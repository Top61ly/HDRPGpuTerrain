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
        uint modIndex = vertexIndex.y % gridStripCount;
        if(modIndex != 0)
        {
            vertexOS.z += PATCH_RESOLUTION * (gridStripCount - modIndex);
            return;
        }
    }
}

void GetTerrainVertex_float(float instanceID, float3 posOS, out float3 oposOS, out float4 color, out float3 normal)
{
    RenderPatch patch = renderPatchList[(int)instanceID];
    FixLodSeam(posOS, patch);
    float2 patchPos = patch.position;
    uint curlod = patch.lod;
    uint2 vertexIndex = floor((posOS.xz + PATCH_SIZE * 0.5 + 0.01) / PATCH_RESOLUTION);
    float patchSize = PATCH_SIZE*pow(2,curlod);
    oposOS = posOS*pow(2,curlod);
    oposOS += float3(patchPos.x,0,patchPos.y);
    
    //oposOS.y = TerrainHeight(oposOS.x, oposOS.z)*200.0f;
    //oposOS.y = 0.0f;
    oposOS.y = TerrainSmoothHeight(oposOS.x, oposOS.z)*200.0f;
    float gridSize = patchSize/16.0f;
    float3 neighbour0 = float3(oposOS.x - gridSize, oposOS.y, oposOS.z);
    float3 neighbour1 = float3(oposOS.x, oposOS.y, oposOS.z - gridSize);
    neighbour0.y = TerrainSmoothHeight(neighbour0.x, neighbour0.z) * 200.0f;
    neighbour1.y = TerrainSmoothHeight(neighbour1.x, neighbour1.z) * 200.0f;
    normal = normalize(cross(neighbour1 - oposOS, neighbour0 - oposOS));

    color = GetBlendMask(oposOS.x, oposOS.z);
}

void GetTerrainVertexbyWorldPos_float(float3 posOS, out float3 oposOS, out float4 color, out float3 normal)
{
    oposOS = posOS;
    oposOS.y = TerrainSmoothHeight(posOS.x, posOS.z) * 200.0f;

    float3 neighbour0 = float3(posOS.x - 1, TerrainSmoothHeight(posOS.x - 1, posOS.z) * 200.0f, posOS.z);
    float3 neighbour1 = float3(posOS.x, 0, posOS.z-1);
    neighbour1.y = TerrainSmoothHeight(neighbour1.x, neighbour1.z) * 200.0f;

    normal = normalize(cross(neighbour1 - oposOS, neighbour0 - oposOS));


    color = GetBlendMask(oposOS.x, oposOS.z);
}
void TerrainHeight_float(float x, float z, out float height)
{
    height = TerrainHeight(x,z)*200.0f;
}

void TerrainColor_float(float x, float z, out float4 color)
{
    color = GetBlendMask(x,z);
}

void setupProcedural()
{

}