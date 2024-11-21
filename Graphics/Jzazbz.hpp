//
//  Jzazbz.hpp
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
// • Jzazbz to Linear RGB Conversion
//
//===------------------------------------------------------------------------===

namespace jzazbz
{

// • Jzazbz to LMS
//
inline simd::float3 convert_to_LMS(simd::float3 jab)
{
    const auto M_IzazbzToLMSp = simd::float3x3 {
        simd::float3{ 1.0f,                 1.0f,                 1.0f                },
        simd::float3{ 0.138605043271539f,  -0.138605043271539f,  -0.0960192420263189f },
        simd::float3{ 0.0580473161561189f, -0.0580473161561189f, -0.811891896056039f  }
    };

    constexpr auto d     = -0.56f;
    constexpr auto d0    =  1.6295499532821566e-11f;

    constexpr auto vc1   = simd::float3( 3424.0f/4096.0f );
    constexpr auto vc2   = simd::float3( 2413.0f/128.0f );
    constexpr auto vc3   = 2392.0f/128.0f;
    constexpr auto vInvP = simd::float3( 32.0f / (1.7f * 2523.0f) );
    constexpr auto vInvN = simd::float3( 16384.0f / 2610.0f );

    // actually 0.000000000037035, adjusted for precision limits
    constexpr auto minLMSp = simd::float3(0.0000000000370353f);
    constexpr auto maxLMSp = simd::float3(3.227f);

    const auto Jzp    = jab[0] + d0;
    const auto Iz     = Jzp / (1.0f + d - d*Jzp);
    const auto LMSp   = M_IzazbzToLMSp * simd::float3{ Iz, jab[1], jab[2] };
    const auto LMSpc  = simd::clamp(LMSp, minLMSp, maxLMSp);

#if !defined ( __METAL_VERSION__ )
    const auto LMSpp1 = simd::pow(LMSpc, vInvP);
    const auto LMSpp2 = (vc1 - LMSpp1) / (vc3*LMSpp1 - vc2);
    const auto LMS    = 100.0f * simd::pow(LMSpp2, vInvN);
#else
    const auto LMSpp1 = powr(LMSpc, vInvP);
    const auto LMSpp2 = (vc1 - LMSpp1) / (vc3*LMSpp1 - vc2);
    const auto LMS    = 100.0f * powr(LMSpp2, vInvN);
#endif

    return LMS;
}

// • Linear sRGB
//
inline simd::float3 LMS_to_linear_sRGB(simd::float3 lms)
{
    // M_LMSToXYZD65p = [ 1.92422643578761   0.350316762094999 -0.0909828109828476 ]
    //                  [-1.00479231259537   0.726481193931655 -0.312728290523074  ]
    //                  [ 0.037651404030618 -0.065384422948085  1.52276656130526   ]

    // X = (Xp + (b-1)*Zp) / b = (1/b)*Xp + (1-1/b)*Zp
    // Y = (Yp + (g-1)*X ) / g = (1/g)*Yp + (1-1/g)*X = (1/b)*(1-1/g)*Xp + (1/g)*Yp + (1-1/b)*(1-1/g)*Zp
    // Z = Zp

    // M_XYZpToXYZD65 = [ 1/b    (1/b)*(1-1/g)    0 ]
    //                  [  0      1/g             0 ]
    //                  [ 1-1/b  (1-1/b)*(1-1/g)  1 ]

    // M_XYZToLinearSRGB = [  3.2406 -0.9689  0.0557 ]
    //                     [ -1.5372  1.8758 -0.2040 ]
    //                     [ -0.4986  0.0415  1.0570 ]

    // M_LMSToLinearSRGB = M_XYZToLinearSRGB * M_XYZpToXYZD65 * M_LMSToXYZD65p
    const auto M_LMSToLinearSRGB = simd::float3x3 {
        simd::float3{  5.928916187675942f,  -2.2232574649245875f, 0.06268512630245734f },
        simd::float3{ -5.223920474711462f,   3.821573874665749f, -0.7021495351522504f  },
        simd::float3{  0.3260003286939446f, -0.5703724416551675f, 1.6669749046738151f  }
    };

    return M_LMSToLinearSRGB * lms;
}

inline simd::float3 convert_to_linear_sRGB(simd::float3 jab)
{
    return LMS_to_linear_sRGB( convert_to_LMS(jab) );
}

// • Linear Display P3
//
inline simd::float3 LMS_to_linear_display_P3(simd::float3 lms)
{
    // M_XYZToLinearP3 = [  2.49350912393461  -0.829473213929555   0.035851264433918  ] T
    //                   [ -0.931388179404779  1.7626305796003    -0.0761839369220758 ]
    //                   [ -0.402712756741652  0.0236242371055886  0.957029586694311  ]

    // M_LMSToLinearP3 = M_XYZToLinearP3 * M_XYZpToXYZD65 * M_LMSToXYZD65p
    const auto M_LMSToLinearP3 = simd::float3x3 {
        simd::float3{  4.4820606379518333f,  -1.9532025238860451f,  -0.0027453573623004834f },
        simd::float3{ -3.6184317541411817f,   3.5217700975984596f,  -0.45182653146288487f   },
        simd::float3{  0.16694496856407345f, -0.54063532522070301f,  1.4822547119502889f    },
    };

    return M_LMSToLinearP3 * lms;
}

inline simd::float3 convert_to_linear_display_P3(simd::float3 jab)
{
    return LMS_to_linear_display_P3( convert_to_LMS(jab) );
}

// • Linear ITU-R 2020
//
inline simd::float3 LMS_to_linear_itur_2020(simd::float3 lms)
{
    const auto M_LMSToLinearITUR2020 = simd::float3x3 {
        simd::float3{  2.9906913209073838f, -1.6344993549194478f,  -0.04251143547568441f },
        simd::float3{ -2.0497570317141833f,  3.145578592952177f,   -0.3780394511655554f  },
        simd::float3{  0.0889774286646932f, -0.48302926695084236f,  1.448234601184897f   }
    };

    return M_LMSToLinearITUR2020 * lms;
}

inline simd::float3 convert_to_linear_itur_2020(simd::float3 jab)
{
    return LMS_to_linear_itur_2020( convert_to_LMS(jab) );
}

// • Jzazbz from LMS
//
inline simd::float3 from_LMS(simd::float3 lms)
{
    // 0.5       0.5       0
    // 3.524000 -4.066708  0.542708
    // 0.199076  1.096799 -1.295875
    const auto M_LMSpToIzazbz = simd::float3x3{
        simd::float3{ 0.5f,  3.524000f,  0.199076f },
        simd::float3{ 0.5f, -4.066708f,  1.096799f },
        simd::float3{ 0.0f,  0.542708f, -1.295875f }
    };

    constexpr auto c1 = simd::float3( 3424.0f / 4096.0f );
    constexpr auto c2 = 2413.0f / 128.0f;
    constexpr auto c3 = 2392.0f / 128.0f;
    constexpr auto n  = 2610.0f / 16384.0f;
    constexpr auto p  = 1.7f * 2523.0f / 32.0f;

    constexpr auto d  = -0.56f;
    constexpr auto d0 =  1.6295499532821566e-11f;

#if !defined ( __METAL_VERSION__ )
    const auto valp     = simd::pow( simd::max(lms/100.0f, simd::float3(0.0f)), simd::float3(n) );
    const auto fraction = (c1 + c2*valp) / (simd::float3(1.0f) + c3*valp);
    const auto lmsp     = simd::pow( fraction, simd::float3(p) );
#else
    const auto valp     = powr( simd::max(lms/100.0f, 0.0f), n );
    const auto fraction = (c1 + c2*valp) / (simd::float3(1.0f) + c3*valp);
    const auto lmsp     = powr(fraction, p);
#endif

    const auto Izazbz   = M_LMSpToIzazbz * lmsp;
    const auto Jzn      = (1.0f + d) * Izazbz[0];
    const auto Jzd      =  1.0f + d*Izazbz[0];
    const auto Jz       = Jzn / Jzd - d0;

    return { Jz, Izazbz[1], Izazbz[2] };
}

} // namespace jzazbz
