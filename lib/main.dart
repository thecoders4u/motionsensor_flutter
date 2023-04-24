import 'package:degreecam/cameramessages.dart';
import 'package:degreecam/pageconfig.dart';
import 'package:degreecam/pages/home.dart';
import 'package:degreecam/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:degreecam/pages/startcamera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:camera/camera.dart';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

late CameraDescription cameraDescription;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await availableCameras().then((cameras) {
    final camera = cameras
        .where((camera) => camera.lensDirection == CameraLensDirection.back)
        .toList()
        .first;
    cameraDescription = camera;
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /**  startModel() async {
    await Tflite.loadModel(
      model: "assets/mobilenet_v1_1.0_224.tflite",
      labels: "assets/mobilenet_v1_1.0_224.txt",
    );
  }
**/
  static late String currentPage = 'a';
  late bool facemode = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initiateFirebase();
    downloadFaces();
    //doSomething();
    /**

        **/
  }


  Future<void> downloadFaces() async {
    String tempPath = (await getApplicationDocumentsDirectory()).path;
    File file = File('$tempPath/emb.json');
    await http.get(Services.SECOND).then((response) {
      String faces = response.body;
      print('faces:' + faces);
      file.writeAsStringSync(faces);
    });
  }

  Future<void> initiateFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).whenComplete(() {
      setState(() {
        CameraMessages.databaseReference = FirebaseDatabase.instance.ref("messages/2022");
        CameraMessages.databaseReference.onValue.listen((DatabaseEvent event) {
          final data = event.snapshot.value;
          print(data);

          final json = data as Map;
          setState(() {

            CameraMessages.status = json['message']['connection'];
            CameraMessages.criminal = json['message']['criminal'];
            CameraMessages.object = json['message']['object'];
            CameraMessages.motion = json['message']['motion'];
            CameraMessages.customer_phone = json['message']['customer_phone'];
            CameraMessages.customer_name = json['message']['customer_name'];
            CameraMessages.customer_id = json['message']['customer_id'];
            if(CameraMessages.criminal == 'yes'){
              CameraMessages.facemode = true;
            }
          });
        });
      });
    });
  }

  Widget _allPages() {
    if (CameraMessages.status == 'connected') {
      return const StartCam();
    }
    else{
      return Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Waiting for connection',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 30.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: const <Widget>[
                SpinKitPianoWave(
                  color: Colors.blue,
                  size: 100.0,
                ),
                Text(
                  'This is because either you have no connection to the camera or you have ended the session',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 25.0,
                  ),
                )
              ],
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: Text('G4S Cam'),
        titleTextStyle: TextStyle(color: Colors.white),
      ),
      body: _allPages(),
    );
  }
}
