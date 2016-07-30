
# reset LANG and any locale settings since ifconfig output depends on it
DOCKER_IP     = `LANG= ifconfig docker0 | fgrep 'inet addr:' | sed 's/inet addr://' | awk '{ print $$1; }'`
PUBLIC_IP     = `hostname -i`

CONTAINER_IDs = `docker ps -a -q | sed s%$$%/stop-rm% | xargs echo`

#ENGINE=tomcat
ENGINE=oraclejdk

# sequential start: make NP=1 run
NP = 8

IMAGE_SQUID    = sameersbn/squid
IMAGE_TOMCAT   = tomcat
IMAGE_ORACLE_JDK = fenyo/oraclejdk
IMAGE_POSTGRES = postgres
IMAGE_APACHE   = httpd

all:
	@echo available targets: stop clean create create-new-database run

create: create-perl create-oraclejdk

run-all: run-squid run-$(ENGINE) run-postgres run-apache

run:
	$(MAKE) $(MAKEFLAGS) -j${NP} run-all

stop-all: stop-squid stop-$(ENGINE) stop-postgres stop-apache

stop:
	$(MAKE) $(MAKEFLAGS) -j${NP} stop-all

clean-all: clean-tomcat clean-oraclejdk clean-postgres clean-squid clean-apache
	-@docker images -a -q | xargs docker rmi

clean: stop
	$(MAKE) $(MAKEFLAGS) clean-all
	-docker ps -a -q | xargs docker stop
	-docker ps -a -q | xargs docker rm
	-docker images -a -q | xargs docker rmi

############################################################
# SQUID

SQUID_INSTANCES  = light full anonymous maint
SQUID_RUN_JOBS   = $(addprefix run/,  ${SQUID_INSTANCES})
SQUID_STOP_JOBS  = $(addprefix stop/, ${SQUID_INSTANCES})
PORT[light]     = 3128
PORT[full]      = 3129
PORT[anonymous] = 3130
PORT[maint]     = 3131

run-squid:	${SQUID_RUN_JOBS}
stop-squid:	${SQUID_STOP_JOBS}

# wwwbadname.vpnoverdns.com is used to generate certificate validation error for testing purpose only (see perl client source code)
${SQUID_RUN_JOBS}:
	-docker run --add-host=docker:${DOCKER_IP} --add-host=www.vpnoverdns.com:${DOCKER_IP} --add-host=wwwbadname.vpnoverdns.com:${DOCKER_IP} -v ${PWD}/squid/squid-$(notdir $@).conf:/etc/squid3/squid.conf:ro --restart=always -d -p ${PORT[$(notdir $@)]}:3128 --name ct-squid-$(notdir $@) ${IMAGE_SQUID}

${SQUID_STOP_JOBS}:
	-@docker stop ct-squid-$(notdir $@)
	-@docker rm ct-squid-$(notdir $@)

clean-squid: ${IMAGE_SQUID}/rmi

############################################################
# TOMCAT+OPENJDK / TOMCAT+ORACLEJDK

# jvisualvm/jconsole/java mission control: connect to PUBLIC_IP:8766
# remote debug: PUBLIC_IP:8765
create-oraclejdk:
	cd oraclejdk ; docker rmi fenyo/oraclejdk ; docker build -t fenyo/oraclejdk .
run-oraclejdk:
	-docker run --add-host=docker:${DOCKER_IP} -e CATALINA_OPTS="-XX:+UnlockCommercialFeatures -XX:+FlightRecorder -XX:StartFlightRecording=duration=60s,filename=myrecording.jfr -Djava.security.egd=file:/dev/./urandom -Dtomcat_password=PASSWORD -Xmx1024m -Xms64m -Djava.rmi.server.hostname=${PUBLIC_IP} -Xdebug -Xrunjdwp:transport=dt_socket,address=8765,server=y,suspend=n -Dcom.sun.management.jmxremote.port=8766 -Dcom.sun.management.jmxremote.rmi.port=8766 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false" -v /var/log/tomcat:/usr/local/tomcat/logs -v ${PWD}/tomcat/dist/mail4hotspot.war:/usr/local/tomcat/webapps/mail4hotspot.war:ro -v ${PWD}/tomcat/tomcat-users.xml:/usr/local/tomcat/conf/tomcat-users.xml:ro --restart=always -d -p 8765:8765 -p 8766:8766 -p 8080:8080 -p 8009:8009 -p 53:53/udp --name ct-tomcat ${IMAGE_ORACLE_JDK}
stop-oraclejdk:		ct-tomcat/stop-rm
clean-oraclejdk:	${IMAGE_ORACLE_JDK}/rmi

