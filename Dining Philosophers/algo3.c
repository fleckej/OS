#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
//#include <semaphore.h>

#include "common.h"
#include "common_threads.h"
#include "zemaphore.h"

Zem_t mutex;
Zem_t taken;
Zem_t available;
Zem_t seated;
int philosophers;
Zem_t *forks;

void drop_forks(int fork_num){
        Zem_wait(&taken); // decrement taken; if taken < 0, sleep
        printf("%d dropping forks\n", fork_num);

        // set forks to available
        Zem_post(&forks[fork_num]);
        Zem_post(&forks[(fork_num + 1) % philosophers]);

        Zem_post(&available); // increment available; wake
}

// direction specifies the fork
void getFork(int direction, int philosopher){
        // check fork is taken
        if (&forks[direction] == 0){ // condition works for accurate left and right fork
            printf("%d no forks\n", philosopher);
            Zem_wait(&available); // decrement available; if available < 0, sleep
        }
        if (direction == philosopher){
            printf("%d taking left fork\n", philosopher);
        } else {
            printf("%d taking right fork\n", philosopher);
        }
        Zem_wait(&forks[direction]); // decrement fork; if fork < 0, sleep
        Zem_post(&taken); // increment taken; wake
}

void *philosopher(void *arg) { 
    long long int value = (long long int) arg;
    int id = (int) value;
    int servings = 0;
    printf("%d started\n",id);

    while(1){
        Zem_wait(&seated); // decrement seated; if seated < 0, sleep
        printf("%d seated\n", id);
        Zem_wait(&mutex); // decrement mutex; if mutex < 0, sleep

        getFork(((id + 1) % philosophers), id);
        getFork(id, id);

        Zem_post(&mutex); // increment mutex; wake

        printf("%d eating\n", id);
        sleep(4);
        servings++;
        printf("%d number of servings: %d\n", id, servings);

        drop_forks(id);
        printf("%d left the table\n", id);
        Zem_post(&seated); // increment seated, wake
        sleep(2);
    }
    return NULL;
}

int main(int argc, char *argv[]) {
    if (argv[1] != NULL){
        philosophers = atoi(argv[1]);
    } else {
        printf("Requires one argument\nExiting\n");
        return 0;
    }
    Zem_init(&mutex, atoi(argv[1]));
    Zem_init(&taken,0);
    Zem_init(&available,0);
    Zem_init(&seated, atoi(argv[1])-1);
    forks = malloc(sizeof(int) * philosophers);

    // make all forks available
    for (int i = 0; i < philosophers; i++){
        Zem_init(&forks[i], 1);
    }
    printf("parent: begin\n");

    // sit all the philosophers at the table
    for (int i = 0; i < philosophers; ++i){
        pthread_t c;
        long long int me = i;
        Pthread_create(&c, NULL, philosopher, (void *)me);
    }
    while (0 < philosophers){}
//    sem_wait(&s); // wait here for child
    printf("parent: end\n");
    return 0;
}