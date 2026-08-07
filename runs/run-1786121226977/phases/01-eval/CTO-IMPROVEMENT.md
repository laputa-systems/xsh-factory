# CTO factory improvement

## Status

validated

The eval controller now checks the cached `XSH_TEST_IMAGE` Docker platform
against `FACTORY_PLATFORM` and forces a rebuild on mismatch. The reusable
contract is `factory/control.xsh::toolchain_image_platform_matches`, covered
by the native control tests. Validation passed: `xsht test` was 111/111 and
the forced arm64 eval build completed successfully, producing the expected
`xsh` and `xsht` binaries without the recorded pull error.
