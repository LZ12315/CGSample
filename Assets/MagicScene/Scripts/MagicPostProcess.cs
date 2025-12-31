using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MagicPostProcess : MonoBehaviour
{
    [Header("配置")]
    public Volume globalVolume;

    [Header("滤镜颜色")]
    [ColorUsage(false, true)] public Color iceColor = new Color(0.6f, 0.8f, 1.0f);
    [ColorUsage(false, true)] public Color fireColor = new Color(1.0f, 0.7f, 0.4f);
    public float colorChangeSpeed = 5.0f;

    [Header("冲击波参数")]
    public float impactDuration = 0.5f;
    public float maxAberration = 1.0f;
    public float maxDistortion = -0.5f;

    private ColorAdjustments _colorAdj;
    private ChromaticAberration _chroma;
    private LensDistortion _distort;

    private Color _targetFilterColor = Color.white;

    void Start()
    {
        if (globalVolume == null) return;

        var profile = globalVolume.profile;
        profile.TryGet(out _colorAdj);
        profile.TryGet(out _chroma);
        profile.TryGet(out _distort);
    }

    void Update()
    {
        HandleFilterSwitch();
    }

    void HandleFilterSwitch()
    {
        if (_colorAdj == null) return;

        if (Input.GetKey(KeyCode.LeftShift))
        {
            _targetFilterColor = iceColor;
        }
        else if (Input.GetKey(KeyCode.F))
        {
            _targetFilterColor = fireColor;
        }
        else
        {
            _targetFilterColor = Color.white;
        }

        _colorAdj.colorFilter.value = Color.Lerp(_colorAdj.colorFilter.value, _targetFilterColor, Time.deltaTime * colorChangeSpeed);
    }

    public void TriggerImpact()
    {
        StopAllCoroutines();
        StartCoroutine(ImpactRoutine());
    }

    System.Collections.IEnumerator ImpactRoutine()
    {
        // 确保组件存在，防止报错
        if (_chroma == null || _distort == null) yield break;

        float timer = 0f;

        while (timer < impactDuration)
        {
            timer += Time.deltaTime;
            float progress = timer / impactDuration;

            float intensity = 1.0f - progress;
            intensity = intensity * intensity;

            _chroma.intensity.value = intensity * maxAberration;
            _distort.intensity.value = intensity * maxDistortion;

            yield return null;
        }

        _chroma.intensity.value = 0f;
        _distort.intensity.value = 0f;
    }
}