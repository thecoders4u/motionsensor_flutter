import 'package:degreecam/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:degreecam/pages/startcamera.dart';
import 'firebase_options.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:camera/camera.dart';

late CameraDescription cameraDescription;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await availableCameras().then((cameras) {
    final camera = cameras.where((camera) => camera.lensDirection == CameraLensDirection.back).toList().first;
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
      home: const MyHomePage(),
    );
  }
}
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
 Future<void> doSomething() async{
   String url = 'https://the5miles.com/faces.json';
   final file = await DefaultCacheManager().getSingleFile(url);
   var content = await file.readAsString();
   print('Content:$content');
 }
 startModel() async{
   await Tflite.loadModel(
     model: "assets/mobilenet_v1_1.0_224.tflite",
     labels: "assets/mobilenet_v1_1.0_224.txt",
   );
 }

  static late String currentPage = 'a';
  late DatabaseReference _databaseReference;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    doSomething();
    initiateFirebase();

  }


  Future<void> initiateFirebase() async{
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).whenComplete(() {
      setState(() {
        _databaseReference = FirebaseDatabase.instance.ref("messages/2022");
        _databaseReference.onValue.listen((DatabaseEvent event) {
          final data = event.snapshot.value;
          print(data);

          final json = data as Map;
          setState(() {
            currentPage = json['message'] as String;
            print(currentPage);
          });

        });

      });
    });
  }
  Widget _allPages(){
   if(currentPage == 'Changed'){
     return Container(
       child: Center(
         child: Column(
           children: <Widget>[
             Padding(
               padding: EdgeInsets.all(20.0),
               child: Text(
                 currentPage,
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
                     'Finalizing',
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
         ),
       ),
     );
   }
   else{
       return StartCam();
   }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: Text(
            'G4S Cam'
        ),
        titleTextStyle: TextStyle(
            color: Colors.white
        ),
      ),
      body: _allPages(),
    );
  }
}


