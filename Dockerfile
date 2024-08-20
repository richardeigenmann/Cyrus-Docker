# docker-compose up -d --build
# docker exec -it cyrus-docker bash

FROM opensuse/leap
LABEL org.opencontainers.image.authors="richard.eigenmann@gmail.com"

USER root

# add the packages needed for the cyrus server and some to work with the shell
#RUN zypper addrepo https://download.opensuse.org/repositories/server:mail/15.6/server:mail.repo
#RUN zypper addrepo https://download.opensuse.org/repositories/home:/buschmann23:/cyrus:/3.4/15.6/home:buschmann23:cyrus:3.4.repo
#RUN zypper addrepo https://download.opensuse.org/repositories/home:/buschmann23:/cyrus:/3.8/15.6/home:buschmann23:cyrus:3.8.repo
RUN zypper addrepo https://download.opensuse.org/repositories/home:/buschmann23:/cyrus:/next/15.6/home:buschmann23:cyrus:next.repo && \
zypper --gpg-auto-import-keys refresh && \
zypper --non-interactive in \
    cyrus-imapd \
    cyrus-sasl-plain \
    cyrus-sasl-crammd5 \
    cyrus-sasl-digestmd5 \
    cyradm \
    cyrus-sasl-saslauthd \
    syslog-ng \
    sudo \
    sysvinit-tools \
    vim && \
zypper clean --all

# make sure the sasldb2 is accessible to the mail group and readable by all!
RUN touch /etc/sasldb2
RUN chgrp mail /etc/sasldb2
RUN chmod go+r /etc/sasldb2
RUN chsh -s /bin/bash cyrus

# add a group for saslauth
RUN groupadd -fr saslauth
RUN usermod -aG saslauth cyrus

# We need a syslog conf file so that logs get written
ADD syslog-cyrus.conf /etc/syslog-ng/conf.d/

# create the logfiles
RUN touch /var/log/imapd.log /var/log/auth.log

# Update the /etc/imapd.conf configuration file:
RUN sed -ibak -e 's/^\(sasl_pwcheck_method:\) .*/\1 auxprop\nsasl_auxprop_plugin: sasldb\n/' /etc/imapd.conf 
RUN echo -e "sasl_auto_transition: yes\nallowplaintext: yes\nltnamespace: no\nimap_admins: cyrus\nunixhierarchysep: 0" >> /etc/imapd.conf

# REMOVE THIS LINE IF YOU ARE CONNECTING TO EXISTING MAILBOXES
# initialise the mailboxes
RUN sudo -u cyrus /usr/lib/cyrus/tools/mkimap

# create a file entypoint.sh in the root directory. This will start the 
# syslog-ng daemon so that we get log output
# saslauthd so that we can authenticate users
# cyrus/master which is the actual daemon
RUN echo -e "#!/bin/bash\n"\
"echo Running entrypoint.sh\n"\
"/usr/sbin/syslog-ng\n"\
"saslauthd -a PAM -n1\n"\
"/usr/lib/cyrus/master\n"\
> /entrypoint.sh;

RUN chmod +x /entrypoint.sh

# start the cyrus server
ENTRYPOINT /entrypoint.sh
