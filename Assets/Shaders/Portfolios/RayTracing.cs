using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;


[ExecuteAlways, ImageEffectAllowedInSceneView]
public sealed class RayTracing : MonoBehaviour
{
    public bool enableTAA;
    public int MaxBounceCount = 10, NumRaysPerPixel = 5;

    [SerializeField] Color SkyColorHorizon, SkyColorZenith;
    [SerializeField] Color GroundColor;
    [SerializeField] Vector3 SunLightDirection;
    [SerializeField] float SunFocus, SunIntensity;
    [SerializeField] float DivergeStrength, DefocusStrength, FocusDistance;

    [SerializeField] Shader rayTracingShader, taaShader;
    private Material rayTracingMaterial, taaMaterial;

    private Camera cam;
    private Transform sphereContainer;
    private Transform meshContainer;

    private int NumRenderedFrame;
    private RenderTexture oldRT;
    private CommandBuffer commandBuffer;
private void OnEnable()
    {
        Init();

    }

    private void Init()
    {
        oldRT = null;
        commandBuffer = new CommandBuffer();
        NumRenderedFrame = 0;
        rayTracingMaterial = new Material(rayTracingShader);
        taaMaterial = new Material(taaShader);
        cam = GetComponent<Camera>();
        sphereContainer = GameObject.Find("Spheres").transform;
        meshContainer = GameObject.Find("Meshes").transform;
    }
    private void OnDestroy()
    {
        if (commandBuffer != null)
        {
            commandBuffer.Release();
        }
    }
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (sphereContainer == null)
        {
            Init();
        }
        NumRenderedFrame++;
        UpdateSceneInfo();
        UpdateCameraParams(cam);

        // Make sure the oldRT has the same format as the source
        if (oldRT == null || oldRT.format != source.format)
        {
            if (oldRT != null)
            {
                RenderTexture.ReleaseTemporary(oldRT);
            }
            oldRT = RenderTexture.GetTemporary(source.width, source.height, source.depth, source.format);
        }


