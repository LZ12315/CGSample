using UnityEngine;

[ExecuteInEditMode] // 允许在编辑模式下预览
[RequireComponent(typeof(Camera))] // 确保脚本挂在摄像机上
public class DepthOfFieldController : MonoBehaviour
{
    [Header("景深参数")]
    [Tooltip("焦点距离（世界单位）")]
    public float focalDistance = 10.0f;
    [Tooltip("焦点区域的清晰范围")]
    public float focalRange = 2.0f;
    [Tooltip("模糊强度")]
    public float blurStrength = 1.0f;

    [Header("Shader引用")]
    public Shader dofShader; // 这里引用的是Shader资产
    private Material dofMaterial; // 材质在运行时动态创建

    void OnEnable()
    {
        // 关键步骤1：启用相机深度纹理渲染
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;

        // 关键步骤2：检查Shader并创建材质
        if (dofShader != null && dofShader.isSupported)
        {
            dofMaterial = new Material(dofShader);
            dofMaterial.hideFlags = HideFlags.DontSave; // 避免场景保存时包含临时材质
        }
        else
        {
            Debug.LogError("景深Shader未分配或不支持当前平台！");
        }
    }

    void OnDisable()
    {
        // 清理动态创建的材质
        if (dofMaterial != null)
            DestroyImmediate(dofMaterial);
    }

    // 这是内置管线后处理的核心函数
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (dofMaterial != null)
        {
            // 将脚本参数传递给Shader
            dofMaterial.SetFloat("_FocalDistance", focalDistance);
            dofMaterial.SetFloat("_FocalRange", focalRange);
            dofMaterial.SetFloat("_BlurStrength", blurStrength);

            // 使用Shader进行处理
            Graphics.Blit(source, destination, dofMaterial);
        }
        else
        {
            // 如果材质未创建成功，直接原样输出
            Graphics.Blit(source, destination);
        }
    }
}