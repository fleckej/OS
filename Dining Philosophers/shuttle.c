#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <time.h>

#include "common.h"
#include "common_threads.h"
#include "zemaphore.h"

Zem_t waiting;      // the shuttle has arrived and passengers may get on
Zem_t destination;  // specify when the shuttle is in transit and passengers should stay on
Zem_t ready;        // only passengers who are in line when the shuttle arrives are allowed on
Zem_t full;         // passengers should not get on if the shuttle is full
int attendees;      // total number of attendees taken from argv[1]
int passengers = 0; // total passengers aboard the shuttle
int capacity = 30;  // total passengers allowed on the shuttle a given time

// a thread for a passenger
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

// a thread for the shuttle
void *shuttle(){
    while(1){
        // the shuttle is at the hotel and passengers may board until it is full
        Zem_init(&destination, 0);
        Zem_init(&full, capacity-1);

        // get all the passengers currently in line ready to board the shuttle
        for (int i = 0; i < passengers; i++){
            Zem_post(&ready);
        }
        printf("shuttle arrived\n");
        // board passengers
        for (int i = 0; i < passengers; i++){
            Zem_post(&waiting);
        }

        // transit to the conference center
        sleep(3);
        printf("shuttle leaving\n");
        sleep(5);

        // drop off all passengers at the conference center
        printf("dropping off passengers\n");        
        for (int i = 0; i < passengers; i++){
            Zem_post(&destination);
        }

        // return to the hotel for more passengers
        sleep(1);
        printf("returning to hotel\n");
        sleep(5);
    }
    return NULL;
}

int main(int argc, char *argv[]){
    // get the number of attendees for the shuttle service
    if (argv[1] != NULL){
        attendees = atoi(argv[1]);
    } else {
        printf("Requires one argument\nExiting\n");
        return 0;
    }

    // initialize zemaphores
    Zem_init(&waiting, 0);
    Zem_init(&ready, 0);
    Zem_init(&destination, 0);
    Zem_init(&full, capacity-1);

    /* Intializes random number generator */
    time_t t;   
    srand((unsigned) time(&t));

    // start the shuttle service
    pthread_t s;
    long long int me = 0;
    Pthread_create(&s, NULL, shuttle, (void *)me);
    sleep(1);

    // take passengers to the platform
    int i = 0;
    while (i < attendees){
        sleep(rand()%2);
        pthread_t c;
        long long int me = i;
        Pthread_create(&c, NULL, passenger, (void *)me);
        i++;
        if (i == attendees - 1){
            break;
        }
    }
    sleep(1);

    while(1){}
    return 0;
}