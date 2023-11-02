Shader "Unlit/SnowTrackGeneration"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "black" {}
        _Coordinate ("Coordinate", Vector) = (0,0,0,0)
        _Color ("Color", Color) = (1,0,0,0)
        _BrushSize ("Brush Size", float) = 1
        _Strength ("Brush Strength", float) = 1
        _Recover ("Recover", float) = 1
        _NoiseStrength ("Noise Strength", float) = 1
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            float4 _MainTex_ST;

            fixed4 _Coordinate;
            fixed4 _Color;

            float _BrushSize;
            float _Strength;
            float _Recover;
            float _NoiseStrength;

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
                fixed4 noiseCol = (tex2D(_NoiseTex, i.uv + frac(_Time.y * 0.1)) -0.5)* 0.05 * _NoiseStrength;
                            
                float draw = pow(saturate(1 - distance(i.uv, _Coordinate.xy + noiseCol.xy)), 50 / _BrushSize);
                fixed4 drawCol = _Color * draw * _Strength;
    
                return saturate(col +drawCol - _Recover * 0.0002);
            }
            ENDCG
        }
    }
}
