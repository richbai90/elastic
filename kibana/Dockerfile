FROM docker.elastic.co/kibana/kibana-oss:6.7.1
LABEL env="test"
LABEL ver="6.8.5.a"
# install plugins
RUN /usr/share/kibana/bin/kibana-plugin install https://github.com/fbaligand/kibana-enhanced-table/releases/download/v1.1.0/enhanced-table-1.1.0_6.7.1.zip
RUN /usr/share/kibana/bin/kibana-plugin install https://github.com/datasweet/kibana-datasweet-formula/releases/download/v2.1.0/datasweet_formula-2.1.0_kibana-6.7.1.zip
RUN /usr/share/kibana/bin/kibana-plugin install https://github.com/sivasamyk/logtrail/releases/download/v0.1.31/logtrail-6.7.1-0.1.31.zip
RUN /usr/share/kibana/bin/kibana-plugin install https://github.com/bitsensor/elastalert-kibana-plugin/releases/download/1.0.3/elastalert-kibana-plugin-1.0.3-6.7.1.zip
RUN /usr/share/kibana/bin/kibana-plugin install https://bitbucket.org/bittercreek_projects/kibana-supportworks-build/raw/2c1ea9a981ee4a518fe805fc7bb2707a88ad6506/supportworks-6.8.5%2Balpha.1.kbn.6.7.1.zip
RUN echo $'supportworks.elasticsearch.url: http://elasticsearch:9200\n\
elasticsearch.hosts: ["http://localhost:19200"]\n\
server.host: 0.0.0.0\n\
elasticsearch.requestHeadersWhitelist: [ x-proxy-user, cookie ]\n\
supportworks.session.secretkey: the-password-must-be-at-least-32-characters-long\n\
supportworks.session.isSecure: false\n\
supportworks.remote_user: session\n\
elastalert-kibana-plugin.serverHost: elastalert\n\
server.defaultRoute: /app/supportworks' > /usr/share/kibana/config/kibana.yml
RUN rm -rf /usr/share/kibana/optimize/bundles
ENV NODE_OPTIONS="--max-old-space-size=4096"