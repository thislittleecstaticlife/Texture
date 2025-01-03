//
//  Reference-Common.hpp
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

//===------------------------------------------------------------------------===
// • namespace data
//===------------------------------------------------------------------------===

namespace data
{

//===------------------------------------------------------------------------===
//
// • Reference
//
//===------------------------------------------------------------------------===

template <TRIVIAL_LAYOUT Type_>
struct Reference
{
    uint32_t offset;    // Offset from the beginning of the buffer (data atom)
};

static_assert( 4 ==  sizeof(Reference<int>), "Unexpected size" );
static_assert( 4 == alignof(Reference<int>), "Unexpected alignment" );

} // namespace data
