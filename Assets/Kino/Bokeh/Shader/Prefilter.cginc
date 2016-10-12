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
half _Distance;
half _LensCoeff;  // f^2 / (N * (S1 - f) * film_width * 2)
half _MaxCoC;

// CoC radius calculation
float CalculateCoC(float2 uv)
{
    // Calculate the radius of CoC.
    // https://en.wikipedia.org/wiki/Circle_of_confusion
    float d = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
    float coc = (d - _Distance) * _LensCoeff / d;
    return clamp(coc, -_MaxCoC, _MaxCoC);
}

float SelectLarger(float x, float y)
{
    return abs(x) > abs(y) ? x : y;
}

// Fragment shader: Downsampling and CoC calculation
half4 frag_Prefilter(v2f_img i) : SV_Target
{
    float2 uv0 = i.uv + _MainTex_TexelSize.xy * float2(-0.5, -0.5);
    float2 uv1 = i.uv + _MainTex_TexelSize.xy * float2(+0.5, -0.5);
    float2 uv2 = i.uv + _MainTex_TexelSize.xy * float2(-0.5, +0.5);
    float2 uv3 = i.uv + _MainTex_TexelSize.xy * float2(+0.5, +0.5);

    half3 c0 = tex2D(_MainTex, uv0).rgb;
    half3 c1 = tex2D(_MainTex, uv1).rgb;
    half3 c2 = tex2D(_MainTex, uv2).rgb;
    half3 c3 = tex2D(_MainTex, uv3).rgb;

    c0 = min(c0, 8);
    c1 = min(c1, 8);
    c2 = min(c2, 8);
    c3 = min(c3, 8);

    float coc0 = CalculateCoC(uv0);
    float coc1 = CalculateCoC(uv1);
    float coc2 = CalculateCoC(uv2);
    float coc3 = CalculateCoC(uv3);

    float w0 = smoothstep(0, _MaxCoC, abs(coc0));
    float w1 = smoothstep(0, _MaxCoC, abs(coc1));
    float w2 = smoothstep(0, _MaxCoC, abs(coc2));
    float w3 = smoothstep(0, _MaxCoC, abs(coc3));

    half3 avg = (c0 * w0 + c1 * w1 + c2 * w2 + c3 * w3) / (w0 + w1 + w2 + w3);
    float coc = (coc0 + coc1 + coc2 + coc3) * 0.25;

    return half4(avg, coc);
}
