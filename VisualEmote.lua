-- Visual Emotes (standalone) - by Honami
-- UI is built in this file (styled after Mugiwara UI); swap and preview logic ported from Mugiwara HUB's
-- Games/Evade/VisualSwap.lua, EmotePreview.lua and VisualGridUI.lua (Carry and the hub's
-- premium-lock plumbing removed - this script has no premium tier of its own).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local FOLDER = "VisualEmotes"
if makefolder and isfolder and not isfolder(FOLDER) then makefolder(FOLDER) end

-- VisualSwap/EmotePreview below call getgenv().MugiwaraRegisterCleanup(...) and read
-- getgenv().MugiwaraFolder - satisfied here with a small local implementation (no hub loaded).
local cleanupFns = {}
local function RegisterCleanup(fn)
    table.insert(cleanupFns, fn)
end
getgenv().MugiwaraFolder = FOLDER
getgenv().MugiwaraRegisterCleanup = RegisterCleanup

-- Dijalankan saat script dimuat ulang: hasil swap dari sesi sebelumnya dikembalikan dulu.
local env = getgenv()
if env.VisualEmotesCleanup then pcall(env.VisualEmotesCleanup) end
env.VisualEmotesCleanup = function()
    for _, fn in ipairs(cleanupFns) do pcall(fn) end
end

-- ==========================================================
-- Swap engine (ported from Games/Evade/VisualSwap.lua)
-- ==========================================================
local function NewSwap(config)
    local Swap = {}

    local CATEGORY = config.Category
    local PATHS = config.Paths or {}
    local WHITELIST = config.Whitelist or {}
    local NOUN = config.Noun or "item"

    local entries = {}
    local byInstance = {}
    local swapped = {}
    local originals = {}

    local function SpacedName(name)
        return (name:gsub("(%l)(%u)", "%1 %2"))
    end

    local function ResolvePath(path)
        local current = game
        for _, name in ipairs(string.split(path, ".")) do
            if name == "ReplicatedStorage" then
                current = ReplicatedStorage
            else
                current = current:FindFirstChild(name)
            end
            if not current then return nil end
        end
        return current
    end

    local loaded = false
    local source = "none"

    local function AddEntry(instance, id)
        if byInstance[instance] then return end

        local info
        local ok, result = pcall(require, instance)
        if ok and type(result) == "table" then info = result end
        local display = info and info.AppearanceInfo and info.AppearanceInfo.Name
        local header = info and info.UIInfo and info.UIInfo.Header

        local entry = {
            Name = instance.Name,
            Display = type(display) == "string" and display or SpacedName(instance.Name),
            Header = type(header) == "string" and header or "Other",
            Id = id,
            Instance = instance,
        }
        table.insert(entries, entry)
        byInstance[instance] = entry
    end

    local function LoadFromRegistry()
        local items = ReplicatedStorage:FindFirstChild("Items")
        local registryModule = items and items:FindFirstChild("Registry")
        if not registryModule then return false end

        local ok, Registry = pcall(require, registryModule)
        if not ok or type(Registry) ~= "table" or type(Registry.GetByCategory) ~= "function" then return false end

        local okList, list = pcall(Registry.GetByCategory, CATEGORY)
        if not okList or type(list) ~= "table" then return false end

        for id, record in pairs(list) do
            local module = type(record) == "table" and record.Module
            if typeof(module) == "Instance" then AddEntry(module, id) end
        end
        return #entries > 0
    end

    local function LoadFromPaths()
        for _, path in ipairs(PATHS) do
            local instance = ResolvePath(path)
            if instance then AddEntry(instance) end
        end
    end

    local function LoadFromScan()
        local items = ReplicatedStorage:FindFirstChild("Items")
        if not items then return end
        for _, descendant in ipairs(items:GetDescendants()) do
            if descendant:IsA("ModuleScript") then
                local inCategory = false
                local parent = descendant.Parent
                while parent and parent ~= items do
                    if parent:IsA("Folder") and parent.Name == CATEGORY then
                        inCategory = true
                        break
                    end
                    parent = parent.Parent
                end
                if inCategory then AddEntry(descendant) end
            end
        end
    end

    function Swap.Load()
        if loaded then return #entries end
        loaded = true

        if not ReplicatedStorage:FindFirstChild("Items") then
            pcall(function() ReplicatedStorage:WaitForChild("Items", 8) end)
        end

        if LoadFromRegistry() then
            source = "registry"
        else
            table.clear(entries)
            table.clear(byInstance)
            LoadFromPaths()
            source = "paths"
            if #entries == 0 then
                LoadFromScan()
                source = "scan"
            end
        end

        table.sort(entries, function(a, b)
            return string.lower(a.Display) < string.lower(b.Display)
        end)
        return #entries
    end

    function Swap.GetSource()
        return source
    end

    function Swap.GetEntries()
        return entries
    end

    function Swap.GetWhitelist(entry)
        return entry and WHITELIST[entry.Name] or nil
    end

    function Swap.GetPartner(entry)
        local partner = entry and swapped[entry.Instance]
        return partner and byInstance[partner] or nil
    end

    -- 1 = belum bisa, 2 = bisa ditukar, 3 = pasangan yang sudah tertukar (tombol jadi Revert)
    function Swap.GetState(base, target)
        if not base or not target or base == target then return 1 end
        if swapped[base.Instance] == target.Instance then return 3 end
        if swapped[base.Instance] ~= nil or swapped[target.Instance] ~= nil then return 1 end
        return 2
    end

    local function CacheOriginal(item)
        if not originals[item] then
            originals[item] = {}
            for _, child in ipairs(item:GetChildren()) do
                table.insert(originals[item], child:Clone())
            end
        end
    end

    local function InjectContents(targetItem, sourceItem)
        for _, child in ipairs(targetItem:GetChildren()) do
            child:Destroy()
        end
        for _, child in ipairs(originals[sourceItem]) do
            child:Clone().Parent = targetItem
        end
    end

    function Swap.Swap(base, target)
        if Swap.GetState(base, target) ~= 2 then
            return false, "Please make sure you picked a valid Base and Target " .. NOUN .. "."
        end

        local ok, err = pcall(function()
            CacheOriginal(base.Instance)
            CacheOriginal(target.Instance)
            InjectContents(base.Instance, target.Instance)
            InjectContents(target.Instance, base.Instance)
        end)
        if not ok then return false, "The swap failed: " .. tostring(err) end

        swapped[base.Instance] = target.Instance
        swapped[target.Instance] = base.Instance
        return true, base.Display .. " ⇌ " .. target.Display
    end

    function Swap.Revert(base, target)
        if Swap.GetState(base, target) ~= 3 then
            return false, "These two " .. NOUN .. "s are not swapped."
        end

        local ok, err = pcall(function()
            InjectContents(base.Instance, base.Instance)
            InjectContents(target.Instance, target.Instance)
        end)
        if not ok then return false, "The revert failed: " .. tostring(err) end

        swapped[base.Instance] = nil
        swapped[target.Instance] = nil
        return true, base.Display .. " and " .. target.Display .. " were restored."
    end

    function Swap.RevertAll()
        local restored, touched = 0, {}
        for instance, partner in pairs(table.clone(swapped)) do
            if swapped[instance] == partner then
                local entry, other = byInstance[instance], byInstance[partner]
                if entry and other and Swap.Revert(entry, other) then
                    restored = restored + 1
                    table.insert(touched, entry)
                    table.insert(touched, other)
                end
            end
        end
        return restored, touched
    end

    getgenv().MugiwaraRegisterCleanup(function()
        pcall(Swap.RevertAll)
    end)

    return Swap
