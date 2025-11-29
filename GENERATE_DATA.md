# TPC-H 테스트 데이터 생성 가이드

dbgen을 사용하여 PART와 PARTSUPP 테이블 데이터를 생성하는 방법입니다.

---

## 방법 1: Linux / WSL에서 생성 (권장 ⭐)

### 1단계: dbgen 다운로드 및 빌드

```bash
# 1. dbgen 다운로드
cd ~
git clone https://github.com/electrum/tpch-dbgen.git
cd tpch-dbgen

# 2. 컴파일
make

# 컴파일 완료 확인
ls -lh dbgen
# -rwxr-xr-x 1 user user 234K ... dbgen
```

**컴파일 에러 발생 시:**
```bash
# GCC가 없다면 설치
sudo apt-get update
sudo apt-get install build-essential

# 또는
sudo yum install gcc make
```

---

### 2단계: 데이터 생성

```bash
# Scale Factor 선택하여 데이터 생성
./dbgen -s 0.01    # 매우 작음 (~10MB) - 빠른 테스트용

# 또는
./dbgen -s 0.1     # 작음 (~100MB) - 과제 제출 권장 ⭐

# 또는
./dbgen -s 1       # 표준 크기 (~1GB) - 성능 벤치마크용

# 또는
./dbgen -s 10      # 큰 크기 (~10GB) - 대규모 테스트용
```

**Scale Factor 설명:**
- `-s 0.01`: 약 10MB, 레코드 수 ~2,000 (PART), ~8,000 (PARTSUPP)
- `-s 0.1`: 약 100MB, 레코드 수 ~20,000 (PART), ~80,000 (PARTSUPP)
- `-s 1`: 약 1GB, 레코드 수 ~200,000 (PART), ~800,000 (PARTSUPP) ⭐
- `-s 10`: 약 10GB, 레코드 수 ~2,000,000 (PART), ~8,000,000 (PARTSUPP)

---

### 3단계: 생성된 파일 확인

```bash
# 생성된 .tbl 파일 확인
ls -lh *.tbl

# 출력 예시:
# -rw-r--r-- 1 user user  24M ... customer.tbl
# -rw-r--r-- 1 user user 759M ... lineitem.tbl
# -rw-r--r-- 1 user user 2.2K ... nation.tbl
# -rw-r--r-- 1 user user 171M ... orders.tbl
# -rw-r--r-- 1 user user  24M ... part.tbl      ← 필요!
# -rw-r--r-- 1 user user 118M ... partsupp.tbl  ← 필요!
# -rw-r--r-- 1 user user 389B ... region.tbl
# -rw-r--r-- 1 user user 1.4M ... supplier.tbl
```

**필요한 파일:**
- `part.tbl` - PART 테이블
- `partsupp.tbl` - PARTSUPP 테이블

---

### 4단계: 프로젝트 폴더로 복사

```bash
# dbsysproject 폴더가 홈 디렉토리에 있다면
cp part.tbl partsupp.tbl ~/dbsysproject/data/

# 또는 절대 경로 사용
cp part.tbl partsupp.tbl /path/to/dbsysproject/data/

# 복사 확인
ls -lh ~/dbsysproject/data/*.tbl
```

---

### 5단계: 데이터 내용 확인

```bash
# PART 테이블 샘플 확인 (처음 3줄)
head -n 3 ~/dbsysproject/data/part.tbl
```

**출력 예시:**
```
1|goldenrod lavender spring chocolate lace|Manufacturer#1|Brand#13|PROMO BURNISHED COPPER|7|JUMBO PKG|901.00|ly. slyly ironi|
2|blush thistle blue yellow saddle|Manufacturer#1|Brand#13|LARGE BRUSHED BRASS|1|LG CASE|902.00|lar accounts amo|
3|spring green yellow purple cornsilk|Manufacturer#4|Brand#42|STANDARD POLISHED BRASS|21|WRAP CASE|903.00|egular deposits hag|
```

