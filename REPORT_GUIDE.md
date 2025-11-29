# 데이터베이스 실습 과제 보고서 작성 가이드

## 📌 과제 요구사항
- **주제**: TPC-H PART와 PARTSUPP 테이블에 대한 Block Nested Loops Join 구현
- **언어**: C/C++
- **핵심 요구사항**:
  1. 고정 크기 블록에 가변 길이 레코드 저장
  2. Block Nested Loops Join 알고리즘 구현
  3. 성능 분석 (버퍼 크기 조절, 수행 시간, 메모리 footprint)
  4. 최적화 구현 시 가산점

---

## 📋 보고서 구조 (권장)

### 1. 프로그램 전체 구조 (2-3페이지)

#### 1.1 시스템 아키텍처
```
[Application Layer]
    ↓
[Join Execution Layer]
    ↓
[Buffer Management] + [Table I/O]
    ↓
[Block & Record Management]
    ↓
[Disk Storage]
```

**포함 내용:**
- 계층별 역할 설명
- 주요 클래스/모듈 간 관계
- 데이터 흐름도
- 디렉토리 구조

**작성 예시:**
```markdown
## 1. 시스템 아키텍처

### 1.1 전체 구조
본 프로젝트는 5개 계층으로 구성된 모듈형 아키텍처를 채택했다:

1. **Application Layer (main.cpp)**
   - CLI 인터페이스 제공
   - 사용자 명령어 파싱
   - 성능 측정 및 결과 출력

2. **Join Execution Layer (join.cpp, optimized_join.cpp)**
   - Block Nested Loops Join 알고리즘 구현
   - 최적화 알고리즘 (Hash Join, Multithreading 등)
   - 조인 통계 수집

[계층도 다이어그램 삽입]

### 1.2 주요 컴포넌트
- **Block**: 고정 크기(4KB) 블록 관리
- **Record**: 가변 길이 레코드 직렬화/역직렬화
- **BufferManager**: 블록 버퍼 풀 관리
- **TableReader/Writer**: 블록 단위 파일 I/O
- **BlockNestedLoopsJoin**: BNLJ 실행 엔진
```

---

### 2. 조인 알고리즘 설명 (2페이지)

#### 2.1 Block Nested Loops Join 선택 이유
- 정렬되지 않은 테이블에 적합
- 메모리 제약 환경에서 효율적
- 큰 테이블에도 안정적으로 동작

#### 2.2 알고리즘 상세
**의사코드 포함:**
```
for each chunk of (B-1) blocks from R:
    load blocks into buffer
    for each block from S:
        load block into buffer
        for each r in outer_blocks:
            for each s in inner_block:
                if r.partkey == s.partkey:
                    output <r, s>
```

**복잡도 분석:**
- 시간 복잡도: O((|R|/(B-1)) × |S|)
- I/O 복잡도: |R| + (|R|/(B-1)) × |S|
- 메모리 사용: B × block_size

**작성 예시:**
```markdown
## 2. Block Nested Loops Join 알고리즘

### 2.1 알고리즘 선택 배경
본 과제에서 Block Nested Loops Join(이하 BNLJ)을 선택한 이유는 다음과 같다:

1. **비정렬 테이블**: TPC-H PART와 PARTSUPP는 PARTKEY 기준으로 정렬되어 있지 않아
   Merge Join 사용 불가
2. **메모리 효율성**: 전체 테이블을 메모리에 로드하지 않고도 실행 가능
3. **범용성**: 모든 크기의 테이블에 적용 가능

### 2.2 알고리즘 원리
BNLJ는 Nested Loops Join의 블록 단위 버전으로, I/O 횟수를 획기적으로 줄인다:

[의사코드]
[시간/공간 복잡도 분석]
[버퍼 관리 전략 설명]
```

---

### 3. 구현 세부사항 (3-4페이지)

#### 3.1 블록 구조
```
블록 레이아웃:
[레코드1 크기(4B)][레코드1 데이터(가변)]
[레코드2 크기(4B)][레코드2 데이터(가변)]
...
[미사용 공간]
```

