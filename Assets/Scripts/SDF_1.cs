using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public sealed class SDF_1 : MonoBehaviour
{
    [SerializeField] float speed = 1f;

    Material mat;
    int sign = 1;
    float curBlend = 0;
    private void OnEnable()
    {
        mat = GetComponent<MeshRenderer>().sharedMaterial;
    }
    private void Update()
    {
        curBlend += 0.01f * speed * sign;
        if (curBlend > 1 || curBlend<0)
            sign = -sign;
        mat.SetFloat("_Blend", curBlend);
    }
}
