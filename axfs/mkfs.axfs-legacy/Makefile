INC = -I./
CFLAGS = -g $(INC) -O0

MKFSOBJS = mkfs.axfs.o

# These packages are required for rebuilding from source
# sudo apt-get install zlibc zlib1g zlib1g-dev

all:   mkfs.axfs

mkfs.axfs: $(MKFSOBJS)
	$(CC) $(CFLAGS) -o mkfs.axfs $(MKFSOBJS) -lz

clean_mkfs.axfs:
	rm -rf $(MKFSOBJS) mkfs.axfs

clean: clean_mkfs.axfs
	rm -rf *.c~ Makefile~
