//
//  FillBackground.metal
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

#include <Shaders/Data/Vertex.hpp>

//===------------------------------------------------------------------------===
// • fill_background_fragment
//===------------------------------------------------------------------------===

[[fragment]] half4 fill_background_fragment(ColorVertex in [[ stage_in ]])
{
    return in.color;
}

//===------------------------------------------------------------------------===
// • fill_background_vertex
//===------------------------------------------------------------------------===

[[vertex]] ColorVertex fill_background_vertex(constant float4& color [[ buffer(0) ]],
                                              ushort           vid   [[ vertex_id ]])
{
    const auto nx = is_left_vertex(vid) ? -1.0f :  1.0f;
    const auto ny = is_top_vertex(vid)  ?  1.0f : -1.0f;

    return {
        .position = { nx, ny, 1.0f, 1.0f },
        // TODO: Accept and convert from alternate color space
        .color    = half4(color)
    };
}
