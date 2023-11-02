Shader "AlexLiu/LinePlot"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Threshold ("Threshold", float) = 0.01
        _BackgroundColor ("Background Color", Color) = (0.5,0.5,0.5,1)
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

            float Values[64];
            float _Threshold;

            fixed4 _Color;
            fixed4 _BackgroundColor;

            float DistancePtLine( float2 a, float2 b, float2 p )
            {
	            float2 n = b - a;
	            float2 pa = a - p;
	            float2 c = n * (dot( pa, n ) / dot( n, n ));
	            float2 d = pa - c;
	            return sqrt( dot( d, d ) );
            }

            int IsOnLine(float2 p, float2 a, float2 b){
                return DistancePtLine(a,b,p) <_Threshold ? 1 : 0;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                int ix =clamp(floor(i.uv.x * 64), 0, 63);
                float val = Values[ix];
                float val2 = Values[ix+1];

                fixed4 col = lerp(_Color, _BackgroundColor, IsOnLine(i.uv, float2(floor(i.uv.x * 64) / 64.0, val), float2(floor(i.uv.x * 64) / 64.0 +1.0/64.0, val2))); 
                return col;
            }
            ENDCG
        }
    }
}
