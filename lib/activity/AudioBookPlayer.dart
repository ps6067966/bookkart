import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/utils/Colors.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:flutterapp/utils/app_widget.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:rxdart/rxdart.dart';

import '../main.dart';

class AudioBookPlayer extends StatefulWidget {
  final String? url;
  final String? bookName;
  final String? bookImage;

  AudioBookPlayer({Key? key, required this.url, this.bookImage, this.bookName}) : super(key: key);

  @override
  _AudioBookPlayerState createState() => _AudioBookPlayerState(url);
}

class _AudioBookPlayerState extends State<AudioBookPlayer> with WidgetsBindingObserver {
  String? url;
  //late AudioPlayer _audioPlayer;

  _AudioBookPlayerState(this.url);

  @override
  void initState() {
    super.initState();
   // _audioPlayer = AudioPlayer();
    _initAudioPlayer();
    WidgetsBinding.instance!.addObserver(this);
  }

  _initAudioPlayer() async {
  //  await _audioPlayer.setUrl(url!);
  //_audioPlayer.play();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
  //  _audioPlayer.dispose();
    super.dispose();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStore.scaffoldBackground,
      appBar: appBar(context, title: widget.bookName) as PreferredSizeWidget?,
      body: Container(
        padding: EdgeInsets.only(top: 20),
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 220,
              height: 308,
              child: Stack(
                children: <Widget>[
                  Card(
                    semanticContainer: true,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: CachedNetworkImage(
                      placeholder: (context, url) => Center(
                        child: Container(width: 220, height: 308, child: bookLoaderWidget),
                      ),
                      imageUrl: widget.bookImage!,
                      fit: BoxFit.fill,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    elevation: 5,
                    margin: EdgeInsets.all(10),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                top: spacing_standard_new,
              ),
              padding: EdgeInsets.only(left: spacing_standard, right: spacing_standard),
              child: Text(
                widget.bookName!,
                style: TextStyle(
                  fontSize: fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: appStore.appTextPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // StreamBuilder<PlayerState>(
            // //  stream: _audioPlayer.playerStateStream,
            //   builder: (context, snapshot) {
            //     final playerState = snapshot.data;
            //     final processingState = playerState?.processingState;
            //     final playing = playerState?.playing;
            //     if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
            //       return Container(
            //         margin: EdgeInsets.only(top: 20),
            //         child: CircularProgressIndicator(),
            //       );
            //     } else if (playing != true) {
            //       return Container(
            //         margin: EdgeInsets.only(top: 20),
            //         width: 60.0,
            //         height: 60.0,
            //         decoration: new BoxDecoration(
            //             shape: BoxShape.circle,
            //             gradient: LinearGradient(
            //               begin: Alignment(6.123234262925839e-17, 1),
            //               end: Alignment(-1, 6.123234262925839e-17),
            //               colors: [Color.fromRGBO(185, 205, 254, 1), Color.fromRGBO(182, 178, 255, 1)],
            //             )),
            //         child: Center(
            //           child: IconButton(
            //             key: Key('play_button'),
            //             onPressed: _audioPlayer.play,
            //             iconSize: 42.0,
            //             icon: Icon(Icons.play_arrow),
            //             color: primaryColor,
            //           ),
            //         ),
            //       );
            //     } else if (processingState != ProcessingState.completed) {
            //       return Container(
            //         margin: EdgeInsets.only(top: 20),
            //         width: 60.0,
            //         height: 60.0,
            //         decoration: new BoxDecoration(
            //             shape: BoxShape.circle,
            //             gradient: LinearGradient(
            //               begin: Alignment(6.123234262925839e-17, 1),
            //               end: Alignment(-1, 6.123234262925839e-17),
            //               colors: [Color.fromRGBO(185, 205, 254, 1), Color.fromRGBO(182, 178, 255, 1)],
            //             )),
            //         child: IconButton(
            //           key: Key('pause_button'),
            //           onPressed: _audioPlayer.pause,
            //           iconSize: 42.0,
            //           icon: Icon(Icons.pause),
            //           color: primaryColor,
            //         ),
            //       );
            //     } else {
            //       return Container(
            //         margin: EdgeInsets.only(top: 20),
            //         width: 60.0,
            //         height: 60.0,
            //         decoration: new BoxDecoration(
            //             shape: BoxShape.circle,
            //             gradient: LinearGradient(
            //               begin: Alignment(6.123234262925839e-17, 1),
            //               end: Alignment(-1, 6.123234262925839e-17),
            //               colors: [Color.fromRGBO(185, 205, 254, 1), Color.fromRGBO(182, 178, 255, 1)],
            //             )),
            //         child: IconButton(
            //           onPressed: () => _audioPlayer.seek(Duration.zero),
            //           iconSize: 42.0,
            //           icon: Icon(Icons.replay),
            //           color: primaryColor,
            //         ),
            //       );
            //     }
            //   },
            // ),
            // StreamBuilder<Duration?>(
            //   stream: _audioPlayer.durationStream,
            //   builder: (context, snapshot) {
            //     final duration = snapshot.data ?? Duration.zero;
            //     return StreamBuilder<PositionData>(
            //       stream: Rx.combineLatest2<Duration, Duration, PositionData>(_audioPlayer.positionStream, _audioPlayer.bufferedPositionStream, (position, bufferedPosition) => PositionData(position, bufferedPosition)),
            //       builder: (context, snapshot) {
            //         final positionData = snapshot.data ?? PositionData(Duration.zero, Duration.zero);
            //         var position = positionData.position;
            //         if (position > duration) {
            //           position = duration;
            //         }
            //         var bufferedPosition = positionData.bufferedPosition;
            //         if (bufferedPosition > duration) {
            //           bufferedPosition = duration;
            //         }
            //         return SeekBar(
            //           duration: duration,
            //           position: position,
            //           bufferedPosition: bufferedPosition,
            //           onChangeEnd: (newPosition) {
            //             _audioPlayer.seek(newPosition);
            //           },
            //         );
            //       },
            //     );
            //  },
         //   ),
          ],
        ),
      ),
    );
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;

  PositionData(this.position, this.bufferedPosition);
}

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  SeekBar({
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;
  late SliderThemeData _sliderThemeData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 2.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SliderTheme(
          data: _sliderThemeData.copyWith(
            activeTrackColor: primaryColor,
            inactiveTrackColor: Colors.grey[300],
          ),
          child: Slider(
            min: 0.0,
            max: widget.duration.inMilliseconds.toDouble(),
            value: min(_dragValue ?? widget.position.inMilliseconds.toDouble(), widget.duration.inMilliseconds.toDouble()),
            onChanged: (value) {
              setState(() {
                _dragValue = value;
              });
              if (widget.onChanged != null) {
                widget.onChanged!(Duration(milliseconds: value.round()));
              }
            },
            onChangeEnd: (value) {
              if (widget.onChangeEnd != null) {
                widget.onChangeEnd!(Duration(milliseconds: value.round()));
              }
              _dragValue = null;
            },
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: 20),
          child: Text(
            '${widget.position.toString().split('.').first} / ${widget.duration.toString().split('.').first}',
            style: TextStyle(fontSize: fontSizeSmall, color: appStore.textSecondaryColor),
          ),
        ),
      ],
    );
  }
}
