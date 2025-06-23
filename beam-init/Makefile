CC ?= gcc
CFLAGS = -Wall -Os -static -fno-strict-aliasing
LDFLAGS = -static -s

TARGET = beam-init

all: $(TARGET)

$(TARGET): beam-init.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

install:
	install -D -m 0755 $(TARGET) $(DESTDIR)/sbin/$(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all install clean