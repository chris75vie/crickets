// Species.scd — SynthDefs modeled from SINA recordings
// Each species has its own voice based on spectral analysis
//
// Species:
//   \fieldCricket   — G. pennsylvanicus (4.6 kHz, paired chirps)
//   \treeCricket    — O. fultoni (2.9 kHz, pure melodic chirps)
//   \katydid        — P. camellifolia (broadband 3-5 kHz, "ka-ty-did")
//   \conehead       — N. robustus (6.7 kHz, continuous drone)
//   \groundCricket  — Nemobiinae (~8 kHz, soft continuous trill)
//
// Aesop & Yoda, 2026-02-14

s.boot;

// ============================================================
// 1. FIELD CRICKET — G. pennsylvanicus
//    Dominant: 4600 Hz, harmonic at ~9200 Hz
//    Rhythm: paired chirps (2 pulses ~0.04s apart), gap ~0.6s
// ============================================================
(
SynthDef(\fieldCricket, {
	arg period=0.9, duty=0.12, cfreq=4600, features=7,
	    amp=0.1, pan=0, out=0,
	    freqDrift=40, noiseAmt=0.06;

	var sig, env, freq, freq2, modulator, mod2, mod3, mod4;
	var cfreqVar, noise;

	cfreqVar = cfreq + LFNoise1.kr(0.5).range(freqDrift.neg, freqDrift);

	// Stepped onset envelope
	env = EnvGen.kr(
		Env.new(
			levels: [0, 0.3, 0.7, 1, 1, 0],
			times: [0.005, 0.01, 0.01, duty - 0.025, 0.008],
			curve: [2, 2, 1, 0, -4]
		),
		doneAction: 2
	);
	env = env * LFNoise2.kr(80).range(0.85, 1.0);

	freq = period.reciprocal;
	freq2 = (features + 1) / duty;

	modulator = LFSaw.ar(freq, 1, 0.5, 0.5);
	mod2 = (modulator * freq2 / freq * pi).cos.squared;

	// Fundamental + 2nd harmonic (strong at -0 dB and -40 dB)
	mod3 = modulator * (cfreqVar / freq);
	mod3 = (mod3 * 2pi).cos +
	       ((mod3 * 2 * 2pi).cos * 0.15) +
	       ((mod3 * 3 * 2pi).cos * 0.05);

	mod4 = Wrap.ar(modulator.min(freq * duty) * (freq * duty).reciprocal);
	mod4 = ((mod4 - 0.5).squared * (-4) + 1);

	sig = mod4 * (mod2 * mod3);

	// Scraping noise
	noise = BPF.ar(PinkNoise.ar(noiseAmt), cfreqVar, 0.8) * mod4 * mod2;
	sig = sig + noise;

	sig = LeakDC.ar(sig);
	sig = sig * env * amp;

	Out.ar(out, Pan2.ar(sig, pan));
}).add;
)

// ============================================================
// 2. SNOWY TREE CRICKET — O. fultoni
//    Dominant: 2900 Hz (nearly pure sine!)
//    Weak harmonic at 5800 Hz (-38 dB)
//    Rhythm: ultra-regular chirps, ~0.35s apart, ~8 pulses per chirp at 52/s
//    "If moonlight could be heard, it would sound like that"
//    Temperature dependent: freq drops with cold
// ============================================================
(
SynthDef(\treeCricket, {
	arg cfreq=2900, chirpDur=0.25, pulseRate=52,
	    amp=0.1, pan=0, out=0,
	    freqDrift=15; // very stable pitch

	var sig, pulseEnv, chirpEnv, cfreqVar;

	cfreqVar = cfreq + LFNoise1.kr(0.3).range(freqDrift.neg, freqDrift);

	// Almost pure sine — the defining characteristic
	sig = SinOsc.ar(cfreqVar);
	// Tiny 2nd harmonic
	sig = sig + (SinOsc.ar(cfreqVar * 2) * 0.012);

	// Pulse structure within chirp: grouped as 2,3,3 or 2,3
	// Model as amplitude tremolo at pulse rate
	pulseEnv = SinOsc.ar(pulseRate).max(0);
	// Soften the pulsing — tree crickets have smooth pulses
	pulseEnv = pulseEnv.sqrt;

	// Overall chirp envelope — gentle, symmetrical
	chirpEnv = EnvGen.kr(
		Env.new(
			levels: [0, 0.5, 1, 1, 0.5, 0],
			times: [0.02, 0.03, chirpDur - 0.08, 0.02, 0.01],
			curve: [2, 1, 0, -1, -3]
		),
		doneAction: 2
	);
	// Gentle amplitude variation
	chirpEnv = chirpEnv * LFNoise2.kr(15).range(0.92, 1.0);

	sig = sig * pulseEnv * chirpEnv * amp;

	Out.ar(out, Pan2.ar(sig, pan));
}).add;
)

