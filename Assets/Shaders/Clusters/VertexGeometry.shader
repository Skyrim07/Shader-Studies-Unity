
Shader "AlexLiu/VertexGeometry"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Resolution("Resolution", float) = 5
        _Smoothness("Smoothness", range(0,1)) = 0.5
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
                float3 normal : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Resolution;
            float _Smoothness;

            float4 voxelize(float4 x)
            {
                x = floor(x);
                return x;
            }

            v2f vert(appdata v)
            {
                v2f o;
                _Smoothness = smoothstep(float2(-.5,-.5), float2(.9, .9), v.normal.yz);
                float4 voxelVert = voxelize(v.vertex * _Resolution) / _Resolution * _Smoothness + v.vertex * (1 - _Smoothness);
                o.vertex = UnityObjectToClipPos(voxelVert);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = mul(unity_ObjectToWorld, v.normal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = fixed4(1,1,1,1);
                float ndl = max(0, dot(i.normal, _WorldSpaceLightPos0))*0.7+0.2;
                col.rgb *= ndl;
                col.rg = i.uv;
                return col;
            }
            ENDCG
        }
    }
}
