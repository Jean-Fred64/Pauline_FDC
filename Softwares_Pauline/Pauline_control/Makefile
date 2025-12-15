#CC=i386-pc-linux-gcc
CC=gcc

UNAME := $(shell uname)

INCLUDES = -I./inc -I../HxCFloppyEmulator/libhxcfe/sources

DEBUG ?= 0
LIBS=

# Définir TARGET_ROOTFS si non défini (pour compilation locale)
TARGET_ROOTFS ?= ../HxCFloppyEmulator/build

# Détecter si on compile pour ARM
ifneq ($(findstring arm,$(CC)),)
    # Cross-compilation ARM : chercher libpng pour ARM
    PNG_LIB_PATH := $(shell find /usr -name "libpng*.so" -path "*/arm-linux-gnueabihf/*" 2>/dev/null | head -1 | xargs dirname)
    ifneq ($(PNG_LIB_PATH),)
        LDFLAGS_PNG = -L$(PNG_LIB_PATH) -lpng
    else
        # Essayer les chemins standards
        LDFLAGS_PNG = -L/usr/arm-linux-gnueabihf/lib -lpng
    endif
    # Pour ARM, utiliser -L et -l pour chercher par nom, avec rpath pour /lib à l'exécution
    LIBHXCFE_LDFLAGS = -L${TARGET_ROOTFS} -lhxcfe -Wl,-rpath=/lib
else
    # Compilation native
    LDFLAGS_PNG = -lpng
    LIBHXCFE_LDFLAGS = ${TARGET_ROOTFS}/libhxcfe.so
endif

ifeq ($(DEBUG), 1)
	CFLAGS=-O0 $(INCLUDES) -Wall -I ../wsServer/include/ -g -rdynamic -DDEBUG -funwind-tables #-fsanitize=address -fno-omit-frame-pointer
	LDFLAGS= -lc -lm -ldl -lpthread -rdynamic ${LIBHXCFE_LDFLAGS} ../wsServer/libws.a
else
	CFLAGS=-O3 $(INCLUDES) -Wall -I ../wsServer/include/ -g -rdynamic -funwind-tables
	LDFLAGS= -lc -lm -ldl -lpthread -rdynamic ${LIBHXCFE_LDFLAGS} ../wsServer/libws.a
endif

sources := $(wildcard src/*.c)
objects := $(sources:src/%.c=obj/%.o)

# Ajouter les flags supplémentaires (rpath pour le répertoire courant, map, et PNG)
# Pour ARM, forcer l'interpréteur dynamique correct
ifneq ($(findstring arm,$(CC)),)
    LDFLAGS += -Wl,-rpath=. -Wl,-Map,foo.map -Wl,--dynamic-linker=/lib/ld-linux.so.3 $(LDFLAGS_PNG)
else
    LDFLAGS += -Wl,-rpath=. -Wl,-Map,foo.map $(LDFLAGS_PNG)
endif

EXEC=pauline

all: output_dir $(EXEC)

pauline:  $(objects)
	${CC} -o $@    $^ $(LDFLAGS)

$(objects): obj/%.o: src/%.c
	${CC} -o $@ $^ -c $(CFLAGS)

clean:
	rm -rf obj/*.o
	rm -rf obj/*.so
	rm -rf $(EXEC)
	rm -rf *.map

mrproper: clean
	-rm -fR obj

output_dir:
	@mkdir -p obj

.PHONY: clean mrproper
