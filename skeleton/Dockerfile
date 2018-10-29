FROM nimmis/java-centos:openjdk-7-jdk
ENV HTTP_PROXY 'http://192.168.3.20:3128'
ENV http_proxy 'http://192.168.3.20:3128'
ENV HTTPS_PROXY 'https://192.168.3.20:3128'
ENV https_proxy 'https://192.168.3.20:3128'
RUN yum -y install tigervnc-server
RUN yes ranger| vncserver
RUN vncserver -kill :1 | :
RUN yum -y install libaio
RUN mkdir -p /home/oracle/app
RUN curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/msprod.repo
#ADD msprod.repo /etc/yum.repos.d/
#RUN yum -y install --nogpgcheck yum-downloadonly
RUN yum remove unixODBC-utf16 unixODBC-utf16-devel
ENV ACCEPT_EULA Y
RUN yum -y --nogpgcheck --assumeyes install mssql-tools unixODBC-devel 
RUN yum -y --nogpgcheck --assumeyes update mssql-tools

RUN mkdir -p /usr/orps/java && mkdir -p /usr/orps/xunit && mkdir -p /usr/orps/xstore && mkdir -p /home/oracle && mkdir -p /tmp/antinstall0
ADD java.tar /usr/orps/java
ADD Skillnet-XUnit-Installer.tar /usr/orps/xunit
ADD jre.tar /opt/
ADD fonts.tar /usr/share/
ADD xunit.properties /usr/orps/xstore/pos
