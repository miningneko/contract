# 0xNEKO

<div align="center">

**CPU-optimierter Proof-of-Work ERC20-Token zum Mining**

[Funktionen](#funktionen) • [Schnellstart](#schnellstart) • [API-Referenz](#api-referenz) • [Mining-Anleitung](#mining-anleitung) • [Sicherheit](#sicherheit)

</div>

---

## Überblick

0xNEKO ist ein dezentraler, minebarer ERC20-Token, der den neuartigen **NekoCycle** Proof-of-Work-Algorithmus verwendet. Der Mining-Prozess erfordert das Finden von Zyklen in einer Graphenstruktur, wobei die Kantengenerierung **BranchingHash** verwendet - einen datenabhängigen Verzweigungsalgorithmus, der für CPU-Mining optimiert ist.

### Hauptmerkmale

- 🔒 **Vollständig Dezentralisiert** - Keine Admin-Schlüssel, keine Eigentümerrechte
- ⛏️ **CPU-Optimiert** - BranchingHash verwendet datenabhängige Verzweigung
- 🔗 **Chain-Gebunden** - Lösungen an spezifische Chain-ID und Miner-Adresse gebunden
- 📈 **ASERT-Schwierigkeit** - Sanfte exponentielle Schwierigkeitsanpassung
- 💰 **Sanfte Emission** - Graduelle Abklingreward-Kurve mit Tail-Emission

---

## Token-Ökonomie

| Parameter | Wert |
| :--- | :--- |
| **Token-Name** | 0xNEKO |
| **Symbol** | 0xNEKO |
| **Dezimalstellen** | 18 |
| **Maximale Versorgung** | 1.000.000.000 (1 Milliarde) |
| **Anfangsbelohnung** | ~953,67 NEKO |
| **Emissionsgeschwindigkeitsfaktor** | 20 |
| **Tail-Emission** | Minimum 0,1 NEKO |
| **Ziel-Blockzeit** | 60 Sekunden |

---

## Funktionen

### NekoCycle Proof-of-Work

Der Mining-Algorithmus erfordert das Finden eines **42-Längen-Zyklus** in einem bipartiten Graphen, wobei die Kanten durch die `_branchingHash()`-Funktion generiert werden.

### ASERT-Schwierigkeitsanpassung

| Parameter | Wert | Beschreibung |
| :--- | :--- | :--- |
| Halbwertszeit | 2.880 Blöcke | ~2 Tage bei Zielrate |
| Ziel-Blockzeit | 60 Sekunden | 1 Minute zwischen Blöcken |
| Anker-Update | Alle 100 Blöcke | Verhindert Berechnungsdrift |

### Sanfte Emissionskurve

```
Belohnung = (MaxVersorgung - GeprägteMenge) >> Emissionsfaktor
```

---

## Schnellstart

```bash
# Repository klonen
git clone https://github.com/your-repo/0xneko.git
cd 0xneko

# Abhängigkeiten installieren
npm install

# Verträge kompilieren
npx hardhat compile

# Tests ausführen
npx hardhat test

# Bereitstellen
npx hardhat run scripts/deploy.js --network hardhat
```

---

## API-Referenz

### Mining-Funktionen

#### `mint(uint256 nonce, uint256[] calldata solution)`
Eine gültige Mining-Lösung einreichen, um Token zu prägen.

### Abfragefunktionen

| Funktion | Beschreibung |
| :--- | :--- |
| `getBlockInfo()` | Gibt alle Mining-Infos in einem Aufruf zurück |
| `getChallengeNumber()` | Aktueller Challenge-Hash |
| `getMiningTarget()` | Schwierigkeitsziel |
| `getMiningReward()` | Aktuelle Blockbelohnung |
| `getLocalChallenge(miner, nonce)` | Lokale Challenge abrufen |
| `verifySolution(nonce, solution)` | Lösung vorprüfen |
| `computeEdge(root, edgeIndex)` | Kante (u, v) berechnen |
| `getDifficulty()` | Lesbare Schwierigkeit |
| `getDifficultyInfo()` | ASERT-Parameter |
| `getEconomicsInfo()` | Token-Wirtschaftsinfos |
| `getNetworkStats()` | Geschätzte Netzwerk-Hashrate |
| `getConstants()` | Protokollkonstanten |

---

## Mining-Anleitung

```
1. Aktuelle Challenge abrufen: getChallengeNumber()
2. Lokale Challenge generieren: hash(challenge, miner, nonce, chainid)
3. Graph-Kanten mit computeEdge() erstellen
4. 42-Zyklus im Graph finden
5. Lösungs-Hash < Ziel verifizieren
6. Einreichen: mint(nonce, solution)
```

---

## Gas-Kosten

| Operation | Gas |
| :--- | ---: |
| **Vertrag-Bereitstellung** | ~1.390.000 |
| **Vollständige Mint-Transaktion** | ~250.000 |

---

## Sicherheit

| Schutz | Implementierung |
| :--- | :--- |
| **Reentrancy** | OpenZeppelin ReentrancyGuard |
| **CEI-Muster** | Zustandsaktualisierungen vor _mint() |
| **Overflow-Schutz** | ASERT verwendet unchecked+Vorvalidierung |
| **Chain-Bindung** | Lösungen enthalten block.chainid |
| **Kein Admin** | Vollständig dezentralisiert |

---

## Lizenz

MIT
