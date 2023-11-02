Shader "AlexLiu/PageTurn"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _SecondTex ("Second Texture", 2D) = "white" {}
        _Turn("Turn", Range(0,3.14)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Back
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
            sampler2D _SecondTex;
            float4 _MainTex_ST;

            fixed _Turn;

            v2f vert (appdata v)
            {
                v2f o;
                float theta = _Turn;
                float pi = UNITY_PI;

                float x = v.vertex.x+5, y = v.vertex.y, z = v.vertex.z;
                float flipCurve = exp(-0.05 * pow(v.vertex.x - 0.5, 2)) * _Turn;
                theta += flipCurve;
                
                float coeffx = 0, coeffy = 0;
                float turn01 = _Turn / 3.14f;
                float turnabs = (turn01 - 0.5) * 2;
                coeffx = abs((v.uv.x*3-3))* turnabs;
                coeffy = abs((v.uv.y*3-3))* turnabs;

                x = v.vertex.x * cos(clamp(theta+ coeffx * 0.8, 0, pi));
                y = v.vertex.x * sin(clamp(theta+ coeffy * 0.5, 0, pi));

                y += pow(v.vertex.x, 0.1f);
                float s, c;
                sincos(radians(theta * 180), s, c);
                float4x4 rotMatrix =
                {
                    c, -s, 0,0,
                    s,c, 0,0,
                    0,0,1,0,
                    0,0,0,1
                };

                y /= 3.f;

                float4 vertex = float4(x, y, z, v.vertex.w);
                o.vertex = UnityObjectToClipPos(vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                i.uv.y = -i.uv.y;
                clip(-i.uv.x +0.5);
                i.uv.x *= 2;
                fixed4 col = tex2D(_MainTex, i.uv);

                col *= saturate(((UNITY_HALF_PI - _Turn)/(UNITY_HALF_PI))/2+.5);

                col *=  smoothstep(-0.3, 0.5, 1-i.uv.x);

                return col;
            }
            ENDCG
        }


              Pass
        {
            Cull Front
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
            sampler2D _SecondTex;
            float4 _MainTex_ST;

            fixed _Turn;

            v2f vert(appdata v)
            {
                v2f o;

                float theta = _Turn;
                float pi = UNITY_PI;

                float x = v.vertex.x + 5, y = v.vertex.y, z = v.vertex.z;
                float flipCurve = exp(-0.05 * pow(v.vertex.x - 0.5, 2)) * _Turn;
                theta += flipCurve;

                float coeffx = 0, coeffy = 0;
                float turn01 = _Turn / 3.14f;
                float turnabs = (turn01 - 0.5) * 2;
                coeffx = abs((v.uv.x * 3 - 3)) * turnabs;
                coeffy = abs((v.uv.y * 3 - 3)) * turnabs;

                x = v.vertex.x * cos(clamp(theta + coeffx * 1, 0, pi));
                y = v.vertex.x * sin(clamp(theta + coeffy * 1, 0, pi));

                y += pow(v.vertex.x, 0.1f);
                // x += 5;
                 float s, c;
                 sincos(radians(theta * 180), s, c);
                 float4x4 rotMatrix =
                 {
                     c, -s, 0,0,
                     s,c, 0,0,
                     0,0,1,0,
                     0,0,0,1
                 };

                 y /= 3.f;

                 float4 vertex = float4(x, y, z, v.vertex.w);
                 //vertex = mul(rotMatrix, vertex);


                 o.vertex = UnityObjectToClipPos(vertex);
                 o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                 return o;
             }

             fixed4 frag(v2f i) : SV_Target
             {
                 i.uv.y = -i.uv.y;
                 clip(-i.uv.x + 0.5);
                 i.uv.x *= 2;
                 fixed4 col = tex2D(_SecondTex, i.uv);

                 col *= 1-saturate(((UNITY_HALF_PI - _Turn) / (UNITY_HALF_PI)) / 1.6 + 0.325);
                 col *= smoothstep(-0.3, 0.5, 1 - i.uv.x);

                 return col;
             }
             ENDCG
         }
    }
}
