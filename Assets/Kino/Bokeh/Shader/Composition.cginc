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

half4 frag_Blur(v2f i) : SV_Target
{
    // 9-tap tent filter
    float4 duv = _MainTex_TexelSize.xyxy * float4(1, 1, -1, 0);
    half4 acc;

    half4 c0 = tex2D(_MainTex, i.uv - duv.xy);
    half4 c1 = tex2D(_MainTex, i.uv - duv.wy);
    half4 c2 = tex2D(_MainTex, i.uv - duv.zy);

    half4 c3 = tex2D(_MainTex, i.uv + duv.zw);
    half4 c4 = tex2D(_MainTex, i.uv         );
    half4 c5 = tex2D(_MainTex, i.uv + duv.xw);

    half4 c6 = tex2D(_MainTex, i.uv + duv.zy);
    half4 c7 = tex2D(_MainTex, i.uv + duv.wy);
    half4 c8 = tex2D(_MainTex, i.uv + duv.xy);

    const float bw = 0.5;
    half w0 = (1 - c0.a * bw);
    half w1 = (1 - c1.a * bw) * 2;
    half w2 = (1 - c2.a * bw);

    half w3 = (1 - c3.a * bw) * 2;
    half w4 = (1 - c4.a * bw) * 4;
    half w5 = (1 - c5.a * bw) * 2;

    half w6 = (1 - c6.a * bw);
    half w7 = (1 - c7.a * bw) * 2;
    half w8 = (1 - c8.a * bw);

    acc = c0 * w0 + c1 * w1 + c2 * w2 + c3 * w3 + c4 * w4 + c5 * w5 + c6 * w6 + c7 * w7 + c8 * w8;
    acc /= w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8;

    //acc.a = min(c0.a, min(c1.a, min(c2.a, min(c3.a, min(c4.a, min(c5.a, min(c6.a, min(c7.a, c8.a))))))));

    return acc;
}

// Fragment shader: Upsampling and composition
half4 frag_Composition(v2f i) : SV_Target
{
    half4 acc  = tex2D(_BlurTex, i.uvAlt);

    // Composite with the source image.
    half4 cs = tex2D(_MainTex, i.uv);
#if defined(UNITY_COLORSPACE_GAMMA)
    cs.rgb = GammaToLinearSpace(cs.rgb);
#endif
    half3 rgb = cs * acc.a + acc.rgb;
#if defined(UNITY_COLORSPACE_GAMMA)
    rgb = LinearToGammaSpace(rgb);
#endif

    return half4(rgb, cs.a);
}
