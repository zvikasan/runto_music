import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import 'dart:async';
import 'package:assets_audio_player/assets_audio_player.dart';

//------------------- Music Related --------------------------------
// typedef void OnError(Exception exception);
// const kUrl1 = 'https://luan.xyz/files/audio/ambient_c_motion.mp3';
//----------------End of Music Related -----------------------------

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'RuntoMusic'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  Stream<StepCount> _stepCountStream;
  Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?', _stepsText = '?';
  int _steps;
  int stepsPerMinute = 0;
  double playbackRate = 1.35;
  double testVar = 0.3;
  ValueListenable<double> playbackValue;
  int lengthOfMeasurement = 20000; // in milliseconds
  int periodOfMeasurement = 2000; // in milliseconds
  int songBPM = 129;
  int corrCoef = 0;
  int initialStepsNumber = 0;
  bool stopMeasuring = true;

  // --- new approach variables ---
  List<int> stepsDataList = [];
  AnimationController _playbackRateController;
  // --- end of new approach variables ---

  var songsBpmMap = {
    'assets/music/i_like_it.mp3': 129,
    'assets/music/despacito.mp3': 89,
    'assets/music/eye-of-tiger.mp3': 108,
    'assets/music/final-countdown.mp3': 117,
    'assets/music/gotta-feeling.mp3': 129,
    'assets/music/higher-love.mp3': 103,
    'assets/music/maniac.mp3': 161,
    'assets/music/pump-it.mp3': 103,
  };

  @override
  void initState() {
    initPlatformState();
    super.initState();
  }

  double setSpeed = 1.0;
  void animatePlaybackSpeed() {
    setState(() {
      setSpeed += 0.01;
      assetsAudioPlayer.setPlaySpeed(setSpeed);
    });
    print(setSpeed);

    // _playbackRateController = AnimationController(
    //     duration: Duration(seconds: 30),
    //     vsync: this,
    //     lowerBound: 1,
    //     upperBound: 2);
    // _playbackRateController.addListener(() {
    //   setState(() {
    //     assetsAudioPlayer.setPlaySpeed(_playbackRateController.value);
    //   });
    //   print(_playbackRateController.value);
    //   print(assetsAudioPlayer.playSpeed.toString());
    // });
    // _playbackRateController.forward();
  }

  void onStepCount(StepCount event) {
    print(event);
    setState(() {
      _stepsText = event.steps.toString();
      _steps = event.steps;
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _stepsText = 'Step Count not available';
    });
  }

  void initPlatformState() {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
        .onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);

    if (!mounted) return;
  }

  calculateStepsPerMinute() async {
    int startSteps = _steps;
    int endSteps = 0;

    await Future.delayed(Duration(seconds: lengthOfMeasurement), () {});
    endSteps = _steps - startSteps;
    setState(() {
      songBPM = songsBpmMap[
          '${assetsAudioPlayer.current.valueWrapper.value.audio.assetAudioPath}'];
      stepsPerMinute = (endSteps * (60 / lengthOfMeasurement)).round();
      if ((stepsPerMinute / songBPM) > playbackRate * 1.002 ||
          (stepsPerMinute / songBPM) < playbackRate * 0.97) {
        playbackRate = (stepsPerMinute /
            (songBPM +
                corrCoef)); //129 is the BPM of first song in my test playlist
        assetsAudioPlayer.setPlaySpeed(playbackRate);
      }
    });
    // advancedPlayer.setPlaybackRate(playbackRate: _playbackRate);
  }

  void startMeasuring() {
    // Timer timer;
    Timer.periodic(Duration(milliseconds: periodOfMeasurement), (Timer t) {
      calculateStepsPerMinute();
    });
  }

  void startMeasuringNew() {
    stepsDataList = [];
    initialStepsNumber = _steps;
    if (stopMeasuring) {
      setState(() {
        stopMeasuring = false;
      });
    } else {
      setState(() {
        stopMeasuring = true;
      });
    }
    if (!stopMeasuring) {
      Timer.periodic(Duration(milliseconds: periodOfMeasurement), (Timer t) {
        if (!stopMeasuring) {
          calculateStepsPerMinuteNew();
        } else {
          t.cancel();
        }
      });
    }
  }

  void calculateStepsPerMinuteNew() async {
    if (stepsDataList.length == 0) {
      stepsDataList.add(_steps);
    } else {
      setState(() {
        stepsPerMinute = (((stepsDataList[0] - stepsDataList.last) /
                    (periodOfMeasurement * stepsDataList.length)) *
                60000)
            .round();
        if ((stepsPerMinute / songBPM) > playbackRate * 1.01 ||
            (stepsPerMinute / songBPM) < playbackRate * 0.99) {
          playbackRate = (stepsPerMinute /
              (songBPM +
                  corrCoef)); //129 is the BPM of first song in my test playlist
          if (playbackRate > 0.3) {
            assetsAudioPlayer.setPlaySpeed(playbackRate);
          }
        }
      });
      // print('STEPS DATA LIST LENGTH: ${stepsDataList.length}');
      // print('INITIAL STEPS NUMBER: $initialStepsNumber');
      // print('STEPS: $_steps');
      // print('STEPS PER MINUTE: $stepsPerMinute');
      // print('PLAYBACK RATE: $playbackRate');
      // print(
      //     'STEPS DATA FIRST: ${stepsDataList.last} LAST: ${stepsDataList[0]}');
      if (stepsDataList.length >= (lengthOfMeasurement / periodOfMeasurement)) {
        stepsDataList.removeLast();
        // print('REMOVED');
      }
      stepsDataList.insert(0, _steps);
    }
  }

  // ---------------- Music-Related-Code ------------------
  final assetsAudioPlayer = AssetsAudioPlayer();

  void newMusic() {
    assetsAudioPlayer.open(Audio('assets/music/i_like_it.mp3'));
    assetsAudioPlayer.play();
  }
  // ----------------End of Music-Related-Code ------------------

  @override
  Widget build(BuildContext context) {
    // changePlaybackRate();
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: startMeasuringNew,
          label: Text('Start / Stop'),
        ),
        appBar: AppBar(
          title: const Text('Run To Music'),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  !stopMeasuring ? 'STARTED' : 'STOPPED',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Text(
                'Steps taken:',
                style: TextStyle(fontSize: 10),
              ),
              Text(
                _stepsText,
                style: TextStyle(fontSize: 10),
              ),
              Divider(
                //height: 100,
                thickness: 2,
                color: Colors.blueAccent,
              ),
              Text(
                'SPM: ${stepsPerMinute.toString()}',
                style: TextStyle(
                    fontSize: 40,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold),
              ),
              Divider(
                // height: 100,
                thickness: 2,
                color: Colors.blueAccent,
              ),
              Text(
                'Pedestrian status:',
                style: TextStyle(fontSize: 10),
              ),
              Icon(
                _status == 'walking'
                    ? Icons.directions_walk
                    : _status == 'stopped'
                        ? Icons.accessibility_new
                        : Icons.error,
                size: 10,
              ),
              Center(
                child: Text(
                  _status,
                  style: _status == 'walking' || _status == 'stopped'
                      ? TextStyle(fontSize: 30)
                      : TextStyle(fontSize: 20, color: Colors.red),
                ),
              ),
              Divider(
                //height: 100,
                thickness: 2,
                color: Colors.blueAccent,
              ),
              Text(
                'Playback Rate $playbackRate',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              Divider(
                //height: 100,
                thickness: 2,
                color: Colors.blueAccent,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: () async {
                        await assetsAudioPlayer.previous();
                        setState(() {
                          songBPM = songsBpmMap[
                              '${assetsAudioPlayer.current.valueWrapper.value.audio.assetAudioPath}'];
                        });
                      },
                      child: Icon(Icons.skip_previous)),
                  ElevatedButton(
                      onPressed: () async {
                        await assetsAudioPlayer.play();
                        setState(() {
                          songBPM = songsBpmMap[
                              '${assetsAudioPlayer.current.valueWrapper.value.audio.assetAudioPath}'];
                        });
                      },
                      child: Icon(Icons.play_arrow)),
                  ElevatedButton(
                      onPressed: () {
                        assetsAudioPlayer.pause();
                      },
                      child: Icon(Icons.pause)),
                  ElevatedButton(
                      onPressed: () async {
                        await assetsAudioPlayer.next();
                        setState(() {
                          songBPM = songsBpmMap[
                              '${assetsAudioPlayer.current.valueWrapper.value.audio.assetAudioPath}'];
                        });
                      },
                      child: Icon(Icons.skip_next)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        // assetsAudioPlayer
                        //     .open(Audio('assets/music/i_like_it.mp3'));
                        assetsAudioPlayer.open(
                          Playlist(audios: [
                            Audio("assets/music/i_like_it.mp3",
                                playSpeed: stepsPerMinute == 0
                                    ? 1
                                    : stepsPerMinute /
                                        (songsBpmMap[
                                                'assets/music/i_like_it.mp3']
                                            .toDouble())),
                            Audio("assets/music/despacito.mp3",
                                playSpeed: stepsPerMinute == 0
                                    ? 1
                                    : stepsPerMinute /
                                        (songsBpmMap[
                                                'assets/music/despacito.mp3']
                                            .toDouble())),
                            Audio("assets/music/eye-of-tiger.mp3",
                                playSpeed: stepsPerMinute == 0
                                    ? 1
                                    : stepsPerMinute /
                                        (songsBpmMap[
                                                'assets/music/eye-of-tiger.mp3']
                                            .toDouble())),
                            Audio("assets/music/final-countdown.mp3",
                                playSpeed: stepsPerMinute == 0
                                    ? 1
                                    : stepsPerMinute /
                                        (songsBpmMap[
                                                'assets/music/final-countdown.mp3']
                                            .toDouble())),
                            Audio("assets/music/gotta-feeling.mp3",
                                playSpeed: stepsPerMinute == 0
                                    ? 1
                                    : stepsPerMinute /
                                        (songsBpmMap[
                                                'assets/music/gotta-feeling.mp3']
                                            .toDouble())),
                            Audio("assets/music/higher-love.mp3",
                                playSpeed: stepsPerMinute == 0
                                    ? 1
                                    : stepsPerMinute /
                                        (songsBpmMap[
                                                'assets/music/higher-love.mp3']
                                            .toDouble())),
                            Audio("assets/music/maniac.mp3",
                                playSpeed: stepsPerMinute == 0
                                    ? 1
                                    : stepsPerMinute /
                                        (songsBpmMap['assets/music/maniac.mp3']
                                            .toDouble())),
                            Audio("assets/music/pump-it.mp3",
                                playSpeed: stepsPerMinute == 0
                                    ? 1
                                    : stepsPerMinute /
                                        (songsBpmMap['assets/music/pump-it.mp3']
                                            .toDouble())),
                          ]),
                          loopMode: LoopMode.playlist,
                          playInBackground: PlayInBackground.enabled,
                        );
                        // setState(() {
                        //   // songBPM = 129;
                        //   assetsAudioPlayer.playlistAudioFinished
                        //       .listen((event) {
                        //     songBPM = songsBpmMap[
                        //         '${assetsAudioPlayer.current.value.audio.assetAudioPath}'];
                        //   });
                        // });
                      },
                      child: Text('Open')),
                  ElevatedButton(
                      onPressed: () {
                        assetsAudioPlayer.stop();
                      },
                      child: Icon(Icons.stop)),
                  ElevatedButton(
                      onPressed: () {
                        animatePlaybackSpeed();
                      },
                      child: Icon(Icons.speed)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        assetsAudioPlayer.setPlaySpeed(0.5);
                      },
                      child: Text('x0.5')),
                  ElevatedButton(
                      onPressed: () {
                        assetsAudioPlayer.setPlaySpeed(1.0);
                      },
                      child: Text('x1.0')),
                  ElevatedButton(
                      onPressed: () {
                        assetsAudioPlayer.setPlaySpeed(1.5);
                      },
                      child: Text('x1.5')),
                  ElevatedButton(
                      onPressed: () {
                        assetsAudioPlayer.setPlaySpeed(2.0);
                      },
                      child: Text('x2.0')),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        assetsAudioPlayer.setPlaySpeed(0.23);
                      },
                      child: Text('x0.23')),
                  ElevatedButton(
                      onPressed: () {
                        assetsAudioPlayer.setPlaySpeed(1.67);
                      },
                      child: Text('x1.67')),
                  ElevatedButton(
                      onPressed: () {
                        assetsAudioPlayer.setPlaySpeed(1.23);
                      },
                      child: Text('x1.23')),
                  ElevatedButton(
                      onPressed: () {
                        assetsAudioPlayer.setPlaySpeed(2.34);
                      },
                      child: Text('x2.34')),
                ],
              ),
              Divider(
                //height: 100,
                thickness: 2,
                color: Colors.blueAccent,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 50,
                    child: TextField(
                      onSubmitted: (nums) {
                        setState(() {
                          lengthOfMeasurement = int.parse(nums);
                        });
                      },
                      //keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'L of M'),
                    ),
                  ),
                  Container(
                    width: 50,
                    child: TextField(
                      onSubmitted: (nums) {
                        setState(() {
                          periodOfMeasurement = int.parse(nums);
                        });
                      },
                      //keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(labelText: 'P of M'),
                    ),
                  ),
                  Container(
                    width: 90,
                    child: TextField(
                      onSubmitted: (nums) {
                        setState(() {
                          corrCoef = int.parse(nums);
                        });
                      },
                      //keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(labelText: 'Correction'),
                    ),
                  ),
                ],
              ),
              Divider(
                //height: 100,
                thickness: 2,
                color: Colors.blueAccent,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Length: ${lengthOfMeasurement / 1000}'),
                  Text('Period: $periodOfMeasurement'),
                  Text('SongBPM: $songBPM'),
                  Text('Corr: $corrCoef')
                ],
              ),
              Divider(
                //height: 100,
                thickness: 2,
                color: Colors.blueAccent,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    RaisedButton(
                      onPressed: () {
                        setState(() {
                          lengthOfMeasurement = 60;
                          periodOfMeasurement = 200;
                          corrCoef = 15;
                        });
                      },
                      child: Text('Reset Values'),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

//--------------- Music Related --------------------------

//--------------End of Music Related ---------------------
