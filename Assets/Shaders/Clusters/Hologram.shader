Shader "AlexLiu/Hologram"
{
    Properties
    {
        _ScannerTex ("Scanner Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _RimColor ("Rim Color", Color) = (1,1,1,1)
        _ScannerColor ("Scanner Color", Color) = (1,1,1,1)
        _RimStrength ("Rim Strength", float) = 1
        _ScannerSpeed ("Scanner Speed", float) = 1
        _ScannerStrength ("Scanner Strength", float) = 1
        _NoiseStrength ("Noise Strength", float) = 1
        _WireColor ("Wire Color", Color) = (0,0,0,1)
        _FillColor ("Fill Color", Color) = (1,1,1,1)
        _WireWidth ("Wire Width", Range(0.1,2)) = 0.2
        
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed2 randVec(fixed2 value)
            {
                fixed2 vec = fixed2(dot(value, fixed2(127.1, 337.1)), dot(value, fixed2(269.5, 183.3)));
                vec = -1 + 2 * frac(sin(vec) * 43758.5453123);
                return vec;
            }

            float PerlinNoise(float2 uv)
            {
                float a, b, c, d;
                float x0 = floor(uv.x);
                float x1 = ceil(uv.x);
                float y0 = floor(uv.y);
                float y1 = ceil(uv.y);
                fixed2 pos = frac(uv);
                a = dot(randVec(fixed2(x0, y0)), pos - fixed2(0, 0));
                b = dot(randVec(fixed2(x0, y1)), pos - fixed2(0, 1));
                c = dot(randVec(fixed2(x1, y1)), pos - fixed2(1, 1));
                d = dot(randVec(fixed2(x1, y0)), pos - fixed2(1, 0));
                float2 st = 6 * pow(pos, 5) - 15 * pow(pos, 4) + 10 * pow(pos, 3);
                a = lerp(a, d, st.x);
                b = lerp(b, c, st.x);
                a = lerp(a, b, st.y);
                return a;
            }            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 scuv : TEXCOORD4;
                float4 vertex : SV_POSITION;
                float4 worldNormal : TEXCOORD1;
                float4 worldView : TEXCOORD2;
                float4 worldPos : TEXCOORD3;
            };

            fixed4 _RimColor;
            fixed4 _Color;
            fixed4 _ScannerColor;
            float _RimStrength;
            float _NoiseStrength;

            sampler2D _ScannerTex;
            sampler2D _NoiseTex;
            float4 _ScannerTex_ST;
            float _ScannerSpeed;
            float _ScannerStrength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.scuv = TRANSFORM_TEX(v.uv, _ScannerTex);

                o.worldNormal = mul(unity_ObjectToWorld, v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldView =float4(normalize( _WorldSpaceCameraPos.xyz - o.worldPos.xyz), 0);
                return o;
            }

       
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = _Color;
                float fresnel = pow(1 - abs(dot(normalize(i.worldNormal),normalize(i.worldView))) , 1/_RimStrength);
                col = lerp(col, _RimColor, fresnel);

                fixed4 scannerCol = tex2D(_ScannerTex, frac(_Time.y * _ScannerSpeed) + i.scuv) * _ScannerColor;
                col.rgb+=scannerCol.rgb * _ScannerStrength;
                col = saturate(col);
                
                return col;
            }
            ENDCG
        }
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

                if(d < _WireWidth * 0.003 / i.vertex.w){
                    col_Wire = _WireColor;
                }
                else{
                    col_Wire = fixed4(0,0,0,0);
                }
                return col_Wire;
            }
            ENDCG
        }
    }
}
