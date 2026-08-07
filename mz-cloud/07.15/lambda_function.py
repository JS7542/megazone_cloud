import json, boto3, os, pymysql
from botocore.exceptions import ClientError


def lambda_handler(event, context):
    try:
        # 변수 설정 부분========================

        #1.환경변수에서 자료 읽어오기
        secret_name = os.environ['SECRET_NAME']
        secret_region = os.environ['SECRET_REGION']
        host = os.environ['DB_HOST']
        db=os.environ['DB_NAME']
        port=os.environ['DB_PORT']

        #1.Secret Manager에서 ID/PW 가져오기
        session = boto3.session.Session()
        client = session.client(
            service_name='secretsmanager',
            region_name=secret_region
        )
        get_secret_value = client.get_secret_value(SecretId=secret_name)
        secrets = get_secrets()

        user = secrets['username']
        password = secrets['password'] 
        #======================================

        connection = pymysql.connect(
            host=host,
            user=user,
            password=password,
            database=db,
            port=int(port), #기본 포트 3306 을 사용할 경우 생략이 가능하다.
            cursorclass=pymysql.cursors.DictCursor,
            connect_timeout=5
        )

    return {
        'statusCode': 200,
        'body': json.dumps({
            'status': 'success',
            'message': '데이터베이스 서버 연결되었습니다.'

        })
    }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'status': 'error',
                'message': str(e)
            })
        }
    connection.close()