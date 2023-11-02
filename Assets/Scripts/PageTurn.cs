using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public sealed class PageTurn : MonoBehaviour
{
    private Material mat;

    private void OnEnable()
    {
        mat = GetComponent<MeshRenderer>().sharedMaterial;
    }

    private void Update()
    {
        mat.SetFloat("_Turn", (Mathf.Clamp(Mathf.Sin(Time.time), -0.5f, 0.5f) + 0.5f)*3.14f);
    }
}
