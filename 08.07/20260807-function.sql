drop table score;
CREATE TABLE score (
    id INT AUTO_INCREMENT,
    score_name VARCHAR(20) NOT NULL,
    kor INT NOT NULL,
    eng INT NOT NULL,
    math INT NOT NULL,
    PRIMARY KEY(id)
);

INSERT INTO score (score_name, kor, eng, math)
VALUES
    ('홍길동', 100, 90, 80),
    ('김철수', 90, 80, 70),
    ('이영희', 80, 70, 60),
    ('박지성', 70, 60, 50),
    ('최민수', 60, 50, 40);


select * from score;


-- 합계 점수 ---------------------------------------------------
DROP FUNCTION IF EXISTS totFun;
DELIMITER //

CREATE FUNCTION totFun(
    user_kor INT,
    user_eng INT,
    user_math INT
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE result INT;

    SET result = user_kor + user_eng + user_math;

    RETURN result;
END //

DELIMITER ;

-- 평균 점수 ---------------------------------------------
DROP FUNCTION IF EXISTS avgFun;


DELIMITER //

CREATE FUNCTION avgFun(
    user_kor INT,
    user_eng INT,
    user_math INT
)
RETURNS DOUBLE
DETERMINISTIC
BEGIN
    DECLARE sum DOUBLE;
    DECLARE result DOUBLE;
    SET sum = totfun(user_kor,user_eng,user_math);
    SET result = sum / 3.0;

    RETURN result;
END //

DELIMITER ;


-- 학점 ---------------------------------------------
DROP FUNCTION IF EXISTS testFun;
DELIMITER //

CREATE FUNCTION testFun(
    user_kor INT,
    user_eng INT,
    user_math INT
)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE result VARCHAR(20);
    DECLARE user_avg DOUBLE;

    SET user_avg =avgFun(user_kor,user_eng,user_math);

    IF user_avg >= 90 THEN
        SET result = 'A';
    ELSEIF user_avg >= 80 THEN
        SET result = 'B';
    ELSEIF user_avg >= 70 THEN
        SET result = 'C';
    ELSEIF user_avg >= 60 THEN
        SET result = 'D';
    ELSE
        SET result = 'F';
    END IF;

    RETURN result;
END //

DELIMITER ;

-- SELECT score_name as '이름',testFun(kor,eng,math) as '학점' from score 
-- order by avgFun(kor,eng,math) desc;
SELECT id,score_name,kor,eng,math,
    totFun(kor, eng, math) AS total,
    avgFun(kor, eng, math) AS average,
    testFun(kor, eng, math) AS grade
FROM score;