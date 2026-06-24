# 🎯 SoccerPulse — Scaletta strategica al completamento

> Stato attuale (24 giugno 2026):
> - **0 errori**, 32 warning
> - **102 file** in lib/ (dopo cleanup massiccio)
> - Mock data ovunque, **demo Lazio-Milan** funzionante
> - Branch: `feature/favorite-team-notifications`
> - Target: **estate 2026**

---

## FASE 1 — Bug fix critici e UX rifiniture (1-2 giorni)

> Obiettivo: l'app NON deve avere bug visibili in nessuna sezione

### 1.1 Bug noti
- [ ] Filtri Classifica match upcoming (Casa/Trasferta/Rendimento) — il bottone non risponde
- [ ] Cuore/campanella nel calendario (cascading state non sincronizzato)
- [ ] Verifica visiva COMPLETA: ogni schermata, ogni tab, ogni interazione

### 1.2 Cleanup warning (32 → 0)
- [ ] 21 `unused_element` (metodi privati mai chiamati) — rimozione manuale, NO automatica
- [ ] 6 `unused_field` (field di classi mai letti)
- [ ] 4 `unused_local_variable`
- [ ] 1 `invalid_use_of_protected_member`

---

## FASE 2 — Feature mancanti (2-3 giorni)

> Obiettivo: aggiungere le ultime feature pendenti

### 2.1 Home screen
- [ ] **FAB menu** (azioni rapide: filtri, preferiti, ricerca)
- [ ] Possibili widget aggiuntivi (live notifications panel?)

### 2.2 Settings screen
- [ ] Rifinitura grafica + sezioni mancanti
- [ ] Privacy & Terms link
- [ ] About / version info
- [ ] Theme picker (chiaro/scuro/auto) ben visibile

### 2.3 Standings comparison
- [ ] Implementazione filtri Casa/Trasferta (dati ricalcolati)
- [ ] Bottone Rendimento (vista alternativa con grafici forma)

### 2.4 Match detail
- [ ] Eventuali piccole feature mancanti (per riallinearsi/superare SofaScore)
- [ ] Tab notifiche personalizzate per match (esiste? completa?)

---

## FASE 3 — Branding & Identity (1 giorno)

> Obiettivo: nome ufficiale, icona, splash screen

### 3.1 App name
- [ ] Decisione finale tra: Statix, MatchPulse, Scorix, LivePitch, StatFlow
- [ ] Verifica disponibilità .com + social handles
- [ ] Update: `pubspec.yaml`, `Info.plist`, `AndroidManifest`, `web/manifest.json`

### 3.2 Visual identity
- [ ] Logo finale (vector + raster)
- [ ] Icona app (iOS + Android + web favicon)
- [ ] Splash screen graphics

### 3.3 Brand
- [ ] Color palette finale (primary green + accent)
- [ ] Font system (forse mantieni quello attuale)

---

## FASE 4 — Translation pass (1-2 giorni)

> Obiettivo: parità IT/EN su tutti gli string letterali

> Infrastruttura: 572 chiavi in entrambe IT e EN ✅

### 4.1 Audit strings hardcoded
- [ ] `favorites_screen.dart` — molti `Text('...'` non usano `tr()`
- [ ] Tutte le altre schermate — scan + replace
- [ ] Mock data strings (`'Casa'`/`'Trasferta'`) — già localizzati via helper

### 4.2 Helper utili
- [ ] `_localizeShotData` / `_localizeEventDetail` — verifica completezza
- [ ] Date e numeri formattati per locale (it_IT vs en_US)

---

## FASE 5 — Real API integration (3-5 giorni) 🚀 MAJOR

> Obiettivo: rimpiazzare TUTTI i mock con dati reali da API-Football

### 5.1 Setup API
- [ ] API-Football account + key
- [ ] Configurazione: rate limiting, caching, error handling
- [ ] Pattern: `ApiMatchRepository` (esistente) → completa implementazione

