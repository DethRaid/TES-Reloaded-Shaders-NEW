//
// Generated by Microsoft (R) D3DX9 Shader Compiler 9.08.299.0000
//
//   psa SLS2048.pso /FcSLS2048.pso.dis
//
//
// Parameters:
//
float4 AmbientColor : register(c1);
float4 PSLightColor[4] : register(c2);
float4 TESR_TerrainData : register(c6);
float4 TESR_ShadowData : register(c7);

sampler2D BaseMap : register(s0);
sampler2D NormalMap : register(s1);
sampler2D ShadowMap : register(s2);
sampler2D ShadowMaskMap : register(s3);
sampler2D TESR_ShadowMapBufferNear : register(s4) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };
sampler2D TESR_ShadowMapBufferFar : register(s5) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };

//
//
// Registers:
//
//   Name          Reg   Size
//   ------------- ----- ----
//   AmbientColor  const_1       1
//   PSLightColor[0]  const_2        1
//   BaseMap       texture_0       1
//   NormalMap     texture_1       1
//   ShadowMap     texture_2       1
//   ShadowMaskMap texture_3       1
//


// Structures:

struct VS_OUTPUT {
    float2 BaseUV : TEXCOORD0;
    float2 NormalUV : TEXCOORD1;
    float3 texcoord_2 : TEXCOORD2_centroid;
    float3 texcoord_3 : TEXCOORD3_centroid;
    float4 texcoord_6 : TEXCOORD6;
	float4 texcoord_7 : TEXCOORD7;
};

struct PS_OUTPUT {
    float4 color_0 : COLOR0;
};

#include "../Shadows/Includes/Shadow.hlsl"

PS_OUTPUT main(VS_OUTPUT IN) {
    PS_OUTPUT OUT;

#define	expand(v)		(((v) - 0.5) / 0.5)
#define	compress(v)		(((v) * 0.5) + 0.5)
#define	shade(n, l)		max(dot(n, l), 0)
#define	shades(n, l)	saturate(dot(n, l))
	
    float3 r0;
    float3 r3;
	float spclr;
	
    r0.xyz = tex2D(NormalMap, IN.NormalUV.xy).xyz;
    r3.xyz = tex2D(BaseMap, IN.BaseUV.xy).xyz;
    r0.x = shades((IN.texcoord_3.xyz * 2) - 1, normalize(expand(r0.xyz)));
    r0.xyz = r3.xyz * ((GetLightAmount(IN.texcoord_6, IN.texcoord_7) * (r0.x * PSLightColor[0].rgb)) + AmbientColor.rgb);
	spclr = smoothstep(0.0, 0.25, length(r3.rgb)) * (r3.b * 2.0 * TESR_TerrainData.z) + 1.0;
    OUT.color_0.a = 1;
    OUT.color_0.rgb = r0.xyz * IN.texcoord_2.xyz * spclr;
    return OUT;
	
};

// approximately 20 instruction slots used (4 texture, 16 arithmetic)
