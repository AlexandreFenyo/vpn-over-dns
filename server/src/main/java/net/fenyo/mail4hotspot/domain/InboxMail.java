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
// @Table(name = "inboxmail", schema = "public", indexes = { @Index(columnList = "id"), @Index(columnList = "sentdate"), @Index(columnList = "receiveddate"), @Index(columnList = "account_id") })
@Table(name = "inboxmail", schema = "public", indexes = { @Index(columnList = "sentdate"), @Index(columnList = "receiveddate"), @Index(columnList = "account_id") })
@SuppressWarnings("serial")
public class InboxMail implements java.io.Serializable {
	private long id;
	private String fromAddr;
	private String toAddr;
	private String ccAddr;
	private String subject;
	private String messageId;
	private String content;
	private java.util.Date sent_date;
	private java.util.Date received_date;
	private Account account;
	private boolean headerOnly;
	private long session_id;
	private boolean unread;

	public static final int MAX_CONTENT_LENGTH = 65535;
	public static final int MAX_ADDRESS_LENGTH = 4095;
	public static final int MAX_SUBJECT_LENGTH = 4095;
	public static final int MAX_MESG_ID_LENGTH = 255;

    public InboxMail() {}

    @Id
    @Column(name = "id", unique = true, nullable = false)
    @GeneratedValue(strategy=GenerationType.AUTO) 
    public long getId() {
        return id;
    }

    @SuppressWarnings("unused")
	private void setId(long id) {
        this.id = id;
    }

    @Column(unique = false, nullable = true, length = MAX_ADDRESS_LENGTH)
    public String getFromAddr() {
    	return fromAddr;
    }

    public void setFromAddr(final String fromAddr) {
    	this.fromAddr = fromAddr;
    }

    @Column(unique = false, nullable = true, length = MAX_ADDRESS_LENGTH)
    public String getToAddr() {
    	return toAddr;
    }

    public void setToAddr(final String toAddr) {
    	this.toAddr = toAddr;
    }

    @Column(unique = false, nullable = true, length = MAX_ADDRESS_LENGTH)
    public String getCcAddr() {
    	return ccAddr;
    }

    public void setCcAddr(final String ccAddr) {
    	this.ccAddr = ccAddr;
    }

    @Column(unique = false, nullable = true, length = MAX_SUBJECT_LENGTH)
    public String getSubject() {
    	return subject;
    }

    public void setSubject(final String subject) {
    	this.subject = subject;
    }

    // pas "unique" car deux Accounts peuvent collecter un même mail. Ce sont deux Accounts, donc ce mail est dupliqué dans deux InboxMails, avec le même MessageId
    @Column(unique = false, nullable = false, length = MAX_MESG_ID_LENGTH)
    public String getMessageId() {
    	return messageId;
    }

    public void setMessageId(final String messageId) {
    	this.messageId = messageId;
    }

    @Column(unique = false, nullable = true, length = MAX_CONTENT_LENGTH)
    public String getContent() {
    	return content;
    }

    public void setContent(final String content) {
    	this.content = content;
    }

    @Column(unique = false, nullable = true)
    public java.util.Date getSentDate() {
    	return sent_date;
    }

    public void setSentDate(final java.util.Date date) {
    	this.sent_date = date;
    }

    @Column(unique = false, nullable = true)
    public java.util.Date getReceivedDate() {
    	return received_date;
    }

    public void setReceivedDate(final java.util.Date date) {
    	this.received_date = date;
    }

    @Column(unique = false, nullable = false)
    public boolean getUnread() {
    	return unread;
    }

    public void setUnread(final boolean unread) {
    	this.unread = unread;
    }

    @Column(unique = false, nullable = false)
    public boolean getHeaderOnly() {
    	return headerOnly;
    }

    public void setHeaderOnly(final boolean headerOnly) {
    	this.headerOnly = headerOnly;
    }

    @Column(unique = false, nullable = false)
    public long getSessionId() {
    	return session_id;
    }

    public void setSessionId(final long session_id) {
    	this.session_id = session_id;
    }

    @ManyToOne
    public Account getAccount() {
    	return account;
    }

    public void setAccount(final Account account) {
    	this.account = account;
    }
}
