Shader "AlexLiu/Pixelate_1"
{
Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
		_TileTex("Tile Texture", 2D) = "white" {}
		_TileSize("Tile Size", Range(0, 100)) = 10
		_DisplayModeID("Display Mode", Range(0, 4)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha

        LOD 100

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

	       sampler2D _MainTex;
			float4 _MainTex_ST;
            sampler2D _TileTex;
			uniform int _TileSize;
			uniform int _DisplayModeID;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float2 TileSum = _ScreenParams / _TileSize;

				float2 uv_Mosaic = ceil(i.uv * TileSum) / TileSum;
				fixed4 col_Mosaic = tex2D(_MainTex, uv_Mosaic);

				float2 uv_Tile = frac(i.uv * TileSum);
				fixed4 col_Tile = tex2D(_TileTex, uv_Tile);
				
				fixed4 col = col_Mosaic;

				switch (_DisplayModeID) 
				{
					case 1:
							col *= col_Tile.r;
							break;
					case 2:
							col *= col_Tile.g;
							break;
					case 3:
							col *= col_Tile.b;
							break;
					case 4:
							col *= col_Tile.a;
							break;
				}

		                return col;
            }
            ENDCG
        }
    }

}