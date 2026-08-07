# CTO factory improvement

## Status

pending-validation

The eval controller now checks the cached `XSH_TEST_IMAGE` Docker platform
against `FACTORY_PLATFORM` and forces a rebuild on mismatch. The reusable
contract is `factory/control.xsh::toolchain_image_platform_matches`, covered
by the native control tests. Next-cycle validation is `xsht test` plus a
successful eval build that does not fail with the recorded `xsh-build.stderr`
pull error.
