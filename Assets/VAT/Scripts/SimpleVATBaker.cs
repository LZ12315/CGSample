using UnityEngine;
using System.Collections.Generic;

public class SimpleVATBaker : MonoBehaviour
{
    public GameObject targetActor; // 拖入你的动画角色模型
    public AnimationClip animationClip; // 拖入你想烘焙的动画片段
    public int bakeFPS = 30; // 烘焙的帧率，越低文件越小，动画越卡顿
    public string textureSavePath = "VAT_Result"; // 保存的文件名

    [ContextMenu("Bake VAT")]
    void BakeVAT()
    {
        if (targetActor == null || animationClip == null)
        {
            Debug.LogError("Target Actor or Animation Clip is missing!");
            return;
        }

        SkinnedMeshRenderer skinnedMesh = targetActor.GetComponentInChildren<SkinnedMeshRenderer>();
        if (skinnedMesh == null)
        {
            Debug.LogError("No SkinnedMeshRenderer found!");
            return;
        }

        Mesh staticMesh = new Mesh();
        int vertexCount = skinnedMesh.sharedMesh.vertexCount;
        int totalFrames = Mathf.FloorToInt(animationClip.length * bakeFPS);

        // 创建一张纹理：宽度=顶点数，高度=总帧数
        Texture2D vatTexture = new Texture2D(vertexCount, totalFrames, TextureFormat.RGBAHalf, false);
        vatTexture.name = textureSavePath;

        // 计算动画中顶点位置的最大和最小范围，用于后续归一化
        Vector3 minBounds = Vector3.positiveInfinity;
        Vector3 maxBounds = Vector3.negativeInfinity;

        List<Vector3[]> allFramesVertices = new List<Vector3[]>();

        // 第一遍采样：获取所有顶点的位置范围
        for (int frame = 0; frame < totalFrames; frame++)
        {
            float time = (float)frame / bakeFPS;
            animationClip.SampleAnimation(targetActor, time);
            skinnedMesh.BakeMesh(staticMesh);

            Vector3[] vertices = staticMesh.vertices;
            allFramesVertices.Add(vertices);

            foreach (Vector3 vert in vertices)
            {
                minBounds = Vector3.Min(minBounds, vert);
                maxBounds = Vector3.Max(maxBounds, vert);
            }
        }

        // 第二遍采样：将顶点位置归一化并存入纹理
        for (int frame = 0; frame < totalFrames; frame++)
        {
            Vector3[] vertices = allFramesVertices[frame];
            for (int vertIndex = 0; vertIndex < vertexCount; vertIndex++)
            {
                // 将顶点位置从世界坐标转换到模型本地坐标
                Vector3 localVert = targetActor.transform.InverseTransformPoint(vertices[vertIndex]);
                // 归一化到0-1范围
                Vector3 normalizedVert = Vector3.zero;
                normalizedVert.x = Mathf.InverseLerp(minBounds.x, maxBounds.x, localVert.x);
                normalizedVert.y = Mathf.InverseLerp(minBounds.y, maxBounds.y, localVert.y);
                normalizedVert.z = Mathf.InverseLerp(minBounds.z, maxBounds.z, localVert.z);

                Color color = new Color(normalizedVert.x, normalizedVert.y, normalizedVert.z, 1.0f);
                vatTexture.SetPixel(vertIndex, frame, color);
            }
        }

        vatTexture.Apply();

        // 保存纹理为PNG文件
        byte[] bytes = vatTexture.EncodeToPNG();
        System.IO.File.WriteAllBytes(Application.dataPath + "/" + textureSavePath + ".png", bytes);
        Debug.Log($"VAT Baking Complete! Saved to: {Application.dataPath}/{textureSavePath}.png");
        Debug.Log($"Vertex Count: {vertexCount}, Total Frames: {totalFrames}");
        Debug.Log($"Position Range - Min: {minBounds}, Max: {maxBounds}");

        // 同时保存静态Mesh和范围数据，便于后续使用
        UnityEditor.AssetDatabase.CreateAsset(staticMesh, $"Assets/{textureSavePath}_Mesh.asset");
        UnityEditor.AssetDatabase.Refresh();
    }
}