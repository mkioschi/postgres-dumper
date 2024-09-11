FROM python:3.12-alpine3.20

RUN apk update && \
    apk add coreutils \
        tzdata \
        nano \
        openssl \
        py3-pip \
        postgresql16-client
    
RUN pip3 install --upgrade pip && \
    pip3 install awscli

RUN cp /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime \
    && echo "America/Sao_Paulo" > /etc/timezone \
    && date

RUN rm /etc/crontabs/root

ADD bin/* /bin/dumper/

ADD scheduler /etc/crontabs/root

CMD ["sh", "/bin/dumper/entrypoint.sh"]