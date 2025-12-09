#!/bin/bash

# 모바일 웹 최적화 비디오 변환 스크립트
# 더 작은 해상도 + 낮은 비트레이트로 용량 최소화

echo "📱 모바일 웹 최적화 시작..."

# 최적화된 파일 저장 디렉토리
if [ ! -d "mobile_optimized" ]; then
    mkdir -p mobile_optimized
    echo "📁 모바일 최적화 폴더 생성: mobile_optimized/"
fi

# 비디오 파일 목록
videos=("ALL.MP4" "MJP.MP4" "MVM.MP4" "NMV.MP4")

for video in "${videos[@]}"; do
    if [ -f "$video" ]; then
        echo ""
        echo "🔄 처리 중: $video"

        # 파일명 (확장자 제거)
        filename="${video%.*}"

        # 모바일 웹 최적화 인코딩
        # - H.264 코덱
        # - CRF 28 (용량 우선)
        # - 해상도 480x1067 (모바일 최적화)
        # - 오디오 AAC 64k (용량 절감)
        # - FastStart (스트리밍 최적화)
        # - 프레임레이트 30fps로 제한

        echo "⚙️  모바일 최적화 인코딩 중..."
        ffmpeg -i "$video" \
            -c:v libx264 \
            -preset slower \
            -crf 28 \
            -vf "scale=480:-2,fps=30" \
            -c:a aac \
            -b:a 64k \
            -ar 44100 \
            -movflags +faststart \
            -max_muxing_queue_size 1024 \
            -y "mobile_optimized/${filename}_mobile.mp4" 2>&1 | tail -20

        if [ $? -eq 0 ]; then
            echo "✅ 최적화 완료: mobile_optimized/${filename}_mobile.mp4"

            # 최적화 결과 비교
            original_size=$(stat -f%z "$video")
            optimized_size=$(stat -f%z "mobile_optimized/${filename}_mobile.mp4")
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
echo "🎉 모든 비디오 모바일 최적화 완료!"
echo ""
echo "📂 결과 파일 위치: mobile_optimized/ 폴더"
echo "📱 모바일 웹 재생에 최적화된 480p 해상도"
echo ""
echo "다음 명령으로 최적화된 파일을 확인하세요:"
echo "  ls -lh mobile_optimized/"
