//-----------------------------------------------------------------------------
// Smuck attempt at granular_visual.ck
//-----------------------------------------------------------------------------
@import "smuck";
public class eZvisual extends ezInstrument
{
    setVoices(50);
    // MIDI callback function
    // Import required graphics modules
    adc => blackhole;
    Gain master => dac;
    0.7 => master.gain;

    // Create global scene and camera
    GG.scene() @=> GScene @ scene;
    GCamera cam;
    cam --> scene; // Connect camera to scene first
    scene.camera(cam);

    // Set camera position and background for better visibility
    cam.posWorld(@(0,0,8));
    scene.backgroundColor(@(0, 0, 0)); // Pure black background

    // Set the camera's field of view to see more of the scene
    cam.fov(70); // Wider field of view

    // Camera adjustments for better visualization
    // Position camera further back and higher to look down at the scene
    cam.posWorld(@(0,0,10));
    // Looking down is automatic with this positioning

    //------------ AUDIO PARAMETERS -------------
    // Global parameters
    "xboxController/sample.aif" => string SAMPLE_PATH; // Default sample, can be overridden by command line
    50::ms => dur GRAIN_LENGTH;           // Base grain length
    0.5 => global float GRAIN_DENSITY;           // Grains per second (relative to grain length)
    0.7 => global float GRAIN_OVERLAP;           // Overlap between grains (0-1)
    1.0 => global float FIRING_RATE;             // Rate at which grains are fired (1.0 = normal, controlled by mod wheel)
    0.1 => global float POSITION_RANDOM;         // Random position variation (0-1)
    0.0 => global float PITCH_RANDOM;            // Random pitch variation in semitones (set to 0 for perfect tuning)
    0.1 => global float POSITION_OFFSET;           // Starting position in sample (0-1)
    0.2 => global float ATTACK_TIME;             // Attack time as fraction of grain length
    0.2 => global float RELEASE_TIME;            // Release time as fraction of grain length
    200::ms => dur NOTE_RELEASE_TIME;     // Release time for notes when key is released
    0.01 => global float RELEASE_DENSITY_FACTOR;  // How much to reduce density during release (lower = more sparse)
    global float GRAIN_LEN;                 // Separate grain length global in float terms

    // Global grain timing variables
    dur GRAIN_SPACING;          // Current grain spacing, will be updated when parameters change
    global Event updateEvent;                    // Event to signal when parameters change
    global Event grainFired;                     // Event to trigger grain visualization

    // For connecting reverb
    NRev reverb => master;
    0.5 => reverb.mix;

    // For active note tracking
    128 => int MIDI_NOTE_RANGE;
    int activeNotes[MIDI_NOTE_RANGE]; // Store active notes

    //------------ VISUALIZATION FUNCTIONS -------------

    // Global grain array to ensure we can track and remove all grains
    GCircle grains[0];
    int maxGrains;
    50 => maxGrains; // Lower maximum for better performance

    
    // Simple helper function to remove a grain after a set time
    fun void removeGrainAfterDelay(GCircle grain, int index, dur delay) {
        // Let it exist for the specified time
        delay => now;
        
        // Check if the grain still exists in our array
        if (index < grains.size()) {
            // Then remove it from the scene
            grains[index] --< scene;
            
            // Remove it from our tracking array
            grains.popOut(index);
        }
        me.exit();
    }

    // Function to periodically check and clean up any remaining grains
    fun void cleanupGrains() {
        while (true) {
            if (grains.size() > 1) {
                // Remove the oldest grain
                grains[0] --< scene;
                grains.popOut(0);
            }
            100::ms => now;
        }
    }

