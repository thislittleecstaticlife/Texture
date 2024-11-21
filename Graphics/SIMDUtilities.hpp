//
//  SIMDUtilities.hpp
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

#pragma once

#include <simd/simd.h>

//===------------------------------------------------------------------------===
// • Type conversion
//===------------------------------------------------------------------------===

constexpr simd::float2 make_float2(simd::uint2 source)
{
    return { static_cast<float>(source.x), static_cast<float>(source.y) };
}

#if !defined ( __METAL_VERSION__ )

//===------------------------------------------------------------------------===
// • Channel expansion (Host)
//===------------------------------------------------------------------------===

constexpr simd::float4 make_float4(simd::float3 xyz, float w)
{
    return { xyz.x, xyz.y, xyz.z, w };
}

#endif // !defined ( __METAL_VERSION__ )
