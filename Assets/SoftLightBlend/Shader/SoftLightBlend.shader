Shader "Custom/SoftLightBlend"
{
    Properties
    {
        _MainTex ("Screen Texture", 2D) = "white" {}
        _BlendTex ("Blend Texture", 2D) = "white" {}
        _BlendIntensity ("Blend Intensity", Range(0, 1)) = 0.5
    }
    SubShader
    {
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

            sampler2D _MainTex; // 屏幕原始图像
            sampler2D _BlendTex; // 混合纹理
            float _BlendIntensity; // 混合强度

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // 柔光混合函数（逐通道处理）
            float3 SoftLightBlend(float3 base, float3 blend)
            {
                float3 result;
                for (int i = 0; i < 3; i++) // 分别处理R、G、B通道
                {
                    if (blend[i] <= 0.5)
                    {
                        // 对于较暗的混合色：使用更柔和的变暗公式
                        result[i] = base[i] - (1.0 - 2.0 * blend[i]) * base[i] * (1.0 - base[i]);
                    }
                    else
                    {
                        // 对于较亮的混合色：使用更柔和的变亮公式
                        result[i] = base[i] + (2.0 * blend[i] - 1.0) * (sqrt(base[i]) - base[i]);
                    }
                }
                // 确保颜色值在有效范围内
                return saturate(result);
            }

            float4 frag (v2f i) : SV_Target
            {
                // 1. 采样屏幕原始颜色（基础层）
                float4 baseColor = tex2D(_MainTex, i.uv);
                // 2. 采样混合纹理颜色（混合层）。使用相同的UV，因此混合纹理应覆盖全屏。
                float4 blendColor = tex2D(_BlendTex, i.uv);

                // 3. 应用柔光混合算法
                float3 blendedRGB = SoftLightBlend(baseColor.rgb, blendColor.rgb);

                // 4. 根据混合强度，在原始图像和混合结果之间进行插值
                float3 finalColor = lerp(baseColor.rgb, blendedRGB, _BlendIntensity);

                return float4(finalColor, baseColor.a);
            }
            ENDCG
        }
    }
    FallBack Off
}