// ============================================================
// 3. COMMON TRUE KATYDID — P. camellifolia
//    Broadband: peaks at 3300, 3600, 4800, 5200, 5900 Hz
//    (all within ~15 dB — very noisy/raspy)
//    Rhythm: "ka-ty-DID" = 2-3 fast rasps (~0.04-0.12s) then ~0.85s gap
//    Each rasp is a burst of wing scrapes
// ============================================================
(
SynthDef(\katydid, {
	arg cfreq=4500, raspDur=0.08, pulseRate=120,
	    amp=0.15, pan=0, out=0,
	    bw=0.6; // wide bandwidth — broadband character

	var sig, env, rasp, formants;

	// Broadband source: filtered noise is the core
	// Multiple resonant peaks like the real spectrum
	formants = [3300, 3600, 4800, 5200, 5900];

	sig = formants.collect({ |f|
		var n = BPF.ar(WhiteNoise.ar(1), f + LFNoise1.kr(0.5).range(-100, 100), 0.15);
		n
	}).sum;

	// Add some tonal component for body
	sig = sig + (Pulse.ar(cfreq, 0.3, 0.15));

	// Rapid internal tooth-strike pulsing
	rasp = EnvGen.ar(Env.perc(0.001, 0.006), Impulse.ar(pulseRate));
	sig = sig * rasp;

	// Overall rasp envelope
	env = EnvGen.kr(
		Env.new(
			levels: [0, 0.6, 1, 0.8, 0],
			times: [0.003, 0.01, raspDur - 0.02, 0.007],
			curve: [4, 1, -1, -6]
		),
		doneAction: 2
	);
	env = env * LFNoise2.kr(50).range(0.8, 1.0);

	sig = sig * env * amp;
	sig = LeakDC.ar(sig);

	Out.ar(out, Pan2.ar(sig, pan));
}).add;
)

// ============================================================
// 4. ROBUST CONEHEAD — N. robustus
//    Dominant: 6700-7000 Hz (tight cluster)
//    Continuous buzz — no gaps, sustained drone
//    Very loud, whining at distance, intense hum up close
//    Uses gate for start/stop
// ============================================================
(
SynthDef(\conehead, {
	arg cfreq=6850, amp=0.12, pan=0, out=0,
	    gate=1, amRate=140, amDepth=0.6,
	    atk=0.3, rel=0.8;

	var sig, env, am, cfreqVar;

	cfreqVar = cfreq + LFNoise1.kr(0.8).range(-80, 80);

	// Buzzy source: pulse wave + noise
	sig = Pulse.ar(cfreqVar, 0.4, 0.7);
	sig = sig + (WhiteNoise.ar(0.25));

	// Tight resonant filter around dominant freq
	sig = BPF.ar(sig, cfreqVar, 0.12);
	// Secondary peak
	sig = sig + BPF.ar(sig, cfreqVar * 1.045, 0.15, 0.5); // 7000/6700 ≈ 1.045

	// Amplitude modulation — the "buzz" texture
	am = SinOsc.kr(amRate + LFNoise1.kr(2).range(-10, 10));
	am = am.range(1 - amDepth, 1);
	sig = sig * am;

	// Gate envelope
	env = EnvGen.kr(
		Env.adsr(atk, 0.1, 0.9, rel),
		gate, doneAction: 2
	);

	// Slow amplitude wander
	sig = sig * LFNoise2.kr(0.5).range(0.85, 1.0);

	sig = LeakDC.ar(sig);
	sig = sig * env * amp;

	Out.ar(out, Pan2.ar(sig, pan));
}).add;
)

