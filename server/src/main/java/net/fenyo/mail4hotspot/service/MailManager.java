// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service;

import java.io.IOException;
import java.util.Properties;

import javax.mail.*;
import javax.mail.Address;
import javax.mail.BodyPart;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.NoSuchProviderException;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;
import javax.net.ssl.*;

import org.apache.commons.lang3.ArrayUtils;
import net.fenyo.mail4hotspot.domain.*;
import net.fenyo.mail4hotspot.tools.GenericTools;

// pour rajouter un certificat au keystore global :
// on va dans le rept contenant le keystore global cacerts :
// cd "/cygdrive/c/Program Files/Java/jdk1.7.0_01/jre/lib/security"
// on rajouter un password :
// c:/Program\ Files/Java/jdk1.7.0_01/jre/bin/keytool.exe -protected -storepasswd -keystore cacerts
// on rajouter le certif à l'aide de ce password :
// c:/Program\ Files/Java/jdk1.7.0_01/jre/bin/keytool.exe -importcert -file cyrus-CAcert.pem -alias rsi -storepass PASSWORD -keystore cacerts
// si on ne précisait pas le keystore, un nouveau serait créé : C:\Documents and Settings\fenyo.C01078599\.keystore

///usr/lib/cyrus/bin/deliver -e -r fenyo fenyo
//From: fenyo
//To: fenyo
//Subject: zefpozekfze
//
//test

//From: John Doe <example@example.com>
//MIME-Version: 1.0
//Content-Type: multipart/mixed;
//        boundary="XXXXboundary text"
//
//This is a multipart message in MIME format.
//
//--XXXXboundary text 
//Content-Type: text/plain
//
//this is the body text
//
//--XXXXboundary text 
//Content-Type: text/plain;
//Content-Disposition: attachment;
//        filename="test.txt"
//
//this is the attachment text
//
//--XXXXboundary text--

//MIME-Version: 1.0
//Content-Type: multipart/mixed; boundary=frontier
//
//This is a message with multiple parts in MIME format.
//--frontier
//Content-Type: text/plain
//
//This is the body of the message.
//--frontier
//Content-Type: application/octet-stream
//Content-Transfer-Encoding: base64
//
//PGh0bWw+CiAgPGhlYWQ+CiAgPC9oZWFkPgogIDxib2R5PgogICAgPHA+VGhpcyBpcyB0aGUg
//Ym9keSBvZiB0aGUgbWVzc2FnZS48L3A+CiAgPC9ib2R5Pgo8L2h0bWw+Cg=
//--frontier--

// Subject: =?iso-8859-1?Q?=A1Hola,_se=F1or!?=
// correspond à Subject: ¡Hola, señor!

// http://en.wikipedia.org/wiki/MIME

//MIME-Version: 1.0
//From: Nathaniel Borenstein 
//Subject: A multipart example
//Content-Type: multipart/mixed;
//                 boundary=unique-boundary-1
//
//This is the preamble area of a multipart message.  Mail readers
//that understand multipart format should ignore this preamble.
//
//If you are reading this text, you might want to consider
//changing to a mail reader that understands how to properly
//display multipart messages.
//--unique-boundary-1
//
//Some text appears here...
//[Note that the preceding blank line means
//no header fields were given and this is text,
//with charset US ASCII.  It could have been
//done with explicit typing as in the next part.]
//--unique-boundary-1
//Content-type: text/plain; charset=US-ASCII
//
//This could have been part of the previous part, but illustrates
//explicit versus implicit typing of body parts.
//
//--unique-boundary-1
//Content-Type: multipart/parallel; boundary=unique-boundary-2
//
//--unique-boundary-2
//Content-Type: audio/basic
//Content-Transfer-Encoding: base64
//
//... base64-encoded 8000 Hz single-channel u-law-format audio data
//goes here ...
//
//--unique-boundary-2
//Content-Type: image/gif
//Content-Transfer-Encoding: Base64
//
//... base64-encoded image data goes here ...
//
//--unique-boundary-2--
//
//--unique-boundary-1
//Content-type: text/richtext
//
//This is richtext.Isn't it
//cool?
//
//--unique-boundary-1
//Content-Type: message/rfc822
//
//From: (name in US-ASCII)
//Subject: (subject in US-ASCII)
//Content-Type: Text/plain; charset=ISO-8859-1
//Content-Transfer-Encoding: Quoted-printable
//
//... Additional text in ISO-8859-1 goes here ...
//
//--unique-boundary-1--

