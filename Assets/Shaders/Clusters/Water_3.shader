// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/Water_3"
{
    Properties
    {
        _Wave1("Wave A (dir, steepness, wavelength)", vector) = (1,0,0.5,10)
        _Wave2("Wave A (dir, steepness, wavelength)", vector) = (1,0,0.5,10)
        _Wave3("Wave A (dir, steepness, wavelength)", vector) = (1,0,0.5,10)
        _Wave4("Wave A (dir, steepness, wavelength)", vector) = (1,0,0.5,10)
        _Wave5("Wave A (dir, steepness, wavelength)", vector) = (1,0,0.5,10)
        _Wave6("Wave A (dir, steepness, wavelength)", vector) = (1,0,0.5,10)
        _MainTex ("Texture", 2D) = "white" {}
        _Contrast("_Contrast", Range(0,1))=0.5
        _Saturation("_Saturation", Range(0,1))=0.5
        _FoamPower("_FoamPower", float)=5
        _FoamThreshold("_FoamThreshold", float)=.7
        _FoamThreshold2("_FoamThreshold2", float)=.7
        _FoamSpeed("_FoamSpeed", float)=.7
        _LinearShoreRange("_LinearShoreRange", float)=.7
        _LinearShoreGradient("_LinearShoreGradient", float)=.7
        _FracIntensity("_FracIntensity", float)=.7
        _FracTransparency("_FracTransparency", float)=.7
        _CausticsIntensity("CausticsIntensity", float) = 1
        _CausticsSpeed("CausticsSpeed", float) = 1
        _CausticsGrow("CausticsGrow", float) = 1
        _CausticsOffset("CausticsOffset", float) = 1
        _Gloss("_Gloss", float)=5
        _Density("_Density", float)=1
        _Speed("_Speed", float)=0.5
        _Speed1("_Speed1", float)=0.5
        _Speed2("_Speed2", float)=0.5
        _Speed3("_Speed3", float)=0.5
        _Speed4("_Speed4", float)=0.5
        _Speed5("_Speed5", float)=0.5
        _Speed6("_Speed5", float)=0.5
        _DiffusePower("_DiffusePower", float)=5
        _LightPos("Light Position", vector)=(1,1,1,0)
        _NoiseTex1 ("Noise Texture 1", 2D) = "white" {}
        _NoiseTex2 ("Noise Texture 2", 2D) = "white" {}
        _NoiseTex3 ("Noise Texture 3", 2D) = "white" {}
        _NoiseTex4 ("Noise Texture 4", 2D) = "white" {}
        [HDR]_LightCol("Light Color", Color) = (1,1,1,1)
        _Color1 ("Color 1", Color) = (1,1,1,1)
        _Color2 ("Color 2", Color) = (1,1,1,1)
        _Color3 ("Color 3", Color) = (1,1,1,1)
        _Color4 ("Color 4", Color) = (1,1,1,1)
        _Color5 ("Color 5", Color) = (1,1,1,1)
        _Color6 ("Color 6", Color) = (1,1,1,1)
        _Color7 ("Color 7", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        LOD 100
        Cull Off
        GrabPass{"_GrabTex"}
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 nuv1 : TEXCOORD1;
                float2 nuv2 : TEXCOORD2;
                float2 nuv3 : TEXCOORD3;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD4;
                float4 worldPos : TEXCOORD5;
                float4 worldView : TEXCOORD6;
                float4 grabPos : TEXCOORD7;
                float4 scrPos : TEXCOORD8;
                float4 objPos : TEXCOORD9;
            };

            sampler2D _GrabTex;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _LightPos;
            float4 _Wave1, _Wave2, _Wave3, _Wave4, _Wave5, _Wave6;
            float _LinearShoreRange, _LinearShoreGradient, _FracTransparency, _FracIntensity;
            float _Gloss, _DiffusePower;

            float _Speed, _Speed1, _Speed2, _Speed3, _Speed4, _Speed5, _Speed6;
            float _Density;

            sampler2D _CameraDepthTexture;
            sampler2D _NoiseTex1;
            float4 _NoiseTex1_ST;
            sampler2D _NoiseTex2;
            float4 _NoiseTex2_ST;
            sampler2D _NoiseTex3;
            sampler2D _NoiseTex4;
            float4 _NoiseTex3_ST;
            float4 _NoiseTex4_ST;

            fixed4 _Color1, _Color2, _Color3, _Color4, _Color5, _Color6,  _Color7;
            fixed4 _LightCol;

            float _FoamThreshold, _FoamPower, _FoamSpeed, _FoamThreshold2;
            float _Contrast, _Saturation;
            float   _CausticsIntensity;
            float   _CausticsSpeed;
            float   _CausticsGrow;
            float   _CausticsOffset;

            float3 Gerstner(float4 wave, float3 vertex, inout float3 tangent, inout float3 binormal, float speed) {
                float amp = wave.z;
                float length = wave.w;
                float2 d = normalize(wave.xy);
                float k = 2 * UNITY_PI / length* _Density;
                float spd = sqrt(9.8 / k);
                float f = k * (dot(d, vertex.xz) - spd * speed *_Speed * _Time.y);
                float s = amp / k;

                 tangent += float3(
                    - d.x * d.x * (amp * sin(f)),
                    d.x * (amp * cos(f)),
                    -d.x * d.y * (amp * sin(f))
                    );
                 binormal += float3(
                    -d.x * d.y * (amp * sin(f)),
                    d.y * (amp * cos(f)),
                    - d.y * d.y * (amp * sin(f))
                    );

                return float3(d.x * s * cos(f), s * sin(f), d.y * s * cos(f));
            }

            fixed4 GetCaustics(float2 uv, fixed factor, fixed offset)
            {
                float2 cuv = uv * _NoiseTex4_ST.xy + _NoiseTex4_ST.zw;
                cuv += _CausticsSpeed * _Time.y * factor;
                fixed s = 1.5 * offset;
                fixed r = tex2D(_NoiseTex4, cuv + fixed2(+s, +s)).r * _CausticsIntensity;
                fixed g = tex2D(_NoiseTex4, cuv + fixed2(+s, -s)).g * _CausticsIntensity;
                fixed b = tex2D(_NoiseTex4, cuv + fixed2(-s, -s)).b * _CausticsIntensity;
                return fixed4(r, g, b, 1);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.nuv1 = TRANSFORM_TEX(v.uv, _NoiseTex1);
                o.nuv2 = TRANSFORM_TEX(v.uv, _NoiseTex2);
                o.nuv3 = TRANSFORM_TEX(v.uv, _NoiseTex3);

                float4 nc1 = tex2Dlod(_NoiseTex1, float4(o.nuv1.x, o.nuv1.y, 0, 0));
                v.vertex.y += nc1 * 0.2;

                float3 tangent = float3(1, 0, 0);
                float3 binormal = float3(0, 0, 1);

                v.vertex.xyz += Gerstner(_Wave1, v.vertex, tangent, binormal,  _Speed1);
                v.vertex.xyz += Gerstner(_Wave2, v.vertex, tangent, binormal, _Speed2);
                v.vertex.xyz += Gerstner(_Wave3, v.vertex, tangent, binormal, _Speed3);
                v.vertex.xyz += Gerstner(_Wave4, v.vertex, tangent, binormal, _Speed4);
                v.vertex.xyz += Gerstner(_Wave5, v.vertex, tangent, binormal, _Speed5);
                v.vertex.xyz += Gerstner(_Wave6, v.vertex, tangent, binormal, _Speed6);

                float3 normal = normalize(cross(binormal, tangent));
                o.normal = normal;
                o.objPos = v.vertex;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldView = float4(UnityWorldSpaceViewDir(o.worldPos), 0.0);
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.grabPos = ComputeGrabScreenPos(o.vertex);
                o.scrPos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.scrPos.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv)*_Color1;
                fixed4 ncol2 = tex2D(_NoiseTex2, i.nuv2);

                float2 disp = tex2D(_NoiseTex3, i.nuv3 + frac(_Time.y * _FoamSpeed * 0.05)).xy;
                disp = ((disp * 2) - 1) * 0.03;
                float4 grabcol = tex2Dproj(_GrabTex, i.grabPos+float4(disp.xy, 0,0));
                col *= grabcol;

                float3 worldNormal = normalize(mul(unity_ObjectToWorld,normalize(i.normal)));
                float4 worldLight =normalize( mul(unity_ObjectToWorld, normalize(_LightPos)));
                float ndl = dot(worldNormal, worldLight);
                float diff = 0.3+0.7*max(ndl, 0.0);
                diff = smoothstep(0, 1, pow(diff, 1/ _DiffusePower));

               float3 worldView = normalize(_WorldSpaceCameraPos - i.worldPos);
               float h = normalize(worldView + worldLight);
               float ndh = max(dot(h, float4(worldNormal, 0.0)),0.0);
               float spec = max(pow(saturate(ndh-0.1), _Gloss),0.0);
               float spec2 = max(pow(saturate(ndh-0.5), _Gloss*3),0.0);


               col =(col* diff* _LightCol +spec* _Color3+ spec2 * _Color4);
               col = saturate(col);

               float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
               float selfZ = i.scrPos.w;
               float sdiff = min(pow((1 - saturate(sceneZ - i.scrPos.z)) / _FoamThreshold, _FoamPower), 1.0);
               float depthDiff = saturate(pow(abs(sceneZ - selfZ), 0.6));
               col *= lerp(_Color5, fixed4(1,1,1,1), depthDiff);
               col = lerp(col, _Color6, i.objPos.y);

               fixed4 bcol = _Color2;
               col = lerp(col, bcol, sdiff);

               float fnoise = tex2D(_NoiseTex1, i.nuv1 - float2(frac(_Time.y * _FoamSpeed * 0.04) - disp.x * 0.3, frac(_Time.y * _FoamSpeed * 0.03) - disp.y * 0.2)).x;
               float cutoff = _FoamThreshold2 * (1 - diff);
               fnoise = smoothstep(cutoff - 0.02, cutoff, fnoise);
               col = lerp(col, _Color7, fnoise);

               float linearShore = smoothstep(
                   0.1, 0.65, saturate((1 - depthDiff + _LinearShoreRange) / _LinearShoreGradient));

               fixed4 fra = tex2D(
                   _GrabTex,
                   (i.scrPos.xy + _FracIntensity * (saturate(1 - depthDiff) + 0.5) * sin(2 * _Time.y)) / (i.scrPos.w
                       ));
               fra.a = 1 - linearShore * _FracTransparency;
               col = lerp(col, fra, fra.a);
               fixed4 causticscol = min(GetCaustics(i.uv, 1, 1), GetCaustics(i.uv, _CausticsGrow, _CausticsOffset));
               causticscol.a *= (1 - depthDiff) * 0.5;
               col = lerp(col, col+ causticscol, causticscol.a);

               UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
               col *= attenuation;
               //pp
               float4 cdiff = col - float4(.5, .5, .5, .5);
               col += cdiff * (_Contrast * 2 - 1);

               float l = Luminance(col);
               float4 sadiff = col - float4(l,l,l,1);
               col += sadiff * (_Saturation * 2 - 1);

                return saturate(col);
            }
            ENDCG
        }
    }
}
