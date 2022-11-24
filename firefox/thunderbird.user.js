// Setings > bottom of page > "Config Editor"
// http://kb.mozillazine.org/Mail_and_news_settings
// https://wiki.archlinux.org/title/thunderbird
// https://github.com/HorlogeSkynet/thunderbird-user.js

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// General
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("browser.aboutConfig.showWarning", false);
user_pref("mail.shell.checkDefaultClient", false);
user_pref("mailnews.start_page.enabled", false);
user_pref("browser.newtabpage.enabled", false);
user_pref("mail.showCondensedAddresses", false); // true = just name, false = address + name
user_pref("mail.rights.override", true);
user_pref("devtools.chrome.enabled", false);
user_pref("devtools.debugger.remote-enabled", false);
user_pref("mailnews.headers.showSender", true);
user_pref("mail.collect_email_address_outgoing", false);
user_pref("mailnews.start_page_override.mstone", "ignore");
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true); // Enable userChrome.css
user_pref("mail.tabs.autoHide", true);
user_pref("ui.key.menuAccessKey", 0);
// user_pref("mail.biff.show_badge", false); // Show the new/unread message count badge on taskbar icon
// user_pref("mail.biff.use_new_count_in_badge", true); // Show the number of "new" messages on taskbar icon (not the number of unread ones)

// User Interface
user_pref("browser.theme.content-theme", 1); // 0=dark, 1=light, 2=system, 3=browser
user_pref("browser.theme.toolbar-theme", 1); // 0=dark, 1=light, 2=system, 3=browser
user_pref("pref.privacy.disable_button.view_cookies", false);
user_pref("pref.privacy.disable_button.cookie_exceptions", false);
user_pref("pref.privacy.disable_button.view_passwords", false);
user_pref("browser.uitour.enabled", false);
user_pref("browser.uitour.url", "");
user_pref("browser.uidensity", 1);
user_pref("browser.compactmode.show", true);

// Use UTF-8
user_pref("intl.fallbackCharsetList.ISO-8859-1", "UTF-8");
user_pref("mailnews.view_default_charset", "UTF-8");
user_pref("mailnews.send_default_charset", "UTF-8");
user_pref("mailnews.reply_in_default_charset", true);

// Ads
user_pref("mail.cloud_files.enabled", false); // Disable "Filelink for Large Attachments" feature
user_pref("mail.provider.enabled", false); // Account creation through partner program.
user_pref("extensions.getAddons.showPane", false);
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);

// SORT
user_pref("browser.display.use_system_colors", false);
user_pref("browser.link.open_newwindow", 3);
user_pref("browser.link.open_newwindow.restriction", 0);
user_pref("accessibility.force_disabled", 1); // https://support.mozilla.org/kb/accessibility-services
user_pref("beacon.enabled", false);
user_pref("browser.helperApps.deleteTempFileOnExit", true);
user_pref("browser.pagethumbnails.capturing_disabled", true);
user_pref("middlemouse.contentLoadURL", false);
user_pref("pdfjs.enableScripting", false);
user_pref("network.protocol-handler.external.ms-windows-store", false);
user_pref("permissions.delegation.enabled", false);

// Downloads
user_pref("browser.download.always_ask_before_handling_new_types", true);
user_pref("browser.download.alwaysOpenPanel", false);
user_pref("browser.download.improvements_to_download_panel", false);
user_pref("browser.download.manager.addToRecentDocs", false);
user_pref("browser.download.manager.alertOnEXEOpen", true);
user_pref("browser.download.panel.shown", true);
user_pref("browser.download.save_converter_index", 0);
user_pref("browser.download.start_downloads_in_tmp_dir", true);
user_pref("browser.download.useDownloadDir", false); // Ask download location


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Privacy
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("privacy.donottrackheader.enabled", true);
user_pref("mail.sanitize_date_header", true); // Don't leak time zone
user_pref("mail.suppress_content_language", true); // Don't leak language
user_pref("privacy.resistFingerprinting", true);
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
user_pref("privacy.partition.network_state.ocsp_cache", true);
user_pref("privacy.query_stripping.enabled", true); // Potentially breaks things
user_pref("privacy.partition.serviceWorkers", true);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Chat
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("mail.chat.enabled", false);
user_pref("purple.logging.log_chats", false);
user_pref("purple.logging.log_ims", false);
user_pref("purple.logging.log_system", false);
user_pref("purple.conversations.im.send_typing", false);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Email View
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("javascript.enabled", false);
user_pref("media.mediasource.enabled", false);
user_pref("media.hardware-video-decoding.enabled", false);
user_pref("permissions.default.image", 2);
user_pref("mail.phishing.detection.enabled", true);
user_pref("mail.phishing.detection.disallow_form_actions", true);
user_pref("mail.phishing.detection.ipaddresses", true);
user_pref("mail.phishing.detection.mismatched_hosts", true);
user_pref("mailnews.message_display.disable_remote_image", true);
user_pref("mailnews.display.html_as", 3); //0=render html; 1=convert: html>txt>render html; 2=show html source; 3=sanitize and render
user_pref("mailnews.display.prefer_plaintext", false);
user_pref("mail.inline_attachments", false);
user_pref("mail.compose.add_link_preview", false);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Studies / Experiments
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");
user_pref("experiments.enabled", false);
user_pref("experiments.supported", false);
user_pref("app.normandy.user_id", "");
user_pref("messaging-system.rsexperimentloader.enabled", false);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Network
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("network.dns.disableIPv6", true);
user_pref("network.notify.IPv6", false);
user_pref("browser.send_pings", false);

