Shader "Unlit/VolumetricLight_1"
{
    Properties
    {
        BaseColor("Base Color",color) = (1,1,1,1)
        Intensity("Intensity",float) = 1
        extrudeDistance("Extrusion", float) = 5.0
        _Pow("Pow",float) = 1
        _NearSmoothDistance("_NearSmoothDistance",float) = 1
        _LightPos("LightPos",Vector) = (1,1,0,0)
    }
        SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
        }
        ZWrite Off
        pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "UnityCG.cginc"

            struct v2f
            {
                float4 pos:SV_POSITION;
                float4 objPos:TEXCOORD0;
            };

            float extrudeDistance;
            float _Pow;
            float4 BaseColor;
            float Intensity;
            float _NearSmoothDistance;
            float3 _LightPos;

            v2f vert(appdata_base v) : POSITION
            {
                v2f o;
                float3 toLight = mul(_LightPos, unity_ObjectToWorld);
                float extrude = dot(toLight, v.normal) < 0.0 ? 1.0 : 0.0;
               v.vertex.xyz += v.normal * 0.05;
                v.vertex.xyz -= toLight * (extrude * extrudeDistance);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.objPos = v.vertex;
                return o;
            }


            float4 frag(v2f i) :COLOR
            {
                float nearSmooth = pow(smoothstep(0, _NearSmoothDistance, i.objPos), _Pow);
                float att = (1 / (1 + length(i.objPos)));
                float4 c = pow(min(1, att * Intensity), _Pow);
                c = lerp(0,1,c);
                c.rgb = BaseColor.rgb;
                return c;
            }
            ENDCG
        }
    }
        FallBack Off
}
