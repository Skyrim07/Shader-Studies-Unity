// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
Shader "MyStandardShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _DiffuseColor ("Diffuse Color", Color) = (1,1,1,1)
        _TextureColor ("Texture Color", Color) = (1,1,1,1)
        _Bump ("Bump", range(-5,5)) =0.5
        _Lambert ("Lambert", range(0,1)) =0.5
        _Alpha ("Alpha", range(0,1)) =0.5
        _Gloss ("Gloss", range(0,100)) =5
    }
    SubShader
    {
	   	Tags { "RenderType"="Transparent" "Queue"="AlphaTest" "IgnoreProjector"="True"}
        Pass
        {
			Tags{ "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
			#pragma multi_compile_fwdbase	
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
				float4 tangent:TANGENT;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
				fixed3 tangentLightDir :TEXCOORD1;
				fixed3 tangentViewDir:TEXCOORD2;
				float4 worldPos:TEXCOORD3;
			    SHADOW_COORDS(4)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _NormalMap;
			float4 _NormalMap_ST;

			fixed4 _DiffuseColor;
			fixed4 _TextureColor;

			float _Bump;
			float _Alpha;

			float _Lambert;
			float _Gloss;

            v2f vert (a2v v)
            {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);
                f.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                f.uv.zw = TRANSFORM_TEX(v.uv, _NormalMap);
				f.worldPos=mul(unity_ObjectToWorld, v.vertex);

				TANGENT_SPACE_ROTATION;

				fixed3 tangentLightDir=normalize(mul(rotation, mul(unity_WorldToObject,  _WorldSpaceLightPos0)));
				f.tangentLightDir=tangentLightDir;
				fixed3 tangentViewDir=normalize(mul(rotation, mul(unity_WorldToObject,  UnityWorldSpaceViewDir(f.worldPos))));
				f.tangentViewDir=tangentViewDir;

				TRANSFER_SHADOW(f);
                return f;
            }

            fixed4 frag (v2f f) : SV_TARGET
            {
			    fixed4 normalColor = tex2D(_NormalMap,f.uv.zw);
			    float3 tangentNormal = UnpackNormal(normalColor);
				tangentNormal.xy*=_Bump;
				tangentNormal.z=sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));
                fixed4 texColor = _TextureColor * tex2D(_MainTex, f.uv.xy);
				fixed4 diffuseColor=_LightColor0*_DiffuseColor *max(0, (dot(tangentNormal,f.tangentLightDir)*_Lambert+(1-_Lambert)));
			    fixed4 specularColor=_LightColor0* pow(max(dot(normalize(f.tangentViewDir+f.tangentLightDir),tangentNormal),0),_Gloss);

				UNITY_LIGHT_ATTENUATION(atten, f, f.worldPos.xyz);

				fixed4 resColor= (texColor*diffuseColor+specularColor)*atten;
                return fixed4(resColor.xyz, _Alpha);
            }
            ENDCG
        }
		Pass
        {
			Tags{ "LightMode" = "ForwardAdd" }
			Blend SrcAlpha One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#pragma multi_compile_fwdadd_fullshadows

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
			#include "AutoLight.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
				float4 tangent:TANGENT;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
				fixed3 tangentLightDir : TEXCOORD1;
				fixed3 tangentViewDir : TEXCOORD2;
				float4 worldPos : TEXCOORD3;
			    SHADOW_COORDS(4)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _NormalMap;
			float4 _NormalMap_ST;

			fixed4 _DiffuseColor;
			fixed4 _TextureColor;

			float _Bump;
			float _Alpha;

			float _Lambert;
			float _Gloss;

            v2f vert (a2v v)
            {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);
                f.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                f.uv.zw = TRANSFORM_TEX(v.uv, _NormalMap);
				f.worldPos=mul(unity_ObjectToWorld, v.vertex);

				TANGENT_SPACE_ROTATION;

				fixed3 tangentLightDir=normalize(mul(rotation, mul(unity_WorldToObject,  _WorldSpaceLightPos0-f.worldPos)));
				f.tangentLightDir=tangentLightDir;
				fixed3 tangentViewDir=normalize(mul(rotation, mul(unity_WorldToObject,  UnityWorldSpaceViewDir(f.worldPos))));
				f.tangentViewDir=tangentViewDir;

			    TRANSFER_SHADOW(f);

                return f;
            }

            fixed4 frag (v2f f) : SV_TARGET
            {
			  fixed4 normalColor = tex2D(_NormalMap,f.uv.zw);
			    float3 tangentNormal = UnpackNormal(normalColor);
				tangentNormal.xy*=_Bump;
				tangentNormal.z=sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                fixed4 texColor = _TextureColor * tex2D(_MainTex, f.uv.xy);
				fixed4 diffuseColor=_LightColor0*_DiffuseColor *max(0, (dot(tangentNormal,f.tangentLightDir)*_Lambert+(1-_Lambert)));
			    fixed4 specularColor=_LightColor0* pow(max(dot(normalize(f.tangentViewDir+f.tangentLightDir),tangentNormal),0),_Gloss);

				UNITY_LIGHT_ATTENUATION(atten, f, f.worldPos.xyz);

				fixed4 resColor= (texColor*diffuseColor+specularColor)*atten;
                return fixed4(resColor.xyz, _Alpha);
            }
            ENDCG
        }
    }

    Fallback "VertexLit"
}
