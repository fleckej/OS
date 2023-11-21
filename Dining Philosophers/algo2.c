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
int philosophers;
Zem_t *forks;

void drop_forks(int philosopher){
        printf("%d dropping forks\n", philosopher);

        // set forks to available
        Zem_post(&forks[philosopher]);
        Zem_post(&forks[(philosopher + 1) % philosophers]);

        // Zem_wait(&taken); // decrement taken; if taken < 0, sleep
        Zem_post(&available); // increment available; wake
}

// direction specifies the fork
void getForks(int philosopher){
        printf("%d checking for forks\n", philosopher);

        // check if either fork is taken
        int left_fork = (&forks[philosopher])->value;
        int right_fork = (&forks[(philosopher + 1) % philosophers])->value;
        if (left_fork == 0 || right_fork == 0){
            printf("%d no forks\n", philosopher);
            Zem_wait(&available); // decrement available; if available < 0, sleep
        }

        printf("%d taking forks\n", philosopher);
        Zem_wait(&forks[philosopher]);
        Zem_wait(&forks[(philosopher + 1) % philosophers]);
        Zem_post(&taken); // increment taken; wake
}

void *philosopher(void *arg) { 
    long long int value = (long long int) arg;
    int id = (int) value;
    printf("%d philosopher started\n",id);
    int servings = 0;

    while(1){
        Zem_wait(&mutex); // decrement mutex; if mutex < 0, sleep
        getForks(id); // gets both left and right
        Zem_post(&mutex); // increment mutex; wake

        printf("%d eating\n", id);
        sleep(4); // eating
        servings++;
        printf("%d number of servings: %d\n", id, servings);


        drop_forks(id);
        sleep(2); // thinking
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
    
    forks = malloc(sizeof(Zem_t) * philosophers);

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
    
