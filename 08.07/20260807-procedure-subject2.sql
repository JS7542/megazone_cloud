DROP PROCEDURE IF EXISTS put_score;
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS put_score(
    IN p_name VARCHAR(10),
    IN p_kor INT,
    IN p_eng INT,
    IN p_math INT,
	OUT p_res VARCHAR(100)
)
BEGIN
	DECLARE mnum INT;
	DECLARE result VARCHAR(100);
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SET p_res = '에러 발생';
	END ;
        
    SELECT IFNULL(MAX(id), 0) + 1 INTO mnum FROM score;
    
    INSERT INTO score (id,score_name,kor,eng,math) 
    VALUE (mnum,p_name,p_kor,p_eng,p_math);
    
    
	SET result = CONCAT(
    '이름:',p_name,', 국어:',p_kor,', 영어:',p_eng,', 수학:',p_math,
    ', 총점:',totFun(p_kor,p_eng,p_math),
    ', 평균:',avgFun(p_kor,p_eng,p_math),
    ', 결과:',testFun(p_kor,p_eng,p_math)
    );
    
    SET p_res = result ;
    
END //

DELIMITER ;


CALL put_score('이학',90,90,100,@res);
select @res;

select * from score;

DROP PROCEDURE IF EXISTS del_score;
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS del_score(
	IN p_name VARCHAR(10),
    OUT p_result VARCHAR(50)
)
BEGIN
	DECLARE en INT;
	DECLARE p_id INT;
	DECLARE result VARCHAR(50);
	
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SET p_result = '에러 발생';
	END ;
    
    SELECT COUNT(id) INTO en FROM score
    WHERE score_name = p_name;
    
    IF en !=0 THEN
		SELECT id INTO p_id FROM score
		WHERE score_name = p_name;
		DELETE FROM score
        WHERE id = p_id;
		SET result = CONCAT(p_name,' 님 의 성적이 삭제 되었습니다.');
	ELSE
		SET result = CONCAT(p_name,'라는 이름의 사람의 성적이 존재하지 않습니다.');
    END IF;
    
    SET p_result = result;
END //

DELIMITER ;


CALL del_score('진석',@res);
SELECT @res;