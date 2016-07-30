// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dns;

import net.fenyo.mail4hotspot.service.*;
import net.fenyo.mail4hotspot.tools.GeneralException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;


import java.io.IOException;
import java.net.*;
import java.nio.charset.Charset;
import java.util.*;
import java.util.concurrent.*;

import org.springframework.beans.factory.*;

import org.apache.commons.lang3.ArrayUtils;

@Component("dnsListener")
public class DnsListener implements InitializingBean, DisposableBean, Runnable {
	protected final org.apache.commons.logging.Log log = org.apache.commons.logging.LogFactory.getLog(getClass());

	private DatagramSocket socket;

	final private int DATAGRAMMAXSIZE = 10000;
	final private int DNSFORMAT_ID_MSB = 0;
	final private int DNSFORMAT_ID_LSB = DNSFORMAT_ID_MSB + 1;
	final private int DNSFORMAT_FLAGS_MSB = DNSFORMAT_ID_LSB + 1;
	final private int DNSFORMAT_FLAGS_LSB = DNSFORMAT_FLAGS_MSB + 1;
	final private int DNSFORMAT_QDCOUNT_MSB = DNSFORMAT_FLAGS_LSB + 1;
	final private int DNSFORMAT_QDCOUNT_LSB = DNSFORMAT_QDCOUNT_MSB + 1;
	final private int DNSFORMAT_ANCOUNT_MSB = DNSFORMAT_QDCOUNT_LSB + 1;
	final private int DNSFORMAT_ANCOUNT_LSB = DNSFORMAT_ANCOUNT_MSB + 1;
	final private int DNSFORMAT_NSCOUNT_MSB = DNSFORMAT_ANCOUNT_LSB + 1;
	final private int DNSFORMAT_NSCOUNT_LSB = DNSFORMAT_NSCOUNT_MSB + 1;
	final private int DNSFORMAT_ARCOUNT_MSB = DNSFORMAT_NSCOUNT_LSB + 1;
	final private int DNSFORMAT_ARCOUNT_LSB = DNSFORMAT_ARCOUNT_MSB + 1;
	final private int DNSFORMAT_DATAOFFSET = DNSFORMAT_ARCOUNT_LSB + 1;
	// tun.vpnoverdns.com
	private String DNSDOMAIN;
	private int DNSPORT;
	private boolean INITIALUSERS;
	private boolean INITIALIPS;

	@Autowired
	private AdvancedServices advancedServices;

	@Autowired
	private GeneralServices generalServices;

	private Thread thread = null;

	private class VersionAndDomain {
		public String version;
		public String domain;
	}
	
	public DnsListener() {}

	public String getCreateInitialUsers() {
		return INITIALUSERS ? "true" : "false";
	}

	public void setCreateInitialUsers(final String initialusers) {
		INITIALUSERS = initialusers.toLowerCase().equals("true") ? true : false;
	}

	public String getCreateInitialIps() {
		return INITIALIPS ? "true" : "false";
	}

	public void setCreateInitialIps(final String initialips) {
		INITIALIPS = initialips.toLowerCase().equals("true") ? true : false;
	}

	public String getDnsDomain() {
		return DNSDOMAIN;
	}

	public void setDnsDomain(final String dnsdomain) {
		DNSDOMAIN = dnsdomain;
	}

	public int getDnsPort() {
		return DNSPORT;
	}

	public void setDnsPort(final int dnsport) {
		DNSPORT = dnsport;
	}

	private String getLabel(final String query_string, final int index) {
		final String labels[] = query_string.split("\\.");
		if (index > labels.length - 1) return null;
		return labels[labels.length - index - 1];
	}

