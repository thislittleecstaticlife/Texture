//
//  Composition.mm
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

#import "Composition.h"

#import <Data/Reference.hpp>

#import <Graphics/BSpline.hpp>
#import <Graphics/Jzazbz.hpp>
#import <Graphics/Gamma.hpp>

#import <Shaders/Data/FieldInitialization.hpp>
#import <Shaders/Data/FieldColorization.hpp>
#import <Shaders/Data/Surface.hpp>
#import <Shaders/Data/AutomatRule.hpp>

#import <numeric>

//===------------------------------------------------------------------------===
//
// • CompositionData
//
//===------------------------------------------------------------------------===

struct CompositionData
{
    data::Reference<FieldInitialization>    field_init;
    data::Reference<FieldColorization>      colorization;
    data::Reference<simd::float4>           background_color;
    data::Reference<Surface>                surface;
    data::Reference<AutomatRule>            rule;
};

static_assert( data::is_trivial_layout<CompositionData>(), "Unexpected layout" );

//===------------------------------------------------------------------------===
//
#pragma mark - Composition Implementation
//
//===------------------------------------------------------------------------===

@implementation Composition
{
    id<MTLBuffer>               compositionBuffer;
    const CompositionData*      composition;
    const FieldInitialization*  field_init;
    const FieldColorization*    colorization;
    const Surface*              surface;
    const AutomatRule*          rule;

    uint8_t                     substep;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device {

    self = [super init];

    if (nil != self) {

        // • Composition data buffer
        //
        auto compositionBufferLength = uint32_t{ 1024 };

        compositionBuffer = [device newBufferWithLength:compositionBufferLength options:0];

        if (nil == compositionBuffer) {
            return nil;
        }

        try
        {
            // • Composition data
            //
            auto [data, composition] = data::format_with_data(compositionBuffer.contents,
                                                              compositionBufferLength,
                                                              CompositionData {
                .field_init   = { 0 },
                .colorization = { 0 },
                .rule         = { 0 }
            });

            self->composition = composition;

            // • Field initialization
            //
            auto field_init = data::allocate(composition->field_init, data);

            field_init->field_size  = { 512, 512 };
            field_init->base_region = geometry::make_region({ 379, 256 }, { 10, 1});
            field_init->offset      = { 0, 0 };
            field_init->count       = 1;

            self->field_init = field_init;

            // • Rule
            //
            auto rule = data::allocate(composition->rule, data);

            rule->born             = 0b000011000;    // 3, 4
            rule->survive          = 0b000011100;    // 2, 3, 4
            rule->growth_duration  = 0;
            rule->decline_duration = 19;

            self->rule = rule;

            // • Colorization
            //
            const auto threshold_color = simd::float3{ 0.0134f, 0.005056f, -0.04002f };
            const auto threshold_lrgb  = jzazbz::convert_to_linear_itur_2020(threshold_color);
            const auto threshold_rgb   = gamma::linear_to_ITUR_2020(threshold_lrgb);

            //  - background
            auto background_color = data::allocate(composition->background_color, data);

            *background_color = make_float4(threshold_rgb, 1.0f);

            //  - colorization
            auto colorization = data::allocate(composition->colorization, data);

            colorization->threshold_lrgb = make_float4(threshold_lrgb, 1.0f);
            colorization->step_duration  = 48;
            colorization->region         = geometry::make_region({ 160, 234 }, { 192, 10 });

            _initialStepCount = 78;

            //  - Decline gradient
            const auto threshold_point = make_float4(threshold_color, 1.0f);

            const simd::float4 P[] = {
                threshold_point, threshold_point,
                simd::float4{ 0.03139424f,  0.06871698f,    0.10111381f,  1.0f },
                simd::float4{ 0.1665044f,  -0.0138282385f,  0.061864287f, 1.0f },
                simd::float4{ 0.03060941f, -0.04786195f,   -0.075418405f, 1.0f },
                threshold_point, threshold_point
            };

            constexpr float k[] = {
                0.0f, 0.0f, 0.0f, 0.0f,
                0.24976527f,
                0.51877934f,
                0.7830986f,
                1.0f, 1.0f, 1.0f, 1.0f,
            };

            auto S = data::make_vector(colorization->decline, data);

            for (auto i = size_t{ 0 }, end = std::size(k) - 7; i < end; ++i)
            {
                if ( k[i+3] >= k[i+4] ) {
                    continue;
                }

                const auto F = bspline::calculate_interval_coefficients(k, i);

                S.push_back( {
                    .f0 = F.f0,   .f1 = F.f1,   .f2 = F.f2,   .f3 = F.f3,
                    .P0 = P[i+0], .P1 = P[i+1], .P2 = P[i+2], .P3 = P[i+3],
                    .u0 = k[i+3], .u1 = k[i+4]
                } );
            }

            S.shrink_to_fit();

            self->colorization = colorization;

            // • Surface
            //
            auto surface = data::allocate(composition->surface, data);

            surface->source_region = geometry::expand(colorization->region, 3);
            surface->output_origin = { 4, 0 };

            surface->output_scale = {
                geometry::width(surface->source_region) + 5,
                geometry::height(surface->source_region) - 3
            };

            self->surface = surface;
        }
        catch ( ... )
        {
            return nil;
        }

        // • Aspect ratio
        //
        _aspectRatio = { 16, 9 };

        // • State
        //
        substep = 0;
    }

    return self;
}

//===------------------------------------------------------------------------===
#pragma mark - Properties (Field Initialization)
//===------------------------------------------------------------------------===

- (nonnull id<MTLBuffer>)fieldInitBuffer {

    return compositionBuffer;
}

- (NSInteger)fieldInitOffset {

    return composition->field_init.offset;
}

- (NSInteger)fieldInitInstanceCount {

    return field_init->count;
}

- (simd_uint2)fieldSize {

    return field_init->field_size;
}

//===------------------------------------------------------------------------===
#pragma mark - Properties (Rule)
//===------------------------------------------------------------------------===

- (nonnull id<MTLBuffer>)ruleBuffer {

    return compositionBuffer;
}

- (NSInteger)ruleOffset {

    return composition->rule.offset;
}

//===------------------------------------------------------------------------===
#pragma mark - Properties (Colorization)
//===------------------------------------------------------------------------===

- (nonnull id<MTLBuffer>)colorizeFieldBuffer {

    return compositionBuffer;
}

- (NSInteger)colorizeFieldOffset {

    return composition->colorization.offset;
}

//===------------------------------------------------------------------------===
#pragma mark - Properties (Surface)
//===------------------------------------------------------------------------===

- (nonnull id<MTLBuffer>)backgroundColorBuffer {

    return compositionBuffer;
}

- (NSInteger)backgroundColorOffset {

    return composition->background_color.offset;
}

- (nonnull id<MTLBuffer>)surfaceBuffer {

    return compositionBuffer;
}

- (NSInteger)surfaceOffset {

    return composition->surface.offset;
}

- (simd::uint2)surfaceDimensions {

    return geometry::size(surface->source_region) - simd::uint2{ 3, 3 };
}

//===------------------------------------------------------------------------===
#pragma mark - Properties (State)
//===------------------------------------------------------------------------===

- (BOOL)shouldStepNext {

    return (substep + 1) == colorization->step_duration;
}

- (uint8_t)currentSubstep {

    return substep;
}

//===------------------------------------------------------------------------===
#pragma mark - Methods (State)
//===------------------------------------------------------------------------===

- (void)nextSubstep {

    substep = (substep + 1) % colorization->step_duration;
}

@end
