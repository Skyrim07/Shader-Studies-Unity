Shader "Hidden/IE_HSV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Hue ("Hue", Range(0,1)) = 1
        _Saturation("Saturation", Range(0,1)) = 1
        _Value ("Value", Range(0,2)) = 1
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

            float3 hsv2rgb(float3 c){
				float3 rgb = clamp( abs(fmod(c.x*6.0+float3(0.0,4.0,2.0),6)-3.0)-1.0, 0, 1);
				rgb = rgb*rgb*(3.0-2.0*rgb);
				return c.z * lerp( float3(1,1,1), rgb, c.y);
			}
			float3 rgb2hsv(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
				float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

				float d = q.x - min(q.w, q.y);
				float e = 1.0e-10;
				return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            fixed _Hue;
            fixed _Saturation;
            fixed _Value;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

				fixed3 hsv = rgb2hsv(col.rgb);
				hsv.x+=_Hue;
				col.rgb=hsv2rgb(hsv);

                fixed luminance = Luminance(col);
                col = lerp(col, fixed4(luminance, luminance, luminance, 1), 1-_Saturation);

				col= fixed4(col.rgb*_Value, col.a);

                return col;
            }
            ENDCG
        }
    }
}
