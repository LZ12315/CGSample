using UnityEngine;
using System.Collections.Generic;

public class SimpleCrowdController : MonoBehaviour
{
    public Mesh instanceMesh; // 使用烘焙得到的静态Mesh
    public Material VATMaterial; // 使用上一步创建的VAT材质
    public int instanceCount = 100;
    public Vector3 areaSize = new Vector3(10, 0, 10);

    private List<Matrix4x4[]> matrixBatches = new List<Matrix4x4[]>(); // 存储批次的变换矩阵
    private Vector4[] startFrames; // 每个实例的随机起始帧

    void Start()
    {
        InitializeCrowd();
    }

    void InitializeCrowd()
    {
        startFrames = new Vector4[instanceCount];
        List<Matrix4x4> matrices = new List<Matrix4x4>();

        for (int i = 0; i < instanceCount; i++)
        {
            // 随机位置
            Vector3 position = new Vector3(
                Random.Range(-areaSize.x / 2, areaSize.x / 2),
                0,
                Random.Range(-areaSize.z / 2, areaSize.z / 2)
            );
            Quaternion rotation = Quaternion.identity;
            Vector3 scale = Vector3.one;

            matrices.Add(Matrix4x4.TRS(position, rotation, scale));
            startFrames[i] = new Vector4(Random.Range(0, 1000), 0, 0, 0); // 随机起始帧

            // 每500个实例为一批，避免超出GPU单次处理上限
            if (matrices.Count >= 500 || i == instanceCount - 1)
            {
                matrixBatches.Add(matrices.ToArray());
                matrices.Clear();
            }
        }
    }

    void Update()
    {
        // 为材质传递起始帧数组参数，实现动画错开
        //VATMaterial.SetVectorArray("_AnimStartFrame", startFrames);

        // 分批渲染
        for (int i = 0; i < matrixBatches.Count; i++)
        {
            Graphics.DrawMeshInstanced(instanceMesh, 0, VATMaterial, matrixBatches[i], matrixBatches[i].Length);
        }
    }
}