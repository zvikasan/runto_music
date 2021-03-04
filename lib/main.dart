import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/src/foundation/constants.dart';
import 'player.dart';
import 'player_widget.dart';

//------------------- Music Related --------------------------------
typedef void OnError(Exception exception);
const kUrl1 = 'https://luan.xyz/files/audio/ambient_c_motion.mp3';
//----------------End of Music Related -----------------------------

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Stream<StepCount> _stepCountStream;
  Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?', _stepsText = '?';
  int _steps;
  int stepsPerMinute;
  double playbackRate = 0;
  double testVar = 0.3;
  ValueListenable<double> playbackValue;

  @override
  void initState() {
    initPlatformState();
    super.initState();
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
    await Future.delayed(const Duration(seconds: 10), () {});
    endSteps = _steps - startSteps;
    setState(() {
      stepsPerMinute = endSteps * 6;
      playbackRate = stepsPerMinute / 90;
      print(playbackRate.runtimeType);
      print('PLAYBACKRATE $playbackRate');
    });
    // advancedPlayer.setPlaybackRate(playbackRate: _playbackRate);
  }

  void startMeasuring() {
    // Timer timer;
    Timer.periodic(
        Duration(seconds: 5), (Timer t) => calculateStepsPerMinute());
  }

  // ---------------- Music-Related-Code ------------------
  AudioCache audioCache = AudioCache();
  AudioPlayer advancedPlayer = AudioPlayer();

  Widget playLocalAsset() {
    audioCache.fixedPlayer = advancedPlayer;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () {
                    audioCache.play('music/i_like_it.mp3');
                  },
                  child: Text('Play')),
              ElevatedButton(
                  onPressed: () {
                    advancedPlayer.pause();
                  },
                  child: Text('Pause')),
              ElevatedButton(
                  onPressed: () {
                    advancedPlayer.stop();
                  },
                  child: Text('Stop')),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () {
                    advancedPlayer.setPlaybackRate(playbackRate: 0.5);
                  },
                  child: Text('Spd x0.5')),
              ElevatedButton(
                  onPressed: () {
                    advancedPlayer.setPlaybackRate(playbackRate: 1);
                  },
                  child: Text('Spd x1')),
              // ValueListenableBuilder(
              //     // valueListenable: playbackRate,
              //     builder: (BuildContext context, double playbackRate,
              //         Widget child) {
              //   return Row(
              //     children: [Text('$playbackRate')],
              //   );
              // }),
              ElevatedButton(
                  onPressed: () {
                    print('Just Set playback rate to $playbackRate');
                    double setRate;
                    setRate = playbackRate;
                    print('SETRATESETRATE $setRate');
                    advancedPlayer.setPlaybackRate(playbackRate: setRate);
                  },
                  child: Text('Custom')),
              ElevatedButton(
                  onPressed: () {
                    advancedPlayer.setPlaybackRate(playbackRate: 2);
                  },
                  child: Text('Spd x2')),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () {
                    advancedPlayer.setVolume(0);
                  },
                  child: Text('Vol 0')),
              ElevatedButton(
                  onPressed: () {
                    advancedPlayer.setVolume(0.5);
                  },
                  child: Text('Vol 0.5')),
              ElevatedButton(
                  onPressed: () {
                    advancedPlayer.setVolume(0.8);
                  },
                  child: Text('Vol 0.8')),
              ElevatedButton(
                  onPressed: () {
                    advancedPlayer.setVolume(1);
                  },
                  child: Text('Vol 1')),
            ],
          )
        ],
      ),
    );
  }
  // music/i_like_it.mp3

  // ----------------End of Music-Related-Code ------------------

  @override
  Widget build(BuildContext context) {
    // changePlaybackRate();

    return MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: startMeasuring,
          child: Text('Start'),
        ),
        appBar: AppBar(
          title: const Text('Pedometer example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 20),
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
              playLocalAsset(),
              Divider(
                //height: 100,
                thickness: 2,
                color: Colors.blueAccent,
              ),
              Text(
                'Playback Rate $playbackRate',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//--------------- Music Related --------------------------

//--------------End of Music Related ---------------------
