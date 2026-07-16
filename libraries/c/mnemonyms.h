#ifndef MNEMONYMS_H
#define MNEMONYMS_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MNEMONYMS_WORDLIST_LENGTH 2048u

typedef enum {
  MNEMONYMS_OK = 0,
  MNEMONYMS_INVALID_ARGUMENT,
  MNEMONYMS_INVALID_CONFIGURATION,
  MNEMONYMS_INVALID_NYM,
  MNEMONYMS_UNKNOWN_WORD,
  MNEMONYMS_CHECKSUM_MISMATCH,
  MNEMONYMS_BUFFER_TOO_SMALL
} mnemonym_status;

typedef struct {
  bool tweaked;
  size_t strength;
  const char *const *wordlist;
} mnemonym;

mnemonym_status mnemonym_init(mnemonym *ctx, bool tweaked, size_t strength,
                              const char *const *wordlist,
                              size_t wordlist_length);

mnemonym_status mnemonym_to_nym(const mnemonym *ctx, const uint8_t *data,
                                size_t data_length, char *out,
                                size_t out_length, size_t *required_length);

mnemonym_status mnemonym_to_entropy(const mnemonym *ctx, const char *nym,
                                    uint8_t *out, size_t out_length,
                                    size_t *required_length);

bool mnemonym_validate_nym(const mnemonym *ctx, const char *nym);

mnemonym_status mnemonym_complete_word(const mnemonym *ctx, const char *nym,
                                       char *out, size_t out_length,
                                       size_t *required_length);

mnemonym_status mnemonym_complete_nym(const mnemonym *ctx, const char *nym,
                                      char *out, size_t out_length,
                                      size_t *required_length);

const char *mnemonym_status_string(mnemonym_status status);

#endif
