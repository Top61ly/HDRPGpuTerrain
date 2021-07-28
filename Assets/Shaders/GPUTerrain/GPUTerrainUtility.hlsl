#define GRIDSIZE 64
#define TERRAIN_WIDTH 10240
#define MAXTERRAINLOD 5 //Highest Res: 0  Lowest Res: 5
#define TOTALTERRAINTILES 34125 //5x5 10x10 20x20 40x40 80x80 160x160

struct RenderPatch
{
    float2 position;
    //float2 minMaxHeight;
    uint lod;
    //uint4 lodTrans;
    //float3 heights[289];
};

struct Bound
{
    float3 minPosition;
    float3 maxPosition;
};

float GetNodeSize(uint curLodLevel)
{
    return (float)GRIDSIZE*pow(2,curLodLevel);
}

float GetNodeCount(uint curLodLevel)
{
    uint highestCount = TERRAIN_WIDTH/GRIDSIZE;
    return (float)highestCount/pow(2,curLodLevel);
}

float3 GetNodeWorldPosition(uint2 node, uint curLodLevel)
{
    float nodeSize = GetNodeSize(curLodLevel);
    float nodeCount = GetNodeCount(curLodLevel);
    float2 nodePositionWS = ((float2)node+0.5f-nodeCount/2)*nodeSize;
    //TODO: Add y to NodeWorldPosition
    return float3(nodePositionWS.x,0,nodePositionWS.y);
}