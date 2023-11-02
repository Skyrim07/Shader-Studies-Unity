Shader "Unlit/TreeWind"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _WindStrength("Wind Strength", vector) = (0.05, 0.05, 0, 0)
        _WindFrequency("Wind Frequency", float) = 1
        _YPower("Y Power", float) = 1
    }
    SubShader
    {
        LOD 100

        Pass
        {
            Tags { "RenderType" = "Opaque" "LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float worldLight : TEXCOORD2;
                float4 objectPos : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _WindFrequency;
            float _YPower;
            float4 _WindStrength;

            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.objectPos = v.vertex;

                v.vertex += sin(_Time.y * _WindFrequency) * _WindStrength * pow(v.vertex.y, _YPower);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = normalize(mul(unity_ObjectToWorld, v.normal));
                o.worldLight = normalize(_WorldSpaceLightPos0);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                float ndl = dot(i.worldNormal, i.worldLight);
                ndl = ndl * 0.5 + 0.5;
                col *= ndl;
                return col;
            }
            ENDCG
        }
        Pass
        {
            Tags {"LightMode" = "ForwardAdd"}
            Blend OneMinusDstColor One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _WindFrequency;
            float _YPower;
            float4 _WindStrength;

            fixed4 _Color;

            float FadeShadows(v2f i, float attenuation) {
                float viewZ =
                    dot(_WorldSpaceCameraPos - i.worldPos, UNITY_MATRIX_V[2].xyz);
                float shadowFadeDistance =
                    UnityComputeShadowFadeDistance(i.worldPos, viewZ);
                float shadowFade = UnityComputeShadowFade(shadowFadeDistance);
                attenuation = saturate(attenuation + shadowFade);
                return attenuation;
            }

            v2f vert(appdata v)
            {
                v2f o;
                v.vertex += sin(_Time.y * _WindFrequency) * _WindStrength * pow(v.vertex.y, _YPower);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = normalize(mul(unity_ObjectToWorld, v.normal));
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos.xyz);
                atten = FadeShadows(i, atten);
                float3 pointlights = atten * _LightColor0.rgb;
                return float4(pointlights, 1);
            }
            ENDCG
        }
    }
}
