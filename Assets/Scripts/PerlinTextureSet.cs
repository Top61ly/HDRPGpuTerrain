using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class PerlinTextureSet : MonoBehaviour
{
    public Texture2D perlin;

    private void Start() 
    {
       Shader.SetGlobalTexture("_PerlinTex", perlin);
    }
}
