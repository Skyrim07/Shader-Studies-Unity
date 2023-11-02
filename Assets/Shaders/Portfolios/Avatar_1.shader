//First line of code in 2022!!!

Shader "AlexLiu/Avatar_1"
{
    Properties
    {
        _NoiseMap1("NoiseMap 1", 2D) = "white" {}
        _NoiseMap2("NoiseMap 2", 2D) = "white" {}
        _NoiseMag1("NoiseMag 1", float) = 5
        _NoiseMag2("NoiseMag 2", float) = 5
        _NoiseSpeed1("NoiseSpeed 1", float) = 1
        _NoiseSpeed2("NoiseSpeed 2", float) = 1
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _Gloss("Gloss", float) = 5
        _Gloss2("Gloss2", float) = 5
        _SpecularRes("Specular Resolution", float) = 5
        _SpecularStrength("Specular Strength", Range(0,1)) = 1
        _SpecularStrength2("Specular Strength2", Range(0,1)) = 1
        [HDR]_WireColor("Wire Color", Color) = (0,0,0,1)
        _FillColor("Fill Color", Color) = (1,1,1,1)
        _WireWidth("Wire Width", Range(0.1,2)) = 0.2
        _DotSize("Dot Size", float) = 1
        [HDR]_DotColor("Dot Color", Color) = (1,1,1,1)
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimStrength("Rim Strength", Range(0,1)) = 1
        _Transparency("Transparency", Range(0,1)) = 0.2
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Stencil
        {
            Ref 5
            Comp Always
            Pass Replace
        }

        GrabPass{"_GrabTex"}
        Pass
        {
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

         struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2g
            {
                float2 uv: TEXCOORD0;
                float4 vertex: SV_POSITION;
                float4 grabPos: NORMAL1;
                float3 normal: NORMAL;
                float4 worldPos: NORMAL2;
            };

            struct g2f
            {
                float2 uv: TEXCOORD0;
                float4 vertex: SV_POSITION;
                float3 dist: NORMAL1;
                float3 vertDist: NORMAL2;
                float3 normal: NORMAL3;
                float4 grabPos: NORMAL4;
                float4 worldPos: NORMAL5;
            };

            v2g vert(appdata v)
            {
                v2g o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            [maxvertexcount(3)]
            void geom(triangle v2g IN[3], inout TriangleStream < g2f > triStream)
            {
                float2 p0 = IN[0].vertex.xy / IN[0].vertex.w;
                float2 p1 = IN[1].vertex.xy / IN[1].vertex.w;
                float2 p2 = IN[2].vertex.xy / IN[2].vertex.w;

                float2 v0 = p2 - p1;
                float2 v1 = p2 - p0;
                float2 v2 = p1 - p0;
                float area = abs(v1.x * v2.y - v1.y * v2.x);

                g2f OUT;
                OUT.vertex = IN[0].vertex;
                OUT.uv = IN[0].uv;
                OUT.dist = float3(area / length(v0), 0, 0);
                OUT.vertDist = length(IN[0].vertex - IN[1].vertex);
                OUT.normal = IN[0].normal;
                OUT.grabPos = IN[0].grabPos;
                OUT.worldPos = IN[0].worldPos;
                triStream.Append(OUT);

                OUT.vertex = IN[1].vertex;
                OUT.uv = IN[1].uv;
                OUT.dist = float3(0, area / length(v1), 0);
                OUT.normal = IN[1].normal;
                OUT.vertDist = length(IN[1].vertex - IN[2].vertex);
                OUT.grabPos = IN[1].grabPos;
                OUT.worldPos = IN[1].worldPos;
                triStream.Append(OUT);

                OUT.vertex = IN[2].vertex;
                OUT.uv = IN[2].uv;
                OUT.dist = float3(0, 0, area / length(v2));
                OUT.normal = IN[2].normal;
                OUT.vertDist = length(IN[2].vertex - IN[0].vertex);
                OUT.grabPos = IN[2].grabPos;
                OUT.worldPos = IN[2].worldPos;
                triStream.Append(OUT);
            }

            fixed4 _WireColor;
            fixed4 _FillColor;
            fixed4 _DotColor;
            fixed4 _SpecularColor;
            fixed4 _RimColor;
            float _WireWidth;
            float _DotSize;
            float _NoiseMag1;
            float _NoiseMag2;
            float _NoiseSpeed1;
            float _NoiseSpeed2;
            float _Gloss;
            float _Gloss2;
            float _SpecularStrength;
            float _SpecularStrength2;
            float _SpecularRes;
            float _RimStrength;
            float _Transparency;
            sampler2D _NoiseMap1;
            sampler2D _NoiseMap2;
            sampler2D _GrabTex;


            fixed4 frag(g2f i) : SV_Target
            {
                float4 wNormal = mul(unity_ObjectToWorld, i.normal);
                fixed4 nwNormal = normalize(wNormal);
                float3 wView = UnityWorldSpaceViewDir(i.worldPos);

                float2 disp = tex2D(_NoiseMap1, i.uv + frac(_Time.y * _NoiseSpeed1 * 0.1)).xy;
                disp = ((disp * 2) - 1) * _NoiseMag1;
                fixed4 col = tex2Dproj(_GrabTex, i.grabPos + float4(disp.xy, 0, 0));
                col *= _FillColor;

                float d = 0.0;
                d = min(i.dist.x, min(i.dist.y, i.dist.z));
                disp = tex2D(_NoiseMap2, i.uv + sin(_Time.y * _NoiseSpeed2 * 0.1)).xy;


                col += d < _WireWidth * 0.003 / i.vertex.w ? _WireColor * 0.2 * disp.x * _NoiseMag2 : fixed4(0, 0, 0, 0);

                d = min(i.vertDist.x, min(i.vertDist.y, i.vertDist.z));
                float dFactor = _DotSize * 0.12 * abs(sin(_Time.y * 0.5));
                float dAmount = (1-smoothstep(0, dFactor, d) )* 0.6;
                col *= d < dFactor ? saturate(_DotColor * (dFactor+max(abs(sin(_Time.y)), 0.01)*0.1)* 2) : fixed4(1, 1, 1, 1);


                float ndl = saturate(dot(wNormal, normalize(_WorldSpaceLightPos0)));
                fixed3 lightCol = ndl * _LightColor0.rgb;
                col.rgb += lightCol*0.2;

                float rawSpec = max(dot(normalize(wView + _WorldSpaceLightPos0), nwNormal), 0);
                fixed4 specularCol = _LightColor0 * ceil(pow(rawSpec, _Gloss)* _SpecularRes)/ _SpecularRes;
                col += smoothstep(0,0.4,specularCol)* _SpecularColor* _SpecularStrength;
                specularCol = ceil(pow(rawSpec, _Gloss2)* _SpecularRes)/ _SpecularRes;
                col += smoothstep(0, 0.4, specularCol) * _SpecularColor * _SpecularStrength2;

                float fresnel = pow(1 - abs(dot(nwNormal, normalize(wView))), 1 / _RimStrength);
                col = lerp(col, _RimColor, fresnel);

                d = min(i.dist.x, min(i.dist.y, i.dist.z));
                col += d < _WireWidth * 0.003 / i.vertex.w ? _WireColor* dAmount* disp.x * _NoiseMag2 : fixed4(0,0,0,0);

                return col;
            }
            ENDCG
        }
    }
}
