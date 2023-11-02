using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public sealed class CurvatureCenter : MonoBehaviour
{
    public float curve = 0.2f;
    public float power = 0.2f;
    private void Update()
    {
        Shader.SetGlobalVector("_CurvatureCenter", new Vector4(transform.position.x, transform.position.y, transform.position.z, 1));
        Shader.SetGlobalFloat("_CurvatureValue", curve);
        Shader.SetGlobalFloat("_CurvaturePower", power);
    }
}
