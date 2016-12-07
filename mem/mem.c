#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/mman.h>
#include <sys/user.h>
#include <sys/types.h>

#ifndef PAGE_SIZE
#define PAGE_SIZE 0x1000
#endif

static void print_buffer(unsigned long addr, int count, int width, unsigned long phys)
{
	int i, j;

	for (i = 0; i < count;) {
		printf("%08lx: ", phys + i);
		for (j = 0; j < 16 && i + j < count; j += width) {
			switch (width) {
			case 1:
				printf("%02x ",
					*(volatile u_int8_t *)
							(addr + i + j));
				break;
			case 2:
				printf("%04x ",
					*(volatile u_int16_t *)
							(addr + i + j));
				break;
			case 4:
				printf("%08x ",
					*(volatile u_int32_t *)
							(addr + i + j));
				break;
			default:
				break;
			}
		}
		i += j;
		printf("\n");
	}
}

static void write_buffer(unsigned long addr, unsigned long val, int count, int width)
{
	int i;

	for (i = 0; i < count; i++) {
		switch (width) {
		case 1:
			*(volatile u_int8_t *)(addr + i * width) =
							(u_int8_t)val;
			break;
		case 2:
			*(volatile u_int16_t *)(addr + i * width) =
							(u_int16_t)val;
			break;
		case 4:
			*(volatile u_int32_t *)(addr + i * width) =
							(u_int32_t)val;
			break;
		}
	}
}


static void print_to_stdout(unsigned long addr, int count, int width)
{
	int i;
	unsigned long value;

	for (i = 0; i < count; i++) {
		switch (width) {
		case 1:
			putchar(*(volatile u_int8_t *)addr);
			break;
		case 2:
			value = *(volatile u_int16_t *)addr;
			putchar(value & 0xFF);
			putchar((value >> 8) & 0xFF);
			break;
		case 4:
			value = *(volatile u_int32_t *)addr;
			putchar(value & 0xFF);
			putchar((value >> 8) & 0xFF);
			putchar((value >> 16) & 0xFF);
			putchar((value >> 24) & 0xFF);
			break;
		default:
			break;
		}

		addr += width;
	}
}

static void write_from_stdin(unsigned long addr, int count, int width )
{
	char ch;

	while(read(STDIN_FILENO, &ch, 1) > 0)
	{
		switch (width) {
		case 1:
			*(volatile u_int8_t *)(addr) = ch;
			break;
		case 2:
			perror("Only a byte width is suported in this mode");
			return;
			break;
		case 4:
			perror("Only a byte width is suported in this mode");
			return;
			break;
		default:
			break;
		}
		addr += width;

		if ( --count == 0 )
			break;
	}

}
int main(int argc, char *argv[])
{
	int read, width, fd;
	unsigned long addr, val, count;
	off_t mofs;
	size_t mlen;
	void *maddr;
	int i;

	if (argc < 4) {
	printf(	"mem: Access memory/register space using /dev/mem\n"\
		"usage: mem [r|w|R|W] [b|w|l] [addr] [rcount/wvalue] [wcount]\n"\
		"        r: Read memory. rcount is optional (defaults to 0x40)\n"\
		"        w: Write memory. wcount is optional (defaults to 1)\n"\
		"        R: Read memory and ouput raw data to stdout\n"\
		"        W: Write to memory, but get raw data from stdin\n"\
		);
		return -1;
	}

	if (strcmp(argv[1], "r") == 0) {
		read = 1;
	} else if (strcmp(argv[1], "w") == 0) {
		read = 0;
	} else if (strcmp(argv[1], "R") == 0) {
		read = 3;
	} else if (strcmp(argv[1], "W") == 0) {
		read = 2;
	} else {
		printf("Invalid command: %s\n", argv[1]);
		return -1;
	}

	if (strcmp(argv[2], "b") == 0) {
		width = 1;
	} else if (strcmp(argv[2], "w") == 0) {
		width = 2;
	} else if (strcmp(argv[2], "l") == 0) {
		width = 4;
	} else {
		printf("Invalid width: %s\n", argv[2]);
		return -1;
	}

	sscanf(argv[3], "%lx", &addr);


	if (addr % width != 0) {
		printf("Address not aligned on %d-bit boundary\n",
				width * 8);
		return -1;
	}

	if (read & 1) {	/* 'r' and 'R' */
		if (argc == 5)
			sscanf(argv[4], "%lx", &count);
		else
			count = 0x40;
	}
	if (read == 0 ) { /* 'w' */
		if (argc < 5) {
			printf("ERROR: Missing write value.\n");
			return -1;
		}
		sscanf(argv[4], "%lx", &val);

		if (argc == 6)
			sscanf(argv[5], "%lx", &count);
		else
			count = 1;
	}

	fd = open("/dev/mem", O_RDWR);
	if (fd == -1) {
		perror("/dev/mem");
		return -1;
	}

	/* offset must be on page boundary */
	mofs = addr & ~(PAGE_SIZE - 1);

	/* length must be a multiple of page size */
	mlen = (addr - mofs + count + PAGE_SIZE - 1) &
			~(PAGE_SIZE - 1);

	/* 'r' */
	if (read == 1) {
		maddr = mmap(NULL, mlen, PROT_READ, MAP_SHARED, fd, mofs);
		if (maddr == MAP_FAILED)
			goto done;
		print_buffer((unsigned long)(maddr + (addr & (PAGE_SIZE - 1))),
				count, width, addr);
	}
	/* 'w' */
	else if (read == 0) {
		maddr = mmap(NULL, mlen, PROT_WRITE, MAP_SHARED, fd, mofs);
		if (maddr == MAP_FAILED)
			goto done;
		write_buffer((unsigned long)(maddr + (addr & (PAGE_SIZE - 1))),
				val, count, width);
	}
	/* 'R' */
	else if (read == 3) {
		maddr = mmap(NULL, mlen, PROT_READ, MAP_SHARED, fd, mofs);
		if (maddr == MAP_FAILED)
			goto done;
		/* output to sdtio */
		print_to_stdout((unsigned long)(maddr + (addr & (PAGE_SIZE - 1))),
				count, width);
	}
	/* 'W' */
	else if (read == 0) {
		maddr = mmap(NULL, mlen, PROT_WRITE, MAP_SHARED, fd, mofs);
		if (maddr == MAP_FAILED)
			goto done;
		write_from_stdin((unsigned long)(maddr + (addr & (PAGE_SIZE - 1))),
				count, width);
	}

	munmap(maddr, mlen);
done:
	close(fd);
}

