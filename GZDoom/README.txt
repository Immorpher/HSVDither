About HSV Dither 1.0
----------------------------------------------
HSV Dither is a non-linear color boosting, banding and dithering shader. It leaves the hues untouched for good color reproduction while optionally boosting and dithering brightness and saturation.


Installation and Use
----------------------------------------------
To use the shader you can load it like any other WAD into GZDoom, where you can drag and drop "HSVDither.pk3" onto the program, or use a launcher like ZDL. If you click on "Full options menu" in the GZDoom options menu, you will find these specific "Bandither" options

"Brightness Boost" is a non-linear brightness boost by boosting the V value of HSV.
"Saturation Boost" is a non-linear saturation boost by boosting the S value of HSV.
"Banding Curve" is the ammount to non-linearly skew brightness banding. Higher numbers have smoother darks and band brights more, which is good for dark games.
"Brightness Levels" is the number of brightness levels. The lower the number, the more more bands and less brightness levels. 
"Brightness Dither" is the type of brightness dither to use: 0 for Bayer 2x2, 1 for Bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, 7 for grid dithering, and 8 for none.
"Saturation Levels" is the number of saturation levels. The lower the number, the more more bands and less colors used. 
"Saturation Dither" is the type of saturation dither to use: 0 for Bayer 2x2, 1 for Bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, 7 for grid dithering, and 8 for none.
"Dither Scale" is the pixel size of the dither. This can be done in combination with an in-engine pixel size setting.


Credits and Links
----------------------------------------------
Color banding learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
Bayer dithering learned from code by hughsk: https://github.com/hughsk/glsl-dither
Noise dithering learned from this code: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
HSV functions learned from this answer by sam hocevar: https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
GZDoom implementation based on code from Molecicco, IDDQD1337, and proydoha

Twitter: https://twitter.com/immorpher64
YouTube: https://www.youtube.com/c/Immorpher