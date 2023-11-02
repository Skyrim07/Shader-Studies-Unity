using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public sealed class AvatarFx_1 : MonoBehaviour
{
    MeshRenderer mr;
    Material mat;
    private void OnEnable()
    {
        mr = GetComponent<MeshRenderer>();
        mat = mr.sharedMaterial;
    }
}
