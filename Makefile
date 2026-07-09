# Makefile para simple-scan
# Uso:  sudo make install   |   sudo make uninstall

PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
BINS   := simple-scan

.PHONY: install uninstall

install:
	@command -v nmap >/dev/null 2>&1 || { echo "nmap no instalado: sudo apt install nmap"; exit 1; }
	install -d $(DESTDIR)$(BINDIR)
	for b in $(BINS); do install -m 0755 $$b $(DESTDIR)$(BINDIR)/$$b; echo "Instalado $(DESTDIR)$(BINDIR)/$$b"; done

uninstall:
	for b in $(BINS); do rm -f $(DESTDIR)$(BINDIR)/$$b; echo "Eliminado $(DESTDIR)$(BINDIR)/$$b"; done
