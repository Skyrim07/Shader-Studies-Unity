Shader "RainGround"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        [HDR]_DiffuseColor("Diffuse Color", Color) = (1,1,1,1)
        _TextureColor ("Texture Color", Color) = (1,1,1,1)
        _Bump ("Bump", range(-5,5)) =0.5
        _Lambert ("Lambert", range(0,1)) =0.5
        _Alpha ("Alpha", range(0,1)) =0.5
        _Gloss ("Gloss", range(0,100)) =5
        _SpecularPower ("SpecularPower", range(0,50)) =5

        _Noise1("Noise1", 2D) = "white" {}
        _WetLevel("WetLevel", float) = 0.5
        _AccumulateWater("AccumulateWater", float) = 0.02
        _BrickF0("BrickF0", float) = 0.05
        _ReflectFactor("ReflectFactor", float) = 1
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
                float3 worldNormal : TEXCOORD4;
                float3 worldView : TEXCOORD5;
                float3 worldLight : TEXCOORD6;
                float3 worldHalf : TEXCOORD7;
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
			float _SpecularPower;

            sampler2D _Noise1;

            float _WetLevel;
            float _AccumulateWater, _BrickF0;
            float _ReflectFactor;

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
                f.worldView = normalize(UnityWorldSpaceViewDir(f.worldPos));
                f.worldNormal = normalize(mul(unity_ObjectToWorld, v.normal));
                f.worldLight = normalize(UnityWorldSpaceLightDir(f.worldPos));
                f.worldHalf = normalize(f.worldNormal + f.worldLight);
				TRANSFER_SHADOW(f);
                return f;
            }

            fixed4 frag (v2f f) : SV_TARGET
            {
			    fixed4 normalColor = tex2D(_NormalMap,f.uv.zw);
			    float3 tangentNormal = UnpackNormal(normalColor);
				tangentNormal.xy*=_Bump;
				tangentNormal.z=sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                float ndv = max(0, dot(f.worldView, f.worldNormal));
                float ndl = max(0, dot(f.worldLight, f.worldNormal));
                float ndh = max(0, dot(f.worldHalf, f.worldNormal));

                fixed4 texColor = _TextureColor * tex2D(_MainTex, f.uv.xy);
                fixed noiseColor1 = tex2D(_Noise1, f.uv.xy);
                noiseColor1 = smoothstep(0.2, 0.4, noiseColor1);

                _WetLevel *= noiseColor1;
                _Gloss = min(_Gloss * lerp(1.0, 2.5, _WetLevel), 1.0);
                _DiffuseColor *= lerp(1.0, 0.4, _WetLevel);
                _Gloss = lerp(_Gloss, 1.0, _AccumulateWater);
                _SpecularPower = lerp(_SpecularPower, 0.02, _AccumulateWater);
               // f.worldNormal = lerp(f.worldNormal, float3(0, 0, 1), _AccumulateWater);

                float f0 = lerp(_BrickF0, 0.02, _AccumulateWater);
                float fresnel = f0 + (1 - f0) * pow((1 - ndv), 5);
                float specular = fresnel * ((_SpecularPower + 2.0) / 8.0) * pow(ndh, _Gloss) * ndl;
                
                float3 irradiance = ShadeSH9(float4(f.worldNormal, 1));
                float3 diffuseEnvCol = irradiance;
                float4 color_cubemap = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflect(-f.worldView, f.worldNormal));
                float3 specularEnvCol = DecodeHDR(color_cubemap, unity_SpecCube0_HDR) ;
                float3 ambient = saturate(_ReflectFactor + fresnel) * specularEnvCol;

				fixed4 diffuseColor=_LightColor0*_DiffuseColor *max(0, (dot(tangentNormal,f.tangentLightDir)*_Lambert+(1-_Lambert)));
                fixed4 specularColor = _LightColor0 * specular;

				UNITY_LIGHT_ATTENUATION(atten, f, f.worldPos.xyz);

				fixed4 resColor= (texColor*diffuseColor+specularColor)*atten+ fixed4(ambient,0);
                fixed4 waterColor = fixed4(specularEnvCol, 1);

                resColor = lerp(resColor, waterColor, saturate(_WetLevel));

                return fixed4(resColor.rgb, _Alpha);
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
