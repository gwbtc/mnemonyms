# mnemonyms.py

from __future__ import annotations


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

        self.wordlist = wordlist

    @classmethod
    def to_nym(cls, data: bytes) -> str:
        # TODO
        # validate length of byte array
        # deserialize eny into array of bytes
        # for each byte in array
        #   convert byte into index number
        #   get word from index
        #   append word to result array
        # return result array
        # join result array with "."
        # if self.tweaked = True
        #   prepend "." to result
        # else
        #  prepend ".." to result
        return "foobar"

    @classmethod
    def to_eny(cls, nym: str) -> bytes:
        # TODO
        # validate_nym(nym)
        # remove "." or ".." at the beginning of the string
        # split remainder by "."
        # define bitwidth = len(words) * 11
        # for word in words
        #  find word's index
        #  set next 11 bits to value of the index
        #  extract original entropy as bytes
        #  create checksum of entropy
        #  return entropy
        return b"\x00" * 8

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
