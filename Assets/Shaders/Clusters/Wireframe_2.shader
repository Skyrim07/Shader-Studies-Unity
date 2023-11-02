Shader "Wireframe_2"
{
    Properties
    {
        [PowerSlider(3.0)]
        _WireframeVal("Wireframe width", Range(0., 0.5)) = 0.05
        [PowerSlider(3.0)]
        _PointVal("Point width", Range(0., 5)) = 0.05
        _Color("Color", color) = (1., 1., 1., 1.)
       [HDR] _Color2("Color2", color) = (1., 1., 1., 1.)
        _LineColor("Line Color", color) = (1., 1., 1., 1.)
        _Power ("Power", float) = 2
        _Threshold ("Threshold", float) = 0.2

    }
        SubShader
        {
            Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }

            Pass
            {
                Cull Off
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma geometry geom

            #include "UnityCG.cginc"

            struct v2g {
                float4 worldPos : SV_POSITION;
            };

            struct g2f {
                float4 pos : SV_POSITION;
                float3 bary : TEXCOORD0;
            };

            v2g vert(appdata_base v) {
                v2g o;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            [maxvertexcount(3)]
            void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {
                float3 param = float3(0., 0., 0.);
                g2f o;
                o.pos = mul(UNITY_MATRIX_VP, IN[0].worldPos);
                o.bary = float3(1., 0., 0.) + param;
                triStream.Append(o);
                o.pos = mul(UNITY_MATRIX_VP, IN[1].worldPos);
                o.bary = float3(0., 0., 1.) + param;
                triStream.Append(o);
                o.pos = mul(UNITY_MATRIX_VP, IN[2].worldPos);
                o.bary = float3(0., 1., 0.) + param;
                triStream.Append(o);
            }

            float _WireframeVal, _PointVal;
            fixed4 _Color, _Color2, _LineColor;
            float _Power;
            float _Threshold;

            float mylength(float3 p) {
                return length(p);
            }

            float mydistance(float3 p, float3 q) {
                return pow(abs(p.x - q.x) + abs(p.y - q.y) + abs(p.z - q.z),1);
            }
            fixed4 frag(g2f i) : SV_Target{
                fixed4 col = _Color;

                float minDist = min(mydistance(i.bary, float3(1, 0, 0)), min(mydistance(i.bary, float3(0, 1, 0)), mydistance(i.bary, float3(0, 0, 1))));
                _WireframeVal *= 1-minDist*0.6;
                minDist = pow(minDist, _Power);

                if (any(bool3(i.bary.x <= _WireframeVal, i.bary.y <= _WireframeVal, i.bary.z <= _WireframeVal)))
                    col += _LineColor;

                if (minDist <= _PointVal)
                    col = lerp(col, _Color2, saturate(1-minDist));
                return col;
            }
            ENDCG
        }
    }
}