#include "./MathUtil.hlsl"

uniform float offset0 = 200.0f;
uniform float offset1 = 1000.0f;
uniform float offset2 = -500.0f;
uniform float offset3 = -1000.0f;
uniform float offset4 = 5000.0f;
uniform float minMountainDistance = 1000.0f;

float GetBaseHeight(float wx, float wy)
{
    float num2 = Length(wx, wy);
    wx += 100000.0f + offset0;
    wy += 100000.0f + offset1;
    float num3 = 0.0f;
    num3 += unity_perlinnoise(wx * 0.002f * 0.5f, wy * 0.002f * 0.5f) * unity_perlinnoise(wx * 0.003f * 0.5f, wy * 0.003f * 0.5f) * 1.0f;
    num3 += unity_perlinnoise(wx * 0.002f * 1.0f, wy * 0.002f * 1.0f) * unity_perlinnoise(wx * 0.003f * 1.0f, wy * 0.003f * 1.0f) * num3 * 0.9f;
    num3 += unity_perlinnoise(wx * 0.005f * 1.0f, wy * 0.005f * 1.0f) * unity_perlinnoise(wx * 0.01f * 1.0f, wy * 0.01f * 1.0f) * 0.5f * num3;
    num3 -= 0.07f;
    float num4 = unity_perlinnoise(wx * 0.002f * 0.25f + 0.123f, wy * 0.002f * 0.25f + 0.15123f);
    float num5 = unity_perlinnoise(wx * 0.002f * 0.25f + 0.321f, wy * 0.002f * 0.25f + 0.231f);
    float v = abs(num4 - num5);
    float num6 = 1.0f - LerpStep(0.02f, 0.12f, v);
    num6 *= smoothstep(744.0f, 1000.0f, num2);
    num3 *= 1.0f - num6;

    [branch]
    if (num2 > 10000.0f)
    {
        float t = LerpStep(10000.0f, 10500.0f, num2);
        num3 = lerp(num3, -0.2f, t);
        float num7 = 10490.0f;

        [branch]
        if (num2 > num7)
        {
            float t2 = LerpStep(num7, 10500.0f, num2);
            num3 = lerp(num3, -2.0f, t2);
        }
    }

    [branch]
    if (num2 < minMountainDistance && num3 > 0.28f)
    {
        float t3 = clamp((num3 - 0.28f) / 0.099999994f,0,1);
        num3 = lerp(lerp(0.28f, 0.38f, t3), num3, LerpStep(minMountainDistance - 400.0f, minMountainDistance, num2));
    }

    return num3;
}


float BaseHeightTilt(float wx, float wy)
{
    float baseHeight = GetBaseHeight(wx - 1.0f, wy);
    float baseHeight2 = GetBaseHeight(wx + 1.0f, wy);
    float baseHeight3 = GetBaseHeight(wx, wy - 1.0f);
    float baseHeight4 = GetBaseHeight(wx, wy + 1.0f);
    return abs(baseHeight2 - baseHeight) + abs(baseHeight3 - baseHeight4);
}

float AddRivers(float wx, float wy, float h)
{
    // float num;
    // float v;
    // GetRiverWeight(wx, wy, out num, out v);
    // if (num <= 0f)
    // {
    //     return h;
    // }
    // float t = Utils.LerpStep(20f, 60f, v);
    // float num2 = Mathf.Lerp(0.14f, 0.12f, t);
    // float num3 = Mathf.Lerp(0.139f, 0.128f, t);
    // if (h > num2)
    // {
    //     h = Mathf.Lerp(h, num2, num);
    // }
    // if (h > num3)
    // {
    //     float t2 = Utils.LerpStep(0.85f, 1f, num);
    //     h = Mathf.Lerp(h, num3, t2);
    // }
    // return h;
    return h;
}

float GetMarshHeight(float wx, float wy)
{
    float wx2 = wx;
    float wy2 = wy;
    float num = 0.137f;
    wx += 100000.0f;
    wy += 100000.0f;
    float num2 = unity_perlinnoise(wx * 0.04f, wy * 0.04f) * unity_perlinnoise(wx * 0.08f, wy * 0.08f);
    num += num2 * 0.03f;
    num = AddRivers(wx2, wy2, num);
    num += unity_perlinnoise(wx * 0.1f, wy * 0.1f) * 0.01f;
    return num + unity_perlinnoise(wx * 0.4f, wy * 0.4f) * 0.003f;
}

