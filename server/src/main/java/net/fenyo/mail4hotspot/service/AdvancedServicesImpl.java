// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service;

import java.io.IOException;
import java.net.Inet4Address;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import javax.mail.Address;
import javax.mail.AuthenticationFailedException;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Message.RecipientType;
import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;
import net.fenyo.mail4hotspot.dns.*;
import net.fenyo.mail4hotspot.dns.Msg.BinaryMessageReply;
import net.fenyo.mail4hotspot.domain.*;
import net.fenyo.mail4hotspot.dao.*;
import net.fenyo.mail4hotspot.domain.Account.Provider;
import net.fenyo.mail4hotspot.tools.GeneralException;
import net.fenyo.mail4hotspot.tools.GenericTools;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import javax.persistence.*;
import java.net.*;

@Service("advancedServices")
public class AdvancedServicesImpl implements AdvancedServices {
	protected final org.apache.commons.logging.Log log = org.apache.commons.logging.LogFactory.getLog(getClass());

	private final List<Long> userIdsProcessing = new ArrayList<Long>();

//	private Map<Integer, HttpProxy> map_port_to_proxy = new HashMap<Integer, HttpProxy>();

//	private final int MAX_MAILS_PER_SESSION = 200;
	private int MAX_MAILS_PER_SESSION;
//	private final int MAX_MAILS_PER_SESSION = 500;
//	private final int MAX_MAILS_PER_SESSION = 4;
	// la marque sert au cas où on la connexion avec le provider est coupée avant qu'on ait pu atteindre MAX_MAILS_PER_SESSION :
	// il ne faut jamais s'arrêter quand on rencontre un msgid déjà rencontré, car dans le cas de la coupure avec le provider, il y aurait des mails qu'on ne recupèrerait jamais
	// on doit donc s'arréter uniquement quand on rencontre la marque (ou qu'on atteint MAX_MAILS_PER_SESSION) et qu'on n'est pas en mode header only
	private String DOCKER_IP;

	private boolean DISABLE_SECURITY;

	@Autowired
	private GeneralServices generalServices;

	private boolean new_mails_working = false;
	private Object new_mails_working_sync = new Object();

	public String getDisableSecurity() {
		return DISABLE_SECURITY ? "true" : "false";
	}

	public void setDisableSecurity(final String disablesecurity) {
		DISABLE_SECURITY = disablesecurity.toLowerCase().equals("true") ? true : false;
	}

	public boolean validAccount(Collection<Account> accounts) {
		if (accounts.size() != 1) return false;
		return accounts.iterator().next().getProvider() != Provider.NOT_INITIALIZED;
	}

	public int getMaxMailsPerSession() {
		return MAX_MAILS_PER_SESSION;
	}

	public void setMaxMailsPerSession(final int max_mails_per_session) {
		MAX_MAILS_PER_SESSION = max_mails_per_session;
	}

	public String getDockerIp() {
		return DOCKER_IP;
	}

	public void setDockerIp(final String docker_ip) {
		DOCKER_IP = docker_ip;
	}

	private class ProcessMailsRunnable implements Runnable {
		private final String username;

		public void run() {
			processMails(username);
		}

		public ProcessMailsRunnable(final String username) {
			this.username = username;
		}
	}

	// each minute
	@Scheduled(fixedDelay = 60000)
	public void sweepDirtyObjects() {
		HttpProxyFactory.sweep();
		MsgFactory.sweep();
	}

	private Address [] getAddressesFromString(final String str) throws AddressException {
		final List<Address> retval = new ArrayList<Address>();

		final String [] parts = str.split("[;, ]");
		for (String part : parts) if (part.length() > 0) retval.add(new InternetAddress(part));
		return retval.toArray(new Address[0]);
	}

