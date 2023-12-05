# Virtualization Project with Lottery Scheduler in xv6

## Overview

This project focuses on enhancing the xv6 operating system by implementing a lottery scheduler. The primary objective is to address the challenges related to virtualization and scheduling algorithms. Initially, xv6 operated on a round-robin scheduler, and the project involved transitioning to a lottery scheduler.

## Background

In our operating systems class, we delved into various scheduling algorithms and their impact on system performance. The need for virtualization arises from the desire to efficiently utilize system resources and provide a fair and dynamic environment for running processes. The lottery scheduler was chosen as an alternative scheduling algorithm due to its ability to introduce an element of randomness, preventing monopolization of resources by long-running processes.

## Changes Made

All relevant code changes for implementing the lottery scheduler can be found in the `CHANGELOG.md` file in the parent directory. The alterations primarily focus on the kernel components responsible for process scheduling, including the introduction of ticket assignment, ticket accumulation over time, and the selection of processes based on ticket randomness.

## Implementation Details

- **Ticket Assignment**: Each process is assigned a certain number of tickets. This number increases the longer the process runs, allowing fair distribution of CPU time among processes.

- **Random Ticket Selection**: The lottery scheduler selects a winning ticket at random, determining the next process to run. This randomness prevents processes with more tickets from consistently dominating the CPU.

- **Dynamic Ticket Adjustment**: Processes that have been running for an extended period are awarded additional tickets to increase their chances of being selected. This dynamic adjustment helps in preventing starvation and ensures a more equitable distribution of resources.

## Usage

To observe the lottery scheduler in action, follow these steps:

1. Build xv6 with the implemented changes.
2. Run the modified xv6 operating system.
3. Observe the behavior of processes as they are scheduled using the lottery scheduler.

## Future Improvements

While the current implementation introduces the lottery scheduler, there is always room for improvement. Future enhancements include optimizing the algorithm for better performance and conducting thorough testing. Additionally, the use of the settickets() function in the scheduler should not be required for proper functionality.

## Contributions

Contributions, bug reports, and suggestions are highly welcome.