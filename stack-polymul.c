#include <stdio.h>
#include <string.h>
#include "randombytes.h"
#include "stm32wrapper.h"
#define MAX_SIZE 0x16000

unsigned int canary_size = MAX_SIZE;
volatile unsigned char *p;
unsigned int c;
uint8_t canary = 0x42;

extern void asm_polymul_256(uint16_t r[DIMENSION],  const uint16_t a[DIMENSION], const uint16_t b[DIMENSION]);

uint16_t x[DIMENSION];
uint16_t y[DIMENSION];
uint16_t z[DIMENSION];
uint16_t check[DIMENSION * 2 - 1];

static void send_stack_usage(const char *s, unsigned int usage) {
  char outs[120];
  send_USART_str(s);
  sprintf(outs, "%u\n", usage);
  send_USART_str(outs);
}

#define FILL_STACK()                                                           \
  p = &a;                                                                      \
  while (p > &a - canary_size)                                                 \
    *(p--) = canary;
#define CHECK_STACK()                                                          \
  c = canary_size;                                                             \
  p = &a - canary_size + 1;                                                    \
  while (*p == canary && p < &a) {                                             \
    p++;                                                                       \
    c--;                                                                       \
  }                                                                            

static void schoolbook_naive(uint16_t *r, const uint16_t *a, const uint16_t *b)
{
  int i, j;
  int32_t result;

  for (i = 0;i < 256;++i) 
  {
    result = 0;
    for (j = 0;j <= i;++j)
      result += a[j]*b[i - j];
    r[i] = result;
  }
  for (i = 256;i < 2*256-1;++i) 
  {
    result = 0;
    for (j = i - 256 + 1;j < 256;++j)
      result += a[j]*b[i - j];
    r[i] = result;
  }
}
static void test(void){
  volatile unsigned char a;
  FILL_STACK()
  asm_polymul_256(z, x, y);
  CHECK_STACK()
  send_stack_usage("stack usage:", c);
}

static void modred(uint16_t *poly, uint16_t q)
{
    unsigned int i = 0;
    for (i = 0; i < DIMENSION; i++) {
        poly[i] &= q-1;
    }
}

static void reduce(uint16_t *poly)
{
    unsigned int i = 0;
    for (i = 0; i < DIMENSION-1; i++) {
        poly[i] -= poly[i+DIMENSION];
    }
}

static void random_poly(uint16_t *poly, unsigned int len)
{
    randombytes((unsigned char *)poly, len * sizeof(uint16_t));
    reduce(poly);
}
int main (void)
{
    clock_setup(CLOCK_BENCHMARK);
    gpio_setup();
    usart_setup(115200);
    systick_setup();
    rng_enable();
    send_USART_str("\n===================================");
    send_stack_usage("n: ", DIMENSION);
    send_stack_usage("t: ", 16);

    memset(x, 0, sizeof(x[0])*DIMENSION);
    memset(y, 0, sizeof(y[0])*DIMENSION);
    memset(z, 0, sizeof(z[0])*DIMENSION);
    memset(check, 0, sizeof(check[0])*(2 * DIMENSION - 1));

    random_poly(x, DIMENSION);
    random_poly(y, DIMENSION);

    test();

    schoolbook_naive(check, x, y);

    reduce(check);
    modred(check,DIMENSION);
    modred(z,DIMENSION);

    if (memcmp(check, z, sizeof(z[0]) * DIMENSION)) {
        send_USART_str("ERROR!");
    }

    send_USART_str("###########");
    while(1);

    return 0;
}