	// check mails to send each 5 secs
	@Scheduled(fixedDelay = 5000)
	public void sendNewMails() {
		try {
			synchronized (new_mails_working_sync) {
				if (new_mails_working == true) return;
				new_mails_working = true;
			}

			final List<AccountAndOutboxMail> accounts_and_mails = generalServices.getSentMails();

			for (AccountAndOutboxMail account_and_mail : accounts_and_mails) {
				boolean should_remove_user_id_processing = false;
				final User user = generalServices.getUserByAccount(account_and_mail.account);

				try {
					boolean abort_this_try = false;
					
					synchronized (userIdsProcessing) {
						if (userIdsProcessing.contains(user.getId())) {
							log.warn("account is currently processed");
							abort_this_try = true;
						} else {
							should_remove_user_id_processing = true;
							userIdsProcessing.add(user.getId());
						}
					}

					final MailManager manager = new MailManager();
					if (abort_this_try == false) {
						try {
							manager.connectToRelay(account_and_mail.account.getProvider(), account_and_mail.account.getUsername(), account_and_mail.account.getPassword());
						} catch (final MessagingException ex) {
							// le mieux serait de ne pas supprimer dans tous les cas, mais de compter le nombre de tentative et de les espacer
							log.warn("can not connect to Relay: " + ex.toString());
							abort_this_try = true;
							generalServices.removeSentMail(account_and_mail.mail);
							generalServices.sendInternalMailByAccount(account_and_mail.account,
									"It was not possible to send your mail",
									"An exception occured while sending your mail:\n" + ex.toString() +
									"\n\nthis mail has not been sent:\n-----\n" +
									"From: " + account_and_mail.account.getEmail() + "\n" +
									"To: " + account_and_mail.mail.getToAddr() + "\n" +
									"Cc: " + ((account_and_mail.mail.getCcAddr() == null) ? "" : account_and_mail.mail.getCcAddr()) + "\n" +
									"Subject: " + account_and_mail.mail.getSubject() + "\n\n" +
									account_and_mail.mail.getContent() + "\n");
						}
					}

					if (abort_this_try == false) {
						generalServices.removeSentMail(account_and_mail.mail);

						try {
							final Address from_addr = new InternetAddress(account_and_mail.account.getEmail());
							final Address [] to_addr = getAddressesFromString(account_and_mail.mail.getToAddr());
							final Address [] cc_addr = getAddressesFromString(account_and_mail.mail.getCcAddr());

							manager.sendMessage(from_addr, to_addr, cc_addr, account_and_mail.mail.getSubject(), account_and_mail.mail.getContent());

						} catch (final MessagingException ex) {
							log.warn(ex.toString());

							generalServices.sendInternalMailByAccount(account_and_mail.account,
									"It was not possible to send your mail",
									"An exception occured while sending your mail:\n" + ex.toString() +
									"\n\nthis mail has not been sent:\n-----\n" +
									"From: " + account_and_mail.account.getEmail() + "\n" +
									"To: " + account_and_mail.mail.getToAddr() + "\n" +
									"Cc: " + ((account_and_mail.mail.getCcAddr() == null) ? "" : account_and_mail.mail.getCcAddr()) + "\n" +
									"Subject: " + account_and_mail.mail.getSubject() + "\n\n" +
									account_and_mail.mail.getContent() + "\n");

						} finally {
							try {
								manager.disconnectRelay();
							} catch (MessagingException ex) {
								log.error(ex.toString());
							}
						}
					}
				} finally {
					synchronized (userIdsProcessing) {
						if (should_remove_user_id_processing && userIdsProcessing.contains(user.getId())) userIdsProcessing.remove(user.getId());
					}			
				}
			}

		} finally {
			synchronized (new_mails_working_sync) {
				new_mails_working = false;
			}
		}
	}

//	@Scheduled(fixedDelay = 60000)
//	public void processMails() {
//		// récupérer les User et sortir de la transaction
//		final List<User> userList = generalServices.getUserList();
//
//		for (User user : userList) {
//			try {
//				// traiter les mails de cet utilisateurs dans une transaction indépendante
//				generalServices.processMailsFromUser(user);
//			} catch (final Exception ex) {
//				ex.printStackTrace();
//			}
//		}
//	}

	public void processMails(final String username) {
		_processMails(username, false);
	}

	public void processMailsWithHeaderOnly(final String username) {
		_processMails(username, true);
	}

