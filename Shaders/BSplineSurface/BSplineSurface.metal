//
//  BSplineSurface.metal
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

#include <metal_stdlib>
using namespace metal;

#include <Shaders/Data/Surface.hpp>
#include <Graphics/BSpline.hpp>
#include <Graphics/Gamma.hpp>

//===------------------------------------------------------------------------===
// • Surface rendering
//===------------------------------------------------------------------------===

struct SurfaceVertex
{
    float4 position [[ position ]];
    float  u, v;
};

struct Patch
{
    simd::float4    fu0, fu1, fu2, fu3;
    simd::float4    fv0, fv1, fv2, fv3;
    simd::float4    P00, P01, P02, P03;
    simd::float4    P10, P11, P12, P13;
    simd::float4    P20, P21, P22, P23;
    simd::float4    P30, P31, P32, P33;
};

using SurfaceMesh = mesh<SurfaceVertex, Patch, 6, 2, topology::triangle>;

struct SurfaceFragment
{
    SurfaceVertex   v;
    Patch           patch;
};

struct SurfacePayload
{
    SurfaceVertex   vertices[6];
    Patch           patch;
};

[[fragment]] half4 bspline_surface_fragment(SurfaceFragment input [[ stage_in ]] )
{
    // • Horizontal calculation for each row
    //
    const auto vu  = bspline::make_cubic_factors(input.v.u);
    const auto Fu0 = dot(input.patch.fu0, vu);
    const auto Fu1 = dot(input.patch.fu1, vu);
    const auto Fu2 = dot(input.patch.fu2, vu);
    const auto Fu3 = dot(input.patch.fu3, vu);

    const auto row0 = Fu0 * input.patch.P00
                    + Fu1 * input.patch.P01
                    + Fu2 * input.patch.P02
                    + Fu3 * input.patch.P03;

    const auto row1 = Fu0 * input.patch.P10
                    + Fu1 * input.patch.P11
                    + Fu2 * input.patch.P12
                    + Fu3 * input.patch.P13;

    const auto row2 = Fu0 * input.patch.P20
                    + Fu1 * input.patch.P21
                    + Fu2 * input.patch.P22
                    + Fu3 * input.patch.P23;

    const auto row3 = Fu0 * input.patch.P30
                    + Fu1 * input.patch.P31
                    + Fu2 * input.patch.P32
                    + Fu3 * input.patch.P33;

    // • Vertical calculation
    //
    const auto vv = bspline::make_cubic_factors(input.v.v);

    const auto lrgbw = dot(input.patch.fv0, vv) * row0
                     + dot(input.patch.fv1, vv) * row1
                     + dot(input.patch.fv2, vv) * row2
                     + dot(input.patch.fv3, vv) * row3;

    auto lrgb = nurbs::remove_weight(lrgbw);

    constexpr auto min_lrgb = float3(0.0f);
    constexpr auto max_lrgb = float3(1.0f);

    if ( all(lrgb == clamp(lrgb, min_lrgb, max_lrgb)) )
    {
        return half4( half3(gamma::linear_to_ITUR_2020(lrgb)), 1.0h );
    }
    else
    {
        return { 0.5h, 0.5h, 0.5h, 1.0h };
    }
}

[[mesh]] void bspline_surface_mesh
(
    SurfaceMesh                       output,
    const object_data SurfacePayload& payload [[ payload                     ]],
    ushort                            tid     [[ thread_index_in_threadgroup ]]
)
{
    output.set_primitive_count(2);

    if (tid < 6)
    {
        output.set_vertex(tid, payload.vertices[tid]);
        output.set_index(tid, tid);
    }

    if (tid < 2)
    {
        output.set_primitive(tid, payload.patch);
    }
}

