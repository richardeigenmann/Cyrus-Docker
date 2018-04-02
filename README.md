# Cyrus-Docker
Run Cyrus Imapd in a Docker container

Cyrus needs state which it keeps in
* /var/lib/imap
* /var/spool/imap
* /etc/sasldb2 # Authentication

It needs two passwords:
* Password for user cyrus
* name and password for mailbox user

To build the mailbox environment go to the SetupServer subdirectory and

```bash
vi Dockerfile # and edit the mailboxuser, mailboxpassword and cyruspassword variables
docker build -t richardeigenmann/cyrus-docker-setup:latest .
mkdir -p /absolute/path/to/the/exported/directory
docker run -it --rm --hostname cyrus -v /absolute/path/to/the/exported/directory:/mnt richardeigenmann/cyrus-docker-setup:latest
exit
```

The cyrus-docker-setup container is not needed any logner

Now cd back to the main directory and configure the Cyrus imapd mailserver:

```bash
vi docker-compose-yml # and edit the mailboxuser, mailboxpassword and cyruspassword
```

Next start the server:

```bash
docker-compose up -d --build
```

To explore the running container:
```bash
docker exec -it  cyrus-docker bash
```
