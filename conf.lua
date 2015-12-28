--------------------------------------------------------------------------------
-- Love2d configuration
--------------------------------------------------------------------------------
function love.conf(conf)

	conf.window.title = "mandelbrot viwer"

	--  the domain and range of the mandelbrot is (3.5, 2), for simplicity sake,
	--  the viewer window is created with this aspect ratio, this can be
	--	adjusted, without 'stretching' the fractal since the fractal calculates
	--  the range of the viewport using the current aspect ratio of the window
	conf.window.height = 500
	conf.window.width = conf.window.height * (3.5 / 2)

	conf.window.resizable = true
	
end