float GetMeadowsHeight(float wx, float wy)
{
    float wx2 = wx;
    float wy2 = wy;
    float baseHeight = GetBaseHeight(wx, wy);
    wx += 100000.0f + offset3;
    wy += 100000.0f + offset3;
    float num = unity_perlinnoise(wx * 0.01f, wy * 0.01f) * unity_perlinnoise(wx * 0.02f, wy * 0.02f);
    num += unity_perlinnoise(wx * 0.05f, wy * 0.05f) * unity_perlinnoise(wx * 0.1f, wy * 0.1f) * num * 0.5f;
    float num2 = baseHeight;
    num2 += num * 0.1f;
    float num3 = 0.15f;
    float num4 = num2 - num3;
    float num5 = clamp(baseHeight / 0.4f,0.0f,1.0f);
    if (num4 > 0.0f)
    {
        num2 -= num4 * (1.0f - num5) * 0.75f;
    }
    num2 = AddRivers(wx2, wy2, num2);
    num2 += unity_perlinnoise(wx * 0.1f, wy * 0.1f) * 0.01f;
    return num2 + unity_perlinnoise(wx * 0.4f, wy * 0.4f) * 0.003f;
}

float GetForestHeight(float wx, float wy)
{
    float wx2 = wx;
    float wy2 = wy;
    float num = GetBaseHeight(wx,wy);
    wx += 100000.0f + offset3;
    wy += 100000.0f + offset3;
    float num2 = unity_perlinnoise(wx * 0.01f, wy * 0.01f) * unity_perlinnoise(wx * 0.02f, wy * 0.02f);
    num2 += unity_perlinnoise(wx * 0.05f, wy * 0.05f) * unity_perlinnoise(wx * 0.1f, wy * 0.1f) * num2 * 0.5f;
    num += num2 * 0.1f;
    num = AddRivers(wx2, wy2, num);
    num += unity_perlinnoise(wx * 0.1f, wy * 0.1f) * 0.01f;
    return num + unity_perlinnoise(wx * 0.4f, wy * 0.4f) * 0.003f;
}

float GetPlainsHeight(float wx, float wy)
{
    float wx2 = wx;
    float wy2 = wy;
    float baseHeight = GetBaseHeight(wx,wy);
    wx += 100000.0f + offset3;
    wy += 100000.0f + offset3;
    float num = unity_perlinnoise(wx * 0.01f, wy * 0.01f) * unity_perlinnoise(wx * 0.02f, wy * 0.02f);
    num += unity_perlinnoise(wx * 0.05f, wy * 0.05f) * unity_perlinnoise(wx * 0.1f, wy * 0.1f) * num * 0.5f;
    float num2 = baseHeight;
    num2 += num * 0.1f;
    float num3 = 0.15f;
    float num4 = num2 - num3;
    float num5 = clamp(baseHeight / 0.4f, 0.0f, 1.0f);
    if (num4 > 0.0f)
    {
        num2 -= num4 * (1.0f - num5) * 0.75f;
    }
    num2 = AddRivers(wx2, wy2, num2);
    num2 += unity_perlinnoise(wx * 0.1f, wy * 0.1f) * 0.01f;
    return num2 + unity_perlinnoise(wx * 0.4f, wy * 0.4f) * 0.003f;
}

float GetAshlandsHeight(float wx, float wy)
{
    float wx2 = wx;
    float wy2 = wy;
    float num = GetBaseHeight(wx,wy);
    wx += 100000.0f + offset3;
    wy += 100000.0f + offset3;
    float num2 = unity_perlinnoise(wx * 0.01f, wy * 0.01f) * unity_perlinnoise(wx * 0.02f, wy * 0.02f);
    num2 += unity_perlinnoise(wx * 0.05f, wy * 0.05f) * unity_perlinnoise(wx * 0.1f, wy * 0.1f) * num2 * 0.5f;
    num += num2 * 0.1f;
    num += 0.1f;
    num += unity_perlinnoise(wx * 0.1f, wy * 0.1f) * 0.01f;
    num += unity_perlinnoise(wx * 0.4f, wy * 0.4f) * 0.003f;
    return AddRivers(wx2, wy2, num);
}

