#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
int main(int argc, char *argv[]) {
    if (argc < 3){
        fprintf(stderr, "Expected 2 arguments: <raw GDB dump> <output binary>\n");
        exit(1);
    }
    char* rawGDBfilePath = argv[1];
    FILE* rawGDBfile;
    if ((rawGDBfile = fopen(rawGDBfilePath,"rb"))==NULL) {
        fprintf(stderr, "File not found: %s\n",rawGDBfilePath);
        exit(1);
    }
    char* outFilePath = argv[2];
    FILE* outFile = fopen(outFilePath,"w");
    uint64_t qemuWord;
    uint64_t verilogWord;
    int bytesReturned=0;
    do {
        bytesReturned=fread(&qemuWord, 8, 1, rawGDBfile);
        verilogWord = (((qemuWord>>0 )&0xff)<<56 | 
                       ((qemuWord>>8 )&0xff)<<48 | 
                       ((qemuWord>>16)&0xff)<<40 | 
                       ((qemuWord>>24)&0xff)<<32 | 
                       ((qemuWord>>32)&0xff)<<24 | 
                       ((qemuWord>>40)&0xff)<<16 | 
                       ((qemuWord>>48)&0xff)<<8  | 
                       ((qemuWord>>56)&0xff)<<0);
        fwrite(&verilogWord, 8, 1, outFile);
    } while(bytesReturned!=0);
    return 0;
}
