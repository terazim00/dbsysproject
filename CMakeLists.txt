# CMake 설정 - Windows/Linux 크로스 플랫폼 지원
cmake_minimum_required(VERSION 3.10)
project(DBSys VERSION 1.0)

# C++ 표준 설정
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# 컴파일 옵션
if(MSVC)
    # Visual Studio
    add_compile_options(/W4)
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        add_compile_options(/O2)
    endif()
else()
    # GCC/Clang
    add_compile_options(-Wall -Wextra)
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        add_compile_options(-O2)
    else()
        add_compile_options(-g)
    endif()
endif()

# 인클루드 디렉토리
include_directories(${PROJECT_SOURCE_DIR}/include)

# 소스 파일 수집
file(GLOB SOURCES
    "${PROJECT_SOURCE_DIR}/src/*.cpp"
)

# 실행 파일 생성
add_executable(dbsys ${SOURCES})

# Windows에서 콘솔 창 유지
if(WIN32)
    set_target_properties(dbsys PROPERTIES
        WIN32_EXECUTABLE FALSE
    )
endif()

# 출력 디렉토리 설정
set_target_properties(dbsys PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}
)

# 설치 규칙
install(TARGETS dbsys DESTINATION bin)

# 테스트 타겟 (선택사항)
enable_testing()
add_test(NAME QuickTest COMMAND dbsys --help)

# 정보 출력
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID}")
