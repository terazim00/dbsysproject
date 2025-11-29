#!/bin/bash
# TPC-H 데이터 자동 생성 및 변환 스크립트

set -e  # 에러 발생 시 중단

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================"
echo "  TPC-H 데이터 생성 자동화"
echo -e "========================================${NC}"
echo ""

# Scale Factor 선택
echo "데이터 크기를 선택하세요:"
echo "[1] 매우 작음 (Scale 0.01 ~10MB)   - 빠른 테스트용"
echo "[2] 작음     (Scale 0.1 ~100MB)   - 과제 제출 권장 ⭐"
echo "[3] 표준     (Scale 1 ~1GB)       - 성능 벤치마크용"
echo "[4] 큰 크기  (Scale 10 ~10GB)     - 대규모 테스트용"
echo "[5] 사용자 정의"
echo ""
read -p "선택 (1/2/3/4/5): " CHOICE

case $CHOICE in
    1) SCALE=0.01 ;;
    2) SCALE=0.1 ;;
    3) SCALE=1 ;;
    4) SCALE=10 ;;
    5)
        read -p "Scale Factor 입력 (예: 0.5): " SCALE
        ;;
    *)
        echo "잘못된 선택입니다. Scale 0.1을 사용합니다."
        SCALE=0.1
        ;;
esac

echo ""
echo -e "${GREEN}선택된 Scale Factor: $SCALE${NC}"
echo ""

# 디렉토리 생성
mkdir -p data
mkdir -p output

# 1. dbgen 확인 및 다운로드
if [ ! -d "tpch-dbgen" ]; then
    echo -e "${BLUE}[1/6] dbgen 다운로드 중...${NC}"
    git clone https://github.com/electrum/tpch-dbgen.git

    echo -e "${BLUE}[2/6] dbgen 컴파일 중...${NC}"
    cd tpch-dbgen
    make
    cd ..
    echo -e "${GREEN}✓ dbgen 빌드 완료${NC}"
else
    echo -e "${YELLOW}[1/6] dbgen 이미 존재 (건너뜀)${NC}"
    echo -e "${YELLOW}[2/6] 컴파일 건너뜀${NC}"
fi

# 2. 데이터 생성
echo ""
echo -e "${BLUE}[3/6] TPC-H 데이터 생성 중... (Scale $SCALE)${NC}"
echo "이 작업은 몇 분 정도 걸릴 수 있습니다..."

cd tpch-dbgen
./dbgen -s $SCALE -f
cd ..

echo -e "${GREEN}✓ 데이터 생성 완료${NC}"

# 3. 파일 크기 확인
echo ""
echo -e "${BLUE}[4/6] 생성된 파일 확인${NC}"
ls -lh tpch-dbgen/*.tbl | awk '{print "  "$9" - "$5}'

# 4. 필요한 파일만 복사
echo ""
echo -e "${BLUE}[5/6] PART와 PARTSUPP 파일 복사 중...${NC}"
cp tpch-dbgen/part.tbl data/
cp tpch-dbgen/partsupp.tbl data/

echo -e "${GREEN}✓ 파일 복사 완료${NC}"
echo "  - data/part.tbl"
echo "  - data/partsupp.tbl"

# 5. 레코드 수 확인
echo ""
echo -e "${BLUE}레코드 수:${NC}"
PART_COUNT=$(wc -l < data/part.tbl)
PARTSUPP_COUNT=$(wc -l < data/partsupp.tbl)
echo "  PART: $PART_COUNT 레코드"
echo "  PARTSUPP: $PARTSUPP_COUNT 레코드"

# 6. 블록 형식으로 변환 (dbsys가 있을 때만)
echo ""
if [ -f "./dbsys" ]; then
    echo -e "${BLUE}[6/6] 블록 형식으로 변환 중...${NC}"

    echo "  - PART 테이블 변환 중..."
    ./dbsys --convert-csv \
        --csv-file data/part.tbl \
        --block-file data/part.dat \
        --table-type PART \
        --block-size 4096

    echo "  - PARTSUPP 테이블 변환 중..."
    ./dbsys --convert-csv \
        --csv-file data/partsupp.tbl \
        --block-file data/partsupp.dat \
        --table-type PARTSUPP \
        --block-size 4096

    echo -e "${GREEN}✓ 변환 완료${NC}"
    echo ""
    echo "생성된 블록 파일:"
    ls -lh data/*.dat | awk '{print "  "$9" - "$5}'
else
    echo -e "${YELLOW}[6/6] dbsys 실행 파일이 없습니다.${NC}"
    echo "먼저 빌드하세요: make"
    echo ""
    echo "나중에 수동으로 변환:"
    echo "  ./dbsys --convert-csv --csv-file data/part.tbl --block-file data/part.dat --table-type PART"
    echo "  ./dbsys --convert-csv --csv-file data/partsupp.tbl --block-file data/partsupp.dat --table-type PARTSUPP"
fi

# 완료 메시지
echo ""
echo -e "${GREEN}========================================"
echo "  데이터 생성 완료! ✓"
echo -e "========================================${NC}"
echo ""
echo "다음 단계:"
if [ -f "data/part.dat" ] && [ -f "data/partsupp.dat" ]; then
    echo -e "${GREEN}1. Join 실행:${NC}"
    echo "   ./dbsys --join \\"
    echo "     --outer-table data/part.dat \\"
    echo "     --inner-table data/partsupp.dat \\"
    echo "     --outer-type PART \\"
    echo "     --inner-type PARTSUPP \\"
    echo "     --output output/result.dat \\"
    echo "     --buffer-size 10"
    echo ""
    echo -e "${GREEN}2. 또는 간단 실행 스크립트 사용:${NC}"
    echo "   ./run-simple.sh"
else
    echo -e "${YELLOW}1. 먼저 프로그램 빌드:${NC}"
    echo "   make"
    echo ""
    echo -e "${YELLOW}2. 데이터 변환:${NC}"
    echo "   ./dbsys --convert-csv --csv-file data/part.tbl --block-file data/part.dat --table-type PART"
    echo "   ./dbsys --convert-csv --csv-file data/partsupp.tbl --block-file data/partsupp.dat --table-type PARTSUPP"
    echo ""
    echo -e "${GREEN}3. Join 실행:${NC}"
    echo "   ./dbsys --join ..."
fi

echo ""
