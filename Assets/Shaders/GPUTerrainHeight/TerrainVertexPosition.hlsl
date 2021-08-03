#include "../GPUTerrain/InputStruct.hlsl"
#include "./GPUTerrainHeight.hlsl"

#define PATCH_SIZE 8
#define PATCH_RESOLUTION 0.5
#define PATCH_GRID_COUNT 16

StructuredBuffer<RenderPatch> renderPatchList;

void FixLodSeam(inout float3 vertexOS, RenderPatch patch)
{
    uint2 vertexIndex = floor((vertexOS.xz + PATCH_SIZE * 0.5 + 0.01) / PATCH_RESOLUTION);
    uint4 lodTrans = patch.lodTrans;
    float uvGridStrip = 1.0f/PATCH_GRID_COUNT;
    //up
    if(lodTrans.x > 0 && vertexIndex.y == PATCH_GRID_COUNT)
    {
        uint gridStripCount = pow(2, lodTrans.x);
        uint modIndex = vertexIndex.x % gridStripCount;
        if(modIndex != 0)
        {
            vertexOS.x += PATCH_RESOLUTION * (gridStripCount - modIndex);
            return;
        }
    }
    //down
    if(lodTrans.y > 0 && vertexIndex.y == 0)
    {
        uint gridStripCount = pow(2, lodTrans.y);
        uint modIndex = vertexIndex.x % gridStripCount;
        if(modIndex != 0)
        {
            vertexOS.x -= PATCH_RESOLUTION * modIndex;
            return;
        }
    }
    //left
    if(lodTrans.z > 0 && vertexIndex.x == 0)
    {
        uint gridStripCount = pow(2, lodTrans.z);
        uint modIndex = vertexIndex.y % gridStripCount;
        if(modIndex != 0)
        {
            vertexOS.z -= PATCH_RESOLUTION * modIndex;
            return;
        }
    }
    //right
    if(lodTrans.w > 0 && vertexIndex.x == PATCH_GRID_COUNT)
    {
        uint gridStripCount = pow(2, lodTrans.w);
        uint modIndex = vertexIndex.y & gridStripCount;
        if(modIndex != 0)
        {
            vertexOS.z += PATCH_RESOLUTION * (gridStripCount - modIndex);
            return;
        }
    }
}

void GetTerrainVertex_float(float instanceID, float3 posOS, out float3 oposOS, out float4 color)
{
    RenderPatch patch = renderPatchList[(int)instanceID];
    FixLodSeam(posOS, patch);
    float2 patchPos = patch.position;
    uint curlod = patch.lod;
    uint2 vertexIndex = floor((posOS.xz + PATCH_SIZE * 0.5 + 0.01) / PATCH_RESOLUTION);
    float patchSize = PATCH_SIZE*pow(2,curlod);
    oposOS = posOS*pow(2,curlod);
    oposOS += float3(patchPos.x,0,patchPos.y);
    
    //int biome = GetBiome(oposOS.x, oposOS.z);
    //oposOS.y = GetBiomeHeight(biome,oposOS.x, oposOS.z)*200.0f;

    oposOS.y = 0;//TerrainSmoothHeight((float2)vertexIndex, oposOS.x, oposOS.z, patchSize, patchPos)*200.0f;
    
    color = 1;//GetBlendMask(oposOS.x, oposOS.z);
}

void setupProcedural()
{

}