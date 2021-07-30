#include "../GPUTerrain/InputStruct.hlsl"
#include "./GPUTerrainHeight.hlsl"

StructuredBuffer<RenderPatch> renderPatchList;

void GetTerrainVertex_float(float instanceID, float3 posOS, out float3 oposOS, out float4 color)
{
    RenderPatch patch = renderPatchList[(int)instanceID];
    float2 patchPos = patch.position;
    uint curlod = patch.lod;

    oposOS = posOS*pow(2,curlod);
    oposOS += float3(patchPos.x,0,patchPos.y);
    
    oposOS.y = TerrainHeight(oposOS.x, oposOS.z)*200.0f;
    
    color = GetBlendMask(oposOS.x, oposOS.z);
}

void setupProcedural()
{

}