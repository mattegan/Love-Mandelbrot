##Love2d Mandelbrot Browser

This is a small Love2d experiment with it's fragment (pixel) shader support. The fractals are rendered offscreen to an oversized buffer canvas, and then scaled down to the window size to achieve smoother results. Click to zoom in and out, pan and change some configuration with the keyboard. Targets Love 0.10.0.

####Controls
* `click` - zoom in on the area under the mouse pointer
* `scroll up/scroll down` - increase/decrease the zoom speed
* `up, down, left, right` - pan the viewport
* `i/k` - step through the available color maps
* `s` - save the fractal in a high resolution version to the Love2d [data directory](https://love2d.org/wiki/love.filesystem)
* `o/l` - increase/decrease sample rate (the multiple of the window size that the drawing canvas is sized to)

Most debug and utility output is directed towards a console window, so launching using the terminal is useful. Read [here](https://love2d.org/wiki/Debug) on how to do this on Windows.


####Bugs + Needed Features
* panning with the arrow keys doesn't work at the same speed at multiple zoom levels
* ability to set output width or height, output currently fails if the viewing window is not tall enough (the output height is hardcoded in, and for the output width to match the aspect ratio of a window that isn't very tall makes the rendering size very large)

###Adding and Changing Coloring

The `colorData.lua` file can be edited to change existing colorings or add more. They look better if they are cyclic, but they don't have to be. There is a note inside this file on how the existing colorings were generated.


####Nofix
* low precision at high zoom levels, a limitation of the OpenGL floating point precision, and this whole thing was created with that expectation

####Screenshots

![image](https://raw.githubusercontent.com/mattegan/Love-Mandelbrot/master/screenshots/1.png)

![image](https://raw.githubusercontent.com/mattegan/Love-Mandelbrot/master/screenshots/2.png)

![image](https://raw.githubusercontent.com/mattegan/Love-Mandelbrot/master/screenshots/3.png)

![image](https://raw.githubusercontent.com/mattegan/Love-Mandelbrot/master/screenshots/4.png)