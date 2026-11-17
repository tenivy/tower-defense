"""Original layered game foley, generated offline with the Python standard library.

Run this file to rebuild mono 32 kHz / 16-bit WAVs. No external recordings,
downloads or runtime dependencies. Replace a WAV with a recording to audition
another sound without changing any game logic. All envelopes end in silence.
"""
from array import array
from math import exp, sin, cos, pi, tanh
from pathlib import Path
import random
import sys
import wave

ROOT = Path(__file__).parent
RATE = 32000
TAU = 2 * pi
rng = random.Random(73491)


def noise(n, cutoff=2000, highpass=0):
    result = array('d')
    a = 1 - exp(-TAU * cutoff / RATE)
    b = 1 - exp(-TAU * highpass / RATE)
    low = dc = 0.0
    for _ in range(n):
        low += a * (rng.uniform(-1, 1) - low)
        dc += b * (low - dc)
        result.append(low - dc)
    return result


def write(name, samples, room=0.05):
    # Short reflections add space without burying the attack in a long echo.
    original = array('d', samples)
    for delay, gain in [(0.037, room), (0.083, room * 0.6), (0.139, room * 0.3)]:
        shift = int(RATE * delay)
        for i in range(shift, len(samples)):
            samples[i] += gain * original[i - shift]
    mean = sum(samples) / len(samples)
    peak = max(abs(v - mean) for v in samples) or 1
    pcm = array('h')
    for i, value in enumerate(samples):
        fade = min(1.0, i / (RATE * 0.003), (len(samples) - 1 - i) / (RATE * 0.055))
        pcm.append(round((value - mean) / peak * 0.82 * 32767 * max(0, fade)))
    if sys.byteorder != 'little':
        pcm.byteswap()
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes(pcm.tobytes())
    rms = (sum((v / 32768) ** 2 for v in pcm) / len(pcm)) ** 0.5
    print(f'{name:10} {len(samples)/RATE:.2f}s  peak=0.820  rms={rms:.3f}')


def sword():
    n = int(RATE * 0.72)
    air, metal = noise(n, 6500, 900), noise(n, 11000, 1500)
    result = array('d')
    for i in range(n):
        t = i / RATE
        hit = max(0, t - 0.065)
        swish = 0.65 * air[i] * exp(-((t - 0.035) / 0.025) ** 2)
        clang = sum(a * sin(TAU * f * hit) * exp(-hit / d)
                    for f, a, d in [(1120, .23, .12), (2373, .16, .16),
                                    (3890, .10, .085), (5680, .045, .04)])
        impact = metal[i] * exp(-hit / .014) + .34 * sin(TAU * 155 * hit) * exp(-hit / .025)
        result.append(swish + (clang + impact if t >= .065 else 0))
    write('sword', result)


def arrow():
    n = int(RATE * .58)
    air, wood = noise(n, 5800, 1000), noise(n, 2300, 250)
    result = array('d')
    for i in range(n):
        t = i / RATE
        twang = sum(sin(TAU * f * t + .16 * sin(TAU * 19 * t)) * a * exp(-t / d)
                    for f, a, d in [(157, .24, .07), (323, .12, .10), (665, .07, .06)])
        flight = air[i] * .7 * (1 - exp(-t / .012)) * exp(-t / .085)
        result.append(twang + flight + .4 * wood[i] * exp(-t / .012))
    write('arrow', result, .025)


def spell():
    n = int(RATE * 1.15)
    air = noise(n, 4700, 700)
    result = array('d')
    for i in range(n):
        t = i / RATE
        envelope = (1 - exp(-t / .018)) * exp(-t / .23)
        shimmer = sum(a * sin(TAU * (f * t + sweep * (1 - exp(-t / .18))))
                      for f, a, sweep in [(523, .17, 28), (784, .11, 41),
                                          (1318, .08, 62), (2093, .04, 82)])
        result.append(envelope * (.8 * air[i] + shimmer * (1 + .15 * sin(TAU * 17 * t))))
    write('spell', result, .18)


def catapult():
    n = int(RATE * 1.08)
    wood, air, rumble = noise(n, 1900, 180), noise(n, 4000, 350), noise(n, 400, 40)
    result = array('d')
    for i in range(n):
        t = i / RATE
        creak = sin(TAU * (190 * t + 110 * t * t)) * .1 * exp(-t / .09)
        thunk = .42 * sin(TAU * 78 * t) * exp(-t / .055) + wood[i] * exp(-t / .035)
        rope = sin(TAU * (95 * t + 10 * (1 - exp(-t / .05)))) * .13 * exp(-t / .08)
        flight = air[i] * .75 * (1 - exp(-t / .018)) * exp(-t / .13)
        result.append(thunk + creak + rope + flight + .24 * rumble[i] * exp(-t / .16))
    write('catapult', result, .075)


def creature(name, duration, howl):
    n = int(RATE * duration)
    breath = noise(n, 2700 if howl else 1900, 180)
    low = noise(n, 70)
    result = array('d')
    phase = 0.0
    for i in range(n):
        t = i / RATE
        if howl:
            # Canine call: rounded rise, held vowel, falling breathy release.
            pitch = 310 + 170 * (1 - exp(-t / .21)) - 125 * (t / duration) ** 3
            pitch += 6 * sin(TAU * 4.1 * t) + 2.5 * sin(TAU * 7.3 * t)
            envelope = (1 - exp(-t / .11)) * (1 - exp(-(duration - t) / .23))
            envelope *= .9 + .1 * sin(TAU * .7 * t)
            formants = [(650, 240, .55), (1150, 280, .2), (2450, 400, .055)]
            roughness = .03
        else:
            # Irregular subharmonics and breath emulate a large, throaty growl.
            pitch = 58 + 15 * sin(pi * t / duration) + 4 * sin(TAU * 7.4 * t) + 18 * low[i]
            envelope = (1 - exp(-t / .045)) * (1 - exp(-(duration - t) / .14))
            envelope *= .65 + .2 * sin(TAU * 2.6 * t) + .15 * sin(TAU * 11 * t) ** 2
            formants = [(330, 130, .8), (850, 220, .42), (1640, 330, .16)]
            roughness = .42
        phase += TAU * pitch / RATE
        voice = 0.0
        for h in range(1, 31 if not howl else 12):
            freq = h * pitch
            weight = .07 / h + sum(a * exp(-.5 * ((freq - f) / w) ** 2) for f, w, a in formants)
            voice += weight * sin(h * phase + .025 * h * sin(TAU * 23 * t)) / h ** .45
        voice += roughness * sin(phase * .5) + breath[i] * (.08 if howl else .55)
        if not howl:
            voice = tanh(voice * 1.35)
        result.append(envelope * voice)
    write(name, result, .12 if howl else .06)


def ui_click():
    # Short wooden press with a soft brass tick, matching the medieval interface.
    n = int(RATE * .11)
    local_rng = random.Random(218)
    result = array('d')
    low = 0.0
    for i in range(n):
        t = i / RATE
        low += .28 * (local_rng.uniform(-1, 1) - low)
        attack = 1 - exp(-t / .0008)
        wood = .5 * sin(TAU * 285 * t) * exp(-t / .009)
        brass = (.13 * sin(TAU * 1460 * t) + .07 * sin(TAU * 2370 * t)) * exp(-t / .014)
        result.append(attack * (wood + brass + .45 * low * exp(-t / .005)))
    write('ui-click', result, .015)


if __name__ == '__main__':
    sword()
    arrow()
    spell()
    catapult()
    creature('ogre', 1.65, False)
    creature('werewolf', 2.6, True)
    ui_click()
