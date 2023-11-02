Shader "Hidden/IE_RGBSplit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DirX ("SplitX", float ) =1
        _DirY ("SplitY", float ) =1
    }
    SubShader
    {
        Cull Off

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
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float _DirX;
            float _DirY;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 colR = tex2D(_MainTex, i.uv+float2(_DirX, 0));
                fixed4 colB = tex2D(_MainTex, i.uv+float2(0, _DirY));

                fixed4 col = fixed4(colR.r, tex2D(_MainTex, i.uv).g, colB.b, 1);
            
                return col;
            }
            ENDCG
        }
    }
}