    // Simple function to visualize a grain with guaranteed cleanup
    fun void visualizeGrain(float pitch, float velocity, float position, dur grainLength) {
        //Limit total number of grains to prevent performance issues
        if (grains.size() >= maxGrains) {
            // If we're at the limit, remove the oldest grain first
            if (grains.size() > 0) {
                grains[0] --< scene;
                grains.popOut(0);
            }
        }
        
        // Randomize X position across the entire screen width but centered
        Math.random2f(-8.0, 8.0) => float posX;
        
        // Map pitch to Y coordinate (higher pitch = higher position)
        // Using logarithmic mapping to handle exponential nature of pitch
        // This maps pitch 0.5 -> bottom, 1.0 -> middle, 2.0 -> top
        Math.log2(pitch) * 4 => float posY;

        
        // Size based on velocity with limited influence from grain length to improve performance
        0.01 + (velocity * 0.05) * (GRAIN_LEN / 100.0) => float size;
        // Cap the size to prevent performance issues with very large grains
        if (size > 5.0) 5.0 => size;
        
        // Create vibrant, randomized colors for a splatter paint effect
        Math.random2f(0.7, 1.0) => float red;
        Math.random2f(0.7, 1.0) => float green;
        Math.random2f(0.7, 1.0) => float blue;
        
        // Randomize which colors are brighter to create more variety
        // We'll dim one or two colors to make others pop more
        if (Math.random2(0, 2) == 0) {
            red * 0.3 => red; // Dim red sometimes
        } else if (Math.random2(0, 2) == 1) {
            green * 0.3 => green; // Dim green sometimes
        } else {
            blue * 0.3 => blue; // Dim blue sometimes
        }
        
        // Create the grain circle
        GCircle grain;
        grain.color(@(red, green, blue));
        grain.sca(size * 4.0); // Quadruple the size for better visibility
        grain.pos(@(posX, posY, 0));
        
        // Add to scene
        grain --> scene;
        
        // Add to our tracking array
        grains << grain;
        
        // Get the index of the grain we just added
        grains.size() - 1 => int grainIndex;
        
        // Use a shorter lifetime for better performance
        spork ~ removeGrainAfterDelay(grain, grainIndex, 60::ms);
    }

    //------------ AUDIO FUNCTIONS -------------

    // Update grain spacing based on density and overlap
    fun void updateGrainSpacing() {
        while (true) {
            // Using synchronized grain timing for better tuning
            // The key to good tuning is having grains synchronized across voices
            (GRAIN_LENGTH * (1.0 - GRAIN_OVERLAP)) / (GRAIN_DENSITY + 0.1) => GRAIN_SPACING;
            
            // Ensure spacing is a multiple of a small time unit (important for tuning)
            // This synchronization helps maintain harmonic relationships between notes
            5::ms => dur syncUnit;
            (GRAIN_SPACING / syncUnit) $ int * syncUnit => GRAIN_SPACING;
            
            // Make sure spacing isn't too extreme which can cause tuning issues
            if (GRAIN_SPACING < 10::ms) 10::ms => GRAIN_SPACING;
            
            updateEvent.broadcast();
            100::ms => now;
        }
    }

    // Wait for parameter updates
    fun void waitForUpdate(Event localEvent) {
        // Wait for either the update event or the local event
        updateEvent => now;
        localEvent => now;
    }

    // Generate a single grain - optimized version
    fun void generateGrain(float basePitch, float velocity, Gain voiceGain) {
        // Create grain oscillator and envelope
        SndBuf grain => PitShift pitch => Envelope env => Gain grainGain => voiceGain;
        // Set PitShift parameters for better tuning
        1.0 => pitch.mix;  // Full wet signal
        
        // Set the grain's individual gain based on velocity (0.0-1.0)
        velocity * 0.5 => grainGain.gain;
        
        // Set pitch shifter
        basePitch => pitch.shift;
        float actualPitch;
        basePitch => actualPitch;
        
        // Configure pitch with perfect tuning method
        // Initialize to exact pitch first
        basePitch => actualPitch => pitch.shift;
        
        // Apply randomization only if enabled
        if (PITCH_RANDOM > 0) {
            // Calculate pitch variation in a way that maintains harmonic relationships
            float pitchVariation;
            
            // For small random values, use very subtle variations that sound harmonic
            if (PITCH_RANDOM < 0.05) {
                // Use only harmonic-friendly variations (smaller multiples work better for chords)
                [1.0, 1.001, 0.999, 1.002, 0.998] @=> float harmonicRatios[];
                harmonicRatios[Math.random2(0, harmonicRatios.size()-1)] => pitchVariation;
            } else {
                // For larger random values, use standard calculation but more controlled
                Math.pow(2.0, Math.random2f(-PITCH_RANDOM, PITCH_RANDOM) / 12.0) => pitchVariation;
            }
            
            // Apply the variation to pitch
            basePitch * pitchVariation => actualPitch => pitch.shift;
        }
        
        // Copy the sample
        SAMPLE_PATH => grain.read;
        
        // Calculate position in sample
        POSITION_OFFSET => float position;
        
        // Add random position variation if enabled
        if (POSITION_RANDOM > 0) {
            position + Math.random2f(-POSITION_RANDOM, POSITION_RANDOM) => position;
            // Clamp to valid range
            if (position < 0) 0 => position;
            if (position > 1) 1 => position;
        }
        
        // Set grain position
        (position * grain.samples()) $ int => grain.pos;
        
        // Visualize this grain - this is the direct connection between audio and visuals!
        spork ~ visualizeGrain(actualPitch, velocity, position, GRAIN_LENGTH);
        
        // Set envelope times
        (GRAIN_LENGTH * ATTACK_TIME) => env.duration;
        1.0 => env.target;
        env.duration() => now;
        
        // Hold
        (GRAIN_LENGTH * (1.0 - ATTACK_TIME - RELEASE_TIME)) => now;
        
        // Release
        (GRAIN_LENGTH * RELEASE_TIME) => env.duration;
        0.0 => env.target;
        env.duration() => now;
        
        // Clean up
        grain =< pitch =< env =< grainGain =< voiceGain;
    }

