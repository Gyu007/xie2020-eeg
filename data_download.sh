#!/bin/bash

echo "========================================"
echo "[1/4] 파이썬 osfclient 패키지를 확인/설치합니다..."
echo "========================================"
# osfclient가 없으면 설치합니다.
if ! command -v osf &> /dev/null; then
    echo "osfclient가 설치되어 있지 않습니다. pip를 통해 설치합니다..."
    pip install osfclient
else
    echo "osfclient가 이미 설치되어 있습니다."
fi

echo ""
echo "========================================"
echo "[2/4] OSF 서버에서 데이터를 개별적으로 안전하게 다운로드합니다..."
echo "========================================"
# 임시 폴더에 프로젝트 전체 구조 클론 (500 에러 방지)
# -p ykp9w: 프로젝트 ID 지정
osf -p ykp9w clone osf_temp_download

echo ""
echo "========================================"
echo "[3/4] 다운로드된 데이터를 'data' 디렉토리로 이동합니다..."
echo "========================================"
mkdir -p data

# osfclient는 기본적으로 'osfstorage'라는 최상위 폴더를 생성합니다.
# 내부의 PreprocData, RawData 등을 우리가 원하는 data/ 위치로 끌어올립니다.
if [ -d "osf_temp_download/osfstorage" ]; then
    mv osf_temp_download/osfstorage/* data/
fi

# 불필요해진 임시 폴더 삭제
rm -rf osf_temp_download
echo " -> 데이터 디렉토리 정리 완료."

echo ""
echo "========================================"
echo "[4/4] 피험자별 .tar 파일 압축 해제 및 원본 정리를 시작합니다..."
echo "========================================"

BASE_DIR="data"
DIRECTORIES=("PreprocData" "RawData")

for SUB_DIR in "${DIRECTORIES[@]}"; do
    DIR="$BASE_DIR/$SUB_DIR"
    
    if [ ! -d "$DIR" ]; then
        echo "[경고] '$DIR' 디렉토리를 찾을 수 없어 건너뜁니다."
        continue
    fi

    echo " -> '$DIR' 내부 작업 중..."

    for tar_file in "$DIR"/*.tar; do
        [ -e "$tar_file" ] || continue
        
        base_name=$(basename "$tar_file" .tar)
        target_dir="$DIR/$base_name"
        
        mkdir -p "$target_dir"
        
        if tar -xf "$tar_file" -C "$target_dir"; then
            echo "    [성공] $base_name 폴더 생성 및 해제 -> 원본 $(basename "$tar_file") 삭제"
            rm "$tar_file"
        else
            echo "    [실패] $tar_file 압축 해제 중 오류 발생"
        fi
    done
done

echo ""
echo "========================================"
echo "🎉 모든 데이터 셋업 파이프라인이 완벽하게 완료되었습니다!"