// ============================================================
// 5. GROUND CRICKET — Nemobiinae
//    Dominant: ~8000 Hz (recording was at 1/4 speed → 2000 Hz × 4)
//    Very pure, high-pitched, soft
//    Nearly continuous trill, regular ~0.3s intervals at real speed
// ============================================================
(
SynthDef(\groundCricket, {
	arg cfreq=8000, trillRate=60, amp=0.05, pan=0, out=0,
	    gate=1, freqDrift=50;

	var sig, env, trill, cfreqVar;

	cfreqVar = cfreq + LFNoise1.kr(0.4).range(freqDrift.neg, freqDrift);

	// Very pure — almost sinusoidal
	sig = SinOsc.ar(cfreqVar);
	sig = sig + (SinOsc.ar(cfreqVar * 2) * 0.05); // faint harmonic

	// Rapid trill — continuous pulsation
	trill = SinOsc.ar(trillRate).max(0);
	trill = trill * LFNoise2.kr(20).range(0.9, 1.0);

	sig = sig * trill;

	// Soft overall envelope
	env = EnvGen.kr(
		Env.asr(0.5, 1, 0.5),
		gate, doneAction: 2
	);
	sig = sig * LFNoise2.kr(0.3).range(0.8, 1.0);

	sig = LeakDC.ar(sig);
	sig = sig * env * amp;

	Out.ar(out, Pan2.ar(sig, pan));
}).add;
)

// ============================================================
// REVERB
// ============================================================
(
SynthDef(\fieldReverb, {
	arg in=0, out=0, mix=0.3, room=0.7, damp=0.5;
	var sig = In.ar(in, 2);
	sig = FreeVerb2.ar(sig[0], sig[1], mix, room, damp);
	Out.ar(out, sig);
}).add;
)

// ============================================================
// NIGHTSCAPE — all species together
// ============================================================

// --- Setup ---
(
~reverbBus = Bus.audio(s, 2);
~reverb = Synth.tail(s, \fieldReverb, [
	\in, ~reverbBus, \out, 0,
	\mix, 0.3, \room, 0.7, \damp, 0.45
]);
)

// --- Helper ---
(
~chirpSeq = { |chirpDurs, restLo, restHi|
	Pseq([
		Pseq(chirpDurs),
		Pwhite(restLo, restHi, 1).collect(Rest(_))
	], inf);
};
)

// --- Field crickets (2 near, 5 far) ---
(
~fieldNear1 = Pbind(
	\instrument, \fieldCricket,
	\out, ~reverbBus,
	// Paired chirps like the recording: 2 pulses close, then gap
	\dur, ~chirpSeq.([0.04, 0.56, 0.04, 0.56], 2.0, 5.0),
	\cfreq, 4600,
	\amp, Pwhite(0.08, 0.12, inf),
	\pan, Pwhite(-0.65, -0.55, inf),
);

~fieldNear2 = Pbind(
	\instrument, \fieldCricket,
	\out, ~reverbBus,
	\dur, ~chirpSeq.([0.04, 0.62, 0.04, 0.58], 3.0, 7.0),
	\cfreq, 4700,
	\amp, Pwhite(0.06, 0.10, inf),
	\pan, Pwhite(0.3, 0.4, inf),
);

~fieldFar = Array.fill(5, {
	Pbind(
		\instrument, \fieldCricket,
		\out, ~reverbBus,
		\dur, ~chirpSeq.(
			[rrand(0.03, 0.05), rrand(0.5, 0.7), rrand(0.03, 0.05), rrand(0.5, 0.7)],
			rrand(3.0, 6.0), rrand(7.0, 14.0)
		),
		\cfreq, rrand(4400, 4900),
		\amp, Pwhite(0.02, 0.04, inf),
		\pan, rrand(-1.0, 1.0),
		\noiseAmt, 0.03,
	);
});
)

