#include <inttypes.h>
#include <stdio.h>
#include <string.h>

int main()
{
//	printf( "$date the date $end\n");
//	printf( "$version the version $end\n");
	printf( "$timescale 1ns $end\n");
	printf( "$scope module logic $end\n");
#define NDATA 8
	int ndata = NDATA;
	int i;
	char alias[NDATA];
	for (i = 0; i < ndata; i++)
	{
		char name[] = "dataX";
		alias[i] = '0' + i;
		name[strlen(name) - 1] = alias[i];
		printf( "$var wire 1 %c %s $end\n", alias[i], name);
	}
	printf( "$upscope $end\n");
	printf( "$enddefinitions $end\n");
	while (!feof( stdin))
	{
		char line[2*(4+1)+2+1];
		if (!fgets( line, sizeof( line), stdin))
			break;
//		printf( "line=%s\n", line);
		char ts[] = "0xYYYYYYYY";
		memcpy( ts + 2, line, 2*4);
//		printf( "ts=%s\n", ts);
		char dt[] = "0xYY";
		memcpy( dt + 2, line + 8, 2*1);
//		printf( "dt=%s\n", dt);
		uint32_t timestamp = 0;
		sscanf( ts, "%" SCNx32, &timestamp);
		uint32_t data = 0;
		sscanf( dt, "%x", &data);
		printf( "#%" PRIu32 "\n", timestamp);
		for (i = 0; i < ndata; i++)
		{
			printf( "%01u%c\n", (data & (1 << i)) != 0, alias[i]);
		}
//		printf( "ts=%08" PRIx32 " v=%02" PRIx8 "\n", timestamp, data);
	}
	return 0;
}