-- Visual Emotes (standalone) - by Honami
-- UI is the Mugiwara UI library; swap and preview logic ported from Mugiwara HUB's
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
-- Mugiwara UI
-- ==========================================================
local UI_VERSION = "v0.10.0"
local UI_URL = "https://raw.githubusercontent.com/honamichanhere/Mugiwara-UI/" .. UI_VERSION .. "/dist/main.lua"

local uiOk, MugiwaraUI = pcall(function() return loadstring(game:HttpGet(UI_URL))() end)
if not uiOk or type(MugiwaraUI) ~= "table" or type(MugiwaraUI.CreateWindow) ~= "function" then
    warn("[Visual Emotes] UI library failed to load. Please try again.")
    return
end
RegisterCleanup(function() pcall(function() MugiwaraUI:Destroy() end) end)

local Window = MugiwaraUI:CreateWindow({
    Title = "Visual Emotes",
    Subtitle = "by Honami",
    Icon = "lucide:drama",
    Folder = FOLDER,
    Version = "v2.0",
    Size = UDim2.fromOffset(640, 420),
})
RegisterCleanup(function() pcall(function() Window:Destroy() end) end)

local Tab = Window:Tab({ Title = "Emotes", Icon = "lucide:drama" })
local Section = Tab:Section({ Title = "Visual Emotes", Icon = "lucide:drama", Box = true })

-- ==========================================================
-- Grid UI: category dropdown + viewport grid on each side, Swap/Revert
-- (ported from Games/Evade/VisualGridUI.lua; Locked/IsPremium removed - no premium tier here)
-- ==========================================================
local HEADER_ORDER = { "Normal", "Gamepasses", "Halloween", "Winter Holidays", "Summer", "Spring", "Valentines", "Event", "Special" }
local LOOK = { Rotate = false, Yaw = 155, Pitch = 10, FieldOfView = 30, Zoom = 1 }

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

