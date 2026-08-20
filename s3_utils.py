import os
import uuid
from fastapi import UploadFile, HTTPException

def upload_file_to_s3(file: UploadFile, folder: str = "documents") -> str:
    bucket_name = os.getenv('AWS_STORAGE_BUCKET_NAME')
    region = os.getenv('AWS_S3_REGION_NAME')
    access_key = os.getenv('AWS_ACCESS_KEY_ID')
    secret_key = os.getenv('AWS_SECRET_ACCESS_KEY')

    file_extension = file.filename.split('.')[-1].lower() if file.filename and '.' in file.filename else 'jpg'
    if file_extension not in ['jpg', 'jpeg', 'png', 'pdf']:
        raise HTTPException(status_code=400, detail="Doar PDF, JPG sau PNG.")

    unique_filename = f"{folder}/{uuid.uuid4()}.{file_extension}"

    if bucket_name and access_key and secret_key:
        try:
            import boto3
            s3_client = boto3.client(
                's3',
                aws_access_key_id=access_key,
                aws_secret_access_key=secret_key,
                region_name=region or 'eu-central-1'
            )
            s3_client.upload_fileobj(
                file.file,
                bucket_name,
                unique_filename,
                ExtraArgs={"ContentType": file.content_type or "image/jpeg"}
            )
            return f"https://{bucket_name}.s3.{region or 'eu-central-1'}.amazonaws.com/{unique_filename}"
        except Exception as e:
            print(f"S3 upload error, saving locally fallback: {e}")

    # Fallback local upload directory
    upload_dir = os.path.join("uploads", folder)
    os.makedirs(upload_dir, exist_ok=True)
    local_path = os.path.join(upload_dir, f"{uuid.uuid4()}.{file_extension}")
    with open(local_path, "wb") as buffer:
        buffer.write(file.file.read())

    return f"/{local_path}"
