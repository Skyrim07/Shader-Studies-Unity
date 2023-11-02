using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


[ExecuteInEditMode]
public class Dissolve : MonoBehaviour
{
    Material mat;
    float dissolveAmount = 0f;
    int sign = 1;

    [Range(0,1)]
    public float dissolveSpeed = 1f;
    private void OnEnable()
    {
        mat = GetComponent<MeshRenderer>().sharedMaterial;
        dissolveAmount = mat.GetFloat("_Threshold");
        EditorApplication.update += Update;
    }
    private void OnDisable()
    {
        EditorApplication.update -= Update;
    }
    private void Update()
    {
        dissolveAmount += sign * dissolveSpeed * 0.005f;
        if (dissolveAmount > 1)
            sign = -1;
        if (dissolveAmount < 0)
            sign = 1;
        mat.SetFloat("_Threshold", dissolveAmount);
    }
}
