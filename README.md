# docker\_aws\_env
_... defines an **alpine linux** container providing an env to run bash or_
_python scripts, that need awscli, credstash, curl and / or jq._

## building

```bash
git clone https://github.com/opsgang/docker_awscli.git
cd docker_awscli
git clone https://github.com/opsgang/alpine_build_scripts
./build.sh # adds custom labels to image
```

## installing

```bash
docker pull opsgang/aws_env:stable # or use the tag you prefer
```

## running

```bash
# run a custom script /path/to/script.sh that uses aws cli, curl, jq blah ...
docker run --rm -i -v /path/to/script.sh:/script.sh:ro opsgang/aws_env:stable /script.sh
```

```bash
# make my aws creds available and run /some/python/script.py
export AWS_ACCESS_KEY_ID="i'll-never-tell" # replace glibness with your access key
export AWS_SECRET_ACCESS_KEY="that's-for-me-to-know" # amend as necessary

docker run --rm -i                      \ # ... run interactive to see stdout / stderr
    -v /some/python/script.py:/my.py:ro \ # ... assume the file is executable
    --env AWS_ACCESS_KEY_ID             \ # ... will read it from your env
    --env AWS_SECRET_ACCESS_KEY         \ # ... will read it from your env
    --env AWS_DEFAULT_REGION=eu-west-2  \ # ... adjust geography to taste
    opsgang/aws_env:stable /my.py         # script will be able to access these AWS_ env vars
```
