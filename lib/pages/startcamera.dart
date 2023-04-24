import 'dart:async' as vx;
import 'dart:io' as io;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:degreecam/compare.dart';
import 'dart:ui';
import 'package:image/image.dart' as imglib;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:degreecam/main.dart';
import 'package:http/http.dart' as http;
import 'package:degreecam/utils.dart';
import 'package:degreecam/fpaint.dart';
import 'package:quiver/collection.dart';
import 'package:palette_generator/palette_generator.dart' as pg;
import 'package:typed_data/typed_data.dart';
import 'dart:typed_data';
import 'package:degreecam/cameramessages.dart';
import 'package:degreecam/imageconvertor.dart';
import 'package:restart_app/restart_app.dart';


class StartCam extends StatefulWidget {
  const StartCam({Key? key}) : super(key: key);

  @override
  State<StartCam> createState() => _StartCamState();
}

class _StartCamState extends State<StartCam> {
  String motionoutput = 'A';
  String objectoutput = 'B';
  String faceoutput = 'C';
  double objectconfidence = 0.0;
  double faceconfidence = 0.0;

  //color for flash button
  /**
 void cop() async{
   var assetResult = await compareImages(
       src1: image1, src2: image2, algorithm: IMED(blurRatio: 0.001));

   print('Difference: ${assetResult * 100}%');

   // Calculate intersection histogram difference between two bytes of images
   var byteResult = await compareImages(
       src1: bytes1, src2: bytes2, algorithm: IntersectionHistogram());

   print('Difference: ${byteResult * 100}%');
 }
**/

  var interpreter;
  CameraImage? cameraImage;
  int counter = 0;
  CameraController? cameraController;
  TextEditingController _labelame = TextEditingController();
  late File jsonFile;
  dynamic _scanResults;
  CameraController? _camera = CameraController(
      cameraDescription, ResolutionPreset.low,
      enableAudio: false);
  bool _isDetecting = false;
  CameraLensDirection _direction = CameraLensDirection.front;
  dynamic data = {};
  double threshold = 1.0;
  late Directory tempDir;
  late List e1 = [];
  bool _faceFound = false;
  bool constant = true;



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print('object:' + CameraMessages.object);

