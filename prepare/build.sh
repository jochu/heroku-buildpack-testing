#!/bin/bash
set -e

cd $(dirname $0)
if [ ! -f ./config ]; then
    echo "Could not find config"
    echo "  See config.example"
fi
source ./config

if [ -z "$AMAZON_ACCESS_KEY_ID" ]; then
    echo "AMAZON_ACCESS_KEY_ID is not set"
    exit 1
fi

if [ -z "$AMAZON_SECRET_ACCESS_KEY" ]; then
    echo "AMAZON_SECRET_ACCESS_KEY is not set"
    exit 1
fi

if [ -z "$AMAZON_S3_BUCKET" ]; then
    echo "AMAZON_S3_BUCKET is not set"
    exit 1
fi

echo "-----> Creating heroku build app"
HEROKU_APP=$(heroku apps:create | awk '{print substr($2, 0, length($2) - 3); exit}')
echo "-----> Configuring build app at $HEROKU_APP"
heroku config:add \
    AMAZON_ACCESS_KEY_ID="$AMAZON_ACCESS_KEY_ID" \
    AMAZON_SECRET_ACCESS_KEY="$AMAZON_SECRET_ACCESS_KEY" \
    AMAZON_S3_BUCKET="$AMAZON_S3_BUCKET" \
    --app "$HEROKU_APP"
echo "-----> Building pay load"
[ -f compile.sh.bz2 ] && rm compile.sh.bz2
bzip2 -9k compile.sh
echo "-----> Compiling on heroku"
if [ "$1" == "debug" ]; then
    heroku run "echo $(base64 --wrap=0 compile.sh.bz2) > compile.b64; base64 --decode compile.b64 > compile.sh.bz2; rm compile.b64; bunzip2 compile.sh.bz2; exec bash" --app "$HEROKU_APP"
else
    heroku run "echo $(base64 --wrap=0 compile.sh.bz2) > compile.b64; base64 --decode compile.b64 > compile.sh.bz2; rm compile.b64; bunzip2 compile.sh.bz2; bash ./compile.sh" --app "$HEROKU_APP"
fi
echo "-----> Destroying build app $HEROKU_APP"
heroku apps:destroy $HEROKU_APP --confirm $HEROKU_APP
echo "-----> Cleaning up"
rm compile.sh.bz2
echo "-----> Done"
