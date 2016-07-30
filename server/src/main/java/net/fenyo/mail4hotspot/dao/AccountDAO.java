// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dao;

import net.fenyo.mail4hotspot.domain.Account;

public interface AccountDAO {
	public void persist(final Account transientAccount);
	public void remove(final Account account);
	public Account getAccount(final long id);
}
