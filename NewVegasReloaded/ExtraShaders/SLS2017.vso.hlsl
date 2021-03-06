//
// Generated by Microsoft (R) HLSL Shader Compiler 9.23.949.2378
//
// Parameters:

float4 Bones[54] : register(c44);
float4 EyePosition : register(c16);
float3 FogColor : register(c15);
float4 FogParam : register(c14);
float4 LightData[10] : register(c25);
row_major float4x4 SkinModelViewProj : register(c1);
row_major float4x4 TESR_InvViewProjectionTransform : register(c35);

// Registers:
//
//   Name              Reg   Size
//   ----------------- ----- ----
//   SkinModelViewProj[0] const_1        1
//   SkinModelViewProj[1] const_2        1
//   SkinModelViewProj[2] const_3        1
//   SkinModelViewProj[3] const_4        1
//   FogParam          const_14      1
//   FogColor          const_15      1
//   EyePosition       const_16      1
//   LightData[0]         const_25      2
//   Bones[0]             const_44     54
//


// Structures:

struct VS_INPUT {
    float4 LPOSITION : POSITION;
    float3 LTANGENT : TANGENT;
    float3 LBINORMAL : BINORMAL;
    float3 LNORMAL : NORMAL;
    float4 LTEXCOORD_0 : TEXCOORD0;
    float4 LCOLOR_0 : COLOR0;
    float3 LBLENDWEIGHT : BLENDWEIGHT;
    float4 LBLENDINDICES : BLENDINDICES;
};

struct VS_OUTPUT {
    float4 color_0 : COLOR0;
    float4 color_1 : COLOR1;
    float4 position : POSITION;
    float2 texcoord_0 : TEXCOORD0;
    float4 texcoord_1 : TEXCOORD1;
    float4 texcoord_2 : TEXCOORD2;
    float3 texcoord_3 : TEXCOORD3;
    float3 texcoord_4 : TEXCOORD4;
    float4 texcoord_5 : TEXCOORD5;
	float4 texcoord_6 : TEXCOORD6;
};

// Code:

