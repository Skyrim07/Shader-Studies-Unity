using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]

public class WaterBottle : MonoBehaviour
{
    private Collider cld;
    private Material mat;
    private void OnEnable()
    {
        cld = GetComponent<Collider>();
        mat = GetComponent<MeshRenderer>().sharedMaterial;
    }

    private void Update()
    {
        mat.SetFloat("_HPos", cld.bounds.max.y);
        mat.SetFloat("_LPos", cld.bounds.min.y);
    }
}
