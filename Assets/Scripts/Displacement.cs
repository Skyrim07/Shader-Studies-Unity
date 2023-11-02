using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[ExecuteInEditMode]
public class Displacement : MonoBehaviour
{
    Material mat;
    float displaceAmount = 0f;
    int sign = 1;

    [Range(0, 1)]
    public float displaceSpeed = 1f;
    private void OnEnable()
    {
        mat = GetComponent<MeshRenderer>().sharedMaterial;
        displaceAmount = mat.GetFloat("_Displacement");
        EditorApplication.update += Update;
    }
    private void OnDisable()
    {
        EditorApplication.update -= Update;
    }
    private void Update()
    {
        displaceAmount += sign * displaceSpeed * 0.005f;
        if (displaceAmount > 1)
            sign = -1;
        if (displaceAmount < 0)
            sign = 1;
        mat.SetFloat("_Displacement", displaceAmount);
    }
}

