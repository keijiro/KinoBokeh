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

// TileMax filter parameters
float2 _TileMaxOffs;
int _TileMaxLoop;

// CoC radius calculation
float CalculateCoC(float2 uv)
{
    // Calculate the radius of CoC.
    // https://en.wikipedia.org/wiki/Circle_of_confusion
    float d = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
    float coc = (d - _Distance) * _LensCoeff / d;
    return clamp(coc, -_MaxCoC, _MaxCoC);
}

// Compare two CoC value sets and returns the nearest/farest values.
half2 MaxCoC(half2 coc1, half2 coc2)
{
    return half2(min(coc1.x, coc2.x), max(coc1.y, coc2.y));
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

// Fragment shader: TileMax filter (horizontal pass)
half4 frag_TileMax1(v2f_img i) : SV_Target
{
    float2 uv = i.uv + float2(_MainTex_TexelSize.x * _TileMaxOffs.x, 0);
    half2 coc = half2(1.0e+5, -1e+5);

    for (int ix = 0; ix < _TileMaxLoop; ix++)
    {
        coc = MaxCoC(coc, tex2Dlod(_MainTex, float4(uv, 0, 0)).w);
        uv.x += _MainTex_TexelSize.x;
    }

    return half4(coc, 0, 0);
}

// Fragment shader: TileMax filter (vertical pass)
half4 frag_TileMax2(v2f_img i) : SV_Target
{
    float2 uv = i.uv + float2(0, _MainTex_TexelSize.y * _TileMaxOffs.y);
    half2 coc = half2(1.0e+5, -1e+5);

    for (int iy = 0; iy < _TileMaxLoop; iy++)
    {
        coc = MaxCoC(coc, tex2Dlod(_MainTex, float4(uv, 0, 0)).xy);
        uv.y += _MainTex_TexelSize.y;
    }

    return half4(coc, 0, 0);
}

// Fragment shader: NeighborMax filter
half4 frag_NeighborMax(v2f_img i) : SV_Target
{
    float4 d = _MainTex_TexelSize.xyxy * float4(1, 1, -1, 0);

    half2 v1 = tex2D(_MainTex, i.uv - d.xy).rg;
    half2 v2 = tex2D(_MainTex, i.uv - d.wy).rg;
    half2 v3 = tex2D(_MainTex, i.uv - d.zy).rg;

    half2 v4 = tex2D(_MainTex, i.uv - d.xw).rg;
    half2 v5 = tex2D(_MainTex, i.uv       ).rg;
    half2 v6 = tex2D(_MainTex, i.uv + d.xw).rg;

    half2 v7 = tex2D(_MainTex, i.uv + d.zy).rg;
    half2 v8 = tex2D(_MainTex, i.uv + d.wy).rg;
    half2 v9 = tex2D(_MainTex, i.uv + d.xy).rg;

    half2 va = MaxCoC(v1, MaxCoC(v2, v3));
    half2 vb = MaxCoC(v4, MaxCoC(v5, v6));
    half2 vc = MaxCoC(v7, MaxCoC(v8, v9));

    return half4(MaxCoC(va, MaxCoC(vb, vc)), 0, 0);
}

// Fragment shader: Debug visualization
half4 frag_Debug(v2f_img i) : SV_Target
{
    half4 src = tex2D(_MainTex, i.uv);

    // CoC radius
    half coc = src.a / _MaxCoC;

    // Visualize CoC (blue -> red -> green)
    half3 rgb = lerp(half3(1, 0, 0), half3(0.8, 0.8, 1), max(0, -coc));
    rgb = lerp(rgb, half3(0.8, 1, 0.8), max(0, coc));

    // Black and white image overlay
    rgb *= dot(src.rgb, 0.5 / 3) + 0.5;

    // Gamma correction
    rgb = lerp(rgb, GammaToLinearSpace(rgb), unity_ColorSpaceLuminance.w);

    return half4(rgb, 1);
}
