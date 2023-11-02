// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "AlexLiu/DimensionShift"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DValue("Dimension", range(0,1)) = 0.5
        _Direction("Direction", vector) = (0,0,1,0)
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
				float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float3 normal: TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _DValue;
            float4 _Direction;

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex.z *= _DValue;
                o.vertex = UnityObjectToClipPos(v.vertex);
                v.normal *=_DValue;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = mul(unity_ObjectToWorld, v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed diffuse = saturate(dot(i.normal, _WorldSpaceLightPos0));
                fixed hLbt =0.5 + diffuse * 0.5;
                col = hLbt * col;
                return col;
            }
            ENDCG
        }
    }
}
