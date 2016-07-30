// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import javax.persistence.EntityManager;
import javax.persistence.NoResultException;
import javax.persistence.PersistenceContext;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Propagation;
import net.fenyo.mail4hotspot.dao.*;
import net.fenyo.mail4hotspot.domain.*;
import net.fenyo.mail4hotspot.domain.Account.Provider;
import net.fenyo.mail4hotspot.tools.GeneralException;

import java.net.*;
import java.net.*;

// Only external method calls can be intercepted (as explained in chapter 6 of the reference guide) so marking private methods with @Transactional doesn't do anything.
// http://stackoverflow.com/questions/3423972/spring-transaction-method-call-by-the-method-within-the-same-class-does-not-wo

// je fais un flush avant un detach car : JSR-317 : "Unflushed changes made to the entity if any (including removal of the entity), will not be synchronized to the database."

@Service("generalServices")
@Transactional(propagation = Propagation.REQUIRED, readOnly = true)
public class GeneralServicesImpl implements GeneralServices {
	protected final org.apache.commons.logging.Log log = org.apache.commons.logging.LogFactory.getLog(getClass());

	// Uniquement pour les tests, ne pas l'utiliser pour autre chose
	@PersistenceContext
	private EntityManager entityManager;

	@Autowired
	private UserDAO userDAO;

	@Autowired
	private AccountDAO accountDAO;

	@Autowired
	private InboxMailDAO inboxMailDAO;

	@Autowired
	private OutboxMailDAO outboxMailDAO;

	@Autowired
	private IpDAO ipDAO;

	private boolean BLOCKDBUPDATES;

	private String generateUuid() {
		String uuid;
		int cpt = 0;
		do {
			uuid = new Integer(Math.abs(new Random().nextInt())).toString();
			if (cpt++ == 100) {
				log.error("can not generate UUID");
				return null;
			}
		} while (userDAO.uuidExists(uuid));
		return uuid;
	}

	public String getBlockDbUpdates() {
		return BLOCKDBUPDATES ? "true" : "false";
	}

	public void setBlockDbUpdates(final String blockdbupdates) {
		BLOCKDBUPDATES = blockdbupdates.toLowerCase().equals("true") ? true : false;
	}

	@Transactional(readOnly = true)
	public User getUserByAccount(final Account transient_account) {
		final User user = userDAO.getUserByAccount(transient_account);
		entityManager.detach(user);
		return user;
	}

	@Transactional(readOnly = false)
	public void sendInternalMailByAccount(final Account transient_account, final String subject, final String message) {
		if (transient_account == null) {
			log.error("transient_account is null");
			return;
		}

		final Account account = accountDAO.getAccount(transient_account.getId());
		
		final InboxMail inboxMail = new InboxMail();
		inboxMail.setAccount(account);
		inboxMail.setUnread(true);
		inboxMail.setHeaderOnly(false);
		inboxMail.setMessageId("<VPN-over-DNS-" + System.currentTimeMillis() + "-" + new Double(Math.random() * 100000).intValue() + ">");
		inboxMail.setFromAddr("support@vpnoverdns.com");
		inboxMail.setToAddr(account.getEmail());
		inboxMail.setCcAddr(null);
		inboxMail.setSubject(subject);
		inboxMail.setSentDate(new java.util.Date());
		inboxMail.setReceivedDate(new java.util.Date());
		inboxMail.setContent(message);
		inboxMailDAO.persist(inboxMail);
		entityManager.flush();
		inboxMail.setSessionId(inboxMail.getId());
		entityManager.flush();
		entityManager.detach(inboxMail);
		entityManager.detach(account);
	}

	@Transactional(readOnly = false)
	public String createUser(final String username, final String password) throws GeneralException {
		if (BLOCKDBUPDATES) throw new GeneralException("blockedbupdates: can not create user");
		
		final User transientUser = new User();
		transientUser.setUsername(username);
		transientUser.setPassword(password);
		transientUser.setType(User.Type.NORMAL);
		transientUser.setUuid(generateUuid());

		final Account transientAccount = new Account();
		transientAccount.setUsername("");
		transientAccount.setEmail("");
		transientAccount.setPassword("");
		transientAccount.setProvider(Provider.NOT_INITIALIZED);
		transientAccount.setProviderError("");

		userDAO.persist(transientUser);
		accountDAO.persist(transientAccount);

		transientUser.getAccounts().add(transientAccount);

		return transientUser.getUuid();
	}

