float LerpStep(float l, float h, float v)
{
    return clamp((v - l) / (h - l),0,1);
}

float Length(float a, float b)
{
    return length(float2(a,b));
}

float GetWorldAngle(float x, float y)
{
    return sin(atan2(x,y)*20.0f);
}

//Perlin noise by perlin Texture
sampler2D _PerlinTex;

float unity_perlinnoise(float u, float v)
{
    return tex2Dlod(_PerlinTex,float4(u,v,0,0)/25.0f).r;
}