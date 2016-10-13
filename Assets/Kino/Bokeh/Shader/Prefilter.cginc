//
// Kino/Bokeh - Depth of field effect
//
// Copyright (C) 2015, 2016 Keijiro Takahashi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#include "UnityCG.cginc"

// Source textures
sampler2D _MainTex;
float4 _MainTex_TexelSize;

sampler2D_float _CameraDepthTexture;

// Camera parameters
float _Distance;
float _LensCoeff;  // f^2 / (N * (S1 - f) * film_width * 2)
half _MaxCoC;
half _RcpMaxCoC;

// Max between three components
half max3(half3 xyz) { return max(xyz.x, max(xyz.y, xyz.z)); }

// Fragment shader: Downsampling, prefiltering and CoC calculation
half4 frag_Prefilter(v2f_img i) : SV_Target
{
    // Sampling positions of neighbor four pixels
    float2 uv0 = i.uv + _MainTex_TexelSize.xy * float2(-0.5, -0.5);
    float2 uv1 = i.uv + _MainTex_TexelSize.xy * float2(+0.5, -0.5);
    float2 uv2 = i.uv + _MainTex_TexelSize.xy * float2(-0.5, +0.5);
    float2 uv3 = i.uv + _MainTex_TexelSize.xy * float2(+0.5, +0.5);

    // Sample source colors.
    half3 c0 = tex2D(_MainTex, uv0).rgb;
    half3 c1 = tex2D(_MainTex, uv1).rgb;
    half3 c2 = tex2D(_MainTex, uv2).rgb;
    half3 c3 = tex2D(_MainTex, uv3).rgb;

    // Sample linear depths.
    float d0 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv0));
    float d1 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv1));
    float d2 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv2));
    float d3 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv3));
    float4 depths = float4(d0, d1, d2, d3);

    // Calculate the radiuses of CoCs at these sample points.
    half4 cocs = (depths - _Distance) * _LensCoeff / depths;
    cocs = clamp(cocs, -_MaxCoC, _MaxCoC);

    // Premultiply CoC to reduce background bleeding.
    half4 weights = saturate(abs(cocs) * _RcpMaxCoC);

#if defined(PREFILTER_LUMA_WEIGHT)
    // Apply luma weights to reduce flickering.
    // Inspired by goo.gl/j1fhLe goo.gl/mfuZ4h
    weights.x *= 1 / (max3(c0) + 1);
    weights.y *= 1 / (max3(c1) + 1);
    weights.z *= 1 / (max3(c2) + 1);
    weights.w *= 1 / (max3(c3) + 1);
#endif

    // Weighted average of the color samples
    half3 avg = c0 * weights.x + c1 * weights.y + c2 * weights.z + c3 * weights.w;
    avg /= dot(weights, 1);

    // Output CoC = average of CoCs
    half coc = dot(cocs, 0.25);

    return half4(avg, coc);
}
