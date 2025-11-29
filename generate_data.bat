@echo off
REM Windows용 TPC-H 데이터 생성 스크립트
REM WSL을 사용하여 데이터 생성

setlocal EnableDelayedExpansion

echo ========================================
echo   TPC-H 데이터 생성 (Windows)
echo ========================================
echo.

REM WSL 확인
wsl --list >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] WSL이 설치되어 있지 않습니다.
    echo.
    echo WSL 설치 방법:
    echo 1. PowerShell을 관리자 권한으로 실행
    echo 2. 다음 명령 실행: wsl --install
    echo 3. 컴퓨터 재시작
    echo 4. Ubuntu 설치 완료 후 다시 실행
    echo.
    echo 또는 Docker 사용: docker build -t dbsys .
    pause
    exit /b 1
)

echo [WSL 사용 가능 ✓]
echo.

REM Scale Factor 선택
echo 데이터 크기를 선택하세요:
echo [1] 매우 작음 (Scale 0.01 ~10MB)   - 빠른 테스트용
echo [2] 작음     (Scale 0.1 ~100MB)   - 과제 제출 권장 ★
echo [3] 표준     (Scale 1 ~1GB)       - 성능 벤치마크용
echo [4] 큰 크기  (Scale 10 ~10GB)     - 대규모 테스트용
echo.
set /p CHOICE="선택 (1/2/3/4): "

if "%CHOICE%"=="1" set SCALE=0.01
if "%CHOICE%"=="2" set SCALE=0.1
if "%CHOICE%"=="3" set SCALE=1
if "%CHOICE%"=="4" set SCALE=10

if not defined SCALE (
    echo 잘못된 선택입니다. Scale 0.1을 사용합니다.
    set SCALE=0.1
)

echo.
echo 선택된 Scale Factor: %SCALE%
echo.

REM 현재 디렉토리를 WSL 경로로 변환
set "CURRENT_DIR=%CD%"
set "WSL_PATH=/mnt/%CURRENT_DIR:~0,1%/%CURRENT_DIR:~3%"
set "WSL_PATH=%WSL_PATH:\=/%"

echo [WSL에서 데이터 생성 중...]
echo.

REM WSL에서 스크립트 실행
wsl bash -c "cd '%WSL_PATH%' && \
    echo '[1/6] dbgen 다운로드 및 빌드' && \
    if [ ! -d 'tpch-dbgen' ]; then \
        git clone https://github.com/electrum/tpch-dbgen.git && \
        cd tpch-dbgen && make && cd ..; \
    else \
        echo '  dbgen 이미 존재 (건너뜀)'; \
    fi && \
    echo '' && \
    echo '[2/6] TPC-H 데이터 생성 (Scale %SCALE%)' && \
    cd tpch-dbgen && ./dbgen -s %SCALE% -f && cd .. && \
    echo '' && \
    echo '[3/6] 파일 복사' && \
    mkdir -p data && \
    cp tpch-dbgen/part.tbl data/ && \
    cp tpch-dbgen/partsupp.tbl data/ && \
    echo '  ✓ part.tbl 복사 완료' && \
    echo '  ✓ partsupp.tbl 복사 완료' && \
    echo '' && \
    echo '[4/6] 레코드 수 확인' && \
    echo \"  PART: $(wc -l < data/part.tbl) 레코드\" && \
    echo \"  PARTSUPP: $(wc -l < data/partsupp.tbl) 레코드\""

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] 데이터 생성 실패
    pause
    exit /b 1
)

echo.
echo ========================================
echo   데이터 생성 완료!
echo ========================================
echo.
echo 생성된 파일:
dir /b data\*.tbl

echo.
echo 다음 단계:
echo 1. 프로그램 빌드: build-windows.bat
echo 2. 데이터 변환 및 Join 실행: run-simple.bat
echo.
pause
