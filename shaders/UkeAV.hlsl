#include <renderer/RenderSetup.hlsl>

struct VS_INPUT
{
   float3 ssPosition   : POSITION;
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
};

struct VS_OUTPUT
{
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
   float4 ssPosition   : SV_POSITION;
};

struct PS_INPUT
{
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
};

sampler2D       baseTexture;
sampler2D       depthTexture;
sampler2D       normalTexture;

cbuffer LayerConstants
{
    float        startTime;
    float        amount;
};

/**
* Vertex shader.
*/  
VS_OUTPUT SFXBasicVS(VS_INPUT input)
{

   VS_OUTPUT output;

   output.ssPosition = float4(input.ssPosition, 1);
   output.texCoord   = input.texCoord + texelCenter;
   output.color      = input.color;

   return output;

}

float4 SFXDarkVisionPS(PS_INPUT input) : COLOR0
{

    // This is an exponent which is used to make the pulse front move faster when it gets
    // farther away from the viewer so that the effect doesn't take too long to complete.
    const float frontMovementPower     = 1.6;
    const float frontSpeed            = 18.0;
    const float pulseWidth            = 20.0;

    float2 texCoord = input.texCoord;

    float2 depth1    = tex2D(depthTexture, input.texCoord).rg;
    float4 inputPixel = tex2D(baseTexture, input.texCoord);
    
    if (amount == 0) {
        return inputPixel;
    }

    float x     = (input.texCoord.x - 0.5) * 2;
    float y     = (input.texCoord.y - 0.5) * 2;	
	float distanceSq	= x * x + y * y;
	
    // exp
	float fadeout = pow(2.71828182846, -depth1.r * 0.23 + 0.23);
	
    const float offset = 0.0005 + distanceSq * 0.005 * (1 + depth1.g);
	float  depth2 = tex2D(depthTexture, input.texCoord + float2( offset, 0)).rg;
	float  depth3 = tex2D(depthTexture, input.texCoord + float2(-offset, 0)).rg;
	float  depth4 = tex2D(depthTexture, input.texCoord + float2( 0,  offset)).rg;
	float  depth5 = tex2D(depthTexture, input.texCoord + float2( 0, -offset)).rg;


	float edge;
    float4 edgeColor;
   	
			edge = clamp(abs(depth2.r - depth1.r) +
					abs(depth3.r - depth1.r) +
					abs(depth4.r - depth1.r) +
					abs(depth5.r - depth1.r),
					0, 8);
					
    if (depth1.g > 0.5)
    {
		edge = clamp(pow(edge * 2, 2), 0.01, 2.0);
		
        if (depth1.r < 0.15){
            edgeColor = float4(0.2, 0.01, 0, 0);
        }
        else
        {
            edgeColor = float4(0.5, 0.08, 0.02, 0) + float4(1.0, 0.1, 0.0, 0) * (fadeout * 8);
        }
    }
    else
    {
		//edge = edge + fadeout;
		if (depth1.r == 0){
			edgeColor = float4(0.3, 0.0, 0.0, 0);
		}
		else{
			//edgeColor = float4(0.16+0.25*fadeout, 0.16+0.4*fadeout, 0.16+0.15*fadeout, 0) * 0.8;
			//edgeColor = float4(0.02+(0.02+(sin(4*fadeout)+1)/2)*fadeout, 0.06+(0.2+(sin(4*fadeout+120)+1)/2)*fadeout, 0.1+(0.06+(sin(4*fadeout+240)+1)/2)*fadeout, 0) * 0.66 + float4(0.02+0.05*fadeout,0.1+0.5*fadeout,0.05+0.2*fadeout,0)*0.33 ;
			//edgeColor = float4( 0.02, 0.26, 0.1, 0 ) * clamp(1.3+fadeout/14,0,1) + float4( 0.02, 0.1, 0.2, 0 ) * clamp(1.3-fadeout/14,0,1) * clamp(1-pow(fadeout/4,2),0,1) ;//) * clamp(1.32-(fadeout/1.6),0.2,1);
			edgeColor = float4( 0.02, 0.26, 0.1, 0 ) * clamp(fadeout*4,0,1) + float4( 0.02, 0.1, 0.2, 0 ) * clamp(1-fadeout*2.6,0,1) * clamp(fadeout*10,0.02,1) + float4( 0, 0, 0.07, 0 ) * (1-clamp(fadeout*10,0.02,1)) ;
		}
		
    }
    
    // Compute a pulse "front" that sweeps out from the viewer when the effect is activated.

    float wave  = cos(4 * x) + sin(4 * x);
   
    float front = pow( (time - startTime) * frontSpeed, frontMovementPower) + wave;
    float pulse = saturate((front - depth1.r * 1) / pulseWidth);
	
    if (pulse > 0)
    {
		const float kPulseFreq = 4;
		const float kEntityPulseSpeed = 1.5;
		const float kBaseMotionScalar = 0.5;
		const float kEntityMotionScalar = 1;
		
		float movement = (sin(time * kPulseFreq * (1.0 - depth1.g * kEntityPulseSpeed) - depth1.r * (kBaseMotionScalar + depth1.g * kEntityMotionScalar)) + 2) * 0.2;
		float saturation = max( max(abs(inputPixel.r - inputPixel.g), abs(inputPixel.r - inputPixel.b)), abs(inputPixel.b - inputPixel.g) );
		
		return inputPixel*0.3 + (max(inputPixel, edge) * edgeColor)*0.7;
    }
    else
    {
        return inputPixel;
    }
}