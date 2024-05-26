// ---------------------------------------------------------------------
// About HSV Dither 1.0

// HSV Dither is a non-linear color boosting, banding and dithering shader. It leaves the hues untouched for good color reproduction while optionally boosting and dithering brightness and saturation.
// See user defined values section to customize this shader and learn more about its capabilities. The effects are enhanced if you pair this with increased pixel sizes.

// Color banding learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
// Bayer dithering learned from code by hughsk: https://github.com/hughsk/glsl-dither
// Noise dithering learned from this code: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
// HSV functions learned from this answer by sam hocevar: https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
// GZDoom implementation based on code from Molecicco, IDDQD1337, and proydoha
// Twitter: https://twitter.com/immorpher64
// YouTube: https://www.youtube.com/c/Immorpher


// --------------------------------------------------------------------
// Header data for reshade

// Get Reshade definitions
#include "ReShade.fxh"

// Sample the screen
sampler Linear
{
	Texture = ReShade::BackBufferTex;
	SRGBTexture = true;
};

// Grab time
uniform float Timer < source = "timer"; >;


// ---------------------------------------------------------------------
// User defined values for UI

uniform float brightness < 
	ui_type = "slider";
	ui_min = 0.001; ui_max = 10;
	ui_label = "Brightness Boost";
	ui_tooltip = "Non-linear brightness boost by boosting the V value of HSV.";
> = 1;

uniform float saturation < 
	ui_type = "slider";
	ui_min = 0.001; ui_max = 10;
	ui_label = "Saturation Boost";
	ui_tooltip = "Non-linear saturation boost by boosting the S value of HSV.";
> = 1;

uniform float curve < 
	ui_type = "slider";
	ui_min = 0.001; ui_max = 10;
	ui_label = "Banding Curve";
	ui_tooltip = "Amount to non-linearly skew brightness banding. Higher numbers have smoother darks and band brights more, which is good for dark games.";
> = 1;

uniform int blevels < 
	ui_type = "slider";
	ui_min = 1; ui_max = 63;
	ui_label = "Brightness Levels";
	ui_tooltip = "Brightness levels plus 1 (black). The lower the number, the more more bands and less brightness levels.";
> = 15;

uniform int bdither <
	ui_type = "combo";
	ui_tooltip = "Dithering for the brightness levels.";
	ui_label = "Brightness Dither";
	ui_items = "Bayer 2x2\0"
	           "Bayer 8x8\0"
	           "Static Noise\0"
	           "Motion Noise\0"
	           "Scanline\0"
	           "Checker\0"
	           "Magic Square\0"
	           "Grid\0"
	           "None\0";
> = 3;

uniform int slevels < 
	ui_type = "slider";
	ui_min = 1; ui_max = 63;
	ui_label = "Saturation Levels";
	ui_tooltip = "Brightness levels plus 1 (black). The lower the number, the more more bands and less brightness levels.";
> = 3;

uniform int sdither <
	ui_type = "combo";
	ui_tooltip = "Saturation levels plus 1. The lower the number, the more more bands and less colors used.";
	ui_label = "Saturation Dither";
	ui_items = "Bayer 2x2\0"
	           "Bayer 8x8\0"
	           "Static Noise\0"
	           "Motion Noise\0"
	           "Scanline\0"
	           "Checker\0"
	           "Magic Square\0"
	           "Grid\0"
	           "None\0";
> = 4;

uniform int ditherscale < 
	ui_type = "slider";
	ui_min = 1; ui_max = 10;
	ui_label = "Dither Scale";
	ui_tooltip = "Pixel size of the dither. This can be done in combination with an in-engine pixel size setting.";
> = 2;

// ---------------------------------------------------------------------
// HSV functions learned from: https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl

