Shader "Unlit/Lava"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LavaTex ("Lava Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _Speed("Speed", float) = 2
        _NoiseStrength("NoiseStrength", float) = 2
    } 
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _LavaTex, _NoiseTex;
            float _Speed, _NoiseStrength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                float2 luv = i.uv;
                fixed n = tex2D(_NoiseTex, luv).r;
                float2 disp = float2(n * 0.02 * _NoiseStrength, - n * 0.02 * _NoiseStrength);

                luv.x -= _Time.y * 0.02 * _Speed;
                fixed4 lcol = tex2D(_LavaTex, luv+disp);
                col *= lcol;
                return col;
            }
            ENDCG
        }
    }
}
