// Image space shadows shader for Oblivion Reloaded

float4x4 TESR_WorldViewProjectionTransform;
float4x4 TESR_ViewTransform;
float4x4 TESR_ProjectionTransform;
float4x4 TESR_ShadowCameraToLightTransformNear;
float4x4 TESR_ShadowCameraToLightTransformFar;
float4 TESR_CameraPosition;
float4 TESR_WaterSettings;
float4 TESR_ShadowData;
float4 TESR_ReciprocalResolution;

sampler2D TESR_RenderedBuffer : register(s0) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };
sampler2D TESR_DepthBuffer : register(s1) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };
sampler2D TESR_SourceBuffer : register(s2) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };
sampler2D TESR_ShadowMapBufferNear : register(s3) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };
sampler2D TESR_ShadowMapBufferFar : register(s4) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };

sampler2D TESR_ShadowGbufferColorNear : register(s5) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };
sampler2D TESR_ShadowGbufferNormalNear : register(s6) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };

sampler2D TESR_ShadowGbufferColorFar : register(s7) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };
sampler2D TESR_ShadowGBufferNormalFar : register(s8) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };

static const float nearZ = TESR_ProjectionTransform._43 / TESR_ProjectionTransform._33;
static const float farZ = (TESR_ProjectionTransform._33 * nearZ) / (TESR_ProjectionTransform._33 - 1.0f);
static const float Zmul = nearZ * farZ;
static const float Zdiff = farZ - nearZ;
static const float BIAS = 0.002f;
static const float2 OffsetMaskH = float2(1.0f, 0.0f);
static const float2 OffsetMaskV = float2(0.0f, 1.0f);

struct VSOUT
{
	float4 vertPos : POSITION;
	float2 UVCoord : TEXCOORD0;
};

struct VSIN
{
	float4 vertPos : POSITION0;
	float2 UVCoord : TEXCOORD0;
};

VSOUT FrameVS(VSIN IN)
{
	VSOUT OUT = (VSOUT)0.0f;
	OUT.vertPos = IN.vertPos;
	OUT.UVCoord = IN.UVCoord;
	return OUT;
}

static const int cKernelSize = 7;

static const float BlurWeights[cKernelSize] = {
    0.064759,
    0.120985,
    0.176033,
    0.199471,
    0.176033,
    0.120985,
    0.064759,
};
 
static const float2 BlurOffsets[cKernelSize] = {
	float2(-3.0f * TESR_ReciprocalResolution.x, -3.0f * TESR_ReciprocalResolution.y),
	float2(-2.0f * TESR_ReciprocalResolution.x, -2.0f * TESR_ReciprocalResolution.y),
	float2(-1.0f * TESR_ReciprocalResolution.x, -1.0f * TESR_ReciprocalResolution.y),
	float2( 0.0f * TESR_ReciprocalResolution.x,  0.0f * TESR_ReciprocalResolution.y),
	float2( 1.0f * TESR_ReciprocalResolution.x,  1.0f * TESR_ReciprocalResolution.y),
	float2( 2.0f * TESR_ReciprocalResolution.x,  2.0f * TESR_ReciprocalResolution.y),
	float2( 3.0f * TESR_ReciprocalResolution.x,  3.0f * TESR_ReciprocalResolution.y),
};

float readDepth(in float2 coord : TEXCOORD0) {
	float posZ = tex2D(TESR_DepthBuffer, coord).x;
	posZ = Zmul / ((posZ * Zdiff) - farZ);
	return posZ;
}

float readDepth01(in float2 coord : TEXCOORD0) {
	float posZ = tex2D(TESR_DepthBuffer, coord).x;
	return (2.0f * nearZ) / (nearZ + farZ - posZ * (farZ - nearZ));
}

float3 toWorld(float2 tex) {
    float3 v = float3(TESR_ViewTransform[0][2], TESR_ViewTransform[1][2], TESR_ViewTransform[2][2]);
    v += (1 / TESR_ProjectionTransform[0][0] * (2 * tex.x - 1)).xxx * float3(TESR_ViewTransform[0][0], TESR_ViewTransform[1][0], TESR_ViewTransform[2][0]);
    v += (-1 / TESR_ProjectionTransform[1][1] * (2 * tex.y - 1)).xxx * float3(TESR_ViewTransform[0][1], TESR_ViewTransform[1][1], TESR_ViewTransform[2][1]);
    return v;
}

