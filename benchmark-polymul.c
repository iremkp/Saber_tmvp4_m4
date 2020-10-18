#include <string.h>
#include <stdio.h>

#include "stm32wrapper.h"
#include "randombytes.h"

extern void asm_polymul_256(uint16_t r[DIMENSION],  const uint16_t a[DIMENSION], const uint16_t b[DIMENSION]);

static unsigned long long overflowcnt = 0;

void sys_tick_handler(void)
{
  ++overflowcnt;
}

static void printcycles(const char *s, unsigned long long c)
{
  char outs[32];
  send_USART_str(s);
  snprintf(outs,sizeof(outs),"%llu\n",c);
  send_USART_str(outs);
}

static void schoolbook_naive(uint16_t *r, const uint16_t *a, const uint16_t *b)
{
  int i, j;
  int32_t result;

  for (i = 0;i < DIMENSION;++i) 
  {
    result = 0;
    for (j = 0;j <= i;++j)
      result += a[j]*b[i - j];
    r[i] = result;
  }
  for (i = DIMENSION;i < 2*DIMENSION-1;++i) 
  {
    result = 0;
    for (j = i - DIMENSION + 1;j < DIMENSION;++j)
      result += a[j]*b[i - j];
    r[i] = result;
  }
}

static void modred(uint16_t *poly, uint16_t p)
{
    unsigned int i = 0;
    for (i = 0; i < DIMENSION; i++) {
        poly[i] &= p-1;
    }
}

static void reduce(uint16_t *poly)
{
    unsigned int i = 0;
    for (i = 0; i < 255; i++) {
        poly[i] -= poly[i+DIMENSION];
    }
}

static void random_poly(uint16_t *p, unsigned int len)
{
    randombytes((unsigned char *)p, len * sizeof(uint16_t));
    modred(p, Q);
}

int main (void)
{
    clock_setup(CLOCK_BENCHMARK);
    gpio_setup();
    usart_setup(115200);
    systick_setup();
    rng_enable();

    unsigned int t0, t1;

    send_USART_str("\n===================================");
    printcycles("n: ", DIMENSION);
    printcycles("t: ", 16);

    uint16_t x[DIMENSION];
    uint16_t y[DIMENSION];
    uint16_t z[DIMENSION];
    uint16_t check[DIMENSION * 2 - 1];


    memset(x, 0, sizeof(x[0])*DIMENSION);
    memset(y, 0, sizeof(y[0])*DIMENSION);
    memset(z, 0, sizeof(z[0])*DIMENSION);
    memset(check, 0, sizeof(check[0])*(2 * DIMENSION - 1));

    random_poly(x, DIMENSION);
    random_poly(y, DIMENSION);

    t0 = systick_get_value();
    overflowcnt = 0;
    asm_polymul_256(z, x, y);	
    t1 = systick_get_value();
    printcycles("cycles: ", (t0+overflowcnt*2400000llu)-t1);

    schoolbook_naive(check, x, y);
    /*for (int i = DIMENSION; i < 511; i++)
	{
		check[i - DIMENSION] = (check[i - DIMENSION] - check[i])&8191;
	}*/
    reduce(check);
    modred(check, Q);
    modred(z, Q);

    if (memcmp(check, z, sizeof(z[0]) * DIMENSION)) {
        send_USART_str("ERROR!");
    }

    send_USART_str("###########");
    while(1);

    return 0;
}
