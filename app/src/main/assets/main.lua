-- Floppy Man (GitHub Build Version)
local state = "menu"
local player = { x = 60, y = 300, v = 0, size = 50, img = nil }
local pipes = {}
local score = 0
local gravity = 950
local jump = -320
local bg_scrolling = true
local bg_x = 0
local bg_img = nil

function love.load()
    -- Default Shapes (ပုံတွေ မရှိသေးခင် အလုပ်လုပ်ဖို့)
    player.canvas = love.graphics.newCanvas(128, 128)
    love.graphics.setCanvas(player.canvas)
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", 64, 64, 60)
    love.graphics.setCanvas()
    
    -- Assets (Files ကို Assets folder ထဲတွင် ဒီအမည်များအတိုင်း ထားပေးပါ)
    pcall(function()
        player.img = love.graphics.newImage("player_face.jpg")
        bg_img = love.graphics.newImage("background.jpg")
        sfx_jump = love.audio.newSource("jump.wav", "static")
        sfx_score = love.audio.newSource("score.wav", "static")
        sfx_die = love.audio.newSource("die.wav", "static")
    end)
end

-- Android Native Helper function (Gallery/Camera ပွင့်ဖို့)
function openAndroidPicker(target)
    local success, android = pcall(require, "android")
    if success and android.pickFile then
        android.pickFile("image/*", function(path)
            if path then
                local data = love.filesystem.newFileData(path)
                local img = love.graphics.newImage(data)
                if target == "face" then player.img = img else bg_img = img end
            end
        end)
    else
        print("This feature needs the APK build.")
    end
end

function love.update(dt)
    if state == "playing" then
        if bg_scrolling then
            bg_x = (bg_x - 100 * dt) % love.graphics.getWidth()
        end

        player.v = player.v + gravity * dt
        player.y = player.y + player.v * dt

        for i, p in ipairs(pipes) do
            p.x = p.x - 180 * dt
            -- Collision
            if player.x + player.size > p.x and player.x < p.x + 50 then
                if player.y < p.top or player.y + player.size > p.bottom then
                    state = "gameover"
                    if sfx_die then sfx_die:play() end
                end
            end
            -- Score
            if not p.passed and player.x > p.x + 50 then
                score = score + 1 ; p.passed = true
                if sfx_score then sfx_score:play() end
            end
        end

        if #pipes == 0 or pipes[#pipes].x < 200 then spawnPipe() end
        if player.y > love.graphics.getHeight() or player.y < 0 then 
            state = "gameover" 
            if sfx_die then sfx_die:play() end
        end
    end
end

function love.draw()
    if bg_img then
        -- Screen width နဲ့ height ကို ပုံရဲ့ width, height နဲ့ စားပြီး scale ရှာတာပါ
        local scaleX = love.graphics.getWidth() / bg_img:getWidth()
        local scaleY = love.graphics.getHeight() / bg_img:getHeight()
        
        -- ပထမပုံ
        love.graphics.draw(bg_img, bg_x - love.graphics.getWidth(), 0, 0, scaleX, scaleY)
        -- ဒုတိယပုံ (Scrolling အတွက်)
        love.graphics.draw(bg_img, bg_x, 0, 0, scaleX, scaleY)
    else
        love.graphics.clear(0.3, 0.6, 0.9)
    end


    if state == "menu" then drawMenu()
    elseif state == "playing" or state == "gameover" then
        drawPlayer() ; drawPipes()
        love.graphics.print("Score: "..score, 20, 20, 0, 2)
        if state == "gameover" then love.graphics.printf("GAME OVER\nTap to Retry", 0, 300, love.graphics.getWidth(), "center", 0, 2) end
    elseif state == "settings" then drawSettings() end
end

function drawPlayer()
    love.graphics.stencil(function()
        love.graphics.circle("fill", player.x + player.size/2, player.y + player.size/2, player.size/2)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    if player.img then
        -- ပုံကို player.size ထဲ ကွက်တိဝင်အောင် scale လုပ်ခြင်း
        local pScaleX = player.size / player.img:getWidth()
        local pScaleY = player.size / player.img:getHeight()
        love.graphics.draw(player.img, player.x, player.y, 0, pScaleX, pScaleY)
    else
        love.graphics.draw(player.canvas, player.x, player.y, 0, player.size/128, player.size/128)
    end
    
    love.graphics.setStencilTest()
end

function drawPipes()
    love.graphics.setColor(0.2, 0.8, 0.2)
    for _, p in ipairs(pipes) do
        love.graphics.rectangle("fill", p.x, 0, 50, p.top)
        love.graphics.rectangle("fill", p.x, p.bottom, 50, love.graphics.getHeight() - p.bottom)
    end
    love.graphics.setColor(1, 1, 1)
end

function drawMenu()
    love.graphics.printf("FLOPPY MAN", 0, 150, love.graphics.getWidth(), "center", 0, 3)
    drawButton("START", 100, 300, 160, 60)
    drawButton("SETTINGS", 100, 380, 160, 60)
end

function drawSettings()
    love.graphics.printf("SETTINGS", 0, 80, love.graphics.getWidth(), "center", 0, 2)
    drawButton("IMPORT FACE", 60, 180, 240, 50)
    drawButton("IMPORT BG", 60, 250, 240, 50)
    local scroll_txt = bg_scrolling and "BG SCROLL: ON" or "BG SCROLL: OFF"
    drawButton(scroll_txt, 60, 320, 240, 50)
    drawButton("BACK", 60, 450, 240, 50)
end

function drawButton(t, x, y, w, h)
    love.graphics.rectangle("line", x, y, w, h, 10, 10)
    love.graphics.printf(t, x, y + h/3, w, "center")
end

function love.mousepressed(x, y)
    if state == "menu" then
        if x > 100 and x < 260 then
            if y > 300 and y < 360 then state = "playing" ; resetGame()
            elseif y > 380 and y < 440 then state = "settings" end
        end
    elseif state == "settings" then
        if x > 60 and x < 300 then
            if y > 180 and y < 230 then openAndroidPicker("face")
            elseif y > 250 and y < 300 then openAndroidPicker("bg")
            elseif y > 320 and y < 370 then bg_scrolling = not bg_scrolling
            elseif y > 450 and y < 500 then state = "menu" end
        end
    elseif state == "playing" then
        player.v = jump
        if sfx_jump then sfx_jump:play() end
    elseif state == "gameover" then state = "menu" end
end

function spawnPipe()
    local gap = 160
    local top = math.random(100, 400)
    table.insert(pipes, {x = 400, top = top, bottom = top + gap, passed = false})
end

function resetGame()
    player.y = 300 ; player.v = 0 ; pipes = {} ; score = 0 ; spawnPipe()
end
