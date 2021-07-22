float2 unity_gradientNoise_dir(float2 p)
{
    p = p % 289;
    float x = (34 * p.x + 1) * p.x % 289 + p.y;
    x = (34 * x + 1) * x % 289;
    x = frac(x / 41) * 2 - 1;
    return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
}

float unity_gradientNoise(float2 p)
{
    float2 ip = floor(p);
    float2 fp = frac(p);
    float d00 = dot(unity_gradientNoise_dir(ip), fp);
    float d01 = dot(unity_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
    float d10 = dot(unity_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
    float d11 = dot(unity_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
    fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
    return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
}

float unity_perlinnoise(float u, float v)
{
    float ret = unity_gradientNoise(float2(u,v))+0.5;
    return ret;
}

float Length(float a, float b)
{
    return length(float2(a,b));
}

float LerpStep(float l, float h, float v)
{
    return clamp((v - l) / (h - l),0,1);
}

float BaseTerrainHeight(float wx, float wy)
{
    float offset0 = 0.0f;
    float offset1 = 0.0f;
    float minMountainDistance = 1000.0f;
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
    if (num2 > 10000.0f)
    {
        float t = LerpStep(10000.0f, 10500.0f, num2);
        num3 = lerp(num3, -0.2f, t);
        float num7 = 10490.0f;
        if (num2 > num7)
        {
            float t2 = LerpStep(num7, 10500.0f, num2);
            num3 = lerp(num3, -2.0f, t2);
        }
    }
    if (num2 < minMountainDistance && num3 > 0.28f)
    {
        float t3 = clamp((num3 - 0.28f) / 0.099999994f,0,1);
        num3 = lerp(lerp(0.28f, 0.38f, t3), num3, LerpStep(minMountainDistance - 400.0f, minMountainDistance, num2));
    }
    return num3;
}

float GetMenuHeight(float wx, float wy)
{
    float baseHeight = BaseTerrainHeight(wx, wy);
    // wx += 100000f + this.m_offset3;
    // wy += 100000f + this.m_offset3;
    float num = unity_perlinnoise(wx * 0.01f, wy * 0.01f) * unity_perlinnoise(wx * 0.02f, wy * 0.02f);
    num += unity_perlinnoise(wx * 0.05f, wy * 0.05f) * unity_perlinnoise(wx * 0.1f, wy * 0.1f) * num * 0.5f;
    return baseHeight + num * 0.1f + unity_perlinnoise(wx * 0.1f, wy * 0.1f) * 0.01f + unity_perlinnoise(wx * 0.4f, wy * 0.4f) * 0.003f;
}

float TerrainHeight(float x, float z)
{
    return GetMenuHeight(x,z);
}

void TerrainHeight_float(float x, float z, out float height)
{
    height = TerrainHeight(x,z)*200.0f;
}