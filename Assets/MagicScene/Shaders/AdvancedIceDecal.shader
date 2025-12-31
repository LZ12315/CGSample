Shader "Custom/Magic/AdvancedIceDecal"
{
    Properties
    {
        [Header(Base)]
        [MainColor] _BaseColor("Ice Color", Color) = (0.5, 0.8, 1, 0.2) // 默认透明度调低
        [HDR] _EdgeColor("Melt Edge Color", Color) = (0, 2, 5, 1) // 融化边缘的高光
        _EdgeWidth("Melt Edge Width", Range(0, 0.2)) = 0.05 // 边缘宽度

        [Header(Textures)]
        _NoiseTex("Noise Texture (R)", 2D) = "white" {} 
        _NormalTex("Normal Map", 2D) = "bump" {} 
        _NormalScale("Normal Strength", Range(0, 2)) = 1.0

        [Header(Settings)]
        _CutoffOffset("Dissolve Progress", Range(-1, 1)) = 0.0 
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
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR; 
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half4 _EdgeColor;
                float4 _NoiseTex_ST;
                float _EdgeWidth;
                float _NormalScale;
                float _CutoffOffset;
            CBUFFER_END

            sampler2D _NoiseTex;
            sampler2D _NormalTex;

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _NoiseTex);
                output.color = input.color;

                // 计算世界坐标位置
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);

                // 计算世界空间法线
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = normalInput.normalWS;

                // 获取视角方向
                output.viewDirWS = GetWorldSpaceViewDir(positionWS);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // --- 【修正核心 1：强制去除方块边缘】 ---
                // 计算当前像素距离 UV 中心的距离 (0~1)
                float2 uvOffset = abs(input.uv - 0.5) * 2.0; 
                // 如果任意一边接近边界 (超过 0.95)，直接丢弃像素，物理消除方块边框
                if (max(uvOffset.x, uvOffset.y) > 0.95) discard;

                // --- 采样贴图 ---
                half noise = tex2D(_NoiseTex, input.uv).r;
                half3 normalMap = UnpackNormal(tex2D(_NormalTex, input.uv));
                
                // --- 【修正核心 2：圆形遮罩】 ---
                // 制作一个柔和的圆形遮罩，越靠外越透明
                float mask = saturate(1.0 - length(uvOffset)); 
                // 让噪点图在边缘处强制变黑，保证消融从边缘开始
                noise *= mask; 
                
                // --- 消融逻辑 ---
                // 使用粒子 Alpha (1->0) 控制消融进度
                float progress = 1.0 - input.color.a; 
                float dissolveVal = noise - progress;
                
                // 剔除像素
                clip(dissolveVal);

                // --- 计算亮边 ---
                float isEdge = step(dissolveVal, _EdgeWidth);

                // --- 菲涅尔效应 (冰的透镜感) ---
                float3 viewDir = normalize(input.viewDirWS);
                float3 worldNormal = normalize(input.normalWS + normalMap * _NormalScale); 
                float fresnel = pow(1.0 - saturate(dot(worldNormal, viewDir)), 4.0); // 指数调高让光感更锐利

                // --- 最终合成 ---
                half4 finalColor = _BaseColor;
                
                // 叠加菲涅尔高光 (让冰面看起来更亮)
                finalColor.rgb += fresnel * 1.0;
                
                // 叠加消融边缘光
                finalColor.rgb = lerp(finalColor.rgb, _EdgeColor.rgb, isEdge); 
                
                // 修正透明度：让边缘更透明，中心保留一点底色
                finalColor.a = _BaseColor.a * mask; 

                return finalColor;
            }
            ENDHLSL
        }
    }
}