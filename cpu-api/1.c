#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

/**
 * fork 函数 
 * 在当前进程中创建一个子进程，返回值为子进程的 pid
 * 在子进程中返回 0
 * 在父进程中返回子进程的 pid
 * fork 创建的子进程代码是父进程的副本，但是执行顺序不同，从 fork 开始，可以获取fork之前的数据状态
 * 
 */

int main(){
    int x = 100;
    printf("I'm process %d, and the value of x is %d\n", (int) getpid(), x);
    int rc = fork();
    printf("fork() returned %d\n", rc);
    if (rc < 0){
        fprintf(stderr, "fork failed\n");
        exit(1);
    } else if (rc == 0){
        x += 5;
        printf("Child (pid = %d): x = %d rc = %d\n", (int) getpid(), x, rc);
    } else{
        x += 10;
        printf("I'm the parent of %d, my value of x is %d\n", rc, x);
    }
    return 0;
}
