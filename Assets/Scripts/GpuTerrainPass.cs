using System;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using Unity.Mathematics;

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
    public int maxLod = 5;
    public int terrianTileCount = 5;
    public float terrianWidth = 10240.0f;
}

class GpuTerrainPass : CustomPass
{
    public TerrainParams terrainParams = new TerrainParams();

    [SerializeField] private Mesh m_TerrainMesh;
    [SerializeField] private Material m_IndirectMaterial;

    [SerializeField] private ComputeShader m_TerrainBuildComputeShader;
    
    const string s_TerrainNodeBuildKernelName = "TerrainNodeBuild";
    const string s_TerrainLodMapKernelName = "TerrainLODMap";
    const string s_TerrainVisibleRenderKernelName = "TerrainVisibleRender";

    int m_NodeBuildKernelID = -1;
    int m_LODMapKernelID = -1;
    int m_VisibleRenderKernelID = -1;
    int m_CopyAppendConsumeBufferKernelID = -1;

    private class ShaderParms
    {
        public static readonly int r_CameraPositionWS = Shader.PropertyToID("_cameraPos");
        public static readonly int r_CameraFrustumPlanes = Shader.PropertyToID("_cameraFrustumPlandes");
        public static readonly int r_WorldParams = Shader.PropertyToID("_worldParams");
        public static readonly int r_CurLodLevelt = Shader.PropertyToID("_curLodLevel");
        public static readonly int r_NodeEvaluationC = Shader.PropertyToID("_nodeEvaluationC");
        public static readonly int r_AppendNodeList = Shader.PropertyToID("appendNodeList");
        public static readonly int r_ConsumeNodeList = Shader.PropertyToID("consumeNodeList");
        public static readonly int r_FinalNodeList = Shader.PropertyToID("finalNodeList");
        public static readonly int r_LodMap = Shader.PropertyToID("_lodMap");
        public static readonly int r_NodeDescriptors = Shader.PropertyToID("nodeDescriptors");
    }

    Camera m_Camera;
    Plane[] m_CameraFrustumPlanes = new Plane[6];
    Vector4[] m_CameraFrustumPlanesV4 = new Vector4[6];
    Vector4 m_NodeEvaluationC = new Vector4(1,0,0,0);

    private int m_ShaderPassID = -1;

    private ComputeBuffer m_InitTerrainPositionBuffer;

    private ComputeBuffer m_TempNodeListA;
    private ComputeBuffer m_TempNodeListB;
    private ComputeBuffer m_FinalNodeList;

    private ComputeBuffer m_IndirectArgsBuffer;
    private ComputeBuffer m_DispatchIndirectArgsBuffer;

    private uint[] args = new uint[5] { 0, 0, 0, 0, 0};