float GetOceanHeight(float wx, float wy)
{
    return GetBaseHeight(wx,wy);
}

float GetSnowMountainHeight(float wx, float wy)
{
    float wx2 = wx;
    float wy2 = wy;
    float num = GetBaseHeight(wx, wy);
    float num2 = BaseHeightTilt(wx, wy);
    wx += 100000.0f + offset3;
    wy += 100000.0f + offset3;
    float num3 = num - 0.4f;
    num += num3;
    float num4 = unity_perlinnoise(wx * 0.01f, wy * 0.01f) * unity_perlinnoise(wx * 0.02f, wy * 0.02f);
    num4 += unity_perlinnoise(wx * 0.05f, wy * 0.05f) * unity_perlinnoise(wx * 0.1f, wy * 0.1f) * num4 * 0.5f;
    num += num4 * 0.2f;
    num = AddRivers(wx2, wy2, num);
    num += unity_perlinnoise(wx * 0.1f, wy * 0.1f) * 0.01f;
    num += unity_perlinnoise(wx * 0.4f, wy * 0.4f) * 0.003f;
    return num + unity_perlinnoise(wx * 0.2f, wy * 0.2f) * 2.0f * num2;
}

float GetDeepNorthHeight(float wx, float wy)
{
    float wx2 = wx;
    float wy2 = wy;
    float num = GetBaseHeight(wx,wy);
    wx += 100000.0f + offset3;
    wy += 100000.0f + offset3;
    float num2 = max(0.0f, num - 0.4f);
    num += num2;
    float num3 = unity_perlinnoise(wx * 0.01f, wy * 0.01f) * unity_perlinnoise(wx * 0.02f, wy * 0.02f);
    num3 += unity_perlinnoise(wx * 0.05f, wy * 0.05f) * unity_perlinnoise(wx * 0.1f, wy * 0.1f) * num3 * 0.5f;
    num += num3 * 0.2f;
    num *= 1.2f;
    num = AddRivers(wx2, wy2, num);
    num += unity_perlinnoise(wx * 0.1f, wy * 0.1f) * 0.01f;
    return num + unity_perlinnoise(wx * 0.4f, wy * 0.4f) * 0.003f;
}

float GetMenuHeight(float wx, float wy)
{
    float baseHeight = GetBaseHeight(wx, wy);
    wx += 100000.0f + offset3;
    wy += 100000.0f + offset3;
    float num = unity_perlinnoise(wx * 0.01f, wy * 0.01f) * unity_perlinnoise(wx * 0.02f, wy * 0.02f);
    num += unity_perlinnoise(wx * 0.05f, wy * 0.05f) * unity_perlinnoise(wx * 0.1f, wy * 0.1f) * num * 0.5f;
    return baseHeight + num * 0.1f + unity_perlinnoise(wx * 0.1f, wy * 0.1f) * 0.01f + unity_perlinnoise(wx * 0.4f, wy * 0.4f) * 0.003f;
}

// enum Biome
// {
// 	None,
// 	Meadows,
// 	Swamp,
// 	Mountain,
// 	BlackForest,
// 	Plains,
// 	AshLands,
// 	DeepNorth,
// 	Ocean,
// 	Mistlands,
// 	BiomesMax
// }

// #define BIOME_NONE 0;
// #define BIOME_MEADOWS 1;
// #define BIOME_SWAMP 2;
// #define BIOME_MOUNTAIN 3;
// #define BIOME_BLACKFOREST 4;
// #define BIOME_PLAINS 5;
// #define BIOME_ASHLANDS 6;
// #define BIOME_DEEPNORTH 7;
// #define BIOME_OCEAN 8;
// #define BIOME_MISTLAND 9;
// #define BIOME_BIOMEMAX 10;

