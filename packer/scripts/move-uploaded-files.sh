#!/bin/bash
set -eu
echo "Syncing uploaded files"
rsync -av $PACKER_FILES_DIR  /