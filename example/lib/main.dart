import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:open_file/open_file.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:screen_recorder/screen_recorder.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false, home: SimpleScreenScreen());
  }
}

class SimpleScreenScreen extends StatefulWidget {
  const SimpleScreenScreen({Key? key}) : super(key: key);
  @override
  SimpleScreenScreenState createState() => SimpleScreenScreenState();
}

class SimpleScreenScreenState extends State<SimpleScreenScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  final _screenRecorderPlugin = ScreenRecorder();
  bool _isRecording = false;
  String _url = "";
  requestPermissions() async {
    if (await Permission.storage.request().isDenied) {
      await Permission.storage.request();
    }
    if (await Permission.photos.request().isDenied) {
      await Permission.photos.request();
    }
    if (await Permission.microphone.request().isDenied) {
      await Permission.microphone.request();
    }
    await Permission.mediaLibrary.request();
  }

  Future<void> loadVideoPlayer(String url) {
    _controller = VideoPlayerController.file(File(url));
    _controller.addListener(() {
      setState(() {});
    });
    return _controller.initialize();
  }

// Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _screenRecorderPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
    requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Container(
        child: Center(
            child: Column(children: [
          Row(
            children: [Text("Is recording: $_isRecording")],
          ),
          Row(
            children: [Text("URL: $_url")],
          ),
          TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 255, 0, 0),
                padding: const EdgeInsets.all(16.0),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () async {
                final bool response = await _screenRecorderPlugin
                    .startRecording(name: "example2");
                print(response);
                setState(() => _isRecording = response);
              },
              child: const Text("Start")),
          TextButton(
              onPressed: () async {
                final String response =
                    await _screenRecorderPlugin.stopRecording();
                //OpenFile.open(response);
                if (Platform.isIOS) {
                  OpenFile.open(response);
                } else {
                  await GallerySaver.saveVideo(response);

                  await Share.shareXFiles([XFile(response)],
                      text: '#GabrielRicoStudio');
                }
                // await loadVideoPlayer(response);
                // _showMyDialog();
                setState(() => _url = response);
                setState(() => _isRecording = false);
              },
              child: const Text("Stop")),
        ])),
      ),
    );
  }

  FutureBuilder<void> buildVideo() {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Si el VideoPlayerController ha finalizado la inicialización, usa
          // los datos que proporciona para limitar la relación de aspecto del VideoPlayer
          return AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            // Usa el Widget VideoPlayer para mostrar el vídeo
            child: VideoPlayer(_controller),
          );
        } else {
          // Si el VideoPlayerController todavía se está inicializando, muestra un
          // spinner de carga
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<void> _showMyDialog() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('AlertDialog Title'),
          content: Column(children: [
            if (_controller.value.isInitialized)
              AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller)),
            if (_controller.value.isInitialized)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                    child: Icon(_controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow),
                  )
                ],
              )
          ]),
          actions: <Widget>[
            TextButton(
              child: const Text('Approve'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("My title"),
          content: VideoPlayer(_controller),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {},
            ),
          ],
        );
      },
    );
  }
}
