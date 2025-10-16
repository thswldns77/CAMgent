
import requests

API_KEY = ''  # ← 여기 본인의 키로 교체

import isodate  # ISO 8601 형식의 duration 파싱용


def search_youtube_shorts(keyword):
    # Step 1: 키워드 검색
    search_url = 'https://www.googleapis.com/youtube/v3/search'
    search_params = {
        'part': 'snippet',
        'q': keyword,
        'type': 'video',
        'maxResults': 10,
        'key': API_KEY
    }
    search_response = requests.get(search_url, params=search_params).json()
    items = search_response.get('items', [])
    video_ids = [item['id']['videoId'] for item in items]

    if not video_ids:
        return "검색 결과가 없습니다."

    # Step 2: 각 영상의 duration 확인
    videos_url = 'https://www.googleapis.com/youtube/v3/videos'
    videos_params = {
        'part': 'contentDetails',
        'id': ','.join(video_ids),
        'key': API_KEY
    }
    videos_response = requests.get(videos_url, params=videos_params).json()

    for video in videos_response.get('items', []):
        duration_str = video['contentDetails']['duration']  # ISO 8601 형식
        duration = isodate.parse_duration(duration_str).total_seconds()

        if duration <= 240:  # 4분 이하
            return f"https://www.youtube.com/watch?v={video['id']}"

    return "영상을 찾지 못했습니다."


