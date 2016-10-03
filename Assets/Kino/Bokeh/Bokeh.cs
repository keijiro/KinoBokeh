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
using UnityEngine.Serialization;

namespace Kino
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    public class Bokeh : MonoBehaviour
    {
        #region Editable properties

        [SerializeField, FormerlySerializedAs("_subject")]
        Transform _pointOfFocus;

        public Transform pointOfFocus {
            get { return _pointOfFocus; }
            set { _pointOfFocus = value; }
        }

        [SerializeField, FormerlySerializedAs("_distance")]
        float _focusDistance = 10.0f;

        public float distance {
            get { return _focusDistance; }
            set { _focusDistance = value; }
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

        // Height of the 35mm full-frame format (36mm x 24mm)
        const float kFilmHeight = 0.024f;

        [SerializeField] Shader _shader;
        Material _material;

        Camera TargetCamera {
            get { return GetComponent<Camera>(); }
        }

        float CalculateFocusDistance()
        {
            if (_pointOfFocus == null) return _focusDistance;
            var cam = TargetCamera.transform;
            return Vector3.Dot(_pointOfFocus.position - cam.position, cam.forward);
        }

        float CalculateFocalLength()
        {
            if (!_useCameraFov) return _focalLength;
            var fov = TargetCamera.fieldOfView * Mathf.Deg2Rad;
            return 0.5f * kFilmHeight / Mathf.Tan(0.5f * fov);
        }

        float CalculateMaxCoCRadius(int screenHeight)
        {
            // Calculate the maximum radius of CoC from the sample count level.
            // The equation below was empirically derived.
            // So, it might not be the best one...
            var radiusInPixels = (float)_sampleCount * 4 + 10;

            // Limit the radius at 10% (this is also empirical).
            return Mathf.Min(0.1f, radiusInPixels / screenHeight);
        }

        void SetUpShaderParameters(RenderTexture source)
        {
            var s1 = CalculateFocusDistance();
            _material.SetFloat("_Distance", s1);

            var f = CalculateFocalLength();
            var coeff = f * f / (_fNumber * (s1 - f) * kFilmHeight * 2);
            _material.SetFloat("_LensCoeff", coeff);

            _material.SetFloat("_MaxCoC", CalculateMaxCoCRadius(source.height));

            var invAspect = (float)source.height / source.width;
            _material.SetFloat("_InvAspect", invAspect);
        }

        RenderTexture GetTemporaryRT(Texture source, int divider,
            RenderTextureFormat format, bool enableFilter)
        {
            var w = source.width / divider;
            var h = source.height / divider;
            var rt = RenderTexture.GetTemporary(w, h, 0, format);
            rt.filterMode = enableFilter ? FilterMode.Bilinear : FilterMode.Point;
            return rt;
        }

        void ReleaseTemporaryRT(RenderTexture rt)
        {
            RenderTexture.ReleaseTemporary(rt);
        }

        #endregion

        #region MonoBehaviour functions

        void OnEnable()
        {
            // Initialize temporary objects (only when not set up yet).
            if (_material == null)
            {
                _material = new Material(Shader.Find("Hidden/Kino/Bokeh"));
                _material.hideFlags = HideFlags.HideAndDontSave;
            }

            // Requires camera depth texture.
            TargetCamera.depthTextureMode |= DepthTextureMode.Depth;
        }

        void OnDestroy()
        {
            // Destroy the temporary objects.
            if (_material != null)
                if (Application.isPlaying)
                    Destroy(_material);
                else
                    DestroyImmediate(_material);
        }

        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            const RenderTextureFormat rgHalf = RenderTextureFormat.RGHalf;

            SetUpShaderParameters(source);

            // Calculate the TileMax size.
            // It should be a multiple of 8 and larger than the CoC radius.
            var maxBlur = CalculateMaxCoCRadius(source.height) * source.height;
            var tileSize = ((Mathf.CeilToInt(maxBlur) - 1) / 8 + 1) * 8;

            // Pass #1 - CoC estimation
            var rtCoC = GetTemporaryRT(source, 1, source.format, true);
            Graphics.Blit(source, rtCoC, _material, 0);

            // Pass #2 - downsampling
            var rtSmall = GetTemporaryRT(source, 2, source.format, true);
            Graphics.Blit(rtCoC, rtSmall, _material, 3);

            // Pass #3 - TileMax filter
            var tileMaxOffs = Vector2.one * (tileSize - 1) * -0.5f;
            _material.SetVector("_TileMaxOffs", tileMaxOffs);
            _material.SetInt("_TileMaxLoop", tileSize);
            var rtTileMax = GetTemporaryRT(source, tileSize, rgHalf, false);
            Graphics.Blit(rtCoC, rtTileMax, _material, 1);

            // Pass #4 - NeighborMax filter
            var rtNeighborMax = GetTemporaryRT(source, tileSize, rgHalf, true);
            Graphics.Blit(rtTileMax, rtNeighborMax, _material, 2);

            if (_visualize)
            {
                // Debug visualization
                Graphics.Blit(rtCoC, destination, _material, 4);
            }
            else
            {
                // Pass #5 - Bokeh simulation
                var rtBokeh = GetTemporaryRT(source, 2, source.format, true);
                _material.SetTexture("_TileTex", rtNeighborMax);
                Graphics.Blit(rtSmall, rtBokeh, _material, 5 + (int)_sampleCount);

                // Pass #6 - Final composition
                _material.SetTexture("_BlurTex", rtBokeh);
                Graphics.Blit(source, destination, _material, 9);
                ReleaseTemporaryRT(rtBokeh);
            }

            ReleaseTemporaryRT(rtCoC);
            ReleaseTemporaryRT(rtSmall);
            ReleaseTemporaryRT(rtTileMax);
            ReleaseTemporaryRT(rtNeighborMax);
        }

        #endregion
    }
}
