import 'package:flutter/material.dart';
import 'package:pod_player/pod_player.dart';

class ShowVideo extends StatefulWidget {
  final String? uri;

  const ShowVideo({super.key, this.uri});

  @override
  State<ShowVideo> createState() => _ShowVideoState();
}

class _ShowVideoState extends State<ShowVideo> {
  PodPlayerController? videoPlayerController;

  @override
  void initState() {
    videoPlayerController = PodPlayerController(
      playVideoFrom: PlayVideoFrom.network(widget.uri!),
      podPlayerConfig: const PodPlayerConfig(autoPlay: false),
    )..initialise();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: PodVideoPlayer(controller: videoPlayerController!),
    );
  }
}
