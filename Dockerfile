# docker-compose up -d --build
# docker exec -it  cyrus-docker bash

#FROM opensuse:42.3
FROM opensuse/leap
MAINTAINER Richard Eigenmann

USER root

# add the packages needed for the cyrus server and some to work with the shell
RUN zypper --non-interactive in \
  cyrus-imapd \
  cyradm \
  cyrus-sasl-saslauthd \
  cyrus-sasl-digestmd5 \
  cyrus-sasl-crammd5 \
  sudo

ARG mailboxuser
ARG mailboxpassword
ARG cyruspassword

# set up the saslauthd accounts (complication: the host name changes all the time!)
# -u cyrus ensures the account is set up for the hostname cyrus
# cyrus is the account we need to run the cyradm commands
RUN echo ${mailboxpassword} | saslpasswd2 -p -u cyrus -c ${mailboxuser}
RUN echo ${cyruspassword} | saslpasswd2 -p -u cyrus -c cyrus
RUN chgrp mail /etc/sasldb2
RUN chsh -s /bin/bash cyrus


# Set up the mailboxes by starting the cyrus imap daemon, calling up cyradm
# and running the create mailbox commands.

# Step 1: set up a sasl password valid under the build hostname (no -u param).
# Since sasl cares about the hostname the validation doesn't work on the above
# passwords with the -u cyrus hostname.

RUN echo ${cyruspassword} | saslpasswd2 -p -c cyrus

# create a file entypoint.sh in the root directory
RUN echo -e "#!/bin/bash\n"\
"echo Running entrypoint.sh\n"\
"chown -R cyrus:mail /var/spool/imap /var/lib/imap\n"\
"/usr/lib/cyrus/bin/master\n"\
> /entrypoint.sh; \
chmod +x /entrypoint.sh

# start the cyrus server
ENTRYPOINT /entrypoint.sh
