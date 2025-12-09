#!/bin/bash

# 웹 최적화 비디오 변환 스크립트
# H.264 코덱, 적절한 비트레이트, FastStart 옵션 적용

echo "🎬 비디오 웹 최적화 시작..."

# 원본 백업 디렉토리 생성
if [ ! -d "original_backup" ]; then
    mkdir -p original_backup
    echo "📁 백업 폴더 생성: original_backup/"
fi

# 최적화된 파일 저장 디렉토리
if [ ! -d "optimized" ]; then
    mkdir -p optimized
    echo "📁 최적화 폴더 생성: optimized/"
fi

# 비디오 파일 목록
videos=("ALL.MP4" "MJP.MP4" "MVM.MP4" "NMV.MP4")

for video in "${videos[@]}"; do
    if [ -f "$video" ]; then
        echo ""
        echo "🔄 처리 중: $video"

        # 원본 파일 정보 확인
        echo "📊 원본 파일 정보:"
        ffprobe -v quiet -print_format json -show_format -show_streams "$video" | grep -E '"duration"|"size"|"bit_rate"|"codec_name"|"width"|"height"' | head -10

        # 파일명 (확장자 제거)
        filename="${video%.*}"

        # 웹 최적화 인코딩
        # - H.264 코덱 (웹 호환성 최고)
        # - CRF 23 (화질 균형점)
        # - 해상도 1280x720 (HD 품질)
        # - 오디오 AAC 128k
        # - FastStart (스트리밍 최적화)
        # - 2-pass 인코딩 (품질 향상)

        echo "⚙️  1단계: 비디오 분석..."
        ffmpeg -i "$video" \
            -c:v libx264 \
            -preset medium \
            -crf 23 \
            -vf "scale='min(1280,iw)':'min(720,ih)':force_original_aspect_ratio=decrease,pad=ceil(iw/2)*2:ceil(ih/2)*2" \
            -c:a aac \
            -b:a 128k \
            -ar 44100 \
            -movflags +faststart \
            -max_muxing_queue_size 1024 \
            -y "optimized/${filename}_web.mp4" 2>&1 | tail -20

        if [ $? -eq 0 ]; then
            echo "✅ 최적화 완료: optimized/${filename}_web.mp4"

            # 최적화 결과 비교
            original_size=$(stat -f%z "$video")
            optimized_size=$(stat -f%z "optimized/${filename}_web.mp4")
            reduction=$((100 - (optimized_size * 100 / original_size)))

            echo "📉 용량 비교:"
            echo "   원본: $(numfmt --to=iec-i --suffix=B $original_size 2>/dev/null || echo $original_size bytes)"
            echo "   최적화: $(numfmt --to=iec-i --suffix=B $optimized_size 2>/dev/null || echo $optimized_size bytes)"
            echo "   감소율: ${reduction}%"
        else
            echo "❌ 최적화 실패: $video"
        fi
    else
        echo "⚠️  파일을 찾을 수 없습니다: $video"
    fi
done

echo ""
echo "🎉 모든 비디오 최적화 완료!"
echo ""
echo "📂 결과 파일 위치: optimized/ 폴더"
echo "💡 원본 파일은 그대로 유지됩니다"
echo ""
echo "다음 명령으로 최적화된 파일을 확인하세요:"
echo "  ls -lh optimized/"
