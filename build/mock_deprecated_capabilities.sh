#!/bin/sh
# vim: et sr sw=4 ts=4 smartindent:
#
BIN_DIR="${BIN_DIR:-/usr/bin}"
CAPS="
    credstash
    vim
"

stub() {
    local cap="$1"
    cat <<EOF  >$BIN_DIR/$cap
#!/bin/sh
cat <<EOM
$(notice)
EOM
EOF
    chmod a+x $BIN_DIR/$cap
}

notice() {
    cat <<EOF
The following capabilities have been removed from
this image:
$CAPS
If you need either of these:

    docker pull opsgang/aws_env:1 # not opsgang/aws_env:stable

= OR =

Create your own Dockerfile, using FROM opsgang/aws_env:stable,
and grab the install scripts from $SCRIPTS_REPO.

EOF
}

for cap in $CAPS; do
    stub $cap
done
