//
// KinoBokeh - Fast DOF filter with hexagonal aperture
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

// The idea of the separable hex bokeh filter came from the paper by
// L. McIntosh (2012). See the following paper for further details.
// http://ivizlab.sfu.ca/media/DiPaolaMcIntoshRiecke2012.pdf

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

    sampler2D _MainTex;
    sampler2D_float _CameraDepthTexture;

    // Only used in the combiner pass.
    sampler2D _BlurTex1;
    sampler2D _BlurTex2;

    // Camera parameters
    float _SubjectDistance;
    float _LensCoeff;  // f^2 / (N * (S1 - f) * film_width)

    // Blur parameters
    float2 _BlurDisp;
    float _MaxBlur;

    // 1st pass - make CoC map in alpha plane
    half4 frag_make_coc(v2f_img i) : SV_Target
    {
        float d = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
        float a = abs(d - _SubjectDistance) * _LensCoeff / d;
        return half4(0, 0, 0, a);
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

        float2 aspect = float2(_ScreenParams.y / _ScreenParams.x, 1);
        float2 disp = _BlurDisp * _MaxBlur * 0.5 / BLUR_STEP;

        for (int di = 1; di < BLUR_STEP; di++)
        {
            float offs = length(disp * di);
            float2 uv1 = i.uv - disp * aspect * di;
            float2 uv2 = i.uv + disp * aspect * di;

            float4 c1 = tex2D(_MainTex, uv1);
            float4 c2 = tex2D(_MainTex, uv2);

            float d1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv1);
            float d2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv2);

            if ((d1 <= d0 ? c1.a : min(c1.a, a0)) > offs) {
                acc += c1;
                total += 1;
            }

            if ((d2 <= d0 ? c2.a : min(c2.a, a0)) > offs) {
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
