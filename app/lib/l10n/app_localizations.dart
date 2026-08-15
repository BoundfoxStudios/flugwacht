import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Flugwacht'**
  String get appTitle;

  /// No description provided for @tabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMap;

  /// No description provided for @tabList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get tabList;

  /// No description provided for @tabMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tabMore;

  /// No description provided for @listTitle.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get listTitle;

  /// DateFormat pattern for today's date in the list header, localized per language.
  ///
  /// In en, this message translates to:
  /// **'EEE, MMMM d'**
  String get listHeaderDateFormat;

  /// Empty state headline; the line break is part of the design.
  ///
  /// In en, this message translates to:
  /// **'No flight\non the list yet'**
  String get listEmptyHeadline;

  /// No description provided for @listEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a flight — Flugwacht tracks it automatically on its flight day and shows you when it arrives.'**
  String get listEmptyBody;

  /// No description provided for @listEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Add flight'**
  String get listEmptyCta;

  /// No description provided for @newFlightTitle.
  ///
  /// In en, this message translates to:
  /// **'New flight'**
  String get newFlightTitle;

  /// No description provided for @newFlightCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get newFlightCancel;

  /// No description provided for @newFlightKindFlightNumber.
  ///
  /// In en, this message translates to:
  /// **'Flight number'**
  String get newFlightKindFlightNumber;

  /// No description provided for @newFlightKindRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get newFlightKindRegistration;

  /// No description provided for @newFlightKindHexAddress.
  ///
  /// In en, this message translates to:
  /// **'Hex'**
  String get newFlightKindHexAddress;

  /// No description provided for @newFlightFlightNumberHint.
  ///
  /// In en, this message translates to:
  /// **'As printed on your ticket, e.g. LH 400'**
  String get newFlightFlightNumberHint;

  /// No description provided for @newFlightRegistrationHint.
  ///
  /// In en, this message translates to:
  /// **'The registration of the aircraft, e.g. D-AIMA'**
  String get newFlightRegistrationHint;

  /// No description provided for @newFlightHexAddressHint.
  ///
  /// In en, this message translates to:
  /// **'The six digit ICAO address, e.g. 3C6444'**
  String get newFlightHexAddressHint;

  /// No description provided for @newFlightLowCostCarrierHint.
  ///
  /// In en, this message translates to:
  /// **'Ryanair, easyJet and Wizz Air often fly under a callsign that does not match the flight number. If your flight stays unfound, add it by registration or hex address.'**
  String get newFlightLowCostCarrierHint;

  /// No description provided for @newFlightDepartureDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Departure date'**
  String get newFlightDepartureDateLabel;

  /// No description provided for @newFlightDepartureDateHint.
  ///
  /// In en, this message translates to:
  /// **'Day of departure · opens the system picker · night flights count into the next day'**
  String get newFlightDepartureDateHint;

  /// DateFormat pattern for the departure date field, localized per language.
  ///
  /// In en, this message translates to:
  /// **'EEE, MMMM d, y'**
  String get newFlightDepartureDateFormat;

  /// No description provided for @newFlightNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get newFlightNoteLabel;

  /// No description provided for @newFlightNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Whatever helps you recognise the flight, e.g. Anna & Ben'**
  String get newFlightNoteHint;

  /// No description provided for @newFlightSubmit.
  ///
  /// In en, this message translates to:
  /// **'Add flight'**
  String get newFlightSubmit;

  /// No description provided for @newFlightDatePickerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get newFlightDatePickerConfirm;

  /// No description provided for @newFlightPreviewFound.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get newFlightPreviewFound;

  /// No description provided for @newFlightPreviewRouteUnknown.
  ///
  /// In en, this message translates to:
  /// **'Route unknown'**
  String get newFlightPreviewRouteUnknown;

  /// No description provided for @newFlightPreviewCallsign.
  ///
  /// In en, this message translates to:
  /// **'Callsign: {callsign}'**
  String newFlightPreviewCallsign(String callsign);

  /// No description provided for @newFlightPreviewRoute.
  ///
  /// In en, this message translates to:
  /// **'{origin} → {destination}'**
  String newFlightPreviewRoute(String origin, String destination);

  /// No description provided for @newFlightPreviewRouteWithAirline.
  ///
  /// In en, this message translates to:
  /// **'{origin} → {destination} · {airline}'**
  String newFlightPreviewRouteWithAirline(
    String origin,
    String destination,
    String airline,
  );

  /// No description provided for @listPastSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get listPastSectionTitle;

  /// DateFormat pattern for the departure date on a planned row, localized per language.
  ///
  /// In en, this message translates to:
  /// **'EEE, MMM d'**
  String get listPlannedDateFormat;

  /// No description provided for @flightTitleWithNote.
  ///
  /// In en, this message translates to:
  /// **'{lookupValue} · {note}'**
  String flightTitleWithNote(String lookupValue, String note);

  /// No description provided for @flightRoute.
  ///
  /// In en, this message translates to:
  /// **'{origin} → {destination}'**
  String flightRoute(String origin, String destination);

  /// No description provided for @flightRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{route} · {state}'**
  String flightRowSubtitle(String route, String state);

  /// No description provided for @flightBadgeLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get flightBadgeLive;

  /// No description provided for @flightBadgeNoSignal.
  ///
  /// In en, this message translates to:
  /// **'No signal'**
  String get flightBadgeNoSignal;

  /// No description provided for @mapAttributionOpenStreetMap.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap'**
  String get mapAttributionOpenStreetMap;

  /// No description provided for @flightRowWaitingForSignal.
  ///
  /// In en, this message translates to:
  /// **'waiting for signal'**
  String get flightRowWaitingForSignal;

  /// No description provided for @flightRowToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get flightRowToday;

  /// No description provided for @flightRowLanded.
  ///
  /// In en, this message translates to:
  /// **'landed ✓'**
  String get flightRowLanded;

  /// No description provided for @flightRowMissed.
  ///
  /// In en, this message translates to:
  /// **'missed'**
  String get flightRowMissed;

  /// No description provided for @flightStatePlanned.
  ///
  /// In en, this message translates to:
  /// **'planned'**
  String get flightStatePlanned;

  /// No description provided for @flightStateWaiting.
  ///
  /// In en, this message translates to:
  /// **'waiting'**
  String get flightStateWaiting;

  /// No description provided for @flightStateLive.
  ///
  /// In en, this message translates to:
  /// **'live'**
  String get flightStateLive;

  /// No description provided for @flightStateNoSignal.
  ///
  /// In en, this message translates to:
  /// **'no signal'**
  String get flightStateNoSignal;

  /// No description provided for @flightStateEnded.
  ///
  /// In en, this message translates to:
  /// **'ended'**
  String get flightStateEnded;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
