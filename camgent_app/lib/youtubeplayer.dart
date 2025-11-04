import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// 유튜브 ID 추출 보강: shorts / youtu.be / watch?v= / 파라미터 포함 케이스
String extractYouTubeId(String url) {
  final id = YoutubePlayer.convertUrlToId(url);
  if (id != null && id.isNotEmpty) return id;

  final uri = Uri.tryParse(url);
  if (uri == null) return '';

  // /shorts/<id>
  final shortsIdx = uri.pathSegments.indexWhere((s) => s == 'shorts');
  if (shortsIdx != -1 && uri.pathSegments.length > shortsIdx + 1) {
    return uri.pathSegments[shortsIdx + 1];
  }

  // youtu.be/<id>
  if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.first;
  }

  // watch?v=<id>
  final v = uri.queryParameters['v'];
  if (v != null && v.isNotEmpty) return v;

  return '';
}

/// 리스트 카드에서 쓰는 미리보기 타일 (탭 시 재생 페이지로 이동)
class YouTubePreviewTile extends StatelessWidget {
  final String youtubeUrl;
  const YouTubePreviewTile({super.key, required this.youtubeUrl});

  // 빠른 연타로 인한 중복 push 방지
  static bool _pushing = false;

  @override
  Widget build(BuildContext context) {
    final id = extractYouTubeId(youtubeUrl);
    if (id.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        if (_pushing) return;
        _pushing = true;
        try {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => YouTubePlayerPage(videoId: id)),
          );
        } finally {
          _pushing = false;
        }
      },
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 유튜브 썸네일 (로딩/에러 처리)
            Hero(
              tag: 'yt_thumb_$id',
              child: Image.network(
                'https://i.ytimg.com/vi/$id/hqdefault.jpg',
                fit: BoxFit.cover,
                loadingBuilder: (c, w, progress) {
                  if (progress == null) return w;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, size: 32),
                ),
              ),
            ),
            // 중앙 재생 버튼 오버레이
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
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

/// 풀페이지 재생 화면 (세로 고정 + 시스템 UI 제어)
class YouTubePlayerPage extends StatefulWidget {
  final String videoId;
  const YouTubePlayerPage({super.key, required this.videoId});

  @override
  State<YouTubePlayerPage> createState() => _YouTubePlayerPageState();
}

class _YouTubePlayerPageState extends State<YouTubePlayerPage> {
  late final YoutubePlayerController _controller;
  bool _immersiveApplied = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );

    // 페이지 진입 후: 세로 고정 + 시스템 UI 숨김
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
      );
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _immersiveApplied = true;
    });
  }

  @override
  void dispose() {
    // 플레이어 정리
    _controller.pause();
    _controller.dispose();

    // 넓게 복원 (가로/세로 허용 + edgeToEdge)
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (_immersiveApplied) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
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
          // FullScreenButton() // 페이지 자체가 풀화면이어서 불필요
        ],
      ),
      onEnterFullScreen: () {
        // 혹시 빌트인 전체화면을 쓸 때도 세로 유지
        SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
        );
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      },
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Hero(
                    tag: 'yt_thumb_${widget.videoId}',
                    child: player,
                  ),
                ),
              ),
              // 좌상단 뒤로가기
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
    );
  }
}

/// 리스트 아이템 내부 등에서 직접 재생하고 싶을 때 쓰는 컴포넌트
/// (Shorts 전용처럼 세로 비율을 강제하려면 9/16, 일반 영상은 16/9)
class YouTubePlayerItem extends StatefulWidget {
  final String youtubeUrl;
  final bool verticalShorts; // true면 9:16, false면 16:9
  const YouTubePlayerItem({
    Key? key,
    required this.youtubeUrl,
    this.verticalShorts = true,
  }) : super(key: key);

  @override
  State<YouTubePlayerItem> createState() => _YouTubePlayerItemState();
}

class _YouTubePlayerItemState extends State<YouTubePlayerItem> {
  YoutubePlayerController? _ytController;
  late final String _videoId;

  @override
  void initState() {
    super.initState();
    _videoId = extractYouTubeId(widget.youtubeUrl);
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

    final aspect = widget.verticalShorts ? (9 / 16) : (16 / 9);

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Theme.of(context).colorScheme.primary,
        bottomActions: const [
          CurrentPosition(),
          SizedBox(width: 8),
          ProgressBar(isExpanded: true),
          FullScreenButton(), // 눌러도 onEnter/Exit에서 세로 유지
        ],
      ),
      onEnterFullScreen: () {
        SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
        );
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      },
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      builder: (context, player) {
        return AspectRatio(
          aspectRatio: aspect,
          child: player,
        );
      },
    );
  }
}
