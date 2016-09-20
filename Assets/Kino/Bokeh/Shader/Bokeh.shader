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

// The idea of the separable hex bokeh filter came from the paper by
// L. McIntosh (2012). See the following paper for further details.
// http://ivizlab.sfu.ca/media/DiPaolaMcIntoshRiecke2012.pdf

Shader "Hidden/Kino/Bokeh"
{
    Properties
    {
        _MainTex("", 2D) = ""{}
        _BlurTex1("", 2D) = ""{}
        _BlurTex2("", 2D) = ""{}
    }
    Subshader
    {
        // Pass 0 - CoC evaluator (embeds into alpha plane)
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment frag_CoC
            #include "Bokeh.cginc"
            ENDCG
        }
        // Pass 1 - CoC visualization
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment frag_AlphaToGrayscale
            #include "Bokeh.cginc"
            ENDCG
        }
        // Pass 2 - Separable blur filter (without foreground blur)
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment frag_SeparableBlur
            #include "Bokeh.cginc"
            ENDCG
        }
        // Pass 3 - Separable blur filter (with foreground blur)
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment frag_SeparableBlur
            #define FOREGROUND_BLUR
            #include "Bokeh.cginc"
            ENDCG
        }
        // Pass 4 - Final composition
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment frag_Composition
            #include "Bokeh.cginc"
            ENDCG
        }
    }
}
