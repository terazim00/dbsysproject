# TPC-H 테스트 데이터 생성 가이드 (WSL)

WSL을 사용하여 Windows에서 TPC-H 데이터를 생성하는 방법입니다.

---

## 🚀 자동 생성 (가장 쉬움!)

```cmd
generate_data.bat
```

메뉴에서 원하는 크기 선택하면 자동으로 모든 과정이 완료됩니다!

---

## 📋 수동 생성 (단계별)

### 전제 조건: WSL 설치

WSL이 설치되어 있지 않다면:

```powershell
# PowerShell을 관리자 권한으로 실행
wsl --install

# 컴퓨터 재시작
# Ubuntu가 자동으로 설치됩니다
```

**WSL 설치 확인:**
```cmd
wsl --list
# Ubuntu 또는 다른 리눅스 배포판이 나타나면 OK
```

---

## 1단계: WSL에서 dbgen 설치

```bash
# WSL 시작
wsl

# dbgen 다운로드 및 빌드
cd ~
git clone https://github.com/electrum/tpch-dbgen.git
cd tpch-dbgen
make

# 빌드 확인
ls -lh dbgen
# -rwxr-xr-x ... dbgen 파일이 보이면 성공!
```

---

## 2단계: 데이터 생성

```bash
# Scale Factor 선택
./dbgen -s 0.01   # 매우 작음 (~10MB) - 빠른 테스트
./dbgen -s 0.1    # 작음 (~100MB) - 과제 제출 권장 ⭐
./dbgen -s 1      # 표준 (~1GB) - 성능 벤치마크
./dbgen -s 10     # 큰 크기 (~10GB) - 대규모 테스트
```

**예시: Scale 0.1 생성**
```bash
./dbgen -s 0.1

# 완료되면 다음 파일들이 생성됨
ls -lh *.tbl
# customer.tbl, lineitem.tbl, orders.tbl, part.tbl, partsupp.tbl 등
```

---

## 3단계: Windows 프로젝트 폴더로 복사

### Windows 경로를 WSL 경로로 변환

**Windows 경로:**
```
C:\Users\YourName\dbsysproject\data
```

**WSL 경로:**
```
/mnt/c/Users/YourName/dbsysproject/data
```

**변환 규칙:**
- `C:\` → `/mnt/c/`
- `D:\` → `/mnt/d/`
- `\` → `/`

### 파일 복사

```bash
# 예시: 프로젝트가 C:\Users\YourName\dbsysproject에 있다면
cp part.tbl partsupp.tbl /mnt/c/Users/YourName/dbsysproject/data/

