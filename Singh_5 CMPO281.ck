135 => float bpm;
60/bpm => float beat;
beat/4 => float quarter;
4*beat => float bar;

SndBuf kick => LPF drumFilter => Gain drumGain => dac;
SndBuf snr => drumFilter => drumGain => dac;
SndBuf hat => drumFilter => drumGain => dac;

SawOsc saw => ADSR sawEnv => NRev sawRev => dac;
SinOsc mod => SqrOsc sqr => dac;
mod => SinOsc sin => dac;
SinOsc fall => dac;

//File reader Stuff
me.dir() => string path;
"/audio/kick_03.wav" => string kickFile;
"/audio/snare_03.wav" => string snrFile;
"/audio/hh_04.wav" => string hatFile;
path+kickFile => kickFile;
path+snrFile => snrFile;
path+hatFile => hatFile;
kickFile => kick.read;
snrFile => snr.read;
hatFile => hat.read;

//drums
0 => kick.rate;
0 => snr.rate;
0 => hat.rate;
0.3 => kick.gain;
0.3 => snr.gain;
0.07 => hat.gain;
0.15 => drumGain.gain;
drumFilter.freq(500);

//saw
sawEnv.set(0::ms, 50::ms, 0, 1::ms);
sawRev.mix(0);
saw.gain(0.05);

//mod
mod.freq(3/(2*beat));
mod.gain(2);

//sqr
sqr.gain(0.025);
0.025 => float sqrGain; //to remember inital gain
sqr.sync(2);
[32, 33, 30] @=> int sqrArr[]; //arr of sqr midi notes

//sin
sin.gain(0.1);
0.1 => float sinGain; //to remember initial gain
sin.sync(2);
[60, 61, 57] @=> int sinArr[]; //arr of sin midi notes

//sin used in sinFall method
fall.gain(0);

/*50% chance to return 0, 25% chance to return 0.5, 
25% chance to return 1*/
fun float randGain(){
    Std.randf() => float rand;
    if(rand < 0){
        return 0.;
    }else if(rand < 0.5){
        return 0.5;
    }else{
        return 1.0;
    }
}

/* passed an array of ints, randomly returns one of the elements of the array*/
fun int randArr(int arr[]){
    Std.rand2(0, arr.cap() -1) => int rand;
    return arr[rand];
}

/* sweeps sin wave between freq hi -> freq lo, over duration d */
fun void sinFall(dur d, float hi, float lo){
    fall.gain(0);
    fall.freq(hi);
    for(0 => int i; i<1000; i++){
        if(fall.gain() < 0.25){
            fall.gain() + 0.001 => fall.gain;
        }
        fall.freq() - (hi-lo)/1000 => fall.freq; //frequency drops from hi to lo over duration
        (d/1000) => now;
    }
    fall.gain(0);
}

/*Plays saw sound, randomly chooses freq between 3 high octaves */
fun void playHiSaw(){
    Std.mtof(randArr([68, 75, 80, 87, 92])) => saw.freq;
    sawEnv.keyOn();
}

/* plays drum sequence according to counter i */
fun void playDrums(int i){
    if((i%16)==0||(i%16)==6){
        kick.pos(0);
        kick.rate(1);
    }
    if((i%16)==8){
        snr.pos(0);
        snr.rate(1);
    }
    hat.pos(0);
    hat.rate(1);
    hat.gain(randGain()*0.1);
}

/* plays bass (Sqr & sin) sequence according to counter i */
fun void playBass(int i){
    if(i%64==0){
        sqr.freq(Std.mtof(sqrArr[0]));
        sin.freq(Std.mtof(sinArr[0]));
    } 
    if(i%64==32){
        sqr.freq(Std.mtof(sqrArr[1])); 
        sin.freq(Std.mtof(sinArr[1])); 
    }
    if(i%64==48){
        sqr.freq(Std.mtof(sqrArr[2])); 
        sin.freq(Std.mtof(sinArr[2])); 
    }
}


sin.gain(0);
sqr.gain(0);

//bars per loop
4 => int one;
8 => int two;
8 => int three; 

0 => int i; //counter

<<<"SECTION 1">>>;
while(i < 16*one - 8){
    playDrums(i);
    playHiSaw();
    if(drumFilter.freq()*1.2 > 10000){
        10000 => drumFilter.freq;
    }else{
        drumFilter.freq()*1.05 => drumFilter.freq;
    }
    quarter::second => now;
    i++;
}
snr.pos(0);
snr.rate(1);
sinFall((2*beat)::second, 1000, 100); 

<<<"SECTION 2">>>;
sin.gain(0.07);
sqr.gain(0.025);
0 => i;
while(i < 16*two){
    playDrums(i);
    playHiSaw();
    playBass(i);
    (beat/4)::second => now;
    i++;
}

<<<"SECTION 3">>>;
kick.pos(0);
kick.rate(1);
sqr.gain(0);
sin.gain(0);
sinFall((2*beat)::second, 200, 50);
8 => i;
while(i < 16){ 
    if(i%8==0||i%8==3||i%8>5){
        snr.pos(0);
        snr.rate(1);
    }
    if(i%8==1||i%8==4){
        kick.pos(0);
        kick.rate(1);
    }
    i++;
    (beat/4)::second => now;
}
sin.gain(sinGain);
sqr.gain(sqrGain);
sin.freq(Std.mtof(sinArr[0]));
sqr.freq(Std.mtof(sqrArr[0]));
saw.gain(0.1);
sawRev.mix(0.7);
[87, 80, 84, 92, 88, 85, 90, 88] @=> int sawArr[];
2 => int sawCount;
while(i < 16*three){
    playDrums(i);
    playBass(i);
    if(i%8==0){
        saw.freq(Std.mtof(sawArr[sawCount%8]));
        sawEnv.keyOn();
        sawCount++;
    }
    
    
    (beat/4)::second => now;
    i++;
}







