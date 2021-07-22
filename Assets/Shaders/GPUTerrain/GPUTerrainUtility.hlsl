#define GRIDSIZE 64
#define TERRAIN_WIDTH 10240
#define MAXTERRAINLOD 5 //Highest Res: 0  Lowest Res: 5
#define TOTALTERRAINTILES 34125 //5x5 10x10 20x20 40x40 80x80 160x160

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
    float2 nodePositionWS = ((float2)node+0.5-nodeCount/2)*nodeSize;
    //TODO: Add y to NodeWorldPosition
    return float3(nodePositionWS.x,0,nodePositionWS.y);
}