using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[ExecuteInEditMode]
public sealed class CSScript : MonoBehaviour
{
    [SerializeField]  RawImage ri;
    [SerializeField] ComputeShader cs;

    private Texture tex;

    private void OnEnable()
    {
        tex = ri.texture;
        cs.SetTexture(cs.FindKernel("CSMain"), "Result", tex);
    }

    private void Update()
    {
        if (ri.texture != null)
        {
            cs.Dispatch(cs.FindKernel("CSMain"), 2, 2, 1);
        //    ri.texture = tex;
        }
    }
}
