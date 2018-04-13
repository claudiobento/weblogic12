FROM oracle/serverjre:8

# Maintainer
# ---------------------------------------------------------------
MAINTAINER Claudio Bento <claudio.bento@tr.com>

# Common ENV
# ---------------------------------------------------------------

ENV ORACLE_HOME=/u01/oracle \
       USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
       SCRIPT_FILE=/u01/oracle/createAndStartEmptyDomain.sh \
       PATH=$PATH:/usr/java/default/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin
	   
# Setup filesystem and oracle user
# Adjust file permissions for user oracle 'oracle' on /u01 to proceed WLS installation

RUN mkdir -p /u01 && \
    chmod a+xr /u01 && \
    useradd -b /u01 -d /u01/oracle -m -s /bin/bash oracle
	   
# Copy scripts
# -------------
COPY container-scripts/createAndStartEmptyDomain.sh container-scripts/create-wls-domain.py /u01/oracle/

# Domain and server environment variables
# -----------------------------------------------------------------
ENV DOMAIN_NAME="${DOMAIN_NAME:-base_domain}" \
    DOMAIN_HOME=/u01/oracle/user_projects/domains/${DOMAIN_NAME:-base_domain} \
    ADMIN_PORT="${DOMAIN_PORT:-7001}" \
    ADMIN_USERNAME="${ADMIN_USERNAME:-weblogic}" \
    ADMIN_NAME="${ADMIN_NAME:-AdminServer}" \
    ADMIN_PASSWORD="${ADMIN_PASSWORD:-""}"
	   
# Environment variables required for this build (do NOT change)
# -----------------------------------------------------------------

ENV FMW_PKG=fmw_12.2.1.3.0_infrastructure_Disk1_1of1.zip \
    FMW_JAR=fmw_12.2.1.3.0_infrastructure.jar
	   
# Copy packages
# ----------------
COPY $FMW_PKG install.file oraInst.loc /u01/
RUN chown oracle:oracle -R /u01 && \
    chmod +xr $SCRIPT_FILE
	   
# Install
# -----------------------------------------------------------------	   

USER oracle

RUN cd /u01 && $JAVA_HOME/bin/jar -xf /u01/$FMW_PKG && \
    ls /u01 && \
    $JAVA_HOME/bin/java -jar /u01/$FMW_JAR -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="Weblogic Server" && \
    rm /u01/$FMW_JAR /u01/$FMW_PKG /u01/oraInst.loc /u01/install.file
		
WORKDIR $ORACLE_HOME

# Define default command to start bash. 

CMD ["/u01/oracle/createAndStartEmptyDomain.sh"]
		
