# Docker 이미지 - 환경 설정 없이 바로 실행
FROM ubuntu:20.04

# 패키지 설치 (비대화형)
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    g++ \
    make \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# 작업 디렉토리 설정
WORKDIR /app

# 소스 코드 복사
COPY include/ ./include/
COPY src/ ./src/
COPY Makefile ./
COPY CMakeLists.txt ./

# 빌드
RUN make clean && make

# 데이터 디렉토리 생성
RUN mkdir -p data output

# 기본 명령어
CMD ["./dbsys", "--help"]

# 사용법:
# docker build -t dbsys .
# docker run -v $(pwd)/data:/app/data -v $(pwd)/output:/app/output dbsys \
#   --join --outer-table /app/data/part.dat --inner-table /app/data/partsupp.dat \
#   --outer-type PART --inner-type PARTSUPP --output /app/output/result.dat