#### 3.2 레코드 직렬화
- 가변 길이 필드 처리 방법
- 직렬화/역직렬화 알고리즘
- 예시 코드 스니펫

#### 3.3 핵심 코드 설명
**중요한 함수 5-6개 선정하여 설명:**
- `BlockNestedLoopsJoin::performJoin()` (join.cpp:85)
- `Block::addRecord()` (block.cpp)
- `BufferManager::getBlock()` (buffer.cpp)

**작성 예시:**
```markdown
## 3. 구현 세부사항

### 3.1 블록 및 레코드 관리

#### 블록 구조 (block.cpp:20-45)
각 블록은 고정 크기(기본 4KB)로 다음과 같이 구성된다:

```cpp
class Block {
    char* data;              // 블록 데이터 버퍼
    size_t block_size;       // 블록 크기
    size_t used_space;       // 사용 중인 공간

    bool addRecord(const char* record_data, size_t size);
    std::vector<std::string> getAllRecords();
};
```

**레코드 추가 로직:**
1. 남은 공간 확인: `used_space + 4 + size <= block_size`
2. 레코드 크기 기록 (4바이트)
3. 레코드 데이터 복사
4. used_space 업데이트

[코드 스니펫 첨부]

#### 가변 길이 레코드 직렬화 (record.cpp:50-80)
PART 테이블의 경우:
- PARTKEY (int): 4바이트
- NAME (varchar): [길이(2B)][데이터]
- MFGR (varchar): [길이(2B)][데이터]
...

[직렬화 예시 다이어그램]

### 3.2 BNLJ 핵심 로직 (join.cpp:100-200)

```cpp
void BlockNestedLoopsJoin::performJoin() {
    // 1. Outer 테이블을 (B-1) 블록씩 읽기
    while (outer_reader.hasMoreBlocks()) {
        std::vector<Block> outer_blocks =
            outer_reader.readBlocks(buffer_size - 1);

        // 2. Inner 테이블 전체 스캔
        inner_reader.reset();
        while (inner_reader.hasMoreBlocks()) {
            Block inner_block = inner_reader.readBlock();

            // 3. 조인 수행
            for (auto& outer_rec : outer_blocks) {
                for (auto& inner_rec : inner_block) {
                    if (outer_rec.partkey == inner_rec.partkey) {
                        writeJoinedRecord(outer_rec, inner_rec);
                    }
                }
            }
        }
    }
}
```

**주요 최적화:**
- 출력 버퍼링: 결과를 블록 단위로 모아서 쓰기
- 레코드 캐싱: 역직렬화 결과 재사용
- 통계 수집: I/O 카운트 자동 추적
```

---

### 4. 사용법 및 실행 결과 (2페이지)

#### 4.1 빌드 방법
```bash
make clean
make
```

#### 4.2 데이터 준비
```bash
# CSV 변환
./dbsys --convert-csv \
  --csv-file data/part.tbl \
  --block-file data/part.dat \
  --table-type PART
```

#### 4.3 Join 실행
```bash
./dbsys --join \
  --outer-table data/part.dat \
  --inner-table data/partsupp.dat \
  --outer-type PART \
  --inner-type PARTSUPP \
  --output output/result.dat \
  --buffer-size 10
```

#### 4.4 실행 결과 스크린샷
- 성공적인 실행 화면
- 성능 통계 출력
- 데이터 검증 결과

**작성 예시:**
```markdown
## 4. 실행 방법 및 결과

### 4.1 실행 환경
- OS: Ubuntu 20.04 LTS
- CPU: Intel Core i5-8250U (4 cores)
- RAM: 8GB
- Disk: SSD 256GB
- Compiler: g++ 9.4.0 (C++14)

### 4.2 데이터셋
- TPC-H Scale Factor: 0.1 (약 100MB)
- PART 레코드: 200,000개 (1,250 블록)
- PARTSUPP 레코드: 800,000개 (11,000 블록)
- 블록 크기: 4KB

### 4.3 실행 결과

**명령어:**
```bash
./dbsys --join \
  --outer-table data/part.dat \
  --inner-table data/partsupp.dat \
  --outer-type PART \
  --inner-type PARTSUPP \
  --output output/result.dat \
  --buffer-size 10
