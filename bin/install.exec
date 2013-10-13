#!/bin/bash
if [[ TARGET_INSTALL_REMOTE -eq 1 ]]; then
	exec ssh -p $THEOS_DEVICE_PORT root@$THEOS_DEVICE_IP "$@"
else
	exec sh -c "$@"
fi
