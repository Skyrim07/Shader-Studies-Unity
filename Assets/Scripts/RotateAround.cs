using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RotateAround : MonoBehaviour
{
    public Transform center;
    [Range(0.1f,15f)]
    public float speed = 1;

    private float angle = 0;
    void Start()
    {
        
    }


    void Update()
    {
        if (!center)
            return;
        angle = 0.05f * speed;
        transform.RotateAround(center.position, Vector3.up, angle);
    }
}
