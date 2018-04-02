# docker build -t richardeigenmann/cyrus-docker-setup:latest .

# Do these steps to set up the mail server and the host directory:

# on the host server
# mkdir -p /absolute/path/to/the/exported/directory
# docker run -it --rm --hostname cyrus -v /absolute/path/to/the/exported/directory:/mnt richardeigenmann/cyrus-docker-setup:latest

# inside the container
# mkdir -p /mnt/lib /mnt/spool
# cp -r /var/lib/imap /mnt/lib/
# cp -r /var/spool/imap /mnt/spool/

FROM opensuse:42.3

ENV mailboxuser richi
ENV mailboxpassword password
ENV cyruspassword password

MAINTAINER Richard Eigenmann

USER root

# add the packages needed for the cyrus server and some to work with the shell
RUN zypper --non-interactive in \
  cyrus-imapd \
  cyradm \
  cyrus-sasl-saslauthd \
  cyrus-sasl-digestmd5 \
  cyrus-sasl-crammd5 \
  sudo less \
  telnet;

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

# Step 2: We can't use here-documents in docker so we create the instructions
# that cyradm needs to execute in a text file

RUN echo -e "createmailbox user.${mailboxuser}\ncreatemailbox user.${mailboxuser}.Archive\nexit" > /createmailbox.commands

# Step 3: Start the daemon and in the same build container run the cyradm command
# (note the ; \  at the end of the line!)

RUN /sbin/startproc -p /var/run/cyrus-master.pid /usr/lib/cyrus/bin/master -d; \
sudo -u cyrus -i cyradm --user cyrus -w ${cyruspassword} localhost < /createmailbox.commands; \
mv /createmailbox.commands /createmailbox.commands.completed;

ENTRYPOINT bash
