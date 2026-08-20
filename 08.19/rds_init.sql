-- ============================================================
-- 1. 문자셋 설정
-- ============================================================
SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;


-- ============================================================
-- 2. 데이터베이스 생성
-- ============================================================
CREATE DATABASE IF NOT EXISTS STUDY
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;


-- ============================================================
-- 3. FastAPI에서 사용할 사용자 생성
-- ============================================================
CREATE USER IF NOT EXISTS 'std20'@'%'
IDENTIFIED BY 'melt7542';

GRANT ALL PRIVILEGES ON STUDY.* TO 'std20'@'%';

FLUSH PRIVILEGES;


-- ============================================================
-- 4. STUDY 데이터베이스 사용
-- ============================================================
USE STUDY;


-- ============================================================
-- 5. 기존 객체 제거
-- VIEW부터 삭제해야 테이블 참조 문제 방지
-- ============================================================
DROP VIEW IF EXISTS VRESULT;
DROP TABLE IF EXISTS TTEST;
DROP TABLE IF EXISTS TMEMBER;


-- ============================================================
-- 6. 교육생 테이블
-- ============================================================
CREATE TABLE TMEMBER (
    fid         VARCHAR(12)     NOT NULL COMMENT '가입자 아이디',
    fpass       VARCHAR(20)     NOT NULL COMMENT '가입자 비밀번호',
    fname       VARCHAR(20)     NOT NULL COMMENT '가입자 이름',
    femail      VARCHAR(50)     NOT NULL COMMENT '가입자 이메일 주소',
    fphone      VARCHAR(13)     NOT NULL COMMENT '가입자 연락처',
    faddr1      VARCHAR(100)    NOT NULL COMMENT '가입자 기본주소',
    faddr2      VARCHAR(100)    NOT NULL COMMENT '가입자 상세주소',
    fbirthday   DATE            NOT NULL COMMENT '가입자 생년월일',
    fgender     SET('남','여')  NOT NULL COMMENT '가입자 성별',
    fdate       DATETIME        NOT NULL COMMENT '가입일'
)
DEFAULT CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci
COMMENT='AWS RDS 서비스 테스트용 테이블';


-- ============================================================
-- 7. 교육생 초기 데이터
-- ============================================================
INSERT INTO TMEMBER (
    fid,
    fpass,
    fname,
    femail,
    fphone,
    faddr1,
    faddr2,
    fbirthday,
    fgender,
    fdate
)
VALUES
(
    'mzc-000',
    '1111',
    '김유신',
    'adc@mz.co.kr',
    '010-1111-1111',
    '서울특별시 강남구 논현로',
    '메가존빌딩 101호',
    '2002-07-26',
    '여',
    NOW()
),
(
    'mzc-111',
    '1111',
    '이순신',
    'bcd@mz.co.kr',
    '010-2222-2222',
    '서울특별시 강남구 강남대로',
    '제니스빌딩 210호',
    '2002-07-26',
    '여',
    NOW()
),
(
    'mzc-333',
    '1111',
    '홍길동',
    'cde@mz.co.kr',
    '010-3333-3333',
    '서울특별시 강남구 삼성로',
    '금정빌딩 310호',
    '2002-07-26',
    '여',
    NOW()
),
(
    'mzc-444',
    '1111',
    '강감찬',
    'def@mz.co.kr',
    '010-4444-4444',
    '서울특별시 강남구 역삼동',
    '빅데이터빌딩 410호',
    '2002-07-26',
    '여',
    NOW()
),
(
    'mzc-555',
    '1111',
    '세종',
    'efg@mz.co.kr',
    '010-5555-5555',
    '서울특별시 강남구 청담동',
    '에이아이빌딩 510호',
    '2002-07-26',
    '여',
    NOW()
),
(
    'mzc-666',
    '1111',
    '정조',
    'fgh@mz.co.kr',
    '010-6666-6666',
    '경기도 수원시',
    '아이오티빌딩 610호',
    '2002-07-26',
    '여',
    NOW()
),
(
    'mzc-777',
    '1111',
    '김종신',
    'ghi@mz.co.kr',
    '010-7777-7777',
    '경기도 의정부시',
    '스마트시티빌딩 710호',
    '2002-07-26',
    '여',
    NOW()
),
(
    'mzc-888',
    '1111',
    '아이유',
    'hij@mz.co.kr',
    '010-8888-8888',
    '경기도 안양시',
    '클라우드빌딩 810호',
    '2002-07-26',
    '여',
    NOW()
),
(
    'mzc-999',
    '1111',
    '안중근',
    'ijk@mz.co.kr',
    '010-9999-9999',
    '경기도 군포시',
    '그램빌딩 210호',
    '2002-07-26',
    '여',
    NOW()
),
(
    'adc-tot',
    '2222',
    '애쓴이',
    'lmn@megazone.com',
    '010-0000-0000',
    '경기도 화성시',
    '메가존빌딩 2층',
    '2004-05-21',
    '남',
    NOW()
);


-- ============================================================
-- 8. 성적 테이블
-- ============================================================
CREATE TABLE TTEST (
    fidx    INT         NOT NULL AUTO_INCREMENT COMMENT '일련번호, 자동증가',
    fid     VARCHAR(12) NOT NULL COMMENT '가입자 아이디',
    fkor    SMALLINT    NOT NULL DEFAULT 0 COMMENT '국어점수',
    feng    SMALLINT    NOT NULL DEFAULT 0 COMMENT '영어점수',
    fmat    SMALLINT    NOT NULL DEFAULT 0 COMMENT '수학점수',
    fdate   DATETIME    NOT NULL COMMENT '성적입력일',

    PRIMARY KEY (fidx)

    -- 수업 실습상 FK는 설정하지 않음
    -- FOREIGN KEY (fid) REFERENCES TMEMBER(fid)
)
DEFAULT CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci
COMMENT='수강생의 성적을 관리하기 위한 테이블';


-- ============================================================
-- 9. 초기 성적 데이터
-- ============================================================
INSERT INTO TTEST (
    fid,
    fkor,
    feng,
    fmat,
    fdate
)
VALUES
(
    'mzc-000',
    99,
    88,
    77,
    NOW()
),
(
    'mzc-111',
    88,
    77,
    60,
    NOW()
);


-- ============================================================
-- 10. 조회용 VIEW
-- ============================================================
CREATE VIEW VRESULT AS
SELECT
    a.fid,
    b.fname,
    b.fgender,
    a.fkor,
    a.feng,
    a.fmat,
    (a.fkor + a.feng + a.fmat) AS ftot,
    ROUND((a.fkor + a.feng + a.fmat) / 3, 1) AS favg,
    a.fdate
FROM TTEST AS a
LEFT JOIN TMEMBER AS b
    ON a.fid = b.fid;


-- ============================================================
-- 11. 최종 확인
-- ============================================================
SHOW TABLES;

SELECT * FROM TMEMBER;

SELECT * FROM TTEST;

SELECT * FROM VRESULT;