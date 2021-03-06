
########################################################################################################################
# General variables. Twiddle as you see fit.
########################################################################################################################

KEY_BITS = 2048

OPENSSL_DIR = ../openssl
OPENSSL = $(OPENSSL_DIR)/apps/openssl

CC = /usr/bin/cc
STRIP = /usr/bin/strip

BIN_DIR = /usr/local/bin
MAN_DIR = /usr/share/man/man1/


########################################################################################################################
# Build specifications. Pick one and uncomment.
########################################################################################################################

## Linux w/static libraries. (Full static build.)
CFLAGS = -static -Wall -Wextra -std=c99 -pedantic -Os -DOPENSSL -I$(OPENSSL_DIR)/include
STATIC_LIBS = $(OPENSSL_DIR)/libssl.a $(OPENSSL_DIR)/libcrypto.a
LIBS = 
KEYS_DIR = keys
KEY_OF_C = in_the_key_of_c
IO_DEP = io_ssl.c

## FreeBSD
## NOTE: 
##	You'll want to change MAN_DIR variable above.
##	Also, tun/tap support doesn't exist for you yet. Sorry. (But everything else should work fine.)
#CFLAGS = -Wall -Wextra -std=c99 -pedantic -Os -DFREEBSD -DOPENSSL
#LIBS = -lssl -lcrypto
#KEYS_DIR = keys
#KEY_OF_C = in_the_key_of_c
#IO_DEP = io_ssl.c

## Linux - Dynamically Linked
## NOTE:
##	I've left this one in, but I think of it as deprecated as it tends to be fragile.
##	Building OpenSSL in statically will be much more robust.
#CFLAGS = -Wall -Wextra -std=c99 -pedantic -Os -DOPENSSL
#LIBS = -lssl -lcrypto
#KEYS_DIR = keys
#KEY_OF_C = in_the_key_of_c
#IO_DEP = io_ssl.c

## Linux w/compatability mode. (Plain text, no SSL.)
## NOTE:
##	You almost certainly don't want this one. It's here mostly for research and exotic use.
##	This version is also deprecated, but probably still works.
#CFLAGS = -Wall -Wextra -std=c99 -pedantic -Os
#LIBS = 
#KEYS_DIR = 
#KEY_OF_C = 
#IO_DEP = io_nossl.c


########################################################################################################################
# make directives - Not intended for modification.
########################################################################################################################


OBJS = string_to_vector.o io.o report.o control.o target.o handler.o broker.o message.o proxy.o escseq.o

all: revsh

revsh: revsh.c helper_objects.h common.h config.h $(KEY_OF_C) $(KEYS_DIR) $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o revsh revsh.c $(STATIC_LIBS) $(LIBS)
	$(STRIP) ./revsh
	@/bin/echo
	@/bin/echo "Build succesful. Enjoy!";
	@/bin/echo

keys:
	if [ ! -e $(KEYS_DIR) ]; then \
		mkdir $(KEYS_DIR) ; \
	fi
	if [ ! -e $(KEYS_DIR)/dh_params.c ]; then \
    $(OPENSSL) dhparam -noout -C $(KEY_BITS) >$(KEYS_DIR)/dh_params.c ; \
		echo "DH *(*get_dh)() = &get_dh$(KEY_BITS);" >>$(KEYS_DIR)/dh_params.c ; \
  fi
	if [ ! -e $(KEYS_DIR)/control_key.pem ]; then \
		$(OPENSSL) req -batch -newkey rsa:$(KEY_BITS) -nodes -x509 -days 36500 -keyout $(KEYS_DIR)/control_key.pem -out $(KEYS_DIR)/control_cert.pem -config $(OPENSSL_DIR)/apps/openssl.cnf ; \
	fi
	if [ ! -e $(KEYS_DIR)/target_key.pem ]; then \
    $(OPENSSL) req -batch -newkey rsa:$(KEY_BITS) -nodes -x509 -days 36500 -keyout $(KEYS_DIR)/target_key.pem -out $(KEYS_DIR)/target_cert.pem -config $(OPENSSL_DIR)/apps/openssl.cnf ; \
	fi
	if [ ! -e $(KEYS_DIR)/control_fingerprint.c ]; then \
		./in_the_key_of_c -c $(KEYS_DIR)/control_cert.pem -f >$(KEYS_DIR)/control_fingerprint.c ; \
	fi
	if [ ! -e $(KEYS_DIR)/target_key.c ]; then \
		./in_the_key_of_c -k $(KEYS_DIR)/target_key.pem >$(KEYS_DIR)/target_key.c ; \
	fi
	if [ ! -e $(KEYS_DIR)/target_cert.c ]; then \
		./in_the_key_of_c -c $(KEYS_DIR)/target_cert.pem >$(KEYS_DIR)/target_cert.c ; \
	fi