end

-- ==========================================================
-- Preview: frozen-pose viewport models for the emote grid
-- (ported from Games/Evade/EmotePreview.lua; the Carry/mannequin branch is dropped - this
-- script only ever renders emotes)
-- ==========================================================
local Preview = {}
do
    local TRACK_TIMEOUT = 5
    local SETTLE_FRAMES = 2
    local POSE_TIME = 0.5
    local MAX_HOSTS = 3
    local COLLECT_GAP = 0.12

    local POSE_FILE = FOLDER .. "/EmotePoses.json"
    local POSE_VERSION = 1

    local alive = true
    local hostGui = nil
    local hosts = {}
    local cache = {}
    local inflight = {}
    local inflightPose = {}
    local poses = nil
    local poseToken = 0

    local function HeartbeatWait(frames)
        for _ = 1, frames or 1 do RunService.Heartbeat:Wait() end
    end

    local function IsR15()
        local ok, rigType = pcall(function() return Players.LocalPlayer:GetAttribute("RigType") end)
        if ok and rigType ~= nil then return rigType == "R15" end
        return true
    end

    local function AssetItem(name)
        local assets = ReplicatedStorage:FindFirstChild("Assets")
        local items = assets and assets:FindFirstChild("Items")
        return items and items:FindFirstChild(name)
    end

    local function RigTemplate(r15)
        return AssetItem(r15 and "VisualRigR15Emote" or "VisualRigClassic")
    end

    function Preview.Available()
        return RigTemplate(IsR15()) ~= nil
    end

    local function LoadPoses()
        if poses then return poses end
        poses = {}
        if readfile and isfile and isfile(POSE_FILE) then
            local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(POSE_FILE)) end)
            if ok and type(decoded) == "table" and decoded.Version == POSE_VERSION and type(decoded.Poses) == "table" then
                poses = decoded.Poses
            end
        end
        return poses
    end

    local function FlushPoses()
        poseToken = poseToken + 1
        if not (poses and writefile) then return end
        pcall(function()
            if makefolder and isfolder and not isfolder(FOLDER) then makefolder(FOLDER) end
            writefile(POSE_FILE, HttpService:JSONEncode({ Version = POSE_VERSION, Poses = poses }))
        end)
    end

    local function SavePosesSoon()
        poseToken = poseToken + 1
        local mine = poseToken
        task.delay(3, function()
            if mine == poseToken then FlushPoses() end
        end)
    end

    local function JointPath(rig, joint)
        local names = {}
        local node = joint
        while node and node ~= rig do
            table.insert(names, 1, node.Name)
            node = node.Parent
        end
        return table.concat(names, "/")
    end

    local IDENTITY = { 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 }

    local function IsIdentity(components)
        for index, value in ipairs(IDENTITY) do
            if math.abs((components[index] or 0) - value) > 0.0001 then return false end
        end
        return true
    end

    local function CapturePose(rig)
        local pose = {}
        for _, descendant in ipairs(rig:GetDescendants()) do
            if descendant:IsA("Motor6D") then
                local components = { descendant.Transform:GetComponents() }
                if not IsIdentity(components) then pose[JointPath(rig, descendant)] = components end
            end
        end
        return pose
    end

    local function HasMotion(rig)
        for _, descendant in ipairs(rig:GetDescendants()) do
            if descendant:IsA("Motor6D") and not IsIdentity({ descendant.Transform:GetComponents() }) then return true end
        end
        return false
    end

    local function ApplyPose(rig, pose)
        for _, descendant in ipairs(rig:GetDescendants()) do
            if descendant:IsA("Motor6D") then
                local components = pose[JointPath(rig, descendant)]
                descendant.Transform = components and CFrame.new(table.unpack(components)) or CFrame.new()
            end
        end
    end

    local function EnsureGui()
        if hostGui and hostGui.Parent then return hostGui end

        local parent
        pcall(function() parent = (gethui and gethui()) or game:GetService("CoreGui") end)
        if not parent then parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

        hostGui = Instance.new("ScreenGui")
        hostGui.Name = "VisualEmotesPreview"
        hostGui.ResetOnSpawn = false
        hostGui.DisplayOrder = -10
        hostGui.IgnoreGuiInset = true
        hostGui.Parent = parent
        table.clear(hosts)
        return hostGui
    end

    local function AcquireHost()
        while alive do
            local gui = EnsureGui()
            for _, entry in ipairs(hosts) do
                if not entry.InUse and entry.Frame.Parent then
                    entry.InUse = true
                    return entry
                end
            end
            if #hosts < MAX_HOSTS then
                local frame = Instance.new("ViewportFrame")
                frame.Name = "Host" .. (#hosts + 1)
                frame.Size = UDim2.fromOffset(8, 8)
                frame.Position = UDim2.fromOffset(0, 0)
                frame.BackgroundTransparency = 1
                frame.ImageTransparency = 0.98
                frame.Parent = gui
                local entry = { Frame = frame, InUse = true }
                table.insert(hosts, entry)
                return entry
            end
            task.wait(0.03)
        end
        return nil
    end

    local function Variant(item)
        local selection = item:FindFirstChild("Selection")
        if selection then return selection:GetChildren()[1] or item end
        return item
    end

    local function FindEmoteAnimation(item, r15)
        if item:FindFirstChild("Animations") or item:FindFirstChild("Selection") then
            local container = item:FindFirstChild("Selection") and Variant(item) or item
            local animations = container:FindFirstChild("Animations")
            local folder = animations and animations:FindFirstChild(r15 and "R15" or "R6")
            local animation = folder and folder:FindFirstChild("Animation")
            if animation and animation.AnimationId ~= "" then return animation end
            return nil
        end
        return item:FindFirstChild(r15 and "Animation" or "AnimationClassic")
    end

    local function PoseJobs(entry, r15)
        local jobs = {}
        local animation = FindEmoteAnimation(entry.Instance, r15)
        if animation then table.insert(jobs, { Name = "Rig", Animation = animation, Prefix = r15 and "R15:" or "R6:", Template = RigTemplate(r15) }) end
        return jobs
    end

    local function PoseKey(job)
        return job.Prefix .. tostring(job.Animation.AnimationId)
    end

    local function RootOffset(model)
        local root = model:FindFirstChild("HumanoidRootPart")
        if not (root and root:IsA("BasePart")) then return 0 end

        local lowest = math.huge
        for _, name in ipairs({ "LeftFoot", "RightFoot", "Left Leg", "Right Leg" }) do
            local part = model:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                local half = part.Size / 2
                for _, sx in ipairs({ -1, 1 }) do
                    for _, sy in ipairs({ -1, 1 }) do
                        for _, sz in ipairs({ -1, 1 }) do
                            lowest = math.min(lowest, (part.CFrame * Vector3.new(sx * half.X, sy * half.Y, sz * half.Z)).Y)
                        end
                    end
                end
            end
        end
        if lowest == math.huge then return 0 end
        return root.Position.Y - lowest - 2.75
    end

    local function AttachProps(rig, item, r15)
        local template = Variant(item):FindFirstChild(r15 and "Character" or "CharacterClassic")
        if not template then return end

        local ok, copy = pcall(function() return template:Clone() end)
        if not ok or not copy then return end

        local emoteModel = copy:FindFirstChild("EmoteModel")
        if not emoteModel then
            copy:Destroy()
            return
        end

        local primary = rig:FindFirstChild("HumanoidRootPart", true) or rig.PrimaryPart
        local target = rig:FindFirstChild("R15Visual") or rig
        local offset = CFrame.new(0, RootOffset(copy), 0)

        emoteModel.Parent = target
        for _, child in ipairs(emoteModel:GetChildren()) do
            if (child:IsA("Motor6D") or child:IsA("Weld")) and child.Part0 and child.Part0.Parent == copy then
                if child.Part0.Name == "HumanoidRootPart" then
                    child.Part0 = primary
                    child.C0 = offset * child.C0
                else
                    child.Part0 = target:FindFirstChild(child.Part0.Name)
                end
            end
        end
        copy:Destroy()
    end

    local function GetAnimator(rig)
        local controller = rig:FindFirstChildWhichIsA("AnimationController", true) or rig:FindFirstChildWhichIsA("Humanoid", true)
        if not controller then return nil end
        return controller:FindFirstChildOfClass("Animator") or (function()
            local animator = Instance.new("Animator")
            animator.Parent = controller
            return animator
        end)()
    end

    local function SolveJoints(container, solved)
        if not solved then
            local root = container:FindFirstChild("HumanoidRootPart", true) or container.PrimaryPart
            if not root then return false end
            solved = { [root] = true }
        end

        local joints = {}
        for _, descendant in ipairs(container:GetDescendants()) do
            if descendant:IsA("Motor6D") or descendant:IsA("Weld") then
                if descendant.Part0 and descendant.Part1 then table.insert(joints, descendant) end
            end
        end

        local progress = true
        while progress do
            progress = false
            for _, joint in ipairs(joints) do
                local part0, part1 = joint.Part0, joint.Part1
                local transform = joint:IsA("Motor6D") and joint.Transform or CFrame.new()
                if solved[part0] and not solved[part1] then
                    part1.CFrame = part0.CFrame * joint.C0 * transform * joint.C1:Inverse()
                    solved[part1] = true
                    progress = true
                elseif solved[part1] and not solved[part0] then
                    part0.CFrame = part1.CFrame * joint.C1 * transform:Inverse() * joint.C0:Inverse()
                    solved[part0] = true
                    progress = true
                end
            end
        end
        return true
    end

    local function Orient(model)
        local primary = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart", true)
        if not primary then return end

        local inverse = primary.CFrame:Inverse()
        local base = CFrame.new(primary.Position)
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then descendant.CFrame = base * (inverse * descendant.CFrame) end
        end
    end

    local STRIP_CLASSES = {
        "Motor6D", "Weld", "ManualWeld", "WeldConstraint", "Snap", "Constraint",
        "ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles", "Explosion", "Highlight", "ForceField",
        "PointLight", "SpotLight", "SurfaceLight", "WrapTarget", "WrapLayer",
        "AnimationController", "Humanoid", "Animator", "LuaSourceContainer", "Sound",
    }

    local function ShouldStrip(instance)
        for _, class in ipairs(STRIP_CLASSES) do
            if instance:IsA(class) then return true end
        end
        return instance:IsA("Attachment") and not instance:IsA("Bone")
    end

    local function Freeze(source, name)
        local copy = source:Clone()
        copy.Name = name
        for _, descendant in ipairs(copy:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Anchored = true
                descendant.CastShadow = false
                descendant.CanCollide = false
                descendant.CanQuery = false
                descendant.CanTouch = false
            end
        end
        for _, descendant in ipairs(copy:GetDescendants()) do
            if ShouldStrip(descendant) then pcall(function() descendant:Destroy() end) end
        end
        Orient(copy)
        return copy
    end

    local function BuildEmoteModel(entry, r15, poseOf)
        local template = RigTemplate(r15)
        if not template then return nil, "the game's preview rig was not found" end

        local rig = template:Clone()
        AttachProps(rig, entry.Instance, r15)
        if poseOf.Rig then ApplyPose(rig, poseOf.Rig) end
        SolveJoints(rig)
        local model = Freeze(rig, entry.Display)
        pcall(function() rig:Destroy() end)
        return model
    end

    local function EnsurePose(job)
        local key = PoseKey(job)
        local store = LoadPoses()
        if store[key] then return store[key] end

        while inflightPose[key] do
            task.wait(0.03)
            if not alive then return nil, "unloaded" end
        end
        if store[key] then return store[key] end
        inflightPose[key] = true

        local hostEntry = AcquireHost()
        if not hostEntry then
            inflightPose[key] = nil
            return nil, "unloaded"
        end

        local pose, failure
        local world
        local ok, err = pcall(function()
            world = Instance.new("WorldModel")
            world.Parent = hostEntry.Frame

            local rig = job.Template:Clone()
            rig.Parent = world

            local animator = GetAnimator(rig)
            if not animator then
                failure = "the preview rig has no animator"
                return
            end

            local track = animator:LoadAnimation(job.Animation)
            track.Priority = Enum.AnimationPriority.Action3
            track:Play(0)
            track:AdjustSpeed(0)

            local limit = os.clock() + TRACK_TIMEOUT
            while alive and os.clock() < limit and track.Length <= 0 and not HasMotion(rig) do HeartbeatWait(1) end
            if track.Length <= 0 and not HasMotion(rig) then
                failure = "the animation did not load (" .. tostring(job.Animation.AnimationId) .. ")"
                return
            end

            track.TimePosition = math.min(POSE_TIME, track.Length)
            HeartbeatWait(SETTLE_FRAMES)
            pose = CapturePose(rig)
        end)

        if world then pcall(function() world:Destroy() end) end
        hostEntry.InUse = false
        inflightPose[key] = nil

        if not ok then return nil, tostring(err) end
        if not pose then return nil, failure or "preview failed" end

        store[key] = pose
        SavePosesSoon()
        return pose
    end

    function Preview.Get(entry)
        return entry and cache[entry.Instance] or nil
    end

    function Preview.PoseKnown(entry)
        local store = LoadPoses()
        for _, job in ipairs(PoseJobs(entry, IsR15())) do
            if not store[PoseKey(job)] then return false end
        end
        return true
    end

    function Preview.Invalidate(entry)
        local model = entry and cache[entry.Instance]
        if model then
            cache[entry.Instance] = nil
            pcall(function() model:Destroy() end)
        end
    end

    function Preview.Preload(entries)
        local r15 = IsR15()
        local store = LoadPoses()
        local list = {}
        for _, entry in ipairs(entries) do
            for _, job in ipairs(PoseJobs(entry, r15)) do
                if not store[PoseKey(job)] then table.insert(list, job.Animation) end
            end
        end
        if #list == 0 then return end
        task.spawn(function()
            pcall(function() game:GetService("ContentProvider"):PreloadAsync(list) end)
        end)
    end

    function Preview.Bake(entry)
        if not alive then return nil, "unloaded" end
        local cached = cache[entry.Instance]
        if cached then return cached end

        local r15 = IsR15()

        while inflight[entry.Instance] do
            task.wait(0.03)
            if not alive then return nil, "unloaded" end
        end
        cached = cache[entry.Instance]
        if cached then return cached end
        inflight[entry.Instance] = true

        local model, failure
        local ok, err = pcall(function()
            local poseOf = {}
            for _, job in ipairs(PoseJobs(entry, r15)) do
                local pose, reason = EnsurePose(job)
                if not pose then
                    failure = reason
                    return
                end
                poseOf[job.Name] = pose
            end
            model, failure = BuildEmoteModel(entry, r15, poseOf)
        end)
        inflight[entry.Instance] = nil

        if not ok then return nil, tostring(err) end
        if not model then return nil, failure or "preview failed" end
        if not alive then
            model:Destroy()
            return nil, "unloaded"
        end

        cache[entry.Instance] = model
        return model
    end

    function Preview.Collect(entries)
        local r15 = IsR15()
        local store = LoadPoses()
        local collected = 0
        for _, entry in ipairs(entries) do
            if not alive then break end
            for _, job in ipairs(PoseJobs(entry, r15)) do
                if not store[PoseKey(job)] then
                    if EnsurePose(job) then collected = collected + 1 end
                    task.wait(COLLECT_GAP)
                end
            end
        end
        return collected
    end

    RegisterCleanup(function()
        alive = false
        FlushPoses()
        for instance, model in pairs(cache) do pcall(function() model:Destroy() end) cache[instance] = nil end
        if hostGui then pcall(function() hostGui:Destroy() end) hostGui = nil end
        table.clear(hosts)
    end)
end

-- ==========================================================
-- Fallback path list (same as Mugiwara HUB, in case the game's own Registry can't be found)
-- ==========================================================
local DaftarPath = {
    "ReplicatedStorage.Items.BaseItems.Emotes.Addendum",
    "ReplicatedStorage.Items.BaseItems.Emotes.Aerobics",
    "ReplicatedStorage.Items.BaseItems.Emotes.Beg",
    "ReplicatedStorage.Items.BaseItems.Emotes.BoldMarch",
    "ReplicatedStorage.Items.BaseItems.Emotes.Breakdown",
    "ReplicatedStorage.Items.BaseItems.Emotes.BumperKart",
    "ReplicatedStorage.Items.BaseItems.Emotes.California",
    "ReplicatedStorage.Items.BaseItems.Emotes.Caramelldansen",
    "ReplicatedStorage.Items.BaseItems.Emotes.Carlton",
    "ReplicatedStorage.Items.BaseItems.Emotes.Catdown",
    "ReplicatedStorage.Items.BaseItems.Emotes.Clap",
    "ReplicatedStorage.Items.BaseItems.Emotes.ClubDance",
    "ReplicatedStorage.Items.BaseItems.Emotes.Conga",
    "ReplicatedStorage.Items.BaseItems.Emotes.Crabby",
    "ReplicatedStorage.Items.BaseItems.Emotes.CrounchDance",
    "ReplicatedStorage.Items.BaseItems.Emotes.Distraction",
    "ReplicatedStorage.Items.BaseItems.Emotes.Epicaricacy",
    "ReplicatedStorage.Items.BaseItems.Emotes.Facepalm",
    "ReplicatedStorage.Items.BaseItems.Emotes.Flexing",
    "ReplicatedStorage.Items.BaseItems.Emotes.Freestyle",
    "ReplicatedStorage.Items.BaseItems.Emotes.Gmod",
    "ReplicatedStorage.Items.BaseItems.Emotes.GoofyStride",
    "ReplicatedStorage.Items.BaseItems.Emotes.Gyrating",
    "ReplicatedStorage.Items.BaseItems.Emotes.Heaventaker",
    "ReplicatedStorage.Items.BaseItems.Emotes.Hired",
    "ReplicatedStorage.Items.BaseItems.Emotes.Infectious",
    "ReplicatedStorage.Items.BaseItems.Emotes.LittleJiggy",
    "ReplicatedStorage.Items.BaseItems.Emotes.Nostalgia",
    "ReplicatedStorage.Items.BaseItems.Emotes.PBJT",
    "ReplicatedStorage.Items.BaseItems.Emotes.PonPon",
    "ReplicatedStorage.Items.BaseItems.Emotes.Rambunctious",
    "ReplicatedStorage.Items.BaseItems.Emotes.RussianDance",
    "ReplicatedStorage.Items.BaseItems.Emotes.Sit",
    "ReplicatedStorage.Items.BaseItems.Emotes.Sleep",
    "ReplicatedStorage.Items.BaseItems.Emotes.Smug",
    "ReplicatedStorage.Items.BaseItems.Emotes.Stride",
    "ReplicatedStorage.Items.BaseItems.Emotes.SwagWalk",
    "ReplicatedStorage.Items.BaseItems.Emotes.TexasStyle",
    "ReplicatedStorage.Items.BaseItems.Emotes.ZenSerenity",

    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.APose",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.BoogieDown",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.BringItAround",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Catjam",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.CompanyMan",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Fazbore",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.FlashingLights",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Kickback",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.LineDance",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.LunarParty",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.MaracaTime",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Mashle",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Moonwalk",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Nizmoo",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.ParkerPride",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.PawsClaws",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Popipopi",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Robot",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.RushinAround",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.SeeTinh",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.SeriousMarch",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Smile",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.SpookyTime",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.StarPower",
    "ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.TPose",

    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.Banger",
    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.GalacticBound",
    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.GamingTime",
    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.HeliosChariot",
    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.Outlaw",
    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.StealthyBox",
    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.TouchGrass",
    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.Writhing",

    "ReplicatedStorage.Items.ItemPacks.Base.NewShop.Emotes.Popular",
    "ReplicatedStorage.Items.ItemPacks.Base.NewShop.Emotes.SightlessDance",

    "ReplicatedStorage.Items.ItemPacks.Base.Special.Emotes.Bhop",

    "ReplicatedStorage.Items.ItemPacks.Collab.ST.Emotes.WinterOf85",

    "ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.Broom",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.FrightFunk",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.PumpItUp",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.Reanimated",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.RockinStride",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.Thriller",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.WerewolfHowl",

    "ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.CyberBroom",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.DeadBoneStride",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.GhastlyGrimoire",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.GhoulishGalleon",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.HeadlessBaller",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.Xylobone",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.ZombieStride",

    "ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.CuerdasDelAlma",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.GraveRider",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.HeadlessHorseman",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.MariachiBand",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.ScorchedEarth",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.SpiritedAway",

    "ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.CampfireDoze",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.ChristmasBoogie",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.FlyingSleigh",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.Marching",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.Nutcracker",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.SnowmobileCruise",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.WindupDance",

    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.BobointheBox",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.IceFishing",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.RudolphMount",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.SantaMech",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.SledDrifting",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.SnowmanConstruction",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.ToyTrainRide",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.WindUpPose",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.WinterRide",

    "ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.CozyChair",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.FrostDrake",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.RockingHorse",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.SkiSpree",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.WinterMelody",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.DailyShop.SnowAngel",

    "ReplicatedStorage.Items.ItemPacks.Events.2024.StPatricks2024.Emotes.AvariceLounge",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.StPatricks2024.Emotes.IrishJig",

    "ReplicatedStorage.Items.ItemPacks.Events.2025.StPatricks2025.Emotes.AprilShower",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.StPatricks2025.Emotes.GoldRitual",

    "ReplicatedStorage.Items.ItemPacks.Events.2026.StPatricks2026.Emotes.AuspiciousWell",

    "ReplicatedStorage.Items.ItemPacks.Events.2024.Valentines2024.Emotes.AngelicWings",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Valentines2024.Emotes.HarpRecital",

    "ReplicatedStorage.Items.ItemPacks.Events.2025.Valentines2025.Emotes.SerenePerch",

    "ReplicatedStorage.Items.ItemPacks.Events.2026.Valentines2026.Emotes.DreamyCloud",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.Valentines2026.Emotes.ValentineComputer",

    "ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.BeachChairLounge",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.CasualSurfing",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.LemonadeStand",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.ManyFans",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.PoolTime",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.RowBoat",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.SummerDays",

    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.AquaticDaydreamer",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.AstralMantaRay",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.ClamClamor",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.EncapsulatedBubble",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.FrutigerFloatie",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.LeapingDolphin",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.SubmarineRide",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.SummerLowrider",

    "ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.CoccoonRebirth",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.HoneyPool",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.LadybugFlight",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.LotusSwing",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.MegaflyJet",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.SnailMail",

    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.LunarNewYear.Emotes.DynastyDrumming",

    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.NewYears2024.Emotes.FireworkBlast",

    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.ClassicDance",
    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.ClassicJeep",
    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.ClassicStride",
    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.FastFoodDelight",
    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.PotionMash",
    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.RainingTacos",
    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.SkateboardStroll",

    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.Thanksgiving2025.Emotes.TurkeyJockey",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.BeeSet.Emotes.QueensAppearance",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.BeeSet.Emotes.RegalWalk",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.BeeSet.Emotes.WingedRoyalSit",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.PoseidonSet.Emotes.MountedSeahorse",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.PoseidonSet.Emotes.NeptunesThrone",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.PoseidonSet.Emotes.ShellHermit",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.AstroSlide",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.BananaDance",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.CrabRave",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.CuddleBearSit",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.HitTheJackpot",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Legacy.Military.Emotes.Rocket",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Legacy.Military.Emotes.Tank",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Legacy.StPatricks2023.Emotes.MarchShowcase",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Animals.Emotes.DuckyMarch",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Animals.Emotes.Sleepybara",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Animals.Emotes.TurtleHobble",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Cats.Emotes.CatParty",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.DogSet.Emotes.DogParty",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.DogSet.Emotes.FreshFlop",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EclipseSet.Emotes.SolarBike",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EclipseSet.Emotes.SolarConqueror",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EclipseSet.Emotes.SolarSlayer",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.Boneless",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.Gangnam",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.Griddy",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.LDance",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.Macarena",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Gems.Emotes.HoveringCrystal",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.LunarNewYearSet.Emotes.FlyingFish",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.Caffeinated",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.CatDance",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.Frolic",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.OiiaOiia",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.Wess",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.RelicEmotesVaulted.Emotes.Bumblebee",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.RelicEmotesVaulted.Emotes.RockefellerStreet",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.RelicEmotesVaulted.Emotes.ShubaDance",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.RelicEmotesVaulted.Emotes.Twist",

    "ReplicatedStorage.Items.ItemPacks.Integration.M3GAN.Emotes.M3GANDance",
    "ReplicatedStorage.Items.ItemPacks.Integration.M3GAN.Emotes.RobotM3GAN",
}


-- ==========================================================
-- UI: own implementation, styled after Mugiwara UI
-- (dark glass window, white cards, warm accent). Layout: Base on the left, Target on the
-- right, each with a category dropdown, a search box and an always-open grid of previews.
-- ==========================================================
local UserInputService = game:GetService("UserInputService")

local VERSION = "v2.0"

local THEME = {
    Background = Color3.fromRGB(12, 13, 21),
    Field = Color3.fromRGB(0, 0, 0),
    Card = Color3.fromRGB(255, 255, 255),
    Popup = Color3.fromRGB(14, 14, 20),
    Text = Color3.fromRGB(247, 247, 252),
    SubText = Color3.fromRGB(192, 194, 210),
    Muted = Color3.fromRGB(134, 136, 154),
    Accent = Color3.fromRGB(255, 150, 40),
    OnAccent = Color3.fromRGB(28, 12, 8),
    Success = Color3.fromRGB(80, 230, 150),
    Danger = Color3.fromRGB(255, 72, 92),
}
local FONT, FONT_BOLD = Enum.Font.Gotham, Enum.Font.GothamBold

local function New(class, props, parent)
    local instance = Instance.new(class)
    for key, value in pairs(props) do instance[key] = value end
    instance.Parent = parent
    return instance
end

local function Round(instance, radius)
    return New("UICorner", { CornerRadius = UDim.new(0, radius) }, instance)
end

local function Stroke(instance, transparency, color)
    return New("UIStroke", {
        Color = color or THEME.Card,
        Transparency = transparency,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, instance)
end

local function Label(parent, props)
    local merged = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = FONT,
        TextColor3 = THEME.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }
    for key, value in pairs(props) do merged[key] = value end
    return New("TextLabel", merged, parent)
end

local function MakeButton(parent, text, primary, width)
    local button = New("TextButton", {
        Text = text,
        Font = FONT_BOLD,
        TextSize = 13,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(width, 30),
        BackgroundColor3 = primary and Color3.new(1, 1, 1) or THEME.Card,
        BackgroundTransparency = primary and 0 or 0.92,
        TextColor3 = primary and THEME.OnAccent or THEME.Text,
    }, parent)
    Round(button, 8)
    if primary then
        New("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new(Color3.fromRGB(255, 200, 62), Color3.fromRGB(255, 122, 26)),
        }, button)
    else
        Stroke(button, 0.85)
    end
    return button
end

local function SetEnabled(button, primary, enabled)
    button.BackgroundTransparency = enabled and (primary and 0 or 0.92) or 0.6
    button.TextTransparency = enabled and 0 or 0.45
end

local guiParent
pcall(function() guiParent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not guiParent then guiParent = Players.LocalPlayer:WaitForChild("PlayerGui") end

local Gui = New("ScreenGui", {
    Name = "VisualEmotes",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 9999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)
RegisterCleanup(function() pcall(function() Gui:Destroy() end) end)

local camera = workspace.CurrentCamera
local screen = camera and camera.ViewportSize or Vector2.new(1280, 720)
local WIDTH = math.min(660, screen.X - 24)
local HEIGHT = math.min(440, screen.Y - 24)
local TITLE_H, BAR_H = 40, 48

local Main = New("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(WIDTH, HEIGHT),
    BackgroundColor3 = THEME.Background,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
}, Gui)
Round(Main, 12)
Stroke(Main, 0.84)

local TitleBar = New("Frame", { Name = "TitleBar", Size = UDim2.new(1, 0, 0, TITLE_H), BackgroundTransparency = 1 }, Main)
Label(TitleBar, {
    Text = 'Visual Emotes  <font color="#868a9a" size="12">by Honami  ·  ' .. VERSION .. "</font>",
    RichText = true,
    Font = FONT_BOLD,
    TextSize = 15,
    Position = UDim2.fromOffset(14, 0),
    Size = UDim2.new(1, -90, 1, 0),
})

local function TitleButton(text, offsetX, hoverColor)
    local button = New("TextButton", {
        Text = text,
        Font = FONT_BOLD,
        TextSize = 16,
        TextColor3 = THEME.SubText,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        BackgroundColor3 = THEME.Card,
        BackgroundTransparency = 0.94,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, offsetX, 0.5, 0),
        Size = UDim2.fromOffset(26, 26),
    }, TitleBar)
    Round(button, 7)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor or THEME.Card
        button.BackgroundTransparency = hoverColor and 0.6 or 0.85
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = THEME.Card
        button.BackgroundTransparency = 0.94
    end)
    return button
