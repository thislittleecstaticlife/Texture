//
//  ColorizeField.metal
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

#include <Shaders/Data/FieldColorization.hpp>
#include <Shaders/Data/FieldValue.hpp>
#include <Shaders/Data/Vertex.hpp>

#include <Graphics/Geometry.hpp>
#include <Graphics/BSpline.hpp>
#include <Graphics/Jzazbz.hpp>
#include <Graphics/Gamma.hpp>

//===------------------------------------------------------------------------===
// • namespace <anonymous>
//===------------------------------------------------------------------------===

namespace
{

//===------------------------------------------------------------------------===
// • colorize_cell
//===------------------------------------------------------------------------===

float4 colorize_cell(FieldValue                  cell,
                     ushort                      substep,
                     constant FieldColorization& colorization [[ buffer(0) ]],
                     constant uint8_t*           base         [[ buffer(1) ]])
{
    // • Transition - use B-spline segment
    //
    //    The algorithm counts down from transition duration to zero, so the
    //    position along the gradient is logically reversed
    //
    constant auto& segments = (cell.alive) ? colorization.growth : colorization.decline;

    const auto step_position  = colorization.step_duration * (cell.duration - cell.step) + substep;
    const auto total_duration = colorization.step_duration *  cell.duration;
    const auto u              = (float(step_position) + 0.5f) / float(total_duration);

    constant auto* S = data::cdata(segments, base);

    for (uint i = 0u; i < segments.count; ++i, ++S)
    {
        if (S->u0 <= u && u < S->u1)
        {
            const auto color = nurbs::calculate_value( S->f0, S->f1, S->f2, S->f3,
                                                       S->P0, S->P1, S->P2, S->P3,
                                                       u - S->u0 );

            const auto lrgb = jzazbz::convert_to_linear_itur_2020(color);

            constexpr auto min_lrgb = float3(0.0f);
            constexpr auto max_lrgb = float3(1.0f);

            if ( all(lrgb == clamp(lrgb, min_lrgb, max_lrgb)) )
            {
                return float4(lrgb, 1.0f);
            }
            else
            {
                return { 0.5f, 0.5f, 0.5f, 1.0f };
            }
        }
    }

    return colorization.threshold_lrgb;
}

} // namespace <anonymous>

//===------------------------------------------------------------------------===
// • colorize_field
//===------------------------------------------------------------------------===

struct ColorizationData
{
    half4 color;
};

[[kernel]] void colorize_field
(
    imageblock<ColorizationData>   image_block,
    constant FieldColorization&    colorization    [[ buffer(0)                      ]],
    constant uint8_t*              base            [[ buffer(1)                      ]],
    constant uint8_t&              substep         [[ buffer(2)                      ]],
    texture2d<ushort,access::read> field           [[ texture(0)                     ]],
    texture2d<half,access::write>  colorized_field [[ texture(1)                     ]],
    uint2                          pos             [[ thread_position_in_grid        ]],
    ushort2                        lid             [[ thread_position_in_threadgroup ]]
)
{
    // • The default color is always threshold color, both for threshold values
    //      and those outside of the colorization region
    //
    auto lrgba = colorization.threshold_lrgb;

    if ( geometry::contains(colorization.region, pos) )
    {
        const auto cell = FieldValue{ field.read(pos) };

        if ( 0 < cell.step )
        {
            // • Transition - use colorization from gradient
            //
            lrgba = colorize_cell(cell, substep, colorization, base);
        }
    }

    // • Write to the image block
    //
    threadgroup_imageblock auto* data = image_block.data(lid.xy);
    data->color = half4(lrgba);

    threadgroup_barrier(mem_flags::mem_threadgroup_imageblock);

    if (0 == lid.x && 0 == lid.y)
    {
        colorized_field.write(image_block.slice(data->color), pos);
    }
}
