Shader "examples/week 11/window"
{
    Properties {
        _stencilRef ("stencil reference", Int) = 1
    }

    SubShader
    {
        Tags {"Queue"="Geometry-1"}
        ZWrite Off
        ColorMask 0

        Stencil {
            Ref [_stencilRef]
            Comp Always
            Pass Replace
        }

        // nothing new below
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct MeshData
            {
                float4 vertex : POSITION;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float4 frag (Interpolators i) : SV_Target
            {
                return 0;
            }
            ENDCG
        }
    }
}
