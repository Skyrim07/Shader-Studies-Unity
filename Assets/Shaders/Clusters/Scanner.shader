Shader "AlexLiu/Scanner"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,0.5,0.5,1)
        _ScannerColor ("ScannerColor", Color) = (1,0.5,0.5,1)
        _EdgeColor ("EdgeColor", Color) = (1,1,1,1)
        _ScannerPower ("ScannerPower", float) = 5
        _EdgeWidth ("EdgeWidth", float) =1
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
            fixed4 _ScannerColor;
            fixed4 _EdgeColor;
            float _ScannerPower;
            float _EdgeWidth;
        
            float ScannerRadius0;
            float ScannerMelt0;
            float4 ScannerPos0;

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
                fixed4 col2 = col;
                float ndl = saturate(dot(i.worldNormal, i.worldLight));

                fixed4 diffuse =  fixed4(1,1,1,1) * ndl * 0.5+0.5;

                float dis = pow(saturate(distance(i.worldPos, ScannerPos0) / max(ScannerRadius0, 0.01)), _ScannerPower);
                fixed4 sCol = _ScannerColor;                
                
                col = (dis<0.95 && dis>0.95 -_EdgeWidth*0.05)?_EdgeColor: lerp(sCol, col, dis);
                if(ScannerMelt0>0)
                      col = lerp(col, col2, ScannerMelt0);
                return col * diffuse;
            }
            ENDCG
        }
    }
}
