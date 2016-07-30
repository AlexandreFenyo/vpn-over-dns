// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.domain;

import java.util.Collection;
import java.util.HashSet;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Enumerated;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Index;
import javax.persistence.OneToMany;
import javax.persistence.Table;
import javax.persistence.*;

@Entity
//@Table(name="user", schema="public", indexes = { @Index(columnList = "id"), @Index(columnList = "username"), @Index(columnList = "uuid") })
@Table(name="user", schema="public", indexes = { @Index(columnList = "username"), @Index(columnList = "uuid") })
@SuppressWarnings("serial")
public class User implements java.io.Serializable {
	private long id;
	private String username;
    private String password;
    private String uuid;
    private String message;

    private Collection<Account> accounts = new HashSet<Account>();

    public enum Type { NORMAL, TRIAL, BLOCKED, INITIALIZE, ANONYMOUS }
    public Type type;

	private long bytesIn = 0;
	private long bytesOut = 0;
    private boolean watch = false;
    private boolean slowdown = false;
    
    public User() {}

    @Id
    @Column(name="id", unique=true, nullable=false)
    @GeneratedValue(strategy=GenerationType.AUTO) 
    public long getId() {
        return id;
    }

    @SuppressWarnings("unused")
	private void setId(final long id) {
        this.id = id;
    }

    @Column(unique=true, nullable=false)
    public String getUsername() {
    	return username;
    }

    public void setUsername(final String username) {
    	this.username = username;
    }

    @Column(unique=false, nullable=false)
    public String getPassword() {
    	return password;
    }

    public void setPassword(final String password) {
    	this.password = password;
    }

    @Column(unique=true, nullable=false)
    public String getUuid() {
    	return uuid;
    }

    public void setUuid(final String uuid) {
    	this.uuid = uuid;
    }

    @Column(unique=false, nullable=true, length=1024)
    public String getMessage() {
    	return message;
    }

    public void setMessage(final String message) {
    	this.message = message;
    }

    // besoin de mettre un index via le @JoinTable car sinon:
    // - postgres dit "Adding a unique constraint will automatically create a unique btree index on the column or group of columns used in the constraint."
    // - et pgAdmin III permet de constater une contrainte d'unicité positionnée par hibernate sur la colonne accounts_id, mais pas sur user_id. Cette contrainte garantit le One de OneToMany.
    @OneToMany(cascade = javax.persistence.CascadeType.ALL, fetch = javax.persistence.FetchType.EAGER)
    @JoinTable(indexes = { @Index(columnList = "user_id"), @Index(columnList = "accounts_id") })
    public Collection<Account> getAccounts() {
    	return accounts;
    }

    public void setAccounts(Collection<Account> accounts) {
    	this.accounts = accounts;
    }

    @Enumerated(javax.persistence.EnumType.STRING)
    @Column(unique=false, nullable=false)
    public Type getType() {
    	return type;
    }

    public void setType(final Type type) {
    	this.type = type;
    }

    @Column(unique=false, nullable=false)
    public long getBytesIn() {
    	return bytesIn;
    }

    public void setBytesIn(final long bytesIn) {
    	this.bytesIn = bytesIn;
    }

    @Column(unique=false, nullable=false)
    public long getBytesOut() {
    	return bytesOut;
    }

    public void setBytesOut(final long bytesOut) {
    	this.bytesOut = bytesOut;
    }

    @Column(unique=false, nullable=false)
    public boolean isWatch() {
    	return watch;
    }

    public void setWatch(final boolean watch) {
    	this.watch = watch;
    }

    @Column(unique=false, nullable=false)
    public boolean isSlowDown() {
    	return slowdown;
    }

    public void setSlowDown(final boolean slowdown) {
    	this.slowdown = slowdown;
    }
}
