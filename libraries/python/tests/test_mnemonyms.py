import os
import json
import unittest
from mnemonyms import Mnemonym


class MnemonymTest(unittest.TestCase):
    def test_vectors(self) -> None:
        with open("../../../test-vectors.json", "r") as fil:
            vectors: dict[str, str] = json.load(fil)

        for lang in vectors.keys():
            path: str = os.path.join(
                os.path.dirname(__file__),
                f"../../../wordlists/{lang}.txt",
            )
            wordlist: list[str] = []

            if os.path.exists(path) and os.path.isfile(path):
                with open(path, "r", encoding="utf-8") as f:
                    wordlist: list[str] = [w.strip() for w in f.readlines()]
            else:
                raise EnvironmentError(f"Wordlist for {lang} not detected")

            for vec in vectors[lang]:
                strength: int = len(bytes.fromhex(vec[0])) * 8
                nym: Mnemonym = Mnemonym(False, strength, wordlist)
                nym_from_eny: str = nym.to_nym(bytes.fromhex(vec[0]))
                eny_from_nym: str = nym.to_eny(nym_from_eny)

                self.assertEqual(
                    vec[0], eny_from_nym, f"round-trip failed for entropy {vec[0]}"
                )
                self.assertEqual(
                    vec[1], nym_from_eny, f"to_nym failed for entropy {vec[0]}"
                )

    def test_complete_word(self) -> None:
        with open("../../../test-vectors.json", "r") as fil:
            vectors: dict[str, str] = json.load(fil)

        for lang in vectors.keys():
            path: str = os.path.join(
                os.path.dirname(__file__),
                f"../../../wordlists/{lang}.txt",
            )
            wordlist: list[str] = []

            if os.path.exists(path) and os.path.isfile(path):
                with open(path, "r", encoding="utf-8") as f:
                    wordlist: list[str] = [w.strip() for w in f.readlines()]
            else:
                raise EnvironmentError(f"Wordlist for {lang} not detected")

        nym: Mnemonym = Mnemonym(False, 256, wordlist)

        self.assertEqual("ablate", nym.complete_word("..ablat"))
        self.assertIsNone(nym.complete_word(
            "..abla"))

        return None

    def test_complete_nym(self) -> None:
        with open("../../../test-vectors.json", "r") as fil:
            vectors: dict[str, str] = json.load(fil)

        for lang in vectors.keys():
            path: str = os.path.join(
                os.path.dirname(__file__),
                f"../../../wordlists/{lang}.txt",
            )
            wordlist: list[str] = []

            if os.path.exists(path) and os.path.isfile(path):
                with open(path, "r", encoding="utf-8") as f:
                    wordlist: list[str] = [w.strip() for w in f.readlines()]
            else:
                raise EnvironmentError(f"Wordlist for {lang} not detected")

        nym: Mnemonym = Mnemonym(False, 256, wordlist)

        self.assertEqual(
            "..ablate",
            nym.complete_nym("..ablat"))
        self.assertIsNone(nym.complete_nym(
            "..abla"))

    def test_validate_nym(self) -> None:
        with open("../../../test-vectors.json", "r") as fil:
            vectors: dict[str, str] = json.load(fil)

        for lang in vectors.keys():
            path: str = os.path.join(
                os.path.dirname(__file__),
                f"../../../wordlists/{lang}.txt",
            )
            wordlist: list[str] = []

            if os.path.exists(path) and os.path.isfile(path):
                with open(path, "r", encoding="utf-8") as f:
                    wordlist: list[str] = [w.strip() for w in f.readlines()]
            else:
                raise EnvironmentError(f"Wordlist for {lang} not detected")

        for vec in vectors[lang]:
            strength: int = len(bytes.fromhex(vec[0])) * 8
            nym: Mnemonym = Mnemonym(False, strength, wordlist)

            self.assertEqual(
                True, nym.validate_nym(
                    vec[1]), f"Failed to validate nym {vec[1]}"
            )


def __main__() -> None:
    unittest.main()


if __name__ == "__main__":
    __main__()
