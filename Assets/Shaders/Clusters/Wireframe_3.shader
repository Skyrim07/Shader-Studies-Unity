Shader "Wireframe_3"
{
	Properties
	{
		[PowerSlider(3.0)]
		_VertexSize("Vertex Size", Range(0., 0.5)) = 0.05
		_VertexTex("Vertex Texture", 2D) = "white"{}
		_Color("Color", color) = (1., 1., 1., 1.)
		 _VerticalBillboarding("Vertical Restraints", Range(0, 1)) = 1
	}
		SubShader
		{
			Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
			Blend SrcAlpha OneMinusSrcAlpha
			Pass
			{
				Cull Front
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma geometry geom

			#pragma shader_feature __ _REMOVEDIAG_ON

			#include "UnityCG.cginc"

			struct v2g {
				float4 worldPos : SV_POSITION;
				float4 rightDir : TEXCOORD0;
				float4 upDir : TEXCOORD1;
			};

			struct g2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;

			};

			float _VerticalBillboarding;
			v2g vert(appdata_base v) {
				v2g o;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				float3 center = float3(0, 0, 0);
				float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));

				float3 normalDir = viewer - center;
				normalDir.y = normalDir.y * _VerticalBillboarding;
				normalDir = normalize(normalDir);
				float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
				float3 rightDir = normalize(cross(upDir, normalDir));
				upDir = normalize(cross(normalDir, rightDir));
				float3 centerOffs = v.vertex.xyz - center;
				float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;

				o.rightDir = mul(unity_ObjectToWorld, float4(rightDir, 0));
				o.upDir = mul(unity_ObjectToWorld, float4(upDir, 0));
				o.worldPos = mul(unity_ObjectToWorld, float4(localPos, 1));

				return o;
			}

			g2f createGSOut() {
				g2f output;
				output.pos = float4(0, 0, 0, 0);
				output.uv = float2(0, 0);
				return output;
			}
			float _VertexSize;
			[maxvertexcount(18)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {

				const int vertexCount = 6;
				float radius = _VertexSize;
				g2f v[vertexCount] = {
					createGSOut(), createGSOut(), createGSOut(), createGSOut(),
					createGSOut(), createGSOut()
				};

				
				for (int i = 0; i < 3; i++) {
					v2g ref = IN[i];
					float4 u = normalize(ref.upDir);
					float4 r = normalize(ref.rightDir);

					v[0].pos = mul(UNITY_MATRIX_VP, ref.worldPos + (-radius * r) + (radius * u));
					v[0].uv = float2(0, 1);
					triStream.Append(v[0]);
					v[1].pos = mul(UNITY_MATRIX_VP, ref.worldPos + (radius * r) + (radius * u));
					v[1].uv = float2(1, 1);
					triStream.Append(v[1]);
					v[2].pos = mul(UNITY_MATRIX_VP, ref.worldPos + (-radius * r) + (-radius * u));
					v[2].uv = float2(0, 0);
					triStream.Append(v[2]);
					v[3].pos = mul(UNITY_MATRIX_VP, ref.worldPos + (radius * r) + (radius * u));
					v[3].uv = float2(1, 1);
					triStream.Append(v[3]);
					v[5].pos = mul(UNITY_MATRIX_VP, ref.worldPos + (-radius * r) + (-radius * u));
					v[5].uv = float2(0, 0);
					triStream.Append(v[5]);
					v[4].pos = mul(UNITY_MATRIX_VP, ref.worldPos + (radius * r) + (-radius * u));
					v[4].uv = float2(1, 0);
					triStream.Append(v[4]);
					triStream.RestartStrip();
				}
			}

			float _WireframeVal;
			fixed4 _Color;
			sampler2D _VertexTex;

			fixed4 frag(g2f i) : SV_Target
			{
				float4 col = tex2D(_VertexTex, i.uv);
				col *= _Color;
				return col;
			}
			ENDCG
			}

		}
}