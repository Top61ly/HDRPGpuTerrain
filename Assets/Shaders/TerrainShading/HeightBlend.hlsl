
// float Min3(float a, float b, float c)
// {
//     return min(min(a,b),c);
// }

// float Max3(float a, float b, float c)
// {
//     return max(max(a,b),c);
// }

float GetMinHeight(float4 heights)
{
    return min(Min3(heights.r, heights.g, heights.b), heights.a);
}

float GetMaxHeight(float4 heights)
{
    return max(Max3(heights.r, heights.g, heights.b), heights.a);
}

// Returns layering blend mask after application of height based blend.
float4 ApplyHeightBlend(float4 heights, float4 blendMask, float heightTransition)
{
    // We need to mask out inactive layers so that their height does not impact the result.
    // First we make every value positive by substracting the minimum value.
    // Otherwise multiplicating by blendMask can invert negative heights.
    // For example, 2 heights value of -10.0 and -5 multiplied by blend mask 0.1 and 1.0 (intent is to give LESS importance to the first value) makes the first value heigher
    float4 maskedHeights = (heights - GetMinHeight(heights)) * blendMask.rgba;

    float maxHeight = GetMaxHeight(maskedHeights);
    // Make sure that transition is not zero otherwise the next computation will be wrong.
    // The epsilon here also has to be bigger than the epsilon in the next computation.
    float transition = max(heightTransition, 1e-5);

    // The goal here is to have all but the highest layer at negative heights, then we add the transition so that if the next highest layer is near transition it will have a positive value.
    // Then we clamp this to zero and normalize everything so that highest layer has a value of 1.
    maskedHeights = maskedHeights - maxHeight.xxxx;
    // We need to add an epsilon here for active layers (hence the blendMask again) so that at least a layer shows up if everything's too low.
    maskedHeights = (max(0, maskedHeights + transition) + 1e-6) * blendMask.rgba;

    // Normalize
    maxHeight = GetMaxHeight(maskedHeights);
    maskedHeights = maskedHeights / max(maxHeight.xxxx, 1e-6);

    return maskedHeights.xyzw;
}

void ComputeMaskWeights(float4 inputMasks, out float4 outWeights)
{
    float masks[4];
    masks[0] = inputMasks.r;
    masks[1] = inputMasks.g;
    masks[2] = inputMasks.b;
    masks[3] = inputMasks.a;

    // calculate weight of each layers
    // Algorithm is like this:
    // Top layer have priority on others layers
    // If a top layer doesn't use the full weight, the remaining can be use by the following layer.
    float weightsSum = 0.0;

    [unroll]
    for (int i = 3; i >= 0; --i)
    {
        outWeights[i] = min(masks[i], (1.0 - weightsSum));
        weightsSum = saturate(weightsSum + masks[i]);
    }
}

void Compute8LayerMaskWeights(float4 blendMasks0, float4 blendMasks1, out float4 outWeights0, out float4 outWeights1)
{
    float weights[8];
    weights[0] = blendMasks0.x;
    weights[1] = blendMasks0.y;
    weights[2] = blendMasks0.z;
    weights[3] = blendMasks0.w;
    weights[4] = blendMasks1.x;
    weights[5] = blendMasks1.y;
    weights[6] = blendMasks1.z;
    weights[7] = blendMasks1.w;
    
    float outWeights[8];

    float weightsSum = 0;
    [unroll]
    for (int i = 7; i >= 0; --i)
    {
        outWeights[i] = min(weights[i], (1.0 - weightsSum));
        weightsSum = saturate(weightsSum + weights[i]);
    }

    float4  weights0 = { outWeights[0], outWeights[1], outWeights[2], outWeights[3] };
    float4  weights1 = { outWeights[4], outWeights[5], outWeights[6], outWeights[7] };
    outWeights0 = weights0;
    outWeights1 = weights1;
    //outWeights0 = {outWeights[0], outWeights[1], outWeights[2], outWeights[3]};
    //outWeights1 = {outWeights[4], outWeights[5], outWeights[6], outWeights[7]};
}

