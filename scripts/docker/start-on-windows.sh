# changer le partage local de la VM VirtualBox comme suit :
# de :
# Nom: c/Users Chemin: c:\Users
# vers :
# Nom: c/Users Chemin: c:\Alex\svn

# ne pas le lancer sous root mais sous docker

docker run --add-host=docker:172.17.42.1 -v /c/Users/vpnoverdns/scripts/docker/squid/squid-light.conf:/etc/squid3/squid.conf --restart=always -d -p 3128:3128 --name ct-squid-light sameersbn/squid
docker run --add-host=docker:172.17.42.1 -v /c/Users/vpnoverdns/scripts/docker/squid/squid-full.conf:/etc/squid3/squid.conf --restart=always -d -p 3129:3128 --name ct-squid-full sameersbn/squid
docker run --add-host=docker:172.17.42.1 -v /c/Users/vpnoverdns/scripts/docker/squid/squid-anonymous.conf:/etc/squid3/squid.conf --restart=always -d -p 3130:3128 --name ct-squid-anonymous sameersbn/squid
docker run --add-host=docker:172.17.42.1 -v /c/Users/vpnoverdns/scripts/docker/squid/squid-maint.conf:/etc/squid3/squid.conf --restart=always -d -p 3131:3128 --name ct-squid-maint sameersbn/squid
docker run --add-host=docker:172.17.42.1 -e CATALINA_OPTS="-Djava.security.egd=file:/dev/./urandom -Dtomcat_password=PASSWORD" -v /c/Users/vpnoverdns/scripts/docker/tomcat/tomcat-users.xml:/usr/local/tomcat/conf/tomcat-users.xml --restart=always -d -p 8080:8080 -p 8009:8009 --name ct-tomcat tomcat
docker run -e POSTGRES_PASSWORD=PASSWORD -v /c/Users/vpnoverdns/scripts/docker/postgres/data:/var/lib/postgresql/data --restart=always -d -p 5432:5432 --name ct-postgres postgres
docker run --add-host=docker:172.17.42.1 -v /c/Users/vpnoverdns/scripts/docker/apache/httpd.conf:/usr/local/apache2/conf/httpd.conf -v /c/Users/vpnoverdns/scripts/docker/apache/GandiCAChain.pem:/usr/local/apache2/certs/GandiCAChain.pem -v /c/Users/vpnoverdns/scripts/docker/apache/cert.pem:/usr/local/apache2/certs/cert.pem -v /c/Users/vpnoverdns/scripts/docker/apache/keypriv.pem:/usr/local/apache2/certs/keypriv.pem -v /c/Users/vpnoverdns/scripts/docker/../../general/web/htdocs/:/usr/local/apache2/htdocs/ --restart=always -d -p 81:80 -p 443:443 --name ct-apache httpd
docker run -v /c/Users/vpnoverdns:/root/svn/vpnoverdns --name ct-perl -t -i ubuntu sh -c 'apt-get update ; apt-get install -y perl make gcc libexpat1 libexpat1-dev expat libxml-sax-expat-perl telnet ; cp /usr/bin/perl /bin ; yes "" | perl -MCPAN -e "install XML::Simple" ; yes "" | perl -MCPAN -e "install Net::DNS" ; echo nameserver 192.168.1.20 > /etc/resolv.conf'
docker commit ct-perl fenyo/perl
docker rm ct-perl
docker run -v /c/Users/vpnoverdns:/root/svn/vpnoverdns --rm -t -i fenyo/perl /root/svn/vpnoverdns/dns-perl/vpnoverdns.pl
