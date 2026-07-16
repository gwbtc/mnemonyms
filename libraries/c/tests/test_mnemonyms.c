#include "mnemonyms.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char *wordlist[MNEMONYMS_WORDLIST_LENGTH];
static unsigned tests_run;

#define CHECK(condition) do { tests_run++; if (!(condition)) { \
  fprintf(stderr, "FAIL %s:%d: %s\n", __FILE__, __LINE__, #condition); exit(1); \
} } while (0)

static void load_wordlist(const char *path) {
  FILE *file = fopen(path, "r");
  if (file == NULL) fprintf(stderr, "Unable to open wordlist: %s\n", path);
  CHECK(file != NULL);
  char line[256];
  size_t count = 0;
  while (count < MNEMONYMS_WORDLIST_LENGTH && fgets(line, sizeof(line), file)) {
    line[strcspn(line, "\r\n")] = '\0';
    wordlist[count] = malloc(strlen(line) + 1);
    CHECK(wordlist[count] != NULL);
    strcpy(wordlist[count++], line);
  }
  fclose(file);
  CHECK(count == MNEMONYMS_WORDLIST_LENGTH);
}

static void free_wordlist(void) {
  for (size_t i = 0; i < MNEMONYMS_WORDLIST_LENGTH; ++i) {
    free(wordlist[i]);
    wordlist[i] = NULL;
  }
}

static void load_language(const char *directory, const char *language) {
  size_t length = strlen(directory) + strlen(language) + 6;
  char *path = malloc(length);
  CHECK(path != NULL);
  snprintf(path, length, "%s/%s.txt", directory, language);
  load_wordlist(path);
  free(path);
}

static int hex_digit(char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  return c - 'A' + 10;
}

static size_t from_hex(const char *hex, uint8_t *out) {
  size_t length = strlen(hex) / 2;
  for (size_t i = 0; i < length; ++i)
    out[i] = (uint8_t)((hex_digit(hex[i * 2]) << 4) | hex_digit(hex[i * 2 + 1]));
  return length;
}

static void skip_whitespace(char **cursor) {
  while (**cursor == ' ' || **cursor == '\n' || **cursor == '\r' ||
         **cursor == '\t')
    ++*cursor;
}

static void expect(char **cursor, char expected) {
  skip_whitespace(cursor);
  CHECK(**cursor == expected);
  ++*cursor;
}

static char *parse_string(char **cursor) {
  skip_whitespace(cursor);
  CHECK(**cursor == '"');
  char *start = ++*cursor;
  while (**cursor != '"') {
    CHECK(**cursor != '\0');
    CHECK(**cursor != '\\');
    ++*cursor;
  }
  **cursor = '\0';
  ++*cursor;
  return start;
}

static void test_vector(const char *entropy_hex, const char *expected_nym) {
  uint8_t entropy[128], decoded[128];
  size_t entropy_length = from_hex(entropy_hex, entropy);
  mnemonym ctx;
  CHECK(mnemonym_init(&ctx, false, entropy_length * 8,
                      (const char *const *)wordlist,
                      MNEMONYMS_WORDLIST_LENGTH) == MNEMONYMS_OK);
  char nym[2048];
  CHECK(mnemonym_to_nym(&ctx, entropy, entropy_length, nym, sizeof(nym), NULL) == MNEMONYMS_OK);
  CHECK(strcmp(nym, expected_nym) == 0);
  CHECK(mnemonym_validate_nym(&ctx, nym));
  CHECK(mnemonym_to_entropy(&ctx, nym, decoded, sizeof(decoded), NULL) == MNEMONYMS_OK);
  CHECK(memcmp(entropy, decoded, entropy_length) == 0);
}

