#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>


int main(int argc, char** argv){
  if(argc < 2)
    return EXIT_FAILURE;
  FILE* file = fopen(argv[1], "rb");

  char char_map[16];
  char zeros[16] = {0};
  while(fread(char_map, 1, sizeof(char_map), file)){
    fwrite(char_map, 1, sizeof(char_map), stdout);
    fwrite(zeros, 1, sizeof(zeros), stdout);
  }
  fclose(file);
}
