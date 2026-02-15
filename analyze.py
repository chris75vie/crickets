#!/usr/bin/env python3
"""Analyze cricket recordings using stdlib only (no numpy/librosa)."""
import wave
import struct
import math
import json
import os
import sys

def read_wav(path):
    with wave.open(path, 'r') as w:
        sr = w.getframerate()
        n = w.getnframes()
        nc = w.getnchannels()
        sw = w.getsampwidth()
        raw = w.readframes(n)
    
    if sw == 2:
        fmt = f'<{n * nc}h'
        samples = list(struct.unpack(fmt, raw))
    elif sw == 1:
        samples = [s - 128 for s in raw]
    else:
        raise ValueError(f"Unsupported sample width: {sw}")
    
    # mono mixdown
    if nc == 2:
        samples = [(samples[i] + samples[i+1]) / 2 for i in range(0, len(samples), 2)]
    
    return samples, sr

def fft_power(samples, sr, fft_size=4096):
    """Simple DFT magnitude spectrum using stdlib. Averages over windows."""
    n = len(samples)
    num_windows = max(1, n // fft_size)
    mag = [0.0] * (fft_size // 2)
    
    for w in range(num_windows):
        offset = w * fft_size
        chunk = samples[offset:offset + fft_size]
        if len(chunk) < fft_size:
            break
        
        # Hann window
        windowed = [chunk[i] * (0.5 - 0.5 * math.cos(2 * math.pi * i / fft_size)) 
                     for i in range(fft_size)]
        
        # DFT of first half (real frequencies) — but full DFT is too slow for 4096
        # Use Goertzel for specific frequency bins instead
        # Actually let's just do a coarse DFT with fewer bins
        pass
    
    # Goertzel approach: check specific frequencies
    freqs_to_check = list(range(500, 15001, 100))  # 500 Hz to 15 kHz in 100 Hz steps
    results = {}
    
    # Use a 0.1s window, average over multiple windows
    win_size = int(sr * 0.1)
    num_wins = max(1, min(20, n // win_size))
    
    for freq in freqs_to_check:
        total_power = 0.0
        for w in range(num_wins):
            offset = w * win_size
            chunk = samples[offset:offset + win_size]
            if len(chunk) < win_size:
                break
            
            # Goertzel algorithm
            k = int(0.5 + win_size * freq / sr)
            omega = 2 * math.pi * k / win_size
            coeff = 2 * math.cos(omega)
            s0 = 0.0
            s1 = 0.0
            s2 = 0.0
            for sample in chunk:
                s0 = sample + coeff * s1 - s2
                s2 = s1
                s1 = s0
            power = s1 * s1 + s2 * s2 - coeff * s1 * s2
            total_power += power
        
        results[freq] = total_power / num_wins
    
    return results

def find_peaks(spectrum, n_peaks=5):
    """Find top N frequency peaks."""
    sorted_freqs = sorted(spectrum.items(), key=lambda x: -x[1])
    peaks = []
    for freq, power in sorted_freqs:
        # Skip if too close to existing peak
        if any(abs(freq - p[0]) < 300 for p in peaks):
            continue
        peaks.append((freq, power))
        if len(peaks) >= n_peaks:
            break
    return peaks

def detect_rhythm(samples, sr, threshold_ratio=0.3):
    """Simple onset detection via amplitude envelope."""
    # RMS envelope with ~20ms windows
    win = int(sr * 0.02)
    env = []
    for i in range(0, len(samples) - win, win):
        rms = math.sqrt(sum(s*s for s in samples[i:i+win]) / win)
        env.append(rms)
    
    if not env:
        return [], 0
    
    max_rms = max(env)
    threshold = max_rms * threshold_ratio
    
    # Find onsets (crossing above threshold)
    onsets = []
    was_below = True
    for i, val in enumerate(env):
        if val > threshold and was_below:
            onsets.append(i * win / sr)  # time in seconds
            was_below = False
        elif val < threshold * 0.7:
            was_below = True
    
    # Compute inter-onset intervals
    if len(onsets) > 1:
        intervals = [onsets[i+1] - onsets[i] for i in range(len(onsets) - 1)]
    else:
        intervals = []
    
    return onsets, intervals

def analyze_file(path):
    name = os.path.basename(path)
    print(f"\n{'='*60}")
    print(f"  {name}")
    print(f"{'='*60}")
    
    samples, sr = read_wav(path)
    duration = len(samples) / sr
    print(f"  Sample rate: {sr} Hz | Duration: {duration:.2f}s")
    
    # Spectrum
    spectrum = fft_power(samples, sr)
    peaks = find_peaks(spectrum, 5)
    
    print(f"\n  Top frequencies:")
    max_power = peaks[0][1] if peaks else 1
    for freq, power in peaks:
        db = 20 * math.log10(power / max_power) if power > 0 and max_power > 0 else -99
        print(f"    {freq:6d} Hz  {db:+6.1f} dB")
    
    # Rhythm
    onsets, intervals = detect_rhythm(samples, sr)
    print(f"\n  Onsets detected: {len(onsets)}")
    if intervals:
        avg_interval = sum(intervals) / len(intervals)
        min_i = min(intervals)
        max_i = max(intervals)
        print(f"  Inter-onset intervals:")
        print(f"    avg: {avg_interval:.3f}s  min: {min_i:.3f}s  max: {max_i:.3f}s")
        print(f"    rate: ~{1/avg_interval:.1f} chirps/sec")
        # Show individual intervals
        print(f"    intervals: {[round(x,3) for x in intervals]}")
    
    return {
        "file": name,
        "sr": sr,
        "duration": duration,
        "peaks": [(f, round(20*math.log10(p/max_power),1) if p > 0 else -99) for f,p in peaks],
        "num_onsets": len(onsets),
        "intervals": [round(x,3) for x in intervals] if intervals else []
    }

# Analyze all samples
sample_dir = "projects/sound-design/samples"
files = {
    "489ss2.wav": "G. pennsylvanicus (fall field cricket)",
    "585ss2.wav": "O. fultoni (snowy tree cricket, warm)",
    "585sso.wav": "O. fultoni (snowy tree cricket, cold)",
    "141ss1.wav": "P. camellifolia (common true katydid)",
    "195ss.wav": "N. robustus (robust conehead)",
    "532ss2_4.wav": "Ground cricket (1/4 speed)",
}

results = []
for fname, species in files.items():
    path = os.path.join(sample_dir, fname)
    if os.path.exists(path):
        print(f"\n  Species: {species}")
        r = analyze_file(path)
        r["species"] = species
        results.append(r)

# Save results
with open(os.path.join(sample_dir, "analysis.json"), "w") as f:
    json.dump(results, f, indent=2)

print(f"\n\nResults saved to {sample_dir}/analysis.json")
