//
// Generated by Microsoft (R) HLSL Shader Compiler 9.23.949.2378
//
// Parameters:

float4 AmbientColor : register(c1);
sampler2D BaseMap[7] : register(s0);
sampler2D NormalMap[7] : register(s7);
float4 PSLightColor[10] : register(c3);
float4 TESR_FogColor : register(c15);
float4 PSLightDir : register(c18);
float4 TESR_ShadowData : register(c32);
sampler2D TESR_ShadowMapBufferNear : register(s14) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };
sampler2D TESR_ShadowMapBufferFar : register(s15) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };

// Registers:
//
//   Name         Reg   Size
//   ------------ ----- ----
//   AmbientColor const_1       1
//   PSLightColor[0] const_3       1
//   PSLightDir   const_18      1
//   BaseMap      texture_0       6
//   NormalMap    texture_7       6
//


// Structures:

struct VS_INPUT {
	float3 LCOLOR_0 : COLOR0;
	float4 LCOLOR_1 : COLOR1;
    float3 BaseUV : TEXCOORD0;
    float3 texcoord_1 : TEXCOORD1_centroid;
    float3 texcoord_3 : TEXCOORD3_centroid;
    float3 texcoord_4 : TEXCOORD4_centroid;
    float3 texcoord_5 : TEXCOORD5_centroid;
	float4 texcoord_6 : TEXCOORD6;
    float4 texcoord_7 : TEXCOORD7;
    float2 ShadowNearFar : TEXCOORD8;
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

    float3 m32;
    float3 q0;
    float3 q1;
    float3 q2;
    float3 q3;
    float3 q4;
    float3 q5;
    float3 q6;
    float3 q7;
    float4 r0;
    float4 r1;
    float4 r10;
    float4 r11;
    float4 r2;
    float4 r3;
    float4 r4;
    float4 r5;
    float4 r6;
    float4 r7;
    float4 r8;
    float4 r9;

    r2.xyzw = tex2D(NormalMap[2], IN.BaseUV.xy);
    r0.xyzw = tex2D(NormalMap[1], IN.BaseUV.xy);
    r1.xyzw = tex2D(NormalMap[0], IN.BaseUV.xy);
    r11.xyzw = tex2D(BaseMap[5], IN.BaseUV.xy);
    r10.xyzw = tex2D(BaseMap[4], IN.BaseUV.xy);
    r9.xyzw = tex2D(BaseMap[3], IN.BaseUV.xy);
    r8.xyzw = tex2D(BaseMap[2], IN.BaseUV.xy);
    r5.xyzw = tex2D(NormalMap[5], IN.BaseUV.xy);
    r4.xyzw = tex2D(NormalMap[4], IN.BaseUV.xy);
    r3.xyzw = tex2D(NormalMap[3], IN.BaseUV.xy);
    r6.xyzw = tex2D(BaseMap[1], IN.BaseUV.xy);
    r7.xyzw = tex2D(BaseMap[0], IN.BaseUV.xy);
    q3.xyz = normalize(IN.texcoord_5.xyz);
    q0.xyz = normalize(IN.texcoord_4.xyz);
    q2.xyz = normalize(IN.texcoord_3.xyz);
    m32.xyz = mul(float3x3(q2.xyz, q0.xyz, q3.xyz), PSLightDir.xyz);
    q4.xyz = (IN.LCOLOR_0.z * r8.xyz) + ((IN.LCOLOR_0.x * r7.xyz) + (r6.xyz * IN.LCOLOR_0.y));
    q5.xyz = (IN.LCOLOR_1.z * r11.xyz) + ((IN.LCOLOR_1.y * r10.xyz) + ((IN.LCOLOR_1.x * r9.xyz) + q4.xyz));
    r0.xyz = (2 * ((r1.xyz - 0.5) * IN.LCOLOR_0.x)) + (2 * ((r0.xyz - 0.5) * IN.LCOLOR_0.y));	// [0,1] to [-1,+1]
    r0.xyz = (2 * ((r2.xyz - 0.5) * IN.LCOLOR_0.z)) + r0.xyz;	// [0,1] to [-1,+1]
    q1.xyz = (2 * ((r4.xyz - 0.5) * IN.LCOLOR_1.y)) + ((2 * ((r3.xyz - 0.5) * IN.LCOLOR_1.x)) + r0.xyz);	// [0,1] to [-1,+1]
    r6.w = shades(normalize((2 * ((r5.xyz - 0.5) * IN.LCOLOR_1.z)) + q1.xyz), m32.xyz);	// [0,1] to [-1,+1]
    q6.xyz = ((GetLightAmount(IN.texcoord_6, IN.texcoord_7, IN.ShadowNearFar.x, IN.ShadowNearFar.y) * (r6.w * PSLightColor[0].rgb)) + AmbientColor.rgb) * q5.xyz;
    q7.xyz = (IN.BaseUV.z * (TESR_FogColor.xyz - (IN.texcoord_1.xyz * q6.xyz))) + (q6.xyz * IN.texcoord_1.xyz);
    OUT.color_0.a = 1;
    OUT.color_0.rgb = q7.xyz;

    return OUT;
};

// approximately 61 instruction slots used (12 texture, 49 arithmetic)