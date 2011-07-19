Why
===

I need ipv6, but the stock Tunnelblick does not include unofficial ipv6 enabled
openvpn due to security reasons.

This project simply uses jjo's openvpn-ipv6 to replace the openvpn used by
Tunnelblick.

How to build
============

First install openssl. (I use homebrew to do this.)

Then run the following command.

<pre>
git submodule update --init
cd tunnelblick
xcodebuild -configuration Release
</pre>

Main Modifications to upstream project
======================================

- Remove ppc target and use 10.6 SDK
- Modify build system to use openvpn-ipv6, which is added as a git submodule
- Use openssl 0.9.8r, 1.0.0d can't pass openvpn's configure script
- Apply a patch to make openvpn-ipv6 to compile on OS X

