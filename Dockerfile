ARG CENTOS_VERSION=8
ARG USER_NAME="user"

FROM centos:${CENTOS_VERSION} as base
ARG USER_NAME

ENV PATH="/home/${USER_NAME}/.pyenv/bin:$PATH"
ENV LC_ALL="C.UTF-8"
ENV LANG="C.UTF-8"

FROM base as builder
ARG USER_NAME

RUN dnf install @development zlib-devel bzip2 bzip2-devel readline-devel sqlite \
sqlite-devel openssl-devel xz xz-devel libffi-devel findutils git which -y

RUN useradd -s /usr/bin/bash -u 1000 -G wheel ${USER_NAME}

WORKDIR /home/${USER_NAME}/build/

COPY . .

RUN chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

USER ${USER_NAME}

RUN curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

RUN pyenv install $(cat .python-version) \
  && eval "$(pyenv init -)" \
  && pyenv global $(cat .python-version) \
  && pip3 install --upgrade pip pipenv \
  && pipenv install --skip-lock --system

RUN echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> /home/${USER_NAME}/.bashrc

#---------------- NEXT STAGE ----------------#
FROM base
ARG USER_NAME

RUN dnf install epel-release -y \
  && dnf install openssh-clients sshpass -y \
  && dnf clean all \
  && rm -rf /var/cache/dnf

# This is needed to Run in Jenkins as Container
RUN useradd -s /usr/bin/bash -u 1000 -G wheel ${USER_NAME}

USER ${USER_NAME}

COPY --from=builder /home/${USER_NAME}/ /home/${USER_NAME}/
