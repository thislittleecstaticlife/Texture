//
//  InitField.metal
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

#include <Shaders/Data/FieldInitialization.hpp>
#include <Shaders/Data/FieldValue.hpp>
#include <Shaders/Data/Vertex.hpp>

//===------------------------------------------------------------------------===
// • init_field_fragment
//===------------------------------------------------------------------------===

[[fragment]] ushort4 init_field_fragment(void)
{
    return { 1u, 0u, 0u, 0u };
}

//===------------------------------------------------------------------------===
// • init_field_vertex
//===------------------------------------------------------------------------===

[[vertex]] float4 init_field_vertex
(
    constant FieldInitialization& field_init [[ buffer(0)   ]],
    ushort                        vid        [[ vertex_id   ]],
    ushort                        iid        [[ instance_id ]]
)
{
    const auto offset = field_init.offset * iid;
    const auto region = field_init.base_region + offset;
    const auto rect   = geometry::make_device_rect(region, field_init.field_size);

    const auto nx = is_left_vertex(vid) ? rect.left : rect.right;
    const auto ny = is_top_vertex(vid)  ? rect.top  : rect.bottom;

    return { nx, ny, 0.0f, 1.0f };
}
