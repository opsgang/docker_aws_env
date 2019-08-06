#!/bin/bash
# vim: et sr sw=4 ts=4 smartindent:
# helper script to generate label data for docker image during building
#
# docker_build will generate an image tagged :candidate
#
# It is a post-step to tag that appropriately and push to repo

MIN_DOCKER=1.11.0
GIT_SHA_LEN=8
IMG_TAG=candidate

version_gt() {
    [[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" ]]
}

valid_docker_version() {
    v=$(docker --version | grep -Po '\b\d+\.\d+\.\d+\b')
    if version_gt $MIN_DOCKER $v
    then
        echo "ERROR: need min docker version $MIN_DOCKER" >&2
        return 1
    fi
}

awscli_version() {
    _pypi_pkg_version 'awscli'
}

g3_version() {
    $g3_init --version | grep -Po 'v[\d\.]+'
}

_pypi_pkg_version() {
    local pkg="$1"
    local uri="https://pypi.org/pypi/$pkg/json"
    curl -s --retry 5                \
        --retry-max-time 20 $uri     \
    | jq -r '.releases | keys | .[]' \
        2>/dev/null                  \
    | sort --version-sort            \
    | tail -1 || return 1
}

alpine_img(){
    grep -Po '(?<=^FROM ).*' Dockerfile
}

init_apk_versions() {
    local img="$1"
    docker pull $img >/dev/null 2>&1 || return 1
}

apk_pkg_version() {
    local img="$1"
    local pkg="$2"

    docker run -i --rm $img apk --no-cache --update info $pkg \
    | grep -Po "(?<=^$pkg-)[^ ]+(?= description:)" | head -n 1
}

built_by() {
    local user="--UNKNOWN--"
    if [[ ! -z "${BUILD_URL}" ]]; then
        user="${BUILD_URL}"
    elif [[ ! -z "${AWS_PROFILE}" ]] || [[ ! -z "${AWS_ACCESS_KEY_ID}" ]]; then
        user="$(aws iam get-user --query 'User.UserName' --output text)@$HOSTNAME"
    else
        user="$(git config --get user.name)@$HOSTNAME"
    fi
    echo "$user"
}

git_uri(){
    git config remote.origin.url || echo 'no-remote'
}

git_sha(){
    git rev-parse --short=${GIT_SHA_LEN} --verify HEAD
}

git_branch(){
    r=$(git rev-parse --abbrev-ref HEAD)
    [[ -z "$r" ]] && echo "ERROR: no rev to parse when finding branch? " >&2 && return 1
    [[ "$r" == "HEAD" ]] && r="from-a-tag"
    echo "$r"
}

img_name(){
    (
        set -o pipefail;
        grep -Po '(?<=[nN]ame=")[^"]+' Dockerfile | head -n 1
    )
}

labels() {
    ai=$(alpine_img) || return 1
    echo "... got base image $ai" >&2
    init_apk_versions $ai || return 1

    av=$(awscli_version) || return 1
    echo "... got awscli version $av" >&2

    gv=$(g3_version) || return 1
    echo "... got g3 version $fv" >&2

    jv=$(apk_pkg_version $ai 'jq') || return 1
    echo "... got jq version $jv" >&2

    gu=$(git_uri) || return 1
    gs=$(git_sha) || return 1
    gb=$(git_branch) || return 1
    gt=$(git describe 2>/dev/null || echo "no-git-tag")
    bb=$(built_by) || return 1

    ts=$(date +'%Y%m%d%H%M%S')
    echo "... got all label data" >&2
    cat<<EOM
    --label version=$ts
    --label opsgang.aws_env.version=$ts
    --label opsgang.aws_env.alpine_version=$ai
    --label opsgang.aws_env.awscli_version=$av
    --label opsgang.aws_env.g3_version=$gv
    --label opsgang.aws_env.jq_version=$jv
    --label opsgang.aws_env.build_git_uri=$gu
    --label opsgang.aws_env.build_git_sha=$gs
    --label opsgang.aws_env.build_git_branch=$gb
    --label opsgang.aws_env.build_git_tag=$gt
    --label opsgang.aws_env.built_by="$bb"
EOM
}

# Currently we are using the opsgang fork of gruntwork's 'fetch'.
# Amongst other changes, we are renaming the binary g3
# as it only works with the github api, not other git services.
# Until we make those changes to our fork, we do the renaming here.
latest_g3_binary() {
    get_g3_init || return 1
    return 0
}

get_g3_init() {
    local g3_init_version="v0.1.1" # fixed tag to use to get latest "stable"
    local g3_init="build/g3"
    local g3_url="${g3_repo}/releases/download/${g3_init_version}/${g3_release_name}"

    (
        set -o pipefail
        if ! curl -sS -L -H 'Accept: application/octet-stream' $g3_url | tar -xzv
        then
            echo >&2 "ERROR: could not fetch g3 binary from $g3_url"
            return 1
        fi
    )

    mv fetch $g3_init
}

docker_build(){
    export g3_desired_constraint="~>0.1.0"
    export g3_repo="https://github.com/opsgang/fetch"
    export g3_init="build/g3"
    export g3_release_name="fetch.tgz"
    export g3_extracted_bin="fetch"

    valid_docker_version || return 1
    get_g3_init || return 1

    labels=$(labels) || return 1
    n=$(img_name) || return 1

    echo "INFO: adding these labels:"
    echo "$labels"
    echo "INFO: building $n:$IMG_TAG"

    docker build --no-cache=true --force-rm \
        --build-arg g3_repo \
        --build-arg g3_desired_constraint \
        --build-arg g3_init \
        --build-arg g3_release_name \
        --build-arg g3_extracted_bin \
        $labels \
        -t $n:$IMG_TAG .
}

docker_build
