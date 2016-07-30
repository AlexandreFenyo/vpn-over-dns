// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dao;

import java.util.List;

import net.fenyo.mail4hotspot.domain.Account;
import net.fenyo.mail4hotspot.domain.User;

public interface UserDAO {
	public void persist(final User transientUser);
	public void remove(final User user);
	public List<User> getUserList();
	public User getUser(final String username);
	public User getUserByUuid(final String uuid);
	public boolean uuidExists(final String uuid);
	public User getUserByAccount(final Account transient_account);
}
