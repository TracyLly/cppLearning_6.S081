
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
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
    80000060:	d8478793          	addi	a5,a5,-636 # 80005de0 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdb87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	f1678793          	addi	a5,a5,-234 # 80000fbc <main>
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
    80000110:	c02080e7          	jalr	-1022(ra) # 80000d0e <acquire>
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
    8000012a:	5a0080e7          	jalr	1440(ra) # 800026c6 <either_copyin>
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
    80000152:	c74080e7          	jalr	-908(ra) # 80000dc2 <release>

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
    800001a2:	b70080e7          	jalr	-1168(ra) # 80000d0e <acquire>
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
    800001d2:	a30080e7          	jalr	-1488(ra) # 80001bfe <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	230080e7          	jalr	560(ra) # 8000240e <sleep>
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
    8000021e:	456080e7          	jalr	1110(ra) # 80002670 <either_copyout>
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
    8000023a:	b8c080e7          	jalr	-1140(ra) # 80000dc2 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	b76080e7          	jalr	-1162(ra) # 80000dc2 <release>
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
    800002e2:	a30080e7          	jalr	-1488(ra) # 80000d0e <acquire>

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
    80000300:	420080e7          	jalr	1056(ra) # 8000271c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	ab6080e7          	jalr	-1354(ra) # 80000dc2 <release>
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
    80000454:	144080e7          	jalr	324(ra) # 80002594 <wakeup>
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
    80000472:	00001097          	auipc	ra,0x1
    80000476:	80c080e7          	jalr	-2036(ra) # 80000c7e <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00241797          	auipc	a5,0x241
    80000486:	52e78793          	addi	a5,a5,1326 # 802419b0 <devsw>
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
    8000057a:	b8a50513          	addi	a0,a0,-1142 # 80008100 <digits+0xc0>
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
    8000060e:	704080e7          	jalr	1796(ra) # 80000d0e <acquire>
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
    80000772:	654080e7          	jalr	1620(ra) # 80000dc2 <release>
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
    80000798:	4ea080e7          	jalr	1258(ra) # 80000c7e <initlock>
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
    800007ee:	494080e7          	jalr	1172(ra) # 80000c7e <initlock>
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
    8000080a:	4bc080e7          	jalr	1212(ra) # 80000cc2 <push_off>

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
    8000083c:	52a080e7          	jalr	1322(ra) # 80000d62 <pop_off>
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
    800008ba:	cde080e7          	jalr	-802(ra) # 80002594 <wakeup>
    
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
    800008fe:	414080e7          	jalr	1044(ra) # 80000d0e <acquire>
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
    80000954:	abe080e7          	jalr	-1346(ra) # 8000240e <sleep>
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
    80000998:	42e080e7          	jalr	1070(ra) # 80000dc2 <release>
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
    80000a04:	30e080e7          	jalr	782(ra) # 80000d0e <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	3b0080e7          	jalr	944(ra) # 80000dc2 <release>
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
    80000a24:	7179                	addi	sp,sp,-48
    80000a26:	f406                	sd	ra,40(sp)
    80000a28:	f022                	sd	s0,32(sp)
    80000a2a:	ec26                	sd	s1,24(sp)
    80000a2c:	e84a                	sd	s2,16(sp)
    80000a2e:	e44e                	sd	s3,8(sp)
    80000a30:	1800                	addi	s0,sp,48
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a32:	03451793          	slli	a5,a0,0x34
    80000a36:	e3ad                	bnez	a5,80000a98 <kfree+0x74>
    80000a38:	84aa                	mv	s1,a0
    80000a3a:	00245797          	auipc	a5,0x245
    80000a3e:	5c678793          	addi	a5,a5,1478 # 80246000 <end>
    80000a42:	04f56b63          	bltu	a0,a5,80000a98 <kfree+0x74>
    80000a46:	47c5                	li	a5,17
    80000a48:	07ee                	slli	a5,a5,0x1b
    80000a4a:	04f57763          	bgeu	a0,a5,80000a98 <kfree+0x74>
    panic("kfree");

  acquire(&kmem.lock);
    80000a4e:	00011917          	auipc	s2,0x11
    80000a52:	ee290913          	addi	s2,s2,-286 # 80011930 <kmem>
    80000a56:	854a                	mv	a0,s2
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	2b6080e7          	jalr	694(ra) # 80000d0e <acquire>
  int remain = --cowcount[PA2INDEX(pa)];
    80000a60:	00c4d793          	srli	a5,s1,0xc
    80000a64:	00279713          	slli	a4,a5,0x2
    80000a68:	00011797          	auipc	a5,0x11
    80000a6c:	ee878793          	addi	a5,a5,-280 # 80011950 <cowcount>
    80000a70:	97ba                	add	a5,a5,a4
    80000a72:	4398                	lw	a4,0(a5)
    80000a74:	377d                	addiw	a4,a4,-1
    80000a76:	0007099b          	sext.w	s3,a4
    80000a7a:	c398                	sw	a4,0(a5)
  release(&kmem.lock);
    80000a7c:	854a                	mv	a0,s2
    80000a7e:	00000097          	auipc	ra,0x0
    80000a82:	344080e7          	jalr	836(ra) # 80000dc2 <release>

  if (remain > 0) {
    80000a86:	03305163          	blez	s3,80000aa8 <kfree+0x84>

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
    80000a8a:	70a2                	ld	ra,40(sp)
    80000a8c:	7402                	ld	s0,32(sp)
    80000a8e:	64e2                	ld	s1,24(sp)
    80000a90:	6942                	ld	s2,16(sp)
    80000a92:	69a2                	ld	s3,8(sp)
    80000a94:	6145                	addi	sp,sp,48
    80000a96:	8082                	ret
    panic("kfree");
    80000a98:	00007517          	auipc	a0,0x7
    80000a9c:	5c850513          	addi	a0,a0,1480 # 80008060 <digits+0x20>
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	aa8080e7          	jalr	-1368(ra) # 80000548 <panic>
  memset(pa, 1, PGSIZE);
    80000aa8:	6605                	lui	a2,0x1
    80000aaa:	4585                	li	a1,1
    80000aac:	8526                	mv	a0,s1
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	35c080e7          	jalr	860(ra) # 80000e0a <memset>
  acquire(&kmem.lock);
    80000ab6:	854a                	mv	a0,s2
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	256080e7          	jalr	598(ra) # 80000d0e <acquire>
  r->next = kmem.freelist;
    80000ac0:	01893783          	ld	a5,24(s2)
    80000ac4:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000ac6:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000aca:	854a                	mv	a0,s2
    80000acc:	00000097          	auipc	ra,0x0
    80000ad0:	2f6080e7          	jalr	758(ra) # 80000dc2 <release>
    80000ad4:	bf5d                	j	80000a8a <kfree+0x66>

0000000080000ad6 <freerange>:
{
    80000ad6:	7139                	addi	sp,sp,-64
    80000ad8:	fc06                	sd	ra,56(sp)
    80000ada:	f822                	sd	s0,48(sp)
    80000adc:	f426                	sd	s1,40(sp)
    80000ade:	f04a                	sd	s2,32(sp)
    80000ae0:	ec4e                	sd	s3,24(sp)
    80000ae2:	e852                	sd	s4,16(sp)
    80000ae4:	e456                	sd	s5,8(sp)
    80000ae6:	e05a                	sd	s6,0(sp)
    80000ae8:	0080                	addi	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aea:	6785                	lui	a5,0x1
    80000aec:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000af0:	9526                	add	a0,a0,s1
    80000af2:	74fd                	lui	s1,0xfffff
    80000af4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
    80000af6:	97a6                	add	a5,a5,s1
    80000af8:	02f5ea63          	bltu	a1,a5,80000b2c <freerange+0x56>
    80000afc:	892e                	mv	s2,a1
    cowcount[PA2INDEX(p)] = 1; // add into free list initially
    80000afe:	00011b17          	auipc	s6,0x11
    80000b02:	e52b0b13          	addi	s6,s6,-430 # 80011950 <cowcount>
    80000b06:	4a85                	li	s5,1
    80000b08:	6a05                	lui	s4,0x1
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
    80000b0a:	6989                	lui	s3,0x2
    cowcount[PA2INDEX(p)] = 1; // add into free list initially
    80000b0c:	00c4d793          	srli	a5,s1,0xc
    80000b10:	078a                	slli	a5,a5,0x2
    80000b12:	97da                	add	a5,a5,s6
    80000b14:	0157a023          	sw	s5,0(a5)
    kfree(p);
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	f0a080e7          	jalr	-246(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
    80000b22:	87a6                	mv	a5,s1
    80000b24:	94d2                	add	s1,s1,s4
    80000b26:	97ce                	add	a5,a5,s3
    80000b28:	fef972e3          	bgeu	s2,a5,80000b0c <freerange+0x36>
}
    80000b2c:	70e2                	ld	ra,56(sp)
    80000b2e:	7442                	ld	s0,48(sp)
    80000b30:	74a2                	ld	s1,40(sp)
    80000b32:	7902                	ld	s2,32(sp)
    80000b34:	69e2                	ld	s3,24(sp)
    80000b36:	6a42                	ld	s4,16(sp)
    80000b38:	6aa2                	ld	s5,8(sp)
    80000b3a:	6b02                	ld	s6,0(sp)
    80000b3c:	6121                	addi	sp,sp,64
    80000b3e:	8082                	ret

0000000080000b40 <kinit>:
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e406                	sd	ra,8(sp)
    80000b44:	e022                	sd	s0,0(sp)
    80000b46:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b48:	00007597          	auipc	a1,0x7
    80000b4c:	52058593          	addi	a1,a1,1312 # 80008068 <digits+0x28>
    80000b50:	00011517          	auipc	a0,0x11
    80000b54:	de050513          	addi	a0,a0,-544 # 80011930 <kmem>
    80000b58:	00000097          	auipc	ra,0x0
    80000b5c:	126080e7          	jalr	294(ra) # 80000c7e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b60:	45c5                	li	a1,17
    80000b62:	05ee                	slli	a1,a1,0x1b
    80000b64:	00245517          	auipc	a0,0x245
    80000b68:	49c50513          	addi	a0,a0,1180 # 80246000 <end>
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	f6a080e7          	jalr	-150(ra) # 80000ad6 <freerange>
}
    80000b74:	60a2                	ld	ra,8(sp)
    80000b76:	6402                	ld	s0,0(sp)
    80000b78:	0141                	addi	sp,sp,16
    80000b7a:	8082                	ret

0000000080000b7c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b7c:	1101                	addi	sp,sp,-32
    80000b7e:	ec06                	sd	ra,24(sp)
    80000b80:	e822                	sd	s0,16(sp)
    80000b82:	e426                	sd	s1,8(sp)
    80000b84:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b86:	00011497          	auipc	s1,0x11
    80000b8a:	daa48493          	addi	s1,s1,-598 # 80011930 <kmem>
    80000b8e:	8526                	mv	a0,s1
    80000b90:	00000097          	auipc	ra,0x0
    80000b94:	17e080e7          	jalr	382(ra) # 80000d0e <acquire>
  r = kmem.freelist;
    80000b98:	6c84                	ld	s1,24(s1)
  if(r)
    80000b9a:	c4a5                	beqz	s1,80000c02 <kalloc+0x86>
    kmem.freelist = r->next;
    80000b9c:	609c                	ld	a5,0(s1)
    80000b9e:	00011517          	auipc	a0,0x11
    80000ba2:	d9250513          	addi	a0,a0,-622 # 80011930 <kmem>
    80000ba6:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000ba8:	00000097          	auipc	ra,0x0
    80000bac:	21a080e7          	jalr	538(ra) # 80000dc2 <release>

  if(r) {
    memset((char *)r, 5, PGSIZE); // fill with junk
    80000bb0:	6605                	lui	a2,0x1
    80000bb2:	4595                	li	a1,5
    80000bb4:	8526                	mv	a0,s1
    80000bb6:	00000097          	auipc	ra,0x0
    80000bba:	254080e7          	jalr	596(ra) # 80000e0a <memset>
    int idx = PA2INDEX(r);
    80000bbe:	00c4d793          	srli	a5,s1,0xc
    80000bc2:	2781                	sext.w	a5,a5
    if (cowcount[idx] != 0) {
    80000bc4:	00279693          	slli	a3,a5,0x2
    80000bc8:	00011717          	auipc	a4,0x11
    80000bcc:	d8870713          	addi	a4,a4,-632 # 80011950 <cowcount>
    80000bd0:	9736                	add	a4,a4,a3
    80000bd2:	4318                	lw	a4,0(a4)
    80000bd4:	ef19                	bnez	a4,80000bf2 <kalloc+0x76>
      panic("kalloc: cowcount[idx] != 0");
    }
    cowcount[idx] = 1;
    80000bd6:	078a                	slli	a5,a5,0x2
    80000bd8:	00011717          	auipc	a4,0x11
    80000bdc:	d7870713          	addi	a4,a4,-648 # 80011950 <cowcount>
    80000be0:	97ba                	add	a5,a5,a4
    80000be2:	4705                	li	a4,1
    80000be4:	c398                	sw	a4,0(a5)
  }
  return (void*)r;
}
    80000be6:	8526                	mv	a0,s1
    80000be8:	60e2                	ld	ra,24(sp)
    80000bea:	6442                	ld	s0,16(sp)
    80000bec:	64a2                	ld	s1,8(sp)
    80000bee:	6105                	addi	sp,sp,32
    80000bf0:	8082                	ret
      panic("kalloc: cowcount[idx] != 0");
    80000bf2:	00007517          	auipc	a0,0x7
    80000bf6:	47e50513          	addi	a0,a0,1150 # 80008070 <digits+0x30>
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	94e080e7          	jalr	-1714(ra) # 80000548 <panic>
  release(&kmem.lock);
    80000c02:	00011517          	auipc	a0,0x11
    80000c06:	d2e50513          	addi	a0,a0,-722 # 80011930 <kmem>
    80000c0a:	00000097          	auipc	ra,0x0
    80000c0e:	1b8080e7          	jalr	440(ra) # 80000dc2 <release>
  if(r) {
    80000c12:	bfd1                	j	80000be6 <kalloc+0x6a>

0000000080000c14 <adjustref>:

// increment the reference count for a physical address by 1
void adjustref(uint64 pa, int num) {
    80000c14:	7179                	addi	sp,sp,-48
    80000c16:	f406                	sd	ra,40(sp)
    80000c18:	f022                	sd	s0,32(sp)
    80000c1a:	ec26                	sd	s1,24(sp)
    80000c1c:	e84a                	sd	s2,16(sp)
    80000c1e:	e44e                	sd	s3,8(sp)
    80000c20:	1800                	addi	s0,sp,48
    if (pa >= PHYSTOP) {
    80000c22:	47c5                	li	a5,17
    80000c24:	07ee                	slli	a5,a5,0x1b
    80000c26:	04f57463          	bgeu	a0,a5,80000c6e <adjustref+0x5a>
    80000c2a:	84aa                	mv	s1,a0
    80000c2c:	892e                	mv	s2,a1
        panic("addref: pa too big");
    }
    acquire(&kmem.lock);
    80000c2e:	00011997          	auipc	s3,0x11
    80000c32:	d0298993          	addi	s3,s3,-766 # 80011930 <kmem>
    80000c36:	854e                	mv	a0,s3
    80000c38:	00000097          	auipc	ra,0x0
    80000c3c:	0d6080e7          	jalr	214(ra) # 80000d0e <acquire>
    cowcount[PA2INDEX(pa)] += num;
    80000c40:	80b1                	srli	s1,s1,0xc
    80000c42:	048a                	slli	s1,s1,0x2
    80000c44:	00011797          	auipc	a5,0x11
    80000c48:	d0c78793          	addi	a5,a5,-756 # 80011950 <cowcount>
    80000c4c:	94be                	add	s1,s1,a5
    80000c4e:	408c                	lw	a1,0(s1)
    80000c50:	012585bb          	addw	a1,a1,s2
    80000c54:	c08c                	sw	a1,0(s1)
    release(&kmem.lock);
    80000c56:	854e                	mv	a0,s3
    80000c58:	00000097          	auipc	ra,0x0
    80000c5c:	16a080e7          	jalr	362(ra) # 80000dc2 <release>
}
    80000c60:	70a2                	ld	ra,40(sp)
    80000c62:	7402                	ld	s0,32(sp)
    80000c64:	64e2                	ld	s1,24(sp)
    80000c66:	6942                	ld	s2,16(sp)
    80000c68:	69a2                	ld	s3,8(sp)
    80000c6a:	6145                	addi	sp,sp,48
    80000c6c:	8082                	ret
        panic("addref: pa too big");
    80000c6e:	00007517          	auipc	a0,0x7
    80000c72:	42250513          	addi	a0,a0,1058 # 80008090 <digits+0x50>
    80000c76:	00000097          	auipc	ra,0x0
    80000c7a:	8d2080e7          	jalr	-1838(ra) # 80000548 <panic>

0000000080000c7e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c7e:	1141                	addi	sp,sp,-16
    80000c80:	e422                	sd	s0,8(sp)
    80000c82:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c84:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c86:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c8a:	00053823          	sd	zero,16(a0)
}
    80000c8e:	6422                	ld	s0,8(sp)
    80000c90:	0141                	addi	sp,sp,16
    80000c92:	8082                	ret

0000000080000c94 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c94:	411c                	lw	a5,0(a0)
    80000c96:	e399                	bnez	a5,80000c9c <holding+0x8>
    80000c98:	4501                	li	a0,0
  return r;
}
    80000c9a:	8082                	ret
{
    80000c9c:	1101                	addi	sp,sp,-32
    80000c9e:	ec06                	sd	ra,24(sp)
    80000ca0:	e822                	sd	s0,16(sp)
    80000ca2:	e426                	sd	s1,8(sp)
    80000ca4:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ca6:	6904                	ld	s1,16(a0)
    80000ca8:	00001097          	auipc	ra,0x1
    80000cac:	f3a080e7          	jalr	-198(ra) # 80001be2 <mycpu>
    80000cb0:	40a48533          	sub	a0,s1,a0
    80000cb4:	00153513          	seqz	a0,a0
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret

0000000080000cc2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cc2:	1101                	addi	sp,sp,-32
    80000cc4:	ec06                	sd	ra,24(sp)
    80000cc6:	e822                	sd	s0,16(sp)
    80000cc8:	e426                	sd	s1,8(sp)
    80000cca:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ccc:	100024f3          	csrr	s1,sstatus
    80000cd0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cd4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cda:	00001097          	auipc	ra,0x1
    80000cde:	f08080e7          	jalr	-248(ra) # 80001be2 <mycpu>
    80000ce2:	5d3c                	lw	a5,120(a0)
    80000ce4:	cf89                	beqz	a5,80000cfe <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ce6:	00001097          	auipc	ra,0x1
    80000cea:	efc080e7          	jalr	-260(ra) # 80001be2 <mycpu>
    80000cee:	5d3c                	lw	a5,120(a0)
    80000cf0:	2785                	addiw	a5,a5,1
    80000cf2:	dd3c                	sw	a5,120(a0)
}
    80000cf4:	60e2                	ld	ra,24(sp)
    80000cf6:	6442                	ld	s0,16(sp)
    80000cf8:	64a2                	ld	s1,8(sp)
    80000cfa:	6105                	addi	sp,sp,32
    80000cfc:	8082                	ret
    mycpu()->intena = old;
    80000cfe:	00001097          	auipc	ra,0x1
    80000d02:	ee4080e7          	jalr	-284(ra) # 80001be2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d06:	8085                	srli	s1,s1,0x1
    80000d08:	8885                	andi	s1,s1,1
    80000d0a:	dd64                	sw	s1,124(a0)
    80000d0c:	bfe9                	j	80000ce6 <push_off+0x24>

0000000080000d0e <acquire>:
{
    80000d0e:	1101                	addi	sp,sp,-32
    80000d10:	ec06                	sd	ra,24(sp)
    80000d12:	e822                	sd	s0,16(sp)
    80000d14:	e426                	sd	s1,8(sp)
    80000d16:	1000                	addi	s0,sp,32
    80000d18:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d1a:	00000097          	auipc	ra,0x0
    80000d1e:	fa8080e7          	jalr	-88(ra) # 80000cc2 <push_off>
  if(holding(lk))
    80000d22:	8526                	mv	a0,s1
    80000d24:	00000097          	auipc	ra,0x0
    80000d28:	f70080e7          	jalr	-144(ra) # 80000c94 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d2c:	4705                	li	a4,1
  if(holding(lk))
    80000d2e:	e115                	bnez	a0,80000d52 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d30:	87ba                	mv	a5,a4
    80000d32:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d36:	2781                	sext.w	a5,a5
    80000d38:	ffe5                	bnez	a5,80000d30 <acquire+0x22>
  __sync_synchronize();
    80000d3a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d3e:	00001097          	auipc	ra,0x1
    80000d42:	ea4080e7          	jalr	-348(ra) # 80001be2 <mycpu>
    80000d46:	e888                	sd	a0,16(s1)
}
    80000d48:	60e2                	ld	ra,24(sp)
    80000d4a:	6442                	ld	s0,16(sp)
    80000d4c:	64a2                	ld	s1,8(sp)
    80000d4e:	6105                	addi	sp,sp,32
    80000d50:	8082                	ret
    panic("acquire");
    80000d52:	00007517          	auipc	a0,0x7
    80000d56:	35650513          	addi	a0,a0,854 # 800080a8 <digits+0x68>
    80000d5a:	fffff097          	auipc	ra,0xfffff
    80000d5e:	7ee080e7          	jalr	2030(ra) # 80000548 <panic>

0000000080000d62 <pop_off>:

void
pop_off(void)
{
    80000d62:	1141                	addi	sp,sp,-16
    80000d64:	e406                	sd	ra,8(sp)
    80000d66:	e022                	sd	s0,0(sp)
    80000d68:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d6a:	00001097          	auipc	ra,0x1
    80000d6e:	e78080e7          	jalr	-392(ra) # 80001be2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d72:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d76:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d78:	e78d                	bnez	a5,80000da2 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d7a:	5d3c                	lw	a5,120(a0)
    80000d7c:	02f05b63          	blez	a5,80000db2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d80:	37fd                	addiw	a5,a5,-1
    80000d82:	0007871b          	sext.w	a4,a5
    80000d86:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d88:	eb09                	bnez	a4,80000d9a <pop_off+0x38>
    80000d8a:	5d7c                	lw	a5,124(a0)
    80000d8c:	c799                	beqz	a5,80000d9a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d8e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d92:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d96:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret
    panic("pop_off - interruptible");
    80000da2:	00007517          	auipc	a0,0x7
    80000da6:	30e50513          	addi	a0,a0,782 # 800080b0 <digits+0x70>
    80000daa:	fffff097          	auipc	ra,0xfffff
    80000dae:	79e080e7          	jalr	1950(ra) # 80000548 <panic>
    panic("pop_off");
    80000db2:	00007517          	auipc	a0,0x7
    80000db6:	31650513          	addi	a0,a0,790 # 800080c8 <digits+0x88>
    80000dba:	fffff097          	auipc	ra,0xfffff
    80000dbe:	78e080e7          	jalr	1934(ra) # 80000548 <panic>

0000000080000dc2 <release>:
{
    80000dc2:	1101                	addi	sp,sp,-32
    80000dc4:	ec06                	sd	ra,24(sp)
    80000dc6:	e822                	sd	s0,16(sp)
    80000dc8:	e426                	sd	s1,8(sp)
    80000dca:	1000                	addi	s0,sp,32
    80000dcc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dce:	00000097          	auipc	ra,0x0
    80000dd2:	ec6080e7          	jalr	-314(ra) # 80000c94 <holding>
    80000dd6:	c115                	beqz	a0,80000dfa <release+0x38>
  lk->cpu = 0;
    80000dd8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ddc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000de0:	0f50000f          	fence	iorw,ow
    80000de4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000de8:	00000097          	auipc	ra,0x0
    80000dec:	f7a080e7          	jalr	-134(ra) # 80000d62 <pop_off>
}
    80000df0:	60e2                	ld	ra,24(sp)
    80000df2:	6442                	ld	s0,16(sp)
    80000df4:	64a2                	ld	s1,8(sp)
    80000df6:	6105                	addi	sp,sp,32
    80000df8:	8082                	ret
    panic("release");
    80000dfa:	00007517          	auipc	a0,0x7
    80000dfe:	2d650513          	addi	a0,a0,726 # 800080d0 <digits+0x90>
    80000e02:	fffff097          	auipc	ra,0xfffff
    80000e06:	746080e7          	jalr	1862(ra) # 80000548 <panic>

0000000080000e0a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e0a:	1141                	addi	sp,sp,-16
    80000e0c:	e422                	sd	s0,8(sp)
    80000e0e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e10:	ce09                	beqz	a2,80000e2a <memset+0x20>
    80000e12:	87aa                	mv	a5,a0
    80000e14:	fff6071b          	addiw	a4,a2,-1
    80000e18:	1702                	slli	a4,a4,0x20
    80000e1a:	9301                	srli	a4,a4,0x20
    80000e1c:	0705                	addi	a4,a4,1
    80000e1e:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000e20:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e24:	0785                	addi	a5,a5,1
    80000e26:	fee79de3          	bne	a5,a4,80000e20 <memset+0x16>
  }
  return dst;
}
    80000e2a:	6422                	ld	s0,8(sp)
    80000e2c:	0141                	addi	sp,sp,16
    80000e2e:	8082                	ret

0000000080000e30 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e30:	1141                	addi	sp,sp,-16
    80000e32:	e422                	sd	s0,8(sp)
    80000e34:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e36:	ca05                	beqz	a2,80000e66 <memcmp+0x36>
    80000e38:	fff6069b          	addiw	a3,a2,-1
    80000e3c:	1682                	slli	a3,a3,0x20
    80000e3e:	9281                	srli	a3,a3,0x20
    80000e40:	0685                	addi	a3,a3,1
    80000e42:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e44:	00054783          	lbu	a5,0(a0)
    80000e48:	0005c703          	lbu	a4,0(a1)
    80000e4c:	00e79863          	bne	a5,a4,80000e5c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e50:	0505                	addi	a0,a0,1
    80000e52:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e54:	fed518e3          	bne	a0,a3,80000e44 <memcmp+0x14>
  }

  return 0;
    80000e58:	4501                	li	a0,0
    80000e5a:	a019                	j	80000e60 <memcmp+0x30>
      return *s1 - *s2;
    80000e5c:	40e7853b          	subw	a0,a5,a4
}
    80000e60:	6422                	ld	s0,8(sp)
    80000e62:	0141                	addi	sp,sp,16
    80000e64:	8082                	ret
  return 0;
    80000e66:	4501                	li	a0,0
    80000e68:	bfe5                	j	80000e60 <memcmp+0x30>

0000000080000e6a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e70:	00a5f963          	bgeu	a1,a0,80000e82 <memmove+0x18>
    80000e74:	02061713          	slli	a4,a2,0x20
    80000e78:	9301                	srli	a4,a4,0x20
    80000e7a:	00e587b3          	add	a5,a1,a4
    80000e7e:	02f56563          	bltu	a0,a5,80000ea8 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e82:	fff6069b          	addiw	a3,a2,-1
    80000e86:	ce11                	beqz	a2,80000ea2 <memmove+0x38>
    80000e88:	1682                	slli	a3,a3,0x20
    80000e8a:	9281                	srli	a3,a3,0x20
    80000e8c:	0685                	addi	a3,a3,1
    80000e8e:	96ae                	add	a3,a3,a1
    80000e90:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000e92:	0585                	addi	a1,a1,1
    80000e94:	0785                	addi	a5,a5,1
    80000e96:	fff5c703          	lbu	a4,-1(a1)
    80000e9a:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000e9e:	fed59ae3          	bne	a1,a3,80000e92 <memmove+0x28>

  return dst;
}
    80000ea2:	6422                	ld	s0,8(sp)
    80000ea4:	0141                	addi	sp,sp,16
    80000ea6:	8082                	ret
    d += n;
    80000ea8:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000eaa:	fff6069b          	addiw	a3,a2,-1
    80000eae:	da75                	beqz	a2,80000ea2 <memmove+0x38>
    80000eb0:	02069613          	slli	a2,a3,0x20
    80000eb4:	9201                	srli	a2,a2,0x20
    80000eb6:	fff64613          	not	a2,a2
    80000eba:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000ebc:	17fd                	addi	a5,a5,-1
    80000ebe:	177d                	addi	a4,a4,-1
    80000ec0:	0007c683          	lbu	a3,0(a5)
    80000ec4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000ec8:	fec79ae3          	bne	a5,a2,80000ebc <memmove+0x52>
    80000ecc:	bfd9                	j	80000ea2 <memmove+0x38>

0000000080000ece <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000ece:	1141                	addi	sp,sp,-16
    80000ed0:	e406                	sd	ra,8(sp)
    80000ed2:	e022                	sd	s0,0(sp)
    80000ed4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ed6:	00000097          	auipc	ra,0x0
    80000eda:	f94080e7          	jalr	-108(ra) # 80000e6a <memmove>
}
    80000ede:	60a2                	ld	ra,8(sp)
    80000ee0:	6402                	ld	s0,0(sp)
    80000ee2:	0141                	addi	sp,sp,16
    80000ee4:	8082                	ret

0000000080000ee6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ee6:	1141                	addi	sp,sp,-16
    80000ee8:	e422                	sd	s0,8(sp)
    80000eea:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000eec:	ce11                	beqz	a2,80000f08 <strncmp+0x22>
    80000eee:	00054783          	lbu	a5,0(a0)
    80000ef2:	cf89                	beqz	a5,80000f0c <strncmp+0x26>
    80000ef4:	0005c703          	lbu	a4,0(a1)
    80000ef8:	00f71a63          	bne	a4,a5,80000f0c <strncmp+0x26>
    n--, p++, q++;
    80000efc:	367d                	addiw	a2,a2,-1
    80000efe:	0505                	addi	a0,a0,1
    80000f00:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f02:	f675                	bnez	a2,80000eee <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f04:	4501                	li	a0,0
    80000f06:	a809                	j	80000f18 <strncmp+0x32>
    80000f08:	4501                	li	a0,0
    80000f0a:	a039                	j	80000f18 <strncmp+0x32>
  if(n == 0)
    80000f0c:	ca09                	beqz	a2,80000f1e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f0e:	00054503          	lbu	a0,0(a0)
    80000f12:	0005c783          	lbu	a5,0(a1)
    80000f16:	9d1d                	subw	a0,a0,a5
}
    80000f18:	6422                	ld	s0,8(sp)
    80000f1a:	0141                	addi	sp,sp,16
    80000f1c:	8082                	ret
    return 0;
    80000f1e:	4501                	li	a0,0
    80000f20:	bfe5                	j	80000f18 <strncmp+0x32>

0000000080000f22 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f22:	1141                	addi	sp,sp,-16
    80000f24:	e422                	sd	s0,8(sp)
    80000f26:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f28:	872a                	mv	a4,a0
    80000f2a:	8832                	mv	a6,a2
    80000f2c:	367d                	addiw	a2,a2,-1
    80000f2e:	01005963          	blez	a6,80000f40 <strncpy+0x1e>
    80000f32:	0705                	addi	a4,a4,1
    80000f34:	0005c783          	lbu	a5,0(a1)
    80000f38:	fef70fa3          	sb	a5,-1(a4)
    80000f3c:	0585                	addi	a1,a1,1
    80000f3e:	f7f5                	bnez	a5,80000f2a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f40:	00c05d63          	blez	a2,80000f5a <strncpy+0x38>
    80000f44:	86ba                	mv	a3,a4
    *s++ = 0;
    80000f46:	0685                	addi	a3,a3,1
    80000f48:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f4c:	fff6c793          	not	a5,a3
    80000f50:	9fb9                	addw	a5,a5,a4
    80000f52:	010787bb          	addw	a5,a5,a6
    80000f56:	fef048e3          	bgtz	a5,80000f46 <strncpy+0x24>
  return os;
}
    80000f5a:	6422                	ld	s0,8(sp)
    80000f5c:	0141                	addi	sp,sp,16
    80000f5e:	8082                	ret

0000000080000f60 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f60:	1141                	addi	sp,sp,-16
    80000f62:	e422                	sd	s0,8(sp)
    80000f64:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f66:	02c05363          	blez	a2,80000f8c <safestrcpy+0x2c>
    80000f6a:	fff6069b          	addiw	a3,a2,-1
    80000f6e:	1682                	slli	a3,a3,0x20
    80000f70:	9281                	srli	a3,a3,0x20
    80000f72:	96ae                	add	a3,a3,a1
    80000f74:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f76:	00d58963          	beq	a1,a3,80000f88 <safestrcpy+0x28>
    80000f7a:	0585                	addi	a1,a1,1
    80000f7c:	0785                	addi	a5,a5,1
    80000f7e:	fff5c703          	lbu	a4,-1(a1)
    80000f82:	fee78fa3          	sb	a4,-1(a5)
    80000f86:	fb65                	bnez	a4,80000f76 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f88:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f8c:	6422                	ld	s0,8(sp)
    80000f8e:	0141                	addi	sp,sp,16
    80000f90:	8082                	ret

0000000080000f92 <strlen>:

int
strlen(const char *s)
{
    80000f92:	1141                	addi	sp,sp,-16
    80000f94:	e422                	sd	s0,8(sp)
    80000f96:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f98:	00054783          	lbu	a5,0(a0)
    80000f9c:	cf91                	beqz	a5,80000fb8 <strlen+0x26>
    80000f9e:	0505                	addi	a0,a0,1
    80000fa0:	87aa                	mv	a5,a0
    80000fa2:	4685                	li	a3,1
    80000fa4:	9e89                	subw	a3,a3,a0
    80000fa6:	00f6853b          	addw	a0,a3,a5
    80000faa:	0785                	addi	a5,a5,1
    80000fac:	fff7c703          	lbu	a4,-1(a5)
    80000fb0:	fb7d                	bnez	a4,80000fa6 <strlen+0x14>
    ;
  return n;
}
    80000fb2:	6422                	ld	s0,8(sp)
    80000fb4:	0141                	addi	sp,sp,16
    80000fb6:	8082                	ret
  for(n = 0; s[n]; n++)
    80000fb8:	4501                	li	a0,0
    80000fba:	bfe5                	j	80000fb2 <strlen+0x20>

0000000080000fbc <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000fbc:	1141                	addi	sp,sp,-16
    80000fbe:	e406                	sd	ra,8(sp)
    80000fc0:	e022                	sd	s0,0(sp)
    80000fc2:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	c0e080e7          	jalr	-1010(ra) # 80001bd2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000fcc:	00008717          	auipc	a4,0x8
    80000fd0:	04070713          	addi	a4,a4,64 # 8000900c <started>
  if(cpuid() == 0){
    80000fd4:	c139                	beqz	a0,8000101a <main+0x5e>
    while(started == 0)
    80000fd6:	431c                	lw	a5,0(a4)
    80000fd8:	2781                	sext.w	a5,a5
    80000fda:	dff5                	beqz	a5,80000fd6 <main+0x1a>
      ;
    __sync_synchronize();
    80000fdc:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fe0:	00001097          	auipc	ra,0x1
    80000fe4:	bf2080e7          	jalr	-1038(ra) # 80001bd2 <cpuid>
    80000fe8:	85aa                	mv	a1,a0
    80000fea:	00007517          	auipc	a0,0x7
    80000fee:	10650513          	addi	a0,a0,262 # 800080f0 <digits+0xb0>
    80000ff2:	fffff097          	auipc	ra,0xfffff
    80000ff6:	5a0080e7          	jalr	1440(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000ffa:	00000097          	auipc	ra,0x0
    80000ffe:	0d8080e7          	jalr	216(ra) # 800010d2 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001002:	00002097          	auipc	ra,0x2
    80001006:	85a080e7          	jalr	-1958(ra) # 8000285c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000100a:	00005097          	auipc	ra,0x5
    8000100e:	e16080e7          	jalr	-490(ra) # 80005e20 <plicinithart>
  }

  scheduler();        
    80001012:	00001097          	auipc	ra,0x1
    80001016:	11c080e7          	jalr	284(ra) # 8000212e <scheduler>
    consoleinit();
    8000101a:	fffff097          	auipc	ra,0xfffff
    8000101e:	440080e7          	jalr	1088(ra) # 8000045a <consoleinit>
    printfinit();
    80001022:	fffff097          	auipc	ra,0xfffff
    80001026:	756080e7          	jalr	1878(ra) # 80000778 <printfinit>
    printf("\n");
    8000102a:	00007517          	auipc	a0,0x7
    8000102e:	0d650513          	addi	a0,a0,214 # 80008100 <digits+0xc0>
    80001032:	fffff097          	auipc	ra,0xfffff
    80001036:	560080e7          	jalr	1376(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    8000103a:	00007517          	auipc	a0,0x7
    8000103e:	09e50513          	addi	a0,a0,158 # 800080d8 <digits+0x98>
    80001042:	fffff097          	auipc	ra,0xfffff
    80001046:	550080e7          	jalr	1360(ra) # 80000592 <printf>
    printf("\n");
    8000104a:	00007517          	auipc	a0,0x7
    8000104e:	0b650513          	addi	a0,a0,182 # 80008100 <digits+0xc0>
    80001052:	fffff097          	auipc	ra,0xfffff
    80001056:	540080e7          	jalr	1344(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    8000105a:	00000097          	auipc	ra,0x0
    8000105e:	ae6080e7          	jalr	-1306(ra) # 80000b40 <kinit>
    kvminit();       // create kernel page table
    80001062:	00000097          	auipc	ra,0x0
    80001066:	2a0080e7          	jalr	672(ra) # 80001302 <kvminit>
    kvminithart();   // turn on paging
    8000106a:	00000097          	auipc	ra,0x0
    8000106e:	068080e7          	jalr	104(ra) # 800010d2 <kvminithart>
    procinit();      // process table
    80001072:	00001097          	auipc	ra,0x1
    80001076:	a90080e7          	jalr	-1392(ra) # 80001b02 <procinit>
    trapinit();      // trap vectors
    8000107a:	00001097          	auipc	ra,0x1
    8000107e:	7ba080e7          	jalr	1978(ra) # 80002834 <trapinit>
    trapinithart();  // install kernel trap vector
    80001082:	00001097          	auipc	ra,0x1
    80001086:	7da080e7          	jalr	2010(ra) # 8000285c <trapinithart>
    plicinit();      // set up interrupt controller
    8000108a:	00005097          	auipc	ra,0x5
    8000108e:	d80080e7          	jalr	-640(ra) # 80005e0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001092:	00005097          	auipc	ra,0x5
    80001096:	d8e080e7          	jalr	-626(ra) # 80005e20 <plicinithart>
    binit();         // buffer cache
    8000109a:	00002097          	auipc	ra,0x2
    8000109e:	f28080e7          	jalr	-216(ra) # 80002fc2 <binit>
    iinit();         // inode cache
    800010a2:	00002097          	auipc	ra,0x2
    800010a6:	5b8080e7          	jalr	1464(ra) # 8000365a <iinit>
    fileinit();      // file table
    800010aa:	00003097          	auipc	ra,0x3
    800010ae:	556080e7          	jalr	1366(ra) # 80004600 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010b2:	00005097          	auipc	ra,0x5
    800010b6:	e76080e7          	jalr	-394(ra) # 80005f28 <virtio_disk_init>
    userinit();      // first user process
    800010ba:	00001097          	auipc	ra,0x1
    800010be:	e0e080e7          	jalr	-498(ra) # 80001ec8 <userinit>
    __sync_synchronize();
    800010c2:	0ff0000f          	fence
    started = 1;
    800010c6:	4785                	li	a5,1
    800010c8:	00008717          	auipc	a4,0x8
    800010cc:	f4f72223          	sw	a5,-188(a4) # 8000900c <started>
    800010d0:	b789                	j	80001012 <main+0x56>

00000000800010d2 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010d2:	1141                	addi	sp,sp,-16
    800010d4:	e422                	sd	s0,8(sp)
    800010d6:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010d8:	00008797          	auipc	a5,0x8
    800010dc:	f387b783          	ld	a5,-200(a5) # 80009010 <kernel_pagetable>
    800010e0:	83b1                	srli	a5,a5,0xc
    800010e2:	577d                	li	a4,-1
    800010e4:	177e                	slli	a4,a4,0x3f
    800010e6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010e8:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010ec:	12000073          	sfence.vma
  sfence_vma();
}
    800010f0:	6422                	ld	s0,8(sp)
    800010f2:	0141                	addi	sp,sp,16
    800010f4:	8082                	ret

00000000800010f6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010f6:	7139                	addi	sp,sp,-64
    800010f8:	fc06                	sd	ra,56(sp)
    800010fa:	f822                	sd	s0,48(sp)
    800010fc:	f426                	sd	s1,40(sp)
    800010fe:	f04a                	sd	s2,32(sp)
    80001100:	ec4e                	sd	s3,24(sp)
    80001102:	e852                	sd	s4,16(sp)
    80001104:	e456                	sd	s5,8(sp)
    80001106:	e05a                	sd	s6,0(sp)
    80001108:	0080                	addi	s0,sp,64
    8000110a:	84aa                	mv	s1,a0
    8000110c:	89ae                	mv	s3,a1
    8000110e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001110:	57fd                	li	a5,-1
    80001112:	83e9                	srli	a5,a5,0x1a
    80001114:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001116:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001118:	04b7f263          	bgeu	a5,a1,8000115c <walk+0x66>
    panic("walk");
    8000111c:	00007517          	auipc	a0,0x7
    80001120:	fec50513          	addi	a0,a0,-20 # 80008108 <digits+0xc8>
    80001124:	fffff097          	auipc	ra,0xfffff
    80001128:	424080e7          	jalr	1060(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000112c:	060a8663          	beqz	s5,80001198 <walk+0xa2>
    80001130:	00000097          	auipc	ra,0x0
    80001134:	a4c080e7          	jalr	-1460(ra) # 80000b7c <kalloc>
    80001138:	84aa                	mv	s1,a0
    8000113a:	c529                	beqz	a0,80001184 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000113c:	6605                	lui	a2,0x1
    8000113e:	4581                	li	a1,0
    80001140:	00000097          	auipc	ra,0x0
    80001144:	cca080e7          	jalr	-822(ra) # 80000e0a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001148:	00c4d793          	srli	a5,s1,0xc
    8000114c:	07aa                	slli	a5,a5,0xa
    8000114e:	0017e793          	ori	a5,a5,1
    80001152:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001156:	3a5d                	addiw	s4,s4,-9
    80001158:	036a0063          	beq	s4,s6,80001178 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000115c:	0149d933          	srl	s2,s3,s4
    80001160:	1ff97913          	andi	s2,s2,511
    80001164:	090e                	slli	s2,s2,0x3
    80001166:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001168:	00093483          	ld	s1,0(s2)
    8000116c:	0014f793          	andi	a5,s1,1
    80001170:	dfd5                	beqz	a5,8000112c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001172:	80a9                	srli	s1,s1,0xa
    80001174:	04b2                	slli	s1,s1,0xc
    80001176:	b7c5                	j	80001156 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001178:	00c9d513          	srli	a0,s3,0xc
    8000117c:	1ff57513          	andi	a0,a0,511
    80001180:	050e                	slli	a0,a0,0x3
    80001182:	9526                	add	a0,a0,s1
}
    80001184:	70e2                	ld	ra,56(sp)
    80001186:	7442                	ld	s0,48(sp)
    80001188:	74a2                	ld	s1,40(sp)
    8000118a:	7902                	ld	s2,32(sp)
    8000118c:	69e2                	ld	s3,24(sp)
    8000118e:	6a42                	ld	s4,16(sp)
    80001190:	6aa2                	ld	s5,8(sp)
    80001192:	6b02                	ld	s6,0(sp)
    80001194:	6121                	addi	sp,sp,64
    80001196:	8082                	ret
        return 0;
    80001198:	4501                	li	a0,0
    8000119a:	b7ed                	j	80001184 <walk+0x8e>

000000008000119c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000119c:	57fd                	li	a5,-1
    8000119e:	83e9                	srli	a5,a5,0x1a
    800011a0:	00b7f463          	bgeu	a5,a1,800011a8 <walkaddr+0xc>
    return 0;
    800011a4:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011a6:	8082                	ret
{
    800011a8:	1141                	addi	sp,sp,-16
    800011aa:	e406                	sd	ra,8(sp)
    800011ac:	e022                	sd	s0,0(sp)
    800011ae:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011b0:	4601                	li	a2,0
    800011b2:	00000097          	auipc	ra,0x0
    800011b6:	f44080e7          	jalr	-188(ra) # 800010f6 <walk>
  if(pte == 0)
    800011ba:	c105                	beqz	a0,800011da <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011bc:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011be:	0117f693          	andi	a3,a5,17
    800011c2:	4745                	li	a4,17
    return 0;
    800011c4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011c6:	00e68663          	beq	a3,a4,800011d2 <walkaddr+0x36>
}
    800011ca:	60a2                	ld	ra,8(sp)
    800011cc:	6402                	ld	s0,0(sp)
    800011ce:	0141                	addi	sp,sp,16
    800011d0:	8082                	ret
  pa = PTE2PA(*pte);
    800011d2:	00a7d513          	srli	a0,a5,0xa
    800011d6:	0532                	slli	a0,a0,0xc
  return pa;
    800011d8:	bfcd                	j	800011ca <walkaddr+0x2e>
    return 0;
    800011da:	4501                	li	a0,0
    800011dc:	b7fd                	j	800011ca <walkaddr+0x2e>

00000000800011de <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800011de:	1101                	addi	sp,sp,-32
    800011e0:	ec06                	sd	ra,24(sp)
    800011e2:	e822                	sd	s0,16(sp)
    800011e4:	e426                	sd	s1,8(sp)
    800011e6:	1000                	addi	s0,sp,32
    800011e8:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800011ea:	1552                	slli	a0,a0,0x34
    800011ec:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800011f0:	4601                	li	a2,0
    800011f2:	00008517          	auipc	a0,0x8
    800011f6:	e1e53503          	ld	a0,-482(a0) # 80009010 <kernel_pagetable>
    800011fa:	00000097          	auipc	ra,0x0
    800011fe:	efc080e7          	jalr	-260(ra) # 800010f6 <walk>
  if(pte == 0)
    80001202:	cd09                	beqz	a0,8000121c <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001204:	6108                	ld	a0,0(a0)
    80001206:	00157793          	andi	a5,a0,1
    8000120a:	c38d                	beqz	a5,8000122c <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000120c:	8129                	srli	a0,a0,0xa
    8000120e:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001210:	9526                	add	a0,a0,s1
    80001212:	60e2                	ld	ra,24(sp)
    80001214:	6442                	ld	s0,16(sp)
    80001216:	64a2                	ld	s1,8(sp)
    80001218:	6105                	addi	sp,sp,32
    8000121a:	8082                	ret
    panic("kvmpa");
    8000121c:	00007517          	auipc	a0,0x7
    80001220:	ef450513          	addi	a0,a0,-268 # 80008110 <digits+0xd0>
    80001224:	fffff097          	auipc	ra,0xfffff
    80001228:	324080e7          	jalr	804(ra) # 80000548 <panic>
    panic("kvmpa");
    8000122c:	00007517          	auipc	a0,0x7
    80001230:	ee450513          	addi	a0,a0,-284 # 80008110 <digits+0xd0>
    80001234:	fffff097          	auipc	ra,0xfffff
    80001238:	314080e7          	jalr	788(ra) # 80000548 <panic>

000000008000123c <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000123c:	715d                	addi	sp,sp,-80
    8000123e:	e486                	sd	ra,72(sp)
    80001240:	e0a2                	sd	s0,64(sp)
    80001242:	fc26                	sd	s1,56(sp)
    80001244:	f84a                	sd	s2,48(sp)
    80001246:	f44e                	sd	s3,40(sp)
    80001248:	f052                	sd	s4,32(sp)
    8000124a:	ec56                	sd	s5,24(sp)
    8000124c:	e85a                	sd	s6,16(sp)
    8000124e:	e45e                	sd	s7,8(sp)
    80001250:	0880                	addi	s0,sp,80
    80001252:	8aaa                	mv	s5,a0
    80001254:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001256:	777d                	lui	a4,0xfffff
    80001258:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000125c:	167d                	addi	a2,a2,-1
    8000125e:	00b609b3          	add	s3,a2,a1
    80001262:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001266:	893e                	mv	s2,a5
    80001268:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000126c:	6b85                	lui	s7,0x1
    8000126e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001272:	4605                	li	a2,1
    80001274:	85ca                	mv	a1,s2
    80001276:	8556                	mv	a0,s5
    80001278:	00000097          	auipc	ra,0x0
    8000127c:	e7e080e7          	jalr	-386(ra) # 800010f6 <walk>
    80001280:	c51d                	beqz	a0,800012ae <mappages+0x72>
    if(*pte & PTE_V)
    80001282:	611c                	ld	a5,0(a0)
    80001284:	8b85                	andi	a5,a5,1
    80001286:	ef81                	bnez	a5,8000129e <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001288:	80b1                	srli	s1,s1,0xc
    8000128a:	04aa                	slli	s1,s1,0xa
    8000128c:	0164e4b3          	or	s1,s1,s6
    80001290:	0014e493          	ori	s1,s1,1
    80001294:	e104                	sd	s1,0(a0)
    if(a == last)
    80001296:	03390863          	beq	s2,s3,800012c6 <mappages+0x8a>
    a += PGSIZE;
    8000129a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000129c:	bfc9                	j	8000126e <mappages+0x32>
      panic("remap");
    8000129e:	00007517          	auipc	a0,0x7
    800012a2:	e7a50513          	addi	a0,a0,-390 # 80008118 <digits+0xd8>
    800012a6:	fffff097          	auipc	ra,0xfffff
    800012aa:	2a2080e7          	jalr	674(ra) # 80000548 <panic>
      return -1;
    800012ae:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
  return 0;
    800012c6:	4501                	li	a0,0
    800012c8:	b7e5                	j	800012b0 <mappages+0x74>

00000000800012ca <kvmmap>:
{
    800012ca:	1141                	addi	sp,sp,-16
    800012cc:	e406                	sd	ra,8(sp)
    800012ce:	e022                	sd	s0,0(sp)
    800012d0:	0800                	addi	s0,sp,16
    800012d2:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800012d4:	86ae                	mv	a3,a1
    800012d6:	85aa                	mv	a1,a0
    800012d8:	00008517          	auipc	a0,0x8
    800012dc:	d3853503          	ld	a0,-712(a0) # 80009010 <kernel_pagetable>
    800012e0:	00000097          	auipc	ra,0x0
    800012e4:	f5c080e7          	jalr	-164(ra) # 8000123c <mappages>
    800012e8:	e509                	bnez	a0,800012f2 <kvmmap+0x28>
}
    800012ea:	60a2                	ld	ra,8(sp)
    800012ec:	6402                	ld	s0,0(sp)
    800012ee:	0141                	addi	sp,sp,16
    800012f0:	8082                	ret
    panic("kvmmap");
    800012f2:	00007517          	auipc	a0,0x7
    800012f6:	e2e50513          	addi	a0,a0,-466 # 80008120 <digits+0xe0>
    800012fa:	fffff097          	auipc	ra,0xfffff
    800012fe:	24e080e7          	jalr	590(ra) # 80000548 <panic>

0000000080001302 <kvminit>:
{
    80001302:	1101                	addi	sp,sp,-32
    80001304:	ec06                	sd	ra,24(sp)
    80001306:	e822                	sd	s0,16(sp)
    80001308:	e426                	sd	s1,8(sp)
    8000130a:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000130c:	00000097          	auipc	ra,0x0
    80001310:	870080e7          	jalr	-1936(ra) # 80000b7c <kalloc>
    80001314:	00008797          	auipc	a5,0x8
    80001318:	cea7be23          	sd	a0,-772(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000131c:	6605                	lui	a2,0x1
    8000131e:	4581                	li	a1,0
    80001320:	00000097          	auipc	ra,0x0
    80001324:	aea080e7          	jalr	-1302(ra) # 80000e0a <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001328:	4699                	li	a3,6
    8000132a:	6605                	lui	a2,0x1
    8000132c:	100005b7          	lui	a1,0x10000
    80001330:	10000537          	lui	a0,0x10000
    80001334:	00000097          	auipc	ra,0x0
    80001338:	f96080e7          	jalr	-106(ra) # 800012ca <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000133c:	4699                	li	a3,6
    8000133e:	6605                	lui	a2,0x1
    80001340:	100015b7          	lui	a1,0x10001
    80001344:	10001537          	lui	a0,0x10001
    80001348:	00000097          	auipc	ra,0x0
    8000134c:	f82080e7          	jalr	-126(ra) # 800012ca <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001350:	4699                	li	a3,6
    80001352:	6641                	lui	a2,0x10
    80001354:	020005b7          	lui	a1,0x2000
    80001358:	02000537          	lui	a0,0x2000
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	f6e080e7          	jalr	-146(ra) # 800012ca <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001364:	4699                	li	a3,6
    80001366:	00400637          	lui	a2,0x400
    8000136a:	0c0005b7          	lui	a1,0xc000
    8000136e:	0c000537          	lui	a0,0xc000
    80001372:	00000097          	auipc	ra,0x0
    80001376:	f58080e7          	jalr	-168(ra) # 800012ca <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000137a:	00007497          	auipc	s1,0x7
    8000137e:	c8648493          	addi	s1,s1,-890 # 80008000 <etext>
    80001382:	46a9                	li	a3,10
    80001384:	80007617          	auipc	a2,0x80007
    80001388:	c7c60613          	addi	a2,a2,-900 # 8000 <_entry-0x7fff8000>
    8000138c:	4585                	li	a1,1
    8000138e:	05fe                	slli	a1,a1,0x1f
    80001390:	852e                	mv	a0,a1
    80001392:	00000097          	auipc	ra,0x0
    80001396:	f38080e7          	jalr	-200(ra) # 800012ca <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000139a:	4699                	li	a3,6
    8000139c:	4645                	li	a2,17
    8000139e:	066e                	slli	a2,a2,0x1b
    800013a0:	8e05                	sub	a2,a2,s1
    800013a2:	85a6                	mv	a1,s1
    800013a4:	8526                	mv	a0,s1
    800013a6:	00000097          	auipc	ra,0x0
    800013aa:	f24080e7          	jalr	-220(ra) # 800012ca <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800013ae:	46a9                	li	a3,10
    800013b0:	6605                	lui	a2,0x1
    800013b2:	00006597          	auipc	a1,0x6
    800013b6:	c4e58593          	addi	a1,a1,-946 # 80007000 <_trampoline>
    800013ba:	04000537          	lui	a0,0x4000
    800013be:	157d                	addi	a0,a0,-1
    800013c0:	0532                	slli	a0,a0,0xc
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	f08080e7          	jalr	-248(ra) # 800012ca <kvmmap>
}
    800013ca:	60e2                	ld	ra,24(sp)
    800013cc:	6442                	ld	s0,16(sp)
    800013ce:	64a2                	ld	s1,8(sp)
    800013d0:	6105                	addi	sp,sp,32
    800013d2:	8082                	ret

00000000800013d4 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013d4:	715d                	addi	sp,sp,-80
    800013d6:	e486                	sd	ra,72(sp)
    800013d8:	e0a2                	sd	s0,64(sp)
    800013da:	fc26                	sd	s1,56(sp)
    800013dc:	f84a                	sd	s2,48(sp)
    800013de:	f44e                	sd	s3,40(sp)
    800013e0:	f052                	sd	s4,32(sp)
    800013e2:	ec56                	sd	s5,24(sp)
    800013e4:	e85a                	sd	s6,16(sp)
    800013e6:	e45e                	sd	s7,8(sp)
    800013e8:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013ea:	03459793          	slli	a5,a1,0x34
    800013ee:	e795                	bnez	a5,8000141a <uvmunmap+0x46>
    800013f0:	8a2a                	mv	s4,a0
    800013f2:	892e                	mv	s2,a1
    800013f4:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013f6:	0632                	slli	a2,a2,0xc
    800013f8:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013fc:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013fe:	6b05                	lui	s6,0x1
    80001400:	0735e863          	bltu	a1,s3,80001470 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001404:	60a6                	ld	ra,72(sp)
    80001406:	6406                	ld	s0,64(sp)
    80001408:	74e2                	ld	s1,56(sp)
    8000140a:	7942                	ld	s2,48(sp)
    8000140c:	79a2                	ld	s3,40(sp)
    8000140e:	7a02                	ld	s4,32(sp)
    80001410:	6ae2                	ld	s5,24(sp)
    80001412:	6b42                	ld	s6,16(sp)
    80001414:	6ba2                	ld	s7,8(sp)
    80001416:	6161                	addi	sp,sp,80
    80001418:	8082                	ret
    panic("uvmunmap: not aligned");
    8000141a:	00007517          	auipc	a0,0x7
    8000141e:	d0e50513          	addi	a0,a0,-754 # 80008128 <digits+0xe8>
    80001422:	fffff097          	auipc	ra,0xfffff
    80001426:	126080e7          	jalr	294(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    8000142a:	00007517          	auipc	a0,0x7
    8000142e:	d1650513          	addi	a0,a0,-746 # 80008140 <digits+0x100>
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	116080e7          	jalr	278(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    8000143a:	00007517          	auipc	a0,0x7
    8000143e:	d1650513          	addi	a0,a0,-746 # 80008150 <digits+0x110>
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	106080e7          	jalr	262(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    8000144a:	00007517          	auipc	a0,0x7
    8000144e:	d1e50513          	addi	a0,a0,-738 # 80008168 <digits+0x128>
    80001452:	fffff097          	auipc	ra,0xfffff
    80001456:	0f6080e7          	jalr	246(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    8000145a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000145c:	0532                	slli	a0,a0,0xc
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	5c6080e7          	jalr	1478(ra) # 80000a24 <kfree>
    *pte = 0;
    80001466:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000146a:	995a                	add	s2,s2,s6
    8000146c:	f9397ce3          	bgeu	s2,s3,80001404 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001470:	4601                	li	a2,0
    80001472:	85ca                	mv	a1,s2
    80001474:	8552                	mv	a0,s4
    80001476:	00000097          	auipc	ra,0x0
    8000147a:	c80080e7          	jalr	-896(ra) # 800010f6 <walk>
    8000147e:	84aa                	mv	s1,a0
    80001480:	d54d                	beqz	a0,8000142a <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001482:	6108                	ld	a0,0(a0)
    80001484:	00157793          	andi	a5,a0,1
    80001488:	dbcd                	beqz	a5,8000143a <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000148a:	3ff57793          	andi	a5,a0,1023
    8000148e:	fb778ee3          	beq	a5,s7,8000144a <uvmunmap+0x76>
    if(do_free){
    80001492:	fc0a8ae3          	beqz	s5,80001466 <uvmunmap+0x92>
    80001496:	b7d1                	j	8000145a <uvmunmap+0x86>

0000000080001498 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001498:	1101                	addi	sp,sp,-32
    8000149a:	ec06                	sd	ra,24(sp)
    8000149c:	e822                	sd	s0,16(sp)
    8000149e:	e426                	sd	s1,8(sp)
    800014a0:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014a2:	fffff097          	auipc	ra,0xfffff
    800014a6:	6da080e7          	jalr	1754(ra) # 80000b7c <kalloc>
    800014aa:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014ac:	c519                	beqz	a0,800014ba <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014ae:	6605                	lui	a2,0x1
    800014b0:	4581                	li	a1,0
    800014b2:	00000097          	auipc	ra,0x0
    800014b6:	958080e7          	jalr	-1704(ra) # 80000e0a <memset>
  return pagetable;
}
    800014ba:	8526                	mv	a0,s1
    800014bc:	60e2                	ld	ra,24(sp)
    800014be:	6442                	ld	s0,16(sp)
    800014c0:	64a2                	ld	s1,8(sp)
    800014c2:	6105                	addi	sp,sp,32
    800014c4:	8082                	ret

00000000800014c6 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800014c6:	7179                	addi	sp,sp,-48
    800014c8:	f406                	sd	ra,40(sp)
    800014ca:	f022                	sd	s0,32(sp)
    800014cc:	ec26                	sd	s1,24(sp)
    800014ce:	e84a                	sd	s2,16(sp)
    800014d0:	e44e                	sd	s3,8(sp)
    800014d2:	e052                	sd	s4,0(sp)
    800014d4:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014d6:	6785                	lui	a5,0x1
    800014d8:	04f67863          	bgeu	a2,a5,80001528 <uvminit+0x62>
    800014dc:	8a2a                	mv	s4,a0
    800014de:	89ae                	mv	s3,a1
    800014e0:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800014e2:	fffff097          	auipc	ra,0xfffff
    800014e6:	69a080e7          	jalr	1690(ra) # 80000b7c <kalloc>
    800014ea:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014ec:	6605                	lui	a2,0x1
    800014ee:	4581                	li	a1,0
    800014f0:	00000097          	auipc	ra,0x0
    800014f4:	91a080e7          	jalr	-1766(ra) # 80000e0a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014f8:	4779                	li	a4,30
    800014fa:	86ca                	mv	a3,s2
    800014fc:	6605                	lui	a2,0x1
    800014fe:	4581                	li	a1,0
    80001500:	8552                	mv	a0,s4
    80001502:	00000097          	auipc	ra,0x0
    80001506:	d3a080e7          	jalr	-710(ra) # 8000123c <mappages>
  memmove(mem, src, sz);
    8000150a:	8626                	mv	a2,s1
    8000150c:	85ce                	mv	a1,s3
    8000150e:	854a                	mv	a0,s2
    80001510:	00000097          	auipc	ra,0x0
    80001514:	95a080e7          	jalr	-1702(ra) # 80000e6a <memmove>
}
    80001518:	70a2                	ld	ra,40(sp)
    8000151a:	7402                	ld	s0,32(sp)
    8000151c:	64e2                	ld	s1,24(sp)
    8000151e:	6942                	ld	s2,16(sp)
    80001520:	69a2                	ld	s3,8(sp)
    80001522:	6a02                	ld	s4,0(sp)
    80001524:	6145                	addi	sp,sp,48
    80001526:	8082                	ret
    panic("inituvm: more than a page");
    80001528:	00007517          	auipc	a0,0x7
    8000152c:	c5850513          	addi	a0,a0,-936 # 80008180 <digits+0x140>
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	018080e7          	jalr	24(ra) # 80000548 <panic>

0000000080001538 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001538:	1101                	addi	sp,sp,-32
    8000153a:	ec06                	sd	ra,24(sp)
    8000153c:	e822                	sd	s0,16(sp)
    8000153e:	e426                	sd	s1,8(sp)
    80001540:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001542:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001544:	00b67d63          	bgeu	a2,a1,8000155e <uvmdealloc+0x26>
    80001548:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000154a:	6785                	lui	a5,0x1
    8000154c:	17fd                	addi	a5,a5,-1
    8000154e:	00f60733          	add	a4,a2,a5
    80001552:	767d                	lui	a2,0xfffff
    80001554:	8f71                	and	a4,a4,a2
    80001556:	97ae                	add	a5,a5,a1
    80001558:	8ff1                	and	a5,a5,a2
    8000155a:	00f76863          	bltu	a4,a5,8000156a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000155e:	8526                	mv	a0,s1
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000156a:	8f99                	sub	a5,a5,a4
    8000156c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000156e:	4685                	li	a3,1
    80001570:	0007861b          	sext.w	a2,a5
    80001574:	85ba                	mv	a1,a4
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	e5e080e7          	jalr	-418(ra) # 800013d4 <uvmunmap>
    8000157e:	b7c5                	j	8000155e <uvmdealloc+0x26>

0000000080001580 <uvmalloc>:
  if(newsz < oldsz)
    80001580:	0ab66163          	bltu	a2,a1,80001622 <uvmalloc+0xa2>
{
    80001584:	7139                	addi	sp,sp,-64
    80001586:	fc06                	sd	ra,56(sp)
    80001588:	f822                	sd	s0,48(sp)
    8000158a:	f426                	sd	s1,40(sp)
    8000158c:	f04a                	sd	s2,32(sp)
    8000158e:	ec4e                	sd	s3,24(sp)
    80001590:	e852                	sd	s4,16(sp)
    80001592:	e456                	sd	s5,8(sp)
    80001594:	0080                	addi	s0,sp,64
    80001596:	8aaa                	mv	s5,a0
    80001598:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000159a:	6985                	lui	s3,0x1
    8000159c:	19fd                	addi	s3,s3,-1
    8000159e:	95ce                	add	a1,a1,s3
    800015a0:	79fd                	lui	s3,0xfffff
    800015a2:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015a6:	08c9f063          	bgeu	s3,a2,80001626 <uvmalloc+0xa6>
    800015aa:	894e                	mv	s2,s3
    mem = kalloc();
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	5d0080e7          	jalr	1488(ra) # 80000b7c <kalloc>
    800015b4:	84aa                	mv	s1,a0
    if(mem == 0){
    800015b6:	c51d                	beqz	a0,800015e4 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	4581                	li	a1,0
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	84e080e7          	jalr	-1970(ra) # 80000e0a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800015c4:	4779                	li	a4,30
    800015c6:	86a6                	mv	a3,s1
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ca                	mv	a1,s2
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	c6e080e7          	jalr	-914(ra) # 8000123c <mappages>
    800015d6:	e905                	bnez	a0,80001606 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	993e                	add	s2,s2,a5
    800015dc:	fd4968e3          	bltu	s2,s4,800015ac <uvmalloc+0x2c>
  return newsz;
    800015e0:	8552                	mv	a0,s4
    800015e2:	a809                	j	800015f4 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800015e4:	864e                	mv	a2,s3
    800015e6:	85ca                	mv	a1,s2
    800015e8:	8556                	mv	a0,s5
    800015ea:	00000097          	auipc	ra,0x0
    800015ee:	f4e080e7          	jalr	-178(ra) # 80001538 <uvmdealloc>
      return 0;
    800015f2:	4501                	li	a0,0
}
    800015f4:	70e2                	ld	ra,56(sp)
    800015f6:	7442                	ld	s0,48(sp)
    800015f8:	74a2                	ld	s1,40(sp)
    800015fa:	7902                	ld	s2,32(sp)
    800015fc:	69e2                	ld	s3,24(sp)
    800015fe:	6a42                	ld	s4,16(sp)
    80001600:	6aa2                	ld	s5,8(sp)
    80001602:	6121                	addi	sp,sp,64
    80001604:	8082                	ret
      kfree(mem);
    80001606:	8526                	mv	a0,s1
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	41c080e7          	jalr	1052(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001610:	864e                	mv	a2,s3
    80001612:	85ca                	mv	a1,s2
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	f22080e7          	jalr	-222(ra) # 80001538 <uvmdealloc>
      return 0;
    8000161e:	4501                	li	a0,0
    80001620:	bfd1                	j	800015f4 <uvmalloc+0x74>
    return oldsz;
    80001622:	852e                	mv	a0,a1
}
    80001624:	8082                	ret
  return newsz;
    80001626:	8532                	mv	a0,a2
    80001628:	b7f1                	j	800015f4 <uvmalloc+0x74>

000000008000162a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000162a:	7179                	addi	sp,sp,-48
    8000162c:	f406                	sd	ra,40(sp)
    8000162e:	f022                	sd	s0,32(sp)
    80001630:	ec26                	sd	s1,24(sp)
    80001632:	e84a                	sd	s2,16(sp)
    80001634:	e44e                	sd	s3,8(sp)
    80001636:	e052                	sd	s4,0(sp)
    80001638:	1800                	addi	s0,sp,48
    8000163a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000163c:	84aa                	mv	s1,a0
    8000163e:	6905                	lui	s2,0x1
    80001640:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001642:	4985                	li	s3,1
    80001644:	a821                	j	8000165c <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001646:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001648:	0532                	slli	a0,a0,0xc
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	fe0080e7          	jalr	-32(ra) # 8000162a <freewalk>
      pagetable[i] = 0;
    80001652:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001656:	04a1                	addi	s1,s1,8
    80001658:	03248163          	beq	s1,s2,8000167a <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000165c:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000165e:	00f57793          	andi	a5,a0,15
    80001662:	ff3782e3          	beq	a5,s3,80001646 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001666:	8905                	andi	a0,a0,1
    80001668:	d57d                	beqz	a0,80001656 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b3650513          	addi	a0,a0,-1226 # 800081a0 <digits+0x160>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ed6080e7          	jalr	-298(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    8000167a:	8552                	mv	a0,s4
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	3a8080e7          	jalr	936(ra) # 80000a24 <kfree>
}
    80001684:	70a2                	ld	ra,40(sp)
    80001686:	7402                	ld	s0,32(sp)
    80001688:	64e2                	ld	s1,24(sp)
    8000168a:	6942                	ld	s2,16(sp)
    8000168c:	69a2                	ld	s3,8(sp)
    8000168e:	6a02                	ld	s4,0(sp)
    80001690:	6145                	addi	sp,sp,48
    80001692:	8082                	ret

0000000080001694 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001694:	1101                	addi	sp,sp,-32
    80001696:	ec06                	sd	ra,24(sp)
    80001698:	e822                	sd	s0,16(sp)
    8000169a:	e426                	sd	s1,8(sp)
    8000169c:	1000                	addi	s0,sp,32
    8000169e:	84aa                	mv	s1,a0
  if(sz > 0)
    800016a0:	e999                	bnez	a1,800016b6 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016a2:	8526                	mv	a0,s1
    800016a4:	00000097          	auipc	ra,0x0
    800016a8:	f86080e7          	jalr	-122(ra) # 8000162a <freewalk>
}
    800016ac:	60e2                	ld	ra,24(sp)
    800016ae:	6442                	ld	s0,16(sp)
    800016b0:	64a2                	ld	s1,8(sp)
    800016b2:	6105                	addi	sp,sp,32
    800016b4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016b6:	6605                	lui	a2,0x1
    800016b8:	167d                	addi	a2,a2,-1
    800016ba:	962e                	add	a2,a2,a1
    800016bc:	4685                	li	a3,1
    800016be:	8231                	srli	a2,a2,0xc
    800016c0:	4581                	li	a1,0
    800016c2:	00000097          	auipc	ra,0x0
    800016c6:	d12080e7          	jalr	-750(ra) # 800013d4 <uvmunmap>
    800016ca:	bfe1                	j	800016a2 <uvmfree+0xe>

00000000800016cc <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    800016cc:	7139                	addi	sp,sp,-64
    800016ce:	fc06                	sd	ra,56(sp)
    800016d0:	f822                	sd	s0,48(sp)
    800016d2:	f426                	sd	s1,40(sp)
    800016d4:	f04a                	sd	s2,32(sp)
    800016d6:	ec4e                	sd	s3,24(sp)
    800016d8:	e852                	sd	s4,16(sp)
    800016da:	e456                	sd	s5,8(sp)
    800016dc:	e05a                	sd	s6,0(sp)
    800016de:	0080                	addi	s0,sp,64
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    800016e0:	c255                	beqz	a2,80001784 <uvmcopy+0xb8>
    800016e2:	8b2a                	mv	s6,a0
    800016e4:	8aae                	mv	s5,a1
    800016e6:	8a32                	mv	s4,a2
    800016e8:	4481                	li	s1,0
    if((pte = walk(old, i, 0)) == 0)
    800016ea:	4601                	li	a2,0
    800016ec:	85a6                	mv	a1,s1
    800016ee:	855a                	mv	a0,s6
    800016f0:	00000097          	auipc	ra,0x0
    800016f4:	a06080e7          	jalr	-1530(ra) # 800010f6 <walk>
    800016f8:	c129                	beqz	a0,8000173a <uvmcopy+0x6e>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016fa:	6118                	ld	a4,0(a0)
    800016fc:	00177793          	andi	a5,a4,1
    80001700:	c7a9                	beqz	a5,8000174a <uvmcopy+0x7e>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001702:	00a75913          	srli	s2,a4,0xa
    80001706:	0932                	slli	s2,s2,0xc
    *pte &= ~PTE_W;  // mask off W bit
    80001708:	9b6d                	andi	a4,a4,-5
    8000170a:	e118                	sd	a4,0(a0)
    flags = PTE_FLAGS(*pte);
    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    8000170c:	3fb77713          	andi	a4,a4,1019
    80001710:	86ca                	mv	a3,s2
    80001712:	6605                	lui	a2,0x1
    80001714:	85a6                	mv	a1,s1
    80001716:	8556                	mv	a0,s5
    80001718:	00000097          	auipc	ra,0x0
    8000171c:	b24080e7          	jalr	-1244(ra) # 8000123c <mappages>
    80001720:	89aa                	mv	s3,a0
    80001722:	ed05                	bnez	a0,8000175a <uvmcopy+0x8e>
      goto err;
    }
    adjustref(pa, 1); // one more process refers to this page
    80001724:	4585                	li	a1,1
    80001726:	854a                	mv	a0,s2
    80001728:	fffff097          	auipc	ra,0xfffff
    8000172c:	4ec080e7          	jalr	1260(ra) # 80000c14 <adjustref>
  for(i = 0; i < sz; i += PGSIZE){
    80001730:	6785                	lui	a5,0x1
    80001732:	94be                	add	s1,s1,a5
    80001734:	fb44ebe3          	bltu	s1,s4,800016ea <uvmcopy+0x1e>
    80001738:	a81d                	j	8000176e <uvmcopy+0xa2>
      panic("uvmcopy: pte should exist");
    8000173a:	00007517          	auipc	a0,0x7
    8000173e:	a7650513          	addi	a0,a0,-1418 # 800081b0 <digits+0x170>
    80001742:	fffff097          	auipc	ra,0xfffff
    80001746:	e06080e7          	jalr	-506(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    8000174a:	00007517          	auipc	a0,0x7
    8000174e:	a8650513          	addi	a0,a0,-1402 # 800081d0 <digits+0x190>
    80001752:	fffff097          	auipc	ra,0xfffff
    80001756:	df6080e7          	jalr	-522(ra) # 80000548 <panic>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000175a:	4685                	li	a3,1
    8000175c:	00c4d613          	srli	a2,s1,0xc
    80001760:	4581                	li	a1,0
    80001762:	8556                	mv	a0,s5
    80001764:	00000097          	auipc	ra,0x0
    80001768:	c70080e7          	jalr	-912(ra) # 800013d4 <uvmunmap>
  return -1;
    8000176c:	59fd                	li	s3,-1
}
    8000176e:	854e                	mv	a0,s3
    80001770:	70e2                	ld	ra,56(sp)
    80001772:	7442                	ld	s0,48(sp)
    80001774:	74a2                	ld	s1,40(sp)
    80001776:	7902                	ld	s2,32(sp)
    80001778:	69e2                	ld	s3,24(sp)
    8000177a:	6a42                	ld	s4,16(sp)
    8000177c:	6aa2                	ld	s5,8(sp)
    8000177e:	6b02                	ld	s6,0(sp)
    80001780:	6121                	addi	sp,sp,64
    80001782:	8082                	ret
  return 0;
    80001784:	4981                	li	s3,0
    80001786:	b7e5                	j	8000176e <uvmcopy+0xa2>

0000000080001788 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001788:	1141                	addi	sp,sp,-16
    8000178a:	e406                	sd	ra,8(sp)
    8000178c:	e022                	sd	s0,0(sp)
    8000178e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001790:	4601                	li	a2,0
    80001792:	00000097          	auipc	ra,0x0
    80001796:	964080e7          	jalr	-1692(ra) # 800010f6 <walk>
  if(pte == 0)
    8000179a:	c901                	beqz	a0,800017aa <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000179c:	611c                	ld	a5,0(a0)
    8000179e:	9bbd                	andi	a5,a5,-17
    800017a0:	e11c                	sd	a5,0(a0)
}
    800017a2:	60a2                	ld	ra,8(sp)
    800017a4:	6402                	ld	s0,0(sp)
    800017a6:	0141                	addi	sp,sp,16
    800017a8:	8082                	ret
    panic("uvmclear");
    800017aa:	00007517          	auipc	a0,0x7
    800017ae:	a4650513          	addi	a0,a0,-1466 # 800081f0 <digits+0x1b0>
    800017b2:	fffff097          	auipc	ra,0xfffff
    800017b6:	d96080e7          	jalr	-618(ra) # 80000548 <panic>

00000000800017ba <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ba:	c6bd                	beqz	a3,80001828 <copyin+0x6e>
{
    800017bc:	715d                	addi	sp,sp,-80
    800017be:	e486                	sd	ra,72(sp)
    800017c0:	e0a2                	sd	s0,64(sp)
    800017c2:	fc26                	sd	s1,56(sp)
    800017c4:	f84a                	sd	s2,48(sp)
    800017c6:	f44e                	sd	s3,40(sp)
    800017c8:	f052                	sd	s4,32(sp)
    800017ca:	ec56                	sd	s5,24(sp)
    800017cc:	e85a                	sd	s6,16(sp)
    800017ce:	e45e                	sd	s7,8(sp)
    800017d0:	e062                	sd	s8,0(sp)
    800017d2:	0880                	addi	s0,sp,80
    800017d4:	8b2a                	mv	s6,a0
    800017d6:	8a2e                	mv	s4,a1
    800017d8:	8c32                	mv	s8,a2
    800017da:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017dc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017de:	6a85                	lui	s5,0x1
    800017e0:	a015                	j	80001804 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017e2:	9562                	add	a0,a0,s8
    800017e4:	0004861b          	sext.w	a2,s1
    800017e8:	412505b3          	sub	a1,a0,s2
    800017ec:	8552                	mv	a0,s4
    800017ee:	fffff097          	auipc	ra,0xfffff
    800017f2:	67c080e7          	jalr	1660(ra) # 80000e6a <memmove>

    len -= n;
    800017f6:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017fa:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017fc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001800:	02098263          	beqz	s3,80001824 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001804:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001808:	85ca                	mv	a1,s2
    8000180a:	855a                	mv	a0,s6
    8000180c:	00000097          	auipc	ra,0x0
    80001810:	990080e7          	jalr	-1648(ra) # 8000119c <walkaddr>
    if(pa0 == 0)
    80001814:	cd01                	beqz	a0,8000182c <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001816:	418904b3          	sub	s1,s2,s8
    8000181a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000181c:	fc99f3e3          	bgeu	s3,s1,800017e2 <copyin+0x28>
    80001820:	84ce                	mv	s1,s3
    80001822:	b7c1                	j	800017e2 <copyin+0x28>
  }
  return 0;
    80001824:	4501                	li	a0,0
    80001826:	a021                	j	8000182e <copyin+0x74>
    80001828:	4501                	li	a0,0
}
    8000182a:	8082                	ret
      return -1;
    8000182c:	557d                	li	a0,-1
}
    8000182e:	60a6                	ld	ra,72(sp)
    80001830:	6406                	ld	s0,64(sp)
    80001832:	74e2                	ld	s1,56(sp)
    80001834:	7942                	ld	s2,48(sp)
    80001836:	79a2                	ld	s3,40(sp)
    80001838:	7a02                	ld	s4,32(sp)
    8000183a:	6ae2                	ld	s5,24(sp)
    8000183c:	6b42                	ld	s6,16(sp)
    8000183e:	6ba2                	ld	s7,8(sp)
    80001840:	6c02                	ld	s8,0(sp)
    80001842:	6161                	addi	sp,sp,80
    80001844:	8082                	ret

0000000080001846 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001846:	c6c5                	beqz	a3,800018ee <copyinstr+0xa8>
{
    80001848:	715d                	addi	sp,sp,-80
    8000184a:	e486                	sd	ra,72(sp)
    8000184c:	e0a2                	sd	s0,64(sp)
    8000184e:	fc26                	sd	s1,56(sp)
    80001850:	f84a                	sd	s2,48(sp)
    80001852:	f44e                	sd	s3,40(sp)
    80001854:	f052                	sd	s4,32(sp)
    80001856:	ec56                	sd	s5,24(sp)
    80001858:	e85a                	sd	s6,16(sp)
    8000185a:	e45e                	sd	s7,8(sp)
    8000185c:	0880                	addi	s0,sp,80
    8000185e:	8a2a                	mv	s4,a0
    80001860:	8b2e                	mv	s6,a1
    80001862:	8bb2                	mv	s7,a2
    80001864:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001866:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001868:	6985                	lui	s3,0x1
    8000186a:	a035                	j	80001896 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000186c:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001870:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001872:	0017b793          	seqz	a5,a5
    80001876:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000187a:	60a6                	ld	ra,72(sp)
    8000187c:	6406                	ld	s0,64(sp)
    8000187e:	74e2                	ld	s1,56(sp)
    80001880:	7942                	ld	s2,48(sp)
    80001882:	79a2                	ld	s3,40(sp)
    80001884:	7a02                	ld	s4,32(sp)
    80001886:	6ae2                	ld	s5,24(sp)
    80001888:	6b42                	ld	s6,16(sp)
    8000188a:	6ba2                	ld	s7,8(sp)
    8000188c:	6161                	addi	sp,sp,80
    8000188e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001890:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001894:	c8a9                	beqz	s1,800018e6 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001896:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000189a:	85ca                	mv	a1,s2
    8000189c:	8552                	mv	a0,s4
    8000189e:	00000097          	auipc	ra,0x0
    800018a2:	8fe080e7          	jalr	-1794(ra) # 8000119c <walkaddr>
    if(pa0 == 0)
    800018a6:	c131                	beqz	a0,800018ea <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018a8:	41790833          	sub	a6,s2,s7
    800018ac:	984e                	add	a6,a6,s3
    if(n > max)
    800018ae:	0104f363          	bgeu	s1,a6,800018b4 <copyinstr+0x6e>
    800018b2:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018b4:	955e                	add	a0,a0,s7
    800018b6:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018ba:	fc080be3          	beqz	a6,80001890 <copyinstr+0x4a>
    800018be:	985a                	add	a6,a6,s6
    800018c0:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018c2:	41650633          	sub	a2,a0,s6
    800018c6:	14fd                	addi	s1,s1,-1
    800018c8:	9b26                	add	s6,s6,s1
    800018ca:	00f60733          	add	a4,a2,a5
    800018ce:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdb9000>
    800018d2:	df49                	beqz	a4,8000186c <copyinstr+0x26>
        *dst = *p;
    800018d4:	00e78023          	sb	a4,0(a5)
      --max;
    800018d8:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018dc:	0785                	addi	a5,a5,1
    while(n > 0){
    800018de:	ff0796e3          	bne	a5,a6,800018ca <copyinstr+0x84>
      dst++;
    800018e2:	8b42                	mv	s6,a6
    800018e4:	b775                	j	80001890 <copyinstr+0x4a>
    800018e6:	4781                	li	a5,0
    800018e8:	b769                	j	80001872 <copyinstr+0x2c>
      return -1;
    800018ea:	557d                	li	a0,-1
    800018ec:	b779                	j	8000187a <copyinstr+0x34>
  int got_null = 0;
    800018ee:	4781                	li	a5,0
  if(got_null){
    800018f0:	0017b793          	seqz	a5,a5
    800018f4:	40f00533          	neg	a0,a5
}
    800018f8:	8082                	ret

00000000800018fa <cowalloc>:

// copy-on-write page fault handler
// allocate a new physical page
// for virtual address va in this process's pagetable
int
cowalloc(pagetable_t pagetable, uint64 va) {
    800018fa:	7179                	addi	sp,sp,-48
    800018fc:	f406                	sd	ra,40(sp)
    800018fe:	f022                	sd	s0,32(sp)
    80001900:	ec26                	sd	s1,24(sp)
    80001902:	e84a                	sd	s2,16(sp)
    80001904:	e44e                	sd	s3,8(sp)
    80001906:	1800                	addi	s0,sp,48
  if (va >= MAXVA) {
    80001908:	57fd                	li	a5,-1
    8000190a:	83e9                	srli	a5,a5,0x1a
    8000190c:	06b7e763          	bltu	a5,a1,8000197a <cowalloc+0x80>
    printf("cowalloc: exceeds MAXVA\n");
    return -1;
  }

  pte_t* pte = walk(pagetable, va, 0); // should refer to a shared PA
    80001910:	4601                	li	a2,0
    80001912:	fffff097          	auipc	ra,0xfffff
    80001916:	7e4080e7          	jalr	2020(ra) # 800010f6 <walk>
    8000191a:	892a                	mv	s2,a0
  if (pte == 0) {
    8000191c:	c92d                	beqz	a0,8000198e <cowalloc+0x94>
    panic("cowalloc: pte not exists");
  }
  if ((*pte & PTE_V) == 0 || (*pte & PTE_U) == 0) {
    8000191e:	611c                	ld	a5,0(a0)
    80001920:	8bc5                	andi	a5,a5,17
    80001922:	4745                	li	a4,17
    80001924:	06e79d63          	bne	a5,a4,8000199e <cowalloc+0xa4>
    panic("cowalloc: pte permission err");
  }
  uint64 pa_new = (uint64)kalloc();
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	254080e7          	jalr	596(ra) # 80000b7c <kalloc>
    80001930:	84aa                	mv	s1,a0
  if (pa_new == 0) {
    80001932:	cd35                	beqz	a0,800019ae <cowalloc+0xb4>
    printf("cowalloc: kalloc fails\n");
    return -1;
  }
  uint64 pa_old = PTE2PA(*pte);
    80001934:	00093983          	ld	s3,0(s2) # 1000 <_entry-0x7ffff000>
    80001938:	00a9d993          	srli	s3,s3,0xa
    8000193c:	09b2                	slli	s3,s3,0xc
  memmove((void *)pa_new, (const void *)pa_old, PGSIZE);
    8000193e:	6605                	lui	a2,0x1
    80001940:	85ce                	mv	a1,s3
    80001942:	fffff097          	auipc	ra,0xfffff
    80001946:	528080e7          	jalr	1320(ra) # 80000e6a <memmove>
  kfree((void *)pa_old); // decrement ref count by 1
    8000194a:	854e                	mv	a0,s3
    8000194c:	fffff097          	auipc	ra,0xfffff
    80001950:	0d8080e7          	jalr	216(ra) # 80000a24 <kfree>
  *pte = PA2PTE(pa_new) | PTE_FLAGS(*pte) | PTE_W;
    80001954:	80b1                	srli	s1,s1,0xc
    80001956:	04aa                	slli	s1,s1,0xa
    80001958:	00093783          	ld	a5,0(s2)
    8000195c:	3ff7f793          	andi	a5,a5,1023
    80001960:	8cdd                	or	s1,s1,a5
    80001962:	0044e493          	ori	s1,s1,4
    80001966:	00993023          	sd	s1,0(s2)
  return 0;
    8000196a:	4501                	li	a0,0
}
    8000196c:	70a2                	ld	ra,40(sp)
    8000196e:	7402                	ld	s0,32(sp)
    80001970:	64e2                	ld	s1,24(sp)
    80001972:	6942                	ld	s2,16(sp)
    80001974:	69a2                	ld	s3,8(sp)
    80001976:	6145                	addi	sp,sp,48
    80001978:	8082                	ret
    printf("cowalloc: exceeds MAXVA\n");
    8000197a:	00007517          	auipc	a0,0x7
    8000197e:	88650513          	addi	a0,a0,-1914 # 80008200 <digits+0x1c0>
    80001982:	fffff097          	auipc	ra,0xfffff
    80001986:	c10080e7          	jalr	-1008(ra) # 80000592 <printf>
    return -1;
    8000198a:	557d                	li	a0,-1
    8000198c:	b7c5                	j	8000196c <cowalloc+0x72>
    panic("cowalloc: pte not exists");
    8000198e:	00007517          	auipc	a0,0x7
    80001992:	89250513          	addi	a0,a0,-1902 # 80008220 <digits+0x1e0>
    80001996:	fffff097          	auipc	ra,0xfffff
    8000199a:	bb2080e7          	jalr	-1102(ra) # 80000548 <panic>
    panic("cowalloc: pte permission err");
    8000199e:	00007517          	auipc	a0,0x7
    800019a2:	8a250513          	addi	a0,a0,-1886 # 80008240 <digits+0x200>
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	ba2080e7          	jalr	-1118(ra) # 80000548 <panic>
    printf("cowalloc: kalloc fails\n");
    800019ae:	00007517          	auipc	a0,0x7
    800019b2:	8b250513          	addi	a0,a0,-1870 # 80008260 <digits+0x220>
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	bdc080e7          	jalr	-1060(ra) # 80000592 <printf>
    return -1;
    800019be:	557d                	li	a0,-1
    800019c0:	b775                	j	8000196c <cowalloc+0x72>

00000000800019c2 <copyout>:
  while(len > 0){
    800019c2:	caf5                	beqz	a3,80001ab6 <copyout+0xf4>
{
    800019c4:	711d                	addi	sp,sp,-96
    800019c6:	ec86                	sd	ra,88(sp)
    800019c8:	e8a2                	sd	s0,80(sp)
    800019ca:	e4a6                	sd	s1,72(sp)
    800019cc:	e0ca                	sd	s2,64(sp)
    800019ce:	fc4e                	sd	s3,56(sp)
    800019d0:	f852                	sd	s4,48(sp)
    800019d2:	f456                	sd	s5,40(sp)
    800019d4:	f05a                	sd	s6,32(sp)
    800019d6:	ec5e                	sd	s7,24(sp)
    800019d8:	e862                	sd	s8,16(sp)
    800019da:	e466                	sd	s9,8(sp)
    800019dc:	e06a                	sd	s10,0(sp)
    800019de:	1080                	addi	s0,sp,96
    800019e0:	8aaa                	mv	s5,a0
    800019e2:	89ae                	mv	s3,a1
    800019e4:	8a32                	mv	s4,a2
    800019e6:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(dstva);
    800019e8:	74fd                	lui	s1,0xfffff
    800019ea:	8ced                	and	s1,s1,a1
    if (va0 >= MAXVA) {
    800019ec:	57fd                	li	a5,-1
    800019ee:	83e9                	srli	a5,a5,0x1a
    800019f0:	0097e663          	bltu	a5,s1,800019fc <copyout+0x3a>
    if (pte == 0 || (*pte & PTE_U) == 0 || (*pte & PTE_V) == 0) {
    800019f4:	4bc5                	li	s7,17
    800019f6:	6c05                	lui	s8,0x1
    if (va0 >= MAXVA) {
    800019f8:	8b3e                	mv	s6,a5
    800019fa:	a8bd                	j	80001a78 <copyout+0xb6>
      printf("copyout: va exceeds MAXVA\n");
    800019fc:	00007517          	auipc	a0,0x7
    80001a00:	87c50513          	addi	a0,a0,-1924 # 80008278 <digits+0x238>
    80001a04:	fffff097          	auipc	ra,0xfffff
    80001a08:	b8e080e7          	jalr	-1138(ra) # 80000592 <printf>
      return -1;
    80001a0c:	557d                	li	a0,-1
    80001a0e:	a811                	j	80001a22 <copyout+0x60>
      printf("copyout: invalid pte\n");
    80001a10:	00007517          	auipc	a0,0x7
    80001a14:	88850513          	addi	a0,a0,-1912 # 80008298 <digits+0x258>
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	b7a080e7          	jalr	-1158(ra) # 80000592 <printf>
      return -1;
    80001a20:	557d                	li	a0,-1
}
    80001a22:	60e6                	ld	ra,88(sp)
    80001a24:	6446                	ld	s0,80(sp)
    80001a26:	64a6                	ld	s1,72(sp)
    80001a28:	6906                	ld	s2,64(sp)
    80001a2a:	79e2                	ld	s3,56(sp)
    80001a2c:	7a42                	ld	s4,48(sp)
    80001a2e:	7aa2                	ld	s5,40(sp)
    80001a30:	7b02                	ld	s6,32(sp)
    80001a32:	6be2                	ld	s7,24(sp)
    80001a34:	6c42                	ld	s8,16(sp)
    80001a36:	6ca2                	ld	s9,8(sp)
    80001a38:	6d02                	ld	s10,0(sp)
    80001a3a:	6125                	addi	sp,sp,96
    80001a3c:	8082                	ret
      if (cowalloc(pagetable, va0) < 0) {
    80001a3e:	85a6                	mv	a1,s1
    80001a40:	8556                	mv	a0,s5
    80001a42:	00000097          	auipc	ra,0x0
    80001a46:	eb8080e7          	jalr	-328(ra) # 800018fa <cowalloc>
    80001a4a:	04055763          	bgez	a0,80001a98 <copyout+0xd6>
        return -1;
    80001a4e:	557d                	li	a0,-1
    80001a50:	bfc9                	j	80001a22 <copyout+0x60>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001a52:	40998533          	sub	a0,s3,s1
    80001a56:	000c861b          	sext.w	a2,s9
    80001a5a:	85d2                	mv	a1,s4
    80001a5c:	953e                	add	a0,a0,a5
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	40c080e7          	jalr	1036(ra) # 80000e6a <memmove>
    len -= n;
    80001a66:	41990933          	sub	s2,s2,s9
    src += n;
    80001a6a:	9a66                	add	s4,s4,s9
  while(len > 0){
    80001a6c:	04090363          	beqz	s2,80001ab2 <copyout+0xf0>
    if (va0 >= MAXVA) {
    80001a70:	f9ab66e3          	bltu	s6,s10,800019fc <copyout+0x3a>
    va0 = PGROUNDDOWN(dstva);
    80001a74:	84ea                	mv	s1,s10
    dstva = va0 + PGSIZE;
    80001a76:	89ea                	mv	s3,s10
    pte_t *pte = walk(pagetable, va0, 0);
    80001a78:	4601                	li	a2,0
    80001a7a:	85a6                	mv	a1,s1
    80001a7c:	8556                	mv	a0,s5
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	678080e7          	jalr	1656(ra) # 800010f6 <walk>
    80001a86:	8caa                	mv	s9,a0
    if (pte == 0 || (*pte & PTE_U) == 0 || (*pte & PTE_V) == 0) {
    80001a88:	d541                	beqz	a0,80001a10 <copyout+0x4e>
    80001a8a:	611c                	ld	a5,0(a0)
    80001a8c:	0117f713          	andi	a4,a5,17
    80001a90:	f97710e3          	bne	a4,s7,80001a10 <copyout+0x4e>
    if ((*pte & PTE_W) == 0) {
    80001a94:	8b91                	andi	a5,a5,4
    80001a96:	d7c5                	beqz	a5,80001a3e <copyout+0x7c>
    pa0 = PTE2PA(*pte);
    80001a98:	000cb783          	ld	a5,0(s9)
    80001a9c:	83a9                	srli	a5,a5,0xa
    80001a9e:	07b2                	slli	a5,a5,0xc
    if(pa0 == 0)
    80001aa0:	cf89                	beqz	a5,80001aba <copyout+0xf8>
    n = PGSIZE - (dstva - va0);
    80001aa2:	01848d33          	add	s10,s1,s8
    80001aa6:	413d0cb3          	sub	s9,s10,s3
    if(n > len)
    80001aaa:	fb9974e3          	bgeu	s2,s9,80001a52 <copyout+0x90>
    80001aae:	8cca                	mv	s9,s2
    80001ab0:	b74d                	j	80001a52 <copyout+0x90>
  return 0;
    80001ab2:	4501                	li	a0,0
    80001ab4:	b7bd                	j	80001a22 <copyout+0x60>
    80001ab6:	4501                	li	a0,0
}
    80001ab8:	8082                	ret
      return -1;
    80001aba:	557d                	li	a0,-1
    80001abc:	b79d                	j	80001a22 <copyout+0x60>

0000000080001abe <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001abe:	1101                	addi	sp,sp,-32
    80001ac0:	ec06                	sd	ra,24(sp)
    80001ac2:	e822                	sd	s0,16(sp)
    80001ac4:	e426                	sd	s1,8(sp)
    80001ac6:	1000                	addi	s0,sp,32
    80001ac8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001aca:	fffff097          	auipc	ra,0xfffff
    80001ace:	1ca080e7          	jalr	458(ra) # 80000c94 <holding>
    80001ad2:	c909                	beqz	a0,80001ae4 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001ad4:	749c                	ld	a5,40(s1)
    80001ad6:	00978f63          	beq	a5,s1,80001af4 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001ada:	60e2                	ld	ra,24(sp)
    80001adc:	6442                	ld	s0,16(sp)
    80001ade:	64a2                	ld	s1,8(sp)
    80001ae0:	6105                	addi	sp,sp,32
    80001ae2:	8082                	ret
    panic("wakeup1");
    80001ae4:	00006517          	auipc	a0,0x6
    80001ae8:	7cc50513          	addi	a0,a0,1996 # 800082b0 <digits+0x270>
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	a5c080e7          	jalr	-1444(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001af4:	4c98                	lw	a4,24(s1)
    80001af6:	4785                	li	a5,1
    80001af8:	fef711e3          	bne	a4,a5,80001ada <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001afc:	4789                	li	a5,2
    80001afe:	cc9c                	sw	a5,24(s1)
}
    80001b00:	bfe9                	j	80001ada <wakeup1+0x1c>

0000000080001b02 <procinit>:
{
    80001b02:	715d                	addi	sp,sp,-80
    80001b04:	e486                	sd	ra,72(sp)
    80001b06:	e0a2                	sd	s0,64(sp)
    80001b08:	fc26                	sd	s1,56(sp)
    80001b0a:	f84a                	sd	s2,48(sp)
    80001b0c:	f44e                	sd	s3,40(sp)
    80001b0e:	f052                	sd	s4,32(sp)
    80001b10:	ec56                	sd	s5,24(sp)
    80001b12:	e85a                	sd	s6,16(sp)
    80001b14:	e45e                	sd	s7,8(sp)
    80001b16:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001b18:	00006597          	auipc	a1,0x6
    80001b1c:	7a058593          	addi	a1,a1,1952 # 800082b8 <digits+0x278>
    80001b20:	00230517          	auipc	a0,0x230
    80001b24:	e3050513          	addi	a0,a0,-464 # 80231950 <pid_lock>
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	156080e7          	jalr	342(ra) # 80000c7e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b30:	00230917          	auipc	s2,0x230
    80001b34:	23890913          	addi	s2,s2,568 # 80231d68 <proc>
      initlock(&p->lock, "proc");
    80001b38:	00006b97          	auipc	s7,0x6
    80001b3c:	788b8b93          	addi	s7,s7,1928 # 800082c0 <digits+0x280>
      uint64 va = KSTACK((int) (p - proc));
    80001b40:	8b4a                	mv	s6,s2
    80001b42:	00006a97          	auipc	s5,0x6
    80001b46:	4bea8a93          	addi	s5,s5,1214 # 80008000 <etext>
    80001b4a:	040009b7          	lui	s3,0x4000
    80001b4e:	19fd                	addi	s3,s3,-1
    80001b50:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b52:	00236a17          	auipc	s4,0x236
    80001b56:	c16a0a13          	addi	s4,s4,-1002 # 80237768 <tickslock>
      initlock(&p->lock, "proc");
    80001b5a:	85de                	mv	a1,s7
    80001b5c:	854a                	mv	a0,s2
    80001b5e:	fffff097          	auipc	ra,0xfffff
    80001b62:	120080e7          	jalr	288(ra) # 80000c7e <initlock>
      char *pa = kalloc();
    80001b66:	fffff097          	auipc	ra,0xfffff
    80001b6a:	016080e7          	jalr	22(ra) # 80000b7c <kalloc>
    80001b6e:	85aa                	mv	a1,a0
      if(pa == 0)
    80001b70:	c929                	beqz	a0,80001bc2 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001b72:	416904b3          	sub	s1,s2,s6
    80001b76:	848d                	srai	s1,s1,0x3
    80001b78:	000ab783          	ld	a5,0(s5)
    80001b7c:	02f484b3          	mul	s1,s1,a5
    80001b80:	2485                	addiw	s1,s1,1
    80001b82:	00d4949b          	slliw	s1,s1,0xd
    80001b86:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b8a:	4699                	li	a3,6
    80001b8c:	6605                	lui	a2,0x1
    80001b8e:	8526                	mv	a0,s1
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	73a080e7          	jalr	1850(ra) # 800012ca <kvmmap>
      p->kstack = va;
    80001b98:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b9c:	16890913          	addi	s2,s2,360
    80001ba0:	fb491de3          	bne	s2,s4,80001b5a <procinit+0x58>
  kvminithart();
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	52e080e7          	jalr	1326(ra) # 800010d2 <kvminithart>
}
    80001bac:	60a6                	ld	ra,72(sp)
    80001bae:	6406                	ld	s0,64(sp)
    80001bb0:	74e2                	ld	s1,56(sp)
    80001bb2:	7942                	ld	s2,48(sp)
    80001bb4:	79a2                	ld	s3,40(sp)
    80001bb6:	7a02                	ld	s4,32(sp)
    80001bb8:	6ae2                	ld	s5,24(sp)
    80001bba:	6b42                	ld	s6,16(sp)
    80001bbc:	6ba2                	ld	s7,8(sp)
    80001bbe:	6161                	addi	sp,sp,80
    80001bc0:	8082                	ret
        panic("kalloc");
    80001bc2:	00006517          	auipc	a0,0x6
    80001bc6:	70650513          	addi	a0,a0,1798 # 800082c8 <digits+0x288>
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	97e080e7          	jalr	-1666(ra) # 80000548 <panic>

0000000080001bd2 <cpuid>:
{
    80001bd2:	1141                	addi	sp,sp,-16
    80001bd4:	e422                	sd	s0,8(sp)
    80001bd6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bd8:	8512                	mv	a0,tp
}
    80001bda:	2501                	sext.w	a0,a0
    80001bdc:	6422                	ld	s0,8(sp)
    80001bde:	0141                	addi	sp,sp,16
    80001be0:	8082                	ret

0000000080001be2 <mycpu>:
mycpu(void) {
    80001be2:	1141                	addi	sp,sp,-16
    80001be4:	e422                	sd	s0,8(sp)
    80001be6:	0800                	addi	s0,sp,16
    80001be8:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001bea:	2781                	sext.w	a5,a5
    80001bec:	079e                	slli	a5,a5,0x7
}
    80001bee:	00230517          	auipc	a0,0x230
    80001bf2:	d7a50513          	addi	a0,a0,-646 # 80231968 <cpus>
    80001bf6:	953e                	add	a0,a0,a5
    80001bf8:	6422                	ld	s0,8(sp)
    80001bfa:	0141                	addi	sp,sp,16
    80001bfc:	8082                	ret

0000000080001bfe <myproc>:
myproc(void) {
    80001bfe:	1101                	addi	sp,sp,-32
    80001c00:	ec06                	sd	ra,24(sp)
    80001c02:	e822                	sd	s0,16(sp)
    80001c04:	e426                	sd	s1,8(sp)
    80001c06:	1000                	addi	s0,sp,32
  push_off();
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	0ba080e7          	jalr	186(ra) # 80000cc2 <push_off>
    80001c10:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001c12:	2781                	sext.w	a5,a5
    80001c14:	079e                	slli	a5,a5,0x7
    80001c16:	00230717          	auipc	a4,0x230
    80001c1a:	d3a70713          	addi	a4,a4,-710 # 80231950 <pid_lock>
    80001c1e:	97ba                	add	a5,a5,a4
    80001c20:	6f84                	ld	s1,24(a5)
  pop_off();
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	140080e7          	jalr	320(ra) # 80000d62 <pop_off>
}
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	60e2                	ld	ra,24(sp)
    80001c2e:	6442                	ld	s0,16(sp)
    80001c30:	64a2                	ld	s1,8(sp)
    80001c32:	6105                	addi	sp,sp,32
    80001c34:	8082                	ret

0000000080001c36 <forkret>:
{
    80001c36:	1141                	addi	sp,sp,-16
    80001c38:	e406                	sd	ra,8(sp)
    80001c3a:	e022                	sd	s0,0(sp)
    80001c3c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	fc0080e7          	jalr	-64(ra) # 80001bfe <myproc>
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	17c080e7          	jalr	380(ra) # 80000dc2 <release>
  if (first) {
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	cb27a783          	lw	a5,-846(a5) # 80008900 <first.1672>
    80001c56:	eb89                	bnez	a5,80001c68 <forkret+0x32>
  usertrapret();
    80001c58:	00001097          	auipc	ra,0x1
    80001c5c:	c1c080e7          	jalr	-996(ra) # 80002874 <usertrapret>
}
    80001c60:	60a2                	ld	ra,8(sp)
    80001c62:	6402                	ld	s0,0(sp)
    80001c64:	0141                	addi	sp,sp,16
    80001c66:	8082                	ret
    first = 0;
    80001c68:	00007797          	auipc	a5,0x7
    80001c6c:	c807ac23          	sw	zero,-872(a5) # 80008900 <first.1672>
    fsinit(ROOTDEV);
    80001c70:	4505                	li	a0,1
    80001c72:	00002097          	auipc	ra,0x2
    80001c76:	968080e7          	jalr	-1688(ra) # 800035da <fsinit>
    80001c7a:	bff9                	j	80001c58 <forkret+0x22>

0000000080001c7c <allocpid>:
allocpid() {
    80001c7c:	1101                	addi	sp,sp,-32
    80001c7e:	ec06                	sd	ra,24(sp)
    80001c80:	e822                	sd	s0,16(sp)
    80001c82:	e426                	sd	s1,8(sp)
    80001c84:	e04a                	sd	s2,0(sp)
    80001c86:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c88:	00230917          	auipc	s2,0x230
    80001c8c:	cc890913          	addi	s2,s2,-824 # 80231950 <pid_lock>
    80001c90:	854a                	mv	a0,s2
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	07c080e7          	jalr	124(ra) # 80000d0e <acquire>
  pid = nextpid;
    80001c9a:	00007797          	auipc	a5,0x7
    80001c9e:	c6a78793          	addi	a5,a5,-918 # 80008904 <nextpid>
    80001ca2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ca4:	0014871b          	addiw	a4,s1,1
    80001ca8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001caa:	854a                	mv	a0,s2
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	116080e7          	jalr	278(ra) # 80000dc2 <release>
}
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	60e2                	ld	ra,24(sp)
    80001cb8:	6442                	ld	s0,16(sp)
    80001cba:	64a2                	ld	s1,8(sp)
    80001cbc:	6902                	ld	s2,0(sp)
    80001cbe:	6105                	addi	sp,sp,32
    80001cc0:	8082                	ret

0000000080001cc2 <proc_pagetable>:
{
    80001cc2:	1101                	addi	sp,sp,-32
    80001cc4:	ec06                	sd	ra,24(sp)
    80001cc6:	e822                	sd	s0,16(sp)
    80001cc8:	e426                	sd	s1,8(sp)
    80001cca:	e04a                	sd	s2,0(sp)
    80001ccc:	1000                	addi	s0,sp,32
    80001cce:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	7c8080e7          	jalr	1992(ra) # 80001498 <uvmcreate>
    80001cd8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001cda:	c121                	beqz	a0,80001d1a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cdc:	4729                	li	a4,10
    80001cde:	00005697          	auipc	a3,0x5
    80001ce2:	32268693          	addi	a3,a3,802 # 80007000 <_trampoline>
    80001ce6:	6605                	lui	a2,0x1
    80001ce8:	040005b7          	lui	a1,0x4000
    80001cec:	15fd                	addi	a1,a1,-1
    80001cee:	05b2                	slli	a1,a1,0xc
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	54c080e7          	jalr	1356(ra) # 8000123c <mappages>
    80001cf8:	02054863          	bltz	a0,80001d28 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cfc:	4719                	li	a4,6
    80001cfe:	05893683          	ld	a3,88(s2)
    80001d02:	6605                	lui	a2,0x1
    80001d04:	020005b7          	lui	a1,0x2000
    80001d08:	15fd                	addi	a1,a1,-1
    80001d0a:	05b6                	slli	a1,a1,0xd
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	52e080e7          	jalr	1326(ra) # 8000123c <mappages>
    80001d16:	02054163          	bltz	a0,80001d38 <proc_pagetable+0x76>
}
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	60e2                	ld	ra,24(sp)
    80001d1e:	6442                	ld	s0,16(sp)
    80001d20:	64a2                	ld	s1,8(sp)
    80001d22:	6902                	ld	s2,0(sp)
    80001d24:	6105                	addi	sp,sp,32
    80001d26:	8082                	ret
    uvmfree(pagetable, 0);
    80001d28:	4581                	li	a1,0
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	00000097          	auipc	ra,0x0
    80001d30:	968080e7          	jalr	-1688(ra) # 80001694 <uvmfree>
    return 0;
    80001d34:	4481                	li	s1,0
    80001d36:	b7d5                	j	80001d1a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d38:	4681                	li	a3,0
    80001d3a:	4605                	li	a2,1
    80001d3c:	040005b7          	lui	a1,0x4000
    80001d40:	15fd                	addi	a1,a1,-1
    80001d42:	05b2                	slli	a1,a1,0xc
    80001d44:	8526                	mv	a0,s1
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	68e080e7          	jalr	1678(ra) # 800013d4 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d4e:	4581                	li	a1,0
    80001d50:	8526                	mv	a0,s1
    80001d52:	00000097          	auipc	ra,0x0
    80001d56:	942080e7          	jalr	-1726(ra) # 80001694 <uvmfree>
    return 0;
    80001d5a:	4481                	li	s1,0
    80001d5c:	bf7d                	j	80001d1a <proc_pagetable+0x58>

0000000080001d5e <proc_freepagetable>:
{
    80001d5e:	1101                	addi	sp,sp,-32
    80001d60:	ec06                	sd	ra,24(sp)
    80001d62:	e822                	sd	s0,16(sp)
    80001d64:	e426                	sd	s1,8(sp)
    80001d66:	e04a                	sd	s2,0(sp)
    80001d68:	1000                	addi	s0,sp,32
    80001d6a:	84aa                	mv	s1,a0
    80001d6c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d6e:	4681                	li	a3,0
    80001d70:	4605                	li	a2,1
    80001d72:	040005b7          	lui	a1,0x4000
    80001d76:	15fd                	addi	a1,a1,-1
    80001d78:	05b2                	slli	a1,a1,0xc
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	65a080e7          	jalr	1626(ra) # 800013d4 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d82:	4681                	li	a3,0
    80001d84:	4605                	li	a2,1
    80001d86:	020005b7          	lui	a1,0x2000
    80001d8a:	15fd                	addi	a1,a1,-1
    80001d8c:	05b6                	slli	a1,a1,0xd
    80001d8e:	8526                	mv	a0,s1
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	644080e7          	jalr	1604(ra) # 800013d4 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d98:	85ca                	mv	a1,s2
    80001d9a:	8526                	mv	a0,s1
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	8f8080e7          	jalr	-1800(ra) # 80001694 <uvmfree>
}
    80001da4:	60e2                	ld	ra,24(sp)
    80001da6:	6442                	ld	s0,16(sp)
    80001da8:	64a2                	ld	s1,8(sp)
    80001daa:	6902                	ld	s2,0(sp)
    80001dac:	6105                	addi	sp,sp,32
    80001dae:	8082                	ret

0000000080001db0 <freeproc>:
{
    80001db0:	1101                	addi	sp,sp,-32
    80001db2:	ec06                	sd	ra,24(sp)
    80001db4:	e822                	sd	s0,16(sp)
    80001db6:	e426                	sd	s1,8(sp)
    80001db8:	1000                	addi	s0,sp,32
    80001dba:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001dbc:	6d28                	ld	a0,88(a0)
    80001dbe:	c509                	beqz	a0,80001dc8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	c64080e7          	jalr	-924(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001dc8:	0404bc23          	sd	zero,88(s1) # fffffffffffff058 <end+0xffffffff7fdb9058>
  if(p->pagetable)
    80001dcc:	68a8                	ld	a0,80(s1)
    80001dce:	c511                	beqz	a0,80001dda <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001dd0:	64ac                	ld	a1,72(s1)
    80001dd2:	00000097          	auipc	ra,0x0
    80001dd6:	f8c080e7          	jalr	-116(ra) # 80001d5e <proc_freepagetable>
  p->pagetable = 0;
    80001dda:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001dde:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001de2:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001de6:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001dea:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001dee:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001df2:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001df6:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001dfa:	0004ac23          	sw	zero,24(s1)
}
    80001dfe:	60e2                	ld	ra,24(sp)
    80001e00:	6442                	ld	s0,16(sp)
    80001e02:	64a2                	ld	s1,8(sp)
    80001e04:	6105                	addi	sp,sp,32
    80001e06:	8082                	ret

0000000080001e08 <allocproc>:
{
    80001e08:	1101                	addi	sp,sp,-32
    80001e0a:	ec06                	sd	ra,24(sp)
    80001e0c:	e822                	sd	s0,16(sp)
    80001e0e:	e426                	sd	s1,8(sp)
    80001e10:	e04a                	sd	s2,0(sp)
    80001e12:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e14:	00230497          	auipc	s1,0x230
    80001e18:	f5448493          	addi	s1,s1,-172 # 80231d68 <proc>
    80001e1c:	00236917          	auipc	s2,0x236
    80001e20:	94c90913          	addi	s2,s2,-1716 # 80237768 <tickslock>
    acquire(&p->lock);
    80001e24:	8526                	mv	a0,s1
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	ee8080e7          	jalr	-280(ra) # 80000d0e <acquire>
    if(p->state == UNUSED) {
    80001e2e:	4c9c                	lw	a5,24(s1)
    80001e30:	cf81                	beqz	a5,80001e48 <allocproc+0x40>
      release(&p->lock);
    80001e32:	8526                	mv	a0,s1
    80001e34:	fffff097          	auipc	ra,0xfffff
    80001e38:	f8e080e7          	jalr	-114(ra) # 80000dc2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e3c:	16848493          	addi	s1,s1,360
    80001e40:	ff2492e3          	bne	s1,s2,80001e24 <allocproc+0x1c>
  return 0;
    80001e44:	4481                	li	s1,0
    80001e46:	a0b9                	j	80001e94 <allocproc+0x8c>
  p->pid = allocpid();
    80001e48:	00000097          	auipc	ra,0x0
    80001e4c:	e34080e7          	jalr	-460(ra) # 80001c7c <allocpid>
    80001e50:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	d2a080e7          	jalr	-726(ra) # 80000b7c <kalloc>
    80001e5a:	892a                	mv	s2,a0
    80001e5c:	eca8                	sd	a0,88(s1)
    80001e5e:	c131                	beqz	a0,80001ea2 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001e60:	8526                	mv	a0,s1
    80001e62:	00000097          	auipc	ra,0x0
    80001e66:	e60080e7          	jalr	-416(ra) # 80001cc2 <proc_pagetable>
    80001e6a:	892a                	mv	s2,a0
    80001e6c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e6e:	c129                	beqz	a0,80001eb0 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001e70:	07000613          	li	a2,112
    80001e74:	4581                	li	a1,0
    80001e76:	06048513          	addi	a0,s1,96
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	f90080e7          	jalr	-112(ra) # 80000e0a <memset>
  p->context.ra = (uint64)forkret;
    80001e82:	00000797          	auipc	a5,0x0
    80001e86:	db478793          	addi	a5,a5,-588 # 80001c36 <forkret>
    80001e8a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e8c:	60bc                	ld	a5,64(s1)
    80001e8e:	6705                	lui	a4,0x1
    80001e90:	97ba                	add	a5,a5,a4
    80001e92:	f4bc                	sd	a5,104(s1)
}
    80001e94:	8526                	mv	a0,s1
    80001e96:	60e2                	ld	ra,24(sp)
    80001e98:	6442                	ld	s0,16(sp)
    80001e9a:	64a2                	ld	s1,8(sp)
    80001e9c:	6902                	ld	s2,0(sp)
    80001e9e:	6105                	addi	sp,sp,32
    80001ea0:	8082                	ret
    release(&p->lock);
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	f1e080e7          	jalr	-226(ra) # 80000dc2 <release>
    return 0;
    80001eac:	84ca                	mv	s1,s2
    80001eae:	b7dd                	j	80001e94 <allocproc+0x8c>
    freeproc(p);
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	00000097          	auipc	ra,0x0
    80001eb6:	efe080e7          	jalr	-258(ra) # 80001db0 <freeproc>
    release(&p->lock);
    80001eba:	8526                	mv	a0,s1
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	f06080e7          	jalr	-250(ra) # 80000dc2 <release>
    return 0;
    80001ec4:	84ca                	mv	s1,s2
    80001ec6:	b7f9                	j	80001e94 <allocproc+0x8c>

0000000080001ec8 <userinit>:
{
    80001ec8:	1101                	addi	sp,sp,-32
    80001eca:	ec06                	sd	ra,24(sp)
    80001ecc:	e822                	sd	s0,16(sp)
    80001ece:	e426                	sd	s1,8(sp)
    80001ed0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	f36080e7          	jalr	-202(ra) # 80001e08 <allocproc>
    80001eda:	84aa                	mv	s1,a0
  initproc = p;
    80001edc:	00007797          	auipc	a5,0x7
    80001ee0:	12a7be23          	sd	a0,316(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ee4:	03400613          	li	a2,52
    80001ee8:	00007597          	auipc	a1,0x7
    80001eec:	a2858593          	addi	a1,a1,-1496 # 80008910 <initcode>
    80001ef0:	6928                	ld	a0,80(a0)
    80001ef2:	fffff097          	auipc	ra,0xfffff
    80001ef6:	5d4080e7          	jalr	1492(ra) # 800014c6 <uvminit>
  p->sz = PGSIZE;
    80001efa:	6785                	lui	a5,0x1
    80001efc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001efe:	6cb8                	ld	a4,88(s1)
    80001f00:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f04:	6cb8                	ld	a4,88(s1)
    80001f06:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f08:	4641                	li	a2,16
    80001f0a:	00006597          	auipc	a1,0x6
    80001f0e:	3c658593          	addi	a1,a1,966 # 800082d0 <digits+0x290>
    80001f12:	15848513          	addi	a0,s1,344
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	04a080e7          	jalr	74(ra) # 80000f60 <safestrcpy>
  p->cwd = namei("/");
    80001f1e:	00006517          	auipc	a0,0x6
    80001f22:	3c250513          	addi	a0,a0,962 # 800082e0 <digits+0x2a0>
    80001f26:	00002097          	auipc	ra,0x2
    80001f2a:	0e0080e7          	jalr	224(ra) # 80004006 <namei>
    80001f2e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f32:	4789                	li	a5,2
    80001f34:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f36:	8526                	mv	a0,s1
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	e8a080e7          	jalr	-374(ra) # 80000dc2 <release>
}
    80001f40:	60e2                	ld	ra,24(sp)
    80001f42:	6442                	ld	s0,16(sp)
    80001f44:	64a2                	ld	s1,8(sp)
    80001f46:	6105                	addi	sp,sp,32
    80001f48:	8082                	ret

0000000080001f4a <growproc>:
{
    80001f4a:	1101                	addi	sp,sp,-32
    80001f4c:	ec06                	sd	ra,24(sp)
    80001f4e:	e822                	sd	s0,16(sp)
    80001f50:	e426                	sd	s1,8(sp)
    80001f52:	e04a                	sd	s2,0(sp)
    80001f54:	1000                	addi	s0,sp,32
    80001f56:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001f58:	00000097          	auipc	ra,0x0
    80001f5c:	ca6080e7          	jalr	-858(ra) # 80001bfe <myproc>
    80001f60:	892a                	mv	s2,a0
  sz = p->sz;
    80001f62:	652c                	ld	a1,72(a0)
    80001f64:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001f68:	00904f63          	bgtz	s1,80001f86 <growproc+0x3c>
  } else if(n < 0){
    80001f6c:	0204cc63          	bltz	s1,80001fa4 <growproc+0x5a>
  p->sz = sz;
    80001f70:	1602                	slli	a2,a2,0x20
    80001f72:	9201                	srli	a2,a2,0x20
    80001f74:	04c93423          	sd	a2,72(s2)
  return 0;
    80001f78:	4501                	li	a0,0
}
    80001f7a:	60e2                	ld	ra,24(sp)
    80001f7c:	6442                	ld	s0,16(sp)
    80001f7e:	64a2                	ld	s1,8(sp)
    80001f80:	6902                	ld	s2,0(sp)
    80001f82:	6105                	addi	sp,sp,32
    80001f84:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f86:	9e25                	addw	a2,a2,s1
    80001f88:	1602                	slli	a2,a2,0x20
    80001f8a:	9201                	srli	a2,a2,0x20
    80001f8c:	1582                	slli	a1,a1,0x20
    80001f8e:	9181                	srli	a1,a1,0x20
    80001f90:	6928                	ld	a0,80(a0)
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	5ee080e7          	jalr	1518(ra) # 80001580 <uvmalloc>
    80001f9a:	0005061b          	sext.w	a2,a0
    80001f9e:	fa69                	bnez	a2,80001f70 <growproc+0x26>
      return -1;
    80001fa0:	557d                	li	a0,-1
    80001fa2:	bfe1                	j	80001f7a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fa4:	9e25                	addw	a2,a2,s1
    80001fa6:	1602                	slli	a2,a2,0x20
    80001fa8:	9201                	srli	a2,a2,0x20
    80001faa:	1582                	slli	a1,a1,0x20
    80001fac:	9181                	srli	a1,a1,0x20
    80001fae:	6928                	ld	a0,80(a0)
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	588080e7          	jalr	1416(ra) # 80001538 <uvmdealloc>
    80001fb8:	0005061b          	sext.w	a2,a0
    80001fbc:	bf55                	j	80001f70 <growproc+0x26>

0000000080001fbe <fork>:
{
    80001fbe:	7179                	addi	sp,sp,-48
    80001fc0:	f406                	sd	ra,40(sp)
    80001fc2:	f022                	sd	s0,32(sp)
    80001fc4:	ec26                	sd	s1,24(sp)
    80001fc6:	e84a                	sd	s2,16(sp)
    80001fc8:	e44e                	sd	s3,8(sp)
    80001fca:	e052                	sd	s4,0(sp)
    80001fcc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fce:	00000097          	auipc	ra,0x0
    80001fd2:	c30080e7          	jalr	-976(ra) # 80001bfe <myproc>
    80001fd6:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001fd8:	00000097          	auipc	ra,0x0
    80001fdc:	e30080e7          	jalr	-464(ra) # 80001e08 <allocproc>
    80001fe0:	c175                	beqz	a0,800020c4 <fork+0x106>
    80001fe2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001fe4:	04893603          	ld	a2,72(s2)
    80001fe8:	692c                	ld	a1,80(a0)
    80001fea:	05093503          	ld	a0,80(s2)
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	6de080e7          	jalr	1758(ra) # 800016cc <uvmcopy>
    80001ff6:	04054863          	bltz	a0,80002046 <fork+0x88>
  np->sz = p->sz;
    80001ffa:	04893783          	ld	a5,72(s2)
    80001ffe:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80002002:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80002006:	05893683          	ld	a3,88(s2)
    8000200a:	87b6                	mv	a5,a3
    8000200c:	0589b703          	ld	a4,88(s3)
    80002010:	12068693          	addi	a3,a3,288
    80002014:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002018:	6788                	ld	a0,8(a5)
    8000201a:	6b8c                	ld	a1,16(a5)
    8000201c:	6f90                	ld	a2,24(a5)
    8000201e:	01073023          	sd	a6,0(a4)
    80002022:	e708                	sd	a0,8(a4)
    80002024:	eb0c                	sd	a1,16(a4)
    80002026:	ef10                	sd	a2,24(a4)
    80002028:	02078793          	addi	a5,a5,32
    8000202c:	02070713          	addi	a4,a4,32
    80002030:	fed792e3          	bne	a5,a3,80002014 <fork+0x56>
  np->trapframe->a0 = 0;
    80002034:	0589b783          	ld	a5,88(s3)
    80002038:	0607b823          	sd	zero,112(a5)
    8000203c:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002040:	15000a13          	li	s4,336
    80002044:	a03d                	j	80002072 <fork+0xb4>
    freeproc(np);
    80002046:	854e                	mv	a0,s3
    80002048:	00000097          	auipc	ra,0x0
    8000204c:	d68080e7          	jalr	-664(ra) # 80001db0 <freeproc>
    release(&np->lock);
    80002050:	854e                	mv	a0,s3
    80002052:	fffff097          	auipc	ra,0xfffff
    80002056:	d70080e7          	jalr	-656(ra) # 80000dc2 <release>
    return -1;
    8000205a:	54fd                	li	s1,-1
    8000205c:	a899                	j	800020b2 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    8000205e:	00002097          	auipc	ra,0x2
    80002062:	634080e7          	jalr	1588(ra) # 80004692 <filedup>
    80002066:	009987b3          	add	a5,s3,s1
    8000206a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    8000206c:	04a1                	addi	s1,s1,8
    8000206e:	01448763          	beq	s1,s4,8000207c <fork+0xbe>
    if(p->ofile[i])
    80002072:	009907b3          	add	a5,s2,s1
    80002076:	6388                	ld	a0,0(a5)
    80002078:	f17d                	bnez	a0,8000205e <fork+0xa0>
    8000207a:	bfcd                	j	8000206c <fork+0xae>
  np->cwd = idup(p->cwd);
    8000207c:	15093503          	ld	a0,336(s2)
    80002080:	00001097          	auipc	ra,0x1
    80002084:	794080e7          	jalr	1940(ra) # 80003814 <idup>
    80002088:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000208c:	4641                	li	a2,16
    8000208e:	15890593          	addi	a1,s2,344
    80002092:	15898513          	addi	a0,s3,344
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	eca080e7          	jalr	-310(ra) # 80000f60 <safestrcpy>
  pid = np->pid;
    8000209e:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    800020a2:	4789                	li	a5,2
    800020a4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800020a8:	854e                	mv	a0,s3
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	d18080e7          	jalr	-744(ra) # 80000dc2 <release>
}
    800020b2:	8526                	mv	a0,s1
    800020b4:	70a2                	ld	ra,40(sp)
    800020b6:	7402                	ld	s0,32(sp)
    800020b8:	64e2                	ld	s1,24(sp)
    800020ba:	6942                	ld	s2,16(sp)
    800020bc:	69a2                	ld	s3,8(sp)
    800020be:	6a02                	ld	s4,0(sp)
    800020c0:	6145                	addi	sp,sp,48
    800020c2:	8082                	ret
    return -1;
    800020c4:	54fd                	li	s1,-1
    800020c6:	b7f5                	j	800020b2 <fork+0xf4>

00000000800020c8 <reparent>:
{
    800020c8:	7179                	addi	sp,sp,-48
    800020ca:	f406                	sd	ra,40(sp)
    800020cc:	f022                	sd	s0,32(sp)
    800020ce:	ec26                	sd	s1,24(sp)
    800020d0:	e84a                	sd	s2,16(sp)
    800020d2:	e44e                	sd	s3,8(sp)
    800020d4:	e052                	sd	s4,0(sp)
    800020d6:	1800                	addi	s0,sp,48
    800020d8:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020da:	00230497          	auipc	s1,0x230
    800020de:	c8e48493          	addi	s1,s1,-882 # 80231d68 <proc>
      pp->parent = initproc;
    800020e2:	00007a17          	auipc	s4,0x7
    800020e6:	f36a0a13          	addi	s4,s4,-202 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020ea:	00235997          	auipc	s3,0x235
    800020ee:	67e98993          	addi	s3,s3,1662 # 80237768 <tickslock>
    800020f2:	a029                	j	800020fc <reparent+0x34>
    800020f4:	16848493          	addi	s1,s1,360
    800020f8:	03348363          	beq	s1,s3,8000211e <reparent+0x56>
    if(pp->parent == p){
    800020fc:	709c                	ld	a5,32(s1)
    800020fe:	ff279be3          	bne	a5,s2,800020f4 <reparent+0x2c>
      acquire(&pp->lock);
    80002102:	8526                	mv	a0,s1
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	c0a080e7          	jalr	-1014(ra) # 80000d0e <acquire>
      pp->parent = initproc;
    8000210c:	000a3783          	ld	a5,0(s4)
    80002110:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002112:	8526                	mv	a0,s1
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	cae080e7          	jalr	-850(ra) # 80000dc2 <release>
    8000211c:	bfe1                	j	800020f4 <reparent+0x2c>
}
    8000211e:	70a2                	ld	ra,40(sp)
    80002120:	7402                	ld	s0,32(sp)
    80002122:	64e2                	ld	s1,24(sp)
    80002124:	6942                	ld	s2,16(sp)
    80002126:	69a2                	ld	s3,8(sp)
    80002128:	6a02                	ld	s4,0(sp)
    8000212a:	6145                	addi	sp,sp,48
    8000212c:	8082                	ret

000000008000212e <scheduler>:
{
    8000212e:	711d                	addi	sp,sp,-96
    80002130:	ec86                	sd	ra,88(sp)
    80002132:	e8a2                	sd	s0,80(sp)
    80002134:	e4a6                	sd	s1,72(sp)
    80002136:	e0ca                	sd	s2,64(sp)
    80002138:	fc4e                	sd	s3,56(sp)
    8000213a:	f852                	sd	s4,48(sp)
    8000213c:	f456                	sd	s5,40(sp)
    8000213e:	f05a                	sd	s6,32(sp)
    80002140:	ec5e                	sd	s7,24(sp)
    80002142:	e862                	sd	s8,16(sp)
    80002144:	e466                	sd	s9,8(sp)
    80002146:	1080                	addi	s0,sp,96
    80002148:	8792                	mv	a5,tp
  int id = r_tp();
    8000214a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000214c:	00779c13          	slli	s8,a5,0x7
    80002150:	00230717          	auipc	a4,0x230
    80002154:	80070713          	addi	a4,a4,-2048 # 80231950 <pid_lock>
    80002158:	9762                	add	a4,a4,s8
    8000215a:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    8000215e:	00230717          	auipc	a4,0x230
    80002162:	81270713          	addi	a4,a4,-2030 # 80231970 <cpus+0x8>
    80002166:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80002168:	4a89                	li	s5,2
        c->proc = p;
    8000216a:	079e                	slli	a5,a5,0x7
    8000216c:	0022fb17          	auipc	s6,0x22f
    80002170:	7e4b0b13          	addi	s6,s6,2020 # 80231950 <pid_lock>
    80002174:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002176:	00235a17          	auipc	s4,0x235
    8000217a:	5f2a0a13          	addi	s4,s4,1522 # 80237768 <tickslock>
    int nproc = 0;
    8000217e:	4c81                	li	s9,0
    80002180:	a8a1                	j	800021d8 <scheduler+0xaa>
        p->state = RUNNING;
    80002182:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80002186:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    8000218a:	06048593          	addi	a1,s1,96
    8000218e:	8562                	mv	a0,s8
    80002190:	00000097          	auipc	ra,0x0
    80002194:	63a080e7          	jalr	1594(ra) # 800027ca <swtch>
        c->proc = 0;
    80002198:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    8000219c:	8526                	mv	a0,s1
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	c24080e7          	jalr	-988(ra) # 80000dc2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800021a6:	16848493          	addi	s1,s1,360
    800021aa:	01448d63          	beq	s1,s4,800021c4 <scheduler+0x96>
      acquire(&p->lock);
    800021ae:	8526                	mv	a0,s1
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	b5e080e7          	jalr	-1186(ra) # 80000d0e <acquire>
      if(p->state != UNUSED) {
    800021b8:	4c9c                	lw	a5,24(s1)
    800021ba:	d3ed                	beqz	a5,8000219c <scheduler+0x6e>
        nproc++;
    800021bc:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    800021be:	fd579fe3          	bne	a5,s5,8000219c <scheduler+0x6e>
    800021c2:	b7c1                	j	80002182 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    800021c4:	013aca63          	blt	s5,s3,800021d8 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021c8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021cc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021d0:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800021d4:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021d8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021dc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021e0:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    800021e4:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    800021e6:	00230497          	auipc	s1,0x230
    800021ea:	b8248493          	addi	s1,s1,-1150 # 80231d68 <proc>
        p->state = RUNNING;
    800021ee:	4b8d                	li	s7,3
    800021f0:	bf7d                	j	800021ae <scheduler+0x80>

00000000800021f2 <sched>:
{
    800021f2:	7179                	addi	sp,sp,-48
    800021f4:	f406                	sd	ra,40(sp)
    800021f6:	f022                	sd	s0,32(sp)
    800021f8:	ec26                	sd	s1,24(sp)
    800021fa:	e84a                	sd	s2,16(sp)
    800021fc:	e44e                	sd	s3,8(sp)
    800021fe:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002200:	00000097          	auipc	ra,0x0
    80002204:	9fe080e7          	jalr	-1538(ra) # 80001bfe <myproc>
    80002208:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	a8a080e7          	jalr	-1398(ra) # 80000c94 <holding>
    80002212:	c93d                	beqz	a0,80002288 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002214:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002216:	2781                	sext.w	a5,a5
    80002218:	079e                	slli	a5,a5,0x7
    8000221a:	0022f717          	auipc	a4,0x22f
    8000221e:	73670713          	addi	a4,a4,1846 # 80231950 <pid_lock>
    80002222:	97ba                	add	a5,a5,a4
    80002224:	0907a703          	lw	a4,144(a5)
    80002228:	4785                	li	a5,1
    8000222a:	06f71763          	bne	a4,a5,80002298 <sched+0xa6>
  if(p->state == RUNNING)
    8000222e:	4c98                	lw	a4,24(s1)
    80002230:	478d                	li	a5,3
    80002232:	06f70b63          	beq	a4,a5,800022a8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002236:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000223a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000223c:	efb5                	bnez	a5,800022b8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000223e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002240:	0022f917          	auipc	s2,0x22f
    80002244:	71090913          	addi	s2,s2,1808 # 80231950 <pid_lock>
    80002248:	2781                	sext.w	a5,a5
    8000224a:	079e                	slli	a5,a5,0x7
    8000224c:	97ca                	add	a5,a5,s2
    8000224e:	0947a983          	lw	s3,148(a5)
    80002252:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002254:	2781                	sext.w	a5,a5
    80002256:	079e                	slli	a5,a5,0x7
    80002258:	0022f597          	auipc	a1,0x22f
    8000225c:	71858593          	addi	a1,a1,1816 # 80231970 <cpus+0x8>
    80002260:	95be                	add	a1,a1,a5
    80002262:	06048513          	addi	a0,s1,96
    80002266:	00000097          	auipc	ra,0x0
    8000226a:	564080e7          	jalr	1380(ra) # 800027ca <swtch>
    8000226e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002270:	2781                	sext.w	a5,a5
    80002272:	079e                	slli	a5,a5,0x7
    80002274:	97ca                	add	a5,a5,s2
    80002276:	0937aa23          	sw	s3,148(a5)
}
    8000227a:	70a2                	ld	ra,40(sp)
    8000227c:	7402                	ld	s0,32(sp)
    8000227e:	64e2                	ld	s1,24(sp)
    80002280:	6942                	ld	s2,16(sp)
    80002282:	69a2                	ld	s3,8(sp)
    80002284:	6145                	addi	sp,sp,48
    80002286:	8082                	ret
    panic("sched p->lock");
    80002288:	00006517          	auipc	a0,0x6
    8000228c:	06050513          	addi	a0,a0,96 # 800082e8 <digits+0x2a8>
    80002290:	ffffe097          	auipc	ra,0xffffe
    80002294:	2b8080e7          	jalr	696(ra) # 80000548 <panic>
    panic("sched locks");
    80002298:	00006517          	auipc	a0,0x6
    8000229c:	06050513          	addi	a0,a0,96 # 800082f8 <digits+0x2b8>
    800022a0:	ffffe097          	auipc	ra,0xffffe
    800022a4:	2a8080e7          	jalr	680(ra) # 80000548 <panic>
    panic("sched running");
    800022a8:	00006517          	auipc	a0,0x6
    800022ac:	06050513          	addi	a0,a0,96 # 80008308 <digits+0x2c8>
    800022b0:	ffffe097          	auipc	ra,0xffffe
    800022b4:	298080e7          	jalr	664(ra) # 80000548 <panic>
    panic("sched interruptible");
    800022b8:	00006517          	auipc	a0,0x6
    800022bc:	06050513          	addi	a0,a0,96 # 80008318 <digits+0x2d8>
    800022c0:	ffffe097          	auipc	ra,0xffffe
    800022c4:	288080e7          	jalr	648(ra) # 80000548 <panic>

00000000800022c8 <exit>:
{
    800022c8:	7179                	addi	sp,sp,-48
    800022ca:	f406                	sd	ra,40(sp)
    800022cc:	f022                	sd	s0,32(sp)
    800022ce:	ec26                	sd	s1,24(sp)
    800022d0:	e84a                	sd	s2,16(sp)
    800022d2:	e44e                	sd	s3,8(sp)
    800022d4:	e052                	sd	s4,0(sp)
    800022d6:	1800                	addi	s0,sp,48
    800022d8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022da:	00000097          	auipc	ra,0x0
    800022de:	924080e7          	jalr	-1756(ra) # 80001bfe <myproc>
    800022e2:	89aa                	mv	s3,a0
  if(p == initproc)
    800022e4:	00007797          	auipc	a5,0x7
    800022e8:	d347b783          	ld	a5,-716(a5) # 80009018 <initproc>
    800022ec:	0d050493          	addi	s1,a0,208
    800022f0:	15050913          	addi	s2,a0,336
    800022f4:	02a79363          	bne	a5,a0,8000231a <exit+0x52>
    panic("init exiting");
    800022f8:	00006517          	auipc	a0,0x6
    800022fc:	03850513          	addi	a0,a0,56 # 80008330 <digits+0x2f0>
    80002300:	ffffe097          	auipc	ra,0xffffe
    80002304:	248080e7          	jalr	584(ra) # 80000548 <panic>
      fileclose(f);
    80002308:	00002097          	auipc	ra,0x2
    8000230c:	3dc080e7          	jalr	988(ra) # 800046e4 <fileclose>
      p->ofile[fd] = 0;
    80002310:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002314:	04a1                	addi	s1,s1,8
    80002316:	01248563          	beq	s1,s2,80002320 <exit+0x58>
    if(p->ofile[fd]){
    8000231a:	6088                	ld	a0,0(s1)
    8000231c:	f575                	bnez	a0,80002308 <exit+0x40>
    8000231e:	bfdd                	j	80002314 <exit+0x4c>
  begin_op();
    80002320:	00002097          	auipc	ra,0x2
    80002324:	ef2080e7          	jalr	-270(ra) # 80004212 <begin_op>
  iput(p->cwd);
    80002328:	1509b503          	ld	a0,336(s3)
    8000232c:	00001097          	auipc	ra,0x1
    80002330:	6e0080e7          	jalr	1760(ra) # 80003a0c <iput>
  end_op();
    80002334:	00002097          	auipc	ra,0x2
    80002338:	f5e080e7          	jalr	-162(ra) # 80004292 <end_op>
  p->cwd = 0;
    8000233c:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002340:	00007497          	auipc	s1,0x7
    80002344:	cd848493          	addi	s1,s1,-808 # 80009018 <initproc>
    80002348:	6088                	ld	a0,0(s1)
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	9c4080e7          	jalr	-1596(ra) # 80000d0e <acquire>
  wakeup1(initproc);
    80002352:	6088                	ld	a0,0(s1)
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	76a080e7          	jalr	1898(ra) # 80001abe <wakeup1>
  release(&initproc->lock);
    8000235c:	6088                	ld	a0,0(s1)
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	a64080e7          	jalr	-1436(ra) # 80000dc2 <release>
  acquire(&p->lock);
    80002366:	854e                	mv	a0,s3
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	9a6080e7          	jalr	-1626(ra) # 80000d0e <acquire>
  struct proc *original_parent = p->parent;
    80002370:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002374:	854e                	mv	a0,s3
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	a4c080e7          	jalr	-1460(ra) # 80000dc2 <release>
  acquire(&original_parent->lock);
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	98e080e7          	jalr	-1650(ra) # 80000d0e <acquire>
  acquire(&p->lock);
    80002388:	854e                	mv	a0,s3
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	984080e7          	jalr	-1660(ra) # 80000d0e <acquire>
  reparent(p);
    80002392:	854e                	mv	a0,s3
    80002394:	00000097          	auipc	ra,0x0
    80002398:	d34080e7          	jalr	-716(ra) # 800020c8 <reparent>
  wakeup1(original_parent);
    8000239c:	8526                	mv	a0,s1
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	720080e7          	jalr	1824(ra) # 80001abe <wakeup1>
  p->xstate = status;
    800023a6:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800023aa:	4791                	li	a5,4
    800023ac:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	a10080e7          	jalr	-1520(ra) # 80000dc2 <release>
  sched();
    800023ba:	00000097          	auipc	ra,0x0
    800023be:	e38080e7          	jalr	-456(ra) # 800021f2 <sched>
  panic("zombie exit");
    800023c2:	00006517          	auipc	a0,0x6
    800023c6:	f7e50513          	addi	a0,a0,-130 # 80008340 <digits+0x300>
    800023ca:	ffffe097          	auipc	ra,0xffffe
    800023ce:	17e080e7          	jalr	382(ra) # 80000548 <panic>

00000000800023d2 <yield>:
{
    800023d2:	1101                	addi	sp,sp,-32
    800023d4:	ec06                	sd	ra,24(sp)
    800023d6:	e822                	sd	s0,16(sp)
    800023d8:	e426                	sd	s1,8(sp)
    800023da:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023dc:	00000097          	auipc	ra,0x0
    800023e0:	822080e7          	jalr	-2014(ra) # 80001bfe <myproc>
    800023e4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	928080e7          	jalr	-1752(ra) # 80000d0e <acquire>
  p->state = RUNNABLE;
    800023ee:	4789                	li	a5,2
    800023f0:	cc9c                	sw	a5,24(s1)
  sched();
    800023f2:	00000097          	auipc	ra,0x0
    800023f6:	e00080e7          	jalr	-512(ra) # 800021f2 <sched>
  release(&p->lock);
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	9c6080e7          	jalr	-1594(ra) # 80000dc2 <release>
}
    80002404:	60e2                	ld	ra,24(sp)
    80002406:	6442                	ld	s0,16(sp)
    80002408:	64a2                	ld	s1,8(sp)
    8000240a:	6105                	addi	sp,sp,32
    8000240c:	8082                	ret

000000008000240e <sleep>:
{
    8000240e:	7179                	addi	sp,sp,-48
    80002410:	f406                	sd	ra,40(sp)
    80002412:	f022                	sd	s0,32(sp)
    80002414:	ec26                	sd	s1,24(sp)
    80002416:	e84a                	sd	s2,16(sp)
    80002418:	e44e                	sd	s3,8(sp)
    8000241a:	1800                	addi	s0,sp,48
    8000241c:	89aa                	mv	s3,a0
    8000241e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	7de080e7          	jalr	2014(ra) # 80001bfe <myproc>
    80002428:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000242a:	05250663          	beq	a0,s2,80002476 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	8e0080e7          	jalr	-1824(ra) # 80000d0e <acquire>
    release(lk);
    80002436:	854a                	mv	a0,s2
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	98a080e7          	jalr	-1654(ra) # 80000dc2 <release>
  p->chan = chan;
    80002440:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002444:	4785                	li	a5,1
    80002446:	cc9c                	sw	a5,24(s1)
  sched();
    80002448:	00000097          	auipc	ra,0x0
    8000244c:	daa080e7          	jalr	-598(ra) # 800021f2 <sched>
  p->chan = 0;
    80002450:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002454:	8526                	mv	a0,s1
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	96c080e7          	jalr	-1684(ra) # 80000dc2 <release>
    acquire(lk);
    8000245e:	854a                	mv	a0,s2
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	8ae080e7          	jalr	-1874(ra) # 80000d0e <acquire>
}
    80002468:	70a2                	ld	ra,40(sp)
    8000246a:	7402                	ld	s0,32(sp)
    8000246c:	64e2                	ld	s1,24(sp)
    8000246e:	6942                	ld	s2,16(sp)
    80002470:	69a2                	ld	s3,8(sp)
    80002472:	6145                	addi	sp,sp,48
    80002474:	8082                	ret
  p->chan = chan;
    80002476:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000247a:	4785                	li	a5,1
    8000247c:	cd1c                	sw	a5,24(a0)
  sched();
    8000247e:	00000097          	auipc	ra,0x0
    80002482:	d74080e7          	jalr	-652(ra) # 800021f2 <sched>
  p->chan = 0;
    80002486:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000248a:	bff9                	j	80002468 <sleep+0x5a>

000000008000248c <wait>:
{
    8000248c:	715d                	addi	sp,sp,-80
    8000248e:	e486                	sd	ra,72(sp)
    80002490:	e0a2                	sd	s0,64(sp)
    80002492:	fc26                	sd	s1,56(sp)
    80002494:	f84a                	sd	s2,48(sp)
    80002496:	f44e                	sd	s3,40(sp)
    80002498:	f052                	sd	s4,32(sp)
    8000249a:	ec56                	sd	s5,24(sp)
    8000249c:	e85a                	sd	s6,16(sp)
    8000249e:	e45e                	sd	s7,8(sp)
    800024a0:	e062                	sd	s8,0(sp)
    800024a2:	0880                	addi	s0,sp,80
    800024a4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	758080e7          	jalr	1880(ra) # 80001bfe <myproc>
    800024ae:	892a                	mv	s2,a0
  acquire(&p->lock);
    800024b0:	8c2a                	mv	s8,a0
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	85c080e7          	jalr	-1956(ra) # 80000d0e <acquire>
    havekids = 0;
    800024ba:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800024bc:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800024be:	00235997          	auipc	s3,0x235
    800024c2:	2aa98993          	addi	s3,s3,682 # 80237768 <tickslock>
        havekids = 1;
    800024c6:	4a85                	li	s5,1
    havekids = 0;
    800024c8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800024ca:	00230497          	auipc	s1,0x230
    800024ce:	89e48493          	addi	s1,s1,-1890 # 80231d68 <proc>
    800024d2:	a08d                	j	80002534 <wait+0xa8>
          pid = np->pid;
    800024d4:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024d8:	000b0e63          	beqz	s6,800024f4 <wait+0x68>
    800024dc:	4691                	li	a3,4
    800024de:	03448613          	addi	a2,s1,52
    800024e2:	85da                	mv	a1,s6
    800024e4:	05093503          	ld	a0,80(s2)
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	4da080e7          	jalr	1242(ra) # 800019c2 <copyout>
    800024f0:	02054263          	bltz	a0,80002514 <wait+0x88>
          freeproc(np);
    800024f4:	8526                	mv	a0,s1
    800024f6:	00000097          	auipc	ra,0x0
    800024fa:	8ba080e7          	jalr	-1862(ra) # 80001db0 <freeproc>
          release(&np->lock);
    800024fe:	8526                	mv	a0,s1
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	8c2080e7          	jalr	-1854(ra) # 80000dc2 <release>
          release(&p->lock);
    80002508:	854a                	mv	a0,s2
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	8b8080e7          	jalr	-1864(ra) # 80000dc2 <release>
          return pid;
    80002512:	a8a9                	j	8000256c <wait+0xe0>
            release(&np->lock);
    80002514:	8526                	mv	a0,s1
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	8ac080e7          	jalr	-1876(ra) # 80000dc2 <release>
            release(&p->lock);
    8000251e:	854a                	mv	a0,s2
    80002520:	fffff097          	auipc	ra,0xfffff
    80002524:	8a2080e7          	jalr	-1886(ra) # 80000dc2 <release>
            return -1;
    80002528:	59fd                	li	s3,-1
    8000252a:	a089                	j	8000256c <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000252c:	16848493          	addi	s1,s1,360
    80002530:	03348463          	beq	s1,s3,80002558 <wait+0xcc>
      if(np->parent == p){
    80002534:	709c                	ld	a5,32(s1)
    80002536:	ff279be3          	bne	a5,s2,8000252c <wait+0xa0>
        acquire(&np->lock);
    8000253a:	8526                	mv	a0,s1
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	7d2080e7          	jalr	2002(ra) # 80000d0e <acquire>
        if(np->state == ZOMBIE){
    80002544:	4c9c                	lw	a5,24(s1)
    80002546:	f94787e3          	beq	a5,s4,800024d4 <wait+0x48>
        release(&np->lock);
    8000254a:	8526                	mv	a0,s1
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	876080e7          	jalr	-1930(ra) # 80000dc2 <release>
        havekids = 1;
    80002554:	8756                	mv	a4,s5
    80002556:	bfd9                	j	8000252c <wait+0xa0>
    if(!havekids || p->killed){
    80002558:	c701                	beqz	a4,80002560 <wait+0xd4>
    8000255a:	03092783          	lw	a5,48(s2)
    8000255e:	c785                	beqz	a5,80002586 <wait+0xfa>
      release(&p->lock);
    80002560:	854a                	mv	a0,s2
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	860080e7          	jalr	-1952(ra) # 80000dc2 <release>
      return -1;
    8000256a:	59fd                	li	s3,-1
}
    8000256c:	854e                	mv	a0,s3
    8000256e:	60a6                	ld	ra,72(sp)
    80002570:	6406                	ld	s0,64(sp)
    80002572:	74e2                	ld	s1,56(sp)
    80002574:	7942                	ld	s2,48(sp)
    80002576:	79a2                	ld	s3,40(sp)
    80002578:	7a02                	ld	s4,32(sp)
    8000257a:	6ae2                	ld	s5,24(sp)
    8000257c:	6b42                	ld	s6,16(sp)
    8000257e:	6ba2                	ld	s7,8(sp)
    80002580:	6c02                	ld	s8,0(sp)
    80002582:	6161                	addi	sp,sp,80
    80002584:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002586:	85e2                	mv	a1,s8
    80002588:	854a                	mv	a0,s2
    8000258a:	00000097          	auipc	ra,0x0
    8000258e:	e84080e7          	jalr	-380(ra) # 8000240e <sleep>
    havekids = 0;
    80002592:	bf1d                	j	800024c8 <wait+0x3c>

0000000080002594 <wakeup>:
{
    80002594:	7139                	addi	sp,sp,-64
    80002596:	fc06                	sd	ra,56(sp)
    80002598:	f822                	sd	s0,48(sp)
    8000259a:	f426                	sd	s1,40(sp)
    8000259c:	f04a                	sd	s2,32(sp)
    8000259e:	ec4e                	sd	s3,24(sp)
    800025a0:	e852                	sd	s4,16(sp)
    800025a2:	e456                	sd	s5,8(sp)
    800025a4:	0080                	addi	s0,sp,64
    800025a6:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800025a8:	0022f497          	auipc	s1,0x22f
    800025ac:	7c048493          	addi	s1,s1,1984 # 80231d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800025b0:	4985                	li	s3,1
      p->state = RUNNABLE;
    800025b2:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800025b4:	00235917          	auipc	s2,0x235
    800025b8:	1b490913          	addi	s2,s2,436 # 80237768 <tickslock>
    800025bc:	a821                	j	800025d4 <wakeup+0x40>
      p->state = RUNNABLE;
    800025be:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800025c2:	8526                	mv	a0,s1
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	7fe080e7          	jalr	2046(ra) # 80000dc2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800025cc:	16848493          	addi	s1,s1,360
    800025d0:	01248e63          	beq	s1,s2,800025ec <wakeup+0x58>
    acquire(&p->lock);
    800025d4:	8526                	mv	a0,s1
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	738080e7          	jalr	1848(ra) # 80000d0e <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800025de:	4c9c                	lw	a5,24(s1)
    800025e0:	ff3791e3          	bne	a5,s3,800025c2 <wakeup+0x2e>
    800025e4:	749c                	ld	a5,40(s1)
    800025e6:	fd479ee3          	bne	a5,s4,800025c2 <wakeup+0x2e>
    800025ea:	bfd1                	j	800025be <wakeup+0x2a>
}
    800025ec:	70e2                	ld	ra,56(sp)
    800025ee:	7442                	ld	s0,48(sp)
    800025f0:	74a2                	ld	s1,40(sp)
    800025f2:	7902                	ld	s2,32(sp)
    800025f4:	69e2                	ld	s3,24(sp)
    800025f6:	6a42                	ld	s4,16(sp)
    800025f8:	6aa2                	ld	s5,8(sp)
    800025fa:	6121                	addi	sp,sp,64
    800025fc:	8082                	ret

00000000800025fe <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800025fe:	7179                	addi	sp,sp,-48
    80002600:	f406                	sd	ra,40(sp)
    80002602:	f022                	sd	s0,32(sp)
    80002604:	ec26                	sd	s1,24(sp)
    80002606:	e84a                	sd	s2,16(sp)
    80002608:	e44e                	sd	s3,8(sp)
    8000260a:	1800                	addi	s0,sp,48
    8000260c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000260e:	0022f497          	auipc	s1,0x22f
    80002612:	75a48493          	addi	s1,s1,1882 # 80231d68 <proc>
    80002616:	00235997          	auipc	s3,0x235
    8000261a:	15298993          	addi	s3,s3,338 # 80237768 <tickslock>
    acquire(&p->lock);
    8000261e:	8526                	mv	a0,s1
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	6ee080e7          	jalr	1774(ra) # 80000d0e <acquire>
    if(p->pid == pid){
    80002628:	5c9c                	lw	a5,56(s1)
    8000262a:	01278d63          	beq	a5,s2,80002644 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000262e:	8526                	mv	a0,s1
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	792080e7          	jalr	1938(ra) # 80000dc2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002638:	16848493          	addi	s1,s1,360
    8000263c:	ff3491e3          	bne	s1,s3,8000261e <kill+0x20>
  }
  return -1;
    80002640:	557d                	li	a0,-1
    80002642:	a829                	j	8000265c <kill+0x5e>
      p->killed = 1;
    80002644:	4785                	li	a5,1
    80002646:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002648:	4c98                	lw	a4,24(s1)
    8000264a:	4785                	li	a5,1
    8000264c:	00f70f63          	beq	a4,a5,8000266a <kill+0x6c>
      release(&p->lock);
    80002650:	8526                	mv	a0,s1
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	770080e7          	jalr	1904(ra) # 80000dc2 <release>
      return 0;
    8000265a:	4501                	li	a0,0
}
    8000265c:	70a2                	ld	ra,40(sp)
    8000265e:	7402                	ld	s0,32(sp)
    80002660:	64e2                	ld	s1,24(sp)
    80002662:	6942                	ld	s2,16(sp)
    80002664:	69a2                	ld	s3,8(sp)
    80002666:	6145                	addi	sp,sp,48
    80002668:	8082                	ret
        p->state = RUNNABLE;
    8000266a:	4789                	li	a5,2
    8000266c:	cc9c                	sw	a5,24(s1)
    8000266e:	b7cd                	j	80002650 <kill+0x52>

0000000080002670 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002670:	7179                	addi	sp,sp,-48
    80002672:	f406                	sd	ra,40(sp)
    80002674:	f022                	sd	s0,32(sp)
    80002676:	ec26                	sd	s1,24(sp)
    80002678:	e84a                	sd	s2,16(sp)
    8000267a:	e44e                	sd	s3,8(sp)
    8000267c:	e052                	sd	s4,0(sp)
    8000267e:	1800                	addi	s0,sp,48
    80002680:	84aa                	mv	s1,a0
    80002682:	892e                	mv	s2,a1
    80002684:	89b2                	mv	s3,a2
    80002686:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002688:	fffff097          	auipc	ra,0xfffff
    8000268c:	576080e7          	jalr	1398(ra) # 80001bfe <myproc>
  if(user_dst){
    80002690:	c08d                	beqz	s1,800026b2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002692:	86d2                	mv	a3,s4
    80002694:	864e                	mv	a2,s3
    80002696:	85ca                	mv	a1,s2
    80002698:	6928                	ld	a0,80(a0)
    8000269a:	fffff097          	auipc	ra,0xfffff
    8000269e:	328080e7          	jalr	808(ra) # 800019c2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026a2:	70a2                	ld	ra,40(sp)
    800026a4:	7402                	ld	s0,32(sp)
    800026a6:	64e2                	ld	s1,24(sp)
    800026a8:	6942                	ld	s2,16(sp)
    800026aa:	69a2                	ld	s3,8(sp)
    800026ac:	6a02                	ld	s4,0(sp)
    800026ae:	6145                	addi	sp,sp,48
    800026b0:	8082                	ret
    memmove((char *)dst, src, len);
    800026b2:	000a061b          	sext.w	a2,s4
    800026b6:	85ce                	mv	a1,s3
    800026b8:	854a                	mv	a0,s2
    800026ba:	ffffe097          	auipc	ra,0xffffe
    800026be:	7b0080e7          	jalr	1968(ra) # 80000e6a <memmove>
    return 0;
    800026c2:	8526                	mv	a0,s1
    800026c4:	bff9                	j	800026a2 <either_copyout+0x32>

00000000800026c6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026c6:	7179                	addi	sp,sp,-48
    800026c8:	f406                	sd	ra,40(sp)
    800026ca:	f022                	sd	s0,32(sp)
    800026cc:	ec26                	sd	s1,24(sp)
    800026ce:	e84a                	sd	s2,16(sp)
    800026d0:	e44e                	sd	s3,8(sp)
    800026d2:	e052                	sd	s4,0(sp)
    800026d4:	1800                	addi	s0,sp,48
    800026d6:	892a                	mv	s2,a0
    800026d8:	84ae                	mv	s1,a1
    800026da:	89b2                	mv	s3,a2
    800026dc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026de:	fffff097          	auipc	ra,0xfffff
    800026e2:	520080e7          	jalr	1312(ra) # 80001bfe <myproc>
  if(user_src){
    800026e6:	c08d                	beqz	s1,80002708 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026e8:	86d2                	mv	a3,s4
    800026ea:	864e                	mv	a2,s3
    800026ec:	85ca                	mv	a1,s2
    800026ee:	6928                	ld	a0,80(a0)
    800026f0:	fffff097          	auipc	ra,0xfffff
    800026f4:	0ca080e7          	jalr	202(ra) # 800017ba <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026f8:	70a2                	ld	ra,40(sp)
    800026fa:	7402                	ld	s0,32(sp)
    800026fc:	64e2                	ld	s1,24(sp)
    800026fe:	6942                	ld	s2,16(sp)
    80002700:	69a2                	ld	s3,8(sp)
    80002702:	6a02                	ld	s4,0(sp)
    80002704:	6145                	addi	sp,sp,48
    80002706:	8082                	ret
    memmove(dst, (char*)src, len);
    80002708:	000a061b          	sext.w	a2,s4
    8000270c:	85ce                	mv	a1,s3
    8000270e:	854a                	mv	a0,s2
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	75a080e7          	jalr	1882(ra) # 80000e6a <memmove>
    return 0;
    80002718:	8526                	mv	a0,s1
    8000271a:	bff9                	j	800026f8 <either_copyin+0x32>

000000008000271c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000271c:	715d                	addi	sp,sp,-80
    8000271e:	e486                	sd	ra,72(sp)
    80002720:	e0a2                	sd	s0,64(sp)
    80002722:	fc26                	sd	s1,56(sp)
    80002724:	f84a                	sd	s2,48(sp)
    80002726:	f44e                	sd	s3,40(sp)
    80002728:	f052                	sd	s4,32(sp)
    8000272a:	ec56                	sd	s5,24(sp)
    8000272c:	e85a                	sd	s6,16(sp)
    8000272e:	e45e                	sd	s7,8(sp)
    80002730:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002732:	00006517          	auipc	a0,0x6
    80002736:	9ce50513          	addi	a0,a0,-1586 # 80008100 <digits+0xc0>
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	e58080e7          	jalr	-424(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002742:	0022f497          	auipc	s1,0x22f
    80002746:	77e48493          	addi	s1,s1,1918 # 80231ec0 <proc+0x158>
    8000274a:	00235917          	auipc	s2,0x235
    8000274e:	17690913          	addi	s2,s2,374 # 802378c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002752:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002754:	00006997          	auipc	s3,0x6
    80002758:	bfc98993          	addi	s3,s3,-1028 # 80008350 <digits+0x310>
    printf("%d %s %s", p->pid, state, p->name);
    8000275c:	00006a97          	auipc	s5,0x6
    80002760:	bfca8a93          	addi	s5,s5,-1028 # 80008358 <digits+0x318>
    printf("\n");
    80002764:	00006a17          	auipc	s4,0x6
    80002768:	99ca0a13          	addi	s4,s4,-1636 # 80008100 <digits+0xc0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000276c:	00006b97          	auipc	s7,0x6
    80002770:	c24b8b93          	addi	s7,s7,-988 # 80008390 <states.1712>
    80002774:	a00d                	j	80002796 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002776:	ee06a583          	lw	a1,-288(a3)
    8000277a:	8556                	mv	a0,s5
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	e16080e7          	jalr	-490(ra) # 80000592 <printf>
    printf("\n");
    80002784:	8552                	mv	a0,s4
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	e0c080e7          	jalr	-500(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000278e:	16848493          	addi	s1,s1,360
    80002792:	03248163          	beq	s1,s2,800027b4 <procdump+0x98>
    if(p->state == UNUSED)
    80002796:	86a6                	mv	a3,s1
    80002798:	ec04a783          	lw	a5,-320(s1)
    8000279c:	dbed                	beqz	a5,8000278e <procdump+0x72>
      state = "???";
    8000279e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027a0:	fcfb6be3          	bltu	s6,a5,80002776 <procdump+0x5a>
    800027a4:	1782                	slli	a5,a5,0x20
    800027a6:	9381                	srli	a5,a5,0x20
    800027a8:	078e                	slli	a5,a5,0x3
    800027aa:	97de                	add	a5,a5,s7
    800027ac:	6390                	ld	a2,0(a5)
    800027ae:	f661                	bnez	a2,80002776 <procdump+0x5a>
      state = "???";
    800027b0:	864e                	mv	a2,s3
    800027b2:	b7d1                	j	80002776 <procdump+0x5a>
  }
}
    800027b4:	60a6                	ld	ra,72(sp)
    800027b6:	6406                	ld	s0,64(sp)
    800027b8:	74e2                	ld	s1,56(sp)
    800027ba:	7942                	ld	s2,48(sp)
    800027bc:	79a2                	ld	s3,40(sp)
    800027be:	7a02                	ld	s4,32(sp)
    800027c0:	6ae2                	ld	s5,24(sp)
    800027c2:	6b42                	ld	s6,16(sp)
    800027c4:	6ba2                	ld	s7,8(sp)
    800027c6:	6161                	addi	sp,sp,80
    800027c8:	8082                	ret

00000000800027ca <swtch>:
    800027ca:	00153023          	sd	ra,0(a0)
    800027ce:	00253423          	sd	sp,8(a0)
    800027d2:	e900                	sd	s0,16(a0)
    800027d4:	ed04                	sd	s1,24(a0)
    800027d6:	03253023          	sd	s2,32(a0)
    800027da:	03353423          	sd	s3,40(a0)
    800027de:	03453823          	sd	s4,48(a0)
    800027e2:	03553c23          	sd	s5,56(a0)
    800027e6:	05653023          	sd	s6,64(a0)
    800027ea:	05753423          	sd	s7,72(a0)
    800027ee:	05853823          	sd	s8,80(a0)
    800027f2:	05953c23          	sd	s9,88(a0)
    800027f6:	07a53023          	sd	s10,96(a0)
    800027fa:	07b53423          	sd	s11,104(a0)
    800027fe:	0005b083          	ld	ra,0(a1)
    80002802:	0085b103          	ld	sp,8(a1)
    80002806:	6980                	ld	s0,16(a1)
    80002808:	6d84                	ld	s1,24(a1)
    8000280a:	0205b903          	ld	s2,32(a1)
    8000280e:	0285b983          	ld	s3,40(a1)
    80002812:	0305ba03          	ld	s4,48(a1)
    80002816:	0385ba83          	ld	s5,56(a1)
    8000281a:	0405bb03          	ld	s6,64(a1)
    8000281e:	0485bb83          	ld	s7,72(a1)
    80002822:	0505bc03          	ld	s8,80(a1)
    80002826:	0585bc83          	ld	s9,88(a1)
    8000282a:	0605bd03          	ld	s10,96(a1)
    8000282e:	0685bd83          	ld	s11,104(a1)
    80002832:	8082                	ret

0000000080002834 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002834:	1141                	addi	sp,sp,-16
    80002836:	e406                	sd	ra,8(sp)
    80002838:	e022                	sd	s0,0(sp)
    8000283a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000283c:	00006597          	auipc	a1,0x6
    80002840:	b7c58593          	addi	a1,a1,-1156 # 800083b8 <states.1712+0x28>
    80002844:	00235517          	auipc	a0,0x235
    80002848:	f2450513          	addi	a0,a0,-220 # 80237768 <tickslock>
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	432080e7          	jalr	1074(ra) # 80000c7e <initlock>
}
    80002854:	60a2                	ld	ra,8(sp)
    80002856:	6402                	ld	s0,0(sp)
    80002858:	0141                	addi	sp,sp,16
    8000285a:	8082                	ret

000000008000285c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000285c:	1141                	addi	sp,sp,-16
    8000285e:	e422                	sd	s0,8(sp)
    80002860:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002862:	00003797          	auipc	a5,0x3
    80002866:	4ee78793          	addi	a5,a5,1262 # 80005d50 <kernelvec>
    8000286a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000286e:	6422                	ld	s0,8(sp)
    80002870:	0141                	addi	sp,sp,16
    80002872:	8082                	ret

0000000080002874 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002874:	1141                	addi	sp,sp,-16
    80002876:	e406                	sd	ra,8(sp)
    80002878:	e022                	sd	s0,0(sp)
    8000287a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000287c:	fffff097          	auipc	ra,0xfffff
    80002880:	382080e7          	jalr	898(ra) # 80001bfe <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002884:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002888:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000288a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000288e:	00004617          	auipc	a2,0x4
    80002892:	77260613          	addi	a2,a2,1906 # 80007000 <_trampoline>
    80002896:	00004697          	auipc	a3,0x4
    8000289a:	76a68693          	addi	a3,a3,1898 # 80007000 <_trampoline>
    8000289e:	8e91                	sub	a3,a3,a2
    800028a0:	040007b7          	lui	a5,0x4000
    800028a4:	17fd                	addi	a5,a5,-1
    800028a6:	07b2                	slli	a5,a5,0xc
    800028a8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028aa:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028ae:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028b0:	180026f3          	csrr	a3,satp
    800028b4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028b6:	6d38                	ld	a4,88(a0)
    800028b8:	6134                	ld	a3,64(a0)
    800028ba:	6585                	lui	a1,0x1
    800028bc:	96ae                	add	a3,a3,a1
    800028be:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028c0:	6d38                	ld	a4,88(a0)
    800028c2:	00000697          	auipc	a3,0x0
    800028c6:	13868693          	addi	a3,a3,312 # 800029fa <usertrap>
    800028ca:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028cc:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028ce:	8692                	mv	a3,tp
    800028d0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028d6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028da:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028de:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028e2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028e4:	6f18                	ld	a4,24(a4)
    800028e6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028ea:	692c                	ld	a1,80(a0)
    800028ec:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028ee:	00004717          	auipc	a4,0x4
    800028f2:	7a270713          	addi	a4,a4,1954 # 80007090 <userret>
    800028f6:	8f11                	sub	a4,a4,a2
    800028f8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028fa:	577d                	li	a4,-1
    800028fc:	177e                	slli	a4,a4,0x3f
    800028fe:	8dd9                	or	a1,a1,a4
    80002900:	02000537          	lui	a0,0x2000
    80002904:	157d                	addi	a0,a0,-1
    80002906:	0536                	slli	a0,a0,0xd
    80002908:	9782                	jalr	a5
}
    8000290a:	60a2                	ld	ra,8(sp)
    8000290c:	6402                	ld	s0,0(sp)
    8000290e:	0141                	addi	sp,sp,16
    80002910:	8082                	ret

0000000080002912 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002912:	1101                	addi	sp,sp,-32
    80002914:	ec06                	sd	ra,24(sp)
    80002916:	e822                	sd	s0,16(sp)
    80002918:	e426                	sd	s1,8(sp)
    8000291a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000291c:	00235497          	auipc	s1,0x235
    80002920:	e4c48493          	addi	s1,s1,-436 # 80237768 <tickslock>
    80002924:	8526                	mv	a0,s1
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	3e8080e7          	jalr	1000(ra) # 80000d0e <acquire>
  ticks++;
    8000292e:	00006517          	auipc	a0,0x6
    80002932:	6f250513          	addi	a0,a0,1778 # 80009020 <ticks>
    80002936:	411c                	lw	a5,0(a0)
    80002938:	2785                	addiw	a5,a5,1
    8000293a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000293c:	00000097          	auipc	ra,0x0
    80002940:	c58080e7          	jalr	-936(ra) # 80002594 <wakeup>
  release(&tickslock);
    80002944:	8526                	mv	a0,s1
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	47c080e7          	jalr	1148(ra) # 80000dc2 <release>
}
    8000294e:	60e2                	ld	ra,24(sp)
    80002950:	6442                	ld	s0,16(sp)
    80002952:	64a2                	ld	s1,8(sp)
    80002954:	6105                	addi	sp,sp,32
    80002956:	8082                	ret

0000000080002958 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002958:	1101                	addi	sp,sp,-32
    8000295a:	ec06                	sd	ra,24(sp)
    8000295c:	e822                	sd	s0,16(sp)
    8000295e:	e426                	sd	s1,8(sp)
    80002960:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002962:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002966:	00074d63          	bltz	a4,80002980 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000296a:	57fd                	li	a5,-1
    8000296c:	17fe                	slli	a5,a5,0x3f
    8000296e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002970:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002972:	06f70363          	beq	a4,a5,800029d8 <devintr+0x80>
  }
}
    80002976:	60e2                	ld	ra,24(sp)
    80002978:	6442                	ld	s0,16(sp)
    8000297a:	64a2                	ld	s1,8(sp)
    8000297c:	6105                	addi	sp,sp,32
    8000297e:	8082                	ret
     (scause & 0xff) == 9){
    80002980:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002984:	46a5                	li	a3,9
    80002986:	fed792e3          	bne	a5,a3,8000296a <devintr+0x12>
    int irq = plic_claim();
    8000298a:	00003097          	auipc	ra,0x3
    8000298e:	4ce080e7          	jalr	1230(ra) # 80005e58 <plic_claim>
    80002992:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002994:	47a9                	li	a5,10
    80002996:	02f50763          	beq	a0,a5,800029c4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000299a:	4785                	li	a5,1
    8000299c:	02f50963          	beq	a0,a5,800029ce <devintr+0x76>
    return 1;
    800029a0:	4505                	li	a0,1
    } else if(irq){
    800029a2:	d8f1                	beqz	s1,80002976 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029a4:	85a6                	mv	a1,s1
    800029a6:	00006517          	auipc	a0,0x6
    800029aa:	a1a50513          	addi	a0,a0,-1510 # 800083c0 <states.1712+0x30>
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	be4080e7          	jalr	-1052(ra) # 80000592 <printf>
      plic_complete(irq);
    800029b6:	8526                	mv	a0,s1
    800029b8:	00003097          	auipc	ra,0x3
    800029bc:	4c4080e7          	jalr	1220(ra) # 80005e7c <plic_complete>
    return 1;
    800029c0:	4505                	li	a0,1
    800029c2:	bf55                	j	80002976 <devintr+0x1e>
      uartintr();
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	010080e7          	jalr	16(ra) # 800009d4 <uartintr>
    800029cc:	b7ed                	j	800029b6 <devintr+0x5e>
      virtio_disk_intr();
    800029ce:	00004097          	auipc	ra,0x4
    800029d2:	948080e7          	jalr	-1720(ra) # 80006316 <virtio_disk_intr>
    800029d6:	b7c5                	j	800029b6 <devintr+0x5e>
    if(cpuid() == 0){
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	1fa080e7          	jalr	506(ra) # 80001bd2 <cpuid>
    800029e0:	c901                	beqz	a0,800029f0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029e2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029e6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029e8:	14479073          	csrw	sip,a5
    return 2;
    800029ec:	4509                	li	a0,2
    800029ee:	b761                	j	80002976 <devintr+0x1e>
      clockintr();
    800029f0:	00000097          	auipc	ra,0x0
    800029f4:	f22080e7          	jalr	-222(ra) # 80002912 <clockintr>
    800029f8:	b7ed                	j	800029e2 <devintr+0x8a>

00000000800029fa <usertrap>:
{
    800029fa:	1101                	addi	sp,sp,-32
    800029fc:	ec06                	sd	ra,24(sp)
    800029fe:	e822                	sd	s0,16(sp)
    80002a00:	e426                	sd	s1,8(sp)
    80002a02:	e04a                	sd	s2,0(sp)
    80002a04:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a06:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a0a:	1007f793          	andi	a5,a5,256
    80002a0e:	e3b9                	bnez	a5,80002a54 <usertrap+0x5a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a10:	00003797          	auipc	a5,0x3
    80002a14:	34078793          	addi	a5,a5,832 # 80005d50 <kernelvec>
    80002a18:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a1c:	fffff097          	auipc	ra,0xfffff
    80002a20:	1e2080e7          	jalr	482(ra) # 80001bfe <myproc>
    80002a24:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a26:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a28:	14102773          	csrr	a4,sepc
    80002a2c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a2e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a32:	47a1                	li	a5,8
    80002a34:	02f70863          	beq	a4,a5,80002a64 <usertrap+0x6a>
    80002a38:	14202773          	csrr	a4,scause
  } else if (r_scause() == 15) {
    80002a3c:	47bd                	li	a5,15
    80002a3e:	06f70563          	beq	a4,a5,80002aa8 <usertrap+0xae>
  } else if((which_dev = devintr()) != 0){
    80002a42:	00000097          	auipc	ra,0x0
    80002a46:	f16080e7          	jalr	-234(ra) # 80002958 <devintr>
    80002a4a:	892a                	mv	s2,a0
    80002a4c:	c935                	beqz	a0,80002ac0 <usertrap+0xc6>
  if(p->killed)
    80002a4e:	589c                	lw	a5,48(s1)
    80002a50:	c7dd                	beqz	a5,80002afe <usertrap+0x104>
    80002a52:	a04d                	j	80002af4 <usertrap+0xfa>
    panic("usertrap: not from user mode");
    80002a54:	00006517          	auipc	a0,0x6
    80002a58:	98c50513          	addi	a0,a0,-1652 # 800083e0 <states.1712+0x50>
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	aec080e7          	jalr	-1300(ra) # 80000548 <panic>
    if(p->killed)
    80002a64:	591c                	lw	a5,48(a0)
    80002a66:	eb9d                	bnez	a5,80002a9c <usertrap+0xa2>
    p->trapframe->epc += 4;
    80002a68:	6cb8                	ld	a4,88(s1)
    80002a6a:	6f1c                	ld	a5,24(a4)
    80002a6c:	0791                	addi	a5,a5,4
    80002a6e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a70:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a74:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a78:	10079073          	csrw	sstatus,a5
    syscall();
    80002a7c:	00000097          	auipc	ra,0x0
    80002a80:	2d8080e7          	jalr	728(ra) # 80002d54 <syscall>
  if(p->killed)
    80002a84:	589c                	lw	a5,48(s1)
    80002a86:	e7c1                	bnez	a5,80002b0e <usertrap+0x114>
  usertrapret();
    80002a88:	00000097          	auipc	ra,0x0
    80002a8c:	dec080e7          	jalr	-532(ra) # 80002874 <usertrapret>
}
    80002a90:	60e2                	ld	ra,24(sp)
    80002a92:	6442                	ld	s0,16(sp)
    80002a94:	64a2                	ld	s1,8(sp)
    80002a96:	6902                	ld	s2,0(sp)
    80002a98:	6105                	addi	sp,sp,32
    80002a9a:	8082                	ret
      exit(-1);
    80002a9c:	557d                	li	a0,-1
    80002a9e:	00000097          	auipc	ra,0x0
    80002aa2:	82a080e7          	jalr	-2006(ra) # 800022c8 <exit>
    80002aa6:	b7c9                	j	80002a68 <usertrap+0x6e>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aa8:	143025f3          	csrr	a1,stval
    if (cowalloc(p->pagetable, r_stval()) < 0) {
    80002aac:	6928                	ld	a0,80(a0)
    80002aae:	fffff097          	auipc	ra,0xfffff
    80002ab2:	e4c080e7          	jalr	-436(ra) # 800018fa <cowalloc>
    80002ab6:	fc0557e3          	bgez	a0,80002a84 <usertrap+0x8a>
      p->killed = 1;
    80002aba:	4785                	li	a5,1
    80002abc:	d89c                	sw	a5,48(s1)
    80002abe:	a815                	j	80002af2 <usertrap+0xf8>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ac0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ac4:	5c90                	lw	a2,56(s1)
    80002ac6:	00006517          	auipc	a0,0x6
    80002aca:	93a50513          	addi	a0,a0,-1734 # 80008400 <states.1712+0x70>
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	ac4080e7          	jalr	-1340(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ad6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ada:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ade:	00006517          	auipc	a0,0x6
    80002ae2:	95250513          	addi	a0,a0,-1710 # 80008430 <states.1712+0xa0>
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	aac080e7          	jalr	-1364(ra) # 80000592 <printf>
    p->killed = 1;
    80002aee:	4785                	li	a5,1
    80002af0:	d89c                	sw	a5,48(s1)
{
    80002af2:	4901                	li	s2,0
    exit(-1);
    80002af4:	557d                	li	a0,-1
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	7d2080e7          	jalr	2002(ra) # 800022c8 <exit>
  if(which_dev == 2)
    80002afe:	4789                	li	a5,2
    80002b00:	f8f914e3          	bne	s2,a5,80002a88 <usertrap+0x8e>
    yield();
    80002b04:	00000097          	auipc	ra,0x0
    80002b08:	8ce080e7          	jalr	-1842(ra) # 800023d2 <yield>
    80002b0c:	bfb5                	j	80002a88 <usertrap+0x8e>
  if(p->killed)
    80002b0e:	4901                	li	s2,0
    80002b10:	b7d5                	j	80002af4 <usertrap+0xfa>

0000000080002b12 <kerneltrap>:
{
    80002b12:	7179                	addi	sp,sp,-48
    80002b14:	f406                	sd	ra,40(sp)
    80002b16:	f022                	sd	s0,32(sp)
    80002b18:	ec26                	sd	s1,24(sp)
    80002b1a:	e84a                	sd	s2,16(sp)
    80002b1c:	e44e                	sd	s3,8(sp)
    80002b1e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b20:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b24:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b28:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b2c:	1004f793          	andi	a5,s1,256
    80002b30:	cb85                	beqz	a5,80002b60 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b32:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b36:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b38:	ef85                	bnez	a5,80002b70 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b3a:	00000097          	auipc	ra,0x0
    80002b3e:	e1e080e7          	jalr	-482(ra) # 80002958 <devintr>
    80002b42:	cd1d                	beqz	a0,80002b80 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b44:	4789                	li	a5,2
    80002b46:	06f50a63          	beq	a0,a5,80002bba <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b4a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b4e:	10049073          	csrw	sstatus,s1
}
    80002b52:	70a2                	ld	ra,40(sp)
    80002b54:	7402                	ld	s0,32(sp)
    80002b56:	64e2                	ld	s1,24(sp)
    80002b58:	6942                	ld	s2,16(sp)
    80002b5a:	69a2                	ld	s3,8(sp)
    80002b5c:	6145                	addi	sp,sp,48
    80002b5e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b60:	00006517          	auipc	a0,0x6
    80002b64:	8f050513          	addi	a0,a0,-1808 # 80008450 <states.1712+0xc0>
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	9e0080e7          	jalr	-1568(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b70:	00006517          	auipc	a0,0x6
    80002b74:	90850513          	addi	a0,a0,-1784 # 80008478 <states.1712+0xe8>
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	9d0080e7          	jalr	-1584(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002b80:	85ce                	mv	a1,s3
    80002b82:	00006517          	auipc	a0,0x6
    80002b86:	91650513          	addi	a0,a0,-1770 # 80008498 <states.1712+0x108>
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	a08080e7          	jalr	-1528(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b92:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b96:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b9a:	00006517          	auipc	a0,0x6
    80002b9e:	90e50513          	addi	a0,a0,-1778 # 800084a8 <states.1712+0x118>
    80002ba2:	ffffe097          	auipc	ra,0xffffe
    80002ba6:	9f0080e7          	jalr	-1552(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002baa:	00006517          	auipc	a0,0x6
    80002bae:	91650513          	addi	a0,a0,-1770 # 800084c0 <states.1712+0x130>
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	996080e7          	jalr	-1642(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bba:	fffff097          	auipc	ra,0xfffff
    80002bbe:	044080e7          	jalr	68(ra) # 80001bfe <myproc>
    80002bc2:	d541                	beqz	a0,80002b4a <kerneltrap+0x38>
    80002bc4:	fffff097          	auipc	ra,0xfffff
    80002bc8:	03a080e7          	jalr	58(ra) # 80001bfe <myproc>
    80002bcc:	4d18                	lw	a4,24(a0)
    80002bce:	478d                	li	a5,3
    80002bd0:	f6f71de3          	bne	a4,a5,80002b4a <kerneltrap+0x38>
    yield();
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	7fe080e7          	jalr	2046(ra) # 800023d2 <yield>
    80002bdc:	b7bd                	j	80002b4a <kerneltrap+0x38>

0000000080002bde <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bde:	1101                	addi	sp,sp,-32
    80002be0:	ec06                	sd	ra,24(sp)
    80002be2:	e822                	sd	s0,16(sp)
    80002be4:	e426                	sd	s1,8(sp)
    80002be6:	1000                	addi	s0,sp,32
    80002be8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bea:	fffff097          	auipc	ra,0xfffff
    80002bee:	014080e7          	jalr	20(ra) # 80001bfe <myproc>
  switch (n) {
    80002bf2:	4795                	li	a5,5
    80002bf4:	0497e163          	bltu	a5,s1,80002c36 <argraw+0x58>
    80002bf8:	048a                	slli	s1,s1,0x2
    80002bfa:	00006717          	auipc	a4,0x6
    80002bfe:	8fe70713          	addi	a4,a4,-1794 # 800084f8 <states.1712+0x168>
    80002c02:	94ba                	add	s1,s1,a4
    80002c04:	409c                	lw	a5,0(s1)
    80002c06:	97ba                	add	a5,a5,a4
    80002c08:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c0a:	6d3c                	ld	a5,88(a0)
    80002c0c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c0e:	60e2                	ld	ra,24(sp)
    80002c10:	6442                	ld	s0,16(sp)
    80002c12:	64a2                	ld	s1,8(sp)
    80002c14:	6105                	addi	sp,sp,32
    80002c16:	8082                	ret
    return p->trapframe->a1;
    80002c18:	6d3c                	ld	a5,88(a0)
    80002c1a:	7fa8                	ld	a0,120(a5)
    80002c1c:	bfcd                	j	80002c0e <argraw+0x30>
    return p->trapframe->a2;
    80002c1e:	6d3c                	ld	a5,88(a0)
    80002c20:	63c8                	ld	a0,128(a5)
    80002c22:	b7f5                	j	80002c0e <argraw+0x30>
    return p->trapframe->a3;
    80002c24:	6d3c                	ld	a5,88(a0)
    80002c26:	67c8                	ld	a0,136(a5)
    80002c28:	b7dd                	j	80002c0e <argraw+0x30>
    return p->trapframe->a4;
    80002c2a:	6d3c                	ld	a5,88(a0)
    80002c2c:	6bc8                	ld	a0,144(a5)
    80002c2e:	b7c5                	j	80002c0e <argraw+0x30>
    return p->trapframe->a5;
    80002c30:	6d3c                	ld	a5,88(a0)
    80002c32:	6fc8                	ld	a0,152(a5)
    80002c34:	bfe9                	j	80002c0e <argraw+0x30>
  panic("argraw");
    80002c36:	00006517          	auipc	a0,0x6
    80002c3a:	89a50513          	addi	a0,a0,-1894 # 800084d0 <states.1712+0x140>
    80002c3e:	ffffe097          	auipc	ra,0xffffe
    80002c42:	90a080e7          	jalr	-1782(ra) # 80000548 <panic>

0000000080002c46 <fetchaddr>:
{
    80002c46:	1101                	addi	sp,sp,-32
    80002c48:	ec06                	sd	ra,24(sp)
    80002c4a:	e822                	sd	s0,16(sp)
    80002c4c:	e426                	sd	s1,8(sp)
    80002c4e:	e04a                	sd	s2,0(sp)
    80002c50:	1000                	addi	s0,sp,32
    80002c52:	84aa                	mv	s1,a0
    80002c54:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c56:	fffff097          	auipc	ra,0xfffff
    80002c5a:	fa8080e7          	jalr	-88(ra) # 80001bfe <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c5e:	653c                	ld	a5,72(a0)
    80002c60:	02f4f863          	bgeu	s1,a5,80002c90 <fetchaddr+0x4a>
    80002c64:	00848713          	addi	a4,s1,8
    80002c68:	02e7e663          	bltu	a5,a4,80002c94 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c6c:	46a1                	li	a3,8
    80002c6e:	8626                	mv	a2,s1
    80002c70:	85ca                	mv	a1,s2
    80002c72:	6928                	ld	a0,80(a0)
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	b46080e7          	jalr	-1210(ra) # 800017ba <copyin>
    80002c7c:	00a03533          	snez	a0,a0
    80002c80:	40a00533          	neg	a0,a0
}
    80002c84:	60e2                	ld	ra,24(sp)
    80002c86:	6442                	ld	s0,16(sp)
    80002c88:	64a2                	ld	s1,8(sp)
    80002c8a:	6902                	ld	s2,0(sp)
    80002c8c:	6105                	addi	sp,sp,32
    80002c8e:	8082                	ret
    return -1;
    80002c90:	557d                	li	a0,-1
    80002c92:	bfcd                	j	80002c84 <fetchaddr+0x3e>
    80002c94:	557d                	li	a0,-1
    80002c96:	b7fd                	j	80002c84 <fetchaddr+0x3e>

0000000080002c98 <fetchstr>:
{
    80002c98:	7179                	addi	sp,sp,-48
    80002c9a:	f406                	sd	ra,40(sp)
    80002c9c:	f022                	sd	s0,32(sp)
    80002c9e:	ec26                	sd	s1,24(sp)
    80002ca0:	e84a                	sd	s2,16(sp)
    80002ca2:	e44e                	sd	s3,8(sp)
    80002ca4:	1800                	addi	s0,sp,48
    80002ca6:	892a                	mv	s2,a0
    80002ca8:	84ae                	mv	s1,a1
    80002caa:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cac:	fffff097          	auipc	ra,0xfffff
    80002cb0:	f52080e7          	jalr	-174(ra) # 80001bfe <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cb4:	86ce                	mv	a3,s3
    80002cb6:	864a                	mv	a2,s2
    80002cb8:	85a6                	mv	a1,s1
    80002cba:	6928                	ld	a0,80(a0)
    80002cbc:	fffff097          	auipc	ra,0xfffff
    80002cc0:	b8a080e7          	jalr	-1142(ra) # 80001846 <copyinstr>
  if(err < 0)
    80002cc4:	00054763          	bltz	a0,80002cd2 <fetchstr+0x3a>
  return strlen(buf);
    80002cc8:	8526                	mv	a0,s1
    80002cca:	ffffe097          	auipc	ra,0xffffe
    80002cce:	2c8080e7          	jalr	712(ra) # 80000f92 <strlen>
}
    80002cd2:	70a2                	ld	ra,40(sp)
    80002cd4:	7402                	ld	s0,32(sp)
    80002cd6:	64e2                	ld	s1,24(sp)
    80002cd8:	6942                	ld	s2,16(sp)
    80002cda:	69a2                	ld	s3,8(sp)
    80002cdc:	6145                	addi	sp,sp,48
    80002cde:	8082                	ret

0000000080002ce0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ce0:	1101                	addi	sp,sp,-32
    80002ce2:	ec06                	sd	ra,24(sp)
    80002ce4:	e822                	sd	s0,16(sp)
    80002ce6:	e426                	sd	s1,8(sp)
    80002ce8:	1000                	addi	s0,sp,32
    80002cea:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	ef2080e7          	jalr	-270(ra) # 80002bde <argraw>
    80002cf4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cf6:	4501                	li	a0,0
    80002cf8:	60e2                	ld	ra,24(sp)
    80002cfa:	6442                	ld	s0,16(sp)
    80002cfc:	64a2                	ld	s1,8(sp)
    80002cfe:	6105                	addi	sp,sp,32
    80002d00:	8082                	ret

0000000080002d02 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d02:	1101                	addi	sp,sp,-32
    80002d04:	ec06                	sd	ra,24(sp)
    80002d06:	e822                	sd	s0,16(sp)
    80002d08:	e426                	sd	s1,8(sp)
    80002d0a:	1000                	addi	s0,sp,32
    80002d0c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d0e:	00000097          	auipc	ra,0x0
    80002d12:	ed0080e7          	jalr	-304(ra) # 80002bde <argraw>
    80002d16:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d18:	4501                	li	a0,0
    80002d1a:	60e2                	ld	ra,24(sp)
    80002d1c:	6442                	ld	s0,16(sp)
    80002d1e:	64a2                	ld	s1,8(sp)
    80002d20:	6105                	addi	sp,sp,32
    80002d22:	8082                	ret

0000000080002d24 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d24:	1101                	addi	sp,sp,-32
    80002d26:	ec06                	sd	ra,24(sp)
    80002d28:	e822                	sd	s0,16(sp)
    80002d2a:	e426                	sd	s1,8(sp)
    80002d2c:	e04a                	sd	s2,0(sp)
    80002d2e:	1000                	addi	s0,sp,32
    80002d30:	84ae                	mv	s1,a1
    80002d32:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	eaa080e7          	jalr	-342(ra) # 80002bde <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d3c:	864a                	mv	a2,s2
    80002d3e:	85a6                	mv	a1,s1
    80002d40:	00000097          	auipc	ra,0x0
    80002d44:	f58080e7          	jalr	-168(ra) # 80002c98 <fetchstr>
}
    80002d48:	60e2                	ld	ra,24(sp)
    80002d4a:	6442                	ld	s0,16(sp)
    80002d4c:	64a2                	ld	s1,8(sp)
    80002d4e:	6902                	ld	s2,0(sp)
    80002d50:	6105                	addi	sp,sp,32
    80002d52:	8082                	ret

0000000080002d54 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002d54:	1101                	addi	sp,sp,-32
    80002d56:	ec06                	sd	ra,24(sp)
    80002d58:	e822                	sd	s0,16(sp)
    80002d5a:	e426                	sd	s1,8(sp)
    80002d5c:	e04a                	sd	s2,0(sp)
    80002d5e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	e9e080e7          	jalr	-354(ra) # 80001bfe <myproc>
    80002d68:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d6a:	05853903          	ld	s2,88(a0)
    80002d6e:	0a893783          	ld	a5,168(s2)
    80002d72:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d76:	37fd                	addiw	a5,a5,-1
    80002d78:	4751                	li	a4,20
    80002d7a:	00f76f63          	bltu	a4,a5,80002d98 <syscall+0x44>
    80002d7e:	00369713          	slli	a4,a3,0x3
    80002d82:	00005797          	auipc	a5,0x5
    80002d86:	78e78793          	addi	a5,a5,1934 # 80008510 <syscalls>
    80002d8a:	97ba                	add	a5,a5,a4
    80002d8c:	639c                	ld	a5,0(a5)
    80002d8e:	c789                	beqz	a5,80002d98 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d90:	9782                	jalr	a5
    80002d92:	06a93823          	sd	a0,112(s2)
    80002d96:	a839                	j	80002db4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d98:	15848613          	addi	a2,s1,344
    80002d9c:	5c8c                	lw	a1,56(s1)
    80002d9e:	00005517          	auipc	a0,0x5
    80002da2:	73a50513          	addi	a0,a0,1850 # 800084d8 <states.1712+0x148>
    80002da6:	ffffd097          	auipc	ra,0xffffd
    80002daa:	7ec080e7          	jalr	2028(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dae:	6cbc                	ld	a5,88(s1)
    80002db0:	577d                	li	a4,-1
    80002db2:	fbb8                	sd	a4,112(a5)
  }
}
    80002db4:	60e2                	ld	ra,24(sp)
    80002db6:	6442                	ld	s0,16(sp)
    80002db8:	64a2                	ld	s1,8(sp)
    80002dba:	6902                	ld	s2,0(sp)
    80002dbc:	6105                	addi	sp,sp,32
    80002dbe:	8082                	ret

0000000080002dc0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002dc0:	1101                	addi	sp,sp,-32
    80002dc2:	ec06                	sd	ra,24(sp)
    80002dc4:	e822                	sd	s0,16(sp)
    80002dc6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002dc8:	fec40593          	addi	a1,s0,-20
    80002dcc:	4501                	li	a0,0
    80002dce:	00000097          	auipc	ra,0x0
    80002dd2:	f12080e7          	jalr	-238(ra) # 80002ce0 <argint>
    return -1;
    80002dd6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dd8:	00054963          	bltz	a0,80002dea <sys_exit+0x2a>
  exit(n);
    80002ddc:	fec42503          	lw	a0,-20(s0)
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	4e8080e7          	jalr	1256(ra) # 800022c8 <exit>
  return 0;  // not reached
    80002de8:	4781                	li	a5,0
}
    80002dea:	853e                	mv	a0,a5
    80002dec:	60e2                	ld	ra,24(sp)
    80002dee:	6442                	ld	s0,16(sp)
    80002df0:	6105                	addi	sp,sp,32
    80002df2:	8082                	ret

0000000080002df4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002df4:	1141                	addi	sp,sp,-16
    80002df6:	e406                	sd	ra,8(sp)
    80002df8:	e022                	sd	s0,0(sp)
    80002dfa:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	e02080e7          	jalr	-510(ra) # 80001bfe <myproc>
}
    80002e04:	5d08                	lw	a0,56(a0)
    80002e06:	60a2                	ld	ra,8(sp)
    80002e08:	6402                	ld	s0,0(sp)
    80002e0a:	0141                	addi	sp,sp,16
    80002e0c:	8082                	ret

0000000080002e0e <sys_fork>:

uint64
sys_fork(void)
{
    80002e0e:	1141                	addi	sp,sp,-16
    80002e10:	e406                	sd	ra,8(sp)
    80002e12:	e022                	sd	s0,0(sp)
    80002e14:	0800                	addi	s0,sp,16
  return fork();
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	1a8080e7          	jalr	424(ra) # 80001fbe <fork>
}
    80002e1e:	60a2                	ld	ra,8(sp)
    80002e20:	6402                	ld	s0,0(sp)
    80002e22:	0141                	addi	sp,sp,16
    80002e24:	8082                	ret

0000000080002e26 <sys_wait>:

uint64
sys_wait(void)
{
    80002e26:	1101                	addi	sp,sp,-32
    80002e28:	ec06                	sd	ra,24(sp)
    80002e2a:	e822                	sd	s0,16(sp)
    80002e2c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e2e:	fe840593          	addi	a1,s0,-24
    80002e32:	4501                	li	a0,0
    80002e34:	00000097          	auipc	ra,0x0
    80002e38:	ece080e7          	jalr	-306(ra) # 80002d02 <argaddr>
    80002e3c:	87aa                	mv	a5,a0
    return -1;
    80002e3e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e40:	0007c863          	bltz	a5,80002e50 <sys_wait+0x2a>
  return wait(p);
    80002e44:	fe843503          	ld	a0,-24(s0)
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	644080e7          	jalr	1604(ra) # 8000248c <wait>
}
    80002e50:	60e2                	ld	ra,24(sp)
    80002e52:	6442                	ld	s0,16(sp)
    80002e54:	6105                	addi	sp,sp,32
    80002e56:	8082                	ret

0000000080002e58 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e58:	7179                	addi	sp,sp,-48
    80002e5a:	f406                	sd	ra,40(sp)
    80002e5c:	f022                	sd	s0,32(sp)
    80002e5e:	ec26                	sd	s1,24(sp)
    80002e60:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e62:	fdc40593          	addi	a1,s0,-36
    80002e66:	4501                	li	a0,0
    80002e68:	00000097          	auipc	ra,0x0
    80002e6c:	e78080e7          	jalr	-392(ra) # 80002ce0 <argint>
    80002e70:	87aa                	mv	a5,a0
    return -1;
    80002e72:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e74:	0207c063          	bltz	a5,80002e94 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	d86080e7          	jalr	-634(ra) # 80001bfe <myproc>
    80002e80:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e82:	fdc42503          	lw	a0,-36(s0)
    80002e86:	fffff097          	auipc	ra,0xfffff
    80002e8a:	0c4080e7          	jalr	196(ra) # 80001f4a <growproc>
    80002e8e:	00054863          	bltz	a0,80002e9e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e92:	8526                	mv	a0,s1
}
    80002e94:	70a2                	ld	ra,40(sp)
    80002e96:	7402                	ld	s0,32(sp)
    80002e98:	64e2                	ld	s1,24(sp)
    80002e9a:	6145                	addi	sp,sp,48
    80002e9c:	8082                	ret
    return -1;
    80002e9e:	557d                	li	a0,-1
    80002ea0:	bfd5                	j	80002e94 <sys_sbrk+0x3c>

0000000080002ea2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ea2:	7139                	addi	sp,sp,-64
    80002ea4:	fc06                	sd	ra,56(sp)
    80002ea6:	f822                	sd	s0,48(sp)
    80002ea8:	f426                	sd	s1,40(sp)
    80002eaa:	f04a                	sd	s2,32(sp)
    80002eac:	ec4e                	sd	s3,24(sp)
    80002eae:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002eb0:	fcc40593          	addi	a1,s0,-52
    80002eb4:	4501                	li	a0,0
    80002eb6:	00000097          	auipc	ra,0x0
    80002eba:	e2a080e7          	jalr	-470(ra) # 80002ce0 <argint>
    return -1;
    80002ebe:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ec0:	06054563          	bltz	a0,80002f2a <sys_sleep+0x88>
  acquire(&tickslock);
    80002ec4:	00235517          	auipc	a0,0x235
    80002ec8:	8a450513          	addi	a0,a0,-1884 # 80237768 <tickslock>
    80002ecc:	ffffe097          	auipc	ra,0xffffe
    80002ed0:	e42080e7          	jalr	-446(ra) # 80000d0e <acquire>
  ticks0 = ticks;
    80002ed4:	00006917          	auipc	s2,0x6
    80002ed8:	14c92903          	lw	s2,332(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002edc:	fcc42783          	lw	a5,-52(s0)
    80002ee0:	cf85                	beqz	a5,80002f18 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ee2:	00235997          	auipc	s3,0x235
    80002ee6:	88698993          	addi	s3,s3,-1914 # 80237768 <tickslock>
    80002eea:	00006497          	auipc	s1,0x6
    80002eee:	13648493          	addi	s1,s1,310 # 80009020 <ticks>
    if(myproc()->killed){
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	d0c080e7          	jalr	-756(ra) # 80001bfe <myproc>
    80002efa:	591c                	lw	a5,48(a0)
    80002efc:	ef9d                	bnez	a5,80002f3a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002efe:	85ce                	mv	a1,s3
    80002f00:	8526                	mv	a0,s1
    80002f02:	fffff097          	auipc	ra,0xfffff
    80002f06:	50c080e7          	jalr	1292(ra) # 8000240e <sleep>
  while(ticks - ticks0 < n){
    80002f0a:	409c                	lw	a5,0(s1)
    80002f0c:	412787bb          	subw	a5,a5,s2
    80002f10:	fcc42703          	lw	a4,-52(s0)
    80002f14:	fce7efe3          	bltu	a5,a4,80002ef2 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f18:	00235517          	auipc	a0,0x235
    80002f1c:	85050513          	addi	a0,a0,-1968 # 80237768 <tickslock>
    80002f20:	ffffe097          	auipc	ra,0xffffe
    80002f24:	ea2080e7          	jalr	-350(ra) # 80000dc2 <release>
  return 0;
    80002f28:	4781                	li	a5,0
}
    80002f2a:	853e                	mv	a0,a5
    80002f2c:	70e2                	ld	ra,56(sp)
    80002f2e:	7442                	ld	s0,48(sp)
    80002f30:	74a2                	ld	s1,40(sp)
    80002f32:	7902                	ld	s2,32(sp)
    80002f34:	69e2                	ld	s3,24(sp)
    80002f36:	6121                	addi	sp,sp,64
    80002f38:	8082                	ret
      release(&tickslock);
    80002f3a:	00235517          	auipc	a0,0x235
    80002f3e:	82e50513          	addi	a0,a0,-2002 # 80237768 <tickslock>
    80002f42:	ffffe097          	auipc	ra,0xffffe
    80002f46:	e80080e7          	jalr	-384(ra) # 80000dc2 <release>
      return -1;
    80002f4a:	57fd                	li	a5,-1
    80002f4c:	bff9                	j	80002f2a <sys_sleep+0x88>

0000000080002f4e <sys_kill>:

uint64
sys_kill(void)
{
    80002f4e:	1101                	addi	sp,sp,-32
    80002f50:	ec06                	sd	ra,24(sp)
    80002f52:	e822                	sd	s0,16(sp)
    80002f54:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f56:	fec40593          	addi	a1,s0,-20
    80002f5a:	4501                	li	a0,0
    80002f5c:	00000097          	auipc	ra,0x0
    80002f60:	d84080e7          	jalr	-636(ra) # 80002ce0 <argint>
    80002f64:	87aa                	mv	a5,a0
    return -1;
    80002f66:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f68:	0007c863          	bltz	a5,80002f78 <sys_kill+0x2a>
  return kill(pid);
    80002f6c:	fec42503          	lw	a0,-20(s0)
    80002f70:	fffff097          	auipc	ra,0xfffff
    80002f74:	68e080e7          	jalr	1678(ra) # 800025fe <kill>
}
    80002f78:	60e2                	ld	ra,24(sp)
    80002f7a:	6442                	ld	s0,16(sp)
    80002f7c:	6105                	addi	sp,sp,32
    80002f7e:	8082                	ret

0000000080002f80 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f80:	1101                	addi	sp,sp,-32
    80002f82:	ec06                	sd	ra,24(sp)
    80002f84:	e822                	sd	s0,16(sp)
    80002f86:	e426                	sd	s1,8(sp)
    80002f88:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f8a:	00234517          	auipc	a0,0x234
    80002f8e:	7de50513          	addi	a0,a0,2014 # 80237768 <tickslock>
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	d7c080e7          	jalr	-644(ra) # 80000d0e <acquire>
  xticks = ticks;
    80002f9a:	00006497          	auipc	s1,0x6
    80002f9e:	0864a483          	lw	s1,134(s1) # 80009020 <ticks>
  release(&tickslock);
    80002fa2:	00234517          	auipc	a0,0x234
    80002fa6:	7c650513          	addi	a0,a0,1990 # 80237768 <tickslock>
    80002faa:	ffffe097          	auipc	ra,0xffffe
    80002fae:	e18080e7          	jalr	-488(ra) # 80000dc2 <release>
  return xticks;
}
    80002fb2:	02049513          	slli	a0,s1,0x20
    80002fb6:	9101                	srli	a0,a0,0x20
    80002fb8:	60e2                	ld	ra,24(sp)
    80002fba:	6442                	ld	s0,16(sp)
    80002fbc:	64a2                	ld	s1,8(sp)
    80002fbe:	6105                	addi	sp,sp,32
    80002fc0:	8082                	ret

0000000080002fc2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fc2:	7179                	addi	sp,sp,-48
    80002fc4:	f406                	sd	ra,40(sp)
    80002fc6:	f022                	sd	s0,32(sp)
    80002fc8:	ec26                	sd	s1,24(sp)
    80002fca:	e84a                	sd	s2,16(sp)
    80002fcc:	e44e                	sd	s3,8(sp)
    80002fce:	e052                	sd	s4,0(sp)
    80002fd0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fd2:	00005597          	auipc	a1,0x5
    80002fd6:	5ee58593          	addi	a1,a1,1518 # 800085c0 <syscalls+0xb0>
    80002fda:	00234517          	auipc	a0,0x234
    80002fde:	7a650513          	addi	a0,a0,1958 # 80237780 <bcache>
    80002fe2:	ffffe097          	auipc	ra,0xffffe
    80002fe6:	c9c080e7          	jalr	-868(ra) # 80000c7e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fea:	0023c797          	auipc	a5,0x23c
    80002fee:	79678793          	addi	a5,a5,1942 # 8023f780 <bcache+0x8000>
    80002ff2:	0023d717          	auipc	a4,0x23d
    80002ff6:	9f670713          	addi	a4,a4,-1546 # 8023f9e8 <bcache+0x8268>
    80002ffa:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ffe:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003002:	00234497          	auipc	s1,0x234
    80003006:	79648493          	addi	s1,s1,1942 # 80237798 <bcache+0x18>
    b->next = bcache.head.next;
    8000300a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000300c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000300e:	00005a17          	auipc	s4,0x5
    80003012:	5baa0a13          	addi	s4,s4,1466 # 800085c8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003016:	2b893783          	ld	a5,696(s2)
    8000301a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000301c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003020:	85d2                	mv	a1,s4
    80003022:	01048513          	addi	a0,s1,16
    80003026:	00001097          	auipc	ra,0x1
    8000302a:	4b0080e7          	jalr	1200(ra) # 800044d6 <initsleeplock>
    bcache.head.next->prev = b;
    8000302e:	2b893783          	ld	a5,696(s2)
    80003032:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003034:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003038:	45848493          	addi	s1,s1,1112
    8000303c:	fd349de3          	bne	s1,s3,80003016 <binit+0x54>
  }
}
    80003040:	70a2                	ld	ra,40(sp)
    80003042:	7402                	ld	s0,32(sp)
    80003044:	64e2                	ld	s1,24(sp)
    80003046:	6942                	ld	s2,16(sp)
    80003048:	69a2                	ld	s3,8(sp)
    8000304a:	6a02                	ld	s4,0(sp)
    8000304c:	6145                	addi	sp,sp,48
    8000304e:	8082                	ret

0000000080003050 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003050:	7179                	addi	sp,sp,-48
    80003052:	f406                	sd	ra,40(sp)
    80003054:	f022                	sd	s0,32(sp)
    80003056:	ec26                	sd	s1,24(sp)
    80003058:	e84a                	sd	s2,16(sp)
    8000305a:	e44e                	sd	s3,8(sp)
    8000305c:	1800                	addi	s0,sp,48
    8000305e:	89aa                	mv	s3,a0
    80003060:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003062:	00234517          	auipc	a0,0x234
    80003066:	71e50513          	addi	a0,a0,1822 # 80237780 <bcache>
    8000306a:	ffffe097          	auipc	ra,0xffffe
    8000306e:	ca4080e7          	jalr	-860(ra) # 80000d0e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003072:	0023d497          	auipc	s1,0x23d
    80003076:	9c64b483          	ld	s1,-1594(s1) # 8023fa38 <bcache+0x82b8>
    8000307a:	0023d797          	auipc	a5,0x23d
    8000307e:	96e78793          	addi	a5,a5,-1682 # 8023f9e8 <bcache+0x8268>
    80003082:	02f48f63          	beq	s1,a5,800030c0 <bread+0x70>
    80003086:	873e                	mv	a4,a5
    80003088:	a021                	j	80003090 <bread+0x40>
    8000308a:	68a4                	ld	s1,80(s1)
    8000308c:	02e48a63          	beq	s1,a4,800030c0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003090:	449c                	lw	a5,8(s1)
    80003092:	ff379ce3          	bne	a5,s3,8000308a <bread+0x3a>
    80003096:	44dc                	lw	a5,12(s1)
    80003098:	ff2799e3          	bne	a5,s2,8000308a <bread+0x3a>
      b->refcnt++;
    8000309c:	40bc                	lw	a5,64(s1)
    8000309e:	2785                	addiw	a5,a5,1
    800030a0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030a2:	00234517          	auipc	a0,0x234
    800030a6:	6de50513          	addi	a0,a0,1758 # 80237780 <bcache>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	d18080e7          	jalr	-744(ra) # 80000dc2 <release>
      acquiresleep(&b->lock);
    800030b2:	01048513          	addi	a0,s1,16
    800030b6:	00001097          	auipc	ra,0x1
    800030ba:	45a080e7          	jalr	1114(ra) # 80004510 <acquiresleep>
      return b;
    800030be:	a8b9                	j	8000311c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030c0:	0023d497          	auipc	s1,0x23d
    800030c4:	9704b483          	ld	s1,-1680(s1) # 8023fa30 <bcache+0x82b0>
    800030c8:	0023d797          	auipc	a5,0x23d
    800030cc:	92078793          	addi	a5,a5,-1760 # 8023f9e8 <bcache+0x8268>
    800030d0:	00f48863          	beq	s1,a5,800030e0 <bread+0x90>
    800030d4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030d6:	40bc                	lw	a5,64(s1)
    800030d8:	cf81                	beqz	a5,800030f0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030da:	64a4                	ld	s1,72(s1)
    800030dc:	fee49de3          	bne	s1,a4,800030d6 <bread+0x86>
  panic("bget: no buffers");
    800030e0:	00005517          	auipc	a0,0x5
    800030e4:	4f050513          	addi	a0,a0,1264 # 800085d0 <syscalls+0xc0>
    800030e8:	ffffd097          	auipc	ra,0xffffd
    800030ec:	460080e7          	jalr	1120(ra) # 80000548 <panic>
      b->dev = dev;
    800030f0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030f4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030f8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030fc:	4785                	li	a5,1
    800030fe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003100:	00234517          	auipc	a0,0x234
    80003104:	68050513          	addi	a0,a0,1664 # 80237780 <bcache>
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	cba080e7          	jalr	-838(ra) # 80000dc2 <release>
      acquiresleep(&b->lock);
    80003110:	01048513          	addi	a0,s1,16
    80003114:	00001097          	auipc	ra,0x1
    80003118:	3fc080e7          	jalr	1020(ra) # 80004510 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000311c:	409c                	lw	a5,0(s1)
    8000311e:	cb89                	beqz	a5,80003130 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003120:	8526                	mv	a0,s1
    80003122:	70a2                	ld	ra,40(sp)
    80003124:	7402                	ld	s0,32(sp)
    80003126:	64e2                	ld	s1,24(sp)
    80003128:	6942                	ld	s2,16(sp)
    8000312a:	69a2                	ld	s3,8(sp)
    8000312c:	6145                	addi	sp,sp,48
    8000312e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003130:	4581                	li	a1,0
    80003132:	8526                	mv	a0,s1
    80003134:	00003097          	auipc	ra,0x3
    80003138:	f38080e7          	jalr	-200(ra) # 8000606c <virtio_disk_rw>
    b->valid = 1;
    8000313c:	4785                	li	a5,1
    8000313e:	c09c                	sw	a5,0(s1)
  return b;
    80003140:	b7c5                	j	80003120 <bread+0xd0>

0000000080003142 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	1000                	addi	s0,sp,32
    8000314c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000314e:	0541                	addi	a0,a0,16
    80003150:	00001097          	auipc	ra,0x1
    80003154:	45a080e7          	jalr	1114(ra) # 800045aa <holdingsleep>
    80003158:	cd01                	beqz	a0,80003170 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000315a:	4585                	li	a1,1
    8000315c:	8526                	mv	a0,s1
    8000315e:	00003097          	auipc	ra,0x3
    80003162:	f0e080e7          	jalr	-242(ra) # 8000606c <virtio_disk_rw>
}
    80003166:	60e2                	ld	ra,24(sp)
    80003168:	6442                	ld	s0,16(sp)
    8000316a:	64a2                	ld	s1,8(sp)
    8000316c:	6105                	addi	sp,sp,32
    8000316e:	8082                	ret
    panic("bwrite");
    80003170:	00005517          	auipc	a0,0x5
    80003174:	47850513          	addi	a0,a0,1144 # 800085e8 <syscalls+0xd8>
    80003178:	ffffd097          	auipc	ra,0xffffd
    8000317c:	3d0080e7          	jalr	976(ra) # 80000548 <panic>

0000000080003180 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003180:	1101                	addi	sp,sp,-32
    80003182:	ec06                	sd	ra,24(sp)
    80003184:	e822                	sd	s0,16(sp)
    80003186:	e426                	sd	s1,8(sp)
    80003188:	e04a                	sd	s2,0(sp)
    8000318a:	1000                	addi	s0,sp,32
    8000318c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000318e:	01050913          	addi	s2,a0,16
    80003192:	854a                	mv	a0,s2
    80003194:	00001097          	auipc	ra,0x1
    80003198:	416080e7          	jalr	1046(ra) # 800045aa <holdingsleep>
    8000319c:	c92d                	beqz	a0,8000320e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000319e:	854a                	mv	a0,s2
    800031a0:	00001097          	auipc	ra,0x1
    800031a4:	3c6080e7          	jalr	966(ra) # 80004566 <releasesleep>

  acquire(&bcache.lock);
    800031a8:	00234517          	auipc	a0,0x234
    800031ac:	5d850513          	addi	a0,a0,1496 # 80237780 <bcache>
    800031b0:	ffffe097          	auipc	ra,0xffffe
    800031b4:	b5e080e7          	jalr	-1186(ra) # 80000d0e <acquire>
  b->refcnt--;
    800031b8:	40bc                	lw	a5,64(s1)
    800031ba:	37fd                	addiw	a5,a5,-1
    800031bc:	0007871b          	sext.w	a4,a5
    800031c0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031c2:	eb05                	bnez	a4,800031f2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031c4:	68bc                	ld	a5,80(s1)
    800031c6:	64b8                	ld	a4,72(s1)
    800031c8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031ca:	64bc                	ld	a5,72(s1)
    800031cc:	68b8                	ld	a4,80(s1)
    800031ce:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031d0:	0023c797          	auipc	a5,0x23c
    800031d4:	5b078793          	addi	a5,a5,1456 # 8023f780 <bcache+0x8000>
    800031d8:	2b87b703          	ld	a4,696(a5)
    800031dc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031de:	0023d717          	auipc	a4,0x23d
    800031e2:	80a70713          	addi	a4,a4,-2038 # 8023f9e8 <bcache+0x8268>
    800031e6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031e8:	2b87b703          	ld	a4,696(a5)
    800031ec:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031ee:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031f2:	00234517          	auipc	a0,0x234
    800031f6:	58e50513          	addi	a0,a0,1422 # 80237780 <bcache>
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	bc8080e7          	jalr	-1080(ra) # 80000dc2 <release>
}
    80003202:	60e2                	ld	ra,24(sp)
    80003204:	6442                	ld	s0,16(sp)
    80003206:	64a2                	ld	s1,8(sp)
    80003208:	6902                	ld	s2,0(sp)
    8000320a:	6105                	addi	sp,sp,32
    8000320c:	8082                	ret
    panic("brelse");
    8000320e:	00005517          	auipc	a0,0x5
    80003212:	3e250513          	addi	a0,a0,994 # 800085f0 <syscalls+0xe0>
    80003216:	ffffd097          	auipc	ra,0xffffd
    8000321a:	332080e7          	jalr	818(ra) # 80000548 <panic>

000000008000321e <bpin>:

void
bpin(struct buf *b) {
    8000321e:	1101                	addi	sp,sp,-32
    80003220:	ec06                	sd	ra,24(sp)
    80003222:	e822                	sd	s0,16(sp)
    80003224:	e426                	sd	s1,8(sp)
    80003226:	1000                	addi	s0,sp,32
    80003228:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000322a:	00234517          	auipc	a0,0x234
    8000322e:	55650513          	addi	a0,a0,1366 # 80237780 <bcache>
    80003232:	ffffe097          	auipc	ra,0xffffe
    80003236:	adc080e7          	jalr	-1316(ra) # 80000d0e <acquire>
  b->refcnt++;
    8000323a:	40bc                	lw	a5,64(s1)
    8000323c:	2785                	addiw	a5,a5,1
    8000323e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003240:	00234517          	auipc	a0,0x234
    80003244:	54050513          	addi	a0,a0,1344 # 80237780 <bcache>
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	b7a080e7          	jalr	-1158(ra) # 80000dc2 <release>
}
    80003250:	60e2                	ld	ra,24(sp)
    80003252:	6442                	ld	s0,16(sp)
    80003254:	64a2                	ld	s1,8(sp)
    80003256:	6105                	addi	sp,sp,32
    80003258:	8082                	ret

000000008000325a <bunpin>:

void
bunpin(struct buf *b) {
    8000325a:	1101                	addi	sp,sp,-32
    8000325c:	ec06                	sd	ra,24(sp)
    8000325e:	e822                	sd	s0,16(sp)
    80003260:	e426                	sd	s1,8(sp)
    80003262:	1000                	addi	s0,sp,32
    80003264:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003266:	00234517          	auipc	a0,0x234
    8000326a:	51a50513          	addi	a0,a0,1306 # 80237780 <bcache>
    8000326e:	ffffe097          	auipc	ra,0xffffe
    80003272:	aa0080e7          	jalr	-1376(ra) # 80000d0e <acquire>
  b->refcnt--;
    80003276:	40bc                	lw	a5,64(s1)
    80003278:	37fd                	addiw	a5,a5,-1
    8000327a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000327c:	00234517          	auipc	a0,0x234
    80003280:	50450513          	addi	a0,a0,1284 # 80237780 <bcache>
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	b3e080e7          	jalr	-1218(ra) # 80000dc2 <release>
}
    8000328c:	60e2                	ld	ra,24(sp)
    8000328e:	6442                	ld	s0,16(sp)
    80003290:	64a2                	ld	s1,8(sp)
    80003292:	6105                	addi	sp,sp,32
    80003294:	8082                	ret

0000000080003296 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003296:	1101                	addi	sp,sp,-32
    80003298:	ec06                	sd	ra,24(sp)
    8000329a:	e822                	sd	s0,16(sp)
    8000329c:	e426                	sd	s1,8(sp)
    8000329e:	e04a                	sd	s2,0(sp)
    800032a0:	1000                	addi	s0,sp,32
    800032a2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032a4:	00d5d59b          	srliw	a1,a1,0xd
    800032a8:	0023d797          	auipc	a5,0x23d
    800032ac:	bb47a783          	lw	a5,-1100(a5) # 8023fe5c <sb+0x1c>
    800032b0:	9dbd                	addw	a1,a1,a5
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	d9e080e7          	jalr	-610(ra) # 80003050 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032ba:	0074f713          	andi	a4,s1,7
    800032be:	4785                	li	a5,1
    800032c0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032c4:	14ce                	slli	s1,s1,0x33
    800032c6:	90d9                	srli	s1,s1,0x36
    800032c8:	00950733          	add	a4,a0,s1
    800032cc:	05874703          	lbu	a4,88(a4)
    800032d0:	00e7f6b3          	and	a3,a5,a4
    800032d4:	c69d                	beqz	a3,80003302 <bfree+0x6c>
    800032d6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032d8:	94aa                	add	s1,s1,a0
    800032da:	fff7c793          	not	a5,a5
    800032de:	8ff9                	and	a5,a5,a4
    800032e0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032e4:	00001097          	auipc	ra,0x1
    800032e8:	104080e7          	jalr	260(ra) # 800043e8 <log_write>
  brelse(bp);
    800032ec:	854a                	mv	a0,s2
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	e92080e7          	jalr	-366(ra) # 80003180 <brelse>
}
    800032f6:	60e2                	ld	ra,24(sp)
    800032f8:	6442                	ld	s0,16(sp)
    800032fa:	64a2                	ld	s1,8(sp)
    800032fc:	6902                	ld	s2,0(sp)
    800032fe:	6105                	addi	sp,sp,32
    80003300:	8082                	ret
    panic("freeing free block");
    80003302:	00005517          	auipc	a0,0x5
    80003306:	2f650513          	addi	a0,a0,758 # 800085f8 <syscalls+0xe8>
    8000330a:	ffffd097          	auipc	ra,0xffffd
    8000330e:	23e080e7          	jalr	574(ra) # 80000548 <panic>

0000000080003312 <balloc>:
{
    80003312:	711d                	addi	sp,sp,-96
    80003314:	ec86                	sd	ra,88(sp)
    80003316:	e8a2                	sd	s0,80(sp)
    80003318:	e4a6                	sd	s1,72(sp)
    8000331a:	e0ca                	sd	s2,64(sp)
    8000331c:	fc4e                	sd	s3,56(sp)
    8000331e:	f852                	sd	s4,48(sp)
    80003320:	f456                	sd	s5,40(sp)
    80003322:	f05a                	sd	s6,32(sp)
    80003324:	ec5e                	sd	s7,24(sp)
    80003326:	e862                	sd	s8,16(sp)
    80003328:	e466                	sd	s9,8(sp)
    8000332a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000332c:	0023d797          	auipc	a5,0x23d
    80003330:	b187a783          	lw	a5,-1256(a5) # 8023fe44 <sb+0x4>
    80003334:	cbd1                	beqz	a5,800033c8 <balloc+0xb6>
    80003336:	8baa                	mv	s7,a0
    80003338:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000333a:	0023db17          	auipc	s6,0x23d
    8000333e:	b06b0b13          	addi	s6,s6,-1274 # 8023fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003342:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003344:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003346:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003348:	6c89                	lui	s9,0x2
    8000334a:	a831                	j	80003366 <balloc+0x54>
    brelse(bp);
    8000334c:	854a                	mv	a0,s2
    8000334e:	00000097          	auipc	ra,0x0
    80003352:	e32080e7          	jalr	-462(ra) # 80003180 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003356:	015c87bb          	addw	a5,s9,s5
    8000335a:	00078a9b          	sext.w	s5,a5
    8000335e:	004b2703          	lw	a4,4(s6)
    80003362:	06eaf363          	bgeu	s5,a4,800033c8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003366:	41fad79b          	sraiw	a5,s5,0x1f
    8000336a:	0137d79b          	srliw	a5,a5,0x13
    8000336e:	015787bb          	addw	a5,a5,s5
    80003372:	40d7d79b          	sraiw	a5,a5,0xd
    80003376:	01cb2583          	lw	a1,28(s6)
    8000337a:	9dbd                	addw	a1,a1,a5
    8000337c:	855e                	mv	a0,s7
    8000337e:	00000097          	auipc	ra,0x0
    80003382:	cd2080e7          	jalr	-814(ra) # 80003050 <bread>
    80003386:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003388:	004b2503          	lw	a0,4(s6)
    8000338c:	000a849b          	sext.w	s1,s5
    80003390:	8662                	mv	a2,s8
    80003392:	faa4fde3          	bgeu	s1,a0,8000334c <balloc+0x3a>
      m = 1 << (bi % 8);
    80003396:	41f6579b          	sraiw	a5,a2,0x1f
    8000339a:	01d7d69b          	srliw	a3,a5,0x1d
    8000339e:	00c6873b          	addw	a4,a3,a2
    800033a2:	00777793          	andi	a5,a4,7
    800033a6:	9f95                	subw	a5,a5,a3
    800033a8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033ac:	4037571b          	sraiw	a4,a4,0x3
    800033b0:	00e906b3          	add	a3,s2,a4
    800033b4:	0586c683          	lbu	a3,88(a3)
    800033b8:	00d7f5b3          	and	a1,a5,a3
    800033bc:	cd91                	beqz	a1,800033d8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033be:	2605                	addiw	a2,a2,1
    800033c0:	2485                	addiw	s1,s1,1
    800033c2:	fd4618e3          	bne	a2,s4,80003392 <balloc+0x80>
    800033c6:	b759                	j	8000334c <balloc+0x3a>
  panic("balloc: out of blocks");
    800033c8:	00005517          	auipc	a0,0x5
    800033cc:	24850513          	addi	a0,a0,584 # 80008610 <syscalls+0x100>
    800033d0:	ffffd097          	auipc	ra,0xffffd
    800033d4:	178080e7          	jalr	376(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033d8:	974a                	add	a4,a4,s2
    800033da:	8fd5                	or	a5,a5,a3
    800033dc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033e0:	854a                	mv	a0,s2
    800033e2:	00001097          	auipc	ra,0x1
    800033e6:	006080e7          	jalr	6(ra) # 800043e8 <log_write>
        brelse(bp);
    800033ea:	854a                	mv	a0,s2
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	d94080e7          	jalr	-620(ra) # 80003180 <brelse>
  bp = bread(dev, bno);
    800033f4:	85a6                	mv	a1,s1
    800033f6:	855e                	mv	a0,s7
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	c58080e7          	jalr	-936(ra) # 80003050 <bread>
    80003400:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003402:	40000613          	li	a2,1024
    80003406:	4581                	li	a1,0
    80003408:	05850513          	addi	a0,a0,88
    8000340c:	ffffe097          	auipc	ra,0xffffe
    80003410:	9fe080e7          	jalr	-1538(ra) # 80000e0a <memset>
  log_write(bp);
    80003414:	854a                	mv	a0,s2
    80003416:	00001097          	auipc	ra,0x1
    8000341a:	fd2080e7          	jalr	-46(ra) # 800043e8 <log_write>
  brelse(bp);
    8000341e:	854a                	mv	a0,s2
    80003420:	00000097          	auipc	ra,0x0
    80003424:	d60080e7          	jalr	-672(ra) # 80003180 <brelse>
}
    80003428:	8526                	mv	a0,s1
    8000342a:	60e6                	ld	ra,88(sp)
    8000342c:	6446                	ld	s0,80(sp)
    8000342e:	64a6                	ld	s1,72(sp)
    80003430:	6906                	ld	s2,64(sp)
    80003432:	79e2                	ld	s3,56(sp)
    80003434:	7a42                	ld	s4,48(sp)
    80003436:	7aa2                	ld	s5,40(sp)
    80003438:	7b02                	ld	s6,32(sp)
    8000343a:	6be2                	ld	s7,24(sp)
    8000343c:	6c42                	ld	s8,16(sp)
    8000343e:	6ca2                	ld	s9,8(sp)
    80003440:	6125                	addi	sp,sp,96
    80003442:	8082                	ret

0000000080003444 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003444:	7179                	addi	sp,sp,-48
    80003446:	f406                	sd	ra,40(sp)
    80003448:	f022                	sd	s0,32(sp)
    8000344a:	ec26                	sd	s1,24(sp)
    8000344c:	e84a                	sd	s2,16(sp)
    8000344e:	e44e                	sd	s3,8(sp)
    80003450:	e052                	sd	s4,0(sp)
    80003452:	1800                	addi	s0,sp,48
    80003454:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003456:	47ad                	li	a5,11
    80003458:	04b7fe63          	bgeu	a5,a1,800034b4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000345c:	ff45849b          	addiw	s1,a1,-12
    80003460:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003464:	0ff00793          	li	a5,255
    80003468:	0ae7e363          	bltu	a5,a4,8000350e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000346c:	08052583          	lw	a1,128(a0)
    80003470:	c5ad                	beqz	a1,800034da <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003472:	00092503          	lw	a0,0(s2)
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	bda080e7          	jalr	-1062(ra) # 80003050 <bread>
    8000347e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003480:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003484:	02049593          	slli	a1,s1,0x20
    80003488:	9181                	srli	a1,a1,0x20
    8000348a:	058a                	slli	a1,a1,0x2
    8000348c:	00b784b3          	add	s1,a5,a1
    80003490:	0004a983          	lw	s3,0(s1)
    80003494:	04098d63          	beqz	s3,800034ee <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003498:	8552                	mv	a0,s4
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	ce6080e7          	jalr	-794(ra) # 80003180 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034a2:	854e                	mv	a0,s3
    800034a4:	70a2                	ld	ra,40(sp)
    800034a6:	7402                	ld	s0,32(sp)
    800034a8:	64e2                	ld	s1,24(sp)
    800034aa:	6942                	ld	s2,16(sp)
    800034ac:	69a2                	ld	s3,8(sp)
    800034ae:	6a02                	ld	s4,0(sp)
    800034b0:	6145                	addi	sp,sp,48
    800034b2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034b4:	02059493          	slli	s1,a1,0x20
    800034b8:	9081                	srli	s1,s1,0x20
    800034ba:	048a                	slli	s1,s1,0x2
    800034bc:	94aa                	add	s1,s1,a0
    800034be:	0504a983          	lw	s3,80(s1)
    800034c2:	fe0990e3          	bnez	s3,800034a2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034c6:	4108                	lw	a0,0(a0)
    800034c8:	00000097          	auipc	ra,0x0
    800034cc:	e4a080e7          	jalr	-438(ra) # 80003312 <balloc>
    800034d0:	0005099b          	sext.w	s3,a0
    800034d4:	0534a823          	sw	s3,80(s1)
    800034d8:	b7e9                	j	800034a2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034da:	4108                	lw	a0,0(a0)
    800034dc:	00000097          	auipc	ra,0x0
    800034e0:	e36080e7          	jalr	-458(ra) # 80003312 <balloc>
    800034e4:	0005059b          	sext.w	a1,a0
    800034e8:	08b92023          	sw	a1,128(s2)
    800034ec:	b759                	j	80003472 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034ee:	00092503          	lw	a0,0(s2)
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	e20080e7          	jalr	-480(ra) # 80003312 <balloc>
    800034fa:	0005099b          	sext.w	s3,a0
    800034fe:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003502:	8552                	mv	a0,s4
    80003504:	00001097          	auipc	ra,0x1
    80003508:	ee4080e7          	jalr	-284(ra) # 800043e8 <log_write>
    8000350c:	b771                	j	80003498 <bmap+0x54>
  panic("bmap: out of range");
    8000350e:	00005517          	auipc	a0,0x5
    80003512:	11a50513          	addi	a0,a0,282 # 80008628 <syscalls+0x118>
    80003516:	ffffd097          	auipc	ra,0xffffd
    8000351a:	032080e7          	jalr	50(ra) # 80000548 <panic>

000000008000351e <iget>:
{
    8000351e:	7179                	addi	sp,sp,-48
    80003520:	f406                	sd	ra,40(sp)
    80003522:	f022                	sd	s0,32(sp)
    80003524:	ec26                	sd	s1,24(sp)
    80003526:	e84a                	sd	s2,16(sp)
    80003528:	e44e                	sd	s3,8(sp)
    8000352a:	e052                	sd	s4,0(sp)
    8000352c:	1800                	addi	s0,sp,48
    8000352e:	89aa                	mv	s3,a0
    80003530:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003532:	0023d517          	auipc	a0,0x23d
    80003536:	92e50513          	addi	a0,a0,-1746 # 8023fe60 <icache>
    8000353a:	ffffd097          	auipc	ra,0xffffd
    8000353e:	7d4080e7          	jalr	2004(ra) # 80000d0e <acquire>
  empty = 0;
    80003542:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003544:	0023d497          	auipc	s1,0x23d
    80003548:	93448493          	addi	s1,s1,-1740 # 8023fe78 <icache+0x18>
    8000354c:	0023e697          	auipc	a3,0x23e
    80003550:	3bc68693          	addi	a3,a3,956 # 80241908 <log>
    80003554:	a039                	j	80003562 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003556:	02090b63          	beqz	s2,8000358c <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000355a:	08848493          	addi	s1,s1,136
    8000355e:	02d48a63          	beq	s1,a3,80003592 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003562:	449c                	lw	a5,8(s1)
    80003564:	fef059e3          	blez	a5,80003556 <iget+0x38>
    80003568:	4098                	lw	a4,0(s1)
    8000356a:	ff3716e3          	bne	a4,s3,80003556 <iget+0x38>
    8000356e:	40d8                	lw	a4,4(s1)
    80003570:	ff4713e3          	bne	a4,s4,80003556 <iget+0x38>
      ip->ref++;
    80003574:	2785                	addiw	a5,a5,1
    80003576:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003578:	0023d517          	auipc	a0,0x23d
    8000357c:	8e850513          	addi	a0,a0,-1816 # 8023fe60 <icache>
    80003580:	ffffe097          	auipc	ra,0xffffe
    80003584:	842080e7          	jalr	-1982(ra) # 80000dc2 <release>
      return ip;
    80003588:	8926                	mv	s2,s1
    8000358a:	a03d                	j	800035b8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000358c:	f7f9                	bnez	a5,8000355a <iget+0x3c>
    8000358e:	8926                	mv	s2,s1
    80003590:	b7e9                	j	8000355a <iget+0x3c>
  if(empty == 0)
    80003592:	02090c63          	beqz	s2,800035ca <iget+0xac>
  ip->dev = dev;
    80003596:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000359a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000359e:	4785                	li	a5,1
    800035a0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035a4:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800035a8:	0023d517          	auipc	a0,0x23d
    800035ac:	8b850513          	addi	a0,a0,-1864 # 8023fe60 <icache>
    800035b0:	ffffe097          	auipc	ra,0xffffe
    800035b4:	812080e7          	jalr	-2030(ra) # 80000dc2 <release>
}
    800035b8:	854a                	mv	a0,s2
    800035ba:	70a2                	ld	ra,40(sp)
    800035bc:	7402                	ld	s0,32(sp)
    800035be:	64e2                	ld	s1,24(sp)
    800035c0:	6942                	ld	s2,16(sp)
    800035c2:	69a2                	ld	s3,8(sp)
    800035c4:	6a02                	ld	s4,0(sp)
    800035c6:	6145                	addi	sp,sp,48
    800035c8:	8082                	ret
    panic("iget: no inodes");
    800035ca:	00005517          	auipc	a0,0x5
    800035ce:	07650513          	addi	a0,a0,118 # 80008640 <syscalls+0x130>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	f76080e7          	jalr	-138(ra) # 80000548 <panic>

00000000800035da <fsinit>:
fsinit(int dev) {
    800035da:	7179                	addi	sp,sp,-48
    800035dc:	f406                	sd	ra,40(sp)
    800035de:	f022                	sd	s0,32(sp)
    800035e0:	ec26                	sd	s1,24(sp)
    800035e2:	e84a                	sd	s2,16(sp)
    800035e4:	e44e                	sd	s3,8(sp)
    800035e6:	1800                	addi	s0,sp,48
    800035e8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035ea:	4585                	li	a1,1
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	a64080e7          	jalr	-1436(ra) # 80003050 <bread>
    800035f4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035f6:	0023d997          	auipc	s3,0x23d
    800035fa:	84a98993          	addi	s3,s3,-1974 # 8023fe40 <sb>
    800035fe:	02000613          	li	a2,32
    80003602:	05850593          	addi	a1,a0,88
    80003606:	854e                	mv	a0,s3
    80003608:	ffffe097          	auipc	ra,0xffffe
    8000360c:	862080e7          	jalr	-1950(ra) # 80000e6a <memmove>
  brelse(bp);
    80003610:	8526                	mv	a0,s1
    80003612:	00000097          	auipc	ra,0x0
    80003616:	b6e080e7          	jalr	-1170(ra) # 80003180 <brelse>
  if(sb.magic != FSMAGIC)
    8000361a:	0009a703          	lw	a4,0(s3)
    8000361e:	102037b7          	lui	a5,0x10203
    80003622:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003626:	02f71263          	bne	a4,a5,8000364a <fsinit+0x70>
  initlog(dev, &sb);
    8000362a:	0023d597          	auipc	a1,0x23d
    8000362e:	81658593          	addi	a1,a1,-2026 # 8023fe40 <sb>
    80003632:	854a                	mv	a0,s2
    80003634:	00001097          	auipc	ra,0x1
    80003638:	b3c080e7          	jalr	-1220(ra) # 80004170 <initlog>
}
    8000363c:	70a2                	ld	ra,40(sp)
    8000363e:	7402                	ld	s0,32(sp)
    80003640:	64e2                	ld	s1,24(sp)
    80003642:	6942                	ld	s2,16(sp)
    80003644:	69a2                	ld	s3,8(sp)
    80003646:	6145                	addi	sp,sp,48
    80003648:	8082                	ret
    panic("invalid file system");
    8000364a:	00005517          	auipc	a0,0x5
    8000364e:	00650513          	addi	a0,a0,6 # 80008650 <syscalls+0x140>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	ef6080e7          	jalr	-266(ra) # 80000548 <panic>

000000008000365a <iinit>:
{
    8000365a:	7179                	addi	sp,sp,-48
    8000365c:	f406                	sd	ra,40(sp)
    8000365e:	f022                	sd	s0,32(sp)
    80003660:	ec26                	sd	s1,24(sp)
    80003662:	e84a                	sd	s2,16(sp)
    80003664:	e44e                	sd	s3,8(sp)
    80003666:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003668:	00005597          	auipc	a1,0x5
    8000366c:	00058593          	mv	a1,a1
    80003670:	0023c517          	auipc	a0,0x23c
    80003674:	7f050513          	addi	a0,a0,2032 # 8023fe60 <icache>
    80003678:	ffffd097          	auipc	ra,0xffffd
    8000367c:	606080e7          	jalr	1542(ra) # 80000c7e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003680:	0023d497          	auipc	s1,0x23d
    80003684:	80848493          	addi	s1,s1,-2040 # 8023fe88 <icache+0x28>
    80003688:	0023e997          	auipc	s3,0x23e
    8000368c:	29098993          	addi	s3,s3,656 # 80241918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003690:	00005917          	auipc	s2,0x5
    80003694:	fe090913          	addi	s2,s2,-32 # 80008670 <syscalls+0x160>
    80003698:	85ca                	mv	a1,s2
    8000369a:	8526                	mv	a0,s1
    8000369c:	00001097          	auipc	ra,0x1
    800036a0:	e3a080e7          	jalr	-454(ra) # 800044d6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036a4:	08848493          	addi	s1,s1,136
    800036a8:	ff3498e3          	bne	s1,s3,80003698 <iinit+0x3e>
}
    800036ac:	70a2                	ld	ra,40(sp)
    800036ae:	7402                	ld	s0,32(sp)
    800036b0:	64e2                	ld	s1,24(sp)
    800036b2:	6942                	ld	s2,16(sp)
    800036b4:	69a2                	ld	s3,8(sp)
    800036b6:	6145                	addi	sp,sp,48
    800036b8:	8082                	ret

00000000800036ba <ialloc>:
{
    800036ba:	715d                	addi	sp,sp,-80
    800036bc:	e486                	sd	ra,72(sp)
    800036be:	e0a2                	sd	s0,64(sp)
    800036c0:	fc26                	sd	s1,56(sp)
    800036c2:	f84a                	sd	s2,48(sp)
    800036c4:	f44e                	sd	s3,40(sp)
    800036c6:	f052                	sd	s4,32(sp)
    800036c8:	ec56                	sd	s5,24(sp)
    800036ca:	e85a                	sd	s6,16(sp)
    800036cc:	e45e                	sd	s7,8(sp)
    800036ce:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036d0:	0023c717          	auipc	a4,0x23c
    800036d4:	77c72703          	lw	a4,1916(a4) # 8023fe4c <sb+0xc>
    800036d8:	4785                	li	a5,1
    800036da:	04e7fa63          	bgeu	a5,a4,8000372e <ialloc+0x74>
    800036de:	8aaa                	mv	s5,a0
    800036e0:	8bae                	mv	s7,a1
    800036e2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036e4:	0023ca17          	auipc	s4,0x23c
    800036e8:	75ca0a13          	addi	s4,s4,1884 # 8023fe40 <sb>
    800036ec:	00048b1b          	sext.w	s6,s1
    800036f0:	0044d593          	srli	a1,s1,0x4
    800036f4:	018a2783          	lw	a5,24(s4)
    800036f8:	9dbd                	addw	a1,a1,a5
    800036fa:	8556                	mv	a0,s5
    800036fc:	00000097          	auipc	ra,0x0
    80003700:	954080e7          	jalr	-1708(ra) # 80003050 <bread>
    80003704:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003706:	05850993          	addi	s3,a0,88
    8000370a:	00f4f793          	andi	a5,s1,15
    8000370e:	079a                	slli	a5,a5,0x6
    80003710:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003712:	00099783          	lh	a5,0(s3)
    80003716:	c785                	beqz	a5,8000373e <ialloc+0x84>
    brelse(bp);
    80003718:	00000097          	auipc	ra,0x0
    8000371c:	a68080e7          	jalr	-1432(ra) # 80003180 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003720:	0485                	addi	s1,s1,1
    80003722:	00ca2703          	lw	a4,12(s4)
    80003726:	0004879b          	sext.w	a5,s1
    8000372a:	fce7e1e3          	bltu	a5,a4,800036ec <ialloc+0x32>
  panic("ialloc: no inodes");
    8000372e:	00005517          	auipc	a0,0x5
    80003732:	f4a50513          	addi	a0,a0,-182 # 80008678 <syscalls+0x168>
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	e12080e7          	jalr	-494(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    8000373e:	04000613          	li	a2,64
    80003742:	4581                	li	a1,0
    80003744:	854e                	mv	a0,s3
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	6c4080e7          	jalr	1732(ra) # 80000e0a <memset>
      dip->type = type;
    8000374e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003752:	854a                	mv	a0,s2
    80003754:	00001097          	auipc	ra,0x1
    80003758:	c94080e7          	jalr	-876(ra) # 800043e8 <log_write>
      brelse(bp);
    8000375c:	854a                	mv	a0,s2
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	a22080e7          	jalr	-1502(ra) # 80003180 <brelse>
      return iget(dev, inum);
    80003766:	85da                	mv	a1,s6
    80003768:	8556                	mv	a0,s5
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	db4080e7          	jalr	-588(ra) # 8000351e <iget>
}
    80003772:	60a6                	ld	ra,72(sp)
    80003774:	6406                	ld	s0,64(sp)
    80003776:	74e2                	ld	s1,56(sp)
    80003778:	7942                	ld	s2,48(sp)
    8000377a:	79a2                	ld	s3,40(sp)
    8000377c:	7a02                	ld	s4,32(sp)
    8000377e:	6ae2                	ld	s5,24(sp)
    80003780:	6b42                	ld	s6,16(sp)
    80003782:	6ba2                	ld	s7,8(sp)
    80003784:	6161                	addi	sp,sp,80
    80003786:	8082                	ret

0000000080003788 <iupdate>:
{
    80003788:	1101                	addi	sp,sp,-32
    8000378a:	ec06                	sd	ra,24(sp)
    8000378c:	e822                	sd	s0,16(sp)
    8000378e:	e426                	sd	s1,8(sp)
    80003790:	e04a                	sd	s2,0(sp)
    80003792:	1000                	addi	s0,sp,32
    80003794:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003796:	415c                	lw	a5,4(a0)
    80003798:	0047d79b          	srliw	a5,a5,0x4
    8000379c:	0023c597          	auipc	a1,0x23c
    800037a0:	6bc5a583          	lw	a1,1724(a1) # 8023fe58 <sb+0x18>
    800037a4:	9dbd                	addw	a1,a1,a5
    800037a6:	4108                	lw	a0,0(a0)
    800037a8:	00000097          	auipc	ra,0x0
    800037ac:	8a8080e7          	jalr	-1880(ra) # 80003050 <bread>
    800037b0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037b2:	05850793          	addi	a5,a0,88
    800037b6:	40c8                	lw	a0,4(s1)
    800037b8:	893d                	andi	a0,a0,15
    800037ba:	051a                	slli	a0,a0,0x6
    800037bc:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037be:	04449703          	lh	a4,68(s1)
    800037c2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037c6:	04649703          	lh	a4,70(s1)
    800037ca:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037ce:	04849703          	lh	a4,72(s1)
    800037d2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037d6:	04a49703          	lh	a4,74(s1)
    800037da:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037de:	44f8                	lw	a4,76(s1)
    800037e0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037e2:	03400613          	li	a2,52
    800037e6:	05048593          	addi	a1,s1,80
    800037ea:	0531                	addi	a0,a0,12
    800037ec:	ffffd097          	auipc	ra,0xffffd
    800037f0:	67e080e7          	jalr	1662(ra) # 80000e6a <memmove>
  log_write(bp);
    800037f4:	854a                	mv	a0,s2
    800037f6:	00001097          	auipc	ra,0x1
    800037fa:	bf2080e7          	jalr	-1038(ra) # 800043e8 <log_write>
  brelse(bp);
    800037fe:	854a                	mv	a0,s2
    80003800:	00000097          	auipc	ra,0x0
    80003804:	980080e7          	jalr	-1664(ra) # 80003180 <brelse>
}
    80003808:	60e2                	ld	ra,24(sp)
    8000380a:	6442                	ld	s0,16(sp)
    8000380c:	64a2                	ld	s1,8(sp)
    8000380e:	6902                	ld	s2,0(sp)
    80003810:	6105                	addi	sp,sp,32
    80003812:	8082                	ret

0000000080003814 <idup>:
{
    80003814:	1101                	addi	sp,sp,-32
    80003816:	ec06                	sd	ra,24(sp)
    80003818:	e822                	sd	s0,16(sp)
    8000381a:	e426                	sd	s1,8(sp)
    8000381c:	1000                	addi	s0,sp,32
    8000381e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003820:	0023c517          	auipc	a0,0x23c
    80003824:	64050513          	addi	a0,a0,1600 # 8023fe60 <icache>
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	4e6080e7          	jalr	1254(ra) # 80000d0e <acquire>
  ip->ref++;
    80003830:	449c                	lw	a5,8(s1)
    80003832:	2785                	addiw	a5,a5,1
    80003834:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003836:	0023c517          	auipc	a0,0x23c
    8000383a:	62a50513          	addi	a0,a0,1578 # 8023fe60 <icache>
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	584080e7          	jalr	1412(ra) # 80000dc2 <release>
}
    80003846:	8526                	mv	a0,s1
    80003848:	60e2                	ld	ra,24(sp)
    8000384a:	6442                	ld	s0,16(sp)
    8000384c:	64a2                	ld	s1,8(sp)
    8000384e:	6105                	addi	sp,sp,32
    80003850:	8082                	ret

0000000080003852 <ilock>:
{
    80003852:	1101                	addi	sp,sp,-32
    80003854:	ec06                	sd	ra,24(sp)
    80003856:	e822                	sd	s0,16(sp)
    80003858:	e426                	sd	s1,8(sp)
    8000385a:	e04a                	sd	s2,0(sp)
    8000385c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000385e:	c115                	beqz	a0,80003882 <ilock+0x30>
    80003860:	84aa                	mv	s1,a0
    80003862:	451c                	lw	a5,8(a0)
    80003864:	00f05f63          	blez	a5,80003882 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003868:	0541                	addi	a0,a0,16
    8000386a:	00001097          	auipc	ra,0x1
    8000386e:	ca6080e7          	jalr	-858(ra) # 80004510 <acquiresleep>
  if(ip->valid == 0){
    80003872:	40bc                	lw	a5,64(s1)
    80003874:	cf99                	beqz	a5,80003892 <ilock+0x40>
}
    80003876:	60e2                	ld	ra,24(sp)
    80003878:	6442                	ld	s0,16(sp)
    8000387a:	64a2                	ld	s1,8(sp)
    8000387c:	6902                	ld	s2,0(sp)
    8000387e:	6105                	addi	sp,sp,32
    80003880:	8082                	ret
    panic("ilock");
    80003882:	00005517          	auipc	a0,0x5
    80003886:	e0e50513          	addi	a0,a0,-498 # 80008690 <syscalls+0x180>
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	cbe080e7          	jalr	-834(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003892:	40dc                	lw	a5,4(s1)
    80003894:	0047d79b          	srliw	a5,a5,0x4
    80003898:	0023c597          	auipc	a1,0x23c
    8000389c:	5c05a583          	lw	a1,1472(a1) # 8023fe58 <sb+0x18>
    800038a0:	9dbd                	addw	a1,a1,a5
    800038a2:	4088                	lw	a0,0(s1)
    800038a4:	fffff097          	auipc	ra,0xfffff
    800038a8:	7ac080e7          	jalr	1964(ra) # 80003050 <bread>
    800038ac:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038ae:	05850593          	addi	a1,a0,88
    800038b2:	40dc                	lw	a5,4(s1)
    800038b4:	8bbd                	andi	a5,a5,15
    800038b6:	079a                	slli	a5,a5,0x6
    800038b8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038ba:	00059783          	lh	a5,0(a1)
    800038be:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038c2:	00259783          	lh	a5,2(a1)
    800038c6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038ca:	00459783          	lh	a5,4(a1)
    800038ce:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038d2:	00659783          	lh	a5,6(a1)
    800038d6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038da:	459c                	lw	a5,8(a1)
    800038dc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038de:	03400613          	li	a2,52
    800038e2:	05b1                	addi	a1,a1,12
    800038e4:	05048513          	addi	a0,s1,80
    800038e8:	ffffd097          	auipc	ra,0xffffd
    800038ec:	582080e7          	jalr	1410(ra) # 80000e6a <memmove>
    brelse(bp);
    800038f0:	854a                	mv	a0,s2
    800038f2:	00000097          	auipc	ra,0x0
    800038f6:	88e080e7          	jalr	-1906(ra) # 80003180 <brelse>
    ip->valid = 1;
    800038fa:	4785                	li	a5,1
    800038fc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038fe:	04449783          	lh	a5,68(s1)
    80003902:	fbb5                	bnez	a5,80003876 <ilock+0x24>
      panic("ilock: no type");
    80003904:	00005517          	auipc	a0,0x5
    80003908:	d9450513          	addi	a0,a0,-620 # 80008698 <syscalls+0x188>
    8000390c:	ffffd097          	auipc	ra,0xffffd
    80003910:	c3c080e7          	jalr	-964(ra) # 80000548 <panic>

0000000080003914 <iunlock>:
{
    80003914:	1101                	addi	sp,sp,-32
    80003916:	ec06                	sd	ra,24(sp)
    80003918:	e822                	sd	s0,16(sp)
    8000391a:	e426                	sd	s1,8(sp)
    8000391c:	e04a                	sd	s2,0(sp)
    8000391e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003920:	c905                	beqz	a0,80003950 <iunlock+0x3c>
    80003922:	84aa                	mv	s1,a0
    80003924:	01050913          	addi	s2,a0,16
    80003928:	854a                	mv	a0,s2
    8000392a:	00001097          	auipc	ra,0x1
    8000392e:	c80080e7          	jalr	-896(ra) # 800045aa <holdingsleep>
    80003932:	cd19                	beqz	a0,80003950 <iunlock+0x3c>
    80003934:	449c                	lw	a5,8(s1)
    80003936:	00f05d63          	blez	a5,80003950 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000393a:	854a                	mv	a0,s2
    8000393c:	00001097          	auipc	ra,0x1
    80003940:	c2a080e7          	jalr	-982(ra) # 80004566 <releasesleep>
}
    80003944:	60e2                	ld	ra,24(sp)
    80003946:	6442                	ld	s0,16(sp)
    80003948:	64a2                	ld	s1,8(sp)
    8000394a:	6902                	ld	s2,0(sp)
    8000394c:	6105                	addi	sp,sp,32
    8000394e:	8082                	ret
    panic("iunlock");
    80003950:	00005517          	auipc	a0,0x5
    80003954:	d5850513          	addi	a0,a0,-680 # 800086a8 <syscalls+0x198>
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	bf0080e7          	jalr	-1040(ra) # 80000548 <panic>

0000000080003960 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003960:	7179                	addi	sp,sp,-48
    80003962:	f406                	sd	ra,40(sp)
    80003964:	f022                	sd	s0,32(sp)
    80003966:	ec26                	sd	s1,24(sp)
    80003968:	e84a                	sd	s2,16(sp)
    8000396a:	e44e                	sd	s3,8(sp)
    8000396c:	e052                	sd	s4,0(sp)
    8000396e:	1800                	addi	s0,sp,48
    80003970:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003972:	05050493          	addi	s1,a0,80
    80003976:	08050913          	addi	s2,a0,128
    8000397a:	a021                	j	80003982 <itrunc+0x22>
    8000397c:	0491                	addi	s1,s1,4
    8000397e:	01248d63          	beq	s1,s2,80003998 <itrunc+0x38>
    if(ip->addrs[i]){
    80003982:	408c                	lw	a1,0(s1)
    80003984:	dde5                	beqz	a1,8000397c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003986:	0009a503          	lw	a0,0(s3)
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	90c080e7          	jalr	-1780(ra) # 80003296 <bfree>
      ip->addrs[i] = 0;
    80003992:	0004a023          	sw	zero,0(s1)
    80003996:	b7dd                	j	8000397c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003998:	0809a583          	lw	a1,128(s3)
    8000399c:	e185                	bnez	a1,800039bc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000399e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039a2:	854e                	mv	a0,s3
    800039a4:	00000097          	auipc	ra,0x0
    800039a8:	de4080e7          	jalr	-540(ra) # 80003788 <iupdate>
}
    800039ac:	70a2                	ld	ra,40(sp)
    800039ae:	7402                	ld	s0,32(sp)
    800039b0:	64e2                	ld	s1,24(sp)
    800039b2:	6942                	ld	s2,16(sp)
    800039b4:	69a2                	ld	s3,8(sp)
    800039b6:	6a02                	ld	s4,0(sp)
    800039b8:	6145                	addi	sp,sp,48
    800039ba:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039bc:	0009a503          	lw	a0,0(s3)
    800039c0:	fffff097          	auipc	ra,0xfffff
    800039c4:	690080e7          	jalr	1680(ra) # 80003050 <bread>
    800039c8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039ca:	05850493          	addi	s1,a0,88
    800039ce:	45850913          	addi	s2,a0,1112
    800039d2:	a811                	j	800039e6 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039d4:	0009a503          	lw	a0,0(s3)
    800039d8:	00000097          	auipc	ra,0x0
    800039dc:	8be080e7          	jalr	-1858(ra) # 80003296 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039e0:	0491                	addi	s1,s1,4
    800039e2:	01248563          	beq	s1,s2,800039ec <itrunc+0x8c>
      if(a[j])
    800039e6:	408c                	lw	a1,0(s1)
    800039e8:	dde5                	beqz	a1,800039e0 <itrunc+0x80>
    800039ea:	b7ed                	j	800039d4 <itrunc+0x74>
    brelse(bp);
    800039ec:	8552                	mv	a0,s4
    800039ee:	fffff097          	auipc	ra,0xfffff
    800039f2:	792080e7          	jalr	1938(ra) # 80003180 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039f6:	0809a583          	lw	a1,128(s3)
    800039fa:	0009a503          	lw	a0,0(s3)
    800039fe:	00000097          	auipc	ra,0x0
    80003a02:	898080e7          	jalr	-1896(ra) # 80003296 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a06:	0809a023          	sw	zero,128(s3)
    80003a0a:	bf51                	j	8000399e <itrunc+0x3e>

0000000080003a0c <iput>:
{
    80003a0c:	1101                	addi	sp,sp,-32
    80003a0e:	ec06                	sd	ra,24(sp)
    80003a10:	e822                	sd	s0,16(sp)
    80003a12:	e426                	sd	s1,8(sp)
    80003a14:	e04a                	sd	s2,0(sp)
    80003a16:	1000                	addi	s0,sp,32
    80003a18:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a1a:	0023c517          	auipc	a0,0x23c
    80003a1e:	44650513          	addi	a0,a0,1094 # 8023fe60 <icache>
    80003a22:	ffffd097          	auipc	ra,0xffffd
    80003a26:	2ec080e7          	jalr	748(ra) # 80000d0e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a2a:	4498                	lw	a4,8(s1)
    80003a2c:	4785                	li	a5,1
    80003a2e:	02f70363          	beq	a4,a5,80003a54 <iput+0x48>
  ip->ref--;
    80003a32:	449c                	lw	a5,8(s1)
    80003a34:	37fd                	addiw	a5,a5,-1
    80003a36:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a38:	0023c517          	auipc	a0,0x23c
    80003a3c:	42850513          	addi	a0,a0,1064 # 8023fe60 <icache>
    80003a40:	ffffd097          	auipc	ra,0xffffd
    80003a44:	382080e7          	jalr	898(ra) # 80000dc2 <release>
}
    80003a48:	60e2                	ld	ra,24(sp)
    80003a4a:	6442                	ld	s0,16(sp)
    80003a4c:	64a2                	ld	s1,8(sp)
    80003a4e:	6902                	ld	s2,0(sp)
    80003a50:	6105                	addi	sp,sp,32
    80003a52:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a54:	40bc                	lw	a5,64(s1)
    80003a56:	dff1                	beqz	a5,80003a32 <iput+0x26>
    80003a58:	04a49783          	lh	a5,74(s1)
    80003a5c:	fbf9                	bnez	a5,80003a32 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a5e:	01048913          	addi	s2,s1,16
    80003a62:	854a                	mv	a0,s2
    80003a64:	00001097          	auipc	ra,0x1
    80003a68:	aac080e7          	jalr	-1364(ra) # 80004510 <acquiresleep>
    release(&icache.lock);
    80003a6c:	0023c517          	auipc	a0,0x23c
    80003a70:	3f450513          	addi	a0,a0,1012 # 8023fe60 <icache>
    80003a74:	ffffd097          	auipc	ra,0xffffd
    80003a78:	34e080e7          	jalr	846(ra) # 80000dc2 <release>
    itrunc(ip);
    80003a7c:	8526                	mv	a0,s1
    80003a7e:	00000097          	auipc	ra,0x0
    80003a82:	ee2080e7          	jalr	-286(ra) # 80003960 <itrunc>
    ip->type = 0;
    80003a86:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a8a:	8526                	mv	a0,s1
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	cfc080e7          	jalr	-772(ra) # 80003788 <iupdate>
    ip->valid = 0;
    80003a94:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a98:	854a                	mv	a0,s2
    80003a9a:	00001097          	auipc	ra,0x1
    80003a9e:	acc080e7          	jalr	-1332(ra) # 80004566 <releasesleep>
    acquire(&icache.lock);
    80003aa2:	0023c517          	auipc	a0,0x23c
    80003aa6:	3be50513          	addi	a0,a0,958 # 8023fe60 <icache>
    80003aaa:	ffffd097          	auipc	ra,0xffffd
    80003aae:	264080e7          	jalr	612(ra) # 80000d0e <acquire>
    80003ab2:	b741                	j	80003a32 <iput+0x26>

0000000080003ab4 <iunlockput>:
{
    80003ab4:	1101                	addi	sp,sp,-32
    80003ab6:	ec06                	sd	ra,24(sp)
    80003ab8:	e822                	sd	s0,16(sp)
    80003aba:	e426                	sd	s1,8(sp)
    80003abc:	1000                	addi	s0,sp,32
    80003abe:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	e54080e7          	jalr	-428(ra) # 80003914 <iunlock>
  iput(ip);
    80003ac8:	8526                	mv	a0,s1
    80003aca:	00000097          	auipc	ra,0x0
    80003ace:	f42080e7          	jalr	-190(ra) # 80003a0c <iput>
}
    80003ad2:	60e2                	ld	ra,24(sp)
    80003ad4:	6442                	ld	s0,16(sp)
    80003ad6:	64a2                	ld	s1,8(sp)
    80003ad8:	6105                	addi	sp,sp,32
    80003ada:	8082                	ret

0000000080003adc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003adc:	1141                	addi	sp,sp,-16
    80003ade:	e422                	sd	s0,8(sp)
    80003ae0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ae2:	411c                	lw	a5,0(a0)
    80003ae4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ae6:	415c                	lw	a5,4(a0)
    80003ae8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003aea:	04451783          	lh	a5,68(a0)
    80003aee:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003af2:	04a51783          	lh	a5,74(a0)
    80003af6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003afa:	04c56783          	lwu	a5,76(a0)
    80003afe:	e99c                	sd	a5,16(a1)
}
    80003b00:	6422                	ld	s0,8(sp)
    80003b02:	0141                	addi	sp,sp,16
    80003b04:	8082                	ret

0000000080003b06 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b06:	457c                	lw	a5,76(a0)
    80003b08:	0ed7e963          	bltu	a5,a3,80003bfa <readi+0xf4>
{
    80003b0c:	7159                	addi	sp,sp,-112
    80003b0e:	f486                	sd	ra,104(sp)
    80003b10:	f0a2                	sd	s0,96(sp)
    80003b12:	eca6                	sd	s1,88(sp)
    80003b14:	e8ca                	sd	s2,80(sp)
    80003b16:	e4ce                	sd	s3,72(sp)
    80003b18:	e0d2                	sd	s4,64(sp)
    80003b1a:	fc56                	sd	s5,56(sp)
    80003b1c:	f85a                	sd	s6,48(sp)
    80003b1e:	f45e                	sd	s7,40(sp)
    80003b20:	f062                	sd	s8,32(sp)
    80003b22:	ec66                	sd	s9,24(sp)
    80003b24:	e86a                	sd	s10,16(sp)
    80003b26:	e46e                	sd	s11,8(sp)
    80003b28:	1880                	addi	s0,sp,112
    80003b2a:	8baa                	mv	s7,a0
    80003b2c:	8c2e                	mv	s8,a1
    80003b2e:	8ab2                	mv	s5,a2
    80003b30:	84b6                	mv	s1,a3
    80003b32:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b34:	9f35                	addw	a4,a4,a3
    return 0;
    80003b36:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b38:	0ad76063          	bltu	a4,a3,80003bd8 <readi+0xd2>
  if(off + n > ip->size)
    80003b3c:	00e7f463          	bgeu	a5,a4,80003b44 <readi+0x3e>
    n = ip->size - off;
    80003b40:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b44:	0a0b0963          	beqz	s6,80003bf6 <readi+0xf0>
    80003b48:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b4a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b4e:	5cfd                	li	s9,-1
    80003b50:	a82d                	j	80003b8a <readi+0x84>
    80003b52:	020a1d93          	slli	s11,s4,0x20
    80003b56:	020ddd93          	srli	s11,s11,0x20
    80003b5a:	05890613          	addi	a2,s2,88
    80003b5e:	86ee                	mv	a3,s11
    80003b60:	963a                	add	a2,a2,a4
    80003b62:	85d6                	mv	a1,s5
    80003b64:	8562                	mv	a0,s8
    80003b66:	fffff097          	auipc	ra,0xfffff
    80003b6a:	b0a080e7          	jalr	-1270(ra) # 80002670 <either_copyout>
    80003b6e:	05950d63          	beq	a0,s9,80003bc8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b72:	854a                	mv	a0,s2
    80003b74:	fffff097          	auipc	ra,0xfffff
    80003b78:	60c080e7          	jalr	1548(ra) # 80003180 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b7c:	013a09bb          	addw	s3,s4,s3
    80003b80:	009a04bb          	addw	s1,s4,s1
    80003b84:	9aee                	add	s5,s5,s11
    80003b86:	0569f763          	bgeu	s3,s6,80003bd4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b8a:	000ba903          	lw	s2,0(s7)
    80003b8e:	00a4d59b          	srliw	a1,s1,0xa
    80003b92:	855e                	mv	a0,s7
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	8b0080e7          	jalr	-1872(ra) # 80003444 <bmap>
    80003b9c:	0005059b          	sext.w	a1,a0
    80003ba0:	854a                	mv	a0,s2
    80003ba2:	fffff097          	auipc	ra,0xfffff
    80003ba6:	4ae080e7          	jalr	1198(ra) # 80003050 <bread>
    80003baa:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bac:	3ff4f713          	andi	a4,s1,1023
    80003bb0:	40ed07bb          	subw	a5,s10,a4
    80003bb4:	413b06bb          	subw	a3,s6,s3
    80003bb8:	8a3e                	mv	s4,a5
    80003bba:	2781                	sext.w	a5,a5
    80003bbc:	0006861b          	sext.w	a2,a3
    80003bc0:	f8f679e3          	bgeu	a2,a5,80003b52 <readi+0x4c>
    80003bc4:	8a36                	mv	s4,a3
    80003bc6:	b771                	j	80003b52 <readi+0x4c>
      brelse(bp);
    80003bc8:	854a                	mv	a0,s2
    80003bca:	fffff097          	auipc	ra,0xfffff
    80003bce:	5b6080e7          	jalr	1462(ra) # 80003180 <brelse>
      tot = -1;
    80003bd2:	59fd                	li	s3,-1
  }
  return tot;
    80003bd4:	0009851b          	sext.w	a0,s3
}
    80003bd8:	70a6                	ld	ra,104(sp)
    80003bda:	7406                	ld	s0,96(sp)
    80003bdc:	64e6                	ld	s1,88(sp)
    80003bde:	6946                	ld	s2,80(sp)
    80003be0:	69a6                	ld	s3,72(sp)
    80003be2:	6a06                	ld	s4,64(sp)
    80003be4:	7ae2                	ld	s5,56(sp)
    80003be6:	7b42                	ld	s6,48(sp)
    80003be8:	7ba2                	ld	s7,40(sp)
    80003bea:	7c02                	ld	s8,32(sp)
    80003bec:	6ce2                	ld	s9,24(sp)
    80003bee:	6d42                	ld	s10,16(sp)
    80003bf0:	6da2                	ld	s11,8(sp)
    80003bf2:	6165                	addi	sp,sp,112
    80003bf4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bf6:	89da                	mv	s3,s6
    80003bf8:	bff1                	j	80003bd4 <readi+0xce>
    return 0;
    80003bfa:	4501                	li	a0,0
}
    80003bfc:	8082                	ret

0000000080003bfe <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bfe:	457c                	lw	a5,76(a0)
    80003c00:	10d7e763          	bltu	a5,a3,80003d0e <writei+0x110>
{
    80003c04:	7159                	addi	sp,sp,-112
    80003c06:	f486                	sd	ra,104(sp)
    80003c08:	f0a2                	sd	s0,96(sp)
    80003c0a:	eca6                	sd	s1,88(sp)
    80003c0c:	e8ca                	sd	s2,80(sp)
    80003c0e:	e4ce                	sd	s3,72(sp)
    80003c10:	e0d2                	sd	s4,64(sp)
    80003c12:	fc56                	sd	s5,56(sp)
    80003c14:	f85a                	sd	s6,48(sp)
    80003c16:	f45e                	sd	s7,40(sp)
    80003c18:	f062                	sd	s8,32(sp)
    80003c1a:	ec66                	sd	s9,24(sp)
    80003c1c:	e86a                	sd	s10,16(sp)
    80003c1e:	e46e                	sd	s11,8(sp)
    80003c20:	1880                	addi	s0,sp,112
    80003c22:	8baa                	mv	s7,a0
    80003c24:	8c2e                	mv	s8,a1
    80003c26:	8ab2                	mv	s5,a2
    80003c28:	8936                	mv	s2,a3
    80003c2a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c2c:	00e687bb          	addw	a5,a3,a4
    80003c30:	0ed7e163          	bltu	a5,a3,80003d12 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c34:	00043737          	lui	a4,0x43
    80003c38:	0cf76f63          	bltu	a4,a5,80003d16 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c3c:	0a0b0863          	beqz	s6,80003cec <writei+0xee>
    80003c40:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c42:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c46:	5cfd                	li	s9,-1
    80003c48:	a091                	j	80003c8c <writei+0x8e>
    80003c4a:	02099d93          	slli	s11,s3,0x20
    80003c4e:	020ddd93          	srli	s11,s11,0x20
    80003c52:	05848513          	addi	a0,s1,88
    80003c56:	86ee                	mv	a3,s11
    80003c58:	8656                	mv	a2,s5
    80003c5a:	85e2                	mv	a1,s8
    80003c5c:	953a                	add	a0,a0,a4
    80003c5e:	fffff097          	auipc	ra,0xfffff
    80003c62:	a68080e7          	jalr	-1432(ra) # 800026c6 <either_copyin>
    80003c66:	07950263          	beq	a0,s9,80003cca <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003c6a:	8526                	mv	a0,s1
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	77c080e7          	jalr	1916(ra) # 800043e8 <log_write>
    brelse(bp);
    80003c74:	8526                	mv	a0,s1
    80003c76:	fffff097          	auipc	ra,0xfffff
    80003c7a:	50a080e7          	jalr	1290(ra) # 80003180 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c7e:	01498a3b          	addw	s4,s3,s4
    80003c82:	0129893b          	addw	s2,s3,s2
    80003c86:	9aee                	add	s5,s5,s11
    80003c88:	056a7763          	bgeu	s4,s6,80003cd6 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c8c:	000ba483          	lw	s1,0(s7)
    80003c90:	00a9559b          	srliw	a1,s2,0xa
    80003c94:	855e                	mv	a0,s7
    80003c96:	fffff097          	auipc	ra,0xfffff
    80003c9a:	7ae080e7          	jalr	1966(ra) # 80003444 <bmap>
    80003c9e:	0005059b          	sext.w	a1,a0
    80003ca2:	8526                	mv	a0,s1
    80003ca4:	fffff097          	auipc	ra,0xfffff
    80003ca8:	3ac080e7          	jalr	940(ra) # 80003050 <bread>
    80003cac:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cae:	3ff97713          	andi	a4,s2,1023
    80003cb2:	40ed07bb          	subw	a5,s10,a4
    80003cb6:	414b06bb          	subw	a3,s6,s4
    80003cba:	89be                	mv	s3,a5
    80003cbc:	2781                	sext.w	a5,a5
    80003cbe:	0006861b          	sext.w	a2,a3
    80003cc2:	f8f674e3          	bgeu	a2,a5,80003c4a <writei+0x4c>
    80003cc6:	89b6                	mv	s3,a3
    80003cc8:	b749                	j	80003c4a <writei+0x4c>
      brelse(bp);
    80003cca:	8526                	mv	a0,s1
    80003ccc:	fffff097          	auipc	ra,0xfffff
    80003cd0:	4b4080e7          	jalr	1204(ra) # 80003180 <brelse>
      n = -1;
    80003cd4:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003cd6:	04cba783          	lw	a5,76(s7)
    80003cda:	0127f463          	bgeu	a5,s2,80003ce2 <writei+0xe4>
      ip->size = off;
    80003cde:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003ce2:	855e                	mv	a0,s7
    80003ce4:	00000097          	auipc	ra,0x0
    80003ce8:	aa4080e7          	jalr	-1372(ra) # 80003788 <iupdate>
  }

  return n;
    80003cec:	000b051b          	sext.w	a0,s6
}
    80003cf0:	70a6                	ld	ra,104(sp)
    80003cf2:	7406                	ld	s0,96(sp)
    80003cf4:	64e6                	ld	s1,88(sp)
    80003cf6:	6946                	ld	s2,80(sp)
    80003cf8:	69a6                	ld	s3,72(sp)
    80003cfa:	6a06                	ld	s4,64(sp)
    80003cfc:	7ae2                	ld	s5,56(sp)
    80003cfe:	7b42                	ld	s6,48(sp)
    80003d00:	7ba2                	ld	s7,40(sp)
    80003d02:	7c02                	ld	s8,32(sp)
    80003d04:	6ce2                	ld	s9,24(sp)
    80003d06:	6d42                	ld	s10,16(sp)
    80003d08:	6da2                	ld	s11,8(sp)
    80003d0a:	6165                	addi	sp,sp,112
    80003d0c:	8082                	ret
    return -1;
    80003d0e:	557d                	li	a0,-1
}
    80003d10:	8082                	ret
    return -1;
    80003d12:	557d                	li	a0,-1
    80003d14:	bff1                	j	80003cf0 <writei+0xf2>
    return -1;
    80003d16:	557d                	li	a0,-1
    80003d18:	bfe1                	j	80003cf0 <writei+0xf2>

0000000080003d1a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d1a:	1141                	addi	sp,sp,-16
    80003d1c:	e406                	sd	ra,8(sp)
    80003d1e:	e022                	sd	s0,0(sp)
    80003d20:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d22:	4639                	li	a2,14
    80003d24:	ffffd097          	auipc	ra,0xffffd
    80003d28:	1c2080e7          	jalr	450(ra) # 80000ee6 <strncmp>
}
    80003d2c:	60a2                	ld	ra,8(sp)
    80003d2e:	6402                	ld	s0,0(sp)
    80003d30:	0141                	addi	sp,sp,16
    80003d32:	8082                	ret

0000000080003d34 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d34:	7139                	addi	sp,sp,-64
    80003d36:	fc06                	sd	ra,56(sp)
    80003d38:	f822                	sd	s0,48(sp)
    80003d3a:	f426                	sd	s1,40(sp)
    80003d3c:	f04a                	sd	s2,32(sp)
    80003d3e:	ec4e                	sd	s3,24(sp)
    80003d40:	e852                	sd	s4,16(sp)
    80003d42:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d44:	04451703          	lh	a4,68(a0)
    80003d48:	4785                	li	a5,1
    80003d4a:	00f71a63          	bne	a4,a5,80003d5e <dirlookup+0x2a>
    80003d4e:	892a                	mv	s2,a0
    80003d50:	89ae                	mv	s3,a1
    80003d52:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d54:	457c                	lw	a5,76(a0)
    80003d56:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d58:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d5a:	e79d                	bnez	a5,80003d88 <dirlookup+0x54>
    80003d5c:	a8a5                	j	80003dd4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d5e:	00005517          	auipc	a0,0x5
    80003d62:	95250513          	addi	a0,a0,-1710 # 800086b0 <syscalls+0x1a0>
    80003d66:	ffffc097          	auipc	ra,0xffffc
    80003d6a:	7e2080e7          	jalr	2018(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003d6e:	00005517          	auipc	a0,0x5
    80003d72:	95a50513          	addi	a0,a0,-1702 # 800086c8 <syscalls+0x1b8>
    80003d76:	ffffc097          	auipc	ra,0xffffc
    80003d7a:	7d2080e7          	jalr	2002(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d7e:	24c1                	addiw	s1,s1,16
    80003d80:	04c92783          	lw	a5,76(s2)
    80003d84:	04f4f763          	bgeu	s1,a5,80003dd2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d88:	4741                	li	a4,16
    80003d8a:	86a6                	mv	a3,s1
    80003d8c:	fc040613          	addi	a2,s0,-64
    80003d90:	4581                	li	a1,0
    80003d92:	854a                	mv	a0,s2
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	d72080e7          	jalr	-654(ra) # 80003b06 <readi>
    80003d9c:	47c1                	li	a5,16
    80003d9e:	fcf518e3          	bne	a0,a5,80003d6e <dirlookup+0x3a>
    if(de.inum == 0)
    80003da2:	fc045783          	lhu	a5,-64(s0)
    80003da6:	dfe1                	beqz	a5,80003d7e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003da8:	fc240593          	addi	a1,s0,-62
    80003dac:	854e                	mv	a0,s3
    80003dae:	00000097          	auipc	ra,0x0
    80003db2:	f6c080e7          	jalr	-148(ra) # 80003d1a <namecmp>
    80003db6:	f561                	bnez	a0,80003d7e <dirlookup+0x4a>
      if(poff)
    80003db8:	000a0463          	beqz	s4,80003dc0 <dirlookup+0x8c>
        *poff = off;
    80003dbc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003dc0:	fc045583          	lhu	a1,-64(s0)
    80003dc4:	00092503          	lw	a0,0(s2)
    80003dc8:	fffff097          	auipc	ra,0xfffff
    80003dcc:	756080e7          	jalr	1878(ra) # 8000351e <iget>
    80003dd0:	a011                	j	80003dd4 <dirlookup+0xa0>
  return 0;
    80003dd2:	4501                	li	a0,0
}
    80003dd4:	70e2                	ld	ra,56(sp)
    80003dd6:	7442                	ld	s0,48(sp)
    80003dd8:	74a2                	ld	s1,40(sp)
    80003dda:	7902                	ld	s2,32(sp)
    80003ddc:	69e2                	ld	s3,24(sp)
    80003dde:	6a42                	ld	s4,16(sp)
    80003de0:	6121                	addi	sp,sp,64
    80003de2:	8082                	ret

0000000080003de4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003de4:	711d                	addi	sp,sp,-96
    80003de6:	ec86                	sd	ra,88(sp)
    80003de8:	e8a2                	sd	s0,80(sp)
    80003dea:	e4a6                	sd	s1,72(sp)
    80003dec:	e0ca                	sd	s2,64(sp)
    80003dee:	fc4e                	sd	s3,56(sp)
    80003df0:	f852                	sd	s4,48(sp)
    80003df2:	f456                	sd	s5,40(sp)
    80003df4:	f05a                	sd	s6,32(sp)
    80003df6:	ec5e                	sd	s7,24(sp)
    80003df8:	e862                	sd	s8,16(sp)
    80003dfa:	e466                	sd	s9,8(sp)
    80003dfc:	1080                	addi	s0,sp,96
    80003dfe:	84aa                	mv	s1,a0
    80003e00:	8b2e                	mv	s6,a1
    80003e02:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e04:	00054703          	lbu	a4,0(a0)
    80003e08:	02f00793          	li	a5,47
    80003e0c:	02f70363          	beq	a4,a5,80003e32 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e10:	ffffe097          	auipc	ra,0xffffe
    80003e14:	dee080e7          	jalr	-530(ra) # 80001bfe <myproc>
    80003e18:	15053503          	ld	a0,336(a0)
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	9f8080e7          	jalr	-1544(ra) # 80003814 <idup>
    80003e24:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e26:	02f00913          	li	s2,47
  len = path - s;
    80003e2a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e2c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e2e:	4c05                	li	s8,1
    80003e30:	a865                	j	80003ee8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e32:	4585                	li	a1,1
    80003e34:	4505                	li	a0,1
    80003e36:	fffff097          	auipc	ra,0xfffff
    80003e3a:	6e8080e7          	jalr	1768(ra) # 8000351e <iget>
    80003e3e:	89aa                	mv	s3,a0
    80003e40:	b7dd                	j	80003e26 <namex+0x42>
      iunlockput(ip);
    80003e42:	854e                	mv	a0,s3
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	c70080e7          	jalr	-912(ra) # 80003ab4 <iunlockput>
      return 0;
    80003e4c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e4e:	854e                	mv	a0,s3
    80003e50:	60e6                	ld	ra,88(sp)
    80003e52:	6446                	ld	s0,80(sp)
    80003e54:	64a6                	ld	s1,72(sp)
    80003e56:	6906                	ld	s2,64(sp)
    80003e58:	79e2                	ld	s3,56(sp)
    80003e5a:	7a42                	ld	s4,48(sp)
    80003e5c:	7aa2                	ld	s5,40(sp)
    80003e5e:	7b02                	ld	s6,32(sp)
    80003e60:	6be2                	ld	s7,24(sp)
    80003e62:	6c42                	ld	s8,16(sp)
    80003e64:	6ca2                	ld	s9,8(sp)
    80003e66:	6125                	addi	sp,sp,96
    80003e68:	8082                	ret
      iunlock(ip);
    80003e6a:	854e                	mv	a0,s3
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	aa8080e7          	jalr	-1368(ra) # 80003914 <iunlock>
      return ip;
    80003e74:	bfe9                	j	80003e4e <namex+0x6a>
      iunlockput(ip);
    80003e76:	854e                	mv	a0,s3
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	c3c080e7          	jalr	-964(ra) # 80003ab4 <iunlockput>
      return 0;
    80003e80:	89d2                	mv	s3,s4
    80003e82:	b7f1                	j	80003e4e <namex+0x6a>
  len = path - s;
    80003e84:	40b48633          	sub	a2,s1,a1
    80003e88:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e8c:	094cd463          	bge	s9,s4,80003f14 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e90:	4639                	li	a2,14
    80003e92:	8556                	mv	a0,s5
    80003e94:	ffffd097          	auipc	ra,0xffffd
    80003e98:	fd6080e7          	jalr	-42(ra) # 80000e6a <memmove>
  while(*path == '/')
    80003e9c:	0004c783          	lbu	a5,0(s1)
    80003ea0:	01279763          	bne	a5,s2,80003eae <namex+0xca>
    path++;
    80003ea4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ea6:	0004c783          	lbu	a5,0(s1)
    80003eaa:	ff278de3          	beq	a5,s2,80003ea4 <namex+0xc0>
    ilock(ip);
    80003eae:	854e                	mv	a0,s3
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	9a2080e7          	jalr	-1630(ra) # 80003852 <ilock>
    if(ip->type != T_DIR){
    80003eb8:	04499783          	lh	a5,68(s3)
    80003ebc:	f98793e3          	bne	a5,s8,80003e42 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ec0:	000b0563          	beqz	s6,80003eca <namex+0xe6>
    80003ec4:	0004c783          	lbu	a5,0(s1)
    80003ec8:	d3cd                	beqz	a5,80003e6a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003eca:	865e                	mv	a2,s7
    80003ecc:	85d6                	mv	a1,s5
    80003ece:	854e                	mv	a0,s3
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	e64080e7          	jalr	-412(ra) # 80003d34 <dirlookup>
    80003ed8:	8a2a                	mv	s4,a0
    80003eda:	dd51                	beqz	a0,80003e76 <namex+0x92>
    iunlockput(ip);
    80003edc:	854e                	mv	a0,s3
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	bd6080e7          	jalr	-1066(ra) # 80003ab4 <iunlockput>
    ip = next;
    80003ee6:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ee8:	0004c783          	lbu	a5,0(s1)
    80003eec:	05279763          	bne	a5,s2,80003f3a <namex+0x156>
    path++;
    80003ef0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ef2:	0004c783          	lbu	a5,0(s1)
    80003ef6:	ff278de3          	beq	a5,s2,80003ef0 <namex+0x10c>
  if(*path == 0)
    80003efa:	c79d                	beqz	a5,80003f28 <namex+0x144>
    path++;
    80003efc:	85a6                	mv	a1,s1
  len = path - s;
    80003efe:	8a5e                	mv	s4,s7
    80003f00:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f02:	01278963          	beq	a5,s2,80003f14 <namex+0x130>
    80003f06:	dfbd                	beqz	a5,80003e84 <namex+0xa0>
    path++;
    80003f08:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f0a:	0004c783          	lbu	a5,0(s1)
    80003f0e:	ff279ce3          	bne	a5,s2,80003f06 <namex+0x122>
    80003f12:	bf8d                	j	80003e84 <namex+0xa0>
    memmove(name, s, len);
    80003f14:	2601                	sext.w	a2,a2
    80003f16:	8556                	mv	a0,s5
    80003f18:	ffffd097          	auipc	ra,0xffffd
    80003f1c:	f52080e7          	jalr	-174(ra) # 80000e6a <memmove>
    name[len] = 0;
    80003f20:	9a56                	add	s4,s4,s5
    80003f22:	000a0023          	sb	zero,0(s4)
    80003f26:	bf9d                	j	80003e9c <namex+0xb8>
  if(nameiparent){
    80003f28:	f20b03e3          	beqz	s6,80003e4e <namex+0x6a>
    iput(ip);
    80003f2c:	854e                	mv	a0,s3
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	ade080e7          	jalr	-1314(ra) # 80003a0c <iput>
    return 0;
    80003f36:	4981                	li	s3,0
    80003f38:	bf19                	j	80003e4e <namex+0x6a>
  if(*path == 0)
    80003f3a:	d7fd                	beqz	a5,80003f28 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f3c:	0004c783          	lbu	a5,0(s1)
    80003f40:	85a6                	mv	a1,s1
    80003f42:	b7d1                	j	80003f06 <namex+0x122>

0000000080003f44 <dirlink>:
{
    80003f44:	7139                	addi	sp,sp,-64
    80003f46:	fc06                	sd	ra,56(sp)
    80003f48:	f822                	sd	s0,48(sp)
    80003f4a:	f426                	sd	s1,40(sp)
    80003f4c:	f04a                	sd	s2,32(sp)
    80003f4e:	ec4e                	sd	s3,24(sp)
    80003f50:	e852                	sd	s4,16(sp)
    80003f52:	0080                	addi	s0,sp,64
    80003f54:	892a                	mv	s2,a0
    80003f56:	8a2e                	mv	s4,a1
    80003f58:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f5a:	4601                	li	a2,0
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	dd8080e7          	jalr	-552(ra) # 80003d34 <dirlookup>
    80003f64:	e93d                	bnez	a0,80003fda <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f66:	04c92483          	lw	s1,76(s2)
    80003f6a:	c49d                	beqz	s1,80003f98 <dirlink+0x54>
    80003f6c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f6e:	4741                	li	a4,16
    80003f70:	86a6                	mv	a3,s1
    80003f72:	fc040613          	addi	a2,s0,-64
    80003f76:	4581                	li	a1,0
    80003f78:	854a                	mv	a0,s2
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	b8c080e7          	jalr	-1140(ra) # 80003b06 <readi>
    80003f82:	47c1                	li	a5,16
    80003f84:	06f51163          	bne	a0,a5,80003fe6 <dirlink+0xa2>
    if(de.inum == 0)
    80003f88:	fc045783          	lhu	a5,-64(s0)
    80003f8c:	c791                	beqz	a5,80003f98 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f8e:	24c1                	addiw	s1,s1,16
    80003f90:	04c92783          	lw	a5,76(s2)
    80003f94:	fcf4ede3          	bltu	s1,a5,80003f6e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f98:	4639                	li	a2,14
    80003f9a:	85d2                	mv	a1,s4
    80003f9c:	fc240513          	addi	a0,s0,-62
    80003fa0:	ffffd097          	auipc	ra,0xffffd
    80003fa4:	f82080e7          	jalr	-126(ra) # 80000f22 <strncpy>
  de.inum = inum;
    80003fa8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fac:	4741                	li	a4,16
    80003fae:	86a6                	mv	a3,s1
    80003fb0:	fc040613          	addi	a2,s0,-64
    80003fb4:	4581                	li	a1,0
    80003fb6:	854a                	mv	a0,s2
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	c46080e7          	jalr	-954(ra) # 80003bfe <writei>
    80003fc0:	872a                	mv	a4,a0
    80003fc2:	47c1                	li	a5,16
  return 0;
    80003fc4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fc6:	02f71863          	bne	a4,a5,80003ff6 <dirlink+0xb2>
}
    80003fca:	70e2                	ld	ra,56(sp)
    80003fcc:	7442                	ld	s0,48(sp)
    80003fce:	74a2                	ld	s1,40(sp)
    80003fd0:	7902                	ld	s2,32(sp)
    80003fd2:	69e2                	ld	s3,24(sp)
    80003fd4:	6a42                	ld	s4,16(sp)
    80003fd6:	6121                	addi	sp,sp,64
    80003fd8:	8082                	ret
    iput(ip);
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	a32080e7          	jalr	-1486(ra) # 80003a0c <iput>
    return -1;
    80003fe2:	557d                	li	a0,-1
    80003fe4:	b7dd                	j	80003fca <dirlink+0x86>
      panic("dirlink read");
    80003fe6:	00004517          	auipc	a0,0x4
    80003fea:	6f250513          	addi	a0,a0,1778 # 800086d8 <syscalls+0x1c8>
    80003fee:	ffffc097          	auipc	ra,0xffffc
    80003ff2:	55a080e7          	jalr	1370(ra) # 80000548 <panic>
    panic("dirlink");
    80003ff6:	00005517          	auipc	a0,0x5
    80003ffa:	80250513          	addi	a0,a0,-2046 # 800087f8 <syscalls+0x2e8>
    80003ffe:	ffffc097          	auipc	ra,0xffffc
    80004002:	54a080e7          	jalr	1354(ra) # 80000548 <panic>

0000000080004006 <namei>:

struct inode*
namei(char *path)
{
    80004006:	1101                	addi	sp,sp,-32
    80004008:	ec06                	sd	ra,24(sp)
    8000400a:	e822                	sd	s0,16(sp)
    8000400c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000400e:	fe040613          	addi	a2,s0,-32
    80004012:	4581                	li	a1,0
    80004014:	00000097          	auipc	ra,0x0
    80004018:	dd0080e7          	jalr	-560(ra) # 80003de4 <namex>
}
    8000401c:	60e2                	ld	ra,24(sp)
    8000401e:	6442                	ld	s0,16(sp)
    80004020:	6105                	addi	sp,sp,32
    80004022:	8082                	ret

0000000080004024 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004024:	1141                	addi	sp,sp,-16
    80004026:	e406                	sd	ra,8(sp)
    80004028:	e022                	sd	s0,0(sp)
    8000402a:	0800                	addi	s0,sp,16
    8000402c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000402e:	4585                	li	a1,1
    80004030:	00000097          	auipc	ra,0x0
    80004034:	db4080e7          	jalr	-588(ra) # 80003de4 <namex>
}
    80004038:	60a2                	ld	ra,8(sp)
    8000403a:	6402                	ld	s0,0(sp)
    8000403c:	0141                	addi	sp,sp,16
    8000403e:	8082                	ret

0000000080004040 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004040:	1101                	addi	sp,sp,-32
    80004042:	ec06                	sd	ra,24(sp)
    80004044:	e822                	sd	s0,16(sp)
    80004046:	e426                	sd	s1,8(sp)
    80004048:	e04a                	sd	s2,0(sp)
    8000404a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000404c:	0023e917          	auipc	s2,0x23e
    80004050:	8bc90913          	addi	s2,s2,-1860 # 80241908 <log>
    80004054:	01892583          	lw	a1,24(s2)
    80004058:	02892503          	lw	a0,40(s2)
    8000405c:	fffff097          	auipc	ra,0xfffff
    80004060:	ff4080e7          	jalr	-12(ra) # 80003050 <bread>
    80004064:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004066:	02c92683          	lw	a3,44(s2)
    8000406a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000406c:	02d05763          	blez	a3,8000409a <write_head+0x5a>
    80004070:	0023e797          	auipc	a5,0x23e
    80004074:	8c878793          	addi	a5,a5,-1848 # 80241938 <log+0x30>
    80004078:	05c50713          	addi	a4,a0,92
    8000407c:	36fd                	addiw	a3,a3,-1
    8000407e:	1682                	slli	a3,a3,0x20
    80004080:	9281                	srli	a3,a3,0x20
    80004082:	068a                	slli	a3,a3,0x2
    80004084:	0023e617          	auipc	a2,0x23e
    80004088:	8b860613          	addi	a2,a2,-1864 # 8024193c <log+0x34>
    8000408c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000408e:	4390                	lw	a2,0(a5)
    80004090:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004092:	0791                	addi	a5,a5,4
    80004094:	0711                	addi	a4,a4,4
    80004096:	fed79ce3          	bne	a5,a3,8000408e <write_head+0x4e>
  }
  bwrite(buf);
    8000409a:	8526                	mv	a0,s1
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	0a6080e7          	jalr	166(ra) # 80003142 <bwrite>
  brelse(buf);
    800040a4:	8526                	mv	a0,s1
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	0da080e7          	jalr	218(ra) # 80003180 <brelse>
}
    800040ae:	60e2                	ld	ra,24(sp)
    800040b0:	6442                	ld	s0,16(sp)
    800040b2:	64a2                	ld	s1,8(sp)
    800040b4:	6902                	ld	s2,0(sp)
    800040b6:	6105                	addi	sp,sp,32
    800040b8:	8082                	ret

00000000800040ba <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ba:	0023e797          	auipc	a5,0x23e
    800040be:	87a7a783          	lw	a5,-1926(a5) # 80241934 <log+0x2c>
    800040c2:	0af05663          	blez	a5,8000416e <install_trans+0xb4>
{
    800040c6:	7139                	addi	sp,sp,-64
    800040c8:	fc06                	sd	ra,56(sp)
    800040ca:	f822                	sd	s0,48(sp)
    800040cc:	f426                	sd	s1,40(sp)
    800040ce:	f04a                	sd	s2,32(sp)
    800040d0:	ec4e                	sd	s3,24(sp)
    800040d2:	e852                	sd	s4,16(sp)
    800040d4:	e456                	sd	s5,8(sp)
    800040d6:	0080                	addi	s0,sp,64
    800040d8:	0023ea97          	auipc	s5,0x23e
    800040dc:	860a8a93          	addi	s5,s5,-1952 # 80241938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040e0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040e2:	0023e997          	auipc	s3,0x23e
    800040e6:	82698993          	addi	s3,s3,-2010 # 80241908 <log>
    800040ea:	0189a583          	lw	a1,24(s3)
    800040ee:	014585bb          	addw	a1,a1,s4
    800040f2:	2585                	addiw	a1,a1,1
    800040f4:	0289a503          	lw	a0,40(s3)
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	f58080e7          	jalr	-168(ra) # 80003050 <bread>
    80004100:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004102:	000aa583          	lw	a1,0(s5)
    80004106:	0289a503          	lw	a0,40(s3)
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	f46080e7          	jalr	-186(ra) # 80003050 <bread>
    80004112:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004114:	40000613          	li	a2,1024
    80004118:	05890593          	addi	a1,s2,88
    8000411c:	05850513          	addi	a0,a0,88
    80004120:	ffffd097          	auipc	ra,0xffffd
    80004124:	d4a080e7          	jalr	-694(ra) # 80000e6a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004128:	8526                	mv	a0,s1
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	018080e7          	jalr	24(ra) # 80003142 <bwrite>
    bunpin(dbuf);
    80004132:	8526                	mv	a0,s1
    80004134:	fffff097          	auipc	ra,0xfffff
    80004138:	126080e7          	jalr	294(ra) # 8000325a <bunpin>
    brelse(lbuf);
    8000413c:	854a                	mv	a0,s2
    8000413e:	fffff097          	auipc	ra,0xfffff
    80004142:	042080e7          	jalr	66(ra) # 80003180 <brelse>
    brelse(dbuf);
    80004146:	8526                	mv	a0,s1
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	038080e7          	jalr	56(ra) # 80003180 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004150:	2a05                	addiw	s4,s4,1
    80004152:	0a91                	addi	s5,s5,4
    80004154:	02c9a783          	lw	a5,44(s3)
    80004158:	f8fa49e3          	blt	s4,a5,800040ea <install_trans+0x30>
}
    8000415c:	70e2                	ld	ra,56(sp)
    8000415e:	7442                	ld	s0,48(sp)
    80004160:	74a2                	ld	s1,40(sp)
    80004162:	7902                	ld	s2,32(sp)
    80004164:	69e2                	ld	s3,24(sp)
    80004166:	6a42                	ld	s4,16(sp)
    80004168:	6aa2                	ld	s5,8(sp)
    8000416a:	6121                	addi	sp,sp,64
    8000416c:	8082                	ret
    8000416e:	8082                	ret

0000000080004170 <initlog>:
{
    80004170:	7179                	addi	sp,sp,-48
    80004172:	f406                	sd	ra,40(sp)
    80004174:	f022                	sd	s0,32(sp)
    80004176:	ec26                	sd	s1,24(sp)
    80004178:	e84a                	sd	s2,16(sp)
    8000417a:	e44e                	sd	s3,8(sp)
    8000417c:	1800                	addi	s0,sp,48
    8000417e:	892a                	mv	s2,a0
    80004180:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004182:	0023d497          	auipc	s1,0x23d
    80004186:	78648493          	addi	s1,s1,1926 # 80241908 <log>
    8000418a:	00004597          	auipc	a1,0x4
    8000418e:	55e58593          	addi	a1,a1,1374 # 800086e8 <syscalls+0x1d8>
    80004192:	8526                	mv	a0,s1
    80004194:	ffffd097          	auipc	ra,0xffffd
    80004198:	aea080e7          	jalr	-1302(ra) # 80000c7e <initlock>
  log.start = sb->logstart;
    8000419c:	0149a583          	lw	a1,20(s3)
    800041a0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041a2:	0109a783          	lw	a5,16(s3)
    800041a6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041a8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041ac:	854a                	mv	a0,s2
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	ea2080e7          	jalr	-350(ra) # 80003050 <bread>
  log.lh.n = lh->n;
    800041b6:	4d3c                	lw	a5,88(a0)
    800041b8:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041ba:	02f05563          	blez	a5,800041e4 <initlog+0x74>
    800041be:	05c50713          	addi	a4,a0,92
    800041c2:	0023d697          	auipc	a3,0x23d
    800041c6:	77668693          	addi	a3,a3,1910 # 80241938 <log+0x30>
    800041ca:	37fd                	addiw	a5,a5,-1
    800041cc:	1782                	slli	a5,a5,0x20
    800041ce:	9381                	srli	a5,a5,0x20
    800041d0:	078a                	slli	a5,a5,0x2
    800041d2:	06050613          	addi	a2,a0,96
    800041d6:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041d8:	4310                	lw	a2,0(a4)
    800041da:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041dc:	0711                	addi	a4,a4,4
    800041de:	0691                	addi	a3,a3,4
    800041e0:	fef71ce3          	bne	a4,a5,800041d8 <initlog+0x68>
  brelse(buf);
    800041e4:	fffff097          	auipc	ra,0xfffff
    800041e8:	f9c080e7          	jalr	-100(ra) # 80003180 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800041ec:	00000097          	auipc	ra,0x0
    800041f0:	ece080e7          	jalr	-306(ra) # 800040ba <install_trans>
  log.lh.n = 0;
    800041f4:	0023d797          	auipc	a5,0x23d
    800041f8:	7407a023          	sw	zero,1856(a5) # 80241934 <log+0x2c>
  write_head(); // clear the log
    800041fc:	00000097          	auipc	ra,0x0
    80004200:	e44080e7          	jalr	-444(ra) # 80004040 <write_head>
}
    80004204:	70a2                	ld	ra,40(sp)
    80004206:	7402                	ld	s0,32(sp)
    80004208:	64e2                	ld	s1,24(sp)
    8000420a:	6942                	ld	s2,16(sp)
    8000420c:	69a2                	ld	s3,8(sp)
    8000420e:	6145                	addi	sp,sp,48
    80004210:	8082                	ret

0000000080004212 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004212:	1101                	addi	sp,sp,-32
    80004214:	ec06                	sd	ra,24(sp)
    80004216:	e822                	sd	s0,16(sp)
    80004218:	e426                	sd	s1,8(sp)
    8000421a:	e04a                	sd	s2,0(sp)
    8000421c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000421e:	0023d517          	auipc	a0,0x23d
    80004222:	6ea50513          	addi	a0,a0,1770 # 80241908 <log>
    80004226:	ffffd097          	auipc	ra,0xffffd
    8000422a:	ae8080e7          	jalr	-1304(ra) # 80000d0e <acquire>
  while(1){
    if(log.committing){
    8000422e:	0023d497          	auipc	s1,0x23d
    80004232:	6da48493          	addi	s1,s1,1754 # 80241908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004236:	4979                	li	s2,30
    80004238:	a039                	j	80004246 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000423a:	85a6                	mv	a1,s1
    8000423c:	8526                	mv	a0,s1
    8000423e:	ffffe097          	auipc	ra,0xffffe
    80004242:	1d0080e7          	jalr	464(ra) # 8000240e <sleep>
    if(log.committing){
    80004246:	50dc                	lw	a5,36(s1)
    80004248:	fbed                	bnez	a5,8000423a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000424a:	509c                	lw	a5,32(s1)
    8000424c:	0017871b          	addiw	a4,a5,1
    80004250:	0007069b          	sext.w	a3,a4
    80004254:	0027179b          	slliw	a5,a4,0x2
    80004258:	9fb9                	addw	a5,a5,a4
    8000425a:	0017979b          	slliw	a5,a5,0x1
    8000425e:	54d8                	lw	a4,44(s1)
    80004260:	9fb9                	addw	a5,a5,a4
    80004262:	00f95963          	bge	s2,a5,80004274 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004266:	85a6                	mv	a1,s1
    80004268:	8526                	mv	a0,s1
    8000426a:	ffffe097          	auipc	ra,0xffffe
    8000426e:	1a4080e7          	jalr	420(ra) # 8000240e <sleep>
    80004272:	bfd1                	j	80004246 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004274:	0023d517          	auipc	a0,0x23d
    80004278:	69450513          	addi	a0,a0,1684 # 80241908 <log>
    8000427c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000427e:	ffffd097          	auipc	ra,0xffffd
    80004282:	b44080e7          	jalr	-1212(ra) # 80000dc2 <release>
      break;
    }
  }
}
    80004286:	60e2                	ld	ra,24(sp)
    80004288:	6442                	ld	s0,16(sp)
    8000428a:	64a2                	ld	s1,8(sp)
    8000428c:	6902                	ld	s2,0(sp)
    8000428e:	6105                	addi	sp,sp,32
    80004290:	8082                	ret

0000000080004292 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004292:	7139                	addi	sp,sp,-64
    80004294:	fc06                	sd	ra,56(sp)
    80004296:	f822                	sd	s0,48(sp)
    80004298:	f426                	sd	s1,40(sp)
    8000429a:	f04a                	sd	s2,32(sp)
    8000429c:	ec4e                	sd	s3,24(sp)
    8000429e:	e852                	sd	s4,16(sp)
    800042a0:	e456                	sd	s5,8(sp)
    800042a2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042a4:	0023d497          	auipc	s1,0x23d
    800042a8:	66448493          	addi	s1,s1,1636 # 80241908 <log>
    800042ac:	8526                	mv	a0,s1
    800042ae:	ffffd097          	auipc	ra,0xffffd
    800042b2:	a60080e7          	jalr	-1440(ra) # 80000d0e <acquire>
  log.outstanding -= 1;
    800042b6:	509c                	lw	a5,32(s1)
    800042b8:	37fd                	addiw	a5,a5,-1
    800042ba:	0007891b          	sext.w	s2,a5
    800042be:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042c0:	50dc                	lw	a5,36(s1)
    800042c2:	efb9                	bnez	a5,80004320 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042c4:	06091663          	bnez	s2,80004330 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042c8:	0023d497          	auipc	s1,0x23d
    800042cc:	64048493          	addi	s1,s1,1600 # 80241908 <log>
    800042d0:	4785                	li	a5,1
    800042d2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042d4:	8526                	mv	a0,s1
    800042d6:	ffffd097          	auipc	ra,0xffffd
    800042da:	aec080e7          	jalr	-1300(ra) # 80000dc2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042de:	54dc                	lw	a5,44(s1)
    800042e0:	06f04763          	bgtz	a5,8000434e <end_op+0xbc>
    acquire(&log.lock);
    800042e4:	0023d497          	auipc	s1,0x23d
    800042e8:	62448493          	addi	s1,s1,1572 # 80241908 <log>
    800042ec:	8526                	mv	a0,s1
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	a20080e7          	jalr	-1504(ra) # 80000d0e <acquire>
    log.committing = 0;
    800042f6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042fa:	8526                	mv	a0,s1
    800042fc:	ffffe097          	auipc	ra,0xffffe
    80004300:	298080e7          	jalr	664(ra) # 80002594 <wakeup>
    release(&log.lock);
    80004304:	8526                	mv	a0,s1
    80004306:	ffffd097          	auipc	ra,0xffffd
    8000430a:	abc080e7          	jalr	-1348(ra) # 80000dc2 <release>
}
    8000430e:	70e2                	ld	ra,56(sp)
    80004310:	7442                	ld	s0,48(sp)
    80004312:	74a2                	ld	s1,40(sp)
    80004314:	7902                	ld	s2,32(sp)
    80004316:	69e2                	ld	s3,24(sp)
    80004318:	6a42                	ld	s4,16(sp)
    8000431a:	6aa2                	ld	s5,8(sp)
    8000431c:	6121                	addi	sp,sp,64
    8000431e:	8082                	ret
    panic("log.committing");
    80004320:	00004517          	auipc	a0,0x4
    80004324:	3d050513          	addi	a0,a0,976 # 800086f0 <syscalls+0x1e0>
    80004328:	ffffc097          	auipc	ra,0xffffc
    8000432c:	220080e7          	jalr	544(ra) # 80000548 <panic>
    wakeup(&log);
    80004330:	0023d497          	auipc	s1,0x23d
    80004334:	5d848493          	addi	s1,s1,1496 # 80241908 <log>
    80004338:	8526                	mv	a0,s1
    8000433a:	ffffe097          	auipc	ra,0xffffe
    8000433e:	25a080e7          	jalr	602(ra) # 80002594 <wakeup>
  release(&log.lock);
    80004342:	8526                	mv	a0,s1
    80004344:	ffffd097          	auipc	ra,0xffffd
    80004348:	a7e080e7          	jalr	-1410(ra) # 80000dc2 <release>
  if(do_commit){
    8000434c:	b7c9                	j	8000430e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000434e:	0023da97          	auipc	s5,0x23d
    80004352:	5eaa8a93          	addi	s5,s5,1514 # 80241938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004356:	0023da17          	auipc	s4,0x23d
    8000435a:	5b2a0a13          	addi	s4,s4,1458 # 80241908 <log>
    8000435e:	018a2583          	lw	a1,24(s4)
    80004362:	012585bb          	addw	a1,a1,s2
    80004366:	2585                	addiw	a1,a1,1
    80004368:	028a2503          	lw	a0,40(s4)
    8000436c:	fffff097          	auipc	ra,0xfffff
    80004370:	ce4080e7          	jalr	-796(ra) # 80003050 <bread>
    80004374:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004376:	000aa583          	lw	a1,0(s5)
    8000437a:	028a2503          	lw	a0,40(s4)
    8000437e:	fffff097          	auipc	ra,0xfffff
    80004382:	cd2080e7          	jalr	-814(ra) # 80003050 <bread>
    80004386:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004388:	40000613          	li	a2,1024
    8000438c:	05850593          	addi	a1,a0,88
    80004390:	05848513          	addi	a0,s1,88
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	ad6080e7          	jalr	-1322(ra) # 80000e6a <memmove>
    bwrite(to);  // write the log
    8000439c:	8526                	mv	a0,s1
    8000439e:	fffff097          	auipc	ra,0xfffff
    800043a2:	da4080e7          	jalr	-604(ra) # 80003142 <bwrite>
    brelse(from);
    800043a6:	854e                	mv	a0,s3
    800043a8:	fffff097          	auipc	ra,0xfffff
    800043ac:	dd8080e7          	jalr	-552(ra) # 80003180 <brelse>
    brelse(to);
    800043b0:	8526                	mv	a0,s1
    800043b2:	fffff097          	auipc	ra,0xfffff
    800043b6:	dce080e7          	jalr	-562(ra) # 80003180 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ba:	2905                	addiw	s2,s2,1
    800043bc:	0a91                	addi	s5,s5,4
    800043be:	02ca2783          	lw	a5,44(s4)
    800043c2:	f8f94ee3          	blt	s2,a5,8000435e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043c6:	00000097          	auipc	ra,0x0
    800043ca:	c7a080e7          	jalr	-902(ra) # 80004040 <write_head>
    install_trans(); // Now install writes to home locations
    800043ce:	00000097          	auipc	ra,0x0
    800043d2:	cec080e7          	jalr	-788(ra) # 800040ba <install_trans>
    log.lh.n = 0;
    800043d6:	0023d797          	auipc	a5,0x23d
    800043da:	5407af23          	sw	zero,1374(a5) # 80241934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043de:	00000097          	auipc	ra,0x0
    800043e2:	c62080e7          	jalr	-926(ra) # 80004040 <write_head>
    800043e6:	bdfd                	j	800042e4 <end_op+0x52>

00000000800043e8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043e8:	1101                	addi	sp,sp,-32
    800043ea:	ec06                	sd	ra,24(sp)
    800043ec:	e822                	sd	s0,16(sp)
    800043ee:	e426                	sd	s1,8(sp)
    800043f0:	e04a                	sd	s2,0(sp)
    800043f2:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043f4:	0023d717          	auipc	a4,0x23d
    800043f8:	54072703          	lw	a4,1344(a4) # 80241934 <log+0x2c>
    800043fc:	47f5                	li	a5,29
    800043fe:	08e7c063          	blt	a5,a4,8000447e <log_write+0x96>
    80004402:	84aa                	mv	s1,a0
    80004404:	0023d797          	auipc	a5,0x23d
    80004408:	5207a783          	lw	a5,1312(a5) # 80241924 <log+0x1c>
    8000440c:	37fd                	addiw	a5,a5,-1
    8000440e:	06f75863          	bge	a4,a5,8000447e <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004412:	0023d797          	auipc	a5,0x23d
    80004416:	5167a783          	lw	a5,1302(a5) # 80241928 <log+0x20>
    8000441a:	06f05a63          	blez	a5,8000448e <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000441e:	0023d917          	auipc	s2,0x23d
    80004422:	4ea90913          	addi	s2,s2,1258 # 80241908 <log>
    80004426:	854a                	mv	a0,s2
    80004428:	ffffd097          	auipc	ra,0xffffd
    8000442c:	8e6080e7          	jalr	-1818(ra) # 80000d0e <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004430:	02c92603          	lw	a2,44(s2)
    80004434:	06c05563          	blez	a2,8000449e <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004438:	44cc                	lw	a1,12(s1)
    8000443a:	0023d717          	auipc	a4,0x23d
    8000443e:	4fe70713          	addi	a4,a4,1278 # 80241938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004442:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004444:	4314                	lw	a3,0(a4)
    80004446:	04b68d63          	beq	a3,a1,800044a0 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000444a:	2785                	addiw	a5,a5,1
    8000444c:	0711                	addi	a4,a4,4
    8000444e:	fec79be3          	bne	a5,a2,80004444 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004452:	0621                	addi	a2,a2,8
    80004454:	060a                	slli	a2,a2,0x2
    80004456:	0023d797          	auipc	a5,0x23d
    8000445a:	4b278793          	addi	a5,a5,1202 # 80241908 <log>
    8000445e:	963e                	add	a2,a2,a5
    80004460:	44dc                	lw	a5,12(s1)
    80004462:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004464:	8526                	mv	a0,s1
    80004466:	fffff097          	auipc	ra,0xfffff
    8000446a:	db8080e7          	jalr	-584(ra) # 8000321e <bpin>
    log.lh.n++;
    8000446e:	0023d717          	auipc	a4,0x23d
    80004472:	49a70713          	addi	a4,a4,1178 # 80241908 <log>
    80004476:	575c                	lw	a5,44(a4)
    80004478:	2785                	addiw	a5,a5,1
    8000447a:	d75c                	sw	a5,44(a4)
    8000447c:	a83d                	j	800044ba <log_write+0xd2>
    panic("too big a transaction");
    8000447e:	00004517          	auipc	a0,0x4
    80004482:	28250513          	addi	a0,a0,642 # 80008700 <syscalls+0x1f0>
    80004486:	ffffc097          	auipc	ra,0xffffc
    8000448a:	0c2080e7          	jalr	194(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    8000448e:	00004517          	auipc	a0,0x4
    80004492:	28a50513          	addi	a0,a0,650 # 80008718 <syscalls+0x208>
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	0b2080e7          	jalr	178(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000449e:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800044a0:	00878713          	addi	a4,a5,8
    800044a4:	00271693          	slli	a3,a4,0x2
    800044a8:	0023d717          	auipc	a4,0x23d
    800044ac:	46070713          	addi	a4,a4,1120 # 80241908 <log>
    800044b0:	9736                	add	a4,a4,a3
    800044b2:	44d4                	lw	a3,12(s1)
    800044b4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044b6:	faf607e3          	beq	a2,a5,80004464 <log_write+0x7c>
  }
  release(&log.lock);
    800044ba:	0023d517          	auipc	a0,0x23d
    800044be:	44e50513          	addi	a0,a0,1102 # 80241908 <log>
    800044c2:	ffffd097          	auipc	ra,0xffffd
    800044c6:	900080e7          	jalr	-1792(ra) # 80000dc2 <release>
}
    800044ca:	60e2                	ld	ra,24(sp)
    800044cc:	6442                	ld	s0,16(sp)
    800044ce:	64a2                	ld	s1,8(sp)
    800044d0:	6902                	ld	s2,0(sp)
    800044d2:	6105                	addi	sp,sp,32
    800044d4:	8082                	ret

00000000800044d6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044d6:	1101                	addi	sp,sp,-32
    800044d8:	ec06                	sd	ra,24(sp)
    800044da:	e822                	sd	s0,16(sp)
    800044dc:	e426                	sd	s1,8(sp)
    800044de:	e04a                	sd	s2,0(sp)
    800044e0:	1000                	addi	s0,sp,32
    800044e2:	84aa                	mv	s1,a0
    800044e4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044e6:	00004597          	auipc	a1,0x4
    800044ea:	25258593          	addi	a1,a1,594 # 80008738 <syscalls+0x228>
    800044ee:	0521                	addi	a0,a0,8
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	78e080e7          	jalr	1934(ra) # 80000c7e <initlock>
  lk->name = name;
    800044f8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044fc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004500:	0204a423          	sw	zero,40(s1)
}
    80004504:	60e2                	ld	ra,24(sp)
    80004506:	6442                	ld	s0,16(sp)
    80004508:	64a2                	ld	s1,8(sp)
    8000450a:	6902                	ld	s2,0(sp)
    8000450c:	6105                	addi	sp,sp,32
    8000450e:	8082                	ret

0000000080004510 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004510:	1101                	addi	sp,sp,-32
    80004512:	ec06                	sd	ra,24(sp)
    80004514:	e822                	sd	s0,16(sp)
    80004516:	e426                	sd	s1,8(sp)
    80004518:	e04a                	sd	s2,0(sp)
    8000451a:	1000                	addi	s0,sp,32
    8000451c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000451e:	00850913          	addi	s2,a0,8
    80004522:	854a                	mv	a0,s2
    80004524:	ffffc097          	auipc	ra,0xffffc
    80004528:	7ea080e7          	jalr	2026(ra) # 80000d0e <acquire>
  while (lk->locked) {
    8000452c:	409c                	lw	a5,0(s1)
    8000452e:	cb89                	beqz	a5,80004540 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004530:	85ca                	mv	a1,s2
    80004532:	8526                	mv	a0,s1
    80004534:	ffffe097          	auipc	ra,0xffffe
    80004538:	eda080e7          	jalr	-294(ra) # 8000240e <sleep>
  while (lk->locked) {
    8000453c:	409c                	lw	a5,0(s1)
    8000453e:	fbed                	bnez	a5,80004530 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004540:	4785                	li	a5,1
    80004542:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004544:	ffffd097          	auipc	ra,0xffffd
    80004548:	6ba080e7          	jalr	1722(ra) # 80001bfe <myproc>
    8000454c:	5d1c                	lw	a5,56(a0)
    8000454e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004550:	854a                	mv	a0,s2
    80004552:	ffffd097          	auipc	ra,0xffffd
    80004556:	870080e7          	jalr	-1936(ra) # 80000dc2 <release>
}
    8000455a:	60e2                	ld	ra,24(sp)
    8000455c:	6442                	ld	s0,16(sp)
    8000455e:	64a2                	ld	s1,8(sp)
    80004560:	6902                	ld	s2,0(sp)
    80004562:	6105                	addi	sp,sp,32
    80004564:	8082                	ret

0000000080004566 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004566:	1101                	addi	sp,sp,-32
    80004568:	ec06                	sd	ra,24(sp)
    8000456a:	e822                	sd	s0,16(sp)
    8000456c:	e426                	sd	s1,8(sp)
    8000456e:	e04a                	sd	s2,0(sp)
    80004570:	1000                	addi	s0,sp,32
    80004572:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004574:	00850913          	addi	s2,a0,8
    80004578:	854a                	mv	a0,s2
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	794080e7          	jalr	1940(ra) # 80000d0e <acquire>
  lk->locked = 0;
    80004582:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004586:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000458a:	8526                	mv	a0,s1
    8000458c:	ffffe097          	auipc	ra,0xffffe
    80004590:	008080e7          	jalr	8(ra) # 80002594 <wakeup>
  release(&lk->lk);
    80004594:	854a                	mv	a0,s2
    80004596:	ffffd097          	auipc	ra,0xffffd
    8000459a:	82c080e7          	jalr	-2004(ra) # 80000dc2 <release>
}
    8000459e:	60e2                	ld	ra,24(sp)
    800045a0:	6442                	ld	s0,16(sp)
    800045a2:	64a2                	ld	s1,8(sp)
    800045a4:	6902                	ld	s2,0(sp)
    800045a6:	6105                	addi	sp,sp,32
    800045a8:	8082                	ret

00000000800045aa <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045aa:	7179                	addi	sp,sp,-48
    800045ac:	f406                	sd	ra,40(sp)
    800045ae:	f022                	sd	s0,32(sp)
    800045b0:	ec26                	sd	s1,24(sp)
    800045b2:	e84a                	sd	s2,16(sp)
    800045b4:	e44e                	sd	s3,8(sp)
    800045b6:	1800                	addi	s0,sp,48
    800045b8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045ba:	00850913          	addi	s2,a0,8
    800045be:	854a                	mv	a0,s2
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	74e080e7          	jalr	1870(ra) # 80000d0e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045c8:	409c                	lw	a5,0(s1)
    800045ca:	ef99                	bnez	a5,800045e8 <holdingsleep+0x3e>
    800045cc:	4481                	li	s1,0
  release(&lk->lk);
    800045ce:	854a                	mv	a0,s2
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	7f2080e7          	jalr	2034(ra) # 80000dc2 <release>
  return r;
}
    800045d8:	8526                	mv	a0,s1
    800045da:	70a2                	ld	ra,40(sp)
    800045dc:	7402                	ld	s0,32(sp)
    800045de:	64e2                	ld	s1,24(sp)
    800045e0:	6942                	ld	s2,16(sp)
    800045e2:	69a2                	ld	s3,8(sp)
    800045e4:	6145                	addi	sp,sp,48
    800045e6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045e8:	0284a983          	lw	s3,40(s1)
    800045ec:	ffffd097          	auipc	ra,0xffffd
    800045f0:	612080e7          	jalr	1554(ra) # 80001bfe <myproc>
    800045f4:	5d04                	lw	s1,56(a0)
    800045f6:	413484b3          	sub	s1,s1,s3
    800045fa:	0014b493          	seqz	s1,s1
    800045fe:	bfc1                	j	800045ce <holdingsleep+0x24>

0000000080004600 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004600:	1141                	addi	sp,sp,-16
    80004602:	e406                	sd	ra,8(sp)
    80004604:	e022                	sd	s0,0(sp)
    80004606:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004608:	00004597          	auipc	a1,0x4
    8000460c:	14058593          	addi	a1,a1,320 # 80008748 <syscalls+0x238>
    80004610:	0023d517          	auipc	a0,0x23d
    80004614:	44050513          	addi	a0,a0,1088 # 80241a50 <ftable>
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	666080e7          	jalr	1638(ra) # 80000c7e <initlock>
}
    80004620:	60a2                	ld	ra,8(sp)
    80004622:	6402                	ld	s0,0(sp)
    80004624:	0141                	addi	sp,sp,16
    80004626:	8082                	ret

0000000080004628 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004628:	1101                	addi	sp,sp,-32
    8000462a:	ec06                	sd	ra,24(sp)
    8000462c:	e822                	sd	s0,16(sp)
    8000462e:	e426                	sd	s1,8(sp)
    80004630:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004632:	0023d517          	auipc	a0,0x23d
    80004636:	41e50513          	addi	a0,a0,1054 # 80241a50 <ftable>
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	6d4080e7          	jalr	1748(ra) # 80000d0e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004642:	0023d497          	auipc	s1,0x23d
    80004646:	42648493          	addi	s1,s1,1062 # 80241a68 <ftable+0x18>
    8000464a:	0023e717          	auipc	a4,0x23e
    8000464e:	3be70713          	addi	a4,a4,958 # 80242a08 <ftable+0xfb8>
    if(f->ref == 0){
    80004652:	40dc                	lw	a5,4(s1)
    80004654:	cf99                	beqz	a5,80004672 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004656:	02848493          	addi	s1,s1,40
    8000465a:	fee49ce3          	bne	s1,a4,80004652 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000465e:	0023d517          	auipc	a0,0x23d
    80004662:	3f250513          	addi	a0,a0,1010 # 80241a50 <ftable>
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	75c080e7          	jalr	1884(ra) # 80000dc2 <release>
  return 0;
    8000466e:	4481                	li	s1,0
    80004670:	a819                	j	80004686 <filealloc+0x5e>
      f->ref = 1;
    80004672:	4785                	li	a5,1
    80004674:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004676:	0023d517          	auipc	a0,0x23d
    8000467a:	3da50513          	addi	a0,a0,986 # 80241a50 <ftable>
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	744080e7          	jalr	1860(ra) # 80000dc2 <release>
}
    80004686:	8526                	mv	a0,s1
    80004688:	60e2                	ld	ra,24(sp)
    8000468a:	6442                	ld	s0,16(sp)
    8000468c:	64a2                	ld	s1,8(sp)
    8000468e:	6105                	addi	sp,sp,32
    80004690:	8082                	ret

0000000080004692 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004692:	1101                	addi	sp,sp,-32
    80004694:	ec06                	sd	ra,24(sp)
    80004696:	e822                	sd	s0,16(sp)
    80004698:	e426                	sd	s1,8(sp)
    8000469a:	1000                	addi	s0,sp,32
    8000469c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000469e:	0023d517          	auipc	a0,0x23d
    800046a2:	3b250513          	addi	a0,a0,946 # 80241a50 <ftable>
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	668080e7          	jalr	1640(ra) # 80000d0e <acquire>
  if(f->ref < 1)
    800046ae:	40dc                	lw	a5,4(s1)
    800046b0:	02f05263          	blez	a5,800046d4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046b4:	2785                	addiw	a5,a5,1
    800046b6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046b8:	0023d517          	auipc	a0,0x23d
    800046bc:	39850513          	addi	a0,a0,920 # 80241a50 <ftable>
    800046c0:	ffffc097          	auipc	ra,0xffffc
    800046c4:	702080e7          	jalr	1794(ra) # 80000dc2 <release>
  return f;
}
    800046c8:	8526                	mv	a0,s1
    800046ca:	60e2                	ld	ra,24(sp)
    800046cc:	6442                	ld	s0,16(sp)
    800046ce:	64a2                	ld	s1,8(sp)
    800046d0:	6105                	addi	sp,sp,32
    800046d2:	8082                	ret
    panic("filedup");
    800046d4:	00004517          	auipc	a0,0x4
    800046d8:	07c50513          	addi	a0,a0,124 # 80008750 <syscalls+0x240>
    800046dc:	ffffc097          	auipc	ra,0xffffc
    800046e0:	e6c080e7          	jalr	-404(ra) # 80000548 <panic>

00000000800046e4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046e4:	7139                	addi	sp,sp,-64
    800046e6:	fc06                	sd	ra,56(sp)
    800046e8:	f822                	sd	s0,48(sp)
    800046ea:	f426                	sd	s1,40(sp)
    800046ec:	f04a                	sd	s2,32(sp)
    800046ee:	ec4e                	sd	s3,24(sp)
    800046f0:	e852                	sd	s4,16(sp)
    800046f2:	e456                	sd	s5,8(sp)
    800046f4:	0080                	addi	s0,sp,64
    800046f6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046f8:	0023d517          	auipc	a0,0x23d
    800046fc:	35850513          	addi	a0,a0,856 # 80241a50 <ftable>
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	60e080e7          	jalr	1550(ra) # 80000d0e <acquire>
  if(f->ref < 1)
    80004708:	40dc                	lw	a5,4(s1)
    8000470a:	06f05163          	blez	a5,8000476c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000470e:	37fd                	addiw	a5,a5,-1
    80004710:	0007871b          	sext.w	a4,a5
    80004714:	c0dc                	sw	a5,4(s1)
    80004716:	06e04363          	bgtz	a4,8000477c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000471a:	0004a903          	lw	s2,0(s1)
    8000471e:	0094ca83          	lbu	s5,9(s1)
    80004722:	0104ba03          	ld	s4,16(s1)
    80004726:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000472a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000472e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004732:	0023d517          	auipc	a0,0x23d
    80004736:	31e50513          	addi	a0,a0,798 # 80241a50 <ftable>
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	688080e7          	jalr	1672(ra) # 80000dc2 <release>

  if(ff.type == FD_PIPE){
    80004742:	4785                	li	a5,1
    80004744:	04f90d63          	beq	s2,a5,8000479e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004748:	3979                	addiw	s2,s2,-2
    8000474a:	4785                	li	a5,1
    8000474c:	0527e063          	bltu	a5,s2,8000478c <fileclose+0xa8>
    begin_op();
    80004750:	00000097          	auipc	ra,0x0
    80004754:	ac2080e7          	jalr	-1342(ra) # 80004212 <begin_op>
    iput(ff.ip);
    80004758:	854e                	mv	a0,s3
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	2b2080e7          	jalr	690(ra) # 80003a0c <iput>
    end_op();
    80004762:	00000097          	auipc	ra,0x0
    80004766:	b30080e7          	jalr	-1232(ra) # 80004292 <end_op>
    8000476a:	a00d                	j	8000478c <fileclose+0xa8>
    panic("fileclose");
    8000476c:	00004517          	auipc	a0,0x4
    80004770:	fec50513          	addi	a0,a0,-20 # 80008758 <syscalls+0x248>
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	dd4080e7          	jalr	-556(ra) # 80000548 <panic>
    release(&ftable.lock);
    8000477c:	0023d517          	auipc	a0,0x23d
    80004780:	2d450513          	addi	a0,a0,724 # 80241a50 <ftable>
    80004784:	ffffc097          	auipc	ra,0xffffc
    80004788:	63e080e7          	jalr	1598(ra) # 80000dc2 <release>
  }
}
    8000478c:	70e2                	ld	ra,56(sp)
    8000478e:	7442                	ld	s0,48(sp)
    80004790:	74a2                	ld	s1,40(sp)
    80004792:	7902                	ld	s2,32(sp)
    80004794:	69e2                	ld	s3,24(sp)
    80004796:	6a42                	ld	s4,16(sp)
    80004798:	6aa2                	ld	s5,8(sp)
    8000479a:	6121                	addi	sp,sp,64
    8000479c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000479e:	85d6                	mv	a1,s5
    800047a0:	8552                	mv	a0,s4
    800047a2:	00000097          	auipc	ra,0x0
    800047a6:	372080e7          	jalr	882(ra) # 80004b14 <pipeclose>
    800047aa:	b7cd                	j	8000478c <fileclose+0xa8>

00000000800047ac <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047ac:	715d                	addi	sp,sp,-80
    800047ae:	e486                	sd	ra,72(sp)
    800047b0:	e0a2                	sd	s0,64(sp)
    800047b2:	fc26                	sd	s1,56(sp)
    800047b4:	f84a                	sd	s2,48(sp)
    800047b6:	f44e                	sd	s3,40(sp)
    800047b8:	0880                	addi	s0,sp,80
    800047ba:	84aa                	mv	s1,a0
    800047bc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047be:	ffffd097          	auipc	ra,0xffffd
    800047c2:	440080e7          	jalr	1088(ra) # 80001bfe <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047c6:	409c                	lw	a5,0(s1)
    800047c8:	37f9                	addiw	a5,a5,-2
    800047ca:	4705                	li	a4,1
    800047cc:	04f76763          	bltu	a4,a5,8000481a <filestat+0x6e>
    800047d0:	892a                	mv	s2,a0
    ilock(f->ip);
    800047d2:	6c88                	ld	a0,24(s1)
    800047d4:	fffff097          	auipc	ra,0xfffff
    800047d8:	07e080e7          	jalr	126(ra) # 80003852 <ilock>
    stati(f->ip, &st);
    800047dc:	fb840593          	addi	a1,s0,-72
    800047e0:	6c88                	ld	a0,24(s1)
    800047e2:	fffff097          	auipc	ra,0xfffff
    800047e6:	2fa080e7          	jalr	762(ra) # 80003adc <stati>
    iunlock(f->ip);
    800047ea:	6c88                	ld	a0,24(s1)
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	128080e7          	jalr	296(ra) # 80003914 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047f4:	46e1                	li	a3,24
    800047f6:	fb840613          	addi	a2,s0,-72
    800047fa:	85ce                	mv	a1,s3
    800047fc:	05093503          	ld	a0,80(s2)
    80004800:	ffffd097          	auipc	ra,0xffffd
    80004804:	1c2080e7          	jalr	450(ra) # 800019c2 <copyout>
    80004808:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000480c:	60a6                	ld	ra,72(sp)
    8000480e:	6406                	ld	s0,64(sp)
    80004810:	74e2                	ld	s1,56(sp)
    80004812:	7942                	ld	s2,48(sp)
    80004814:	79a2                	ld	s3,40(sp)
    80004816:	6161                	addi	sp,sp,80
    80004818:	8082                	ret
  return -1;
    8000481a:	557d                	li	a0,-1
    8000481c:	bfc5                	j	8000480c <filestat+0x60>

000000008000481e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000481e:	7179                	addi	sp,sp,-48
    80004820:	f406                	sd	ra,40(sp)
    80004822:	f022                	sd	s0,32(sp)
    80004824:	ec26                	sd	s1,24(sp)
    80004826:	e84a                	sd	s2,16(sp)
    80004828:	e44e                	sd	s3,8(sp)
    8000482a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000482c:	00854783          	lbu	a5,8(a0)
    80004830:	c3d5                	beqz	a5,800048d4 <fileread+0xb6>
    80004832:	84aa                	mv	s1,a0
    80004834:	89ae                	mv	s3,a1
    80004836:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004838:	411c                	lw	a5,0(a0)
    8000483a:	4705                	li	a4,1
    8000483c:	04e78963          	beq	a5,a4,8000488e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004840:	470d                	li	a4,3
    80004842:	04e78d63          	beq	a5,a4,8000489c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004846:	4709                	li	a4,2
    80004848:	06e79e63          	bne	a5,a4,800048c4 <fileread+0xa6>
    ilock(f->ip);
    8000484c:	6d08                	ld	a0,24(a0)
    8000484e:	fffff097          	auipc	ra,0xfffff
    80004852:	004080e7          	jalr	4(ra) # 80003852 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004856:	874a                	mv	a4,s2
    80004858:	5094                	lw	a3,32(s1)
    8000485a:	864e                	mv	a2,s3
    8000485c:	4585                	li	a1,1
    8000485e:	6c88                	ld	a0,24(s1)
    80004860:	fffff097          	auipc	ra,0xfffff
    80004864:	2a6080e7          	jalr	678(ra) # 80003b06 <readi>
    80004868:	892a                	mv	s2,a0
    8000486a:	00a05563          	blez	a0,80004874 <fileread+0x56>
      f->off += r;
    8000486e:	509c                	lw	a5,32(s1)
    80004870:	9fa9                	addw	a5,a5,a0
    80004872:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004874:	6c88                	ld	a0,24(s1)
    80004876:	fffff097          	auipc	ra,0xfffff
    8000487a:	09e080e7          	jalr	158(ra) # 80003914 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000487e:	854a                	mv	a0,s2
    80004880:	70a2                	ld	ra,40(sp)
    80004882:	7402                	ld	s0,32(sp)
    80004884:	64e2                	ld	s1,24(sp)
    80004886:	6942                	ld	s2,16(sp)
    80004888:	69a2                	ld	s3,8(sp)
    8000488a:	6145                	addi	sp,sp,48
    8000488c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000488e:	6908                	ld	a0,16(a0)
    80004890:	00000097          	auipc	ra,0x0
    80004894:	418080e7          	jalr	1048(ra) # 80004ca8 <piperead>
    80004898:	892a                	mv	s2,a0
    8000489a:	b7d5                	j	8000487e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000489c:	02451783          	lh	a5,36(a0)
    800048a0:	03079693          	slli	a3,a5,0x30
    800048a4:	92c1                	srli	a3,a3,0x30
    800048a6:	4725                	li	a4,9
    800048a8:	02d76863          	bltu	a4,a3,800048d8 <fileread+0xba>
    800048ac:	0792                	slli	a5,a5,0x4
    800048ae:	0023d717          	auipc	a4,0x23d
    800048b2:	10270713          	addi	a4,a4,258 # 802419b0 <devsw>
    800048b6:	97ba                	add	a5,a5,a4
    800048b8:	639c                	ld	a5,0(a5)
    800048ba:	c38d                	beqz	a5,800048dc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048bc:	4505                	li	a0,1
    800048be:	9782                	jalr	a5
    800048c0:	892a                	mv	s2,a0
    800048c2:	bf75                	j	8000487e <fileread+0x60>
    panic("fileread");
    800048c4:	00004517          	auipc	a0,0x4
    800048c8:	ea450513          	addi	a0,a0,-348 # 80008768 <syscalls+0x258>
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	c7c080e7          	jalr	-900(ra) # 80000548 <panic>
    return -1;
    800048d4:	597d                	li	s2,-1
    800048d6:	b765                	j	8000487e <fileread+0x60>
      return -1;
    800048d8:	597d                	li	s2,-1
    800048da:	b755                	j	8000487e <fileread+0x60>
    800048dc:	597d                	li	s2,-1
    800048de:	b745                	j	8000487e <fileread+0x60>

00000000800048e0 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800048e0:	00954783          	lbu	a5,9(a0)
    800048e4:	14078563          	beqz	a5,80004a2e <filewrite+0x14e>
{
    800048e8:	715d                	addi	sp,sp,-80
    800048ea:	e486                	sd	ra,72(sp)
    800048ec:	e0a2                	sd	s0,64(sp)
    800048ee:	fc26                	sd	s1,56(sp)
    800048f0:	f84a                	sd	s2,48(sp)
    800048f2:	f44e                	sd	s3,40(sp)
    800048f4:	f052                	sd	s4,32(sp)
    800048f6:	ec56                	sd	s5,24(sp)
    800048f8:	e85a                	sd	s6,16(sp)
    800048fa:	e45e                	sd	s7,8(sp)
    800048fc:	e062                	sd	s8,0(sp)
    800048fe:	0880                	addi	s0,sp,80
    80004900:	892a                	mv	s2,a0
    80004902:	8aae                	mv	s5,a1
    80004904:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004906:	411c                	lw	a5,0(a0)
    80004908:	4705                	li	a4,1
    8000490a:	02e78263          	beq	a5,a4,8000492e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000490e:	470d                	li	a4,3
    80004910:	02e78563          	beq	a5,a4,8000493a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004914:	4709                	li	a4,2
    80004916:	10e79463          	bne	a5,a4,80004a1e <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000491a:	0ec05e63          	blez	a2,80004a16 <filewrite+0x136>
    int i = 0;
    8000491e:	4981                	li	s3,0
    80004920:	6b05                	lui	s6,0x1
    80004922:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004926:	6b85                	lui	s7,0x1
    80004928:	c00b8b9b          	addiw	s7,s7,-1024
    8000492c:	a851                	j	800049c0 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000492e:	6908                	ld	a0,16(a0)
    80004930:	00000097          	auipc	ra,0x0
    80004934:	254080e7          	jalr	596(ra) # 80004b84 <pipewrite>
    80004938:	a85d                	j	800049ee <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000493a:	02451783          	lh	a5,36(a0)
    8000493e:	03079693          	slli	a3,a5,0x30
    80004942:	92c1                	srli	a3,a3,0x30
    80004944:	4725                	li	a4,9
    80004946:	0ed76663          	bltu	a4,a3,80004a32 <filewrite+0x152>
    8000494a:	0792                	slli	a5,a5,0x4
    8000494c:	0023d717          	auipc	a4,0x23d
    80004950:	06470713          	addi	a4,a4,100 # 802419b0 <devsw>
    80004954:	97ba                	add	a5,a5,a4
    80004956:	679c                	ld	a5,8(a5)
    80004958:	cff9                	beqz	a5,80004a36 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    8000495a:	4505                	li	a0,1
    8000495c:	9782                	jalr	a5
    8000495e:	a841                	j	800049ee <filewrite+0x10e>
    80004960:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004964:	00000097          	auipc	ra,0x0
    80004968:	8ae080e7          	jalr	-1874(ra) # 80004212 <begin_op>
      ilock(f->ip);
    8000496c:	01893503          	ld	a0,24(s2)
    80004970:	fffff097          	auipc	ra,0xfffff
    80004974:	ee2080e7          	jalr	-286(ra) # 80003852 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004978:	8762                	mv	a4,s8
    8000497a:	02092683          	lw	a3,32(s2)
    8000497e:	01598633          	add	a2,s3,s5
    80004982:	4585                	li	a1,1
    80004984:	01893503          	ld	a0,24(s2)
    80004988:	fffff097          	auipc	ra,0xfffff
    8000498c:	276080e7          	jalr	630(ra) # 80003bfe <writei>
    80004990:	84aa                	mv	s1,a0
    80004992:	02a05f63          	blez	a0,800049d0 <filewrite+0xf0>
        f->off += r;
    80004996:	02092783          	lw	a5,32(s2)
    8000499a:	9fa9                	addw	a5,a5,a0
    8000499c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049a0:	01893503          	ld	a0,24(s2)
    800049a4:	fffff097          	auipc	ra,0xfffff
    800049a8:	f70080e7          	jalr	-144(ra) # 80003914 <iunlock>
      end_op();
    800049ac:	00000097          	auipc	ra,0x0
    800049b0:	8e6080e7          	jalr	-1818(ra) # 80004292 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800049b4:	049c1963          	bne	s8,s1,80004a06 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800049b8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049bc:	0349d663          	bge	s3,s4,800049e8 <filewrite+0x108>
      int n1 = n - i;
    800049c0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049c4:	84be                	mv	s1,a5
    800049c6:	2781                	sext.w	a5,a5
    800049c8:	f8fb5ce3          	bge	s6,a5,80004960 <filewrite+0x80>
    800049cc:	84de                	mv	s1,s7
    800049ce:	bf49                	j	80004960 <filewrite+0x80>
      iunlock(f->ip);
    800049d0:	01893503          	ld	a0,24(s2)
    800049d4:	fffff097          	auipc	ra,0xfffff
    800049d8:	f40080e7          	jalr	-192(ra) # 80003914 <iunlock>
      end_op();
    800049dc:	00000097          	auipc	ra,0x0
    800049e0:	8b6080e7          	jalr	-1866(ra) # 80004292 <end_op>
      if(r < 0)
    800049e4:	fc04d8e3          	bgez	s1,800049b4 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800049e8:	8552                	mv	a0,s4
    800049ea:	033a1863          	bne	s4,s3,80004a1a <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049ee:	60a6                	ld	ra,72(sp)
    800049f0:	6406                	ld	s0,64(sp)
    800049f2:	74e2                	ld	s1,56(sp)
    800049f4:	7942                	ld	s2,48(sp)
    800049f6:	79a2                	ld	s3,40(sp)
    800049f8:	7a02                	ld	s4,32(sp)
    800049fa:	6ae2                	ld	s5,24(sp)
    800049fc:	6b42                	ld	s6,16(sp)
    800049fe:	6ba2                	ld	s7,8(sp)
    80004a00:	6c02                	ld	s8,0(sp)
    80004a02:	6161                	addi	sp,sp,80
    80004a04:	8082                	ret
        panic("short filewrite");
    80004a06:	00004517          	auipc	a0,0x4
    80004a0a:	d7250513          	addi	a0,a0,-654 # 80008778 <syscalls+0x268>
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	b3a080e7          	jalr	-1222(ra) # 80000548 <panic>
    int i = 0;
    80004a16:	4981                	li	s3,0
    80004a18:	bfc1                	j	800049e8 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004a1a:	557d                	li	a0,-1
    80004a1c:	bfc9                	j	800049ee <filewrite+0x10e>
    panic("filewrite");
    80004a1e:	00004517          	auipc	a0,0x4
    80004a22:	d6a50513          	addi	a0,a0,-662 # 80008788 <syscalls+0x278>
    80004a26:	ffffc097          	auipc	ra,0xffffc
    80004a2a:	b22080e7          	jalr	-1246(ra) # 80000548 <panic>
    return -1;
    80004a2e:	557d                	li	a0,-1
}
    80004a30:	8082                	ret
      return -1;
    80004a32:	557d                	li	a0,-1
    80004a34:	bf6d                	j	800049ee <filewrite+0x10e>
    80004a36:	557d                	li	a0,-1
    80004a38:	bf5d                	j	800049ee <filewrite+0x10e>

0000000080004a3a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a3a:	7179                	addi	sp,sp,-48
    80004a3c:	f406                	sd	ra,40(sp)
    80004a3e:	f022                	sd	s0,32(sp)
    80004a40:	ec26                	sd	s1,24(sp)
    80004a42:	e84a                	sd	s2,16(sp)
    80004a44:	e44e                	sd	s3,8(sp)
    80004a46:	e052                	sd	s4,0(sp)
    80004a48:	1800                	addi	s0,sp,48
    80004a4a:	84aa                	mv	s1,a0
    80004a4c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a4e:	0005b023          	sd	zero,0(a1)
    80004a52:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a56:	00000097          	auipc	ra,0x0
    80004a5a:	bd2080e7          	jalr	-1070(ra) # 80004628 <filealloc>
    80004a5e:	e088                	sd	a0,0(s1)
    80004a60:	c551                	beqz	a0,80004aec <pipealloc+0xb2>
    80004a62:	00000097          	auipc	ra,0x0
    80004a66:	bc6080e7          	jalr	-1082(ra) # 80004628 <filealloc>
    80004a6a:	00aa3023          	sd	a0,0(s4)
    80004a6e:	c92d                	beqz	a0,80004ae0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a70:	ffffc097          	auipc	ra,0xffffc
    80004a74:	10c080e7          	jalr	268(ra) # 80000b7c <kalloc>
    80004a78:	892a                	mv	s2,a0
    80004a7a:	c125                	beqz	a0,80004ada <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a7c:	4985                	li	s3,1
    80004a7e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a82:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a86:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a8a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a8e:	00004597          	auipc	a1,0x4
    80004a92:	d0a58593          	addi	a1,a1,-758 # 80008798 <syscalls+0x288>
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	1e8080e7          	jalr	488(ra) # 80000c7e <initlock>
  (*f0)->type = FD_PIPE;
    80004a9e:	609c                	ld	a5,0(s1)
    80004aa0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004aa4:	609c                	ld	a5,0(s1)
    80004aa6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004aaa:	609c                	ld	a5,0(s1)
    80004aac:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ab0:	609c                	ld	a5,0(s1)
    80004ab2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ab6:	000a3783          	ld	a5,0(s4)
    80004aba:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004abe:	000a3783          	ld	a5,0(s4)
    80004ac2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ac6:	000a3783          	ld	a5,0(s4)
    80004aca:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ace:	000a3783          	ld	a5,0(s4)
    80004ad2:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ad6:	4501                	li	a0,0
    80004ad8:	a025                	j	80004b00 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ada:	6088                	ld	a0,0(s1)
    80004adc:	e501                	bnez	a0,80004ae4 <pipealloc+0xaa>
    80004ade:	a039                	j	80004aec <pipealloc+0xb2>
    80004ae0:	6088                	ld	a0,0(s1)
    80004ae2:	c51d                	beqz	a0,80004b10 <pipealloc+0xd6>
    fileclose(*f0);
    80004ae4:	00000097          	auipc	ra,0x0
    80004ae8:	c00080e7          	jalr	-1024(ra) # 800046e4 <fileclose>
  if(*f1)
    80004aec:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004af0:	557d                	li	a0,-1
  if(*f1)
    80004af2:	c799                	beqz	a5,80004b00 <pipealloc+0xc6>
    fileclose(*f1);
    80004af4:	853e                	mv	a0,a5
    80004af6:	00000097          	auipc	ra,0x0
    80004afa:	bee080e7          	jalr	-1042(ra) # 800046e4 <fileclose>
  return -1;
    80004afe:	557d                	li	a0,-1
}
    80004b00:	70a2                	ld	ra,40(sp)
    80004b02:	7402                	ld	s0,32(sp)
    80004b04:	64e2                	ld	s1,24(sp)
    80004b06:	6942                	ld	s2,16(sp)
    80004b08:	69a2                	ld	s3,8(sp)
    80004b0a:	6a02                	ld	s4,0(sp)
    80004b0c:	6145                	addi	sp,sp,48
    80004b0e:	8082                	ret
  return -1;
    80004b10:	557d                	li	a0,-1
    80004b12:	b7fd                	j	80004b00 <pipealloc+0xc6>

0000000080004b14 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b14:	1101                	addi	sp,sp,-32
    80004b16:	ec06                	sd	ra,24(sp)
    80004b18:	e822                	sd	s0,16(sp)
    80004b1a:	e426                	sd	s1,8(sp)
    80004b1c:	e04a                	sd	s2,0(sp)
    80004b1e:	1000                	addi	s0,sp,32
    80004b20:	84aa                	mv	s1,a0
    80004b22:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	1ea080e7          	jalr	490(ra) # 80000d0e <acquire>
  if(writable){
    80004b2c:	02090d63          	beqz	s2,80004b66 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b30:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b34:	21848513          	addi	a0,s1,536
    80004b38:	ffffe097          	auipc	ra,0xffffe
    80004b3c:	a5c080e7          	jalr	-1444(ra) # 80002594 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b40:	2204b783          	ld	a5,544(s1)
    80004b44:	eb95                	bnez	a5,80004b78 <pipeclose+0x64>
    release(&pi->lock);
    80004b46:	8526                	mv	a0,s1
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	27a080e7          	jalr	634(ra) # 80000dc2 <release>
    kfree((char*)pi);
    80004b50:	8526                	mv	a0,s1
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	ed2080e7          	jalr	-302(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004b5a:	60e2                	ld	ra,24(sp)
    80004b5c:	6442                	ld	s0,16(sp)
    80004b5e:	64a2                	ld	s1,8(sp)
    80004b60:	6902                	ld	s2,0(sp)
    80004b62:	6105                	addi	sp,sp,32
    80004b64:	8082                	ret
    pi->readopen = 0;
    80004b66:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b6a:	21c48513          	addi	a0,s1,540
    80004b6e:	ffffe097          	auipc	ra,0xffffe
    80004b72:	a26080e7          	jalr	-1498(ra) # 80002594 <wakeup>
    80004b76:	b7e9                	j	80004b40 <pipeclose+0x2c>
    release(&pi->lock);
    80004b78:	8526                	mv	a0,s1
    80004b7a:	ffffc097          	auipc	ra,0xffffc
    80004b7e:	248080e7          	jalr	584(ra) # 80000dc2 <release>
}
    80004b82:	bfe1                	j	80004b5a <pipeclose+0x46>

0000000080004b84 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b84:	7119                	addi	sp,sp,-128
    80004b86:	fc86                	sd	ra,120(sp)
    80004b88:	f8a2                	sd	s0,112(sp)
    80004b8a:	f4a6                	sd	s1,104(sp)
    80004b8c:	f0ca                	sd	s2,96(sp)
    80004b8e:	ecce                	sd	s3,88(sp)
    80004b90:	e8d2                	sd	s4,80(sp)
    80004b92:	e4d6                	sd	s5,72(sp)
    80004b94:	e0da                	sd	s6,64(sp)
    80004b96:	fc5e                	sd	s7,56(sp)
    80004b98:	f862                	sd	s8,48(sp)
    80004b9a:	f466                	sd	s9,40(sp)
    80004b9c:	f06a                	sd	s10,32(sp)
    80004b9e:	ec6e                	sd	s11,24(sp)
    80004ba0:	0100                	addi	s0,sp,128
    80004ba2:	84aa                	mv	s1,a0
    80004ba4:	8cae                	mv	s9,a1
    80004ba6:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004ba8:	ffffd097          	auipc	ra,0xffffd
    80004bac:	056080e7          	jalr	86(ra) # 80001bfe <myproc>
    80004bb0:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	15a080e7          	jalr	346(ra) # 80000d0e <acquire>
  for(i = 0; i < n; i++){
    80004bbc:	0d605963          	blez	s6,80004c8e <pipewrite+0x10a>
    80004bc0:	89a6                	mv	s3,s1
    80004bc2:	3b7d                	addiw	s6,s6,-1
    80004bc4:	1b02                	slli	s6,s6,0x20
    80004bc6:	020b5b13          	srli	s6,s6,0x20
    80004bca:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004bcc:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bd0:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bd4:	5dfd                	li	s11,-1
    80004bd6:	000b8d1b          	sext.w	s10,s7
    80004bda:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004bdc:	2184a783          	lw	a5,536(s1)
    80004be0:	21c4a703          	lw	a4,540(s1)
    80004be4:	2007879b          	addiw	a5,a5,512
    80004be8:	02f71b63          	bne	a4,a5,80004c1e <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004bec:	2204a783          	lw	a5,544(s1)
    80004bf0:	cbad                	beqz	a5,80004c62 <pipewrite+0xde>
    80004bf2:	03092783          	lw	a5,48(s2)
    80004bf6:	e7b5                	bnez	a5,80004c62 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004bf8:	8556                	mv	a0,s5
    80004bfa:	ffffe097          	auipc	ra,0xffffe
    80004bfe:	99a080e7          	jalr	-1638(ra) # 80002594 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c02:	85ce                	mv	a1,s3
    80004c04:	8552                	mv	a0,s4
    80004c06:	ffffe097          	auipc	ra,0xffffe
    80004c0a:	808080e7          	jalr	-2040(ra) # 8000240e <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c0e:	2184a783          	lw	a5,536(s1)
    80004c12:	21c4a703          	lw	a4,540(s1)
    80004c16:	2007879b          	addiw	a5,a5,512
    80004c1a:	fcf709e3          	beq	a4,a5,80004bec <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c1e:	4685                	li	a3,1
    80004c20:	019b8633          	add	a2,s7,s9
    80004c24:	f8f40593          	addi	a1,s0,-113
    80004c28:	05093503          	ld	a0,80(s2)
    80004c2c:	ffffd097          	auipc	ra,0xffffd
    80004c30:	b8e080e7          	jalr	-1138(ra) # 800017ba <copyin>
    80004c34:	05b50e63          	beq	a0,s11,80004c90 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c38:	21c4a783          	lw	a5,540(s1)
    80004c3c:	0017871b          	addiw	a4,a5,1
    80004c40:	20e4ae23          	sw	a4,540(s1)
    80004c44:	1ff7f793          	andi	a5,a5,511
    80004c48:	97a6                	add	a5,a5,s1
    80004c4a:	f8f44703          	lbu	a4,-113(s0)
    80004c4e:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c52:	001d0c1b          	addiw	s8,s10,1
    80004c56:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004c5a:	036b8b63          	beq	s7,s6,80004c90 <pipewrite+0x10c>
    80004c5e:	8bbe                	mv	s7,a5
    80004c60:	bf9d                	j	80004bd6 <pipewrite+0x52>
        release(&pi->lock);
    80004c62:	8526                	mv	a0,s1
    80004c64:	ffffc097          	auipc	ra,0xffffc
    80004c68:	15e080e7          	jalr	350(ra) # 80000dc2 <release>
        return -1;
    80004c6c:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004c6e:	8562                	mv	a0,s8
    80004c70:	70e6                	ld	ra,120(sp)
    80004c72:	7446                	ld	s0,112(sp)
    80004c74:	74a6                	ld	s1,104(sp)
    80004c76:	7906                	ld	s2,96(sp)
    80004c78:	69e6                	ld	s3,88(sp)
    80004c7a:	6a46                	ld	s4,80(sp)
    80004c7c:	6aa6                	ld	s5,72(sp)
    80004c7e:	6b06                	ld	s6,64(sp)
    80004c80:	7be2                	ld	s7,56(sp)
    80004c82:	7c42                	ld	s8,48(sp)
    80004c84:	7ca2                	ld	s9,40(sp)
    80004c86:	7d02                	ld	s10,32(sp)
    80004c88:	6de2                	ld	s11,24(sp)
    80004c8a:	6109                	addi	sp,sp,128
    80004c8c:	8082                	ret
  for(i = 0; i < n; i++){
    80004c8e:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004c90:	21848513          	addi	a0,s1,536
    80004c94:	ffffe097          	auipc	ra,0xffffe
    80004c98:	900080e7          	jalr	-1792(ra) # 80002594 <wakeup>
  release(&pi->lock);
    80004c9c:	8526                	mv	a0,s1
    80004c9e:	ffffc097          	auipc	ra,0xffffc
    80004ca2:	124080e7          	jalr	292(ra) # 80000dc2 <release>
  return i;
    80004ca6:	b7e1                	j	80004c6e <pipewrite+0xea>

0000000080004ca8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ca8:	715d                	addi	sp,sp,-80
    80004caa:	e486                	sd	ra,72(sp)
    80004cac:	e0a2                	sd	s0,64(sp)
    80004cae:	fc26                	sd	s1,56(sp)
    80004cb0:	f84a                	sd	s2,48(sp)
    80004cb2:	f44e                	sd	s3,40(sp)
    80004cb4:	f052                	sd	s4,32(sp)
    80004cb6:	ec56                	sd	s5,24(sp)
    80004cb8:	e85a                	sd	s6,16(sp)
    80004cba:	0880                	addi	s0,sp,80
    80004cbc:	84aa                	mv	s1,a0
    80004cbe:	892e                	mv	s2,a1
    80004cc0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cc2:	ffffd097          	auipc	ra,0xffffd
    80004cc6:	f3c080e7          	jalr	-196(ra) # 80001bfe <myproc>
    80004cca:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ccc:	8b26                	mv	s6,s1
    80004cce:	8526                	mv	a0,s1
    80004cd0:	ffffc097          	auipc	ra,0xffffc
    80004cd4:	03e080e7          	jalr	62(ra) # 80000d0e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cd8:	2184a703          	lw	a4,536(s1)
    80004cdc:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ce0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ce4:	02f71463          	bne	a4,a5,80004d0c <piperead+0x64>
    80004ce8:	2244a783          	lw	a5,548(s1)
    80004cec:	c385                	beqz	a5,80004d0c <piperead+0x64>
    if(pr->killed){
    80004cee:	030a2783          	lw	a5,48(s4)
    80004cf2:	ebc1                	bnez	a5,80004d82 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cf4:	85da                	mv	a1,s6
    80004cf6:	854e                	mv	a0,s3
    80004cf8:	ffffd097          	auipc	ra,0xffffd
    80004cfc:	716080e7          	jalr	1814(ra) # 8000240e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d00:	2184a703          	lw	a4,536(s1)
    80004d04:	21c4a783          	lw	a5,540(s1)
    80004d08:	fef700e3          	beq	a4,a5,80004ce8 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d0c:	09505263          	blez	s5,80004d90 <piperead+0xe8>
    80004d10:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d12:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d14:	2184a783          	lw	a5,536(s1)
    80004d18:	21c4a703          	lw	a4,540(s1)
    80004d1c:	02f70d63          	beq	a4,a5,80004d56 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d20:	0017871b          	addiw	a4,a5,1
    80004d24:	20e4ac23          	sw	a4,536(s1)
    80004d28:	1ff7f793          	andi	a5,a5,511
    80004d2c:	97a6                	add	a5,a5,s1
    80004d2e:	0187c783          	lbu	a5,24(a5)
    80004d32:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d36:	4685                	li	a3,1
    80004d38:	fbf40613          	addi	a2,s0,-65
    80004d3c:	85ca                	mv	a1,s2
    80004d3e:	050a3503          	ld	a0,80(s4)
    80004d42:	ffffd097          	auipc	ra,0xffffd
    80004d46:	c80080e7          	jalr	-896(ra) # 800019c2 <copyout>
    80004d4a:	01650663          	beq	a0,s6,80004d56 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d4e:	2985                	addiw	s3,s3,1
    80004d50:	0905                	addi	s2,s2,1
    80004d52:	fd3a91e3          	bne	s5,s3,80004d14 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d56:	21c48513          	addi	a0,s1,540
    80004d5a:	ffffe097          	auipc	ra,0xffffe
    80004d5e:	83a080e7          	jalr	-1990(ra) # 80002594 <wakeup>
  release(&pi->lock);
    80004d62:	8526                	mv	a0,s1
    80004d64:	ffffc097          	auipc	ra,0xffffc
    80004d68:	05e080e7          	jalr	94(ra) # 80000dc2 <release>
  return i;
}
    80004d6c:	854e                	mv	a0,s3
    80004d6e:	60a6                	ld	ra,72(sp)
    80004d70:	6406                	ld	s0,64(sp)
    80004d72:	74e2                	ld	s1,56(sp)
    80004d74:	7942                	ld	s2,48(sp)
    80004d76:	79a2                	ld	s3,40(sp)
    80004d78:	7a02                	ld	s4,32(sp)
    80004d7a:	6ae2                	ld	s5,24(sp)
    80004d7c:	6b42                	ld	s6,16(sp)
    80004d7e:	6161                	addi	sp,sp,80
    80004d80:	8082                	ret
      release(&pi->lock);
    80004d82:	8526                	mv	a0,s1
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	03e080e7          	jalr	62(ra) # 80000dc2 <release>
      return -1;
    80004d8c:	59fd                	li	s3,-1
    80004d8e:	bff9                	j	80004d6c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d90:	4981                	li	s3,0
    80004d92:	b7d1                	j	80004d56 <piperead+0xae>

0000000080004d94 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d94:	df010113          	addi	sp,sp,-528
    80004d98:	20113423          	sd	ra,520(sp)
    80004d9c:	20813023          	sd	s0,512(sp)
    80004da0:	ffa6                	sd	s1,504(sp)
    80004da2:	fbca                	sd	s2,496(sp)
    80004da4:	f7ce                	sd	s3,488(sp)
    80004da6:	f3d2                	sd	s4,480(sp)
    80004da8:	efd6                	sd	s5,472(sp)
    80004daa:	ebda                	sd	s6,464(sp)
    80004dac:	e7de                	sd	s7,456(sp)
    80004dae:	e3e2                	sd	s8,448(sp)
    80004db0:	ff66                	sd	s9,440(sp)
    80004db2:	fb6a                	sd	s10,432(sp)
    80004db4:	f76e                	sd	s11,424(sp)
    80004db6:	0c00                	addi	s0,sp,528
    80004db8:	84aa                	mv	s1,a0
    80004dba:	dea43c23          	sd	a0,-520(s0)
    80004dbe:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dc2:	ffffd097          	auipc	ra,0xffffd
    80004dc6:	e3c080e7          	jalr	-452(ra) # 80001bfe <myproc>
    80004dca:	892a                	mv	s2,a0

  begin_op();
    80004dcc:	fffff097          	auipc	ra,0xfffff
    80004dd0:	446080e7          	jalr	1094(ra) # 80004212 <begin_op>

  if((ip = namei(path)) == 0){
    80004dd4:	8526                	mv	a0,s1
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	230080e7          	jalr	560(ra) # 80004006 <namei>
    80004dde:	c92d                	beqz	a0,80004e50 <exec+0xbc>
    80004de0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004de2:	fffff097          	auipc	ra,0xfffff
    80004de6:	a70080e7          	jalr	-1424(ra) # 80003852 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dea:	04000713          	li	a4,64
    80004dee:	4681                	li	a3,0
    80004df0:	e4840613          	addi	a2,s0,-440
    80004df4:	4581                	li	a1,0
    80004df6:	8526                	mv	a0,s1
    80004df8:	fffff097          	auipc	ra,0xfffff
    80004dfc:	d0e080e7          	jalr	-754(ra) # 80003b06 <readi>
    80004e00:	04000793          	li	a5,64
    80004e04:	00f51a63          	bne	a0,a5,80004e18 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e08:	e4842703          	lw	a4,-440(s0)
    80004e0c:	464c47b7          	lui	a5,0x464c4
    80004e10:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e14:	04f70463          	beq	a4,a5,80004e5c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e18:	8526                	mv	a0,s1
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	c9a080e7          	jalr	-870(ra) # 80003ab4 <iunlockput>
    end_op();
    80004e22:	fffff097          	auipc	ra,0xfffff
    80004e26:	470080e7          	jalr	1136(ra) # 80004292 <end_op>
  }
  return -1;
    80004e2a:	557d                	li	a0,-1
}
    80004e2c:	20813083          	ld	ra,520(sp)
    80004e30:	20013403          	ld	s0,512(sp)
    80004e34:	74fe                	ld	s1,504(sp)
    80004e36:	795e                	ld	s2,496(sp)
    80004e38:	79be                	ld	s3,488(sp)
    80004e3a:	7a1e                	ld	s4,480(sp)
    80004e3c:	6afe                	ld	s5,472(sp)
    80004e3e:	6b5e                	ld	s6,464(sp)
    80004e40:	6bbe                	ld	s7,456(sp)
    80004e42:	6c1e                	ld	s8,448(sp)
    80004e44:	7cfa                	ld	s9,440(sp)
    80004e46:	7d5a                	ld	s10,432(sp)
    80004e48:	7dba                	ld	s11,424(sp)
    80004e4a:	21010113          	addi	sp,sp,528
    80004e4e:	8082                	ret
    end_op();
    80004e50:	fffff097          	auipc	ra,0xfffff
    80004e54:	442080e7          	jalr	1090(ra) # 80004292 <end_op>
    return -1;
    80004e58:	557d                	li	a0,-1
    80004e5a:	bfc9                	j	80004e2c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e5c:	854a                	mv	a0,s2
    80004e5e:	ffffd097          	auipc	ra,0xffffd
    80004e62:	e64080e7          	jalr	-412(ra) # 80001cc2 <proc_pagetable>
    80004e66:	8baa                	mv	s7,a0
    80004e68:	d945                	beqz	a0,80004e18 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e6a:	e6842983          	lw	s3,-408(s0)
    80004e6e:	e8045783          	lhu	a5,-384(s0)
    80004e72:	c7ad                	beqz	a5,80004edc <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e74:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e76:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004e78:	6c85                	lui	s9,0x1
    80004e7a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e7e:	def43823          	sd	a5,-528(s0)
    80004e82:	a42d                	j	800050ac <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e84:	00004517          	auipc	a0,0x4
    80004e88:	91c50513          	addi	a0,a0,-1764 # 800087a0 <syscalls+0x290>
    80004e8c:	ffffb097          	auipc	ra,0xffffb
    80004e90:	6bc080e7          	jalr	1724(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e94:	8756                	mv	a4,s5
    80004e96:	012d86bb          	addw	a3,s11,s2
    80004e9a:	4581                	li	a1,0
    80004e9c:	8526                	mv	a0,s1
    80004e9e:	fffff097          	auipc	ra,0xfffff
    80004ea2:	c68080e7          	jalr	-920(ra) # 80003b06 <readi>
    80004ea6:	2501                	sext.w	a0,a0
    80004ea8:	1aaa9963          	bne	s5,a0,8000505a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004eac:	6785                	lui	a5,0x1
    80004eae:	0127893b          	addw	s2,a5,s2
    80004eb2:	77fd                	lui	a5,0xfffff
    80004eb4:	01478a3b          	addw	s4,a5,s4
    80004eb8:	1f897163          	bgeu	s2,s8,8000509a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004ebc:	02091593          	slli	a1,s2,0x20
    80004ec0:	9181                	srli	a1,a1,0x20
    80004ec2:	95ea                	add	a1,a1,s10
    80004ec4:	855e                	mv	a0,s7
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	2d6080e7          	jalr	726(ra) # 8000119c <walkaddr>
    80004ece:	862a                	mv	a2,a0
    if(pa == 0)
    80004ed0:	d955                	beqz	a0,80004e84 <exec+0xf0>
      n = PGSIZE;
    80004ed2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ed4:	fd9a70e3          	bgeu	s4,s9,80004e94 <exec+0x100>
      n = sz - i;
    80004ed8:	8ad2                	mv	s5,s4
    80004eda:	bf6d                	j	80004e94 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004edc:	4901                	li	s2,0
  iunlockput(ip);
    80004ede:	8526                	mv	a0,s1
    80004ee0:	fffff097          	auipc	ra,0xfffff
    80004ee4:	bd4080e7          	jalr	-1068(ra) # 80003ab4 <iunlockput>
  end_op();
    80004ee8:	fffff097          	auipc	ra,0xfffff
    80004eec:	3aa080e7          	jalr	938(ra) # 80004292 <end_op>
  p = myproc();
    80004ef0:	ffffd097          	auipc	ra,0xffffd
    80004ef4:	d0e080e7          	jalr	-754(ra) # 80001bfe <myproc>
    80004ef8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004efa:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004efe:	6785                	lui	a5,0x1
    80004f00:	17fd                	addi	a5,a5,-1
    80004f02:	993e                	add	s2,s2,a5
    80004f04:	757d                	lui	a0,0xfffff
    80004f06:	00a977b3          	and	a5,s2,a0
    80004f0a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f0e:	6609                	lui	a2,0x2
    80004f10:	963e                	add	a2,a2,a5
    80004f12:	85be                	mv	a1,a5
    80004f14:	855e                	mv	a0,s7
    80004f16:	ffffc097          	auipc	ra,0xffffc
    80004f1a:	66a080e7          	jalr	1642(ra) # 80001580 <uvmalloc>
    80004f1e:	8b2a                	mv	s6,a0
  ip = 0;
    80004f20:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f22:	12050c63          	beqz	a0,8000505a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f26:	75f9                	lui	a1,0xffffe
    80004f28:	95aa                	add	a1,a1,a0
    80004f2a:	855e                	mv	a0,s7
    80004f2c:	ffffd097          	auipc	ra,0xffffd
    80004f30:	85c080e7          	jalr	-1956(ra) # 80001788 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f34:	7c7d                	lui	s8,0xfffff
    80004f36:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f38:	e0043783          	ld	a5,-512(s0)
    80004f3c:	6388                	ld	a0,0(a5)
    80004f3e:	c535                	beqz	a0,80004faa <exec+0x216>
    80004f40:	e8840993          	addi	s3,s0,-376
    80004f44:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f48:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f4a:	ffffc097          	auipc	ra,0xffffc
    80004f4e:	048080e7          	jalr	72(ra) # 80000f92 <strlen>
    80004f52:	2505                	addiw	a0,a0,1
    80004f54:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f58:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f5c:	13896363          	bltu	s2,s8,80005082 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f60:	e0043d83          	ld	s11,-512(s0)
    80004f64:	000dba03          	ld	s4,0(s11)
    80004f68:	8552                	mv	a0,s4
    80004f6a:	ffffc097          	auipc	ra,0xffffc
    80004f6e:	028080e7          	jalr	40(ra) # 80000f92 <strlen>
    80004f72:	0015069b          	addiw	a3,a0,1
    80004f76:	8652                	mv	a2,s4
    80004f78:	85ca                	mv	a1,s2
    80004f7a:	855e                	mv	a0,s7
    80004f7c:	ffffd097          	auipc	ra,0xffffd
    80004f80:	a46080e7          	jalr	-1466(ra) # 800019c2 <copyout>
    80004f84:	10054363          	bltz	a0,8000508a <exec+0x2f6>
    ustack[argc] = sp;
    80004f88:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f8c:	0485                	addi	s1,s1,1
    80004f8e:	008d8793          	addi	a5,s11,8
    80004f92:	e0f43023          	sd	a5,-512(s0)
    80004f96:	008db503          	ld	a0,8(s11)
    80004f9a:	c911                	beqz	a0,80004fae <exec+0x21a>
    if(argc >= MAXARG)
    80004f9c:	09a1                	addi	s3,s3,8
    80004f9e:	fb3c96e3          	bne	s9,s3,80004f4a <exec+0x1b6>
  sz = sz1;
    80004fa2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fa6:	4481                	li	s1,0
    80004fa8:	a84d                	j	8000505a <exec+0x2c6>
  sp = sz;
    80004faa:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fac:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fae:	00349793          	slli	a5,s1,0x3
    80004fb2:	f9040713          	addi	a4,s0,-112
    80004fb6:	97ba                	add	a5,a5,a4
    80004fb8:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004fbc:	00148693          	addi	a3,s1,1
    80004fc0:	068e                	slli	a3,a3,0x3
    80004fc2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fc6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fca:	01897663          	bgeu	s2,s8,80004fd6 <exec+0x242>
  sz = sz1;
    80004fce:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fd2:	4481                	li	s1,0
    80004fd4:	a059                	j	8000505a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fd6:	e8840613          	addi	a2,s0,-376
    80004fda:	85ca                	mv	a1,s2
    80004fdc:	855e                	mv	a0,s7
    80004fde:	ffffd097          	auipc	ra,0xffffd
    80004fe2:	9e4080e7          	jalr	-1564(ra) # 800019c2 <copyout>
    80004fe6:	0a054663          	bltz	a0,80005092 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004fea:	058ab783          	ld	a5,88(s5)
    80004fee:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ff2:	df843783          	ld	a5,-520(s0)
    80004ff6:	0007c703          	lbu	a4,0(a5)
    80004ffa:	cf11                	beqz	a4,80005016 <exec+0x282>
    80004ffc:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ffe:	02f00693          	li	a3,47
    80005002:	a029                	j	8000500c <exec+0x278>
  for(last=s=path; *s; s++)
    80005004:	0785                	addi	a5,a5,1
    80005006:	fff7c703          	lbu	a4,-1(a5)
    8000500a:	c711                	beqz	a4,80005016 <exec+0x282>
    if(*s == '/')
    8000500c:	fed71ce3          	bne	a4,a3,80005004 <exec+0x270>
      last = s+1;
    80005010:	def43c23          	sd	a5,-520(s0)
    80005014:	bfc5                	j	80005004 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005016:	4641                	li	a2,16
    80005018:	df843583          	ld	a1,-520(s0)
    8000501c:	158a8513          	addi	a0,s5,344
    80005020:	ffffc097          	auipc	ra,0xffffc
    80005024:	f40080e7          	jalr	-192(ra) # 80000f60 <safestrcpy>
  oldpagetable = p->pagetable;
    80005028:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000502c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005030:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005034:	058ab783          	ld	a5,88(s5)
    80005038:	e6043703          	ld	a4,-416(s0)
    8000503c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000503e:	058ab783          	ld	a5,88(s5)
    80005042:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005046:	85ea                	mv	a1,s10
    80005048:	ffffd097          	auipc	ra,0xffffd
    8000504c:	d16080e7          	jalr	-746(ra) # 80001d5e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005050:	0004851b          	sext.w	a0,s1
    80005054:	bbe1                	j	80004e2c <exec+0x98>
    80005056:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000505a:	e0843583          	ld	a1,-504(s0)
    8000505e:	855e                	mv	a0,s7
    80005060:	ffffd097          	auipc	ra,0xffffd
    80005064:	cfe080e7          	jalr	-770(ra) # 80001d5e <proc_freepagetable>
  if(ip){
    80005068:	da0498e3          	bnez	s1,80004e18 <exec+0x84>
  return -1;
    8000506c:	557d                	li	a0,-1
    8000506e:	bb7d                	j	80004e2c <exec+0x98>
    80005070:	e1243423          	sd	s2,-504(s0)
    80005074:	b7dd                	j	8000505a <exec+0x2c6>
    80005076:	e1243423          	sd	s2,-504(s0)
    8000507a:	b7c5                	j	8000505a <exec+0x2c6>
    8000507c:	e1243423          	sd	s2,-504(s0)
    80005080:	bfe9                	j	8000505a <exec+0x2c6>
  sz = sz1;
    80005082:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005086:	4481                	li	s1,0
    80005088:	bfc9                	j	8000505a <exec+0x2c6>
  sz = sz1;
    8000508a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000508e:	4481                	li	s1,0
    80005090:	b7e9                	j	8000505a <exec+0x2c6>
  sz = sz1;
    80005092:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005096:	4481                	li	s1,0
    80005098:	b7c9                	j	8000505a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000509a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000509e:	2b05                	addiw	s6,s6,1
    800050a0:	0389899b          	addiw	s3,s3,56
    800050a4:	e8045783          	lhu	a5,-384(s0)
    800050a8:	e2fb5be3          	bge	s6,a5,80004ede <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050ac:	2981                	sext.w	s3,s3
    800050ae:	03800713          	li	a4,56
    800050b2:	86ce                	mv	a3,s3
    800050b4:	e1040613          	addi	a2,s0,-496
    800050b8:	4581                	li	a1,0
    800050ba:	8526                	mv	a0,s1
    800050bc:	fffff097          	auipc	ra,0xfffff
    800050c0:	a4a080e7          	jalr	-1462(ra) # 80003b06 <readi>
    800050c4:	03800793          	li	a5,56
    800050c8:	f8f517e3          	bne	a0,a5,80005056 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800050cc:	e1042783          	lw	a5,-496(s0)
    800050d0:	4705                	li	a4,1
    800050d2:	fce796e3          	bne	a5,a4,8000509e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800050d6:	e3843603          	ld	a2,-456(s0)
    800050da:	e3043783          	ld	a5,-464(s0)
    800050de:	f8f669e3          	bltu	a2,a5,80005070 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050e2:	e2043783          	ld	a5,-480(s0)
    800050e6:	963e                	add	a2,a2,a5
    800050e8:	f8f667e3          	bltu	a2,a5,80005076 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050ec:	85ca                	mv	a1,s2
    800050ee:	855e                	mv	a0,s7
    800050f0:	ffffc097          	auipc	ra,0xffffc
    800050f4:	490080e7          	jalr	1168(ra) # 80001580 <uvmalloc>
    800050f8:	e0a43423          	sd	a0,-504(s0)
    800050fc:	d141                	beqz	a0,8000507c <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    800050fe:	e2043d03          	ld	s10,-480(s0)
    80005102:	df043783          	ld	a5,-528(s0)
    80005106:	00fd77b3          	and	a5,s10,a5
    8000510a:	fba1                	bnez	a5,8000505a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000510c:	e1842d83          	lw	s11,-488(s0)
    80005110:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005114:	f80c03e3          	beqz	s8,8000509a <exec+0x306>
    80005118:	8a62                	mv	s4,s8
    8000511a:	4901                	li	s2,0
    8000511c:	b345                	j	80004ebc <exec+0x128>

000000008000511e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000511e:	7179                	addi	sp,sp,-48
    80005120:	f406                	sd	ra,40(sp)
    80005122:	f022                	sd	s0,32(sp)
    80005124:	ec26                	sd	s1,24(sp)
    80005126:	e84a                	sd	s2,16(sp)
    80005128:	1800                	addi	s0,sp,48
    8000512a:	892e                	mv	s2,a1
    8000512c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000512e:	fdc40593          	addi	a1,s0,-36
    80005132:	ffffe097          	auipc	ra,0xffffe
    80005136:	bae080e7          	jalr	-1106(ra) # 80002ce0 <argint>
    8000513a:	04054063          	bltz	a0,8000517a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000513e:	fdc42703          	lw	a4,-36(s0)
    80005142:	47bd                	li	a5,15
    80005144:	02e7ed63          	bltu	a5,a4,8000517e <argfd+0x60>
    80005148:	ffffd097          	auipc	ra,0xffffd
    8000514c:	ab6080e7          	jalr	-1354(ra) # 80001bfe <myproc>
    80005150:	fdc42703          	lw	a4,-36(s0)
    80005154:	01a70793          	addi	a5,a4,26
    80005158:	078e                	slli	a5,a5,0x3
    8000515a:	953e                	add	a0,a0,a5
    8000515c:	611c                	ld	a5,0(a0)
    8000515e:	c395                	beqz	a5,80005182 <argfd+0x64>
    return -1;
  if(pfd)
    80005160:	00090463          	beqz	s2,80005168 <argfd+0x4a>
    *pfd = fd;
    80005164:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005168:	4501                	li	a0,0
  if(pf)
    8000516a:	c091                	beqz	s1,8000516e <argfd+0x50>
    *pf = f;
    8000516c:	e09c                	sd	a5,0(s1)
}
    8000516e:	70a2                	ld	ra,40(sp)
    80005170:	7402                	ld	s0,32(sp)
    80005172:	64e2                	ld	s1,24(sp)
    80005174:	6942                	ld	s2,16(sp)
    80005176:	6145                	addi	sp,sp,48
    80005178:	8082                	ret
    return -1;
    8000517a:	557d                	li	a0,-1
    8000517c:	bfcd                	j	8000516e <argfd+0x50>
    return -1;
    8000517e:	557d                	li	a0,-1
    80005180:	b7fd                	j	8000516e <argfd+0x50>
    80005182:	557d                	li	a0,-1
    80005184:	b7ed                	j	8000516e <argfd+0x50>

0000000080005186 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005186:	1101                	addi	sp,sp,-32
    80005188:	ec06                	sd	ra,24(sp)
    8000518a:	e822                	sd	s0,16(sp)
    8000518c:	e426                	sd	s1,8(sp)
    8000518e:	1000                	addi	s0,sp,32
    80005190:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005192:	ffffd097          	auipc	ra,0xffffd
    80005196:	a6c080e7          	jalr	-1428(ra) # 80001bfe <myproc>
    8000519a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000519c:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7fdb90d0>
    800051a0:	4501                	li	a0,0
    800051a2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051a4:	6398                	ld	a4,0(a5)
    800051a6:	cb19                	beqz	a4,800051bc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051a8:	2505                	addiw	a0,a0,1
    800051aa:	07a1                	addi	a5,a5,8
    800051ac:	fed51ce3          	bne	a0,a3,800051a4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051b0:	557d                	li	a0,-1
}
    800051b2:	60e2                	ld	ra,24(sp)
    800051b4:	6442                	ld	s0,16(sp)
    800051b6:	64a2                	ld	s1,8(sp)
    800051b8:	6105                	addi	sp,sp,32
    800051ba:	8082                	ret
      p->ofile[fd] = f;
    800051bc:	01a50793          	addi	a5,a0,26
    800051c0:	078e                	slli	a5,a5,0x3
    800051c2:	963e                	add	a2,a2,a5
    800051c4:	e204                	sd	s1,0(a2)
      return fd;
    800051c6:	b7f5                	j	800051b2 <fdalloc+0x2c>

00000000800051c8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051c8:	715d                	addi	sp,sp,-80
    800051ca:	e486                	sd	ra,72(sp)
    800051cc:	e0a2                	sd	s0,64(sp)
    800051ce:	fc26                	sd	s1,56(sp)
    800051d0:	f84a                	sd	s2,48(sp)
    800051d2:	f44e                	sd	s3,40(sp)
    800051d4:	f052                	sd	s4,32(sp)
    800051d6:	ec56                	sd	s5,24(sp)
    800051d8:	0880                	addi	s0,sp,80
    800051da:	89ae                	mv	s3,a1
    800051dc:	8ab2                	mv	s5,a2
    800051de:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051e0:	fb040593          	addi	a1,s0,-80
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	e40080e7          	jalr	-448(ra) # 80004024 <nameiparent>
    800051ec:	892a                	mv	s2,a0
    800051ee:	12050f63          	beqz	a0,8000532c <create+0x164>
    return 0;

  ilock(dp);
    800051f2:	ffffe097          	auipc	ra,0xffffe
    800051f6:	660080e7          	jalr	1632(ra) # 80003852 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051fa:	4601                	li	a2,0
    800051fc:	fb040593          	addi	a1,s0,-80
    80005200:	854a                	mv	a0,s2
    80005202:	fffff097          	auipc	ra,0xfffff
    80005206:	b32080e7          	jalr	-1230(ra) # 80003d34 <dirlookup>
    8000520a:	84aa                	mv	s1,a0
    8000520c:	c921                	beqz	a0,8000525c <create+0x94>
    iunlockput(dp);
    8000520e:	854a                	mv	a0,s2
    80005210:	fffff097          	auipc	ra,0xfffff
    80005214:	8a4080e7          	jalr	-1884(ra) # 80003ab4 <iunlockput>
    ilock(ip);
    80005218:	8526                	mv	a0,s1
    8000521a:	ffffe097          	auipc	ra,0xffffe
    8000521e:	638080e7          	jalr	1592(ra) # 80003852 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005222:	2981                	sext.w	s3,s3
    80005224:	4789                	li	a5,2
    80005226:	02f99463          	bne	s3,a5,8000524e <create+0x86>
    8000522a:	0444d783          	lhu	a5,68(s1)
    8000522e:	37f9                	addiw	a5,a5,-2
    80005230:	17c2                	slli	a5,a5,0x30
    80005232:	93c1                	srli	a5,a5,0x30
    80005234:	4705                	li	a4,1
    80005236:	00f76c63          	bltu	a4,a5,8000524e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000523a:	8526                	mv	a0,s1
    8000523c:	60a6                	ld	ra,72(sp)
    8000523e:	6406                	ld	s0,64(sp)
    80005240:	74e2                	ld	s1,56(sp)
    80005242:	7942                	ld	s2,48(sp)
    80005244:	79a2                	ld	s3,40(sp)
    80005246:	7a02                	ld	s4,32(sp)
    80005248:	6ae2                	ld	s5,24(sp)
    8000524a:	6161                	addi	sp,sp,80
    8000524c:	8082                	ret
    iunlockput(ip);
    8000524e:	8526                	mv	a0,s1
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	864080e7          	jalr	-1948(ra) # 80003ab4 <iunlockput>
    return 0;
    80005258:	4481                	li	s1,0
    8000525a:	b7c5                	j	8000523a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000525c:	85ce                	mv	a1,s3
    8000525e:	00092503          	lw	a0,0(s2)
    80005262:	ffffe097          	auipc	ra,0xffffe
    80005266:	458080e7          	jalr	1112(ra) # 800036ba <ialloc>
    8000526a:	84aa                	mv	s1,a0
    8000526c:	c529                	beqz	a0,800052b6 <create+0xee>
  ilock(ip);
    8000526e:	ffffe097          	auipc	ra,0xffffe
    80005272:	5e4080e7          	jalr	1508(ra) # 80003852 <ilock>
  ip->major = major;
    80005276:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000527a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000527e:	4785                	li	a5,1
    80005280:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005284:	8526                	mv	a0,s1
    80005286:	ffffe097          	auipc	ra,0xffffe
    8000528a:	502080e7          	jalr	1282(ra) # 80003788 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000528e:	2981                	sext.w	s3,s3
    80005290:	4785                	li	a5,1
    80005292:	02f98a63          	beq	s3,a5,800052c6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005296:	40d0                	lw	a2,4(s1)
    80005298:	fb040593          	addi	a1,s0,-80
    8000529c:	854a                	mv	a0,s2
    8000529e:	fffff097          	auipc	ra,0xfffff
    800052a2:	ca6080e7          	jalr	-858(ra) # 80003f44 <dirlink>
    800052a6:	06054b63          	bltz	a0,8000531c <create+0x154>
  iunlockput(dp);
    800052aa:	854a                	mv	a0,s2
    800052ac:	fffff097          	auipc	ra,0xfffff
    800052b0:	808080e7          	jalr	-2040(ra) # 80003ab4 <iunlockput>
  return ip;
    800052b4:	b759                	j	8000523a <create+0x72>
    panic("create: ialloc");
    800052b6:	00003517          	auipc	a0,0x3
    800052ba:	50a50513          	addi	a0,a0,1290 # 800087c0 <syscalls+0x2b0>
    800052be:	ffffb097          	auipc	ra,0xffffb
    800052c2:	28a080e7          	jalr	650(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800052c6:	04a95783          	lhu	a5,74(s2)
    800052ca:	2785                	addiw	a5,a5,1
    800052cc:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052d0:	854a                	mv	a0,s2
    800052d2:	ffffe097          	auipc	ra,0xffffe
    800052d6:	4b6080e7          	jalr	1206(ra) # 80003788 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052da:	40d0                	lw	a2,4(s1)
    800052dc:	00003597          	auipc	a1,0x3
    800052e0:	4f458593          	addi	a1,a1,1268 # 800087d0 <syscalls+0x2c0>
    800052e4:	8526                	mv	a0,s1
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	c5e080e7          	jalr	-930(ra) # 80003f44 <dirlink>
    800052ee:	00054f63          	bltz	a0,8000530c <create+0x144>
    800052f2:	00492603          	lw	a2,4(s2)
    800052f6:	00003597          	auipc	a1,0x3
    800052fa:	4e258593          	addi	a1,a1,1250 # 800087d8 <syscalls+0x2c8>
    800052fe:	8526                	mv	a0,s1
    80005300:	fffff097          	auipc	ra,0xfffff
    80005304:	c44080e7          	jalr	-956(ra) # 80003f44 <dirlink>
    80005308:	f80557e3          	bgez	a0,80005296 <create+0xce>
      panic("create dots");
    8000530c:	00003517          	auipc	a0,0x3
    80005310:	4d450513          	addi	a0,a0,1236 # 800087e0 <syscalls+0x2d0>
    80005314:	ffffb097          	auipc	ra,0xffffb
    80005318:	234080e7          	jalr	564(ra) # 80000548 <panic>
    panic("create: dirlink");
    8000531c:	00003517          	auipc	a0,0x3
    80005320:	4d450513          	addi	a0,a0,1236 # 800087f0 <syscalls+0x2e0>
    80005324:	ffffb097          	auipc	ra,0xffffb
    80005328:	224080e7          	jalr	548(ra) # 80000548 <panic>
    return 0;
    8000532c:	84aa                	mv	s1,a0
    8000532e:	b731                	j	8000523a <create+0x72>

0000000080005330 <sys_dup>:
{
    80005330:	7179                	addi	sp,sp,-48
    80005332:	f406                	sd	ra,40(sp)
    80005334:	f022                	sd	s0,32(sp)
    80005336:	ec26                	sd	s1,24(sp)
    80005338:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000533a:	fd840613          	addi	a2,s0,-40
    8000533e:	4581                	li	a1,0
    80005340:	4501                	li	a0,0
    80005342:	00000097          	auipc	ra,0x0
    80005346:	ddc080e7          	jalr	-548(ra) # 8000511e <argfd>
    return -1;
    8000534a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000534c:	02054363          	bltz	a0,80005372 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005350:	fd843503          	ld	a0,-40(s0)
    80005354:	00000097          	auipc	ra,0x0
    80005358:	e32080e7          	jalr	-462(ra) # 80005186 <fdalloc>
    8000535c:	84aa                	mv	s1,a0
    return -1;
    8000535e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005360:	00054963          	bltz	a0,80005372 <sys_dup+0x42>
  filedup(f);
    80005364:	fd843503          	ld	a0,-40(s0)
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	32a080e7          	jalr	810(ra) # 80004692 <filedup>
  return fd;
    80005370:	87a6                	mv	a5,s1
}
    80005372:	853e                	mv	a0,a5
    80005374:	70a2                	ld	ra,40(sp)
    80005376:	7402                	ld	s0,32(sp)
    80005378:	64e2                	ld	s1,24(sp)
    8000537a:	6145                	addi	sp,sp,48
    8000537c:	8082                	ret

000000008000537e <sys_read>:
{
    8000537e:	7179                	addi	sp,sp,-48
    80005380:	f406                	sd	ra,40(sp)
    80005382:	f022                	sd	s0,32(sp)
    80005384:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005386:	fe840613          	addi	a2,s0,-24
    8000538a:	4581                	li	a1,0
    8000538c:	4501                	li	a0,0
    8000538e:	00000097          	auipc	ra,0x0
    80005392:	d90080e7          	jalr	-624(ra) # 8000511e <argfd>
    return -1;
    80005396:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005398:	04054163          	bltz	a0,800053da <sys_read+0x5c>
    8000539c:	fe440593          	addi	a1,s0,-28
    800053a0:	4509                	li	a0,2
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	93e080e7          	jalr	-1730(ra) # 80002ce0 <argint>
    return -1;
    800053aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ac:	02054763          	bltz	a0,800053da <sys_read+0x5c>
    800053b0:	fd840593          	addi	a1,s0,-40
    800053b4:	4505                	li	a0,1
    800053b6:	ffffe097          	auipc	ra,0xffffe
    800053ba:	94c080e7          	jalr	-1716(ra) # 80002d02 <argaddr>
    return -1;
    800053be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c0:	00054d63          	bltz	a0,800053da <sys_read+0x5c>
  return fileread(f, p, n);
    800053c4:	fe442603          	lw	a2,-28(s0)
    800053c8:	fd843583          	ld	a1,-40(s0)
    800053cc:	fe843503          	ld	a0,-24(s0)
    800053d0:	fffff097          	auipc	ra,0xfffff
    800053d4:	44e080e7          	jalr	1102(ra) # 8000481e <fileread>
    800053d8:	87aa                	mv	a5,a0
}
    800053da:	853e                	mv	a0,a5
    800053dc:	70a2                	ld	ra,40(sp)
    800053de:	7402                	ld	s0,32(sp)
    800053e0:	6145                	addi	sp,sp,48
    800053e2:	8082                	ret

00000000800053e4 <sys_write>:
{
    800053e4:	7179                	addi	sp,sp,-48
    800053e6:	f406                	sd	ra,40(sp)
    800053e8:	f022                	sd	s0,32(sp)
    800053ea:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ec:	fe840613          	addi	a2,s0,-24
    800053f0:	4581                	li	a1,0
    800053f2:	4501                	li	a0,0
    800053f4:	00000097          	auipc	ra,0x0
    800053f8:	d2a080e7          	jalr	-726(ra) # 8000511e <argfd>
    return -1;
    800053fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053fe:	04054163          	bltz	a0,80005440 <sys_write+0x5c>
    80005402:	fe440593          	addi	a1,s0,-28
    80005406:	4509                	li	a0,2
    80005408:	ffffe097          	auipc	ra,0xffffe
    8000540c:	8d8080e7          	jalr	-1832(ra) # 80002ce0 <argint>
    return -1;
    80005410:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005412:	02054763          	bltz	a0,80005440 <sys_write+0x5c>
    80005416:	fd840593          	addi	a1,s0,-40
    8000541a:	4505                	li	a0,1
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	8e6080e7          	jalr	-1818(ra) # 80002d02 <argaddr>
    return -1;
    80005424:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005426:	00054d63          	bltz	a0,80005440 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000542a:	fe442603          	lw	a2,-28(s0)
    8000542e:	fd843583          	ld	a1,-40(s0)
    80005432:	fe843503          	ld	a0,-24(s0)
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	4aa080e7          	jalr	1194(ra) # 800048e0 <filewrite>
    8000543e:	87aa                	mv	a5,a0
}
    80005440:	853e                	mv	a0,a5
    80005442:	70a2                	ld	ra,40(sp)
    80005444:	7402                	ld	s0,32(sp)
    80005446:	6145                	addi	sp,sp,48
    80005448:	8082                	ret

000000008000544a <sys_close>:
{
    8000544a:	1101                	addi	sp,sp,-32
    8000544c:	ec06                	sd	ra,24(sp)
    8000544e:	e822                	sd	s0,16(sp)
    80005450:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005452:	fe040613          	addi	a2,s0,-32
    80005456:	fec40593          	addi	a1,s0,-20
    8000545a:	4501                	li	a0,0
    8000545c:	00000097          	auipc	ra,0x0
    80005460:	cc2080e7          	jalr	-830(ra) # 8000511e <argfd>
    return -1;
    80005464:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005466:	02054463          	bltz	a0,8000548e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000546a:	ffffc097          	auipc	ra,0xffffc
    8000546e:	794080e7          	jalr	1940(ra) # 80001bfe <myproc>
    80005472:	fec42783          	lw	a5,-20(s0)
    80005476:	07e9                	addi	a5,a5,26
    80005478:	078e                	slli	a5,a5,0x3
    8000547a:	97aa                	add	a5,a5,a0
    8000547c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005480:	fe043503          	ld	a0,-32(s0)
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	260080e7          	jalr	608(ra) # 800046e4 <fileclose>
  return 0;
    8000548c:	4781                	li	a5,0
}
    8000548e:	853e                	mv	a0,a5
    80005490:	60e2                	ld	ra,24(sp)
    80005492:	6442                	ld	s0,16(sp)
    80005494:	6105                	addi	sp,sp,32
    80005496:	8082                	ret

0000000080005498 <sys_fstat>:
{
    80005498:	1101                	addi	sp,sp,-32
    8000549a:	ec06                	sd	ra,24(sp)
    8000549c:	e822                	sd	s0,16(sp)
    8000549e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054a0:	fe840613          	addi	a2,s0,-24
    800054a4:	4581                	li	a1,0
    800054a6:	4501                	li	a0,0
    800054a8:	00000097          	auipc	ra,0x0
    800054ac:	c76080e7          	jalr	-906(ra) # 8000511e <argfd>
    return -1;
    800054b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054b2:	02054563          	bltz	a0,800054dc <sys_fstat+0x44>
    800054b6:	fe040593          	addi	a1,s0,-32
    800054ba:	4505                	li	a0,1
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	846080e7          	jalr	-1978(ra) # 80002d02 <argaddr>
    return -1;
    800054c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054c6:	00054b63          	bltz	a0,800054dc <sys_fstat+0x44>
  return filestat(f, st);
    800054ca:	fe043583          	ld	a1,-32(s0)
    800054ce:	fe843503          	ld	a0,-24(s0)
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	2da080e7          	jalr	730(ra) # 800047ac <filestat>
    800054da:	87aa                	mv	a5,a0
}
    800054dc:	853e                	mv	a0,a5
    800054de:	60e2                	ld	ra,24(sp)
    800054e0:	6442                	ld	s0,16(sp)
    800054e2:	6105                	addi	sp,sp,32
    800054e4:	8082                	ret

00000000800054e6 <sys_link>:
{
    800054e6:	7169                	addi	sp,sp,-304
    800054e8:	f606                	sd	ra,296(sp)
    800054ea:	f222                	sd	s0,288(sp)
    800054ec:	ee26                	sd	s1,280(sp)
    800054ee:	ea4a                	sd	s2,272(sp)
    800054f0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054f2:	08000613          	li	a2,128
    800054f6:	ed040593          	addi	a1,s0,-304
    800054fa:	4501                	li	a0,0
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	828080e7          	jalr	-2008(ra) # 80002d24 <argstr>
    return -1;
    80005504:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005506:	10054e63          	bltz	a0,80005622 <sys_link+0x13c>
    8000550a:	08000613          	li	a2,128
    8000550e:	f5040593          	addi	a1,s0,-176
    80005512:	4505                	li	a0,1
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	810080e7          	jalr	-2032(ra) # 80002d24 <argstr>
    return -1;
    8000551c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000551e:	10054263          	bltz	a0,80005622 <sys_link+0x13c>
  begin_op();
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	cf0080e7          	jalr	-784(ra) # 80004212 <begin_op>
  if((ip = namei(old)) == 0){
    8000552a:	ed040513          	addi	a0,s0,-304
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	ad8080e7          	jalr	-1320(ra) # 80004006 <namei>
    80005536:	84aa                	mv	s1,a0
    80005538:	c551                	beqz	a0,800055c4 <sys_link+0xde>
  ilock(ip);
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	318080e7          	jalr	792(ra) # 80003852 <ilock>
  if(ip->type == T_DIR){
    80005542:	04449703          	lh	a4,68(s1)
    80005546:	4785                	li	a5,1
    80005548:	08f70463          	beq	a4,a5,800055d0 <sys_link+0xea>
  ip->nlink++;
    8000554c:	04a4d783          	lhu	a5,74(s1)
    80005550:	2785                	addiw	a5,a5,1
    80005552:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005556:	8526                	mv	a0,s1
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	230080e7          	jalr	560(ra) # 80003788 <iupdate>
  iunlock(ip);
    80005560:	8526                	mv	a0,s1
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	3b2080e7          	jalr	946(ra) # 80003914 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000556a:	fd040593          	addi	a1,s0,-48
    8000556e:	f5040513          	addi	a0,s0,-176
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	ab2080e7          	jalr	-1358(ra) # 80004024 <nameiparent>
    8000557a:	892a                	mv	s2,a0
    8000557c:	c935                	beqz	a0,800055f0 <sys_link+0x10a>
  ilock(dp);
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	2d4080e7          	jalr	724(ra) # 80003852 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005586:	00092703          	lw	a4,0(s2)
    8000558a:	409c                	lw	a5,0(s1)
    8000558c:	04f71d63          	bne	a4,a5,800055e6 <sys_link+0x100>
    80005590:	40d0                	lw	a2,4(s1)
    80005592:	fd040593          	addi	a1,s0,-48
    80005596:	854a                	mv	a0,s2
    80005598:	fffff097          	auipc	ra,0xfffff
    8000559c:	9ac080e7          	jalr	-1620(ra) # 80003f44 <dirlink>
    800055a0:	04054363          	bltz	a0,800055e6 <sys_link+0x100>
  iunlockput(dp);
    800055a4:	854a                	mv	a0,s2
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	50e080e7          	jalr	1294(ra) # 80003ab4 <iunlockput>
  iput(ip);
    800055ae:	8526                	mv	a0,s1
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	45c080e7          	jalr	1116(ra) # 80003a0c <iput>
  end_op();
    800055b8:	fffff097          	auipc	ra,0xfffff
    800055bc:	cda080e7          	jalr	-806(ra) # 80004292 <end_op>
  return 0;
    800055c0:	4781                	li	a5,0
    800055c2:	a085                	j	80005622 <sys_link+0x13c>
    end_op();
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	cce080e7          	jalr	-818(ra) # 80004292 <end_op>
    return -1;
    800055cc:	57fd                	li	a5,-1
    800055ce:	a891                	j	80005622 <sys_link+0x13c>
    iunlockput(ip);
    800055d0:	8526                	mv	a0,s1
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	4e2080e7          	jalr	1250(ra) # 80003ab4 <iunlockput>
    end_op();
    800055da:	fffff097          	auipc	ra,0xfffff
    800055de:	cb8080e7          	jalr	-840(ra) # 80004292 <end_op>
    return -1;
    800055e2:	57fd                	li	a5,-1
    800055e4:	a83d                	j	80005622 <sys_link+0x13c>
    iunlockput(dp);
    800055e6:	854a                	mv	a0,s2
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	4cc080e7          	jalr	1228(ra) # 80003ab4 <iunlockput>
  ilock(ip);
    800055f0:	8526                	mv	a0,s1
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	260080e7          	jalr	608(ra) # 80003852 <ilock>
  ip->nlink--;
    800055fa:	04a4d783          	lhu	a5,74(s1)
    800055fe:	37fd                	addiw	a5,a5,-1
    80005600:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005604:	8526                	mv	a0,s1
    80005606:	ffffe097          	auipc	ra,0xffffe
    8000560a:	182080e7          	jalr	386(ra) # 80003788 <iupdate>
  iunlockput(ip);
    8000560e:	8526                	mv	a0,s1
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	4a4080e7          	jalr	1188(ra) # 80003ab4 <iunlockput>
  end_op();
    80005618:	fffff097          	auipc	ra,0xfffff
    8000561c:	c7a080e7          	jalr	-902(ra) # 80004292 <end_op>
  return -1;
    80005620:	57fd                	li	a5,-1
}
    80005622:	853e                	mv	a0,a5
    80005624:	70b2                	ld	ra,296(sp)
    80005626:	7412                	ld	s0,288(sp)
    80005628:	64f2                	ld	s1,280(sp)
    8000562a:	6952                	ld	s2,272(sp)
    8000562c:	6155                	addi	sp,sp,304
    8000562e:	8082                	ret

0000000080005630 <sys_unlink>:
{
    80005630:	7151                	addi	sp,sp,-240
    80005632:	f586                	sd	ra,232(sp)
    80005634:	f1a2                	sd	s0,224(sp)
    80005636:	eda6                	sd	s1,216(sp)
    80005638:	e9ca                	sd	s2,208(sp)
    8000563a:	e5ce                	sd	s3,200(sp)
    8000563c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000563e:	08000613          	li	a2,128
    80005642:	f3040593          	addi	a1,s0,-208
    80005646:	4501                	li	a0,0
    80005648:	ffffd097          	auipc	ra,0xffffd
    8000564c:	6dc080e7          	jalr	1756(ra) # 80002d24 <argstr>
    80005650:	18054163          	bltz	a0,800057d2 <sys_unlink+0x1a2>
  begin_op();
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	bbe080e7          	jalr	-1090(ra) # 80004212 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000565c:	fb040593          	addi	a1,s0,-80
    80005660:	f3040513          	addi	a0,s0,-208
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	9c0080e7          	jalr	-1600(ra) # 80004024 <nameiparent>
    8000566c:	84aa                	mv	s1,a0
    8000566e:	c979                	beqz	a0,80005744 <sys_unlink+0x114>
  ilock(dp);
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	1e2080e7          	jalr	482(ra) # 80003852 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005678:	00003597          	auipc	a1,0x3
    8000567c:	15858593          	addi	a1,a1,344 # 800087d0 <syscalls+0x2c0>
    80005680:	fb040513          	addi	a0,s0,-80
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	696080e7          	jalr	1686(ra) # 80003d1a <namecmp>
    8000568c:	14050a63          	beqz	a0,800057e0 <sys_unlink+0x1b0>
    80005690:	00003597          	auipc	a1,0x3
    80005694:	14858593          	addi	a1,a1,328 # 800087d8 <syscalls+0x2c8>
    80005698:	fb040513          	addi	a0,s0,-80
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	67e080e7          	jalr	1662(ra) # 80003d1a <namecmp>
    800056a4:	12050e63          	beqz	a0,800057e0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056a8:	f2c40613          	addi	a2,s0,-212
    800056ac:	fb040593          	addi	a1,s0,-80
    800056b0:	8526                	mv	a0,s1
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	682080e7          	jalr	1666(ra) # 80003d34 <dirlookup>
    800056ba:	892a                	mv	s2,a0
    800056bc:	12050263          	beqz	a0,800057e0 <sys_unlink+0x1b0>
  ilock(ip);
    800056c0:	ffffe097          	auipc	ra,0xffffe
    800056c4:	192080e7          	jalr	402(ra) # 80003852 <ilock>
  if(ip->nlink < 1)
    800056c8:	04a91783          	lh	a5,74(s2)
    800056cc:	08f05263          	blez	a5,80005750 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056d0:	04491703          	lh	a4,68(s2)
    800056d4:	4785                	li	a5,1
    800056d6:	08f70563          	beq	a4,a5,80005760 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056da:	4641                	li	a2,16
    800056dc:	4581                	li	a1,0
    800056de:	fc040513          	addi	a0,s0,-64
    800056e2:	ffffb097          	auipc	ra,0xffffb
    800056e6:	728080e7          	jalr	1832(ra) # 80000e0a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056ea:	4741                	li	a4,16
    800056ec:	f2c42683          	lw	a3,-212(s0)
    800056f0:	fc040613          	addi	a2,s0,-64
    800056f4:	4581                	li	a1,0
    800056f6:	8526                	mv	a0,s1
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	506080e7          	jalr	1286(ra) # 80003bfe <writei>
    80005700:	47c1                	li	a5,16
    80005702:	0af51563          	bne	a0,a5,800057ac <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005706:	04491703          	lh	a4,68(s2)
    8000570a:	4785                	li	a5,1
    8000570c:	0af70863          	beq	a4,a5,800057bc <sys_unlink+0x18c>
  iunlockput(dp);
    80005710:	8526                	mv	a0,s1
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	3a2080e7          	jalr	930(ra) # 80003ab4 <iunlockput>
  ip->nlink--;
    8000571a:	04a95783          	lhu	a5,74(s2)
    8000571e:	37fd                	addiw	a5,a5,-1
    80005720:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005724:	854a                	mv	a0,s2
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	062080e7          	jalr	98(ra) # 80003788 <iupdate>
  iunlockput(ip);
    8000572e:	854a                	mv	a0,s2
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	384080e7          	jalr	900(ra) # 80003ab4 <iunlockput>
  end_op();
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	b5a080e7          	jalr	-1190(ra) # 80004292 <end_op>
  return 0;
    80005740:	4501                	li	a0,0
    80005742:	a84d                	j	800057f4 <sys_unlink+0x1c4>
    end_op();
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	b4e080e7          	jalr	-1202(ra) # 80004292 <end_op>
    return -1;
    8000574c:	557d                	li	a0,-1
    8000574e:	a05d                	j	800057f4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005750:	00003517          	auipc	a0,0x3
    80005754:	0b050513          	addi	a0,a0,176 # 80008800 <syscalls+0x2f0>
    80005758:	ffffb097          	auipc	ra,0xffffb
    8000575c:	df0080e7          	jalr	-528(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005760:	04c92703          	lw	a4,76(s2)
    80005764:	02000793          	li	a5,32
    80005768:	f6e7f9e3          	bgeu	a5,a4,800056da <sys_unlink+0xaa>
    8000576c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005770:	4741                	li	a4,16
    80005772:	86ce                	mv	a3,s3
    80005774:	f1840613          	addi	a2,s0,-232
    80005778:	4581                	li	a1,0
    8000577a:	854a                	mv	a0,s2
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	38a080e7          	jalr	906(ra) # 80003b06 <readi>
    80005784:	47c1                	li	a5,16
    80005786:	00f51b63          	bne	a0,a5,8000579c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000578a:	f1845783          	lhu	a5,-232(s0)
    8000578e:	e7a1                	bnez	a5,800057d6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005790:	29c1                	addiw	s3,s3,16
    80005792:	04c92783          	lw	a5,76(s2)
    80005796:	fcf9ede3          	bltu	s3,a5,80005770 <sys_unlink+0x140>
    8000579a:	b781                	j	800056da <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000579c:	00003517          	auipc	a0,0x3
    800057a0:	07c50513          	addi	a0,a0,124 # 80008818 <syscalls+0x308>
    800057a4:	ffffb097          	auipc	ra,0xffffb
    800057a8:	da4080e7          	jalr	-604(ra) # 80000548 <panic>
    panic("unlink: writei");
    800057ac:	00003517          	auipc	a0,0x3
    800057b0:	08450513          	addi	a0,a0,132 # 80008830 <syscalls+0x320>
    800057b4:	ffffb097          	auipc	ra,0xffffb
    800057b8:	d94080e7          	jalr	-620(ra) # 80000548 <panic>
    dp->nlink--;
    800057bc:	04a4d783          	lhu	a5,74(s1)
    800057c0:	37fd                	addiw	a5,a5,-1
    800057c2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057c6:	8526                	mv	a0,s1
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	fc0080e7          	jalr	-64(ra) # 80003788 <iupdate>
    800057d0:	b781                	j	80005710 <sys_unlink+0xe0>
    return -1;
    800057d2:	557d                	li	a0,-1
    800057d4:	a005                	j	800057f4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057d6:	854a                	mv	a0,s2
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	2dc080e7          	jalr	732(ra) # 80003ab4 <iunlockput>
  iunlockput(dp);
    800057e0:	8526                	mv	a0,s1
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	2d2080e7          	jalr	722(ra) # 80003ab4 <iunlockput>
  end_op();
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	aa8080e7          	jalr	-1368(ra) # 80004292 <end_op>
  return -1;
    800057f2:	557d                	li	a0,-1
}
    800057f4:	70ae                	ld	ra,232(sp)
    800057f6:	740e                	ld	s0,224(sp)
    800057f8:	64ee                	ld	s1,216(sp)
    800057fa:	694e                	ld	s2,208(sp)
    800057fc:	69ae                	ld	s3,200(sp)
    800057fe:	616d                	addi	sp,sp,240
    80005800:	8082                	ret

0000000080005802 <sys_open>:

uint64
sys_open(void)
{
    80005802:	7131                	addi	sp,sp,-192
    80005804:	fd06                	sd	ra,184(sp)
    80005806:	f922                	sd	s0,176(sp)
    80005808:	f526                	sd	s1,168(sp)
    8000580a:	f14a                	sd	s2,160(sp)
    8000580c:	ed4e                	sd	s3,152(sp)
    8000580e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005810:	08000613          	li	a2,128
    80005814:	f5040593          	addi	a1,s0,-176
    80005818:	4501                	li	a0,0
    8000581a:	ffffd097          	auipc	ra,0xffffd
    8000581e:	50a080e7          	jalr	1290(ra) # 80002d24 <argstr>
    return -1;
    80005822:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005824:	0c054163          	bltz	a0,800058e6 <sys_open+0xe4>
    80005828:	f4c40593          	addi	a1,s0,-180
    8000582c:	4505                	li	a0,1
    8000582e:	ffffd097          	auipc	ra,0xffffd
    80005832:	4b2080e7          	jalr	1202(ra) # 80002ce0 <argint>
    80005836:	0a054863          	bltz	a0,800058e6 <sys_open+0xe4>

  begin_op();
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	9d8080e7          	jalr	-1576(ra) # 80004212 <begin_op>

  if(omode & O_CREATE){
    80005842:	f4c42783          	lw	a5,-180(s0)
    80005846:	2007f793          	andi	a5,a5,512
    8000584a:	cbdd                	beqz	a5,80005900 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000584c:	4681                	li	a3,0
    8000584e:	4601                	li	a2,0
    80005850:	4589                	li	a1,2
    80005852:	f5040513          	addi	a0,s0,-176
    80005856:	00000097          	auipc	ra,0x0
    8000585a:	972080e7          	jalr	-1678(ra) # 800051c8 <create>
    8000585e:	892a                	mv	s2,a0
    if(ip == 0){
    80005860:	c959                	beqz	a0,800058f6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005862:	04491703          	lh	a4,68(s2)
    80005866:	478d                	li	a5,3
    80005868:	00f71763          	bne	a4,a5,80005876 <sys_open+0x74>
    8000586c:	04695703          	lhu	a4,70(s2)
    80005870:	47a5                	li	a5,9
    80005872:	0ce7ec63          	bltu	a5,a4,8000594a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	db2080e7          	jalr	-590(ra) # 80004628 <filealloc>
    8000587e:	89aa                	mv	s3,a0
    80005880:	10050263          	beqz	a0,80005984 <sys_open+0x182>
    80005884:	00000097          	auipc	ra,0x0
    80005888:	902080e7          	jalr	-1790(ra) # 80005186 <fdalloc>
    8000588c:	84aa                	mv	s1,a0
    8000588e:	0e054663          	bltz	a0,8000597a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005892:	04491703          	lh	a4,68(s2)
    80005896:	478d                	li	a5,3
    80005898:	0cf70463          	beq	a4,a5,80005960 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000589c:	4789                	li	a5,2
    8000589e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058a2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058a6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058aa:	f4c42783          	lw	a5,-180(s0)
    800058ae:	0017c713          	xori	a4,a5,1
    800058b2:	8b05                	andi	a4,a4,1
    800058b4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058b8:	0037f713          	andi	a4,a5,3
    800058bc:	00e03733          	snez	a4,a4
    800058c0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058c4:	4007f793          	andi	a5,a5,1024
    800058c8:	c791                	beqz	a5,800058d4 <sys_open+0xd2>
    800058ca:	04491703          	lh	a4,68(s2)
    800058ce:	4789                	li	a5,2
    800058d0:	08f70f63          	beq	a4,a5,8000596e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058d4:	854a                	mv	a0,s2
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	03e080e7          	jalr	62(ra) # 80003914 <iunlock>
  end_op();
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	9b4080e7          	jalr	-1612(ra) # 80004292 <end_op>

  return fd;
}
    800058e6:	8526                	mv	a0,s1
    800058e8:	70ea                	ld	ra,184(sp)
    800058ea:	744a                	ld	s0,176(sp)
    800058ec:	74aa                	ld	s1,168(sp)
    800058ee:	790a                	ld	s2,160(sp)
    800058f0:	69ea                	ld	s3,152(sp)
    800058f2:	6129                	addi	sp,sp,192
    800058f4:	8082                	ret
      end_op();
    800058f6:	fffff097          	auipc	ra,0xfffff
    800058fa:	99c080e7          	jalr	-1636(ra) # 80004292 <end_op>
      return -1;
    800058fe:	b7e5                	j	800058e6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005900:	f5040513          	addi	a0,s0,-176
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	702080e7          	jalr	1794(ra) # 80004006 <namei>
    8000590c:	892a                	mv	s2,a0
    8000590e:	c905                	beqz	a0,8000593e <sys_open+0x13c>
    ilock(ip);
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	f42080e7          	jalr	-190(ra) # 80003852 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005918:	04491703          	lh	a4,68(s2)
    8000591c:	4785                	li	a5,1
    8000591e:	f4f712e3          	bne	a4,a5,80005862 <sys_open+0x60>
    80005922:	f4c42783          	lw	a5,-180(s0)
    80005926:	dba1                	beqz	a5,80005876 <sys_open+0x74>
      iunlockput(ip);
    80005928:	854a                	mv	a0,s2
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	18a080e7          	jalr	394(ra) # 80003ab4 <iunlockput>
      end_op();
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	960080e7          	jalr	-1696(ra) # 80004292 <end_op>
      return -1;
    8000593a:	54fd                	li	s1,-1
    8000593c:	b76d                	j	800058e6 <sys_open+0xe4>
      end_op();
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	954080e7          	jalr	-1708(ra) # 80004292 <end_op>
      return -1;
    80005946:	54fd                	li	s1,-1
    80005948:	bf79                	j	800058e6 <sys_open+0xe4>
    iunlockput(ip);
    8000594a:	854a                	mv	a0,s2
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	168080e7          	jalr	360(ra) # 80003ab4 <iunlockput>
    end_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	93e080e7          	jalr	-1730(ra) # 80004292 <end_op>
    return -1;
    8000595c:	54fd                	li	s1,-1
    8000595e:	b761                	j	800058e6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005960:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005964:	04691783          	lh	a5,70(s2)
    80005968:	02f99223          	sh	a5,36(s3)
    8000596c:	bf2d                	j	800058a6 <sys_open+0xa4>
    itrunc(ip);
    8000596e:	854a                	mv	a0,s2
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	ff0080e7          	jalr	-16(ra) # 80003960 <itrunc>
    80005978:	bfb1                	j	800058d4 <sys_open+0xd2>
      fileclose(f);
    8000597a:	854e                	mv	a0,s3
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	d68080e7          	jalr	-664(ra) # 800046e4 <fileclose>
    iunlockput(ip);
    80005984:	854a                	mv	a0,s2
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	12e080e7          	jalr	302(ra) # 80003ab4 <iunlockput>
    end_op();
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	904080e7          	jalr	-1788(ra) # 80004292 <end_op>
    return -1;
    80005996:	54fd                	li	s1,-1
    80005998:	b7b9                	j	800058e6 <sys_open+0xe4>

000000008000599a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000599a:	7175                	addi	sp,sp,-144
    8000599c:	e506                	sd	ra,136(sp)
    8000599e:	e122                	sd	s0,128(sp)
    800059a0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059a2:	fffff097          	auipc	ra,0xfffff
    800059a6:	870080e7          	jalr	-1936(ra) # 80004212 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059aa:	08000613          	li	a2,128
    800059ae:	f7040593          	addi	a1,s0,-144
    800059b2:	4501                	li	a0,0
    800059b4:	ffffd097          	auipc	ra,0xffffd
    800059b8:	370080e7          	jalr	880(ra) # 80002d24 <argstr>
    800059bc:	02054963          	bltz	a0,800059ee <sys_mkdir+0x54>
    800059c0:	4681                	li	a3,0
    800059c2:	4601                	li	a2,0
    800059c4:	4585                	li	a1,1
    800059c6:	f7040513          	addi	a0,s0,-144
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	7fe080e7          	jalr	2046(ra) # 800051c8 <create>
    800059d2:	cd11                	beqz	a0,800059ee <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	0e0080e7          	jalr	224(ra) # 80003ab4 <iunlockput>
  end_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	8b6080e7          	jalr	-1866(ra) # 80004292 <end_op>
  return 0;
    800059e4:	4501                	li	a0,0
}
    800059e6:	60aa                	ld	ra,136(sp)
    800059e8:	640a                	ld	s0,128(sp)
    800059ea:	6149                	addi	sp,sp,144
    800059ec:	8082                	ret
    end_op();
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	8a4080e7          	jalr	-1884(ra) # 80004292 <end_op>
    return -1;
    800059f6:	557d                	li	a0,-1
    800059f8:	b7fd                	j	800059e6 <sys_mkdir+0x4c>

00000000800059fa <sys_mknod>:

uint64
sys_mknod(void)
{
    800059fa:	7135                	addi	sp,sp,-160
    800059fc:	ed06                	sd	ra,152(sp)
    800059fe:	e922                	sd	s0,144(sp)
    80005a00:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	810080e7          	jalr	-2032(ra) # 80004212 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a0a:	08000613          	li	a2,128
    80005a0e:	f7040593          	addi	a1,s0,-144
    80005a12:	4501                	li	a0,0
    80005a14:	ffffd097          	auipc	ra,0xffffd
    80005a18:	310080e7          	jalr	784(ra) # 80002d24 <argstr>
    80005a1c:	04054a63          	bltz	a0,80005a70 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a20:	f6c40593          	addi	a1,s0,-148
    80005a24:	4505                	li	a0,1
    80005a26:	ffffd097          	auipc	ra,0xffffd
    80005a2a:	2ba080e7          	jalr	698(ra) # 80002ce0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a2e:	04054163          	bltz	a0,80005a70 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a32:	f6840593          	addi	a1,s0,-152
    80005a36:	4509                	li	a0,2
    80005a38:	ffffd097          	auipc	ra,0xffffd
    80005a3c:	2a8080e7          	jalr	680(ra) # 80002ce0 <argint>
     argint(1, &major) < 0 ||
    80005a40:	02054863          	bltz	a0,80005a70 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a44:	f6841683          	lh	a3,-152(s0)
    80005a48:	f6c41603          	lh	a2,-148(s0)
    80005a4c:	458d                	li	a1,3
    80005a4e:	f7040513          	addi	a0,s0,-144
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	776080e7          	jalr	1910(ra) # 800051c8 <create>
     argint(2, &minor) < 0 ||
    80005a5a:	c919                	beqz	a0,80005a70 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	058080e7          	jalr	88(ra) # 80003ab4 <iunlockput>
  end_op();
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	82e080e7          	jalr	-2002(ra) # 80004292 <end_op>
  return 0;
    80005a6c:	4501                	li	a0,0
    80005a6e:	a031                	j	80005a7a <sys_mknod+0x80>
    end_op();
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	822080e7          	jalr	-2014(ra) # 80004292 <end_op>
    return -1;
    80005a78:	557d                	li	a0,-1
}
    80005a7a:	60ea                	ld	ra,152(sp)
    80005a7c:	644a                	ld	s0,144(sp)
    80005a7e:	610d                	addi	sp,sp,160
    80005a80:	8082                	ret

0000000080005a82 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a82:	7135                	addi	sp,sp,-160
    80005a84:	ed06                	sd	ra,152(sp)
    80005a86:	e922                	sd	s0,144(sp)
    80005a88:	e526                	sd	s1,136(sp)
    80005a8a:	e14a                	sd	s2,128(sp)
    80005a8c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a8e:	ffffc097          	auipc	ra,0xffffc
    80005a92:	170080e7          	jalr	368(ra) # 80001bfe <myproc>
    80005a96:	892a                	mv	s2,a0
  
  begin_op();
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	77a080e7          	jalr	1914(ra) # 80004212 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005aa0:	08000613          	li	a2,128
    80005aa4:	f6040593          	addi	a1,s0,-160
    80005aa8:	4501                	li	a0,0
    80005aaa:	ffffd097          	auipc	ra,0xffffd
    80005aae:	27a080e7          	jalr	634(ra) # 80002d24 <argstr>
    80005ab2:	04054b63          	bltz	a0,80005b08 <sys_chdir+0x86>
    80005ab6:	f6040513          	addi	a0,s0,-160
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	54c080e7          	jalr	1356(ra) # 80004006 <namei>
    80005ac2:	84aa                	mv	s1,a0
    80005ac4:	c131                	beqz	a0,80005b08 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	d8c080e7          	jalr	-628(ra) # 80003852 <ilock>
  if(ip->type != T_DIR){
    80005ace:	04449703          	lh	a4,68(s1)
    80005ad2:	4785                	li	a5,1
    80005ad4:	04f71063          	bne	a4,a5,80005b14 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ad8:	8526                	mv	a0,s1
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	e3a080e7          	jalr	-454(ra) # 80003914 <iunlock>
  iput(p->cwd);
    80005ae2:	15093503          	ld	a0,336(s2)
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	f26080e7          	jalr	-218(ra) # 80003a0c <iput>
  end_op();
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	7a4080e7          	jalr	1956(ra) # 80004292 <end_op>
  p->cwd = ip;
    80005af6:	14993823          	sd	s1,336(s2)
  return 0;
    80005afa:	4501                	li	a0,0
}
    80005afc:	60ea                	ld	ra,152(sp)
    80005afe:	644a                	ld	s0,144(sp)
    80005b00:	64aa                	ld	s1,136(sp)
    80005b02:	690a                	ld	s2,128(sp)
    80005b04:	610d                	addi	sp,sp,160
    80005b06:	8082                	ret
    end_op();
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	78a080e7          	jalr	1930(ra) # 80004292 <end_op>
    return -1;
    80005b10:	557d                	li	a0,-1
    80005b12:	b7ed                	j	80005afc <sys_chdir+0x7a>
    iunlockput(ip);
    80005b14:	8526                	mv	a0,s1
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	f9e080e7          	jalr	-98(ra) # 80003ab4 <iunlockput>
    end_op();
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	774080e7          	jalr	1908(ra) # 80004292 <end_op>
    return -1;
    80005b26:	557d                	li	a0,-1
    80005b28:	bfd1                	j	80005afc <sys_chdir+0x7a>

0000000080005b2a <sys_exec>:

uint64
sys_exec(void)
{
    80005b2a:	7145                	addi	sp,sp,-464
    80005b2c:	e786                	sd	ra,456(sp)
    80005b2e:	e3a2                	sd	s0,448(sp)
    80005b30:	ff26                	sd	s1,440(sp)
    80005b32:	fb4a                	sd	s2,432(sp)
    80005b34:	f74e                	sd	s3,424(sp)
    80005b36:	f352                	sd	s4,416(sp)
    80005b38:	ef56                	sd	s5,408(sp)
    80005b3a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b3c:	08000613          	li	a2,128
    80005b40:	f4040593          	addi	a1,s0,-192
    80005b44:	4501                	li	a0,0
    80005b46:	ffffd097          	auipc	ra,0xffffd
    80005b4a:	1de080e7          	jalr	478(ra) # 80002d24 <argstr>
    return -1;
    80005b4e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b50:	0c054a63          	bltz	a0,80005c24 <sys_exec+0xfa>
    80005b54:	e3840593          	addi	a1,s0,-456
    80005b58:	4505                	li	a0,1
    80005b5a:	ffffd097          	auipc	ra,0xffffd
    80005b5e:	1a8080e7          	jalr	424(ra) # 80002d02 <argaddr>
    80005b62:	0c054163          	bltz	a0,80005c24 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b66:	10000613          	li	a2,256
    80005b6a:	4581                	li	a1,0
    80005b6c:	e4040513          	addi	a0,s0,-448
    80005b70:	ffffb097          	auipc	ra,0xffffb
    80005b74:	29a080e7          	jalr	666(ra) # 80000e0a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b78:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b7c:	89a6                	mv	s3,s1
    80005b7e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b80:	02000a13          	li	s4,32
    80005b84:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b88:	00391513          	slli	a0,s2,0x3
    80005b8c:	e3040593          	addi	a1,s0,-464
    80005b90:	e3843783          	ld	a5,-456(s0)
    80005b94:	953e                	add	a0,a0,a5
    80005b96:	ffffd097          	auipc	ra,0xffffd
    80005b9a:	0b0080e7          	jalr	176(ra) # 80002c46 <fetchaddr>
    80005b9e:	02054a63          	bltz	a0,80005bd2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ba2:	e3043783          	ld	a5,-464(s0)
    80005ba6:	c3b9                	beqz	a5,80005bec <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ba8:	ffffb097          	auipc	ra,0xffffb
    80005bac:	fd4080e7          	jalr	-44(ra) # 80000b7c <kalloc>
    80005bb0:	85aa                	mv	a1,a0
    80005bb2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bb6:	cd11                	beqz	a0,80005bd2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bb8:	6605                	lui	a2,0x1
    80005bba:	e3043503          	ld	a0,-464(s0)
    80005bbe:	ffffd097          	auipc	ra,0xffffd
    80005bc2:	0da080e7          	jalr	218(ra) # 80002c98 <fetchstr>
    80005bc6:	00054663          	bltz	a0,80005bd2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005bca:	0905                	addi	s2,s2,1
    80005bcc:	09a1                	addi	s3,s3,8
    80005bce:	fb491be3          	bne	s2,s4,80005b84 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bd2:	10048913          	addi	s2,s1,256
    80005bd6:	6088                	ld	a0,0(s1)
    80005bd8:	c529                	beqz	a0,80005c22 <sys_exec+0xf8>
    kfree(argv[i]);
    80005bda:	ffffb097          	auipc	ra,0xffffb
    80005bde:	e4a080e7          	jalr	-438(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005be2:	04a1                	addi	s1,s1,8
    80005be4:	ff2499e3          	bne	s1,s2,80005bd6 <sys_exec+0xac>
  return -1;
    80005be8:	597d                	li	s2,-1
    80005bea:	a82d                	j	80005c24 <sys_exec+0xfa>
      argv[i] = 0;
    80005bec:	0a8e                	slli	s5,s5,0x3
    80005bee:	fc040793          	addi	a5,s0,-64
    80005bf2:	9abe                	add	s5,s5,a5
    80005bf4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bf8:	e4040593          	addi	a1,s0,-448
    80005bfc:	f4040513          	addi	a0,s0,-192
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	194080e7          	jalr	404(ra) # 80004d94 <exec>
    80005c08:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c0a:	10048993          	addi	s3,s1,256
    80005c0e:	6088                	ld	a0,0(s1)
    80005c10:	c911                	beqz	a0,80005c24 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c12:	ffffb097          	auipc	ra,0xffffb
    80005c16:	e12080e7          	jalr	-494(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1a:	04a1                	addi	s1,s1,8
    80005c1c:	ff3499e3          	bne	s1,s3,80005c0e <sys_exec+0xe4>
    80005c20:	a011                	j	80005c24 <sys_exec+0xfa>
  return -1;
    80005c22:	597d                	li	s2,-1
}
    80005c24:	854a                	mv	a0,s2
    80005c26:	60be                	ld	ra,456(sp)
    80005c28:	641e                	ld	s0,448(sp)
    80005c2a:	74fa                	ld	s1,440(sp)
    80005c2c:	795a                	ld	s2,432(sp)
    80005c2e:	79ba                	ld	s3,424(sp)
    80005c30:	7a1a                	ld	s4,416(sp)
    80005c32:	6afa                	ld	s5,408(sp)
    80005c34:	6179                	addi	sp,sp,464
    80005c36:	8082                	ret

0000000080005c38 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c38:	7139                	addi	sp,sp,-64
    80005c3a:	fc06                	sd	ra,56(sp)
    80005c3c:	f822                	sd	s0,48(sp)
    80005c3e:	f426                	sd	s1,40(sp)
    80005c40:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c42:	ffffc097          	auipc	ra,0xffffc
    80005c46:	fbc080e7          	jalr	-68(ra) # 80001bfe <myproc>
    80005c4a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c4c:	fd840593          	addi	a1,s0,-40
    80005c50:	4501                	li	a0,0
    80005c52:	ffffd097          	auipc	ra,0xffffd
    80005c56:	0b0080e7          	jalr	176(ra) # 80002d02 <argaddr>
    return -1;
    80005c5a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c5c:	0e054063          	bltz	a0,80005d3c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c60:	fc840593          	addi	a1,s0,-56
    80005c64:	fd040513          	addi	a0,s0,-48
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	dd2080e7          	jalr	-558(ra) # 80004a3a <pipealloc>
    return -1;
    80005c70:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c72:	0c054563          	bltz	a0,80005d3c <sys_pipe+0x104>
  fd0 = -1;
    80005c76:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c7a:	fd043503          	ld	a0,-48(s0)
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	508080e7          	jalr	1288(ra) # 80005186 <fdalloc>
    80005c86:	fca42223          	sw	a0,-60(s0)
    80005c8a:	08054c63          	bltz	a0,80005d22 <sys_pipe+0xea>
    80005c8e:	fc843503          	ld	a0,-56(s0)
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	4f4080e7          	jalr	1268(ra) # 80005186 <fdalloc>
    80005c9a:	fca42023          	sw	a0,-64(s0)
    80005c9e:	06054863          	bltz	a0,80005d0e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ca2:	4691                	li	a3,4
    80005ca4:	fc440613          	addi	a2,s0,-60
    80005ca8:	fd843583          	ld	a1,-40(s0)
    80005cac:	68a8                	ld	a0,80(s1)
    80005cae:	ffffc097          	auipc	ra,0xffffc
    80005cb2:	d14080e7          	jalr	-748(ra) # 800019c2 <copyout>
    80005cb6:	02054063          	bltz	a0,80005cd6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cba:	4691                	li	a3,4
    80005cbc:	fc040613          	addi	a2,s0,-64
    80005cc0:	fd843583          	ld	a1,-40(s0)
    80005cc4:	0591                	addi	a1,a1,4
    80005cc6:	68a8                	ld	a0,80(s1)
    80005cc8:	ffffc097          	auipc	ra,0xffffc
    80005ccc:	cfa080e7          	jalr	-774(ra) # 800019c2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cd0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cd2:	06055563          	bgez	a0,80005d3c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005cd6:	fc442783          	lw	a5,-60(s0)
    80005cda:	07e9                	addi	a5,a5,26
    80005cdc:	078e                	slli	a5,a5,0x3
    80005cde:	97a6                	add	a5,a5,s1
    80005ce0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ce4:	fc042503          	lw	a0,-64(s0)
    80005ce8:	0569                	addi	a0,a0,26
    80005cea:	050e                	slli	a0,a0,0x3
    80005cec:	9526                	add	a0,a0,s1
    80005cee:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cf2:	fd043503          	ld	a0,-48(s0)
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	9ee080e7          	jalr	-1554(ra) # 800046e4 <fileclose>
    fileclose(wf);
    80005cfe:	fc843503          	ld	a0,-56(s0)
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	9e2080e7          	jalr	-1566(ra) # 800046e4 <fileclose>
    return -1;
    80005d0a:	57fd                	li	a5,-1
    80005d0c:	a805                	j	80005d3c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d0e:	fc442783          	lw	a5,-60(s0)
    80005d12:	0007c863          	bltz	a5,80005d22 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d16:	01a78513          	addi	a0,a5,26
    80005d1a:	050e                	slli	a0,a0,0x3
    80005d1c:	9526                	add	a0,a0,s1
    80005d1e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d22:	fd043503          	ld	a0,-48(s0)
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	9be080e7          	jalr	-1602(ra) # 800046e4 <fileclose>
    fileclose(wf);
    80005d2e:	fc843503          	ld	a0,-56(s0)
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	9b2080e7          	jalr	-1614(ra) # 800046e4 <fileclose>
    return -1;
    80005d3a:	57fd                	li	a5,-1
}
    80005d3c:	853e                	mv	a0,a5
    80005d3e:	70e2                	ld	ra,56(sp)
    80005d40:	7442                	ld	s0,48(sp)
    80005d42:	74a2                	ld	s1,40(sp)
    80005d44:	6121                	addi	sp,sp,64
    80005d46:	8082                	ret
	...

0000000080005d50 <kernelvec>:
    80005d50:	7111                	addi	sp,sp,-256
    80005d52:	e006                	sd	ra,0(sp)
    80005d54:	e40a                	sd	sp,8(sp)
    80005d56:	e80e                	sd	gp,16(sp)
    80005d58:	ec12                	sd	tp,24(sp)
    80005d5a:	f016                	sd	t0,32(sp)
    80005d5c:	f41a                	sd	t1,40(sp)
    80005d5e:	f81e                	sd	t2,48(sp)
    80005d60:	fc22                	sd	s0,56(sp)
    80005d62:	e0a6                	sd	s1,64(sp)
    80005d64:	e4aa                	sd	a0,72(sp)
    80005d66:	e8ae                	sd	a1,80(sp)
    80005d68:	ecb2                	sd	a2,88(sp)
    80005d6a:	f0b6                	sd	a3,96(sp)
    80005d6c:	f4ba                	sd	a4,104(sp)
    80005d6e:	f8be                	sd	a5,112(sp)
    80005d70:	fcc2                	sd	a6,120(sp)
    80005d72:	e146                	sd	a7,128(sp)
    80005d74:	e54a                	sd	s2,136(sp)
    80005d76:	e94e                	sd	s3,144(sp)
    80005d78:	ed52                	sd	s4,152(sp)
    80005d7a:	f156                	sd	s5,160(sp)
    80005d7c:	f55a                	sd	s6,168(sp)
    80005d7e:	f95e                	sd	s7,176(sp)
    80005d80:	fd62                	sd	s8,184(sp)
    80005d82:	e1e6                	sd	s9,192(sp)
    80005d84:	e5ea                	sd	s10,200(sp)
    80005d86:	e9ee                	sd	s11,208(sp)
    80005d88:	edf2                	sd	t3,216(sp)
    80005d8a:	f1f6                	sd	t4,224(sp)
    80005d8c:	f5fa                	sd	t5,232(sp)
    80005d8e:	f9fe                	sd	t6,240(sp)
    80005d90:	d83fc0ef          	jal	ra,80002b12 <kerneltrap>
    80005d94:	6082                	ld	ra,0(sp)
    80005d96:	6122                	ld	sp,8(sp)
    80005d98:	61c2                	ld	gp,16(sp)
    80005d9a:	7282                	ld	t0,32(sp)
    80005d9c:	7322                	ld	t1,40(sp)
    80005d9e:	73c2                	ld	t2,48(sp)
    80005da0:	7462                	ld	s0,56(sp)
    80005da2:	6486                	ld	s1,64(sp)
    80005da4:	6526                	ld	a0,72(sp)
    80005da6:	65c6                	ld	a1,80(sp)
    80005da8:	6666                	ld	a2,88(sp)
    80005daa:	7686                	ld	a3,96(sp)
    80005dac:	7726                	ld	a4,104(sp)
    80005dae:	77c6                	ld	a5,112(sp)
    80005db0:	7866                	ld	a6,120(sp)
    80005db2:	688a                	ld	a7,128(sp)
    80005db4:	692a                	ld	s2,136(sp)
    80005db6:	69ca                	ld	s3,144(sp)
    80005db8:	6a6a                	ld	s4,152(sp)
    80005dba:	7a8a                	ld	s5,160(sp)
    80005dbc:	7b2a                	ld	s6,168(sp)
    80005dbe:	7bca                	ld	s7,176(sp)
    80005dc0:	7c6a                	ld	s8,184(sp)
    80005dc2:	6c8e                	ld	s9,192(sp)
    80005dc4:	6d2e                	ld	s10,200(sp)
    80005dc6:	6dce                	ld	s11,208(sp)
    80005dc8:	6e6e                	ld	t3,216(sp)
    80005dca:	7e8e                	ld	t4,224(sp)
    80005dcc:	7f2e                	ld	t5,232(sp)
    80005dce:	7fce                	ld	t6,240(sp)
    80005dd0:	6111                	addi	sp,sp,256
    80005dd2:	10200073          	sret
    80005dd6:	00000013          	nop
    80005dda:	00000013          	nop
    80005dde:	0001                	nop

0000000080005de0 <timervec>:
    80005de0:	34051573          	csrrw	a0,mscratch,a0
    80005de4:	e10c                	sd	a1,0(a0)
    80005de6:	e510                	sd	a2,8(a0)
    80005de8:	e914                	sd	a3,16(a0)
    80005dea:	710c                	ld	a1,32(a0)
    80005dec:	7510                	ld	a2,40(a0)
    80005dee:	6194                	ld	a3,0(a1)
    80005df0:	96b2                	add	a3,a3,a2
    80005df2:	e194                	sd	a3,0(a1)
    80005df4:	4589                	li	a1,2
    80005df6:	14459073          	csrw	sip,a1
    80005dfa:	6914                	ld	a3,16(a0)
    80005dfc:	6510                	ld	a2,8(a0)
    80005dfe:	610c                	ld	a1,0(a0)
    80005e00:	34051573          	csrrw	a0,mscratch,a0
    80005e04:	30200073          	mret
	...

0000000080005e0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e0a:	1141                	addi	sp,sp,-16
    80005e0c:	e422                	sd	s0,8(sp)
    80005e0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e10:	0c0007b7          	lui	a5,0xc000
    80005e14:	4705                	li	a4,1
    80005e16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e18:	c3d8                	sw	a4,4(a5)
}
    80005e1a:	6422                	ld	s0,8(sp)
    80005e1c:	0141                	addi	sp,sp,16
    80005e1e:	8082                	ret

0000000080005e20 <plicinithart>:

void
plicinithart(void)
{
    80005e20:	1141                	addi	sp,sp,-16
    80005e22:	e406                	sd	ra,8(sp)
    80005e24:	e022                	sd	s0,0(sp)
    80005e26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e28:	ffffc097          	auipc	ra,0xffffc
    80005e2c:	daa080e7          	jalr	-598(ra) # 80001bd2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e30:	0085171b          	slliw	a4,a0,0x8
    80005e34:	0c0027b7          	lui	a5,0xc002
    80005e38:	97ba                	add	a5,a5,a4
    80005e3a:	40200713          	li	a4,1026
    80005e3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e42:	00d5151b          	slliw	a0,a0,0xd
    80005e46:	0c2017b7          	lui	a5,0xc201
    80005e4a:	953e                	add	a0,a0,a5
    80005e4c:	00052023          	sw	zero,0(a0)
}
    80005e50:	60a2                	ld	ra,8(sp)
    80005e52:	6402                	ld	s0,0(sp)
    80005e54:	0141                	addi	sp,sp,16
    80005e56:	8082                	ret

0000000080005e58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e58:	1141                	addi	sp,sp,-16
    80005e5a:	e406                	sd	ra,8(sp)
    80005e5c:	e022                	sd	s0,0(sp)
    80005e5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e60:	ffffc097          	auipc	ra,0xffffc
    80005e64:	d72080e7          	jalr	-654(ra) # 80001bd2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e68:	00d5179b          	slliw	a5,a0,0xd
    80005e6c:	0c201537          	lui	a0,0xc201
    80005e70:	953e                	add	a0,a0,a5
  return irq;
}
    80005e72:	4148                	lw	a0,4(a0)
    80005e74:	60a2                	ld	ra,8(sp)
    80005e76:	6402                	ld	s0,0(sp)
    80005e78:	0141                	addi	sp,sp,16
    80005e7a:	8082                	ret

0000000080005e7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e7c:	1101                	addi	sp,sp,-32
    80005e7e:	ec06                	sd	ra,24(sp)
    80005e80:	e822                	sd	s0,16(sp)
    80005e82:	e426                	sd	s1,8(sp)
    80005e84:	1000                	addi	s0,sp,32
    80005e86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	d4a080e7          	jalr	-694(ra) # 80001bd2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e90:	00d5151b          	slliw	a0,a0,0xd
    80005e94:	0c2017b7          	lui	a5,0xc201
    80005e98:	97aa                	add	a5,a5,a0
    80005e9a:	c3c4                	sw	s1,4(a5)
}
    80005e9c:	60e2                	ld	ra,24(sp)
    80005e9e:	6442                	ld	s0,16(sp)
    80005ea0:	64a2                	ld	s1,8(sp)
    80005ea2:	6105                	addi	sp,sp,32
    80005ea4:	8082                	ret

0000000080005ea6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ea6:	1141                	addi	sp,sp,-16
    80005ea8:	e406                	sd	ra,8(sp)
    80005eaa:	e022                	sd	s0,0(sp)
    80005eac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eae:	479d                	li	a5,7
    80005eb0:	04a7cc63          	blt	a5,a0,80005f08 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005eb4:	0023d797          	auipc	a5,0x23d
    80005eb8:	14c78793          	addi	a5,a5,332 # 80243000 <disk>
    80005ebc:	00a78733          	add	a4,a5,a0
    80005ec0:	6789                	lui	a5,0x2
    80005ec2:	97ba                	add	a5,a5,a4
    80005ec4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ec8:	eba1                	bnez	a5,80005f18 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005eca:	00451713          	slli	a4,a0,0x4
    80005ece:	0023f797          	auipc	a5,0x23f
    80005ed2:	1327b783          	ld	a5,306(a5) # 80245000 <disk+0x2000>
    80005ed6:	97ba                	add	a5,a5,a4
    80005ed8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005edc:	0023d797          	auipc	a5,0x23d
    80005ee0:	12478793          	addi	a5,a5,292 # 80243000 <disk>
    80005ee4:	97aa                	add	a5,a5,a0
    80005ee6:	6509                	lui	a0,0x2
    80005ee8:	953e                	add	a0,a0,a5
    80005eea:	4785                	li	a5,1
    80005eec:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005ef0:	0023f517          	auipc	a0,0x23f
    80005ef4:	12850513          	addi	a0,a0,296 # 80245018 <disk+0x2018>
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	69c080e7          	jalr	1692(ra) # 80002594 <wakeup>
}
    80005f00:	60a2                	ld	ra,8(sp)
    80005f02:	6402                	ld	s0,0(sp)
    80005f04:	0141                	addi	sp,sp,16
    80005f06:	8082                	ret
    panic("virtio_disk_intr 1");
    80005f08:	00003517          	auipc	a0,0x3
    80005f0c:	93850513          	addi	a0,a0,-1736 # 80008840 <syscalls+0x330>
    80005f10:	ffffa097          	auipc	ra,0xffffa
    80005f14:	638080e7          	jalr	1592(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005f18:	00003517          	auipc	a0,0x3
    80005f1c:	94050513          	addi	a0,a0,-1728 # 80008858 <syscalls+0x348>
    80005f20:	ffffa097          	auipc	ra,0xffffa
    80005f24:	628080e7          	jalr	1576(ra) # 80000548 <panic>

0000000080005f28 <virtio_disk_init>:
{
    80005f28:	1101                	addi	sp,sp,-32
    80005f2a:	ec06                	sd	ra,24(sp)
    80005f2c:	e822                	sd	s0,16(sp)
    80005f2e:	e426                	sd	s1,8(sp)
    80005f30:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f32:	00003597          	auipc	a1,0x3
    80005f36:	93e58593          	addi	a1,a1,-1730 # 80008870 <syscalls+0x360>
    80005f3a:	0023f517          	auipc	a0,0x23f
    80005f3e:	16e50513          	addi	a0,a0,366 # 802450a8 <disk+0x20a8>
    80005f42:	ffffb097          	auipc	ra,0xffffb
    80005f46:	d3c080e7          	jalr	-708(ra) # 80000c7e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f4a:	100017b7          	lui	a5,0x10001
    80005f4e:	4398                	lw	a4,0(a5)
    80005f50:	2701                	sext.w	a4,a4
    80005f52:	747277b7          	lui	a5,0x74727
    80005f56:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f5a:	0ef71163          	bne	a4,a5,8000603c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f5e:	100017b7          	lui	a5,0x10001
    80005f62:	43dc                	lw	a5,4(a5)
    80005f64:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f66:	4705                	li	a4,1
    80005f68:	0ce79a63          	bne	a5,a4,8000603c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f6c:	100017b7          	lui	a5,0x10001
    80005f70:	479c                	lw	a5,8(a5)
    80005f72:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f74:	4709                	li	a4,2
    80005f76:	0ce79363          	bne	a5,a4,8000603c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f7a:	100017b7          	lui	a5,0x10001
    80005f7e:	47d8                	lw	a4,12(a5)
    80005f80:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f82:	554d47b7          	lui	a5,0x554d4
    80005f86:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f8a:	0af71963          	bne	a4,a5,8000603c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f8e:	100017b7          	lui	a5,0x10001
    80005f92:	4705                	li	a4,1
    80005f94:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f96:	470d                	li	a4,3
    80005f98:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f9a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f9c:	c7ffe737          	lui	a4,0xc7ffe
    80005fa0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47db875f>
    80005fa4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fa6:	2701                	sext.w	a4,a4
    80005fa8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005faa:	472d                	li	a4,11
    80005fac:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fae:	473d                	li	a4,15
    80005fb0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005fb2:	6705                	lui	a4,0x1
    80005fb4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fb6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fba:	5bdc                	lw	a5,52(a5)
    80005fbc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fbe:	c7d9                	beqz	a5,8000604c <virtio_disk_init+0x124>
  if(max < NUM)
    80005fc0:	471d                	li	a4,7
    80005fc2:	08f77d63          	bgeu	a4,a5,8000605c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fc6:	100014b7          	lui	s1,0x10001
    80005fca:	47a1                	li	a5,8
    80005fcc:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fce:	6609                	lui	a2,0x2
    80005fd0:	4581                	li	a1,0
    80005fd2:	0023d517          	auipc	a0,0x23d
    80005fd6:	02e50513          	addi	a0,a0,46 # 80243000 <disk>
    80005fda:	ffffb097          	auipc	ra,0xffffb
    80005fde:	e30080e7          	jalr	-464(ra) # 80000e0a <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fe2:	0023d717          	auipc	a4,0x23d
    80005fe6:	01e70713          	addi	a4,a4,30 # 80243000 <disk>
    80005fea:	00c75793          	srli	a5,a4,0xc
    80005fee:	2781                	sext.w	a5,a5
    80005ff0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005ff2:	0023f797          	auipc	a5,0x23f
    80005ff6:	00e78793          	addi	a5,a5,14 # 80245000 <disk+0x2000>
    80005ffa:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005ffc:	0023d717          	auipc	a4,0x23d
    80006000:	08470713          	addi	a4,a4,132 # 80243080 <disk+0x80>
    80006004:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006006:	0023e717          	auipc	a4,0x23e
    8000600a:	ffa70713          	addi	a4,a4,-6 # 80244000 <disk+0x1000>
    8000600e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006010:	4705                	li	a4,1
    80006012:	00e78c23          	sb	a4,24(a5)
    80006016:	00e78ca3          	sb	a4,25(a5)
    8000601a:	00e78d23          	sb	a4,26(a5)
    8000601e:	00e78da3          	sb	a4,27(a5)
    80006022:	00e78e23          	sb	a4,28(a5)
    80006026:	00e78ea3          	sb	a4,29(a5)
    8000602a:	00e78f23          	sb	a4,30(a5)
    8000602e:	00e78fa3          	sb	a4,31(a5)
}
    80006032:	60e2                	ld	ra,24(sp)
    80006034:	6442                	ld	s0,16(sp)
    80006036:	64a2                	ld	s1,8(sp)
    80006038:	6105                	addi	sp,sp,32
    8000603a:	8082                	ret
    panic("could not find virtio disk");
    8000603c:	00003517          	auipc	a0,0x3
    80006040:	84450513          	addi	a0,a0,-1980 # 80008880 <syscalls+0x370>
    80006044:	ffffa097          	auipc	ra,0xffffa
    80006048:	504080e7          	jalr	1284(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    8000604c:	00003517          	auipc	a0,0x3
    80006050:	85450513          	addi	a0,a0,-1964 # 800088a0 <syscalls+0x390>
    80006054:	ffffa097          	auipc	ra,0xffffa
    80006058:	4f4080e7          	jalr	1268(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000605c:	00003517          	auipc	a0,0x3
    80006060:	86450513          	addi	a0,a0,-1948 # 800088c0 <syscalls+0x3b0>
    80006064:	ffffa097          	auipc	ra,0xffffa
    80006068:	4e4080e7          	jalr	1252(ra) # 80000548 <panic>

000000008000606c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000606c:	7119                	addi	sp,sp,-128
    8000606e:	fc86                	sd	ra,120(sp)
    80006070:	f8a2                	sd	s0,112(sp)
    80006072:	f4a6                	sd	s1,104(sp)
    80006074:	f0ca                	sd	s2,96(sp)
    80006076:	ecce                	sd	s3,88(sp)
    80006078:	e8d2                	sd	s4,80(sp)
    8000607a:	e4d6                	sd	s5,72(sp)
    8000607c:	e0da                	sd	s6,64(sp)
    8000607e:	fc5e                	sd	s7,56(sp)
    80006080:	f862                	sd	s8,48(sp)
    80006082:	f466                	sd	s9,40(sp)
    80006084:	f06a                	sd	s10,32(sp)
    80006086:	0100                	addi	s0,sp,128
    80006088:	892a                	mv	s2,a0
    8000608a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000608c:	00c52c83          	lw	s9,12(a0)
    80006090:	001c9c9b          	slliw	s9,s9,0x1
    80006094:	1c82                	slli	s9,s9,0x20
    80006096:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000609a:	0023f517          	auipc	a0,0x23f
    8000609e:	00e50513          	addi	a0,a0,14 # 802450a8 <disk+0x20a8>
    800060a2:	ffffb097          	auipc	ra,0xffffb
    800060a6:	c6c080e7          	jalr	-916(ra) # 80000d0e <acquire>
  for(int i = 0; i < 3; i++){
    800060aa:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060ac:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060ae:	0023db97          	auipc	s7,0x23d
    800060b2:	f52b8b93          	addi	s7,s7,-174 # 80243000 <disk>
    800060b6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800060b8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060ba:	8a4e                	mv	s4,s3
    800060bc:	a051                	j	80006140 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800060be:	00fb86b3          	add	a3,s7,a5
    800060c2:	96da                	add	a3,a3,s6
    800060c4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060c8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060ca:	0207c563          	bltz	a5,800060f4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060ce:	2485                	addiw	s1,s1,1
    800060d0:	0711                	addi	a4,a4,4
    800060d2:	23548d63          	beq	s1,s5,8000630c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    800060d6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060d8:	0023f697          	auipc	a3,0x23f
    800060dc:	f4068693          	addi	a3,a3,-192 # 80245018 <disk+0x2018>
    800060e0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060e2:	0006c583          	lbu	a1,0(a3)
    800060e6:	fde1                	bnez	a1,800060be <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060e8:	2785                	addiw	a5,a5,1
    800060ea:	0685                	addi	a3,a3,1
    800060ec:	ff879be3          	bne	a5,s8,800060e2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060f0:	57fd                	li	a5,-1
    800060f2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060f4:	02905a63          	blez	s1,80006128 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060f8:	f9042503          	lw	a0,-112(s0)
    800060fc:	00000097          	auipc	ra,0x0
    80006100:	daa080e7          	jalr	-598(ra) # 80005ea6 <free_desc>
      for(int j = 0; j < i; j++)
    80006104:	4785                	li	a5,1
    80006106:	0297d163          	bge	a5,s1,80006128 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000610a:	f9442503          	lw	a0,-108(s0)
    8000610e:	00000097          	auipc	ra,0x0
    80006112:	d98080e7          	jalr	-616(ra) # 80005ea6 <free_desc>
      for(int j = 0; j < i; j++)
    80006116:	4789                	li	a5,2
    80006118:	0097d863          	bge	a5,s1,80006128 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000611c:	f9842503          	lw	a0,-104(s0)
    80006120:	00000097          	auipc	ra,0x0
    80006124:	d86080e7          	jalr	-634(ra) # 80005ea6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006128:	0023f597          	auipc	a1,0x23f
    8000612c:	f8058593          	addi	a1,a1,-128 # 802450a8 <disk+0x20a8>
    80006130:	0023f517          	auipc	a0,0x23f
    80006134:	ee850513          	addi	a0,a0,-280 # 80245018 <disk+0x2018>
    80006138:	ffffc097          	auipc	ra,0xffffc
    8000613c:	2d6080e7          	jalr	726(ra) # 8000240e <sleep>
  for(int i = 0; i < 3; i++){
    80006140:	f9040713          	addi	a4,s0,-112
    80006144:	84ce                	mv	s1,s3
    80006146:	bf41                	j	800060d6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006148:	4785                	li	a5,1
    8000614a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000614e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006152:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006156:	f9042983          	lw	s3,-112(s0)
    8000615a:	00499493          	slli	s1,s3,0x4
    8000615e:	0023fa17          	auipc	s4,0x23f
    80006162:	ea2a0a13          	addi	s4,s4,-350 # 80245000 <disk+0x2000>
    80006166:	000a3a83          	ld	s5,0(s4)
    8000616a:	9aa6                	add	s5,s5,s1
    8000616c:	f8040513          	addi	a0,s0,-128
    80006170:	ffffb097          	auipc	ra,0xffffb
    80006174:	06e080e7          	jalr	110(ra) # 800011de <kvmpa>
    80006178:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000617c:	000a3783          	ld	a5,0(s4)
    80006180:	97a6                	add	a5,a5,s1
    80006182:	4741                	li	a4,16
    80006184:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006186:	000a3783          	ld	a5,0(s4)
    8000618a:	97a6                	add	a5,a5,s1
    8000618c:	4705                	li	a4,1
    8000618e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006192:	f9442703          	lw	a4,-108(s0)
    80006196:	000a3783          	ld	a5,0(s4)
    8000619a:	97a6                	add	a5,a5,s1
    8000619c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061a0:	0712                	slli	a4,a4,0x4
    800061a2:	000a3783          	ld	a5,0(s4)
    800061a6:	97ba                	add	a5,a5,a4
    800061a8:	05890693          	addi	a3,s2,88
    800061ac:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800061ae:	000a3783          	ld	a5,0(s4)
    800061b2:	97ba                	add	a5,a5,a4
    800061b4:	40000693          	li	a3,1024
    800061b8:	c794                	sw	a3,8(a5)
  if(write)
    800061ba:	100d0a63          	beqz	s10,800062ce <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061be:	0023f797          	auipc	a5,0x23f
    800061c2:	e427b783          	ld	a5,-446(a5) # 80245000 <disk+0x2000>
    800061c6:	97ba                	add	a5,a5,a4
    800061c8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061cc:	0023d517          	auipc	a0,0x23d
    800061d0:	e3450513          	addi	a0,a0,-460 # 80243000 <disk>
    800061d4:	0023f797          	auipc	a5,0x23f
    800061d8:	e2c78793          	addi	a5,a5,-468 # 80245000 <disk+0x2000>
    800061dc:	6394                	ld	a3,0(a5)
    800061de:	96ba                	add	a3,a3,a4
    800061e0:	00c6d603          	lhu	a2,12(a3)
    800061e4:	00166613          	ori	a2,a2,1
    800061e8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061ec:	f9842683          	lw	a3,-104(s0)
    800061f0:	6390                	ld	a2,0(a5)
    800061f2:	9732                	add	a4,a4,a2
    800061f4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800061f8:	20098613          	addi	a2,s3,512
    800061fc:	0612                	slli	a2,a2,0x4
    800061fe:	962a                	add	a2,a2,a0
    80006200:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006204:	00469713          	slli	a4,a3,0x4
    80006208:	6394                	ld	a3,0(a5)
    8000620a:	96ba                	add	a3,a3,a4
    8000620c:	6589                	lui	a1,0x2
    8000620e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006212:	94ae                	add	s1,s1,a1
    80006214:	94aa                	add	s1,s1,a0
    80006216:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006218:	6394                	ld	a3,0(a5)
    8000621a:	96ba                	add	a3,a3,a4
    8000621c:	4585                	li	a1,1
    8000621e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006220:	6394                	ld	a3,0(a5)
    80006222:	96ba                	add	a3,a3,a4
    80006224:	4509                	li	a0,2
    80006226:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000622a:	6394                	ld	a3,0(a5)
    8000622c:	9736                	add	a4,a4,a3
    8000622e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006232:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006236:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000623a:	6794                	ld	a3,8(a5)
    8000623c:	0026d703          	lhu	a4,2(a3)
    80006240:	8b1d                	andi	a4,a4,7
    80006242:	2709                	addiw	a4,a4,2
    80006244:	0706                	slli	a4,a4,0x1
    80006246:	9736                	add	a4,a4,a3
    80006248:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000624c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006250:	6798                	ld	a4,8(a5)
    80006252:	00275783          	lhu	a5,2(a4)
    80006256:	2785                	addiw	a5,a5,1
    80006258:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000625c:	100017b7          	lui	a5,0x10001
    80006260:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006264:	00492703          	lw	a4,4(s2)
    80006268:	4785                	li	a5,1
    8000626a:	02f71163          	bne	a4,a5,8000628c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000626e:	0023f997          	auipc	s3,0x23f
    80006272:	e3a98993          	addi	s3,s3,-454 # 802450a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006276:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006278:	85ce                	mv	a1,s3
    8000627a:	854a                	mv	a0,s2
    8000627c:	ffffc097          	auipc	ra,0xffffc
    80006280:	192080e7          	jalr	402(ra) # 8000240e <sleep>
  while(b->disk == 1) {
    80006284:	00492783          	lw	a5,4(s2)
    80006288:	fe9788e3          	beq	a5,s1,80006278 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000628c:	f9042483          	lw	s1,-112(s0)
    80006290:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006294:	00479713          	slli	a4,a5,0x4
    80006298:	0023d797          	auipc	a5,0x23d
    8000629c:	d6878793          	addi	a5,a5,-664 # 80243000 <disk>
    800062a0:	97ba                	add	a5,a5,a4
    800062a2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062a6:	0023f917          	auipc	s2,0x23f
    800062aa:	d5a90913          	addi	s2,s2,-678 # 80245000 <disk+0x2000>
    free_desc(i);
    800062ae:	8526                	mv	a0,s1
    800062b0:	00000097          	auipc	ra,0x0
    800062b4:	bf6080e7          	jalr	-1034(ra) # 80005ea6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062b8:	0492                	slli	s1,s1,0x4
    800062ba:	00093783          	ld	a5,0(s2)
    800062be:	94be                	add	s1,s1,a5
    800062c0:	00c4d783          	lhu	a5,12(s1)
    800062c4:	8b85                	andi	a5,a5,1
    800062c6:	cf89                	beqz	a5,800062e0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800062c8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800062cc:	b7cd                	j	800062ae <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062ce:	0023f797          	auipc	a5,0x23f
    800062d2:	d327b783          	ld	a5,-718(a5) # 80245000 <disk+0x2000>
    800062d6:	97ba                	add	a5,a5,a4
    800062d8:	4689                	li	a3,2
    800062da:	00d79623          	sh	a3,12(a5)
    800062de:	b5fd                	j	800061cc <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062e0:	0023f517          	auipc	a0,0x23f
    800062e4:	dc850513          	addi	a0,a0,-568 # 802450a8 <disk+0x20a8>
    800062e8:	ffffb097          	auipc	ra,0xffffb
    800062ec:	ada080e7          	jalr	-1318(ra) # 80000dc2 <release>
}
    800062f0:	70e6                	ld	ra,120(sp)
    800062f2:	7446                	ld	s0,112(sp)
    800062f4:	74a6                	ld	s1,104(sp)
    800062f6:	7906                	ld	s2,96(sp)
    800062f8:	69e6                	ld	s3,88(sp)
    800062fa:	6a46                	ld	s4,80(sp)
    800062fc:	6aa6                	ld	s5,72(sp)
    800062fe:	6b06                	ld	s6,64(sp)
    80006300:	7be2                	ld	s7,56(sp)
    80006302:	7c42                	ld	s8,48(sp)
    80006304:	7ca2                	ld	s9,40(sp)
    80006306:	7d02                	ld	s10,32(sp)
    80006308:	6109                	addi	sp,sp,128
    8000630a:	8082                	ret
  if(write)
    8000630c:	e20d1ee3          	bnez	s10,80006148 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006310:	f8042023          	sw	zero,-128(s0)
    80006314:	bd2d                	j	8000614e <virtio_disk_rw+0xe2>

0000000080006316 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006316:	1101                	addi	sp,sp,-32
    80006318:	ec06                	sd	ra,24(sp)
    8000631a:	e822                	sd	s0,16(sp)
    8000631c:	e426                	sd	s1,8(sp)
    8000631e:	e04a                	sd	s2,0(sp)
    80006320:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006322:	0023f517          	auipc	a0,0x23f
    80006326:	d8650513          	addi	a0,a0,-634 # 802450a8 <disk+0x20a8>
    8000632a:	ffffb097          	auipc	ra,0xffffb
    8000632e:	9e4080e7          	jalr	-1564(ra) # 80000d0e <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006332:	0023f717          	auipc	a4,0x23f
    80006336:	cce70713          	addi	a4,a4,-818 # 80245000 <disk+0x2000>
    8000633a:	02075783          	lhu	a5,32(a4)
    8000633e:	6b18                	ld	a4,16(a4)
    80006340:	00275683          	lhu	a3,2(a4)
    80006344:	8ebd                	xor	a3,a3,a5
    80006346:	8a9d                	andi	a3,a3,7
    80006348:	cab9                	beqz	a3,8000639e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000634a:	0023d917          	auipc	s2,0x23d
    8000634e:	cb690913          	addi	s2,s2,-842 # 80243000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006352:	0023f497          	auipc	s1,0x23f
    80006356:	cae48493          	addi	s1,s1,-850 # 80245000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000635a:	078e                	slli	a5,a5,0x3
    8000635c:	97ba                	add	a5,a5,a4
    8000635e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006360:	20078713          	addi	a4,a5,512
    80006364:	0712                	slli	a4,a4,0x4
    80006366:	974a                	add	a4,a4,s2
    80006368:	03074703          	lbu	a4,48(a4)
    8000636c:	ef21                	bnez	a4,800063c4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000636e:	20078793          	addi	a5,a5,512
    80006372:	0792                	slli	a5,a5,0x4
    80006374:	97ca                	add	a5,a5,s2
    80006376:	7798                	ld	a4,40(a5)
    80006378:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000637c:	7788                	ld	a0,40(a5)
    8000637e:	ffffc097          	auipc	ra,0xffffc
    80006382:	216080e7          	jalr	534(ra) # 80002594 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006386:	0204d783          	lhu	a5,32(s1)
    8000638a:	2785                	addiw	a5,a5,1
    8000638c:	8b9d                	andi	a5,a5,7
    8000638e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006392:	6898                	ld	a4,16(s1)
    80006394:	00275683          	lhu	a3,2(a4)
    80006398:	8a9d                	andi	a3,a3,7
    8000639a:	fcf690e3          	bne	a3,a5,8000635a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000639e:	10001737          	lui	a4,0x10001
    800063a2:	533c                	lw	a5,96(a4)
    800063a4:	8b8d                	andi	a5,a5,3
    800063a6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800063a8:	0023f517          	auipc	a0,0x23f
    800063ac:	d0050513          	addi	a0,a0,-768 # 802450a8 <disk+0x20a8>
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	a12080e7          	jalr	-1518(ra) # 80000dc2 <release>
}
    800063b8:	60e2                	ld	ra,24(sp)
    800063ba:	6442                	ld	s0,16(sp)
    800063bc:	64a2                	ld	s1,8(sp)
    800063be:	6902                	ld	s2,0(sp)
    800063c0:	6105                	addi	sp,sp,32
    800063c2:	8082                	ret
      panic("virtio_disk_intr status");
    800063c4:	00002517          	auipc	a0,0x2
    800063c8:	51c50513          	addi	a0,a0,1308 # 800088e0 <syscalls+0x3d0>
    800063cc:	ffffa097          	auipc	ra,0xffffa
    800063d0:	17c080e7          	jalr	380(ra) # 80000548 <panic>
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
