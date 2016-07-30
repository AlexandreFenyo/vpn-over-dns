// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dao;

import java.util.List;

import net.fenyo.mail4hotspot.domain.Account;
import net.fenyo.mail4hotspot.domain.OutboxMail;

public interface OutboxMailDAO {
	public OutboxMail getLatestSentMail();
	public List<OutboxMail> getSentMails();
	public void persist(final OutboxMail transientOutboxMail);
	public void removeMailsFromAccount(final Account account);
	public void removeMail(final OutboxMail transientOutboxMail);
}
