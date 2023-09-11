/*  Mini Shell
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>


void tokenize(char *input, int *tokenc, char ***tokenv);
void startup(int tokenc, char **tokenv);

// infinitely prompt the user and tokenize the input until end-of-file
int main(int argc, char *argv[]){
	int tokenc; // argument counter for the mini shell
    char *input, **tokenv;	// user input string and empty vector of arguments
    input = malloc(200 * sizeof(char));      // set the size for the input string

    do{
        // prompt the user, store the user input, and print it to the terminal
        printf("prompt> ");
        fgets(input, 20 * sizeof(char *), stdin);
        printf("%s", input);

        // tokenize user input and get the token count and vector
        tokenize(input, &tokenc, &tokenv);

		// execute the input string
		startup(tokenc, tokenv);
    } while (input != NULL);
}

// parse the user input into a token vector and get the count of tokens
void tokenize(char *input, int *tokenc, char ***tokenv){
    char *token,        *whitespace = " \t\f\r\v\n";
    int token_i = 0;

	// create space for token list plus a NULL pointer
    *tokenv = malloc(strlen(input) * sizeof(char *) + sizeof(char *));  
	// get the first token
	token = strtok(input, whitespace); 

	do {
		(*tokenv)[token_i] = strdup(token);	// set the token as an index in tokenv
		token = strtok(NULL, whitespace); 	// get the next token
        token_i++;							// increment the token index
    } while (token != NULL);				// continue through all the tokens in the input string

	(*tokenv)[token_i] = NULL;				// append NULL to the end of token vector
	token_i++;								// increment token index to reflect number of tokens + NULL
    *tokenc = token_i;                      // set tokenc as the total tokens + NULL
}

void startup(int tokenc, char **tokenv){
	int rc = fork();
	if (rc < 0) {
		// fork failed; exit
		fprintf(stderr, "fork failed\n");
		exit(1);
	} else if (rc == 0) {
		// child process
		int error = execvp(tokenv[0], &tokenv[0]);  // runs exec

		// check for errors
		if (error != 0){
			perror("Error: ");
		}
	} else {
		// parent process
		wait(&rc);	// wait for command to be executed
	}
}