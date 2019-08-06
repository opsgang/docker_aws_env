#!/bin/sh
# vim: et smartindent sr sw=4 ts=4:
APK_TMP=/var/cache/apk
BUILD_PKGS="openssl-dev wget python-dev ca-certificates"
PKGS="$BUILD_PKGS python3 groff less"

echo "INFO $0: installing python (3), pip and awscli"
apk --no-cache add --update $PKGS \
&& pip3 --no-cache-dir install --upgrade awscli \
&& apk --no-cache --purge del --update $BUILD_PKGS \
&& rm -rf $APK_TMP/* \
&& aws --version \
&& echo "INFO $0: aws version $(aws --version) installed successfully"

[[ $? -eq 0 ]] || exit 1

if [[ ! -e /usr/bin/python ]]; then
    echo "INFO $0: symlinking to /usr/bin/python"
    ln -s $(which python3) /usr/bin/python
else
    true
fi
