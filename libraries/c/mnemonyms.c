#include "mnemonyms.h"

#include <stdlib.h>
#include <string.h>

typedef struct {
  uint32_t state[8];
  uint64_t bit_count;
  uint8_t block[64];
  size_t block_length;
} sha256_ctx;

static uint32_t rotr(uint32_t value, unsigned count) {
  return (value >> count) | (value << (32u - count));
}

static void sha256_transform(sha256_ctx *ctx, const uint8_t block[64]) {
  static const uint32_t k[64] = {
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b,
      0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01,
      0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7,
      0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
      0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152,
      0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
      0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc,
      0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819,
      0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08,
      0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f,
      0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
      0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2};
  uint32_t w[64];
  uint32_t a, b, c, d, e, f, g, h;

  for (size_t i = 0; i < 16; ++i) {
    w[i] = ((uint32_t)block[i * 4] << 24) |
           ((uint32_t)block[i * 4 + 1] << 16) |
           ((uint32_t)block[i * 4 + 2] << 8) | block[i * 4 + 3];
  }
  for (size_t i = 16; i < 64; ++i) {
    uint32_t s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
    uint32_t s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
    w[i] = w[i - 16] + s0 + w[i - 7] + s1;
  }

  a = ctx->state[0]; b = ctx->state[1]; c = ctx->state[2]; d = ctx->state[3];
  e = ctx->state[4]; f = ctx->state[5]; g = ctx->state[6]; h = ctx->state[7];
  for (size_t i = 0; i < 64; ++i) {
    uint32_t s1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
    uint32_t ch = (e & f) ^ (~e & g);
    uint32_t temp1 = h + s1 + ch + k[i] + w[i];
    uint32_t s0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
    uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
    uint32_t temp2 = s0 + maj;
    h = g; g = f; f = e; e = d + temp1;
    d = c; c = b; b = a; a = temp1 + temp2;
  }
  ctx->state[0] += a; ctx->state[1] += b; ctx->state[2] += c;
  ctx->state[3] += d; ctx->state[4] += e; ctx->state[5] += f;
  ctx->state[6] += g; ctx->state[7] += h;
}

static void sha256(const uint8_t *data, size_t length, uint8_t digest[32]) {
  sha256_ctx ctx = {{0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
                     0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19},
                    0, {0}, 0};
  ctx.bit_count = (uint64_t)length * 8;
  while (length != 0) {
    size_t take = 64 - ctx.block_length;
    if (take > length) take = length;
    memcpy(ctx.block + ctx.block_length, data, take);
    ctx.block_length += take;
    data += take;
    length -= take;
    if (ctx.block_length == 64) {
      sha256_transform(&ctx, ctx.block);
      ctx.block_length = 0;
    }
  }
  ctx.block[ctx.block_length++] = 0x80;
  if (ctx.block_length > 56) {
    memset(ctx.block + ctx.block_length, 0, 64 - ctx.block_length);
    sha256_transform(&ctx, ctx.block);
    ctx.block_length = 0;
  }
  memset(ctx.block + ctx.block_length, 0, 56 - ctx.block_length);
  for (size_t i = 0; i < 8; ++i)
    ctx.block[63 - i] = (uint8_t)(ctx.bit_count >> (i * 8));
  sha256_transform(&ctx, ctx.block);
  for (size_t i = 0; i < 8; ++i) {
    digest[i * 4] = (uint8_t)(ctx.state[i] >> 24);
    digest[i * 4 + 1] = (uint8_t)(ctx.state[i] >> 16);
    digest[i * 4 + 2] = (uint8_t)(ctx.state[i] >> 8);
    digest[i * 4 + 3] = (uint8_t)ctx.state[i];
  }
}

static unsigned get_bit(const uint8_t *bytes, size_t bit) {
  return (bytes[bit / 8] >> (7u - (bit % 8))) & 1u;
}

static void set_bit(uint8_t *bytes, size_t bit, unsigned value) {
  if (value) bytes[bit / 8] |= (uint8_t)(1u << (7u - (bit % 8)));
}

static size_t total_words(const mnemonym *ctx) {
  return (ctx->strength + ctx->strength / 32) / 11;
}

