using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Scanner : MonoBehaviour
{
    public int id = 0;

    public float radius = 1;
    public float frequency = 2;
    public float speed = 1;
    public float meltSpeed = 2;

    private float timer = 0;
    private float r = 0;


    private void Update()
    {
        timer += 0.01f;
        if (timer >= frequency)
        {
            Shader.SetGlobalFloat("ScannerMelt" + id, Mathf.Clamp01((timer - frequency) / (frequency * (0.5f / meltSpeed))));
        }
        else
        {
            Shader.SetGlobalFloat("ScannerMelt" + id, 0);
        }
        if (timer >= frequency * (1+0.5f / meltSpeed))
        {
            timer = 0;
        }
        r = timer * speed;
        Shader.SetGlobalFloat("ScannerRadius"+id, r);
        Shader.SetGlobalVector("ScannerPos" + id, transform.position);
    }

}
