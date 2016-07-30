// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dao;

import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import net.fenyo.mail4hotspot.domain.Account;
import net.fenyo.mail4hotspot.domain.User;

import org.springframework.stereotype.Component;

// @qualifier: http://static.springsource.org/spring/docs/3.0.x/spring-framework-reference/html/beans.html#beans-autowired-annotation
@Component
public class UserDAOImpl implements UserDAO {
	protected final org.apache.commons.logging.Log log = org.apache.commons.logging.LogFactory.getLog(getClass());

	@PersistenceContext
	private EntityManager entityManager;

	public void persist(final User transientUser) {
		entityManager.persist(transientUser);		
	}

	public void remove(final User user) {
		entityManager.remove(user);		
	}

	@SuppressWarnings("unchecked")
	public List<User> getUserList() {
		return entityManager.createQuery("select u from User u order by id").setMaxResults(100).getResultList();
	}

	// http://docs.jboss.org/hibernate/stable/entitymanager/reference/en/html_single/
	// cf. 3.4.1. Executing queries
	public User getUser(final String username) {
		return (User) entityManager.createQuery("select u from User u where u.username = ?1").setParameter(1, username).getSingleResult();
	}

	// throws javax.persistence.NoResultException if no result
	public User getUserByUuid(final String uuid) {
		return (User) entityManager.createQuery("select u from User u where u.uuid = ?1").setParameter(1, uuid).getSingleResult();
	}

	public boolean uuidExists(final String uuid) {
		return entityManager.createQuery("select u from User u where u.uuid = ?1").setParameter(1, uuid).getResultList().size() != 0;
	}

	public User getUserByAccount(final Account transient_account) {
		return (User) entityManager.createQuery("select u from User u join u.accounts a where a.id = ?").setParameter(1, transient_account.getId()).getSingleResult();
	}
}
