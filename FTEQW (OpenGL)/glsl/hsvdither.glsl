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

!!ver 450
!!samps screen=0

// ---------------------------------------------------------------------
// User defined values

!!cvardf r_hsvd_brightness=1 // Non-linear brightness boost by boosting the V value of HSV.
!!cvardf r_hsvd_saturation=1 // Non-linear saturation boost by boosting the S value of HSV.
!!cvardf r_hsvd_curve=1 // Amount to non-linearly skew brightness banding. Higher numbers have smoother darks and band brights more, which is good for dark games.
!!cvardf r_hsvd_blevels=15 // Brightness levels plus 1 (black). The lower the number, the more more bands and less brightness levels. 
!!cvardf r_hsvd_bdither=3 // Brightness dither: 0 for Bayer 2x2, 1 for Bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, 7 for grid dithering, and 8 for none.
!!cvardf r_hsvd_slevels=3 // Saturation levels plus 1. The lower the number, the more more bands and less colors used. 
!!cvardf r_hsvd_sdither=4 // Saturation dither: 0 for Bayer 2x2, 1 for Bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, 7 for grid dithering, and 8 for none.
!!cvardf r_hsvd_scale=2 // Pixel size of the dither. This can be done in combination with an in-engine pixel size setting.


// ---------------------------------------------------------------------
// Header stuffs

#include "sys/defs.h"
varying vec2 texcoord;

#ifdef VERTEX_SHADER

	void main ()
	{
		texcoord = v_texcoord.xy;
		texcoord.y = 1.0 - texcoord.y;
		gl_Position = ftetransform();
	}

#endif


// ---------------------------------------------------------------------
// HSV functions learned from: https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl

// RGB to HSV
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV to RGB
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


// ---------------------------------------------------------------------
// Dithering functions

// Static noise based dither roughly learned from: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
float staticnoise(vec2 position){ 
	float limit = 0.0; // dither on or off
	vec2 wavenum = vec2(12.9898,78.233); // screen position noise
	
	// Get random number based on oscillating sine
    limit = fract(sin(dot(position,wavenum))*23758.5453);
	
	return limit; // return the limit
}

// Motion noise based dither roughly learned from: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
float motionnoise(vec2 position){ 
	float limit = 0.0; // dither on or off
	vec2 wavenum = vec2(12.9898,28.233); // screen position noise
	float timer = e_time; // Grab the FTE uniform for time
	
	// Alternate oscillations
	wavenum = wavenum + sin(float(timer)*vec2(34.9898,50.233));
	
	// Get random number based on oscillating sine
    limit = fract((sin(dot(position,wavenum)+float(timer)))*13758.5453);
	
	return limit; // return limit
}

// Scanline dithering inspired by bayer style
float scanline(vec2 position) {
	int y = int(mod(position.y, 2.0)); // restrict to 2 pixel increments vertically
	float limit = 0.0; // comparison place holder value

	// define scanline array of 2 values
	float scanline[2] = float[2](0.333,0.666);
	
	// Find and adjust the limit value to scale the dithering
	limit = scanline[y];
	
	return limit; // return the limit
}

