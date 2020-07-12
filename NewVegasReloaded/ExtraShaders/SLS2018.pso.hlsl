//
// Generated by Microsoft (R) HLSL Shader Compiler 9.23.949.2378
//
// Parameters:

float4 AmbientColor : register(c1);
sampler2D BaseMap : register(s0);
float4 EmittanceColor : register(c2);
sampler2D GlowMap : register(s4);
sampler2D NormalMap : register(s1);
float4 PSLightColor[10] : register(c3);
float4 Toggles : register(c27);
float4 TESR_ShadowData : register(c32);
sampler2D TESR_ShadowMapBufferNear : register(s14) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };
sampler2D TESR_ShadowMapBufferFar : register(s15) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };

// Registers:
//
//   Name           Reg   Size
//   -------------- ----- ----
//   AmbientColor   const_1       1
//   EmittanceColor const_2       1
//   PSLightColor[0]   const_3       1
//   Toggles        const_27      1
//   BaseMap        texture_0       1
//   NormalMap      texture_1       1
//   GlowMap        texture_4       1
//


// Structures:

struct VS_INPUT {
    float2 BaseUV : TEXCOORD0;
    float3 LCOLOR_0 : COLOR0;
    float4 LCOLOR_1 : COLOR1;
    float4 texcoord_1 : TEXCOORD1_centroid;
    float3 texcoord_3 : TEXCOORD3_centroid;
	float4 texcoord_6 : TEXCOORD6;
	float4 texcoord_7 : TEXCOORD7;
};

struct PS_OUTPUT {
    float4 color_0 : COLOR0;
};

#include "../Shadows/Includes/Shadow.hlsl"

PS_OUTPUT main(VS_INPUT IN) {
    PS_OUTPUT OUT;

#define	expand(v)		(((v) - 0.5) / 0.5)
#define	compress(v)		(((v) * 0.5) + 0.5)
#define	shade(n, l)		max(dot(n, l), 0)
#define	shades(n, l)		saturate(dot(n, l))

    float3 noxel0;
	float1 q1;
    float1 q2;
    float1 q3;
    float3 q4;
    float3 q5;
    float3 q6;
    float4 r0;
    float4 r1;
    float4 r2;
    float4 r3;
    float4 r4;
	
	q1.x = GetLightAmount(IN.texcoord_6, IN.texcoord_7);
    r0.xyzw = tex2D(BaseMap, IN.BaseUV.xy);
    r4.w = r0.w * AmbientColor.a;
    r1.xyzw = AmbientColor.rgba;
    r2.xyzw = (r1.w >= 1 ? 0 : (r0.w - Toggles.w));
    clip(r2.xyzw);
    noxel0.xyz = tex2D(NormalMap, IN.BaseUV.xy).xyz;
    r3.xyzw = tex2D(GlowMap, IN.BaseUV.xy);
    q3.x = r2.w * pow(abs(shades(normalize(expand(noxel0.xyz)), normalize(IN.texcoord_3.xyz))), Toggles.z);
    q2.x = dot(normalize(expand(noxel0.xyz)), IN.texcoord_1.xyz);
    q5.xyz = saturate(((0.2 >= q2.x ? (q3.x * saturate(q2.x + 0.5)) : q3.x) * PSLightColor[0].rgb) * IN.texcoord_1.w);
    q4.xyz = (q1.x * (saturate(q2.x) * PSLightColor[0].rgb)) + ((r3.xyz * EmittanceColor.rgb) + r1.xyz);
    q6.xyz = ((Toggles.x <= 0.0 ? r0.xyz : (r0.xyz * IN.LCOLOR_0.xyz)) * max(q4.xyz, 0)) + (q5.xyz * q1.x);
    r4.xyz = (Toggles.y <= 0.0 ? q6.xyz : lerp(q6.xyz, IN.LCOLOR_1.xyz, IN.LCOLOR_1.w));
    OUT.color_0.rgba = r4.xyzw;

    return OUT;
};

// approximately 40 instruction slots used (3 texture, 37 arithmetic)