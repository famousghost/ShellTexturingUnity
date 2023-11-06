// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

Shader "McShaders/ShellTextureGenerator"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            float random(in float2 p)
            {
                return frac(sin(dot(p, float2(19.5423f, 33.32353))) * 7567.4534f);
            }

            float sampleSeamlessNoise(in float2 p, in float freq)
            {
                return random(float2(p.x % freq, p.y % freq));
            }

            float3 noise(in float2 p, in float freq)
            {
                float2 iuv = floor(p);
                float2 fuv = frac(p);
                float a = sampleSeamlessNoise(iuv, freq);
                float b = sampleSeamlessNoise(iuv + float2(1.0f, 0.0f), freq);
                float c = sampleSeamlessNoise(iuv + float2(0.0f, 1.0f), freq);
                float d = sampleSeamlessNoise(iuv + float2(1.0f, 1.0f), freq);

                float2 u = smoothstep(fuv, 0.0f, 1.0f);

                float ab = lerp(a, b, u.x);
                float cd = lerp(c, d, u.x);

                float abcd = lerp(ab, cd, u.y);

                return abcd;
            }

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float, _Resolution)
                UNITY_DEFINE_INSTANCED_PROP(float, _Frequency)
                UNITY_DEFINE_INSTANCED_PROP(float, _LayerHeight)
                UNITY_DEFINE_INSTANCED_PROP(float, _Radius)
                UNITY_DEFINE_INSTANCED_PROP(float, _HeightStepSize)
                UNITY_DEFINE_INSTANCED_PROP(float4, _GrassColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _DisplacementStrength)
                UNITY_DEFINE_INSTANCED_PROP(float3, _FieldSize)
                UNITY_DEFINE_INSTANCED_PROP(int, _ObjectType)
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                v.vertex.xyz *= UNITY_ACCESS_INSTANCED_PROP(Props, _FieldSize);
                v.vertex.xyz += v.normal * UNITY_ACCESS_INSTANCED_PROP(Props, _LayerHeight);
                const float2 uv = (v.uv * 2.0f - 1.0f) * UNITY_ACCESS_INSTANCED_PROP(Props, _Resolution);
                const float2 iuv = floor(uv);
                const float displacementStrength = UNITY_ACCESS_INSTANCED_PROP(Props, _DisplacementStrength);
                const int objectType = UNITY_ACCESS_INSTANCED_PROP(Props, _ObjectType);
                if (objectType == 1)
                {
                    const float3 dir = normalize(float3(0.5f, 0.5f, 0.0f) - float3(v.uv.x, v.uv.y, 0.0f));
                    v.vertex.xyz += dir * displacementStrength;
                }
                else if (objectType == 2)
                {
                    const float3 dir = float3(0.0f, 1.0f, 0.0f);
                    v.vertex.xyz += dir * displacementStrength;
                }

                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                const float2 uv = i.uv * UNITY_ACCESS_INSTANCED_PROP(Props, _Resolution);
                const float2 fuv = frac(uv);
                const float2 iuv = floor(uv);
                float result = noise(uv, UNITY_ACCESS_INSTANCED_PROP(Props, _Frequency));
                float4 col = UNITY_ACCESS_INSTANCED_PROP(Props, _GrassColor);
                if (result > UNITY_ACCESS_INSTANCED_PROP(Props, _LayerHeight))
                {
                    const float radius = UNITY_ACCESS_INSTANCED_PROP(Props, _Radius);
                    const float addedValue = lerp(0.0f, 1.0f - radius, UNITY_ACCESS_INSTANCED_PROP(Props, _HeightStepSize));
                    const float rnd = random(iuv);
                    result *= lerp(1.0f, 0.0f, length(fuv - float2(cos(rnd * 2.0f * UNITY_PI), sin(rnd * 2.0f * UNITY_PI))) + radius + addedValue);
                    col *= addedValue;
                }
                else
                {
                    discard;
                }

                if (result < 0.0f)
                {
                    discard;
                }

                return col;
            }
        ENDCG
    }
}
}