string_to_vector.o: string_to_vector.c
	$(CC) $(CFLAGS) -c -o string_to_vector.o string_to_vector.c

io.o: $(IO_DEP) io.c common.h config.h helper_objects.h
	$(CC) $(CFLAGS) -c -o io.o io.c

report.o: report.c common.h config.h helper_objects.h
	$(CC) $(CFLAGS) -c -o report.o report.c

control.o: control.c common.h config.h helper_objects.h
	$(CC) $(CFLAGS) -c -o control.o control.c

target.o: target.c common.h config.h helper_objects.h
	$(CC) $(CFLAGS) -c -o target.o target.c

handler.o: handler.c common.h config.h helper_objects.h
	$(CC) $(CFLAGS) -c -o handler.o handler.c

broker.o: broker.c common.h config.h helper_objects.h
	$(CC) $(CFLAGS) -c -o broker.o broker.c

message.o: message.c common.h config.h helper_objects.h
	$(CC) $(CFLAGS) -c -o message.o message.c

proxy.o: proxy.c common.h config.h helper_objects.h
	$(CC) $(CFLAGS) -c -o proxy.o proxy.c

escape.o: escseq.c common.h config.h helper_objects.h
	$(CC) $(CFLAGS) -c -o escseq.o escseq.c

in_the_key_of_c: in_the_key_of_c.c
	@/bin/echo
	$(CC) $(CFLAGS) -o in_the_key_of_c in_the_key_of_c.c $(STATIC_LIBS) $(LIBS)

install:
	if [ ! -e $(HOME)/.revsh ]; then \
		mkdir $(HOME)/.revsh ; \
	fi
	if [ $(KEYS_DIR) ] && [ -e $(HOME)/.revsh/$(KEYS_DIR) ]; then \
		echo "\nERROR: $(HOME)/.revsh/$(KEYS_DIR) already exists! Move it safely out of the way then try again, please." ; \
	else \
		if [ $(KEYS_DIR) ]; then \
			cp -r $(KEYS_DIR) $(HOME)/.revsh ; \
			cp -f revsh $(HOME)/.revsh/$(KEYS_DIR) ; \
		fi ; \
		if [ ! -e $(BIN_DIR) ]; then \
			echo "\nERROR: $(BIN_DIR) does not exist!" ; \
		fi ; \
		cp -f revsh $(BIN_DIR) ; \
		if [ ! -e $(MAN_DIR) ]; then \
			echo "\nERROR: $(MAN_DIR) does not exist!" ; \
		fi ; \
		cp -f Documentation/revsh.1 $(MAN_DIR) ; \
		gzip $(MAN_DIR)/revsh.1 ; \
		if [ ! -e $(HOME)/.revsh/rc ]; then \
			cp rc $(HOME)/.revsh/ ; \
		fi \
	fi

# "make dirty" deletes executables and object files.
dirty:
	rm -f revsh $(OBJS) $(KEY_OF_C) 

# "make clean" calls "make dirty", then also removes the keys folder.
clean: dirty
	if [ -n "$(KEYS_DIR)" ] && [ -e "$(KEYS_DIR)" ]; then \
		rm -rf $(KEYS_DIR) ; \
	fi

uninstall:
	if [ -e $(HOME)/.revsh ]; then \
		rm -rf $(HOME)/.revsh; \
	fi
	if [ -e $(BIN_DIR)/revsh ]; then \
		rm -rf $(BIN_DIR)/revsh; \
	fi
	if [ -e $(MAN_DIR)/revsh.1 ]; then \
		rm -rf $(MAN_DIR)/revsh.1; \
	fi 
	if [ -e $(MAN_DIR)/revsh.1.gz ]; then \
		rm -rf $(MAN_DIR)/revsh.1.gz; \
	fi 