**필드 설명:**
- PARTKEY (1, 2, 3...)
- NAME
- MFGR (Manufacturer)
- BRAND
- TYPE
- SIZE
- CONTAINER
- RETAILPRICE
- COMMENT

---

## 방법 2: Windows에서 생성

### 옵션 A: WSL 사용 (가장 쉬움 ⭐)

```powershell
# 1. WSL 설치 (Windows 10/11)
wsl --install

# 2. Ubuntu 시작
wsl

# 3. 위의 "방법 1: Linux/WSL" 단계 따라하기
cd ~
git clone https://github.com/electrum/tpch-dbgen.git
cd tpch-dbgen
make
./dbgen -s 0.1

# 4. Windows 경로로 복사
cp part.tbl partsupp.tbl /mnt/c/Users/YourName/dbsysproject/data/
```

**WSL 경로 변환:**
- Windows: `C:\Users\YourName\dbsysproject`
- WSL: `/mnt/c/Users/YourName/dbsysproject`

---

### 옵션 B: MinGW에서 컴파일

```cmd
# 1. MinGW 설치
# https://www.mingw-w64.org/ 다운로드

# 2. Git Bash 또는 MinGW Shell에서
git clone https://github.com/electrum/tpch-dbgen.git
cd tpch-dbgen

# 3. Makefile 수정 (메모장으로 열기)
# CC = gcc
# DATABASE =
# MACHINE = WIN32
# WORKLOAD = TPCH

# 4. 컴파일
make -f makefile.win

# 5. 실행
dbgen.exe -s 0.1

# 6. 파일 복사
copy part.tbl ..\dbsysproject\data\
copy partsupp.tbl ..\dbsysproject\data\
```

---

### 옵션 C: 미리 생성된 데이터 다운로드

TPC-H 데이터를 직접 생성하기 어렵다면 온라인에서 다운로드:

1. **GitHub에서 검색:**
   - "TPC-H sample data" 검색
   - Scale Factor 0.1 정도의 작은 데이터 찾기

2. **직접 제공 받기:**
   - 교수님 또는 조교님께 요청
   - 팀원과 공유

---

## 방법 3: Docker에서 생성 (모든 플랫폼)

```bash
# 1. Docker 컨테이너에서 dbgen 실행
docker run -it --rm -v ${PWD}/data:/data ubuntu:20.04 bash

# 컨테이너 내부에서:
apt-get update
apt-get install -y git build-essential

git clone https://github.com/electrum/tpch-dbgen.git
cd tpch-dbgen
make

# 데이터 생성
./dbgen -s 0.1

# 호스트로 복사
cp part.tbl partsupp.tbl /data/
exit

# 2. 호스트에서 확인
ls -lh data/*.tbl
```

---

## 빠른 샘플 데이터 생성 (수동)

dbgen 설치가 어렵다면 직접 간단한 샘플 생성:

### create_sample_data.sh

