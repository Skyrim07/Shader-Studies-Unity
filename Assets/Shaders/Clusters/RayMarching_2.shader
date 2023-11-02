
Shader "AlexLiu/RayMarching_2"
{
    Properties
    {
        _Color ("Color", Color) = (0.7,0.7,0.7,1)
        _Center ("Center", Vector) = (0,0,0)
        _Radius ("Radius", float) =1
        _StepCount ("StepCount", float) =16
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
            #include "Lighting.cginc"

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

            fixed4 _Color;
            float4 _Center;
            float _Radius;
            float _StepCount;

            fixed4 LambertBlinn(fixed3 normal,float3 direction) {
                    fixed3 viewDirection = direction;
                    fixed3 lightDir = _WorldSpaceLightPos0.xyz; 
                    fixed3 lightCol = _LightColor0.rgb;
                    fixed NdotL = max(dot(normal, lightDir), 0);
                    fixed4 c;

                    fixed3 h = (lightDir - viewDirection) / 2.;
                    fixed s = pow(dot(normal, h), 5) * 0.7;
                    c.rgb = _Color * lightCol * NdotL + s;
                    c.a = 1;                    
                    return c;
                }

            float RMDistance(float3 pos)
            {
                return distance(pos,mul(unity_ObjectToWorld,  _Center)) - _Radius;
            }

            float3 Normal(float3 p)
            {
                const float eps = 0.01;
                return normalize
                (
                        float3(RMDistance(p + float3(eps, 0, 0)) - RMDistance(p - float3(eps, 0, 0)),
                        RMDistance(p + float3(0, eps, 0)) - RMDistance(p - float3(0, eps, 0)),
                        RMDistance(p + float3(0, 0, eps)) - RMDistance(p - float3(0, 0, eps)))
                );
            }

            fixed4 RayMarch(float3 startPos, float3 dir)
            {
                float stepCount = _StepCount;
                float stepLength = 0.1;
        
                for(int i =0;i<stepCount;i++)
                {
                    float dist = RMDistance(startPos);
                    if(dist < 0.01){
                        float3 normal = Normal(startPos);
                        return LambertBlinn(normal, dir);
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

            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewDir = normalize(i.wPos.xyz - _WorldSpaceCameraPos);
                fixed4 rm = RayMarch(i.wPos.xyz, viewDir);
                fixed4 col = (rm+0.8) * _Color;
                return col;
            }
            ENDCG
        }
    }
}