	@Transactional(readOnly = false)
	public void createInitialIps() throws UnknownHostException {
//		final Ip transientIp = new Ip();
//		transientIp.setIpString("127.0.0.1");
//		transientIp.setWatch(true);
//		ipDAO.persist(transientIp);

//		final Ip transientIp2 = new Ip();
//		transientIp2.setIpString("192.168.1.14");
//		transientIp2.setWatch(true);
//		ipDAO.persist(transientIp2);
	}

	@Transactional(readOnly = false)
	public void createInitialUsers() {
		// user "initialize"
		final User transientUser = new User();
		transientUser.setUsername("initialize");
		transientUser.setPassword("initialize");
		transientUser.setType(User.Type.INITIALIZE);
		transientUser.setUuid("initiali");

		final Account transientAccount = new Account();
		transientAccount.setUsername("");
		transientAccount.setEmail("");
		transientAccount.setPassword("");
		transientAccount.setProvider(Provider.NOT_INITIALIZED);
		transientAccount.setProviderError("");

		userDAO.persist(transientUser);
		accountDAO.persist(transientAccount);

		transientUser.getAccounts().add(transientAccount);

		// user "anonymous"
		final User transientUser2 = new User();
		transientUser2.setUsername("anonymous");
		transientUser2.setPassword("anonymous");
		transientUser2.setType(User.Type.ANONYMOUS);
		transientUser2.setUuid("anonymou");

		final Account transientAccount2 = new Account();
		transientAccount2.setUsername("");
		transientAccount2.setEmail("");
		transientAccount2.setPassword("");
		transientAccount2.setProvider(Provider.NOT_INITIALIZED);
		transientAccount2.setProviderError("");

		userDAO.persist(transientUser2);
		accountDAO.persist(transientAccount2);

		transientUser2.getAccounts().add(transientAccount2);

		// user "trial"
		final User transientUser3 = new User();
		transientUser3.setUsername("trial");
		transientUser3.setPassword("PASSWORD");
		transientUser3.setType(User.Type.TRIAL);
		transientUser3.setUuid("trial000");

		final Account transientAccount3 = new Account();
		transientAccount3.setUsername("");
		transientAccount3.setEmail("");
		transientAccount3.setPassword("");
		transientAccount3.setProvider(Provider.NOT_INITIALIZED);
		transientAccount3.setProviderError("");

		userDAO.persist(transientUser3);
		accountDAO.persist(transientAccount3);

		transientUser3.getAccounts().add(transientAccount3);

		// user "blocked"
		final User transientUser4 = new User();
		transientUser4.setUsername("blocked");
		transientUser4.setPassword("PASSWORD");
		transientUser4.setType(User.Type.BLOCKED);
		transientUser4.setUuid("blocked0");

		final Account transientAccount4 = new Account();
		transientAccount4.setUsername("");
		transientAccount4.setEmail("");
		transientAccount4.setPassword("");
		transientAccount4.setProvider(Provider.NOT_INITIALIZED);
		transientAccount4.setProviderError("");

		userDAO.persist(transientUser4);
		accountDAO.persist(transientAccount4);

		transientUser4.getAccounts().add(transientAccount4);

		// user "fenyoa"
		final User transientUserFenyo = new User();
		transientUserFenyo.setUsername("fenyoa");
		transientUserFenyo.setPassword("PASSWORD");
		transientUserFenyo.setUuid("7777777");
		transientUserFenyo.setType(User.Type.NORMAL);
		//transientUserFenyo.setWatch(true);
		userDAO.persist(transientUserFenyo);

		Account transientAccountFenyo;
		transientAccountFenyo = new Account();
		transientAccountFenyo.setUsername("alexandre.fenyo@gmail.com");
		transientAccountFenyo.setEmail("alexandre.fenyo@gmail.com");
		transientAccountFenyo.setPassword("PASSWORD");
		transientAccountFenyo.setProvider(Account.Provider.GMAIL);
		transientAccountFenyo.setProviderError("");
		accountDAO.persist(transientAccountFenyo);
		transientUserFenyo.getAccounts().add(transientAccountFenyo);
	}

	// return detached entities
	@Transactional(readOnly = true)
	public List<User> getUserList() {
		final List<User> user_list = userDAO.getUserList();
		for (User user : user_list) entityManager.detach(user);
		return user_list;
	}

