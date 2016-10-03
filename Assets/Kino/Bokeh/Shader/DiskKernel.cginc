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

#if !defined(SAMPLE_COUNT_LOW) && !defined(SAMPLE_COUNT_MEDIUM) && \
    !defined(SAMPLE_COUNT_HIGH) && !defined(SAMPLE_COUNT_VERYHIGH)

static const int kSampleCount = 1;
static const float2 kDiskKernel[1] = { float2(0, 0) };

#endif

#if defined(SAMPLE_COUNT_LOW)

static const int kSampleCount = 16;
static const float2 kDiskKernel[kSampleCount] = {
    float2(0,0),
    float2(0.33333334,0),
    float2(0.10300566,0.31701887),
    float2(-0.26967236,0.1959284),
    float2(-0.26967233,-0.19592845),
    float2(0.10300571,-0.31701884),
    float2(0.6666667,0),
    float2(0.53934467,0.39185685),
    float2(0.20601133,0.63403773),
    float2(-0.20601135,0.6340377),
    float2(-0.5393447,0.3918568),
    float2(-0.6666667,-0.000000058281852),
    float2(-0.53934467,-0.3918569),
    float2(-0.2060111,-0.63403773),
    float2(0.20601141,-0.6340377),
    float2(0.53934467,-0.39185688),
};

#endif

#if defined(SAMPLE_COUNT_MEDIUM)

static const int kSampleCount = 31;
static const float2 kDiskKernel[kSampleCount] = {
    float2(0,0),
    float2(0.25,0),
    float2(0.07725424,0.23776414),
    float2(-0.20225427,0.1469463),
    float2(-0.20225424,-0.14694634),
    float2(0.07725428,-0.23776412),
    float2(0.5,0),
    float2(0.4045085,0.29389262),
    float2(0.15450849,0.47552827),
    float2(-0.15450852,0.47552824),
    float2(-0.40450853,0.2938926),
    float2(-0.5,-0.00000004371139),
    float2(-0.40450847,-0.29389268),
    float2(-0.15450832,-0.4755283),
    float2(0.15450856,-0.47552824),
    float2(0.40450847,-0.29389265),
    float2(0.75,0),
    float2(0.6851591,0.3050525),
    float2(0.5018479,0.5573586),
    float2(0.23176274,0.7132924),
    float2(-0.07839638,0.74589145),
    float2(-0.37500006,0.649519),
    float2(-0.60676277,0.44083887),
    float2(-0.73361075,0.15593371),
    float2(-0.7336107,-0.15593384),
    float2(-0.6067627,-0.44083902),
    float2(-0.37499994,-0.6495191),
    float2(-0.07839625,-0.74589145),
    float2(0.23176284,-0.71329236),
    float2(0.50184804,-0.55735856),
    float2(0.68515915,-0.30505237),
};

#endif

#if defined(SAMPLE_COUNT_HIGH)

static const int kSampleCount = 43;
static const float2 kDiskKernel[kSampleCount] = {
    float2(0,0),
    float2(0.25,0),
    float2(0.15587245,0.19545788),
    float2(-0.055630237,0.24373198),
    float2(-0.22524221,0.108470954),
    float2(-0.22524221,-0.10847094),
    float2(-0.055630136,-0.243732),
    float2(0.15587242,-0.1954579),
    float2(0.5,0),
    float2(0.45048442,0.21694188),
    float2(0.3117449,0.39091575),
    float2(0.11126049,0.48746395),
    float2(-0.111260474,0.48746395),
    float2(-0.311745,0.3909157),
    float2(-0.45048442,0.21694191),
    float2(-0.5,-0.00000004371139),
    float2(-0.45048442,-0.21694188),
    float2(-0.3117448,-0.3909158),
    float2(-0.11126027,-0.487464),
    float2(0.11126075,-0.4874639),
    float2(0.31174484,-0.3909158),
    float2(0.45048442,-0.21694188),
    float2(0.75,0),
    float2(0.7166796,0.22106639),
    float2(0.6196791,0.42249006),
    float2(0.46761733,0.5863736),
    float2(0.27400574,0.6981553),
    float2(0.0560475,0.74790287),
    float2(-0.16689071,0.7311959),
    float2(-0.37500006,0.649519),
    float2(-0.54978895,0.5101295),
    float2(-0.67572665,0.32541287),
    float2(-0.74162316,0.11178157),
    float2(-0.7416231,-0.111781865),
    float2(-0.67572665,-0.3254128),
    float2(-0.5497889,-0.5101296),
    float2(-0.37499994,-0.6495191),
    float2(-0.16689076,-0.7311959),
    float2(0.05604772,-0.7479028),
    float2(0.27400613,-0.69815516),
    float2(0.46761727,-0.5863737),
    float2(0.6196791,-0.42249),
    float2(0.7166797,-0.22106612),
};