        if (enableTAA)
        {
            RenderTexture renderTexture = RenderTexture.GetTemporary(source.width, source.height, source.depth, source.format);
            commandBuffer.Clear();

            // Ray tracing pass
            commandBuffer.Blit(null, renderTexture, rayTracingMaterial);

            // Temporal anti-aliasing pass
            commandBuffer.SetGlobalTexture("_MainTexOld", oldRT);
            commandBuffer.SetGlobalFloat("NumRenderedFrame", NumRenderedFrame);
            commandBuffer.Blit(renderTexture, destination, taaMaterial);

            // Copy the result to oldRT for the next frame
            commandBuffer.Blit(destination, oldRT);

            Graphics.ExecuteCommandBuffer(commandBuffer);
            RenderTexture.ReleaseTemporary(renderTexture);
        }
        else
        {
            Graphics.Blit(null, destination, rayTracingMaterial);
        }
    }

    void UpdateCameraParams(Camera cam)
    {
        float planeHeight = cam.nearClipPlane * Mathf.Tan(cam.fieldOfView * 0.5f * Mathf.Deg2Rad) * 2;
        float planeWidth = planeHeight * cam.aspect;

        rayTracingMaterial.SetVector("ViewParams", new Vector3(planeWidth, planeHeight, FocusDistance*cam.nearClipPlane));
        rayTracingMaterial.SetMatrix("CamLocalToWorldMatrix", cam.transform.localToWorldMatrix);    
        rayTracingMaterial.SetFloat("MaxBounceCount", MaxBounceCount);    
        rayTracingMaterial.SetFloat("NumRaysPerPixel", NumRaysPerPixel);

        rayTracingMaterial.SetColor("SkyColorHorizon", SkyColorHorizon);
        rayTracingMaterial.SetColor("SkyColorZenith", SkyColorZenith);
        rayTracingMaterial.SetColor("GroundColor", GroundColor);
        rayTracingMaterial.SetVector("SunLightDirection", SunLightDirection);
        rayTracingMaterial.SetFloat("SunFocus", SunFocus);
        rayTracingMaterial.SetFloat("SunIntensity", SunIntensity);
        rayTracingMaterial.SetFloat("DivergeStrength", DivergeStrength);
        rayTracingMaterial.SetFloat("DefocusStrength", DefocusStrength);
    }

    void UpdateSceneInfo()
    {
        int count = sphereContainer.childCount;
        Sphere[] spheres = new Sphere[count];
        for (int i = 0; i < count; i++)
        {
            Transform tf = sphereContainer.GetChild(i);
            spheres[i].position = tf.position;
            spheres[i].radius = tf.localScale.x / 2.0f;
            spheres[i].material = tf.GetComponent<RaytraceObject>().material;
        }
        ComputeBuffer sphereBuffer = new ComputeBuffer(count, 12 + 4 + (16 * 3 + 4 + 4 +4 + 4 + 4 + 4));
        sphereBuffer.SetData(spheres);
        rayTracingMaterial.SetFloat("NumSpheres", count);
        rayTracingMaterial.SetBuffer("Spheres", sphereBuffer);
        if(enableTAA)
        rayTracingMaterial.SetFloat("NumRenderedFrame", NumRenderedFrame);

        count = meshContainer.childCount;
        MeshInfo[] meshes = new MeshInfo[count];
        List<Triangle> triangles = new List<Triangle>();
        uint numTriangles = 0;
        for (int i = 0; i < count; i++)
        {
            Transform tf = meshContainer.GetChild(i);
            Matrix4x4 localToWorld = tf.localToWorldMatrix;
            Mesh mesh = tf.GetComponent<MeshFilter>().sharedMesh;
            Renderer mr = tf.GetComponent<Renderer>();
            MeshInfo meshInfo = new MeshInfo();
            meshInfo.firstTriangleIndex = numTriangles;
            meshInfo.material = meshContainer.GetChild(i).GetComponent<RaytraceObject>().material;
            meshInfo.numTriangles = (uint)mesh.triangles.Length / 3;
            meshInfo.boundsMin = mr.bounds.min;
            meshInfo.boundsMax =mr.bounds.max;
            meshes[i] = meshInfo;
            for (int j = 0; j < mesh.triangles.Length; j+=3)
            {
                int[] mtri = { mesh.triangles[j], mesh.triangles[j+1], mesh.triangles[j+2]};
                Triangle tri = new Triangle();
                tri.posA = localToWorld.MultiplyPoint3x4(mesh.vertices[mtri[0]]);
                tri.posB = localToWorld.MultiplyPoint3x4(mesh.vertices[mtri[1]]);
                tri.posC = localToWorld.MultiplyPoint3x4(mesh.vertices[mtri[2]]);

                tri.normalA = localToWorld.MultiplyPoint3x4(mesh.normals[mtri[0]]);
                tri.normalB= localToWorld.MultiplyPoint3x4(mesh.normals[mtri[1]]);
                tri.normalC = localToWorld.MultiplyPoint3x4(mesh.normals[mtri[1]]);
                triangles.Add(tri);
                numTriangles++;
            }

        }
        ComputeBuffer meshBuffer = new ComputeBuffer(count, 4+4+12+12+ (16 * 3 + 4 +4 +4 +4+4+4));
        ComputeBuffer triangleBuffer = new ComputeBuffer(triangles.Count, 12 *6);
        meshBuffer.SetData(meshes);
        triangleBuffer.SetData(triangles);
        rayTracingMaterial.SetFloat("NumMeshes", count);
        rayTracingMaterial.SetBuffer("AllMeshInfo", meshBuffer);
        rayTracingMaterial.SetBuffer("Triangles", triangleBuffer);
    }

    [Serializable]
    public struct Sphere
    {
        public Vector3 position;
        public float radius;
        public RayTracingMaterial material;
    };
    [Serializable]
    public struct RayTracingMaterial
    {
        public Color color;
        public Color specularColor;
        public Color emissionColor;
        public float emissionStrength;
        [Range(0.0f, 1.0f)]
        public float smoothness, specularProbability;
        [Range(0.0f, 1.0f)]
        public float refractionIndex;
        public int isVolume;
        [Range(0.0f, 1.0f)]
        public float volumeDensity;
    };

    public struct Triangle
    {
        public Vector3 posA, posB, posC;
        public Vector3 normalA, normalB, normalC;
    };

    public struct MeshInfo
    {
        public uint firstTriangleIndex;
        public uint numTriangles;
        public Vector3 boundsMin;
        public Vector3 boundsMax;
        public RayTracingMaterial material;
    };
}
