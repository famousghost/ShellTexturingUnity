// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

Shader "McShaders/ShellTextureGenerator"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile_fwdbase
            #include "AutoLight.cginc"

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                float3 bitangent : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float4 _ShadowCoord : TEXCOORD3;
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

            float3 calculateNormal(in float2 p, in float freq)
            {
                float left = noise(p - float2(0.001f, 0.0f), freq);
                float right = noise(p + float2(0.001f, 0.0f), freq);
                float top = noise(p + float2(0.0f, 0.001f), freq);
                float bottom = noise(p - float2(0.0f, 0.001f), freq);

                return normalize(float3(right - left, top - bottom, 1.0f));
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
                UNITY_DEFINE_INSTANCED_PROP(float, _SpecularStrength)
                UNITY_DEFINE_INSTANCED_PROP(float3, _VelocityDirection)
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                v.vertex.xyz *= UNITY_ACCESS_INSTANCED_PROP(Props, _FieldSize);
                v.normal.xyz *= UNITY_ACCESS_INSTANCED_PROP(Props, _FieldSize);
                v.vertex.xyz += v.normal * UNITY_ACCESS_INSTANCED_PROP(Props, _LayerHeight);
                const float2 uv = (v.uv * 2.0f - 1.0f) * UNITY_ACCESS_INSTANCED_PROP(Props, _Resolution);
                const float2 iuv = floor(uv);
                const float displacementStrength = UNITY_ACCESS_INSTANCED_PROP(Props, _DisplacementStrength);
                const int objectType = UNITY_ACCESS_INSTANCED_PROP(Props, _ObjectType);
                if (objectType == 1)
                {
                    const float3 dir = normalize(float3(0.5f, 0.5f, 0.0f) - float3(v.uv.x, v.uv.y, 0.0f)) + UNITY_ACCESS_INSTANCED_PROP(Props, _VelocityDirection).xzy;
                    v.vertex.xyz += dir * displacementStrength;
                }
                else if (objectType == 2)
                {
                    const float3 dir = float3(0.0f, 1.0f, 0.0f) + UNITY_ACCESS_INSTANCED_PROP(Props, _VelocityDirection);
                    v.vertex.xyz += dir * displacementStrength;
                }

                o.vertex = UnityObjectToClipPos(v.vertex);

                float3 worldNormal = mul((float3x3)unity_ObjectToWorld, v.normal);
                float3 worldTangent = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz);

                float3 binormal = cross(v.normal, v.tangent.xyz) * v.tangent.w;
                float3 worldBinormal = mul((float3x3)unity_ObjectToWorld, binormal);

                o.tangent = normalize(worldTangent);
                o.normal = normalize(worldNormal);
                o.bitangent = normalize(worldBinormal);

                o.uv = v.uv;
                o.worldPos = mul(v.vertex, UNITY_MATRIX_M);

                o._ShadowCoord = ComputeScreenPos(o.vertex);

                return o;
            }

            float diffuseLight(float3 normal, float3 lightDir)
            {
                return saturate(dot(lightDir, normal) * 0.5f + 0.5f);
            }

            float specularLight(float3 normal, float3 cameraDir, float3 lightDir, float power)
            {
                float3 H = normalize(lightDir - cameraDir);
                return pow(saturate(dot(H, normal)), power);
            }

            float3 normalBlend(in float3 normalA, in float3 normalB)
            {
                return normalize(float3(normalA.r + normalB.r, normalA.g + normalB.g, normalA.b * normalB.b));
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
                    const float3 normal = calculateNormal(iuv, UNITY_ACCESS_INSTANCED_PROP(Props, _Frequency));
                    const float3x3 TBN = float3x3(i.tangent, i.bitangent, i.normal);
                    const float3 normalWS = normalize(mul(transpose(TBN), normal));
                    const float diffColor = diffuseLight(normalWS, normalize(_WorldSpaceLightPos0.xyz));
                    const float specColor = specularLight(normalWS, normalize(i.worldPos.xyz - _WorldSpaceCameraPos.xyz), normalize(_WorldSpaceLightPos0.xyz), UNITY_ACCESS_INSTANCED_PROP(Props, _SpecularStrength));
                    const float angle = rnd * 2.0f * UNITY_PI;
                    result *= lerp(1.0f, 0.0f, length(fuv - float2(cos(angle), sin(angle))) + radius + addedValue);
                    col *= addedValue * (diffColor + specColor);
                    col = lerp(col * 0.2f, col, smoothstep(0.001f, 0.05f, SHADOW_ATTENUATION(i)));
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
    Pass
    {
        Tags {"LightMode" = "ShadowCaster"}
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_instancing
        #include "AutoLight.cginc"

        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
            float2 uv : TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
            float3 normal : NORMAL;
            float3 tangent : TANGENT;
            float3 bitangent : TEXCOORD1;
            float3 worldPos : TEXCOORD2;
            float3x3 TBN : TEXCOORD3;
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
            UNITY_DEFINE_INSTANCED_PROP(float, _SpecularStrength)
            UNITY_DEFINE_INSTANCED_PROP(float3, _VelocityDirection)
        UNITY_INSTANCING_BUFFER_END(Props)

        v2f vert(appdata v)
        {
            v2f o;
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_TRANSFER_INSTANCE_ID(v, o);
            v.vertex.xyz *= UNITY_ACCESS_INSTANCED_PROP(Props, _FieldSize);
            v.normal.xyz *= UNITY_ACCESS_INSTANCED_PROP(Props, _FieldSize);
            v.vertex.xyz += v.normal * UNITY_ACCESS_INSTANCED_PROP(Props, _LayerHeight);
            const float2 uv = (v.uv * 2.0f - 1.0f) * UNITY_ACCESS_INSTANCED_PROP(Props, _Resolution);
            const float2 iuv = floor(uv);
            const float displacementStrength = UNITY_ACCESS_INSTANCED_PROP(Props, _DisplacementStrength);
            const int objectType = UNITY_ACCESS_INSTANCED_PROP(Props, _ObjectType);
            if (objectType == 1)
            {
                const float3 dir = normalize(float3(0.5f, 0.5f, 0.0f) - float3(v.uv.x, v.uv.y, 0.0f)) + UNITY_ACCESS_INSTANCED_PROP(Props, _VelocityDirection).xzy;
                v.vertex.xyz += dir * displacementStrength;
            }
            else if (objectType == 2)
            {
                const float3 dir = float3(0.0f, 1.0f, 0.0f) + UNITY_ACCESS_INSTANCED_PROP(Props, _VelocityDirection);
                v.vertex.xyz += dir * displacementStrength;
            }

            o.vertex = UnityObjectToClipPos(v.vertex);

            o.uv = v.uv;

            return o;
        }

        float diffuseLight(float3 normal, float3 lightDir)
        {
            return saturate(dot(lightDir, normal) * 0.5f + 0.5f);
        }

        float specularLight(float3 normal, float3 cameraDir, float3 lightDir, float power)
        {
            float3 H = normalize(lightDir - cameraDir);
            return pow(saturate(dot(H, normal)), power);
        }

        float3 normalBlend(in float3 normalA, in float3 normalB)
        {
            return normalize(float3(normalA.r + normalB.r, normalA.g + normalB.g, normalA.b * normalB.b));
        }

        float4 frag(v2f i) : SV_Target
        {
            UNITY_SETUP_INSTANCE_ID(i);
            const float2 uv = i.uv * UNITY_ACCESS_INSTANCED_PROP(Props, _Resolution);
            const float2 fuv = frac(uv);
            const float2 iuv = floor(uv);
            float result = noise(uv, UNITY_ACCESS_INSTANCED_PROP(Props, _Frequency));

            if (result > UNITY_ACCESS_INSTANCED_PROP(Props, _LayerHeight))
            {
                const float radius = UNITY_ACCESS_INSTANCED_PROP(Props, _Radius);
                const float addedValue = lerp(0.0f, 1.0f - radius, UNITY_ACCESS_INSTANCED_PROP(Props, _HeightStepSize));
                const float rnd = random(iuv);
                const float angle = rnd * 2.0f * UNITY_PI;
                result *= lerp(1.0f, 0.0f, length(fuv - float2(cos(angle), sin(angle))) + radius + addedValue);
            }
            else
            {
                discard;
            }

            if (result < 0.0f)
            {
                discard;
            }

            return float4(0.0f, 0.0f, 0.0f, 1.0f);
        }
    ENDCG
    }
}
}