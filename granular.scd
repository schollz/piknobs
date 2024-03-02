(
    s.waitForBoot({
        Routine {
        "starting up".postln;

        SynthDef("fx", {
            var rev;
                var snd = In.ar(0, 2);
        snd = AnalogTape.ar(snd, 0.9, 0.9, 0.7, 2);
        rev = Fverb.ar(snd[0], snd[1],
            predelay: 50,
            tail_density: LFNoise2.kr(1 / 3).range(50, 90),
            decay: LFNoise2.kr(1 / 3).range(50, 90)
        );
        snd = SelectX.ar(LFNoise2.kr(1 / 3).range(0.2, 0.4), [snd, rev]);
        ReplaceOut.ar(0, snd);
    }).add;

SynthDef("grain", {
    arg buf, freq=1, move=1, pos=0, t_jump=1, rate=1, db=0, dur=1, num=0, dir=1, pan=0;
    var snd, phase;
    rate = Clip.kr(rate, -2, 2);
    freq = Clip.kr(freq, 0.1, 10);
    dur = Clip.kr(dur, 0.25, 6);
    phase = Phasor.ar(
        trig: t_jump + TDelay.kr(Impulse.kr(0), 0.01),
        rate: move * rate / BufFrames.ir(buf),
        start: 0,
        end: 1,
        resetPos: 0,
    );
    snd = GrainBuf.ar(
        numChannels: 1,
        trigger: Impulse.kr(freq),
        dur: dur,
        sndbuf: buf,
        pos: phase,
        rate: rate.sign * [1],
        interp: 4,
        maxGrains: 64,
        mul: [1]
    );
    snd = Mix.new(snd);
    snd = Pan2.ar(snd, pan);
    Out.ar(0, snd * 12.neg.dbamp * db.dbamp);
}).add;

s.sync;

~file1 = "PMJO_Vocal_Sessions_Cosmic_145_Dm_Vocal_Atmosphere_05_keyDmin_bpm145_beats24_.flac";
~file2 = "cm_pad90_celestial_Dm_keyDmin_bpm90.wav";
~bufs=Dictionary.new();
~syns=Dictionary.new();
~bufs.put("1l", Buffer.readChannel(s, thisProcess.nowExecutingPath.dirname++"/"++~file1, channels: [0]));
~bufs.put("1r", Buffer.readChannel(s, thisProcess.nowExecutingPath.dirname++"/"++~file1, channels: [1]));
~bufs.put("2l", Buffer.readChannel(s, thisProcess.nowExecutingPath.dirname++"/"++~file2, channels: [0]));
~bufs.put("2r", Buffer.readChannel(s, thisProcess.nowExecutingPath.dirname++"/"++~file2, channels: [1]));


s.sync;
~syns.put("fx", Synth.tail(s, "fx"));
~syns.put("1l", Synth.head(s, "grain", [
    \buf, ~bufs.at("1l").postln,
    \pan, -1,
]));
~syns.put("1r", Synth.head(s, "grain", [
    \buf, ~bufs.at("1r").postln,
    \pan, 1,
]));
~syns.put("2l", Synth.head(s, "grain", [
    \buf, ~bufs.at("2l"),
    \pan, -1,
    \db, -96,
]));
~syns.put("2r", Synth.head(s, "grain", [
    \buf, ~bufs.at("2r"),
    \pan, 1,
    \db, -96,
]));

if (o.notNil, {
    o.free
});
o = OSCFunc({
    arg msg;
    msg.postln;

    ["l", "r"].do({ arg v;
                    ~syns.at("1"++v).set(
        \db, msg[1].linlin(0, 255, -48, 12),
        \rate, msg[2].linlin(0, 255, -0.5, 0.5),
        \freq, msg[3].linexp(1, 255, 1.2, 40),
        \dur, msg[4].linexp(1, 255, 1 / 1.2, 1 / 40),
    );
});
["l", "r"].do({ arg v;
                    ~syns.at("2"++v).set(
    \db, msg[5].linlin(0, 255, -48, 12),
    \rate, msg[6].linlin(0, 255, -0.5, 0.5),
    \freq, msg[7].linexp(1, 255, 1.2, 40),
    \dur, msg[8].linexp(1, 255, 1 / 1.2, 1 / 40),
);
                });
            }, "/ads7830", recvPort: 7771);
        }.play;
    });
    )
