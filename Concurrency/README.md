# Dining Philosophers and Shuttle Service Operating System Project

## Overview

This project is a small operating systems experiment that explores three different dining philosophers algorithms and one shuttle service algorithm to demonstrate concurrency concepts. The dining philosophers problem is a synchronization problem that highlights the challenges of resource sharing and deadlock avoidance, while the shuttle service algorithm illustrates concurrent processes in a transportation scenario.

## Table of Contents

- [Dining Philosophers Algorithms](#dining-philosophers-algorithms)
  - [1. Dining Philosophers 1](#dining-philosophers-1)
  - [2. Dining Philosophers 2](#dining-philosophers-2)
  - [3. Dining Philosophers 3](#dining-philosophers-3)
- [Shuttle Service Algorithm](#shuttle-service-algorithm)
- [Getting Started](#getting-started)
- [Usage](#usage)

## Dining Philosophers Algorithms

### Dining Philosophers 1

Each philosopher picks up first their left fork, and then their right fork. This can lead to deadlock and starvation. 


### Dining Philosophers 2

A philosopher is allowed to pick up both of her forks together, only if both of them are available. This puts a lock around the forks of philosophers 0 and 1.


### Dining Philosophers 3

Each philosopher has their own seat at the table, but they do all of their thinking away from the table.  When they get hungry, they try to sit at the table, and then pick up their forks (first the right and then the left).  At most N-1 philosophers can sit at the table simultaneously.  When a philosopher is done eating, they get up from the table.


## Shuttle Service Algorithm

The shuttle service algorithm simulates a transportation system where a shuttle moves between different locations to pick up and drop off passengers. The algorithm involves multiple processes representing shuttle movements and passenger interactions, showcasing concurrency in a real-world scenario.

Attendees milled about the front entrance, waiting for a shuttle. 
When a shuttle arrived, everyone already waiting was allowed to get on the shuttle. 
Those who show up while the shuttle is boarding must wait for the next one.
The shuttles hold 30 people, so if there are more people waiting, they also have to hang out for the next shuttle.
When the allowed attendees were onboard, the shuttle departs.
If a shuttle arrived and no attendees were waiting, the shuttle immediately departed.


## Getting Started

To run the project, follow these steps:

1. Clone the repository: `git clone https://github.com/fleckej/OS.git`
2. Navigate to the project directory: `cd OS/Concurrency`
4. Run the executable: 
- `./algo1.o <philosophers>`
- `./algo2.o <philosophers>`
- `./algo3.o <philosophers>`
- `./shuttle.o <passengers>`

## Usage

- Append the number of philosophers or passengers to the end of the command.
- Execute the program to observe the behavior of the chosen algorithm.