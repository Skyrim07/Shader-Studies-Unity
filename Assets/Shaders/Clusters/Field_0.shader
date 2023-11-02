
Shader "AlexLiu/Field_0"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Noise ("Noise", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _NoiseColor ("NoiseColor", Color) = (1,1,1,0.2)
        _RimColor ("RimColor", Color) = (0,0,0,1)
        _Threshold ("Threshold", float) =2
        _Power ("Power", float) =5
        _Fresnel ("Fresnel", float) =1
        _NoiseStrength("Noise Strength", float) = 1
        _NoiseSpeed("Noise Speed", float) = 1
}
    SubShader
    {
       Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
	    Cull Off
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
                float2 nuv : TEXCOORD1;
                float4 vertex : SV_POSITION;
                float4 scrPos : POSITION1;
                float4 worldNormal : POSITION2;
                float4 worldView : POSITION3;
                float4 worldPos : POSITION4;
            };

            sampler2D _MainTex;
            sampler2D _Noise;
            sampler2D _CameraDepthTexture;
            float4 _MainTex_ST;
            float4 _Noise_ST;
            fixed4 _Color;
            fixed4 _RimColor;
            fixed4 _NoiseColor;
            float _Threshold;
            float _Fresnel;
            float _Power;
            float _NoiseStrength;
            float _NoiseSpeed;

            float4 _HitPoint;
            float _HitRadius = 1;

            float Distance (float4 v1, float4 v2){
                return sqrt(pow(v1.x-v2.x, 2)+pow(v1.y-v2.y, 2)+pow(v1.z-v2.z, 2));
            }            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.nuv = TRANSFORM_TEX(v.uv, _Noise);
                
                o.worldNormal = mul(unity_ObjectToWorld, v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldView =float4(normalize( _WorldSpaceCameraPos.xyz - o.worldPos.xyz), 0);

                o.scrPos = ComputeScreenPos(o.vertex);
               // COMPUTE_EYEDEPTH(o.scrPos.z);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                
                col *= lerp(col, fixed4(1,1,1,1), saturate(sin(_Time.y * 3)));
                col *= saturate(tex2D(_Noise, i.nuv + frac(_Time.x * _NoiseSpeed)) / (1/_NoiseStrength)) * _NoiseColor;

                //Contact
                float dist = Distance(i.worldPos, _HitPoint) / _HitRadius;
                if(dist <= 1)
                    return fixed4(0,0,0,0);
                col = lerp(col, _RimColor,  pow(1- saturate((dist - 1)/_Threshold * 2), _Power) );                

                //Rim
                float fresnel = pow(1 - abs(dot(normalize(i.worldNormal),normalize(i.worldView))) , _Fresnel);
                col = lerp(col, _RimColor, fresnel);

                // Scene contact
                float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, i.scrPos));
                float selfZ = i.scrPos.w;
                float diff =min(pow((1-saturate(sceneZ-selfZ))/_Threshold,_Power), 1.0);
                col = lerp(col,_RimColor, diff);

                return col;
            }
            ENDCG
        }
    }
}
