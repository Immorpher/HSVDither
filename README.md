# HSV Dither
HSV Dither is a shader based on the hue, saturation, and value (HSV) method of color representation rather than red, green, blue (RGB) or even hue, saturation, brightness (HSB). I first noticed this in the code of Doom 64, where the sector lights were being boosted by this method. In modern days, I believe Nightdive’s KEX engine also utilizes this method for brightness boosting. In the HSV method, brightness can be used by boosting the value (V) component. Contrary to other methods, the HSV method preserves color saturation while boosting brightness. This is why Doom 64 is remembered for its deep colors and perhaps explains why KEX engine has some of its vibrant colors too. Here HSV Dither has options to boost both the brightness and saturation within the HSV method. This boosting is done non-linearly where higher brightnesses and saturations are not clipped, rather they are compressed.

This shader is also a continuation of my previous Bandither shader. Bandither is a shader which reduces the color output in RGB space akin to classic 90’s hardware. Keeping within the theme, HSV Dither operates color (hue/saturation) and value channels independently for banding and dithering. Often games which use lower-resolution assets can benefit from banding and dithering. I first noticed it with Quake 64 where banding caused sharp color edges to its texture which added some detail. When programming for the Nintendo 64 I noticed a set of additional dithers which add grit (specifically bayer, noise, and magic square) which are options here as well. You may recognize the bayer dither as hatch patterns in older graphics. Additionally, there are dithers for scanlines, grids, zig zags, and checkers. In total there are 13 dithers which can be combined to create various effects, including a CRT-like effect. Overall, this is a shader particularly suited for dark and colorful games, both modern and classic.

# Supported Software
GZDoom - https://zdoom.org/downloads  
VKDoom - https://vkdoom.org/  
FTEQW (OpenGL) - https://fte.triptohell.info/  
ReShade - https://reshade.me/  

For specific instructions for each software, refer to the corresponding sub-directory.  

# Credits and Links
Color banding learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154  
HSV functions learned from this answer by sam hocevar: https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl  
Bayer dithering learned from code by hughsk: https://github.com/hughsk/glsl-dither  
Noise dithering learned from this code: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner  
ILG Noise dithering learned from: http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare  
GZDoom implementation based on code from Molecicco, IDDQD1337, and proydoha  

Twitter: https://twitter.com/immorpher64  
YouTube: https://www.youtube.com/c/Immorpher  
