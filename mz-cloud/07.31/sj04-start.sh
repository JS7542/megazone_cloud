#!/bin/bash

# 배열 ##########################

# [*] 배열 요소를 모두 묶어서 반환
# [@] 배열 요소를 각각 한꺼번에 반환

# 공백을 이용한 배열값 지정
# 배열명 = (값1 값2 값3 값4 값5 ...)

# # 배열명[index] = 값
# NAME=("사과" "바나나" "딸기" "파인애플" "자두" "오렌지" "복숭아" "포도")
# NUM[0]="1"
# NUM[1]="32"
# NUM[2]="456"

# echo ${NAME[2]}

# echo ${#NAME[0]}

# echo ${NAME[*]}

# echo ${NAME[@]}

# NUM[1]=""
# unset NUM
# echo ${NUM[@]}

# 슬라이싱 ###########
# echo ${NAME[@]::1}

# 반복문 응용

FRUITS=("사과" "바나나" "딸기" "파인애플" "체리" "오렌지" "복숭아" "포도")

for i in ${FRUITS[@]}; do
    if [ $i != "체리" ]; then
        echo -e -n "${i}\t"
    fi
done
echo
# continue 를 만나면 이번 반복을 스킵하고 다음 반복으로 넘어감
# break 를 만나면 전체 반복을 종료함.
for i in ${FRUITS[@]}; do
    if [ $i == "체리" ]; then
        break
    fi
        echo -e -n "${i}\t"
done
echo