	// le principe de la marque consiste à contourner le pb potentiel suivant :
	// cas où on récupère des nouveaux messages mais la connexion est interrompue en cours
	// ex:
	// on a 20 nouveaux messages : de 20 (le plus récent) à 1 (le plus vieux)
	// on récupère le 20, puis le 19, etc. et au 15 ca plante
	// donc la marque n'est pas modifiée, puisqu'on est pas arrivé au bout
	// donc quand on rerécupère 20, 19 etc. on les a déjà lus mais on ne stoppe pas
	private void _processMails(final String username, final boolean headerOnly) {
		Long session_id = null;
		boolean should_remove_user_id_processing = false;

		final GeneralServices.UserAndAccounts userAndAccounts = generalServices.getUserAndAccounts(username);

		if (!validAccount(userAndAccounts.accounts)) {
			log.warn("invalid number of accounts");
			return;
		}

		try {
			synchronized (userIdsProcessing) {
				if (userIdsProcessing.contains(userAndAccounts.user.getId())) {
//					log.warn("account is currently processed");
					return;
				} else {
					should_remove_user_id_processing = true;
					userIdsProcessing.add(userAndAccounts.user.getId());
				}
			}

			final Account account = userAndAccounts.accounts.iterator().next();

			// on supprime les mails qui sont plus vieux que la marque et récupérés il y a plus d'un certain temps
			// s'il n'y a pas de marque, on ne supprime rien
			generalServices.removeOldMessages(account);

			final List<String> msgids = generalServices.getMsgIds(account);
			final List<String> msgids_older_than_mark = generalServices.getMessageIdsOlderThanMark(account);
			// final String message_id_mark = generalServices.getMessageIdMark(account);

//			if (message_id_mark != null) {
//				// trouver comment se servir de "assert(msgids.contains(message_id_mark));"
//				if (msgids.contains(message_id_mark) == false) {
//					log.error("assertion failed");
//					System.exit(1);
//				}
//			}

			final MailManager manager = new MailManager();
			try {
				manager.connectToProvider(account.getProvider(), account.getUsername(), account.getPassword());

				if (manager.getMessages() == null) log.error("manager.getMessages() == null");
				else {
					final Message [] messages = manager.getMessages();
					boolean marked = false;
					String first_message_id = null;

					for (int msg_idx = messages.length - 1; (msg_idx >= 0) && (messages.length - msg_idx <= MAX_MAILS_PER_SESSION); msg_idx--) {
						final Message message = messages[msg_idx];

						final String [] msgidHeaders = message.getHeader("Message-Id");
						if (msgidHeaders == null || msgidHeaders.length == 0) log.warn("ignoring message without Message-Id");
						else {
							if (first_message_id == null) first_message_id = msgidHeaders[0];

							if (!msgids.contains(msgidHeaders[0])) {
								// this is a new mail

								final InboxMail inboxMail = new InboxMail();

								inboxMail.setUnread(true);
								inboxMail.setHeaderOnly(headerOnly);

								// Message-Id
								inboxMail.setMessageId(GenericTools.truncate(msgidHeaders[0], InboxMail.MAX_MESG_ID_LENGTH));

								// From
								final Address [] from_addr = message.getFrom();
								if (from_addr != null) {
									final StringBuffer from_addresses = new StringBuffer();
									for (int i = 0; i < from_addr.length; i++) {
										if (i > 0) from_addresses.append("; ");
										from_addresses.append(from_addr[0].toString());
									}
									inboxMail.setFromAddr(GenericTools.truncate(from_addr[0].toString(), InboxMail.MAX_ADDRESS_LENGTH));
								}

								// To
								final Address [] to_addr = message.getRecipients(RecipientType.TO);
								if (to_addr != null) {
									final StringBuffer to_addresses = new StringBuffer();
									for (int i = 0; i < to_addr.length; i++) {
										if (i > 0) to_addresses.append("; ");
										to_addresses.append(to_addr[0].toString());
									}
									inboxMail.setToAddr(GenericTools.truncate(to_addr[0].toString(), InboxMail.MAX_ADDRESS_LENGTH));
								}

								// Cc
								final Address [] cc_addr = message.getRecipients(RecipientType.CC);
								if (cc_addr != null) {
									final StringBuffer cc_addresses = new StringBuffer();
									for (int i = 0; i < cc_addr.length; i++) {
										if (i > 0) cc_addresses.append("; ");
										cc_addresses.append(cc_addr[0].toString());
									}
									inboxMail.setCcAddr(GenericTools.truncate(cc_addr[0].toString(), InboxMail.MAX_ADDRESS_LENGTH));
								}

								// Subject
								if (message.getSubject() != null)
									inboxMail.setSubject(GenericTools.truncate(message.getSubject(), InboxMail.MAX_SUBJECT_LENGTH));

								// Dates
								inboxMail.setSentDate(message.getSentDate());
								inboxMail.setReceivedDate(new java.util.Date());

								if (!headerOnly) {
									// Content
									try {
										inboxMail.setContent(GenericTools.truncate(manager.getMessageContentString(message), InboxMail.MAX_CONTENT_LENGTH));
									} catch (final IOException ex) {
										ex.printStackTrace();
									} catch (final MessagingException ex) {
										ex.printStackTrace();
									}
								}

								// persists entity
								if (headerOnly) {
									// header only == objectif : ce qui est déjà dans la boîte mail du provider ne sera jamais récupéré
									// le plus récent mail (on commence par les plus récents et on marque le 1er), qu'on n'a pas déjà vu (car on ne passe ici que pour les mails pas déjà vus), est marqué
									if (!marked) {
										session_id = generalServices.saveInboxMailMark(account, inboxMail, session_id);
										marked = true;
									} else session_id = generalServices.saveInboxMail(account, inboxMail, session_id);
								} else {
									session_id = generalServices.saveInboxMail(account, inboxMail, session_id);
								}
							} else {
								// on a déjà ce message-id

								if (headerOnly) {
									// header only == objectif : ce qui est déjà dans la boîte mail du provider ne sera jamais récupéré
									// le plus récent mail (on commence par les plus récents et on marque le 1er), qu'on n'a pas déjà vu (car on ne passe ici que pour les mails pas déjà vus), est marqué
									if (!marked) {
										generalServices.saveMark(account, msgidHeaders[0]);
										marked = true;
									}
								} else {
									// pas en mode header only => on vérifie si on a rencontré la marque

//									if (msgidHeaders[0].equals(message_id_mark)) {
										// marque rencontrée => on arrête
//										break;
//									}
//									log.debug("msgids_older_than_mark size:" + msgids_older_than_mark.size());
									if (msgids_older_than_mark != null && msgids_older_than_mark.contains(msgidHeaders[0])) {
										// marque rencontrée => on arrête
										break;
									}
								}
							}

						}
					}

					// après la boucle sur les messages (donc soit sortie du break car rencontre de la marque, soit boucle terminée)
					// on met donc à jour la marque avec le 1er message (le plus récent récupéré)
					if  (!headerOnly && first_message_id != null) generalServices.saveMark(account, first_message_id);

				}
			} catch (final AuthenticationFailedException ex) {
	    		log.info("TRACE: authentication failure;" + username + ";" + ex.toString() + ";");
				generalServices.saveProviderError(account, ex.toString());
			} catch (final MessagingException ex) {
				ex.printStackTrace();
			} finally {
				try {
					manager.disconnect();
				} catch (final MessagingException ex) {
					ex.printStackTrace();
				}
			}

		} finally {
			synchronized (userIdsProcessing) {
				if (should_remove_user_id_processing && userIdsProcessing.contains(userAndAccounts.user.getId())) userIdsProcessing.remove(userAndAccounts.user.getId());
			}			
		}
	}

