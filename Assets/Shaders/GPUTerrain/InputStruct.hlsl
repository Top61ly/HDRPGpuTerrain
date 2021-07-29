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