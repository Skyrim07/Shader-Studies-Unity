Shader "examples/week 11/exterior"
{
    Properties {
        _surfaceColor ("surface color", Color) = (0.4, 0.1, 0.9)
        _gloss ("gloss", Range(0,1)) = 1
        _diffuseLightSteps ("diffuse light steps", Int) = 4
        _specularLightSteps ("specular light steps", Int) = 2
        _ambientColor ("ambient color", Color) = (0.7, 0.05, 0.15)
    }

    SubShader
    {
        Tags { "Queue"="Geometry" }

        Stencil {
            Ref 0
            Comp Equal
        }

        // nothing new below
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            // might be UnityLightingCommon.cginc for later versions of unity
            #include "Lighting.cginc"

            #define MAX_SPECULAR_POWER 256
            
            float3 _surfaceColor;
            float _gloss;
            int _diffuseLightSteps;
            int _specularLightSteps;
            float3 _ambientColor;

            struct MeshData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 posWorld : TEXCOORD2;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;

                o.normal = UnityObjectToWorldNormal(v.normal);
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                
                o.uv = v.uv;
                return o;
            }

            float4 frag (Interpolators i) : SV_Target
            {
                float2 uv = i.uv;

                float3 normal = normalize(i.normal);
                
                float3 lightDirection = _WorldSpaceLightPos0;
                float3 lightColor = _LightColor0; // includes intensity

                // blinn-phong
                // calculates "half direction" and compares it to normal 
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld);
                float3 halfDirection = normalize(viewDirection + lightDirection);

                float diffuseFalloff = max(0, dot(normal, lightDirection));
                float specularFalloff = max(0, dot(normal, halfDirection));

                float3 specular = pow(specularFalloff, _gloss * MAX_SPECULAR_POWER + 0.0001) * lightColor * _gloss;


                // posterization
                diffuseFalloff = floor(diffuseFalloff * _diffuseLightSteps) / _diffuseLightSteps;
                specular = floor(specular * _specularLightSteps) / _specularLightSteps;


                float3 posterizedBlinnPhong = diffuseFalloff * _surfaceColor * lightColor + specular + _ambientColor;

                return float4(posterizedBlinnPhong, 1.0);
            }
            ENDCG
        }
    }
}
