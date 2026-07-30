import time
import logging
import pymysql

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


# 1. 로깅 설정
logging.basicConfig(
    filename="/opt/mysql-test/access.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)

logger = logging.getLogger("access_logger")

app = FastAPI()


# 2. 접속자 로그 기록 미들웨어
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()

    client_host = request.client.host if request.client else "unknown"

    response = await call_next(request)

    process_time = (time.time() - start_time) * 1000

    log_msg = (
        f"Client: {client_host} | "
        f"Method: {request.method} | "
        f"Path: {request.url.path} | "
        f"Status: {response.status_code} | "
        f"Duration: {process_time:.2f}ms"
    )

    logger.info(log_msg)

    return response


# =====================================================================================================================
# 3. 엔드포인트

@app.get("/")
def read_root():
    return {
        "message": "FastAPI server is running"
    }


@app.get("/items/{item_id}")
def read_item(item_id: int, q: str = None):
    return {
        "item_id": item_id,
        "q": q
    }


@app.get("/api/db-test")
def test_database_connection():
    connection = None

    try:
        connection = pymysql.connect(
            host="127.0.0.1",
            port=3306,
            user="student",
            password="melt7542",
            database="testdb",
            charset="utf8mb4",
            connect_timeout=5,
            cursorclass=pymysql.cursors.DictCursor
        )

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT DATABASE() AS db_name, VERSION() AS version"
            )
            result = cursor.fetchone()

        logger.info(
            f"MySQL connection success | "
            f"Database: {result['db_name']} | "
            f"Version: {result['version']}"
        )

        return {
            "status": "Success",
            "message": "MySQL 데이터베이스 연결에 성공했습니다.",
            "database": result["db_name"],
            "version": result["version"]
        }

    except pymysql.MySQLError as error:
        logger.error(
            f"MySQL connection failed | Error: {error}"
        )

        return JSONResponse(
            status_code=500,
            content={
                "status": "Failed",
                "message": "MySQL 데이터베이스 연결에 실패했습니다.",
                "error": str(error)
            }
        )

    finally:
        if connection is not None:
            connection.close()