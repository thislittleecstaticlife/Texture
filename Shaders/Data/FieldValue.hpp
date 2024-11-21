//
//  FieldValue.hpp
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

#if defined ( __METAL_VERSION__ )

#include <metal_stdlib>

//===------------------------------------------------------------------------===
//
// • FieldValue (Metal only)
//
//===------------------------------------------------------------------------===

struct FieldValue
{
    uint8_t alive;
    uint8_t step;
    uint8_t duration;
    uint8_t reserved;

    FieldValue(ushort4 src)
        :
            alive   { static_cast<uint8_t>(src[0]) },
            step    { static_cast<uint8_t>(src[1]) },
            duration{ static_cast<uint8_t>(src[2]) },
            reserved{ 0u }
    {
    }
};

#endif // defined ( __METAL_VERSION__ )
