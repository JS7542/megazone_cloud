DROP PROCEDURE IF EXISTS call_score;
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS call_score(
	IN p_id INT,
    OUT p_name VARCHAR(10),
    OUT p_kor INT,
    OUT p_eng INT,
    OUT p_math INT,
    OUT p_sum INT,
	OUT p_avg INT,
	OUT p_res VARCHAR(20)
)
BEGIN
	SELECT score_name,kor,eng,math,
    totFun(p_kor,p_eng,p_math),
    avgFun(p_kor,p_eng,p_math),
    testFun(p_kor,p_eng,p_math) 
	INTO p_name,p_kor,p_eng,p_math,p_sum,p_avg,p_res FROM score 
    WHERE id = p_id;
	
    
--     SET p_sum = totFun(p_kor,p_eng,p_math);
--     SET p_avg = avgFun(p_kor,p_eng,p_math);
--     SET p_res = testFun(p_kor,p_eng,p_math);
    
END //

DELIMITER ;

CALL call_score(1,@s_name,@kor,@eng,@mat,@sum,@s_avg,@res);
select @s_name AS '이름',@kor AS '국어',
	@eng AS '영어',@mat AS '수학',
	@sum AS '합계',@s_avg AS '평균',
    @res AS '학점';