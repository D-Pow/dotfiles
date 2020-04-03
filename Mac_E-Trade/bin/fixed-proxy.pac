function FindProxyForURL(url, host) {
	if (shExpMatch(host, "*.google.com") || host.match(/.*.google.com/) || url.match(/.*.google.com/)) {
		return "DIRECT";
	}

	/**
	 * Go to System Preferences -> Network -> Wifi -> Advanced -> Proxies
	 * Original was: http://127.0.0.1:9000/localproxy-[someNumberThatChanges].pac
	 * New is: file:///Users/<username>/path/dotfiles/Mac_E-Trade/bin/fixed-proxy.pac
	 */
	var privateIP = /^(0|10|127|192\.168|172\.1[6789]|172\.2[0-9]|172\.3[01]|169\.254|192\.88\.99)\.[0-9.]+$/;
	var resolved_ip = dnsResolve(host);

	/* Don't send non-FQDN or private IP auths to us */
	if (isPlainHostName(host) || isInNet(resolved_ip, "192.0.2.0", "255.255.255.0") || privateIP.test(resolved_ip))
		return "DIRECT";

	/* FTP goes directly */
	if (url.substring(0, 4) == "ftp:")
		return "DIRECT";

	/* test with ZPA */
	if (isInNet(resolved_ip, "100.64.0.0", "255.255.0.0"))
		return "DIRECT";

	if (shExpMatch(host, "mia35288.us-east-1.privatelink.snowflakecomputing.com") ||
		shExpMatch(host, "rka49415.us-east-1.privatelink.snowflakecomputing.com")) {
		return "PROXY snowproxy.dit.etrade.com:8080";
	}

	if (shExpMatch(host, "lca02007.us-east-1.privatelink.snowflakecomputing.com")) {
		return "PROXY snowproxy.etrade.com:8080";
	}

	/* Updates are directly accessible */
	if (((localHostOrDomainIs(host, "trust.zscaler.com")) ||
			(localHostOrDomainIs(host, "trust.zscaler.net")) ||
			(localHostOrDomainIs(host, "trust.zscalerone.net")) ||
			(localHostOrDomainIs(host, "trust.zscalertwo.net")) ||
			(localHostOrDomainIs(host, "trust.zscalerthree.net")) ||
			(localHostOrDomainIs(host, "trust.zscloud.net"))) &&
		(url.substring(0, 5) == "http:" || url.substring(0, 6) == "https:"))
		return "DIRECT";

	if (shExpMatch(host, "api.nasdaq.com") ||
		shExpMatch(host, "*.etrade.com") ||
		/*   Start Office360 URL bypass section  */
		shExpMatch(host, "*.office365.com") ||
		shExpMatch(host, "*.portal.cloudappsecurity.com") ||
		shExpMatch(host, "*.onmicrosoft.com") ||
		shExpMatch(host, "*.office.net") ||
		shExpMatch(host, "*.office.com") ||
		shExpMatch(host, "*.microsoft.com") ||
		shExpMatch(host, "*.microsoftonline.com") ||
		shExpMatch(host, "*.azure.net") ||
		shExpMatch(host, "auth.gfx.ms") ||
		shExpMatch(host, "*.onestore.ms") ||
		shExpMatch(host, "*.o365weve.com") ||
		shExpMatch(host, "platform.linkedin.com") ||
		shExpMatch(host, "*.cloudapp.net") ||
		shExpMatch(host, "*.windows.net") ||
		shExpMatch(host, "*.helpshift.com") ||
		shExpMatch(host, "*.localytics.com") ||
		shExpMatch(host, "*.msocdn.com") ||
		shExpMatch(host, "*.microsoftonline-p.net") ||
		shExpMatch(host, "*.microsoftonline-p.com") ||
		shExpMatch(host, "*.oaspapps.com") ||
		shExpMatch(host, "*.hockeyapp.net") ||
		shExpMatch(host, "*.outlook.com") ||
		shExpMatch(host, "*.outlookgroups.ms") ||
		shExpMatch(host, "*.sharepoint.com") ||
		shExpMatch(host, "*.svc.ms") ||
		shExpMatch(host, "*.sharepointonline.com") ||
		shExpMatch(host, "oneclient.sfx.ms") ||
		shExpMatch(host, "*.akamaized.net") ||
		shExpMatch(host, "*.azure.com") ||
		shExpMatch(host, "*.windowsazure.com") ||
		shExpMatch(host, "*.api.skype.com") ||
		shExpMatch(host, "*.asm.skype.com") ||
		shExpMatch(host, "*.broadcast.skype.com") ||
		shExpMatch(host, "*.cc.skype.com") ||
		shExpMatch(host, "*.config.skype.com") ||
		shExpMatch(host, "*.conv.skype.com") ||
		shExpMatch(host, "*.dc.trouter.io") ||
		shExpMatch(host, "*.lync.com") ||
		shExpMatch(host, "*.onenote.com") ||
		shExpMatch(host, "*.pipe.skype.com") ||
		shExpMatch(host, "*.skypeforbusiness.com") ||
		shExpMatch(host, "*.teams.skype.com") ||
		shExpMatch(host, "*.yammer.com") ||
		shExpMatch(host, "*.yammerusercontent.com") ||
		shExpMatch(host, "*.officeapps.live.com") ||
		shExpMatch(host, "broadcast.skype.com") ||
		shExpMatch(host, "config.edge.skype.com") ||
		shExpMatch(host, "office.live.com") ||
		shExpMatch(host, "officeapps.live.com") ||
		shExpMatch(host, "pipe.skype.com") ||
		shExpMatch(host, "prod.registrar.skype.com") ||
		shExpMatch(host, "prod.tpc.skype.com") ||
		shExpMatch(host, "s-0001.s-msedge.net") ||
		shExpMatch(host, "s-0004.s-msedge.net") ||
		shExpMatch(host, "scsinstrument-ss-us.trafficmanager.net") ||
		shExpMatch(host, "scsquery-ss-asia.trafficmanager.net") ||
		shExpMatch(host, "scsquery-ss-eu.trafficmanager.net") ||
		shExpMatch(host, "scsquery-ss-us.trafficmanager.net") ||
		shExpMatch(host, "*.aadrm.com") ||
		shExpMatch(host, "*.azurerms.com") ||
		shExpMatch(host, "ecn.dev.virtualearth.net") ||
		shExpMatch(host, "spoprod-a.akamaihd.net") ||
		shExpMatch(host, "g.live.com") ||
		shExpMatch(host, "*.log.optimizely.com") ||
		shExpMatch(host, "ssw.live.com") ||
		shExpMatch(host, "storage.live.com") ||
		shExpMatch(host, "*.search.production.us.trafficmanager.net") ||
		shExpMatch(host, "*.search.production.emea.trafficmanager.net") ||
		shExpMatch(host, "*.search.production.apac.trafficmanager.net") ||
		shExpMatch(host, "accounts.accesscontrol.windows.net") ||
		shExpMatch(host, "*.onedrive.com") ||
		shExpMatch(host, "officeci-mauservice.azurewebsites.net") ||
		shExpMatch(host, "officeci.azurewebsites.net") ||
		shExpMatch(host, "ocos-office365-s2s.msedge.net") ||
		shExpMatch(host, "client-office365-tas.msedge.net") ||
		shExpMatch(host, "ajax.aspnetcdn.com") ||
		shExpMatch(host, "prod-global-autodetect.acompli.net") ||
		shExpMatch(host, "login.live.com") ||
		shExpMatch(host, "www.bing.com") ||
		shExpMatch(host, "c.bing.com") ||
		shExpMatch(host, "tse1.mm.bing.net") ||
		shExpMatch(host, "ajax.googleapis.com") ||
		shExpMatch(host, "*.google.com") ||
		shExpMatch(host, "cdnjs.cloudflare.com") ||
		shExpMatch(host, "powerlift-frontdesk.acompli.net") ||
		shExpMatch(host, "*.cdn.optimizely.com") ||
		shExpMatch(host, "errors.client.optimizely.com") ||
		shExpMatch(host, "nexus.ensighten.com") ||
		shExpMatch(host, "*.vo.msecnd.net") ||
		shExpMatch(host, "*.wikipedia.org") ||
		shExpMatch(host, "wikipedia.firstpartyappssandbox.oappseperate.com") ||
		shExpMatch(host, "*.virtualearth.net") ||
		shExpMatch(host, "client.hip.live.com") ||
		shExpMatch(host, "*.msappproxy.net") ||
		shExpMatch(host, "autologon.microsoftazuread-sso.com") ||
		shExpMatch(host, "azurerange.azurewebsites.net") ||
		shExpMatch(host, "clientconfig.passport.net") ||
		shExpMatch(host, "msftncsi.com") ||
		shExpMatch(host, "download.windowsupdate.com") ||
		/* Stop Office360 URL bypass section  */
		/* Start Adobe Creative Cloud Libraries URL bypass section  */
		shExpMatch(host, "cc-api-storage.adobe.io") ||
		shExpMatch(host, "assets.adobe.com") ||
		shExpMatch(host, "helpx.adobe.com") ||
		shExpMatch(host, "use.typekit.net") ||
		shExpMatch(host, "www.adobeexchange.com") ||
		shExpMatch(host, "*.adobesc.com") ||
		shExpMatch(host, "scproxy-prod.adobecc.com") ||
		shExpMatch(host, "cc-collab.adobe.io") ||
		shExpMatch(host, "adbemdigitalmediarebootprod2.112.2o7.net") ||
		shExpMatch(host, "polka.typekit.com") ||
		shExpMatch(host, "wwwimages2.adobe.com") ||
		shExpMatch(host, "sstats.adobe.com") ||
		shExpMatch(host, "assets.adobedtm.com") ||
		shExpMatch(host, "cdn.tt.omtrdc.net") ||
		shExpMatch(host, "api.demandbase.com") ||
		shExpMatch(host, "*.ftcdn.net") ||
		shExpMatch(host, "*.behance.net") ||
		shExpMatch(host, "dpm.demdex.net") ||
		shExpMatch(host, "cc-api-image.adobe.io") ||
		shExpMatch(host, "cc-api-image-x.adobe.io") ||
		/* Stop Adobe Creative Cloud Libraries URL bypass section  */
		/* Start TCA Business App URL bypass section  */
		shExpMatch(host, "*tcadocustar.com") ||
		shExpMatch(host, "*docustaruat.com") ||
		shExpMatch(host, "etuat.newgenbpmcloud.com") ||
		/* Stop TCA Business App URL bypass section  */
		/* Start Apple-update URL bypass section  */
		shExpMatch(host, "osrecovery.apple.com") ||
		shExpMatch(host, "oscdn.apple.com") ||
		shExpMatch(host, "jamf-patch.jamfcloud.com") ||
		shExpMatch(host, "swscan.apple.com") ||
		shExpMatch(host, "ocsp.digicert.com") ||
		shExpMatch(host, "albert.apple.com") ||
		shExpMatch(host, "s2.symcb.com") ||
		shExpMatch(host, "swdist.apple.com") ||
		shExpMatch(host, "swcdn.apple.com") ||
		/* Stop Apple-update URL bypass section  */
		/* Start Webex Teams URL bypass section  */
		shExpMatch(host, "*.ciscospark.com") ||
		shExpMatch(host, "*.ciscowebex.com") ||
		shExpMatch(host, "*.wbx2.com") ||
		shExpMatch(host, "*.webex.com") ||
		shExpMatch(host, "*.webexconnect.com") ||
		shExpMatch(host, "*.storage101.ord1.clouddrive.com") ||
		shExpMatch(host, "*.storage101.dfw1.clouddrive.com") ||
		shExpMatch(host, "*.storage101.iad3.clouddrive.com") ||
		shExpMatch(host, "*.rackcdn.com") ||
		shExpMatch(host, "*.huron-dev.com") ||
		shExpMatch(host, "*.crashlytics.com") ||
		shExpMatch(host, "*.optimizely.com") ||
		shExpMatch(host, "*.2.android.pool.ntp.org") ||
		shExpMatch(host, "*.cloudconnector.cisco.com") ||
		shExpMatch(host, "*.cloudfront.net") ||
		shExpMatch(host, "*.docker.io") ||
		shExpMatch(host, "199.26.17.92") ||
		shExpMatch(host, "207.45.34.1") ||
		shExpMatch(host, "207.45.47.40") ||
		/* Stop Webex Teams URL bypass section  */
		shExpMatch(host, "etradetestconsole.cadency.trintech.com") ||
		shExpMatch(host, "etradeconsole.cadency.trintech.com") ||
		shExpMatch(host, "etradetest.cadency.trintech.com"))
		return "DIRECT";

	/* Default Traffic Forwarding. Forwarding to Zen on port 80, but you can use port 9400 also */
	return "PROXY 127.0.0.1:9000";
}
