-- 조건 제어문 
#IF 조건 THEN
#	실행 문장
#ELSEIF 조건 THEN
#	실행 문장
#    :
#ELSE
#	실행 문장
#END IF

-- ===================

 --  여기서 선언된 기호를 기준으로 뒤의 END 뒤에 오는 기호와 함께 바뀐다.
DELIMITER //
CREATE FUNCTION testFun(
		user_age INT
)
	RETURNS VARCHAR(20)
    DETERMINISTIC -- 입력 값 대비 반환값이 동일(일정)할 경우
BEGIN
	DECLARE result VARCHAR(20); -- 반환할 변수 선언 / 이 값은 반환되는 데이터의 값과 일치하여야 한다.
	IF user_age < 20 THEN 
		SET	result = '아가';
    ELSEIF user_age < 30 THEN
		SET result = '20대';
	ELSEIF user_age < 40 THEN 
		SET	result = '영써티' ;
	ELSE
		SET result = '할아버지';
    END IF;
    
    RETURN result;
END //
    
DELIMITER ;
-- 여기까지

-- 함수 호출
SELECT testFUN(35) as grade;

