FROM docker.elastic.co/beats/filebeat:8.13.0

# Copy in your tuned config
COPY filebeat.yml /usr/share/filebeat/filebeat.yml

USER root
RUN chown root:root /usr/share/filebeat/filebeat.yml \
 && chmod go-w /usr/share/filebeat/filebeat.yml

USER filebeat