    // Play a MIDI note
    fun void noteOn(ezNote Enote, float velocity) {
        // Check if note is in range
        Std.ftoi(Enote.pitch()) => int note; 
        if (note < 0 || note >= MIDI_NOTE_RANGE) {
            return;
        }
        
        // Note is already active, do nothing
        if (activeNotes[note]) {
            return;
        }
        
        // Mark note as active
        1 => activeNotes[note];
        
        // Calculate pitch ratio (1.0 = normal, 0.5 = octave down, 2.0 = octave up)
        // MIDI note 60 = middle C = normal pitch
        Math.pow(2.0, (note - 60) / 12.0) => float basePitch;
        
        // Create a gain for this voice that will persist
        Gain voiceGain => reverb;
        
        // Log info
        <<< "Note On:", note, "Velocity:", velocity, "Pitch Ratio:", basePitch >>>;
        
        // Create grains until note is released
        while (activeNotes[note]) {
            // Spawn a grain with normal velocity
            spork ~ generateGrain(basePitch, velocity, voiceGain);
            
            // Wait for next grain or parameter update
            Event localEvent;
            spork ~ waitForUpdate(localEvent);
            GRAIN_SPACING => now;
            localEvent.signal(); // Stop the waiting shred
        }
        
        // Note was released, do a release fade
        1.0 => float releaseFactor;
        NOTE_RELEASE_TIME => dur releaseTime;
        now => time releaseStart;
        
        // Create a few more grains but with decreasing velocity
        while (now < releaseStart + releaseTime) {
            // Calculate release progress (0.0 to 1.0)
            (now - releaseStart) / releaseTime => float releaseProgress;
            
            // Calculate release velocity, fading out
            velocity * (1.0 - releaseProgress) => float releasedVelocity;
            
            // Spawn a grain with reduced velocity
            spork ~ generateGrain(basePitch, releasedVelocity, voiceGain);
            
            // Wait for next grain with adjusted spacing
            Event localEvent;
            spork ~ waitForUpdate(localEvent);
            releaseGrainSpacing() => now;
            localEvent.signal();
        }
        
        // Clean up
        voiceGain =< master;
    }

    
    // Release a MIDI note
    fun void noteOff(ezNote Enote) {
        Std.ftoi(Enote.pitch()) => int note; 
        // Check if note is active
        if (note >= 0 && note < MIDI_NOTE_RANGE && activeNotes[note]) {
            // Mark as inactive
            0 => activeNotes[note];
            <<< "Note Off:", note >>>;
        }
    }

    // Calculate grain spacing during release phase
    fun dur releaseGrainSpacing() {
        return GRAIN_SPACING * (1.0 / RELEASE_DENSITY_FACTOR);
    }

