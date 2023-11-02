using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class MotionBlur : MonoBehaviour
{
    public float intensity = 1, moveSpeed = 1;

    private float t, m;
    private Vector3 lastPos, newPos;
    private Material mat;
    void OnEnable()
    {
        mat = GetComponent<MeshRenderer>().sharedMaterial;
        lastPos = transform.position;
    }

    void Update()
    {
        newPos = transform.position;

        if (Vector3.Distance(newPos , lastPos) < 0.05f) 
            t = 0;
        t += Time.deltaTime;

        lastPos = Vector3.Lerp(lastPos, newPos, t / 2);

        Vector3 dir = transform.position - lastPos;
        mat.SetVector("_Direction", new Vector4(dir.x, dir.y, dir.z, intensity));


        m += Time.deltaTime;
        if (m > 1f && m < 1.3f)
        {
            transform.Translate(new Vector3(moveSpeed * Time.deltaTime, 0, 0));
        }
        if (m > 2f && m < 2.3f)
        {
            transform.Translate(new Vector3( - moveSpeed * Time.deltaTime, 0, 0));
        }
        if (m > 2.5f){
            m = 0f;
        }
    }
}
