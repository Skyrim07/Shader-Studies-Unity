using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]

public sealed class AcatarFx_2 : MonoBehaviour
{
    [Range(0.1f, 1f)]
    public float resolution = 0.5f;
    ComputeBuffer pointBuffer;

    [SerializeField] SkinnedMeshRenderer mr;
    [SerializeField] Material cubeMat;
    [SerializeField] ComputeShader cubeCS;

    Camera cam;

    int vertCount;
    private void OnEnable()
    {
        cam = Camera.main;
        PopulateBuffer();
    }
    public Vector3[] PixelateMesh(Mesh mesh)
    {
       // Vector3[] p_Verts = new Vector3[Mathf.CeilToInt(mesh.vertexCount * resolution)];
        Vector3[] p_Verts = mesh.vertices;
        for (int i = 0; i < mesh.vertexCount; i++)
        {

        }
        vertCount = p_Verts.Length;
        return p_Verts;
    }
    public void PopulateBuffer()
    {
        Vector3[] p_Verts = PixelateMesh(mr.sharedMesh);
        if (p_Verts.Length == 0)
            return;

        pointBuffer = new ComputeBuffer(p_Verts.Length, sizeof(float) * 3);
        pointBuffer.SetData(p_Verts);

        cubeMat.SetBuffer("pointBuffer", pointBuffer);
        cubeMat.SetFloat("pointCount", vertCount);
        //cubeCS.SetBuffer(cubeCS.FindKernel("CSMain"), "pointBuffer", pointBuffer);
        GenerateMesh(p_Verts);
    }

    public void GenerateMesh(Vector3[] verts)
    {
        Matrix4x4 mvp = cam.projectionMatrix * cam.worldToCameraMatrix * mr.transform.localToWorldMatrix;
        for (int i = 0; i < verts.Length; i+=100)
        {
            if (i >= verts.Length)
                return;
            GameObject go = GameObject.CreatePrimitive(PrimitiveType.Cube);
            go.hideFlags = HideFlags.HideAndDontSave;
            //go.transform.position = 
        }
    }
    void OnRenderObject()
    {
        //PopulateBuffer();
        //cubeMat.SetPass(0);
        //Graphics.DrawProceduralNow(MeshTopology.Points, 1, vertCount);
    }
}
