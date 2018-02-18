# vim: et sr sw=4 ts=4 smartindent syntax=dockerfile:
FROM alpine:3.7

LABEL \
      name="opsgang/aws_env" \
      vendor="sortuniq"     \
      description="... to run bash or python code, with awscli, credstash, curl, fetch, jq"

COPY fetch /var/tmp/fetch

ENV SCRIPTS_REPO="https://github.com/opsgang/alpine_build_scripts"

# ... the subshells below are to avoid any
# aufs locking unpleasantness from shippable
RUN apk --no-cache --update add ca-certificates \
    && ( sh -c "cp /var/tmp/ghfetch /usr/local/bin/ghfetch" ) \
    && ( sh -c "chmod a+x /usr/local/bin/ghfetch" ) \
    && ( sh -c "ghfetch --repo ${SCRIPTS_REPO} --tag='~>1.0' /scripts" ) \
    && sh /scripts/install_vim.sh        \
    && cp /etc/vim/vimrc /root/.vimrc    \
    && sh /scripts/install_awscli.sh     \
    && sh /scripts/install_credstash.sh  \
    && sh /scripts/install_essentials.sh \
    && rm -rf /var/tmp/ghfetch /var/cache/apk/* /scripts 2>/dev/null

# built with additional labels:
#
# version
# opsgang.alpine_version
# opsgang.awscli_version
# opsgang.credstash_version
# opsgang.fetch_version
# opsgang.jq_version
# opsgang.build_git_uri
# opsgang.build_git_sha
# opsgang.build_git_branch
# opsgang.build_git_tag
# opsgang.built_by
#
