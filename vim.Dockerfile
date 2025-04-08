FROM debian:latest AS neovim-image
ARG NVIM_VERSION=stable
ARG NVIM_ARCH=-linux-x86_64
ADD --chmod=755 https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim${NVIM_ARCH}.appimage /nvim-linux-x86_64.appimage
RUN /nvim-linux-x86_64.appimage --appimage-extract

FROM debian:latest AS vim-image
ARG VIM_VERSION=v9.1.1287
ADD --chmod=755 https://github.com/vim/vim-appimage/releases/download/${VIM_VERSION}/Vim-${VIM_VERSION}.glibc2.29-x86_64.AppImage /vim-linux-x86_64.appimage
RUN /vim-linux-x86_64.appimage --appimage-extract

FROM python:latest AS base
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      git \
      ca-certificates \
      make

FROM base AS test-prep
WORKDIR /work
COPY test/new/requirements.txt test/new/requirements.txt
COPY test/new/Makefile test/new/Makefile
RUN cd test/new && make env
RUN mkdir -p test/vader/vader.vim && git clone --depth=1 https://github.com/junegunn/vader.vim.git test/vader/vader.vim

FROM python:latest AS nvim

# nvim
COPY --from=neovim-image /squashfs-root /nvim-root
RUN ln -s /nvim-root/AppRun /bin/nvim

# vim
COPY --from=vim-image /squashfs-root /vim-root
RUN ln -s /vim-root/AppRun /bin/vim

WORKDIR /work
ENV HOME=/work
ENV GIT_PAGER=cat

COPY . .
COPY --from=test-prep /work/test test

ENTRYPOINT ["bash"]