# 복사 확인
ls -lh /mnt/c/Users/YourName/dbsysproject/data/*.tbl
```

**내 프로젝트 경로 찾기:**
```cmd
REM Windows CMD에서 프로젝트 폴더로 이동 후
cd C:\Users\YourName\dbsysproject
echo %cd%
REM 출력된 경로를 WSL 경로로 변환하여 사용
```

---

## 4단계: 데이터 검증

### WSL에서 확인
```bash
# 레코드 수 확인
wc -l /mnt/c/Users/YourName/dbsysproject/data/part.tbl
# 20000 (Scale 0.1 기준)

wc -l /mnt/c/Users/YourName/dbsysproject/data/partsupp.tbl
# 80000 (Scale 0.1 기준)

# 데이터 형식 확인
head -n 2 /mnt/c/Users/YourName/dbsysproject/data/part.tbl
# 1|goldenrod lavender...|Manufacturer#1|...
# 파이프(|)로 구분되어 있으면 정상!
```

### Windows에서 확인
```cmd
REM 프로젝트 폴더에서
dir data\*.tbl

REM 파일 크기 확인
REM part.tbl: 약 24MB (Scale 0.1)
REM partsupp.tbl: 약 118MB (Scale 0.1)
```

---

## 📊 Scale Factor 선택 가이드

| Scale | 총 크기 | PART 레코드 | PARTSUPP 레코드 | 생성 시간 | 용도 |
|-------|---------|-------------|-----------------|-----------|------|
| **0.01** | ~10 MB | 2,000 | 8,000 | 10초 | 빠른 테스트 |
| **0.1** | ~100 MB | 20,000 | 80,000 | 1분 | **과제 제출** ⭐ |
| **1** | ~1 GB | 200,000 | 800,000 | 5-10분 | 성능 벤치마크 |
| **10** | ~10 GB | 2,000,000 | 8,000,000 | 1시간 | 대규모 테스트 |

**과제 제출용 권장: Scale 0.1**
- 적절한 크기 (100MB)
- 빠른 생성 시간 (1분)
- 의미 있는 성능 측정 가능

---

## 🎯 전체 과정 요약

### 자동 방법 (30초)
```cmd
generate_data.bat
REM [2] 선택 (Scale 0.1)
```

### 수동 방법 (5분)
```bash
# 1. WSL 시작
wsl

# 2. dbgen 설치 (최초 1회만)
cd ~
git clone https://github.com/electrum/tpch-dbgen.git
cd tpch-dbgen
make

# 3. 데이터 생성
./dbgen -s 0.1

# 4. Windows로 복사
cp part.tbl partsupp.tbl /mnt/c/Users/YourName/dbsysproject/data/

# 5. WSL 종료
exit
```

```cmd
REM 6. Windows에서 빌드 및 실행
build-windows.bat
run-simple.bat
```

---

## 🛠️ 트러블슈팅

### WSL이 설치되지 않음
```powershell
# PowerShell 관리자 권限으로 실행
wsl --install

# 재부팅 후
wsl --list
```

### make: command not found
```bash
# WSL Ubuntu에서
sudo apt-get update
sudo apt-get install build-essential
```

### git: command not found
```bash
sudo apt-get install git
```

### 컴파일 에러 발생
```bash
cd ~/tpch-dbgen

# Makefile 편집
nano Makefile

# 다음 라인 확인:
# CC = gcc
# DATABASE =
# MACHINE = LINUX
# WORKLOAD = TPCH

# 저장 후 (Ctrl+O, Enter, Ctrl+X)
make clean
make
```

### 파일 복사 시 "No such file or directory"
```bash
# Windows 경로 확인
# WSL에서 Windows 파일 시스템 탐색
ls /mnt/c/Users
# 본인의 사용자 이름 확인

# 프로젝트 폴더 확인
ls /mnt/c/Users/YourName
# dbsysproject 폴더가 있는지 확인

# data 폴더 생성
mkdir -p /mnt/c/Users/YourName/dbsysproject/data

# 다시 복사
cp part.tbl partsupp.tbl /mnt/c/Users/YourName/dbsysproject/data/
```

### 한글 경로 문제
```
❌ C:\사용자\홍길동\dbsysproject
✅ C:\Users\YourName\dbsysproject

프로젝트를 영문 경로에 두는 것을 권장합니다.
```

---

## 💡 WSL 팁

### WSL에서 Windows 탐색기 열기
```bash
# 현재 디렉토리를 Windows 탐색기로 열기
explorer.exe .

# 특정 폴더 열기
explorer.exe /mnt/c/Users/YourName/dbsysproject/data
```

### Windows에서 WSL 파일 접근
```
Windows 탐색기 주소창에 입력:
\\wsl$\Ubuntu\home\YourName\tpch-dbgen
```

### WSL 경로 빠르게 이동
```bash
# Windows 홈 디렉토리로 바로 이동
cd /mnt/c/Users/YourName

# 또는 별칭 설정
echo "alias cdwin='cd /mnt/c/Users/YourName'" >> ~/.bashrc
source ~/.bashrc

# 이후 사용
cdwin
cd dbsysproject/data
```

---

## 📁 생성되는 파일 목록

dbgen 실행 후 생성되는 파일들:

```
tpch-dbgen/
├── customer.tbl      (고객 정보)
├── lineitem.tbl      (주문 라인 아이템)
├── nation.tbl        (국가 정보)
├── orders.tbl        (주문 정보)
├── part.tbl          ⭐ 필요!
├── partsupp.tbl      ⭐ 필요!
├── region.tbl        (지역 정보)
└── supplier.tbl      (공급자 정보)
```

**우리 프로젝트에 필요한 파일:**
- `part.tbl` - PART 테이블
- `partsupp.tbl` - PARTSUPP 테이블

나머지 파일은 무시해도 됩니다.

---

## ✅ 데이터 생성 완료 후

### 1. 프로그램 빌드
```cmd
build-windows.bat
```

### 2. 데이터 변환 및 Join 실행
```cmd
run-simple.bat
REM [2] 선택 - TPC-H 데이터 변환 후 Join 실행
```

또는 수동:
```cmd
REM 데이터 변환
dbsys.exe --convert-csv --csv-file data\part.tbl --block-file data\part.dat --table-type PART
dbsys.exe --convert-csv --csv-file data\partsupp.tbl --block-file data\partsupp.dat --table-type PARTSUPP

REM Join 실행
dbsys.exe --join --outer-table data\part.dat --inner-table data\partsupp.dat --outer-type PART --inner-type PARTSUPP --output output\result.dat --buffer-size 10
```

---

## 📖 관련 문서

- [QUICK_START.md](QUICK_START.md) - 전체 실행 가이드
- [REPORT_GUIDE.md](REPORT_GUIDE.md) - 보고서 작성 가이드
- [README.md](README.md) - 프로젝트 개요

---

**작성일**: 2025-11-29
**버전**: 2.0 (WSL 전용)
