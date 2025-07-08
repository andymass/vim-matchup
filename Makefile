PHONY: docker_build docker_test_nvim

RUNFOR ?= nvim
VIMCMD = $(shell if [ $(RUNFOR) = nvim ]; then echo "nvim --headless"; else echo "vim -T dumb --not-a-term -n"; fi)
VIMCMD != if [ $(RUNFOR) = nvim ]; then echo "nvim --headless"; else echo "vim -T dumb --not-a-term -n"; fi
NVIM_VERSION ?= stable
NVIM_ARCH ?= -linux-x86_64
VIM_VERSION ?= v9.1.1287

docker_build:
	docker build --tag 'vim-matchup-nvim-stable' \
	  --file vim.Dockerfile \
	  --build-arg NVIM_VERSION=${NVIM_VERSION} \
	  --build-arg NVIM_ARCH=${NVIM_ARCH} \
	  --build-arg VIM_VERSION=${VIM_VERSION} \
	  .

docker_test_old: docker_build
	docker run --rm -it --pull=never --name nvim vim-matchup-nvim-stable -c 'VIMCMD="${VIMCMD}" test/vader/run'

docker_test_new: docker_build
	docker run --rm -it --pull=never --name nvim vim-matchup-nvim-stable -c 'cd ./test/new && make -j1 MYVIM="${VIMCMD}"'

docker_test_shell: docker_build
	docker run --rm -it --pull=never --name nvim vim-matchup-nvim-stable
