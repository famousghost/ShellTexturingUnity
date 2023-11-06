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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Resolution;
            float _Frequency;
            float _LayerHeight;
            float _Radius;
            float _HeightStepSize;
            float4 _GrassColor;
            float _DisplacementStrength;

            float3 rotateY(float angle)
            {
                return float3(cos(angle) + sin(angle), 1.0f, -sin(angle) + cos(angle));
            }

            v2f vert(appdata v)
            {
                v2f o;
                v.vertex.xyz += v.normal * _LayerHeight;
                v.vertex.xyz += float3(0.0f, -1.0f, 0.0f) * _DisplacementStrength;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv * _Resolution;
                float2 fuv = frac(uv);
                float2 iuv = floor(uv);
                float result = noise(uv, _Frequency);
                float4 col = _GrassColor;
                if (result >= _LayerHeight)
                {
                    float addedValue = lerp(0.0f, 1.0f - _Radius, _HeightStepSize);
                    float val = lerp(1.0f, 0.0f, length(fuv - (0.5f + (random(iuv) * 0.5f))) + _Radius + addedValue);
                    result *= val;
                    col = _GrassColor * addedValue;
                }
                else
                {
                    discard;
                }

                if (result <= 0.0f)
                {
                    discard;
                }

                return col;
            }
        ENDCG
    }
}
}