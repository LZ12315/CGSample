using UnityEngine;

[ExecuteInEditMode]
public class PixelateEffect_Enhanced : MonoBehaviour
{
    [Header("像素化控制")]
    [Range(1, 512)]
    public int pixelDensity = 64;

    [Header("颜色量化")]
    [Range(1, 256)]
    public int colorLevels = 64;

    [Header("边缘增强")]
    [Range(0, 5)]
    public float edgeStrength = 1.0f;

    [Header("色彩调整")]
    [Range(0, 2)]
    public float brightness = 1.0f;
    [Range(0, 2)]
    public float saturation = 1.0f;
    [Range(0, 2)]
    public float contrast = 1.0f;

    public Material pixelateMaterial;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (pixelateMaterial != null)
        {
            // 传递所有参数到Shader
            pixelateMaterial.SetInt("_PixelDensity", pixelDensity);
            pixelateMaterial.SetInt("_ColorLevels", colorLevels);
            pixelateMaterial.SetFloat("_EdgeStrength", edgeStrength);
            pixelateMaterial.SetFloat("_Brightness", brightness);
            pixelateMaterial.SetFloat("_Saturation", saturation);
            pixelateMaterial.SetFloat("_Contrast", contrast);

            Graphics.Blit(source, destination, pixelateMaterial);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

    // 实时更新参数（在编辑器模式下）
    void OnValidate()
    {
        if (pixelateMaterial != null)
        {
            pixelateMaterial.SetInt("_PixelDensity", pixelDensity);
            pixelateMaterial.SetInt("_ColorLevels", colorLevels);
            pixelateMaterial.SetFloat("_EdgeStrength", edgeStrength);
            pixelateMaterial.SetFloat("_Brightness", brightness);
            pixelateMaterial.SetFloat("_Saturation", saturation);
            pixelateMaterial.SetFloat("_Contrast", contrast);
        }
    }
}