// ---------------------------------------------------------------------
// About HSV Dither 1.1

// HSV Dither is a color boosting, banding and dithering shader. It operates on the color and brightness channels independently and non-linearly.
// See user defined values section to customize this shader and learn more about its capabilities. The effects are enhanced if you pair this with increased pixel sizes.

// GZDoom implementation based on code from Molecicco, IDDQD1337, and proydoha
// Twitter: https://twitter.com/immorpher64
// YouTube: https://www.youtube.com/c/Immorpher

// ---------------------------------------------------------------------
// User defined values

float brightness = 1; // Non-linear brightness boost by boosting the V value of HSV.
float saturation = 1; // Non-linear saturation boost by boosting the S value of HSV.
float curve = 2; // Amount to non-linearly skew brightness banding. Higher numbers have smoother darks and band brights more, which is good for dark games.
float blevels = 31; // Brightness levels plus 1 (black). The lower the number, the more more bands and less brightness levels. 
int bdither = 3; // Brightness dither: 0 for Bayer 2x2, 1 for Bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, 7 for grid, 8 for interleaved gradient noise, 9 for tate, 10 for zigzag, and 11 for none.
float clevels = 15; // Color levels plus 1. The lower the number, the more more bands and less colors used. 
int cdither = 4; // Color dither: 0 for Bayer 2x2, 1 for Bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, 7 for grid, 8 for interleaved gradient noise, 9 for tate, 10 for zigzag, and 11 for none.
int ditherscale = 2; // Pixel size of the dither. This can be done in combination with an in-engine pixel size setting.


// ---------------------------------------------------------------------
// HSV functions learned from this answer by sam hocevar: https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl

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

// Scanline dithering inspired by bayer style
float scanline(vec2 position) {
	int y = int(mod(position.y, 2.0)); // restrict to 2 pixel increments vertically

	// define scanline array of 2 values
	float scanline[2] = float[2](0.333,0.666);
	
	// Find and adjust the limit value to scale the dithering
	return scanline[y]; // return the limit
}

// Tate (vertical) dithering inspired by scanline
float tate(vec2 position) {
	int x = int(mod(position.x, 2.0)); // restrict to 2 pixel increments vertically

	// define tate array of 2 values
	float tate[2] = float[2](0.333,0.666);
	
	// Find and adjust the limit value to scale the dithering
	return tate[x]; // return the limit
}

