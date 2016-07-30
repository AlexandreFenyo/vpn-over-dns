// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.domain;

import javax.persistence.*;

// https://docs.oracle.com/javaee/7/api/javax/persistence/Index.html:
// Note that it is not necessary to specify an index for a primary key, as the primary key index will be created automatically.
// pourtant, d'après pgAdmin III, ce n'est pas fait, il faut forcer avec un @Index même sur la clé primaire
// Il y a un gars qui dit encore plus "primary key and unique cosntraints are automatically indexed in database"
// Confirmé par doc postgres : Adding a unique constraint will automatically create a unique btree index on the column or group of columns used in the constraint.
// Pourtant, on la voit pas avec pgAdmin III

@Entity
// @Table(name = "account", schema = "public", indexes = { @Index(columnList = "id"), @Index(columnList = "email") })
@Table(name = "account", schema = "public", indexes = { @Index(columnList = "email") })
@SuppressWarnings("serial")
public class Account implements java.io.Serializable {
	private long id;
	private String username;
	private String email;
	private String password;
	private InboxMail inbox_mail_mark;
	private String provider_error;

    public enum Provider { GMAIL, YAHOO, HOTMAIL, AOL, OPERAMAIL, TESTPOPRSI, TESTPOPLOCALHOST, TESTIMAPRSI, TESTIMAPLOCALHOST, NOT_INITIALIZED }
	private Provider provider;

    public Account() {}

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

    @OneToOne
    public InboxMail getInboxMailMark() {
    	return inbox_mail_mark;
    }

    public void setInboxMailMark(final InboxMail inbox_mail_mark) {
    	this.inbox_mail_mark = inbox_mail_mark;
    }

    @Column(unique=false, nullable=false)
    public String getProviderError() {
    	return provider_error;
    }

    public void setProviderError(final String provider_error) {
    	this.provider_error = provider_error;
    }

    @Column(unique=false, nullable=false)
    public String getUsername() {
    	return username;
    }

    public void setUsername(final String username) {
    	this.username = username;
    }

    @Column(unique=false, nullable=false)
    public String getEmail() {
    	return email;
    }

    public void setEmail(final String email) {
    	this.email = email;
    }

    @Column(unique=false, nullable=false)
    public String getPassword() {
    	return password;
    }

    public void setPassword(final String password) {
    	this.password = password;
    }

    @Enumerated(javax.persistence.EnumType.STRING)
    @Column(unique=false, nullable=false)
    public Provider getProvider() {
    	return provider;
    }

    public void setProvider(final Provider provider) {
    	this.provider = provider;
    }

    /*
     * Avec un OneToMany, un add sur la collection conduit à tout recharger !
     * => jamais de OneToMany pour une collection de taille importante
     * cf la FAQ hibernate : "Why does Hibernate always initialize a collection when I only want to add or remove an element?"
    @OneToMany( cascade = javax.persistence.CascadeType.ALL, fetch = javax.persistence.FetchType.LAZY )
    public List<InboxMail> getInboxMails() {
    	return inboxMails;
    }

    public void setInboxMails(List<InboxMail> inboxMails) {
    	this.inboxMails = inboxMails;
    }

    @OneToMany( cascade = javax.persistence.CascadeType.ALL, fetch = javax.persistence.FetchType.LAZY )
    public List<OutboxMail> getOutboxMails() {
    	return outboxMails;
    }

    public void setOutboxMails(List<OutboxMail> outboxMails) {
    	this.outboxMails = outboxMails;
    }
    */
}
