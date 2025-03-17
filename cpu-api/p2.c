#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
int main(int argc, char *argv[]){
    printf("hello (pid:%d)\n", (int) getpid());
    int rc = fork();
    if (rc < 0){
        fprintf(stderr, "fork failed\n");
        exit(1);
    } else if (rc == 0){
        printf("child (pid:%d)\n", (int) getpid());
    } else {
        int wc = wait(NULL);
        printf("parent of %d (rc_wait:%d) (pid:%d)\n",
        rc, wc, (int) getpid());
    }
    return 0;
}
