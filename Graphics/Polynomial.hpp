//
//  Polynomial.hpp
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
// Polynomial multiplication
//===------------------------------------------------------------------------===

namespace polynomial
{

inline simd::float3 multiply(simd::float2 lhs, simd::float2 rhs)
{
    const auto f0 = lhs[0]*rhs[0];
    const auto f1 = lhs[0]*rhs[1] + lhs[1]*rhs[0];
    const auto f2 =                 lhs[1]*rhs[1];

    return { f0, f1, f2 };
}

inline simd::float4 multiply(simd::float2 lhs, simd::float3 rhs)
{
    const auto f0 = lhs[0]*rhs[0];
    const auto f1 = lhs[0]*rhs[1] + lhs[1]*rhs[0];
    const auto f2 = lhs[0]*rhs[2] + lhs[1]*rhs[1];
    const auto f3 =                 lhs[1]*rhs[2];

    return { f0, f1, f2, f3 };
}

} // namespace polynomial