// Checker 2x2 dither inspired by bayer 2x2
float checker(vec2 position) {
	int x = int(mod(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(mod(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array

	// define checker 2x2 array of 4 values
	float check[4] = float[4](0.333,0.666,0.666,0.333);
	
	// Find and adjust the limit value to scale the dithering
	return check[index]; // return the limit
}

// Grid 2x2 dither inspired by bayer 2x2
float grid2x2(vec2 position) {
	int x = int(mod(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(mod(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array

	// define grid 2x2 array of 4 values
	float grid[4] = float[4](0.75,0.5,0.5,0.25);
	
	// Find and adjust the limit value to scale the dithering
	return grid[index]; // return the limit
}

// Bayer 2x2 dither learned from code by hughsk: https://github.com/hughsk/glsl-dither
float bayer2x2(vec2 position) {
	int x = int(mod(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(mod(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array

	// define bayer 2x2 array of 4 values
	float bayer[4] = float[4](0.2,0.6,0.8,0.4);
	
	// Find and adjust the limit value to scale the dithering
	return bayer[index]; // return the limit
}

// Magic Square 3x3 dither inspired by https://en.wikipedia.org/wiki/Magic_square
float magic3x3(vec2 position) {
	int x = int(mod(position.x, 3.0)); // restrict to 3 pixel increments horizontally
	int y = int(mod(position.y, 3.0)); // restrict to 3 pixel increments vertically
	int index = x + y * 3; // determine position in magic square array
	
	// define magic square 3x3 array of 9 values
	float magic[9] = float[9](0.2,0.7,0.6,0.9,0.5,0.1,0.4,0.3,0.8);
		
	// Find and adjust the limit value to scale the dithering
	return magic[index]; // return the limit
}

// ZigZag dither related to magic square
float zigzag(vec2 position) {
	int x = int(mod(position.x, 4.0)); // restrict to 4 pixel increments horizontally
	int y = int(mod(position.y, 4.0)); // restrict to 4 pixel increments vertically
	int index = x + y * 4; // determine position in diagonal array
	
	// define zigzag array of 16 values
	float ziag[16] = float[16](0.75,0.5,0.25,0.5,0.5,0.75,0.5,0.75,0.25,0.5,0.75,0.5,0.5,0.25,0.5,0.25);
		
	// Find and adjust the limit value to scale the dithering
	return ziag[index]; // return the limit
}

// Bayer 8x8 dither learned from code by hughsk: https://github.com/hughsk/glsl-dither
float bayer8x8(vec2 position) {
	int x = int(mod(position.x, 8.0)); // restrict to 8 pixel increments horizontally
	int y = int(mod(position.y, 8.0)); // restrict to 8 pixel increments vertically
	int index = x + y * 8; // determine position in Bayer array
	
	// define bayer 8x8 array of 64 values
	float bayer[64] = float[64](0.01538461538,0.5076923077,0.1384615385,0.6307692308,0.04615384615,0.5384615385,0.1692307692,0.6615384615,0.7538461538,0.2615384615,0.8769230769,0.3846153846,0.7846153846,0.2923076923,0.9076923077,0.4153846154,0.2,0.6923076923,0.07692307692,0.5692307692,0.2307692308,0.7230769231,0.1076923077,0.6,0.9384615385,0.4461538462,0.8153846154,0.3230769231,0.9692307692,0.4769230769,0.8461538462,0.3538461538,0.06153846154,0.5538461538,0.1846153846,0.6769230769,0.03076923077,0.5230769231,0.1538461538,0.6461538462,0.8,0.3076923077,0.9230769231,0.4307692308,0.7692307692,0.2769230769,0.8923076923,0.4,0.2461538462,0.7384615385,0.1230769231,0.6153846154,0.2153846154,0.7076923077,0.09230769231,0.5846153846,0.9846153846,0.4923076923,0.8615384615,0.3692307692,0.9538461538,0.4615384615,0.8307692308,0.3384615385);
	
	return bayer[index]; // return the comparison value
}

// ILG Noise learned from: http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare
float ilgnoise(vec2 position) {
	vec2 wavenum = vec2(0.06711056,0.00583715); // screen position noise
	
	return fract(52.9829189*dot(wavenum,position)); // return the limit
}

// Static noise based dither roughly learned from: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
float staticnoise(vec2 position){ 
	vec2 wavenum = vec2(78.233,12.9898)+ilgnoise(position); // screen position noise
	
	// Get random number based on oscillating sine
	return fract(sin(dot(position,wavenum))*43758.5453); // return the comparison value
}

// Motion noise based dither roughly learned from: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
float motionnoise(vec2 position){ 
	vec2 wavenum = vec2(78.233,12.9898)+ilgnoise(position); // screen position noise
	
	// Alternate oscillations
	wavenum = wavenum + sin(float(timer)*vec2(34.989854,50.2336357));
	
	// Get random number based on oscillating sine
	return fract(sin(dot(position,wavenum))*43758.5453); // return comparison value
}


// ---------------------------------------------------------------------
// Banding with addition of dither

// Quantization learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
vec4 colround(vec2 position, vec4 color){ // Rounding function
	vec3 c = rgb2hsv(color.rgb); // Convert to HSV
	vec3 ditherlimit = vec3(0,0,0); // saturation and brightness dither probability
	bvec3 compare = bvec3(0,0,0); // boolean vector for comparison of dither limit vector
	
	// saturation / brightness boost
	c.yz = atan(c.yz*vec2(saturation,brightness))/atan(vec2(saturation,brightness)); // non-linear scale and normalize back to 1
	
	// apply non-linear brightness banding
	c.z = atan(c.z*curve)/atan(curve); // non-linear scale the colors before banding	
	
	// Multiply the vector by the level value for banding
	c *= vec3(clevels+1,clevels,blevels); // color levels have +1 since both ends of hue are the same
	
	// round colors to bands
	vec3 cfloor = floor(c); // round down to lowest band
	vec3 cceil = ceil(c)-cfloor; // round up to higher band
	
	// determine color dither probability
	switch (cdither) {
		case 0: ditherlimit.x = bayer2x2(position); break; // Bayer 2x2 dither
		case 1: ditherlimit.x = bayer8x8(position); break; // Bayer 8x8 dither
		case 2: ditherlimit.x = staticnoise(position); break; // Static noise dither
		case 3: ditherlimit.x = motionnoise(position); break; // Motion dither
		case 4: ditherlimit.x = scanline(position); break; // Scanline dither
		case 5: ditherlimit.x = checker(position); break; // Checker dither
		case 6: ditherlimit.x = magic3x3(position); break; // Magic square dither
		case 7: ditherlimit.x = grid2x2(position); break; // Grid Dither
		case 8: ditherlimit.x = ilgnoise(position); break; // ILG Noise Dither
		case 9: ditherlimit.x = tate(position); break; // Tate Dither
		case 10: ditherlimit.x = zigzag(position); break; // ZigZag Dither
		case 11: ditherlimit.x = 0.5; break; // None
	}
	
	ditherlimit.y = ditherlimit.x; // Hue and saturation have same ditherlimit
	
	// determine brightness dither probability
	switch (bdither) {
		case 0: ditherlimit.z = bayer2x2(position); break; // Bayer 2x2 dither
		case 1: ditherlimit.z = bayer8x8(position); break; // Bayer 8x8 dither
		case 2: ditherlimit.z = staticnoise(position); break; // Static noise dither
		case 3: ditherlimit.z = motionnoise(position); break; // Motion dither
		case 4: ditherlimit.z = scanline(position); break; // Scanline dither
		case 5: ditherlimit.z = checker(position); break; // Checker dither
		case 6: ditherlimit.z = magic3x3(position); break; // Magic square dither
		case 7: ditherlimit.z = grid2x2(position); break; // Grid Dither
		case 8: ditherlimit.z = ilgnoise(position); break; // ILG Noise Dither
		case 9: ditherlimit.z = tate(position); break; // Tate Dither
		case 10: ditherlimit.z = zigzag(position); break; // ZigZag Dither
		case 11: ditherlimit.z = 0.5; break; // None
	}
	
	// determine which color values to quantize up for dithering
	compare = greaterThan(c-cfloor,ditherlimit);
	
	// add dither
	c = cfloor + cceil*vec3(float(compare.x),float(compare.y),float(compare.z));
	
	// return back to normal color space
	c /= vec3(clevels+1,clevels,blevels); // re-normalize back to 0 to 1
	c.z = tan(atan(curve)*c.z)/curve; // Go back to linear brightness space
	c = hsv2rgb(c); // Convert to RGB
	
	return vec4(c,color.w);
}


// ---------------------------------------------------------------------
// Main operations

void main()
{
	brightness = (hsvd_brightness)/20; // grab brightness boost from GZDoom
	saturation = (hsvd_saturation)/20; // grab saturation boost from GZDoom
	curve = hsvd_curve; // grab banding curve from GZDoom
	blevels = hsvd_blevels - 1.0; // grab brightness levels from GZDoom
	bdither = hsvd_bdither; // grab brightness dither from GZDoom
	clevels = hsvd_clevels - 1.0; // grab saturation levels from GZDoom
	cdither = hsvd_cdither; // grab saturation dither from GZDoom
	ditherscale = hsvd_scale; // grab dither scale from GZDoom


	vec4 frag = texture(InputTexture, TexCoord); // grab color value from screen coordinate
	FragColor = colround(floor(gl_FragCoord.xy/float(ditherscale)), frag); // band it and dither it
}