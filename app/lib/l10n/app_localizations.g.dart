import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.g.dart';
import 'app_localizations_en.g.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.g.dart';
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
  /// **'Flights'**
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

  /// No description provided for @newFlightDepartureTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Departure time (optional)'**
  String get newFlightDepartureTimeLabel;

  /// No description provided for @newFlightDepartureTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Scheduled departure · the search starts two hours before it'**
  String get newFlightDepartureTimeHint;

  /// No description provided for @newFlightDepartureTimePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get newFlightDepartureTimePlaceholder;

  /// No description provided for @newFlightDepartureTimeClear.
  ///
  /// In en, this message translates to:
  /// **'Clear the departure time'**
  String get newFlightDepartureTimeClear;

  /// DateFormat pattern for the departure time field, localized per language.
  ///
  /// In en, this message translates to:
  /// **'h:mm a'**
  String get newFlightDepartureTimeFormat;

  /// No description provided for @newFlightDepartureTimeOriginLocal.
  ///
  /// In en, this message translates to:
  /// **'In the origin\'s local time'**
  String get newFlightDepartureTimeOriginLocal;

  /// No description provided for @newFlightDepartureTimeDeviceFallback.
  ///
  /// In en, this message translates to:
  /// **'Without a route the time counts as your device time'**
  String get newFlightDepartureTimeDeviceFallback;

  /// No description provided for @newFlightDepartureTimeSearchingRoute.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the route to settle the clock'**
  String get newFlightDepartureTimeSearchingRoute;

  /// No description provided for @liveActivityReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Activity available'**
  String get liveActivityReminderTitle;

  /// No description provided for @liveActivityReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Follow {flight} on your Lock Screen today. Tap to start.'**
  String liveActivityReminderBody(String flight);

  /// No description provided for @settingsLiveActivityReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind me on the flight day'**
  String get settingsLiveActivityReminder;

  /// No description provided for @settingsLiveActivityHint.
  ///
  /// In en, this message translates to:
  /// **'Flugwacht sends you a notification on the flight day, so you can start the Live Activity from there.'**
  String get settingsLiveActivityHint;

  /// No description provided for @liveActivityArmLabel.
  ///
  /// In en, this message translates to:
  /// **'Live Activity on flight day'**
  String get liveActivityArmLabel;

  /// No description provided for @liveActivityDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Live Activities are switched off for Flugwacht in the system settings'**
  String get liveActivityDisabledHint;

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

  /// No description provided for @newFlightPreviewSearching.
  ///
  /// In en, this message translates to:
  /// **'Looking for the route'**
  String get newFlightPreviewSearching;

  /// No description provided for @newFlightPreviewChooseLeg.
  ///
  /// In en, this message translates to:
  /// **'Which leg is yours?'**
  String get newFlightPreviewChooseLeg;

  /// No description provided for @newFlightPreviewChooseLegHint.
  ///
  /// In en, this message translates to:
  /// **'The airline files the whole rotation under this number.'**
  String get newFlightPreviewChooseLegHint;

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
  /// **'Past · gone in 24 h'**
  String get listPastSectionTitle;

  /// No description provided for @listFlightDeleted.
  ///
  /// In en, this message translates to:
  /// **'{flight} deleted'**
  String listFlightDeleted(String flight);

  /// No description provided for @listUndoDelete.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get listUndoDelete;

  /// Screen-reader label of the delete affordance a swiped row reveals.
  ///
  /// In en, this message translates to:
  /// **'Delete flight'**
  String get listDeleteFlight;

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

  /// Accessibility label of the button that switches between the reduced and the OpenStreetMap style.
  ///
  /// In en, this message translates to:
  /// **'Switch map style'**
  String get mapStyleToggleLabel;

  /// Accessibility label of the button that frames the selected flight again.
  ///
  /// In en, this message translates to:
  /// **'Center on the flight'**
  String get mapRecenterLabel;

  /// Credit of the reduced style, whose vector tiles OpenFreeMap serves from OpenMapTiles data.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap · © OpenMapTiles'**
  String get mapAttributionOpenMapTiles;

  /// The credit of the rendered tiles next to the flight data source.
  ///
  /// In en, this message translates to:
  /// **'{attribution} · Data: {source}'**
  String mapAttributionWithSource(String attribution, String source);

  /// Title of the map legend that names the trail color of every source.
  ///
  /// In en, this message translates to:
  /// **'TRAIL BY SOURCE'**
  String get mapLegendTitle;

  /// Marks the legend row of the source the app is polling right now.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get mapLegendActive;

  /// Stands in for the arrival time of a flight without an estimate.
  ///
  /// In en, this message translates to:
  /// **'–:–'**
  String get mapSheetArrivalPlaceholder;

  /// Stands in for a measurement the flight has not reported.
  ///
  /// In en, this message translates to:
  /// **'–'**
  String get mapSheetValuePlaceholder;

  /// No description provided for @mapSheetAltitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get mapSheetAltitudeLabel;

  /// No description provided for @mapSheetSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get mapSheetSpeedLabel;

  /// No description provided for @mapSheetSignalLabel.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get mapSheetSignalLabel;

  /// No description provided for @mapSheetSignalSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s ago'**
  String mapSheetSignalSeconds(String seconds);

  /// No description provided for @mapSheetSignalMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String mapSheetSignalMinutes(String minutes);

  /// No description provided for @mapSheetSignalHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String mapSheetSignalHours(String hours);

  /// No description provided for @mapSheetSignalHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min ago'**
  String mapSheetSignalHoursMinutes(String hours, String minutes);

  /// Explains a coverage gap; the age comes from the signal age copy.
  ///
  /// In en, this message translates to:
  /// **'Last signal {age}. Over oceans there are often no receivers for 1–2 hours — the trail will come back.'**
  String mapSheetNoSignalInfo(String age);

  /// Explains what a flight without a first signal is being searched for.
  ///
  /// In en, this message translates to:
  /// **'Searching for {identity}. Receivers are often missing for one to two hours, the trail starts as soon as one sees the aircraft.'**
  String mapSheetWaitingInfo(String identity);

  /// No description provided for @mapSheetAltitudeValue.
  ///
  /// In en, this message translates to:
  /// **'{value} m'**
  String mapSheetAltitudeValue(String value);

  /// No description provided for @mapSheetSpeedValue.
  ///
  /// In en, this message translates to:
  /// **'{value} km/h'**
  String mapSheetSpeedValue(String value);

  /// No description provided for @mapSheetAltitudeValueFeet.
  ///
  /// In en, this message translates to:
  /// **'{value} ft'**
  String mapSheetAltitudeValueFeet(String value);

  /// No description provided for @mapSheetSpeedValueKnots.
  ///
  /// In en, this message translates to:
  /// **'{value} kt'**
  String mapSheetSpeedValueKnots(String value);

  /// The flight data source next to the credit of the rendered tiles.
  ///
  /// In en, this message translates to:
  /// **'Source: {source} · {attribution}'**
  String mapSheetSource(String source, String attribution);

  /// Link in the sheet of a flight without signal that switches to the next source.
  ///
  /// In en, this message translates to:
  /// **'Try another source'**
  String get mapSheetTryAnotherSource;

  /// No description provided for @flightArrivalLabel.
  ///
  /// In en, this message translates to:
  /// **'Arrival, your time'**
  String get flightArrivalLabel;

  /// DateFormat pattern for the estimated arrival, localized per language.
  ///
  /// In en, this message translates to:
  /// **'h:mm a'**
  String get flightArrivalTimeFormat;

  /// Marks an arrival that stopped moving because the signal did.
  ///
  /// In en, this message translates to:
  /// **'~{time}'**
  String flightArrivalFrozenTime(String time);

  /// No description provided for @flightArrivalRemainingMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left'**
  String flightArrivalRemainingMinutes(String minutes);

  /// No description provided for @flightArrivalRemainingHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h left'**
  String flightArrivalRemainingHours(String hours);

  /// No description provided for @flightArrivalRemainingHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min left'**
  String flightArrivalRemainingHoursMinutes(String hours, String minutes);

  /// Dates the frozen arrival with the signal age, e.g. "As of 42 min ago".
  ///
  /// In en, this message translates to:
  /// **'As of {age}'**
  String flightArrivalAsOf(String age);

  /// No description provided for @flightArrivalLocalTime.
  ///
  /// In en, this message translates to:
  /// **'Local time {city} · {time}'**
  String flightArrivalLocalTime(String city, String time);

  /// Joins the arrival label and its detail into the hero cell's single line.
  ///
  /// In en, this message translates to:
  /// **'{label} · {detail}'**
  String flightArrivalSummary(String label, String detail);

  /// Names the first moment the app saw the flight off the ground, on a flight that has been up since today. That fix is not the takeoff, which may have happened earlier and unwatched, so the wording claims a lower bound rather than a departure time.
  ///
  /// In en, this message translates to:
  /// **'Airborne since {time}'**
  String flightAirborneSince(String time);

  /// The same as flightAirborneSince for a flight that has been up since an earlier day, which the bare clock time would read as today. The day is "yesterday" or a date.
  ///
  /// In en, this message translates to:
  /// **'Airborne since {day} {time}'**
  String flightAirborneSinceDay(String day, String time);

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

  /// No description provided for @flightRowYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get flightRowYesterday;

  /// No description provided for @flightRowPastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{route} · {day}'**
  String flightRowPastSubtitle(String route, String day);

  /// No description provided for @flightRowDepartureTime.
  ///
  /// In en, this message translates to:
  /// **'from {time}'**
  String flightRowDepartureTime(String time);

  /// DateFormat pattern for the departure time on a waiting row, localized per language.
  ///
  /// In en, this message translates to:
  /// **'h:mm a'**
  String get flightRowDepartureTimeFormat;

  /// No description provided for @flightRowDepartureTimeWithLocal.
  ///
  /// In en, this message translates to:
  /// **'from {deviceTime} · {localTime} local'**
  String flightRowDepartureTimeWithLocal(String deviceTime, String localTime);

  /// No description provided for @flightRowLanded.
  ///
  /// In en, this message translates to:
  /// **'landed ✓'**
  String get flightRowLanded;

  /// No description provided for @flightRowProbablyLanded.
  ///
  /// In en, this message translates to:
  /// **'probably landed'**
  String get flightRowProbablyLanded;

  /// No description provided for @flightRowMissed.
  ///
  /// In en, this message translates to:
  /// **'missed'**
  String get flightRowMissed;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSourceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Data source'**
  String get settingsSourceSectionTitle;

  /// No description provided for @settingsSourceExplainer.
  ///
  /// In en, this message translates to:
  /// **'All sources deliver the same values — they only differ in who is receiving your aircraft right now. Switching pays off when there are gaps; the trail carries on.'**
  String get settingsSourceExplainer;

  /// No description provided for @settingsUnitsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnitsSectionTitle;

  /// No description provided for @settingsUnitsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric (m, km/h)'**
  String get settingsUnitsMetric;

  /// No description provided for @settingsUnitsAviation.
  ///
  /// In en, this message translates to:
  /// **'Aviation (ft, kt)'**
  String get settingsUnitsAviation;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsDuringFlightTitle.
  ///
  /// In en, this message translates to:
  /// **'During the flight'**
  String get notificationsDuringFlightTitle;

  /// No description provided for @notificationsFlightDayTitle.
  ///
  /// In en, this message translates to:
  /// **'On the flight day'**
  String get notificationsFlightDayTitle;

  /// No description provided for @settingsNotificationDeparted.
  ///
  /// In en, this message translates to:
  /// **'Departed'**
  String get settingsNotificationDeparted;

  /// No description provided for @settingsNotificationArrivingSoon.
  ///
  /// In en, this message translates to:
  /// **'Arriving soon (~30 min)'**
  String get settingsNotificationArrivingSoon;

  /// No description provided for @settingsNotificationLanded.
  ///
  /// In en, this message translates to:
  /// **'Landed'**
  String get settingsNotificationLanded;

  /// No description provided for @settingsNotificationsDelivery.
  ///
  /// In en, this message translates to:
  /// **'Departed and landed only arrive while Flugwacht is open. Arriving soon also reaches you with the app closed, at roughly the right moment.'**
  String get settingsNotificationsDelivery;

  /// No description provided for @settingsNotificationsDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications for Flugwacht are switched off in your system settings.'**
  String get settingsNotificationsDenied;

  /// No description provided for @settingsNotificationsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This device could not set notifications up, so the switches above stay without effect.'**
  String get settingsNotificationsUnavailable;

  /// No description provided for @notificationOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn notifications on?'**
  String get notificationOfferTitle;

  /// No description provided for @notificationOfferBody.
  ///
  /// In en, this message translates to:
  /// **'Flugwacht can tell you when your flight has departed, is arriving soon, and has landed. You can change this in the settings at any time.'**
  String get notificationOfferBody;

  /// No description provided for @notificationOfferAccept.
  ///
  /// In en, this message translates to:
  /// **'Yes, please'**
  String get notificationOfferAccept;

  /// No description provided for @notificationOfferDecline.
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get notificationOfferDecline;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Flugwacht'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · Licenses & sources'**
  String settingsAboutSubtitle(String version);

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Flugwacht'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({buildNumber})'**
  String aboutVersion(String version, String buildNumber);

  /// No description provided for @aboutSourcesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Data & map'**
  String get aboutSourcesSectionTitle;

  /// Says what the flight data sources credited above the sentence are. The sources name themselves in their own rows, so the sentence carries no names.
  ///
  /// In en, this message translates to:
  /// **'Community networks, free for private use, without warranty about availability or freshness.'**
  String get aboutSources;

  /// No description provided for @aboutMapAttribution.
  ///
  /// In en, this message translates to:
  /// **'Map © OpenStreetMap contributors'**
  String get aboutMapAttribution;

  /// No description provided for @aboutIconCredit.
  ///
  /// In en, this message translates to:
  /// **'Icons: Font Awesome Pro'**
  String get aboutIconCredit;

  /// No description provided for @aboutLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get aboutLicenses;

  /// No description provided for @aboutRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate Flugwacht'**
  String get aboutRateApp;

  /// No description provided for @aboutBoundfox.
  ///
  /// In en, this message translates to:
  /// **'A project by Boundfox Studios'**
  String get aboutBoundfox;

  /// No description provided for @aboutGithub.
  ///
  /// In en, this message translates to:
  /// **'Flugwacht on GitHub'**
  String get aboutGithub;

  /// No description provided for @aboutDiscord.
  ///
  /// In en, this message translates to:
  /// **'Join Flugwacht on Discord'**
  String get aboutDiscord;

  /// No description provided for @settingsBugHint.
  ///
  /// In en, this message translates to:
  /// **'Use GitHub or Discord to report issues or make suggestions.'**
  String get settingsBugHint;

  /// No description provided for @settingsFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get settingsFaqTitle;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get faqTitle;

  /// No description provided for @faqOtherServicesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why does the data differ from FlightRadar24 and others?'**
  String get faqOtherServicesQuestion;

  /// No description provided for @faqOtherServicesAnswer.
  ///
  /// In en, this message translates to:
  /// **'Those services blend ADS-B with MLAT, satellite reception and airline schedule data. Flugwacht only shows what community receivers actually pick up — no schedule-based guesses. That is why there are gaps wherever nobody is listening.'**
  String get faqOtherServicesAnswer;

  /// No description provided for @faqArrivalAccuracyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why is the arrival time sometimes inaccurate?'**
  String get faqArrivalAccuracyQuestion;

  /// No description provided for @faqArrivalAccuracyAnswer.
  ///
  /// In en, this message translates to:
  /// **'It is the remaining distance divided by the current ground speed. Holding patterns, approach routing, taxi time and the wind on the last leg are not in it. It sharpens the closer the aircraft gets, and a “~” marks an estimate built on an aged position.'**
  String get faqArrivalAccuracyAnswer;

  /// No description provided for @faqTrailStartQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why does the trail only start when I add the flight?'**
  String get faqTrailStartQuestion;

  /// No description provided for @faqTrailStartAnswer.
  ///
  /// In en, this message translates to:
  /// **'There is no history to fetch. The sources report the live state, and Flugwacht builds the trail itself from the points it collects from that moment on. A flight you add mid-air therefore starts without a trail.'**
  String get faqTrailStartAnswer;

  /// No description provided for @faqFlightNotFoundQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why can I not find my flight?'**
  String get faqFlightNotFoundQuestion;

  /// No description provided for @faqFlightNotFoundAnswer.
  ///
  /// In en, this message translates to:
  /// **'A flight only shows up once a receiver hears it: not before takeoff, and not in regions without coverage. Check the flight number the way the airline writes it (LH400, not DLH400), or search by registration or hex address. Trying another source is worth it, too.'**
  String get faqFlightNotFoundAnswer;

  /// No description provided for @faqTrailGapsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why does the trail have gaps?'**
  String get faqTrailGapsQuestion;

  /// No description provided for @faqTrailGapsAnswer.
  ///
  /// In en, this message translates to:
  /// **'ADS-B needs a ground receiver in range. Over oceans, deserts and polar routes there often is none for one to two hours. The trail pauses and picks up again afterwards.'**
  String get faqTrailGapsAnswer;

  /// No description provided for @faqFlightsDisappearQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why do flights disappear after landing?'**
  String get faqFlightsDisappearQuestion;

  /// No description provided for @faqFlightsDisappearAnswer.
  ///
  /// In en, this message translates to:
  /// **'Flights clear themselves 24 hours after landing. That keeps the list to what is still ahead of you.'**
  String get faqFlightsDisappearAnswer;

  /// No description provided for @faqLateNotificationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why does a notification sometimes arrive late?'**
  String get faqLateNotificationQuestion;

  /// No description provided for @faqLateNotificationAnswer.
  ///
  /// In en, this message translates to:
  /// **'The operating system decides when an app may run in the background. In battery saver mode, or when you rarely open the app, the message can arrive a few minutes late.'**
  String get faqLateNotificationAnswer;

  /// No description provided for @faqDataOriginQuestion.
  ///
  /// In en, this message translates to:
  /// **'Where does the data come from?'**
  String get faqDataOriginQuestion;

  /// No description provided for @faqDataOriginAnswer.
  ///
  /// In en, this message translates to:
  /// **'Volunteers run ADS-B receivers and share what they hear in open networks such as adsb.lol and adsb.fi. No airline, no official feed — which is why it is free, and why it comes without a guarantee.'**
  String get faqDataOriginAnswer;

  /// No description provided for @faqAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do I need an account?'**
  String get faqAccountQuestion;

  /// No description provided for @faqAccountAnswer.
  ///
  /// In en, this message translates to:
  /// **'No. No account, no server, no sign-up. Flights and settings stay on the device; the only things leaving it are the queries to the selected source and the map tiles.'**
  String get faqAccountAnswer;

  /// No description provided for @notificationDepartedBody.
  ///
  /// In en, this message translates to:
  /// **'The flight has taken off.'**
  String get notificationDepartedBody;

  /// No description provided for @notificationArrivingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Arriving in about 30 minutes.'**
  String get notificationArrivingSoonBody;

  /// No description provided for @notificationLandedBody.
  ///
  /// In en, this message translates to:
  /// **'The flight has landed.'**
  String get notificationLandedBody;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Flight status'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Departure, arrival and landing of your flights.'**
  String get notificationChannelDescription;

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

  /// No description provided for @lockScreenArmLabel.
  ///
  /// In en, this message translates to:
  /// **'On the lock screen on flight day'**
  String get lockScreenArmLabel;

  /// No description provided for @lockScreenReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow on the lock screen'**
  String get lockScreenReminderTitle;

  /// No description provided for @lockScreenReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Follow {flight} on your lock screen today. Tap to start.'**
  String lockScreenReminderBody(String flight);

  /// No description provided for @settingsLockScreenHint.
  ///
  /// In en, this message translates to:
  /// **'Flugwacht sends you a notification on the flight day, so you can put the flight on your lock screen from there.'**
  String get settingsLockScreenHint;

  /// No description provided for @lockScreenDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Notifications on the lock screen are switched off for Flugwacht in the system settings'**
  String get lockScreenDisabledHint;

  /// No description provided for @lockScreenChannelName.
  ///
  /// In en, this message translates to:
  /// **'Running flights'**
  String get lockScreenChannelName;

  /// No description provided for @lockScreenChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'The card that shows a flight on your lock screen while it is under way.'**
  String get lockScreenChannelDescription;

  /// No description provided for @lockScreenCardArrival.
  ///
  /// In en, this message translates to:
  /// **'arrival {time}'**
  String lockScreenCardArrival(String time);

  /// No description provided for @lockScreenCardArrivalUncertain.
  ///
  /// In en, this message translates to:
  /// **'arrival ~{time}'**
  String lockScreenCardArrivalUncertain(String time);

  /// No description provided for @lockScreenCardLanded.
  ///
  /// In en, this message translates to:
  /// **'landed {time}'**
  String lockScreenCardLanded(String time);

  /// No description provided for @lockScreenCardProbablyLanded.
  ///
  /// In en, this message translates to:
  /// **'probably landed'**
  String get lockScreenCardProbablyLanded;
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
