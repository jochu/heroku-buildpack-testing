#!/bin/bash
set -e

GMP_VERSION=5.0.5
GHC_VERSION=7.4.2
HASKELL_PLATFORM_VERSION=2012.4.0.0

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


echo "-----> Installing GMP version ${GMP_VERSION}"
curl -O ftp://ftp.gmplib.org/pub/gmp-${GMP_VERSION}/gmp-${GMP_VERSION}.tar.bz2
tar jxf gmp-${GMP_VERSION}.tar.bz2
pushd gmp-${GMP_VERSION}
./configure --prefix=/app/vendor/gmp
make install
popd

export LD_LIBRARY_PATH=/app/vendor/gmp/lib:$LD_LIBRARY_PATH


echo "-----> Installing GHC version ${GHC_VERSION}"
curl -O http://www.haskell.org/ghc/dist/${GHC_VERSION}/ghc-${GHC_VERSION}-x86_64-unknown-linux.tar.bz2
tar -jxvf ghc-${GHC_VERSION}-x86_64-unknown-linux.tar.bz2
pushd ghc-${GHC_VERSION}
./configure --prefix=/app/vendor/ghc
make install
popd

/app/vendor/ghc/bin/ghc-pkg describe rts | awk '{print} $1 == "library-dirs:" {print "              /app/vendor/gmp/lib"}' > rts.pkg
/app/vendor/ghc/bin/ghc-pkg update rts.pkg


echo "-----> Installing Haskell Platform version ${HASKELL_PLATFORM_VERSION}"
curl -O http://lambda.haskell.org/platform/download/${HASKELL_PLATFORM_VERSION}/haskell-platform-${HASKELL_PLATFORM_VERSION}.tar.gz
tar zxf haskell-platform-${HASKELL_PLATFORM_VERSION}.tar.gz
pushd haskell-platform-${HASKELL_PLATFORM_VERSION}
export PATH=/app/vendor/ghc/bin:$PATH

# Disable OpenGL
awk '/OpenGL/,/fi/ {next} {print}' configure.ac > configure.ac.new
mv configure.ac{.new,}
awk '/OpenGL|GLUT/ {next} {print}' packages/platform.packages > packages/platform.packages.new
mv packages/platform.packages{.new,}
awk '$1 == "name:" { print "name: haskell-platform-server"; next } $1 == "GLUT" || $1 == "OpenGL" { next } {print}' \
    packages/haskell-platform-${HASKELL_PLATFORM_VERSION}/haskell-platform.cabal > packages/haskell-platform-${HASKELL_PLATFORM_VERSION}/haskell-platform.cabal.new
mv packages/haskell-platform-${HASKELL_PLATFORM_VERSION}/haskell-platform.cabal{.new,}

autoconf
./configure \
    --prefix=/app/vendor/ghc \
    --with-ghc=/app/vendor/ghc/bin/ghc \
    --with-ghc-pkg=/app/vendor/ghc/bin/ghc-pkg \
    --with-hsc2hs=/app/vendor/ghc/bin/hsc2hs \
    --enable-user-install=no
make install
popd

cd vendor

echo "-----> Tarballing GMP ${GMP_VERSION}"
tar cf gmp-${GMP_VERSION}.tar gmp
xz -zvv gmp-${GMP_VERSION}.tar

echo "-----> Tarballing haskell platform ${HASKELL_PLATFORM_VERSION}"
tar cf haskell-platform-server-${HASKELL_PLATFORM_VERSION}.tar ghc
xz -zvv haskell-platform-server-${HASKELL_PLATFORM_VERSION}.tar

echo "-----> Uploading to AWS S3"
gem install aws-s3 --user > /dev/null

~/.gem/ruby/1.9.1/bin/s3sh <<EOF
hp = "haskell-platform-server-${HASKELL_PLATFORM_VERSION}.tar.xz"
gmp = "gmp-${GMP_VERSION}.tar.xz"
S3Object.store(hp, open(hp), "${AMAZON_S3_BUCKET}")
S3Object.store(gmp, open(gmp), "${AMAZON_S3_BUCKET}")
EOF
