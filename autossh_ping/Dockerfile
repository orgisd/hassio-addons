ARG BUILD_FROM
FROM $BUILD_FROM

# Add env
ENV LANG C.UTF-8

# Install requirements for add-on
RUN \
  apk add --no-cache \
    tzdata jq openssh curl autossh

# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]