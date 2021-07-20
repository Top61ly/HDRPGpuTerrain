using System;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

[GenerateHLSL]
struct TerrainInstanceData
{
    public Vector3 pos;
    public float scale;

    public TerrainInstanceData(Vector3 center, float scale)
    {
        pos = center;
        this.scale = scale;
    }
}

[Serializable]
class TerrainParams
{
    public int terrianTileCount = 5;
    public float terrianWidth = 10240.0f;
}

class GpuTerrainPass : CustomPass
{
    public TerrainParams terrainParams = new TerrainParams();

    [SerializeField] private Mesh m_TerrainMesh;
    [SerializeField] private Material m_IndirectMaterial;

    [SerializeField] private ComputeShader m_TerrainBuildComputeShader;
    [SerializeField] private ComputeShader m_CopyBufferComputeShader;

    const string s_TerrainNodeBuildKernelName = "TerrainNodeBuild";
    const string s_TerrainLodMapKernelName = "TerrainLODMap";
    const string s_TerrainVisibleRenderKernelName = "TerrainVisibleRender";
    const string s_CopyBufferKernelName = "CSCopyBuffer";

    int m_NodeBuildKernelID = -1;
    int m_LODMapKernelID = -1;
    int m_VisibleRenderKernelID = -1;
    int m_CopyBufferKernelID = -1;

    private int m_ShaderPassID = -1;
    private ComputeBuffer m_InitTerrainPositionBuffer;
    private ComputeBuffer m_TestBuffer;
    private ComputeBuffer m_TempABuffer;
    private ComputeBuffer m_TempBBuffer;
    private ComputeBuffer m_IndirectArgsBuffer;

    private uint[] args = new uint[5] { 0, 0, 0, 0, 0};

    protected override void Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)
    {
        //1 Compute Shader Kernel Init
        //1.1   Terrain Build
        m_NodeBuildKernelID = m_TerrainBuildComputeShader.FindKernel(s_TerrainNodeBuildKernelName);
        m_LODMapKernelID = m_TerrainBuildComputeShader.FindKernel(s_TerrainLodMapKernelName);
        m_VisibleRenderKernelID = m_TerrainBuildComputeShader.FindKernel(s_TerrainVisibleRenderKernelName);
        
        //1.2   ComputeShader CopyBuffer
        m_CopyBufferKernelID = m_CopyBufferComputeShader.FindKernel(s_CopyBufferKernelName);
       
        m_ShaderPassID = m_IndirectMaterial.FindPass("GBuffer");
        
        //Init Terrain Node
        TerrainInstanceData[] instances = new TerrainInstanceData[25];
        for(int i = 0; i<terrainParams.terrianTileCount; i++)
            for (int j = 0; j<terrainParams.terrianTileCount; j++)
            {
                float tileWidth = terrainParams.terrianWidth/terrainParams.terrianTileCount;
                Vector3 center = new Vector3(tileWidth*(i+0.5f),0,tileWidth*(j+0.5f));
                center -= new Vector3(terrainParams.terrianWidth/2,0,terrainParams.terrianWidth/2);
                instances[i+j*terrainParams.terrianTileCount] = new TerrainInstanceData(center,31.0f);
            }

        m_InitTerrainPositionBuffer = new ComputeBuffer(25,Marshal.SizeOf(typeof(TerrainInstanceData)));
        m_TestBuffer = new ComputeBuffer(16,Marshal.SizeOf(typeof(TerrainInstanceData)));
        m_InitTerrainPositionBuffer.SetData(instances);
        m_IndirectMaterial.SetBuffer("instances", m_InitTerrainPositionBuffer);

        //Init Args
        m_IndirectArgsBuffer = new ComputeBuffer(1,args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
        args[0] = (uint)m_TerrainMesh.GetIndexCount(0);
        args[1] = (uint)25;
        args[2] = (uint)m_TerrainMesh.GetIndexStart(0);
        args[3] = (uint)m_TerrainMesh.GetBaseVertex(0);
        m_IndirectArgsBuffer.SetData(args);
    }

    protected override void Execute(CustomPassContext ctx)
    {
        ctx.cmd.DrawMeshInstancedIndirect(m_TerrainMesh,0,m_IndirectMaterial,m_ShaderPassID,m_IndirectArgsBuffer);
    }

    protected override void Cleanup()
    {
        if(m_IndirectArgsBuffer != null)
            m_IndirectArgsBuffer.Release();
        if(m_InitTerrainPositionBuffer != null)
            m_InitTerrainPositionBuffer.Release();
    }    
}