# docker-compose up -d --build
# docker exec -it  cyrus-docker bash

FROM opensuse/leap
LABEL org.opencontainers.image.authors="richard.eigenmann@gmail.com"

USER root

# add the packages needed for the cyrus server and some to work with the shell
#RUN zypper addrepo https://download.opensuse.org/repositories/server:mail/15.6/server:mail.repo
RUN zypper addrepo https://download.opensuse.org/repositories/home:/buschmann23:/cyrus:/3.8/15.6/home:buschmann23:cyrus:3.8.repo
RUN zypper --gpg-auto-import-keys refresh
RUN zypper --non-interactive in \
    cyrus-imapd \
    cyrus-sasl-plain \
    cyrus-sasl-crammd5 \
    cyrus-sasl-digestmd5 \
    cyradm \
    cyrus-sasl-saslauthd \
    syslog-ng \
    sudo \
    vim 

ARG mailboxuser1
ARG mailboxpassword1
ARG mailboxuser2
ARG mailboxpassword2
ARG cyruspassword

# set up the saslauthd accounts (complication: the host name changes all the time!)
# -u cyrus ensures the account is set up for the hostname cyrus
# cyrus is the account we need to run the cyradm commands
RUN echo ${mailboxpassword1} | saslpasswd2 -p -u cyrus -c ${mailboxuser1}
RUN echo ${mailboxpassword2} | saslpasswd2 -p -u cyrus -c ${mailboxuser2}
RUN echo ${cyruspassword} | saslpasswd2 -p -u cyrus -c cyrus

RUN chgrp mail /etc/sasldb2
RUN chmod go+r /etc/sasldb2
RUN chsh -s /bin/bash cyrus

RUN groupadd -fr saslauth
RUN usermod -aG saslauth cyrus

# create a file entypoint.sh in the root directory
RUN echo -e "#!/bin/bash\n"\
"echo Running entrypoint.sh\n"\
"#/usr/sbin/syslog-ng\n"\
"saslauthd -a PAM -n1\n"\
"#sleep 2000000\n" \
"#/usr/lib/cyrus/master -D -C /etc/imapd.conf -l /var/log/imapd.log\n"\
"/usr/lib/cyrus/master\n"\
> /entrypoint.sh;

RUN chmod +x /entrypoint.sh

# We need a syslog conf file so that logs get written
ADD syslog-cyrus.conf /etc/syslog-ng/conf.d/

# create the logfiles
#RUN touch /var/log/imapd.log /var/log/auth.log && chmod a+rwx /var/log/imapd.log /var/log/auth.log

# Create the script that creates the mailboxes for the 2 users
RUN echo -e "createmailbox user.${mailboxuser1}\ncreatemailbox user.${mailboxuser1}.Archive\nexit" > /createmailbox1.commands
RUN echo -e "createmailbox user.${mailboxuser2}\ncreatemailbox user.${mailboxuser2}.Archive\nexit" > /createmailbox2.commands

#RUN /sbin/startproc -p /var/run/cyrus-master.pid /usr/lib/cyrus/master -d; \
#/sbin/startproc -p /var/run/cyrus-master.pid /usr/lib/cyrus/master -d /usr/local/libexec/master
#sudo -u cyrus -i cyradm --user cyrus -w ${cyruspassword} localhost < /createmailbox1.commands; \
#mv /createmailbox1.commands /createmailbox1.commands.completed;

#RUN /sbin/startproc -p /var/run/cyrus-master.pid /usr/lib/cyrus/master -d; \
#sudo -u cyrus -i cyradm --user cyrus -w ${cyruspassword} localhost < /createmailbox2.commands; \
#mv /createmailbox2.commands /createmailbox2.commands.completed;

#RUN sed -ibak -e 's/^\(sasl_pwcheck_method:\) .*/\1 auxprop\nsasl_auxprop_plugin: sasldb\nsasl_mech_list: DIGEST-MD5 EXTERNAL CRAM-MD5 LOGIN PLAIN\n/' /etc/imapd.conf 
#RUN sed -ibak -e 's/^\(sasl_pwcheck_method:\) .*/\1 alwaystrue\n/' /etc/imapd.conf 
#RUN echo "debug: 1" >> /etc/imapd.conf
RUN echo "sasl_auto_transition: yes" >> /etc/imapd.conf

#RUN echo -e "SASLAUTHD_MECHANISMS=\"sasldb\"\n" >> /etc/sysconfig/saslauthd
#RUN echo -e "SASLAUTHD_START=\"yes\"\n" >> /etc/sysconfig/saslauthd

RUN sudo -u cyrus /usr/lib/cyrus/tools/mkimap

# start the cyrus server
ENTRYPOINT /entrypoint.sh
