@import "smuck";
@import "eZvisual.ck"; 

ezScore dots;


dots.importMIDI("claredeLune.mid");
<<< 'Midi Imported' >>>;

eZvisual synth4 => dac;

1::second => now;

// 3. Play the score
ezScorePlayer player(dots);
player.bpm(50);
<<<player.bpm()>>>;
player.setInstrument([synth4]);
10::second => now;

player.play();


15::second => now;


