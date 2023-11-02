Shader "AlexLiu/Diamond"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Transparent"}
        Cull Off
        LOD 100

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
                float4 vertex : SV_POSITION;
                float4 grabPos : TEXCOORD1;
                float4 scrPos : TEXCOORD2;
                float4 worldPos : TEXCOORD3;
                float4 lightPos : TEXCOORD4;
                float4 worldView : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _GrabTex;
            fixed4 _Color;

            float4 _LightPos;

            float N11(float x) {
                return frac(sin(x * 2487.13) * 131.14);
            }

            v2f vert (appdata v)
            {
                v2f o;
                _LightPos = float4(-1, 1, -1,0);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.grabPos = ComputeGrabScreenPos(o.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.lightPos = normalize(mul(unity_ObjectToWorld, _LightPos));
                o.worldView = float4(normalize(_WorldSpaceCameraPos.xyz - o.worldPos.xyz), 0);
                o.scrPos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.scrPos.z);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldDx = ddx(i.worldPos);
                float4 worldDy = ddy(i.worldPos);
                float3 worldNormal = normalize(cross(worldDy, worldDx));

                float n = N11(ceil(worldNormal.x * 3 +worldNormal.y * 2 +worldNormal.z * 3));

                float4 disp = float4(n / 5, n / 5, 0, 0);
                fixed4 col = tex2Dproj(_GrabTex, i.grabPos+disp);
                col *= _Color;

                float fresnel = pow(1 - abs(dot(worldNormal, normalize(i.worldView))), 4);

                float ndl = max(0,dot(worldNormal, i.lightPos))*0.5+0.4;
                ndl *= (n/2+0.5);
                col = lerp(col, ndl, 0.7);
                
                col = pow(col, 0.8);
                fixed4 diff = col - fixed4(.5, .5, .5, .5);
                col += diff * 1;

                fixed l = Luminance(col);
                diff = col - fixed4(l, l, l, l);
                col += diff * 1;

                col += fresnel*0.7;
                return col;
            }
            ENDCG
        }
    }
}
