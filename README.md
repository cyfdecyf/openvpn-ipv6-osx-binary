How to build
============

First install openssl. (I use homebrew to do this.)

Then run the following command.

<pre>
git submodule update --init
cd tunnelblick
xcodebuild -configuration Release
<pre>

Modifications I've done
=======================

- Remove ppc target and use 10.6 SDK
- Modify build system to use openvpn-ipv6, which is added as a git submodule
- Apply a patch to make openvpn-ipv6 to compile on OS X.

