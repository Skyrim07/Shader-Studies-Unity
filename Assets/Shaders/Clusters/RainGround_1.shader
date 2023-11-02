Shader "RainGround_1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RainTex ("Rain Texture", 2D) = "white" {}
        [HDR]_Color("Color", Color) = (1,1,1,1)
        [Header(Roughness)]
        _RoughnessTex ("_RoughnessTex", 2D) = "white"{}
        _Roughness ("_Roughness", Range(0,1)) = 0
        [Header(Metallic)]
        _MetallicTex("_MetallicTex", 2D) = "white"{}
        _Metallic("_Metallic", Range(0,1)) = 0
         [Header(Normal)]
        _NormalTex("_NormalTex", 2D) = "white"{}
        _Normal("_Normal", Range(0,1)) = 0

        _RainAlbedo("Rain Albedo", Color) = (1,1,1,1)
    }
    SubShader
    {
        LOD 100
        Cull Off
        CGINCLUDE
        #include "UnityCG.cginc"
                      #include "Lighting.cginc"
        // Normal distribution, D in FGD
        float NDF(float ndh, float roughness)
        {
            float a = roughness * roughness;
            float a2 = a * a;
            float ndh2 = ndh * ndh;

            //denominator
            float denom = ndh2 * (a2 - 1) + 1;
            denom = UNITY_PI * denom * denom;

            return a2 / denom;
        }

        //Geometric Occlusion, G in FGD
        float GF(float ndv, float ndl, float roughness)
        {
            float r = roughness + 1;
            float k = (r * r) / 8.0f;
            
            float ggx1 = ndv / lerp(ndv, 1, k);
            float ggx2 = ndl / lerp(ndl, 1, k);
            return ggx1 * ggx2;
        }

        //Fresnel, F in FGD
        float FF(float ndv, float F0)
        {
            return lerp(F0, 1, pow(1 - ndv, 5));
        }

        float3 PBR_Direct(float3 pos, float3 normal, float3 albedo, float roughness, float metallic, float ao, float shadow)
        {
            float3 viewDir = normalize(_WorldSpaceCameraPos - pos);
            float3 lightDir = UnityWorldSpaceLightDir(pos);
            float3 halfDir = normalize(normal + lightDir);
            half ndl = saturate(dot(normal, lightDir));
            half ndh = saturate(dot(normal, halfDir));
            half ndv = saturate(dot(normal, viewDir));

            float3 F0 = 0.04;
            F0 = lerp(F0, albedo, metallic);

            float F = FF(ndv, F0);
            float D = NDF(ndh, roughness);
            float G = GF(ndv, ndl, roughness);

            float3 kD = 1 - F;
            kD *= 1 - metallic;

            float3 specular = (F * G * D) / (4 * ndv * ndl + 0.00001);
            float3 diffuse = kD * albedo / UNITY_PI;

            float3 dirCol = (diffuse + specular) * ndl * shadow * _LightColor0;

            return dirCol;
        }

        float3 PBR(float3 pos, float3 normal, float3 albedo, float roughness, float metallic, float ao, float shadow, float rain, float3 rainAlbedo) 
        {
            float3 viewDir = normalize(_WorldSpaceCameraPos - pos);
            float3 lightDir = UnityWorldSpaceLightDir(pos);
            float3 halfDir = normalize(normal + lightDir);
            half ndl = saturate(dot(normal, lightDir));
            half ndh = saturate(dot(normal, halfDir));
            half ndv = saturate(dot(normal, viewDir));

            metallic *= rain;
            roughness *= rain;

            float3 F0 = 0.04;
            F0 = lerp(F0, albedo, metallic);

            float F = FF(ndv, F0);
            float D = NDF(ndh, roughness);
            float G = GF(ndv, ndl, roughness);

            float3 kD = 1 - F;
            kD *= 1 - metallic;

            float3 specular = (F * G * D) / (4 * ndv * ndl + 0.00001);
            specular *= rain;
            float3 diffuse = kD * albedo / UNITY_PI;

            float3 dirCol = (diffuse + specular)  * ndl * shadow * _LightColor0;
            
            //env lighting
            float3 irradiance = ShadeSH9(float4(normal, 1));
            float3 diffuseEnvCol = irradiance * albedo;
            float4 color_cubemap = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflect(-viewDir, normal), roughness * 6);
            float3 skyboxCol = DecodeHDR(color_cubemap, unity_SpecCube0_HDR);
            float3 specularEnvCol = skyboxCol * F;
            float3 envCol = kD * diffuseEnvCol + specularEnvCol;

            float3 finalCol = dirCol + envCol;
            float3 rainyCol = skyboxCol * pow(rain,0.2) * rainAlbedo;
            float3 diff = rainyCol - fixed3(.5, .5, .5);
            rainyCol += diff * .2;

            finalCol = lerp(finalCol, rainyCol, rain);
            return finalCol;
        }

        ENDCG


        Pass
        {
            Tags { "RenderType" = "Opaque" "LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma multi_compile_fwdbase_fullshadows
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float4 worldTangent : TEXCOORD3;
                LIGHTING_COORDS(4, 5)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _RainTex;

            fixed4 _Color;
            sampler2D _RoughnessTex, _MetallicTex, _NormalTex;
            float _Roughness, _Metallic, _Normal;
            fixed4 _RainAlbedo;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldTangent = float4(UnityObjectToWorldDir(v.tangent), v.tangent.w);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float rainCol = tex2D(_RainTex, i.uv).r;
                half3 worldNormal = normalize(i.worldNormal);
                half3 binormal = cross(i.worldNormal, i.worldTangent.xyz) * (i.worldTangent.w * unity_WorldTransformParams.w);
                half4 normal = tex2D(_NormalTex, i.uv);
                normal.xyz = UnpackNormalWithScale(normal, _Normal*pow((1-rainCol.r), 3));
                normal.xyz = normal.xzy;
                worldNormal = normalize(normal.x * i.worldTangent +
                    normal.y * i.worldNormal +
                    normal.z * binormal);

                float3 albedo = tex2D(_MainTex, i.uv) * _Color;
                float roughness = tex2D(_RoughnessTex, i.uv) * _Roughness;
                float metallic = tex2D(_MetallicTex, i.uv) * _Metallic;

                float shadowAtten = LIGHT_ATTENUATION(i);

                float3 pbr = PBR(i.worldPos, worldNormal, albedo, roughness, metallic, 1, shadowAtten, rainCol, _RainAlbedo.rgb);

                fixed4 col = fixed4(pbr, 1);
                return col;
            }
            ENDCG
        }

            Pass
            {
                Tags { "RenderType" = "Opaque" "LightMode" = "ForwardAdd"}
                Blend One One

                CGPROGRAM
                #pragma multi_compile_fwdadd_fullshadows
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"
                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0;
                    float4 pos : SV_POSITION;
                    float4 worldPos : TEXCOORD1;
                    float3 worldNormal : TEXCOORD2;
                    float4 worldTangent : TEXCOORD3;
                    LIGHTING_COORDS(4, 5)
                };

                sampler2D _MainTex;
                float4 _MainTex_ST;

                fixed4 _Color;
                sampler2D _RoughnessTex, _MetallicTex, _NormalTex;
                float _Roughness, _Metallic, _Normal;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.worldTangent = float4(UnityObjectToWorldDir(v.tangent), v.tangent.w);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    half3 worldNormal = normalize(i.worldNormal);
                    half3 binormal = cross(i.worldNormal, i.worldTangent.xyz) * (i.worldTangent.w * unity_WorldTransformParams.w);
                    half4 normal = tex2D(_NormalTex, i.uv);
                    normal.xyz = UnpackNormalWithScale(normal, _Normal);
                    normal.xyz = normal.xzy;
                    worldNormal = normalize(normal.x * i.worldTangent +
                        normal.y * i.worldNormal +
                        normal.z * binormal);

                    float3 albedo = tex2D(_MainTex, i.uv) * _Color;
                    float roughness = tex2D(_RoughnessTex, i.uv) * _Roughness;
                    float metallic = tex2D(_MetallicTex, i.uv) * _Metallic;

                    float shadowAtten = LIGHT_ATTENUATION(i);

                    float3 pbr = PBR_Direct(i.worldPos, worldNormal, albedo, roughness, metallic, 1, shadowAtten);

                    fixed4 col = fixed4(pbr, 1);
                    return col;
                }
                ENDCG
            }

                UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