	// return detached entities
	@Transactional(readOnly = true)
	public UserAndAccounts getUserAndAccounts(final String username) {
		final UserAndAccounts userAndAccounts = new UserAndAccounts();
		final User user = userDAO.getUser(username);
		userAndAccounts.user = user;
		userAndAccounts.accounts = user.getAccounts();
		entityManager.detach(userAndAccounts.user);
		// après migratino vers hibernate 4.x: le detach qui suit et est commenté génère une exception. C'est normal car on a mis CascadeType.ALL sur l'association entre user et accounts.
		// Ce bug aurait dû apparaître avant et lever une exception.
		// entityManager.detach(userAndAccounts.accounts);
		return userAndAccounts;
	}

	// return detached entities : très important à ne pas changer, car par ex dans GeneralServices.processQueryFromClient(),
	// on s'appuie sur le fait que si on a pu à un instant accéder à userAndAccounts.user.getId(), alors on n'aura pas d'exception par la suite en y réaccédant. Si on avait une exception par la suite,
	// on aurait alors une entrée permanente dans userIdsProcessing, donc un utilisateur qui n'aurait plus la possibilité d'accéder à ses nouveaux mails
	@Transactional(readOnly = true)
	public UserAndAccounts getUserAndAccountsByUuid(final String uuid) {
		final UserAndAccounts userAndAccounts = new UserAndAccounts();
		final User user = userDAO.getUserByUuid(uuid);
		userAndAccounts.user = user;
		userAndAccounts.accounts = user.getAccounts();
		entityManager.detach(userAndAccounts.user);
		// entityManager.detach(userAndAccounts.accounts);
		return userAndAccounts;
	}

	// return detached entity
	@Transactional(readOnly = true)
	public User getUser(final String username) {
		final User user = userDAO.getUser(username);
		entityManager.detach(user);
		return user;
	}

	// return detached entity
	@Transactional(readOnly = true)
	public User getUserByUuid(final String uuid) {
		final User user = userDAO.getUserByUuid(uuid);
		entityManager.detach(user);
		return user;
	}

	// return detached entity
	@Transactional(readOnly = false)
	public Ip createIp(final String ipString) throws UnknownHostException {
		final Ip transientIp = new Ip();
		transientIp.setIpString(ipString);
		ipDAO.persist(transientIp);
		entityManager.flush();
		entityManager.detach(transientIp);
		return transientIp;
	}

	// return detached entity
	@Transactional(readOnly = false)
	public Ip createIp(final Inet4Address inet4Address) throws UnknownHostException {
		final Ip transientIp = new Ip();
		transientIp.setIpString(inet4Address.toString().replaceFirst(".*/", ""));
		ipDAO.persist(transientIp);
		entityManager.flush();
		entityManager.detach(transientIp);
		return transientIp;
	}
	
	// return detached entity
	@Transactional(readOnly = true)
	public Ip getIp(final String ipString) {
		final Ip ip = ipDAO.getIp(ipString);
		entityManager.detach(ip);
		return ip;
	}

	// return detached entity
	@Transactional(readOnly = true)
	public Ip getIp(final Inet4Address inet4Address) {
		final Ip ip = ipDAO.getIp(inet4Address);
		entityManager.detach(ip);
		return ip;
	}

	@Transactional(readOnly = false)
	public void addIpIn(final Ip ipTransient, final long len) {
		final Ip ip = ipDAO.getIp(ipTransient.getIpString());
		ip.setBytesIn(ip.getBytesIn() + len);
	}

	@Transactional(readOnly = false)
	public void addIpOut(final Ip ipTransient, final long len) {
		final Ip ip = ipDAO.getIp(ipTransient.getIpString());
		ip.setBytesOut(ip.getBytesOut() + len);
	}

	@Transactional(readOnly = false)
	public void addUserIn(final User userTransient, final long len) {
		final User user = userDAO.getUser(userTransient.getUsername());
		user.setBytesIn(user.getBytesIn() + len);
	}

	@Transactional(readOnly = false)
	public void addUserOut(final User userTransient, final long len) {
		final User user = userDAO.getUser(userTransient.getUsername());
		user.setBytesOut(user.getBytesOut() + len);
	}