run-tomcat:
	-docker run --add-host=docker:${DOCKER_IP} -e CATALINA_OPTS="-Djava.security.egd=file:/dev/./urandom -Dtomcat_password=PASSWORD -Xmx1024m -Xms64m -Djava.rmi.server.hostname=${PUBLIC_IP} -Xdebug -Xrunjdwp:transport=dt_socket,address=8765,server=y,suspend=n -Dcom.sun.management.jmxremote.port=8766 -Dcom.sun.management.jmxremote.rmi.port=8766 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false" -v /var/log/tomcat:/usr/local/tomcat/logs -v ${PWD}/tomcat/dist/mail4hotspot.war:/usr/local/tomcat/webapps/mail4hotspot.war:ro -v ${PWD}/tomcat/tomcat-users.xml:/usr/local/tomcat/conf/tomcat-users.xml:ro --restart=always -d -p 8765:8765 -p 8766:8766 -p 8080:8080 -p 8009:8009 -p 53:53/udp --name ct-tomcat ${IMAGE_TOMCAT}
stop-tomcat:	ct-tomcat/stop-rm
clean-tomcat:	${IMAGE_TOMCAT}/rmi

############################################################
# APACHE

run-apache:
	-docker run --add-host=docker:${DOCKER_IP} -v ${PWD}/apache/httpd.conf:/usr/local/apache2/conf/httpd.conf:ro -v ${PWD}/apache/GandiCAChain.pem:/usr/local/apache2/certs/GandiCAChain.pem:ro -v ${PWD}/apache/cert.pem:/usr/local/apache2/certs/cert.pem:ro -v ${PWD}/apache/keypriv.pem:/usr/local/apache2/certs/keypriv.pem:ro -v ${PWD}/../../general/web/htdocs/:/usr/local/apache2/htdocs/:ro --restart=always -d -p 80:80 -p 443:443 --name ct-apache ${IMAGE_APACHE}
stop-apache:	ct-apache/stop-rm
clean-apache:	${IMAGE_APACHE}/rmi

############################################################
# POSTGRES

run-postgres:
	# if postgres container exists and is running, do not remote its bdd data files
	-docker inspect -f '{{.State.Running}}' ct-postgres 2> /dev/null | fgrep true > /dev/null 2>&1 || rm -rf postgres/data
	-docker run -e POSTGRES_PASSWORD=PASSWORD -v ${PWD}/postgres/data:/var/lib/postgresql/data --restart=always -d -p 5432:5432 --name ct-postgres ${IMAGE_POSTGRES}

# must be run after postgres startup: may take up to 10 or 20 seconds after "make run-postgres" is launched
create-new-database:
	-docker exec -t -i ct-postgres psql -U postgres postgres -c 'drop database mail4hotspot'
	-docker exec -t -i ct-postgres psql -U postgres postgres -c 'create database mail4hotspot'

stop-postgres:	ct-postgres/stop-rm
clean-postgres:	${IMAGE_POSTGRES}/rmi

psql:
	# docker exec -t -i ct-postgres psql -U postgres postgres
	docker exec -t -i ct-postgres psql -U postgres mail4hotspot

clean-pgdata: stop-postgres
	-@rm -rf postgres/data

############################################################

create-cert:
	openssl req -outform PEM -text -new -newkey rsa:2048 -keyform PEM -keyout apache/srv-keypriv.pem > apache/csr.pem

############################################################

create-perl:
	cd perl ; docker rmi fenyo/perl ; docker build -t fenyo/perl .

# use when tomcat on a docker container
run-perl:
	docker run -v /root/svn/vpnoverdns/dns-perl/vpnoverdns.pl:/root/vpnoverdns.pl:ro --rm -t -i fenyo/perl sh -c "echo nameserver ${DOCKER_IP} > /etc/resolv.conf ; perl /root/vpnoverdns.pl -i fenyoa PASSWORD"

# use when tomcat on a docker container
run-perl-debug:
	docker run -v /root/svn/vpnoverdns/dns-perl/vpnoverdns.pl:/root/vpnoverdns.pl:ro --rm -t -i fenyo/perl sh -c "echo nameserver ${DOCKER_IP} > /etc/resolv.conf ; perl /root/vpnoverdns.pl -d -v -i fenyoa PASSWORD"

# use when tomcat in Eclipse on w7
run-perl-ubuntu:
	@echo if not in a container, need to start on the tomcat server: "ssh 192.168.1.50 -l root -R 8009:127.0.0.1:8009"
	docker run -v /root/svn/vpnoverdns/dns-perl/vpnoverdns.pl:/root/vpnoverdns.pl:ro --rm -t -i fenyo/perl sh -c "echo nameserver 192.168.1.20 > /etc/resolv.conf ; perl /root/vpnoverdns.pl -i fenyoa PASSWORD"

