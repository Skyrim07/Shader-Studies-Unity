Shader "SnowField" {
        Properties {
            _Tess ("Tessellation", Range(1,32)) = 4
            _SnowTex ("Snow Texture", 2D) = "white" {}
            _SnowColor ("Snow Color", color) = (1,1,1,0)
            _GroundTex ("Ground Texture", 2D) = "white" {}
            _GroundColor ("Ground Color", color) = (1,1,1,0)
            _DispTex ("Disp Texture", 2D) = "gray" {}
            _NormalMap ("Normalmap", 2D) = "bump" {}
            _Displacement ("Displacement", Range(0, 1.0)) = 0.3
            _SpecColor ("Spec color", color) = (0.5,0.5,0.5,0.5)
        }
        SubShader {
            Tags { "RenderType"="Opaque" }
            LOD 300
            
            CGPROGRAM
            #pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:disp tessellate:tessDistance nolightmap
            #pragma target 4.6
            #include "Tessellation.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            float _Tess;

            float4 tessDistance (appdata v0, appdata v1, appdata v2) {
                float minDist = 10.0;
                float maxDist = 25.0;
                return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
            }

            sampler2D _DispTex;
            float _Displacement;

            void disp (inout appdata v)
            {
                float d = tex2Dlod(_DispTex, float4(v.texcoord.xy,0,0)).r * _Displacement;
                v.vertex.xyz -= v.normal * d;
                v.vertex.xyz += v.normal * _Displacement;
            }

            struct Input {
                float2 uv_SnowTex;
                float2 uv_GroundTex;
                float2 uv_DispTex;
            };

            sampler2D _SnowTex;
            sampler2D _GroundTex;
            sampler2D _NormalMap;
            fixed4 _SnowColor;
            fixed4 _GroundColor;

            void surf (Input IN, inout SurfaceOutput o) {
                fixed4 snowCol = tex2D(_SnowTex, IN.uv_SnowTex)*_SnowColor;
                fixed4 groundCol = tex2D(_GroundTex, IN.uv_GroundTex)*_GroundColor;
                half amount = tex2Dlod(_DispTex, float4(IN.uv_DispTex, 0,0)).r;
                fixed4 c = lerp(snowCol, groundCol, amount);
                o.Albedo = c.rgb;
                o.Specular = 0.2;
                o.Gloss = 1.0;
            }
            ENDCG
        }
        FallBack "Diffuse"
    }