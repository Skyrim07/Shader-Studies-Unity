Shader "AlexLiu/BoxPlot"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
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

            float Values[256];

            fixed4 _Color;
            fixed4 _BackgroundColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float val = Values[round(i.uv.x * 256)];

                fixed4 col = lerp(_Color, _BackgroundColor, step(i.uv.y , val)); 
                return col;
            }
            ENDCG
        }
    }
}