	// return detached entity
	@Transactional(readOnly = true)
	public Account getFirstAccount(final String username) {
		final User user = (User) entityManager.createQuery("select u from User u where u.username = ?1").setParameter(1, username).getSingleResult();
		if (user.getAccounts().isEmpty() == true) return null;
		else {
			final Account account = user.getAccounts().iterator().next();
			entityManager.detach(account);
			return account;
		}
	}

	@Transactional(readOnly = false)
	public int setUser(final String username, final String password, final Account.Provider provider,
			final String provider_email, final String provider_login, final String provider_password) throws GeneralException {
		if (BLOCKDBUPDATES) throw new GeneralException("blockedbupdates: can not set user parameters");

		final User user = (User) entityManager.createQuery("select u from User u where u.username = ?1").setParameter(1, username).getSingleResult();
		if (user.getPassword().equals(password) == false) return 1;
		if (user.getAccounts().isEmpty() == true) {
			final Account transientAccount = new Account();
			transientAccount.setProvider(provider);
			transientAccount.setEmail(provider_email);
			transientAccount.setUsername(provider_login);
			transientAccount.setPassword(provider_password);
			transientAccount.setProviderError("");
			accountDAO.persist(transientAccount);
			// transientAccount is no longer transient
			user.getAccounts().add(transientAccount);
		} else {
			final Account account = user.getAccounts().iterator().next();
			account.setProvider(provider);
			account.setEmail(provider_email);
			account.setUsername(provider_login);
			account.setPassword(provider_password);
			account.setProviderError("");
		}
		return 0;
	}

	@Transactional(readOnly = false)
	public void createAccount(final String user_username, final String username,
			final String email, final String password, final Account.Provider provider) throws GeneralException {
		if (BLOCKDBUPDATES) throw new GeneralException("blockedbupdates: can not create account");

		final User user = userDAO.getUser(user_username);

		final Account transientAccount = new Account();
		transientAccount.setUsername(username);
		transientAccount.setEmail(email);
		transientAccount.setPassword(password);
		transientAccount.setProvider(provider);
		transientAccount.setProviderError("");
		accountDAO.persist(transientAccount);
		// transientAccount is no longer transient
		user.getAccounts().add(transientAccount);
	}

	@Transactional(readOnly = false)
	public void dropAccount(final String username, final long id) throws GeneralException {
		if (BLOCKDBUPDATES) throw new GeneralException("blockedbupdates: can not drop account");

		final User user = userDAO.getUser(username);
		Account myAccount = null;
		for (Account account : user.getAccounts()) {
			if (account.getId() == id) {
				myAccount = account;
			}
		}
		inboxMailDAO.removeMailsFromAccount(myAccount);
		outboxMailDAO.removeMailsFromAccount(myAccount);
		user.getAccounts().remove(myAccount);
		accountDAO.remove(myAccount);
	}

	@Transactional(readOnly = false)
	public void dropUser(final String username) throws GeneralException {
		if (BLOCKDBUPDATES) throw new GeneralException("blockedbupdates: can not drop user");

		final User user = userDAO.getUser(username);
		for (Account account : user.getAccounts()) {
			account.setInboxMailMark(null);
			entityManager.flush();
			inboxMailDAO.removeMailsFromAccount(account);
			outboxMailDAO.removeMailsFromAccount(account);
		}
		userDAO.remove(user);
	}

	@Transactional(readOnly = true)
	public List<String> getMsgIds(final Account transientAccount) {
		return inboxMailDAO.getMsgIdsFromAccount(transientAccount);
	}

	@Transactional(readOnly = false)
	public long getUnreadMailsCount(final Account transientAccount) {
		return inboxMailDAO.getUnreadMailsCount(transientAccount);
	}

	@Transactional(readOnly = false)
	public InboxMail getLatestUnreadMail(final Account transientAccount) {
		final InboxMail mail = inboxMailDAO.getLatestUnreadMail(transientAccount);
		if (mail != null) {
			mail.setUnread(false);
			entityManager.flush();
			entityManager.detach(mail);
		}
		return mail;
	}

	@Transactional(readOnly = false)
	public void removeSentMail(final OutboxMail mail) {
		outboxMailDAO.removeMail(mail);
	}

