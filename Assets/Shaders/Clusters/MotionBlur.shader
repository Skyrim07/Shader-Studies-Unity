Shader "AlexLiu/MotionBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Direction("Direction",vector) = (0,0,0,1)
        _Color ("Color", Color) = (1,1,1,1)
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float2 ndd : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Direction;

            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                fixed NdotD = max(0,dot(v.normal,_Direction));
                float noise = frac(sin(dot(v.uv.xy, float2(12.9898, 78.233))) * 43758.5453);
                v.vertex.xyz += _Direction.xyz * _Direction.w * noise * NdotD;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ndd.x = NdotD;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                col += _Color * i.ndd.x;
                return col;
            }
            ENDCG
        }
    }
}
