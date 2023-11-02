using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public sealed class DS : MonoBehaviour
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
        if (curBlend > 1.0f || curBlend < 0.0f)
            sign = -sign;
        mat.SetFloat("_DValue", curBlend);
    }
}
