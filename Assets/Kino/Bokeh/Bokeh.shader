//
// HexBokeh - A Fast DOF Shader With Hexagonal Apertures
//
// Copyright (C) 2014 Keijiro Takahashi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

//
// This shader is based on McIntosh's paper "Efficiently Simulating the Bokeh of
// Polygonal Apertures in a Post-Process Depth of Field Shader". For further
// details see the paper below.
//
// http://ivizlab.sfu.ca/media/DiPaolaMcIntoshRiecke2012.pdf
//

Shader "Hidden/Kino/Bokeh"
{
    Properties
    {
        _MainTex("-", 2D) = "black"{}
        _BlurTex1("-", 2D) = "black"{}
        _BlurTex2("-", 2D) = "black"{}
    }

    CGINCLUDE

    #include "UnityCG.cginc"

    // Shader variants.
    #pragma multi_compile NEAR_OFF NEAR_ON
    #pragma multi_compile SAMPLE_LOW SAMPLE_HIGH

    // Source image.
    sampler2D _MainTex;
    float4 _MainTex_TexelSize;

    // Blurred image 1 (used only on the combiner)
    sampler2D _BlurTex1;
    float4 _BlurTex1_TexelSize;

    // Blurred image 2 (used only on the combiner)
    sampler2D _BlurTex2;
    float4 _BlurTex2_TexelSize;

    // Camera depth texture.
    sampler2D_float _CameraDepthTexture;

    // Parameters for the CoC writer.
    float3 _CurveParams; // focal_size, 1/aperture, distance01

    // Parameters for the blur filter.
    float4 _BlurDisp;

    //
    // 1st pass - Write CoC into the alpha channel
    //

    float4 frag_write_coc(v2f_img i) : SV_Target
    {
        float d = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.xy));
#ifdef NEAR_ON
        float a = _CurveParams.y * abs(d - _CurveParams.z) / (d + 1e-5f);
#else
        float a = _CurveParams.y * (d - _CurveParams.z) / (d + 1e-5f);
#endif
        return float4(0, 0, 0, saturate(a - _CurveParams.x));
    }

    //
    // 2nd pass - Visualize CoC
    //

    float4 frag_alpha_to_grayscale(v2f_img i) : SV_Target
    {
        float a = tex2D(_MainTex, i.uv).a;
        return float4(a, a, a, a);
    }

    //
    // 3rd pass - Separable blur filter
    //

    struct v2f_blur
    {
        float4 pos   : SV_POSITION;
        float2 uv    : TEXCOORD0;
        float4 uv_12 : TEXCOORD1;
        float4 uv_34 : TEXCOORD2;
        float4 uv_56 : TEXCOORD3;
#ifdef SAMPLE_HIGH
        float4 uv_78 : TEXCOORD4;
        float4 uv_9a : TEXCOORD5;
        float4 uv_bc : TEXCOORD6;
#endif
    };

    v2f_blur vert_blur(appdata_img v)
    {
        v2f_blur o;

        o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

        float4 uv = v.texcoord.xyxy;
        float4 d = _MainTex_TexelSize.xyxy * _BlurDisp;

        o.uv    = uv;
        o.uv_12 = uv + d;
        o.uv_34 = uv + d * 2;
        o.uv_56 = uv + d * 3;
#ifdef SAMPLE_HIGH
        o.uv_78 = uv + d * 4;
        o.uv_9a = uv + d * 5;
        o.uv_bc = uv + d * 6;
#endif

        return o;
    }

    float4 frag_blur(v2f_blur i) : SV_Target 
    {
        float4 c  = tex2D(_MainTex, i.uv);
        float4 c1 = tex2D(_MainTex, i.uv_12.xy);
        float4 c2 = tex2D(_MainTex, i.uv_12.zw);
        float4 c3 = tex2D(_MainTex, i.uv_34.xy);
        float4 c4 = tex2D(_MainTex, i.uv_34.zw);
        float4 c5 = tex2D(_MainTex, i.uv_56.xy);
        float4 c6 = tex2D(_MainTex, i.uv_56.zw);
#ifdef SAMPLE_HIGH
        float4 c7 = tex2D(_MainTex, i.uv_78.xy);
        float4 c8 = tex2D(_MainTex, i.uv_78.zw);
        float4 c9 = tex2D(_MainTex, i.uv_9a.xy);
        float4 ca = tex2D(_MainTex, i.uv_9a.zw);
        float4 cb = tex2D(_MainTex, i.uv_bc.xy);
        float4 cc = tex2D(_MainTex, i.uv_bc.zw);
#endif

        float s = 1;
        float a = c.a;

#ifdef NEAR_ON

        float d  = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
        float d1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_12.xy);
        float d2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_12.zw);
        float d3 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_34.xy);
        float d4 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_34.zw);
        float d5 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_56.xy);
        float d6 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_56.zw);
