extends Node

func _ready() -> void:
    pass

func _build_tone_stream(effect_name: String) -> AudioStreamWAV:
    var stream = AudioStreamWAV.new()
    var sample_rate := 44100
    var duration := 0.08
    var frequency := 440.0
    var amplitude := 0.25

    match effect_name:
        "drop":
            frequency = 180.0
            duration = 0.04
        "success":
            frequency = 560.0
            duration = 0.18
        "fail":
            frequency = 110.0
            duration = 0.22
            amplitude = 0.35

    var frame_count = int(sample_rate * duration)
    var data = PackedByteArray()
    data.resize(frame_count * 2)

    for i in range(frame_count):
        var t = float(i) / float(sample_rate)
        var sample_value = sin(TAU * frequency * t) * amplitude
        var sample = int(clamp(sample_value, -1.0, 1.0) * 32767.0)
        data[i * 2] = sample & 0xFF
        data[i * 2 + 1] = (sample >> 8) & 0xFF

    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    stream.data = data
    return stream
