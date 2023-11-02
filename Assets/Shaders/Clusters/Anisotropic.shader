Shader "AlexLiu/Anisotropic"
{
	Properties
	{
		_Diffuse("Diffuse", Color) = (1, 1, 1, 1)
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
		_Tangent ("Tangent", Range(0, 2)) = 0
	}
	SubShader
	{
		Pass
		{
			Tags {"LightMode" = "ForwardBase"}
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"

			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			float _Tangent;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};
			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 worldBinormal : TEXCOORD2;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldNormal = worldNormal;
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				o.worldBinormal = cross(worldTangent, worldNormal);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 AnisotropicworldNormal = normalize(lerp(i.worldNormal + i.worldBinormal, i.worldBinormal, _Tangent));
				fixed3 lightDir =  normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 viewDir =  normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 reflectDir = normalize(lightDir + viewDir);

				float Anisotropic = dot(AnisotropicworldNormal, reflectDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, sqrt(1 - (Anisotropic * Anisotropic))), _Gloss);

				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(i.worldNormal, lightDir));

				specular *= saturate(diffuse * 5);
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			ENDCG
		}
	}
	FallBack "Specular"
}