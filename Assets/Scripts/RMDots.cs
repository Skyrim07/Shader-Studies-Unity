using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public sealed class RMDots : MonoBehaviour
{
    public int density = 5;
    public float random = 1;
    public float moveScatter = 1;
    public Vector4 center;
    
    private float invDensity;
    private Material mat;

    private float randl, randr;
    private Vector4[] points;
    private Vector4[] randDis;
    private void OnEnable()
    {
        invDensity = 1f / density;
        mat = GetComponent<MeshRenderer>().sharedMaterial;
        points = new Vector4[density * density * density];
        randDis = new Vector4[density * density * density];
        randl = -random * 0.2f;
        randr = random * 0.2f;

        for (int i = 0; i < randDis.Length; i ++)
        {
            randDis[i] = new Vector4(Random.Range(randl, randr), Random.Range(randl, randr), Random.Range(randl, randr), 0);
        }
    }

    private void Update()
    {
        int count = 0;
        for (float i = 0; i < 1; i+= invDensity)
        {
            for (float j = 0; j < 1; j += invDensity)
            {
                for (float k = 0; k < 1; k += invDensity)
                {
                    points[count] = center+new Vector4(i*2-1, j * 2 - 1, k * 2 - 1, 1) + randDis[count] + RandPos(count+Time.time)* moveScatter;
                    count++;
                }
            }
        }

        mat.SetVectorArray("_Points", points);
    }

    Vector4 RandPos(float f)
    {
        return new Vector4(Mathf.Sin(f + Mathf.Sin(f)), Mathf.Cos(f + Mathf.Sin(f + 2.43f)), Mathf.Sin(f + Mathf.Sin(f + Mathf.Cos(f + 2.43f))), 0);
    }
}
