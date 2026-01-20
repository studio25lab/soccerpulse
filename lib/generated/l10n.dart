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
