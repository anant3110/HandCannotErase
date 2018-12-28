~server = Server.local.options;
~server.numOutputBusChannels = 10;
~server.device = "Scarlett 18i20 USB"

// Supercollider interface for Hand cannot Erase
//
// This work was done as a part of the Digital Audio
// course at IIIT Delhi
//
// Authors
// Anant Sharma (2016129) anant16129@iiitd.ac.in
// Kushagra Singh (2014056) kushagra14056@iiitd.ac.in

// Initial coordinatexs
x=200;
y=150;

~widthBus=Bus.control.set(0);
~xcoord=0;
~ycoord= 0;
~dis=0;


// Window for surround 5.1 speakers
// source modified from SuperCollider examples
(
var speakerList, targx=200, targy=150;
var atorad = (2pi) / 360, rtoang = 360.0 / (2pi);
var targRotate, actRotate;
var maxShiftPerFrame = 20, frameInterval = 0.01;
var resched = false, count = 0;
var panBus, recButton;
var a, b, c;

maxShiftPerFrame = maxShiftPerFrame * atorad;
~actPoint = Point(x, y) - Point(200, 200);
panBus = Bus.control;
~widthBus = Bus.control.set(0);

w = Window.new("5.1 Panner", Rect(128, 64, 400, 450)).front;
w.view.background_(Color.grey(0.3));
w.view.decorator = FlowLayout(w.view.bounds);
// speakerList = [[-22.5, "L"], [22.5, "R"], [67.5, "C"], [112.5, "Rs"], [157.5, "Lb"], [-157.5, "Rb"], [-112.5, "Rs"], [-67.5, "Ls"]];
// speakerList = [[-30, "L"], [30, "R"], [0, "C"], [-90, "Ls"], [90, "Rs"], [-150, "Lb"], [150, "Rb"]];
speakerList = [[-22.5, "L"], [22.5, "R"], [-67.5, "Ls"], [67.5, "C"], [-112.5, "Rs"], [112.5, "Rs"], [-157.5, "Lb"], [157.5, "Rb"]];

c = UserView.new(w,Rect(0, 0, 400, 380));
c.canFocus = false;

c.drawFunc = {

    Color.grey(0.8).set;
    // draw the speaker layout
    Pen.translate(200,200);
    ((~actPoint.theta + (0.5pi)).wrap2(pi) * rtoang).round(0.01).asString.drawCenteredIn(Rect.aboutPoint(0@170, 30, 10), Font.new("Arial", 10), Color.grey(0.8));
    Pen.strokeOval(Rect.aboutPoint(0@0, 150, 150));
    Pen.rotate(pi);

    speakerList.do({|spkr|
        Pen.use({
            Pen.rotate(spkr[0] * atorad);
            Pen.moveTo(0@170);
            Pen.strokeRect(r = Rect.aboutPoint(0@170, 30, 10));
            if(spkr[0].abs < 90, {
                Pen.use({
                    Pen.translate(0, 170);
                    Pen.rotate(pi);
                    spkr[1].drawCenteredIn(Rect.aboutPoint(0@0, 30, 10),
                        GUI.font.new("Arial", 10), Color.grey(0.8));
                });
            },{
                spkr[1].drawCenteredIn(r, GUI.font.new("Arial", 10), Color.grey(0.8));
            });
        });
    });

    Pen.moveTo(0@0);

    // draw the pan point
    Pen.rotate(~actPoint.theta + 0.5pi);

    ~targPoint = Point(x, y) - Point(200, 200);

    // trunc to avoid loops due to fp math
    targRotate = (~targPoint.theta - ~actPoint.theta).trunc(1e-15);
    // wrap around
    if(targRotate.abs > pi, {targRotate = (2pi - targRotate.abs) * targRotate.sign.neg});
    actRotate = targRotate.clip2(maxShiftPerFrame).trunc(1e-15);

    ~actPoint = ~actPoint.rotate(actRotate);

    Pen.rotate(actRotate);
    Pen.lineTo(0@150);
    Pen.stroke;
    Pen.fillOval(Rect.aboutPoint(0@150, 7, 7));
    Pen.addWedge(0@0, 140, neg(e.value * 0.5) * atorad + 0.5pi, e.value * atorad);
    Pen.stroke;
    Color.grey(0.8).alpha_(0.1).set;
    Pen.addWedge(0@0, 140, neg(e.value * 0.5) * atorad + 0.5pi, e.value * atorad);
    Pen.fill;


    if((actRotate.abs > 0), {AppClock.sched(frameInterval, {w.refresh})}, {count = 0;});
    if(count%4 == 0, {panBus.set((~actPoint.theta + (0.5pi)).wrap2(pi) * rtoang)});

};

// Use mouse on GUI interface to adjust coordinates
c.mouseMoveAction_({|v,inx,iny| x = inx; y = iny; w.refresh;});
c.mouseDownAction_({|v,inx,iny| x = inx; y = iny; w.refresh;});

// Slider for spread in GUI
e = EZSlider.new(w, 380@20, "Stereo Width", [0, 100].asSpec, {arg ez; ~widthBus.set(ez.value); w.refresh}, labelWidth: 80);
e.labelView.setProperty(\stringColor,Color.grey(0.8));
w.refresh;


a = VBAPSpeakerArray.new(2, speakerList.collect(_.first));
b = a.loadToBuffer;

SynthDef('VBAP 8 chan', { |azi = 0, ele = 0, spr = 0, width = 0, vbapBuf|
	var panned, source;


	var freq = 150, offset = 0, wave, mix = 0.5, room = 0.7, env;
	offset = LFTri.ar(10);
	// env = Line.ar(1, 0, 0.5, doneAction:2);
	env = 1;
	wave = Saw.ar([freq,freq + offset]) + SinOsc.ar([freq, freq + offset + 4]) * offset;
	source = FreeVerb.ar(wave, mix) * env;

	// source = SinOsc.ar([440, 660], 0, Decay2.ar(Impulse.ar([1, 0.9]), 0.1, 0.2));
	// source = SinOsc.ar(240);
	source = Buffer.read(s,"/Users/kushagrasingh/Desktop/output4.wav");
	source = PlayBuf.ar(8, source.bufnum, loop:1);

	azi = azi.circleRamp;
	panned = VBAP.ar(8, source, vbapBuf, [azi - (0.5 * width), azi + (0.5 * width)], ele, spr);

	// 'standard' channel order for 5.1
	// [0, 1, 2, 4, 5].do({arg bus, i; Out.ar(bus, panned[0][i])});
	// [0, 1, 2, 4, 5].do({arg bus, i; Out.ar(bus, panned[1][i])});

	// 'standard' channel order for 8.1
	[0, 1, 2, 3, 4, 5, 6, 7].do({arg bus, i; Out.ar(bus, panned[0][i])});
	[0, 1, 2, 3, 4, 5, 6, 7].do({arg bus, i; Out.ar(bus, panned[1][i])});

}).play(s, [vbapBuf: b.bufnum, azi: panBus.asMap, width: ~widthBus.asMap]);
)


// Update every 0.01 seconds
(AppClock.sched(0.0,{ arg time;

	// Update coordinates
	x = ~xcoord;
	y = ~ycoord;

	// Update spread
	e.value=~dis;
	~widthBus.set(~dis);

	// Redraw interface
	w.refresh;
	rrand(0.01,0.01);
});
)
AppClock.clear


// Get data from Kinect Stream (OSC)
thisProcess.openUDPPort(1121); // attempt to open 1121
thisProcess.openPorts; // list all open ports

(
~stream = { |msg, time, addr|
    if(msg[0] != '/status.reply') {
		"time: % sender: %\nmessage: %\n".postf(time, addr, msg);

		// Right hand -> 3 -> x, 4 -> y, 6 -> index
		// Get coordinate and distance values from Kinect stream
		~xcoord = msg.at(3).asFloat + 200;
		~ycoord = -1 * msg.at(4).asFloat + 200;
		~dis = (msg.at(6).asFloat * 100).asInteger;
	}}
)

// Bind stream function
thisProcess.addOSCRecvFunc(~stream);

// Stop stream function
thisProcess.removeOSCRecvFunc(~stream);

