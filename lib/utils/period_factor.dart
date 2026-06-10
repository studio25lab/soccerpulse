// lib/utils/period_factor.dart
//
// Helper per applicare un fattore proporzionale a dati statistici
// in base al filtro periodo selezionato (Tutti / 1°T / 2°T).
//
// PROVVISORIO (mock data): applica fattori fissi 0.45 / 0.55
// rispettivamente al 1° tempo e 2° tempo.
//
// QUANDO ARRIVERA' L'API:
// - Sostituire questa funzione con identita: return value
// - I dati verranno gia forniti per periodo dal backend
// - OPPURE estendere la funzione per usare 6 dataset (home1T/2T/All,
//   away1T/2T/All)
//
// USO:
//   periodScale(346, 0)  // -> 346 (Tutti, identita)
//   periodScale(346, 1)  // -> 156 (1° tempo, 45%)
//   periodScale(346, 2)  // -> 190 (2° tempo, 55%)

/// Applica fattore proporzionale a [value] in base al [filter] periodo.
/// filter: 0=Tutti, 1=1°Tempo, 2=2°Tempo.
int periodScale(int value, int filter) {
  if (filter == 0) return value;
  if (filter == 1) return (value * 0.45).round();
  return (value * 0.55).round();
}
