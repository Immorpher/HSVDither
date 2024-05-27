# HSV Dither
HSV Dither is a shader based on the hue, saturation, and value (HSV) method of color representation rather than red, green, blue (RGB) or even hue, saturation, brightness (HSB). I first noticed this in the code of Doom 64, where the sector lights were being boosted by this method. In modern days, I believe Nightdive’s KEX engine also utilizes this method for brightness boosting. In the HSV method, brightness can be used by boosting the value (V) component. Contrary to other methods, the HSV method preserves color saturation while boosting brightness. This is why Doom 64 is remembered for its deep colors and perhaps explains why KEX engine has some of its vibrant colors too. Here HSV Dither has options to boost both the brightness and saturation within the HSV method.

This shader is also a continuation of my previous Bandither shader. Bandither is a shader which reduces the color output in RGB space which emulates classic 90’s hardware such as the Playstation 1 and Voodoo graphics cards. Keeping within the theme, HSV Dither operates on the HSV color space. It leaves the hue channel unaltered, mostly leaving the color as intended. However the saturation and value channels can be banded and dithered independently. This can create various effects from adding some grit to creating a pseudo-CRT look. Overall, HSV Dither is a shader particularly suited for dark and colorful games, modern and classic.

# Supported Software
GZDoom - https://zdoom.org/downloads  
FTEQW (OpenGL) - https://fte.triptohell.info/  
ReShade - https://reshade.me/  

For specific instructions for each softare, refer to the corresponding sub-directory.  

# Credits and Links
Color banding learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154  
Bayer dithering learned from code by hughsk: https://github.com/hughsk/glsl-dither  
Noise dithering learned from this code: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner  
HSV functions learned from this answer by sam hocevar: https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl  
GZDoom implementation based on code from Molecicco, IDDQD1337, and proydoha  

Twitter: https://twitter.com/immorpher64  
YouTube: https://www.youtube.com/c/Immorpher  
