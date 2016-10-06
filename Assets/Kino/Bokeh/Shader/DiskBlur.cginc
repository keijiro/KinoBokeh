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
#include "DiskKernel.cginc"

// Source textures
sampler2D _MainTex;
float4 _MainTex_TexelSize;

sampler2D _BlurTex;
float4 _BlurTex_TexelSize;

// Camera parameters
float _InvAspect;
float _MaxCoC;

// Fragment shader: Bokeh filter with disk-shaped kernels
half4 frag_Blur(v2f_img i) : SV_Target
{
    half4 samp0 = tex2D(_MainTex, i.uv);

    half4 bgAcc = 0;
    half4 fgAcc = 0;

    for (int si = 0; si < kSampleCount; si++)
    {
        float2 disp = kDiskKernel[si] * _MaxCoC;
        float dist = length(disp);

        float2 duv = float2(disp.x * _InvAspect, disp.y);
        half4 samp = tex2D(_MainTex, i.uv + duv);

        // BG: Compare CoC of the current sample and the center sample.
        // Select smaller one.
        half bgCoC = max(min(samp0.a, samp.a), 0);

        // BG: Compare the CoC to the sample distance.
        // Add a small margin to smooth out.
        half bgWeight = saturate((bgCoC - dist + 0.005) / 0.01);

        // FG: Calculate the area of CoC and normalize it.
        half fgWeight = -samp.a * max(-samp.a, 0) * UNITY_PI;
        fgWeight /= _MaxCoC * _MaxCoC * kSampleCount;

        // FG: Compare the CoC to the sample distance.
        // Add a small margin to smooth out.
        fgWeight *= saturate((-samp.a - dist + 0.005) / 0.01);

        // Accumulation
        bgAcc += half4(samp.rgb, 1) * bgWeight;
        fgAcc += half4(samp.rgb, 1) * fgWeight;
    }

    // Get the weighted average.
    bgAcc.rgb /= bgAcc.a + (bgAcc.a == 0); // zero-div guard
    fgAcc.rgb /= fgAcc.a + (fgAcc.a == 0);

    // Distance based alpha
    half distAlpha = samp0.a * abs(samp0.a) / (3 * _MaxCoC * _MaxCoC * _MaxCoC);
    bgAcc.a = saturate(distAlpha);                // BG: Always apply distAlpha

    // Alpha premultiplying
    half3 rgb = 0;
    rgb = lerp(rgb, bgAcc.rgb, saturate(bgAcc.a));
    rgb = lerp(rgb, fgAcc.rgb, saturate(fgAcc.a));

    // Combined alpha value
    half alpha = (1 - saturate(bgAcc.a)) * (1 - saturate(fgAcc.a));

    return half4(rgb, alpha);
}

// Fragment shader: Final composition
half4 frag_Composite(v2f_img i) : SV_Target
{
    half4 cs = tex2D(_MainTex, i.uv);
    half4 cb = tex2D(_BlurTex, i.uv);
    half3 rgb = cs * cb.a + cb.rgb;
    return half4(rgb, cs.a);
}