```

**출력:**
```
=== Join Statistics ===
Block Reads: 152,250
Block Writes: 4,500
Output Records: 800,000
Elapsed Time: 4.235 seconds
Memory Usage: 40960 bytes (0.039 MB)
```

**결과 검증:**
1. 출력 레코드 수 = PARTSUPP 레코드 수 (1:4 관계 확인)
2. 조인 키 일치 여부 샘플링 검사 통과
3. 출력 파일 크기: 약 150MB

[실행 화면 스크린샷]
```

---

### 5. 최적화 기법 (2-3페이지)

#### 5.1 구현한 최적화
1. **Hash Join**
   - 원리 및 구현
   - 성능 향상 메커니즘
   - 메모리 트레이드오프

2. **Multithreaded Join**
   - Producer-Consumer 패턴
   - 스레드 동기화 전략
   - CPU 병렬화

3. **Prefetching**
   - 비동기 I/O
   - I/O-CPU 오버랩

#### 5.2 버퍼 크기 최적화
- 버퍼 크기가 성능에 미치는 영향
- 수식: Inner 스캔 횟수 = ⌈|R|/(B-1)⌉
- 최적 버퍼 크기 선정

**작성 예시:**
```markdown
## 5. 최적화 전략

### 5.1 Hash Join 구현 (optimized_join.cpp:100-200)

#### 알고리즘 개요
Hash Join은 BNLJ의 Inner 테이블 반복 스캔 문제를 해결한다:

**Phase 1: Build**
```cpp
for each record r in PART:
    hash_table[r.partkey].push_back(r)
```

**Phase 2: Probe**
```cpp
for each record s in PARTSUPP:
    for each r in hash_table[s.partkey]:
        output <r, s>
```

#### 성능 분석
- **시간 복잡도**: O(|R| + |S|) vs BNLJ의 O((|R|/(B-1)) × |S|)
- **I/O 복잡도**: |R| + |S| = 12,250 블록 vs BNLJ의 152,250 블록
- **I/O 감소율**: 92.0% 감소!

#### 구현 상세
```cpp
class HashJoin {
    std::unordered_map<int, std::vector<PartRecord>> hash_table;

    void buildHashTable() {
        TableReader reader(part_file);
        while (reader.hasMore()) {
            PartRecord rec = reader.readRecord();
            hash_table[rec.partkey].push_back(rec);
        }
    }

    void probeAndJoin(TableWriter& writer) {
        TableReader reader(partsupp_file);
        while (reader.hasMore()) {
            PartSuppRecord rec = reader.readRecord();
            auto& matches = hash_table[rec.partkey];
            for (auto& part : matches) {
                writer.writeJoinedRecord(part, rec);
            }
        }
    }
};
```

#### 메모리 요구사항
- PART 레코드 크기: 평균 200 바이트
- 총 레코드: 200,000개
- 해시 테이블 크기: ~40MB + 오버헤드 ≈ **50MB**

### 5.2 Multithreaded Join (optimized_join.cpp:300-450)

#### 병렬화 전략
1. **I/O 스레드**: 블록 읽기/쓰기 담당
2. **Worker 스레드**: 조인 연산 수행
3. **동기화**: Producer-Consumer 패턴 + 조건 변수

[스레드 다이어그램]

#### 예상 성능
- 단일 스레드: 4.2초
- 듀얼 스레드: 2.5초 (1.68배 향상)
- 오버헤드: 동기화 비용 ~10%

### 5.3 버퍼 크기 최적화

#### 수학적 분석
Inner 테이블 스캔 횟수 = ⌈|R| / (B-1)⌉

예: |R| = 1,250 블록
- B=5: 1,250/4 = 313회
- B=10: 1,250/9 = 139회
- B=50: 1,250/49 = 26회

**총 I/O = |R| + 스캔횟수 × |S|**
- B=5: 1,250 + 313×11,000 = 3,444,250
- B=10: 1,250 + 139×11,000 = 1,530,250
- B=50: 1,250 + 26×11,000 = 287,250

→ 버퍼 10배 증가 시 I/O 5.3배 감소!
```

