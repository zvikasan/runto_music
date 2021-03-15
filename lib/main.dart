import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import 'dart:async';
import 'package:assets_audio_player/assets_audio_player.dart';

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
  double playbackRate = 1.35;
  double testVar = 0.3;
  ValueListenable<double> playbackValue;
  int lengthOfMeasurement = 20;
  int periodOfMeasurement = 5;
  int songBPM = 129;

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
    await Future.delayed(Duration(seconds: lengthOfMeasurement), () {});
    endSteps = _steps - startSteps;
    setState(() {
      stepsPerMinute = endSteps * 6;
      playbackRate = stepsPerMinute / songBPM; //129 is my sample song BPM
      assetsAudioPlayer.setPlaySpeed(playbackRate);
    });
    // advancedPlayer.setPlaybackRate(playbackRate: _playbackRate);
  }

  void startMeasuring() {
    // Timer timer;
    Timer.periodic(Duration(seconds: periodOfMeasurement),
        (Timer t) => calculateStepsPerMinute());
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
        floatingActionButton: FloatingActionButton(
          onPressed: startMeasuring,
          child: Text('Start'),
        ),
        appBar: AppBar(
          title: const Text('Pedometer example app'),
        ),
        body: Center(
          child: SingleChildScrollView(
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
                        onPressed: () {
                          assetsAudioPlayer
                              .open(Audio('assets/music/i_like_it.mp3'));
                        },
                        child: Text('OpenSong')),
                    ElevatedButton(
                        onPressed: () {
                          assetsAudioPlayer.play();
                        },
                        child: Text('Play')),
                    ElevatedButton(
                        onPressed: () {
                          assetsAudioPlayer.stop();
                        },
                        child: Text('NewPlayerStop')),
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(labelText: 'P of M'),
                      ),
                    ),
                    Container(
                      width: 90,
                      child: TextField(
                        onSubmitted: (nums) {
                          setState(() {
                            songBPM = int.parse(nums);
                          });
                        },
                        //keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(labelText: 'Song BPM'),
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
                    Text('Length: $lengthOfMeasurement'),
                    Text('Period: $periodOfMeasurement'),
                    Text('SongBPM: $songBPM')
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//--------------- Music Related --------------------------

//--------------End of Music Related ---------------------
