BASE_VERSION = 22.04
VERSION = 22.04.2
OS := $(shell uname)
ifeq ($(ARCH), arm64)
	BASE_URL = https://cdimage.ubuntu.com/releases/$(BASE_VERSION)/release/
else
	BASE_URL = http://releases.ubuntu.com/$(BASE_VERSION)
endif
DST_IMAGE = custom-ubuntu-$(VERSION)-$(ARCH).iso
BASE_IMAGE = ubuntu-$(VERSION)-live-server-$(ARCH).iso
WORKDIR = ./custom-ubuntu-workdir-$(ARCH)
EFI=$(WORKDIR)/boot/grub/efi.img

.PHONY: cdc download efi clean purge

all: cdc

download: $(BASE_IMAGE)

$(BASE_IMAGE):
	wget "$(BASE_URL)/$(BASE_IMAGE)"

mnt:
	mkdir -p ./mnt

mount: $(BASE_IMAGE) mnt
ifeq ($(OS),Darwin)
#--- this is a sequence where the semicolon and backslash is extremely important
	set -e ;\
	ISO_DEVICE=$$(hdiutil attach -nobrowse -nomount ./$(BASE_IMAGE) | head -1 | cut -d" " -f1) ;\
	echo "iso $$ISO_DEVICE" ;\
	sudo mount -t cd9660 $$ISO_DEVICE ./mnt
else
	sudo mount -o loop $(BASE_IMAGE) ./mnt
endif

umount:
	sudo umount ./mnt
	rmdir ./mnt

password:
	openssl passwd -6

$(WORKDIR): mnt
	mkdir -p $(WORKDIR)
	(cd mnt; sudo tar cf - .) | (cd $(WORKDIR); pwd ; tar xf - )
	chmod -R u+w $(WORKDIR)

efi: $(WORKDIR)
ifeq ($(OS),Darwin)
	SKIP=$(shell hdiutil imageinfo $(BASE_IMAGE) 2>/dev/null |grep -B 5 ESP|grep start| awk '{print $$2}');\
	COUNT=$(shell hdiutil imageinfo $(BASE_IMAGE) 2>/dev/null |grep -B 5 ESP|grep length| awk '{print $$2}');\
	dd if=$(BASE_IMAGE) bs=512 count=$$COUNT skip=$$SKIP of=$(EFI)
else
	echo "needs to be implemented"
endif

cdc: download mount $(WORKDIR) efi
	mkdir -p $(WORKDIR)/nocloud
	touch $(WORKDIR)/nocloud/meta-data # empty file must be created
	cp ./preseed/user-data $(WORKDIR)/nocloud/user-data
	sed -i '' "s/CHANGE-ARCH/$(ARCH)/g" $(WORKDIR)/nocloud/user-data
	cp ./preseed/grub.cfg $(WORKDIR)/boot/grub/grub.cfg

	cat mnt/md5sum.txt | sed -e "s~`grep './boot/grub/grub.cfg' mnt/md5sum.txt | cut -d' ' -f1`~`md5 $(WORKDIR)/boot/grub/grub.cfg | cut -d' ' -f4`~g" | tee $(WORKDIR)/md5sum.txt
	xorriso -as mkisofs -r -V 'MGB-CDC-Image' -J -joliet-long -cache-inodes -e boot/grub/efi.img -no-emul-boot -o $(DST_IMAGE) $(WORKDIR)
	sudo umount ./mnt

clean:
	rm -rf $(WORKDIR)

purge:
	rm -rf $(BASE_IMAGE)
