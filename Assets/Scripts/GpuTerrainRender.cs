using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GpuTerrainRender : MonoBehaviour
{
    public Mesh terrainPatch;
    public Material instanceMaterial;
    public Texture perlinTexture;
    public static ComputeBuffer m_IndirectArgs;

    private uint[] args = new uint[5]{0,0,0,0,0};

    private void OnEnable() 
    {
        m_IndirectArgs = new ComputeBuffer(5,sizeof(uint), ComputeBufferType.IndirectArguments);
        args[0] = (uint)terrainPatch.GetIndexCount(0);
        args[1] = (uint)0;
        args[2] = (uint)terrainPatch.GetIndexStart(0);
        args[3] = (uint)terrainPatch.GetBaseVertex(0);
        m_IndirectArgs.SetData(args);

        instanceMaterial.SetTexture("_PerlinTex", perlinTexture);
    }

    private void Update() 
    {
        Graphics.DrawMeshInstancedIndirect(terrainPatch, 0, instanceMaterial, new Bounds(Vector3.zero, Vector3.one*10240), m_IndirectArgs);
    }

    private void OnDisable() {
        if(m_IndirectArgs != null)
            m_IndirectArgs.Release();
        m_IndirectArgs = null;
    }
}
