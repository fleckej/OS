#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <time.h>

#include "common.h"
#include "common_threads.h"
#include "zemaphore.h"

Zem_t waiting;     // Zem_wait is they're waiting and Zem_post is they got on; 
Zem_t destination;
Zem_t ready;
Zem_t full;
int attendees;
int passengers = 0;
int capacity = 30;

void *passenger(void *arg){
    long long int value = (long long int) arg;
    int id = (int) value;
    printf("%d waiting to board\n", id);

    // wait if the shuttle is full
    Zem_wait(&full);
    // wait if the shuttle has already arrived and you must wait for the next one
    passengers++;
    Zem_wait(&ready);
    // wait to be let on to the shuttle
    Zem_wait(&waiting);
    
    printf("%d boarding\n", id);

    // wait until the shuttle reaches the destination
    Zem_wait(&destination);
    printf("%d getting off shuttle\n", id);

    // get off the shuttle and increment the full counter
    Zem_post(&full);
    passengers--;
    return NULL;
}

void *shuttle(){
    while(1){
        Zem_init(&destination, 0);
        Zem_init(&full, capacity-1);
        for (int i = 0; i < passengers; i++){
            Zem_post(&ready); // wake passengers to board;
        }
        printf("shuttle arrived\n");
        for (int i = 0; i < passengers; i++){
            Zem_post(&waiting); // wake passengers to board;
        }
        sleep(3);
        printf("shuttle leaving\n");
        sleep(5);
        printf("dropping off passengers\n");        
        for (int i = 0; i < passengers; i++){
            Zem_post(&destination);
        }
        sleep(1);
        printf("returning to hotel\n");
        sleep(5);
    }
    return NULL;
}

int main(int argc, char *argv[]){
    if (argv[1] != NULL){
        attendees = atoi(argv[1]);
    } else {
        printf("Requires one argument\nExiting\n");
        return 0;
    }

    Zem_init(&waiting, 0);
    Zem_init(&ready, 0);
    Zem_init(&destination, 0);
    Zem_init(&full, capacity-1);

   time_t t;   
   /* Intializes random number generator */
   srand((unsigned) time(&t));

    // start the shuttle service
    pthread_t s;
    long long int me = 0;
    Pthread_create(&s, NULL, shuttle, (void *)me);
    sleep(1);

    // take passengers to platform
    for (int i = 0; i < attendees; ++i){
        sleep(rand()%2);
        pthread_t c;
        long long int me = i;
        Pthread_create(&c, NULL, passenger, (void *)me);
    }

    sleep(1);

    while(1){}
    return 0;
}