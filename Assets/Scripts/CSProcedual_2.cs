using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]

public class CSProcedual_2 : MonoBehaviour
{
    public ComputeShader shader;
    public string kernelName;
    public int threadGroupCount = 1;
    public Color bgColor;
    public Color color;

    Vector2Int threadGroupSize;
    Vector2Int texResolution = new Vector2Int(512, 512);
    private int kernelHandle;
    private Renderer renderer;
    private RenderTexture rt;
    private float timer;

    public float radius = 5;
    public float edgeWidth = 2;

    private void OnEnable()
    {
        if (!shader)
            return;

        rt = new RenderTexture(texResolution.x, texResolution.y, 1);
        rt.enableRandomWrite = true;
        rt.Create();
        renderer = GetComponent<Renderer>();

        InitializeData();
    }

    protected virtual void InitializeData()
    {
        uint x, y;
        kernelHandle = shader.FindKernel(kernelName);
        shader.GetKernelThreadGroupSizes(kernelHandle, out x,out y, out _);
        threadGroupSize.x = Mathf.CeilToInt(texResolution.x/(float)x);
        threadGroupSize.y = Mathf.CeilToInt(texResolution.y / (float)y);

        shader.SetTexture(kernelHandle, "Result", rt);
        shader.SetInts("texResolution", texResolution.x, texResolution.y);
        renderer.sharedMaterial.SetTexture("_MainTex", rt);

        Dispatch();
    }

    public void Dispatch()
    {
        shader.SetFloat("radius", radius);
        shader.SetFloat("edgeWidth", edgeWidth);
        shader.SetVector("color", color);
        shader.SetVector("bgColor", bgColor);
        shader.Dispatch(kernelHandle, threadGroupSize.x, threadGroupSize.y, 1);
    }

    private void Update()
    {
        Dispatch();
    }
}
