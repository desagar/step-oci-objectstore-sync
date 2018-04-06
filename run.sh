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
  echo "tenancy=${WERCKER_OCI_OBJECTSTORE_SYNC_TENANCY_OCID}" >> "$CONFIG_FILE"
  echo "fingerprint=${WERCKER_OCI_OBJECTSTORE_SYNC_FINGERPRINT}" >> "$CONFIG_FILE"
  echo "region=${WERCKER_OCI_OBJECTSTORE_SYNC_REGION}" >> "$CONFIG_FILE"
  echo "key_file=${key_file}" >> "$CONFIG_FILE"

  debug "generated OCI config file"
}

validate_oci_flags() {
  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_TENANCY_OCID" ]; then
    fail 'missing or empty option tenancy_ocid, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_USER_OCID" ]; then
    fail 'missing or empty option user_ocid, please check wercker.yml'
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
}

set_overwrite_flag() {
  if [[ "$WERCKER_OCI_OBJECTSTORE_SYNC_OVERWRITE" == "true" || "$WERCKER_OCI_OBJECTSTORE_SYNC_OVERWRITE" == "TRUE" ]]; then
    OVERWRITE_FLAG="--overwrite"
  else
    OVERWRITE_FLAG="--no-overwrite"
  fi
}

get_bulk_upload_cmd() {
  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_DIR" ]; then
    fail 'missing or empty option local_dir, please check wercker.yml'
  fi

  if [[ ! -d $WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_DIR || -L $WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_DIR ]] ; then
    fail 'specified local directory does not exist or is not readable'
  fi

  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_PREFIX" ]; then
    WERCKER_OCI_OBJECTSTORE_SYNC_PREFIX="$(basename $WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_DIR)/"
  fi

  set +e
  echo "$WERCKER_STEP_ROOT/oci --config-file $CONFIG_FILE os object bulk-upload $WERCKER_OCI_OBJECTSTORE_SYNC_OPTIONS --namespace $WERCKER_OCI_OBJECTSTORE_SYNC_NAMESPACE --bucket-name $WERCKER_OCI_OBJECTSTORE_SYNC_BUCKET_NAME --src-dir $WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_DIR --object-prefix $WERCKER_OCI_OBJECTSTORE_SYNC_PREFIX"
}

get_bulk_download_cmd() {
  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_DIR" ]; then
    fail 'missing or empty option local_dir, please check wercker.yml'
  fi

  if [[ ! -d $WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_DIR || -L $WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_DIR  || ! -w $WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_DIR ]] ; then
    fail 'specified local directory does not exist or is not writable'
  fi

  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_PREFIX" ]; then
    WERCKER_OCI_OBJECTSTORE_SYNC_PREFIX="$(basename $WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_DIR)/"
  fi

  if [ -n "$WERCKER_OCI_OBJECTSTORE_SYNC_PREFIX" ]; then
    WERCKER_OCI_OBJECTSTORE_SYNC_OPTIONS="$WERCKER_OCI_OBJECTSTORE_SYNC_OPTIONS --prefix ""$WERCKER_OCI_OBJECTSTORE_SYNC_PREFIX"""
  fi

  set +e
  echo "$WERCKER_STEP_ROOT/oci --config-file $CONFIG_FILE os object bulk-download $WERCKER_OCI_OBJECTSTORE_SYNC_OPTIONS -ns $WERCKER_OCI_OBJECTSTORE_SYNC_NAMESPACE -bn $WERCKER_OCI_OBJECTSTORE_SYNC_BUCKET_NAME --download-dir $WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_DIR"

}

get_single_file_upload_cmd() {
  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_FILE" ]; then
    fail 'missing or empty option local_file is required for uploading a single file, please check wercker.yml'
  fi

  if [[ ! -f $WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_FILE || ! -r $WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_FILE ]] ; then
    fail 'specified local_file must be a regular file and must be readable'
  fi

  #default the object name to the same as the file's basename
  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_OBJECT_NAME" ]; then
    WERCKER_OCI_OBJECTSTORE_SYNC_OBJECT_NAME="$(basename $WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_FILE)"
  fi

  set +e
  echo "$WERCKER_STEP_ROOT/oci --config-file $CONFIG_FILE os object put $WERCKER_OCI_OBJECTSTORE_SYNC_OPTIONS -ns $WERCKER_OCI_OBJECTSTORE_SYNC_NAMESPACE -bn $WERCKER_OCI_OBJECTSTORE_SYNC_BUCKET_NAME --file $WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_FILE"
}

get_single_file_download_cmd() {
  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_OBJECT_NAME" ]; then
    fail 'missing or empty option object_name is required for downloading a single object, please check wercker.yml'
  fi

  #default the local file name to the same as the object name
  if [ ! -n "$WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_FILE" ]; then
    WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_FILE="$WERCKER_OCI_OBJECTSTORE_SYNC_OBJECT_NAME"
  fi

  set +e
  echo "$WERCKER_STEP_ROOT/oci --config-file $CONFIG_FILE os object get $WERCKER_OCI_OBJECTSTORE_SYNC_OPTIONS -ns $WERCKER_OCI_OBJECTSTORE_SYNC_NAMESPACE -bn $WERCKER_OCI_OBJECTSTORE_SYNC_BUCKET_NAME --file $WERCKER_OCI_OBJECTSTORE_SYNC_LOCAL_FILE"
}

main() {
  validate_oci_flags
  
  set_auth

  #Python 3 has ascii as locale default which makes a library ("click") used by ocicli to fail.
  #Explicitly set locale to UTF-8
  export LANG=C.UTF-8
  export LC_ALL=C.UTF-8
  info 'starting OCI object store synchronisation'
  #$WERCKER_STEP_ROOT/oci --version

  set_overwrite_flag
  WERCKER_OCI_OBJECTSTORE_SYNC_OPTIONS="$WERCKER_OCI_OBJECTSTORE_SYNC_OPTIONS $OVERWRITE_FLAG"

  case "$WERCKER_OCI_OBJECTSTORE_SYNC_COMMAND" in
    bulk-upload)
        local SYNC=$(get_bulk_upload_cmd)
        ;;
    bulk-download)
        local SYNC=$(get_bulk_download_cmd)
        ;;        
    *)
        fail "unknown oci command $WERCKER_OCI_OBJECTSTORE_SYNC_COMMAND - currently supported commands are [bulk-upload]"
        ;;
  esac

  debug "$SYNC"
  echo "running"
  local sync_output=$($SYNC)

  if [[ $? -ne 0 ]];then
      echo "$sync_output"
      fail 'oci os put failed';
  else
      echo "$sync_output"
      success 'completed oci object store synchronisation';
  fi
  set -e
}

main
