import os
import boto3
import uuid
from fastapi import UploadFile, HTTPException

def upload_file_to_s3(file: UploadFile, folder: str = "documents") -> str:

    bucket_name = os.getenv('AWS_STORAGE_BUCKET_NAME')
    region = os.getenv('AWS_S3_REGION_NAME')
    
    file_extension = file.filename.split('.')[-1].lower()
    if file_extension not in ['jpg', 'jpeg', 'png', 'pdf']:
        raise HTTPException(status_code=400, detail="Doar PDF, JPG sau PNG.")
    
    # creare nume unic
    unique_filename = f"{folder}/{uuid.uuid4()}.{file_extension}"
    
    try:
        # urcare fisier
        s3_client = boto3.client(
            's3',
            aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
            aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
            region_name=region
        )
        s3_client.upload_fileobj(
            file.file,
            bucket_name,
            unique_filename,
            ExtraArgs={"ContentType": file.content_type}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Eroare la AWS S3: {str(e)}")
    
    # link ul care ajunge in baza de date 
    return f"https://{bucket_name}.s3.{region}.amazonaws.com/{unique_filename}"