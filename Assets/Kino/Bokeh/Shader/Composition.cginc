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

sampler2D_float _CameraDepthTexture;

// Camera parameters
float _Distance;
float _LensCoeff;  // f^2 / (N * (S1 - f) * film_width * 2)
half _MaxCoC;

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
    half4 cb = tex2D(_BlurTex, i.uvAlt);
#if defined(UNITY_COLORSPACE_GAMMA)
    cs.rgb = GammaToLinearSpace(cs.rgb);
#endif
#if defined(_ALLOW_RESAMPLE_COC)
    // Resample CoC in x1 resolution.
    float d = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uvAlt));
    float coc = (d - _Distance) * _LensCoeff / d;
    // Far field alpha.
    float alpha = smoothstep(_MainTex_TexelSize.y * 2, _MainTex_TexelSize.y * 4, coc);
    // lerp(lerp(cs.rgb, cb.rgb, alpha), cb.rgb, cb.a)
    half3 rgb = lerp(cs.rgb, cb.rgb, alpha + cb.a - alpha * cb.a);
#else
    half3 rgb = cs * cb.a + cb.rgb;
#endif
#if defined(UNITY_COLORSPACE_GAMMA)
    rgb = LinearToGammaSpace(rgb);
#endif

    return half4(rgb, cs.a);
}
