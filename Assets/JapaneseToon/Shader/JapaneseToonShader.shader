Shader "Custom/JapaneseToonShader"
{
    Properties
    {
        // Base Color and Texture
        _MainTex ("Main Texture (RGB)", 2D) = "white" {}
        _Color ("Main Color", Color) = (1,1,1,1)

        // Outline Parameters
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth ("Outline Width", Range(0, 0.1)) = 0.02

        // Shading Parameters
        _ColorSteps ("Color Steps", Range(1, 5)) = 3
        _DiffuseSmooth ("Diffuse Smoothness", Range(0, 1)) = 0.2

        // Specular Parameters
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _SpecularScale ("Specular Intensity", Range(0, 2)) = 0.5
        _SpecularSmooth ("Specular Smoothness", Range(0.1, 10)) = 5
        _SpecularThreshold ("Specular Threshold", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        // Pass 1: Outline Pass (Geometry-based)
        Pass
        {
            Name "OUTLINE"
            Tags { "LightMode" = "Always" }
            Cull Front
            ZWrite On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float _OutlineWidth;
            float4 _OutlineColor;

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata v) {
                v2f o;
                float4 viewPos = mul(UNITY_MATRIX_MV, v.vertex);
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                viewNormal = normalize(viewNormal);
                viewPos.xyz += viewNormal * _OutlineWidth;
                o.pos = mul(UNITY_MATRIX_P, viewPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                return _OutlineColor;
            }
            ENDCG
        }

        // Pass 2: Main Shading Pass (Includes Shading and Specular)
        Pass
        {
            Name "MAIN"
            Tags { "LightMode" = "ForwardBase" }
            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _ColorSteps;
            float _DiffuseSmooth;
            float4 _SpecularColor;
            float _SpecularScale;
            float _SpecularSmooth;
            float _SpecularThreshold;

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert (appdata v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                // 1. Sample base texture and color
                fixed4 baseColor = tex2D(_MainTex, i.uv) * _Color;

                // 2. Calculate lighting information
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + worldViewDir);

                // 3. Core Toon Shading: Discrete diffuse
                half diffuse = dot(worldNormal, worldLightDir);
                diffuse = diffuse * 0.5 + 0.5;
                half toonDiffuse = floor(diffuse * _ColorSteps) / _ColorSteps;
                diffuse = lerp(diffuse, toonDiffuse, _DiffuseSmooth);

                // 4. Stylized Specular
                half specular = dot(worldNormal, halfDir);
                specular = smoothstep(_SpecularThreshold, _SpecularThreshold + 0.1, specular);
                specular = pow(specular, _SpecularSmooth) * _SpecularScale;

                // 5. Composite final color
                fixed3 finalColor = baseColor.rgb * _LightColor0.rgb * diffuse;
                finalColor += _SpecularColor.rgb * specular;

                return fixed4(finalColor, baseColor.a);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}