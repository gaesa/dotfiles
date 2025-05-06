local input = require("mp.input")
local mp = require("mp")

local presets = {
    {
        name = "1. Auto -24LUFS",
        af = "loudnorm=I=-24:LRA=15:TP=-1,aresample=48000:out_sample_fmt=fltp:resampler=soxr",
    },
    {
        name = "2. M1 -10dB",
        af = "volume=-10dB,acompressor=threshold=-15dB:ratio=2:attack=20:release=200,alimiter=limit=0.89,aresample=48000:out_sample_fmt=fltp:resampler=soxr",
    },
    {
        name = "3. M2 -7dB",
        af = "volume=-7dB,acompressor=threshold=-15dB:ratio=2:attack=20:release=200,alimiter=limit=0.89,aresample=48000:out_sample_fmt=fltp:resampler=soxr",
    },
    {
        name = "4. M3 -4dB",
        af = "volume=-4dB,acompressor=threshold=-15dB:ratio=2:attack=20:release=200,alimiter=limit=0.89,aresample=48000:out_sample_fmt=fltp:resampler=soxr",
    },
    {
        name = "0. Raw",
        af = "anull",
    },
}

local function get_names()
    local names = {}
    for _, p in ipairs(presets) do
        table.insert(names, p.name)
    end
    return names
end

local function show_af_selector()
    input.select({
        prompt = "Select af preset",
        items = get_names(),
        submit = function(index)
            local preset = presets[index]
            mp.set_property("af", preset.af)
            mp.osd_message("Apply filter preset " .. preset.name)
        end,
    })
end

mp.add_key_binding("Shift+a", "choose-af", show_af_selector)
