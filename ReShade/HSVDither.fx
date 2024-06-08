// ---------------------------------------------------------------------
// About HSV Dither 1.2

// HSV Dither is a color boosting, banding and dithering shader. It operates on the color and brightness channels independently and non-linearly.
// See user defined values section to customize this shader and learn more about its capabilities. The effects are enhanced if you pair this with increased pixel sizes.

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
	ui_min = 0; ui_max = 10;
	ui_label = "Brightness";
	ui_tooltip = "Brightness adjustment via the V value of HSV. A value of one is no change, greater than one increases brightness, and less than one decreases brightness.";
> = 2;

uniform float saturation < 
	ui_type = "slider";
	ui_min = 0; ui_max = 10;
	ui_label = "Saturation";
	ui_tooltip = "Saturation adjustment via the S value of HSV. A value of one is no change, greater than one increases saturation, and less than one decreases saturation.";
> = 2;

uniform float curve < 
	ui_type = "slider";
	ui_min = 0.001; ui_max = 10;
	ui_label = "Banding Curve";
	ui_tooltip = "Amount to non-linearly skew brightness banding. Higher numbers have smoother darks and band brights more, which is good for dark games.";
> = 2;

uniform int blevels < 
	ui_type = "slider";
	ui_min = 1; ui_max = 63;
	ui_label = "Brightness Levels";
	ui_tooltip = "Brightness levels plus 1 (black). The lower the number, the more more bands and less brightness levels.";
> = 23;

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
	           "ILG Noise\0"
	           "Tate\0"
	           "ZigZag\0"
	           "Diagonal\0"
	           "None\0";
> = 4;

uniform int clevels < 
	ui_type = "slider";
	ui_min = 1; ui_max = 63;
	ui_label = "Color Levels";
	ui_tooltip = "Color levels plus 1. The lower the number, the more more bands and less color levels.";
> = 23;

uniform int cdither <
	ui_type = "combo";
	ui_tooltip = "Dithering for the color levels.";
	ui_label = "Color Dither";
	ui_items = "Bayer 2x2\0"
	           "Bayer 8x8\0"
	           "Static Noise\0"
	           "Motion Noise\0"
	           "Scanline\0"
	           "Checker\0"
	           "Magic Square\0"
	           "Grid\0"
	           "ILG Noise\0"
	           "Tate\0"
	           "ZigZag\0"
	           "Diagonal\0"
	           "None\0";
> = 3;

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

// Scanline dithering inspired by bayer style
float scanline(float2 position) {
	int y = int(modulo(position.y, 2.0)); // restrict to 2 pixel increments vertically

	// define scanline array of 2 values
	float scanline[2] = {0.333,0.666};
	
	// Find and adjust the limit value to scale the dithering
	return scanline[y]; // return limits
}

// Tate (vertical) dithering inspired by scanline
float tate(float2 position) {
	int x = int(modulo(position.x, 2.0)); // restrict to 2 pixel increments vertically

	// define scanline array of 2 values
	float tate[2] = {0.333,0.666};
	
	// Find and adjust the limit value to scale the dithering
	return tate[x]; // return limits
}