end

local CloseButton = TitleButton("×", -10, THEME.Danger)
local MinimizeButton = TitleButton("–", -42)

New("Frame", {
    Position = UDim2.fromOffset(0, TITLE_H),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = THEME.Card,
    BackgroundTransparency = 0.9,
    BorderSizePixel = 0,
}, Main)

local Body = New("Frame", {
    Name = "Body",
    Position = UDim2.fromOffset(0, TITLE_H + 1),
    Size = UDim2.new(1, 0, 1, -(TITLE_H + 1)),
    BackgroundTransparency = 1,
}, Main)

local PaneHolder = New("Frame", { Name = "Panes", Size = UDim2.new(1, 0, 1, -BAR_H), BackgroundTransparency = 1 }, Body)
New("UIPadding", {
    PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 6),
}, PaneHolder)
New("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 8),
}, PaneHolder)

local BottomBar = New("Frame", {
    Name = "BottomBar",
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.fromScale(0, 1),
    Size = UDim2.new(1, 0, 0, BAR_H),
    BackgroundTransparency = 1,
}, Body)
New("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = THEME.Card,
    BackgroundTransparency = 0.9,
    BorderSizePixel = 0,
}, BottomBar)

local StatusLabel = Label(BottomBar, {
    Position = UDim2.fromOffset(14, 0),
    Size = UDim2.new(1, -270, 1, 0),
    TextColor3 = THEME.SubText,
    TextTruncate = Enum.TextTruncate.AtEnd,
})
local RevertAllButton = MakeButton(BottomBar, "Revert All", false, 100)
RevertAllButton.AnchorPoint = Vector2.new(1, 0.5)
RevertAllButton.Position = UDim2.new(1, -10, 0.5, 0)
local SwapButton = MakeButton(BottomBar, "Swap", true, 130)
SwapButton.AnchorPoint = Vector2.new(1, 0.5)
SwapButton.Position = UDim2.new(1, -118, 0.5, 0)