static void test_vectors(const char *wordlist_directory, const char *path) {
  FILE *file = fopen(path, "r");
  if (file == NULL) fprintf(stderr, "Unable to open test vectors: %s\n", path);
  CHECK(file != NULL);
  CHECK(fseek(file, 0, SEEK_END) == 0);
  long file_length = ftell(file);
  CHECK(file_length >= 0);
  CHECK(fseek(file, 0, SEEK_SET) == 0);
  char *json = malloc((size_t)file_length + 1);
  CHECK(json != NULL);
  size_t length = fread(json, 1, (size_t)file_length, file);
  fclose(file);
  CHECK(length == (size_t)file_length);
  json[length] = '\0';
  char *cursor = json;
  unsigned language_count = 0;
  expect(&cursor, '{');
  skip_whitespace(&cursor);
  while (*cursor != '}') {
    char *language = parse_string(&cursor);
    expect(&cursor, ':');
    expect(&cursor, '[');
    load_language(wordlist_directory, language);
    unsigned vector_count = 0;
    skip_whitespace(&cursor);
    while (*cursor != ']') {
      expect(&cursor, '[');
      char *entropy_hex = parse_string(&cursor);
      expect(&cursor, ',');
      char *expected_nym = parse_string(&cursor);
      expect(&cursor, ']');
      test_vector(entropy_hex, expected_nym);
      vector_count++;
      skip_whitespace(&cursor);
      if (*cursor == ',') ++cursor;
    }
    expect(&cursor, ']');
    CHECK(vector_count > 0);
    free_wordlist();
    language_count++;
    skip_whitespace(&cursor);
    if (*cursor == ',') ++cursor;
    skip_whitespace(&cursor);
  }
  expect(&cursor, '}');
  CHECK(language_count > 0);
  free(json);
}

static void test_completion(void) {
  mnemonym ctx;
  CHECK(mnemonym_init(&ctx, false, 256, (const char *const *)wordlist,
                      MNEMONYMS_WORDLIST_LENGTH) == MNEMONYMS_OK);
  char out[256];
  CHECK(mnemonym_complete_word(&ctx, "..ablat", out, sizeof(out), NULL) == MNEMONYMS_OK);
  CHECK(strcmp(out, "ablate") == 0);
  CHECK(mnemonym_complete_word(&ctx, "..abla", out, sizeof(out), NULL) == MNEMONYMS_INVALID_NYM);
  CHECK(mnemonym_complete_nym(&ctx, "..ablat", out, sizeof(out), NULL) == MNEMONYMS_OK);
  CHECK(strcmp(out, "..ablate") == 0);
  CHECK(mnemonym_complete_nym(&ctx, "..abla", out, sizeof(out), NULL) == MNEMONYMS_INVALID_NYM);
}

static void test_errors_and_prefixes(void) {
  mnemonym ctx;
  CHECK(mnemonym_init(&ctx, true, 128, (const char *const *)wordlist,
                      MNEMONYMS_WORDLIST_LENGTH) == MNEMONYMS_OK);
  uint8_t entropy[16] = {0};
  char nym[256];
  CHECK(mnemonym_to_nym(&ctx, entropy, sizeof(entropy), nym, sizeof(nym), NULL) == MNEMONYMS_OK);
  CHECK(nym[0] == '.' && nym[1] != '.');
  CHECK(mnemonym_to_nym(&ctx, entropy, 15, nym, sizeof(nym), NULL) == MNEMONYMS_INVALID_ARGUMENT);
  CHECK(!mnemonym_validate_nym(&ctx, "not-a-nym"));
  CHECK(!mnemonym_validate_nym(&ctx, ".notaword"));
  size_t required = 0;
  CHECK(mnemonym_to_nym(&ctx, entropy, sizeof(entropy), NULL, 0, &required) == MNEMONYMS_BUFFER_TOO_SMALL);
  CHECK(required > 1);
}

int main(int argc, char **argv) {
  if (argc != 3) {
    fprintf(stderr, "Usage: %s WORDLIST_DIRECTORY TEST_VECTORS\n", argv[0]);
    return 2;
  }

  test_vectors(argv[1], argv[2]);
  load_language(argv[1], "english");
  test_completion();
  test_errors_and_prefixes();
  free_wordlist();
  printf("ok: %u assertions\n", tests_run);
  return 0;
}