	public String processQueryFromClient(final String query, final Inet4Address address) {
		boolean should_remove_user_id_processing = false;

		try {
	        Ip ip = null;
	        try {
	        	ip = generalServices.getIp(address);
	        } catch (final NoResultException ex) {}
	        if (ip != null && ip.isWatch()) log.info("TRACE: watch ip;process query;" + address.toString() + ";");

			final String [] fields = query.split("§");
	        final String uuid = fields[0];
	        final User user = generalServices.getUserByUuid(uuid);
	        final String username = user.getUsername();
	        if (ip != null && ip.isWatch()) log.info("TRACE: watch ip;process query w/ valid username;" + username + ";" + address.toString() + ";");
	        if (user.isWatch()) log.info("TRACE: watch user;process query;" + username + ";" + address.toString() + ";");

	        if (fields[1].equals("GetMessage")) {
	        	if (user.getType() != User.Type.ANONYMOUS && user.getType() != User.Type.INITIALIZE && user.getMessage() != null && !user.getMessage().isEmpty()) {
	        		log.info("TRACE: message for user;" + username + ";" + user.getMessage() + ";");
	        		return "" + VpnCode.SRV2CLT_OK + "§" + "message for user " + username + ": " + user.getMessage();
	        	}

	        	if (ip != null && ip.getMessage() != null && !ip.getMessage().isEmpty()) {
	        		log.info("TRACE: message for ip;" + ip.getIpString() + ";" + ip.getMessage() + ";");
	        		return "" + VpnCode.SRV2CLT_OK + "§" + "message for anonymous user from IP " + ip.getIpString() + ": " + ip.getMessage();
	        	}

	        	return "" + VpnCode.SRV2CLT_OK + "§";
	        }
	        
	        if (user.getType() == User.Type.BLOCKED) throw new GeneralException("query from blocked user (username=" + username + ")");
	        if ((user.getType() == User.Type.ANONYMOUS || user.getType() == User.Type.INITIALIZE) && ip != null && ip.getType() == Ip.Type.BLOCKED) throw new GeneralException("query from blocked ip (ip=" + ip.toString() + ")");

	        // userAndAccounts contient des entités détachées (donc si pas d'exception en accédant à userAndAccounts.user.getId() la première fois, pas de risque en y accédant en sortant)
    		final GeneralServices.UserAndAccounts userAndAccounts = generalServices.getUserAndAccountsByUuid(uuid);

	        if (fields[1].equals("CheckMails")) {
	    		log.info("TRACE: CheckMails;" + username + ";" + address.toString() + ";");

	    		if (user.getType() != User.Type.NORMAL && user.getType() != User.Type.TRIAL) throw new GeneralException("security exception: CheckMails authorized only for NORMAL/TRIAL users (username=" + username + ")");
	    		
	    		// si cet utilisateur a par ex été supprimé du serveur, il y aura une exception, prise en compte dans le catch final de cette méthode
	    		if (!validAccount(userAndAccounts.accounts)) log.warn("invalid number of accounts for " + username);
	    		else {
		        	// race condition possible ici : userIdsProcessing n'est mis à jour que dans le thread donc si le GetNMails envoyé par le client arrive avant la mise à jour, le client pensera qu'il n'y a pas de nouveau même alors que la vérification n'a pas commencé 
		        	final Thread thread = new Thread(new ProcessMailsRunnable(username));
		        	thread.start();
	    		}

	        	return "" + VpnCode.SRV2CLT_START_CHECKING_MAILS + "§Start checking mails";
	        } else if (fields[1].equals("SendMail")) {
	    		log.info("TRACE: SendMail;" + username + ";" + address.toString() + ";");

	    		if (user.getType() != User.Type.NORMAL && user.getType() != User.Type.TRIAL) throw new GeneralException("security exception: SendMail authorized only for NORMAL/TRIAL users (username=" + username + ")");

	    		if (!validAccount(userAndAccounts.accounts)) {
	    			log.error("invalid number of accounts");
	    			return "" + VpnCode.SRV2CLT_NO_ACCOUNT;
	    		} else {
	    			final Account account = userAndAccounts.accounts.iterator().next();
					final OutboxMail outboxMail = new OutboxMail();
					outboxMail.setToAddr(fields[2]);
					outboxMail.setCcAddr(fields[3]);
					outboxMail.setSubject(fields[4]);
					outboxMail.setContent(fields[5]);
					generalServices.saveOutboxMail(account, outboxMail);
	    		}

    			return "" + VpnCode.SRV2CLT_MAIL_SAVED;
	        } else if (fields[1].equals("GetNMails")) {
	    		log.info("TRACE: GetNMails;" + username + ";" + address.toString() + ";");

	    		if (user.getType() != User.Type.NORMAL && user.getType() != User.Type.TRIAL) throw new GeneralException("security exception: GetNMails authorized only for NORMAL/TRIAL users (username=" + username + ")");

	    		// si cet utilisateur a par ex été supprimé du serveur, il y aura une exception, prise en compte dans le catch final de cette méthode
	    		if (!validAccount(userAndAccounts.accounts)) {
	    			log.warn("invalid number of accounts for " + username);
	    			return "" + VpnCode.SRV2CLT_NO_ACCOUNT;
	    		}

	    		try {
	    			synchronized (userIdsProcessing) {
	    				if (userIdsProcessing.contains(userAndAccounts.user.getId())) {
//	    					log.warn("account is currently processed");
	    					return "" + VpnCode.SRV2CLT_CURRENTLY_CHECKING_MAILS + "§Currently checking mails";
	    				} else {
	    					should_remove_user_id_processing = true;
	    					userIdsProcessing.add(userAndAccounts.user.getId());

	    					final long nmails = generalServices.getUnreadMailsCount(userAndAccounts.accounts.iterator().next());

	    					final String provider_error = generalServices.getLastProviderError(userAndAccounts.accounts.iterator().next());
    						return "" + VpnCode.SRV2CLT_NMAILS + "§NMails" + "§" + nmails + "§" + provider_error;
	    				}
	    			}
	    		} finally {
					synchronized (userIdsProcessing) {
						if (should_remove_user_id_processing && userIdsProcessing.contains(userAndAccounts.user.getId())) userIdsProcessing.remove(userAndAccounts.user.getId());
					}
	    		}

	        } else if (fields[1].equals("GetNewMail")) {
	    		log.info("TRACE: GetNewMail;" + username + ";" + address.toString() + ";");

	    		if (user.getType() != User.Type.NORMAL && user.getType() != User.Type.TRIAL) throw new GeneralException("security exception: GetNewMail authorized only for NORMAL users (username=" + username + ")");

	    		// si cet utilisateur a par ex été supprimé du serveur, il y aura une exception, prise en compte dans le catch final de cette méthode
	    		if (!validAccount(userAndAccounts.accounts)) {
	    			log.warn("invalid number of accounts for " + username);
	    			return "" + VpnCode.SRV2CLT_NO_UNREAD_MAIL + "§OK: no unread mail";
	    		}

	    		try {
	    			synchronized (userIdsProcessing) {
	    				if (userIdsProcessing.contains(userAndAccounts.user.getId())) {
//	    					log.warn("account is currently processed");
	    					return "" + VpnCode.SRV2CLT_CURRENTLY_CHECKING_MAILS + "§Currently checking mails";
	    				} else {
	    					should_remove_user_id_processing = true;
	    					userIdsProcessing.add(userAndAccounts.user.getId());

	    					final long nmails = generalServices.getUnreadMailsCount(userAndAccounts.accounts.iterator().next());

	    					// pb potentiel à corriger : getLatestUnreadMail passe le mail à read dans la BDD, mais si on plante avant la réception par le client, il ne sera jamais récupéré
	    					// il faudrait attendre l'acquittement de ce Message pour passer le mail à read dans la BDD
	    					final InboxMail mail = generalServices.getLatestUnreadMail(userAndAccounts.accounts.iterator().next());
	    					if (mail == null) return "" + VpnCode.SRV2CLT_NO_UNREAD_MAIL + "§OK: no unread mail";
	    					else {
	    						final String field_from = GenericTools.escapeDelimiter(mail.getFromAddr());
	    						final String field_to = GenericTools.escapeDelimiter(mail.getToAddr());
	    						final String field_cc = GenericTools.escapeDelimiter(mail.getCcAddr());
	    						final String field_message_id = GenericTools.escapeDelimiter(mail.getMessageId());
	    						final String field_subject = GenericTools.escapeDelimiter(mail.getSubject());
	    						final String field_sent_date = GenericTools.escapeDelimiter(mail.getSentDate().toString());
	    						final String field_received_date = GenericTools.escapeDelimiter(mail.getReceivedDate().toString());
	    						final String field_content = GenericTools.escapeDelimiter(mail.getContent());

	    						return "" + VpnCode.SRV2CLT_NEW_MAIL + "§New mail" +
	    							"§" + field_from +
	    							"§" + field_to +
	    							"§" + field_cc +
	    							"§" + field_message_id +
	    							"§" + field_subject +
	    							"§" + field_sent_date +
	    							"§" + field_received_date +
	    							"§" + field_content +
	    							"§" + (nmails - 1);
	    					}
	    				}
	    			}
	    		} finally {
					synchronized (userIdsProcessing) {
						if (should_remove_user_id_processing && userIdsProcessing.contains(userAndAccounts.user.getId())) userIdsProcessing.remove(userAndAccounts.user.getId());
					}
	    		}

	        } else if (fields[1].equals("ConnectSocket")) {
	    		log.info("TRACE: ConnectSocket;" + username + ";" + fields[2] + ";" + fields[3] + ";" + address.toString() + ";");

	    		final int remote_port = new Integer(fields[2]);

	    		// convert IPv4 name to address is necessary
	    		fields[3] = Inet4Address.getByName(fields[3]).toString().replaceFirst(".*/", "");
	    		if (fields[3].equals("127.0.0.1")) {
	    			fields[3] = DOCKER_IP;
	    			switch (user.getType()) {
	    			case INITIALIZE:
	    			case ANONYMOUS:
		    			if (!DISABLE_SECURITY && remote_port != 443 && remote_port != 3130) throw new GeneralException("security exception: invalid remote port " + remote_port + " - (username=" + username + ")");
	    				break;
	    				
	    			case NORMAL:
	    			case TRIAL:
	    				if (!DISABLE_SECURITY && remote_port != 80 && remote_port != 443 && remote_port != 3128 && remote_port != 3129 && remote_port != 3130) throw new GeneralException("security exception: invalid remote port " + remote_port + " - (username=" + username + ")");
	    				break;

	    			case BLOCKED:
	    			default:
	    				throw new GeneralException("should not happen (username=" + username + ")");
	    			}
	    		} else {
	    			// vérifier que c'est unicast et pas rfc1918 et { normal ou trial }
	    			if (!DISABLE_SECURITY && (
	    					(user.getType() == User.Type.ANONYMOUS && remote_port != 22) ||
	    					(user.getType() != User.Type.ANONYMOUS && user.getType() != User.Type.NORMAL && user.getType() != User.Type.TRIAL)
	    					)) throw new GeneralException("invalid account type for destination " + fields[3] + ":" + remote_port + " - (username=" + username + ")");
	    			if (user.getType() == User.Type.ANONYMOUS) log.info("TRACE: ConnectSocket anonymous ssh;" + fields[3] + ";" + address.toString() + ";");
	    			final String [] bytes = fields[3].split("\\.");
	    			if (bytes.length != 4) throw new GeneralException("invalid address: " + fields[3] + " - (username=" + username + ")");
	    			for (final String _byte : bytes) {
		    			if (!_byte.matches("[0-9]+")) throw new GeneralException("invalid address: " + fields[3] + " - (username=" + username + ")");
		    			if (_byte.length() >= 2 && _byte.matches("0.*")) throw new GeneralException("invalid address: " + fields[3] + " - (username=" + username + ")");
		    			if (new Integer(_byte).intValue() < 0 || new Integer(_byte).intValue() > 255) throw new GeneralException("invalid non RFC-1918 unicast address: " + fields[3] + " - (username=" + username + ")");
	    			}
	    			final int [] intvalues = { new Integer(bytes[0]), new Integer(bytes[1]), new Integer(bytes[2]), new Integer(bytes[3])};
	    			if (!DISABLE_SECURITY && (intvalues[0] >= 224 || (intvalues[0] == 192 && intvalues[1] == 168) || (intvalues[0] == 172 && intvalues[1] >= 16 && intvalues[1] < 32) || intvalues[0] == 10))
	    				throw new GeneralException("invalid address: " + fields[3] + " - (username=" + username + ")");
	    		}

	        	final HttpProxy proxy = HttpProxyFactory.createHttpProxy(uuid, remote_port, fields[3]);
	        	final int port = proxy.getLocalPort();
	    		log.info("TRACE: ConnectSocket id;" + username + ";" + fields[2] + ";" + fields[3] + ";" + port + ";" + address.toString() + ";");
	        	return "" + VpnCode.SRV2CLT_SOCKET_ID + "§" + port;

	        } else if (fields[1].equals("ClosedSocket")) {
	        	final int id = new Integer(fields[2]);
	    		log.info("TRACE: ClosedSocket;" + username + ";" + id + ";" + address.toString() + ";");
	        	final boolean ret = HttpProxyFactory.removeHttpProxy(id);
        		if (ret == false) {
        			log.warn("no such id");
        			return VpnCode.SRV2CLT_ERROR + "§Error: no such id";
        		} else return VpnCode.SRV2CLT_OK + "§OK";
	        } else return "" + VpnCode.SRV2CLT_NO_SUCH_COMMAND + "§Error: no such command";
		} catch (final Exception ex) {
			log.error(ex);
			// pour voir qui génère cela, suite à une possible attaque
			log.error("address: " + address.toString() + " - query: [" + query + "]");
			ex.printStackTrace();
			return VpnCode.SRV2CLT_EXCEPTION + "§Error: exception";
		}
	}