// --- Tree crickets (2 — the melodic backdrop) ---
(
~tree1 = Pbind(
	\instrument, \treeCricket,
	\out, ~reverbBus,
	// Ultra-regular: ~0.35s chirps with brief gaps
	\dur, Pwhite(0.34, 0.36, inf),
	\chirpDur, Pwhite(0.22, 0.26, inf),
	\cfreq, 2900,
	\amp, Pwhite(0.06, 0.09, inf),
	\pan, Pwhite(-0.8, -0.7, inf),
);

~tree2 = Pbind(
	\instrument, \treeCricket,
	\out, ~reverbBus,
	\dur, Pwhite(0.33, 0.37, inf),
	\chirpDur, Pwhite(0.20, 0.24, inf),
	\cfreq, 2850, // slightly detuned — different individual
	\amp, Pwhite(0.04, 0.07, inf),
	\pan, Pwhite(0.6, 0.75, inf),
);
)

// --- Katydids (2 — sparse, dramatic) ---
(
~katydid1 = Pbind(
	\instrument, \katydid,
	\out, ~reverbBus,
	// "ka-ty-DID": 3 fast rasps, long gap
	\dur, ~chirpSeq.([0.04, 0.08, 0.12], 2.5, 5.0),
	\raspDur, Pseq([0.06, 0.07, 0.10], inf), // last rasp is longest
	\amp, Pseq([0.08, 0.10, 0.15], inf),     // last rasp is loudest
	\pan, Pwhite(-0.4, -0.2, inf),
);

~katydid2 = Pbind(
	\instrument, \katydid,
	\out, ~reverbBus,
	// Antiphonal — responds after katydid1
	\dur, ~chirpSeq.([Rest(1.2), 0.05, 0.09, 0.13], 3.0, 6.0),
	\raspDur, Pseq([0.07, 0.08, 0.11], inf),
	\amp, Pseq([0.06, 0.08, 0.12], inf),
	\pan, Pwhite(0.5, 0.7, inf),
);
)

// --- Conehead (1 — distant continuous drone) ---
(
~conehead = Pbind(
	\instrument, \conehead,
	\out, ~reverbBus,
	// Long sustained buzzes with occasional pauses
	\dur, Pwhite(8.0, 20.0, inf),
	\legato, Pwhite(0.85, 0.95, inf),
	\cfreq, 6850,
	\amp, Pwhite(0.03, 0.05, inf), // distant
	\pan, Pwhite(0.8, 0.95, inf),  // far right
	\amRate, Pwhite(130, 150, inf),
);
)

// --- Ground crickets (2 — soft high trill, continuous) ---
(
~ground1 = Pbind(
	\instrument, \groundCricket,
	\out, ~reverbBus,
	\dur, Pwhite(4.0, 10.0, inf),
	\legato, Pwhite(0.9, 1.0, inf),
	\cfreq, 7800,
	\amp, Pwhite(0.02, 0.04, inf),
	\pan, Pwhite(-0.3, 0.0, inf),
);

~ground2 = Pbind(
	\instrument, \groundCricket,
	\out, ~reverbBus,
	\dur, Pwhite(5.0, 12.0, inf),
	\legato, Pwhite(0.85, 0.95, inf),
	\cfreq, 8200,
	\amp, Pwhite(0.015, 0.03, inf),
	\pan, Pwhite(0.1, 0.4, inf),
);
)

// ============================================================
// PLAY THE NIGHTSCAPE
// ============================================================
(
~nightscape = Ppar([
	~fieldNear1, ~fieldNear2,
] ++ ~fieldFar ++ [
	~tree1, ~tree2,
	~katydid1, ~katydid2,
	~conehead,
	~ground1, ~ground2,
]).play;
)

// ============================================================
// STOP
// ============================================================
// ~nightscape.stop; ~reverb.free;
