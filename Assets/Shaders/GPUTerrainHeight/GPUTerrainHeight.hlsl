#include "./TerrainBiomeHeight.hlsl"

float TerrainHeight(float x, float z)
{
    return GetPlainsHeight(x,z);
    return GetMenuHeight(x,z);
}

void TerrainHeight_float(float x, float z, out float height)
{
    height = TerrainHeight(x,z)*200.0f;
}