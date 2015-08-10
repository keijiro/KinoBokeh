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
using UnityEngine;

namespace Kino
{
    [ExecuteInEditMode, RequireComponent(typeof(Camera))]
    public class Bokeh : MonoBehaviour
    {
        #region Public Properties

        [SerializeField]
        Transform _subject;

        [SerializeField]
        float _distance = 10.0f;

        [SerializeField]
        float _fNumber = 1.4f;

        [SerializeField]
        bool _useCameraFov = true;

        [SerializeField]
        float _focalLength = 0.05f;

        [SerializeField]
        float _maxBlur = 2;

        public enum SampleCount { Low, Medium, High, UltraHigh }

        [SerializeField]
        public SampleCount _sampleCount = SampleCount.Medium;

        [SerializeField]
        bool _visualize;

        #endregion

        #region Private Properties and Functions

        // Standard film height = 24mm
        const float sensorHeight = 0.024f;

        [SerializeField] Shader _shader;
        Material _material;

        float CalculateSubjectDistance()
        {
            if (_subject == null) return _distance;
            var cam = GetComponent<Camera>().transform;
            return Vector3.Dot(_subject.position - cam.position, cam.forward);
        }

        float CalculateFocalLength()
        {
            if (!_useCameraFov) return _focalLength;
            var fov = GetComponent<Camera>().fieldOfView * Mathf.Deg2Rad;
            return 0.5f * sensorHeight / Mathf.Tan(0.5f * fov);
        }

        void SetUpShaderKeywords()
        {
            if (_sampleCount == SampleCount.Low)
            {
                _material.DisableKeyword("SAMPLES_MEDIUM");
                _material.DisableKeyword("SAMPLES_HIGH");
                _material.DisableKeyword("SAMPLES_ULTRA");
            }
            else if (_sampleCount == SampleCount.Medium)
            {
                _material.EnableKeyword("SAMPLES_MEDIUM");
                _material.DisableKeyword("SAMPLES_HIGH");
                _material.DisableKeyword("SAMPLES_ULTRA");
            }
            else if (_sampleCount == SampleCount.High)
            {
                _material.DisableKeyword("SAMPLES_MEDIUM");
                _material.EnableKeyword("SAMPLES_HIGH");
                _material.DisableKeyword("SAMPLES_ULTRA");
            }
            else // SampleCount.UltraHigh
            {
                _material.DisableKeyword("SAMPLES_MEDIUM");
                _material.DisableKeyword("SAMPLES_HIGH");
                _material.EnableKeyword("SAMPLES_ULTRA");
            }
        }
        
        void SetUpShaderParameters()
        {
            var s1 = CalculateSubjectDistance();
            _material.SetFloat("_SubjectDistance", s1);

            var f = CalculateFocalLength();
            var coeff = f * f / (_fNumber * (s1 - f) * sensorHeight);
            _material.SetFloat("_LensCoeff", coeff);

            _material.SetFloat("_MaxBlur", _maxBlur);
        }

        #endregion

        #region MonoBehaviour Functions

        void OnEnable()
        {
            var cam = GetComponent<Camera>();
            cam.depthTextureMode |= DepthTextureMode.Depth;
        }

        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            if (_material == null)
            {
                _material = new Material(_shader);
                _material.hideFlags = HideFlags.DontSave;
            }

            SetUpShaderKeywords();
            SetUpShaderParameters();

            // Make CoC map in alpha channel.
            Graphics.Blit(source, source, _material, 0);
    
            if (_visualize)
            {
                // CoC visualization.
                Graphics.Blit(source, destination, _material, 1);
            }
            else
            {
                // Create temporary buffers.
                var rt1 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
                var rt2 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
                var rt3 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);

                // 1st separable filter: horizontal blur.
                _material.SetVector("_BlurDisp", new Vector2(1, 0));
                Graphics.Blit(source, rt1, _material, 2);

                // 2nd separable filter: skewed vertical blur (left).
                _material.SetVector("_BlurDisp", new Vector2(-0.5f, -1));
                Graphics.Blit(rt1, rt2, _material, 2);

                // 3rd separable filter: skewed vertical blur (right).
                _material.SetVector("_BlurDisp", new Vector2(0.5f, -1));
                Graphics.Blit(rt1, rt3, _material, 2);

                // Combine the result.
                _material.SetTexture("_BlurTex1", rt2);
                _material.SetTexture("_BlurTex2", rt3);
                Graphics.Blit(source, destination, _material, 3);

                // Release the temporary buffers.
                RenderTexture.ReleaseTemporary(rt1);
                RenderTexture.ReleaseTemporary(rt2);
                RenderTexture.ReleaseTemporary(rt3);
            }
        }

        #endregion
    }
}