public class MailManager {
	protected final org.apache.commons.logging.Log log = org.apache.commons.logging.LogFactory.getLog(getClass());

	private javax.mail.Session session = null;
	private Store store = null;
	private Folder inbox = null;
	private Message [] messages = null;
 
	private Transport transport = null;

	public MailManager() {}

	private void connectToOutgoingServer(final String protocol, final String host, final int port, final String username, final String password) throws MessagingException {
		final Properties prop = new Properties();
		prop.setProperty("mail.mime.address.strict", "false");

		// prop.put("mail.smtp.auth", "true"); mais ça laisse useAuth false
		prop.put("mail.smtp.starttls.enable", "true");

		prop.setProperty("mail.debug", "true");
		session = javax.mail.Session.getInstance(prop, null);
		session.setDebugOut(System.out);
		//session.setDebug(false);
		session.setDebug(true);

		transport = session.getTransport(protocol);
		transport.connect(host, username, password);
	}

	private void connectToServer(final String protocol, final String host, final int port, final String username, final String password) throws MessagingException {
		final Properties prop = new Properties();
		prop.setProperty("mail.mime.address.strict", "false");

//		prop.setProperty(" mail.debug", "true");
		session = javax.mail.Session.getInstance(prop, null);

		//session.setDebugOut(System.out);
		//session.setDebug(false);
//		session.setDebug(true);

		store = session.getStore(protocol);
		store.connect(host, port, username, password);
		inbox = store.getDefaultFolder().getFolder("INBOX");
		inbox.open(Folder.READ_ONLY);
		messages = inbox.getMessages();
	}

	public Message [] getMessages() {
		return messages;
	}

	public String getMessageContentString(final Message message) throws IOException, MessagingException {
		final Object content = message.getContent();
		if (String.class.isInstance(content))
			// content-type: text/{plain, html, etc.}
			// préférer isMimeType(...) à getContentType().equals(...) car getContentType() peut contenir aussi le charset et renvoyer une string comme suit : << text/html; charset="us-ascii" >>
			if (message.isMimeType("text/html")) return GenericTools.html2Text((String) content);
			else if (message.isMimeType("text/plain")) return (String) content;
			else {
				log.warn("message content-type not handled: " + message.getContentType() + " -> downgrading to String");
				return (String) content;
			}
		else if (MimeMultipart.class.isInstance(content)) {
			boolean mixed = false;
			if (message.isMimeType("multipart/mixed")) mixed = true;
			else if (message.isMimeType("multipart/alternative")) mixed = false;
			else {
				log.warn("multipart content-type not handled: " + message.getContentType() + " -> downgrading to multipart/mixed");
				mixed = true;
			}
			return getMultipartContentString((MimeMultipart) content, mixed);
		}
		else {
			log.warn("invalid message content type and class: " + content.getClass().toString() + " - " + message.getContentType());
			return "";
		}
	}

	private String getMultipartContentString(final MimeMultipart multipart, final boolean mixed) throws IOException, MessagingException {
		// content-type: multipart/mixed ou multipart/alternative

		final StringBuffer selected_content = new StringBuffer();
		for (int i = 0; i < multipart.getCount(); i++) {
			final BodyPart body_part = multipart.getBodyPart(i);
			final Object content = body_part.getContent();

			final String content_string;
			if (String.class.isInstance(content))
				if (body_part.isMimeType("text/html")) content_string = GenericTools.html2Text((String) content);
				else if (body_part.isMimeType("text/plain")) content_string = (String) content;
				else {
					log.warn("body part content-type not handled: " + body_part.getContentType() + " -> downgrading to String");
					content_string = (String) content;
				}
			else if (MimeMultipart.class.isInstance(content)) {
				boolean part_mixed = false;
				if (body_part.isMimeType("multipart/mixed")) part_mixed = true;
				else if (body_part.isMimeType("multipart/alternative")) part_mixed = false;
				else {
					log.warn("body part content-type not handled: " + body_part.getContentType() + " -> downgrading to multipart/mixed");
					part_mixed = true;
				}
				content_string = getMultipartContentString((MimeMultipart) content, part_mixed);
			} else {
				log.warn("invalid body part content type and class: " + content.getClass().toString() + " - " + body_part.getContentType());
				content_string = "";
			}

			if (mixed == false) {
				// on sélectionne la première part non vide - ce n'est pas forcément la meilleure alternative, mais comment différentiel un text/plain d'une pièce jointe d'un text/plain du corps du message, accompagnant un text/html du même corps ???
				if (selected_content.length() == 0) selected_content.append(content_string);
			} else {
				if (selected_content.length() > 0 && content_string.length() > 0) selected_content.append("\r\n---\r\n");
				selected_content.append(content_string);
			}
		}
		return selected_content.toString();
	}

