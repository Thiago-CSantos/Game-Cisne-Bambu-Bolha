local menuengine = require "libs/menuengine"
local Config = require "config"
local BLACK = { 0, 0, 0 }
local BLUE = { 0, 0, 1 }

menuengine.settings.sndMove = love.audio.newSource("sounds/pick.wav", "static")
menuengine.settings.sndSuccess = love.audio.newSource("sounds/accept.wav", "static")

local gameState = "menu"
local player
local enemies
local ghosts
local orbs
local bambuImage
local bambuTimer
local angle
local parede = {}

-- Menu Principal
local menuPrincipal

-- Funções do menu
local function iniciar_jogo()
    gameState = "jogo"
end

local function opcoes()
    gameState = "opcoes"
end

local function comandos()
    gameState = "comandos"
end

local function sair_jogo()
    love.event.quit()
end

-- Função para verificar colisões entre dois retângulos
function isColliding(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x1 + w1 > x2 and y1 < y2 + h2 and y1 + h1 > y2
end

function isCollidingOrbs(x1, y1, x2, y2, radius1, radius2)
    local dx = x2 - x1
    local dy = y2 - y1
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance < radius1 + radius2
end

function randomPositionInMap()
    local x = math.random(0, gameMap.width * gameMap.tilewidth)
    local y = math.random(0, gameMap.height * gameMap.tileheight)
    return x, y
end

function drawRandomBamboo()
    local x, y = randomPositionInMap()
    love.graphics.draw(bambu, x, y)
end

function generateBambu(x, y)
    local bambu = {}
    -- bambu.x, bambu.y = randomPositionInMap()
    bambu.x = x
    bambu.y = y
    bambu.live = true
    table.insert(bamboos, bambu)
end

function generateorb(x, y)
    numOrbs = numOrbs + 1
end

function carregaJogo()
    if gameState ~= "menu" then
        gameState = "jogo"
    end
    -- imagem vida
    vidas = love.graphics.newImage('sprites/heart.png')
    -- Carregamento de bibliotecas e configurações iniciais
    -- Carrega a biblioteca Windfield para física
    wf = require 'libraries/windfield'
    world = wf.newWorld(0, 0) -- Cria um novo mundo de física
    parede = world:newBSGRectangleCollider(1100, 2400, 600, 2, 15)
    parede:setType('static')

    -- Carrega a biblioteca Anim8 para animações
    anim8 = require 'libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest") -- Configuração para manter a nitidez das imagens

    -- Carrega a biblioteca Simple Tiled Implementation (STI) para mapas
    sti = require 'libraries/sti'
    gameMap = sti('maps/mapateste.lua') -- Carrega o mapa

    -- Carrega a biblioteca para controle de câmera
    camera = require 'libraries/camera'
    cam = camera() -- Cria uma nova câmera

    -- Carrega a imagem do bambu
    bambuImage = love.graphics.newImage('sprites/bamboo.png')
    -- Variável para controlar o temporizador do bambu
    bambuTimer = 0

    -- Inicialização do jogador
    player = {}
    player.collider = world:newBSGRectangleCollider(1900, 4300, 60, 70, 15)                            -- Define um retângulo de colisão para o jogador

    player.collider:setFixedRotation(true)                                                             -- Faz com que a colisão do jogador não gire
    player.lives = 5                                                                                   -- Define a quantidade de vidas do jogador
    player.x = (gameMap.width * gameMap.tilewidth) /
        2                                                                                              -- Posição inicial X do jogador (centro do mapa)
    player.y = (gameMap.height * gameMap.tileheight) /
        2                                                                                              -- Posição inicial Y do jogador
    player.speed = 200                                                                                 -- Velocidade de movimento do jogador
    player.width = 48                                                                                  -- Largura do jogador
    player.height = 64                                                                                 -- Altura do jogador

    player.spriteSheet = love.graphics.newImage('sprites/dodo.png')                                    -- Carrega a folha de sprites do jogador
    player.grid = anim8.newGrid(48, 64, player.spriteSheet:getWidth(), player.spriteSheet:getHeight()) -- Cria uma grade de animações

    time = player.speed /
        400 -- Define o tempo de animação com base na velocidade do jogador

    -- Define as animações do jogador para cada direção
    player.animations = {}
    player.animations.down = anim8.newAnimation(player.grid('1-3', 3), time)
    player.animations.left = anim8.newAnimation(player.grid('1-3', 4), time)
    player.animations.right = anim8.newAnimation(player.grid('1-3', 2), time)
    player.animations.up = anim8.newAnimation(player.grid('1-3', 1), time)

    player.anim = player.animations.left -- Define a animação inicial do jogador como 'esquerda'

    -- Inicialização dos inimigos
    enemies = {} --Tabela para armazenar os inimigos

    -- Gera 3 inimigos em posições aleatórias
    for i = 1, 3 do
        local enemy = {}
        enemy.x = 620 + i +
            (i * 60)                                                                                    -- Posição X do inimigo
        enemy.y = 750 + (i + 1 * 20)
        enemy.speed = 80                                                                                -- Velocidade de movimento do inimigo
        enemy.width = 32                                                                                -- Largura do inimigo
        enemy.height = 52                                                                               -- Altura do inimigo
        enemy.live = true                                                                               -- Define se o inimigo está vivo ou não
        enemy.spriteSheet = love.graphics.newImage('sprites/zombie_n_skeleton2.png')                    -- Carrega a folha de sprites do inimigo
        enemy.grid = anim8.newGrid(32, 52, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight()) -- Cria uma grade de animações para o inimigo
        enemy.animations = {}
        enemy.animations.down = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.left = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.right = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.up = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.anim = enemy.animations.left -- Define a animação inicial do inimigo como 'esquerda'

        -- Cria um colisor para o inimigo
        enemy.collider = world:newBSGRectangleCollider(enemy.x, enemy.y, 1, 1, 2)
        enemy.collider:setFixedRotation(true) -- Impede que o colisor gire

        table.insert(enemies, enemy)          -- Adiciona o novo inimigo à tabela de inimigos
    end

    -- Gera 3 inimigos em posições aleatórias
    for i = 1, 3 do
        local enemy = {}
        enemy.x = 1170 + i +
            (i * 60)                                                                                    -- Posição X do inimigo
        enemy.y = 480 + (i + 1 * 20)
        enemy.speed = 80                                                                                -- Velocidade de movimento do inimigo
        enemy.width = 32                                                                                -- Largura do inimigo
        enemy.height = 52                                                                               -- Altura do inimigo
        enemy.live = true                                                                               -- Define se o inimigo está vivo ou não
        enemy.spriteSheet = love.graphics.newImage('sprites/zombie_n_skeleton2.png')                    -- Carrega a folha de sprites do inimigo
        enemy.grid = anim8.newGrid(32, 52, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight()) -- Cria uma grade de animações para o inimigo
        enemy.animations = {}
        enemy.animations.down = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.left = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.right = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.up = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.anim = enemy.animations.left -- Define a animação inicial do inimigo como 'esquerda'

        -- Cria um colisor para o inimigo
        enemy.collider = world:newBSGRectangleCollider(enemy.x, enemy.y, 1, 1, 2)
        enemy.collider:setFixedRotation(true) -- Impede que o colisor gire

        table.insert(enemies, enemy)          -- Adiciona o novo inimigo à tabela de inimigos
    end

    -- Gera 3 inimigos em posições aleatórias
    for i = 1, 3 do
        local enemy = {}
        enemy.x = 1180 + i +
            (i * 60)                                                                                    -- Posição X do inimigo
        enemy.y = 1100 + (i + 1 * 20)
        enemy.speed = 80                                                                                -- Velocidade de movimento do inimigo
        enemy.width = 32                                                                                -- Largura do inimigo
        enemy.height = 52                                                                               -- Altura do inimigo
        enemy.live = true                                                                               -- Define se o inimigo está vivo ou não
        enemy.spriteSheet = love.graphics.newImage('sprites/zombie_n_skeleton2.png')                    -- Carrega a folha de sprites do inimigo
        enemy.grid = anim8.newGrid(32, 52, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight()) -- Cria uma grade de animações para o inimigo
        enemy.animations = {}
        enemy.animations.down = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.left = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.right = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.up = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.anim = enemy.animations.left -- Define a animação inicial do inimigo como 'esquerda'

        -- Cria um colisor para o inimigo
        enemy.collider = world:newBSGRectangleCollider(enemy.x, enemy.y, 1, 1, 2)
        enemy.collider:setFixedRotation(true) -- Impede que o colisor gire

        table.insert(enemies, enemy)          -- Adiciona o novo inimigo à tabela de inimigos
    end
    -- Gera 3 inimigos em posições aleatórias
    for i = 1, 3 do
        local enemy = {}
        enemy.x = 450 + i +
            (i * 60)                                                                                    -- Posição X do inimigo
        enemy.y = 1700 + (i + 1 * 20)
        enemy.speed = 80                                                                                -- Velocidade de movimento do inimigo
        enemy.width = 32                                                                                -- Largura do inimigo
        enemy.height = 52                                                                               -- Altura do inimigo
        enemy.live = true                                                                               -- Define se o inimigo está vivo ou não
        enemy.spriteSheet = love.graphics.newImage('sprites/zombie_n_skeleton2.png')                    -- Carrega a folha de sprites do inimigo
        enemy.grid = anim8.newGrid(32, 52, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight()) -- Cria uma grade de animações para o inimigo
        enemy.animations = {}
        enemy.animations.down = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.left = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.right = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.up = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.anim = enemy.animations.left -- Define a animação inicial do inimigo como 'esquerda'

        -- Cria um colisor para o inimigo
        enemy.collider = world:newBSGRectangleCollider(enemy.x, enemy.y, 1, 1, 2)
        enemy.collider:setFixedRotation(true) -- Impede que o colisor gire

        table.insert(enemies, enemy)          -- Adiciona o novo inimigo à tabela de inimigos
    end
    -- Gera 3 inimigos em posições aleatórias
    for i = 1, 3 do
        local enemy = {}
        enemy.x = 2000 + i +
            (i * 60)                                                                                    -- Posição X do inimigo
        enemy.y = 800 + (i + 1 * 20)
        enemy.speed = 80                                                                                -- Velocidade de movimento do inimigo
        enemy.width = 32                                                                                -- Largura do inimigo
        enemy.height = 52                                                                               -- Altura do inimigo
        enemy.live = true                                                                               -- Define se o inimigo está vivo ou não
        enemy.spriteSheet = love.graphics.newImage('sprites/zombie_n_skeleton2.png')                    -- Carrega a folha de sprites do inimigo
        enemy.grid = anim8.newGrid(32, 52, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight()) -- Cria uma grade de animações para o inimigo
        enemy.animations = {}
        enemy.animations.down = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.left = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.right = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.up = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.anim = enemy.animations.left -- Define a animação inicial do inimigo como 'esquerda'

        -- Cria um colisor para o inimigo
        enemy.collider = world:newBSGRectangleCollider(enemy.x, enemy.y, 1, 1, 2)
        enemy.collider:setFixedRotation(true) -- Impede que o colisor gire

        table.insert(enemies, enemy)          -- Adiciona o novo inimigo à tabela de inimigos
    end
    -- Gera 3 inimigos em posições aleatórias
    for i = 1, 5 do
        local enemy = {}
        enemy.x = 400 + i +
            (i * 60)                                                                                    -- Posição X do inimigo
        enemy.y = 2030 + (i + 1 * 20)
        enemy.speed = 80                                                                                -- Velocidade de movimento do inimigo
        enemy.width = 32                                                                                -- Largura do inimigo
        enemy.height = 52                                                                               -- Altura do inimigo
        enemy.live = true                                                                               -- Define se o inimigo está vivo ou não
        enemy.spriteSheet = love.graphics.newImage('sprites/zombie_n_skeleton2.png')                    -- Carrega a folha de sprites do inimigo
        enemy.grid = anim8.newGrid(32, 52, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight()) -- Cria uma grade de animações para o inimigo
        enemy.animations = {}
        enemy.animations.down = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.left = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.right = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.up = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.anim = enemy.animations.left -- Define a animação inicial do inimigo como 'esquerda'

        -- Cria um colisor para o inimigo
        enemy.collider = world:newBSGRectangleCollider(enemy.x, enemy.y, 1, 1, 2)
        enemy.collider:setFixedRotation(true) -- Impede que o colisor gire

        table.insert(enemies, enemy)          -- Adiciona o novo inimigo à tabela de inimigos
    end
    ghosts = {}

    for i = 1, 20 do
        local ghost = {}
        ghost.x, ghost.y = randomPositionInMap()
        ghost.speed = 100
        ghost.width = 32
        ghost.height = 32
        ghost.live = true
        ghost.spriteSheet = love.graphics.newImage('sprites/ghost.png')
        ghost.grid = anim8.newGrid(32, 32, ghost.spriteSheet:getWidth(), ghost.spriteSheet:getHeight())
        ghost.animations = {}
        ghost.animations.down = anim8.newAnimation(ghost.grid('1-6', 1), time)
        ghost.animations.left = anim8.newAnimation(ghost.grid('1-6', 1), time)
        ghost.animations.right = anim8.newAnimation(ghost.grid('1-6', 1), time)
        ghost.animations.up = anim8.newAnimation(ghost.grid('1-6', 1), time)
        ghost.anim = ghost.animations.left
        table.insert(ghosts, ghost)
    end

    devils = {}

    for i = 1, 1 do
        local devil = {}
        devil.x, devil.y = 1040, 300
        devil.speed = 200
        devil.hit = 600
        devil.maxHit = 600
        devil.width = 64
        devil.height = 64
        devil.live = true
        devil.spriteSheet = love.graphics.newImage('sprites/walk - sword.png')
        devil.grid = anim8.newGrid(64, 64, devil.spriteSheet:getWidth(), devil.spriteSheet:getHeight())
        devil.animations = {}
        devil.animations.down = anim8.newAnimation(devil.grid('1-4', 1), time)
        devil.animations.left = anim8.newAnimation(devil.grid('1-4', 4), time)
        devil.animations.right = anim8.newAnimation(devil.grid('1-4', 3), time)
        devil.animations.up = anim8.newAnimation(devil.grid('1-4', 2), time)
        devil.anim = devil.animations.down
        table.insert(devils, devil)
    end

    minotaurs = {}

    for i = 1, 1 do
        local minotaur = {}
        minotaur.x, minotaur.y = 540, 4150
        minotaur.speed = 120
        minotaur.hit = 300
        minotaur.maxHit = 300
        minotaur.width = 96
        minotaur.height = 96
        minotaur.live = true
        minotaur.spriteSheet = love.graphics.newImage('sprites/minotaurus_spritesheet_earth_original.png')
        minotaur.grid = anim8.newGrid(96, 96, minotaur.spriteSheet:getWidth(), minotaur.spriteSheet:getHeight())
        minotaur.animations = {}
        minotaur.animations.right = anim8.newAnimation(minotaur.grid('1-4', 2), time)
        minotaur.anim = minotaur.animations.right
        table.insert(minotaurs, minotaur)
    end

    -- inimigos mapa novo
    for i = 1, 3 do
        local enemy = {}
        enemy.x = 540 +
            (i * 60)                                                                                    -- Posição X do inimigo
        enemy.y = 4100 + (i + 1 * 30)
        enemy.speed = 80                                                                                -- Velocidade de movimento do inimigo
        enemy.width = 32                                                                                -- Largura do inimigo
        enemy.height = 52                                                                               -- Altura do inimigo
        enemy.live = true                                                                               -- Define se o inimigo está vivo ou não
        enemy.spriteSheet = love.graphics.newImage('sprites/zombie_n_skeleton2.png')                    -- Carrega a folha de sprites do inimigo
        enemy.grid = anim8.newGrid(32, 52, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight()) -- Cria uma grade de animações para o inimigo
        enemy.animations = {}
        enemy.animations.down = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.left = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.right = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.up = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.anim = enemy.animations.left -- Define a animação inicial do inimigo como 'esquerda'

        -- Cria um colisor para o inimigo
        enemy.collider = world:newBSGRectangleCollider(enemy.x, enemy.y, 1, 1, 2)
        enemy.collider:setFixedRotation(true) -- Impede que o colisor gire

        table.insert(enemies, enemy)          -- Adiciona o novo inimigo à tabela de inimigos
    end

    for i = 1, 8 do
        local enemy = {}
        enemy.x = 540 + i +
            (i * 60)                                                                                    -- Posição X do inimigo
        enemy.y = 2600 + ((i + 2) * 30)
        enemy.speed = 80                                                                                -- Velocidade de movimento do inimigo
        enemy.width = 32                                                                                -- Largura do inimigo
        enemy.height = 52                                                                               -- Altura do inimigo
        enemy.live = true                                                                               -- Define se o inimigo está vivo ou não
        enemy.spriteSheet = love.graphics.newImage('sprites/zombie_n_skeleton2.png')                    -- Carrega a folha de sprites do inimigo
        enemy.grid = anim8.newGrid(32, 52, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight()) -- Cria uma grade de animações para o inimigo
        enemy.animations = {}
        enemy.animations.down = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.left = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.right = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.up = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.anim = enemy.animations.left -- Define a animação inicial do inimigo como 'esquerda'

        -- Cria um colisor para o inimigo
        enemy.collider = world:newBSGRectangleCollider(enemy.x, enemy.y, 1, 1, 2)
        enemy.collider:setFixedRotation(true) -- Impede que o colisor gire

        table.insert(enemies, enemy)          -- Adiciona o novo inimigo à tabela de inimigos
    end

    for i = 1, 8 do
        local enemy = {}
        enemy.x = 2000 +
            (i * 60)                                                                                    -- Posição X do inimigo
        enemy.y = 2800 + ((i + 2) * math.random(30, 50))
        enemy.speed = 80                                                                                -- Velocidade de movimento do inimigo
        enemy.width = 32                                                                                -- Largura do inimigo
        enemy.height = 52                                                                               -- Altura do inimigo
        enemy.live = true                                                                               -- Define se o inimigo está vivo ou não
        enemy.spriteSheet = love.graphics.newImage('sprites/zombie_n_skeleton2.png')                    -- Carrega a folha de sprites do inimigo
        enemy.grid = anim8.newGrid(32, 52, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight()) -- Cria uma grade de animações para o inimigo
        enemy.animations = {}
        enemy.animations.down = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.left = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.right = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.up = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.anim = enemy.animations.left -- Define a animação inicial do inimigo como 'esquerda'

        -- Cria um colisor para o inimigo
        enemy.collider = world:newBSGRectangleCollider(enemy.x, enemy.y, 1, 1, 2)
        enemy.collider:setFixedRotation(true) -- Impede que o colisor gire

        table.insert(enemies, enemy)          -- Adiciona o novo inimigo à tabela de inimigos
    end

    for i = 1, 8 do
        local enemy = {}
        enemy.x = 120 + i +
            (i * 60)                                                                                    -- Posição X do inimigo
        enemy.y = 3450
        enemy.speed = 80                                                                                -- Velocidade de movimento do inimigo
        enemy.width = 32                                                                                -- Largura do inimigo
        enemy.height = 52                                                                               -- Altura do inimigo
        enemy.live = true                                                                               -- Define se o inimigo está vivo ou não
        enemy.spriteSheet = love.graphics.newImage('sprites/zombie_n_skeleton2.png')                    -- Carrega a folha de sprites do inimigo
        enemy.grid = anim8.newGrid(32, 52, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight()) -- Cria uma grade de animações para o inimigo
        enemy.animations = {}
        enemy.animations.down = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.left = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.right = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.up = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.anim = enemy.animations.left -- Define a animação inicial do inimigo como 'esquerda'

        -- Cria um colisor para o inimigo
        enemy.collider = world:newBSGRectangleCollider(enemy.x, enemy.y, 1, 1, 2)
        enemy.collider:setFixedRotation(true) -- Impede que o colisor gire

        table.insert(enemies, enemy)          -- Adiciona o novo inimigo à tabela de inimigos
    end

    for i = 1, 8 do
        local enemy = {}
        enemy.x = 4000 + i +
            (i * 60)                                                                                    -- Posição X do inimigo
        enemy.y = 3500
        enemy.speed = 80                                                                                -- Velocidade de movimento do inimigo
        enemy.width = 32                                                                                -- Largura do inimigo
        enemy.height = 52                                                                               -- Altura do inimigo
        enemy.live = true                                                                               -- Define se o inimigo está vivo ou não
        enemy.spriteSheet = love.graphics.newImage('sprites/zombie_n_skeleton2.png')                    -- Carrega a folha de sprites do inimigo
        enemy.grid = anim8.newGrid(32, 52, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight()) -- Cria uma grade de animações para o inimigo
        enemy.animations = {}
        enemy.animations.down = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.left = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.right = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.animations.up = anim8.newAnimation(enemy.grid('1-6', 1), time)
        enemy.anim = enemy.animations.left -- Define a animação inicial do inimigo como 'esquerda'

        -- Cria um colisor para o inimigo
        enemy.collider = world:newBSGRectangleCollider(enemy.x, enemy.y, 1, 1, 2)
        enemy.collider:setFixedRotation(true) -- Impede que o colisor gire

        table.insert(enemies, enemy)          -- Adiciona o novo inimigo à tabela de inimigos
    end

    -- fim do inimigos mapa novo


    -- Criação de colisões para paredes do mapa
    walls = {}
    if gameMap.layers['walls'] then
        for i, obj in pairs(gameMap.layers["walls"].objects) do
            local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            table.insert(walls, wall)
            wall:setType('static')
        end
    end

    -- Inicialização das bolhas
    orbs = {}


    bubleMusic = love.audio.newSource('sounds/Plop.ogg', 'static')

    -- Número de esferas desejadas
    numOrbs = 4


    -- Raio da órbita
    orbitRadius = 100

    -- Velocidade de rotação das esferas
    orbitSpeed = 0.8

    -- Carrega a imagem da esfera
    orbImage = love.graphics.newImage('sprites/orbs.png')

    -- Posição inicial do ângulo
    angle = 0

    contadorMortes = 0

    -- Cria as esferas
    for i = 1, numOrbs do
        local orb = {}
        orb.angle = (i - 1) * (2 * math.pi / numOrbs) -- Distribui as esferas uniformemente em torno do jogador
        orb.x = player.x + math.cos(orb.angle) * orbitRadius
        orb.y = player.y + math.sin(orb.angle) * orbitRadius
        orb.speed = orbitSpeed
        table.insert(orbs, orb)
    end

    -- Variável para controlar a pausa
    isPaused = false

    -- Criação dos bambus
    bamboos = {}

    generateBambu(500, 600)
    generateBambu(600, 600)
    generateBambu(800, 800)

    generateBambu(1600, 800)
    generateBambu(1200, 300)

    generateBambu(800, 800)
    generateBambu(360, 1300)
    generateBambu(410, 1500)

    generateBambu(1875, 250)
    generateBambu(2000, 250)
    generateBambu(2200, 320)

    somDemonio = love.audio.newSource("sounds/demonio.wav", "stream")
    somMinotauro = love.audio.newSource("sounds/minot.mp3", "stream")
end

function love.load()
    if gameState == "menu" then
        -- Configuração para tela cheia
        love.window.setFullscreen(true)

        -- Carregar a imagem de fundo
        cisneBackground = love.graphics.newImage("background/cisneBackground.png")
        fundoGameOver = love.graphics.newImage("sounds/gameOver.jpeg")
        fundoWin = love.graphics.newImage("sounds/gameWin.jpeg")

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
        menuPrincipal:addEntry("Comandos", comandos, nil, nil, BLACK, BLUE)
        menuPrincipal:addSep()
        menuPrincipal:addEntry("Sair do Jogo", sair_jogo, nil, nil, BLACK, BLUE)
    end

    somMenu = love.audio.newSource("sounds/castle 2.ogg", "stream")

    somZumbi = love.audio.newSource("sounds/Zombie Sound.wav", "static")
    somZumbi:setVolume(0.5)
    somzumbiflag = 0

    carregaJogo()
end

local isPaused = false
local colorTimer = 0
local colorDuration = 0.5               -- Duração em segundos para a mudança de cor
local originalColor = { 255, 255, 255 } -- Cor original do jogador

function love.update(dt)
    if gameState == "menu" then
        menuPrincipal:update()
    end

    if gameState == "jogo" then
        if not isPaused then
            -- Atualizações de lógica do jogo vão aqui dentro

            local isMoving = false -- Flag para verificar se o jogador está se movendo

            local vx = 0
            local vy = 0

            -- Movimentação do jogador
            if love.keyboard.isDown("d") then
                vx = player.speed
                player.anim = player.animations.right
                isMoving = true
            end

            if love.keyboard.isDown("a") then
                vx = player.speed * -1
                player.anim = player.animations.left
                isMoving = true
            end

            if love.keyboard.isDown("s") then
                vy = player.speed
                player.anim = player.animations.down
                isMoving = true
            end

            if love.keyboard.isDown("w") then
                vy = player.speed * -1
                player.anim = player.animations.up
                isMoving = true
            end

            player.collider:setLinearVelocity(vx, vy)

            -- Atualiza a animação do jogador se ele não estiver se movendo
            if isMoving == false then
                player.anim:gotoFrame(2)
            end

            --ao apertar espaço o personagem da um dash
            if love.keyboard.isDown("space") then
                player.speed = 1000
            else
                player.speed = 200
            end

            player.anim:update(dt) -- Atualiza a animação do jogador


            -- Movimentação dos inimigos e verificação de colisões
            -- se o inimigo estiver a mais de 150 pixel do player ele nao anda
            for i = #enemies, 1, -1 do
                local enemy = enemies[i]
                if enemy and enemy.live then
                    local dx = player.x + player.width / 2 - enemy.x
                    local dy = player.y + player.height / 2 - enemy.y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance > 0 then
                        if distance < 500 then
                            local vx = dx / distance * enemy.speed
                            local vy = dy / distance * enemy.speed
                            enemy.collider:setLinearVelocity(vx, vy)
                            enemy.anim:update(dt)
                        end
                    end

                    -- Atualiza a animação do inimigo

                    -- Atualiza a posição do inimigo
                    enemy.x = enemy.collider:getX() - enemy.width / 2 - 10
                    enemy.y = enemy.collider:getY() - enemy.height / 2 - 10

                    -- Verifica colisão entre o jogador e o inimigo
                    if not enemy.collided and isColliding(player.x, player.y, player.width, player.height, enemy.x, enemy.y, enemy.width, enemy.height) then
                        player.lives = player.lives - 1
                        enemy.collided = true -- Marca que ocorreu uma colisão com este inimigo
                        enemy.live = false    -- Define que o inimigo não está mais vivo

                        -- Altera a cor da sobreposição quando o jogador perde uma vida
                        love.graphics.setColor(love.math.colorFromBytes(255, 100, 100, 150))

                        -- Inicia o temporizador para restaurar a cor normal
                        colorTimer = colorDuration
                        if player.lives <= 0 then
                            gameState = "morreu"
                        end
                        table.remove(enemies, i) -- Remove o inimigo da tabela
                    end
                end
            end


            -- Movimentação dos fantasmas (semelhante aos inimigos)
            for i = #ghosts, 1, -1 do
                local ghost = ghosts[i]
                if ghost and ghost.live then
                    local dx = player.x + player.width / 2 - ghost.x
                    local dy = player.y + player.height / 2 - ghost.y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance > 0 then
                        ghost.x = ghost.x + dx / distance * ghost.speed * dt
                        ghost.y = ghost.y + dy / distance * ghost.speed * dt
                    end
                    ghost.anim:update(dt) -- Atualiza a animação do inimigo

                    -- Verifica colisão entre o jogador e o inimigo apenas se ainda não ocorreu uma colisão
                    if not ghost.collided and isColliding(player.x, player.y, player.width, player.height, ghost.x, ghost.y, ghost.width, ghost.height) then
                        player.lives = player.lives - 1
                        ghost.collided = true -- Marca que ocorreu uma colisão com este inimigo
                        ghost.live = false    -- Define que o inimigo não está mais vivo

                        -- Altera a cor da sobreposição quando o jogador perde uma vida
                        love.graphics.setColor(love.math.colorFromBytes(255, 100, 100, 150))

                        -- Inicia o temporizador para restaurar a cor normal
                        colorTimer = colorDuration
                        if player.lives <= 0 then
                            gameState = "morreu"
                        end
                        table.remove(ghosts, i) -- Remove o inimigo da tabela
                    end
                end
            end

            -- Movimentação dos fantasmas verdes (semelhante aos inimigos)
            for i = #devils, 1, -1 do
                local devil = devils[i]
                if devil and devil.live then
                    local dx = player.x + player.width / 2 - devil.x
                    local dy = player.y + player.height / 2 - devil.y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < 1200 then
                        devil.x = devil.x + dx / distance * devil.speed * dt
                        devil.y = devil.y + dy / distance * devil.speed * dt
                        -- musica demoniaca
                        somDemonio:play()
                        somDemonio:setVolume(0.4)
                    else
                        somDemonio:stop()
                    end

                    devil.anim:update(dt) -- Atualiza a animação do inimigo

                    -- Verifica colisão entre o jogador e o inimigo apenas se ainda não ocorreu uma colisão
                    if not devil.collided and isColliding(player.x, player.y, player.width, player.height, devil.x, devil.y, devil.width, devil.height) then
                        player.lives = player.lives - 1

                        --devil.live = false    -- Define que o inimigo não está mais vivo

                        -- Altera a cor da sobreposição quando o jogador perde uma vida
                        love.graphics.setColor(love.math.colorFromBytes(255, 100, 100, 150))

                        -- Inicia o temporizador para restaurar a cor normal
                        colorTimer = colorDuration
                        if player.lives <= 0 then
                            somDemonio:stop()
                            gameState = "morreu"
                        end
                        --table.remove(devils, i)        -- Remove o inimigo da tabela
                    end
                end
            end

            -- Movimentação dos minotauros (semelhante aos inimigos)
            for i = #minotaurs, 1, -1 do
                local minotaur = minotaurs[i]
                if minotaur and minotaur.live then
                    local dx = player.x + player.width / 2 - minotaur.x
                    local dy = player.y + player.height / 2 - minotaur.y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < 500 then
                        minotaur.x = minotaur.x + dx / distance * minotaur.speed * dt
                        minotaur.y = minotaur.y + dy / distance * minotaur.speed * dt
                        -- musica do minotauro
                        somMinotauro:play()
                        somMinotauro:setVolume(0.4)
                    else
                        somMinotauro:stop()
                    end
                    minotaur.anim:update(dt) -- Atualiza a animação do inimigo

                    -- Verifica colisão entre o jogador e o inimigo apenas se ainda não ocorreu uma colisão
                    if not minotaur.collided and isColliding(player.x, player.y, player.width, player.height, minotaur.x, minotaur.y, minotaur.width, minotaur.height) then
                        player.lives = player.lives - 1


                        -- Altera a cor da sobreposição quando o jogador perde uma vida
                        love.graphics.setColor(love.math.colorFromBytes(255, 100, 100, 150))

                        -- Inicia o temporizador para restaurar a cor normal
                        colorTimer = colorDuration
                        if player.lives <= 0 then
                            gameState = "morreu"
                        end
                    end
                end
            end

            -- Atualiza o ângulo das esferas
            angle = angle + orbitSpeed * dt
            for i, orb in ipairs(orbs) do
                orb.angle = orb.angle + orb.speed * dt
                orb.x = player.x + math.cos(orb.angle + angle) * orbitRadius
                orb.y = player.y + math.sin(orb.angle + angle) * orbitRadius
            end

            -- Atualização do mundo de física
            world:update(dt)

            -- Atualização da posição do jogador
            player.x = player.collider:getX() - player.width + 8 / 2
            player.y = player.collider:getY() - player.height - 9 / 2

            -- Atualização da câmera
            cam:lookAt(player.x, player.y)

            -- Limitação da câmera aos limites do mapa
            local w = love.graphics.getWidth()
            local h = love.graphics.getHeight()

            if cam.x < w / 2 then
                cam.x = w / 2
            end

            if cam.y < h / 2 then
                cam.y = h / 2
            end

            local mapW = gameMap.width * 64
            local mapH = gameMap.height * 64

            if cam.x > (mapW - w / 2) then
                cam.x = (mapW - w / 2)
            end

            if cam.y > (mapH - h / 2) then
                cam.y = (mapH - h / 2)
            end

            -- Fisica das bolhas para matar o enemy
            -- Verifica colisões entre orbs e inimigos
            for i = #orbs, 1, -1 do
                local orb = orbs[i]
                for j = #enemies, 1, -1 do
                    local enemy = enemies[j]
                    if enemy and orb and enemy.live then
                        if isCollidingOrbs(orb.x, orb.y, enemy.x, enemy.y, orbImage:getWidth() / 2, enemy.width / 2) then
                            -- Lógica para colisão entre orbs e inimigos
                            enemy.live = false       -- Define que o inimigo não está mais vivo
                            table.remove(enemies, j) -- Remove o inimigo da lista
                            contadorMortes = contadorMortes + 100
                            -- remove a bolha
                            -- table.remove(orbs, i)
                            -- carregar audio
                            bubleMusic:play()
                        end
                    end
                end
            end

            for i = #orbs, 1, -1 do
                local orb = orbs[i]
                for j = #ghosts, 1, -1 do
                    local ghost = ghosts[j]
                    if ghost and orb and ghost.live then
                        if isCollidingOrbs(orb.x, orb.y, ghost.x, ghost.y, orbImage:getWidth() / 2, ghost.width / 2) then
                            -- Lógica para colisão entre orbs e inimigos
                            ghost.live = false      -- Define que o inimigo não está mais vivo
                            table.remove(ghosts, j) -- Remove o inimigo da lista
                            contadorMortes = contadorMortes + 150
                        end
                    end
                end
            end

            for i = #orbs, 1, -1 do
                local orb = orbs[i]
                for j = #devils, 1, -1 do
                    local devil = devils[j]
                    if devil and orb and devil.live then
                        if isCollidingOrbs(orb.x, orb.y, devil.x, devil.y, orbImage:getWidth() / 2, devil.width / 2) then
                            -- Lógica para colisão entre orbs e inimigos
                            devil.hit = devil.hit - 1
                            if devil.hit == 0 then
                                devil.live = false      -- Define que o inimigo não está mais vivo
                                table.remove(devils, j) -- Remove o inimigo da lista
                                contadorMortes = contadorMortes + 500
                                gameState = "ganhou"
                            end
                        end
                    end
                end
            end

            for i = #orbs, 1, -1 do
                local orb = orbs[i]
                for j = #minotaurs, 1, -1 do
                    local minotaur = minotaurs[j]
                    if minotaur and orb and minotaur.live then
                        if isCollidingOrbs(orb.x, orb.y, minotaur.x, minotaur.y, orbImage:getWidth() / 2, minotaur.width / 2) then
                            -- Lógica para colisão entre orbs e inimigos
                            minotaur.hit = minotaur.hit - 1
                            if minotaur.hit == 0 then
                                minotaur.live = false      -- Define que o inimigo não está mais vivo
                                table.remove(minotaurs, j) -- Remove o inimigo da lista
                                contadorMortes = contadorMortes + 500
                                -- destroir a colisão parede
                                parede:destroy()
                                somMinotauro:stop()
                            end
                        end
                    end
                end
            end

            -- Atualiza o temporizador de mudança de cor
            if colorTimer > 0 then
                colorTimer = colorTimer - dt / 0.7
                if colorTimer <= 0 then
                    -- Restaura a cor original
                    love.graphics.setColor(originalColor)
                end
            end

            -- Atualiza o temporizador do bambu
            bambuTimer = bambuTimer + dt

            if player.lives < 3 then
                for i = #bamboos, 1, -1 do -- detecta colisão do player com bamboo e faz ele ganhar vida
                    local bambu = bamboos[i]
                    if bambu.live and isColliding(player.x, player.y, player.width, player.height, bambu.x, bambu.y, bambuImage:getWidth(), bambuImage:getHeight()) then
                        player.lives = player.lives + 1
                        bambu.live = false
                    end
                end
            end
        end
    end
end

function love.draw()
    if gameState == "ganhou" then
        
        love.graphics.draw(fundoWin, love.graphics.getWidth()/2 - fundoGameOver:getWidth()/2, love.graphics.getHeight()/2 - fundoGameOver:getHeight()/2)
        --escreva na tela que o jogador ganhou
        love.graphics.setColor(255, 255, 255)
        --escrever a pontuação na tela
        love.graphics.print("Pontuação: " .. contadorMortes, 100, 400)
        somDemonio:stop()
        somMinotauro:stop()
    end
    if gameState == "menu" then
        -- Obtendo as dimensões da imagem de fundo
        local bgWidth, bgHeight = cisneBackground:getDimensions()

        -- Obtendo as dimensões da tela
        local screenWidth, screenHeight = love.graphics.getDimensions()

        -- Calculando a posição para centralizar a imagem de fundo
        local x = (screenWidth - bgWidth) / 2
        local y = (screenHeight - bgHeight) / 2

        -- Desenhar imagem de fundo
        love.graphics.draw(cisneBackground, x, y)

        -- som do menu
        somMenu:play()

        -- Desenhar o menu
        menuPrincipal:draw()
    end

    if gameState == "jogo" then
        cam:attach() -- Anexa a câmera
        somMenu:stop()
        -- Desenha as camadas do mapa
        --gameMap:drawLayer(gameMap.layers["camada3"])
        --gameMap:drawLayer(gameMap.layers["Camada de Blocos 1"])
        --gameMap:drawLayer(gameMap.layers["objetosnomapa"])
        --gameMap:drawLayer(gameMap.layers["montanhas"])

        gameMap:drawLayer(gameMap.layers["Camada de Blocos 1"])
        --gameMap:drawLayer(gameMap.layers["chao"])



        -- Desenha o jogador
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 2, nil, 2, 2)
        for _, bambu in ipairs(bamboos) do
            if bambu.live then
                love.graphics.draw(bambuImage, bambu.x, bambu.y)
            end
        end
        for _, enemy in ipairs(enemies) do
            if enemy then
                enemy.anim:draw(enemy.spriteSheet, enemy.x, enemy.y, nil, 2)
            end
        end
        for _, ghost in ipairs(ghosts) do
            if ghost then
                ghost.anim:draw(ghost.spriteSheet, ghost.x, ghost.y, nil, 2)
            end
        end

        for _, minotaur in ipairs(minotaurs) do
            if minotaur then
                local barWidth = 50 + 50     -- Largura da barra de vida
                local barHeight = 10         -- Altura da barra de vida
                local barX = minotaur.x      -- Posição X da barra de vida
                local barY = minotaur.y - 20 -- Posição Y da barra de vida

                -- Desenha a barra de vida
                love.graphics.setColor(255, 0, 0)                                -- Define a cor vermelha para a barra de vida
                love.graphics.rectangle("fill", barX, barY, barWidth, barHeight) -- Desenha a barra de vida preenchida

                -- Calcula a porcentagem de vida restante
                local healthPercentage = minotaur.hit / minotaur.maxHit

                -- Calcula a largura atual da barra de vida com base na porcentagem de vida restante
                local currentWidth = barWidth * healthPercentage

                -- Desenha a parte atual da barra de vida com uma cor verde
                love.graphics.setColor(0, 255, 0)                                    -- Define a cor verde para a parte atual da barra de vida
                love.graphics.rectangle("fill", barX, barY, currentWidth, barHeight) -- Desenha a parte atual da barra de vida

                -- Desenha o texto de hit na posição da barra de vida
                love.graphics.setColor(255, 255, 255) -- Define a cor branca para o texto de hit

                -- Desenha o sprite do chefe
                minotaur.anim:draw(minotaur.spriteSheet, minotaur.x, minotaur.y, nil, 2)
            end
            if not minotaur then
                gameState = "vitoria"
            end
        end

        -- Desenha as esferas orbitando o jogador
        for i, orb in ipairs(orbs) do
            local centerX = player.x + player.width / 2 + 25
            local centerY = player.y + player.height / 2 + 68
            local ballX = centerX + orbitRadius * math.cos(orb.angle)
            local ballY = centerY + orbitRadius * math.sin(orb.angle)
            love.graphics.draw(orbImage, ballX, ballY, 10)
        end


        gameMap:drawLayer(gameMap.layers["paredes1"])
        gameMap:drawLayer(gameMap.layers["paredes"])

        gameMap:drawLayer(gameMap.layers["arvores1,5"])
        gameMap:drawLayer(gameMap.layers["arvoeres2.5"])
        gameMap:drawLayer(gameMap.layers["arvores1"])
        gameMap:drawLayer(gameMap.layers["arvores2"])
        gameMap:drawLayer(gameMap.layers["objetos"])
        --world:draw()


        for _, devil in ipairs(devils) do
            if devil then
                local barWidth = 50 + 50  -- Largura da barra de vida
                local barHeight = 10      -- Altura da barra de vida
                local barX = devil.x      -- Posição X da barra de vida
                local barY = devil.y - 20 -- Posição Y da barra de vida

                -- Desenha a barra de vida
                love.graphics.setColor(255, 0, 0)                                -- Define a cor vermelha para a barra de vida
                love.graphics.rectangle("fill", barX, barY, barWidth, barHeight) -- Desenha a barra de vida preenchida

                -- Calcula a porcentagem de vida restante
                local healthPercentage = devil.hit / devil.maxHit

                -- Calcula a largura atual da barra de vida com base na porcentagem de vida restante
                local currentWidth = barWidth * healthPercentage

                -- Desenha a parte atual da barra de vida com uma cor verde
                love.graphics.setColor(0, 255, 0)                                    -- Define a cor verde para a parte atual da barra de vida
                love.graphics.rectangle("fill", barX, barY, currentWidth, barHeight) -- Desenha a parte atual da barra de vida

                -- Desenha o texto de hit na posição da barra de vida
                love.graphics.setColor(255, 255, 255) -- Define a cor branca para o texto de hit

                -- Desenha o sprite do chefe
                devil.anim:draw(devil.spriteSheet, devil.x, devil.y, nil, 2)
            end
            if not devil then
                gameState = "vitoria"
            end
        end


        --gameMap:drawLayer(gameMap.layers["arvores2"])

        -- Desenha os bambus


        cam:detach() -- Desanexa a câmera

        local mouseX, mouseY = love.mouse.getPosition()
        -- Agora vamos desenhar a posição do mouse na tela


        local contador
        -- Desenha as vidas do jogador
        for i = 1, player.lives do
            love.graphics.draw(vidas, 10 + (i - 1) * (vidas:getWidth() + 5), 10) -- Desenha os corações com um espaçamento de 5 pixels entre eles
        end

        -- Exibe o contador de mortes na tela

        love.graphics.setColor(0, 0, 0)       -- Define a cor preta para o contorno
        love.graphics.print("PONTOS: " .. contadorMortes, 14, 40)
        love.graphics.setColor(255, 255, 0)   -- Define a cor amarela para o texto
        love.graphics.print("PONTOS: " .. contadorMortes, 11, 37)
        love.graphics.setColor(255, 255, 255) -- Restaura a cor padrão para desenhar o texto


        if isPaused then
            love.graphics.setColor(0, 0, 0, 0.5)                                                                -- Configura uma cor preta com transparência para a sobreposição
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())          -- Desenha um retângulo preto que cobre toda a tela
            love.graphics.setColor(255, 255, 255)                                                               -- Restaura a cor padrão para desenhar o texto de pausa
            love.graphics.printf("PAUSE", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center") -- Desenha o texto de pausa no centro da tela
        end
    end


    if gameState == "opcoes" then
         -- Define a cor de fundo como cinza
         love.graphics.setColor(79, 38, 38) -- RGB for gray
         love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight()) -- Desenha o fundo cinza
 
         -- Reseta a cor para preto para o restante dos desenhos
         love.graphics.setColor(0, 0, 0)
 
         -- Desenha o menu de opções
         love.graphics.rectangle("line", 100, 250, love.graphics.getWidth() - 200, 350) -- Desenha o quadro

        love.graphics.setColor(0, 0, 0)
        love.graphics.print("Opções", 400, 300)
        love.graphics.print("Pressione 'A' para abaixar o áudio", 400, 350)
        love.graphics.print("Pressione 'S' para aumentar o áudio", 400, 400)

        -- Desenha o botão de voltar
        love.graphics.print("Voltar (ESC)", 400, 450)
        love.graphics.setColor(255, 255, 255)
    end

    if gameState == "comandos" then
        -- Define a cor de fundo como cinza
        love.graphics.setColor(79, 38, 38) -- RGB for gray
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight()) -- Desenha o fundo cinza

        -- Reseta a cor para preto para o restante dos desenhos
        love.graphics.setColor(0, 0, 0)

        -- Desenha o menu de opções
        love.graphics.rectangle("line", 100, 250, love.graphics.getWidth() - 200, 350) -- Desenha o quadro

        love.graphics.setFont(love.graphics.newFont(36))
        love.graphics.printf("Comandos", 0, 300, love.graphics.getWidth(), "center")
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.printf("Movimentação: [W], [A], [S], [D]", 0, 350, love.graphics.getWidth(), "center")
        love.graphics.printf("Dash: [Espaço]", 0, 400, love.graphics.getWidth(), "center")
        love.graphics.printf("Pausar: [P]", 0, 450, love.graphics.getWidth(), "center")

        -- Desenha o botão de voltar
        love.graphics.setFont(love.graphics.newFont(36))
        love.graphics.printf("Voltar (ESC)", 0, 500, love.graphics.getWidth(), "center")

        love.graphics.setColor(255, 255, 255)
    end

    if gameState == "morreu" then
        love.graphics.draw(fundoGameOver, love.graphics.getWidth()/2 - fundoGameOver:getWidth()/2, love.graphics.getHeight()/2 - fundoGameOver:getHeight()/2)
        --escreva na tela que o jogador morreu
        love.graphics.setColor(255, 255, 255)
        --escrever a pontuação na tela
        love.graphics.print("Pontuação: " .. contadorMortes, 100, 400)

        love.graphics.print("Pressione 'R' ", 100, 500)
        love.graphics.print("(ESC) para SAIR", 100, 600)
        somDemonio:stop()
        somMinotauro:stop()
        if love.keyboard.isDown("r") then
            carregaJogo()
        end
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "p" then
        isPaused = not isPaused
    elseif gameState == "menu" and scancode == "escape" then
        love.event.quit(0)
    elseif gameState == "opcoes" and key == "s" then
        local newVolume = math.max(0, somMenu:getVolume() - 0.1)
        somMenu:setVolume(newVolume)
    elseif gameState == "opcoes" and key == "w" then
        local newVolume = math.max(0, somMenu:getVolume() + 0.1)
        somMenu:setVolume(newVolume)
    elseif gameState == "opcoes" and key == "escape" then
        gameState = "menu"
    elseif gameState == "morreu" and key == "escape" then
        gameState = "menu"
    elseif gameState == "ganhou" and key == "escape" then
        gameState = "menu"
    elseif gameState == "comandos" and key == "escape" then
        gameState = "menu"
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    menuengine.mousemoved(x, y)
end
