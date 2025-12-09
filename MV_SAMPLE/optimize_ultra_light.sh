#!/bin/bash

# 초경량 웹 최적화 비디오 변환 스크립트
# 최소 용량 우선, 모바일 데이터 절약

echo "🚀 초경량 웹 최적화 시작..."

# 최적화된 파일 저장 디렉토리
if [ ! -d "ultra_light" ]; then
    mkdir -p ultra_light
    echo "📁 초경량 폴더 생성: ultra_light/"
fi

# 비디오 파일 목록
videos=("ALL.MP4" "MJP.MP4" "MVM.MP4" "NMV.MP4")

for video in "${videos[@]}"; do
    if [ -f "$video" ]; then
        echo ""
        echo "🔄 처리 중: $video"

        # 파일명 (확장자 제거)
        filename="${video%.*}"

        # 초경량 웹 최적화 인코딩
        # - H.264 코덱 (baseline profile - 모든 기기 호환)
        # - CRF 32 (최대 압축)
        # - 해상도 360x778 (360p - 초경량)
        # - 오디오 AAC 48k (최소 품질)
        # - FastStart
        # - 프레임레이트 24fps

        echo "⚙️  초경량 인코딩 중..."
        ffmpeg -i "$video" \
            -c:v libx264 \
            -preset slower \
            -profile:v baseline \
            -level 3.0 \
            -crf 32 \
            -vf "scale=360:-2,fps=24" \
            -c:a aac \
            -b:a 48k \
            -ar 44100 \
            -movflags +faststart \
            -max_muxing_queue_size 1024 \
            -y "ultra_light/${filename}_light.mp4" 2>&1 | tail -20

        if [ $? -eq 0 ]; then
            echo "✅ 최적화 완료: ultra_light/${filename}_light.mp4"

            # 최적화 결과 비교
            original_size=$(stat -f%z "$video")
            optimized_size=$(stat -f%z "ultra_light/${filename}_light.mp4")
            reduction=$((100 - (optimized_size * 100 / original_size)))

            echo "📉 용량 비교:"
            echo "   원본: $(numfmt --to=iec-i --suffix=B $original_size 2>/dev/null || echo $original_size bytes)"
            echo "   초경량: $(numfmt --to=iec-i --suffix=B $optimized_size 2>/dev/null || echo $optimized_size bytes)"
            echo "   감소율: ${reduction}%"
        else
            echo "❌ 최적화 실패: $video"
        fi
    else
        echo "⚠️  파일을 찾을 수 없습니다: $video"
    fi
done

echo ""
echo "🎉 모든 비디오 초경량 최적화 완료!"
echo ""
echo "📂 결과 파일 위치: ultra_light/ 폴더"
echo "📱 360p 해상도 - 모바일 데이터 최소 사용"
echo "⚡ 저사양 기기에서도 부드러운 재생"
echo ""
echo "다음 명령으로 최적화된 파일을 확인하세요:"
echo "  ls -lh ultra_light/"
