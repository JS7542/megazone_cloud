-- DELIMITER //

-- CREATE PROCEDURE exPROC (
-- 	IN 매개변수 데이터타입,
--     OUT 매개변수 데이터타입,
--     INOUT 매개변수 데이터타입
-- )
-- BEGIN
-- 	DECLARE 변수 데이터타입, -- 변수 선언
-- 		:
-- 	-- 에러가 발생한 경우 되돌리기 위한 예외처리 설정
-- 	DECLARE EXIT HANDLER FOR SQLEXCEPTION
-- 	BEGIN
-- 		ROLLBACK; -- 쿼리에 문제 발생시 전체 되돌림.
--         SET OUT_변수 = 문제 발생시 반환할 데이터;
--     END;
--     -- ----------------------------------
--     START TRANSACTION; -- ROLLBACK or COMMIT 을 위한 트랜젝션 시작
--     
--     
--     -- : 작업들
--     
--     
-- 	COMMIT;	-- 변경사항 적용
--     SET OUT_변수 = 값; -- 변수값 변경
--     -- 따로 리턴 이 없기에, END 를 만났을 때, SET 된 아웃_변수 값들이 반환된다.
-- END //


-- DELIMITER ;

DROP PROCEDURE calProc;

DELIMITER //
CREATE PROCEDURE calProc(
	IN simbol VARCHAR(1),
    IN num1 INT,
    IN num2 INT,
    OUT result VARCHAR(20)    
)
BEGIN
	DECLARE res INT;
    
	IF simbol = '+' THEN 
		SET res = num1 + num2;
	ELSEIF simbol = '-' THEN 
		SET res = num1 - num2;
	ELSEIF simbol = '*' THEN 
		SET res = num1 * num2;
	ELSEIF simbol = '/' THEN 
		SET res = num1 / num2;
    END IF;
		SET	result = CONCAT(res,'입니다');
END //

DELIMITER ;

CALL calProc('-',16,5,@res);

SELECT @res AS 결과;


-- ======================================================================

DROP PROCEDURE IF EXISTS call_score;
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS call_score(
	IN p_id INT,
    OUT p_name VARCHAR(10),
    OUT p_kor INT,
    OUT p_eng INT,
    OUT p_math INT
)
BEGIN
	SELECT score_name,kor,eng,math INTO p_name,p_kor,p_eng,p_math FROM score 
    WHERE id = p_id;
    
END //

DELIMITER ;

CALL call_score(3,@s_name,@kor,@eng,@mat);
select @s_name,@kor,@eng,@mat;