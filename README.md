Heroku buildpack: Haskell Platform
====

This is a (https://devcenter.heroku.com/articles/buildpacks)[Heroku Buildpack] for Haskell apps. It uses an OpenGL-less
(http://www.haskell.org/platform/)[Haskell Platform].

Still in development
----

This package is still in development and isn't quite ready for use yet.

Usage
----

First you need to 

```
$ ls
$ heroku create --stack cedar --buildpack http://github.com/jochu/haskell-platform-buildpack
```

Package should contain cabal-install.packages containing packages to cabal-install. Follows cabal install conventions
where you would include a trailing '/' to indicate you're installing a package in the path and no '/' to indicate you're
installing a package from hackage.

If you do not have sub-packages and you are installing the current repo, simply include `.` in your
cabal-install.packages file.

The executable run for the website is the first non-remote executable cabal found in the cabal-install.packages list. If
none is found, compilation will fail.

Hacking
----

To build your own vendored binaries, set environment config:

```
$ cp prepare/config.example prepare/config
```

Open `prepare/config` in your editor and modify configs.

```
$ support/build.sh
```

To modify the version of the binaries, open `prepare/compile.sh` and modify the following lines

```
GMP_VERSION=5.0.5
GHC_VERSION=7.4.2
HASKELL_PLATFORM_VERSION=2012.4.0.0
```

Also open `bin/compile` and modify the following lines

```
GMP_VERSION=5.0.5
HASKELL_PLATFORM_VERSION=2012.4.0.0
S3_BUCKET=haskell-platform-bp
```