# testing with lynx: http_proxy=http://192.168.1.50:3333 https_proxy=http://192.168.1.50:3333 lynx http://www.wikipedia.org/
run-perl-ubuntu-anonymous:
	@echo if not in a container, need to start on the tomcat server: "ssh 192.168.1.50 -l root -R 8009:127.0.0.1:8009"
	docker run -p 3333:3333 -v /root/svn/vpnoverdns/dns-perl/vpnoverdns.pl:/root/vpnoverdns.pl:ro --rm -t -i fenyo/perl sh -c "echo nameserver 192.168.1.20 > /etc/resolv.conf ; perl /root/vpnoverdns.pl -A ; perl /root/vpnoverdns.pl -g -L 3333:127.0.0.1:3130"

# testing: ssh -p 3333 192.168.1.50
run-perl-ubuntu-ssh:
	@echo if not in a container, need to start on the tomcat server: "ssh 192.168.1.50 -l root -R 8009:127.0.0.1:8009"
	docker run -p 3333:3333 -v /root/svn/vpnoverdns/dns-perl/vpnoverdns.pl:/root/vpnoverdns.pl:ro --rm -t -i fenyo/perl sh -c "echo nameserver 192.168.1.20 > /etc/resolv.conf ; perl /root/vpnoverdns.pl -i fenyoa PASSWORD ; perl /root/vpnoverdns.pl -g -L 3333:fenyo.net:22"

# use when tomcat in Eclipse on w7
run-perl-ubuntu-debug:
	@echo if not in a container, need to start on the tomcat server: "ssh 192.168.1.50 -l root -R 8009:127.0.0.1:8009"
	docker run -v /root/svn/vpnoverdns/dns-perl/vpnoverdns.pl:/root/vpnoverdns.pl:ro --rm -t -i fenyo/perl sh -c "echo nameserver 192.168.1.20 > /etc/resolv.conf ; perl /root/vpnoverdns.pl -d -v -i fenyoa PASSWORD"

# use when tomcat in Eclipse on ibm (lenovo)
run-perl-ibm:
	@echo if not in a container, need to start on the tomcat server: "ssh 10.69.127.250 -l root -R 8009:127.0.0.1:8009"
	docker run -v /root/svn/vpnoverdns/dns-perl/vpnoverdns.pl:/root/vpnoverdns.pl:ro --rm -t -i fenyo/perl sh -c "echo nameserver 10.69.127.249 > /etc/resolv.conf ; perl /root/vpnoverdns.pl -i fenyoa PASSWORD"

# use when tomcat in Eclipse on ibm (lenovo)
run-perl-ibm-debug:
	@echo if not in a container, need to start on the tomcat server: "ssh 10.69.127.250 -l root -R 8009:127.0.0.1:8009"
	docker run -v /root/svn/vpnoverdns/dns-perl/vpnoverdns.pl:/root/vpnoverdns.pl:ro --rm -t -i fenyo/perl sh -c "echo nameserver 10.69.127.249 > /etc/resolv.conf ; perl /root/vpnoverdns.pl -F -d -v -i fenyoa PASSWORD"

create-eclipse:
	echo docker run --name ct-eclipse -p 53:53/udp -t -i ubuntu bash
	echo docker start -i ct-eclipse
	echo apt-get update
	echo apt-get install xterm telnet x11-apps wget lynx firefox unzip zsh
	echo wget http://artfiles.org/eclipse.org//technology/epp/downloads/release/mars/1/eclipse-jee-mars-1-linux-gtk-x86_64.tar.gz
	echo tar zxf eclipse-jee-mars-1-linux-gtk-x86_64.tar.gz
	echo rm eclipse-jee-mars-1-linux-gtk-x86_64.tar.gz
	echo "download with firefox Java SE Development Kit 8u60"
	echo tar zxf Downloads/jdk-8u60-linux-x64.tar.gz
	echo rm -f Downloads/jdk-8u60-linux-x64.tar.gz
	echo wget http://apache.crihan.fr/dist/tomcat/tomcat-8/v8.0.27/bin/apache-tomcat-8.0.27.tar.gz
	echo tar zxf apache-tomcat-8.0.27.tar.gz
	echo rm -f apache-tomcat-8.0.27.tar.gz
	echo 'echo export PATH=/root/jdk1.8.0_60/bin:$PATH > /root/.zshrc'
	echo 'export DISPLAY=172.17.42.1:0 >> /root/.zshrc'
	echo 'lancer zsh puis eclipse et aller dans le marketplace pour installer subversive'
	echo 'pour utiliser subversive: root@virt#ssh -R 3690:localhost:3690 root@ovh'
	echo 'sortir et faire docker commit ct-eclipse fenyo/eclipse'
	echo 'pour lancer eclipse : docker start -i ct-eclipse puis zsh puis eclipse'

############################################################

%/stop-rm:
	-@echo $@ | sed 's%/stop-rm$$%%' | xargs docker stop
	-@echo $@ | sed 's%/stop-rm$$%%' | xargs docker rm

%/rmi:
	-@echo $@ | sed 's%/rmi$$%%' | xargs docker rmi

