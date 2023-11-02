Shader "AlexLiu/Fireworks"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _Scatter ("Scatter", float) = 2
        _ScatterLimit ("Scatter Limit", float) = 4
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
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
                float2 gv : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 gv: TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NoiseTex;

            float _Radius, _Smooth, _Speed;
            int _BlockSize;
            float _Scatter, _ScatterLimit;

            float N11(float a) {
                return frac(sin(a * 25252.15) * 1145.14);
            }

            v2f vert (appdata v)
            {
                v2f o;
                float4 dir = normalize(v.vertex-1);
                v.vertex += dir * _Scatter;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.gv = v.gv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.uv = ceil(i.uv * _BlockSize) / _BlockSize;
                fixed4 col = tex2D(_MainTex, i.uv);
                float t = frac(_Time.y * 0.01f * _Speed);
                float n = tex2D(_NoiseTex, i.uv + float2(t,t));
                col *= n/2+0.9;
                _Radius *= (n / 4 + 0.8);
                float alpha = smoothstep(_Radius, _Radius-_Smooth, length(i.gv - fixed2(.5, .5)));
                col.a *= alpha;
                col.a *= n;

                col.a *= smoothstep(_ScatterLimit, _ScatterLimit / 2.0f, _Scatter);
                return col;
            }
            ENDCG
        }
    }
}
