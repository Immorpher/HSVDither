About HSV Dither 1.2
----------------------------------------------
HSV Dither is a color boosting, banding, and dithering shader. It operates on the color and brightness channels independently and non-linearly.


Installation and Use
----------------------------------------------
To use the shader you can load it like any other WAD into GZDoom, where you can drag and drop "HSVDither.pk3" onto the program, or use a launcher like ZDL. If you click on "Full options menu" in the GZDoom options menu, you will find these specific "Bandither" options

"Brightness" is a brightness adjustment via the V value of HSV. A value of one is no change, greater than one increases brightness, and less than one decreases brightness. 
"Saturation" is a saturation adjustment via the S value of HSV. A value of one is no change, greater than one increases saturation, and less than one decreases saturation.
"Banding Curve" is the ammount to non-linearly skew brightness banding. Higher numbers have smoother darks and band brights more, which is good for dark games.
"Brightness Levels" is the number of brightness levels. The lower the number, the more more bands and less brightness levels. 
"Brightness Dither" is the type of brightness dither to use: 0 for bayer 2x2, 1 for bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, 7 for grid, 8 for interleaved gradient noise, 9 for tate, 10 for zigzag, 11 for diagonal, and 12 for none.
"Color Levels" is the number of color levels. The lower the number, the more more bands and less colors used. 
"Color Dither" is the type of color dither to use: 0 for bayer 2x2, 1 for bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, 7 for grid, 8 for interleaved gradient noise, 9 for tate, 10 for zigzag, 11 for diagonal, and 12 for none.
"Dither Scale" is the pixel size of the dither. This can be done in combination with an in-engine pixel size setting.


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