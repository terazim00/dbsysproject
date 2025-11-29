#!/bin/bash
# Linux/WSL용 간단 실행 스크립트
# 한 번의 명령으로 빌드부터 실행까지

set -e  # 에러 발생 시 중단

echo "========================================"
echo "  DBSys - Simple Execution Script"
echo "========================================"
echo ""

# 디렉토리 생성
mkdir -p data output

# 빌드
if [ ! -f "dbsys" ]; then
    echo "[빌드 중...]"
    make clean
    make
    echo ""
fi

# 실행 모드 선택
echo "실행 모드를 선택하세요:"
echo "[1] 샘플 데이터로 빠른 테스트 (1000 레코드)"
echo "[2] TPC-H 데이터 변환 후 Join 실행"
echo "[3] Join만 실행 (이미 변환된 데이터)"
echo "[4] 성능 벤치마크 (버퍼 크기별 테스트)"
echo ""
read -p "선택 (1/2/3/4): " MODE

case $MODE in
    1)
        echo ""
        echo "[샘플 데이터 생성 중...]"
        # 샘플 데이터 생성 (head 명령으로 작은 데이터 생성)
        if [ -f "data/part.tbl" ]; then
            head -n 1000 data/part.tbl > data/part_sample.tbl
            head -n 4000 data/partsupp.tbl > data/partsupp_sample.tbl

            ./dbsys --convert-csv \
                --csv-file data/part_sample.tbl \
                --block-file data/part_sample.dat \
                --table-type PART

            ./dbsys --convert-csv \
                --csv-file data/partsupp_sample.tbl \
                --block-file data/partsupp_sample.dat \
                --table-type PARTSUPP
        else
            echo "[경고] data/part.tbl 파일이 없어 샘플 데이터를 생성할 수 없습니다."
            echo "기존 샘플 데이터로 진행합니다."
        fi

        echo ""
        echo "[Join 실행 중...]"
        ./dbsys --join \
            --outer-table data/part_sample.dat \
            --inner-table data/partsupp_sample.dat \
            --outer-type PART \
            --inner-type PARTSUPP \
            --output output/result.dat \
            --buffer-size 10
        ;;

    2)
        if [ ! -f "data/part.tbl" ] || [ ! -f "data/partsupp.tbl" ]; then
            echo "[ERROR] data/part.tbl 또는 data/partsupp.tbl 파일이 없습니다."
            echo ""
            echo "TPC-H 데이터 생성 방법:"
            echo "1. git clone https://github.com/electrum/tpch-dbgen.git"
            echo "2. cd tpch-dbgen && make"
            echo "3. ./dbgen -s 0.1"
            echo "4. cp *.tbl ../data/"
            exit 1
        fi

        echo ""
        echo "[1/3] PART 테이블 변환 중..."
        ./dbsys --convert-csv \
            --csv-file data/part.tbl \
            --block-file data/part.dat \
            --table-type PART \
            --block-size 4096

        echo ""
        echo "[2/3] PARTSUPP 테이블 변환 중..."
        ./dbsys --convert-csv \
            --csv-file data/partsupp.tbl \
            --block-file data/partsupp.dat \
            --table-type PARTSUPP \
            --block-size 4096

        echo ""
        echo "[3/3] Join 실행 중..."
        ./dbsys --join \
            --outer-table data/part.dat \
            --inner-table data/partsupp.dat \
            --outer-type PART \
            --inner-type PARTSUPP \
            --output output/result.dat \
            --buffer-size 10
        ;;

    3)
        if [ ! -f "data/part.dat" ] || [ ! -f "data/partsupp.dat" ]; then
            echo "[ERROR] 변환된 데이터 파일이 없습니다."
            echo "먼저 모드 2를 실행하여 데이터를 변환하세요."
            exit 1
        fi

        echo ""
        echo "[Join 실행 중...]"
        ./dbsys --join \
            --outer-table data/part.dat \
            --inner-table data/partsupp.dat \
            --outer-type PART \
            --inner-type PARTSUPP \
            --output output/result.dat \
            --buffer-size 10
        ;;

    4)
        if [ ! -f "data/part.dat" ] || [ ! -f "data/partsupp.dat" ]; then
            echo "[ERROR] 변환된 데이터 파일이 없습니다."
            echo "먼저 모드 2를 실행하여 데이터를 변환하세요."
            exit 1
        fi

        echo ""
        echo "[성능 벤치마크 시작...]"
        echo "BufferSize,BlockReads,BlockWrites,Records,Time,Memory" > benchmark.csv

        for bufsize in 5 10 20 50 100; do
            echo ""
            echo "=== 버퍼 크기: $bufsize 블록 ==="
            ./dbsys --join \
                --outer-table data/part.dat \
                --inner-table data/partsupp.dat \
                --outer-type PART \
                --inner-type PARTSUPP \
                --output output/result_buf${bufsize}.dat \
                --buffer-size $bufsize | tee temp_output.txt

            # CSV로 결과 추출
            grep "Block Reads\|Block Writes\|Output Records\|Elapsed Time\|Memory Usage" temp_output.txt | \
                awk -v bs=$bufsize 'BEGIN{printf "%d,", bs} {printf "%s,", $NF} END{print ""}' >> benchmark.csv
        done

        rm -f temp_output.txt
        echo ""
        echo "[벤치마크 완료]"
        echo "결과: benchmark.csv"
        cat benchmark.csv
        ;;

    *)
        echo "잘못된 선택입니다."
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "  실행 완료!"
echo "========================================"
echo "결과 파일: output/result.dat"
echo ""
