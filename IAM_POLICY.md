# AWS IAM Policy for Infisical Backup

## Required IAM Permissions

Create an IAM user with the following policy to enable database backups to S3:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "InfisicalBackupS3Access",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::YOUR_BUCKET_NAME/*",
                "arn:aws:s3:::YOUR_BUCKET_NAME"
            ]
        }
    ]
}
```

## Setup Instructions

1. **Create S3 Bucket**:
   ```bash
   aws s3 mb s3://YOUR_BUCKET_NAME --region us-east-1
   ```

2. **Create IAM User**:
   ```bash
   aws iam create-user --user-name infisical-backup
   ```

3. **Create Access Key**:
   ```bash
   aws iam create-access-key --user-name infisical-backup
   ```
   Save the `AccessKeyId` and `SecretAccessKey` for the `.env` file.

4. **Attach Policy**:
   Create a file `infisical-backup-policy.json` with the above policy (replace `YOUR_BUCKET_NAME`), then:
   ```bash
   aws iam put-user-policy \
     --user-name infisical-backup \
     --policy-name InfisicalBackupPolicy \
     --policy-document file://infisical-backup-policy.json
   ```

## S3 Bucket Structure

The backup container will create the following structure:
```
s3://YOUR_BUCKET_NAME/
├── backups/
│   ├── infisical_backup_20240115_020000.sql.gz
│   ├── infisical_backup_20240116_020000.sql.gz
│   └── ...
└── config/
    └── .env  # Your encrypted environment file
```

## Security Recommendations

1. **Enable S3 Versioning**:
   ```bash
   aws s3api put-bucket-versioning \
     --bucket YOUR_BUCKET_NAME \
     --versioning-configuration Status=Enabled
   ```

2. **Enable S3 Server-Side Encryption** (already configured in backup script with `--sse AES256`)

3. **Set S3 Lifecycle Policy** for automated retention:
   ```json
   {
       "Rules": [
           {
               "Id": "DeleteOldBackups",
               "Status": "Enabled",
               "Expiration": {
                   "Days": 90
               },
               "NoncurrentVersionExpiration": {
                   "NoncurrentDays": 30
               }
           }
       ]
   }
   ```

4. **Restrict IAM User Access**:
   - Use IAM roles if running on EC2/ECS
   - Rotate access keys regularly
   - Monitor access with CloudTrail

## Environment Variables

Add these to your `.env` file:
```bash
# AWS S3 Backup Configuration
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
AWS_REGION=us-east-1
S3_BUCKET=your-infisical-backup-bucket
DELETE_OLD_BACKUPS=true
TZ=UTC
```