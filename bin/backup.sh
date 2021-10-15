#!/bin/sh

set -e
set -o pipefail

>&2 echo "------------------------------------------------------------"

# 1. Validade environment variables
if [ -z "${S3_BACKUP}" ]; then
  echo "You need to set the S3_BACKUP environment variable."
  exit 1
fi

if [ -z "${KEEP_LOCAL_DUMP}" ]; then
  echo "You need to set the KEEP_LOCAL_DUMP environment variable."
  exit 1
fi

if [ -z "${POSTGRES_DATABASE}" ]; then
  echo "You need to set the POSTGRES_DATABASE environment variable."
  exit 1
fi

if [ -z "${POSTGRES_HOST}" ]; then
  echo "You need to set the POSTGRES_HOST environment variable."
  exit 1
fi

if [ -z "${POSTGRES_USERNAME}" ]; then
  echo "You need to set the POSTGRES_USERNAME environment variable."
  exit 1
fi

if [ -z "${POSTGRES_PASSWORD}" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable or link to a container named POSTGRES."
  exit 1
fi

if [ "${S3_BACKUP}" != "yes" -a "${KEEP_LOCAL_DUMP}" != "yes" ]; then
  echo "At least one way of backup must be 'yes', S3_BACKUP or KEEP_LOCAL_DUMP."
  exit 1
fi

# 2. Create dump
export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"

SOURCE_FILE=dump.sql.gz
DEST_FILE=${POSTGRES_DATABASE}_$(date +"%Y%m%d%H%M%S").sql.gz
DATE_PATH=$(date +"%Y/%m")

if [ "${POSTGRES_DATABASE}" == "all" ]; then
  echo "Creating dump of all databases from ${POSTGRES_HOST}..."
  pg_dumpall $POSTGRES_HOST_OPTS | gzip > $SOURCE_FILE
else
  echo "Creating dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..."
  pg_dump $POSTGRES_HOST_OPTS $POSTGRES_DATABASE | gzip > $SOURCE_FILE
fi

# 3. Encrypt compressed dump, if needed
if [ -n "${ENCRYPTION_PASSWORD}" ]; then
  >&2 echo "Encrypting ${SOURCE_FILE}"

  openssl enc -aes-256-cbc -in $SOURCE_FILE -out ${SOURCE_FILE}.enc -k $ENCRYPTION_PASSWORD
  
  if [ $? != 0 ]; then
    >&2 echo "Error encrypting ${SOURCE_FILE}"
  fi
  
  rm $SOURCE_FILE
  SOURCE_FILE="${SOURCE_FILE}.enc"
  DEST_FILE="${DEST_FILE}.enc"
fi

# 4. Create a local copy, if needed
if [ "${KEEP_LOCAL_DUMP}" == "yes" ]; then
  echo "Creating a local copy..."

  mkdir -p /var/backups/$DATE_PATH

  cp $SOURCE_FILE /var/backups/$DATE_PATH/$DEST_FILE
fi

# 5. Backup on S3, if needed
if [ "${S3_BACKUP}" == "yes" ]; then
  if [ -z "${S3_ACCESS_KEY_ID}" ]; then
    echo "You need to set the S3_ACCESS_KEY_ID environment variable."
    exit 1
  fi

  if [ -z "${S3_SECRET_ACCESS_KEY}" ]; then
    echo "You need to set the S3_SECRET_ACCESS_KEY environment variable."
    exit 1
  fi

  if [ -z "${S3_BUCKET}" ]; then
    echo "You need to set the S3_BUCKET environment variable."
    exit 1
  fi

  if [ -n "${S3_ENDPOINT}" ]; then
    AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
  else
    AWS_ARGS=""
  fi

  export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION=$S3_REGION

  echo "Uploading dump to $S3_BUCKET..."

  if [ -n "${S3_PREFIX}" ]; then
    aws $AWS_ARGS s3 cp $SOURCE_FILE s3://$S3_BUCKET/$S3_PREFIX/$DATE_PATH/$DEST_FILE || exit 2
  else
    aws $AWS_ARGS s3 cp $SOURCE_FILE s3://$S3_BUCKET/$DATE_PATH/$DEST_FILE || exit 2
  fi
fi

echo "Backup finished!"