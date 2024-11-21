//
//  FieldColorization.hpp
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

#include <Data/Vector.hpp>
#include <Graphics/Geometry.hpp>
#include <simd/simd.h>

//===------------------------------------------------------------------------===
//
// • Transition Colorization
//
//===------------------------------------------------------------------------===

//===------------------------------------------------------------------------===
// • NURBSSegment
//===------------------------------------------------------------------------===

struct NURBSSegment
{
    simd::float4    f0, f1, f2, f3;
    simd::float4    P0, P1, P2, P3;
    float           u0, u1;
};

#if !defined ( __METAL_VERSION__ )
static_assert( data::is_trivial_layout<NURBSSegment>(), "Unexpected layout" );
#endif

//===------------------------------------------------------------------------===
// • FieldColorization
//===------------------------------------------------------------------------===

struct FieldColorization
{
    simd::float4                    threshold_lrgb; // Linear Display P3
    data::VectorRef<NURBSSegment>   growth;         // index 1
    data::VectorRef<NURBSSegment>   decline;        // index 0
    uint8_t                         step_duration;  // Same as Rule::step_duration
    geometry::Region                region;
};

#if !defined ( __METAL_VERSION__ )
static_assert( data::is_trivial_layout<FieldColorization>(), "Unexpected layout" );
#endif
