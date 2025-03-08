
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9e013103          	ld	sp,-1568(sp) # 800089e0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000060:	bb478793          	addi	a5,a5,-1100 # 80005c10 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
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
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
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
    8000012a:	388080e7          	jalr	904(ra) # 800024ae <either_copyin>
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
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

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
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
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
    800001d2:	810080e7          	jalr	-2032(ra) # 800019de <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	018080e7          	jalr	24(ra) # 800021f6 <sleep>
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
    8000021e:	23e080e7          	jalr	574(ra) # 80002458 <either_copyout>
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
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
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
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

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
    80000300:	208080e7          	jalr	520(ra) # 80002504 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
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
    80000454:	f2c080e7          	jalr	-212(ra) # 8000237c <wakeup>
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
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

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
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
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
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
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
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
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
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
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
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

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
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
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
    800008ba:	ac6080e7          	jalr	-1338(ra) # 8000237c <wakeup>
    
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
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
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
    80000954:	8a6080e7          	jalr	-1882(ra) # 800021f6 <sleep>
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
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
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
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
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
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
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
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
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
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00025517          	auipc	a0,0x25
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80026000 <end>
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
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
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
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
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
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	e18080e7          	jalr	-488(ra) # 800019c2 <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	de6080e7          	jalr	-538(ra) # 800019c2 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	dda080e7          	jalr	-550(ra) # 800019c2 <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	dc2080e7          	jalr	-574(ra) # 800019c2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d82080e7          	jalr	-638(ra) # 800019c2 <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	41c50513          	addi	a0,a0,1052 # 80008070 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	d56080e7          	jalr	-682(ra) # 800019c2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3d450513          	addi	a0,a0,980 # 80008078 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3dc50513          	addi	a0,a0,988 # 80008090 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	39c50513          	addi	a0,a0,924 # 80008098 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	aec080e7          	jalr	-1300(ra) # 800019b2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	ad0080e7          	jalr	-1328(ra) # 800019b2 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0d8080e7          	jalr	216(ra) # 80000fd4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00001097          	auipc	ra,0x1
    80000f08:	740080e7          	jalr	1856(ra) # 80002644 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	d44080e7          	jalr	-700(ra) # 80005c50 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	006080e7          	jalr	6(ra) # 80001f1a <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    printfinit();
    80000f24:	00000097          	auipc	ra,0x0
    80000f28:	854080e7          	jalr	-1964(ra) # 80000778 <printfinit>
    printf("\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	19c50513          	addi	a0,a0,412 # 800080c8 <digits+0x88>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	65e080e7          	jalr	1630(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	16450513          	addi	a0,a0,356 # 800080a0 <digits+0x60>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	64e080e7          	jalr	1614(ra) # 80000592 <printf>
    printf("\n");
    80000f4c:	00007517          	auipc	a0,0x7
    80000f50:	17c50513          	addi	a0,a0,380 # 800080c8 <digits+0x88>
    80000f54:	fffff097          	auipc	ra,0xfffff
    80000f58:	63e080e7          	jalr	1598(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	b88080e7          	jalr	-1144(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	2a0080e7          	jalr	672(ra) # 80001204 <kvminit>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	068080e7          	jalr	104(ra) # 80000fd4 <kvminithart>
    procinit();      // process table
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	96e080e7          	jalr	-1682(ra) # 800018e2 <procinit>
    trapinit();      // trap vectors
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	6a0080e7          	jalr	1696(ra) # 8000261c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	6c0080e7          	jalr	1728(ra) # 80002644 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	cae080e7          	jalr	-850(ra) # 80005c3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	cbc080e7          	jalr	-836(ra) # 80005c50 <plicinithart>
    binit();         // buffer cache
    80000f9c:	00002097          	auipc	ra,0x2
    80000fa0:	e62080e7          	jalr	-414(ra) # 80002dfe <binit>
    iinit();         // inode cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	4f2080e7          	jalr	1266(ra) # 80003496 <iinit>
    fileinit();      // file table
    80000fac:	00003097          	auipc	ra,0x3
    80000fb0:	48c080e7          	jalr	1164(ra) # 80004438 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	da4080e7          	jalr	-604(ra) # 80005d58 <virtio_disk_init>
    userinit();      // first user process
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	cf0080e7          	jalr	-784(ra) # 80001cac <userinit>
    __sync_synchronize();
    80000fc4:	0ff0000f          	fence
    started = 1;
    80000fc8:	4785                	li	a5,1
    80000fca:	00008717          	auipc	a4,0x8
    80000fce:	04f72123          	sw	a5,66(a4) # 8000900c <started>
    80000fd2:	b789                	j	80000f14 <main+0x56>

0000000080000fd4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fd4:	1141                	addi	sp,sp,-16
    80000fd6:	e422                	sd	s0,8(sp)
    80000fd8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fda:	00008797          	auipc	a5,0x8
    80000fde:	0367b783          	ld	a5,54(a5) # 80009010 <kernel_pagetable>
    80000fe2:	83b1                	srli	a5,a5,0xc
    80000fe4:	577d                	li	a4,-1
    80000fe6:	177e                	slli	a4,a4,0x3f
    80000fe8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fea:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fee:	12000073          	sfence.vma
  sfence_vma();
}
    80000ff2:	6422                	ld	s0,8(sp)
    80000ff4:	0141                	addi	sp,sp,16
    80000ff6:	8082                	ret

0000000080000ff8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000ff8:	7139                	addi	sp,sp,-64
    80000ffa:	fc06                	sd	ra,56(sp)
    80000ffc:	f822                	sd	s0,48(sp)
    80000ffe:	f426                	sd	s1,40(sp)
    80001000:	f04a                	sd	s2,32(sp)
    80001002:	ec4e                	sd	s3,24(sp)
    80001004:	e852                	sd	s4,16(sp)
    80001006:	e456                	sd	s5,8(sp)
    80001008:	e05a                	sd	s6,0(sp)
    8000100a:	0080                	addi	s0,sp,64
    8000100c:	84aa                	mv	s1,a0
    8000100e:	89ae                	mv	s3,a1
    80001010:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001012:	57fd                	li	a5,-1
    80001014:	83e9                	srli	a5,a5,0x1a
    80001016:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001018:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000101a:	04b7f263          	bgeu	a5,a1,8000105e <walk+0x66>
    panic("walk");
    8000101e:	00007517          	auipc	a0,0x7
    80001022:	0b250513          	addi	a0,a0,178 # 800080d0 <digits+0x90>
    80001026:	fffff097          	auipc	ra,0xfffff
    8000102a:	522080e7          	jalr	1314(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000102e:	060a8663          	beqz	s5,8000109a <walk+0xa2>
    80001032:	00000097          	auipc	ra,0x0
    80001036:	aee080e7          	jalr	-1298(ra) # 80000b20 <kalloc>
    8000103a:	84aa                	mv	s1,a0
    8000103c:	c529                	beqz	a0,80001086 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000103e:	6605                	lui	a2,0x1
    80001040:	4581                	li	a1,0
    80001042:	00000097          	auipc	ra,0x0
    80001046:	cca080e7          	jalr	-822(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000104a:	00c4d793          	srli	a5,s1,0xc
    8000104e:	07aa                	slli	a5,a5,0xa
    80001050:	0017e793          	ori	a5,a5,1
    80001054:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001058:	3a5d                	addiw	s4,s4,-9
    8000105a:	036a0063          	beq	s4,s6,8000107a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000105e:	0149d933          	srl	s2,s3,s4
    80001062:	1ff97913          	andi	s2,s2,511
    80001066:	090e                	slli	s2,s2,0x3
    80001068:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000106a:	00093483          	ld	s1,0(s2)
    8000106e:	0014f793          	andi	a5,s1,1
    80001072:	dfd5                	beqz	a5,8000102e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001074:	80a9                	srli	s1,s1,0xa
    80001076:	04b2                	slli	s1,s1,0xc
    80001078:	b7c5                	j	80001058 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000107a:	00c9d513          	srli	a0,s3,0xc
    8000107e:	1ff57513          	andi	a0,a0,511
    80001082:	050e                	slli	a0,a0,0x3
    80001084:	9526                	add	a0,a0,s1
}
    80001086:	70e2                	ld	ra,56(sp)
    80001088:	7442                	ld	s0,48(sp)
    8000108a:	74a2                	ld	s1,40(sp)
    8000108c:	7902                	ld	s2,32(sp)
    8000108e:	69e2                	ld	s3,24(sp)
    80001090:	6a42                	ld	s4,16(sp)
    80001092:	6aa2                	ld	s5,8(sp)
    80001094:	6b02                	ld	s6,0(sp)
    80001096:	6121                	addi	sp,sp,64
    80001098:	8082                	ret
        return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7ed                	j	80001086 <walk+0x8e>

000000008000109e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000109e:	57fd                	li	a5,-1
    800010a0:	83e9                	srli	a5,a5,0x1a
    800010a2:	00b7f463          	bgeu	a5,a1,800010aa <walkaddr+0xc>
    return 0;
    800010a6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010a8:	8082                	ret
{
    800010aa:	1141                	addi	sp,sp,-16
    800010ac:	e406                	sd	ra,8(sp)
    800010ae:	e022                	sd	s0,0(sp)
    800010b0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010b2:	4601                	li	a2,0
    800010b4:	00000097          	auipc	ra,0x0
    800010b8:	f44080e7          	jalr	-188(ra) # 80000ff8 <walk>
  if(pte == 0)
    800010bc:	c105                	beqz	a0,800010dc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010be:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c0:	0117f693          	andi	a3,a5,17
    800010c4:	4745                	li	a4,17
    return 0;
    800010c6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010c8:	00e68663          	beq	a3,a4,800010d4 <walkaddr+0x36>
}
    800010cc:	60a2                	ld	ra,8(sp)
    800010ce:	6402                	ld	s0,0(sp)
    800010d0:	0141                	addi	sp,sp,16
    800010d2:	8082                	ret
  pa = PTE2PA(*pte);
    800010d4:	00a7d513          	srli	a0,a5,0xa
    800010d8:	0532                	slli	a0,a0,0xc
  return pa;
    800010da:	bfcd                	j	800010cc <walkaddr+0x2e>
    return 0;
    800010dc:	4501                	li	a0,0
    800010de:	b7fd                	j	800010cc <walkaddr+0x2e>

00000000800010e0 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010e0:	1101                	addi	sp,sp,-32
    800010e2:	ec06                	sd	ra,24(sp)
    800010e4:	e822                	sd	s0,16(sp)
    800010e6:	e426                	sd	s1,8(sp)
    800010e8:	1000                	addi	s0,sp,32
    800010ea:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010ec:	1552                	slli	a0,a0,0x34
    800010ee:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010f2:	4601                	li	a2,0
    800010f4:	00008517          	auipc	a0,0x8
    800010f8:	f1c53503          	ld	a0,-228(a0) # 80009010 <kernel_pagetable>
    800010fc:	00000097          	auipc	ra,0x0
    80001100:	efc080e7          	jalr	-260(ra) # 80000ff8 <walk>
  if(pte == 0)
    80001104:	cd09                	beqz	a0,8000111e <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001106:	6108                	ld	a0,0(a0)
    80001108:	00157793          	andi	a5,a0,1
    8000110c:	c38d                	beqz	a5,8000112e <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000110e:	8129                	srli	a0,a0,0xa
    80001110:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001112:	9526                	add	a0,a0,s1
    80001114:	60e2                	ld	ra,24(sp)
    80001116:	6442                	ld	s0,16(sp)
    80001118:	64a2                	ld	s1,8(sp)
    8000111a:	6105                	addi	sp,sp,32
    8000111c:	8082                	ret
    panic("kvmpa");
    8000111e:	00007517          	auipc	a0,0x7
    80001122:	fba50513          	addi	a0,a0,-70 # 800080d8 <digits+0x98>
    80001126:	fffff097          	auipc	ra,0xfffff
    8000112a:	422080e7          	jalr	1058(ra) # 80000548 <panic>
    panic("kvmpa");
    8000112e:	00007517          	auipc	a0,0x7
    80001132:	faa50513          	addi	a0,a0,-86 # 800080d8 <digits+0x98>
    80001136:	fffff097          	auipc	ra,0xfffff
    8000113a:	412080e7          	jalr	1042(ra) # 80000548 <panic>

000000008000113e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000113e:	715d                	addi	sp,sp,-80
    80001140:	e486                	sd	ra,72(sp)
    80001142:	e0a2                	sd	s0,64(sp)
    80001144:	fc26                	sd	s1,56(sp)
    80001146:	f84a                	sd	s2,48(sp)
    80001148:	f44e                	sd	s3,40(sp)
    8000114a:	f052                	sd	s4,32(sp)
    8000114c:	ec56                	sd	s5,24(sp)
    8000114e:	e85a                	sd	s6,16(sp)
    80001150:	e45e                	sd	s7,8(sp)
    80001152:	0880                	addi	s0,sp,80
    80001154:	8aaa                	mv	s5,a0
    80001156:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001158:	777d                	lui	a4,0xfffff
    8000115a:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000115e:	167d                	addi	a2,a2,-1
    80001160:	00b609b3          	add	s3,a2,a1
    80001164:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001168:	893e                	mv	s2,a5
    8000116a:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000116e:	6b85                	lui	s7,0x1
    80001170:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001174:	4605                	li	a2,1
    80001176:	85ca                	mv	a1,s2
    80001178:	8556                	mv	a0,s5
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	e7e080e7          	jalr	-386(ra) # 80000ff8 <walk>
    80001182:	c51d                	beqz	a0,800011b0 <mappages+0x72>
    if(*pte & PTE_V)
    80001184:	611c                	ld	a5,0(a0)
    80001186:	8b85                	andi	a5,a5,1
    80001188:	ef81                	bnez	a5,800011a0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000118a:	80b1                	srli	s1,s1,0xc
    8000118c:	04aa                	slli	s1,s1,0xa
    8000118e:	0164e4b3          	or	s1,s1,s6
    80001192:	0014e493          	ori	s1,s1,1
    80001196:	e104                	sd	s1,0(a0)
    if(a == last)
    80001198:	03390863          	beq	s2,s3,800011c8 <mappages+0x8a>
    a += PGSIZE;
    8000119c:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000119e:	bfc9                	j	80001170 <mappages+0x32>
      panic("remap");
    800011a0:	00007517          	auipc	a0,0x7
    800011a4:	f4050513          	addi	a0,a0,-192 # 800080e0 <digits+0xa0>
    800011a8:	fffff097          	auipc	ra,0xfffff
    800011ac:	3a0080e7          	jalr	928(ra) # 80000548 <panic>
      return -1;
    800011b0:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011b2:	60a6                	ld	ra,72(sp)
    800011b4:	6406                	ld	s0,64(sp)
    800011b6:	74e2                	ld	s1,56(sp)
    800011b8:	7942                	ld	s2,48(sp)
    800011ba:	79a2                	ld	s3,40(sp)
    800011bc:	7a02                	ld	s4,32(sp)
    800011be:	6ae2                	ld	s5,24(sp)
    800011c0:	6b42                	ld	s6,16(sp)
    800011c2:	6ba2                	ld	s7,8(sp)
    800011c4:	6161                	addi	sp,sp,80
    800011c6:	8082                	ret
  return 0;
    800011c8:	4501                	li	a0,0
    800011ca:	b7e5                	j	800011b2 <mappages+0x74>

00000000800011cc <kvmmap>:
{
    800011cc:	1141                	addi	sp,sp,-16
    800011ce:	e406                	sd	ra,8(sp)
    800011d0:	e022                	sd	s0,0(sp)
    800011d2:	0800                	addi	s0,sp,16
    800011d4:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011d6:	86ae                	mv	a3,a1
    800011d8:	85aa                	mv	a1,a0
    800011da:	00008517          	auipc	a0,0x8
    800011de:	e3653503          	ld	a0,-458(a0) # 80009010 <kernel_pagetable>
    800011e2:	00000097          	auipc	ra,0x0
    800011e6:	f5c080e7          	jalr	-164(ra) # 8000113e <mappages>
    800011ea:	e509                	bnez	a0,800011f4 <kvmmap+0x28>
}
    800011ec:	60a2                	ld	ra,8(sp)
    800011ee:	6402                	ld	s0,0(sp)
    800011f0:	0141                	addi	sp,sp,16
    800011f2:	8082                	ret
    panic("kvmmap");
    800011f4:	00007517          	auipc	a0,0x7
    800011f8:	ef450513          	addi	a0,a0,-268 # 800080e8 <digits+0xa8>
    800011fc:	fffff097          	auipc	ra,0xfffff
    80001200:	34c080e7          	jalr	844(ra) # 80000548 <panic>

0000000080001204 <kvminit>:
{
    80001204:	1101                	addi	sp,sp,-32
    80001206:	ec06                	sd	ra,24(sp)
    80001208:	e822                	sd	s0,16(sp)
    8000120a:	e426                	sd	s1,8(sp)
    8000120c:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	912080e7          	jalr	-1774(ra) # 80000b20 <kalloc>
    80001216:	00008797          	auipc	a5,0x8
    8000121a:	dea7bd23          	sd	a0,-518(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000121e:	6605                	lui	a2,0x1
    80001220:	4581                	li	a1,0
    80001222:	00000097          	auipc	ra,0x0
    80001226:	aea080e7          	jalr	-1302(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000122a:	4699                	li	a3,6
    8000122c:	6605                	lui	a2,0x1
    8000122e:	100005b7          	lui	a1,0x10000
    80001232:	10000537          	lui	a0,0x10000
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f96080e7          	jalr	-106(ra) # 800011cc <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000123e:	4699                	li	a3,6
    80001240:	6605                	lui	a2,0x1
    80001242:	100015b7          	lui	a1,0x10001
    80001246:	10001537          	lui	a0,0x10001
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	f82080e7          	jalr	-126(ra) # 800011cc <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001252:	4699                	li	a3,6
    80001254:	6641                	lui	a2,0x10
    80001256:	020005b7          	lui	a1,0x2000
    8000125a:	02000537          	lui	a0,0x2000
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f6e080e7          	jalr	-146(ra) # 800011cc <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001266:	4699                	li	a3,6
    80001268:	00400637          	lui	a2,0x400
    8000126c:	0c0005b7          	lui	a1,0xc000
    80001270:	0c000537          	lui	a0,0xc000
    80001274:	00000097          	auipc	ra,0x0
    80001278:	f58080e7          	jalr	-168(ra) # 800011cc <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000127c:	00007497          	auipc	s1,0x7
    80001280:	d8448493          	addi	s1,s1,-636 # 80008000 <etext>
    80001284:	46a9                	li	a3,10
    80001286:	80007617          	auipc	a2,0x80007
    8000128a:	d7a60613          	addi	a2,a2,-646 # 8000 <_entry-0x7fff8000>
    8000128e:	4585                	li	a1,1
    80001290:	05fe                	slli	a1,a1,0x1f
    80001292:	852e                	mv	a0,a1
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f38080e7          	jalr	-200(ra) # 800011cc <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000129c:	4699                	li	a3,6
    8000129e:	4645                	li	a2,17
    800012a0:	066e                	slli	a2,a2,0x1b
    800012a2:	8e05                	sub	a2,a2,s1
    800012a4:	85a6                	mv	a1,s1
    800012a6:	8526                	mv	a0,s1
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f24080e7          	jalr	-220(ra) # 800011cc <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012b0:	46a9                	li	a3,10
    800012b2:	6605                	lui	a2,0x1
    800012b4:	00006597          	auipc	a1,0x6
    800012b8:	d4c58593          	addi	a1,a1,-692 # 80007000 <_trampoline>
    800012bc:	04000537          	lui	a0,0x4000
    800012c0:	157d                	addi	a0,a0,-1
    800012c2:	0532                	slli	a0,a0,0xc
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f08080e7          	jalr	-248(ra) # 800011cc <kvmmap>
}
    800012cc:	60e2                	ld	ra,24(sp)
    800012ce:	6442                	ld	s0,16(sp)
    800012d0:	64a2                	ld	s1,8(sp)
    800012d2:	6105                	addi	sp,sp,32
    800012d4:	8082                	ret

00000000800012d6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012d6:	715d                	addi	sp,sp,-80
    800012d8:	e486                	sd	ra,72(sp)
    800012da:	e0a2                	sd	s0,64(sp)
    800012dc:	fc26                	sd	s1,56(sp)
    800012de:	f84a                	sd	s2,48(sp)
    800012e0:	f44e                	sd	s3,40(sp)
    800012e2:	f052                	sd	s4,32(sp)
    800012e4:	ec56                	sd	s5,24(sp)
    800012e6:	e85a                	sd	s6,16(sp)
    800012e8:	e45e                	sd	s7,8(sp)
    800012ea:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012ec:	03459793          	slli	a5,a1,0x34
    800012f0:	e795                	bnez	a5,8000131c <uvmunmap+0x46>
    800012f2:	8a2a                	mv	s4,a0
    800012f4:	892e                	mv	s2,a1
    800012f6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f8:	0632                	slli	a2,a2,0xc
    800012fa:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012fe:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001300:	6b05                	lui	s6,0x1
    80001302:	0735e863          	bltu	a1,s3,80001372 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001306:	60a6                	ld	ra,72(sp)
    80001308:	6406                	ld	s0,64(sp)
    8000130a:	74e2                	ld	s1,56(sp)
    8000130c:	7942                	ld	s2,48(sp)
    8000130e:	79a2                	ld	s3,40(sp)
    80001310:	7a02                	ld	s4,32(sp)
    80001312:	6ae2                	ld	s5,24(sp)
    80001314:	6b42                	ld	s6,16(sp)
    80001316:	6ba2                	ld	s7,8(sp)
    80001318:	6161                	addi	sp,sp,80
    8000131a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000131c:	00007517          	auipc	a0,0x7
    80001320:	dd450513          	addi	a0,a0,-556 # 800080f0 <digits+0xb0>
    80001324:	fffff097          	auipc	ra,0xfffff
    80001328:	224080e7          	jalr	548(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    8000132c:	00007517          	auipc	a0,0x7
    80001330:	ddc50513          	addi	a0,a0,-548 # 80008108 <digits+0xc8>
    80001334:	fffff097          	auipc	ra,0xfffff
    80001338:	214080e7          	jalr	532(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    8000133c:	00007517          	auipc	a0,0x7
    80001340:	ddc50513          	addi	a0,a0,-548 # 80008118 <digits+0xd8>
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	204080e7          	jalr	516(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    8000134c:	00007517          	auipc	a0,0x7
    80001350:	de450513          	addi	a0,a0,-540 # 80008130 <digits+0xf0>
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	1f4080e7          	jalr	500(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    8000135c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000135e:	0532                	slli	a0,a0,0xc
    80001360:	fffff097          	auipc	ra,0xfffff
    80001364:	6c4080e7          	jalr	1732(ra) # 80000a24 <kfree>
    *pte = 0;
    80001368:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000136c:	995a                	add	s2,s2,s6
    8000136e:	f9397ce3          	bgeu	s2,s3,80001306 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001372:	4601                	li	a2,0
    80001374:	85ca                	mv	a1,s2
    80001376:	8552                	mv	a0,s4
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	c80080e7          	jalr	-896(ra) # 80000ff8 <walk>
    80001380:	84aa                	mv	s1,a0
    80001382:	d54d                	beqz	a0,8000132c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001384:	6108                	ld	a0,0(a0)
    80001386:	00157793          	andi	a5,a0,1
    8000138a:	dbcd                	beqz	a5,8000133c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000138c:	3ff57793          	andi	a5,a0,1023
    80001390:	fb778ee3          	beq	a5,s7,8000134c <uvmunmap+0x76>
    if(do_free){
    80001394:	fc0a8ae3          	beqz	s5,80001368 <uvmunmap+0x92>
    80001398:	b7d1                	j	8000135c <uvmunmap+0x86>

000000008000139a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000139a:	1101                	addi	sp,sp,-32
    8000139c:	ec06                	sd	ra,24(sp)
    8000139e:	e822                	sd	s0,16(sp)
    800013a0:	e426                	sd	s1,8(sp)
    800013a2:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013a4:	fffff097          	auipc	ra,0xfffff
    800013a8:	77c080e7          	jalr	1916(ra) # 80000b20 <kalloc>
    800013ac:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013ae:	c519                	beqz	a0,800013bc <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b0:	6605                	lui	a2,0x1
    800013b2:	4581                	li	a1,0
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	958080e7          	jalr	-1704(ra) # 80000d0c <memset>
  return pagetable;
}
    800013bc:	8526                	mv	a0,s1
    800013be:	60e2                	ld	ra,24(sp)
    800013c0:	6442                	ld	s0,16(sp)
    800013c2:	64a2                	ld	s1,8(sp)
    800013c4:	6105                	addi	sp,sp,32
    800013c6:	8082                	ret

00000000800013c8 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013c8:	7179                	addi	sp,sp,-48
    800013ca:	f406                	sd	ra,40(sp)
    800013cc:	f022                	sd	s0,32(sp)
    800013ce:	ec26                	sd	s1,24(sp)
    800013d0:	e84a                	sd	s2,16(sp)
    800013d2:	e44e                	sd	s3,8(sp)
    800013d4:	e052                	sd	s4,0(sp)
    800013d6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013d8:	6785                	lui	a5,0x1
    800013da:	04f67863          	bgeu	a2,a5,8000142a <uvminit+0x62>
    800013de:	8a2a                	mv	s4,a0
    800013e0:	89ae                	mv	s3,a1
    800013e2:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013e4:	fffff097          	auipc	ra,0xfffff
    800013e8:	73c080e7          	jalr	1852(ra) # 80000b20 <kalloc>
    800013ec:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013ee:	6605                	lui	a2,0x1
    800013f0:	4581                	li	a1,0
    800013f2:	00000097          	auipc	ra,0x0
    800013f6:	91a080e7          	jalr	-1766(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013fa:	4779                	li	a4,30
    800013fc:	86ca                	mv	a3,s2
    800013fe:	6605                	lui	a2,0x1
    80001400:	4581                	li	a1,0
    80001402:	8552                	mv	a0,s4
    80001404:	00000097          	auipc	ra,0x0
    80001408:	d3a080e7          	jalr	-710(ra) # 8000113e <mappages>
  memmove(mem, src, sz);
    8000140c:	8626                	mv	a2,s1
    8000140e:	85ce                	mv	a1,s3
    80001410:	854a                	mv	a0,s2
    80001412:	00000097          	auipc	ra,0x0
    80001416:	95a080e7          	jalr	-1702(ra) # 80000d6c <memmove>
}
    8000141a:	70a2                	ld	ra,40(sp)
    8000141c:	7402                	ld	s0,32(sp)
    8000141e:	64e2                	ld	s1,24(sp)
    80001420:	6942                	ld	s2,16(sp)
    80001422:	69a2                	ld	s3,8(sp)
    80001424:	6a02                	ld	s4,0(sp)
    80001426:	6145                	addi	sp,sp,48
    80001428:	8082                	ret
    panic("inituvm: more than a page");
    8000142a:	00007517          	auipc	a0,0x7
    8000142e:	d1e50513          	addi	a0,a0,-738 # 80008148 <digits+0x108>
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	116080e7          	jalr	278(ra) # 80000548 <panic>

000000008000143a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000143a:	1101                	addi	sp,sp,-32
    8000143c:	ec06                	sd	ra,24(sp)
    8000143e:	e822                	sd	s0,16(sp)
    80001440:	e426                	sd	s1,8(sp)
    80001442:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001444:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001446:	00b67d63          	bgeu	a2,a1,80001460 <uvmdealloc+0x26>
    8000144a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000144c:	6785                	lui	a5,0x1
    8000144e:	17fd                	addi	a5,a5,-1
    80001450:	00f60733          	add	a4,a2,a5
    80001454:	767d                	lui	a2,0xfffff
    80001456:	8f71                	and	a4,a4,a2
    80001458:	97ae                	add	a5,a5,a1
    8000145a:	8ff1                	and	a5,a5,a2
    8000145c:	00f76863          	bltu	a4,a5,8000146c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001460:	8526                	mv	a0,s1
    80001462:	60e2                	ld	ra,24(sp)
    80001464:	6442                	ld	s0,16(sp)
    80001466:	64a2                	ld	s1,8(sp)
    80001468:	6105                	addi	sp,sp,32
    8000146a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000146c:	8f99                	sub	a5,a5,a4
    8000146e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001470:	4685                	li	a3,1
    80001472:	0007861b          	sext.w	a2,a5
    80001476:	85ba                	mv	a1,a4
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	e5e080e7          	jalr	-418(ra) # 800012d6 <uvmunmap>
    80001480:	b7c5                	j	80001460 <uvmdealloc+0x26>

0000000080001482 <uvmalloc>:
  if(newsz < oldsz)
    80001482:	0ab66163          	bltu	a2,a1,80001524 <uvmalloc+0xa2>
{
    80001486:	7139                	addi	sp,sp,-64
    80001488:	fc06                	sd	ra,56(sp)
    8000148a:	f822                	sd	s0,48(sp)
    8000148c:	f426                	sd	s1,40(sp)
    8000148e:	f04a                	sd	s2,32(sp)
    80001490:	ec4e                	sd	s3,24(sp)
    80001492:	e852                	sd	s4,16(sp)
    80001494:	e456                	sd	s5,8(sp)
    80001496:	0080                	addi	s0,sp,64
    80001498:	8aaa                	mv	s5,a0
    8000149a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000149c:	6985                	lui	s3,0x1
    8000149e:	19fd                	addi	s3,s3,-1
    800014a0:	95ce                	add	a1,a1,s3
    800014a2:	79fd                	lui	s3,0xfffff
    800014a4:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014a8:	08c9f063          	bgeu	s3,a2,80001528 <uvmalloc+0xa6>
    800014ac:	894e                	mv	s2,s3
    mem = kalloc();
    800014ae:	fffff097          	auipc	ra,0xfffff
    800014b2:	672080e7          	jalr	1650(ra) # 80000b20 <kalloc>
    800014b6:	84aa                	mv	s1,a0
    if(mem == 0){
    800014b8:	c51d                	beqz	a0,800014e6 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014ba:	6605                	lui	a2,0x1
    800014bc:	4581                	li	a1,0
    800014be:	00000097          	auipc	ra,0x0
    800014c2:	84e080e7          	jalr	-1970(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014c6:	4779                	li	a4,30
    800014c8:	86a6                	mv	a3,s1
    800014ca:	6605                	lui	a2,0x1
    800014cc:	85ca                	mv	a1,s2
    800014ce:	8556                	mv	a0,s5
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	c6e080e7          	jalr	-914(ra) # 8000113e <mappages>
    800014d8:	e905                	bnez	a0,80001508 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014da:	6785                	lui	a5,0x1
    800014dc:	993e                	add	s2,s2,a5
    800014de:	fd4968e3          	bltu	s2,s4,800014ae <uvmalloc+0x2c>
  return newsz;
    800014e2:	8552                	mv	a0,s4
    800014e4:	a809                	j	800014f6 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014e6:	864e                	mv	a2,s3
    800014e8:	85ca                	mv	a1,s2
    800014ea:	8556                	mv	a0,s5
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	f4e080e7          	jalr	-178(ra) # 8000143a <uvmdealloc>
      return 0;
    800014f4:	4501                	li	a0,0
}
    800014f6:	70e2                	ld	ra,56(sp)
    800014f8:	7442                	ld	s0,48(sp)
    800014fa:	74a2                	ld	s1,40(sp)
    800014fc:	7902                	ld	s2,32(sp)
    800014fe:	69e2                	ld	s3,24(sp)
    80001500:	6a42                	ld	s4,16(sp)
    80001502:	6aa2                	ld	s5,8(sp)
    80001504:	6121                	addi	sp,sp,64
    80001506:	8082                	ret
      kfree(mem);
    80001508:	8526                	mv	a0,s1
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	51a080e7          	jalr	1306(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001512:	864e                	mv	a2,s3
    80001514:	85ca                	mv	a1,s2
    80001516:	8556                	mv	a0,s5
    80001518:	00000097          	auipc	ra,0x0
    8000151c:	f22080e7          	jalr	-222(ra) # 8000143a <uvmdealloc>
      return 0;
    80001520:	4501                	li	a0,0
    80001522:	bfd1                	j	800014f6 <uvmalloc+0x74>
    return oldsz;
    80001524:	852e                	mv	a0,a1
}
    80001526:	8082                	ret
  return newsz;
    80001528:	8532                	mv	a0,a2
    8000152a:	b7f1                	j	800014f6 <uvmalloc+0x74>

000000008000152c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000152c:	7179                	addi	sp,sp,-48
    8000152e:	f406                	sd	ra,40(sp)
    80001530:	f022                	sd	s0,32(sp)
    80001532:	ec26                	sd	s1,24(sp)
    80001534:	e84a                	sd	s2,16(sp)
    80001536:	e44e                	sd	s3,8(sp)
    80001538:	e052                	sd	s4,0(sp)
    8000153a:	1800                	addi	s0,sp,48
    8000153c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000153e:	84aa                	mv	s1,a0
    80001540:	6905                	lui	s2,0x1
    80001542:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001544:	4985                	li	s3,1
    80001546:	a821                	j	8000155e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001548:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000154a:	0532                	slli	a0,a0,0xc
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	fe0080e7          	jalr	-32(ra) # 8000152c <freewalk>
      pagetable[i] = 0;
    80001554:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001558:	04a1                	addi	s1,s1,8
    8000155a:	03248163          	beq	s1,s2,8000157c <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000155e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001560:	00f57793          	andi	a5,a0,15
    80001564:	ff3782e3          	beq	a5,s3,80001548 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001568:	8905                	andi	a0,a0,1
    8000156a:	d57d                	beqz	a0,80001558 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000156c:	00007517          	auipc	a0,0x7
    80001570:	bfc50513          	addi	a0,a0,-1028 # 80008168 <digits+0x128>
    80001574:	fffff097          	auipc	ra,0xfffff
    80001578:	fd4080e7          	jalr	-44(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    8000157c:	8552                	mv	a0,s4
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	4a6080e7          	jalr	1190(ra) # 80000a24 <kfree>
}
    80001586:	70a2                	ld	ra,40(sp)
    80001588:	7402                	ld	s0,32(sp)
    8000158a:	64e2                	ld	s1,24(sp)
    8000158c:	6942                	ld	s2,16(sp)
    8000158e:	69a2                	ld	s3,8(sp)
    80001590:	6a02                	ld	s4,0(sp)
    80001592:	6145                	addi	sp,sp,48
    80001594:	8082                	ret

0000000080001596 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001596:	1101                	addi	sp,sp,-32
    80001598:	ec06                	sd	ra,24(sp)
    8000159a:	e822                	sd	s0,16(sp)
    8000159c:	e426                	sd	s1,8(sp)
    8000159e:	1000                	addi	s0,sp,32
    800015a0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015a2:	e999                	bnez	a1,800015b8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015a4:	8526                	mv	a0,s1
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	f86080e7          	jalr	-122(ra) # 8000152c <freewalk>
}
    800015ae:	60e2                	ld	ra,24(sp)
    800015b0:	6442                	ld	s0,16(sp)
    800015b2:	64a2                	ld	s1,8(sp)
    800015b4:	6105                	addi	sp,sp,32
    800015b6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	167d                	addi	a2,a2,-1
    800015bc:	962e                	add	a2,a2,a1
    800015be:	4685                	li	a3,1
    800015c0:	8231                	srli	a2,a2,0xc
    800015c2:	4581                	li	a1,0
    800015c4:	00000097          	auipc	ra,0x0
    800015c8:	d12080e7          	jalr	-750(ra) # 800012d6 <uvmunmap>
    800015cc:	bfe1                	j	800015a4 <uvmfree+0xe>

00000000800015ce <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015ce:	c679                	beqz	a2,8000169c <uvmcopy+0xce>
{
    800015d0:	715d                	addi	sp,sp,-80
    800015d2:	e486                	sd	ra,72(sp)
    800015d4:	e0a2                	sd	s0,64(sp)
    800015d6:	fc26                	sd	s1,56(sp)
    800015d8:	f84a                	sd	s2,48(sp)
    800015da:	f44e                	sd	s3,40(sp)
    800015dc:	f052                	sd	s4,32(sp)
    800015de:	ec56                	sd	s5,24(sp)
    800015e0:	e85a                	sd	s6,16(sp)
    800015e2:	e45e                	sd	s7,8(sp)
    800015e4:	0880                	addi	s0,sp,80
    800015e6:	8b2a                	mv	s6,a0
    800015e8:	8aae                	mv	s5,a1
    800015ea:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015ec:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015ee:	4601                	li	a2,0
    800015f0:	85ce                	mv	a1,s3
    800015f2:	855a                	mv	a0,s6
    800015f4:	00000097          	auipc	ra,0x0
    800015f8:	a04080e7          	jalr	-1532(ra) # 80000ff8 <walk>
    800015fc:	c531                	beqz	a0,80001648 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015fe:	6118                	ld	a4,0(a0)
    80001600:	00177793          	andi	a5,a4,1
    80001604:	cbb1                	beqz	a5,80001658 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001606:	00a75593          	srli	a1,a4,0xa
    8000160a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000160e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	50e080e7          	jalr	1294(ra) # 80000b20 <kalloc>
    8000161a:	892a                	mv	s2,a0
    8000161c:	c939                	beqz	a0,80001672 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000161e:	6605                	lui	a2,0x1
    80001620:	85de                	mv	a1,s7
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	74a080e7          	jalr	1866(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000162a:	8726                	mv	a4,s1
    8000162c:	86ca                	mv	a3,s2
    8000162e:	6605                	lui	a2,0x1
    80001630:	85ce                	mv	a1,s3
    80001632:	8556                	mv	a0,s5
    80001634:	00000097          	auipc	ra,0x0
    80001638:	b0a080e7          	jalr	-1270(ra) # 8000113e <mappages>
    8000163c:	e515                	bnez	a0,80001668 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000163e:	6785                	lui	a5,0x1
    80001640:	99be                	add	s3,s3,a5
    80001642:	fb49e6e3          	bltu	s3,s4,800015ee <uvmcopy+0x20>
    80001646:	a081                	j	80001686 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001648:	00007517          	auipc	a0,0x7
    8000164c:	b3050513          	addi	a0,a0,-1232 # 80008178 <digits+0x138>
    80001650:	fffff097          	auipc	ra,0xfffff
    80001654:	ef8080e7          	jalr	-264(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b4050513          	addi	a0,a0,-1216 # 80008198 <digits+0x158>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ee8080e7          	jalr	-280(ra) # 80000548 <panic>
      kfree(mem);
    80001668:	854a                	mv	a0,s2
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	3ba080e7          	jalr	954(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001672:	4685                	li	a3,1
    80001674:	00c9d613          	srli	a2,s3,0xc
    80001678:	4581                	li	a1,0
    8000167a:	8556                	mv	a0,s5
    8000167c:	00000097          	auipc	ra,0x0
    80001680:	c5a080e7          	jalr	-934(ra) # 800012d6 <uvmunmap>
  return -1;
    80001684:	557d                	li	a0,-1
}
    80001686:	60a6                	ld	ra,72(sp)
    80001688:	6406                	ld	s0,64(sp)
    8000168a:	74e2                	ld	s1,56(sp)
    8000168c:	7942                	ld	s2,48(sp)
    8000168e:	79a2                	ld	s3,40(sp)
    80001690:	7a02                	ld	s4,32(sp)
    80001692:	6ae2                	ld	s5,24(sp)
    80001694:	6b42                	ld	s6,16(sp)
    80001696:	6ba2                	ld	s7,8(sp)
    80001698:	6161                	addi	sp,sp,80
    8000169a:	8082                	ret
  return 0;
    8000169c:	4501                	li	a0,0
}
    8000169e:	8082                	ret

00000000800016a0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016a0:	1141                	addi	sp,sp,-16
    800016a2:	e406                	sd	ra,8(sp)
    800016a4:	e022                	sd	s0,0(sp)
    800016a6:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016a8:	4601                	li	a2,0
    800016aa:	00000097          	auipc	ra,0x0
    800016ae:	94e080e7          	jalr	-1714(ra) # 80000ff8 <walk>
  if(pte == 0)
    800016b2:	c901                	beqz	a0,800016c2 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016b4:	611c                	ld	a5,0(a0)
    800016b6:	9bbd                	andi	a5,a5,-17
    800016b8:	e11c                	sd	a5,0(a0)
}
    800016ba:	60a2                	ld	ra,8(sp)
    800016bc:	6402                	ld	s0,0(sp)
    800016be:	0141                	addi	sp,sp,16
    800016c0:	8082                	ret
    panic("uvmclear");
    800016c2:	00007517          	auipc	a0,0x7
    800016c6:	af650513          	addi	a0,a0,-1290 # 800081b8 <digits+0x178>
    800016ca:	fffff097          	auipc	ra,0xfffff
    800016ce:	e7e080e7          	jalr	-386(ra) # 80000548 <panic>

00000000800016d2 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016d2:	c6bd                	beqz	a3,80001740 <copyout+0x6e>
{
    800016d4:	715d                	addi	sp,sp,-80
    800016d6:	e486                	sd	ra,72(sp)
    800016d8:	e0a2                	sd	s0,64(sp)
    800016da:	fc26                	sd	s1,56(sp)
    800016dc:	f84a                	sd	s2,48(sp)
    800016de:	f44e                	sd	s3,40(sp)
    800016e0:	f052                	sd	s4,32(sp)
    800016e2:	ec56                	sd	s5,24(sp)
    800016e4:	e85a                	sd	s6,16(sp)
    800016e6:	e45e                	sd	s7,8(sp)
    800016e8:	e062                	sd	s8,0(sp)
    800016ea:	0880                	addi	s0,sp,80
    800016ec:	8b2a                	mv	s6,a0
    800016ee:	8c2e                	mv	s8,a1
    800016f0:	8a32                	mv	s4,a2
    800016f2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016f4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016f6:	6a85                	lui	s5,0x1
    800016f8:	a015                	j	8000171c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016fa:	9562                	add	a0,a0,s8
    800016fc:	0004861b          	sext.w	a2,s1
    80001700:	85d2                	mv	a1,s4
    80001702:	41250533          	sub	a0,a0,s2
    80001706:	fffff097          	auipc	ra,0xfffff
    8000170a:	666080e7          	jalr	1638(ra) # 80000d6c <memmove>

    len -= n;
    8000170e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001712:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001714:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001718:	02098263          	beqz	s3,8000173c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000171c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001720:	85ca                	mv	a1,s2
    80001722:	855a                	mv	a0,s6
    80001724:	00000097          	auipc	ra,0x0
    80001728:	97a080e7          	jalr	-1670(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    8000172c:	cd01                	beqz	a0,80001744 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000172e:	418904b3          	sub	s1,s2,s8
    80001732:	94d6                	add	s1,s1,s5
    if(n > len)
    80001734:	fc99f3e3          	bgeu	s3,s1,800016fa <copyout+0x28>
    80001738:	84ce                	mv	s1,s3
    8000173a:	b7c1                	j	800016fa <copyout+0x28>
  }
  return 0;
    8000173c:	4501                	li	a0,0
    8000173e:	a021                	j	80001746 <copyout+0x74>
    80001740:	4501                	li	a0,0
}
    80001742:	8082                	ret
      return -1;
    80001744:	557d                	li	a0,-1
}
    80001746:	60a6                	ld	ra,72(sp)
    80001748:	6406                	ld	s0,64(sp)
    8000174a:	74e2                	ld	s1,56(sp)
    8000174c:	7942                	ld	s2,48(sp)
    8000174e:	79a2                	ld	s3,40(sp)
    80001750:	7a02                	ld	s4,32(sp)
    80001752:	6ae2                	ld	s5,24(sp)
    80001754:	6b42                	ld	s6,16(sp)
    80001756:	6ba2                	ld	s7,8(sp)
    80001758:	6c02                	ld	s8,0(sp)
    8000175a:	6161                	addi	sp,sp,80
    8000175c:	8082                	ret

000000008000175e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000175e:	c6bd                	beqz	a3,800017cc <copyin+0x6e>
{
    80001760:	715d                	addi	sp,sp,-80
    80001762:	e486                	sd	ra,72(sp)
    80001764:	e0a2                	sd	s0,64(sp)
    80001766:	fc26                	sd	s1,56(sp)
    80001768:	f84a                	sd	s2,48(sp)
    8000176a:	f44e                	sd	s3,40(sp)
    8000176c:	f052                	sd	s4,32(sp)
    8000176e:	ec56                	sd	s5,24(sp)
    80001770:	e85a                	sd	s6,16(sp)
    80001772:	e45e                	sd	s7,8(sp)
    80001774:	e062                	sd	s8,0(sp)
    80001776:	0880                	addi	s0,sp,80
    80001778:	8b2a                	mv	s6,a0
    8000177a:	8a2e                	mv	s4,a1
    8000177c:	8c32                	mv	s8,a2
    8000177e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001780:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001782:	6a85                	lui	s5,0x1
    80001784:	a015                	j	800017a8 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001786:	9562                	add	a0,a0,s8
    80001788:	0004861b          	sext.w	a2,s1
    8000178c:	412505b3          	sub	a1,a0,s2
    80001790:	8552                	mv	a0,s4
    80001792:	fffff097          	auipc	ra,0xfffff
    80001796:	5da080e7          	jalr	1498(ra) # 80000d6c <memmove>

    len -= n;
    8000179a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000179e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017a0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017a4:	02098263          	beqz	s3,800017c8 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017a8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017ac:	85ca                	mv	a1,s2
    800017ae:	855a                	mv	a0,s6
    800017b0:	00000097          	auipc	ra,0x0
    800017b4:	8ee080e7          	jalr	-1810(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    800017b8:	cd01                	beqz	a0,800017d0 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800017ba:	418904b3          	sub	s1,s2,s8
    800017be:	94d6                	add	s1,s1,s5
    if(n > len)
    800017c0:	fc99f3e3          	bgeu	s3,s1,80001786 <copyin+0x28>
    800017c4:	84ce                	mv	s1,s3
    800017c6:	b7c1                	j	80001786 <copyin+0x28>
  }
  return 0;
    800017c8:	4501                	li	a0,0
    800017ca:	a021                	j	800017d2 <copyin+0x74>
    800017cc:	4501                	li	a0,0
}
    800017ce:	8082                	ret
      return -1;
    800017d0:	557d                	li	a0,-1
}
    800017d2:	60a6                	ld	ra,72(sp)
    800017d4:	6406                	ld	s0,64(sp)
    800017d6:	74e2                	ld	s1,56(sp)
    800017d8:	7942                	ld	s2,48(sp)
    800017da:	79a2                	ld	s3,40(sp)
    800017dc:	7a02                	ld	s4,32(sp)
    800017de:	6ae2                	ld	s5,24(sp)
    800017e0:	6b42                	ld	s6,16(sp)
    800017e2:	6ba2                	ld	s7,8(sp)
    800017e4:	6c02                	ld	s8,0(sp)
    800017e6:	6161                	addi	sp,sp,80
    800017e8:	8082                	ret

00000000800017ea <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017ea:	c6c5                	beqz	a3,80001892 <copyinstr+0xa8>
{
    800017ec:	715d                	addi	sp,sp,-80
    800017ee:	e486                	sd	ra,72(sp)
    800017f0:	e0a2                	sd	s0,64(sp)
    800017f2:	fc26                	sd	s1,56(sp)
    800017f4:	f84a                	sd	s2,48(sp)
    800017f6:	f44e                	sd	s3,40(sp)
    800017f8:	f052                	sd	s4,32(sp)
    800017fa:	ec56                	sd	s5,24(sp)
    800017fc:	e85a                	sd	s6,16(sp)
    800017fe:	e45e                	sd	s7,8(sp)
    80001800:	0880                	addi	s0,sp,80
    80001802:	8a2a                	mv	s4,a0
    80001804:	8b2e                	mv	s6,a1
    80001806:	8bb2                	mv	s7,a2
    80001808:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000180a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000180c:	6985                	lui	s3,0x1
    8000180e:	a035                	j	8000183a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001810:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001814:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001816:	0017b793          	seqz	a5,a5
    8000181a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000181e:	60a6                	ld	ra,72(sp)
    80001820:	6406                	ld	s0,64(sp)
    80001822:	74e2                	ld	s1,56(sp)
    80001824:	7942                	ld	s2,48(sp)
    80001826:	79a2                	ld	s3,40(sp)
    80001828:	7a02                	ld	s4,32(sp)
    8000182a:	6ae2                	ld	s5,24(sp)
    8000182c:	6b42                	ld	s6,16(sp)
    8000182e:	6ba2                	ld	s7,8(sp)
    80001830:	6161                	addi	sp,sp,80
    80001832:	8082                	ret
    srcva = va0 + PGSIZE;
    80001834:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001838:	c8a9                	beqz	s1,8000188a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000183a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000183e:	85ca                	mv	a1,s2
    80001840:	8552                	mv	a0,s4
    80001842:	00000097          	auipc	ra,0x0
    80001846:	85c080e7          	jalr	-1956(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    8000184a:	c131                	beqz	a0,8000188e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000184c:	41790833          	sub	a6,s2,s7
    80001850:	984e                	add	a6,a6,s3
    if(n > max)
    80001852:	0104f363          	bgeu	s1,a6,80001858 <copyinstr+0x6e>
    80001856:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001858:	955e                	add	a0,a0,s7
    8000185a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000185e:	fc080be3          	beqz	a6,80001834 <copyinstr+0x4a>
    80001862:	985a                	add	a6,a6,s6
    80001864:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001866:	41650633          	sub	a2,a0,s6
    8000186a:	14fd                	addi	s1,s1,-1
    8000186c:	9b26                	add	s6,s6,s1
    8000186e:	00f60733          	add	a4,a2,a5
    80001872:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001876:	df49                	beqz	a4,80001810 <copyinstr+0x26>
        *dst = *p;
    80001878:	00e78023          	sb	a4,0(a5)
      --max;
    8000187c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001880:	0785                	addi	a5,a5,1
    while(n > 0){
    80001882:	ff0796e3          	bne	a5,a6,8000186e <copyinstr+0x84>
      dst++;
    80001886:	8b42                	mv	s6,a6
    80001888:	b775                	j	80001834 <copyinstr+0x4a>
    8000188a:	4781                	li	a5,0
    8000188c:	b769                	j	80001816 <copyinstr+0x2c>
      return -1;
    8000188e:	557d                	li	a0,-1
    80001890:	b779                	j	8000181e <copyinstr+0x34>
  int got_null = 0;
    80001892:	4781                	li	a5,0
  if(got_null){
    80001894:	0017b793          	seqz	a5,a5
    80001898:	40f00533          	neg	a0,a5
}
    8000189c:	8082                	ret

000000008000189e <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000189e:	1101                	addi	sp,sp,-32
    800018a0:	ec06                	sd	ra,24(sp)
    800018a2:	e822                	sd	s0,16(sp)
    800018a4:	e426                	sd	s1,8(sp)
    800018a6:	1000                	addi	s0,sp,32
    800018a8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018aa:	fffff097          	auipc	ra,0xfffff
    800018ae:	2ec080e7          	jalr	748(ra) # 80000b96 <holding>
    800018b2:	c909                	beqz	a0,800018c4 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018b4:	749c                	ld	a5,40(s1)
    800018b6:	00978f63          	beq	a5,s1,800018d4 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800018ba:	60e2                	ld	ra,24(sp)
    800018bc:	6442                	ld	s0,16(sp)
    800018be:	64a2                	ld	s1,8(sp)
    800018c0:	6105                	addi	sp,sp,32
    800018c2:	8082                	ret
    panic("wakeup1");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	90450513          	addi	a0,a0,-1788 # 800081c8 <digits+0x188>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c7c080e7          	jalr	-900(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800018d4:	4c98                	lw	a4,24(s1)
    800018d6:	4785                	li	a5,1
    800018d8:	fef711e3          	bne	a4,a5,800018ba <wakeup1+0x1c>
    p->state = RUNNABLE;
    800018dc:	4789                	li	a5,2
    800018de:	cc9c                	sw	a5,24(s1)
}
    800018e0:	bfe9                	j	800018ba <wakeup1+0x1c>

00000000800018e2 <procinit>:
{
    800018e2:	715d                	addi	sp,sp,-80
    800018e4:	e486                	sd	ra,72(sp)
    800018e6:	e0a2                	sd	s0,64(sp)
    800018e8:	fc26                	sd	s1,56(sp)
    800018ea:	f84a                	sd	s2,48(sp)
    800018ec:	f44e                	sd	s3,40(sp)
    800018ee:	f052                	sd	s4,32(sp)
    800018f0:	ec56                	sd	s5,24(sp)
    800018f2:	e85a                	sd	s6,16(sp)
    800018f4:	e45e                	sd	s7,8(sp)
    800018f6:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8d858593          	addi	a1,a1,-1832 # 800081d0 <digits+0x190>
    80001900:	00010517          	auipc	a0,0x10
    80001904:	05050513          	addi	a0,a0,80 # 80011950 <pid_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	278080e7          	jalr	632(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	00010917          	auipc	s2,0x10
    80001914:	45890913          	addi	s2,s2,1112 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b97          	auipc	s7,0x7
    8000191c:	8c0b8b93          	addi	s7,s7,-1856 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001920:	8b4a                	mv	s6,s2
    80001922:	00006a97          	auipc	s5,0x6
    80001926:	6dea8a93          	addi	s5,s5,1758 # 80008000 <etext>
    8000192a:	040009b7          	lui	s3,0x4000
    8000192e:	19fd                	addi	s3,s3,-1
    80001930:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00016a17          	auipc	s4,0x16
    80001936:	036a0a13          	addi	s4,s4,54 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85de                	mv	a1,s7
    8000193c:	854a                	mv	a0,s2
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	242080e7          	jalr	578(ra) # 80000b80 <initlock>
      char *pa = kalloc();
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	1da080e7          	jalr	474(ra) # 80000b20 <kalloc>
    8000194e:	85aa                	mv	a1,a0
      if(pa == 0)
    80001950:	c929                	beqz	a0,800019a2 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001952:	416904b3          	sub	s1,s2,s6
    80001956:	8491                	srai	s1,s1,0x4
    80001958:	000ab783          	ld	a5,0(s5)
    8000195c:	02f484b3          	mul	s1,s1,a5
    80001960:	2485                	addiw	s1,s1,1
    80001962:	00d4949b          	slliw	s1,s1,0xd
    80001966:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000196a:	4699                	li	a3,6
    8000196c:	6605                	lui	a2,0x1
    8000196e:	8526                	mv	a0,s1
    80001970:	00000097          	auipc	ra,0x0
    80001974:	85c080e7          	jalr	-1956(ra) # 800011cc <kvmmap>
      p->kstack = va;
    80001978:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	17090913          	addi	s2,s2,368
    80001980:	fb491de3          	bne	s2,s4,8000193a <procinit+0x58>
  kvminithart();
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	650080e7          	jalr	1616(ra) # 80000fd4 <kvminithart>
}
    8000198c:	60a6                	ld	ra,72(sp)
    8000198e:	6406                	ld	s0,64(sp)
    80001990:	74e2                	ld	s1,56(sp)
    80001992:	7942                	ld	s2,48(sp)
    80001994:	79a2                	ld	s3,40(sp)
    80001996:	7a02                	ld	s4,32(sp)
    80001998:	6ae2                	ld	s5,24(sp)
    8000199a:	6b42                	ld	s6,16(sp)
    8000199c:	6ba2                	ld	s7,8(sp)
    8000199e:	6161                	addi	sp,sp,80
    800019a0:	8082                	ret
        panic("kalloc");
    800019a2:	00007517          	auipc	a0,0x7
    800019a6:	83e50513          	addi	a0,a0,-1986 # 800081e0 <digits+0x1a0>
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	b9e080e7          	jalr	-1122(ra) # 80000548 <panic>

00000000800019b2 <cpuid>:
{
    800019b2:	1141                	addi	sp,sp,-16
    800019b4:	e422                	sd	s0,8(sp)
    800019b6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019b8:	8512                	mv	a0,tp
}
    800019ba:	2501                	sext.w	a0,a0
    800019bc:	6422                	ld	s0,8(sp)
    800019be:	0141                	addi	sp,sp,16
    800019c0:	8082                	ret

00000000800019c2 <mycpu>:
mycpu(void) {
    800019c2:	1141                	addi	sp,sp,-16
    800019c4:	e422                	sd	s0,8(sp)
    800019c6:	0800                	addi	s0,sp,16
    800019c8:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019ca:	2781                	sext.w	a5,a5
    800019cc:	079e                	slli	a5,a5,0x7
}
    800019ce:	00010517          	auipc	a0,0x10
    800019d2:	f9a50513          	addi	a0,a0,-102 # 80011968 <cpus>
    800019d6:	953e                	add	a0,a0,a5
    800019d8:	6422                	ld	s0,8(sp)
    800019da:	0141                	addi	sp,sp,16
    800019dc:	8082                	ret

00000000800019de <myproc>:
myproc(void) {
    800019de:	1101                	addi	sp,sp,-32
    800019e0:	ec06                	sd	ra,24(sp)
    800019e2:	e822                	sd	s0,16(sp)
    800019e4:	e426                	sd	s1,8(sp)
    800019e6:	1000                	addi	s0,sp,32
  push_off();
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	1dc080e7          	jalr	476(ra) # 80000bc4 <push_off>
    800019f0:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    800019f2:	2781                	sext.w	a5,a5
    800019f4:	079e                	slli	a5,a5,0x7
    800019f6:	00010717          	auipc	a4,0x10
    800019fa:	f5a70713          	addi	a4,a4,-166 # 80011950 <pid_lock>
    800019fe:	97ba                	add	a5,a5,a4
    80001a00:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a02:	fffff097          	auipc	ra,0xfffff
    80001a06:	262080e7          	jalr	610(ra) # 80000c64 <pop_off>
}
    80001a0a:	8526                	mv	a0,s1
    80001a0c:	60e2                	ld	ra,24(sp)
    80001a0e:	6442                	ld	s0,16(sp)
    80001a10:	64a2                	ld	s1,8(sp)
    80001a12:	6105                	addi	sp,sp,32
    80001a14:	8082                	ret

0000000080001a16 <forkret>:
{
    80001a16:	1141                	addi	sp,sp,-16
    80001a18:	e406                	sd	ra,8(sp)
    80001a1a:	e022                	sd	s0,0(sp)
    80001a1c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a1e:	00000097          	auipc	ra,0x0
    80001a22:	fc0080e7          	jalr	-64(ra) # 800019de <myproc>
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	29e080e7          	jalr	670(ra) # 80000cc4 <release>
  if (first) {
    80001a2e:	00007797          	auipc	a5,0x7
    80001a32:	f627a783          	lw	a5,-158(a5) # 80008990 <first.1663>
    80001a36:	eb89                	bnez	a5,80001a48 <forkret+0x32>
  usertrapret();
    80001a38:	00001097          	auipc	ra,0x1
    80001a3c:	c24080e7          	jalr	-988(ra) # 8000265c <usertrapret>
}
    80001a40:	60a2                	ld	ra,8(sp)
    80001a42:	6402                	ld	s0,0(sp)
    80001a44:	0141                	addi	sp,sp,16
    80001a46:	8082                	ret
    first = 0;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	f407a423          	sw	zero,-184(a5) # 80008990 <first.1663>
    fsinit(ROOTDEV);
    80001a50:	4505                	li	a0,1
    80001a52:	00002097          	auipc	ra,0x2
    80001a56:	9c4080e7          	jalr	-1596(ra) # 80003416 <fsinit>
    80001a5a:	bff9                	j	80001a38 <forkret+0x22>

0000000080001a5c <allocpid>:
allocpid() {
    80001a5c:	1101                	addi	sp,sp,-32
    80001a5e:	ec06                	sd	ra,24(sp)
    80001a60:	e822                	sd	s0,16(sp)
    80001a62:	e426                	sd	s1,8(sp)
    80001a64:	e04a                	sd	s2,0(sp)
    80001a66:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a68:	00010917          	auipc	s2,0x10
    80001a6c:	ee890913          	addi	s2,s2,-280 # 80011950 <pid_lock>
    80001a70:	854a                	mv	a0,s2
    80001a72:	fffff097          	auipc	ra,0xfffff
    80001a76:	19e080e7          	jalr	414(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001a7a:	00007797          	auipc	a5,0x7
    80001a7e:	f1a78793          	addi	a5,a5,-230 # 80008994 <nextpid>
    80001a82:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a84:	0014871b          	addiw	a4,s1,1
    80001a88:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a8a:	854a                	mv	a0,s2
    80001a8c:	fffff097          	auipc	ra,0xfffff
    80001a90:	238080e7          	jalr	568(ra) # 80000cc4 <release>
}
    80001a94:	8526                	mv	a0,s1
    80001a96:	60e2                	ld	ra,24(sp)
    80001a98:	6442                	ld	s0,16(sp)
    80001a9a:	64a2                	ld	s1,8(sp)
    80001a9c:	6902                	ld	s2,0(sp)
    80001a9e:	6105                	addi	sp,sp,32
    80001aa0:	8082                	ret

0000000080001aa2 <proc_pagetable>:
{
    80001aa2:	1101                	addi	sp,sp,-32
    80001aa4:	ec06                	sd	ra,24(sp)
    80001aa6:	e822                	sd	s0,16(sp)
    80001aa8:	e426                	sd	s1,8(sp)
    80001aaa:	e04a                	sd	s2,0(sp)
    80001aac:	1000                	addi	s0,sp,32
    80001aae:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ab0:	00000097          	auipc	ra,0x0
    80001ab4:	8ea080e7          	jalr	-1814(ra) # 8000139a <uvmcreate>
    80001ab8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aba:	c121                	beqz	a0,80001afa <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001abc:	4729                	li	a4,10
    80001abe:	00005697          	auipc	a3,0x5
    80001ac2:	54268693          	addi	a3,a3,1346 # 80007000 <_trampoline>
    80001ac6:	6605                	lui	a2,0x1
    80001ac8:	040005b7          	lui	a1,0x4000
    80001acc:	15fd                	addi	a1,a1,-1
    80001ace:	05b2                	slli	a1,a1,0xc
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	66e080e7          	jalr	1646(ra) # 8000113e <mappages>
    80001ad8:	02054863          	bltz	a0,80001b08 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001adc:	4719                	li	a4,6
    80001ade:	05893683          	ld	a3,88(s2)
    80001ae2:	6605                	lui	a2,0x1
    80001ae4:	020005b7          	lui	a1,0x2000
    80001ae8:	15fd                	addi	a1,a1,-1
    80001aea:	05b6                	slli	a1,a1,0xd
    80001aec:	8526                	mv	a0,s1
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	650080e7          	jalr	1616(ra) # 8000113e <mappages>
    80001af6:	02054163          	bltz	a0,80001b18 <proc_pagetable+0x76>
}
    80001afa:	8526                	mv	a0,s1
    80001afc:	60e2                	ld	ra,24(sp)
    80001afe:	6442                	ld	s0,16(sp)
    80001b00:	64a2                	ld	s1,8(sp)
    80001b02:	6902                	ld	s2,0(sp)
    80001b04:	6105                	addi	sp,sp,32
    80001b06:	8082                	ret
    uvmfree(pagetable, 0);
    80001b08:	4581                	li	a1,0
    80001b0a:	8526                	mv	a0,s1
    80001b0c:	00000097          	auipc	ra,0x0
    80001b10:	a8a080e7          	jalr	-1398(ra) # 80001596 <uvmfree>
    return 0;
    80001b14:	4481                	li	s1,0
    80001b16:	b7d5                	j	80001afa <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b18:	4681                	li	a3,0
    80001b1a:	4605                	li	a2,1
    80001b1c:	040005b7          	lui	a1,0x4000
    80001b20:	15fd                	addi	a1,a1,-1
    80001b22:	05b2                	slli	a1,a1,0xc
    80001b24:	8526                	mv	a0,s1
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	7b0080e7          	jalr	1968(ra) # 800012d6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b2e:	4581                	li	a1,0
    80001b30:	8526                	mv	a0,s1
    80001b32:	00000097          	auipc	ra,0x0
    80001b36:	a64080e7          	jalr	-1436(ra) # 80001596 <uvmfree>
    return 0;
    80001b3a:	4481                	li	s1,0
    80001b3c:	bf7d                	j	80001afa <proc_pagetable+0x58>

0000000080001b3e <proc_freepagetable>:
{
    80001b3e:	1101                	addi	sp,sp,-32
    80001b40:	ec06                	sd	ra,24(sp)
    80001b42:	e822                	sd	s0,16(sp)
    80001b44:	e426                	sd	s1,8(sp)
    80001b46:	e04a                	sd	s2,0(sp)
    80001b48:	1000                	addi	s0,sp,32
    80001b4a:	84aa                	mv	s1,a0
    80001b4c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b4e:	4681                	li	a3,0
    80001b50:	4605                	li	a2,1
    80001b52:	040005b7          	lui	a1,0x4000
    80001b56:	15fd                	addi	a1,a1,-1
    80001b58:	05b2                	slli	a1,a1,0xc
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	77c080e7          	jalr	1916(ra) # 800012d6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b62:	4681                	li	a3,0
    80001b64:	4605                	li	a2,1
    80001b66:	020005b7          	lui	a1,0x2000
    80001b6a:	15fd                	addi	a1,a1,-1
    80001b6c:	05b6                	slli	a1,a1,0xd
    80001b6e:	8526                	mv	a0,s1
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	766080e7          	jalr	1894(ra) # 800012d6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b78:	85ca                	mv	a1,s2
    80001b7a:	8526                	mv	a0,s1
    80001b7c:	00000097          	auipc	ra,0x0
    80001b80:	a1a080e7          	jalr	-1510(ra) # 80001596 <uvmfree>
}
    80001b84:	60e2                	ld	ra,24(sp)
    80001b86:	6442                	ld	s0,16(sp)
    80001b88:	64a2                	ld	s1,8(sp)
    80001b8a:	6902                	ld	s2,0(sp)
    80001b8c:	6105                	addi	sp,sp,32
    80001b8e:	8082                	ret

0000000080001b90 <freeproc>:
{
    80001b90:	1101                	addi	sp,sp,-32
    80001b92:	ec06                	sd	ra,24(sp)
    80001b94:	e822                	sd	s0,16(sp)
    80001b96:	e426                	sd	s1,8(sp)
    80001b98:	1000                	addi	s0,sp,32
    80001b9a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b9c:	6d28                	ld	a0,88(a0)
    80001b9e:	c509                	beqz	a0,80001ba8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	e84080e7          	jalr	-380(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001ba8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bac:	68a8                	ld	a0,80(s1)
    80001bae:	c511                	beqz	a0,80001bba <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bb0:	64ac                	ld	a1,72(s1)
    80001bb2:	00000097          	auipc	ra,0x0
    80001bb6:	f8c080e7          	jalr	-116(ra) # 80001b3e <proc_freepagetable>
  p->pagetable = 0;
    80001bba:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bbe:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bc2:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001bc6:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001bca:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bce:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001bd2:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001bd6:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001bda:	0004ac23          	sw	zero,24(s1)
}
    80001bde:	60e2                	ld	ra,24(sp)
    80001be0:	6442                	ld	s0,16(sp)
    80001be2:	64a2                	ld	s1,8(sp)
    80001be4:	6105                	addi	sp,sp,32
    80001be6:	8082                	ret

0000000080001be8 <allocproc>:
{
    80001be8:	1101                	addi	sp,sp,-32
    80001bea:	ec06                	sd	ra,24(sp)
    80001bec:	e822                	sd	s0,16(sp)
    80001bee:	e426                	sd	s1,8(sp)
    80001bf0:	e04a                	sd	s2,0(sp)
    80001bf2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf4:	00010497          	auipc	s1,0x10
    80001bf8:	17448493          	addi	s1,s1,372 # 80011d68 <proc>
    80001bfc:	00016917          	auipc	s2,0x16
    80001c00:	d6c90913          	addi	s2,s2,-660 # 80017968 <tickslock>
    acquire(&p->lock);
    80001c04:	8526                	mv	a0,s1
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	00a080e7          	jalr	10(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001c0e:	4c9c                	lw	a5,24(s1)
    80001c10:	cf81                	beqz	a5,80001c28 <allocproc+0x40>
      release(&p->lock);
    80001c12:	8526                	mv	a0,s1
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	0b0080e7          	jalr	176(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c1c:	17048493          	addi	s1,s1,368
    80001c20:	ff2492e3          	bne	s1,s2,80001c04 <allocproc+0x1c>
  return 0;
    80001c24:	4481                	li	s1,0
    80001c26:	a889                	j	80001c78 <allocproc+0x90>
  p->pid = allocpid();
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	e34080e7          	jalr	-460(ra) # 80001a5c <allocpid>
    80001c30:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	eee080e7          	jalr	-274(ra) # 80000b20 <kalloc>
    80001c3a:	892a                	mv	s2,a0
    80001c3c:	eca8                	sd	a0,88(s1)
    80001c3e:	c521                	beqz	a0,80001c86 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c40:	8526                	mv	a0,s1
    80001c42:	00000097          	auipc	ra,0x0
    80001c46:	e60080e7          	jalr	-416(ra) # 80001aa2 <proc_pagetable>
    80001c4a:	892a                	mv	s2,a0
    80001c4c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c4e:	c139                	beqz	a0,80001c94 <allocproc+0xac>
  memset(&p->context, 0, sizeof(p->context));
    80001c50:	07000613          	li	a2,112
    80001c54:	4581                	li	a1,0
    80001c56:	06048513          	addi	a0,s1,96
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	0b2080e7          	jalr	178(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001c62:	00000797          	auipc	a5,0x0
    80001c66:	db478793          	addi	a5,a5,-588 # 80001a16 <forkret>
    80001c6a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c6c:	60bc                	ld	a5,64(s1)
    80001c6e:	6705                	lui	a4,0x1
    80001c70:	97ba                	add	a5,a5,a4
    80001c72:	f4bc                	sd	a5,104(s1)
  p->tracemask = 0;
    80001c74:	1604b423          	sd	zero,360(s1)
}
    80001c78:	8526                	mv	a0,s1
    80001c7a:	60e2                	ld	ra,24(sp)
    80001c7c:	6442                	ld	s0,16(sp)
    80001c7e:	64a2                	ld	s1,8(sp)
    80001c80:	6902                	ld	s2,0(sp)
    80001c82:	6105                	addi	sp,sp,32
    80001c84:	8082                	ret
    release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	03c080e7          	jalr	60(ra) # 80000cc4 <release>
    return 0;
    80001c90:	84ca                	mv	s1,s2
    80001c92:	b7dd                	j	80001c78 <allocproc+0x90>
    freeproc(p);
    80001c94:	8526                	mv	a0,s1
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	efa080e7          	jalr	-262(ra) # 80001b90 <freeproc>
    release(&p->lock);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	024080e7          	jalr	36(ra) # 80000cc4 <release>
    return 0;
    80001ca8:	84ca                	mv	s1,s2
    80001caa:	b7f9                	j	80001c78 <allocproc+0x90>

0000000080001cac <userinit>:
{
    80001cac:	1101                	addi	sp,sp,-32
    80001cae:	ec06                	sd	ra,24(sp)
    80001cb0:	e822                	sd	s0,16(sp)
    80001cb2:	e426                	sd	s1,8(sp)
    80001cb4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	f32080e7          	jalr	-206(ra) # 80001be8 <allocproc>
    80001cbe:	84aa                	mv	s1,a0
  initproc = p;
    80001cc0:	00007797          	auipc	a5,0x7
    80001cc4:	34a7bc23          	sd	a0,856(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cc8:	03400613          	li	a2,52
    80001ccc:	00007597          	auipc	a1,0x7
    80001cd0:	cd458593          	addi	a1,a1,-812 # 800089a0 <initcode>
    80001cd4:	6928                	ld	a0,80(a0)
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	6f2080e7          	jalr	1778(ra) # 800013c8 <uvminit>
  p->sz = PGSIZE;
    80001cde:	6785                	lui	a5,0x1
    80001ce0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ce2:	6cb8                	ld	a4,88(s1)
    80001ce4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce8:	6cb8                	ld	a4,88(s1)
    80001cea:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cec:	4641                	li	a2,16
    80001cee:	00006597          	auipc	a1,0x6
    80001cf2:	4fa58593          	addi	a1,a1,1274 # 800081e8 <digits+0x1a8>
    80001cf6:	15848513          	addi	a0,s1,344
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	168080e7          	jalr	360(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001d02:	00006517          	auipc	a0,0x6
    80001d06:	4f650513          	addi	a0,a0,1270 # 800081f8 <digits+0x1b8>
    80001d0a:	00002097          	auipc	ra,0x2
    80001d0e:	134080e7          	jalr	308(ra) # 80003e3e <namei>
    80001d12:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d16:	4789                	li	a5,2
    80001d18:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	fa8080e7          	jalr	-88(ra) # 80000cc4 <release>
}
    80001d24:	60e2                	ld	ra,24(sp)
    80001d26:	6442                	ld	s0,16(sp)
    80001d28:	64a2                	ld	s1,8(sp)
    80001d2a:	6105                	addi	sp,sp,32
    80001d2c:	8082                	ret

0000000080001d2e <growproc>:
{
    80001d2e:	1101                	addi	sp,sp,-32
    80001d30:	ec06                	sd	ra,24(sp)
    80001d32:	e822                	sd	s0,16(sp)
    80001d34:	e426                	sd	s1,8(sp)
    80001d36:	e04a                	sd	s2,0(sp)
    80001d38:	1000                	addi	s0,sp,32
    80001d3a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d3c:	00000097          	auipc	ra,0x0
    80001d40:	ca2080e7          	jalr	-862(ra) # 800019de <myproc>
    80001d44:	892a                	mv	s2,a0
  sz = p->sz;
    80001d46:	652c                	ld	a1,72(a0)
    80001d48:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d4c:	00904f63          	bgtz	s1,80001d6a <growproc+0x3c>
  } else if(n < 0){
    80001d50:	0204cc63          	bltz	s1,80001d88 <growproc+0x5a>
  p->sz = sz;
    80001d54:	1602                	slli	a2,a2,0x20
    80001d56:	9201                	srli	a2,a2,0x20
    80001d58:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d5c:	4501                	li	a0,0
}
    80001d5e:	60e2                	ld	ra,24(sp)
    80001d60:	6442                	ld	s0,16(sp)
    80001d62:	64a2                	ld	s1,8(sp)
    80001d64:	6902                	ld	s2,0(sp)
    80001d66:	6105                	addi	sp,sp,32
    80001d68:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d6a:	9e25                	addw	a2,a2,s1
    80001d6c:	1602                	slli	a2,a2,0x20
    80001d6e:	9201                	srli	a2,a2,0x20
    80001d70:	1582                	slli	a1,a1,0x20
    80001d72:	9181                	srli	a1,a1,0x20
    80001d74:	6928                	ld	a0,80(a0)
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	70c080e7          	jalr	1804(ra) # 80001482 <uvmalloc>
    80001d7e:	0005061b          	sext.w	a2,a0
    80001d82:	fa69                	bnez	a2,80001d54 <growproc+0x26>
      return -1;
    80001d84:	557d                	li	a0,-1
    80001d86:	bfe1                	j	80001d5e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d88:	9e25                	addw	a2,a2,s1
    80001d8a:	1602                	slli	a2,a2,0x20
    80001d8c:	9201                	srli	a2,a2,0x20
    80001d8e:	1582                	slli	a1,a1,0x20
    80001d90:	9181                	srli	a1,a1,0x20
    80001d92:	6928                	ld	a0,80(a0)
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	6a6080e7          	jalr	1702(ra) # 8000143a <uvmdealloc>
    80001d9c:	0005061b          	sext.w	a2,a0
    80001da0:	bf55                	j	80001d54 <growproc+0x26>

0000000080001da2 <fork>:
{
    80001da2:	7179                	addi	sp,sp,-48
    80001da4:	f406                	sd	ra,40(sp)
    80001da6:	f022                	sd	s0,32(sp)
    80001da8:	ec26                	sd	s1,24(sp)
    80001daa:	e84a                	sd	s2,16(sp)
    80001dac:	e44e                	sd	s3,8(sp)
    80001dae:	e052                	sd	s4,0(sp)
    80001db0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001db2:	00000097          	auipc	ra,0x0
    80001db6:	c2c080e7          	jalr	-980(ra) # 800019de <myproc>
    80001dba:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	e2c080e7          	jalr	-468(ra) # 80001be8 <allocproc>
    80001dc4:	c575                	beqz	a0,80001eb0 <fork+0x10e>
    80001dc6:	89aa                	mv	s3,a0
  np->tracemask = p->tracemask;
    80001dc8:	16893783          	ld	a5,360(s2)
    80001dcc:	16f53423          	sd	a5,360(a0)
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dd0:	04893603          	ld	a2,72(s2)
    80001dd4:	692c                	ld	a1,80(a0)
    80001dd6:	05093503          	ld	a0,80(s2)
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	7f4080e7          	jalr	2036(ra) # 800015ce <uvmcopy>
    80001de2:	04054863          	bltz	a0,80001e32 <fork+0x90>
  np->sz = p->sz;
    80001de6:	04893783          	ld	a5,72(s2)
    80001dea:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001dee:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001df2:	05893683          	ld	a3,88(s2)
    80001df6:	87b6                	mv	a5,a3
    80001df8:	0589b703          	ld	a4,88(s3)
    80001dfc:	12068693          	addi	a3,a3,288
    80001e00:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e04:	6788                	ld	a0,8(a5)
    80001e06:	6b8c                	ld	a1,16(a5)
    80001e08:	6f90                	ld	a2,24(a5)
    80001e0a:	01073023          	sd	a6,0(a4)
    80001e0e:	e708                	sd	a0,8(a4)
    80001e10:	eb0c                	sd	a1,16(a4)
    80001e12:	ef10                	sd	a2,24(a4)
    80001e14:	02078793          	addi	a5,a5,32
    80001e18:	02070713          	addi	a4,a4,32
    80001e1c:	fed792e3          	bne	a5,a3,80001e00 <fork+0x5e>
  np->trapframe->a0 = 0;
    80001e20:	0589b783          	ld	a5,88(s3)
    80001e24:	0607b823          	sd	zero,112(a5)
    80001e28:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e2c:	15000a13          	li	s4,336
    80001e30:	a03d                	j	80001e5e <fork+0xbc>
    freeproc(np);
    80001e32:	854e                	mv	a0,s3
    80001e34:	00000097          	auipc	ra,0x0
    80001e38:	d5c080e7          	jalr	-676(ra) # 80001b90 <freeproc>
    release(&np->lock);
    80001e3c:	854e                	mv	a0,s3
    80001e3e:	fffff097          	auipc	ra,0xfffff
    80001e42:	e86080e7          	jalr	-378(ra) # 80000cc4 <release>
    return -1;
    80001e46:	54fd                	li	s1,-1
    80001e48:	a899                	j	80001e9e <fork+0xfc>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e4a:	00002097          	auipc	ra,0x2
    80001e4e:	680080e7          	jalr	1664(ra) # 800044ca <filedup>
    80001e52:	009987b3          	add	a5,s3,s1
    80001e56:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e58:	04a1                	addi	s1,s1,8
    80001e5a:	01448763          	beq	s1,s4,80001e68 <fork+0xc6>
    if(p->ofile[i])
    80001e5e:	009907b3          	add	a5,s2,s1
    80001e62:	6388                	ld	a0,0(a5)
    80001e64:	f17d                	bnez	a0,80001e4a <fork+0xa8>
    80001e66:	bfcd                	j	80001e58 <fork+0xb6>
  np->cwd = idup(p->cwd);
    80001e68:	15093503          	ld	a0,336(s2)
    80001e6c:	00001097          	auipc	ra,0x1
    80001e70:	7e4080e7          	jalr	2020(ra) # 80003650 <idup>
    80001e74:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e78:	4641                	li	a2,16
    80001e7a:	15890593          	addi	a1,s2,344
    80001e7e:	15898513          	addi	a0,s3,344
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	fe0080e7          	jalr	-32(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80001e8a:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001e8e:	4789                	li	a5,2
    80001e90:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e94:	854e                	mv	a0,s3
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	e2e080e7          	jalr	-466(ra) # 80000cc4 <release>
}
    80001e9e:	8526                	mv	a0,s1
    80001ea0:	70a2                	ld	ra,40(sp)
    80001ea2:	7402                	ld	s0,32(sp)
    80001ea4:	64e2                	ld	s1,24(sp)
    80001ea6:	6942                	ld	s2,16(sp)
    80001ea8:	69a2                	ld	s3,8(sp)
    80001eaa:	6a02                	ld	s4,0(sp)
    80001eac:	6145                	addi	sp,sp,48
    80001eae:	8082                	ret
    return -1;
    80001eb0:	54fd                	li	s1,-1
    80001eb2:	b7f5                	j	80001e9e <fork+0xfc>

0000000080001eb4 <reparent>:
{
    80001eb4:	7179                	addi	sp,sp,-48
    80001eb6:	f406                	sd	ra,40(sp)
    80001eb8:	f022                	sd	s0,32(sp)
    80001eba:	ec26                	sd	s1,24(sp)
    80001ebc:	e84a                	sd	s2,16(sp)
    80001ebe:	e44e                	sd	s3,8(sp)
    80001ec0:	e052                	sd	s4,0(sp)
    80001ec2:	1800                	addi	s0,sp,48
    80001ec4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ec6:	00010497          	auipc	s1,0x10
    80001eca:	ea248493          	addi	s1,s1,-350 # 80011d68 <proc>
      pp->parent = initproc;
    80001ece:	00007a17          	auipc	s4,0x7
    80001ed2:	14aa0a13          	addi	s4,s4,330 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ed6:	00016997          	auipc	s3,0x16
    80001eda:	a9298993          	addi	s3,s3,-1390 # 80017968 <tickslock>
    80001ede:	a029                	j	80001ee8 <reparent+0x34>
    80001ee0:	17048493          	addi	s1,s1,368
    80001ee4:	03348363          	beq	s1,s3,80001f0a <reparent+0x56>
    if(pp->parent == p){
    80001ee8:	709c                	ld	a5,32(s1)
    80001eea:	ff279be3          	bne	a5,s2,80001ee0 <reparent+0x2c>
      acquire(&pp->lock);
    80001eee:	8526                	mv	a0,s1
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	d20080e7          	jalr	-736(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    80001ef8:	000a3783          	ld	a5,0(s4)
    80001efc:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	dc4080e7          	jalr	-572(ra) # 80000cc4 <release>
    80001f08:	bfe1                	j	80001ee0 <reparent+0x2c>
}
    80001f0a:	70a2                	ld	ra,40(sp)
    80001f0c:	7402                	ld	s0,32(sp)
    80001f0e:	64e2                	ld	s1,24(sp)
    80001f10:	6942                	ld	s2,16(sp)
    80001f12:	69a2                	ld	s3,8(sp)
    80001f14:	6a02                	ld	s4,0(sp)
    80001f16:	6145                	addi	sp,sp,48
    80001f18:	8082                	ret

0000000080001f1a <scheduler>:
{
    80001f1a:	715d                	addi	sp,sp,-80
    80001f1c:	e486                	sd	ra,72(sp)
    80001f1e:	e0a2                	sd	s0,64(sp)
    80001f20:	fc26                	sd	s1,56(sp)
    80001f22:	f84a                	sd	s2,48(sp)
    80001f24:	f44e                	sd	s3,40(sp)
    80001f26:	f052                	sd	s4,32(sp)
    80001f28:	ec56                	sd	s5,24(sp)
    80001f2a:	e85a                	sd	s6,16(sp)
    80001f2c:	e45e                	sd	s7,8(sp)
    80001f2e:	e062                	sd	s8,0(sp)
    80001f30:	0880                	addi	s0,sp,80
    80001f32:	8792                	mv	a5,tp
  int id = r_tp();
    80001f34:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f36:	00779b13          	slli	s6,a5,0x7
    80001f3a:	00010717          	auipc	a4,0x10
    80001f3e:	a1670713          	addi	a4,a4,-1514 # 80011950 <pid_lock>
    80001f42:	975a                	add	a4,a4,s6
    80001f44:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f48:	00010717          	auipc	a4,0x10
    80001f4c:	a2870713          	addi	a4,a4,-1496 # 80011970 <cpus+0x8>
    80001f50:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f52:	4c0d                	li	s8,3
        c->proc = p;
    80001f54:	079e                	slli	a5,a5,0x7
    80001f56:	00010a17          	auipc	s4,0x10
    80001f5a:	9faa0a13          	addi	s4,s4,-1542 # 80011950 <pid_lock>
    80001f5e:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f60:	00016997          	auipc	s3,0x16
    80001f64:	a0898993          	addi	s3,s3,-1528 # 80017968 <tickslock>
        found = 1;
    80001f68:	4b85                	li	s7,1
    80001f6a:	a899                	j	80001fc0 <scheduler+0xa6>
        p->state = RUNNING;
    80001f6c:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001f70:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001f74:	06048593          	addi	a1,s1,96
    80001f78:	855a                	mv	a0,s6
    80001f7a:	00000097          	auipc	ra,0x0
    80001f7e:	638080e7          	jalr	1592(ra) # 800025b2 <swtch>
        c->proc = 0;
    80001f82:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001f86:	8ade                	mv	s5,s7
      release(&p->lock);
    80001f88:	8526                	mv	a0,s1
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	d3a080e7          	jalr	-710(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f92:	17048493          	addi	s1,s1,368
    80001f96:	01348b63          	beq	s1,s3,80001fac <scheduler+0x92>
      acquire(&p->lock);
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	c74080e7          	jalr	-908(ra) # 80000c10 <acquire>
      if(p->state == RUNNABLE) {
    80001fa4:	4c9c                	lw	a5,24(s1)
    80001fa6:	ff2791e3          	bne	a5,s2,80001f88 <scheduler+0x6e>
    80001faa:	b7c9                	j	80001f6c <scheduler+0x52>
    if(found == 0) {
    80001fac:	000a9a63          	bnez	s5,80001fc0 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fb4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fb8:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001fbc:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fc0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fc4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fc8:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001fcc:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fce:	00010497          	auipc	s1,0x10
    80001fd2:	d9a48493          	addi	s1,s1,-614 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80001fd6:	4909                	li	s2,2
    80001fd8:	b7c9                	j	80001f9a <scheduler+0x80>

0000000080001fda <sched>:
{
    80001fda:	7179                	addi	sp,sp,-48
    80001fdc:	f406                	sd	ra,40(sp)
    80001fde:	f022                	sd	s0,32(sp)
    80001fe0:	ec26                	sd	s1,24(sp)
    80001fe2:	e84a                	sd	s2,16(sp)
    80001fe4:	e44e                	sd	s3,8(sp)
    80001fe6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fe8:	00000097          	auipc	ra,0x0
    80001fec:	9f6080e7          	jalr	-1546(ra) # 800019de <myproc>
    80001ff0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	ba4080e7          	jalr	-1116(ra) # 80000b96 <holding>
    80001ffa:	c93d                	beqz	a0,80002070 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ffc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ffe:	2781                	sext.w	a5,a5
    80002000:	079e                	slli	a5,a5,0x7
    80002002:	00010717          	auipc	a4,0x10
    80002006:	94e70713          	addi	a4,a4,-1714 # 80011950 <pid_lock>
    8000200a:	97ba                	add	a5,a5,a4
    8000200c:	0907a703          	lw	a4,144(a5)
    80002010:	4785                	li	a5,1
    80002012:	06f71763          	bne	a4,a5,80002080 <sched+0xa6>
  if(p->state == RUNNING)
    80002016:	4c98                	lw	a4,24(s1)
    80002018:	478d                	li	a5,3
    8000201a:	06f70b63          	beq	a4,a5,80002090 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002022:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002024:	efb5                	bnez	a5,800020a0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002026:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002028:	00010917          	auipc	s2,0x10
    8000202c:	92890913          	addi	s2,s2,-1752 # 80011950 <pid_lock>
    80002030:	2781                	sext.w	a5,a5
    80002032:	079e                	slli	a5,a5,0x7
    80002034:	97ca                	add	a5,a5,s2
    80002036:	0947a983          	lw	s3,148(a5)
    8000203a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000203c:	2781                	sext.w	a5,a5
    8000203e:	079e                	slli	a5,a5,0x7
    80002040:	00010597          	auipc	a1,0x10
    80002044:	93058593          	addi	a1,a1,-1744 # 80011970 <cpus+0x8>
    80002048:	95be                	add	a1,a1,a5
    8000204a:	06048513          	addi	a0,s1,96
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	564080e7          	jalr	1380(ra) # 800025b2 <swtch>
    80002056:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002058:	2781                	sext.w	a5,a5
    8000205a:	079e                	slli	a5,a5,0x7
    8000205c:	97ca                	add	a5,a5,s2
    8000205e:	0937aa23          	sw	s3,148(a5)
}
    80002062:	70a2                	ld	ra,40(sp)
    80002064:	7402                	ld	s0,32(sp)
    80002066:	64e2                	ld	s1,24(sp)
    80002068:	6942                	ld	s2,16(sp)
    8000206a:	69a2                	ld	s3,8(sp)
    8000206c:	6145                	addi	sp,sp,48
    8000206e:	8082                	ret
    panic("sched p->lock");
    80002070:	00006517          	auipc	a0,0x6
    80002074:	19050513          	addi	a0,a0,400 # 80008200 <digits+0x1c0>
    80002078:	ffffe097          	auipc	ra,0xffffe
    8000207c:	4d0080e7          	jalr	1232(ra) # 80000548 <panic>
    panic("sched locks");
    80002080:	00006517          	auipc	a0,0x6
    80002084:	19050513          	addi	a0,a0,400 # 80008210 <digits+0x1d0>
    80002088:	ffffe097          	auipc	ra,0xffffe
    8000208c:	4c0080e7          	jalr	1216(ra) # 80000548 <panic>
    panic("sched running");
    80002090:	00006517          	auipc	a0,0x6
    80002094:	19050513          	addi	a0,a0,400 # 80008220 <digits+0x1e0>
    80002098:	ffffe097          	auipc	ra,0xffffe
    8000209c:	4b0080e7          	jalr	1200(ra) # 80000548 <panic>
    panic("sched interruptible");
    800020a0:	00006517          	auipc	a0,0x6
    800020a4:	19050513          	addi	a0,a0,400 # 80008230 <digits+0x1f0>
    800020a8:	ffffe097          	auipc	ra,0xffffe
    800020ac:	4a0080e7          	jalr	1184(ra) # 80000548 <panic>

00000000800020b0 <exit>:
{
    800020b0:	7179                	addi	sp,sp,-48
    800020b2:	f406                	sd	ra,40(sp)
    800020b4:	f022                	sd	s0,32(sp)
    800020b6:	ec26                	sd	s1,24(sp)
    800020b8:	e84a                	sd	s2,16(sp)
    800020ba:	e44e                	sd	s3,8(sp)
    800020bc:	e052                	sd	s4,0(sp)
    800020be:	1800                	addi	s0,sp,48
    800020c0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020c2:	00000097          	auipc	ra,0x0
    800020c6:	91c080e7          	jalr	-1764(ra) # 800019de <myproc>
    800020ca:	89aa                	mv	s3,a0
  if(p == initproc)
    800020cc:	00007797          	auipc	a5,0x7
    800020d0:	f4c7b783          	ld	a5,-180(a5) # 80009018 <initproc>
    800020d4:	0d050493          	addi	s1,a0,208
    800020d8:	15050913          	addi	s2,a0,336
    800020dc:	02a79363          	bne	a5,a0,80002102 <exit+0x52>
    panic("init exiting");
    800020e0:	00006517          	auipc	a0,0x6
    800020e4:	16850513          	addi	a0,a0,360 # 80008248 <digits+0x208>
    800020e8:	ffffe097          	auipc	ra,0xffffe
    800020ec:	460080e7          	jalr	1120(ra) # 80000548 <panic>
      fileclose(f);
    800020f0:	00002097          	auipc	ra,0x2
    800020f4:	42c080e7          	jalr	1068(ra) # 8000451c <fileclose>
      p->ofile[fd] = 0;
    800020f8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800020fc:	04a1                	addi	s1,s1,8
    800020fe:	01248563          	beq	s1,s2,80002108 <exit+0x58>
    if(p->ofile[fd]){
    80002102:	6088                	ld	a0,0(s1)
    80002104:	f575                	bnez	a0,800020f0 <exit+0x40>
    80002106:	bfdd                	j	800020fc <exit+0x4c>
  begin_op();
    80002108:	00002097          	auipc	ra,0x2
    8000210c:	f42080e7          	jalr	-190(ra) # 8000404a <begin_op>
  iput(p->cwd);
    80002110:	1509b503          	ld	a0,336(s3)
    80002114:	00001097          	auipc	ra,0x1
    80002118:	734080e7          	jalr	1844(ra) # 80003848 <iput>
  end_op();
    8000211c:	00002097          	auipc	ra,0x2
    80002120:	fae080e7          	jalr	-82(ra) # 800040ca <end_op>
  p->cwd = 0;
    80002124:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002128:	00007497          	auipc	s1,0x7
    8000212c:	ef048493          	addi	s1,s1,-272 # 80009018 <initproc>
    80002130:	6088                	ld	a0,0(s1)
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	ade080e7          	jalr	-1314(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    8000213a:	6088                	ld	a0,0(s1)
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	762080e7          	jalr	1890(ra) # 8000189e <wakeup1>
  release(&initproc->lock);
    80002144:	6088                	ld	a0,0(s1)
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	b7e080e7          	jalr	-1154(ra) # 80000cc4 <release>
  acquire(&p->lock);
    8000214e:	854e                	mv	a0,s3
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	ac0080e7          	jalr	-1344(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    80002158:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000215c:	854e                	mv	a0,s3
    8000215e:	fffff097          	auipc	ra,0xfffff
    80002162:	b66080e7          	jalr	-1178(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    80002166:	8526                	mv	a0,s1
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	aa8080e7          	jalr	-1368(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    80002170:	854e                	mv	a0,s3
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	a9e080e7          	jalr	-1378(ra) # 80000c10 <acquire>
  reparent(p);
    8000217a:	854e                	mv	a0,s3
    8000217c:	00000097          	auipc	ra,0x0
    80002180:	d38080e7          	jalr	-712(ra) # 80001eb4 <reparent>
  wakeup1(original_parent);
    80002184:	8526                	mv	a0,s1
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	718080e7          	jalr	1816(ra) # 8000189e <wakeup1>
  p->xstate = status;
    8000218e:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002192:	4791                	li	a5,4
    80002194:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002198:	8526                	mv	a0,s1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	b2a080e7          	jalr	-1238(ra) # 80000cc4 <release>
  sched();
    800021a2:	00000097          	auipc	ra,0x0
    800021a6:	e38080e7          	jalr	-456(ra) # 80001fda <sched>
  panic("zombie exit");
    800021aa:	00006517          	auipc	a0,0x6
    800021ae:	0ae50513          	addi	a0,a0,174 # 80008258 <digits+0x218>
    800021b2:	ffffe097          	auipc	ra,0xffffe
    800021b6:	396080e7          	jalr	918(ra) # 80000548 <panic>

00000000800021ba <yield>:
{
    800021ba:	1101                	addi	sp,sp,-32
    800021bc:	ec06                	sd	ra,24(sp)
    800021be:	e822                	sd	s0,16(sp)
    800021c0:	e426                	sd	s1,8(sp)
    800021c2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021c4:	00000097          	auipc	ra,0x0
    800021c8:	81a080e7          	jalr	-2022(ra) # 800019de <myproc>
    800021cc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	a42080e7          	jalr	-1470(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    800021d6:	4789                	li	a5,2
    800021d8:	cc9c                	sw	a5,24(s1)
  sched();
    800021da:	00000097          	auipc	ra,0x0
    800021de:	e00080e7          	jalr	-512(ra) # 80001fda <sched>
  release(&p->lock);
    800021e2:	8526                	mv	a0,s1
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	ae0080e7          	jalr	-1312(ra) # 80000cc4 <release>
}
    800021ec:	60e2                	ld	ra,24(sp)
    800021ee:	6442                	ld	s0,16(sp)
    800021f0:	64a2                	ld	s1,8(sp)
    800021f2:	6105                	addi	sp,sp,32
    800021f4:	8082                	ret

00000000800021f6 <sleep>:
{
    800021f6:	7179                	addi	sp,sp,-48
    800021f8:	f406                	sd	ra,40(sp)
    800021fa:	f022                	sd	s0,32(sp)
    800021fc:	ec26                	sd	s1,24(sp)
    800021fe:	e84a                	sd	s2,16(sp)
    80002200:	e44e                	sd	s3,8(sp)
    80002202:	1800                	addi	s0,sp,48
    80002204:	89aa                	mv	s3,a0
    80002206:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	7d6080e7          	jalr	2006(ra) # 800019de <myproc>
    80002210:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002212:	05250663          	beq	a0,s2,8000225e <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	9fa080e7          	jalr	-1542(ra) # 80000c10 <acquire>
    release(lk);
    8000221e:	854a                	mv	a0,s2
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	aa4080e7          	jalr	-1372(ra) # 80000cc4 <release>
  p->chan = chan;
    80002228:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000222c:	4785                	li	a5,1
    8000222e:	cc9c                	sw	a5,24(s1)
  sched();
    80002230:	00000097          	auipc	ra,0x0
    80002234:	daa080e7          	jalr	-598(ra) # 80001fda <sched>
  p->chan = 0;
    80002238:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a86080e7          	jalr	-1402(ra) # 80000cc4 <release>
    acquire(lk);
    80002246:	854a                	mv	a0,s2
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	9c8080e7          	jalr	-1592(ra) # 80000c10 <acquire>
}
    80002250:	70a2                	ld	ra,40(sp)
    80002252:	7402                	ld	s0,32(sp)
    80002254:	64e2                	ld	s1,24(sp)
    80002256:	6942                	ld	s2,16(sp)
    80002258:	69a2                	ld	s3,8(sp)
    8000225a:	6145                	addi	sp,sp,48
    8000225c:	8082                	ret
  p->chan = chan;
    8000225e:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002262:	4785                	li	a5,1
    80002264:	cd1c                	sw	a5,24(a0)
  sched();
    80002266:	00000097          	auipc	ra,0x0
    8000226a:	d74080e7          	jalr	-652(ra) # 80001fda <sched>
  p->chan = 0;
    8000226e:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002272:	bff9                	j	80002250 <sleep+0x5a>

0000000080002274 <wait>:
{
    80002274:	715d                	addi	sp,sp,-80
    80002276:	e486                	sd	ra,72(sp)
    80002278:	e0a2                	sd	s0,64(sp)
    8000227a:	fc26                	sd	s1,56(sp)
    8000227c:	f84a                	sd	s2,48(sp)
    8000227e:	f44e                	sd	s3,40(sp)
    80002280:	f052                	sd	s4,32(sp)
    80002282:	ec56                	sd	s5,24(sp)
    80002284:	e85a                	sd	s6,16(sp)
    80002286:	e45e                	sd	s7,8(sp)
    80002288:	e062                	sd	s8,0(sp)
    8000228a:	0880                	addi	s0,sp,80
    8000228c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	750080e7          	jalr	1872(ra) # 800019de <myproc>
    80002296:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002298:	8c2a                	mv	s8,a0
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	976080e7          	jalr	-1674(ra) # 80000c10 <acquire>
    havekids = 0;
    800022a2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022a4:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022a6:	00015997          	auipc	s3,0x15
    800022aa:	6c298993          	addi	s3,s3,1730 # 80017968 <tickslock>
        havekids = 1;
    800022ae:	4a85                	li	s5,1
    havekids = 0;
    800022b0:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022b2:	00010497          	auipc	s1,0x10
    800022b6:	ab648493          	addi	s1,s1,-1354 # 80011d68 <proc>
    800022ba:	a08d                	j	8000231c <wait+0xa8>
          pid = np->pid;
    800022bc:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022c0:	000b0e63          	beqz	s6,800022dc <wait+0x68>
    800022c4:	4691                	li	a3,4
    800022c6:	03448613          	addi	a2,s1,52
    800022ca:	85da                	mv	a1,s6
    800022cc:	05093503          	ld	a0,80(s2)
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	402080e7          	jalr	1026(ra) # 800016d2 <copyout>
    800022d8:	02054263          	bltz	a0,800022fc <wait+0x88>
          freeproc(np);
    800022dc:	8526                	mv	a0,s1
    800022de:	00000097          	auipc	ra,0x0
    800022e2:	8b2080e7          	jalr	-1870(ra) # 80001b90 <freeproc>
          release(&np->lock);
    800022e6:	8526                	mv	a0,s1
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	9dc080e7          	jalr	-1572(ra) # 80000cc4 <release>
          release(&p->lock);
    800022f0:	854a                	mv	a0,s2
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	9d2080e7          	jalr	-1582(ra) # 80000cc4 <release>
          return pid;
    800022fa:	a8a9                	j	80002354 <wait+0xe0>
            release(&np->lock);
    800022fc:	8526                	mv	a0,s1
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	9c6080e7          	jalr	-1594(ra) # 80000cc4 <release>
            release(&p->lock);
    80002306:	854a                	mv	a0,s2
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	9bc080e7          	jalr	-1604(ra) # 80000cc4 <release>
            return -1;
    80002310:	59fd                	li	s3,-1
    80002312:	a089                	j	80002354 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002314:	17048493          	addi	s1,s1,368
    80002318:	03348463          	beq	s1,s3,80002340 <wait+0xcc>
      if(np->parent == p){
    8000231c:	709c                	ld	a5,32(s1)
    8000231e:	ff279be3          	bne	a5,s2,80002314 <wait+0xa0>
        acquire(&np->lock);
    80002322:	8526                	mv	a0,s1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	8ec080e7          	jalr	-1812(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    8000232c:	4c9c                	lw	a5,24(s1)
    8000232e:	f94787e3          	beq	a5,s4,800022bc <wait+0x48>
        release(&np->lock);
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	990080e7          	jalr	-1648(ra) # 80000cc4 <release>
        havekids = 1;
    8000233c:	8756                	mv	a4,s5
    8000233e:	bfd9                	j	80002314 <wait+0xa0>
    if(!havekids || p->killed){
    80002340:	c701                	beqz	a4,80002348 <wait+0xd4>
    80002342:	03092783          	lw	a5,48(s2)
    80002346:	c785                	beqz	a5,8000236e <wait+0xfa>
      release(&p->lock);
    80002348:	854a                	mv	a0,s2
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	97a080e7          	jalr	-1670(ra) # 80000cc4 <release>
      return -1;
    80002352:	59fd                	li	s3,-1
}
    80002354:	854e                	mv	a0,s3
    80002356:	60a6                	ld	ra,72(sp)
    80002358:	6406                	ld	s0,64(sp)
    8000235a:	74e2                	ld	s1,56(sp)
    8000235c:	7942                	ld	s2,48(sp)
    8000235e:	79a2                	ld	s3,40(sp)
    80002360:	7a02                	ld	s4,32(sp)
    80002362:	6ae2                	ld	s5,24(sp)
    80002364:	6b42                	ld	s6,16(sp)
    80002366:	6ba2                	ld	s7,8(sp)
    80002368:	6c02                	ld	s8,0(sp)
    8000236a:	6161                	addi	sp,sp,80
    8000236c:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000236e:	85e2                	mv	a1,s8
    80002370:	854a                	mv	a0,s2
    80002372:	00000097          	auipc	ra,0x0
    80002376:	e84080e7          	jalr	-380(ra) # 800021f6 <sleep>
    havekids = 0;
    8000237a:	bf1d                	j	800022b0 <wait+0x3c>

000000008000237c <wakeup>:
{
    8000237c:	7139                	addi	sp,sp,-64
    8000237e:	fc06                	sd	ra,56(sp)
    80002380:	f822                	sd	s0,48(sp)
    80002382:	f426                	sd	s1,40(sp)
    80002384:	f04a                	sd	s2,32(sp)
    80002386:	ec4e                	sd	s3,24(sp)
    80002388:	e852                	sd	s4,16(sp)
    8000238a:	e456                	sd	s5,8(sp)
    8000238c:	0080                	addi	s0,sp,64
    8000238e:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002390:	00010497          	auipc	s1,0x10
    80002394:	9d848493          	addi	s1,s1,-1576 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002398:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000239a:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000239c:	00015917          	auipc	s2,0x15
    800023a0:	5cc90913          	addi	s2,s2,1484 # 80017968 <tickslock>
    800023a4:	a821                	j	800023bc <wakeup+0x40>
      p->state = RUNNABLE;
    800023a6:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023aa:	8526                	mv	a0,s1
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	918080e7          	jalr	-1768(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023b4:	17048493          	addi	s1,s1,368
    800023b8:	01248e63          	beq	s1,s2,800023d4 <wakeup+0x58>
    acquire(&p->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	852080e7          	jalr	-1966(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800023c6:	4c9c                	lw	a5,24(s1)
    800023c8:	ff3791e3          	bne	a5,s3,800023aa <wakeup+0x2e>
    800023cc:	749c                	ld	a5,40(s1)
    800023ce:	fd479ee3          	bne	a5,s4,800023aa <wakeup+0x2e>
    800023d2:	bfd1                	j	800023a6 <wakeup+0x2a>
}
    800023d4:	70e2                	ld	ra,56(sp)
    800023d6:	7442                	ld	s0,48(sp)
    800023d8:	74a2                	ld	s1,40(sp)
    800023da:	7902                	ld	s2,32(sp)
    800023dc:	69e2                	ld	s3,24(sp)
    800023de:	6a42                	ld	s4,16(sp)
    800023e0:	6aa2                	ld	s5,8(sp)
    800023e2:	6121                	addi	sp,sp,64
    800023e4:	8082                	ret

00000000800023e6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023e6:	7179                	addi	sp,sp,-48
    800023e8:	f406                	sd	ra,40(sp)
    800023ea:	f022                	sd	s0,32(sp)
    800023ec:	ec26                	sd	s1,24(sp)
    800023ee:	e84a                	sd	s2,16(sp)
    800023f0:	e44e                	sd	s3,8(sp)
    800023f2:	1800                	addi	s0,sp,48
    800023f4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023f6:	00010497          	auipc	s1,0x10
    800023fa:	97248493          	addi	s1,s1,-1678 # 80011d68 <proc>
    800023fe:	00015997          	auipc	s3,0x15
    80002402:	56a98993          	addi	s3,s3,1386 # 80017968 <tickslock>
    acquire(&p->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	808080e7          	jalr	-2040(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    80002410:	5c9c                	lw	a5,56(s1)
    80002412:	01278d63          	beq	a5,s2,8000242c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	8ac080e7          	jalr	-1876(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002420:	17048493          	addi	s1,s1,368
    80002424:	ff3491e3          	bne	s1,s3,80002406 <kill+0x20>
  }
  return -1;
    80002428:	557d                	li	a0,-1
    8000242a:	a829                	j	80002444 <kill+0x5e>
      p->killed = 1;
    8000242c:	4785                	li	a5,1
    8000242e:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002430:	4c98                	lw	a4,24(s1)
    80002432:	4785                	li	a5,1
    80002434:	00f70f63          	beq	a4,a5,80002452 <kill+0x6c>
      release(&p->lock);
    80002438:	8526                	mv	a0,s1
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	88a080e7          	jalr	-1910(ra) # 80000cc4 <release>
      return 0;
    80002442:	4501                	li	a0,0
}
    80002444:	70a2                	ld	ra,40(sp)
    80002446:	7402                	ld	s0,32(sp)
    80002448:	64e2                	ld	s1,24(sp)
    8000244a:	6942                	ld	s2,16(sp)
    8000244c:	69a2                	ld	s3,8(sp)
    8000244e:	6145                	addi	sp,sp,48
    80002450:	8082                	ret
        p->state = RUNNABLE;
    80002452:	4789                	li	a5,2
    80002454:	cc9c                	sw	a5,24(s1)
    80002456:	b7cd                	j	80002438 <kill+0x52>

0000000080002458 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002458:	7179                	addi	sp,sp,-48
    8000245a:	f406                	sd	ra,40(sp)
    8000245c:	f022                	sd	s0,32(sp)
    8000245e:	ec26                	sd	s1,24(sp)
    80002460:	e84a                	sd	s2,16(sp)
    80002462:	e44e                	sd	s3,8(sp)
    80002464:	e052                	sd	s4,0(sp)
    80002466:	1800                	addi	s0,sp,48
    80002468:	84aa                	mv	s1,a0
    8000246a:	892e                	mv	s2,a1
    8000246c:	89b2                	mv	s3,a2
    8000246e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	56e080e7          	jalr	1390(ra) # 800019de <myproc>
  if(user_dst){
    80002478:	c08d                	beqz	s1,8000249a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000247a:	86d2                	mv	a3,s4
    8000247c:	864e                	mv	a2,s3
    8000247e:	85ca                	mv	a1,s2
    80002480:	6928                	ld	a0,80(a0)
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	250080e7          	jalr	592(ra) # 800016d2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248a:	70a2                	ld	ra,40(sp)
    8000248c:	7402                	ld	s0,32(sp)
    8000248e:	64e2                	ld	s1,24(sp)
    80002490:	6942                	ld	s2,16(sp)
    80002492:	69a2                	ld	s3,8(sp)
    80002494:	6a02                	ld	s4,0(sp)
    80002496:	6145                	addi	sp,sp,48
    80002498:	8082                	ret
    memmove((char *)dst, src, len);
    8000249a:	000a061b          	sext.w	a2,s4
    8000249e:	85ce                	mv	a1,s3
    800024a0:	854a                	mv	a0,s2
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	8ca080e7          	jalr	-1846(ra) # 80000d6c <memmove>
    return 0;
    800024aa:	8526                	mv	a0,s1
    800024ac:	bff9                	j	8000248a <either_copyout+0x32>

00000000800024ae <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024ae:	7179                	addi	sp,sp,-48
    800024b0:	f406                	sd	ra,40(sp)
    800024b2:	f022                	sd	s0,32(sp)
    800024b4:	ec26                	sd	s1,24(sp)
    800024b6:	e84a                	sd	s2,16(sp)
    800024b8:	e44e                	sd	s3,8(sp)
    800024ba:	e052                	sd	s4,0(sp)
    800024bc:	1800                	addi	s0,sp,48
    800024be:	892a                	mv	s2,a0
    800024c0:	84ae                	mv	s1,a1
    800024c2:	89b2                	mv	s3,a2
    800024c4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	518080e7          	jalr	1304(ra) # 800019de <myproc>
  if(user_src){
    800024ce:	c08d                	beqz	s1,800024f0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d0:	86d2                	mv	a3,s4
    800024d2:	864e                	mv	a2,s3
    800024d4:	85ca                	mv	a1,s2
    800024d6:	6928                	ld	a0,80(a0)
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	286080e7          	jalr	646(ra) # 8000175e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e0:	70a2                	ld	ra,40(sp)
    800024e2:	7402                	ld	s0,32(sp)
    800024e4:	64e2                	ld	s1,24(sp)
    800024e6:	6942                	ld	s2,16(sp)
    800024e8:	69a2                	ld	s3,8(sp)
    800024ea:	6a02                	ld	s4,0(sp)
    800024ec:	6145                	addi	sp,sp,48
    800024ee:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f0:	000a061b          	sext.w	a2,s4
    800024f4:	85ce                	mv	a1,s3
    800024f6:	854a                	mv	a0,s2
    800024f8:	fffff097          	auipc	ra,0xfffff
    800024fc:	874080e7          	jalr	-1932(ra) # 80000d6c <memmove>
    return 0;
    80002500:	8526                	mv	a0,s1
    80002502:	bff9                	j	800024e0 <either_copyin+0x32>

0000000080002504 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002504:	715d                	addi	sp,sp,-80
    80002506:	e486                	sd	ra,72(sp)
    80002508:	e0a2                	sd	s0,64(sp)
    8000250a:	fc26                	sd	s1,56(sp)
    8000250c:	f84a                	sd	s2,48(sp)
    8000250e:	f44e                	sd	s3,40(sp)
    80002510:	f052                	sd	s4,32(sp)
    80002512:	ec56                	sd	s5,24(sp)
    80002514:	e85a                	sd	s6,16(sp)
    80002516:	e45e                	sd	s7,8(sp)
    80002518:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000251a:	00006517          	auipc	a0,0x6
    8000251e:	bae50513          	addi	a0,a0,-1106 # 800080c8 <digits+0x88>
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	070080e7          	jalr	112(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252a:	00010497          	auipc	s1,0x10
    8000252e:	99648493          	addi	s1,s1,-1642 # 80011ec0 <proc+0x158>
    80002532:	00015917          	auipc	s2,0x15
    80002536:	58e90913          	addi	s2,s2,1422 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253a:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000253c:	00006997          	auipc	s3,0x6
    80002540:	d2c98993          	addi	s3,s3,-724 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002544:	00006a97          	auipc	s5,0x6
    80002548:	d2ca8a93          	addi	s5,s5,-724 # 80008270 <digits+0x230>
    printf("\n");
    8000254c:	00006a17          	auipc	s4,0x6
    80002550:	b7ca0a13          	addi	s4,s4,-1156 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002554:	00006b97          	auipc	s7,0x6
    80002558:	d54b8b93          	addi	s7,s7,-684 # 800082a8 <states.1703>
    8000255c:	a00d                	j	8000257e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000255e:	ee06a583          	lw	a1,-288(a3)
    80002562:	8556                	mv	a0,s5
    80002564:	ffffe097          	auipc	ra,0xffffe
    80002568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
    printf("\n");
    8000256c:	8552                	mv	a0,s4
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002576:	17048493          	addi	s1,s1,368
    8000257a:	03248163          	beq	s1,s2,8000259c <procdump+0x98>
    if(p->state == UNUSED)
    8000257e:	86a6                	mv	a3,s1
    80002580:	ec04a783          	lw	a5,-320(s1)
    80002584:	dbed                	beqz	a5,80002576 <procdump+0x72>
      state = "???";
    80002586:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002588:	fcfb6be3          	bltu	s6,a5,8000255e <procdump+0x5a>
    8000258c:	1782                	slli	a5,a5,0x20
    8000258e:	9381                	srli	a5,a5,0x20
    80002590:	078e                	slli	a5,a5,0x3
    80002592:	97de                	add	a5,a5,s7
    80002594:	6390                	ld	a2,0(a5)
    80002596:	f661                	bnez	a2,8000255e <procdump+0x5a>
      state = "???";
    80002598:	864e                	mv	a2,s3
    8000259a:	b7d1                	j	8000255e <procdump+0x5a>
  }
}
    8000259c:	60a6                	ld	ra,72(sp)
    8000259e:	6406                	ld	s0,64(sp)
    800025a0:	74e2                	ld	s1,56(sp)
    800025a2:	7942                	ld	s2,48(sp)
    800025a4:	79a2                	ld	s3,40(sp)
    800025a6:	7a02                	ld	s4,32(sp)
    800025a8:	6ae2                	ld	s5,24(sp)
    800025aa:	6b42                	ld	s6,16(sp)
    800025ac:	6ba2                	ld	s7,8(sp)
    800025ae:	6161                	addi	sp,sp,80
    800025b0:	8082                	ret

00000000800025b2 <swtch>:
    800025b2:	00153023          	sd	ra,0(a0)
    800025b6:	00253423          	sd	sp,8(a0)
    800025ba:	e900                	sd	s0,16(a0)
    800025bc:	ed04                	sd	s1,24(a0)
    800025be:	03253023          	sd	s2,32(a0)
    800025c2:	03353423          	sd	s3,40(a0)
    800025c6:	03453823          	sd	s4,48(a0)
    800025ca:	03553c23          	sd	s5,56(a0)
    800025ce:	05653023          	sd	s6,64(a0)
    800025d2:	05753423          	sd	s7,72(a0)
    800025d6:	05853823          	sd	s8,80(a0)
    800025da:	05953c23          	sd	s9,88(a0)
    800025de:	07a53023          	sd	s10,96(a0)
    800025e2:	07b53423          	sd	s11,104(a0)
    800025e6:	0005b083          	ld	ra,0(a1)
    800025ea:	0085b103          	ld	sp,8(a1)
    800025ee:	6980                	ld	s0,16(a1)
    800025f0:	6d84                	ld	s1,24(a1)
    800025f2:	0205b903          	ld	s2,32(a1)
    800025f6:	0285b983          	ld	s3,40(a1)
    800025fa:	0305ba03          	ld	s4,48(a1)
    800025fe:	0385ba83          	ld	s5,56(a1)
    80002602:	0405bb03          	ld	s6,64(a1)
    80002606:	0485bb83          	ld	s7,72(a1)
    8000260a:	0505bc03          	ld	s8,80(a1)
    8000260e:	0585bc83          	ld	s9,88(a1)
    80002612:	0605bd03          	ld	s10,96(a1)
    80002616:	0685bd83          	ld	s11,104(a1)
    8000261a:	8082                	ret

000000008000261c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000261c:	1141                	addi	sp,sp,-16
    8000261e:	e406                	sd	ra,8(sp)
    80002620:	e022                	sd	s0,0(sp)
    80002622:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002624:	00006597          	auipc	a1,0x6
    80002628:	cac58593          	addi	a1,a1,-852 # 800082d0 <states.1703+0x28>
    8000262c:	00015517          	auipc	a0,0x15
    80002630:	33c50513          	addi	a0,a0,828 # 80017968 <tickslock>
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	54c080e7          	jalr	1356(ra) # 80000b80 <initlock>
}
    8000263c:	60a2                	ld	ra,8(sp)
    8000263e:	6402                	ld	s0,0(sp)
    80002640:	0141                	addi	sp,sp,16
    80002642:	8082                	ret

0000000080002644 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002644:	1141                	addi	sp,sp,-16
    80002646:	e422                	sd	s0,8(sp)
    80002648:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000264a:	00003797          	auipc	a5,0x3
    8000264e:	53678793          	addi	a5,a5,1334 # 80005b80 <kernelvec>
    80002652:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002656:	6422                	ld	s0,8(sp)
    80002658:	0141                	addi	sp,sp,16
    8000265a:	8082                	ret

000000008000265c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000265c:	1141                	addi	sp,sp,-16
    8000265e:	e406                	sd	ra,8(sp)
    80002660:	e022                	sd	s0,0(sp)
    80002662:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002664:	fffff097          	auipc	ra,0xfffff
    80002668:	37a080e7          	jalr	890(ra) # 800019de <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000266c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002670:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002672:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002676:	00005617          	auipc	a2,0x5
    8000267a:	98a60613          	addi	a2,a2,-1654 # 80007000 <_trampoline>
    8000267e:	00005697          	auipc	a3,0x5
    80002682:	98268693          	addi	a3,a3,-1662 # 80007000 <_trampoline>
    80002686:	8e91                	sub	a3,a3,a2
    80002688:	040007b7          	lui	a5,0x4000
    8000268c:	17fd                	addi	a5,a5,-1
    8000268e:	07b2                	slli	a5,a5,0xc
    80002690:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002692:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002696:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002698:	180026f3          	csrr	a3,satp
    8000269c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000269e:	6d38                	ld	a4,88(a0)
    800026a0:	6134                	ld	a3,64(a0)
    800026a2:	6585                	lui	a1,0x1
    800026a4:	96ae                	add	a3,a3,a1
    800026a6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026a8:	6d38                	ld	a4,88(a0)
    800026aa:	00000697          	auipc	a3,0x0
    800026ae:	13868693          	addi	a3,a3,312 # 800027e2 <usertrap>
    800026b2:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026b4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026b6:	8692                	mv	a3,tp
    800026b8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ba:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026be:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026c2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026ca:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026cc:	6f18                	ld	a4,24(a4)
    800026ce:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026d2:	692c                	ld	a1,80(a0)
    800026d4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026d6:	00005717          	auipc	a4,0x5
    800026da:	9ba70713          	addi	a4,a4,-1606 # 80007090 <userret>
    800026de:	8f11                	sub	a4,a4,a2
    800026e0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026e2:	577d                	li	a4,-1
    800026e4:	177e                	slli	a4,a4,0x3f
    800026e6:	8dd9                	or	a1,a1,a4
    800026e8:	02000537          	lui	a0,0x2000
    800026ec:	157d                	addi	a0,a0,-1
    800026ee:	0536                	slli	a0,a0,0xd
    800026f0:	9782                	jalr	a5
}
    800026f2:	60a2                	ld	ra,8(sp)
    800026f4:	6402                	ld	s0,0(sp)
    800026f6:	0141                	addi	sp,sp,16
    800026f8:	8082                	ret

00000000800026fa <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026fa:	1101                	addi	sp,sp,-32
    800026fc:	ec06                	sd	ra,24(sp)
    800026fe:	e822                	sd	s0,16(sp)
    80002700:	e426                	sd	s1,8(sp)
    80002702:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002704:	00015497          	auipc	s1,0x15
    80002708:	26448493          	addi	s1,s1,612 # 80017968 <tickslock>
    8000270c:	8526                	mv	a0,s1
    8000270e:	ffffe097          	auipc	ra,0xffffe
    80002712:	502080e7          	jalr	1282(ra) # 80000c10 <acquire>
  ticks++;
    80002716:	00007517          	auipc	a0,0x7
    8000271a:	90a50513          	addi	a0,a0,-1782 # 80009020 <ticks>
    8000271e:	411c                	lw	a5,0(a0)
    80002720:	2785                	addiw	a5,a5,1
    80002722:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002724:	00000097          	auipc	ra,0x0
    80002728:	c58080e7          	jalr	-936(ra) # 8000237c <wakeup>
  release(&tickslock);
    8000272c:	8526                	mv	a0,s1
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	596080e7          	jalr	1430(ra) # 80000cc4 <release>
}
    80002736:	60e2                	ld	ra,24(sp)
    80002738:	6442                	ld	s0,16(sp)
    8000273a:	64a2                	ld	s1,8(sp)
    8000273c:	6105                	addi	sp,sp,32
    8000273e:	8082                	ret

0000000080002740 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002740:	1101                	addi	sp,sp,-32
    80002742:	ec06                	sd	ra,24(sp)
    80002744:	e822                	sd	s0,16(sp)
    80002746:	e426                	sd	s1,8(sp)
    80002748:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000274a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000274e:	00074d63          	bltz	a4,80002768 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002752:	57fd                	li	a5,-1
    80002754:	17fe                	slli	a5,a5,0x3f
    80002756:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002758:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000275a:	06f70363          	beq	a4,a5,800027c0 <devintr+0x80>
  }
}
    8000275e:	60e2                	ld	ra,24(sp)
    80002760:	6442                	ld	s0,16(sp)
    80002762:	64a2                	ld	s1,8(sp)
    80002764:	6105                	addi	sp,sp,32
    80002766:	8082                	ret
     (scause & 0xff) == 9){
    80002768:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000276c:	46a5                	li	a3,9
    8000276e:	fed792e3          	bne	a5,a3,80002752 <devintr+0x12>
    int irq = plic_claim();
    80002772:	00003097          	auipc	ra,0x3
    80002776:	516080e7          	jalr	1302(ra) # 80005c88 <plic_claim>
    8000277a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000277c:	47a9                	li	a5,10
    8000277e:	02f50763          	beq	a0,a5,800027ac <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002782:	4785                	li	a5,1
    80002784:	02f50963          	beq	a0,a5,800027b6 <devintr+0x76>
    return 1;
    80002788:	4505                	li	a0,1
    } else if(irq){
    8000278a:	d8f1                	beqz	s1,8000275e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000278c:	85a6                	mv	a1,s1
    8000278e:	00006517          	auipc	a0,0x6
    80002792:	b4a50513          	addi	a0,a0,-1206 # 800082d8 <states.1703+0x30>
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	dfc080e7          	jalr	-516(ra) # 80000592 <printf>
      plic_complete(irq);
    8000279e:	8526                	mv	a0,s1
    800027a0:	00003097          	auipc	ra,0x3
    800027a4:	50c080e7          	jalr	1292(ra) # 80005cac <plic_complete>
    return 1;
    800027a8:	4505                	li	a0,1
    800027aa:	bf55                	j	8000275e <devintr+0x1e>
      uartintr();
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	228080e7          	jalr	552(ra) # 800009d4 <uartintr>
    800027b4:	b7ed                	j	8000279e <devintr+0x5e>
      virtio_disk_intr();
    800027b6:	00004097          	auipc	ra,0x4
    800027ba:	990080e7          	jalr	-1648(ra) # 80006146 <virtio_disk_intr>
    800027be:	b7c5                	j	8000279e <devintr+0x5e>
    if(cpuid() == 0){
    800027c0:	fffff097          	auipc	ra,0xfffff
    800027c4:	1f2080e7          	jalr	498(ra) # 800019b2 <cpuid>
    800027c8:	c901                	beqz	a0,800027d8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027ca:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027ce:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027d0:	14479073          	csrw	sip,a5
    return 2;
    800027d4:	4509                	li	a0,2
    800027d6:	b761                	j	8000275e <devintr+0x1e>
      clockintr();
    800027d8:	00000097          	auipc	ra,0x0
    800027dc:	f22080e7          	jalr	-222(ra) # 800026fa <clockintr>
    800027e0:	b7ed                	j	800027ca <devintr+0x8a>

00000000800027e2 <usertrap>:
{
    800027e2:	1101                	addi	sp,sp,-32
    800027e4:	ec06                	sd	ra,24(sp)
    800027e6:	e822                	sd	s0,16(sp)
    800027e8:	e426                	sd	s1,8(sp)
    800027ea:	e04a                	sd	s2,0(sp)
    800027ec:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ee:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027f2:	1007f793          	andi	a5,a5,256
    800027f6:	e3ad                	bnez	a5,80002858 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f8:	00003797          	auipc	a5,0x3
    800027fc:	38878793          	addi	a5,a5,904 # 80005b80 <kernelvec>
    80002800:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002804:	fffff097          	auipc	ra,0xfffff
    80002808:	1da080e7          	jalr	474(ra) # 800019de <myproc>
    8000280c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000280e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002810:	14102773          	csrr	a4,sepc
    80002814:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002816:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000281a:	47a1                	li	a5,8
    8000281c:	04f71c63          	bne	a4,a5,80002874 <usertrap+0x92>
    if(p->killed)
    80002820:	591c                	lw	a5,48(a0)
    80002822:	e3b9                	bnez	a5,80002868 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002824:	6cb8                	ld	a4,88(s1)
    80002826:	6f1c                	ld	a5,24(a4)
    80002828:	0791                	addi	a5,a5,4
    8000282a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000282c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002830:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002834:	10079073          	csrw	sstatus,a5
    syscall();
    80002838:	00000097          	auipc	ra,0x0
    8000283c:	2e0080e7          	jalr	736(ra) # 80002b18 <syscall>
  if(p->killed)
    80002840:	589c                	lw	a5,48(s1)
    80002842:	ebc1                	bnez	a5,800028d2 <usertrap+0xf0>
  usertrapret();
    80002844:	00000097          	auipc	ra,0x0
    80002848:	e18080e7          	jalr	-488(ra) # 8000265c <usertrapret>
}
    8000284c:	60e2                	ld	ra,24(sp)
    8000284e:	6442                	ld	s0,16(sp)
    80002850:	64a2                	ld	s1,8(sp)
    80002852:	6902                	ld	s2,0(sp)
    80002854:	6105                	addi	sp,sp,32
    80002856:	8082                	ret
    panic("usertrap: not from user mode");
    80002858:	00006517          	auipc	a0,0x6
    8000285c:	aa050513          	addi	a0,a0,-1376 # 800082f8 <states.1703+0x50>
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	ce8080e7          	jalr	-792(ra) # 80000548 <panic>
      exit(-1);
    80002868:	557d                	li	a0,-1
    8000286a:	00000097          	auipc	ra,0x0
    8000286e:	846080e7          	jalr	-1978(ra) # 800020b0 <exit>
    80002872:	bf4d                	j	80002824 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002874:	00000097          	auipc	ra,0x0
    80002878:	ecc080e7          	jalr	-308(ra) # 80002740 <devintr>
    8000287c:	892a                	mv	s2,a0
    8000287e:	c501                	beqz	a0,80002886 <usertrap+0xa4>
  if(p->killed)
    80002880:	589c                	lw	a5,48(s1)
    80002882:	c3a1                	beqz	a5,800028c2 <usertrap+0xe0>
    80002884:	a815                	j	800028b8 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002886:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000288a:	5c90                	lw	a2,56(s1)
    8000288c:	00006517          	auipc	a0,0x6
    80002890:	a8c50513          	addi	a0,a0,-1396 # 80008318 <states.1703+0x70>
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	cfe080e7          	jalr	-770(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000289c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028a0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028a4:	00006517          	auipc	a0,0x6
    800028a8:	aa450513          	addi	a0,a0,-1372 # 80008348 <states.1703+0xa0>
    800028ac:	ffffe097          	auipc	ra,0xffffe
    800028b0:	ce6080e7          	jalr	-794(ra) # 80000592 <printf>
    p->killed = 1;
    800028b4:	4785                	li	a5,1
    800028b6:	d89c                	sw	a5,48(s1)
    exit(-1);
    800028b8:	557d                	li	a0,-1
    800028ba:	fffff097          	auipc	ra,0xfffff
    800028be:	7f6080e7          	jalr	2038(ra) # 800020b0 <exit>
  if(which_dev == 2)
    800028c2:	4789                	li	a5,2
    800028c4:	f8f910e3          	bne	s2,a5,80002844 <usertrap+0x62>
    yield();
    800028c8:	00000097          	auipc	ra,0x0
    800028cc:	8f2080e7          	jalr	-1806(ra) # 800021ba <yield>
    800028d0:	bf95                	j	80002844 <usertrap+0x62>
  int which_dev = 0;
    800028d2:	4901                	li	s2,0
    800028d4:	b7d5                	j	800028b8 <usertrap+0xd6>

00000000800028d6 <kerneltrap>:
{
    800028d6:	7179                	addi	sp,sp,-48
    800028d8:	f406                	sd	ra,40(sp)
    800028da:	f022                	sd	s0,32(sp)
    800028dc:	ec26                	sd	s1,24(sp)
    800028de:	e84a                	sd	s2,16(sp)
    800028e0:	e44e                	sd	s3,8(sp)
    800028e2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ec:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028f0:	1004f793          	andi	a5,s1,256
    800028f4:	cb85                	beqz	a5,80002924 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028fa:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028fc:	ef85                	bnez	a5,80002934 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028fe:	00000097          	auipc	ra,0x0
    80002902:	e42080e7          	jalr	-446(ra) # 80002740 <devintr>
    80002906:	cd1d                	beqz	a0,80002944 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002908:	4789                	li	a5,2
    8000290a:	06f50a63          	beq	a0,a5,8000297e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000290e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002912:	10049073          	csrw	sstatus,s1
}
    80002916:	70a2                	ld	ra,40(sp)
    80002918:	7402                	ld	s0,32(sp)
    8000291a:	64e2                	ld	s1,24(sp)
    8000291c:	6942                	ld	s2,16(sp)
    8000291e:	69a2                	ld	s3,8(sp)
    80002920:	6145                	addi	sp,sp,48
    80002922:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002924:	00006517          	auipc	a0,0x6
    80002928:	a4450513          	addi	a0,a0,-1468 # 80008368 <states.1703+0xc0>
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	c1c080e7          	jalr	-996(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002934:	00006517          	auipc	a0,0x6
    80002938:	a5c50513          	addi	a0,a0,-1444 # 80008390 <states.1703+0xe8>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	c0c080e7          	jalr	-1012(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002944:	85ce                	mv	a1,s3
    80002946:	00006517          	auipc	a0,0x6
    8000294a:	a6a50513          	addi	a0,a0,-1430 # 800083b0 <states.1703+0x108>
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	c44080e7          	jalr	-956(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002956:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000295a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000295e:	00006517          	auipc	a0,0x6
    80002962:	a6250513          	addi	a0,a0,-1438 # 800083c0 <states.1703+0x118>
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	c2c080e7          	jalr	-980(ra) # 80000592 <printf>
    panic("kerneltrap");
    8000296e:	00006517          	auipc	a0,0x6
    80002972:	a6a50513          	addi	a0,a0,-1430 # 800083d8 <states.1703+0x130>
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	bd2080e7          	jalr	-1070(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000297e:	fffff097          	auipc	ra,0xfffff
    80002982:	060080e7          	jalr	96(ra) # 800019de <myproc>
    80002986:	d541                	beqz	a0,8000290e <kerneltrap+0x38>
    80002988:	fffff097          	auipc	ra,0xfffff
    8000298c:	056080e7          	jalr	86(ra) # 800019de <myproc>
    80002990:	4d18                	lw	a4,24(a0)
    80002992:	478d                	li	a5,3
    80002994:	f6f71de3          	bne	a4,a5,8000290e <kerneltrap+0x38>
    yield();
    80002998:	00000097          	auipc	ra,0x0
    8000299c:	822080e7          	jalr	-2014(ra) # 800021ba <yield>
    800029a0:	b7bd                	j	8000290e <kerneltrap+0x38>

00000000800029a2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029a2:	1101                	addi	sp,sp,-32
    800029a4:	ec06                	sd	ra,24(sp)
    800029a6:	e822                	sd	s0,16(sp)
    800029a8:	e426                	sd	s1,8(sp)
    800029aa:	1000                	addi	s0,sp,32
    800029ac:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029ae:	fffff097          	auipc	ra,0xfffff
    800029b2:	030080e7          	jalr	48(ra) # 800019de <myproc>
  switch (n) {
    800029b6:	4795                	li	a5,5
    800029b8:	0497e163          	bltu	a5,s1,800029fa <argraw+0x58>
    800029bc:	048a                	slli	s1,s1,0x2
    800029be:	00006717          	auipc	a4,0x6
    800029c2:	b1270713          	addi	a4,a4,-1262 # 800084d0 <states.1703+0x228>
    800029c6:	94ba                	add	s1,s1,a4
    800029c8:	409c                	lw	a5,0(s1)
    800029ca:	97ba                	add	a5,a5,a4
    800029cc:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029ce:	6d3c                	ld	a5,88(a0)
    800029d0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029d2:	60e2                	ld	ra,24(sp)
    800029d4:	6442                	ld	s0,16(sp)
    800029d6:	64a2                	ld	s1,8(sp)
    800029d8:	6105                	addi	sp,sp,32
    800029da:	8082                	ret
    return p->trapframe->a1;
    800029dc:	6d3c                	ld	a5,88(a0)
    800029de:	7fa8                	ld	a0,120(a5)
    800029e0:	bfcd                	j	800029d2 <argraw+0x30>
    return p->trapframe->a2;
    800029e2:	6d3c                	ld	a5,88(a0)
    800029e4:	63c8                	ld	a0,128(a5)
    800029e6:	b7f5                	j	800029d2 <argraw+0x30>
    return p->trapframe->a3;
    800029e8:	6d3c                	ld	a5,88(a0)
    800029ea:	67c8                	ld	a0,136(a5)
    800029ec:	b7dd                	j	800029d2 <argraw+0x30>
    return p->trapframe->a4;
    800029ee:	6d3c                	ld	a5,88(a0)
    800029f0:	6bc8                	ld	a0,144(a5)
    800029f2:	b7c5                	j	800029d2 <argraw+0x30>
    return p->trapframe->a5;
    800029f4:	6d3c                	ld	a5,88(a0)
    800029f6:	6fc8                	ld	a0,152(a5)
    800029f8:	bfe9                	j	800029d2 <argraw+0x30>
  panic("argraw");
    800029fa:	00006517          	auipc	a0,0x6
    800029fe:	9ee50513          	addi	a0,a0,-1554 # 800083e8 <states.1703+0x140>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	b46080e7          	jalr	-1210(ra) # 80000548 <panic>

0000000080002a0a <fetchaddr>:
{
    80002a0a:	1101                	addi	sp,sp,-32
    80002a0c:	ec06                	sd	ra,24(sp)
    80002a0e:	e822                	sd	s0,16(sp)
    80002a10:	e426                	sd	s1,8(sp)
    80002a12:	e04a                	sd	s2,0(sp)
    80002a14:	1000                	addi	s0,sp,32
    80002a16:	84aa                	mv	s1,a0
    80002a18:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a1a:	fffff097          	auipc	ra,0xfffff
    80002a1e:	fc4080e7          	jalr	-60(ra) # 800019de <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a22:	653c                	ld	a5,72(a0)
    80002a24:	02f4f863          	bgeu	s1,a5,80002a54 <fetchaddr+0x4a>
    80002a28:	00848713          	addi	a4,s1,8
    80002a2c:	02e7e663          	bltu	a5,a4,80002a58 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a30:	46a1                	li	a3,8
    80002a32:	8626                	mv	a2,s1
    80002a34:	85ca                	mv	a1,s2
    80002a36:	6928                	ld	a0,80(a0)
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	d26080e7          	jalr	-730(ra) # 8000175e <copyin>
    80002a40:	00a03533          	snez	a0,a0
    80002a44:	40a00533          	neg	a0,a0
}
    80002a48:	60e2                	ld	ra,24(sp)
    80002a4a:	6442                	ld	s0,16(sp)
    80002a4c:	64a2                	ld	s1,8(sp)
    80002a4e:	6902                	ld	s2,0(sp)
    80002a50:	6105                	addi	sp,sp,32
    80002a52:	8082                	ret
    return -1;
    80002a54:	557d                	li	a0,-1
    80002a56:	bfcd                	j	80002a48 <fetchaddr+0x3e>
    80002a58:	557d                	li	a0,-1
    80002a5a:	b7fd                	j	80002a48 <fetchaddr+0x3e>

0000000080002a5c <fetchstr>:
{
    80002a5c:	7179                	addi	sp,sp,-48
    80002a5e:	f406                	sd	ra,40(sp)
    80002a60:	f022                	sd	s0,32(sp)
    80002a62:	ec26                	sd	s1,24(sp)
    80002a64:	e84a                	sd	s2,16(sp)
    80002a66:	e44e                	sd	s3,8(sp)
    80002a68:	1800                	addi	s0,sp,48
    80002a6a:	892a                	mv	s2,a0
    80002a6c:	84ae                	mv	s1,a1
    80002a6e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a70:	fffff097          	auipc	ra,0xfffff
    80002a74:	f6e080e7          	jalr	-146(ra) # 800019de <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a78:	86ce                	mv	a3,s3
    80002a7a:	864a                	mv	a2,s2
    80002a7c:	85a6                	mv	a1,s1
    80002a7e:	6928                	ld	a0,80(a0)
    80002a80:	fffff097          	auipc	ra,0xfffff
    80002a84:	d6a080e7          	jalr	-662(ra) # 800017ea <copyinstr>
  if(err < 0)
    80002a88:	00054763          	bltz	a0,80002a96 <fetchstr+0x3a>
  return strlen(buf);
    80002a8c:	8526                	mv	a0,s1
    80002a8e:	ffffe097          	auipc	ra,0xffffe
    80002a92:	406080e7          	jalr	1030(ra) # 80000e94 <strlen>
}
    80002a96:	70a2                	ld	ra,40(sp)
    80002a98:	7402                	ld	s0,32(sp)
    80002a9a:	64e2                	ld	s1,24(sp)
    80002a9c:	6942                	ld	s2,16(sp)
    80002a9e:	69a2                	ld	s3,8(sp)
    80002aa0:	6145                	addi	sp,sp,48
    80002aa2:	8082                	ret

0000000080002aa4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002aa4:	1101                	addi	sp,sp,-32
    80002aa6:	ec06                	sd	ra,24(sp)
    80002aa8:	e822                	sd	s0,16(sp)
    80002aaa:	e426                	sd	s1,8(sp)
    80002aac:	1000                	addi	s0,sp,32
    80002aae:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ab0:	00000097          	auipc	ra,0x0
    80002ab4:	ef2080e7          	jalr	-270(ra) # 800029a2 <argraw>
    80002ab8:	c088                	sw	a0,0(s1)
  return 0;
}
    80002aba:	4501                	li	a0,0
    80002abc:	60e2                	ld	ra,24(sp)
    80002abe:	6442                	ld	s0,16(sp)
    80002ac0:	64a2                	ld	s1,8(sp)
    80002ac2:	6105                	addi	sp,sp,32
    80002ac4:	8082                	ret

0000000080002ac6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ac6:	1101                	addi	sp,sp,-32
    80002ac8:	ec06                	sd	ra,24(sp)
    80002aca:	e822                	sd	s0,16(sp)
    80002acc:	e426                	sd	s1,8(sp)
    80002ace:	1000                	addi	s0,sp,32
    80002ad0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ad2:	00000097          	auipc	ra,0x0
    80002ad6:	ed0080e7          	jalr	-304(ra) # 800029a2 <argraw>
    80002ada:	e088                	sd	a0,0(s1)
  return 0;
}
    80002adc:	4501                	li	a0,0
    80002ade:	60e2                	ld	ra,24(sp)
    80002ae0:	6442                	ld	s0,16(sp)
    80002ae2:	64a2                	ld	s1,8(sp)
    80002ae4:	6105                	addi	sp,sp,32
    80002ae6:	8082                	ret

0000000080002ae8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ae8:	1101                	addi	sp,sp,-32
    80002aea:	ec06                	sd	ra,24(sp)
    80002aec:	e822                	sd	s0,16(sp)
    80002aee:	e426                	sd	s1,8(sp)
    80002af0:	e04a                	sd	s2,0(sp)
    80002af2:	1000                	addi	s0,sp,32
    80002af4:	84ae                	mv	s1,a1
    80002af6:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002af8:	00000097          	auipc	ra,0x0
    80002afc:	eaa080e7          	jalr	-342(ra) # 800029a2 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b00:	864a                	mv	a2,s2
    80002b02:	85a6                	mv	a1,s1
    80002b04:	00000097          	auipc	ra,0x0
    80002b08:	f58080e7          	jalr	-168(ra) # 80002a5c <fetchstr>
}
    80002b0c:	60e2                	ld	ra,24(sp)
    80002b0e:	6442                	ld	s0,16(sp)
    80002b10:	64a2                	ld	s1,8(sp)
    80002b12:	6902                	ld	s2,0(sp)
    80002b14:	6105                	addi	sp,sp,32
    80002b16:	8082                	ret

0000000080002b18 <syscall>:
  "trace",
};

void
syscall(void)
{
    80002b18:	7179                	addi	sp,sp,-48
    80002b1a:	f406                	sd	ra,40(sp)
    80002b1c:	f022                	sd	s0,32(sp)
    80002b1e:	ec26                	sd	s1,24(sp)
    80002b20:	e84a                	sd	s2,16(sp)
    80002b22:	e44e                	sd	s3,8(sp)
    80002b24:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	eb8080e7          	jalr	-328(ra) # 800019de <myproc>
    80002b2e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b30:	05853903          	ld	s2,88(a0)
    80002b34:	0a893783          	ld	a5,168(s2)
    80002b38:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b3c:	37fd                	addiw	a5,a5,-1
    80002b3e:	4755                	li	a4,21
    80002b40:	04f76963          	bltu	a4,a5,80002b92 <syscall+0x7a>
    80002b44:	00399713          	slli	a4,s3,0x3
    80002b48:	00006797          	auipc	a5,0x6
    80002b4c:	9a078793          	addi	a5,a5,-1632 # 800084e8 <syscalls>
    80002b50:	97ba                	add	a5,a5,a4
    80002b52:	639c                	ld	a5,0(a5)
    80002b54:	cf9d                	beqz	a5,80002b92 <syscall+0x7a>
    p->trapframe->a0 = syscalls[num]();
    80002b56:	9782                	jalr	a5
    80002b58:	06a93823          	sd	a0,112(s2)
    if (p->tracemask & (1 << num)) {
    80002b5c:	4785                	li	a5,1
    80002b5e:	013797bb          	sllw	a5,a5,s3
    80002b62:	1684b703          	ld	a4,360(s1)
    80002b66:	8ff9                	and	a5,a5,a4
    80002b68:	c7a1                	beqz	a5,80002bb0 <syscall+0x98>
      //this process traces this sys call num
      printf("%d: syscall %s -> %d\n", p->pid, sysnames[num], p->trapframe->a0);
    80002b6a:	6cb8                	ld	a4,88(s1)
    80002b6c:	098e                	slli	s3,s3,0x3
    80002b6e:	00006797          	auipc	a5,0x6
    80002b72:	97a78793          	addi	a5,a5,-1670 # 800084e8 <syscalls>
    80002b76:	99be                	add	s3,s3,a5
    80002b78:	7b34                	ld	a3,112(a4)
    80002b7a:	0b89b603          	ld	a2,184(s3)
    80002b7e:	5c8c                	lw	a1,56(s1)
    80002b80:	00006517          	auipc	a0,0x6
    80002b84:	87050513          	addi	a0,a0,-1936 # 800083f0 <states.1703+0x148>
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	a0a080e7          	jalr	-1526(ra) # 80000592 <printf>
    80002b90:	a005                	j	80002bb0 <syscall+0x98>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b92:	86ce                	mv	a3,s3
    80002b94:	15848613          	addi	a2,s1,344
    80002b98:	5c8c                	lw	a1,56(s1)
    80002b9a:	00006517          	auipc	a0,0x6
    80002b9e:	86e50513          	addi	a0,a0,-1938 # 80008408 <states.1703+0x160>
    80002ba2:	ffffe097          	auipc	ra,0xffffe
    80002ba6:	9f0080e7          	jalr	-1552(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002baa:	6cbc                	ld	a5,88(s1)
    80002bac:	577d                	li	a4,-1
    80002bae:	fbb8                	sd	a4,112(a5)
  }
}
    80002bb0:	70a2                	ld	ra,40(sp)
    80002bb2:	7402                	ld	s0,32(sp)
    80002bb4:	64e2                	ld	s1,24(sp)
    80002bb6:	6942                	ld	s2,16(sp)
    80002bb8:	69a2                	ld	s3,8(sp)
    80002bba:	6145                	addi	sp,sp,48
    80002bbc:	8082                	ret

0000000080002bbe <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bbe:	1101                	addi	sp,sp,-32
    80002bc0:	ec06                	sd	ra,24(sp)
    80002bc2:	e822                	sd	s0,16(sp)
    80002bc4:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002bc6:	fec40593          	addi	a1,s0,-20
    80002bca:	4501                	li	a0,0
    80002bcc:	00000097          	auipc	ra,0x0
    80002bd0:	ed8080e7          	jalr	-296(ra) # 80002aa4 <argint>
    return -1;
    80002bd4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002bd6:	00054963          	bltz	a0,80002be8 <sys_exit+0x2a>
  exit(n);
    80002bda:	fec42503          	lw	a0,-20(s0)
    80002bde:	fffff097          	auipc	ra,0xfffff
    80002be2:	4d2080e7          	jalr	1234(ra) # 800020b0 <exit>
  return 0;  // not reached
    80002be6:	4781                	li	a5,0
}
    80002be8:	853e                	mv	a0,a5
    80002bea:	60e2                	ld	ra,24(sp)
    80002bec:	6442                	ld	s0,16(sp)
    80002bee:	6105                	addi	sp,sp,32
    80002bf0:	8082                	ret

0000000080002bf2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bf2:	1141                	addi	sp,sp,-16
    80002bf4:	e406                	sd	ra,8(sp)
    80002bf6:	e022                	sd	s0,0(sp)
    80002bf8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	de4080e7          	jalr	-540(ra) # 800019de <myproc>
}
    80002c02:	5d08                	lw	a0,56(a0)
    80002c04:	60a2                	ld	ra,8(sp)
    80002c06:	6402                	ld	s0,0(sp)
    80002c08:	0141                	addi	sp,sp,16
    80002c0a:	8082                	ret

0000000080002c0c <sys_fork>:

uint64
sys_fork(void)
{
    80002c0c:	1141                	addi	sp,sp,-16
    80002c0e:	e406                	sd	ra,8(sp)
    80002c10:	e022                	sd	s0,0(sp)
    80002c12:	0800                	addi	s0,sp,16
  return fork();
    80002c14:	fffff097          	auipc	ra,0xfffff
    80002c18:	18e080e7          	jalr	398(ra) # 80001da2 <fork>
}
    80002c1c:	60a2                	ld	ra,8(sp)
    80002c1e:	6402                	ld	s0,0(sp)
    80002c20:	0141                	addi	sp,sp,16
    80002c22:	8082                	ret

0000000080002c24 <sys_wait>:

uint64
sys_wait(void)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c2c:	fe840593          	addi	a1,s0,-24
    80002c30:	4501                	li	a0,0
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	e94080e7          	jalr	-364(ra) # 80002ac6 <argaddr>
    80002c3a:	87aa                	mv	a5,a0
    return -1;
    80002c3c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c3e:	0007c863          	bltz	a5,80002c4e <sys_wait+0x2a>
  return wait(p);
    80002c42:	fe843503          	ld	a0,-24(s0)
    80002c46:	fffff097          	auipc	ra,0xfffff
    80002c4a:	62e080e7          	jalr	1582(ra) # 80002274 <wait>
}
    80002c4e:	60e2                	ld	ra,24(sp)
    80002c50:	6442                	ld	s0,16(sp)
    80002c52:	6105                	addi	sp,sp,32
    80002c54:	8082                	ret

0000000080002c56 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c56:	7179                	addi	sp,sp,-48
    80002c58:	f406                	sd	ra,40(sp)
    80002c5a:	f022                	sd	s0,32(sp)
    80002c5c:	ec26                	sd	s1,24(sp)
    80002c5e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c60:	fdc40593          	addi	a1,s0,-36
    80002c64:	4501                	li	a0,0
    80002c66:	00000097          	auipc	ra,0x0
    80002c6a:	e3e080e7          	jalr	-450(ra) # 80002aa4 <argint>
    80002c6e:	87aa                	mv	a5,a0
    return -1;
    80002c70:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002c72:	0207c063          	bltz	a5,80002c92 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002c76:	fffff097          	auipc	ra,0xfffff
    80002c7a:	d68080e7          	jalr	-664(ra) # 800019de <myproc>
    80002c7e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c80:	fdc42503          	lw	a0,-36(s0)
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	0aa080e7          	jalr	170(ra) # 80001d2e <growproc>
    80002c8c:	00054863          	bltz	a0,80002c9c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c90:	8526                	mv	a0,s1
}
    80002c92:	70a2                	ld	ra,40(sp)
    80002c94:	7402                	ld	s0,32(sp)
    80002c96:	64e2                	ld	s1,24(sp)
    80002c98:	6145                	addi	sp,sp,48
    80002c9a:	8082                	ret
    return -1;
    80002c9c:	557d                	li	a0,-1
    80002c9e:	bfd5                	j	80002c92 <sys_sbrk+0x3c>

0000000080002ca0 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ca0:	7139                	addi	sp,sp,-64
    80002ca2:	fc06                	sd	ra,56(sp)
    80002ca4:	f822                	sd	s0,48(sp)
    80002ca6:	f426                	sd	s1,40(sp)
    80002ca8:	f04a                	sd	s2,32(sp)
    80002caa:	ec4e                	sd	s3,24(sp)
    80002cac:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002cae:	fcc40593          	addi	a1,s0,-52
    80002cb2:	4501                	li	a0,0
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	df0080e7          	jalr	-528(ra) # 80002aa4 <argint>
    return -1;
    80002cbc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cbe:	06054563          	bltz	a0,80002d28 <sys_sleep+0x88>
  acquire(&tickslock);
    80002cc2:	00015517          	auipc	a0,0x15
    80002cc6:	ca650513          	addi	a0,a0,-858 # 80017968 <tickslock>
    80002cca:	ffffe097          	auipc	ra,0xffffe
    80002cce:	f46080e7          	jalr	-186(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002cd2:	00006917          	auipc	s2,0x6
    80002cd6:	34e92903          	lw	s2,846(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002cda:	fcc42783          	lw	a5,-52(s0)
    80002cde:	cf85                	beqz	a5,80002d16 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ce0:	00015997          	auipc	s3,0x15
    80002ce4:	c8898993          	addi	s3,s3,-888 # 80017968 <tickslock>
    80002ce8:	00006497          	auipc	s1,0x6
    80002cec:	33848493          	addi	s1,s1,824 # 80009020 <ticks>
    if(myproc()->killed){
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	cee080e7          	jalr	-786(ra) # 800019de <myproc>
    80002cf8:	591c                	lw	a5,48(a0)
    80002cfa:	ef9d                	bnez	a5,80002d38 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002cfc:	85ce                	mv	a1,s3
    80002cfe:	8526                	mv	a0,s1
    80002d00:	fffff097          	auipc	ra,0xfffff
    80002d04:	4f6080e7          	jalr	1270(ra) # 800021f6 <sleep>
  while(ticks - ticks0 < n){
    80002d08:	409c                	lw	a5,0(s1)
    80002d0a:	412787bb          	subw	a5,a5,s2
    80002d0e:	fcc42703          	lw	a4,-52(s0)
    80002d12:	fce7efe3          	bltu	a5,a4,80002cf0 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d16:	00015517          	auipc	a0,0x15
    80002d1a:	c5250513          	addi	a0,a0,-942 # 80017968 <tickslock>
    80002d1e:	ffffe097          	auipc	ra,0xffffe
    80002d22:	fa6080e7          	jalr	-90(ra) # 80000cc4 <release>
  return 0;
    80002d26:	4781                	li	a5,0
}
    80002d28:	853e                	mv	a0,a5
    80002d2a:	70e2                	ld	ra,56(sp)
    80002d2c:	7442                	ld	s0,48(sp)
    80002d2e:	74a2                	ld	s1,40(sp)
    80002d30:	7902                	ld	s2,32(sp)
    80002d32:	69e2                	ld	s3,24(sp)
    80002d34:	6121                	addi	sp,sp,64
    80002d36:	8082                	ret
      release(&tickslock);
    80002d38:	00015517          	auipc	a0,0x15
    80002d3c:	c3050513          	addi	a0,a0,-976 # 80017968 <tickslock>
    80002d40:	ffffe097          	auipc	ra,0xffffe
    80002d44:	f84080e7          	jalr	-124(ra) # 80000cc4 <release>
      return -1;
    80002d48:	57fd                	li	a5,-1
    80002d4a:	bff9                	j	80002d28 <sys_sleep+0x88>

0000000080002d4c <sys_kill>:

uint64
sys_kill(void)
{
    80002d4c:	1101                	addi	sp,sp,-32
    80002d4e:	ec06                	sd	ra,24(sp)
    80002d50:	e822                	sd	s0,16(sp)
    80002d52:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d54:	fec40593          	addi	a1,s0,-20
    80002d58:	4501                	li	a0,0
    80002d5a:	00000097          	auipc	ra,0x0
    80002d5e:	d4a080e7          	jalr	-694(ra) # 80002aa4 <argint>
    80002d62:	87aa                	mv	a5,a0
    return -1;
    80002d64:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d66:	0007c863          	bltz	a5,80002d76 <sys_kill+0x2a>
  return kill(pid);
    80002d6a:	fec42503          	lw	a0,-20(s0)
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	678080e7          	jalr	1656(ra) # 800023e6 <kill>
}
    80002d76:	60e2                	ld	ra,24(sp)
    80002d78:	6442                	ld	s0,16(sp)
    80002d7a:	6105                	addi	sp,sp,32
    80002d7c:	8082                	ret

0000000080002d7e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d7e:	1101                	addi	sp,sp,-32
    80002d80:	ec06                	sd	ra,24(sp)
    80002d82:	e822                	sd	s0,16(sp)
    80002d84:	e426                	sd	s1,8(sp)
    80002d86:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d88:	00015517          	auipc	a0,0x15
    80002d8c:	be050513          	addi	a0,a0,-1056 # 80017968 <tickslock>
    80002d90:	ffffe097          	auipc	ra,0xffffe
    80002d94:	e80080e7          	jalr	-384(ra) # 80000c10 <acquire>
  xticks = ticks;
    80002d98:	00006497          	auipc	s1,0x6
    80002d9c:	2884a483          	lw	s1,648(s1) # 80009020 <ticks>
  release(&tickslock);
    80002da0:	00015517          	auipc	a0,0x15
    80002da4:	bc850513          	addi	a0,a0,-1080 # 80017968 <tickslock>
    80002da8:	ffffe097          	auipc	ra,0xffffe
    80002dac:	f1c080e7          	jalr	-228(ra) # 80000cc4 <release>
  return xticks;
}
    80002db0:	02049513          	slli	a0,s1,0x20
    80002db4:	9101                	srli	a0,a0,0x20
    80002db6:	60e2                	ld	ra,24(sp)
    80002db8:	6442                	ld	s0,16(sp)
    80002dba:	64a2                	ld	s1,8(sp)
    80002dbc:	6105                	addi	sp,sp,32
    80002dbe:	8082                	ret

0000000080002dc0 <sys_trace>:

uint64
sys_trace(void) {
    80002dc0:	1101                	addi	sp,sp,-32
    80002dc2:	ec06                	sd	ra,24(sp)
    80002dc4:	e822                	sd	s0,16(sp)
    80002dc6:	1000                	addi	s0,sp,32
  int trace_sys_mask;
  if (argint(0, &trace_sys_mask) < 0)
    80002dc8:	fec40593          	addi	a1,s0,-20
    80002dcc:	4501                	li	a0,0
    80002dce:	00000097          	auipc	ra,0x0
    80002dd2:	cd6080e7          	jalr	-810(ra) # 80002aa4 <argint>
    return -1;
    80002dd6:	57fd                	li	a5,-1
  if (argint(0, &trace_sys_mask) < 0)
    80002dd8:	00054e63          	bltz	a0,80002df4 <sys_trace+0x34>
  myproc()->tracemask |= trace_sys_mask;
    80002ddc:	fffff097          	auipc	ra,0xfffff
    80002de0:	c02080e7          	jalr	-1022(ra) # 800019de <myproc>
    80002de4:	fec42703          	lw	a4,-20(s0)
    80002de8:	16853783          	ld	a5,360(a0)
    80002dec:	8fd9                	or	a5,a5,a4
    80002dee:	16f53423          	sd	a5,360(a0)
  return 0;
    80002df2:	4781                	li	a5,0
    80002df4:	853e                	mv	a0,a5
    80002df6:	60e2                	ld	ra,24(sp)
    80002df8:	6442                	ld	s0,16(sp)
    80002dfa:	6105                	addi	sp,sp,32
    80002dfc:	8082                	ret

0000000080002dfe <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002dfe:	7179                	addi	sp,sp,-48
    80002e00:	f406                	sd	ra,40(sp)
    80002e02:	f022                	sd	s0,32(sp)
    80002e04:	ec26                	sd	s1,24(sp)
    80002e06:	e84a                	sd	s2,16(sp)
    80002e08:	e44e                	sd	s3,8(sp)
    80002e0a:	e052                	sd	s4,0(sp)
    80002e0c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e0e:	00006597          	auipc	a1,0x6
    80002e12:	84a58593          	addi	a1,a1,-1974 # 80008658 <sysnames+0xb8>
    80002e16:	00015517          	auipc	a0,0x15
    80002e1a:	b6a50513          	addi	a0,a0,-1174 # 80017980 <bcache>
    80002e1e:	ffffe097          	auipc	ra,0xffffe
    80002e22:	d62080e7          	jalr	-670(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e26:	0001d797          	auipc	a5,0x1d
    80002e2a:	b5a78793          	addi	a5,a5,-1190 # 8001f980 <bcache+0x8000>
    80002e2e:	0001d717          	auipc	a4,0x1d
    80002e32:	dba70713          	addi	a4,a4,-582 # 8001fbe8 <bcache+0x8268>
    80002e36:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e3a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e3e:	00015497          	auipc	s1,0x15
    80002e42:	b5a48493          	addi	s1,s1,-1190 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80002e46:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e48:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e4a:	00006a17          	auipc	s4,0x6
    80002e4e:	816a0a13          	addi	s4,s4,-2026 # 80008660 <sysnames+0xc0>
    b->next = bcache.head.next;
    80002e52:	2b893783          	ld	a5,696(s2)
    80002e56:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e58:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e5c:	85d2                	mv	a1,s4
    80002e5e:	01048513          	addi	a0,s1,16
    80002e62:	00001097          	auipc	ra,0x1
    80002e66:	4ac080e7          	jalr	1196(ra) # 8000430e <initsleeplock>
    bcache.head.next->prev = b;
    80002e6a:	2b893783          	ld	a5,696(s2)
    80002e6e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e70:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e74:	45848493          	addi	s1,s1,1112
    80002e78:	fd349de3          	bne	s1,s3,80002e52 <binit+0x54>
  }
}
    80002e7c:	70a2                	ld	ra,40(sp)
    80002e7e:	7402                	ld	s0,32(sp)
    80002e80:	64e2                	ld	s1,24(sp)
    80002e82:	6942                	ld	s2,16(sp)
    80002e84:	69a2                	ld	s3,8(sp)
    80002e86:	6a02                	ld	s4,0(sp)
    80002e88:	6145                	addi	sp,sp,48
    80002e8a:	8082                	ret

0000000080002e8c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e8c:	7179                	addi	sp,sp,-48
    80002e8e:	f406                	sd	ra,40(sp)
    80002e90:	f022                	sd	s0,32(sp)
    80002e92:	ec26                	sd	s1,24(sp)
    80002e94:	e84a                	sd	s2,16(sp)
    80002e96:	e44e                	sd	s3,8(sp)
    80002e98:	1800                	addi	s0,sp,48
    80002e9a:	89aa                	mv	s3,a0
    80002e9c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e9e:	00015517          	auipc	a0,0x15
    80002ea2:	ae250513          	addi	a0,a0,-1310 # 80017980 <bcache>
    80002ea6:	ffffe097          	auipc	ra,0xffffe
    80002eaa:	d6a080e7          	jalr	-662(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002eae:	0001d497          	auipc	s1,0x1d
    80002eb2:	d8a4b483          	ld	s1,-630(s1) # 8001fc38 <bcache+0x82b8>
    80002eb6:	0001d797          	auipc	a5,0x1d
    80002eba:	d3278793          	addi	a5,a5,-718 # 8001fbe8 <bcache+0x8268>
    80002ebe:	02f48f63          	beq	s1,a5,80002efc <bread+0x70>
    80002ec2:	873e                	mv	a4,a5
    80002ec4:	a021                	j	80002ecc <bread+0x40>
    80002ec6:	68a4                	ld	s1,80(s1)
    80002ec8:	02e48a63          	beq	s1,a4,80002efc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ecc:	449c                	lw	a5,8(s1)
    80002ece:	ff379ce3          	bne	a5,s3,80002ec6 <bread+0x3a>
    80002ed2:	44dc                	lw	a5,12(s1)
    80002ed4:	ff2799e3          	bne	a5,s2,80002ec6 <bread+0x3a>
      b->refcnt++;
    80002ed8:	40bc                	lw	a5,64(s1)
    80002eda:	2785                	addiw	a5,a5,1
    80002edc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ede:	00015517          	auipc	a0,0x15
    80002ee2:	aa250513          	addi	a0,a0,-1374 # 80017980 <bcache>
    80002ee6:	ffffe097          	auipc	ra,0xffffe
    80002eea:	dde080e7          	jalr	-546(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002eee:	01048513          	addi	a0,s1,16
    80002ef2:	00001097          	auipc	ra,0x1
    80002ef6:	456080e7          	jalr	1110(ra) # 80004348 <acquiresleep>
      return b;
    80002efa:	a8b9                	j	80002f58 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002efc:	0001d497          	auipc	s1,0x1d
    80002f00:	d344b483          	ld	s1,-716(s1) # 8001fc30 <bcache+0x82b0>
    80002f04:	0001d797          	auipc	a5,0x1d
    80002f08:	ce478793          	addi	a5,a5,-796 # 8001fbe8 <bcache+0x8268>
    80002f0c:	00f48863          	beq	s1,a5,80002f1c <bread+0x90>
    80002f10:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f12:	40bc                	lw	a5,64(s1)
    80002f14:	cf81                	beqz	a5,80002f2c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f16:	64a4                	ld	s1,72(s1)
    80002f18:	fee49de3          	bne	s1,a4,80002f12 <bread+0x86>
  panic("bget: no buffers");
    80002f1c:	00005517          	auipc	a0,0x5
    80002f20:	74c50513          	addi	a0,a0,1868 # 80008668 <sysnames+0xc8>
    80002f24:	ffffd097          	auipc	ra,0xffffd
    80002f28:	624080e7          	jalr	1572(ra) # 80000548 <panic>
      b->dev = dev;
    80002f2c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002f30:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002f34:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f38:	4785                	li	a5,1
    80002f3a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f3c:	00015517          	auipc	a0,0x15
    80002f40:	a4450513          	addi	a0,a0,-1468 # 80017980 <bcache>
    80002f44:	ffffe097          	auipc	ra,0xffffe
    80002f48:	d80080e7          	jalr	-640(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002f4c:	01048513          	addi	a0,s1,16
    80002f50:	00001097          	auipc	ra,0x1
    80002f54:	3f8080e7          	jalr	1016(ra) # 80004348 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f58:	409c                	lw	a5,0(s1)
    80002f5a:	cb89                	beqz	a5,80002f6c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f5c:	8526                	mv	a0,s1
    80002f5e:	70a2                	ld	ra,40(sp)
    80002f60:	7402                	ld	s0,32(sp)
    80002f62:	64e2                	ld	s1,24(sp)
    80002f64:	6942                	ld	s2,16(sp)
    80002f66:	69a2                	ld	s3,8(sp)
    80002f68:	6145                	addi	sp,sp,48
    80002f6a:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f6c:	4581                	li	a1,0
    80002f6e:	8526                	mv	a0,s1
    80002f70:	00003097          	auipc	ra,0x3
    80002f74:	f2c080e7          	jalr	-212(ra) # 80005e9c <virtio_disk_rw>
    b->valid = 1;
    80002f78:	4785                	li	a5,1
    80002f7a:	c09c                	sw	a5,0(s1)
  return b;
    80002f7c:	b7c5                	j	80002f5c <bread+0xd0>

0000000080002f7e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f7e:	1101                	addi	sp,sp,-32
    80002f80:	ec06                	sd	ra,24(sp)
    80002f82:	e822                	sd	s0,16(sp)
    80002f84:	e426                	sd	s1,8(sp)
    80002f86:	1000                	addi	s0,sp,32
    80002f88:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f8a:	0541                	addi	a0,a0,16
    80002f8c:	00001097          	auipc	ra,0x1
    80002f90:	456080e7          	jalr	1110(ra) # 800043e2 <holdingsleep>
    80002f94:	cd01                	beqz	a0,80002fac <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f96:	4585                	li	a1,1
    80002f98:	8526                	mv	a0,s1
    80002f9a:	00003097          	auipc	ra,0x3
    80002f9e:	f02080e7          	jalr	-254(ra) # 80005e9c <virtio_disk_rw>
}
    80002fa2:	60e2                	ld	ra,24(sp)
    80002fa4:	6442                	ld	s0,16(sp)
    80002fa6:	64a2                	ld	s1,8(sp)
    80002fa8:	6105                	addi	sp,sp,32
    80002faa:	8082                	ret
    panic("bwrite");
    80002fac:	00005517          	auipc	a0,0x5
    80002fb0:	6d450513          	addi	a0,a0,1748 # 80008680 <sysnames+0xe0>
    80002fb4:	ffffd097          	auipc	ra,0xffffd
    80002fb8:	594080e7          	jalr	1428(ra) # 80000548 <panic>

0000000080002fbc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fbc:	1101                	addi	sp,sp,-32
    80002fbe:	ec06                	sd	ra,24(sp)
    80002fc0:	e822                	sd	s0,16(sp)
    80002fc2:	e426                	sd	s1,8(sp)
    80002fc4:	e04a                	sd	s2,0(sp)
    80002fc6:	1000                	addi	s0,sp,32
    80002fc8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fca:	01050913          	addi	s2,a0,16
    80002fce:	854a                	mv	a0,s2
    80002fd0:	00001097          	auipc	ra,0x1
    80002fd4:	412080e7          	jalr	1042(ra) # 800043e2 <holdingsleep>
    80002fd8:	c92d                	beqz	a0,8000304a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fda:	854a                	mv	a0,s2
    80002fdc:	00001097          	auipc	ra,0x1
    80002fe0:	3c2080e7          	jalr	962(ra) # 8000439e <releasesleep>

  acquire(&bcache.lock);
    80002fe4:	00015517          	auipc	a0,0x15
    80002fe8:	99c50513          	addi	a0,a0,-1636 # 80017980 <bcache>
    80002fec:	ffffe097          	auipc	ra,0xffffe
    80002ff0:	c24080e7          	jalr	-988(ra) # 80000c10 <acquire>
  b->refcnt--;
    80002ff4:	40bc                	lw	a5,64(s1)
    80002ff6:	37fd                	addiw	a5,a5,-1
    80002ff8:	0007871b          	sext.w	a4,a5
    80002ffc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002ffe:	eb05                	bnez	a4,8000302e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003000:	68bc                	ld	a5,80(s1)
    80003002:	64b8                	ld	a4,72(s1)
    80003004:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003006:	64bc                	ld	a5,72(s1)
    80003008:	68b8                	ld	a4,80(s1)
    8000300a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000300c:	0001d797          	auipc	a5,0x1d
    80003010:	97478793          	addi	a5,a5,-1676 # 8001f980 <bcache+0x8000>
    80003014:	2b87b703          	ld	a4,696(a5)
    80003018:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000301a:	0001d717          	auipc	a4,0x1d
    8000301e:	bce70713          	addi	a4,a4,-1074 # 8001fbe8 <bcache+0x8268>
    80003022:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003024:	2b87b703          	ld	a4,696(a5)
    80003028:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000302a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000302e:	00015517          	auipc	a0,0x15
    80003032:	95250513          	addi	a0,a0,-1710 # 80017980 <bcache>
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	c8e080e7          	jalr	-882(ra) # 80000cc4 <release>
}
    8000303e:	60e2                	ld	ra,24(sp)
    80003040:	6442                	ld	s0,16(sp)
    80003042:	64a2                	ld	s1,8(sp)
    80003044:	6902                	ld	s2,0(sp)
    80003046:	6105                	addi	sp,sp,32
    80003048:	8082                	ret
    panic("brelse");
    8000304a:	00005517          	auipc	a0,0x5
    8000304e:	63e50513          	addi	a0,a0,1598 # 80008688 <sysnames+0xe8>
    80003052:	ffffd097          	auipc	ra,0xffffd
    80003056:	4f6080e7          	jalr	1270(ra) # 80000548 <panic>

000000008000305a <bpin>:

void
bpin(struct buf *b) {
    8000305a:	1101                	addi	sp,sp,-32
    8000305c:	ec06                	sd	ra,24(sp)
    8000305e:	e822                	sd	s0,16(sp)
    80003060:	e426                	sd	s1,8(sp)
    80003062:	1000                	addi	s0,sp,32
    80003064:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003066:	00015517          	auipc	a0,0x15
    8000306a:	91a50513          	addi	a0,a0,-1766 # 80017980 <bcache>
    8000306e:	ffffe097          	auipc	ra,0xffffe
    80003072:	ba2080e7          	jalr	-1118(ra) # 80000c10 <acquire>
  b->refcnt++;
    80003076:	40bc                	lw	a5,64(s1)
    80003078:	2785                	addiw	a5,a5,1
    8000307a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000307c:	00015517          	auipc	a0,0x15
    80003080:	90450513          	addi	a0,a0,-1788 # 80017980 <bcache>
    80003084:	ffffe097          	auipc	ra,0xffffe
    80003088:	c40080e7          	jalr	-960(ra) # 80000cc4 <release>
}
    8000308c:	60e2                	ld	ra,24(sp)
    8000308e:	6442                	ld	s0,16(sp)
    80003090:	64a2                	ld	s1,8(sp)
    80003092:	6105                	addi	sp,sp,32
    80003094:	8082                	ret

0000000080003096 <bunpin>:

void
bunpin(struct buf *b) {
    80003096:	1101                	addi	sp,sp,-32
    80003098:	ec06                	sd	ra,24(sp)
    8000309a:	e822                	sd	s0,16(sp)
    8000309c:	e426                	sd	s1,8(sp)
    8000309e:	1000                	addi	s0,sp,32
    800030a0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030a2:	00015517          	auipc	a0,0x15
    800030a6:	8de50513          	addi	a0,a0,-1826 # 80017980 <bcache>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	b66080e7          	jalr	-1178(ra) # 80000c10 <acquire>
  b->refcnt--;
    800030b2:	40bc                	lw	a5,64(s1)
    800030b4:	37fd                	addiw	a5,a5,-1
    800030b6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030b8:	00015517          	auipc	a0,0x15
    800030bc:	8c850513          	addi	a0,a0,-1848 # 80017980 <bcache>
    800030c0:	ffffe097          	auipc	ra,0xffffe
    800030c4:	c04080e7          	jalr	-1020(ra) # 80000cc4 <release>
}
    800030c8:	60e2                	ld	ra,24(sp)
    800030ca:	6442                	ld	s0,16(sp)
    800030cc:	64a2                	ld	s1,8(sp)
    800030ce:	6105                	addi	sp,sp,32
    800030d0:	8082                	ret

00000000800030d2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030d2:	1101                	addi	sp,sp,-32
    800030d4:	ec06                	sd	ra,24(sp)
    800030d6:	e822                	sd	s0,16(sp)
    800030d8:	e426                	sd	s1,8(sp)
    800030da:	e04a                	sd	s2,0(sp)
    800030dc:	1000                	addi	s0,sp,32
    800030de:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030e0:	00d5d59b          	srliw	a1,a1,0xd
    800030e4:	0001d797          	auipc	a5,0x1d
    800030e8:	f787a783          	lw	a5,-136(a5) # 8002005c <sb+0x1c>
    800030ec:	9dbd                	addw	a1,a1,a5
    800030ee:	00000097          	auipc	ra,0x0
    800030f2:	d9e080e7          	jalr	-610(ra) # 80002e8c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030f6:	0074f713          	andi	a4,s1,7
    800030fa:	4785                	li	a5,1
    800030fc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003100:	14ce                	slli	s1,s1,0x33
    80003102:	90d9                	srli	s1,s1,0x36
    80003104:	00950733          	add	a4,a0,s1
    80003108:	05874703          	lbu	a4,88(a4)
    8000310c:	00e7f6b3          	and	a3,a5,a4
    80003110:	c69d                	beqz	a3,8000313e <bfree+0x6c>
    80003112:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003114:	94aa                	add	s1,s1,a0
    80003116:	fff7c793          	not	a5,a5
    8000311a:	8ff9                	and	a5,a5,a4
    8000311c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003120:	00001097          	auipc	ra,0x1
    80003124:	100080e7          	jalr	256(ra) # 80004220 <log_write>
  brelse(bp);
    80003128:	854a                	mv	a0,s2
    8000312a:	00000097          	auipc	ra,0x0
    8000312e:	e92080e7          	jalr	-366(ra) # 80002fbc <brelse>
}
    80003132:	60e2                	ld	ra,24(sp)
    80003134:	6442                	ld	s0,16(sp)
    80003136:	64a2                	ld	s1,8(sp)
    80003138:	6902                	ld	s2,0(sp)
    8000313a:	6105                	addi	sp,sp,32
    8000313c:	8082                	ret
    panic("freeing free block");
    8000313e:	00005517          	auipc	a0,0x5
    80003142:	55250513          	addi	a0,a0,1362 # 80008690 <sysnames+0xf0>
    80003146:	ffffd097          	auipc	ra,0xffffd
    8000314a:	402080e7          	jalr	1026(ra) # 80000548 <panic>

000000008000314e <balloc>:
{
    8000314e:	711d                	addi	sp,sp,-96
    80003150:	ec86                	sd	ra,88(sp)
    80003152:	e8a2                	sd	s0,80(sp)
    80003154:	e4a6                	sd	s1,72(sp)
    80003156:	e0ca                	sd	s2,64(sp)
    80003158:	fc4e                	sd	s3,56(sp)
    8000315a:	f852                	sd	s4,48(sp)
    8000315c:	f456                	sd	s5,40(sp)
    8000315e:	f05a                	sd	s6,32(sp)
    80003160:	ec5e                	sd	s7,24(sp)
    80003162:	e862                	sd	s8,16(sp)
    80003164:	e466                	sd	s9,8(sp)
    80003166:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003168:	0001d797          	auipc	a5,0x1d
    8000316c:	edc7a783          	lw	a5,-292(a5) # 80020044 <sb+0x4>
    80003170:	cbd1                	beqz	a5,80003204 <balloc+0xb6>
    80003172:	8baa                	mv	s7,a0
    80003174:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003176:	0001db17          	auipc	s6,0x1d
    8000317a:	ecab0b13          	addi	s6,s6,-310 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000317e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003180:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003182:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003184:	6c89                	lui	s9,0x2
    80003186:	a831                	j	800031a2 <balloc+0x54>
    brelse(bp);
    80003188:	854a                	mv	a0,s2
    8000318a:	00000097          	auipc	ra,0x0
    8000318e:	e32080e7          	jalr	-462(ra) # 80002fbc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003192:	015c87bb          	addw	a5,s9,s5
    80003196:	00078a9b          	sext.w	s5,a5
    8000319a:	004b2703          	lw	a4,4(s6)
    8000319e:	06eaf363          	bgeu	s5,a4,80003204 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800031a2:	41fad79b          	sraiw	a5,s5,0x1f
    800031a6:	0137d79b          	srliw	a5,a5,0x13
    800031aa:	015787bb          	addw	a5,a5,s5
    800031ae:	40d7d79b          	sraiw	a5,a5,0xd
    800031b2:	01cb2583          	lw	a1,28(s6)
    800031b6:	9dbd                	addw	a1,a1,a5
    800031b8:	855e                	mv	a0,s7
    800031ba:	00000097          	auipc	ra,0x0
    800031be:	cd2080e7          	jalr	-814(ra) # 80002e8c <bread>
    800031c2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031c4:	004b2503          	lw	a0,4(s6)
    800031c8:	000a849b          	sext.w	s1,s5
    800031cc:	8662                	mv	a2,s8
    800031ce:	faa4fde3          	bgeu	s1,a0,80003188 <balloc+0x3a>
      m = 1 << (bi % 8);
    800031d2:	41f6579b          	sraiw	a5,a2,0x1f
    800031d6:	01d7d69b          	srliw	a3,a5,0x1d
    800031da:	00c6873b          	addw	a4,a3,a2
    800031de:	00777793          	andi	a5,a4,7
    800031e2:	9f95                	subw	a5,a5,a3
    800031e4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031e8:	4037571b          	sraiw	a4,a4,0x3
    800031ec:	00e906b3          	add	a3,s2,a4
    800031f0:	0586c683          	lbu	a3,88(a3)
    800031f4:	00d7f5b3          	and	a1,a5,a3
    800031f8:	cd91                	beqz	a1,80003214 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031fa:	2605                	addiw	a2,a2,1
    800031fc:	2485                	addiw	s1,s1,1
    800031fe:	fd4618e3          	bne	a2,s4,800031ce <balloc+0x80>
    80003202:	b759                	j	80003188 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003204:	00005517          	auipc	a0,0x5
    80003208:	4a450513          	addi	a0,a0,1188 # 800086a8 <sysnames+0x108>
    8000320c:	ffffd097          	auipc	ra,0xffffd
    80003210:	33c080e7          	jalr	828(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003214:	974a                	add	a4,a4,s2
    80003216:	8fd5                	or	a5,a5,a3
    80003218:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000321c:	854a                	mv	a0,s2
    8000321e:	00001097          	auipc	ra,0x1
    80003222:	002080e7          	jalr	2(ra) # 80004220 <log_write>
        brelse(bp);
    80003226:	854a                	mv	a0,s2
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	d94080e7          	jalr	-620(ra) # 80002fbc <brelse>
  bp = bread(dev, bno);
    80003230:	85a6                	mv	a1,s1
    80003232:	855e                	mv	a0,s7
    80003234:	00000097          	auipc	ra,0x0
    80003238:	c58080e7          	jalr	-936(ra) # 80002e8c <bread>
    8000323c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000323e:	40000613          	li	a2,1024
    80003242:	4581                	li	a1,0
    80003244:	05850513          	addi	a0,a0,88
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	ac4080e7          	jalr	-1340(ra) # 80000d0c <memset>
  log_write(bp);
    80003250:	854a                	mv	a0,s2
    80003252:	00001097          	auipc	ra,0x1
    80003256:	fce080e7          	jalr	-50(ra) # 80004220 <log_write>
  brelse(bp);
    8000325a:	854a                	mv	a0,s2
    8000325c:	00000097          	auipc	ra,0x0
    80003260:	d60080e7          	jalr	-672(ra) # 80002fbc <brelse>
}
    80003264:	8526                	mv	a0,s1
    80003266:	60e6                	ld	ra,88(sp)
    80003268:	6446                	ld	s0,80(sp)
    8000326a:	64a6                	ld	s1,72(sp)
    8000326c:	6906                	ld	s2,64(sp)
    8000326e:	79e2                	ld	s3,56(sp)
    80003270:	7a42                	ld	s4,48(sp)
    80003272:	7aa2                	ld	s5,40(sp)
    80003274:	7b02                	ld	s6,32(sp)
    80003276:	6be2                	ld	s7,24(sp)
    80003278:	6c42                	ld	s8,16(sp)
    8000327a:	6ca2                	ld	s9,8(sp)
    8000327c:	6125                	addi	sp,sp,96
    8000327e:	8082                	ret

0000000080003280 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003280:	7179                	addi	sp,sp,-48
    80003282:	f406                	sd	ra,40(sp)
    80003284:	f022                	sd	s0,32(sp)
    80003286:	ec26                	sd	s1,24(sp)
    80003288:	e84a                	sd	s2,16(sp)
    8000328a:	e44e                	sd	s3,8(sp)
    8000328c:	e052                	sd	s4,0(sp)
    8000328e:	1800                	addi	s0,sp,48
    80003290:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003292:	47ad                	li	a5,11
    80003294:	04b7fe63          	bgeu	a5,a1,800032f0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003298:	ff45849b          	addiw	s1,a1,-12
    8000329c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032a0:	0ff00793          	li	a5,255
    800032a4:	0ae7e363          	bltu	a5,a4,8000334a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032a8:	08052583          	lw	a1,128(a0)
    800032ac:	c5ad                	beqz	a1,80003316 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800032ae:	00092503          	lw	a0,0(s2)
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	bda080e7          	jalr	-1062(ra) # 80002e8c <bread>
    800032ba:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032bc:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032c0:	02049593          	slli	a1,s1,0x20
    800032c4:	9181                	srli	a1,a1,0x20
    800032c6:	058a                	slli	a1,a1,0x2
    800032c8:	00b784b3          	add	s1,a5,a1
    800032cc:	0004a983          	lw	s3,0(s1)
    800032d0:	04098d63          	beqz	s3,8000332a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800032d4:	8552                	mv	a0,s4
    800032d6:	00000097          	auipc	ra,0x0
    800032da:	ce6080e7          	jalr	-794(ra) # 80002fbc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032de:	854e                	mv	a0,s3
    800032e0:	70a2                	ld	ra,40(sp)
    800032e2:	7402                	ld	s0,32(sp)
    800032e4:	64e2                	ld	s1,24(sp)
    800032e6:	6942                	ld	s2,16(sp)
    800032e8:	69a2                	ld	s3,8(sp)
    800032ea:	6a02                	ld	s4,0(sp)
    800032ec:	6145                	addi	sp,sp,48
    800032ee:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032f0:	02059493          	slli	s1,a1,0x20
    800032f4:	9081                	srli	s1,s1,0x20
    800032f6:	048a                	slli	s1,s1,0x2
    800032f8:	94aa                	add	s1,s1,a0
    800032fa:	0504a983          	lw	s3,80(s1)
    800032fe:	fe0990e3          	bnez	s3,800032de <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003302:	4108                	lw	a0,0(a0)
    80003304:	00000097          	auipc	ra,0x0
    80003308:	e4a080e7          	jalr	-438(ra) # 8000314e <balloc>
    8000330c:	0005099b          	sext.w	s3,a0
    80003310:	0534a823          	sw	s3,80(s1)
    80003314:	b7e9                	j	800032de <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003316:	4108                	lw	a0,0(a0)
    80003318:	00000097          	auipc	ra,0x0
    8000331c:	e36080e7          	jalr	-458(ra) # 8000314e <balloc>
    80003320:	0005059b          	sext.w	a1,a0
    80003324:	08b92023          	sw	a1,128(s2)
    80003328:	b759                	j	800032ae <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000332a:	00092503          	lw	a0,0(s2)
    8000332e:	00000097          	auipc	ra,0x0
    80003332:	e20080e7          	jalr	-480(ra) # 8000314e <balloc>
    80003336:	0005099b          	sext.w	s3,a0
    8000333a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000333e:	8552                	mv	a0,s4
    80003340:	00001097          	auipc	ra,0x1
    80003344:	ee0080e7          	jalr	-288(ra) # 80004220 <log_write>
    80003348:	b771                	j	800032d4 <bmap+0x54>
  panic("bmap: out of range");
    8000334a:	00005517          	auipc	a0,0x5
    8000334e:	37650513          	addi	a0,a0,886 # 800086c0 <sysnames+0x120>
    80003352:	ffffd097          	auipc	ra,0xffffd
    80003356:	1f6080e7          	jalr	502(ra) # 80000548 <panic>

000000008000335a <iget>:
{
    8000335a:	7179                	addi	sp,sp,-48
    8000335c:	f406                	sd	ra,40(sp)
    8000335e:	f022                	sd	s0,32(sp)
    80003360:	ec26                	sd	s1,24(sp)
    80003362:	e84a                	sd	s2,16(sp)
    80003364:	e44e                	sd	s3,8(sp)
    80003366:	e052                	sd	s4,0(sp)
    80003368:	1800                	addi	s0,sp,48
    8000336a:	89aa                	mv	s3,a0
    8000336c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000336e:	0001d517          	auipc	a0,0x1d
    80003372:	cf250513          	addi	a0,a0,-782 # 80020060 <icache>
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	89a080e7          	jalr	-1894(ra) # 80000c10 <acquire>
  empty = 0;
    8000337e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003380:	0001d497          	auipc	s1,0x1d
    80003384:	cf848493          	addi	s1,s1,-776 # 80020078 <icache+0x18>
    80003388:	0001e697          	auipc	a3,0x1e
    8000338c:	78068693          	addi	a3,a3,1920 # 80021b08 <log>
    80003390:	a039                	j	8000339e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003392:	02090b63          	beqz	s2,800033c8 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003396:	08848493          	addi	s1,s1,136
    8000339a:	02d48a63          	beq	s1,a3,800033ce <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000339e:	449c                	lw	a5,8(s1)
    800033a0:	fef059e3          	blez	a5,80003392 <iget+0x38>
    800033a4:	4098                	lw	a4,0(s1)
    800033a6:	ff3716e3          	bne	a4,s3,80003392 <iget+0x38>
    800033aa:	40d8                	lw	a4,4(s1)
    800033ac:	ff4713e3          	bne	a4,s4,80003392 <iget+0x38>
      ip->ref++;
    800033b0:	2785                	addiw	a5,a5,1
    800033b2:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800033b4:	0001d517          	auipc	a0,0x1d
    800033b8:	cac50513          	addi	a0,a0,-852 # 80020060 <icache>
    800033bc:	ffffe097          	auipc	ra,0xffffe
    800033c0:	908080e7          	jalr	-1784(ra) # 80000cc4 <release>
      return ip;
    800033c4:	8926                	mv	s2,s1
    800033c6:	a03d                	j	800033f4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033c8:	f7f9                	bnez	a5,80003396 <iget+0x3c>
    800033ca:	8926                	mv	s2,s1
    800033cc:	b7e9                	j	80003396 <iget+0x3c>
  if(empty == 0)
    800033ce:	02090c63          	beqz	s2,80003406 <iget+0xac>
  ip->dev = dev;
    800033d2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033d6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033da:	4785                	li	a5,1
    800033dc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033e0:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800033e4:	0001d517          	auipc	a0,0x1d
    800033e8:	c7c50513          	addi	a0,a0,-900 # 80020060 <icache>
    800033ec:	ffffe097          	auipc	ra,0xffffe
    800033f0:	8d8080e7          	jalr	-1832(ra) # 80000cc4 <release>
}
    800033f4:	854a                	mv	a0,s2
    800033f6:	70a2                	ld	ra,40(sp)
    800033f8:	7402                	ld	s0,32(sp)
    800033fa:	64e2                	ld	s1,24(sp)
    800033fc:	6942                	ld	s2,16(sp)
    800033fe:	69a2                	ld	s3,8(sp)
    80003400:	6a02                	ld	s4,0(sp)
    80003402:	6145                	addi	sp,sp,48
    80003404:	8082                	ret
    panic("iget: no inodes");
    80003406:	00005517          	auipc	a0,0x5
    8000340a:	2d250513          	addi	a0,a0,722 # 800086d8 <sysnames+0x138>
    8000340e:	ffffd097          	auipc	ra,0xffffd
    80003412:	13a080e7          	jalr	314(ra) # 80000548 <panic>

0000000080003416 <fsinit>:
fsinit(int dev) {
    80003416:	7179                	addi	sp,sp,-48
    80003418:	f406                	sd	ra,40(sp)
    8000341a:	f022                	sd	s0,32(sp)
    8000341c:	ec26                	sd	s1,24(sp)
    8000341e:	e84a                	sd	s2,16(sp)
    80003420:	e44e                	sd	s3,8(sp)
    80003422:	1800                	addi	s0,sp,48
    80003424:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003426:	4585                	li	a1,1
    80003428:	00000097          	auipc	ra,0x0
    8000342c:	a64080e7          	jalr	-1436(ra) # 80002e8c <bread>
    80003430:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003432:	0001d997          	auipc	s3,0x1d
    80003436:	c0e98993          	addi	s3,s3,-1010 # 80020040 <sb>
    8000343a:	02000613          	li	a2,32
    8000343e:	05850593          	addi	a1,a0,88
    80003442:	854e                	mv	a0,s3
    80003444:	ffffe097          	auipc	ra,0xffffe
    80003448:	928080e7          	jalr	-1752(ra) # 80000d6c <memmove>
  brelse(bp);
    8000344c:	8526                	mv	a0,s1
    8000344e:	00000097          	auipc	ra,0x0
    80003452:	b6e080e7          	jalr	-1170(ra) # 80002fbc <brelse>
  if(sb.magic != FSMAGIC)
    80003456:	0009a703          	lw	a4,0(s3)
    8000345a:	102037b7          	lui	a5,0x10203
    8000345e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003462:	02f71263          	bne	a4,a5,80003486 <fsinit+0x70>
  initlog(dev, &sb);
    80003466:	0001d597          	auipc	a1,0x1d
    8000346a:	bda58593          	addi	a1,a1,-1062 # 80020040 <sb>
    8000346e:	854a                	mv	a0,s2
    80003470:	00001097          	auipc	ra,0x1
    80003474:	b38080e7          	jalr	-1224(ra) # 80003fa8 <initlog>
}
    80003478:	70a2                	ld	ra,40(sp)
    8000347a:	7402                	ld	s0,32(sp)
    8000347c:	64e2                	ld	s1,24(sp)
    8000347e:	6942                	ld	s2,16(sp)
    80003480:	69a2                	ld	s3,8(sp)
    80003482:	6145                	addi	sp,sp,48
    80003484:	8082                	ret
    panic("invalid file system");
    80003486:	00005517          	auipc	a0,0x5
    8000348a:	26250513          	addi	a0,a0,610 # 800086e8 <sysnames+0x148>
    8000348e:	ffffd097          	auipc	ra,0xffffd
    80003492:	0ba080e7          	jalr	186(ra) # 80000548 <panic>

0000000080003496 <iinit>:
{
    80003496:	7179                	addi	sp,sp,-48
    80003498:	f406                	sd	ra,40(sp)
    8000349a:	f022                	sd	s0,32(sp)
    8000349c:	ec26                	sd	s1,24(sp)
    8000349e:	e84a                	sd	s2,16(sp)
    800034a0:	e44e                	sd	s3,8(sp)
    800034a2:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800034a4:	00005597          	auipc	a1,0x5
    800034a8:	25c58593          	addi	a1,a1,604 # 80008700 <sysnames+0x160>
    800034ac:	0001d517          	auipc	a0,0x1d
    800034b0:	bb450513          	addi	a0,a0,-1100 # 80020060 <icache>
    800034b4:	ffffd097          	auipc	ra,0xffffd
    800034b8:	6cc080e7          	jalr	1740(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034bc:	0001d497          	auipc	s1,0x1d
    800034c0:	bcc48493          	addi	s1,s1,-1076 # 80020088 <icache+0x28>
    800034c4:	0001e997          	auipc	s3,0x1e
    800034c8:	65498993          	addi	s3,s3,1620 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800034cc:	00005917          	auipc	s2,0x5
    800034d0:	23c90913          	addi	s2,s2,572 # 80008708 <sysnames+0x168>
    800034d4:	85ca                	mv	a1,s2
    800034d6:	8526                	mv	a0,s1
    800034d8:	00001097          	auipc	ra,0x1
    800034dc:	e36080e7          	jalr	-458(ra) # 8000430e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034e0:	08848493          	addi	s1,s1,136
    800034e4:	ff3498e3          	bne	s1,s3,800034d4 <iinit+0x3e>
}
    800034e8:	70a2                	ld	ra,40(sp)
    800034ea:	7402                	ld	s0,32(sp)
    800034ec:	64e2                	ld	s1,24(sp)
    800034ee:	6942                	ld	s2,16(sp)
    800034f0:	69a2                	ld	s3,8(sp)
    800034f2:	6145                	addi	sp,sp,48
    800034f4:	8082                	ret

00000000800034f6 <ialloc>:
{
    800034f6:	715d                	addi	sp,sp,-80
    800034f8:	e486                	sd	ra,72(sp)
    800034fa:	e0a2                	sd	s0,64(sp)
    800034fc:	fc26                	sd	s1,56(sp)
    800034fe:	f84a                	sd	s2,48(sp)
    80003500:	f44e                	sd	s3,40(sp)
    80003502:	f052                	sd	s4,32(sp)
    80003504:	ec56                	sd	s5,24(sp)
    80003506:	e85a                	sd	s6,16(sp)
    80003508:	e45e                	sd	s7,8(sp)
    8000350a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000350c:	0001d717          	auipc	a4,0x1d
    80003510:	b4072703          	lw	a4,-1216(a4) # 8002004c <sb+0xc>
    80003514:	4785                	li	a5,1
    80003516:	04e7fa63          	bgeu	a5,a4,8000356a <ialloc+0x74>
    8000351a:	8aaa                	mv	s5,a0
    8000351c:	8bae                	mv	s7,a1
    8000351e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003520:	0001da17          	auipc	s4,0x1d
    80003524:	b20a0a13          	addi	s4,s4,-1248 # 80020040 <sb>
    80003528:	00048b1b          	sext.w	s6,s1
    8000352c:	0044d593          	srli	a1,s1,0x4
    80003530:	018a2783          	lw	a5,24(s4)
    80003534:	9dbd                	addw	a1,a1,a5
    80003536:	8556                	mv	a0,s5
    80003538:	00000097          	auipc	ra,0x0
    8000353c:	954080e7          	jalr	-1708(ra) # 80002e8c <bread>
    80003540:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003542:	05850993          	addi	s3,a0,88
    80003546:	00f4f793          	andi	a5,s1,15
    8000354a:	079a                	slli	a5,a5,0x6
    8000354c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000354e:	00099783          	lh	a5,0(s3)
    80003552:	c785                	beqz	a5,8000357a <ialloc+0x84>
    brelse(bp);
    80003554:	00000097          	auipc	ra,0x0
    80003558:	a68080e7          	jalr	-1432(ra) # 80002fbc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000355c:	0485                	addi	s1,s1,1
    8000355e:	00ca2703          	lw	a4,12(s4)
    80003562:	0004879b          	sext.w	a5,s1
    80003566:	fce7e1e3          	bltu	a5,a4,80003528 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000356a:	00005517          	auipc	a0,0x5
    8000356e:	1a650513          	addi	a0,a0,422 # 80008710 <sysnames+0x170>
    80003572:	ffffd097          	auipc	ra,0xffffd
    80003576:	fd6080e7          	jalr	-42(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    8000357a:	04000613          	li	a2,64
    8000357e:	4581                	li	a1,0
    80003580:	854e                	mv	a0,s3
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	78a080e7          	jalr	1930(ra) # 80000d0c <memset>
      dip->type = type;
    8000358a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000358e:	854a                	mv	a0,s2
    80003590:	00001097          	auipc	ra,0x1
    80003594:	c90080e7          	jalr	-880(ra) # 80004220 <log_write>
      brelse(bp);
    80003598:	854a                	mv	a0,s2
    8000359a:	00000097          	auipc	ra,0x0
    8000359e:	a22080e7          	jalr	-1502(ra) # 80002fbc <brelse>
      return iget(dev, inum);
    800035a2:	85da                	mv	a1,s6
    800035a4:	8556                	mv	a0,s5
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	db4080e7          	jalr	-588(ra) # 8000335a <iget>
}
    800035ae:	60a6                	ld	ra,72(sp)
    800035b0:	6406                	ld	s0,64(sp)
    800035b2:	74e2                	ld	s1,56(sp)
    800035b4:	7942                	ld	s2,48(sp)
    800035b6:	79a2                	ld	s3,40(sp)
    800035b8:	7a02                	ld	s4,32(sp)
    800035ba:	6ae2                	ld	s5,24(sp)
    800035bc:	6b42                	ld	s6,16(sp)
    800035be:	6ba2                	ld	s7,8(sp)
    800035c0:	6161                	addi	sp,sp,80
    800035c2:	8082                	ret

00000000800035c4 <iupdate>:
{
    800035c4:	1101                	addi	sp,sp,-32
    800035c6:	ec06                	sd	ra,24(sp)
    800035c8:	e822                	sd	s0,16(sp)
    800035ca:	e426                	sd	s1,8(sp)
    800035cc:	e04a                	sd	s2,0(sp)
    800035ce:	1000                	addi	s0,sp,32
    800035d0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035d2:	415c                	lw	a5,4(a0)
    800035d4:	0047d79b          	srliw	a5,a5,0x4
    800035d8:	0001d597          	auipc	a1,0x1d
    800035dc:	a805a583          	lw	a1,-1408(a1) # 80020058 <sb+0x18>
    800035e0:	9dbd                	addw	a1,a1,a5
    800035e2:	4108                	lw	a0,0(a0)
    800035e4:	00000097          	auipc	ra,0x0
    800035e8:	8a8080e7          	jalr	-1880(ra) # 80002e8c <bread>
    800035ec:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035ee:	05850793          	addi	a5,a0,88
    800035f2:	40c8                	lw	a0,4(s1)
    800035f4:	893d                	andi	a0,a0,15
    800035f6:	051a                	slli	a0,a0,0x6
    800035f8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800035fa:	04449703          	lh	a4,68(s1)
    800035fe:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003602:	04649703          	lh	a4,70(s1)
    80003606:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000360a:	04849703          	lh	a4,72(s1)
    8000360e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003612:	04a49703          	lh	a4,74(s1)
    80003616:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000361a:	44f8                	lw	a4,76(s1)
    8000361c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000361e:	03400613          	li	a2,52
    80003622:	05048593          	addi	a1,s1,80
    80003626:	0531                	addi	a0,a0,12
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	744080e7          	jalr	1860(ra) # 80000d6c <memmove>
  log_write(bp);
    80003630:	854a                	mv	a0,s2
    80003632:	00001097          	auipc	ra,0x1
    80003636:	bee080e7          	jalr	-1042(ra) # 80004220 <log_write>
  brelse(bp);
    8000363a:	854a                	mv	a0,s2
    8000363c:	00000097          	auipc	ra,0x0
    80003640:	980080e7          	jalr	-1664(ra) # 80002fbc <brelse>
}
    80003644:	60e2                	ld	ra,24(sp)
    80003646:	6442                	ld	s0,16(sp)
    80003648:	64a2                	ld	s1,8(sp)
    8000364a:	6902                	ld	s2,0(sp)
    8000364c:	6105                	addi	sp,sp,32
    8000364e:	8082                	ret

0000000080003650 <idup>:
{
    80003650:	1101                	addi	sp,sp,-32
    80003652:	ec06                	sd	ra,24(sp)
    80003654:	e822                	sd	s0,16(sp)
    80003656:	e426                	sd	s1,8(sp)
    80003658:	1000                	addi	s0,sp,32
    8000365a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000365c:	0001d517          	auipc	a0,0x1d
    80003660:	a0450513          	addi	a0,a0,-1532 # 80020060 <icache>
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	5ac080e7          	jalr	1452(ra) # 80000c10 <acquire>
  ip->ref++;
    8000366c:	449c                	lw	a5,8(s1)
    8000366e:	2785                	addiw	a5,a5,1
    80003670:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003672:	0001d517          	auipc	a0,0x1d
    80003676:	9ee50513          	addi	a0,a0,-1554 # 80020060 <icache>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	64a080e7          	jalr	1610(ra) # 80000cc4 <release>
}
    80003682:	8526                	mv	a0,s1
    80003684:	60e2                	ld	ra,24(sp)
    80003686:	6442                	ld	s0,16(sp)
    80003688:	64a2                	ld	s1,8(sp)
    8000368a:	6105                	addi	sp,sp,32
    8000368c:	8082                	ret

000000008000368e <ilock>:
{
    8000368e:	1101                	addi	sp,sp,-32
    80003690:	ec06                	sd	ra,24(sp)
    80003692:	e822                	sd	s0,16(sp)
    80003694:	e426                	sd	s1,8(sp)
    80003696:	e04a                	sd	s2,0(sp)
    80003698:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000369a:	c115                	beqz	a0,800036be <ilock+0x30>
    8000369c:	84aa                	mv	s1,a0
    8000369e:	451c                	lw	a5,8(a0)
    800036a0:	00f05f63          	blez	a5,800036be <ilock+0x30>
  acquiresleep(&ip->lock);
    800036a4:	0541                	addi	a0,a0,16
    800036a6:	00001097          	auipc	ra,0x1
    800036aa:	ca2080e7          	jalr	-862(ra) # 80004348 <acquiresleep>
  if(ip->valid == 0){
    800036ae:	40bc                	lw	a5,64(s1)
    800036b0:	cf99                	beqz	a5,800036ce <ilock+0x40>
}
    800036b2:	60e2                	ld	ra,24(sp)
    800036b4:	6442                	ld	s0,16(sp)
    800036b6:	64a2                	ld	s1,8(sp)
    800036b8:	6902                	ld	s2,0(sp)
    800036ba:	6105                	addi	sp,sp,32
    800036bc:	8082                	ret
    panic("ilock");
    800036be:	00005517          	auipc	a0,0x5
    800036c2:	06a50513          	addi	a0,a0,106 # 80008728 <sysnames+0x188>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	e82080e7          	jalr	-382(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036ce:	40dc                	lw	a5,4(s1)
    800036d0:	0047d79b          	srliw	a5,a5,0x4
    800036d4:	0001d597          	auipc	a1,0x1d
    800036d8:	9845a583          	lw	a1,-1660(a1) # 80020058 <sb+0x18>
    800036dc:	9dbd                	addw	a1,a1,a5
    800036de:	4088                	lw	a0,0(s1)
    800036e0:	fffff097          	auipc	ra,0xfffff
    800036e4:	7ac080e7          	jalr	1964(ra) # 80002e8c <bread>
    800036e8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036ea:	05850593          	addi	a1,a0,88
    800036ee:	40dc                	lw	a5,4(s1)
    800036f0:	8bbd                	andi	a5,a5,15
    800036f2:	079a                	slli	a5,a5,0x6
    800036f4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036f6:	00059783          	lh	a5,0(a1)
    800036fa:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036fe:	00259783          	lh	a5,2(a1)
    80003702:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003706:	00459783          	lh	a5,4(a1)
    8000370a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000370e:	00659783          	lh	a5,6(a1)
    80003712:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003716:	459c                	lw	a5,8(a1)
    80003718:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000371a:	03400613          	li	a2,52
    8000371e:	05b1                	addi	a1,a1,12
    80003720:	05048513          	addi	a0,s1,80
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	648080e7          	jalr	1608(ra) # 80000d6c <memmove>
    brelse(bp);
    8000372c:	854a                	mv	a0,s2
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	88e080e7          	jalr	-1906(ra) # 80002fbc <brelse>
    ip->valid = 1;
    80003736:	4785                	li	a5,1
    80003738:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000373a:	04449783          	lh	a5,68(s1)
    8000373e:	fbb5                	bnez	a5,800036b2 <ilock+0x24>
      panic("ilock: no type");
    80003740:	00005517          	auipc	a0,0x5
    80003744:	ff050513          	addi	a0,a0,-16 # 80008730 <sysnames+0x190>
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	e00080e7          	jalr	-512(ra) # 80000548 <panic>

0000000080003750 <iunlock>:
{
    80003750:	1101                	addi	sp,sp,-32
    80003752:	ec06                	sd	ra,24(sp)
    80003754:	e822                	sd	s0,16(sp)
    80003756:	e426                	sd	s1,8(sp)
    80003758:	e04a                	sd	s2,0(sp)
    8000375a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000375c:	c905                	beqz	a0,8000378c <iunlock+0x3c>
    8000375e:	84aa                	mv	s1,a0
    80003760:	01050913          	addi	s2,a0,16
    80003764:	854a                	mv	a0,s2
    80003766:	00001097          	auipc	ra,0x1
    8000376a:	c7c080e7          	jalr	-900(ra) # 800043e2 <holdingsleep>
    8000376e:	cd19                	beqz	a0,8000378c <iunlock+0x3c>
    80003770:	449c                	lw	a5,8(s1)
    80003772:	00f05d63          	blez	a5,8000378c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003776:	854a                	mv	a0,s2
    80003778:	00001097          	auipc	ra,0x1
    8000377c:	c26080e7          	jalr	-986(ra) # 8000439e <releasesleep>
}
    80003780:	60e2                	ld	ra,24(sp)
    80003782:	6442                	ld	s0,16(sp)
    80003784:	64a2                	ld	s1,8(sp)
    80003786:	6902                	ld	s2,0(sp)
    80003788:	6105                	addi	sp,sp,32
    8000378a:	8082                	ret
    panic("iunlock");
    8000378c:	00005517          	auipc	a0,0x5
    80003790:	fb450513          	addi	a0,a0,-76 # 80008740 <sysnames+0x1a0>
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	db4080e7          	jalr	-588(ra) # 80000548 <panic>

000000008000379c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000379c:	7179                	addi	sp,sp,-48
    8000379e:	f406                	sd	ra,40(sp)
    800037a0:	f022                	sd	s0,32(sp)
    800037a2:	ec26                	sd	s1,24(sp)
    800037a4:	e84a                	sd	s2,16(sp)
    800037a6:	e44e                	sd	s3,8(sp)
    800037a8:	e052                	sd	s4,0(sp)
    800037aa:	1800                	addi	s0,sp,48
    800037ac:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037ae:	05050493          	addi	s1,a0,80
    800037b2:	08050913          	addi	s2,a0,128
    800037b6:	a021                	j	800037be <itrunc+0x22>
    800037b8:	0491                	addi	s1,s1,4
    800037ba:	01248d63          	beq	s1,s2,800037d4 <itrunc+0x38>
    if(ip->addrs[i]){
    800037be:	408c                	lw	a1,0(s1)
    800037c0:	dde5                	beqz	a1,800037b8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037c2:	0009a503          	lw	a0,0(s3)
    800037c6:	00000097          	auipc	ra,0x0
    800037ca:	90c080e7          	jalr	-1780(ra) # 800030d2 <bfree>
      ip->addrs[i] = 0;
    800037ce:	0004a023          	sw	zero,0(s1)
    800037d2:	b7dd                	j	800037b8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037d4:	0809a583          	lw	a1,128(s3)
    800037d8:	e185                	bnez	a1,800037f8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037da:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037de:	854e                	mv	a0,s3
    800037e0:	00000097          	auipc	ra,0x0
    800037e4:	de4080e7          	jalr	-540(ra) # 800035c4 <iupdate>
}
    800037e8:	70a2                	ld	ra,40(sp)
    800037ea:	7402                	ld	s0,32(sp)
    800037ec:	64e2                	ld	s1,24(sp)
    800037ee:	6942                	ld	s2,16(sp)
    800037f0:	69a2                	ld	s3,8(sp)
    800037f2:	6a02                	ld	s4,0(sp)
    800037f4:	6145                	addi	sp,sp,48
    800037f6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037f8:	0009a503          	lw	a0,0(s3)
    800037fc:	fffff097          	auipc	ra,0xfffff
    80003800:	690080e7          	jalr	1680(ra) # 80002e8c <bread>
    80003804:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003806:	05850493          	addi	s1,a0,88
    8000380a:	45850913          	addi	s2,a0,1112
    8000380e:	a811                	j	80003822 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003810:	0009a503          	lw	a0,0(s3)
    80003814:	00000097          	auipc	ra,0x0
    80003818:	8be080e7          	jalr	-1858(ra) # 800030d2 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000381c:	0491                	addi	s1,s1,4
    8000381e:	01248563          	beq	s1,s2,80003828 <itrunc+0x8c>
      if(a[j])
    80003822:	408c                	lw	a1,0(s1)
    80003824:	dde5                	beqz	a1,8000381c <itrunc+0x80>
    80003826:	b7ed                	j	80003810 <itrunc+0x74>
    brelse(bp);
    80003828:	8552                	mv	a0,s4
    8000382a:	fffff097          	auipc	ra,0xfffff
    8000382e:	792080e7          	jalr	1938(ra) # 80002fbc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003832:	0809a583          	lw	a1,128(s3)
    80003836:	0009a503          	lw	a0,0(s3)
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	898080e7          	jalr	-1896(ra) # 800030d2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003842:	0809a023          	sw	zero,128(s3)
    80003846:	bf51                	j	800037da <itrunc+0x3e>

0000000080003848 <iput>:
{
    80003848:	1101                	addi	sp,sp,-32
    8000384a:	ec06                	sd	ra,24(sp)
    8000384c:	e822                	sd	s0,16(sp)
    8000384e:	e426                	sd	s1,8(sp)
    80003850:	e04a                	sd	s2,0(sp)
    80003852:	1000                	addi	s0,sp,32
    80003854:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003856:	0001d517          	auipc	a0,0x1d
    8000385a:	80a50513          	addi	a0,a0,-2038 # 80020060 <icache>
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	3b2080e7          	jalr	946(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003866:	4498                	lw	a4,8(s1)
    80003868:	4785                	li	a5,1
    8000386a:	02f70363          	beq	a4,a5,80003890 <iput+0x48>
  ip->ref--;
    8000386e:	449c                	lw	a5,8(s1)
    80003870:	37fd                	addiw	a5,a5,-1
    80003872:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003874:	0001c517          	auipc	a0,0x1c
    80003878:	7ec50513          	addi	a0,a0,2028 # 80020060 <icache>
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	448080e7          	jalr	1096(ra) # 80000cc4 <release>
}
    80003884:	60e2                	ld	ra,24(sp)
    80003886:	6442                	ld	s0,16(sp)
    80003888:	64a2                	ld	s1,8(sp)
    8000388a:	6902                	ld	s2,0(sp)
    8000388c:	6105                	addi	sp,sp,32
    8000388e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003890:	40bc                	lw	a5,64(s1)
    80003892:	dff1                	beqz	a5,8000386e <iput+0x26>
    80003894:	04a49783          	lh	a5,74(s1)
    80003898:	fbf9                	bnez	a5,8000386e <iput+0x26>
    acquiresleep(&ip->lock);
    8000389a:	01048913          	addi	s2,s1,16
    8000389e:	854a                	mv	a0,s2
    800038a0:	00001097          	auipc	ra,0x1
    800038a4:	aa8080e7          	jalr	-1368(ra) # 80004348 <acquiresleep>
    release(&icache.lock);
    800038a8:	0001c517          	auipc	a0,0x1c
    800038ac:	7b850513          	addi	a0,a0,1976 # 80020060 <icache>
    800038b0:	ffffd097          	auipc	ra,0xffffd
    800038b4:	414080e7          	jalr	1044(ra) # 80000cc4 <release>
    itrunc(ip);
    800038b8:	8526                	mv	a0,s1
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	ee2080e7          	jalr	-286(ra) # 8000379c <itrunc>
    ip->type = 0;
    800038c2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038c6:	8526                	mv	a0,s1
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	cfc080e7          	jalr	-772(ra) # 800035c4 <iupdate>
    ip->valid = 0;
    800038d0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038d4:	854a                	mv	a0,s2
    800038d6:	00001097          	auipc	ra,0x1
    800038da:	ac8080e7          	jalr	-1336(ra) # 8000439e <releasesleep>
    acquire(&icache.lock);
    800038de:	0001c517          	auipc	a0,0x1c
    800038e2:	78250513          	addi	a0,a0,1922 # 80020060 <icache>
    800038e6:	ffffd097          	auipc	ra,0xffffd
    800038ea:	32a080e7          	jalr	810(ra) # 80000c10 <acquire>
    800038ee:	b741                	j	8000386e <iput+0x26>

00000000800038f0 <iunlockput>:
{
    800038f0:	1101                	addi	sp,sp,-32
    800038f2:	ec06                	sd	ra,24(sp)
    800038f4:	e822                	sd	s0,16(sp)
    800038f6:	e426                	sd	s1,8(sp)
    800038f8:	1000                	addi	s0,sp,32
    800038fa:	84aa                	mv	s1,a0
  iunlock(ip);
    800038fc:	00000097          	auipc	ra,0x0
    80003900:	e54080e7          	jalr	-428(ra) # 80003750 <iunlock>
  iput(ip);
    80003904:	8526                	mv	a0,s1
    80003906:	00000097          	auipc	ra,0x0
    8000390a:	f42080e7          	jalr	-190(ra) # 80003848 <iput>
}
    8000390e:	60e2                	ld	ra,24(sp)
    80003910:	6442                	ld	s0,16(sp)
    80003912:	64a2                	ld	s1,8(sp)
    80003914:	6105                	addi	sp,sp,32
    80003916:	8082                	ret

0000000080003918 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003918:	1141                	addi	sp,sp,-16
    8000391a:	e422                	sd	s0,8(sp)
    8000391c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000391e:	411c                	lw	a5,0(a0)
    80003920:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003922:	415c                	lw	a5,4(a0)
    80003924:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003926:	04451783          	lh	a5,68(a0)
    8000392a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000392e:	04a51783          	lh	a5,74(a0)
    80003932:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003936:	04c56783          	lwu	a5,76(a0)
    8000393a:	e99c                	sd	a5,16(a1)
}
    8000393c:	6422                	ld	s0,8(sp)
    8000393e:	0141                	addi	sp,sp,16
    80003940:	8082                	ret

0000000080003942 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003942:	457c                	lw	a5,76(a0)
    80003944:	0ed7e863          	bltu	a5,a3,80003a34 <readi+0xf2>
{
    80003948:	7159                	addi	sp,sp,-112
    8000394a:	f486                	sd	ra,104(sp)
    8000394c:	f0a2                	sd	s0,96(sp)
    8000394e:	eca6                	sd	s1,88(sp)
    80003950:	e8ca                	sd	s2,80(sp)
    80003952:	e4ce                	sd	s3,72(sp)
    80003954:	e0d2                	sd	s4,64(sp)
    80003956:	fc56                	sd	s5,56(sp)
    80003958:	f85a                	sd	s6,48(sp)
    8000395a:	f45e                	sd	s7,40(sp)
    8000395c:	f062                	sd	s8,32(sp)
    8000395e:	ec66                	sd	s9,24(sp)
    80003960:	e86a                	sd	s10,16(sp)
    80003962:	e46e                	sd	s11,8(sp)
    80003964:	1880                	addi	s0,sp,112
    80003966:	8baa                	mv	s7,a0
    80003968:	8c2e                	mv	s8,a1
    8000396a:	8ab2                	mv	s5,a2
    8000396c:	84b6                	mv	s1,a3
    8000396e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003970:	9f35                	addw	a4,a4,a3
    return 0;
    80003972:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003974:	08d76f63          	bltu	a4,a3,80003a12 <readi+0xd0>
  if(off + n > ip->size)
    80003978:	00e7f463          	bgeu	a5,a4,80003980 <readi+0x3e>
    n = ip->size - off;
    8000397c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003980:	0a0b0863          	beqz	s6,80003a30 <readi+0xee>
    80003984:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003986:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000398a:	5cfd                	li	s9,-1
    8000398c:	a82d                	j	800039c6 <readi+0x84>
    8000398e:	020a1d93          	slli	s11,s4,0x20
    80003992:	020ddd93          	srli	s11,s11,0x20
    80003996:	05890613          	addi	a2,s2,88
    8000399a:	86ee                	mv	a3,s11
    8000399c:	963a                	add	a2,a2,a4
    8000399e:	85d6                	mv	a1,s5
    800039a0:	8562                	mv	a0,s8
    800039a2:	fffff097          	auipc	ra,0xfffff
    800039a6:	ab6080e7          	jalr	-1354(ra) # 80002458 <either_copyout>
    800039aa:	05950d63          	beq	a0,s9,80003a04 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    800039ae:	854a                	mv	a0,s2
    800039b0:	fffff097          	auipc	ra,0xfffff
    800039b4:	60c080e7          	jalr	1548(ra) # 80002fbc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039b8:	013a09bb          	addw	s3,s4,s3
    800039bc:	009a04bb          	addw	s1,s4,s1
    800039c0:	9aee                	add	s5,s5,s11
    800039c2:	0569f663          	bgeu	s3,s6,80003a0e <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039c6:	000ba903          	lw	s2,0(s7)
    800039ca:	00a4d59b          	srliw	a1,s1,0xa
    800039ce:	855e                	mv	a0,s7
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	8b0080e7          	jalr	-1872(ra) # 80003280 <bmap>
    800039d8:	0005059b          	sext.w	a1,a0
    800039dc:	854a                	mv	a0,s2
    800039de:	fffff097          	auipc	ra,0xfffff
    800039e2:	4ae080e7          	jalr	1198(ra) # 80002e8c <bread>
    800039e6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039e8:	3ff4f713          	andi	a4,s1,1023
    800039ec:	40ed07bb          	subw	a5,s10,a4
    800039f0:	413b06bb          	subw	a3,s6,s3
    800039f4:	8a3e                	mv	s4,a5
    800039f6:	2781                	sext.w	a5,a5
    800039f8:	0006861b          	sext.w	a2,a3
    800039fc:	f8f679e3          	bgeu	a2,a5,8000398e <readi+0x4c>
    80003a00:	8a36                	mv	s4,a3
    80003a02:	b771                	j	8000398e <readi+0x4c>
      brelse(bp);
    80003a04:	854a                	mv	a0,s2
    80003a06:	fffff097          	auipc	ra,0xfffff
    80003a0a:	5b6080e7          	jalr	1462(ra) # 80002fbc <brelse>
  }
  return tot;
    80003a0e:	0009851b          	sext.w	a0,s3
}
    80003a12:	70a6                	ld	ra,104(sp)
    80003a14:	7406                	ld	s0,96(sp)
    80003a16:	64e6                	ld	s1,88(sp)
    80003a18:	6946                	ld	s2,80(sp)
    80003a1a:	69a6                	ld	s3,72(sp)
    80003a1c:	6a06                	ld	s4,64(sp)
    80003a1e:	7ae2                	ld	s5,56(sp)
    80003a20:	7b42                	ld	s6,48(sp)
    80003a22:	7ba2                	ld	s7,40(sp)
    80003a24:	7c02                	ld	s8,32(sp)
    80003a26:	6ce2                	ld	s9,24(sp)
    80003a28:	6d42                	ld	s10,16(sp)
    80003a2a:	6da2                	ld	s11,8(sp)
    80003a2c:	6165                	addi	sp,sp,112
    80003a2e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a30:	89da                	mv	s3,s6
    80003a32:	bff1                	j	80003a0e <readi+0xcc>
    return 0;
    80003a34:	4501                	li	a0,0
}
    80003a36:	8082                	ret

0000000080003a38 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a38:	457c                	lw	a5,76(a0)
    80003a3a:	10d7e663          	bltu	a5,a3,80003b46 <writei+0x10e>
{
    80003a3e:	7159                	addi	sp,sp,-112
    80003a40:	f486                	sd	ra,104(sp)
    80003a42:	f0a2                	sd	s0,96(sp)
    80003a44:	eca6                	sd	s1,88(sp)
    80003a46:	e8ca                	sd	s2,80(sp)
    80003a48:	e4ce                	sd	s3,72(sp)
    80003a4a:	e0d2                	sd	s4,64(sp)
    80003a4c:	fc56                	sd	s5,56(sp)
    80003a4e:	f85a                	sd	s6,48(sp)
    80003a50:	f45e                	sd	s7,40(sp)
    80003a52:	f062                	sd	s8,32(sp)
    80003a54:	ec66                	sd	s9,24(sp)
    80003a56:	e86a                	sd	s10,16(sp)
    80003a58:	e46e                	sd	s11,8(sp)
    80003a5a:	1880                	addi	s0,sp,112
    80003a5c:	8baa                	mv	s7,a0
    80003a5e:	8c2e                	mv	s8,a1
    80003a60:	8ab2                	mv	s5,a2
    80003a62:	8936                	mv	s2,a3
    80003a64:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a66:	00e687bb          	addw	a5,a3,a4
    80003a6a:	0ed7e063          	bltu	a5,a3,80003b4a <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a6e:	00043737          	lui	a4,0x43
    80003a72:	0cf76e63          	bltu	a4,a5,80003b4e <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a76:	0a0b0763          	beqz	s6,80003b24 <writei+0xec>
    80003a7a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a7c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a80:	5cfd                	li	s9,-1
    80003a82:	a091                	j	80003ac6 <writei+0x8e>
    80003a84:	02099d93          	slli	s11,s3,0x20
    80003a88:	020ddd93          	srli	s11,s11,0x20
    80003a8c:	05848513          	addi	a0,s1,88
    80003a90:	86ee                	mv	a3,s11
    80003a92:	8656                	mv	a2,s5
    80003a94:	85e2                	mv	a1,s8
    80003a96:	953a                	add	a0,a0,a4
    80003a98:	fffff097          	auipc	ra,0xfffff
    80003a9c:	a16080e7          	jalr	-1514(ra) # 800024ae <either_copyin>
    80003aa0:	07950263          	beq	a0,s9,80003b04 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003aa4:	8526                	mv	a0,s1
    80003aa6:	00000097          	auipc	ra,0x0
    80003aaa:	77a080e7          	jalr	1914(ra) # 80004220 <log_write>
    brelse(bp);
    80003aae:	8526                	mv	a0,s1
    80003ab0:	fffff097          	auipc	ra,0xfffff
    80003ab4:	50c080e7          	jalr	1292(ra) # 80002fbc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ab8:	01498a3b          	addw	s4,s3,s4
    80003abc:	0129893b          	addw	s2,s3,s2
    80003ac0:	9aee                	add	s5,s5,s11
    80003ac2:	056a7663          	bgeu	s4,s6,80003b0e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ac6:	000ba483          	lw	s1,0(s7)
    80003aca:	00a9559b          	srliw	a1,s2,0xa
    80003ace:	855e                	mv	a0,s7
    80003ad0:	fffff097          	auipc	ra,0xfffff
    80003ad4:	7b0080e7          	jalr	1968(ra) # 80003280 <bmap>
    80003ad8:	0005059b          	sext.w	a1,a0
    80003adc:	8526                	mv	a0,s1
    80003ade:	fffff097          	auipc	ra,0xfffff
    80003ae2:	3ae080e7          	jalr	942(ra) # 80002e8c <bread>
    80003ae6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ae8:	3ff97713          	andi	a4,s2,1023
    80003aec:	40ed07bb          	subw	a5,s10,a4
    80003af0:	414b06bb          	subw	a3,s6,s4
    80003af4:	89be                	mv	s3,a5
    80003af6:	2781                	sext.w	a5,a5
    80003af8:	0006861b          	sext.w	a2,a3
    80003afc:	f8f674e3          	bgeu	a2,a5,80003a84 <writei+0x4c>
    80003b00:	89b6                	mv	s3,a3
    80003b02:	b749                	j	80003a84 <writei+0x4c>
      brelse(bp);
    80003b04:	8526                	mv	a0,s1
    80003b06:	fffff097          	auipc	ra,0xfffff
    80003b0a:	4b6080e7          	jalr	1206(ra) # 80002fbc <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003b0e:	04cba783          	lw	a5,76(s7)
    80003b12:	0127f463          	bgeu	a5,s2,80003b1a <writei+0xe2>
      ip->size = off;
    80003b16:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003b1a:	855e                	mv	a0,s7
    80003b1c:	00000097          	auipc	ra,0x0
    80003b20:	aa8080e7          	jalr	-1368(ra) # 800035c4 <iupdate>
  }

  return n;
    80003b24:	000b051b          	sext.w	a0,s6
}
    80003b28:	70a6                	ld	ra,104(sp)
    80003b2a:	7406                	ld	s0,96(sp)
    80003b2c:	64e6                	ld	s1,88(sp)
    80003b2e:	6946                	ld	s2,80(sp)
    80003b30:	69a6                	ld	s3,72(sp)
    80003b32:	6a06                	ld	s4,64(sp)
    80003b34:	7ae2                	ld	s5,56(sp)
    80003b36:	7b42                	ld	s6,48(sp)
    80003b38:	7ba2                	ld	s7,40(sp)
    80003b3a:	7c02                	ld	s8,32(sp)
    80003b3c:	6ce2                	ld	s9,24(sp)
    80003b3e:	6d42                	ld	s10,16(sp)
    80003b40:	6da2                	ld	s11,8(sp)
    80003b42:	6165                	addi	sp,sp,112
    80003b44:	8082                	ret
    return -1;
    80003b46:	557d                	li	a0,-1
}
    80003b48:	8082                	ret
    return -1;
    80003b4a:	557d                	li	a0,-1
    80003b4c:	bff1                	j	80003b28 <writei+0xf0>
    return -1;
    80003b4e:	557d                	li	a0,-1
    80003b50:	bfe1                	j	80003b28 <writei+0xf0>

0000000080003b52 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b52:	1141                	addi	sp,sp,-16
    80003b54:	e406                	sd	ra,8(sp)
    80003b56:	e022                	sd	s0,0(sp)
    80003b58:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b5a:	4639                	li	a2,14
    80003b5c:	ffffd097          	auipc	ra,0xffffd
    80003b60:	28c080e7          	jalr	652(ra) # 80000de8 <strncmp>
}
    80003b64:	60a2                	ld	ra,8(sp)
    80003b66:	6402                	ld	s0,0(sp)
    80003b68:	0141                	addi	sp,sp,16
    80003b6a:	8082                	ret

0000000080003b6c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b6c:	7139                	addi	sp,sp,-64
    80003b6e:	fc06                	sd	ra,56(sp)
    80003b70:	f822                	sd	s0,48(sp)
    80003b72:	f426                	sd	s1,40(sp)
    80003b74:	f04a                	sd	s2,32(sp)
    80003b76:	ec4e                	sd	s3,24(sp)
    80003b78:	e852                	sd	s4,16(sp)
    80003b7a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b7c:	04451703          	lh	a4,68(a0)
    80003b80:	4785                	li	a5,1
    80003b82:	00f71a63          	bne	a4,a5,80003b96 <dirlookup+0x2a>
    80003b86:	892a                	mv	s2,a0
    80003b88:	89ae                	mv	s3,a1
    80003b8a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b8c:	457c                	lw	a5,76(a0)
    80003b8e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b90:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b92:	e79d                	bnez	a5,80003bc0 <dirlookup+0x54>
    80003b94:	a8a5                	j	80003c0c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b96:	00005517          	auipc	a0,0x5
    80003b9a:	bb250513          	addi	a0,a0,-1102 # 80008748 <sysnames+0x1a8>
    80003b9e:	ffffd097          	auipc	ra,0xffffd
    80003ba2:	9aa080e7          	jalr	-1622(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003ba6:	00005517          	auipc	a0,0x5
    80003baa:	bba50513          	addi	a0,a0,-1094 # 80008760 <sysnames+0x1c0>
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	99a080e7          	jalr	-1638(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bb6:	24c1                	addiw	s1,s1,16
    80003bb8:	04c92783          	lw	a5,76(s2)
    80003bbc:	04f4f763          	bgeu	s1,a5,80003c0a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bc0:	4741                	li	a4,16
    80003bc2:	86a6                	mv	a3,s1
    80003bc4:	fc040613          	addi	a2,s0,-64
    80003bc8:	4581                	li	a1,0
    80003bca:	854a                	mv	a0,s2
    80003bcc:	00000097          	auipc	ra,0x0
    80003bd0:	d76080e7          	jalr	-650(ra) # 80003942 <readi>
    80003bd4:	47c1                	li	a5,16
    80003bd6:	fcf518e3          	bne	a0,a5,80003ba6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003bda:	fc045783          	lhu	a5,-64(s0)
    80003bde:	dfe1                	beqz	a5,80003bb6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003be0:	fc240593          	addi	a1,s0,-62
    80003be4:	854e                	mv	a0,s3
    80003be6:	00000097          	auipc	ra,0x0
    80003bea:	f6c080e7          	jalr	-148(ra) # 80003b52 <namecmp>
    80003bee:	f561                	bnez	a0,80003bb6 <dirlookup+0x4a>
      if(poff)
    80003bf0:	000a0463          	beqz	s4,80003bf8 <dirlookup+0x8c>
        *poff = off;
    80003bf4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bf8:	fc045583          	lhu	a1,-64(s0)
    80003bfc:	00092503          	lw	a0,0(s2)
    80003c00:	fffff097          	auipc	ra,0xfffff
    80003c04:	75a080e7          	jalr	1882(ra) # 8000335a <iget>
    80003c08:	a011                	j	80003c0c <dirlookup+0xa0>
  return 0;
    80003c0a:	4501                	li	a0,0
}
    80003c0c:	70e2                	ld	ra,56(sp)
    80003c0e:	7442                	ld	s0,48(sp)
    80003c10:	74a2                	ld	s1,40(sp)
    80003c12:	7902                	ld	s2,32(sp)
    80003c14:	69e2                	ld	s3,24(sp)
    80003c16:	6a42                	ld	s4,16(sp)
    80003c18:	6121                	addi	sp,sp,64
    80003c1a:	8082                	ret

0000000080003c1c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c1c:	711d                	addi	sp,sp,-96
    80003c1e:	ec86                	sd	ra,88(sp)
    80003c20:	e8a2                	sd	s0,80(sp)
    80003c22:	e4a6                	sd	s1,72(sp)
    80003c24:	e0ca                	sd	s2,64(sp)
    80003c26:	fc4e                	sd	s3,56(sp)
    80003c28:	f852                	sd	s4,48(sp)
    80003c2a:	f456                	sd	s5,40(sp)
    80003c2c:	f05a                	sd	s6,32(sp)
    80003c2e:	ec5e                	sd	s7,24(sp)
    80003c30:	e862                	sd	s8,16(sp)
    80003c32:	e466                	sd	s9,8(sp)
    80003c34:	1080                	addi	s0,sp,96
    80003c36:	84aa                	mv	s1,a0
    80003c38:	8b2e                	mv	s6,a1
    80003c3a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c3c:	00054703          	lbu	a4,0(a0)
    80003c40:	02f00793          	li	a5,47
    80003c44:	02f70363          	beq	a4,a5,80003c6a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c48:	ffffe097          	auipc	ra,0xffffe
    80003c4c:	d96080e7          	jalr	-618(ra) # 800019de <myproc>
    80003c50:	15053503          	ld	a0,336(a0)
    80003c54:	00000097          	auipc	ra,0x0
    80003c58:	9fc080e7          	jalr	-1540(ra) # 80003650 <idup>
    80003c5c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c5e:	02f00913          	li	s2,47
  len = path - s;
    80003c62:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003c64:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c66:	4c05                	li	s8,1
    80003c68:	a865                	j	80003d20 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c6a:	4585                	li	a1,1
    80003c6c:	4505                	li	a0,1
    80003c6e:	fffff097          	auipc	ra,0xfffff
    80003c72:	6ec080e7          	jalr	1772(ra) # 8000335a <iget>
    80003c76:	89aa                	mv	s3,a0
    80003c78:	b7dd                	j	80003c5e <namex+0x42>
      iunlockput(ip);
    80003c7a:	854e                	mv	a0,s3
    80003c7c:	00000097          	auipc	ra,0x0
    80003c80:	c74080e7          	jalr	-908(ra) # 800038f0 <iunlockput>
      return 0;
    80003c84:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c86:	854e                	mv	a0,s3
    80003c88:	60e6                	ld	ra,88(sp)
    80003c8a:	6446                	ld	s0,80(sp)
    80003c8c:	64a6                	ld	s1,72(sp)
    80003c8e:	6906                	ld	s2,64(sp)
    80003c90:	79e2                	ld	s3,56(sp)
    80003c92:	7a42                	ld	s4,48(sp)
    80003c94:	7aa2                	ld	s5,40(sp)
    80003c96:	7b02                	ld	s6,32(sp)
    80003c98:	6be2                	ld	s7,24(sp)
    80003c9a:	6c42                	ld	s8,16(sp)
    80003c9c:	6ca2                	ld	s9,8(sp)
    80003c9e:	6125                	addi	sp,sp,96
    80003ca0:	8082                	ret
      iunlock(ip);
    80003ca2:	854e                	mv	a0,s3
    80003ca4:	00000097          	auipc	ra,0x0
    80003ca8:	aac080e7          	jalr	-1364(ra) # 80003750 <iunlock>
      return ip;
    80003cac:	bfe9                	j	80003c86 <namex+0x6a>
      iunlockput(ip);
    80003cae:	854e                	mv	a0,s3
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	c40080e7          	jalr	-960(ra) # 800038f0 <iunlockput>
      return 0;
    80003cb8:	89d2                	mv	s3,s4
    80003cba:	b7f1                	j	80003c86 <namex+0x6a>
  len = path - s;
    80003cbc:	40b48633          	sub	a2,s1,a1
    80003cc0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003cc4:	094cd463          	bge	s9,s4,80003d4c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cc8:	4639                	li	a2,14
    80003cca:	8556                	mv	a0,s5
    80003ccc:	ffffd097          	auipc	ra,0xffffd
    80003cd0:	0a0080e7          	jalr	160(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003cd4:	0004c783          	lbu	a5,0(s1)
    80003cd8:	01279763          	bne	a5,s2,80003ce6 <namex+0xca>
    path++;
    80003cdc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cde:	0004c783          	lbu	a5,0(s1)
    80003ce2:	ff278de3          	beq	a5,s2,80003cdc <namex+0xc0>
    ilock(ip);
    80003ce6:	854e                	mv	a0,s3
    80003ce8:	00000097          	auipc	ra,0x0
    80003cec:	9a6080e7          	jalr	-1626(ra) # 8000368e <ilock>
    if(ip->type != T_DIR){
    80003cf0:	04499783          	lh	a5,68(s3)
    80003cf4:	f98793e3          	bne	a5,s8,80003c7a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003cf8:	000b0563          	beqz	s6,80003d02 <namex+0xe6>
    80003cfc:	0004c783          	lbu	a5,0(s1)
    80003d00:	d3cd                	beqz	a5,80003ca2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d02:	865e                	mv	a2,s7
    80003d04:	85d6                	mv	a1,s5
    80003d06:	854e                	mv	a0,s3
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	e64080e7          	jalr	-412(ra) # 80003b6c <dirlookup>
    80003d10:	8a2a                	mv	s4,a0
    80003d12:	dd51                	beqz	a0,80003cae <namex+0x92>
    iunlockput(ip);
    80003d14:	854e                	mv	a0,s3
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	bda080e7          	jalr	-1062(ra) # 800038f0 <iunlockput>
    ip = next;
    80003d1e:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d20:	0004c783          	lbu	a5,0(s1)
    80003d24:	05279763          	bne	a5,s2,80003d72 <namex+0x156>
    path++;
    80003d28:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d2a:	0004c783          	lbu	a5,0(s1)
    80003d2e:	ff278de3          	beq	a5,s2,80003d28 <namex+0x10c>
  if(*path == 0)
    80003d32:	c79d                	beqz	a5,80003d60 <namex+0x144>
    path++;
    80003d34:	85a6                	mv	a1,s1
  len = path - s;
    80003d36:	8a5e                	mv	s4,s7
    80003d38:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d3a:	01278963          	beq	a5,s2,80003d4c <namex+0x130>
    80003d3e:	dfbd                	beqz	a5,80003cbc <namex+0xa0>
    path++;
    80003d40:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d42:	0004c783          	lbu	a5,0(s1)
    80003d46:	ff279ce3          	bne	a5,s2,80003d3e <namex+0x122>
    80003d4a:	bf8d                	j	80003cbc <namex+0xa0>
    memmove(name, s, len);
    80003d4c:	2601                	sext.w	a2,a2
    80003d4e:	8556                	mv	a0,s5
    80003d50:	ffffd097          	auipc	ra,0xffffd
    80003d54:	01c080e7          	jalr	28(ra) # 80000d6c <memmove>
    name[len] = 0;
    80003d58:	9a56                	add	s4,s4,s5
    80003d5a:	000a0023          	sb	zero,0(s4)
    80003d5e:	bf9d                	j	80003cd4 <namex+0xb8>
  if(nameiparent){
    80003d60:	f20b03e3          	beqz	s6,80003c86 <namex+0x6a>
    iput(ip);
    80003d64:	854e                	mv	a0,s3
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	ae2080e7          	jalr	-1310(ra) # 80003848 <iput>
    return 0;
    80003d6e:	4981                	li	s3,0
    80003d70:	bf19                	j	80003c86 <namex+0x6a>
  if(*path == 0)
    80003d72:	d7fd                	beqz	a5,80003d60 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d74:	0004c783          	lbu	a5,0(s1)
    80003d78:	85a6                	mv	a1,s1
    80003d7a:	b7d1                	j	80003d3e <namex+0x122>

0000000080003d7c <dirlink>:
{
    80003d7c:	7139                	addi	sp,sp,-64
    80003d7e:	fc06                	sd	ra,56(sp)
    80003d80:	f822                	sd	s0,48(sp)
    80003d82:	f426                	sd	s1,40(sp)
    80003d84:	f04a                	sd	s2,32(sp)
    80003d86:	ec4e                	sd	s3,24(sp)
    80003d88:	e852                	sd	s4,16(sp)
    80003d8a:	0080                	addi	s0,sp,64
    80003d8c:	892a                	mv	s2,a0
    80003d8e:	8a2e                	mv	s4,a1
    80003d90:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d92:	4601                	li	a2,0
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	dd8080e7          	jalr	-552(ra) # 80003b6c <dirlookup>
    80003d9c:	e93d                	bnez	a0,80003e12 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d9e:	04c92483          	lw	s1,76(s2)
    80003da2:	c49d                	beqz	s1,80003dd0 <dirlink+0x54>
    80003da4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003da6:	4741                	li	a4,16
    80003da8:	86a6                	mv	a3,s1
    80003daa:	fc040613          	addi	a2,s0,-64
    80003dae:	4581                	li	a1,0
    80003db0:	854a                	mv	a0,s2
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	b90080e7          	jalr	-1136(ra) # 80003942 <readi>
    80003dba:	47c1                	li	a5,16
    80003dbc:	06f51163          	bne	a0,a5,80003e1e <dirlink+0xa2>
    if(de.inum == 0)
    80003dc0:	fc045783          	lhu	a5,-64(s0)
    80003dc4:	c791                	beqz	a5,80003dd0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc6:	24c1                	addiw	s1,s1,16
    80003dc8:	04c92783          	lw	a5,76(s2)
    80003dcc:	fcf4ede3          	bltu	s1,a5,80003da6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003dd0:	4639                	li	a2,14
    80003dd2:	85d2                	mv	a1,s4
    80003dd4:	fc240513          	addi	a0,s0,-62
    80003dd8:	ffffd097          	auipc	ra,0xffffd
    80003ddc:	04c080e7          	jalr	76(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80003de0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003de4:	4741                	li	a4,16
    80003de6:	86a6                	mv	a3,s1
    80003de8:	fc040613          	addi	a2,s0,-64
    80003dec:	4581                	li	a1,0
    80003dee:	854a                	mv	a0,s2
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	c48080e7          	jalr	-952(ra) # 80003a38 <writei>
    80003df8:	872a                	mv	a4,a0
    80003dfa:	47c1                	li	a5,16
  return 0;
    80003dfc:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dfe:	02f71863          	bne	a4,a5,80003e2e <dirlink+0xb2>
}
    80003e02:	70e2                	ld	ra,56(sp)
    80003e04:	7442                	ld	s0,48(sp)
    80003e06:	74a2                	ld	s1,40(sp)
    80003e08:	7902                	ld	s2,32(sp)
    80003e0a:	69e2                	ld	s3,24(sp)
    80003e0c:	6a42                	ld	s4,16(sp)
    80003e0e:	6121                	addi	sp,sp,64
    80003e10:	8082                	ret
    iput(ip);
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	a36080e7          	jalr	-1482(ra) # 80003848 <iput>
    return -1;
    80003e1a:	557d                	li	a0,-1
    80003e1c:	b7dd                	j	80003e02 <dirlink+0x86>
      panic("dirlink read");
    80003e1e:	00005517          	auipc	a0,0x5
    80003e22:	95250513          	addi	a0,a0,-1710 # 80008770 <sysnames+0x1d0>
    80003e26:	ffffc097          	auipc	ra,0xffffc
    80003e2a:	722080e7          	jalr	1826(ra) # 80000548 <panic>
    panic("dirlink");
    80003e2e:	00005517          	auipc	a0,0x5
    80003e32:	a5a50513          	addi	a0,a0,-1446 # 80008888 <sysnames+0x2e8>
    80003e36:	ffffc097          	auipc	ra,0xffffc
    80003e3a:	712080e7          	jalr	1810(ra) # 80000548 <panic>

0000000080003e3e <namei>:

struct inode*
namei(char *path)
{
    80003e3e:	1101                	addi	sp,sp,-32
    80003e40:	ec06                	sd	ra,24(sp)
    80003e42:	e822                	sd	s0,16(sp)
    80003e44:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e46:	fe040613          	addi	a2,s0,-32
    80003e4a:	4581                	li	a1,0
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	dd0080e7          	jalr	-560(ra) # 80003c1c <namex>
}
    80003e54:	60e2                	ld	ra,24(sp)
    80003e56:	6442                	ld	s0,16(sp)
    80003e58:	6105                	addi	sp,sp,32
    80003e5a:	8082                	ret

0000000080003e5c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e5c:	1141                	addi	sp,sp,-16
    80003e5e:	e406                	sd	ra,8(sp)
    80003e60:	e022                	sd	s0,0(sp)
    80003e62:	0800                	addi	s0,sp,16
    80003e64:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e66:	4585                	li	a1,1
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	db4080e7          	jalr	-588(ra) # 80003c1c <namex>
}
    80003e70:	60a2                	ld	ra,8(sp)
    80003e72:	6402                	ld	s0,0(sp)
    80003e74:	0141                	addi	sp,sp,16
    80003e76:	8082                	ret

0000000080003e78 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e78:	1101                	addi	sp,sp,-32
    80003e7a:	ec06                	sd	ra,24(sp)
    80003e7c:	e822                	sd	s0,16(sp)
    80003e7e:	e426                	sd	s1,8(sp)
    80003e80:	e04a                	sd	s2,0(sp)
    80003e82:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e84:	0001e917          	auipc	s2,0x1e
    80003e88:	c8490913          	addi	s2,s2,-892 # 80021b08 <log>
    80003e8c:	01892583          	lw	a1,24(s2)
    80003e90:	02892503          	lw	a0,40(s2)
    80003e94:	fffff097          	auipc	ra,0xfffff
    80003e98:	ff8080e7          	jalr	-8(ra) # 80002e8c <bread>
    80003e9c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e9e:	02c92683          	lw	a3,44(s2)
    80003ea2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ea4:	02d05763          	blez	a3,80003ed2 <write_head+0x5a>
    80003ea8:	0001e797          	auipc	a5,0x1e
    80003eac:	c9078793          	addi	a5,a5,-880 # 80021b38 <log+0x30>
    80003eb0:	05c50713          	addi	a4,a0,92
    80003eb4:	36fd                	addiw	a3,a3,-1
    80003eb6:	1682                	slli	a3,a3,0x20
    80003eb8:	9281                	srli	a3,a3,0x20
    80003eba:	068a                	slli	a3,a3,0x2
    80003ebc:	0001e617          	auipc	a2,0x1e
    80003ec0:	c8060613          	addi	a2,a2,-896 # 80021b3c <log+0x34>
    80003ec4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ec6:	4390                	lw	a2,0(a5)
    80003ec8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003eca:	0791                	addi	a5,a5,4
    80003ecc:	0711                	addi	a4,a4,4
    80003ece:	fed79ce3          	bne	a5,a3,80003ec6 <write_head+0x4e>
  }
  bwrite(buf);
    80003ed2:	8526                	mv	a0,s1
    80003ed4:	fffff097          	auipc	ra,0xfffff
    80003ed8:	0aa080e7          	jalr	170(ra) # 80002f7e <bwrite>
  brelse(buf);
    80003edc:	8526                	mv	a0,s1
    80003ede:	fffff097          	auipc	ra,0xfffff
    80003ee2:	0de080e7          	jalr	222(ra) # 80002fbc <brelse>
}
    80003ee6:	60e2                	ld	ra,24(sp)
    80003ee8:	6442                	ld	s0,16(sp)
    80003eea:	64a2                	ld	s1,8(sp)
    80003eec:	6902                	ld	s2,0(sp)
    80003eee:	6105                	addi	sp,sp,32
    80003ef0:	8082                	ret

0000000080003ef2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ef2:	0001e797          	auipc	a5,0x1e
    80003ef6:	c427a783          	lw	a5,-958(a5) # 80021b34 <log+0x2c>
    80003efa:	0af05663          	blez	a5,80003fa6 <install_trans+0xb4>
{
    80003efe:	7139                	addi	sp,sp,-64
    80003f00:	fc06                	sd	ra,56(sp)
    80003f02:	f822                	sd	s0,48(sp)
    80003f04:	f426                	sd	s1,40(sp)
    80003f06:	f04a                	sd	s2,32(sp)
    80003f08:	ec4e                	sd	s3,24(sp)
    80003f0a:	e852                	sd	s4,16(sp)
    80003f0c:	e456                	sd	s5,8(sp)
    80003f0e:	0080                	addi	s0,sp,64
    80003f10:	0001ea97          	auipc	s5,0x1e
    80003f14:	c28a8a93          	addi	s5,s5,-984 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f18:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f1a:	0001e997          	auipc	s3,0x1e
    80003f1e:	bee98993          	addi	s3,s3,-1042 # 80021b08 <log>
    80003f22:	0189a583          	lw	a1,24(s3)
    80003f26:	014585bb          	addw	a1,a1,s4
    80003f2a:	2585                	addiw	a1,a1,1
    80003f2c:	0289a503          	lw	a0,40(s3)
    80003f30:	fffff097          	auipc	ra,0xfffff
    80003f34:	f5c080e7          	jalr	-164(ra) # 80002e8c <bread>
    80003f38:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f3a:	000aa583          	lw	a1,0(s5)
    80003f3e:	0289a503          	lw	a0,40(s3)
    80003f42:	fffff097          	auipc	ra,0xfffff
    80003f46:	f4a080e7          	jalr	-182(ra) # 80002e8c <bread>
    80003f4a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f4c:	40000613          	li	a2,1024
    80003f50:	05890593          	addi	a1,s2,88
    80003f54:	05850513          	addi	a0,a0,88
    80003f58:	ffffd097          	auipc	ra,0xffffd
    80003f5c:	e14080e7          	jalr	-492(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f60:	8526                	mv	a0,s1
    80003f62:	fffff097          	auipc	ra,0xfffff
    80003f66:	01c080e7          	jalr	28(ra) # 80002f7e <bwrite>
    bunpin(dbuf);
    80003f6a:	8526                	mv	a0,s1
    80003f6c:	fffff097          	auipc	ra,0xfffff
    80003f70:	12a080e7          	jalr	298(ra) # 80003096 <bunpin>
    brelse(lbuf);
    80003f74:	854a                	mv	a0,s2
    80003f76:	fffff097          	auipc	ra,0xfffff
    80003f7a:	046080e7          	jalr	70(ra) # 80002fbc <brelse>
    brelse(dbuf);
    80003f7e:	8526                	mv	a0,s1
    80003f80:	fffff097          	auipc	ra,0xfffff
    80003f84:	03c080e7          	jalr	60(ra) # 80002fbc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f88:	2a05                	addiw	s4,s4,1
    80003f8a:	0a91                	addi	s5,s5,4
    80003f8c:	02c9a783          	lw	a5,44(s3)
    80003f90:	f8fa49e3          	blt	s4,a5,80003f22 <install_trans+0x30>
}
    80003f94:	70e2                	ld	ra,56(sp)
    80003f96:	7442                	ld	s0,48(sp)
    80003f98:	74a2                	ld	s1,40(sp)
    80003f9a:	7902                	ld	s2,32(sp)
    80003f9c:	69e2                	ld	s3,24(sp)
    80003f9e:	6a42                	ld	s4,16(sp)
    80003fa0:	6aa2                	ld	s5,8(sp)
    80003fa2:	6121                	addi	sp,sp,64
    80003fa4:	8082                	ret
    80003fa6:	8082                	ret

0000000080003fa8 <initlog>:
{
    80003fa8:	7179                	addi	sp,sp,-48
    80003faa:	f406                	sd	ra,40(sp)
    80003fac:	f022                	sd	s0,32(sp)
    80003fae:	ec26                	sd	s1,24(sp)
    80003fb0:	e84a                	sd	s2,16(sp)
    80003fb2:	e44e                	sd	s3,8(sp)
    80003fb4:	1800                	addi	s0,sp,48
    80003fb6:	892a                	mv	s2,a0
    80003fb8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fba:	0001e497          	auipc	s1,0x1e
    80003fbe:	b4e48493          	addi	s1,s1,-1202 # 80021b08 <log>
    80003fc2:	00004597          	auipc	a1,0x4
    80003fc6:	7be58593          	addi	a1,a1,1982 # 80008780 <sysnames+0x1e0>
    80003fca:	8526                	mv	a0,s1
    80003fcc:	ffffd097          	auipc	ra,0xffffd
    80003fd0:	bb4080e7          	jalr	-1100(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80003fd4:	0149a583          	lw	a1,20(s3)
    80003fd8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fda:	0109a783          	lw	a5,16(s3)
    80003fde:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003fe0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fe4:	854a                	mv	a0,s2
    80003fe6:	fffff097          	auipc	ra,0xfffff
    80003fea:	ea6080e7          	jalr	-346(ra) # 80002e8c <bread>
  log.lh.n = lh->n;
    80003fee:	4d3c                	lw	a5,88(a0)
    80003ff0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003ff2:	02f05563          	blez	a5,8000401c <initlog+0x74>
    80003ff6:	05c50713          	addi	a4,a0,92
    80003ffa:	0001e697          	auipc	a3,0x1e
    80003ffe:	b3e68693          	addi	a3,a3,-1218 # 80021b38 <log+0x30>
    80004002:	37fd                	addiw	a5,a5,-1
    80004004:	1782                	slli	a5,a5,0x20
    80004006:	9381                	srli	a5,a5,0x20
    80004008:	078a                	slli	a5,a5,0x2
    8000400a:	06050613          	addi	a2,a0,96
    8000400e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004010:	4310                	lw	a2,0(a4)
    80004012:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004014:	0711                	addi	a4,a4,4
    80004016:	0691                	addi	a3,a3,4
    80004018:	fef71ce3          	bne	a4,a5,80004010 <initlog+0x68>
  brelse(buf);
    8000401c:	fffff097          	auipc	ra,0xfffff
    80004020:	fa0080e7          	jalr	-96(ra) # 80002fbc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004024:	00000097          	auipc	ra,0x0
    80004028:	ece080e7          	jalr	-306(ra) # 80003ef2 <install_trans>
  log.lh.n = 0;
    8000402c:	0001e797          	auipc	a5,0x1e
    80004030:	b007a423          	sw	zero,-1272(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    80004034:	00000097          	auipc	ra,0x0
    80004038:	e44080e7          	jalr	-444(ra) # 80003e78 <write_head>
}
    8000403c:	70a2                	ld	ra,40(sp)
    8000403e:	7402                	ld	s0,32(sp)
    80004040:	64e2                	ld	s1,24(sp)
    80004042:	6942                	ld	s2,16(sp)
    80004044:	69a2                	ld	s3,8(sp)
    80004046:	6145                	addi	sp,sp,48
    80004048:	8082                	ret

000000008000404a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000404a:	1101                	addi	sp,sp,-32
    8000404c:	ec06                	sd	ra,24(sp)
    8000404e:	e822                	sd	s0,16(sp)
    80004050:	e426                	sd	s1,8(sp)
    80004052:	e04a                	sd	s2,0(sp)
    80004054:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004056:	0001e517          	auipc	a0,0x1e
    8000405a:	ab250513          	addi	a0,a0,-1358 # 80021b08 <log>
    8000405e:	ffffd097          	auipc	ra,0xffffd
    80004062:	bb2080e7          	jalr	-1102(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    80004066:	0001e497          	auipc	s1,0x1e
    8000406a:	aa248493          	addi	s1,s1,-1374 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000406e:	4979                	li	s2,30
    80004070:	a039                	j	8000407e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004072:	85a6                	mv	a1,s1
    80004074:	8526                	mv	a0,s1
    80004076:	ffffe097          	auipc	ra,0xffffe
    8000407a:	180080e7          	jalr	384(ra) # 800021f6 <sleep>
    if(log.committing){
    8000407e:	50dc                	lw	a5,36(s1)
    80004080:	fbed                	bnez	a5,80004072 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004082:	509c                	lw	a5,32(s1)
    80004084:	0017871b          	addiw	a4,a5,1
    80004088:	0007069b          	sext.w	a3,a4
    8000408c:	0027179b          	slliw	a5,a4,0x2
    80004090:	9fb9                	addw	a5,a5,a4
    80004092:	0017979b          	slliw	a5,a5,0x1
    80004096:	54d8                	lw	a4,44(s1)
    80004098:	9fb9                	addw	a5,a5,a4
    8000409a:	00f95963          	bge	s2,a5,800040ac <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000409e:	85a6                	mv	a1,s1
    800040a0:	8526                	mv	a0,s1
    800040a2:	ffffe097          	auipc	ra,0xffffe
    800040a6:	154080e7          	jalr	340(ra) # 800021f6 <sleep>
    800040aa:	bfd1                	j	8000407e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040ac:	0001e517          	auipc	a0,0x1e
    800040b0:	a5c50513          	addi	a0,a0,-1444 # 80021b08 <log>
    800040b4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040b6:	ffffd097          	auipc	ra,0xffffd
    800040ba:	c0e080e7          	jalr	-1010(ra) # 80000cc4 <release>
      break;
    }
  }
}
    800040be:	60e2                	ld	ra,24(sp)
    800040c0:	6442                	ld	s0,16(sp)
    800040c2:	64a2                	ld	s1,8(sp)
    800040c4:	6902                	ld	s2,0(sp)
    800040c6:	6105                	addi	sp,sp,32
    800040c8:	8082                	ret

00000000800040ca <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040ca:	7139                	addi	sp,sp,-64
    800040cc:	fc06                	sd	ra,56(sp)
    800040ce:	f822                	sd	s0,48(sp)
    800040d0:	f426                	sd	s1,40(sp)
    800040d2:	f04a                	sd	s2,32(sp)
    800040d4:	ec4e                	sd	s3,24(sp)
    800040d6:	e852                	sd	s4,16(sp)
    800040d8:	e456                	sd	s5,8(sp)
    800040da:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040dc:	0001e497          	auipc	s1,0x1e
    800040e0:	a2c48493          	addi	s1,s1,-1492 # 80021b08 <log>
    800040e4:	8526                	mv	a0,s1
    800040e6:	ffffd097          	auipc	ra,0xffffd
    800040ea:	b2a080e7          	jalr	-1238(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    800040ee:	509c                	lw	a5,32(s1)
    800040f0:	37fd                	addiw	a5,a5,-1
    800040f2:	0007891b          	sext.w	s2,a5
    800040f6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040f8:	50dc                	lw	a5,36(s1)
    800040fa:	efb9                	bnez	a5,80004158 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040fc:	06091663          	bnez	s2,80004168 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004100:	0001e497          	auipc	s1,0x1e
    80004104:	a0848493          	addi	s1,s1,-1528 # 80021b08 <log>
    80004108:	4785                	li	a5,1
    8000410a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000410c:	8526                	mv	a0,s1
    8000410e:	ffffd097          	auipc	ra,0xffffd
    80004112:	bb6080e7          	jalr	-1098(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004116:	54dc                	lw	a5,44(s1)
    80004118:	06f04763          	bgtz	a5,80004186 <end_op+0xbc>
    acquire(&log.lock);
    8000411c:	0001e497          	auipc	s1,0x1e
    80004120:	9ec48493          	addi	s1,s1,-1556 # 80021b08 <log>
    80004124:	8526                	mv	a0,s1
    80004126:	ffffd097          	auipc	ra,0xffffd
    8000412a:	aea080e7          	jalr	-1302(ra) # 80000c10 <acquire>
    log.committing = 0;
    8000412e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004132:	8526                	mv	a0,s1
    80004134:	ffffe097          	auipc	ra,0xffffe
    80004138:	248080e7          	jalr	584(ra) # 8000237c <wakeup>
    release(&log.lock);
    8000413c:	8526                	mv	a0,s1
    8000413e:	ffffd097          	auipc	ra,0xffffd
    80004142:	b86080e7          	jalr	-1146(ra) # 80000cc4 <release>
}
    80004146:	70e2                	ld	ra,56(sp)
    80004148:	7442                	ld	s0,48(sp)
    8000414a:	74a2                	ld	s1,40(sp)
    8000414c:	7902                	ld	s2,32(sp)
    8000414e:	69e2                	ld	s3,24(sp)
    80004150:	6a42                	ld	s4,16(sp)
    80004152:	6aa2                	ld	s5,8(sp)
    80004154:	6121                	addi	sp,sp,64
    80004156:	8082                	ret
    panic("log.committing");
    80004158:	00004517          	auipc	a0,0x4
    8000415c:	63050513          	addi	a0,a0,1584 # 80008788 <sysnames+0x1e8>
    80004160:	ffffc097          	auipc	ra,0xffffc
    80004164:	3e8080e7          	jalr	1000(ra) # 80000548 <panic>
    wakeup(&log);
    80004168:	0001e497          	auipc	s1,0x1e
    8000416c:	9a048493          	addi	s1,s1,-1632 # 80021b08 <log>
    80004170:	8526                	mv	a0,s1
    80004172:	ffffe097          	auipc	ra,0xffffe
    80004176:	20a080e7          	jalr	522(ra) # 8000237c <wakeup>
  release(&log.lock);
    8000417a:	8526                	mv	a0,s1
    8000417c:	ffffd097          	auipc	ra,0xffffd
    80004180:	b48080e7          	jalr	-1208(ra) # 80000cc4 <release>
  if(do_commit){
    80004184:	b7c9                	j	80004146 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004186:	0001ea97          	auipc	s5,0x1e
    8000418a:	9b2a8a93          	addi	s5,s5,-1614 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000418e:	0001ea17          	auipc	s4,0x1e
    80004192:	97aa0a13          	addi	s4,s4,-1670 # 80021b08 <log>
    80004196:	018a2583          	lw	a1,24(s4)
    8000419a:	012585bb          	addw	a1,a1,s2
    8000419e:	2585                	addiw	a1,a1,1
    800041a0:	028a2503          	lw	a0,40(s4)
    800041a4:	fffff097          	auipc	ra,0xfffff
    800041a8:	ce8080e7          	jalr	-792(ra) # 80002e8c <bread>
    800041ac:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041ae:	000aa583          	lw	a1,0(s5)
    800041b2:	028a2503          	lw	a0,40(s4)
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	cd6080e7          	jalr	-810(ra) # 80002e8c <bread>
    800041be:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041c0:	40000613          	li	a2,1024
    800041c4:	05850593          	addi	a1,a0,88
    800041c8:	05848513          	addi	a0,s1,88
    800041cc:	ffffd097          	auipc	ra,0xffffd
    800041d0:	ba0080e7          	jalr	-1120(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    800041d4:	8526                	mv	a0,s1
    800041d6:	fffff097          	auipc	ra,0xfffff
    800041da:	da8080e7          	jalr	-600(ra) # 80002f7e <bwrite>
    brelse(from);
    800041de:	854e                	mv	a0,s3
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	ddc080e7          	jalr	-548(ra) # 80002fbc <brelse>
    brelse(to);
    800041e8:	8526                	mv	a0,s1
    800041ea:	fffff097          	auipc	ra,0xfffff
    800041ee:	dd2080e7          	jalr	-558(ra) # 80002fbc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041f2:	2905                	addiw	s2,s2,1
    800041f4:	0a91                	addi	s5,s5,4
    800041f6:	02ca2783          	lw	a5,44(s4)
    800041fa:	f8f94ee3          	blt	s2,a5,80004196 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041fe:	00000097          	auipc	ra,0x0
    80004202:	c7a080e7          	jalr	-902(ra) # 80003e78 <write_head>
    install_trans(); // Now install writes to home locations
    80004206:	00000097          	auipc	ra,0x0
    8000420a:	cec080e7          	jalr	-788(ra) # 80003ef2 <install_trans>
    log.lh.n = 0;
    8000420e:	0001e797          	auipc	a5,0x1e
    80004212:	9207a323          	sw	zero,-1754(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004216:	00000097          	auipc	ra,0x0
    8000421a:	c62080e7          	jalr	-926(ra) # 80003e78 <write_head>
    8000421e:	bdfd                	j	8000411c <end_op+0x52>

0000000080004220 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004220:	1101                	addi	sp,sp,-32
    80004222:	ec06                	sd	ra,24(sp)
    80004224:	e822                	sd	s0,16(sp)
    80004226:	e426                	sd	s1,8(sp)
    80004228:	e04a                	sd	s2,0(sp)
    8000422a:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000422c:	0001e717          	auipc	a4,0x1e
    80004230:	90872703          	lw	a4,-1784(a4) # 80021b34 <log+0x2c>
    80004234:	47f5                	li	a5,29
    80004236:	08e7c063          	blt	a5,a4,800042b6 <log_write+0x96>
    8000423a:	84aa                	mv	s1,a0
    8000423c:	0001e797          	auipc	a5,0x1e
    80004240:	8e87a783          	lw	a5,-1816(a5) # 80021b24 <log+0x1c>
    80004244:	37fd                	addiw	a5,a5,-1
    80004246:	06f75863          	bge	a4,a5,800042b6 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000424a:	0001e797          	auipc	a5,0x1e
    8000424e:	8de7a783          	lw	a5,-1826(a5) # 80021b28 <log+0x20>
    80004252:	06f05a63          	blez	a5,800042c6 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004256:	0001e917          	auipc	s2,0x1e
    8000425a:	8b290913          	addi	s2,s2,-1870 # 80021b08 <log>
    8000425e:	854a                	mv	a0,s2
    80004260:	ffffd097          	auipc	ra,0xffffd
    80004264:	9b0080e7          	jalr	-1616(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004268:	02c92603          	lw	a2,44(s2)
    8000426c:	06c05563          	blez	a2,800042d6 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004270:	44cc                	lw	a1,12(s1)
    80004272:	0001e717          	auipc	a4,0x1e
    80004276:	8c670713          	addi	a4,a4,-1850 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000427a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000427c:	4314                	lw	a3,0(a4)
    8000427e:	04b68d63          	beq	a3,a1,800042d8 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004282:	2785                	addiw	a5,a5,1
    80004284:	0711                	addi	a4,a4,4
    80004286:	fec79be3          	bne	a5,a2,8000427c <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000428a:	0621                	addi	a2,a2,8
    8000428c:	060a                	slli	a2,a2,0x2
    8000428e:	0001e797          	auipc	a5,0x1e
    80004292:	87a78793          	addi	a5,a5,-1926 # 80021b08 <log>
    80004296:	963e                	add	a2,a2,a5
    80004298:	44dc                	lw	a5,12(s1)
    8000429a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000429c:	8526                	mv	a0,s1
    8000429e:	fffff097          	auipc	ra,0xfffff
    800042a2:	dbc080e7          	jalr	-580(ra) # 8000305a <bpin>
    log.lh.n++;
    800042a6:	0001e717          	auipc	a4,0x1e
    800042aa:	86270713          	addi	a4,a4,-1950 # 80021b08 <log>
    800042ae:	575c                	lw	a5,44(a4)
    800042b0:	2785                	addiw	a5,a5,1
    800042b2:	d75c                	sw	a5,44(a4)
    800042b4:	a83d                	j	800042f2 <log_write+0xd2>
    panic("too big a transaction");
    800042b6:	00004517          	auipc	a0,0x4
    800042ba:	4e250513          	addi	a0,a0,1250 # 80008798 <sysnames+0x1f8>
    800042be:	ffffc097          	auipc	ra,0xffffc
    800042c2:	28a080e7          	jalr	650(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800042c6:	00004517          	auipc	a0,0x4
    800042ca:	4ea50513          	addi	a0,a0,1258 # 800087b0 <sysnames+0x210>
    800042ce:	ffffc097          	auipc	ra,0xffffc
    800042d2:	27a080e7          	jalr	634(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800042d6:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800042d8:	00878713          	addi	a4,a5,8
    800042dc:	00271693          	slli	a3,a4,0x2
    800042e0:	0001e717          	auipc	a4,0x1e
    800042e4:	82870713          	addi	a4,a4,-2008 # 80021b08 <log>
    800042e8:	9736                	add	a4,a4,a3
    800042ea:	44d4                	lw	a3,12(s1)
    800042ec:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042ee:	faf607e3          	beq	a2,a5,8000429c <log_write+0x7c>
  }
  release(&log.lock);
    800042f2:	0001e517          	auipc	a0,0x1e
    800042f6:	81650513          	addi	a0,a0,-2026 # 80021b08 <log>
    800042fa:	ffffd097          	auipc	ra,0xffffd
    800042fe:	9ca080e7          	jalr	-1590(ra) # 80000cc4 <release>
}
    80004302:	60e2                	ld	ra,24(sp)
    80004304:	6442                	ld	s0,16(sp)
    80004306:	64a2                	ld	s1,8(sp)
    80004308:	6902                	ld	s2,0(sp)
    8000430a:	6105                	addi	sp,sp,32
    8000430c:	8082                	ret

000000008000430e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000430e:	1101                	addi	sp,sp,-32
    80004310:	ec06                	sd	ra,24(sp)
    80004312:	e822                	sd	s0,16(sp)
    80004314:	e426                	sd	s1,8(sp)
    80004316:	e04a                	sd	s2,0(sp)
    80004318:	1000                	addi	s0,sp,32
    8000431a:	84aa                	mv	s1,a0
    8000431c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000431e:	00004597          	auipc	a1,0x4
    80004322:	4b258593          	addi	a1,a1,1202 # 800087d0 <sysnames+0x230>
    80004326:	0521                	addi	a0,a0,8
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	858080e7          	jalr	-1960(ra) # 80000b80 <initlock>
  lk->name = name;
    80004330:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004334:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004338:	0204a423          	sw	zero,40(s1)
}
    8000433c:	60e2                	ld	ra,24(sp)
    8000433e:	6442                	ld	s0,16(sp)
    80004340:	64a2                	ld	s1,8(sp)
    80004342:	6902                	ld	s2,0(sp)
    80004344:	6105                	addi	sp,sp,32
    80004346:	8082                	ret

0000000080004348 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004348:	1101                	addi	sp,sp,-32
    8000434a:	ec06                	sd	ra,24(sp)
    8000434c:	e822                	sd	s0,16(sp)
    8000434e:	e426                	sd	s1,8(sp)
    80004350:	e04a                	sd	s2,0(sp)
    80004352:	1000                	addi	s0,sp,32
    80004354:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004356:	00850913          	addi	s2,a0,8
    8000435a:	854a                	mv	a0,s2
    8000435c:	ffffd097          	auipc	ra,0xffffd
    80004360:	8b4080e7          	jalr	-1868(ra) # 80000c10 <acquire>
  while (lk->locked) {
    80004364:	409c                	lw	a5,0(s1)
    80004366:	cb89                	beqz	a5,80004378 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004368:	85ca                	mv	a1,s2
    8000436a:	8526                	mv	a0,s1
    8000436c:	ffffe097          	auipc	ra,0xffffe
    80004370:	e8a080e7          	jalr	-374(ra) # 800021f6 <sleep>
  while (lk->locked) {
    80004374:	409c                	lw	a5,0(s1)
    80004376:	fbed                	bnez	a5,80004368 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004378:	4785                	li	a5,1
    8000437a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000437c:	ffffd097          	auipc	ra,0xffffd
    80004380:	662080e7          	jalr	1634(ra) # 800019de <myproc>
    80004384:	5d1c                	lw	a5,56(a0)
    80004386:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004388:	854a                	mv	a0,s2
    8000438a:	ffffd097          	auipc	ra,0xffffd
    8000438e:	93a080e7          	jalr	-1734(ra) # 80000cc4 <release>
}
    80004392:	60e2                	ld	ra,24(sp)
    80004394:	6442                	ld	s0,16(sp)
    80004396:	64a2                	ld	s1,8(sp)
    80004398:	6902                	ld	s2,0(sp)
    8000439a:	6105                	addi	sp,sp,32
    8000439c:	8082                	ret

000000008000439e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000439e:	1101                	addi	sp,sp,-32
    800043a0:	ec06                	sd	ra,24(sp)
    800043a2:	e822                	sd	s0,16(sp)
    800043a4:	e426                	sd	s1,8(sp)
    800043a6:	e04a                	sd	s2,0(sp)
    800043a8:	1000                	addi	s0,sp,32
    800043aa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043ac:	00850913          	addi	s2,a0,8
    800043b0:	854a                	mv	a0,s2
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	85e080e7          	jalr	-1954(ra) # 80000c10 <acquire>
  lk->locked = 0;
    800043ba:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043be:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043c2:	8526                	mv	a0,s1
    800043c4:	ffffe097          	auipc	ra,0xffffe
    800043c8:	fb8080e7          	jalr	-72(ra) # 8000237c <wakeup>
  release(&lk->lk);
    800043cc:	854a                	mv	a0,s2
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	8f6080e7          	jalr	-1802(ra) # 80000cc4 <release>
}
    800043d6:	60e2                	ld	ra,24(sp)
    800043d8:	6442                	ld	s0,16(sp)
    800043da:	64a2                	ld	s1,8(sp)
    800043dc:	6902                	ld	s2,0(sp)
    800043de:	6105                	addi	sp,sp,32
    800043e0:	8082                	ret

00000000800043e2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043e2:	7179                	addi	sp,sp,-48
    800043e4:	f406                	sd	ra,40(sp)
    800043e6:	f022                	sd	s0,32(sp)
    800043e8:	ec26                	sd	s1,24(sp)
    800043ea:	e84a                	sd	s2,16(sp)
    800043ec:	e44e                	sd	s3,8(sp)
    800043ee:	1800                	addi	s0,sp,48
    800043f0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043f2:	00850913          	addi	s2,a0,8
    800043f6:	854a                	mv	a0,s2
    800043f8:	ffffd097          	auipc	ra,0xffffd
    800043fc:	818080e7          	jalr	-2024(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004400:	409c                	lw	a5,0(s1)
    80004402:	ef99                	bnez	a5,80004420 <holdingsleep+0x3e>
    80004404:	4481                	li	s1,0
  release(&lk->lk);
    80004406:	854a                	mv	a0,s2
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	8bc080e7          	jalr	-1860(ra) # 80000cc4 <release>
  return r;
}
    80004410:	8526                	mv	a0,s1
    80004412:	70a2                	ld	ra,40(sp)
    80004414:	7402                	ld	s0,32(sp)
    80004416:	64e2                	ld	s1,24(sp)
    80004418:	6942                	ld	s2,16(sp)
    8000441a:	69a2                	ld	s3,8(sp)
    8000441c:	6145                	addi	sp,sp,48
    8000441e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004420:	0284a983          	lw	s3,40(s1)
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	5ba080e7          	jalr	1466(ra) # 800019de <myproc>
    8000442c:	5d04                	lw	s1,56(a0)
    8000442e:	413484b3          	sub	s1,s1,s3
    80004432:	0014b493          	seqz	s1,s1
    80004436:	bfc1                	j	80004406 <holdingsleep+0x24>

0000000080004438 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004438:	1141                	addi	sp,sp,-16
    8000443a:	e406                	sd	ra,8(sp)
    8000443c:	e022                	sd	s0,0(sp)
    8000443e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004440:	00004597          	auipc	a1,0x4
    80004444:	3a058593          	addi	a1,a1,928 # 800087e0 <sysnames+0x240>
    80004448:	0001e517          	auipc	a0,0x1e
    8000444c:	80850513          	addi	a0,a0,-2040 # 80021c50 <ftable>
    80004450:	ffffc097          	auipc	ra,0xffffc
    80004454:	730080e7          	jalr	1840(ra) # 80000b80 <initlock>
}
    80004458:	60a2                	ld	ra,8(sp)
    8000445a:	6402                	ld	s0,0(sp)
    8000445c:	0141                	addi	sp,sp,16
    8000445e:	8082                	ret

0000000080004460 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004460:	1101                	addi	sp,sp,-32
    80004462:	ec06                	sd	ra,24(sp)
    80004464:	e822                	sd	s0,16(sp)
    80004466:	e426                	sd	s1,8(sp)
    80004468:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000446a:	0001d517          	auipc	a0,0x1d
    8000446e:	7e650513          	addi	a0,a0,2022 # 80021c50 <ftable>
    80004472:	ffffc097          	auipc	ra,0xffffc
    80004476:	79e080e7          	jalr	1950(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000447a:	0001d497          	auipc	s1,0x1d
    8000447e:	7ee48493          	addi	s1,s1,2030 # 80021c68 <ftable+0x18>
    80004482:	0001e717          	auipc	a4,0x1e
    80004486:	78670713          	addi	a4,a4,1926 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    8000448a:	40dc                	lw	a5,4(s1)
    8000448c:	cf99                	beqz	a5,800044aa <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000448e:	02848493          	addi	s1,s1,40
    80004492:	fee49ce3          	bne	s1,a4,8000448a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004496:	0001d517          	auipc	a0,0x1d
    8000449a:	7ba50513          	addi	a0,a0,1978 # 80021c50 <ftable>
    8000449e:	ffffd097          	auipc	ra,0xffffd
    800044a2:	826080e7          	jalr	-2010(ra) # 80000cc4 <release>
  return 0;
    800044a6:	4481                	li	s1,0
    800044a8:	a819                	j	800044be <filealloc+0x5e>
      f->ref = 1;
    800044aa:	4785                	li	a5,1
    800044ac:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044ae:	0001d517          	auipc	a0,0x1d
    800044b2:	7a250513          	addi	a0,a0,1954 # 80021c50 <ftable>
    800044b6:	ffffd097          	auipc	ra,0xffffd
    800044ba:	80e080e7          	jalr	-2034(ra) # 80000cc4 <release>
}
    800044be:	8526                	mv	a0,s1
    800044c0:	60e2                	ld	ra,24(sp)
    800044c2:	6442                	ld	s0,16(sp)
    800044c4:	64a2                	ld	s1,8(sp)
    800044c6:	6105                	addi	sp,sp,32
    800044c8:	8082                	ret

00000000800044ca <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044ca:	1101                	addi	sp,sp,-32
    800044cc:	ec06                	sd	ra,24(sp)
    800044ce:	e822                	sd	s0,16(sp)
    800044d0:	e426                	sd	s1,8(sp)
    800044d2:	1000                	addi	s0,sp,32
    800044d4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044d6:	0001d517          	auipc	a0,0x1d
    800044da:	77a50513          	addi	a0,a0,1914 # 80021c50 <ftable>
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	732080e7          	jalr	1842(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800044e6:	40dc                	lw	a5,4(s1)
    800044e8:	02f05263          	blez	a5,8000450c <filedup+0x42>
    panic("filedup");
  f->ref++;
    800044ec:	2785                	addiw	a5,a5,1
    800044ee:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800044f0:	0001d517          	auipc	a0,0x1d
    800044f4:	76050513          	addi	a0,a0,1888 # 80021c50 <ftable>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	7cc080e7          	jalr	1996(ra) # 80000cc4 <release>
  return f;
}
    80004500:	8526                	mv	a0,s1
    80004502:	60e2                	ld	ra,24(sp)
    80004504:	6442                	ld	s0,16(sp)
    80004506:	64a2                	ld	s1,8(sp)
    80004508:	6105                	addi	sp,sp,32
    8000450a:	8082                	ret
    panic("filedup");
    8000450c:	00004517          	auipc	a0,0x4
    80004510:	2dc50513          	addi	a0,a0,732 # 800087e8 <sysnames+0x248>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	034080e7          	jalr	52(ra) # 80000548 <panic>

000000008000451c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000451c:	7139                	addi	sp,sp,-64
    8000451e:	fc06                	sd	ra,56(sp)
    80004520:	f822                	sd	s0,48(sp)
    80004522:	f426                	sd	s1,40(sp)
    80004524:	f04a                	sd	s2,32(sp)
    80004526:	ec4e                	sd	s3,24(sp)
    80004528:	e852                	sd	s4,16(sp)
    8000452a:	e456                	sd	s5,8(sp)
    8000452c:	0080                	addi	s0,sp,64
    8000452e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004530:	0001d517          	auipc	a0,0x1d
    80004534:	72050513          	addi	a0,a0,1824 # 80021c50 <ftable>
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	6d8080e7          	jalr	1752(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    80004540:	40dc                	lw	a5,4(s1)
    80004542:	06f05163          	blez	a5,800045a4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004546:	37fd                	addiw	a5,a5,-1
    80004548:	0007871b          	sext.w	a4,a5
    8000454c:	c0dc                	sw	a5,4(s1)
    8000454e:	06e04363          	bgtz	a4,800045b4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004552:	0004a903          	lw	s2,0(s1)
    80004556:	0094ca83          	lbu	s5,9(s1)
    8000455a:	0104ba03          	ld	s4,16(s1)
    8000455e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004562:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004566:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000456a:	0001d517          	auipc	a0,0x1d
    8000456e:	6e650513          	addi	a0,a0,1766 # 80021c50 <ftable>
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	752080e7          	jalr	1874(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    8000457a:	4785                	li	a5,1
    8000457c:	04f90d63          	beq	s2,a5,800045d6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004580:	3979                	addiw	s2,s2,-2
    80004582:	4785                	li	a5,1
    80004584:	0527e063          	bltu	a5,s2,800045c4 <fileclose+0xa8>
    begin_op();
    80004588:	00000097          	auipc	ra,0x0
    8000458c:	ac2080e7          	jalr	-1342(ra) # 8000404a <begin_op>
    iput(ff.ip);
    80004590:	854e                	mv	a0,s3
    80004592:	fffff097          	auipc	ra,0xfffff
    80004596:	2b6080e7          	jalr	694(ra) # 80003848 <iput>
    end_op();
    8000459a:	00000097          	auipc	ra,0x0
    8000459e:	b30080e7          	jalr	-1232(ra) # 800040ca <end_op>
    800045a2:	a00d                	j	800045c4 <fileclose+0xa8>
    panic("fileclose");
    800045a4:	00004517          	auipc	a0,0x4
    800045a8:	24c50513          	addi	a0,a0,588 # 800087f0 <sysnames+0x250>
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	f9c080e7          	jalr	-100(ra) # 80000548 <panic>
    release(&ftable.lock);
    800045b4:	0001d517          	auipc	a0,0x1d
    800045b8:	69c50513          	addi	a0,a0,1692 # 80021c50 <ftable>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	708080e7          	jalr	1800(ra) # 80000cc4 <release>
  }
}
    800045c4:	70e2                	ld	ra,56(sp)
    800045c6:	7442                	ld	s0,48(sp)
    800045c8:	74a2                	ld	s1,40(sp)
    800045ca:	7902                	ld	s2,32(sp)
    800045cc:	69e2                	ld	s3,24(sp)
    800045ce:	6a42                	ld	s4,16(sp)
    800045d0:	6aa2                	ld	s5,8(sp)
    800045d2:	6121                	addi	sp,sp,64
    800045d4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045d6:	85d6                	mv	a1,s5
    800045d8:	8552                	mv	a0,s4
    800045da:	00000097          	auipc	ra,0x0
    800045de:	372080e7          	jalr	882(ra) # 8000494c <pipeclose>
    800045e2:	b7cd                	j	800045c4 <fileclose+0xa8>

00000000800045e4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045e4:	715d                	addi	sp,sp,-80
    800045e6:	e486                	sd	ra,72(sp)
    800045e8:	e0a2                	sd	s0,64(sp)
    800045ea:	fc26                	sd	s1,56(sp)
    800045ec:	f84a                	sd	s2,48(sp)
    800045ee:	f44e                	sd	s3,40(sp)
    800045f0:	0880                	addi	s0,sp,80
    800045f2:	84aa                	mv	s1,a0
    800045f4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045f6:	ffffd097          	auipc	ra,0xffffd
    800045fa:	3e8080e7          	jalr	1000(ra) # 800019de <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045fe:	409c                	lw	a5,0(s1)
    80004600:	37f9                	addiw	a5,a5,-2
    80004602:	4705                	li	a4,1
    80004604:	04f76763          	bltu	a4,a5,80004652 <filestat+0x6e>
    80004608:	892a                	mv	s2,a0
    ilock(f->ip);
    8000460a:	6c88                	ld	a0,24(s1)
    8000460c:	fffff097          	auipc	ra,0xfffff
    80004610:	082080e7          	jalr	130(ra) # 8000368e <ilock>
    stati(f->ip, &st);
    80004614:	fb840593          	addi	a1,s0,-72
    80004618:	6c88                	ld	a0,24(s1)
    8000461a:	fffff097          	auipc	ra,0xfffff
    8000461e:	2fe080e7          	jalr	766(ra) # 80003918 <stati>
    iunlock(f->ip);
    80004622:	6c88                	ld	a0,24(s1)
    80004624:	fffff097          	auipc	ra,0xfffff
    80004628:	12c080e7          	jalr	300(ra) # 80003750 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000462c:	46e1                	li	a3,24
    8000462e:	fb840613          	addi	a2,s0,-72
    80004632:	85ce                	mv	a1,s3
    80004634:	05093503          	ld	a0,80(s2)
    80004638:	ffffd097          	auipc	ra,0xffffd
    8000463c:	09a080e7          	jalr	154(ra) # 800016d2 <copyout>
    80004640:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004644:	60a6                	ld	ra,72(sp)
    80004646:	6406                	ld	s0,64(sp)
    80004648:	74e2                	ld	s1,56(sp)
    8000464a:	7942                	ld	s2,48(sp)
    8000464c:	79a2                	ld	s3,40(sp)
    8000464e:	6161                	addi	sp,sp,80
    80004650:	8082                	ret
  return -1;
    80004652:	557d                	li	a0,-1
    80004654:	bfc5                	j	80004644 <filestat+0x60>

0000000080004656 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004656:	7179                	addi	sp,sp,-48
    80004658:	f406                	sd	ra,40(sp)
    8000465a:	f022                	sd	s0,32(sp)
    8000465c:	ec26                	sd	s1,24(sp)
    8000465e:	e84a                	sd	s2,16(sp)
    80004660:	e44e                	sd	s3,8(sp)
    80004662:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004664:	00854783          	lbu	a5,8(a0)
    80004668:	c3d5                	beqz	a5,8000470c <fileread+0xb6>
    8000466a:	84aa                	mv	s1,a0
    8000466c:	89ae                	mv	s3,a1
    8000466e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004670:	411c                	lw	a5,0(a0)
    80004672:	4705                	li	a4,1
    80004674:	04e78963          	beq	a5,a4,800046c6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004678:	470d                	li	a4,3
    8000467a:	04e78d63          	beq	a5,a4,800046d4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000467e:	4709                	li	a4,2
    80004680:	06e79e63          	bne	a5,a4,800046fc <fileread+0xa6>
    ilock(f->ip);
    80004684:	6d08                	ld	a0,24(a0)
    80004686:	fffff097          	auipc	ra,0xfffff
    8000468a:	008080e7          	jalr	8(ra) # 8000368e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000468e:	874a                	mv	a4,s2
    80004690:	5094                	lw	a3,32(s1)
    80004692:	864e                	mv	a2,s3
    80004694:	4585                	li	a1,1
    80004696:	6c88                	ld	a0,24(s1)
    80004698:	fffff097          	auipc	ra,0xfffff
    8000469c:	2aa080e7          	jalr	682(ra) # 80003942 <readi>
    800046a0:	892a                	mv	s2,a0
    800046a2:	00a05563          	blez	a0,800046ac <fileread+0x56>
      f->off += r;
    800046a6:	509c                	lw	a5,32(s1)
    800046a8:	9fa9                	addw	a5,a5,a0
    800046aa:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046ac:	6c88                	ld	a0,24(s1)
    800046ae:	fffff097          	auipc	ra,0xfffff
    800046b2:	0a2080e7          	jalr	162(ra) # 80003750 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046b6:	854a                	mv	a0,s2
    800046b8:	70a2                	ld	ra,40(sp)
    800046ba:	7402                	ld	s0,32(sp)
    800046bc:	64e2                	ld	s1,24(sp)
    800046be:	6942                	ld	s2,16(sp)
    800046c0:	69a2                	ld	s3,8(sp)
    800046c2:	6145                	addi	sp,sp,48
    800046c4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046c6:	6908                	ld	a0,16(a0)
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	418080e7          	jalr	1048(ra) # 80004ae0 <piperead>
    800046d0:	892a                	mv	s2,a0
    800046d2:	b7d5                	j	800046b6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046d4:	02451783          	lh	a5,36(a0)
    800046d8:	03079693          	slli	a3,a5,0x30
    800046dc:	92c1                	srli	a3,a3,0x30
    800046de:	4725                	li	a4,9
    800046e0:	02d76863          	bltu	a4,a3,80004710 <fileread+0xba>
    800046e4:	0792                	slli	a5,a5,0x4
    800046e6:	0001d717          	auipc	a4,0x1d
    800046ea:	4ca70713          	addi	a4,a4,1226 # 80021bb0 <devsw>
    800046ee:	97ba                	add	a5,a5,a4
    800046f0:	639c                	ld	a5,0(a5)
    800046f2:	c38d                	beqz	a5,80004714 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046f4:	4505                	li	a0,1
    800046f6:	9782                	jalr	a5
    800046f8:	892a                	mv	s2,a0
    800046fa:	bf75                	j	800046b6 <fileread+0x60>
    panic("fileread");
    800046fc:	00004517          	auipc	a0,0x4
    80004700:	10450513          	addi	a0,a0,260 # 80008800 <sysnames+0x260>
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	e44080e7          	jalr	-444(ra) # 80000548 <panic>
    return -1;
    8000470c:	597d                	li	s2,-1
    8000470e:	b765                	j	800046b6 <fileread+0x60>
      return -1;
    80004710:	597d                	li	s2,-1
    80004712:	b755                	j	800046b6 <fileread+0x60>
    80004714:	597d                	li	s2,-1
    80004716:	b745                	j	800046b6 <fileread+0x60>

0000000080004718 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004718:	00954783          	lbu	a5,9(a0)
    8000471c:	14078563          	beqz	a5,80004866 <filewrite+0x14e>
{
    80004720:	715d                	addi	sp,sp,-80
    80004722:	e486                	sd	ra,72(sp)
    80004724:	e0a2                	sd	s0,64(sp)
    80004726:	fc26                	sd	s1,56(sp)
    80004728:	f84a                	sd	s2,48(sp)
    8000472a:	f44e                	sd	s3,40(sp)
    8000472c:	f052                	sd	s4,32(sp)
    8000472e:	ec56                	sd	s5,24(sp)
    80004730:	e85a                	sd	s6,16(sp)
    80004732:	e45e                	sd	s7,8(sp)
    80004734:	e062                	sd	s8,0(sp)
    80004736:	0880                	addi	s0,sp,80
    80004738:	892a                	mv	s2,a0
    8000473a:	8aae                	mv	s5,a1
    8000473c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000473e:	411c                	lw	a5,0(a0)
    80004740:	4705                	li	a4,1
    80004742:	02e78263          	beq	a5,a4,80004766 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004746:	470d                	li	a4,3
    80004748:	02e78563          	beq	a5,a4,80004772 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000474c:	4709                	li	a4,2
    8000474e:	10e79463          	bne	a5,a4,80004856 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004752:	0ec05e63          	blez	a2,8000484e <filewrite+0x136>
    int i = 0;
    80004756:	4981                	li	s3,0
    80004758:	6b05                	lui	s6,0x1
    8000475a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000475e:	6b85                	lui	s7,0x1
    80004760:	c00b8b9b          	addiw	s7,s7,-1024
    80004764:	a851                	j	800047f8 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004766:	6908                	ld	a0,16(a0)
    80004768:	00000097          	auipc	ra,0x0
    8000476c:	254080e7          	jalr	596(ra) # 800049bc <pipewrite>
    80004770:	a85d                	j	80004826 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004772:	02451783          	lh	a5,36(a0)
    80004776:	03079693          	slli	a3,a5,0x30
    8000477a:	92c1                	srli	a3,a3,0x30
    8000477c:	4725                	li	a4,9
    8000477e:	0ed76663          	bltu	a4,a3,8000486a <filewrite+0x152>
    80004782:	0792                	slli	a5,a5,0x4
    80004784:	0001d717          	auipc	a4,0x1d
    80004788:	42c70713          	addi	a4,a4,1068 # 80021bb0 <devsw>
    8000478c:	97ba                	add	a5,a5,a4
    8000478e:	679c                	ld	a5,8(a5)
    80004790:	cff9                	beqz	a5,8000486e <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004792:	4505                	li	a0,1
    80004794:	9782                	jalr	a5
    80004796:	a841                	j	80004826 <filewrite+0x10e>
    80004798:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000479c:	00000097          	auipc	ra,0x0
    800047a0:	8ae080e7          	jalr	-1874(ra) # 8000404a <begin_op>
      ilock(f->ip);
    800047a4:	01893503          	ld	a0,24(s2)
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	ee6080e7          	jalr	-282(ra) # 8000368e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047b0:	8762                	mv	a4,s8
    800047b2:	02092683          	lw	a3,32(s2)
    800047b6:	01598633          	add	a2,s3,s5
    800047ba:	4585                	li	a1,1
    800047bc:	01893503          	ld	a0,24(s2)
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	278080e7          	jalr	632(ra) # 80003a38 <writei>
    800047c8:	84aa                	mv	s1,a0
    800047ca:	02a05f63          	blez	a0,80004808 <filewrite+0xf0>
        f->off += r;
    800047ce:	02092783          	lw	a5,32(s2)
    800047d2:	9fa9                	addw	a5,a5,a0
    800047d4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047d8:	01893503          	ld	a0,24(s2)
    800047dc:	fffff097          	auipc	ra,0xfffff
    800047e0:	f74080e7          	jalr	-140(ra) # 80003750 <iunlock>
      end_op();
    800047e4:	00000097          	auipc	ra,0x0
    800047e8:	8e6080e7          	jalr	-1818(ra) # 800040ca <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800047ec:	049c1963          	bne	s8,s1,8000483e <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800047f0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047f4:	0349d663          	bge	s3,s4,80004820 <filewrite+0x108>
      int n1 = n - i;
    800047f8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800047fc:	84be                	mv	s1,a5
    800047fe:	2781                	sext.w	a5,a5
    80004800:	f8fb5ce3          	bge	s6,a5,80004798 <filewrite+0x80>
    80004804:	84de                	mv	s1,s7
    80004806:	bf49                	j	80004798 <filewrite+0x80>
      iunlock(f->ip);
    80004808:	01893503          	ld	a0,24(s2)
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	f44080e7          	jalr	-188(ra) # 80003750 <iunlock>
      end_op();
    80004814:	00000097          	auipc	ra,0x0
    80004818:	8b6080e7          	jalr	-1866(ra) # 800040ca <end_op>
      if(r < 0)
    8000481c:	fc04d8e3          	bgez	s1,800047ec <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004820:	8552                	mv	a0,s4
    80004822:	033a1863          	bne	s4,s3,80004852 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004826:	60a6                	ld	ra,72(sp)
    80004828:	6406                	ld	s0,64(sp)
    8000482a:	74e2                	ld	s1,56(sp)
    8000482c:	7942                	ld	s2,48(sp)
    8000482e:	79a2                	ld	s3,40(sp)
    80004830:	7a02                	ld	s4,32(sp)
    80004832:	6ae2                	ld	s5,24(sp)
    80004834:	6b42                	ld	s6,16(sp)
    80004836:	6ba2                	ld	s7,8(sp)
    80004838:	6c02                	ld	s8,0(sp)
    8000483a:	6161                	addi	sp,sp,80
    8000483c:	8082                	ret
        panic("short filewrite");
    8000483e:	00004517          	auipc	a0,0x4
    80004842:	fd250513          	addi	a0,a0,-46 # 80008810 <sysnames+0x270>
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	d02080e7          	jalr	-766(ra) # 80000548 <panic>
    int i = 0;
    8000484e:	4981                	li	s3,0
    80004850:	bfc1                	j	80004820 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004852:	557d                	li	a0,-1
    80004854:	bfc9                	j	80004826 <filewrite+0x10e>
    panic("filewrite");
    80004856:	00004517          	auipc	a0,0x4
    8000485a:	fca50513          	addi	a0,a0,-54 # 80008820 <sysnames+0x280>
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	cea080e7          	jalr	-790(ra) # 80000548 <panic>
    return -1;
    80004866:	557d                	li	a0,-1
}
    80004868:	8082                	ret
      return -1;
    8000486a:	557d                	li	a0,-1
    8000486c:	bf6d                	j	80004826 <filewrite+0x10e>
    8000486e:	557d                	li	a0,-1
    80004870:	bf5d                	j	80004826 <filewrite+0x10e>

0000000080004872 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004872:	7179                	addi	sp,sp,-48
    80004874:	f406                	sd	ra,40(sp)
    80004876:	f022                	sd	s0,32(sp)
    80004878:	ec26                	sd	s1,24(sp)
    8000487a:	e84a                	sd	s2,16(sp)
    8000487c:	e44e                	sd	s3,8(sp)
    8000487e:	e052                	sd	s4,0(sp)
    80004880:	1800                	addi	s0,sp,48
    80004882:	84aa                	mv	s1,a0
    80004884:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004886:	0005b023          	sd	zero,0(a1)
    8000488a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	bd2080e7          	jalr	-1070(ra) # 80004460 <filealloc>
    80004896:	e088                	sd	a0,0(s1)
    80004898:	c551                	beqz	a0,80004924 <pipealloc+0xb2>
    8000489a:	00000097          	auipc	ra,0x0
    8000489e:	bc6080e7          	jalr	-1082(ra) # 80004460 <filealloc>
    800048a2:	00aa3023          	sd	a0,0(s4)
    800048a6:	c92d                	beqz	a0,80004918 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	278080e7          	jalr	632(ra) # 80000b20 <kalloc>
    800048b0:	892a                	mv	s2,a0
    800048b2:	c125                	beqz	a0,80004912 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048b4:	4985                	li	s3,1
    800048b6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048ba:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048be:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048c2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048c6:	00004597          	auipc	a1,0x4
    800048ca:	b7a58593          	addi	a1,a1,-1158 # 80008440 <states.1703+0x198>
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	2b2080e7          	jalr	690(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    800048d6:	609c                	ld	a5,0(s1)
    800048d8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048dc:	609c                	ld	a5,0(s1)
    800048de:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048e2:	609c                	ld	a5,0(s1)
    800048e4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048e8:	609c                	ld	a5,0(s1)
    800048ea:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048ee:	000a3783          	ld	a5,0(s4)
    800048f2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048f6:	000a3783          	ld	a5,0(s4)
    800048fa:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048fe:	000a3783          	ld	a5,0(s4)
    80004902:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004906:	000a3783          	ld	a5,0(s4)
    8000490a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000490e:	4501                	li	a0,0
    80004910:	a025                	j	80004938 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004912:	6088                	ld	a0,0(s1)
    80004914:	e501                	bnez	a0,8000491c <pipealloc+0xaa>
    80004916:	a039                	j	80004924 <pipealloc+0xb2>
    80004918:	6088                	ld	a0,0(s1)
    8000491a:	c51d                	beqz	a0,80004948 <pipealloc+0xd6>
    fileclose(*f0);
    8000491c:	00000097          	auipc	ra,0x0
    80004920:	c00080e7          	jalr	-1024(ra) # 8000451c <fileclose>
  if(*f1)
    80004924:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004928:	557d                	li	a0,-1
  if(*f1)
    8000492a:	c799                	beqz	a5,80004938 <pipealloc+0xc6>
    fileclose(*f1);
    8000492c:	853e                	mv	a0,a5
    8000492e:	00000097          	auipc	ra,0x0
    80004932:	bee080e7          	jalr	-1042(ra) # 8000451c <fileclose>
  return -1;
    80004936:	557d                	li	a0,-1
}
    80004938:	70a2                	ld	ra,40(sp)
    8000493a:	7402                	ld	s0,32(sp)
    8000493c:	64e2                	ld	s1,24(sp)
    8000493e:	6942                	ld	s2,16(sp)
    80004940:	69a2                	ld	s3,8(sp)
    80004942:	6a02                	ld	s4,0(sp)
    80004944:	6145                	addi	sp,sp,48
    80004946:	8082                	ret
  return -1;
    80004948:	557d                	li	a0,-1
    8000494a:	b7fd                	j	80004938 <pipealloc+0xc6>

000000008000494c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000494c:	1101                	addi	sp,sp,-32
    8000494e:	ec06                	sd	ra,24(sp)
    80004950:	e822                	sd	s0,16(sp)
    80004952:	e426                	sd	s1,8(sp)
    80004954:	e04a                	sd	s2,0(sp)
    80004956:	1000                	addi	s0,sp,32
    80004958:	84aa                	mv	s1,a0
    8000495a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	2b4080e7          	jalr	692(ra) # 80000c10 <acquire>
  if(writable){
    80004964:	02090d63          	beqz	s2,8000499e <pipeclose+0x52>
    pi->writeopen = 0;
    80004968:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000496c:	21848513          	addi	a0,s1,536
    80004970:	ffffe097          	auipc	ra,0xffffe
    80004974:	a0c080e7          	jalr	-1524(ra) # 8000237c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004978:	2204b783          	ld	a5,544(s1)
    8000497c:	eb95                	bnez	a5,800049b0 <pipeclose+0x64>
    release(&pi->lock);
    8000497e:	8526                	mv	a0,s1
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	344080e7          	jalr	836(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004988:	8526                	mv	a0,s1
    8000498a:	ffffc097          	auipc	ra,0xffffc
    8000498e:	09a080e7          	jalr	154(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004992:	60e2                	ld	ra,24(sp)
    80004994:	6442                	ld	s0,16(sp)
    80004996:	64a2                	ld	s1,8(sp)
    80004998:	6902                	ld	s2,0(sp)
    8000499a:	6105                	addi	sp,sp,32
    8000499c:	8082                	ret
    pi->readopen = 0;
    8000499e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049a2:	21c48513          	addi	a0,s1,540
    800049a6:	ffffe097          	auipc	ra,0xffffe
    800049aa:	9d6080e7          	jalr	-1578(ra) # 8000237c <wakeup>
    800049ae:	b7e9                	j	80004978 <pipeclose+0x2c>
    release(&pi->lock);
    800049b0:	8526                	mv	a0,s1
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	312080e7          	jalr	786(ra) # 80000cc4 <release>
}
    800049ba:	bfe1                	j	80004992 <pipeclose+0x46>

00000000800049bc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049bc:	7119                	addi	sp,sp,-128
    800049be:	fc86                	sd	ra,120(sp)
    800049c0:	f8a2                	sd	s0,112(sp)
    800049c2:	f4a6                	sd	s1,104(sp)
    800049c4:	f0ca                	sd	s2,96(sp)
    800049c6:	ecce                	sd	s3,88(sp)
    800049c8:	e8d2                	sd	s4,80(sp)
    800049ca:	e4d6                	sd	s5,72(sp)
    800049cc:	e0da                	sd	s6,64(sp)
    800049ce:	fc5e                	sd	s7,56(sp)
    800049d0:	f862                	sd	s8,48(sp)
    800049d2:	f466                	sd	s9,40(sp)
    800049d4:	f06a                	sd	s10,32(sp)
    800049d6:	ec6e                	sd	s11,24(sp)
    800049d8:	0100                	addi	s0,sp,128
    800049da:	84aa                	mv	s1,a0
    800049dc:	8cae                	mv	s9,a1
    800049de:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    800049e0:	ffffd097          	auipc	ra,0xffffd
    800049e4:	ffe080e7          	jalr	-2(ra) # 800019de <myproc>
    800049e8:	892a                	mv	s2,a0

  acquire(&pi->lock);
    800049ea:	8526                	mv	a0,s1
    800049ec:	ffffc097          	auipc	ra,0xffffc
    800049f0:	224080e7          	jalr	548(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    800049f4:	0d605963          	blez	s6,80004ac6 <pipewrite+0x10a>
    800049f8:	89a6                	mv	s3,s1
    800049fa:	3b7d                	addiw	s6,s6,-1
    800049fc:	1b02                	slli	s6,s6,0x20
    800049fe:	020b5b13          	srli	s6,s6,0x20
    80004a02:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004a04:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a08:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a0c:	5dfd                	li	s11,-1
    80004a0e:	000b8d1b          	sext.w	s10,s7
    80004a12:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a14:	2184a783          	lw	a5,536(s1)
    80004a18:	21c4a703          	lw	a4,540(s1)
    80004a1c:	2007879b          	addiw	a5,a5,512
    80004a20:	02f71b63          	bne	a4,a5,80004a56 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004a24:	2204a783          	lw	a5,544(s1)
    80004a28:	cbad                	beqz	a5,80004a9a <pipewrite+0xde>
    80004a2a:	03092783          	lw	a5,48(s2)
    80004a2e:	e7b5                	bnez	a5,80004a9a <pipewrite+0xde>
      wakeup(&pi->nread);
    80004a30:	8556                	mv	a0,s5
    80004a32:	ffffe097          	auipc	ra,0xffffe
    80004a36:	94a080e7          	jalr	-1718(ra) # 8000237c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a3a:	85ce                	mv	a1,s3
    80004a3c:	8552                	mv	a0,s4
    80004a3e:	ffffd097          	auipc	ra,0xffffd
    80004a42:	7b8080e7          	jalr	1976(ra) # 800021f6 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a46:	2184a783          	lw	a5,536(s1)
    80004a4a:	21c4a703          	lw	a4,540(s1)
    80004a4e:	2007879b          	addiw	a5,a5,512
    80004a52:	fcf709e3          	beq	a4,a5,80004a24 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a56:	4685                	li	a3,1
    80004a58:	019b8633          	add	a2,s7,s9
    80004a5c:	f8f40593          	addi	a1,s0,-113
    80004a60:	05093503          	ld	a0,80(s2)
    80004a64:	ffffd097          	auipc	ra,0xffffd
    80004a68:	cfa080e7          	jalr	-774(ra) # 8000175e <copyin>
    80004a6c:	05b50e63          	beq	a0,s11,80004ac8 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a70:	21c4a783          	lw	a5,540(s1)
    80004a74:	0017871b          	addiw	a4,a5,1
    80004a78:	20e4ae23          	sw	a4,540(s1)
    80004a7c:	1ff7f793          	andi	a5,a5,511
    80004a80:	97a6                	add	a5,a5,s1
    80004a82:	f8f44703          	lbu	a4,-113(s0)
    80004a86:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004a8a:	001d0c1b          	addiw	s8,s10,1
    80004a8e:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004a92:	036b8b63          	beq	s7,s6,80004ac8 <pipewrite+0x10c>
    80004a96:	8bbe                	mv	s7,a5
    80004a98:	bf9d                	j	80004a0e <pipewrite+0x52>
        release(&pi->lock);
    80004a9a:	8526                	mv	a0,s1
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	228080e7          	jalr	552(ra) # 80000cc4 <release>
        return -1;
    80004aa4:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004aa6:	8562                	mv	a0,s8
    80004aa8:	70e6                	ld	ra,120(sp)
    80004aaa:	7446                	ld	s0,112(sp)
    80004aac:	74a6                	ld	s1,104(sp)
    80004aae:	7906                	ld	s2,96(sp)
    80004ab0:	69e6                	ld	s3,88(sp)
    80004ab2:	6a46                	ld	s4,80(sp)
    80004ab4:	6aa6                	ld	s5,72(sp)
    80004ab6:	6b06                	ld	s6,64(sp)
    80004ab8:	7be2                	ld	s7,56(sp)
    80004aba:	7c42                	ld	s8,48(sp)
    80004abc:	7ca2                	ld	s9,40(sp)
    80004abe:	7d02                	ld	s10,32(sp)
    80004ac0:	6de2                	ld	s11,24(sp)
    80004ac2:	6109                	addi	sp,sp,128
    80004ac4:	8082                	ret
  for(i = 0; i < n; i++){
    80004ac6:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004ac8:	21848513          	addi	a0,s1,536
    80004acc:	ffffe097          	auipc	ra,0xffffe
    80004ad0:	8b0080e7          	jalr	-1872(ra) # 8000237c <wakeup>
  release(&pi->lock);
    80004ad4:	8526                	mv	a0,s1
    80004ad6:	ffffc097          	auipc	ra,0xffffc
    80004ada:	1ee080e7          	jalr	494(ra) # 80000cc4 <release>
  return i;
    80004ade:	b7e1                	j	80004aa6 <pipewrite+0xea>

0000000080004ae0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ae0:	715d                	addi	sp,sp,-80
    80004ae2:	e486                	sd	ra,72(sp)
    80004ae4:	e0a2                	sd	s0,64(sp)
    80004ae6:	fc26                	sd	s1,56(sp)
    80004ae8:	f84a                	sd	s2,48(sp)
    80004aea:	f44e                	sd	s3,40(sp)
    80004aec:	f052                	sd	s4,32(sp)
    80004aee:	ec56                	sd	s5,24(sp)
    80004af0:	e85a                	sd	s6,16(sp)
    80004af2:	0880                	addi	s0,sp,80
    80004af4:	84aa                	mv	s1,a0
    80004af6:	892e                	mv	s2,a1
    80004af8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004afa:	ffffd097          	auipc	ra,0xffffd
    80004afe:	ee4080e7          	jalr	-284(ra) # 800019de <myproc>
    80004b02:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b04:	8b26                	mv	s6,s1
    80004b06:	8526                	mv	a0,s1
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	108080e7          	jalr	264(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b10:	2184a703          	lw	a4,536(s1)
    80004b14:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b18:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b1c:	02f71463          	bne	a4,a5,80004b44 <piperead+0x64>
    80004b20:	2244a783          	lw	a5,548(s1)
    80004b24:	c385                	beqz	a5,80004b44 <piperead+0x64>
    if(pr->killed){
    80004b26:	030a2783          	lw	a5,48(s4)
    80004b2a:	ebc1                	bnez	a5,80004bba <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b2c:	85da                	mv	a1,s6
    80004b2e:	854e                	mv	a0,s3
    80004b30:	ffffd097          	auipc	ra,0xffffd
    80004b34:	6c6080e7          	jalr	1734(ra) # 800021f6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b38:	2184a703          	lw	a4,536(s1)
    80004b3c:	21c4a783          	lw	a5,540(s1)
    80004b40:	fef700e3          	beq	a4,a5,80004b20 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b44:	09505263          	blez	s5,80004bc8 <piperead+0xe8>
    80004b48:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b4a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b4c:	2184a783          	lw	a5,536(s1)
    80004b50:	21c4a703          	lw	a4,540(s1)
    80004b54:	02f70d63          	beq	a4,a5,80004b8e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b58:	0017871b          	addiw	a4,a5,1
    80004b5c:	20e4ac23          	sw	a4,536(s1)
    80004b60:	1ff7f793          	andi	a5,a5,511
    80004b64:	97a6                	add	a5,a5,s1
    80004b66:	0187c783          	lbu	a5,24(a5)
    80004b6a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b6e:	4685                	li	a3,1
    80004b70:	fbf40613          	addi	a2,s0,-65
    80004b74:	85ca                	mv	a1,s2
    80004b76:	050a3503          	ld	a0,80(s4)
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	b58080e7          	jalr	-1192(ra) # 800016d2 <copyout>
    80004b82:	01650663          	beq	a0,s6,80004b8e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b86:	2985                	addiw	s3,s3,1
    80004b88:	0905                	addi	s2,s2,1
    80004b8a:	fd3a91e3          	bne	s5,s3,80004b4c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b8e:	21c48513          	addi	a0,s1,540
    80004b92:	ffffd097          	auipc	ra,0xffffd
    80004b96:	7ea080e7          	jalr	2026(ra) # 8000237c <wakeup>
  release(&pi->lock);
    80004b9a:	8526                	mv	a0,s1
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	128080e7          	jalr	296(ra) # 80000cc4 <release>
  return i;
}
    80004ba4:	854e                	mv	a0,s3
    80004ba6:	60a6                	ld	ra,72(sp)
    80004ba8:	6406                	ld	s0,64(sp)
    80004baa:	74e2                	ld	s1,56(sp)
    80004bac:	7942                	ld	s2,48(sp)
    80004bae:	79a2                	ld	s3,40(sp)
    80004bb0:	7a02                	ld	s4,32(sp)
    80004bb2:	6ae2                	ld	s5,24(sp)
    80004bb4:	6b42                	ld	s6,16(sp)
    80004bb6:	6161                	addi	sp,sp,80
    80004bb8:	8082                	ret
      release(&pi->lock);
    80004bba:	8526                	mv	a0,s1
    80004bbc:	ffffc097          	auipc	ra,0xffffc
    80004bc0:	108080e7          	jalr	264(ra) # 80000cc4 <release>
      return -1;
    80004bc4:	59fd                	li	s3,-1
    80004bc6:	bff9                	j	80004ba4 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bc8:	4981                	li	s3,0
    80004bca:	b7d1                	j	80004b8e <piperead+0xae>

0000000080004bcc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004bcc:	df010113          	addi	sp,sp,-528
    80004bd0:	20113423          	sd	ra,520(sp)
    80004bd4:	20813023          	sd	s0,512(sp)
    80004bd8:	ffa6                	sd	s1,504(sp)
    80004bda:	fbca                	sd	s2,496(sp)
    80004bdc:	f7ce                	sd	s3,488(sp)
    80004bde:	f3d2                	sd	s4,480(sp)
    80004be0:	efd6                	sd	s5,472(sp)
    80004be2:	ebda                	sd	s6,464(sp)
    80004be4:	e7de                	sd	s7,456(sp)
    80004be6:	e3e2                	sd	s8,448(sp)
    80004be8:	ff66                	sd	s9,440(sp)
    80004bea:	fb6a                	sd	s10,432(sp)
    80004bec:	f76e                	sd	s11,424(sp)
    80004bee:	0c00                	addi	s0,sp,528
    80004bf0:	84aa                	mv	s1,a0
    80004bf2:	dea43c23          	sd	a0,-520(s0)
    80004bf6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004bfa:	ffffd097          	auipc	ra,0xffffd
    80004bfe:	de4080e7          	jalr	-540(ra) # 800019de <myproc>
    80004c02:	892a                	mv	s2,a0

  begin_op();
    80004c04:	fffff097          	auipc	ra,0xfffff
    80004c08:	446080e7          	jalr	1094(ra) # 8000404a <begin_op>

  if((ip = namei(path)) == 0){
    80004c0c:	8526                	mv	a0,s1
    80004c0e:	fffff097          	auipc	ra,0xfffff
    80004c12:	230080e7          	jalr	560(ra) # 80003e3e <namei>
    80004c16:	c92d                	beqz	a0,80004c88 <exec+0xbc>
    80004c18:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c1a:	fffff097          	auipc	ra,0xfffff
    80004c1e:	a74080e7          	jalr	-1420(ra) # 8000368e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c22:	04000713          	li	a4,64
    80004c26:	4681                	li	a3,0
    80004c28:	e4840613          	addi	a2,s0,-440
    80004c2c:	4581                	li	a1,0
    80004c2e:	8526                	mv	a0,s1
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	d12080e7          	jalr	-750(ra) # 80003942 <readi>
    80004c38:	04000793          	li	a5,64
    80004c3c:	00f51a63          	bne	a0,a5,80004c50 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c40:	e4842703          	lw	a4,-440(s0)
    80004c44:	464c47b7          	lui	a5,0x464c4
    80004c48:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c4c:	04f70463          	beq	a4,a5,80004c94 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c50:	8526                	mv	a0,s1
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	c9e080e7          	jalr	-866(ra) # 800038f0 <iunlockput>
    end_op();
    80004c5a:	fffff097          	auipc	ra,0xfffff
    80004c5e:	470080e7          	jalr	1136(ra) # 800040ca <end_op>
  }
  return -1;
    80004c62:	557d                	li	a0,-1
}
    80004c64:	20813083          	ld	ra,520(sp)
    80004c68:	20013403          	ld	s0,512(sp)
    80004c6c:	74fe                	ld	s1,504(sp)
    80004c6e:	795e                	ld	s2,496(sp)
    80004c70:	79be                	ld	s3,488(sp)
    80004c72:	7a1e                	ld	s4,480(sp)
    80004c74:	6afe                	ld	s5,472(sp)
    80004c76:	6b5e                	ld	s6,464(sp)
    80004c78:	6bbe                	ld	s7,456(sp)
    80004c7a:	6c1e                	ld	s8,448(sp)
    80004c7c:	7cfa                	ld	s9,440(sp)
    80004c7e:	7d5a                	ld	s10,432(sp)
    80004c80:	7dba                	ld	s11,424(sp)
    80004c82:	21010113          	addi	sp,sp,528
    80004c86:	8082                	ret
    end_op();
    80004c88:	fffff097          	auipc	ra,0xfffff
    80004c8c:	442080e7          	jalr	1090(ra) # 800040ca <end_op>
    return -1;
    80004c90:	557d                	li	a0,-1
    80004c92:	bfc9                	j	80004c64 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c94:	854a                	mv	a0,s2
    80004c96:	ffffd097          	auipc	ra,0xffffd
    80004c9a:	e0c080e7          	jalr	-500(ra) # 80001aa2 <proc_pagetable>
    80004c9e:	8baa                	mv	s7,a0
    80004ca0:	d945                	beqz	a0,80004c50 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ca2:	e6842983          	lw	s3,-408(s0)
    80004ca6:	e8045783          	lhu	a5,-384(s0)
    80004caa:	c7ad                	beqz	a5,80004d14 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004cac:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cae:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004cb0:	6c85                	lui	s9,0x1
    80004cb2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004cb6:	def43823          	sd	a5,-528(s0)
    80004cba:	a42d                	j	80004ee4 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cbc:	00004517          	auipc	a0,0x4
    80004cc0:	b7450513          	addi	a0,a0,-1164 # 80008830 <sysnames+0x290>
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	884080e7          	jalr	-1916(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ccc:	8756                	mv	a4,s5
    80004cce:	012d86bb          	addw	a3,s11,s2
    80004cd2:	4581                	li	a1,0
    80004cd4:	8526                	mv	a0,s1
    80004cd6:	fffff097          	auipc	ra,0xfffff
    80004cda:	c6c080e7          	jalr	-916(ra) # 80003942 <readi>
    80004cde:	2501                	sext.w	a0,a0
    80004ce0:	1aaa9963          	bne	s5,a0,80004e92 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ce4:	6785                	lui	a5,0x1
    80004ce6:	0127893b          	addw	s2,a5,s2
    80004cea:	77fd                	lui	a5,0xfffff
    80004cec:	01478a3b          	addw	s4,a5,s4
    80004cf0:	1f897163          	bgeu	s2,s8,80004ed2 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004cf4:	02091593          	slli	a1,s2,0x20
    80004cf8:	9181                	srli	a1,a1,0x20
    80004cfa:	95ea                	add	a1,a1,s10
    80004cfc:	855e                	mv	a0,s7
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	3a0080e7          	jalr	928(ra) # 8000109e <walkaddr>
    80004d06:	862a                	mv	a2,a0
    if(pa == 0)
    80004d08:	d955                	beqz	a0,80004cbc <exec+0xf0>
      n = PGSIZE;
    80004d0a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d0c:	fd9a70e3          	bgeu	s4,s9,80004ccc <exec+0x100>
      n = sz - i;
    80004d10:	8ad2                	mv	s5,s4
    80004d12:	bf6d                	j	80004ccc <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d14:	4901                	li	s2,0
  iunlockput(ip);
    80004d16:	8526                	mv	a0,s1
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	bd8080e7          	jalr	-1064(ra) # 800038f0 <iunlockput>
  end_op();
    80004d20:	fffff097          	auipc	ra,0xfffff
    80004d24:	3aa080e7          	jalr	938(ra) # 800040ca <end_op>
  p = myproc();
    80004d28:	ffffd097          	auipc	ra,0xffffd
    80004d2c:	cb6080e7          	jalr	-842(ra) # 800019de <myproc>
    80004d30:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d32:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d36:	6785                	lui	a5,0x1
    80004d38:	17fd                	addi	a5,a5,-1
    80004d3a:	993e                	add	s2,s2,a5
    80004d3c:	757d                	lui	a0,0xfffff
    80004d3e:	00a977b3          	and	a5,s2,a0
    80004d42:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d46:	6609                	lui	a2,0x2
    80004d48:	963e                	add	a2,a2,a5
    80004d4a:	85be                	mv	a1,a5
    80004d4c:	855e                	mv	a0,s7
    80004d4e:	ffffc097          	auipc	ra,0xffffc
    80004d52:	734080e7          	jalr	1844(ra) # 80001482 <uvmalloc>
    80004d56:	8b2a                	mv	s6,a0
  ip = 0;
    80004d58:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d5a:	12050c63          	beqz	a0,80004e92 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d5e:	75f9                	lui	a1,0xffffe
    80004d60:	95aa                	add	a1,a1,a0
    80004d62:	855e                	mv	a0,s7
    80004d64:	ffffd097          	auipc	ra,0xffffd
    80004d68:	93c080e7          	jalr	-1732(ra) # 800016a0 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d6c:	7c7d                	lui	s8,0xfffff
    80004d6e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d70:	e0043783          	ld	a5,-512(s0)
    80004d74:	6388                	ld	a0,0(a5)
    80004d76:	c535                	beqz	a0,80004de2 <exec+0x216>
    80004d78:	e8840993          	addi	s3,s0,-376
    80004d7c:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004d80:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004d82:	ffffc097          	auipc	ra,0xffffc
    80004d86:	112080e7          	jalr	274(ra) # 80000e94 <strlen>
    80004d8a:	2505                	addiw	a0,a0,1
    80004d8c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d90:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d94:	13896363          	bltu	s2,s8,80004eba <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d98:	e0043d83          	ld	s11,-512(s0)
    80004d9c:	000dba03          	ld	s4,0(s11)
    80004da0:	8552                	mv	a0,s4
    80004da2:	ffffc097          	auipc	ra,0xffffc
    80004da6:	0f2080e7          	jalr	242(ra) # 80000e94 <strlen>
    80004daa:	0015069b          	addiw	a3,a0,1
    80004dae:	8652                	mv	a2,s4
    80004db0:	85ca                	mv	a1,s2
    80004db2:	855e                	mv	a0,s7
    80004db4:	ffffd097          	auipc	ra,0xffffd
    80004db8:	91e080e7          	jalr	-1762(ra) # 800016d2 <copyout>
    80004dbc:	10054363          	bltz	a0,80004ec2 <exec+0x2f6>
    ustack[argc] = sp;
    80004dc0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dc4:	0485                	addi	s1,s1,1
    80004dc6:	008d8793          	addi	a5,s11,8
    80004dca:	e0f43023          	sd	a5,-512(s0)
    80004dce:	008db503          	ld	a0,8(s11)
    80004dd2:	c911                	beqz	a0,80004de6 <exec+0x21a>
    if(argc >= MAXARG)
    80004dd4:	09a1                	addi	s3,s3,8
    80004dd6:	fb3c96e3          	bne	s9,s3,80004d82 <exec+0x1b6>
  sz = sz1;
    80004dda:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004dde:	4481                	li	s1,0
    80004de0:	a84d                	j	80004e92 <exec+0x2c6>
  sp = sz;
    80004de2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004de4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004de6:	00349793          	slli	a5,s1,0x3
    80004dea:	f9040713          	addi	a4,s0,-112
    80004dee:	97ba                	add	a5,a5,a4
    80004df0:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004df4:	00148693          	addi	a3,s1,1
    80004df8:	068e                	slli	a3,a3,0x3
    80004dfa:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004dfe:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e02:	01897663          	bgeu	s2,s8,80004e0e <exec+0x242>
  sz = sz1;
    80004e06:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e0a:	4481                	li	s1,0
    80004e0c:	a059                	j	80004e92 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e0e:	e8840613          	addi	a2,s0,-376
    80004e12:	85ca                	mv	a1,s2
    80004e14:	855e                	mv	a0,s7
    80004e16:	ffffd097          	auipc	ra,0xffffd
    80004e1a:	8bc080e7          	jalr	-1860(ra) # 800016d2 <copyout>
    80004e1e:	0a054663          	bltz	a0,80004eca <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004e22:	058ab783          	ld	a5,88(s5)
    80004e26:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e2a:	df843783          	ld	a5,-520(s0)
    80004e2e:	0007c703          	lbu	a4,0(a5)
    80004e32:	cf11                	beqz	a4,80004e4e <exec+0x282>
    80004e34:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e36:	02f00693          	li	a3,47
    80004e3a:	a029                	j	80004e44 <exec+0x278>
  for(last=s=path; *s; s++)
    80004e3c:	0785                	addi	a5,a5,1
    80004e3e:	fff7c703          	lbu	a4,-1(a5)
    80004e42:	c711                	beqz	a4,80004e4e <exec+0x282>
    if(*s == '/')
    80004e44:	fed71ce3          	bne	a4,a3,80004e3c <exec+0x270>
      last = s+1;
    80004e48:	def43c23          	sd	a5,-520(s0)
    80004e4c:	bfc5                	j	80004e3c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e4e:	4641                	li	a2,16
    80004e50:	df843583          	ld	a1,-520(s0)
    80004e54:	158a8513          	addi	a0,s5,344
    80004e58:	ffffc097          	auipc	ra,0xffffc
    80004e5c:	00a080e7          	jalr	10(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e60:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e64:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004e68:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e6c:	058ab783          	ld	a5,88(s5)
    80004e70:	e6043703          	ld	a4,-416(s0)
    80004e74:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e76:	058ab783          	ld	a5,88(s5)
    80004e7a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e7e:	85ea                	mv	a1,s10
    80004e80:	ffffd097          	auipc	ra,0xffffd
    80004e84:	cbe080e7          	jalr	-834(ra) # 80001b3e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e88:	0004851b          	sext.w	a0,s1
    80004e8c:	bbe1                	j	80004c64 <exec+0x98>
    80004e8e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004e92:	e0843583          	ld	a1,-504(s0)
    80004e96:	855e                	mv	a0,s7
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	ca6080e7          	jalr	-858(ra) # 80001b3e <proc_freepagetable>
  if(ip){
    80004ea0:	da0498e3          	bnez	s1,80004c50 <exec+0x84>
  return -1;
    80004ea4:	557d                	li	a0,-1
    80004ea6:	bb7d                	j	80004c64 <exec+0x98>
    80004ea8:	e1243423          	sd	s2,-504(s0)
    80004eac:	b7dd                	j	80004e92 <exec+0x2c6>
    80004eae:	e1243423          	sd	s2,-504(s0)
    80004eb2:	b7c5                	j	80004e92 <exec+0x2c6>
    80004eb4:	e1243423          	sd	s2,-504(s0)
    80004eb8:	bfe9                	j	80004e92 <exec+0x2c6>
  sz = sz1;
    80004eba:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ebe:	4481                	li	s1,0
    80004ec0:	bfc9                	j	80004e92 <exec+0x2c6>
  sz = sz1;
    80004ec2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ec6:	4481                	li	s1,0
    80004ec8:	b7e9                	j	80004e92 <exec+0x2c6>
  sz = sz1;
    80004eca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ece:	4481                	li	s1,0
    80004ed0:	b7c9                	j	80004e92 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ed2:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ed6:	2b05                	addiw	s6,s6,1
    80004ed8:	0389899b          	addiw	s3,s3,56
    80004edc:	e8045783          	lhu	a5,-384(s0)
    80004ee0:	e2fb5be3          	bge	s6,a5,80004d16 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ee4:	2981                	sext.w	s3,s3
    80004ee6:	03800713          	li	a4,56
    80004eea:	86ce                	mv	a3,s3
    80004eec:	e1040613          	addi	a2,s0,-496
    80004ef0:	4581                	li	a1,0
    80004ef2:	8526                	mv	a0,s1
    80004ef4:	fffff097          	auipc	ra,0xfffff
    80004ef8:	a4e080e7          	jalr	-1458(ra) # 80003942 <readi>
    80004efc:	03800793          	li	a5,56
    80004f00:	f8f517e3          	bne	a0,a5,80004e8e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004f04:	e1042783          	lw	a5,-496(s0)
    80004f08:	4705                	li	a4,1
    80004f0a:	fce796e3          	bne	a5,a4,80004ed6 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004f0e:	e3843603          	ld	a2,-456(s0)
    80004f12:	e3043783          	ld	a5,-464(s0)
    80004f16:	f8f669e3          	bltu	a2,a5,80004ea8 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f1a:	e2043783          	ld	a5,-480(s0)
    80004f1e:	963e                	add	a2,a2,a5
    80004f20:	f8f667e3          	bltu	a2,a5,80004eae <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f24:	85ca                	mv	a1,s2
    80004f26:	855e                	mv	a0,s7
    80004f28:	ffffc097          	auipc	ra,0xffffc
    80004f2c:	55a080e7          	jalr	1370(ra) # 80001482 <uvmalloc>
    80004f30:	e0a43423          	sd	a0,-504(s0)
    80004f34:	d141                	beqz	a0,80004eb4 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004f36:	e2043d03          	ld	s10,-480(s0)
    80004f3a:	df043783          	ld	a5,-528(s0)
    80004f3e:	00fd77b3          	and	a5,s10,a5
    80004f42:	fba1                	bnez	a5,80004e92 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f44:	e1842d83          	lw	s11,-488(s0)
    80004f48:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f4c:	f80c03e3          	beqz	s8,80004ed2 <exec+0x306>
    80004f50:	8a62                	mv	s4,s8
    80004f52:	4901                	li	s2,0
    80004f54:	b345                	j	80004cf4 <exec+0x128>

0000000080004f56 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f56:	7179                	addi	sp,sp,-48
    80004f58:	f406                	sd	ra,40(sp)
    80004f5a:	f022                	sd	s0,32(sp)
    80004f5c:	ec26                	sd	s1,24(sp)
    80004f5e:	e84a                	sd	s2,16(sp)
    80004f60:	1800                	addi	s0,sp,48
    80004f62:	892e                	mv	s2,a1
    80004f64:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f66:	fdc40593          	addi	a1,s0,-36
    80004f6a:	ffffe097          	auipc	ra,0xffffe
    80004f6e:	b3a080e7          	jalr	-1222(ra) # 80002aa4 <argint>
    80004f72:	04054063          	bltz	a0,80004fb2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f76:	fdc42703          	lw	a4,-36(s0)
    80004f7a:	47bd                	li	a5,15
    80004f7c:	02e7ed63          	bltu	a5,a4,80004fb6 <argfd+0x60>
    80004f80:	ffffd097          	auipc	ra,0xffffd
    80004f84:	a5e080e7          	jalr	-1442(ra) # 800019de <myproc>
    80004f88:	fdc42703          	lw	a4,-36(s0)
    80004f8c:	01a70793          	addi	a5,a4,26
    80004f90:	078e                	slli	a5,a5,0x3
    80004f92:	953e                	add	a0,a0,a5
    80004f94:	611c                	ld	a5,0(a0)
    80004f96:	c395                	beqz	a5,80004fba <argfd+0x64>
    return -1;
  if(pfd)
    80004f98:	00090463          	beqz	s2,80004fa0 <argfd+0x4a>
    *pfd = fd;
    80004f9c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fa0:	4501                	li	a0,0
  if(pf)
    80004fa2:	c091                	beqz	s1,80004fa6 <argfd+0x50>
    *pf = f;
    80004fa4:	e09c                	sd	a5,0(s1)
}
    80004fa6:	70a2                	ld	ra,40(sp)
    80004fa8:	7402                	ld	s0,32(sp)
    80004faa:	64e2                	ld	s1,24(sp)
    80004fac:	6942                	ld	s2,16(sp)
    80004fae:	6145                	addi	sp,sp,48
    80004fb0:	8082                	ret
    return -1;
    80004fb2:	557d                	li	a0,-1
    80004fb4:	bfcd                	j	80004fa6 <argfd+0x50>
    return -1;
    80004fb6:	557d                	li	a0,-1
    80004fb8:	b7fd                	j	80004fa6 <argfd+0x50>
    80004fba:	557d                	li	a0,-1
    80004fbc:	b7ed                	j	80004fa6 <argfd+0x50>

0000000080004fbe <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fbe:	1101                	addi	sp,sp,-32
    80004fc0:	ec06                	sd	ra,24(sp)
    80004fc2:	e822                	sd	s0,16(sp)
    80004fc4:	e426                	sd	s1,8(sp)
    80004fc6:	1000                	addi	s0,sp,32
    80004fc8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fca:	ffffd097          	auipc	ra,0xffffd
    80004fce:	a14080e7          	jalr	-1516(ra) # 800019de <myproc>
    80004fd2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004fd4:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004fd8:	4501                	li	a0,0
    80004fda:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004fdc:	6398                	ld	a4,0(a5)
    80004fde:	cb19                	beqz	a4,80004ff4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004fe0:	2505                	addiw	a0,a0,1
    80004fe2:	07a1                	addi	a5,a5,8
    80004fe4:	fed51ce3          	bne	a0,a3,80004fdc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004fe8:	557d                	li	a0,-1
}
    80004fea:	60e2                	ld	ra,24(sp)
    80004fec:	6442                	ld	s0,16(sp)
    80004fee:	64a2                	ld	s1,8(sp)
    80004ff0:	6105                	addi	sp,sp,32
    80004ff2:	8082                	ret
      p->ofile[fd] = f;
    80004ff4:	01a50793          	addi	a5,a0,26
    80004ff8:	078e                	slli	a5,a5,0x3
    80004ffa:	963e                	add	a2,a2,a5
    80004ffc:	e204                	sd	s1,0(a2)
      return fd;
    80004ffe:	b7f5                	j	80004fea <fdalloc+0x2c>

0000000080005000 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005000:	715d                	addi	sp,sp,-80
    80005002:	e486                	sd	ra,72(sp)
    80005004:	e0a2                	sd	s0,64(sp)
    80005006:	fc26                	sd	s1,56(sp)
    80005008:	f84a                	sd	s2,48(sp)
    8000500a:	f44e                	sd	s3,40(sp)
    8000500c:	f052                	sd	s4,32(sp)
    8000500e:	ec56                	sd	s5,24(sp)
    80005010:	0880                	addi	s0,sp,80
    80005012:	89ae                	mv	s3,a1
    80005014:	8ab2                	mv	s5,a2
    80005016:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005018:	fb040593          	addi	a1,s0,-80
    8000501c:	fffff097          	auipc	ra,0xfffff
    80005020:	e40080e7          	jalr	-448(ra) # 80003e5c <nameiparent>
    80005024:	892a                	mv	s2,a0
    80005026:	12050f63          	beqz	a0,80005164 <create+0x164>
    return 0;

  ilock(dp);
    8000502a:	ffffe097          	auipc	ra,0xffffe
    8000502e:	664080e7          	jalr	1636(ra) # 8000368e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005032:	4601                	li	a2,0
    80005034:	fb040593          	addi	a1,s0,-80
    80005038:	854a                	mv	a0,s2
    8000503a:	fffff097          	auipc	ra,0xfffff
    8000503e:	b32080e7          	jalr	-1230(ra) # 80003b6c <dirlookup>
    80005042:	84aa                	mv	s1,a0
    80005044:	c921                	beqz	a0,80005094 <create+0x94>
    iunlockput(dp);
    80005046:	854a                	mv	a0,s2
    80005048:	fffff097          	auipc	ra,0xfffff
    8000504c:	8a8080e7          	jalr	-1880(ra) # 800038f0 <iunlockput>
    ilock(ip);
    80005050:	8526                	mv	a0,s1
    80005052:	ffffe097          	auipc	ra,0xffffe
    80005056:	63c080e7          	jalr	1596(ra) # 8000368e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000505a:	2981                	sext.w	s3,s3
    8000505c:	4789                	li	a5,2
    8000505e:	02f99463          	bne	s3,a5,80005086 <create+0x86>
    80005062:	0444d783          	lhu	a5,68(s1)
    80005066:	37f9                	addiw	a5,a5,-2
    80005068:	17c2                	slli	a5,a5,0x30
    8000506a:	93c1                	srli	a5,a5,0x30
    8000506c:	4705                	li	a4,1
    8000506e:	00f76c63          	bltu	a4,a5,80005086 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005072:	8526                	mv	a0,s1
    80005074:	60a6                	ld	ra,72(sp)
    80005076:	6406                	ld	s0,64(sp)
    80005078:	74e2                	ld	s1,56(sp)
    8000507a:	7942                	ld	s2,48(sp)
    8000507c:	79a2                	ld	s3,40(sp)
    8000507e:	7a02                	ld	s4,32(sp)
    80005080:	6ae2                	ld	s5,24(sp)
    80005082:	6161                	addi	sp,sp,80
    80005084:	8082                	ret
    iunlockput(ip);
    80005086:	8526                	mv	a0,s1
    80005088:	fffff097          	auipc	ra,0xfffff
    8000508c:	868080e7          	jalr	-1944(ra) # 800038f0 <iunlockput>
    return 0;
    80005090:	4481                	li	s1,0
    80005092:	b7c5                	j	80005072 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005094:	85ce                	mv	a1,s3
    80005096:	00092503          	lw	a0,0(s2)
    8000509a:	ffffe097          	auipc	ra,0xffffe
    8000509e:	45c080e7          	jalr	1116(ra) # 800034f6 <ialloc>
    800050a2:	84aa                	mv	s1,a0
    800050a4:	c529                	beqz	a0,800050ee <create+0xee>
  ilock(ip);
    800050a6:	ffffe097          	auipc	ra,0xffffe
    800050aa:	5e8080e7          	jalr	1512(ra) # 8000368e <ilock>
  ip->major = major;
    800050ae:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050b2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050b6:	4785                	li	a5,1
    800050b8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800050bc:	8526                	mv	a0,s1
    800050be:	ffffe097          	auipc	ra,0xffffe
    800050c2:	506080e7          	jalr	1286(ra) # 800035c4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050c6:	2981                	sext.w	s3,s3
    800050c8:	4785                	li	a5,1
    800050ca:	02f98a63          	beq	s3,a5,800050fe <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800050ce:	40d0                	lw	a2,4(s1)
    800050d0:	fb040593          	addi	a1,s0,-80
    800050d4:	854a                	mv	a0,s2
    800050d6:	fffff097          	auipc	ra,0xfffff
    800050da:	ca6080e7          	jalr	-858(ra) # 80003d7c <dirlink>
    800050de:	06054b63          	bltz	a0,80005154 <create+0x154>
  iunlockput(dp);
    800050e2:	854a                	mv	a0,s2
    800050e4:	fffff097          	auipc	ra,0xfffff
    800050e8:	80c080e7          	jalr	-2036(ra) # 800038f0 <iunlockput>
  return ip;
    800050ec:	b759                	j	80005072 <create+0x72>
    panic("create: ialloc");
    800050ee:	00003517          	auipc	a0,0x3
    800050f2:	76250513          	addi	a0,a0,1890 # 80008850 <sysnames+0x2b0>
    800050f6:	ffffb097          	auipc	ra,0xffffb
    800050fa:	452080e7          	jalr	1106(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800050fe:	04a95783          	lhu	a5,74(s2)
    80005102:	2785                	addiw	a5,a5,1
    80005104:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005108:	854a                	mv	a0,s2
    8000510a:	ffffe097          	auipc	ra,0xffffe
    8000510e:	4ba080e7          	jalr	1210(ra) # 800035c4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005112:	40d0                	lw	a2,4(s1)
    80005114:	00003597          	auipc	a1,0x3
    80005118:	74c58593          	addi	a1,a1,1868 # 80008860 <sysnames+0x2c0>
    8000511c:	8526                	mv	a0,s1
    8000511e:	fffff097          	auipc	ra,0xfffff
    80005122:	c5e080e7          	jalr	-930(ra) # 80003d7c <dirlink>
    80005126:	00054f63          	bltz	a0,80005144 <create+0x144>
    8000512a:	00492603          	lw	a2,4(s2)
    8000512e:	00003597          	auipc	a1,0x3
    80005132:	73a58593          	addi	a1,a1,1850 # 80008868 <sysnames+0x2c8>
    80005136:	8526                	mv	a0,s1
    80005138:	fffff097          	auipc	ra,0xfffff
    8000513c:	c44080e7          	jalr	-956(ra) # 80003d7c <dirlink>
    80005140:	f80557e3          	bgez	a0,800050ce <create+0xce>
      panic("create dots");
    80005144:	00003517          	auipc	a0,0x3
    80005148:	72c50513          	addi	a0,a0,1836 # 80008870 <sysnames+0x2d0>
    8000514c:	ffffb097          	auipc	ra,0xffffb
    80005150:	3fc080e7          	jalr	1020(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005154:	00003517          	auipc	a0,0x3
    80005158:	72c50513          	addi	a0,a0,1836 # 80008880 <sysnames+0x2e0>
    8000515c:	ffffb097          	auipc	ra,0xffffb
    80005160:	3ec080e7          	jalr	1004(ra) # 80000548 <panic>
    return 0;
    80005164:	84aa                	mv	s1,a0
    80005166:	b731                	j	80005072 <create+0x72>

0000000080005168 <sys_dup>:
{
    80005168:	7179                	addi	sp,sp,-48
    8000516a:	f406                	sd	ra,40(sp)
    8000516c:	f022                	sd	s0,32(sp)
    8000516e:	ec26                	sd	s1,24(sp)
    80005170:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005172:	fd840613          	addi	a2,s0,-40
    80005176:	4581                	li	a1,0
    80005178:	4501                	li	a0,0
    8000517a:	00000097          	auipc	ra,0x0
    8000517e:	ddc080e7          	jalr	-548(ra) # 80004f56 <argfd>
    return -1;
    80005182:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005184:	02054363          	bltz	a0,800051aa <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005188:	fd843503          	ld	a0,-40(s0)
    8000518c:	00000097          	auipc	ra,0x0
    80005190:	e32080e7          	jalr	-462(ra) # 80004fbe <fdalloc>
    80005194:	84aa                	mv	s1,a0
    return -1;
    80005196:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005198:	00054963          	bltz	a0,800051aa <sys_dup+0x42>
  filedup(f);
    8000519c:	fd843503          	ld	a0,-40(s0)
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	32a080e7          	jalr	810(ra) # 800044ca <filedup>
  return fd;
    800051a8:	87a6                	mv	a5,s1
}
    800051aa:	853e                	mv	a0,a5
    800051ac:	70a2                	ld	ra,40(sp)
    800051ae:	7402                	ld	s0,32(sp)
    800051b0:	64e2                	ld	s1,24(sp)
    800051b2:	6145                	addi	sp,sp,48
    800051b4:	8082                	ret

00000000800051b6 <sys_read>:
{
    800051b6:	7179                	addi	sp,sp,-48
    800051b8:	f406                	sd	ra,40(sp)
    800051ba:	f022                	sd	s0,32(sp)
    800051bc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051be:	fe840613          	addi	a2,s0,-24
    800051c2:	4581                	li	a1,0
    800051c4:	4501                	li	a0,0
    800051c6:	00000097          	auipc	ra,0x0
    800051ca:	d90080e7          	jalr	-624(ra) # 80004f56 <argfd>
    return -1;
    800051ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051d0:	04054163          	bltz	a0,80005212 <sys_read+0x5c>
    800051d4:	fe440593          	addi	a1,s0,-28
    800051d8:	4509                	li	a0,2
    800051da:	ffffe097          	auipc	ra,0xffffe
    800051de:	8ca080e7          	jalr	-1846(ra) # 80002aa4 <argint>
    return -1;
    800051e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051e4:	02054763          	bltz	a0,80005212 <sys_read+0x5c>
    800051e8:	fd840593          	addi	a1,s0,-40
    800051ec:	4505                	li	a0,1
    800051ee:	ffffe097          	auipc	ra,0xffffe
    800051f2:	8d8080e7          	jalr	-1832(ra) # 80002ac6 <argaddr>
    return -1;
    800051f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051f8:	00054d63          	bltz	a0,80005212 <sys_read+0x5c>
  return fileread(f, p, n);
    800051fc:	fe442603          	lw	a2,-28(s0)
    80005200:	fd843583          	ld	a1,-40(s0)
    80005204:	fe843503          	ld	a0,-24(s0)
    80005208:	fffff097          	auipc	ra,0xfffff
    8000520c:	44e080e7          	jalr	1102(ra) # 80004656 <fileread>
    80005210:	87aa                	mv	a5,a0
}
    80005212:	853e                	mv	a0,a5
    80005214:	70a2                	ld	ra,40(sp)
    80005216:	7402                	ld	s0,32(sp)
    80005218:	6145                	addi	sp,sp,48
    8000521a:	8082                	ret

000000008000521c <sys_write>:
{
    8000521c:	7179                	addi	sp,sp,-48
    8000521e:	f406                	sd	ra,40(sp)
    80005220:	f022                	sd	s0,32(sp)
    80005222:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005224:	fe840613          	addi	a2,s0,-24
    80005228:	4581                	li	a1,0
    8000522a:	4501                	li	a0,0
    8000522c:	00000097          	auipc	ra,0x0
    80005230:	d2a080e7          	jalr	-726(ra) # 80004f56 <argfd>
    return -1;
    80005234:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005236:	04054163          	bltz	a0,80005278 <sys_write+0x5c>
    8000523a:	fe440593          	addi	a1,s0,-28
    8000523e:	4509                	li	a0,2
    80005240:	ffffe097          	auipc	ra,0xffffe
    80005244:	864080e7          	jalr	-1948(ra) # 80002aa4 <argint>
    return -1;
    80005248:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000524a:	02054763          	bltz	a0,80005278 <sys_write+0x5c>
    8000524e:	fd840593          	addi	a1,s0,-40
    80005252:	4505                	li	a0,1
    80005254:	ffffe097          	auipc	ra,0xffffe
    80005258:	872080e7          	jalr	-1934(ra) # 80002ac6 <argaddr>
    return -1;
    8000525c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000525e:	00054d63          	bltz	a0,80005278 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005262:	fe442603          	lw	a2,-28(s0)
    80005266:	fd843583          	ld	a1,-40(s0)
    8000526a:	fe843503          	ld	a0,-24(s0)
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	4aa080e7          	jalr	1194(ra) # 80004718 <filewrite>
    80005276:	87aa                	mv	a5,a0
}
    80005278:	853e                	mv	a0,a5
    8000527a:	70a2                	ld	ra,40(sp)
    8000527c:	7402                	ld	s0,32(sp)
    8000527e:	6145                	addi	sp,sp,48
    80005280:	8082                	ret

0000000080005282 <sys_close>:
{
    80005282:	1101                	addi	sp,sp,-32
    80005284:	ec06                	sd	ra,24(sp)
    80005286:	e822                	sd	s0,16(sp)
    80005288:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000528a:	fe040613          	addi	a2,s0,-32
    8000528e:	fec40593          	addi	a1,s0,-20
    80005292:	4501                	li	a0,0
    80005294:	00000097          	auipc	ra,0x0
    80005298:	cc2080e7          	jalr	-830(ra) # 80004f56 <argfd>
    return -1;
    8000529c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000529e:	02054463          	bltz	a0,800052c6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052a2:	ffffc097          	auipc	ra,0xffffc
    800052a6:	73c080e7          	jalr	1852(ra) # 800019de <myproc>
    800052aa:	fec42783          	lw	a5,-20(s0)
    800052ae:	07e9                	addi	a5,a5,26
    800052b0:	078e                	slli	a5,a5,0x3
    800052b2:	97aa                	add	a5,a5,a0
    800052b4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052b8:	fe043503          	ld	a0,-32(s0)
    800052bc:	fffff097          	auipc	ra,0xfffff
    800052c0:	260080e7          	jalr	608(ra) # 8000451c <fileclose>
  return 0;
    800052c4:	4781                	li	a5,0
}
    800052c6:	853e                	mv	a0,a5
    800052c8:	60e2                	ld	ra,24(sp)
    800052ca:	6442                	ld	s0,16(sp)
    800052cc:	6105                	addi	sp,sp,32
    800052ce:	8082                	ret

00000000800052d0 <sys_fstat>:
{
    800052d0:	1101                	addi	sp,sp,-32
    800052d2:	ec06                	sd	ra,24(sp)
    800052d4:	e822                	sd	s0,16(sp)
    800052d6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052d8:	fe840613          	addi	a2,s0,-24
    800052dc:	4581                	li	a1,0
    800052de:	4501                	li	a0,0
    800052e0:	00000097          	auipc	ra,0x0
    800052e4:	c76080e7          	jalr	-906(ra) # 80004f56 <argfd>
    return -1;
    800052e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052ea:	02054563          	bltz	a0,80005314 <sys_fstat+0x44>
    800052ee:	fe040593          	addi	a1,s0,-32
    800052f2:	4505                	li	a0,1
    800052f4:	ffffd097          	auipc	ra,0xffffd
    800052f8:	7d2080e7          	jalr	2002(ra) # 80002ac6 <argaddr>
    return -1;
    800052fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052fe:	00054b63          	bltz	a0,80005314 <sys_fstat+0x44>
  return filestat(f, st);
    80005302:	fe043583          	ld	a1,-32(s0)
    80005306:	fe843503          	ld	a0,-24(s0)
    8000530a:	fffff097          	auipc	ra,0xfffff
    8000530e:	2da080e7          	jalr	730(ra) # 800045e4 <filestat>
    80005312:	87aa                	mv	a5,a0
}
    80005314:	853e                	mv	a0,a5
    80005316:	60e2                	ld	ra,24(sp)
    80005318:	6442                	ld	s0,16(sp)
    8000531a:	6105                	addi	sp,sp,32
    8000531c:	8082                	ret

000000008000531e <sys_link>:
{
    8000531e:	7169                	addi	sp,sp,-304
    80005320:	f606                	sd	ra,296(sp)
    80005322:	f222                	sd	s0,288(sp)
    80005324:	ee26                	sd	s1,280(sp)
    80005326:	ea4a                	sd	s2,272(sp)
    80005328:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000532a:	08000613          	li	a2,128
    8000532e:	ed040593          	addi	a1,s0,-304
    80005332:	4501                	li	a0,0
    80005334:	ffffd097          	auipc	ra,0xffffd
    80005338:	7b4080e7          	jalr	1972(ra) # 80002ae8 <argstr>
    return -1;
    8000533c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000533e:	10054e63          	bltz	a0,8000545a <sys_link+0x13c>
    80005342:	08000613          	li	a2,128
    80005346:	f5040593          	addi	a1,s0,-176
    8000534a:	4505                	li	a0,1
    8000534c:	ffffd097          	auipc	ra,0xffffd
    80005350:	79c080e7          	jalr	1948(ra) # 80002ae8 <argstr>
    return -1;
    80005354:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005356:	10054263          	bltz	a0,8000545a <sys_link+0x13c>
  begin_op();
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	cf0080e7          	jalr	-784(ra) # 8000404a <begin_op>
  if((ip = namei(old)) == 0){
    80005362:	ed040513          	addi	a0,s0,-304
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	ad8080e7          	jalr	-1320(ra) # 80003e3e <namei>
    8000536e:	84aa                	mv	s1,a0
    80005370:	c551                	beqz	a0,800053fc <sys_link+0xde>
  ilock(ip);
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	31c080e7          	jalr	796(ra) # 8000368e <ilock>
  if(ip->type == T_DIR){
    8000537a:	04449703          	lh	a4,68(s1)
    8000537e:	4785                	li	a5,1
    80005380:	08f70463          	beq	a4,a5,80005408 <sys_link+0xea>
  ip->nlink++;
    80005384:	04a4d783          	lhu	a5,74(s1)
    80005388:	2785                	addiw	a5,a5,1
    8000538a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000538e:	8526                	mv	a0,s1
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	234080e7          	jalr	564(ra) # 800035c4 <iupdate>
  iunlock(ip);
    80005398:	8526                	mv	a0,s1
    8000539a:	ffffe097          	auipc	ra,0xffffe
    8000539e:	3b6080e7          	jalr	950(ra) # 80003750 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053a2:	fd040593          	addi	a1,s0,-48
    800053a6:	f5040513          	addi	a0,s0,-176
    800053aa:	fffff097          	auipc	ra,0xfffff
    800053ae:	ab2080e7          	jalr	-1358(ra) # 80003e5c <nameiparent>
    800053b2:	892a                	mv	s2,a0
    800053b4:	c935                	beqz	a0,80005428 <sys_link+0x10a>
  ilock(dp);
    800053b6:	ffffe097          	auipc	ra,0xffffe
    800053ba:	2d8080e7          	jalr	728(ra) # 8000368e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053be:	00092703          	lw	a4,0(s2)
    800053c2:	409c                	lw	a5,0(s1)
    800053c4:	04f71d63          	bne	a4,a5,8000541e <sys_link+0x100>
    800053c8:	40d0                	lw	a2,4(s1)
    800053ca:	fd040593          	addi	a1,s0,-48
    800053ce:	854a                	mv	a0,s2
    800053d0:	fffff097          	auipc	ra,0xfffff
    800053d4:	9ac080e7          	jalr	-1620(ra) # 80003d7c <dirlink>
    800053d8:	04054363          	bltz	a0,8000541e <sys_link+0x100>
  iunlockput(dp);
    800053dc:	854a                	mv	a0,s2
    800053de:	ffffe097          	auipc	ra,0xffffe
    800053e2:	512080e7          	jalr	1298(ra) # 800038f0 <iunlockput>
  iput(ip);
    800053e6:	8526                	mv	a0,s1
    800053e8:	ffffe097          	auipc	ra,0xffffe
    800053ec:	460080e7          	jalr	1120(ra) # 80003848 <iput>
  end_op();
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	cda080e7          	jalr	-806(ra) # 800040ca <end_op>
  return 0;
    800053f8:	4781                	li	a5,0
    800053fa:	a085                	j	8000545a <sys_link+0x13c>
    end_op();
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	cce080e7          	jalr	-818(ra) # 800040ca <end_op>
    return -1;
    80005404:	57fd                	li	a5,-1
    80005406:	a891                	j	8000545a <sys_link+0x13c>
    iunlockput(ip);
    80005408:	8526                	mv	a0,s1
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	4e6080e7          	jalr	1254(ra) # 800038f0 <iunlockput>
    end_op();
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	cb8080e7          	jalr	-840(ra) # 800040ca <end_op>
    return -1;
    8000541a:	57fd                	li	a5,-1
    8000541c:	a83d                	j	8000545a <sys_link+0x13c>
    iunlockput(dp);
    8000541e:	854a                	mv	a0,s2
    80005420:	ffffe097          	auipc	ra,0xffffe
    80005424:	4d0080e7          	jalr	1232(ra) # 800038f0 <iunlockput>
  ilock(ip);
    80005428:	8526                	mv	a0,s1
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	264080e7          	jalr	612(ra) # 8000368e <ilock>
  ip->nlink--;
    80005432:	04a4d783          	lhu	a5,74(s1)
    80005436:	37fd                	addiw	a5,a5,-1
    80005438:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000543c:	8526                	mv	a0,s1
    8000543e:	ffffe097          	auipc	ra,0xffffe
    80005442:	186080e7          	jalr	390(ra) # 800035c4 <iupdate>
  iunlockput(ip);
    80005446:	8526                	mv	a0,s1
    80005448:	ffffe097          	auipc	ra,0xffffe
    8000544c:	4a8080e7          	jalr	1192(ra) # 800038f0 <iunlockput>
  end_op();
    80005450:	fffff097          	auipc	ra,0xfffff
    80005454:	c7a080e7          	jalr	-902(ra) # 800040ca <end_op>
  return -1;
    80005458:	57fd                	li	a5,-1
}
    8000545a:	853e                	mv	a0,a5
    8000545c:	70b2                	ld	ra,296(sp)
    8000545e:	7412                	ld	s0,288(sp)
    80005460:	64f2                	ld	s1,280(sp)
    80005462:	6952                	ld	s2,272(sp)
    80005464:	6155                	addi	sp,sp,304
    80005466:	8082                	ret

0000000080005468 <sys_unlink>:
{
    80005468:	7151                	addi	sp,sp,-240
    8000546a:	f586                	sd	ra,232(sp)
    8000546c:	f1a2                	sd	s0,224(sp)
    8000546e:	eda6                	sd	s1,216(sp)
    80005470:	e9ca                	sd	s2,208(sp)
    80005472:	e5ce                	sd	s3,200(sp)
    80005474:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005476:	08000613          	li	a2,128
    8000547a:	f3040593          	addi	a1,s0,-208
    8000547e:	4501                	li	a0,0
    80005480:	ffffd097          	auipc	ra,0xffffd
    80005484:	668080e7          	jalr	1640(ra) # 80002ae8 <argstr>
    80005488:	18054163          	bltz	a0,8000560a <sys_unlink+0x1a2>
  begin_op();
    8000548c:	fffff097          	auipc	ra,0xfffff
    80005490:	bbe080e7          	jalr	-1090(ra) # 8000404a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005494:	fb040593          	addi	a1,s0,-80
    80005498:	f3040513          	addi	a0,s0,-208
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	9c0080e7          	jalr	-1600(ra) # 80003e5c <nameiparent>
    800054a4:	84aa                	mv	s1,a0
    800054a6:	c979                	beqz	a0,8000557c <sys_unlink+0x114>
  ilock(dp);
    800054a8:	ffffe097          	auipc	ra,0xffffe
    800054ac:	1e6080e7          	jalr	486(ra) # 8000368e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054b0:	00003597          	auipc	a1,0x3
    800054b4:	3b058593          	addi	a1,a1,944 # 80008860 <sysnames+0x2c0>
    800054b8:	fb040513          	addi	a0,s0,-80
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	696080e7          	jalr	1686(ra) # 80003b52 <namecmp>
    800054c4:	14050a63          	beqz	a0,80005618 <sys_unlink+0x1b0>
    800054c8:	00003597          	auipc	a1,0x3
    800054cc:	3a058593          	addi	a1,a1,928 # 80008868 <sysnames+0x2c8>
    800054d0:	fb040513          	addi	a0,s0,-80
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	67e080e7          	jalr	1662(ra) # 80003b52 <namecmp>
    800054dc:	12050e63          	beqz	a0,80005618 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054e0:	f2c40613          	addi	a2,s0,-212
    800054e4:	fb040593          	addi	a1,s0,-80
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	682080e7          	jalr	1666(ra) # 80003b6c <dirlookup>
    800054f2:	892a                	mv	s2,a0
    800054f4:	12050263          	beqz	a0,80005618 <sys_unlink+0x1b0>
  ilock(ip);
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	196080e7          	jalr	406(ra) # 8000368e <ilock>
  if(ip->nlink < 1)
    80005500:	04a91783          	lh	a5,74(s2)
    80005504:	08f05263          	blez	a5,80005588 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005508:	04491703          	lh	a4,68(s2)
    8000550c:	4785                	li	a5,1
    8000550e:	08f70563          	beq	a4,a5,80005598 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005512:	4641                	li	a2,16
    80005514:	4581                	li	a1,0
    80005516:	fc040513          	addi	a0,s0,-64
    8000551a:	ffffb097          	auipc	ra,0xffffb
    8000551e:	7f2080e7          	jalr	2034(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005522:	4741                	li	a4,16
    80005524:	f2c42683          	lw	a3,-212(s0)
    80005528:	fc040613          	addi	a2,s0,-64
    8000552c:	4581                	li	a1,0
    8000552e:	8526                	mv	a0,s1
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	508080e7          	jalr	1288(ra) # 80003a38 <writei>
    80005538:	47c1                	li	a5,16
    8000553a:	0af51563          	bne	a0,a5,800055e4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000553e:	04491703          	lh	a4,68(s2)
    80005542:	4785                	li	a5,1
    80005544:	0af70863          	beq	a4,a5,800055f4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005548:	8526                	mv	a0,s1
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	3a6080e7          	jalr	934(ra) # 800038f0 <iunlockput>
  ip->nlink--;
    80005552:	04a95783          	lhu	a5,74(s2)
    80005556:	37fd                	addiw	a5,a5,-1
    80005558:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000555c:	854a                	mv	a0,s2
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	066080e7          	jalr	102(ra) # 800035c4 <iupdate>
  iunlockput(ip);
    80005566:	854a                	mv	a0,s2
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	388080e7          	jalr	904(ra) # 800038f0 <iunlockput>
  end_op();
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	b5a080e7          	jalr	-1190(ra) # 800040ca <end_op>
  return 0;
    80005578:	4501                	li	a0,0
    8000557a:	a84d                	j	8000562c <sys_unlink+0x1c4>
    end_op();
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	b4e080e7          	jalr	-1202(ra) # 800040ca <end_op>
    return -1;
    80005584:	557d                	li	a0,-1
    80005586:	a05d                	j	8000562c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005588:	00003517          	auipc	a0,0x3
    8000558c:	30850513          	addi	a0,a0,776 # 80008890 <sysnames+0x2f0>
    80005590:	ffffb097          	auipc	ra,0xffffb
    80005594:	fb8080e7          	jalr	-72(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005598:	04c92703          	lw	a4,76(s2)
    8000559c:	02000793          	li	a5,32
    800055a0:	f6e7f9e3          	bgeu	a5,a4,80005512 <sys_unlink+0xaa>
    800055a4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055a8:	4741                	li	a4,16
    800055aa:	86ce                	mv	a3,s3
    800055ac:	f1840613          	addi	a2,s0,-232
    800055b0:	4581                	li	a1,0
    800055b2:	854a                	mv	a0,s2
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	38e080e7          	jalr	910(ra) # 80003942 <readi>
    800055bc:	47c1                	li	a5,16
    800055be:	00f51b63          	bne	a0,a5,800055d4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055c2:	f1845783          	lhu	a5,-232(s0)
    800055c6:	e7a1                	bnez	a5,8000560e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055c8:	29c1                	addiw	s3,s3,16
    800055ca:	04c92783          	lw	a5,76(s2)
    800055ce:	fcf9ede3          	bltu	s3,a5,800055a8 <sys_unlink+0x140>
    800055d2:	b781                	j	80005512 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055d4:	00003517          	auipc	a0,0x3
    800055d8:	2d450513          	addi	a0,a0,724 # 800088a8 <sysnames+0x308>
    800055dc:	ffffb097          	auipc	ra,0xffffb
    800055e0:	f6c080e7          	jalr	-148(ra) # 80000548 <panic>
    panic("unlink: writei");
    800055e4:	00003517          	auipc	a0,0x3
    800055e8:	2dc50513          	addi	a0,a0,732 # 800088c0 <sysnames+0x320>
    800055ec:	ffffb097          	auipc	ra,0xffffb
    800055f0:	f5c080e7          	jalr	-164(ra) # 80000548 <panic>
    dp->nlink--;
    800055f4:	04a4d783          	lhu	a5,74(s1)
    800055f8:	37fd                	addiw	a5,a5,-1
    800055fa:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055fe:	8526                	mv	a0,s1
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	fc4080e7          	jalr	-60(ra) # 800035c4 <iupdate>
    80005608:	b781                	j	80005548 <sys_unlink+0xe0>
    return -1;
    8000560a:	557d                	li	a0,-1
    8000560c:	a005                	j	8000562c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000560e:	854a                	mv	a0,s2
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	2e0080e7          	jalr	736(ra) # 800038f0 <iunlockput>
  iunlockput(dp);
    80005618:	8526                	mv	a0,s1
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	2d6080e7          	jalr	726(ra) # 800038f0 <iunlockput>
  end_op();
    80005622:	fffff097          	auipc	ra,0xfffff
    80005626:	aa8080e7          	jalr	-1368(ra) # 800040ca <end_op>
  return -1;
    8000562a:	557d                	li	a0,-1
}
    8000562c:	70ae                	ld	ra,232(sp)
    8000562e:	740e                	ld	s0,224(sp)
    80005630:	64ee                	ld	s1,216(sp)
    80005632:	694e                	ld	s2,208(sp)
    80005634:	69ae                	ld	s3,200(sp)
    80005636:	616d                	addi	sp,sp,240
    80005638:	8082                	ret

000000008000563a <sys_open>:

uint64
sys_open(void)
{
    8000563a:	7131                	addi	sp,sp,-192
    8000563c:	fd06                	sd	ra,184(sp)
    8000563e:	f922                	sd	s0,176(sp)
    80005640:	f526                	sd	s1,168(sp)
    80005642:	f14a                	sd	s2,160(sp)
    80005644:	ed4e                	sd	s3,152(sp)
    80005646:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005648:	08000613          	li	a2,128
    8000564c:	f5040593          	addi	a1,s0,-176
    80005650:	4501                	li	a0,0
    80005652:	ffffd097          	auipc	ra,0xffffd
    80005656:	496080e7          	jalr	1174(ra) # 80002ae8 <argstr>
    return -1;
    8000565a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000565c:	0c054163          	bltz	a0,8000571e <sys_open+0xe4>
    80005660:	f4c40593          	addi	a1,s0,-180
    80005664:	4505                	li	a0,1
    80005666:	ffffd097          	auipc	ra,0xffffd
    8000566a:	43e080e7          	jalr	1086(ra) # 80002aa4 <argint>
    8000566e:	0a054863          	bltz	a0,8000571e <sys_open+0xe4>

  begin_op();
    80005672:	fffff097          	auipc	ra,0xfffff
    80005676:	9d8080e7          	jalr	-1576(ra) # 8000404a <begin_op>

  if(omode & O_CREATE){
    8000567a:	f4c42783          	lw	a5,-180(s0)
    8000567e:	2007f793          	andi	a5,a5,512
    80005682:	cbdd                	beqz	a5,80005738 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005684:	4681                	li	a3,0
    80005686:	4601                	li	a2,0
    80005688:	4589                	li	a1,2
    8000568a:	f5040513          	addi	a0,s0,-176
    8000568e:	00000097          	auipc	ra,0x0
    80005692:	972080e7          	jalr	-1678(ra) # 80005000 <create>
    80005696:	892a                	mv	s2,a0
    if(ip == 0){
    80005698:	c959                	beqz	a0,8000572e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000569a:	04491703          	lh	a4,68(s2)
    8000569e:	478d                	li	a5,3
    800056a0:	00f71763          	bne	a4,a5,800056ae <sys_open+0x74>
    800056a4:	04695703          	lhu	a4,70(s2)
    800056a8:	47a5                	li	a5,9
    800056aa:	0ce7ec63          	bltu	a5,a4,80005782 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056ae:	fffff097          	auipc	ra,0xfffff
    800056b2:	db2080e7          	jalr	-590(ra) # 80004460 <filealloc>
    800056b6:	89aa                	mv	s3,a0
    800056b8:	10050263          	beqz	a0,800057bc <sys_open+0x182>
    800056bc:	00000097          	auipc	ra,0x0
    800056c0:	902080e7          	jalr	-1790(ra) # 80004fbe <fdalloc>
    800056c4:	84aa                	mv	s1,a0
    800056c6:	0e054663          	bltz	a0,800057b2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056ca:	04491703          	lh	a4,68(s2)
    800056ce:	478d                	li	a5,3
    800056d0:	0cf70463          	beq	a4,a5,80005798 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056d4:	4789                	li	a5,2
    800056d6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056da:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056de:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056e2:	f4c42783          	lw	a5,-180(s0)
    800056e6:	0017c713          	xori	a4,a5,1
    800056ea:	8b05                	andi	a4,a4,1
    800056ec:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056f0:	0037f713          	andi	a4,a5,3
    800056f4:	00e03733          	snez	a4,a4
    800056f8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800056fc:	4007f793          	andi	a5,a5,1024
    80005700:	c791                	beqz	a5,8000570c <sys_open+0xd2>
    80005702:	04491703          	lh	a4,68(s2)
    80005706:	4789                	li	a5,2
    80005708:	08f70f63          	beq	a4,a5,800057a6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000570c:	854a                	mv	a0,s2
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	042080e7          	jalr	66(ra) # 80003750 <iunlock>
  end_op();
    80005716:	fffff097          	auipc	ra,0xfffff
    8000571a:	9b4080e7          	jalr	-1612(ra) # 800040ca <end_op>

  return fd;
}
    8000571e:	8526                	mv	a0,s1
    80005720:	70ea                	ld	ra,184(sp)
    80005722:	744a                	ld	s0,176(sp)
    80005724:	74aa                	ld	s1,168(sp)
    80005726:	790a                	ld	s2,160(sp)
    80005728:	69ea                	ld	s3,152(sp)
    8000572a:	6129                	addi	sp,sp,192
    8000572c:	8082                	ret
      end_op();
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	99c080e7          	jalr	-1636(ra) # 800040ca <end_op>
      return -1;
    80005736:	b7e5                	j	8000571e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005738:	f5040513          	addi	a0,s0,-176
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	702080e7          	jalr	1794(ra) # 80003e3e <namei>
    80005744:	892a                	mv	s2,a0
    80005746:	c905                	beqz	a0,80005776 <sys_open+0x13c>
    ilock(ip);
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	f46080e7          	jalr	-186(ra) # 8000368e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005750:	04491703          	lh	a4,68(s2)
    80005754:	4785                	li	a5,1
    80005756:	f4f712e3          	bne	a4,a5,8000569a <sys_open+0x60>
    8000575a:	f4c42783          	lw	a5,-180(s0)
    8000575e:	dba1                	beqz	a5,800056ae <sys_open+0x74>
      iunlockput(ip);
    80005760:	854a                	mv	a0,s2
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	18e080e7          	jalr	398(ra) # 800038f0 <iunlockput>
      end_op();
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	960080e7          	jalr	-1696(ra) # 800040ca <end_op>
      return -1;
    80005772:	54fd                	li	s1,-1
    80005774:	b76d                	j	8000571e <sys_open+0xe4>
      end_op();
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	954080e7          	jalr	-1708(ra) # 800040ca <end_op>
      return -1;
    8000577e:	54fd                	li	s1,-1
    80005780:	bf79                	j	8000571e <sys_open+0xe4>
    iunlockput(ip);
    80005782:	854a                	mv	a0,s2
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	16c080e7          	jalr	364(ra) # 800038f0 <iunlockput>
    end_op();
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	93e080e7          	jalr	-1730(ra) # 800040ca <end_op>
    return -1;
    80005794:	54fd                	li	s1,-1
    80005796:	b761                	j	8000571e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005798:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000579c:	04691783          	lh	a5,70(s2)
    800057a0:	02f99223          	sh	a5,36(s3)
    800057a4:	bf2d                	j	800056de <sys_open+0xa4>
    itrunc(ip);
    800057a6:	854a                	mv	a0,s2
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	ff4080e7          	jalr	-12(ra) # 8000379c <itrunc>
    800057b0:	bfb1                	j	8000570c <sys_open+0xd2>
      fileclose(f);
    800057b2:	854e                	mv	a0,s3
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	d68080e7          	jalr	-664(ra) # 8000451c <fileclose>
    iunlockput(ip);
    800057bc:	854a                	mv	a0,s2
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	132080e7          	jalr	306(ra) # 800038f0 <iunlockput>
    end_op();
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	904080e7          	jalr	-1788(ra) # 800040ca <end_op>
    return -1;
    800057ce:	54fd                	li	s1,-1
    800057d0:	b7b9                	j	8000571e <sys_open+0xe4>

00000000800057d2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057d2:	7175                	addi	sp,sp,-144
    800057d4:	e506                	sd	ra,136(sp)
    800057d6:	e122                	sd	s0,128(sp)
    800057d8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	870080e7          	jalr	-1936(ra) # 8000404a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057e2:	08000613          	li	a2,128
    800057e6:	f7040593          	addi	a1,s0,-144
    800057ea:	4501                	li	a0,0
    800057ec:	ffffd097          	auipc	ra,0xffffd
    800057f0:	2fc080e7          	jalr	764(ra) # 80002ae8 <argstr>
    800057f4:	02054963          	bltz	a0,80005826 <sys_mkdir+0x54>
    800057f8:	4681                	li	a3,0
    800057fa:	4601                	li	a2,0
    800057fc:	4585                	li	a1,1
    800057fe:	f7040513          	addi	a0,s0,-144
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	7fe080e7          	jalr	2046(ra) # 80005000 <create>
    8000580a:	cd11                	beqz	a0,80005826 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	0e4080e7          	jalr	228(ra) # 800038f0 <iunlockput>
  end_op();
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	8b6080e7          	jalr	-1866(ra) # 800040ca <end_op>
  return 0;
    8000581c:	4501                	li	a0,0
}
    8000581e:	60aa                	ld	ra,136(sp)
    80005820:	640a                	ld	s0,128(sp)
    80005822:	6149                	addi	sp,sp,144
    80005824:	8082                	ret
    end_op();
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	8a4080e7          	jalr	-1884(ra) # 800040ca <end_op>
    return -1;
    8000582e:	557d                	li	a0,-1
    80005830:	b7fd                	j	8000581e <sys_mkdir+0x4c>

0000000080005832 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005832:	7135                	addi	sp,sp,-160
    80005834:	ed06                	sd	ra,152(sp)
    80005836:	e922                	sd	s0,144(sp)
    80005838:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	810080e7          	jalr	-2032(ra) # 8000404a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005842:	08000613          	li	a2,128
    80005846:	f7040593          	addi	a1,s0,-144
    8000584a:	4501                	li	a0,0
    8000584c:	ffffd097          	auipc	ra,0xffffd
    80005850:	29c080e7          	jalr	668(ra) # 80002ae8 <argstr>
    80005854:	04054a63          	bltz	a0,800058a8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005858:	f6c40593          	addi	a1,s0,-148
    8000585c:	4505                	li	a0,1
    8000585e:	ffffd097          	auipc	ra,0xffffd
    80005862:	246080e7          	jalr	582(ra) # 80002aa4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005866:	04054163          	bltz	a0,800058a8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000586a:	f6840593          	addi	a1,s0,-152
    8000586e:	4509                	li	a0,2
    80005870:	ffffd097          	auipc	ra,0xffffd
    80005874:	234080e7          	jalr	564(ra) # 80002aa4 <argint>
     argint(1, &major) < 0 ||
    80005878:	02054863          	bltz	a0,800058a8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000587c:	f6841683          	lh	a3,-152(s0)
    80005880:	f6c41603          	lh	a2,-148(s0)
    80005884:	458d                	li	a1,3
    80005886:	f7040513          	addi	a0,s0,-144
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	776080e7          	jalr	1910(ra) # 80005000 <create>
     argint(2, &minor) < 0 ||
    80005892:	c919                	beqz	a0,800058a8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	05c080e7          	jalr	92(ra) # 800038f0 <iunlockput>
  end_op();
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	82e080e7          	jalr	-2002(ra) # 800040ca <end_op>
  return 0;
    800058a4:	4501                	li	a0,0
    800058a6:	a031                	j	800058b2 <sys_mknod+0x80>
    end_op();
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	822080e7          	jalr	-2014(ra) # 800040ca <end_op>
    return -1;
    800058b0:	557d                	li	a0,-1
}
    800058b2:	60ea                	ld	ra,152(sp)
    800058b4:	644a                	ld	s0,144(sp)
    800058b6:	610d                	addi	sp,sp,160
    800058b8:	8082                	ret

00000000800058ba <sys_chdir>:

uint64
sys_chdir(void)
{
    800058ba:	7135                	addi	sp,sp,-160
    800058bc:	ed06                	sd	ra,152(sp)
    800058be:	e922                	sd	s0,144(sp)
    800058c0:	e526                	sd	s1,136(sp)
    800058c2:	e14a                	sd	s2,128(sp)
    800058c4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058c6:	ffffc097          	auipc	ra,0xffffc
    800058ca:	118080e7          	jalr	280(ra) # 800019de <myproc>
    800058ce:	892a                	mv	s2,a0
  
  begin_op();
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	77a080e7          	jalr	1914(ra) # 8000404a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058d8:	08000613          	li	a2,128
    800058dc:	f6040593          	addi	a1,s0,-160
    800058e0:	4501                	li	a0,0
    800058e2:	ffffd097          	auipc	ra,0xffffd
    800058e6:	206080e7          	jalr	518(ra) # 80002ae8 <argstr>
    800058ea:	04054b63          	bltz	a0,80005940 <sys_chdir+0x86>
    800058ee:	f6040513          	addi	a0,s0,-160
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	54c080e7          	jalr	1356(ra) # 80003e3e <namei>
    800058fa:	84aa                	mv	s1,a0
    800058fc:	c131                	beqz	a0,80005940 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	d90080e7          	jalr	-624(ra) # 8000368e <ilock>
  if(ip->type != T_DIR){
    80005906:	04449703          	lh	a4,68(s1)
    8000590a:	4785                	li	a5,1
    8000590c:	04f71063          	bne	a4,a5,8000594c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005910:	8526                	mv	a0,s1
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	e3e080e7          	jalr	-450(ra) # 80003750 <iunlock>
  iput(p->cwd);
    8000591a:	15093503          	ld	a0,336(s2)
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	f2a080e7          	jalr	-214(ra) # 80003848 <iput>
  end_op();
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	7a4080e7          	jalr	1956(ra) # 800040ca <end_op>
  p->cwd = ip;
    8000592e:	14993823          	sd	s1,336(s2)
  return 0;
    80005932:	4501                	li	a0,0
}
    80005934:	60ea                	ld	ra,152(sp)
    80005936:	644a                	ld	s0,144(sp)
    80005938:	64aa                	ld	s1,136(sp)
    8000593a:	690a                	ld	s2,128(sp)
    8000593c:	610d                	addi	sp,sp,160
    8000593e:	8082                	ret
    end_op();
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	78a080e7          	jalr	1930(ra) # 800040ca <end_op>
    return -1;
    80005948:	557d                	li	a0,-1
    8000594a:	b7ed                	j	80005934 <sys_chdir+0x7a>
    iunlockput(ip);
    8000594c:	8526                	mv	a0,s1
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	fa2080e7          	jalr	-94(ra) # 800038f0 <iunlockput>
    end_op();
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	774080e7          	jalr	1908(ra) # 800040ca <end_op>
    return -1;
    8000595e:	557d                	li	a0,-1
    80005960:	bfd1                	j	80005934 <sys_chdir+0x7a>

0000000080005962 <sys_exec>:

uint64
sys_exec(void)
{
    80005962:	7145                	addi	sp,sp,-464
    80005964:	e786                	sd	ra,456(sp)
    80005966:	e3a2                	sd	s0,448(sp)
    80005968:	ff26                	sd	s1,440(sp)
    8000596a:	fb4a                	sd	s2,432(sp)
    8000596c:	f74e                	sd	s3,424(sp)
    8000596e:	f352                	sd	s4,416(sp)
    80005970:	ef56                	sd	s5,408(sp)
    80005972:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005974:	08000613          	li	a2,128
    80005978:	f4040593          	addi	a1,s0,-192
    8000597c:	4501                	li	a0,0
    8000597e:	ffffd097          	auipc	ra,0xffffd
    80005982:	16a080e7          	jalr	362(ra) # 80002ae8 <argstr>
    return -1;
    80005986:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005988:	0c054a63          	bltz	a0,80005a5c <sys_exec+0xfa>
    8000598c:	e3840593          	addi	a1,s0,-456
    80005990:	4505                	li	a0,1
    80005992:	ffffd097          	auipc	ra,0xffffd
    80005996:	134080e7          	jalr	308(ra) # 80002ac6 <argaddr>
    8000599a:	0c054163          	bltz	a0,80005a5c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000599e:	10000613          	li	a2,256
    800059a2:	4581                	li	a1,0
    800059a4:	e4040513          	addi	a0,s0,-448
    800059a8:	ffffb097          	auipc	ra,0xffffb
    800059ac:	364080e7          	jalr	868(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059b0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059b4:	89a6                	mv	s3,s1
    800059b6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059b8:	02000a13          	li	s4,32
    800059bc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059c0:	00391513          	slli	a0,s2,0x3
    800059c4:	e3040593          	addi	a1,s0,-464
    800059c8:	e3843783          	ld	a5,-456(s0)
    800059cc:	953e                	add	a0,a0,a5
    800059ce:	ffffd097          	auipc	ra,0xffffd
    800059d2:	03c080e7          	jalr	60(ra) # 80002a0a <fetchaddr>
    800059d6:	02054a63          	bltz	a0,80005a0a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800059da:	e3043783          	ld	a5,-464(s0)
    800059de:	c3b9                	beqz	a5,80005a24 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059e0:	ffffb097          	auipc	ra,0xffffb
    800059e4:	140080e7          	jalr	320(ra) # 80000b20 <kalloc>
    800059e8:	85aa                	mv	a1,a0
    800059ea:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059ee:	cd11                	beqz	a0,80005a0a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059f0:	6605                	lui	a2,0x1
    800059f2:	e3043503          	ld	a0,-464(s0)
    800059f6:	ffffd097          	auipc	ra,0xffffd
    800059fa:	066080e7          	jalr	102(ra) # 80002a5c <fetchstr>
    800059fe:	00054663          	bltz	a0,80005a0a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a02:	0905                	addi	s2,s2,1
    80005a04:	09a1                	addi	s3,s3,8
    80005a06:	fb491be3          	bne	s2,s4,800059bc <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a0a:	10048913          	addi	s2,s1,256
    80005a0e:	6088                	ld	a0,0(s1)
    80005a10:	c529                	beqz	a0,80005a5a <sys_exec+0xf8>
    kfree(argv[i]);
    80005a12:	ffffb097          	auipc	ra,0xffffb
    80005a16:	012080e7          	jalr	18(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a1a:	04a1                	addi	s1,s1,8
    80005a1c:	ff2499e3          	bne	s1,s2,80005a0e <sys_exec+0xac>
  return -1;
    80005a20:	597d                	li	s2,-1
    80005a22:	a82d                	j	80005a5c <sys_exec+0xfa>
      argv[i] = 0;
    80005a24:	0a8e                	slli	s5,s5,0x3
    80005a26:	fc040793          	addi	a5,s0,-64
    80005a2a:	9abe                	add	s5,s5,a5
    80005a2c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a30:	e4040593          	addi	a1,s0,-448
    80005a34:	f4040513          	addi	a0,s0,-192
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	194080e7          	jalr	404(ra) # 80004bcc <exec>
    80005a40:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a42:	10048993          	addi	s3,s1,256
    80005a46:	6088                	ld	a0,0(s1)
    80005a48:	c911                	beqz	a0,80005a5c <sys_exec+0xfa>
    kfree(argv[i]);
    80005a4a:	ffffb097          	auipc	ra,0xffffb
    80005a4e:	fda080e7          	jalr	-38(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a52:	04a1                	addi	s1,s1,8
    80005a54:	ff3499e3          	bne	s1,s3,80005a46 <sys_exec+0xe4>
    80005a58:	a011                	j	80005a5c <sys_exec+0xfa>
  return -1;
    80005a5a:	597d                	li	s2,-1
}
    80005a5c:	854a                	mv	a0,s2
    80005a5e:	60be                	ld	ra,456(sp)
    80005a60:	641e                	ld	s0,448(sp)
    80005a62:	74fa                	ld	s1,440(sp)
    80005a64:	795a                	ld	s2,432(sp)
    80005a66:	79ba                	ld	s3,424(sp)
    80005a68:	7a1a                	ld	s4,416(sp)
    80005a6a:	6afa                	ld	s5,408(sp)
    80005a6c:	6179                	addi	sp,sp,464
    80005a6e:	8082                	ret

0000000080005a70 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a70:	7139                	addi	sp,sp,-64
    80005a72:	fc06                	sd	ra,56(sp)
    80005a74:	f822                	sd	s0,48(sp)
    80005a76:	f426                	sd	s1,40(sp)
    80005a78:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a7a:	ffffc097          	auipc	ra,0xffffc
    80005a7e:	f64080e7          	jalr	-156(ra) # 800019de <myproc>
    80005a82:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a84:	fd840593          	addi	a1,s0,-40
    80005a88:	4501                	li	a0,0
    80005a8a:	ffffd097          	auipc	ra,0xffffd
    80005a8e:	03c080e7          	jalr	60(ra) # 80002ac6 <argaddr>
    return -1;
    80005a92:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005a94:	0e054063          	bltz	a0,80005b74 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005a98:	fc840593          	addi	a1,s0,-56
    80005a9c:	fd040513          	addi	a0,s0,-48
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	dd2080e7          	jalr	-558(ra) # 80004872 <pipealloc>
    return -1;
    80005aa8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005aaa:	0c054563          	bltz	a0,80005b74 <sys_pipe+0x104>
  fd0 = -1;
    80005aae:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ab2:	fd043503          	ld	a0,-48(s0)
    80005ab6:	fffff097          	auipc	ra,0xfffff
    80005aba:	508080e7          	jalr	1288(ra) # 80004fbe <fdalloc>
    80005abe:	fca42223          	sw	a0,-60(s0)
    80005ac2:	08054c63          	bltz	a0,80005b5a <sys_pipe+0xea>
    80005ac6:	fc843503          	ld	a0,-56(s0)
    80005aca:	fffff097          	auipc	ra,0xfffff
    80005ace:	4f4080e7          	jalr	1268(ra) # 80004fbe <fdalloc>
    80005ad2:	fca42023          	sw	a0,-64(s0)
    80005ad6:	06054863          	bltz	a0,80005b46 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ada:	4691                	li	a3,4
    80005adc:	fc440613          	addi	a2,s0,-60
    80005ae0:	fd843583          	ld	a1,-40(s0)
    80005ae4:	68a8                	ld	a0,80(s1)
    80005ae6:	ffffc097          	auipc	ra,0xffffc
    80005aea:	bec080e7          	jalr	-1044(ra) # 800016d2 <copyout>
    80005aee:	02054063          	bltz	a0,80005b0e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005af2:	4691                	li	a3,4
    80005af4:	fc040613          	addi	a2,s0,-64
    80005af8:	fd843583          	ld	a1,-40(s0)
    80005afc:	0591                	addi	a1,a1,4
    80005afe:	68a8                	ld	a0,80(s1)
    80005b00:	ffffc097          	auipc	ra,0xffffc
    80005b04:	bd2080e7          	jalr	-1070(ra) # 800016d2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b08:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b0a:	06055563          	bgez	a0,80005b74 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b0e:	fc442783          	lw	a5,-60(s0)
    80005b12:	07e9                	addi	a5,a5,26
    80005b14:	078e                	slli	a5,a5,0x3
    80005b16:	97a6                	add	a5,a5,s1
    80005b18:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b1c:	fc042503          	lw	a0,-64(s0)
    80005b20:	0569                	addi	a0,a0,26
    80005b22:	050e                	slli	a0,a0,0x3
    80005b24:	9526                	add	a0,a0,s1
    80005b26:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b2a:	fd043503          	ld	a0,-48(s0)
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	9ee080e7          	jalr	-1554(ra) # 8000451c <fileclose>
    fileclose(wf);
    80005b36:	fc843503          	ld	a0,-56(s0)
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	9e2080e7          	jalr	-1566(ra) # 8000451c <fileclose>
    return -1;
    80005b42:	57fd                	li	a5,-1
    80005b44:	a805                	j	80005b74 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b46:	fc442783          	lw	a5,-60(s0)
    80005b4a:	0007c863          	bltz	a5,80005b5a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b4e:	01a78513          	addi	a0,a5,26
    80005b52:	050e                	slli	a0,a0,0x3
    80005b54:	9526                	add	a0,a0,s1
    80005b56:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b5a:	fd043503          	ld	a0,-48(s0)
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	9be080e7          	jalr	-1602(ra) # 8000451c <fileclose>
    fileclose(wf);
    80005b66:	fc843503          	ld	a0,-56(s0)
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	9b2080e7          	jalr	-1614(ra) # 8000451c <fileclose>
    return -1;
    80005b72:	57fd                	li	a5,-1
}
    80005b74:	853e                	mv	a0,a5
    80005b76:	70e2                	ld	ra,56(sp)
    80005b78:	7442                	ld	s0,48(sp)
    80005b7a:	74a2                	ld	s1,40(sp)
    80005b7c:	6121                	addi	sp,sp,64
    80005b7e:	8082                	ret

0000000080005b80 <kernelvec>:
    80005b80:	7111                	addi	sp,sp,-256
    80005b82:	e006                	sd	ra,0(sp)
    80005b84:	e40a                	sd	sp,8(sp)
    80005b86:	e80e                	sd	gp,16(sp)
    80005b88:	ec12                	sd	tp,24(sp)
    80005b8a:	f016                	sd	t0,32(sp)
    80005b8c:	f41a                	sd	t1,40(sp)
    80005b8e:	f81e                	sd	t2,48(sp)
    80005b90:	fc22                	sd	s0,56(sp)
    80005b92:	e0a6                	sd	s1,64(sp)
    80005b94:	e4aa                	sd	a0,72(sp)
    80005b96:	e8ae                	sd	a1,80(sp)
    80005b98:	ecb2                	sd	a2,88(sp)
    80005b9a:	f0b6                	sd	a3,96(sp)
    80005b9c:	f4ba                	sd	a4,104(sp)
    80005b9e:	f8be                	sd	a5,112(sp)
    80005ba0:	fcc2                	sd	a6,120(sp)
    80005ba2:	e146                	sd	a7,128(sp)
    80005ba4:	e54a                	sd	s2,136(sp)
    80005ba6:	e94e                	sd	s3,144(sp)
    80005ba8:	ed52                	sd	s4,152(sp)
    80005baa:	f156                	sd	s5,160(sp)
    80005bac:	f55a                	sd	s6,168(sp)
    80005bae:	f95e                	sd	s7,176(sp)
    80005bb0:	fd62                	sd	s8,184(sp)
    80005bb2:	e1e6                	sd	s9,192(sp)
    80005bb4:	e5ea                	sd	s10,200(sp)
    80005bb6:	e9ee                	sd	s11,208(sp)
    80005bb8:	edf2                	sd	t3,216(sp)
    80005bba:	f1f6                	sd	t4,224(sp)
    80005bbc:	f5fa                	sd	t5,232(sp)
    80005bbe:	f9fe                	sd	t6,240(sp)
    80005bc0:	d17fc0ef          	jal	ra,800028d6 <kerneltrap>
    80005bc4:	6082                	ld	ra,0(sp)
    80005bc6:	6122                	ld	sp,8(sp)
    80005bc8:	61c2                	ld	gp,16(sp)
    80005bca:	7282                	ld	t0,32(sp)
    80005bcc:	7322                	ld	t1,40(sp)
    80005bce:	73c2                	ld	t2,48(sp)
    80005bd0:	7462                	ld	s0,56(sp)
    80005bd2:	6486                	ld	s1,64(sp)
    80005bd4:	6526                	ld	a0,72(sp)
    80005bd6:	65c6                	ld	a1,80(sp)
    80005bd8:	6666                	ld	a2,88(sp)
    80005bda:	7686                	ld	a3,96(sp)
    80005bdc:	7726                	ld	a4,104(sp)
    80005bde:	77c6                	ld	a5,112(sp)
    80005be0:	7866                	ld	a6,120(sp)
    80005be2:	688a                	ld	a7,128(sp)
    80005be4:	692a                	ld	s2,136(sp)
    80005be6:	69ca                	ld	s3,144(sp)
    80005be8:	6a6a                	ld	s4,152(sp)
    80005bea:	7a8a                	ld	s5,160(sp)
    80005bec:	7b2a                	ld	s6,168(sp)
    80005bee:	7bca                	ld	s7,176(sp)
    80005bf0:	7c6a                	ld	s8,184(sp)
    80005bf2:	6c8e                	ld	s9,192(sp)
    80005bf4:	6d2e                	ld	s10,200(sp)
    80005bf6:	6dce                	ld	s11,208(sp)
    80005bf8:	6e6e                	ld	t3,216(sp)
    80005bfa:	7e8e                	ld	t4,224(sp)
    80005bfc:	7f2e                	ld	t5,232(sp)
    80005bfe:	7fce                	ld	t6,240(sp)
    80005c00:	6111                	addi	sp,sp,256
    80005c02:	10200073          	sret
    80005c06:	00000013          	nop
    80005c0a:	00000013          	nop
    80005c0e:	0001                	nop

0000000080005c10 <timervec>:
    80005c10:	34051573          	csrrw	a0,mscratch,a0
    80005c14:	e10c                	sd	a1,0(a0)
    80005c16:	e510                	sd	a2,8(a0)
    80005c18:	e914                	sd	a3,16(a0)
    80005c1a:	710c                	ld	a1,32(a0)
    80005c1c:	7510                	ld	a2,40(a0)
    80005c1e:	6194                	ld	a3,0(a1)
    80005c20:	96b2                	add	a3,a3,a2
    80005c22:	e194                	sd	a3,0(a1)
    80005c24:	4589                	li	a1,2
    80005c26:	14459073          	csrw	sip,a1
    80005c2a:	6914                	ld	a3,16(a0)
    80005c2c:	6510                	ld	a2,8(a0)
    80005c2e:	610c                	ld	a1,0(a0)
    80005c30:	34051573          	csrrw	a0,mscratch,a0
    80005c34:	30200073          	mret
	...

0000000080005c3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c3a:	1141                	addi	sp,sp,-16
    80005c3c:	e422                	sd	s0,8(sp)
    80005c3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c40:	0c0007b7          	lui	a5,0xc000
    80005c44:	4705                	li	a4,1
    80005c46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c48:	c3d8                	sw	a4,4(a5)
}
    80005c4a:	6422                	ld	s0,8(sp)
    80005c4c:	0141                	addi	sp,sp,16
    80005c4e:	8082                	ret

0000000080005c50 <plicinithart>:

void
plicinithart(void)
{
    80005c50:	1141                	addi	sp,sp,-16
    80005c52:	e406                	sd	ra,8(sp)
    80005c54:	e022                	sd	s0,0(sp)
    80005c56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c58:	ffffc097          	auipc	ra,0xffffc
    80005c5c:	d5a080e7          	jalr	-678(ra) # 800019b2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c60:	0085171b          	slliw	a4,a0,0x8
    80005c64:	0c0027b7          	lui	a5,0xc002
    80005c68:	97ba                	add	a5,a5,a4
    80005c6a:	40200713          	li	a4,1026
    80005c6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c72:	00d5151b          	slliw	a0,a0,0xd
    80005c76:	0c2017b7          	lui	a5,0xc201
    80005c7a:	953e                	add	a0,a0,a5
    80005c7c:	00052023          	sw	zero,0(a0)
}
    80005c80:	60a2                	ld	ra,8(sp)
    80005c82:	6402                	ld	s0,0(sp)
    80005c84:	0141                	addi	sp,sp,16
    80005c86:	8082                	ret

0000000080005c88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c88:	1141                	addi	sp,sp,-16
    80005c8a:	e406                	sd	ra,8(sp)
    80005c8c:	e022                	sd	s0,0(sp)
    80005c8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c90:	ffffc097          	auipc	ra,0xffffc
    80005c94:	d22080e7          	jalr	-734(ra) # 800019b2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c98:	00d5179b          	slliw	a5,a0,0xd
    80005c9c:	0c201537          	lui	a0,0xc201
    80005ca0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ca2:	4148                	lw	a0,4(a0)
    80005ca4:	60a2                	ld	ra,8(sp)
    80005ca6:	6402                	ld	s0,0(sp)
    80005ca8:	0141                	addi	sp,sp,16
    80005caa:	8082                	ret

0000000080005cac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cac:	1101                	addi	sp,sp,-32
    80005cae:	ec06                	sd	ra,24(sp)
    80005cb0:	e822                	sd	s0,16(sp)
    80005cb2:	e426                	sd	s1,8(sp)
    80005cb4:	1000                	addi	s0,sp,32
    80005cb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cb8:	ffffc097          	auipc	ra,0xffffc
    80005cbc:	cfa080e7          	jalr	-774(ra) # 800019b2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cc0:	00d5151b          	slliw	a0,a0,0xd
    80005cc4:	0c2017b7          	lui	a5,0xc201
    80005cc8:	97aa                	add	a5,a5,a0
    80005cca:	c3c4                	sw	s1,4(a5)
}
    80005ccc:	60e2                	ld	ra,24(sp)
    80005cce:	6442                	ld	s0,16(sp)
    80005cd0:	64a2                	ld	s1,8(sp)
    80005cd2:	6105                	addi	sp,sp,32
    80005cd4:	8082                	ret

0000000080005cd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005cd6:	1141                	addi	sp,sp,-16
    80005cd8:	e406                	sd	ra,8(sp)
    80005cda:	e022                	sd	s0,0(sp)
    80005cdc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cde:	479d                	li	a5,7
    80005ce0:	04a7cc63          	blt	a5,a0,80005d38 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005ce4:	0001d797          	auipc	a5,0x1d
    80005ce8:	31c78793          	addi	a5,a5,796 # 80023000 <disk>
    80005cec:	00a78733          	add	a4,a5,a0
    80005cf0:	6789                	lui	a5,0x2
    80005cf2:	97ba                	add	a5,a5,a4
    80005cf4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005cf8:	eba1                	bnez	a5,80005d48 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005cfa:	00451713          	slli	a4,a0,0x4
    80005cfe:	0001f797          	auipc	a5,0x1f
    80005d02:	3027b783          	ld	a5,770(a5) # 80025000 <disk+0x2000>
    80005d06:	97ba                	add	a5,a5,a4
    80005d08:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005d0c:	0001d797          	auipc	a5,0x1d
    80005d10:	2f478793          	addi	a5,a5,756 # 80023000 <disk>
    80005d14:	97aa                	add	a5,a5,a0
    80005d16:	6509                	lui	a0,0x2
    80005d18:	953e                	add	a0,a0,a5
    80005d1a:	4785                	li	a5,1
    80005d1c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d20:	0001f517          	auipc	a0,0x1f
    80005d24:	2f850513          	addi	a0,a0,760 # 80025018 <disk+0x2018>
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	654080e7          	jalr	1620(ra) # 8000237c <wakeup>
}
    80005d30:	60a2                	ld	ra,8(sp)
    80005d32:	6402                	ld	s0,0(sp)
    80005d34:	0141                	addi	sp,sp,16
    80005d36:	8082                	ret
    panic("virtio_disk_intr 1");
    80005d38:	00003517          	auipc	a0,0x3
    80005d3c:	b9850513          	addi	a0,a0,-1128 # 800088d0 <sysnames+0x330>
    80005d40:	ffffb097          	auipc	ra,0xffffb
    80005d44:	808080e7          	jalr	-2040(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005d48:	00003517          	auipc	a0,0x3
    80005d4c:	ba050513          	addi	a0,a0,-1120 # 800088e8 <sysnames+0x348>
    80005d50:	ffffa097          	auipc	ra,0xffffa
    80005d54:	7f8080e7          	jalr	2040(ra) # 80000548 <panic>

0000000080005d58 <virtio_disk_init>:
{
    80005d58:	1101                	addi	sp,sp,-32
    80005d5a:	ec06                	sd	ra,24(sp)
    80005d5c:	e822                	sd	s0,16(sp)
    80005d5e:	e426                	sd	s1,8(sp)
    80005d60:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d62:	00003597          	auipc	a1,0x3
    80005d66:	b9e58593          	addi	a1,a1,-1122 # 80008900 <sysnames+0x360>
    80005d6a:	0001f517          	auipc	a0,0x1f
    80005d6e:	33e50513          	addi	a0,a0,830 # 800250a8 <disk+0x20a8>
    80005d72:	ffffb097          	auipc	ra,0xffffb
    80005d76:	e0e080e7          	jalr	-498(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d7a:	100017b7          	lui	a5,0x10001
    80005d7e:	4398                	lw	a4,0(a5)
    80005d80:	2701                	sext.w	a4,a4
    80005d82:	747277b7          	lui	a5,0x74727
    80005d86:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d8a:	0ef71163          	bne	a4,a5,80005e6c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d8e:	100017b7          	lui	a5,0x10001
    80005d92:	43dc                	lw	a5,4(a5)
    80005d94:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d96:	4705                	li	a4,1
    80005d98:	0ce79a63          	bne	a5,a4,80005e6c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d9c:	100017b7          	lui	a5,0x10001
    80005da0:	479c                	lw	a5,8(a5)
    80005da2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005da4:	4709                	li	a4,2
    80005da6:	0ce79363          	bne	a5,a4,80005e6c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005daa:	100017b7          	lui	a5,0x10001
    80005dae:	47d8                	lw	a4,12(a5)
    80005db0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005db2:	554d47b7          	lui	a5,0x554d4
    80005db6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005dba:	0af71963          	bne	a4,a5,80005e6c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dbe:	100017b7          	lui	a5,0x10001
    80005dc2:	4705                	li	a4,1
    80005dc4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dc6:	470d                	li	a4,3
    80005dc8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005dca:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005dcc:	c7ffe737          	lui	a4,0xc7ffe
    80005dd0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005dd4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005dd6:	2701                	sext.w	a4,a4
    80005dd8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dda:	472d                	li	a4,11
    80005ddc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dde:	473d                	li	a4,15
    80005de0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005de2:	6705                	lui	a4,0x1
    80005de4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005de6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005dea:	5bdc                	lw	a5,52(a5)
    80005dec:	2781                	sext.w	a5,a5
  if(max == 0)
    80005dee:	c7d9                	beqz	a5,80005e7c <virtio_disk_init+0x124>
  if(max < NUM)
    80005df0:	471d                	li	a4,7
    80005df2:	08f77d63          	bgeu	a4,a5,80005e8c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005df6:	100014b7          	lui	s1,0x10001
    80005dfa:	47a1                	li	a5,8
    80005dfc:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005dfe:	6609                	lui	a2,0x2
    80005e00:	4581                	li	a1,0
    80005e02:	0001d517          	auipc	a0,0x1d
    80005e06:	1fe50513          	addi	a0,a0,510 # 80023000 <disk>
    80005e0a:	ffffb097          	auipc	ra,0xffffb
    80005e0e:	f02080e7          	jalr	-254(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e12:	0001d717          	auipc	a4,0x1d
    80005e16:	1ee70713          	addi	a4,a4,494 # 80023000 <disk>
    80005e1a:	00c75793          	srli	a5,a4,0xc
    80005e1e:	2781                	sext.w	a5,a5
    80005e20:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005e22:	0001f797          	auipc	a5,0x1f
    80005e26:	1de78793          	addi	a5,a5,478 # 80025000 <disk+0x2000>
    80005e2a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005e2c:	0001d717          	auipc	a4,0x1d
    80005e30:	25470713          	addi	a4,a4,596 # 80023080 <disk+0x80>
    80005e34:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005e36:	0001e717          	auipc	a4,0x1e
    80005e3a:	1ca70713          	addi	a4,a4,458 # 80024000 <disk+0x1000>
    80005e3e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e40:	4705                	li	a4,1
    80005e42:	00e78c23          	sb	a4,24(a5)
    80005e46:	00e78ca3          	sb	a4,25(a5)
    80005e4a:	00e78d23          	sb	a4,26(a5)
    80005e4e:	00e78da3          	sb	a4,27(a5)
    80005e52:	00e78e23          	sb	a4,28(a5)
    80005e56:	00e78ea3          	sb	a4,29(a5)
    80005e5a:	00e78f23          	sb	a4,30(a5)
    80005e5e:	00e78fa3          	sb	a4,31(a5)
}
    80005e62:	60e2                	ld	ra,24(sp)
    80005e64:	6442                	ld	s0,16(sp)
    80005e66:	64a2                	ld	s1,8(sp)
    80005e68:	6105                	addi	sp,sp,32
    80005e6a:	8082                	ret
    panic("could not find virtio disk");
    80005e6c:	00003517          	auipc	a0,0x3
    80005e70:	aa450513          	addi	a0,a0,-1372 # 80008910 <sysnames+0x370>
    80005e74:	ffffa097          	auipc	ra,0xffffa
    80005e78:	6d4080e7          	jalr	1748(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005e7c:	00003517          	auipc	a0,0x3
    80005e80:	ab450513          	addi	a0,a0,-1356 # 80008930 <sysnames+0x390>
    80005e84:	ffffa097          	auipc	ra,0xffffa
    80005e88:	6c4080e7          	jalr	1732(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005e8c:	00003517          	auipc	a0,0x3
    80005e90:	ac450513          	addi	a0,a0,-1340 # 80008950 <sysnames+0x3b0>
    80005e94:	ffffa097          	auipc	ra,0xffffa
    80005e98:	6b4080e7          	jalr	1716(ra) # 80000548 <panic>

0000000080005e9c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e9c:	7119                	addi	sp,sp,-128
    80005e9e:	fc86                	sd	ra,120(sp)
    80005ea0:	f8a2                	sd	s0,112(sp)
    80005ea2:	f4a6                	sd	s1,104(sp)
    80005ea4:	f0ca                	sd	s2,96(sp)
    80005ea6:	ecce                	sd	s3,88(sp)
    80005ea8:	e8d2                	sd	s4,80(sp)
    80005eaa:	e4d6                	sd	s5,72(sp)
    80005eac:	e0da                	sd	s6,64(sp)
    80005eae:	fc5e                	sd	s7,56(sp)
    80005eb0:	f862                	sd	s8,48(sp)
    80005eb2:	f466                	sd	s9,40(sp)
    80005eb4:	f06a                	sd	s10,32(sp)
    80005eb6:	0100                	addi	s0,sp,128
    80005eb8:	892a                	mv	s2,a0
    80005eba:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ebc:	00c52c83          	lw	s9,12(a0)
    80005ec0:	001c9c9b          	slliw	s9,s9,0x1
    80005ec4:	1c82                	slli	s9,s9,0x20
    80005ec6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005eca:	0001f517          	auipc	a0,0x1f
    80005ece:	1de50513          	addi	a0,a0,478 # 800250a8 <disk+0x20a8>
    80005ed2:	ffffb097          	auipc	ra,0xffffb
    80005ed6:	d3e080e7          	jalr	-706(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    80005eda:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005edc:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005ede:	0001db97          	auipc	s7,0x1d
    80005ee2:	122b8b93          	addi	s7,s7,290 # 80023000 <disk>
    80005ee6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005ee8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005eea:	8a4e                	mv	s4,s3
    80005eec:	a051                	j	80005f70 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005eee:	00fb86b3          	add	a3,s7,a5
    80005ef2:	96da                	add	a3,a3,s6
    80005ef4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005ef8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005efa:	0207c563          	bltz	a5,80005f24 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005efe:	2485                	addiw	s1,s1,1
    80005f00:	0711                	addi	a4,a4,4
    80005f02:	23548d63          	beq	s1,s5,8000613c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005f06:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005f08:	0001f697          	auipc	a3,0x1f
    80005f0c:	11068693          	addi	a3,a3,272 # 80025018 <disk+0x2018>
    80005f10:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005f12:	0006c583          	lbu	a1,0(a3)
    80005f16:	fde1                	bnez	a1,80005eee <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f18:	2785                	addiw	a5,a5,1
    80005f1a:	0685                	addi	a3,a3,1
    80005f1c:	ff879be3          	bne	a5,s8,80005f12 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f20:	57fd                	li	a5,-1
    80005f22:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005f24:	02905a63          	blez	s1,80005f58 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f28:	f9042503          	lw	a0,-112(s0)
    80005f2c:	00000097          	auipc	ra,0x0
    80005f30:	daa080e7          	jalr	-598(ra) # 80005cd6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f34:	4785                	li	a5,1
    80005f36:	0297d163          	bge	a5,s1,80005f58 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f3a:	f9442503          	lw	a0,-108(s0)
    80005f3e:	00000097          	auipc	ra,0x0
    80005f42:	d98080e7          	jalr	-616(ra) # 80005cd6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f46:	4789                	li	a5,2
    80005f48:	0097d863          	bge	a5,s1,80005f58 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f4c:	f9842503          	lw	a0,-104(s0)
    80005f50:	00000097          	auipc	ra,0x0
    80005f54:	d86080e7          	jalr	-634(ra) # 80005cd6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f58:	0001f597          	auipc	a1,0x1f
    80005f5c:	15058593          	addi	a1,a1,336 # 800250a8 <disk+0x20a8>
    80005f60:	0001f517          	auipc	a0,0x1f
    80005f64:	0b850513          	addi	a0,a0,184 # 80025018 <disk+0x2018>
    80005f68:	ffffc097          	auipc	ra,0xffffc
    80005f6c:	28e080e7          	jalr	654(ra) # 800021f6 <sleep>
  for(int i = 0; i < 3; i++){
    80005f70:	f9040713          	addi	a4,s0,-112
    80005f74:	84ce                	mv	s1,s3
    80005f76:	bf41                	j	80005f06 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80005f78:	4785                	li	a5,1
    80005f7a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    80005f7e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80005f82:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80005f86:	f9042983          	lw	s3,-112(s0)
    80005f8a:	00499493          	slli	s1,s3,0x4
    80005f8e:	0001fa17          	auipc	s4,0x1f
    80005f92:	072a0a13          	addi	s4,s4,114 # 80025000 <disk+0x2000>
    80005f96:	000a3a83          	ld	s5,0(s4)
    80005f9a:	9aa6                	add	s5,s5,s1
    80005f9c:	f8040513          	addi	a0,s0,-128
    80005fa0:	ffffb097          	auipc	ra,0xffffb
    80005fa4:	140080e7          	jalr	320(ra) # 800010e0 <kvmpa>
    80005fa8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    80005fac:	000a3783          	ld	a5,0(s4)
    80005fb0:	97a6                	add	a5,a5,s1
    80005fb2:	4741                	li	a4,16
    80005fb4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005fb6:	000a3783          	ld	a5,0(s4)
    80005fba:	97a6                	add	a5,a5,s1
    80005fbc:	4705                	li	a4,1
    80005fbe:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80005fc2:	f9442703          	lw	a4,-108(s0)
    80005fc6:	000a3783          	ld	a5,0(s4)
    80005fca:	97a6                	add	a5,a5,s1
    80005fcc:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005fd0:	0712                	slli	a4,a4,0x4
    80005fd2:	000a3783          	ld	a5,0(s4)
    80005fd6:	97ba                	add	a5,a5,a4
    80005fd8:	05890693          	addi	a3,s2,88
    80005fdc:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    80005fde:	000a3783          	ld	a5,0(s4)
    80005fe2:	97ba                	add	a5,a5,a4
    80005fe4:	40000693          	li	a3,1024
    80005fe8:	c794                	sw	a3,8(a5)
  if(write)
    80005fea:	100d0a63          	beqz	s10,800060fe <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fee:	0001f797          	auipc	a5,0x1f
    80005ff2:	0127b783          	ld	a5,18(a5) # 80025000 <disk+0x2000>
    80005ff6:	97ba                	add	a5,a5,a4
    80005ff8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005ffc:	0001d517          	auipc	a0,0x1d
    80006000:	00450513          	addi	a0,a0,4 # 80023000 <disk>
    80006004:	0001f797          	auipc	a5,0x1f
    80006008:	ffc78793          	addi	a5,a5,-4 # 80025000 <disk+0x2000>
    8000600c:	6394                	ld	a3,0(a5)
    8000600e:	96ba                	add	a3,a3,a4
    80006010:	00c6d603          	lhu	a2,12(a3)
    80006014:	00166613          	ori	a2,a2,1
    80006018:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000601c:	f9842683          	lw	a3,-104(s0)
    80006020:	6390                	ld	a2,0(a5)
    80006022:	9732                	add	a4,a4,a2
    80006024:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006028:	20098613          	addi	a2,s3,512
    8000602c:	0612                	slli	a2,a2,0x4
    8000602e:	962a                	add	a2,a2,a0
    80006030:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006034:	00469713          	slli	a4,a3,0x4
    80006038:	6394                	ld	a3,0(a5)
    8000603a:	96ba                	add	a3,a3,a4
    8000603c:	6589                	lui	a1,0x2
    8000603e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006042:	94ae                	add	s1,s1,a1
    80006044:	94aa                	add	s1,s1,a0
    80006046:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006048:	6394                	ld	a3,0(a5)
    8000604a:	96ba                	add	a3,a3,a4
    8000604c:	4585                	li	a1,1
    8000604e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006050:	6394                	ld	a3,0(a5)
    80006052:	96ba                	add	a3,a3,a4
    80006054:	4509                	li	a0,2
    80006056:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000605a:	6394                	ld	a3,0(a5)
    8000605c:	9736                	add	a4,a4,a3
    8000605e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006062:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006066:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000606a:	6794                	ld	a3,8(a5)
    8000606c:	0026d703          	lhu	a4,2(a3)
    80006070:	8b1d                	andi	a4,a4,7
    80006072:	2709                	addiw	a4,a4,2
    80006074:	0706                	slli	a4,a4,0x1
    80006076:	9736                	add	a4,a4,a3
    80006078:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000607c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006080:	6798                	ld	a4,8(a5)
    80006082:	00275783          	lhu	a5,2(a4)
    80006086:	2785                	addiw	a5,a5,1
    80006088:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000608c:	100017b7          	lui	a5,0x10001
    80006090:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006094:	00492703          	lw	a4,4(s2)
    80006098:	4785                	li	a5,1
    8000609a:	02f71163          	bne	a4,a5,800060bc <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000609e:	0001f997          	auipc	s3,0x1f
    800060a2:	00a98993          	addi	s3,s3,10 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800060a6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800060a8:	85ce                	mv	a1,s3
    800060aa:	854a                	mv	a0,s2
    800060ac:	ffffc097          	auipc	ra,0xffffc
    800060b0:	14a080e7          	jalr	330(ra) # 800021f6 <sleep>
  while(b->disk == 1) {
    800060b4:	00492783          	lw	a5,4(s2)
    800060b8:	fe9788e3          	beq	a5,s1,800060a8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800060bc:	f9042483          	lw	s1,-112(s0)
    800060c0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800060c4:	00479713          	slli	a4,a5,0x4
    800060c8:	0001d797          	auipc	a5,0x1d
    800060cc:	f3878793          	addi	a5,a5,-200 # 80023000 <disk>
    800060d0:	97ba                	add	a5,a5,a4
    800060d2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800060d6:	0001f917          	auipc	s2,0x1f
    800060da:	f2a90913          	addi	s2,s2,-214 # 80025000 <disk+0x2000>
    free_desc(i);
    800060de:	8526                	mv	a0,s1
    800060e0:	00000097          	auipc	ra,0x0
    800060e4:	bf6080e7          	jalr	-1034(ra) # 80005cd6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800060e8:	0492                	slli	s1,s1,0x4
    800060ea:	00093783          	ld	a5,0(s2)
    800060ee:	94be                	add	s1,s1,a5
    800060f0:	00c4d783          	lhu	a5,12(s1)
    800060f4:	8b85                	andi	a5,a5,1
    800060f6:	cf89                	beqz	a5,80006110 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800060f8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800060fc:	b7cd                	j	800060de <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060fe:	0001f797          	auipc	a5,0x1f
    80006102:	f027b783          	ld	a5,-254(a5) # 80025000 <disk+0x2000>
    80006106:	97ba                	add	a5,a5,a4
    80006108:	4689                	li	a3,2
    8000610a:	00d79623          	sh	a3,12(a5)
    8000610e:	b5fd                	j	80005ffc <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006110:	0001f517          	auipc	a0,0x1f
    80006114:	f9850513          	addi	a0,a0,-104 # 800250a8 <disk+0x20a8>
    80006118:	ffffb097          	auipc	ra,0xffffb
    8000611c:	bac080e7          	jalr	-1108(ra) # 80000cc4 <release>
}
    80006120:	70e6                	ld	ra,120(sp)
    80006122:	7446                	ld	s0,112(sp)
    80006124:	74a6                	ld	s1,104(sp)
    80006126:	7906                	ld	s2,96(sp)
    80006128:	69e6                	ld	s3,88(sp)
    8000612a:	6a46                	ld	s4,80(sp)
    8000612c:	6aa6                	ld	s5,72(sp)
    8000612e:	6b06                	ld	s6,64(sp)
    80006130:	7be2                	ld	s7,56(sp)
    80006132:	7c42                	ld	s8,48(sp)
    80006134:	7ca2                	ld	s9,40(sp)
    80006136:	7d02                	ld	s10,32(sp)
    80006138:	6109                	addi	sp,sp,128
    8000613a:	8082                	ret
  if(write)
    8000613c:	e20d1ee3          	bnez	s10,80005f78 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006140:	f8042023          	sw	zero,-128(s0)
    80006144:	bd2d                	j	80005f7e <virtio_disk_rw+0xe2>

0000000080006146 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006146:	1101                	addi	sp,sp,-32
    80006148:	ec06                	sd	ra,24(sp)
    8000614a:	e822                	sd	s0,16(sp)
    8000614c:	e426                	sd	s1,8(sp)
    8000614e:	e04a                	sd	s2,0(sp)
    80006150:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006152:	0001f517          	auipc	a0,0x1f
    80006156:	f5650513          	addi	a0,a0,-170 # 800250a8 <disk+0x20a8>
    8000615a:	ffffb097          	auipc	ra,0xffffb
    8000615e:	ab6080e7          	jalr	-1354(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006162:	0001f717          	auipc	a4,0x1f
    80006166:	e9e70713          	addi	a4,a4,-354 # 80025000 <disk+0x2000>
    8000616a:	02075783          	lhu	a5,32(a4)
    8000616e:	6b18                	ld	a4,16(a4)
    80006170:	00275683          	lhu	a3,2(a4)
    80006174:	8ebd                	xor	a3,a3,a5
    80006176:	8a9d                	andi	a3,a3,7
    80006178:	cab9                	beqz	a3,800061ce <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000617a:	0001d917          	auipc	s2,0x1d
    8000617e:	e8690913          	addi	s2,s2,-378 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006182:	0001f497          	auipc	s1,0x1f
    80006186:	e7e48493          	addi	s1,s1,-386 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000618a:	078e                	slli	a5,a5,0x3
    8000618c:	97ba                	add	a5,a5,a4
    8000618e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006190:	20078713          	addi	a4,a5,512
    80006194:	0712                	slli	a4,a4,0x4
    80006196:	974a                	add	a4,a4,s2
    80006198:	03074703          	lbu	a4,48(a4)
    8000619c:	ef21                	bnez	a4,800061f4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000619e:	20078793          	addi	a5,a5,512
    800061a2:	0792                	slli	a5,a5,0x4
    800061a4:	97ca                	add	a5,a5,s2
    800061a6:	7798                	ld	a4,40(a5)
    800061a8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800061ac:	7788                	ld	a0,40(a5)
    800061ae:	ffffc097          	auipc	ra,0xffffc
    800061b2:	1ce080e7          	jalr	462(ra) # 8000237c <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800061b6:	0204d783          	lhu	a5,32(s1)
    800061ba:	2785                	addiw	a5,a5,1
    800061bc:	8b9d                	andi	a5,a5,7
    800061be:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800061c2:	6898                	ld	a4,16(s1)
    800061c4:	00275683          	lhu	a3,2(a4)
    800061c8:	8a9d                	andi	a3,a3,7
    800061ca:	fcf690e3          	bne	a3,a5,8000618a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061ce:	10001737          	lui	a4,0x10001
    800061d2:	533c                	lw	a5,96(a4)
    800061d4:	8b8d                	andi	a5,a5,3
    800061d6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800061d8:	0001f517          	auipc	a0,0x1f
    800061dc:	ed050513          	addi	a0,a0,-304 # 800250a8 <disk+0x20a8>
    800061e0:	ffffb097          	auipc	ra,0xffffb
    800061e4:	ae4080e7          	jalr	-1308(ra) # 80000cc4 <release>
}
    800061e8:	60e2                	ld	ra,24(sp)
    800061ea:	6442                	ld	s0,16(sp)
    800061ec:	64a2                	ld	s1,8(sp)
    800061ee:	6902                	ld	s2,0(sp)
    800061f0:	6105                	addi	sp,sp,32
    800061f2:	8082                	ret
      panic("virtio_disk_intr status");
    800061f4:	00002517          	auipc	a0,0x2
    800061f8:	77c50513          	addi	a0,a0,1916 # 80008970 <sysnames+0x3d0>
    800061fc:	ffffa097          	auipc	ra,0xffffa
    80006200:	34c080e7          	jalr	844(ra) # 80000548 <panic>
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
