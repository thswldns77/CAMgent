
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class YouTubePreviewTile extends StatelessWidget {
  final String youtubeUrl;
  const YouTubePreviewTile({super.key, required this.youtubeUrl});

  @override
  Widget build(BuildContext context) {
    final id = YoutubePlayer.convertUrlToId(youtubeUrl) ?? '';
    if (id.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => YouTubePlayerPage(videoId: id)),
        );
      },
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 유튜브 썸네일 (아주 가벼움)
            Image.network(
              'https://i.ytimg.com/vi/$id/hqdefault.jpg',
              fit: BoxFit.cover,
            ),
            // 중앙 재생 버튼 오버레이
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class YouTubePlayerPage extends StatefulWidget {
  final String videoId;
  const YouTubePlayerPage({super.key, required this.videoId});

  @override
  State<YouTubePlayerPage> createState() => _YouTubePlayerPageState();
}

class _YouTubePlayerPageState extends State<YouTubePlayerPage> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false
        ,
        mute: false,
        // loop: true, // 원하면 반복
      ),
    );

    // 페이지 진입 즉시: 세로 고정 + 시스템 UI 숨김
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
      );
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
  }

  @override
  void dispose() {
    // 복원
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Theme.of(context).colorScheme.primary,
        bottomActions: const [
          CurrentPosition(),
          SizedBox(width: 8),
          ProgressBar(isExpanded: true),
          PlaybackSpeedButton(),
          // FullScreenButton()  // ← 페이지 자체가 풀스크린이라 굳이 안 써도 됨
        ],
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // ★ 화면을 세로 9:16로 꽉 채우기
              Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: player,
                ),
              ),
              // ★ 좌상단 뒤로가기 부유 버튼
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onEnterFullScreen: () {
        // 혹시 전체 화면 버튼을 쓸 경우에도 세로 유지
        SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
        );
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      },
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
        );
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
    );
  }
}


class YouTubePlayerItem extends StatefulWidget {
  final String youtubeUrl;
  const YouTubePlayerItem({ Key? key, required this.youtubeUrl }) : super(key: key);

  @override
  _YouTubePlayerItemState createState() => _YouTubePlayerItemState();
}

class _YouTubePlayerItemState extends State<YouTubePlayerItem> {
  YoutubePlayerController? _ytController;
  late final String _videoId;

  @override
  void initState() {
    super.initState();
    _videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl) ?? '';
    if (_videoId.isNotEmpty) {
      _ytController = YoutubePlayerController(
        initialVideoId: _videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId.isEmpty || _ytController == null) {
      return const SizedBox.shrink();
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Theme.of(context).colorScheme.primary,
        bottomActions: const [
          CurrentPosition(),
          SizedBox(width: 8),
          ProgressBar(isExpanded: true),
          FullScreenButton(), // 눌러도 세로 유지
        ],
      ),
      onEnterFullScreen: () {
        SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
        );
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      },
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
        );
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      builder: (context, player) {
        return AspectRatio(
          aspectRatio: 9 / 16, // ★ 세로형
          child: player,
        );
      },
    );
  }
}
