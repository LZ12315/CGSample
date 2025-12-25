Shader "Custom/FrostedGlassShader" {
    Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {} // 用于扰动的噪声纹理
        _Distortion ("Distortion Intensity", Range(0, 0.1)) = 0.02 // 扰动强度
        _BlurSize ("Blur Size", Range(0, 0.02)) = 0.005 // 模糊采样距离
        _GlassColor ("Glass Tint", Color) = (1, 1, 1, 0.5) // 玻璃色调和透明度
    }

    SubShader {
        // 重要：设置渲染队列为透明，确保在其他不透明物体之后渲染
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        
        // 使用GrabPass抓取屏幕内容。标签内命名"_GrabTexture"是常见做法[2,6](@ref)
        GrabPass { "_GrabTexture" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 grabPos : TEXCOORD1; // 用于访问抓取的屏幕纹理
            };

            sampler2D _GrabTexture;
            sampler2D _NoiseTex;
            float _Distortion;
            float _BlurSize;
            float4 _GlassColor;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                // 计算抓屏坐标，这是正确采样_GrabTexture的关键[3](@ref)
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                // 1. 采样噪声纹理，获取扰动方向
                fixed4 noise = tex2D(_NoiseTex, i.uv);
                // 将噪声值从[0,1]范围映射到[-1,1]，产生各向扰动
                float2 noiseOffset = (noise.rg * 2 - 1) * _Distortion;

                // 2. 应用简单的3x3模糊卷积核[1,7](@ref)
                fixed4 blurredColor = fixed4(0, 0, 0, 0);
                float blurWeights[9] = {0.0625, 0.125, 0.0625,
                                        0.125,  0.25,  0.125,
                                        0.0625, 0.125, 0.0625}; // 近似高斯权重

                int index = 0;
                for (int x = -1; x <= 1; x++) {
                    for (int y = -1; y <= 1; y++) {
                        // 计算每个采样点的偏移（结合噪声扰动和模糊采样）
                        float2 offset = noiseOffset + float2(x, y) * _BlurSize;
                        // 计算采样坐标，注意透视除法（i.grabPos.w）
                        float2 sampleUV = (i.grabPos.xy + offset) / i.grabPos.w;
                        // 采样并累加
                        blurredColor += tex2D(_GrabTexture, sampleUV) * blurWeights[index];
                        index++;
                    }
                }

                // 3. 将模糊后的颜色与玻璃色调和透明度混合
                blurredColor.rgb *= _GlassColor.rgb;
                blurredColor.a = _GlassColor.a;

                return blurredColor;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}