# test_mnemonyms.py

import os
import json
import unittest
from mnemonyms import Mnemonym


class MnemonymTest(unittest.TestCase):
    def test_vectors(self) -> None:
        with open("../../../test-vectors.json", "r") as fil:
            vectors = json.load(fil)

        for lang in vectors.keys():
            path = os.path.join(
                os.path.dirname(__file__),
                f"../../../wordlists/{lang}.txt",
            )
            wordlist = []

            if os.path.exists(path) and os.path.isfile(path):
                with open(path, "r", encoding="utf-8") as f:
                    wordlist = [w.strip() for w in f.readlines()]
            else:
                raise EnvironmentError(f"Wordlist for {lang} not detected")

            nym = Mnemonym(False, 128, wordlist)

            for vec in vectors[lang]:
                nym_from_eny = nym.to_nym(bytes.fromhex(vec[0]))
                eny_from_nym = nym.to_eny(nym_from_eny)
                self.assertEqual(vec[0], eny_from_nym, "foobar")
                self.assertEqual(vec[1], nym_from_eny, "foobaz")

    def test_complete_word(self) -> None:
        return None

    def test_validate_nym(self) -> None:
        return None


def __main__() -> None:
    unittest.main()


if __name__ == "__main__":
    __main__()
