FROM ubuntu
ENV TERM vt100
RUN apt-get update && apt-get install -y --force-yes perl make gcc libexpat1 libexpat1-dev expat libxml-sax-expat-perl telnet libxml-simple-perl libnet-dns-perl
# RUN cpan Mozilla::CA
# alternative:
# FROM ubuntu
# ENV TERM vt100
# RUN apt-get update && apt-get install -y --force-yes perl make gcc libexpat1 libexpat1-dev expat libxml-sax-expat-perl telnet
# RUN cpan XML::Simple
# On ne veut pas la version 1.03 de Net::DNS a cause du bug GLOB
# RUN cpan N/NL/NLNETLABS/Net-DNS-1.02.tar.gz
# RUN cpan Mozilla::CA