   if(CameraMessages.motion == 'yes'){

     if(CameraMessages.object == 'yes'){
       CameraMessages.alert_type = 'Object and Motion';
       loadObjectModel();
       loadObjectMotion();

     }
     else{
       CameraMessages.alert_type = 'Motion';
       loadMotion();
     }
   }
   else if(CameraMessages.object == 'yes'){

     if(CameraMessages.motion == 'yes'){
       CameraMessages.alert_type = 'Object and Motion';
        loadObjectModel();
        loadObjectMotion();
      }
      else{
       CameraMessages.alert_type = 'Object';
        loadObjectModel();
        loadObject();
      }
   }
   else if(CameraMessages.criminal == 'yes'){
     CameraMessages.alert_type = 'Criminal';
       loadFace();
   }
    // loadObjectModel(); to start object detection model
   // loadCamera(); //for motion and objects
     //this one is for faces
  }


  Future loadFaceModel() async {
    try {
      interpreter = await tfl.Interpreter.fromAsset('mobilefacenet.tflite');
    } on Exception {
      print('Failed to load model.');
    }
  }
  void loadFace() async {
    await loadFaceModel();

    ImageRotation rotation = rotationIntToImageRotation(
      cameraDescription.sensorOrientation,
    );

    await _camera!.initialize();
    await Future.delayed(Duration(milliseconds: 100));
    tempDir = await getApplicationDocumentsDirectory();
    String _embPath = tempDir.path + '/emb.json';
    jsonFile = new File(_embPath);
    if (jsonFile.existsSync()) data = json.decode(jsonFile.readAsStringSync());

    setState(() {
      _camera!.startImageStream((CameraImage image) {
        if(counter < 20){
          if(_camera != null) {
            checkFaceEnvironment(image);
            cameraImage = image;
          }
        }
        else if (counter > 20){

          if (_camera != null) {
            if (_isDetecting) return;
            _isDetecting = true;
            String res;
            dynamic finalResult = Multimap<String, Face>();
            detect(image, _getDetectionMethod(), rotation).then(
                  (dynamic result) async {
                if (result.length == 0)
                  _faceFound = false;
                else
                  _faceFound = true;
                Face _face;
                imglib.Image convertedImage =
                _convertCameraImage(image, _direction);
                for (_face in result) {
                  double x, y, w, h;
                  x = (_face.boundingBox.left - 10);
                  y = (_face.boundingBox.top - 10);
                  w = (_face.boundingBox.width + 10);
                  h = (_face.boundingBox.height + 10);
                  imglib.Image croppedImage = imglib.copyCrop(
                      convertedImage, x.round(), y.round(), w.round(), h.round());
                  croppedImage = imglib.copyResizeCropSquare(croppedImage, 112);
                  // int startTime = new DateTime.now().millisecondsSinceEpoch;
                  res = _recog(croppedImage);
                  if(double.parse(res.split('/').last) > 0.9){
                    faceDetectionOperator(image, cameraImage!);
                  }
                  // int endTime = new DateTime.now().millisecondsSinceEpoch;
                  // print("Inference took ${endTime - startTime}ms");
                  finalResult.add(res, _face);
                }
                setState(() {
                  _scanResults = finalResult;
                });

                _isDetecting = false;
              },
            ).catchError(
                  (_) {
                _isDetecting = false;
              },
            );
          }
        }
        print(counter);
        counter++;
      });
    });
  }



  /** Future<String> uploadPhotos(List<String> paths) async {
    Uri uri = Uri.parse('http://10.0.0.103:5000/profile/upload-mutiple');
    http.MultipartRequest request = http.MultipartRequest('POST', uri);
    for(String path in paths){
      request.files.add(await http.MultipartFile.fromPath(field, filePath));
    }

    http.StreamedResponse response = await request.send();
    var responseBytes = await response.stream.toBytes();
    var responseString = utf8.decode(responseBytes);
    print('\n\n');
    print('RESPONSE WITH HTTP');
    print(responseString);
    print('\n\n');
    return responseString;
  }
**/
  void _handle(String text) {
    data[text] = e1;
    jsonFile.writeAsStringSync(json.encode(data));
    loadFace();
  }

  HandleDetection _getDetectionMethod() {
    final faceDetector = FirebaseVision.instance.faceDetector(
      FaceDetectorOptions(
        mode: FaceDetectorMode.accurate,
      ),
    );
    return faceDetector.processImage;
  }

  imglib.Image _convertCameraImage(
      CameraImage image, CameraLensDirection _dir) {
    int width = image.width;
    int height = image.height;
    // imglib -> Image package from https://pub.dartlang.org/packages/image
    var img = imglib.Image(width, height); // Create Image buffer
    const int hexFF = 0xFF000000;
    final int uvyButtonStride = image.planes[1].bytesPerRow;
    final int? uvPixelStride = image.planes[1].bytesPerPixel;
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex = uvPixelStride! * (x / 2).floor() +
            uvyButtonStride * (y / 2).floor();
        final int index = y * width + x;
        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        // Calculate pixel color
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        // color: 0x FF  FF  FF  FF
        //           A   B   G   R
        img.data[index] = hexFF | (b << 16) | (g << 8) | r;
      }
    }
    var img1 = (_dir == CameraLensDirection.front)
        ? imglib.copyRotate(img, -90)
        : imglib.copyRotate(img, 90);
    return img1;
  }

  String _recog(imglib.Image img) {
    List input = imageToByteListFloat32(img, 112, 128, 128);
    input = input.reshape([1, 112, 112, 3]);
    List output = List.filled(1 * 192, null, growable: false).reshape([1, 192]);
    interpreter.run(input, output);
    output = output.reshape([192]);
    e1 = List.from(output);
    return compare(e1).toUpperCase();
  }

  String compare(List currEmb) {
    print('ruunnig');
    if (data.length == 0) return "No Face saved";
    double minDist = 999;
    double currDist = 0.0;
    String predRes = "NOT RECOGNIZED";
    for (String label in data.keys) {
      currDist = euclideanDistance(data[label], currEmb);
      if (currDist <= threshold && currDist < minDist) {
        minDist = currDist;
        predRes = label;
      }
    }
    setState(() {
      faceoutput = predRes;
      faceconfidence = minDist;
    });
    print(minDist.toString() + "//. " + predRes);
    return '$predRes/$minDist';
  }
  void _resetFile() {
    data = {};
    jsonFile.deleteSync();
  }

  void _viewLabels() {
    setState(() {
      _camera = null;
    });
    String name;
    var alert = new AlertDialog(
      title: new Text("Saved Faces"),
      content: new ListView.builder(
          padding: new EdgeInsets.all(2),
          itemCount: data.length,
          itemBuilder: (BuildContext context, int index) {
            name = data.keys.elementAt(index);
            return new Column(
              children: <Widget>[
                new ListTile(
                  title: new Text(
                    name,
                    style: new TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                new Padding(
                  padding: EdgeInsets.all(2),
                ),
                new Divider(),
              ],
            );
          }),
      actions: <Widget>[
        new FlatButton(
          child: Text("OK"),
          onPressed: () {
            loadFace();
            Navigator.pop(context);

          },
        )
      ],
    );
    showDialog(
        context: context,
        builder: (context) {
          return alert;
        });
  }

  void _addLabel() {
    setState(() {
      _camera = null;
    });
    print("Adding new face");
    var alert = AlertDialog(
      title: Text("Add Face"),
      content: new Row(
        children: <Widget>[
          new Expanded(
            child: new TextField(
              controller: _labelame,
              autofocus: true,
              decoration: new InputDecoration(
                  labelText: "Name", icon: new Icon(Icons.face)),
            ),
          )
        ],
      ),
      actions: <Widget>[
        new FlatButton(
            child: Text("Save"),
            onPressed: () {
              _handle(_labelame.text.toUpperCase());
              _labelame.clear();
              Navigator.pop(context);
              loadFace();
            }),
        new FlatButton(
          child: Text("Cancel"),
          onPressed: () {

            Navigator.pop(context);
            loadFace();
          },
        )
      ],
    );
    showDialog(
        context: context,
        builder: (context) {
          return alert;
        });
  }

  void checkEnvironment(CameraImage image){

    imglib.Image realImg = imglib.Image.fromBytes(
        image.width, image.height, image.planes[0].bytes,
        format: imglib.Format.bgra);

    final bytesList = realImg.data;
    final colorList = bytesList.map<Color>((e) => Color(e)).toList();//Map the decoded data to colors
    //Change format to a 2d list of colors so that they can be accessed as colorGrid[x][y]
    final Color color1 = colorList.first;
    var grayscale = (0.299 * color1.red) + (0.587 * color1.green) + (0.114 * color1.blue);

    if(grayscale > 128){
      print('LIGHT');

    }else{
      print('DARK');
      cameraController!.setFlashMode(FlashMode.torch);
    }
  }
  void checkFaceEnvironment(CameraImage image){

    imglib.Image realImg = imglib.Image.fromBytes(
        image.width, image.height, image.planes[0].bytes,
        format: imglib.Format.bgra);

    final bytesList = realImg.data;
    final colorList = bytesList.map<Color>((e) => Color(e)).toList();//Map the decoded data to colors
    //Change format to a 2d list of colors so that they can be accessed as colorGrid[x][y]
    final Color color1 = colorList.first;
    var grayscale = (0.299 * color1.red) + (0.587 * color1.green) + (0.114 * color1.blue);

    if(grayscale > 128){
      print('LIGHT');

    }else{
      print('DARK');
      _camera!.setFlashMode(FlashMode.torch);
    }
  }
  /**
  Upload(File imageFile) async {
    var stream = new http.ByteStream(vx.DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();

    var uri = Uri.parse(uploadURL);

    var request = new http.MultipartRequest("POST", uri);
    var multipartFile = new http.MultipartFile('file', stream, length,
        filename: basename(imageFile.path));
    //contentType: new MediaType('image', 'png'));

    request.files.add(multipartFile);
    var response = await request.send();
    print(response.statusCode);
    response.stream.transform(utf8.decoder).listen((value) {
      print(value);
    });
  }

  void uploadImages(imglib.Image imageFile, imglib.Image imageFiletwo) async {
    String tempPath = (await getApplicationDocumentsDirectory()).path;
    String currentimage = DateTime.now().toString() + '.png';
    File file = File('$tempPath/$currentimage');
    Stream<List<int>> streamy = file.openRead();
    var stream = http.ByteStream(streamy);

    var length =  imageFile.length;

    var uri = Uri.parse(uploadURL);

    var request = new http.MultipartRequest("POST", uri);
    var multipartFile = http.MultipartFile('file', stream, length);
    var multi_two = http.MultipartFile();

    //contentType: new MediaType('image', 'png'));

    request.files.add(multipartFile);
    var response = await request.send();
    print(response.statusCode);
    response.stream.transform(utf8.decoder).listen((value) {
      print(value);
    });
  }
  **/

  Future<Uint8List?> convertYUV420toImageColor(CameraImage image) async {

    const shift = (0xFF << 24);
    try {
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int? uvPixelStride = image.planes[1].bytesPerPixel;

      print("uvRowStride: " + uvRowStride.toString());
      print("uvPixelStride: " + uvPixelStride.toString());

      // imgLib -> Image package from https://pub.dartlang.org/packages/image
      var img = imglib.Image(width, height); // Create Image buffer

      // Fill image buffer with plane[0] from YUV420_888
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          final int uvIndex = uvPixelStride! * (x / 2).floor() + uvRowStride * (y / 2).floor();
          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];
          // Calculate pixel color
          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
          // color: 0x FF  FF  FF  FF
          //           A   B   G   R
          img.data[index] = shift | (b << 16) | (g << 8) | r;
        }
      }
      img = imglib.copyRotate(img, 90);
      imglib.PngEncoder pngEncoder = new imglib.PngEncoder(level: 0, filter: 0);
      List<int> png = pngEncoder.encodeImage(img);
      Uint8List byte = Uint8List.fromList(png);
      print('your bytes' + byte.toString());
      return byte;
    } catch (e) {
      print(">>>>>>>>>>>> ERROR:" + e.toString());
    }
    return null;
  }
  Future<void> myAsyncMethod(BuildContext context) async {
    Navigator.of(context).push(
        MaterialPageRoute(
            builder: (BuildContext context){
              return const MyApp();
            }
        )
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  }
  void faceDetectionOperator(CameraImage image, CameraImage image2) {

    //in this line put sensitivity settings

    _camera!.stopImageStream();
    _camera!.setFlashMode(FlashMode.off);

    setState(() async {

      Uint8List? imagelistone = await convertYUV420toImageColor(image);
      Uint8List? imagelisttwo = await convertYUV420toImageColor(image2);


      File firtsimage = await ImageConvertor.imageToFile(imagelistone!);
      File secondimage = await ImageConvertor.imageToFile(imagelisttwo!);

      await ImageConvertor.lastUpload(firtsimage, secondimage).then((value) {
        print('lastly');
      });


      Map<dynamic  , dynamic> connection = {};
      connection['connection'] = 'plus';
      connection['door'] = 'locked';
      await CameraMessages.databaseReference.set({
        "message": connection,
      }).whenComplete(() => print("success")
      );
      await AssetsAudioPlayer.newPlayer().open(
          Audio("assets/audios/newalert.mp3"),
          showNotification: true,
          volume: 100
      );
      await Restart.restartApp();
    });

  }
  void objectDetectionOperator(CameraImage image, CameraImage image2) {

    //in this line put sensitivity settings

      cameraController!.stopImageStream();
      cameraController!.setFlashMode(FlashMode.off);

      setState(() async {

        Uint8List? imagelistone = await convertYUV420toImageColor(image);
        Uint8List? imagelisttwo = await convertYUV420toImageColor(image2);


        File firtsimage = await ImageConvertor.imageToFile(imagelistone!);
        File secondimage = await ImageConvertor.imageToFile(imagelisttwo!);

        await ImageConvertor.lastUpload(firtsimage, secondimage).then((value) {
          print('lastly');
        });


        Map<dynamic  , dynamic> connection = {};
        connection['connection'] = 'plus';
        connection['door'] = 'locked';
        await CameraMessages.databaseReference.set({
          "message": connection,
        }).whenComplete(() {print("success");
        }
        );
        await AssetsAudioPlayer.newPlayer().open(
            Audio("assets/audios/newalert.mp3"),
            showNotification: true,
            volume: 100
        );
        await Restart.restartApp();
      });

  }
  void motionDetectionOperator(CameraImage image, CameraImage image2) {



    imglib.Image realImg = imglib.Image.fromBytes(
        image.width, image.height, image.planes[0].bytes,
        format: imglib.Format.bgra);

    imglib.Image realImg2 = imglib.Image.fromBytes(
        image2.width, image2.height, image2.planes[0].bytes,
        format: imglib.Format.bgra);

    var diff2 = DiffImage.compareFromMemory(
      realImg,
      realImg2,
    );
    //in this line put sensitivity settings
    if (diff2.diffValue >= 0.9) {
      cameraController!.stopImageStream();
      cameraController!.setFlashMode(FlashMode.off);
      setState(() {

        constant = false;

        motionoutput = 'Detected';
      });


      setState(() async {

        motionoutput = 'The difference between images is: ${diff2.diffValue} %';
        Uint8List? imagelistone = await convertYUV420toImageColor(image);
        Uint8List? imagelisttwo = await convertYUV420toImageColor(image2);


        File firtsimage = await ImageConvertor.imageToFile(imagelistone!);
        File secondimage = await ImageConvertor.imageToFile(imagelisttwo!);

        await ImageConvertor.lastUpload(firtsimage, secondimage).then((value) {
          print('lastly');
        });

        Map<dynamic  , dynamic> connection = {};
        connection['connection'] = 'plus';
        connection['door'] = 'locked';
        await CameraMessages.databaseReference.set({
          "message": connection,
        }).whenComplete(() { print("success");

        }

        );
        await AssetsAudioPlayer.newPlayer().open(
            Audio("assets/audios/newalert.mp3"),
            showNotification: true,
            volume: 100
        );
       await Restart.restartApp();
      });
    } else {
      setState(() {
        motionoutput = 'The difference between images is: ${diff2.diffValue} %';
      });
    }
  }

  loadMotion() async {
    cameraController = CameraController(cameraDescription, ResolutionPreset.low,
        enableAudio: false);

    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      } else {
       // cameraController!.setFlashMode(FlashMode.torch);
        setState(() {
          cameraController!.startImageStream((imageStream) {
            if(counter < 35){
              print('executed');
              checkEnvironment(imageStream);
              cameraImage = imageStream;

            }
            else if (counter > 35) {
              print('different');
              motionDetectionOperator(imageStream, cameraImage!);
              cameraImage = imageStream;
            }
            print(counter);
            counter++;
          });
        });
      }
    });
  }
  loadObject() async {
    cameraController = CameraController(cameraDescription, ResolutionPreset.low,
        enableAudio: false);

    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      } else {
        // cameraController!.setFlashMode(FlashMode.torch);
        setState(() {
          cameraController!.startImageStream((imageStream) {
            if(counter < 25){
              print('executed');
              checkEnvironment(imageStream);
              cameraImage = imageStream;
            }
            else if (counter > 25) {
              print('different');
              runObjectModel(imageStream, cameraImage!);
              cameraImage = imageStream;
            }
            print(counter);
            counter++;
          });
        });
      }
    });
  }
  Widget processor(BuildContext context) {
    myAsyncMethod(context);
    return Text('Hi');
  }
  loadObjectMotion() async {
    cameraController = CameraController(cameraDescription, ResolutionPreset.low,
        enableAudio: false);

    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      } else {
        setState(() {
          cameraController!.startImageStream((imageStream) {
            if(counter < 25){
              print('executed');
              checkEnvironment(imageStream);
              cameraImage = imageStream;
            }
            else if (counter > 25) {
              print('different');
              motionDetectionOperator(imageStream, cameraImage!);
              runObjectModel(imageStream, cameraImage!);
              cameraImage = imageStream;
               //objects
            }
            print(counter);
            counter++;
          });
        });
      }
    });
  }

  void runObjectModel(CameraImage imgone, CameraImage imgtwo) async {


    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
          bytesList: cameraImage!.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: cameraImage!.height,
          imageWidth: cameraImage!.width,
          imageMean: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
          asynch: true);
      for (var element in predictions!) {
        setState(() {
          objectoutput = element['label'];
          objectconfidence = element['confidence'];

          if((objectconfidence >= 0.9 && objectoutput == 'guns') || (objectconfidence >= 0.9 && objectoutput == 'guns')){
            objectDetectionOperator(imgone, imgtwo);
          }

          print(objectoutput);
        });
      }
    }
  }

  void loadObjectModel() async {
    try {
      await Tflite.loadModel(
          model: "assets/realmodel.tflite", labels: "assets/reallabels.txt");
    } catch (Exception) {
      objectoutput = 'error';
    }
  }




  Widget _buildCameraContainer() {
    if (_camera == null || !_camera!.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      constraints: const BoxConstraints.expand(),
      child: _camera == null
          ? const Center(child: null)
          : Container(
             width: MediaQuery.of(context).size.width,
             height: MediaQuery.of(context).size.height * 0.65,
             child: Column(
               children: [
                 CameraPreview(_camera!),
                 _buildResults(),
                 Text(faceoutput),
                 Text(faceconfidence.toString()),
               ],
             ),
            ),
    );
  }

  Widget _buildResults() {
    const Text noResultsText = const Text('');
    if (_scanResults == null ||
        _camera == null ||
        _camera!.value.isInitialized) {
      return noResultsText;
    }
    CustomPainter painter;

    final Size imageSize = Size(
      _camera!.value.previewSize!.height,
      _camera!.value.previewSize!.width,
    );
    painter = FaceDetectorPainter(imageSize, _scanResults);
    return CustomPaint(
      painter: painter,
    );
  }

  Widget faceMode() {
    return Scaffold(

      appBar: AppBar(
        actions: <Widget>[
          PopupMenuButton<Choice>(
            onSelected: (Choice result) {
              if (result == Choice.delete)
                _resetFile();
              else
                _viewLabels();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Choice>>[
              const PopupMenuItem<Choice>(
                child: Text('View Saved Faces'),
                value: Choice.view,
              ),
              const PopupMenuItem<Choice>(
                child: Text('Remove all faces'),
                value: Choice.delete,
              )
            ],
          ),
        ],
      ),
      body: _buildCameraContainer(),
      floatingActionButton:
      Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
          backgroundColor: (_faceFound) ? Colors.blue : Colors.blueGrey,
          child: Icon(Icons.add),
          onPressed: () {
            if (_faceFound) _addLabel();
          },
          heroTag: null,
        ),
        SizedBox(
          height: 10,
        ),
      ]),
    );
  }
  Widget normalMode() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.65,
            child: !cameraController!.value.isInitialized
                ? Container(
              child: Center(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Still Loading',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 30.0,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Hold up for a sec',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 25.0,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: <Widget>[
                          SpinKitPouringHourGlass(
                            color: Colors.blue,
                            size: 100.0,
                          ),
                          Text(
                            'Waiting for Connection',
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
            )
                : AspectRatio(
              aspectRatio: cameraController!.value.aspectRatio,
              child: CameraPreview(cameraController!),
            ),
          ),
        ),
        Text(
          objectoutput,
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        Text(
          objectconfidence.toString(),
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        Text(
          motionoutput,
          style: TextStyle(
            color: Colors.black,
          ),
        ),

      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return CameraMessages.facemode? faceMode(): normalMode();
  }
}


/// Stores RGBA values
class Color {
  final int alpha, blue, green, red;

  Color(int abgr)
      :
        alpha = abgr >> 24 & 0xFF,
        blue = abgr >> 16 & 0xFF,
        green = abgr >> 8 & 0xFF,
        red = abgr & 0xFF;

  @override
  String toString() {
    return 'R: $red, G: $green, B: $blue, A: $alpha';
  }
}