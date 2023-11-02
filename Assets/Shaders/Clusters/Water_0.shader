Shader "AlexLiu/Water_0"
{
    Properties
    {
        _DisplacementTex("Displacement Texture", 2D) = "white" {}
    	_Magnitude("Magnitude", Range(0, 1)) =  0.5
    	_Speed("Speed", float) =  1
    	_Color("Color", Color) =  (0.8,0.8,0.8,1)
    	_HighlightColor("Highlight Color", Color) =  (0.8,0.8,0.8,1)
    	_Threshold("Threshold", float) =  1
    	_Power("Power", float) =  8
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        GrabPass{"_GrabTex"}

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
                float2 duv : TEXCOORD1;
                float4 vertex : SV_POSITION;
                float4 grabPos : TEXCOORD2;
                float4 scrPos : TEXCOORD3;
            };

            sampler2D _GrabTex;
            sampler2D _DisplacementTex;
            sampler2D _CameraDepthTexture;
            float4 _DisplacementTex_ST;
            float _Magnitude;
            float _Speed;
            float _Threshold;
            float _Power;
            fixed4 _Color;
            fixed4 _HighlightColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.duv = TRANSFORM_TEX(v.uv, _DisplacementTex);
                o.grabPos = ComputeGrabScreenPos(o.vertex);

                o.scrPos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.scrPos.z);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 disp = tex2D(_DisplacementTex, i.duv+ frac(_Time.y * _Speed * 0.05)).xy ;
                disp = ((disp * 2) - 1) * _Magnitude;
	            float4 col = tex2Dproj(_GrabTex, i.grabPos + float4(disp.xy,0,0));
                col *= _Color;

                float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
                float selfZ = i.scrPos.w;
                float diff =min(pow((1-saturate(sceneZ-i.scrPos.z))/_Threshold,_Power), 1.0);
                col = lerp(col, _HighlightColor,diff);

                return col;
            }
            ENDCG
        }
    }
}