[[object]] void bspline_surface_object
(
    mesh_grid_properties          mesh_grid,
    object_data SurfacePayload&   payload   [[ payload                 ]],
    constant Surface&             surface   [[ buffer(0)               ]],
    texture2d<float,access::read> points    [[ texture(0)              ]],
    ushort3                       tid       [[ thread_position_in_grid ]]
)
{
    if ( 0 < tid.x ) {
        return;
    }

    const auto i = tid.y;
    const auto j = tid.z;

    if (   geometry::width (surface.source_region) - bspline::P <= i
        || geometry::height(surface.source_region) - bspline::P <= j )
    {
        return;
    }

    // • Factors (implicit uniform B-Spline)
    //
    const auto F = bspline::calculate_interval_coefficients(-2.0f, -1.0f, 0.0f, 1.0f, 2.0f, 3.0f);

    payload.patch.fu0 = F.f0;
    payload.patch.fu1 = F.f1;
    payload.patch.fu2 = F.f2;
    payload.patch.fu3 = F.f3;

    payload.patch.fv0 = F.f0;
    payload.patch.fv1 = F.f1;
    payload.patch.fv2 = F.f2;
    payload.patch.fv3 = F.f3;

    // • Points
    //
    const auto x = surface.source_region.left + i;
    const auto y = surface.source_region.top  + j;

    payload.patch.P00 = nurbs::apply_weight( points.read({ x+0u, y+0u }) );
    payload.patch.P01 = nurbs::apply_weight( points.read({ x+1u, y+0u }) );
    payload.patch.P02 = nurbs::apply_weight( points.read({ x+2u, y+0u }) );
    payload.patch.P03 = nurbs::apply_weight( points.read({ x+3u, y+0u }) );

    payload.patch.P10 = nurbs::apply_weight( points.read({ x+0u, y+1u }) );
    payload.patch.P11 = nurbs::apply_weight( points.read({ x+1u, y+1u }) );
    payload.patch.P12 = nurbs::apply_weight( points.read({ x+2u, y+1u }) );
    payload.patch.P13 = nurbs::apply_weight( points.read({ x+3u, y+1u }) );

    payload.patch.P20 = nurbs::apply_weight( points.read({ x+0u, y+2u }) );
    payload.patch.P21 = nurbs::apply_weight( points.read({ x+1u, y+2u }) );
    payload.patch.P22 = nurbs::apply_weight( points.read({ x+2u, y+2u }) );
    payload.patch.P23 = nurbs::apply_weight( points.read({ x+3u, y+2u }) );

    payload.patch.P30 = nurbs::apply_weight( points.read({ x+0u, y+3u }) );
    payload.patch.P31 = nurbs::apply_weight( points.read({ x+1u, y+3u }) );
    payload.patch.P32 = nurbs::apply_weight( points.read({ x+2u, y+3u }) );
    payload.patch.P33 = nurbs::apply_weight( points.read({ x+3u, y+3u }) );

    // • Vertices
    //
    const auto interval_origin = surface.output_origin + uint2{ i, j };
    const auto interval_region = geometry::make_region(interval_origin, { 1, 1});
    const auto interval_rect   = geometry::make_device_rect(interval_region, surface.output_scale);

    const auto x0 = interval_rect.left;
    const auto x1 = interval_rect.right;
    const auto du = 1.0f;
    const auto y0 = interval_rect.top;
    const auto y1 = interval_rect.bottom;
    const auto dv = 1.0f;

    payload.vertices[0] = { .position = { x0, y0, 0.0f, 1.0f }, .u = 0.0f, .v = 0.0f };
    payload.vertices[1] = { .position = { x0, y1, 0.0f, 1.0f }, .u = 0.0f, .v = dv   };
    payload.vertices[2] = { .position = { x1, y0, 0.0f, 1.0f }, .u = du,   .v = 0.0f };

    payload.vertices[3] = { .position = { x1, y0, 0.0f, 1.0f }, .u = du,   .v = 0.0f };
    payload.vertices[4] = { .position = { x0, y1, 0.0f, 1.0f }, .u = 0.0f, .v = dv   };
    payload.vertices[5] = { .position = { x1, y1, 0.0f, 1.0f }, .u = du,   .v = dv   };

    // • One mesh per patch
    //
    mesh_grid.set_threadgroups_per_grid({ 1, 1, 1});
}
