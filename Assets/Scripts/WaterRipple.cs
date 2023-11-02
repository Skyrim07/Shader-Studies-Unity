using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class WaterRipple : MonoBehaviour
{
    public float flattenSpeed=1, spreadSpeed=1;

    private Material mat;
    private int waveNum =0;
    private float[] distX, distZ, amplitude, dist;
    private Vector4[] ripplePos;

    private float timer;

    private void OnEnable()
    {
        mat = GetComponent<MeshRenderer>().sharedMaterial;
        distX = new float[8];
        distZ = new float[8];
        dist = new float[8];
        amplitude = new float[8];
        ripplePos = new Vector4[8];
    }

    private void Update()
    {
        timer += 0.01f;
        if (timer >= 1.2f)
        {
            GenerateRipple(transform.position + new Vector3(Random.Range(-2.5f, 2.5f), 0, Random.Range(-2.5f, 2.5f)));
            timer = 0;
        }

        for (int i = 0; i < 8; i++)
        {
            amplitude[i] -= flattenSpeed * 0.01f;
            amplitude[i] = Mathf.Max(0, amplitude[i]);

            dist[i] += spreadSpeed * 0.01f;
        }
        mat.SetFloatArray("amplitude", amplitude);
        mat.SetFloatArray("dist", dist);
    }

    private void OnCollisionEnter(Collision collision)
    {
        GenerateRipple(collision.transform.position);
    }

    private void GenerateRipple(Vector3 worldPos)
    {
        if (waveNum >= 8)
            waveNum = 0;

        float coeff = transform.lossyScale.x * transform.lossyScale.z * (mat.GetFloat("_Freq") / 20f);
        distX[waveNum] = (transform.position.x - worldPos.x) * coeff;
        distZ[waveNum] = (transform.position.z - worldPos.z) * coeff;
        ripplePos[waveNum] = worldPos;

        amplitude[waveNum] = Random.Range(0.5f, 2f);
        dist[waveNum] = 1.5f;

        mat.SetFloatArray("offsetX", distX);
        mat.SetFloatArray("offsetZ", distZ);
        mat.SetFloatArray("amplitude", amplitude);
        mat.SetVectorArray("ripplePos", ripplePos);

        waveNum++;
    }
}
