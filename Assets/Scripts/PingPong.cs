using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public sealed class PingPong : MonoBehaviour
{
    public float speed = 1;
    public float distance = 1;

    private int sign = 1;
    private Vector3 left, right;
    private void OnEnable()
    {
        left = transform.position + Vector3.left * distance;
        right = transform.position + Vector3.right * distance;
    }
    private void Update()
    {
        if (transform.position.x < left.x)
            sign = 1;
        else if (transform.position.x > right.x)
            sign = -1;

        transform.Translate(new Vector3(Time.deltaTime*speed*sign, 0, 0));
    }

}