---

### 6. 성능 분석 및 비교 (3-4페이지)

#### 6.1 실험 설계
- 테스트 환경
- 데이터셋 규모
- 측정 항목 (시간, I/O, 메모리)

#### 6.2 버퍼 크기별 성능
**표 형식:**
| 버퍼 크기 | Block Reads | 실행 시간 | 메모리 | 성능 향상 |
|-----------|-------------|-----------|--------|-----------|
| 5         | 280,000     | 8.5s      | 20KB   | 1.0x      |
| 10        | 160,000     | 4.2s      | 40KB   | 2.0x      |
| 20        | 80,000      | 2.3s      | 80KB   | 3.7x      |

**그래프:**
- 버퍼 크기 vs 실행 시간
- 버퍼 크기 vs I/O 횟수

#### 6.3 블록 크기별 성능
#### 6.4 알고리즘별 비교
- BNLJ vs Hash Join
- BNLJ vs Multithreaded BNLJ
- Speedup 그래프

**작성 예시:**
```markdown
## 6. 성능 벤치마크 및 분석

### 6.1 실험 설계

#### 테스트 환경
- CPU: Intel Core i5-8250U @ 1.6GHz (4 cores)
- RAM: 8GB DDR4
- Disk: Samsung 860 EVO SSD
- OS: Ubuntu 20.04 LTS
- Compiler: g++ 9.4.0 (-O2 optimization)

#### 데이터셋
- TPC-H Scale Factor 0.1
- PART: 200,000 레코드 (25MB, 1,250 블록)
- PARTSUPP: 800,000 레코드 (110MB, 11,000 블록)

#### 측정 항목
1. **실행 시간**: 고해상도 타이머 (chrono)
2. **Block I/O**: 읽기/쓰기 블록 수
3. **메모리 사용**: 버퍼 풀 크기
4. **CPU 사용률**: top 명령어
5. **반복 횟수**: 5회 평균

### 6.2 버퍼 크기별 성능 분석

#### 실험 방법
```bash
for bufsize in 5 10 20 50 100; do
  echo "Testing buffer size: $bufsize"
  ./dbsys --join \
    --outer-table data/part.dat \
    --inner-table data/partsupp.dat \
    --buffer-size $bufsize \
    --output output/result_buf${bufsize}.dat
