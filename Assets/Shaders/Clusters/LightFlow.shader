Shader "Unlit/LightFlow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _LightColor ("Light Color", Color) = (1,1,1,1)
        _Radian ("Angle Radian", float) = 0
        _SpeedX ("Speed", float) = 1
        _Strength ("Strength", float) = 1
        _Width ("Width", float) = 1
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
            fixed4 _LightColor;
            float _SpeedX;
            float _Strength;
            float _Radian;
            float _Width;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldPos =  normalize(mul(unity_ObjectToWorld, v.vertex));
                o.worldNormal = normalize(mul(unity_ObjectToWorld, v.normal));
                o.worldLight = float4(normalize(UnityWorldSpaceLightDir(o.worldPos)),0);
                o.worldView =float4(normalize(o.worldPos.xyz-_WorldSpaceCameraPos.xyz), 0);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                float ndl = saturate(dot(i.worldNormal, i.worldLight));
                fixed4 diffuse =  fixed4((fixed3(1,1,1) * ndl * 0.5 + 0.5).rgb, 1);
                col *= diffuse;

                fixed cosV = cos(_Radian);
				fixed sinV = sin(_Radian);
 
				fixed4x4 rotMatrix = fixed4x4(cosV, -sinV, 0, 0,
											  sinV, cosV, 0, 0,
											  0, 0, 1, 0,
											  0, 0, 0, 1);
				float2 uv = mul(rotMatrix, float4(i.uv, 0, 0)).xy;
                uv.y += cos(fmod(_Time.y * _SpeedX, 3.14)) * 2;

                float v = abs(uv.y) * _Width + 1;
				v = 1 / v;
				col += _LightColor* v;

                return col;
            }
            ENDCG
        }
    }
}
