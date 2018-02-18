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

credstash_version() {
    _pypi_pkg_version 'credstash'
}

fetch_version() {
    ./fetch --version | grep -Po 'v[\d\.]+'
}

_pypi_pkg_version() {
    local pkg="$1"
    local uri="https://pypi.python.org/pypi/$pkg/json"
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

packer_version() {
    echo $PACKER_VERSION
}

terraform_version() {
    echo $TERRAFORM_VERSION
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

    cv=$(credstash_version) || return 1
    echo "... got credstash version $cv" >&2

    fv=$(fetch_version) || return 1
    echo "... got fetch version $fv" >&2

    jv=$(apk_pkg_version $ai 'jq') || return 1
    echo "... got jq version $jv" >&2

    gu=$(git_uri) || return 1
    gs=$(git_sha) || return 1
    gb=$(git_branch) || return 1
    gt=$(git describe 2>/dev/null || echo "no-git-tag")
    bb=$(built_by) || return 1

    echo "... got all label data" >&2
    cat<<EOM
    --label version=$(date +'%Y%m%d%H%M%S')
    --label opsgang.alpine_version=$ai
    --label opsgang.awscli_version=$av
    --label opsgang.credstash_version=$cv
    --label opsgang.fetch_version=$fv
    --label opsgang.jq_version=$jv
    --label opsgang.build_git_uri=$gu
    --label opsgang.build_git_sha=$gs
    --label opsgang.build_git_branch=$gb
    --label opsgang.build_git_tag=$gt
    --label opsgang.built_by="$bb"
EOM
}

latest_fetch_binary() {
    local FETCH_REPO="https://github.com/opsgang/fetch"
    local FETCH_BOOT_VERSION="v0.1.1" # fixed tag to use to get latest "stable"
    local FETCH_DESIRED="~>0.1.0"
    local FETCH_RELEASE_URL="${FETCH_REPO}/releases/download/${FETCH_BOOT_VERSION}/fetch.tgz"

    set -o pipefail
    if ! curl -sS -L -H 'Accept: application/octet-stream' $FETCH_RELEASE_URL | tar -xzv
    then
        echo "ERROR: could not fetch bootstrap 'fetch' binary from $FETCH_RELEASE_URL" >&2
        return 1
    fi

    mv fetch fetch.init

    echo "INFO: getting latest fetch (semver constraint: $FETCH_DESIRED)"
    if ! ./fetch.init --repo ${FETCH_REPO} --tag="${FETCH_DESIRED}" --release-asset="fetch.tgz" .
    then
        echo "ERROR: could not fetch a better version of fetch binary" >&2
        return 1
    fi

    tar xzvf fetch.tgz >/dev/null 2>&1

    if ! ls -1 fetch | grep -Po '^fetch$' >/dev/null 2>&1
    then
        echo "ERROR: could not extract fetch binary from tgz"
        return 1
    else
        echo "INFO: I've, um, fetched 'fetch' :)"
    fi
    rm -rf fetch.init fetch.tgz
    return 0
}

docker_build(){

    valid_docker_version || return 1

    latest_fetch_binary || return 1

    labels=$(labels) || return 1
    n=$(img_name) || return 1

    echo "INFO: adding these labels:"
    echo "$labels"
    echo "INFO: building $n:$IMG_TAG"

    docker build --no-cache=true --force-rm $labels -t $n:$IMG_TAG .
}

docker_build
