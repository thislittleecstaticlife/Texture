//
//  BSpline.hpp
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

#include <Data/Layout.hpp>
#include <Graphics/Polynomial.hpp>
#include <simd/simd.h>

#if defined ( __METAL_VERSION__ )
#include <metal_stdlib>
#else
#include <algorithm>
#include <cassert>
#endif

//===------------------------------------------------------------------------===
// B-spline utlities
//===------------------------------------------------------------------------===

namespace bspline
{

//===------------------------------------------------------------------------===
// • Constants
//===------------------------------------------------------------------------===

enum : uint32_t
{
    // • B-spline constants
    //
    Degree = 3,
    P      = Degree
};

//===------------------------------------------------------------------------===
// • Size utilities
//===------------------------------------------------------------------------===

constexpr uint32_t point_count(uint32_t knot_count)
{
    return knot_count - P - 1;
}

constexpr uint32_t knot_count(uint32_t point_count)
{
    return point_count + P + 1;
}

constexpr uint32_t max_intervals(uint32_t knot_count)
{
#if !defined ( __METAL_VERSION__ )
    return std::max<uint32_t>(2*P+1, knot_count) - (2*P+1);
#else
    return metal::max(2*P+1, knot_count) - (2*P+1);
#endif
}

//===------------------------------------------------------------------------===
// • IntervalCoefficients
//===------------------------------------------------------------------------===

struct IntervalCoefficients
{
    simd::float4    f0, f1, f2, f3;
};

#if !defined ( __METAL_VERSION__ )
static_assert( data::is_trivial_layout<IntervalCoefficients>(), "Unexpected layout" );
#endif

//===------------------------------------------------------------------------===
// • calculate_IntervalCoefficients
//===------------------------------------------------------------------------===

inline IntervalCoefficients calculate_interval_coefficients
(
    float ki1, float ki2, float ki3, float ki4, float ki5, float ki6
)
{
#if !defined ( __METAL_VERSION__ )
    assert( ki3 < ki4 );
#endif

    // • Calculate interval coefficients, remapping to [0, k[4] - k[3]) for numerical stability
    //
    using namespace polynomial;
    using namespace simd;

    // N1
    const auto N12 = float2{  ki4 - ki3, -1.0 } / (ki4 - ki3); // * N03
    const auto N13 = float2{ -ki3 + ki3,  1.0 } / (ki4 - ki3); // * N03

    // N2
    const auto N21 = multiply( float2{  ki4 - ki3, -1.0 } / (ki4 - ki2), N12 );
    const auto N22 = multiply( float2{ -ki2 + ki3,  1.0 } / (ki4 - ki2), N12 )
                   + multiply( float2{  ki5 - ki3, -1.0 } / (ki5 - ki3), N13 );
    const auto N23 = multiply( float2{ -ki3 + ki3,  1.0 } / (ki5 - ki3), N13 );

    // N3
    const auto N30 = multiply( float2{  ki4 - ki3, -1.0 } / (ki4 - ki1), N21 );
    const auto N31 = multiply( float2{ -ki1 + ki3,  1.0 } / (ki4 - ki1), N21 )
                   + multiply( float2{  ki5 - ki3, -1.0 } / (ki5 - ki2), N22 );
    const auto N32 = multiply( float2{ -ki2 + ki3,  1.0 } / (ki5 - ki2), N22 )
                   + multiply( float2{  ki6 - ki3, -1.0 } / (ki6 - ki3), N23 );
    const auto N33 = multiply( float2{ -ki3 + ki3,  1.0 } / (ki6 - ki3), N23 );

    return { .f0 = N30, .f1 = N31, .f2 = N32, .f3 = N33 };
}

#if !defined ( __METAL_VERSION__ )

// • Host specializations
//
inline IntervalCoefficients calculate_interval_coefficients(const float* k, size_t i)
{
    return calculate_interval_coefficients(k[i+1], k[i+2], k[i+3], k[i+4], k[i+5], k[i+6]);
}

#else

// • Metal specializations
//
inline IntervalCoefficients calculate_interval_coefficients(const device float* k, uint16_t i)
{
    return calculate_interval_coefficients(k[i+1], k[i+2], k[i+3], k[i+4], k[i+5], k[i+6]);
}

inline IntervalCoefficients calculate_interval_coefficients(constant float* k, uint16_t i)
{
    return calculate_interval_coefficients(k[i+1], k[i+2], k[i+3], k[i+4], k[i+5], k[i+6]);
}

#endif // defined ( __METAL_VERSION__ )

//===------------------------------------------------------------------------===
// • make_cubic_factors
//===------------------------------------------------------------------------===

inline simd::float4 make_cubic_factors(float u)
{
    const auto u2  = u * u;

    return { 1.0f, u, u2, u*u2 };
}

//===------------------------------------------------------------------------===
//
// • Non-rational B-spline
//
//===------------------------------------------------------------------------===

//===------------------------------------------------------------------------===
// • calculate_value
//===------------------------------------------------------------------------===

inline simd::float3 calculate_value
(
    simd::float4 f0, simd::float4 f1, simd::float4 f2, simd::float4 f3,
    simd::float3 P0, simd::float3 P1, simd::float3 P2, simd::float3 P3,
    float        u
)
{
    const auto vu  = make_cubic_factors(u);
    const auto fP0 = simd::dot(f0, vu) * P0;
    const auto fP1 = simd::dot(f1, vu) * P1;
    const auto fP2 = simd::dot(f2, vu) * P2;
    const auto fP3 = simd::dot(f3, vu) * P3;

    return fP0 + fP1 + fP2 + fP3;
}

} // namespace bspline

