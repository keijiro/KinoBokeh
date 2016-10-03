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
using UnityEngine;

namespace Kino
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    public class Bokeh : MonoBehaviour
    {
        #region Editable properties

        [SerializeField]
        Transform _subject;

        public Transform subject {
            get { return _subject; }
            set { _subject = value; }
        }

        [SerializeField]
        float _distance = 10.0f;

        public float distance {
            get { return _distance; }
            set { _distance = value; }
        }

        [SerializeField]
        float _fNumber = 1.4f;

        public float fNumber {
            get { return _fNumber; }
            set { _fNumber = value; }
        }

        [SerializeField]
        bool _useCameraFov = true;

        public bool useCameraFov {
            get { return _useCameraFov; }
            set { _useCameraFov = value; }
        }

        [SerializeField]
        float _focalLength = 0.05f;

        public float focalLength {
            get { return _focalLength; }
            set { _focalLength = value; }
        }

        [SerializeField]
        float _maxBlur = 0.03f;

        public float maxBlur {
            get { return _maxBlur; }
            set { _maxBlur = value; }
        }

        public enum SampleCount { Low, Medium, High, VeryHigh }

        [SerializeField]
        public SampleCount _sampleCount = SampleCount.Medium;

        public SampleCount sampleCount {
            get { return _sampleCount; }
            set { _sampleCount = value; }
        }

        [SerializeField]
        bool _visualize;

        #endregion

        #region Private members

        // Standard film width = 24mm
        const float filmWidth = 0.024f;

        [SerializeField] Shader _shader;
        Material _material;

        Camera TargetCamera {
            get { return GetComponent<Camera>(); }
        }

        RenderTexture GetTemporaryRT(Texture source, int divider, RenderTextureFormat format)
        {
            var w = source.width / divider;
            var h = source.height / divider;
            var rt = RenderTexture.GetTemporary(w, h, 0, format);
            rt.filterMode = FilterMode.Point;
            return rt;
        }

        void ReleaseTemporaryRT(RenderTexture rt)
        {
            RenderTexture.ReleaseTemporary(rt);
        }

        float CalculateSubjectDistance()
        {
            if (_subject == null) return _distance;
            var cam = TargetCamera.transform;
            return Vector3.Dot(_subject.position - cam.position, cam.forward);
        }

        float CalculateFocalLength()
        {
            if (!_useCameraFov) return _focalLength;
            var fov = TargetCamera.fieldOfView * Mathf.Deg2Rad;
            return 0.5f * filmWidth / Mathf.Tan(0.5f * fov);
        }

        void SetUpShaderParameters(RenderTexture source)
        {
            var s1 = CalculateSubjectDistance();
            _material.SetFloat("_SubjectDistance", s1);

            var f = CalculateFocalLength();
            var coeff = f * f / (_fNumber * (s1 - f) * filmWidth);
            _material.SetFloat("_LensCoeff", coeff);

            var aspect = new Vector2((float)source.height / source.width, 1);
            _material.SetVector("_Aspect", aspect);

            _material.SetFloat("_MaxCoC", _maxBlur * 0.5f);
        }

        #endregion

        #region MonoBehaviour functions

        void OnEnable()
        {
            TargetCamera.depthTextureMode |= DepthTextureMode.Depth;
        }

        void OnDestroy()
        {
            if (_material != null)
                if (Application.isPlaying)
                    Destroy(_material);
                else
                    DestroyImmediate(_material);
        }

        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            var rgHalf = RenderTextureFormat.RGHalf;

            if (_material == null) {
                _material = new Material(Shader.Find("Hidden/Kino/Bokeh"));
                _material.hideFlags = HideFlags.HideAndDontSave;
            }

            // Set up the shader parameters.
            SetUpShaderParameters(source);

            // Calculate the maximum blur radius in pixels.
            var maxBlurPixels = (int)(_maxBlur * 0.5f * source.height);

            // Calculate the TileMax size.
            // It should be a multiple of 8 and larger than maxBlur.
            var tileSize = ((maxBlurPixels - 1) / 8 + 1) * 8;

            // 1st pass - CoC estimation
            var rtCoC = GetTemporaryRT(source, 1, source.format);
            Graphics.Blit(source, rtCoC, _material, 0);

            // Half-res source
            var rtHalf = GetTemporaryRT(source, 2, source.format);
            rtCoC.filterMode = FilterMode.Bilinear;
            Graphics.Blit(rtCoC, rtHalf, _material, 3);

            // 2nd pass - TileMax filter
            var tileMaxOffs = Vector2.one * (tileSize - 1) * -0.5f;
            _material.SetVector("_TileMaxOffs", tileMaxOffs);
            _material.SetInt("_TileMaxLoop", tileSize);
            var rtTileMax = GetTemporaryRT(source, tileSize, rgHalf);
            Graphics.Blit(rtCoC, rtTileMax, _material, 1);

            // 3rd pass - NeighborMax filter
            var rtNeighborMax = GetTemporaryRT(source, tileSize, rgHalf);
            Graphics.Blit(rtTileMax, rtNeighborMax, _material, 2);

            if (_visualize)
            {
                // Debug visualization
                Graphics.Blit(rtCoC, destination, _material, 4);
            }
            else
            {
                var rtBokeh = GetTemporaryRT(source, 2, source.format);

                rtHalf.filterMode = FilterMode.Bilinear;
                rtNeighborMax.filterMode = FilterMode.Bilinear;
                _material.SetTexture("_TileTex", rtNeighborMax);
                Graphics.Blit(rtHalf, rtBokeh, _material, 5 + (int)_sampleCount);

                rtBokeh.filterMode = FilterMode.Bilinear;
                _material.SetTexture("_BlurTex", rtBokeh);
                Graphics.Blit(source, destination, _material, 9);

                ReleaseTemporaryRT(rtBokeh);
            }

            // Release the temporary buffers.
            ReleaseTemporaryRT(rtCoC);
            ReleaseTemporaryRT(rtHalf);
            ReleaseTemporaryRT(rtTileMax);
            ReleaseTemporaryRT(rtNeighborMax);
        }

        #endregion
    }
}
