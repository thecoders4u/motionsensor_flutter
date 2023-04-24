import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:degreecam/cameramessages.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import 'services.dart';
import 'package:dio/dio.dart' as newdio;
import 'package:image/image.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'dart:io';
import 'package:http/src/response.dart';


class CustomRequest {
  static final dio = newdio.Dio();
}
class ImageConvertor {


  static Future<File> imageToFile(Uint8List bytes) async {
    String tempPath = (await getApplicationDocumentsDirectory()).path;
    DateTime dt = new DateTime.now();
    String year = dt.year.toString();
    String month = dt.month.toString();
    String day = dt.day.toString();
    String hour = dt.hour.toString();
    String min = dt.minute.toString();
    String sec = dt.second.toString();

    String fullData = '$year-$month-$day-$hour-$min-$sec';
    String currentimage = '$fullData.png';
    File file = File('$tempPath/$currentimage');
    await file.writeAsBytes(
        bytes
    );
    return file;
  }

  static Future<void> doImage() async {
    String tempjson = (await getApplicationDocumentsDirectory()).path;
    File jsonfile = File('$tempjson/emb.json');
    String data = jsonfile.readAsStringSync();

    String tempPath = (await getApplicationDocumentsDirectory()).path;
    String currentimage = DateTime.now().toString() + '.jpg';
    File file = File('$tempPath/emb.json');

    await http.get(Services.SECOND).then((response) {
      Uint8List bodyBytes = response.bodyBytes;
      print('byea' + bodyBytes.toString());
      file.writeAsBytes(bodyBytes);
    });
  }
  static Future<void> lastUpload(File file, File filetwo) async{
    int imgNo = Random().nextInt(500000);
    int alertNo = Random().nextInt(800000);


    final request = http.MultipartRequest('POST', Uri.parse('https://the5miles.com/upload.php'));
    String customer = CameraMessages.customer_id;
    String firstarray = file.path.split('/').last;
    String year = firstarray.split('-')[0];
    String month = firstarray.split('-')[1];
    String day = firstarray.split('-')[2];
    String hour = firstarray.split('-')[3];
    String mins = firstarray.split('-')[4];
    String tempSec = firstarray.split('-')[5];

    String sec = tempSec.split('.').first;

    String timeone = '$hour:$mins:$sec';
    String dateone =  '$year-$month-$day';

    String secondarray = filetwo.path.split('/').last;
    String year_two = secondarray.split('-')[0];
    String month_two = secondarray.split('-')[1];
    String day_two = secondarray.split('-')[2];
    String hour_two = secondarray.split('-')[3];
    String mins_two = secondarray.split('-')[4];
    String tempSec_two = secondarray.split('-')[5];

    String sec_two = tempSec_two.split('.').first;

    String timeone_two = '$hour_two:$mins_two:$sec_two';
    String dateone_two =  '$year_two-$month_two-$day_two';


    String tempName = filetwo.path.split('/').last;
    String customfileName = '${tempName.split('.').first}_${customer}_second.png';



    String tempNameA = file.path.split('/').last;
    String customfileNameA = '${tempNameA.split('.').first}_$customer.png';

    request.fields['action'] = 'IMAGE_SAVING';
    request.fields['name'] = customfileNameA;
    request.fields['name_two'] = customfileName;
    request.fields['customer_name'] = CameraMessages.customer_name;
    request.fields['customer_id'] = CameraMessages.customer_id;
    request.fields['customer_phone'] = CameraMessages.customer_phone;
    request.fields['alert_type'] = CameraMessages.alert_type;

    request.fields['image_no'] = imgNo.toString();
    request.fields['alert_no'] = alertNo.toString();

    request.fields['date_one'] = dateone;
    request.fields['date_two'] = dateone_two;
    request.fields['time_one'] = timeone;
    request.fields['time_two'] = timeone_two;



    print('processing');
   // Uint8List bytes = await file.readAsBytes();

   /** newdio.FormData formData = newdio.FormData.fromMap({
    "image": newdio.MultipartFile.fromFileSync(file.path)
    });
       **/
    /**
    newdio.FormData formdata = newdio.FormData.fromMap({

      "file": await newdio.MultipartFile.fromFile(
          file.path,
          filename: basename(file.path)
        //show only filename from path
      ),
    });
        **/
    /** var response = await newdio.Dio().postUri(Uri.parse('http://192.168.148.213/motionsensor/upload.php'), data: formData);
    if(response.statusCode == 200){
      print(response.data);
    }
    **/

    request.files.add(await http.MultipartFile.fromPath("file", file.path, filename: file.path.split('/').last, contentType: MediaType('image', 'png')));
    request.files.add(await http.MultipartFile.fromPath("filetwo", filetwo.path, filename: customfileName, contentType: MediaType('image', 'png')));

    final response = await request.send();
    if(response.statusCode == 200){
      final respStr = await response.stream.bytesToString();
      print(respStr);
    }
    else{
      print(response.statusCode);
    }
    /**

    var response = await newdio.Dio().postUri(Uri.parse('http://192.168.148.213/motionsensor/upload.php'),
      data: formdata
    );

    if(response.statusCode == 200){
      print(response.toString());
      //print response from server
    }else{
      print("Error during connection to server.");
    }
    **/
  }

/**
    static Future<void> uploadImages(File imageFile, File imageFile2) async {

    Stream<List<int>> streamy = imageFile.openRead();
    Stream<List<int>> streamy2 = imageFile2.openRead();


    var stream = http.ByteStream(streamy);
    var stream2 = http.ByteStream(streamy2);

    var length = await imageFile.length();
    var length2 = await imageFile2.length();

    var uri = Uri.parse('https://the5miles.com/detections');

    var request = new http.MultipartRequest("POST", uri);
    var multipartFile = new http.MultipartFile('file', stream, length,
    filename: basename(imageFile.path), contentType: MediaType('image', 'png'));
    //contentType: new MediaType('image', 'png'));
    var multipartFile2 = new http.MultipartFile('file', stream2, length2,
    filename: basename(imageFile2.path), contentType: MediaType('image', 'png'));

    request.files.add(multipartFile);
    request.files.add(multipartFile2);

    var response = await request.send();
    print(response.statusCode);
    response.stream.transform(utf8.decoder).listen((value) {
    print(value);
    });
    }
 **/

}