	private void connectToSMTPServer(final String host, final int port, final String username, final String password) throws MessagingException {
		connectToOutgoingServer("smtp", host, port, username, password);
	}

	private void connectToSMTPsServer(final String host, final int port, final String username, final String password) throws MessagingException {
		connectToOutgoingServer("smtps", host, port, username, password);
	}

	private void connectToPop3SSLServer(final String host, final int port, final String username, final String password) throws MessagingException {
		connectToServer("pop3s", host, port, username, password);
	}

	private void connectToPop3Server(final String host, final int port, final String username, final String password) throws MessagingException {
		connectToServer("pop3", host, port, username, password);
	}

	private void connectToImapServer(final String host, final int port, final String username, final String password) throws MessagingException {
		connectToServer("imap", host, port, username, password);
	}

	private void connectToImapSSLServer(final String host, final int port, final String username, final String password) throws MessagingException {
		connectToServer("imaps", host, port, username, password);
	}

	public void connectToProvider(final Account.Provider provider, final String username, final String password) throws MessagingException {
		// il faut rajouter dans le client AOL puis tester l'algo de la marque
		if (provider == Account.Provider.AOL) connectToPop3SSLServer("pop.aol.com.", 995, username, password);

		// GMail testé OK pour la réception avec l'algo de la marque
		// en production : en imap - pour tester : en pop
		// if (provider == Account.Provider.GMAIL) connectToPop3SSLServer("pop.gmail.com.", 995, username, password);
		// protocole version 2 : réception OK
		if (provider == Account.Provider.GMAIL) connectToImapSSLServer("imap.gmail.com.", 993, username, password);

		// HotMail inclut outlook.com et live.com
		// HotMail testé OK pour la réception avec l'algo de la marque
		// protocole version 2 : réception OK
		// if (provider == Account.Provider.HOTMAIL) connectToPop3SSLServer("pop3.live.com.", 995, username, password);
		if (provider == Account.Provider.HOTMAIL) connectToImapSSLServer("imap-mail.outlook.com.", 993, username, password);
		
		// YahooMail testé OK pour la réception avec l'algo de la marque
		// MARCHE PAS EN AUTOMATIQUE en POP3S (le password n'est pas pris ou reconnu, l'échange login/passwd semble planter car le passwd est envoyé sans attendre le OK de la commande du login)
		// => ont fait en POP3
		//if (provider == Account.Provider.YAHOO) connectToPop3Server("pop.mail.yahoo.com.", 110, username, password);
		// protocole version 2 : réception OK (corrigée en passant de pop à imaps)
		if (provider == Account.Provider.YAHOO) connectToImapSSLServer("imap.mail.yahoo.com.", 993, username, password);

		// OperaMail correspond à FastMail
		// OperaMail testé OK pour la réception avec l'algo de la marque
		// protocole version 2 : réception OK
		if (provider == Account.Provider.OPERAMAIL) connectToImapSSLServer("mail.messagingengine.com.", 993, username, password);

		if (provider == Account.Provider.TESTIMAPLOCALHOST) connectToImapServer("localhost", 143, username, password);
		if (provider == Account.Provider.TESTIMAPRSI) connectToImapServer("10.69.60.6", 143, username, password);
		if (provider == Account.Provider.TESTPOPLOCALHOST) connectToPop3Server("localhost", 110, username, password);
		if (provider == Account.Provider.TESTPOPRSI) connectToPop3Server("10.69.60.6", 110, username, password);
	}

	public void connectToRelay(final Account.Provider provider, final String username, final String password) throws MessagingException {
		// il faut rajouter dans le client AOL puis tester
		if (provider == Account.Provider.AOL) connectToSMTPsServer("pop.aol.com.", 465, username, password);

		// testé OK
		// protocole version 2 : à retester
		// émission : "DEBUG SMTP: useEhlo true, useAuth false" et version de JavaMail à regarder (1.5.4 : https://java.net/projects/javamail/pages/Home)
		//            et regarder les spécificités de JavaMail pour les différents providers : https://java.net/projects/javamail/pages/Home et " Q: How do I access Yahoo! Mail with JavaMail? " sur http://www.oracle.com/technetwork/java/javamail/faq/index.html#yahoomail
		// voir aussi l'exemple ici : https://community.oracle.com/thread/2350165?tstart=0
		// protocole version 2 : testé OK
		if (provider == Account.Provider.GMAIL) connectToSMTPsServer("smtp.gmail.com.", 465, username, password);

		// testé OK
		// protocole version 2 : testé OK
		// if (provider == Account.Provider.HOTMAIL) connectToSMTPServer("smtp.live.com.", 25, username, password);
		if (provider == Account.Provider.HOTMAIL) connectToSMTPServer("smtp-mail.outlook.com.", 25, username, password);

		// testé OK
		// protocole version 2 : testé OK
		if (provider == Account.Provider.YAHOO) connectToSMTPsServer("smtp.mail.yahoo.com.", 465, username, password);

		// protocole version 2 : testé OK
		if (provider == Account.Provider.OPERAMAIL) connectToSMTPsServer("mail.messagingengine.com.", 995, username, password);

// ICI
	}
	