done
```

#### 결과 데이터

| 버퍼 크기 | Block Reads | Block Writes | 실행 시간 (s) | 메모리 (KB) | Speedup |
|-----------|-------------|--------------|---------------|-------------|---------|
| 5         | 2,751,250   | 4,500        | 8.234        | 20          | 1.00x   |
| 10        | 1,530,250   | 4,500        | 4.187        | 40          | 1.97x   |
| 20        | 786,250     | 4,500        | 2.345        | 80          | 3.51x   |
| 50        | 286,250     | 4,500        | 1.123        | 200         | 7.33x   |
| 100       | 146,750     | 4,500        | 0.789        | 400         | 10.44x  |

#### 그래프 분석

[그래프 1: 버퍼 크기 vs 실행 시간]
- 지수 감소 곡선 형태
- 50 블록 이상에서 수익 체감

[그래프 2: 버퍼 크기 vs Block Reads]
- 이론값과 실측값 비교
- 오차율 < 2%

#### 핵심 발견
1. **버퍼 크기 2배 → 실행 시간 약 50% 감소**
2. **최적 지점**: 20~50 블록 (성능/메모리 균형)
3. **100 블록 이상**: 추가 성능 향상 미미 (<10%)

### 6.3 블록 크기별 성능 분석

| 블록 크기 | Block Reads | 실행 시간 (s) | Throughput (MB/s) |
|-----------|-------------|---------------|-------------------|
| 2KB       | 306,500     | 5.234         | 25.8              |
| 4KB       | 153,250     | 4.187         | 32.3              |
| 8KB       | 76,625      | 3.891         | 34.7              |
| 16KB      | 38,313      | 3.756         | 36.0              |

**분석:**
- 블록 크기 증가 → I/O 횟수 감소
- 4KB~8KB 구간이 최적 (OS 페이지 크기와 일치)
- 16KB 이상: 추가 개선 제한적 (버퍼 메모리 증가 대비)

### 6.4 알고리즘별 성능 비교

#### 실험 조건
- 버퍼: 10 블록
- 블록: 4KB
- 반복: 5회 평균

#### 결과

| 알고리즘 | 실행 시간 | Block Reads | 메모리 | Speedup | 비고 |
|----------|-----------|-------------|--------|---------|------|
| **BNLJ (기본)** | 4.187s | 1,530,250 | 40KB | 1.00x | 기준선 |
| Hash Join | 0.823s | 12,250 | 52MB | **5.09x** | 메모리 intensive |
| Multithreaded BNLJ | 2.456s | 1,530,250 | 80KB | 1.70x | CPU 병렬화 |
| Prefetching BNLJ | 3.124s | 1,530,250 | 80KB | 1.34x | I/O 오버랩 |

#### 상세 분석

**1. Hash Join (5.09배 향상)**
- **I/O 감소**: 1,530,250 → 12,250 (99.2% 감소!)
- **병목**: 해시 테이블 구축 (0.3초)
- **메모리**: 52MB (PART 전체 로드)
- **적용 조건**: 작은 테이블이 메모리에 들어갈 때

**2. Multithreaded BNLJ (1.70배 향상)**
- **CPU 사용률**: 45% → 78% (듀얼 코어 활용)
- **스레드 오버헤드**: ~15%
- **확장성**: 4코어에서 2.3배 향상 예상
- **메모리**: 80KB (버퍼 2세트)

**3. Prefetching BNLJ (1.34배 향상)**
- **I/O 대기 감소**: 35% → 18%
- **CPU-I/O 오버랩**: 약 30%
- **제한 요인**: SSD의 빠른 I/O로 효과 제한적
  (HDD에서는 2배 이상 향상 예상)

### 6.5 종합 결론

#### 최적화 전략 선택 가이드

| 상황 | 추천 알고리즘 | 이유 |
|------|---------------|------|
| 메모리 충분 (>100MB) | **Hash Join** | 압도적 성능 (5배) |
| 메모리 제한 (<50MB) | **Multithreaded BNLJ** | 메모리 효율적, 1.7배 향상 |
| 단일 코어 | **버퍼 증가** | 간단하고 효과적 |
| HDD 환경 | **Prefetching BNLJ** | I/O 레이턴시 숨김 |

#### 실무 적용 시나리오
1. **소규모 데이터 (<1GB)**: Hash Join
2. **대규모 데이터 (>10GB)**: Multithreaded BNLJ + 대용량 버퍼
3. **임베디드 시스템**: BNLJ + 최소 버퍼

#### 이론 vs 실제
- **이론적 복잡도**: 실측값과 ±5% 이내로 일치
- **예상치 못한 발견**: SSD 환경에서 Prefetching 효과 제한적
- **개선 방향**: 하이브리드 알고리즘 (Hash + BNLJ 결합)
```

---

### 7. 결론 및 향후 과제 (1페이지)

**작성 예시:**
```markdown
## 7. 결론

### 7.1 달성 사항
1. **Block Nested Loops Join 성공적 구현**
   - 고정 크기 블록(4KB)에 가변 길이 레코드 저장
   - TPC-H PART/PARTSUPP 테이블 조인 (800,000 레코드)
   - 성능 측정 시스템 구축

2. **다양한 최적화 기법 적용**
   - Hash Join: 5.1배 성능 향상
   - Multithreading: 1.7배 성능 향상
   - 버퍼 크기 최적화: 10.4배 성능 향상 (100 블록)

3. **성능 분석 및 검증**
   - 이론적 복잡도와 실측값 일치 확인
   - 버퍼/블록 크기 최적화 가이드라인 도출

### 7.2 배운 점
- **I/O 최적화의 중요성**: 버퍼 관리가 성능에 결정적 영향
- **알고리즘 선택**: 데이터 특성과 메모리 제약에 따른 전략 필요
- **시스템 프로그래밍**: 저수준 파일 I/O, 메모리 관리, 멀티스레딩 경험

### 7.3 향후 개선 방향
1. **Sort-Merge Join 추가**: 정렬된 데이터에 대한 최적화
2. **Grace Hash Join**: 대용량 데이터를 위한 파티셔닝 기법
3. **인덱스 활용**: B+ Tree 인덱스 기반 조인
4. **SIMD 최적화**: 벡터화를 통한 CPU 성능 극대화
5. **분산 처리**: 여러 노드에서 병렬 조인

### 7.4 실무 적용 가능성
본 프로젝트에서 구현한 기법들은 다음 분야에 적용 가능:
- 임베디드 데이터베이스 (SQLite 등)
- 빅데이터 처리 시스템 (Hadoop, Spark)
- 실시간 스트림 조인 (Kafka Streams)
```

