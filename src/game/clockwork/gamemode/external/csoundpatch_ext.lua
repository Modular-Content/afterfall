local META = FindMetaTable 'CSoundPatch'

local Wrapper = {}
Wrapper.__index = Wrapper

local function forward(method)
    return function(self, ...) return method(self._snd, ...) end
end

for name, fn in next, META do
    if isfunction(fn) then
        Wrapper[name] = forward(fn)
    end
end

function Wrapper:Play()
    self._fadeRequested = false
    self._snd:Play()
end

function Wrapper:PlayEx(vol, pitch)
    self._fadeRequested = false
    self._snd:PlayEx(vol, pitch)
end

function Wrapper:FadeOut(time)
    if self._fadeRequested then return end
    self._fadeRequested = true
    if self._snd:IsPlaying() then self._snd:FadeOut(time) end
end

function Wrapper:IsFading()
    return self._fadeRequested and self._snd:IsPlaying()
end

local function newSoundObject(soundObj)
    return setmetatable({
        _snd = soundObj,
        _fadeRequested = false
    }, Wrapper)
end

function CreateSoundExt(ent, snd, filter)
    local base = CreateSound(ent, snd, filter)
    return newSoundObject(base)
end