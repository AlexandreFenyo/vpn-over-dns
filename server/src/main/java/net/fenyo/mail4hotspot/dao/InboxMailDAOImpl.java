// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dao;

import java.util.List;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import net.fenyo.mail4hotspot.domain.Account;
import net.fenyo.mail4hotspot.domain.InboxMail;
import org.springframework.stereotype.Component;

// @qualifier: http://static.springsource.org/spring/docs/3.0.x/spring-framework-reference/html/beans.html#beans-autowired-annotation
@Component
public class InboxMailDAOImpl implements InboxMailDAO {
	protected final org.apache.commons.logging.Log log = org.apache.commons.logging.LogFactory.getLog(getClass());

	@PersistenceContext
	private EntityManager entityManager;

	public void persist(final InboxMail transientInboxMail) {
		entityManager.persist(transientInboxMail);
	}

	public InboxMail getInboxMailByMsgId(final Account account, final String message_id) {
		return (InboxMail) entityManager.createQuery("select m from InboxMail m where m.messageId = ?1 and m.account = ?2").setParameter(1, message_id).setParameter(2, account).getSingleResult();
	}

	public long getUnreadMailsCount(final Account transientAccount) {
		return (Long) entityManager.createQuery("select count(m) from InboxMail m where m.headerOnly = false and m.unread = true and m.account = ?1").setParameter(1, transientAccount).getSingleResult();
	}

	public InboxMail getLatestUnreadMail(final Account transientAccount) {
		@SuppressWarnings("unchecked")
		final List<InboxMail> mails = entityManager.createQuery("select m from InboxMail m where m.headerOnly = false and m.unread = true and m.account = ?1 order by sessionid desc, id asc").setParameter(1, transientAccount).getResultList();
		return (mails.size() == 0) ? null : mails.get(0);
	}

	@SuppressWarnings("unchecked")
	public List<InboxMail> getOlderMessages(final Account account, final InboxMail inbox_mail) {
		return entityManager.createQuery("select m from InboxMail m where (m.sessionId < ?1 or (m.sessionId = ?1 and m.id >= ?2)) and m.account = ?3")
		.setParameter(1, inbox_mail.getSessionId())
		.setParameter(2, inbox_mail.getId())
		.setParameter(3, account)
		.getResultList();
	}

	public List<String> getMsgIdsFromAccount(final Account transientAccount) {
		@SuppressWarnings("unchecked")
		final List<String> results = (List<String>) entityManager.createQuery("select messageId from InboxMail mail where mail.account = ?1").setParameter(1, transientAccount).getResultList();
		return results;
	}

	public void removeMailsFromAccount(final Account account) {
		entityManager.createQuery("delete InboxMail mail where mail.account = ?1").setParameter(1, account).executeUpdate();
	}

	public void remove(final InboxMail inbox_mail) {
		entityManager.remove(inbox_mail);		
	}
}
