#!/bin/bash
set -eux

# ============================================================
# 실습 환경 변수
# ============================================================

REGION="ap-east-1"

# Manager 고정 Private IP
MANAGER_IP="10.0.11.74"

# Manager에서 확인한 Worker Token 복붙
WORKER_TOKEN="SWMTKN-1-43nt5qyikffrjt7kmt13lkirlxicpld1ljh1s6fiuan3qoto1l-7w7jch58ayutf4ao1yn5u9zgq"

# ECR
ACCOUNT_ID=$(aws sts get-caller-identity \
  --query Account \
  --output text)

ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

NGINX_IMAGE="${ECR}/bipa17-std20/nginx:v2"
FASTAPI_IMAGE="${ECR}/bipa17-std20/fastapi:v2"


# ============================================================
# 로그
# ============================================================

exec > >(tee -a /var/log/worker-userdata.log) 2>&1

echo "=========================================="
echo " Swarm Worker UserData Start"
echo "=========================================="


# ============================================================
# 1. Docker 시작
# ============================================================

systemctl enable docker
systemctl start docker


# ============================================================
# 2. ECR 로그인
# ============================================================

aws ecr get-login-password \
  --region ${REGION} \
| docker login \
  --username AWS \
  --password-stdin ${ECR}


# ============================================================
# 3. 이미지 미리 Pull
# 필수는 아니지만 실습에서는 확인하기 편함
# ============================================================

docker pull ${NGINX_IMAGE}
docker pull ${FASTAPI_IMAGE}


# ============================================================
# 4. 이미 Swarm 가입 상태인지 확인
# ============================================================

SWARM_STATE=$(docker info \
  --format '{{.Swarm.LocalNodeState}}' \
  2>/dev/null || echo "inactive")


# ============================================================
# 5. Swarm Worker 자동 가입
# ============================================================

if [ "$SWARM_STATE" != "active" ]; then

    # Manager가 아직 준비 안 됐을 수도 있으므로 재시도
    for i in $(seq 1 30)
    do

        echo "Swarm Join Attempt: ${i}"

        if docker swarm join \
          --token "${WORKER_TOKEN}" \
          "${MANAGER_IP}:2377"
        then
            echo "Swarm Join Success"
            break
        fi

        sleep 10

    done

else

    echo "Already joined Swarm"

fi


# ============================================================
# 6. 최종 상태
# ============================================================

docker info | grep -A 10 Swarm || true

echo "=========================================="
echo " Swarm Worker UserData Complete"
echo "=========================================="