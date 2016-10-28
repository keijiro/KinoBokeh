//
// Kino/Bokeh - Depth of field effect
//
// Copyright (C) 2016 Unity Technologies
// Copyright (C) 2015 Keijiro Takahashi
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

#include "Common.cginc"

sampler2D _BlurTex;
float4 _BlurTex_TexelSize;

// Fragment shader: Additional blur
half4 frag_Blur2(v2f i) : SV_Target
{
    // 9-tap tent filter
    float4 duv = _MainTex_TexelSize.xyxy * float4(1, 1, -1, 0);
    half4 acc;

    acc  = tex2D(_MainTex, i.uv - duv.xy);
    acc += tex2D(_MainTex, i.uv - duv.wy) * 2;
    acc += tex2D(_MainTex, i.uv - duv.zy);

    acc += tex2D(_MainTex, i.uv + duv.zw) * 2;
    acc += tex2D(_MainTex, i.uv         ) * 4;
    acc += tex2D(_MainTex, i.uv + duv.xw) * 2;

    acc += tex2D(_MainTex, i.uv + duv.zy);
    acc += tex2D(_MainTex, i.uv + duv.wy) * 2;
    acc += tex2D(_MainTex, i.uv + duv.xy);

    return acc / 16;
}

// Fragment shader: Upsampling and composition
half4 frag_Composition(v2f i) : SV_Target
{
    half4 cs = tex2D(_MainTex, i.uv);
#if 1
    float2 uv = i.uv * _MainTex_TexelSize.zw - 0.5;
    float2 iuv = floor(uv);// + 0.5;
    float2 f = uv - iuv;
    float2 f2 = f * f;
    float2 f3 = f2 * f;

    float2 nf = 1 - f;
    float2 nf2 = nf * nf;
    float2 nf3 = nf2 * nf;

    float2 w0 = nf3 / 6;
    float2 w1 = 0.66666 + 0.5 * f3 - f2;
    float2 w2 = 0.66666 + 3.0 * w0 - nf2;
    float2 w3 = f3 * 0.16666;

    float2 s0 = w0 + w1;
    float2 s1 = w2 + w3;

    float2 f0 = w1 / (w0 + w1);
    float2 f1 = w3 / (w2 + w3);
    float2 t0 = (iuv - 0.5 + f0) * _MainTex_TexelSize.xy;
    float2 t1 = (iuv + 1.5 + f1) * _MainTex_TexelSize.xy;

    half4 cb =
    (tex2D(_BlurTex, float2(t0.x, t0.y)) * s0.x +
     tex2D(_BlurTex, float2(t1.x, t0.y)) * s1.x) * s0.y +
    (tex2D(_BlurTex, float2(t0.x, t1.y)) * s0.x +
     tex2D(_BlurTex, float2(t1.x, t1.y)) * s1.x) * s1.y;
#else
    half4 cb = tex2D(_BlurTex, i.uvAlt);
#endif
#if defined(UNITY_COLORSPACE_GAMMA)
    cs.rgb = GammaToLinearSpace(cs.rgb);
#endif
    half3 rgb = cs * cb.a + cb.rgb;
#if defined(UNITY_COLORSPACE_GAMMA)
    rgb = LinearToGammaSpace(rgb);
#endif

    return half4(rgb, cs.a);
}