static int word_index(const mnemonym *ctx, const char *word, size_t length) {
  for (size_t i = 0; i < MNEMONYMS_WORDLIST_LENGTH; ++i)
    if (strlen(ctx->wordlist[i]) == length &&
        memcmp(ctx->wordlist[i], word, length) == 0)
      return (int)i;
  return -1;
}

mnemonym_status mnemonym_init(mnemonym *ctx, bool tweaked, size_t strength,
                              const char *const *wordlist,
                              size_t wordlist_length) {
  if (ctx == NULL || wordlist == NULL) return MNEMONYMS_INVALID_ARGUMENT;
  if (wordlist_length != MNEMONYMS_WORDLIST_LENGTH || strength < 32 ||
      strength % 32 != 0)
    return MNEMONYMS_INVALID_CONFIGURATION;
  for (size_t i = 0; i < wordlist_length; ++i)
    if (wordlist[i] == NULL) return MNEMONYMS_INVALID_CONFIGURATION;
  ctx->tweaked = tweaked;
  ctx->strength = strength;
  ctx->wordlist = wordlist;
  return MNEMONYMS_OK;
}

mnemonym_status mnemonym_to_nym(const mnemonym *ctx, const uint8_t *data,
                                size_t data_length, char *out,
                                size_t out_length, size_t *required_length) {
  if (ctx == NULL || data == NULL) return MNEMONYMS_INVALID_ARGUMENT;
  if (data_length != ctx->strength / 8) return MNEMONYMS_INVALID_ARGUMENT;
  uint8_t digest[32];
  sha256(data, data_length, digest);
  size_t words = total_words(ctx), first = 0, needed = ctx->tweaked ? 2 : 3;
  uint16_t *indices = malloc(words * sizeof(*indices));
  if (indices == NULL) return MNEMONYMS_INVALID_ARGUMENT;
  for (size_t i = 0; i < words; ++i) {
    unsigned index = 0;
    for (size_t j = 0; j < 11; ++j) {
      size_t bit = i * 11 + j;
      unsigned value = bit < ctx->strength ? get_bit(data, bit)
                                             : get_bit(digest, bit - ctx->strength);
      index = (index << 1) | value;
    }
    indices[i] = (uint16_t)index;
  }
  while (first < words && indices[first] == 0) ++first;
  for (size_t i = first; i < words; ++i) needed += strlen(ctx->wordlist[indices[i]]) + 1;
  if (first < words) --needed;
  if (required_length != NULL) *required_length = needed;
  if (out == NULL || out_length < needed) {
    free(indices);
    return MNEMONYMS_BUFFER_TOO_SMALL;
  }
  char *cursor = out;
  *cursor++ = '.';
  if (!ctx->tweaked) *cursor++ = '.';
  for (size_t i = first; i < words; ++i) {
    if (i != first) *cursor++ = '.';
    size_t length = strlen(ctx->wordlist[indices[i]]);
    memcpy(cursor, ctx->wordlist[indices[i]], length);
    cursor += length;
  }
  *cursor = '\0';
  free(indices);
  return MNEMONYMS_OK;
}

static mnemonym_status decode(const mnemonym *ctx, const char *nym,
                              uint8_t *entropy) {
  if (ctx == NULL || nym == NULL) return MNEMONYMS_INVALID_ARGUMENT;
  const char *cursor;
  if (nym[0] != '.') return MNEMONYMS_INVALID_NYM;
  cursor = nym + (nym[1] == '.' ? 2 : 1);
  if (*cursor == '\0') return MNEMONYMS_INVALID_NYM;
  size_t max_words = total_words(ctx), count = 1;
  for (const char *p = cursor; *p != '\0'; ++p) if (*p == '.') ++count;
  if (count > max_words) return MNEMONYMS_INVALID_NYM;
  uint16_t *indices = calloc(max_words, sizeof(*indices));
  if (indices == NULL) return MNEMONYMS_INVALID_ARGUMENT;
  size_t at = max_words - count;
  while (*cursor != '\0') {
    const char *end = strchr(cursor, '.');
    size_t length = end == NULL ? strlen(cursor) : (size_t)(end - cursor);
    int index = word_index(ctx, cursor, length);
    if (index < 0) { free(indices); return MNEMONYMS_UNKNOWN_WORD; }
    indices[at++] = (uint16_t)index;
    if (end == NULL) break;
    cursor = end + 1;
  }
  memset(entropy, 0, ctx->strength / 8);
  size_t checksum_bits = ctx->strength / 32;
  uint8_t supplied_checksum[32] = {0};
  for (size_t bit = 0; bit < ctx->strength + checksum_bits; ++bit) {
    unsigned value = (indices[bit / 11] >> (10u - (bit % 11))) & 1u;
    if (bit < ctx->strength) set_bit(entropy, bit, value);
    else set_bit(supplied_checksum, bit - ctx->strength, value);
  }
  free(indices);
  uint8_t digest[32];
  sha256(entropy, ctx->strength / 8, digest);
  for (size_t bit = 0; bit < checksum_bits; ++bit)
    if (get_bit(supplied_checksum, bit) != get_bit(digest, bit))
      return MNEMONYMS_CHECKSUM_MISMATCH;
  return MNEMONYMS_OK;
}

