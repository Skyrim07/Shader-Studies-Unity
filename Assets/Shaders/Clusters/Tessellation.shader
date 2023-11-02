Shader "Unlit/Tessellation"
{
    Properties
    {
     _MainTex("Texture", 2D) = "white" {}
     [IntRange]_Density("Density", Range(1, 5)) = 3
     _WireColor("Wire Color", Color) = (0,0,0,1)
     _FillColor("Fill Color", Color) = (1,1,1,1)
     _WireWidth("Wire Width", Range(0,2)) = 0.2
    }
    SubShader
    {
         Tags { "RenderType" = "Opaque" }
         LOD 100

         Pass
         {
              CGPROGRAM
              #pragma vertex tessvert
              #pragma fragment frag
              #pragma geometry geom
              #pragma hull hs
              #pragma domain ds
              #pragma target 4.6

              #include "UnityCG.cginc"
              #include "Lighting.cginc"

              struct appdata
              {
                  float4 vertex : POSITION;
                  float4 tangent : TANGENT;
                  float3 normal : NORMAL;
                  float2 texcoord : TEXCOORD0;
              };

              struct v2g
              {
                   float2 texcoord:TEXCOORD0;
                   float4 vertex : SV_POSITION;
                   float4 tangent : TANGENT;
                   float3 normal : NORMAL;
              };

              struct g2f
              {
                  float2 uv : TEXCOORD0;
                  float4 vertex : SV_POSITION;
                  float4 tangent : TANGENT;
                  float3 normal : NORMAL;
                  float3 dist : TEXCOORD1;
              };

              struct InternalTessInterp_appdata {
                    float4 vertex : INTERNALTESSPOS;
                    float4 tangent : TANGENT;
                    float3 normal : NORMAL;
                    float2 texcoord : TEXCOORD0;
              };

              sampler2D _MainTex;
              float4 _MainTex_ST;
              float _Density,_WireWidth;

              fixed4 _WireColor, _FillColor;

              InternalTessInterp_appdata tessvert(appdata v) {
                    InternalTessInterp_appdata o;
                    o.vertex = v.vertex;
                    o.tangent = v.tangent;
                    o.normal = v.normal;
                    o.texcoord = v.texcoord;
                    return o;
              }


              v2g vert(appdata v)
              {
                   v2g o;
                   o.vertex = UnityObjectToClipPos(v.vertex);
                   o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                   return o;
              }


              UnityTessellationFactors hsconst(InputPatch<InternalTessInterp_appdata,3> v) {
                    UnityTessellationFactors o;
                    float4 tf;
                    tf = float4(_Density, _Density, _Density, _Density);
                    o.edge[0] = tf.x;
                    o.edge[1] = tf.y;
                    o.edge[2] = tf.z;
                    o.inside = tf.w;
                    return o;
              }

              [UNITY_domain("tri")]
              [UNITY_partitioning("fractional_odd")]
              [UNITY_outputtopology("triangle_cw")]
              [UNITY_patchconstantfunc("hsconst")]
              [UNITY_outputcontrolpoints(3)]
              InternalTessInterp_appdata hs(InputPatch<InternalTessInterp_appdata,3> v, uint id : SV_OutputControlPointID) {
                  return v[id];
              }

              [UNITY_domain("tri")]
              v2g ds(UnityTessellationFactors tessFactors, const OutputPatch<InternalTessInterp_appdata,3> vi, float3 bary : SV_DomainLocation) {
                    appdata v;

                    v.vertex = vi[0].vertex * bary.x + vi[1].vertex * bary.y + vi[2].vertex * bary.z;
                    v.tangent = vi[0].tangent * bary.x + vi[1].tangent * bary.y + vi[2].tangent * bary.z;
                    v.normal = vi[0].normal * bary.x + vi[1].normal * bary.y + vi[2].normal * bary.z;
                    v.texcoord = vi[0].texcoord * bary.x + vi[1].texcoord * bary.y + vi[2].texcoord * bary.z;

                    v2g o = vert(v);
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
                  OUT.normal = IN[0].normal;
                  OUT.tangent = IN[0].tangent;
                  OUT.uv = IN[0].texcoord;
                  OUT.dist = float3(area / length(v0), 0, 0);
                  triStream.Append(OUT);

                  OUT.vertex = IN[1].vertex;
                  OUT.normal = IN[1].normal;
                  OUT.tangent = IN[1].tangent;
                  OUT.uv = IN[1].texcoord;
                  OUT.dist = float3(0, area / length(v1), 0);
                  triStream.Append(OUT);

                  OUT.vertex = IN[2].vertex;
                  OUT.normal = IN[2].normal;
                  OUT.tangent = IN[2].tangent;
                  OUT.uv = IN[2].texcoord;
                  OUT.dist = float3(0, 0, area / length(v2));
                  triStream.Append(OUT);
              }

              fixed4 frag(g2f i) : SV_Target
              {
                    fixed4 col_Wire;
                    float d = min(i.dist.x, min(i.dist.y, i.dist.z));
                    col_Wire.rgb = d < _WireWidth * 0.003 / i.vertex.w ? _WireColor : _FillColor;
                    //col_Wire.rgb =(_WireWidth * 0.003 / i.vertex.w > i.dist.z || _WireWidth * 0.003 / i.vertex.w > i.dist.x)? _WireColor : _FillColor;
                    col_Wire.a = 1;
                    return col_Wire;
              }
              ENDCG
         }
    }
}