// Checker 2x2 dither inspired by bayer 2x2
float checker(vec2 position) {
	int x = int(mod(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(mod(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array
	float limit = 0.0; // comparison place holder value

	// define checker 2x2 array of 4 values
	float check[4] = float[4](0.333,0.666,0.666,0.333);
	
	// Find and adjust the limit value to scale the dithering
	limit = check[index];
	
	return limit; // return the limit
}

// Grid 2x2 dither inspired by bayer 2x2
float grid2x2(vec2 position) {
	int x = int(mod(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(mod(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array
	float limit = 0.0; // comparison place holder value

	// define grid 2x2 array of 4 values
	float grid[4] = float[4](0.75,0.5,0.5,0.25);
	
	// Find and adjust the limit value to scale the dithering
	limit = grid[index];
	
	return limit; // return the limit
}

// Bayer 2x2 dither roughly adapted and corrected from: https://github.com/hughsk/glsl-dither
float dither2x2(vec2 position) {
	int x = int(mod(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(mod(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array
	float limit = 0.0; // comparison place holder value

	// define bayer 2x2 array of 4 values
	float bayer[4] = float[4](0.2,0.6,0.8,0.4);
	
	// Find and adjust the limit value to scale the dithering
	limit = bayer[index];
	
	return limit; // return the limit
}

// Magic Square 3x3 dither inspired by https://en.wikipedia.org/wiki/Magic_square
float magic3x3(vec2 position) {
	int x = int(mod(position.x, 3.0)); // restrict to 3 pixel increments horizontally
	int y = int(mod(position.y, 3.0)); // restrict to 3 pixel increments vertically
	int index = x + y * 3; // determine position in magic square array
	float limit = 0.0; // comparison place holder value
	
	// define magic square 3x3 array of 9 values
	float magic[9] = float[9](0.2,0.7,0.6,0.9,0.5,0.1,0.4,0.3,0.8);
		
	// Find and adjust the limit value to scale the dithering
	limit = magic[index];
	
	return limit; // return the limit
}

// Bayer 8x8 dither roughly adapted from: https://github.com/hughsk/glsl-dither
float dither8x8(vec2 position) {
	int x = int(mod(position.x, 8.0)); // restrict to 8 pixel increments horizontally
	int y = int(mod(position.y, 8.0)); // restrict to 8 pixel increments vertically
	int index = x + y * 8; // determine position in Bayer array
	float limit = 0.0; // comparison place holder value
	bvec4 compare = bvec4(0,0,0,0); // boolean vector for comparison of brightness vec4
	
	// define bayer 8x8 array of 64 values
	float bayer[64] = float[64](0.01538461538,0.5076923077,0.1384615385,0.6307692308,0.04615384615,0.5384615385,0.1692307692,0.6615384615,0.7538461538,0.2615384615,0.8769230769,0.3846153846,0.7846153846,0.2923076923,0.9076923077,0.4153846154,0.2,0.6923076923,0.07692307692,0.5692307692,0.2307692308,0.7230769231,0.1076923077,0.6,0.9384615385,0.4461538462,0.8153846154,0.3230769231,0.9692307692,0.4769230769,0.8461538462,0.3538461538,0.06153846154,0.5538461538,0.1846153846,0.6769230769,0.03076923077,0.5230769231,0.1538461538,0.6461538462,0.8,0.3076923077,0.9230769231,0.4307692308,0.7692307692,0.2769230769,0.8923076923,0.4,0.2461538462,0.7384615385,0.1230769231,0.6153846154,0.2153846154,0.7076923077,0.09230769231,0.5846153846,0.9846153846,0.4923076923,0.8615384615,0.3692307692,0.9538461538,0.4615384615,0.8307692308,0.3384615385);
	
	// Find and adjust the limit value to scale the dithering
	limit = bayer[index];
	
	return limit; // return the limit
}


// ---------------------------------------------------------------------
// Banding with addition of dither

// Quantization learned from: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
vec4 colround(vec2 position, vec4 color){ // Rounding function
	vec3 c = rgb2hsv(color.rgb); // Convert to HSV
	vec2 ditherlimit = vec2(0,0); // saturation and brightness dither probability
	bvec2 compare = bvec2(0,0); // boolean vector for comparison of dither limit vector
	
	// saturation / brightness boost
	c.yz = atan(c.yz*vec2(r_hsvd_saturation,r_hsvd_brightness))/atan(vec2(r_hsvd_saturation,r_hsvd_brightness)); // non-linear scale and normalize back to 1
	
	// apply non-linear brightness banding
	c.z = atan(c.z*r_hsvd_curve)/atan(r_hsvd_curve); // non-linear scale the colors before banding	
	
	// Multiply the vector by the level value for banding
	c.yz *= vec2(r_hsvd_slevels,r_hsvd_blevels);
	
	// round colors to bands
	vec2 cfloor = floor(c.yz); // round down to lowest band
	vec2 cceil = ceil(c.yz)-cfloor; // round up to higher band
	
	// determine saturation dither probability
	switch (r_hsvd_sdither) {
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
	switch (r_hsvd_bdither) {
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
	compare = greaterThan(c.yz-cfloor,ditherlimit);
	
	// add dither
	c.yz = cfloor + cceil*vec2(float(compare.x),float(compare.y));
	
	// return back to normal color space
	c.yz /= vec2(r_hsvd_slevels,r_hsvd_blevels); // re-normalize back to 0 to 1
	c.z = tan(atan(r_hsvd_curve)*c.z)/r_hsvd_curve; // Go back to linear brightness space
	c = hsv2rgb(c); // Convert to RGB
	
	return vec4(c,color.w);
}


// ---------------------------------------------------------------------
// Main operations

uniform sampler2D bgl_RenderedTexture; // get screen texture

#ifdef FRAGMENT_SHADER
	void main() {	
		vec4 color = texture(s_screen, texcoord.xy); // grab color value from screen coordinate
		color = colround(floor(gl_FragCoord.xy/r_hsvd_scale), color); // band it and dither it
		gl_FragColor = color; // apply color to screen
	}
#endif