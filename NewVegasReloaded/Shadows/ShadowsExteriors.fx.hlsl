// Image space shadows shader for TES Reloaded

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

bool IsOutsideNdcSpace(float4 Pos) {
	return Pos.x < -1.0f || Pos.x > 1.0f ||
        Pos.y < -1.0f || Pos.y > 1.0f ||
        Pos.z <  0.0f || Pos.z > 1.0f;
}

float ShadowNearDistanceToWorldDistance(float Depth) {
    static const float zNear = TESR_ShadowCameraToLightTransformNear._43 / TESR_ShadowCameraToLightTransformNear._33;
    static const float zFar = (TESR_ShadowCameraToLightTransformNear._33 * nearZ) / (TESR_ShadowCameraToLightTransformNear._33 - 1.0f);

    // bias it from [0, 1] to [-1, 1]
    float LinearDepth = zNear / (zFar - Depth * (zFar - zNear)) * zFar;

    return (LinearDepth * 2.0) - 1.0;
}

float LookupFar(float4 ShadowPos) {
	float Shadow = tex2D(TESR_ShadowMapBufferFar, ShadowPos.xy).r;
	if (Shadow < ShadowPos.z - BIAS) {
		return TESR_ShadowData.y;
	}

	return 1.0f;
}

float Lookup(float4 ShadowPos) {
	float Shadow = tex2D(TESR_ShadowMapBufferNear, ShadowPos.xy).r;
	if (Shadow < ShadowPos.z - BIAS) {
		return TESR_ShadowData.y;
	}

	return 1.0f;
}

/*!
 * \brief Finds the best-fix shadow blocker for the current fragment
 */
float GetBlockerDepth(float4 ShadowPos) {
	// If TESR_ShadowData.y is 0, this function will take one sample directly towards the lights
	// If TESR_ShadowData.y is 1, this function will sample a 5x5 block of pixels centered on the light
	// If TESR_ShadowData.y is 2, this funciton will sample a 7x7 block...
	// TODO: Randomize the orientation of the block each fragment and maybe each frame

	const float NEAR_SHADOW_MAP_EDGE_LENGTH = 4096.0f;	// Hardcoded for now - value came from my ini
	const float NEAR_SHADOW_MAP_RADIUS = 2048.0f;	// Also hardcoded with a value that came from my personal ini

	// Size of the blocker search kernel, in world units
	const float BLOCKER_SEARCH_SIZE = 5.0f;

	const float NumSamplesHalf = abs(TESR_ShadowData.y) * 2.0f;
	const float NumSamples = NumSamplesHalf * 2.0f + 1.0f;

	const float BlockerSearchSizeTexelspace = BLOCKER_SEARCH_SIZE * (NEAR_SHADOW_MAP_EDGE_LENGTH / NEAR_SHADOW_MAP_RADIUS);
	const float BlockerSearchStepSize = BlockerSearchSizeTexelspace / NumSamples;
	const float2 UvDistanceBetweenSamples = 1.0f / BlockerSearchStepSize;

	float BlockerDepth = 0.0f;
	for(int y = -NumSamplesHalf; y < NumSamplesHalf; y++) {
		for(int x = -NumSamplesHalf; x < NumSamplesHalf; x++) {
			// TODO: Rotate the sample offset by a random amount

			const float2 SamplePos = ShadowPos.xy + float2(x, y) * UvDistanceBetweenSamples;

			const float RawDepth = tex2D(TESR_ShadowMapBufferNear, SamplePos).r;
            const float LinearDepth = ShadowNearDistanceToWorldDistance(RawDepth);

            BlockerDepth += LinearDepth;
		}
	}

    BlockerDepth /= NumSamples * NumSamples;

    return BlockerDepth;
}

