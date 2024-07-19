import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.red[900],
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  String _status = '';
  List<yt.StreamInfo> _videoStreams = [];
  yt.StreamInfo? _selectedStream;

  Future<void> _fetchVideoStreams(String url) async {
    setState(() {
      _status = 'Fetching video streams...';
      _videoStreams.clear();
      _selectedStream = null;
    });

    var client = yt.YoutubeExplode();
    try {
      var video = await client.videos.get(url);
      var manifest = await client.videos.streamsClient.getManifest(video.id);

      _videoStreams.addAll(manifest.muxed);
      _videoStreams.addAll(manifest.audioOnly);

      setState(() {
        _status = 'Video streams fetched successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      client.close();
    }
  }

  Future<void> _downloadVideo(String url) async {
    setState(() {
      _status = 'Downloading video...';
    });

    try {
      var response = await _fetchWithRetry(url, retries: 3);

      if (response.statusCode == 200) {
        var downloadsDir = await DownloadsPath.downloadsDirectory();
        if (downloadsDir == null) {
          throw 'Downloads directory not available';
        }

        var fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        var filePath = '${downloadsDir.path}/$fileName';

        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _status = 'Download successful! File saved to $filePath';
        });
      } else {
        setState(() {
          _status = 'Failed to download video. Server responded with status code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<http.Response> _fetchWithRetry(String url, {int retries = 3}) async {
    int attempt = 0;
    while (attempt < retries) {
      try {
        attempt++;
        var response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 30));
        return response;
      } catch (e) {
        if (attempt >= retries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2));
      }
    }
    throw Exception('Failed to fetch data after $retries attempts');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'YouTube Video Downloader',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.red[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        constraints: BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'asset/logo.png',
                height: 100,
              ),
              SizedBox(height: 20),
              Text(
                'Enter YouTube URL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library,
                    size: 28,
                    color: Colors.red[900],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: 'Enter YouTube Video URL',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _status = 'Fetching video streams...';
                  });
                  await _fetchVideoStreams(_controller.text);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red[900],
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text('Get Video'),
              ),
              SizedBox(height: 20),
              if (_videoStreams.isNotEmpty)
                DropdownButton<yt.StreamInfo>(
                  value: _selectedStream,
                  onChanged: (yt.StreamInfo? newValue) {
                    setState(() {
                      _selectedStream = newValue;
                    });
                  },
                  style: TextStyle(color: Colors.black87),
                  elevation: 3,
                  icon: Icon(Icons.arrow_drop_down),
                  underline: Container(
                    height: 2,
                    color: Colors.red[900],
                  ),
                  items: _videoStreams.map((yt.StreamInfo stream) {
                    return DropdownMenuItem<yt.StreamInfo>(
                      value: stream,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          stream is yt.AudioOnlyStreamInfo
                              ? 'Audio (${stream.audioCodec})'
                              : (stream is yt.VideoStreamInfo
                              ? 'Video (${stream.videoResolution.height}p)'
                              : 'Unknown'),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectedStream != null
                    ? () => _downloadVideo(_selectedStream!.url.toString())
                    : null,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red[900],
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text('Download'),
              ),
              SizedBox(height: 20),
              Text(
                _status,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
