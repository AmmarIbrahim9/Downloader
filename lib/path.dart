// import 'dart:io';
//
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:http/http.dart' as http;
//
//
// Future<void> _downloadVideo(String url) async {
//   var status = await Permission.storage.status;
//   if (!status.isGranted) {
//     await Permission.storage.request();
//   }
//
//   if (await Permission.storage.isGranted) {
//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final directory = await getExternalStorageDirectory();
//         final downloadsDirectory = Directory('${directory?.parent?.parent?.parent?.parent?.path}/Download');
//         if (!(await downloadsDirectory.exists())) {
//           await downloadsDirectory.create(recursive: true);
//         }
//         final file = File('${downloadsDirectory.path}/video.mp4');
//         await file.writeAsBytes(response.bodyBytes);
//         setState(() {
//           _status = 'Download successful! File saved to ${file.path}';
//         });
//       } else {
//         setState(() {
//           _status = 'Failed to download video.';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _status = 'Error: $e';
//       });
//     }
//   } else {
//     setState(() {
//       _status = 'Storage permission denied.';
//     });
//   }
// }
