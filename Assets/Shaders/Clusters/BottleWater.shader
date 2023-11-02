
Shader "AlexLiu/BottledWater"
{
      Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,0.5,0.5,1)
        _WaterLevel("Water Level", Range(0,1)) = 0.5
        _OutlineColor ("Outline Color", Color) = (1,1,1,1)
        _OutlineWidth ("Outline Width", Range(0,5)) = 0.5
    }
    SubShader
    {
        
        LOD 100
    
        Pass
        {
            Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
            Cull Front
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            float _OutlineWidth;
            fixed4 _OutlineColor;

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex.xyz += v.normal * _OutlineWidth * 0.075;
                o.vertex = UnityObjectToClipPos(v.vertex);
        
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }
    
        Pass
        {
            Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
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
                float4 worldNormal : TEXCOORD1;
                float4 worldLight : TEXCOORD2;
                float4 worldView : TEXCOORD3;
                float4 worldPos : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;

            float _WaterLevel;
            float _LPos;
            float _HPos;
    
            fixed2 randVec(fixed2 value)
            {
                fixed2 vec = fixed2(dot(value, fixed2(127.1, 337.1)), dot(value, fixed2(269.5, 183.3)));
                vec = -1 + 2 * frac(sin(vec) * 43758.5453123);
                return vec;
            }

            float perlinNoise(float2 uv)
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        
                o.worldPos =  mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = normalize(mul(unity_ObjectToWorld, v.normal));
                o.worldLight = float4(normalize(UnityWorldSpaceLightDir(o.worldPos)),0);
                o.worldView = float4(normalize(UnityWorldSpaceViewDir(o.worldPos)),0);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                
                float noiseValue = 0.5 * abs(frac(i.worldPos.xz + i.worldPos.zx + float2(_Time.y, 1.5 * _Time.y)) - 0.5);
                 _WaterLevel += 0.05 * perlinNoise(noiseValue);

                if(_LPos+_WaterLevel*(_HPos-_LPos) > i.worldPos.y){
                     if(abs(_LPos+_WaterLevel*(_HPos-_LPos) - i.worldPos.y)<0.02){
                        col.rgb*=0.8;
                        }
                }
                else{
                    discard;
                }
                return col;
            }
            ENDCG
        }
    }
}