    protected override void Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)
    {
        //1 Compute Shader Kernel Init
        //1.1   Terrain Build
        m_NodeBuildKernelID = m_TerrainBuildComputeShader.FindKernel(s_TerrainNodeBuildKernelName);
        m_LODMapKernelID = m_TerrainBuildComputeShader.FindKernel(s_TerrainLodMapKernelName);
        m_VisibleRenderKernelID = m_TerrainBuildComputeShader.FindKernel(s_TerrainVisibleRenderKernelName);
               
        m_ShaderPassID = m_IndirectMaterial.FindPass("GBuffer");
        
        //Init Terrain Node List
        var index = 0;
        uint2[] instances = new uint2[25];
        for(uint i = 0; i<terrainParams.terrianTileCount; i++)
            for (uint j = 0; j<terrainParams.terrianTileCount; j++)
            {
                instances[index] = new uint2(i,j);
                index++;
            }

        m_InitTerrainPositionBuffer = new ComputeBuffer(25,8,ComputeBufferType.Append);
        m_InitTerrainPositionBuffer.SetData(instances); 

        //Init NodeList Buffer
        m_TempNodeListA = new ComputeBuffer(25, 8, ComputeBufferType.Append);
        m_TempNodeListB = new ComputeBuffer(25, 8, ComputeBufferType.Append);
        m_FinalNodeList = new ComputeBuffer(25, 12, ComputeBufferType.Append);
        
        //Init Indirect Draw Args 
        m_IndirectArgsBuffer = new ComputeBuffer(5,sizeof(uint), ComputeBufferType.IndirectArguments);
        args[0] = (uint)m_TerrainMesh.GetIndexCount(0);
        args[1] = (uint)0;
        args[2] = (uint)m_TerrainMesh.GetIndexStart(0);
        args[3] = (uint)m_TerrainMesh.GetBaseVertex(0);
        m_IndirectArgsBuffer.SetData(args);

        //Init Dispatch Indirect Args
        m_DispatchIndirectArgsBuffer = new ComputeBuffer(3,4,ComputeBufferType.IndirectArguments);
        m_DispatchIndirectArgsBuffer.SetData(new uint[]{1,1,1});

        //Set Material Buffer
        //m_IndirectMaterial.SetBuffer("finalNodeList", m_InitTerrainPositionBuffer);
    }

    protected override void Execute(CustomPassContext ctx)
    {   
        ClearBufferCounter(ctx.cmd);

        //Set Camera Params
        m_Camera = Camera.main;
        UpdateCameraFrustumPlanes(m_Camera);
        
        ctx.cmd.SetComputeVectorParam(m_TerrainBuildComputeShader, ShaderParms.r_CameraPositionWS, m_Camera.transform.position);
        ctx.cmd.SetComputeVectorArrayParam(m_TerrainBuildComputeShader, ShaderParms.r_CameraFrustumPlanes, m_CameraFrustumPlanesV4);

        ctx.cmd.SetComputeVectorParam(m_TerrainBuildComputeShader, ShaderParms.r_NodeEvaluationC, m_NodeEvaluationC);

        ctx.cmd.CopyCounterValue(m_InitTerrainPositionBuffer, m_DispatchIndirectArgsBuffer, 0);
        
        //Stage 1 : Traverse All Node add to finalNodeList
        ctx.cmd.SetComputeBufferParam(m_TerrainBuildComputeShader, m_NodeBuildKernelID, ShaderParms.r_FinalNodeList, m_FinalNodeList);

        ComputeBuffer consumeNodeList = m_TempNodeListA;
        ComputeBuffer appendNodeList = m_TempNodeListB;
        for(int lod = terrainParams.maxLod; lod >= 0; lod--)
        {
            ctx.cmd.SetComputeIntParam(m_TerrainBuildComputeShader, ShaderParms.r_CurLodLevelt, lod);

            if(lod == terrainParams.maxLod)
                ctx.cmd.SetComputeBufferParam(m_TerrainBuildComputeShader, m_NodeBuildKernelID, ShaderParms.r_ConsumeNodeList, m_InitTerrainPositionBuffer);
            else
                ctx.cmd.SetComputeBufferParam(m_TerrainBuildComputeShader, m_NodeBuildKernelID, ShaderParms.r_ConsumeNodeList, consumeNodeList);
           
            ctx.cmd.SetComputeBufferParam(m_TerrainBuildComputeShader, m_NodeBuildKernelID, ShaderParms.r_AppendNodeList, appendNodeList);
           
            ctx.cmd.DispatchCompute(m_TerrainBuildComputeShader, m_NodeBuildKernelID, m_DispatchIndirectArgsBuffer, 0);
           
            ctx.cmd.CopyCounterValue(appendNodeList, m_DispatchIndirectArgsBuffer, 0);
           
            var temp = consumeNodeList;
            consumeNodeList = appendNodeList;
            appendNodeList = temp;
        }

        ctx.cmd.CopyCounterValue(m_FinalNodeList, m_IndirectArgsBuffer, 4);

        m_IndirectMaterial.SetBuffer("finalNodeList", m_FinalNodeList);

        ctx.cmd.DrawMeshInstancedIndirect(m_TerrainMesh,0,m_IndirectMaterial,m_ShaderPassID,m_IndirectArgsBuffer);
    }

    protected override void Cleanup()
    {
        if(m_IndirectArgsBuffer != null)
            m_IndirectArgsBuffer.Release();
        
        if(m_InitTerrainPositionBuffer != null)
            m_InitTerrainPositionBuffer.Release();

        if(m_TempNodeListA != null)
            m_TempNodeListA.Release();

        if(m_TempNodeListB != null)
            m_TempNodeListB.Release();

        if(m_FinalNodeList != null)
            m_FinalNodeList.Release();
        
        if(m_DispatchIndirectArgsBuffer != null)
            m_DispatchIndirectArgsBuffer.Release();        
    }    

    private void UpdateCameraFrustumPlanes(Camera camera)
    {
        GeometryUtility.CalculateFrustumPlanes(camera, m_CameraFrustumPlanes);
        for (int i = 0; i<m_CameraFrustumPlanes.Length; i++)
        {
            Vector4 v4 = (Vector4)m_CameraFrustumPlanes[i].normal;
            v4.w = m_CameraFrustumPlanes[i].distance;
            m_CameraFrustumPlanesV4[i] = v4;
        }
    }

    private void ClearBufferCounter(CommandBuffer cmd)
    {
        cmd.SetComputeBufferCounterValue(m_InitTerrainPositionBuffer, (uint)m_InitTerrainPositionBuffer.count);
        cmd.SetComputeBufferCounterValue(m_TempNodeListA, 0);
        cmd.SetComputeBufferCounterValue(m_TempNodeListB, 0);
        cmd.SetComputeBufferCounterValue(m_FinalNodeList, 0);
    }
}