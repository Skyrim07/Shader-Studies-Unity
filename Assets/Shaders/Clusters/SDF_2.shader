
Shader "AlexLiu/SDF_2"
{
    Properties
    {
        _Color ("Color", Color) = (0.7,0.7,0.7,1)
        _Center ("Center", Vector) = (0,0,0)
        _Center1 ("Center2", Vector) = (0,0,0)
        _Size ("Size", Vector) = (1,1,1)
        _StepCount ("StepCount", float) =16
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off

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
            float4 _Center1;
            float4 _Size;
            float _StepCount;
            float _Blend;

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

            float sdf_sphere(float3 p,float3 c, float3 s)
            {
                return distance(p, c) -s.x;
            }

            float sdf_box(float3 p, float3 c, float3 s)
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

            float sdf_smin(float a, float b, float k = 32)
            {
                float res = exp(-k*a) + exp(-k*b);
                return -log(max(0.0001,res)) / k;
            }

            float RMDistance(float3 pos)
            {
                float sdist1 = abs(sdf_sphere(pos, mul(unity_ObjectToWorld, _Center), _Size)) - 0.2;
                float sdist2 =  abs(sdf_sphere(pos, mul(unity_ObjectToWorld, _Center1), _Size)) - 0.2;

                return sdf_smin( sdist1,  sdist2, 1);
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
                    if(dist < 0.01)
                    {
                        float3 normal = Normal(startPos);
                        return LambertBlinn(normal, dir);
                    }
                    startPos+=dir*dist;
                }
                return -1;
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
                clip(rm.x+0.9);
                fixed4 col = (rm+0.8) * _Color;
                return col;
            }
            ENDCG
        }
    }
}
