using UnityEngine;

[ExecuteInEditMode] // 允许在编辑模式下预览效果
[RequireComponent(typeof(Camera))]
public class SoftLightBlend : MonoBehaviour
{
    [Header("混合纹理设置")]
    [Tooltip("用于与屏幕画面进行柔光混合的纹理")]
    public Texture2D blendTexture; // 用户需在Inspector中赋值一张纹理图片
    [Tooltip("混合强度：0为原图，1为完全柔光效果")]
    [Range(0.0f, 1.0f)]
    public float blendIntensity = 0.5f;

    [Header("Shader关联")]
    public Shader softLightShader;
    private Material softLightMaterial;

    void OnEnable()
    {
        // 检查Shader并创建材质
        if (softLightShader != null && softLightShader.isSupported)
        {
            softLightMaterial = new Material(softLightShader);
            softLightMaterial.hideFlags = HideFlags.DontSave;
        }
        else
        {
            Debug.LogError("柔光混合Shader未分配或不支持当前平台！");
        }
    }

    void OnDisable()
    {
        // 清理动态创建的材质
        if (softLightMaterial != null)
            DestroyImmediate(softLightMaterial);
    }

    // 内置渲染管线的核心后处理函数
    void OnRenderImage(RenderTexture source, RenderTexture dest)
    {
        if (softLightMaterial != null && blendTexture != null)
        {
            // 将参数传递给Shader
            softLightMaterial.SetTexture("_BlendTex", blendTexture);
            softLightMaterial.SetFloat("_BlendIntensity", blendIntensity);

            // 使用Shader处理屏幕图像
            Graphics.Blit(source, dest, softLightMaterial);
        }
        else
        {
            // 如果条件不满足，直接原样输出
            Graphics.Blit(source, dest);
        }
    }
}