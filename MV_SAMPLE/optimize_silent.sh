#!/bin/bash

# 무음 초경량 웹 최적화 비디오 변환 스크립트
# 오디오 제거 + 최소 용량

echo "🔇 무음 초경량 웹 최적화 시작..."

# 최적화된 파일 저장 디렉토리
if [ ! -d "silent" ]; then
    mkdir -p silent
    echo "📁 무음 폴더 생성: silent/"
fi

# 비디오 파일 목록
videos=("ALL.MP4" "MJP.MP4" "MVM.MP4" "NMV.MP4")

for video in "${videos[@]}"; do
    if [ -f "$video" ]; then
        echo ""
        echo "🔄 처리 중: $video"

        # 파일명 (확장자 제거)
        filename="${video%.*}"

        # 무음 초경량 웹 최적화 인코딩
        # - H.264 코덱 (baseline profile)
        # - CRF 32 (최대 압축)
        # - 해상도 360x778 (360p)
        # - 오디오 제거 (-an)
        # - FastStart
        # - 프레임레이트 24fps

        echo "⚙️  무음 초경량 인코딩 중..."
        ffmpeg -i "$video" \
            -c:v libx264 \
            -preset slower \
            -profile:v baseline \
            -level 3.0 \
            -crf 32 \
            -vf "scale=360:-2,fps=24" \
            -an \
            -movflags +faststart \
            -max_muxing_queue_size 1024 \
            -y "silent/${filename}_silent.mp4" 2>&1 | tail -20

        if [ $? -eq 0 ]; then
            echo "✅ 최적화 완료: silent/${filename}_silent.mp4"

            # 최적화 결과 비교
            original_size=$(stat -f%z "$video")
            optimized_size=$(stat -f%z "silent/${filename}_silent.mp4")
            reduction=$((100 - (optimized_size * 100 / original_size)))

            echo "📉 용량 비교:"
            echo "   원본: $(numfmt --to=iec-i --suffix=B $original_size 2>/dev/null || echo $original_size bytes)"
            echo "   무음 초경량: $(numfmt --to=iec-i --suffix=B $optimized_size 2>/dev/null || echo $optimized_size bytes)"
            echo "   감소율: ${reduction}%"
        else
            echo "❌ 최적화 실패: $video"
        fi
    else
        echo "⚠️  파일을 찾을 수 없습니다: $video"
    fi
done

echo ""
echo "🎉 모든 비디오 무음 초경량 최적화 완료!"
echo ""
echo "📂 결과 파일 위치: silent/ 폴더"
echo "🔇 오디오 제거 - 최소 용량"
echo "📱 360p 해상도 - 모바일 데이터 최소 사용"
echo "⚡ 저사양 기기에서도 부드러운 재생"
echo ""
echo "다음 명령으로 최적화된 파일을 확인하세요:"
echo "  ls -lh silent/"
