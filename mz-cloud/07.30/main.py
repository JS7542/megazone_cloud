import logging
import os
import time
from pathlib import Path

import pymysql
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


# =============================================================================
# 1. 기본 설정
# =============================================================================

APP_NAME = "std20-fastapi"

LOG_DIR = Path("/mnt/data2/fastapi/log")
ACCESS_LOG_PATH = LOG_DIR / "access.log"

# 로그 디렉터리가 없는 경우 생성
LOG_DIR.mkdir(parents=True, exist_ok=True)


# =============================================================================
# 2. 로깅 설정
# =============================================================================

logger = logging.getLogger(APP_NAME)
logger.setLevel(logging.INFO)
logger.propagate = False

# Uvicorn worker가 여러 번 로거를 초기화해도 핸들러가 중복되지 않도록 처리
if not logger.handlers:
    file_handler = logging.FileHandler(
        ACCESS_LOG_PATH,
        encoding="utf-8"
    )

    file_handler.setFormatter(
        logging.Formatter(
            "%(asctime)s - %(levelname)s - %(message)s"
        )
    )

    logger.addHandler(file_handler)


# =============================================================================
# 3. DB 환경변수
# =============================================================================

DB_HOST = os.getenv("DB_HOST", "10.0.11.146")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER", "student")
DB_PASSWORD = os.getenv("DB_PASSWORD", "melt7542")
DB_NAME = os.getenv("DB_NAME", "std20")


# =============================================================================
# 4. FastAPI 애플리케이션
# =============================================================================

app = FastAPI(
    title="std20 FastAPI",
    description="Nginx 및 Auto Scaling 연동 FastAPI 서버",
    version="1.0.0"
)


# =============================================================================
# 5. 접속자 로그 기록 미들웨어
# =============================================================================

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()

    # ALB 또는 프록시를 통과한 실제 클라이언트 IP 확인
    forwarded_for = request.headers.get("x-forwarded-for")

    if forwarded_for:
        client_host = forwarded_for.split(",")[0].strip()
    elif request.client:
        client_host = request.client.host
    else:
        client_host = "unknown"

    try:
        response = await call_next(request)

    except Exception as error:
        process_time = (time.time() - start_time) * 1000

        logger.exception(
            "Request failed | "
            f"Client: {client_host} | "
            f"Method: {request.method} | "
            f"Path: {request.url.path} | "
            f"Duration: {process_time:.2f}ms | "
            f"Error: {error}"
        )

        return JSONResponse(
            status_code=500,
            content={
                "status": "Failed",
                "message": "서버 내부 오류가 발생했습니다."
            }
        )

    process_time = (time.time() - start_time) * 1000

    logger.info(
        f"Client: {client_host} | "
        f"Method: {request.method} | "
        f"Path: {request.url.path} | "
        f"Status: {response.status_code} | "
        f"Duration: {process_time:.2f}ms"
    )

    return response


# =============================================================================
# 6. 기본 엔드포인트
# =============================================================================


# ALB 대상 그룹 헬스체크용
@app.get("/")
def health_check():
    return {
        "status": "healthy",
        "service": APP_NAME
    }


# =============================================================================
# 7. DB 연결 함수
# =============================================================================

def create_database_connection():
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        charset="utf8mb4",
        connect_timeout=5,
        read_timeout=5,
        write_timeout=5,
        autocommit=True,
        cursorclass=pymysql.cursors.DictCursor
    )


# =============================================================================
# 8. DB 연결 테스트
# =============================================================================

@app.get("/api/db-test")
def test_database_connection():
    connection = None

    try:
        connection = create_database_connection()

        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    DATABASE() AS db_name,
                    VERSION() AS version
                """
            )

            result = cursor.fetchone()

        logger.info(
            "Database connection success | "
            f"Host: {DB_HOST} | "
            f"Database: {result['db_name']} | "
            f"Version: {result['version']}"
        )

        return {
            "status": "Success",
            "message": "데이터베이스 연결에 성공했습니다.",
            "host": DB_HOST,
            "database": result["db_name"],
            "version": result["version"]
        }

    except pymysql.MySQLError as error:
        logger.error(
            "Database connection failed | "
            f"Host: {DB_HOST} | "
            f"Database: {DB_NAME} | "
            f"Error: {error}"
        )

        return JSONResponse(
            status_code=500,
            content={
                "status": "Failed",
                "message": "데이터베이스 연결에 실패했습니다.",
                "error": str(error)
            }
        )

    finally:
        if connection is not None:
            connection.close()


# =============================================================================
# 9. tquize 테이블 전체 조회
# =============================================================================

@app.get("/api/quiz")
def read_quiz_answers():
    connection = None

    try:
        connection = create_database_connection()

        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    idx,
                    answer
                FROM tquize
                ORDER BY idx ASC
                """
            )

            rows = cursor.fetchall()

        logger.info(
            "Quiz data read success | "
            f"Database: {DB_NAME} | "
            f"Count: {len(rows)}"
        )

        return {
            "status": "Success",
            "count": len(rows),
            "data": rows
        }

    except pymysql.MySQLError as error:
        logger.error(
            "Quiz data read failed | "
            f"Database: {DB_NAME} | "
            f"Table: tquize | "
            f"Error: {error}"
        )

        return JSONResponse(
            status_code=500,
            content={
                "status": "Failed",
                "message": "퀴즈 데이터 조회에 실패했습니다.",
                "error": str(error)
            }
        )

    finally:
        if connection is not None:
            connection.close()


# =============================================================================
# 10. 특정 퀴즈 정답 조회
# =============================================================================

@app.get("/api/quiz/{idx}")
def read_quiz_answer(idx: int):
    connection = None

    try:
        connection = create_database_connection()

        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    idx,
                    answer
                FROM tquize
                WHERE idx = %s
                """,
                (idx,)
            )

            row = cursor.fetchone()

        if row is None:
            return JSONResponse(
                status_code=404,
                content={
                    "status": "Failed",
                    "message": "해당 번호의 퀴즈가 존재하지 않습니다.",
                    "idx": idx
                }
            )

        return {
            "status": "Success",
            "data": row
        }

    except pymysql.MySQLError as error:
        logger.error(
            "Quiz answer read failed | "
            f"Index: {idx} | "
            f"Error: {error}"
        )

        return JSONResponse(
            status_code=500,
            content={
                "status": "Failed",
                "message": "퀴즈 정답 조회에 실패했습니다.",
                "error": str(error)
            }
        )

    finally:
        if connection is not None:
            connection.close()