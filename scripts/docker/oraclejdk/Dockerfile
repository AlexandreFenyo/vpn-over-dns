FROM ubuntu:15.10
ENV TERM vt100
ENV LANG C.UTF-8
ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.0.29
ENV JAVA_VERSION 8u66
ENV JDK_FILE_VERSION 1.8.0_66
ENV JAVA_HOME /usr/local/jdk
RUN apt-get update && apt-get install -y --force-yes telnet less libgtk2.0-0 xterm net-tools tcpdump tshark vim
ADD apache-tomcat-$TOMCAT_VERSION.tar.gz /usr/local
RUN mv /usr/local/apache-tomcat-$TOMCAT_VERSION /usr/local/tomcat
RUN ln -s /usr/local/tomcat /usr/local/apache-tomcat-$TOMCAT_VERSION
ADD jdk-$JAVA_VERSION-linux-x64.tar.gz /usr/local
RUN mv /usr/local/jdk$JDK_FILE_VERSION /usr/local/jdk
RUN ln -s /usr/local/jdk /usr/local/jdk$JDK_FILE_VERSION
CMD ["/usr/local/tomcat/bin/catalina.sh", "run"]
