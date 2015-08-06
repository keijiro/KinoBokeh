//
// KinoBokeh - Fast DOF Shader With Hexagonal Apertures
//
// Copyright (C) 2015 Keijiro Takahashi
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
// This shader is based on the paper by L. McIntosh (2012). See the following
// paper for further details.
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

    #pragma multi_compile SAMPLES_LOW SAMPLES_MEDIUM SAMPLES_HIGH SAMPLES_ULTRA

#if SAMPLES_LOW
    static const int BLUR_STEP = 5;
#elif SAMPLES_MEDIUM
    static const int BLUR_STEP = 10;
#elif SAMPLES_HIGH
    static const int BLUR_STEP = 15;
#else
    static const int BLUR_STEP = 20;
#endif

    // Source image
    sampler2D _MainTex;
    float4 _MainTex_TexelSize;

    // Blurred image 1
    sampler2D _BlurTex1;
    float4 _BlurTex1_TexelSize;

    // Blurred image 2
    sampler2D _BlurTex2;
    float4 _BlurTex2_TexelSize;

    // Camera depth texture.
    sampler2D_float _CameraDepthTexture;

    // CoC parameters
    float3 _CurveParams; // (focal length, aperture size, focal dist in 0-1)

    // Displacement vector for the blur filter
    float2 _BlurDisp;

    // 1st pass - make CoC map in alpha plane
    half4 frag_make_coc(v2f_img i) : SV_Target
    {
        float d = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
        float a = _CurveParams.y * abs(d - _CurveParams.z) / (d + 1e-5f);
        return half4(0, 0, 0, saturate(a - _CurveParams.x));
    }

    // 2nd pass - CoC visualization
    half4 frag_alpha_to_grayscale(v2f_img i) : SV_Target
    {
        return (half4)tex2D(_MainTex, i.uv).a;
    }

    // 3rd pass - separable blur filter
    float4 frag_blur(v2f_img i) : SV_Target 
    {
        float4 acc = tex2D(_MainTex, i.uv);
        float total = 1;

        float a0 = acc.a;
        float d0 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);

        for (int di = 1; di < BLUR_STEP; di++)
        {
            float2 uv1 = i.uv - _BlurDisp * _MainTex_TexelSize.xy * di;
            float2 uv2 = i.uv + _BlurDisp * _MainTex_TexelSize.xy * di;

            float4 c1 = tex2D(_MainTex, uv1);
            float4 c2 = tex2D(_MainTex, uv2);

            float d1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv1);
            float d2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv2);

            if ((d1 <= d0 ? c1.a : min(c1.a, a0)) > (float)di / BLUR_STEP) {
                acc += c1;
                total += 1;
            }
            
            if ((d2 <= d0 ? c2.a : min(c2.a, a0)) > (float)di / BLUR_STEP) {
                acc += c2;
                total += 1;
            }
        }

        return acc / total;
    }

    // 4th pass - combiner
    float4 frag_combiner(v2f_img i) : SV_Target 
    {
        float4 c1 = tex2D(_BlurTex1, i.uv);
        float4 c2 = tex2D(_BlurTex2, i.uv);
        return min(c1, c2);
    }

    ENDCG 

    Subshader
    {
        Pass
        {
            ColorMask A
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_make_coc
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_alpha_to_grayscale
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment frag_blur
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_combiner
            ENDCG
        }
    }
}
