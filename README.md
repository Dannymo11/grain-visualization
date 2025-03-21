# MIDI Granular Synthesizer with Pitch Shifting

This project contains a granular synthesizer that responds to MIDI input, built with ChucK. The latest implementation uses pitch shifting for more accurate note reproduction.

## Files

- `experiment.ck` - Original granular synth with Xbox controller input
- `midi.ck` - First attempt at MIDI-controlled granular synth
- `granular_midi.ck` - New improved MIDI granular synth with pitch shifting

## Running the Granular MIDI Synth

To run the improved MIDI granular synth with pitch shifting:

```
chuck granular_midi.ck
```

You can specify a different sample file:

```
chuck granular_midi.ck:path/to/sample.wav
```

## How It Works

The granular MIDI synthesizer uses a combination of techniques:

1. **Granular Synthesis**: Plays small "grains" of sound from a sample
2. **Pitch Shifting**: Uses ChucK's PitShift UGen to accurately shift the pitch of grains
3. **Envelope Shaping**: Applies attack and release envelopes to each grain
4. **Polyphony**: Supports playing multiple notes simultaneously

## MIDI Controls

- **MIDI Notes**: Each note triggers grains at the corresponding pitch
- **Note Velocity**: Controls the volume of the grains
- **CC1 (Mod Wheel)**: Controls firing rate (0.1 to 4.0) - how fast grains are generated
- **CC22**: Controls grain density
- **CC23**: Controls grain length (10ms to 500ms)
- **CC24**: Controls position offset in the sample (0 to 1)
- **CC25**: Controls position randomness (0 to 0.5)
- **CC26**: Controls pitch randomness (0 to 2 semitones)
- **CC27**: Controls reverb mix (0 to 0.5)
- **CC28**: Controls grain overlap (0.1 to 1.0)
- **CC29**: Controls master gain (0 to 1.2)

## Parameters You Can Modify

The following global parameters can be adjusted in the code:

```chuck
"special:dope" => string SAMPLE_PATH;  // Default sample
50::ms => dur GRAIN_LENGTH;            // Base grain length
0.5 => float GRAIN_DENSITY;            // Grains per second
0.7 => float GRAIN_OVERLAP;            // Overlap between grains
0.1 => float POSITION_RANDOM;          // Random position variation
0.1 => float PITCH_RANDOM;             // Random pitch variation
0 => float POSITION_OFFSET;            // Starting position in sample
0.2 => float ATTACK_TIME;              // Attack time fraction
0.2 => float RELEASE_TIME;             // Release time fraction
```

## Troubleshooting

If no sound is playing:

1. Make sure your MIDI device is connected and recognized
2. Check that the sample file exists or use a built-in ChucK sample like "special:dope"
3. Verify that you're playing notes in the appropriate range
4. Ensure your audio output is properly configured

## Extending the Synth

You can modify the code to:
- Add more MIDI CC controls
- Implement different grain selection algorithms
- Add more effects processing
- Create presets for different sounds
- Add sample recording capabilities

## Credits

Created by Danny Mottesi
