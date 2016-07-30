// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dao;

import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import net.fenyo.mail4hotspot.domain.Account;
import net.fenyo.mail4hotspot.domain.OutboxMail;

import org.springframework.stereotype.Component;

// @qualifier: http://static.springsource.org/spring/docs/3.0.x/spring-framework-reference/html/beans.html#beans-autowired-annotation
@Component
public class OutboxMailDAOImpl implements OutboxMailDAO {
	protected final org.apache.commons.logging.Log log = org.apache.commons.logging.LogFactory.getLog(getClass());

	@PersistenceContext
	private EntityManager entityManager;

	public OutboxMail getLatestSentMail() {
		@SuppressWarnings("unchecked")
		final List<OutboxMail> mails = entityManager.createQuery("select m from OutboxMail m order by id desc").getResultList();
		return (mails.size() == 0) ? null : mails.get(0);
	}

	@SuppressWarnings("unchecked")
	public List<OutboxMail> getSentMails() {
		return entityManager.createQuery("select m from OutboxMail m order by id desc").getResultList();
	}

	public void persist(final OutboxMail transientOutboxMail) {
		entityManager.persist(transientOutboxMail);		
	}

	public void removeMailsFromAccount(final Account account) {
		entityManager.createQuery("delete OutboxMail mail where mail.account = ?1").setParameter(1, account).executeUpdate();
	}

	public void removeMail(final OutboxMail transientOutboxMail) {
		entityManager.createQuery("delete OutboxMail mail where mail.id = ?1").setParameter(1, transientOutboxMail.getId()).executeUpdate();
	}
}
