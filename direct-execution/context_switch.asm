# void swtch(struct context *old, struct context *new);
#
# Save current register context in old
# and then load register context from new.

# %eax 表述寄存器本身  0(%eax) 是一个内存地址表达式，指向%eax中值所表示的内存位置
# 结构体的内存地址是连续的，所以可以通过偏移量来访问结构体的成员且结构体的起始与其第一个成员的起始地址相同
.globl swtch
swtch:
    # Save old registers
            # 当函数调用时，会将函数的参数从右向左压入栈中，然后再将返回地址压入栈中
            # 所以4(%esp)是old的地址，0(%eax)是返回地址
            # esp 是栈指针，指向栈顶; eax 是累加寄存器
            movl 4(%esp), %eax # put old ptr into eax 将 esp 指向的地址的高4字节的数据即 *old 放入 eax 中
            popl 0(%eax) # save the old IP 将返回地址从栈中弹出，并存储到 eax 指向的内存地址中即 *old 的第一个成员
            # 此时 esp 指向的是 *old 的地址
            movl %esp, 4(%eax) # and stack 将 esp 指向的地址的高4字节的数据即 *new 的第二个成员
            # 以下是将最少必要寄存器中的值存储在 *old 的第接下来的成员中
            movl %ebx, 8(%eax) # and other registers
            movl %ecx, 12(%eax)
            movl %edx, 16(%eax)
            movl %esi, 20(%eax)
            movl %edi, 24(%eax)
            movl %ebp, 28(%eax)

            # Load new registers
            movl 4(%esp), %eax # put new ptr into eax 此时的 4(%esp) 是 new 的地址
            # 以下是将 *new 的成员的值存储在最少必要寄存器中
            movl 28(%eax), %ebp # restore other registers
            movl 24(%eax), %edi
            movl 20(%eax), %esi
            movl 16(%eax), %edx
            movl 12(%eax), %ecx
            movl 8(%eax), %ebx
            movl 4(%eax), %esp # stack is switched here
            # 以下是将 *new 的第一个成员即返回地址压入栈中
            pushl 0(%eax) # return addr put in place
    ret # finally return into new ctxt

###############################################################################
# 代码总结：
# 1. 这段代码实现了xv6操作系统中的进程上下文切换功能
# 2. struct context结构体的内存布局：
#    - 起始地址与第一个字段(eip)地址相同
#    - 连续8个字段，每个4字节：eip(0)、esp(4)、ebx(8)、ecx(12)、edx(16)、esi(20)、edi(24)、ebp(28)
# 3. AT&T汇编语法要点：
#    - %前缀表示寄存器（如%eax）
#    - 0(%eax)表示寄存器内值作为地址，偏移量为0的内存位置
#    - 源操作数在左，目标操作数在右
# 4. 寄存器保存与恢复的顺序特点：
#    - 普通寄存器（ebx, ecx, edx, esi, edi, ebp）保存和恢复顺序理论上可以任意变化
#    - 恢复顺序必须严格遵循以下规则：
#       1. 先恢复普通寄存器(ebx, ecx, edx, esi, edi, ebp)
#       2. 然后恢复ESP寄存器（倒数第二个）
#       3. 最后恢复EIP（通过pushl和ret指令）
#    - 这是因为ESP恢复后立即切换到新栈，无法再访问旧栈数据
#    - EIP恢复后立即跳转到新位置，必须是最后一步
# 5. 保存的寄存器是最小必要集：
#    - 只保存callee-saved寄存器，不包括eax等caller-saved寄存器
#    - 这种精简设计使上下文切换既高效又易于理解
# 6. 栈的变化及其重要性：
#    - popl指令不仅取出数据，还自动调整栈指针
#    - ESP切换是上下文切换的关键点，表示从一个进程的栈转到另一个进程的栈
# 7. 关于EIP寄存器：
#    - EIP (Instruction Pointer) 是x86架构中的指令指针寄存器，也称为程序计数器
#    - 功能：存储CPU下一条要执行的指令的内存地址，控制程序执行流
#    - 工作方式：CPU执行时会不断重复以下步骤：
#      a. 从EIP指向的内存地址读取指令
#      b. 执行该指令
#      c. 自动更新EIP指向下一条指令
#    - 在本代码中对EIP的特殊处理：
#      a. 用户模式下无法直接修改EIP，需要间接操作（通过返回地址）
#      b. 保存阶段：通过popl 0(%eax)将返回地址保存到context结构体第一个字段
#      c. 恢复阶段：先用pushl 0(%eax)将返回地址压入栈，再用ret指令跳转
#      d. ret指令从栈顶弹出地址并加载到EIP，实现执行流的切换
#    - 为什么EIP必须最后恢复：一旦EIP被改变，执行立即跳转到新地址，不再返回
# 8. ret指令：
#    - 从栈顶弹出地址并加载到EIP，实现执行流的切换
#    - 执行ret指令时，栈顶的地址会被弹出并加载到EIP寄存器中，从而控制程序跳转到该地址继续执行
###############################################################################