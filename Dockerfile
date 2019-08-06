# vim: et sr sw=4 ts=4 smartindent syntax=dockerfile:
FROM alpine:3.10

LABEL \
      name="opsgang/aws_env" \
      vendor="sortuniq"     \
      description="... to run bash or python code, with awscli, curl, gogitget, jq"

COPY build build/

# ... all args used to install g3 tool (gogitget)
# vals come from build.sh
ARG g3_repo
ARG g3_desired_constraint
ARG g3_init
ARG g3_release_name
ARG g3_extracted_bin

# ... the subshells below are to avoid any
# aufs locking unpleasantness from shippable
RUN apk --no-cache --update add ca-certificates \
    && sh /build/mock_deprecated_capabilities.sh \
    && sh /build/install_g3.sh \
    && sh /build/install_awscli.sh \
    && sh /build/install_essentials.sh \
    rm -rf /var/cache/apk/* /build 2>/dev/null

# built with additional labels - see build.sh
