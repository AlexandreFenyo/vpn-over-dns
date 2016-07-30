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

import net.fenyo.mail4hotspot.domain.User.Type;

import javax.persistence.*;
import java.net.*;

@Entity
//@Table(name="ip", schema="public", indexes = { @Index(columnList = "id"), @Index(columnList = "ipstring") })
@Table(name="ip", schema="public", indexes = { @Index(columnList = "ipstring") })
@SuppressWarnings("serial")
public class Ip implements java.io.Serializable {
	private long id;
	private Inet4Address ip;

	private long bytesIn = 0;
	private long bytesOut = 0;

    public enum Type { NORMAL, SLOWDOWN, BLOCKED }
    public Type type = Type.NORMAL;

	private boolean watch = false;
    private String message;

    public Ip() {}

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
    public String getIpString() {
    	return ip.toString().replaceFirst(".*/", "");
    }

    public void setIpString(final String ipString) throws UnknownHostException {
    	this.ip = (Inet4Address) InetAddress.getByName(ipString);
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

    @Column(unique=false, nullable=true, length=1024)
    public String getMessage() {
    	return message;
    }
    
    public void setMessage(final String message) {
    	this.message = message;
    }

    @Enumerated(javax.persistence.EnumType.STRING)
    @Column(unique=false, nullable=false)
    public Type getType() {
    	return type;
    }

    public void setType(final Type type) {
    	this.type = type;
    }
}