    fun void midiCallback() {
    
        // Set up MIDI device
        MidiIn min;
        MidiMsg msg;
        
        // Try to open the MIDI port
        if (min.open("MPK225 Port A")) {
            <<< "MIDI device '", "MPK225 Port A", "' opened" >>>;
            // Initialize grain spacing
            spork ~ updateGrainSpacing();

        } 
        if (min.open("Logic Pro Virtual Out")) {
            <<< "Logic opened" >>>;
        }
        else {
            <<< "Could not open MPK or Logic , trying default..." >>>;
            if (!min.open(0)) {
                <<< "No MIDI devices available!" >>>;
                return;
            }
        }
        // Main message loop
        while (true) {
            // Wait for a message
            min => now;
            
            // Process all queued messages
            while (min.recv(msg)) {
                // Note On message (0x90)
                // if ((msg.data1 & 0xF0) == 0x90 && msg.data3 > 0) {
                //     msg.data2 => int note;
                //     msg.data3 / 127.0 => float velocity;
                    
                    
                //     activeNotes.size() => int voice; 
                //     // Create visualization for note start
                //     spork ~ noteOn(note, voice, velocity);
                // }
                // // Note Off message (0x80 or 0x90 with velocity 0)
                // else if (((msg.data1 & 0xF0) == 0x80) || 
                //         ((msg.data1 & 0xF0) == 0x90 && msg.data3 == 0)) {
                //     msg.data2 => int note;
                    
                //     // Debug
                //     <<< "Visualizing Note Off:", note >>>;
                    
                //     // Create visualization for note end
                //     noteOff(note);
                // }
                // CC message (0xB0) - for firing rate and other parameters
                if ((msg.data1 & 0xF0) == 0xB0) {
                    // CC number
                    msg.data2 => int cc;
                    // CC value
                    msg.data3 / 127.0 => float normalized;
                    
                    // Process different CC controls
                    if (cc == 1) {
                        // CC 1: Mod wheel controls firing rate
                        normalized * 2+ 0.1  => FIRING_RATE; // 0.5 to 1.5 range
                        <<< "Firing Rate:", FIRING_RATE >>>;
                    }
                    else if (cc == 22) {
                        // CC 22: Grain density
                        normalized * 0.9 + 0.001 => GRAIN_DENSITY;
                        <<< "Grain Density:", GRAIN_DENSITY >>>;
                    }
                    else if (cc == 23) {
                        // CC 23: Grain length
                        (normalized * 490 + 10) => GRAIN_LEN; 
                        GRAIN_LEN::ms => GRAIN_LENGTH;
                        <<< "Grain Length:", GRAIN_LENGTH/ms, "ms" >>>;
                    }
                    else if (cc == 24) {
                        // CC 24: Position offset
                        normalized => POSITION_OFFSET;
                        <<< "Position:", POSITION_OFFSET >>>;
                    }
                    else if (cc == 25) {
                        // CC 25: Position randomness
                        normalized * 0.5 => POSITION_RANDOM;
                        <<< "Position Random:", POSITION_RANDOM >>>;
                    }
                    else if (cc == 26) {
                        // CC 26: Pitch randomness (0-2 semitones - back to original range)
                        normalized * 2.0 => PITCH_RANDOM;
                        <<< "Pitch Random:", PITCH_RANDOM, "semitones" >>>;
                    }
                    else if (cc == 27) {
                        // CC 27: Reverb mix
                        normalized * 0.8 => reverb.mix;
                        <<< "Reverb:", reverb.mix >>>;
                    }
                    else if (cc == 28) {
                        // CC 28: Grain overlap (adjusted range for better tuning)
                        // Scale from 0.2 to 0.9 for better tuning stability
                        normalized * 0.7 + 0.2 => GRAIN_OVERLAP;
                        <<< "Grain Overlap:", GRAIN_OVERLAP >>>;
                    }
                    else if (cc == 29) {
                        // CC 29: Master gain
                        normalized * 1.5 => master.gain;
                        <<< "Master Gain:", master.gain >>>;
                    }
                }
            }
        }
    }

    // For debugging - show instructions
    fun void showInstructions() {
        <<< "MIDI Granular Synth with Visualizations" >>>;
        <<< "Play notes on your MIDI controller" >>>;
        <<< "CC1 (Mod Wheel): Firing Rate" >>>;
        <<< "CC22: Grain Density, CC23: Grain Length" >>>;
        <<< "CC24: Position, CC25: Position Random, CC26: Pitch Random, CC27: Reverb" >>>;
        <<< "CC28: Grain Overlap, CC29: Master Gain" >>>;
    }
    
    // Start the MIDI callback
    spork ~ midiCallback();

    // Show instructions
    showInstructions();

    // Start the cleanup process
    spork ~ cleanupGrains();    

    fun void frames () {
         // Main loop 
        while (true) {
            GG.nextFrame() => now;
            20::ms => now; // Slightly longer sleep for better performance
        }
    }
    spork ~ frames();

}