//
//  Pattern.hpp
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

#include <Graphics/Geometry.hpp>
#include <simd/simd.h>

//===------------------------------------------------------------------------===
//
// • Pattern
//
//===------------------------------------------------------------------------===

struct Pattern
{
    simd::uint2         grid_size;
    geometry::Region    base_region;
    simd::int2          offset;
    uint32_t            count;
};

#if !defined ( __METAL_VERSION__ )
static_assert( data::is_trivial_layout<Pattern>(), "Unexpected layout" );
#endif
