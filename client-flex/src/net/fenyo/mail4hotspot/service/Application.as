// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service
{
	import flash.events.*;
	import flash.system.System;
	import flash.utils.*;
	
	import mx.collections.*;
	import mx.core.FlexGlobals;
	import mx.resources.ResourceManager;
	
	import net.fenyo.mail4hotspot.dns.*;

	public class Application
	{
		// tenter de rendre les fonctions non statiques, afin de pouvoir remplacer Globals.topLevelApplication par parentApplication

		private static var new_mails : int = 0;
		private static var nmails : int = 0;
		private static var nchecks : int = 0;

		private static const timer_T : int = 1000;
		private static const timer : Timer = new Timer(timer_T);

		private static var sending_mail_number : int = 0;

		public function Application() { }

		public static function initMail4HotSpot() : void {
			timer.addEventListener(TimerEvent.TIMER, wait_while_checking_mails);
		}

		// attention : il y a une race condition : si on reclique sur le bouton de recherche des mails avant que les callbacks en cours n'aient été appelés, on peut se retrouver à ne pas stoper ces callbacks
		// il faudrait en fait attendre l'appel des callbacks avant de réautoriser un nouveau lancement
		public static function stopCheckingNewMails(message : String) : void {
			VuMeter.progress_bar_for_mails_ratio = 0;
			VuMeter.progress_bar_for_mails_text = message;
			if (!Main.tablet) {
				//			FlexGlobals.topLevelApplication.view_status.activeView.label_state.text = message;
				FlexGlobals.topLevelApplication.view_status.activeView.button_start.enabled = true;
				FlexGlobals.topLevelApplication.view_status.activeView.button_stop.enabled = false;
			} else {
				//			FlexGlobals.topLevelApplication.tablet_view_status.activeView.label_state.text = message;
				FlexGlobals.topLevelApplication.tablet_view_status.activeView.button_start.enabled = true;
				FlexGlobals.topLevelApplication.tablet_view_status.activeView.button_stop.enabled = false;
			}

			timer.stop();
			DnsQuerierFactory.cancelMailQueries();
		}

		public static function checkNewMails() : void {
			try {

				if (!Main.tablet) {
					FlexGlobals.topLevelApplication.view_status.activeView.button_start.enabled = false;
					FlexGlobals.topLevelApplication.view_status.activeView.button_stop.enabled = true;
				} else {
					FlexGlobals.topLevelApplication.tablet_view_status.activeView.button_start.enabled = false;
					FlexGlobals.topLevelApplication.tablet_view_status.activeView.button_stop.enabled = true;
				}

			nmails = 0;
			nchecks = 0;
			new_mails = 0;
			
//			FlexGlobals.topLevelApplication.view_status.activeView.label_state.text =
//				ResourceManager.getInstance().getString('localizedContent', 'StatusView_state_setup_tunnel');
			// FlexGlobals.topLevelApplication.resourceManager.getString('localizedContent', 'StatusView_state_setup_tunnel');
			VuMeter.progress_bar_for_mails_ratio = 10;
			VuMeter.progress_bar_for_mails_text = ResourceManager.getInstance().getString('localizedContent', 'Application_setup_tunnel');

			var dnsQuerier : DnsQuerier = DnsQuerierFactory.getDnsQuerier(DnsQuerierFactory.TYPE_MAIL);

			dnsQuerier.sendMessage(FlexGlobals.topLevelApplication.persistenceManager.getProperty("uuid") + "§CheckMails" +
				"§" + Main.release_info_account_type + "§" + Main.release_info_client_version + "§" + Main.deviceId,
				checkNewMailsCB1);

			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("Application.checkNewMails()", e);
			}
		}

		private static function wait_while_checking_mails(event : TimerEvent) : void {
			timer.stop();

			const dnsQuerier : DnsQuerier = DnsQuerierFactory.getDnsQuerier(DnsQuerierFactory.TYPE_MAIL);
			dnsQuerier.sendMessage(FlexGlobals.topLevelApplication.persistenceManager.getProperty("uuid") + "§GetNMails" +
				"§" + Main.release_info_account_type + "§" + Main.release_info_client_version + "§" + Main.deviceId,
				checkNewMailsCB1);
		}

		private static function checkNewMailsCB1(reply : String) : void {
			try {

			if (reply == null) {
				// pas de réponse même après toutes les retransmissions
				stopCheckingNewMails(ResourceManager.getInstance().getString('localizedContent', 'Application_timeout'));
			} else {
				var fields : Array = reply.split("§");
				// remplacer tous les var qui peuvent l'être par des const

				switch (new int(fields[0])) {
					case VpnCode.SRV2CLT_MAIL_SAVED:
						FlexGlobals.topLevelApplication.mailsDataProvider.removeItemAt(sending_mail_number);
						FlexGlobals.topLevelApplication.persistenceManager.setProperty("mailsDataProvider", FlexGlobals.topLevelApplication.mailsDataProvider.list);
						FlexGlobals.topLevelApplication.persistenceManager.save();

						// find mails waiting to be sent
						sending_mail_number = 0;
						while (sending_mail_number < FlexGlobals.topLevelApplication.mailsDataProvider.length) {
							if (FlexGlobals.topLevelApplication.mailsDataProvider.getItemAt(sending_mail_number).message_id == "VPN-over-DNS") {
								
								VuMeter.progress_bar_for_mails_text = ResourceManager.getInstance().getString('localizedContent', 'Application_send_mail');
								
								// bug potentiel : s'il y a un § dans un des champs composant le mail
								const dnsQuerier5 : DnsQuerier = DnsQuerierFactory.getDnsQuerier(DnsQuerierFactory.TYPE_MAIL);
								dnsQuerier5.sendMessage(FlexGlobals.topLevelApplication.persistenceManager.getProperty("uuid") + "§SendMail" +
									"§" + FlexGlobals.topLevelApplication.mailsDataProvider.getItemAt(sending_mail_number).to +
									"§" + FlexGlobals.topLevelApplication.mailsDataProvider.getItemAt(sending_mail_number).cc +
									"§" + FlexGlobals.topLevelApplication.mailsDataProvider.getItemAt(sending_mail_number).subject +
									"§" + FlexGlobals.topLevelApplication.mailsDataProvider.getItemAt(sending_mail_number).content +
									"§" + Main.release_info_account_type + "§" + Main.release_info_client_version + "§" + Main.deviceId,
									checkNewMailsCB1);
								return;
								
							}
							sending_mail_number++;
						}

						const dnsQuerier6 : DnsQuerier = DnsQuerierFactory.getDnsQuerier(DnsQuerierFactory.TYPE_MAIL);
						dnsQuerier6.sendMessage(FlexGlobals.topLevelApplication.persistenceManager.getProperty("uuid") + "§GetNMails" +
							"§" + Main.release_info_account_type + "§" + Main.release_info_client_version + "§" + Main.deviceId,
							checkNewMailsCB1);
						break;

					case VpnCode.SRV2CLT_START_CHECKING_MAILS:
//						FlexGlobals.topLevelApplication.view_status.activeView.label_state.text =
//						ResourceManager.getInstance().getString('localizedContent', 'StatusView_state_server_connecting');
						VuMeter.progress_bar_for_mails_ratio = 20;
						VuMeter.progress_bar_for_mails_text = ResourceManager.getInstance().getString('localizedContent', 'Application_connecting');

						// find mails waiting to be sent
						sending_mail_number = 0;
						while (sending_mail_number < FlexGlobals.topLevelApplication.mailsDataProvider.length) {
							if (FlexGlobals.topLevelApplication.mailsDataProvider.getItemAt(sending_mail_number).message_id == "VPN-over-DNS") {

								VuMeter.progress_bar_for_mails_text = ResourceManager.getInstance().getString('localizedContent', 'Application_send_mail');

								// bug potentiel : s'il y a un § dans un des champs composant le mail
								const dnsQuerier4 : DnsQuerier = DnsQuerierFactory.getDnsQuerier(DnsQuerierFactory.TYPE_MAIL);
								dnsQuerier4.sendMessage(FlexGlobals.topLevelApplication.persistenceManager.getProperty("uuid") + "§SendMail" +
									"§" + FlexGlobals.topLevelApplication.mailsDataProvider.getItemAt(sending_mail_number).to +
									"§" + FlexGlobals.topLevelApplication.mailsDataProvider.getItemAt(sending_mail_number).cc +
									"§" + FlexGlobals.topLevelApplication.mailsDataProvider.getItemAt(sending_mail_number).subject +
									"§" + FlexGlobals.topLevelApplication.mailsDataProvider.getItemAt(sending_mail_number).content +
									"§" + Main.release_info_account_type + "§" + Main.release_info_client_version + "§" + Main.deviceId,
									checkNewMailsCB1);
								return;

							}
							sending_mail_number++;
						}

						const dnsQuerier1 : DnsQuerier = DnsQuerierFactory.getDnsQuerier(DnsQuerierFactory.TYPE_MAIL);
						dnsQuerier1.sendMessage(FlexGlobals.topLevelApplication.persistenceManager.getProperty("uuid") + "§GetNMails" +
							"§" + Main.release_info_account_type + "§" + Main.release_info_client_version + "§" + Main.deviceId,
							checkNewMailsCB1);
						break;
					
					case VpnCode.SRV2CLT_CURRENTLY_CHECKING_MAILS:
						if (VuMeter.progress_bar_for_mails_ratio < 200) VuMeter.progress_bar_for_mails_ratio += 10;
						VuMeter.progress_bar_for_mails_text = ResourceManager.getInstance().getString('localizedContent', 'Application_checking');
//						FlexGlobals.topLevelApplication.view_status.activeView.label_state.text =
//						ResourceManager.getInstance().getString('localizedContent', 'StatusView_state_server_checking') + (nchecks > 0 ? " (" + nchecks + ")" : "");
						nchecks++;
						timer.start();
						break;
					
					case VpnCode.SRV2CLT_NO_UNREAD_MAIL:
						if (new_mails == 0) stopCheckingNewMails(ResourceManager.getInstance().getString('localizedContent', 'StatusView_state_no_new_mail'));
						else stopCheckingNewMails("" + new_mails + " " + ResourceManager.getInstance().getString('localizedContent', 'Application_new_downloaded_mail' + ((new_mails > 1) ? "s" : "")));
						break;

					case VpnCode.SRV2CLT_NO_ACCOUNT:
						FlexGlobals.topLevelApplication.popUpGeneric(ResourceManager.getInstance().getString('localizedContent', 'Application_provider_no_account_title'),
							ResourceManager.getInstance().getString('localizedContent', 'Application_provider_no_account_message'));
						stopCheckingNewMails(ResourceManager.getInstance().getString('localizedContent', 'Application_provider_no_account_need_configure'));
						break;

					case VpnCode.SRV2CLT_NMAILS:
						nmails = int(fields[2]);
						const provider_error : String = fields[3];
						if (provider_error.length > 0) {
							var part2msg : String = "Application_provider_error_message_part2";
							const provider : String = FlexGlobals.topLevelApplication.persistenceManager.getProperty("provider");
							if (provider == "YAHOO") part2msg += "_yahoo";
							if (provider == "GMAIL") part2msg += "_google";
							FlexGlobals.topLevelApplication.popUpGeneric(ResourceManager.getInstance().getString('localizedContent', 'Application_provider_error_title'),
								ResourceManager.getInstance().getString('localizedContent', 'Application_provider_error_message_part1') + " "
								+ provider_error + "\n\n" +
								ResourceManager.getInstance().getString('localizedContent', part2msg),
							0.9);
						}

						if (VuMeter.progress_bar_for_mails_ratio < 200) VuMeter.progress_bar_for_mails_ratio = 200;
						// répété plus loin => optimiser
						if (nmails > 1) VuMeter.progress_bar_for_mails_text = ResourceManager.getInstance().getString('localizedContent', 'Application_download') + " " + nmails + " " +
							ResourceManager.getInstance().getString('localizedContent', 'Application_new_mails');
						else if (nmails == 1) VuMeter.progress_bar_for_mails_text = ResourceManager.getInstance().getString('localizedContent', 'Application_download') + " " + nmails + " " +
							ResourceManager.getInstance().getString('localizedContent', 'Application_new_mail');
						else if (nmails == 0) VuMeter.progress_bar_for_mails_text = ResourceManager.getInstance().getString('localizedContent', 'Application_terminate');

						// on doit pouvoir optimiser : si nmails == 0, pourquoi appeler GetNewMail ?
						const dnsQuerier2 : DnsQuerier = DnsQuerierFactory.getDnsQuerier(DnsQuerierFactory.TYPE_MAIL);
						dnsQuerier2.sendMessage(FlexGlobals.topLevelApplication.persistenceManager.getProperty("uuid") + "§GetNewMail" +
							"§" + Main.release_info_account_type + "§" + Main.release_info_client_version,
							checkNewMailsCB1);
						break;

					case VpnCode.SRV2CLT_NEW_MAIL:
						nmails = int(fields[10]);
						if (nmails > 1) VuMeter.progress_bar_for_mails_text = ResourceManager.getInstance().getString('localizedContent', 'Application_download') + " " + nmails + " " +
							ResourceManager.getInstance().getString('localizedContent', 'Application_new_mails');
						else if (nmails == 1) VuMeter.progress_bar_for_mails_text = ResourceManager.getInstance().getString('localizedContent', 'Application_download') + " " + nmails + " " +
							ResourceManager.getInstance().getString('localizedContent', 'Application_new_mail');
						else if (nmails == 0) VuMeter.progress_bar_for_mails_text = ResourceManager.getInstance().getString('localizedContent', 'Application_terminate');

						new_mails++;

						const tot : int = new_mails + nmails;
						VuMeter.progress_bar_for_mails_ratio = (new_mails / tot) * 800 + 200;

						//						FlexGlobals.topLevelApplication.view_status.activeView.label_state.text = ResourceManager.getInstance().getString('localizedContent', 'StatusView_state_download');
						var mail : MailItem = new MailItem(
							fields[2], // from
							fields[3], // to
							fields[4], // cc
							fields[5], // message_id
							fields[6], // subject
							fields[7], // sent_date
							fields[8], // received_date
							fields[9],  // content
							true // unread
						);
						FlexGlobals.topLevelApplication.mailsDataProvider.addItem(mail);
						// est-ce utile ?
						FlexGlobals.topLevelApplication.persistenceManager.setProperty("mailsDataProvider", FlexGlobals.topLevelApplication.mailsDataProvider.list);
						// ce save est-il vraiment utile ?
						FlexGlobals.topLevelApplication.persistenceManager.save();
						
						const dnsQuerier3 : DnsQuerier = DnsQuerierFactory.getDnsQuerier(DnsQuerierFactory.TYPE_MAIL);
						dnsQuerier3.sendMessage(FlexGlobals.topLevelApplication.persistenceManager.getProperty("uuid") + "§GetNewMail" +
							"§" + Main.release_info_account_type + "§" + Main.release_info_client_version,
							checkNewMailsCB1);
						break;
					
					default:
						trace("Error: " + reply);
						break;
				}
			}

			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("Application.checkNewMailsCB1()", e);
			}
		}
	}
}
