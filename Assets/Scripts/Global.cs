using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class Global
{
    public static string ShaderPrefix = "AlexLiu/";

    public static Shader FindShader(string shaderName)
    {
        return Shader.Find(ShaderPrefix + shaderName);
    }
}