-- Window behaviour: drag by the title bar, minimize, close.
do
    local dragging, dragStart, startPosition = false, nil, nil
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPosition = true, input.Position, Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    local moveConnection = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    RegisterCleanup(function() moveConnection:Disconnect() end)

    local minimized = false
    MinimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        Body.Visible = not minimized
        Main.Size = minimized and UDim2.fromOffset(WIDTH, TITLE_H) or UDim2.fromOffset(WIDTH, HEIGHT)
    end)
    CloseButton.MouseButton1Click:Connect(function()
        local fns = cleanupFns
        cleanupFns = {}
        for _, fn in ipairs(fns) do pcall(fn) end
    end)
end

-- ==========================================================
-- Emote grid logic (ported from Games/Evade/VisualGridUI.lua, rebuilt on the UI above)
-- ==========================================================
local HEADER_ORDER = { "Normal", "Gamepasses", "Halloween", "Winter Holidays", "Summer", "Spring", "Valentines", "Event", "Special" }

local function BuildGroups(entries)
    local byHeader = {}
    for _, entry in ipairs(entries) do
        byHeader[entry.Header] = byHeader[entry.Header] or {}
        table.insert(byHeader[entry.Header], entry)
    end

    local order, seen = {}, {}
    for _, header in ipairs(HEADER_ORDER) do
        if byHeader[header] then
            table.insert(order, header)
            seen[header] = true
        end
    end
    local rest = {}
    for header in pairs(byHeader) do
        if not seen[header] then table.insert(rest, header) end
    end
    table.sort(rest)
    for _, header in ipairs(rest) do table.insert(order, header) end

    local groups = {}
    for _, header in ipairs(order) do
        table.insert(groups, { Title = header, Entries = byHeader[header] })
    end
    return groups
