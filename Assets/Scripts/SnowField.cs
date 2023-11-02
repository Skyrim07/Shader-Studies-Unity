using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.UI;

[ExecuteInEditMode]

public class SnowField : MonoBehaviour
{
    public Shader shader;
    public Texture2D noiseTex;

    public GameObject player;

    [Range(0.01f,1f)]
    public float brushSize = 1;
    public float brushStrength = 1;
    [Range(0.01f, 2f)]
    public float noiseStrength = 1;

    [Range(0.01f,5f)]
    public float recoverRate = 1;

    private RenderTexture rt;
    private Material snowMat, trackMat;
    private RaycastHit hit;

    private void OnEnable()
    {
        trackMat = new Material(shader);
        trackMat.SetVector("_Color", Color.red);

        snowMat = GetComponent<MeshRenderer>().sharedMaterial;

        rt = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGBFloat);
        snowMat.SetTexture("_DispTex", rt);

        EditorApplication.update += Update;
    }
    private void OnDisable()
    {
        EditorApplication.update -= Update;
    }
    private void Update()
    {
        if (!rt)
            return;

        Recover();

        if (!player)
            return;

        Physics.Raycast(player.transform.position, Vector3.down, out hit);
        if (hit.collider != null)
        {
            snowMat.SetTexture("_DispTex", rt);
            DrawTrack();
        }
    }

    private void Recover()
    {
        trackMat.SetFloat("_Recover", recoverRate);
        RenderTexture t = RenderTexture.GetTemporary(rt.width, rt.height, 0, RenderTextureFormat.ARGBFloat);
        ///IMPORTANT! 
        ///Use a temp render texture to preserve the track drawn before. (Draw track shader will read the pixels of the last texture
        ///and add new track onto it.)
        Graphics.Blit(rt, t);
        Graphics.Blit(t, rt, trackMat);
        RenderTexture.ReleaseTemporary(t);
    }

    private void DrawTrack()
    {
        trackMat.SetVector("_Coordinate", new Vector4(hit.textureCoord.x, hit.textureCoord.y, 0, 0));
        trackMat.SetFloat("_BrushSize", brushSize);
        trackMat.SetFloat("_Strength", brushStrength);
        trackMat.SetTexture("_NoiseTex", noiseTex);
        trackMat.SetFloat("_NoiseStrength", noiseStrength);

        RenderTexture t = RenderTexture.GetTemporary(rt.width, rt.height, 0, RenderTextureFormat.ARGBFloat);
        ///IMPORTANT! 
        ///Use a temp render texture to preserve the track drawn before. (Draw track shader will read the pixels of the last texture
        ///and add new track onto it.)
        Graphics.Blit(rt, t);
        Graphics.Blit(t, rt, trackMat);
        RenderTexture.ReleaseTemporary(t);
    }
}
