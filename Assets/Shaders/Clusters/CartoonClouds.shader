Shader "AlexLiu/CartoonClouds"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color1 ("Color 1", Color) = (1,1,1,1)
        _Color2 ("Color 2", Color) = (0,0,0,1)
        _Threshold("Threshold", float) = 1
        _Power("Power", float) =3
        _Height("Height", float) =2
        _Speed("Speed", float) =1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
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
                float4 scrPos : TEXCOORD1;
                float2 CloudUV01 : TEXCOORD2;
                float2 CloudUV02 : TEXCOORD3;
                float2 noisePos : TEXCOORD4;
            };

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float4 _MainTex_ST;

            float _Threshold;
            float _Power;
            float _Height;
            float _Speed;

            fixed4 _Color1, _Color2;

            v2f vert (appdata v)
            {
                v2f o;

                o.CloudUV01 = v.uv + _Time.x * _Speed;
                o.CloudUV02 = v.uv - _Time.x * _Speed;
                o.noisePos.x = tex2Dlod(_MainTex, float4(o.CloudUV01, 0, 0)).r;
                o.noisePos.y = tex2Dlod(_MainTex, float4(o.CloudUV02, 0, 0)).r;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex.y += o.noisePos.x * o.noisePos.y * _Height;

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.scrPos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.scrPos.z);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                col = lerp(_Color1, _Color2, i.noisePos.y);

                float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
                float selfZ = i.scrPos.w;
                float diff = min(pow((1 - saturate(sceneZ - i.scrPos.z)) / _Threshold, _Power), 1.0);
                float depthDiff = saturate(pow(abs(sceneZ - selfZ) / _Threshold, _Power));
                col.a = depthDiff *1;

                return col;
            }
            ENDCG
        }
    }
}
