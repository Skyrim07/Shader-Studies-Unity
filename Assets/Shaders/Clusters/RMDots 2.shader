Shader "AlexLiu/RMDots2"
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

            float4 _Points[27];

            float N31(float3 p)
            {
                return frac(sin(dot(p, float3(1928.12, 3846.09, 801263.3+p.x+p.z))) * 1299.1241 + 918.2);
            }

            float N11(float a)
            {
                return frac(sin(a * 183971.13) * 914.1);
            }

            float SDSphere(float3 uvpos, float4 center)
            {
                return distance(uvpos, mul(unity_ObjectToWorld, center)) - _Radius;
            }

            //uvpos, center, size
            float SDBox(float3 p, float3 c, float3 s)
            {
                float x = max
                (p.x - c.x - float3(s.x / 2., 0, 0),
                    c.x - p.x - float3(s.x / 2., 0, 0)
                );
                float y = max
                (p.y - c.y - float3(s.y / 2., 0, 0),
                    c.y - p.y - float3(s.y / 2., 0, 0)
                );

                float z = max
                (p.z - c.z - float3(s.z / 2., 0, 0),
                    c.z - p.z - float3(s.z / 2., 0, 0)
                );
                float d = x;
                d = max(d, y);
                d = max(d, z);
                return d;
            }
            float RMDistance(float3 uvpos, float4 center)
            {
                float sphere = SDSphere(uvpos, center);
                return sphere;
            }

            float distLine(float3 A, float3 B, float3 C) {
                return length(cross(A - B, C - B)) / length(C - B);
            }

            float RayMarch(float3 startPos, float3 dir, float4 center, float4 nextCenter)
            {
                float stepCount = _StepCount;
                float stepLength = 0.01;

                float result=0;
        
                for(int i =0;i<stepCount;i++)
                {
                    float dist = RMDistance(startPos, center);
                    if(dist < 0.0005){
                        //result += (float)i / stepCount;
                       result+= 1-((float)i/stepCount * 0.6f);
                       return saturate(result);
                    }

                    startPos+=dir* dist;
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
                float3 viewDir = normalize(i.wPos.xyz - _WorldSpaceCameraPos);
                fixed4 rm = 0;
                for (int x = 0; x < 26; x++)
                {
                    _Points[x].xyz *= 0.4f;
                    float xrm = RayMarch(i.wPos.xyz, viewDir, _Points[x], _Points[x+1]);
                    xrm = pow(xrm, 4) * 2;
                    rm += xrm; 
                    //if (xrm > 0)
                    //    break;
                }
               
                fixed4 rmColor = rm * _DotColor;
                rmColor.a = 1;
                fixed4 col = fixed4(_HighlightColor.rgb, _Color.a);
                col.rgb = lerp(rmColor.rgb, _Color.rgb, saturate(1.f - rm));
                return col;
            }
            ENDCG
    }
        }
}
