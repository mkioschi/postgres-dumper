FROM alpine:3.13

RUN apk update \
	&& apk add coreutils \
	&& apk add postgresql-client \
    && apk add tzdata \
    && apk add nano \
    && apk add openssl \
	&& apk add python3 py3-pip && pip3 install --upgrade pip && pip3 install awscli

RUN cp /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime \
    && echo "America/Sao_Paulo" > /etc/timezone \
    && date

RUN rm /etc/crontabs/root

ADD bin/* /bin/dumper/

ADD scheduler /etc/crontabs/root

CMD ["sh", "/bin/dumper/entrypoint.sh"]