---

## 📊 필수 포함 요소 체크리스트

### ✅ 코드 관련
- [ ] 주요 클래스/함수 코드 스니펫 (5-10개)
- [ ] 의사코드로 알고리즘 설명
- [ ] 복잡도 분석 (시간, 공간, I/O)
- [ ] 블록/레코드 구조 다이어그램

### ✅ 실행 관련
- [ ] 빌드 방법 (Makefile 설명)
- [ ] 실행 명령어 예시
- [ ] 실행 결과 스크린샷 (최소 3개)
- [ ] 출력 통계 해석

### ✅ 성능 관련
- [ ] 버퍼 크기별 성능 테이블 (최소 5개 데이터 포인트)
- [ ] 블록 크기별 성능 비교
- [ ] 알고리즘별 비교 (BNLJ vs 최적화 버전)
- [ ] 성능 그래프 (최소 2개)

### ✅ 분석 관련
- [ ] 이론적 복잡도 vs 실측값 비교
- [ ] 병목 지점 분석
- [ ] 최적 파라미터 도출 (버퍼/블록 크기)
- [ ] 트레이드오프 분석 (메모리 vs 성능)

---

## 🎨 보고서 작성 팁

### 1. 그래프 및 다이어그램
**필수 그래프 (최소 5개):**
1. 버퍼 크기 vs 실행 시간 (선 그래프)
2. 버퍼 크기 vs Block I/O (막대 그래프)
3. 블록 크기 vs 처리량 (선 그래프)
4. 알고리즘별 Speedup (막대 그래프)
5. 시스템 아키텍처 (블록 다이어그램)

**도구 추천:**
- Python matplotlib: 성능 그래프
- Draw.io / Lucidchart: 아키텍처 다이어그램
- Gnuplot: CSV 데이터 시각화

### 2. 표 작성 가이드
- 모든 숫자는 천 단위 구분 (1,530,250)
- 단위 명시 (s, KB, MB, 회)
- 소수점 3자리까지 (4.187s)
- Speedup은 배수(x) 표시

### 3. 코드 스니펫 규칙
- 핵심 로직만 발췌 (20줄 이내)
- 주석으로 설명 추가
- 파일명과 라인 번호 명시
- 문법 하이라이팅 적용

### 4. 실행 결과 캡처
```bash
# 터미널 출력을 파일로 저장
./dbsys --join ... | tee output.txt

# 스크린샷 포함 항목
- 성공적인 실행 화면
- 성능 통계 출력
- 데이터 파일 크기 확인 (ls -lh)
- top/htop으로 리소스 사용률
```

### 5. 문서 구성
- **페이지 수**: 10-15페이지 권장
- **폰트**: 본문 11pt, 코드 9pt
- **여백**: 2.5cm (상하좌우)
- **줄 간격**: 1.5줄
- **목차**: 자동 생성

---

## 📝 성능 데이터 수집 스크립트