end

-- Same camera as the game's emote menu: in front, a little to the right and above.
local LOOK_DIRECTION = Vector3.new(4.25, 1.7, -8.5).Unit

local function BuildEmoteUI(Swap)
    if Swap.Load() == 0 then
        Label(PaneHolder, {
            Text = "No emotes were found in this game. The game may have changed its item folders.",
            TextWrapped = true,
            TextColor3 = THEME.SubText,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
        })
        SwapButton.Visible = false
        RevertAllButton.Visible = false
        return
    end

    local groups = BuildGroups(Swap.GetEntries())
    local sides = {}
    local failedPreview = {}
    local previewState = nil
    local statusToken = 0
    local Refresh, RefreshVisible

    local function TitleOf(entry)
        local partner = Swap.GetPartner(entry)
        return partner and (entry.Display .. " (" .. partner.Display .. ")") or entry.Display
    end

    local function ShowHint()
        local base, target = sides.Base.Selected, sides.Target.Selected
        local state = Swap.GetState(base, target)
        if state == 3 then
            StatusLabel.Text = base.Display .. " looks like " .. target.Display .. " (swapped)"
        elseif state == 2 then
            StatusLabel.Text = "Ready: " .. base.Display .. " will look like " .. target.Display
        else
            StatusLabel.Text = "Pick a Base and a Target emote."
        end
        StatusLabel.TextColor3 = THEME.SubText
    end

    local function SetStatus(text, color)
        statusToken = statusToken + 1
        local mine = statusToken
        StatusLabel.Text = text
        StatusLabel.TextColor3 = color or THEME.SubText
        task.delay(3.5, function()
            if mine == statusToken then ShowHint() end
        end)
    end

    local function PreviewsOn()
        if previewState == nil then
            previewState = Preview.Available() and true or false
            if not previewState then SetStatus("Previews are not available in this game version.", THEME.Danger) end
        end
        return previewState
    end

    -- ---------- tiles ----------
    local function AttachView(tile)
        if tile.View then return end
        local model = Preview.Get(tile.Entry)
        if not model then return end

        local view = New("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Ambient = Color3.fromRGB(190, 190, 190),
            LightColor = Color3.fromRGB(255, 255, 255),
        }, tile.Holder)
        local clone = model:Clone()
        clone.Parent = view

        local cf, size = clone:GetBoundingBox()
        local radius = math.max(size.X, size.Y, size.Z) / 2
        local distance = radius / math.tan(math.rad(15)) * 1.1
        local viewCamera = New("Camera", { FieldOfView = 30 }, view)
        viewCamera.CFrame = CFrame.lookAt(cf.Position + LOOK_DIRECTION * distance, cf.Position)
        view.CurrentCamera = viewCamera

        tile.View = view
        tile.Placeholder.Visible = false
    end

    local function DetachView(tile)
        if tile.View then
            tile.View:Destroy()
            tile.View = nil
        end
        tile.Placeholder.Visible = true
    end

    local function UpdateTileLook(side, tile)
        local selected = side.Selected == tile.Entry
        tile.Stroke.Color = selected and THEME.Accent or THEME.Card
        tile.Stroke.Transparency = selected and 0 or 0.88
        tile.Stroke.Thickness = selected and 2 or 1
        tile.Name.TextColor3 = selected and THEME.Text or THEME.SubText
    end

    local function Pick(side, entry)
        side.Selected = (side.Selected ~= entry) and entry or nil
        Refresh()
    end

    local function MakeTile(side, entry)
        local button = New("TextButton", {
            Name = entry.Name,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            BackgroundColor3 = THEME.Field,
            BackgroundTransparency = 0.55,
        }, side.Scroll)
        Round(button, 8)
        local stroke = Stroke(button, 0.88)
        local holder = New("Frame", {
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Size = UDim2.new(1, 0, 1, -24),
        }, button)
        local placeholder = Label(holder, {
            Text = "…",
            TextSize = 18,
            TextColor3 = THEME.Muted,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
        })
        local name = Label(button, {
            Text = TitleOf(entry),
            TextSize = 11,
            TextColor3 = THEME.SubText,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.new(0, 5, 1, -22),
            Size = UDim2.new(1, -10, 0, 20),
        })
        button.MouseButton1Click:Connect(function() Pick(side, entry) end)
        return { Entry = entry, Button = button, Stroke = stroke, Holder = holder, Placeholder = placeholder, Name = name }
    end

    local function DestroyTile(tile)
        DetachView(tile)
        tile.Button:Destroy()
    end

    -- Only tiles near the visible part of the scroll list hold a viewport; each one is a separate
    -- render surface that is redrawn every frame.
    local function IsNear(side, tile)
        local scroll = side.Scroll
        local top = scroll.CanvasPosition.Y
        local bottom = top + scroll.AbsoluteWindowSize.Y
        local y = tile.Button.AbsolutePosition.Y - scroll.AbsolutePosition.Y + top
        local margin = 120
        return y + tile.Button.AbsoluteSize.Y >= top - margin and y <= bottom + margin
    end

    local function UpdateVisible(side)
        for _, tile in ipairs(side.TileList) do
            if IsNear(side, tile) then AttachView(tile) elseif tile.View then DetachView(tile) end
        end
    end

    local function OnBaked(entry)
        for _, side in pairs(sides) do
            local tile = side.TileByEntry[entry]
            if tile and IsNear(side, tile) then AttachView(tile) end
        end
    end

    local WORKERS = 3
    local function Bake(side)
        if not PreviewsOn() then return end
        side.BakeToken = side.BakeToken + 1
        local mine = side.BakeToken

        local pending = {}
        for _, tile in ipairs(side.TileList) do
            if IsNear(side, tile) and not Preview.Get(tile.Entry) and not failedPreview[tile.Entry] then
                table.insert(pending, tile.Entry)
            end
        end
        if #pending == 0 then return end
        Preview.Preload(pending)

        local nextIndex = 1
        local function Worker()
            while mine == side.BakeToken and nextIndex <= #pending do
                local entry = pending[nextIndex]
                nextIndex = nextIndex + 1

                local model, reason = Preview.Bake(entry)
                if model then
                    OnBaked(entry)
                else
                    failedPreview[entry] = true
                    if reason ~= "unloaded" then warn("[Visual Emotes] Preview failed for " .. entry.Name .. ": " .. tostring(reason)) end
                end
            end
        end
        for _ = 1, math.min(WORKERS, #pending) do task.spawn(Worker) end
    end

    RefreshVisible = function(side)
        UpdateVisible(side)
        Bake(side)
    end

    -- ---------- one side (Base / Target) ----------
    local function RenderSide(side)
        local other = side == sides.Base and sides.Target or sides.Base
        local query = string.lower(side.Query)

        local entries = {}
        for _, entry in ipairs(groups[side.Group].Entries) do
            if entry ~= other.Selected and (query == "" or string.find(string.lower(entry.Display), query, 1, true)) then
                table.insert(entries, entry)
            end
        end

        local list, map = {}, {}
        for index, entry in ipairs(entries) do
            local tile = side.TileByEntry[entry] or MakeTile(side, entry)
            tile.Button.LayoutOrder = index
            tile.Name.Text = TitleOf(entry)
            list[index] = tile
            map[entry] = tile
        end
        for entry, tile in pairs(side.TileByEntry) do
            if not map[entry] then DestroyTile(tile) end
        end
        side.TileList, side.TileByEntry = list, map

        for _, tile in ipairs(list) do UpdateTileLook(side, tile) end

        local selected = side.Selected
        side.SelectedLabel.Text = selected and TitleOf(selected) or "None selected"
        side.SelectedLabel.TextColor3 = selected and THEME.Accent or THEME.Muted
    end

    local function UpdateButton()
        local state = Swap.GetState(sides.Base.Selected, sides.Target.Selected)
        SwapButton.Text = state == 3 and "Revert" or "Swap"
        SetEnabled(SwapButton, true, state ~= 1)
    end

    Refresh = function()
        RenderSide(sides.Base)
        RenderSide(sides.Target)
        UpdateButton()
        ShowHint()
        for _, side in pairs(sides) do
            task.defer(function() RefreshVisible(side) end)
        end
    end

    local function NewSide(sideName, titleText)
        local side = {
            Name = sideName, Group = 1, Query = "", Selected = nil,
            TileList = {}, TileByEntry = {}, BakeToken = 0,
        }
        sides[sideName] = side

        local frame = New("Frame", {
            Name = sideName,
            LayoutOrder = sideName == "Base" and 1 or 2,
            Size = UDim2.new(0.5, -4, 1, 0),
            BackgroundColor3 = THEME.Card,
            BackgroundTransparency = 0.94,
            BorderSizePixel = 0,
        }, PaneHolder)
        Round(frame, 10)
        Stroke(frame, 0.9)

        local inner = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, frame)
        New("UIPadding", {
            PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
        }, inner)

        Label(inner, { Text = titleText, Font = FONT_BOLD, Size = UDim2.new(0.5, 0, 0, 18) })
        side.SelectedLabel = Label(inner, {
            Text = "None selected",
            TextSize = 12,
            TextColor3 = THEME.Muted,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(0.5, 0, 0, 18),
        })

        -- category dropdown
        local categoryButton = New("TextButton", {
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            BackgroundColor3 = THEME.Field,
            BackgroundTransparency = 0.55,
            Position = UDim2.fromOffset(0, 22),
            Size = UDim2.new(1, 0, 0, 30),
        }, inner)
        Round(categoryButton, 8)
        Stroke(categoryButton, 0.9)
        local categoryLabel = Label(categoryButton, {
            Text = groups[1].Title,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -34, 1, 0),
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        Label(categoryButton, {
            Text = "v",
            TextSize = 12,
            TextColor3 = THEME.Muted,
            TextXAlignment = Enum.TextXAlignment.Center,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.fromScale(1, 0),
            Size = UDim2.new(0, 26, 1, 0),
        })

        -- search
        local search = New("TextBox", {
            Text = "",
            PlaceholderText = "Search emote...",
            PlaceholderColor3 = THEME.Muted,
            TextColor3 = THEME.Text,
            Font = FONT,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            BorderSizePixel = 0,
            BackgroundColor3 = THEME.Field,
            BackgroundTransparency = 0.55,
            Position = UDim2.fromOffset(0, 58),
            Size = UDim2.new(1, 0, 0, 30),
        }, inner)
        Round(search, 8)
        Stroke(search, 0.9)
        New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, search)

        -- grid, open from the start
        side.Scroll = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 94),
            Size = UDim2.new(1, 0, 1, -94),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = THEME.Muted,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ElasticBehavior = Enum.ElasticBehavior.Never,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
        }, inner)
        New("UIGridLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            CellSize = UDim2.new(1 / 3, -6, 0, 108),
            CellPadding = UDim2.fromOffset(6, 6),
        }, side.Scroll)
        New("UIPadding", { PaddingRight = UDim.new(0, 4) }, side.Scroll)

        -- category popup (drawn over the grid)
        local popup = New("ScrollingFrame", {
            Visible = false,
            ZIndex = 20,
            BorderSizePixel = 0,
            BackgroundColor3 = THEME.Popup,
            BackgroundTransparency = 0.02,
            Position = UDim2.fromOffset(0, 54),
            Size = UDim2.new(1, 0, 0, math.min(#groups * 30 + 8, 200)),
            ScrollBarThickness = 3,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
        }, inner)
        Round(popup, 8)
        Stroke(popup, 0.8)
        New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, popup)
        New("UIPadding", {
            PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
        }, popup)

        for index, group in ipairs(groups) do
            local item = New("TextButton", {
                Text = group.Title .. "   ·   " .. #group.Entries,
                Font = FONT,
                TextSize = 13,
                TextColor3 = THEME.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                BorderSizePixel = 0,
                BackgroundColor3 = THEME.Card,
                BackgroundTransparency = 0.94,
                LayoutOrder = index,
                ZIndex = 21,
                Size = UDim2.new(1, 0, 0, 28),
            }, popup)
            Round(item, 6)
            New("UIPadding", { PaddingLeft = UDim.new(0, 10) }, item)
            item.MouseEnter:Connect(function() item.BackgroundTransparency = 0.85 end)
            item.MouseLeave:Connect(function() item.BackgroundTransparency = 0.94 end)
            item.MouseButton1Click:Connect(function()
                side.Group = index
                categoryLabel.Text = group.Title
                popup.Visible = false
                side.Scroll.CanvasPosition = Vector2.zero
                for entry in pairs(failedPreview) do failedPreview[entry] = nil end
                Refresh()
            end)
        end

        categoryButton.MouseButton1Click:Connect(function() popup.Visible = not popup.Visible end)

        search:GetPropertyChangedSignal("Text"):Connect(function()
            side.Query = search.Text
            side.Scroll.CanvasPosition = Vector2.zero
            Refresh()
        end)

        local scrollToken = 0
        side.Scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            scrollToken = scrollToken + 1
            local mine = scrollToken
            task.delay(0.08, function()
                if mine == scrollToken then RefreshVisible(side) end
            end)
        end)
    end

    NewSide("Base", "Base Emote")
    NewSide("Target", "Target Emote")

    -- Swaps drop the old preview models (the items changed) and rebuild them.
    local function Forget(entries)
        for _, entry in ipairs(entries) do
            Preview.Invalidate(entry)
            failedPreview[entry] = nil
            for _, side in pairs(sides) do
                local tile = side.TileByEntry[entry]
                if tile then DetachView(tile) end
            end
        end
    end

    SwapButton.MouseButton1Click:Connect(function()
        local base, target = sides.Base.Selected, sides.Target.Selected
        local state = Swap.GetState(base, target)
        if state == 1 then
            SetStatus("Pick a valid Base and Target emote first.", THEME.Danger)
            return
        end

        local pair = { base, target }
        local ok, message
        if state == 2 then
            ok, message = Swap.Swap(base, target)
            SetStatus(ok and (base.Display .. " now looks like " .. target.Display) or message, ok and THEME.Success or THEME.Danger)
        else
            ok, message = Swap.Revert(base, target)
            SetStatus(ok and "Restored to normal." or message, ok and THEME.Success or THEME.Danger)
        end

        if ok then Forget(pair) end
        sides.Base.Selected, sides.Target.Selected = nil, nil
        Refresh()
    end)

    RevertAllButton.MouseButton1Click:Connect(function()
        local restored, touched = Swap.RevertAll()
        Forget(touched)
        sides.Base.Selected, sides.Target.Selected = nil, nil
        Refresh()
        SetStatus(restored > 0 and ("Restored " .. restored .. " swapped pair(s).") or "Nothing is swapped.", restored > 0 and THEME.Success or THEME.SubText)
    end)

    Refresh()

    -- Poses of every emote are gathered quietly in the background (once; saved to a file), so
    -- opening any category later is instant.
    task.spawn(function()
        if not PreviewsOn() then return end
        local list, missing = {}, 0
        for _, group in ipairs(groups) do
            for _, entry in ipairs(group.Entries) do
                table.insert(list, entry)
                if not Preview.PoseKnown(entry) then missing = missing + 1 end
            end
        end
        if missing == 0 then return end
        if missing > 20 then SetStatus("Preparing " .. missing .. " emote previews in the background (one time only)...") end
        Preview.Collect(list)
    end)
end

local Swap = NewSwap({ Category = "Emotes", Paths = DaftarPath, Noun = "emote" })
BuildEmoteUI(Swap)
