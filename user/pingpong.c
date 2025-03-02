#include "kernel/types.h"
#include "user/user.h"

int
main(void)
{
  int p1[2], p2[2];           // 两个管道：p1用于父→子，p2用于子→父
  pipe(p1);
  pipe(p2);

  int pid = fork();           // 创建子进程
  if (pid < 0) {
    fprintf(2, "fork failed\n");
    exit(1);
  }

  if (pid == 0) {
    // 子进程
    char buf[1];
    // 子进程只用 p1[0] 读父进程数据、p2[1] 写回父进程
    close(p1[1]);
    close(p2[0]);

    // 从父进程读一个字节
    read(p1[0], buf, 1);
    // 打印 "<child_pid>: received ping"
    printf("%d: received ping\n", getpid());

    // 将任意一个字节写回给父进程
    write(p2[1], "x", 1);

    exit(0);

  } else {
    // 父进程
    char buf[1];
    // 父进程只用 p1[1] 写给子进程、p2[0] 读子进程数据
    close(p1[0]);
    close(p2[1]);

    // 向子进程发送一个字节
    write(p1[1], "y", 1);
    // 读子进程发回的字节
    read(p2[0], buf, 1);

    // 打印 "<parent_pid>: received pong"
    printf("%d: received pong\n", getpid());

    exit(0);
  }
}
