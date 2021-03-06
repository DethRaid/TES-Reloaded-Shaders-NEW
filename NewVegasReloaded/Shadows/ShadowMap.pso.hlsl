
float4 TESR_ShadowData : register(c0);
sampler2D DiffuseMap : register(s0);
sampler2D NormalsMap : register(s1);
sampler2D GlowMap : register(s2);

struct VS_OUTPUT {
    float4 texcoord_0 : TEXCOORD0;
	float4 texcoord_1 : TEXCOORD1;
};

struct PS_OUTPUT {
    float4 color_0 : COLOR0;
	float4 color_specular : COLOR1;
	float4 normal_roughness : COLOR2;
};


PS_OUTPUT main(VS_OUTPUT IN) {
    PS_OUTPUT OUT;
	OUT.color_specular = float4(0.f, 0.f, 0.f, 0.f);
	OUT.normal_roughness = float4(0.5f, 0.5f, 1.0f, 0.8f);

	if (TESR_ShadowData.x == 2.0f || TESR_ShadowData.y == 1.0f) { // Leaves (Speedtrees) or alpha is required
		float4 r0 = tex2D(DiffuseMap, IN.texcoord_1.xy);
		if (r0.a <= 0.2f) {
			discard;
		}
		
		if (TESR_ShadowData.z < 0.5f) {	// Reflectance Shadow Maps are enabled. TODO: Is this check necessary?
			OUT.color_specular.rgb = DiffuseColor.rgb;

			float3 Normals = tex2D(NormalsMap, IN.texcoord_1.xy).rgb;	// Don't try to unpack here, just pass the data down the rendering pipeline
			OUT.normal_roughness.rgb = Normal;
		}
	}
    OUT.color_0 = IN.texcoord_0.z / IN.texcoord_0.w;
    return OUT;
	
};