### 5.2 Cosa sostituire (TODO già nel codice)
- [ ] `home_screen.dart` → `_loadMockMatches` → chiamata API
- [ ] `calendar_screen.dart` → data di oggi reale
- [ ] `standings_screen.dart` → currentMatchday da API
- [ ] `main.dart` → notifiche live reali (rimuovi `_testNotifications`)
- [ ] `live_notification_overlay.dart` → eventi live da socket/polling
- [ ] `match_data_service.dart` → parse completo
- [ ] `api_match_repository.dart` → `isHomeTeam` da team info reale

### 5.3 Mock files da eliminare (dopo API)
- [ ] `mock_shot_data.dart`, `mock_player_profile_data.dart`
- [ ] `mock_form_data.dart`, `mock_match_events.dart`
- [ ] `mock_defensive_data.dart`, `mock_lineup_data.dart`
- [ ] `mock_match_repository.dart`, `mock_player_repository.dart`
- [ ] Caso speciale: **Lazio-Milan id=9001** decide se restano demo o no

### 5.4 Live updates
- [ ] Polling ogni 60s sui live match
- [ ] Notifiche push (gol, cartellini, fine partita)
- [ ] WebSocket se disponibile (alcune API lo offrono)

---

## FASE 6 — Polishing & QA (1-2 giorni)

> Obiettivo: zero bug, performance ottime

### 6.1 Performance
- [ ] Web bundle size analysis
- [ ] Lazy loading immagini (CachedNetworkImage già usato ✅)
- [ ] Tempi di caricamento home screen

### 6.2 Testing
- [ ] Test manuali su Chrome desktop
- [ ] Test mobile (Chrome Android via DevTools)
- [ ] Test Safari (compatibilità Apple ecosystem)

### 6.3 Empty states & error handling
- [ ] Schermata "nessuna connessione"
- [ ] Schermata "errore API"
- [ ] Schermata "nessun risultato" in ricerca

---

## FASE 7 — Deploy (1 giorno)

> Obiettivo: app live e accessibile

### 7.1 Deploy web
- [ ] Firebase Hosting / Vercel / Netlify
- [ ] Dominio custom (legato all'app name FASE 3)
- [ ] HTTPS + redirect

### 7.2 Mobile (se ancora target)
- [ ] App Store iOS (richiede ~1 settimana review)
- [ ] Play Store Android (~1 giorno)
- [ ] Versioning + changelog

### 7.3 Marketing minimo
- [ ] Landing page con feature highlights
- [ ] Social presence iniziale

---

## 📅 STIMA TEMPORALE TOTALE

| Fase | Giorni |
|---|---|
| 1 — Bug fix + cleanup | 1-2 |
| 2 — Feature mancanti | 2-3 |
| 3 — Branding | 1 |
| 4 — Translation | 1-2 |
| 5 — Real API integration | **3-5** |
| 6 — Polishing & QA | 1-2 |
| 7 — Deploy | 1 |
| **TOTALE** | **10-16 giorni** |

> Target estate 2026 → ben dentro la finestra

---

## 🎯 ORDINE CONSIGLIATO

**Lavori grossi prima** (fase 1, 2):
- Tutta la parte tecnica senza dipendenza esterna
- Si può lavorare 100% in locale

**Branding al centro** (fase 3):
- Dipende da decisioni personali
- Può essere fatto in parallelo a fase 4

**Translation prima dell'API** (fase 4):
- Più facile su mock data che dover poi rifare con dati reali

**API ultimo** (fase 5):
- Lavoro più ad alto rischio (dipendenza esterna, rate limits)
- Tutto deve essere pronto prima

**Polish & deploy finali** (6, 7):
- Naturale chiusura

---

## ❌ COSA NON FARE OGGI

- Toccare unused_element warnings con automazioni (storico fallimentare)
- Refactor di file grossi (>2000 righe) per le righe — il codice funziona
- Pattern matching multi-line lunghi su file complessi (storico fallimentare)
