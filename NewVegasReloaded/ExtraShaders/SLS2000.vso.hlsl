//
// Generated by Microsoft (R) HLSL Shader Compiler 9.23.949.2378
//
// Parameters:

float3 FogColor : register(c15);
float4 FogParam : register(c14);
float4 LightData[10] : register(c25);
row_major float4x4 ModelViewProj : register(c0);
row_major float4x4 TESR_ShadowCameraToLightTransform[2] : register(c35);

// Registers:
//
//   Name          Reg   Size
//   ------------- ----- ----
//   ModelViewProj[0] const_0        1
//   ModelViewProj[1] const_1        1
//   ModelViewProj[2] const_2        1
//   ModelViewProj[3] const_3        1
//   FogParam      const_14      1
//   FogColor      const_15      1
//   LightData[0]     const_25      1
//


// Structures:

struct VS_INPUT {
    float4 LPOSITION : POSITION;
    float3 LTANGENT : TANGENT;
    float3 LBINORMAL : BINORMAL;
    float3 LNORMAL : NORMAL;
    float4 LTEXCOORD_0 : TEXCOORD0;
    float4 LCOLOR_0 : COLOR0;
};

struct VS_OUTPUT {
    float4 color_0 : COLOR0;
    float4 color_1 : COLOR1;
    float4 position : POSITION;
    float2 texcoord_0 : TEXCOORD0;
    float4 texcoord_1 : TEXCOORD1;
	float4 texcoord_6 : TEXCOORD6;
	float4 texcoord_7 : TEXCOORD7;
    float2 ShadowNearFar : TEXCOORD8;
};

// Code:

VS_OUTPUT main(VS_INPUT IN) {
    VS_OUTPUT OUT;

    float3 l3;
    float1 q0;
    float4 r0;
	
#define	TanSpaceProj	float3x3(IN.LTANGENT.xyz, IN.LBINORMAL.xyz, IN.LNORMAL.xyz)

    l3.xyz = mul(TanSpaceProj, LightData[0].xyz);
    r0 = mul(ModelViewProj, IN.LPOSITION);
    OUT.color_0.rgba = IN.LCOLOR_0.xyzw;
    OUT.position = r0;
    q0.x = log2(1 - saturate((FogParam.x - length(r0.xyz)) / FogParam.y));
    OUT.texcoord_1.w = 1;
    OUT.texcoord_1.xyz = normalize(l3.xyz);
    OUT.color_1.a = exp2(q0.x * FogParam.z);
    OUT.color_1.rgb = FogColor.rgb;
    OUT.texcoord_0.xy = IN.LTEXCOORD_0.xy;
    OUT.texcoord_6 = mul(r0, TESR_ShadowCameraToLightTransform[0]);
	OUT.texcoord_7 = mul(r0, TESR_ShadowCameraToLightTransform[1]);
    
 	OUT.ShadowNearFar.x = TESR_ShadowCameraToLightTransform[0]._43 / TESR_ShadowCameraToLightTransform[0]._33;
 	OUT.ShadowNearFar.y = (TESR_ShadowCameraToLightTransform[0]._33 * OUT.ShadowNearFar.x) / (TESR_ShadowCameraToLightTransform[0]._33 - 1.0f);
	
    return OUT;
};

// approximately 27 instruction slots used