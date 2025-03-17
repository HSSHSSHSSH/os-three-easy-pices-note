## 在 windows 上使用 wsl 运行 linux 程序
- 安装 wsl

  ```shell
  wsl --install -d Ubuntu
  ```

  进入 wsl 

  ``` shell
  wsl -d Ubuntu
  ```

- 安装 gcc 与 build-essential

  ```shell
  sudo apt-get install gcc
  sudo apt-get install build-essential
  ```

之后就可以在 wsl 中使用 gcc 编译 linux c 程序了。

## Unix/Linux进程与文件描述符学习笔记

### 1. 文件描述符基础
- **定义**：文件描述符是一个非负整数，用于标识进程打开的文件或I/O资源
- **标准文件描述符**：
  - 0 (STDIN_FILENO)：标准输入，默认连接到键盘
  - 1 (STDOUT_FILENO)：标准输出，默认连接到终端屏幕
  - 2 (STDERR_FILENO)：标准错误，默认连接到终端屏幕
- **特点**：
  - 每个进程都有独立的文件描述符表
  - 文件描述符只是索引值，本身没有特殊功能
  - 新打开的文件会获得当前可用的最小描述符号

### 2. 进程创建与文件描述符继承
- **fork()函数**：
  - 创建当前进程的副本(子进程)
  - 子进程继承父进程的整个文件描述符表
  - 子进程之后对描述符的修改不影响父进程
  - 返回值：父进程中返回子进程PID，子进程中返回0

- **exec()函数族**：
  - 用新程序替换当前进程的内容
  - 保留文件描述符表(除非设置了FD_CLOEXEC标志)
  - 替换后，原进程的代码不再执行

### 3. I/O重定向实现
- **关闭和打开描述符**：
  ```c
  close(STDOUT_FILENO);  // 关闭描述符1
  open("output.txt", O_WRONLY|O_CREAT, 0644);  // 获取描述符1
  ```
  
- **open()函数参数**：
  - 第一个参数：文件路径
  - 第二个参数：打开标志(O_RDONLY, O_WRONLY, O_CREAT等)
  - 第三个参数：权限模式(仅当创建文件时使用)

- **重定向的工作原理**：
  - close()释放特定的描述符号
  - open()会使用最小可用的描述符号
  - 结合使用实现了文件描述符的"重用"

- **dup/dup2函数**：
  - `dup(fd)`：复制描述符，返回新描述符
  - `dup2(oldfd, newfd)`：将newfd指向与oldfd相同的文件

### 4. 缓冲区机制
- **stdio库的缓冲模式**：
  - **行缓冲**：终端设备的默认模式，遇到换行符刷新
  - **完全缓冲**：普通文件的默认模式，缓冲区满或显式刷新才写入
  - **无缓冲**：数据立即写入，不经过缓冲区(如stderr通常是无缓冲的)

- **缓冲区刷新时机**：
  - 缓冲区满时
  - 遇到换行符(仅限行缓冲模式)
  - 程序正常结束
  - 显式调用fflush()

- **exec()前的缓冲区管理**：
  - exec()会替换进程，包括未刷新的缓冲区
  - 必须在exec()前调用fflush()确保数据写入
  - 或使用无缓冲的写入函数，如write()

- **C标准库中的缓冲函数**：
  - 几乎所有stdio的I/O函数都使用缓冲：
    - 输出：printf(), fprintf(), fputs(), fwrite(), putc()/fputc(), puts()
    - 输入：scanf(), fscanf(), fgets(), fread(), getc()/fgetc()
  - 系统调用级函数不使用stdio缓冲：
    - write(), read() 等直接系统调用不经过stdio缓冲机制

- **控制缓冲区行为**：
  - `setvbuf(FILE *stream, char *buf, int mode, size_t size)` - 设置流的缓冲模式
    - 模式参数：_IONBF(无缓冲)、_IOLBF(行缓冲)、_IOFBF(完全缓冲)
  - `setbuf(FILE *stream, char *buf)` - 简化版的setvbuf
  - `fflush(FILE *stream)` - 强制刷新指定流的缓冲区

- **其他编程语言中的缓冲机制**：
  - **Python**：
    - print()函数默认使用缓冲的stdout
    - 可以通过print(..., flush=True)强制刷新
    - 文件操作可以指定缓冲模式：open(file, buffering=0/1/-1)
    - sys.stdout.flush()方法显式刷新缓冲区
  
  - **JavaScript (Node.js)**：
    - process.stdout有缓冲机制
    - console.log()使用这些缓冲流
    - Node.js的流(Streams)API有内置缓冲控制
    - 可通过stream.cork()和stream.uncork()管理缓冲行为

- **缓冲区的性能影响**：
  - 缓冲区增大I/O操作效率，减少系统调用次数
  - 缓冲可能导致数据不是实时可见
  - 关键应用场景(如日志)需要权衡缓冲效率和实时性
  - 进程意外终止可能导致缓冲数据丢失


### 5. 实际应用示例
- **简单重定向**：
  ```c
  close(STDOUT_FILENO);
  open("output.txt", O_WRONLY|O_CREAT, 0644);
  printf("输出到文件\n");
  fflush(stdout);  // 确保数据写入文件
  ```

- **命令执行与重定向**：
  ```c
  if (fork() == 0) {  // 子进程
      close(STDOUT_FILENO);
      open("output.txt", O_WRONLY|O_CREAT, 0644);
      execlp("ls", "ls", "-l", NULL);  // ls的输出会写入文件
  }
  ```

- **等效的Shell命令**：
  ```bash
  ls -l > output.txt
  ```

### 6. 核心概念总结
- Unix/Linux的"一切皆文件"哲学使I/O操作统一
- 标准文件描述符是约定，而非硬性规定
- 文件描述符表是进程的属性，子进程继承，exec后保留
- 重定向的本质是改变文件描述符的指向
- 缓冲区行为取决于输出目标类型
```

