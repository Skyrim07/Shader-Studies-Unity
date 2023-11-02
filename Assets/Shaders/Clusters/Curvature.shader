Shader "AlexLiu/Curvature"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "LightMode" = "ForwardBase"}
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
                float4 worldPos : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
                float3 worldLight : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed4 _Color;

            float4 _CurvatureCenter;
            float _CurvatureValue;
            float _CurvaturePower;

            v2f vert (appdata v)
            {
                v2f o;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = normalize(mul(unity_ObjectToWorld, v.normal));
                o.worldLight = normalize(_WorldSpaceLightPos0);
                float dist = distance(o.worldPos.z, _CurvatureCenter.z);
                dist = pow(dist, _CurvaturePower);
                v.vertex.y += dist* _CurvatureValue;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                float ndl = max(0, dot(i.worldNormal, i.worldLight));
                ndl = ndl * 0.8 + 0.2;
               col.rgb *= ndl;
                
                return col;
            }
            ENDCG
        }
    }
}
