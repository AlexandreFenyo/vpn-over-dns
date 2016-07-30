M ubuntu:xenial
MAINTAINER Alexandre Fenyo <alex@fenyo.net>
RUN apt-get update && apt-get install -y build-essential ssh perl liblwp-protocol-https-perl libxml-simple-perl
RUN wget -O /root/Net-DNS-0.68.tar.gz http://search.cpan.org/CPAN/authors/id/N/NL/NLNETLABS/Net-DNS-0.68.tar.gz
RUN wget -O /usr/bin/vpnoverdns.pl http://vpnoverdns.com/vpnoverdns-docker.pl
RUN chmod 755 /usr/bin/vpnoverdns.pl && ln -s /usr/bin/vpnoverdns.pl /usr/bin/vpnoverdns
RUN cd /root ; tar zxf Net-DNS-0.68.tar.gz ; cd Net-DNS-0.68 ; perl Makefile.PL ; make ; make install ; make clean ; cd .. ; rm -rf Net-DNS-0.68.tar.gz Net-DNS-0.68
RUN echo -n anonymou > /root/.vpnoverdns
CMD ["/usr/bin/perl", "/usr/bin/vpnoverdns.pl"]
