
FROM phusion/baseimage

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -

RUN	apt-get update && \
	apt-get install -y software-properties-common && \
	add-apt-repository ppa:gophers/archive &&\
	add-apt-repository -y ppa:ethereum/ethereum && \
	apt-get update && \
	apt-get install -y git nodejs && \
	apt-get install -y golang-1.10-go && \
	apt-get install -y ethereum  && \
	apt-get install -y netcat && \
	rm -rf /var/lib/apt/lists/*


RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update && \
	apt-get install --no-install-recommends yarn

#for some reason, npm install -g chokes. so we install them "locally", in the root folder.
RUN npm install ganache-cli truffle

#need to select which version we install: default is (right now) 0.5.5
RUN curl -L -o /usr/local/bin/solc-5.10 https://github.com/ethereum/solidity/releases/download/v0.5.10/solc-static-linux && chmod a+rx /usr/local/bin/solc-5.10
RUN ln -s /usr/local/bin/solc-5.10 /usr/local/bin/solc
#RUN apt-get install -y solc

WORKDIR /relayserver

COPY . .
RUN yarn
ENV PS1 "\e[31min-docker\e[0m \W \$ "
RUN echo "export PS1=\"$PS1\"" >> /etc/bash.bashrc
RUN echo "export PS1=\"$PS1\"" >> /root/.bashrc
ENV PATH /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/node_modules/.bin:/usr/lib/go-1.10/bin

EXPOSE 8545
EXPOSE 8090

CMD "./restart-relay.sh"