### benchmark.sh
```bash
#!/bin/bash

# 성능 테스트 자동화 스크립트
OUTPUT_DIR="benchmark_results"
mkdir -p $OUTPUT_DIR

echo "=== Starting Performance Benchmark ==="
echo "Timestamp: $(date)" | tee $OUTPUT_DIR/summary.txt

# 1. 버퍼 크기별 테스트
echo -e "\n[1] Buffer Size Test" | tee -a $OUTPUT_DIR/summary.txt
echo "BufferSize,BlockReads,BlockWrites,Records,Time,Memory" > $OUTPUT_DIR/buffer_test.csv

for bufsize in 5 10 20 50 100; do
    echo "Testing buffer size: $bufsize blocks"
    ./dbsys --join \
        --outer-table data/part.dat \
        --inner-table data/partsupp.dat \
        --outer-type PART \
        --inner-type PARTSUPP \
        --output $OUTPUT_DIR/result_buf${bufsize}.dat \
        --buffer-size $bufsize > $OUTPUT_DIR/buf${bufsize}.txt

    # CSV로 결과 추출
    grep "Block Reads\|Block Writes\|Output Records\|Elapsed Time\|Memory Usage" \
        $OUTPUT_DIR/buf${bufsize}.txt | \
        awk -v bs=$bufsize 'BEGIN{printf "%d,", bs} {printf "%s,", $NF} END{print ""}' \
        >> $OUTPUT_DIR/buffer_test.csv
done

# 2. 블록 크기별 테스트
echo -e "\n[2] Block Size Test" | tee -a $OUTPUT_DIR/summary.txt
echo "BlockSize,BlockReads,Time" > $OUTPUT_DIR/block_test.csv

for blocksize in 2048 4096 8192 16384; do
    echo "Testing block size: $blocksize bytes"

    # 데이터 재변환
    ./dbsys --convert-csv \
        --csv-file data/part.tbl \
        --block-file $OUTPUT_DIR/part_${blocksize}.dat \
        --table-type PART \
        --block-size $blocksize

    ./dbsys --convert-csv \
        --csv-file data/partsupp.tbl \
        --block-file $OUTPUT_DIR/partsupp_${blocksize}.dat \
        --table-type PARTSUPP \
        --block-size $blocksize

    # Join 실행
    ./dbsys --join \
        --outer-table $OUTPUT_DIR/part_${blocksize}.dat \
        --inner-table $OUTPUT_DIR/partsupp_${blocksize}.dat \
        --outer-type PART \
        --inner-type PARTSUPP \
        --output $OUTPUT_DIR/result_block${blocksize}.dat \
        --buffer-size 10 \
        --block-size $blocksize > $OUTPUT_DIR/block${blocksize}.txt

    # CSV로 결과 추출
    grep "Block Reads\|Elapsed Time" $OUTPUT_DIR/block${blocksize}.txt | \
        awk -v bs=$blocksize 'BEGIN{printf "%d,", bs} {printf "%s,", $NF} END{print ""}' \
        >> $OUTPUT_DIR/block_test.csv
done

# 3. 알고리즘별 비교 (Hash Join 등 구현되어 있다면)
echo -e "\n[3] Algorithm Comparison" | tee -a $OUTPUT_DIR/summary.txt

echo "=== Benchmark Complete ===" | tee -a $OUTPUT_DIR/summary.txt
echo "Results saved in: $OUTPUT_DIR/" | tee -a $OUTPUT_DIR/summary.txt
```

### plot_results.py
```python
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# 스타일 설정
sns.set_style("whitegrid")
plt.rcParams['font.family'] = 'DejaVu Sans'

# 1. 버퍼 크기 vs 성능
df_buffer = pd.read_csv('benchmark_results/buffer_test.csv')

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

# 실행 시간
ax1.plot(df_buffer['BufferSize'], df_buffer['Time'],
         marker='o', linewidth=2, markersize=8)
ax1.set_xlabel('Buffer Size (blocks)', fontsize=12)
ax1.set_ylabel('Execution Time (seconds)', fontsize=12)
ax1.set_title('Buffer Size vs Execution Time', fontsize=14, fontweight='bold')
ax1.grid(True, alpha=0.3)

# Block Reads
ax2.bar(df_buffer['BufferSize'], df_buffer['BlockReads'],
        color='skyblue', edgecolor='navy')
ax2.set_xlabel('Buffer Size (blocks)', fontsize=12)
ax2.set_ylabel('Block Reads', fontsize=12)
ax2.set_title('Buffer Size vs I/O Operations', fontsize=14, fontweight='bold')
ax2.grid(True, alpha=0.3, axis='y')

plt.tight_layout()
plt.savefig('benchmark_results/buffer_performance.png', dpi=300)
print("Graph saved: buffer_performance.png")

# 2. 블록 크기 vs 성능
df_block = pd.read_csv('benchmark_results/block_test.csv')

fig, ax = plt.subplots(figsize=(10, 6))
ax.plot(df_block['BlockSize'], df_block['Time'],
        marker='s', linewidth=2, markersize=8, color='green')
ax.set_xlabel('Block Size (bytes)', fontsize=12)
ax.set_ylabel('Execution Time (seconds)', fontsize=12)
ax.set_title('Block Size vs Execution Time', fontsize=14, fontweight='bold')
ax.grid(True, alpha=0.3)

plt.savefig('benchmark_results/block_performance.png', dpi=300)
print("Graph saved: block_performance.png")

plt.show()
```

