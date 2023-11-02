Shader "examples/week 11/interior"
{
    Properties {
        _colorA ("color a", Color) = (1, 1, 1, 1)
        _colorB ("color b", Color) = (1, 1, 1, 1)

        _stencilRef ("stencil reference", Int) = 1
    }

    SubShader
    {
        Tags { "Queue" = "Geometry" }
        Cull Front

        Stencil {
            Ref [_stencilRef]
            Comp Equal
        }

        // nothing new below
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #define TAU 6.28318530718

            float3 _colorA;
            float3 _colorB;

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (Interpolators i) : SV_Target
            {
                float2 uv = i.uv;
                float angle = (atan2(uv.y, uv.x) / TAU) + 0.5;
                angle = abs(sin((angle - (_Time.y * 0.5)) * 3)); 
                float3 color = 0;
                color = lerp(_colorA, _colorB, angle);

                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}
