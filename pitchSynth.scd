// Digital Audio Synth Project
//
// Authors
// Anant Sharma (2016129) anant16129@iiitd.ac.in
// Kushagra Singh (2014056) kushagra14056@iiitd.ac.in


// Read file from path onto buffer
b = Buffer.read(s,"/Users/kushagrasingh/Desktop/Sam/Linear-transformation.wav")

// Define synth which takes reads from buffer b, applies modulation, LPF and HPF and sends an out signal.
(SynthDef(\outSynth, {

	// Arguments for LPF, HPF, Carrier frequency, Modulator frequency
	arg qwertyFreq, amp = 1, lpFreq = 10000, hpFreq = 0, modFreq = 0, carFreq = 0;
	var signal, final, modulatedWave, shift;
    var carrierWave;

	// Input signal
	signal = PlayBuf.ar(2, b.bufnum);

	// Create modulated wave
	modulatedWave = SinOsc.ar(carFreq + SinOsc.ar(modFreq));

	// If modFreq and carFreq > 0, multiply input signal with modulated wave
	signal = Select.ar((carFreq > 0) * (modFreq > 0), [signal, signal * modulatedWave]);

	// Apply HPF and LPF
	signal = LPF.ar(signal, lpFreq);
	signal = HPF.ar(signal, hpFreq);

	// Pitch shift according to keyboard input
	shift = FreqShift.ar(signal, Pitch.kr(signal) + qwertyFreq);

	// Apply envelope to pitch shifted
	final = shift * EnvGen.ar(Env.perc,doneAction:2);

	Out.ar(0, [final, final]);
}).send(s);
)





// Define synth interface.
// User can change value of modulator and carrier frequency.
// User canCan add HPF and LPF
(
    w = Window.new("mySynth", 500@500);

    // Global vars for effect arguments
    ~lpFreq = 10000;
    ~hpFreq = 0;
    ~modFreq = 0;
    ~carFreq = 0;

    // On a key down, take present values of effect arguments and run synth using them.
    // Default values set above in case user doesn't anything
    w.view.keyDownAction = {

	    // Get input from keyboard for pitch shifting
    	arg view, char, modifiers, unicode, keycode;
    	var signal, qwertyFreq, noteDictionary;

	    // Shift pitch according to the button pressed
    	noteDictionary = (z:48, x:50, c:52, v:53, b:55, n:57, m:59, ', ':60, '.':62, '/':64, q:60,
		    		      w:62, e:64, r:65, t:67, y:69, u:71, i:72, o:74, p:76, '[':77, ']':79,
				          s:49, d:51, g:54, h:56, j:58, l:61, ';':63, '2':61, '3z':63, '5':66,
				         '6':68, '7':70, '9':73, '0':75, '=':78);
    	// Get frequency to be shited by (check which button was pressed)
    	qwertyFreq = noteDictionary[char.asSymbol].midicps;

	    // Run synth with the current values of effect arguments
    	Synth(\outSynth, [\qwertyFreq, qwertyFreq, \lpFreq, ~lpFreq,
		                  \hpFreq, ~hpFreq, \modFreq, ~modFreq, \carFreq, ~carFreq]);
    };

    // Freq threshold for LPF
    EZSlider(w,Rect(100, 200, 300, 20), "LPF   ", ControlSpec(100, 5000)).action = {|slider|
	    ~lpFreq = slider.value.postln;
    };

    // Freq threshold for HPF
    EZSlider(w,Rect(100, 250, 300, 20),"HPF   ", ControlSpec(0, 10000)).action = {|slider|
	    ~hpFreq = slider.value.postln;
    };

    // Modulator Frequency
    EZKnob(w,Rect(150,20,100,100),"modFreq", ControlSpec(0, 400)).action = {|slider|
	    ~modFreq = slider.value.postln;
    };

    // Carrier Frequency
    EZKnob(w,Rect(300,20,100,100),"carFreq", ControlSpec(0, 400)).action = {|slider|
	    ~carFreq = slider.value.postln;
    };

    w.front;
)