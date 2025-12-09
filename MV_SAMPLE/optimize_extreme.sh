#!/bin/bash

# 극한 압축 비디오 변환 스크립트 (ALL, NMV 타겟)
# 최소 용량을 위한 극한 최적화

echo "🔥 극한 압축 최적화 시작..."

# 최적화된 파일 저장 디렉토리
if [ ! -d "extreme" ]; then
    mkdir -p extreme
    echo "📁 극한 압축 폴더 생성: extreme/"
fi

# 압축 대상 비디오 파일
videos=("ALL.MP4" "NMV.MP4")

for video in "${videos[@]}"; do
    if [ -f "$video" ]; then
        echo ""
        echo "🔄 처리 중: $video"

        # 파일명 (확장자 제거)
        filename="${video%.*}"

        # 극한 압축 인코딩
        # - H.264 코덱 (baseline profile)
        # - CRF 35 (극한 압축)
        # - 해상도 240x520 (240p - 극소형)
        # - 오디오 제거
        # - FastStart
        # - 프레임레이트 20fps (더 낮은 fps)
        # - 비트레이트 제한 추가

        echo "⚙️  극한 압축 인코딩 중..."
        ffmpeg -i "$video" \
            -c:v libx264 \
            -preset slower \
            -profile:v baseline \
            -level 3.0 \
            -crf 35 \
            -maxrate 200k \
            -bufsize 400k \
            -vf "scale=240:-2,fps=20" \
            -an \
            -movflags +faststart \
            -max_muxing_queue_size 1024 \
            -y "extreme/${filename}_extreme.mp4" 2>&1 | tail -20

        if [ $? -eq 0 ]; then
            echo "✅ 최적화 완료: extreme/${filename}_extreme.mp4"

            # 최적화 결과 비교
            original_size=$(stat -f%z "$video")
            optimized_size=$(stat -f%z "extreme/${filename}_extreme.mp4")
            reduction=$((100 - (optimized_size * 100 / original_size)))

            echo "📉 용량 비교:"
            echo "   원본: $(numfmt --to=iec-i --suffix=B $original_size 2>/dev/null || echo $original_size bytes)"
            echo "   극한 압축: $(numfmt --to=iec-i --suffix=B $optimized_size 2>/dev/null || echo $optimized_size bytes)"
            echo "   감소율: ${reduction}%"
        else
            echo "❌ 최적화 실패: $video"
        fi
    else
        echo "⚠️  파일을 찾을 수 없습니다: $video"
    fi
done

# 작은 파일들도 극한 압축
echo ""
echo "🔄 작은 파일들도 극한 압축 중..."

small_videos=("MJP.MP4" "MVM.MP4")

for video in "${small_videos[@]}"; do
    if [ -f "$video" ]; then
        filename="${video%.*}"

        echo "🔄 처리 중: $video"

        ffmpeg -i "$video" \
            -c:v libx264 \
            -preset slower \
            -profile:v baseline \
            -level 3.0 \
            -crf 35 \
            -maxrate 150k \
            -bufsize 300k \
            -vf "scale=240:-2,fps=20" \
            -an \
            -movflags +faststart \
            -max_muxing_queue_size 1024 \
            -y "extreme/${filename}_extreme.mp4" 2>&1 | tail -10

        if [ $? -eq 0 ]; then
            echo "✅ 완료: extreme/${filename}_extreme.mp4"

            original_size=$(stat -f%z "$video")
            optimized_size=$(stat -f%z "extreme/${filename}_extreme.mp4")
            reduction=$((100 - (optimized_size * 100 / original_size)))

            echo "📉 감소율: ${reduction}%"
        fi
    fi
done

echo ""
echo "🎉 모든 비디오 극한 압축 완료!"
echo ""
echo "📂 결과 파일 위치: extreme/ 폴더"
echo "🔥 240p 해상도 - 극한 압축"
echo "🔇 무음 처리"
echo "⚡ 20fps - 최소 데이터 사용"
echo ""
echo "다음 명령으로 최적화된 파일을 확인하세요:"
echo "  ls -lh extreme/"
