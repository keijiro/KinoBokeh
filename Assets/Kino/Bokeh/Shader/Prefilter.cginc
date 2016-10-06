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

// Fragment shader: Prefilter (downsampling and CoC calculation)
half4 frag_Prefilter(v2f_img i) : SV_Target
{
    float4 duv = _MainTex_TexelSize.xyxy * float4(1, 1, -1, 0) * 2;

    half3 acc;

    acc  = tex2D(_MainTex, i.uv - duv.xy).rgb;
    acc += tex2D(_MainTex, i.uv - duv.wy).rgb * 2;
    acc += tex2D(_MainTex, i.uv - duv.zy).rgb;

    acc += tex2D(_MainTex, i.uv - duv.xw).rgb * 2;
    acc += tex2D(_MainTex, i.uv         ).rgb * 4;
    acc += tex2D(_MainTex, i.uv + duv.xw).rgb * 2;

    acc += tex2D(_MainTex, i.uv + duv.zy).rgb;
    acc += tex2D(_MainTex, i.uv + duv.wy).rgb * 2;
    acc += tex2D(_MainTex, i.uv + duv.xy).rgb;

    return half4(acc / 16, CalculateCoC(i.uv));
}
