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
RUN chsh -s /bin/bash cyrus

# create a file entypoint.sh in the root directory
RUN echo -e "#!/bin/bash\n"\
"echo Running entrypoint.sh\n"\
"/usr/sbin/syslog-ng\n"\
"saslauthd -a PAM -n1\n"\
"/usr/lib/cyrus/master\n"\
> /entrypoint.sh;

RUN chmod +x /entrypoint.sh

# We need a syslog conf file so that logs get written
ADD syslog-cyrus.conf /etc/syslog-ng/conf.d/

# start the syslog server or we never get to see any error messages!
RUN touch /var/log/imapd.log /var/log/auth.log

# start the cyrus server
ENTRYPOINT /entrypoint.sh
