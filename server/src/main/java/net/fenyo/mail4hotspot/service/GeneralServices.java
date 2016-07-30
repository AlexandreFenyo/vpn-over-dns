// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service;

import java.net.UnknownHostException;
import java.util.Collection;
import java.util.List;
import net.fenyo.mail4hotspot.domain.*;
import net.fenyo.mail4hotspot.tools.GeneralException;
import net.fenyo.mail4hotspot.dao.*;
import java.net.*;

public interface GeneralServices {
	public class UserAndAccounts {
		public User user;
		public Collection<Account> accounts;
	}

	// public void createRandomAccount(Account transientAccount);
	public String createUser(final String username, final String password) throws GeneralException;
	public String getBlockDbUpdates();
	public void setBlockDbUpdates(final String blockdbupdates);
	public void createInitialIps() throws UnknownHostException;
	public void createInitialUsers();
	public UserAndAccounts getUserAndAccounts(final String username);
	public UserAndAccounts getUserAndAccountsByUuid(final String uuid);
	public long getUnreadMailsCount(final Account transientAccount);
	public String getLastProviderError(final Account transientAccount);
	public AccountAndOutboxMail getLatestSentMail();
	public void removeSentMail(final OutboxMail mail);
	public List<AccountAndOutboxMail> getSentMails();
	public InboxMail getLatestUnreadMail(final Account transientAccount);
	public void saveOutboxMail(final Account transientAccount, final OutboxMail transientOutboxMail);
	public long saveInboxMail(final Account transientAccount, final InboxMail transientInboxMail, Long session_id);
	public long saveInboxMailMark(final Account transientAccount, final InboxMail transientInboxMail, Long session_id);
	public void saveMark(final Account transientAccount, final String msgid);
	public void saveProviderError(final Account transientAccount, final String error);
	public String getMessageIdMark(final Account transientAccount);
	public User getUserByAccount(final Account transient_account);
	public void sendInternalMailByAccount(final Account transient_account, final String subject, final String message);
	public void removeOldMessages(final Account transientAccount);
	public List<String> getMessageIdsOlderThanMark(final Account transientAccount);
	public List<String> getMsgIds(final Account transientAccount);
	public List<User> getUserList();
	public User getUser(final String username);
	public User getUserByUuid(final String uuid);
	public Ip createIp(final String ipString) throws UnknownHostException;
	public Ip createIp(final Inet4Address inet4Address) throws UnknownHostException;
	public Ip getIp(final String ipString);
	public Ip getIp(final Inet4Address inet4Address);
	public void addIpIn(final Ip ipTransient, final long len);
	public void addIpOut(final Ip ipTransient, final long len);
	public void addUserIn(final User userTransient, final long len);
	public void addUserOut(final User userTransient, final long len);
	public Account getFirstAccount(final String username);
	public void createAccount(final String user_username, final String username, final String email, final String password, final Account.Provider provider) throws GeneralException;
	public void dropAccount(final String username, final long id) throws GeneralException;
	public void dropUser(final String username) throws GeneralException;
	public void createDefault();
	public int setUser(final String username, final String password, final Account.Provider provider, final String provider_email, final String provider_login, final String provider_password) throws GeneralException;
}
