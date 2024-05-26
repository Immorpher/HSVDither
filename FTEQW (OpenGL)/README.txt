About HSV Dither 1.0
----------------------------------------------
HSV Dither is a non-linear color boosting, banding and dithering shader. It leaves the hues untouched for good color reproduction while optionally boosting and dithering brightness and saturation.


Installation and Use
----------------------------------------------
To install this shader, move the "HSVDither.pk3" file into the "id1" directory within the FTEQW directory. To use this shader, either add "r_postprocshader hsvdither" text to your fte.cfg, autoexec.cfg file, or when the game is loaded open the console with the "'" key and type the command in. This only works with OpenGL rendering with FTEQW. Once the shader is loaded in FTEQW you can use these console variables to cusomize the shader:

r_hsvd_brightness is a non-linear brightness boost by boosting the V value of HSV.
r_hsvd_saturation is a non-linear saturation boost by boosting the S value of HSV.
r_hsvd_curve is the amount to non-linearly skew brightness banding. Higher numbers have smoother darks and band brights more, which is good for dark games.
r_hsvd_blevels is the brightness levels plus 1 (black). The lower the number, the more more bands and less brightness levels. 
r_hsvd_bdither is the brightness dither used: 0 for Bayer 2x2, 1 for Bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, 7 for grid dithering, and 8 for none.
r_hsvd_slevels is the saturation levels plus 1. The lower the number, the more more bands and less colors used. 
r_hsvd_sdither is the saturation dither used: 0 for Bayer 2x2, 1 for Bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, 7 for grid dithering, and 8 for none.
r_hsvd_scale is the pixel size of the dither. This can be done in combination with an in-engine pixel size setting.


Credits and Links
----------------------------------------------
Color banding learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
Bayer dithering learned from code by hughsk: https://github.com/hughsk/glsl-dither
Noise dithering learned from this code: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
HSV functions learned from this answer by sam hocevar: https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
GZDoom implementation based on code from Molecicco, IDDQD1337, and proydoha

Twitter: https://twitter.com/immorpher64
YouTube: https://www.youtube.com/c/Immorpher