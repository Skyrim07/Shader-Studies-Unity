using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class CopyShadowMap : MonoBehaviour
{
    public string maskName = "_ShadowMap0";
    CommandBuffer cb = null;

    void OnEnable()
    {
        var light = GetComponent<Light>();
        if (light)
        {
            cb = new CommandBuffer();
            cb.name = "CopyShadowMap";
            cb.SetGlobalTexture(maskName, new RenderTargetIdentifier(BuiltinRenderTextureType.CurrentActive));
            light.AddCommandBuffer(UnityEngine.Rendering.LightEvent.AfterScreenspaceMask, cb);
        }
    }

    void OnDisable()
    {
        var light = GetComponent<Light>();
        if (light)
        {
            light.RemoveCommandBuffer(UnityEngine.Rendering.LightEvent.AfterScreenspaceMask, cb);
        }
    }
}