// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dao;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import net.fenyo.mail4hotspot.domain.Account;
import org.springframework.stereotype.Component;

// @qualifier: http://static.springsource.org/spring/docs/3.0.x/spring-framework-reference/html/beans.html#beans-autowired-annotation
@Component
public class AccountDAOImpl implements AccountDAO {
	protected final org.apache.commons.logging.Log log = org.apache.commons.logging.LogFactory.getLog(getClass());

	@PersistenceContext
	private EntityManager entityManager;

	public void persist(final Account transientAccount) {
		entityManager.persist(transientAccount);		
	}

	public void remove(final Account account) {
		entityManager.remove(account);		
	}

	public Account getAccount(final long id) {
		return (Account) entityManager.createQuery("select a from Account a where a.id = ?1").setParameter(1, id).getSingleResult();
	}
}
