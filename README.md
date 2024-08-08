# Cyrus-Docker
Run Cyrus Imapd in a Docker container

Cyrus needs state which it keeps in
* /var/lib/imap
* /var/spool/imap
* /etc/sasldb2 # Authentication

It needs two passwords which we supply in the .env file
* Password for user cyrus
* name and password for mailbox user

```bash
cp .env.template .env
vi .env
# Define your user and passwords
```

To build the mailbox environment go to the SetupServer subdirectory and

```bash
cd SetupServer
source ../.env && docker build --build-arg mailboxuser=${mailboxuser} --build-arg mailboxpassword=${mailboxpassword} --build-arg cyruspassword=${cyruspassword} -t richardeigenmann/cyrus-docker-setup:latest .
mkdir -p /absolute/path/to/the/exported/directory
docker run -it --rm --hostname cyrus -v /absolute/path/to/the/exported/directory:/mnt richardeigenmann/cyrus-docker-setup:latest

# inside the container
mkdir -p /mnt/lib /mnt/spool
cp -rv /var/lib/imap /mnt/lib/
cp -rv /var/spool/imap /mnt/spool/
exit
```

The cyrus-docker-setup container is not needed any longer

Next start the server:

```bash
docker-compose up -d --build
```

To explore the running container:
```bash
docker exec -it  cyrus-docker bash
sudo -u cyrus -i cyradm --user cyrus -w <<cyruspassword>> localhost
sudo -u cyrus -i cyradm --user richi -w <<cyruspassword>> localhost
# The storage units are, as defined in RFC 2087, groups of 1024 octets (i.e. Kilobytes). see https://www.cyrusimap.org/imap/reference/manpages/systemcommands/cyradm.html
setquota user.richi STORAGE 6000000
```
