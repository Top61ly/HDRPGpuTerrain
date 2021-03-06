#ifndef __UTILITY__
#define __UTILITY__

#include "./InputStruct.hlsl"

struct BoundingBox
{
	float4 corners[8];
};

struct BoundingRect
{
	float2 minXY;
	float2 maxXY;
	float depth;
};

struct InstanceData
{
    float3x3 rotScale;
    float3 pos;
    float param;
/*
    float3 pos;
    float3 rot;
    float scaleXZ;
    float scaleY;*/
};

struct TerrainInstanceData
{
    float3 pos;
    float scale;
};

inline BoundingRect CreateBoundingRect(BoundingBox box)
{
	BoundingRect rect;

	[unroll]
	for (int i = 0; i < 8; i++)
		box.corners[i].xyz /= box.corners[i].w;

	rect.minXY = box.corners[0].xy;
	rect.maxXY = box.corners[0].xy;
	rect.depth = box.corners[0].z;

	[unroll]
	for (int m = 1; m < 8; m++)
	{
		rect.minXY.x = min(box.corners[m].x, rect.minXY.x);
		rect.minXY.y = min(box.corners[m].y, rect.minXY.y);
		rect.maxXY.x = max(box.corners[m].x, rect.maxXY.x);
		rect.maxXY.y = max(box.corners[m].y, rect.maxXY.y);
		rect.depth = min(box.corners[m].z, rect.depth);
	}

	rect.minXY.xy = rect.minXY.xy / 2.0 + 0.5;
	rect.maxXY.xy = rect.maxXY.xy / 2.0 + 0.5;
	rect.depth = rect.depth / 2.0 + 0.5;

	return rect;
}


inline BoundingBox CreateBoundingBox(float4x4 mvp, float3 min, float3 max)
{
	BoundingBox box;

    box.corners[0] = mul(mvp, float4(min.x, max.y, min.z, 1.0));
    box.corners[1] = mul(mvp, float4(min.x, max.y, max.z, 1.0));
    box.corners[2] = mul(mvp, float4(max.x, max.y, max.z, 1.0));
    box.corners[3] = mul(mvp, float4(max.x, max.y, min.z, 1.0));
    box.corners[4] = mul(mvp, float4(max.x, min.y, min.z, 1.0));
    box.corners[5] = mul(mvp, float4(max.x, min.y, max.z, 1.0));
    box.corners[6] = mul(mvp, float4(min.x, min.y, max.z, 1.0));
    box.corners[7] = mul(mvp, float4(min.x, min.y, min.z, 1.0));

	return box;
}


float4x4 GetRotationMatrix(float xRadian, float yRadian, float zRadian)
{
    float sina, cosa;
    sincos(xRadian, sina, cosa);

    float4x4 xMatrix;

    xMatrix[0] = float4(1, 0, 0, 0);
    xMatrix[1] = float4(0, cosa, -sina, 0);
    xMatrix[2] = float4(0, sina, cosa, 0);
    xMatrix[3] = float4(0, 0, 0, 1);

    sincos(yRadian, sina, cosa);

    float4x4 yMatrix;

    yMatrix[0] = float4(cosa, 0, sina, 0);
    yMatrix[1] = float4(0, 1, 0, 0);
    yMatrix[2] = float4(-sina, 0, cosa, 0);
    yMatrix[3] = float4(0, 0, 0, 1);

    sincos(zRadian, sina, cosa);

    float4x4 zMatrix;

    zMatrix[0] = float4(cosa, -sina, 0, 0);
    zMatrix[1] = float4(sina, cosa, 0, 0);
    zMatrix[2] = float4(0, 0, 1, 0);
    zMatrix[3] = float4(0, 0, 0, 1);

    return mul(mul(yMatrix, xMatrix), zMatrix);
}


float4x4 ToMatrix(InstanceData data)
{
    float4x4 mat;
    mat._11_21_31_41 = float4(data.rotScale._11_21_31, 0.0);
    mat._12_22_32_42 = float4(data.rotScale._12_22_32, 0.0);
    mat._13_23_33_43 = float4(data.rotScale._13_23_33, 0.0);
    mat._14_24_34_44 = float4(data.pos, 1.0);
    /*GetRotationMatrix(data.rot.x, data.rot.y, data.rot.z );
    mat._14_24_34 = data.pos;
    mat._11 *= data.scaleXZ;
    mat._22 *= data.scaleY;
    mat._33 *= data.scaleXZ;*/
    return mat;
}

float4x4 ToMatrix(TerrainInstanceData data)
{
    float4x4 mat;
    mat._11_21_31_41 = float4(data.scale,0.0,0.0,0.0);
    mat._12_22_32_42 = float4(0.0,data.scale,0.0,0.0);
    mat._13_23_33_43 = float4(0.0,0.0,data.scale,0.0);
    mat._14_24_34_44 = float4(data.pos, 1.0);
    return mat;
}

float4x4 Uint2ToMatrix(uint3 node)
{
    float4x4 mat;
    float scale = pow(2,node.z);
    float nodeCount = 5.0f*pow(2,5-node.z);
    float2 pos = ((float2)node+0.5f-nodeCount/2)*64.0f*scale;
    scale -= 0.1f;
    float3 position = float3(pos.x,0,pos.y);
    mat._11_21_31_41 = float4(scale,0.0,0.0,0.0);
    mat._12_22_32_42 = float4(0.0,scale,0.0,0.0);
    mat._13_23_33_43 = float4(0.0,0.0,scale,0.0);
    mat._14_24_34_44 = float4(position, 1.0);
    return mat;
}

float4x4 RenderPatchToMatrix(RenderPatch patch)
{
    float4x4 mat;
    float scale = pow(2, patch.lod);
    float2 pos = patch.position;
    //scale += 1.0f;
    scale -= 0.1f;
    float3 position = float3(pos.x,0,pos.y);
    mat._11_21_31_41 = float4(scale,0.0,0.0,0.0);
    mat._12_22_32_42 = float4(0.0,scale,0.0,0.0);
    mat._13_23_33_43 = float4(0.0,0.0,scale,0.0);
    mat._14_24_34_44 = float4(position, 1.0);
    return mat;
}

#endif