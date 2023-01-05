import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/src/widgets/image.dart' as rex;
import 'dart:convert';
import 'package:degreecam/compare.dart';
import 'dart:ui';
import 'package:image/image.dart' as imglib;
import 'package:image/image.dart';
import  'package:image/src/image.dart';
import 'package:flutter/src/widgets/image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:degreecam/main.dart';
import 'package:http/http.dart' as http;


class StartCam extends StatefulWidget {
  const StartCam({Key? key}) : super(key: key);

  @override
  State<StartCam> createState() => _StartCamState();
}

class _StartCamState extends State<StartCam> {
  String output = 'A';

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



  Uint8List convertYUV420toImageColor(CameraImage image) {
   Uint8List realimage;
   Uint8List fakeimage = Uint8List.fromList([]);
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
      for(int x=0; x < width; x++) {
        for(int y=0; y < height; y++) {
          final int uvIndex = uvPixelStride! * (x/2).floor() + uvRowStride*(y/2).floor();
          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];
          // Calculate pixel color
          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 -vp * 93604 / 131072 + 91).round().clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
          // color: 0x FF  FF  FF  FF
          //           A   B   G   R
          img.data[index] = (0xFF << 24) | (b << 16) | (g << 8) | r;
        }
      }

      imglib.PngEncoder pngEncoder = imglib.PngEncoder(level: 0, filter: 0);
      List<int> png = pngEncoder.encodeImage(img);
      realimage = Uint8List.fromList(png);
      return realimage;
    } catch (e) {
      print(">>>>>>>>>>>> ERROR:" + e.toString());
    }
    return fakeimage;
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    loadCamera();
    loadtheModel();
  }
  var interpreter;
  CameraImage? cameraImage;
  int counter = 0;
  CameraController? cameraController;




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

  void conversion(CameraImage image, CameraImage image2){
    imglib.Image img = imglib.Image.fromBytes(22, 5566, [990]);

    imglib.Image realImg = imglib.Image.fromBytes(image.width, image.height,
        image.planes[0].bytes, format: imglib.Format.bgra);

    imglib.Image realImg2 = imglib.Image.fromBytes(image2.width, image2.height,
        image2.planes[0].bytes, format: imglib.Format.bgra);


    var diff2 = DiffImage.compareFromMemory(
      realImg,
      realImg2,
    );
    //in this line put sensitivity settings
    if(diff2.diffValue >= 0.15){
      cameraController!.stopImageStream();
      setState(() {
        output = 'Motion Detected';
      });
    }
    else{
      setState(() {
        output = 'The difference between images is: ${diff2.diffValue} %';
      });
    }

    // Calculate intersection histogram difference between two bytes of images
    print('The difference between images is: ${diff2.diffValue} %');
    print('Images Captured');
  }
  loadCamera() async{
    cameraController = CameraController(cameraDescription, ResolutionPreset.low, enableAudio: false);
    cameraController!.initialize().then((value) {
      if(!mounted){
        return;
      }
      else{
        setState(() {
          cameraController!.startImageStream((imageStream) {

            if(counter > 5){
              print('different');
              conversion(cameraImage!, imageStream);

            }
            cameraImage = imageStream;
           // runtheModel();
            counter++;
          });
        });
      }
    });
  }

  void runtheModel() async{

    if(cameraImage!=null){
      var predictions = await Tflite.runModelOnFrame(bytesList: cameraImage!.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true
      );
      for (var element in predictions!) { 
        setState(() {
          output = element['label'];
          print(output);
        });
      }
    }

    
  }
  void loadtheModel() async{
    try{
      await Tflite.loadModel(model: "assets/oldmodel.tflite", labels: "assets/oldlabels.txt");
    }
    catch(Exception){
      output = 'error';
    }

  }
  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Padding(padding: EdgeInsets.all(20),
           child: Container(
           width: MediaQuery.of(context).size.width,
           height: MediaQuery.of(context).size.height * 0.65,
           child: !cameraController!.value.isInitialized?
           Container(
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
           ):
           AspectRatio(aspectRatio: cameraController!.value.aspectRatio,
             child: CameraPreview(cameraController!),
           ),
           ),),
          Text(output,
          style: TextStyle(
            color: Colors.black,
          ),),
          ElevatedButton(onPressed: () {
            cameraController!.stopImageStream();
          }, child: const Text('Stop Streaming')),
        ],
      );
  }

  void captureImage(CameraImage image) {}
}
