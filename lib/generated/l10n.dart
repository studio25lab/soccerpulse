import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';
import 'l10n_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it')
  ];

  /// No description provided for @home.
  ///
  /// In it, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @calendar.
  ///
  /// In it, this message translates to:
  /// **'Calendario'**
  String get calendar;

  /// No description provided for @players.
  ///
  /// In it, this message translates to:
  /// **'Giocatori'**
  String get players;

  /// No description provided for @standings.
  ///
  /// In it, this message translates to:
  /// **'Classifica'**
  String get standings;

  /// No description provided for @favorites.
  ///
  /// In it, this message translates to:
  /// **'Preferiti'**
  String get favorites;

  /// No description provided for @settings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settings;

  /// No description provided for @welcome.
  ///
  /// In it, this message translates to:
  /// **'Benvenuto'**
  String get welcome;

  /// No description provided for @quickActions.
  ///
  /// In it, this message translates to:
  /// **'Azioni Rapide'**
  String get quickActions;

  /// No description provided for @allMatches.
  ///
  /// In it, this message translates to:
  /// **'Tutte le partite'**
  String get allMatches;

  /// No description provided for @viewStandings.
  ///
  /// In it, this message translates to:
  /// **'Vedi classifica'**
  String get viewStandings;

  /// No description provided for @compareTeams.
  ///
  /// In it, this message translates to:
  /// **'Confronta squadre'**
  String get compareTeams;

  /// No description provided for @yourTeams.
  ///
  /// In it, this message translates to:
  /// **'Le tue squadre'**
  String get yourTeams;

  /// No description provided for @todayMatches.
  ///
  /// In it, this message translates to:
  /// **'Partite di Oggi'**
  String get todayMatches;

  /// No description provided for @viewAll.
  ///
  /// In it, this message translates to:
  /// **'Vedi Tutte'**
  String get viewAll;

  /// No description provided for @noMatchesToday.
  ///
  /// In it, this message translates to:
  /// **'Nessuna Partita Oggi'**
  String get noMatchesToday;

  /// No description provided for @checkBackLater.
  ///
  /// In it, this message translates to:
  /// **'Ricontrolla più tardi per nuove partite'**
  String get checkBackLater;

  /// No description provided for @h2h.
  ///
  /// In it, this message translates to:
  /// **'Scontri Diretti'**
  String get h2h;

  /// No description provided for @today.
  ///
  /// In it, this message translates to:
  /// **'Oggi'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In it, this message translates to:
  /// **'Domani'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In it, this message translates to:
  /// **'Ieri'**
  String get yesterday;

  /// No description provided for @live.
  ///
  /// In it, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @upcoming.
  ///
  /// In it, this message translates to:
  /// **'Prossime'**
  String get upcoming;

  /// No description provided for @finished.
  ///
  /// In it, this message translates to:
  /// **'Finite'**
  String get finished;

  /// No description provided for @liveMatches.
  ///
  /// In it, this message translates to:
  /// **'Partite Live'**
  String get liveMatches;

  /// No description provided for @upcomingMatches.
  ///
  /// In it, this message translates to:
  /// **'Partite in Programma'**
  String get upcomingMatches;

  /// No description provided for @finishedMatches.
  ///
  /// In it, this message translates to:
  /// **'Partite Terminate'**
  String get finishedMatches;

  /// No description provided for @changeLeague.
  ///
  /// In it, this message translates to:
  /// **'Cambia Campionato'**
  String get changeLeague;

  /// No description provided for @noMatchesFound.
  ///
  /// In it, this message translates to:
  /// **'Nessuna Partita Trovata'**
  String get noMatchesFound;

  /// No description provided for @noMatchesOnDate.
  ///
  /// In it, this message translates to:
  /// **'Non ci sono partite in questa data'**
  String get noMatchesOnDate;

  /// No description provided for @errorLoadingMatches.
  ///
  /// In it, this message translates to:
  /// **'Errore nel caricamento delle partite'**
  String get errorLoadingMatches;

  /// No description provided for @retry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get retry;

  /// No description provided for @goToToday.
  ///
  /// In it, this message translates to:
  /// **'Vai a Oggi'**
  String get goToToday;

  /// No description provided for @standingsTitle.
  ///
  /// In it, this message translates to:
  /// **'Classifica'**
  String get standingsTitle;

  /// No description provided for @tryAnotherLeague.
  ///
  /// In it, this message translates to:
  /// **'Prova con un altro campionato'**
  String get tryAnotherLeague;

  /// No description provided for @rank.
  ///
  /// In it, this message translates to:
  /// **'Pos'**
  String get rank;

  /// No description provided for @legend.
  ///
  /// In it, this message translates to:
  /// **'Legenda'**
  String get legend;

  /// No description provided for @champions.
  ///
  /// In it, this message translates to:
  /// **'Champions League'**
  String get champions;

  /// No description provided for @europa.
  ///
  /// In it, this message translates to:
  /// **'Europa League'**
  String get europa;

  /// No description provided for @conference.
  ///
  /// In it, this message translates to:
  /// **'Conference League'**
  String get conference;

  /// No description provided for @relegation.
  ///
  /// In it, this message translates to:
  /// **'Retrocessione'**
  String get relegation;

  /// No description provided for @errorLoadingStandings.
  ///
  /// In it, this message translates to:
  /// **'Errore nel caricamento della classifica'**
  String get errorLoadingStandings;

  /// No description provided for @topPlayers.
  ///
  /// In it, this message translates to:
  /// **'Top Giocatori'**
  String get topPlayers;

  /// No description provided for @playersStats.
  ///
  /// In it, this message translates to:
  /// **'Statistiche Giocatori'**
  String get playersStats;

  /// No description provided for @goals.
  ///
  /// In it, this message translates to:
  /// **'Gol'**
  String get goals;

  /// No description provided for @assists.
  ///
  /// In it, this message translates to:
  /// **'Assist'**
  String get assists;

  /// No description provided for @yellowCards.
  ///
  /// In it, this message translates to:
  /// **'Cartellini Gialli'**
  String get yellowCards;

  /// No description provided for @redCards.
  ///
  /// In it, this message translates to:
  /// **'Cartellini Rossi'**
  String get redCards;

  /// No description provided for @noPlayersData.
  ///
  /// In it, this message translates to:
  /// **'Nessun Dato Disponibile'**
  String get noPlayersData;

  /// No description provided for @noPlayersDataDesc.
  ///
  /// In it, this message translates to:
  /// **'Non ci sono statistiche disponibili per questo campionato'**
  String get noPlayersDataDesc;

  /// No description provided for @errorLoading.
  ///
  /// In it, this message translates to:
  /// **'Errore nel Caricamento'**
  String get errorLoading;

  /// No description provided for @age.
  ///
  /// In it, this message translates to:
  /// **'anni'**
  String get age;

  /// No description provided for @statistics.
  ///
  /// In it, this message translates to:
  /// **'Statistiche'**
  String get statistics;

  /// No description provided for @attackingStats.
  ///
  /// In it, this message translates to:
  /// **'Attacco'**
  String get attackingStats;

  /// No description provided for @defendingStats.
  ///
  /// In it, this message translates to:
  /// **'Difesa'**
  String get defendingStats;

  /// No description provided for @noDataAvailable.
  ///
  /// In it, this message translates to:
  /// **'Nessun Dato Disponibile'**
  String get noDataAvailable;

  /// No description provided for @appearances.
  ///
  /// In it, this message translates to:
  /// **'Presenze'**
  String get appearances;

  /// No description provided for @totalMatches.
  ///
  /// In it, this message translates to:
  /// **'Partite Totali'**
  String get totalMatches;

  /// No description provided for @minutesPlayed.
  ///
  /// In it, this message translates to:
  /// **'Minuti Giocati'**
  String get minutesPlayed;

  /// No description provided for @rating.
  ///
  /// In it, this message translates to:
  /// **'Voto Medio'**
  String get rating;

  /// No description provided for @disciplineStats.
  ///
  /// In it, this message translates to:
  /// **'Disciplina'**
  String get disciplineStats;

  /// No description provided for @totalGoals.
  ///
  /// In it, this message translates to:
  /// **'Gol Totali'**
  String get totalGoals;

  /// No description provided for @penaltyGoals.
  ///
  /// In it, this message translates to:
  /// **'Rigori'**
  String get penaltyGoals;

  /// No description provided for @goalsPerMatch.
  ///
  /// In it, this message translates to:
  /// **'Gol/Partita'**
  String get goalsPerMatch;

  /// No description provided for @dribbles.
  ///
  /// In it, this message translates to:
  /// **'Dribbling'**
  String get dribbles;

  /// No description provided for @passesTotal.
  ///
  /// In it, this message translates to:
  /// **'Passaggi Totali'**
  String get passesTotal;

  /// No description provided for @passesAccuracy.
  ///
  /// In it, this message translates to:
  /// **'Precisione Passaggi'**
  String get passesAccuracy;

  /// No description provided for @tackles.
  ///
  /// In it, this message translates to:
  /// **'Contrasti'**
  String get tackles;

  /// No description provided for @duelsWon.
  ///
  /// In it, this message translates to:
  /// **'Duelli Vinti'**
  String get duelsWon;

  /// No description provided for @myFavorites.
  ///
  /// In it, this message translates to:
  /// **'I Miei Preferiti'**
  String get myFavorites;

  /// No description provided for @noFavorites.
  ///
  /// In it, this message translates to:
  /// **'Nessuna Squadra Preferita'**
  String get noFavorites;

  /// No description provided for @addFavorites.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi le tue squadre preferite per seguirle facilmente'**
  String get addFavorites;

  /// No description provided for @addTeam.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi Squadra'**
  String get addTeam;

  /// No description provided for @addTeams.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi Squadre'**
  String get addTeams;

  /// No description provided for @removeFavorite.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi dai Preferiti'**
  String get removeFavorite;

  /// No description provided for @confirmRemove.
  ///
  /// In it, this message translates to:
  /// **'Vuoi rimuovere questa squadra dai preferiti?'**
  String get confirmRemove;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi'**
  String get remove;

  /// No description provided for @upcomingMatchesFor.
  ///
  /// In it, this message translates to:
  /// **'Prossime Partite'**
  String get upcomingMatchesFor;

  /// No description provided for @followedTeams.
  ///
  /// In it, this message translates to:
  /// **'squadre seguite'**
  String get followedTeams;

  /// No description provided for @noFavoriteTeams.
  ///
  /// In it, this message translates to:
  /// **'Nessuna Squadra Preferita'**
  String get noFavoriteTeams;

  /// No description provided for @noFavoriteTeamsDesc.
  ///
  /// In it, this message translates to:
  /// **'Inizia ad aggiungere le tue squadre del cuore'**
  String get noFavoriteTeamsDesc;

  /// No description provided for @noMatchesForFavorites.
  ///
  /// In it, this message translates to:
  /// **'Nessuna partita in programma per le tue squadre'**
  String get noMatchesForFavorites;

  /// No description provided for @appearance.
  ///
  /// In it, this message translates to:
  /// **'Aspetto'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get language;

  /// No description provided for @data.
  ///
  /// In it, this message translates to:
  /// **'Dati'**
  String get data;

  /// No description provided for @about.
  ///
  /// In it, this message translates to:
  /// **'Info'**
  String get about;

  /// No description provided for @theme.
  ///
  /// In it, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In it, this message translates to:
  /// **'Modalità Scura'**
  String get darkMode;

  /// No description provided for @darkModeActive.
  ///
  /// In it, this message translates to:
  /// **'Modalità scura attiva'**
  String get darkModeActive;

  /// No description provided for @lightModeActive.
  ///
  /// In it, this message translates to:
  /// **'Modalità chiara attiva'**
  String get lightModeActive;

  /// No description provided for @selectLanguage.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Lingua'**
  String get selectLanguage;

  /// No description provided for @languageChangedToItalian.
  ///
  /// In it, this message translates to:
  /// **'Lingua cambiata in Italiano'**
  String get languageChangedToItalian;

  /// No description provided for @languageChangedToEnglish.
  ///
  /// In it, this message translates to:
  /// **'Lingua cambiata in Inglese'**
  String get languageChangedToEnglish;

  /// No description provided for @notifications.
  ///
  /// In it, this message translates to:
  /// **'Notifiche'**
  String get notifications;

  /// No description provided for @matchNotifications.
  ///
  /// In it, this message translates to:
  /// **'Notifiche Partite'**
  String get matchNotifications;

  /// No description provided for @matchNotificationsDesc.
  ///
  /// In it, this message translates to:
  /// **'Ricevi notifiche per le partite'**
  String get matchNotificationsDesc;

  /// No description provided for @favoriteNotifications.
  ///
  /// In it, this message translates to:
  /// **'Notifiche Preferiti'**
  String get favoriteNotifications;

  /// No description provided for @favoriteNotificationsDesc.
  ///
  /// In it, this message translates to:
  /// **'Notifiche per le tue squadre preferite'**
  String get favoriteNotificationsDesc;

  /// No description provided for @clearCache.
  ///
  /// In it, this message translates to:
  /// **'Cancella Cache'**
  String get clearCache;

  /// No description provided for @clearCacheDesc.
  ///
  /// In it, this message translates to:
  /// **'Libera spazio eliminando i dati in cache'**
  String get clearCacheDesc;

  /// No description provided for @clearCacheConfirm.
  ///
  /// In it, this message translates to:
  /// **'Vuoi cancellare tutti i dati in cache?'**
  String get clearCacheConfirm;

  /// No description provided for @clearCacheSuccess.
  ///
  /// In it, this message translates to:
  /// **'Cache cancellata con successo'**
  String get clearCacheSuccess;

  /// No description provided for @forceUpdate.
  ///
  /// In it, this message translates to:
  /// **'Forza Aggiornamento'**
  String get forceUpdate;

  /// No description provided for @updateData.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna Dati'**
  String get updateData;

  /// No description provided for @updateDataDesc.
  ///
  /// In it, this message translates to:
  /// **'Scarica gli ultimi dati disponibili'**
  String get updateDataDesc;

  /// No description provided for @updating.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamento in corso...'**
  String get updating;

  /// No description provided for @updateSuccess.
  ///
  /// In it, this message translates to:
  /// **'Dati aggiornati con successo'**
  String get updateSuccess;

  /// No description provided for @manageFavorites.
  ///
  /// In it, this message translates to:
  /// **'Gestisci Preferiti'**
  String get manageFavorites;

  /// No description provided for @manageFavoritesDesc.
  ///
  /// In it, this message translates to:
  /// **'Modifica le tue squadre preferite'**
  String get manageFavoritesDesc;

  /// No description provided for @removeAllFavorites.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi Tutti'**
  String get removeAllFavorites;

  /// No description provided for @removeAllFavoritesDesc.
  ///
  /// In it, this message translates to:
  /// **'Elimina tutte le squadre preferite'**
  String get removeAllFavoritesDesc;

  /// No description provided for @removeAllFavoritesConfirm.
  ///
  /// In it, this message translates to:
  /// **'Vuoi rimuovere tutte le squadre dai preferiti?'**
  String get removeAllFavoritesConfirm;

  /// No description provided for @removeAllFavoritesSuccess.
  ///
  /// In it, this message translates to:
  /// **'Tutti i preferiti sono stati rimossi'**
  String get removeAllFavoritesSuccess;

  /// No description provided for @deleteAll.
  ///
  /// In it, this message translates to:
  /// **'Elimina Tutto'**
  String get deleteAll;

  /// No description provided for @version.
  ///
  /// In it, this message translates to:
  /// **'Versione'**
  String get version;

  /// No description provided for @credits.
  ///
  /// In it, this message translates to:
  /// **'Crediti'**
  String get credits;

  /// No description provided for @apiProvider.
  ///
  /// In it, this message translates to:
  /// **'Provider API'**
  String get apiProvider;

  /// No description provided for @info.
  ///
  /// In it, this message translates to:
  /// **'Informazioni'**
  String get info;

  /// No description provided for @appVersion.
  ///
  /// In it, this message translates to:
  /// **'Versione App'**
  String get appVersion;

  /// No description provided for @beta.
  ///
  /// In it, this message translates to:
  /// **'Beta'**
  String get beta;

  /// No description provided for @reportBug.
  ///
  /// In it, this message translates to:
  /// **'Segnala un Bug'**
  String get reportBug;

  /// No description provided for @reportBugEmail.
  ///
  /// In it, this message translates to:
  /// **'Invia email a support@soccerpulse.com'**
  String get reportBugEmail;

  /// No description provided for @comingSoon.
  ///
  /// In it, this message translates to:
  /// **'Funzionalità in arrivo!'**
  String get comingSoon;

  /// No description provided for @madeWithLove.
  ///
  /// In it, this message translates to:
  /// **'Fatto con ❤️ per gli amanti del calcio'**
  String get madeWithLove;

  /// No description provided for @appTitle.
  ///
  /// In it, this message translates to:
  /// **'SoccerPulse'**
  String get appTitle;

  /// No description provided for @appDescription.
  ///
  /// In it, this message translates to:
  /// **'La tua app definitiva per seguire il calcio in tempo reale'**
  String get appDescription;

  /// No description provided for @features.
  ///
  /// In it, this message translates to:
  /// **'Caratteristiche:'**
  String get features;

  /// No description provided for @featureLiveMatches.
  ///
  /// In it, this message translates to:
  /// **'• Partite in tempo reale'**
  String get featureLiveMatches;

  /// No description provided for @featureStandings.
  ///
  /// In it, this message translates to:
  /// **'• Classifiche aggiornate'**
  String get featureStandings;

  /// No description provided for @featureFavorites.
  ///
  /// In it, this message translates to:
  /// **'• Squadre preferite'**
  String get featureFavorites;

  /// No description provided for @featureStats.
  ///
  /// In it, this message translates to:
  /// **'• Statistiche dettagliate'**
  String get featureStats;

  /// No description provided for @featureLineups.
  ///
  /// In it, this message translates to:
  /// **'• Formazioni e lineup'**
  String get featureLineups;

  /// No description provided for @poweredBy.
  ///
  /// In it, this message translates to:
  /// **'Powered by:'**
  String get poweredBy;

  /// No description provided for @apiSports.
  ///
  /// In it, this message translates to:
  /// **'• API-Football per i dati'**
  String get apiSports;

  /// No description provided for @flutterDart.
  ///
  /// In it, this message translates to:
  /// **'• Flutter & Dart'**
  String get flutterDart;

  /// No description provided for @material3.
  ///
  /// In it, this message translates to:
  /// **'• Material Design 3'**
  String get material3;

  /// No description provided for @openSourceLibs.
  ///
  /// In it, this message translates to:
  /// **'Librerie Open Source:'**
  String get openSourceLibs;

  /// No description provided for @libProvider.
  ///
  /// In it, this message translates to:
  /// **'• Provider'**
  String get libProvider;

  /// No description provided for @libCachedImage.
  ///
  /// In it, this message translates to:
  /// **'• Cached Network Image'**
  String get libCachedImage;

  /// No description provided for @libAnimate.
  ///
  /// In it, this message translates to:
  /// **'• Flutter Animate'**
  String get libAnimate;

  /// No description provided for @libShimmer.
  ///
  /// In it, this message translates to:
  /// **'• Shimmer'**
  String get libShimmer;

  /// No description provided for @libSlidable.
  ///
  /// In it, this message translates to:
  /// **'• Flutter Slidable'**
  String get libSlidable;

  /// No description provided for @copyright.
  ///
  /// In it, this message translates to:
  /// **'© 2024 SoccerPulse. Tutti i diritti riservati.'**
  String get copyright;

  /// No description provided for @close.
  ///
  /// In it, this message translates to:
  /// **'Chiudi'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In it, this message translates to:
  /// **'Conferma'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get save;

  /// No description provided for @selectLeague.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Campionato'**
  String get selectLeague;

  /// No description provided for @popularLeagues.
  ///
  /// In it, this message translates to:
  /// **'Campionati Popolari'**
  String get popularLeagues;

  /// No description provided for @selectTeam.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Squadra'**
  String get selectTeam;

  /// No description provided for @selectTeams.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Squadre'**
  String get selectTeams;

  /// No description provided for @selectTwoTeams.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Due Squadre'**
  String get selectTwoTeams;

  /// No description provided for @teamsSelected.
  ///
  /// In it, this message translates to:
  /// **'squadre selezionate'**
  String get teamsSelected;

  /// No description provided for @chooseTeams.
  ///
  /// In it, this message translates to:
  /// **'Scegli le Squadre'**
  String get chooseTeams;

  /// No description provided for @selectFirstTeam.
  ///
  /// In it, this message translates to:
  /// **'Seleziona prima squadra'**
  String get selectFirstTeam;

  /// No description provided for @selectSecondTeam.
  ///
  /// In it, this message translates to:
  /// **'Seleziona seconda squadra'**
  String get selectSecondTeam;

  /// No description provided for @searchTeam.
  ///
  /// In it, this message translates to:
  /// **'Cerca squadra...'**
  String get searchTeam;

  /// No description provided for @noTeamsFound.
  ///
  /// In it, this message translates to:
  /// **'Nessuna squadra trovata'**
  String get noTeamsFound;

  /// No description provided for @team.
  ///
  /// In it, this message translates to:
  /// **'Squadra'**
  String get team;

  /// No description provided for @teams.
  ///
  /// In it, this message translates to:
  /// **'squadre'**
  String get teams;

  /// No description provided for @headToHead.
  ///
  /// In it, this message translates to:
  /// **'Scontro Diretto'**
  String get headToHead;

  /// No description provided for @overallStats.
  ///
  /// In it, this message translates to:
  /// **'Statistiche Generali'**
  String get overallStats;

  /// No description provided for @wins.
  ///
  /// In it, this message translates to:
  /// **'Vittorie'**
  String get wins;

  /// No description provided for @draws.
  ///
  /// In it, this message translates to:
  /// **'Pareggi'**
  String get draws;

  /// No description provided for @losses.
  ///
  /// In it, this message translates to:
  /// **'Sconfitte'**
  String get losses;

  /// No description provided for @totalMatches2.
  ///
  /// In it, this message translates to:
  /// **'Partite Totali'**
  String get totalMatches2;

  /// No description provided for @goalsScored.
  ///
  /// In it, this message translates to:
  /// **'Gol Segnati'**
  String get goalsScored;

  /// No description provided for @lastMatches.
  ///
  /// In it, this message translates to:
  /// **'Ultime Partite'**
  String get lastMatches;

  /// No description provided for @biggestWin.
  ///
  /// In it, this message translates to:
  /// **'Vittoria più Larga'**
  String get biggestWin;

  /// No description provided for @averageGoals.
  ///
  /// In it, this message translates to:
  /// **'Media Gol/Partita'**
  String get averageGoals;

  /// No description provided for @prediction.
  ///
  /// In it, this message translates to:
  /// **'Predizione'**
  String get prediction;

  /// No description provided for @basedOnHistory.
  ///
  /// In it, this message translates to:
  /// **'Basata sullo storico'**
  String get basedOnHistory;

  /// No description provided for @noH2HData.
  ///
  /// In it, this message translates to:
  /// **'Nessun Dato Disponibile'**
  String get noH2HData;

  /// No description provided for @noH2HDataDesc.
  ///
  /// In it, this message translates to:
  /// **'Non ci sono scontri diretti tra queste squadre'**
  String get noH2HDataDesc;

  /// No description provided for @totalMeetings.
  ///
  /// In it, this message translates to:
  /// **'Incontri Totali'**
  String get totalMeetings;

  /// No description provided for @victories.
  ///
  /// In it, this message translates to:
  /// **'Vittorie'**
  String get victories;

  /// No description provided for @avgGoalsPerMatch.
  ///
  /// In it, this message translates to:
  /// **'Media Gol/Partita'**
  String get avgGoalsPerMatch;

  /// No description provided for @favoriteTeam.
  ///
  /// In it, this message translates to:
  /// **'Squadra Favorita'**
  String get favoriteTeam;

  /// No description provided for @basedOnLast.
  ///
  /// In it, this message translates to:
  /// **'Basato sugli ultimi'**
  String get basedOnLast;

  /// No description provided for @meetings.
  ///
  /// In it, this message translates to:
  /// **'incontri'**
  String get meetings;

  /// No description provided for @matchHistory.
  ///
  /// In it, this message translates to:
  /// **'Storico Partite'**
  String get matchHistory;

  /// No description provided for @matches.
  ///
  /// In it, this message translates to:
  /// **'Partite'**
  String get matches;

  /// No description provided for @matchDetails.
  ///
  /// In it, this message translates to:
  /// **'Dettaglio Partita'**
  String get matchDetails;

  /// No description provided for @events.
  ///
  /// In it, this message translates to:
  /// **'Eventi'**
  String get events;

  /// No description provided for @lineups.
  ///
  /// In it, this message translates to:
  /// **'Formazioni'**
  String get lineups;

  /// No description provided for @possession.
  ///
  /// In it, this message translates to:
  /// **'Possesso Palla'**
  String get possession;

  /// No description provided for @shots.
  ///
  /// In it, this message translates to:
  /// **'Tiri'**
  String get shots;

  /// No description provided for @shotsOnTarget.
  ///
  /// In it, this message translates to:
  /// **'Tiri in Porta'**
  String get shotsOnTarget;

  /// No description provided for @corners.
  ///
  /// In it, this message translates to:
  /// **'Calci d\'Angolo'**
  String get corners;

  /// No description provided for @fouls.
  ///
  /// In it, this message translates to:
  /// **'Falli'**
  String get fouls;

  /// No description provided for @cards.
  ///
  /// In it, this message translates to:
  /// **'Cartellini'**
  String get cards;

  /// No description provided for @noStatsAvailable.
  ///
  /// In it, this message translates to:
  /// **'Nessuna Statistica Disponibile'**
  String get noStatsAvailable;

  /// No description provided for @noEventsAvailable.
  ///
  /// In it, this message translates to:
  /// **'Nessun Evento Disponibile'**
  String get noEventsAvailable;

  /// No description provided for @noLineupsAvailable.
  ///
  /// In it, this message translates to:
  /// **'Nessuna Formazione Disponibile'**
  String get noLineupsAvailable;

  /// No description provided for @statisticsNotAvailable.
  ///
  /// In it, this message translates to:
  /// **'Statistiche Non Disponibili'**
  String get statisticsNotAvailable;

  /// No description provided for @statisticsAvailableAfterMatch.
  ///
  /// In it, this message translates to:
  /// **'Le statistiche saranno disponibili dopo la partita'**
  String get statisticsAvailableAfterMatch;

  /// No description provided for @dataNotAvailable.
  ///
  /// In it, this message translates to:
  /// **'Dati non disponibili'**
  String get dataNotAvailable;

  /// No description provided for @lineupsNotAvailable.
  ///
  /// In it, this message translates to:
  /// **'Formazioni Non Disponibili'**
  String get lineupsNotAvailable;

  /// No description provided for @startingXI.
  ///
  /// In it, this message translates to:
  /// **'Titolari'**
  String get startingXI;

  /// No description provided for @substitutes.
  ///
  /// In it, this message translates to:
  /// **'Riserve'**
  String get substitutes;

  /// No description provided for @coach.
  ///
  /// In it, this message translates to:
  /// **'Allenatore'**
  String get coach;

  /// No description provided for @formation.
  ///
  /// In it, this message translates to:
  /// **'Modulo'**
  String get formation;

  /// No description provided for @goal.
  ///
  /// In it, this message translates to:
  /// **'Gol'**
  String get goal;

  /// No description provided for @yellowCard.
  ///
  /// In it, this message translates to:
  /// **'Cartellino Giallo'**
  String get yellowCard;

  /// No description provided for @redCard.
  ///
  /// In it, this message translates to:
  /// **'Cartellino Rosso'**
  String get redCard;

  /// No description provided for @substitution.
  ///
  /// In it, this message translates to:
  /// **'Sostituzione'**
  String get substitution;

  /// No description provided for @minute.
  ///
  /// In it, this message translates to:
  /// **'min'**
  String get minute;

  /// No description provided for @played.
  ///
  /// In it, this message translates to:
  /// **'G'**
  String get played;

  /// No description provided for @won.
  ///
  /// In it, this message translates to:
  /// **'V'**
  String get won;

  /// No description provided for @draw.
  ///
  /// In it, this message translates to:
  /// **'P'**
  String get draw;

  /// No description provided for @lost.
  ///
  /// In it, this message translates to:
  /// **'S'**
  String get lost;

  /// No description provided for @goalsFor.
  ///
  /// In it, this message translates to:
  /// **'GF'**
  String get goalsFor;

  /// No description provided for @goalsAgainst.
  ///
  /// In it, this message translates to:
  /// **'GS'**
  String get goalsAgainst;

  /// No description provided for @goalDifference.
  ///
  /// In it, this message translates to:
  /// **'DR'**
  String get goalDifference;

  /// No description provided for @points.
  ///
  /// In it, this message translates to:
  /// **'Pt'**
  String get points;

  /// No description provided for @form.
  ///
  /// In it, this message translates to:
  /// **'Forma'**
  String get form;

  /// No description provided for @position.
  ///
  /// In it, this message translates to:
  /// **'Pos'**
  String get position;

  /// No description provided for @venue.
  ///
  /// In it, this message translates to:
  /// **'Stadio'**
  String get venue;

  /// No description provided for @referee.
  ///
  /// In it, this message translates to:
  /// **'Arbitro'**
  String get referee;

  /// No description provided for @date.
  ///
  /// In it, this message translates to:
  /// **'Data'**
  String get date;

  /// No description provided for @time.
  ///
  /// In it, this message translates to:
  /// **'Ora'**
  String get time;

  /// No description provided for @status.
  ///
  /// In it, this message translates to:
  /// **'Stato'**
  String get status;

  /// No description provided for @finalText.
  ///
  /// In it, this message translates to:
  /// **'Finale'**
  String get finalText;

  /// No description provided for @scheduled.
  ///
  /// In it, this message translates to:
  /// **'Programmata'**
  String get scheduled;

  /// No description provided for @teamAnalytics.
  ///
  /// In it, this message translates to:
  /// **'Analytics'**
  String get teamAnalytics;

  /// No description provided for @performance.
  ///
  /// In it, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @pointsProgression.
  ///
  /// In it, this message translates to:
  /// **'Andamento Punti'**
  String get pointsProgression;

  /// No description provided for @goalsAnalysis.
  ///
  /// In it, this message translates to:
  /// **'Analisi Gol'**
  String get goalsAnalysis;

  /// No description provided for @teamRadar.
  ///
  /// In it, this message translates to:
  /// **'Radar Squadra'**
  String get teamRadar;

  /// No description provided for @goalTiming.
  ///
  /// In it, this message translates to:
  /// **'Quando Segnano'**
  String get goalTiming;

  /// No description provided for @attack.
  ///
  /// In it, this message translates to:
  /// **'Attacco'**
  String get attack;

  /// No description provided for @defense.
  ///
  /// In it, this message translates to:
  /// **'Difesa'**
  String get defense;

  /// No description provided for @consistency.
  ///
  /// In it, this message translates to:
  /// **'Costanza'**
  String get consistency;

  /// No description provided for @efficiency.
  ///
  /// In it, this message translates to:
  /// **'Efficienza'**
  String get efficiency;

  /// No description provided for @overallPerformance.
  ///
  /// In it, this message translates to:
  /// **'Performance Generale'**
  String get overallPerformance;

  /// No description provided for @attackStats.
  ///
  /// In it, this message translates to:
  /// **'Statistiche Attacco'**
  String get attackStats;

  /// No description provided for @defenseStats.
  ///
  /// In it, this message translates to:
  /// **'Statistiche Difesa'**
  String get defenseStats;

  /// No description provided for @winRate.
  ///
  /// In it, this message translates to:
  /// **'% Vittorie'**
  String get winRate;

  /// No description provided for @avgGoalsScored.
  ///
  /// In it, this message translates to:
  /// **'Media Gol Fatti'**
  String get avgGoalsScored;

  /// No description provided for @avgGoalsConceded.
  ///
  /// In it, this message translates to:
  /// **'Media Gol Subiti'**
  String get avgGoalsConceded;

  /// No description provided for @cleanSheets.
  ///
  /// In it, this message translates to:
  /// **'Porta Inviolata'**
  String get cleanSheets;

  /// No description provided for @bestAttack.
  ///
  /// In it, this message translates to:
  /// **'Miglior Attacco'**
  String get bestAttack;

  /// No description provided for @goalsConceded.
  ///
  /// In it, this message translates to:
  /// **'Gol Subiti'**
  String get goalsConceded;

  /// No description provided for @goalsConcedePerMatch.
  ///
  /// In it, this message translates to:
  /// **'Gol Subiti/Partita'**
  String get goalsConcedePerMatch;

  /// No description provided for @bestDefense.
  ///
  /// In it, this message translates to:
  /// **'Miglior Difesa'**
  String get bestDefense;

  /// No description provided for @yes.
  ///
  /// In it, this message translates to:
  /// **'Sì'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In it, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @liveUpdates.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamenti Live'**
  String get liveUpdates;

  /// No description provided for @pauseUpdates.
  ///
  /// In it, this message translates to:
  /// **'Pausa Aggiornamenti'**
  String get pauseUpdates;

  /// No description provided for @resumeUpdates.
  ///
  /// In it, this message translates to:
  /// **'Riprendi Aggiornamenti'**
  String get resumeUpdates;

  /// No description provided for @lastUpdated.
  ///
  /// In it, this message translates to:
  /// **'Ultimo aggiornamento'**
  String get lastUpdated;

  /// No description provided for @autoRefresh.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamento Automatico'**
  String get autoRefresh;

  /// No description provided for @autoRefreshDesc.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna automaticamente le partite live'**
  String get autoRefreshDesc;

  /// No description provided for @refreshInterval.
  ///
  /// In it, this message translates to:
  /// **'Intervallo Aggiornamento'**
  String get refreshInterval;

  /// No description provided for @refreshIntervalDesc.
  ///
  /// In it, this message translates to:
  /// **'Ogni 30 secondi'**
  String get refreshIntervalDesc;

  /// No description provided for @liveNotifications.
  ///
  /// In it, this message translates to:
  /// **'Notifiche Live'**
  String get liveNotifications;

  /// No description provided for @liveNotificationsDesc.
  ///
  /// In it, this message translates to:
  /// **'Ricevi notifiche per eventi live'**
  String get liveNotificationsDesc;

  /// No description provided for @vibrationFeedback.
  ///
  /// In it, this message translates to:
  /// **'Feedback Vibrazione'**
  String get vibrationFeedback;

  /// No description provided for @vibrationFeedbackDesc.
  ///
  /// In it, this message translates to:
  /// **'Vibra per gol e eventi importanti'**
  String get vibrationFeedbackDesc;

  /// No description provided for @soundEffects.
  ///
  /// In it, this message translates to:
  /// **'Effetti Sonori'**
  String get soundEffects;

  /// No description provided for @soundEffectsDesc.
  ///
  /// In it, this message translates to:
  /// **'Riproduci suoni per eventi'**
  String get soundEffectsDesc;

  /// No description provided for @advanced.
  ///
  /// In it, this message translates to:
  /// **'Avanzate'**
  String get advanced;

  /// No description provided for @formazioni.
  ///
  /// In it, this message translates to:
  /// **'Formazioni'**
  String get formazioni;

  /// No description provided for @keyEvents.
  ///
  /// In it, this message translates to:
  /// **'Eventi chiave'**
  String get keyEvents;

  /// No description provided for @chrono.
  ///
  /// In it, this message translates to:
  /// **'Crono'**
  String get chrono;

  /// No description provided for @offensive.
  ///
  /// In it, this message translates to:
  /// **'Azioni offensive'**
  String get offensive;

  /// No description provided for @discipline.
  ///
  /// In it, this message translates to:
  /// **'Disciplina'**
  String get discipline;

  /// No description provided for @other.
  ///
  /// In it, this message translates to:
  /// **'Altro'**
  String get other;

  /// No description provided for @goalNotif.
  ///
  /// In it, this message translates to:
  /// **'Goal'**
  String get goalNotif;

  /// No description provided for @assistNotif.
  ///
  /// In it, this message translates to:
  /// **'Assist'**
  String get assistNotif;

  /// No description provided for @shotsOnTargetNotif.
  ///
  /// In it, this message translates to:
  /// **'Tiri in porta'**
  String get shotsOnTargetNotif;

  /// No description provided for @keyPassesNotif.
  ///
  /// In it, this message translates to:
  /// **'Passaggi chiave'**
  String get keyPassesNotif;

  /// No description provided for @dribblesNotif.
  ///
  /// In it, this message translates to:
  /// **'Dribbling riusciti'**
  String get dribblesNotif;

  /// No description provided for @offsidesNotif.
  ///
  /// In it, this message translates to:
  /// **'Fuorigioco'**
  String get offsidesNotif;

  /// No description provided for @yellowCardNotif.
  ///
  /// In it, this message translates to:
  /// **'Cartellini gialli'**
  String get yellowCardNotif;

  /// No description provided for @redCardNotif.
  ///
  /// In it, this message translates to:
  /// **'Cartellini rossi'**
  String get redCardNotif;

  /// No description provided for @foulsCommittedNotif.
  ///
  /// In it, this message translates to:
  /// **'Falli commessi'**
  String get foulsCommittedNotif;

  /// No description provided for @foulsSufferedNotif.
  ///
  /// In it, this message translates to:
  /// **'Falli subiti'**
  String get foulsSufferedNotif;

  /// No description provided for @substitutionNotif.
  ///
  /// In it, this message translates to:
  /// **'Sostituzioni'**
  String get substitutionNotif;

  /// No description provided for @goalDesc.
  ///
  /// In it, this message translates to:
  /// **'Reti segnate'**
  String get goalDesc;

  /// No description provided for @assistDesc.
  ///
  /// In it, this message translates to:
  /// **'Passaggi decisivi'**
  String get assistDesc;

  /// No description provided for @shotsOnTargetDesc.
  ///
  /// In it, this message translates to:
  /// **'Tiri nello specchio'**
  String get shotsOnTargetDesc;

  /// No description provided for @keyPassesDesc.
  ///
  /// In it, this message translates to:
  /// **'Passaggi che creano occasioni'**
  String get keyPassesDesc;

  /// No description provided for @dribblesDesc.
  ///
  /// In it, this message translates to:
  /// **'Dribbling completati'**
  String get dribblesDesc;

  /// No description provided for @offsidesDesc.
  ///
  /// In it, this message translates to:
  /// **'Posizioni di offside'**
  String get offsidesDesc;

  /// No description provided for @yellowCardDesc.
  ///
  /// In it, this message translates to:
  /// **'Ammonizioni'**
  String get yellowCardDesc;

  /// No description provided for @redCardDesc.
  ///
  /// In it, this message translates to:
  /// **'Espulsioni'**
  String get redCardDesc;

  /// No description provided for @foulsCommittedDesc.
  ///
  /// In it, this message translates to:
  /// **'Falli fischiati contro'**
  String get foulsCommittedDesc;

  /// No description provided for @foulsSufferedDesc.
  ///
  /// In it, this message translates to:
  /// **'Falli subiti dal giocatore'**
  String get foulsSufferedDesc;

  /// No description provided for @substitutionDesc.
  ///
  /// In it, this message translates to:
  /// **'Entrata/uscita dal campo'**
  String get substitutionDesc;

  /// No description provided for @activateAll.
  ///
  /// In it, this message translates to:
  /// **'Attiva tutto'**
  String get activateAll;

  /// No description provided for @deactivate.
  ///
  /// In it, this message translates to:
  /// **'Disattiva'**
  String get deactivate;

  /// No description provided for @notificationsActive.
  ///
  /// In it, this message translates to:
  /// **'notifiche attive'**
  String get notificationsActive;

  /// No description provided for @noNotificationActive.
  ///
  /// In it, this message translates to:
  /// **'Nessuna notifica attiva'**
  String get noNotificationActive;

  /// No description provided for @onlyForThisMatch.
  ///
  /// In it, this message translates to:
  /// **'Solo per questa partita'**
  String get onlyForThisMatch;

  /// No description provided for @profile.
  ///
  /// In it, this message translates to:
  /// **'Profilo'**
  String get profile;

  /// No description provided for @compare.
  ///
  /// In it, this message translates to:
  /// **'Confronta'**
  String get compare;

  /// No description provided for @minutesPlayedLabel.
  ///
  /// In it, this message translates to:
  /// **'Minuti giocati'**
  String get minutesPlayedLabel;

  /// No description provided for @heatmap.
  ///
  /// In it, this message translates to:
  /// **'Heatmap'**
  String get heatmap;

  /// No description provided for @pres.
  ///
  /// In it, this message translates to:
  /// **'Pres.'**
  String get pres;

  /// No description provided for @cart.
  ///
  /// In it, this message translates to:
  /// **'Cart.'**
  String get cart;

  /// No description provided for @totalHome.
  ///
  /// In it, this message translates to:
  /// **'Totale'**
  String get totalHome;

  /// No description provided for @casa.
  ///
  /// In it, this message translates to:
  /// **'Casa'**
  String get casa;

  /// No description provided for @trasferta.
  ///
  /// In it, this message translates to:
  /// **'Trasferta'**
  String get trasferta;

  /// No description provided for @classifica.
  ///
  /// In it, this message translates to:
  /// **'Classifica'**
  String get classifica;

  /// No description provided for @marcatori.
  ///
  /// In it, this message translates to:
  /// **'Marcatori'**
  String get marcatori;

  /// No description provided for @assistman.
  ///
  /// In it, this message translates to:
  /// **'Assistman'**
  String get assistman;

  /// No description provided for @cleanSheet.
  ///
  /// In it, this message translates to:
  /// **'Clean Sheet'**
  String get cleanSheet;

  /// No description provided for @cartellini.
  ///
  /// In it, this message translates to:
  /// **'Cartellini'**
  String get cartellini;

  /// No description provided for @rendimento.
  ///
  /// In it, this message translates to:
  /// **'Rendimento'**
  String get rendimento;

  /// No description provided for @punti.
  ///
  /// In it, this message translates to:
  /// **'Punti'**
  String get punti;

  /// No description provided for @giocate.
  ///
  /// In it, this message translates to:
  /// **'Giocate'**
  String get giocate;

  /// No description provided for @vittorie.
  ///
  /// In it, this message translates to:
  /// **'Vittorie'**
  String get vittorie;

  /// No description provided for @pareggi.
  ///
  /// In it, this message translates to:
  /// **'Pareggi'**
  String get pareggi;

  /// No description provided for @sconfitte.
  ///
  /// In it, this message translates to:
  /// **'Sconfitte'**
  String get sconfitte;

  /// No description provided for @diffReti.
  ///
  /// In it, this message translates to:
  /// **'Diff. Reti'**
  String get diffReti;

  /// No description provided for @partite.
  ///
  /// In it, this message translates to:
  /// **'Partite'**
  String get partite;

  /// No description provided for @statistiche.
  ///
  /// In it, this message translates to:
  /// **'Statistiche'**
  String get statistiche;

  /// No description provided for @giocatori.
  ///
  /// In it, this message translates to:
  /// **'Giocatori'**
  String get giocatori;

  /// No description provided for @informazioni.
  ///
  /// In it, this message translates to:
  /// **'Informazioni'**
  String get informazioni;

  /// No description provided for @aggiungiGiocatore.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi Giocatore'**
  String get aggiungiGiocatore;

  /// No description provided for @squadre.
  ///
  /// In it, this message translates to:
  /// **'Squadre'**
  String get squadre;

  /// No description provided for @classifiche.
  ///
  /// In it, this message translates to:
  /// **'Classifiche'**
  String get classifiche;

  /// No description provided for @gPlusA.
  ///
  /// In it, this message translates to:
  /// **'G+A'**
  String get gPlusA;

  /// No description provided for @cleanSheetTab.
  ///
  /// In it, this message translates to:
  /// **'Clean Sheet'**
  String get cleanSheetTab;

  /// No description provided for @cartelliniTab.
  ///
  /// In it, this message translates to:
  /// **'Cartellini'**
  String get cartelliniTab;

  /// No description provided for @totale.
  ///
  /// In it, this message translates to:
  /// **'Totale'**
  String get totale;

  /// No description provided for @rendimentoSerieA.
  ///
  /// In it, this message translates to:
  /// **'Rendimento Serie A'**
  String get rendimentoSerieA;

  /// No description provided for @squadra.
  ///
  /// In it, this message translates to:
  /// **'Squadra'**
  String get squadra;

  /// No description provided for @gol.
  ///
  /// In it, this message translates to:
  /// **'Gol'**
  String get gol;

  /// No description provided for @classificaMarcatori.
  ///
  /// In it, this message translates to:
  /// **'Classifica Marcatori'**
  String get classificaMarcatori;

  /// No description provided for @classificaAssistman.
  ///
  /// In it, this message translates to:
  /// **'Classifica Assistman'**
  String get classificaAssistman;

  /// No description provided for @cerca.
  ///
  /// In it, this message translates to:
  /// **'Cerca'**
  String get cerca;

  /// No description provided for @notifiche.
  ///
  /// In it, this message translates to:
  /// **'Notifiche'**
  String get notifiche;

  /// No description provided for @impostazioni.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get impostazioni;

  /// No description provided for @aggiungiSquadra.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi Squadra'**
  String get aggiungiSquadra;

  /// No description provided for @nessunGiocatorePreferito.
  ///
  /// In it, this message translates to:
  /// **'Nessun Giocatore Preferito'**
  String get nessunGiocatorePreferito;

  /// No description provided for @aggiungiGiocatoriDesc.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi giocatori per seguire le loro prestazioni'**
  String get aggiungiGiocatoriDesc;

  /// No description provided for @nessunDato.
  ///
  /// In it, this message translates to:
  /// **'Nessun dato'**
  String get nessunDato;

  /// No description provided for @posizione.
  ///
  /// In it, this message translates to:
  /// **'Posizione'**
  String get posizione;

  /// No description provided for @sistema.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get sistema;

  /// No description provided for @searchPlayers.
  ///
  /// In it, this message translates to:
  /// **'Cerca giocatore...'**
  String get searchPlayers;

  /// No description provided for @possessoPalla.
  ///
  /// In it, this message translates to:
  /// **'Possesso Palla'**
  String get possessoPalla;

  /// No description provided for @tiri.
  ///
  /// In it, this message translates to:
  /// **'TIRI'**
  String get tiri;

  /// No description provided for @tiriTotali.
  ///
  /// In it, this message translates to:
  /// **'Tiri Totali'**
  String get tiriTotali;

  /// No description provided for @tiriInPorta.
  ///
  /// In it, this message translates to:
  /// **'Tiri in Porta'**
  String get tiriInPorta;

  /// No description provided for @tiriFuori.
  ///
  /// In it, this message translates to:
  /// **'Tiri Fuori'**
  String get tiriFuori;

  /// No description provided for @passaggi.
  ///
  /// In it, this message translates to:
  /// **'PASSAGGI'**
  String get passaggi;

  /// No description provided for @passaggiTotali.
  ///
  /// In it, this message translates to:
  /// **'Passaggi Totali'**
  String get passaggiTotali;

  /// No description provided for @passaggiPrecisi.
  ///
  /// In it, this message translates to:
  /// **'Passaggi Precisi'**
  String get passaggiPrecisi;

  /// No description provided for @passaggiChiave.
  ///
  /// In it, this message translates to:
  /// **'Passaggi Chiave'**
  String get passaggiChiave;

  /// No description provided for @crossRiusciti.
  ///
  /// In it, this message translates to:
  /// **'Cross Riusciti'**
  String get crossRiusciti;

  /// No description provided for @eventiChiave.
  ///
  /// In it, this message translates to:
  /// **'Eventi chiave'**
  String get eventiChiave;

  /// No description provided for @recenti.
  ///
  /// In it, this message translates to:
  /// **'Recenti'**
  String get recenti;

  /// No description provided for @intervallo.
  ///
  /// In it, this message translates to:
  /// **'INTERVALLO'**
  String get intervallo;

  /// No description provided for @falloTattico.
  ///
  /// In it, this message translates to:
  /// **'Fallo tattico'**
  String get falloTattico;

  /// No description provided for @falloSu.
  ///
  /// In it, this message translates to:
  /// **'Fallo su'**
  String get falloSu;

  /// No description provided for @calcioInizio.
  ///
  /// In it, this message translates to:
  /// **'CALCIO D\'INIZIO'**
  String get calcioInizio;

  /// No description provided for @finePartita.
  ///
  /// In it, this message translates to:
  /// **'FINE PARTITA'**
  String get finePartita;

  /// No description provided for @dribbling.
  ///
  /// In it, this message translates to:
  /// **'DRIBBLING'**
  String get dribbling;

  /// No description provided for @dribblingRiusciti.
  ///
  /// In it, this message translates to:
  /// **'Dribbling Riusciti'**
  String get dribblingRiusciti;

  /// No description provided for @dribblingTentati.
  ///
  /// In it, this message translates to:
  /// **'Dribbling Tentati'**
  String get dribblingTentati;

  /// No description provided for @duelli.
  ///
  /// In it, this message translates to:
  /// **'DUELLI'**
  String get duelli;

  /// No description provided for @duelliTotali.
  ///
  /// In it, this message translates to:
  /// **'Duelli Totali'**
  String get duelliTotali;

  /// No description provided for @duelliVinti.
  ///
  /// In it, this message translates to:
  /// **'Duelli Vinti'**
  String get duelliVinti;

  /// No description provided for @duelliAerei.
  ///
  /// In it, this message translates to:
  /// **'Duelli Aerei'**
  String get duelliAerei;

  /// No description provided for @difesa.
  ///
  /// In it, this message translates to:
  /// **'DIFESA'**
  String get difesa;

  /// No description provided for @contrasti.
  ///
  /// In it, this message translates to:
  /// **'Contrasti'**
  String get contrasti;

  /// No description provided for @intercettazioni.
  ///
  /// In it, this message translates to:
  /// **'Intercettazioni'**
  String get intercettazioni;

  /// No description provided for @salvataggi.
  ///
  /// In it, this message translates to:
  /// **'Salvataggi'**
  String get salvataggi;

  /// No description provided for @calciAngolo.
  ///
  /// In it, this message translates to:
  /// **'Calci d\'Angolo'**
  String get calciAngolo;

  /// No description provided for @falli.
  ///
  /// In it, this message translates to:
  /// **'Falli'**
  String get falli;

  /// No description provided for @fuorigioco.
  ///
  /// In it, this message translates to:
  /// **'Fuorigioco'**
  String get fuorigioco;

  /// No description provided for @attacco.
  ///
  /// In it, this message translates to:
  /// **'Attacco'**
  String get attacco;

  /// No description provided for @possesso.
  ///
  /// In it, this message translates to:
  /// **'Possesso'**
  String get possesso;

  /// No description provided for @fase.
  ///
  /// In it, this message translates to:
  /// **'Fase'**
  String get fase;

  /// No description provided for @faseOffensiva.
  ///
  /// In it, this message translates to:
  /// **'Fase Offensiva'**
  String get faseOffensiva;

  /// No description provided for @precisione.
  ///
  /// In it, this message translates to:
  /// **'Precisione'**
  String get precisione;

  /// No description provided for @matchday.
  ///
  /// In it, this message translates to:
  /// **'Giornata'**
  String get matchday;

  /// No description provided for @palleLunghe.
  ///
  /// In it, this message translates to:
  /// **'Palle Lunghe'**
  String get palleLunghe;

  /// No description provided for @generali.
  ///
  /// In it, this message translates to:
  /// **'GENERALI'**
  String get generali;

  /// No description provided for @rimesseLaterali.
  ///
  /// In it, this message translates to:
  /// **'Rimesse Laterali'**
  String get rimesseLaterali;

  /// No description provided for @contrastiTotali.
  ///
  /// In it, this message translates to:
  /// **'Contrasti Totali'**
  String get contrastiTotali;

  /// No description provided for @contrastiVinti.
  ///
  /// In it, this message translates to:
  /// **'Contrasti Vinti'**
  String get contrastiVinti;

  /// No description provided for @intercetti.
  ///
  /// In it, this message translates to:
  /// **'Intercetti'**
  String get intercetti;

  /// No description provided for @rinvii.
  ///
  /// In it, this message translates to:
  /// **'Rinvii'**
  String get rinvii;

  /// No description provided for @falliTotali.
  ///
  /// In it, this message translates to:
  /// **'Falli Totali'**
  String get falliTotali;

  /// No description provided for @cartelliniGialli.
  ///
  /// In it, this message translates to:
  /// **'Cartellini Gialli'**
  String get cartelliniGialli;

  /// No description provided for @cartelliniRossi.
  ///
  /// In it, this message translates to:
  /// **'Cartellini Rossi'**
  String get cartelliniRossi;

  /// No description provided for @disciplinaSection.
  ///
  /// In it, this message translates to:
  /// **'DISCIPLINA'**
  String get disciplinaSection;

  /// No description provided for @proteste.
  ///
  /// In it, this message translates to:
  /// **'Proteste'**
  String get proteste;

  /// No description provided for @falloSuPlayer.
  ///
  /// In it, this message translates to:
  /// **'Fallo su'**
  String get falloSuPlayer;

  /// No description provided for @fuorigiocoAttivo.
  ///
  /// In it, this message translates to:
  /// **'Fuorigioco attivo'**
  String get fuorigiocoAttivo;

  /// No description provided for @fuorigiocoPassivo.
  ///
  /// In it, this message translates to:
  /// **'Fuorigioco passivo'**
  String get fuorigiocoPassivo;

  /// No description provided for @falliLabel.
  ///
  /// In it, this message translates to:
  /// **'Falli'**
  String get falliLabel;

  /// No description provided for @calciDAngolo.
  ///
  /// In it, this message translates to:
  /// **'Calci d\'Angolo'**
  String get calciDAngolo;

  /// No description provided for @statisticheStagione.
  ///
  /// In it, this message translates to:
  /// **'Statistiche Stagione 2023/24'**
  String get statisticheStagione;

  /// No description provided for @minuti.
  ///
  /// In it, this message translates to:
  /// **'Minuti'**
  String get minuti;

  /// No description provided for @ammonizioni.
  ///
  /// In it, this message translates to:
  /// **'Ammonizioni'**
  String get ammonizioni;

  /// No description provided for @mediaVoto.
  ///
  /// In it, this message translates to:
  /// **'Media voto'**
  String get mediaVoto;

  /// No description provided for @attaccoSection.
  ///
  /// In it, this message translates to:
  /// **'Attacco'**
  String get attaccoSection;

  /// No description provided for @possessoSection.
  ///
  /// In it, this message translates to:
  /// **'Possesso'**
  String get possessoSection;

  /// No description provided for @tiriSection.
  ///
  /// In it, this message translates to:
  /// **'Tiri'**
  String get tiriSection;

  /// No description provided for @passaggiSection.
  ///
  /// In it, this message translates to:
  /// **'Passaggi'**
  String get passaggiSection;

  /// No description provided for @difesaSection.
  ///
  /// In it, this message translates to:
  /// **'Difesa'**
  String get difesaSection;

  /// No description provided for @disciplinaLabel.
  ///
  /// In it, this message translates to:
  /// **'Disciplina'**
  String get disciplinaLabel;

  /// No description provided for @presenze.
  ///
  /// In it, this message translates to:
  /// **'Presenze'**
  String get presenze;

  /// No description provided for @dribblingLabel.
  ///
  /// In it, this message translates to:
  /// **'Dribbling'**
  String get dribblingLabel;

  /// No description provided for @duelliLabel.
  ///
  /// In it, this message translates to:
  /// **'Duelli'**
  String get duelliLabel;

  /// No description provided for @azioniDiGioco.
  ///
  /// In it, this message translates to:
  /// **'Azioni di gioco'**
  String get azioniDiGioco;

  /// No description provided for @calcioPiazzato.
  ///
  /// In it, this message translates to:
  /// **'Calcio piazzato'**
  String get calcioPiazzato;

  /// No description provided for @titoloPassaggi.
  ///
  /// In it, this message translates to:
  /// **'Passaggi'**
  String get titoloPassaggi;

  /// No description provided for @titoloTiri.
  ///
  /// In it, this message translates to:
  /// **'Tiri'**
  String get titoloTiri;

  /// No description provided for @titoloAttacco.
  ///
  /// In it, this message translates to:
  /// **'Attacco'**
  String get titoloAttacco;

  /// No description provided for @titoloDifesa.
  ///
  /// In it, this message translates to:
  /// **'Difesa'**
  String get titoloDifesa;

  /// No description provided for @titoloPossesso.
  ///
  /// In it, this message translates to:
  /// **'Possesso'**
  String get titoloPossesso;

  /// No description provided for @mappaTiri.
  ///
  /// In it, this message translates to:
  /// **'Mappa Tiri'**
  String get mappaTiri;

  /// No description provided for @attaccoTab.
  ///
  /// In it, this message translates to:
  /// **'Attacco'**
  String get attaccoTab;

  /// No description provided for @passaggiTab.
  ///
  /// In it, this message translates to:
  /// **'Passaggi'**
  String get passaggiTab;

  /// No description provided for @difensiva.
  ///
  /// In it, this message translates to:
  /// **'Difensiva'**
  String get difensiva;

  /// No description provided for @grandiOccasioniRealizzate.
  ///
  /// In it, this message translates to:
  /// **'Grandi occasioni realizzate'**
  String get grandiOccasioniRealizzate;

  /// No description provided for @grandiOccasioniMancate.
  ///
  /// In it, this message translates to:
  /// **'Grandi occasioni mancate'**
  String get grandiOccasioniMancate;

  /// No description provided for @tocchiAreaAvversaria.
  ///
  /// In it, this message translates to:
  /// **'Tocchi nell\'area avversaria'**
  String get tocchiAreaAvversaria;

  /// No description provided for @falliTerzoOffensivo.
  ///
  /// In it, this message translates to:
  /// **'Falli avversari nel terzo offensivo'**
  String get falliTerzoOffensivo;

  /// No description provided for @attacchiPericolosi.
  ///
  /// In it, this message translates to:
  /// **'Attacchi pericolosi'**
  String get attacchiPericolosi;

  /// No description provided for @attacchiLabel.
  ///
  /// In it, this message translates to:
  /// **'Attacchi'**
  String get attacchiLabel;

  /// No description provided for @retePassaggi.
  ///
  /// In it, this message translates to:
  /// **'Rete passaggi'**
  String get retePassaggi;

  /// No description provided for @azioniDifensive.
  ///
  /// In it, this message translates to:
  /// **'Azioni difensive'**
  String get azioniDifensive;

  /// No description provided for @radarDuelli.
  ///
  /// In it, this message translates to:
  /// **'Radar duelli'**
  String get radarDuelli;

  /// No description provided for @zoneCampo.
  ///
  /// In it, this message translates to:
  /// **'Zone campo'**
  String get zoneCampo;

  /// No description provided for @palloniRecuperati.
  ///
  /// In it, this message translates to:
  /// **'Palloni recuperati'**
  String get palloniRecuperati;

  /// No description provided for @passaggiRiusciti.
  ///
  /// In it, this message translates to:
  /// **'Passaggi riusciti'**
  String get passaggiRiusciti;

  /// No description provided for @passaggiLunghi.
  ///
  /// In it, this message translates to:
  /// **'Passaggi lunghi'**
  String get passaggiLunghi;

  /// No description provided for @passaggiCorti.
  ///
  /// In it, this message translates to:
  /// **'Passaggi corti'**
  String get passaggiCorti;

  /// No description provided for @crossTentati.
  ///
  /// In it, this message translates to:
  /// **'Cross tentati'**
  String get crossTentati;

  /// No description provided for @assist.
  ///
  /// In it, this message translates to:
  /// **'Assist'**
  String get assist;

  /// No description provided for @tocchi.
  ///
  /// In it, this message translates to:
  /// **'Tocchi'**
  String get tocchi;

  /// No description provided for @passaggiPrecisilabel.
  ///
  /// In it, this message translates to:
  /// **'Passaggi precisi'**
  String get passaggiPrecisilabel;

  /// No description provided for @passaggiProgressivi.
  ///
  /// In it, this message translates to:
  /// **'Passaggi progressivi'**
  String get passaggiProgressivi;

  /// No description provided for @passaggiTerzoOffensivo.
  ///
  /// In it, this message translates to:
  /// **'Passaggi nel\nterzo offensivo'**
  String get passaggiTerzoOffensivo;

  /// No description provided for @passaggiAvanzano.
  ///
  /// In it, this message translates to:
  /// **'Passaggi che avanzano il gioco di almeno 10m verso la porta'**
  String get passaggiAvanzano;

  /// No description provided for @passaggiTotaliLabel.
  ///
  /// In it, this message translates to:
  /// **'Passaggi totali'**
  String get passaggiTotaliLabel;

  /// No description provided for @rimuovi.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi'**
  String get rimuovi;

  /// No description provided for @aggiungiGiocatoriPerSeguire.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi giocatori per seguire le loro prestazioni'**
  String get aggiungiGiocatoriPerSeguire;

  /// No description provided for @notificheAttive.
  ///
  /// In it, this message translates to:
  /// **'notifiche attive'**
  String get notificheAttive;

  /// No description provided for @nessunaNotificaAttiva.
  ///
  /// In it, this message translates to:
  /// **'Nessuna notifica attiva'**
  String get nessunaNotificaAttiva;

  /// No description provided for @cartelliniGialliNotif.
  ///
  /// In it, this message translates to:
  /// **'Cartellini gialli'**
  String get cartelliniGialliNotif;

  /// No description provided for @ammonizioni2.
  ///
  /// In it, this message translates to:
  /// **'Ammonizioni e doppi gialli'**
  String get ammonizioni2;

  /// No description provided for @cartelliniRossiNotif.
  ///
  /// In it, this message translates to:
  /// **'Cartellini rossi'**
  String get cartelliniRossiNotif;

  /// No description provided for @espulsioniNotif.
  ///
  /// In it, this message translates to:
  /// **'Espulsioni dirette e per doppio giallo'**
  String get espulsioniNotif;

  /// No description provided for @calciAngoloDett.
  ///
  /// In it, this message translates to:
  /// **'Calci d\'angolo'**
  String get calciAngoloDett;

  /// No description provided for @cornerDesc.
  ///
  /// In it, this message translates to:
  /// **'Corner battuti da entrambe le squadre'**
  String get cornerDesc;

  /// No description provided for @falliNotif.
  ///
  /// In it, this message translates to:
  /// **'Falli'**
  String get falliNotif;

  /// No description provided for @falliDesc.
  ///
  /// In it, this message translates to:
  /// **'Falli commessi in campo'**
  String get falliDesc;

  /// No description provided for @partiteDelGiorno.
  ///
  /// In it, this message translates to:
  /// **'Partite del'**
  String get partiteDelGiorno;

  /// No description provided for @oggi.
  ///
  /// In it, this message translates to:
  /// **'Oggi'**
  String get oggi;

  /// No description provided for @ieri.
  ///
  /// In it, this message translates to:
  /// **'Ier'**
  String get ieri;

  /// No description provided for @statisticheAvanzate.
  ///
  /// In it, this message translates to:
  /// **'Statistiche Avanzate'**
  String get statisticheAvanzate;

  /// No description provided for @modulo.
  ///
  /// In it, this message translates to:
  /// **'Modulo'**
  String get modulo;

  /// No description provided for @titolari.
  ///
  /// In it, this message translates to:
  /// **'Titolari'**
  String get titolari;

  /// No description provided for @riserve.
  ///
  /// In it, this message translates to:
  /// **'Riserve'**
  String get riserve;

  /// No description provided for @allenatore.
  ///
  /// In it, this message translates to:
  /// **'Allenatore'**
  String get allenatore;

  /// No description provided for @sostituzione.
  ///
  /// In it, this message translates to:
  /// **'Sostituzione'**
  String get sostituzione;

  /// No description provided for @rigore.
  ///
  /// In it, this message translates to:
  /// **'Rigore'**
  String get rigore;

  /// No description provided for @secondoTempo.
  ///
  /// In it, this message translates to:
  /// **'Secondo tempo'**
  String get secondoTempo;

  /// No description provided for @primoTempo.
  ///
  /// In it, this message translates to:
  /// **'Primo tempo'**
  String get primoTempo;

  /// No description provided for @supplementari.
  ///
  /// In it, this message translates to:
  /// **'Supplementari'**
  String get supplementari;

  /// No description provided for @vediProfilo.
  ///
  /// In it, this message translates to:
  /// **'Vedi profilo'**
  String get vediProfilo;

  /// No description provided for @vediTutto.
  ///
  /// In it, this message translates to:
  /// **'Vedi tutto'**
  String get vediTutto;

  /// No description provided for @giocatore.
  ///
  /// In it, this message translates to:
  /// **'Giocatore'**
  String get giocatore;

  /// No description provided for @giocata.
  ///
  /// In it, this message translates to:
  /// **'Giocata'**
  String get giocata;

  /// No description provided for @tutti.
  ///
  /// In it, this message translates to:
  /// **'Tutti'**
  String get tutti;

  /// No description provided for @primoTempoShort.
  ///
  /// In it, this message translates to:
  /// **'1° Tempo'**
  String get primoTempoShort;

  /// No description provided for @secondoTempoShort.
  ///
  /// In it, this message translates to:
  /// **'2° Tempo'**
  String get secondoTempoShort;

  /// No description provided for @totali.
  ///
  /// In it, this message translates to:
  /// **'Totali'**
  String get totali;

  /// No description provided for @contrastiLabel.
  ///
  /// In it, this message translates to:
  /// **'Contrasti'**
  String get contrastiLabel;

  /// No description provided for @intercettiLabel.
  ///
  /// In it, this message translates to:
  /// **'Intercetti'**
  String get intercettiLabel;

  /// No description provided for @vintiLabel.
  ///
  /// In it, this message translates to:
  /// **'Vinti'**
  String get vintiLabel;

  /// No description provided for @topDifensori.
  ///
  /// In it, this message translates to:
  /// **'Top difensori'**
  String get topDifensori;

  /// No description provided for @toccaGiocatore.
  ///
  /// In it, this message translates to:
  /// **'Tocca un giocatore per filtrare il campo'**
  String get toccaGiocatore;

  /// No description provided for @centrocampo.
  ///
  /// In it, this message translates to:
  /// **'Centrocampo'**
  String get centrocampo;

  /// No description provided for @dominioTerritoriale.
  ///
  /// In it, this message translates to:
  /// **'Dominio Territoriale'**
  String get dominioTerritoriale;

  /// No description provided for @azioniMetaCampo.
  ///
  /// In it, this message translates to:
  /// **'% azioni nella metà campo avversaria'**
  String get azioniMetaCampo;

  /// No description provided for @territorio.
  ///
  /// In it, this message translates to:
  /// **'Territorio'**
  String get territorio;

  /// No description provided for @inPorta.
  ///
  /// In it, this message translates to:
  /// **'In Porta'**
  String get inPorta;

  /// No description provided for @fuori.
  ///
  /// In it, this message translates to:
  /// **'Fuori'**
  String get fuori;

  /// No description provided for @respinto.
  ///
  /// In it, this message translates to:
  /// **'Respinto'**
  String get respinto;

  /// No description provided for @situazione.
  ///
  /// In it, this message translates to:
  /// **'Situazione'**
  String get situazione;

  /// No description provided for @contropiede.
  ///
  /// In it, this message translates to:
  /// **'Contropiede'**
  String get contropiede;

  /// No description provided for @tipoDiTiro.
  ///
  /// In it, this message translates to:
  /// **'Tipo di tiro'**
  String get tipoDiTiro;

  /// No description provided for @tiroDiSinistro.
  ///
  /// In it, this message translates to:
  /// **'Tiro di sinistro'**
  String get tiroDiSinistro;

  /// No description provided for @tiroDiDestro.
  ///
  /// In it, this message translates to:
  /// **'Tiro di destro'**
  String get tiroDiDestro;

  /// No description provided for @colpoDiTesta.
  ///
  /// In it, this message translates to:
  /// **'Colpo di testa'**
  String get colpoDiTesta;

  /// No description provided for @esito.
  ///
  /// In it, this message translates to:
  /// **'Esito'**
  String get esito;

  /// No description provided for @zonaGol.
  ///
  /// In it, this message translates to:
  /// **'Zona gol'**
  String get zonaGol;

  /// No description provided for @inBassoSinistra.
  ///
  /// In it, this message translates to:
  /// **'In basso a sinistra'**
  String get inBassoSinistra;

  /// No description provided for @inBassoDestra.
  ///
  /// In it, this message translates to:
  /// **'In basso a destra'**
  String get inBassoDestra;

  /// No description provided for @inBassoAlCentro.
  ///
  /// In it, this message translates to:
  /// **'In basso al centro'**
  String get inBassoAlCentro;

  /// No description provided for @inAltoSinistra.
  ///
  /// In it, this message translates to:
  /// **'In alto a sinistra'**
  String get inAltoSinistra;

  /// No description provided for @inAltoDestra.
  ///
  /// In it, this message translates to:
  /// **'In alto a destra'**
  String get inAltoDestra;

  /// No description provided for @inAltoAlCentro.
  ///
  /// In it, this message translates to:
  /// **'In alto al centro'**
  String get inAltoAlCentro;

  /// No description provided for @alCentro.
  ///
  /// In it, this message translates to:
  /// **'Al centro'**
  String get alCentro;

  /// No description provided for @passaggiPrecisiLabel.
  ///
  /// In it, this message translates to:
  /// **'Passaggi precisi'**
  String get passaggiPrecisiLabel;

  /// No description provided for @passaggiChiaveLabel.
  ///
  /// In it, this message translates to:
  /// **'Passaggi chiave'**
  String get passaggiChiaveLabel;

  /// No description provided for @passaggiProgressiviLabel.
  ///
  /// In it, this message translates to:
  /// **'Passaggi progressivi'**
  String get passaggiProgressiviLabel;

  /// No description provided for @passaggiNelTerzo.
  ///
  /// In it, this message translates to:
  /// **'Passaggi nel terzo offensivo'**
  String get passaggiNelTerzo;

  /// No description provided for @palleLungheLabel.
  ///
  /// In it, this message translates to:
  /// **'Palle lunghe'**
  String get palleLungheLabel;

  /// No description provided for @palleCorte.
  ///
  /// In it, this message translates to:
  /// **'Palle corte'**
  String get palleCorte;

  /// No description provided for @recuperiPalla.
  ///
  /// In it, this message translates to:
  /// **'Recuperi palla'**
  String get recuperiPalla;

  /// No description provided for @salvataggiLabel.
  ///
  /// In it, this message translates to:
  /// **'Salvataggi'**
  String get salvataggiLabel;

  /// No description provided for @grandiOccRealizzate.
  ///
  /// In it, this message translates to:
  /// **'Grandi occasioni realizzate'**
  String get grandiOccRealizzate;

  /// No description provided for @grandiOccMancate.
  ///
  /// In it, this message translates to:
  /// **'Grandi occasioni mancate'**
  String get grandiOccMancate;

  /// No description provided for @tocchiAreaAvv.
  ///
  /// In it, this message translates to:
  /// **'Tocchi nell\'area avversaria'**
  String get tocchiAreaAvv;

  /// No description provided for @falliTerzoOff.
  ///
  /// In it, this message translates to:
  /// **'Falli avversari nel terzo offensivo'**
  String get falliTerzoOff;

  /// No description provided for @attacchiPeric.
  ///
  /// In it, this message translates to:
  /// **'Attacchi pericolosi'**
  String get attacchiPeric;

  /// No description provided for @attacchiTot.
  ///
  /// In it, this message translates to:
  /// **'Attacchi'**
  String get attacchiTot;

  /// No description provided for @assistLabel.
  ///
  /// In it, this message translates to:
  /// **'Assist'**
  String get assistLabel;

  /// No description provided for @tiriLabel.
  ///
  /// In it, this message translates to:
  /// **'Tiri'**
  String get tiriLabel;

  /// No description provided for @passaggiRLabel.
  ///
  /// In it, this message translates to:
  /// **'Passaggi'**
  String get passaggiRLabel;

  /// No description provided for @dribLabel.
  ///
  /// In it, this message translates to:
  /// **'Drib'**
  String get dribLabel;

  /// No description provided for @difLabel.
  ///
  /// In it, this message translates to:
  /// **'Dif'**
  String get difLabel;

  /// No description provided for @faseDifensiva.
  ///
  /// In it, this message translates to:
  /// **'Fase Difensiva'**
  String get faseDifensiva;

  /// No description provided for @topAttaccanti.
  ///
  /// In it, this message translates to:
  /// **'Top attaccanti'**
  String get topAttaccanti;

  /// No description provided for @topCentrocampisti.
  ///
  /// In it, this message translates to:
  /// **'Top centrocampisti'**
  String get topCentrocampisti;

  /// No description provided for @toccaPerFiltrare.
  ///
  /// In it, this message translates to:
  /// **'Tocca un giocatore per filtrare'**
  String get toccaPerFiltrare;

  /// No description provided for @azioneAperta.
  ///
  /// In it, this message translates to:
  /// **'Azione aperta'**
  String get azioneAperta;

  /// No description provided for @calcioPiazzatoLabel.
  ///
  /// In it, this message translates to:
  /// **'Calcio piazzato'**
  String get calcioPiazzatoLabel;

  /// No description provided for @reteLabel.
  ///
  /// In it, this message translates to:
  /// **'Rete'**
  String get reteLabel;

  /// No description provided for @paratoLabel.
  ///
  /// In it, this message translates to:
  /// **'Parato'**
  String get paratoLabel;

  /// No description provided for @traversaLabel.
  ///
  /// In it, this message translates to:
  /// **'Traversa'**
  String get traversaLabel;

  /// No description provided for @paloLabel.
  ///
  /// In it, this message translates to:
  /// **'Palo'**
  String get paloLabel;

  /// No description provided for @xGLabel.
  ///
  /// In it, this message translates to:
  /// **'xG'**
  String get xGLabel;

  /// No description provided for @totaliCarriera.
  ///
  /// In it, this message translates to:
  /// **'Totali Carriera'**
  String get totaliCarriera;

  /// No description provided for @fuorigiocoLabel.
  ///
  /// In it, this message translates to:
  /// **'Fuorigioco'**
  String get fuorigiocoLabel;

  /// No description provided for @fuorigiocoFischiati.
  ///
  /// In it, this message translates to:
  /// **'Fuorigioco fischiati'**
  String get fuorigiocoFischiati;

  /// No description provided for @posizioniOffside.
  ///
  /// In it, this message translates to:
  /// **'Posizioni di offside segnalate'**
  String get posizioniOffside;

  /// No description provided for @tuttiTentativi.
  ///
  /// In it, this message translates to:
  /// **'Tutti i tentativi verso la porta'**
  String get tuttiTentativi;

  /// No description provided for @centrocampoSX.
  ///
  /// In it, this message translates to:
  /// **'Centrocampo SX'**
  String get centrocampoSX;

  /// No description provided for @centrocampoCSX.
  ///
  /// In it, this message translates to:
  /// **'Centrocampo CSX'**
  String get centrocampoCSX;

  /// No description provided for @centrocampoCDX.
  ///
  /// In it, this message translates to:
  /// **'Centrocampo CDX'**
  String get centrocampoCDX;

  /// No description provided for @centrocampoDX.
  ///
  /// In it, this message translates to:
  /// **'Centrocampo DX'**
  String get centrocampoDX;

  /// No description provided for @contrastiVintiLabel.
  ///
  /// In it, this message translates to:
  /// **'Contrasti (vinti)'**
  String get contrastiVintiLabel;

  /// No description provided for @notificaFuorigioco.
  ///
  /// In it, this message translates to:
  /// **'Notifica fuorigioco'**
  String get notificaFuorigioco;

  /// No description provided for @stagione.
  ///
  /// In it, this message translates to:
  /// **'Stagione'**
  String get stagione;

  /// No description provided for @carriera.
  ///
  /// In it, this message translates to:
  /// **'Carriera'**
  String get carriera;

  /// No description provided for @ultime5partite.
  ///
  /// In it, this message translates to:
  /// **'Ultime 5 partite'**
  String get ultime5partite;

  /// No description provided for @overallFC26.
  ///
  /// In it, this message translates to:
  /// **'Overall FC26'**
  String get overallFC26;

  /// No description provided for @rendimentoLabel.
  ///
  /// In it, this message translates to:
  /// **'Rendimento'**
  String get rendimentoLabel;

  /// No description provided for @partiteGiocate.
  ///
  /// In it, this message translates to:
  /// **'partite giocate'**
  String get partiteGiocate;

  /// No description provided for @vittoriePerc.
  ///
  /// In it, this message translates to:
  /// **'vittorie'**
  String get vittoriePerc;

  /// No description provided for @golLabel.
  ///
  /// In it, this message translates to:
  /// **'Gol'**
  String get golLabel;

  /// No description provided for @golFatti.
  ///
  /// In it, this message translates to:
  /// **'Gol fatti'**
  String get golFatti;

  /// No description provided for @golSubiti.
  ///
  /// In it, this message translates to:
  /// **'Gol subiti'**
  String get golSubiti;

  /// No description provided for @differenza.
  ///
  /// In it, this message translates to:
  /// **'Differenza'**
  String get differenza;

  /// No description provided for @mediaGolPartita.
  ///
  /// In it, this message translates to:
  /// **'Media gol/partita'**
  String get mediaGolPartita;

  /// No description provided for @puntiLabel.
  ///
  /// In it, this message translates to:
  /// **'Points'**
  String get puntiLabel;

  /// No description provided for @totaleLabel.
  ///
  /// In it, this message translates to:
  /// **'Totale'**
  String get totaleLabel;

  /// No description provided for @puntiPartita.
  ///
  /// In it, this message translates to:
  /// **'Punti/partita'**
  String get puntiPartita;

  /// No description provided for @posizioneLabel.
  ///
  /// In it, this message translates to:
  /// **'Posizione'**
  String get posizioneLabel;

  /// No description provided for @portiere.
  ///
  /// In it, this message translates to:
  /// **'PORTIERE'**
  String get portiere;

  /// No description provided for @difensore.
  ///
  /// In it, this message translates to:
  /// **'DIFENSORE'**
  String get difensore;

  /// No description provided for @centrocampista.
  ///
  /// In it, this message translates to:
  /// **'CENTROCAMPISTA'**
  String get centrocampista;

  /// No description provided for @attaccante.
  ///
  /// In it, this message translates to:
  /// **'ATTACCANTE'**
  String get attaccante;

  /// No description provided for @competizione.
  ///
  /// In it, this message translates to:
  /// **'Competizione'**
  String get competizione;

  /// No description provided for @campionato.
  ///
  /// In it, this message translates to:
  /// **'Campionato'**
  String get campionato;

  /// No description provided for @giornate.
  ///
  /// In it, this message translates to:
  /// **'Giornate'**
  String get giornate;

  /// No description provided for @zonaChampions.
  ///
  /// In it, this message translates to:
  /// **'Zona Champions League'**
  String get zonaChampions;

  /// No description provided for @puntiInPartite.
  ///
  /// In it, this message translates to:
  /// **'punti in'**
  String get puntiInPartite;

  /// No description provided for @golPartita.
  ///
  /// In it, this message translates to:
  /// **'Gol/partita'**
  String get golPartita;

  /// No description provided for @subitiPartita.
  ///
  /// In it, this message translates to:
  /// **'Subiti/partita'**
  String get subitiPartita;

  /// No description provided for @formaRecente.
  ///
  /// In it, this message translates to:
  /// **'Forma Recente'**
  String get formaRecente;

  /// No description provided for @sede.
  ///
  /// In it, this message translates to:
  /// **'Sede'**
  String get sede;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return SEn();
    case 'it': return SIt();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
