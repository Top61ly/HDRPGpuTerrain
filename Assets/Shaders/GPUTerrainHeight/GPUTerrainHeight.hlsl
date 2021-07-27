#include "./TerrainBiomeHeight.hlsl"

float TerrainHeight(float x, float z)
{
    float scale = 4.0f;
    int biome0 = GetBiome(x,z);
    int biome1 = GetBiome(x+scale,z);
    int biome2 = GetBiome(x,z+scale);
    int biome3 = GetBiome(x+scale,z+scale);

    [branch]
    if(biome0 == biome1 && biome1 == biome2 && biome2==biome3)
    {
        return GetBiomeHeight(biome0,x,z);
    }
    else
    {
        float biomeHeight0 = GetBiomeHeight(biome0,x,z);
        float biomeHeight1 = GetBiomeHeight(biome1,x+scale,z);
        float biomeHeight2 = GetBiomeHeight(biome2,x,z+scale);
        float biomeHeight3 = GetBiomeHeight(biome3,x+scale,z+scale);
        
        return (biomeHeight0+biomeHeight1+biomeHeight2+biomeHeight3)/4;
    }
}

void TerrainHeight_float(float x, float z, out float height)
{
    height = TerrainHeight(x,z)*200.0f;
}

void TerrainColor_float(float x, float z, out float4 color)
{
    color = GetBlendMask(x,z);
}