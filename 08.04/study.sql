-- DML
-- DB 생성 및 제어 -----------------------------------------
CREATE DATABASE std20db;

SHOW DATABASES;

DROP DATABASE std20db;

USE std20db;

-- TABLE 생성 및 제어 --------------------------------------

-- CREATE TABLE table_name (
-- 	colune_name1		data_type(len) [제약 조건]
-- 	colune_name2		data_type(len) [제약 조건]
-- 		:
-- 	colune_name3		data_type(len) [제약 조건]
--     PRIMARY KEY(colune_name)
-- ); 

CREATE TABLE IF NOT EXISTS t_subject (
	idx		smallint	auto_increment,
    subject varchar(20) NOT NULL,
    PRIMARY KEY(idx)
);

DESCRIBE t_subject;

DROP TABLE IF EXISTS t_subject;

-- 행 삽입 -------------------------------
-- INSERT INTO table_name (column1,column2, ..., column3) VALUE('','','', ...);

-- 모든 컬럼이 대상, 값은 컬럼 순서대로 나열
-- INSERT INTO table_name VALUES (all values),(all values),(all values)

-- 삭제 ---------------------------------
-- DELETE FROM table_name 
-- WHERE 조건절 ;

-- -- 수정 ---------------------------------

-- UPDATE table_name SET column1='value1',column2='value2', ...
-- WHERE 조건절;

-- ------ 컬럼 조회 및 제어 DCL -----------------------------------------------------------

SELECT * FROM t_subject
WHERE 조건절;
drop table tbookinfo;

CREATE TABLE IF NOT EXISTS tbookinfo (
	idx			int			AUTO_INCREMENT,
    bookname	VARCHAR(20)	NOT NULL,
    publisher	VARCHAR(20)	NOT NULL,
    pubdate		DATE		NOT NULL,
    price		INT			NOT NULL,
    PRIMARY KEY(idx)
);

desc tbookinfo;

INSERT INTO tbookinfo (bookname,publisher,pubdate,price) 
VALUE ('배우','영진닷컴',sysdate(),'16000');

INSERT INTO tbookinfo VALUES
('1','데이터','영진닷컴','2026-03-01','37000'),
('2','데이터베이스','영진닷컴','2026-03-01','37000'),
('3','내가 그린 기린 그림','기린닷컴','2019-03-01','77000'),
('4','IT 엔지니어를 위한 AWS 운영','길벗','2026-08-04','24000'),
('5','운영 체제','퍼스트북','2024-06-21','54000');

-- SELECT * FROM tbookinfo
-- WHERE pubdate BETWEEN '2022-01-01' AND '2024-06-21';
-- BETWEEN 은 이상  이하

-- 2만원 이하의 영진닷컴
-- WHERE price <= 20000 && publisher = '영진닷컴';

-- WHERE idx in (1,3,5);

-- ORDER BY pubdate;
-- asc(순차 생략 가능),desc(역순)

-- ORDER BY publisher , price;
SELECT * FROM tbookinfo
limit 2 offset 2;

update tbookinfo set publisher='길벗' -- , price='100000'
WHERE idx in (2 , 3, 5);


INSERT INTO tbookinfo  VALUES
((SELECT idx+10 FROM tbookinfo order by idx desc limit 1),'췍','컴',sysdate(),'76000');

-- ------------------------------------------------------

CREATE TABLE IF NOT EXISTS tuserinfo (
	user_name	varchar(30)	NOT NULL	COMMENT '이름',
    mail		varchar(30)	NOT NULL	COMMENT '메일',
    region		varchar(30)	NOT NULL	COMMENT '지역',
    PRIMARY KEY(mail)
)COMMENT '유저 정보';

CREATE TABLE IF NOT EXISTS tbookinfo (
	idx			int			AUTO_INCREMENT,
    bookname	VARCHAR(20)	NOT NULL		COMMENT '책 이름',
    publisher	VARCHAR(20)	NOT NULL		COMMENT '출판사',
    pubdate		DATE		NOT NULL		COMMENT '출판일',
    price		INT			NOT NULL		COMMENT '가격',
    PRIMARY KEY(idx)
);

CREATE TABLE IF NOT EXISTS tsellinfo (
	idx			INT			AUTO_INCREMENT,
    price		INT			NOT NULL		COMMENT '도서 판매가',
    salenum		INT			NOT NULL		COMMENT '도서 판매 수량',
    seldate		date		NOT NULL		COMMENT '도서 판매 일자',
	book_idx	INT 		NOT NULL 		COMMENT 'tbookinfo 에서 참조할 idx 값',
    user_mail	varchar(30)	NOT NULL		COMMENT	'tuserinfo 에서 참조할 mail 값',
    PRIMARY KEY(idx),
    CONSTRAINT fk_tbookinfo_idx FOREIGN KEY(book_idx) REFERENCES tbookinfo (idx),
    CONSTRAINT fk_tuserinfo_mail FOREIGN KEY(user_mail) REFERENCES tuserinfo (mail)
)COMMENT '도서 판매 정보';

SELECT * FROM tsellinfo;

INSERT INTO tuserinfo VALUES
('홍길동','a@a.com','서울'),
('김유신','b@b.com','경기'),
('아이유','c@c.com','제주');

INSERT INTO tbookinfo VALUES
('1','데이터','영진닷컴','2026-03-01','37000'),
('2','데이터베이스','영진닷컴','2026-03-01','37000'),
('3','내가 그린 기린 그림','기린닷컴','2019-03-01','77000'),
('4','IT 엔지니어를 위한 AWS 운영','길벗','2026-08-04','24000'),
('5','운영 체제','퍼스트북','2024-06-21','54000');

INSERT INTO tsellinfo VALUES
('1','21000','1',sysdate(),'1','a@a.com'),
('2','19000','1',sysdate(),'4','b@b.com'),
('3','18100','2',sysdate(),'2','b@b.com'),
('4','26000','3',sysdate(),'4','a@a.com'),
('5','11000','14',sysdate(),'3','c@c.com'),
('6','14000','5',sysdate(),'1','a@a.com');

SELECT price,salenum,seldate,(
	select bookname from tbookinfo 
	where idx=tsellinfo.book_idx
),(
	select user_name from tuserinfo 
	where mail=tsellinfo.user_mail
) FROM tsellinfo;
