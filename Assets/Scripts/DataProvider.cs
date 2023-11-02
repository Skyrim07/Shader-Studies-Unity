using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DataProvider : MonoBehaviour
{
    public int count = 256;
    [Range(0, 1)]
    public float min = 0, max =1;

    [Range(0, 0.1f)]
    public float amplitude = 0.03f;

    public float[] values;

    private Material mat;

    private void OnEnable()
    {
        mat = GetComponent<MeshRenderer>().sharedMaterial;
        values = new float[count];
    }

    void Update()
    {
        for (int i = 0; i < count; i++)
        {
            values[i] += Random.Range(-amplitude, amplitude);
            values[i] = Mathf.Clamp(values[i], min, max);
        }
        mat.SetFloatArray("Values", values);
    }
}
