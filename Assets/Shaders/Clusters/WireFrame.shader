Shader "AlexLiu/WireFrame"
{
    Properties
    {
        _WireColor ("Wire Color", Color) = (0,0,0,1)
        _FillColor ("Fill Color", Color) = (1,1,1,1)
        _WireWidth ("Wire Width", Range(0.1,2)) = 0.2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom

            #include "UnityCG.cginc"

         struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct v2g
            {
                float2 uv: TEXCOORD0;
                float4 vertex: SV_POSITION;
            };

            struct g2f
            {
                float2 uv: TEXCOORD0;
                float4 vertex: SV_POSITION;
                float3 dist: NORMAL1;
            };

            v2g vert(appdata v)
            {
                v2g o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            [maxvertexcount(3)]
             void geom(triangle v2g IN[3], inout TriangleStream < g2f > triStream)
            {
                float2 p0 = IN[0].vertex.xy / IN[0].vertex.w;
                float2 p1 = IN[1].vertex.xy / IN[1].vertex.w;
                float2 p2 = IN[2].vertex.xy / IN[2].vertex.w;

                float2 v0 = p2 - p1;
                float2 v1 = p2 - p0;
                float2 v2 = p1 - p0;
                //triangles area
                float area = abs(v1.x * v2.y - v1.y * v2.x);

                // //到三条边的最短距离
                g2f OUT;
                OUT.vertex = IN[0].vertex;
                OUT.uv = IN[0].uv;
                OUT.dist = float3(area / length(v0), 0, 0);
                triStream.Append(OUT);

                OUT.vertex = IN[1].vertex;
                OUT.uv = IN[1].uv;
                OUT.dist = float3(0, area / length(v1), 0);
                triStream.Append(OUT);

                OUT.vertex = IN[2].vertex;
                OUT.uv = IN[2].uv;
                OUT.dist = float3(0, 0, area / length(v2));
                triStream.Append(OUT);
            }

            fixed4 _WireColor;
            fixed4 _FillColor;
            float _WireWidth;        

            fixed4 frag(g2f i): SV_Target
            {
                fixed4 col_Wire;
                float d = min(i.dist.x, min(i.dist.y, i.dist.z));
                col_Wire.rgb = d < _WireWidth * 0.003 / i.vertex.w ?_WireColor: _FillColor;
                col_Wire.a = 1;
                return col_Wire;
            }
            ENDCG
        }
    }
}
