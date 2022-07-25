VERSION ?= 0.0.1
COMMIT  ?= $(shell git rev-parse --short HEAD)
PROJECT ?= beltwiz
MODDIR  ?= $(HOME)/.factorio/mods

FULL_NAME = $(PROJECT)_$(VERSION)
ZIP_NAME = $(FULL_NAME).zip

S = src
O = $(FULL_NAME)
SRCS = $(shell find $(S) -type f)
OBJS = $(SRCS:$(S)/%=$(O)/%)

release: $(OBJS)
	zip -qr $(ZIP_NAME) $(O)

link:
	ln -sf $(CURDIR)/src $(MODDIR)/$(FULL_NAME)

unlink:
	rm -f -- $(MODDIR)/$(FULL_NAME)

clean:
	rm -rf -- $(O) $(ZIP_NAME)

$(OBJS): $(O)/%: $(S)/%
	@mkdir -p -- $(dir $@)
	cp -- $< $@ 

