Shader "Custom/PixelateShader"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _PixelDensity ("Pixel Density", Range(1, 512)) = 64
        _ColorLevels ("Color Levels", Range(1, 256)) = 64
        _EdgeStrength ("Edge Strength", Range(0, 5)) = 1.0
        _Brightness ("Brightness", Range(0, 2)) = 1.0
        _Saturation ("Saturation", Range(0, 2)) = 1.0
        _Contrast ("Contrast", Range(0, 2)) = 1.0
    }
    
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            int _PixelDensity;
            int _ColorLevels;
            float _EdgeStrength;
            float _Brightness;
            float _Saturation;
            float _Contrast;
            
            // 颜色量化函数
            float3 QuantizeColor(float3 originalColor, int levels)
            {
                float quantizationFactor = 1.0 / levels;
                float3 quantizedColor;
                quantizedColor.r = floor(originalColor.r / quantizationFactor) * quantizationFactor;
                quantizedColor.g = floor(originalColor.g / quantizationFactor) * quantizationFactor;
                quantizedColor.b = floor(originalColor.b / quantizationFactor) * quantizationFactor;
                return quantizedColor;
            }
            
            // 边缘检测函数
            float EdgeDetection(float2 uv)
            {
                float2 pixelSize = 1.0 / _PixelDensity;
                
                // 采样周围像素
                float centerLum = Luminance(tex2D(_MainTex, uv).rgb);
                float leftLum = Luminance(tex2D(_MainTex, uv + float2(-pixelSize.x, 0)).rgb);
                float rightLum = Luminance(tex2D(_MainTex, uv + float2(pixelSize.x, 0)).rgb);
                float topLum = Luminance(tex2D(_MainTex, uv + float2(0, pixelSize.y)).rgb);
                float bottomLum = Luminance(tex2D(_MainTex, uv + float2(0, -pixelSize.y)).rgb);
                
                // 计算梯度
                float horizontal = abs(leftLum - centerLum) + abs(rightLum - centerLum);
                float vertical = abs(topLum - centerLum) + abs(bottomLum - centerLum);
                float edge = (horizontal + vertical) * _EdgeStrength;
                
                return saturate(edge);
            }
            
            // 亮度计算
            float Luminance(float3 color)
            {
                return dot(color, float3(0.2126, 0.7152, 0.0722));
            }
            
            fixed4 frag(v2f_img i) : SV_Target
            {
                // 1. 像素化UV坐标
                float2 pixelatedUV = floor(i.uv * _PixelDensity) / _PixelDensity;
                
                // 2. 采样纹理
                fixed4 col = tex2D(_MainTex, pixelatedUV);
                
                // 3. 颜色量化
                if (_ColorLevels < 256)
                {
                    col.rgb = QuantizeColor(col.rgb, _ColorLevels);
                }
                
                // 4. 边缘增强
                float edge = EdgeDetection(pixelatedUV);
                col.rgb += edge * float3(0.1, 0.1, 0.1);
                
                // 5. 色彩调整
                // 亮度调整
                col.rgb *= _Brightness;
                
                // 饱和度调整
                float luminance = Luminance(col.rgb);
                col.rgb = lerp(float3(luminance, luminance, luminance), col.rgb, _Saturation);
                
                // 对比度调整
                float3 avgColor = float3(0.5, 0.5, 0.5);
                col.rgb = lerp(avgColor, col.rgb, _Contrast);
                
                return col;
            }
            ENDCG
        }
    }
    FallBack Off
}