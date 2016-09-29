#include "UnityCG.cginc"

// Source textures
sampler2D _MainTex;
float4 _MainTex_TexelSize;

sampler2D _TileTex;
float4 _TileTex_TexelSize;

#define SAMPLE_COUNT_HIGHER

#if defined(SAMPLE_COUNT_LOWER)

static const int sampleCount = 31;
static const float2 kernel[sampleCount] = {
    float2(0,0),
    float2(0.24927607,0.019011661),
    float2(0.058949366,0.24295056),
    float2(-0.21284336,0.13114002),
    float2(-0.19049378,-0.16190158),
    float2(0.095111795,-0.23120067),
    float2(0.49421692,0.07582644),
    float2(0.35526022,0.3518383),
    float2(0.08060618,0.49345988),
    float2(-0.22483668,0.44659653),
    float2(-0.44439957,0.2291485),
    float2(-0.4942169,-0.07582648),
    float2(-0.35526016,-0.35183832),
    float2(-0.08060601,-0.4934599),
    float2(0.2248367,-0.44659653),
    float2(0.4443995,-0.22914857),
    float2(0.730363,0.17049894),
    float2(0.59787166,0.45282394),
    float2(0.36200282,0.65685153),
    float2(0.06354043,0.7473036),
    float2(-0.24590868,0.70853996),
    float2(-0.51283795,0.5472634),
    float2(-0.69109285,0.29136002),
    float2(-0.7498515,-0.0149221765),
    float2(-0.67895406,-0.3186242),
    float2(-0.49065927,-0.5672332),
    float2(-0.21752518,-0.71776235),
    float2(0.09322147,-0.74418396),
    float2(0.38784862,-0.64192945),
    float2(0.6154138,-0.42867917),
    float2(0.736568,-0.14130694),
};

#endif

#if defined(SAMPLE_COUNT_HIGH)

static const int sampleCount = 43;
static const float2 kernel[sampleCount] = {
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

#if defined(SAMPLE_COUNT_HIGHER)

static const int sampleCount = 71;
static const float2 kernel[sampleCount] = {
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

float GetArea(float coc)
{
    float radius = max(0.7071, abs(coc) / 20 / _MainTex_TexelSize.y);
    return radius * radius * UNITY_PI;
}

float TestDistance(float d, float coc, float maxCoC)
{
    return pow(saturate((maxCoC - d) / (maxCoC - coc)), 6);
}

half4 frag(v2f_img i) : SV_Target
{
    float aspect = _MainTex_TexelSize.x / _MainTex_TexelSize.y;

    half4 color0 = tex2D(_MainTex, i.uv);
    half2 tile0 = tex2D(_TileTex, i.uv);

    half maxCoC = max(abs(tile0.x), tile0.y);

    half4 bgAcc = 0;
    half4 fgAcc = 0;

    for (int si = 0; si < sampleCount; si++)
    {
        float2 disp = kernel[si] * maxCoC;
        float lDisp = length(disp);

        float2 duv = float2(disp.x * aspect, disp.y);
        half4 color = tex2D(_MainTex, i.uv + duv);

        half weight = color.a * abs(color.a) * 100;
        half bgWeight = saturate( weight);
        half fgWeight = saturate(-weight);

        bgWeight *= TestDistance(lDisp, abs(min(color.a, color0.a)), maxCoC);
        fgWeight *= TestDistance(lDisp, abs(    color.a           ), maxCoC);

        bgAcc += half4(color.rgb, 1) * bgWeight;
        fgAcc += half4(color.rgb, 1) * fgWeight;
    }

    bgAcc.rgb /= bgAcc.a + (bgAcc.a == 0); // avoiding zero-div
    fgAcc.rgb /= fgAcc.a + (fgAcc.a == 0);

    half3 rgb = color0.rgb;
    rgb = lerp(rgb, bgAcc.rgb, saturate(bgAcc.a));
    rgb = lerp(rgb, fgAcc.rgb, saturate(fgAcc.a));

    return half4(rgb, 1);
}
