import os
from contextlib import contextmanager
from typing import List

import pymysql
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field


# ============================================================
# FastAPI
# 외부: /api/...
# Nginx: location /api/ { proxy_pass http://my-app:8000/; }
# FastAPI 내부에서는 /api prefix가 제거되어 들어옴
# ============================================================
app = FastAPI(
    title="Student Score API",
    description="TMEMBER / TTEST 기반 성적 관리 API",
    version="1.0.0",
    root_path="/api",
)


# ============================================================
# DB 환경변수
# ============================================================
DB_CONFIG = {
    "host": os.getenv("DB_HOST"),
    "port": int(os.getenv("DB_PORT", "3306")),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME"),
    "charset": "utf8mb4",
    "cursorclass": pymysql.cursors.DictCursor,
    "connect_timeout": int(os.getenv("DB_TIMEOUT", "5")),
    "autocommit": False,
}


@contextmanager
def get_db():
    """
    요청마다 DB 연결을 생성하고 종료한다.
    실습 규모에서는 단순하고 확인하기 쉬운 방식.
    """
    conn = None

    try:
        conn = pymysql.connect(**DB_CONFIG)
        yield conn
    except pymysql.MySQLError as exc:
        if conn:
            conn.rollback()

        print(f"[DB ERROR] {exc}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database operation failed",
        )
    finally:
        if conn:
            conn.close()


# ============================================================
# Pydantic Models
# ============================================================
class ScoreCreate(BaseModel):
    fid: str = Field(..., min_length=1, max_length=12)
    kor: int = Field(..., ge=0, le=100)
    eng: int = Field(..., ge=0, le=100)
    mat: int = Field(..., ge=0, le=100)


class ScoreUpdate(BaseModel):
    fid: str = Field(..., min_length=1, max_length=12)
    kor: int = Field(..., ge=0, le=100)
    eng: int = Field(..., ge=0, le=100)
    mat: int = Field(..., ge=0, le=100)


class BulkDeleteRequest(BaseModel):
    fidx_list: List[int]


# ============================================================
# Health Check
# ============================================================
@app.get("/health")
def health():
    """
    ALB / Docker health check용.
    DB 상태와 무관하게 FastAPI 프로세스가 살아있는지만 확인.
    """
    return {
        "status": "ok",
        "service": "fastapi",
    }


@app.get("/db-check")
def db_check():
    """
    MySQL 연결 확인용.
    """
    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute("SELECT 1 AS db_status")
            result = cursor.fetchone()

    return {
        "status": "success",
        "database": "connected",
        "result": result["db_status"],
    }


# ============================================================
# 교육생 목록
# HTML: #uid select / #btnReload
# 외부 요청: GET /api/students
# ============================================================
@app.get("/students")
def get_students():
    sql = """
        SELECT
            fid,
            fname,
            fgender
        FROM TMEMBER
        ORDER BY fid ASC
    """

    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()

    return {
        "status": "success",
        "count": len(rows),
        "data": rows,
    }


# ============================================================
# 전체 성적 목록
# HTML: #btnLoding / #resultArea
# 외부 요청: GET /api/scores
#
# VRESULT에는 fidx가 없으므로 수정/삭제용 PK를 확보하기 위해
# TTEST + TMEMBER를 직접 JOIN한다.
# ============================================================
@app.get("/scores")
def get_scores():
    sql = """
        SELECT
            a.fidx,
            a.fid,
            b.fname,
            b.fgender,
            a.fkor AS kor,
            a.feng AS eng,
            a.fmat AS mat,
            (a.fkor + a.feng + a.fmat) AS total,
            ROUND((a.fkor + a.feng + a.fmat) / 3, 1) AS average,
            DATE_FORMAT(a.fdate, '%Y-%m-%d %H:%i:%s') AS test_date
        FROM TTEST AS a
        LEFT JOIN TMEMBER AS b
            ON a.fid = b.fid
        ORDER BY a.fidx DESC
    """

    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()

    return {
        "status": "success",
        "count": len(rows),
        "data": rows,
    }


# ============================================================
# 단일 성적 조회
# 테이블의 '작업' 버튼에서 수정할 데이터를 폼에 채울 때 사용 가능
# 외부 요청: GET /api/scores/{fidx}
# ============================================================
@app.get("/scores/{fidx}")
def get_score(fidx: int):
    sql = """
        SELECT
            a.fidx,
            a.fid,
            b.fname,
            b.fgender,
            a.fkor AS kor,
            a.feng AS eng,
            a.fmat AS mat,
            (a.fkor + a.feng + a.fmat) AS total,
            ROUND((a.fkor + a.feng + a.fmat) / 3, 1) AS average,
            DATE_FORMAT(a.fdate, '%%Y-%%m-%%d %%H:%%i:%%s') AS test_date
        FROM TTEST AS a
        LEFT JOIN TMEMBER AS b
            ON a.fid = b.fid
        WHERE a.fidx = %s
    """

    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute(sql, (fidx,))
            row = cursor.fetchone()

    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Score not found",
        )

    return {
        "status": "success",
        "data": row,
    }


