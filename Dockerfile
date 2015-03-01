FROM debian:wheezy
MAINTAINER whoami <who@am.i>

ADD ./sources.list  /etc/apt/sources.list

RUN apt-get -y update
RUN apt-get -y install software-properties-common \
		       python-software-properties

RUN apt-get -y install git \
                       nodejs

RUN apt-get -y install python-django \
                       python-django-tagging \
                       python-simplejson \
                       python-memcache \
                       python-ldap \
                       python-cairo \
                       python-twisted \
                       python-pysqlite2 \
                       python-support \
                       python-pip




# carbon, and whisper
WORKDIR /usr/local/src
RUN git clone https://github.com/graphite-project/graphite-web.git
RUN git clone https://github.com/graphite-project/carbon.git
RUN git clone https://github.com/graphite-project/whisper.git
RUN cd whisper && git checkout master && python setup.py install
RUN cd carbon && git checkout 0.9.x && python setup.py install
RUN cd graphite-web && git checkout 0.9.x && python check-dependencies.py; python setup.py install


# config files
ADD initial_data.json /opt/graphite/webapp/graphite/initial_data.json 
ADD local_settings.py /opt/graphite/webapp/graphite/local_settings.py 
ADD carbon.conf /opt/graphite/conf/carbon.conf
ADD storage-schemas.conf /opt/graphite/conf/storage-schemas.conf
ADD storage-aggregation.conf /opt/graphite/conf/storage-aggregation.conf

RUN mkdir -p /opt/graphite/storage/whisper
RUN touch /opt/graphite/storage/graphite.db /opt/graphite/storage/index
RUN chown -R www-data /opt/graphite/storage
RUN chmod 0775 /opt/graphite/storage /opt/graphite/storage/whisper
RUN chmod 0664 /opt/graphite/storage/graphite.db
RUN cd /opt/graphite/webapp/graphite && python manage.py syncdb --noinput

RUN apt-get -y install gunicorn
RUN mkdir -p /opt/graphite/webapp



#EXPOSE 2003 2004 7002

RUN mkdir /src && git clone https://github.com/etsy/statsd.git /src/statsd
ADD config.js /src/statsd/config.js

EXPOSE 8125/udp 8126 8000

CMD ["/usr/bin/nodejs", "/src/statsd/stats.js", "/src/statsd/config.js"]
CMD ["/opt/graphite/bin/carbon-cache.py", "--debug", "start"]


# make use of cache from dockerana/carbon
WORKDIR /opt/graphite/webapp

ENV GRAPHITE_STORAGE_DIR /opt/graphite/storage
ENV GRAPHITE_CONF_DIR /opt/graphite/conf
ENV PYTHONPATH /opt/graphite/webapp

CMD ["/usr/bin/gunicorn_django", "-b0.0.0.0:8000", "-w2", "graphite/settings.py"]