#ifdef SAMPLE_HIGH
        float d7 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_78.xy);
        float d8 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_78.zw);
        float d9 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_9a.xy);
        float da = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_9a.zw);
        float db = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_bc.xy);
        float dc = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_bc.zw);
#endif

        if ((d1 <= d ? c1.a : min(c1.a, a)) > 1.0 / 7 * 1) { c += c1; s += 1; }
        if ((d2 <= d ? c2.a : min(c2.a, a)) > 1.0 / 7 * 1) { c += c2; s += 1; }
        if ((d3 <= d ? c3.a : min(c3.a, a)) > 1.0 / 7 * 2) { c += c3; s += 1; }
        if ((d4 <= d ? c4.a : min(c4.a, a)) > 1.0 / 7 * 2) { c += c4; s += 1; }
        if ((d5 <= d ? c5.a : min(c5.a, a)) > 1.0 / 7 * 3) { c += c5; s += 1; }
        if ((d6 <= d ? c6.a : min(c6.a, a)) > 1.0 / 7 * 3) { c += c6; s += 1; }
#ifdef SAMPLE_HIGH
        if ((d7 <= d ? c7.a : min(c7.a, a)) > 1.0 / 7 * 4) { c += c7; s += 1; }
        if ((d8 <= d ? c8.a : min(c8.a, a)) > 1.0 / 7 * 4) { c += c8; s += 1; }
        if ((d9 <= d ? c9.a : min(c9.a, a)) > 1.0 / 7 * 5) { c += c9; s += 1; }
        if ((da <= d ? ca.a : min(ca.a, a)) > 1.0 / 7 * 5) { c += ca; s += 1; }
        if ((db <= d ? cb.a : min(cb.a, a)) > 1.0 / 7 * 6) { c += cb; s += 1; }
        if ((dc <= d ? cc.a : min(cc.a, a)) > 1.0 / 7 * 6) { c += cc; s += 1; }
#endif

#else // NEAR_ON

        if (min(c1.a, a) > 1.0 / 7 * 1) { c += c1; s += 1; }
        if (min(c2.a, a) > 1.0 / 7 * 1) { c += c2; s += 1; }
        if (min(c3.a, a) > 1.0 / 7 * 2) { c += c3; s += 1; }
        if (min(c4.a, a) > 1.0 / 7 * 2) { c += c4; s += 1; }
        if (min(c5.a, a) > 1.0 / 7 * 3) { c += c5; s += 1; }
        if (min(c6.a, a) > 1.0 / 7 * 3) { c += c6; s += 1; }
#ifdef SAMPLE_HIGH
        if (min(c7.a, a) > 1.0 / 7 * 4) { c += c7; s += 1; }
        if (min(c8.a, a) > 1.0 / 7 * 4) { c += c8; s += 1; }
        if (min(c9.a, a) > 1.0 / 7 * 5) { c += c9; s += 1; }
        if (min(ca.a, a) > 1.0 / 7 * 5) { c += ca; s += 1; }
        if (min(cb.a, a) > 1.0 / 7 * 6) { c += cb; s += 1; }
        if (min(cc.a, a) > 1.0 / 7 * 6) { c += cc; s += 1; }
#endif

#endif // NEAR_ON

        return c / s;
    }

    //
    // 4th pass - Combiner
    //

    float4 frag_combiner(v2f_img i) : SV_Target 
    {
        float4 c1 = tex2D(_BlurTex1, i.uv);
        float4 c2 = tex2D(_BlurTex2, i.uv);
        return min(c1, c2);
    }

    ENDCG 

    Subshader
    {
        // 0: CoC
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            ColorMask A
            Fog { Mode off }      
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_write_coc
            ENDCG
        }

        // 1: CoC visualizer
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Fog { Mode off }      
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_alpha_to_grayscale
            ENDCG
        }

        // 2: Separable blur filter
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Fog { Mode off }      
            CGPROGRAM
            #pragma glsl
            #pragma target 3.0
            #pragma vertex vert_blur
            #pragma fragment frag_blur
            ENDCG
        }

        // 3: Combiner
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Fog { Mode off }      
            CGPROGRAM
            #pragma glsl
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment frag_combiner
            #pragma glsl
            ENDCG
        }
    }
}
