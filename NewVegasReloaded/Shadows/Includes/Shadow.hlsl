
static const float BIAS = 0.001f;

float LinearizeShadowDepth(in float Depth, in float ZNear, in float ZFar) {
	// float NdcDepth = (Depth * 2.0) - 1.0;
	return ZNear * ZFar / ((Depth * (ZFar - ZNear)) - ZFar);
}

float LookupFar(float4 ShadowPos, float2 OffSet) {
	
	float Shadow = tex2D(TESR_ShadowMapBufferFar, ShadowPos.xy + float2(OffSet.x * TESR_ShadowData.w, OffSet.y * TESR_ShadowData.w)).r;
	if (Shadow < ShadowPos.z - BIAS) return TESR_ShadowData.y;
	return 1.0f;
	
}

float Lookup(float4 ShadowPos, float2 OffSet) {
	
	float Shadow = tex2D(TESR_ShadowMapBufferNear, ShadowPos.xy + float2(OffSet.x * TESR_ShadowData.z, OffSet.y * TESR_ShadowData.z)).r;
	if (Shadow < ShadowPos.z - BIAS) return TESR_ShadowData.y;
	return 1.0f;
	
}

float rand(in float2 co){
  return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453);
}

float GetBlockerDepth(in float4 ShadowPos, in float Near, in float Far) {
	// TODO: Randomly rotate the search kernel for each fragment and maybe each frame

	float NEAR_SHADOW_MAP_EDGE_LENGTH = 4096.0f;	// Hardcoded for now - value came from my ini
	float NEAR_SHADOW_MAP_RADIUS = 2048.0f;	// Also hardcoded with a value that came from my personal ini

	// Size of the blocker search kernel, in world units
	float BLOCKER_SEARCH_SIZE = 17.0f;

	// 5x5 sample grid
	float NumSamples = 3.0f;

	float CurFragShadowDepth = LinearizeShadowDepth(ShadowPos.z, Near, Far);

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

            float LinearBlockerDepth = LinearizeShadowDepth(RawBlockerDepth, Near, Far);

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

float PCSS(in float4 ShadowPos, in float Near, in float Far) {
	float NEAR_SHADOW_MAP_EDGE_LENGTH = 4096.0f;	// Hardcoded for now - value came from my ini
	float NEAR_SHADOW_MAP_RADIUS = 2048.0f;	// Also hardcoded with a value that came from my personal ini

	float BlockerDepth = GetBlockerDepth(ShadowPos, Near, Far);
	// return BlockerDepth;

	// 9x9 sample grid
	float NumSamples = 7.0f;

    // Angular diameter of the Earth's sun in radians
    float SUN_ANGULAR_DIAMETER = 0.00930842267730304f;

	float CurFragShadowDepth = LinearizeShadowDepth(ShadowPos.z, Near, Far);
	
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

			IncomingLight += Lookup(ShadowPos, Offset);
		}
	}

	IncomingLight /= NumSamples * NumSamples;

	return IncomingLight;
}

float GetLightAmountFar(float4 ShadowPos) {
	
	float Shadow = 0.0f;
	float x;
	float y;
	
	ShadowPos.xyz /= ShadowPos.w;
    if (ShadowPos.x < -1.0f || ShadowPos.x > 1.0f ||
        ShadowPos.y < -1.0f || ShadowPos.y > 1.0f ||
        ShadowPos.z <  0.0f || ShadowPos.z > 1.0f)
		return 1.0f;

    ShadowPos.x = ShadowPos.x *  0.5f + 0.5f;
    ShadowPos.y = ShadowPos.y * -0.5f + 0.5f;
	for (y = -0.5f; y <= 0.5f; y += 0.5f) {
		for (x = -0.5f; x <= 0.5f; x += 0.5f) {
			Shadow += LookupFar(ShadowPos, float2(x, y));
		}
	}
	Shadow /= 9.0f;
	return Shadow;
	
}

