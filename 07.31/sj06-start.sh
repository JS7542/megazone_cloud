#!/bin/bash

# 오류 발생 시 즉시 중단
set -e

# 패키지 설치 중 대화형 입력 방지
export DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------
# 1. 사용할 디스크와 파티션 번호
# ------------------------------------------------------------
DISKS=("nvme1n1" "nvme2n1")
PART_NUMBERS=("1" "2")

# 첫 번째 디스크: MySQL
MYSQL_LOG_BASE="/mnt/nvme1n1/data1"
MYSQL_DATA_BASE="/mnt/nvme1n1/data2"
MYSQL_LOG_DIR="${MYSQL_LOG_BASE}/log/mysql"
MYSQL_DATA_DIR="${MYSQL_DATA_BASE}/data/mysql"

# 두 번째 디스크: nginx
NGINX_LOG_BASE="/mnt/nvme2n1/data1"
NGINX_WEB_BASE="/mnt/nvme2n1/data2"
NGINX_LOG_DIR="${NGINX_LOG_BASE}/log/nginx"
NGINX_WEB_DIR="${NGINX_WEB_BASE}/www/nginx"

S3_URI="s3://bipa17-instructor-bucket/docker/"

# ------------------------------------------------------------
# 2. 디스크 작업에 필요한 패키지 설치
# ------------------------------------------------------------
sudo apt-get update
sudo apt-get install -y xfsprogs parted curl unzip rsync

# ------------------------------------------------------------
# 3. 디스크 확인, 파티션 생성, XFS 포맷, fstab 등록
# ------------------------------------------------------------
for disk in "${DISKS[@]}"; do
    DEVICE="/dev/${disk}"
    PART1="${DEVICE}p1"
    PART2="${DEVICE}p2"

    echo "[확인] ${DEVICE}"

    if [ -b "${DEVICE}" ]; then
        echo "${DEVICE} 장치를 확인했습니다."
    else
        echo "오류: ${DEVICE} 장치가 존재하지 않습니다."
        exit 1
    fi

    # p1과 p2가 모두 있으면 기존 파티션 사용
    if [ -b "${PART1}" ] && [ -b "${PART2}" ]; then
        echo "${DEVICE}에 기존 파티션 2개가 있습니다."

    # p1과 p2가 모두 없으면 새로 생성
    elif [ ! -b "${PART1}" ] && [ ! -b "${PART2}" ]; then
        echo "${DEVICE}에 파티션이 없어 새로 생성합니다."

        # p1은 5GiB, p2는 나머지 전체 공간 사용
        echo -e "g\nn\n\n\n\n+5G\nn\n\n\n\n\nw\n" | sudo fdisk "${DEVICE}"

        sudo partprobe "${DEVICE}"
        sudo udevadm settle

    # 파티션이 하나만 존재하는 비정상 상태에서는 중단
    else
        echo "오류: ${DEVICE}에 p1 또는 p2 중 하나만 존재합니다."
        echo "lsblk 명령으로 파티션 상태를 확인한 후 다시 실행하세요."
        exit 1
    fi

    # 각 디스크의 p1, p2를 반복 처리
    for part_number in "${PART_NUMBERS[@]}"; do
        PARTITION="${DEVICE}p${part_number}"
        MOUNT_DIR="/mnt/${disk}/data${part_number}"

        if [ -b "${PARTITION}" ]; then
            echo "${PARTITION} 파티션을 확인했습니다."
        else
            echo "오류: ${PARTITION} 파티션을 찾을 수 없습니다."
            exit 1
        fi

        # 파일시스템이 없을 때만 XFS로 포맷
        FILESYSTEM=$(sudo blkid -s TYPE -o value "${PARTITION}" 2>/dev/null || true)

        if [ -z "${FILESYSTEM}" ]; then
            echo "${PARTITION}을 XFS로 포맷합니다."
            sudo mkfs -t xfs "${PARTITION}"
        elif [ "${FILESYSTEM}" = "xfs" ]; then
            echo "${PARTITION}은 이미 XFS로 포맷되어 있습니다."
        else
            echo "오류: ${PARTITION}에 ${FILESYSTEM} 파일시스템이 존재합니다."
            echo "기존 데이터를 보호하기 위해 자동 포맷하지 않습니다."
            exit 1
        fi

        # 마운트 디렉토리 생성
        sudo mkdir -p "${MOUNT_DIR}"

        # UUID는 마운트 디렉토리가 아니라 파티션 장치에서 조회
        UUID_VALUE=$(sudo blkid -s UUID -o value "${PARTITION}")

        if [ -n "${UUID_VALUE}" ]; then
            echo "${PARTITION} UUID: ${UUID_VALUE}"
        else
            echo "오류: ${PARTITION}의 UUID를 가져오지 못했습니다."
            exit 1
        fi

        # 같은 UUID가 fstab에 없을 때만 추가
        if sudo grep -q "UUID=${UUID_VALUE}" /etc/fstab; then
            echo "${PARTITION}은 이미 /etc/fstab에 등록되어 있습니다."
        else
            echo "UUID=${UUID_VALUE}  ${MOUNT_DIR}  xfs  defaults,nofail  0  0" \
                | sudo tee -a /etc/fstab > /dev/null
            echo "${PARTITION}을 /etc/fstab에 등록했습니다."
        fi
    done
