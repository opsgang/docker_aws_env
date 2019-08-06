#!/bin/sh
# vim: et smartindent sr sw=4 ts=4:
#
# Go Git-Get gogitget ... Get it?
#
# *sigh*. Fine. Use existing g3 to fetch a version of g3
# that matches a user-specified constraint.
g3_g3() {
    g3_bin=${g3_bin:-/usr/local/bin}
    g3="$g3_bin/g3"
    g3_init="${g3_init:-$g3}"
    g3_alias="$g3_bin/gogitget"
    release_name="${g3_release_name:-g3.tgz}"
    extracted_bin="${g3_extracted_bin:-g3}" # TODO modify to g3 once renamed

    echo "INFO: using g3 to update itself from $g3_repo"
    echo "INFO: ... semver constraint: $g3_desired_constraint"

    $g3_init \
        --repo="${g3_repo}" \
        --tag="${g3_desired_constraint}" \
        --release-asset="${release_name}" \
        $(pwd)

    if [[ $? -ne 0 ]]; then
        echo >&2 "ERROR: could not fetch a better version of g3 - gogitget - binary"
        return 1
    fi

    tar xzvf $release_name &>/dev/null ; chmod a+x $extracted_bin &>/dev/null

    if [[ ! -x "$extracted_bin" ]]; then
        echo >&2 "ERROR: could not extract $extracted_bin from tgz"
        return 1
    else
        rm $release_name
        echo "INFO: ... moving to $g3"
        mv $extracted_bin $g3
        if [[ ! -e $g3_alias ]]; then
            echo "INFO: ... creating alias $g3_alias"
            ln -s $g3 $g3_alias
        fi
    fi
}

g3_g3
