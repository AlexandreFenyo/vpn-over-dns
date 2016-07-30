// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.domain;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Index;
import javax.persistence.ManyToOne;
import javax.persistence.Table;

@Entity
//@Table(name="outboxmail", schema="public", indexes = { @Index(columnList = "id"), @Index(columnList = "account_id") })
@Table(name="outboxmail", schema="public", indexes = { @Index(columnList = "account_id") })
@SuppressWarnings("serial")
public class OutboxMail implements java.io.Serializable {
	private long id;
	private String toAddr;
	private String ccAddr;
	private String subject;
	private String content;
	private Account account;

    public OutboxMail() {}

    @Id
    @Column(name="id", unique=true, nullable=false)
    @GeneratedValue(strategy=GenerationType.AUTO) 
    public long getId() {
        return id;
    }

    @SuppressWarnings("unused")
	private void setId(long id) {
        this.id = id;
    }

    @Column(unique=false, nullable=false)
    public String getToAddr() {
    	return toAddr;
    }

    public void setToAddr(final String toAddr) {
    	this.toAddr = toAddr;
    }

    @Column(unique=false, nullable=true)
    public String getCcAddr() {
    	return ccAddr;
    }

    public void setCcAddr(final String ccAddr) {
    	this.ccAddr = ccAddr;
    }

    @Column(unique=false, nullable=true)
    public String getSubject() {
    	return subject;
    }

    public void setSubject(final String subject) {
    	this.subject = subject;
    }

    @Column(unique=false, nullable=true)
    public String getContent() {
    	return content;
    }

    public void setContent(final String content) {
    	this.content = content;
    }

    @ManyToOne
    public Account getAccount() {
    	return account;
    }

    public void setAccount(final Account account) {
    	this.account = account;
    }
}
