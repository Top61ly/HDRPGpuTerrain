#include "./TerrainBiomeHeight.hlsl"

// 3  x  2
// y     y
// 0  x  1
float TerrainSmoothHeight(float2 vertexIndex, float x, float z, float patchSize, float2 patchPos)
{
    int biome0 = GetBiome(patchPos.x-patchSize/2, patchPos.y - patchSize/2);
    int biome1 = GetBiome(patchPos.x+patchSize/2, patchPos.y - patchSize/2);
    int biome2 = GetBiome(patchPos.x+patchSize/2, patchPos.y + patchSize/2);
    int biome3 = GetBiome(patchPos.x-patchSize/2, patchPos.y + patchSize/2);
    
    
    [branch]
    if(biome0 == biome1 && biome1 == biome2 && biome2==biome3)
    {
        return GetBiomeHeight(GetBiome(x,z),x,z);
    }
    else
    {
        float biomeHeight0 = GetBiomeHeight(biome0,x,z);
        float biomeHeight1 = GetBiomeHeight(biome1,x,z);
        float biomeHeight2 = GetBiomeHeight(biome2,x,z);
        float biomeHeight3 = GetBiomeHeight(biome3,x,z);
        
        float t = smoothstep(0.0f,1.0f,vertexIndex.x/15.0f);
        float t1 = smoothstep(0.0f,1.0f,vertexIndex.y/15.0f);

        float a = lerp(biomeHeight0, biomeHeight1, t);
        float b = lerp(biomeHeight3, biomeHeight2, t);
        float c = lerp(a, b, t1);

        return c;
    }
}

float TerrainHeight(float x, float z)
{
   int biome = GetBiome(x,z);
   return GetBiomeHeight(biome,x,z);
}

void TerrainHeight_float(float x, float z, out float height)
{
    height = TerrainHeight(x,z)*200.0f;
}

void TerrainColor_float(float x, float z, out float4 color)
{
    color = GetBlendMask(x,z);
}