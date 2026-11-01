-- LocalScript (Localização: StarterPlayerScripts ou StarterCharacterScripts)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Configurações gerais
local COOLDOWNS = {
JumpRegeneration = 10,
NoclipTransformation = 15,
GrappleHook = 8
}

local ABILITIES = {
JumpRegeneration = false,
NoclipTransformation = false,
GrappleHook = false
}

-- Função para desativar habilidades em execução
local function disableAllAbilities()
for ability, isActive in pairs(ABILITIES) do
ABILITIES[ability] = false
end
end

-- Função para iniciar cooldown
local function startCooldown(abilityName, duration)
if ABILITIES[abilityName] then return end

ABILITIES[abilityName] = true
local cooldownConnection

cooldownConnection = coroutine.wrap(function()
wait(duration)
ABILITIES[abilityName] = false
cooldownConnection = nil
end)()

return cooldownConnection
end

-- ===== HABILIDADE 1: JUMP COM REGENERAÇÃO =====
local function activateJumpRegeneration()
if ABILITIES.JumpRegeneration or humanoid:GetState() == Enum.HumanoidStateType.Jumping then return end

disableAllAbilities()
startCooldown("JumpRegeneration", COOLDOWNS.JumpRegeneration)

-- 1. Salto forte com desprendimento das pernas
humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
rootPart.Velocity = Vector3.new(0, 30, 0) -- Força do salto

-- Animação de desprendimento (usar AnimationTrack)
local legDetachAnim = Instance.new("Animation")
legDetachAnim.AnimationId = "rbxassetid:123456789" -- Substituir por ID real
local animTrack = humanoid:LoadAnimation(legDetachAnim)
animTrack:Play()

-- 2. Queda e aterrissagem deitada
humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
if humanoid.FloorMaterial == Enum.Material.Air then return end

-- Desativar colisões temporariamente
humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Falling, false)

-- Aplicar rotação e impacto
rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position - Vector3.new(0, 1, 0))
rootPart.Velocity = Vector3.new(0, 0, 0)

-- Criar efeito de impacto
local impactEffect = Instance.new("Part")
impactEffect.Size = Vector3.new(5, 0.5, 5)
impactEffect.Anchored = true
impactEffect.CanCollide = false
impactEffect.Transparency = 0.7
impactEffect.Material = Enum.Material.Neon
impactEffect.Color = Color3.fromRGB(100, 0, 0)
impactEffect.Position = rootPart.Position - Vector3.new(0, 1, 0)
impactEffect.Parent = workspace

game.Debris:AddItem(impactEffect, 0.5)

-- Iniciar regeneração das pernas
regenerateLegs()
end)
end

local function regenerateLegs()
local leftLeg = character:FindFirstChild("LeftLeg")
local rightLeg = character:FindFirstChild("RightLeg")

if not leftLeg or not rightLeg then return end

-- Remover pernas visualmente
leftLeg.Transparency = 1
rightLeg.Transparency = 1

-- Criar estrutura de regeneração (modelo 3D)
local regenModel = Instance.new("Model")
regenModel.Name = "RegenerationLegs"
regenModel.Parent = character

-- Animação de crescimento (simplificado)
local regenAnim = Instance.new("Animation")
regenAnim.AnimationId = "rbxassetid:987654321" -- Substituir por ID real
local regenTrack = humanoid:LoadAnimation(regenAnim)
regenTrack:Play()

-- Restaurar pernas após animação
wait(2.5)
leftLeg.Transparency = 0
rightLeg.Transparency = 0
regenModel:Destroy()

-- Animação de levantamento
humanoid:MoveTo(rootPart.Position + Vector3.new(0, 1, 0))
end

-- ===== HABILIDADE 2: NOCLIP (TRANSFORMAÇÃO EM GOTA) =====
local function activateNoclip()
if ABILITIES.NoclipTransformation then return end

disableAllAbilities()
startCooldown("NoclipTransformation", COOLDOWNS.NoclipTransformation)

-- 1. Desintegração do corpo
local explosion = Instance.new("Explosion")
explosion.Position = rootPart.Position
explosion.BlastRadius = 5
explosion.BlastPressure = 0
explosion.Parent = workspace

-- Ocultar modelo original
character:SetPrimaryPartCFrame(CFrame.new(rootPart.Position, Vector3.new(0, 1, 0)))
character.PrimaryPart = nil

-- Criar poça de energia
local puddle = Instance.new("Part")
puddle.Size = Vector3.new(4, 0.2, 4)
puddle.Anchored = true
puddle.CanCollide = false
puddle.Material = Enum.Material.Neon
puddle.Color = Color3.fromRGB(150, 0, 0)
puddle.Transparency = 0.5
puddle.Position = rootPart.Position - Vector3.new(0, 1, 0)
puddle.Parent = workspace

-- Transformar em gota
wait(1.5)
local droplet = Instance.new("Part")
droplet.Size = Vector3.new(0.5, 0.5, 0.5)
droplet.Anchored = false
droplet.CanCollide = false
droplet.Material = Enum.Material.Neon
droplet.Color = Color3.fromRGB(200, 0, 0)
droplet.Transparency = 0.3
droplet.Position = puddle.Position
droplet.Parent = workspace

-- Controle da gota (3 segundos)
local startTime = tick()
local isDropletActive = true

RunService.Heartbeat:Connect(function()
if not isDropletActive then return end

-- Movimento da gota (sem colisões)
if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
local mousePos = UserInputService:GetMouseLocation()
local direction = (mousePos - droplet.Position).Unit
droplet.Velocity = direction * 20
end

-- Deformação da gota
droplet.Size = Vector3.new(0.5 + math.sin(tick() * 2) * 0.1, 0.5, 0.5 + math.sin(tick() * 2) * 0.1)

-- Regeneração após 3 segundos
if tick() - startTime >= 3 then
isDropletActive = false
regenerateFromDroplet(droplet.Position)
end
end)

-- Função de regeneração
local function regenerateFromDroplet(position)
droplet:Destroy()
puddle:Destroy()

-- Restaurar corpo em partes
local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
if torso