	public BinaryMessageReply processBinaryQueryFromClient(final String query, final byte data[], final Inet4Address address) {
        final BinaryMessageReply reply = new BinaryMessageReply();
		reply.reply_data = new byte [] {};

		try {
	        Ip ip = null;
	        try {
	        	ip = generalServices.getIp(address);
	        } catch (final NoResultException ex) {}
	        if (ip == null) {
	        	try {
	        		ip = generalServices.createIp(address);
	        	} catch (final UnknownHostException ex) {
	        		log.error(ex);
	        	}
	        }
	        if (ip != null && ip.isWatch()) log.info("TRACE: watch ip;process binary query;" + address.toString() + ";");

	        final String [] fields = query.split("§");
	        final String uuid = fields[0];
	        final User user = generalServices.getUserByUuid(uuid);
	        final String username = user.getUsername();
	        if (ip != null && ip.isWatch()) log.info("TRACE: watch ip;process binary query w/ valid username;" + username + ";" + address.toString() + ";");
	        if (user.isWatch()) log.info("TRACE: watch user;process binary query;" + username + ";" + address.toString() + ";");
    		if (user.getType() == User.Type.BLOCKED) throw new GeneralException("binary query from blocked user (username=" + username + ")");
    		if ((user.getType() == User.Type.ANONYMOUS || user.getType() == User.Type.INITIALIZE) && ip != null && ip.getType() == Ip.Type.BLOCKED) throw new GeneralException("binary query from blocked ip (ip=" + ip.getIpString() + ")");

    		if (fields[1].equals("SocketData")) {

    			if (((user.getType() != User.Type.ANONYMOUS && user.getType() != User.Type.INITIALIZE) && user.isSlowDown()) ||
    					((user.getType() == User.Type.ANONYMOUS || user.getType() == User.Type.INITIALIZE) && ip != null && ip.getType() == Ip.Type.SLOWDOWN)) Thread.sleep(2000);
    			
    			final int port = new Integer(fields[2]);
		        final HttpProxy proxy = HttpProxyFactory.getHttpProxy(port);
		        if (proxy == null) {
		        	log.warn("bad proxy for user: " + uuid + " - port: " + port);
		        	reply.reply_string = VpnCode.SRV2CLT_BAD_USER + "§Error: bad proxy for this user";
		        	return reply;
		        } else if (!proxy.getUuid().equals(uuid)) {
		        	log.warn("bad user: uuid=" + uuid + " - proxy uuid=" + proxy.getUuid());
		        	reply.reply_string = VpnCode.SRV2CLT_BAD_USER + "§Error: bad user";
		        	return reply;
		        } else if (user.getType() == User.Type.ANONYMOUS && proxy.getRemotePort() == 22 && (System.currentTimeMillis() - proxy.getFirstUse() > 120000)) {
		        	reply.reply_string = "" + VpnCode.SRV2CLT_EXCEPTION + "§Error: anonymous SSH session expired after 2 minutes";
		        	return reply;
		        } else {
		        	try {
		        		reply.reply_data = proxy.receiveData();
		        		if (reply.reply_data == null) {
		    		        if (user.isWatch() || (ip != null && ip.isWatch()))
		    		        	log.info("TRACE: watch binary message;username=" + user.getUsername() + ";ip=" + address.toString() + ";port=" + port + ";msg=no reply data, closing connection");
		        			reply.reply_data = new byte [] { };
		        			HttpProxyFactory.removeHttpProxy(proxy.getLocalPort());
				        	reply.reply_string = "" + VpnCode.SRV2CLT_EXCEPTION + "§Error: EOF";
				        	return reply;
		        		} else {
	        				generalServices.addUserIn(user, reply.reply_data.length);
		        			if (ip != null) {
		        				generalServices.addIpIn(ip, reply.reply_data.length);
				        		if (user.isWatch() || ip.isWatch()) {
				        			log.info("TRACE: watch binary message;username=" + user.getUsername() + ";ip=" + address.toString() + ";port=" + port + ";msg=reply data length " + reply.reply_data.length);
				        			String content = "";
				        			for (final byte b : reply.reply_data)
				        				content += Integer.toHexString(128 + b) + " ";
				        			log.info("binary content:[ " + content + "]");
				        			log.info("ascii content:[" + java.nio.charset.StandardCharsets.US_ASCII.decode(ByteBuffer.wrap(reply.reply_data)).toString() + "]");
				        		}
		        			}
		        		}
		        	} catch (final IOException ex) {
	        			HttpProxyFactory.removeHttpProxy(proxy.getLocalPort());
			        	reply.reply_string = "" + VpnCode.SRV2CLT_EXCEPTION + "§Error: exception";
			        	return reply;
		        	}

		        	try {
		        		if (data.length != 0) {
		        			proxy.sendData(data);
	        				generalServices.addUserOut(user, data.length);
		        			if (ip != null) {
		        				generalServices.addIpOut(ip, data.length);
				        		if (user.isWatch() || ip.isWatch()) {
				        			log.info("TRACE: watch binary message;username=" + user.getUsername() + ";ip=" + address.toString() + ";port=" + port + ";msg=sending data length " + data.length);
				        			String content = "";
				        			for (final byte b : data)
				        				content += Integer.toHexString(128 + b) + " ";
				        			log.info("binary content:[ " + content + "]");
				        			log.info("ascii content:[" + java.nio.charset.StandardCharsets.US_ASCII.decode(ByteBuffer.wrap(data)).toString() + "]");
				        		}
		        			}
		        		}
		        	} catch (final IOException ex) {
			        	reply.reply_string = "" + VpnCode.SRV2CLT_OK + "§OK";
			        	return reply;
		        	}

		        	reply.reply_string = "" + VpnCode.SRV2CLT_OK + "§OK";
		        	return reply;
		        }
	        } else {
	        	reply.reply_string = "" + VpnCode.SRV2CLT_NO_SUCH_COMMAND + "§Error: no such command";
	        	return reply;
	        }

		} catch (final Exception ex) {
			ex.printStackTrace();
			log.error(ex);
			reply.reply_string = VpnCode.SRV2CLT_EXCEPTION + "§Error: exception";
			return reply;
		} finally {
	        // log.info("TRACE: SocketData binary message;msg=EXIT FUNCTION");
		}
	}

	@Override
	public void testLog() {
		final org.apache.commons.logging.Log log = org.apache.commons.logging.LogFactory.getLog(getClass());
		
		log.trace("testlog: TRACE");
        log.fatal("testlog: FATAL");
        log.error("testlog: ERROR");
        log.info("testlog: INFO");
        log.debug("testlog: DEBUG");
		log.warn("testlog: WARN");
	}
}
