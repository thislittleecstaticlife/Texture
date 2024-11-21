//
//  Reference-Host.hpp
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
#include <Data/Allocation.hpp>

#include <cassert>

//===------------------------------------------------------------------------===
// • namespace data
//===------------------------------------------------------------------------===

namespace data
{

//===------------------------------------------------------------------------===
// • Verification
//===------------------------------------------------------------------------===

static_assert( is_trivial_layout<Reference<int>>(), "Unexpected layout" );

//===------------------------------------------------------------------------===
//
// • Reference Utilities (Host)
//
//===------------------------------------------------------------------------===

template <TrivialLayout Type_>
constexpr bool is_null(const Reference<Type_>& ref) noexcept
{
    return 0 == ref.offset;
}

namespace detail
{

//===------------------------------------------------------------------------===
// • Reference header offset
//===------------------------------------------------------------------------===

template <TrivialLayout Type_>
Atom* allocation_header(const Reference<Type_>& ref, Atom* data) noexcept(false)
{
    if ( !is_aligned(ref.offset) || ref.offset < 2*atom_header_length )
    {
        assert( false );
        throw false;
    }

    auto allocation_offset = ref.offset - atom_header_length;
    auto allocation        = detail::offset_by(data, allocation_offset);

    if ( AtomID::reference != allocation->identifier
        || allocation->length < atom_header_length + sizeof(Type_) )
    {
        assert( false );
        throw false;
    }

    return allocation;
}

} // namespace detail

//===------------------------------------------------------------------------===
// • Allocation
//===------------------------------------------------------------------------===

template <TrivialLayout Type_>
Type_* allocate(Reference<Type_>& ref, Atom* data) noexcept(false)
{
    auto refr     = detail::reserve(data, aligned_size<Type_>(), AtomID::reference);
    auto contents = detail::contents<Type_>(refr);

    ref.offset = detail::distance(data, contents);

    return contents;
}

template <TrivialLayout Type_>
void free(Reference<Type_>& ref, Atom* data) noexcept
{
    if ( !is_null(ref) )
    {
        auto refr = detail::allocation_header(ref, data);

        detail::free(refr);

        ref.offset = 0;
    }
}

//===------------------------------------------------------------------------===
// • Data access
//===------------------------------------------------------------------------===

template <TrivialLayout Type_>
Type_* data(Reference<Type_> ref, Atom* data)
{
    assert( !is_null(ref) );

    return reinterpret_cast<Type_*> (
                reinterpret_cast<uint8_t*>(data) + ref.offset );
}

template <TrivialLayout Type_>
const Type_* cdata(const Reference<Type_>& ref, const Atom* data)
{
    assert( !is_null(ref) );

    return reinterpret_cast<const Type_*> (
                reinterpret_cast<const uint8_t*>(data) + ref.offset );
}

template <TrivialLayout Type_>
const Type_* data(const Reference<Type_>& ref, const Atom* data)
{
    return cdata(ref, data);
}

} // namespace data
