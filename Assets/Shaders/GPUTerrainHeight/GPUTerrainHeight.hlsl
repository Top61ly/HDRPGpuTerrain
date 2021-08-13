#include "./TerrainBiomeHeight.hlsl"

// #pragma multi_compile_instancing
// #pragma instancing_options procedural:setupProcedural

// 3  x  2
// y     y
// 0  x  1
float TerrainSmoothHeight(float x, float z)
{
    float terrainSize = 10240.0f;
    float smoothPatchSize = 256.0f;

    float2 patchPos = (floor((float2(x,z) + terrainSize/2)/smoothPatchSize)+0.5f)*smoothPatchSize;

    int biome0 = GetBiome(patchPos.x-smoothPatchSize/2, patchPos.y - smoothPatchSize/2);
    int biome1 = GetBiome(patchPos.x+smoothPatchSize/2, patchPos.y - smoothPatchSize/2);
    int biome2 = GetBiome(patchPos.x+smoothPatchSize/2, patchPos.y + smoothPatchSize/2);
    int biome3 = GetBiome(patchPos.x-smoothPatchSize/2, patchPos.y + smoothPatchSize/2);
    
    
    [branch]
    if(biome0 == biome1 && biome1 == biome2 && biome2==biome3)
    {
        return GetBiomeHeight(biome0,x,z);
    }
    else
    {
        float biomeHeight0 = GetBiomeHeight(biome0,x,z);
        float biomeHeight1 = GetBiomeHeight(biome1,x,z);
        float biomeHeight2 = GetBiomeHeight(biome2,x,z);
        float biomeHeight3 = GetBiomeHeight(biome3,x,z);
        
        float t = smoothstep(0.0f,1.0f, fmod(x+terrainSize/2,smoothPatchSize)/smoothPatchSize);
        float t1 = smoothstep(0.0f,1.0f,fmod(z+terrainSize/2,smoothPatchSize)/smoothPatchSize);

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