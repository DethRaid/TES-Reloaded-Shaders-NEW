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
float4 PSLightPosition[8] : register(c19);
float4 TESR_ShadowData : register(c32);
sampler2D TESR_ShadowMapBufferNear : register(s14) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };
sampler2D TESR_ShadowMapBufferFar : register(s15) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };

// Registers:
//
//   Name            Reg   Size
//   --------------- ----- ----
//   AmbientColor    const_1       1
//   PSLightColor[0]    const_3       4
//   PSLightDir      const_18      1
//   PSLightPosition[0] const_19      3
//   BaseMap         texture_0       7
//   NormalMap       texture_7       7
//


// Structures:

struct VS_INPUT {
	float3 LCOLOR_0 : COLOR0;
	float4 LCOLOR_1 : COLOR1;
    float3 BaseUV : TEXCOORD0;
    float3 texcoord_1 : TEXCOORD1_centroid;
	float3 texcoord_2 : TEXCOORD2_centroid;
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

    float3 m61;
    float3 m63;
    float3 m65;
    float3 m69;
    float3 q0;
    float3 q1;
    float3 q10;
    float3 q11;
    float3 q12;
    float3 q16;
    float3 q17;
    float3 q2;
    float3 q28;
    float3 q29;
    float3 q3;
    float3 q4;
    float3 q5;
    float3 q6;
    float3 q7;
    float3 q8;
    float3 q84;
    float3 q9;
    float3 q92;
    float4 r0;
    float4 r1;
    float4 r10;
    float4 r11;
    float4 r12;
    float4 r13;
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
    r13.xyzw = tex2D(BaseMap[6], IN.BaseUV.xy);
    r12.xyzw = tex2D(BaseMap[5], IN.BaseUV.xy);
    r11.xyzw = tex2D(BaseMap[4], IN.BaseUV.xy);
    r10.xyzw = tex2D(BaseMap[3], IN.BaseUV.xy);
    r9.xyzw = tex2D(BaseMap[2], IN.BaseUV.xy);
    r6.xyzw = tex2D(NormalMap[6], IN.BaseUV.xy);
    r5.xyzw = tex2D(NormalMap[5], IN.BaseUV.xy);
    r4.xyzw = tex2D(NormalMap[4], IN.BaseUV.xy);
    r3.xyzw = tex2D(NormalMap[3], IN.BaseUV.xy);
    r7.xyzw = tex2D(BaseMap[1], IN.BaseUV.xy);
    r8.xyzw = tex2D(BaseMap[0], IN.BaseUV.xy);
    q2.xyz = normalize(IN.texcoord_5.xyz);
    q1.xyz = normalize(IN.texcoord_4.xyz);
    q3.xyz = normalize(IN.texcoord_3.xyz);
    m63.xyz = mul(float3x3(q3.xyz, q1.xyz, q2.xyz), PSLightDir.xyz);
    q7.xyz = PSLightPosition[2].xyz - IN.texcoord_2.xyz;
    q8.xyz = q7.xyz / PSLightPosition[2].w;
    m69.xyz = mul(float3x3(q3.xyz, q1.xyz, q2.xyz), q7.xyz);
    q5.xyz = PSLightPosition[1].xyz - IN.texcoord_2.xyz;
    q6.xyz = q5.xyz / PSLightPosition[1].w;
    m65.xyz = mul(float3x3(q3.xyz, q1.xyz, q2.xyz), q5.xyz);
    q0.xyz = PSLightPosition[0].xyz - IN.texcoord_2.xyz;
    q4.xyz = q0.xyz / PSLightPosition[0].w;
    m61.xyz = mul(float3x3(q3.xyz, q1.xyz, q2.xyz), q0.xyz);
    q9.xyz = (IN.LCOLOR_0.z * r9.xyz) + ((IN.LCOLOR_0.x * r8.xyz) + (r7.xyz * IN.LCOLOR_0.y));
    q10.xyz = (IN.LCOLOR_1.z * r12.xyz) + ((IN.LCOLOR_1.y * r11.xyz) + ((IN.LCOLOR_1.x * r10.xyz) + q9.xyz));
    r0.xyz = (2 * ((r1.xyz - 0.5) * IN.LCOLOR_0.x)) + (2 * ((r0.xyz - 0.5) * IN.LCOLOR_0.y));	// [0,1] to [-1,+1]
    q16.xyz = (2 * ((r3.xyz - 0.5) * IN.LCOLOR_1.x)) + ((2 * ((r2.xyz - 0.5) * IN.LCOLOR_0.z)) + r0.xyz);	// [0,1] to [-1,+1]
    q17.xyz = (2 * ((r5.xyz - 0.5) * IN.LCOLOR_1.z)) + ((2 * ((r4.xyz - 0.5) * IN.LCOLOR_1.y)) + q16.xyz);	// [0,1] to [-1,+1]
    q84.xyz = normalize((2 * ((r6.xyz - 0.5) * IN.LCOLOR_1.w)) + q17.xyz);	// [0,1] to [-1,+1]
    q92.xyz = shades(q84.xyz, normalize(m61.xyz)) * (1 - shades(q4.xyz, q4.xyz)) * PSLightColor[1].xyz;
    r2.xyz = (shades(q84.xyz, m63.xyz) * PSLightColor[0].rgb) + q92.xyz;
    q28.xyz = ((shades(q84.xyz, normalize(m65.xyz)) * (1 - shades(q6.xyz, q6.xyz))) * PSLightColor[2].xyz) + r2.xyz;
    q29.xyz = ((shades(q84.xyz, normalize(m69.xyz)) * (1 - shades(q8.xyz, q8.xyz))) * PSLightColor[3].xyz) + q28.xyz;
    q11.xyz = ((GetLightAmount(IN.texcoord_6, IN.texcoord_7, IN.ShadowNearFar.x, IN.ShadowNearFar.y) * q29.xyz) + AmbientColor.rgb) * ((IN.LCOLOR_1.w * r13.xyz) + q10.xyz);
    q12.xyz = (IN.BaseUV.z * (TESR_FogColor.xyz - (IN.texcoord_1.xyz * q11.xyz))) + (q11.xyz * IN.texcoord_1.xyz);
    OUT.color_0.a = 1;
    OUT.color_0.rgb = q12.xyz;

    return OUT;
};

// approximately 109 instruction slots used (14 texture, 95 arithmetic)