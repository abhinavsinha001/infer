FROM alpine
RUN apk add --virtual build-deps alpine-sdk opam python2 openjdk8 autoconf automake bash gmp-dev sqlite-dev zlib-dev mpfr-dev tzdata linux-headers bash

ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk
ENV PATH="$JAVA_HOME/bin:${PATH}"

# Set TimeZone
ENV TZ=America/Los_Angeles
RUN cp -rf /usr/share/zoneinfo/$TZ /etc/localtime
RUN echo "cache buster2"
RUN git clone -b 0.17.0 https://github.com/abhinavsinha001/infer.git
RUN opam init --reinit --bare --disable-sandboxing
RUN cd infer && ./build-infer.sh java

RUN cd infer && make install

RUN apk del build-deps
