Shader "Custom/DepthOfFieldShader"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _FocalDistance ("Focal Distance", Float) = 5.0
        _FocalRange ("Focal Range", Float) = 2.0
        _BlurStrength ("Blur Strength", Float) = 1.0
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // 应用程序到顶点着色器的输入结构
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0; // 初始UV坐标
            };

            // 顶点着色器到片段着色器的输出结构（关键修复）
            struct v2f
            {
                float4 pos : SV_POSITION; // 裁剪空间位置
                float2 uv : TEXCOORD0;     // 纹理坐标（修复：明确定义uv字段）
            };

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float _FocalDistance;
            float _FocalRange;
            float _BlurStrength;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv; // 正确传递UV坐标
                return o;
            }

            // 简单的高斯模糊函数
            half4 GaussianBlur(float2 uv, float2 pixelSize)
            {
                half4 color = half4(0,0,0,0);
                float weights[9] = {0.0625, 0.125, 0.0625,
                                    0.125, 0.25, 0.125,
                                    0.0625, 0.125, 0.0625};
                int index = 0;
                for (int x = -1; x <= 1; x++)
                {
                    for (int y = -1; y <= 1; y++)
                    {
                        float2 offset = float2(x, y) * pixelSize * _BlurStrength;
                        color += tex2D(_MainTex, uv + offset) * weights[index];
                        index++;
                    }
                }
                return color;
            }

            half4 frag (v2f i) : SV_Target
            {
                // 0. 处理平台相关的UV翻转（重要！）
                #if UNITY_UV_STARTS_AT_TOP
                    float2 uv = float2(i.uv.x, 1.0 - i.uv.y);
                #else
                    float2 uv = i.uv;
                #endif

                // 1. 计算像素大小用于模糊
                float2 pixelSize = float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);

                // 2. 采样原始清晰图像
                half4 sharpImage = tex2D(_MainTex, uv);

                // 3. 获取深度并转换为线性01深度（关键修正：保持01深度进行计算）
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
                depth = Linear01Depth(depth); // 此时depth是[0, 1]的范围，1为远裁剪面

                // 4. 将焦点距离也从世界空间转换为01线性深度（假设远裁剪面为1000单位，可根据项目调整）
                // 这一步是关键！它将脚本设置的世界空间焦点距离映射到深度纹理的[0,1]空间。
                float focalDistance01 = _FocalDistance / _ProjectionParams.z; // 通常 _ProjectionParams.z 是远裁剪面距离

                // 5. 计算模糊因子：基于深度与焦点的距离（使用平滑的smoothstep函数）
                float depthDiff = abs(depth - focalDistance01);
                // smoothstep(min, max, x): 当x<min时返回0，x>max时返回1，在中间则平滑过渡。
                float blurFactor = smoothstep(0, _FocalRange, depthDiff);

                // 6. 应用模糊（将模糊因子与强度相乘）
                half4 blurImage = GaussianBlur(uv, pixelSize);
                half4 finalColor = lerp(sharpImage, blurImage, blurFactor * _BlurStrength);

                return finalColor;
            }
            ENDCG
        }
    }
    FallBack Off
}