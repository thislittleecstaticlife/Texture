//
//  Reference-Metal.hpp
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

#include <Data/Reference-Common.hpp>

//===------------------------------------------------------------------------===
// • namespace data
//===------------------------------------------------------------------------===

namespace data
{

//===------------------------------------------------------------------------===
//
// • Reference utilities (Metal)
//
//===------------------------------------------------------------------------===

template <TRIVIAL_LAYOUT Type_>
const device Type_* cdata(Reference<Type_> ref, const device uint8_t* base)
{
    return reinterpret_cast<const device Type_*>(base + ref.offset);
}

template <TRIVIAL_LAYOUT Type_>
const device Type_* data(Reference<Type_> ref, const device uint8_t* base)
{
    return cdata(ref, base);
}

template <TRIVIAL_LAYOUT Type_>
device Type_* data(Reference<Type_> ref, device uint8_t* base)
{
    return reinterpret_cast<device Type_*>(base + ref.offset);
}

template <TRIVIAL_LAYOUT Type_>
const device Type_* cdata(Reference<Type_> ref, device uint8_t* base)
{
    return data(ref, base);
}

template <TRIVIAL_LAYOUT Type_>
constant Type_* cdata(Reference<Type_> ref, constant uint8_t* base)
{
    return reinterpret_cast<constant Type_*>(base + ref.offset);
}

template <TRIVIAL_LAYOUT Type_>
constant Type_* data(Reference<Type_> ref, constant uint8_t* base)
{
    return cdata(base + ref.offset);
}

} // namespace data