mnemonym_status mnemonym_to_entropy(const mnemonym *ctx, const char *nym,
                                    uint8_t *out, size_t out_length,
                                    size_t *required_length) {
  if (ctx == NULL) return MNEMONYMS_INVALID_ARGUMENT;
  size_t needed = ctx->strength / 8;
  if (required_length != NULL) *required_length = needed;
  if (out == NULL || out_length < needed) return MNEMONYMS_BUFFER_TOO_SMALL;
  return decode(ctx, nym, out);
}

bool mnemonym_validate_nym(const mnemonym *ctx, const char *nym) {
  if (ctx == NULL) return false;
  uint8_t *entropy = malloc(ctx->strength / 8);
  if (entropy == NULL) return false;
  bool valid = decode(ctx, nym, entropy) == MNEMONYMS_OK;
  free(entropy);
  return valid;
}

mnemonym_status mnemonym_complete_word(const mnemonym *ctx, const char *nym,
                                       char *out, size_t out_length,
                                       size_t *required_length) {
  if (ctx == NULL || nym == NULL || nym[0] != '.') return MNEMONYMS_INVALID_NYM;
  const char *fragment = strrchr(nym, '.');
  ++fragment;
  const char *match = NULL;
  size_t fragment_length = strlen(fragment);
  for (size_t i = 0; i < MNEMONYMS_WORDLIST_LENGTH; ++i) {
    if (strncmp(ctx->wordlist[i], fragment, fragment_length) == 0) {
      if (match != NULL) return MNEMONYMS_INVALID_NYM;
      match = ctx->wordlist[i];
    }
  }
  if (match == NULL) return MNEMONYMS_INVALID_NYM;
  size_t needed = strlen(match) + 1;
  if (required_length != NULL) *required_length = needed;
  if (out == NULL || out_length < needed) return MNEMONYMS_BUFFER_TOO_SMALL;
  memcpy(out, match, needed);
  return MNEMONYMS_OK;
}

mnemonym_status mnemonym_complete_nym(const mnemonym *ctx, const char *nym,
                                      char *out, size_t out_length,
                                      size_t *required_length) {
  char word[256];
  mnemonym_status status = mnemonym_complete_word(ctx, nym, word, sizeof(word), NULL);
  if (status != MNEMONYMS_OK) return status;
  const char *fragment = strrchr(nym, '.');
  size_t prefix_length = (size_t)(fragment - nym + 1);
  size_t needed = prefix_length + strlen(word) + 1;
  if (required_length != NULL) *required_length = needed;
  if (out == NULL || out_length < needed) return MNEMONYMS_BUFFER_TOO_SMALL;
  memcpy(out, nym, prefix_length);
  memcpy(out + prefix_length, word, strlen(word) + 1);
  return MNEMONYMS_OK;
}

const char *mnemonym_status_string(mnemonym_status status) {
  switch (status) {
    case MNEMONYMS_OK: return "ok";
    case MNEMONYMS_INVALID_ARGUMENT: return "invalid argument";
    case MNEMONYMS_INVALID_CONFIGURATION: return "invalid configuration";
    case MNEMONYMS_INVALID_NYM: return "invalid nym";
    case MNEMONYMS_UNKNOWN_WORD: return "unknown word";
    case MNEMONYMS_CHECKSUM_MISMATCH: return "checksum mismatch";
    case MNEMONYMS_BUFFER_TOO_SMALL: return "buffer too small";
  }
  return "unknown status";
}
