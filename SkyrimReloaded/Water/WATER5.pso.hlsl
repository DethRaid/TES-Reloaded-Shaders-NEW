//
// Generated by Microsoft (R) HLSL Shader Compiler 9.27.952.3022
//
// Parameters:

row_major float4x4 TextureProj : register(c0);
float4 ShallowColor : register(c4);
float4 DeepColor : register(c5);
float4 ReflectionColor : register(c6);
float4 FresnelRI : register(c7);
float4 PosAdjust : register(c8);
float4 ReflectPlane : register(c9);
float4 CameraData : register(c10);
float4 ProjData : register(c11);
float4 VarAmounts : register(c12);
float4 NormalsAmplitude : register(c13);
float4 WaterParams : register(c14);
float4 FogParam : register(c15);
float4 DepthControl : register(c16);
float4 FogNearColor : register(c17);
float4 SunDir : register(c18);
float4 SunColor : register(c19);
float4 VPOSOffset : register(c20);
float4 TESR_WaterCoefficients : register(c21);
float4 TESR_WaveParams : register(c22);
float4 TESR_WaterVolume : register(c23);
float4 TESR_Tick : register(c24);
float4 TESR_ReciprocalResolution : register(c25);
float4x4 TESR_ViewTransform : register(c26);
float4x4 TESR_ProjectionTransform : register(c30);

sampler2D RefractionSampler : register(s0);
sampler2D DepthSampler : register(s1);
samplerCUBE CubeMapSampler : register(s2);
sampler2D Normals01Sampler : register(s3);
sampler2D Normals02Sampler : register(s4);
sampler2D Normals03Sampler : register(s5);
sampler2D TESR_RenderedBuffer : register(s6) = sampler_state { };
sampler3D TESR_CausticSampler : register(s7) < string ResourceName = "Water\water_NRM.dds"; > = sampler_state { ADDRESSU = WRAP; ADDRESSV = WRAP; ADDRESSW = WRAP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };

static const float nearZ = TESR_ProjectionTransform._34 / TESR_ProjectionTransform._33;
static const float farZ = (TESR_ProjectionTransform._33 * nearZ) / (TESR_ProjectionTransform._33 - 1.0f);
static const float Zmul = nearZ * farZ;
static const float Zdiff = farZ - nearZ;
static const float depthRange = nearZ - farZ;
static const float frame = TESR_Tick.y * TESR_WaveParams.z / 1500.0f;

// Registers:
//
//   Name              Reg   Size
//   ----------------- ----- ----
//   TextureProj       const_0       4
//   ShallowColor      const_4       1
//   DeepColor         const_5       1
//   ReflectionColor   const_6       1
//   FresnelRI         const_7       1
//   PosAdjust         const_8       1
//   ReflectPlane      const_9       1
//   CameraData        const_10      1
//   ProjData          const_11      1
//   VarAmounts        const_12      1
//   NormalsAmplitude  const_13      1
//   WaterParams       const_14      1
//   FogParam          const_15      1
//   DepthControl      const_16      1
//   FogNearColor      const_17      1
//   SunDir            const_18      1
//   SunColor          const_19      1
//   VPOSOffset        const_20      1
//   RefractionSampler texture_0       1
//   DepthSampler      texture_1       1
//   CubeMapSampler    texture_2       1
//   Normals01Sampler  texture_3       1
//   Normals02Sampler  texture_4       1
//   Normals03Sampler  texture_5       1
//

// Structures:

struct VS_INPUT {
    float4 LTEXCOORD_0 : TEXCOORD0;
    float4 LTEXCOORD_1 : TEXCOORD1;
    float2 LTEXCOORD_2 : TEXCOORD2;
    float3 LTEXCOORD_4 : TEXCOORD4;
    float4 LCOLOR_1 : COLOR1;
};

struct PS_OUTPUT {
    float4 color_0 : COLOR0;
};

