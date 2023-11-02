// Alex Liu shader studies. 2022/1/8.

Shader "AlexLiu/RainWindow"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_Size("Block Size", float) = 1
		_T("Speed", float) = 1
		_Distortion("Distortion", float) = 1
		_Blur("Blur", Range(0,1)) = 0.5
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" }
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
					float3 normal:NORMAL;
				};

				struct v2f
				{
					float2 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
					float3 normal:NORMAL1;
					float4 worldPos:NORMAL2;
					float4 grabPos:NORMAL3;
				};

				sampler2D _MainTex;
				sampler2D _GrabTex;
				float4 _MainTex_ST;

				fixed4 _Color;

				float _Size;
				float _T;
				float _Distortion;
				fixed _Blur;

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					o.normal = v.normal;
					o.worldPos = mul(unity_ObjectToWorld, v.vertex);
					o.grabPos = ComputeGrabScreenPos(o.vertex);
					return o;
				}

				float rand(float s) {
					return frac(sin(s * 114.514) * 191.810);
				}

				float3 Rain(v2f i, float speed) {

					fixed4 rainCol = fixed4(0, 0, 0, 0);
					//loop the time to prevent floating point imprecision for large numbers
					float t = fmod(_Time.y * speed * _T, 3600);

					//aspect ratio for each bounding box of raindrop. x direction is squeezed
					float2 aspect = float2(1.2, 1);
					//increase the uv value to be pixelized later
					float2 uv = i.uv * _Size * aspect;
					//increase the uv.y by time to cancel out the upward motion of raindrops
					uv.y += t * .25 ;
					//assign a unique id for each bounding box
					float2 id = floor(uv);
					//generate a rand number based on the unique id
					float n = rand(id.x+id.y);

					//assign a randomized initial time for each raindrop. times 2pi since t is used in a sine function with a cycle of 2pi
					t += n * 6.28;
					//uv within each bounding box. pixelize.
					float2 gv = frac(uv) - .5; //-0.5, 0.5

					//main raindrop
					//randomize the x position for each raindrop
					float x = (n - 0.5) * .75;
					//add a wiggling effect to the x position
					x += (abs(x) + 0.2) * sin(3 * i.uv.y * 10) * pow(sin(i.uv.y * 10), 6) * 0.2;
					//create a looping motion for the raindrop to actually drop. goes down quickly and then up slowly (upward motion is canceled by the movement of uv)
					float y = -sin(t + sin(t + sin(t) * .5)) * 0.43;
					//tweak the shape of the raindrop to prevent perfect circles
					y -= (gv.x - x) * (gv.x - x);
					//use x and y to create the actualy position for the drop
					float2 dotPos = (gv - float2(x, y)) / aspect;
					//draw the drop using smoothstep. since the center of each box is with a uv of 0,0, length of dotPos represents the distance
					float dot = smoothstep(0.06, 0.04, length(dotPos));

					//small raindrop that follows behind each main raindrop
					//aspect ratio of the small raindrops
					float sdensity = 6;
					//adjust the size such that it becomes smaller at the top of each box and larger at the bottom
					float ssize = smoothstep(0.5, 0, gv.y) * 0.01;
					//use x and t*.25 (exactly the downward motion of uv) to make the dot stay still
					float2 sdotPos = (gv - float2(x, t * .25)) / aspect / aspect;
					//pixelize the y position
					sdotPos.y = (frac(sdotPos.y * sdensity) - 0.5) / sdensity;
					//draw the small raindrops. divide by the aspect ratios applied on these drops
					float sdot = smoothstep(ssize, ssize - 0.01, length(sdotPos / aspect / fixed2(1, sdensity)));
					//make the small drops only visible above the main drops in each box
					sdot *= smoothstep(0, 0.5, dotPos.y) * 5;

					//trail
					//make a gradient going toward the top
					float trail = smoothstep(0, 0.5, dotPos.y);
					//cut out the bottom in each box
					trail *= smoothstep(0.5, y, gv.y);
					sdot *= trail;
					//cut out the left and the right, leaving only the line in the center
					trail *= smoothstep(.05, .04, abs(dotPos.x));

					//multiply the dot and sdot values by a vector2 (dotPos, sdotPos) to make the x and y different, such that they can be used to displace
					//textures along both axes
					float2 disp = dot * dotPos + sdot * sdotPos;
					return float3(disp.xy, trail);
				}

				fixed4 frag(v2f i) : SV_Target
				{
					//create multiple layers of rain
					v2f raini = i;
					float3 rain = Rain(raini, 1);
					raini.uv = raini.uv * 1.23 + 8.54;
					rain += Rain(raini, 0.79);
					raini.uv = raini.uv * 1.35+2.34;
					rain += Rain(raini, 1.12);
					raini.uv = raini.uv * 1.57-8.54;
					rain += Rain(raini, 1.04);

					/*fwidth returns the difference between the current fragment and its neighbors.
					fwidth(i.uv) returns the uv diference. the further we are from the object, the greater the value. use this value to reduce the effect
					when viewing at a large distance.*/
					float fade = 1 - saturate(fwidth(i.uv) * 60);
					//apply the rain track and fade factors to the blur
					float blur = _Blur * 7 * (1 - rain.z * fade);
					blur *= .01;
					//calculate the projection uv for grab sampling
					float2 projuv = i.grabPos.xy / i.grabPos.w;
					//distort the uv by the raindrops
					projuv += rain.xy * _Distortion * fade;

					/*sample the grab tex within a circle with radius blur centered at i.uv
					add up the sampled color and average it. the greater blur is, the further we sample*/
					const float sampleCount = 16;
					//initial value of the angle, random between 0 and 2pi
					float a = rand(i.uv) * 6.28;
					float4 col = 0;
					for (int k = 0; k < sampleCount; k++) {
						//the displacement vector to reach a point we want to sample. use sinx+cosx to make the effect in a circle. multiply by blur to increase the radius.
						float2 disp = float2(sin(a), cos(a)) * blur;
						//random number for each sample
						float d = frac(sin((k + 1) * 712) * 4235);
						//make the effect smoother
						d = sqrt(d);
						//randomize the radius
						disp *= d;
						//sample the grab texture
						col += tex2D(_GrabTex, projuv + disp);
						//increae the angle
						a++;
					}
					//average the result
					col /= sampleCount;

					col *= _Color;
					return col;
				}
				ENDCG
			}
		}
}
