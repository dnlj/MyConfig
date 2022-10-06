// https://support.mozilla.org/en-US/kb/how-stop-firefox-making-automatic-connections
// https://github.com/DonQuixoteI/Firefox-UserGuide/blob/master/doc/user.js.md
// https://github.com/arkenfox/user.js

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// User Options
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// General
user_pref("dnlj.user.setup", true);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true); // Enable userChrome.css
user_pref("browser.safebrowsing.downloads.remote.enabled", false); // Does NOT disable SafeBrowsing. Only disables online checks. Still checks against known blacklist.
user_pref("findbar.highlightAll", true);
user_pref("general.smoothScroll", false);
user_pref("identity.fxaccounts.enabled", false); // Firefox Account
user_pref("layout.spellcheckDefault", 0);
user_pref("extensions.pocket.enabled", false);
user_pref("ui.osk.enabled", false); // On screen keyboard

// User Interface
user_pref("browser.theme.content-theme", 1);
user_pref("browser.toolbars.bookmarks.visibility", "always");
user_pref("browser.uidensity", 1);
user_pref("browser.compactmode.show", true);
//user_pref("ui.prefersReducedMotion", 1);

// Downloads
user_pref("browser.download.always_ask_before_handling_new_types", true);
user_pref("browser.download.alwaysOpenPanel", false);
user_pref("browser.download.improvements_to_download_panel", false);
user_pref("browser.download.manager.alertOnEXEOpen", false);
user_pref("browser.download.panel.shown", true);
user_pref("browser.download.save_converter_index", 0);
user_pref("browser.download.start_downloads_in_tmp_dir", true);
user_pref("browser.download.useDownloadDir", false); // Ask download location
user_pref("browser.download.manager.addToRecentDocs", false);

// Dev Tool
user_pref("devtools.cache.disabled", true);
user_pref("devtools.chrome.enabled", false);
user_pref("devtools.command-button-screenshot.enabled", true);
user_pref("devtools.debugger.event-listeners-visible", true);
user_pref("devtools.debugger.ignore-caught-exceptions", false);
user_pref("devtools.debugger.remote-enabled", false);
user_pref("devtools.theme", "dark");
user_pref("devtools.toolbox.tabsOrder", "inspector,webconsole,jsdebugger,styleeditor,performance,memory,netmonitor,storage,accessibility");

// Sync
user_pref("services.sync.clients.lastSync", "0");
user_pref("services.sync.clients.lastSyncLocal", "0");
user_pref("services.sync.declinedEngines", "");
user_pref("services.sync.engine.addresses.available", true);
user_pref("services.sync.globalScore", 0);
user_pref("services.sync.migrated", true);
user_pref("services.sync.nextSync", 0);
user_pref("services.sync.tabs.lastSync", "0");
user_pref("services.sync.tabs.lastSyncLocal", "0");
user_pref("trailhead.firstrun.didSeeAboutWelcome", true);

// Unsorted / Other
user_pref("accessibility.browsewithcaret_shortcut.enabled", false);
user_pref("accessibility.typeaheadfind.flashBar", 0);
user_pref("browser.aboutConfig.showWarning", false);
user_pref("browser.bookmarks.defaultLocation", "toolbar_____");
user_pref("browser.bookmarks.restore_default_bookmarks", false);
user_pref("browser.bookmarks.showMobileBookmarks", false);
user_pref("browser.bookmarks.editDialog.confirmationHintShowCount", 100);
user_pref("browser.cache.disk.telemetry_report_ID", -1);
user_pref("browser.display.document_color_use", 1);
user_pref("browser.launcherProcess.enabled", true);
user_pref("browser.reader.detectedFirstArticle", true);
user_pref("media.videocontrols.picture-in-picture.video-toggle.has-used", true);
user_pref("privacy.socialtracking.notification.enabled", false);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Notifications / Tips / Recommendations
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Addon recommendations
user_pref("browser.discovery.enabled", false);
user_pref("extensions.getAddons.showPane", false); 
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);

