# What is Joomla?

> Joomla! is a PHP content management system (CMS) for publishing web content. It includes features such as page caching, RSS feeds, printable versions of pages, news flashes, blogs, search, and support for non-english languages

https://www.joomla.org/

# TL;DR
### Install
  #### Using DECK
  Install Joomla from the DECK marketplace and follow the instructions on the GUI

### From terminal with Docker

```console
$  git clone https://github.com/deck-app/joomla
$  cd joomla
$  docker-compose up -d
```

Edit .env [Environment Variables](#environment-variables)  file to change any settings before installing like php, nginx versions etc.

    `docker-compose up -d`

#### Modifying project settings
From the DECK app, go to stack list and click on project's ` More > configure > Advanced configuration` Follow the instructions below and restart your stack from the GUI

### Edit Nginx configuration
httpd.conf is located at `./joomla/default.conf`


### Edit Apache configuration
httpd.conf is located at `./joomla/httpd.conf`

### Editing php.in
PHP ini file is located at `./joomla/php.ini`

### Installing / removing PHP extensions
Add / remove PHP extensions from `./apache/Dockerfile-{YOUR.PHP.VERSION}`
```
RUN apk add --update --no-cache bash \
                curl \
                curl-dev \
                php8-intl \
                php8-openssl \
                php8-dba \
                php8-sqlite3 \
```
### Rebuilding from terminal
You have to rebuild the docker image after you make any changes to the project configuration, use the snippet below to rebuild and restart the stack
```
docker-compose stop && docker-compose up --build -d
```
