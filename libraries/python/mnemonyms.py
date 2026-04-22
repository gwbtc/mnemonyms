# mnemonyms.py

from __future__ import annotations
import hashlib


class ConfigurationError(Exception):
    """Raised when Mnemonym configuration is invalid."""


class Mnemonym:
    wordlist_length: int = 2048

    def __init__(self,
                 tweaked: bool,
                 strength: int,
                 wordlist: list[str]
                 ) -> None:
        if len(wordlist) != self.wordlist_length:
            raise ConfigurationError(
                f"Wordlist must contain exactly {self.wordlist_length} words",
            )

        self.tweaked = tweaked
        self.strength = strength
        self.wordlist = wordlist

    def to_nym(self, data: bytes) -> str:
        if len(data) == 0 or len(data) % 4 != 0:
            raise ValueError(
                f"Input must be a non-zero multiple of 32 bits, got {len(data) * 8} bits"
            )

        h: str = hashlib.sha256(data).hexdigest()
        b: str = (
            bin(int.from_bytes(data, byteorder="big"))[2:].zfill(len(data) * 8)
            + bin(int(h, 16))[2:].zfill(256)[:len(data) * 8 // 32]
        )
        indices: int = [int(b[i * 11:(i + 1) * 11], 2) for i in range(len(b) // 11)]

        while indices and indices[0] == 0:
            indices.pop(0)

        words: list[str] = [self.wordlist[idx] for idx in indices]
        prefix: str = "." if self.tweaked else ".."

        return prefix + ".".join(words)

    def to_eny(self, nym: str) -> str:
        if nym.startswith(".."):
            words_str = nym[2:]
        elif nym.startswith("."):
            words_str = nym[1:]
        else:
            raise ValueError("Nym must start with '.' or '..'")

        words: list[str] = words_str.split(".")

        for n_bytes in range(128, 0, -4):
            total_words = (n_bytes * 8 + n_bytes * 8 // 32) // 11
            if total_words < len(words):
                continue

            leading_zeros: int = total_words - len(words)
            indices: int = [0] * leading_zeros + [self.wordlist.index(w) for w in words]
            b: str = "".join(bin(idx)[2:].zfill(11) for idx in indices)
            checksum_bits: int = len(b) // 33
            entropy_bits: int = len(b) - checksum_bits
            entropy: int = int(b[:entropy_bits], 2).to_bytes(entropy_bits // 8, byteorder="big")
            h: str = hashlib.sha256(entropy).hexdigest()
            expected_cs: str = bin(int(h, 16))[2:].zfill(256)[:checksum_bits]

            if b[entropy_bits:] == expected_cs:
                return entropy.hex()

        raise ValueError(f"Failed to decode nym: checksum mismatch for all valid lengths")

    @classmethod
    def validate_nym(cls, nym: str) -> bool:
        # TODO
        # check string begins with "." or ".."
        # remove dot(s)
        # split remainder by "."
        # validate length of words
        # validate each word is in wordlist
        # validate checksum
        # check to_eny() result against checksum
        #   derives bitwidth from self.strength
        return True

    @classmethod
    def complete_current_word(cls, nym: str) -> str:
        # TODO
        # split nym
        # get last fragment
        # search for fragment in wordlist
        # if there's only one result, return it
        return "foobarbaz"

    @classmethod
    def complete_current_nym(cls, nym: str, nyms: list[str]) -> str:
        # TODO
        # search for nym in nyms
        # if there's only one result, return it
        return "foobarbaz"
