Shader "Unlit/IBL_1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CubeTex("Cube Texture", CUBE) = "black"{}
        _FresnelPower("fresnel power", Range(0, 10)) = 5
        _Gloss("gloss", Range(0,1)) = 1
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _FresnelColor("Fresnel Color", Color) = (1,1,1,1)
        _Refract("Refraction", float) =1.5
        _IndirDiffuse("Indirect Diffuse",  Range(0,1)) =0.3
        _Contrast("_Contrast", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 100
            Blend SrcAlpha OneMinusSrcAlpha
        GrabPass{"_GrabTex"}
        Pass
        {
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 tangent : TEXCOORD2;
                float3 bitangent : TEXCOORD3;
                float3 posWorld : TEXCOORD4;
                float4 grabPos : TEXCOORD5;
                float4 scrPos : TEXCOORD6;
                float3 viewNormal : TEXCOORD7;
            };

            sampler2D _GrabTex;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            samplerCUBE _CubeTex;

            float _FresnelPower, _Gloss, _Refract, _IndirDiffuse;
            float _Contrast;
            fixed4 _SpecularColor, _FresnelColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = UnityObjectToWorldNormal(v.tangent);
                o.bitangent = cross(o.normal, o.tangent) * v.tangent.w;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.viewNormal = COMPUTE_VIEW_NORMAL;
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                o.scrPos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.scrPos.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld);
                float3 lightDirection = _WorldSpaceLightPos0;
                float3 viewReflection = reflect(-viewDirection, i.normal);
                float3 halfDirection = normalize(viewDirection + lightDirection);
                float fresnel = 1 - saturate(dot(viewDirection, i.normal));
                fresnel = pow(fresnel, _FresnelPower);

                //fixed4 col = tex2Dproj(_GrabTex, i.grabPos);
                fixed4 col = tex2Dproj(_GrabTex, i.grabPos + float4(i.viewNormal.xy * _Refract,0,0));
                fixed4 cubeCol = texCUBE(_CubeTex, viewReflection);
                col = lerp(col, cubeCol, fresnel);

                float specularFalloff = max(0, dot(i.normal, halfDirection));
                specularFalloff = pow(specularFalloff, _Gloss* 256 + 0.0001)* _Gloss;
                float specularFalloff2 = pow(specularFalloff, _Gloss* 128 + 0.0001)* _Gloss;
                float4 directSpecular = specularFalloff * _SpecularColor;
                float4 directSpecular2 = specularFalloff2 * _SpecularColor;
                directSpecular += directSpecular2;
                float3 indirectDiffuse = texCUBElod(_CubeTex, float4(i.normal, 9));
                col.rgb = lerp(col.rgb,col.rgb*indirectDiffuse, _IndirDiffuse);
                col += directSpecular;
                col += _FresnelColor * fresnel;
                col.a = 1;
                return col;
            }
            ENDCG
        }
         Pass
        {
            Cull Back
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 tangent : TEXCOORD2;
                float3 bitangent : TEXCOORD3;
                float3 posWorld : TEXCOORD4;
                float4 grabPos : TEXCOORD5;
                float4 scrPos : TEXCOORD6;
                float3 viewNormal : TEXCOORD7;
            };

            sampler2D _GrabTex;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Contrast;
            samplerCUBE _CubeTex;

            float _FresnelPower, _Gloss, _Refract, _IndirDiffuse;

            fixed4 _SpecularColor, _FresnelColor;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = UnityObjectToWorldNormal(v.tangent);
                o.bitangent = cross(o.normal, o.tangent) * v.tangent.w;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.viewNormal = COMPUTE_VIEW_NORMAL;
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                o.scrPos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.scrPos.z);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld);
                float3 lightDirection = _WorldSpaceLightPos0;
                float3 viewReflection = reflect(-viewDirection, i.normal);
                float3 halfDirection = normalize(viewDirection + lightDirection);
                float fresnel = 1 - saturate(dot(viewDirection, i.normal));
                fresnel = pow(fresnel, _FresnelPower);

                //fixed4 col = tex2Dproj(_GrabTex, i.grabPos);
                fixed4 col = tex2Dproj(_GrabTex, i.grabPos + float4(i.viewNormal.xy * _Refract,0,0));
                fixed4 cubeCol = texCUBE(_CubeTex, viewReflection);
                col = lerp(col, cubeCol, fresnel);

                float specularFalloff = max(0, dot(i.normal, halfDirection));
                specularFalloff = pow(specularFalloff, _Gloss * 256 + 0.0001) * _Gloss;
                float specularFalloff2 = pow(specularFalloff, _Gloss * 128 + 0.0001) * _Gloss;
                float4 directSpecular = specularFalloff * _SpecularColor;
                float4 directSpecular2 = specularFalloff2 * _SpecularColor;
                directSpecular += directSpecular2;
                float3 indirectDiffuse = texCUBElod(_CubeTex, float4(i.normal, 9));
                col.rgb = lerp(col.rgb,col.rgb * indirectDiffuse, _IndirDiffuse);
                col += directSpecular;
                col += _FresnelColor * fresnel;
                float4 cdiff = col - float4(.5, .5, .5, .5);
                col += cdiff * (_Contrast * 2 - 1);
                col.a = 0.7;
                return col;
            }
            ENDCG
        }
    }
}
