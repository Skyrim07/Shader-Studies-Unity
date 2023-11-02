using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]

public class GrassSpawner : MonoBehaviour
{
    public Texture2D heightMap;     //我们指定的高度图

    [Range(0, 70f)]     //Range作为一个Attribute，可以方便我们在Inspector面板上进行
                        //拖拽更改变量的值，并对其大小做一个限制
    public float terrainHeight = 10;

    [Range(0, 250)]
    public int terrainSize = 64;    //我们所生成的地形的长宽

    public Vector3 terrainOffset, grassOffset;

    public Material terrainMat, grassMat;  

    private GameObject terrain, grassLayer;

    //“草根集”的行列数，“草根集”是什么下文会提及
    public int grassRowCount = 30;
    public int grassCountPerPatch = 50;
    //public Material grassMat;	//之后会指定给点云的材质
    private List<Vector3> verts;

    void OnEnable()
    {
        verts = new List<Vector3>();
        GenerateTerrain();		//生成地形
        GenerateGrassArea(grassRowCount, grassCountPerPatch);
    }

    private void GenerateTerrain()
    {
        if (terrain)
            DestroyImmediate(terrain);
        if (grassLayer)
            DestroyImmediate(grassLayer);

        //要生成一个平面，我们需要自定义其顶点和网格数据
        List<Vector3> vertexs = new List<Vector3>();
        List<int> tris = new List<int>();

        //进行循环，生成一个基本的平面
        for (int i = 0; i < terrainSize; i++)
            for (int j = 0; j < terrainSize; j++)
            {
                //使用GetPixel读取高度图的灰度，计算所生成点的高度
                vertexs.Add(new Vector3(i, heightMap.GetPixel(i, j).grayscale * terrainHeight, j));

                //非坐标轴的顶点
                if (i == 0 || j == 0)
                    continue;

                //给tris添加vertex的索引，可以理解为把每三个顶点“相互连起来”，生成三角形
                tris.Add(terrainSize * i + j);
                tris.Add(terrainSize * i + j - 1);
                tris.Add(terrainSize * (i - 1) + j - 1);
                tris.Add(terrainSize * (i - 1) + j - 1);
                tris.Add(terrainSize * (i - 1) + j);
                tris.Add(terrainSize * i + j);
            }
        //计算uv
        Vector2[] uvs = new Vector2[vertexs.Count];
        for (var i = 0; i < uvs.Length; i++)
            uvs[i] = new Vector2(vertexs[i].x, vertexs[i].z);

        //创建一个名为Terrain的GameObject，并赋予其材质
        terrain = new GameObject("Terrain");
        terrain.transform.SetParent(transform, true);
        terrain.transform.localPosition = Vector3.zero+ terrainOffset;
        terrain.AddComponent<MeshFilter>();
        MeshRenderer renderer = terrain.AddComponent<MeshRenderer>();
        renderer.sharedMaterial = terrainMat;

        //创建一个mesh来承载我们的网格数据，并将该mesh赋予生成的Terrain
        Mesh groundMesh = new Mesh();
        groundMesh.vertices = vertexs.ToArray();
        groundMesh.uv = uvs;
        groundMesh.triangles = tris.ToArray();
        //重新计算法线
        groundMesh.RecalculateNormals();
        terrain.GetComponent<MeshFilter>().mesh = groundMesh;

        verts.Clear();
    }
    private void GenerateGrassArea(int rowCount, int countPerPatch)
    {
        List<int> indices = new List<int>();
        //Unity网格顶点上限65535
        for (int i = 0; i < 65000; i++)
        {
            indices.Add(i);
        }

        //设置循环起始位置
        var startPosition =Vector3.zero;
        //计算每次循环后位置的偏移量，即“步幅”
        var patchSize = new Vector3(terrainSize / rowCount, 0, terrainSize / rowCount);

        for (int x = 0; x < rowCount; x++)
        {
            for (int y = 0; y < rowCount; y++)
            {
                //调用另一个函数来在startPosition的周围生成更多的随机分布的点，这些点即为上文提到的“草根集”
                this.GenerateGrass(startPosition, patchSize, countPerPatch);
                startPosition.x += patchSize.x;
            }

            startPosition.x = 0;
            startPosition.z += patchSize.z;
        }

        Mesh mesh;
        MeshFilter meshFilter;
        MeshRenderer renderer;

        int a = 0;
        ////当要生成的顶点超过65000时
        //while (verts.Count > 65000)
        //{
        //    mesh = new Mesh();
        //    mesh.vertices = verts.GetRange(0, 65000).ToArray();
        //    //设置子网格的索引缓冲区,相关官方文档：https://docs.unity3d.com/ScriptReference/Mesh.SetIndices.html
        //    mesh.SetIndices(indices.ToArray(), MeshTopology.Points, 0);

        //    //创建一个GameObject来承载这些点
        //    grassLayer = new GameObject("grassLayer " + a++);
        //    meshFilter = grassLayer.AddComponent<MeshFilter>();
        //    renderer = grassLayer.AddComponent<MeshRenderer>();
        //    //renderer.sharedMaterial = grassMat;
        //    meshFilter.mesh = mesh;
        //    verts.RemoveRange(0, 65000);
        //}

        grassLayer = new GameObject("GrassLayer");
        grassLayer.transform.SetParent(transform);
        grassLayer.transform.localPosition = grassOffset;
        mesh = new Mesh();
        mesh.vertices = verts.ToArray();

        mesh.SetIndices(indices.GetRange(0, verts.Count).ToArray(), MeshTopology.Points, 0);
        meshFilter = grassLayer.AddComponent<MeshFilter>();
        renderer = grassLayer.AddComponent<MeshRenderer>();
        meshFilter.mesh = mesh;
        renderer.sharedMaterial = grassMat;

    }

    private void GenerateGrass(Vector3 pos, Vector3 patchSize, int grassCountPerPatch)
    {
        //循环以生成“草根集”
        for (int i = 0; i < grassCountPerPatch; i++)
        {
            //Random.value范围[0,1]之间的一个随机浮点数，将其乘以步幅大小
            var randomX = Random.value * patchSize.x;
            var randomZ = Random.value * patchSize.z;

            int indexX = (int)(pos.x + randomX);
            int indexZ = (int)(pos.z + randomZ);

            //防止种草种出地形
            if (indexX >= terrainSize)
            {
                indexX = (int)terrainSize - 1;
            }

            if (indexZ >= terrainSize)
            {
                indexZ = (int)terrainSize - 1;
            }
            //添加此次循环生成的点的位置
            Vector3 currentPos = new Vector3(pos.x + randomX, heightMap.GetPixel(indexX, indexZ).grayscale * terrainHeight, pos.z + randomZ);
            verts.Add(currentPos);

        }
    }
}
