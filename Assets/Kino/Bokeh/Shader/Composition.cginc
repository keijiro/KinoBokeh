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

#include "Common.cginc"

sampler2D _BlurTex;
float4 _BlurTex_TexelSize;

// Fragment shader: Upsampling and composition
half4 frag_Composition(v2f i) : SV_Target
{
    // 9-tap tent filter
    float4 duv = _BlurTex_TexelSize.xyxy * float4(1, 1, -1, 0);
    half4 acc;

    acc  = tex2D(_BlurTex, i.uvAlt - duv.xy);
    acc += tex2D(_BlurTex, i.uvAlt - duv.wy) * 2;
    acc += tex2D(_BlurTex, i.uvAlt - duv.zy);

    acc += tex2D(_BlurTex, i.uvAlt + duv.zw) * 2;
    acc += tex2D(_BlurTex, i.uvAlt         ) * 4;
    acc += tex2D(_BlurTex, i.uvAlt + duv.xw) * 2;

    acc += tex2D(_BlurTex, i.uvAlt + duv.zy);
    acc += tex2D(_BlurTex, i.uvAlt + duv.wy) * 2;
    acc += tex2D(_BlurTex, i.uvAlt + duv.xy);

    acc /= 16;

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
