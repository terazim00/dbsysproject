@echo off
REM Windows용 간단 실행 스크립트
REM 데이터 변환부터 Join 실행까지 자동화

setlocal EnableDelayedExpansion

echo ========================================
echo   DBSys - Simple Execution Script
echo ========================================
echo.

REM 디렉토리 생성
if not exist "data" mkdir data
if not exist "output" mkdir output

REM 실행 파일 확인
if not exist "dbsys.exe" (
    echo [ERROR] dbsys.exe가 없습니다. 먼저 빌드하세요:
    echo   build-windows.bat
    pause
    exit /b 1
)

REM 사용자에게 옵션 제공
echo 실행 모드를 선택하세요:
echo [1] 샘플 데이터로 빠른 테스트 (데이터 자동 생성)
echo [2] TPC-H 데이터 변환 후 Join 실행
echo [3] Join만 실행 (이미 변환된 데이터 사용)
echo.
set /p MODE="선택 (1/2/3): "

if "%MODE%"=="1" (
    echo.
    echo [샘플 데이터 생성 중...]
    call :CreateSampleData

    echo.
    echo [Join 실행 중...]
    dbsys.exe --join ^
        --outer-table data\part_sample.dat ^
        --inner-table data\partsupp_sample.dat ^
        --outer-type PART ^
        --inner-type PARTSUPP ^
        --output output\result.dat ^
        --buffer-size 10

) else if "%MODE%"=="2" (
    REM TPC-H 파일 확인
    if not exist "data\part.tbl" (
        echo [ERROR] data\part.tbl 파일이 없습니다.
        echo TPC-H 데이터를 data\ 폴더에 복사하세요.
        pause
        exit /b 1
    )
    if not exist "data\partsupp.tbl" (
        echo [ERROR] data\partsupp.tbl 파일이 없습니다.
        pause
        exit /b 1
    )

    echo.
    echo [1/3] PART 테이블 변환 중...
    dbsys.exe --convert-csv ^
        --csv-file data\part.tbl ^
        --block-file data\part.dat ^
        --table-type PART ^
        --block-size 4096

    echo.
    echo [2/3] PARTSUPP 테이블 변환 중...
    dbsys.exe --convert-csv ^
        --csv-file data\partsupp.tbl ^
        --block-file data\partsupp.dat ^
        --table-type PARTSUPP ^
        --block-size 4096

    echo.
    echo [3/3] Join 실행 중...
    dbsys.exe --join ^
        --outer-table data\part.dat ^
        --inner-table data\partsupp.dat ^
        --outer-type PART ^
        --inner-type PARTSUPP ^
        --output output\result.dat ^
        --buffer-size 10

) else if "%MODE%"=="3" (
    if not exist "data\part.dat" (
        echo [ERROR] data\part.dat 파일이 없습니다.
        echo 먼저 모드 2로 데이터를 변환하세요.
        pause
        exit /b 1
    )

    echo.
    echo [Join 실행 중...]
    dbsys.exe --join ^
        --outer-table data\part.dat ^
        --inner-table data\partsupp.dat ^
        --outer-type PART ^
        --inner-type PARTSUPP ^
        --output output\result.dat ^
        --buffer-size 10

) else (
    echo 잘못된 선택입니다.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   실행 완료!
echo ========================================
echo 결과 파일: output\result.dat
echo.
pause
exit /b 0

:CreateSampleData
REM 간단한 샘플 데이터 생성 (실제로는 C++ 프로그램에 --generate-sample 옵션 추가 필요)
echo 샘플 데이터는 수동으로 생성하거나 작은 TPC-H 데이터를 사용하세요.
echo TPC-H Scale Factor 0.01 권장
exit /b 0
