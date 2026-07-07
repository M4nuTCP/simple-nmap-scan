# Makefile para simple-scan
# Uso:  sudo make install   |   sudo make uninstall

PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
BIN    := simple-scan

.PHONY: install uninstall

install:
	@command -v nmap >/dev/null 2>&1 || { echo "nmap no instalado: sudo apt install nmap"; exit 1; }
	install -d $(DESTDIR)$(BINDIR)
	install -m 0755 $(BIN) $(DESTDIR)$(BINDIR)/$(BIN)
	@echo "Instalado en $(DESTDIR)$(BINDIR)/$(BIN)"

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(BIN)
	@echo "Eliminado $(DESTDIR)$(BINDIR)/$(BIN)"
