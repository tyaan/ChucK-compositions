160 => float bpm;
60/bpm => float beat;
beat*5 => float bar;

SawOsc saw => LPF sawLoPass => dac;
SinOsc sin => dac;
TriOsc tri => ADSR triEnv => dac;
SqrOsc chord[4];
ADSR chordEnv;
HPF chordHiPass;
for(0=>int i;i<chord.cap();i++){
    chord[i] => chordEnv => chordHiPass => dac;
}

//arrays of notes that the saw oscillator loops through
[43, 36, 41, 38, 31] @=> int sawArray1[];
[43, 36, 41, 39, 31] @=> int sawArray2[];
[43, 36, 41, 37, 31] @=> int sawArray3[];
0.3 => saw.gain;
100 => sawLoPass.freq;

//arrays of notes the sin oscillator loops through
[58, 53, 57, 55, 50] @=> int sinArray1[];
[60, 53, 56, 53, 53] @=> int sinArray2[];
0 => sin.gain;

//arrays of notes the tri oscillator loops through
[69, 70, 81, -1] @=> int triArray1[]; // -1 will produce invalid mtof conversion, so will play nothing
[74, 77, 75, -1] @=> int triArray2[];
[77, 72, 77, 84, 77, 72, 77, 82] @=> int triArray3[];
[79, -1, 79, -1] @=> int triArray4[];
0.25 => tri.gain;
triEnv.set(0::ms, 800::ms, 0, 0::ms);

//4 notes assigned to the 4 sqr oscillators in the chord array to produce a chord
[61, 65, 68, 72] @=> int chord1[];
[60, 65, 67, 70] @=> int chord2[];
for(0 => int i; i<chord.cap(); i++){
    Std.mtof(chord1[i]) => chord[i].freq;
    0.0 => chord[i].gain;
}
chordEnv.set(0::ms, 0::ms, 0.08, 1::second); 
1000 => chordHiPass.freq;


//assigning lengths of sections
(2*bar)::second + now => time one;
(2*bar)::second + one => time two;
(2*bar)::second + two => time three;
(2*bar)::second + three => time four;
(4*bar)::second + four => time five;
(4*bar)::second + five => time six;

//saw oscillator alone, increasing LPF frequency
while(now < one){
    for(0=>int i;i<sawArray1.cap();i++){
        Std.mtof(sawArray1[i]) => saw.freq;
        (beat/2)::second => now;
        
        sawLoPass.freq()*1.2 => sawLoPass.freq;
    }
}

//saw oscillator alone, decreasing LPF frequency
while(now < two){
    for(0=>int i;i<sawArray2.cap();i++){
        Std.mtof(sawArray2[i]) => saw.freq;
        (beat/2)::second => now;
        
        sawLoPass.freq()*(1/1.2) => sawLoPass.freq;
    }
}

//introcuce sin, and tri melody, increasing saw LPF frequency
0.2 => sin.gain;
0 => int count;
while(now < three){
    Std.mtof(triArray1[count]) => tri.freq;
    triEnv.keyOn();
    
    for(0=>int i;i<sawArray1.cap();i++){
        Std.mtof(sawArray1[i]) => saw.freq;
        Std.mtof(sinArray1[i]) => sin.freq;
        (beat/2)::second => now;
        
        sawLoPass.freq()*1.2 => sawLoPass.freq;
    }
    
    triEnv.keyOff();
    count++;
}

//decreasing saw LPF frequency
0 => count;
while(now < four){
    Std.mtof(triArray2[count]) => tri.freq;
    triEnv.keyOn();
    
    for(0=>int i;i<sawArray2.cap();i++){
        Std.mtof(sawArray2[i]) => saw.freq;
        Std.mtof(sinArray1[i]) => sin.freq;
        (beat/2)::second => now;
        
        sawLoPass.freq()*(1/1.2) => sawLoPass.freq;
    }
    
    triEnv.keyOff();
    count++;
}

//Slowly increase gain on chord 1. Wanted to just use an attack envelope, 
//but seems to increase to gain of 1 at the peak regardless of the sustain level, 
//making it too loud. Increased gain each loop instead. 
//Saw LPF frequency increasing. 
0 => count;
chordEnv.keyOn();
while(now < five){
    Std.mtof(triArray3[count]) => tri.freq;
    triEnv.keyOn();
    
    for(0=>int i;i<sawArray3.cap();i++){
        Std.mtof(sawArray3[i]) => saw.freq;
        Std.mtof(sinArray2[i]) => sin.freq;
        (beat/2)::second => now;
        
        sawLoPass.freq()*(1.1) => sawLoPass.freq;
        
        
        for(0=>int i;i<chord.cap();i++){ //increases chord gain each loop. 
            if(chord[i].gain() < 0.08){
                chord[i].gain() + 0.002 => chord[i].gain;
            }
        }
    }
    if(count==6){ chordEnv.keyOff(); }
    
    triEnv.keyOff();
    count++;
}

//reset chord gains to 0
for(0=>int i; i<chord.cap(); i++){
    0 => chord[i].gain;
    Std.mtof(chord2[i]) => chord[i].freq;
}

//Increasing chord2 gain. Saw LPF frequency constant. 
0 => count;
chordEnv.keyOn();
while(now < six){
    Std.mtof(triArray4[count%4]) => tri.freq;
    triEnv.keyOn();
    
    for(0=>int i;i<sawArray3.cap();i++){
        Std.mtof(sawArray1[i]) => saw.freq;
        Std.mtof(sinArray1[i]) => sin.freq;
        (beat/2)::second => now;
        
        for(0=>int i;i<chord.cap();i++){ //increases chord gain each loop. 
            if(chord[i].gain() < 0.08){
                chord[i].gain() + 0.004 => chord[i].gain;
            }
        }
    }
    triEnv.keyOff();
    count++;
    
}
//Let chord volume decay, set all other oscillator gains to 0. 
chordEnv.keyOff();
0 => saw.gain;
0 => tri.gain;
0 => sin.gain;

1::second => now;