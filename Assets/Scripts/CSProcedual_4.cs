using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]

public class CSProcedual_4: MonoBehaviour
{
    public ComputeShader shader;
    public string kernelName;
    public int threadGroupCount = 1;
    public Color bgColor;
    public Color color;
    public Vector2[] points = new Vector2[] {new Vector2(0.2f, 0.4f), new Vector2(0.8f, 0.3f), new Vector2(0.5f, 0.6f) };

    Vector2Int threadGroupSize;
    Vector2Int texResolution = new Vector2Int(512, 512);



    private int kernelHandle;
    private Renderer renderer;
    private RenderTexture rt;
    private ComputeBuffer buffer;

    public float radius = 5;

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

        buffer = new ComputeBuffer(points.Length, 2 * sizeof(float));
        buffer.SetData(points); 

        shader.SetTexture(kernelHandle, "Result", rt);
        shader.SetInts("texResolution", texResolution.x, texResolution.y);
        renderer.sharedMaterial.SetTexture("_MainTex", rt);

        Dispatch();
    }

    public void Dispatch()
    {
        shader.SetFloat("radius", radius);
        if (buffer!=null)
        {
            shader.SetBuffer(kernelHandle, "points", buffer);
            shader.SetInt("pointCount", points.Length);
        }
        shader.SetVector("color", color);
        shader.SetVector("bgColor", bgColor);
        shader.Dispatch(kernelHandle, threadGroupSize.x, threadGroupSize.y, 1);   
    }

    private void Update()
    {
        Dispatch();
    }

    private void OnDisable()
    {
        buffer.Dispose();
        rt.Release();
    }
}