done

# fstab 반영 및 전체 마운트
sudo systemctl daemon-reload
sudo mount -a

# 모든 마운트 지점 확인
for disk in "${DISKS[@]}"; do
    for part_number in "${PART_NUMBERS[@]}"; do
        MOUNT_DIR="/mnt/${disk}/data${part_number}"

        if mountpoint -q "${MOUNT_DIR}"; then
            echo "마운트 성공: ${MOUNT_DIR}"
        else
            echo "오류: ${MOUNT_DIR} 마운트에 실패했습니다."
            exit 1
        fi
    done
done

# ------------------------------------------------------------
# 4. MySQL 설치
# ------------------------------------------------------------
sudo apt-get install -y mysql-server
sudo systemctl stop mysql

# MySQL 로그 디렉토리 생성
sudo mkdir -p "${MYSQL_LOG_DIR}"
sudo chmod 750 "${MYSQL_LOG_DIR}"
sudo chown mysql:adm "${MYSQL_LOG_DIR}"

# MySQL 데이터 디렉토리 생성
sudo mkdir -p "${MYSQL_DATA_DIR}"
sudo chmod 750 "${MYSQL_DATA_DIR}"
sudo chown mysql:mysql "${MYSQL_DATA_DIR}"

# 새 데이터 경로가 비어 있으면 기본 데이터 디렉토리 내용 복사
if [ -d "/var/lib/mysql/mysql" ] && [ ! -d "${MYSQL_DATA_DIR}/mysql" ]; then
    echo "MySQL 기본 데이터를 새 EBS 경로로 복사합니다."
    sudo rsync -aHAX /var/lib/mysql/ "${MYSQL_DATA_DIR}/"
    sudo chown -R mysql:mysql "${MYSQL_DATA_DIR}"
elif [ -d "${MYSQL_DATA_DIR}/mysql" ]; then
    echo "새 MySQL 데이터 경로에 기존 데이터가 있어 복사를 생략합니다."
else
    echo "오류: 복사할 MySQL 기본 데이터가 없습니다."
    exit 1
fi

# MySQL 경로 전용 설정 파일 생성
sudo tee /etc/mysql/mysql.conf.d/99-custom-storage.cnf > /dev/null <<EOF_MYSQL_CNF
[mysqld]
datadir = ${MYSQL_DATA_DIR}
log_error = ${MYSQL_LOG_DIR}/error.log
EOF_MYSQL_CNF

# AppArmor에 새 MySQL 데이터 및 로그 경로 허용
sudo mkdir -p /etc/apparmor.d/local

if sudo grep -q "${MYSQL_DATA_DIR}" /etc/apparmor.d/local/usr.sbin.mysqld 2>/dev/null; then
    echo "MySQL AppArmor 데이터 경로가 이미 등록되어 있습니다."
else
    sudo tee -a /etc/apparmor.d/local/usr.sbin.mysqld > /dev/null <<EOF_MYSQL_APPARMOR

