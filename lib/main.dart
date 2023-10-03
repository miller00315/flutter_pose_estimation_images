import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyHomePage());
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ImagePicker imagePicker;
  File? _image;
  String result = '';

  late PoseDetectorOptions options;

  late PoseDetector poseDetector;

  ui.Image? image;

  List<Pose>? poses;

  //TODO declare detector

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();

    options = PoseDetectorOptions(mode: PoseDetectionMode.single);

    poseDetector = PoseDetector(options: options);
  }

  @override
  void dispose() async {
    poseDetector.close();
    super.dispose();
  }

  //TODO capture image using camera
  _imgFromCamera() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      doPoseDetection();
    }
  }

  //TODO choose image using gallery
  _imgFromGallery() {
    imagePicker.pickImage(source: ImageSource.gallery).then((value) {
      XFile? pickedFile = value;

      if (pickedFile != null) {
        _image = File(pickedFile.path);
        doPoseDetection();
      }
    });
  }

  doPoseDetection() async {
    setState(() {
      _image;
    });

    if (_image != null) {
      final InputImage inputImage = InputImage.fromFile(_image!);

      poses = await poseDetector.processImage(inputImage);
    }

    drawPose();
  }

  // //TODO draw pose
  drawPose() async {
    final imageArray = await _image?.readAsBytes();

    if (imageArray != null) {
      image = await decodeImageFromList(imageArray);
    }

    setState(() {
      image;
      poses;
      result;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      home: Scaffold(
          body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('images/bg.jpg'), fit: BoxFit.cover),
        ),
        child: Column(
          children: [
            const SizedBox(
              width: 100,
            ),
            Container(
              margin: const EdgeInsets.only(top: 100),
              child: Stack(children: <Widget>[
                Center(
                  child: ElevatedButton(
                    onPressed: _imgFromGallery,
                    onLongPress: _imgFromCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: Container(
                        child: image != null
                            ? Center(
                                child: FittedBox(
                                  child: SizedBox(
                                    width: image!.width.toDouble(),
                                    height: image!.height.toDouble(),
                                    child: poses != null
                                        ? CustomPaint(
                                            painter: PosePainter(poses!, image),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.indigo,
                                width: 350,
                                height: 350,
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 53,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      )),
    );
  }
}

class PosePainter extends CustomPainter {
  PosePainter(this.poses, this.imageFile);

  final List<Pose> poses;

  ui.Image? imageFile;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile!, Offset.zero, Paint());
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.yellow;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.blueAccent;

    for (final pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(Offset(landmark.x, landmark.y), 1, paint);
      });

      void paintLine(
          PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType) {
        final PoseLandmark joint1 = pose.landmarks[type1]!;
        final PoseLandmark joint2 = pose.landmarks[type2]!;
        canvas.drawLine(
            Offset(joint1.x, joint1.y), Offset(joint2.x, joint2.y), paintType);
      }

      //Draw arms
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint);
      paintLine(
          PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow,
          rightPaint);
      paintLine(
          PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint);

      //Draw Body
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip,
          rightPaint);

      //Draw legs
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
      paintLine(
          PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint);
      paintLine(
          PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint);
      paintLine(
          PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses;
  }
}