// Code:
float3 toWorld(float2 tex)
{
    float3 v = float3(TESR_ViewTransform[2][0], TESR_ViewTransform[2][1], TESR_ViewTransform[2][2]);
    v += (1 / TESR_ProjectionTransform[0][0] * (2 * tex.x - 1)).xxx * float3(TESR_ViewTransform[0][0], TESR_ViewTransform[0][1], TESR_ViewTransform[0][2]);
    v += (-1 / TESR_ProjectionTransform[1][1] * (2 * tex.y - 1)).xxx * float3(TESR_ViewTransform[1][0], TESR_ViewTransform[1][1], TESR_ViewTransform[1][2]);
    return v;
}

float readDepth(in float2 coord : TEXCOORD0)
{
	float posZ = tex2D(DepthSampler, coord).x;
	posZ = Zmul / ((posZ * Zdiff) - farZ);
	return posZ;
}

PS_OUTPUT main(VS_INPUT IN, float2 PixelPos : VPOS) {
    PS_OUTPUT OUT;

#define	expand(v)		(((v) - 0.5) / 0.5)
#define	compress(v)		(((v) * 0.5) + 0.5)
#define	shade(n, l)		max(dot(n, l), 0)
#define	shades(n, l)	saturate(dot(n, l))
#define	weight(v)		dot(v, 1)
#define	sqr(v)			((v) * (v))

    const int4 const_21 = {-8192, 2, -1, 1};
    const float4 const_22 = {-0.0989999995, 0.99000001, 0, 0};
    const int4 const_23 = {2, -1, -2, -0};
    const int4 const_24 = {0, -1, 1, 0};

    float1 q0;
    float2 q1;
    float3 q11;
    float1 q124;
    float3 q14;
    float1 q15;
    float3 q2;
    float1 q3;
    float1 q4;
    float1 q5;
    float3 q7;
    float1 q8;
    float3 q9;
    float4 r0;
    float4 r1;
    float4 r2;
    float4 r3;
    float4 r4;
    float4 r5;
    float4 r6;
	
	float2 UVCoord = (PixelPos + 0.5) * TESR_ReciprocalResolution.xy;
	float3 eyePos = PosAdjust.xyz;
	eyePos.z = -IN.LTEXCOORD_0.z;

    float4 color = tex2D(TESR_RenderedBuffer, UVCoord);
    float depth = readDepth(UVCoord);
    float3 cameraVector = toWorld(UVCoord);
    float3 worldPos = eyePos + cameraVector * depth;
	
    r0.xyzw = tex2D(Normals03Sampler, IN.LTEXCOORD_2.xy);
    r1.xyzw = tex2D(Normals01Sampler, IN.LTEXCOORD_1.xy);
    q2.xyz = normalize(IN.LTEXCOORD_0.xyz);
    r2.yw = const_23.yw;
    r3.xw = const_21.xw;
    q0.x = saturate((IN.LTEXCOORD_0.w - 8192) / (r3.x + WaterParams.x));
    q9.xyz = SunDir.w * SunColor.rgb;
    r3.y = 1.0 / ProjData.y;
    r3.x = 1.0 / ProjData.x;
    r1.xyz = (NormalsAmplitude.x * TESR_WaveParams.x * ((2 * r1.xyz) + const_23.yyz)) - r2.wwy;
    r2.xyzw = tex2D(Normals02Sampler, IN.LTEXCOORD_1.zw);
    r1.xyz = (q0.x * (expand(r2.xyz) * NormalsAmplitude.y * TESR_WaveParams.x)) + r1.xyz;
    r0.xyz = (q0.x * (expand(r0.xyz) * NormalsAmplitude.z * TESR_WaveParams.x)) + r1.xyz;
    q1.xy = (PixelPos.xy * VPOSOffset.xy) + VPOSOffset.zw;
    r2.xyzw = tex2D(DepthSampler, q1.xy);
    r2.z = CameraData.w / (CameraData.x - (r2.x * CameraData.z));
    r2.xy = (expand(q1.xy) * r2.z) * r3.xy;
    q14.xyz = length(r2.xyz) * -q2.xyz;
    q15.x = dot(q14.xyz, ReflectPlane.xyz);
    q3.x = (r3.w - (ReflectPlane.w / q15.x)) * TESR_WaterVolume.z;
    r1.x = length(q14.xyz) * q3.x;
    r1.z = abs(q15.x) * q3.x;
    r4.xyzw = saturate((1.0 / FogParam.z) * r1.xxzz);
    q4.x = pow(abs(saturate((1.0 / FogParam.w) * (FogParam.z - (r4.y * FogParam.z)))), FogNearColor.a);
    r5.zw = (IN.LTEXCOORD_4.z * -const_23.yw) - const_23.wy;
    r1.xyzw = ((r4.xyzw - 1) * DepthControl.xyzw) + r3.w;
    r3.xyz = normalize((r1.z * (normalize(r0.xyz) + const_23.wwy)) - const_23.wwy);
    q8.x = pow(abs(shades(q2.xyz - ((2 * dot(q2.xyz, r3.xyz)) * r3.xyz), SunDir.xyz)), VarAmounts.x);
    q5.x = 1 - shades(-q2.xyz, r3.xyz);
	r0.xyz = (r4.y * (DeepColor.rgb - ShallowColor.rgb)) + ShallowColor.rgb;
    r4.yw = WaterParams.yw;
    q124.x = (q0.x * ((lerp(FresnelRI.x, r3.w, sqr(sqr(q5.x)) * q5.x) * r1.x) - 1)) + 1;
    q7.xyz = (WaterParams.y * r3.xyz) + ((r4.y * const_24.xxy) + const_24.xxz);
    r5.xy = ((r1.y * VarAmounts.w) * r3.xy) + IN.LTEXCOORD_4.xy;
    r6.w = dot(TextureProj[3].xyzw, r5.xyzw);
    r6.y = r6.w - dot(TextureProj[1].xyzw, r5.xyzw);
    r6.z = dot(TextureProj[2].xyzw, r5.xyzw);
    r6.x = dot(TextureProj[0].xyzw, r5.xyzw);
    r5.xyzw = tex2Dproj(RefractionSampler, r6.xyzw);
    float3 waterfloorNorm = normalize(cross(ddx(worldPos), ddy(worldPos)));
	float3 causticsPos = worldPos - SunDir.xyz * (worldPos.z / SunDir.z);
	float caustics = tex3D(TESR_CausticSampler, float3(causticsPos.xy / 512, frac(frame))).b;
	caustics += TESR_WaterVolume.w * tex3D(TESR_CausticSampler, float3(IN.LTEXCOORD_2.xy, frac(frame))).b;
	caustics += TESR_WaterVolume.w * 0.6 * tex3D(TESR_CausticSampler, float3(IN.LTEXCOORD_1.xy, frac(frame))).b;
	caustics += TESR_WaterVolume.w * 0.4 * tex3D(TESR_CausticSampler, float3(IN.LTEXCOORD_1.zw, frac(frame))).b;
	float causticsAngle = saturate(dot(-waterfloorNorm, SunDir.xyz));
	r5.rgb *= 1 + TESR_WaterVolume.x * caustics * causticsAngle * SunColor.xyz;
	float SinBoverSinA = -normalize(cameraVector).z;
	float3 waterColor = TESR_WaterCoefficients.w * FogNearColor.xyz / (TESR_WaterCoefficients.xyz * (1 + SinBoverSinA));
	r0.rgb += waterColor;
    r0.xyz = ((1 - q4.x) * (r0.xyz - (WaterParams.w * r5.xyz))) + (r5.xyz * WaterParams.w);
    r5.xyzw = texCUBE(CubeMapSampler, q2.xyz - ((2 * dot(q2.xyz, q7.xyz)) * q7.xyz));
    r4.xyz = lerp(r0.xyz, (VarAmounts.y * TESR_WaveParams.w * ((r4.w * r5.xyz) - ReflectionColor.rgb)) + ReflectionColor.rgb, q124.x);
    r0.xyz = (q9.xyz * pow(abs(shades(r3.xyz, const_22.xxy)), ShallowColor.a * 5)) * WaterParams.z;
    q11.xyz = lerp((r1.w * ((DeepColor.a * (q9.xyz * q8.x)) + r0.xyz)) + r4.xyz, IN.LCOLOR_1.xyz, IN.LCOLOR_1.w);
    OUT.color_0.a = 1;
    OUT.color_0.rgb = lerp(q11.xyz, color.rgb, saturate(pow(saturate(exp(worldPos.z / (800 * TESR_WaterVolume.y))), 90)));

    return OUT;
};