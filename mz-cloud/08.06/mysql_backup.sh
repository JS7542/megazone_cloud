#!/bin/bash

#날짜 포멧
DATE=$(date +%Y%m%d_%H%M)

#백업 파일명
BACK_FILE="mysql-backup-${DATE}.sql.gz"

#백업 진행및 용령절약을 위한 압축 진행
mysqldump -u std20 -pmelt7542 std20db | gzip > "/home/ubuntu/backup/${BACK_FILE}"

#s3 업로드
aws s3 cp ./backup/${BACK_FILE} s3://std20-mysql-backup-bucket/mysql/

#용량 최적화를 위해 업로드 후 원본 압축파일 삭제
rm -f ./backup/${BACK_FILE}