	public void disconnect() throws MessagingException {
		try {
			if (inbox != null) inbox.close(false);
		} finally {
			if (store != null) store.close();
		}
	}

	public void disconnectRelay() throws MessagingException {
		if (transport != null) transport.close();
	}

	public void sendMessage(Address from_addr, Address [] to_addr, Address [] cc_addr, String subject, String content) throws MessagingException {
		final MimeMessage msg = new MimeMessage(session);

		msg.setFrom(from_addr);
		msg.setRecipients(Message.RecipientType.TO, to_addr);
		if (cc_addr.length > 0) msg.setRecipients(Message.RecipientType.CC, cc_addr);
		msg.setSubject(subject, "UTF-8");
		msg.setContent(content, "text/plain");

		transport.sendMessage(msg, ArrayUtils.addAll(to_addr, cc_addr));
	}

	// marche uniquement pour les connexions HTTPs, pas pour pop3s ni smtps
	public static void trustSSL() {
		// Create a trust manager that does not validate certificate chains
		TrustManager[] trustAllCerts = new TrustManager[]{
		    new X509TrustManager() {
		        public java.security.cert.X509Certificate[] getAcceptedIssuers() {
		            return null;
		        }
		        public void checkClientTrusted(
		            java.security.cert.X509Certificate[] certs, String authType) {
		        }
		        public void checkServerTrusted(
		            java.security.cert.X509Certificate[] certs, String authType) {
		        }
		    }
		};

		// c'est un pb de sécurité, il faudrait mettre à jour les certifs racine et supprimer le all-trusting trust manager
		// Install the all-trusting trust manager
		try {
		    SSLContext sc = SSLContext.getInstance("SSL");
		    sc.init(null, trustAllCerts, new java.security.SecureRandom());
		    HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
		} catch (Exception e) {
			System.out.println("Can not install the all-trusting trust manager");
		}
	}