VS_OUTPUT main(VS_INPUT IN) {
    VS_OUTPUT OUT;

#define	expand(v)		(((v) - 0.5) / 0.5)
#define	compress(v)		(((v) * 0.5) + 0.5)
#define	weight(v)		dot(v, 1)
#define	sqr(v)			((v) * (v))

    const float4 const_0 = {1, 765.01001, 0, 0.5};

    float3 eye1;
    float3 m30;
    float4 mdl39;
    float4 offset;
    float4 q0;
    float3 q31;
    float3 q4;
    float3 q46;
    float1 q7;
    float4 r0;
    float4 r1;
    float3 r2;
    float3 r4;
    float3 r5;
	float4 shw;
	
    OUT.color_0.rgba = IN.LCOLOR_0.xyzw;
    offset.xyzw = IN.LBLENDINDICES.zyxw * 765.01001;
    r5.z = dot(Bones[2 + offset.y].xyz, IN.LNORMAL.xyz);
    r4.z = dot(Bones[2 + offset.y].xyz, IN.LBINORMAL.xyz);
    r5.y = dot(Bones[1 + offset.y].xyz, IN.LNORMAL.xyz);
    r4.y = dot(Bones[1 + offset.y].xyz, IN.LBINORMAL.xyz);
    r5.x = dot(Bones[0 + offset.y].xyz, IN.LNORMAL.xyz);
    r4.x = dot(Bones[0 + offset.y].xyz, IN.LBINORMAL.xyz);
    r1.w = 1;
    q0.xyzw = (IN.LPOSITION.xyzx * const_0.xxxz) + const_0.zzzx;
    r2.z = dot(Bones[2 + offset.y].xyzw, q0.xyzw);
    r2.y = dot(Bones[1 + offset.y].xyzw, q0.xyzw);
    r2.x = dot(Bones[0 + offset.y].xyzw, q0.xyzw);
    r0.yzw = r2.xyz * IN.LBLENDWEIGHT.y;
    r2.z = dot(Bones[2 + offset.x].xyzw, q0.xyzw);
    r2.y = dot(Bones[1 + offset.x].xyzw, q0.xyzw);
    r2.x = dot(Bones[0 + offset.x].xyzw, q0.xyzw);
    r0.yzw = (r2.xyz * IN.LBLENDWEIGHT.x) + r0.yzw;
    r2.z = dot(Bones[2 + offset.z].xyzw, q0.xyzw);
    r2.y = dot(Bones[1 + offset.z].xyzw, q0.xyzw);
    r2.x = dot(Bones[0 + offset.z].xyzw, q0.xyzw);
    r0.yzw = (r2.xyz * IN.LBLENDWEIGHT.z) + r0.yzw;
    r2.z = dot(Bones[2 + offset.w].xyzw, q0.xyzw);
    r2.y = dot(Bones[1 + offset.w].xyzw, q0.xyzw);
    r2.x = dot(Bones[0 + offset.w].xyzw, q0.xyzw);
    r1.xyz = ((1 - weight(IN.LBLENDWEIGHT.xyz)) * r2.xyz) + r0.yzw;
    r2.z = dot(Bones[2 + offset.y].xyz, IN.LTANGENT.xyz);
    r2.y = dot(Bones[1 + offset.y].xyz, IN.LTANGENT.xyz);
    r2.x = dot(Bones[0 + offset.y].xyz, IN.LTANGENT.xyz);
    r0.yzw = r2.xyz * IN.LBLENDWEIGHT.y;
    r2.z = dot(Bones[2 + offset.x].xyz, IN.LTANGENT.xyz);
    r2.y = dot(Bones[1 + offset.x].xyz, IN.LTANGENT.xyz);
    r2.x = dot(Bones[0 + offset.x].xyz, IN.LTANGENT.xyz);
    eye1.xyz = EyePosition.xyz - r1.xyz;
    r0.yzw = (r2.xyz * IN.LBLENDWEIGHT.x) + r0.yzw;
    r2.z = dot(Bones[2 + offset.z].xyz, IN.LTANGENT.xyz);
    r2.y = dot(Bones[1 + offset.z].xyz, IN.LTANGENT.xyz);
    r2.x = dot(Bones[0 + offset.z].xyz, IN.LTANGENT.xyz);
    r0.yzw = (r2.xyz * IN.LBLENDWEIGHT.z) + r0.yzw;
    r2.z = dot(Bones[2 + offset.w].xyz, IN.LTANGENT.xyz);
    r2.y = dot(Bones[1 + offset.w].xyz, IN.LTANGENT.xyz);
    r2.x = dot(Bones[0 + offset.w].xyz, IN.LTANGENT.xyz);
    r2.xyz = normalize((r2.xyz * (1 - weight(IN.LBLENDWEIGHT.xyz))) + r0.yzw);
    r0.yzw = r4.xyz * IN.LBLENDWEIGHT.y;
    r4.z = dot(Bones[2 + offset.x].xyz, IN.LBINORMAL.xyz);
    r4.y = dot(Bones[1 + offset.x].xyz, IN.LBINORMAL.xyz);
    r4.x = dot(Bones[0 + offset.x].xyz, IN.LBINORMAL.xyz);
    r0.yzw = (r4.xyz * IN.LBLENDWEIGHT.x) + r0.yzw;
    r4.z = dot(Bones[2 + offset.z].xyz, IN.LBINORMAL.xyz);
    r4.y = dot(Bones[1 + offset.z].xyz, IN.LBINORMAL.xyz);
    r4.x = dot(Bones[0 + offset.z].xyz, IN.LBINORMAL.xyz);
    r0.yzw = (r4.xyz * IN.LBLENDWEIGHT.z) + r0.yzw;
    r4.z = dot(Bones[2 + offset.w].xyz, IN.LBINORMAL.xyz);
    r4.y = dot(Bones[1 + offset.w].xyz, IN.LBINORMAL.xyz);
    r4.x = dot(Bones[0 + offset.w].xyz, IN.LBINORMAL.xyz);
    r4.xyz = normalize((r4.xyz * (1 - weight(IN.LBLENDWEIGHT.xyz))) + r0.yzw);
    r0.yzw = r5.xyz * IN.LBLENDWEIGHT.y;
    r5.z = dot(Bones[2 + offset.x].xyz, IN.LNORMAL.xyz);
    r5.y = dot(Bones[1 + offset.x].xyz, IN.LNORMAL.xyz);
    r5.x = dot(Bones[0 + offset.x].xyz, IN.LNORMAL.xyz);
    r0.yzw = (r5.xyz * IN.LBLENDWEIGHT.x) + r0.yzw;
    r5.z = dot(Bones[2 + offset.z].xyz, IN.LNORMAL.xyz);
    r5.y = dot(Bones[1 + offset.z].xyz, IN.LNORMAL.xyz);
    r5.x = dot(Bones[0 + offset.z].xyz, IN.LNORMAL.xyz);
    r0.yzw = (r5.xyz * IN.LBLENDWEIGHT.z) + r0.yzw;
    r5.z = dot(Bones[2 + offset.w].xyz, IN.LNORMAL.xyz);
    r5.y = dot(Bones[1 + offset.w].xyz, IN.LNORMAL.xyz);
    r5.x = dot(Bones[0 + offset.w].xyz, IN.LNORMAL.xyz);
	mdl39 = mul(SkinModelViewProj, r1.xyzw);
	shw = mul(mdl39, TESR_InvViewProjectionTransform);
    q46.xyz = normalize(((1 - weight(IN.LBLENDWEIGHT.xyz)) * r5.xyz) + r0.yzw);
    q4.xyz = LightData[1].xyz - r1.xyz;
    q31.xyz = mul(float3x3(r2.xyz, r4.xyz, q46.xyz), normalize(normalize(eye1.xyz) + LightData[0].xyz));
    m30.xyz = mul(float3x3(r2.xyz, r4.xyz, q46.xyz), LightData[0].xyz);
    q7.x = log2(1 - saturate((FogParam.x - length(mdl39.xyz)) / FogParam.y));
    OUT.color_1.a = exp2(q7.x * FogParam.z);
    OUT.color_1.rgb = FogColor.rgb;
    OUT.position = mdl39;
    OUT.texcoord_0.xy = IN.LTEXCOORD_0.xy;
    OUT.texcoord_1.w = LightData[0].w;
    OUT.texcoord_1.xyz = normalize(m30.xyz);
    OUT.texcoord_2.w = 1;
    OUT.texcoord_2.xyz = mul(float3x3(r2.xyz, r4.xyz, q46.xyz), normalize(q4.xyz));
    OUT.texcoord_3.xyz = normalize(q31.xyz);
    OUT.texcoord_4.xyz = mul(float3x3(r2.xyz, r4.xyz, q46.xyz), normalize(normalize(eye1.xyz) + normalize(q4.xyz)));
    OUT.texcoord_5.w = 0.5;
    OUT.texcoord_5.xyz = compress(q4.xyz / LightData[1].w);	// [-1,+1] to [0,1]
	OUT.texcoord_6 = shw;
    return OUT;
};

// approximately 140 instruction slots used
 