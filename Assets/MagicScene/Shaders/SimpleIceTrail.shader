Shader "Custom/Magic/SimpleIceTrail"
{
    Properties
    {
        [MainColor] _BaseColor("Color (HDR)", Color) = (0, 0.5, 1, 1) // 颜色，支持HDR发光
        _MainTex("Noise Texture", 2D) = "white" {} // 噪点图
        _NoiseScale("Noise Tiling", Float) = 1.0 // 噪点缩放，防止拉伸
        _CutoffOffset("Cutoff Offset", Range(-1, 1)) = 0.0 // 微调消融范围
    }

    SubShader
    {
        Tags 
        { 
            "RenderType" = "Transparent" 
            "Queue" = "Transparent" 
            "RenderPipeline" = "UniversalPipeline" 
        }

        LOD 100
        
        // 混合模式：标准半透明
        Blend SrcAlpha OneMinusSrcAlpha
        // 关闭深度写入
        ZWrite Off
        // 关闭剔除（双面显示，防止某些角度看不到）
        Cull Off

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // 引入 URP 核心库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR; // 必须获取 Trail Renderer 传进来的顶点色
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _MainTex_ST;
                float _NoiseScale;
                float _CutoffOffset;
            CBUFFER_END

            sampler2D _MainTex;

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                
                // 简单的 UV 处理，乘上缩放系数
                output.uv = TRANSFORM_TEX(input.uv, _MainTex) * _NoiseScale;
                
                output.color = input.color;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // 1. 采样噪点图 (只取 R 通道)
                half noiseValue = tex2D(_MainTex, input.uv).r;

                // 2. 获取 Trail 的生命周期 (Alpha)
                // 刚生成时 Alpha=1，快消失时 Alpha=0
                half lifeAlpha = input.color.a;

                // 3. 核心消融逻辑 (代码版 Step)
                // 如果 生命值 + 偏移量 < 噪点值，则丢弃该像素
                // 效果：生命值越低，越多的像素被丢弃（看起来像碎裂）
                clip(lifeAlpha - noiseValue + _CutoffOffset);

                // 4. 输出颜色
                half4 finalColor = _BaseColor;
                
                // 保持颜色亮度，但 Alpha 设为 1 (因为 clip 已经负责了镂空，不需要半透明混合了)
                finalColor.a = 1; 

                return finalColor;
            }
            ENDHLSL
        }
    }
}