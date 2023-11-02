Shader "Unlit/Voronoi"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Density("Density", float) = 1
        _Speed("Speed", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Density;
            float _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            float2 N22(float2 p)
            {
                float3 a = frac(p.xyx * float3(123.34, 234.34, 345.65));
                a += dot(a, a + 34.45);
                return frac(float2(a.x * a.y, a.y * a.z));
            }
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                float2 uv = i.uv * _Density;
                float2 gv = frac(uv) - 0.5;
                float2 id = floor(uv);

                float minDist = 100;
                float2 cellid = float2(0, 0);
                for(float x = -1; x<=1; x++)
                    for (float y = -1; y <= 1; y++) {
                        float2 offset = float2(x, y);
                        float2 n = N22(offset + id);

                        float2 p = offset + sin(n * _Time.y*_Speed) * 0.5;
                        float d = length(gv - p);
                        if (d < minDist) {
                            minDist = d;
                            cellid = offset + id;
                        }
                    }
                float c = (cellid.x*5 + cellid.y*5 + 10) / 10/_Density;

                col = float4(c, c, c, 1);
                return col;
            }
            ENDCG
        }
    }
}
