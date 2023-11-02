using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public sealed class Fireworks : MonoBehaviour
{
    public int gridCount = 10;
    public float gridSize = 0.2f;
    public float randomFactor = 0.2f;

    [Range(0,1)]
    public float radius = 0.5f;
    [Range(0, 1)]
    public float smooth = 0.2f;
    public float speed = 2f;

    Mesh mesh;
    List<Vector3> vertex = new List<Vector3>();
    List<Vector2> uv = new List<Vector2>();
    List<Vector2> gv = new List<Vector2>();
    List<int> triangle = new List<int>();

    private Vector3 center;
    private MeshFilter mf;
    private MeshRenderer mr;
    private Material mat;
    private float fract(float a)
    {
        return a-Mathf.Floor(a);
    }
    private float N11(float a)
    {
        return fract(Mathf.Sin(a * 35365.16f) * 14.161f);
    }
    private float N21(float a, float b)
    {
        return fract(Mathf.Sin(a * b* 35365.16f) * 14.161f);
    }

    private void OnEnable()
    {
        vertex.Clear();
        uv.Clear();
        gv.Clear();
        triangle.Clear();

        center = Vector3.zero;
        mf = gameObject.GetComponent<MeshFilter>(); 
        mr = gameObject.GetComponent<MeshRenderer>();
        mat = mr.sharedMaterial;

        mesh = new Mesh();
        int index = 0;
        for (int i = 0; i < gridCount-1; i++)
        {
            for (int j = 0; j < gridCount-1; j++)
            {
                Vector3 random = new Vector3(N11(i +j+ 50), N11((i+5)*(j+5) + 90)) * randomFactor;
                vertex.Add(new Vector3(i * gridSize, j * gridSize) + random);
                vertex.Add(new Vector3((i+1) * gridSize, j * gridSize) + random);
                vertex.Add(new Vector3((i + 1) * gridSize, (j+1) * gridSize) + random);
                vertex.Add(new Vector3(i * gridSize, (j+1) * gridSize) + random);

                triangle.Add(index);
                triangle.Add(index+3);
                triangle.Add(index+2);

                triangle.Add(index);
                triangle.Add(index+2);
                triangle.Add(index+1);

                uv.Add(new Vector2(i/(float)gridCount, j/(float)gridCount));
                uv.Add(new Vector2((i+1)/(float)gridCount, j/(float)gridCount));
                uv.Add(new Vector2((i+1)/(float)gridCount, (j+1)/(float)gridCount));
                uv.Add(new Vector2(i/(float)gridCount, (j+1)/(float)gridCount));

                gv.Add(Vector2.zero);
                gv.Add(Vector2.right);
                gv.Add(Vector2.one);
                gv.Add(Vector2.up);

                index += 4;
            }
        }

        mesh.vertices = vertex.ToArray();
        mesh.uv = uv.ToArray();
        mesh.triangles = triangle.ToArray();
        mesh.uv2 = gv.ToArray();
        mf.sharedMesh = mesh;
    }

    private void Update()
    {
        if (mat)
        {
            mat.SetFloat("_Radius", radius);
            mat.SetFloat("_Smooth", smooth);
            mat.SetFloat("_Speed", speed);
            mat.SetInt("_BlockSize", gridCount);

           // mat.SetFloat("_Scatter", Mathf.Sin(Time.time) * 6 - 2);
        }
    }
}
