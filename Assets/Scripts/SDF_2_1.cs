﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public sealed class SDF_2_1 : MonoBehaviour
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
        if (curBlend > 0.3f || curBlend < -0.4f)
            sign = -sign;
        mat.SetVector("_Center", new Vector4(0, curBlend, 0, 1));
    }
}