```bash
#!/bin/bash
# 간단한 샘플 데이터 생성 (100 레코드)

mkdir -p data

# PART 테이블 샘플
cat > data/part_sample.tbl << 'EOF'
1|goldenrod lavender spring|Manufacturer#1|Brand#13|PROMO BURNISHED COPPER|7|JUMBO PKG|901.00|test comment|
2|blush thistle blue yellow|Manufacturer#1|Brand#13|LARGE BRUSHED BRASS|1|LG CASE|902.00|test comment|
3|spring green yellow purple|Manufacturer#4|Brand#42|STANDARD POLISHED BRASS|21|WRAP CASE|903.00|test comment|
4|cornflower chocolate smoke|Manufacturer#3|Brand#34|SMALL PLATED BRASS|14|MED DRUM|904.00|test comment|
5|forest brown coral puff|Manufacturer#3|Brand#32|STANDARD POLISHED TIN|15|SM PKG|905.00|test comment|
EOF

# PARTSUPP 테이블 샘플 (각 PART당 4개)
cat > data/partsupp_sample.tbl << 'EOF'
1|1|5000|993.49|ven ideas. quickly even|
1|2|2500|993.49|ven ideas. quickly even|
1|3|7500|993.49|ven ideas. quickly even|
1|4|9000|993.49|ven ideas. quickly even|
2|1|8000|993.49|ven ideas. quickly even|
2|2|3000|993.49|ven ideas. quickly even|
2|3|6500|993.49|ven ideas. quickly even|
2|4|4500|993.49|ven ideas. quickly even|
3|1|4500|993.49|ven ideas. quickly even|
3|2|7000|993.49|ven ideas. quickly even|
3|3|2500|993.49|ven ideas. quickly even|
3|4|8500|993.49|ven ideas. quickly even|
4|1|6000|993.49|ven ideas. quickly even|
4|2|1500|993.49|ven ideas. quickly even|
4|3|9500|993.49|ven ideas. quickly even|
4|4|3500|993.49|ven ideas. quickly even|
5|1|3000|993.49|ven ideas. quickly even|
5|2|8000|993.49|ven ideas. quickly even|
5|3|5500|993.49|ven ideas. quickly even|
5|4|2000|993.49|ven ideas. quickly even|
EOF

echo "샘플 데이터 생성 완료!"
ls -lh data/part_sample.tbl data/partsupp_sample.tbl
```

**사용법:**
```bash
chmod +x create_sample_data.sh
./create_sample_data.sh

# 변환 및 실행
./dbsys --convert-csv --csv-file data/part_sample.tbl \
  --block-file data/part_sample.dat --table-type PART

./dbsys --convert-csv --csv-file data/partsupp_sample.tbl \
  --block-file data/partsupp_sample.dat --table-type PARTSUPP

./dbsys --join \
  --outer-table data/part_sample.dat \
  --inner-table data/partsupp_sample.dat \
  --outer-type PART --inner-type PARTSUPP \
  --output output/result.dat
```

---

## 데이터 크기 선택 가이드

| Scale Factor | 데이터 크기 | PART 레코드 | PARTSUPP 레코드 | 용도 |
|--------------|-------------|-------------|-----------------|------|
| **0.01** | ~10 MB | ~2,000 | ~8,000 | 빠른 테스트, 개발 |
| **0.1** | ~100 MB | ~20,000 | ~80,000 | **과제 제출 권장** ⭐ |
| **1** | ~1 GB | ~200,000 | ~800,000 | 성능 벤치마크 |
| **10** | ~10 GB | ~2,000,000 | ~8,000,000 | 대규모 테스트 |
| 수동 샘플 | ~1 KB | 5-100 | 20-400 | dbgen 없을 때 |

---

## 생성 후 검증

### 1. 파일 크기 확인
```bash
ls -lh data/*.tbl
# part.tbl: 약 24MB (scale 0.1)
# partsupp.tbl: 약 118MB (scale 0.1)
```

### 2. 레코드 수 확인
```bash
# PART 레코드 수
wc -l data/part.tbl
# 20000 data/part.tbl (scale 0.1)

# PARTSUPP 레코드 수
wc -l data/partsupp.tbl
# 80000 data/partsupp.tbl (scale 0.1)
```

### 3. 형식 확인
```bash
# 파이프(|)로 구분되어 있는지 확인
head -n 1 data/part.tbl
# 1|goldenrod lavender...|Manufacturer#1|...
```

### 4. 프로젝트에서 변환 테스트
```bash
cd ~/dbsysproject

# PART 변환 테스트
./dbsys --convert-csv \
  --csv-file data/part.tbl \
  --block-file data/part.dat \
  --table-type PART

# 성공 메시지 확인
# Converted 20000 records to 1250 blocks
```

---

## 트러블슈팅

### "make: command not found"
```bash
# Ubuntu/Debian
sudo apt-get install build-essential

# CentOS/RHEL
sudo yum install gcc make

# macOS
xcode-select --install
```

