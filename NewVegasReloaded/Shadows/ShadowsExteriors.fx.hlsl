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
sampler2D TESR_DepthBuffer : register(s1) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = POINT; MINFILTER = POINT; MIPFILTER = POINT; };
sampler2D TESR_SourceBuffer : register(s2) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };
sampler2D TESR_ShadowMapBufferNear : register(s3) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = POINT; MINFILTER = POINT; MIPFILTER = POINT; };
sampler2D TESR_ShadowMapBufferFar : register(s4) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = POINT; MINFILTER = POINT; MIPFILTER = POINT; };

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

float LinearizeShadowDepth(float Depth) {
 	float ZNear = TESR_ShadowCameraToLightTransformNear._43 / TESR_ShadowCameraToLightTransformNear._33;
 	float ZFar = (TESR_ShadowCameraToLightTransformNear._33 * ZNear) / (TESR_ShadowCameraToLightTransformNear._33 - 1.0f);
	
	return ZNear * ZFar / ((Depth * (ZFar - ZNear)) - ZFar);
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

float rand(float2 co) {
  return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
}

float GetBlockerDepth(float4 ShadowPos) {
	// TODO: Randomly rotate the search kernel for each fragment and maybe each frame

	float NEAR_SHADOW_MAP_EDGE_LENGTH = 4096.0f;	// Hardcoded for now - value came from my ini
	float NEAR_SHADOW_MAP_RADIUS = 2048.0f;	// Also hardcoded with a value that came from my personal ini

	// Size of the blocker search kernel, in world units
	float BLOCKER_SEARCH_SIZE = 17.0f;

	// 5x5 sample grid
	float NumSamples = 5.0f;

	float CurFragShadowDepth = LinearizeShadowDepth(ShadowPos.z);

	float BlockerSearchSizeTexelspace = BLOCKER_SEARCH_SIZE * (NEAR_SHADOW_MAP_EDGE_LENGTH / NEAR_SHADOW_MAP_RADIUS);
	float BlockerSearchStepSize = BlockerSearchSizeTexelspace / NumSamples;
	float UvDistanceBetweenSamples = BlockerSearchStepSize / NEAR_SHADOW_MAP_EDGE_LENGTH;

	float TexelOffsetLowerBound = -floor(NumSamples / 2.0f);
	float TexelOffsetUpperBound = -TexelOffsetLowerBound + 1.0f;
	
	float Angle = rand(ShadowPos.xy) * 2.0f * 3.14159f;
	float SinTheta = sin(Angle);
	float CosTheta = cos(Angle);
	float2x2 RotationMatrix = float2x2(CosTheta, -SinTheta, SinTheta, CosTheta);

	float BlockerDepth = 0.0f;
	float NumBlockerSamples = 0.0f;
	
	for (int y = TexelOffsetLowerBound; y < TexelOffsetUpperBound; y++) {
		for (int x = TexelOffsetLowerBound; x < TexelOffsetUpperBound; x++) {
			float2 Offset = float2(x, y) * float2(UvDistanceBetweenSamples, UvDistanceBetweenSamples);
			Offset = mul(Offset, RotationMatrix);
			float2 SamplePos = ShadowPos.xy + Offset;

			float RawBlockerDepth = tex2D(TESR_ShadowMapBufferNear, SamplePos.xy).r;			
			if(RawBlockerDepth < BIAS || RawBlockerDepth > 1.0 - BIAS) {
				// Ignore places where the shadowmap is at its limits
				continue;
			}

            float LinearBlockerDepth = LinearizeShadowDepth(RawBlockerDepth);

			if (LinearBlockerDepth > CurFragShadowDepth - BIAS) {
				BlockerDepth += LinearBlockerDepth;
				NumBlockerSamples += 1.0f;
			}
		}
	}

	if (NumBlockerSamples > 0.0f) {
    	BlockerDepth /= NumBlockerSamples;
	}

    return BlockerDepth;
}

float PCSS(in float4 ShadowPos) {
	float NEAR_SHADOW_MAP_EDGE_LENGTH = 4096.0f;	// Hardcoded for now - value came from my ini
	float NEAR_SHADOW_MAP_RADIUS = 2048.0f;	// Also hardcoded with a value that came from my personal ini

	float BlockerDepth = GetBlockerDepth(ShadowPos);
	// return BlockerDepth;

	// 9x9 sample grid
	float NumSamples = 9.0f;

    // Angular diameter of the Earth's sun in radians
    float SUN_ANGULAR_DIAMETER = 0.00930842267730304f;

	float CurFragShadowDepth = LinearizeShadowDepth(ShadowPos.z);
	
	float Theta = SUN_ANGULAR_DIAMETER * 0.5f;
    float PenumbraWidth = 91.0f * (CurFragShadowDepth - BlockerDepth) / BlockerDepth;
	if(BlockerDepth == 0.0f) {
		PenumbraWidth = 0.0f;
	}
	
    float PenumbraWidthTexelspace = PenumbraWidth * (NEAR_SHADOW_MAP_EDGE_LENGTH / NEAR_SHADOW_MAP_RADIUS);
	float UvPenumbraWidth = PenumbraWidthTexelspace / NEAR_SHADOW_MAP_EDGE_LENGTH;
	float UvDistanceBetweenSamples = UvPenumbraWidth / NumSamples;
	
	float Angle = rand(ShadowPos.xy) * 2.0f * 3.14159f;
	float SinTheta = sin(Angle);
	float CosTheta = cos(Angle);
	float2x2 RotationMatrix = float2x2(CosTheta, -SinTheta, SinTheta, CosTheta);

	float IncomingLight = 0.0f;

	float TexelOffsetLowerBound = -floor(NumSamples / 2.0f);
	float TexelOffsetUpperBound = -TexelOffsetLowerBound + 1.0f;

	for (int y = TexelOffsetLowerBound; y < TexelOffsetUpperBound; y++) {
		for (int x = TexelOffsetLowerBound; x < TexelOffsetUpperBound; x++) {
			float2 Offset = float2(x, y) * float2(UvDistanceBetweenSamples, UvDistanceBetweenSamples);
			Offset = mul(Offset, RotationMatrix);
			float2 SamplePos = ShadowPos.xy + Offset;
			
			IncomingLight += Lookup(float4(SamplePos, ShadowPos.z, 0));
		}
	}

	IncomingLight /= NumSamples * NumSamples;

	return IncomingLight;
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
