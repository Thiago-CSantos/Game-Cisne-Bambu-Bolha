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


function love.load()
    -- imagem vida
    vidas = love.graphics.newImage('sprites/heart.png')
    -- Carregamento de bibliotecas e configurações iniciais
    -- Carrega a biblioteca Windfield para física
    wf = require 'libraries/windfield'
    world = wf.newWorld(0, 0) -- Cria um novo mundo de física

    -- Carrega a biblioteca Anim8 para animações
    anim8 = require 'libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest") -- Configuração para manter a nitidez das imagens

    -- Carrega a biblioteca Simple Tiled Implementation (STI) para mapas
    sti = require 'libraries/sti'
    gameMap = sti('maps/mapa2.lua') -- Carrega o mapa

    -- Carrega a biblioteca para controle de câmera
    camera = require 'libraries/camera'
    cam = camera() -- Cria uma nova câmera

    -- Carrega a imagem do bambu
    bambuImage = love.graphics.newImage('sprites/bamboo.png')
    -- Variável para controlar o temporizador do bambu
    bambuTimer = 0

    -- Inicialização do jogador
    player = {}
    player.collider = world:newBSGRectangleCollider(400, 250, 60, 90, 15)                              -- Define um retângulo de colisão para o jogador

    player.collider:setFixedRotation(true)                                                             -- Faz com que a colisão do jogador não gire
    player.lives = 4                                                                                   -- Define a quantidade de vidas do jogador
    player.x = (gameMap.width * gameMap.tilewidth) /2                                                                                              -- Posição inicial X do jogador (centro do mapa)
    player.y = (gameMap.height * gameMap.tileheight) /2                                                                                             -- Posição inicial Y do jogador
    player.speed = 80                                                                                  -- Velocidade de movimento do jogador
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

    -- Gera 10 inimigos em posições aleatórias
    for i = 1, 50 do
        local enemy = {}
        enemy.x, enemy.y = randomPositionInMap()

        -- Restante das configurações do inimigo, como velocidade, dimensões, etc.
        enemy.speed = 70                                                                                -- Velocidade de movimento do inimigo
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

        table.insert(enemies, enemy)       -- Adiciona o novo inimigo à tabela de inimigos
    end

    ghosts = {}

    for i = 1, 10 do
        local ghost = {}    
        ghost.x, ghost.y = randomPositionInMap()    
        ghost.speed = 130
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
    for i = 1, 20 do
        local bambu = {}
        bambu.x, bambu.y = randomPositionInMap()
        bambu.live = true
        table.insert(bamboos, bambu)
    end
end

local isPaused = false
local colorTimer = 0
local colorDuration = 0.5               -- Duração em segundos para a mudança de cor
local originalColor = { 255, 255, 255 } -- Cor original do jogador

function love.update(dt)
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

        player.anim:update(dt) -- Atualiza a animação do jogador

        -- Movimentação dos inimigos e verificação de colisões
        for i = #enemies, 1, -1 do
            local enemy = enemies[i]
            if enemy and enemy.live then
                local dx = player.x + player.width / 2 - enemy.x
                local dy = player.y + player.height / 2 - enemy.y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance > 0 then
                    enemy.x = enemy.x + dx / distance * enemy.speed * dt
                    enemy.y = enemy.y + dy / distance * enemy.speed * dt
                end
                enemy.anim:update(dt) -- Atualiza a animação do inimigo

                -- Verifica colisão entre o jogador e o inimigo apenas se ainda não ocorreu uma colisão
                if not enemy.collided and isColliding(player.x, player.y, player.width, player.height, enemy.x, enemy.y, enemy.width, enemy.height) then
                    player.lives = player.lives - 1
                    enemy.collided = true -- Marca que ocorreu uma colisão com este inimigo
                    enemy.live = false    -- Define que o inimigo não está mais vivo

                    -- Altera a cor da sobreposição quando o jogador perde uma vida
                    love.graphics.setColor(love.math.colorFromBytes(255, 100, 100, 150))

                    -- Inicia o temporizador para restaurar a cor normal
                    colorTimer = colorDuration
                    if player.lives <= 0 then
                        love.event.quit()    -- Encerra o jogo se o jogador ficar sem vidas Mudar aqui quando morrer
                    end
                    table.remove(enemies, i) -- Remove o inimigo da tabela
                end
            end
        end

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
                        -- love.event.quit()    -- Encerra o jogo se o jogador ficar sem vidas Mudar aqui quando morrer
                    end
                    table.remove(ghosts, i) -- Remove o inimigo da tabela
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
                        contadorMortes = contadorMortes + 1
                        -- remove a bolha
                        -- table.remove(orbs, i)
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
                        ghost.live = false       -- Define que o inimigo não está mais vivo
                        table.remove(ghosts, j) -- Remove o inimigo da lista
                        contadorMortes = contadorMortes + 1
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

        -- Geração de bambus
        if bambuTimer >= 11 then
            for i = 1, 5 do
                local x, y = randomPositionInMap()
                table.insert(bamboos, { x = x, y = y, live = true })
            end
            bambuTimer = 0
        end
    end
end

function love.draw()
    cam:attach() -- Anexa a câmera

    -- Desenha as camadas do mapa
    gameMap:drawLayer(gameMap.layers["Camada de Blocos 1"])
    gameMap:drawLayer(gameMap.layers["arvores"])

    -- Desenha o jogador
    player.anim:draw(player.spriteSheet, player.x, player.y, nil, 2, nil, 2, 2)

    -- Desenha as esferas orbitando o jogador
    for i, orb in ipairs(orbs) do
        local centerX = player.x + player.width / 2 + 25
        local centerY = player.y + player.height / 2 + 68
        local ballX = centerX + orbitRadius * math.cos(orb.angle)
        local ballY = centerY + orbitRadius * math.sin(orb.angle)
        love.graphics.draw(orbImage, ballX, ballY, 10)
    end

    -- Desenha os inimigos
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

    gameMap:drawLayer(gameMap.layers["arvores2"])

    -- Desenha os bambus
    for _, bambu in ipairs(bamboos) do
        if bambu.live then
            love.graphics.draw(bambuImage, bambu.x, bambu.y)
        end
    end

    cam:detach() -- Desanexa a câmera

    -- Desenha as vidas do jogador
    for i = 1, player.lives do
        love.graphics.draw(vidas, 10 + (i - 1) * (vidas:getWidth() + 5), 10) -- Desenha os corações com um espaçamento de 5 pixels entre eles
    end

    -- Exibe o contador de mortes na tela
    love.graphics.print("Mortes: " .. contadorMortes, 10, 30)

    if isPaused then
        love.graphics.setColor(0, 0, 0, 0.5)                                                                       -- Configura uma cor preta com transparência para a sobreposição
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())                 -- Desenha um retângulo preto que cobre toda a tela
        love.graphics.setColor(255, 255, 255)                                                                      -- Restaura a cor padrão para desenhar o texto de pausa
        love.graphics.printf("Jogo pausado", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center") -- Desenha o texto de pausa no centro da tela
    end

    love.graphics.print("Time: " .. math.floor(bambuTimer), 500, 500)
end

function love.keypressed(key)
    if key == "p" then
        isPaused = not isPaused
    end
end
