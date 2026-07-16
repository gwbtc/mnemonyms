# Mnemonyms C library

This dependency-free C11 implementation mirrors `libraries/python/mnemonyms.py`:
encoding, checksum-checked decoding, validation, and unique-prefix completion.
The caller supplies a 2,048-entry wordlist and owns all output buffers.

Build and run the tests against the repository's wordlists and shared test
vectors:

```sh
make test
```

The test executable requires paths for the wordlist directory and test-vector
file as positional arguments:

```text
test_mnemonyms WORDLIST_DIRECTORY TEST_VECTORS
```

For example, after running `make` from `libraries/c`:

```sh
./test_mnemonyms /path/to/wordlists /path/to/test-vectors.json
```

For every top-level language key in `TEST_VECTORS`, the round-trip tests load
`WORDLIST_DIRECTORY/{language}.txt` and run every vector in that set. Each
wordlist must contain exactly 2,048 words, one per line. The completion-specific
tests use the `english` wordlist. `make test` passes
`../../wordlists` and `../../test-vectors.json` explicitly as the repository
defaults.

`required_length` includes the trailing NUL for strings and is the byte count for
entropy. Passing a null or undersized output buffer returns
`MNEMONYMS_BUFFER_TOO_SMALL` and reports the required size.