// Checker 2x2 dither inspired by bayer 2x2
float checker(float2 position) {
	int x = int(modulo(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(modulo(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array

	// define checker 2x2 array of 4 values
	float check[4] = {0.333,0.666,0.666,0.333};
	
	// Find and adjust the limit value to scale the dithering
	return check[index]; // return
}

// Grid 2x2 dither inspired by bayer 2x2
float grid2x2(float2 position) {
	int x = int(modulo(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(modulo(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array

	// define grid 2x2 array of 4 values
	float grid[4] = {0.75,0.5,0.5,0.25};
	
	// Find and adjust the limit value to scale the dithering
	return grid[index]; // return the limit
}

// Bayer 2x2 dither roughly adapted and corrected from: https://github.com/hughsk/glsl-dither
float dither2x2(float2 position) {
	int x = int(modulo(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(modulo(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array

	// define bayer 2x2 array of 4 values
	float bayer[4] = {0.2,0.6,0.8,0.4};
	
	// Find and adjust the limit value to scale the dithering
	return bayer[index]; // return the limit
}

// Magic Square 3x3 dither inspired by https://en.wikipedia.org/wiki/Magic_square
float magic3x3(float2 position) {
	int x = int(modulo(position.x, 3.0)); // restrict to 3 pixel increments horizontally
	int y = int(modulo(position.y, 3.0)); // restrict to 3 pixel increments vertically
	int index = x + y * 3; // determine position in magic square array
	
	// define magic square 3x3 array of 9 values
	float magic[9] = {0.2,0.7,0.6,0.9,0.5,0.1,0.4,0.3,0.8};
		
	// Find and adjust the limit value to scale the dithering
	return magic[index]; // return the limit
}

// ZigZag dither related to magic square
float zigzag(float2 position) {
	int x = int(modulo(position.x, 4.0)); // restrict to 4 pixel increments horizontally
	int y = int(modulo(position.y, 4.0)); // restrict to 4 pixel increments vertically
	int index = x + y * 4; // determine position in diagonal array
	
	// define zigzag array of 16 values
	float ziag[16] = {0.75,0.5,0.25,0.5,0.5,0.75,0.5,0.75,0.25,0.5,0.75,0.5,0.5,0.25,0.5,0.25};
		
	// Find and adjust the limit value to scale the dithering
	return ziag[index]; // return the limit
}

// Bayer 8x8 dither roughly adapted from: https://github.com/hughsk/glsl-dither
float dither8x8(float2 position) {
	int x = int(modulo(position.x, 8.0)); // restrict to 8 pixel increments horizontally
	int y = int(modulo(position.y, 8.0)); // restrict to 8 pixel increments vertically
	int index = x + y * 8; // determine position in Bayer array
	
	// define bayer 8x8 array of 64 values
	float bayer[64] = {0.01538461538,0.5076923077,0.1384615385,0.6307692308,0.04615384615,0.5384615385,0.1692307692,0.6615384615,0.7538461538,0.2615384615,0.8769230769,0.3846153846,0.7846153846,0.2923076923,0.9076923077,0.4153846154,0.2,0.6923076923,0.07692307692,0.5692307692,0.2307692308,0.7230769231,0.1076923077,0.6,0.9384615385,0.4461538462,0.8153846154,0.3230769231,0.9692307692,0.4769230769,0.8461538462,0.3538461538,0.06153846154,0.5538461538,0.1846153846,0.6769230769,0.03076923077,0.5230769231,0.1538461538,0.6461538462,0.8,0.3076923077,0.9230769231,0.4307692308,0.7692307692,0.2769230769,0.8923076923,0.4,0.2461538462,0.7384615385,0.1230769231,0.6153846154,0.2153846154,0.7076923077,0.09230769231,0.5846153846,0.9846153846,0.4923076923,0.8615384615,0.3692307692,0.9538461538,0.4615384615,0.8307692308,0.3384615385};

	// Find and adjust the limit value to scale the dithering
	return bayer[index]; // return the limit
}

// ILG Noise learned from: http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare
float ilgnoise(float2 position) {
	float2 wavenum = float2(0.06711056,0.00583715); // screen position noise
	
	return frac(52.9829189*dot(wavenum,position)); // return the limit
}

// Diagonal dither adapted from ILG Noise
float diagonal(float2 position) {
	float2 wavenum = float2(0.2501,-0.1999); // screen position noise
	
	return 2*abs(frac(dot(wavenum,position))-0.5); // return the limit
}

// Static noise based dither roughly learned from: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
float staticnoise(float2 position){ 
	float2 wavenum = float2(78.233,12.9898)+ilgnoise(position); // screen position noise
	
	// Get random number based on oscillating sine
	return frac(sin(dot(position,wavenum))*43758.5453); // return the comparison value
}

// Motion noise based dither roughly learned from: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
float motionnoise(float2 position){ 
	float2 wavenum = float2(78.233,12.9898)+ilgnoise(position); // screen position noise
	
	// Alternate oscillations
	wavenum = wavenum + sin(float(Timer)*float2(34.989854,50.2336357));
	
	// Get random number based on oscillating sine
	return frac(sin(dot(position,wavenum))*43758.5453); // return comparison value
}


// ---------------------------------------------------------------------
// Color banding with addition of dither

// Quantization learned from: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
float3 colround(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 position = floor(texcoord.xy*BUFFER_SCREEN_SIZE/ditherscale);
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 c = rgb2hsv(color); // Convert to HSV
	float3 ditherlimit = float3(0,0,0); // saturation and brightness dither probability
	bool3 compare = bool3(0,0,0); // boolean vector for comparison of dither limit
	
	// saturation / brightness boost
	if (saturation > 1) { // saturate
		c.y = atan(c.y*(saturation-1))/atan(saturation-1); // non-linear scale and normalize back to 1	
	} else { // desaturate
		c.y *= saturation;
	}
	
	if (brightness > 1) { // brighten
		c.z = atan(c.z*(brightness-1))/atan(brightness-1); // non-linear scale and normalize back to 1
	} else { // darken
		c.z *= brightness;
	}
	
	// apply non-linear brightness banding
	c.z = atan(c.z*curve)/atan(curve); // non-linear scale the colors before banding	
	
	// Multiply the floattor by the level value for banding
	c *= float3(clevels+1,clevels,blevels); // color levels have +1 since both ends of hue are the same
	
	// round colors to bands
	float3 cfloor = floor(c); // round down to lowest band
	float3 cceil = ceil(c)-cfloor; // round up to higher band
	
	// determine saturation dither probability
	[branch] switch(cdither)
	{
		case 0: ditherlimit.x = dither2x2(position); break; // Bayer 2x2 dither
		case 1: ditherlimit.x = dither8x8(position); break; // Bayer 8x8 dither
		case 2: ditherlimit.x = staticnoise(position); break; // Static noise dither
		case 3: ditherlimit.x = motionnoise(position); break; // Motion dither
		case 4: ditherlimit.x = scanline(position); break; // Scanline dither
		case 5: ditherlimit.x = checker(position); break; // Checker dither
		case 6: ditherlimit.x = magic3x3(position); break; // Magic square dither
		case 7: ditherlimit.x = grid2x2(position); break; // Grid Dither
		case 8: ditherlimit.x = ilgnoise(position); break; // ILG Noise Dither
		case 9: ditherlimit.x = tate(position); break; // Tate Dither
		case 10: ditherlimit.x = zigzag(position); break; // ZigZag Dither
		case 11: ditherlimit.x = diagonal(position); break; // Diagonal Dither
		case 12: ditherlimit.x = 0.5; break; // None
	}
	
	ditherlimit.y = ditherlimit.x; // Hue and saturation have same ditherlimit
	
	// determine brightness dither probability
	[branch] switch(bdither)
	{
		case 0: ditherlimit.z = dither2x2(position); break; // Bayer 2x2 dither
		case 1: ditherlimit.z = dither8x8(position); break; // Bayer 8x8 dither
		case 2: ditherlimit.z = staticnoise(position); break; // Static noise dither
		case 3: ditherlimit.z = motionnoise(position); break; // Motion dither
		case 4: ditherlimit.z = scanline(position); break; // Scanline dither
		case 5: ditherlimit.z = checker(position); break; // Checker dither
		case 6: ditherlimit.z = magic3x3(position); break; // Magic square dither
		case 7: ditherlimit.z = grid2x2(position); break; // Grid Dither
		case 8: ditherlimit.z = ilgnoise(position); break; // ILG Noise Dither
		case 9: ditherlimit.z = tate(position); break; // Tate Dither
		case 10: ditherlimit.z = zigzag(position); break; // ZigZag Dither
		case 11: ditherlimit.z = diagonal(position); break; // Diagonal Dither
		case 12: ditherlimit.z = 0.5; break; // None
	}
	
	// determine which color values to quantize up for dithering
	compare = (c-cfloor) > ditherlimit;
	
	// add dither
	c = cfloor + cceil*compare;
	
	// return back to normal color space
	c /= float3(clevels+1,clevels,blevels); // re-normalize back to 0 to 1
	c.z = tan(atan(curve)*c.z)/curve; // Go back to linear brightness space
	c = hsv2rgb(c); // Convert to RGB
	
	return c;
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