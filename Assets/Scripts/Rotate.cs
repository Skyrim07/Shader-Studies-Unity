using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Rotate : MonoBehaviour
{
    public bool multipleAxes = false;
    public float speed = 1;
    void Update()
    {
        transform.Rotate(Vector3.up, speed * 0.01f);
        if(multipleAxes)
        {
            transform.Rotate(Vector3.left, speed * 0.01f);
            transform.Rotate(Vector3.forward, speed * 0.01f);
        }
    }
}
