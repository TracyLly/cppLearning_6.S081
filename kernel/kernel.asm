
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ac013103          	ld	sp,-1344(sp) # 80008ac0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	dc478793          	addi	a5,a5,-572 # 80005e20 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e6278793          	addi	a5,a5,-414 # 80000f08 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b4e080e7          	jalr	-1202(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	4ba080e7          	jalr	1210(ra) # 800025e0 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bc0080e7          	jalr	-1088(ra) # 80000d0e <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	abc080e7          	jalr	-1348(ra) # 80000c5a <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	942080e7          	jalr	-1726(ra) # 80001b10 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	14a080e7          	jalr	330(ra) # 80002328 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	370080e7          	jalr	880(ra) # 8000258a <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	ad8080e7          	jalr	-1320(ra) # 80000d0e <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	ac2080e7          	jalr	-1342(ra) # 80000d0e <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	97c080e7          	jalr	-1668(ra) # 80000c5a <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	33a080e7          	jalr	826(ra) # 80002636 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a02080e7          	jalr	-1534(ra) # 80000d0e <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	05e080e7          	jalr	94(ra) # 800024ae <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	758080e7          	jalr	1880(ra) # 80000bca <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	72e78793          	addi	a5,a5,1838 # 80021bb0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	650080e7          	jalr	1616(ra) # 80000c5a <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	5a0080e7          	jalr	1440(ra) # 80000d0e <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	436080e7          	jalr	1078(ra) # 80000bca <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	3e0080e7          	jalr	992(ra) # 80000bca <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	408080e7          	jalr	1032(ra) # 80000c0e <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	476080e7          	jalr	1142(ra) # 80000cae <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	bf8080e7          	jalr	-1032(ra) # 800024ae <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	360080e7          	jalr	864(ra) # 80000c5a <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	9d8080e7          	jalr	-1576(ra) # 80002328 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	37a080e7          	jalr	890(ra) # 80000d0e <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	25a080e7          	jalr	602(ra) # 80000c5a <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2fc080e7          	jalr	764(ra) # 80000d0e <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00026797          	auipc	a5,0x26
    80000a3c:	5e878793          	addi	a5,a5,1512 # 80027020 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	306080e7          	jalr	774(ra) # 80000d56 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1f8080e7          	jalr	504(ra) # 80000c5a <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	298080e7          	jalr	664(ra) # 80000d0e <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	0ce080e7          	jalr	206(ra) # 80000bca <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00026517          	auipc	a0,0x26
    80000b0c:	51850513          	addi	a0,a0,1304 # 80027020 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	126080e7          	jalr	294(ra) # 80000c5a <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	1c2080e7          	jalr	450(ra) # 80000d0e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1fc080e7          	jalr	508(ra) # 80000d56 <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	198080e7          	jalr	408(ra) # 80000d0e <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <kfreemem>:

// Return the number of bytes of free memory
// should be multiple of PGSIZE
uint64
kfreemem(void) {
    80000b80:	1101                	addi	sp,sp,-32
    80000b82:	ec06                	sd	ra,24(sp)
    80000b84:	e822                	sd	s0,16(sp)
    80000b86:	e426                	sd	s1,8(sp)
    80000b88:	1000                	addi	s0,sp,32
  struct run *r;
  uint64 free = 0;
  acquire(&kmem.lock);
    80000b8a:	00011497          	auipc	s1,0x11
    80000b8e:	da648493          	addi	s1,s1,-602 # 80011930 <kmem>
    80000b92:	8526                	mv	a0,s1
    80000b94:	00000097          	auipc	ra,0x0
    80000b98:	0c6080e7          	jalr	198(ra) # 80000c5a <acquire>
  r = kmem.freelist;
    80000b9c:	6c9c                	ld	a5,24(s1)
  while (r) {
    80000b9e:	c785                	beqz	a5,80000bc6 <kfreemem+0x46>
  uint64 free = 0;
    80000ba0:	4481                	li	s1,0
    free += PGSIZE;
    80000ba2:	6705                	lui	a4,0x1
    80000ba4:	94ba                	add	s1,s1,a4
    r = r->next;
    80000ba6:	639c                	ld	a5,0(a5)
  while (r) {
    80000ba8:	fff5                	bnez	a5,80000ba4 <kfreemem+0x24>
  }
  release(&kmem.lock);
    80000baa:	00011517          	auipc	a0,0x11
    80000bae:	d8650513          	addi	a0,a0,-634 # 80011930 <kmem>
    80000bb2:	00000097          	auipc	ra,0x0
    80000bb6:	15c080e7          	jalr	348(ra) # 80000d0e <release>
  return free;
}
    80000bba:	8526                	mv	a0,s1
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
  uint64 free = 0;
    80000bc6:	4481                	li	s1,0
    80000bc8:	b7cd                	j	80000baa <kfreemem+0x2a>

0000000080000bca <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bca:	1141                	addi	sp,sp,-16
    80000bcc:	e422                	sd	s0,8(sp)
    80000bce:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bd0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bd2:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bd6:	00053823          	sd	zero,16(a0)
}
    80000bda:	6422                	ld	s0,8(sp)
    80000bdc:	0141                	addi	sp,sp,16
    80000bde:	8082                	ret

0000000080000be0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	411c                	lw	a5,0(a0)
    80000be2:	e399                	bnez	a5,80000be8 <holding+0x8>
    80000be4:	4501                	li	a0,0
  return r;
}
    80000be6:	8082                	ret
{
    80000be8:	1101                	addi	sp,sp,-32
    80000bea:	ec06                	sd	ra,24(sp)
    80000bec:	e822                	sd	s0,16(sp)
    80000bee:	e426                	sd	s1,8(sp)
    80000bf0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bf2:	6904                	ld	s1,16(a0)
    80000bf4:	00001097          	auipc	ra,0x1
    80000bf8:	f00080e7          	jalr	-256(ra) # 80001af4 <mycpu>
    80000bfc:	40a48533          	sub	a0,s1,a0
    80000c00:	00153513          	seqz	a0,a0
}
    80000c04:	60e2                	ld	ra,24(sp)
    80000c06:	6442                	ld	s0,16(sp)
    80000c08:	64a2                	ld	s1,8(sp)
    80000c0a:	6105                	addi	sp,sp,32
    80000c0c:	8082                	ret

0000000080000c0e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c0e:	1101                	addi	sp,sp,-32
    80000c10:	ec06                	sd	ra,24(sp)
    80000c12:	e822                	sd	s0,16(sp)
    80000c14:	e426                	sd	s1,8(sp)
    80000c16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c18:	100024f3          	csrr	s1,sstatus
    80000c1c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c20:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c22:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c26:	00001097          	auipc	ra,0x1
    80000c2a:	ece080e7          	jalr	-306(ra) # 80001af4 <mycpu>
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	cf89                	beqz	a5,80000c4a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	ec2080e7          	jalr	-318(ra) # 80001af4 <mycpu>
    80000c3a:	5d3c                	lw	a5,120(a0)
    80000c3c:	2785                	addiw	a5,a5,1
    80000c3e:	dd3c                	sw	a5,120(a0)
}
    80000c40:	60e2                	ld	ra,24(sp)
    80000c42:	6442                	ld	s0,16(sp)
    80000c44:	64a2                	ld	s1,8(sp)
    80000c46:	6105                	addi	sp,sp,32
    80000c48:	8082                	ret
    mycpu()->intena = old;
    80000c4a:	00001097          	auipc	ra,0x1
    80000c4e:	eaa080e7          	jalr	-342(ra) # 80001af4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8085                	srli	s1,s1,0x1
    80000c54:	8885                	andi	s1,s1,1
    80000c56:	dd64                	sw	s1,124(a0)
    80000c58:	bfe9                	j	80000c32 <push_off+0x24>

0000000080000c5a <acquire>:
{
    80000c5a:	1101                	addi	sp,sp,-32
    80000c5c:	ec06                	sd	ra,24(sp)
    80000c5e:	e822                	sd	s0,16(sp)
    80000c60:	e426                	sd	s1,8(sp)
    80000c62:	1000                	addi	s0,sp,32
    80000c64:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c66:	00000097          	auipc	ra,0x0
    80000c6a:	fa8080e7          	jalr	-88(ra) # 80000c0e <push_off>
  if(holding(lk))
    80000c6e:	8526                	mv	a0,s1
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	f70080e7          	jalr	-144(ra) # 80000be0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c78:	4705                	li	a4,1
  if(holding(lk))
    80000c7a:	e115                	bnez	a0,80000c9e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c7c:	87ba                	mv	a5,a4
    80000c7e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c82:	2781                	sext.w	a5,a5
    80000c84:	ffe5                	bnez	a5,80000c7c <acquire+0x22>
  __sync_synchronize();
    80000c86:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c8a:	00001097          	auipc	ra,0x1
    80000c8e:	e6a080e7          	jalr	-406(ra) # 80001af4 <mycpu>
    80000c92:	e888                	sd	a0,16(s1)
}
    80000c94:	60e2                	ld	ra,24(sp)
    80000c96:	6442                	ld	s0,16(sp)
    80000c98:	64a2                	ld	s1,8(sp)
    80000c9a:	6105                	addi	sp,sp,32
    80000c9c:	8082                	ret
    panic("acquire");
    80000c9e:	00007517          	auipc	a0,0x7
    80000ca2:	3d250513          	addi	a0,a0,978 # 80008070 <digits+0x30>
    80000ca6:	00000097          	auipc	ra,0x0
    80000caa:	8a2080e7          	jalr	-1886(ra) # 80000548 <panic>

0000000080000cae <pop_off>:

void
pop_off(void)
{
    80000cae:	1141                	addi	sp,sp,-16
    80000cb0:	e406                	sd	ra,8(sp)
    80000cb2:	e022                	sd	s0,0(sp)
    80000cb4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cb6:	00001097          	auipc	ra,0x1
    80000cba:	e3e080e7          	jalr	-450(ra) # 80001af4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cbe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cc2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cc4:	e78d                	bnez	a5,80000cee <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cc6:	5d3c                	lw	a5,120(a0)
    80000cc8:	02f05b63          	blez	a5,80000cfe <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ccc:	37fd                	addiw	a5,a5,-1
    80000cce:	0007871b          	sext.w	a4,a5
    80000cd2:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cd4:	eb09                	bnez	a4,80000ce6 <pop_off+0x38>
    80000cd6:	5d7c                	lw	a5,124(a0)
    80000cd8:	c799                	beqz	a5,80000ce6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cda:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cde:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ce2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ce6:	60a2                	ld	ra,8(sp)
    80000ce8:	6402                	ld	s0,0(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret
    panic("pop_off - interruptible");
    80000cee:	00007517          	auipc	a0,0x7
    80000cf2:	38a50513          	addi	a0,a0,906 # 80008078 <digits+0x38>
    80000cf6:	00000097          	auipc	ra,0x0
    80000cfa:	852080e7          	jalr	-1966(ra) # 80000548 <panic>
    panic("pop_off");
    80000cfe:	00007517          	auipc	a0,0x7
    80000d02:	39250513          	addi	a0,a0,914 # 80008090 <digits+0x50>
    80000d06:	00000097          	auipc	ra,0x0
    80000d0a:	842080e7          	jalr	-1982(ra) # 80000548 <panic>

0000000080000d0e <release>:
{
    80000d0e:	1101                	addi	sp,sp,-32
    80000d10:	ec06                	sd	ra,24(sp)
    80000d12:	e822                	sd	s0,16(sp)
    80000d14:	e426                	sd	s1,8(sp)
    80000d16:	1000                	addi	s0,sp,32
    80000d18:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d1a:	00000097          	auipc	ra,0x0
    80000d1e:	ec6080e7          	jalr	-314(ra) # 80000be0 <holding>
    80000d22:	c115                	beqz	a0,80000d46 <release+0x38>
  lk->cpu = 0;
    80000d24:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d28:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d2c:	0f50000f          	fence	iorw,ow
    80000d30:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d34:	00000097          	auipc	ra,0x0
    80000d38:	f7a080e7          	jalr	-134(ra) # 80000cae <pop_off>
}
    80000d3c:	60e2                	ld	ra,24(sp)
    80000d3e:	6442                	ld	s0,16(sp)
    80000d40:	64a2                	ld	s1,8(sp)
    80000d42:	6105                	addi	sp,sp,32
    80000d44:	8082                	ret
    panic("release");
    80000d46:	00007517          	auipc	a0,0x7
    80000d4a:	35250513          	addi	a0,a0,850 # 80008098 <digits+0x58>
    80000d4e:	fffff097          	auipc	ra,0xfffff
    80000d52:	7fa080e7          	jalr	2042(ra) # 80000548 <panic>

0000000080000d56 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d5c:	ce09                	beqz	a2,80000d76 <memset+0x20>
    80000d5e:	87aa                	mv	a5,a0
    80000d60:	fff6071b          	addiw	a4,a2,-1
    80000d64:	1702                	slli	a4,a4,0x20
    80000d66:	9301                	srli	a4,a4,0x20
    80000d68:	0705                	addi	a4,a4,1
    80000d6a:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d6c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d70:	0785                	addi	a5,a5,1
    80000d72:	fee79de3          	bne	a5,a4,80000d6c <memset+0x16>
  }
  return dst;
}
    80000d76:	6422                	ld	s0,8(sp)
    80000d78:	0141                	addi	sp,sp,16
    80000d7a:	8082                	ret

0000000080000d7c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d7c:	1141                	addi	sp,sp,-16
    80000d7e:	e422                	sd	s0,8(sp)
    80000d80:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d82:	ca05                	beqz	a2,80000db2 <memcmp+0x36>
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	1682                	slli	a3,a3,0x20
    80000d8a:	9281                	srli	a3,a3,0x20
    80000d8c:	0685                	addi	a3,a3,1
    80000d8e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d90:	00054783          	lbu	a5,0(a0)
    80000d94:	0005c703          	lbu	a4,0(a1)
    80000d98:	00e79863          	bne	a5,a4,80000da8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d9c:	0505                	addi	a0,a0,1
    80000d9e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000da0:	fed518e3          	bne	a0,a3,80000d90 <memcmp+0x14>
  }

  return 0;
    80000da4:	4501                	li	a0,0
    80000da6:	a019                	j	80000dac <memcmp+0x30>
      return *s1 - *s2;
    80000da8:	40e7853b          	subw	a0,a5,a4
}
    80000dac:	6422                	ld	s0,8(sp)
    80000dae:	0141                	addi	sp,sp,16
    80000db0:	8082                	ret
  return 0;
    80000db2:	4501                	li	a0,0
    80000db4:	bfe5                	j	80000dac <memcmp+0x30>

0000000080000db6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000db6:	1141                	addi	sp,sp,-16
    80000db8:	e422                	sd	s0,8(sp)
    80000dba:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dbc:	00a5f963          	bgeu	a1,a0,80000dce <memmove+0x18>
    80000dc0:	02061713          	slli	a4,a2,0x20
    80000dc4:	9301                	srli	a4,a4,0x20
    80000dc6:	00e587b3          	add	a5,a1,a4
    80000dca:	02f56563          	bltu	a0,a5,80000df4 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dce:	fff6069b          	addiw	a3,a2,-1
    80000dd2:	ce11                	beqz	a2,80000dee <memmove+0x38>
    80000dd4:	1682                	slli	a3,a3,0x20
    80000dd6:	9281                	srli	a3,a3,0x20
    80000dd8:	0685                	addi	a3,a3,1
    80000dda:	96ae                	add	a3,a3,a1
    80000ddc:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000dde:	0585                	addi	a1,a1,1
    80000de0:	0785                	addi	a5,a5,1
    80000de2:	fff5c703          	lbu	a4,-1(a1)
    80000de6:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dea:	fed59ae3          	bne	a1,a3,80000dde <memmove+0x28>

  return dst;
}
    80000dee:	6422                	ld	s0,8(sp)
    80000df0:	0141                	addi	sp,sp,16
    80000df2:	8082                	ret
    d += n;
    80000df4:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000df6:	fff6069b          	addiw	a3,a2,-1
    80000dfa:	da75                	beqz	a2,80000dee <memmove+0x38>
    80000dfc:	02069613          	slli	a2,a3,0x20
    80000e00:	9201                	srli	a2,a2,0x20
    80000e02:	fff64613          	not	a2,a2
    80000e06:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e08:	17fd                	addi	a5,a5,-1
    80000e0a:	177d                	addi	a4,a4,-1
    80000e0c:	0007c683          	lbu	a3,0(a5)
    80000e10:	00d70023          	sb	a3,0(a4) # 1000 <_entry-0x7ffff000>
    while(n-- > 0)
    80000e14:	fec79ae3          	bne	a5,a2,80000e08 <memmove+0x52>
    80000e18:	bfd9                	j	80000dee <memmove+0x38>

0000000080000e1a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e1a:	1141                	addi	sp,sp,-16
    80000e1c:	e406                	sd	ra,8(sp)
    80000e1e:	e022                	sd	s0,0(sp)
    80000e20:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e22:	00000097          	auipc	ra,0x0
    80000e26:	f94080e7          	jalr	-108(ra) # 80000db6 <memmove>
}
    80000e2a:	60a2                	ld	ra,8(sp)
    80000e2c:	6402                	ld	s0,0(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e38:	ce11                	beqz	a2,80000e54 <strncmp+0x22>
    80000e3a:	00054783          	lbu	a5,0(a0)
    80000e3e:	cf89                	beqz	a5,80000e58 <strncmp+0x26>
    80000e40:	0005c703          	lbu	a4,0(a1)
    80000e44:	00f71a63          	bne	a4,a5,80000e58 <strncmp+0x26>
    n--, p++, q++;
    80000e48:	367d                	addiw	a2,a2,-1
    80000e4a:	0505                	addi	a0,a0,1
    80000e4c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e4e:	f675                	bnez	a2,80000e3a <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e50:	4501                	li	a0,0
    80000e52:	a809                	j	80000e64 <strncmp+0x32>
    80000e54:	4501                	li	a0,0
    80000e56:	a039                	j	80000e64 <strncmp+0x32>
  if(n == 0)
    80000e58:	ca09                	beqz	a2,80000e6a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e5a:	00054503          	lbu	a0,0(a0)
    80000e5e:	0005c783          	lbu	a5,0(a1)
    80000e62:	9d1d                	subw	a0,a0,a5
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret
    return 0;
    80000e6a:	4501                	li	a0,0
    80000e6c:	bfe5                	j	80000e64 <strncmp+0x32>

0000000080000e6e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e6e:	1141                	addi	sp,sp,-16
    80000e70:	e422                	sd	s0,8(sp)
    80000e72:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e74:	872a                	mv	a4,a0
    80000e76:	8832                	mv	a6,a2
    80000e78:	367d                	addiw	a2,a2,-1
    80000e7a:	01005963          	blez	a6,80000e8c <strncpy+0x1e>
    80000e7e:	0705                	addi	a4,a4,1
    80000e80:	0005c783          	lbu	a5,0(a1)
    80000e84:	fef70fa3          	sb	a5,-1(a4)
    80000e88:	0585                	addi	a1,a1,1
    80000e8a:	f7f5                	bnez	a5,80000e76 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e8c:	00c05d63          	blez	a2,80000ea6 <strncpy+0x38>
    80000e90:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e92:	0685                	addi	a3,a3,1
    80000e94:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e98:	fff6c793          	not	a5,a3
    80000e9c:	9fb9                	addw	a5,a5,a4
    80000e9e:	010787bb          	addw	a5,a5,a6
    80000ea2:	fef048e3          	bgtz	a5,80000e92 <strncpy+0x24>
  return os;
}
    80000ea6:	6422                	ld	s0,8(sp)
    80000ea8:	0141                	addi	sp,sp,16
    80000eaa:	8082                	ret

0000000080000eac <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000eac:	1141                	addi	sp,sp,-16
    80000eae:	e422                	sd	s0,8(sp)
    80000eb0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eb2:	02c05363          	blez	a2,80000ed8 <safestrcpy+0x2c>
    80000eb6:	fff6069b          	addiw	a3,a2,-1
    80000eba:	1682                	slli	a3,a3,0x20
    80000ebc:	9281                	srli	a3,a3,0x20
    80000ebe:	96ae                	add	a3,a3,a1
    80000ec0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ec2:	00d58963          	beq	a1,a3,80000ed4 <safestrcpy+0x28>
    80000ec6:	0585                	addi	a1,a1,1
    80000ec8:	0785                	addi	a5,a5,1
    80000eca:	fff5c703          	lbu	a4,-1(a1)
    80000ece:	fee78fa3          	sb	a4,-1(a5)
    80000ed2:	fb65                	bnez	a4,80000ec2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ed4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ed8:	6422                	ld	s0,8(sp)
    80000eda:	0141                	addi	sp,sp,16
    80000edc:	8082                	ret

0000000080000ede <strlen>:

int
strlen(const char *s)
{
    80000ede:	1141                	addi	sp,sp,-16
    80000ee0:	e422                	sd	s0,8(sp)
    80000ee2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ee4:	00054783          	lbu	a5,0(a0)
    80000ee8:	cf91                	beqz	a5,80000f04 <strlen+0x26>
    80000eea:	0505                	addi	a0,a0,1
    80000eec:	87aa                	mv	a5,a0
    80000eee:	4685                	li	a3,1
    80000ef0:	9e89                	subw	a3,a3,a0
    80000ef2:	00f6853b          	addw	a0,a3,a5
    80000ef6:	0785                	addi	a5,a5,1
    80000ef8:	fff7c703          	lbu	a4,-1(a5)
    80000efc:	fb7d                	bnez	a4,80000ef2 <strlen+0x14>
    ;
  return n;
}
    80000efe:	6422                	ld	s0,8(sp)
    80000f00:	0141                	addi	sp,sp,16
    80000f02:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f04:	4501                	li	a0,0
    80000f06:	bfe5                	j	80000efe <strlen+0x20>

0000000080000f08 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f08:	1141                	addi	sp,sp,-16
    80000f0a:	e406                	sd	ra,8(sp)
    80000f0c:	e022                	sd	s0,0(sp)
    80000f0e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f10:	00001097          	auipc	ra,0x1
    80000f14:	bd4080e7          	jalr	-1068(ra) # 80001ae4 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f18:	00008717          	auipc	a4,0x8
    80000f1c:	0f470713          	addi	a4,a4,244 # 8000900c <started>
  if(cpuid() == 0){
    80000f20:	c139                	beqz	a0,80000f66 <main+0x5e>
    while(started == 0)
    80000f22:	431c                	lw	a5,0(a4)
    80000f24:	2781                	sext.w	a5,a5
    80000f26:	dff5                	beqz	a5,80000f22 <main+0x1a>
      ;
    __sync_synchronize();
    80000f28:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f2c:	00001097          	auipc	ra,0x1
    80000f30:	bb8080e7          	jalr	-1096(ra) # 80001ae4 <cpuid>
    80000f34:	85aa                	mv	a1,a0
    80000f36:	00007517          	auipc	a0,0x7
    80000f3a:	18250513          	addi	a0,a0,386 # 800080b8 <digits+0x78>
    80000f3e:	fffff097          	auipc	ra,0xfffff
    80000f42:	654080e7          	jalr	1620(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	0e0080e7          	jalr	224(ra) # 80001026 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f4e:	00002097          	auipc	ra,0x2
    80000f52:	87c080e7          	jalr	-1924(ra) # 800027ca <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f56:	00005097          	auipc	ra,0x5
    80000f5a:	f0a080e7          	jalr	-246(ra) # 80005e60 <plicinithart>
  }

  scheduler();        
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	0ee080e7          	jalr	238(ra) # 8000204c <scheduler>
    consoleinit();
    80000f66:	fffff097          	auipc	ra,0xfffff
    80000f6a:	4f4080e7          	jalr	1268(ra) # 8000045a <consoleinit>
    statsinit();
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	6b4080e7          	jalr	1716(ra) # 80006622 <statsinit>
    printfinit();
    80000f76:	00000097          	auipc	ra,0x0
    80000f7a:	802080e7          	jalr	-2046(ra) # 80000778 <printfinit>
    printf("\n");
    80000f7e:	00007517          	auipc	a0,0x7
    80000f82:	14a50513          	addi	a0,a0,330 # 800080c8 <digits+0x88>
    80000f86:	fffff097          	auipc	ra,0xfffff
    80000f8a:	60c080e7          	jalr	1548(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f8e:	00007517          	auipc	a0,0x7
    80000f92:	11250513          	addi	a0,a0,274 # 800080a0 <digits+0x60>
    80000f96:	fffff097          	auipc	ra,0xfffff
    80000f9a:	5fc080e7          	jalr	1532(ra) # 80000592 <printf>
    printf("\n");
    80000f9e:	00007517          	auipc	a0,0x7
    80000fa2:	12a50513          	addi	a0,a0,298 # 800080c8 <digits+0x88>
    80000fa6:	fffff097          	auipc	ra,0xfffff
    80000faa:	5ec080e7          	jalr	1516(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000fae:	00000097          	auipc	ra,0x0
    80000fb2:	b36080e7          	jalr	-1226(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000fb6:	00000097          	auipc	ra,0x0
    80000fba:	2a0080e7          	jalr	672(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000fbe:	00000097          	auipc	ra,0x0
    80000fc2:	068080e7          	jalr	104(ra) # 80001026 <kvminithart>
    procinit();      // process table
    80000fc6:	00001097          	auipc	ra,0x1
    80000fca:	a4e080e7          	jalr	-1458(ra) # 80001a14 <procinit>
    trapinit();      // trap vectors
    80000fce:	00001097          	auipc	ra,0x1
    80000fd2:	7d4080e7          	jalr	2004(ra) # 800027a2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fd6:	00001097          	auipc	ra,0x1
    80000fda:	7f4080e7          	jalr	2036(ra) # 800027ca <trapinithart>
    plicinit();      // set up interrupt controller
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	e6c080e7          	jalr	-404(ra) # 80005e4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fe6:	00005097          	auipc	ra,0x5
    80000fea:	e7a080e7          	jalr	-390(ra) # 80005e60 <plicinithart>
    binit();         // buffer cache
    80000fee:	00002097          	auipc	ra,0x2
    80000ff2:	ffa080e7          	jalr	-6(ra) # 80002fe8 <binit>
    iinit();         // inode cache
    80000ff6:	00002097          	auipc	ra,0x2
    80000ffa:	68a080e7          	jalr	1674(ra) # 80003680 <iinit>
    fileinit();      // file table
    80000ffe:	00003097          	auipc	ra,0x3
    80001002:	624080e7          	jalr	1572(ra) # 80004622 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001006:	00005097          	auipc	ra,0x5
    8000100a:	f62080e7          	jalr	-158(ra) # 80005f68 <virtio_disk_init>
    userinit();      // first user process
    8000100e:	00001097          	auipc	ra,0x1
    80001012:	dd0080e7          	jalr	-560(ra) # 80001dde <userinit>
    __sync_synchronize();
    80001016:	0ff0000f          	fence
    started = 1;
    8000101a:	4785                	li	a5,1
    8000101c:	00008717          	auipc	a4,0x8
    80001020:	fef72823          	sw	a5,-16(a4) # 8000900c <started>
    80001024:	bf2d                	j	80000f5e <main+0x56>

0000000080001026 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001026:	1141                	addi	sp,sp,-16
    80001028:	e422                	sd	s0,8(sp)
    8000102a:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000102c:	00008797          	auipc	a5,0x8
    80001030:	fe47b783          	ld	a5,-28(a5) # 80009010 <kernel_pagetable>
    80001034:	83b1                	srli	a5,a5,0xc
    80001036:	577d                	li	a4,-1
    80001038:	177e                	slli	a4,a4,0x3f
    8000103a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000103c:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001040:	12000073          	sfence.vma
  sfence_vma();
}
    80001044:	6422                	ld	s0,8(sp)
    80001046:	0141                	addi	sp,sp,16
    80001048:	8082                	ret

000000008000104a <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000104a:	7139                	addi	sp,sp,-64
    8000104c:	fc06                	sd	ra,56(sp)
    8000104e:	f822                	sd	s0,48(sp)
    80001050:	f426                	sd	s1,40(sp)
    80001052:	f04a                	sd	s2,32(sp)
    80001054:	ec4e                	sd	s3,24(sp)
    80001056:	e852                	sd	s4,16(sp)
    80001058:	e456                	sd	s5,8(sp)
    8000105a:	e05a                	sd	s6,0(sp)
    8000105c:	0080                	addi	s0,sp,64
    8000105e:	84aa                	mv	s1,a0
    80001060:	89ae                	mv	s3,a1
    80001062:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001064:	57fd                	li	a5,-1
    80001066:	83e9                	srli	a5,a5,0x1a
    80001068:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000106a:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000106c:	04b7f263          	bgeu	a5,a1,800010b0 <walk+0x66>
    panic("walk");
    80001070:	00007517          	auipc	a0,0x7
    80001074:	06050513          	addi	a0,a0,96 # 800080d0 <digits+0x90>
    80001078:	fffff097          	auipc	ra,0xfffff
    8000107c:	4d0080e7          	jalr	1232(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001080:	060a8663          	beqz	s5,800010ec <walk+0xa2>
    80001084:	00000097          	auipc	ra,0x0
    80001088:	a9c080e7          	jalr	-1380(ra) # 80000b20 <kalloc>
    8000108c:	84aa                	mv	s1,a0
    8000108e:	c529                	beqz	a0,800010d8 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001090:	6605                	lui	a2,0x1
    80001092:	4581                	li	a1,0
    80001094:	00000097          	auipc	ra,0x0
    80001098:	cc2080e7          	jalr	-830(ra) # 80000d56 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000109c:	00c4d793          	srli	a5,s1,0xc
    800010a0:	07aa                	slli	a5,a5,0xa
    800010a2:	0017e793          	ori	a5,a5,1
    800010a6:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010aa:	3a5d                	addiw	s4,s4,-9
    800010ac:	036a0063          	beq	s4,s6,800010cc <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010b0:	0149d933          	srl	s2,s3,s4
    800010b4:	1ff97913          	andi	s2,s2,511
    800010b8:	090e                	slli	s2,s2,0x3
    800010ba:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010bc:	00093483          	ld	s1,0(s2)
    800010c0:	0014f793          	andi	a5,s1,1
    800010c4:	dfd5                	beqz	a5,80001080 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010c6:	80a9                	srli	s1,s1,0xa
    800010c8:	04b2                	slli	s1,s1,0xc
    800010ca:	b7c5                	j	800010aa <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010cc:	00c9d513          	srli	a0,s3,0xc
    800010d0:	1ff57513          	andi	a0,a0,511
    800010d4:	050e                	slli	a0,a0,0x3
    800010d6:	9526                	add	a0,a0,s1
}
    800010d8:	70e2                	ld	ra,56(sp)
    800010da:	7442                	ld	s0,48(sp)
    800010dc:	74a2                	ld	s1,40(sp)
    800010de:	7902                	ld	s2,32(sp)
    800010e0:	69e2                	ld	s3,24(sp)
    800010e2:	6a42                	ld	s4,16(sp)
    800010e4:	6aa2                	ld	s5,8(sp)
    800010e6:	6b02                	ld	s6,0(sp)
    800010e8:	6121                	addi	sp,sp,64
    800010ea:	8082                	ret
        return 0;
    800010ec:	4501                	li	a0,0
    800010ee:	b7ed                	j	800010d8 <walk+0x8e>

00000000800010f0 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010f0:	57fd                	li	a5,-1
    800010f2:	83e9                	srli	a5,a5,0x1a
    800010f4:	00b7f463          	bgeu	a5,a1,800010fc <walkaddr+0xc>
    return 0;
    800010f8:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010fa:	8082                	ret
{
    800010fc:	1141                	addi	sp,sp,-16
    800010fe:	e406                	sd	ra,8(sp)
    80001100:	e022                	sd	s0,0(sp)
    80001102:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001104:	4601                	li	a2,0
    80001106:	00000097          	auipc	ra,0x0
    8000110a:	f44080e7          	jalr	-188(ra) # 8000104a <walk>
  if(pte == 0)
    8000110e:	c105                	beqz	a0,8000112e <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001110:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001112:	0117f693          	andi	a3,a5,17
    80001116:	4745                	li	a4,17
    return 0;
    80001118:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000111a:	00e68663          	beq	a3,a4,80001126 <walkaddr+0x36>
}
    8000111e:	60a2                	ld	ra,8(sp)
    80001120:	6402                	ld	s0,0(sp)
    80001122:	0141                	addi	sp,sp,16
    80001124:	8082                	ret
  pa = PTE2PA(*pte);
    80001126:	00a7d513          	srli	a0,a5,0xa
    8000112a:	0532                	slli	a0,a0,0xc
  return pa;
    8000112c:	bfcd                	j	8000111e <walkaddr+0x2e>
    return 0;
    8000112e:	4501                	li	a0,0
    80001130:	b7fd                	j	8000111e <walkaddr+0x2e>

0000000080001132 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001132:	1101                	addi	sp,sp,-32
    80001134:	ec06                	sd	ra,24(sp)
    80001136:	e822                	sd	s0,16(sp)
    80001138:	e426                	sd	s1,8(sp)
    8000113a:	1000                	addi	s0,sp,32
    8000113c:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    8000113e:	1552                	slli	a0,a0,0x34
    80001140:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001144:	4601                	li	a2,0
    80001146:	00008517          	auipc	a0,0x8
    8000114a:	eca53503          	ld	a0,-310(a0) # 80009010 <kernel_pagetable>
    8000114e:	00000097          	auipc	ra,0x0
    80001152:	efc080e7          	jalr	-260(ra) # 8000104a <walk>
  if(pte == 0)
    80001156:	cd09                	beqz	a0,80001170 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001158:	6108                	ld	a0,0(a0)
    8000115a:	00157793          	andi	a5,a0,1
    8000115e:	c38d                	beqz	a5,80001180 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001160:	8129                	srli	a0,a0,0xa
    80001162:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001164:	9526                	add	a0,a0,s1
    80001166:	60e2                	ld	ra,24(sp)
    80001168:	6442                	ld	s0,16(sp)
    8000116a:	64a2                	ld	s1,8(sp)
    8000116c:	6105                	addi	sp,sp,32
    8000116e:	8082                	ret
    panic("kvmpa");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f6850513          	addi	a0,a0,-152 # 800080d8 <digits+0x98>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3d0080e7          	jalr	976(ra) # 80000548 <panic>
    panic("kvmpa");
    80001180:	00007517          	auipc	a0,0x7
    80001184:	f5850513          	addi	a0,a0,-168 # 800080d8 <digits+0x98>
    80001188:	fffff097          	auipc	ra,0xfffff
    8000118c:	3c0080e7          	jalr	960(ra) # 80000548 <panic>

0000000080001190 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001190:	715d                	addi	sp,sp,-80
    80001192:	e486                	sd	ra,72(sp)
    80001194:	e0a2                	sd	s0,64(sp)
    80001196:	fc26                	sd	s1,56(sp)
    80001198:	f84a                	sd	s2,48(sp)
    8000119a:	f44e                	sd	s3,40(sp)
    8000119c:	f052                	sd	s4,32(sp)
    8000119e:	ec56                	sd	s5,24(sp)
    800011a0:	e85a                	sd	s6,16(sp)
    800011a2:	e45e                	sd	s7,8(sp)
    800011a4:	0880                	addi	s0,sp,80
    800011a6:	8aaa                	mv	s5,a0
    800011a8:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011aa:	777d                	lui	a4,0xfffff
    800011ac:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011b0:	167d                	addi	a2,a2,-1
    800011b2:	00b609b3          	add	s3,a2,a1
    800011b6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011ba:	893e                	mv	s2,a5
    800011bc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011c0:	6b85                	lui	s7,0x1
    800011c2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011c6:	4605                	li	a2,1
    800011c8:	85ca                	mv	a1,s2
    800011ca:	8556                	mv	a0,s5
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	e7e080e7          	jalr	-386(ra) # 8000104a <walk>
    800011d4:	c51d                	beqz	a0,80001202 <mappages+0x72>
    if(*pte & PTE_V)
    800011d6:	611c                	ld	a5,0(a0)
    800011d8:	8b85                	andi	a5,a5,1
    800011da:	ef81                	bnez	a5,800011f2 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011dc:	80b1                	srli	s1,s1,0xc
    800011de:	04aa                	slli	s1,s1,0xa
    800011e0:	0164e4b3          	or	s1,s1,s6
    800011e4:	0014e493          	ori	s1,s1,1
    800011e8:	e104                	sd	s1,0(a0)
    if(a == last)
    800011ea:	03390863          	beq	s2,s3,8000121a <mappages+0x8a>
    a += PGSIZE;
    800011ee:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011f0:	bfc9                	j	800011c2 <mappages+0x32>
      panic("remap");
    800011f2:	00007517          	auipc	a0,0x7
    800011f6:	eee50513          	addi	a0,a0,-274 # 800080e0 <digits+0xa0>
    800011fa:	fffff097          	auipc	ra,0xfffff
    800011fe:	34e080e7          	jalr	846(ra) # 80000548 <panic>
      return -1;
    80001202:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001204:	60a6                	ld	ra,72(sp)
    80001206:	6406                	ld	s0,64(sp)
    80001208:	74e2                	ld	s1,56(sp)
    8000120a:	7942                	ld	s2,48(sp)
    8000120c:	79a2                	ld	s3,40(sp)
    8000120e:	7a02                	ld	s4,32(sp)
    80001210:	6ae2                	ld	s5,24(sp)
    80001212:	6b42                	ld	s6,16(sp)
    80001214:	6ba2                	ld	s7,8(sp)
    80001216:	6161                	addi	sp,sp,80
    80001218:	8082                	ret
  return 0;
    8000121a:	4501                	li	a0,0
    8000121c:	b7e5                	j	80001204 <mappages+0x74>

000000008000121e <kvmmap>:
{
    8000121e:	1141                	addi	sp,sp,-16
    80001220:	e406                	sd	ra,8(sp)
    80001222:	e022                	sd	s0,0(sp)
    80001224:	0800                	addi	s0,sp,16
    80001226:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001228:	86ae                	mv	a3,a1
    8000122a:	85aa                	mv	a1,a0
    8000122c:	00008517          	auipc	a0,0x8
    80001230:	de453503          	ld	a0,-540(a0) # 80009010 <kernel_pagetable>
    80001234:	00000097          	auipc	ra,0x0
    80001238:	f5c080e7          	jalr	-164(ra) # 80001190 <mappages>
    8000123c:	e509                	bnez	a0,80001246 <kvmmap+0x28>
}
    8000123e:	60a2                	ld	ra,8(sp)
    80001240:	6402                	ld	s0,0(sp)
    80001242:	0141                	addi	sp,sp,16
    80001244:	8082                	ret
    panic("kvmmap");
    80001246:	00007517          	auipc	a0,0x7
    8000124a:	ea250513          	addi	a0,a0,-350 # 800080e8 <digits+0xa8>
    8000124e:	fffff097          	auipc	ra,0xfffff
    80001252:	2fa080e7          	jalr	762(ra) # 80000548 <panic>

0000000080001256 <kvminit>:
{
    80001256:	1101                	addi	sp,sp,-32
    80001258:	ec06                	sd	ra,24(sp)
    8000125a:	e822                	sd	s0,16(sp)
    8000125c:	e426                	sd	s1,8(sp)
    8000125e:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001260:	00000097          	auipc	ra,0x0
    80001264:	8c0080e7          	jalr	-1856(ra) # 80000b20 <kalloc>
    80001268:	00008797          	auipc	a5,0x8
    8000126c:	daa7b423          	sd	a0,-600(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001270:	6605                	lui	a2,0x1
    80001272:	4581                	li	a1,0
    80001274:	00000097          	auipc	ra,0x0
    80001278:	ae2080e7          	jalr	-1310(ra) # 80000d56 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000127c:	4699                	li	a3,6
    8000127e:	6605                	lui	a2,0x1
    80001280:	100005b7          	lui	a1,0x10000
    80001284:	10000537          	lui	a0,0x10000
    80001288:	00000097          	auipc	ra,0x0
    8000128c:	f96080e7          	jalr	-106(ra) # 8000121e <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001290:	4699                	li	a3,6
    80001292:	6605                	lui	a2,0x1
    80001294:	100015b7          	lui	a1,0x10001
    80001298:	10001537          	lui	a0,0x10001
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f82080e7          	jalr	-126(ra) # 8000121e <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012a4:	4699                	li	a3,6
    800012a6:	6641                	lui	a2,0x10
    800012a8:	020005b7          	lui	a1,0x2000
    800012ac:	02000537          	lui	a0,0x2000
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	f6e080e7          	jalr	-146(ra) # 8000121e <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012b8:	4699                	li	a3,6
    800012ba:	00400637          	lui	a2,0x400
    800012be:	0c0005b7          	lui	a1,0xc000
    800012c2:	0c000537          	lui	a0,0xc000
    800012c6:	00000097          	auipc	ra,0x0
    800012ca:	f58080e7          	jalr	-168(ra) # 8000121e <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012ce:	00007497          	auipc	s1,0x7
    800012d2:	d3248493          	addi	s1,s1,-718 # 80008000 <etext>
    800012d6:	46a9                	li	a3,10
    800012d8:	80007617          	auipc	a2,0x80007
    800012dc:	d2860613          	addi	a2,a2,-728 # 8000 <_entry-0x7fff8000>
    800012e0:	4585                	li	a1,1
    800012e2:	05fe                	slli	a1,a1,0x1f
    800012e4:	852e                	mv	a0,a1
    800012e6:	00000097          	auipc	ra,0x0
    800012ea:	f38080e7          	jalr	-200(ra) # 8000121e <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012ee:	4699                	li	a3,6
    800012f0:	4645                	li	a2,17
    800012f2:	066e                	slli	a2,a2,0x1b
    800012f4:	8e05                	sub	a2,a2,s1
    800012f6:	85a6                	mv	a1,s1
    800012f8:	8526                	mv	a0,s1
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	f24080e7          	jalr	-220(ra) # 8000121e <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001302:	46a9                	li	a3,10
    80001304:	6605                	lui	a2,0x1
    80001306:	00006597          	auipc	a1,0x6
    8000130a:	cfa58593          	addi	a1,a1,-774 # 80007000 <_trampoline>
    8000130e:	04000537          	lui	a0,0x4000
    80001312:	157d                	addi	a0,a0,-1
    80001314:	0532                	slli	a0,a0,0xc
    80001316:	00000097          	auipc	ra,0x0
    8000131a:	f08080e7          	jalr	-248(ra) # 8000121e <kvmmap>
}
    8000131e:	60e2                	ld	ra,24(sp)
    80001320:	6442                	ld	s0,16(sp)
    80001322:	64a2                	ld	s1,8(sp)
    80001324:	6105                	addi	sp,sp,32
    80001326:	8082                	ret

0000000080001328 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001328:	715d                	addi	sp,sp,-80
    8000132a:	e486                	sd	ra,72(sp)
    8000132c:	e0a2                	sd	s0,64(sp)
    8000132e:	fc26                	sd	s1,56(sp)
    80001330:	f84a                	sd	s2,48(sp)
    80001332:	f44e                	sd	s3,40(sp)
    80001334:	f052                	sd	s4,32(sp)
    80001336:	ec56                	sd	s5,24(sp)
    80001338:	e85a                	sd	s6,16(sp)
    8000133a:	e45e                	sd	s7,8(sp)
    8000133c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000133e:	03459793          	slli	a5,a1,0x34
    80001342:	e795                	bnez	a5,8000136e <uvmunmap+0x46>
    80001344:	8a2a                	mv	s4,a0
    80001346:	892e                	mv	s2,a1
    80001348:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134a:	0632                	slli	a2,a2,0xc
    8000134c:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001350:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001352:	6b05                	lui	s6,0x1
    80001354:	0735e863          	bltu	a1,s3,800013c4 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001358:	60a6                	ld	ra,72(sp)
    8000135a:	6406                	ld	s0,64(sp)
    8000135c:	74e2                	ld	s1,56(sp)
    8000135e:	7942                	ld	s2,48(sp)
    80001360:	79a2                	ld	s3,40(sp)
    80001362:	7a02                	ld	s4,32(sp)
    80001364:	6ae2                	ld	s5,24(sp)
    80001366:	6b42                	ld	s6,16(sp)
    80001368:	6ba2                	ld	s7,8(sp)
    8000136a:	6161                	addi	sp,sp,80
    8000136c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000136e:	00007517          	auipc	a0,0x7
    80001372:	d8250513          	addi	a0,a0,-638 # 800080f0 <digits+0xb0>
    80001376:	fffff097          	auipc	ra,0xfffff
    8000137a:	1d2080e7          	jalr	466(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    8000137e:	00007517          	auipc	a0,0x7
    80001382:	d8a50513          	addi	a0,a0,-630 # 80008108 <digits+0xc8>
    80001386:	fffff097          	auipc	ra,0xfffff
    8000138a:	1c2080e7          	jalr	450(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    8000138e:	00007517          	auipc	a0,0x7
    80001392:	d8a50513          	addi	a0,a0,-630 # 80008118 <digits+0xd8>
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	1b2080e7          	jalr	434(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    8000139e:	00007517          	auipc	a0,0x7
    800013a2:	d9250513          	addi	a0,a0,-622 # 80008130 <digits+0xf0>
    800013a6:	fffff097          	auipc	ra,0xfffff
    800013aa:	1a2080e7          	jalr	418(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800013ae:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013b0:	0532                	slli	a0,a0,0xc
    800013b2:	fffff097          	auipc	ra,0xfffff
    800013b6:	672080e7          	jalr	1650(ra) # 80000a24 <kfree>
    *pte = 0;
    800013ba:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013be:	995a                	add	s2,s2,s6
    800013c0:	f9397ce3          	bgeu	s2,s3,80001358 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013c4:	4601                	li	a2,0
    800013c6:	85ca                	mv	a1,s2
    800013c8:	8552                	mv	a0,s4
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	c80080e7          	jalr	-896(ra) # 8000104a <walk>
    800013d2:	84aa                	mv	s1,a0
    800013d4:	d54d                	beqz	a0,8000137e <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013d6:	6108                	ld	a0,0(a0)
    800013d8:	00157793          	andi	a5,a0,1
    800013dc:	dbcd                	beqz	a5,8000138e <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013de:	3ff57793          	andi	a5,a0,1023
    800013e2:	fb778ee3          	beq	a5,s7,8000139e <uvmunmap+0x76>
    if(do_free){
    800013e6:	fc0a8ae3          	beqz	s5,800013ba <uvmunmap+0x92>
    800013ea:	b7d1                	j	800013ae <uvmunmap+0x86>

00000000800013ec <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013ec:	1101                	addi	sp,sp,-32
    800013ee:	ec06                	sd	ra,24(sp)
    800013f0:	e822                	sd	s0,16(sp)
    800013f2:	e426                	sd	s1,8(sp)
    800013f4:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013f6:	fffff097          	auipc	ra,0xfffff
    800013fa:	72a080e7          	jalr	1834(ra) # 80000b20 <kalloc>
    800013fe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001400:	c519                	beqz	a0,8000140e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001402:	6605                	lui	a2,0x1
    80001404:	4581                	li	a1,0
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	950080e7          	jalr	-1712(ra) # 80000d56 <memset>
  return pagetable;
}
    8000140e:	8526                	mv	a0,s1
    80001410:	60e2                	ld	ra,24(sp)
    80001412:	6442                	ld	s0,16(sp)
    80001414:	64a2                	ld	s1,8(sp)
    80001416:	6105                	addi	sp,sp,32
    80001418:	8082                	ret

000000008000141a <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000141a:	7179                	addi	sp,sp,-48
    8000141c:	f406                	sd	ra,40(sp)
    8000141e:	f022                	sd	s0,32(sp)
    80001420:	ec26                	sd	s1,24(sp)
    80001422:	e84a                	sd	s2,16(sp)
    80001424:	e44e                	sd	s3,8(sp)
    80001426:	e052                	sd	s4,0(sp)
    80001428:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000142a:	6785                	lui	a5,0x1
    8000142c:	04f67863          	bgeu	a2,a5,8000147c <uvminit+0x62>
    80001430:	8a2a                	mv	s4,a0
    80001432:	89ae                	mv	s3,a1
    80001434:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001436:	fffff097          	auipc	ra,0xfffff
    8000143a:	6ea080e7          	jalr	1770(ra) # 80000b20 <kalloc>
    8000143e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001440:	6605                	lui	a2,0x1
    80001442:	4581                	li	a1,0
    80001444:	00000097          	auipc	ra,0x0
    80001448:	912080e7          	jalr	-1774(ra) # 80000d56 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000144c:	4779                	li	a4,30
    8000144e:	86ca                	mv	a3,s2
    80001450:	6605                	lui	a2,0x1
    80001452:	4581                	li	a1,0
    80001454:	8552                	mv	a0,s4
    80001456:	00000097          	auipc	ra,0x0
    8000145a:	d3a080e7          	jalr	-710(ra) # 80001190 <mappages>
  memmove(mem, src, sz);
    8000145e:	8626                	mv	a2,s1
    80001460:	85ce                	mv	a1,s3
    80001462:	854a                	mv	a0,s2
    80001464:	00000097          	auipc	ra,0x0
    80001468:	952080e7          	jalr	-1710(ra) # 80000db6 <memmove>
}
    8000146c:	70a2                	ld	ra,40(sp)
    8000146e:	7402                	ld	s0,32(sp)
    80001470:	64e2                	ld	s1,24(sp)
    80001472:	6942                	ld	s2,16(sp)
    80001474:	69a2                	ld	s3,8(sp)
    80001476:	6a02                	ld	s4,0(sp)
    80001478:	6145                	addi	sp,sp,48
    8000147a:	8082                	ret
    panic("inituvm: more than a page");
    8000147c:	00007517          	auipc	a0,0x7
    80001480:	ccc50513          	addi	a0,a0,-820 # 80008148 <digits+0x108>
    80001484:	fffff097          	auipc	ra,0xfffff
    80001488:	0c4080e7          	jalr	196(ra) # 80000548 <panic>

000000008000148c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000148c:	1101                	addi	sp,sp,-32
    8000148e:	ec06                	sd	ra,24(sp)
    80001490:	e822                	sd	s0,16(sp)
    80001492:	e426                	sd	s1,8(sp)
    80001494:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001496:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001498:	00b67d63          	bgeu	a2,a1,800014b2 <uvmdealloc+0x26>
    8000149c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000149e:	6785                	lui	a5,0x1
    800014a0:	17fd                	addi	a5,a5,-1
    800014a2:	00f60733          	add	a4,a2,a5
    800014a6:	767d                	lui	a2,0xfffff
    800014a8:	8f71                	and	a4,a4,a2
    800014aa:	97ae                	add	a5,a5,a1
    800014ac:	8ff1                	and	a5,a5,a2
    800014ae:	00f76863          	bltu	a4,a5,800014be <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014b2:	8526                	mv	a0,s1
    800014b4:	60e2                	ld	ra,24(sp)
    800014b6:	6442                	ld	s0,16(sp)
    800014b8:	64a2                	ld	s1,8(sp)
    800014ba:	6105                	addi	sp,sp,32
    800014bc:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014be:	8f99                	sub	a5,a5,a4
    800014c0:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014c2:	4685                	li	a3,1
    800014c4:	0007861b          	sext.w	a2,a5
    800014c8:	85ba                	mv	a1,a4
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	e5e080e7          	jalr	-418(ra) # 80001328 <uvmunmap>
    800014d2:	b7c5                	j	800014b2 <uvmdealloc+0x26>

00000000800014d4 <uvmalloc>:
  if(newsz < oldsz)
    800014d4:	0ab66163          	bltu	a2,a1,80001576 <uvmalloc+0xa2>
{
    800014d8:	7139                	addi	sp,sp,-64
    800014da:	fc06                	sd	ra,56(sp)
    800014dc:	f822                	sd	s0,48(sp)
    800014de:	f426                	sd	s1,40(sp)
    800014e0:	f04a                	sd	s2,32(sp)
    800014e2:	ec4e                	sd	s3,24(sp)
    800014e4:	e852                	sd	s4,16(sp)
    800014e6:	e456                	sd	s5,8(sp)
    800014e8:	0080                	addi	s0,sp,64
    800014ea:	8aaa                	mv	s5,a0
    800014ec:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014ee:	6985                	lui	s3,0x1
    800014f0:	19fd                	addi	s3,s3,-1
    800014f2:	95ce                	add	a1,a1,s3
    800014f4:	79fd                	lui	s3,0xfffff
    800014f6:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014fa:	08c9f063          	bgeu	s3,a2,8000157a <uvmalloc+0xa6>
    800014fe:	894e                	mv	s2,s3
    mem = kalloc();
    80001500:	fffff097          	auipc	ra,0xfffff
    80001504:	620080e7          	jalr	1568(ra) # 80000b20 <kalloc>
    80001508:	84aa                	mv	s1,a0
    if(mem == 0){
    8000150a:	c51d                	beqz	a0,80001538 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000150c:	6605                	lui	a2,0x1
    8000150e:	4581                	li	a1,0
    80001510:	00000097          	auipc	ra,0x0
    80001514:	846080e7          	jalr	-1978(ra) # 80000d56 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001518:	4779                	li	a4,30
    8000151a:	86a6                	mv	a3,s1
    8000151c:	6605                	lui	a2,0x1
    8000151e:	85ca                	mv	a1,s2
    80001520:	8556                	mv	a0,s5
    80001522:	00000097          	auipc	ra,0x0
    80001526:	c6e080e7          	jalr	-914(ra) # 80001190 <mappages>
    8000152a:	e905                	bnez	a0,8000155a <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000152c:	6785                	lui	a5,0x1
    8000152e:	993e                	add	s2,s2,a5
    80001530:	fd4968e3          	bltu	s2,s4,80001500 <uvmalloc+0x2c>
  return newsz;
    80001534:	8552                	mv	a0,s4
    80001536:	a809                	j	80001548 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001538:	864e                	mv	a2,s3
    8000153a:	85ca                	mv	a1,s2
    8000153c:	8556                	mv	a0,s5
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f4e080e7          	jalr	-178(ra) # 8000148c <uvmdealloc>
      return 0;
    80001546:	4501                	li	a0,0
}
    80001548:	70e2                	ld	ra,56(sp)
    8000154a:	7442                	ld	s0,48(sp)
    8000154c:	74a2                	ld	s1,40(sp)
    8000154e:	7902                	ld	s2,32(sp)
    80001550:	69e2                	ld	s3,24(sp)
    80001552:	6a42                	ld	s4,16(sp)
    80001554:	6aa2                	ld	s5,8(sp)
    80001556:	6121                	addi	sp,sp,64
    80001558:	8082                	ret
      kfree(mem);
    8000155a:	8526                	mv	a0,s1
    8000155c:	fffff097          	auipc	ra,0xfffff
    80001560:	4c8080e7          	jalr	1224(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001564:	864e                	mv	a2,s3
    80001566:	85ca                	mv	a1,s2
    80001568:	8556                	mv	a0,s5
    8000156a:	00000097          	auipc	ra,0x0
    8000156e:	f22080e7          	jalr	-222(ra) # 8000148c <uvmdealloc>
      return 0;
    80001572:	4501                	li	a0,0
    80001574:	bfd1                	j	80001548 <uvmalloc+0x74>
    return oldsz;
    80001576:	852e                	mv	a0,a1
}
    80001578:	8082                	ret
  return newsz;
    8000157a:	8532                	mv	a0,a2
    8000157c:	b7f1                	j	80001548 <uvmalloc+0x74>

000000008000157e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000157e:	7179                	addi	sp,sp,-48
    80001580:	f406                	sd	ra,40(sp)
    80001582:	f022                	sd	s0,32(sp)
    80001584:	ec26                	sd	s1,24(sp)
    80001586:	e84a                	sd	s2,16(sp)
    80001588:	e44e                	sd	s3,8(sp)
    8000158a:	e052                	sd	s4,0(sp)
    8000158c:	1800                	addi	s0,sp,48
    8000158e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001590:	84aa                	mv	s1,a0
    80001592:	6905                	lui	s2,0x1
    80001594:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001596:	4985                	li	s3,1
    80001598:	a821                	j	800015b0 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000159a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000159c:	0532                	slli	a0,a0,0xc
    8000159e:	00000097          	auipc	ra,0x0
    800015a2:	fe0080e7          	jalr	-32(ra) # 8000157e <freewalk>
      pagetable[i] = 0;
    800015a6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015aa:	04a1                	addi	s1,s1,8
    800015ac:	03248163          	beq	s1,s2,800015ce <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015b0:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015b2:	00f57793          	andi	a5,a0,15
    800015b6:	ff3782e3          	beq	a5,s3,8000159a <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015ba:	8905                	andi	a0,a0,1
    800015bc:	d57d                	beqz	a0,800015aa <freewalk+0x2c>
      panic("freewalk: leaf");
    800015be:	00007517          	auipc	a0,0x7
    800015c2:	baa50513          	addi	a0,a0,-1110 # 80008168 <digits+0x128>
    800015c6:	fffff097          	auipc	ra,0xfffff
    800015ca:	f82080e7          	jalr	-126(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015ce:	8552                	mv	a0,s4
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	454080e7          	jalr	1108(ra) # 80000a24 <kfree>
}
    800015d8:	70a2                	ld	ra,40(sp)
    800015da:	7402                	ld	s0,32(sp)
    800015dc:	64e2                	ld	s1,24(sp)
    800015de:	6942                	ld	s2,16(sp)
    800015e0:	69a2                	ld	s3,8(sp)
    800015e2:	6a02                	ld	s4,0(sp)
    800015e4:	6145                	addi	sp,sp,48
    800015e6:	8082                	ret

00000000800015e8 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015e8:	1101                	addi	sp,sp,-32
    800015ea:	ec06                	sd	ra,24(sp)
    800015ec:	e822                	sd	s0,16(sp)
    800015ee:	e426                	sd	s1,8(sp)
    800015f0:	1000                	addi	s0,sp,32
    800015f2:	84aa                	mv	s1,a0
  if(sz > 0)
    800015f4:	e999                	bnez	a1,8000160a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015f6:	8526                	mv	a0,s1
    800015f8:	00000097          	auipc	ra,0x0
    800015fc:	f86080e7          	jalr	-122(ra) # 8000157e <freewalk>
}
    80001600:	60e2                	ld	ra,24(sp)
    80001602:	6442                	ld	s0,16(sp)
    80001604:	64a2                	ld	s1,8(sp)
    80001606:	6105                	addi	sp,sp,32
    80001608:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000160a:	6605                	lui	a2,0x1
    8000160c:	167d                	addi	a2,a2,-1
    8000160e:	962e                	add	a2,a2,a1
    80001610:	4685                	li	a3,1
    80001612:	8231                	srli	a2,a2,0xc
    80001614:	4581                	li	a1,0
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	d12080e7          	jalr	-750(ra) # 80001328 <uvmunmap>
    8000161e:	bfe1                	j	800015f6 <uvmfree+0xe>

0000000080001620 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001620:	c679                	beqz	a2,800016ee <uvmcopy+0xce>
{
    80001622:	715d                	addi	sp,sp,-80
    80001624:	e486                	sd	ra,72(sp)
    80001626:	e0a2                	sd	s0,64(sp)
    80001628:	fc26                	sd	s1,56(sp)
    8000162a:	f84a                	sd	s2,48(sp)
    8000162c:	f44e                	sd	s3,40(sp)
    8000162e:	f052                	sd	s4,32(sp)
    80001630:	ec56                	sd	s5,24(sp)
    80001632:	e85a                	sd	s6,16(sp)
    80001634:	e45e                	sd	s7,8(sp)
    80001636:	0880                	addi	s0,sp,80
    80001638:	8b2a                	mv	s6,a0
    8000163a:	8aae                	mv	s5,a1
    8000163c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000163e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001640:	4601                	li	a2,0
    80001642:	85ce                	mv	a1,s3
    80001644:	855a                	mv	a0,s6
    80001646:	00000097          	auipc	ra,0x0
    8000164a:	a04080e7          	jalr	-1532(ra) # 8000104a <walk>
    8000164e:	c531                	beqz	a0,8000169a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001650:	6118                	ld	a4,0(a0)
    80001652:	00177793          	andi	a5,a4,1
    80001656:	cbb1                	beqz	a5,800016aa <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001658:	00a75593          	srli	a1,a4,0xa
    8000165c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001660:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	4bc080e7          	jalr	1212(ra) # 80000b20 <kalloc>
    8000166c:	892a                	mv	s2,a0
    8000166e:	c939                	beqz	a0,800016c4 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001670:	6605                	lui	a2,0x1
    80001672:	85de                	mv	a1,s7
    80001674:	fffff097          	auipc	ra,0xfffff
    80001678:	742080e7          	jalr	1858(ra) # 80000db6 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000167c:	8726                	mv	a4,s1
    8000167e:	86ca                	mv	a3,s2
    80001680:	6605                	lui	a2,0x1
    80001682:	85ce                	mv	a1,s3
    80001684:	8556                	mv	a0,s5
    80001686:	00000097          	auipc	ra,0x0
    8000168a:	b0a080e7          	jalr	-1270(ra) # 80001190 <mappages>
    8000168e:	e515                	bnez	a0,800016ba <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001690:	6785                	lui	a5,0x1
    80001692:	99be                	add	s3,s3,a5
    80001694:	fb49e6e3          	bltu	s3,s4,80001640 <uvmcopy+0x20>
    80001698:	a081                	j	800016d8 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000169a:	00007517          	auipc	a0,0x7
    8000169e:	ade50513          	addi	a0,a0,-1314 # 80008178 <digits+0x138>
    800016a2:	fffff097          	auipc	ra,0xfffff
    800016a6:	ea6080e7          	jalr	-346(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800016aa:	00007517          	auipc	a0,0x7
    800016ae:	aee50513          	addi	a0,a0,-1298 # 80008198 <digits+0x158>
    800016b2:	fffff097          	auipc	ra,0xfffff
    800016b6:	e96080e7          	jalr	-362(ra) # 80000548 <panic>
      kfree(mem);
    800016ba:	854a                	mv	a0,s2
    800016bc:	fffff097          	auipc	ra,0xfffff
    800016c0:	368080e7          	jalr	872(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016c4:	4685                	li	a3,1
    800016c6:	00c9d613          	srli	a2,s3,0xc
    800016ca:	4581                	li	a1,0
    800016cc:	8556                	mv	a0,s5
    800016ce:	00000097          	auipc	ra,0x0
    800016d2:	c5a080e7          	jalr	-934(ra) # 80001328 <uvmunmap>
  return -1;
    800016d6:	557d                	li	a0,-1
}
    800016d8:	60a6                	ld	ra,72(sp)
    800016da:	6406                	ld	s0,64(sp)
    800016dc:	74e2                	ld	s1,56(sp)
    800016de:	7942                	ld	s2,48(sp)
    800016e0:	79a2                	ld	s3,40(sp)
    800016e2:	7a02                	ld	s4,32(sp)
    800016e4:	6ae2                	ld	s5,24(sp)
    800016e6:	6b42                	ld	s6,16(sp)
    800016e8:	6ba2                	ld	s7,8(sp)
    800016ea:	6161                	addi	sp,sp,80
    800016ec:	8082                	ret
  return 0;
    800016ee:	4501                	li	a0,0
}
    800016f0:	8082                	ret

00000000800016f2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016f2:	1141                	addi	sp,sp,-16
    800016f4:	e406                	sd	ra,8(sp)
    800016f6:	e022                	sd	s0,0(sp)
    800016f8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016fa:	4601                	li	a2,0
    800016fc:	00000097          	auipc	ra,0x0
    80001700:	94e080e7          	jalr	-1714(ra) # 8000104a <walk>
  if(pte == 0)
    80001704:	c901                	beqz	a0,80001714 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001706:	611c                	ld	a5,0(a0)
    80001708:	9bbd                	andi	a5,a5,-17
    8000170a:	e11c                	sd	a5,0(a0)
}
    8000170c:	60a2                	ld	ra,8(sp)
    8000170e:	6402                	ld	s0,0(sp)
    80001710:	0141                	addi	sp,sp,16
    80001712:	8082                	ret
    panic("uvmclear");
    80001714:	00007517          	auipc	a0,0x7
    80001718:	aa450513          	addi	a0,a0,-1372 # 800081b8 <digits+0x178>
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	e2c080e7          	jalr	-468(ra) # 80000548 <panic>

0000000080001724 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001724:	c6bd                	beqz	a3,80001792 <copyout+0x6e>
{
    80001726:	715d                	addi	sp,sp,-80
    80001728:	e486                	sd	ra,72(sp)
    8000172a:	e0a2                	sd	s0,64(sp)
    8000172c:	fc26                	sd	s1,56(sp)
    8000172e:	f84a                	sd	s2,48(sp)
    80001730:	f44e                	sd	s3,40(sp)
    80001732:	f052                	sd	s4,32(sp)
    80001734:	ec56                	sd	s5,24(sp)
    80001736:	e85a                	sd	s6,16(sp)
    80001738:	e45e                	sd	s7,8(sp)
    8000173a:	e062                	sd	s8,0(sp)
    8000173c:	0880                	addi	s0,sp,80
    8000173e:	8b2a                	mv	s6,a0
    80001740:	8c2e                	mv	s8,a1
    80001742:	8a32                	mv	s4,a2
    80001744:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001746:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001748:	6a85                	lui	s5,0x1
    8000174a:	a015                	j	8000176e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000174c:	9562                	add	a0,a0,s8
    8000174e:	0004861b          	sext.w	a2,s1
    80001752:	85d2                	mv	a1,s4
    80001754:	41250533          	sub	a0,a0,s2
    80001758:	fffff097          	auipc	ra,0xfffff
    8000175c:	65e080e7          	jalr	1630(ra) # 80000db6 <memmove>

    len -= n;
    80001760:	409989b3          	sub	s3,s3,s1
    src += n;
    80001764:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001766:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000176a:	02098263          	beqz	s3,8000178e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000176e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001772:	85ca                	mv	a1,s2
    80001774:	855a                	mv	a0,s6
    80001776:	00000097          	auipc	ra,0x0
    8000177a:	97a080e7          	jalr	-1670(ra) # 800010f0 <walkaddr>
    if(pa0 == 0)
    8000177e:	cd01                	beqz	a0,80001796 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001780:	418904b3          	sub	s1,s2,s8
    80001784:	94d6                	add	s1,s1,s5
    if(n > len)
    80001786:	fc99f3e3          	bgeu	s3,s1,8000174c <copyout+0x28>
    8000178a:	84ce                	mv	s1,s3
    8000178c:	b7c1                	j	8000174c <copyout+0x28>
  }
  return 0;
    8000178e:	4501                	li	a0,0
    80001790:	a021                	j	80001798 <copyout+0x74>
    80001792:	4501                	li	a0,0
}
    80001794:	8082                	ret
      return -1;
    80001796:	557d                	li	a0,-1
}
    80001798:	60a6                	ld	ra,72(sp)
    8000179a:	6406                	ld	s0,64(sp)
    8000179c:	74e2                	ld	s1,56(sp)
    8000179e:	7942                	ld	s2,48(sp)
    800017a0:	79a2                	ld	s3,40(sp)
    800017a2:	7a02                	ld	s4,32(sp)
    800017a4:	6ae2                	ld	s5,24(sp)
    800017a6:	6b42                	ld	s6,16(sp)
    800017a8:	6ba2                	ld	s7,8(sp)
    800017aa:	6c02                	ld	s8,0(sp)
    800017ac:	6161                	addi	sp,sp,80
    800017ae:	8082                	ret

00000000800017b0 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017b0:	c6bd                	beqz	a3,8000181e <copyin+0x6e>
{
    800017b2:	715d                	addi	sp,sp,-80
    800017b4:	e486                	sd	ra,72(sp)
    800017b6:	e0a2                	sd	s0,64(sp)
    800017b8:	fc26                	sd	s1,56(sp)
    800017ba:	f84a                	sd	s2,48(sp)
    800017bc:	f44e                	sd	s3,40(sp)
    800017be:	f052                	sd	s4,32(sp)
    800017c0:	ec56                	sd	s5,24(sp)
    800017c2:	e85a                	sd	s6,16(sp)
    800017c4:	e45e                	sd	s7,8(sp)
    800017c6:	e062                	sd	s8,0(sp)
    800017c8:	0880                	addi	s0,sp,80
    800017ca:	8b2a                	mv	s6,a0
    800017cc:	8a2e                	mv	s4,a1
    800017ce:	8c32                	mv	s8,a2
    800017d0:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017d2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017d4:	6a85                	lui	s5,0x1
    800017d6:	a015                	j	800017fa <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017d8:	9562                	add	a0,a0,s8
    800017da:	0004861b          	sext.w	a2,s1
    800017de:	412505b3          	sub	a1,a0,s2
    800017e2:	8552                	mv	a0,s4
    800017e4:	fffff097          	auipc	ra,0xfffff
    800017e8:	5d2080e7          	jalr	1490(ra) # 80000db6 <memmove>

    len -= n;
    800017ec:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017f0:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017f2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017f6:	02098263          	beqz	s3,8000181a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017fa:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017fe:	85ca                	mv	a1,s2
    80001800:	855a                	mv	a0,s6
    80001802:	00000097          	auipc	ra,0x0
    80001806:	8ee080e7          	jalr	-1810(ra) # 800010f0 <walkaddr>
    if(pa0 == 0)
    8000180a:	cd01                	beqz	a0,80001822 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000180c:	418904b3          	sub	s1,s2,s8
    80001810:	94d6                	add	s1,s1,s5
    if(n > len)
    80001812:	fc99f3e3          	bgeu	s3,s1,800017d8 <copyin+0x28>
    80001816:	84ce                	mv	s1,s3
    80001818:	b7c1                	j	800017d8 <copyin+0x28>
  }
  return 0;
    8000181a:	4501                	li	a0,0
    8000181c:	a021                	j	80001824 <copyin+0x74>
    8000181e:	4501                	li	a0,0
}
    80001820:	8082                	ret
      return -1;
    80001822:	557d                	li	a0,-1
}
    80001824:	60a6                	ld	ra,72(sp)
    80001826:	6406                	ld	s0,64(sp)
    80001828:	74e2                	ld	s1,56(sp)
    8000182a:	7942                	ld	s2,48(sp)
    8000182c:	79a2                	ld	s3,40(sp)
    8000182e:	7a02                	ld	s4,32(sp)
    80001830:	6ae2                	ld	s5,24(sp)
    80001832:	6b42                	ld	s6,16(sp)
    80001834:	6ba2                	ld	s7,8(sp)
    80001836:	6c02                	ld	s8,0(sp)
    80001838:	6161                	addi	sp,sp,80
    8000183a:	8082                	ret

000000008000183c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000183c:	c6c5                	beqz	a3,800018e4 <copyinstr+0xa8>
{
    8000183e:	715d                	addi	sp,sp,-80
    80001840:	e486                	sd	ra,72(sp)
    80001842:	e0a2                	sd	s0,64(sp)
    80001844:	fc26                	sd	s1,56(sp)
    80001846:	f84a                	sd	s2,48(sp)
    80001848:	f44e                	sd	s3,40(sp)
    8000184a:	f052                	sd	s4,32(sp)
    8000184c:	ec56                	sd	s5,24(sp)
    8000184e:	e85a                	sd	s6,16(sp)
    80001850:	e45e                	sd	s7,8(sp)
    80001852:	0880                	addi	s0,sp,80
    80001854:	8a2a                	mv	s4,a0
    80001856:	8b2e                	mv	s6,a1
    80001858:	8bb2                	mv	s7,a2
    8000185a:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000185c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000185e:	6985                	lui	s3,0x1
    80001860:	a035                	j	8000188c <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001862:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001866:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001868:	0017b793          	seqz	a5,a5
    8000186c:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001870:	60a6                	ld	ra,72(sp)
    80001872:	6406                	ld	s0,64(sp)
    80001874:	74e2                	ld	s1,56(sp)
    80001876:	7942                	ld	s2,48(sp)
    80001878:	79a2                	ld	s3,40(sp)
    8000187a:	7a02                	ld	s4,32(sp)
    8000187c:	6ae2                	ld	s5,24(sp)
    8000187e:	6b42                	ld	s6,16(sp)
    80001880:	6ba2                	ld	s7,8(sp)
    80001882:	6161                	addi	sp,sp,80
    80001884:	8082                	ret
    srcva = va0 + PGSIZE;
    80001886:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000188a:	c8a9                	beqz	s1,800018dc <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000188c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001890:	85ca                	mv	a1,s2
    80001892:	8552                	mv	a0,s4
    80001894:	00000097          	auipc	ra,0x0
    80001898:	85c080e7          	jalr	-1956(ra) # 800010f0 <walkaddr>
    if(pa0 == 0)
    8000189c:	c131                	beqz	a0,800018e0 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000189e:	41790833          	sub	a6,s2,s7
    800018a2:	984e                	add	a6,a6,s3
    if(n > max)
    800018a4:	0104f363          	bgeu	s1,a6,800018aa <copyinstr+0x6e>
    800018a8:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018aa:	955e                	add	a0,a0,s7
    800018ac:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018b0:	fc080be3          	beqz	a6,80001886 <copyinstr+0x4a>
    800018b4:	985a                	add	a6,a6,s6
    800018b6:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018b8:	41650633          	sub	a2,a0,s6
    800018bc:	14fd                	addi	s1,s1,-1
    800018be:	9b26                	add	s6,s6,s1
    800018c0:	00f60733          	add	a4,a2,a5
    800018c4:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    800018c8:	df49                	beqz	a4,80001862 <copyinstr+0x26>
        *dst = *p;
    800018ca:	00e78023          	sb	a4,0(a5)
      --max;
    800018ce:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018d2:	0785                	addi	a5,a5,1
    while(n > 0){
    800018d4:	ff0796e3          	bne	a5,a6,800018c0 <copyinstr+0x84>
      dst++;
    800018d8:	8b42                	mv	s6,a6
    800018da:	b775                	j	80001886 <copyinstr+0x4a>
    800018dc:	4781                	li	a5,0
    800018de:	b769                	j	80001868 <copyinstr+0x2c>
      return -1;
    800018e0:	557d                	li	a0,-1
    800018e2:	b779                	j	80001870 <copyinstr+0x34>
  int got_null = 0;
    800018e4:	4781                	li	a5,0
  if(got_null){
    800018e6:	0017b793          	seqz	a5,a5
    800018ea:	40f00533          	neg	a0,a5
}
    800018ee:	8082                	ret

00000000800018f0 <vmprint_helper>:

// Recursive helper
void vmprint_helper(pagetable_t pagetable, int depth) {
    800018f0:	715d                	addi	sp,sp,-80
    800018f2:	e486                	sd	ra,72(sp)
    800018f4:	e0a2                	sd	s0,64(sp)
    800018f6:	fc26                	sd	s1,56(sp)
    800018f8:	f84a                	sd	s2,48(sp)
    800018fa:	f44e                	sd	s3,40(sp)
    800018fc:	f052                	sd	s4,32(sp)
    800018fe:	ec56                	sd	s5,24(sp)
    80001900:	e85a                	sd	s6,16(sp)
    80001902:	e45e                	sd	s7,8(sp)
    80001904:	e062                	sd	s8,0(sp)
    80001906:	0880                	addi	s0,sp,80
      "",
      "..",
      ".. ..",
      ".. .. .."
  };
  if (depth <= 0 || depth >= 4) {
    80001908:	fff5871b          	addiw	a4,a1,-1
    8000190c:	4789                	li	a5,2
    8000190e:	02e7e463          	bltu	a5,a4,80001936 <vmprint_helper+0x46>
    80001912:	89aa                	mv	s3,a0
    80001914:	4901                	li	s2,0
  }
  // there are 2^9 = 512 PTES in a page table.
  for (int i = 0; i < 512; i++) {
    pte_t pte = pagetable[i];
    if (pte & PTE_V) {
      printf("%s%d: pte %p pa %p\n", indent[depth], i, pte, PTE2PA(pte));
    80001916:	00359793          	slli	a5,a1,0x3
    8000191a:	00007b17          	auipc	s6,0x7
    8000191e:	91eb0b13          	addi	s6,s6,-1762 # 80008238 <indent.1674>
    80001922:	9b3e                	add	s6,s6,a5
    80001924:	00007b97          	auipc	s7,0x7
    80001928:	8ccb8b93          	addi	s7,s7,-1844 # 800081f0 <digits+0x1b0>
      if ((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
        // points to a lower-level page table
        uint64 child = PTE2PA(pte);
        vmprint_helper((pagetable_t)child, depth+1);
    8000192c:	00158c1b          	addiw	s8,a1,1
  for (int i = 0; i < 512; i++) {
    80001930:	20000a93          	li	s5,512
    80001934:	a01d                	j	8000195a <vmprint_helper+0x6a>
    panic("vmprint_helper: depth not in {1, 2, 3}");
    80001936:	00007517          	auipc	a0,0x7
    8000193a:	89250513          	addi	a0,a0,-1902 # 800081c8 <digits+0x188>
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	c0a080e7          	jalr	-1014(ra) # 80000548 <panic>
        vmprint_helper((pagetable_t)child, depth+1);
    80001946:	85e2                	mv	a1,s8
    80001948:	8552                	mv	a0,s4
    8000194a:	00000097          	auipc	ra,0x0
    8000194e:	fa6080e7          	jalr	-90(ra) # 800018f0 <vmprint_helper>
  for (int i = 0; i < 512; i++) {
    80001952:	2905                	addiw	s2,s2,1
    80001954:	09a1                	addi	s3,s3,8
    80001956:	03590763          	beq	s2,s5,80001984 <vmprint_helper+0x94>
    pte_t pte = pagetable[i];
    8000195a:	0009b483          	ld	s1,0(s3) # 1000 <_entry-0x7ffff000>
    if (pte & PTE_V) {
    8000195e:	0014f793          	andi	a5,s1,1
    80001962:	dbe5                	beqz	a5,80001952 <vmprint_helper+0x62>
      printf("%s%d: pte %p pa %p\n", indent[depth], i, pte, PTE2PA(pte));
    80001964:	00a4da13          	srli	s4,s1,0xa
    80001968:	0a32                	slli	s4,s4,0xc
    8000196a:	8752                	mv	a4,s4
    8000196c:	86a6                	mv	a3,s1
    8000196e:	864a                	mv	a2,s2
    80001970:	000b3583          	ld	a1,0(s6)
    80001974:	855e                	mv	a0,s7
    80001976:	fffff097          	auipc	ra,0xfffff
    8000197a:	c1c080e7          	jalr	-996(ra) # 80000592 <printf>
      if ((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
    8000197e:	88b9                	andi	s1,s1,14
    80001980:	f8e9                	bnez	s1,80001952 <vmprint_helper+0x62>
    80001982:	b7d1                	j	80001946 <vmprint_helper+0x56>
      }
    }
  }
}
    80001984:	60a6                	ld	ra,72(sp)
    80001986:	6406                	ld	s0,64(sp)
    80001988:	74e2                	ld	s1,56(sp)
    8000198a:	7942                	ld	s2,48(sp)
    8000198c:	79a2                	ld	s3,40(sp)
    8000198e:	7a02                	ld	s4,32(sp)
    80001990:	6ae2                	ld	s5,24(sp)
    80001992:	6b42                	ld	s6,16(sp)
    80001994:	6ba2                	ld	s7,8(sp)
    80001996:	6c02                	ld	s8,0(sp)
    80001998:	6161                	addi	sp,sp,80
    8000199a:	8082                	ret

000000008000199c <vmprint>:

// Utility func to print the valid
// PTEs within a page table recursively
void vmprint(pagetable_t pagetable) {
    8000199c:	1101                	addi	sp,sp,-32
    8000199e:	ec06                	sd	ra,24(sp)
    800019a0:	e822                	sd	s0,16(sp)
    800019a2:	e426                	sd	s1,8(sp)
    800019a4:	1000                	addi	s0,sp,32
    800019a6:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    800019a8:	85aa                	mv	a1,a0
    800019aa:	00007517          	auipc	a0,0x7
    800019ae:	85e50513          	addi	a0,a0,-1954 # 80008208 <digits+0x1c8>
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	be0080e7          	jalr	-1056(ra) # 80000592 <printf>
  vmprint_helper(pagetable, 1);
    800019ba:	4585                	li	a1,1
    800019bc:	8526                	mv	a0,s1
    800019be:	00000097          	auipc	ra,0x0
    800019c2:	f32080e7          	jalr	-206(ra) # 800018f0 <vmprint_helper>
}
    800019c6:	60e2                	ld	ra,24(sp)
    800019c8:	6442                	ld	s0,16(sp)
    800019ca:	64a2                	ld	s1,8(sp)
    800019cc:	6105                	addi	sp,sp,32
    800019ce:	8082                	ret

00000000800019d0 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800019d0:	1101                	addi	sp,sp,-32
    800019d2:	ec06                	sd	ra,24(sp)
    800019d4:	e822                	sd	s0,16(sp)
    800019d6:	e426                	sd	s1,8(sp)
    800019d8:	1000                	addi	s0,sp,32
    800019da:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	204080e7          	jalr	516(ra) # 80000be0 <holding>
    800019e4:	c909                	beqz	a0,800019f6 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800019e6:	749c                	ld	a5,40(s1)
    800019e8:	00978f63          	beq	a5,s1,80001a06 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800019ec:	60e2                	ld	ra,24(sp)
    800019ee:	6442                	ld	s0,16(sp)
    800019f0:	64a2                	ld	s1,8(sp)
    800019f2:	6105                	addi	sp,sp,32
    800019f4:	8082                	ret
    panic("wakeup1");
    800019f6:	00007517          	auipc	a0,0x7
    800019fa:	86250513          	addi	a0,a0,-1950 # 80008258 <indent.1674+0x20>
    800019fe:	fffff097          	auipc	ra,0xfffff
    80001a02:	b4a080e7          	jalr	-1206(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001a06:	4c98                	lw	a4,24(s1)
    80001a08:	4785                	li	a5,1
    80001a0a:	fef711e3          	bne	a4,a5,800019ec <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001a0e:	4789                	li	a5,2
    80001a10:	cc9c                	sw	a5,24(s1)
}
    80001a12:	bfe9                	j	800019ec <wakeup1+0x1c>

0000000080001a14 <procinit>:
{
    80001a14:	715d                	addi	sp,sp,-80
    80001a16:	e486                	sd	ra,72(sp)
    80001a18:	e0a2                	sd	s0,64(sp)
    80001a1a:	fc26                	sd	s1,56(sp)
    80001a1c:	f84a                	sd	s2,48(sp)
    80001a1e:	f44e                	sd	s3,40(sp)
    80001a20:	f052                	sd	s4,32(sp)
    80001a22:	ec56                	sd	s5,24(sp)
    80001a24:	e85a                	sd	s6,16(sp)
    80001a26:	e45e                	sd	s7,8(sp)
    80001a28:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001a2a:	00007597          	auipc	a1,0x7
    80001a2e:	83658593          	addi	a1,a1,-1994 # 80008260 <indent.1674+0x28>
    80001a32:	00010517          	auipc	a0,0x10
    80001a36:	f1e50513          	addi	a0,a0,-226 # 80011950 <pid_lock>
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	190080e7          	jalr	400(ra) # 80000bca <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a42:	00010917          	auipc	s2,0x10
    80001a46:	32690913          	addi	s2,s2,806 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001a4a:	00007b97          	auipc	s7,0x7
    80001a4e:	81eb8b93          	addi	s7,s7,-2018 # 80008268 <indent.1674+0x30>
      uint64 va = KSTACK((int) (p - proc));
    80001a52:	8b4a                	mv	s6,s2
    80001a54:	00006a97          	auipc	s5,0x6
    80001a58:	5aca8a93          	addi	s5,s5,1452 # 80008000 <etext>
    80001a5c:	040009b7          	lui	s3,0x4000
    80001a60:	19fd                	addi	s3,s3,-1
    80001a62:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a64:	00016a17          	auipc	s4,0x16
    80001a68:	f04a0a13          	addi	s4,s4,-252 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    80001a6c:	85de                	mv	a1,s7
    80001a6e:	854a                	mv	a0,s2
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	15a080e7          	jalr	346(ra) # 80000bca <initlock>
      char *pa = kalloc();
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	0a8080e7          	jalr	168(ra) # 80000b20 <kalloc>
    80001a80:	85aa                	mv	a1,a0
      if(pa == 0)
    80001a82:	c929                	beqz	a0,80001ad4 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001a84:	416904b3          	sub	s1,s2,s6
    80001a88:	8491                	srai	s1,s1,0x4
    80001a8a:	000ab783          	ld	a5,0(s5)
    80001a8e:	02f484b3          	mul	s1,s1,a5
    80001a92:	2485                	addiw	s1,s1,1
    80001a94:	00d4949b          	slliw	s1,s1,0xd
    80001a98:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a9c:	4699                	li	a3,6
    80001a9e:	6605                	lui	a2,0x1
    80001aa0:	8526                	mv	a0,s1
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	77c080e7          	jalr	1916(ra) # 8000121e <kvmmap>
      p->kstack = va;
    80001aaa:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aae:	17090913          	addi	s2,s2,368
    80001ab2:	fb491de3          	bne	s2,s4,80001a6c <procinit+0x58>
  kvminithart();
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	570080e7          	jalr	1392(ra) # 80001026 <kvminithart>
}
    80001abe:	60a6                	ld	ra,72(sp)
    80001ac0:	6406                	ld	s0,64(sp)
    80001ac2:	74e2                	ld	s1,56(sp)
    80001ac4:	7942                	ld	s2,48(sp)
    80001ac6:	79a2                	ld	s3,40(sp)
    80001ac8:	7a02                	ld	s4,32(sp)
    80001aca:	6ae2                	ld	s5,24(sp)
    80001acc:	6b42                	ld	s6,16(sp)
    80001ace:	6ba2                	ld	s7,8(sp)
    80001ad0:	6161                	addi	sp,sp,80
    80001ad2:	8082                	ret
        panic("kalloc");
    80001ad4:	00006517          	auipc	a0,0x6
    80001ad8:	79c50513          	addi	a0,a0,1948 # 80008270 <indent.1674+0x38>
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	a6c080e7          	jalr	-1428(ra) # 80000548 <panic>

0000000080001ae4 <cpuid>:
{
    80001ae4:	1141                	addi	sp,sp,-16
    80001ae6:	e422                	sd	s0,8(sp)
    80001ae8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001aea:	8512                	mv	a0,tp
}
    80001aec:	2501                	sext.w	a0,a0
    80001aee:	6422                	ld	s0,8(sp)
    80001af0:	0141                	addi	sp,sp,16
    80001af2:	8082                	ret

0000000080001af4 <mycpu>:
mycpu(void) {
    80001af4:	1141                	addi	sp,sp,-16
    80001af6:	e422                	sd	s0,8(sp)
    80001af8:	0800                	addi	s0,sp,16
    80001afa:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001afc:	2781                	sext.w	a5,a5
    80001afe:	079e                	slli	a5,a5,0x7
}
    80001b00:	00010517          	auipc	a0,0x10
    80001b04:	e6850513          	addi	a0,a0,-408 # 80011968 <cpus>
    80001b08:	953e                	add	a0,a0,a5
    80001b0a:	6422                	ld	s0,8(sp)
    80001b0c:	0141                	addi	sp,sp,16
    80001b0e:	8082                	ret

0000000080001b10 <myproc>:
myproc(void) {
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	1000                	addi	s0,sp,32
  push_off();
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	0f4080e7          	jalr	244(ra) # 80000c0e <push_off>
    80001b22:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b24:	2781                	sext.w	a5,a5
    80001b26:	079e                	slli	a5,a5,0x7
    80001b28:	00010717          	auipc	a4,0x10
    80001b2c:	e2870713          	addi	a4,a4,-472 # 80011950 <pid_lock>
    80001b30:	97ba                	add	a5,a5,a4
    80001b32:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	17a080e7          	jalr	378(ra) # 80000cae <pop_off>
}
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	60e2                	ld	ra,24(sp)
    80001b40:	6442                	ld	s0,16(sp)
    80001b42:	64a2                	ld	s1,8(sp)
    80001b44:	6105                	addi	sp,sp,32
    80001b46:	8082                	ret

0000000080001b48 <forkret>:
{
    80001b48:	1141                	addi	sp,sp,-16
    80001b4a:	e406                	sd	ra,8(sp)
    80001b4c:	e022                	sd	s0,0(sp)
    80001b4e:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b50:	00000097          	auipc	ra,0x0
    80001b54:	fc0080e7          	jalr	-64(ra) # 80001b10 <myproc>
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	1b6080e7          	jalr	438(ra) # 80000d0e <release>
  if (first) {
    80001b60:	00007797          	auipc	a5,0x7
    80001b64:	f107a783          	lw	a5,-240(a5) # 80008a70 <first.1677>
    80001b68:	eb89                	bnez	a5,80001b7a <forkret+0x32>
  usertrapret();
    80001b6a:	00001097          	auipc	ra,0x1
    80001b6e:	c78080e7          	jalr	-904(ra) # 800027e2 <usertrapret>
}
    80001b72:	60a2                	ld	ra,8(sp)
    80001b74:	6402                	ld	s0,0(sp)
    80001b76:	0141                	addi	sp,sp,16
    80001b78:	8082                	ret
    first = 0;
    80001b7a:	00007797          	auipc	a5,0x7
    80001b7e:	ee07ab23          	sw	zero,-266(a5) # 80008a70 <first.1677>
    fsinit(ROOTDEV);
    80001b82:	4505                	li	a0,1
    80001b84:	00002097          	auipc	ra,0x2
    80001b88:	a7c080e7          	jalr	-1412(ra) # 80003600 <fsinit>
    80001b8c:	bff9                	j	80001b6a <forkret+0x22>

0000000080001b8e <allocpid>:
allocpid() {
    80001b8e:	1101                	addi	sp,sp,-32
    80001b90:	ec06                	sd	ra,24(sp)
    80001b92:	e822                	sd	s0,16(sp)
    80001b94:	e426                	sd	s1,8(sp)
    80001b96:	e04a                	sd	s2,0(sp)
    80001b98:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b9a:	00010917          	auipc	s2,0x10
    80001b9e:	db690913          	addi	s2,s2,-586 # 80011950 <pid_lock>
    80001ba2:	854a                	mv	a0,s2
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	0b6080e7          	jalr	182(ra) # 80000c5a <acquire>
  pid = nextpid;
    80001bac:	00007797          	auipc	a5,0x7
    80001bb0:	ec878793          	addi	a5,a5,-312 # 80008a74 <nextpid>
    80001bb4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bb6:	0014871b          	addiw	a4,s1,1
    80001bba:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bbc:	854a                	mv	a0,s2
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	150080e7          	jalr	336(ra) # 80000d0e <release>
}
    80001bc6:	8526                	mv	a0,s1
    80001bc8:	60e2                	ld	ra,24(sp)
    80001bca:	6442                	ld	s0,16(sp)
    80001bcc:	64a2                	ld	s1,8(sp)
    80001bce:	6902                	ld	s2,0(sp)
    80001bd0:	6105                	addi	sp,sp,32
    80001bd2:	8082                	ret

0000000080001bd4 <proc_pagetable>:
{
    80001bd4:	1101                	addi	sp,sp,-32
    80001bd6:	ec06                	sd	ra,24(sp)
    80001bd8:	e822                	sd	s0,16(sp)
    80001bda:	e426                	sd	s1,8(sp)
    80001bdc:	e04a                	sd	s2,0(sp)
    80001bde:	1000                	addi	s0,sp,32
    80001be0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001be2:	00000097          	auipc	ra,0x0
    80001be6:	80a080e7          	jalr	-2038(ra) # 800013ec <uvmcreate>
    80001bea:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bec:	c121                	beqz	a0,80001c2c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bee:	4729                	li	a4,10
    80001bf0:	00005697          	auipc	a3,0x5
    80001bf4:	41068693          	addi	a3,a3,1040 # 80007000 <_trampoline>
    80001bf8:	6605                	lui	a2,0x1
    80001bfa:	040005b7          	lui	a1,0x4000
    80001bfe:	15fd                	addi	a1,a1,-1
    80001c00:	05b2                	slli	a1,a1,0xc
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	58e080e7          	jalr	1422(ra) # 80001190 <mappages>
    80001c0a:	02054863          	bltz	a0,80001c3a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c0e:	4719                	li	a4,6
    80001c10:	05893683          	ld	a3,88(s2)
    80001c14:	6605                	lui	a2,0x1
    80001c16:	020005b7          	lui	a1,0x2000
    80001c1a:	15fd                	addi	a1,a1,-1
    80001c1c:	05b6                	slli	a1,a1,0xd
    80001c1e:	8526                	mv	a0,s1
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	570080e7          	jalr	1392(ra) # 80001190 <mappages>
    80001c28:	02054163          	bltz	a0,80001c4a <proc_pagetable+0x76>
}
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	60e2                	ld	ra,24(sp)
    80001c30:	6442                	ld	s0,16(sp)
    80001c32:	64a2                	ld	s1,8(sp)
    80001c34:	6902                	ld	s2,0(sp)
    80001c36:	6105                	addi	sp,sp,32
    80001c38:	8082                	ret
    uvmfree(pagetable, 0);
    80001c3a:	4581                	li	a1,0
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	9aa080e7          	jalr	-1622(ra) # 800015e8 <uvmfree>
    return 0;
    80001c46:	4481                	li	s1,0
    80001c48:	b7d5                	j	80001c2c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c4a:	4681                	li	a3,0
    80001c4c:	4605                	li	a2,1
    80001c4e:	040005b7          	lui	a1,0x4000
    80001c52:	15fd                	addi	a1,a1,-1
    80001c54:	05b2                	slli	a1,a1,0xc
    80001c56:	8526                	mv	a0,s1
    80001c58:	fffff097          	auipc	ra,0xfffff
    80001c5c:	6d0080e7          	jalr	1744(ra) # 80001328 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c60:	4581                	li	a1,0
    80001c62:	8526                	mv	a0,s1
    80001c64:	00000097          	auipc	ra,0x0
    80001c68:	984080e7          	jalr	-1660(ra) # 800015e8 <uvmfree>
    return 0;
    80001c6c:	4481                	li	s1,0
    80001c6e:	bf7d                	j	80001c2c <proc_pagetable+0x58>

0000000080001c70 <proc_freepagetable>:
{
    80001c70:	1101                	addi	sp,sp,-32
    80001c72:	ec06                	sd	ra,24(sp)
    80001c74:	e822                	sd	s0,16(sp)
    80001c76:	e426                	sd	s1,8(sp)
    80001c78:	e04a                	sd	s2,0(sp)
    80001c7a:	1000                	addi	s0,sp,32
    80001c7c:	84aa                	mv	s1,a0
    80001c7e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c80:	4681                	li	a3,0
    80001c82:	4605                	li	a2,1
    80001c84:	040005b7          	lui	a1,0x4000
    80001c88:	15fd                	addi	a1,a1,-1
    80001c8a:	05b2                	slli	a1,a1,0xc
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	69c080e7          	jalr	1692(ra) # 80001328 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c94:	4681                	li	a3,0
    80001c96:	4605                	li	a2,1
    80001c98:	020005b7          	lui	a1,0x2000
    80001c9c:	15fd                	addi	a1,a1,-1
    80001c9e:	05b6                	slli	a1,a1,0xd
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	686080e7          	jalr	1670(ra) # 80001328 <uvmunmap>
  uvmfree(pagetable, sz);
    80001caa:	85ca                	mv	a1,s2
    80001cac:	8526                	mv	a0,s1
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	93a080e7          	jalr	-1734(ra) # 800015e8 <uvmfree>
}
    80001cb6:	60e2                	ld	ra,24(sp)
    80001cb8:	6442                	ld	s0,16(sp)
    80001cba:	64a2                	ld	s1,8(sp)
    80001cbc:	6902                	ld	s2,0(sp)
    80001cbe:	6105                	addi	sp,sp,32
    80001cc0:	8082                	ret

0000000080001cc2 <freeproc>:
{
    80001cc2:	1101                	addi	sp,sp,-32
    80001cc4:	ec06                	sd	ra,24(sp)
    80001cc6:	e822                	sd	s0,16(sp)
    80001cc8:	e426                	sd	s1,8(sp)
    80001cca:	1000                	addi	s0,sp,32
    80001ccc:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cce:	6d28                	ld	a0,88(a0)
    80001cd0:	c509                	beqz	a0,80001cda <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	d52080e7          	jalr	-686(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001cda:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001cde:	68a8                	ld	a0,80(s1)
    80001ce0:	c511                	beqz	a0,80001cec <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ce2:	64ac                	ld	a1,72(s1)
    80001ce4:	00000097          	auipc	ra,0x0
    80001ce8:	f8c080e7          	jalr	-116(ra) # 80001c70 <proc_freepagetable>
  p->pagetable = 0;
    80001cec:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cf0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cf4:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001cf8:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001cfc:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d00:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d04:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d08:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d0c:	0004ac23          	sw	zero,24(s1)
}
    80001d10:	60e2                	ld	ra,24(sp)
    80001d12:	6442                	ld	s0,16(sp)
    80001d14:	64a2                	ld	s1,8(sp)
    80001d16:	6105                	addi	sp,sp,32
    80001d18:	8082                	ret

0000000080001d1a <allocproc>:
{
    80001d1a:	1101                	addi	sp,sp,-32
    80001d1c:	ec06                	sd	ra,24(sp)
    80001d1e:	e822                	sd	s0,16(sp)
    80001d20:	e426                	sd	s1,8(sp)
    80001d22:	e04a                	sd	s2,0(sp)
    80001d24:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d26:	00010497          	auipc	s1,0x10
    80001d2a:	04248493          	addi	s1,s1,66 # 80011d68 <proc>
    80001d2e:	00016917          	auipc	s2,0x16
    80001d32:	c3a90913          	addi	s2,s2,-966 # 80017968 <tickslock>
    acquire(&p->lock);
    80001d36:	8526                	mv	a0,s1
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	f22080e7          	jalr	-222(ra) # 80000c5a <acquire>
    if(p->state == UNUSED) {
    80001d40:	4c9c                	lw	a5,24(s1)
    80001d42:	cf81                	beqz	a5,80001d5a <allocproc+0x40>
      release(&p->lock);
    80001d44:	8526                	mv	a0,s1
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	fc8080e7          	jalr	-56(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d4e:	17048493          	addi	s1,s1,368
    80001d52:	ff2492e3          	bne	s1,s2,80001d36 <allocproc+0x1c>
  return 0;
    80001d56:	4481                	li	s1,0
    80001d58:	a889                	j	80001daa <allocproc+0x90>
  p->pid = allocpid();
    80001d5a:	00000097          	auipc	ra,0x0
    80001d5e:	e34080e7          	jalr	-460(ra) # 80001b8e <allocpid>
    80001d62:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	dbc080e7          	jalr	-580(ra) # 80000b20 <kalloc>
    80001d6c:	892a                	mv	s2,a0
    80001d6e:	eca8                	sd	a0,88(s1)
    80001d70:	c521                	beqz	a0,80001db8 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d72:	8526                	mv	a0,s1
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	e60080e7          	jalr	-416(ra) # 80001bd4 <proc_pagetable>
    80001d7c:	892a                	mv	s2,a0
    80001d7e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d80:	c139                	beqz	a0,80001dc6 <allocproc+0xac>
  memset(&p->context, 0, sizeof(p->context));
    80001d82:	07000613          	li	a2,112
    80001d86:	4581                	li	a1,0
    80001d88:	06048513          	addi	a0,s1,96
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	fca080e7          	jalr	-54(ra) # 80000d56 <memset>
  p->context.ra = (uint64)forkret;
    80001d94:	00000797          	auipc	a5,0x0
    80001d98:	db478793          	addi	a5,a5,-588 # 80001b48 <forkret>
    80001d9c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d9e:	60bc                	ld	a5,64(s1)
    80001da0:	6705                	lui	a4,0x1
    80001da2:	97ba                	add	a5,a5,a4
    80001da4:	f4bc                	sd	a5,104(s1)
  p->tracemask = 0;
    80001da6:	1604b423          	sd	zero,360(s1)
}
    80001daa:	8526                	mv	a0,s1
    80001dac:	60e2                	ld	ra,24(sp)
    80001dae:	6442                	ld	s0,16(sp)
    80001db0:	64a2                	ld	s1,8(sp)
    80001db2:	6902                	ld	s2,0(sp)
    80001db4:	6105                	addi	sp,sp,32
    80001db6:	8082                	ret
    release(&p->lock);
    80001db8:	8526                	mv	a0,s1
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	f54080e7          	jalr	-172(ra) # 80000d0e <release>
    return 0;
    80001dc2:	84ca                	mv	s1,s2
    80001dc4:	b7dd                	j	80001daa <allocproc+0x90>
    freeproc(p);
    80001dc6:	8526                	mv	a0,s1
    80001dc8:	00000097          	auipc	ra,0x0
    80001dcc:	efa080e7          	jalr	-262(ra) # 80001cc2 <freeproc>
    release(&p->lock);
    80001dd0:	8526                	mv	a0,s1
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	f3c080e7          	jalr	-196(ra) # 80000d0e <release>
    return 0;
    80001dda:	84ca                	mv	s1,s2
    80001ddc:	b7f9                	j	80001daa <allocproc+0x90>

0000000080001dde <userinit>:
{
    80001dde:	1101                	addi	sp,sp,-32
    80001de0:	ec06                	sd	ra,24(sp)
    80001de2:	e822                	sd	s0,16(sp)
    80001de4:	e426                	sd	s1,8(sp)
    80001de6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001de8:	00000097          	auipc	ra,0x0
    80001dec:	f32080e7          	jalr	-206(ra) # 80001d1a <allocproc>
    80001df0:	84aa                	mv	s1,a0
  initproc = p;
    80001df2:	00007797          	auipc	a5,0x7
    80001df6:	22a7b323          	sd	a0,550(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001dfa:	03400613          	li	a2,52
    80001dfe:	00007597          	auipc	a1,0x7
    80001e02:	c8258593          	addi	a1,a1,-894 # 80008a80 <initcode>
    80001e06:	6928                	ld	a0,80(a0)
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	612080e7          	jalr	1554(ra) # 8000141a <uvminit>
  p->sz = PGSIZE;
    80001e10:	6785                	lui	a5,0x1
    80001e12:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e14:	6cb8                	ld	a4,88(s1)
    80001e16:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e1a:	6cb8                	ld	a4,88(s1)
    80001e1c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e1e:	4641                	li	a2,16
    80001e20:	00006597          	auipc	a1,0x6
    80001e24:	45858593          	addi	a1,a1,1112 # 80008278 <indent.1674+0x40>
    80001e28:	15848513          	addi	a0,s1,344
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	080080e7          	jalr	128(ra) # 80000eac <safestrcpy>
  p->cwd = namei("/");
    80001e34:	00006517          	auipc	a0,0x6
    80001e38:	45450513          	addi	a0,a0,1108 # 80008288 <indent.1674+0x50>
    80001e3c:	00002097          	auipc	ra,0x2
    80001e40:	1ec080e7          	jalr	492(ra) # 80004028 <namei>
    80001e44:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e48:	4789                	li	a5,2
    80001e4a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e4c:	8526                	mv	a0,s1
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	ec0080e7          	jalr	-320(ra) # 80000d0e <release>
}
    80001e56:	60e2                	ld	ra,24(sp)
    80001e58:	6442                	ld	s0,16(sp)
    80001e5a:	64a2                	ld	s1,8(sp)
    80001e5c:	6105                	addi	sp,sp,32
    80001e5e:	8082                	ret

0000000080001e60 <growproc>:
{
    80001e60:	1101                	addi	sp,sp,-32
    80001e62:	ec06                	sd	ra,24(sp)
    80001e64:	e822                	sd	s0,16(sp)
    80001e66:	e426                	sd	s1,8(sp)
    80001e68:	e04a                	sd	s2,0(sp)
    80001e6a:	1000                	addi	s0,sp,32
    80001e6c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e6e:	00000097          	auipc	ra,0x0
    80001e72:	ca2080e7          	jalr	-862(ra) # 80001b10 <myproc>
    80001e76:	892a                	mv	s2,a0
  sz = p->sz;
    80001e78:	652c                	ld	a1,72(a0)
    80001e7a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e7e:	00904f63          	bgtz	s1,80001e9c <growproc+0x3c>
  } else if(n < 0){
    80001e82:	0204cc63          	bltz	s1,80001eba <growproc+0x5a>
  p->sz = sz;
    80001e86:	1602                	slli	a2,a2,0x20
    80001e88:	9201                	srli	a2,a2,0x20
    80001e8a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e8e:	4501                	li	a0,0
}
    80001e90:	60e2                	ld	ra,24(sp)
    80001e92:	6442                	ld	s0,16(sp)
    80001e94:	64a2                	ld	s1,8(sp)
    80001e96:	6902                	ld	s2,0(sp)
    80001e98:	6105                	addi	sp,sp,32
    80001e9a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e9c:	9e25                	addw	a2,a2,s1
    80001e9e:	1602                	slli	a2,a2,0x20
    80001ea0:	9201                	srli	a2,a2,0x20
    80001ea2:	1582                	slli	a1,a1,0x20
    80001ea4:	9181                	srli	a1,a1,0x20
    80001ea6:	6928                	ld	a0,80(a0)
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	62c080e7          	jalr	1580(ra) # 800014d4 <uvmalloc>
    80001eb0:	0005061b          	sext.w	a2,a0
    80001eb4:	fa69                	bnez	a2,80001e86 <growproc+0x26>
      return -1;
    80001eb6:	557d                	li	a0,-1
    80001eb8:	bfe1                	j	80001e90 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001eba:	9e25                	addw	a2,a2,s1
    80001ebc:	1602                	slli	a2,a2,0x20
    80001ebe:	9201                	srli	a2,a2,0x20
    80001ec0:	1582                	slli	a1,a1,0x20
    80001ec2:	9181                	srli	a1,a1,0x20
    80001ec4:	6928                	ld	a0,80(a0)
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	5c6080e7          	jalr	1478(ra) # 8000148c <uvmdealloc>
    80001ece:	0005061b          	sext.w	a2,a0
    80001ed2:	bf55                	j	80001e86 <growproc+0x26>

0000000080001ed4 <fork>:
{
    80001ed4:	7179                	addi	sp,sp,-48
    80001ed6:	f406                	sd	ra,40(sp)
    80001ed8:	f022                	sd	s0,32(sp)
    80001eda:	ec26                	sd	s1,24(sp)
    80001edc:	e84a                	sd	s2,16(sp)
    80001ede:	e44e                	sd	s3,8(sp)
    80001ee0:	e052                	sd	s4,0(sp)
    80001ee2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ee4:	00000097          	auipc	ra,0x0
    80001ee8:	c2c080e7          	jalr	-980(ra) # 80001b10 <myproc>
    80001eec:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001eee:	00000097          	auipc	ra,0x0
    80001ef2:	e2c080e7          	jalr	-468(ra) # 80001d1a <allocproc>
    80001ef6:	c575                	beqz	a0,80001fe2 <fork+0x10e>
    80001ef8:	89aa                	mv	s3,a0
  np->tracemask = p->tracemask;
    80001efa:	16893783          	ld	a5,360(s2)
    80001efe:	16f53423          	sd	a5,360(a0)
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f02:	04893603          	ld	a2,72(s2)
    80001f06:	692c                	ld	a1,80(a0)
    80001f08:	05093503          	ld	a0,80(s2)
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	714080e7          	jalr	1812(ra) # 80001620 <uvmcopy>
    80001f14:	04054863          	bltz	a0,80001f64 <fork+0x90>
  np->sz = p->sz;
    80001f18:	04893783          	ld	a5,72(s2)
    80001f1c:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001f20:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f24:	05893683          	ld	a3,88(s2)
    80001f28:	87b6                	mv	a5,a3
    80001f2a:	0589b703          	ld	a4,88(s3)
    80001f2e:	12068693          	addi	a3,a3,288
    80001f32:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f36:	6788                	ld	a0,8(a5)
    80001f38:	6b8c                	ld	a1,16(a5)
    80001f3a:	6f90                	ld	a2,24(a5)
    80001f3c:	01073023          	sd	a6,0(a4)
    80001f40:	e708                	sd	a0,8(a4)
    80001f42:	eb0c                	sd	a1,16(a4)
    80001f44:	ef10                	sd	a2,24(a4)
    80001f46:	02078793          	addi	a5,a5,32
    80001f4a:	02070713          	addi	a4,a4,32
    80001f4e:	fed792e3          	bne	a5,a3,80001f32 <fork+0x5e>
  np->trapframe->a0 = 0;
    80001f52:	0589b783          	ld	a5,88(s3)
    80001f56:	0607b823          	sd	zero,112(a5)
    80001f5a:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f5e:	15000a13          	li	s4,336
    80001f62:	a03d                	j	80001f90 <fork+0xbc>
    freeproc(np);
    80001f64:	854e                	mv	a0,s3
    80001f66:	00000097          	auipc	ra,0x0
    80001f6a:	d5c080e7          	jalr	-676(ra) # 80001cc2 <freeproc>
    release(&np->lock);
    80001f6e:	854e                	mv	a0,s3
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	d9e080e7          	jalr	-610(ra) # 80000d0e <release>
    return -1;
    80001f78:	54fd                	li	s1,-1
    80001f7a:	a899                	j	80001fd0 <fork+0xfc>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f7c:	00002097          	auipc	ra,0x2
    80001f80:	738080e7          	jalr	1848(ra) # 800046b4 <filedup>
    80001f84:	009987b3          	add	a5,s3,s1
    80001f88:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f8a:	04a1                	addi	s1,s1,8
    80001f8c:	01448763          	beq	s1,s4,80001f9a <fork+0xc6>
    if(p->ofile[i])
    80001f90:	009907b3          	add	a5,s2,s1
    80001f94:	6388                	ld	a0,0(a5)
    80001f96:	f17d                	bnez	a0,80001f7c <fork+0xa8>
    80001f98:	bfcd                	j	80001f8a <fork+0xb6>
  np->cwd = idup(p->cwd);
    80001f9a:	15093503          	ld	a0,336(s2)
    80001f9e:	00002097          	auipc	ra,0x2
    80001fa2:	89c080e7          	jalr	-1892(ra) # 8000383a <idup>
    80001fa6:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001faa:	4641                	li	a2,16
    80001fac:	15890593          	addi	a1,s2,344
    80001fb0:	15898513          	addi	a0,s3,344
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	ef8080e7          	jalr	-264(ra) # 80000eac <safestrcpy>
  pid = np->pid;
    80001fbc:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001fc0:	4789                	li	a5,2
    80001fc2:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fc6:	854e                	mv	a0,s3
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	d46080e7          	jalr	-698(ra) # 80000d0e <release>
}
    80001fd0:	8526                	mv	a0,s1
    80001fd2:	70a2                	ld	ra,40(sp)
    80001fd4:	7402                	ld	s0,32(sp)
    80001fd6:	64e2                	ld	s1,24(sp)
    80001fd8:	6942                	ld	s2,16(sp)
    80001fda:	69a2                	ld	s3,8(sp)
    80001fdc:	6a02                	ld	s4,0(sp)
    80001fde:	6145                	addi	sp,sp,48
    80001fe0:	8082                	ret
    return -1;
    80001fe2:	54fd                	li	s1,-1
    80001fe4:	b7f5                	j	80001fd0 <fork+0xfc>

0000000080001fe6 <reparent>:
{
    80001fe6:	7179                	addi	sp,sp,-48
    80001fe8:	f406                	sd	ra,40(sp)
    80001fea:	f022                	sd	s0,32(sp)
    80001fec:	ec26                	sd	s1,24(sp)
    80001fee:	e84a                	sd	s2,16(sp)
    80001ff0:	e44e                	sd	s3,8(sp)
    80001ff2:	e052                	sd	s4,0(sp)
    80001ff4:	1800                	addi	s0,sp,48
    80001ff6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ff8:	00010497          	auipc	s1,0x10
    80001ffc:	d7048493          	addi	s1,s1,-656 # 80011d68 <proc>
      pp->parent = initproc;
    80002000:	00007a17          	auipc	s4,0x7
    80002004:	018a0a13          	addi	s4,s4,24 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002008:	00016997          	auipc	s3,0x16
    8000200c:	96098993          	addi	s3,s3,-1696 # 80017968 <tickslock>
    80002010:	a029                	j	8000201a <reparent+0x34>
    80002012:	17048493          	addi	s1,s1,368
    80002016:	03348363          	beq	s1,s3,8000203c <reparent+0x56>
    if(pp->parent == p){
    8000201a:	709c                	ld	a5,32(s1)
    8000201c:	ff279be3          	bne	a5,s2,80002012 <reparent+0x2c>
      acquire(&pp->lock);
    80002020:	8526                	mv	a0,s1
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	c38080e7          	jalr	-968(ra) # 80000c5a <acquire>
      pp->parent = initproc;
    8000202a:	000a3783          	ld	a5,0(s4)
    8000202e:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002030:	8526                	mv	a0,s1
    80002032:	fffff097          	auipc	ra,0xfffff
    80002036:	cdc080e7          	jalr	-804(ra) # 80000d0e <release>
    8000203a:	bfe1                	j	80002012 <reparent+0x2c>
}
    8000203c:	70a2                	ld	ra,40(sp)
    8000203e:	7402                	ld	s0,32(sp)
    80002040:	64e2                	ld	s1,24(sp)
    80002042:	6942                	ld	s2,16(sp)
    80002044:	69a2                	ld	s3,8(sp)
    80002046:	6a02                	ld	s4,0(sp)
    80002048:	6145                	addi	sp,sp,48
    8000204a:	8082                	ret

000000008000204c <scheduler>:
{
    8000204c:	715d                	addi	sp,sp,-80
    8000204e:	e486                	sd	ra,72(sp)
    80002050:	e0a2                	sd	s0,64(sp)
    80002052:	fc26                	sd	s1,56(sp)
    80002054:	f84a                	sd	s2,48(sp)
    80002056:	f44e                	sd	s3,40(sp)
    80002058:	f052                	sd	s4,32(sp)
    8000205a:	ec56                	sd	s5,24(sp)
    8000205c:	e85a                	sd	s6,16(sp)
    8000205e:	e45e                	sd	s7,8(sp)
    80002060:	e062                	sd	s8,0(sp)
    80002062:	0880                	addi	s0,sp,80
    80002064:	8792                	mv	a5,tp
  int id = r_tp();
    80002066:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002068:	00779b13          	slli	s6,a5,0x7
    8000206c:	00010717          	auipc	a4,0x10
    80002070:	8e470713          	addi	a4,a4,-1820 # 80011950 <pid_lock>
    80002074:	975a                	add	a4,a4,s6
    80002076:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    8000207a:	00010717          	auipc	a4,0x10
    8000207e:	8f670713          	addi	a4,a4,-1802 # 80011970 <cpus+0x8>
    80002082:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80002084:	4c0d                	li	s8,3
        c->proc = p;
    80002086:	079e                	slli	a5,a5,0x7
    80002088:	00010a17          	auipc	s4,0x10
    8000208c:	8c8a0a13          	addi	s4,s4,-1848 # 80011950 <pid_lock>
    80002090:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002092:	00016997          	auipc	s3,0x16
    80002096:	8d698993          	addi	s3,s3,-1834 # 80017968 <tickslock>
        found = 1;
    8000209a:	4b85                	li	s7,1
    8000209c:	a899                	j	800020f2 <scheduler+0xa6>
        p->state = RUNNING;
    8000209e:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    800020a2:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    800020a6:	06048593          	addi	a1,s1,96
    800020aa:	855a                	mv	a0,s6
    800020ac:	00000097          	auipc	ra,0x0
    800020b0:	68c080e7          	jalr	1676(ra) # 80002738 <swtch>
        c->proc = 0;
    800020b4:	000a3c23          	sd	zero,24(s4)
        found = 1;
    800020b8:	8ade                	mv	s5,s7
      release(&p->lock);
    800020ba:	8526                	mv	a0,s1
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	c52080e7          	jalr	-942(ra) # 80000d0e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800020c4:	17048493          	addi	s1,s1,368
    800020c8:	01348b63          	beq	s1,s3,800020de <scheduler+0x92>
      acquire(&p->lock);
    800020cc:	8526                	mv	a0,s1
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	b8c080e7          	jalr	-1140(ra) # 80000c5a <acquire>
      if(p->state == RUNNABLE) {
    800020d6:	4c9c                	lw	a5,24(s1)
    800020d8:	ff2791e3          	bne	a5,s2,800020ba <scheduler+0x6e>
    800020dc:	b7c9                	j	8000209e <scheduler+0x52>
    if(found == 0) {
    800020de:	000a9a63          	bnez	s5,800020f2 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020e2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020e6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020ea:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800020ee:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020f2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020f6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020fa:	10079073          	csrw	sstatus,a5
    int found = 0;
    800020fe:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002100:	00010497          	auipc	s1,0x10
    80002104:	c6848493          	addi	s1,s1,-920 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002108:	4909                	li	s2,2
    8000210a:	b7c9                	j	800020cc <scheduler+0x80>

000000008000210c <sched>:
{
    8000210c:	7179                	addi	sp,sp,-48
    8000210e:	f406                	sd	ra,40(sp)
    80002110:	f022                	sd	s0,32(sp)
    80002112:	ec26                	sd	s1,24(sp)
    80002114:	e84a                	sd	s2,16(sp)
    80002116:	e44e                	sd	s3,8(sp)
    80002118:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	9f6080e7          	jalr	-1546(ra) # 80001b10 <myproc>
    80002122:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	abc080e7          	jalr	-1348(ra) # 80000be0 <holding>
    8000212c:	c93d                	beqz	a0,800021a2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000212e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002130:	2781                	sext.w	a5,a5
    80002132:	079e                	slli	a5,a5,0x7
    80002134:	00010717          	auipc	a4,0x10
    80002138:	81c70713          	addi	a4,a4,-2020 # 80011950 <pid_lock>
    8000213c:	97ba                	add	a5,a5,a4
    8000213e:	0907a703          	lw	a4,144(a5)
    80002142:	4785                	li	a5,1
    80002144:	06f71763          	bne	a4,a5,800021b2 <sched+0xa6>
  if(p->state == RUNNING)
    80002148:	4c98                	lw	a4,24(s1)
    8000214a:	478d                	li	a5,3
    8000214c:	06f70b63          	beq	a4,a5,800021c2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002150:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002154:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002156:	efb5                	bnez	a5,800021d2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002158:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000215a:	0000f917          	auipc	s2,0xf
    8000215e:	7f690913          	addi	s2,s2,2038 # 80011950 <pid_lock>
    80002162:	2781                	sext.w	a5,a5
    80002164:	079e                	slli	a5,a5,0x7
    80002166:	97ca                	add	a5,a5,s2
    80002168:	0947a983          	lw	s3,148(a5)
    8000216c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000216e:	2781                	sext.w	a5,a5
    80002170:	079e                	slli	a5,a5,0x7
    80002172:	0000f597          	auipc	a1,0xf
    80002176:	7fe58593          	addi	a1,a1,2046 # 80011970 <cpus+0x8>
    8000217a:	95be                	add	a1,a1,a5
    8000217c:	06048513          	addi	a0,s1,96
    80002180:	00000097          	auipc	ra,0x0
    80002184:	5b8080e7          	jalr	1464(ra) # 80002738 <swtch>
    80002188:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000218a:	2781                	sext.w	a5,a5
    8000218c:	079e                	slli	a5,a5,0x7
    8000218e:	97ca                	add	a5,a5,s2
    80002190:	0937aa23          	sw	s3,148(a5)
}
    80002194:	70a2                	ld	ra,40(sp)
    80002196:	7402                	ld	s0,32(sp)
    80002198:	64e2                	ld	s1,24(sp)
    8000219a:	6942                	ld	s2,16(sp)
    8000219c:	69a2                	ld	s3,8(sp)
    8000219e:	6145                	addi	sp,sp,48
    800021a0:	8082                	ret
    panic("sched p->lock");
    800021a2:	00006517          	auipc	a0,0x6
    800021a6:	0ee50513          	addi	a0,a0,238 # 80008290 <indent.1674+0x58>
    800021aa:	ffffe097          	auipc	ra,0xffffe
    800021ae:	39e080e7          	jalr	926(ra) # 80000548 <panic>
    panic("sched locks");
    800021b2:	00006517          	auipc	a0,0x6
    800021b6:	0ee50513          	addi	a0,a0,238 # 800082a0 <indent.1674+0x68>
    800021ba:	ffffe097          	auipc	ra,0xffffe
    800021be:	38e080e7          	jalr	910(ra) # 80000548 <panic>
    panic("sched running");
    800021c2:	00006517          	auipc	a0,0x6
    800021c6:	0ee50513          	addi	a0,a0,238 # 800082b0 <indent.1674+0x78>
    800021ca:	ffffe097          	auipc	ra,0xffffe
    800021ce:	37e080e7          	jalr	894(ra) # 80000548 <panic>
    panic("sched interruptible");
    800021d2:	00006517          	auipc	a0,0x6
    800021d6:	0ee50513          	addi	a0,a0,238 # 800082c0 <indent.1674+0x88>
    800021da:	ffffe097          	auipc	ra,0xffffe
    800021de:	36e080e7          	jalr	878(ra) # 80000548 <panic>

00000000800021e2 <exit>:
{
    800021e2:	7179                	addi	sp,sp,-48
    800021e4:	f406                	sd	ra,40(sp)
    800021e6:	f022                	sd	s0,32(sp)
    800021e8:	ec26                	sd	s1,24(sp)
    800021ea:	e84a                	sd	s2,16(sp)
    800021ec:	e44e                	sd	s3,8(sp)
    800021ee:	e052                	sd	s4,0(sp)
    800021f0:	1800                	addi	s0,sp,48
    800021f2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021f4:	00000097          	auipc	ra,0x0
    800021f8:	91c080e7          	jalr	-1764(ra) # 80001b10 <myproc>
    800021fc:	89aa                	mv	s3,a0
  if(p == initproc)
    800021fe:	00007797          	auipc	a5,0x7
    80002202:	e1a7b783          	ld	a5,-486(a5) # 80009018 <initproc>
    80002206:	0d050493          	addi	s1,a0,208
    8000220a:	15050913          	addi	s2,a0,336
    8000220e:	02a79363          	bne	a5,a0,80002234 <exit+0x52>
    panic("init exiting");
    80002212:	00006517          	auipc	a0,0x6
    80002216:	0c650513          	addi	a0,a0,198 # 800082d8 <indent.1674+0xa0>
    8000221a:	ffffe097          	auipc	ra,0xffffe
    8000221e:	32e080e7          	jalr	814(ra) # 80000548 <panic>
      fileclose(f);
    80002222:	00002097          	auipc	ra,0x2
    80002226:	4e4080e7          	jalr	1252(ra) # 80004706 <fileclose>
      p->ofile[fd] = 0;
    8000222a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000222e:	04a1                	addi	s1,s1,8
    80002230:	01248563          	beq	s1,s2,8000223a <exit+0x58>
    if(p->ofile[fd]){
    80002234:	6088                	ld	a0,0(s1)
    80002236:	f575                	bnez	a0,80002222 <exit+0x40>
    80002238:	bfdd                	j	8000222e <exit+0x4c>
  begin_op();
    8000223a:	00002097          	auipc	ra,0x2
    8000223e:	ffa080e7          	jalr	-6(ra) # 80004234 <begin_op>
  iput(p->cwd);
    80002242:	1509b503          	ld	a0,336(s3)
    80002246:	00001097          	auipc	ra,0x1
    8000224a:	7ec080e7          	jalr	2028(ra) # 80003a32 <iput>
  end_op();
    8000224e:	00002097          	auipc	ra,0x2
    80002252:	066080e7          	jalr	102(ra) # 800042b4 <end_op>
  p->cwd = 0;
    80002256:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000225a:	00007497          	auipc	s1,0x7
    8000225e:	dbe48493          	addi	s1,s1,-578 # 80009018 <initproc>
    80002262:	6088                	ld	a0,0(s1)
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	9f6080e7          	jalr	-1546(ra) # 80000c5a <acquire>
  wakeup1(initproc);
    8000226c:	6088                	ld	a0,0(s1)
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	762080e7          	jalr	1890(ra) # 800019d0 <wakeup1>
  release(&initproc->lock);
    80002276:	6088                	ld	a0,0(s1)
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	a96080e7          	jalr	-1386(ra) # 80000d0e <release>
  acquire(&p->lock);
    80002280:	854e                	mv	a0,s3
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	9d8080e7          	jalr	-1576(ra) # 80000c5a <acquire>
  struct proc *original_parent = p->parent;
    8000228a:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000228e:	854e                	mv	a0,s3
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	a7e080e7          	jalr	-1410(ra) # 80000d0e <release>
  acquire(&original_parent->lock);
    80002298:	8526                	mv	a0,s1
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	9c0080e7          	jalr	-1600(ra) # 80000c5a <acquire>
  acquire(&p->lock);
    800022a2:	854e                	mv	a0,s3
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	9b6080e7          	jalr	-1610(ra) # 80000c5a <acquire>
  reparent(p);
    800022ac:	854e                	mv	a0,s3
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	d38080e7          	jalr	-712(ra) # 80001fe6 <reparent>
  wakeup1(original_parent);
    800022b6:	8526                	mv	a0,s1
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	718080e7          	jalr	1816(ra) # 800019d0 <wakeup1>
  p->xstate = status;
    800022c0:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800022c4:	4791                	li	a5,4
    800022c6:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	a42080e7          	jalr	-1470(ra) # 80000d0e <release>
  sched();
    800022d4:	00000097          	auipc	ra,0x0
    800022d8:	e38080e7          	jalr	-456(ra) # 8000210c <sched>
  panic("zombie exit");
    800022dc:	00006517          	auipc	a0,0x6
    800022e0:	00c50513          	addi	a0,a0,12 # 800082e8 <indent.1674+0xb0>
    800022e4:	ffffe097          	auipc	ra,0xffffe
    800022e8:	264080e7          	jalr	612(ra) # 80000548 <panic>

00000000800022ec <yield>:
{
    800022ec:	1101                	addi	sp,sp,-32
    800022ee:	ec06                	sd	ra,24(sp)
    800022f0:	e822                	sd	s0,16(sp)
    800022f2:	e426                	sd	s1,8(sp)
    800022f4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	81a080e7          	jalr	-2022(ra) # 80001b10 <myproc>
    800022fe:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	95a080e7          	jalr	-1702(ra) # 80000c5a <acquire>
  p->state = RUNNABLE;
    80002308:	4789                	li	a5,2
    8000230a:	cc9c                	sw	a5,24(s1)
  sched();
    8000230c:	00000097          	auipc	ra,0x0
    80002310:	e00080e7          	jalr	-512(ra) # 8000210c <sched>
  release(&p->lock);
    80002314:	8526                	mv	a0,s1
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	9f8080e7          	jalr	-1544(ra) # 80000d0e <release>
}
    8000231e:	60e2                	ld	ra,24(sp)
    80002320:	6442                	ld	s0,16(sp)
    80002322:	64a2                	ld	s1,8(sp)
    80002324:	6105                	addi	sp,sp,32
    80002326:	8082                	ret

0000000080002328 <sleep>:
{
    80002328:	7179                	addi	sp,sp,-48
    8000232a:	f406                	sd	ra,40(sp)
    8000232c:	f022                	sd	s0,32(sp)
    8000232e:	ec26                	sd	s1,24(sp)
    80002330:	e84a                	sd	s2,16(sp)
    80002332:	e44e                	sd	s3,8(sp)
    80002334:	1800                	addi	s0,sp,48
    80002336:	89aa                	mv	s3,a0
    80002338:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	7d6080e7          	jalr	2006(ra) # 80001b10 <myproc>
    80002342:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002344:	05250663          	beq	a0,s2,80002390 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	912080e7          	jalr	-1774(ra) # 80000c5a <acquire>
    release(lk);
    80002350:	854a                	mv	a0,s2
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	9bc080e7          	jalr	-1604(ra) # 80000d0e <release>
  p->chan = chan;
    8000235a:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000235e:	4785                	li	a5,1
    80002360:	cc9c                	sw	a5,24(s1)
  sched();
    80002362:	00000097          	auipc	ra,0x0
    80002366:	daa080e7          	jalr	-598(ra) # 8000210c <sched>
  p->chan = 0;
    8000236a:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000236e:	8526                	mv	a0,s1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	99e080e7          	jalr	-1634(ra) # 80000d0e <release>
    acquire(lk);
    80002378:	854a                	mv	a0,s2
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	8e0080e7          	jalr	-1824(ra) # 80000c5a <acquire>
}
    80002382:	70a2                	ld	ra,40(sp)
    80002384:	7402                	ld	s0,32(sp)
    80002386:	64e2                	ld	s1,24(sp)
    80002388:	6942                	ld	s2,16(sp)
    8000238a:	69a2                	ld	s3,8(sp)
    8000238c:	6145                	addi	sp,sp,48
    8000238e:	8082                	ret
  p->chan = chan;
    80002390:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002394:	4785                	li	a5,1
    80002396:	cd1c                	sw	a5,24(a0)
  sched();
    80002398:	00000097          	auipc	ra,0x0
    8000239c:	d74080e7          	jalr	-652(ra) # 8000210c <sched>
  p->chan = 0;
    800023a0:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800023a4:	bff9                	j	80002382 <sleep+0x5a>

00000000800023a6 <wait>:
{
    800023a6:	715d                	addi	sp,sp,-80
    800023a8:	e486                	sd	ra,72(sp)
    800023aa:	e0a2                	sd	s0,64(sp)
    800023ac:	fc26                	sd	s1,56(sp)
    800023ae:	f84a                	sd	s2,48(sp)
    800023b0:	f44e                	sd	s3,40(sp)
    800023b2:	f052                	sd	s4,32(sp)
    800023b4:	ec56                	sd	s5,24(sp)
    800023b6:	e85a                	sd	s6,16(sp)
    800023b8:	e45e                	sd	s7,8(sp)
    800023ba:	e062                	sd	s8,0(sp)
    800023bc:	0880                	addi	s0,sp,80
    800023be:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	750080e7          	jalr	1872(ra) # 80001b10 <myproc>
    800023c8:	892a                	mv	s2,a0
  acquire(&p->lock);
    800023ca:	8c2a                	mv	s8,a0
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	88e080e7          	jalr	-1906(ra) # 80000c5a <acquire>
    havekids = 0;
    800023d4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023d6:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800023d8:	00015997          	auipc	s3,0x15
    800023dc:	59098993          	addi	s3,s3,1424 # 80017968 <tickslock>
        havekids = 1;
    800023e0:	4a85                	li	s5,1
    havekids = 0;
    800023e2:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023e4:	00010497          	auipc	s1,0x10
    800023e8:	98448493          	addi	s1,s1,-1660 # 80011d68 <proc>
    800023ec:	a08d                	j	8000244e <wait+0xa8>
          pid = np->pid;
    800023ee:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023f2:	000b0e63          	beqz	s6,8000240e <wait+0x68>
    800023f6:	4691                	li	a3,4
    800023f8:	03448613          	addi	a2,s1,52
    800023fc:	85da                	mv	a1,s6
    800023fe:	05093503          	ld	a0,80(s2)
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	322080e7          	jalr	802(ra) # 80001724 <copyout>
    8000240a:	02054263          	bltz	a0,8000242e <wait+0x88>
          freeproc(np);
    8000240e:	8526                	mv	a0,s1
    80002410:	00000097          	auipc	ra,0x0
    80002414:	8b2080e7          	jalr	-1870(ra) # 80001cc2 <freeproc>
          release(&np->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	8f4080e7          	jalr	-1804(ra) # 80000d0e <release>
          release(&p->lock);
    80002422:	854a                	mv	a0,s2
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	8ea080e7          	jalr	-1814(ra) # 80000d0e <release>
          return pid;
    8000242c:	a8a9                	j	80002486 <wait+0xe0>
            release(&np->lock);
    8000242e:	8526                	mv	a0,s1
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	8de080e7          	jalr	-1826(ra) # 80000d0e <release>
            release(&p->lock);
    80002438:	854a                	mv	a0,s2
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	8d4080e7          	jalr	-1836(ra) # 80000d0e <release>
            return -1;
    80002442:	59fd                	li	s3,-1
    80002444:	a089                	j	80002486 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002446:	17048493          	addi	s1,s1,368
    8000244a:	03348463          	beq	s1,s3,80002472 <wait+0xcc>
      if(np->parent == p){
    8000244e:	709c                	ld	a5,32(s1)
    80002450:	ff279be3          	bne	a5,s2,80002446 <wait+0xa0>
        acquire(&np->lock);
    80002454:	8526                	mv	a0,s1
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	804080e7          	jalr	-2044(ra) # 80000c5a <acquire>
        if(np->state == ZOMBIE){
    8000245e:	4c9c                	lw	a5,24(s1)
    80002460:	f94787e3          	beq	a5,s4,800023ee <wait+0x48>
        release(&np->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	8a8080e7          	jalr	-1880(ra) # 80000d0e <release>
        havekids = 1;
    8000246e:	8756                	mv	a4,s5
    80002470:	bfd9                	j	80002446 <wait+0xa0>
    if(!havekids || p->killed){
    80002472:	c701                	beqz	a4,8000247a <wait+0xd4>
    80002474:	03092783          	lw	a5,48(s2)
    80002478:	c785                	beqz	a5,800024a0 <wait+0xfa>
      release(&p->lock);
    8000247a:	854a                	mv	a0,s2
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	892080e7          	jalr	-1902(ra) # 80000d0e <release>
      return -1;
    80002484:	59fd                	li	s3,-1
}
    80002486:	854e                	mv	a0,s3
    80002488:	60a6                	ld	ra,72(sp)
    8000248a:	6406                	ld	s0,64(sp)
    8000248c:	74e2                	ld	s1,56(sp)
    8000248e:	7942                	ld	s2,48(sp)
    80002490:	79a2                	ld	s3,40(sp)
    80002492:	7a02                	ld	s4,32(sp)
    80002494:	6ae2                	ld	s5,24(sp)
    80002496:	6b42                	ld	s6,16(sp)
    80002498:	6ba2                	ld	s7,8(sp)
    8000249a:	6c02                	ld	s8,0(sp)
    8000249c:	6161                	addi	sp,sp,80
    8000249e:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800024a0:	85e2                	mv	a1,s8
    800024a2:	854a                	mv	a0,s2
    800024a4:	00000097          	auipc	ra,0x0
    800024a8:	e84080e7          	jalr	-380(ra) # 80002328 <sleep>
    havekids = 0;
    800024ac:	bf1d                	j	800023e2 <wait+0x3c>

00000000800024ae <wakeup>:
{
    800024ae:	7139                	addi	sp,sp,-64
    800024b0:	fc06                	sd	ra,56(sp)
    800024b2:	f822                	sd	s0,48(sp)
    800024b4:	f426                	sd	s1,40(sp)
    800024b6:	f04a                	sd	s2,32(sp)
    800024b8:	ec4e                	sd	s3,24(sp)
    800024ba:	e852                	sd	s4,16(sp)
    800024bc:	e456                	sd	s5,8(sp)
    800024be:	0080                	addi	s0,sp,64
    800024c0:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800024c2:	00010497          	auipc	s1,0x10
    800024c6:	8a648493          	addi	s1,s1,-1882 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800024ca:	4985                	li	s3,1
      p->state = RUNNABLE;
    800024cc:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800024ce:	00015917          	auipc	s2,0x15
    800024d2:	49a90913          	addi	s2,s2,1178 # 80017968 <tickslock>
    800024d6:	a821                	j	800024ee <wakeup+0x40>
      p->state = RUNNABLE;
    800024d8:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800024dc:	8526                	mv	a0,s1
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	830080e7          	jalr	-2000(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024e6:	17048493          	addi	s1,s1,368
    800024ea:	01248e63          	beq	s1,s2,80002506 <wakeup+0x58>
    acquire(&p->lock);
    800024ee:	8526                	mv	a0,s1
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	76a080e7          	jalr	1898(ra) # 80000c5a <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800024f8:	4c9c                	lw	a5,24(s1)
    800024fa:	ff3791e3          	bne	a5,s3,800024dc <wakeup+0x2e>
    800024fe:	749c                	ld	a5,40(s1)
    80002500:	fd479ee3          	bne	a5,s4,800024dc <wakeup+0x2e>
    80002504:	bfd1                	j	800024d8 <wakeup+0x2a>
}
    80002506:	70e2                	ld	ra,56(sp)
    80002508:	7442                	ld	s0,48(sp)
    8000250a:	74a2                	ld	s1,40(sp)
    8000250c:	7902                	ld	s2,32(sp)
    8000250e:	69e2                	ld	s3,24(sp)
    80002510:	6a42                	ld	s4,16(sp)
    80002512:	6aa2                	ld	s5,8(sp)
    80002514:	6121                	addi	sp,sp,64
    80002516:	8082                	ret

0000000080002518 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002518:	7179                	addi	sp,sp,-48
    8000251a:	f406                	sd	ra,40(sp)
    8000251c:	f022                	sd	s0,32(sp)
    8000251e:	ec26                	sd	s1,24(sp)
    80002520:	e84a                	sd	s2,16(sp)
    80002522:	e44e                	sd	s3,8(sp)
    80002524:	1800                	addi	s0,sp,48
    80002526:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002528:	00010497          	auipc	s1,0x10
    8000252c:	84048493          	addi	s1,s1,-1984 # 80011d68 <proc>
    80002530:	00015997          	auipc	s3,0x15
    80002534:	43898993          	addi	s3,s3,1080 # 80017968 <tickslock>
    acquire(&p->lock);
    80002538:	8526                	mv	a0,s1
    8000253a:	ffffe097          	auipc	ra,0xffffe
    8000253e:	720080e7          	jalr	1824(ra) # 80000c5a <acquire>
    if(p->pid == pid){
    80002542:	5c9c                	lw	a5,56(s1)
    80002544:	01278d63          	beq	a5,s2,8000255e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002548:	8526                	mv	a0,s1
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	7c4080e7          	jalr	1988(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002552:	17048493          	addi	s1,s1,368
    80002556:	ff3491e3          	bne	s1,s3,80002538 <kill+0x20>
  }
  return -1;
    8000255a:	557d                	li	a0,-1
    8000255c:	a829                	j	80002576 <kill+0x5e>
      p->killed = 1;
    8000255e:	4785                	li	a5,1
    80002560:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002562:	4c98                	lw	a4,24(s1)
    80002564:	4785                	li	a5,1
    80002566:	00f70f63          	beq	a4,a5,80002584 <kill+0x6c>
      release(&p->lock);
    8000256a:	8526                	mv	a0,s1
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	7a2080e7          	jalr	1954(ra) # 80000d0e <release>
      return 0;
    80002574:	4501                	li	a0,0
}
    80002576:	70a2                	ld	ra,40(sp)
    80002578:	7402                	ld	s0,32(sp)
    8000257a:	64e2                	ld	s1,24(sp)
    8000257c:	6942                	ld	s2,16(sp)
    8000257e:	69a2                	ld	s3,8(sp)
    80002580:	6145                	addi	sp,sp,48
    80002582:	8082                	ret
        p->state = RUNNABLE;
    80002584:	4789                	li	a5,2
    80002586:	cc9c                	sw	a5,24(s1)
    80002588:	b7cd                	j	8000256a <kill+0x52>

000000008000258a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000258a:	7179                	addi	sp,sp,-48
    8000258c:	f406                	sd	ra,40(sp)
    8000258e:	f022                	sd	s0,32(sp)
    80002590:	ec26                	sd	s1,24(sp)
    80002592:	e84a                	sd	s2,16(sp)
    80002594:	e44e                	sd	s3,8(sp)
    80002596:	e052                	sd	s4,0(sp)
    80002598:	1800                	addi	s0,sp,48
    8000259a:	84aa                	mv	s1,a0
    8000259c:	892e                	mv	s2,a1
    8000259e:	89b2                	mv	s3,a2
    800025a0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025a2:	fffff097          	auipc	ra,0xfffff
    800025a6:	56e080e7          	jalr	1390(ra) # 80001b10 <myproc>
  if(user_dst){
    800025aa:	c08d                	beqz	s1,800025cc <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025ac:	86d2                	mv	a3,s4
    800025ae:	864e                	mv	a2,s3
    800025b0:	85ca                	mv	a1,s2
    800025b2:	6928                	ld	a0,80(a0)
    800025b4:	fffff097          	auipc	ra,0xfffff
    800025b8:	170080e7          	jalr	368(ra) # 80001724 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025bc:	70a2                	ld	ra,40(sp)
    800025be:	7402                	ld	s0,32(sp)
    800025c0:	64e2                	ld	s1,24(sp)
    800025c2:	6942                	ld	s2,16(sp)
    800025c4:	69a2                	ld	s3,8(sp)
    800025c6:	6a02                	ld	s4,0(sp)
    800025c8:	6145                	addi	sp,sp,48
    800025ca:	8082                	ret
    memmove((char *)dst, src, len);
    800025cc:	000a061b          	sext.w	a2,s4
    800025d0:	85ce                	mv	a1,s3
    800025d2:	854a                	mv	a0,s2
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	7e2080e7          	jalr	2018(ra) # 80000db6 <memmove>
    return 0;
    800025dc:	8526                	mv	a0,s1
    800025de:	bff9                	j	800025bc <either_copyout+0x32>

00000000800025e0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025e0:	7179                	addi	sp,sp,-48
    800025e2:	f406                	sd	ra,40(sp)
    800025e4:	f022                	sd	s0,32(sp)
    800025e6:	ec26                	sd	s1,24(sp)
    800025e8:	e84a                	sd	s2,16(sp)
    800025ea:	e44e                	sd	s3,8(sp)
    800025ec:	e052                	sd	s4,0(sp)
    800025ee:	1800                	addi	s0,sp,48
    800025f0:	892a                	mv	s2,a0
    800025f2:	84ae                	mv	s1,a1
    800025f4:	89b2                	mv	s3,a2
    800025f6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025f8:	fffff097          	auipc	ra,0xfffff
    800025fc:	518080e7          	jalr	1304(ra) # 80001b10 <myproc>
  if(user_src){
    80002600:	c08d                	beqz	s1,80002622 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002602:	86d2                	mv	a3,s4
    80002604:	864e                	mv	a2,s3
    80002606:	85ca                	mv	a1,s2
    80002608:	6928                	ld	a0,80(a0)
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	1a6080e7          	jalr	422(ra) # 800017b0 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002612:	70a2                	ld	ra,40(sp)
    80002614:	7402                	ld	s0,32(sp)
    80002616:	64e2                	ld	s1,24(sp)
    80002618:	6942                	ld	s2,16(sp)
    8000261a:	69a2                	ld	s3,8(sp)
    8000261c:	6a02                	ld	s4,0(sp)
    8000261e:	6145                	addi	sp,sp,48
    80002620:	8082                	ret
    memmove(dst, (char*)src, len);
    80002622:	000a061b          	sext.w	a2,s4
    80002626:	85ce                	mv	a1,s3
    80002628:	854a                	mv	a0,s2
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	78c080e7          	jalr	1932(ra) # 80000db6 <memmove>
    return 0;
    80002632:	8526                	mv	a0,s1
    80002634:	bff9                	j	80002612 <either_copyin+0x32>

0000000080002636 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002636:	715d                	addi	sp,sp,-80
    80002638:	e486                	sd	ra,72(sp)
    8000263a:	e0a2                	sd	s0,64(sp)
    8000263c:	fc26                	sd	s1,56(sp)
    8000263e:	f84a                	sd	s2,48(sp)
    80002640:	f44e                	sd	s3,40(sp)
    80002642:	f052                	sd	s4,32(sp)
    80002644:	ec56                	sd	s5,24(sp)
    80002646:	e85a                	sd	s6,16(sp)
    80002648:	e45e                	sd	s7,8(sp)
    8000264a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000264c:	00006517          	auipc	a0,0x6
    80002650:	a7c50513          	addi	a0,a0,-1412 # 800080c8 <digits+0x88>
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	f3e080e7          	jalr	-194(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000265c:	00010497          	auipc	s1,0x10
    80002660:	86448493          	addi	s1,s1,-1948 # 80011ec0 <proc+0x158>
    80002664:	00015917          	auipc	s2,0x15
    80002668:	45c90913          	addi	s2,s2,1116 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000266c:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000266e:	00006997          	auipc	s3,0x6
    80002672:	c8a98993          	addi	s3,s3,-886 # 800082f8 <indent.1674+0xc0>
    printf("%d %s %s", p->pid, state, p->name);
    80002676:	00006a97          	auipc	s5,0x6
    8000267a:	c8aa8a93          	addi	s5,s5,-886 # 80008300 <indent.1674+0xc8>
    printf("\n");
    8000267e:	00006a17          	auipc	s4,0x6
    80002682:	a4aa0a13          	addi	s4,s4,-1462 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002686:	00006b97          	auipc	s7,0x6
    8000268a:	cb2b8b93          	addi	s7,s7,-846 # 80008338 <states.1717>
    8000268e:	a00d                	j	800026b0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002690:	ee06a583          	lw	a1,-288(a3)
    80002694:	8556                	mv	a0,s5
    80002696:	ffffe097          	auipc	ra,0xffffe
    8000269a:	efc080e7          	jalr	-260(ra) # 80000592 <printf>
    printf("\n");
    8000269e:	8552                	mv	a0,s4
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	ef2080e7          	jalr	-270(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026a8:	17048493          	addi	s1,s1,368
    800026ac:	03248163          	beq	s1,s2,800026ce <procdump+0x98>
    if(p->state == UNUSED)
    800026b0:	86a6                	mv	a3,s1
    800026b2:	ec04a783          	lw	a5,-320(s1)
    800026b6:	dbed                	beqz	a5,800026a8 <procdump+0x72>
      state = "???";
    800026b8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026ba:	fcfb6be3          	bltu	s6,a5,80002690 <procdump+0x5a>
    800026be:	1782                	slli	a5,a5,0x20
    800026c0:	9381                	srli	a5,a5,0x20
    800026c2:	078e                	slli	a5,a5,0x3
    800026c4:	97de                	add	a5,a5,s7
    800026c6:	6390                	ld	a2,0(a5)
    800026c8:	f661                	bnez	a2,80002690 <procdump+0x5a>
      state = "???";
    800026ca:	864e                	mv	a2,s3
    800026cc:	b7d1                	j	80002690 <procdump+0x5a>
  }
}
    800026ce:	60a6                	ld	ra,72(sp)
    800026d0:	6406                	ld	s0,64(sp)
    800026d2:	74e2                	ld	s1,56(sp)
    800026d4:	7942                	ld	s2,48(sp)
    800026d6:	79a2                	ld	s3,40(sp)
    800026d8:	7a02                	ld	s4,32(sp)
    800026da:	6ae2                	ld	s5,24(sp)
    800026dc:	6b42                	ld	s6,16(sp)
    800026de:	6ba2                	ld	s7,8(sp)
    800026e0:	6161                	addi	sp,sp,80
    800026e2:	8082                	ret

00000000800026e4 <count_free_proc>:

// Count how many processes are not in the state of UNUSED
uint64
count_free_proc(void) {
    800026e4:	7179                	addi	sp,sp,-48
    800026e6:	f406                	sd	ra,40(sp)
    800026e8:	f022                	sd	s0,32(sp)
    800026ea:	ec26                	sd	s1,24(sp)
    800026ec:	e84a                	sd	s2,16(sp)
    800026ee:	e44e                	sd	s3,8(sp)
    800026f0:	1800                	addi	s0,sp,48
  struct proc *p;
  uint64 count = 0;
    800026f2:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    800026f4:	0000f497          	auipc	s1,0xf
    800026f8:	67448493          	addi	s1,s1,1652 # 80011d68 <proc>
    800026fc:	00015997          	auipc	s3,0x15
    80002700:	26c98993          	addi	s3,s3,620 # 80017968 <tickslock>
    acquire(&p->lock);
    80002704:	8526                	mv	a0,s1
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	554080e7          	jalr	1364(ra) # 80000c5a <acquire>
    if(p->state != UNUSED) {
    8000270e:	4c9c                	lw	a5,24(s1)
      count += 1;
    80002710:	00f037b3          	snez	a5,a5
    80002714:	993e                	add	s2,s2,a5
    }
    release(&p->lock);
    80002716:	8526                	mv	a0,s1
    80002718:	ffffe097          	auipc	ra,0xffffe
    8000271c:	5f6080e7          	jalr	1526(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002720:	17048493          	addi	s1,s1,368
    80002724:	ff3490e3          	bne	s1,s3,80002704 <count_free_proc+0x20>
  }
  return count;
}
    80002728:	854a                	mv	a0,s2
    8000272a:	70a2                	ld	ra,40(sp)
    8000272c:	7402                	ld	s0,32(sp)
    8000272e:	64e2                	ld	s1,24(sp)
    80002730:	6942                	ld	s2,16(sp)
    80002732:	69a2                	ld	s3,8(sp)
    80002734:	6145                	addi	sp,sp,48
    80002736:	8082                	ret

0000000080002738 <swtch>:
    80002738:	00153023          	sd	ra,0(a0)
    8000273c:	00253423          	sd	sp,8(a0)
    80002740:	e900                	sd	s0,16(a0)
    80002742:	ed04                	sd	s1,24(a0)
    80002744:	03253023          	sd	s2,32(a0)
    80002748:	03353423          	sd	s3,40(a0)
    8000274c:	03453823          	sd	s4,48(a0)
    80002750:	03553c23          	sd	s5,56(a0)
    80002754:	05653023          	sd	s6,64(a0)
    80002758:	05753423          	sd	s7,72(a0)
    8000275c:	05853823          	sd	s8,80(a0)
    80002760:	05953c23          	sd	s9,88(a0)
    80002764:	07a53023          	sd	s10,96(a0)
    80002768:	07b53423          	sd	s11,104(a0)
    8000276c:	0005b083          	ld	ra,0(a1)
    80002770:	0085b103          	ld	sp,8(a1)
    80002774:	6980                	ld	s0,16(a1)
    80002776:	6d84                	ld	s1,24(a1)
    80002778:	0205b903          	ld	s2,32(a1)
    8000277c:	0285b983          	ld	s3,40(a1)
    80002780:	0305ba03          	ld	s4,48(a1)
    80002784:	0385ba83          	ld	s5,56(a1)
    80002788:	0405bb03          	ld	s6,64(a1)
    8000278c:	0485bb83          	ld	s7,72(a1)
    80002790:	0505bc03          	ld	s8,80(a1)
    80002794:	0585bc83          	ld	s9,88(a1)
    80002798:	0605bd03          	ld	s10,96(a1)
    8000279c:	0685bd83          	ld	s11,104(a1)
    800027a0:	8082                	ret

00000000800027a2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027a2:	1141                	addi	sp,sp,-16
    800027a4:	e406                	sd	ra,8(sp)
    800027a6:	e022                	sd	s0,0(sp)
    800027a8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027aa:	00006597          	auipc	a1,0x6
    800027ae:	bb658593          	addi	a1,a1,-1098 # 80008360 <states.1717+0x28>
    800027b2:	00015517          	auipc	a0,0x15
    800027b6:	1b650513          	addi	a0,a0,438 # 80017968 <tickslock>
    800027ba:	ffffe097          	auipc	ra,0xffffe
    800027be:	410080e7          	jalr	1040(ra) # 80000bca <initlock>
}
    800027c2:	60a2                	ld	ra,8(sp)
    800027c4:	6402                	ld	s0,0(sp)
    800027c6:	0141                	addi	sp,sp,16
    800027c8:	8082                	ret

00000000800027ca <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027ca:	1141                	addi	sp,sp,-16
    800027cc:	e422                	sd	s0,8(sp)
    800027ce:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027d0:	00003797          	auipc	a5,0x3
    800027d4:	5c078793          	addi	a5,a5,1472 # 80005d90 <kernelvec>
    800027d8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027dc:	6422                	ld	s0,8(sp)
    800027de:	0141                	addi	sp,sp,16
    800027e0:	8082                	ret

00000000800027e2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027e2:	1141                	addi	sp,sp,-16
    800027e4:	e406                	sd	ra,8(sp)
    800027e6:	e022                	sd	s0,0(sp)
    800027e8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027ea:	fffff097          	auipc	ra,0xfffff
    800027ee:	326080e7          	jalr	806(ra) # 80001b10 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027f2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027f6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027f8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800027fc:	00005617          	auipc	a2,0x5
    80002800:	80460613          	addi	a2,a2,-2044 # 80007000 <_trampoline>
    80002804:	00004697          	auipc	a3,0x4
    80002808:	7fc68693          	addi	a3,a3,2044 # 80007000 <_trampoline>
    8000280c:	8e91                	sub	a3,a3,a2
    8000280e:	040007b7          	lui	a5,0x4000
    80002812:	17fd                	addi	a5,a5,-1
    80002814:	07b2                	slli	a5,a5,0xc
    80002816:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002818:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000281c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000281e:	180026f3          	csrr	a3,satp
    80002822:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002824:	6d38                	ld	a4,88(a0)
    80002826:	6134                	ld	a3,64(a0)
    80002828:	6585                	lui	a1,0x1
    8000282a:	96ae                	add	a3,a3,a1
    8000282c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000282e:	6d38                	ld	a4,88(a0)
    80002830:	00000697          	auipc	a3,0x0
    80002834:	13868693          	addi	a3,a3,312 # 80002968 <usertrap>
    80002838:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000283a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000283c:	8692                	mv	a3,tp
    8000283e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002840:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002844:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002848:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000284c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002850:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002852:	6f18                	ld	a4,24(a4)
    80002854:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002858:	692c                	ld	a1,80(a0)
    8000285a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000285c:	00005717          	auipc	a4,0x5
    80002860:	83470713          	addi	a4,a4,-1996 # 80007090 <userret>
    80002864:	8f11                	sub	a4,a4,a2
    80002866:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002868:	577d                	li	a4,-1
    8000286a:	177e                	slli	a4,a4,0x3f
    8000286c:	8dd9                	or	a1,a1,a4
    8000286e:	02000537          	lui	a0,0x2000
    80002872:	157d                	addi	a0,a0,-1
    80002874:	0536                	slli	a0,a0,0xd
    80002876:	9782                	jalr	a5
}
    80002878:	60a2                	ld	ra,8(sp)
    8000287a:	6402                	ld	s0,0(sp)
    8000287c:	0141                	addi	sp,sp,16
    8000287e:	8082                	ret

0000000080002880 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002880:	1101                	addi	sp,sp,-32
    80002882:	ec06                	sd	ra,24(sp)
    80002884:	e822                	sd	s0,16(sp)
    80002886:	e426                	sd	s1,8(sp)
    80002888:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000288a:	00015497          	auipc	s1,0x15
    8000288e:	0de48493          	addi	s1,s1,222 # 80017968 <tickslock>
    80002892:	8526                	mv	a0,s1
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	3c6080e7          	jalr	966(ra) # 80000c5a <acquire>
  ticks++;
    8000289c:	00006517          	auipc	a0,0x6
    800028a0:	78450513          	addi	a0,a0,1924 # 80009020 <ticks>
    800028a4:	411c                	lw	a5,0(a0)
    800028a6:	2785                	addiw	a5,a5,1
    800028a8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028aa:	00000097          	auipc	ra,0x0
    800028ae:	c04080e7          	jalr	-1020(ra) # 800024ae <wakeup>
  release(&tickslock);
    800028b2:	8526                	mv	a0,s1
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	45a080e7          	jalr	1114(ra) # 80000d0e <release>
}
    800028bc:	60e2                	ld	ra,24(sp)
    800028be:	6442                	ld	s0,16(sp)
    800028c0:	64a2                	ld	s1,8(sp)
    800028c2:	6105                	addi	sp,sp,32
    800028c4:	8082                	ret

00000000800028c6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028c6:	1101                	addi	sp,sp,-32
    800028c8:	ec06                	sd	ra,24(sp)
    800028ca:	e822                	sd	s0,16(sp)
    800028cc:	e426                	sd	s1,8(sp)
    800028ce:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028d0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028d4:	00074d63          	bltz	a4,800028ee <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028d8:	57fd                	li	a5,-1
    800028da:	17fe                	slli	a5,a5,0x3f
    800028dc:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028de:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028e0:	06f70363          	beq	a4,a5,80002946 <devintr+0x80>
  }
}
    800028e4:	60e2                	ld	ra,24(sp)
    800028e6:	6442                	ld	s0,16(sp)
    800028e8:	64a2                	ld	s1,8(sp)
    800028ea:	6105                	addi	sp,sp,32
    800028ec:	8082                	ret
     (scause & 0xff) == 9){
    800028ee:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028f2:	46a5                	li	a3,9
    800028f4:	fed792e3          	bne	a5,a3,800028d8 <devintr+0x12>
    int irq = plic_claim();
    800028f8:	00003097          	auipc	ra,0x3
    800028fc:	5a0080e7          	jalr	1440(ra) # 80005e98 <plic_claim>
    80002900:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002902:	47a9                	li	a5,10
    80002904:	02f50763          	beq	a0,a5,80002932 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002908:	4785                	li	a5,1
    8000290a:	02f50963          	beq	a0,a5,8000293c <devintr+0x76>
    return 1;
    8000290e:	4505                	li	a0,1
    } else if(irq){
    80002910:	d8f1                	beqz	s1,800028e4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002912:	85a6                	mv	a1,s1
    80002914:	00006517          	auipc	a0,0x6
    80002918:	a5450513          	addi	a0,a0,-1452 # 80008368 <states.1717+0x30>
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	c76080e7          	jalr	-906(ra) # 80000592 <printf>
      plic_complete(irq);
    80002924:	8526                	mv	a0,s1
    80002926:	00003097          	auipc	ra,0x3
    8000292a:	596080e7          	jalr	1430(ra) # 80005ebc <plic_complete>
    return 1;
    8000292e:	4505                	li	a0,1
    80002930:	bf55                	j	800028e4 <devintr+0x1e>
      uartintr();
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	0a2080e7          	jalr	162(ra) # 800009d4 <uartintr>
    8000293a:	b7ed                	j	80002924 <devintr+0x5e>
      virtio_disk_intr();
    8000293c:	00004097          	auipc	ra,0x4
    80002940:	a1a080e7          	jalr	-1510(ra) # 80006356 <virtio_disk_intr>
    80002944:	b7c5                	j	80002924 <devintr+0x5e>
    if(cpuid() == 0){
    80002946:	fffff097          	auipc	ra,0xfffff
    8000294a:	19e080e7          	jalr	414(ra) # 80001ae4 <cpuid>
    8000294e:	c901                	beqz	a0,8000295e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002950:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002954:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002956:	14479073          	csrw	sip,a5
    return 2;
    8000295a:	4509                	li	a0,2
    8000295c:	b761                	j	800028e4 <devintr+0x1e>
      clockintr();
    8000295e:	00000097          	auipc	ra,0x0
    80002962:	f22080e7          	jalr	-222(ra) # 80002880 <clockintr>
    80002966:	b7ed                	j	80002950 <devintr+0x8a>

0000000080002968 <usertrap>:
{
    80002968:	1101                	addi	sp,sp,-32
    8000296a:	ec06                	sd	ra,24(sp)
    8000296c:	e822                	sd	s0,16(sp)
    8000296e:	e426                	sd	s1,8(sp)
    80002970:	e04a                	sd	s2,0(sp)
    80002972:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002974:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002978:	1007f793          	andi	a5,a5,256
    8000297c:	e3ad                	bnez	a5,800029de <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000297e:	00003797          	auipc	a5,0x3
    80002982:	41278793          	addi	a5,a5,1042 # 80005d90 <kernelvec>
    80002986:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000298a:	fffff097          	auipc	ra,0xfffff
    8000298e:	186080e7          	jalr	390(ra) # 80001b10 <myproc>
    80002992:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002994:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002996:	14102773          	csrr	a4,sepc
    8000299a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000299c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029a0:	47a1                	li	a5,8
    800029a2:	04f71c63          	bne	a4,a5,800029fa <usertrap+0x92>
    if(p->killed)
    800029a6:	591c                	lw	a5,48(a0)
    800029a8:	e3b9                	bnez	a5,800029ee <usertrap+0x86>
    p->trapframe->epc += 4;
    800029aa:	6cb8                	ld	a4,88(s1)
    800029ac:	6f1c                	ld	a5,24(a4)
    800029ae:	0791                	addi	a5,a5,4
    800029b0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029b6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ba:	10079073          	csrw	sstatus,a5
    syscall();
    800029be:	00000097          	auipc	ra,0x0
    800029c2:	2e0080e7          	jalr	736(ra) # 80002c9e <syscall>
  if(p->killed)
    800029c6:	589c                	lw	a5,48(s1)
    800029c8:	ebc1                	bnez	a5,80002a58 <usertrap+0xf0>
  usertrapret();
    800029ca:	00000097          	auipc	ra,0x0
    800029ce:	e18080e7          	jalr	-488(ra) # 800027e2 <usertrapret>
}
    800029d2:	60e2                	ld	ra,24(sp)
    800029d4:	6442                	ld	s0,16(sp)
    800029d6:	64a2                	ld	s1,8(sp)
    800029d8:	6902                	ld	s2,0(sp)
    800029da:	6105                	addi	sp,sp,32
    800029dc:	8082                	ret
    panic("usertrap: not from user mode");
    800029de:	00006517          	auipc	a0,0x6
    800029e2:	9aa50513          	addi	a0,a0,-1622 # 80008388 <states.1717+0x50>
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	b62080e7          	jalr	-1182(ra) # 80000548 <panic>
      exit(-1);
    800029ee:	557d                	li	a0,-1
    800029f0:	fffff097          	auipc	ra,0xfffff
    800029f4:	7f2080e7          	jalr	2034(ra) # 800021e2 <exit>
    800029f8:	bf4d                	j	800029aa <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800029fa:	00000097          	auipc	ra,0x0
    800029fe:	ecc080e7          	jalr	-308(ra) # 800028c6 <devintr>
    80002a02:	892a                	mv	s2,a0
    80002a04:	c501                	beqz	a0,80002a0c <usertrap+0xa4>
  if(p->killed)
    80002a06:	589c                	lw	a5,48(s1)
    80002a08:	c3a1                	beqz	a5,80002a48 <usertrap+0xe0>
    80002a0a:	a815                	j	80002a3e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a0c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a10:	5c90                	lw	a2,56(s1)
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	99650513          	addi	a0,a0,-1642 # 800083a8 <states.1717+0x70>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b78080e7          	jalr	-1160(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a22:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a26:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a2a:	00006517          	auipc	a0,0x6
    80002a2e:	9ae50513          	addi	a0,a0,-1618 # 800083d8 <states.1717+0xa0>
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	b60080e7          	jalr	-1184(ra) # 80000592 <printf>
    p->killed = 1;
    80002a3a:	4785                	li	a5,1
    80002a3c:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002a3e:	557d                	li	a0,-1
    80002a40:	fffff097          	auipc	ra,0xfffff
    80002a44:	7a2080e7          	jalr	1954(ra) # 800021e2 <exit>
  if(which_dev == 2)
    80002a48:	4789                	li	a5,2
    80002a4a:	f8f910e3          	bne	s2,a5,800029ca <usertrap+0x62>
    yield();
    80002a4e:	00000097          	auipc	ra,0x0
    80002a52:	89e080e7          	jalr	-1890(ra) # 800022ec <yield>
    80002a56:	bf95                	j	800029ca <usertrap+0x62>
  int which_dev = 0;
    80002a58:	4901                	li	s2,0
    80002a5a:	b7d5                	j	80002a3e <usertrap+0xd6>

0000000080002a5c <kerneltrap>:
{
    80002a5c:	7179                	addi	sp,sp,-48
    80002a5e:	f406                	sd	ra,40(sp)
    80002a60:	f022                	sd	s0,32(sp)
    80002a62:	ec26                	sd	s1,24(sp)
    80002a64:	e84a                	sd	s2,16(sp)
    80002a66:	e44e                	sd	s3,8(sp)
    80002a68:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a6a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a6e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a72:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a76:	1004f793          	andi	a5,s1,256
    80002a7a:	cb85                	beqz	a5,80002aaa <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a7c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a80:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a82:	ef85                	bnez	a5,80002aba <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a84:	00000097          	auipc	ra,0x0
    80002a88:	e42080e7          	jalr	-446(ra) # 800028c6 <devintr>
    80002a8c:	cd1d                	beqz	a0,80002aca <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a8e:	4789                	li	a5,2
    80002a90:	06f50a63          	beq	a0,a5,80002b04 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a94:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a98:	10049073          	csrw	sstatus,s1
}
    80002a9c:	70a2                	ld	ra,40(sp)
    80002a9e:	7402                	ld	s0,32(sp)
    80002aa0:	64e2                	ld	s1,24(sp)
    80002aa2:	6942                	ld	s2,16(sp)
    80002aa4:	69a2                	ld	s3,8(sp)
    80002aa6:	6145                	addi	sp,sp,48
    80002aa8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	94e50513          	addi	a0,a0,-1714 # 800083f8 <states.1717+0xc0>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	a96080e7          	jalr	-1386(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002aba:	00006517          	auipc	a0,0x6
    80002abe:	96650513          	addi	a0,a0,-1690 # 80008420 <states.1717+0xe8>
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	a86080e7          	jalr	-1402(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002aca:	85ce                	mv	a1,s3
    80002acc:	00006517          	auipc	a0,0x6
    80002ad0:	97450513          	addi	a0,a0,-1676 # 80008440 <states.1717+0x108>
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	abe080e7          	jalr	-1346(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002adc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ae0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ae4:	00006517          	auipc	a0,0x6
    80002ae8:	96c50513          	addi	a0,a0,-1684 # 80008450 <states.1717+0x118>
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	aa6080e7          	jalr	-1370(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002af4:	00006517          	auipc	a0,0x6
    80002af8:	97450513          	addi	a0,a0,-1676 # 80008468 <states.1717+0x130>
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	a4c080e7          	jalr	-1460(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	00c080e7          	jalr	12(ra) # 80001b10 <myproc>
    80002b0c:	d541                	beqz	a0,80002a94 <kerneltrap+0x38>
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	002080e7          	jalr	2(ra) # 80001b10 <myproc>
    80002b16:	4d18                	lw	a4,24(a0)
    80002b18:	478d                	li	a5,3
    80002b1a:	f6f71de3          	bne	a4,a5,80002a94 <kerneltrap+0x38>
    yield();
    80002b1e:	fffff097          	auipc	ra,0xfffff
    80002b22:	7ce080e7          	jalr	1998(ra) # 800022ec <yield>
    80002b26:	b7bd                	j	80002a94 <kerneltrap+0x38>

0000000080002b28 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b28:	1101                	addi	sp,sp,-32
    80002b2a:	ec06                	sd	ra,24(sp)
    80002b2c:	e822                	sd	s0,16(sp)
    80002b2e:	e426                	sd	s1,8(sp)
    80002b30:	1000                	addi	s0,sp,32
    80002b32:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	fdc080e7          	jalr	-36(ra) # 80001b10 <myproc>
  switch (n) {
    80002b3c:	4795                	li	a5,5
    80002b3e:	0497e163          	bltu	a5,s1,80002b80 <argraw+0x58>
    80002b42:	048a                	slli	s1,s1,0x2
    80002b44:	00006717          	auipc	a4,0x6
    80002b48:	a2470713          	addi	a4,a4,-1500 # 80008568 <states.1717+0x230>
    80002b4c:	94ba                	add	s1,s1,a4
    80002b4e:	409c                	lw	a5,0(s1)
    80002b50:	97ba                	add	a5,a5,a4
    80002b52:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b54:	6d3c                	ld	a5,88(a0)
    80002b56:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b58:	60e2                	ld	ra,24(sp)
    80002b5a:	6442                	ld	s0,16(sp)
    80002b5c:	64a2                	ld	s1,8(sp)
    80002b5e:	6105                	addi	sp,sp,32
    80002b60:	8082                	ret
    return p->trapframe->a1;
    80002b62:	6d3c                	ld	a5,88(a0)
    80002b64:	7fa8                	ld	a0,120(a5)
    80002b66:	bfcd                	j	80002b58 <argraw+0x30>
    return p->trapframe->a2;
    80002b68:	6d3c                	ld	a5,88(a0)
    80002b6a:	63c8                	ld	a0,128(a5)
    80002b6c:	b7f5                	j	80002b58 <argraw+0x30>
    return p->trapframe->a3;
    80002b6e:	6d3c                	ld	a5,88(a0)
    80002b70:	67c8                	ld	a0,136(a5)
    80002b72:	b7dd                	j	80002b58 <argraw+0x30>
    return p->trapframe->a4;
    80002b74:	6d3c                	ld	a5,88(a0)
    80002b76:	6bc8                	ld	a0,144(a5)
    80002b78:	b7c5                	j	80002b58 <argraw+0x30>
    return p->trapframe->a5;
    80002b7a:	6d3c                	ld	a5,88(a0)
    80002b7c:	6fc8                	ld	a0,152(a5)
    80002b7e:	bfe9                	j	80002b58 <argraw+0x30>
  panic("argraw");
    80002b80:	00006517          	auipc	a0,0x6
    80002b84:	8f850513          	addi	a0,a0,-1800 # 80008478 <states.1717+0x140>
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	9c0080e7          	jalr	-1600(ra) # 80000548 <panic>

0000000080002b90 <fetchaddr>:
{
    80002b90:	1101                	addi	sp,sp,-32
    80002b92:	ec06                	sd	ra,24(sp)
    80002b94:	e822                	sd	s0,16(sp)
    80002b96:	e426                	sd	s1,8(sp)
    80002b98:	e04a                	sd	s2,0(sp)
    80002b9a:	1000                	addi	s0,sp,32
    80002b9c:	84aa                	mv	s1,a0
    80002b9e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ba0:	fffff097          	auipc	ra,0xfffff
    80002ba4:	f70080e7          	jalr	-144(ra) # 80001b10 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ba8:	653c                	ld	a5,72(a0)
    80002baa:	02f4f863          	bgeu	s1,a5,80002bda <fetchaddr+0x4a>
    80002bae:	00848713          	addi	a4,s1,8
    80002bb2:	02e7e663          	bltu	a5,a4,80002bde <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bb6:	46a1                	li	a3,8
    80002bb8:	8626                	mv	a2,s1
    80002bba:	85ca                	mv	a1,s2
    80002bbc:	6928                	ld	a0,80(a0)
    80002bbe:	fffff097          	auipc	ra,0xfffff
    80002bc2:	bf2080e7          	jalr	-1038(ra) # 800017b0 <copyin>
    80002bc6:	00a03533          	snez	a0,a0
    80002bca:	40a00533          	neg	a0,a0
}
    80002bce:	60e2                	ld	ra,24(sp)
    80002bd0:	6442                	ld	s0,16(sp)
    80002bd2:	64a2                	ld	s1,8(sp)
    80002bd4:	6902                	ld	s2,0(sp)
    80002bd6:	6105                	addi	sp,sp,32
    80002bd8:	8082                	ret
    return -1;
    80002bda:	557d                	li	a0,-1
    80002bdc:	bfcd                	j	80002bce <fetchaddr+0x3e>
    80002bde:	557d                	li	a0,-1
    80002be0:	b7fd                	j	80002bce <fetchaddr+0x3e>

0000000080002be2 <fetchstr>:
{
    80002be2:	7179                	addi	sp,sp,-48
    80002be4:	f406                	sd	ra,40(sp)
    80002be6:	f022                	sd	s0,32(sp)
    80002be8:	ec26                	sd	s1,24(sp)
    80002bea:	e84a                	sd	s2,16(sp)
    80002bec:	e44e                	sd	s3,8(sp)
    80002bee:	1800                	addi	s0,sp,48
    80002bf0:	892a                	mv	s2,a0
    80002bf2:	84ae                	mv	s1,a1
    80002bf4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bf6:	fffff097          	auipc	ra,0xfffff
    80002bfa:	f1a080e7          	jalr	-230(ra) # 80001b10 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002bfe:	86ce                	mv	a3,s3
    80002c00:	864a                	mv	a2,s2
    80002c02:	85a6                	mv	a1,s1
    80002c04:	6928                	ld	a0,80(a0)
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	c36080e7          	jalr	-970(ra) # 8000183c <copyinstr>
  if(err < 0)
    80002c0e:	00054763          	bltz	a0,80002c1c <fetchstr+0x3a>
  return strlen(buf);
    80002c12:	8526                	mv	a0,s1
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	2ca080e7          	jalr	714(ra) # 80000ede <strlen>
}
    80002c1c:	70a2                	ld	ra,40(sp)
    80002c1e:	7402                	ld	s0,32(sp)
    80002c20:	64e2                	ld	s1,24(sp)
    80002c22:	6942                	ld	s2,16(sp)
    80002c24:	69a2                	ld	s3,8(sp)
    80002c26:	6145                	addi	sp,sp,48
    80002c28:	8082                	ret

0000000080002c2a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c2a:	1101                	addi	sp,sp,-32
    80002c2c:	ec06                	sd	ra,24(sp)
    80002c2e:	e822                	sd	s0,16(sp)
    80002c30:	e426                	sd	s1,8(sp)
    80002c32:	1000                	addi	s0,sp,32
    80002c34:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c36:	00000097          	auipc	ra,0x0
    80002c3a:	ef2080e7          	jalr	-270(ra) # 80002b28 <argraw>
    80002c3e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c40:	4501                	li	a0,0
    80002c42:	60e2                	ld	ra,24(sp)
    80002c44:	6442                	ld	s0,16(sp)
    80002c46:	64a2                	ld	s1,8(sp)
    80002c48:	6105                	addi	sp,sp,32
    80002c4a:	8082                	ret

0000000080002c4c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c4c:	1101                	addi	sp,sp,-32
    80002c4e:	ec06                	sd	ra,24(sp)
    80002c50:	e822                	sd	s0,16(sp)
    80002c52:	e426                	sd	s1,8(sp)
    80002c54:	1000                	addi	s0,sp,32
    80002c56:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c58:	00000097          	auipc	ra,0x0
    80002c5c:	ed0080e7          	jalr	-304(ra) # 80002b28 <argraw>
    80002c60:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c62:	4501                	li	a0,0
    80002c64:	60e2                	ld	ra,24(sp)
    80002c66:	6442                	ld	s0,16(sp)
    80002c68:	64a2                	ld	s1,8(sp)
    80002c6a:	6105                	addi	sp,sp,32
    80002c6c:	8082                	ret

0000000080002c6e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c6e:	1101                	addi	sp,sp,-32
    80002c70:	ec06                	sd	ra,24(sp)
    80002c72:	e822                	sd	s0,16(sp)
    80002c74:	e426                	sd	s1,8(sp)
    80002c76:	e04a                	sd	s2,0(sp)
    80002c78:	1000                	addi	s0,sp,32
    80002c7a:	84ae                	mv	s1,a1
    80002c7c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	eaa080e7          	jalr	-342(ra) # 80002b28 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c86:	864a                	mv	a2,s2
    80002c88:	85a6                	mv	a1,s1
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	f58080e7          	jalr	-168(ra) # 80002be2 <fetchstr>
}
    80002c92:	60e2                	ld	ra,24(sp)
    80002c94:	6442                	ld	s0,16(sp)
    80002c96:	64a2                	ld	s1,8(sp)
    80002c98:	6902                	ld	s2,0(sp)
    80002c9a:	6105                	addi	sp,sp,32
    80002c9c:	8082                	ret

0000000080002c9e <syscall>:
    "sysinfo",
};

void
syscall(void)
{
    80002c9e:	7179                	addi	sp,sp,-48
    80002ca0:	f406                	sd	ra,40(sp)
    80002ca2:	f022                	sd	s0,32(sp)
    80002ca4:	ec26                	sd	s1,24(sp)
    80002ca6:	e84a                	sd	s2,16(sp)
    80002ca8:	e44e                	sd	s3,8(sp)
    80002caa:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002cac:	fffff097          	auipc	ra,0xfffff
    80002cb0:	e64080e7          	jalr	-412(ra) # 80001b10 <myproc>
    80002cb4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cb6:	05853903          	ld	s2,88(a0)
    80002cba:	0a893783          	ld	a5,168(s2)
    80002cbe:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cc2:	37fd                	addiw	a5,a5,-1
    80002cc4:	4759                	li	a4,22
    80002cc6:	04f76963          	bltu	a4,a5,80002d18 <syscall+0x7a>
    80002cca:	00399713          	slli	a4,s3,0x3
    80002cce:	00006797          	auipc	a5,0x6
    80002cd2:	8b278793          	addi	a5,a5,-1870 # 80008580 <syscalls>
    80002cd6:	97ba                	add	a5,a5,a4
    80002cd8:	639c                	ld	a5,0(a5)
    80002cda:	cf9d                	beqz	a5,80002d18 <syscall+0x7a>
    p->trapframe->a0 = syscalls[num]();
    80002cdc:	9782                	jalr	a5
    80002cde:	06a93823          	sd	a0,112(s2)
    if (p->tracemask & (1 << num)) {
    80002ce2:	4785                	li	a5,1
    80002ce4:	013797bb          	sllw	a5,a5,s3
    80002ce8:	1684b703          	ld	a4,360(s1)
    80002cec:	8ff9                	and	a5,a5,a4
    80002cee:	c7a1                	beqz	a5,80002d36 <syscall+0x98>
      // this process traces this sys call num
      printf("%d: syscall %s -> %d\n", p->pid, sysnames[num], p->trapframe->a0);
    80002cf0:	6cb8                	ld	a4,88(s1)
    80002cf2:	098e                	slli	s3,s3,0x3
    80002cf4:	00006797          	auipc	a5,0x6
    80002cf8:	88c78793          	addi	a5,a5,-1908 # 80008580 <syscalls>
    80002cfc:	99be                	add	s3,s3,a5
    80002cfe:	7b34                	ld	a3,112(a4)
    80002d00:	0c09b603          	ld	a2,192(s3)
    80002d04:	5c8c                	lw	a1,56(s1)
    80002d06:	00005517          	auipc	a0,0x5
    80002d0a:	77a50513          	addi	a0,a0,1914 # 80008480 <states.1717+0x148>
    80002d0e:	ffffe097          	auipc	ra,0xffffe
    80002d12:	884080e7          	jalr	-1916(ra) # 80000592 <printf>
    80002d16:	a005                	j	80002d36 <syscall+0x98>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d18:	86ce                	mv	a3,s3
    80002d1a:	15848613          	addi	a2,s1,344
    80002d1e:	5c8c                	lw	a1,56(s1)
    80002d20:	00005517          	auipc	a0,0x5
    80002d24:	77850513          	addi	a0,a0,1912 # 80008498 <states.1717+0x160>
    80002d28:	ffffe097          	auipc	ra,0xffffe
    80002d2c:	86a080e7          	jalr	-1942(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d30:	6cbc                	ld	a5,88(s1)
    80002d32:	577d                	li	a4,-1
    80002d34:	fbb8                	sd	a4,112(a5)
  }
}
    80002d36:	70a2                	ld	ra,40(sp)
    80002d38:	7402                	ld	s0,32(sp)
    80002d3a:	64e2                	ld	s1,24(sp)
    80002d3c:	6942                	ld	s2,16(sp)
    80002d3e:	69a2                	ld	s3,8(sp)
    80002d40:	6145                	addi	sp,sp,48
    80002d42:	8082                	ret

0000000080002d44 <sys_exit>:
#include "sysinfo.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d44:	1101                	addi	sp,sp,-32
    80002d46:	ec06                	sd	ra,24(sp)
    80002d48:	e822                	sd	s0,16(sp)
    80002d4a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d4c:	fec40593          	addi	a1,s0,-20
    80002d50:	4501                	li	a0,0
    80002d52:	00000097          	auipc	ra,0x0
    80002d56:	ed8080e7          	jalr	-296(ra) # 80002c2a <argint>
    return -1;
    80002d5a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d5c:	00054963          	bltz	a0,80002d6e <sys_exit+0x2a>
  exit(n);
    80002d60:	fec42503          	lw	a0,-20(s0)
    80002d64:	fffff097          	auipc	ra,0xfffff
    80002d68:	47e080e7          	jalr	1150(ra) # 800021e2 <exit>
  return 0;  // not reached
    80002d6c:	4781                	li	a5,0
}
    80002d6e:	853e                	mv	a0,a5
    80002d70:	60e2                	ld	ra,24(sp)
    80002d72:	6442                	ld	s0,16(sp)
    80002d74:	6105                	addi	sp,sp,32
    80002d76:	8082                	ret

0000000080002d78 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d78:	1141                	addi	sp,sp,-16
    80002d7a:	e406                	sd	ra,8(sp)
    80002d7c:	e022                	sd	s0,0(sp)
    80002d7e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d80:	fffff097          	auipc	ra,0xfffff
    80002d84:	d90080e7          	jalr	-624(ra) # 80001b10 <myproc>
}
    80002d88:	5d08                	lw	a0,56(a0)
    80002d8a:	60a2                	ld	ra,8(sp)
    80002d8c:	6402                	ld	s0,0(sp)
    80002d8e:	0141                	addi	sp,sp,16
    80002d90:	8082                	ret

0000000080002d92 <sys_fork>:

uint64
sys_fork(void)
{
    80002d92:	1141                	addi	sp,sp,-16
    80002d94:	e406                	sd	ra,8(sp)
    80002d96:	e022                	sd	s0,0(sp)
    80002d98:	0800                	addi	s0,sp,16
  return fork();
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	13a080e7          	jalr	314(ra) # 80001ed4 <fork>
}
    80002da2:	60a2                	ld	ra,8(sp)
    80002da4:	6402                	ld	s0,0(sp)
    80002da6:	0141                	addi	sp,sp,16
    80002da8:	8082                	ret

0000000080002daa <sys_wait>:

uint64
sys_wait(void)
{
    80002daa:	1101                	addi	sp,sp,-32
    80002dac:	ec06                	sd	ra,24(sp)
    80002dae:	e822                	sd	s0,16(sp)
    80002db0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002db2:	fe840593          	addi	a1,s0,-24
    80002db6:	4501                	li	a0,0
    80002db8:	00000097          	auipc	ra,0x0
    80002dbc:	e94080e7          	jalr	-364(ra) # 80002c4c <argaddr>
    80002dc0:	87aa                	mv	a5,a0
    return -1;
    80002dc2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002dc4:	0007c863          	bltz	a5,80002dd4 <sys_wait+0x2a>
  return wait(p);
    80002dc8:	fe843503          	ld	a0,-24(s0)
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	5da080e7          	jalr	1498(ra) # 800023a6 <wait>
}
    80002dd4:	60e2                	ld	ra,24(sp)
    80002dd6:	6442                	ld	s0,16(sp)
    80002dd8:	6105                	addi	sp,sp,32
    80002dda:	8082                	ret

0000000080002ddc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ddc:	7179                	addi	sp,sp,-48
    80002dde:	f406                	sd	ra,40(sp)
    80002de0:	f022                	sd	s0,32(sp)
    80002de2:	ec26                	sd	s1,24(sp)
    80002de4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002de6:	fdc40593          	addi	a1,s0,-36
    80002dea:	4501                	li	a0,0
    80002dec:	00000097          	auipc	ra,0x0
    80002df0:	e3e080e7          	jalr	-450(ra) # 80002c2a <argint>
    80002df4:	87aa                	mv	a5,a0
    return -1;
    80002df6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002df8:	0207c063          	bltz	a5,80002e18 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	d14080e7          	jalr	-748(ra) # 80001b10 <myproc>
    80002e04:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e06:	fdc42503          	lw	a0,-36(s0)
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	056080e7          	jalr	86(ra) # 80001e60 <growproc>
    80002e12:	00054863          	bltz	a0,80002e22 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e16:	8526                	mv	a0,s1
}
    80002e18:	70a2                	ld	ra,40(sp)
    80002e1a:	7402                	ld	s0,32(sp)
    80002e1c:	64e2                	ld	s1,24(sp)
    80002e1e:	6145                	addi	sp,sp,48
    80002e20:	8082                	ret
    return -1;
    80002e22:	557d                	li	a0,-1
    80002e24:	bfd5                	j	80002e18 <sys_sbrk+0x3c>

0000000080002e26 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e26:	7139                	addi	sp,sp,-64
    80002e28:	fc06                	sd	ra,56(sp)
    80002e2a:	f822                	sd	s0,48(sp)
    80002e2c:	f426                	sd	s1,40(sp)
    80002e2e:	f04a                	sd	s2,32(sp)
    80002e30:	ec4e                	sd	s3,24(sp)
    80002e32:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e34:	fcc40593          	addi	a1,s0,-52
    80002e38:	4501                	li	a0,0
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	df0080e7          	jalr	-528(ra) # 80002c2a <argint>
    return -1;
    80002e42:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e44:	06054563          	bltz	a0,80002eae <sys_sleep+0x88>
  acquire(&tickslock);
    80002e48:	00015517          	auipc	a0,0x15
    80002e4c:	b2050513          	addi	a0,a0,-1248 # 80017968 <tickslock>
    80002e50:	ffffe097          	auipc	ra,0xffffe
    80002e54:	e0a080e7          	jalr	-502(ra) # 80000c5a <acquire>
  ticks0 = ticks;
    80002e58:	00006917          	auipc	s2,0x6
    80002e5c:	1c892903          	lw	s2,456(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002e60:	fcc42783          	lw	a5,-52(s0)
    80002e64:	cf85                	beqz	a5,80002e9c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e66:	00015997          	auipc	s3,0x15
    80002e6a:	b0298993          	addi	s3,s3,-1278 # 80017968 <tickslock>
    80002e6e:	00006497          	auipc	s1,0x6
    80002e72:	1b248493          	addi	s1,s1,434 # 80009020 <ticks>
    if(myproc()->killed){
    80002e76:	fffff097          	auipc	ra,0xfffff
    80002e7a:	c9a080e7          	jalr	-870(ra) # 80001b10 <myproc>
    80002e7e:	591c                	lw	a5,48(a0)
    80002e80:	ef9d                	bnez	a5,80002ebe <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e82:	85ce                	mv	a1,s3
    80002e84:	8526                	mv	a0,s1
    80002e86:	fffff097          	auipc	ra,0xfffff
    80002e8a:	4a2080e7          	jalr	1186(ra) # 80002328 <sleep>
  while(ticks - ticks0 < n){
    80002e8e:	409c                	lw	a5,0(s1)
    80002e90:	412787bb          	subw	a5,a5,s2
    80002e94:	fcc42703          	lw	a4,-52(s0)
    80002e98:	fce7efe3          	bltu	a5,a4,80002e76 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e9c:	00015517          	auipc	a0,0x15
    80002ea0:	acc50513          	addi	a0,a0,-1332 # 80017968 <tickslock>
    80002ea4:	ffffe097          	auipc	ra,0xffffe
    80002ea8:	e6a080e7          	jalr	-406(ra) # 80000d0e <release>
  return 0;
    80002eac:	4781                	li	a5,0
}
    80002eae:	853e                	mv	a0,a5
    80002eb0:	70e2                	ld	ra,56(sp)
    80002eb2:	7442                	ld	s0,48(sp)
    80002eb4:	74a2                	ld	s1,40(sp)
    80002eb6:	7902                	ld	s2,32(sp)
    80002eb8:	69e2                	ld	s3,24(sp)
    80002eba:	6121                	addi	sp,sp,64
    80002ebc:	8082                	ret
      release(&tickslock);
    80002ebe:	00015517          	auipc	a0,0x15
    80002ec2:	aaa50513          	addi	a0,a0,-1366 # 80017968 <tickslock>
    80002ec6:	ffffe097          	auipc	ra,0xffffe
    80002eca:	e48080e7          	jalr	-440(ra) # 80000d0e <release>
      return -1;
    80002ece:	57fd                	li	a5,-1
    80002ed0:	bff9                	j	80002eae <sys_sleep+0x88>

0000000080002ed2 <sys_kill>:

uint64
sys_kill(void)
{
    80002ed2:	1101                	addi	sp,sp,-32
    80002ed4:	ec06                	sd	ra,24(sp)
    80002ed6:	e822                	sd	s0,16(sp)
    80002ed8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002eda:	fec40593          	addi	a1,s0,-20
    80002ede:	4501                	li	a0,0
    80002ee0:	00000097          	auipc	ra,0x0
    80002ee4:	d4a080e7          	jalr	-694(ra) # 80002c2a <argint>
    80002ee8:	87aa                	mv	a5,a0
    return -1;
    80002eea:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002eec:	0007c863          	bltz	a5,80002efc <sys_kill+0x2a>
  return kill(pid);
    80002ef0:	fec42503          	lw	a0,-20(s0)
    80002ef4:	fffff097          	auipc	ra,0xfffff
    80002ef8:	624080e7          	jalr	1572(ra) # 80002518 <kill>
}
    80002efc:	60e2                	ld	ra,24(sp)
    80002efe:	6442                	ld	s0,16(sp)
    80002f00:	6105                	addi	sp,sp,32
    80002f02:	8082                	ret

0000000080002f04 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f04:	1101                	addi	sp,sp,-32
    80002f06:	ec06                	sd	ra,24(sp)
    80002f08:	e822                	sd	s0,16(sp)
    80002f0a:	e426                	sd	s1,8(sp)
    80002f0c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f0e:	00015517          	auipc	a0,0x15
    80002f12:	a5a50513          	addi	a0,a0,-1446 # 80017968 <tickslock>
    80002f16:	ffffe097          	auipc	ra,0xffffe
    80002f1a:	d44080e7          	jalr	-700(ra) # 80000c5a <acquire>
  xticks = ticks;
    80002f1e:	00006497          	auipc	s1,0x6
    80002f22:	1024a483          	lw	s1,258(s1) # 80009020 <ticks>
  release(&tickslock);
    80002f26:	00015517          	auipc	a0,0x15
    80002f2a:	a4250513          	addi	a0,a0,-1470 # 80017968 <tickslock>
    80002f2e:	ffffe097          	auipc	ra,0xffffe
    80002f32:	de0080e7          	jalr	-544(ra) # 80000d0e <release>
  return xticks;
}
    80002f36:	02049513          	slli	a0,s1,0x20
    80002f3a:	9101                	srli	a0,a0,0x20
    80002f3c:	60e2                	ld	ra,24(sp)
    80002f3e:	6442                	ld	s0,16(sp)
    80002f40:	64a2                	ld	s1,8(sp)
    80002f42:	6105                	addi	sp,sp,32
    80002f44:	8082                	ret

0000000080002f46 <sys_trace>:

// click the sys call number in p->tracemask
// so as to tracing its calling afterwards
uint64
sys_trace(void) {
    80002f46:	1101                	addi	sp,sp,-32
    80002f48:	ec06                	sd	ra,24(sp)
    80002f4a:	e822                	sd	s0,16(sp)
    80002f4c:	1000                	addi	s0,sp,32
  int trace_sys_mask;
  if (argint(0, &trace_sys_mask) < 0)
    80002f4e:	fec40593          	addi	a1,s0,-20
    80002f52:	4501                	li	a0,0
    80002f54:	00000097          	auipc	ra,0x0
    80002f58:	cd6080e7          	jalr	-810(ra) # 80002c2a <argint>
    return -1;
    80002f5c:	57fd                	li	a5,-1
  if (argint(0, &trace_sys_mask) < 0)
    80002f5e:	00054e63          	bltz	a0,80002f7a <sys_trace+0x34>
  myproc()->tracemask |= trace_sys_mask;
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	bae080e7          	jalr	-1106(ra) # 80001b10 <myproc>
    80002f6a:	fec42703          	lw	a4,-20(s0)
    80002f6e:	16853783          	ld	a5,360(a0)
    80002f72:	8fd9                	or	a5,a5,a4
    80002f74:	16f53423          	sd	a5,360(a0)
  return 0;
    80002f78:	4781                	li	a5,0
}
    80002f7a:	853e                	mv	a0,a5
    80002f7c:	60e2                	ld	ra,24(sp)
    80002f7e:	6442                	ld	s0,16(sp)
    80002f80:	6105                	addi	sp,sp,32
    80002f82:	8082                	ret

0000000080002f84 <sys_sysinfo>:

// collect system info
uint64
sys_sysinfo(void) {
    80002f84:	7139                	addi	sp,sp,-64
    80002f86:	fc06                	sd	ra,56(sp)
    80002f88:	f822                	sd	s0,48(sp)
    80002f8a:	f426                	sd	s1,40(sp)
    80002f8c:	0080                	addi	s0,sp,64
  struct proc *my_proc = myproc();
    80002f8e:	fffff097          	auipc	ra,0xfffff
    80002f92:	b82080e7          	jalr	-1150(ra) # 80001b10 <myproc>
    80002f96:	84aa                	mv	s1,a0
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f98:	fd840593          	addi	a1,s0,-40
    80002f9c:	4501                	li	a0,0
    80002f9e:	00000097          	auipc	ra,0x0
    80002fa2:	cae080e7          	jalr	-850(ra) # 80002c4c <argaddr>
    return -1;
    80002fa6:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    80002fa8:	02054a63          	bltz	a0,80002fdc <sys_sysinfo+0x58>
  // construct in kernel first
  struct sysinfo s;
  s.freemem = kfreemem();
    80002fac:	ffffe097          	auipc	ra,0xffffe
    80002fb0:	bd4080e7          	jalr	-1068(ra) # 80000b80 <kfreemem>
    80002fb4:	fca43423          	sd	a0,-56(s0)
  s.nproc = count_free_proc();
    80002fb8:	fffff097          	auipc	ra,0xfffff
    80002fbc:	72c080e7          	jalr	1836(ra) # 800026e4 <count_free_proc>
    80002fc0:	fca43823          	sd	a0,-48(s0)
  // copy to user space
  if(copyout(my_proc->pagetable, p, (char *)&s, sizeof(s)) < 0)
    80002fc4:	46c1                	li	a3,16
    80002fc6:	fc840613          	addi	a2,s0,-56
    80002fca:	fd843583          	ld	a1,-40(s0)
    80002fce:	68a8                	ld	a0,80(s1)
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	754080e7          	jalr	1876(ra) # 80001724 <copyout>
    80002fd8:	43f55793          	srai	a5,a0,0x3f
    return -1;
  return 0;
}
    80002fdc:	853e                	mv	a0,a5
    80002fde:	70e2                	ld	ra,56(sp)
    80002fe0:	7442                	ld	s0,48(sp)
    80002fe2:	74a2                	ld	s1,40(sp)
    80002fe4:	6121                	addi	sp,sp,64
    80002fe6:	8082                	ret

0000000080002fe8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fe8:	7179                	addi	sp,sp,-48
    80002fea:	f406                	sd	ra,40(sp)
    80002fec:	f022                	sd	s0,32(sp)
    80002fee:	ec26                	sd	s1,24(sp)
    80002ff0:	e84a                	sd	s2,16(sp)
    80002ff2:	e44e                	sd	s3,8(sp)
    80002ff4:	e052                	sd	s4,0(sp)
    80002ff6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ff8:	00005597          	auipc	a1,0x5
    80002ffc:	70858593          	addi	a1,a1,1800 # 80008700 <sysnames+0xc0>
    80003000:	00015517          	auipc	a0,0x15
    80003004:	98050513          	addi	a0,a0,-1664 # 80017980 <bcache>
    80003008:	ffffe097          	auipc	ra,0xffffe
    8000300c:	bc2080e7          	jalr	-1086(ra) # 80000bca <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003010:	0001d797          	auipc	a5,0x1d
    80003014:	97078793          	addi	a5,a5,-1680 # 8001f980 <bcache+0x8000>
    80003018:	0001d717          	auipc	a4,0x1d
    8000301c:	bd070713          	addi	a4,a4,-1072 # 8001fbe8 <bcache+0x8268>
    80003020:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003024:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003028:	00015497          	auipc	s1,0x15
    8000302c:	97048493          	addi	s1,s1,-1680 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80003030:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003032:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003034:	00005a17          	auipc	s4,0x5
    80003038:	6d4a0a13          	addi	s4,s4,1748 # 80008708 <sysnames+0xc8>
    b->next = bcache.head.next;
    8000303c:	2b893783          	ld	a5,696(s2)
    80003040:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003042:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003046:	85d2                	mv	a1,s4
    80003048:	01048513          	addi	a0,s1,16
    8000304c:	00001097          	auipc	ra,0x1
    80003050:	4ac080e7          	jalr	1196(ra) # 800044f8 <initsleeplock>
    bcache.head.next->prev = b;
    80003054:	2b893783          	ld	a5,696(s2)
    80003058:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000305a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000305e:	45848493          	addi	s1,s1,1112
    80003062:	fd349de3          	bne	s1,s3,8000303c <binit+0x54>
  }
}
    80003066:	70a2                	ld	ra,40(sp)
    80003068:	7402                	ld	s0,32(sp)
    8000306a:	64e2                	ld	s1,24(sp)
    8000306c:	6942                	ld	s2,16(sp)
    8000306e:	69a2                	ld	s3,8(sp)
    80003070:	6a02                	ld	s4,0(sp)
    80003072:	6145                	addi	sp,sp,48
    80003074:	8082                	ret

0000000080003076 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003076:	7179                	addi	sp,sp,-48
    80003078:	f406                	sd	ra,40(sp)
    8000307a:	f022                	sd	s0,32(sp)
    8000307c:	ec26                	sd	s1,24(sp)
    8000307e:	e84a                	sd	s2,16(sp)
    80003080:	e44e                	sd	s3,8(sp)
    80003082:	1800                	addi	s0,sp,48
    80003084:	89aa                	mv	s3,a0
    80003086:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003088:	00015517          	auipc	a0,0x15
    8000308c:	8f850513          	addi	a0,a0,-1800 # 80017980 <bcache>
    80003090:	ffffe097          	auipc	ra,0xffffe
    80003094:	bca080e7          	jalr	-1078(ra) # 80000c5a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003098:	0001d497          	auipc	s1,0x1d
    8000309c:	ba04b483          	ld	s1,-1120(s1) # 8001fc38 <bcache+0x82b8>
    800030a0:	0001d797          	auipc	a5,0x1d
    800030a4:	b4878793          	addi	a5,a5,-1208 # 8001fbe8 <bcache+0x8268>
    800030a8:	02f48f63          	beq	s1,a5,800030e6 <bread+0x70>
    800030ac:	873e                	mv	a4,a5
    800030ae:	a021                	j	800030b6 <bread+0x40>
    800030b0:	68a4                	ld	s1,80(s1)
    800030b2:	02e48a63          	beq	s1,a4,800030e6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030b6:	449c                	lw	a5,8(s1)
    800030b8:	ff379ce3          	bne	a5,s3,800030b0 <bread+0x3a>
    800030bc:	44dc                	lw	a5,12(s1)
    800030be:	ff2799e3          	bne	a5,s2,800030b0 <bread+0x3a>
      b->refcnt++;
    800030c2:	40bc                	lw	a5,64(s1)
    800030c4:	2785                	addiw	a5,a5,1
    800030c6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030c8:	00015517          	auipc	a0,0x15
    800030cc:	8b850513          	addi	a0,a0,-1864 # 80017980 <bcache>
    800030d0:	ffffe097          	auipc	ra,0xffffe
    800030d4:	c3e080e7          	jalr	-962(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    800030d8:	01048513          	addi	a0,s1,16
    800030dc:	00001097          	auipc	ra,0x1
    800030e0:	456080e7          	jalr	1110(ra) # 80004532 <acquiresleep>
      return b;
    800030e4:	a8b9                	j	80003142 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030e6:	0001d497          	auipc	s1,0x1d
    800030ea:	b4a4b483          	ld	s1,-1206(s1) # 8001fc30 <bcache+0x82b0>
    800030ee:	0001d797          	auipc	a5,0x1d
    800030f2:	afa78793          	addi	a5,a5,-1286 # 8001fbe8 <bcache+0x8268>
    800030f6:	00f48863          	beq	s1,a5,80003106 <bread+0x90>
    800030fa:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030fc:	40bc                	lw	a5,64(s1)
    800030fe:	cf81                	beqz	a5,80003116 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003100:	64a4                	ld	s1,72(s1)
    80003102:	fee49de3          	bne	s1,a4,800030fc <bread+0x86>
  panic("bget: no buffers");
    80003106:	00005517          	auipc	a0,0x5
    8000310a:	60a50513          	addi	a0,a0,1546 # 80008710 <sysnames+0xd0>
    8000310e:	ffffd097          	auipc	ra,0xffffd
    80003112:	43a080e7          	jalr	1082(ra) # 80000548 <panic>
      b->dev = dev;
    80003116:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000311a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000311e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003122:	4785                	li	a5,1
    80003124:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003126:	00015517          	auipc	a0,0x15
    8000312a:	85a50513          	addi	a0,a0,-1958 # 80017980 <bcache>
    8000312e:	ffffe097          	auipc	ra,0xffffe
    80003132:	be0080e7          	jalr	-1056(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    80003136:	01048513          	addi	a0,s1,16
    8000313a:	00001097          	auipc	ra,0x1
    8000313e:	3f8080e7          	jalr	1016(ra) # 80004532 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003142:	409c                	lw	a5,0(s1)
    80003144:	cb89                	beqz	a5,80003156 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003146:	8526                	mv	a0,s1
    80003148:	70a2                	ld	ra,40(sp)
    8000314a:	7402                	ld	s0,32(sp)
    8000314c:	64e2                	ld	s1,24(sp)
    8000314e:	6942                	ld	s2,16(sp)
    80003150:	69a2                	ld	s3,8(sp)
    80003152:	6145                	addi	sp,sp,48
    80003154:	8082                	ret
    virtio_disk_rw(b, 0);
    80003156:	4581                	li	a1,0
    80003158:	8526                	mv	a0,s1
    8000315a:	00003097          	auipc	ra,0x3
    8000315e:	f52080e7          	jalr	-174(ra) # 800060ac <virtio_disk_rw>
    b->valid = 1;
    80003162:	4785                	li	a5,1
    80003164:	c09c                	sw	a5,0(s1)
  return b;
    80003166:	b7c5                	j	80003146 <bread+0xd0>

0000000080003168 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003168:	1101                	addi	sp,sp,-32
    8000316a:	ec06                	sd	ra,24(sp)
    8000316c:	e822                	sd	s0,16(sp)
    8000316e:	e426                	sd	s1,8(sp)
    80003170:	1000                	addi	s0,sp,32
    80003172:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003174:	0541                	addi	a0,a0,16
    80003176:	00001097          	auipc	ra,0x1
    8000317a:	456080e7          	jalr	1110(ra) # 800045cc <holdingsleep>
    8000317e:	cd01                	beqz	a0,80003196 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003180:	4585                	li	a1,1
    80003182:	8526                	mv	a0,s1
    80003184:	00003097          	auipc	ra,0x3
    80003188:	f28080e7          	jalr	-216(ra) # 800060ac <virtio_disk_rw>
}
    8000318c:	60e2                	ld	ra,24(sp)
    8000318e:	6442                	ld	s0,16(sp)
    80003190:	64a2                	ld	s1,8(sp)
    80003192:	6105                	addi	sp,sp,32
    80003194:	8082                	ret
    panic("bwrite");
    80003196:	00005517          	auipc	a0,0x5
    8000319a:	59250513          	addi	a0,a0,1426 # 80008728 <sysnames+0xe8>
    8000319e:	ffffd097          	auipc	ra,0xffffd
    800031a2:	3aa080e7          	jalr	938(ra) # 80000548 <panic>

00000000800031a6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031a6:	1101                	addi	sp,sp,-32
    800031a8:	ec06                	sd	ra,24(sp)
    800031aa:	e822                	sd	s0,16(sp)
    800031ac:	e426                	sd	s1,8(sp)
    800031ae:	e04a                	sd	s2,0(sp)
    800031b0:	1000                	addi	s0,sp,32
    800031b2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031b4:	01050913          	addi	s2,a0,16
    800031b8:	854a                	mv	a0,s2
    800031ba:	00001097          	auipc	ra,0x1
    800031be:	412080e7          	jalr	1042(ra) # 800045cc <holdingsleep>
    800031c2:	c92d                	beqz	a0,80003234 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031c4:	854a                	mv	a0,s2
    800031c6:	00001097          	auipc	ra,0x1
    800031ca:	3c2080e7          	jalr	962(ra) # 80004588 <releasesleep>

  acquire(&bcache.lock);
    800031ce:	00014517          	auipc	a0,0x14
    800031d2:	7b250513          	addi	a0,a0,1970 # 80017980 <bcache>
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	a84080e7          	jalr	-1404(ra) # 80000c5a <acquire>
  b->refcnt--;
    800031de:	40bc                	lw	a5,64(s1)
    800031e0:	37fd                	addiw	a5,a5,-1
    800031e2:	0007871b          	sext.w	a4,a5
    800031e6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031e8:	eb05                	bnez	a4,80003218 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031ea:	68bc                	ld	a5,80(s1)
    800031ec:	64b8                	ld	a4,72(s1)
    800031ee:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031f0:	64bc                	ld	a5,72(s1)
    800031f2:	68b8                	ld	a4,80(s1)
    800031f4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031f6:	0001c797          	auipc	a5,0x1c
    800031fa:	78a78793          	addi	a5,a5,1930 # 8001f980 <bcache+0x8000>
    800031fe:	2b87b703          	ld	a4,696(a5)
    80003202:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003204:	0001d717          	auipc	a4,0x1d
    80003208:	9e470713          	addi	a4,a4,-1564 # 8001fbe8 <bcache+0x8268>
    8000320c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000320e:	2b87b703          	ld	a4,696(a5)
    80003212:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003214:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003218:	00014517          	auipc	a0,0x14
    8000321c:	76850513          	addi	a0,a0,1896 # 80017980 <bcache>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	aee080e7          	jalr	-1298(ra) # 80000d0e <release>
}
    80003228:	60e2                	ld	ra,24(sp)
    8000322a:	6442                	ld	s0,16(sp)
    8000322c:	64a2                	ld	s1,8(sp)
    8000322e:	6902                	ld	s2,0(sp)
    80003230:	6105                	addi	sp,sp,32
    80003232:	8082                	ret
    panic("brelse");
    80003234:	00005517          	auipc	a0,0x5
    80003238:	4fc50513          	addi	a0,a0,1276 # 80008730 <sysnames+0xf0>
    8000323c:	ffffd097          	auipc	ra,0xffffd
    80003240:	30c080e7          	jalr	780(ra) # 80000548 <panic>

0000000080003244 <bpin>:

void
bpin(struct buf *b) {
    80003244:	1101                	addi	sp,sp,-32
    80003246:	ec06                	sd	ra,24(sp)
    80003248:	e822                	sd	s0,16(sp)
    8000324a:	e426                	sd	s1,8(sp)
    8000324c:	1000                	addi	s0,sp,32
    8000324e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003250:	00014517          	auipc	a0,0x14
    80003254:	73050513          	addi	a0,a0,1840 # 80017980 <bcache>
    80003258:	ffffe097          	auipc	ra,0xffffe
    8000325c:	a02080e7          	jalr	-1534(ra) # 80000c5a <acquire>
  b->refcnt++;
    80003260:	40bc                	lw	a5,64(s1)
    80003262:	2785                	addiw	a5,a5,1
    80003264:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003266:	00014517          	auipc	a0,0x14
    8000326a:	71a50513          	addi	a0,a0,1818 # 80017980 <bcache>
    8000326e:	ffffe097          	auipc	ra,0xffffe
    80003272:	aa0080e7          	jalr	-1376(ra) # 80000d0e <release>
}
    80003276:	60e2                	ld	ra,24(sp)
    80003278:	6442                	ld	s0,16(sp)
    8000327a:	64a2                	ld	s1,8(sp)
    8000327c:	6105                	addi	sp,sp,32
    8000327e:	8082                	ret

0000000080003280 <bunpin>:

void
bunpin(struct buf *b) {
    80003280:	1101                	addi	sp,sp,-32
    80003282:	ec06                	sd	ra,24(sp)
    80003284:	e822                	sd	s0,16(sp)
    80003286:	e426                	sd	s1,8(sp)
    80003288:	1000                	addi	s0,sp,32
    8000328a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000328c:	00014517          	auipc	a0,0x14
    80003290:	6f450513          	addi	a0,a0,1780 # 80017980 <bcache>
    80003294:	ffffe097          	auipc	ra,0xffffe
    80003298:	9c6080e7          	jalr	-1594(ra) # 80000c5a <acquire>
  b->refcnt--;
    8000329c:	40bc                	lw	a5,64(s1)
    8000329e:	37fd                	addiw	a5,a5,-1
    800032a0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032a2:	00014517          	auipc	a0,0x14
    800032a6:	6de50513          	addi	a0,a0,1758 # 80017980 <bcache>
    800032aa:	ffffe097          	auipc	ra,0xffffe
    800032ae:	a64080e7          	jalr	-1436(ra) # 80000d0e <release>
}
    800032b2:	60e2                	ld	ra,24(sp)
    800032b4:	6442                	ld	s0,16(sp)
    800032b6:	64a2                	ld	s1,8(sp)
    800032b8:	6105                	addi	sp,sp,32
    800032ba:	8082                	ret

00000000800032bc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032bc:	1101                	addi	sp,sp,-32
    800032be:	ec06                	sd	ra,24(sp)
    800032c0:	e822                	sd	s0,16(sp)
    800032c2:	e426                	sd	s1,8(sp)
    800032c4:	e04a                	sd	s2,0(sp)
    800032c6:	1000                	addi	s0,sp,32
    800032c8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032ca:	00d5d59b          	srliw	a1,a1,0xd
    800032ce:	0001d797          	auipc	a5,0x1d
    800032d2:	d8e7a783          	lw	a5,-626(a5) # 8002005c <sb+0x1c>
    800032d6:	9dbd                	addw	a1,a1,a5
    800032d8:	00000097          	auipc	ra,0x0
    800032dc:	d9e080e7          	jalr	-610(ra) # 80003076 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032e0:	0074f713          	andi	a4,s1,7
    800032e4:	4785                	li	a5,1
    800032e6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032ea:	14ce                	slli	s1,s1,0x33
    800032ec:	90d9                	srli	s1,s1,0x36
    800032ee:	00950733          	add	a4,a0,s1
    800032f2:	05874703          	lbu	a4,88(a4)
    800032f6:	00e7f6b3          	and	a3,a5,a4
    800032fa:	c69d                	beqz	a3,80003328 <bfree+0x6c>
    800032fc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032fe:	94aa                	add	s1,s1,a0
    80003300:	fff7c793          	not	a5,a5
    80003304:	8ff9                	and	a5,a5,a4
    80003306:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000330a:	00001097          	auipc	ra,0x1
    8000330e:	100080e7          	jalr	256(ra) # 8000440a <log_write>
  brelse(bp);
    80003312:	854a                	mv	a0,s2
    80003314:	00000097          	auipc	ra,0x0
    80003318:	e92080e7          	jalr	-366(ra) # 800031a6 <brelse>
}
    8000331c:	60e2                	ld	ra,24(sp)
    8000331e:	6442                	ld	s0,16(sp)
    80003320:	64a2                	ld	s1,8(sp)
    80003322:	6902                	ld	s2,0(sp)
    80003324:	6105                	addi	sp,sp,32
    80003326:	8082                	ret
    panic("freeing free block");
    80003328:	00005517          	auipc	a0,0x5
    8000332c:	41050513          	addi	a0,a0,1040 # 80008738 <sysnames+0xf8>
    80003330:	ffffd097          	auipc	ra,0xffffd
    80003334:	218080e7          	jalr	536(ra) # 80000548 <panic>

0000000080003338 <balloc>:
{
    80003338:	711d                	addi	sp,sp,-96
    8000333a:	ec86                	sd	ra,88(sp)
    8000333c:	e8a2                	sd	s0,80(sp)
    8000333e:	e4a6                	sd	s1,72(sp)
    80003340:	e0ca                	sd	s2,64(sp)
    80003342:	fc4e                	sd	s3,56(sp)
    80003344:	f852                	sd	s4,48(sp)
    80003346:	f456                	sd	s5,40(sp)
    80003348:	f05a                	sd	s6,32(sp)
    8000334a:	ec5e                	sd	s7,24(sp)
    8000334c:	e862                	sd	s8,16(sp)
    8000334e:	e466                	sd	s9,8(sp)
    80003350:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003352:	0001d797          	auipc	a5,0x1d
    80003356:	cf27a783          	lw	a5,-782(a5) # 80020044 <sb+0x4>
    8000335a:	cbd1                	beqz	a5,800033ee <balloc+0xb6>
    8000335c:	8baa                	mv	s7,a0
    8000335e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003360:	0001db17          	auipc	s6,0x1d
    80003364:	ce0b0b13          	addi	s6,s6,-800 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003368:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000336a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000336c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000336e:	6c89                	lui	s9,0x2
    80003370:	a831                	j	8000338c <balloc+0x54>
    brelse(bp);
    80003372:	854a                	mv	a0,s2
    80003374:	00000097          	auipc	ra,0x0
    80003378:	e32080e7          	jalr	-462(ra) # 800031a6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000337c:	015c87bb          	addw	a5,s9,s5
    80003380:	00078a9b          	sext.w	s5,a5
    80003384:	004b2703          	lw	a4,4(s6)
    80003388:	06eaf363          	bgeu	s5,a4,800033ee <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000338c:	41fad79b          	sraiw	a5,s5,0x1f
    80003390:	0137d79b          	srliw	a5,a5,0x13
    80003394:	015787bb          	addw	a5,a5,s5
    80003398:	40d7d79b          	sraiw	a5,a5,0xd
    8000339c:	01cb2583          	lw	a1,28(s6)
    800033a0:	9dbd                	addw	a1,a1,a5
    800033a2:	855e                	mv	a0,s7
    800033a4:	00000097          	auipc	ra,0x0
    800033a8:	cd2080e7          	jalr	-814(ra) # 80003076 <bread>
    800033ac:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ae:	004b2503          	lw	a0,4(s6)
    800033b2:	000a849b          	sext.w	s1,s5
    800033b6:	8662                	mv	a2,s8
    800033b8:	faa4fde3          	bgeu	s1,a0,80003372 <balloc+0x3a>
      m = 1 << (bi % 8);
    800033bc:	41f6579b          	sraiw	a5,a2,0x1f
    800033c0:	01d7d69b          	srliw	a3,a5,0x1d
    800033c4:	00c6873b          	addw	a4,a3,a2
    800033c8:	00777793          	andi	a5,a4,7
    800033cc:	9f95                	subw	a5,a5,a3
    800033ce:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033d2:	4037571b          	sraiw	a4,a4,0x3
    800033d6:	00e906b3          	add	a3,s2,a4
    800033da:	0586c683          	lbu	a3,88(a3)
    800033de:	00d7f5b3          	and	a1,a5,a3
    800033e2:	cd91                	beqz	a1,800033fe <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033e4:	2605                	addiw	a2,a2,1
    800033e6:	2485                	addiw	s1,s1,1
    800033e8:	fd4618e3          	bne	a2,s4,800033b8 <balloc+0x80>
    800033ec:	b759                	j	80003372 <balloc+0x3a>
  panic("balloc: out of blocks");
    800033ee:	00005517          	auipc	a0,0x5
    800033f2:	36250513          	addi	a0,a0,866 # 80008750 <sysnames+0x110>
    800033f6:	ffffd097          	auipc	ra,0xffffd
    800033fa:	152080e7          	jalr	338(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033fe:	974a                	add	a4,a4,s2
    80003400:	8fd5                	or	a5,a5,a3
    80003402:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003406:	854a                	mv	a0,s2
    80003408:	00001097          	auipc	ra,0x1
    8000340c:	002080e7          	jalr	2(ra) # 8000440a <log_write>
        brelse(bp);
    80003410:	854a                	mv	a0,s2
    80003412:	00000097          	auipc	ra,0x0
    80003416:	d94080e7          	jalr	-620(ra) # 800031a6 <brelse>
  bp = bread(dev, bno);
    8000341a:	85a6                	mv	a1,s1
    8000341c:	855e                	mv	a0,s7
    8000341e:	00000097          	auipc	ra,0x0
    80003422:	c58080e7          	jalr	-936(ra) # 80003076 <bread>
    80003426:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003428:	40000613          	li	a2,1024
    8000342c:	4581                	li	a1,0
    8000342e:	05850513          	addi	a0,a0,88
    80003432:	ffffe097          	auipc	ra,0xffffe
    80003436:	924080e7          	jalr	-1756(ra) # 80000d56 <memset>
  log_write(bp);
    8000343a:	854a                	mv	a0,s2
    8000343c:	00001097          	auipc	ra,0x1
    80003440:	fce080e7          	jalr	-50(ra) # 8000440a <log_write>
  brelse(bp);
    80003444:	854a                	mv	a0,s2
    80003446:	00000097          	auipc	ra,0x0
    8000344a:	d60080e7          	jalr	-672(ra) # 800031a6 <brelse>
}
    8000344e:	8526                	mv	a0,s1
    80003450:	60e6                	ld	ra,88(sp)
    80003452:	6446                	ld	s0,80(sp)
    80003454:	64a6                	ld	s1,72(sp)
    80003456:	6906                	ld	s2,64(sp)
    80003458:	79e2                	ld	s3,56(sp)
    8000345a:	7a42                	ld	s4,48(sp)
    8000345c:	7aa2                	ld	s5,40(sp)
    8000345e:	7b02                	ld	s6,32(sp)
    80003460:	6be2                	ld	s7,24(sp)
    80003462:	6c42                	ld	s8,16(sp)
    80003464:	6ca2                	ld	s9,8(sp)
    80003466:	6125                	addi	sp,sp,96
    80003468:	8082                	ret

000000008000346a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000346a:	7179                	addi	sp,sp,-48
    8000346c:	f406                	sd	ra,40(sp)
    8000346e:	f022                	sd	s0,32(sp)
    80003470:	ec26                	sd	s1,24(sp)
    80003472:	e84a                	sd	s2,16(sp)
    80003474:	e44e                	sd	s3,8(sp)
    80003476:	e052                	sd	s4,0(sp)
    80003478:	1800                	addi	s0,sp,48
    8000347a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000347c:	47ad                	li	a5,11
    8000347e:	04b7fe63          	bgeu	a5,a1,800034da <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003482:	ff45849b          	addiw	s1,a1,-12
    80003486:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000348a:	0ff00793          	li	a5,255
    8000348e:	0ae7e363          	bltu	a5,a4,80003534 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003492:	08052583          	lw	a1,128(a0)
    80003496:	c5ad                	beqz	a1,80003500 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003498:	00092503          	lw	a0,0(s2)
    8000349c:	00000097          	auipc	ra,0x0
    800034a0:	bda080e7          	jalr	-1062(ra) # 80003076 <bread>
    800034a4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034a6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034aa:	02049593          	slli	a1,s1,0x20
    800034ae:	9181                	srli	a1,a1,0x20
    800034b0:	058a                	slli	a1,a1,0x2
    800034b2:	00b784b3          	add	s1,a5,a1
    800034b6:	0004a983          	lw	s3,0(s1)
    800034ba:	04098d63          	beqz	s3,80003514 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034be:	8552                	mv	a0,s4
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	ce6080e7          	jalr	-794(ra) # 800031a6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034c8:	854e                	mv	a0,s3
    800034ca:	70a2                	ld	ra,40(sp)
    800034cc:	7402                	ld	s0,32(sp)
    800034ce:	64e2                	ld	s1,24(sp)
    800034d0:	6942                	ld	s2,16(sp)
    800034d2:	69a2                	ld	s3,8(sp)
    800034d4:	6a02                	ld	s4,0(sp)
    800034d6:	6145                	addi	sp,sp,48
    800034d8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034da:	02059493          	slli	s1,a1,0x20
    800034de:	9081                	srli	s1,s1,0x20
    800034e0:	048a                	slli	s1,s1,0x2
    800034e2:	94aa                	add	s1,s1,a0
    800034e4:	0504a983          	lw	s3,80(s1)
    800034e8:	fe0990e3          	bnez	s3,800034c8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034ec:	4108                	lw	a0,0(a0)
    800034ee:	00000097          	auipc	ra,0x0
    800034f2:	e4a080e7          	jalr	-438(ra) # 80003338 <balloc>
    800034f6:	0005099b          	sext.w	s3,a0
    800034fa:	0534a823          	sw	s3,80(s1)
    800034fe:	b7e9                	j	800034c8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003500:	4108                	lw	a0,0(a0)
    80003502:	00000097          	auipc	ra,0x0
    80003506:	e36080e7          	jalr	-458(ra) # 80003338 <balloc>
    8000350a:	0005059b          	sext.w	a1,a0
    8000350e:	08b92023          	sw	a1,128(s2)
    80003512:	b759                	j	80003498 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003514:	00092503          	lw	a0,0(s2)
    80003518:	00000097          	auipc	ra,0x0
    8000351c:	e20080e7          	jalr	-480(ra) # 80003338 <balloc>
    80003520:	0005099b          	sext.w	s3,a0
    80003524:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003528:	8552                	mv	a0,s4
    8000352a:	00001097          	auipc	ra,0x1
    8000352e:	ee0080e7          	jalr	-288(ra) # 8000440a <log_write>
    80003532:	b771                	j	800034be <bmap+0x54>
  panic("bmap: out of range");
    80003534:	00005517          	auipc	a0,0x5
    80003538:	23450513          	addi	a0,a0,564 # 80008768 <sysnames+0x128>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	00c080e7          	jalr	12(ra) # 80000548 <panic>

0000000080003544 <iget>:
{
    80003544:	7179                	addi	sp,sp,-48
    80003546:	f406                	sd	ra,40(sp)
    80003548:	f022                	sd	s0,32(sp)
    8000354a:	ec26                	sd	s1,24(sp)
    8000354c:	e84a                	sd	s2,16(sp)
    8000354e:	e44e                	sd	s3,8(sp)
    80003550:	e052                	sd	s4,0(sp)
    80003552:	1800                	addi	s0,sp,48
    80003554:	89aa                	mv	s3,a0
    80003556:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003558:	0001d517          	auipc	a0,0x1d
    8000355c:	b0850513          	addi	a0,a0,-1272 # 80020060 <icache>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	6fa080e7          	jalr	1786(ra) # 80000c5a <acquire>
  empty = 0;
    80003568:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000356a:	0001d497          	auipc	s1,0x1d
    8000356e:	b0e48493          	addi	s1,s1,-1266 # 80020078 <icache+0x18>
    80003572:	0001e697          	auipc	a3,0x1e
    80003576:	59668693          	addi	a3,a3,1430 # 80021b08 <log>
    8000357a:	a039                	j	80003588 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000357c:	02090b63          	beqz	s2,800035b2 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003580:	08848493          	addi	s1,s1,136
    80003584:	02d48a63          	beq	s1,a3,800035b8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003588:	449c                	lw	a5,8(s1)
    8000358a:	fef059e3          	blez	a5,8000357c <iget+0x38>
    8000358e:	4098                	lw	a4,0(s1)
    80003590:	ff3716e3          	bne	a4,s3,8000357c <iget+0x38>
    80003594:	40d8                	lw	a4,4(s1)
    80003596:	ff4713e3          	bne	a4,s4,8000357c <iget+0x38>
      ip->ref++;
    8000359a:	2785                	addiw	a5,a5,1
    8000359c:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000359e:	0001d517          	auipc	a0,0x1d
    800035a2:	ac250513          	addi	a0,a0,-1342 # 80020060 <icache>
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	768080e7          	jalr	1896(ra) # 80000d0e <release>
      return ip;
    800035ae:	8926                	mv	s2,s1
    800035b0:	a03d                	j	800035de <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035b2:	f7f9                	bnez	a5,80003580 <iget+0x3c>
    800035b4:	8926                	mv	s2,s1
    800035b6:	b7e9                	j	80003580 <iget+0x3c>
  if(empty == 0)
    800035b8:	02090c63          	beqz	s2,800035f0 <iget+0xac>
  ip->dev = dev;
    800035bc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035c0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035c4:	4785                	li	a5,1
    800035c6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035ca:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800035ce:	0001d517          	auipc	a0,0x1d
    800035d2:	a9250513          	addi	a0,a0,-1390 # 80020060 <icache>
    800035d6:	ffffd097          	auipc	ra,0xffffd
    800035da:	738080e7          	jalr	1848(ra) # 80000d0e <release>
}
    800035de:	854a                	mv	a0,s2
    800035e0:	70a2                	ld	ra,40(sp)
    800035e2:	7402                	ld	s0,32(sp)
    800035e4:	64e2                	ld	s1,24(sp)
    800035e6:	6942                	ld	s2,16(sp)
    800035e8:	69a2                	ld	s3,8(sp)
    800035ea:	6a02                	ld	s4,0(sp)
    800035ec:	6145                	addi	sp,sp,48
    800035ee:	8082                	ret
    panic("iget: no inodes");
    800035f0:	00005517          	auipc	a0,0x5
    800035f4:	19050513          	addi	a0,a0,400 # 80008780 <sysnames+0x140>
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	f50080e7          	jalr	-176(ra) # 80000548 <panic>

0000000080003600 <fsinit>:
fsinit(int dev) {
    80003600:	7179                	addi	sp,sp,-48
    80003602:	f406                	sd	ra,40(sp)
    80003604:	f022                	sd	s0,32(sp)
    80003606:	ec26                	sd	s1,24(sp)
    80003608:	e84a                	sd	s2,16(sp)
    8000360a:	e44e                	sd	s3,8(sp)
    8000360c:	1800                	addi	s0,sp,48
    8000360e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003610:	4585                	li	a1,1
    80003612:	00000097          	auipc	ra,0x0
    80003616:	a64080e7          	jalr	-1436(ra) # 80003076 <bread>
    8000361a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000361c:	0001d997          	auipc	s3,0x1d
    80003620:	a2498993          	addi	s3,s3,-1500 # 80020040 <sb>
    80003624:	02000613          	li	a2,32
    80003628:	05850593          	addi	a1,a0,88
    8000362c:	854e                	mv	a0,s3
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	788080e7          	jalr	1928(ra) # 80000db6 <memmove>
  brelse(bp);
    80003636:	8526                	mv	a0,s1
    80003638:	00000097          	auipc	ra,0x0
    8000363c:	b6e080e7          	jalr	-1170(ra) # 800031a6 <brelse>
  if(sb.magic != FSMAGIC)
    80003640:	0009a703          	lw	a4,0(s3)
    80003644:	102037b7          	lui	a5,0x10203
    80003648:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000364c:	02f71263          	bne	a4,a5,80003670 <fsinit+0x70>
  initlog(dev, &sb);
    80003650:	0001d597          	auipc	a1,0x1d
    80003654:	9f058593          	addi	a1,a1,-1552 # 80020040 <sb>
    80003658:	854a                	mv	a0,s2
    8000365a:	00001097          	auipc	ra,0x1
    8000365e:	b38080e7          	jalr	-1224(ra) # 80004192 <initlog>
}
    80003662:	70a2                	ld	ra,40(sp)
    80003664:	7402                	ld	s0,32(sp)
    80003666:	64e2                	ld	s1,24(sp)
    80003668:	6942                	ld	s2,16(sp)
    8000366a:	69a2                	ld	s3,8(sp)
    8000366c:	6145                	addi	sp,sp,48
    8000366e:	8082                	ret
    panic("invalid file system");
    80003670:	00005517          	auipc	a0,0x5
    80003674:	12050513          	addi	a0,a0,288 # 80008790 <sysnames+0x150>
    80003678:	ffffd097          	auipc	ra,0xffffd
    8000367c:	ed0080e7          	jalr	-304(ra) # 80000548 <panic>

0000000080003680 <iinit>:
{
    80003680:	7179                	addi	sp,sp,-48
    80003682:	f406                	sd	ra,40(sp)
    80003684:	f022                	sd	s0,32(sp)
    80003686:	ec26                	sd	s1,24(sp)
    80003688:	e84a                	sd	s2,16(sp)
    8000368a:	e44e                	sd	s3,8(sp)
    8000368c:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000368e:	00005597          	auipc	a1,0x5
    80003692:	11a58593          	addi	a1,a1,282 # 800087a8 <sysnames+0x168>
    80003696:	0001d517          	auipc	a0,0x1d
    8000369a:	9ca50513          	addi	a0,a0,-1590 # 80020060 <icache>
    8000369e:	ffffd097          	auipc	ra,0xffffd
    800036a2:	52c080e7          	jalr	1324(ra) # 80000bca <initlock>
  for(i = 0; i < NINODE; i++) {
    800036a6:	0001d497          	auipc	s1,0x1d
    800036aa:	9e248493          	addi	s1,s1,-1566 # 80020088 <icache+0x28>
    800036ae:	0001e997          	auipc	s3,0x1e
    800036b2:	46a98993          	addi	s3,s3,1130 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800036b6:	00005917          	auipc	s2,0x5
    800036ba:	0fa90913          	addi	s2,s2,250 # 800087b0 <sysnames+0x170>
    800036be:	85ca                	mv	a1,s2
    800036c0:	8526                	mv	a0,s1
    800036c2:	00001097          	auipc	ra,0x1
    800036c6:	e36080e7          	jalr	-458(ra) # 800044f8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036ca:	08848493          	addi	s1,s1,136
    800036ce:	ff3498e3          	bne	s1,s3,800036be <iinit+0x3e>
}
    800036d2:	70a2                	ld	ra,40(sp)
    800036d4:	7402                	ld	s0,32(sp)
    800036d6:	64e2                	ld	s1,24(sp)
    800036d8:	6942                	ld	s2,16(sp)
    800036da:	69a2                	ld	s3,8(sp)
    800036dc:	6145                	addi	sp,sp,48
    800036de:	8082                	ret

00000000800036e0 <ialloc>:
{
    800036e0:	715d                	addi	sp,sp,-80
    800036e2:	e486                	sd	ra,72(sp)
    800036e4:	e0a2                	sd	s0,64(sp)
    800036e6:	fc26                	sd	s1,56(sp)
    800036e8:	f84a                	sd	s2,48(sp)
    800036ea:	f44e                	sd	s3,40(sp)
    800036ec:	f052                	sd	s4,32(sp)
    800036ee:	ec56                	sd	s5,24(sp)
    800036f0:	e85a                	sd	s6,16(sp)
    800036f2:	e45e                	sd	s7,8(sp)
    800036f4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036f6:	0001d717          	auipc	a4,0x1d
    800036fa:	95672703          	lw	a4,-1706(a4) # 8002004c <sb+0xc>
    800036fe:	4785                	li	a5,1
    80003700:	04e7fa63          	bgeu	a5,a4,80003754 <ialloc+0x74>
    80003704:	8aaa                	mv	s5,a0
    80003706:	8bae                	mv	s7,a1
    80003708:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000370a:	0001da17          	auipc	s4,0x1d
    8000370e:	936a0a13          	addi	s4,s4,-1738 # 80020040 <sb>
    80003712:	00048b1b          	sext.w	s6,s1
    80003716:	0044d593          	srli	a1,s1,0x4
    8000371a:	018a2783          	lw	a5,24(s4)
    8000371e:	9dbd                	addw	a1,a1,a5
    80003720:	8556                	mv	a0,s5
    80003722:	00000097          	auipc	ra,0x0
    80003726:	954080e7          	jalr	-1708(ra) # 80003076 <bread>
    8000372a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000372c:	05850993          	addi	s3,a0,88
    80003730:	00f4f793          	andi	a5,s1,15
    80003734:	079a                	slli	a5,a5,0x6
    80003736:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003738:	00099783          	lh	a5,0(s3)
    8000373c:	c785                	beqz	a5,80003764 <ialloc+0x84>
    brelse(bp);
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	a68080e7          	jalr	-1432(ra) # 800031a6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003746:	0485                	addi	s1,s1,1
    80003748:	00ca2703          	lw	a4,12(s4)
    8000374c:	0004879b          	sext.w	a5,s1
    80003750:	fce7e1e3          	bltu	a5,a4,80003712 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003754:	00005517          	auipc	a0,0x5
    80003758:	06450513          	addi	a0,a0,100 # 800087b8 <sysnames+0x178>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	dec080e7          	jalr	-532(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003764:	04000613          	li	a2,64
    80003768:	4581                	li	a1,0
    8000376a:	854e                	mv	a0,s3
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	5ea080e7          	jalr	1514(ra) # 80000d56 <memset>
      dip->type = type;
    80003774:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003778:	854a                	mv	a0,s2
    8000377a:	00001097          	auipc	ra,0x1
    8000377e:	c90080e7          	jalr	-880(ra) # 8000440a <log_write>
      brelse(bp);
    80003782:	854a                	mv	a0,s2
    80003784:	00000097          	auipc	ra,0x0
    80003788:	a22080e7          	jalr	-1502(ra) # 800031a6 <brelse>
      return iget(dev, inum);
    8000378c:	85da                	mv	a1,s6
    8000378e:	8556                	mv	a0,s5
    80003790:	00000097          	auipc	ra,0x0
    80003794:	db4080e7          	jalr	-588(ra) # 80003544 <iget>
}
    80003798:	60a6                	ld	ra,72(sp)
    8000379a:	6406                	ld	s0,64(sp)
    8000379c:	74e2                	ld	s1,56(sp)
    8000379e:	7942                	ld	s2,48(sp)
    800037a0:	79a2                	ld	s3,40(sp)
    800037a2:	7a02                	ld	s4,32(sp)
    800037a4:	6ae2                	ld	s5,24(sp)
    800037a6:	6b42                	ld	s6,16(sp)
    800037a8:	6ba2                	ld	s7,8(sp)
    800037aa:	6161                	addi	sp,sp,80
    800037ac:	8082                	ret

00000000800037ae <iupdate>:
{
    800037ae:	1101                	addi	sp,sp,-32
    800037b0:	ec06                	sd	ra,24(sp)
    800037b2:	e822                	sd	s0,16(sp)
    800037b4:	e426                	sd	s1,8(sp)
    800037b6:	e04a                	sd	s2,0(sp)
    800037b8:	1000                	addi	s0,sp,32
    800037ba:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037bc:	415c                	lw	a5,4(a0)
    800037be:	0047d79b          	srliw	a5,a5,0x4
    800037c2:	0001d597          	auipc	a1,0x1d
    800037c6:	8965a583          	lw	a1,-1898(a1) # 80020058 <sb+0x18>
    800037ca:	9dbd                	addw	a1,a1,a5
    800037cc:	4108                	lw	a0,0(a0)
    800037ce:	00000097          	auipc	ra,0x0
    800037d2:	8a8080e7          	jalr	-1880(ra) # 80003076 <bread>
    800037d6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037d8:	05850793          	addi	a5,a0,88
    800037dc:	40c8                	lw	a0,4(s1)
    800037de:	893d                	andi	a0,a0,15
    800037e0:	051a                	slli	a0,a0,0x6
    800037e2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037e4:	04449703          	lh	a4,68(s1)
    800037e8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037ec:	04649703          	lh	a4,70(s1)
    800037f0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037f4:	04849703          	lh	a4,72(s1)
    800037f8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037fc:	04a49703          	lh	a4,74(s1)
    80003800:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003804:	44f8                	lw	a4,76(s1)
    80003806:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003808:	03400613          	li	a2,52
    8000380c:	05048593          	addi	a1,s1,80
    80003810:	0531                	addi	a0,a0,12
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	5a4080e7          	jalr	1444(ra) # 80000db6 <memmove>
  log_write(bp);
    8000381a:	854a                	mv	a0,s2
    8000381c:	00001097          	auipc	ra,0x1
    80003820:	bee080e7          	jalr	-1042(ra) # 8000440a <log_write>
  brelse(bp);
    80003824:	854a                	mv	a0,s2
    80003826:	00000097          	auipc	ra,0x0
    8000382a:	980080e7          	jalr	-1664(ra) # 800031a6 <brelse>
}
    8000382e:	60e2                	ld	ra,24(sp)
    80003830:	6442                	ld	s0,16(sp)
    80003832:	64a2                	ld	s1,8(sp)
    80003834:	6902                	ld	s2,0(sp)
    80003836:	6105                	addi	sp,sp,32
    80003838:	8082                	ret

000000008000383a <idup>:
{
    8000383a:	1101                	addi	sp,sp,-32
    8000383c:	ec06                	sd	ra,24(sp)
    8000383e:	e822                	sd	s0,16(sp)
    80003840:	e426                	sd	s1,8(sp)
    80003842:	1000                	addi	s0,sp,32
    80003844:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003846:	0001d517          	auipc	a0,0x1d
    8000384a:	81a50513          	addi	a0,a0,-2022 # 80020060 <icache>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	40c080e7          	jalr	1036(ra) # 80000c5a <acquire>
  ip->ref++;
    80003856:	449c                	lw	a5,8(s1)
    80003858:	2785                	addiw	a5,a5,1
    8000385a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000385c:	0001d517          	auipc	a0,0x1d
    80003860:	80450513          	addi	a0,a0,-2044 # 80020060 <icache>
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	4aa080e7          	jalr	1194(ra) # 80000d0e <release>
}
    8000386c:	8526                	mv	a0,s1
    8000386e:	60e2                	ld	ra,24(sp)
    80003870:	6442                	ld	s0,16(sp)
    80003872:	64a2                	ld	s1,8(sp)
    80003874:	6105                	addi	sp,sp,32
    80003876:	8082                	ret

0000000080003878 <ilock>:
{
    80003878:	1101                	addi	sp,sp,-32
    8000387a:	ec06                	sd	ra,24(sp)
    8000387c:	e822                	sd	s0,16(sp)
    8000387e:	e426                	sd	s1,8(sp)
    80003880:	e04a                	sd	s2,0(sp)
    80003882:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003884:	c115                	beqz	a0,800038a8 <ilock+0x30>
    80003886:	84aa                	mv	s1,a0
    80003888:	451c                	lw	a5,8(a0)
    8000388a:	00f05f63          	blez	a5,800038a8 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000388e:	0541                	addi	a0,a0,16
    80003890:	00001097          	auipc	ra,0x1
    80003894:	ca2080e7          	jalr	-862(ra) # 80004532 <acquiresleep>
  if(ip->valid == 0){
    80003898:	40bc                	lw	a5,64(s1)
    8000389a:	cf99                	beqz	a5,800038b8 <ilock+0x40>
}
    8000389c:	60e2                	ld	ra,24(sp)
    8000389e:	6442                	ld	s0,16(sp)
    800038a0:	64a2                	ld	s1,8(sp)
    800038a2:	6902                	ld	s2,0(sp)
    800038a4:	6105                	addi	sp,sp,32
    800038a6:	8082                	ret
    panic("ilock");
    800038a8:	00005517          	auipc	a0,0x5
    800038ac:	f2850513          	addi	a0,a0,-216 # 800087d0 <sysnames+0x190>
    800038b0:	ffffd097          	auipc	ra,0xffffd
    800038b4:	c98080e7          	jalr	-872(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038b8:	40dc                	lw	a5,4(s1)
    800038ba:	0047d79b          	srliw	a5,a5,0x4
    800038be:	0001c597          	auipc	a1,0x1c
    800038c2:	79a5a583          	lw	a1,1946(a1) # 80020058 <sb+0x18>
    800038c6:	9dbd                	addw	a1,a1,a5
    800038c8:	4088                	lw	a0,0(s1)
    800038ca:	fffff097          	auipc	ra,0xfffff
    800038ce:	7ac080e7          	jalr	1964(ra) # 80003076 <bread>
    800038d2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038d4:	05850593          	addi	a1,a0,88
    800038d8:	40dc                	lw	a5,4(s1)
    800038da:	8bbd                	andi	a5,a5,15
    800038dc:	079a                	slli	a5,a5,0x6
    800038de:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038e0:	00059783          	lh	a5,0(a1)
    800038e4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038e8:	00259783          	lh	a5,2(a1)
    800038ec:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038f0:	00459783          	lh	a5,4(a1)
    800038f4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038f8:	00659783          	lh	a5,6(a1)
    800038fc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003900:	459c                	lw	a5,8(a1)
    80003902:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003904:	03400613          	li	a2,52
    80003908:	05b1                	addi	a1,a1,12
    8000390a:	05048513          	addi	a0,s1,80
    8000390e:	ffffd097          	auipc	ra,0xffffd
    80003912:	4a8080e7          	jalr	1192(ra) # 80000db6 <memmove>
    brelse(bp);
    80003916:	854a                	mv	a0,s2
    80003918:	00000097          	auipc	ra,0x0
    8000391c:	88e080e7          	jalr	-1906(ra) # 800031a6 <brelse>
    ip->valid = 1;
    80003920:	4785                	li	a5,1
    80003922:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003924:	04449783          	lh	a5,68(s1)
    80003928:	fbb5                	bnez	a5,8000389c <ilock+0x24>
      panic("ilock: no type");
    8000392a:	00005517          	auipc	a0,0x5
    8000392e:	eae50513          	addi	a0,a0,-338 # 800087d8 <sysnames+0x198>
    80003932:	ffffd097          	auipc	ra,0xffffd
    80003936:	c16080e7          	jalr	-1002(ra) # 80000548 <panic>

000000008000393a <iunlock>:
{
    8000393a:	1101                	addi	sp,sp,-32
    8000393c:	ec06                	sd	ra,24(sp)
    8000393e:	e822                	sd	s0,16(sp)
    80003940:	e426                	sd	s1,8(sp)
    80003942:	e04a                	sd	s2,0(sp)
    80003944:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003946:	c905                	beqz	a0,80003976 <iunlock+0x3c>
    80003948:	84aa                	mv	s1,a0
    8000394a:	01050913          	addi	s2,a0,16
    8000394e:	854a                	mv	a0,s2
    80003950:	00001097          	auipc	ra,0x1
    80003954:	c7c080e7          	jalr	-900(ra) # 800045cc <holdingsleep>
    80003958:	cd19                	beqz	a0,80003976 <iunlock+0x3c>
    8000395a:	449c                	lw	a5,8(s1)
    8000395c:	00f05d63          	blez	a5,80003976 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003960:	854a                	mv	a0,s2
    80003962:	00001097          	auipc	ra,0x1
    80003966:	c26080e7          	jalr	-986(ra) # 80004588 <releasesleep>
}
    8000396a:	60e2                	ld	ra,24(sp)
    8000396c:	6442                	ld	s0,16(sp)
    8000396e:	64a2                	ld	s1,8(sp)
    80003970:	6902                	ld	s2,0(sp)
    80003972:	6105                	addi	sp,sp,32
    80003974:	8082                	ret
    panic("iunlock");
    80003976:	00005517          	auipc	a0,0x5
    8000397a:	e7250513          	addi	a0,a0,-398 # 800087e8 <sysnames+0x1a8>
    8000397e:	ffffd097          	auipc	ra,0xffffd
    80003982:	bca080e7          	jalr	-1078(ra) # 80000548 <panic>

0000000080003986 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003986:	7179                	addi	sp,sp,-48
    80003988:	f406                	sd	ra,40(sp)
    8000398a:	f022                	sd	s0,32(sp)
    8000398c:	ec26                	sd	s1,24(sp)
    8000398e:	e84a                	sd	s2,16(sp)
    80003990:	e44e                	sd	s3,8(sp)
    80003992:	e052                	sd	s4,0(sp)
    80003994:	1800                	addi	s0,sp,48
    80003996:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003998:	05050493          	addi	s1,a0,80
    8000399c:	08050913          	addi	s2,a0,128
    800039a0:	a021                	j	800039a8 <itrunc+0x22>
    800039a2:	0491                	addi	s1,s1,4
    800039a4:	01248d63          	beq	s1,s2,800039be <itrunc+0x38>
    if(ip->addrs[i]){
    800039a8:	408c                	lw	a1,0(s1)
    800039aa:	dde5                	beqz	a1,800039a2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039ac:	0009a503          	lw	a0,0(s3)
    800039b0:	00000097          	auipc	ra,0x0
    800039b4:	90c080e7          	jalr	-1780(ra) # 800032bc <bfree>
      ip->addrs[i] = 0;
    800039b8:	0004a023          	sw	zero,0(s1)
    800039bc:	b7dd                	j	800039a2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039be:	0809a583          	lw	a1,128(s3)
    800039c2:	e185                	bnez	a1,800039e2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039c4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039c8:	854e                	mv	a0,s3
    800039ca:	00000097          	auipc	ra,0x0
    800039ce:	de4080e7          	jalr	-540(ra) # 800037ae <iupdate>
}
    800039d2:	70a2                	ld	ra,40(sp)
    800039d4:	7402                	ld	s0,32(sp)
    800039d6:	64e2                	ld	s1,24(sp)
    800039d8:	6942                	ld	s2,16(sp)
    800039da:	69a2                	ld	s3,8(sp)
    800039dc:	6a02                	ld	s4,0(sp)
    800039de:	6145                	addi	sp,sp,48
    800039e0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039e2:	0009a503          	lw	a0,0(s3)
    800039e6:	fffff097          	auipc	ra,0xfffff
    800039ea:	690080e7          	jalr	1680(ra) # 80003076 <bread>
    800039ee:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039f0:	05850493          	addi	s1,a0,88
    800039f4:	45850913          	addi	s2,a0,1112
    800039f8:	a811                	j	80003a0c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039fa:	0009a503          	lw	a0,0(s3)
    800039fe:	00000097          	auipc	ra,0x0
    80003a02:	8be080e7          	jalr	-1858(ra) # 800032bc <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a06:	0491                	addi	s1,s1,4
    80003a08:	01248563          	beq	s1,s2,80003a12 <itrunc+0x8c>
      if(a[j])
    80003a0c:	408c                	lw	a1,0(s1)
    80003a0e:	dde5                	beqz	a1,80003a06 <itrunc+0x80>
    80003a10:	b7ed                	j	800039fa <itrunc+0x74>
    brelse(bp);
    80003a12:	8552                	mv	a0,s4
    80003a14:	fffff097          	auipc	ra,0xfffff
    80003a18:	792080e7          	jalr	1938(ra) # 800031a6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a1c:	0809a583          	lw	a1,128(s3)
    80003a20:	0009a503          	lw	a0,0(s3)
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	898080e7          	jalr	-1896(ra) # 800032bc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a2c:	0809a023          	sw	zero,128(s3)
    80003a30:	bf51                	j	800039c4 <itrunc+0x3e>

0000000080003a32 <iput>:
{
    80003a32:	1101                	addi	sp,sp,-32
    80003a34:	ec06                	sd	ra,24(sp)
    80003a36:	e822                	sd	s0,16(sp)
    80003a38:	e426                	sd	s1,8(sp)
    80003a3a:	e04a                	sd	s2,0(sp)
    80003a3c:	1000                	addi	s0,sp,32
    80003a3e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a40:	0001c517          	auipc	a0,0x1c
    80003a44:	62050513          	addi	a0,a0,1568 # 80020060 <icache>
    80003a48:	ffffd097          	auipc	ra,0xffffd
    80003a4c:	212080e7          	jalr	530(ra) # 80000c5a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a50:	4498                	lw	a4,8(s1)
    80003a52:	4785                	li	a5,1
    80003a54:	02f70363          	beq	a4,a5,80003a7a <iput+0x48>
  ip->ref--;
    80003a58:	449c                	lw	a5,8(s1)
    80003a5a:	37fd                	addiw	a5,a5,-1
    80003a5c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a5e:	0001c517          	auipc	a0,0x1c
    80003a62:	60250513          	addi	a0,a0,1538 # 80020060 <icache>
    80003a66:	ffffd097          	auipc	ra,0xffffd
    80003a6a:	2a8080e7          	jalr	680(ra) # 80000d0e <release>
}
    80003a6e:	60e2                	ld	ra,24(sp)
    80003a70:	6442                	ld	s0,16(sp)
    80003a72:	64a2                	ld	s1,8(sp)
    80003a74:	6902                	ld	s2,0(sp)
    80003a76:	6105                	addi	sp,sp,32
    80003a78:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a7a:	40bc                	lw	a5,64(s1)
    80003a7c:	dff1                	beqz	a5,80003a58 <iput+0x26>
    80003a7e:	04a49783          	lh	a5,74(s1)
    80003a82:	fbf9                	bnez	a5,80003a58 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a84:	01048913          	addi	s2,s1,16
    80003a88:	854a                	mv	a0,s2
    80003a8a:	00001097          	auipc	ra,0x1
    80003a8e:	aa8080e7          	jalr	-1368(ra) # 80004532 <acquiresleep>
    release(&icache.lock);
    80003a92:	0001c517          	auipc	a0,0x1c
    80003a96:	5ce50513          	addi	a0,a0,1486 # 80020060 <icache>
    80003a9a:	ffffd097          	auipc	ra,0xffffd
    80003a9e:	274080e7          	jalr	628(ra) # 80000d0e <release>
    itrunc(ip);
    80003aa2:	8526                	mv	a0,s1
    80003aa4:	00000097          	auipc	ra,0x0
    80003aa8:	ee2080e7          	jalr	-286(ra) # 80003986 <itrunc>
    ip->type = 0;
    80003aac:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ab0:	8526                	mv	a0,s1
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	cfc080e7          	jalr	-772(ra) # 800037ae <iupdate>
    ip->valid = 0;
    80003aba:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003abe:	854a                	mv	a0,s2
    80003ac0:	00001097          	auipc	ra,0x1
    80003ac4:	ac8080e7          	jalr	-1336(ra) # 80004588 <releasesleep>
    acquire(&icache.lock);
    80003ac8:	0001c517          	auipc	a0,0x1c
    80003acc:	59850513          	addi	a0,a0,1432 # 80020060 <icache>
    80003ad0:	ffffd097          	auipc	ra,0xffffd
    80003ad4:	18a080e7          	jalr	394(ra) # 80000c5a <acquire>
    80003ad8:	b741                	j	80003a58 <iput+0x26>

0000000080003ada <iunlockput>:
{
    80003ada:	1101                	addi	sp,sp,-32
    80003adc:	ec06                	sd	ra,24(sp)
    80003ade:	e822                	sd	s0,16(sp)
    80003ae0:	e426                	sd	s1,8(sp)
    80003ae2:	1000                	addi	s0,sp,32
    80003ae4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ae6:	00000097          	auipc	ra,0x0
    80003aea:	e54080e7          	jalr	-428(ra) # 8000393a <iunlock>
  iput(ip);
    80003aee:	8526                	mv	a0,s1
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	f42080e7          	jalr	-190(ra) # 80003a32 <iput>
}
    80003af8:	60e2                	ld	ra,24(sp)
    80003afa:	6442                	ld	s0,16(sp)
    80003afc:	64a2                	ld	s1,8(sp)
    80003afe:	6105                	addi	sp,sp,32
    80003b00:	8082                	ret

0000000080003b02 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b02:	1141                	addi	sp,sp,-16
    80003b04:	e422                	sd	s0,8(sp)
    80003b06:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b08:	411c                	lw	a5,0(a0)
    80003b0a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b0c:	415c                	lw	a5,4(a0)
    80003b0e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b10:	04451783          	lh	a5,68(a0)
    80003b14:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b18:	04a51783          	lh	a5,74(a0)
    80003b1c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b20:	04c56783          	lwu	a5,76(a0)
    80003b24:	e99c                	sd	a5,16(a1)
}
    80003b26:	6422                	ld	s0,8(sp)
    80003b28:	0141                	addi	sp,sp,16
    80003b2a:	8082                	ret

0000000080003b2c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b2c:	457c                	lw	a5,76(a0)
    80003b2e:	0ed7e863          	bltu	a5,a3,80003c1e <readi+0xf2>
{
    80003b32:	7159                	addi	sp,sp,-112
    80003b34:	f486                	sd	ra,104(sp)
    80003b36:	f0a2                	sd	s0,96(sp)
    80003b38:	eca6                	sd	s1,88(sp)
    80003b3a:	e8ca                	sd	s2,80(sp)
    80003b3c:	e4ce                	sd	s3,72(sp)
    80003b3e:	e0d2                	sd	s4,64(sp)
    80003b40:	fc56                	sd	s5,56(sp)
    80003b42:	f85a                	sd	s6,48(sp)
    80003b44:	f45e                	sd	s7,40(sp)
    80003b46:	f062                	sd	s8,32(sp)
    80003b48:	ec66                	sd	s9,24(sp)
    80003b4a:	e86a                	sd	s10,16(sp)
    80003b4c:	e46e                	sd	s11,8(sp)
    80003b4e:	1880                	addi	s0,sp,112
    80003b50:	8baa                	mv	s7,a0
    80003b52:	8c2e                	mv	s8,a1
    80003b54:	8ab2                	mv	s5,a2
    80003b56:	84b6                	mv	s1,a3
    80003b58:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b5a:	9f35                	addw	a4,a4,a3
    return 0;
    80003b5c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b5e:	08d76f63          	bltu	a4,a3,80003bfc <readi+0xd0>
  if(off + n > ip->size)
    80003b62:	00e7f463          	bgeu	a5,a4,80003b6a <readi+0x3e>
    n = ip->size - off;
    80003b66:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b6a:	0a0b0863          	beqz	s6,80003c1a <readi+0xee>
    80003b6e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b70:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b74:	5cfd                	li	s9,-1
    80003b76:	a82d                	j	80003bb0 <readi+0x84>
    80003b78:	020a1d93          	slli	s11,s4,0x20
    80003b7c:	020ddd93          	srli	s11,s11,0x20
    80003b80:	05890613          	addi	a2,s2,88
    80003b84:	86ee                	mv	a3,s11
    80003b86:	963a                	add	a2,a2,a4
    80003b88:	85d6                	mv	a1,s5
    80003b8a:	8562                	mv	a0,s8
    80003b8c:	fffff097          	auipc	ra,0xfffff
    80003b90:	9fe080e7          	jalr	-1538(ra) # 8000258a <either_copyout>
    80003b94:	05950d63          	beq	a0,s9,80003bee <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003b98:	854a                	mv	a0,s2
    80003b9a:	fffff097          	auipc	ra,0xfffff
    80003b9e:	60c080e7          	jalr	1548(ra) # 800031a6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ba2:	013a09bb          	addw	s3,s4,s3
    80003ba6:	009a04bb          	addw	s1,s4,s1
    80003baa:	9aee                	add	s5,s5,s11
    80003bac:	0569f663          	bgeu	s3,s6,80003bf8 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bb0:	000ba903          	lw	s2,0(s7)
    80003bb4:	00a4d59b          	srliw	a1,s1,0xa
    80003bb8:	855e                	mv	a0,s7
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	8b0080e7          	jalr	-1872(ra) # 8000346a <bmap>
    80003bc2:	0005059b          	sext.w	a1,a0
    80003bc6:	854a                	mv	a0,s2
    80003bc8:	fffff097          	auipc	ra,0xfffff
    80003bcc:	4ae080e7          	jalr	1198(ra) # 80003076 <bread>
    80003bd0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd2:	3ff4f713          	andi	a4,s1,1023
    80003bd6:	40ed07bb          	subw	a5,s10,a4
    80003bda:	413b06bb          	subw	a3,s6,s3
    80003bde:	8a3e                	mv	s4,a5
    80003be0:	2781                	sext.w	a5,a5
    80003be2:	0006861b          	sext.w	a2,a3
    80003be6:	f8f679e3          	bgeu	a2,a5,80003b78 <readi+0x4c>
    80003bea:	8a36                	mv	s4,a3
    80003bec:	b771                	j	80003b78 <readi+0x4c>
      brelse(bp);
    80003bee:	854a                	mv	a0,s2
    80003bf0:	fffff097          	auipc	ra,0xfffff
    80003bf4:	5b6080e7          	jalr	1462(ra) # 800031a6 <brelse>
  }
  return tot;
    80003bf8:	0009851b          	sext.w	a0,s3
}
    80003bfc:	70a6                	ld	ra,104(sp)
    80003bfe:	7406                	ld	s0,96(sp)
    80003c00:	64e6                	ld	s1,88(sp)
    80003c02:	6946                	ld	s2,80(sp)
    80003c04:	69a6                	ld	s3,72(sp)
    80003c06:	6a06                	ld	s4,64(sp)
    80003c08:	7ae2                	ld	s5,56(sp)
    80003c0a:	7b42                	ld	s6,48(sp)
    80003c0c:	7ba2                	ld	s7,40(sp)
    80003c0e:	7c02                	ld	s8,32(sp)
    80003c10:	6ce2                	ld	s9,24(sp)
    80003c12:	6d42                	ld	s10,16(sp)
    80003c14:	6da2                	ld	s11,8(sp)
    80003c16:	6165                	addi	sp,sp,112
    80003c18:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c1a:	89da                	mv	s3,s6
    80003c1c:	bff1                	j	80003bf8 <readi+0xcc>
    return 0;
    80003c1e:	4501                	li	a0,0
}
    80003c20:	8082                	ret

0000000080003c22 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c22:	457c                	lw	a5,76(a0)
    80003c24:	10d7e663          	bltu	a5,a3,80003d30 <writei+0x10e>
{
    80003c28:	7159                	addi	sp,sp,-112
    80003c2a:	f486                	sd	ra,104(sp)
    80003c2c:	f0a2                	sd	s0,96(sp)
    80003c2e:	eca6                	sd	s1,88(sp)
    80003c30:	e8ca                	sd	s2,80(sp)
    80003c32:	e4ce                	sd	s3,72(sp)
    80003c34:	e0d2                	sd	s4,64(sp)
    80003c36:	fc56                	sd	s5,56(sp)
    80003c38:	f85a                	sd	s6,48(sp)
    80003c3a:	f45e                	sd	s7,40(sp)
    80003c3c:	f062                	sd	s8,32(sp)
    80003c3e:	ec66                	sd	s9,24(sp)
    80003c40:	e86a                	sd	s10,16(sp)
    80003c42:	e46e                	sd	s11,8(sp)
    80003c44:	1880                	addi	s0,sp,112
    80003c46:	8baa                	mv	s7,a0
    80003c48:	8c2e                	mv	s8,a1
    80003c4a:	8ab2                	mv	s5,a2
    80003c4c:	8936                	mv	s2,a3
    80003c4e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c50:	00e687bb          	addw	a5,a3,a4
    80003c54:	0ed7e063          	bltu	a5,a3,80003d34 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c58:	00043737          	lui	a4,0x43
    80003c5c:	0cf76e63          	bltu	a4,a5,80003d38 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c60:	0a0b0763          	beqz	s6,80003d0e <writei+0xec>
    80003c64:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c66:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c6a:	5cfd                	li	s9,-1
    80003c6c:	a091                	j	80003cb0 <writei+0x8e>
    80003c6e:	02099d93          	slli	s11,s3,0x20
    80003c72:	020ddd93          	srli	s11,s11,0x20
    80003c76:	05848513          	addi	a0,s1,88
    80003c7a:	86ee                	mv	a3,s11
    80003c7c:	8656                	mv	a2,s5
    80003c7e:	85e2                	mv	a1,s8
    80003c80:	953a                	add	a0,a0,a4
    80003c82:	fffff097          	auipc	ra,0xfffff
    80003c86:	95e080e7          	jalr	-1698(ra) # 800025e0 <either_copyin>
    80003c8a:	07950263          	beq	a0,s9,80003cee <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c8e:	8526                	mv	a0,s1
    80003c90:	00000097          	auipc	ra,0x0
    80003c94:	77a080e7          	jalr	1914(ra) # 8000440a <log_write>
    brelse(bp);
    80003c98:	8526                	mv	a0,s1
    80003c9a:	fffff097          	auipc	ra,0xfffff
    80003c9e:	50c080e7          	jalr	1292(ra) # 800031a6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ca2:	01498a3b          	addw	s4,s3,s4
    80003ca6:	0129893b          	addw	s2,s3,s2
    80003caa:	9aee                	add	s5,s5,s11
    80003cac:	056a7663          	bgeu	s4,s6,80003cf8 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cb0:	000ba483          	lw	s1,0(s7)
    80003cb4:	00a9559b          	srliw	a1,s2,0xa
    80003cb8:	855e                	mv	a0,s7
    80003cba:	fffff097          	auipc	ra,0xfffff
    80003cbe:	7b0080e7          	jalr	1968(ra) # 8000346a <bmap>
    80003cc2:	0005059b          	sext.w	a1,a0
    80003cc6:	8526                	mv	a0,s1
    80003cc8:	fffff097          	auipc	ra,0xfffff
    80003ccc:	3ae080e7          	jalr	942(ra) # 80003076 <bread>
    80003cd0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cd2:	3ff97713          	andi	a4,s2,1023
    80003cd6:	40ed07bb          	subw	a5,s10,a4
    80003cda:	414b06bb          	subw	a3,s6,s4
    80003cde:	89be                	mv	s3,a5
    80003ce0:	2781                	sext.w	a5,a5
    80003ce2:	0006861b          	sext.w	a2,a3
    80003ce6:	f8f674e3          	bgeu	a2,a5,80003c6e <writei+0x4c>
    80003cea:	89b6                	mv	s3,a3
    80003cec:	b749                	j	80003c6e <writei+0x4c>
      brelse(bp);
    80003cee:	8526                	mv	a0,s1
    80003cf0:	fffff097          	auipc	ra,0xfffff
    80003cf4:	4b6080e7          	jalr	1206(ra) # 800031a6 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003cf8:	04cba783          	lw	a5,76(s7)
    80003cfc:	0127f463          	bgeu	a5,s2,80003d04 <writei+0xe2>
      ip->size = off;
    80003d00:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003d04:	855e                	mv	a0,s7
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	aa8080e7          	jalr	-1368(ra) # 800037ae <iupdate>
  }

  return n;
    80003d0e:	000b051b          	sext.w	a0,s6
}
    80003d12:	70a6                	ld	ra,104(sp)
    80003d14:	7406                	ld	s0,96(sp)
    80003d16:	64e6                	ld	s1,88(sp)
    80003d18:	6946                	ld	s2,80(sp)
    80003d1a:	69a6                	ld	s3,72(sp)
    80003d1c:	6a06                	ld	s4,64(sp)
    80003d1e:	7ae2                	ld	s5,56(sp)
    80003d20:	7b42                	ld	s6,48(sp)
    80003d22:	7ba2                	ld	s7,40(sp)
    80003d24:	7c02                	ld	s8,32(sp)
    80003d26:	6ce2                	ld	s9,24(sp)
    80003d28:	6d42                	ld	s10,16(sp)
    80003d2a:	6da2                	ld	s11,8(sp)
    80003d2c:	6165                	addi	sp,sp,112
    80003d2e:	8082                	ret
    return -1;
    80003d30:	557d                	li	a0,-1
}
    80003d32:	8082                	ret
    return -1;
    80003d34:	557d                	li	a0,-1
    80003d36:	bff1                	j	80003d12 <writei+0xf0>
    return -1;
    80003d38:	557d                	li	a0,-1
    80003d3a:	bfe1                	j	80003d12 <writei+0xf0>

0000000080003d3c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d3c:	1141                	addi	sp,sp,-16
    80003d3e:	e406                	sd	ra,8(sp)
    80003d40:	e022                	sd	s0,0(sp)
    80003d42:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d44:	4639                	li	a2,14
    80003d46:	ffffd097          	auipc	ra,0xffffd
    80003d4a:	0ec080e7          	jalr	236(ra) # 80000e32 <strncmp>
}
    80003d4e:	60a2                	ld	ra,8(sp)
    80003d50:	6402                	ld	s0,0(sp)
    80003d52:	0141                	addi	sp,sp,16
    80003d54:	8082                	ret

0000000080003d56 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d56:	7139                	addi	sp,sp,-64
    80003d58:	fc06                	sd	ra,56(sp)
    80003d5a:	f822                	sd	s0,48(sp)
    80003d5c:	f426                	sd	s1,40(sp)
    80003d5e:	f04a                	sd	s2,32(sp)
    80003d60:	ec4e                	sd	s3,24(sp)
    80003d62:	e852                	sd	s4,16(sp)
    80003d64:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d66:	04451703          	lh	a4,68(a0)
    80003d6a:	4785                	li	a5,1
    80003d6c:	00f71a63          	bne	a4,a5,80003d80 <dirlookup+0x2a>
    80003d70:	892a                	mv	s2,a0
    80003d72:	89ae                	mv	s3,a1
    80003d74:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d76:	457c                	lw	a5,76(a0)
    80003d78:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d7a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d7c:	e79d                	bnez	a5,80003daa <dirlookup+0x54>
    80003d7e:	a8a5                	j	80003df6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d80:	00005517          	auipc	a0,0x5
    80003d84:	a7050513          	addi	a0,a0,-1424 # 800087f0 <sysnames+0x1b0>
    80003d88:	ffffc097          	auipc	ra,0xffffc
    80003d8c:	7c0080e7          	jalr	1984(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003d90:	00005517          	auipc	a0,0x5
    80003d94:	a7850513          	addi	a0,a0,-1416 # 80008808 <sysnames+0x1c8>
    80003d98:	ffffc097          	auipc	ra,0xffffc
    80003d9c:	7b0080e7          	jalr	1968(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003da0:	24c1                	addiw	s1,s1,16
    80003da2:	04c92783          	lw	a5,76(s2)
    80003da6:	04f4f763          	bgeu	s1,a5,80003df4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003daa:	4741                	li	a4,16
    80003dac:	86a6                	mv	a3,s1
    80003dae:	fc040613          	addi	a2,s0,-64
    80003db2:	4581                	li	a1,0
    80003db4:	854a                	mv	a0,s2
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	d76080e7          	jalr	-650(ra) # 80003b2c <readi>
    80003dbe:	47c1                	li	a5,16
    80003dc0:	fcf518e3          	bne	a0,a5,80003d90 <dirlookup+0x3a>
    if(de.inum == 0)
    80003dc4:	fc045783          	lhu	a5,-64(s0)
    80003dc8:	dfe1                	beqz	a5,80003da0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dca:	fc240593          	addi	a1,s0,-62
    80003dce:	854e                	mv	a0,s3
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	f6c080e7          	jalr	-148(ra) # 80003d3c <namecmp>
    80003dd8:	f561                	bnez	a0,80003da0 <dirlookup+0x4a>
      if(poff)
    80003dda:	000a0463          	beqz	s4,80003de2 <dirlookup+0x8c>
        *poff = off;
    80003dde:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003de2:	fc045583          	lhu	a1,-64(s0)
    80003de6:	00092503          	lw	a0,0(s2)
    80003dea:	fffff097          	auipc	ra,0xfffff
    80003dee:	75a080e7          	jalr	1882(ra) # 80003544 <iget>
    80003df2:	a011                	j	80003df6 <dirlookup+0xa0>
  return 0;
    80003df4:	4501                	li	a0,0
}
    80003df6:	70e2                	ld	ra,56(sp)
    80003df8:	7442                	ld	s0,48(sp)
    80003dfa:	74a2                	ld	s1,40(sp)
    80003dfc:	7902                	ld	s2,32(sp)
    80003dfe:	69e2                	ld	s3,24(sp)
    80003e00:	6a42                	ld	s4,16(sp)
    80003e02:	6121                	addi	sp,sp,64
    80003e04:	8082                	ret

0000000080003e06 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e06:	711d                	addi	sp,sp,-96
    80003e08:	ec86                	sd	ra,88(sp)
    80003e0a:	e8a2                	sd	s0,80(sp)
    80003e0c:	e4a6                	sd	s1,72(sp)
    80003e0e:	e0ca                	sd	s2,64(sp)
    80003e10:	fc4e                	sd	s3,56(sp)
    80003e12:	f852                	sd	s4,48(sp)
    80003e14:	f456                	sd	s5,40(sp)
    80003e16:	f05a                	sd	s6,32(sp)
    80003e18:	ec5e                	sd	s7,24(sp)
    80003e1a:	e862                	sd	s8,16(sp)
    80003e1c:	e466                	sd	s9,8(sp)
    80003e1e:	1080                	addi	s0,sp,96
    80003e20:	84aa                	mv	s1,a0
    80003e22:	8b2e                	mv	s6,a1
    80003e24:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e26:	00054703          	lbu	a4,0(a0)
    80003e2a:	02f00793          	li	a5,47
    80003e2e:	02f70363          	beq	a4,a5,80003e54 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e32:	ffffe097          	auipc	ra,0xffffe
    80003e36:	cde080e7          	jalr	-802(ra) # 80001b10 <myproc>
    80003e3a:	15053503          	ld	a0,336(a0)
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	9fc080e7          	jalr	-1540(ra) # 8000383a <idup>
    80003e46:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e48:	02f00913          	li	s2,47
  len = path - s;
    80003e4c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e4e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e50:	4c05                	li	s8,1
    80003e52:	a865                	j	80003f0a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e54:	4585                	li	a1,1
    80003e56:	4505                	li	a0,1
    80003e58:	fffff097          	auipc	ra,0xfffff
    80003e5c:	6ec080e7          	jalr	1772(ra) # 80003544 <iget>
    80003e60:	89aa                	mv	s3,a0
    80003e62:	b7dd                	j	80003e48 <namex+0x42>
      iunlockput(ip);
    80003e64:	854e                	mv	a0,s3
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	c74080e7          	jalr	-908(ra) # 80003ada <iunlockput>
      return 0;
    80003e6e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e70:	854e                	mv	a0,s3
    80003e72:	60e6                	ld	ra,88(sp)
    80003e74:	6446                	ld	s0,80(sp)
    80003e76:	64a6                	ld	s1,72(sp)
    80003e78:	6906                	ld	s2,64(sp)
    80003e7a:	79e2                	ld	s3,56(sp)
    80003e7c:	7a42                	ld	s4,48(sp)
    80003e7e:	7aa2                	ld	s5,40(sp)
    80003e80:	7b02                	ld	s6,32(sp)
    80003e82:	6be2                	ld	s7,24(sp)
    80003e84:	6c42                	ld	s8,16(sp)
    80003e86:	6ca2                	ld	s9,8(sp)
    80003e88:	6125                	addi	sp,sp,96
    80003e8a:	8082                	ret
      iunlock(ip);
    80003e8c:	854e                	mv	a0,s3
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	aac080e7          	jalr	-1364(ra) # 8000393a <iunlock>
      return ip;
    80003e96:	bfe9                	j	80003e70 <namex+0x6a>
      iunlockput(ip);
    80003e98:	854e                	mv	a0,s3
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	c40080e7          	jalr	-960(ra) # 80003ada <iunlockput>
      return 0;
    80003ea2:	89d2                	mv	s3,s4
    80003ea4:	b7f1                	j	80003e70 <namex+0x6a>
  len = path - s;
    80003ea6:	40b48633          	sub	a2,s1,a1
    80003eaa:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003eae:	094cd463          	bge	s9,s4,80003f36 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003eb2:	4639                	li	a2,14
    80003eb4:	8556                	mv	a0,s5
    80003eb6:	ffffd097          	auipc	ra,0xffffd
    80003eba:	f00080e7          	jalr	-256(ra) # 80000db6 <memmove>
  while(*path == '/')
    80003ebe:	0004c783          	lbu	a5,0(s1)
    80003ec2:	01279763          	bne	a5,s2,80003ed0 <namex+0xca>
    path++;
    80003ec6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ec8:	0004c783          	lbu	a5,0(s1)
    80003ecc:	ff278de3          	beq	a5,s2,80003ec6 <namex+0xc0>
    ilock(ip);
    80003ed0:	854e                	mv	a0,s3
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	9a6080e7          	jalr	-1626(ra) # 80003878 <ilock>
    if(ip->type != T_DIR){
    80003eda:	04499783          	lh	a5,68(s3)
    80003ede:	f98793e3          	bne	a5,s8,80003e64 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ee2:	000b0563          	beqz	s6,80003eec <namex+0xe6>
    80003ee6:	0004c783          	lbu	a5,0(s1)
    80003eea:	d3cd                	beqz	a5,80003e8c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003eec:	865e                	mv	a2,s7
    80003eee:	85d6                	mv	a1,s5
    80003ef0:	854e                	mv	a0,s3
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	e64080e7          	jalr	-412(ra) # 80003d56 <dirlookup>
    80003efa:	8a2a                	mv	s4,a0
    80003efc:	dd51                	beqz	a0,80003e98 <namex+0x92>
    iunlockput(ip);
    80003efe:	854e                	mv	a0,s3
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	bda080e7          	jalr	-1062(ra) # 80003ada <iunlockput>
    ip = next;
    80003f08:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f0a:	0004c783          	lbu	a5,0(s1)
    80003f0e:	05279763          	bne	a5,s2,80003f5c <namex+0x156>
    path++;
    80003f12:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f14:	0004c783          	lbu	a5,0(s1)
    80003f18:	ff278de3          	beq	a5,s2,80003f12 <namex+0x10c>
  if(*path == 0)
    80003f1c:	c79d                	beqz	a5,80003f4a <namex+0x144>
    path++;
    80003f1e:	85a6                	mv	a1,s1
  len = path - s;
    80003f20:	8a5e                	mv	s4,s7
    80003f22:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f24:	01278963          	beq	a5,s2,80003f36 <namex+0x130>
    80003f28:	dfbd                	beqz	a5,80003ea6 <namex+0xa0>
    path++;
    80003f2a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f2c:	0004c783          	lbu	a5,0(s1)
    80003f30:	ff279ce3          	bne	a5,s2,80003f28 <namex+0x122>
    80003f34:	bf8d                	j	80003ea6 <namex+0xa0>
    memmove(name, s, len);
    80003f36:	2601                	sext.w	a2,a2
    80003f38:	8556                	mv	a0,s5
    80003f3a:	ffffd097          	auipc	ra,0xffffd
    80003f3e:	e7c080e7          	jalr	-388(ra) # 80000db6 <memmove>
    name[len] = 0;
    80003f42:	9a56                	add	s4,s4,s5
    80003f44:	000a0023          	sb	zero,0(s4)
    80003f48:	bf9d                	j	80003ebe <namex+0xb8>
  if(nameiparent){
    80003f4a:	f20b03e3          	beqz	s6,80003e70 <namex+0x6a>
    iput(ip);
    80003f4e:	854e                	mv	a0,s3
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	ae2080e7          	jalr	-1310(ra) # 80003a32 <iput>
    return 0;
    80003f58:	4981                	li	s3,0
    80003f5a:	bf19                	j	80003e70 <namex+0x6a>
  if(*path == 0)
    80003f5c:	d7fd                	beqz	a5,80003f4a <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f5e:	0004c783          	lbu	a5,0(s1)
    80003f62:	85a6                	mv	a1,s1
    80003f64:	b7d1                	j	80003f28 <namex+0x122>

0000000080003f66 <dirlink>:
{
    80003f66:	7139                	addi	sp,sp,-64
    80003f68:	fc06                	sd	ra,56(sp)
    80003f6a:	f822                	sd	s0,48(sp)
    80003f6c:	f426                	sd	s1,40(sp)
    80003f6e:	f04a                	sd	s2,32(sp)
    80003f70:	ec4e                	sd	s3,24(sp)
    80003f72:	e852                	sd	s4,16(sp)
    80003f74:	0080                	addi	s0,sp,64
    80003f76:	892a                	mv	s2,a0
    80003f78:	8a2e                	mv	s4,a1
    80003f7a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f7c:	4601                	li	a2,0
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	dd8080e7          	jalr	-552(ra) # 80003d56 <dirlookup>
    80003f86:	e93d                	bnez	a0,80003ffc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f88:	04c92483          	lw	s1,76(s2)
    80003f8c:	c49d                	beqz	s1,80003fba <dirlink+0x54>
    80003f8e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f90:	4741                	li	a4,16
    80003f92:	86a6                	mv	a3,s1
    80003f94:	fc040613          	addi	a2,s0,-64
    80003f98:	4581                	li	a1,0
    80003f9a:	854a                	mv	a0,s2
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	b90080e7          	jalr	-1136(ra) # 80003b2c <readi>
    80003fa4:	47c1                	li	a5,16
    80003fa6:	06f51163          	bne	a0,a5,80004008 <dirlink+0xa2>
    if(de.inum == 0)
    80003faa:	fc045783          	lhu	a5,-64(s0)
    80003fae:	c791                	beqz	a5,80003fba <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fb0:	24c1                	addiw	s1,s1,16
    80003fb2:	04c92783          	lw	a5,76(s2)
    80003fb6:	fcf4ede3          	bltu	s1,a5,80003f90 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fba:	4639                	li	a2,14
    80003fbc:	85d2                	mv	a1,s4
    80003fbe:	fc240513          	addi	a0,s0,-62
    80003fc2:	ffffd097          	auipc	ra,0xffffd
    80003fc6:	eac080e7          	jalr	-340(ra) # 80000e6e <strncpy>
  de.inum = inum;
    80003fca:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fce:	4741                	li	a4,16
    80003fd0:	86a6                	mv	a3,s1
    80003fd2:	fc040613          	addi	a2,s0,-64
    80003fd6:	4581                	li	a1,0
    80003fd8:	854a                	mv	a0,s2
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	c48080e7          	jalr	-952(ra) # 80003c22 <writei>
    80003fe2:	872a                	mv	a4,a0
    80003fe4:	47c1                	li	a5,16
  return 0;
    80003fe6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fe8:	02f71863          	bne	a4,a5,80004018 <dirlink+0xb2>
}
    80003fec:	70e2                	ld	ra,56(sp)
    80003fee:	7442                	ld	s0,48(sp)
    80003ff0:	74a2                	ld	s1,40(sp)
    80003ff2:	7902                	ld	s2,32(sp)
    80003ff4:	69e2                	ld	s3,24(sp)
    80003ff6:	6a42                	ld	s4,16(sp)
    80003ff8:	6121                	addi	sp,sp,64
    80003ffa:	8082                	ret
    iput(ip);
    80003ffc:	00000097          	auipc	ra,0x0
    80004000:	a36080e7          	jalr	-1482(ra) # 80003a32 <iput>
    return -1;
    80004004:	557d                	li	a0,-1
    80004006:	b7dd                	j	80003fec <dirlink+0x86>
      panic("dirlink read");
    80004008:	00005517          	auipc	a0,0x5
    8000400c:	81050513          	addi	a0,a0,-2032 # 80008818 <sysnames+0x1d8>
    80004010:	ffffc097          	auipc	ra,0xffffc
    80004014:	538080e7          	jalr	1336(ra) # 80000548 <panic>
    panic("dirlink");
    80004018:	00005517          	auipc	a0,0x5
    8000401c:	91050513          	addi	a0,a0,-1776 # 80008928 <sysnames+0x2e8>
    80004020:	ffffc097          	auipc	ra,0xffffc
    80004024:	528080e7          	jalr	1320(ra) # 80000548 <panic>

0000000080004028 <namei>:

struct inode*
namei(char *path)
{
    80004028:	1101                	addi	sp,sp,-32
    8000402a:	ec06                	sd	ra,24(sp)
    8000402c:	e822                	sd	s0,16(sp)
    8000402e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004030:	fe040613          	addi	a2,s0,-32
    80004034:	4581                	li	a1,0
    80004036:	00000097          	auipc	ra,0x0
    8000403a:	dd0080e7          	jalr	-560(ra) # 80003e06 <namex>
}
    8000403e:	60e2                	ld	ra,24(sp)
    80004040:	6442                	ld	s0,16(sp)
    80004042:	6105                	addi	sp,sp,32
    80004044:	8082                	ret

0000000080004046 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004046:	1141                	addi	sp,sp,-16
    80004048:	e406                	sd	ra,8(sp)
    8000404a:	e022                	sd	s0,0(sp)
    8000404c:	0800                	addi	s0,sp,16
    8000404e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004050:	4585                	li	a1,1
    80004052:	00000097          	auipc	ra,0x0
    80004056:	db4080e7          	jalr	-588(ra) # 80003e06 <namex>
}
    8000405a:	60a2                	ld	ra,8(sp)
    8000405c:	6402                	ld	s0,0(sp)
    8000405e:	0141                	addi	sp,sp,16
    80004060:	8082                	ret

0000000080004062 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004062:	1101                	addi	sp,sp,-32
    80004064:	ec06                	sd	ra,24(sp)
    80004066:	e822                	sd	s0,16(sp)
    80004068:	e426                	sd	s1,8(sp)
    8000406a:	e04a                	sd	s2,0(sp)
    8000406c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000406e:	0001e917          	auipc	s2,0x1e
    80004072:	a9a90913          	addi	s2,s2,-1382 # 80021b08 <log>
    80004076:	01892583          	lw	a1,24(s2)
    8000407a:	02892503          	lw	a0,40(s2)
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	ff8080e7          	jalr	-8(ra) # 80003076 <bread>
    80004086:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004088:	02c92683          	lw	a3,44(s2)
    8000408c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000408e:	02d05763          	blez	a3,800040bc <write_head+0x5a>
    80004092:	0001e797          	auipc	a5,0x1e
    80004096:	aa678793          	addi	a5,a5,-1370 # 80021b38 <log+0x30>
    8000409a:	05c50713          	addi	a4,a0,92
    8000409e:	36fd                	addiw	a3,a3,-1
    800040a0:	1682                	slli	a3,a3,0x20
    800040a2:	9281                	srli	a3,a3,0x20
    800040a4:	068a                	slli	a3,a3,0x2
    800040a6:	0001e617          	auipc	a2,0x1e
    800040aa:	a9660613          	addi	a2,a2,-1386 # 80021b3c <log+0x34>
    800040ae:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040b0:	4390                	lw	a2,0(a5)
    800040b2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040b4:	0791                	addi	a5,a5,4
    800040b6:	0711                	addi	a4,a4,4
    800040b8:	fed79ce3          	bne	a5,a3,800040b0 <write_head+0x4e>
  }
  bwrite(buf);
    800040bc:	8526                	mv	a0,s1
    800040be:	fffff097          	auipc	ra,0xfffff
    800040c2:	0aa080e7          	jalr	170(ra) # 80003168 <bwrite>
  brelse(buf);
    800040c6:	8526                	mv	a0,s1
    800040c8:	fffff097          	auipc	ra,0xfffff
    800040cc:	0de080e7          	jalr	222(ra) # 800031a6 <brelse>
}
    800040d0:	60e2                	ld	ra,24(sp)
    800040d2:	6442                	ld	s0,16(sp)
    800040d4:	64a2                	ld	s1,8(sp)
    800040d6:	6902                	ld	s2,0(sp)
    800040d8:	6105                	addi	sp,sp,32
    800040da:	8082                	ret

00000000800040dc <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040dc:	0001e797          	auipc	a5,0x1e
    800040e0:	a587a783          	lw	a5,-1448(a5) # 80021b34 <log+0x2c>
    800040e4:	0af05663          	blez	a5,80004190 <install_trans+0xb4>
{
    800040e8:	7139                	addi	sp,sp,-64
    800040ea:	fc06                	sd	ra,56(sp)
    800040ec:	f822                	sd	s0,48(sp)
    800040ee:	f426                	sd	s1,40(sp)
    800040f0:	f04a                	sd	s2,32(sp)
    800040f2:	ec4e                	sd	s3,24(sp)
    800040f4:	e852                	sd	s4,16(sp)
    800040f6:	e456                	sd	s5,8(sp)
    800040f8:	0080                	addi	s0,sp,64
    800040fa:	0001ea97          	auipc	s5,0x1e
    800040fe:	a3ea8a93          	addi	s5,s5,-1474 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004102:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004104:	0001e997          	auipc	s3,0x1e
    80004108:	a0498993          	addi	s3,s3,-1532 # 80021b08 <log>
    8000410c:	0189a583          	lw	a1,24(s3)
    80004110:	014585bb          	addw	a1,a1,s4
    80004114:	2585                	addiw	a1,a1,1
    80004116:	0289a503          	lw	a0,40(s3)
    8000411a:	fffff097          	auipc	ra,0xfffff
    8000411e:	f5c080e7          	jalr	-164(ra) # 80003076 <bread>
    80004122:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004124:	000aa583          	lw	a1,0(s5)
    80004128:	0289a503          	lw	a0,40(s3)
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	f4a080e7          	jalr	-182(ra) # 80003076 <bread>
    80004134:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004136:	40000613          	li	a2,1024
    8000413a:	05890593          	addi	a1,s2,88
    8000413e:	05850513          	addi	a0,a0,88
    80004142:	ffffd097          	auipc	ra,0xffffd
    80004146:	c74080e7          	jalr	-908(ra) # 80000db6 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000414a:	8526                	mv	a0,s1
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	01c080e7          	jalr	28(ra) # 80003168 <bwrite>
    bunpin(dbuf);
    80004154:	8526                	mv	a0,s1
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	12a080e7          	jalr	298(ra) # 80003280 <bunpin>
    brelse(lbuf);
    8000415e:	854a                	mv	a0,s2
    80004160:	fffff097          	auipc	ra,0xfffff
    80004164:	046080e7          	jalr	70(ra) # 800031a6 <brelse>
    brelse(dbuf);
    80004168:	8526                	mv	a0,s1
    8000416a:	fffff097          	auipc	ra,0xfffff
    8000416e:	03c080e7          	jalr	60(ra) # 800031a6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004172:	2a05                	addiw	s4,s4,1
    80004174:	0a91                	addi	s5,s5,4
    80004176:	02c9a783          	lw	a5,44(s3)
    8000417a:	f8fa49e3          	blt	s4,a5,8000410c <install_trans+0x30>
}
    8000417e:	70e2                	ld	ra,56(sp)
    80004180:	7442                	ld	s0,48(sp)
    80004182:	74a2                	ld	s1,40(sp)
    80004184:	7902                	ld	s2,32(sp)
    80004186:	69e2                	ld	s3,24(sp)
    80004188:	6a42                	ld	s4,16(sp)
    8000418a:	6aa2                	ld	s5,8(sp)
    8000418c:	6121                	addi	sp,sp,64
    8000418e:	8082                	ret
    80004190:	8082                	ret

0000000080004192 <initlog>:
{
    80004192:	7179                	addi	sp,sp,-48
    80004194:	f406                	sd	ra,40(sp)
    80004196:	f022                	sd	s0,32(sp)
    80004198:	ec26                	sd	s1,24(sp)
    8000419a:	e84a                	sd	s2,16(sp)
    8000419c:	e44e                	sd	s3,8(sp)
    8000419e:	1800                	addi	s0,sp,48
    800041a0:	892a                	mv	s2,a0
    800041a2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041a4:	0001e497          	auipc	s1,0x1e
    800041a8:	96448493          	addi	s1,s1,-1692 # 80021b08 <log>
    800041ac:	00004597          	auipc	a1,0x4
    800041b0:	67c58593          	addi	a1,a1,1660 # 80008828 <sysnames+0x1e8>
    800041b4:	8526                	mv	a0,s1
    800041b6:	ffffd097          	auipc	ra,0xffffd
    800041ba:	a14080e7          	jalr	-1516(ra) # 80000bca <initlock>
  log.start = sb->logstart;
    800041be:	0149a583          	lw	a1,20(s3)
    800041c2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041c4:	0109a783          	lw	a5,16(s3)
    800041c8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041ca:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041ce:	854a                	mv	a0,s2
    800041d0:	fffff097          	auipc	ra,0xfffff
    800041d4:	ea6080e7          	jalr	-346(ra) # 80003076 <bread>
  log.lh.n = lh->n;
    800041d8:	4d3c                	lw	a5,88(a0)
    800041da:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041dc:	02f05563          	blez	a5,80004206 <initlog+0x74>
    800041e0:	05c50713          	addi	a4,a0,92
    800041e4:	0001e697          	auipc	a3,0x1e
    800041e8:	95468693          	addi	a3,a3,-1708 # 80021b38 <log+0x30>
    800041ec:	37fd                	addiw	a5,a5,-1
    800041ee:	1782                	slli	a5,a5,0x20
    800041f0:	9381                	srli	a5,a5,0x20
    800041f2:	078a                	slli	a5,a5,0x2
    800041f4:	06050613          	addi	a2,a0,96
    800041f8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041fa:	4310                	lw	a2,0(a4)
    800041fc:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041fe:	0711                	addi	a4,a4,4
    80004200:	0691                	addi	a3,a3,4
    80004202:	fef71ce3          	bne	a4,a5,800041fa <initlog+0x68>
  brelse(buf);
    80004206:	fffff097          	auipc	ra,0xfffff
    8000420a:	fa0080e7          	jalr	-96(ra) # 800031a6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000420e:	00000097          	auipc	ra,0x0
    80004212:	ece080e7          	jalr	-306(ra) # 800040dc <install_trans>
  log.lh.n = 0;
    80004216:	0001e797          	auipc	a5,0x1e
    8000421a:	9007af23          	sw	zero,-1762(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    8000421e:	00000097          	auipc	ra,0x0
    80004222:	e44080e7          	jalr	-444(ra) # 80004062 <write_head>
}
    80004226:	70a2                	ld	ra,40(sp)
    80004228:	7402                	ld	s0,32(sp)
    8000422a:	64e2                	ld	s1,24(sp)
    8000422c:	6942                	ld	s2,16(sp)
    8000422e:	69a2                	ld	s3,8(sp)
    80004230:	6145                	addi	sp,sp,48
    80004232:	8082                	ret

0000000080004234 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004234:	1101                	addi	sp,sp,-32
    80004236:	ec06                	sd	ra,24(sp)
    80004238:	e822                	sd	s0,16(sp)
    8000423a:	e426                	sd	s1,8(sp)
    8000423c:	e04a                	sd	s2,0(sp)
    8000423e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004240:	0001e517          	auipc	a0,0x1e
    80004244:	8c850513          	addi	a0,a0,-1848 # 80021b08 <log>
    80004248:	ffffd097          	auipc	ra,0xffffd
    8000424c:	a12080e7          	jalr	-1518(ra) # 80000c5a <acquire>
  while(1){
    if(log.committing){
    80004250:	0001e497          	auipc	s1,0x1e
    80004254:	8b848493          	addi	s1,s1,-1864 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004258:	4979                	li	s2,30
    8000425a:	a039                	j	80004268 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000425c:	85a6                	mv	a1,s1
    8000425e:	8526                	mv	a0,s1
    80004260:	ffffe097          	auipc	ra,0xffffe
    80004264:	0c8080e7          	jalr	200(ra) # 80002328 <sleep>
    if(log.committing){
    80004268:	50dc                	lw	a5,36(s1)
    8000426a:	fbed                	bnez	a5,8000425c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000426c:	509c                	lw	a5,32(s1)
    8000426e:	0017871b          	addiw	a4,a5,1
    80004272:	0007069b          	sext.w	a3,a4
    80004276:	0027179b          	slliw	a5,a4,0x2
    8000427a:	9fb9                	addw	a5,a5,a4
    8000427c:	0017979b          	slliw	a5,a5,0x1
    80004280:	54d8                	lw	a4,44(s1)
    80004282:	9fb9                	addw	a5,a5,a4
    80004284:	00f95963          	bge	s2,a5,80004296 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004288:	85a6                	mv	a1,s1
    8000428a:	8526                	mv	a0,s1
    8000428c:	ffffe097          	auipc	ra,0xffffe
    80004290:	09c080e7          	jalr	156(ra) # 80002328 <sleep>
    80004294:	bfd1                	j	80004268 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004296:	0001e517          	auipc	a0,0x1e
    8000429a:	87250513          	addi	a0,a0,-1934 # 80021b08 <log>
    8000429e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042a0:	ffffd097          	auipc	ra,0xffffd
    800042a4:	a6e080e7          	jalr	-1426(ra) # 80000d0e <release>
      break;
    }
  }
}
    800042a8:	60e2                	ld	ra,24(sp)
    800042aa:	6442                	ld	s0,16(sp)
    800042ac:	64a2                	ld	s1,8(sp)
    800042ae:	6902                	ld	s2,0(sp)
    800042b0:	6105                	addi	sp,sp,32
    800042b2:	8082                	ret

00000000800042b4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042b4:	7139                	addi	sp,sp,-64
    800042b6:	fc06                	sd	ra,56(sp)
    800042b8:	f822                	sd	s0,48(sp)
    800042ba:	f426                	sd	s1,40(sp)
    800042bc:	f04a                	sd	s2,32(sp)
    800042be:	ec4e                	sd	s3,24(sp)
    800042c0:	e852                	sd	s4,16(sp)
    800042c2:	e456                	sd	s5,8(sp)
    800042c4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042c6:	0001e497          	auipc	s1,0x1e
    800042ca:	84248493          	addi	s1,s1,-1982 # 80021b08 <log>
    800042ce:	8526                	mv	a0,s1
    800042d0:	ffffd097          	auipc	ra,0xffffd
    800042d4:	98a080e7          	jalr	-1654(ra) # 80000c5a <acquire>
  log.outstanding -= 1;
    800042d8:	509c                	lw	a5,32(s1)
    800042da:	37fd                	addiw	a5,a5,-1
    800042dc:	0007891b          	sext.w	s2,a5
    800042e0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042e2:	50dc                	lw	a5,36(s1)
    800042e4:	efb9                	bnez	a5,80004342 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042e6:	06091663          	bnez	s2,80004352 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042ea:	0001e497          	auipc	s1,0x1e
    800042ee:	81e48493          	addi	s1,s1,-2018 # 80021b08 <log>
    800042f2:	4785                	li	a5,1
    800042f4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042f6:	8526                	mv	a0,s1
    800042f8:	ffffd097          	auipc	ra,0xffffd
    800042fc:	a16080e7          	jalr	-1514(ra) # 80000d0e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004300:	54dc                	lw	a5,44(s1)
    80004302:	06f04763          	bgtz	a5,80004370 <end_op+0xbc>
    acquire(&log.lock);
    80004306:	0001e497          	auipc	s1,0x1e
    8000430a:	80248493          	addi	s1,s1,-2046 # 80021b08 <log>
    8000430e:	8526                	mv	a0,s1
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	94a080e7          	jalr	-1718(ra) # 80000c5a <acquire>
    log.committing = 0;
    80004318:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000431c:	8526                	mv	a0,s1
    8000431e:	ffffe097          	auipc	ra,0xffffe
    80004322:	190080e7          	jalr	400(ra) # 800024ae <wakeup>
    release(&log.lock);
    80004326:	8526                	mv	a0,s1
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	9e6080e7          	jalr	-1562(ra) # 80000d0e <release>
}
    80004330:	70e2                	ld	ra,56(sp)
    80004332:	7442                	ld	s0,48(sp)
    80004334:	74a2                	ld	s1,40(sp)
    80004336:	7902                	ld	s2,32(sp)
    80004338:	69e2                	ld	s3,24(sp)
    8000433a:	6a42                	ld	s4,16(sp)
    8000433c:	6aa2                	ld	s5,8(sp)
    8000433e:	6121                	addi	sp,sp,64
    80004340:	8082                	ret
    panic("log.committing");
    80004342:	00004517          	auipc	a0,0x4
    80004346:	4ee50513          	addi	a0,a0,1262 # 80008830 <sysnames+0x1f0>
    8000434a:	ffffc097          	auipc	ra,0xffffc
    8000434e:	1fe080e7          	jalr	510(ra) # 80000548 <panic>
    wakeup(&log);
    80004352:	0001d497          	auipc	s1,0x1d
    80004356:	7b648493          	addi	s1,s1,1974 # 80021b08 <log>
    8000435a:	8526                	mv	a0,s1
    8000435c:	ffffe097          	auipc	ra,0xffffe
    80004360:	152080e7          	jalr	338(ra) # 800024ae <wakeup>
  release(&log.lock);
    80004364:	8526                	mv	a0,s1
    80004366:	ffffd097          	auipc	ra,0xffffd
    8000436a:	9a8080e7          	jalr	-1624(ra) # 80000d0e <release>
  if(do_commit){
    8000436e:	b7c9                	j	80004330 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004370:	0001da97          	auipc	s5,0x1d
    80004374:	7c8a8a93          	addi	s5,s5,1992 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004378:	0001da17          	auipc	s4,0x1d
    8000437c:	790a0a13          	addi	s4,s4,1936 # 80021b08 <log>
    80004380:	018a2583          	lw	a1,24(s4)
    80004384:	012585bb          	addw	a1,a1,s2
    80004388:	2585                	addiw	a1,a1,1
    8000438a:	028a2503          	lw	a0,40(s4)
    8000438e:	fffff097          	auipc	ra,0xfffff
    80004392:	ce8080e7          	jalr	-792(ra) # 80003076 <bread>
    80004396:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004398:	000aa583          	lw	a1,0(s5)
    8000439c:	028a2503          	lw	a0,40(s4)
    800043a0:	fffff097          	auipc	ra,0xfffff
    800043a4:	cd6080e7          	jalr	-810(ra) # 80003076 <bread>
    800043a8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043aa:	40000613          	li	a2,1024
    800043ae:	05850593          	addi	a1,a0,88
    800043b2:	05848513          	addi	a0,s1,88
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	a00080e7          	jalr	-1536(ra) # 80000db6 <memmove>
    bwrite(to);  // write the log
    800043be:	8526                	mv	a0,s1
    800043c0:	fffff097          	auipc	ra,0xfffff
    800043c4:	da8080e7          	jalr	-600(ra) # 80003168 <bwrite>
    brelse(from);
    800043c8:	854e                	mv	a0,s3
    800043ca:	fffff097          	auipc	ra,0xfffff
    800043ce:	ddc080e7          	jalr	-548(ra) # 800031a6 <brelse>
    brelse(to);
    800043d2:	8526                	mv	a0,s1
    800043d4:	fffff097          	auipc	ra,0xfffff
    800043d8:	dd2080e7          	jalr	-558(ra) # 800031a6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043dc:	2905                	addiw	s2,s2,1
    800043de:	0a91                	addi	s5,s5,4
    800043e0:	02ca2783          	lw	a5,44(s4)
    800043e4:	f8f94ee3          	blt	s2,a5,80004380 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043e8:	00000097          	auipc	ra,0x0
    800043ec:	c7a080e7          	jalr	-902(ra) # 80004062 <write_head>
    install_trans(); // Now install writes to home locations
    800043f0:	00000097          	auipc	ra,0x0
    800043f4:	cec080e7          	jalr	-788(ra) # 800040dc <install_trans>
    log.lh.n = 0;
    800043f8:	0001d797          	auipc	a5,0x1d
    800043fc:	7207ae23          	sw	zero,1852(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004400:	00000097          	auipc	ra,0x0
    80004404:	c62080e7          	jalr	-926(ra) # 80004062 <write_head>
    80004408:	bdfd                	j	80004306 <end_op+0x52>

000000008000440a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000440a:	1101                	addi	sp,sp,-32
    8000440c:	ec06                	sd	ra,24(sp)
    8000440e:	e822                	sd	s0,16(sp)
    80004410:	e426                	sd	s1,8(sp)
    80004412:	e04a                	sd	s2,0(sp)
    80004414:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004416:	0001d717          	auipc	a4,0x1d
    8000441a:	71e72703          	lw	a4,1822(a4) # 80021b34 <log+0x2c>
    8000441e:	47f5                	li	a5,29
    80004420:	08e7c063          	blt	a5,a4,800044a0 <log_write+0x96>
    80004424:	84aa                	mv	s1,a0
    80004426:	0001d797          	auipc	a5,0x1d
    8000442a:	6fe7a783          	lw	a5,1790(a5) # 80021b24 <log+0x1c>
    8000442e:	37fd                	addiw	a5,a5,-1
    80004430:	06f75863          	bge	a4,a5,800044a0 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004434:	0001d797          	auipc	a5,0x1d
    80004438:	6f47a783          	lw	a5,1780(a5) # 80021b28 <log+0x20>
    8000443c:	06f05a63          	blez	a5,800044b0 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004440:	0001d917          	auipc	s2,0x1d
    80004444:	6c890913          	addi	s2,s2,1736 # 80021b08 <log>
    80004448:	854a                	mv	a0,s2
    8000444a:	ffffd097          	auipc	ra,0xffffd
    8000444e:	810080e7          	jalr	-2032(ra) # 80000c5a <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004452:	02c92603          	lw	a2,44(s2)
    80004456:	06c05563          	blez	a2,800044c0 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000445a:	44cc                	lw	a1,12(s1)
    8000445c:	0001d717          	auipc	a4,0x1d
    80004460:	6dc70713          	addi	a4,a4,1756 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004464:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004466:	4314                	lw	a3,0(a4)
    80004468:	04b68d63          	beq	a3,a1,800044c2 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000446c:	2785                	addiw	a5,a5,1
    8000446e:	0711                	addi	a4,a4,4
    80004470:	fec79be3          	bne	a5,a2,80004466 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004474:	0621                	addi	a2,a2,8
    80004476:	060a                	slli	a2,a2,0x2
    80004478:	0001d797          	auipc	a5,0x1d
    8000447c:	69078793          	addi	a5,a5,1680 # 80021b08 <log>
    80004480:	963e                	add	a2,a2,a5
    80004482:	44dc                	lw	a5,12(s1)
    80004484:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004486:	8526                	mv	a0,s1
    80004488:	fffff097          	auipc	ra,0xfffff
    8000448c:	dbc080e7          	jalr	-580(ra) # 80003244 <bpin>
    log.lh.n++;
    80004490:	0001d717          	auipc	a4,0x1d
    80004494:	67870713          	addi	a4,a4,1656 # 80021b08 <log>
    80004498:	575c                	lw	a5,44(a4)
    8000449a:	2785                	addiw	a5,a5,1
    8000449c:	d75c                	sw	a5,44(a4)
    8000449e:	a83d                	j	800044dc <log_write+0xd2>
    panic("too big a transaction");
    800044a0:	00004517          	auipc	a0,0x4
    800044a4:	3a050513          	addi	a0,a0,928 # 80008840 <sysnames+0x200>
    800044a8:	ffffc097          	auipc	ra,0xffffc
    800044ac:	0a0080e7          	jalr	160(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800044b0:	00004517          	auipc	a0,0x4
    800044b4:	3a850513          	addi	a0,a0,936 # 80008858 <sysnames+0x218>
    800044b8:	ffffc097          	auipc	ra,0xffffc
    800044bc:	090080e7          	jalr	144(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800044c0:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800044c2:	00878713          	addi	a4,a5,8
    800044c6:	00271693          	slli	a3,a4,0x2
    800044ca:	0001d717          	auipc	a4,0x1d
    800044ce:	63e70713          	addi	a4,a4,1598 # 80021b08 <log>
    800044d2:	9736                	add	a4,a4,a3
    800044d4:	44d4                	lw	a3,12(s1)
    800044d6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044d8:	faf607e3          	beq	a2,a5,80004486 <log_write+0x7c>
  }
  release(&log.lock);
    800044dc:	0001d517          	auipc	a0,0x1d
    800044e0:	62c50513          	addi	a0,a0,1580 # 80021b08 <log>
    800044e4:	ffffd097          	auipc	ra,0xffffd
    800044e8:	82a080e7          	jalr	-2006(ra) # 80000d0e <release>
}
    800044ec:	60e2                	ld	ra,24(sp)
    800044ee:	6442                	ld	s0,16(sp)
    800044f0:	64a2                	ld	s1,8(sp)
    800044f2:	6902                	ld	s2,0(sp)
    800044f4:	6105                	addi	sp,sp,32
    800044f6:	8082                	ret

00000000800044f8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044f8:	1101                	addi	sp,sp,-32
    800044fa:	ec06                	sd	ra,24(sp)
    800044fc:	e822                	sd	s0,16(sp)
    800044fe:	e426                	sd	s1,8(sp)
    80004500:	e04a                	sd	s2,0(sp)
    80004502:	1000                	addi	s0,sp,32
    80004504:	84aa                	mv	s1,a0
    80004506:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004508:	00004597          	auipc	a1,0x4
    8000450c:	37058593          	addi	a1,a1,880 # 80008878 <sysnames+0x238>
    80004510:	0521                	addi	a0,a0,8
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	6b8080e7          	jalr	1720(ra) # 80000bca <initlock>
  lk->name = name;
    8000451a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000451e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004522:	0204a423          	sw	zero,40(s1)
}
    80004526:	60e2                	ld	ra,24(sp)
    80004528:	6442                	ld	s0,16(sp)
    8000452a:	64a2                	ld	s1,8(sp)
    8000452c:	6902                	ld	s2,0(sp)
    8000452e:	6105                	addi	sp,sp,32
    80004530:	8082                	ret

0000000080004532 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004532:	1101                	addi	sp,sp,-32
    80004534:	ec06                	sd	ra,24(sp)
    80004536:	e822                	sd	s0,16(sp)
    80004538:	e426                	sd	s1,8(sp)
    8000453a:	e04a                	sd	s2,0(sp)
    8000453c:	1000                	addi	s0,sp,32
    8000453e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004540:	00850913          	addi	s2,a0,8
    80004544:	854a                	mv	a0,s2
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	714080e7          	jalr	1812(ra) # 80000c5a <acquire>
  while (lk->locked) {
    8000454e:	409c                	lw	a5,0(s1)
    80004550:	cb89                	beqz	a5,80004562 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004552:	85ca                	mv	a1,s2
    80004554:	8526                	mv	a0,s1
    80004556:	ffffe097          	auipc	ra,0xffffe
    8000455a:	dd2080e7          	jalr	-558(ra) # 80002328 <sleep>
  while (lk->locked) {
    8000455e:	409c                	lw	a5,0(s1)
    80004560:	fbed                	bnez	a5,80004552 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004562:	4785                	li	a5,1
    80004564:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004566:	ffffd097          	auipc	ra,0xffffd
    8000456a:	5aa080e7          	jalr	1450(ra) # 80001b10 <myproc>
    8000456e:	5d1c                	lw	a5,56(a0)
    80004570:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004572:	854a                	mv	a0,s2
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	79a080e7          	jalr	1946(ra) # 80000d0e <release>
}
    8000457c:	60e2                	ld	ra,24(sp)
    8000457e:	6442                	ld	s0,16(sp)
    80004580:	64a2                	ld	s1,8(sp)
    80004582:	6902                	ld	s2,0(sp)
    80004584:	6105                	addi	sp,sp,32
    80004586:	8082                	ret

0000000080004588 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004588:	1101                	addi	sp,sp,-32
    8000458a:	ec06                	sd	ra,24(sp)
    8000458c:	e822                	sd	s0,16(sp)
    8000458e:	e426                	sd	s1,8(sp)
    80004590:	e04a                	sd	s2,0(sp)
    80004592:	1000                	addi	s0,sp,32
    80004594:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004596:	00850913          	addi	s2,a0,8
    8000459a:	854a                	mv	a0,s2
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	6be080e7          	jalr	1726(ra) # 80000c5a <acquire>
  lk->locked = 0;
    800045a4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045a8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045ac:	8526                	mv	a0,s1
    800045ae:	ffffe097          	auipc	ra,0xffffe
    800045b2:	f00080e7          	jalr	-256(ra) # 800024ae <wakeup>
  release(&lk->lk);
    800045b6:	854a                	mv	a0,s2
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	756080e7          	jalr	1878(ra) # 80000d0e <release>
}
    800045c0:	60e2                	ld	ra,24(sp)
    800045c2:	6442                	ld	s0,16(sp)
    800045c4:	64a2                	ld	s1,8(sp)
    800045c6:	6902                	ld	s2,0(sp)
    800045c8:	6105                	addi	sp,sp,32
    800045ca:	8082                	ret

00000000800045cc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045cc:	7179                	addi	sp,sp,-48
    800045ce:	f406                	sd	ra,40(sp)
    800045d0:	f022                	sd	s0,32(sp)
    800045d2:	ec26                	sd	s1,24(sp)
    800045d4:	e84a                	sd	s2,16(sp)
    800045d6:	e44e                	sd	s3,8(sp)
    800045d8:	1800                	addi	s0,sp,48
    800045da:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045dc:	00850913          	addi	s2,a0,8
    800045e0:	854a                	mv	a0,s2
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	678080e7          	jalr	1656(ra) # 80000c5a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045ea:	409c                	lw	a5,0(s1)
    800045ec:	ef99                	bnez	a5,8000460a <holdingsleep+0x3e>
    800045ee:	4481                	li	s1,0
  release(&lk->lk);
    800045f0:	854a                	mv	a0,s2
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	71c080e7          	jalr	1820(ra) # 80000d0e <release>
  return r;
}
    800045fa:	8526                	mv	a0,s1
    800045fc:	70a2                	ld	ra,40(sp)
    800045fe:	7402                	ld	s0,32(sp)
    80004600:	64e2                	ld	s1,24(sp)
    80004602:	6942                	ld	s2,16(sp)
    80004604:	69a2                	ld	s3,8(sp)
    80004606:	6145                	addi	sp,sp,48
    80004608:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000460a:	0284a983          	lw	s3,40(s1)
    8000460e:	ffffd097          	auipc	ra,0xffffd
    80004612:	502080e7          	jalr	1282(ra) # 80001b10 <myproc>
    80004616:	5d04                	lw	s1,56(a0)
    80004618:	413484b3          	sub	s1,s1,s3
    8000461c:	0014b493          	seqz	s1,s1
    80004620:	bfc1                	j	800045f0 <holdingsleep+0x24>

0000000080004622 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004622:	1141                	addi	sp,sp,-16
    80004624:	e406                	sd	ra,8(sp)
    80004626:	e022                	sd	s0,0(sp)
    80004628:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000462a:	00004597          	auipc	a1,0x4
    8000462e:	25e58593          	addi	a1,a1,606 # 80008888 <sysnames+0x248>
    80004632:	0001d517          	auipc	a0,0x1d
    80004636:	61e50513          	addi	a0,a0,1566 # 80021c50 <ftable>
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	590080e7          	jalr	1424(ra) # 80000bca <initlock>
}
    80004642:	60a2                	ld	ra,8(sp)
    80004644:	6402                	ld	s0,0(sp)
    80004646:	0141                	addi	sp,sp,16
    80004648:	8082                	ret

000000008000464a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000464a:	1101                	addi	sp,sp,-32
    8000464c:	ec06                	sd	ra,24(sp)
    8000464e:	e822                	sd	s0,16(sp)
    80004650:	e426                	sd	s1,8(sp)
    80004652:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004654:	0001d517          	auipc	a0,0x1d
    80004658:	5fc50513          	addi	a0,a0,1532 # 80021c50 <ftable>
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	5fe080e7          	jalr	1534(ra) # 80000c5a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004664:	0001d497          	auipc	s1,0x1d
    80004668:	60448493          	addi	s1,s1,1540 # 80021c68 <ftable+0x18>
    8000466c:	0001e717          	auipc	a4,0x1e
    80004670:	59c70713          	addi	a4,a4,1436 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    80004674:	40dc                	lw	a5,4(s1)
    80004676:	cf99                	beqz	a5,80004694 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004678:	02848493          	addi	s1,s1,40
    8000467c:	fee49ce3          	bne	s1,a4,80004674 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004680:	0001d517          	auipc	a0,0x1d
    80004684:	5d050513          	addi	a0,a0,1488 # 80021c50 <ftable>
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	686080e7          	jalr	1670(ra) # 80000d0e <release>
  return 0;
    80004690:	4481                	li	s1,0
    80004692:	a819                	j	800046a8 <filealloc+0x5e>
      f->ref = 1;
    80004694:	4785                	li	a5,1
    80004696:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004698:	0001d517          	auipc	a0,0x1d
    8000469c:	5b850513          	addi	a0,a0,1464 # 80021c50 <ftable>
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	66e080e7          	jalr	1646(ra) # 80000d0e <release>
}
    800046a8:	8526                	mv	a0,s1
    800046aa:	60e2                	ld	ra,24(sp)
    800046ac:	6442                	ld	s0,16(sp)
    800046ae:	64a2                	ld	s1,8(sp)
    800046b0:	6105                	addi	sp,sp,32
    800046b2:	8082                	ret

00000000800046b4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046b4:	1101                	addi	sp,sp,-32
    800046b6:	ec06                	sd	ra,24(sp)
    800046b8:	e822                	sd	s0,16(sp)
    800046ba:	e426                	sd	s1,8(sp)
    800046bc:	1000                	addi	s0,sp,32
    800046be:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046c0:	0001d517          	auipc	a0,0x1d
    800046c4:	59050513          	addi	a0,a0,1424 # 80021c50 <ftable>
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	592080e7          	jalr	1426(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    800046d0:	40dc                	lw	a5,4(s1)
    800046d2:	02f05263          	blez	a5,800046f6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046d6:	2785                	addiw	a5,a5,1
    800046d8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046da:	0001d517          	auipc	a0,0x1d
    800046de:	57650513          	addi	a0,a0,1398 # 80021c50 <ftable>
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	62c080e7          	jalr	1580(ra) # 80000d0e <release>
  return f;
}
    800046ea:	8526                	mv	a0,s1
    800046ec:	60e2                	ld	ra,24(sp)
    800046ee:	6442                	ld	s0,16(sp)
    800046f0:	64a2                	ld	s1,8(sp)
    800046f2:	6105                	addi	sp,sp,32
    800046f4:	8082                	ret
    panic("filedup");
    800046f6:	00004517          	auipc	a0,0x4
    800046fa:	19a50513          	addi	a0,a0,410 # 80008890 <sysnames+0x250>
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	e4a080e7          	jalr	-438(ra) # 80000548 <panic>

0000000080004706 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004706:	7139                	addi	sp,sp,-64
    80004708:	fc06                	sd	ra,56(sp)
    8000470a:	f822                	sd	s0,48(sp)
    8000470c:	f426                	sd	s1,40(sp)
    8000470e:	f04a                	sd	s2,32(sp)
    80004710:	ec4e                	sd	s3,24(sp)
    80004712:	e852                	sd	s4,16(sp)
    80004714:	e456                	sd	s5,8(sp)
    80004716:	0080                	addi	s0,sp,64
    80004718:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000471a:	0001d517          	auipc	a0,0x1d
    8000471e:	53650513          	addi	a0,a0,1334 # 80021c50 <ftable>
    80004722:	ffffc097          	auipc	ra,0xffffc
    80004726:	538080e7          	jalr	1336(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    8000472a:	40dc                	lw	a5,4(s1)
    8000472c:	06f05163          	blez	a5,8000478e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004730:	37fd                	addiw	a5,a5,-1
    80004732:	0007871b          	sext.w	a4,a5
    80004736:	c0dc                	sw	a5,4(s1)
    80004738:	06e04363          	bgtz	a4,8000479e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000473c:	0004a903          	lw	s2,0(s1)
    80004740:	0094ca83          	lbu	s5,9(s1)
    80004744:	0104ba03          	ld	s4,16(s1)
    80004748:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000474c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004750:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004754:	0001d517          	auipc	a0,0x1d
    80004758:	4fc50513          	addi	a0,a0,1276 # 80021c50 <ftable>
    8000475c:	ffffc097          	auipc	ra,0xffffc
    80004760:	5b2080e7          	jalr	1458(ra) # 80000d0e <release>

  if(ff.type == FD_PIPE){
    80004764:	4785                	li	a5,1
    80004766:	04f90d63          	beq	s2,a5,800047c0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000476a:	3979                	addiw	s2,s2,-2
    8000476c:	4785                	li	a5,1
    8000476e:	0527e063          	bltu	a5,s2,800047ae <fileclose+0xa8>
    begin_op();
    80004772:	00000097          	auipc	ra,0x0
    80004776:	ac2080e7          	jalr	-1342(ra) # 80004234 <begin_op>
    iput(ff.ip);
    8000477a:	854e                	mv	a0,s3
    8000477c:	fffff097          	auipc	ra,0xfffff
    80004780:	2b6080e7          	jalr	694(ra) # 80003a32 <iput>
    end_op();
    80004784:	00000097          	auipc	ra,0x0
    80004788:	b30080e7          	jalr	-1232(ra) # 800042b4 <end_op>
    8000478c:	a00d                	j	800047ae <fileclose+0xa8>
    panic("fileclose");
    8000478e:	00004517          	auipc	a0,0x4
    80004792:	10a50513          	addi	a0,a0,266 # 80008898 <sysnames+0x258>
    80004796:	ffffc097          	auipc	ra,0xffffc
    8000479a:	db2080e7          	jalr	-590(ra) # 80000548 <panic>
    release(&ftable.lock);
    8000479e:	0001d517          	auipc	a0,0x1d
    800047a2:	4b250513          	addi	a0,a0,1202 # 80021c50 <ftable>
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	568080e7          	jalr	1384(ra) # 80000d0e <release>
  }
}
    800047ae:	70e2                	ld	ra,56(sp)
    800047b0:	7442                	ld	s0,48(sp)
    800047b2:	74a2                	ld	s1,40(sp)
    800047b4:	7902                	ld	s2,32(sp)
    800047b6:	69e2                	ld	s3,24(sp)
    800047b8:	6a42                	ld	s4,16(sp)
    800047ba:	6aa2                	ld	s5,8(sp)
    800047bc:	6121                	addi	sp,sp,64
    800047be:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047c0:	85d6                	mv	a1,s5
    800047c2:	8552                	mv	a0,s4
    800047c4:	00000097          	auipc	ra,0x0
    800047c8:	372080e7          	jalr	882(ra) # 80004b36 <pipeclose>
    800047cc:	b7cd                	j	800047ae <fileclose+0xa8>

00000000800047ce <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047ce:	715d                	addi	sp,sp,-80
    800047d0:	e486                	sd	ra,72(sp)
    800047d2:	e0a2                	sd	s0,64(sp)
    800047d4:	fc26                	sd	s1,56(sp)
    800047d6:	f84a                	sd	s2,48(sp)
    800047d8:	f44e                	sd	s3,40(sp)
    800047da:	0880                	addi	s0,sp,80
    800047dc:	84aa                	mv	s1,a0
    800047de:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047e0:	ffffd097          	auipc	ra,0xffffd
    800047e4:	330080e7          	jalr	816(ra) # 80001b10 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047e8:	409c                	lw	a5,0(s1)
    800047ea:	37f9                	addiw	a5,a5,-2
    800047ec:	4705                	li	a4,1
    800047ee:	04f76763          	bltu	a4,a5,8000483c <filestat+0x6e>
    800047f2:	892a                	mv	s2,a0
    ilock(f->ip);
    800047f4:	6c88                	ld	a0,24(s1)
    800047f6:	fffff097          	auipc	ra,0xfffff
    800047fa:	082080e7          	jalr	130(ra) # 80003878 <ilock>
    stati(f->ip, &st);
    800047fe:	fb840593          	addi	a1,s0,-72
    80004802:	6c88                	ld	a0,24(s1)
    80004804:	fffff097          	auipc	ra,0xfffff
    80004808:	2fe080e7          	jalr	766(ra) # 80003b02 <stati>
    iunlock(f->ip);
    8000480c:	6c88                	ld	a0,24(s1)
    8000480e:	fffff097          	auipc	ra,0xfffff
    80004812:	12c080e7          	jalr	300(ra) # 8000393a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004816:	46e1                	li	a3,24
    80004818:	fb840613          	addi	a2,s0,-72
    8000481c:	85ce                	mv	a1,s3
    8000481e:	05093503          	ld	a0,80(s2)
    80004822:	ffffd097          	auipc	ra,0xffffd
    80004826:	f02080e7          	jalr	-254(ra) # 80001724 <copyout>
    8000482a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000482e:	60a6                	ld	ra,72(sp)
    80004830:	6406                	ld	s0,64(sp)
    80004832:	74e2                	ld	s1,56(sp)
    80004834:	7942                	ld	s2,48(sp)
    80004836:	79a2                	ld	s3,40(sp)
    80004838:	6161                	addi	sp,sp,80
    8000483a:	8082                	ret
  return -1;
    8000483c:	557d                	li	a0,-1
    8000483e:	bfc5                	j	8000482e <filestat+0x60>

0000000080004840 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004840:	7179                	addi	sp,sp,-48
    80004842:	f406                	sd	ra,40(sp)
    80004844:	f022                	sd	s0,32(sp)
    80004846:	ec26                	sd	s1,24(sp)
    80004848:	e84a                	sd	s2,16(sp)
    8000484a:	e44e                	sd	s3,8(sp)
    8000484c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000484e:	00854783          	lbu	a5,8(a0)
    80004852:	c3d5                	beqz	a5,800048f6 <fileread+0xb6>
    80004854:	84aa                	mv	s1,a0
    80004856:	89ae                	mv	s3,a1
    80004858:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000485a:	411c                	lw	a5,0(a0)
    8000485c:	4705                	li	a4,1
    8000485e:	04e78963          	beq	a5,a4,800048b0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004862:	470d                	li	a4,3
    80004864:	04e78d63          	beq	a5,a4,800048be <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004868:	4709                	li	a4,2
    8000486a:	06e79e63          	bne	a5,a4,800048e6 <fileread+0xa6>
    ilock(f->ip);
    8000486e:	6d08                	ld	a0,24(a0)
    80004870:	fffff097          	auipc	ra,0xfffff
    80004874:	008080e7          	jalr	8(ra) # 80003878 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004878:	874a                	mv	a4,s2
    8000487a:	5094                	lw	a3,32(s1)
    8000487c:	864e                	mv	a2,s3
    8000487e:	4585                	li	a1,1
    80004880:	6c88                	ld	a0,24(s1)
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	2aa080e7          	jalr	682(ra) # 80003b2c <readi>
    8000488a:	892a                	mv	s2,a0
    8000488c:	00a05563          	blez	a0,80004896 <fileread+0x56>
      f->off += r;
    80004890:	509c                	lw	a5,32(s1)
    80004892:	9fa9                	addw	a5,a5,a0
    80004894:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004896:	6c88                	ld	a0,24(s1)
    80004898:	fffff097          	auipc	ra,0xfffff
    8000489c:	0a2080e7          	jalr	162(ra) # 8000393a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048a0:	854a                	mv	a0,s2
    800048a2:	70a2                	ld	ra,40(sp)
    800048a4:	7402                	ld	s0,32(sp)
    800048a6:	64e2                	ld	s1,24(sp)
    800048a8:	6942                	ld	s2,16(sp)
    800048aa:	69a2                	ld	s3,8(sp)
    800048ac:	6145                	addi	sp,sp,48
    800048ae:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048b0:	6908                	ld	a0,16(a0)
    800048b2:	00000097          	auipc	ra,0x0
    800048b6:	418080e7          	jalr	1048(ra) # 80004cca <piperead>
    800048ba:	892a                	mv	s2,a0
    800048bc:	b7d5                	j	800048a0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048be:	02451783          	lh	a5,36(a0)
    800048c2:	03079693          	slli	a3,a5,0x30
    800048c6:	92c1                	srli	a3,a3,0x30
    800048c8:	4725                	li	a4,9
    800048ca:	02d76863          	bltu	a4,a3,800048fa <fileread+0xba>
    800048ce:	0792                	slli	a5,a5,0x4
    800048d0:	0001d717          	auipc	a4,0x1d
    800048d4:	2e070713          	addi	a4,a4,736 # 80021bb0 <devsw>
    800048d8:	97ba                	add	a5,a5,a4
    800048da:	639c                	ld	a5,0(a5)
    800048dc:	c38d                	beqz	a5,800048fe <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048de:	4505                	li	a0,1
    800048e0:	9782                	jalr	a5
    800048e2:	892a                	mv	s2,a0
    800048e4:	bf75                	j	800048a0 <fileread+0x60>
    panic("fileread");
    800048e6:	00004517          	auipc	a0,0x4
    800048ea:	fc250513          	addi	a0,a0,-62 # 800088a8 <sysnames+0x268>
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	c5a080e7          	jalr	-934(ra) # 80000548 <panic>
    return -1;
    800048f6:	597d                	li	s2,-1
    800048f8:	b765                	j	800048a0 <fileread+0x60>
      return -1;
    800048fa:	597d                	li	s2,-1
    800048fc:	b755                	j	800048a0 <fileread+0x60>
    800048fe:	597d                	li	s2,-1
    80004900:	b745                	j	800048a0 <fileread+0x60>

0000000080004902 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004902:	00954783          	lbu	a5,9(a0)
    80004906:	14078563          	beqz	a5,80004a50 <filewrite+0x14e>
{
    8000490a:	715d                	addi	sp,sp,-80
    8000490c:	e486                	sd	ra,72(sp)
    8000490e:	e0a2                	sd	s0,64(sp)
    80004910:	fc26                	sd	s1,56(sp)
    80004912:	f84a                	sd	s2,48(sp)
    80004914:	f44e                	sd	s3,40(sp)
    80004916:	f052                	sd	s4,32(sp)
    80004918:	ec56                	sd	s5,24(sp)
    8000491a:	e85a                	sd	s6,16(sp)
    8000491c:	e45e                	sd	s7,8(sp)
    8000491e:	e062                	sd	s8,0(sp)
    80004920:	0880                	addi	s0,sp,80
    80004922:	892a                	mv	s2,a0
    80004924:	8aae                	mv	s5,a1
    80004926:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004928:	411c                	lw	a5,0(a0)
    8000492a:	4705                	li	a4,1
    8000492c:	02e78263          	beq	a5,a4,80004950 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004930:	470d                	li	a4,3
    80004932:	02e78563          	beq	a5,a4,8000495c <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004936:	4709                	li	a4,2
    80004938:	10e79463          	bne	a5,a4,80004a40 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000493c:	0ec05e63          	blez	a2,80004a38 <filewrite+0x136>
    int i = 0;
    80004940:	4981                	li	s3,0
    80004942:	6b05                	lui	s6,0x1
    80004944:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004948:	6b85                	lui	s7,0x1
    8000494a:	c00b8b9b          	addiw	s7,s7,-1024
    8000494e:	a851                	j	800049e2 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004950:	6908                	ld	a0,16(a0)
    80004952:	00000097          	auipc	ra,0x0
    80004956:	254080e7          	jalr	596(ra) # 80004ba6 <pipewrite>
    8000495a:	a85d                	j	80004a10 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000495c:	02451783          	lh	a5,36(a0)
    80004960:	03079693          	slli	a3,a5,0x30
    80004964:	92c1                	srli	a3,a3,0x30
    80004966:	4725                	li	a4,9
    80004968:	0ed76663          	bltu	a4,a3,80004a54 <filewrite+0x152>
    8000496c:	0792                	slli	a5,a5,0x4
    8000496e:	0001d717          	auipc	a4,0x1d
    80004972:	24270713          	addi	a4,a4,578 # 80021bb0 <devsw>
    80004976:	97ba                	add	a5,a5,a4
    80004978:	679c                	ld	a5,8(a5)
    8000497a:	cff9                	beqz	a5,80004a58 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    8000497c:	4505                	li	a0,1
    8000497e:	9782                	jalr	a5
    80004980:	a841                	j	80004a10 <filewrite+0x10e>
    80004982:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004986:	00000097          	auipc	ra,0x0
    8000498a:	8ae080e7          	jalr	-1874(ra) # 80004234 <begin_op>
      ilock(f->ip);
    8000498e:	01893503          	ld	a0,24(s2)
    80004992:	fffff097          	auipc	ra,0xfffff
    80004996:	ee6080e7          	jalr	-282(ra) # 80003878 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000499a:	8762                	mv	a4,s8
    8000499c:	02092683          	lw	a3,32(s2)
    800049a0:	01598633          	add	a2,s3,s5
    800049a4:	4585                	li	a1,1
    800049a6:	01893503          	ld	a0,24(s2)
    800049aa:	fffff097          	auipc	ra,0xfffff
    800049ae:	278080e7          	jalr	632(ra) # 80003c22 <writei>
    800049b2:	84aa                	mv	s1,a0
    800049b4:	02a05f63          	blez	a0,800049f2 <filewrite+0xf0>
        f->off += r;
    800049b8:	02092783          	lw	a5,32(s2)
    800049bc:	9fa9                	addw	a5,a5,a0
    800049be:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049c2:	01893503          	ld	a0,24(s2)
    800049c6:	fffff097          	auipc	ra,0xfffff
    800049ca:	f74080e7          	jalr	-140(ra) # 8000393a <iunlock>
      end_op();
    800049ce:	00000097          	auipc	ra,0x0
    800049d2:	8e6080e7          	jalr	-1818(ra) # 800042b4 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800049d6:	049c1963          	bne	s8,s1,80004a28 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800049da:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049de:	0349d663          	bge	s3,s4,80004a0a <filewrite+0x108>
      int n1 = n - i;
    800049e2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049e6:	84be                	mv	s1,a5
    800049e8:	2781                	sext.w	a5,a5
    800049ea:	f8fb5ce3          	bge	s6,a5,80004982 <filewrite+0x80>
    800049ee:	84de                	mv	s1,s7
    800049f0:	bf49                	j	80004982 <filewrite+0x80>
      iunlock(f->ip);
    800049f2:	01893503          	ld	a0,24(s2)
    800049f6:	fffff097          	auipc	ra,0xfffff
    800049fa:	f44080e7          	jalr	-188(ra) # 8000393a <iunlock>
      end_op();
    800049fe:	00000097          	auipc	ra,0x0
    80004a02:	8b6080e7          	jalr	-1866(ra) # 800042b4 <end_op>
      if(r < 0)
    80004a06:	fc04d8e3          	bgez	s1,800049d6 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004a0a:	8552                	mv	a0,s4
    80004a0c:	033a1863          	bne	s4,s3,80004a3c <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a10:	60a6                	ld	ra,72(sp)
    80004a12:	6406                	ld	s0,64(sp)
    80004a14:	74e2                	ld	s1,56(sp)
    80004a16:	7942                	ld	s2,48(sp)
    80004a18:	79a2                	ld	s3,40(sp)
    80004a1a:	7a02                	ld	s4,32(sp)
    80004a1c:	6ae2                	ld	s5,24(sp)
    80004a1e:	6b42                	ld	s6,16(sp)
    80004a20:	6ba2                	ld	s7,8(sp)
    80004a22:	6c02                	ld	s8,0(sp)
    80004a24:	6161                	addi	sp,sp,80
    80004a26:	8082                	ret
        panic("short filewrite");
    80004a28:	00004517          	auipc	a0,0x4
    80004a2c:	e9050513          	addi	a0,a0,-368 # 800088b8 <sysnames+0x278>
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	b18080e7          	jalr	-1256(ra) # 80000548 <panic>
    int i = 0;
    80004a38:	4981                	li	s3,0
    80004a3a:	bfc1                	j	80004a0a <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004a3c:	557d                	li	a0,-1
    80004a3e:	bfc9                	j	80004a10 <filewrite+0x10e>
    panic("filewrite");
    80004a40:	00004517          	auipc	a0,0x4
    80004a44:	e8850513          	addi	a0,a0,-376 # 800088c8 <sysnames+0x288>
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	b00080e7          	jalr	-1280(ra) # 80000548 <panic>
    return -1;
    80004a50:	557d                	li	a0,-1
}
    80004a52:	8082                	ret
      return -1;
    80004a54:	557d                	li	a0,-1
    80004a56:	bf6d                	j	80004a10 <filewrite+0x10e>
    80004a58:	557d                	li	a0,-1
    80004a5a:	bf5d                	j	80004a10 <filewrite+0x10e>

0000000080004a5c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a5c:	7179                	addi	sp,sp,-48
    80004a5e:	f406                	sd	ra,40(sp)
    80004a60:	f022                	sd	s0,32(sp)
    80004a62:	ec26                	sd	s1,24(sp)
    80004a64:	e84a                	sd	s2,16(sp)
    80004a66:	e44e                	sd	s3,8(sp)
    80004a68:	e052                	sd	s4,0(sp)
    80004a6a:	1800                	addi	s0,sp,48
    80004a6c:	84aa                	mv	s1,a0
    80004a6e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a70:	0005b023          	sd	zero,0(a1)
    80004a74:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a78:	00000097          	auipc	ra,0x0
    80004a7c:	bd2080e7          	jalr	-1070(ra) # 8000464a <filealloc>
    80004a80:	e088                	sd	a0,0(s1)
    80004a82:	c551                	beqz	a0,80004b0e <pipealloc+0xb2>
    80004a84:	00000097          	auipc	ra,0x0
    80004a88:	bc6080e7          	jalr	-1082(ra) # 8000464a <filealloc>
    80004a8c:	00aa3023          	sd	a0,0(s4)
    80004a90:	c92d                	beqz	a0,80004b02 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	08e080e7          	jalr	142(ra) # 80000b20 <kalloc>
    80004a9a:	892a                	mv	s2,a0
    80004a9c:	c125                	beqz	a0,80004afc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a9e:	4985                	li	s3,1
    80004aa0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004aa4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004aa8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004aac:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ab0:	00004597          	auipc	a1,0x4
    80004ab4:	a2058593          	addi	a1,a1,-1504 # 800084d0 <states.1717+0x198>
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	112080e7          	jalr	274(ra) # 80000bca <initlock>
  (*f0)->type = FD_PIPE;
    80004ac0:	609c                	ld	a5,0(s1)
    80004ac2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ac6:	609c                	ld	a5,0(s1)
    80004ac8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004acc:	609c                	ld	a5,0(s1)
    80004ace:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ad2:	609c                	ld	a5,0(s1)
    80004ad4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ad8:	000a3783          	ld	a5,0(s4)
    80004adc:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ae0:	000a3783          	ld	a5,0(s4)
    80004ae4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ae8:	000a3783          	ld	a5,0(s4)
    80004aec:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004af0:	000a3783          	ld	a5,0(s4)
    80004af4:	0127b823          	sd	s2,16(a5)
  return 0;
    80004af8:	4501                	li	a0,0
    80004afa:	a025                	j	80004b22 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004afc:	6088                	ld	a0,0(s1)
    80004afe:	e501                	bnez	a0,80004b06 <pipealloc+0xaa>
    80004b00:	a039                	j	80004b0e <pipealloc+0xb2>
    80004b02:	6088                	ld	a0,0(s1)
    80004b04:	c51d                	beqz	a0,80004b32 <pipealloc+0xd6>
    fileclose(*f0);
    80004b06:	00000097          	auipc	ra,0x0
    80004b0a:	c00080e7          	jalr	-1024(ra) # 80004706 <fileclose>
  if(*f1)
    80004b0e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b12:	557d                	li	a0,-1
  if(*f1)
    80004b14:	c799                	beqz	a5,80004b22 <pipealloc+0xc6>
    fileclose(*f1);
    80004b16:	853e                	mv	a0,a5
    80004b18:	00000097          	auipc	ra,0x0
    80004b1c:	bee080e7          	jalr	-1042(ra) # 80004706 <fileclose>
  return -1;
    80004b20:	557d                	li	a0,-1
}
    80004b22:	70a2                	ld	ra,40(sp)
    80004b24:	7402                	ld	s0,32(sp)
    80004b26:	64e2                	ld	s1,24(sp)
    80004b28:	6942                	ld	s2,16(sp)
    80004b2a:	69a2                	ld	s3,8(sp)
    80004b2c:	6a02                	ld	s4,0(sp)
    80004b2e:	6145                	addi	sp,sp,48
    80004b30:	8082                	ret
  return -1;
    80004b32:	557d                	li	a0,-1
    80004b34:	b7fd                	j	80004b22 <pipealloc+0xc6>

0000000080004b36 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b36:	1101                	addi	sp,sp,-32
    80004b38:	ec06                	sd	ra,24(sp)
    80004b3a:	e822                	sd	s0,16(sp)
    80004b3c:	e426                	sd	s1,8(sp)
    80004b3e:	e04a                	sd	s2,0(sp)
    80004b40:	1000                	addi	s0,sp,32
    80004b42:	84aa                	mv	s1,a0
    80004b44:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	114080e7          	jalr	276(ra) # 80000c5a <acquire>
  if(writable){
    80004b4e:	02090d63          	beqz	s2,80004b88 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b52:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b56:	21848513          	addi	a0,s1,536
    80004b5a:	ffffe097          	auipc	ra,0xffffe
    80004b5e:	954080e7          	jalr	-1708(ra) # 800024ae <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b62:	2204b783          	ld	a5,544(s1)
    80004b66:	eb95                	bnez	a5,80004b9a <pipeclose+0x64>
    release(&pi->lock);
    80004b68:	8526                	mv	a0,s1
    80004b6a:	ffffc097          	auipc	ra,0xffffc
    80004b6e:	1a4080e7          	jalr	420(ra) # 80000d0e <release>
    kfree((char*)pi);
    80004b72:	8526                	mv	a0,s1
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	eb0080e7          	jalr	-336(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004b7c:	60e2                	ld	ra,24(sp)
    80004b7e:	6442                	ld	s0,16(sp)
    80004b80:	64a2                	ld	s1,8(sp)
    80004b82:	6902                	ld	s2,0(sp)
    80004b84:	6105                	addi	sp,sp,32
    80004b86:	8082                	ret
    pi->readopen = 0;
    80004b88:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b8c:	21c48513          	addi	a0,s1,540
    80004b90:	ffffe097          	auipc	ra,0xffffe
    80004b94:	91e080e7          	jalr	-1762(ra) # 800024ae <wakeup>
    80004b98:	b7e9                	j	80004b62 <pipeclose+0x2c>
    release(&pi->lock);
    80004b9a:	8526                	mv	a0,s1
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	172080e7          	jalr	370(ra) # 80000d0e <release>
}
    80004ba4:	bfe1                	j	80004b7c <pipeclose+0x46>

0000000080004ba6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ba6:	7119                	addi	sp,sp,-128
    80004ba8:	fc86                	sd	ra,120(sp)
    80004baa:	f8a2                	sd	s0,112(sp)
    80004bac:	f4a6                	sd	s1,104(sp)
    80004bae:	f0ca                	sd	s2,96(sp)
    80004bb0:	ecce                	sd	s3,88(sp)
    80004bb2:	e8d2                	sd	s4,80(sp)
    80004bb4:	e4d6                	sd	s5,72(sp)
    80004bb6:	e0da                	sd	s6,64(sp)
    80004bb8:	fc5e                	sd	s7,56(sp)
    80004bba:	f862                	sd	s8,48(sp)
    80004bbc:	f466                	sd	s9,40(sp)
    80004bbe:	f06a                	sd	s10,32(sp)
    80004bc0:	ec6e                	sd	s11,24(sp)
    80004bc2:	0100                	addi	s0,sp,128
    80004bc4:	84aa                	mv	s1,a0
    80004bc6:	8cae                	mv	s9,a1
    80004bc8:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004bca:	ffffd097          	auipc	ra,0xffffd
    80004bce:	f46080e7          	jalr	-186(ra) # 80001b10 <myproc>
    80004bd2:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004bd4:	8526                	mv	a0,s1
    80004bd6:	ffffc097          	auipc	ra,0xffffc
    80004bda:	084080e7          	jalr	132(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    80004bde:	0d605963          	blez	s6,80004cb0 <pipewrite+0x10a>
    80004be2:	89a6                	mv	s3,s1
    80004be4:	3b7d                	addiw	s6,s6,-1
    80004be6:	1b02                	slli	s6,s6,0x20
    80004be8:	020b5b13          	srli	s6,s6,0x20
    80004bec:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004bee:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bf2:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bf6:	5dfd                	li	s11,-1
    80004bf8:	000b8d1b          	sext.w	s10,s7
    80004bfc:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004bfe:	2184a783          	lw	a5,536(s1)
    80004c02:	21c4a703          	lw	a4,540(s1)
    80004c06:	2007879b          	addiw	a5,a5,512
    80004c0a:	02f71b63          	bne	a4,a5,80004c40 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004c0e:	2204a783          	lw	a5,544(s1)
    80004c12:	cbad                	beqz	a5,80004c84 <pipewrite+0xde>
    80004c14:	03092783          	lw	a5,48(s2)
    80004c18:	e7b5                	bnez	a5,80004c84 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004c1a:	8556                	mv	a0,s5
    80004c1c:	ffffe097          	auipc	ra,0xffffe
    80004c20:	892080e7          	jalr	-1902(ra) # 800024ae <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c24:	85ce                	mv	a1,s3
    80004c26:	8552                	mv	a0,s4
    80004c28:	ffffd097          	auipc	ra,0xffffd
    80004c2c:	700080e7          	jalr	1792(ra) # 80002328 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c30:	2184a783          	lw	a5,536(s1)
    80004c34:	21c4a703          	lw	a4,540(s1)
    80004c38:	2007879b          	addiw	a5,a5,512
    80004c3c:	fcf709e3          	beq	a4,a5,80004c0e <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c40:	4685                	li	a3,1
    80004c42:	019b8633          	add	a2,s7,s9
    80004c46:	f8f40593          	addi	a1,s0,-113
    80004c4a:	05093503          	ld	a0,80(s2)
    80004c4e:	ffffd097          	auipc	ra,0xffffd
    80004c52:	b62080e7          	jalr	-1182(ra) # 800017b0 <copyin>
    80004c56:	05b50e63          	beq	a0,s11,80004cb2 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c5a:	21c4a783          	lw	a5,540(s1)
    80004c5e:	0017871b          	addiw	a4,a5,1
    80004c62:	20e4ae23          	sw	a4,540(s1)
    80004c66:	1ff7f793          	andi	a5,a5,511
    80004c6a:	97a6                	add	a5,a5,s1
    80004c6c:	f8f44703          	lbu	a4,-113(s0)
    80004c70:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c74:	001d0c1b          	addiw	s8,s10,1
    80004c78:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004c7c:	036b8b63          	beq	s7,s6,80004cb2 <pipewrite+0x10c>
    80004c80:	8bbe                	mv	s7,a5
    80004c82:	bf9d                	j	80004bf8 <pipewrite+0x52>
        release(&pi->lock);
    80004c84:	8526                	mv	a0,s1
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	088080e7          	jalr	136(ra) # 80000d0e <release>
        return -1;
    80004c8e:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004c90:	8562                	mv	a0,s8
    80004c92:	70e6                	ld	ra,120(sp)
    80004c94:	7446                	ld	s0,112(sp)
    80004c96:	74a6                	ld	s1,104(sp)
    80004c98:	7906                	ld	s2,96(sp)
    80004c9a:	69e6                	ld	s3,88(sp)
    80004c9c:	6a46                	ld	s4,80(sp)
    80004c9e:	6aa6                	ld	s5,72(sp)
    80004ca0:	6b06                	ld	s6,64(sp)
    80004ca2:	7be2                	ld	s7,56(sp)
    80004ca4:	7c42                	ld	s8,48(sp)
    80004ca6:	7ca2                	ld	s9,40(sp)
    80004ca8:	7d02                	ld	s10,32(sp)
    80004caa:	6de2                	ld	s11,24(sp)
    80004cac:	6109                	addi	sp,sp,128
    80004cae:	8082                	ret
  for(i = 0; i < n; i++){
    80004cb0:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004cb2:	21848513          	addi	a0,s1,536
    80004cb6:	ffffd097          	auipc	ra,0xffffd
    80004cba:	7f8080e7          	jalr	2040(ra) # 800024ae <wakeup>
  release(&pi->lock);
    80004cbe:	8526                	mv	a0,s1
    80004cc0:	ffffc097          	auipc	ra,0xffffc
    80004cc4:	04e080e7          	jalr	78(ra) # 80000d0e <release>
  return i;
    80004cc8:	b7e1                	j	80004c90 <pipewrite+0xea>

0000000080004cca <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cca:	715d                	addi	sp,sp,-80
    80004ccc:	e486                	sd	ra,72(sp)
    80004cce:	e0a2                	sd	s0,64(sp)
    80004cd0:	fc26                	sd	s1,56(sp)
    80004cd2:	f84a                	sd	s2,48(sp)
    80004cd4:	f44e                	sd	s3,40(sp)
    80004cd6:	f052                	sd	s4,32(sp)
    80004cd8:	ec56                	sd	s5,24(sp)
    80004cda:	e85a                	sd	s6,16(sp)
    80004cdc:	0880                	addi	s0,sp,80
    80004cde:	84aa                	mv	s1,a0
    80004ce0:	892e                	mv	s2,a1
    80004ce2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ce4:	ffffd097          	auipc	ra,0xffffd
    80004ce8:	e2c080e7          	jalr	-468(ra) # 80001b10 <myproc>
    80004cec:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cee:	8b26                	mv	s6,s1
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	f68080e7          	jalr	-152(ra) # 80000c5a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cfa:	2184a703          	lw	a4,536(s1)
    80004cfe:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d02:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d06:	02f71463          	bne	a4,a5,80004d2e <piperead+0x64>
    80004d0a:	2244a783          	lw	a5,548(s1)
    80004d0e:	c385                	beqz	a5,80004d2e <piperead+0x64>
    if(pr->killed){
    80004d10:	030a2783          	lw	a5,48(s4)
    80004d14:	ebc1                	bnez	a5,80004da4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d16:	85da                	mv	a1,s6
    80004d18:	854e                	mv	a0,s3
    80004d1a:	ffffd097          	auipc	ra,0xffffd
    80004d1e:	60e080e7          	jalr	1550(ra) # 80002328 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d22:	2184a703          	lw	a4,536(s1)
    80004d26:	21c4a783          	lw	a5,540(s1)
    80004d2a:	fef700e3          	beq	a4,a5,80004d0a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d2e:	09505263          	blez	s5,80004db2 <piperead+0xe8>
    80004d32:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d34:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d36:	2184a783          	lw	a5,536(s1)
    80004d3a:	21c4a703          	lw	a4,540(s1)
    80004d3e:	02f70d63          	beq	a4,a5,80004d78 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d42:	0017871b          	addiw	a4,a5,1
    80004d46:	20e4ac23          	sw	a4,536(s1)
    80004d4a:	1ff7f793          	andi	a5,a5,511
    80004d4e:	97a6                	add	a5,a5,s1
    80004d50:	0187c783          	lbu	a5,24(a5)
    80004d54:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d58:	4685                	li	a3,1
    80004d5a:	fbf40613          	addi	a2,s0,-65
    80004d5e:	85ca                	mv	a1,s2
    80004d60:	050a3503          	ld	a0,80(s4)
    80004d64:	ffffd097          	auipc	ra,0xffffd
    80004d68:	9c0080e7          	jalr	-1600(ra) # 80001724 <copyout>
    80004d6c:	01650663          	beq	a0,s6,80004d78 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d70:	2985                	addiw	s3,s3,1
    80004d72:	0905                	addi	s2,s2,1
    80004d74:	fd3a91e3          	bne	s5,s3,80004d36 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d78:	21c48513          	addi	a0,s1,540
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	732080e7          	jalr	1842(ra) # 800024ae <wakeup>
  release(&pi->lock);
    80004d84:	8526                	mv	a0,s1
    80004d86:	ffffc097          	auipc	ra,0xffffc
    80004d8a:	f88080e7          	jalr	-120(ra) # 80000d0e <release>
  return i;
}
    80004d8e:	854e                	mv	a0,s3
    80004d90:	60a6                	ld	ra,72(sp)
    80004d92:	6406                	ld	s0,64(sp)
    80004d94:	74e2                	ld	s1,56(sp)
    80004d96:	7942                	ld	s2,48(sp)
    80004d98:	79a2                	ld	s3,40(sp)
    80004d9a:	7a02                	ld	s4,32(sp)
    80004d9c:	6ae2                	ld	s5,24(sp)
    80004d9e:	6b42                	ld	s6,16(sp)
    80004da0:	6161                	addi	sp,sp,80
    80004da2:	8082                	ret
      release(&pi->lock);
    80004da4:	8526                	mv	a0,s1
    80004da6:	ffffc097          	auipc	ra,0xffffc
    80004daa:	f68080e7          	jalr	-152(ra) # 80000d0e <release>
      return -1;
    80004dae:	59fd                	li	s3,-1
    80004db0:	bff9                	j	80004d8e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004db2:	4981                	li	s3,0
    80004db4:	b7d1                	j	80004d78 <piperead+0xae>

0000000080004db6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004db6:	df010113          	addi	sp,sp,-528
    80004dba:	20113423          	sd	ra,520(sp)
    80004dbe:	20813023          	sd	s0,512(sp)
    80004dc2:	ffa6                	sd	s1,504(sp)
    80004dc4:	fbca                	sd	s2,496(sp)
    80004dc6:	f7ce                	sd	s3,488(sp)
    80004dc8:	f3d2                	sd	s4,480(sp)
    80004dca:	efd6                	sd	s5,472(sp)
    80004dcc:	ebda                	sd	s6,464(sp)
    80004dce:	e7de                	sd	s7,456(sp)
    80004dd0:	e3e2                	sd	s8,448(sp)
    80004dd2:	ff66                	sd	s9,440(sp)
    80004dd4:	fb6a                	sd	s10,432(sp)
    80004dd6:	f76e                	sd	s11,424(sp)
    80004dd8:	0c00                	addi	s0,sp,528
    80004dda:	84aa                	mv	s1,a0
    80004ddc:	dea43c23          	sd	a0,-520(s0)
    80004de0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	d2c080e7          	jalr	-724(ra) # 80001b10 <myproc>
    80004dec:	892a                	mv	s2,a0

  begin_op();
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	446080e7          	jalr	1094(ra) # 80004234 <begin_op>

  if((ip = namei(path)) == 0){
    80004df6:	8526                	mv	a0,s1
    80004df8:	fffff097          	auipc	ra,0xfffff
    80004dfc:	230080e7          	jalr	560(ra) # 80004028 <namei>
    80004e00:	c92d                	beqz	a0,80004e72 <exec+0xbc>
    80004e02:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e04:	fffff097          	auipc	ra,0xfffff
    80004e08:	a74080e7          	jalr	-1420(ra) # 80003878 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e0c:	04000713          	li	a4,64
    80004e10:	4681                	li	a3,0
    80004e12:	e4840613          	addi	a2,s0,-440
    80004e16:	4581                	li	a1,0
    80004e18:	8526                	mv	a0,s1
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	d12080e7          	jalr	-750(ra) # 80003b2c <readi>
    80004e22:	04000793          	li	a5,64
    80004e26:	00f51a63          	bne	a0,a5,80004e3a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e2a:	e4842703          	lw	a4,-440(s0)
    80004e2e:	464c47b7          	lui	a5,0x464c4
    80004e32:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e36:	04f70463          	beq	a4,a5,80004e7e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e3a:	8526                	mv	a0,s1
    80004e3c:	fffff097          	auipc	ra,0xfffff
    80004e40:	c9e080e7          	jalr	-866(ra) # 80003ada <iunlockput>
    end_op();
    80004e44:	fffff097          	auipc	ra,0xfffff
    80004e48:	470080e7          	jalr	1136(ra) # 800042b4 <end_op>
  }
  return -1;
    80004e4c:	557d                	li	a0,-1
}
    80004e4e:	20813083          	ld	ra,520(sp)
    80004e52:	20013403          	ld	s0,512(sp)
    80004e56:	74fe                	ld	s1,504(sp)
    80004e58:	795e                	ld	s2,496(sp)
    80004e5a:	79be                	ld	s3,488(sp)
    80004e5c:	7a1e                	ld	s4,480(sp)
    80004e5e:	6afe                	ld	s5,472(sp)
    80004e60:	6b5e                	ld	s6,464(sp)
    80004e62:	6bbe                	ld	s7,456(sp)
    80004e64:	6c1e                	ld	s8,448(sp)
    80004e66:	7cfa                	ld	s9,440(sp)
    80004e68:	7d5a                	ld	s10,432(sp)
    80004e6a:	7dba                	ld	s11,424(sp)
    80004e6c:	21010113          	addi	sp,sp,528
    80004e70:	8082                	ret
    end_op();
    80004e72:	fffff097          	auipc	ra,0xfffff
    80004e76:	442080e7          	jalr	1090(ra) # 800042b4 <end_op>
    return -1;
    80004e7a:	557d                	li	a0,-1
    80004e7c:	bfc9                	j	80004e4e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e7e:	854a                	mv	a0,s2
    80004e80:	ffffd097          	auipc	ra,0xffffd
    80004e84:	d54080e7          	jalr	-684(ra) # 80001bd4 <proc_pagetable>
    80004e88:	8baa                	mv	s7,a0
    80004e8a:	d945                	beqz	a0,80004e3a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e8c:	e6842983          	lw	s3,-408(s0)
    80004e90:	e8045783          	lhu	a5,-384(s0)
    80004e94:	c7ad                	beqz	a5,80004efe <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e96:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e98:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004e9a:	6c85                	lui	s9,0x1
    80004e9c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ea0:	def43823          	sd	a5,-528(s0)
    80004ea4:	a489                	j	800050e6 <exec+0x330>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ea6:	00004517          	auipc	a0,0x4
    80004eaa:	a3250513          	addi	a0,a0,-1486 # 800088d8 <sysnames+0x298>
    80004eae:	ffffb097          	auipc	ra,0xffffb
    80004eb2:	69a080e7          	jalr	1690(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004eb6:	8756                	mv	a4,s5
    80004eb8:	012d86bb          	addw	a3,s11,s2
    80004ebc:	4581                	li	a1,0
    80004ebe:	8526                	mv	a0,s1
    80004ec0:	fffff097          	auipc	ra,0xfffff
    80004ec4:	c6c080e7          	jalr	-916(ra) # 80003b2c <readi>
    80004ec8:	2501                	sext.w	a0,a0
    80004eca:	1caa9563          	bne	s5,a0,80005094 <exec+0x2de>
  for(i = 0; i < sz; i += PGSIZE){
    80004ece:	6785                	lui	a5,0x1
    80004ed0:	0127893b          	addw	s2,a5,s2
    80004ed4:	77fd                	lui	a5,0xfffff
    80004ed6:	01478a3b          	addw	s4,a5,s4
    80004eda:	1f897d63          	bgeu	s2,s8,800050d4 <exec+0x31e>
    pa = walkaddr(pagetable, va + i);
    80004ede:	02091593          	slli	a1,s2,0x20
    80004ee2:	9181                	srli	a1,a1,0x20
    80004ee4:	95ea                	add	a1,a1,s10
    80004ee6:	855e                	mv	a0,s7
    80004ee8:	ffffc097          	auipc	ra,0xffffc
    80004eec:	208080e7          	jalr	520(ra) # 800010f0 <walkaddr>
    80004ef0:	862a                	mv	a2,a0
    if(pa == 0)
    80004ef2:	d955                	beqz	a0,80004ea6 <exec+0xf0>
      n = PGSIZE;
    80004ef4:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ef6:	fd9a70e3          	bgeu	s4,s9,80004eb6 <exec+0x100>
      n = sz - i;
    80004efa:	8ad2                	mv	s5,s4
    80004efc:	bf6d                	j	80004eb6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004efe:	4901                	li	s2,0
  iunlockput(ip);
    80004f00:	8526                	mv	a0,s1
    80004f02:	fffff097          	auipc	ra,0xfffff
    80004f06:	bd8080e7          	jalr	-1064(ra) # 80003ada <iunlockput>
  end_op();
    80004f0a:	fffff097          	auipc	ra,0xfffff
    80004f0e:	3aa080e7          	jalr	938(ra) # 800042b4 <end_op>
  p = myproc();
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	bfe080e7          	jalr	-1026(ra) # 80001b10 <myproc>
    80004f1a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f1c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f20:	6785                	lui	a5,0x1
    80004f22:	17fd                	addi	a5,a5,-1
    80004f24:	993e                	add	s2,s2,a5
    80004f26:	757d                	lui	a0,0xfffff
    80004f28:	00a977b3          	and	a5,s2,a0
    80004f2c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f30:	6609                	lui	a2,0x2
    80004f32:	963e                	add	a2,a2,a5
    80004f34:	85be                	mv	a1,a5
    80004f36:	855e                	mv	a0,s7
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	59c080e7          	jalr	1436(ra) # 800014d4 <uvmalloc>
    80004f40:	8b2a                	mv	s6,a0
  ip = 0;
    80004f42:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f44:	14050863          	beqz	a0,80005094 <exec+0x2de>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f48:	75f9                	lui	a1,0xffffe
    80004f4a:	95aa                	add	a1,a1,a0
    80004f4c:	855e                	mv	a0,s7
    80004f4e:	ffffc097          	auipc	ra,0xffffc
    80004f52:	7a4080e7          	jalr	1956(ra) # 800016f2 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f56:	7c7d                	lui	s8,0xfffff
    80004f58:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f5a:	e0043783          	ld	a5,-512(s0)
    80004f5e:	6388                	ld	a0,0(a5)
    80004f60:	c535                	beqz	a0,80004fcc <exec+0x216>
    80004f62:	e8840993          	addi	s3,s0,-376
    80004f66:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f6a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f6c:	ffffc097          	auipc	ra,0xffffc
    80004f70:	f72080e7          	jalr	-142(ra) # 80000ede <strlen>
    80004f74:	2505                	addiw	a0,a0,1
    80004f76:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f7a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f7e:	13896f63          	bltu	s2,s8,800050bc <exec+0x306>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f82:	e0043d83          	ld	s11,-512(s0)
    80004f86:	000dba03          	ld	s4,0(s11)
    80004f8a:	8552                	mv	a0,s4
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	f52080e7          	jalr	-174(ra) # 80000ede <strlen>
    80004f94:	0015069b          	addiw	a3,a0,1
    80004f98:	8652                	mv	a2,s4
    80004f9a:	85ca                	mv	a1,s2
    80004f9c:	855e                	mv	a0,s7
    80004f9e:	ffffc097          	auipc	ra,0xffffc
    80004fa2:	786080e7          	jalr	1926(ra) # 80001724 <copyout>
    80004fa6:	10054f63          	bltz	a0,800050c4 <exec+0x30e>
    ustack[argc] = sp;
    80004faa:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fae:	0485                	addi	s1,s1,1
    80004fb0:	008d8793          	addi	a5,s11,8
    80004fb4:	e0f43023          	sd	a5,-512(s0)
    80004fb8:	008db503          	ld	a0,8(s11)
    80004fbc:	c911                	beqz	a0,80004fd0 <exec+0x21a>
    if(argc >= MAXARG)
    80004fbe:	09a1                	addi	s3,s3,8
    80004fc0:	fb3c96e3          	bne	s9,s3,80004f6c <exec+0x1b6>
  sz = sz1;
    80004fc4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc8:	4481                	li	s1,0
    80004fca:	a0e9                	j	80005094 <exec+0x2de>
  sp = sz;
    80004fcc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fce:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fd0:	00349793          	slli	a5,s1,0x3
    80004fd4:	f9040713          	addi	a4,s0,-112
    80004fd8:	97ba                	add	a5,a5,a4
    80004fda:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004fde:	00148693          	addi	a3,s1,1
    80004fe2:	068e                	slli	a3,a3,0x3
    80004fe4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fe8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fec:	01897663          	bgeu	s2,s8,80004ff8 <exec+0x242>
  sz = sz1;
    80004ff0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ff4:	4481                	li	s1,0
    80004ff6:	a879                	j	80005094 <exec+0x2de>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ff8:	e8840613          	addi	a2,s0,-376
    80004ffc:	85ca                	mv	a1,s2
    80004ffe:	855e                	mv	a0,s7
    80005000:	ffffc097          	auipc	ra,0xffffc
    80005004:	724080e7          	jalr	1828(ra) # 80001724 <copyout>
    80005008:	0c054263          	bltz	a0,800050cc <exec+0x316>
  p->trapframe->a1 = sp;
    8000500c:	058ab783          	ld	a5,88(s5)
    80005010:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005014:	df843783          	ld	a5,-520(s0)
    80005018:	0007c703          	lbu	a4,0(a5)
    8000501c:	cf11                	beqz	a4,80005038 <exec+0x282>
    8000501e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005020:	02f00693          	li	a3,47
    80005024:	a029                	j	8000502e <exec+0x278>
  for(last=s=path; *s; s++)
    80005026:	0785                	addi	a5,a5,1
    80005028:	fff7c703          	lbu	a4,-1(a5)
    8000502c:	c711                	beqz	a4,80005038 <exec+0x282>
    if(*s == '/')
    8000502e:	fed71ce3          	bne	a4,a3,80005026 <exec+0x270>
      last = s+1;
    80005032:	def43c23          	sd	a5,-520(s0)
    80005036:	bfc5                	j	80005026 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005038:	4641                	li	a2,16
    8000503a:	df843583          	ld	a1,-520(s0)
    8000503e:	158a8513          	addi	a0,s5,344
    80005042:	ffffc097          	auipc	ra,0xffffc
    80005046:	e6a080e7          	jalr	-406(ra) # 80000eac <safestrcpy>
  oldpagetable = p->pagetable;
    8000504a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000504e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005052:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005056:	058ab783          	ld	a5,88(s5)
    8000505a:	e6043703          	ld	a4,-416(s0)
    8000505e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005060:	058ab783          	ld	a5,88(s5)
    80005064:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005068:	85ea                	mv	a1,s10
    8000506a:	ffffd097          	auipc	ra,0xffffd
    8000506e:	c06080e7          	jalr	-1018(ra) # 80001c70 <proc_freepagetable>
  if (p->pid == 1)
    80005072:	038aa703          	lw	a4,56(s5)
    80005076:	4785                	li	a5,1
    80005078:	00f70563          	beq	a4,a5,80005082 <exec+0x2cc>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000507c:	0004851b          	sext.w	a0,s1
    80005080:	b3f9                	j	80004e4e <exec+0x98>
    vmprint(p->pagetable);
    80005082:	050ab503          	ld	a0,80(s5)
    80005086:	ffffd097          	auipc	ra,0xffffd
    8000508a:	916080e7          	jalr	-1770(ra) # 8000199c <vmprint>
    8000508e:	b7fd                	j	8000507c <exec+0x2c6>
    80005090:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005094:	e0843583          	ld	a1,-504(s0)
    80005098:	855e                	mv	a0,s7
    8000509a:	ffffd097          	auipc	ra,0xffffd
    8000509e:	bd6080e7          	jalr	-1066(ra) # 80001c70 <proc_freepagetable>
  if(ip){
    800050a2:	d8049ce3          	bnez	s1,80004e3a <exec+0x84>
  return -1;
    800050a6:	557d                	li	a0,-1
    800050a8:	b35d                	j	80004e4e <exec+0x98>
    800050aa:	e1243423          	sd	s2,-504(s0)
    800050ae:	b7dd                	j	80005094 <exec+0x2de>
    800050b0:	e1243423          	sd	s2,-504(s0)
    800050b4:	b7c5                	j	80005094 <exec+0x2de>
    800050b6:	e1243423          	sd	s2,-504(s0)
    800050ba:	bfe9                	j	80005094 <exec+0x2de>
  sz = sz1;
    800050bc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050c0:	4481                	li	s1,0
    800050c2:	bfc9                	j	80005094 <exec+0x2de>
  sz = sz1;
    800050c4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050c8:	4481                	li	s1,0
    800050ca:	b7e9                	j	80005094 <exec+0x2de>
  sz = sz1;
    800050cc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050d0:	4481                	li	s1,0
    800050d2:	b7c9                	j	80005094 <exec+0x2de>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050d4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050d8:	2b05                	addiw	s6,s6,1
    800050da:	0389899b          	addiw	s3,s3,56
    800050de:	e8045783          	lhu	a5,-384(s0)
    800050e2:	e0fb5fe3          	bge	s6,a5,80004f00 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050e6:	2981                	sext.w	s3,s3
    800050e8:	03800713          	li	a4,56
    800050ec:	86ce                	mv	a3,s3
    800050ee:	e1040613          	addi	a2,s0,-496
    800050f2:	4581                	li	a1,0
    800050f4:	8526                	mv	a0,s1
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	a36080e7          	jalr	-1482(ra) # 80003b2c <readi>
    800050fe:	03800793          	li	a5,56
    80005102:	f8f517e3          	bne	a0,a5,80005090 <exec+0x2da>
    if(ph.type != ELF_PROG_LOAD)
    80005106:	e1042783          	lw	a5,-496(s0)
    8000510a:	4705                	li	a4,1
    8000510c:	fce796e3          	bne	a5,a4,800050d8 <exec+0x322>
    if(ph.memsz < ph.filesz)
    80005110:	e3843603          	ld	a2,-456(s0)
    80005114:	e3043783          	ld	a5,-464(s0)
    80005118:	f8f669e3          	bltu	a2,a5,800050aa <exec+0x2f4>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000511c:	e2043783          	ld	a5,-480(s0)
    80005120:	963e                	add	a2,a2,a5
    80005122:	f8f667e3          	bltu	a2,a5,800050b0 <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005126:	85ca                	mv	a1,s2
    80005128:	855e                	mv	a0,s7
    8000512a:	ffffc097          	auipc	ra,0xffffc
    8000512e:	3aa080e7          	jalr	938(ra) # 800014d4 <uvmalloc>
    80005132:	e0a43423          	sd	a0,-504(s0)
    80005136:	d141                	beqz	a0,800050b6 <exec+0x300>
    if(ph.vaddr % PGSIZE != 0)
    80005138:	e2043d03          	ld	s10,-480(s0)
    8000513c:	df043783          	ld	a5,-528(s0)
    80005140:	00fd77b3          	and	a5,s10,a5
    80005144:	fba1                	bnez	a5,80005094 <exec+0x2de>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005146:	e1842d83          	lw	s11,-488(s0)
    8000514a:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000514e:	f80c03e3          	beqz	s8,800050d4 <exec+0x31e>
    80005152:	8a62                	mv	s4,s8
    80005154:	4901                	li	s2,0
    80005156:	b361                	j	80004ede <exec+0x128>

0000000080005158 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005158:	7179                	addi	sp,sp,-48
    8000515a:	f406                	sd	ra,40(sp)
    8000515c:	f022                	sd	s0,32(sp)
    8000515e:	ec26                	sd	s1,24(sp)
    80005160:	e84a                	sd	s2,16(sp)
    80005162:	1800                	addi	s0,sp,48
    80005164:	892e                	mv	s2,a1
    80005166:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005168:	fdc40593          	addi	a1,s0,-36
    8000516c:	ffffe097          	auipc	ra,0xffffe
    80005170:	abe080e7          	jalr	-1346(ra) # 80002c2a <argint>
    80005174:	04054063          	bltz	a0,800051b4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005178:	fdc42703          	lw	a4,-36(s0)
    8000517c:	47bd                	li	a5,15
    8000517e:	02e7ed63          	bltu	a5,a4,800051b8 <argfd+0x60>
    80005182:	ffffd097          	auipc	ra,0xffffd
    80005186:	98e080e7          	jalr	-1650(ra) # 80001b10 <myproc>
    8000518a:	fdc42703          	lw	a4,-36(s0)
    8000518e:	01a70793          	addi	a5,a4,26
    80005192:	078e                	slli	a5,a5,0x3
    80005194:	953e                	add	a0,a0,a5
    80005196:	611c                	ld	a5,0(a0)
    80005198:	c395                	beqz	a5,800051bc <argfd+0x64>
    return -1;
  if(pfd)
    8000519a:	00090463          	beqz	s2,800051a2 <argfd+0x4a>
    *pfd = fd;
    8000519e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051a2:	4501                	li	a0,0
  if(pf)
    800051a4:	c091                	beqz	s1,800051a8 <argfd+0x50>
    *pf = f;
    800051a6:	e09c                	sd	a5,0(s1)
}
    800051a8:	70a2                	ld	ra,40(sp)
    800051aa:	7402                	ld	s0,32(sp)
    800051ac:	64e2                	ld	s1,24(sp)
    800051ae:	6942                	ld	s2,16(sp)
    800051b0:	6145                	addi	sp,sp,48
    800051b2:	8082                	ret
    return -1;
    800051b4:	557d                	li	a0,-1
    800051b6:	bfcd                	j	800051a8 <argfd+0x50>
    return -1;
    800051b8:	557d                	li	a0,-1
    800051ba:	b7fd                	j	800051a8 <argfd+0x50>
    800051bc:	557d                	li	a0,-1
    800051be:	b7ed                	j	800051a8 <argfd+0x50>

00000000800051c0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051c0:	1101                	addi	sp,sp,-32
    800051c2:	ec06                	sd	ra,24(sp)
    800051c4:	e822                	sd	s0,16(sp)
    800051c6:	e426                	sd	s1,8(sp)
    800051c8:	1000                	addi	s0,sp,32
    800051ca:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051cc:	ffffd097          	auipc	ra,0xffffd
    800051d0:	944080e7          	jalr	-1724(ra) # 80001b10 <myproc>
    800051d4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051d6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80b0>
    800051da:	4501                	li	a0,0
    800051dc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051de:	6398                	ld	a4,0(a5)
    800051e0:	cb19                	beqz	a4,800051f6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051e2:	2505                	addiw	a0,a0,1
    800051e4:	07a1                	addi	a5,a5,8
    800051e6:	fed51ce3          	bne	a0,a3,800051de <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051ea:	557d                	li	a0,-1
}
    800051ec:	60e2                	ld	ra,24(sp)
    800051ee:	6442                	ld	s0,16(sp)
    800051f0:	64a2                	ld	s1,8(sp)
    800051f2:	6105                	addi	sp,sp,32
    800051f4:	8082                	ret
      p->ofile[fd] = f;
    800051f6:	01a50793          	addi	a5,a0,26
    800051fa:	078e                	slli	a5,a5,0x3
    800051fc:	963e                	add	a2,a2,a5
    800051fe:	e204                	sd	s1,0(a2)
      return fd;
    80005200:	b7f5                	j	800051ec <fdalloc+0x2c>

0000000080005202 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005202:	715d                	addi	sp,sp,-80
    80005204:	e486                	sd	ra,72(sp)
    80005206:	e0a2                	sd	s0,64(sp)
    80005208:	fc26                	sd	s1,56(sp)
    8000520a:	f84a                	sd	s2,48(sp)
    8000520c:	f44e                	sd	s3,40(sp)
    8000520e:	f052                	sd	s4,32(sp)
    80005210:	ec56                	sd	s5,24(sp)
    80005212:	0880                	addi	s0,sp,80
    80005214:	89ae                	mv	s3,a1
    80005216:	8ab2                	mv	s5,a2
    80005218:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000521a:	fb040593          	addi	a1,s0,-80
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	e28080e7          	jalr	-472(ra) # 80004046 <nameiparent>
    80005226:	892a                	mv	s2,a0
    80005228:	12050f63          	beqz	a0,80005366 <create+0x164>
    return 0;

  ilock(dp);
    8000522c:	ffffe097          	auipc	ra,0xffffe
    80005230:	64c080e7          	jalr	1612(ra) # 80003878 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005234:	4601                	li	a2,0
    80005236:	fb040593          	addi	a1,s0,-80
    8000523a:	854a                	mv	a0,s2
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	b1a080e7          	jalr	-1254(ra) # 80003d56 <dirlookup>
    80005244:	84aa                	mv	s1,a0
    80005246:	c921                	beqz	a0,80005296 <create+0x94>
    iunlockput(dp);
    80005248:	854a                	mv	a0,s2
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	890080e7          	jalr	-1904(ra) # 80003ada <iunlockput>
    ilock(ip);
    80005252:	8526                	mv	a0,s1
    80005254:	ffffe097          	auipc	ra,0xffffe
    80005258:	624080e7          	jalr	1572(ra) # 80003878 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000525c:	2981                	sext.w	s3,s3
    8000525e:	4789                	li	a5,2
    80005260:	02f99463          	bne	s3,a5,80005288 <create+0x86>
    80005264:	0444d783          	lhu	a5,68(s1)
    80005268:	37f9                	addiw	a5,a5,-2
    8000526a:	17c2                	slli	a5,a5,0x30
    8000526c:	93c1                	srli	a5,a5,0x30
    8000526e:	4705                	li	a4,1
    80005270:	00f76c63          	bltu	a4,a5,80005288 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005274:	8526                	mv	a0,s1
    80005276:	60a6                	ld	ra,72(sp)
    80005278:	6406                	ld	s0,64(sp)
    8000527a:	74e2                	ld	s1,56(sp)
    8000527c:	7942                	ld	s2,48(sp)
    8000527e:	79a2                	ld	s3,40(sp)
    80005280:	7a02                	ld	s4,32(sp)
    80005282:	6ae2                	ld	s5,24(sp)
    80005284:	6161                	addi	sp,sp,80
    80005286:	8082                	ret
    iunlockput(ip);
    80005288:	8526                	mv	a0,s1
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	850080e7          	jalr	-1968(ra) # 80003ada <iunlockput>
    return 0;
    80005292:	4481                	li	s1,0
    80005294:	b7c5                	j	80005274 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005296:	85ce                	mv	a1,s3
    80005298:	00092503          	lw	a0,0(s2)
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	444080e7          	jalr	1092(ra) # 800036e0 <ialloc>
    800052a4:	84aa                	mv	s1,a0
    800052a6:	c529                	beqz	a0,800052f0 <create+0xee>
  ilock(ip);
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	5d0080e7          	jalr	1488(ra) # 80003878 <ilock>
  ip->major = major;
    800052b0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052b4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052b8:	4785                	li	a5,1
    800052ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052be:	8526                	mv	a0,s1
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	4ee080e7          	jalr	1262(ra) # 800037ae <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052c8:	2981                	sext.w	s3,s3
    800052ca:	4785                	li	a5,1
    800052cc:	02f98a63          	beq	s3,a5,80005300 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052d0:	40d0                	lw	a2,4(s1)
    800052d2:	fb040593          	addi	a1,s0,-80
    800052d6:	854a                	mv	a0,s2
    800052d8:	fffff097          	auipc	ra,0xfffff
    800052dc:	c8e080e7          	jalr	-882(ra) # 80003f66 <dirlink>
    800052e0:	06054b63          	bltz	a0,80005356 <create+0x154>
  iunlockput(dp);
    800052e4:	854a                	mv	a0,s2
    800052e6:	ffffe097          	auipc	ra,0xffffe
    800052ea:	7f4080e7          	jalr	2036(ra) # 80003ada <iunlockput>
  return ip;
    800052ee:	b759                	j	80005274 <create+0x72>
    panic("create: ialloc");
    800052f0:	00003517          	auipc	a0,0x3
    800052f4:	60850513          	addi	a0,a0,1544 # 800088f8 <sysnames+0x2b8>
    800052f8:	ffffb097          	auipc	ra,0xffffb
    800052fc:	250080e7          	jalr	592(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005300:	04a95783          	lhu	a5,74(s2)
    80005304:	2785                	addiw	a5,a5,1
    80005306:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000530a:	854a                	mv	a0,s2
    8000530c:	ffffe097          	auipc	ra,0xffffe
    80005310:	4a2080e7          	jalr	1186(ra) # 800037ae <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005314:	40d0                	lw	a2,4(s1)
    80005316:	00003597          	auipc	a1,0x3
    8000531a:	5f258593          	addi	a1,a1,1522 # 80008908 <sysnames+0x2c8>
    8000531e:	8526                	mv	a0,s1
    80005320:	fffff097          	auipc	ra,0xfffff
    80005324:	c46080e7          	jalr	-954(ra) # 80003f66 <dirlink>
    80005328:	00054f63          	bltz	a0,80005346 <create+0x144>
    8000532c:	00492603          	lw	a2,4(s2)
    80005330:	00003597          	auipc	a1,0x3
    80005334:	ee858593          	addi	a1,a1,-280 # 80008218 <digits+0x1d8>
    80005338:	8526                	mv	a0,s1
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	c2c080e7          	jalr	-980(ra) # 80003f66 <dirlink>
    80005342:	f80557e3          	bgez	a0,800052d0 <create+0xce>
      panic("create dots");
    80005346:	00003517          	auipc	a0,0x3
    8000534a:	5ca50513          	addi	a0,a0,1482 # 80008910 <sysnames+0x2d0>
    8000534e:	ffffb097          	auipc	ra,0xffffb
    80005352:	1fa080e7          	jalr	506(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005356:	00003517          	auipc	a0,0x3
    8000535a:	5ca50513          	addi	a0,a0,1482 # 80008920 <sysnames+0x2e0>
    8000535e:	ffffb097          	auipc	ra,0xffffb
    80005362:	1ea080e7          	jalr	490(ra) # 80000548 <panic>
    return 0;
    80005366:	84aa                	mv	s1,a0
    80005368:	b731                	j	80005274 <create+0x72>

000000008000536a <sys_dup>:
{
    8000536a:	7179                	addi	sp,sp,-48
    8000536c:	f406                	sd	ra,40(sp)
    8000536e:	f022                	sd	s0,32(sp)
    80005370:	ec26                	sd	s1,24(sp)
    80005372:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005374:	fd840613          	addi	a2,s0,-40
    80005378:	4581                	li	a1,0
    8000537a:	4501                	li	a0,0
    8000537c:	00000097          	auipc	ra,0x0
    80005380:	ddc080e7          	jalr	-548(ra) # 80005158 <argfd>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005386:	02054363          	bltz	a0,800053ac <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000538a:	fd843503          	ld	a0,-40(s0)
    8000538e:	00000097          	auipc	ra,0x0
    80005392:	e32080e7          	jalr	-462(ra) # 800051c0 <fdalloc>
    80005396:	84aa                	mv	s1,a0
    return -1;
    80005398:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000539a:	00054963          	bltz	a0,800053ac <sys_dup+0x42>
  filedup(f);
    8000539e:	fd843503          	ld	a0,-40(s0)
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	312080e7          	jalr	786(ra) # 800046b4 <filedup>
  return fd;
    800053aa:	87a6                	mv	a5,s1
}
    800053ac:	853e                	mv	a0,a5
    800053ae:	70a2                	ld	ra,40(sp)
    800053b0:	7402                	ld	s0,32(sp)
    800053b2:	64e2                	ld	s1,24(sp)
    800053b4:	6145                	addi	sp,sp,48
    800053b6:	8082                	ret

00000000800053b8 <sys_read>:
{
    800053b8:	7179                	addi	sp,sp,-48
    800053ba:	f406                	sd	ra,40(sp)
    800053bc:	f022                	sd	s0,32(sp)
    800053be:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c0:	fe840613          	addi	a2,s0,-24
    800053c4:	4581                	li	a1,0
    800053c6:	4501                	li	a0,0
    800053c8:	00000097          	auipc	ra,0x0
    800053cc:	d90080e7          	jalr	-624(ra) # 80005158 <argfd>
    return -1;
    800053d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d2:	04054163          	bltz	a0,80005414 <sys_read+0x5c>
    800053d6:	fe440593          	addi	a1,s0,-28
    800053da:	4509                	li	a0,2
    800053dc:	ffffe097          	auipc	ra,0xffffe
    800053e0:	84e080e7          	jalr	-1970(ra) # 80002c2a <argint>
    return -1;
    800053e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e6:	02054763          	bltz	a0,80005414 <sys_read+0x5c>
    800053ea:	fd840593          	addi	a1,s0,-40
    800053ee:	4505                	li	a0,1
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	85c080e7          	jalr	-1956(ra) # 80002c4c <argaddr>
    return -1;
    800053f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053fa:	00054d63          	bltz	a0,80005414 <sys_read+0x5c>
  return fileread(f, p, n);
    800053fe:	fe442603          	lw	a2,-28(s0)
    80005402:	fd843583          	ld	a1,-40(s0)
    80005406:	fe843503          	ld	a0,-24(s0)
    8000540a:	fffff097          	auipc	ra,0xfffff
    8000540e:	436080e7          	jalr	1078(ra) # 80004840 <fileread>
    80005412:	87aa                	mv	a5,a0
}
    80005414:	853e                	mv	a0,a5
    80005416:	70a2                	ld	ra,40(sp)
    80005418:	7402                	ld	s0,32(sp)
    8000541a:	6145                	addi	sp,sp,48
    8000541c:	8082                	ret

000000008000541e <sys_write>:
{
    8000541e:	7179                	addi	sp,sp,-48
    80005420:	f406                	sd	ra,40(sp)
    80005422:	f022                	sd	s0,32(sp)
    80005424:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005426:	fe840613          	addi	a2,s0,-24
    8000542a:	4581                	li	a1,0
    8000542c:	4501                	li	a0,0
    8000542e:	00000097          	auipc	ra,0x0
    80005432:	d2a080e7          	jalr	-726(ra) # 80005158 <argfd>
    return -1;
    80005436:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005438:	04054163          	bltz	a0,8000547a <sys_write+0x5c>
    8000543c:	fe440593          	addi	a1,s0,-28
    80005440:	4509                	li	a0,2
    80005442:	ffffd097          	auipc	ra,0xffffd
    80005446:	7e8080e7          	jalr	2024(ra) # 80002c2a <argint>
    return -1;
    8000544a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000544c:	02054763          	bltz	a0,8000547a <sys_write+0x5c>
    80005450:	fd840593          	addi	a1,s0,-40
    80005454:	4505                	li	a0,1
    80005456:	ffffd097          	auipc	ra,0xffffd
    8000545a:	7f6080e7          	jalr	2038(ra) # 80002c4c <argaddr>
    return -1;
    8000545e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005460:	00054d63          	bltz	a0,8000547a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005464:	fe442603          	lw	a2,-28(s0)
    80005468:	fd843583          	ld	a1,-40(s0)
    8000546c:	fe843503          	ld	a0,-24(s0)
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	492080e7          	jalr	1170(ra) # 80004902 <filewrite>
    80005478:	87aa                	mv	a5,a0
}
    8000547a:	853e                	mv	a0,a5
    8000547c:	70a2                	ld	ra,40(sp)
    8000547e:	7402                	ld	s0,32(sp)
    80005480:	6145                	addi	sp,sp,48
    80005482:	8082                	ret

0000000080005484 <sys_close>:
{
    80005484:	1101                	addi	sp,sp,-32
    80005486:	ec06                	sd	ra,24(sp)
    80005488:	e822                	sd	s0,16(sp)
    8000548a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000548c:	fe040613          	addi	a2,s0,-32
    80005490:	fec40593          	addi	a1,s0,-20
    80005494:	4501                	li	a0,0
    80005496:	00000097          	auipc	ra,0x0
    8000549a:	cc2080e7          	jalr	-830(ra) # 80005158 <argfd>
    return -1;
    8000549e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054a0:	02054463          	bltz	a0,800054c8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054a4:	ffffc097          	auipc	ra,0xffffc
    800054a8:	66c080e7          	jalr	1644(ra) # 80001b10 <myproc>
    800054ac:	fec42783          	lw	a5,-20(s0)
    800054b0:	07e9                	addi	a5,a5,26
    800054b2:	078e                	slli	a5,a5,0x3
    800054b4:	97aa                	add	a5,a5,a0
    800054b6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054ba:	fe043503          	ld	a0,-32(s0)
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	248080e7          	jalr	584(ra) # 80004706 <fileclose>
  return 0;
    800054c6:	4781                	li	a5,0
}
    800054c8:	853e                	mv	a0,a5
    800054ca:	60e2                	ld	ra,24(sp)
    800054cc:	6442                	ld	s0,16(sp)
    800054ce:	6105                	addi	sp,sp,32
    800054d0:	8082                	ret

00000000800054d2 <sys_fstat>:
{
    800054d2:	1101                	addi	sp,sp,-32
    800054d4:	ec06                	sd	ra,24(sp)
    800054d6:	e822                	sd	s0,16(sp)
    800054d8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054da:	fe840613          	addi	a2,s0,-24
    800054de:	4581                	li	a1,0
    800054e0:	4501                	li	a0,0
    800054e2:	00000097          	auipc	ra,0x0
    800054e6:	c76080e7          	jalr	-906(ra) # 80005158 <argfd>
    return -1;
    800054ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054ec:	02054563          	bltz	a0,80005516 <sys_fstat+0x44>
    800054f0:	fe040593          	addi	a1,s0,-32
    800054f4:	4505                	li	a0,1
    800054f6:	ffffd097          	auipc	ra,0xffffd
    800054fa:	756080e7          	jalr	1878(ra) # 80002c4c <argaddr>
    return -1;
    800054fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005500:	00054b63          	bltz	a0,80005516 <sys_fstat+0x44>
  return filestat(f, st);
    80005504:	fe043583          	ld	a1,-32(s0)
    80005508:	fe843503          	ld	a0,-24(s0)
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	2c2080e7          	jalr	706(ra) # 800047ce <filestat>
    80005514:	87aa                	mv	a5,a0
}
    80005516:	853e                	mv	a0,a5
    80005518:	60e2                	ld	ra,24(sp)
    8000551a:	6442                	ld	s0,16(sp)
    8000551c:	6105                	addi	sp,sp,32
    8000551e:	8082                	ret

0000000080005520 <sys_link>:
{
    80005520:	7169                	addi	sp,sp,-304
    80005522:	f606                	sd	ra,296(sp)
    80005524:	f222                	sd	s0,288(sp)
    80005526:	ee26                	sd	s1,280(sp)
    80005528:	ea4a                	sd	s2,272(sp)
    8000552a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000552c:	08000613          	li	a2,128
    80005530:	ed040593          	addi	a1,s0,-304
    80005534:	4501                	li	a0,0
    80005536:	ffffd097          	auipc	ra,0xffffd
    8000553a:	738080e7          	jalr	1848(ra) # 80002c6e <argstr>
    return -1;
    8000553e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005540:	10054e63          	bltz	a0,8000565c <sys_link+0x13c>
    80005544:	08000613          	li	a2,128
    80005548:	f5040593          	addi	a1,s0,-176
    8000554c:	4505                	li	a0,1
    8000554e:	ffffd097          	auipc	ra,0xffffd
    80005552:	720080e7          	jalr	1824(ra) # 80002c6e <argstr>
    return -1;
    80005556:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005558:	10054263          	bltz	a0,8000565c <sys_link+0x13c>
  begin_op();
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	cd8080e7          	jalr	-808(ra) # 80004234 <begin_op>
  if((ip = namei(old)) == 0){
    80005564:	ed040513          	addi	a0,s0,-304
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	ac0080e7          	jalr	-1344(ra) # 80004028 <namei>
    80005570:	84aa                	mv	s1,a0
    80005572:	c551                	beqz	a0,800055fe <sys_link+0xde>
  ilock(ip);
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	304080e7          	jalr	772(ra) # 80003878 <ilock>
  if(ip->type == T_DIR){
    8000557c:	04449703          	lh	a4,68(s1)
    80005580:	4785                	li	a5,1
    80005582:	08f70463          	beq	a4,a5,8000560a <sys_link+0xea>
  ip->nlink++;
    80005586:	04a4d783          	lhu	a5,74(s1)
    8000558a:	2785                	addiw	a5,a5,1
    8000558c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005590:	8526                	mv	a0,s1
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	21c080e7          	jalr	540(ra) # 800037ae <iupdate>
  iunlock(ip);
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	39e080e7          	jalr	926(ra) # 8000393a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055a4:	fd040593          	addi	a1,s0,-48
    800055a8:	f5040513          	addi	a0,s0,-176
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	a9a080e7          	jalr	-1382(ra) # 80004046 <nameiparent>
    800055b4:	892a                	mv	s2,a0
    800055b6:	c935                	beqz	a0,8000562a <sys_link+0x10a>
  ilock(dp);
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	2c0080e7          	jalr	704(ra) # 80003878 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055c0:	00092703          	lw	a4,0(s2)
    800055c4:	409c                	lw	a5,0(s1)
    800055c6:	04f71d63          	bne	a4,a5,80005620 <sys_link+0x100>
    800055ca:	40d0                	lw	a2,4(s1)
    800055cc:	fd040593          	addi	a1,s0,-48
    800055d0:	854a                	mv	a0,s2
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	994080e7          	jalr	-1644(ra) # 80003f66 <dirlink>
    800055da:	04054363          	bltz	a0,80005620 <sys_link+0x100>
  iunlockput(dp);
    800055de:	854a                	mv	a0,s2
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	4fa080e7          	jalr	1274(ra) # 80003ada <iunlockput>
  iput(ip);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	448080e7          	jalr	1096(ra) # 80003a32 <iput>
  end_op();
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	cc2080e7          	jalr	-830(ra) # 800042b4 <end_op>
  return 0;
    800055fa:	4781                	li	a5,0
    800055fc:	a085                	j	8000565c <sys_link+0x13c>
    end_op();
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	cb6080e7          	jalr	-842(ra) # 800042b4 <end_op>
    return -1;
    80005606:	57fd                	li	a5,-1
    80005608:	a891                	j	8000565c <sys_link+0x13c>
    iunlockput(ip);
    8000560a:	8526                	mv	a0,s1
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	4ce080e7          	jalr	1230(ra) # 80003ada <iunlockput>
    end_op();
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	ca0080e7          	jalr	-864(ra) # 800042b4 <end_op>
    return -1;
    8000561c:	57fd                	li	a5,-1
    8000561e:	a83d                	j	8000565c <sys_link+0x13c>
    iunlockput(dp);
    80005620:	854a                	mv	a0,s2
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	4b8080e7          	jalr	1208(ra) # 80003ada <iunlockput>
  ilock(ip);
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	24c080e7          	jalr	588(ra) # 80003878 <ilock>
  ip->nlink--;
    80005634:	04a4d783          	lhu	a5,74(s1)
    80005638:	37fd                	addiw	a5,a5,-1
    8000563a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	16e080e7          	jalr	366(ra) # 800037ae <iupdate>
  iunlockput(ip);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	490080e7          	jalr	1168(ra) # 80003ada <iunlockput>
  end_op();
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	c62080e7          	jalr	-926(ra) # 800042b4 <end_op>
  return -1;
    8000565a:	57fd                	li	a5,-1
}
    8000565c:	853e                	mv	a0,a5
    8000565e:	70b2                	ld	ra,296(sp)
    80005660:	7412                	ld	s0,288(sp)
    80005662:	64f2                	ld	s1,280(sp)
    80005664:	6952                	ld	s2,272(sp)
    80005666:	6155                	addi	sp,sp,304
    80005668:	8082                	ret

000000008000566a <sys_unlink>:
{
    8000566a:	7151                	addi	sp,sp,-240
    8000566c:	f586                	sd	ra,232(sp)
    8000566e:	f1a2                	sd	s0,224(sp)
    80005670:	eda6                	sd	s1,216(sp)
    80005672:	e9ca                	sd	s2,208(sp)
    80005674:	e5ce                	sd	s3,200(sp)
    80005676:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005678:	08000613          	li	a2,128
    8000567c:	f3040593          	addi	a1,s0,-208
    80005680:	4501                	li	a0,0
    80005682:	ffffd097          	auipc	ra,0xffffd
    80005686:	5ec080e7          	jalr	1516(ra) # 80002c6e <argstr>
    8000568a:	18054163          	bltz	a0,8000580c <sys_unlink+0x1a2>
  begin_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	ba6080e7          	jalr	-1114(ra) # 80004234 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005696:	fb040593          	addi	a1,s0,-80
    8000569a:	f3040513          	addi	a0,s0,-208
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	9a8080e7          	jalr	-1624(ra) # 80004046 <nameiparent>
    800056a6:	84aa                	mv	s1,a0
    800056a8:	c979                	beqz	a0,8000577e <sys_unlink+0x114>
  ilock(dp);
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	1ce080e7          	jalr	462(ra) # 80003878 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056b2:	00003597          	auipc	a1,0x3
    800056b6:	25658593          	addi	a1,a1,598 # 80008908 <sysnames+0x2c8>
    800056ba:	fb040513          	addi	a0,s0,-80
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	67e080e7          	jalr	1662(ra) # 80003d3c <namecmp>
    800056c6:	14050a63          	beqz	a0,8000581a <sys_unlink+0x1b0>
    800056ca:	00003597          	auipc	a1,0x3
    800056ce:	b4e58593          	addi	a1,a1,-1202 # 80008218 <digits+0x1d8>
    800056d2:	fb040513          	addi	a0,s0,-80
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	666080e7          	jalr	1638(ra) # 80003d3c <namecmp>
    800056de:	12050e63          	beqz	a0,8000581a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056e2:	f2c40613          	addi	a2,s0,-212
    800056e6:	fb040593          	addi	a1,s0,-80
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	66a080e7          	jalr	1642(ra) # 80003d56 <dirlookup>
    800056f4:	892a                	mv	s2,a0
    800056f6:	12050263          	beqz	a0,8000581a <sys_unlink+0x1b0>
  ilock(ip);
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	17e080e7          	jalr	382(ra) # 80003878 <ilock>
  if(ip->nlink < 1)
    80005702:	04a91783          	lh	a5,74(s2)
    80005706:	08f05263          	blez	a5,8000578a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000570a:	04491703          	lh	a4,68(s2)
    8000570e:	4785                	li	a5,1
    80005710:	08f70563          	beq	a4,a5,8000579a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005714:	4641                	li	a2,16
    80005716:	4581                	li	a1,0
    80005718:	fc040513          	addi	a0,s0,-64
    8000571c:	ffffb097          	auipc	ra,0xffffb
    80005720:	63a080e7          	jalr	1594(ra) # 80000d56 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005724:	4741                	li	a4,16
    80005726:	f2c42683          	lw	a3,-212(s0)
    8000572a:	fc040613          	addi	a2,s0,-64
    8000572e:	4581                	li	a1,0
    80005730:	8526                	mv	a0,s1
    80005732:	ffffe097          	auipc	ra,0xffffe
    80005736:	4f0080e7          	jalr	1264(ra) # 80003c22 <writei>
    8000573a:	47c1                	li	a5,16
    8000573c:	0af51563          	bne	a0,a5,800057e6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005740:	04491703          	lh	a4,68(s2)
    80005744:	4785                	li	a5,1
    80005746:	0af70863          	beq	a4,a5,800057f6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000574a:	8526                	mv	a0,s1
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	38e080e7          	jalr	910(ra) # 80003ada <iunlockput>
  ip->nlink--;
    80005754:	04a95783          	lhu	a5,74(s2)
    80005758:	37fd                	addiw	a5,a5,-1
    8000575a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000575e:	854a                	mv	a0,s2
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	04e080e7          	jalr	78(ra) # 800037ae <iupdate>
  iunlockput(ip);
    80005768:	854a                	mv	a0,s2
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	370080e7          	jalr	880(ra) # 80003ada <iunlockput>
  end_op();
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	b42080e7          	jalr	-1214(ra) # 800042b4 <end_op>
  return 0;
    8000577a:	4501                	li	a0,0
    8000577c:	a84d                	j	8000582e <sys_unlink+0x1c4>
    end_op();
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	b36080e7          	jalr	-1226(ra) # 800042b4 <end_op>
    return -1;
    80005786:	557d                	li	a0,-1
    80005788:	a05d                	j	8000582e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000578a:	00003517          	auipc	a0,0x3
    8000578e:	1a650513          	addi	a0,a0,422 # 80008930 <sysnames+0x2f0>
    80005792:	ffffb097          	auipc	ra,0xffffb
    80005796:	db6080e7          	jalr	-586(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000579a:	04c92703          	lw	a4,76(s2)
    8000579e:	02000793          	li	a5,32
    800057a2:	f6e7f9e3          	bgeu	a5,a4,80005714 <sys_unlink+0xaa>
    800057a6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057aa:	4741                	li	a4,16
    800057ac:	86ce                	mv	a3,s3
    800057ae:	f1840613          	addi	a2,s0,-232
    800057b2:	4581                	li	a1,0
    800057b4:	854a                	mv	a0,s2
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	376080e7          	jalr	886(ra) # 80003b2c <readi>
    800057be:	47c1                	li	a5,16
    800057c0:	00f51b63          	bne	a0,a5,800057d6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057c4:	f1845783          	lhu	a5,-232(s0)
    800057c8:	e7a1                	bnez	a5,80005810 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ca:	29c1                	addiw	s3,s3,16
    800057cc:	04c92783          	lw	a5,76(s2)
    800057d0:	fcf9ede3          	bltu	s3,a5,800057aa <sys_unlink+0x140>
    800057d4:	b781                	j	80005714 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057d6:	00003517          	auipc	a0,0x3
    800057da:	17250513          	addi	a0,a0,370 # 80008948 <sysnames+0x308>
    800057de:	ffffb097          	auipc	ra,0xffffb
    800057e2:	d6a080e7          	jalr	-662(ra) # 80000548 <panic>
    panic("unlink: writei");
    800057e6:	00003517          	auipc	a0,0x3
    800057ea:	17a50513          	addi	a0,a0,378 # 80008960 <sysnames+0x320>
    800057ee:	ffffb097          	auipc	ra,0xffffb
    800057f2:	d5a080e7          	jalr	-678(ra) # 80000548 <panic>
    dp->nlink--;
    800057f6:	04a4d783          	lhu	a5,74(s1)
    800057fa:	37fd                	addiw	a5,a5,-1
    800057fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005800:	8526                	mv	a0,s1
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	fac080e7          	jalr	-84(ra) # 800037ae <iupdate>
    8000580a:	b781                	j	8000574a <sys_unlink+0xe0>
    return -1;
    8000580c:	557d                	li	a0,-1
    8000580e:	a005                	j	8000582e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005810:	854a                	mv	a0,s2
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	2c8080e7          	jalr	712(ra) # 80003ada <iunlockput>
  iunlockput(dp);
    8000581a:	8526                	mv	a0,s1
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	2be080e7          	jalr	702(ra) # 80003ada <iunlockput>
  end_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	a90080e7          	jalr	-1392(ra) # 800042b4 <end_op>
  return -1;
    8000582c:	557d                	li	a0,-1
}
    8000582e:	70ae                	ld	ra,232(sp)
    80005830:	740e                	ld	s0,224(sp)
    80005832:	64ee                	ld	s1,216(sp)
    80005834:	694e                	ld	s2,208(sp)
    80005836:	69ae                	ld	s3,200(sp)
    80005838:	616d                	addi	sp,sp,240
    8000583a:	8082                	ret

000000008000583c <sys_open>:

uint64
sys_open(void)
{
    8000583c:	7131                	addi	sp,sp,-192
    8000583e:	fd06                	sd	ra,184(sp)
    80005840:	f922                	sd	s0,176(sp)
    80005842:	f526                	sd	s1,168(sp)
    80005844:	f14a                	sd	s2,160(sp)
    80005846:	ed4e                	sd	s3,152(sp)
    80005848:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000584a:	08000613          	li	a2,128
    8000584e:	f5040593          	addi	a1,s0,-176
    80005852:	4501                	li	a0,0
    80005854:	ffffd097          	auipc	ra,0xffffd
    80005858:	41a080e7          	jalr	1050(ra) # 80002c6e <argstr>
    return -1;
    8000585c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000585e:	0c054163          	bltz	a0,80005920 <sys_open+0xe4>
    80005862:	f4c40593          	addi	a1,s0,-180
    80005866:	4505                	li	a0,1
    80005868:	ffffd097          	auipc	ra,0xffffd
    8000586c:	3c2080e7          	jalr	962(ra) # 80002c2a <argint>
    80005870:	0a054863          	bltz	a0,80005920 <sys_open+0xe4>

  begin_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	9c0080e7          	jalr	-1600(ra) # 80004234 <begin_op>

  if(omode & O_CREATE){
    8000587c:	f4c42783          	lw	a5,-180(s0)
    80005880:	2007f793          	andi	a5,a5,512
    80005884:	cbdd                	beqz	a5,8000593a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005886:	4681                	li	a3,0
    80005888:	4601                	li	a2,0
    8000588a:	4589                	li	a1,2
    8000588c:	f5040513          	addi	a0,s0,-176
    80005890:	00000097          	auipc	ra,0x0
    80005894:	972080e7          	jalr	-1678(ra) # 80005202 <create>
    80005898:	892a                	mv	s2,a0
    if(ip == 0){
    8000589a:	c959                	beqz	a0,80005930 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000589c:	04491703          	lh	a4,68(s2)
    800058a0:	478d                	li	a5,3
    800058a2:	00f71763          	bne	a4,a5,800058b0 <sys_open+0x74>
    800058a6:	04695703          	lhu	a4,70(s2)
    800058aa:	47a5                	li	a5,9
    800058ac:	0ce7ec63          	bltu	a5,a4,80005984 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	d9a080e7          	jalr	-614(ra) # 8000464a <filealloc>
    800058b8:	89aa                	mv	s3,a0
    800058ba:	10050263          	beqz	a0,800059be <sys_open+0x182>
    800058be:	00000097          	auipc	ra,0x0
    800058c2:	902080e7          	jalr	-1790(ra) # 800051c0 <fdalloc>
    800058c6:	84aa                	mv	s1,a0
    800058c8:	0e054663          	bltz	a0,800059b4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058cc:	04491703          	lh	a4,68(s2)
    800058d0:	478d                	li	a5,3
    800058d2:	0cf70463          	beq	a4,a5,8000599a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058d6:	4789                	li	a5,2
    800058d8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058dc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058e0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058e4:	f4c42783          	lw	a5,-180(s0)
    800058e8:	0017c713          	xori	a4,a5,1
    800058ec:	8b05                	andi	a4,a4,1
    800058ee:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058f2:	0037f713          	andi	a4,a5,3
    800058f6:	00e03733          	snez	a4,a4
    800058fa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058fe:	4007f793          	andi	a5,a5,1024
    80005902:	c791                	beqz	a5,8000590e <sys_open+0xd2>
    80005904:	04491703          	lh	a4,68(s2)
    80005908:	4789                	li	a5,2
    8000590a:	08f70f63          	beq	a4,a5,800059a8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000590e:	854a                	mv	a0,s2
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	02a080e7          	jalr	42(ra) # 8000393a <iunlock>
  end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	99c080e7          	jalr	-1636(ra) # 800042b4 <end_op>

  return fd;
}
    80005920:	8526                	mv	a0,s1
    80005922:	70ea                	ld	ra,184(sp)
    80005924:	744a                	ld	s0,176(sp)
    80005926:	74aa                	ld	s1,168(sp)
    80005928:	790a                	ld	s2,160(sp)
    8000592a:	69ea                	ld	s3,152(sp)
    8000592c:	6129                	addi	sp,sp,192
    8000592e:	8082                	ret
      end_op();
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	984080e7          	jalr	-1660(ra) # 800042b4 <end_op>
      return -1;
    80005938:	b7e5                	j	80005920 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000593a:	f5040513          	addi	a0,s0,-176
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	6ea080e7          	jalr	1770(ra) # 80004028 <namei>
    80005946:	892a                	mv	s2,a0
    80005948:	c905                	beqz	a0,80005978 <sys_open+0x13c>
    ilock(ip);
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	f2e080e7          	jalr	-210(ra) # 80003878 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005952:	04491703          	lh	a4,68(s2)
    80005956:	4785                	li	a5,1
    80005958:	f4f712e3          	bne	a4,a5,8000589c <sys_open+0x60>
    8000595c:	f4c42783          	lw	a5,-180(s0)
    80005960:	dba1                	beqz	a5,800058b0 <sys_open+0x74>
      iunlockput(ip);
    80005962:	854a                	mv	a0,s2
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	176080e7          	jalr	374(ra) # 80003ada <iunlockput>
      end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	948080e7          	jalr	-1720(ra) # 800042b4 <end_op>
      return -1;
    80005974:	54fd                	li	s1,-1
    80005976:	b76d                	j	80005920 <sys_open+0xe4>
      end_op();
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	93c080e7          	jalr	-1732(ra) # 800042b4 <end_op>
      return -1;
    80005980:	54fd                	li	s1,-1
    80005982:	bf79                	j	80005920 <sys_open+0xe4>
    iunlockput(ip);
    80005984:	854a                	mv	a0,s2
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	154080e7          	jalr	340(ra) # 80003ada <iunlockput>
    end_op();
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	926080e7          	jalr	-1754(ra) # 800042b4 <end_op>
    return -1;
    80005996:	54fd                	li	s1,-1
    80005998:	b761                	j	80005920 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000599a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000599e:	04691783          	lh	a5,70(s2)
    800059a2:	02f99223          	sh	a5,36(s3)
    800059a6:	bf2d                	j	800058e0 <sys_open+0xa4>
    itrunc(ip);
    800059a8:	854a                	mv	a0,s2
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	fdc080e7          	jalr	-36(ra) # 80003986 <itrunc>
    800059b2:	bfb1                	j	8000590e <sys_open+0xd2>
      fileclose(f);
    800059b4:	854e                	mv	a0,s3
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	d50080e7          	jalr	-688(ra) # 80004706 <fileclose>
    iunlockput(ip);
    800059be:	854a                	mv	a0,s2
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	11a080e7          	jalr	282(ra) # 80003ada <iunlockput>
    end_op();
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	8ec080e7          	jalr	-1812(ra) # 800042b4 <end_op>
    return -1;
    800059d0:	54fd                	li	s1,-1
    800059d2:	b7b9                	j	80005920 <sys_open+0xe4>

00000000800059d4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059d4:	7175                	addi	sp,sp,-144
    800059d6:	e506                	sd	ra,136(sp)
    800059d8:	e122                	sd	s0,128(sp)
    800059da:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	858080e7          	jalr	-1960(ra) # 80004234 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059e4:	08000613          	li	a2,128
    800059e8:	f7040593          	addi	a1,s0,-144
    800059ec:	4501                	li	a0,0
    800059ee:	ffffd097          	auipc	ra,0xffffd
    800059f2:	280080e7          	jalr	640(ra) # 80002c6e <argstr>
    800059f6:	02054963          	bltz	a0,80005a28 <sys_mkdir+0x54>
    800059fa:	4681                	li	a3,0
    800059fc:	4601                	li	a2,0
    800059fe:	4585                	li	a1,1
    80005a00:	f7040513          	addi	a0,s0,-144
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	7fe080e7          	jalr	2046(ra) # 80005202 <create>
    80005a0c:	cd11                	beqz	a0,80005a28 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	0cc080e7          	jalr	204(ra) # 80003ada <iunlockput>
  end_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	89e080e7          	jalr	-1890(ra) # 800042b4 <end_op>
  return 0;
    80005a1e:	4501                	li	a0,0
}
    80005a20:	60aa                	ld	ra,136(sp)
    80005a22:	640a                	ld	s0,128(sp)
    80005a24:	6149                	addi	sp,sp,144
    80005a26:	8082                	ret
    end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	88c080e7          	jalr	-1908(ra) # 800042b4 <end_op>
    return -1;
    80005a30:	557d                	li	a0,-1
    80005a32:	b7fd                	j	80005a20 <sys_mkdir+0x4c>

0000000080005a34 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a34:	7135                	addi	sp,sp,-160
    80005a36:	ed06                	sd	ra,152(sp)
    80005a38:	e922                	sd	s0,144(sp)
    80005a3a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	7f8080e7          	jalr	2040(ra) # 80004234 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a44:	08000613          	li	a2,128
    80005a48:	f7040593          	addi	a1,s0,-144
    80005a4c:	4501                	li	a0,0
    80005a4e:	ffffd097          	auipc	ra,0xffffd
    80005a52:	220080e7          	jalr	544(ra) # 80002c6e <argstr>
    80005a56:	04054a63          	bltz	a0,80005aaa <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a5a:	f6c40593          	addi	a1,s0,-148
    80005a5e:	4505                	li	a0,1
    80005a60:	ffffd097          	auipc	ra,0xffffd
    80005a64:	1ca080e7          	jalr	458(ra) # 80002c2a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a68:	04054163          	bltz	a0,80005aaa <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a6c:	f6840593          	addi	a1,s0,-152
    80005a70:	4509                	li	a0,2
    80005a72:	ffffd097          	auipc	ra,0xffffd
    80005a76:	1b8080e7          	jalr	440(ra) # 80002c2a <argint>
     argint(1, &major) < 0 ||
    80005a7a:	02054863          	bltz	a0,80005aaa <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a7e:	f6841683          	lh	a3,-152(s0)
    80005a82:	f6c41603          	lh	a2,-148(s0)
    80005a86:	458d                	li	a1,3
    80005a88:	f7040513          	addi	a0,s0,-144
    80005a8c:	fffff097          	auipc	ra,0xfffff
    80005a90:	776080e7          	jalr	1910(ra) # 80005202 <create>
     argint(2, &minor) < 0 ||
    80005a94:	c919                	beqz	a0,80005aaa <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	044080e7          	jalr	68(ra) # 80003ada <iunlockput>
  end_op();
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	816080e7          	jalr	-2026(ra) # 800042b4 <end_op>
  return 0;
    80005aa6:	4501                	li	a0,0
    80005aa8:	a031                	j	80005ab4 <sys_mknod+0x80>
    end_op();
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	80a080e7          	jalr	-2038(ra) # 800042b4 <end_op>
    return -1;
    80005ab2:	557d                	li	a0,-1
}
    80005ab4:	60ea                	ld	ra,152(sp)
    80005ab6:	644a                	ld	s0,144(sp)
    80005ab8:	610d                	addi	sp,sp,160
    80005aba:	8082                	ret

0000000080005abc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005abc:	7135                	addi	sp,sp,-160
    80005abe:	ed06                	sd	ra,152(sp)
    80005ac0:	e922                	sd	s0,144(sp)
    80005ac2:	e526                	sd	s1,136(sp)
    80005ac4:	e14a                	sd	s2,128(sp)
    80005ac6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ac8:	ffffc097          	auipc	ra,0xffffc
    80005acc:	048080e7          	jalr	72(ra) # 80001b10 <myproc>
    80005ad0:	892a                	mv	s2,a0
  
  begin_op();
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	762080e7          	jalr	1890(ra) # 80004234 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ada:	08000613          	li	a2,128
    80005ade:	f6040593          	addi	a1,s0,-160
    80005ae2:	4501                	li	a0,0
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	18a080e7          	jalr	394(ra) # 80002c6e <argstr>
    80005aec:	04054b63          	bltz	a0,80005b42 <sys_chdir+0x86>
    80005af0:	f6040513          	addi	a0,s0,-160
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	534080e7          	jalr	1332(ra) # 80004028 <namei>
    80005afc:	84aa                	mv	s1,a0
    80005afe:	c131                	beqz	a0,80005b42 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	d78080e7          	jalr	-648(ra) # 80003878 <ilock>
  if(ip->type != T_DIR){
    80005b08:	04449703          	lh	a4,68(s1)
    80005b0c:	4785                	li	a5,1
    80005b0e:	04f71063          	bne	a4,a5,80005b4e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b12:	8526                	mv	a0,s1
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	e26080e7          	jalr	-474(ra) # 8000393a <iunlock>
  iput(p->cwd);
    80005b1c:	15093503          	ld	a0,336(s2)
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	f12080e7          	jalr	-238(ra) # 80003a32 <iput>
  end_op();
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	78c080e7          	jalr	1932(ra) # 800042b4 <end_op>
  p->cwd = ip;
    80005b30:	14993823          	sd	s1,336(s2)
  return 0;
    80005b34:	4501                	li	a0,0
}
    80005b36:	60ea                	ld	ra,152(sp)
    80005b38:	644a                	ld	s0,144(sp)
    80005b3a:	64aa                	ld	s1,136(sp)
    80005b3c:	690a                	ld	s2,128(sp)
    80005b3e:	610d                	addi	sp,sp,160
    80005b40:	8082                	ret
    end_op();
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	772080e7          	jalr	1906(ra) # 800042b4 <end_op>
    return -1;
    80005b4a:	557d                	li	a0,-1
    80005b4c:	b7ed                	j	80005b36 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b4e:	8526                	mv	a0,s1
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	f8a080e7          	jalr	-118(ra) # 80003ada <iunlockput>
    end_op();
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	75c080e7          	jalr	1884(ra) # 800042b4 <end_op>
    return -1;
    80005b60:	557d                	li	a0,-1
    80005b62:	bfd1                	j	80005b36 <sys_chdir+0x7a>

0000000080005b64 <sys_exec>:

uint64
sys_exec(void)
{
    80005b64:	7145                	addi	sp,sp,-464
    80005b66:	e786                	sd	ra,456(sp)
    80005b68:	e3a2                	sd	s0,448(sp)
    80005b6a:	ff26                	sd	s1,440(sp)
    80005b6c:	fb4a                	sd	s2,432(sp)
    80005b6e:	f74e                	sd	s3,424(sp)
    80005b70:	f352                	sd	s4,416(sp)
    80005b72:	ef56                	sd	s5,408(sp)
    80005b74:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b76:	08000613          	li	a2,128
    80005b7a:	f4040593          	addi	a1,s0,-192
    80005b7e:	4501                	li	a0,0
    80005b80:	ffffd097          	auipc	ra,0xffffd
    80005b84:	0ee080e7          	jalr	238(ra) # 80002c6e <argstr>
    return -1;
    80005b88:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b8a:	0c054a63          	bltz	a0,80005c5e <sys_exec+0xfa>
    80005b8e:	e3840593          	addi	a1,s0,-456
    80005b92:	4505                	li	a0,1
    80005b94:	ffffd097          	auipc	ra,0xffffd
    80005b98:	0b8080e7          	jalr	184(ra) # 80002c4c <argaddr>
    80005b9c:	0c054163          	bltz	a0,80005c5e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ba0:	10000613          	li	a2,256
    80005ba4:	4581                	li	a1,0
    80005ba6:	e4040513          	addi	a0,s0,-448
    80005baa:	ffffb097          	auipc	ra,0xffffb
    80005bae:	1ac080e7          	jalr	428(ra) # 80000d56 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bb2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bb6:	89a6                	mv	s3,s1
    80005bb8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bba:	02000a13          	li	s4,32
    80005bbe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bc2:	00391513          	slli	a0,s2,0x3
    80005bc6:	e3040593          	addi	a1,s0,-464
    80005bca:	e3843783          	ld	a5,-456(s0)
    80005bce:	953e                	add	a0,a0,a5
    80005bd0:	ffffd097          	auipc	ra,0xffffd
    80005bd4:	fc0080e7          	jalr	-64(ra) # 80002b90 <fetchaddr>
    80005bd8:	02054a63          	bltz	a0,80005c0c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bdc:	e3043783          	ld	a5,-464(s0)
    80005be0:	c3b9                	beqz	a5,80005c26 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	f3e080e7          	jalr	-194(ra) # 80000b20 <kalloc>
    80005bea:	85aa                	mv	a1,a0
    80005bec:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bf0:	cd11                	beqz	a0,80005c0c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bf2:	6605                	lui	a2,0x1
    80005bf4:	e3043503          	ld	a0,-464(s0)
    80005bf8:	ffffd097          	auipc	ra,0xffffd
    80005bfc:	fea080e7          	jalr	-22(ra) # 80002be2 <fetchstr>
    80005c00:	00054663          	bltz	a0,80005c0c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c04:	0905                	addi	s2,s2,1
    80005c06:	09a1                	addi	s3,s3,8
    80005c08:	fb491be3          	bne	s2,s4,80005bbe <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c0c:	10048913          	addi	s2,s1,256
    80005c10:	6088                	ld	a0,0(s1)
    80005c12:	c529                	beqz	a0,80005c5c <sys_exec+0xf8>
    kfree(argv[i]);
    80005c14:	ffffb097          	auipc	ra,0xffffb
    80005c18:	e10080e7          	jalr	-496(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1c:	04a1                	addi	s1,s1,8
    80005c1e:	ff2499e3          	bne	s1,s2,80005c10 <sys_exec+0xac>
  return -1;
    80005c22:	597d                	li	s2,-1
    80005c24:	a82d                	j	80005c5e <sys_exec+0xfa>
      argv[i] = 0;
    80005c26:	0a8e                	slli	s5,s5,0x3
    80005c28:	fc040793          	addi	a5,s0,-64
    80005c2c:	9abe                	add	s5,s5,a5
    80005c2e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c32:	e4040593          	addi	a1,s0,-448
    80005c36:	f4040513          	addi	a0,s0,-192
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	17c080e7          	jalr	380(ra) # 80004db6 <exec>
    80005c42:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c44:	10048993          	addi	s3,s1,256
    80005c48:	6088                	ld	a0,0(s1)
    80005c4a:	c911                	beqz	a0,80005c5e <sys_exec+0xfa>
    kfree(argv[i]);
    80005c4c:	ffffb097          	auipc	ra,0xffffb
    80005c50:	dd8080e7          	jalr	-552(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c54:	04a1                	addi	s1,s1,8
    80005c56:	ff3499e3          	bne	s1,s3,80005c48 <sys_exec+0xe4>
    80005c5a:	a011                	j	80005c5e <sys_exec+0xfa>
  return -1;
    80005c5c:	597d                	li	s2,-1
}
    80005c5e:	854a                	mv	a0,s2
    80005c60:	60be                	ld	ra,456(sp)
    80005c62:	641e                	ld	s0,448(sp)
    80005c64:	74fa                	ld	s1,440(sp)
    80005c66:	795a                	ld	s2,432(sp)
    80005c68:	79ba                	ld	s3,424(sp)
    80005c6a:	7a1a                	ld	s4,416(sp)
    80005c6c:	6afa                	ld	s5,408(sp)
    80005c6e:	6179                	addi	sp,sp,464
    80005c70:	8082                	ret

0000000080005c72 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c72:	7139                	addi	sp,sp,-64
    80005c74:	fc06                	sd	ra,56(sp)
    80005c76:	f822                	sd	s0,48(sp)
    80005c78:	f426                	sd	s1,40(sp)
    80005c7a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c7c:	ffffc097          	auipc	ra,0xffffc
    80005c80:	e94080e7          	jalr	-364(ra) # 80001b10 <myproc>
    80005c84:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c86:	fd840593          	addi	a1,s0,-40
    80005c8a:	4501                	li	a0,0
    80005c8c:	ffffd097          	auipc	ra,0xffffd
    80005c90:	fc0080e7          	jalr	-64(ra) # 80002c4c <argaddr>
    return -1;
    80005c94:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c96:	0e054063          	bltz	a0,80005d76 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c9a:	fc840593          	addi	a1,s0,-56
    80005c9e:	fd040513          	addi	a0,s0,-48
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	dba080e7          	jalr	-582(ra) # 80004a5c <pipealloc>
    return -1;
    80005caa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cac:	0c054563          	bltz	a0,80005d76 <sys_pipe+0x104>
  fd0 = -1;
    80005cb0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cb4:	fd043503          	ld	a0,-48(s0)
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	508080e7          	jalr	1288(ra) # 800051c0 <fdalloc>
    80005cc0:	fca42223          	sw	a0,-60(s0)
    80005cc4:	08054c63          	bltz	a0,80005d5c <sys_pipe+0xea>
    80005cc8:	fc843503          	ld	a0,-56(s0)
    80005ccc:	fffff097          	auipc	ra,0xfffff
    80005cd0:	4f4080e7          	jalr	1268(ra) # 800051c0 <fdalloc>
    80005cd4:	fca42023          	sw	a0,-64(s0)
    80005cd8:	06054863          	bltz	a0,80005d48 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cdc:	4691                	li	a3,4
    80005cde:	fc440613          	addi	a2,s0,-60
    80005ce2:	fd843583          	ld	a1,-40(s0)
    80005ce6:	68a8                	ld	a0,80(s1)
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	a3c080e7          	jalr	-1476(ra) # 80001724 <copyout>
    80005cf0:	02054063          	bltz	a0,80005d10 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cf4:	4691                	li	a3,4
    80005cf6:	fc040613          	addi	a2,s0,-64
    80005cfa:	fd843583          	ld	a1,-40(s0)
    80005cfe:	0591                	addi	a1,a1,4
    80005d00:	68a8                	ld	a0,80(s1)
    80005d02:	ffffc097          	auipc	ra,0xffffc
    80005d06:	a22080e7          	jalr	-1502(ra) # 80001724 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d0a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d0c:	06055563          	bgez	a0,80005d76 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d10:	fc442783          	lw	a5,-60(s0)
    80005d14:	07e9                	addi	a5,a5,26
    80005d16:	078e                	slli	a5,a5,0x3
    80005d18:	97a6                	add	a5,a5,s1
    80005d1a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d1e:	fc042503          	lw	a0,-64(s0)
    80005d22:	0569                	addi	a0,a0,26
    80005d24:	050e                	slli	a0,a0,0x3
    80005d26:	9526                	add	a0,a0,s1
    80005d28:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d2c:	fd043503          	ld	a0,-48(s0)
    80005d30:	fffff097          	auipc	ra,0xfffff
    80005d34:	9d6080e7          	jalr	-1578(ra) # 80004706 <fileclose>
    fileclose(wf);
    80005d38:	fc843503          	ld	a0,-56(s0)
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	9ca080e7          	jalr	-1590(ra) # 80004706 <fileclose>
    return -1;
    80005d44:	57fd                	li	a5,-1
    80005d46:	a805                	j	80005d76 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d48:	fc442783          	lw	a5,-60(s0)
    80005d4c:	0007c863          	bltz	a5,80005d5c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d50:	01a78513          	addi	a0,a5,26
    80005d54:	050e                	slli	a0,a0,0x3
    80005d56:	9526                	add	a0,a0,s1
    80005d58:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d5c:	fd043503          	ld	a0,-48(s0)
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	9a6080e7          	jalr	-1626(ra) # 80004706 <fileclose>
    fileclose(wf);
    80005d68:	fc843503          	ld	a0,-56(s0)
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	99a080e7          	jalr	-1638(ra) # 80004706 <fileclose>
    return -1;
    80005d74:	57fd                	li	a5,-1
}
    80005d76:	853e                	mv	a0,a5
    80005d78:	70e2                	ld	ra,56(sp)
    80005d7a:	7442                	ld	s0,48(sp)
    80005d7c:	74a2                	ld	s1,40(sp)
    80005d7e:	6121                	addi	sp,sp,64
    80005d80:	8082                	ret
	...

0000000080005d90 <kernelvec>:
    80005d90:	7111                	addi	sp,sp,-256
    80005d92:	e006                	sd	ra,0(sp)
    80005d94:	e40a                	sd	sp,8(sp)
    80005d96:	e80e                	sd	gp,16(sp)
    80005d98:	ec12                	sd	tp,24(sp)
    80005d9a:	f016                	sd	t0,32(sp)
    80005d9c:	f41a                	sd	t1,40(sp)
    80005d9e:	f81e                	sd	t2,48(sp)
    80005da0:	fc22                	sd	s0,56(sp)
    80005da2:	e0a6                	sd	s1,64(sp)
    80005da4:	e4aa                	sd	a0,72(sp)
    80005da6:	e8ae                	sd	a1,80(sp)
    80005da8:	ecb2                	sd	a2,88(sp)
    80005daa:	f0b6                	sd	a3,96(sp)
    80005dac:	f4ba                	sd	a4,104(sp)
    80005dae:	f8be                	sd	a5,112(sp)
    80005db0:	fcc2                	sd	a6,120(sp)
    80005db2:	e146                	sd	a7,128(sp)
    80005db4:	e54a                	sd	s2,136(sp)
    80005db6:	e94e                	sd	s3,144(sp)
    80005db8:	ed52                	sd	s4,152(sp)
    80005dba:	f156                	sd	s5,160(sp)
    80005dbc:	f55a                	sd	s6,168(sp)
    80005dbe:	f95e                	sd	s7,176(sp)
    80005dc0:	fd62                	sd	s8,184(sp)
    80005dc2:	e1e6                	sd	s9,192(sp)
    80005dc4:	e5ea                	sd	s10,200(sp)
    80005dc6:	e9ee                	sd	s11,208(sp)
    80005dc8:	edf2                	sd	t3,216(sp)
    80005dca:	f1f6                	sd	t4,224(sp)
    80005dcc:	f5fa                	sd	t5,232(sp)
    80005dce:	f9fe                	sd	t6,240(sp)
    80005dd0:	c8dfc0ef          	jal	ra,80002a5c <kerneltrap>
    80005dd4:	6082                	ld	ra,0(sp)
    80005dd6:	6122                	ld	sp,8(sp)
    80005dd8:	61c2                	ld	gp,16(sp)
    80005dda:	7282                	ld	t0,32(sp)
    80005ddc:	7322                	ld	t1,40(sp)
    80005dde:	73c2                	ld	t2,48(sp)
    80005de0:	7462                	ld	s0,56(sp)
    80005de2:	6486                	ld	s1,64(sp)
    80005de4:	6526                	ld	a0,72(sp)
    80005de6:	65c6                	ld	a1,80(sp)
    80005de8:	6666                	ld	a2,88(sp)
    80005dea:	7686                	ld	a3,96(sp)
    80005dec:	7726                	ld	a4,104(sp)
    80005dee:	77c6                	ld	a5,112(sp)
    80005df0:	7866                	ld	a6,120(sp)
    80005df2:	688a                	ld	a7,128(sp)
    80005df4:	692a                	ld	s2,136(sp)
    80005df6:	69ca                	ld	s3,144(sp)
    80005df8:	6a6a                	ld	s4,152(sp)
    80005dfa:	7a8a                	ld	s5,160(sp)
    80005dfc:	7b2a                	ld	s6,168(sp)
    80005dfe:	7bca                	ld	s7,176(sp)
    80005e00:	7c6a                	ld	s8,184(sp)
    80005e02:	6c8e                	ld	s9,192(sp)
    80005e04:	6d2e                	ld	s10,200(sp)
    80005e06:	6dce                	ld	s11,208(sp)
    80005e08:	6e6e                	ld	t3,216(sp)
    80005e0a:	7e8e                	ld	t4,224(sp)
    80005e0c:	7f2e                	ld	t5,232(sp)
    80005e0e:	7fce                	ld	t6,240(sp)
    80005e10:	6111                	addi	sp,sp,256
    80005e12:	10200073          	sret
    80005e16:	00000013          	nop
    80005e1a:	00000013          	nop
    80005e1e:	0001                	nop

0000000080005e20 <timervec>:
    80005e20:	34051573          	csrrw	a0,mscratch,a0
    80005e24:	e10c                	sd	a1,0(a0)
    80005e26:	e510                	sd	a2,8(a0)
    80005e28:	e914                	sd	a3,16(a0)
    80005e2a:	710c                	ld	a1,32(a0)
    80005e2c:	7510                	ld	a2,40(a0)
    80005e2e:	6194                	ld	a3,0(a1)
    80005e30:	96b2                	add	a3,a3,a2
    80005e32:	e194                	sd	a3,0(a1)
    80005e34:	4589                	li	a1,2
    80005e36:	14459073          	csrw	sip,a1
    80005e3a:	6914                	ld	a3,16(a0)
    80005e3c:	6510                	ld	a2,8(a0)
    80005e3e:	610c                	ld	a1,0(a0)
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	30200073          	mret
	...

0000000080005e4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e4a:	1141                	addi	sp,sp,-16
    80005e4c:	e422                	sd	s0,8(sp)
    80005e4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e50:	0c0007b7          	lui	a5,0xc000
    80005e54:	4705                	li	a4,1
    80005e56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e58:	c3d8                	sw	a4,4(a5)
}
    80005e5a:	6422                	ld	s0,8(sp)
    80005e5c:	0141                	addi	sp,sp,16
    80005e5e:	8082                	ret

0000000080005e60 <plicinithart>:

void
plicinithart(void)
{
    80005e60:	1141                	addi	sp,sp,-16
    80005e62:	e406                	sd	ra,8(sp)
    80005e64:	e022                	sd	s0,0(sp)
    80005e66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	c7c080e7          	jalr	-900(ra) # 80001ae4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e70:	0085171b          	slliw	a4,a0,0x8
    80005e74:	0c0027b7          	lui	a5,0xc002
    80005e78:	97ba                	add	a5,a5,a4
    80005e7a:	40200713          	li	a4,1026
    80005e7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e82:	00d5151b          	slliw	a0,a0,0xd
    80005e86:	0c2017b7          	lui	a5,0xc201
    80005e8a:	953e                	add	a0,a0,a5
    80005e8c:	00052023          	sw	zero,0(a0)
}
    80005e90:	60a2                	ld	ra,8(sp)
    80005e92:	6402                	ld	s0,0(sp)
    80005e94:	0141                	addi	sp,sp,16
    80005e96:	8082                	ret

0000000080005e98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e98:	1141                	addi	sp,sp,-16
    80005e9a:	e406                	sd	ra,8(sp)
    80005e9c:	e022                	sd	s0,0(sp)
    80005e9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ea0:	ffffc097          	auipc	ra,0xffffc
    80005ea4:	c44080e7          	jalr	-956(ra) # 80001ae4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ea8:	00d5179b          	slliw	a5,a0,0xd
    80005eac:	0c201537          	lui	a0,0xc201
    80005eb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005eb2:	4148                	lw	a0,4(a0)
    80005eb4:	60a2                	ld	ra,8(sp)
    80005eb6:	6402                	ld	s0,0(sp)
    80005eb8:	0141                	addi	sp,sp,16
    80005eba:	8082                	ret

0000000080005ebc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ebc:	1101                	addi	sp,sp,-32
    80005ebe:	ec06                	sd	ra,24(sp)
    80005ec0:	e822                	sd	s0,16(sp)
    80005ec2:	e426                	sd	s1,8(sp)
    80005ec4:	1000                	addi	s0,sp,32
    80005ec6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	c1c080e7          	jalr	-996(ra) # 80001ae4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ed0:	00d5151b          	slliw	a0,a0,0xd
    80005ed4:	0c2017b7          	lui	a5,0xc201
    80005ed8:	97aa                	add	a5,a5,a0
    80005eda:	c3c4                	sw	s1,4(a5)
}
    80005edc:	60e2                	ld	ra,24(sp)
    80005ede:	6442                	ld	s0,16(sp)
    80005ee0:	64a2                	ld	s1,8(sp)
    80005ee2:	6105                	addi	sp,sp,32
    80005ee4:	8082                	ret

0000000080005ee6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ee6:	1141                	addi	sp,sp,-16
    80005ee8:	e406                	sd	ra,8(sp)
    80005eea:	e022                	sd	s0,0(sp)
    80005eec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eee:	479d                	li	a5,7
    80005ef0:	04a7cc63          	blt	a5,a0,80005f48 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005ef4:	0001d797          	auipc	a5,0x1d
    80005ef8:	10c78793          	addi	a5,a5,268 # 80023000 <disk>
    80005efc:	00a78733          	add	a4,a5,a0
    80005f00:	6789                	lui	a5,0x2
    80005f02:	97ba                	add	a5,a5,a4
    80005f04:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f08:	eba1                	bnez	a5,80005f58 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f0a:	00451713          	slli	a4,a0,0x4
    80005f0e:	0001f797          	auipc	a5,0x1f
    80005f12:	0f27b783          	ld	a5,242(a5) # 80025000 <disk+0x2000>
    80005f16:	97ba                	add	a5,a5,a4
    80005f18:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005f1c:	0001d797          	auipc	a5,0x1d
    80005f20:	0e478793          	addi	a5,a5,228 # 80023000 <disk>
    80005f24:	97aa                	add	a5,a5,a0
    80005f26:	6509                	lui	a0,0x2
    80005f28:	953e                	add	a0,a0,a5
    80005f2a:	4785                	li	a5,1
    80005f2c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f30:	0001f517          	auipc	a0,0x1f
    80005f34:	0e850513          	addi	a0,a0,232 # 80025018 <disk+0x2018>
    80005f38:	ffffc097          	auipc	ra,0xffffc
    80005f3c:	576080e7          	jalr	1398(ra) # 800024ae <wakeup>
}
    80005f40:	60a2                	ld	ra,8(sp)
    80005f42:	6402                	ld	s0,0(sp)
    80005f44:	0141                	addi	sp,sp,16
    80005f46:	8082                	ret
    panic("virtio_disk_intr 1");
    80005f48:	00003517          	auipc	a0,0x3
    80005f4c:	a2850513          	addi	a0,a0,-1496 # 80008970 <sysnames+0x330>
    80005f50:	ffffa097          	auipc	ra,0xffffa
    80005f54:	5f8080e7          	jalr	1528(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005f58:	00003517          	auipc	a0,0x3
    80005f5c:	a3050513          	addi	a0,a0,-1488 # 80008988 <sysnames+0x348>
    80005f60:	ffffa097          	auipc	ra,0xffffa
    80005f64:	5e8080e7          	jalr	1512(ra) # 80000548 <panic>

0000000080005f68 <virtio_disk_init>:
{
    80005f68:	1101                	addi	sp,sp,-32
    80005f6a:	ec06                	sd	ra,24(sp)
    80005f6c:	e822                	sd	s0,16(sp)
    80005f6e:	e426                	sd	s1,8(sp)
    80005f70:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f72:	00003597          	auipc	a1,0x3
    80005f76:	a2e58593          	addi	a1,a1,-1490 # 800089a0 <sysnames+0x360>
    80005f7a:	0001f517          	auipc	a0,0x1f
    80005f7e:	12e50513          	addi	a0,a0,302 # 800250a8 <disk+0x20a8>
    80005f82:	ffffb097          	auipc	ra,0xffffb
    80005f86:	c48080e7          	jalr	-952(ra) # 80000bca <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f8a:	100017b7          	lui	a5,0x10001
    80005f8e:	4398                	lw	a4,0(a5)
    80005f90:	2701                	sext.w	a4,a4
    80005f92:	747277b7          	lui	a5,0x74727
    80005f96:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f9a:	0ef71163          	bne	a4,a5,8000607c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f9e:	100017b7          	lui	a5,0x10001
    80005fa2:	43dc                	lw	a5,4(a5)
    80005fa4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fa6:	4705                	li	a4,1
    80005fa8:	0ce79a63          	bne	a5,a4,8000607c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fac:	100017b7          	lui	a5,0x10001
    80005fb0:	479c                	lw	a5,8(a5)
    80005fb2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fb4:	4709                	li	a4,2
    80005fb6:	0ce79363          	bne	a5,a4,8000607c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fba:	100017b7          	lui	a5,0x10001
    80005fbe:	47d8                	lw	a4,12(a5)
    80005fc0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fc2:	554d47b7          	lui	a5,0x554d4
    80005fc6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fca:	0af71963          	bne	a4,a5,8000607c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fce:	100017b7          	lui	a5,0x10001
    80005fd2:	4705                	li	a4,1
    80005fd4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd6:	470d                	li	a4,3
    80005fd8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fda:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fdc:	c7ffe737          	lui	a4,0xc7ffe
    80005fe0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80005fe4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fe6:	2701                	sext.w	a4,a4
    80005fe8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fea:	472d                	li	a4,11
    80005fec:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fee:	473d                	li	a4,15
    80005ff0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ff2:	6705                	lui	a4,0x1
    80005ff4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ff6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ffa:	5bdc                	lw	a5,52(a5)
    80005ffc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ffe:	c7d9                	beqz	a5,8000608c <virtio_disk_init+0x124>
  if(max < NUM)
    80006000:	471d                	li	a4,7
    80006002:	08f77d63          	bgeu	a4,a5,8000609c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006006:	100014b7          	lui	s1,0x10001
    8000600a:	47a1                	li	a5,8
    8000600c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000600e:	6609                	lui	a2,0x2
    80006010:	4581                	li	a1,0
    80006012:	0001d517          	auipc	a0,0x1d
    80006016:	fee50513          	addi	a0,a0,-18 # 80023000 <disk>
    8000601a:	ffffb097          	auipc	ra,0xffffb
    8000601e:	d3c080e7          	jalr	-708(ra) # 80000d56 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006022:	0001d717          	auipc	a4,0x1d
    80006026:	fde70713          	addi	a4,a4,-34 # 80023000 <disk>
    8000602a:	00c75793          	srli	a5,a4,0xc
    8000602e:	2781                	sext.w	a5,a5
    80006030:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006032:	0001f797          	auipc	a5,0x1f
    80006036:	fce78793          	addi	a5,a5,-50 # 80025000 <disk+0x2000>
    8000603a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000603c:	0001d717          	auipc	a4,0x1d
    80006040:	04470713          	addi	a4,a4,68 # 80023080 <disk+0x80>
    80006044:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006046:	0001e717          	auipc	a4,0x1e
    8000604a:	fba70713          	addi	a4,a4,-70 # 80024000 <disk+0x1000>
    8000604e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006050:	4705                	li	a4,1
    80006052:	00e78c23          	sb	a4,24(a5)
    80006056:	00e78ca3          	sb	a4,25(a5)
    8000605a:	00e78d23          	sb	a4,26(a5)
    8000605e:	00e78da3          	sb	a4,27(a5)
    80006062:	00e78e23          	sb	a4,28(a5)
    80006066:	00e78ea3          	sb	a4,29(a5)
    8000606a:	00e78f23          	sb	a4,30(a5)
    8000606e:	00e78fa3          	sb	a4,31(a5)
}
    80006072:	60e2                	ld	ra,24(sp)
    80006074:	6442                	ld	s0,16(sp)
    80006076:	64a2                	ld	s1,8(sp)
    80006078:	6105                	addi	sp,sp,32
    8000607a:	8082                	ret
    panic("could not find virtio disk");
    8000607c:	00003517          	auipc	a0,0x3
    80006080:	93450513          	addi	a0,a0,-1740 # 800089b0 <sysnames+0x370>
    80006084:	ffffa097          	auipc	ra,0xffffa
    80006088:	4c4080e7          	jalr	1220(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    8000608c:	00003517          	auipc	a0,0x3
    80006090:	94450513          	addi	a0,a0,-1724 # 800089d0 <sysnames+0x390>
    80006094:	ffffa097          	auipc	ra,0xffffa
    80006098:	4b4080e7          	jalr	1204(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000609c:	00003517          	auipc	a0,0x3
    800060a0:	95450513          	addi	a0,a0,-1708 # 800089f0 <sysnames+0x3b0>
    800060a4:	ffffa097          	auipc	ra,0xffffa
    800060a8:	4a4080e7          	jalr	1188(ra) # 80000548 <panic>

00000000800060ac <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060ac:	7119                	addi	sp,sp,-128
    800060ae:	fc86                	sd	ra,120(sp)
    800060b0:	f8a2                	sd	s0,112(sp)
    800060b2:	f4a6                	sd	s1,104(sp)
    800060b4:	f0ca                	sd	s2,96(sp)
    800060b6:	ecce                	sd	s3,88(sp)
    800060b8:	e8d2                	sd	s4,80(sp)
    800060ba:	e4d6                	sd	s5,72(sp)
    800060bc:	e0da                	sd	s6,64(sp)
    800060be:	fc5e                	sd	s7,56(sp)
    800060c0:	f862                	sd	s8,48(sp)
    800060c2:	f466                	sd	s9,40(sp)
    800060c4:	f06a                	sd	s10,32(sp)
    800060c6:	0100                	addi	s0,sp,128
    800060c8:	892a                	mv	s2,a0
    800060ca:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060cc:	00c52c83          	lw	s9,12(a0)
    800060d0:	001c9c9b          	slliw	s9,s9,0x1
    800060d4:	1c82                	slli	s9,s9,0x20
    800060d6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060da:	0001f517          	auipc	a0,0x1f
    800060de:	fce50513          	addi	a0,a0,-50 # 800250a8 <disk+0x20a8>
    800060e2:	ffffb097          	auipc	ra,0xffffb
    800060e6:	b78080e7          	jalr	-1160(ra) # 80000c5a <acquire>
  for(int i = 0; i < 3; i++){
    800060ea:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060ec:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060ee:	0001db97          	auipc	s7,0x1d
    800060f2:	f12b8b93          	addi	s7,s7,-238 # 80023000 <disk>
    800060f6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800060f8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060fa:	8a4e                	mv	s4,s3
    800060fc:	a051                	j	80006180 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800060fe:	00fb86b3          	add	a3,s7,a5
    80006102:	96da                	add	a3,a3,s6
    80006104:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006108:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000610a:	0207c563          	bltz	a5,80006134 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000610e:	2485                	addiw	s1,s1,1
    80006110:	0711                	addi	a4,a4,4
    80006112:	23548d63          	beq	s1,s5,8000634c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006116:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006118:	0001f697          	auipc	a3,0x1f
    8000611c:	f0068693          	addi	a3,a3,-256 # 80025018 <disk+0x2018>
    80006120:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006122:	0006c583          	lbu	a1,0(a3)
    80006126:	fde1                	bnez	a1,800060fe <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006128:	2785                	addiw	a5,a5,1
    8000612a:	0685                	addi	a3,a3,1
    8000612c:	ff879be3          	bne	a5,s8,80006122 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006130:	57fd                	li	a5,-1
    80006132:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006134:	02905a63          	blez	s1,80006168 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006138:	f9042503          	lw	a0,-112(s0)
    8000613c:	00000097          	auipc	ra,0x0
    80006140:	daa080e7          	jalr	-598(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    80006144:	4785                	li	a5,1
    80006146:	0297d163          	bge	a5,s1,80006168 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000614a:	f9442503          	lw	a0,-108(s0)
    8000614e:	00000097          	auipc	ra,0x0
    80006152:	d98080e7          	jalr	-616(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    80006156:	4789                	li	a5,2
    80006158:	0097d863          	bge	a5,s1,80006168 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000615c:	f9842503          	lw	a0,-104(s0)
    80006160:	00000097          	auipc	ra,0x0
    80006164:	d86080e7          	jalr	-634(ra) # 80005ee6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006168:	0001f597          	auipc	a1,0x1f
    8000616c:	f4058593          	addi	a1,a1,-192 # 800250a8 <disk+0x20a8>
    80006170:	0001f517          	auipc	a0,0x1f
    80006174:	ea850513          	addi	a0,a0,-344 # 80025018 <disk+0x2018>
    80006178:	ffffc097          	auipc	ra,0xffffc
    8000617c:	1b0080e7          	jalr	432(ra) # 80002328 <sleep>
  for(int i = 0; i < 3; i++){
    80006180:	f9040713          	addi	a4,s0,-112
    80006184:	84ce                	mv	s1,s3
    80006186:	bf41                	j	80006116 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006188:	4785                	li	a5,1
    8000618a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000618e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006192:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006196:	f9042983          	lw	s3,-112(s0)
    8000619a:	00499493          	slli	s1,s3,0x4
    8000619e:	0001fa17          	auipc	s4,0x1f
    800061a2:	e62a0a13          	addi	s4,s4,-414 # 80025000 <disk+0x2000>
    800061a6:	000a3a83          	ld	s5,0(s4)
    800061aa:	9aa6                	add	s5,s5,s1
    800061ac:	f8040513          	addi	a0,s0,-128
    800061b0:	ffffb097          	auipc	ra,0xffffb
    800061b4:	f82080e7          	jalr	-126(ra) # 80001132 <kvmpa>
    800061b8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800061bc:	000a3783          	ld	a5,0(s4)
    800061c0:	97a6                	add	a5,a5,s1
    800061c2:	4741                	li	a4,16
    800061c4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061c6:	000a3783          	ld	a5,0(s4)
    800061ca:	97a6                	add	a5,a5,s1
    800061cc:	4705                	li	a4,1
    800061ce:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800061d2:	f9442703          	lw	a4,-108(s0)
    800061d6:	000a3783          	ld	a5,0(s4)
    800061da:	97a6                	add	a5,a5,s1
    800061dc:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061e0:	0712                	slli	a4,a4,0x4
    800061e2:	000a3783          	ld	a5,0(s4)
    800061e6:	97ba                	add	a5,a5,a4
    800061e8:	05890693          	addi	a3,s2,88
    800061ec:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800061ee:	000a3783          	ld	a5,0(s4)
    800061f2:	97ba                	add	a5,a5,a4
    800061f4:	40000693          	li	a3,1024
    800061f8:	c794                	sw	a3,8(a5)
  if(write)
    800061fa:	100d0a63          	beqz	s10,8000630e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061fe:	0001f797          	auipc	a5,0x1f
    80006202:	e027b783          	ld	a5,-510(a5) # 80025000 <disk+0x2000>
    80006206:	97ba                	add	a5,a5,a4
    80006208:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000620c:	0001d517          	auipc	a0,0x1d
    80006210:	df450513          	addi	a0,a0,-524 # 80023000 <disk>
    80006214:	0001f797          	auipc	a5,0x1f
    80006218:	dec78793          	addi	a5,a5,-532 # 80025000 <disk+0x2000>
    8000621c:	6394                	ld	a3,0(a5)
    8000621e:	96ba                	add	a3,a3,a4
    80006220:	00c6d603          	lhu	a2,12(a3)
    80006224:	00166613          	ori	a2,a2,1
    80006228:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000622c:	f9842683          	lw	a3,-104(s0)
    80006230:	6390                	ld	a2,0(a5)
    80006232:	9732                	add	a4,a4,a2
    80006234:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006238:	20098613          	addi	a2,s3,512
    8000623c:	0612                	slli	a2,a2,0x4
    8000623e:	962a                	add	a2,a2,a0
    80006240:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006244:	00469713          	slli	a4,a3,0x4
    80006248:	6394                	ld	a3,0(a5)
    8000624a:	96ba                	add	a3,a3,a4
    8000624c:	6589                	lui	a1,0x2
    8000624e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006252:	94ae                	add	s1,s1,a1
    80006254:	94aa                	add	s1,s1,a0
    80006256:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006258:	6394                	ld	a3,0(a5)
    8000625a:	96ba                	add	a3,a3,a4
    8000625c:	4585                	li	a1,1
    8000625e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006260:	6394                	ld	a3,0(a5)
    80006262:	96ba                	add	a3,a3,a4
    80006264:	4509                	li	a0,2
    80006266:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000626a:	6394                	ld	a3,0(a5)
    8000626c:	9736                	add	a4,a4,a3
    8000626e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006272:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006276:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000627a:	6794                	ld	a3,8(a5)
    8000627c:	0026d703          	lhu	a4,2(a3)
    80006280:	8b1d                	andi	a4,a4,7
    80006282:	2709                	addiw	a4,a4,2
    80006284:	0706                	slli	a4,a4,0x1
    80006286:	9736                	add	a4,a4,a3
    80006288:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000628c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006290:	6798                	ld	a4,8(a5)
    80006292:	00275783          	lhu	a5,2(a4)
    80006296:	2785                	addiw	a5,a5,1
    80006298:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000629c:	100017b7          	lui	a5,0x10001
    800062a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062a4:	00492703          	lw	a4,4(s2)
    800062a8:	4785                	li	a5,1
    800062aa:	02f71163          	bne	a4,a5,800062cc <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800062ae:	0001f997          	auipc	s3,0x1f
    800062b2:	dfa98993          	addi	s3,s3,-518 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800062b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062b8:	85ce                	mv	a1,s3
    800062ba:	854a                	mv	a0,s2
    800062bc:	ffffc097          	auipc	ra,0xffffc
    800062c0:	06c080e7          	jalr	108(ra) # 80002328 <sleep>
  while(b->disk == 1) {
    800062c4:	00492783          	lw	a5,4(s2)
    800062c8:	fe9788e3          	beq	a5,s1,800062b8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800062cc:	f9042483          	lw	s1,-112(s0)
    800062d0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800062d4:	00479713          	slli	a4,a5,0x4
    800062d8:	0001d797          	auipc	a5,0x1d
    800062dc:	d2878793          	addi	a5,a5,-728 # 80023000 <disk>
    800062e0:	97ba                	add	a5,a5,a4
    800062e2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062e6:	0001f917          	auipc	s2,0x1f
    800062ea:	d1a90913          	addi	s2,s2,-742 # 80025000 <disk+0x2000>
    free_desc(i);
    800062ee:	8526                	mv	a0,s1
    800062f0:	00000097          	auipc	ra,0x0
    800062f4:	bf6080e7          	jalr	-1034(ra) # 80005ee6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062f8:	0492                	slli	s1,s1,0x4
    800062fa:	00093783          	ld	a5,0(s2)
    800062fe:	94be                	add	s1,s1,a5
    80006300:	00c4d783          	lhu	a5,12(s1)
    80006304:	8b85                	andi	a5,a5,1
    80006306:	cf89                	beqz	a5,80006320 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006308:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000630c:	b7cd                	j	800062ee <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000630e:	0001f797          	auipc	a5,0x1f
    80006312:	cf27b783          	ld	a5,-782(a5) # 80025000 <disk+0x2000>
    80006316:	97ba                	add	a5,a5,a4
    80006318:	4689                	li	a3,2
    8000631a:	00d79623          	sh	a3,12(a5)
    8000631e:	b5fd                	j	8000620c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006320:	0001f517          	auipc	a0,0x1f
    80006324:	d8850513          	addi	a0,a0,-632 # 800250a8 <disk+0x20a8>
    80006328:	ffffb097          	auipc	ra,0xffffb
    8000632c:	9e6080e7          	jalr	-1562(ra) # 80000d0e <release>
}
    80006330:	70e6                	ld	ra,120(sp)
    80006332:	7446                	ld	s0,112(sp)
    80006334:	74a6                	ld	s1,104(sp)
    80006336:	7906                	ld	s2,96(sp)
    80006338:	69e6                	ld	s3,88(sp)
    8000633a:	6a46                	ld	s4,80(sp)
    8000633c:	6aa6                	ld	s5,72(sp)
    8000633e:	6b06                	ld	s6,64(sp)
    80006340:	7be2                	ld	s7,56(sp)
    80006342:	7c42                	ld	s8,48(sp)
    80006344:	7ca2                	ld	s9,40(sp)
    80006346:	7d02                	ld	s10,32(sp)
    80006348:	6109                	addi	sp,sp,128
    8000634a:	8082                	ret
  if(write)
    8000634c:	e20d1ee3          	bnez	s10,80006188 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006350:	f8042023          	sw	zero,-128(s0)
    80006354:	bd2d                	j	8000618e <virtio_disk_rw+0xe2>

0000000080006356 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006356:	1101                	addi	sp,sp,-32
    80006358:	ec06                	sd	ra,24(sp)
    8000635a:	e822                	sd	s0,16(sp)
    8000635c:	e426                	sd	s1,8(sp)
    8000635e:	e04a                	sd	s2,0(sp)
    80006360:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006362:	0001f517          	auipc	a0,0x1f
    80006366:	d4650513          	addi	a0,a0,-698 # 800250a8 <disk+0x20a8>
    8000636a:	ffffb097          	auipc	ra,0xffffb
    8000636e:	8f0080e7          	jalr	-1808(ra) # 80000c5a <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006372:	0001f717          	auipc	a4,0x1f
    80006376:	c8e70713          	addi	a4,a4,-882 # 80025000 <disk+0x2000>
    8000637a:	02075783          	lhu	a5,32(a4)
    8000637e:	6b18                	ld	a4,16(a4)
    80006380:	00275683          	lhu	a3,2(a4)
    80006384:	8ebd                	xor	a3,a3,a5
    80006386:	8a9d                	andi	a3,a3,7
    80006388:	cab9                	beqz	a3,800063de <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000638a:	0001d917          	auipc	s2,0x1d
    8000638e:	c7690913          	addi	s2,s2,-906 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006392:	0001f497          	auipc	s1,0x1f
    80006396:	c6e48493          	addi	s1,s1,-914 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000639a:	078e                	slli	a5,a5,0x3
    8000639c:	97ba                	add	a5,a5,a4
    8000639e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800063a0:	20078713          	addi	a4,a5,512
    800063a4:	0712                	slli	a4,a4,0x4
    800063a6:	974a                	add	a4,a4,s2
    800063a8:	03074703          	lbu	a4,48(a4)
    800063ac:	ef21                	bnez	a4,80006404 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800063ae:	20078793          	addi	a5,a5,512
    800063b2:	0792                	slli	a5,a5,0x4
    800063b4:	97ca                	add	a5,a5,s2
    800063b6:	7798                	ld	a4,40(a5)
    800063b8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800063bc:	7788                	ld	a0,40(a5)
    800063be:	ffffc097          	auipc	ra,0xffffc
    800063c2:	0f0080e7          	jalr	240(ra) # 800024ae <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063c6:	0204d783          	lhu	a5,32(s1)
    800063ca:	2785                	addiw	a5,a5,1
    800063cc:	8b9d                	andi	a5,a5,7
    800063ce:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063d2:	6898                	ld	a4,16(s1)
    800063d4:	00275683          	lhu	a3,2(a4)
    800063d8:	8a9d                	andi	a3,a3,7
    800063da:	fcf690e3          	bne	a3,a5,8000639a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063de:	10001737          	lui	a4,0x10001
    800063e2:	533c                	lw	a5,96(a4)
    800063e4:	8b8d                	andi	a5,a5,3
    800063e6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800063e8:	0001f517          	auipc	a0,0x1f
    800063ec:	cc050513          	addi	a0,a0,-832 # 800250a8 <disk+0x20a8>
    800063f0:	ffffb097          	auipc	ra,0xffffb
    800063f4:	91e080e7          	jalr	-1762(ra) # 80000d0e <release>
}
    800063f8:	60e2                	ld	ra,24(sp)
    800063fa:	6442                	ld	s0,16(sp)
    800063fc:	64a2                	ld	s1,8(sp)
    800063fe:	6902                	ld	s2,0(sp)
    80006400:	6105                	addi	sp,sp,32
    80006402:	8082                	ret
      panic("virtio_disk_intr status");
    80006404:	00002517          	auipc	a0,0x2
    80006408:	60c50513          	addi	a0,a0,1548 # 80008a10 <sysnames+0x3d0>
    8000640c:	ffffa097          	auipc	ra,0xffffa
    80006410:	13c080e7          	jalr	316(ra) # 80000548 <panic>

0000000080006414 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    80006414:	7179                	addi	sp,sp,-48
    80006416:	f406                	sd	ra,40(sp)
    80006418:	f022                	sd	s0,32(sp)
    8000641a:	ec26                	sd	s1,24(sp)
    8000641c:	e84a                	sd	s2,16(sp)
    8000641e:	e44e                	sd	s3,8(sp)
    80006420:	e052                	sd	s4,0(sp)
    80006422:	1800                	addi	s0,sp,48
    80006424:	892a                	mv	s2,a0
    80006426:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006428:	00003a17          	auipc	s4,0x3
    8000642c:	c00a0a13          	addi	s4,s4,-1024 # 80009028 <stats>
    80006430:	000a2683          	lw	a3,0(s4)
    80006434:	00002617          	auipc	a2,0x2
    80006438:	5f460613          	addi	a2,a2,1524 # 80008a28 <sysnames+0x3e8>
    8000643c:	00000097          	auipc	ra,0x0
    80006440:	2c2080e7          	jalr	706(ra) # 800066fe <snprintf>
    80006444:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    80006446:	004a2683          	lw	a3,4(s4)
    8000644a:	00002617          	auipc	a2,0x2
    8000644e:	5ee60613          	addi	a2,a2,1518 # 80008a38 <sysnames+0x3f8>
    80006452:	85ce                	mv	a1,s3
    80006454:	954a                	add	a0,a0,s2
    80006456:	00000097          	auipc	ra,0x0
    8000645a:	2a8080e7          	jalr	680(ra) # 800066fe <snprintf>
  return n;
}
    8000645e:	9d25                	addw	a0,a0,s1
    80006460:	70a2                	ld	ra,40(sp)
    80006462:	7402                	ld	s0,32(sp)
    80006464:	64e2                	ld	s1,24(sp)
    80006466:	6942                	ld	s2,16(sp)
    80006468:	69a2                	ld	s3,8(sp)
    8000646a:	6a02                	ld	s4,0(sp)
    8000646c:	6145                	addi	sp,sp,48
    8000646e:	8082                	ret

0000000080006470 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80006470:	7179                	addi	sp,sp,-48
    80006472:	f406                	sd	ra,40(sp)
    80006474:	f022                	sd	s0,32(sp)
    80006476:	ec26                	sd	s1,24(sp)
    80006478:	e84a                	sd	s2,16(sp)
    8000647a:	e44e                	sd	s3,8(sp)
    8000647c:	1800                	addi	s0,sp,48
    8000647e:	89ae                	mv	s3,a1
    80006480:	84b2                	mv	s1,a2
    80006482:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006484:	ffffb097          	auipc	ra,0xffffb
    80006488:	68c080e7          	jalr	1676(ra) # 80001b10 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    8000648c:	653c                	ld	a5,72(a0)
    8000648e:	02f4ff63          	bgeu	s1,a5,800064cc <copyin_new+0x5c>
    80006492:	01248733          	add	a4,s1,s2
    80006496:	02f77d63          	bgeu	a4,a5,800064d0 <copyin_new+0x60>
    8000649a:	02976d63          	bltu	a4,s1,800064d4 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    8000649e:	0009061b          	sext.w	a2,s2
    800064a2:	85a6                	mv	a1,s1
    800064a4:	854e                	mv	a0,s3
    800064a6:	ffffb097          	auipc	ra,0xffffb
    800064aa:	910080e7          	jalr	-1776(ra) # 80000db6 <memmove>
  stats.ncopyin++;   // XXX lock
    800064ae:	00003717          	auipc	a4,0x3
    800064b2:	b7a70713          	addi	a4,a4,-1158 # 80009028 <stats>
    800064b6:	431c                	lw	a5,0(a4)
    800064b8:	2785                	addiw	a5,a5,1
    800064ba:	c31c                	sw	a5,0(a4)
  return 0;
    800064bc:	4501                	li	a0,0
}
    800064be:	70a2                	ld	ra,40(sp)
    800064c0:	7402                	ld	s0,32(sp)
    800064c2:	64e2                	ld	s1,24(sp)
    800064c4:	6942                	ld	s2,16(sp)
    800064c6:	69a2                	ld	s3,8(sp)
    800064c8:	6145                	addi	sp,sp,48
    800064ca:	8082                	ret
    return -1;
    800064cc:	557d                	li	a0,-1
    800064ce:	bfc5                	j	800064be <copyin_new+0x4e>
    800064d0:	557d                	li	a0,-1
    800064d2:	b7f5                	j	800064be <copyin_new+0x4e>
    800064d4:	557d                	li	a0,-1
    800064d6:	b7e5                	j	800064be <copyin_new+0x4e>

00000000800064d8 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800064d8:	7179                	addi	sp,sp,-48
    800064da:	f406                	sd	ra,40(sp)
    800064dc:	f022                	sd	s0,32(sp)
    800064de:	ec26                	sd	s1,24(sp)
    800064e0:	e84a                	sd	s2,16(sp)
    800064e2:	e44e                	sd	s3,8(sp)
    800064e4:	1800                	addi	s0,sp,48
    800064e6:	89ae                	mv	s3,a1
    800064e8:	8932                	mv	s2,a2
    800064ea:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    800064ec:	ffffb097          	auipc	ra,0xffffb
    800064f0:	624080e7          	jalr	1572(ra) # 80001b10 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    800064f4:	00003717          	auipc	a4,0x3
    800064f8:	b3470713          	addi	a4,a4,-1228 # 80009028 <stats>
    800064fc:	435c                	lw	a5,4(a4)
    800064fe:	2785                	addiw	a5,a5,1
    80006500:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006502:	cc85                	beqz	s1,8000653a <copyinstr_new+0x62>
    80006504:	00990833          	add	a6,s2,s1
    80006508:	87ca                	mv	a5,s2
    8000650a:	6538                	ld	a4,72(a0)
    8000650c:	00e7ff63          	bgeu	a5,a4,8000652a <copyinstr_new+0x52>
    dst[i] = s[i];
    80006510:	0007c683          	lbu	a3,0(a5)
    80006514:	41278733          	sub	a4,a5,s2
    80006518:	974e                	add	a4,a4,s3
    8000651a:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    8000651e:	c285                	beqz	a3,8000653e <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006520:	0785                	addi	a5,a5,1
    80006522:	ff0794e3          	bne	a5,a6,8000650a <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    80006526:	557d                	li	a0,-1
    80006528:	a011                	j	8000652c <copyinstr_new+0x54>
    8000652a:	557d                	li	a0,-1
}
    8000652c:	70a2                	ld	ra,40(sp)
    8000652e:	7402                	ld	s0,32(sp)
    80006530:	64e2                	ld	s1,24(sp)
    80006532:	6942                	ld	s2,16(sp)
    80006534:	69a2                	ld	s3,8(sp)
    80006536:	6145                	addi	sp,sp,48
    80006538:	8082                	ret
  return -1;
    8000653a:	557d                	li	a0,-1
    8000653c:	bfc5                	j	8000652c <copyinstr_new+0x54>
      return 0;
    8000653e:	4501                	li	a0,0
    80006540:	b7f5                	j	8000652c <copyinstr_new+0x54>

0000000080006542 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006542:	1141                	addi	sp,sp,-16
    80006544:	e422                	sd	s0,8(sp)
    80006546:	0800                	addi	s0,sp,16
  return -1;
}
    80006548:	557d                	li	a0,-1
    8000654a:	6422                	ld	s0,8(sp)
    8000654c:	0141                	addi	sp,sp,16
    8000654e:	8082                	ret

0000000080006550 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006550:	7179                	addi	sp,sp,-48
    80006552:	f406                	sd	ra,40(sp)
    80006554:	f022                	sd	s0,32(sp)
    80006556:	ec26                	sd	s1,24(sp)
    80006558:	e84a                	sd	s2,16(sp)
    8000655a:	e44e                	sd	s3,8(sp)
    8000655c:	e052                	sd	s4,0(sp)
    8000655e:	1800                	addi	s0,sp,48
    80006560:	892a                	mv	s2,a0
    80006562:	89ae                	mv	s3,a1
    80006564:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    80006566:	00020517          	auipc	a0,0x20
    8000656a:	a9a50513          	addi	a0,a0,-1382 # 80026000 <stats>
    8000656e:	ffffa097          	auipc	ra,0xffffa
    80006572:	6ec080e7          	jalr	1772(ra) # 80000c5a <acquire>

  if(stats.sz == 0) {
    80006576:	00021797          	auipc	a5,0x21
    8000657a:	aa27a783          	lw	a5,-1374(a5) # 80027018 <stats+0x1018>
    8000657e:	cbb5                	beqz	a5,800065f2 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006580:	00021797          	auipc	a5,0x21
    80006584:	a8078793          	addi	a5,a5,-1408 # 80027000 <stats+0x1000>
    80006588:	4fd8                	lw	a4,28(a5)
    8000658a:	4f9c                	lw	a5,24(a5)
    8000658c:	9f99                	subw	a5,a5,a4
    8000658e:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006592:	06d05e63          	blez	a3,8000660e <statsread+0xbe>
    if(m > n)
    80006596:	8a3e                	mv	s4,a5
    80006598:	00d4d363          	bge	s1,a3,8000659e <statsread+0x4e>
    8000659c:	8a26                	mv	s4,s1
    8000659e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800065a2:	86a6                	mv	a3,s1
    800065a4:	00020617          	auipc	a2,0x20
    800065a8:	a7460613          	addi	a2,a2,-1420 # 80026018 <stats+0x18>
    800065ac:	963a                	add	a2,a2,a4
    800065ae:	85ce                	mv	a1,s3
    800065b0:	854a                	mv	a0,s2
    800065b2:	ffffc097          	auipc	ra,0xffffc
    800065b6:	fd8080e7          	jalr	-40(ra) # 8000258a <either_copyout>
    800065ba:	57fd                	li	a5,-1
    800065bc:	00f50a63          	beq	a0,a5,800065d0 <statsread+0x80>
      stats.off += m;
    800065c0:	00021717          	auipc	a4,0x21
    800065c4:	a4070713          	addi	a4,a4,-1472 # 80027000 <stats+0x1000>
    800065c8:	4f5c                	lw	a5,28(a4)
    800065ca:	014787bb          	addw	a5,a5,s4
    800065ce:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800065d0:	00020517          	auipc	a0,0x20
    800065d4:	a3050513          	addi	a0,a0,-1488 # 80026000 <stats>
    800065d8:	ffffa097          	auipc	ra,0xffffa
    800065dc:	736080e7          	jalr	1846(ra) # 80000d0e <release>
  return m;
}
    800065e0:	8526                	mv	a0,s1
    800065e2:	70a2                	ld	ra,40(sp)
    800065e4:	7402                	ld	s0,32(sp)
    800065e6:	64e2                	ld	s1,24(sp)
    800065e8:	6942                	ld	s2,16(sp)
    800065ea:	69a2                	ld	s3,8(sp)
    800065ec:	6a02                	ld	s4,0(sp)
    800065ee:	6145                	addi	sp,sp,48
    800065f0:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    800065f2:	6585                	lui	a1,0x1
    800065f4:	00020517          	auipc	a0,0x20
    800065f8:	a2450513          	addi	a0,a0,-1500 # 80026018 <stats+0x18>
    800065fc:	00000097          	auipc	ra,0x0
    80006600:	e18080e7          	jalr	-488(ra) # 80006414 <statscopyin>
    80006604:	00021797          	auipc	a5,0x21
    80006608:	a0a7aa23          	sw	a0,-1516(a5) # 80027018 <stats+0x1018>
    8000660c:	bf95                	j	80006580 <statsread+0x30>
    stats.sz = 0;
    8000660e:	00021797          	auipc	a5,0x21
    80006612:	9f278793          	addi	a5,a5,-1550 # 80027000 <stats+0x1000>
    80006616:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    8000661a:	0007ae23          	sw	zero,28(a5)
    m = -1;
    8000661e:	54fd                	li	s1,-1
    80006620:	bf45                	j	800065d0 <statsread+0x80>

0000000080006622 <statsinit>:

void
statsinit(void)
{
    80006622:	1141                	addi	sp,sp,-16
    80006624:	e406                	sd	ra,8(sp)
    80006626:	e022                	sd	s0,0(sp)
    80006628:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000662a:	00002597          	auipc	a1,0x2
    8000662e:	41e58593          	addi	a1,a1,1054 # 80008a48 <sysnames+0x408>
    80006632:	00020517          	auipc	a0,0x20
    80006636:	9ce50513          	addi	a0,a0,-1586 # 80026000 <stats>
    8000663a:	ffffa097          	auipc	ra,0xffffa
    8000663e:	590080e7          	jalr	1424(ra) # 80000bca <initlock>

  devsw[STATS].read = statsread;
    80006642:	0001b797          	auipc	a5,0x1b
    80006646:	56e78793          	addi	a5,a5,1390 # 80021bb0 <devsw>
    8000664a:	00000717          	auipc	a4,0x0
    8000664e:	f0670713          	addi	a4,a4,-250 # 80006550 <statsread>
    80006652:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006654:	00000717          	auipc	a4,0x0
    80006658:	eee70713          	addi	a4,a4,-274 # 80006542 <statswrite>
    8000665c:	f798                	sd	a4,40(a5)
}
    8000665e:	60a2                	ld	ra,8(sp)
    80006660:	6402                	ld	s0,0(sp)
    80006662:	0141                	addi	sp,sp,16
    80006664:	8082                	ret

0000000080006666 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006666:	1101                	addi	sp,sp,-32
    80006668:	ec22                	sd	s0,24(sp)
    8000666a:	1000                	addi	s0,sp,32
    8000666c:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    8000666e:	c299                	beqz	a3,80006674 <sprintint+0xe>
    80006670:	0805c163          	bltz	a1,800066f2 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006674:	2581                	sext.w	a1,a1
    80006676:	4301                	li	t1,0

  i = 0;
    80006678:	fe040713          	addi	a4,s0,-32
    8000667c:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    8000667e:	2601                	sext.w	a2,a2
    80006680:	00002697          	auipc	a3,0x2
    80006684:	3d068693          	addi	a3,a3,976 # 80008a50 <digits>
    80006688:	88aa                	mv	a7,a0
    8000668a:	2505                	addiw	a0,a0,1
    8000668c:	02c5f7bb          	remuw	a5,a1,a2
    80006690:	1782                	slli	a5,a5,0x20
    80006692:	9381                	srli	a5,a5,0x20
    80006694:	97b6                	add	a5,a5,a3
    80006696:	0007c783          	lbu	a5,0(a5)
    8000669a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000669e:	0005879b          	sext.w	a5,a1
    800066a2:	02c5d5bb          	divuw	a1,a1,a2
    800066a6:	0705                	addi	a4,a4,1
    800066a8:	fec7f0e3          	bgeu	a5,a2,80006688 <sprintint+0x22>

  if(sign)
    800066ac:	00030b63          	beqz	t1,800066c2 <sprintint+0x5c>
    buf[i++] = '-';
    800066b0:	ff040793          	addi	a5,s0,-16
    800066b4:	97aa                	add	a5,a5,a0
    800066b6:	02d00713          	li	a4,45
    800066ba:	fee78823          	sb	a4,-16(a5)
    800066be:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800066c2:	02a05c63          	blez	a0,800066fa <sprintint+0x94>
    800066c6:	fe040793          	addi	a5,s0,-32
    800066ca:	00a78733          	add	a4,a5,a0
    800066ce:	87c2                	mv	a5,a6
    800066d0:	0805                	addi	a6,a6,1
    800066d2:	fff5061b          	addiw	a2,a0,-1
    800066d6:	1602                	slli	a2,a2,0x20
    800066d8:	9201                	srli	a2,a2,0x20
    800066da:	9642                	add	a2,a2,a6
  *s = c;
    800066dc:	fff74683          	lbu	a3,-1(a4)
    800066e0:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    800066e4:	177d                	addi	a4,a4,-1
    800066e6:	0785                	addi	a5,a5,1
    800066e8:	fec79ae3          	bne	a5,a2,800066dc <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    800066ec:	6462                	ld	s0,24(sp)
    800066ee:	6105                	addi	sp,sp,32
    800066f0:	8082                	ret
    x = -xx;
    800066f2:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    800066f6:	4305                	li	t1,1
    x = -xx;
    800066f8:	b741                	j	80006678 <sprintint+0x12>
  while(--i >= 0)
    800066fa:	4501                	li	a0,0
    800066fc:	bfc5                	j	800066ec <sprintint+0x86>

00000000800066fe <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    800066fe:	7171                	addi	sp,sp,-176
    80006700:	fc86                	sd	ra,120(sp)
    80006702:	f8a2                	sd	s0,112(sp)
    80006704:	f4a6                	sd	s1,104(sp)
    80006706:	f0ca                	sd	s2,96(sp)
    80006708:	ecce                	sd	s3,88(sp)
    8000670a:	e8d2                	sd	s4,80(sp)
    8000670c:	e4d6                	sd	s5,72(sp)
    8000670e:	e0da                	sd	s6,64(sp)
    80006710:	fc5e                	sd	s7,56(sp)
    80006712:	f862                	sd	s8,48(sp)
    80006714:	f466                	sd	s9,40(sp)
    80006716:	f06a                	sd	s10,32(sp)
    80006718:	ec6e                	sd	s11,24(sp)
    8000671a:	0100                	addi	s0,sp,128
    8000671c:	e414                	sd	a3,8(s0)
    8000671e:	e818                	sd	a4,16(s0)
    80006720:	ec1c                	sd	a5,24(s0)
    80006722:	03043023          	sd	a6,32(s0)
    80006726:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000672a:	ca0d                	beqz	a2,8000675c <snprintf+0x5e>
    8000672c:	8baa                	mv	s7,a0
    8000672e:	89ae                	mv	s3,a1
    80006730:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006732:	00840793          	addi	a5,s0,8
    80006736:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    8000673a:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000673c:	4901                	li	s2,0
    8000673e:	02b05763          	blez	a1,8000676c <snprintf+0x6e>
    if(c != '%'){
    80006742:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006746:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000674a:	02800d93          	li	s11,40
  *s = c;
    8000674e:	02500d13          	li	s10,37
    switch(c){
    80006752:	07800c93          	li	s9,120
    80006756:	06400c13          	li	s8,100
    8000675a:	a01d                	j	80006780 <snprintf+0x82>
    panic("null fmt");
    8000675c:	00002517          	auipc	a0,0x2
    80006760:	8cc50513          	addi	a0,a0,-1844 # 80008028 <etext+0x28>
    80006764:	ffffa097          	auipc	ra,0xffffa
    80006768:	de4080e7          	jalr	-540(ra) # 80000548 <panic>
  int off = 0;
    8000676c:	4481                	li	s1,0
    8000676e:	a86d                	j	80006828 <snprintf+0x12a>
  *s = c;
    80006770:	009b8733          	add	a4,s7,s1
    80006774:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006778:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000677a:	2905                	addiw	s2,s2,1
    8000677c:	0b34d663          	bge	s1,s3,80006828 <snprintf+0x12a>
    80006780:	012a07b3          	add	a5,s4,s2
    80006784:	0007c783          	lbu	a5,0(a5)
    80006788:	0007871b          	sext.w	a4,a5
    8000678c:	cfd1                	beqz	a5,80006828 <snprintf+0x12a>
    if(c != '%'){
    8000678e:	ff5711e3          	bne	a4,s5,80006770 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    80006792:	2905                	addiw	s2,s2,1
    80006794:	012a07b3          	add	a5,s4,s2
    80006798:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    8000679c:	c7d1                	beqz	a5,80006828 <snprintf+0x12a>
    switch(c){
    8000679e:	05678c63          	beq	a5,s6,800067f6 <snprintf+0xf8>
    800067a2:	02fb6763          	bltu	s6,a5,800067d0 <snprintf+0xd2>
    800067a6:	0b578763          	beq	a5,s5,80006854 <snprintf+0x156>
    800067aa:	0b879b63          	bne	a5,s8,80006860 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800067ae:	f8843783          	ld	a5,-120(s0)
    800067b2:	00878713          	addi	a4,a5,8
    800067b6:	f8e43423          	sd	a4,-120(s0)
    800067ba:	4685                	li	a3,1
    800067bc:	4629                	li	a2,10
    800067be:	438c                	lw	a1,0(a5)
    800067c0:	009b8533          	add	a0,s7,s1
    800067c4:	00000097          	auipc	ra,0x0
    800067c8:	ea2080e7          	jalr	-350(ra) # 80006666 <sprintint>
    800067cc:	9ca9                	addw	s1,s1,a0
      break;
    800067ce:	b775                	j	8000677a <snprintf+0x7c>
    switch(c){
    800067d0:	09979863          	bne	a5,s9,80006860 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    800067d4:	f8843783          	ld	a5,-120(s0)
    800067d8:	00878713          	addi	a4,a5,8
    800067dc:	f8e43423          	sd	a4,-120(s0)
    800067e0:	4685                	li	a3,1
    800067e2:	4641                	li	a2,16
    800067e4:	438c                	lw	a1,0(a5)
    800067e6:	009b8533          	add	a0,s7,s1
    800067ea:	00000097          	auipc	ra,0x0
    800067ee:	e7c080e7          	jalr	-388(ra) # 80006666 <sprintint>
    800067f2:	9ca9                	addw	s1,s1,a0
      break;
    800067f4:	b759                	j	8000677a <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    800067f6:	f8843783          	ld	a5,-120(s0)
    800067fa:	00878713          	addi	a4,a5,8
    800067fe:	f8e43423          	sd	a4,-120(s0)
    80006802:	639c                	ld	a5,0(a5)
    80006804:	c3b1                	beqz	a5,80006848 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006806:	0007c703          	lbu	a4,0(a5)
    8000680a:	db25                	beqz	a4,8000677a <snprintf+0x7c>
    8000680c:	0134de63          	bge	s1,s3,80006828 <snprintf+0x12a>
    80006810:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006814:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006818:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    8000681a:	0785                	addi	a5,a5,1
    8000681c:	0007c703          	lbu	a4,0(a5)
    80006820:	df29                	beqz	a4,8000677a <snprintf+0x7c>
    80006822:	0685                	addi	a3,a3,1
    80006824:	fe9998e3          	bne	s3,s1,80006814 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006828:	8526                	mv	a0,s1
    8000682a:	70e6                	ld	ra,120(sp)
    8000682c:	7446                	ld	s0,112(sp)
    8000682e:	74a6                	ld	s1,104(sp)
    80006830:	7906                	ld	s2,96(sp)
    80006832:	69e6                	ld	s3,88(sp)
    80006834:	6a46                	ld	s4,80(sp)
    80006836:	6aa6                	ld	s5,72(sp)
    80006838:	6b06                	ld	s6,64(sp)
    8000683a:	7be2                	ld	s7,56(sp)
    8000683c:	7c42                	ld	s8,48(sp)
    8000683e:	7ca2                	ld	s9,40(sp)
    80006840:	7d02                	ld	s10,32(sp)
    80006842:	6de2                	ld	s11,24(sp)
    80006844:	614d                	addi	sp,sp,176
    80006846:	8082                	ret
        s = "(null)";
    80006848:	00001797          	auipc	a5,0x1
    8000684c:	7d878793          	addi	a5,a5,2008 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006850:	876e                	mv	a4,s11
    80006852:	bf6d                	j	8000680c <snprintf+0x10e>
  *s = c;
    80006854:	009b87b3          	add	a5,s7,s1
    80006858:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    8000685c:	2485                	addiw	s1,s1,1
      break;
    8000685e:	bf31                	j	8000677a <snprintf+0x7c>
  *s = c;
    80006860:	009b8733          	add	a4,s7,s1
    80006864:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006868:	0014871b          	addiw	a4,s1,1
  *s = c;
    8000686c:	975e                	add	a4,a4,s7
    8000686e:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006872:	2489                	addiw	s1,s1,2
      break;
    80006874:	b719                	j	8000677a <snprintf+0x7c>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