	private VersionAndDomain getVersionAndDomain(final byte query[]) throws GeneralException {
		VersionAndDomain vad = new VersionAndDomain();

		final StringBuffer tmpstr = new StringBuffer();
		int offset = DNSFORMAT_DATAOFFSET;
		while (query[offset] != 0) {
			tmpstr.append(new String(query, offset + 1, query[offset], Charset.forName("US-ASCII")));
			tmpstr.append(".");
			offset += query[offset] + 1;
		}
		if (!tmpstr.toString().toLowerCase().endsWith(DNSDOMAIN + ".")) throw new GeneralException("bad domain: " + tmpstr.toString());
		vad.domain = tmpstr.substring(0, tmpstr.length() - DNSDOMAIN.length() - 5).toString();
		// version must be 2 char length beginning with 'v'
		vad.version = tmpstr.substring(tmpstr.length() - DNSDOMAIN.length() - 4, tmpstr.length() - DNSDOMAIN.length() - 2 - 3 + 2 + 1).toString();
		if (vad.version.length() != 2 || !vad.version.substring(0, 1).toLowerCase().equals("v")) throw new GeneralException("bad version: " + tmpstr.toString());
		return vad;
	}

	// pour tester la taille max :
	// dig @192.168.0.205 cn-00000192.id-00000000.v0.mail4hotspot.fenyo.net. a
	// apparemment, en interrogeant via gw, la limite est à 183 octets inclus
	// idem depuis RSI

	// c'est truncated en UDP donc réessai en TCP
	// <fenyo@gw> dig @192.168.0.5 cn-00000183.id-00000000.v0.mail4hotspot.fenyo.net. a
	// ;; Truncated, retrying in TCP mode.
	// A NOTER : par DNS de Free, jusqu'à 78 inclus, ça passe en UDP, sinon, en TCP et ca marche plus. EN EFFET, à partir de 79, le datagram fait dépasse 512 octets

	// DONC limiter au max à 64 octets par réponse : cf constante MAX_REPLY_LEN dans le code flex : DnsQuerier.as
	// quoique le calcul plutôt exact est le suivant et engage à réduire MAX_REPLY_LEN à 32 :
	// paquet le plus long : c'est une réponse (car dans le cas d'une réponse, il y a plusieurs RRs)
	// il doit contenir plusieurs RRs donc c'est des :
	// retry-XXX.ln-XXX.rd-XXXXXXXX.id-XXXXXXXX.v0.mail4hotspot.fenyo.net. :
	// la chaîne fait 57 octets avec le "." final si pas dans un retry, sinon 67 octets, mais n'est pas répétée car c'est une référence vers elle qui est mise dans chaque RR
	// le paquet contient :
	// - entete IP : 20 octets
	// - entete UDP : 8 octets
	// - entete DNS (transaction Id + flags) : 4 octets
	// - 1 query : 57 + 1 (zéro délimiteur de fin - nota : en début de chaque segment il y a la longueur du segment)
	//           = 58 ou 68 avec des retries
	// - des RRs de réponse faisant chacun 16 octets pour transporter 4 octets utiles
	// - des RRs d'infos complémentaires (34 octets au total dans mon test via ethereal) :
	//              - mail4hotspot.fenyo.net IN NS ns1.fenyo.net. : 18 octets
	//              - ns1.fenyo.net          IN A  88.170.235.198 : 16 octets
	// donc : taille du datagramme IP :
	//           sans retries : 124 + (nb de RRs de réponse) * 16
	//           avec retries : 134 + (nb de RRs de réponse) * 16
	// or il y a 3 octets utiles par RR de réponse (le 4ième indique la position dans la réponse car les RRs sont mélangés pour le loadbalancing DNS)
	// donc pour MAX_REPLY_LEN octets utiles à envoyer du serveur vers le client, il y a :
	//           sans retries : 124 + (MAX_REPLY_LEN / 3) * 16 octets dans le datagramme IP
	//           avec retries : 134 + (MAX_REPLY_LEN / 3) * 16 octets dans le datagramme IP
	// donc si MAX_REPLY_LEN = 64, cela fait :
	//           sans retries : 486 octets par datagramme < 512 octets => reste 26 octets pour des RRs complémentaires
	//           avec retries : 496 octets par datagramme < 512 octets => reste 16 octets pour des RRs complémentaires
	// donc c'est très dangereux car trop petit si on rajoute par ex des secondaires supplémentaires pour mail4hotspot.fenyo.net
	// => on prend MAX_REPLY_LEN = 32, ce qui fait gagner 176 octets supplémentaires de marge

