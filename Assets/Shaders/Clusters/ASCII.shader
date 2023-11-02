Shader "AlexLiu/ASCII" {
	Properties{
		_MainTex("Main Tex", 2D) = "white" {}
		_CharTex("Character Map", 2D) = "white" {}
		_GridX("Grid X", int) = 96
		_GridY("Grid Y", int) = 54
		_Brightness("_Brightness", float) = 0.0
		_Colorness("_Colorness", float) = 0.0
	}

		SubShader{
			Cull Off
			Pass{
				CGPROGRAM
				#pragma fragment frag
				#pragma vertex vert_img
				#include "UnityCG.cginc"

				struct v2f {
					float4 pos : SV_POSITION;
					float2 uv  : TEXCOORD0;
				};

				sampler2D _MainTex;
				sampler2D _CharTex;
				float _GridX, _GridY;
				float _CharW, _CharH;
				float _Brightness, _Colorness;

				float4 sampleChar(int index, float2 guv) 
				{
					guv.x = guv.x / 8.0 + index / 8.0;
					return tex2D(_CharTex, guv);
				}

				float4 frag(v2f i) : COLOR{
					float2 uv = float2(floor(_GridX * i.uv.x) / _GridX, floor(_GridY * i.uv.y) / _GridY);
					float4 col = tex2D(_MainTex,uv);
					
					float2 guv = float2(frac(_GridX * i.uv.x), frac(_GridY * i.uv.y));
					float l = Luminance(col);
					float cdist = length(col);
					float4 acol = sampleChar(floor(l*8), guv);
					acol = lerp(acol, acol * col*0.8, step(_Colorness, cdist));
					col = acol;
					col *= _Brightness;
					col = lerp(col, float4(0, 0, 0, 0), step(guv.x, 0.05));
					col = lerp(col, float4(0, 0, 0, 0), step(0.95,guv.x));
					col = lerp(col, float4(0, 0, 0, 0), step(guv.y, 0.05));
					col = lerp(col, float4(0, 0, 0, 0), step(0.95,guv.y));
					return col;
				}
				ENDCG
			}
		}
			FallBack off
}