#endif

#if defined(SAMPLE_COUNT_VERYHIGH)

static const int kSampleCount = 71;
static const float2 kDiskKernel[kSampleCount] = {
    float2(0,0),
    float2(0.2,0),
    float2(0.12469796,0.1563663),
    float2(-0.04450419,0.19498558),
    float2(-0.18019377,0.08677676),
    float2(-0.18019377,-0.086776756),
    float2(-0.04450411,-0.19498561),
    float2(0.12469794,-0.15636633),
    float2(0.4,0),
    float2(0.36038753,0.17355351),
    float2(0.24939592,0.3127326),
    float2(0.08900839,0.38997117),
    float2(-0.08900838,0.38997117),
    float2(-0.249396,0.31273255),
    float2(-0.36038753,0.17355353),
    float2(-0.4,-0.000000034969112),
    float2(-0.36038753,-0.17355351),
    float2(-0.24939585,-0.31273267),
    float2(-0.08900822,-0.38997123),
    float2(0.0890086,-0.3899711),
    float2(0.24939588,-0.31273267),
    float2(0.36038753,-0.17355351),
    float2(0.6,0),
    float2(0.5733437,0.17685312),
    float2(0.49574327,0.33799207),
    float2(0.3740939,0.46909893),
    float2(0.21920459,0.55852425),
    float2(0.044838004,0.59832233),
    float2(-0.13351257,0.58495677),
    float2(-0.30000004,0.51961523),
    float2(-0.4398312,0.40810362),
    float2(-0.54058135,0.2603303),
    float2(-0.59329855,0.08942525),
    float2(-0.5932985,-0.0894255),
    float2(-0.54058135,-0.26033026),
    float2(-0.4398311,-0.4081037),
    float2(-0.29999995,-0.5196153),
    float2(-0.13351262,-0.58495677),
    float2(0.044838175,-0.5983223),
    float2(0.2192049,-0.5585242),
    float2(0.37409383,-0.469099),
    float2(0.4957433,-0.337992),
    float2(0.57334375,-0.17685291),
    float2(0.8,0),
    float2(0.77994233,0.17801675),
    float2(0.72077507,0.34710702),
    float2(0.6254652,0.49879184),
    float2(0.49879184,0.6254652),
    float2(0.3471069,0.7207751),
    float2(0.17801678,0.77994233),
    float2(-0.000000034969112,0.8),
    float2(-0.17801677,0.77994233),
    float2(-0.34710708,0.72077507),
    float2(-0.498792,0.6254651),
    float2(-0.62546533,0.49879166),
    float2(-0.72077507,0.34710705),
    float2(-0.77994233,0.17801675),
    float2(-0.8,-0.000000069938224),
    float2(-0.77994233,-0.1780167),
    float2(-0.72077507,-0.34710702),
    float2(-0.6254651,-0.49879193),
    float2(-0.4987917,-0.62546533),
    float2(-0.34710678,-0.72077525),
    float2(-0.17801644,-0.77994245),
    float2(0.00000039100965,-0.8),
    float2(0.1780172,-0.7799422),
    float2(0.34710678,-0.7207752),
    float2(0.49879175,-0.62546533),
    float2(0.62546515,-0.4987919),
    float2(0.72077507,-0.34710702),
    float2(0.77994233,-0.17801669),
};

#endif