	// maj 12/8/2012 :
	//   avec 64 c'est 2x plus rapide, on prend 64
	//   les captures wireshark sont dans mail4hotspot - general\captures\MAX_REPLY_LEN_{32,64}.cap
	//   taille de paquets IP : MAX_REPLY_LEN == 32 => 308 octets au niveau IP
	//   taille de paquets IP : MAX_REPLY_LEN == 64 => 484 octets au niveau IP
	//   donc avec des retries, ca ferait 10 octets de plus, donc 318 et 494 respectivement
	//   donc il reste 512-494=18 octets, environ la taille d'un additional record
	//   on prend une petite marge avec MAX_REPLY_LEN = 
	//   ces paquets ont :
	//   - l'entete DNS
	//   - les flags
	//   - la query courte (pas de retransmission)
	//   - 11 answers si MAX_REPLY_LEN == 32 (car 3 * 11 == 33 >= 32) et 22 answers si MAX_REPLY_LEN == 64 (car 3 * 22 == 66 >= 64) ; 1 answer == 16 octets
	//     donc si on avait mis MAX_REPLY_LEN = 63, on aurait 21 answers car 3 * 21 == 63
	//   - un autoritative nameserver (l'IN NS pour tun.vpnoverdns.com) : 18 octets
	//   - un additional record (l'IN A pour ns2.vpnoverdns.com) : 16 octets
	//  donc on prend MAX_REPLY_LEN == 63 et on a donc :
	//  taille de paquets IP : MAX_REPLY_LEN == 63 => 468 octets au niveau IP
	//  donc reste 512-468 == 44 octets, la marge est donc plus du double qu'avec MAX_REPLY_LEN == 64
	//  au final : MAX_REPLY_LEN == 63, donc 21 réponses par datagramme, donc 63 octets par réponse

	// pb: "dig -p 54 @192.168.0.5 id-00000000.v0.mail4hotspot.fenyo.net. a +norecurse" renvoie le IN NS du domaine
	//     alors qu'avec +recurse ça marche
	// dig @212.27.40.241 id-00000000.v0.mail4hotspot.fenyo.net. a +recurse
	// donc patcher BIND9 : si domaine mail4hotspot.fenyo.net, alors rajouter +recurse
	// recompilé comme suit : ./configure --prefix=/usr/local/bind9 CFLAGS=-g
	// client_request(isc_task_t *task, isc_event_t *event) {
	// appelle
	// dns_message_parse(dns_message_t *msg, isc_buffer_t *source,
	// dans lib/dns/message.c
	// solution : commenter //      allow-recursion     { 127.0.0.0/8; 192.168.0.0/24; };
	//            pour autoriser la recursion
	// et ajouter :
	// dans dns_message_parse() de lib/dns/message.c:
//    msg->id = isc_buffer_getuint16(source);
//    tmpflags = isc_buffer_getuint16(source);
//{
//char str[256];
//sprintf(str, "-------------- 0x%lx\n", (long) tmpflags);
//write(1, str, strlen(str));
//tmpflags |= 0x100;
//}
//    msg->opcode = ((tmpflags & DNS_MESSAGE_OPCODE_MASK)
	// le mieux serait de tester le domaine pour ne faire cela que sous le domaine ad-hoc
	// rqs: on fait comme si recursion demandée ET on recopie dans la réponse comme si l'émetteur l'avait mis, c'est non conforme au RFC-1035

	// pour tester des écritures :
	// sz-00000005.rn-00000000.id-00000001.v0.mail4hotspot.fenyo.net.
	// bf-FFFFFFFFFF.wr-00000000.id-00000256.v0.mail4hotspot.fenyo.net.
	// ck-00000000.id-00000256.v0.mail4hotspot.fenyo.net.
	// a05.rd-00000000.id-00000256.v0.mail4hotspot.fenyo.net.

