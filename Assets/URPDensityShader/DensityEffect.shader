Shader "Muveso/Density"
{
    Properties
    {
    	[MaterialToggle] _isEnabled("Effect Enabled", Float) = 1
    	_defaultColor("Default Color", Color) = (.5, .8, 1, 1)
    	[PowerSlider(3.0)] _Tolerance("Tolerance", Range(0, 50)) = 1.15
    	[PowerSlider(3.0)] _Brightness("Brightness", Range(1, 3)) = 2
    	[PowerSlider(3.0)] _Saturation("Saturation", Range(1, 10)) = 2
    	[PowerSlider(3.0)] _Contrast("Contrast", Range(0.25, 10)) = 2
    }
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
			#pragma geometry geom
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // Transformations : CG -> HLSL Compatability
            #define UnityObjectToClipPos(x)     TransformObjectToHClip(x)
            #define UnityObjectToWorldDir(x)    TransformObjectToWorldDir(x)
            #define UnityObjectToWorldNormal(x) TransformObjectToWorldNormal(x)
            
            #define UnityWorldToViewPos(x)      TransformWorldToView(x)
            #define UnityWorldToObjectDir(x)    TransformWorldToObjectDir(x)
            #define UnityWorldSpaceViewDir(x)   _WorldSpaceCameraPos.xyz - x

            struct appdata
            {
                float4 vertex : POSITION; // Object Position
                float3 normal : NORMAL;   // Object Normal
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2g
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct g2f
			{
				float4 pos : SV_POSITION;
				half4 col : COLOR;
            	float3 normal : NORMAL;
				float3 worldSpacePos : TEXCOORD1;
			};
            
            /*****************************************************************
            *                             VARIABLES
            ******************************************************************/
            CBUFFER_START(UnityPerMaterial)

            float _isEnabled;
            half4 _defaultColor;
            float _Tolerance;
            float _Brightness;
            float _Contrast;
            float _Saturation;

            CBUFFER_END

            float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}

            half3 AdjustContrast(half3 color, half contrast)
            {
			    return saturate(lerp(half3(0.5, 0.5, 0.5), color, contrast));
			}

            [maxvertexcount(3)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> tristream)
			{
				g2f o;

				float3 AB = IN[1].worldPos.xyz - IN[0].worldPos.xyz;
				float3 AC = IN[2].worldPos.xyz - IN[0].worldPos.xyz;
				
				float3 normal = normalize(cross(AB, AC));

				float angle = acos(dot(AB, AC) / (length(AC) * length(AB)));
				float area = .5 * length(AC) * length(AB) * sin(angle);
				
				for (int i = 0; i < 3; i++)
				{
					o.pos = IN[i].vertex;
					o.normal = normal;
					float c = _Tolerance * (0.01 + sqrt(area));
					c = clamp(c, 0, 0.65);
					
					float3 hsv = float3(c, 1 * _Saturation, 1);
					float3 rgb = HSVToRGB(hsv);
					o.col = half4(rgb.r, rgb.g, rgb.b, 1);
					o.worldSpacePos = IN[i].worldPos;
					tristream.Append(o);
				}
			}
            
            /*****************************************************************
            *                             VERTEX
            ******************************************************************/
            v2g vert (appdata v)
            {
                v2g o;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.vertex = UnityObjectToClipPos(v.vertex);

				return o;
            }

            /*****************************************************************
            *                             FRAGMENT
            ******************************************************************/
            half4 frag (g2f input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float3 lightDir = normalize(_MainLightPosition.xyz);
				float lightDot = clamp(dot(input.normal, lightDir), -1, 1);
				lightDot = exp(-pow(2 * (1 - lightDot), 1.3));
            	
				half4 albedo = input.col;

            	float3 rgb = lightDot * _Brightness;

            	if(_isEnabled > 0)
					rgb *= AdjustContrast(albedo.rgb, _Contrast);
                else
					rgb *= _defaultColor;
            	
				return half4(rgb, 1);
            }
            ENDHLSL
        }
    }
}