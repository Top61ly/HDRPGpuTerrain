#include "./TerrainBiomeHeight.hlsl"

float TerrainHeight(float x, float z)
{
    // return GetBaseHeight(x,z);
    // return GetMenuHeight(x,z);
    return GetBiomeHeight(x,z);
}

void TerrainHeight_float(float x, float z, out float height)
{
    height = TerrainHeight(x,z)*200.0f;
}

void TerrainColor_float(float x, float z, out float4 color)
{
    color = GetBlendMask(x,z);
}