// RGB to HSV
float3 rgb2hsv(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV to RGB
float3 hsv2rgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


// ---------------------------------------------------------------------
// Dithering functions

// definite modulo operator for hlsl, since online documentation aint great
float modulo(float x, float y) {
	return x - y * trunc(x/y);
}

// Static noise based dither roughly learned from: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
float staticnoise(float2 position){ 
	float limit = 0.0; // dither on or off
	float2 wavenum = float2(12.9898,78.233); // screen position noise
	
	// Get random number based on oscillating sine
    limit = frac(sin(dot(position,wavenum))*23758.5453);
	
	return limit; // return the limit
}

// Motion noise based dither roughly learned from: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
float motionnoise(float2 position){ 
	float limit = 0.0; // dither on or off
	float2 wavenum = float2(12.9898,78.233); // screen position noise
	
	// Alternate oscillations
	wavenum = wavenum + sin(Timer*float2(34.9898,50.233));
	
	// Get random number based on oscillating sine
    limit = frac(sin(dot(position,wavenum)+Timer)*13758.5453);
	
	return limit; // return limit
}

// Scanline dithering inspired by bayer style
float scanline(float2 position) {
	int y = int(modulo(position.y, 2.0)); // restrict to 2 pixel increments vertically
	float limit = 0.0; // comparison place holder value

	// define scanline array of 2 values
	float scanline[2];
	scanline[0] = 0.333;
	scanline[1] = 0.666;
	
	// Find and adjust the limit value to scale the dithering
	limit = scanline[y];
	
	return limit; // return limits
}

// Checker 2x2 dither inspired by bayer 2x2
float checker(float2 position) {
	int x = int(modulo(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(modulo(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array
	float limit = 0.0; // comparison place holder value

	// define checker 2x2 array of 4 values
	float check[4];
	check[0] = 0.333;
	check[1] = 0.666;
	check[2] = 0.666;
	check[3] = 0.333;
	
	// Find and adjust the limit value to scale the dithering
	limit = check[index];
	
	return limit; // return
}

// Grid 2x2 dither inspired by bayer 2x2
float grid2x2(float2 position) {
	int x = int(modulo(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(modulo(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array
	float limit = 0.0; // comparison place holder value

	// define grid 2x2 array of 4 values
	float grid[4];
	grid[0] = 0.75;
	grid[1] = 0.5;
	grid[2] = 0.5;
	grid[3] = 0.25;
	
	// Find and adjust the limit value to scale the dithering
	limit = grid[index];
	
	return limit; // return the limit
}

// Bayer 2x2 dither roughly adapted and corrected from: https://github.com/hughsk/glsl-dither
float dither2x2(float2 position) {
	int x = int(modulo(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(modulo(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array
	float limit = 0.0; // comparison place holder value

	// define bayer 2x2 array of 4 values
	float bayer[4];
	bayer[0] = 0.2;
	bayer[1] = 0.6;
	bayer[2] = 0.8;
	bayer[3] = 0.4;
	
	// Find and adjust the limit value to scale the dithering
	limit = bayer[index];

	return limit; // return the limit
}

// Magic Square 3x3 dither inspired by https://en.wikipedia.org/wiki/Magic_square
float magic3x3(float2 position) {
	int x = int(modulo(position.x, 3.0)); // restrict to 3 pixel increments horizontally
	int y = int(modulo(position.y, 3.0)); // restrict to 3 pixel increments vertically
	int index = x + y * 3; // determine position in magic square array
	float limit = 0.0; // comparison place holder value
	
	// define magic square 3x3 array of 9 values
	float magic[9];
	magic[0] = 0.2;
	magic[1] = 0.7;
	magic[2] = 0.6;
	magic[3] = 0.9;
	magic[4] = 0.5;
	magic[5] = 0.1;
	magic[6] = 0.4;
	magic[7] = 0.3;
	magic[8] = 0.8;
		
	// Find and adjust the limit value to scale the dithering
	limit = magic[index];
	
	return limit; // return the limit
}

// Bayer 8x8 dither roughly adapted from: https://github.com/hughsk/glsl-dither
float dither8x8(float2 position) {
	int x = int(modulo(position.x, 8.0)); // restrict to 8 pixel increments horizontally
	int y = int(modulo(position.y, 8.0)); // restrict to 8 pixel increments vertically
	int index = x + y * 8; // determine position in Bayer array
	float limit = 0.0; // comparison place holder value
	bool4 compare = bool4(0,0,0,0); // boolean vector for comparison of brightness float4
	
	// define bayer 8x8 array of 64 values
	float bayer[64];
	bayer[0] = 0.0153846153846154;
	bayer[1] = 0.507692307692308;
	bayer[2] = 0.138461538461538;
	bayer[3] = 0.630769230769231;
	bayer[4] = 0.0461538461538462;
	bayer[5] = 0.538461538461538;
	bayer[6] = 0.169230769230769;
	bayer[7] = 0.661538461538462;
	bayer[8] = 0.753846153846154;
	bayer[9] = 0.261538461538462;
	bayer[10] = 0.876923076923077;
	bayer[11] = 0.384615384615385;
	bayer[12] = 0.784615384615385;
	bayer[13] = 0.292307692307692;
	bayer[14] = 0.907692307692308;
	bayer[15] = 0.415384615384615;
	bayer[16] = 0.2;
	bayer[17] = 0.692307692307692;
	bayer[18] = 0.0769230769230769;
	bayer[19] = 0.569230769230769;
	bayer[20] = 0.230769230769231;
	bayer[21] = 0.723076923076923;
	bayer[22] = 0.107692307692308;
	bayer[23] = 0.6;
	bayer[24] = 0.938461538461539;
	bayer[25] = 0.446153846153846;
	bayer[26] = 0.815384615384615;
	bayer[27] = 0.323076923076923;
	bayer[28] = 0.969230769230769;
	bayer[29] = 0.476923076923077;
	bayer[30] = 0.846153846153846;
	bayer[31] = 0.353846153846154;
	bayer[32] = 0.0615384615384615;
	bayer[33] = 0.553846153846154;
	bayer[34] = 0.184615384615385;
	bayer[35] = 0.676923076923077;
	bayer[36] = 0.0307692307692308;
	bayer[37] = 0.523076923076923;
	bayer[38] = 0.153846153846154;
	bayer[39] = 0.646153846153846;
	bayer[40] = 0.8;
	bayer[41] = 0.307692307692308;
	bayer[42] = 0.923076923076923;
	bayer[43] = 0.430769230769231;
	bayer[44] = 0.769230769230769;
	bayer[45] = 0.276923076923077;
	bayer[46] = 0.892307692307692;
	bayer[47] = 0.4;
	bayer[48] = 0.246153846153846;
	bayer[49] = 0.738461538461539;
	bayer[50] = 0.123076923076923;
	bayer[51] = 0.615384615384615;
	bayer[52] = 0.215384615384615;
	bayer[53] = 0.707692307692308;
	bayer[54] = 0.0923076923076923;
	bayer[55] = 0.584615384615385;
	bayer[56] = 0.984615384615385;
	bayer[57] = 0.492307692307692;
	bayer[58] = 0.861538461538462;
	bayer[59] = 0.369230769230769;
	bayer[60] = 0.953846153846154;
	bayer[61] = 0.461538461538462;
	bayer[62] = 0.830769230769231;
	bayer[63] = 0.338461538461539;

	// Find and adjust the limit value to scale the dithering
	limit = bayer[index];
	
	return limit; // return the limit
}


// ---------------------------------------------------------------------
// Color banding with addition of dither

// Quantization learned from: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
float4 colround(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 position = floor(texcoord.xy*BUFFER_SCREEN_SIZE/ditherscale);
	float4 color = tex2D(ReShade::BackBuffer, (position*ditherscale+floor(ditherscale*0.5))/BUFFER_SCREEN_SIZE).rgba;
	float3 c = rgb2hsv(color.rgb); // Convert to HSV
	float2 ditherlimit = float2(0,0); // saturation and brightness dither probability
	bool2 compare = bool2(0,0); // boolean vector for comparison of dither limit vector
	
	// saturation / brightness boost
	c.yz = atan(c.yz*float2(saturation,brightness))/atan(float2(saturation,brightness)); // non-linear scale and normalize back to 1
	
	// apply non-linear brightness banding
	c.z = atan(c.z*curve)/atan(curve); // non-linear scale the colors before banding	
	
	// Multiply the vector by the level value for banding
	c.yz *= float2(slevels,blevels);
	
	// round colors to bands
	float2 cfloor = floor(c.yz); // round down to lowest band
	float2 cceil = ceil(c.yz)-cfloor; // round up to higher band
	
	// determine saturation dither probability
	[branch] switch(sdither)
	{
		case 0: ditherlimit.x = dither2x2(position); break; // Bayer 2x2 dither
		case 1: ditherlimit.x = dither8x8(position); break; // Bayer 8x8 dither
		case 2: ditherlimit.x = staticnoise(position); break; // Static noise dither
		case 3: ditherlimit.x = motionnoise(position); break; // Motion dither
		case 4: ditherlimit.x = scanline(position); break; // Scanline dither
		case 5: ditherlimit.x = checker(position); break; // Checker dither
		case 6: ditherlimit.x = magic3x3(position); break; // Magic square dither
		case 7: ditherlimit.x = grid2x2(position); break; // Grid Dither
		case 8: ditherlimit.x = 0.5; break; // None
	}
	
	// determine brightness dither probability
	[branch] switch(bdither)
	{
		case 0: ditherlimit.y = dither2x2(position); break; // Bayer 2x2 dither
		case 1: ditherlimit.y = dither8x8(position); break; // Bayer 8x8 dither
		case 2: ditherlimit.y = staticnoise(position); break; // Static noise dither
		case 3: ditherlimit.y = motionnoise(position); break; // Motion dither
		case 4: ditherlimit.y = scanline(position); break; // Scanline dither
		case 5: ditherlimit.y = checker(position); break; // Checker dither
		case 6: ditherlimit.y = magic3x3(position); break; // Magic square dither
		case 7: ditherlimit.y = grid2x2(position); break; // Grid Dither
		case 8: ditherlimit.y = 0.5; break; // None
	}
	
	// determine which color values to quantize up for dithering
	compare = (c.yz-cfloor) > ditherlimit;
	
	// add dither
	c.yz = cfloor + cceil*compare;
	
	// return back to normal color space
	c.yz /= float2(slevels,blevels); // re-normalize back to 0 to 1
	c.z = tan(atan(curve)*c.z)/curve; // Go back to linear brightness space
	c = hsv2rgb(c); // Convert to RGB
	
	return float4(c,color.w);
}

// Main loop
technique HSVDither
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = colround;
	}
}