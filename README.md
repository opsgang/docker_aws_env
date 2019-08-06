[1]: http://docs.aws.amazon.com/cli/latest/reference "use aws apis from cmd line"
[2]: build/install_essentials.sh "common GNU tools useful for automation"
# docker\_aws\_env

>
> **alpine linux 3.10** image providing a consistent env
> for bash or python3 scripts along with a bunch of
> useful scripting tools and libs for working with aws.
>

## featuring ...

* [aws cli][1]

* python3

* bash 5

* curl, git, make, jq, openssh client [and friends][2]

## docker tags

### semver

Part of, or the entire numeric portion of a semver string.

* Major
    e.g. opsgang/aws\_env:2 - latest 2.x.x build
* Major.Minor
    e.g. opsgang/aws\_env:2.3 - latest 2.3.x build
* Major.Minor.Patch
    e.g. opsgang/aws\_env:2.3.1 - the 2.3.1 build
    This tag is immutable - it is never reassigned to a different image

## building

**master branch built at shippable.com**

[![Run Status](https://api.shippable.com/projects/589464f08d80360f008b754e/badge?branch=master)](https://app.shippable.com/projects/589464f08d80360f008b754e)

```bash
git clone https://github.com/opsgang/docker_aws_env.git
cd docker_aws_env
./build.sh # adds custom labels to image
```

## installing

```bash
docker pull opsgang/aws_env:2 # or use the tag you prefer
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
    opsgang/aws_env:stable /my.py         # script can access these env vars
```
