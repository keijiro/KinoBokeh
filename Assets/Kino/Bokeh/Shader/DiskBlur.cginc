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

sampler2D _TileTex;
float4 _TileTex_TexelSize;

sampler2D _BlurTex;
float4 _BlurTex_TexelSize;

// Camera parameters
float _InvAspect;
float _MaxCoC;

half4 frag_Blur(v2f_img i) : SV_Target
{
    half4 samp0 = tex2D(_MainTex, i.uv);
    half2 tile0 = tex2D(_TileTex, i.uv);

    half maxCoC = max(-tile0.x, tile0.y);

    half4 bgAcc = 0;
    half4 fgAcc = 0;

    for (int si = 0; si < kSampleCount; si++)
    {
        float2 disp = kDiskKernel[si] * maxCoC;
        float dist = length(disp);

        float2 duv = float2(disp.x * _InvAspect, disp.y);
        half4 samp = tex2D(_MainTex, i.uv + duv);

        // BG: Select the smaller CoC.
        half bgWeight = max(min(samp0.a, samp.a), 0);
        // BG: Compare the CoC to the sample distance with a small margin.
        bgWeight = saturate((bgWeight - dist + 0.01) / 0.01);

        // FG: CoC area
        half fgWeight = -samp.a * max(-samp.a, 0);
        fgWeight /= _MaxCoC * _MaxCoC * kSampleCount;
        fgWeight = saturate(fgWeight * 2);
        // FG: Compare the CoC to the sample distance with a small toe.
        fgWeight *= pow(saturate((maxCoC - dist) / (maxCoC - abs(samp.a))), 6);

        // Accumulation
        bgAcc += half4(samp.rgb, 1) * bgWeight;
        fgAcc += half4(samp.rgb, 1) * fgWeight;
    }

    // Get weighted average.
    bgAcc.rgb /= bgAcc.a + (bgAcc.a == 0); // avoiding zero-div
    fgAcc.rgb /= fgAcc.a + (fgAcc.a == 0);

    // BG: Distance based alpha
    bgAcc.a = saturate(samp0.a * abs(samp0.a) / (_MaxCoC * _MaxCoC * _MaxCoC));

    // Alpha premultiplying
    half3 rgb = 0;
    rgb = lerp(rgb, bgAcc.rgb, saturate(bgAcc.a));
    rgb = lerp(rgb, fgAcc.rgb, saturate(fgAcc.a));

    // Combined alpha value
    half alpha = (1 - saturate(bgAcc.a)) * (1 - saturate(fgAcc.a));

    return half4(rgb, alpha);
}

half4 frag_Composite(v2f_img i) : SV_Target
{
    half4 cs = tex2D(_MainTex, i.uv);
    half4 cb = tex2D(_BlurTex, i.uv);

    half3 rgb = cs * cb.a + cb.rgb;

    return half4(rgb, cs.a);
}
