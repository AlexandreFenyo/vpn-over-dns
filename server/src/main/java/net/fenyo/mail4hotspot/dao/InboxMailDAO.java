// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dao;

import java.util.List;

import net.fenyo.mail4hotspot.domain.Account;
import net.fenyo.mail4hotspot.domain.InboxMail;

public interface InboxMailDAO {
	public void persist(final InboxMail transientInboxMail);
	public List<String> getMsgIdsFromAccount(final Account transientAccount);
	public InboxMail getInboxMailByMsgId(final Account account, final String message_id);
	public InboxMail getLatestUnreadMail(final Account transientAccount);
	public long getUnreadMailsCount(final Account transientAccount);
	public void removeMailsFromAccount(final Account account);
	public List<InboxMail> getOlderMessages(final Account account, final InboxMail inbox_mail);
	public void remove(final InboxMail inbox_mail);
}
