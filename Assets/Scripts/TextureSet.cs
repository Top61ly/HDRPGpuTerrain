using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class TextureSet : MonoBehaviour
{
    public Texture perlin;

    void OnEnable()
    {
        Shader.SetGlobalTexture("_PerlinTex",perlin);
    }
}
