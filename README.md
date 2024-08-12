# Cyrus-Docker
Run Cyrus Imapd in a Docker container

Note: It doesn't work any more! sasl authentication isn't working.

Cyrus needs state which it keeps in
* /var/lib/imap
* /var/spool/imap
* /etc/sasldb2 # For Authentication

It needs two passwords which we supply in the .env file
* Password for user cyrus
* name and password for the mailbox users

```bash
vi .env # Define your user and passwords
vi docker-compose.yml 
# change the paths to the imap folders to where you want them on the filesystem
docker create network RichiNetXps  # or change it in the yml file above
docker-compose up -d --build
```

In this example I have user alice and bob with password1 and password2

I map the folders where imapd stores its stuff to outside the container for backups etc.

/richi/Privat/Data/Cyrus/lib/imap to /var/lib/imap in the container
/richi/Privat/Data/Cyrus/spool/imap to /var/spool/imap in the container


To explore the running container:
```bash
docker exec -it  cyrus-docker bash

sasldblistusers2 # lists the users

tail -f /var/log/imapd.log /var/log/auth.log & # tail the log

ps aux # show the background processes note saslauthd 

zypper in netcat-openbsd # install nc program
nc -vz localhost 143 # prove that imapd is running

# This should succeed but fails:
testsaslauthd -u alice -p password1 -f /run/sasl2/mux
# Error: cyrus saslauthd[13]: DEBUG: auth_pam: pam_authenticate failed: User not known to the underlying authentication module

# If we change the /etc/pam.d/imap file to look like this and restart saslauthd

cyrus:/etc/pam.d # cat imap 
#%PAM-1.0
auth      sufficient     libsasldb.so  debug 
account   sufficient     libsasldb.so  debug 

saslauthd -d -a PAM -n1 -O log_level=10 &

testsaslauthd -u alice -p password1 -f /run/sasl2/mux
# Error: cyrus saslauthd[94]: DEBUG: auth_pam: pam_authenticate failed: Permission denied

# permissions of the password file
ls -l /etc/sasldb2
chmod g+r /etc/sasldb2
chmod o+r /etc/sasldb2
```


# What's going on

/usr/lib/cyrus/master reads /etc/imapd.conf
This says sasl_pwcheck_method: saslauthd
saslauthd might be reading /etc/sysconfig/saslauthd
This says SASLAUTHD_AUTHMECH=pam
Pam in turn reads /etc/security/pam_env.conf but this only has comments
