using UnityEngine;
using System.Collections;
using Cinemachine; // 必须引入

public class MagicController : MonoBehaviour
{
    [Header("=== 核心引用 ===")]
    [Tooltip("拖入挂载了 MagicPostProcess 脚本的物体 (例如 SceneManager)")]
    public MagicPostProcess postProcessManager;

    [Header("=== 寒冰技能 (Shift) ===")]
    public ParticleSystem iceParticles;

    [Header("=== 炎爆术基础设置 (F) ===")]
    public GameObject fireBlastPrefab;
    public Vector3 spawnOffset = new Vector3(0, 1.5f, 2.5f);
    public Vector3 effectScale = new Vector3(1, 1, 1);

    [Header("=== 连环爆破设置 ===")]
    [Range(1, 10)]
    public int burstCount = 5;
    public float burstInterval = 0.05f;
    public float positionJitter = 0.8f;
    public float scaleJitter = 0.2f;

    [Header("=== 物理参数 ===")]
    public float explosionRadius = 6.0f;
    public float explosionForce = 800.0f;
    public LayerMask interactLayer;

    void Start()
    {
        // 隐藏鼠标
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    void Update()
    {
        // 1. 寒冰路径
        HandleIceMagic();

        // 2. 炎爆术
        if (Input.GetKeyDown(KeyCode.F))
        {
            StartCoroutine(CastPyroblastRoutine());
        }

        // 4. 紧急呼出鼠标 (按左Alt)
        if (Input.GetKeyDown(KeyCode.LeftAlt))
        {
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }
    }

    void HandleIceMagic()
    {
        if (Input.GetKey(KeyCode.LeftShift))
        {
            if (!iceParticles.isPlaying) iceParticles.Play();
        }
        else
        {
            if (iceParticles.isPlaying) iceParticles.Stop();
        }
    }

    IEnumerator CastPyroblastRoutine()
    {
        // 【新增】触发强烈的视觉冲击 (色差+扭曲)
        if (postProcessManager != null)
        {
            postProcessManager.TriggerImpact();
        }

        for (int i = 0; i < burstCount; i++)
        {
            if (fireBlastPrefab != null)
            {
                // 计算位置
                Vector3 basePos = transform.TransformPoint(spawnOffset);
                Vector3 randomOffset = Random.insideUnitSphere * positionJitter;
                Vector3 finalPos = basePos + randomOffset;

                // 生成
                GameObject vfxInstance = Instantiate(fireBlastPrefab, finalPos, Quaternion.identity);

                // 缩放
                float randomScaleMultiplier = Random.Range(1.0f - scaleJitter, 1.0f + scaleJitter);
                vfxInstance.transform.localScale = effectScale * randomScaleMultiplier;

                // 物理震屏 (Cinemachine)
                var impulse = vfxInstance.GetComponent<CinemachineImpulseSource>();
                if (impulse != null)
                {
                    impulse.GenerateImpulse(Vector3.down * 0.5f);
                }

                // 销毁
                Destroy(vfxInstance, 3.0f);

                // 物理爆炸
                DoPhysicsExplosion(finalPos);
            }

            if (burstInterval > 0) yield return new WaitForSeconds(burstInterval);
        }
    }

    void DoPhysicsExplosion(Vector3 centerPoint)
    {
        Collider[] hits = Physics.OverlapSphere(centerPoint, explosionRadius, interactLayer);
        foreach (var hit in hits)
        {
            // 处理箱子击飞
            if (hit.TryGetComponent<Rigidbody>(out Rigidbody rb))
            {
                float randomUp = Random.Range(2.0f, 5.0f);
                rb.AddExplosionForce(explosionForce, centerPoint, explosionRadius, randomUp);
            }
        }
    }

    IEnumerator ShieldOpenAnim(GameObject shield)
    {
        float timer = 0f;
        float duration = 0.3f;
        Vector3 targetScale = Vector3.one * 2.5f;
        shield.transform.localScale = Vector3.zero;

        while (timer < duration && shield != null)
        {
            timer += Time.deltaTime;
            float t = timer / duration;
            float curve = t * t * (2.70158f * t - 1.70158f) + 1;
            shield.transform.localScale = Vector3.LerpUnclamped(Vector3.zero, targetScale, curve);
            yield return null;
        }
    }

    void OnDrawGizmosSelected()
    {
        Vector3 center = transform.TransformPoint(spawnOffset);
        Gizmos.color = new Color(1, 0, 0, 0.3f);
        Gizmos.DrawWireSphere(center, explosionRadius);
    }
}