# docker-compose up -d --build
# docker exec -it cyrus-docker bash

FROM opensuse/leap
LABEL org.opencontainers.image.authors="richard.eigenmann@gmail.com"

USER root

# add the packages needed for the cyrus server and some to work with the shell
#RUN zypper addrepo https://download.opensuse.org/repositories/server:mail/15.6/server:mail.repo
#RUN zypper addrepo https://download.opensuse.org/repositories/home:/buschmann23:/cyrus:/3.8/15.6/home:buschmann23:cyrus:3.8.repo
RUN zypper addrepo https://download.opensuse.org/repositories/home:/buschmann23:/cyrus:/next/15.6/home:buschmann23:cyrus:next.repo
#RUN zypper addrepo https://download.opensuse.org/repositories/home:/buschmann23:/cyrus:/3.4/15.6/home:buschmann23:cyrus:3.4.repo
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
    sysvinit-tools \
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

# set up user cyrus with a local password
RUN echo "cyrus:${cyruspassword}" | chpasswd

RUN chgrp mail /etc/sasldb2
RUN chmod go+r /etc/sasldb2
RUN chsh -s /bin/bash cyrus

RUN groupadd -fr saslauth
RUN usermod -aG saslauth cyrus

# We need a syslog conf file so that logs get written
ADD syslog-cyrus.conf /etc/syslog-ng/conf.d/

# create the logfiles
RUN touch /var/log/imapd.log /var/log/auth.log

#RUN sed -ibak -e 's/^\(sasl_pwcheck_method:\) .*/\1 auxprop\nsasl_auxprop_plugin: sasldb\nsasl_mech_list: DIGEST-MD5 EXTERNAL CRAM-MD5 LOGIN PLAIN\n/' /etc/imapd.conf 
RUN sed -ibak -e 's/^\(sasl_pwcheck_method:\) .*/\1 auxprop\nsasl_auxprop_plugin: sasldb\n/' /etc/imapd.conf 
#RUN sed -ibak -e 's/^\(sasl_pwcheck_method:\) .*/\1 alwaystrue\n/' /etc/imapd.conf 
#RUN echo "debug: 1" >> /etc/imapd.conf
RUN echo "sasl_auto_transition: yes" >> /etc/imapd.conf
RUN echo "allowplaintext: yes" >> /etc/imapd.conf
#RUN echo "autocreate_quota: 10000" >> /etc/imapd.conf
RUN echo "altnamespace: no" >> /etc/imapd.conf
RUN echo "imap_admins: cyrus" >> /etc/imapd.conf
RUN echo "unixhierarchysep: 0"  >> /etc/imapd.conf

#RUN echo -e "SASLAUTHD_MECHANISMS=\"sasldb\"\n" >> /etc/sysconfig/saslauthd
#RUN echo -e "SASLAUTHD_START=\"yes\"\n" >> /etc/sysconfig/saslauthd

RUN sudo -u cyrus /usr/lib/cyrus/tools/mkimap

# Create the script that creates the mailboxes for a users
RUN echo -e "createmailbox INBOX\ncreatemailbox INBOX.Archive" > /createmailboxes.commands
RUN echo -e "subscribe INBOX\nsubscribe INBOX.Archive" >> /createmailboxes.commands

RUN echo -e "cyradm --user cyrus --password ${cyruspassword} --authz ${mailboxuser1} --auth PLAIN localhost < createmailboxes.commands" > /createmailboxes.sh; \
echo -e "cyradm --user cyrus --password ${cyruspassword} --authz ${mailboxuser2} --auth PLAIN localhost < createmailboxes.commands" >> /createmailboxes.sh; \
chmod +x createmailboxes.sh;

# Create the mailboxes and VERY IMPORTANT subscribe to the mailboxes
#RUN /sbin/startproc -p /var/run/cyrus-master.pid /usr/lib/cyrus/master -d; /sbin/startproc -p /var/run/saslauthd.pid saslauthd -a PAM -n1; ./createmailboxes.sh
#echo "createmailbox user/${mailboxuser1}/Inbox" | sudo -u cyrus -i cyradm --user cyrus --password ${cyruspassword} --auth PLAIN localhost; \
#sudo -u cyrus -i cyradm --user cyrus --password ${cyruspassword} --auth PLAIN subscribe user/${mailboxuser1}/Inbox localhost; \
#sudo -u cyrus -i cyradm --user cyrus --password ${cyruspassword} --auth PLAIN createmailbox user/${mailboxuser2}/Inbox localhost; \
#sudo -u cyrus -i cyradm --user cyrus --password ${cyruspassword} --auth PLAIN subscribe user/${mailboxuser2}/Inbox localhost;

#RUN /usr/lib/cyrus/master -d; saslauthd -a PAM -n1; cyradm --user cyrus --password ${cyruspassword} --auth PLAIN localhost < createmailboxes.commands

#mv /createmailbox1.commands /createmailbox1.commands.completed;

#RUN /sbin/startproc -p /var/run/cyrus-master.pid /usr/lib/cyrus/master -d; \
#sudo -u cyrus -i cyradm --user cyrus -w ${cyruspassword} localhost < /createmailbox2.commands; \
#mv /createmailbox2.commands /createmailbox2.commands.completed;

# create a file entypoint.sh in the root directory
RUN echo -e "#!/bin/bash\n"\
"echo Running entrypoint.sh\n"\
"/usr/sbin/syslog-ng\n"\
"saslauthd -a PAM -n1\n"\
"/usr/lib/cyrus/master\n"\
> /entrypoint.sh;

RUN chmod +x /entrypoint.sh

# start the cyrus server
ENTRYPOINT /entrypoint.sh
