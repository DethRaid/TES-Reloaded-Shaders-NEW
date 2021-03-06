//
// Generated by Microsoft (R) D3DX9 Shader Compiler 9.08.299.0000
//
//   vsa shaderdump19/PAR2024.pso /Fcshaderdump19/PAR2024.pso.dis
//
//
// Parameters:
//
sampler2D TESR_samplerBaseMap : register(s1) = sampler_state { MINFILTER = LINEAR; };
sampler2D NormalMap : register(s0);
float4 PSLightColor[4] : register(c2);
sampler2D ShadowMap : register(s4);
sampler2D ShadowMaskMap : register(s5);
float4 Toggles : register(c7);
//
//
// Registers:
//
//   Name          Reg   Size
//   ------------- ----- ----
//   PSLightColor[0]  const_2        1
//   Toggles       const_7        1
//   NormalMap     texture_0       1
//   TESR_samplerBaseMap       texture_1       1
//   ShadowMap     texture_4       1
//   ShadowMaskMap texture_5       1
//

// Structures:

struct VS_OUTPUT {
    // PAR2032.vso

    float2 BaseUV : TEXCOORD0;
    float3 Light0Dir : TEXCOORD1_centroid;
    float3 Light0Spc : TEXCOORD3_centroid;
    float4 ShadowUV : TEXCOORD6;
    float3 CameraDir : TEXCOORD7_centroid;
};

struct PS_OUTPUT {
    float4 Color : COLOR0;
};

// Code:

#include "Includes/PAR.hlsl"

PS_OUTPUT main(VS_OUTPUT IN) {
    PS_OUTPUT OUT;

#define	expand(v)		(((v) - 0.5) / 0.5)
#define	compress(v)		(((v) * 0.5) + 0.5)
#define	uvtile(w)		(((w) * 0.04) - 0.02)
#define	shade(n, l)		max(dot(n, l), 0)
#define	shades(n, l)		saturate(dot(n, l))
#define	weight(v)		dot(v, 1)
#define	sqr(v)			((v) * (v))

    float1 q10;
    float1 q2;
    float3 q5;
    float4 r0;
    float4 r2;
    float3 t3;
    float1 t4;
    float2 uv;
    float  ao;
    float  hg;
    float3 cm = normalize(IN.CameraDir);

    /* calculate parallaxed position */
    hg = tex2D(TESR_samplerBaseMap, IN.BaseUV.xy).a;
    uv.xy = (uvtile(hg) * (cm.xy / length(cm.xyz))) + IN.BaseUV.xy;
    ao = 1.0;

    /* modifying shader --------------------------------------- */

    psParallax(IN.BaseUV, IN.CameraDir, uv, ao);

    /* fetch Normal+Diffuse from parallaxed position */
    r2.xyzw = tex2D(NormalMap, uv.xy);

    /* fetch additional unmodified Shadow */
    t4.x = tex2D(ShadowMaskMap, IN.ShadowUV.zw).x;
    t3.xyz = tex2D(ShadowMap, IN.ShadowUV.xy).xyz;

    q10.x = r2.w * pow(abs(shades(normalize(expand(r2.xyz)), normalize(IN.Light0Spc.xyz))), Toggles.z);
    q2.x = dot(normalize(expand(r2.xyz)), normalize(IN.Light0Dir.xyz));
    q5.xyz = ((0.2 >= q2.x ? (q10.x * max(q2.x + 0.5, 0)) : q10.x) * PSLightColor[0].rgb) * ((t4.x * (t3.xyz - 1)) + 1);

    OUT.Color.a = weight(q5.xyz);
    OUT.Color.rgb = saturate(q5.xyz * ao);

    return OUT;
};

// approximately 40 instruction slots used (4 texture, 36 arithmetic)
