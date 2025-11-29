# 🚀 빠른 시작 가이드

프로젝트를 간단하게 실행하는 3가지 방법을 제공합니다.

---

## 방법 1: 간단 실행 스크립트 (추천 ⭐)

### Windows에서
```cmd
# 1. 빌드
build-windows.bat

# 2. 실행 (대화형 메뉴)
run-simple.bat
```

### Linux / WSL / macOS에서
```bash
# 한 번에 실행 (빌드 + Join)
./run-simple.sh

# 또는 단계별:
chmod +x run-simple.sh
./run-simple.sh
```

**실행 모드:**
- `[1]` 샘플 데이터로 빠른 테스트 (1000 레코드) ✨
- `[2]` TPC-H 데이터 변환 후 Join 실행
- `[3]` Join만 실행 (이미 변환된 데이터)
- `[4]` 성능 벤치마크 (Linux만)

---

## 방법 2: Docker (환경 설정 불필요 🐳)

### 설치
Windows/Mac/Linux 모두 Docker Desktop 설치:
- https://www.docker.com/products/docker-desktop/

### 사용법
```bash
# 1. Docker 이미지 빌드 (최초 1회)
docker build -t dbsys .

# 2. 컨테이너 실행
docker run -v ${PWD}/data:/app/data -v ${PWD}/output:/app/output dbsys --help

# 3. Join 실행 예시
docker run -v ${PWD}/data:/app/data -v ${PWD}/output:/app/output dbsys \
  --join \
  --outer-table /app/data/part.dat \
  --inner-table /app/partsupp.dat \
  --outer-type PART \
  --inner-type PARTSUPP \
  --output /app/output/result.dat \
  --buffer-size 10
```

**Windows PowerShell에서:**
```powershell
docker run -v ${PWD}/data:/app/data -v ${PWD}/output:/app/output dbsys --help
```

**Windows CMD에서:**
```cmd
docker run -v %cd%/data:/app/data -v %cd%/output:/app/output dbsys --help
```

---

## 방법 3: 수동 빌드 및 실행

### Windows - Visual Studio
```cmd
# CMake 사용
mkdir build
cd build
cmake .. -G "Visual Studio 16 2019"
cmake --build . --config Release
cd ..
copy build\Release\dbsys.exe dbsys.exe
```

### Windows - MinGW
```cmd
# MinGW 설치: https://www.mingw-w64.org/
mkdir build
cd build
cmake .. -G "MinGW Makefiles"
cmake --build .
cd ..
copy build\dbsys.exe dbsys.exe
```

### Linux / WSL
```bash
# Make 사용
make clean
make

# 또는 CMake 사용
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make
cd ..
cp build/dbsys .
```

### 실행
```bash
# 1. 데이터 변환
./dbsys --convert-csv \
  --csv-file data/part.tbl \
  --block-file data/part.dat \
  --table-type PART

./dbsys --convert-csv \
  --csv-file data/partsupp.tbl \
  --block-file data/partsupp.dat \
  --table-type PARTSUPP

# 2. Join 실행
./dbsys --join \
  --outer-table data/part.dat \
  --inner-table data/partsupp.dat \
  --outer-type PART \
  --inner-type PARTSUPP \
  --output output/result.dat \
  --buffer-size 10
```

---

## 📊 TPC-H 테스트 데이터 준비

### 방법 1: TPC-H 데이터 생성 (권장)

**Linux/WSL:**
```bash
# 1. dbgen 다운로드 및 빌드
git clone https://github.com/electrum/tpch-dbgen.git
cd tpch-dbgen
make

# 2. 데이터 생성
./dbgen -s 0.01   # 아주 작은 데이터 (~10MB) - 빠른 테스트용
./dbgen -s 0.1    # 작은 데이터 (~100MB) - 과제 제출용 추천
./dbgen -s 1      # 표준 크기 (~1GB) - 성능 벤치마크용

# 3. 데이터 복사
cp part.tbl partsupp.tbl ../data/
cd ..
```

**Windows:**
1. WSL 사용 (위 방법 동일)
2. 또는 사전 생성된 데이터 다운로드:
   - TPC-H 벤치마크 사이트에서 다운로드
   - 또는 온라인에서 `.tbl` 파일 검색

### 방법 2: 샘플 데이터 생성

이미 TPC-H 데이터가 있다면 일부만 추출:

**Linux/WSL:**
```bash
head -n 1000 data/part.tbl > data/part_sample.tbl
head -n 4000 data/partsupp.tbl > data/partsupp_sample.tbl
```

