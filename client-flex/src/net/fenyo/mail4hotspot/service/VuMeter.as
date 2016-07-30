// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service
{
	import flash.events.*;
	import flash.system.System;
	import flash.utils.*;
	import flash.net.*;
	
	import mx.core.FlexGlobals;
	import mx.resources.ResourceManager;
	
	import net.fenyo.mail4hotspot.dns.*;
	import net.fenyo.mail4hotspot.tools.GenericTools;

	// bug dans le calcul du débit et dans le slider : on ne voit pas dans le slider et on ne doit pas compter les paquets envoyés pour préparer une réception 

	public class VuMeter {
		// 40 ms
		// private static const timer_gui_T : int = 40;
		// 10 ms
		private static const needle_timer_T : int = 10;
		private static var needle_timer : Timer = new Timer(needle_timer_T);
		
		private static const gui_timer_T : int = 200;
		private static var gui_timer : Timer = new Timer(gui_timer_T);
		private static var gui_timer_cnt : int = 0;
		private static var last_sum : int = 0;
		private static var avg : Number = 0.0;
		private static const alpha : Number = 0.9;

		public static var last_transmission : Date = new Date();

		[Bindable]
		public static var progress_bar_for_mails_ratio : uint = 0;

		[Bindable]
		public static var progress_bar_for_messages_ratio : uint = 0;

		[Bindable]
		public static var progress_bar_for_mails_text : String = "";

		[Bindable]
		public static var progress_bar_for_messages_text : String = "";

		[Bindable]
		public static var label_dns_packets_in : String = "";
		private static var dns_packets_in : uint = 0;

		[Bindable]
		public static var label_dns_packets_out : String = "";
		private static var dns_packets_out : uint = 0;

		[Bindable]
		public static var label_dns_packets_error : String = "";
		private static var dns_packets_error : uint = 0;

		[Bindable]
		public static var label_encapsulated_bytes_in : String = "";
		private static var encapsulated_bytes_in : uint = 0;

		[Bindable]
		public static var label_encapsulated_bytes_out : String = "";
		private static var encapsulated_bytes_out : uint = 0;

		public static function init() : void {
			try {
				clearCounters();
				gui_timer.addEventListener(TimerEvent.TIMER, guiTimer);
				needle_timer.addEventListener(TimerEvent.TIMER, needleTimer);
				gui_timer.start();
				activate(true);
				if (ServerSocket.isSupported) needle_timer.start();
			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("VuMeter.init()", e);
			}
		}

		public static function clearCounters() : void {
			dns_packets_in = 0;
			updateReceiveDnsPacket();

			dns_packets_out = 0;
			updateSendDnsPacket();

			dns_packets_error = 0;
			updateLossDnsPacket();

			encapsulated_bytes_in = 0;
			updateReceiveEncapsulatedBytes();

			encapsulated_bytes_out = 0;
			updateSendEncapsulatedBytes();
		}

		public static function activate(active : Boolean) : void {
			try {

                        // A reverifier car ServerSocket.isSupported est apparu sous Android recents
			// sur Windows, on est désactivé quand on perd le focus...
			// Sous Android, on est désactivé quand l'application passe en background, par ex quand le délai avant fermeture du rétro éclairage de l'écran arrive à échéance.
			if (!ServerSocket.isSupported) {
				if (active) needle_timer.start();
				else needle_timer.stop();
			}

			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("VuMeter.activate()", e);
			}
		}

		private static function guiTimer(event : TimerEvent) : void {
			try {

//			trace("current mail queries: " + DnsQuerierFactory.getMailCount());
//			trace("current web queries: " + DnsQuerierFactory.getWebCount());
//			trace("current redirect queries: " + DnsQuerierFactory.getRedirectCount());

			updateProgressBarForMessages();

			if (DnsQuerierFactory.getNQueries() > 0) {
				const now : Date = new Date();
				const delay : Number = now.time - last_transmission.time;
				if (delay > 1000) {
					if ((gui_timer_cnt & 1) == 0) ledOn();
					else ledOff();
				} else {
					if ((gui_timer_cnt & 4) == 0) ledOn();
					else ledOff();
				}
			} else ledOff();

			gui_timer_cnt++;
			if (gui_timer_cnt == 8) gui_timer_cnt = 0;

			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("VuMeter.guiTimer()", e);
			}
		}
		
		private static function needleTimer(event : TimerEvent) : void {
			try {

			var added : int = encapsulated_bytes_in + encapsulated_bytes_out - last_sum;
			avg = alpha * avg + (1.0 - alpha) * (added * 8.0 / (needle_timer_T / 1000));
			last_sum = encapsulated_bytes_in + encapsulated_bytes_out;
			
			var angle : Number = -45.0;
			
			const _avg : Number = avg / 1000.0;
			
			if (_avg < 0) angle = -45.0;
			if (_avg >= 0 && _avg < .1) angle = (-45.0) + (_avg - 0) / (.1 - 0) * ((-38) - (-45));
			if (_avg >= .1 && _avg < 1) angle = (-38.0) + (_avg - .1) / (1 - .1) * ((-26) - (-38));
			if (_avg >= 1 && _avg < 10) angle = (-26.0) + (_avg - 1) / (10 - 1) * ((-16) - (-26));
			if (_avg >= 10 && _avg < 30) angle = (-16.0) + (_avg - 10) / (30 - 10) * ((-6) - (-16));
			if (_avg >= 30 && _avg < 60) angle = (-6.0) + (_avg - 30) / (60 - 30) * ((5) - (-6));
			if (_avg >= 60 && _avg < 100) angle = (5.0) + (_avg - 60) / (100 - 60) * ((21) - (5));
			if (_avg >= 100 && _avg < 200) angle = (21.0) + (_avg - 100) / (200 - 100) * ((35) - (21));
			if (_avg >= 200) angle = 40.0;
			
			// trace("avg=" + avg + " - angle=" + angle);

			if (!Main.tablet) {
				if (FlexGlobals.topLevelApplication.view_status.activeView != null)
					FlexGlobals.topLevelApplication.view_status.activeView.setAngle(-angle);
			} else {
				if (FlexGlobals.topLevelApplication.tablet_view_status.activeView != null)
					FlexGlobals.topLevelApplication.tablet_view_status.activeView.setAngle(-angle);
			}
//			if (need_stop == true && avg < 1.0) needle_timer.stop();

			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("VuMeter.needleTimer()", e);
			}
		}

		private static function ledOn() : void {
			if (!Main.tablet) {
				if (FlexGlobals.topLevelApplication.view_status.activeView == null) return;
			} else {
				if (FlexGlobals.topLevelApplication.tablet_view_status.activeView == null) return;
			}

			switch (FlexGlobals.topLevelApplication.applicationDPI) {
				default:
				case 160:
					if (!Main.tablet) {
						FlexGlobals.topLevelApplication.view_status.activeView.vumeter.source = Main.PictureVumeterBgled160;
					} else {
						FlexGlobals.topLevelApplication.tablet_view_status.activeView.vumeter.source = Main.PictureVumeterBgled160;
					}
					break;

				case 120:
					if (!Main.tablet) {
						FlexGlobals.topLevelApplication.view_status.activeView.vumeter.source = Main.PictureVumeterBgled120;
					} else {
						FlexGlobals.topLevelApplication.tablet_view_status.activeView.vumeter.source = Main.PictureVumeterBgled120;
					}
					break;

				case 240:
					if (!Main.tablet) {
						FlexGlobals.topLevelApplication.view_status.activeView.vumeter.source = Main.PictureVumeterBgled240;
					} else {
						FlexGlobals.topLevelApplication.tablet_view_status.activeView.vumeter.source = Main.PictureVumeterBgled240;
					}
					break;
				
				case 320:
					if (!Main.tablet) {
						FlexGlobals.topLevelApplication.view_status.activeView.vumeter.source = Main.PictureVumeterBgled320;
					} else {
						FlexGlobals.topLevelApplication.tablet_view_status.activeView.vumeter.source = Main.PictureVumeterBgled320;
					}
					break;

				case 480:
					if (!Main.tablet) {
						FlexGlobals.topLevelApplication.view_status.activeView.vumeter.source = Main.PictureVumeterBgled480;
					} else {
						FlexGlobals.topLevelApplication.tablet_view_status.activeView.vumeter.source = Main.PictureVumeterBgled480;
					}
					break;

				case 640:
					if (!Main.tablet) {
						FlexGlobals.topLevelApplication.view_status.activeView.vumeter.source = Main.PictureVumeterBgled640;
					} else {
						FlexGlobals.topLevelApplication.tablet_view_status.activeView.vumeter.source = Main.PictureVumeterBgled640;
					}
					break;

			}
		}
		
		private static function ledOff() : void {
			if (!Main.tablet) {
				if (FlexGlobals.topLevelApplication.view_status.activeView == null) return;
			} else {
				if (FlexGlobals.topLevelApplication.tablet_view_status.activeView == null) return;
			}

			switch (FlexGlobals.topLevelApplication.applicationDPI) {
				default:
				case 160:
					if (!Main.tablet) {
						FlexGlobals.topLevelApplication.view_status.activeView.vumeter.source = Main.PictureVumeterBg160;
					} else {
						FlexGlobals.topLevelApplication.tablet_view_status.activeView.vumeter.source = Main.PictureVumeterBg160;
					}
					break;

				case 120:
					if (!Main.tablet) {
						FlexGlobals.topLevelApplication.view_status.activeView.vumeter.source = Main.PictureVumeterBg120;
					} else {
						FlexGlobals.topLevelApplication.tablet_view_status.activeView.vumeter.source = Main.PictureVumeterBg120;
					}
					break;

				case 240:
					if (!Main.tablet) {
						FlexGlobals.topLevelApplication.view_status.activeView.vumeter.source = Main.PictureVumeterBg240;
					} else {
						FlexGlobals.topLevelApplication.tablet_view_status.activeView.vumeter.source = Main.PictureVumeterBg240;
					}
					break;
				
				case 320:
					if (!Main.tablet) {
						FlexGlobals.topLevelApplication.view_status.activeView.vumeter.source = Main.PictureVumeterBg320;
					} else {
						FlexGlobals.topLevelApplication.tablet_view_status.activeView.vumeter.source = Main.PictureVumeterBg320;
					}
					break;

				case 480:
					if (!Main.tablet) {
						FlexGlobals.topLevelApplication.view_status.activeView.vumeter.source = Main.PictureVumeterBg480;
					} else {
						FlexGlobals.topLevelApplication.tablet_view_status.activeView.vumeter.source = Main.PictureVumeterBg480;
					}
					break;

				case 640:
					if (!Main.tablet) {
						FlexGlobals.topLevelApplication.view_status.activeView.vumeter.source = Main.PictureVumeterBg640;
					} else {
						FlexGlobals.topLevelApplication.tablet_view_status.activeView.vumeter.source = Main.PictureVumeterBg640;
					}
					break;

			}
		}

		private static function updateProgressBarForMessages() : void {
			const ratioInfo : RatioInfo = DnsQuerierFactory.getRatio();
			if (ratioInfo.ratio == -1) ratioInfo.ratio = 0;
			progress_bar_for_messages_ratio = ratioInfo.ratio;
			progress_bar_for_messages_text = ratioInfo.message;
		}

		private static function updateReceiveEncapsulatedBytes() : void {
			label_encapsulated_bytes_in = GenericTools.padNumber(encapsulated_bytes_in, 6);
		}

		public static function statsReceiveEncapsulatedBytes(len : uint) : void {
			encapsulated_bytes_in += len;
			updateReceiveEncapsulatedBytes();
		}

		private static function updateSendEncapsulatedBytes() : void {
			label_encapsulated_bytes_out = GenericTools.padNumber(encapsulated_bytes_out, 6);
		}

		public static function statsSendEncapsulatedBytes(len : uint) : void {
			encapsulated_bytes_out += len;
			updateSendEncapsulatedBytes();
		}

		private static function updateReceiveDnsPacket() : void {
			label_dns_packets_in = GenericTools.padNumber(dns_packets_in, 6);
		}

		public static function statsReceiveDnsPacket() : void {
			dns_packets_in++;
			updateReceiveDnsPacket();
			updateProgressBarForMessages();
			last_transmission = new Date();
		}

		private static function updateSendDnsPacket() : void {
			label_dns_packets_out = GenericTools.padNumber(dns_packets_out, 6);
		}

		public static function statsSendDnsPacket() : void {
			dns_packets_out++;
			updateSendDnsPacket();
			last_transmission = new Date();
		}

		private static function updateLossDnsPacket() : void {
			label_dns_packets_error = GenericTools.padNumber(dns_packets_error, 4);
		}

		public static function statsLossDnsPacket() : void {
			dns_packets_error++;
			updateLossDnsPacket();
		}
	}
}
