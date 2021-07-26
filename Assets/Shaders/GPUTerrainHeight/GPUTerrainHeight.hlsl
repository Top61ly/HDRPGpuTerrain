#include "./TerrainBiomeHeight.hlsl"

float TerrainHeight(float x, float z)
{
    int biome0 = GetBiome(x,z);
    int biome1 = GetBiome(x+1.0f,z);
    int biome2 = GetBiome(x,z+1.0f);
    int biome3 = GetBiome(x+1.0f,z+1.0f);

    [branch]
    if(biome0 == biome1 && biome1 == biome2 && biome2==biome3)
    {
        return GetBiomeHeight(biome0,x,z);
    }
    else
    {
        float biomeHeight0 = GetBiomeHeight(biome0,x,z);
        float biomeHeight1 = GetBiomeHeight(biome1,x+1.0f,z);
        float biomeHeight2 = GetBiomeHeight(biome2,x,z+1.0f);
        float biomeHeight3 = GetBiomeHeight(biome3,x+1.0f,z+1.0f);
        
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