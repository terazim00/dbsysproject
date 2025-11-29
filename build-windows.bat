@echo off
REM Windows용 빌드 스크립트
REM 요구사항: Visual Studio 또는 MinGW

echo ========================================
echo   DBSys - Windows Build Script
echo ========================================
echo.

REM CMake가 설치되어 있는지 확인
where cmake >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] CMake가 설치되어 있지 않습니다.
    echo.
    echo 설치 방법:
    echo 1. https://cmake.org/download/ 에서 CMake 다운로드
    echo 2. 또는 MinGW 사용: https://www.mingw-w64.org/
    echo.
    pause
    exit /b 1
)

REM 빌드 디렉토리 생성
if not exist "build" mkdir build
cd build

echo [1/3] CMake 설정 중...
cmake .. -DCMAKE_BUILD_TYPE=Release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] CMake 설정 실패
    cd ..
    pause
    exit /b 1
)

echo [2/3] 컴파일 중...
cmake --build . --config Release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 컴파일 실패
    cd ..
    pause
    exit /b 1
)

echo [3/3] 실행 파일 복사 중...
cd ..
if exist "build\Release\dbsys.exe" (
    copy "build\Release\dbsys.exe" "dbsys.exe"
) else if exist "build\dbsys.exe" (
    copy "build\dbsys.exe" "dbsys.exe"
)

echo.
echo ========================================
echo   빌드 완료!
echo ========================================
echo.
echo 실행 방법:
echo   dbsys.exe --help
echo.
pause