# ============================================================
# 성적 등록
# HTML: #btnLogin
# 외부 요청: POST /api/scores
#
# JSON 예:
# {
#   "fid": "mzc-000",
#   "kor": 90,
#   "eng": 80,
#   "mat": 70
# }
# ============================================================
@app.post("/scores", status_code=status.HTTP_201_CREATED)
def create_score(score: ScoreCreate):

    # 1. 교육생 존재 여부 확인
    check_student_sql = """
        SELECT COUNT(*) AS cnt
        FROM TMEMBER
        WHERE fid = %s
    """

    # 2. 이미 성적이 등록되어 있는지 확인
    check_score_sql = """
        SELECT COUNT(*) AS cnt
        FROM TTEST
        WHERE fid = %s
    """

    # 3. 성적 등록
    insert_sql = """
        INSERT INTO TTEST (
            fid,
            fkor,
            feng,
            fmat,
            fdate
        )
        VALUES (%s, %s, %s, %s, NOW())
    """

    with get_db() as conn:
        with conn.cursor() as cursor:

            # 교육생 확인
            cursor.execute(check_student_sql, (score.fid,))
            student_exists = cursor.fetchone()["cnt"]

            if student_exists == 0:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="존재하지 않는 교육생입니다."
                )

            # 이미 성적이 있는지 확인
            cursor.execute(check_score_sql, (score.fid,))
            score_exists = cursor.fetchone()["cnt"]

            if score_exists > 0:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="성적이 이미 입력되어 있습니다."
                )

            # 성적 등록
            cursor.execute(
                insert_sql,
                (
                    score.fid,
                    score.kor,
                    score.eng,
                    score.mat,
                ),
            )

            new_fidx = cursor.lastrowid
            conn.commit()

    return {
        "status": "success",
        "message": "성적이 등록되었습니다.",
        "fidx": new_fidx,
    }


# ============================================================
# 성적 수정
# HTML: hidden #idx + #btnChoEdit
# 외부 요청: PUT /api/scores/{fidx}
# ============================================================
@app.put("/scores/{fidx}")
def update_score(fidx: int, score: ScoreUpdate):
    check_student_sql = """
        SELECT COUNT(*) AS cnt
        FROM TMEMBER
        WHERE fid = %s
    """

    update_sql = """
        UPDATE TTEST
        SET
            fid = %s,
            fkor = %s,
            feng = %s,
            fmat = %s,
            fdate = NOW()
        WHERE fidx = %s
    """

    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute(check_student_sql, (score.fid,))
            exists = cursor.fetchone()["cnt"]

            if exists == 0:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Student not found",
                )

            cursor.execute(
                update_sql,
                (
                    score.fid,
                    score.kor,
                    score.eng,
                    score.mat,
                    fidx,
                ),
            )

            if cursor.rowcount == 0:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Score not found",
                )

            conn.commit()

    return {
        "status": "success",
        "message": "성적이 수정되었습니다.",
        "fidx": fidx,
    }


# ============================================================
# 단일 성적 삭제
# 테이블의 개별 삭제 버튼용
# 외부 요청: DELETE /api/scores/{fidx}
# ============================================================
@app.delete("/scores/{fidx}")
def delete_score(fidx: int):
    sql = """
        DELETE FROM TTEST
        WHERE fidx = %s
    """

    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute(sql, (fidx,))

            if cursor.rowcount == 0:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Score not found",
                )

            conn.commit()

    return {
        "status": "success",
        "message": "성적이 삭제되었습니다.",
        "fidx": fidx,
    }


# ============================================================
# 성적 일괄 삭제
# HTML: checkbox + #btnChoDel
# 외부 요청: DELETE /api/scores
#
# JSON 예:
# {
#   "fidx_list": [1, 2, 3]
# }
# ============================================================
@app.delete("/scores")
def bulk_delete_scores(request: BulkDeleteRequest):
    if not request.fidx_list:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="삭제할 성적을 선택하세요.",
        )

    placeholders = ",".join(["%s"] * len(request.fidx_list))

    sql = f"""
        DELETE FROM TTEST
        WHERE fidx IN ({placeholders})
    """

    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute(sql, tuple(request.fidx_list))
            deleted_count = cursor.rowcount
            conn.commit()

    return {
        "status": "success",
        "message": f"{deleted_count}개의 성적이 삭제되었습니다.",
        "deleted_count": deleted_count,
    }
