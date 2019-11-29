(
s.waitForBoot
{
	~b1 = Buffer.readChannel(s, "Cthulhu-trifft-Bach-im-Advent-(Chorale-125).ogg", channels:[0]);

	(
	SynthDef.new(\stretcher, {
		arg buf, pitchRatio=1, grainRate=20, overlap=4, posSpeed=1, ffreq=20000, reverb=0, randAmt=0, amp=1;
		var randF = LFNoise1.kr(0.1).linlin(0,1,0.1,1);
		var rdDur = LFNoise2.kr(randF).clip2().squared * randAmt;
		var rdPitch = LFNoise2.kr(randF).clip2().squared * randAmt;
		var rdPos = LFNoise2.kr(randF).clip2().squared * randAmt;
		var grainDur = (overlap / grainRate) * (1.0 - rdDur);
		var pitchRate = pitchRatio * (1.0 - rdPitch);
		var position = LFSaw.kr(posSpeed / BufDur.kr(buf)).range(0,1) * (1.0 - rdPos);
		var sig = GrainBuf.ar(2, Impulse.kr(grainRate), grainDur, buf, pitchRate, position, 4, 0, -1);
		sig = MoogFF.ar(sig, ffreq);
		sig = FreeVerb.ar(sig, reverb, 1, 0.2);
		Out.ar(0, Limiter.ar(sig*amp));
	}).add;
	);

	s.sync;
	y = Synth.new(\stretcher, [\buf, ~b1]);
	s.sync;

	(
		w = Window("Fullscreen Analyzer", Rect(0, 0, 1920, 1080));
		f = FreqScopeView(w, w.view.bounds);
		f.active_(true);
		w.onClose_({ f.kill });
		w.front;
		w.fullScreen;
	);

	(
	OSCdef.new(\pitchRatio, {|msg, time, addr, recvPort| y.set(\pitchRatio, msg[1].linlin(0,1,-36,36).midiratio)}, "/pitch/ratio", NetAddr.new("127.0.0.1", 55555), 55556);
	OSCdef.new(\randomnessAmount, {|msg, time, addr, recvPort| y.set(\randAmt, msg[1].linlin(0,1,0,0.25))}, "/randomness/amount", NetAddr.new("127.0.0.1", 55555), 55556);
	OSCdef.new(\grainRate, {|msg, time, addr, recvPort| y.set(\grainRate, msg[1].linexp(0,1,1,500))}, "/grain/rate", NetAddr.new("127.0.0.1", 55555), 55556);
	OSCdef.new(\grainOverlap, {|msg, time, addr, recvPort| y.set(\overlap, msg[1].linlin(0,1,1,10))}, "/grain/overlap", NetAddr.new("127.0.0.1", 55555), 55556);
	OSCdef.new(\positionSpeed, {|msg, time, addr, recvPort| y.set(\posSpeed, msg[1]*2)}, "/position/speed", NetAddr.new("127.0.0.1", 55555), 55556);
	OSCdef.new(\reverbMix, {|msg, time, addr, recvPort| y.set(\reverb, msg[1])}, "/reverb/mix", NetAddr.new("127.0.0.1", 55555), 55556);
	OSCdef.new(\filterCutoff, {|msg, time, addr, recvPort| y.set(\ffreq, msg[1].linexp(0,1,20,20000))}, "/filter/cutoff", NetAddr.new("127.0.0.1", 55555), 55556);
	OSCdef.new(\volume, {|msg, time, addr, recvPort| y.set(\amp, msg[1].linexp(0,1,-60.dbamp,2))}, "/volume", NetAddr.new("127.0.0.1", 55555), 55556);
	)
}
)
