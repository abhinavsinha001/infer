FROM alpine
RUN apk add alpine-sdk opam python openjdk8 autoconf automake bash gmp-dev sqlite-dev zlib-dev mpfr-dev tzdata

#Export JAVE_HOME and javac path
ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk
ENV PATH="$JAVA_HOME/bin:${PATH}"

# Set TimeZone
ENV TZ=America/Los_Angeles
RUN cp -rf /usr/share/zoneinfo/$TZ /etc/localtime

RUN git clone https://github.com/abhinavsinha001/infer.git

#RUN addgroup -S app && adduser -S -G app app 
#USER app
RUN opam init --reinit --bare --disable-sandboxing
RUN cd infer && ./build-infer.sh java

RUN cd infer && make install