void HeightBlend2Layer_float(float2 heights, float2 blendMask, float heightTransition, out float2 mask)
{
    float2 maskedHeights = (heights -min(heights.x,heights.y)) * blendMask.yx;
    float maxHeight = max(maskedHeights.x, maskedHeights.y);
    float transition = max(heightTransition, 1e-5);

    maskedHeights = maskedHeights - maxHeight.xx;

    maskedHeights = (max(0, maskedHeights+transition)+1e-6) * blendMask.yx;
    maxHeight = max(maskedHeights.x,maskedHeights.y);
    maskedHeights = maskedHeights / max(maxHeight.xx, 1e-6);
    mask = maskedHeights.xy;
}

void ComputeMaskWeights_float(float4 inputMasks, out float4 outWeights)
{
    ComputeMaskWeights(inputMasks, outWeights);
}

float GetSumHeight(float4 heights0, float4 heights1)
{
    float sumHeight = heights0.x;
    sumHeight += heights0.y;
    sumHeight += heights0.z;
    sumHeight += heights0.w;
    sumHeight += heights1.x;
    sumHeight += heights1.y;
    sumHeight += heights1.z;
    sumHeight += heights1.w;
    return sumHeight;
}

void HeightBlend8Layers_float(float4 heights0, float4 heights1, float4 blendMask, float4 blendMask1, float heightTransition, 
                            out float4 outWeights, out float4 outWeights1)
{
    float masks[8];
    masks[0] = blendMask.x; masks[1] = blendMask.y; masks[2] = blendMask.z; masks[3] = blendMask.w;
    masks[4] = blendMask1.x; masks[5] = blendMask1.y; masks[6] = blendMask1.z; masks[7] = blendMask1.w;
    
    float tmpWeights[8];
    float weightsSum = 0;
    [unroll]
    for (int i = 7; i >= 0; --i)
    {
        tmpWeights[i] = min(masks[i], (1.0 - weightsSum));
        weightsSum = saturate(weightsSum + masks[i]);
    }

    float4 tmpBlend0 = { tmpWeights[0], tmpWeights[1], tmpWeights[2], tmpWeights[3]};
    float4 tmpBlend1 = { tmpWeights[4], tmpWeights[5], tmpWeights[6], tmpWeights[7]};

    blendMask = tmpBlend0;
    blendMask1 = tmpBlend1;

    float heights[8];
    heights[0] = heights0.x; heights[1] = heights0.y; heights[2] = heights0.z; heights[3] = heights0.w;
    heights[4] = heights1.x; heights[5] = heights1.y; heights[6] = heights1.z; heights[7] = heights1.w;

    float maxHeight = heights[0];
    maxHeight = max(maxHeight, heights[1]);
    maxHeight = max(maxHeight, heights[2]);
    maxHeight = max(maxHeight, heights[3]);
    maxHeight = max(maxHeight, heights[4]);
    maxHeight = max(maxHeight, heights[5]);
    maxHeight = max(maxHeight, heights[6]);
    maxHeight = max(maxHeight, heights[7]);
    
    // Make sure that transition is not zero otherwise the next computation will be wrong.
    // The epsilon here also has to be bigger than the epsilon in the next computation.
    float transition = max(heightTransition, 1e-5);

    // The goal here is to have all but the highest layer at negative heights, then we add the transition so that if the next highest layer is near transition it will have a positive value.
    // Then we clamp this to zero and normalize everything so that highest layer has a value of 1.
    float4 weightedHeights0 = { heights[0], heights[1], heights[2], heights[3] };
    weightedHeights0 = weightedHeights0 - maxHeight.xxxx;
    // We need to add an epsilon here for active layers (hence the blendMask again) so that at least a layer shows up if everything's too low.
    weightedHeights0 = (max(0, weightedHeights0 + transition) + 1e-6) * blendMask;

    float4 weightedHeights1 = { heights[4], heights[5], heights[6], heights[7] };
    weightedHeights1 = weightedHeights1 - maxHeight.xxxx;
    weightedHeights1 = (max(0, weightedHeights1 + transition) + 1e-6) * blendMask1;

    // Normalize
    float sumHeight = GetSumHeight(weightedHeights0, weightedHeights1);
    Compute8LayerMaskWeights(weightedHeights0 / sumHeight.xxxx,weightedHeights1 / sumHeight.xxxx, outWeights, outWeights1);
}

void ComputeHeightBlendMask_float(float4 heights, float4 inputMasks, float heightTransition, out float4 outWeights)
{
    float4 mask = ApplyHeightBlend(heights, inputMasks, heightTransition);
    ComputeMaskWeights(mask, outWeights);
}