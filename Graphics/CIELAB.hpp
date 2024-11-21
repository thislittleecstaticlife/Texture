//
//  CIELAB.hpp
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
//
// • CIELAB to Linear RGB Conversion
//
//===------------------------------------------------------------------------===

namespace cielab
{

// • CIELAB to XYZ
//
constexpr float component_to_XYZ(float labc)
{
    // 108/841   = 3 * (6/29)^2
    // 432/24389 = 3 * (6/29)^2 * 4/29
    return (labc > 6.0f/29.0f) ? labc*labc*labc : simd::fma(labc, 108.0f/841.0f, -432.0f/24389.0f);
}

inline simd::float3 convert_to_XYZ(simd::float3 lab)
{
    const auto Ls = (lab[0] + 16.0f) / 116.0f;
    const auto Y  = component_to_XYZ(Ls);
    const auto X  = component_to_XYZ(Ls + lab[1]/500.0f);
    const auto Z  = component_to_XYZ(Ls - lab[2]/200.0f);

    return { X, Y, Z };
}

// • CIELAB XYZ to linear sRGB
//
inline simd::float3 XYZ_to_linear_sRGB(simd::float3 xyz)
{
    // • Pre-multiply by XnYnZn for D65 white point
    //
    const auto M_XYZ_to_linear_sRGB = simd::float3x3 {
        simd::float3{  3.2406f * 0.95047f, -0.9689f * 0.95047f,  0.0557f * 0.95047f  },
        simd::float3{ -1.5372f * 1.00000f,  1.8758f * 1.00000f, -0.2040f * 1.00000f  },
        simd::float3{ -0.4986f * 1.08883f,  0.0415f * 1.08883f,  1.0570f * 1.08883f  }
    };

    return M_XYZ_to_linear_sRGB * xyz;
}

inline simd::float3 convert_to_linear_sRGB(simd::float3 lab)
{
    return XYZ_to_linear_sRGB( convert_to_XYZ(lab) );
}

// • CIELAB XYZ to linear display P3
//
inline simd::float3 XYZ_to_linear_display_P3(simd::float3 xyz)
{
    // • Pre-multiply by XnYnZn for D65 white point
    //
    const auto M_XYZ_to_linear_display_P3 = simd::float3x3 {
        simd::float3{  2.493509123935f * 0.95047f, -0.829473213930f * 0.95047f,  0.035851264434f * 0.95047f  },
        simd::float3{ -0.931388179405f * 1.00000f,  1.762630579600f * 1.00000f, -0.076183936922f * 1.00000f  },
        simd::float3{ -0.402712756742f * 1.08883f,  0.023624237106f * 1.08883f,  0.957029586694f * 1.08883f  }
    };

    return M_XYZ_to_linear_display_P3 * xyz;
}

inline simd::float3 convert_to_linear_display_P3(simd::float3 lab)
{
    return XYZ_to_linear_display_P3( convert_to_XYZ(lab) );
}

} // namespace cielab