//===------------------------------------------------------------------------===
//
// • namespace nurbs
//
//===------------------------------------------------------------------------===

namespace nurbs
{

//===------------------------------------------------------------------------===
// • Interval
//===------------------------------------------------------------------------===

struct Interval
{
    simd::float4    f0, f1, f2, f3;
    simd::float4    P0, P1, P2, P3;
};

#if !defined ( __METAL_VERSION__ )
static_assert( data::is_trivial_layout<Interval>(), "Unexpected layout" );
#endif

//===------------------------------------------------------------------------===
// • calculate_value
//===------------------------------------------------------------------------===

inline simd::float4 apply_weight(simd::float4 p)
{
#if !defined ( __METAL_VERSION__ )
    const auto wp3 = simd::float3{ p.x, p.y, p.z } * p.w;

    return { wp3.x, wp3.y, wp3.x, p.w };
#else
    p.xyz *= p.w;

    return p;
#endif
}

inline simd::float3 remove_weight(simd::float4 wp)
{
#if !defined ( __METAL_VERSION__ )
    return simd::float3{ wp.x, wp.y, wp.z } / wp.w;
#else
    return wp.xyz /= wp.w;
#endif
}

inline simd::float3 calculate_value
(
    simd::float4 f0, simd::float4 f1, simd::float4 f2, simd::float4 f3,
    simd::float4 P0, simd::float4 P1, simd::float4 P2, simd::float4 P3,
    simd::float4 vu
)
{
    const auto fP0 = simd::dot(f0, vu) * apply_weight(P0);
    const auto fP1 = simd::dot(f1, vu) * apply_weight(P1);
    const auto fP2 = simd::dot(f2, vu) * apply_weight(P2);
    const auto fP3 = simd::dot(f3, vu) * apply_weight(P3);

    return remove_weight(fP0 + fP1 + fP2 + fP3);
}

inline simd::float3 calculate_value
(
    simd::float4 f0, simd::float4 f1, simd::float4 f2, simd::float4 f3,
    simd::float4 P0, simd::float4 P1, simd::float4 P2, simd::float4 P3,
    float        u
)
{
    return calculate_value( f0, f1, f2, f3, P0, P1, P2, P3, bspline::make_cubic_factors(u) );
}

#if defined ( __METAL_VERSION__ )

// • Metal specializations
//
inline simd::float3 calculate_value(constant Interval& I, float u)
{
    return calculate_value(I.f0, I.f1, I.f2, I.f3, I.P0, I.P1, I.P2, I.P3, u);
}

inline simd::float3 calculate_value(const thread Interval& I, float u)
{
    return calculate_value(I.f0, I.f1, I.f2, I.f3, I.P0, I.P1, I.P2, I.P3, u);
}

#endif // defined ( __METAL_VERSION__ )

} // namespace nurbs