	@Transactional(readOnly = true)
	public List<AccountAndOutboxMail> getSentMails() {
		List<AccountAndOutboxMail> accounts_and_mails = new ArrayList<AccountAndOutboxMail>();
		final List<OutboxMail> mails = outboxMailDAO.getSentMails();
		entityManager.flush();
		for (OutboxMail mail : mails) {
			final AccountAndOutboxMail account_and_mail = new AccountAndOutboxMail();
			account_and_mail.mail = mail;
			account_and_mail.account = mail.getAccount();
			entityManager.detach(account_and_mail.mail);
			entityManager.detach(account_and_mail.account);
			accounts_and_mails.add(account_and_mail);
		}
		return accounts_and_mails;
	}

	@Transactional(readOnly = true)
	public AccountAndOutboxMail getLatestSentMail() {
		final AccountAndOutboxMail account_and_mail = new AccountAndOutboxMail();
		account_and_mail.mail = outboxMailDAO.getLatestSentMail();
		account_and_mail.account = account_and_mail.mail.getAccount();
		entityManager.flush();
		entityManager.detach(account_and_mail.mail);
		entityManager.detach(account_and_mail.account);
		return account_and_mail;
	}

	@Transactional(readOnly = false)
	public void saveOutboxMail(final Account transientAccount, final OutboxMail transientOutboxMail) {
		final Account account = accountDAO.getAccount(transientAccount.getId());
		transientOutboxMail.setAccount(account);

		outboxMailDAO.persist(transientOutboxMail);

		entityManager.flush();
		entityManager.detach(transientOutboxMail);
	}

	private long _saveInboxMail(final Account transientAccount, final InboxMail transientInboxMail, Long session_id, boolean mark) {
		final Account account = accountDAO.getAccount(transientAccount.getId());
		transientInboxMail.setAccount(account);

		inboxMailDAO.persist(transientInboxMail);
		if (session_id != null) transientInboxMail.setSessionId(session_id);
		else transientInboxMail.setSessionId(transientInboxMail.getId());
		if (mark) account.setInboxMailMark(transientInboxMail);
		// interdit : JSR-317 : "Unflushed changes made to the entity if any (including removal of the entity), will not be synchronized to the database."
		// entityManager.detach(transientInboxMail);

		entityManager.flush();
		entityManager.detach(transientInboxMail);

		if (session_id == null) session_id = transientInboxMail.getId();
		return session_id;
	}

	@Transactional(readOnly = false)
	public long saveInboxMail(final Account transientAccount, final InboxMail transientInboxMail, Long session_id) {
		return _saveInboxMail(transientAccount, transientInboxMail, session_id, false);
	}

	@Transactional(readOnly = false)
	public long saveInboxMailMark(final Account transientAccount, final InboxMail transientInboxMail, Long session_id) {
		return _saveInboxMail(transientAccount, transientInboxMail, session_id, true);
	}

	@Transactional(readOnly = true)
	public String getMessageIdMark(final Account transientAccount) {
		final Account account = accountDAO.getAccount(transientAccount.getId());
		if (account.getInboxMailMark() == null) return null;
		else return account.getInboxMailMark().getMessageId();
	}

	@Transactional(readOnly = false)
	public void removeOldMessages(final Account transientAccount) {
		final Account account = accountDAO.getAccount(transientAccount.getId());
		if (account.getInboxMailMark() == null) return;
		final InboxMail mark = account.getInboxMailMark();
		final long mark_id = mark.getId();
		final List<InboxMail> inbox_mails = inboxMailDAO.getOlderMessages(account, mark);
		for (InboxMail mail : inbox_mails)
			// suppression des mails plus vieux que la marque et récupérés il y a plus de 7 jours
			if (mail.getId() != mark_id && (System.currentTimeMillis() - mail.getReceivedDate().getTime()) > 7 * 86400 * 1000)
				inboxMailDAO.remove(mail);
	}

	// transformer le type de retour en Set, pour utiliser un HashSet, pour plus de performances
	@Transactional(readOnly = true)
	public List<String> getMessageIdsOlderThanMark(final Account transientAccount) {
		final List<String> msgids = new ArrayList<String>();
		final Account account = accountDAO.getAccount(transientAccount.getId());
		if (account.getInboxMailMark() == null) return null;
		final List<InboxMail> inbox_mails = inboxMailDAO.getOlderMessages(account, account.getInboxMailMark());
		for (InboxMail mail : inbox_mails) msgids.add(mail.getMessageId());
		return msgids;
	}

