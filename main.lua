--------------------------------------------------------------------------------
-- globals
--------------------------------------------------------------------------------
-- windowWidth, windowHeight and the window aspect ratio are used multiple times
-- in the program, so they're stored here in love.load() for handy use
windowWidth = 0
windowHeight = 0
aspectRatio = 0

--  the fragment shader used to render the fractal
shader = {}

--  the fractal is rendered to this canvas off-screen only whenever its
--  parameters are changed, this keeps the graphics card from being pegged
--  constantly, also keep track of this canvas' dimensions
fractalCanvas = {}
fractalCanvasWidth = 0
fractalCanvasHeight = 0

--  the index of the 'colorpack' to use on startup
colorPack = 2

--  this controls how large the rendering canvas and rendering size is, as a
--  multiple of the window size
oversample = 2

--  initial starting coordinates and domain (range is calculated in the shader
--  using the window's aspect ratio to avoid distortion of the fractal)
xCenter = -0.75;
yCenter = 0;
domain = 3.5;

--  the domain is multiplied times this when zooming, smaller numbers cause
--  zooming to occur faster
zoomSpeed = 0.98

--  controls if the current zoomspeed is displayed
displayZoomSpeed = true

--------------------------------------------------------------------------------
-- Love2d initialization
--------------------------------------------------------------------------------
function love.load(a)

    --  populate some of the configuration globals for use later
    windowWidth = love.graphics.getWidth()
    windowHeight = love.graphics.getHeight()
    aspectRatio = windowWidth / windowHeight

    --  load and execute the color data, which creates a "colors" global
    local colorData = love.filesystem.load("colorData.lua")
    colorData()

    --  create the fractal shader from the shader program
    shader = love.graphics.newShader("shader.frag")

    --  create the offscreen drawing canvas
    createCanvas()

    --  send the current colorPack to the shader
    sendColorPack(colorPack)

    --  draw the fractal to the canvas
    drawFractal(fractalCanvasWidth, fractalCanvasHeight, fractalCanvas)
end

--------------------------------------------------------------------------------
-- Love2d pre-frame update
--------------------------------------------------------------------------------
function love.update(dt)
    --  the mouse zooms the fractal in our out (left = in, right = out)
    if love.mouse.isDown(1, 2) then

        --  find the x and y point in the current fractal domain
        local x = love.mouse.getX()
        local y = love.mouse.getY()
        local range = domain / aspectRatio
        local xClick = xCenter + ((x / windowWidth) * domain) - (domain / 2)
        local yClick = yCenter + ((y / windowHeight) * range) - (range / 2)

        --  are we zooming in or out?
        if love.mouse.isDown(1) then
            domain = domain * zoomSpeed
        elseif love.mouse.isDown(2) then
            domain = domain / zoomSpeed
        end

        --  need to set a new center so that this point stays at the
        --  location of the click, instead of zooming in at the center, this is
        --  essentially the inverse of the previous calculation, just using
        --  the new domain after zooming in or out
        local range = domain / aspectRatio
        xCenter = xClick - ((x / windowWidth) * domain) + (domain / 2)
        yCenter = yClick - ((y / windowHeight) * range) + (range / 2)

        --  update the fractal in the offscreen buffer
        drawFractal(fractalCanvasWidth, fractalCanvasHeight, fractalCanvas)
    end

    local panRatio = 1000
    --  the arrow keys can be used to pan around the fractal
    --  TODO: implement accurate panning math, right now the panning appears to
    --        occur at different speeds at different zoom levels
    if love.keyboard.isDown("up", "down", "left", "right") then
        if love.keyboard.isDown("up") then
            yCenter = yCenter - ((zoomSpeed * domain) / panRatio)
        elseif love.keyboard.isDown("down") then
            yCenter = yCenter + ((zoomSpeed * domain) / panRatio)
        end

        if love.keyboard.isDown("left") then
            xCenter = xCenter - ((zoomSpeed * domain) / panRatio)
        elseif love.keyboard.isDown("right") then
            xCenter = xCenter + ((zoomSpeed * domain) / panRatio)
        end
        print(xCenter, yCenter, domain)
        drawFractal(fractalCanvasWidth, fractalCanvasHeight, fractalCanvas)
    end

end

--------------------------------------------------------------------------------
-- Love2d drawing
--------------------------------------------------------------------------------
function love.draw(dt)

    --  draw the fractal canvas, rescaling it to the window's size
    love.graphics.draw(fractalCanvas, 0, 0, 0, 1 / oversample)

    --  print the current zoom speed to the screen
    if displayZoomSpeed then
        local x = 5
        local y = windowHeight - 18
        love.graphics.print("zoom speed : " .. zoomSpeed, x, y, 0, 0.8)
    end

end

--------------------------------------------------------------------------------
-- Love2d event callbacks
--------------------------------------------------------------------------------
function love.resize()
    --  recalculate some of the configuration globals
    windowWidth = love.graphics.getWidth()
    windowHeight = love.graphics.getHeight()
    aspectRatio = windowWidth / windowHeight

    --  recreate the canvas and the canvas size globals
    createCanvas()

    --  redraw the fractal
    drawFractal(fractalCanvasWidth, fractalCanvasHeight, fractalCanvas)
end
function love.wheelmoved(x, y)

    --  adjust the zoom speed with a up or down scrolling
    zoomSpeed = math.min(zoomSpeed + (-0.0005 * y), 1)

end

function love.keypressed(key, scancode, isrepeat)

    --  the 'i' and 'k' keys can be used to index through the available
    --  color packs, after changing the index, the new colorPack is sent to
    --  the shader and then the fractal is redrawn
    if key == "i" or key == "k" then
        if key == "i" then
            colorPack = ((colorPack + 1) % table.maxn(colors))
        elseif key == "k" then
            colorPack = ((colorPack - 1) % table.maxn(colors))
        end
        print("Changed colorPack index to " .. colorPack)
        sendColorPack(colorPack)
        drawFractal(fractalCanvasWidth, fractalCanvasHeight, fractalCanvas)
    end

    --  's' initiates a save of the current window to the game directory
    --  which is platform dependent (check the Love2d docs for the location)
    if key == "s" then
        saveFractal()
    end

    --  the 'o' and 'l' keys can be used to increase or decrease the sample
    --  rate, this requires recreating the canvas and redrawing the fractal
    if key == "o" or key == "l" then
        if key == "o" then
            oversample = oversample + 1
        elseif key == "l" and not (oversample == 1) then
            oversample = oversample - 1
        end
        print("Changed oversample rate to " .. oversample)
        createCanvas()
        drawFractal(fractalCanvasWidth, fractalCanvasHeight, fractalCanvas)
    end
end

--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------
function createCanvas()
    --  the canvas needs to be oversample times the windowsize large
    fractalCanvasWidth = windowWidth * oversample
    fractalCanvasHeight = windowHeight * oversample

    -- create a canvas to the render fractal to offscreen
    fractalCanvas = love.graphics.newCanvas(fractalCanvasWidth, fractalCanvasHeight)
end

function drawFractal(width, height, drawCanvas, sendSize)

    --  send all of the information to the shader
    print(width, height, xCenter, yCenter, domain)
    print(drawCanvas)
    print(fractalCanvas)
    shader:send("window_width", width)
    shader:send("window_height", height)
    shader:send("x_center", xCenter)
    shader:send("y_center", yCenter)
    shader:send("domain", domain)

    --  draw the fractal to the drawCanvas using the shader by filling the
    --  canvas with a filled rectangle
    love.graphics.setCanvas(drawCanvas)
    love.graphics.setShader(shader)
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setShader()
    love.graphics.setCanvas()

end

function saveFractal()
    --  set the output height an the width using the current window aspect ratio
    local outputHeight = 1500
    local outputWidth = outputHeight * aspectRatio

    --  set the rate at which the final output will be supersampled
    local outputOversample = 4

    --  create the output canvas and draw the fractal to it
    local outputCanvasWidth = outputWidth * outputOversample
    local outputCanvasHeight = outputHeight * outputOversample
    local outputCanvas = love.graphics.newCanvas(outputCanvasWidth, outputCanvasHeight)

    print("Rendering...")
    drawFractal(outputCanvasWidth, outputCanvasHeight, outputCanvas)

    --  get the image data and save it to the data directory
    local canvasData = outputCanvas:newImageData()
    local canvasImage = canvasData:encode("png")
    local filename = os.time() .. ".png"
    local result = love.filesystem.write(filename, canvasImage:getString())

    --  see if it worked
    if result then
        print("Fractal output was successful, saved to file: " .. filename)
    else
        print("Error while saving fractal output")
    end

end

function sendColorPack(n)
    --  send the color_count (the length of the colorMap) to the shader, the
    --  colors themselves, and the backgroundColor of the colorMap
    shader:send("color_count", table.maxn(colors[n + 1]["colorMap"]))
    shader:sendColor("colors", unpack(colors[n + 1]["colorMap"]))
    shader:sendColor("background_color", colors[n + 1]["backgroundColor"])
end
