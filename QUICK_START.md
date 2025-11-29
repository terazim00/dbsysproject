# 🚀 빠른 시작 가이드 (WSL)

Windows에서 WSL을 사용하여 프로젝트를 실행하는 방법입니다.

---

## 전제 조건: WSL 설치

### WSL이 없다면 먼저 설치

```powershell
# PowerShell을 관리자 권한으로 실행
wsl --install

# 컴퓨터 재시작
# Ubuntu가 자동으로 설치됩니다
```

**설치 확인:**
```cmd
wsl --list
# Ubuntu가 나타나면 성공!
```

---

## 방법 1: 원클릭 실행 (가장 쉬움 ⭐)

### 1단계: 데이터 생성
```cmd
generate_data.bat
```
메뉴에서 **[2] Scale 0.1** 선택 (과제 제출용 권장)

### 2단계: 빌드
```cmd
build-windows.bat
```

### 3단계: 실행
```cmd
run-simple.bat
```
메뉴에서 **[2] TPC-H 데이터 변환 후 Join 실행** 선택

**완료! 🎉**

---

## 방법 2: 단계별 실행

### 1. TPC-H 데이터 생성

#### WSL에서 데이터 생성
```bash
# WSL 시작
wsl

# dbgen 다운로드 및 빌드 (최초 1회만)
cd ~
git clone https://github.com/electrum/tpch-dbgen.git
cd tpch-dbgen
make

# 데이터 생성 (Scale 0.1 권장)
./dbgen -s 0.1

# Windows 프로젝트 폴더로 복사
# 예: C:\Users\YourName\dbsysproject\data
cp part.tbl partsupp.tbl /mnt/c/Users/YourName/dbsysproject/data/

# WSL 종료
exit
```

**경로 변환 가이드:**
- Windows: `C:\Users\YourName\dbsysproject`
- WSL: `/mnt/c/Users/YourName/dbsysproject`

---

### 2. 프로그램 빌드

#### Windows CMD에서:
```cmd
build-windows.bat
```

또는 수동 빌드:
```cmd
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
cd ..
copy build\Release\dbsys.exe dbsys.exe
```

---

### 3. 데이터 변환

```cmd
REM PART 테이블 변환
dbsys.exe --convert-csv ^
  --csv-file data\part.tbl ^
  --block-file data\part.dat ^
  --table-type PART ^
  --block-size 4096

REM PARTSUPP 테이블 변환
dbsys.exe --convert-csv ^
  --csv-file data\partsupp.tbl ^
  --block-file data\partsupp.dat ^
  --table-type PARTSUPP ^
  --block-size 4096
```

---

### 4. Join 실행

```cmd
dbsys.exe --join ^
  --outer-table data\part.dat ^
  --inner-table data\partsupp.dat ^
  --outer-type PART ^
  --inner-type PARTSUPP ^
  --output output\result.dat ^
  --buffer-size 10
```

**실행 결과:**
```
=== Join Statistics ===
Block Reads: 152,250
Block Writes: 4,500
Output Records: 80,000
Elapsed Time: 4.235 seconds
Memory Usage: 40960 bytes (0.039 MB)
```

---

## 📊 성능 벤치마크

### 버퍼 크기별 테스트

```cmd
REM 여러 버퍼 크기로 자동 테스트
for %%b in (5 10 20 50 100) do (
  echo === Buffer Size: %%b ===
  dbsys.exe --join ^
    --outer-table data\part.dat ^
    --inner-table data\partsupp.dat ^
    --outer-type PART ^
    --inner-type PARTSUPP ^
    --output output\result_buf%%b.dat ^
    --buffer-size %%b
  echo.
)
```

---

## 🛠️ 트러블슈팅

### WSL이 설치되지 않음
```powershell
# PowerShell 관리자 권한
wsl --install

# 재부팅 후 확인
wsl --list
```

### "cmake가 인식되지 않습니다"
**해결책 1: Visual Studio 설치 (권장)**
- https://visualstudio.microsoft.com/downloads/
- "C++를 사용한 데스크톱 개발" 선택

**해결책 2: CMake 직접 설치**
- https://cmake.org/download/
- 설치 시 "Add to PATH" 선택

### WSL에서 "make: command not found"
```bash
wsl
sudo apt-get update
sudo apt-get install build-essential git
```

### 파일 복사 시 경로 오류
```bash
# WSL에서 본인의 사용자 이름 확인
ls /mnt/c/Users

# 프로젝트 폴더 확인
ls /mnt/c/Users/YourName

# data 폴더 생성
mkdir -p /mnt/c/Users/YourName/dbsysproject/data

# 다시 복사
cp part.tbl partsupp.tbl /mnt/c/Users/YourName/dbsysproject/data/
```

### output 디렉토리가 없다는 에러
```cmd
mkdir data
mkdir output
```

---

## 💡 WSL 유용한 팁

### Windows 탐색기에서 WSL 파일 열기
```
탐색기 주소창에 입력:
\\wsl$\Ubuntu\home\YourName\tpch-dbgen
```

### WSL에서 Windows 탐색기 열기
```bash
# 현재 폴더를 탐색기로 열기
explorer.exe .

# 프로젝트 폴더 열기
explorer.exe /mnt/c/Users/YourName/dbsysproject
```

### WSL 경로 별칭 설정
```bash
# .bashrc에 별칭 추가
echo "alias cdwin='cd /mnt/c/Users/YourName'" >> ~/.bashrc
source ~/.bashrc

# 사용
cdwin
cd dbsysproject
```

---

## 📝 빠른 테스트 (1분)

작은 데이터로 빠르게 테스트:

```bash
# WSL에서 작은 데이터 생성
wsl
cd ~/tpch-dbgen
./dbgen -s 0.01  # 매우 작은 데이터
cp part.tbl partsupp.tbl /mnt/c/Users/YourName/dbsysproject/data/
exit
```

```cmd
REM Windows에서 빌드 및 실행
build-windows.bat
run-simple.bat
REM [2] 선택
```

---

## 🎓 과제 제출용 체크리스트

- [ ] WSL 설치 완료
- [ ] TPC-H 데이터 생성 (Scale 0.1)
- [ ] 프로그램 빌드 성공 (dbsys.exe)
- [ ] 데이터 변환 완료 (part.dat, partsupp.dat)
- [ ] Join 실행 성공
- [ ] 성능 통계 확인 및 스크린샷
- [ ] 버퍼 크기별 성능 테스트 (최소 5개)
- [ ] 결과 데이터 검증
- [ ] 보고서 작성 (REPORT_GUIDE.md 참조)
- [ ] 소스코드 정리

---

## 📖 관련 문서

- **[GENERATE_DATA.md](GENERATE_DATA.md)** - TPC-H 데이터 생성 상세 가이드
- **[REPORT_GUIDE.md](REPORT_GUIDE.md)** - 보고서 작성 가이드
- **[README.md](README.md)** - 프로젝트 전체 문서

---

## 🎯 전체 과정 요약 (30초)

```cmd
REM 1. 데이터 생성
generate_data.bat

REM 2. 빌드
build-windows.bat

REM 3. 실행
run-simple.bat
```

**완료! 이제 보고서를 작성하세요!** 📄

---

**작성일**: 2025-11-29
**버전**: 2.0 (WSL 전용)
