# 문자열 관련 함수
# CONCAT(): 문자열을 이어준다.
-- 컬럼 명 또한 들어올 수 있다.
SELECT CONCAT('a','bc','dee','we');

# concat_ws(): 지정된 문자를 중간에 넣어줌.
SELECT CONCAT_WS('-','010','7179','4305');

# 문자열 추출
# SUBSTRING('전체 문자열',시작 문자열 순서,몇 글자) /
# SUBSTR('전체 문자열',,)
# LEFT() / RIGHT() 각각 왼쪽, 오른쪽으로부터 특정 글자
-- 2번째 글자부터 5글자
SELECT SUBSTRING('qwerty 홍길동',4,2);
SELECT SUBSTR('qwerty 홍길동',4,2);

# 공백 삭제
# trim() 앞 뒤 공백 제거, ltrim(), rtrim()

# 치환
# REPLACE(): 문자를 찾아서 바꿈.
SELECT REPLACE('산토끼 토끼','토끼','거북이');

# 대문자로 또는 소문자로 변환
SELECT UPPER('asdfEdd');
SELECT LOWER('aSDfEdd');

# 글자 갯수 반환
SELECT LENGTH('a비c'); -- > byte 반환 / 거의 안쓰긴 하지만, byte 단위로 구성시에는 종종 쓴다.
SELECT CHAR_LENGTH('a비c'); 

# 문자 위치 반환
SELECT INSTR('산토끼 토끼야..... 어디를 가느냐?','토끼');
-- ####################################################

# 날짜 형식 만들기 
# 분 : i / 초 : s / 
SELECT date_format(now(),'%Y/%m/%d');

-- ###################################################

# 현재 날짜 및 시간
SELECT SYSDATE();
SELECT NOW();
SELECT CURDATE();
SELECT CURTIME();

# 날짜 연산 함수
SELECT DATE_ADD('2026-03-01',INTERVAL -1 DAY);
SELECT DATE_ADD('2026-01-01',INTERVAL 3 MONTH);
SELECT DATEDIFF('2026-01-03','2026-01-01');  -- 일반적인 날짜 개념이 아닌 산술적 연산이기에, 우리가 세는 날짜 방식으로 숫자를 표시할려면 + 1 을 해주어야 한다.
SELECT TIMEDIFF(CURTIME(),'02:56:26');
SELECT TIMEDIFF(SYSDATE(),'2026-08-06 02:56:26');


# 날짜 및 시간 추출
# year(now()) / month(now()) / day(now())
# hour() / minute() / secend()
select month(now());

CREATE table t1(
	idx int auto_increment,
    content varchar(50),
	primary key(idx)
);

INSERT into t1(content) value('50000');


-- ==============================================================
-- 조건부 제어 함수!!!
-- ifnull(colume,'기본값'): 컬럼이 null 이면 기본값을 반환한다. / null이 아니면 컬럽의 값을 반환


SELECT IFNULL(MAX(id), 0) + 1 from t1;


SELECT IF(content='50000','VIP','NIP') FROM t1;



# NULL 이 아닌 첫번째 값 반환 : coalesce('값1','값2', ...)
SELECT idx, coalesce(content,idx, '호호아줌마') from t1;

# 다중 조건문: CASE WHEN THEN !!
SELECT idx,
	CASE
		WHEN content is null THEN '거지'
        WHEN content='2000' THEN '2000원'
        ELSE '부자'
	END as '부자 인가요?'
from t1;