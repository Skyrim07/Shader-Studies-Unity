Shader "Hidden/IE_NightVision"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _Color ("Color", color) = (0.2,1,0.2,1)
        _Density ("Line Density", float) = 10
        _Speed ("Line Speed", float) = 1
        _LineColor ("Line Color", color) = (1,1,1,1)
        _LineStrength ("Line Strength", Range(0,1)) = 0.5
        _Block("Block Size", float) = 2
        _NoiseBlock("Noise Block Size", float) = 2
        _NoiseStrength ("Noise Strength", Range(0,1)) = 0.5
    }
    SubShader
    {
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

            float random(float value, float seed = 0.546){
	            float random = (frac(sin(value + seed) * 143758.5453));
	            return random;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            float _Density;
            float _Speed;
            float _Block;
            float _NoiseBlock;
            fixed4 _LineColor;
            fixed4 _Color;
            fixed _LineStrength;
            fixed _NoiseStrength;

            fixed4 frag (v2f i) : SV_Target
            {
                // pixelize
                i.uv = ceil( i.uv*_Block) / _Block;
                fixed4 col = tex2D(_MainTex, i.uv);

                // noise
                fixed2 blockeduv= ceil( i.uv*_NoiseBlock) / _NoiseBlock;
                fixed noise = tex2D(_NoiseTex, fixed2(random(blockeduv.x+_Time.y), random(blockeduv.y+_Time.y))).r;
                col = lerp (col, col*noise, _NoiseStrength);

                // scan line
                fixed scanLine = frac(i.uv.y*_Density+_Time.y*_Speed) ;
                scanLine = saturate(1 - smoothstep(0.1,0.8,scanLine))* _LineStrength;
                col = lerp(col, _LineColor, scanLine);

                // color tint
                col = Luminance(col) * _Color;

                return col;
            }
            ENDCG
        }
    }
}