user_pref("network.prefetch-next", false);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disablePrefetchFromHTTPS", true);
user_pref("network.predictor.enabled", false);
user_pref("network.predictor.enable-prefetch", false);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("browser.meta_refresh_when_inactive.disabled", true);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is a email client, not a web browser
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("webgl.disabled", true);
//user_pref("mathml.disabled", true);
//user_pref("svg.disabled", true);
user_pref("dom.caches.enabled", false);
user_pref("dom.disable_beforeunload", true);
user_pref("dom.disable_open_during_load", true);
user_pref("dom.disable_window_move_resize", true);
user_pref("dom.event.clipboardevents.enabled", false);
user_pref("dom.event.contextmenu.enabled", false);
user_pref("dom.popup_allowed_events", "click dblclick mousedown pointerdown");
user_pref("dom.storage_access.enabled", false);
user_pref("dom.storageManager.enabled", false);
user_pref("dom.vr.enabled", false);
user_pref("full-screen-api.enabled", false);
user_pref("geo.enabled", false);
user_pref("gfx.font_rendering.graphite.enabled", false);
user_pref("javascript.options.asmjs", false);
user_pref("javascript.options.baselinejit", false);
user_pref("javascript.options.ion", false);
user_pref("javascript.options.jit_trustedprincipals", true);
user_pref("javascript.options.wasm", false);
user_pref("security.external_protocol_requires_permission", true);

// Clear data on exit (most of these default to on anyways)
user_pref("network.cookie.cookieBehavior", 2);
user_pref("network.cookie.lifetimePolicy", 2);
user_pref("network.cookie.thirdparty.nonsecureSessionOnly", true);
user_pref("network.cookie.thirdparty.sessionOnly", true);
user_pref("privacy.clearOnShutdown.cache", true);
user_pref("privacy.clearOnShutdown.cookies", true);
user_pref("privacy.clearOnShutdown.downloads", true);
user_pref("privacy.clearOnShutdown.formdata", true);
user_pref("privacy.clearOnShutdown.history", true);
user_pref("privacy.clearOnShutdown.offlineApps", true);
user_pref("privacy.clearOnShutdown.sessions", true);
user_pref("privacy.sanitize.sanitizeOnShutdown", true);

user_pref("browser.fixup.alternate.enabled", false);
user_pref("browser.formfill.enable", false);
user_pref("extensions.formautofill.addresses.enabled", false);
user_pref("extensions.formautofill.available", "off");
user_pref("extensions.formautofill.creditCards.available", false);
user_pref("extensions.formautofill.creditCards.enabled", false);
user_pref("extensions.formautofill.heuristics.enabled", false);
//user_pref("layout.css.visited_links_enabled", false);
user_pref("signon.autofillForms", false);
user_pref("signon.formlessCapture.enabled", false);
user_pref("network.auth.subresource-http-auth-allow", 1);

// Media
user_pref("media.peerconnection.enabled", false);
user_pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);
user_pref("media.peerconnection.ice.default_address_only", true);
user_pref("media.peerconnection.ice.no_host", true);
user_pref("media.gmp-provider.enabled", false);
user_pref("media.gmp-widevinecdm.enabled", false);
user_pref("media.eme.enabled", false);
user_pref("media.autoplay.default", 5);
user_pref("media.autoplay.blocking_policy", 2);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Telemetry / Reporting / Tracking
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.server", "data:,");
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.coverage.opt-out", true);
user_pref("toolkit.coverage.opt-out", true);
user_pref("toolkit.coverage.endpoint.base", "");
user_pref("browser.ping-centre.telemetry", false);
user_pref("captivedetect.canonicalURL", "");
user_pref("network.captive-portal-service.enabled", false);
user_pref("network.connectivity-service.enabled", false);
user_pref("mail.instrumentation.postUrl", "");
user_pref("mail.instrumentation.askUser", false);
user_pref("mail.instrumentation.userOptedIn", false);

// Crash Reporting
user_pref("breakpad.reportURL", "");
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Location
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("geo.provider.ms-windows-location", false);
user_pref("geo.provider.use_corelocation", false);
user_pref("geo.provider.use_gpsd", false);
user_pref("browser.region.network.url", "");
user_pref("browser.region.update.enabled", false);
user_pref("intl.accept_languages", "en-US, en");
user_pref("spellchecker.dictionary", "en-US");
user_pref("javascript.use_us_english_locale", true);
//user_pref("geo.provider.network.url", "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%");


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Cache and Disk usage
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.disk_cache_ssl", false);
user_pref("browser.cache.memory.enable", true);
user_pref("browser.cache.memory.capacity", 256*1024); // In KB
user_pref("browser.cache.memory.max_entry_size", 50*1024); // In KB
user_pref("browser.sessionstore.interval", 5*60*1000); // Time in MS
user_pref("browser.sessionstore.interval.idle", 10*60*1000); // Time in MS
user_pref("browser.sessionstore.privacy_level", 2);
user_pref("browser.privatebrowsing.forceMediaMemoryCache", true);
