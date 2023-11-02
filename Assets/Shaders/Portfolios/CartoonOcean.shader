Shader "AlexLiu/CartoonOcean"
{
    Properties
    {
         _NoiseTex("Noise Texture", 2D) = "white" {}
         _CausticsTex("Caustics Texture", 2D) = "white" {}
        [HDR] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
         [HDR]_OceanColorShallow("Ocean Color Shallow", Color) = (1, 1, 1, 1)
        [HDR] _OceanColorDeep("Ocean Color Deep", Color) = (1, 1, 1, 1)
        [HDR] _DirectionalScatteringColor("DirectionalScatteringColor", Color) = (1, 1, 1, 1)
        _BubblesColor("Bubbles Color", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
        _FresnelScale("Fresnel Scale", Range(0, 1)) = 0.5
        _Displace("Displace", 2D) = "black" { }
        _Normal("Normal", 2D) = "black" { }
        _Bubbles("Bubbles", 2D) = "black" { }
        _Alpha ("Alpha", Range(0,1)) = 0.2
        _FoamSpeed ("Foam Speed ", float) = 1
        _FoamDisplacement ("Foam Displacement ", float) = 1
        _FoamPower ("Foam Power ", float) = 1
        _Threshold ("Disp Threshold ", float) = 1
        _FoamThreshold ("Foam Threshold ", float) = 1
        _FracIntensity("Refract Intensity ", float) = 1
        _FracTransparency("Refract Transparency ", Range(0,1)) = 0.5
        _LinearShoreRange("Linear Shore Range ", float) = 1
        _LinearShoreGradient("Linear Shore Gradient ", float) = 1
        _DirectTranslucencyPow("DirectTranslucencyPow", float) = 1
        _EmissionStrength("EmissionStrength", float) = 1
        _ShadowFactor("ShadowFactor", float) = 1
        _HeightFactor("HeightFactor", float) = 1
        _CausticsIntensity("CausticsIntensity", float) = 1
        _CausticsSpeed("CausticsSpeed", float) = 1
        _CausticsGrow("CausticsGrow", float) = 1
        _CausticsOffset("CausticsOffset", float) = 1
    }
        SubShader
    {
        Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        LOD 100
        GrabPass{"_GrabTex"}
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
                float4 pos: SV_POSITION;
                float2 uv: TEXCOORD0;
                float2 nuv: TEXCOORD4;
                float3 worldPos: TEXCOORD1;
                float4 grabPos : TEXCOORD2;
                float4 scrPos : TEXCOORD3;
            };

            fixed4 _OceanColorShallow;
            fixed4 _OceanColorDeep;
            fixed4 _BubblesColor;
            fixed4 _BaseColor;
            fixed4 _Specular;
            fixed4 _DirectionalScatteringColor;
            float _Gloss;
            fixed _FresnelScale;
            sampler2D _Displace;
            sampler2D _Normal;
            sampler2D _Bubbles;
            float4 _Displace_ST;
            float4 _CausticsTex_ST;

            sampler2D _NoiseTex;
            sampler2D _CausticsTex;
            sampler2D _GrabTex;
            sampler2D _CameraDepthTexture;
            float4 _NoiseTex_ST;
            float _FoamSpeed;
            float _Threshold;
            float _FoamThreshold;
            float _FoamPower;
            float _FoamDisplacement;
            float _Alpha;
            float  _FracIntensity;
            float   _FracTransparency;
            float    _LinearShoreRange;
            float   _LinearShoreGradient;
            float   _DirectTranslucencyPow;
            float   _EmissionStrength;
            float   _ShadowFactor;
            float   _HeightFactor;
            float   _CausticsIntensity;
            float   _CausticsSpeed;
            float   _CausticsGrow;
            float   _CausticsOffset;

            float4 CalculateSSSColor(float3 lightDirection, float3 worldNormal, float3 viewDir, float waveHeight)
            {
                float lightStrength = sqrt(saturate(lightDirection.y));
                float SSSFactor = pow(saturate(dot(viewDir, lightDirection)) + saturate(dot(worldNormal, -lightDirection)), _DirectTranslucencyPow) * _ShadowFactor * lightStrength * _EmissionStrength;
                return _DirectionalScatteringColor * (SSSFactor + waveHeight * 0.6);
            }

            fixed4 GetCaustics(float2 uv, fixed factor, fixed offset)
            {
                float2 cuv = uv * _CausticsTex_ST.xy + _CausticsTex_ST.zw;
                cuv += _CausticsSpeed * _Time.y * factor;
                fixed s = 1.5 * offset;
                fixed r = tex2D(_CausticsTex, cuv + fixed2(+s, +s)).r * _CausticsIntensity;
                fixed g = tex2D(_CausticsTex, cuv + fixed2(+s, -s)).g * _CausticsIntensity;
                fixed b = tex2D(_CausticsTex, cuv + fixed2(-s, -s)).b * _CausticsIntensity;
                return fixed4(r, g, b, 1);
            }


            v2f vert(appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _Displace);
                float4 displcae = tex2Dlod(_Displace, float4(o.uv, 0, 0));
                v.vertex += float4(displcae.xyz, 0);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.grabPos = ComputeGrabScreenPos(o.pos);
                o.nuv = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.scrPos = ComputeScreenPos(o.pos);
                COMPUTE_EYEDEPTH(o.scrPos.z);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 normal = UnityObjectToWorldNormal(tex2D(_Normal, i.uv).rgb);
                fixed bubbles = tex2D(_Bubbles, i.uv).r;

                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 reflectDir = reflect(-viewDir, normal);

                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectDir, 0);
                half3 sky = DecodeHDR(rgbm, unity_SpecCube0_HDR);

                fixed fresnel = saturate(_FresnelScale + (1 - _FresnelScale) * pow(1 - dot(normal, viewDir), 4));
                fresnel = fresnel < 0.5 ? 0.05 : 0.4;

                half facing = saturate(dot(viewDir, normal));
                facing = facing < 0.5 ? 0 : 1;

                fixed3 oceanColor = _BaseColor+ lerp(_OceanColorShallow , _OceanColorDeep , facing);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
                //泡沫颜色
                fixed3 bubblesDiffuse = _BubblesColor.rbg   * saturate(dot(lightDir, normal));
                //海洋颜色
                fixed3 oceanDiffuse = oceanColor * _LightColor0.rgb;
                fixed diffuseControl = saturate(dot(lightDir, normal));
                oceanDiffuse *= diffuseControl < 0.7 ? 0.7 : 0.8;

                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(normal, halfDir)), _Gloss);

                fixed3 diffuse = lerp(oceanDiffuse, bubblesDiffuse, bubbles);


                float2 disp = tex2D(_NoiseTex, i.nuv + frac(_Time.y * _FoamSpeed * 0.05)).xy;
                disp = ((disp * 2) - 1) * 1;
                float4 dcol = tex2Dproj(_GrabTex, i.grabPos + float4(disp.xy, 0, 0));
                float4 grabcol = tex2Dproj(_GrabTex, i.grabPos);

                float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
                float selfZ = i.scrPos.w;
                float diff = min(pow((1 - saturate(sceneZ - i.scrPos.z)) / _Threshold, _FoamPower), 1.0);
                float depthDiff = saturate(pow(abs(sceneZ - selfZ), 1));
                dcol *= lerp(_OceanColorShallow, _OceanColorDeep, depthDiff);
                dcol = lerp(dcol, _BubblesColor, diff);


                disp = tex2D(_NoiseTex, i.nuv + sin(_Time.y * _FoamSpeed * 0.03)).xy;
                disp = ((disp * 2) - 1) * _FoamDisplacement;
                float noise = tex2D(_NoiseTex, i.nuv - float2(frac(_Time.y * _FoamSpeed * 0.04) - disp.x * 0.3, frac(_Time.y * _FoamSpeed * 0.03) - disp.y * 0.2)).x;
                float cutoff = _FoamThreshold * (1 - diff);
                noise = smoothstep(cutoff - 0.02, cutoff, noise);
                dcol = lerp(dcol, _BubblesColor, noise);

                float linearShore = smoothstep(
                    0.1, 0.65, saturate((1 - depthDiff + _LinearShoreRange) / _LinearShoreGradient));

                fixed4 fra = tex2D(
                    _GrabTex,
                    (i.scrPos.xy + _FracIntensity * (saturate(1 - depthDiff) + 0.5) * sin(2 * _Time.y)) / (i.scrPos.w
                        ));
                fra.a = 1- linearShore * _FracTransparency;

                fixed4 ssscol = CalculateSSSColor(lightDir, normal, viewDir, i.pos.y*0.01* _HeightFactor);

                fixed4 causticscol = min(GetCaustics(i.uv, 1, 1), GetCaustics(i.uv, _CausticsGrow, _CausticsOffset));
                causticscol.a *= (1- depthDiff)*0.5;

                fixed4 col = fixed4(ambient +diffuse*ssscol+ specular, 1);
                
                col = lerp(col, grabcol, 1-_Alpha);
                col *= fra;
                col.rgb += dcol.rgb;
                col.rgb = lerp(col.rgb, col.rgb+causticscol.rgb, causticscol.a);
                return fixed4(col);
            }
            ENDCG

        }
    }
}