int GetBiome(float wx, float wy)
{
    float magnitude = Length(wx,wy);
    float baseHeight = GetBaseHeight(wx,wy);
    float worldAngle = GetWorldAngle(wx,wy);
    
    if (Length(wx, wy + -4000.0f) > 12000.0f + worldAngle)
    {
        return 6;//Heightmap.Biome.AshLands;
    }
    
    if (baseHeight <= 0.02f)
    {
        return 8;//Heightmap.Biome.Ocean;
    }

    [branch]
    if (Length(wx, wy + 4000.0f) > 12000.0f + worldAngle)
    {
        if (baseHeight > 0.4f)
        {
            return 3;//Heightmap.Biome.Mountain;
        }
        return 7;//Heightmap.Biome.DeepNorth;
    }
    else
    {
        if (baseHeight > 0.4f)
        {
            return 3;//Heightmap.Biome.Mountain;
        }
        if (unity_perlinnoise((offset0 + wx) * 0.001f, (offset0 + wy) * 0.001f) > 0.6f && magnitude > 2000.0f && magnitude < 8000.0f && baseHeight > 0.05f && baseHeight < 0.25f)
        {
            return 2;//Heightmap.Biome.Swamp;
        }
        if (unity_perlinnoise((offset4 + wx) * 0.001f, (offset4 + wy) * 0.001f) > 0.5f && magnitude > 6000.0f + worldAngle && magnitude < 10000.0f)
        {
            return 9;//Heightmap.Biome.Mistlands;
        }
        if (unity_perlinnoise((offset1 + wx) * 0.001f, (offset1 + wy) * 0.001f) > 0.4f && magnitude > 3000.0f + worldAngle && magnitude < 8000.0f)
        {
            return 5;//Heightmap.Biome.Plains;
        }
        if (unity_perlinnoise((offset2 + wx) * 0.001f, (offset2 + wy) * 0.001f) > 0.4f && magnitude > 600.0f + worldAngle && magnitude < 6000.0f)
        {
            return 4;//Heightmap.Biome.BlackForest;
        }
        if (magnitude > 5000.0f + worldAngle)
        {
            return 4;//Heightmap.Biome.BlackForest;
        }
        return 1;//Heightmap.Biome.Meadows;
    }
}

float GetBiomeHeight(float wx, float wy)
{
    int biome = GetBiome(wx,wy);

    // [branch]
    // switch(biome)
    // {
    //     case 0:
    //         return 0.0f;
    //     case 1:
    //         return 1.0f;
    //     default:
    //         return 2.0f;
    // }
    [branch] 
    switch(biome)
    {
        case 1:
            return GetMeadowsHeight(wx,wy);
        case 2:
            return GetMarshHeight(wx,wy);
        case 3:
            return GetSnowMountainHeight(wx,wy);
        case 4:
            return GetForestHeight(wx,wy);
        case 5:
            return GetPlainsHeight(wx,wy);
        case 6:
            return GetAshlandsHeight(wx,wy);
        case 7:
            return GetDeepNorthHeight(wx,wy);
        case 8:
            return GetOceanHeight(wx,wy);
        case 9:
            return GetForestHeight(wx,wy);
        default:
            return 0.0f; 
    }
}

//TODO: Should add a keyword to represent a Blend Array
float4 GetBlendMask(float wx, float wy)
{
    int biome = GetBiome(wx,wy);

    [branch] 
    switch(biome)
    {
        case 1:
            return float4(1.0f,0,0,0);
        case 2:
            return float4(1.0f,0,0,0);
        case 3:
            return float4(0,1.0f,0,0);
        case 4:
            return float4(0,0,1.0f,0);
        case 5:
            return float4(0,0,0,1.0f);
        case 6:
            return float4(1.0f,0,0,1.0f);
        case 7:
            return float4(0,1.0f,0,0);
        case 8:
            return float4(0,0,0,0);
        case 9:
            return float4(0,0,1.0f,1.0f);
        default:
            return float4(0,0,0,0); 
    }
}

//TODO: Should change to maxlayer's number
void VertexMask(float wx, float wy, out float4 mask1)
{
    int biome = GetBiome(wx,wy);
    
    [branch] 
    switch(biome)
    {
        case 1:
            mask1.x = 1.0f;
            break;
        case 2:
            mask1.x = 1.0f;
            break;
        case 3:
            mask1.y = 1.0f;
            break;
        case 4:
            mask1.z = 1.0f;
            break;
        case 5:
            mask1.w = 1.0f;
            break;
        case 6:
            mask1.x = 1.0f;
            mask1.w = 1.0f;
            break;
        case 7:
            mask1.y = 1.0f;
            break;
        // case 8:
        //     break;
        case 9:
            mask1.y = 1.0f;
            mask1.w = 1.0f;
            break;
        default:
            return;
    }
}