float PCSS(in float4 ShadowPos) {
	const float NEAR_SHADOW_MAP_EDGE_LENGTH = 4096.0f;	// Hardcoded for now - value came from my ini
	const float NEAR_SHADOW_MAP_RADIUS = 2048.0f;	// Also hardcoded with a value that came from my personal ini

	const float BlockerDepth = GetBlockerDepth(ShadowPos);

	const float NumSamplesHalf = abs(TESR_ShadowData.y) * 2.0f;
	const float NumSamples = NumSamplesHalf * 2.0f + 1.0f;

    // Angular diameter of the Earth's sun in radians
    const float SUN_ANGULAR_DIAMETER = 0.00930842267730304f;

    const float Theta = SUN_ANGULAR_DIAMETER * 0.5f;
    const float PenumbraWidth = tan(Theta) * 2.0f * BlockerDepth;
    const float PenumbraWidthTexelspace = PenumbraWidth * (NEAR_SHADOW_MAP_EDGE_LENGTH / NEAR_SHADOW_MAP_RADIUS);
	const float2 UvDistanceBetweenSamples = NumSamples / PenumbraWidthTexelspace;

	float Shadow = 0.0f;

	for(int y = -NumSamplesHalf; y < NumSamplesHalf; y++) {
		for(int x = -NumSamplesHalf; x < NumSamplesHalf; x++) {
			// TODO: Rotate the sample offset by a random amount
			const float2 SamplePos = ShadowPos.xy + float2(x, y) * UvDistanceBetweenSamples;
			
			Shadow += Lookup(float4(SamplePos, 0, 0));
		}
	}

	Shadow /= NumSamples * NumSamples;

	return Shadow;
}

float GetLightAmountFar(float4 ShadowPos) {
	float x;
	float y;
	
    if (IsOutsideNdcSpace(ShadowPos)) {
		return 1.0f;
	}

    ShadowPos.x = ShadowPos.x * 0.5f + 0.5f;
    ShadowPos.y = ShadowPos.y * -0.5f + 0.5f;
	
	return LookupFar(ShadowPos);
}

float GetLightAmount(float4 ShadowPos, float4 ShadowPosFar) {	
	float x;
	float y;
	
    if (IsOutsideNdcSpace(ShadowPos)) {
		return GetLightAmountFar(ShadowPosFar);
	}
 
    ShadowPos.x = ShadowPos.x * 0.5f + 0.5f;
    ShadowPos.y = ShadowPos.y * -0.5f + 0.5f;
	
	return PCSS(ShadowPos);
}

float4 Shadow( VSOUT IN ) : COLOR0 {	
	float Shadow = 1.0f;
	float3 IndirectIllumination = 0.0f;

	float depth = readDepth(IN.UVCoord);
    float3 camera_vector = toWorld(IN.UVCoord) * depth;
    float4 world_pos = float4(TESR_CameraPosition.xyz + camera_vector, 1.0f);	
	
	if (world_pos.z > TESR_WaterSettings.x) {
		float4 pos = mul(world_pos, TESR_WorldViewProjectionTransform);

		float4 ShadowNear = mul(pos, TESR_ShadowCameraToLightTransformNear);

		float4 ShadowFar = mul(pos, TESR_ShadowCameraToLightTransformFar);	

		Shadow = GetLightAmount(ShadowNear, ShadowFar);
	}

    return float4(Shadow, Shadow, Shadow, 1.0f);	
}

float4 CombineShadow( VSOUT IN ) : COLOR0 {
	float3 color = tex2D(TESR_SourceBuffer, IN.UVCoord).rgb;
	float Shadow = tex2D(TESR_RenderedBuffer, IN.UVCoord).r;
	
	color.rgb *= Shadow;

    return float4(color, 1.0f);	
}

technique {
	pass {
		VertexShader = compile vs_3_0 FrameVS();
		PixelShader = compile ps_3_0 Shadow();
	}
	
	pass {
		VertexShader = compile vs_3_0 FrameVS();
		PixelShader = compile ps_3_0 CombineShadow();
	}
}
