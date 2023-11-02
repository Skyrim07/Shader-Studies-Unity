Shader "Unlit/Ghost"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,0.5,0.5,1)
        _RimColor ("Rim Color", Color) = (1,1,1,1)
        _RimStrength ("Rim Strength", float) = 1
    }
    SubShader
    {

        Pass
        {
        Tags { "RenderType"="Opaque" }
            ZTest Less
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        
                o.worldPos =  normalize(mul(unity_ObjectToWorld, v.vertex));
                o.worldNormal = normalize(mul(unity_ObjectToWorld, v.normal));
                o.worldLight = float4(normalize(UnityWorldSpaceLightDir(o.worldPos)),0);
                o.worldView = float4(normalize(UnityWorldSpaceViewDir(o.worldPos)),0);
                return o;
            }

       
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                float ndl = saturate(dot(i.worldNormal, i.worldLight));
                fixed4 diffuse =  fixed4(1,1,1,1) * ndl * 0.5+0.5;
                
                return col * diffuse;
            }
            ENDCG
        }
        Pass
        {
            Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
            ZTest Greater
            Blend SrcAlpha OneMinusSrcAlpha

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
                float4 worldView : TEXCOORD2;
                float4 worldPos : TEXCOORD3;
            };

            fixed4 _RimColor;
            float _RimStrength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.worldNormal = mul(unity_ObjectToWorld, v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldView =float4(normalize( _WorldSpaceCameraPos.xyz - o.worldPos.xyz), 0);
                return o;
            }

       
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = fixed4(1,1,1,0);
                float fresnel = pow(1 - abs(dot(normalize(i.worldNormal),normalize(i.worldView))) , 1/_RimStrength);
                col = lerp(col, _RimColor, fresnel);
                
                return col;
            }
            ENDCG
        }
    }
}
