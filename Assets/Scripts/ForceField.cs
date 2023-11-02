using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]

public class ForceField : MonoBehaviour
{
    Material mat;
    Shader shader;

    public float hitRadius = 1f;

    private void OnEnable()
    {
        mat = GetComponent<MeshRenderer>().sharedMaterial;
        shader = mat.shader;
    }

    private void OnCollisionEnter(Collision collision)
    {
        mat.SetVector("_HitPoint", collision.contacts[0].point);
        mat.SetFloat("_HitRadius", hitRadius);
    }
}
