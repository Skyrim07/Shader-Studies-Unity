using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteInEditMode]
[RequireComponent(typeof(CapsuleCollider))]
public sealed class GrassInteract : MonoBehaviour
{
    public float radius = 1, strength =1;

    private CapsuleCollider capsuleCollider;
    public MeshRenderer mr;
    private Material grassMat;
    private void OnEnable()
    {
        capsuleCollider = GetComponent<CapsuleCollider>();
        grassMat = mr.sharedMaterial;
    }

    private void Update()
    {
        if (!grassMat)
            return;
        grassMat.SetVector("_GrassInteractCenter",capsuleCollider.bounds.center - new Vector3(0,capsuleCollider.bounds.extents.y,0));
        grassMat.SetFloat("_GrassInteractRadius",radius);
        grassMat.SetFloat("_InteractiveStrength", strength);
    }
}
