using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class OutlineSmooth : MonoBehaviour
{
    private void OnEnable()
    {
        MeshFilter mf = GetComponent<MeshFilter>();
        if (mf)
        {
            MeshNormalAverage(mf.sharedMesh);
        }
    }
    public void MeshNormalAverage(Mesh mesh)
    {
        Dictionary<Vector3, List<int>> map = new Dictionary<Vector3, List<int>>();

        for (int i = 0; i < mesh.vertexCount; i++)
        {
            if (!map.ContainsKey(mesh.vertices[i]))
            {
                map.Add(mesh.vertices[i], new List<int>());
            }

            map[mesh.vertices[i]].Add(i);
        }

        Vector3[] normals = mesh.normals;
        Vector3 normal;

        foreach (var p in map)
        {
            normal = Vector3.zero;

            foreach (var n in p.Value)
            {
                normal += mesh.normals[n];
            }

            normal /= p.Value.Count;

            foreach (var n in p.Value)
            {
                normals[n] = normal;
            }
        }
        mesh.normals = normals;
    }
}