### "git: command not found"
```bash
# Ubuntu/Debian
sudo apt-get install git

# CentOS/RHEL
sudo yum install git
```

### 컴파일 에러: "undefined reference to `..."
```bash
# Makefile 수정
cd tpch-dbgen
nano Makefile

# 다음 라인 찾아서 수정:
# CC = gcc
# DATABASE = ORACLE  → DATABASE =
# MACHINE = LINUX    → 본인 환경에 맞게
# WORKLOAD = TPCH

make clean
make
```

### Windows에서 ./dbgen 실행 안됨
```bash
# WSL 사용 권장
wsl
cd /mnt/c/Users/YourName
git clone https://github.com/electrum/tpch-dbgen.git
cd tpch-dbgen
make
./dbgen -s 0.1
```

---

## 자동화 스크립트

### generate_and_convert.sh (Linux/WSL)

```bash
#!/bin/bash
# TPC-H 데이터 생성 및 변환 자동화

SCALE=0.1  # Scale Factor 변경 가능
PROJECT_DIR=$(pwd)

echo "=== TPC-H 데이터 생성 및 변환 ==="
echo "Scale Factor: $SCALE"
echo ""

# 1. dbgen 다운로드 및 빌드
if [ ! -d "tpch-dbgen" ]; then
    echo "[1/5] dbgen 다운로드 중..."
    git clone https://github.com/electrum/tpch-dbgen.git
    cd tpch-dbgen
    echo "[2/5] 컴파일 중..."
    make
    cd ..
else
    echo "[1/5] dbgen 이미 존재함 (건너뜀)"
fi

# 2. 데이터 생성
echo "[3/5] TPC-H 데이터 생성 중 (Scale $SCALE)..."
cd tpch-dbgen
./dbgen -s $SCALE
cd ..

# 3. 파일 복사
echo "[4/5] 파일 복사 중..."
mkdir -p data
cp tpch-dbgen/part.tbl data/
cp tpch-dbgen/partsupp.tbl data/

# 4. 블록 형식으로 변환
echo "[5/5] 블록 형식 변환 중..."
./dbsys --convert-csv \
    --csv-file data/part.tbl \
    --block-file data/part.dat \
    --table-type PART

./dbsys --convert-csv \
    --csv-file data/partsupp.tbl \
    --block-file data/partsupp.dat \
    --table-type PARTSUPP

echo ""
echo "=== 완료! ==="
ls -lh data/*.dat
echo ""
echo "이제 Join을 실행할 수 있습니다:"
echo "./dbsys --join --outer-table data/part.dat --inner-table data/partsupp.dat --outer-type PART --inner-type PARTSUPP --output output/result.dat"
```

**사용법:**
```bash
chmod +x generate_and_convert.sh
./generate_and_convert.sh
```

---

## 요약

### 가장 쉬운 방법 (추천 순서)

1. **WSL 사용 (Windows):**
   ```bash
   wsl
   git clone https://github.com/electrum/tpch-dbgen.git
   cd tpch-dbgen && make
   ./dbgen -s 0.1
   cp part.tbl partsupp.tbl /mnt/c/Users/YourName/dbsysproject/data/
   ```

2. **Linux 직접:**
   ```bash
   git clone https://github.com/electrum/tpch-dbgen.git
   cd tpch-dbgen && make
   ./dbgen -s 0.1
   cp part.tbl partsupp.tbl ~/dbsysproject/data/
   ```

3. **Docker:**
   ```bash
   docker run -v ${PWD}/data:/data ubuntu:20.04 bash -c \
     "apt-get update && apt-get install -y git build-essential && \
      git clone https://github.com/electrum/tpch-dbgen.git && \
      cd tpch-dbgen && make && ./dbgen -s 0.1 && \
      cp part.tbl partsupp.tbl /data/"
   ```

---

**작성일**: 2025-11-29
**버전**: 1.0