// Warnings / Notifications
user_pref("general.warnOnAboutConfig", false);
user_pref("media.hardwaremediakeys.enabled", false);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Studies / Experiments
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("app.normandy.enabled", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("experiments.enabled", false);
user_pref("experiments.supported", false);
user_pref("app.normandy.api_url", "");
user_pref("messaging-system.rsexperimentloader.enabled", false);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Mozilla: Telemetry / Reporting / Tracking
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("app.update.lastUpdateTime.telemetry_modules_ping", 2147483647);
user_pref("beacon.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.telemetry.ping.endpoint", "");
user_pref("browser.newtabpage.activity-stream.telemetry.ut.events", false);
user_pref("browser.newtabpage.activity-stream.telemetry", false);
user_pref("browser.ping-centre.telemetry", false);
user_pref("browser.urlbar.eventTelemetry.enabled", false);
user_pref("datareporting.healthreport.service.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("devtools.onboarding.telemetry.logged", true);
user_pref("privacy.trackingprotection.origin_telemetry.enabled", false);
user_pref("security.app_menu.recordEventTelemetry", false);
user_pref("security.certerrors.recordEventTelemetry", false);
user_pref("security.identitypopup.recordEventTelemetry", false);
user_pref("security.protectionspopup.recordEventTelemetry", false);
user_pref("toolkit.coverage.endpoint.base", "");
user_pref("toolkit.coverage.opt-out", true);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.cachedClientID", "c0ffeec0-ffee-c0ff-eec0-ffeec0ffeec0");
user_pref("toolkit.telemetry.coverage.opt-out", true);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.healthping.enabled", false);
user_pref("toolkit.telemetry.hybridContent.enabled", false);
user_pref("toolkit.telemetry.log.level", "Fatal");
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.pioneer-new-studies-available", false);
user_pref("toolkit.telemetry.prioping.enabled", false);
user_pref("toolkit.telemetry.prompted", 2);
user_pref("toolkit.telemetry.rejected", true);
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("toolkit.telemetry.server", "");
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabledFirstSession", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.unifiedIsOptIn", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);

// Crash Reporting
user_pref("breakpad.reportURL", "");
user_pref("dom.ipc.plugins.flash.subprocess.crashreporter.enabled", false);
user_pref("dom.ipc.plugins.reportCrashURL", false);
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.crashReports.unsubmittedCheck.enabled", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);

// SSL Error Reporting
user_pref("security.ssl.errorReporting.enabled", false);
user_pref("security.ssl.errorReporting.url", "");

// Region Tracking: https://firefox-source-docs.mozilla.org/toolkit/modules/toolkit_modules/Region.html
user_pref("browser.region.update.enabled", false);
user_pref("browser.region.network.url", "");

// Captive Portals
user_pref("network.captive-portal-service.enabled", false);
user_pref("captivedetect.canonicalURL", "");
user_pref("network.connectivity-service.enabled", false); // Connectivity checks


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 3rdParty: Telemetry / Reporting / Tracking
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("webgl.disabled", true);
user_pref("dom.vr.process.enabled", false);
//user_pref("media.peerconnection.enabled", false);

// Push API
user_pref("dom.push.enabled", false);
user_pref("dom.push.connection.enabled", false);
user_pref("dom.push.serverURL", "");

// Fingerprinting
// https://wiki.mozilla.org/Security/Fingerprinting
user_pref("privacy.resistFingerprinting", true);
//user_pref("privacy.window.maxInnerWidth", 1600);
//user_pref("privacy.window.maxInnerHeight", 900);
//user_pref("privacy.resistFingerprinting.letterboxing", true);
user_pref("browser.display.use_system_colors", false);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Startup / Home / New Tabs
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("browser.startup.page", 1); // 0 = blank, 1 = homepage, 2 = last visited, 3 = restore last session
user_pref("browser.shell.checkDefaultBrowser", false); // Don't check for default browser
user_pref("browser.newtabpage.activity-stream.enabled", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
user_pref("browser.newtabpage.activity-stream.prerender", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includeBookmarks", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includeDownloads", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includeVisited", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Network
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("network.dns.disableIPv6", true);

// Prefetch and Speculative Navigation
user_pref("network.dns.disablePrefetch", true);
user_pref("network.prefetch-next", false);
user_pref("network.predictor.cleaned-up", true);
user_pref("network.predictor.enabled", false);
user_pref("network.predictor.enable-prefetch", false);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("browser.places.speculativeConnect.enabled", false);
user_pref("browser.send_pings", false);
user_pref("browser.urlbar.speculativeConnect.enabled", false);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Search / URL / Autofill
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("browser.region.update.updated", 1664875301);
user_pref("browser.search.countryCode", "US");
user_pref("browser.search.hiddenOneOffs", "Google");
user_pref("browser.search.region", "US");
user_pref("browser.search.suggest.enabled.private", true);
user_pref("browser.search.update", false);
user_pref("browser.urlbar.placeholderName.private", "Google");
user_pref("browser.urlbar.placeholderName", "Google");
user_pref("browser.urlbar.shortcuts.bookmarks", false);
user_pref("browser.urlbar.shortcuts.history", false);
user_pref("browser.urlbar.shortcuts.tabs", false);
user_pref("browser.urlbar.showSearchSuggestionsFirst", false);
user_pref("browser.urlbar.suggest.bookmark", false);
user_pref("browser.urlbar.suggest.engines", false);
user_pref("browser.urlbar.suggest.openpage", false);
user_pref("browser.urlbar.suggest.topsites", false);
user_pref("browser.urlbar.timesBeforeHidingSuggestionsHint", 0);
user_pref("browser.urlbar.tipShownCount.searchTip_onboard", 1);
user_pref("browser.urlbar.tipShownCount.tabToSearch", 60);
user_pref("browser.urlbar.trimURLs", false);
user_pref("browser.urlbar.update1.interventions", false);
user_pref("browser.urlbar.update1.searchTips", false);
user_pref("browser.urlbar.update1.view.stripHttps", false);
user_pref("browser.urlbar.update1", false);
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);

// Autofill
user_pref("browser.formfill.enable", false);
user_pref("browser.formfill.expire_days", 0);
user_pref("extensions.formautofill.addresses.enabled", false);
user_pref("extensions.formautofill.addresses.usage.hasEntry", false);
user_pref("extensions.formautofill.available", "off");
user_pref("extensions.formautofill.creditCards.available", false);
user_pref("extensions.formautofill.firstTimeUse", false);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Javascript / DOM / Page
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("dom.disable_window_move_resize", true);
user_pref("browser.uitour.enabled", false);
user_pref("browser.uitour.url", "");
user_pref("pdfjs.enableScripting", false);
user_pref("network.protocol-handler.external.ms-windows-store", false); // Disable Microsoft Store links
//user_pref("permissions.delegation.enabled", false);
