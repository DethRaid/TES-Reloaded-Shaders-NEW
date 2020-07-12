//
// Generated by Microsoft (R) D3DX9 Shader Compiler 9.08.299.0000
//
//   vsa shaderdump19/SLS2042.vso /Fcshaderdump19/SLS2042.vso.dis
//
//
// Parameters:
//
row_major float4x4 ModelViewProj : register(c0);
float3 LightDirection[3] : register(c13);
row_major float4x4 ShadowProj : register(c28);
float4 ShadowProjData : register(c32);
float4 ShadowProjTransform : register(c33);
row_major float4x4 TESR_ShadowCameraToLightTransform[2] : register(c34);
//
//
// Registers:
//
//   Name                Reg   Size
//   ------------------- ----- ----
//   ModelViewProj[0]       const_0        1
//   ModelViewProj[1]       const_1        1
//   ModelViewProj[2]       const_2        1
//   ModelViewProj[3]       const_3        1
//   LightDirection[0]      const_13       1
//   ShadowProj[0]          const_28       1
//   ShadowProj[1]          const_29       1
//   ShadowProj[2]          const_30       1
//   ShadowProj[3]          const_31       1
//   ShadowProjData      const_32      1
//   ShadowProjTransform const_33      1
//


// Structures:

struct VS_INPUT {
    float4 position : POSITION;
    float3 tangent : TANGENT;
    float3 binormal : BINORMAL;
    float3 normal : NORMAL;
    float4 texcoord_0 : TEXCOORD0;
    float4 color_0 : COLOR0;

#define	TanSpaceProj	float3x3(IN.tangent.xyz, IN.binormal.xyz, IN.normal.xyz)
};

struct VS_OUTPUT {
    float4 position : POSITION;
    float2 texcoord_0 : TEXCOORD0;
    float2 texcoord_1 : TEXCOORD1;
    float4 texcoord_2 : TEXCOORD2;
    float3 texcoord_3 : TEXCOORD3;
    float4 texcoord_6 : TEXCOORD6;
	float4 texcoord_7 : TEXCOORD7;
};

// Code:

VS_OUTPUT main(VS_INPUT IN) {
    VS_OUTPUT OUT;

#define	expand(v)		(((v) - 0.5) / 0.5)
#define	compress(v)		(((v) * 0.5) + 0.5)

    const float4 const_4 = {0.5, 1, 0, 0};
	
	float4 r0;
	
	r0 = mul(ModelViewProj, IN.position);
    OUT.position = r0;
    OUT.texcoord_0.xy = IN.texcoord_0.xy;
    OUT.texcoord_1.xy = IN.texcoord_0.xy;
    OUT.texcoord_2.xyzw = (IN.color_0.xyzx * const_4.yyyz) + const_4.zzzy;
    OUT.texcoord_3.xyz = compress(mul(TanSpaceProj, LightDirection[0].xyz));
	OUT.texcoord_6 = mul(r0, TESR_ShadowCameraToLightTransform[0]);
	OUT.texcoord_7 = mul(r0, TESR_ShadowCameraToLightTransform[1]);
    return OUT;
	
};

// approximately 22 instruction slots used
