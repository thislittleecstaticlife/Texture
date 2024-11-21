//
//  Vertex.hpp
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

#pragma once

#if defined ( __METAL_VERSION__ )

#import <metal_stdlib>

//===------------------------------------------------------------------------===
// • Vertex positions for implicit clockwise quad triangle strip
//
//      1   3
//      | \ |
//      0   2
//
//===------------------------------------------------------------------------===

constexpr bool is_left_vertex(ushort vid)
{
    return 0 != (vid & 0b10);
}

constexpr bool is_top_vertex(ushort vid)
{
    return 0 != (vid & 0b01);
}

//===------------------------------------------------------------------------===
// • TextureVertex
//===------------------------------------------------------------------------===

struct TextureVertex
{
    float4  position [[ position ]];
    float2  tex_coord;
};

//===------------------------------------------------------------------------===
// • ColorVertex
//===------------------------------------------------------------------------===

struct ColorVertex
{
    float4  position [[ position ]];
    half4   color;
};

#endif // defined ( __METAL_VERSION__ )
