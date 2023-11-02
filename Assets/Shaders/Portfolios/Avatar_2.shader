Shader "AlexLiu/Avatar_2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                uint instanceID : SV_InstanceID;
                uint vertID : SV_VertexID;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float size : PSIZE;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            StructuredBuffer<float3> pointBuffer;
            float pointCount;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(float4(pointBuffer[v.instanceID].xyz, 1.0f));
                o.size = 500;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float c = 1000;
                fixed4 col = float4(saturate(pointBuffer[3400].xyz), 1.0f);
                return col;
            }
            ENDCG
        }
    }
}
