local menuengine = require "libs/menuengine"
local Config = require "config"
local BLACK = { 0, 0, 0 }
local BLUE = { 0, 0, 1 }

menuengine.settings.sndMove = love.audio.newSource("sounds/pick.wav", "static")
menuengine.settings.sndSuccess = love.audio.newSource("sounds/accept.wav", "static")
local jogo = require("cisne")
      -- Cria uma nova câmera

-- Menu Principal
local menuPrincipal

-- Funções do menu
local function iniciar_jogo()
    jogo.load()
end

local function opcoes()
    text = "Opções selecionadas!"
end

local function sair_jogo()
    love.event.quit()
end

function love.load()
    -- Configuração para tela cheia
    love.window.setFullscreen(true)

    -- Carregar a imagem de fundo
    cisneBackground = love.graphics.newImage("background/cisneBackground.png")

    -- Obtendo as dimensões da tela
    local screenWidth, screenHeight = love.graphics.getDimensions()

    -- Definindo o tamanho do texto
    local fontSize = 30
    love.graphics.setFont(love.graphics.newFont(fontSize))

    -- Calculando a largura do texto
    local textWidth = love.graphics.getFont():getWidth("Iniciar Jogo")

    -- Calculando a posição x para centralizar o texto
    local x = (screenWidth - textWidth) / 2

    -- Calculando a posição y para centralizar o texto verticalmente
    local y = screenHeight / 2 - fontSize / 2

    -- Criando o menu principal
    menuPrincipal = menuengine.new(x, y)
    menuPrincipal:addEntry("Iniciar Jogo", iniciar_jogo, nil, nil, BLACK, BLUE)
    menuPrincipal:addEntry("Opções", opcoes, nil, nil, BLACK, BLUE)
    menuPrincipal:addSep()
    menuPrincipal:addEntry("Sair do Jogo", sair_jogo, nil, nil, BLACK, BLUE)
end

function love.update(dt)
    menuPrincipal:update()
end

function love.draw()
    -- Obtendo as dimensões da imagem de fundo
    local bgWidth, bgHeight = cisneBackground:getDimensions()

    -- Obtendo as dimensões da tela
    local screenWidth, screenHeight = love.graphics.getDimensions()

    -- Calculando a posição para centralizar a imagem de fundo
    local x = (screenWidth - bgWidth) / 2
    local y = (screenHeight - bgHeight) / 2

    -- Desenhar imagem de fundo
    love.graphics.draw(cisneBackground, x, y)

    -- Desenhar o menu
    menuPrincipal:draw()
end

function love.keypressed(key, scancode, isrepeat)
    menuengine.keypressed(scancode)

    if scancode == "escape" then
        love.event.quit(0)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    menuengine.mousemoved(x, y)
end


