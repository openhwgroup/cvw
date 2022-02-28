#include <stdio.h>
#include <stdlib.h>

int main(void)
{
  char *line = NULL;
  size_t len = 0;
  while (1) {
      FILE* controlFile = fopen("silencePipe.control", "r");
      char silenceChar = getc(controlFile);
      fclose(controlFile);
      ssize_t lineSize = getline(&line, &len, stdin);
      if (silenceChar!='1') {
          printf("%s",line);
      } else {
        fprintf(stderr,"%s",line);
      }
  }
  free(line);
  return 0;
}
