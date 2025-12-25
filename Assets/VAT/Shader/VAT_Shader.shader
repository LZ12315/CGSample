Shader "Custom/VAT_Shader" {
    Properties {
        _MainTex ("Main Texture", 2D) = "white" {}
        _VATTex ("VAT Texture", 2D) = "white" {}
        _AnimSpeed ("Animation Speed", Float) = 1.0
        _AnimStartFrame ("Start Frame", Float) = 0
        _BoundsMin ("Bounds Min", Vector) = (0,0,0,0)
        _BoundsMax ("Bounds Max", Vector) = (1,1,1,1)
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100

        // 关键：开启GPU Instancing
        CGPROGRAM
        #pragma surface surf Lambert vertex:vert addshadow
        #pragma multi_compile_instancing // 启用Instancing

        sampler2D _MainTex;
        sampler2D _VATTex;
        float _AnimSpeed;
        float _AnimStartFrame;
        float3 _BoundsMin;
        float3 _BoundsMax;

        struct Input {
            float2 uv_MainTex;
        };

        // 顶点着色器：应用顶点动画
        void vert (inout appdata_full v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            // 计算当前时间对应的动画帧
            float currentFrame = _AnimStartFrame + _Time.y * _AnimSpeed;
            // 将帧数归一化为UV坐标（V方向）
            float2 vatUV = float2(v.texcoord1.x, currentFrame);

            // 从VAT纹理中采样，得到归一化的顶点位置
            float4 vertexData = tex2Dlod(_VATTex, float4(vatUV, 0, 0));

            // 将归一化的位置还原到实际的世界坐标范围
            float3 worldPos = lerp(_BoundsMin, _BoundsMax, vertexData.rgb);

            // 应用动画顶点位置（从模型空间转换到世界空间）
            v.vertex.xyz = worldPos;
        }

        void surf (Input IN, inout SurfaceOutput o) {
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}