float GetLightAmount(float4 ShadowPos, float4 ShadowPosFar, float Near, float Far) {
	
	if (TESR_ShadowData.x == -1.0f) return 1.0f; // Shadows are applied in post processing (ShadowsExteriors.fx.hlsl)
	
	float Shadow = 0.0f;
	float x;
	float y;
	
	ShadowPos.xyz /= ShadowPos.w;
    if (ShadowPos.x < -1.0f || ShadowPos.x > 1.0f ||
        ShadowPos.y < -1.0f || ShadowPos.y > 1.0f ||
        ShadowPos.z <  0.0f || ShadowPos.z > 1.0f)
		return GetLightAmountFar(ShadowPosFar);
 
    ShadowPos.x = ShadowPos.x *  0.5f + 0.5f;
    ShadowPos.y = ShadowPos.y * -0.5f + 0.5f;
	if (TESR_ShadowData.x == 0.0f) {
		for (y = -0.5f; y <= 0.5f; y += 0.5f) {
			for (x = -0.5f; x <= 0.5f; x += 0.5f) {
				Shadow += Lookup(ShadowPos, float2(x, y));
			}
		}
		Shadow /= 9.0f;
	}
	else if (TESR_ShadowData.x == 1.0f) {
		for (y = -1.5f; y <= 1.5f; y += 1.0f) {
			for (x = -1.5f; x <= 1.5f; x += 1.0f) {
				Shadow += Lookup(ShadowPos, float2(x, y));
			}
		}
		Shadow /= 16.0f;
	}
	else if (TESR_ShadowData.x == 2.0f) {
		for (y = -1.0f; y <= 1.0f; y += 0.5f) {
			for (x = -1.0f; x <= 1.0f; x += 0.5f) {
				Shadow += Lookup(ShadowPos, float2(x, y));
			}
		}
		Shadow /= 25.0f;
	}
	else if(TESR_ShadowData.y == 3.0f) {
		for (y = -2.5f; y <= 2.5f; y += 1.0f) {
			for (x = -2.5f; x <= 2.5f; x += 1.0f) {
				Shadow += Lookup(ShadowPos, float2(x, y));
			}
		}
		Shadow /= 36.0f;
	}
	else {
		Shadow = PCSS(ShadowPos, Near, Far);
	}
	return Shadow;
	
}

float GetLightAmountSkinFar(float4 ShadowPos) {
					
	float Shadow = 0.0f;
	float x;
	float y;
	
	ShadowPos.xyz /= ShadowPos.w;
    if (ShadowPos.x < -1.0f || ShadowPos.x > 1.0f ||
        ShadowPos.y < -1.0f || ShadowPos.y > 1.0f ||
        ShadowPos.z <  0.0f || ShadowPos.z > 1.0f)
		return 1.0f;
 
    ShadowPos.x = ShadowPos.x *  0.5f + 0.5f;
    ShadowPos.y = ShadowPos.y * -0.5f + 0.5f;
	for (y = -0.5f; y <= 0.5f; y += 0.5f) {
		for (x = -0.5f; x <= 0.5f; x += 0.5f) {
			Shadow += Lookup(ShadowPos, float2(x, y));
		}
	}
	Shadow /= 9.0f;
	return Shadow;
	
}

float GetLightAmountSkin(float4 ShadowPos, float4 ShadowPosFar) {
	
	if (TESR_ShadowData.x == -1.0f) return 1.0f; // Shadows are applied in post processing (ShadowsExteriors.fx.hlsl)
	
	float Shadow = 0.0f;
	float x;
	float y;
	
	ShadowPos.xyz /= ShadowPos.w;
    if (ShadowPos.x < -1.0f || ShadowPos.x > 1.0f ||
        ShadowPos.y < -1.0f || ShadowPos.y > 1.0f ||
        ShadowPos.z <  0.0f || ShadowPos.z > 1.0f)
		return GetLightAmountSkinFar(ShadowPosFar);
 
    ShadowPos.x = ShadowPos.x *  0.5f + 0.5f;
    ShadowPos.y = ShadowPos.y * -0.5f + 0.5f;
	for (y = -0.1f; y <= 0.1f; y += 0.05f) {
		for (x = -0.1f; x <= 0.1f; x += 0.05f) {
			Shadow += Lookup(ShadowPos, float2(x, y));
		}
	}
	Shadow /= 25.0f;
	return Shadow;
	
}

float GetLightAmountGrass(float4 ShadowPos) {
	
	if (TESR_ShadowData.x == -1.0f) return 1.0f; // Shadows are applied in post processing (ShadowsExteriors.fx.hlsl)
	
	float Shadow = 0.0f;
	float x;
	float y;
	
	ShadowPos.xyz /= ShadowPos.w;
    if (ShadowPos.x < -1.0f || ShadowPos.x > 1.0f ||
        ShadowPos.y < -1.0f || ShadowPos.y > 1.0f ||
        ShadowPos.z <  0.0f || ShadowPos.z > 1.0f)
		return 1.0f;
 
    ShadowPos.x = ShadowPos.x *  0.5f + 0.5f;
    ShadowPos.y = ShadowPos.y * -0.5f + 0.5f;
	Shadow = Lookup(ShadowPos, float2(0.0f, 0.0f));
	return Shadow;
	
}