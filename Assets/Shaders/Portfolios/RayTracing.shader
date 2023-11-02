Shader "RayTracing"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			float3 ViewParams;
			float4x4 CamLocalToWorldMatrix;

			struct Ray {
				float3 origin;
				float3 dir;
				float time;
			};

			struct RayTracingMaterial {
				float4 color;
				float4 specularColor;
				float4 emissionColor;
				float emissionStrength;
				float smoothness;
				float specularProbability;
				float refractionIndex;
				int isVolume;
				float volumeDensity;
			};

			struct HitInfo {
				bool didHit;
				float dst;
				float3 hitPoint;
				float3 normal;
				RayTracingMaterial material;
			};

			struct Sphere {
				float3 position;
				float radius;
				RayTracingMaterial material;
			};
			struct Triangle {
				float3 posA, posB, posC;
				float3 normalA, normalB, normalC;
			};

			struct MeshInfo {
				uint firstTriangleIndex;
				uint numTriangles;
				float3 boundsMin;
				float3 boundsMax;
				RayTracingMaterial material;
			};
			static const float PI = 3.14159;

			StructuredBuffer<Triangle> Triangles;
			StructuredBuffer<MeshInfo> AllMeshInfo;
			int NumMeshes;

			StructuredBuffer<Sphere> Spheres;
			int NumSpheres;

			float MaxBounceCount;
			float NumRaysPerPixel;
			float NumRenderedFrame;

			float DivergeStrength, DefocusStrength;

			float N11(inout uint state) {
				state = state * 747796405 + 2891336453;
				uint result = ((state >> ((state >> 28) + 4)) ^ state) * 277803737;
				result = (result >> 22) ^ result;
				return result / 4294967295.0;
			}

			float3 RandomDirection(inout uint state) {
				for (int limit = 0; limit < 100; limit++) {
					float x = N11(state) * 2 - 1;
					float y = N11(state) * 2 - 1;
					float z = N11(state) * 2 - 1;
					float3 pointInCube = float3(x, y, z);
					float sqrDstFromCenter = dot(pointInCube, pointInCube);
					if (sqrDstFromCenter <= 1) {
						return pointInCube / sqrt(sqrDstFromCenter);
					}
				}
				return 0;
			}

			float3 RandomHemisphereDirection(float3 normal, inout uint state) {
				float3 dir = RandomDirection(state);
				return dir * sign(dot(normal, dir));
			}

			float2 RandomPointInCircle(inout uint state) {
				float angle = N11(state) * 2 * PI;
				float2 pointOnCircle = float2(cos(angle), sin(angle));
				return pointOnCircle * sqrt(N11(state));
			}
			float3 RandomPointOnSphere(inout uint state)
			{
				float phi = N11(state) * 2 * PI;
				float cosTheta = N11(state) * 2 - 1;
				float sinTheta = sqrt(1 - cosTheta * cosTheta);

				float3 pointOnSphere = float3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);
				return pointOnSphere;
			}
			float3 refract(float3 uv, float3 n, float etai_over_etat) {
				float cos_theta = min(dot(-uv, n), 1.0);
				float3 r_out_perp = etai_over_etat * (uv + cos_theta * n);
				float3 r_out_parallel = -sqrt(abs(1.0 - dot(r_out_perp, r_out_perp))) * n;
				return r_out_perp + r_out_parallel;
			}
			float reflectance(float cosine, float ref_idx) {
				// Use Schlick's approximation for reflectance.
				float r0 = (1 - ref_idx) / (1 + ref_idx);
				r0 = r0 * r0;
				return r0 + (1 - r0) * pow((1 - cosine), 5);
			}

			bool RayAABB(Ray ray, float3 boundsMin, float3 boundsMax) {
				float tmin = 0.0;
				float tmax = 1.0e38;

				for (int i = 0; i < 3; ++i)
				{
					float invD = 1.0 / ray.dir[i];
					float t0 = (boundsMin[i] - ray.origin[i]) * invD;
					float t1 = (boundsMax[i] - ray.origin[i]) * invD;

					if (invD < 0.0)
					{
						float temp = t0;
						t0 = t1;
						t1 = temp;
					}

					tmin = max(tmin, t0);
					tmax = min(tmax, t1);

					if (tmax <= tmin)
					{
						return false;
					}
				}
				return true;
			}
		

			HitInfo RaySphere(Ray ray, float3 center, float radius) {
				HitInfo hitInfo = (HitInfo)0;
				float3 offsetRayOrigin = ray.origin - center;

				float a = dot(ray.dir, ray.dir);
				float b = 2 * dot(offsetRayOrigin, ray.dir);
				float c = dot(offsetRayOrigin, offsetRayOrigin) - radius * radius;
				float delta = b * b - 4 * a * c;
				if (delta >= 0) {
					float dst = (-b - sqrt(delta)) / (2 * a);
					if (dst >= 0) {
						hitInfo.didHit = true;
						hitInfo.dst = dst;
						hitInfo.hitPoint = ray.origin + ray.dir * dst;
						hitInfo.normal = normalize(hitInfo.hitPoint - center);
					}
				}
				return hitInfo;
			}
			HitInfo RayTriangle(Ray ray, Triangle tri) {
				float3 edgeAB = tri.posB - tri.posA;
				float3 edgeAC = tri.posC - tri.posA;
				float3 normal = cross(edgeAB, edgeAC);
				float3 ao = ray.origin - tri.posA;
				float3 dao = cross(ao, ray.dir);

				float determinant = -dot(ray.dir, normal);
				float invDet = 1 / determinant;

				float dst = dot(ao, normal) * invDet;
				float u = dot(edgeAC, dao) * invDet;
				float v = -dot(edgeAB, dao) * invDet;
				float w = 1 - u - v;

				HitInfo hitInfo;
				hitInfo.didHit = determinant >= 1E-6 && dst >= 0 && u >= 0 && v >= 0 && w >= 0;
				hitInfo.hitPoint = ray.origin + ray.dir * dst;
				hitInfo.normal = normalize(tri.normalA * w + tri.normalB * u + tri.normalC * v);
				hitInfo.dst = dst;
				return hitInfo;
			}
			HitInfo CalculateRayCollision(Ray ray) {
				HitInfo closestHit = (HitInfo)0;
				closestHit.dst = 1.#INF;

				for (int i = 0; i < NumSpheres; i++) {
					Sphere sphere = Spheres[i];
					HitInfo hitInfo = RaySphere(ray, sphere.position, sphere.radius);
					if (hitInfo.didHit && hitInfo.dst < closestHit.dst) {
						closestHit = hitInfo;
						closestHit.material = sphere.material;
					}
				}

				for (int meshIndex = 0; meshIndex < NumMeshes; meshIndex++) {
					MeshInfo meshInfo = AllMeshInfo[meshIndex];

					if (!RayAABB(ray, meshInfo.boundsMin, meshInfo.boundsMax))
					{
						continue;
					}
					for (int i = 0; i < meshInfo.numTriangles; i++) {
						int triIndex = meshInfo.firstTriangleIndex + i;
						Triangle tri = Triangles[triIndex];
						HitInfo hitInfo = RayTriangle(ray,tri);
						if (hitInfo.didHit && hitInfo.dst < closestHit.dst) {
							closestHit = hitInfo;
							closestHit.material = meshInfo.material;
						}
					}
				}
				return closestHit;
			}

			float4 SkyColorHorizon, SkyColorZenith;
			float4 GroundColor;
			float4 SunLightDirection;
			float SunFocus, SunIntensity;

			float3 GetEnvironmentLight(Ray ray) {
				float skyGradientT = pow(smoothstep(0, 0.4, ray.dir.y), 0.35);
				float3 skyGradient = lerp(SkyColorHorizon, SkyColorZenith, skyGradientT);
				float sun = pow(max(0, dot(ray.dir, -normalize(SunLightDirection))), SunFocus) * SunIntensity;

				float groundToSkyT = smoothstep(-0.01, 0, ray.dir.y);
				float sunMask = groundToSkyT >= 1;
				return lerp(GroundColor, skyGradient, groundToSkyT) + sun * sunMask;
			}

			float3 Trace(Ray ray, inout uint state) {
				float3 incomingLight = 0;
				float3 rayColor = 1;
				for (int i = 0; i < MaxBounceCount; i++)
				{
					HitInfo hitInfo = CalculateRayCollision(ray);
					RayTracingMaterial material = hitInfo.material;
					if (hitInfo.didHit) {
						ray.origin = hitInfo.hitPoint - hitInfo.normal*0.01;
						float3 diffuseDir = normalize(hitInfo.normal + RandomDirection(state));
						float3 specularDir = reflect(ray.dir, hitInfo.normal);
						bool isSpecularBounce = material.specularProbability >= N11(state);

						float refractionIndex = material.refractionIndex;
						float cos_theta = min(dot(-ray.dir, hitInfo.normal), 1.0);
						float sin_theta = sqrt(1.0 - cos_theta * cos_theta);
						bool cannot_refract = refractionIndex * sin_theta > 1.0;
						if (!(cannot_refract || reflectance(cos_theta, refractionIndex) > N11(state)))
							specularDir = refract(ray.dir, hitInfo.normal, refractionIndex);

						if (material.isVolume) {
							float ray_length = length(ray.dir);
							float neg_inv_density = -1.0 / material.volumeDensity;
							float hit_distance = neg_inv_density * log(N11(state));
							ray.origin = hitInfo.hitPoint + hit_distance / ray_length;
							ray.dir = RandomPointOnSphere(state);
						}
						else {
							ray.dir = lerp(diffuseDir, specularDir, material.smoothness * isSpecularBounce);
						}



						float3 emittedLight = material.emissionColor * material.emissionStrength;
						incomingLight += emittedLight * rayColor;
						rayColor *= lerp(material.color, material.specularColor, isSpecularBounce);
					}
					else {
						incomingLight += GetEnvironmentLight(ray) * rayColor;
						break;
					}
				}
				return incomingLight;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				i.uv.y = 1 - i.uv.y;
				float3 viewPointLocal = float3(i.uv - 0.5, 1) * ViewParams;
				float3 viewPoint = mul(CamLocalToWorldMatrix, float4(viewPointLocal, 1));
				float3 camRight = CamLocalToWorldMatrix._m00_m10_m20;
				float3 camUp = CamLocalToWorldMatrix._m01_m11_m21;

				uint2 numPixels = _ScreenParams.xy;
				uint2 pixelCoord = i.uv * numPixels;
				uint pixelIndex = pixelCoord.y * numPixels.x + pixelCoord.x;
				uint rngState = pixelIndex + NumRenderedFrame * 194714;
				float3 totalIncomingLight = 0;
				for (int rayIndex = 0; rayIndex < NumRaysPerPixel; rayIndex++) {
					Ray ray;
					float2 defocusJitter = RandomPointInCircle(rngState) * DefocusStrength / numPixels.x;
					ray.origin = _WorldSpaceCameraPos + camRight * defocusJitter.x + camUp * defocusJitter.y;
					float2 jitter = RandomPointInCircle(rngState) * DivergeStrength / numPixels.x;
					float3 jitteredViewPoint = viewPoint + camRight * jitter.x + camUp * jitter.y;
					ray.dir = normalize(jitteredViewPoint - ray.origin);
					ray.time = NumRenderedFrame;

					totalIncomingLight += Trace(ray, rngState);
				}
				float3 pixelCol = totalIncomingLight / NumRaysPerPixel;
				return float4(pixelCol, 1);
			}
			ENDCG
	}
}
}
