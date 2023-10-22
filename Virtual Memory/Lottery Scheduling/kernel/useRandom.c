#include <stdio.h>
#include "random.h"
int main()
{
    rand_init(17);
    for (int i = 0; i < 100; ++i)
        printf("%d\n", scaled_random(1, 1000));
}
