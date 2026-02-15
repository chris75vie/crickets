# crickets
Sound Design with musical intent of animals, insects especially crickets using SuperCollider

## About

Species-accurate synthesis of cricket and insect sounds in SuperCollider, driven by analysis of real recordings from the [SINA database](https://orthsoc.org/sina/). Each SynthDef is parameterised from spectral analysis — dominant frequencies, harmonic structure, onset timing, and inter-chirp intervals — rather than generic approximations.

## Species

| SynthDef | Species | Dominant Freq | Character |
|---|---|---|---|
| `\fieldCricket` | *Gryllus pennsylvanicus* | 4600 Hz | Paired chirps, classic cricket |
| `\treeCricket` | *Oecanthus fultoni* | 2900 Hz | Pure tone, ultra-regular rhythm |
| `\katydid` | *Pterophylla camellifolia* | 3800 Hz | Raucous bursts, broadband |
| `\conehead` | *Neoconocephalus robustus* | 7000 Hz | Loudest NA insect, dense buzz |
| `\groundCricket` | *Allonemobius allardi* | 7300 Hz | Continuous high-pitched trill |

## Research Context

### Key references

- **Andy Farnell** — *Designing Sound* (2010). Generic SC insect synthesis recipes; the foundation this project builds on.
- **Alexander Liebermann** — Juilliard composer who transcribes animal sounds (including cicada rhythms) into precise musical notation. [alexanderliebermann.com](https://alexanderliebermann.com)
- **David Dunn** — Composer and bioacoustician. Works like *The Sound of Light in Trees* (2006) explore insect sounds artistically. [davidddunn.com](https://www.davidddunn.com)
- **Dr. Thorin Jonsson** (Uni Graz) — FEM modelling of wing resonance and tooth-strike superposition in cricket stridulation.
- **SINA** — [Singing Insects of North America](https://orthsoc.org/sina/) by Thomas J. Walker. Recording database used for parameter derivation.

### What makes this different

Most existing SuperCollider insect code is still based on Farnell's generic recipes from 2010. This project combines:

- **Real recordings** as the ground truth (SINA database)
- **Spectral analysis** to extract species-specific parameters
- **Scientific literature** on stridulation mechanics
- **Musical intent** — the goal is a natural, convincing sound, not a physics simulation

### Community

- [scsynth.org](https://scsynth.org) — SuperCollider forum
- [SC Discord](https://discord.gg/TbBtCXxp5p) — Real-time chat
- [sccode.org](https://sccode.org) — Code sharing

## Usage

1. Download reference recordings (see [samples.md](samples.md))
2. Boot SuperCollider: `s.boot`
3. Evaluate `Species.scd` — loads all SynthDefs and starts the nightscape ensemble

## Licence

TBD
