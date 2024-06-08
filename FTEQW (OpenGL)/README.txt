About HSV Dither 1.2
----------------------------------------------
HSV Dither is a color boosting, banding, and dithering shader. It operates on the color and brightness channels independently and non-linearly.


Installation and Use
----------------------------------------------
To install this shader, move the "HSVDither.pk3" file into the "id1" directory within the FTEQW directory. To use this shader, either add "r_postprocshader hsvdither" text to your fte.cfg, autoexec.cfg file, or when the game is loaded open the console with the "'" key and type the command in. This only works with OpenGL rendering with FTEQW. Once the shader is loaded in FTEQW you can use these console variables to cusomize the shader:

r_hsvd_brightness is a brightness adjustment via the V value of HSV. A value of one is no change, greater than one increases brightness, and less than one decreases brightness. 
r_hsvd_saturation is a saturation adjustment via the S value of HSV. A value of one is no change, greater than one increases saturation, and less than one decreases saturation.
r_hsvd_curve is the amount to non-linearly skew brightness banding. Higher numbers have smoother darks and band brights more, which is good for dark games.
r_hsvd_blevels is the brightness levels plus 1 (black). The lower the number, the more more bands and less brightness levels. 
r_hsvd_bdither is the type of brightness dither to use: 0 for bayer 2x2, 1 for bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, 7 for grid, 8 for interleaved gradient noise, 9 for tate, 10 for zigzag, 11 for diagonal, and 12 for none.
r_hsvd_clevels is the number of color levels. The lower the number, the more more bands and less colors used. 
r_hsvd_cdither is the type of color dither to use: 0 for bayer 2x2, 1 for bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, 7 for grid, 8 for interleaved gradient noise, 9 for tate, 10 for zigzag, 11 for diagonal, and 12 for none.
r_hsvd_scale is the pixel size of the dither. This can be done in combination with an in-engine pixel size setting.


Credits and Links
----------------------------------------------
Color banding learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
HSV functions learned from this answer by sam hocevar: https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
Bayer dithering learned from code by hughsk: https://github.com/hughsk/glsl-dither
Noise dithering learned from this code: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
ILG Noise dithering learned from: http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare  
GZDoom implementation based on code from Molecicco, IDDQD1337, and proydoha

Twitter: https://twitter.com/immorpher64
YouTube: https://www.youtube.com/c/Immorpher