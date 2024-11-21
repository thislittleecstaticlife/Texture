//
//  Gamma.hpp
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

#if defined ( __METAL_VERSION__)
#include <metal_stdlib>
#endif

#include <simd/simd.h>

//===------------------------------------------------------------------------===
//
// • RGB gamma coding
//
//===------------------------------------------------------------------------===

namespace gamma
{

//===------------------------------------------------------------------------===
// • sRGB
//===------------------------------------------------------------------------===

#if !defined ( __METAL_VERSION__)

inline float linear_to_sRGB(float c)
{
    const auto abs_c = fabs(c);

    const auto abs_gamma = (0.0031308f < abs_c)
        ? (1.055f * powf(abs_c, 1.0f/2.4f)) - 0.055f
        :  12.92f * abs_c;

    return 0.0f <= c ? abs_gamma : -abs_gamma;
}

#else

inline float linear_to_sRGB(float c)
{
    const auto abs_c = metal::abs(c);

    const auto abs_gamma = (0.0031308f < abs_c)
        ? (1.055f * metal::powr(abs_c, 1.0f/2.4f)) - 0.055f
        :  12.92f * abs_c;

    return metal::copysign(abs_gamma, c);
}

#endif // defined ( __METAL_VERSION__ )

inline simd::float3 linear_to_sRGB(simd::float3 lrgb)
{
    return {
        linear_to_sRGB(lrgb.x),
        linear_to_sRGB(lrgb.y),
        linear_to_sRGB(lrgb.z)
    };
}

//===------------------------------------------------------------------------===
// • ITU R 2020
//===------------------------------------------------------------------------===

inline float linear_to_ITUR_2020(float V)
{
    const auto abs_v = fabs(V);

    const auto abs_gamma = (0.018053968510807f <= abs_v)
        ? (1.09929682680944f * pow(abs_v, 0.45f)) - 0.09929682680944f
        :  4.5f * abs_v;

    return 0.0f <= V ? abs_gamma : -abs_gamma;
}

inline simd::float3 linear_to_ITUR_2020(simd::float3 lrgb)
{
    return {
        linear_to_ITUR_2020(lrgb.x),
        linear_to_ITUR_2020(lrgb.y),
        linear_to_ITUR_2020(lrgb.z)
    };
}

} // namespace gamma
