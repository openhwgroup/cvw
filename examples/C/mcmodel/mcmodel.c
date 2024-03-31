// mcmodel.c
// Demonstrate different code generation with mcmodel = medany vs. medlow

long a;
long b[2000];

int main(void)
{
    return a + b[1000];
}