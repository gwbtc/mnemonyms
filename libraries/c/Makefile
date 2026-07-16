CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -Wpedantic -Werror -O2

.PHONY: all test clean

all: test_mnemonyms

test_mnemonyms: mnemonyms.c mnemonyms.h tests/test_mnemonyms.c
	$(CC) $(CFLAGS) -I. mnemonyms.c tests/test_mnemonyms.c -o $@

test: test_mnemonyms
	./test_mnemonyms ../../wordlists ../../test-vectors.json

clean:
	rm -f test_mnemonyms
