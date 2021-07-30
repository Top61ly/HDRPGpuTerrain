#include "../GPUTerrain/InputStruct.hlsl"
#include "./GPUTerrainHeight.hlsl"

StructuredBuffer<RenderPatch> renderPatchList;

void GetVertexID_float(float3 posOS, out uint2 vertexIndex)
{
    vertexIndex = floor((posOS.xz + 8*0.5 + 0.01)/0.5);
}

void GetTerrainVertex_float(float instanceID, float3 posOS, out float3 oposOS, out float4 color)
{
    RenderPatch patch = renderPatchList[(int)instanceID];
    float2 patchPos = patch.position;
    uint curlod = patch.lod;
    uint2 vertexIndex = floor((posOS.xz + 8 * 0.5 + 0.01) / 0.5);
    float patchSize = 8*pow(2,curlod);
    oposOS = posOS*pow(2,curlod);
    oposOS += float3(patchPos.x,0,patchPos.y);
    
    //int biome = GetBiome(oposOS.x, oposOS.z);
    //oposOS.y = GetBiomeHeight(biome,oposOS.x, oposOS.z)*200.0f;

    oposOS.y = TerrainSmoothHeight((float2)vertexIndex, oposOS.x, oposOS.z, patchSize, patchPos)*200.0f;
    
    color = GetBlendMask(oposOS.x, oposOS.z);
}

void setupProcedural()
{

}