	// http://javamail.kenai.com/nonav/javadocs/
	// http://code.google.com/p/tubesrus/source/browse/trunk/src/tubesrus/beans/MailManager.java?spec=svn88&r=88
	public static void main(String [] args) throws NoSuchProviderException, MessagingException {
		System.out.println("Salut");

//		trustSSL();

/*		 final Properties props = new Properties();
		 props.put("mail.smtp.host", "my-mail-server");
		 props.put("mail.from", "me@example.com");
		 javax.mail.Session session = javax.mail.Session.getInstance(props, null);
		 try {
		        MimeMessage msg = new MimeMessage(session);
		        msg.setFrom();
		        msg.setRecipients(Message.RecipientType.TO,
		                          "you@example.com");
		        msg.setSubject("JavaMail hello world example");
		        msg.setSentDate(new Date());
		        msg.setText("Hello, world!\n");
		        Transport.send(msg);
		    } catch (MessagingException mex) {
		        System.out.println("send failed, exception: " + mex);
		    }*/

		 final Properties props = new Properties();

		 //props.put("mail.host", "10.69.60.6");
		 //props.put("mail.user", "fenyo");
		 //props.put("mail.from", "fenyo@fenyo.net");
		 //props.put("mail.transport.protocol", "smtps");

		 //props.put("mail.store.protocol", "pop3s");

		 // [javax.mail.Provider[STORE,imap,com.sun.mail.imap.IMAPStore,Sun Microsystems, Inc],
		 // javax.mail.Provider[STORE,imaps,com.sun.mail.imap.IMAPSSLStore,Sun Microsystems, Inc],
		 // javax.mail.Provider[TRANSPORT,smtp,com.sun.mail.smtp.SMTPTransport,Sun Microsystems, Inc],
		 // javax.mail.Provider[TRANSPORT,smtps,com.sun.mail.smtp.SMTPSSLTransport,Sun Microsystems, Inc],
		 // javax.mail.Provider[STORE,pop3,com.sun.mail.pop3.POP3Store,Sun Microsystems, Inc],
		 // javax.mail.Provider[STORE,pop3s,com.sun.mail.pop3.POP3SSLStore,Sun Microsystems, Inc]]
		 // final Provider[] providers = session.getProviders();

		 javax.mail.Session session = javax.mail.Session.getInstance(props, null);

		 session.setDebug(true);
		 //session.setDebug(false);

		 //		 final Store store = session.getStore("pop3s");
//		 store.connect("10.69.60.6", 995, "fenyo", "PASSWORD");
//		 final Store store = session.getStore("imaps");
//		 store.connect("10.69.60.6", 993, "fenyo", "PASSWORD");
//		 System.out.println(store.getDefaultFolder().getMessageCount());

		  //final Store store = session.getStore("pop3");
		 final Store store = session.getStore("pop3s");
		 //final Store store = session.getStore("imaps");

//		 store.addStoreListener(new StoreListener() {
//			 public void notification(StoreEvent e) {
//			 String s;
//			 if (e.getMessageType() == StoreEvent.ALERT)
//			 s = "ALERT: ";
//			 else
//			 s = "NOTICE: ";
//			 System.out.println("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX: " + s + e.getMessage());
//			 }
//		 });

		 //store.connect("10.69.60.6", 110, "fenyo", "PASSWORD");
		 store.connect("pop.gmail.com", 995, "alexandre.fenyo@gmail.com", "PASSWORD");
		 //store.connect("localhost", 110, "alexandre.fenyo@yahoo.com", "PASSWORD");
		 //store.connect("localhost", 995, "fenyo@live.fr", "PASSWORD");
		 //store.connect("localhost", 995, "thisisatestforalex@aol.fr", "PASSWORD");

		 //		 final Folder[] folders = store.getPersonalNamespaces();
//		 for (Folder f : folders) {
//			 System.out.println("Folder: " + f.getMessageCount());
//			 final Folder g = f.getFolder("INBOX");
//			 g.open(Folder.READ_ONLY);
//			 System.out.println("   g:" + g.getMessageCount());
//		 }

		 final Folder inbox = store.getDefaultFolder().getFolder("INBOX");
		 inbox.open(Folder.READ_ONLY);
		 System.out.println("nmessages: " + inbox.getMessageCount());

		 final Message [] messages = inbox.getMessages();

		 for (Message message : messages) {
			 System.out.println("message:");
			 System.out.println("  size: " + message.getSize());
			 try {
				 if (message.getFrom() != null) System.out.println("  From: " + message.getFrom()[0]);
			 } catch (final Exception ex) {
				 System.out.println(ex.toString());
			 }
			 System.out.println("  content-type: " + message.getContentType());
			 System.out.println("  disposition: " + message.getDisposition());
			 System.out.println("  description: " + message.getDescription());
			 System.out.println("  filename: " + message.getFileName());
			 System.out.println("  line count: " + message.getLineCount());
			 System.out.println("  message number: " + message.getMessageNumber());
			 System.out.println("  subject: " + message.getSubject());
			 try {
				 if (message.getAllRecipients() != null) for (Address address : message.getAllRecipients()) System.out.println("  address: " + address);
			 } catch (final Exception ex) {
				 System.out.println(ex.toString());
			 }
		 }

		 for (Message message : messages) {
			 System.out.println("-----------------------------------------------------");
			 Object content;
			try {
				content = message.getContent();
			 if (javax.mail.Multipart.class.isInstance(content)) {
				 System.out.println("CONTENT OBJECT CLASS: MULTIPART");
				 final javax.mail.Multipart multipart = (javax.mail.Multipart) content;
				 System.out.println("multipart content type: " + multipart.getContentType());
				 System.out.println("multipart count: " + multipart.getCount());
				 for (int i = 0; i < multipart.getCount(); i++) {
					 System.out.println("  multipart body[" + i + "]: " + multipart.getBodyPart(i));
					 BodyPart part = multipart.getBodyPart(i);
					 System.out.println("    content-type: " + part.getContentType());
				 }
			 
			 } else if (String.class.isInstance(content)) {
				 System.out.println("CONTENT IS A STRING: {" + content + "}");
			 } else {
				 System.out.println("CONTENT OBJECT CLASS: " + content.getClass().toString());
			 }
			} catch (IOException e) {
				e.printStackTrace();
			}
		 }

		 store.close();

	}
}
