"""Generate deterministic sci-fi sound effects for TD Survival.

The generator uses only the Python standard library so the WAV assets can be
recreated on any development machine without checking in an audio toolchain.
"""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 44_100
ASSET_AUDIO_DIR = Path(__file__).resolve().parents[1] / "assets" / "audio"
OUTPUT_CATEGORIES = {
    "ui_click.wav": "ui",
    "level_up.wav": "gameplay",
    "boss_warning.wav": "events",
    "boss_spawn.wav": "events",
    "core_skill.wav": "gameplay",
    "hit_light.wav": "combat",
    "hit_heavy.wav": "combat",
    "core_hit.wav": "combat",
    "victory.wav": "events",
    "defeat.wav": "events",
    "core_skill_emerald.wav": "gameplay",
    "core_skill_sapphire.wav": "gameplay",
    "core_skill_amethyst.wav": "gameplay",
    "core_skill_jade.wav": "gameplay",
    "core_skill_obsidian.wav": "gameplay",
    "tower_rapid.wav": "combat",
    "tower_blast.wav": "combat",
    "tower_energy.wav": "combat",
    "tower_saw.wav": "combat",
    "tower_arcane.wav": "combat",
}
TAU = math.tau


def envelope(t: float, duration: float, attack: float = 0.01, release: float = 0.12) -> float:
    attack_gain = min(t / max(attack, 1e-5), 1.0)
    release_gain = min((duration - t) / max(release, 1e-5), 1.0)
    return max(min(attack_gain, release_gain), 0.0)


def note(t: float, start: float, duration: float, frequency: float, gain: float = 1.0) -> float:
    local = t - start
    if local < 0.0 or local >= duration:
        return 0.0
    env = envelope(local, duration, 0.012, min(0.16, duration * 0.45))
    fundamental = math.sin(TAU * frequency * local)
    shimmer = math.sin(TAU * frequency * 2.01 * local) * 0.24
    return (fundamental + shimmer) * env * gain


