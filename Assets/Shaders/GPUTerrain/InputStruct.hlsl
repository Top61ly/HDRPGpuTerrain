struct RenderPatch
{
    float2 position;
    //float2 minMaxHeight;
    uint lod;
    //uint4 lodTrans;
    //float heights[256];
};

struct NodeDescriptor
{
    uint branch;
};

struct Bound
{
    float3 minPosition;
    float3 maxPosition;
};