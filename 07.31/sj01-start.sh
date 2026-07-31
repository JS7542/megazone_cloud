#!/bin/bash

# echo "hello"

# 변수 선언
# NAME="윤진수"
# AGE=27

# 변수 사용
# echo $NAME
# echo "이름 : $NAME$AGE"
# echo "나이 : ${AGE}${NAME}25"

# ###############################
# echo "현재 실행된 파일명 : ${0}"
# ###############################

# 산술 연산자

# sum=$((${AGE} + 3))
# echo ${sum}


# N1=1
# N2=2
# S=${N1}+${N2}
# echo ${S}

# ####################################################

# 비교 연산자 (왼쪽 기준)
# return 값은 boolean형식

#1.숫자 비교
# -eq(=), -ne(!=), -gt(>), -ge(>=), -lt(<), -le(<=)

# N1=10
# if [ $N1 -gt 5 ]; then
#     echo "N1은 5보다 크다."
# else
#     echo "N1은 5보다 작다."

# fi

#2. 문자 비교
#   =|==(같다) ,!=(다르다) ,-z(비어있다.) ,-n(비어있지않다)

# STR="hello"
# if [ "${STR}" != "hello" ]; then
#     echo "다르다"

# fi
# # -z , -n (NULL,EMPTY,UNDEFINED) 모두 인식
# EMPTY_VAR=""
# if [ -z $EMPTY_VAR ]; then
#     echo "변수가 비어있다."
# fi


# 3. 파일 비교 연산자
#   -e: (중요)파일이나 디렉토리가 존재하면 참
#   -f: (중요)일반 파일이면 참
#   -d: (중요)디렉토리이면 참
#   -r: 읽기 권한이 있으면 참
#   -w: 쓰기 권한이 있으면 참
#   -x: 실행 권한이 있으면 참
# CONFIG_FILE="/etc/hosts"
# if [ -f "${CONFIG_FILE}" ];then
#     echo "설정 파일이 존재합니다."
# fi

# 4. 논리 연산자
# 모든 기준은 참을 기준으로 한다.
# AND(&& | -a): 모두 참
# OR(|| | -o): 둘중 하나만 참이여도 참
# NOT(!): 참이면 거짓, 거짓이면 참

# NAME="진수"
# AGE=27
# if [ ${NAME} = "진수" ] && [ ${AGE} -eq 27 ]; then
#     echo "27세 진수 확인되었습니다."

# elif [ ${NAME} != "진수" ] && [ ${AGE} -eq 27 ]; then
#     echo "이름이 다릅니다"


# elif [ ${NAME} = "진수" ] && [ ${AGE} -ne 27 ]; then
#     echo "나이가 다릅니다"


# elif [ ${NAME} != "진수" ] && [ ${AGE} -ne 27 ]; then
#     echo "누구세요?"
# fi

# 입출력문

read