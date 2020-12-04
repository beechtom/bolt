FROM rastasheep/ubuntu-sshd:18.04 AS base
RUN apt-get update && apt-get -y install sudo tree locales apt-transport-https
RUN locale-gen en_US.UTF-8

ENV LC_ALL="en_US.UTF-8"
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US.UTF-8"

# Add bolt user with authorized key
RUN useradd bolt && echo "bolt:bolt" | chpasswd && adduser bolt sudo
RUN mkdir -p /home/bolt/.ssh/
COPY fixtures/keys/id_rsa.pub /home/bolt/.ssh/id_rsa.pub
COPY fixtures/keys/id_rsa.pub /home/bolt/.ssh/authorized_keys
RUN chmod 700 /home/bolt/.ssh/
RUN chmod 600 /home/bolt/.ssh/authorized_keys
RUN chown -R bolt:sudo /home/bolt

# Add test user without authorized key and different login shell
RUN useradd test && echo "test:test" | chpasswd && adduser test sudo
RUN echo test | chsh -s /bin/bash test
RUN mkdir -p /home/test/.ssh
COPY fixtures/keys/id_rsa.pub /home/test/.ssh/id_rsa.pub
COPY fixtures/keys/id_rsa.pub /home/test/.ssh/authorized_keys
RUN chmod 700 /home/test/.ssh/
RUN chmod 600 /home/test/.ssh/authorized_keys
RUN chown -R test:sudo /home/test

CMD ["/usr/sbin/sshd", "-D"]

FROM base AS puppet5
RUN wget https://apt.puppetlabs.com/puppet5-release-bionic.deb \
    && sudo dpkg -i puppet5-release-bionic.deb \
    && sudo apt update \
    && sudo apt-get install puppet-agent
CMD ["/usr/sbin/sshd", "-D"]

FROM base AS puppet6
RUN wget https://apt.puppetlabs.com/puppet6-release-bionic.deb \
    && sudo dpkg -i puppet6-release-bionic.deb \
    && sudo apt update \
    && sudo apt-get install puppet-agent
CMD ["/usr/sbin/sshd", "-D"]

FROM base AS puppet7
RUN wget https://apt.puppetlabs.com/puppet7-release-bionic.deb \
    && sudo dpkg -i puppet7-release-bionic.deb \
    && sudo apt update \
    && sudo apt-get install puppet-agent
CMD ["/usr/sbin/sshd", "-D"]
