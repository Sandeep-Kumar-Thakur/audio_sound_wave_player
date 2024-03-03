library audio_sound_wave_player;

import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';



class AudioSoundWavePlayer extends StatefulWidget {
  final String url;
  final Color soundActiveColor;
  final Color soundInActiveColor;
  final Color backgroundColor;

  const AudioSoundWavePlayer(
      {super.key,
        required this.url,
        required this.backgroundColor,
        required this.soundActiveColor,
        required this.soundInActiveColor});

  @override
  State<AudioSoundWavePlayer> createState() => _AudioSoundWavePlayerState();
}

class _AudioSoundWavePlayerState extends State<AudioSoundWavePlayer> {
  final player = AudioPlayer();
  final playerForDuration = AudioPlayer();

  Duration maxDuration =  const Duration(hours: 100);
  Duration currentDuration =  const Duration(seconds: 0);
  Random random = Random();
  List<double> waves = [];

  StreamController<List<Duration>> controller = StreamController();
  StreamController<bool> playerStateStream = StreamController();

  @override
  void initState() {
    waves.addAll(List.generate(150, (index) {
      return double.parse((random.nextBool() ? "-" : "") +
          (random.nextDouble() * 100).toString());
    }));
    player.onDurationChanged.listen((event) {
      maxDuration = event;
      controller.sink.add([maxDuration, currentDuration]);
    });

    player.onPositionChanged.listen((event) {
      currentDuration = event;
      controller.sink.add([maxDuration, currentDuration]);
      if (maxDuration == currentDuration) {
        Duration currentDuration = const Duration(seconds: 0);
        controller.sink.add([maxDuration, currentDuration]);
        playerStateStream.sink.add(false);
      }
    });

    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(100)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<bool>(
              stream: playerStateStream.stream,
              initialData: false,
              builder: (context, snapshot) {
                return InkWell(
                    onTap: () {
                      if (player.state == PlayerState.playing) {
                        player.pause();
                        playerStateStream.add(false);
                      } else if (player.state == PlayerState.paused) {
                        player.resume();
                        playerStateStream.add(true);
                      } else if (player.state == PlayerState.completed) {
                        player.play(UrlSource(widget.url));
                        playerStateStream.add(true);
                      } else {
                        player.play(UrlSource(widget.url));
                        playerStateStream.add(true);
                      }
                    },
                    child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100)),
                        child: Icon(snapshot.data == true
                            ? Icons.pause
                            : Icons.play_arrow)));
              }),
          const SizedBox(
            width: 10,
          ),
          StreamBuilder<List<Duration>>(
              stream: controller.stream,
              initialData: const [Duration(hours: 1000), Duration(seconds: 0)],
              builder: (context, snapshot) {
                return SquigglyWaveform(
                  invert: true,
                  activeColor: widget.soundActiveColor,
                  inactiveColor: widget.soundInActiveColor,

                  showActiveWaveform: snapshot.data!.last.inSeconds > 1,
                  //style: PaintingStyle.stroke,
                  samples: waves,
                  height: 50,
                  width: 200,
                  maxDuration: snapshot.data!.first.inMilliseconds < 1
                      ? const Duration(seconds: 10)
                      : snapshot.data!.first,
                  elapsedDuration: snapshot.data!.last,
                );
              }),
          const SizedBox(width: 10,),
          FutureBuilder<String>(
              future:
              playerForDuration.setSource(UrlSource(widget.url)).then((value) async {
                Duration? duration = await playerForDuration.getDuration();
                return "${duration!.inMinutes.toString()} : ${duration.inSeconds%60}";
              }),
              initialData: '...',
              builder: (context, snapShot) {
                return Text(
                  snapShot.data ?? "",
                  style: TextStyle(color: widget.soundActiveColor),
                );
              })
        ],
      ),
    );
  }
}