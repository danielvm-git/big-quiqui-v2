#!/usr/bin/env python3
# story: e12s01
from pathlib import Path

ROOT = Path("/Users/danielvm/Developer/big-quiqui-v2-e12/game/scripts/scenes")
KEYS = {
    "closet_intro.ogg": "vo.closet.intro",
    "kitchen_intro.ogg": "vo.kitchen.intro",
    "celebration_congrats.ogg": "vo.celebration.congrats",
    "village_welcome.ogg": "vo.village.welcome",
    "market_choose.ogg": "vo.market.intro",
    "home_welcome.ogg": "vo.home.welcome",
    "playhouse_party_congrats.ogg": "vo.party.congrats",
    "playroom_intro.ogg": "vo.playroom.intro",
    "bathroom_intro.ogg": "vo.bathroom.intro",
    "wheel_good_luck.ogg": "vo.wheel.intro",
}

for path in ROOT.glob("*.gd"):
    text = path.read_text(encoding="utf-8")
    orig = text
    for tail, key in KEYS.items():
        old = f'const VOICE_PATH: String = "res://assets/audio/voice/pt_BR/{tail}"'
        if old in text:
            text = text.replace(old, f'const VOICE_KEY: String = "{key}"')
    text = text.replace('_play_stream("play_voice", VOICE_PATH)', "AudioManager.play_voice_key(VOICE_KEY)")
    if "VOICE_PATH" in text and "casa.gd" in str(path):
        text = text.replace(
            """func _play_voice() -> void:
\tif not ResourceLoader.exists(VOICE_PATH):
\t\treturn
\tvar manager: Node = get_node_or_null("/root/AudioManager")
\tif manager == null:
\t\treturn
\tvar stream: AudioStream = load(VOICE_PATH) as AudioStream
\tif stream == null:
\t\treturn
\tvoice_started = bool(manager.call("play_voice", stream))""",
            """func _play_voice() -> void:
\tvoice_started = AudioManager.play_voice_key(VOICE_KEY)""",
        )
        text = text.replace('const VOICE_PATH: String = "res://assets/audio/voice/pt_BR/home_welcome.ogg"', 'const VOICE_KEY: String = "vo.home.welcome"')
    if "roda.gd" in str(path):
        text = text.replace('const VOICE_PATH: String = "res://assets/audio/voice/pt_BR/wheel_good_luck.ogg"', 'const VOICE_KEY: String = "vo.wheel.intro"')
        text = text.replace(
            """func _play_voice() -> void:
\tif not ResourceLoader.exists(VOICE_PATH):
\t\treturn
\tvar audio: Node = get_node_or_null("/root/AudioManager")
\tif audio == null:
\t\treturn
\tvar stream: AudioStream = load(VOICE_PATH) as AudioStream
\tif stream != null:
\t\taudio.call("play_voice", stream)""",
            """func _play_voice() -> void:
\tAudioManager.play_voice_key(VOICE_KEY)""",
        )
    if text != orig:
        path.write_text(text, encoding="utf-8")