local function BuildGridUI(Section, Swap)
    local function Notify(title, content, duration)
        MugiwaraUI:Notify({ Title = title, Content = content, Duration = duration or 3 })
    end

    if Swap.Load() == 0 then
        Section:Paragraph({
            Title = "Visual Emotes Unavailable",
            Desc = "No emotes were found in this game. The game may have changed its item folders.",
            Icon = "lucide:triangle-alert"
        })
        return
    end

    local all = Swap.GetEntries()
    local groups = BuildGroups(all)
    local byName = {}
    for _, entry in ipairs(all) do byName[entry.Name] = entry end

    local previewState = nil
    local previewWarned = false
    local function PreviewsOn()
        if previewState == nil then
            previewState = Preview.Available() and true or false
            if not previewState then Notify("Visual Emotes", "Previews are not available in this game version, showing icons instead.", 4) end
        end
        return previewState
    end
    local failedPreview = {}

    local base, target = nil, nil
    local notifiedWhitelist = false
    local sides = {}
    local SwapButton
    local Refresh

    local function TitleOf(entry)
        local partner = Swap.GetPartner(entry)
        return partner and (entry.Display .. " (" .. partner.Display .. ")") or entry.Display
    end

    local function ItemFor(entry, withView)
        local item = { Title = TitleOf(entry) }
        local model = withView and Preview.Get(entry) or nil
        if model then
            item.Viewport = model
        else
            item.Icon = "lucide:music"
        end
        return item
    end

    local function VisibleEntries(side, onlyName, excluded)
        local source = onlyName and { byName[onlyName] } or groups[side.Group].Entries
        local entries = {}
        for _, entry in ipairs(source) do
            if entry ~= excluded then table.insert(entries, entry) end
        end
        return entries
    end

    local function Present(side, entries)
        local items, lookup, signature = {}, {}, {}
        for _, entry in ipairs(entries) do
            local item = ItemFor(entry, side.IsOpen)
            table.insert(items, item)
            lookup[item.Title] = entry
            table.insert(signature, item.Title .. (item.Viewport and "+" or "-"))
        end
        side.Entries = entries

        local key = table.concat(signature, "|")
        if key ~= side.Signature then
            side.Signature = key
            side.Lookup = lookup
            side.Grid:Refresh(items, false)
        else
            side.Lookup = lookup
        end

        local chosen
        if side == sides.Base then chosen = base else chosen = target end
        local wanted = chosen and TitleOf(chosen) or nil
        if side.Grid:Get() ~= wanted then side.Grid:Set(wanted, true) end
    end

    local WORKERS = 3
    local REFRESH_AFTER = { [6] = true, [14] = true, [24] = true }

    local function Bake(side)
        if not PreviewsOn() then return end
        side.Token = side.Token + 1
        local mine = side.Token

        local pending = {}
        for _, entry in ipairs(side.Entries or {}) do
            if not Preview.Get(entry) and not failedPreview[entry] then table.insert(pending, entry) end
        end
        if #pending == 0 then
            Refresh()
            return
        end

        if #pending > 6 then Notify("Visual Emotes", "Rendering " .. #pending .. " previews...", 2) end
        Preview.Preload(pending)

        local nextIndex, done, active = 1, 0, 0

        local function Worker()
            while mine == side.Token and nextIndex <= #pending do
                local entry = pending[nextIndex]
                nextIndex = nextIndex + 1

                local model, reason = Preview.Bake(entry)
                if not model then
                    failedPreview[entry] = true
                    if reason ~= "unloaded" then
                        warn("[Visual Emotes] Preview failed for " .. entry.Name .. ": " .. tostring(reason))
                        if not previewWarned then
                            previewWarned = true
                            Notify("Visual Emotes", "Could not render a preview: " .. tostring(reason), 5)
                        end
                    end
                end

                done = done + 1
                if mine == side.Token and REFRESH_AFTER[done] then Refresh() end
            end

            active = active - 1
            if active == 0 and mine == side.Token then Refresh() end
        end

        for _ = 1, math.min(WORKERS, #pending) do
            active = active + 1
            task.spawn(Worker)
        end
    end

    local function UpdateButton()
        local state = Swap.GetState(base, target)
        if state == 3 then
            SwapButton:SetTitle("Revert")
            SwapButton:SetIcon("lucide:undo-2")
            SwapButton:SetDesc("Restore these two emotes to normal.")
        else
            SwapButton:SetTitle("Swap")
            SwapButton:SetIcon("lucide:repeat")
            SwapButton:SetDesc(state == 2 and "Swap the two emotes visually." or "Pick a Base and a Target emote first. An emote that is already swapped must be reverted before it can be swapped again.")
        end
    end

    Refresh = function()
        local targetOnly = base and Swap.GetWhitelist(base) or nil
        local baseOnly = target and Swap.GetWhitelist(target) or nil

        if target and ((targetOnly and target.Name ~= targetOnly) or target == base) then target = nil end
        if base and ((baseOnly and base.Name ~= baseOnly) or base == target) then base = nil end

        Present(sides.Base, VisibleEntries(sides.Base, baseOnly, target))
        Present(sides.Target, VisibleEntries(sides.Target, targetOnly, base))
        UpdateButton()
    end

    local function Picked(entry)
        if entry and Swap.GetWhitelist(entry) and not notifiedWhitelist then
            notifiedWhitelist = true
            Notify("Visual Emotes", "Whitelist applied! This emote is restricted to a specific pair.", 4)
        end
        if not entry then notifiedWhitelist = false end
    end

    local function CategoryItems()
        local items = {}
        for _, group in ipairs(groups) do
            table.insert(items, { Title = group.Title, Desc = #group.Entries .. " emotes", Icon = "lucide:folder" })
        end
        return items
    end

    local function GroupIndexOf(title)
        for index, group in ipairs(groups) do
            if group.Title == title then return index end
        end
        return 1
    end

    local function BuildSide(sideName, titleText, descText, icon, isBase)
        local side = { Name = sideName, Group = 1, Token = 0, Signature = nil, Entries = {}, Lookup = {}, IsOpen = false }
        sides[sideName] = side

        Section:Dropdown({
            Title = titleText .. " Category",
            Desc = descText,
            Icon = "lucide:folder-open",
            Values = CategoryItems(),
            Value = groups[1].Title,
            Callback = function(Option)
                if type(Option) ~= "string" then return end
                side.Group = GroupIndexOf(Option)
                if isBase then base = nil else target = nil end
                Picked(nil)
                Refresh()
                Bake(side)
            end
        })

        side.Grid = Section:GridDropdown({
            Title = titleText,
            Icon = icon,
            Values = {},
            AllowNone = true,
            Searchable = true,
            Placeholder = "Select an emote...",
            Columns = 4,
            CellHeight = 124,
            MaxHeight = 300,
            Viewport = LOOK,
            Callback = function(Option)
                side.IsOpen = false
                local entry = type(Option) == "string" and side.Lookup[Option] or nil
                if isBase then base = entry else target = entry end
                Picked(entry)
                Refresh()
            end
        })

        side.Grid.Top.MouseButton1Click:Connect(function()
            side.IsOpen = not side.IsOpen
            if side.IsOpen then
                for _, entry in ipairs(side.Entries) do failedPreview[entry] = nil end
                previewWarned = false
                Bake(side)
            else
                Refresh()
            end
        end)
        return side
    end

    BuildSide("Base", "Base Emote", "Category of the emote you will change.", "lucide:music", true)
    BuildSide("Target", "Target Emote", "Category of the emote it will look like.", "lucide:drama", false)

    local collecting = false
    local function StartCollector()
        if collecting or not PreviewsOn() then return end
        collecting = true
        task.spawn(function()
            local list, missing = {}, 0
            for _, group in ipairs(groups) do
                for _, entry in ipairs(group.Entries) do
                    table.insert(list, entry)
                    if not Preview.PoseKnown(entry) then missing = missing + 1 end
                end
            end
            if missing == 0 then return end
            if missing > 20 then Notify("Visual Emotes", "Preparing " .. missing .. " emote previews in the background (one time only)...", 4) end
            local collected = Preview.Collect(list)
            if missing > 20 and collected > 0 then Notify("Visual Emotes", "Emote previews are ready.", 3) end
        end)
    end

    local warmed = false
    local header = Section.Frame and Section.Frame:FindFirstChild("Header", true)
    if header then
        header.MouseButton1Click:Connect(function()
            if not warmed then
                warmed = true
                Bake(sides.Base)
                StartCollector()
            end
        end)
    end

    local function Forget(entries)
        for _, entry in ipairs(entries) do
            Preview.Invalidate(entry)
            failedPreview[entry] = nil
        end
    end

    SwapButton = Section:Button({
        Title = "Swap",
        Desc = "Pick a Base and a Target emote first.",
        Icon = "lucide:repeat",
        Callback = function()
            local state = Swap.GetState(base, target)
            if state == 1 then
                Notify("Swap Unavailable", "Please make sure you picked a valid Base and Target emote.", 3)
                return
            end

            local pair = { base, target }
            local ok, message
            if state == 2 then
                ok, message = Swap.Swap(base, target)
                Notify(ok and "Swap Successful!" or "Swap Failed", message, 3)
            else
                ok, message = Swap.Revert(base, target)
                Notify(ok and "Revert Successful!" or "Revert Failed", message, 3)
            end

            if ok then Forget(pair) end

            base, target, notifiedWhitelist = nil, nil, false
            Refresh()
            Bake(sides.Base)
            Bake(sides.Target)
        end
    })

    Section:Button({
        Title = "Revert All",
        Desc = "Put every swapped emote back to normal.",
        Icon = "lucide:rotate-ccw",
        Callback = function()
            local restored, touched = Swap.RevertAll()
            Notify("Visual Emotes", restored > 0 and ("Restored " .. restored .. " swapped pair(s).") or "Nothing is swapped.", 3)
            Forget(touched)
            base, target, notifiedWhitelist = nil, nil, false
            Refresh()
            Bake(sides.Base)
            Bake(sides.Target)
        end
    })

    Refresh()
end

local Swap = NewSwap({ Category = "Emotes", Paths = DaftarPath, Noun = "emote" })
BuildGridUI(Section, Swap)
