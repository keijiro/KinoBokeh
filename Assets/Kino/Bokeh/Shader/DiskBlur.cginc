#include "UnityCG.cginc"
#include "DiskKernel.cginc"

// Source textures
sampler2D _MainTex;
float4 _MainTex_TexelSize;

sampler2D _TileTex;
float4 _TileTex_TexelSize;

sampler2D _BlurTex;
float4 _BlurTex_TexelSize;

float _InvAspect;

float GetArea(float coc)
{
    float radius = max(0.7071, abs(coc) / 20 / _MainTex_TexelSize.y);
    return radius * radius * UNITY_PI;
}

float TestDistance(float d, float coc, float maxCoC)
{
    return pow(saturate((maxCoC - d) / (maxCoC - coc)), 6);
}

half4 frag_Blur(v2f_img i) : SV_Target
{
    half4 color0 = tex2D(_MainTex, i.uv);
    half2 tile0 = tex2D(_TileTex, i.uv);

    half maxCoC = max(abs(tile0.x), tile0.y);

    half4 bgAcc = 0;
    half4 fgAcc = 0;

    for (int si = 0; si < kSampleCount; si++)
    {
        float2 disp = kDiskKernel[si] * maxCoC;
        float lDisp = length(disp);

        float2 duv = float2(disp.x * _InvAspect, disp.y);
        half4 color = tex2D(_MainTex, i.uv + duv);

        half weight = color.a * abs(color.a) * 200;
        half bgWeight = saturate( weight);
        half fgWeight = saturate(-weight);

        bgWeight *= TestDistance(lDisp, abs(min(color.a, color0.a)), maxCoC);
        fgWeight *= TestDistance(lDisp, abs(    color.a           ), maxCoC);

        bgAcc += half4(color.rgb, 1) * bgWeight;
        fgAcc += half4(color.rgb, 1) * fgWeight;
    }

    bgAcc.rgb /= bgAcc.a + (bgAcc.a == 0); // avoiding zero-div
    fgAcc.rgb /= fgAcc.a + (fgAcc.a == 0);

    half3 rgb = 0;
    rgb = lerp(rgb, bgAcc.rgb, saturate(bgAcc.a));
    rgb = lerp(rgb, fgAcc.rgb, saturate(fgAcc.a));

    half alpha = (1 - saturate(bgAcc.a)) * (1 - saturate(fgAcc.a));

    return half4(rgb, alpha);
}

half4 frag_Composite(v2f_img i) : SV_Target
{
    half4 cs = tex2D(_MainTex, i.uv);
    half4 cb = tex2D(_BlurTex, i.uv);

    half3 rgb = cs * cb.a + cb.rgb;

    return half4(rgb, cs.a);
}
