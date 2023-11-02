Shader "Alex Liu/079"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color1 ("Color 1", Color) = (1,1,1,1)
        _Color2 ("Color 2", Color) = (1,1,1,1)
        _Color3 ("Color 3", Color) = (1,1,1,1)
        _Color4 ("Color 4", Color) = (1,1,1,1)
        _Color5 ("Color 5", Color) = (1,1,1,1)
        _Noise1 ("Noise 1", float) =1
        _Noise2 ("Noise 2", float) =1
        _Noise3 ("Noise 3", float) =1
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

            float rand(float2 uv) {
                return frac(sin(dot(uv.xy, float2(12.9898, 18.233))) * 4758.5453123);
            }

            float noise(float2 uv) {
                float2 ipos = floor(uv);
                float2 fpos = frac(uv);

                float o = rand(ipos);
                float x = rand(ipos + float2(1, 0));
                float y = rand(ipos + float2(0, 1));
                float xy = rand(ipos + float2(1, 1));

                float2 smooth = smoothstep(0, 1, fpos);
                return lerp(lerp(o,  x, smooth.x),
                             lerp(y, xy, smooth.x), smooth.y);
            }

            float fractal_noise(float2 uv) {
                float n = 0;
                n = (1 / 2.0) * noise(uv * 1);
                n += (1 / 4.0) * noise(uv * 2);
                n += (1 / 8.0) * noise(uv * 4);
                n += (1 / 16.0) * noise(uv * 8);
                n = pow(n, 3);
                return saturate(n);
            }
            float cloud(float2 uv, float t) {
                float res = fractal_noise(uv);
                res += fractal_noise(uv /2);
                res = smoothstep(0, .6+abs(sin(_Time.y*t/2))*0.05, res);
                return res;
            }
            float circle(float2 uv, float2 pos, float r) {
                return smoothstep(r, r + 0.05, length(uv - pos));
            }

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
            float _Noise1, _Noise2, _Noise3;
            fixed4 _Color1, _Color2, _Color3, _Color4, _Color5;
                
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = lerp(_Color1, _Color3, i.uv.y);
                float2 uv = i.uv * 2 - 1;

                //sun
                float2 pos = float2(.7, .7);
                float c = 1 - circle(uv, pos, .05);
                for(float x=1;x<8;x++)
                 c += 1 / pow(length(uv - pos) * 8*x, x);

                c = saturate(c);
                col = lerp(col, _Color4, c);

                //cloud layers
                for (float x = 0; x < 5; x++) {
                    float2 uv1 = uv * _Noise1*(x*0.25);
                    float t= _Time.y * (1 / (pow(x, 1.5)));
                    uv1 -= t;
                    float n1 = cloud(uv1, x);
                    n1 = saturate(pow(n1, 2));
                    float s = smoothstep(.8, 1, n1);
                    n1 -= s * .2;
                    s = pow(smoothstep(.5, 1, n1), 2);
                    col = lerp(col, lerp(_Color2, _Color5, x/10), n1);
                }

                return col;
            }
            ENDCG
        }
    }
}
