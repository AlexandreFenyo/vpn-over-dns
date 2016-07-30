// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dao;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import net.fenyo.mail4hotspot.domain.*;

import org.springframework.stereotype.Component;
import java.net.*;

@Component
public class IpDAOImpl implements IpDAO {
	protected final org.apache.commons.logging.Log log = org.apache.commons.logging.LogFactory.getLog(getClass());

	@PersistenceContext
	private EntityManager entityManager;

	public void persist(final Ip transientIp) {
		entityManager.persist(transientIp);		
	}

	public void remove(final Ip ip) {
		entityManager.remove(ip);		
	}

	// throws javax.persistence.NoResultException if no result
	public Ip getIp(final String ipString) {
		return (Ip) entityManager.createQuery("select i from Ip i where i.ipString = ?1").setParameter(1, ipString).getSingleResult();
	}

	// throws javax.persistence.NoResultException if no result
	public Ip getIp(final Inet4Address inet4Address) {
		return getIp(inet4Address.toString().replaceFirst(".*/", ""));
	}
}