	// maj 25/10/2015 : TDL :
	// la taille max d'un paquet UDP était de 512 octets (rfc-1035) initialement, et la bibliothèque perl pour le DNS utilisée filtre à cette taille, donc on doit limiter à 512 absolument.
	// mais mettre référence dans chaque RR pour limiter l'usage : rfc-1045§4.1.4
	// et supprimer les réponses RFC-1918 car sinon filtrées par certains DNS.
	// mettre les retry-XXX dans perl.
	// Limitation de la taille max d'une réponse UDP. A mettre en relation avec MAX_REPLY_LEN dans le code flex, l'équivalent dans le code perl est l'option -Y.
	// src/net/fenyo/mail4hotspot/dns/DnsQuerier.as: indique qu'il faut mettre 48 (suite à pb dans un hôtel)
	// vérifier que la compression sert à quelque chose...
	// vérifier dans le code perl que les RR recus sont bien les bons
	
	// maj 08/11/2015 : on met 64 ce qui fait 22 RR et des paquets UDP de 440 octets au niveau UDP et 474 au niveau IP, incluant les "retry-", mais pas d'additional RRs
	// pour tester la bonne valeur : utiliser -Y avec le client perl et faire un wireshark pour regarder le nombre de RR et si ça passe

	// maj 26/11/2015 : protocole "fast" : taille sans réponse :
	// RFC-1035 : Messages carried by UDP are restricted to 512 bytes (not counting the IP or UDP headers).
	// dans ces 512 : on a 12 (header DNS) + 68 (requête) => reste 432 octets
	// on met au max 2 chaînes de 256 caractères chacun (dont la taille est la 1er octet), sachant que les TXT peuvent enchaîner des chaînes de 256.
	// on règle la taille max demandée dans le client.
	