---

## 🔍 체크포인트

### 제출 전 최종 확인
- [ ] 모든 코드가 컴파일되고 실행되는가?
- [ ] 실행 결과가 정확한가? (레코드 수 검증)
- [ ] 성능 데이터가 이론과 일치하는가? (±10% 이내)
- [ ] 모든 그래프/표에 캡션이 있는가?
- [ ] 참고문헌이 올바르게 인용되었는가?
- [ ] 오타 및 문법 검사 완료했는가?
- [ ] 소스코드가 주석과 함께 첨부되었는가?

---

## 📚 참고 자료

### 추천 문헌
1. **Database System Concepts** (7th Edition)
   - Silberschatz, Korth, Sudarshan
   - Chapter 12: Query Processing (Join Algorithms)

2. **TPC-H Benchmark Specification**
   - http://www.tpc.org/tpch/

3. **Block Nested Loops Join**
   - Wikipedia: Nested Loop Join
   - 논문: "Join Processing in Database Systems with Large Main Memories"

### 유용한 링크
- TPC-H 데이터 생성기: https://github.com/electrum/tpch-dbgen
- C++ I/O 최적화: https://en.cppreference.com/w/cpp/io
- 성능 프로파일링: `perf`, `valgrind`, `gprof`

---

## 💡 자주 묻는 질문 (FAQ)

### Q1: 버퍼 크기는 어떻게 선정하나요?
**A:** 실험을 통해 최적값을 찾되, 일반적으로:
- 최소: 2 블록 (outer 1 + inner 1)
- 권장: 10-20 블록 (40-80KB)
- 최대: 메모리 허용 범위 내

### Q2: PART와 PARTSUPP 중 어느 것을 Outer로?
**A:** **PART를 Outer로 권장** (작은 테이블을 Outer로)
- PART: 200,000 레코드
- PARTSUPP: 800,000 레코드
- Inner 스캔 횟수 = ⌈|Outer|/(B-1)⌉ 이므로 Outer가 작을수록 유리

### Q3: 실행 시간이 너무 오래 걸려요
**A:** 다음을 확인하세요:
1. Scale Factor 줄이기 (0.01 사용)
2. 샘플 데이터로 테스트
3. 버퍼 크기 증가 (50-100)
4. 최적화 빌드 확인 (`make` with `-O2`)

### Q4: Hash Join이 BNLJ보다 느려요
**A:** 데이터가 너무 작거나 해시 테이블 구축 오버헤드 때문일 수 있습니다.
- 최소 100,000 레코드 이상에서 테스트
- 메모리 할당 최적화 확인

---

## 📦 제출 파일 구성

```
submission.zip
├── report.pdf                  # 보고서 (PDF)
├── source/                     # 소스코드
│   ├── include/
│   ├── src/
│   ├── Makefile
│   └── README.md
├── benchmark_results/          # 성능 측정 결과
│   ├── buffer_test.csv
│   ├── block_test.csv
│   ├── buffer_performance.png
│   └── summary.txt
└── screenshots/                # 실행 결과 스크린샷
    ├── build.png
    ├── join_execution.png
    └── performance_stats.png
```

---

**작성 일자**: 2025-11-29
**버전**: 1.0
**작성자**: Database Systems Course
