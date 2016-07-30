#!/bin/zsh

echo UNLOAD APPLICATION
ssh root@aws /etc/init.d/tomcat7 stop
ssh root@aws rm -rf /var/lib/tomcat7/webapps/mail4hotspot

echo
echo CREATE WAR
JAVA_HOME="c:/Program Files (x86)/Java/jdk1.7.0_02" C:/Alex/java/apache-maven-3.0.4/bin/mvn.bat install

echo
echo CLEAN WAR
cd target
rm -rf tmp
mkdir tmp
cd tmp
"c:/Program Files (x86)/Java/jdk1.7.0_02/bin/jar.exe" xf ../mail4hotspot-0.0.1-SNAPSHOT.war
rm -rf WEB-INF/lib/*
"c:/Program Files (x86)/Java/jdk1.7.0_02/bin/jar.exe" cf ../mail4hotspot-0.0.1-SNAPSHOT-light.war .
cd ..

echo
echo SEND WAR TO AWS
ssh root@aws rm /tmp/mail4hotspot-0.0.1-SNAPSHOT-light.war
scp mail4hotspot-0.0.1-SNAPSHOT-light.war root@aws:/tmp

echo
echo UNJAR WAR
ssh root@aws 'cd /tmp ; rm -rf mail4hotspot ; mkdir mail4hotspot ; cd mail4hotspot ; fastjar xf /tmp/mail4hotspot-0.0.1-SNAPSHOT-light.war'

echo
echo ADD REMOVED LIBRARIES
ssh root@aws 'cd /tmp/mail4hotspot ; cp -rp ~fenyo/mail4hotspot-libs/* WEB-INF/lib'

echo
echo CREATE CONFIG FILE
ssh root@aws 'cat > /tmp/mail4hotspot/META-INF/config.properties' << EOF
mail4hotspot.dnsdomain=v0.tun.vpnoverdns.com
mail4hotspot.dnsport=53
mail4hotspot.maxmailspersession=20
mail4hotspot.proxyhost=
mail4hotspot.proxyport=
jpa.dialect=org.springframework.orm.jpa.vendor.HibernateJpaDialect
jpa.vendor.adapter=HibernateJpaVendorAdapter
hibernate.connection.driver_class=org.postgresql.Driver
hibernate.connection.url=jdbc:postgresql://127.0.0.1:5432/mail4hotspot
hibernate.connection.username=mail4hotspotadmin
hibernate.connection.password=PASSWORD
hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
hibernate.hbm2ddl.auto=validate
#hibernate.hbm2ddl.auto=create
hibernate.show_sql=false
EOF

echo
echo LOAD APPLICATION
ssh root@aws 'chown -R tomcat7.tomcat7 /tmp/mail4hotspot ; mv /tmp/mail4hotspot /var/lib/tomcat7/webapps/mail4hotspot'
ssh root@aws '/etc/init.d/tomcat7 start'
