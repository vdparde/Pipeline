FROM docker-repo.skillnetinc.com:8502/linux_skeleton
ADD xstore-mssqlserver.tar /usr/orps/xstore
ADD ant.install.properties.mssql /usr/orps/xstore/pos
WORKDIR /usr/orps/xstore/pos
ENV PATH '/opt/mssql-tools/bin/:/usr/orps/java/jdk1.8.0_144/bin:/usr/lib/oracle/12.1/client64/bin:/home/oracle/Installer/jdk1.8.0_144/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/opt/puppetlabs/bin:/root/bin:/root/bin:/root/bin' 
RUN cp ant.install.properties.mssql ant.install.properties
RUN cd /usr/orps/xstore/pos && export JAVA_HOME=/usr/orps/java/jdk1.8.0_144 && export PATH=$JAVA_HOME/bin:$PATH && java -jar *install*.jar
RUN cd /usr/orps/xunit && export JAVA_HOME=/usr/orps/java/jdk1.8.0_144 && export ANT_HOME=/usr/orps/xunit/apache-ant-1.9.2 && export PATH=$JAVA_HOME/bin:$ANT_HOME/bin:$PATH && /bin/bash -c 'source /usr/orps/xunit/apache-ant-1.9.2/bin/ant -f xunitautotest.xml install-linux'
WORKDIR /usr/orps/xstore/
RUN rm -rf pos

