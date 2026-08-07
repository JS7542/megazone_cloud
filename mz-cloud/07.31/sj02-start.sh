#!/bin/bash

# printf '#%.0s' {1..70}
# echo

# command -v 명령 : 명령이  존재하면 경로를 반환함.
# nginx가 없다면 nginx 설치
# if [ ! $(command -v nginx) ];then
#     sudo apt install -y nginx
# else
#     sudo apt remove -y nginx
#     sudo apt purge nginx
#     sudo apt autoremove -y
#     sudo apt clean
#     sudo rm -rf /etc/nginx
#     sudo rm -rf /var/www/html/*
#     sudo rm -rf /var/log/nginx
# fi

# NUM=2
# if [ ${NUM} -eq 1 ]; then
#     echo "1"

# elif [ ${NUM} -eq 2 ]; then
#     echo "2"

# elif [ ${NUM} -eq 3 ]; then
#     echo "3"

# elif [ ${NUM} -eq 4 ]; then
#     echo "4"

# elif [ ${NUM} -eq 5 ]; then
#     echo "5"

# else
#     echo "5보다 큰값"

# fi


KOR=80
ENG=70
MATH=90
SUM=$(( ${KOR} + ${ENG} + ${MATH} ))
AVG=$(( ${SUM} / 3 ))


if [ ${AVG} -ge 90 ]; then
    RESULT="수"

elif [ ${AVG} -ge 80 ]; then
    RESULT="우"

elif [ ${AVG} -ge 70 ]; then
    RESULT="미"

elif [ ${AVG} -ge 60 ]; then
    RESULT="양"

else
    RESULT="가"
fi


echo "국어 : ${KOR}, 영어 : ${ENG}, 수학 : ${MATH}, 합계 : ${SUM}, 평균 : ${AVG}, 결과 : ${RESULT}"