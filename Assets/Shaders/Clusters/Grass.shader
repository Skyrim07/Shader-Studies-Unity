Shader "Grass"{
 Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AlphaTex("Alpha (A)", 2D) = "white" {}
        _Height("Grass Height", float) = 3
        _Width("Grass Width", range(0, 0.1)) = 0.05
        _WindSpeed("WindSpeed", float) = 5
        _WindForce("WindForce",float) = 1
    }
    SubShader
    {
        Tags { "Queue"="AlphaTest" "RenderType" = "TransparentCutout" "IgnoreProjector" = "True"}
        LOD 100
        Cull Off

        Pass
        {
            Cull OFF
            Tags{ "LightMode" = "ForwardBase" }
            AlphaToMask On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            #pragma target 4.0

            struct v2g
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                //这一步所添加的观察空间坐标
                float3 viewPos : TEXCOORD1;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
            };
            
            sampler2D _MainTex;
            sampler2D _AlphaTex;
            float4 _MainTex_ST;
            float _Width;
            float _Height;
            float _WindSpeed;
            float _WindForce;
            float _LODDistance1;
            float _LODDistance2;

            v2g vert (appdata_full v)
            {
                v2g o;
                o.pos = v.vertex;
                o.normal = v.normal;
                o.uv = v.texcoord;
                //进行观察坐标计算
                o.viewPos = mul(UNITY_MATRIX_MV, v.vertex);
                return o;
            }

            g2f createGSOut() {
                g2f output;

                output.pos = float4(0, 0, 0, 0);
                output.normal = float3(0, 0, 0);
                output.uv= float2(0, 0);

                return output;
            }
            
            [maxvertexcount(30)]
            void geom (point v2g points[1], inout TriangleStream<g2f> triStream)
            {
                float4 root = points[0].pos;

                float random = sin(UNITY_HALF_PI * frac(root.x) + UNITY_HALF_PI * frac(root.z));

                _Width = _Width + (random / 50);
                _Height = _Height +(random / 5);

                fixed randomAngle = frac(sin(root.x)*10000.0) * UNITY_HALF_PI;

                float4x4 firstransfromMat = float4x4(1.0, 0.0, 0.0, -root.x,
                0.0, 1.0, 0.0, -root.y,
                0.0, 0.0, 1.0, -root.z,
                0.0, 0.0, 0.0, 1.0);

                float4x4 transformationMatrix = float4x4(cos(randomAngle), 0, sin(randomAngle),0,
                0, 1, 0, 0,
                -sin(randomAngle), 0, cos(randomAngle),0,
                0, 0, 0, 1);

                float4x4 lasttransformat = float4x4(1.0, 0.0, 0.0, root.x,
                0.0, 1.0, 0.0, root.y,
                0.0, 0.0, 1.0, root.z,
                0.0, 0.0, 0.0, 1.0);
                
                    const int vertexCount = 12;

                    g2f v[vertexCount] = {
                        createGSOut(), createGSOut(), createGSOut(), createGSOut(),
                        createGSOut(), createGSOut(), createGSOut(), createGSOut(),
                        createGSOut(), createGSOut(), createGSOut(), createGSOut()
                    };

                    float currentV = 0;
                    float offsetV = 1.0 / (vertexCount/2 - 1);

                    float currentHeightOffset = 0;
                    float currentVertexHeight = 0;
                    float windCoEff = 0;

                    
                    for (uint i = 0; i < vertexCount; i++)
                    {
                        v[i].normal = fixed3(0, 0, 1);

                        if(fmod(i, 2) == 0)
                        { 
                            v[i].pos = float4(root.x - _Width, root.y + currentVertexHeight, root.z, 1);
                            v[i].uv = fixed2(0, currentV);
                        }
                        else
                        {
                            v[i].pos = float4(root.x + _Width, root.y + currentVertexHeight, root.z, 1);
                            v[i].uv = fixed2(1, currentV);

                            currentV += offsetV;
                            currentVertexHeight = currentV * _Height;
                        }  
                        v[i].pos = mul(lasttransformat,mul(transformationMatrix,mul(firstransfromMat, v[i].pos)));
                        
                        float2 randomDir = float2(sin((random*15)), sin((random*10)));
                        v[i].pos.xz += (sin((root.x * 10 + root.z / 5) * random)* windCoEff + randomDir * sin((random*15)))* windCoEff;

                        float2 windDir = fixed2(1, 1);
                        float2 wind = windDir * sin(_Time.y * UNITY_PI * _WindSpeed * (root.x * windDir.x + root.z * windDir.y)/100);
                        v[i].pos.xz += wind *_WindForce * windCoEff * 0.2;
                        v[i].pos.y -= length(wind *_WindForce * windCoEff);
                        
                        if (fmod(i, 2) == 1) {
                            windCoEff += offsetV;
                        }
                        
                        v[i].pos = UnityObjectToClipPos(v[i].pos);
                    }
                    for (int p = 0; p < (vertexCount - 2); p++) {
                        triStream.Append(v[p]);
                        triStream.Append(v[p + 2]);
                        triStream.Append(v[p + 1]);
                    }
                }


            fixed4 frag (g2f i) : SV_Target
            {
                // sample the texture
                fixed3 col = tex2D(_MainTex, i.uv);
                fixed4 alpha = tex2D(_AlphaTex, i.uv);

                fixed3 light;
                half3 worldNormal = UnityObjectToWorldNormal(i.normal);
                //ambient
                fixed3 ambient = ShadeSH9(half4(worldNormal, 1));

                //diffuse
                fixed3 diffuseLight = saturate(dot(worldNormal, UnityWorldSpaceLightDir(i.pos))) * _LightColor0;

                //specular Blinn-Phong 
                fixed3 halfVector = normalize(UnityWorldSpaceLightDir(i.pos) + WorldSpaceViewDir(i.pos));
                fixed3 specularLight = pow(saturate(dot(worldNormal, halfVector)), 15) * _LightColor0;

                light = ambient + diffuseLight + specularLight;

                return fixed4(col * light, alpha.r);
            }
            ENDCG
        }
    }
}