${MYSQL_DATA_DIR}/ r,
${MYSQL_DATA_DIR}/** rwk,
${MYSQL_LOG_DIR}/ rw,
${MYSQL_LOG_DIR}/** rw,
EOF_MYSQL_APPARMOR
fi

sudo systemctl reload apparmor
sudo systemctl restart mysql

# MySQL 초기 계정 및 데이터베이스 생성
sleep 5

sudo mysql <<EOF_MYSQL_SQL
CREATE DATABASE IF NOT EXISTS testdb;
CREATE USER IF NOT EXISTS 'student'@'localhost' IDENTIFIED BY 'melt7542';
ALTER USER 'student'@'localhost' IDENTIFIED BY 'melt7542';
GRANT ALL PRIVILEGES ON *.* TO 'student'@'localhost';
FLUSH PRIVILEGES;
EOF_MYSQL_SQL

# ------------------------------------------------------------
# 5. nginx 설치 및 저장 경로 변경
# ------------------------------------------------------------
sudo apt-get install -y nginx
sudo systemctl stop nginx

# nginx 디렉토리 생성
sudo mkdir -p "${NGINX_LOG_DIR}"
sudo mkdir -p "${NGINX_WEB_DIR}"

sudo chmod 750 "${NGINX_LOG_DIR}"
sudo chmod 755 "${NGINX_WEB_DIR}"

sudo chown www-data:adm "${NGINX_LOG_DIR}"
sudo chown -R www-data:www-data "${NGINX_WEB_DIR}"

# nginx HTML 경로 변경
if sudo grep -q "/var/www/html" /etc/nginx/sites-available/default; then
    sudo sed -i "s|/var/www/html|${NGINX_WEB_DIR}|g" \
        /etc/nginx/sites-available/default
else
    echo "nginx HTML 경로는 이미 변경되었거나 기본 문자열이 없습니다."
fi

# nginx 로그 경로 변경
if sudo grep -q "/var/log/nginx" /etc/nginx/nginx.conf; then
    sudo sed -i "s|/var/log/nginx|${NGINX_LOG_DIR}|g" \
        /etc/nginx/nginx.conf
else
    echo "nginx 로그 경로는 이미 변경되었거나 기본 문자열이 없습니다."
fi

# nginx UTF-8 설정
sudo tee /etc/nginx/conf.d/charset.conf > /dev/null <<EOF_NGINX_CHARSET
charset utf-8;
EOF_NGINX_CHARSET

# ------------------------------------------------------------
# 6. AWS CLI 설치
# ------------------------------------------------------------
if command -v aws > /dev/null 2>&1; then
    echo "AWS CLI가 이미 설치되어 있습니다."
else
    echo "AWS CLI를 설치합니다."
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
        -o awscliv2.zip
    unzip -q awscliv2.zip
    sudo ./aws/install
    cd - > /dev/null
fi

# ------------------------------------------------------------
# 7. S3 웹 문서 동기화
# ------------------------------------------------------------
if aws s3 ls "${S3_URI}" > /dev/null 2>&1; then
    aws s3 sync "${S3_URI}" "${NGINX_WEB_DIR}/" --delete
    sudo chown -R www-data:www-data "${NGINX_WEB_DIR}"
else
    echo "오류: ${S3_URI}에 접근할 수 없습니다."
    echo "EC2 IAM 역할, S3 권한, NAT 또는 S3 Endpoint를 확인하세요."
    exit 1
fi

# nginx 설정 검사
sudo nginx -t

# 기존 기본 경로 정리
sudo rm -rf /var/log/nginx
sudo rm -f /var/www/html/*
sudo rm -rf /tmp/aws /tmp/awscliv2.zip

# 서비스 재시작
sudo systemctl restart nginx

# ------------------------------------------------------------
# 8. 설치 결과 확인
# ------------------------------------------------------------
SERVICES=("mysql" "nginx")

for service in "${SERVICES[@]}"; do
    if sudo systemctl is-active --quiet "${service}"; then
        echo "${service} 서비스가 정상 실행 중입니다."
    else
        echo "오류: ${service} 서비스가 실행되지 않았습니다."
        sudo systemctl status "${service}" --no-pager
        exit 1
    fi
done

echo "모든 작업이 완료되었습니다."