	private byte [] handle(final byte query[], final Inet4Address address) throws GeneralException {
		boolean txt = false;
		boolean txtwithb64 = false;
		byte retvalues[] = null;
		if (query.length <= DNSFORMAT_DATAOFFSET) throw new GeneralException("datagram too short");
		if ((query[DNSFORMAT_QDCOUNT_MSB] << 8) + query[DNSFORMAT_QDCOUNT_LSB] != 1) throw new GeneralException("invalid query count");
		if ((query[DNSFORMAT_FLAGS_MSB] & 2) != 0) throw new GeneralException("truncated");

		final VersionAndDomain vad = getVersionAndDomain(query);
		final String query_string = vad.domain;
		final String version_string = vad.version;
//		log.debug("version string: " + version_string);
//		log.debug("query string: " + query_string);
//		log.debug("label[0]: " + getLabel(query_string, 0));

		final String label0 = getLabel(query_string, 0);

		if (label0.toLowerCase().equals("id-00000000")) {
			final String label1 = getLabel(query_string, 1);
			if (label1 != null && label1.toLowerCase().matches("^cn-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$")) {
				int cnt = new Integer(label1.substring(3));
				if (cnt > 192) throw new GeneralException("ping request too long");
				retvalues = new byte [cnt];
				for (int i = 0; i < cnt; i++) retvalues[i] = (byte) i;
			
			} else retvalues = new byte [] { 'E', 1 }; // 'E'rror 1

		} else if (label0.toLowerCase().equals("id-00000001")) {
			final String label1 = getLabel(query_string, 1);
			if (label1 != null && label1.toLowerCase().matches("^rn-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$")) {
				final String label2 = getLabel(query_string, 2);
				if (label2 != null && label2.toLowerCase().matches("^sz-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$")) {

					int size = new Integer(label2.substring(3));
					final int msg_id = MsgFactory.createMsg(size);
					retvalues = new byte [] { (byte) ((msg_id & 0x00ff0000) >> 16), (byte) ((msg_id & 0x0000ff00) >> 8), (byte) (msg_id & 0x000000ff) };

				} else retvalues = new byte [] { 'E', 2 }; // 'E'rror 2
		
			} else retvalues = new byte [] { 'E', 3 }; // 'E'rror 3
			
		} else if (label0.toLowerCase().matches("^id-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$")) {
			final int msg_id = new Integer(label0.substring(3));
			final String label1 = getLabel(query_string, 1);

//			requête max : 131 car : retry-001.rn-75706993.bf-00696e697469616c69c2a7436f6e6e656374536f636b6574c2a733313330.wr-00000000.id-00731058.v2.tun.vpnoverdns.com
//			longueur max d'un nom de domaine : 250 (certains softs vont plus loin mais pas tous - cf gethostname)
//			2 car par octet de données
//			chaque bf coût 64 car (en incluant .bf-)
//			donc on met plusieurs bf
//			(250-131)/64 = 1,86
//			on peut en mettre 1,8 de plus
//			ça veut dire 3 bf au total mais pas 3 pleins :
//			3 bf à concurrence de 250 car
//			0 bf : 67 car
//			250 = 131-64 + 2*64 + 55
//			55 impair => remplacé par 54
//			Donc deux de 64 (2x30 octets) et 1 de 54 (25 octets)
//			donc 85 octets au lieu de 30
//			donc 2,8 fois plus rapide
			if (label1 != null && label1.toLowerCase().matches("^wr-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$")) {

				final int pos = new Integer(label1.substring(3));

				final String label2 = getLabel(query_string, 2);
				if (label2 != null && label2.toLowerCase().matches("^bf-([0-9a-f][0-9a-f])+$")) {
					final String content = label2.substring(3);
					if (MsgFactory.msgExists(msg_id) == false) {
						retvalues = new byte [] { 'E', 8 }; // 'E'rror 8;
						// log.info("Error 8-1: msg_id=" + msg_id);
					} else retvalues = MsgFactory.getMsg(msg_id).write(pos, content, advancedServices, address);
				} else retvalues = new byte [] { 'E', 4 }; // 'E'rror 4

				if (retvalues != null) {
					final String label3 = getLabel(query_string, 3);
					if (label3 != null && label3.toLowerCase().matches("^bf-([0-9a-f][0-9a-f])+$")) {
						final String content = label3.substring(3);
						if (MsgFactory.msgExists(msg_id) == false) {
							retvalues = new byte [] { 'E', 8 }; // 'E'rror 8;
							// log.info("Error 8-2: msg_id=" + msg_id);
						} else retvalues = MsgFactory.getMsg(msg_id).write(pos + 30, content, advancedServices, address);
					}
				}

				if (retvalues != null) {
					final String label4 = getLabel(query_string, 4);
					if (label4 != null && label4.toLowerCase().matches("^bf-([0-9a-f][0-9a-f])+$")) {
						final String content = label4.substring(3);
						if (MsgFactory.msgExists(msg_id) == false) {
							retvalues = new byte [] { 'E', 8 }; // 'E'rror 8;
							// log.info("Error 8-3: msg_id=" + msg_id);
						} else retvalues = MsgFactory.getMsg(msg_id).write(pos + 60, content, advancedServices, address);
					}
				}

			} else if (label1 != null && label1.toLowerCase().matches("^ck-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$")) {
				if (MsgFactory.msgExists(msg_id) == false) retvalues = new byte [] { 'E', 9 }; // 'E'rror 9;
				else {
					final Msg msg = MsgFactory.getMsg(msg_id);
					if (msg.isProcessed() == false) {
						// message pas encore traité, on demande au client de refaire un ck (check)
//						log.debug(msg.debugContent() + " - " + version_string + "." + query_string);
						retvalues = new byte [] { 'E', 10 }; // 'E'rror 10
					} else {
						final byte len0 = (byte) (msg.outputLength() >> 16);
						final byte len1 = (byte) ((msg.outputLength() >> 8) & 255);
						final byte len2 = (byte) (msg.outputLength() & 255);
						retvalues = new byte [] { 'L', len0, len1, len2 }; // 'L'ength fournie en réponse
					}
				}

			} else if (label1 != null && label1.toLowerCase().matches("^r[dxy]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$")) {
				if (label1.toLowerCase().startsWith("rx") || label1.toLowerCase().startsWith("ry")) txt = true;
				if (label1.toLowerCase().startsWith("ry")) txtwithb64 = true;
				
				final String label2 = getLabel(query_string, 2);
				final int pos = new Integer(label1.substring(3));

				if (label2 != null && label2.toLowerCase().matches("^ln-[0-9][0-9][0-9]$")) {
					final int size = new Integer(label2.substring(3));
					if (MsgFactory.msgExists(msg_id) == false) retvalues = new byte [] { 'E', 11 }; // 'E'rror 11
					else {
						final Msg msg = MsgFactory.getMsg(msg_id);
						if (msg.isProcessed() == false) retvalues = new byte [] { 'E', 12 }; // 'E'rror 12
						// bug dans le protocole v0 corrigé dans les versions suivantes : si on lit 2 octets de la partie compressée (typiquement les 2 derniers du buffer compressé) et que le premier des deux est E, on signale une erreur involontairement
						else {
							if (version_string.toLowerCase().equals("v0") || version_string.toLowerCase().equals("v1")) retvalues = msg.read(pos,  size);
							else {
								byte [] content = msg.read(pos, size);
								if (txtwithb64) {
									// avec Java8
									// content = Base64.getEncoder().encode(content);
									// avec apache commons-codec
									content = org.apache.commons.codec.binary.Base64.encodeBase64(content);

									retvalues = new byte [content.length + 1];
									// put a '0' (48) instead of 0 if base64 encoding, since base64 encoding means non-char bytes (like 0) are not handled
									retvalues[0] = '0';
									for (int i = 0; i < content.length; i++) retvalues[i + 1] = content[i];
								} else {
									retvalues = new byte [size + 1];
									// add a 0 to the beginning of the returned byte array to be sure it can not start with 'E', so it can be distinguished from any error message on the client side
									retvalues[0] = 0;
									for (int i = 0; i < size; i++) retvalues[i + 1] = content[i];
								}
							}
						}
						// pour tester l'erreur involontaire, décommenter :
						// retvalues = new byte [] { 'E', 12 };
						// Ca crée une erreur dans perl à la ligne 'die "  remote error for $names[$i]: try $tries[$i]: ".chr($msgbytes[0]).$msgbytes[1]."\n"'
					}
				} else retvalues = new byte [] { 'E', 13 }; // 'E'rror 13

			} else if (label1 != null && label1.toLowerCase().matches("^ac$")) {

				if (MsgFactory.msgExists(msg_id) == false) retvalues = new byte [] { 'E', 14 }; // 'E'rror 14
				else {
					MsgFactory.removeMsg(msg_id);
					retvalues = new byte [] { 'E', 0 }; // 'E'rror 0 == OK
				}

			} else retvalues = new byte [] { 'E', 5 }; // 'E'rror 5

		} else retvalues = new byte [] { 'E', 6 }; // 'E'rror 6

		if (retvalues == null) retvalues = new byte [] { 'E', 7 }; // 'E'rror 7

		if (txt) {
			final int ntxtstrings = 1 + (retvalues.length - 1) / 255;
			
			final int rr_length = 2 /* pointeur sur le nom de domaine de la query */ + 10 /* TYPE + CLASS + TTL + RDLENGTH */ + ntxtstrings + retvalues.length;
			final int answer_length = ArrayUtils.indexOf(query, (byte) 0, DNSFORMAT_DATAOFFSET) /* nom de domaine de la query */ + 1 /* '\0' */ + 2 /* QTYPE */ + 2 /* QCLASS */ +
					rr_length;
			
			byte answer[] = new byte [answer_length];
			answer[DNSFORMAT_ID_MSB] = query[DNSFORMAT_ID_MSB];
			answer[DNSFORMAT_ID_LSB] = query[DNSFORMAT_ID_LSB];
			answer[DNSFORMAT_FLAGS_LSB] = 0;
			answer[DNSFORMAT_FLAGS_MSB] = (byte) (((byte) (query[DNSFORMAT_FLAGS_MSB] | 128 /* QR: response */ | 4 /* AA */)) & (byte) ~2 /* TC */);
			answer[DNSFORMAT_QDCOUNT_MSB] = 0;
			answer[DNSFORMAT_QDCOUNT_LSB] = 1;
			answer[DNSFORMAT_ANCOUNT_MSB] = 0;
			answer[DNSFORMAT_ANCOUNT_LSB] = 1;
			answer[DNSFORMAT_NSCOUNT_MSB] = 0;
			answer[DNSFORMAT_NSCOUNT_LSB] = 0;
			answer[DNSFORMAT_ARCOUNT_MSB] = 0;
			answer[DNSFORMAT_ARCOUNT_LSB] = 0;

			for (int i = DNSFORMAT_DATAOFFSET; i < DNSFORMAT_DATAOFFSET + 1 /* octet de longueur du premier label */ +
					version_string.length() + 1 /* '.' */ + query_string.length() + 1 /* '.' */ + DNSDOMAIN.length() + 1 /* '\0' */ + 4 /* TYPE + CLASS */; i++)
				answer[i] = query[i];

		    int current_offset = DNSFORMAT_DATAOFFSET + 1 /* octet de longueur du premier label */ + version_string.length() + 1 /* '.' */ + query_string.length() + 1 /* '.' */ +
					DNSDOMAIN.length() + 1 /* '\0' */ + 4 /* QTYPE + QCLASS */;

		    answer[current_offset++] = (DNSFORMAT_DATAOFFSET >> 8) + (byte) 0xc0;
		    answer[current_offset++] = DNSFORMAT_DATAOFFSET & 0xff;

		    answer[current_offset++] = 0x00;
		    answer[current_offset++] = 0x10 /* TYPE */;

		    answer[current_offset++] = 0x00;
		    answer[current_offset++] = 0x01 /* CLASS */;

		    answer[current_offset++] = 0x00;
		    answer[current_offset++] = 0x00;
		    answer[current_offset++] = 0x00;
		    answer[current_offset++] = 0x00 /* TTL */;

		    answer[current_offset++] = (byte) ((ntxtstrings + retvalues.length) >> 8);
		    answer[current_offset++] = (byte) ((ntxtstrings + retvalues.length) & 0xff);

		    for (int i = 0; i < retvalues.length; i++) {
		    	if ((i % 255) == 0) answer[current_offset++] = (byte) (Math.min(255, retvalues.length - i));
		    	answer[current_offset++] = retvalues[i];
		    }
		    
			return answer;

		} else {
				
			// calculer la taille de la section requêtes
			// retvalues length: 1 2 3 4 5 6 7 8 9 10 ...
			// nombre de in a:   1 1 1 2 2 2 3 3 3  4 ...
			// retvalues.length vaut au max optmaxread (ou optmaxread + 1 à partir de la v2) dans perl - il faut trouver l'optimal de optmaxread et le positionner dans perl
			// Par défaut, c'est 48 donc ((48 + 1 /* v2 */) + 2) / 3 == 17 RR par réponse max.
			final int nanswers = (retvalues.length + 2) / 3;
			
			// 192 (3 * 64) bytes max per answer
			if (nanswers > 64) throw new GeneralException("too many answers (" + nanswers + ")");

			final int rr_length = 2 /* pointeur sur le nom de domaine de la query */ + 10 /* TYPE + CLASS + TTL + RDLENGTH */ + 4 /* taille de l'adresse IP résultante */;
			final int answer_length = ArrayUtils.indexOf(query, (byte) 0, DNSFORMAT_DATAOFFSET) /* nom de domaine de la query */ + 1 /* '\0' */ + 2 /* QTYPE */ + 2 /* QCLASS */ +
					rr_length * nanswers;
			
			byte answer[] = new byte [answer_length];
			answer[DNSFORMAT_ID_MSB] = query[DNSFORMAT_ID_MSB];
			answer[DNSFORMAT_ID_LSB] = query[DNSFORMAT_ID_LSB];
			answer[DNSFORMAT_FLAGS_LSB] = 0;
			answer[DNSFORMAT_FLAGS_MSB] = (byte) (((byte) (query[DNSFORMAT_FLAGS_MSB] | 128 /* QR: response */ | 4 /* AA */)) & (byte) ~2 /* TC */);
			answer[DNSFORMAT_QDCOUNT_MSB] = 0;
			answer[DNSFORMAT_QDCOUNT_LSB] = 1;
			answer[DNSFORMAT_ANCOUNT_MSB] = 0;
			answer[DNSFORMAT_ANCOUNT_LSB] = (byte) nanswers;
			answer[DNSFORMAT_NSCOUNT_MSB] = 0;
			answer[DNSFORMAT_NSCOUNT_LSB] = 0;
			answer[DNSFORMAT_ARCOUNT_MSB] = 0;
			answer[DNSFORMAT_ARCOUNT_LSB] = 0;

			for (int i = DNSFORMAT_DATAOFFSET; i < DNSFORMAT_DATAOFFSET + 1 /* octet de longueur du premier label */ +
					version_string.length() + 1 /* '.' */ + query_string.length() + 1 /* '.' */ + DNSDOMAIN.length() + 1 /* '\0' */ + 4 /* TYPE + CLASS */; i++)
				answer[i] = query[i];

			byte rr[] = { (DNSFORMAT_DATAOFFSET >> 8) + (byte) 0xc0, DNSFORMAT_DATAOFFSET & 0xff, 0x00, 0x01 /* TYPE */, 0x00, 0x01 /* CLASS */,
					0, 0, 0, 0 /* TTL */, 0, 4 /* RDLENGTH */, (byte) 0xff, (byte) 0xff, (byte) 0xff, (byte) 0xff /* IP address */ };
			
		    int current_offset = DNSFORMAT_DATAOFFSET + 1 /* octet de longueur du premier label */ + version_string.length() + 1 /* '.' */ + query_string.length() + 1 /* '.' */ +
					DNSDOMAIN.length() + 1 /* '\0' */ + 4 /* QTYPE + QCLASS */;
		    int retindex = 0;
			for (int ans_idx = 0; ans_idx < nanswers; ans_idx++) {
				int ncar = 0;

				if (retindex < retvalues.length) {
					rr[rr.length - 3] = retvalues[retindex];
					ncar++;
				}
				retindex++;
				if (retindex < retvalues.length) {
					rr[rr.length - 2] = retvalues[retindex];
					ncar++;
				}
				retindex++;
				if (retindex < retvalues.length) {
					rr[rr.length - 1] = retvalues[retindex];
					ncar++;
				}
				retindex++;

				rr[rr.length - 4] = (byte) (((byte) ans_idx) | (byte) (ncar << 6));
				
				for (int i = 0; i < rr.length; i++) answer[current_offset++] = rr[i];
			}
			
			return answer;
		}
	}

