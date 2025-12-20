// main.c
extern void end(void);

int main(void) {
    end();         // never returns
    return 0;      // unreachable, but keeps compilers happy
}
