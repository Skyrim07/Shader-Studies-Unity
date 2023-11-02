Shader "AlexLiu/IE_AlphaFade"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SecondTex ("Texture2", 2D) = "white" {}
        _FadeX ("FadeX", float) = 1
        _FadeY ("FadeY", float) = 1
        _Amount ("FadeAmount", Range(0,1)) =1
    }
    SubShader
    {
        Tags
        { 
            "Queue"="Transparent" 
            "IgnoreProjector"="True" 
            "RenderType"="Transparent" 
        }

        Cull Off
        Lighting Off
        Blend SrcAlpha OneMinusSrcAlpha

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _SecondTex;
            float _FadeX;
            float _FadeY;
            float _Amount;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 dir = normalize(float2(_FadeX, _FadeY));
                fixed x = 1 - (i.uv.x * dir.x-_Amount) / _Amount;
                fixed y = 1 - (i.uv.y * dir.y-_Amount) / _Amount;

                fixed4 col = x > 0 ? tex2D(_MainTex, i.uv) : tex2D(_SecondTex, i.uv);
                col.a=saturate(x*y);
                return col;
            }
            ENDCG
        }
    }
}