	private class Handler implements Runnable {
		final DatagramPacket query;

		public Handler(final DatagramPacket query) {
			this.query = query;
		}

		public void run() {
			try {
				// 75% de pertes simulées
				// if (Math.random() * 100 < 25) {
				// 85% de pertes simulées
				// if (Math.random() * 100 < 15) {
				if (Math.random() * 100 < 100) {

				    final byte buf[] = handle(Arrays.copyOf(query.getData(), query.getLength()), (Inet4Address) query.getAddress());
					final DatagramPacket answer = new DatagramPacket(buf, buf.length);
					answer.setAddress(query.getAddress());
					answer.setPort(query.getPort());
					socket.send(answer);

			    } else {
			    	log.debug("simulating loss of datagram");
			    }

			} catch (final GeneralException ex) {
				ex.printStackTrace();
			} catch(Exception ex) {
				ex.printStackTrace();
			}
		}
	}

	public void run() {
		final ExecutorService pool = Executors.newCachedThreadPool();

		try {
			socket = new DatagramSocket(DNSPORT);
		} catch (final SocketException ex) {
			ex.printStackTrace();
			log.error("can not start DNS service");
			return;
		}

		do {
			final DatagramPacket query = new DatagramPacket(new byte [DATAGRAMMAXSIZE], DATAGRAMMAXSIZE);
			try {
				socket.receive(query);
				pool.execute(new Handler(query));
			} catch (IOException ex) {
				log.error(ex);
			}
		} while (thread.isInterrupted() == false);

		try {
			log.info("waiting for executor tasks to terminate");
			pool.awaitTermination(120, TimeUnit.SECONDS);
		} catch (InterruptedException ex) {
			log.error(ex);
		}
	}

	public void destroy() throws Exception {
		try {
			thread.interrupt();
			socket.close();
			thread.join();
		} catch (final InterruptedException ex) {
			log.error(ex);
		}
	}
	public void afterPropertiesSet() throws Exception {
		if (INITIALUSERS) generalServices.createInitialUsers();
		if (INITIALIPS) generalServices.createInitialIps();
		
		thread = new Thread(this);
		thread.start();
	}
}
