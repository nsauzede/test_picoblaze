#include <inttypes.h>
#include <stdio.h>
#include <string.h>

int main()
{
	uint32_t freq = 48000000;
//	printf( "$date the date $end\n");
//	printf( "$version the version $end\n");
	printf( "$timescale 1ns $end\n");
	uint32_t scale = 1000000000 / freq;		// time unit is ns
	printf( "$scope module logic $end\n");
#define NDATA 8
	int ndata = NDATA;
	int i;
#define USE_WIRES
#ifdef USE_WIRES
	char alias[NDATA];
	for (i = 0; i < ndata; i++)
	{
		char name[] = "dataX";
		alias[i] = '0' + i;
		name[strlen(name) - 1] = alias[i];
		printf( "$var wire 1 %c %s $end\n", alias[i], name);
	}
#else
	printf( "$var wire %d 0 data $end\n", ndata);
#endif
	printf( "$upscope $end\n");
	printf( "$enddefinitions $end\n");
	while (!feof( stdin))
	{
		char line[2*(4+1)+2+1];
#if 0
		if (!fgets( line, sizeof( line), stdin))
			break;
#else
		int pos = 0;
#define WANTED (2*(4+1))
		while (pos < WANTED)
		{
			line[pos] = fgetc( stdin);
			if (line[pos] == EOF)
				break;
			if ((line[pos] == ' ') ||
				(line[pos] == '\n')
			   )
				continue;
			pos++;
		}
		if (pos < WANTED)
			break;
		line[pos] = 0;
#endif
//		printf( "line=%s\n", line);
		char ts[] = "0xYYYYYYYY";
		memcpy( ts + 2, line, 2*4);
//		printf( "ts=%s\n", ts);
		char dt[] = "0xYY";
		memcpy( dt + 2, line + 8, 2*1);
//		printf( "dt=%s\n", dt);
		uint32_t timestamp = 0;
		sscanf( ts, "%" SCNx32, &timestamp);
		timestamp *= scale;
#if 1
		static uint32_t first_timestamp = 0xffffffff;
		if (first_timestamp == 0xffffffff)
			first_timestamp = timestamp;
		timestamp -= first_timestamp;
#endif
		uint32_t data = 0;
		sscanf( dt, "%x", &data);
		printf( "#%" PRIu32, timestamp);
#ifndef USE_WIRES
		printf( "\n");
		printf( "b");
#endif
		for (i = 0; i < ndata; i++)
		{
#ifdef USE_WIRES
//			printf( "%01u%c\n", (data & (1 << i)) != 0, alias[i]);
			printf( " %01u%c", (data & (1 << i)) != 0, alias[i]);
#else
			printf( "%01u", (data & (1 << (ndata - 1 - i))) != 0);
#endif
		}
#ifdef USE_WIRES
		printf( "\n");
#else
		printf( " 0\n");
#endif
//		printf( "ts=%08" PRIx32 " v=%02" PRIx8 "\n", timestamp, data);
	}
	return 0;
}
