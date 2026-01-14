# 0xNEKO

<div align="center">

**Token ERC20 minable con Proof-of-Work optimizado para CPU**

[Características](#características) • [Inicio Rápido](#inicio-rápido) • [Referencia API](#referencia-api) • [Guía de Minería](#guía-de-minería) • [Seguridad](#seguridad)

</div>

---

## Descripción General

0xNEKO es un token ERC20 minable descentralizado que utiliza el novedoso algoritmo de Proof-of-Work **NekoCycle**. El proceso de minería implica encontrar ciclos en una estructura de grafos, con generación de aristas usando **BranchingHash** - un algoritmo de ramificación dependiente de datos diseñado para optimizar la minería por CPU.

### Aspectos Destacados

- 🔒 **Totalmente Descentralizado** - Sin claves de administrador, sin privilegios de propietario
- ⛏️ **Optimizado para CPU** - BranchingHash usa ramificación dependiente de datos
- 🔗 **Vinculado a Cadena** - Soluciones vinculadas a ID de cadena y dirección del minero
- 📈 **Dificultad ASERT** - Ajuste de dificultad exponencial suave
- 💰 **Emisión Suave** - Curva de recompensa con decaimiento gradual con emisión de cola

---

## Economía del Token

| Parámetro | Valor |
| :--- | :--- |
| **Nombre del Token** | 0xNEKO |
| **Símbolo** | 0xNEKO |
| **Decimales** | 18 |
| **Suministro Máximo** | 1,000,000,000 (mil millones) |
| **Recompensa Inicial** | ~953.67 NEKO |
| **Factor de Velocidad de Emisión** | 20 |
| **Emisión de Cola** | Mínimo 0.1 NEKO |
| **Tiempo de Bloque Objetivo** | 60 segundos |

---

## Características

### NekoCycle Proof-of-Work

El algoritmo de minería requiere encontrar un **ciclo de longitud 42** en un grafo bipartito donde las aristas son generadas por la función `_branchingHash()`.

### Ajuste de Dificultad ASERT

| Parámetro | Valor | Descripción |
| :--- | :--- | :--- |
| Vida media | 2,880 bloques | ~2 días a tasa objetivo |
| Tiempo de bloque objetivo | 60 segundos | 1 minuto entre bloques |
| Actualización de ancla | Cada 100 bloques | Previene deriva de cálculo |

### Curva de Emisión Suave

```
recompensa = (suministroMáximo - tokensMinados) >> factorVelocidadEmisión
```

---

## Inicio Rápido

```bash
# Clonar repositorio
git clone https://github.com/your-repo/0xneko.git
cd 0xneko

# Instalar dependencias
npm install

# Compilar contratos
npx hardhat compile

# Ejecutar pruebas
npx hardhat test

# Desplegar
npx hardhat run scripts/deploy.js --network hardhat
```

---

## Referencia API

### Funciones de Minería

#### `mint(uint256 nonce, uint256[] calldata solution)`
Enviar una solución de minería válida para acuñar tokens.

### Funciones de Consulta

| Función | Descripción |
| :--- | :--- |
| `getBlockInfo()` | Devuelve toda la info de minería en una llamada |
| `getChallengeNumber()` | Hash del desafío actual |
| `getMiningTarget()` | Objetivo de dificultad |
| `getMiningReward()` | Recompensa de bloque actual |
| `getLocalChallenge(miner, nonce)` | Obtener desafío local |
| `verifySolution(nonce, solution)` | Pre-verificar solución |
| `computeEdge(root, edgeIndex)` | Calcular arista (u, v) |
| `getDifficulty()` | Dificultad legible |
| `getDifficultyInfo()` | Parámetros ASERT |
| `getEconomicsInfo()` | Info de economía del token |
| `getNetworkStats()` | Hashrate estimado de la red |
| `getConstants()` | Constantes del protocolo |

---

## Guía de Minería

```
1. Obtener desafío actual: getChallengeNumber()
2. Generar desafío local: hash(challenge, miner, nonce, chainid)
3. Construir aristas del grafo con computeEdge()
4. Encontrar ciclo de 42 en el grafo
5. Verificar hash de solución < objetivo
6. Enviar: mint(nonce, solution)
```

---

## Costos de Gas

| Operación | Gas |
| :--- | ---: |
| **Despliegue de Contrato** | ~1,390,000 |
| **Transacción Mint Completa** | ~250,000 |

---

## Seguridad

| Protección | Implementación |
| :--- | :--- |
| **Reentrada** | OpenZeppelin ReentrancyGuard |
| **Patrón CEI** | Actualizaciones de estado antes de _mint() |
| **Protección Overflow** | ASERT usa unchecked+pre-validación |
| **Vinculación de Cadena** | Soluciones incluyen block.chainid |
| **Sin Administrador** | Completamente descentralizado |

---

## Licencia

MIT