def render(name: str, duration: float, sample_function) -> None:
    count = round(duration * SAMPLE_RATE)
    samples = [sample_function(index / SAMPLE_RATE) for index in range(count)]
    fade_count = min(round(SAMPLE_RATE * 0.015), max(count // 2, 1))
    for index in range(fade_count):
        samples[index] *= index / fade_count
        samples[-index - 1] *= index / fade_count
    peak = max(max(abs(value) for value in samples), 1e-6)
    scale = 0.88 / peak
    pcm = b"".join(struct.pack("<h", round(max(-1.0, min(1.0, value * scale)) * 32767)) for value in samples)
    output_dir = ASSET_AUDIO_DIR / OUTPUT_CATEGORIES[name]
    output_dir.mkdir(parents=True, exist_ok=True)
    with wave.open(str(output_dir / name), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(pcm)


def generate() -> None:
    rng = random.Random(0x7D5F)
    click_noise = [rng.uniform(-1.0, 1.0) for _ in range(round(0.1 * SAMPLE_RATE))]
    render(
        "ui_click.wav",
        0.1,
        lambda t: (
            math.sin(TAU * (920.0 - 510.0 * t / 0.1) * t) * math.exp(-32.0 * t)
            + click_noise[min(int(t * SAMPLE_RATE), len(click_noise) - 1)] * math.exp(-55.0 * t) * 0.22
        ),
    )

    level_notes = [(0.0, 523.25), (0.11, 659.25), (0.22, 783.99), (0.34, 1046.5)]
    render(
        "level_up.wav",
        0.72,
        lambda t: sum(note(t, start, 0.32, frequency, 0.75) for start, frequency in level_notes)
        + math.sin(TAU * 1568.0 * t) * envelope(t, 0.72, 0.2, 0.3) * 0.08,
    )

    warning_noise = [rng.uniform(-1.0, 1.0) for _ in range(round(1.05 * SAMPLE_RATE))]

    def warning(t: float) -> float:
        pulse = 1.0 if (0.08 <= t < 0.38) or (0.55 <= t < 0.88) else 0.0
        local = t - (0.08 if t < 0.5 else 0.55)
        alarm = math.sin(TAU * (172.0 + 35.0 * math.sin(TAU * 5.0 * local)) * local)
        grit = warning_noise[min(int(t * SAMPLE_RATE), len(warning_noise) - 1)] * 0.08
        return (alarm + grit) * pulse * envelope(max(local, 0.0), 0.33, 0.02, 0.08)

    render("boss_warning.wav", 1.05, warning)

    boss_noise = [rng.uniform(-1.0, 1.0) for _ in range(round(1.1 * SAMPLE_RATE))]

    def boss_spawn(t: float) -> float:
        bass_frequency = 96.0 - 52.0 * min(t / 0.8, 1.0)
        bass = math.sin(TAU * bass_frequency * t) + 0.35 * math.sin(TAU * bass_frequency * 0.5 * t)
        metal = math.sin(TAU * (620.0 - 390.0 * min(t / 0.7, 1.0)) * t) * math.exp(-3.8 * t)
        noise = boss_noise[min(int(t * SAMPLE_RATE), len(boss_noise) - 1)] * math.exp(-5.0 * t)
        return (bass * 0.72 + metal * 0.22 + noise * 0.16) * envelope(t, 1.1, 0.015, 0.35)

    render("boss_spawn.wav", 1.1, boss_spawn)

    skill_noise = [rng.uniform(-1.0, 1.0) for _ in range(round(0.95 * SAMPLE_RATE))]

    def core_skill(t: float) -> float:
        charge_progress = min(t / 0.58, 1.0)
        charge_frequency = 180.0 + 1120.0 * charge_progress * charge_progress
        charge = math.sin(TAU * charge_frequency * t) * envelope(t, 0.62, 0.08, 0.06) * 0.55
        impact_t = t - 0.58
        if impact_t < 0.0:
            return charge
        impact = math.sin(TAU * (118.0 - 55.0 * impact_t) * impact_t) * math.exp(-5.5 * impact_t)
        sparkle = math.sin(TAU * 1640.0 * impact_t) * math.exp(-8.0 * impact_t)
        noise = skill_noise[min(int(t * SAMPLE_RATE), len(skill_noise) - 1)] * math.exp(-10.0 * impact_t)
        return charge + impact * 0.85 + sparkle * 0.2 + noise * 0.14

    render("core_skill.wav", 0.95, core_skill)

    emerald_noise = [rng.uniform(-1.0, 1.0) for _ in range(round(1.0 * SAMPLE_RATE))]
    render(
        "core_skill_emerald.wav",
        1.0,
        lambda t: (
            math.sin(TAU * (240.0 + 980.0 * min(t / 0.62, 1.0) ** 2) * t) * envelope(t, 0.68, 0.09, 0.08) * 0.46
            + note(t, 0.12, 0.34, 659.25, 0.28)
            + note(t, 0.30, 0.34, 987.77, 0.25)
            + math.sin(TAU * 92.0 * max(t - 0.62, 0.0)) * math.exp(-7.0 * max(t - 0.62, 0.0)) * (1.0 if t >= 0.62 else 0.0) * 0.8
            + emerald_noise[min(int(t * SAMPLE_RATE), len(emerald_noise) - 1)] * math.exp(-15.0 * max(t - 0.62, 0.0)) * (1.0 if t >= 0.62 else 0.0) * 0.1
        ),
    )

    render(
        "core_skill_sapphire.wav",
        1.08,
        lambda t: (
            math.sin(TAU * (310.0 + 1480.0 * min(t / 0.72, 1.0)) * t) * envelope(t, 0.76, 0.12, 0.08) * 0.38
            + math.sin(TAU * (620.0 + 480.0 * math.sin(TAU * 2.2 * t)) * t) * envelope(t, 0.82, 0.16, 0.1) * 0.18
            + note(t, 0.68, 0.38, 1174.66, 0.62)
            + note(t, 0.73, 0.34, 1567.98, 0.34)
        ),
    )

    amethyst_noise = [rng.uniform(-1.0, 1.0) for _ in range(round(1.06 * SAMPLE_RATE))]
    render(
        "core_skill_amethyst.wav",
        1.06,
        lambda t: (
            math.sin(TAU * 146.83 * t) * envelope(t, 1.0, 0.18, 0.3) * 0.42
            + math.sin(TAU * 220.0 * t) * envelope(t, 0.92, 0.16, 0.22) * 0.3
            + sum(note(t, 0.58 + pulse * 0.09, 0.28, 440.0 - pulse * 55.0, 0.38) for pulse in range(3))
            + amethyst_noise[min(int(t * SAMPLE_RATE), len(amethyst_noise) - 1)] * envelope(t, 1.06, 0.32, 0.28) * 0.07
        ),
    )

    jade_noise = [rng.uniform(-1.0, 1.0) for _ in range(round(1.18 * SAMPLE_RATE))]
    render(
        "core_skill_jade.wav",
        1.18,
        lambda t: (
            sum(note(t, start, 0.42, frequency, 0.38) for start, frequency in [(0.0, 698.46), (0.16, 523.25), (0.32, 392.0), (0.48, 293.66)])
            + math.sin(TAU * (118.0 - 42.0 * min(t, 1.0)) * t) * envelope(t, 1.18, 0.25, 0.32) * 0.34
            + jade_noise[min(int(t * SAMPLE_RATE), len(jade_noise) - 1)] * envelope(t, 1.18, 0.3, 0.4) * 0.06
        ),
    )

    obsidian_noise = [rng.uniform(-1.0, 1.0) for _ in range(round(1.2 * SAMPLE_RATE))]
    render(
        "core_skill_obsidian.wav",
        1.2,
        lambda t: (
            note(t, 0.0, 1.05, 110.0, 0.48)
            + note(t, 0.0, 1.05, 164.81, 0.3)
            + math.sin(TAU * 880.0 * t) * math.exp(-5.5 * t) * 0.44
            + math.sin(TAU * 58.0 * max(t - 0.62, 0.0)) * math.exp(-4.6 * max(t - 0.62, 0.0)) * (1.0 if t >= 0.62 else 0.0) * 0.85
            + obsidian_noise[min(int(t * SAMPLE_RATE), len(obsidian_noise) - 1)] * math.exp(-9.0 * max(t - 0.62, 0.0)) * (1.0 if t >= 0.62 else 0.0) * 0.13
        ),
    )

    light_noise = [rng.uniform(-1.0, 1.0) for _ in range(round(0.14 * SAMPLE_RATE))]
    render(
        "hit_light.wav",
        0.14,
        lambda t: math.sin(TAU * (310.0 - 130.0 * t / 0.14) * t) * math.exp(-25.0 * t)
        + light_noise[min(int(t * SAMPLE_RATE), len(light_noise) - 1)] * math.exp(-35.0 * t) * 0.45,
    )

    heavy_noise = [rng.uniform(-1.0, 1.0) for _ in range(round(0.32 * SAMPLE_RATE))]
    render(
        "hit_heavy.wav",
        0.32,
        lambda t: (
            math.sin(TAU * (126.0 - 62.0 * t / 0.32) * t) * math.exp(-8.0 * t)
            + math.sin(TAU * 48.0 * t) * math.exp(-5.5 * t) * 0.55
            + heavy_noise[min(int(t * SAMPLE_RATE), len(heavy_noise) - 1)] * math.exp(-18.0 * t) * 0.3
        ),
    )

    core_noise = [rng.uniform(-1.0, 1.0) for _ in range(round(0.48 * SAMPLE_RATE))]
    render(
        "core_hit.wav",
        0.48,
        lambda t: (
            math.sin(TAU * (78.0 - 24.0 * t / 0.48) * t) * math.exp(-5.0 * t)
            + math.sin(TAU * 438.0 * t) * math.exp(-12.0 * t) * 0.32
            + core_noise[min(int(t * SAMPLE_RATE), len(core_noise) - 1)] * math.exp(-15.0 * t) * 0.28
        ),
    )

    rapid_noise = [rng.uniform(-1.0, 1.0) for _ in range(round(0.11 * SAMPLE_RATE))]
    render(
        "tower_rapid.wav",
        0.11,
        lambda t: math.sin(TAU * (760.0 - 390.0 * t / 0.11) * t) * math.exp(-30.0 * t)
        + rapid_noise[min(int(t * SAMPLE_RATE), len(rapid_noise) - 1)] * math.exp(-48.0 * t) * 0.24,
    )

    blast_noise = [rng.uniform(-1.0, 1.0) for _ in range(round(0.34 * SAMPLE_RATE))]
    render(
        "tower_blast.wav",
        0.34,
        lambda t: math.sin(TAU * (112.0 - 54.0 * t / 0.34) * t) * math.exp(-7.5 * t)
        + math.sin(TAU * 43.0 * t) * math.exp(-5.0 * t) * 0.48
        + blast_noise[min(int(t * SAMPLE_RATE), len(blast_noise) - 1)] * math.exp(-15.0 * t) * 0.34,
    )

    render(
        "tower_energy.wav",
        0.22,
        lambda t: math.sin(TAU * (1380.0 - 720.0 * t / 0.22) * t) * envelope(t, 0.22, 0.008, 0.13) * 0.65
        + math.sin(TAU * 2760.0 * t) * math.exp(-18.0 * t) * 0.18,
    )

    saw_noise = [rng.uniform(-1.0, 1.0) for _ in range(round(0.24 * SAMPLE_RATE))]
    render(
        "tower_saw.wav",
        0.24,
        lambda t: (
            (1.0 if math.sin(TAU * (94.0 + 170.0 * t) * t) >= 0.0 else -1.0) * envelope(t, 0.24, 0.012, 0.11) * 0.42
            + saw_noise[min(int(t * SAMPLE_RATE), len(saw_noise) - 1)] * envelope(t, 0.24, 0.008, 0.12) * 0.3
        ),
    )

    render(
        "tower_arcane.wav",
        0.29,
        lambda t: note(t, 0.0, 0.27, 783.99, 0.62)
        + note(t, 0.035, 0.24, 1174.66, 0.34)
        + math.sin(TAU * 196.0 * t) * math.exp(-10.0 * t) * 0.24,
    )

    victory_notes = [(0.0, 392.0), (0.16, 493.88), (0.32, 587.33), (0.49, 783.99)]
    render(
        "victory.wav",
        1.45,
        lambda t: sum(note(t, start, 0.58, frequency, 0.62) for start, frequency in victory_notes)
        + note(t, 0.52, 0.86, 392.0, 0.25)
        + note(t, 0.52, 0.86, 493.88, 0.22)
        + note(t, 0.52, 0.86, 587.33, 0.2),
    )

    defeat_notes = [(0.0, 392.0), (0.22, 293.66), (0.46, 233.08), (0.7, 146.83)]
    render(
        "defeat.wav",
        1.5,
        lambda t: sum(note(t, start, 0.54, frequency, 0.6) for start, frequency in defeat_notes)
        + math.sin(TAU * 55.0 * t) * envelope(t, 1.5, 0.45, 0.5) * 0.22,
    )


if __name__ == "__main__":
    generate()
    print(f"Generated {len(OUTPUT_CATEGORIES)} sound effects in categorized folders under {ASSET_AUDIO_DIR}")