**Windows (PowerShell):**
```powershell
Get-Content data\part.tbl -Head 1000 > data\part_sample.tbl
Get-Content data\partsupp.tbl -Head 4000 > data\partsupp_sample.tbl
```

---

## 🎯 초간단 실행 (30초 만에!)

### Linux/WSL (원클릭)
```bash
chmod +x run-simple.sh && ./run-simple.sh
# 메뉴에서 [1] 선택
```

### Windows (원클릭)
```cmd
build-windows.bat
run-simple.bat
:: 메뉴에서 [1] 선택
```

### Docker (원클릭)
```bash
docker build -t dbsys . && docker run dbsys --help
```

---

## 🛠️ 트러블슈팅

### Windows: "cmake가 인식되지 않습니다"
**해결:**
1. CMake 설치: https://cmake.org/download/
2. 설치 시 "Add to PATH" 옵션 선택
3. 또는 Visual Studio 설치 (CMake 포함)

### Windows: "컴파일러를 찾을 수 없습니다"
**해결 방법 1 - Visual Studio (권장):**
1. Visual Studio 2019/2022 Community 설치
2. "C++를 사용한 데스크톱 개발" 워크로드 선택
3. https://visualstudio.microsoft.com/downloads/

**해결 방법 2 - MinGW:**
1. MinGW-w64 설치: https://www.mingw-w64.org/
2. PATH에 MinGW bin 폴더 추가
3. `g++ --version`으로 확인

### Linux/WSL: "Permission denied"
```bash
chmod +x run-simple.sh
chmod +x dbsys
```

### Docker: "Cannot connect to Docker daemon"
**Windows:**
- Docker Desktop 실행 확인
- WSL 2 백엔드 활성화

**Linux:**
```bash
sudo systemctl start docker
sudo usermod -aG docker $USER  # 재로그인 필요
```

### "data/part.tbl 파일이 없습니다"
**해결:**
1. TPC-H 데이터 생성 (위 참조)
2. 또는 샘플 데이터로 테스트:
   - `run-simple.sh`에서 옵션 [1] 선택

---

## 📝 빠른 성능 테스트

### 버퍼 크기별 성능 비교 (5분)
```bash
# Linux/WSL
./run-simple.sh
# [4] 선택 → benchmark.csv 생성

# 또는 수동:
for bufsize in 5 10 20 50; do
  ./dbsys --join \
    --outer-table data/part.dat \
    --inner-table data/partsupp.dat \
    --outer-type PART \
    --inner-type PARTSUPP \
    --output output/result_buf${bufsize}.dat \
    --buffer-size $bufsize
done
```

### 결과 확인
```bash
cat benchmark.csv
# BufferSize,BlockReads,BlockWrites,Records,Time,Memory
# 5,280000,4500,800000,8.5s,20KB
# 10,160000,4500,800000,4.2s,40KB
# ...
```

---

## 💡 환경별 추천 방법

| 환경 | 추천 방법 | 이유 |
|------|-----------|------|
| **Windows 초보자** | Docker | 환경 설정 불필요 |
| **Windows 개발자** | CMake + Visual Studio | 디버깅 편리 |
| **WSL 사용자** | run-simple.sh | 가장 빠르고 간단 |
| **Linux** | run-simple.sh | 네이티브 성능 |
| **macOS** | Docker 또는 CMake | 호환성 보장 |
| **과제 제출용** | run-simple.sh [2] | 전체 데이터 테스트 |
| **빠른 테스트** | run-simple.sh [1] | 샘플 데이터 (30초) |

---

## 🎓 과제 제출용 체크리스트

- [ ] 프로그램 빌드 성공
- [ ] TPC-H 데이터 준비 (Scale Factor 0.1 이상)
- [ ] 데이터 변환 완료 (.tbl → .dat)
- [ ] Join 실행 성공
- [ ] 성능 통계 출력 확인
- [ ] 버퍼 크기별 성능 측정 (최소 5개)
- [ ] 결과 스크린샷 캡처
- [ ] 소스코드 정리 및 주석
- [ ] 보고서 작성 (REPORT_GUIDE.md 참조)

---

## 📞 도움이 필요하면?

1. **README.md** - 전체 문서
2. **REPORT_GUIDE.md** - 보고서 작성 가이드
3. **실행 예시:**
   ```bash
   ./dbsys --help
   ```

---

**작성일**: 2025-11-29
**버전**: 1.0