float LookupFar(float4 ShadowPos) {	
	float Shadow = tex2D(TESR_ShadowMapBufferFar, ShadowPos.xy).r;
	if (Shadow < ShadowPos.z - BIAS) return TESR_ShadowData.y;
	return 1.0f;	
}

bool IsOutsideClipSpace(float4 Pos) {
	return Pos.x < -1.0f || Pos.x > 1.0f ||
        Pos.y < -1.0f || Pos.y > 1.0f ||
        Pos.z <  0.0f || Pos.z > 1.0f;
}

float GetLightAmountFar(float4 ShadowPos) {
	float x;
	float y;
	
    if (IsOutsideClipSpace(ShadowPos.xyz)) {
		return 1.0f;
	}

    ShadowPos.x = ShadowPos.x *  0.5f + 0.5f;
    ShadowPos.y = ShadowPos.y * -0.5f + 0.5f;
	return LookupFar(ShadowPos);	
}

float Lookup(float4 ShadowPos) {	
	float Shadow = tex2D(TESR_ShadowMapBufferNear, ShadowPos.xy).r;
	if (Shadow < ShadowPos.z - BIAS) return TESR_ShadowData.y;
	return 1.0f;	
}

float GetLightAmount(float4 ShadowPos, float4 ShadowPosFar) {	
	float x;
	float y;
	
    if (IsOutsideClipSpace(ShadowPos.xyz)) {
		return GetLightAmountFar(ShadowPosFar);
	}
 
    ShadowPos.x = ShadowPos.x *  0.5f + 0.5f;
    ShadowPos.y = ShadowPos.y * -0.5f + 0.5f;
	return Lookup(ShadowPos);	
}

float3 SampleLightingHemisphere(float3 WorldspaceLocation, float4 ShadowPos, float4 ShadowPosFar) {
	const uint FILTER_SIZE_X = 5;
	const uint FILTER_SIZE_Y = FILTER_SIZE_Y;

	const uint FILTER_SIZE_X_HALF = FILTER_SIZE_X / 2;
	const uint FILTER_SIZE_Y_HALF = FILTER_SIZE_Y / 2;

	const float2 ShadowTexelSize = 1.f / 4096.f;	// Hardcoded from my settings file
	const float2 ShadowFarTexelSize = 1.f / 2048.f;	// Hardcoded from my settings file

	float3 IncomingLight = 0.0f;


	for(int y = -FILTER_SIZE_Y_HALF, y < FILTER_SIZE_Y_HALF; y++) {
		for(int x = -FILTER_SIZE_X_HALF; x < FILTER_SIZE_X_HALF; x++) {

		}
	}

	return IncomingLight;
}

float4 Shadow( VSOUT IN ) : COLOR0 {	
	float Shadow = 1.0f;
	float3 IncomingIndirectLight = 0.0f;

	float depth = readDepth(IN.UVCoord);
    float3 camera_vector = toWorld(IN.UVCoord) * depth;
    float4 world_pos = float4(TESR_CameraPosition.xyz + camera_vector, 1.0f);	
	
	if (world_pos.z > TESR_WaterSettings.x) {
		float4 pos = mul(world_pos, TESR_WorldViewProjectionTransform);
		float4 ShadowNear = mul(pos, TESR_ShadowCameraToLightTransformNear);
		ShadowNear /= ShadowNear.w;

		float4 ShadowFar = mul(pos, TESR_ShadowCameraToLightTransformFar);	
		ShadowFar /= ShadowFar.w;
		
		Shadow = GetLightAmount(ShadowNear, ShadowFar);
		
		if(abs(TESR_ShadowData.z - 1.0) < 0.001) {
			IncomingIndirectLight = SampleLightingHemisphere(world_pos.xyz, ShadowNear, ShadowFar);
		}
	}

	float3 color = tex2D(TESR_SourceBuffer, IN.UVCoord).rgb;
	
	color.rgb *= Shadow;
    return float4(color + IncomingIndirectLight, 1.0f);	
}

technique {	
	pass {
		VertexShader = compile vs_3_0 FrameVS();
		PixelShader = compile ps_3_0 Shadow();
	}
}
