SHELL := /bin/bash
PROJECT := $(CURDIR)
RUN := $(PROJECT)/build/container.sh

.PHONY: help bootstrap base desktop installer live shell qemu-base qemu-live status assets clean distclean

help:
	@echo "ARMOS build targets:"
	@echo "  make bootstrap   Download stage3 + Portage snapshot, extract, configure"
	@echo "  make base        Build base system (kernel, firmware, network, dracut)"
	@echo "  make desktop     Build XFCE desktop and applications"
	@echo "  make installer   Install Calamares and ARMOS installer config"
	@echo "  make live        Build live ISO"
	@echo "  make shell       Enter the build chroot"
	@echo "  make qemu-base   Boot the base system in QEMU (serial console)"
	@echo "  make qemu-live   Boot the live ISO in QEMU (BIOS; UEFI=1 for OVMF)"
	@echo "  make assets      Render SVG branding assets to PNG"
	@echo "  make status      Show build status"
	@echo "  make clean       Remove generated images and ISO"
	@echo "  make distclean   Remove rootfs and caches (destructive)"

bootstrap:
	"$(RUN)" /armos/build/bootstrap.sh

base:
	"$(RUN)" /armos/build/base.sh

desktop:
	"$(RUN)" /armos/build/desktop.sh

installer:
	"$(RUN)" /armos/build/installer.sh

live:
	"$(RUN)" /armos/build/live.sh

shell:
	ARMOS_TTY=1 "$(RUN)" /armos/build/enter-chroot.sh

qemu-base:
	"$(PROJECT)/qemu/run-base.sh"

qemu-live:
	"$(PROJECT)/qemu/run-live.sh"

assets:
	bash "$(PROJECT)/build/render-assets.sh"

status:
	@echo "Project: $(PROJECT)"
	@du -sh "$(PROJECT)/build/rootfs" 2>/dev/null || echo "rootfs: not built"
	@du -sh "$(PROJECT)/build/cache" 2>/dev/null || echo "cache: empty"
	@ls -lh "$(PROJECT)"/out/*.iso 2>/dev/null || echo "ISO: not built"

clean:
	rm -f "$(PROJECT)"/build/*.img "$(PROJECT)"/out/*.iso "$(PROJECT)"/out/*.sha256

distclean: clean
	rm -rf "$(PROJECT)/build/rootfs" "$(PROJECT)/build/cache"