	@Transactional(readOnly = false)
	public void saveMark(final Account transientAccount, final String message_id) {
		final Account account = accountDAO.getAccount(transientAccount.getId());
		final InboxMail inboxMail = inboxMailDAO.getInboxMailByMsgId(account, message_id);
		account.setInboxMailMark(inboxMail);
	}

	@Transactional(readOnly = false)
	public void saveProviderError(final Account transientAccount, final String provider_error) {
		final Account account = accountDAO.getAccount(transientAccount.getId());
		account.setProviderError(provider_error);
	}

	@Transactional(readOnly = false)
	public String getLastProviderError(final Account transientAccount) {
		final Account account = accountDAO.getAccount(transientAccount.getId());
		final String provider_error = account.getProviderError();
		account.setProviderError("");
		return provider_error;
	}

	@Transactional(readOnly = false)
	public void createDefault() {
		// GMail
		
		final User transientUser = new User();
		transientUser.setUsername("fenyog");
		transientUser.setPassword("PASSWORD");
		//transientUser.setUuid(generateUuid());
		transientUser.setUuid("8888888");
		transientUser.setType(User.Type.NORMAL);
		userDAO.persist(transientUser);

		Account transientAccount;
		transientAccount = new Account();
		transientAccount.setUsername("alexandre.fenyo@gmail.com");
		transientAccount.setEmail("alexandre.fenyo@gmail.com");
		transientAccount.setPassword("PASSWORD");
		transientAccount.setProviderError("");
		transientAccount.setProvider(Account.Provider.GMAIL);
		accountDAO.persist(transientAccount);
		transientUser.getAccounts().add(transientAccount);

		// Yahoo! Mail

		final User transientUser2 = new User();
		transientUser2.setUsername("fenyoy");
		transientUser2.setPassword("PASSWORD");
		transientUser2.setUuid("9999999");
		transientUser2.setType(User.Type.NORMAL);
		userDAO.persist(transientUser2);

		Account transientAccount2;
		transientAccount2 = new Account();
		transientAccount2.setUsername("alexandre.fenyo@yahoo.fr");
		transientAccount2.setEmail("alexandre.fenyo@yahoo.fr");
		transientAccount2.setPassword("PASSWORD");
		transientAccount2.setProviderError("");
		transientAccount2.setProvider(Account.Provider.YAHOO);
		accountDAO.persist(transientAccount2);
		transientUser2.getAccounts().add(transientAccount2);

		// HotMail

		final User transientUser3 = new User();
		transientUser3.setUsername("fenyoh");
		transientUser3.setPassword("PASSWORD");
		transientUser3.setUuid("1111111");
		transientUser3.setType(User.Type.NORMAL);
		userDAO.persist(transientUser3);

		Account transientAccount3;
		transientAccount3 = new Account();
		transientAccount3.setUsername("fenyoa@hotmail.com");
		transientAccount3.setEmail("fenyoa@hotmail.com");
		transientAccount3.setPassword("PASSWORD");
		transientAccount3.setProvider(Account.Provider.HOTMAIL);
		transientAccount3.setProviderError("");
		accountDAO.persist(transientAccount3);
		transientUser3.getAccounts().add(transientAccount3);

//		transientAccount = new Account();
//		transientAccount.setUsername("thisisatestforalex@aol.fr");
//		transientAccount.setEmail("thisisatestforalex@aol.fr");
//		transientAccount.setPassword("PASSWORD");
//		transientAccount.setProvider(Account.Provider.AOL);
//		accountDAO.persist(transientAccount);
//		transientUser.getAccounts().add(transientAccount);

		// Opera Mail
		
		final User transientUser4 = new User();
		transientUser4.setUsername("fenyoo");
		transientUser4.setPassword("PASSWORD");
		transientUser4.setUuid("2222222");
		transientUser4.setType(User.Type.NORMAL);
		userDAO.persist(transientUser4);

		Account transientAccount4;
		transientAccount4 = new Account();
		transientAccount4.setUsername("map_map@imap.cc");
		transientAccount4.setEmail("map_map@imap.cc");
		transientAccount4.setPassword("PASSWORD");
		transientAccount4.setProvider(Account.Provider.OPERAMAIL);
		transientAccount4.setProviderError("");
		accountDAO.persist(transientAccount4);
		transientUser4.getAccounts().add(transientAccount4);


	}
}
