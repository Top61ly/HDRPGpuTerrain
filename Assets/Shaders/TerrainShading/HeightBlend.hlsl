
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
    float4 maskedHeights = (heights - GetMinHeight(heights)) * blendMask.argb;

    float maxHeight = GetMaxHeight(maskedHeights);
    // Make sure that transition is not zero otherwise the next computation will be wrong.
    // The epsilon here also has to be bigger than the epsilon in the next computation.
    float transition = max(heightTransition, 1e-5);

    // The goal here is to have all but the highest layer at negative heights, then we add the transition so that if the next highest layer is near transition it will have a positive value.
    // Then we clamp this to zero and normalize everything so that highest layer has a value of 1.
    maskedHeights = maskedHeights - maxHeight.xxxx;
    // We need to add an epsilon here for active layers (hence the blendMask again) so that at least a layer shows up if everything's too low.
    maskedHeights = (max(0, maskedHeights + transition) + 1e-6) * blendMask.argb;

    // Normalize
    maxHeight = GetMaxHeight(maskedHeights);
    maskedHeights = maskedHeights / max(maxHeight.xxxx, 1e-6);

    return maskedHeights.yzwx;
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

    UNITY_UNROLL
    for (int i = 3; i >= 0; --i)
    {
        outWeights[i] = min(masks[i], (1.0 - weightsSum));
        weightsSum = saturate(weightsSum + masks[i]);
    }
}

void ComputeMaskWeights_float(float4 inputMasks, out float4 outWeights)
{
    ComputeMaskWeights(inputMasks, outWeights);
}