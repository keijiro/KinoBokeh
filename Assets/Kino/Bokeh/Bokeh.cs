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

using UnityEngine;
using System.Collections;

namespace Kino
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    public class Bokeh : MonoBehaviour
    {
        // Reference to the shader.
        [SerializeField] Shader shader;
    
        // Camera parameters.
        public Transform focalTarget;
        public float focalLength = 10.0f;
        public float focalSize = 0.05f;
        public float aperture = 11.5f;
        public bool visualize;
        public bool nearBlur;
    
        // Blur filter settings.
        public enum SampleCount { Low, High }
        public SampleCount sampleCount = SampleCount.High;
        public float sampleDist = 1;
    
        // Temporary objects.
        Material material;
    
        // Calculate the focal point.
        Vector3 focalPoint {
            get {
                if (focalTarget != null)
                    return focalTarget.position;
                else
                    return focalLength * GetComponent<Camera>().transform.forward + GetComponent<Camera>().transform.position;
            }
        }
    
        void OnEnable()
        {
            GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
        }  
    
        void SetUpObjects()
        {
            if (material != null) return;
            material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;
        }
    
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            SetUpObjects();
    
            // Apply the shader variant option.
            if (nearBlur)
                material.EnableKeyword("NEAR_ON");
            else
                material.DisableKeyword("NEAR_ON");
    
            if (sampleCount == SampleCount.High)
                material.EnableKeyword("SAMPLE_HIGH");
            else
                material.DisableKeyword("SAMPLE_HIGH");
    
            // Update the curve parameter.
            var dist01 = GetComponent<Camera>().WorldToViewportPoint(focalPoint).z / (GetComponent<Camera>().farClipPlane - GetComponent<Camera>().nearClipPlane);
            material.SetVector("_CurveParams", new Vector4(focalSize, aperture / 10.0f, dist01, 0));
    
            // Write CoC into the alpha channel.
            Graphics.Blit(source, source, material, 0);
    
            if (visualize)
            {
                // Visualize the CoC.
                Graphics.Blit(source, destination, material, 1);
            }
            else
            {
                var rt1 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
                var rt2 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
                var rt3 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
    
                // 1st separable filter: horizontal blur.
                material.SetVector("_BlurDisp", new Vector4(1, 0, -1, 0) * sampleDist);
                Graphics.Blit(source, rt1, material, 2);
    
                // 2nd separable filter: skewed vertical blur (left).
                material.SetVector("_BlurDisp", new Vector4(-0.5f, -1, 0.5f, 1) * sampleDist);
                Graphics.Blit(rt1, rt2, material, 2);
    
                // 3rd separable filter: skewed vertical blur (right).
                material.SetVector("_BlurDisp", new Vector4(0.5f, -1, -0.5f, 1) * sampleDist);
                Graphics.Blit(rt1, rt3, material, 2);
    
                // Combine the result.
                material.SetTexture("_BlurTex1", rt2);
                material.SetTexture("_BlurTex2", rt3);
    
                Graphics.Blit(source, destination, material, 3);
    
                material.SetTexture("_BlurTex1", null);
                material.SetTexture("_BlurTex2", null);
    
                RenderTexture.ReleaseTemporary(rt1);
                RenderTexture.ReleaseTemporary(rt2);
                RenderTexture.ReleaseTemporary(rt3);
            }
        }
    }
}