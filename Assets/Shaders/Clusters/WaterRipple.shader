// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/WaterRipple"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _Scale ("Scale", float) = 1
        _Speed ("Speed", float) = 1
        _Freq ("Frequency", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert

        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float _Scale;
        float _Speed;
        float _Freq;

        float offsetX[8];
        float offsetZ[8];
        float amplitude[8];
        float dist[8];
        float4 ripplePos[8];

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void vert(inout appdata_full v)
        {
            half offsetVert = ((v.vertex.x * v.vertex.x) + (v.vertex.z * v.vertex.z))  ;
            
            for(int i =0; i<8; i++){
                 half value = _Scale * sin(_Time.w * _Speed  + _Freq * offsetVert + v.vertex.x*offsetX[i] + v.vertex.z*offsetZ[i]);
                 if(distance(mul(unity_ObjectToWorld, v.vertex), ripplePos[i])<dist[i]){
                     v.vertex.y += value * amplitude[i];                
                     v.normal.xz += value * amplitude[i] * 3;
                }
            }
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
