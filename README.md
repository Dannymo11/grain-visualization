# MIDI Granular Synthesizer with Visual Representation

This project features a granular synthesizer with real-time visual representation of each sound grain, built with ChucK and the ChugL graphical framework. The synthesizer responds to MIDI input and provides an interactive audiovisual experience where every grain of sound is visualized as a colorful circle.

Every grain that is generated is visualized in real-time. Each vertical line represents a note, and the size of each circle represents grain-size and velocity. The visual component adds a new dimension to the understanding and enjoyment of granular synthesis.

## Features

- **Granular Synthesis**: Plays small "grains" of sound from audio samples
- **Real-time Visualization**: Every grain appears as a vibrant circle in a 3D space
- **MIDI Control**: Full MIDI compatibility for notes and controllers
- **Pitch Shifting**: Uses ChucK's PitShift UGen for accurate pitch shifting
- **Polyphonic Playback**: Supports playing multiple notes simultaneously
- **Integrated Audio-Visual Experience**: Sound and visuals are tightly coupled

## Running granular_visual.ck

To run the audiovisual granular synthesizer:

```bash
chuck granular_visual.ck
```

The program will automatically try to connect to a MIDI device (specifically looking for "MPK225 Port A" or "Logic Pro Virtual Out" first, then falling back to the default MIDI device).

## Required Files

The project includes sample audio files in the xboxController directory:
- `sample.aif` (default sample)
- `c2.aif`
- `organ.aif`

## How It Works

### Audio Generation
The synthesizer generates sound by playing small overlapping "grains" from an audio sample. Each grain:
1. Has its own pitch, determined by the MIDI note being played
2. Is processed through a pitch shifter for accurate tuning
3. Has an envelope applied (attack and release) to avoid clicks
4. Can have randomized parameters (position, pitch) for a more organic sound

### Visual Representation
For each audio grain generated:
1. A colored circle is created in the 3D scene
2. The circle's position represents the pitch (Y-axis) and a randomized X position
3. The circle's size relates to the grain's velocity and length
4. The color is randomly generated for a vibrant, artistic effect
5. Circles fade out as the grain completes, creating a dynamic visual field

## MIDI Controls

- **MIDI Notes**: Each note triggers grains at the corresponding pitch
- **Note Velocity**: Controls the volume of the grains
- **CC1 (Mod Wheel)**: Controls firing rate (0.1 to 4.0) - how fast grains are generated
- **CC22**: Controls grain density
- **CC23**: Controls grain length (10ms to 500ms)
- **CC24**: Controls position offset in the sample (0 to 1)
- **CC25**: Controls position randomness (0 to 0.5)
- **CC26**: Controls pitch randomness (0 to 2 semitones)
- **CC27**: Controls reverb mix (0 to 0.8)
- **CC28**: Controls grain overlap (0.2 to 0.9)
- **CC29**: Controls master gain (0 to 1.5)

## Default Parameters

The following default parameters are used:

```chuck
"xboxController/sample.aif" => string SAMPLE_PATH;  // Default sample
50::ms => dur GRAIN_LENGTH;                // Base grain length
0.5 => float GRAIN_DENSITY;                // Grains per second
0.7 => float GRAIN_OVERLAP;                // Overlap between grains
1.0 => float FIRING_RATE;                  // Rate of grain generation
0.1 => float POSITION_RANDOM;              // Random position variation
0.0 => float PITCH_RANDOM;                 // Random pitch variation
0.1 => float POSITION_OFFSET;              // Starting position in sample
0.2 => float ATTACK_TIME;                  // Attack time fraction
0.2 => float RELEASE_TIME;                 // Release time fraction
```

## Troubleshooting

If you encounter issues:

1. **No Sound**: 
   - Make sure your MIDI device is connected and recognized
   - Verify that the sample files exist in the xboxController directory
   - Check that your audio output is properly configured

2. **No Visuals**:
   - Ensure you have the proper ChucK version with Graphics (GG) support
   - Check that you have a compatible graphics system

3. **Performance Issues**:
   - Reduce the maximum number of grains (maxGrains variable) if visuals are lagging
   - Increase the sleep time in the main loop for better performance

## System Requirements

- ChucK with Graphics (GG) support
- MIDI controller or virtual MIDI input
- Audio output device

## Credits

Created by Danny Mottesi
