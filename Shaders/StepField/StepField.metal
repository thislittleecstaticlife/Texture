//
//  StepField.metal
//
//  Copyright © 2024 Robert Guequierre
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

#include <metal_stdlib>
using namespace metal;

#include <Shaders/Data/AutomatRule.hpp>
#include <Shaders/Data/FieldValue.hpp>

//===------------------------------------------------------------------------===
// • step
//===------------------------------------------------------------------------===

struct FieldData
{
    uchar4  value;
};

[[kernel]] void step_field
(
    imageblock<FieldData>           image_block,
    constant AutomatRule&           rule         [[ buffer(0)                      ]],
    texture2d<ushort,access::read>  source_field [[ texture(0)                     ]],
    texture2d<ushort,access::write> dest_field   [[ texture(1)                     ]],
    threadgroup FieldValue*         shared       [[ threadgroup(0)                 ]],
    const ushort2                   field_size   [[ threads_per_grid               ]],
    const ushort2                   pos          [[ thread_position_in_grid        ]],
    const ushort2                   tg_size      [[ threads_per_threadgroup        ]],
    const ushort2                   lid          [[ thread_position_in_threadgroup ]]
)
{
    // • Read source values into threadgroup memory along with a one pixel border on all sides
    //
    const auto row_offset = tg_size.x + 2u;
    const auto offset     = uint2{ lid.x, row_offset * lid.y };
    const auto alt_offset = offset + uint2{ tg_size.x, row_offset*tg_size.y };

    const auto source_pos = (pos + field_size - ushort2{ 1, 1 }) % field_size;
    const auto alt_pos    = (source_pos + tg_size) % field_size;

    // • All threads read one pixel up and to the left
    //
    shared[offset.y + offset.x] = source_field.read(source_pos);

    if (lid.x < 2) {
        // 2 left-most columns also read the pixel offset by tg_size.x to the right
        shared[offset.y + alt_offset.x] = source_field.read({ alt_pos.x, source_pos.y });
    }

    if (lid.y < 2) {
        // 2 top-most rows also read the pixel offset by tg_size.y below
        shared[alt_offset.y + offset.x] = source_field.read({ source_pos.x, alt_pos.y });
    }

    if (lid.x < 2 && lid.y < 2) {
        // 4 upper-left threads also read the pixel offset by (tg_size.x, tg_size.y)
        shared[alt_offset.y + alt_offset.x] = source_field.read(alt_pos);
    }

    threadgroup_barrier(mem_flags::mem_threadgroup);

    // • Step or calculate neighbors
    //
    const auto center_offset = offset + uint2{ 1, row_offset };

    auto value = shared[center_offset.y + center_offset.x];

    if (0 < value.step)
    {
        // • Next step
        //
        --value.step;
    }
    else
    {
        threadgroup auto* upper  = shared + offset.y + offset.x;
        threadgroup auto* middle = upper  + row_offset;
        threadgroup auto* lower  = middle + row_offset;

        // • Fallow or mature
        //
        const auto neighbor_count =  upper[0].alive
                                  +  upper[1].alive
                                  +  upper[2].alive
                                  + middle[0].alive
                                  + middle[2].alive
                                  +  lower[0].alive
                                  +  lower[1].alive
                                  +  lower[2].alive;

        const auto neighbors = 1 << neighbor_count;

        if (value.alive)
        {
            // Mature
            if ( 0 == (neighbors & rule.survive) )
            {
                // Decline
                value.step  = value.duration = rule.decline_duration;
                value.alive = 0;
            }
        }
        else
        {
            // Fallow
            if ( 0 != (neighbors & rule.born) )
            {
                // Growth
                value.step  = value.duration = rule.growth_duration;
                value.alive = 1;
            }
        }
    }

    // • Write to image block
    //
    threadgroup_imageblock auto* field_data = image_block.data(lid);
    field_data->value = { value.alive, value.step, value.duration, 0 };

    threadgroup_barrier(mem_flags::mem_threadgroup_imageblock);

    // • Write image block to device memory
    //
    if ( 0 == lid.x && 0 == lid.y )
    {
        dest_field.write(image_block.slice(field_data->value), pos);
    }
}
