﻿Shader "AlexLiu/RMDots"
{
    Properties
    {
        _Color ("Color", Color) = (0.7,0.7,0.7,1)
        _DotColor ("Dot Color", Color) = (0.7,0.7,0.7,1)
        _HighlightColor ("Highlight Color", Color) = (0.7,0.7,0.7,1)
        _Center ("Center", Vector) = (0,0,0)
        _Density ("_Density", float) = 5
        _RMRandom ("_RMRandom", Range(0,10)) = 5
        _Radius ("Radius", float) =1
        _StepCount ("StepCount", float) =16
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
                float4 wPos : TEXCOORD1;
            };

            fixed4 _Color, _DotColor, _HighlightColor;
            float4 _Center;
            float _Radius;
            float _StepCount;
            float _Density;
            float _RMRandom;


            float N31(float3 p)
            {
                return frac(sin(dot(p, float3(1928.12, 3846.09, 801263.3+p.x+p.z))) * 1299.1241 + 918.2);
            }

            float N11(float a)
            {
                return frac(sin(a * 183971.13) * 914.1);
            }

            float SDSphere(float3 pos)
            {
                return distance(pos, mul(unity_ObjectToWorld, _Center)) - _Radius;
            }

            float RMDistance(float3 pos)
            {
                float sphere = SDSphere(pos);
                return sphere;
            }

            fixed4 RayMarch(float3 startPos, float3 dir)
            {
                float stepCount = _StepCount;
                float stepLength = 0.1;
        
                for(int i =0;i<stepCount;i++)
                {
                    float dist = RMDistance(startPos);
                    if(dist < 0.01){
                        return 1-((float)i/stepCount * 2);
                    }
                    startPos+=dir*dist;
                }
                return 0;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                _Radius = abs(frac(_Time.y)-0.5)*2;
                i.wPos.xyz = ceil(i.wPos.xyz * _Density) / _Density;
                float3 viewDir = normalize(i.wPos.xyz - _WorldSpaceCameraPos);
                fixed4 rm = RayMarch(i.wPos.xyz, viewDir);
                fixed4 rmColor = rm * _DotColor;
                rmColor.rgb *= (N31(i.wPos.zxy) / _RMRandom + (1-1/ _RMRandom));
                rmColor = rm < 0.9 ? _HighlightColor : rmColor;
                fixed4 col = lerp(rmColor, _Color, 1-rm);
                return col;
            }
            ENDCG
    }
        }
}
