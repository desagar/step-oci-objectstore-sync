#!/bin/bash

CONFIG_FILE="$HOME/.oci/config"
set_auth() {
  local key_file="$HOME/.oci/api_key.pem"

  mkdir -p $HOME/.oci

  if [ -e "$CONFIG_FILE" ]; then
    warn 'OCI config file already exists in home directory and will be overwritten'
  fi

  #Write the key to a file
  echo "${WERCKER_OCI_OBJECTSTORE_SYNC_API_KEY}" > $key_file
 
  echo '[DEFAULT]' > "$CONFIG_FILE"
  echo "user=${WERCKER_OCI_OBJECTSTORE_SYNC_USER_OCID}" >> "$CONFIG_FILE"
  echo "fingerprint=${WERCKER_OCI_OBJECTSTORE_SYNC_TENANCY_OCID}" >> "$CONFIG_FILE"
  echo "fingerprint=${WERCKER_OCI_OBJECTSTORE_SYNC_FINGERPRINT}" >> "$CONFIG_FILE"
  echo "region=${WERCKER_OCI_OBJECTSTORE_SYNC_REGION}" >> "$CONFIG_FILE"
  echo "key_file=${key_file}" >> "$CONFIG_FILE"

  debug "generated OCI config file"
}

main() {
  set_auth

  info 'starting s3 synchronisation'

  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_USER_OCID" ]; then
    fail 'missing or empty option user_ocid, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_TENANCY_OCID" ]; then
    fail 'missing or empty option tenancy_ocid, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_FINGERPRINT" ]; then
    fail 'missing or empty option fingerprint, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_REGION" ]; then
    fail 'missing or empty option region, please check wercker.yml'
  fi

#TODO should we check for key? if it is a public bucket do they still need a key?
  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_API_KEY" ]; then
    fail 'missing or empty option api_key, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_BUCKET_NAME" ]; then
    fail 'missing or empty option bucket_name, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_NAMESPACE" ]; then
    fail 'missing or empty option namespace, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_FILE" ]; then
    fail 'missing or empty option file, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_OBJECT_NAME" ]; then
    fail 'missing or empty option object_name, please check wercker.yml'
  fi

  if [[ ! -e $WERCKER_OCI_OBJECTSTORE_SYNC_FILE || ! -r $WERCKER_OCI_OBJECTSTORE_SYNC_FILE ]] ; then
    fail 'specified file does not exist or is not readable'
  fi

#  if [ ! -n "$WERCKER_S3SYNC_OPTS" ]; then
#    export WERCKER_S3SYNC_OPTS="--acl-public"
#  fi

#  source_dir="$WERCKER_ROOT/$WERCKER_S3SYNC_SOURCE_DIR"
#  if cd "$source_dir";
#  then
#      debug "changed directory $source_dir, content is: $(ls -l)"
#  else
#      fail "unable to change directory to $source_dir"
#  fi

  set +e
  local SYNC="oci --config-file $CONFIG_FILE os object put --namespace $WERCKER_OCI_OBJECTSTORE_SYNC_NAMESPACE --bucket-name WERCKER_OCI_OBJECTSTORE_SYNC_BUCKET_NAME --name $WERCKER_OBJECTSTORE_SYNC_OBJECT_NAME --file $WERCKER_OBJECTSTORE_SYNC_FILE"

  #local SYNCPUT="oci --config-file ~/.oci/config os object put --namespace odx-pipelines --bucket-name grappler-testing --name devausingcli.txt --file $TODO_FILE_TO_PUT"
  #local SYNCGET="oci --config-file $TODO_CONFIG_FILE os object get --namespace odx-pipelines --bucket-name grappler-testing --name tmp.json --file $TODO_OUTPUT_FILE"
#"$WERCKER_STEP_ROOT/s3cmd sync $WERCKER_S3SYNC_OPTS $WERCKER_S3SYNC_DELETE_REMOVED --verbose ./ $WERCKER_S3SYNC_BUCKET_URL"
  debug "$SYNC"
  echo "not running"
  #local sync_output=$($SYNC)

  if [[ $? -ne 0 ]];then
      echo "$sync_output"
      fail 'oci os put failed';
  else
      echo "$sync_output"
      success 'finished oci object store synchronisation';
  fi
  set -e
}

main
