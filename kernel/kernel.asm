
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9f013103          	ld	sp,-1552(sp) # 800089f0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000060:	cc478793          	addi	a5,a5,-828 # 80005d20 <timervec>
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
    8000012a:	3d2080e7          	jalr	978(ra) # 800024f8 <either_copyin>
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
    800001d2:	85a080e7          	jalr	-1958(ra) # 80001a28 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	062080e7          	jalr	98(ra) # 80002240 <sleep>
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
    8000021e:	288080e7          	jalr	648(ra) # 800024a2 <either_copyout>
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
    80000300:	252080e7          	jalr	594(ra) # 8000254e <procdump>
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
    80000454:	f76080e7          	jalr	-138(ra) # 800023c6 <wakeup>
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
    800008ba:	b10080e7          	jalr	-1264(ra) # 800023c6 <wakeup>
    
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
    80000954:	8f0080e7          	jalr	-1808(ra) # 80002240 <sleep>
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
  acquire(&kmem.lock); // 上锁, 防止数据竞态
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
    free += PGSIZE; // 每一页固定4096字节
    80000ba2:	6705                	lui	a4,0x1
    80000ba4:	94ba                	add	s1,s1,a4
    r = r->next; // 遍历单链表
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
    80000bf8:	e18080e7          	jalr	-488(ra) # 80001a0c <mycpu>
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
    80000c2a:	de6080e7          	jalr	-538(ra) # 80001a0c <mycpu>
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	cf89                	beqz	a5,80000c4a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	dda080e7          	jalr	-550(ra) # 80001a0c <mycpu>
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
    80000c4e:	dc2080e7          	jalr	-574(ra) # 80001a0c <mycpu>
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
    80000c8e:	d82080e7          	jalr	-638(ra) # 80001a0c <mycpu>
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
    80000cba:	d56080e7          	jalr	-682(ra) # 80001a0c <mycpu>
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
    80000f14:	aec080e7          	jalr	-1300(ra) # 800019fc <cpuid>
    virtio_disk_init(); // emulated hard disk
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
    80000f30:	ad0080e7          	jalr	-1328(ra) # 800019fc <cpuid>
    80000f34:	85aa                	mv	a1,a0
    80000f36:	00007517          	auipc	a0,0x7
    80000f3a:	18250513          	addi	a0,a0,386 # 800080b8 <digits+0x78>
    80000f3e:	fffff097          	auipc	ra,0xfffff
    80000f42:	654080e7          	jalr	1620(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	0d8080e7          	jalr	216(ra) # 8000101e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f4e:	00001097          	auipc	ra,0x1
    80000f52:	794080e7          	jalr	1940(ra) # 800026e2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f56:	00005097          	auipc	ra,0x5
    80000f5a:	e0a080e7          	jalr	-502(ra) # 80005d60 <plicinithart>
  }

  scheduler();        
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	006080e7          	jalr	6(ra) # 80001f64 <scheduler>
    consoleinit();
    80000f66:	fffff097          	auipc	ra,0xfffff
    80000f6a:	4f4080e7          	jalr	1268(ra) # 8000045a <consoleinit>
    printfinit();
    80000f6e:	00000097          	auipc	ra,0x0
    80000f72:	80a080e7          	jalr	-2038(ra) # 80000778 <printfinit>
    printf("\n");
    80000f76:	00007517          	auipc	a0,0x7
    80000f7a:	15250513          	addi	a0,a0,338 # 800080c8 <digits+0x88>
    80000f7e:	fffff097          	auipc	ra,0xfffff
    80000f82:	614080e7          	jalr	1556(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f86:	00007517          	auipc	a0,0x7
    80000f8a:	11a50513          	addi	a0,a0,282 # 800080a0 <digits+0x60>
    80000f8e:	fffff097          	auipc	ra,0xfffff
    80000f92:	604080e7          	jalr	1540(ra) # 80000592 <printf>
    printf("\n");
    80000f96:	00007517          	auipc	a0,0x7
    80000f9a:	13250513          	addi	a0,a0,306 # 800080c8 <digits+0x88>
    80000f9e:	fffff097          	auipc	ra,0xfffff
    80000fa2:	5f4080e7          	jalr	1524(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000fa6:	00000097          	auipc	ra,0x0
    80000faa:	b3e080e7          	jalr	-1218(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000fae:	00000097          	auipc	ra,0x0
    80000fb2:	2a0080e7          	jalr	672(ra) # 8000124e <kvminit>
    kvminithart();   // turn on paging
    80000fb6:	00000097          	auipc	ra,0x0
    80000fba:	068080e7          	jalr	104(ra) # 8000101e <kvminithart>
    procinit();      // process table
    80000fbe:	00001097          	auipc	ra,0x1
    80000fc2:	96e080e7          	jalr	-1682(ra) # 8000192c <procinit>
    trapinit();      // trap vectors
    80000fc6:	00001097          	auipc	ra,0x1
    80000fca:	6f4080e7          	jalr	1780(ra) # 800026ba <trapinit>
    trapinithart();  // install kernel trap vector
    80000fce:	00001097          	auipc	ra,0x1
    80000fd2:	714080e7          	jalr	1812(ra) # 800026e2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fd6:	00005097          	auipc	ra,0x5
    80000fda:	d74080e7          	jalr	-652(ra) # 80005d4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	d82080e7          	jalr	-638(ra) # 80005d60 <plicinithart>
    binit();         // buffer cache
    80000fe6:	00002097          	auipc	ra,0x2
    80000fea:	f1a080e7          	jalr	-230(ra) # 80002f00 <binit>
    iinit();         // inode cache
    80000fee:	00002097          	auipc	ra,0x2
    80000ff2:	5aa080e7          	jalr	1450(ra) # 80003598 <iinit>
    fileinit();      // file table
    80000ff6:	00003097          	auipc	ra,0x3
    80000ffa:	544080e7          	jalr	1348(ra) # 8000453a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ffe:	00005097          	auipc	ra,0x5
    80001002:	e6a080e7          	jalr	-406(ra) # 80005e68 <virtio_disk_init>
    userinit();      // first user process
    80001006:	00001097          	auipc	ra,0x1
    8000100a:	cf0080e7          	jalr	-784(ra) # 80001cf6 <userinit>
    __sync_synchronize();
    8000100e:	0ff0000f          	fence
    started = 1;
    80001012:	4785                	li	a5,1
    80001014:	00008717          	auipc	a4,0x8
    80001018:	fef72c23          	sw	a5,-8(a4) # 8000900c <started>
    8000101c:	b789                	j	80000f5e <main+0x56>

000000008000101e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000101e:	1141                	addi	sp,sp,-16
    80001020:	e422                	sd	s0,8(sp)
    80001022:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001024:	00008797          	auipc	a5,0x8
    80001028:	fec7b783          	ld	a5,-20(a5) # 80009010 <kernel_pagetable>
    8000102c:	83b1                	srli	a5,a5,0xc
    8000102e:	577d                	li	a4,-1
    80001030:	177e                	slli	a4,a4,0x3f
    80001032:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001034:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001038:	12000073          	sfence.vma
  sfence_vma();
}
    8000103c:	6422                	ld	s0,8(sp)
    8000103e:	0141                	addi	sp,sp,16
    80001040:	8082                	ret

0000000080001042 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001042:	7139                	addi	sp,sp,-64
    80001044:	fc06                	sd	ra,56(sp)
    80001046:	f822                	sd	s0,48(sp)
    80001048:	f426                	sd	s1,40(sp)
    8000104a:	f04a                	sd	s2,32(sp)
    8000104c:	ec4e                	sd	s3,24(sp)
    8000104e:	e852                	sd	s4,16(sp)
    80001050:	e456                	sd	s5,8(sp)
    80001052:	e05a                	sd	s6,0(sp)
    80001054:	0080                	addi	s0,sp,64
    80001056:	84aa                	mv	s1,a0
    80001058:	89ae                	mv	s3,a1
    8000105a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001062:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001064:	04b7f263          	bgeu	a5,a1,800010a8 <walk+0x66>
    panic("walk");
    80001068:	00007517          	auipc	a0,0x7
    8000106c:	06850513          	addi	a0,a0,104 # 800080d0 <digits+0x90>
    80001070:	fffff097          	auipc	ra,0xfffff
    80001074:	4d8080e7          	jalr	1240(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001078:	060a8663          	beqz	s5,800010e4 <walk+0xa2>
    8000107c:	00000097          	auipc	ra,0x0
    80001080:	aa4080e7          	jalr	-1372(ra) # 80000b20 <kalloc>
    80001084:	84aa                	mv	s1,a0
    80001086:	c529                	beqz	a0,800010d0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001088:	6605                	lui	a2,0x1
    8000108a:	4581                	li	a1,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	cca080e7          	jalr	-822(ra) # 80000d56 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001094:	00c4d793          	srli	a5,s1,0xc
    80001098:	07aa                	slli	a5,a5,0xa
    8000109a:	0017e793          	ori	a5,a5,1
    8000109e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010a2:	3a5d                	addiw	s4,s4,-9
    800010a4:	036a0063          	beq	s4,s6,800010c4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010a8:	0149d933          	srl	s2,s3,s4
    800010ac:	1ff97913          	andi	s2,s2,511
    800010b0:	090e                	slli	s2,s2,0x3
    800010b2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010b4:	00093483          	ld	s1,0(s2)
    800010b8:	0014f793          	andi	a5,s1,1
    800010bc:	dfd5                	beqz	a5,80001078 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010be:	80a9                	srli	s1,s1,0xa
    800010c0:	04b2                	slli	s1,s1,0xc
    800010c2:	b7c5                	j	800010a2 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010c4:	00c9d513          	srli	a0,s3,0xc
    800010c8:	1ff57513          	andi	a0,a0,511
    800010cc:	050e                	slli	a0,a0,0x3
    800010ce:	9526                	add	a0,a0,s1
}
    800010d0:	70e2                	ld	ra,56(sp)
    800010d2:	7442                	ld	s0,48(sp)
    800010d4:	74a2                	ld	s1,40(sp)
    800010d6:	7902                	ld	s2,32(sp)
    800010d8:	69e2                	ld	s3,24(sp)
    800010da:	6a42                	ld	s4,16(sp)
    800010dc:	6aa2                	ld	s5,8(sp)
    800010de:	6b02                	ld	s6,0(sp)
    800010e0:	6121                	addi	sp,sp,64
    800010e2:	8082                	ret
        return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7ed                	j	800010d0 <walk+0x8e>

00000000800010e8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010e8:	57fd                	li	a5,-1
    800010ea:	83e9                	srli	a5,a5,0x1a
    800010ec:	00b7f463          	bgeu	a5,a1,800010f4 <walkaddr+0xc>
    return 0;
    800010f0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010f2:	8082                	ret
{
    800010f4:	1141                	addi	sp,sp,-16
    800010f6:	e406                	sd	ra,8(sp)
    800010f8:	e022                	sd	s0,0(sp)
    800010fa:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010fc:	4601                	li	a2,0
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	f44080e7          	jalr	-188(ra) # 80001042 <walk>
  if(pte == 0)
    80001106:	c105                	beqz	a0,80001126 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001108:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000110a:	0117f693          	andi	a3,a5,17
    8000110e:	4745                	li	a4,17
    return 0;
    80001110:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001112:	00e68663          	beq	a3,a4,8000111e <walkaddr+0x36>
}
    80001116:	60a2                	ld	ra,8(sp)
    80001118:	6402                	ld	s0,0(sp)
    8000111a:	0141                	addi	sp,sp,16
    8000111c:	8082                	ret
  pa = PTE2PA(*pte);
    8000111e:	00a7d513          	srli	a0,a5,0xa
    80001122:	0532                	slli	a0,a0,0xc
  return pa;
    80001124:	bfcd                	j	80001116 <walkaddr+0x2e>
    return 0;
    80001126:	4501                	li	a0,0
    80001128:	b7fd                	j	80001116 <walkaddr+0x2e>

000000008000112a <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000112a:	1101                	addi	sp,sp,-32
    8000112c:	ec06                	sd	ra,24(sp)
    8000112e:	e822                	sd	s0,16(sp)
    80001130:	e426                	sd	s1,8(sp)
    80001132:	1000                	addi	s0,sp,32
    80001134:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001136:	1552                	slli	a0,a0,0x34
    80001138:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000113c:	4601                	li	a2,0
    8000113e:	00008517          	auipc	a0,0x8
    80001142:	ed253503          	ld	a0,-302(a0) # 80009010 <kernel_pagetable>
    80001146:	00000097          	auipc	ra,0x0
    8000114a:	efc080e7          	jalr	-260(ra) # 80001042 <walk>
  if(pte == 0)
    8000114e:	cd09                	beqz	a0,80001168 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001150:	6108                	ld	a0,0(a0)
    80001152:	00157793          	andi	a5,a0,1
    80001156:	c38d                	beqz	a5,80001178 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001158:	8129                	srli	a0,a0,0xa
    8000115a:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000115c:	9526                	add	a0,a0,s1
    8000115e:	60e2                	ld	ra,24(sp)
    80001160:	6442                	ld	s0,16(sp)
    80001162:	64a2                	ld	s1,8(sp)
    80001164:	6105                	addi	sp,sp,32
    80001166:	8082                	ret
    panic("kvmpa");
    80001168:	00007517          	auipc	a0,0x7
    8000116c:	f7050513          	addi	a0,a0,-144 # 800080d8 <digits+0x98>
    80001170:	fffff097          	auipc	ra,0xfffff
    80001174:	3d8080e7          	jalr	984(ra) # 80000548 <panic>
    panic("kvmpa");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f6050513          	addi	a0,a0,-160 # 800080d8 <digits+0x98>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3c8080e7          	jalr	968(ra) # 80000548 <panic>

0000000080001188 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001188:	715d                	addi	sp,sp,-80
    8000118a:	e486                	sd	ra,72(sp)
    8000118c:	e0a2                	sd	s0,64(sp)
    8000118e:	fc26                	sd	s1,56(sp)
    80001190:	f84a                	sd	s2,48(sp)
    80001192:	f44e                	sd	s3,40(sp)
    80001194:	f052                	sd	s4,32(sp)
    80001196:	ec56                	sd	s5,24(sp)
    80001198:	e85a                	sd	s6,16(sp)
    8000119a:	e45e                	sd	s7,8(sp)
    8000119c:	0880                	addi	s0,sp,80
    8000119e:	8aaa                	mv	s5,a0
    800011a0:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011a2:	777d                	lui	a4,0xfffff
    800011a4:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011a8:	167d                	addi	a2,a2,-1
    800011aa:	00b609b3          	add	s3,a2,a1
    800011ae:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011b2:	893e                	mv	s2,a5
    800011b4:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011b8:	6b85                	lui	s7,0x1
    800011ba:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011be:	4605                	li	a2,1
    800011c0:	85ca                	mv	a1,s2
    800011c2:	8556                	mv	a0,s5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	e7e080e7          	jalr	-386(ra) # 80001042 <walk>
    800011cc:	c51d                	beqz	a0,800011fa <mappages+0x72>
    if(*pte & PTE_V)
    800011ce:	611c                	ld	a5,0(a0)
    800011d0:	8b85                	andi	a5,a5,1
    800011d2:	ef81                	bnez	a5,800011ea <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011d4:	80b1                	srli	s1,s1,0xc
    800011d6:	04aa                	slli	s1,s1,0xa
    800011d8:	0164e4b3          	or	s1,s1,s6
    800011dc:	0014e493          	ori	s1,s1,1
    800011e0:	e104                	sd	s1,0(a0)
    if(a == last)
    800011e2:	03390863          	beq	s2,s3,80001212 <mappages+0x8a>
    a += PGSIZE;
    800011e6:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011e8:	bfc9                	j	800011ba <mappages+0x32>
      panic("remap");
    800011ea:	00007517          	auipc	a0,0x7
    800011ee:	ef650513          	addi	a0,a0,-266 # 800080e0 <digits+0xa0>
    800011f2:	fffff097          	auipc	ra,0xfffff
    800011f6:	356080e7          	jalr	854(ra) # 80000548 <panic>
      return -1;
    800011fa:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011fc:	60a6                	ld	ra,72(sp)
    800011fe:	6406                	ld	s0,64(sp)
    80001200:	74e2                	ld	s1,56(sp)
    80001202:	7942                	ld	s2,48(sp)
    80001204:	79a2                	ld	s3,40(sp)
    80001206:	7a02                	ld	s4,32(sp)
    80001208:	6ae2                	ld	s5,24(sp)
    8000120a:	6b42                	ld	s6,16(sp)
    8000120c:	6ba2                	ld	s7,8(sp)
    8000120e:	6161                	addi	sp,sp,80
    80001210:	8082                	ret
  return 0;
    80001212:	4501                	li	a0,0
    80001214:	b7e5                	j	800011fc <mappages+0x74>

0000000080001216 <kvmmap>:
{
    80001216:	1141                	addi	sp,sp,-16
    80001218:	e406                	sd	ra,8(sp)
    8000121a:	e022                	sd	s0,0(sp)
    8000121c:	0800                	addi	s0,sp,16
    8000121e:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001220:	86ae                	mv	a3,a1
    80001222:	85aa                	mv	a1,a0
    80001224:	00008517          	auipc	a0,0x8
    80001228:	dec53503          	ld	a0,-532(a0) # 80009010 <kernel_pagetable>
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f5c080e7          	jalr	-164(ra) # 80001188 <mappages>
    80001234:	e509                	bnez	a0,8000123e <kvmmap+0x28>
}
    80001236:	60a2                	ld	ra,8(sp)
    80001238:	6402                	ld	s0,0(sp)
    8000123a:	0141                	addi	sp,sp,16
    8000123c:	8082                	ret
    panic("kvmmap");
    8000123e:	00007517          	auipc	a0,0x7
    80001242:	eaa50513          	addi	a0,a0,-342 # 800080e8 <digits+0xa8>
    80001246:	fffff097          	auipc	ra,0xfffff
    8000124a:	302080e7          	jalr	770(ra) # 80000548 <panic>

000000008000124e <kvminit>:
{
    8000124e:	1101                	addi	sp,sp,-32
    80001250:	ec06                	sd	ra,24(sp)
    80001252:	e822                	sd	s0,16(sp)
    80001254:	e426                	sd	s1,8(sp)
    80001256:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001258:	00000097          	auipc	ra,0x0
    8000125c:	8c8080e7          	jalr	-1848(ra) # 80000b20 <kalloc>
    80001260:	00008797          	auipc	a5,0x8
    80001264:	daa7b823          	sd	a0,-592(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001268:	6605                	lui	a2,0x1
    8000126a:	4581                	li	a1,0
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	aea080e7          	jalr	-1302(ra) # 80000d56 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001274:	4699                	li	a3,6
    80001276:	6605                	lui	a2,0x1
    80001278:	100005b7          	lui	a1,0x10000
    8000127c:	10000537          	lui	a0,0x10000
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f96080e7          	jalr	-106(ra) # 80001216 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001288:	4699                	li	a3,6
    8000128a:	6605                	lui	a2,0x1
    8000128c:	100015b7          	lui	a1,0x10001
    80001290:	10001537          	lui	a0,0x10001
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f82080e7          	jalr	-126(ra) # 80001216 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000129c:	4699                	li	a3,6
    8000129e:	6641                	lui	a2,0x10
    800012a0:	020005b7          	lui	a1,0x2000
    800012a4:	02000537          	lui	a0,0x2000
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f6e080e7          	jalr	-146(ra) # 80001216 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012b0:	4699                	li	a3,6
    800012b2:	00400637          	lui	a2,0x400
    800012b6:	0c0005b7          	lui	a1,0xc000
    800012ba:	0c000537          	lui	a0,0xc000
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	f58080e7          	jalr	-168(ra) # 80001216 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012c6:	00007497          	auipc	s1,0x7
    800012ca:	d3a48493          	addi	s1,s1,-710 # 80008000 <etext>
    800012ce:	46a9                	li	a3,10
    800012d0:	80007617          	auipc	a2,0x80007
    800012d4:	d3060613          	addi	a2,a2,-720 # 8000 <_entry-0x7fff8000>
    800012d8:	4585                	li	a1,1
    800012da:	05fe                	slli	a1,a1,0x1f
    800012dc:	852e                	mv	a0,a1
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	f38080e7          	jalr	-200(ra) # 80001216 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012e6:	4699                	li	a3,6
    800012e8:	4645                	li	a2,17
    800012ea:	066e                	slli	a2,a2,0x1b
    800012ec:	8e05                	sub	a2,a2,s1
    800012ee:	85a6                	mv	a1,s1
    800012f0:	8526                	mv	a0,s1
    800012f2:	00000097          	auipc	ra,0x0
    800012f6:	f24080e7          	jalr	-220(ra) # 80001216 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012fa:	46a9                	li	a3,10
    800012fc:	6605                	lui	a2,0x1
    800012fe:	00006597          	auipc	a1,0x6
    80001302:	d0258593          	addi	a1,a1,-766 # 80007000 <_trampoline>
    80001306:	04000537          	lui	a0,0x4000
    8000130a:	157d                	addi	a0,a0,-1
    8000130c:	0532                	slli	a0,a0,0xc
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	f08080e7          	jalr	-248(ra) # 80001216 <kvmmap>
}
    80001316:	60e2                	ld	ra,24(sp)
    80001318:	6442                	ld	s0,16(sp)
    8000131a:	64a2                	ld	s1,8(sp)
    8000131c:	6105                	addi	sp,sp,32
    8000131e:	8082                	ret

0000000080001320 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001320:	715d                	addi	sp,sp,-80
    80001322:	e486                	sd	ra,72(sp)
    80001324:	e0a2                	sd	s0,64(sp)
    80001326:	fc26                	sd	s1,56(sp)
    80001328:	f84a                	sd	s2,48(sp)
    8000132a:	f44e                	sd	s3,40(sp)
    8000132c:	f052                	sd	s4,32(sp)
    8000132e:	ec56                	sd	s5,24(sp)
    80001330:	e85a                	sd	s6,16(sp)
    80001332:	e45e                	sd	s7,8(sp)
    80001334:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001336:	03459793          	slli	a5,a1,0x34
    8000133a:	e795                	bnez	a5,80001366 <uvmunmap+0x46>
    8000133c:	8a2a                	mv	s4,a0
    8000133e:	892e                	mv	s2,a1
    80001340:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001342:	0632                	slli	a2,a2,0xc
    80001344:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001348:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134a:	6b05                	lui	s6,0x1
    8000134c:	0735e863          	bltu	a1,s3,800013bc <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001350:	60a6                	ld	ra,72(sp)
    80001352:	6406                	ld	s0,64(sp)
    80001354:	74e2                	ld	s1,56(sp)
    80001356:	7942                	ld	s2,48(sp)
    80001358:	79a2                	ld	s3,40(sp)
    8000135a:	7a02                	ld	s4,32(sp)
    8000135c:	6ae2                	ld	s5,24(sp)
    8000135e:	6b42                	ld	s6,16(sp)
    80001360:	6ba2                	ld	s7,8(sp)
    80001362:	6161                	addi	sp,sp,80
    80001364:	8082                	ret
    panic("uvmunmap: not aligned");
    80001366:	00007517          	auipc	a0,0x7
    8000136a:	d8a50513          	addi	a0,a0,-630 # 800080f0 <digits+0xb0>
    8000136e:	fffff097          	auipc	ra,0xfffff
    80001372:	1da080e7          	jalr	474(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001376:	00007517          	auipc	a0,0x7
    8000137a:	d9250513          	addi	a0,a0,-622 # 80008108 <digits+0xc8>
    8000137e:	fffff097          	auipc	ra,0xfffff
    80001382:	1ca080e7          	jalr	458(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001386:	00007517          	auipc	a0,0x7
    8000138a:	d9250513          	addi	a0,a0,-622 # 80008118 <digits+0xd8>
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	1ba080e7          	jalr	442(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	d9a50513          	addi	a0,a0,-614 # 80008130 <digits+0xf0>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	1aa080e7          	jalr	426(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800013a6:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013a8:	0532                	slli	a0,a0,0xc
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	67a080e7          	jalr	1658(ra) # 80000a24 <kfree>
    *pte = 0;
    800013b2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013b6:	995a                	add	s2,s2,s6
    800013b8:	f9397ce3          	bgeu	s2,s3,80001350 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013bc:	4601                	li	a2,0
    800013be:	85ca                	mv	a1,s2
    800013c0:	8552                	mv	a0,s4
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	c80080e7          	jalr	-896(ra) # 80001042 <walk>
    800013ca:	84aa                	mv	s1,a0
    800013cc:	d54d                	beqz	a0,80001376 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013ce:	6108                	ld	a0,0(a0)
    800013d0:	00157793          	andi	a5,a0,1
    800013d4:	dbcd                	beqz	a5,80001386 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013d6:	3ff57793          	andi	a5,a0,1023
    800013da:	fb778ee3          	beq	a5,s7,80001396 <uvmunmap+0x76>
    if(do_free){
    800013de:	fc0a8ae3          	beqz	s5,800013b2 <uvmunmap+0x92>
    800013e2:	b7d1                	j	800013a6 <uvmunmap+0x86>

00000000800013e4 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013ee:	fffff097          	auipc	ra,0xfffff
    800013f2:	732080e7          	jalr	1842(ra) # 80000b20 <kalloc>
    800013f6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013f8:	c519                	beqz	a0,80001406 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013fa:	6605                	lui	a2,0x1
    800013fc:	4581                	li	a1,0
    800013fe:	00000097          	auipc	ra,0x0
    80001402:	958080e7          	jalr	-1704(ra) # 80000d56 <memset>
  return pagetable;
}
    80001406:	8526                	mv	a0,s1
    80001408:	60e2                	ld	ra,24(sp)
    8000140a:	6442                	ld	s0,16(sp)
    8000140c:	64a2                	ld	s1,8(sp)
    8000140e:	6105                	addi	sp,sp,32
    80001410:	8082                	ret

0000000080001412 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001412:	7179                	addi	sp,sp,-48
    80001414:	f406                	sd	ra,40(sp)
    80001416:	f022                	sd	s0,32(sp)
    80001418:	ec26                	sd	s1,24(sp)
    8000141a:	e84a                	sd	s2,16(sp)
    8000141c:	e44e                	sd	s3,8(sp)
    8000141e:	e052                	sd	s4,0(sp)
    80001420:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001422:	6785                	lui	a5,0x1
    80001424:	04f67863          	bgeu	a2,a5,80001474 <uvminit+0x62>
    80001428:	8a2a                	mv	s4,a0
    8000142a:	89ae                	mv	s3,a1
    8000142c:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000142e:	fffff097          	auipc	ra,0xfffff
    80001432:	6f2080e7          	jalr	1778(ra) # 80000b20 <kalloc>
    80001436:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001438:	6605                	lui	a2,0x1
    8000143a:	4581                	li	a1,0
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	91a080e7          	jalr	-1766(ra) # 80000d56 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001444:	4779                	li	a4,30
    80001446:	86ca                	mv	a3,s2
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	8552                	mv	a0,s4
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	d3a080e7          	jalr	-710(ra) # 80001188 <mappages>
  memmove(mem, src, sz);
    80001456:	8626                	mv	a2,s1
    80001458:	85ce                	mv	a1,s3
    8000145a:	854a                	mv	a0,s2
    8000145c:	00000097          	auipc	ra,0x0
    80001460:	95a080e7          	jalr	-1702(ra) # 80000db6 <memmove>
}
    80001464:	70a2                	ld	ra,40(sp)
    80001466:	7402                	ld	s0,32(sp)
    80001468:	64e2                	ld	s1,24(sp)
    8000146a:	6942                	ld	s2,16(sp)
    8000146c:	69a2                	ld	s3,8(sp)
    8000146e:	6a02                	ld	s4,0(sp)
    80001470:	6145                	addi	sp,sp,48
    80001472:	8082                	ret
    panic("inituvm: more than a page");
    80001474:	00007517          	auipc	a0,0x7
    80001478:	cd450513          	addi	a0,a0,-812 # 80008148 <digits+0x108>
    8000147c:	fffff097          	auipc	ra,0xfffff
    80001480:	0cc080e7          	jalr	204(ra) # 80000548 <panic>

0000000080001484 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001484:	1101                	addi	sp,sp,-32
    80001486:	ec06                	sd	ra,24(sp)
    80001488:	e822                	sd	s0,16(sp)
    8000148a:	e426                	sd	s1,8(sp)
    8000148c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000148e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001490:	00b67d63          	bgeu	a2,a1,800014aa <uvmdealloc+0x26>
    80001494:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001496:	6785                	lui	a5,0x1
    80001498:	17fd                	addi	a5,a5,-1
    8000149a:	00f60733          	add	a4,a2,a5
    8000149e:	767d                	lui	a2,0xfffff
    800014a0:	8f71                	and	a4,a4,a2
    800014a2:	97ae                	add	a5,a5,a1
    800014a4:	8ff1                	and	a5,a5,a2
    800014a6:	00f76863          	bltu	a4,a5,800014b6 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014aa:	8526                	mv	a0,s1
    800014ac:	60e2                	ld	ra,24(sp)
    800014ae:	6442                	ld	s0,16(sp)
    800014b0:	64a2                	ld	s1,8(sp)
    800014b2:	6105                	addi	sp,sp,32
    800014b4:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014b6:	8f99                	sub	a5,a5,a4
    800014b8:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014ba:	4685                	li	a3,1
    800014bc:	0007861b          	sext.w	a2,a5
    800014c0:	85ba                	mv	a1,a4
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	e5e080e7          	jalr	-418(ra) # 80001320 <uvmunmap>
    800014ca:	b7c5                	j	800014aa <uvmdealloc+0x26>

00000000800014cc <uvmalloc>:
  if(newsz < oldsz)
    800014cc:	0ab66163          	bltu	a2,a1,8000156e <uvmalloc+0xa2>
{
    800014d0:	7139                	addi	sp,sp,-64
    800014d2:	fc06                	sd	ra,56(sp)
    800014d4:	f822                	sd	s0,48(sp)
    800014d6:	f426                	sd	s1,40(sp)
    800014d8:	f04a                	sd	s2,32(sp)
    800014da:	ec4e                	sd	s3,24(sp)
    800014dc:	e852                	sd	s4,16(sp)
    800014de:	e456                	sd	s5,8(sp)
    800014e0:	0080                	addi	s0,sp,64
    800014e2:	8aaa                	mv	s5,a0
    800014e4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014e6:	6985                	lui	s3,0x1
    800014e8:	19fd                	addi	s3,s3,-1
    800014ea:	95ce                	add	a1,a1,s3
    800014ec:	79fd                	lui	s3,0xfffff
    800014ee:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014f2:	08c9f063          	bgeu	s3,a2,80001572 <uvmalloc+0xa6>
    800014f6:	894e                	mv	s2,s3
    mem = kalloc();
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	628080e7          	jalr	1576(ra) # 80000b20 <kalloc>
    80001500:	84aa                	mv	s1,a0
    if(mem == 0){
    80001502:	c51d                	beqz	a0,80001530 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001504:	6605                	lui	a2,0x1
    80001506:	4581                	li	a1,0
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	84e080e7          	jalr	-1970(ra) # 80000d56 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001510:	4779                	li	a4,30
    80001512:	86a6                	mv	a3,s1
    80001514:	6605                	lui	a2,0x1
    80001516:	85ca                	mv	a1,s2
    80001518:	8556                	mv	a0,s5
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	c6e080e7          	jalr	-914(ra) # 80001188 <mappages>
    80001522:	e905                	bnez	a0,80001552 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001524:	6785                	lui	a5,0x1
    80001526:	993e                	add	s2,s2,a5
    80001528:	fd4968e3          	bltu	s2,s4,800014f8 <uvmalloc+0x2c>
  return newsz;
    8000152c:	8552                	mv	a0,s4
    8000152e:	a809                	j	80001540 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001530:	864e                	mv	a2,s3
    80001532:	85ca                	mv	a1,s2
    80001534:	8556                	mv	a0,s5
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	f4e080e7          	jalr	-178(ra) # 80001484 <uvmdealloc>
      return 0;
    8000153e:	4501                	li	a0,0
}
    80001540:	70e2                	ld	ra,56(sp)
    80001542:	7442                	ld	s0,48(sp)
    80001544:	74a2                	ld	s1,40(sp)
    80001546:	7902                	ld	s2,32(sp)
    80001548:	69e2                	ld	s3,24(sp)
    8000154a:	6a42                	ld	s4,16(sp)
    8000154c:	6aa2                	ld	s5,8(sp)
    8000154e:	6121                	addi	sp,sp,64
    80001550:	8082                	ret
      kfree(mem);
    80001552:	8526                	mv	a0,s1
    80001554:	fffff097          	auipc	ra,0xfffff
    80001558:	4d0080e7          	jalr	1232(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000155c:	864e                	mv	a2,s3
    8000155e:	85ca                	mv	a1,s2
    80001560:	8556                	mv	a0,s5
    80001562:	00000097          	auipc	ra,0x0
    80001566:	f22080e7          	jalr	-222(ra) # 80001484 <uvmdealloc>
      return 0;
    8000156a:	4501                	li	a0,0
    8000156c:	bfd1                	j	80001540 <uvmalloc+0x74>
    return oldsz;
    8000156e:	852e                	mv	a0,a1
}
    80001570:	8082                	ret
  return newsz;
    80001572:	8532                	mv	a0,a2
    80001574:	b7f1                	j	80001540 <uvmalloc+0x74>

0000000080001576 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001576:	7179                	addi	sp,sp,-48
    80001578:	f406                	sd	ra,40(sp)
    8000157a:	f022                	sd	s0,32(sp)
    8000157c:	ec26                	sd	s1,24(sp)
    8000157e:	e84a                	sd	s2,16(sp)
    80001580:	e44e                	sd	s3,8(sp)
    80001582:	e052                	sd	s4,0(sp)
    80001584:	1800                	addi	s0,sp,48
    80001586:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001588:	84aa                	mv	s1,a0
    8000158a:	6905                	lui	s2,0x1
    8000158c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000158e:	4985                	li	s3,1
    80001590:	a821                	j	800015a8 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001592:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001594:	0532                	slli	a0,a0,0xc
    80001596:	00000097          	auipc	ra,0x0
    8000159a:	fe0080e7          	jalr	-32(ra) # 80001576 <freewalk>
      pagetable[i] = 0;
    8000159e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015a2:	04a1                	addi	s1,s1,8
    800015a4:	03248163          	beq	s1,s2,800015c6 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015a8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015aa:	00f57793          	andi	a5,a0,15
    800015ae:	ff3782e3          	beq	a5,s3,80001592 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015b2:	8905                	andi	a0,a0,1
    800015b4:	d57d                	beqz	a0,800015a2 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015b6:	00007517          	auipc	a0,0x7
    800015ba:	bb250513          	addi	a0,a0,-1102 # 80008168 <digits+0x128>
    800015be:	fffff097          	auipc	ra,0xfffff
    800015c2:	f8a080e7          	jalr	-118(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015c6:	8552                	mv	a0,s4
    800015c8:	fffff097          	auipc	ra,0xfffff
    800015cc:	45c080e7          	jalr	1116(ra) # 80000a24 <kfree>
}
    800015d0:	70a2                	ld	ra,40(sp)
    800015d2:	7402                	ld	s0,32(sp)
    800015d4:	64e2                	ld	s1,24(sp)
    800015d6:	6942                	ld	s2,16(sp)
    800015d8:	69a2                	ld	s3,8(sp)
    800015da:	6a02                	ld	s4,0(sp)
    800015dc:	6145                	addi	sp,sp,48
    800015de:	8082                	ret

00000000800015e0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015e0:	1101                	addi	sp,sp,-32
    800015e2:	ec06                	sd	ra,24(sp)
    800015e4:	e822                	sd	s0,16(sp)
    800015e6:	e426                	sd	s1,8(sp)
    800015e8:	1000                	addi	s0,sp,32
    800015ea:	84aa                	mv	s1,a0
  if(sz > 0)
    800015ec:	e999                	bnez	a1,80001602 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015ee:	8526                	mv	a0,s1
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	f86080e7          	jalr	-122(ra) # 80001576 <freewalk>
}
    800015f8:	60e2                	ld	ra,24(sp)
    800015fa:	6442                	ld	s0,16(sp)
    800015fc:	64a2                	ld	s1,8(sp)
    800015fe:	6105                	addi	sp,sp,32
    80001600:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001602:	6605                	lui	a2,0x1
    80001604:	167d                	addi	a2,a2,-1
    80001606:	962e                	add	a2,a2,a1
    80001608:	4685                	li	a3,1
    8000160a:	8231                	srli	a2,a2,0xc
    8000160c:	4581                	li	a1,0
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	d12080e7          	jalr	-750(ra) # 80001320 <uvmunmap>
    80001616:	bfe1                	j	800015ee <uvmfree+0xe>

0000000080001618 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001618:	c679                	beqz	a2,800016e6 <uvmcopy+0xce>
{
    8000161a:	715d                	addi	sp,sp,-80
    8000161c:	e486                	sd	ra,72(sp)
    8000161e:	e0a2                	sd	s0,64(sp)
    80001620:	fc26                	sd	s1,56(sp)
    80001622:	f84a                	sd	s2,48(sp)
    80001624:	f44e                	sd	s3,40(sp)
    80001626:	f052                	sd	s4,32(sp)
    80001628:	ec56                	sd	s5,24(sp)
    8000162a:	e85a                	sd	s6,16(sp)
    8000162c:	e45e                	sd	s7,8(sp)
    8000162e:	0880                	addi	s0,sp,80
    80001630:	8b2a                	mv	s6,a0
    80001632:	8aae                	mv	s5,a1
    80001634:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001636:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001638:	4601                	li	a2,0
    8000163a:	85ce                	mv	a1,s3
    8000163c:	855a                	mv	a0,s6
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	a04080e7          	jalr	-1532(ra) # 80001042 <walk>
    80001646:	c531                	beqz	a0,80001692 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001648:	6118                	ld	a4,0(a0)
    8000164a:	00177793          	andi	a5,a4,1
    8000164e:	cbb1                	beqz	a5,800016a2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001650:	00a75593          	srli	a1,a4,0xa
    80001654:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001658:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000165c:	fffff097          	auipc	ra,0xfffff
    80001660:	4c4080e7          	jalr	1220(ra) # 80000b20 <kalloc>
    80001664:	892a                	mv	s2,a0
    80001666:	c939                	beqz	a0,800016bc <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001668:	6605                	lui	a2,0x1
    8000166a:	85de                	mv	a1,s7
    8000166c:	fffff097          	auipc	ra,0xfffff
    80001670:	74a080e7          	jalr	1866(ra) # 80000db6 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001674:	8726                	mv	a4,s1
    80001676:	86ca                	mv	a3,s2
    80001678:	6605                	lui	a2,0x1
    8000167a:	85ce                	mv	a1,s3
    8000167c:	8556                	mv	a0,s5
    8000167e:	00000097          	auipc	ra,0x0
    80001682:	b0a080e7          	jalr	-1270(ra) # 80001188 <mappages>
    80001686:	e515                	bnez	a0,800016b2 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001688:	6785                	lui	a5,0x1
    8000168a:	99be                	add	s3,s3,a5
    8000168c:	fb49e6e3          	bltu	s3,s4,80001638 <uvmcopy+0x20>
    80001690:	a081                	j	800016d0 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001692:	00007517          	auipc	a0,0x7
    80001696:	ae650513          	addi	a0,a0,-1306 # 80008178 <digits+0x138>
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	eae080e7          	jalr	-338(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800016a2:	00007517          	auipc	a0,0x7
    800016a6:	af650513          	addi	a0,a0,-1290 # 80008198 <digits+0x158>
    800016aa:	fffff097          	auipc	ra,0xfffff
    800016ae:	e9e080e7          	jalr	-354(ra) # 80000548 <panic>
      kfree(mem);
    800016b2:	854a                	mv	a0,s2
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	370080e7          	jalr	880(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016bc:	4685                	li	a3,1
    800016be:	00c9d613          	srli	a2,s3,0xc
    800016c2:	4581                	li	a1,0
    800016c4:	8556                	mv	a0,s5
    800016c6:	00000097          	auipc	ra,0x0
    800016ca:	c5a080e7          	jalr	-934(ra) # 80001320 <uvmunmap>
  return -1;
    800016ce:	557d                	li	a0,-1
}
    800016d0:	60a6                	ld	ra,72(sp)
    800016d2:	6406                	ld	s0,64(sp)
    800016d4:	74e2                	ld	s1,56(sp)
    800016d6:	7942                	ld	s2,48(sp)
    800016d8:	79a2                	ld	s3,40(sp)
    800016da:	7a02                	ld	s4,32(sp)
    800016dc:	6ae2                	ld	s5,24(sp)
    800016de:	6b42                	ld	s6,16(sp)
    800016e0:	6ba2                	ld	s7,8(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret
  return 0;
    800016e6:	4501                	li	a0,0
}
    800016e8:	8082                	ret

00000000800016ea <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016ea:	1141                	addi	sp,sp,-16
    800016ec:	e406                	sd	ra,8(sp)
    800016ee:	e022                	sd	s0,0(sp)
    800016f0:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016f2:	4601                	li	a2,0
    800016f4:	00000097          	auipc	ra,0x0
    800016f8:	94e080e7          	jalr	-1714(ra) # 80001042 <walk>
  if(pte == 0)
    800016fc:	c901                	beqz	a0,8000170c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016fe:	611c                	ld	a5,0(a0)
    80001700:	9bbd                	andi	a5,a5,-17
    80001702:	e11c                	sd	a5,0(a0)
}
    80001704:	60a2                	ld	ra,8(sp)
    80001706:	6402                	ld	s0,0(sp)
    80001708:	0141                	addi	sp,sp,16
    8000170a:	8082                	ret
    panic("uvmclear");
    8000170c:	00007517          	auipc	a0,0x7
    80001710:	aac50513          	addi	a0,a0,-1364 # 800081b8 <digits+0x178>
    80001714:	fffff097          	auipc	ra,0xfffff
    80001718:	e34080e7          	jalr	-460(ra) # 80000548 <panic>

000000008000171c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000171c:	c6bd                	beqz	a3,8000178a <copyout+0x6e>
{
    8000171e:	715d                	addi	sp,sp,-80
    80001720:	e486                	sd	ra,72(sp)
    80001722:	e0a2                	sd	s0,64(sp)
    80001724:	fc26                	sd	s1,56(sp)
    80001726:	f84a                	sd	s2,48(sp)
    80001728:	f44e                	sd	s3,40(sp)
    8000172a:	f052                	sd	s4,32(sp)
    8000172c:	ec56                	sd	s5,24(sp)
    8000172e:	e85a                	sd	s6,16(sp)
    80001730:	e45e                	sd	s7,8(sp)
    80001732:	e062                	sd	s8,0(sp)
    80001734:	0880                	addi	s0,sp,80
    80001736:	8b2a                	mv	s6,a0
    80001738:	8c2e                	mv	s8,a1
    8000173a:	8a32                	mv	s4,a2
    8000173c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000173e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001740:	6a85                	lui	s5,0x1
    80001742:	a015                	j	80001766 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001744:	9562                	add	a0,a0,s8
    80001746:	0004861b          	sext.w	a2,s1
    8000174a:	85d2                	mv	a1,s4
    8000174c:	41250533          	sub	a0,a0,s2
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	666080e7          	jalr	1638(ra) # 80000db6 <memmove>

    len -= n;
    80001758:	409989b3          	sub	s3,s3,s1
    src += n;
    8000175c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000175e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001762:	02098263          	beqz	s3,80001786 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001766:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000176a:	85ca                	mv	a1,s2
    8000176c:	855a                	mv	a0,s6
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	97a080e7          	jalr	-1670(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001776:	cd01                	beqz	a0,8000178e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001778:	418904b3          	sub	s1,s2,s8
    8000177c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000177e:	fc99f3e3          	bgeu	s3,s1,80001744 <copyout+0x28>
    80001782:	84ce                	mv	s1,s3
    80001784:	b7c1                	j	80001744 <copyout+0x28>
  }
  return 0;
    80001786:	4501                	li	a0,0
    80001788:	a021                	j	80001790 <copyout+0x74>
    8000178a:	4501                	li	a0,0
}
    8000178c:	8082                	ret
      return -1;
    8000178e:	557d                	li	a0,-1
}
    80001790:	60a6                	ld	ra,72(sp)
    80001792:	6406                	ld	s0,64(sp)
    80001794:	74e2                	ld	s1,56(sp)
    80001796:	7942                	ld	s2,48(sp)
    80001798:	79a2                	ld	s3,40(sp)
    8000179a:	7a02                	ld	s4,32(sp)
    8000179c:	6ae2                	ld	s5,24(sp)
    8000179e:	6b42                	ld	s6,16(sp)
    800017a0:	6ba2                	ld	s7,8(sp)
    800017a2:	6c02                	ld	s8,0(sp)
    800017a4:	6161                	addi	sp,sp,80
    800017a6:	8082                	ret

00000000800017a8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017a8:	c6bd                	beqz	a3,80001816 <copyin+0x6e>
{
    800017aa:	715d                	addi	sp,sp,-80
    800017ac:	e486                	sd	ra,72(sp)
    800017ae:	e0a2                	sd	s0,64(sp)
    800017b0:	fc26                	sd	s1,56(sp)
    800017b2:	f84a                	sd	s2,48(sp)
    800017b4:	f44e                	sd	s3,40(sp)
    800017b6:	f052                	sd	s4,32(sp)
    800017b8:	ec56                	sd	s5,24(sp)
    800017ba:	e85a                	sd	s6,16(sp)
    800017bc:	e45e                	sd	s7,8(sp)
    800017be:	e062                	sd	s8,0(sp)
    800017c0:	0880                	addi	s0,sp,80
    800017c2:	8b2a                	mv	s6,a0
    800017c4:	8a2e                	mv	s4,a1
    800017c6:	8c32                	mv	s8,a2
    800017c8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017ca:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017cc:	6a85                	lui	s5,0x1
    800017ce:	a015                	j	800017f2 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017d0:	9562                	add	a0,a0,s8
    800017d2:	0004861b          	sext.w	a2,s1
    800017d6:	412505b3          	sub	a1,a0,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	fffff097          	auipc	ra,0xfffff
    800017e0:	5da080e7          	jalr	1498(ra) # 80000db6 <memmove>

    len -= n;
    800017e4:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017e8:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017ea:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017ee:	02098263          	beqz	s3,80001812 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017f2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017f6:	85ca                	mv	a1,s2
    800017f8:	855a                	mv	a0,s6
    800017fa:	00000097          	auipc	ra,0x0
    800017fe:	8ee080e7          	jalr	-1810(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001802:	cd01                	beqz	a0,8000181a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001804:	418904b3          	sub	s1,s2,s8
    80001808:	94d6                	add	s1,s1,s5
    if(n > len)
    8000180a:	fc99f3e3          	bgeu	s3,s1,800017d0 <copyin+0x28>
    8000180e:	84ce                	mv	s1,s3
    80001810:	b7c1                	j	800017d0 <copyin+0x28>
  }
  return 0;
    80001812:	4501                	li	a0,0
    80001814:	a021                	j	8000181c <copyin+0x74>
    80001816:	4501                	li	a0,0
}
    80001818:	8082                	ret
      return -1;
    8000181a:	557d                	li	a0,-1
}
    8000181c:	60a6                	ld	ra,72(sp)
    8000181e:	6406                	ld	s0,64(sp)
    80001820:	74e2                	ld	s1,56(sp)
    80001822:	7942                	ld	s2,48(sp)
    80001824:	79a2                	ld	s3,40(sp)
    80001826:	7a02                	ld	s4,32(sp)
    80001828:	6ae2                	ld	s5,24(sp)
    8000182a:	6b42                	ld	s6,16(sp)
    8000182c:	6ba2                	ld	s7,8(sp)
    8000182e:	6c02                	ld	s8,0(sp)
    80001830:	6161                	addi	sp,sp,80
    80001832:	8082                	ret

0000000080001834 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001834:	c6c5                	beqz	a3,800018dc <copyinstr+0xa8>
{
    80001836:	715d                	addi	sp,sp,-80
    80001838:	e486                	sd	ra,72(sp)
    8000183a:	e0a2                	sd	s0,64(sp)
    8000183c:	fc26                	sd	s1,56(sp)
    8000183e:	f84a                	sd	s2,48(sp)
    80001840:	f44e                	sd	s3,40(sp)
    80001842:	f052                	sd	s4,32(sp)
    80001844:	ec56                	sd	s5,24(sp)
    80001846:	e85a                	sd	s6,16(sp)
    80001848:	e45e                	sd	s7,8(sp)
    8000184a:	0880                	addi	s0,sp,80
    8000184c:	8a2a                	mv	s4,a0
    8000184e:	8b2e                	mv	s6,a1
    80001850:	8bb2                	mv	s7,a2
    80001852:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001854:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001856:	6985                	lui	s3,0x1
    80001858:	a035                	j	80001884 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000185a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000185e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001860:	0017b793          	seqz	a5,a5
    80001864:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001868:	60a6                	ld	ra,72(sp)
    8000186a:	6406                	ld	s0,64(sp)
    8000186c:	74e2                	ld	s1,56(sp)
    8000186e:	7942                	ld	s2,48(sp)
    80001870:	79a2                	ld	s3,40(sp)
    80001872:	7a02                	ld	s4,32(sp)
    80001874:	6ae2                	ld	s5,24(sp)
    80001876:	6b42                	ld	s6,16(sp)
    80001878:	6ba2                	ld	s7,8(sp)
    8000187a:	6161                	addi	sp,sp,80
    8000187c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000187e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001882:	c8a9                	beqz	s1,800018d4 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001884:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001888:	85ca                	mv	a1,s2
    8000188a:	8552                	mv	a0,s4
    8000188c:	00000097          	auipc	ra,0x0
    80001890:	85c080e7          	jalr	-1956(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001894:	c131                	beqz	a0,800018d8 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001896:	41790833          	sub	a6,s2,s7
    8000189a:	984e                	add	a6,a6,s3
    if(n > max)
    8000189c:	0104f363          	bgeu	s1,a6,800018a2 <copyinstr+0x6e>
    800018a0:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018a2:	955e                	add	a0,a0,s7
    800018a4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018a8:	fc080be3          	beqz	a6,8000187e <copyinstr+0x4a>
    800018ac:	985a                	add	a6,a6,s6
    800018ae:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018b0:	41650633          	sub	a2,a0,s6
    800018b4:	14fd                	addi	s1,s1,-1
    800018b6:	9b26                	add	s6,s6,s1
    800018b8:	00f60733          	add	a4,a2,a5
    800018bc:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018c0:	df49                	beqz	a4,8000185a <copyinstr+0x26>
        *dst = *p;
    800018c2:	00e78023          	sb	a4,0(a5)
      --max;
    800018c6:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018ca:	0785                	addi	a5,a5,1
    while(n > 0){
    800018cc:	ff0796e3          	bne	a5,a6,800018b8 <copyinstr+0x84>
      dst++;
    800018d0:	8b42                	mv	s6,a6
    800018d2:	b775                	j	8000187e <copyinstr+0x4a>
    800018d4:	4781                	li	a5,0
    800018d6:	b769                	j	80001860 <copyinstr+0x2c>
      return -1;
    800018d8:	557d                	li	a0,-1
    800018da:	b779                	j	80001868 <copyinstr+0x34>
  int got_null = 0;
    800018dc:	4781                	li	a5,0
  if(got_null){
    800018de:	0017b793          	seqz	a5,a5
    800018e2:	40f00533          	neg	a0,a5
}
    800018e6:	8082                	ret

00000000800018e8 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018e8:	1101                	addi	sp,sp,-32
    800018ea:	ec06                	sd	ra,24(sp)
    800018ec:	e822                	sd	s0,16(sp)
    800018ee:	e426                	sd	s1,8(sp)
    800018f0:	1000                	addi	s0,sp,32
    800018f2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	2ec080e7          	jalr	748(ra) # 80000be0 <holding>
    800018fc:	c909                	beqz	a0,8000190e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018fe:	749c                	ld	a5,40(s1)
    80001900:	00978f63          	beq	a5,s1,8000191e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001904:	60e2                	ld	ra,24(sp)
    80001906:	6442                	ld	s0,16(sp)
    80001908:	64a2                	ld	s1,8(sp)
    8000190a:	6105                	addi	sp,sp,32
    8000190c:	8082                	ret
    panic("wakeup1");
    8000190e:	00007517          	auipc	a0,0x7
    80001912:	8ba50513          	addi	a0,a0,-1862 # 800081c8 <digits+0x188>
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	c32080e7          	jalr	-974(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000191e:	4c98                	lw	a4,24(s1)
    80001920:	4785                	li	a5,1
    80001922:	fef711e3          	bne	a4,a5,80001904 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001926:	4789                	li	a5,2
    80001928:	cc9c                	sw	a5,24(s1)
}
    8000192a:	bfe9                	j	80001904 <wakeup1+0x1c>

000000008000192c <procinit>:
{
    8000192c:	715d                	addi	sp,sp,-80
    8000192e:	e486                	sd	ra,72(sp)
    80001930:	e0a2                	sd	s0,64(sp)
    80001932:	fc26                	sd	s1,56(sp)
    80001934:	f84a                	sd	s2,48(sp)
    80001936:	f44e                	sd	s3,40(sp)
    80001938:	f052                	sd	s4,32(sp)
    8000193a:	ec56                	sd	s5,24(sp)
    8000193c:	e85a                	sd	s6,16(sp)
    8000193e:	e45e                	sd	s7,8(sp)
    80001940:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001942:	00007597          	auipc	a1,0x7
    80001946:	88e58593          	addi	a1,a1,-1906 # 800081d0 <digits+0x190>
    8000194a:	00010517          	auipc	a0,0x10
    8000194e:	00650513          	addi	a0,a0,6 # 80011950 <pid_lock>
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	278080e7          	jalr	632(ra) # 80000bca <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195a:	00010917          	auipc	s2,0x10
    8000195e:	40e90913          	addi	s2,s2,1038 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001962:	00007b97          	auipc	s7,0x7
    80001966:	876b8b93          	addi	s7,s7,-1930 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    8000196a:	8b4a                	mv	s6,s2
    8000196c:	00006a97          	auipc	s5,0x6
    80001970:	694a8a93          	addi	s5,s5,1684 # 80008000 <etext>
    80001974:	040009b7          	lui	s3,0x4000
    80001978:	19fd                	addi	s3,s3,-1
    8000197a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	00016a17          	auipc	s4,0x16
    80001980:	feca0a13          	addi	s4,s4,-20 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    80001984:	85de                	mv	a1,s7
    80001986:	854a                	mv	a0,s2
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	242080e7          	jalr	578(ra) # 80000bca <initlock>
      char *pa = kalloc();
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	190080e7          	jalr	400(ra) # 80000b20 <kalloc>
    80001998:	85aa                	mv	a1,a0
      if(pa == 0)
    8000199a:	c929                	beqz	a0,800019ec <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000199c:	416904b3          	sub	s1,s2,s6
    800019a0:	8491                	srai	s1,s1,0x4
    800019a2:	000ab783          	ld	a5,0(s5)
    800019a6:	02f484b3          	mul	s1,s1,a5
    800019aa:	2485                	addiw	s1,s1,1
    800019ac:	00d4949b          	slliw	s1,s1,0xd
    800019b0:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019b4:	4699                	li	a3,6
    800019b6:	6605                	lui	a2,0x1
    800019b8:	8526                	mv	a0,s1
    800019ba:	00000097          	auipc	ra,0x0
    800019be:	85c080e7          	jalr	-1956(ra) # 80001216 <kvmmap>
      p->kstack = va;
    800019c2:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c6:	17090913          	addi	s2,s2,368
    800019ca:	fb491de3          	bne	s2,s4,80001984 <procinit+0x58>
  kvminithart();
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	650080e7          	jalr	1616(ra) # 8000101e <kvminithart>
}
    800019d6:	60a6                	ld	ra,72(sp)
    800019d8:	6406                	ld	s0,64(sp)
    800019da:	74e2                	ld	s1,56(sp)
    800019dc:	7942                	ld	s2,48(sp)
    800019de:	79a2                	ld	s3,40(sp)
    800019e0:	7a02                	ld	s4,32(sp)
    800019e2:	6ae2                	ld	s5,24(sp)
    800019e4:	6b42                	ld	s6,16(sp)
    800019e6:	6ba2                	ld	s7,8(sp)
    800019e8:	6161                	addi	sp,sp,80
    800019ea:	8082                	ret
        panic("kalloc");
    800019ec:	00006517          	auipc	a0,0x6
    800019f0:	7f450513          	addi	a0,a0,2036 # 800081e0 <digits+0x1a0>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	b54080e7          	jalr	-1196(ra) # 80000548 <panic>

00000000800019fc <cpuid>:
{
    800019fc:	1141                	addi	sp,sp,-16
    800019fe:	e422                	sd	s0,8(sp)
    80001a00:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a02:	8512                	mv	a0,tp
}
    80001a04:	2501                	sext.w	a0,a0
    80001a06:	6422                	ld	s0,8(sp)
    80001a08:	0141                	addi	sp,sp,16
    80001a0a:	8082                	ret

0000000080001a0c <mycpu>:
mycpu(void) {
    80001a0c:	1141                	addi	sp,sp,-16
    80001a0e:	e422                	sd	s0,8(sp)
    80001a10:	0800                	addi	s0,sp,16
    80001a12:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a14:	2781                	sext.w	a5,a5
    80001a16:	079e                	slli	a5,a5,0x7
}
    80001a18:	00010517          	auipc	a0,0x10
    80001a1c:	f5050513          	addi	a0,a0,-176 # 80011968 <cpus>
    80001a20:	953e                	add	a0,a0,a5
    80001a22:	6422                	ld	s0,8(sp)
    80001a24:	0141                	addi	sp,sp,16
    80001a26:	8082                	ret

0000000080001a28 <myproc>:
myproc(void) {
    80001a28:	1101                	addi	sp,sp,-32
    80001a2a:	ec06                	sd	ra,24(sp)
    80001a2c:	e822                	sd	s0,16(sp)
    80001a2e:	e426                	sd	s1,8(sp)
    80001a30:	1000                	addi	s0,sp,32
  push_off();
    80001a32:	fffff097          	auipc	ra,0xfffff
    80001a36:	1dc080e7          	jalr	476(ra) # 80000c0e <push_off>
    80001a3a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a3c:	2781                	sext.w	a5,a5
    80001a3e:	079e                	slli	a5,a5,0x7
    80001a40:	00010717          	auipc	a4,0x10
    80001a44:	f1070713          	addi	a4,a4,-240 # 80011950 <pid_lock>
    80001a48:	97ba                	add	a5,a5,a4
    80001a4a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	262080e7          	jalr	610(ra) # 80000cae <pop_off>
}
    80001a54:	8526                	mv	a0,s1
    80001a56:	60e2                	ld	ra,24(sp)
    80001a58:	6442                	ld	s0,16(sp)
    80001a5a:	64a2                	ld	s1,8(sp)
    80001a5c:	6105                	addi	sp,sp,32
    80001a5e:	8082                	ret

0000000080001a60 <forkret>:
{
    80001a60:	1141                	addi	sp,sp,-16
    80001a62:	e406                	sd	ra,8(sp)
    80001a64:	e022                	sd	s0,0(sp)
    80001a66:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	fc0080e7          	jalr	-64(ra) # 80001a28 <myproc>
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	29e080e7          	jalr	670(ra) # 80000d0e <release>
  if (first) {
    80001a78:	00007797          	auipc	a5,0x7
    80001a7c:	f287a783          	lw	a5,-216(a5) # 800089a0 <first.1667>
    80001a80:	eb89                	bnez	a5,80001a92 <forkret+0x32>
  usertrapret();
    80001a82:	00001097          	auipc	ra,0x1
    80001a86:	c78080e7          	jalr	-904(ra) # 800026fa <usertrapret>
}
    80001a8a:	60a2                	ld	ra,8(sp)
    80001a8c:	6402                	ld	s0,0(sp)
    80001a8e:	0141                	addi	sp,sp,16
    80001a90:	8082                	ret
    first = 0;
    80001a92:	00007797          	auipc	a5,0x7
    80001a96:	f007a723          	sw	zero,-242(a5) # 800089a0 <first.1667>
    fsinit(ROOTDEV);
    80001a9a:	4505                	li	a0,1
    80001a9c:	00002097          	auipc	ra,0x2
    80001aa0:	a7c080e7          	jalr	-1412(ra) # 80003518 <fsinit>
    80001aa4:	bff9                	j	80001a82 <forkret+0x22>

0000000080001aa6 <allocpid>:
allocpid() {
    80001aa6:	1101                	addi	sp,sp,-32
    80001aa8:	ec06                	sd	ra,24(sp)
    80001aaa:	e822                	sd	s0,16(sp)
    80001aac:	e426                	sd	s1,8(sp)
    80001aae:	e04a                	sd	s2,0(sp)
    80001ab0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ab2:	00010917          	auipc	s2,0x10
    80001ab6:	e9e90913          	addi	s2,s2,-354 # 80011950 <pid_lock>
    80001aba:	854a                	mv	a0,s2
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	19e080e7          	jalr	414(ra) # 80000c5a <acquire>
  pid = nextpid;
    80001ac4:	00007797          	auipc	a5,0x7
    80001ac8:	ee078793          	addi	a5,a5,-288 # 800089a4 <nextpid>
    80001acc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ace:	0014871b          	addiw	a4,s1,1
    80001ad2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad4:	854a                	mv	a0,s2
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	238080e7          	jalr	568(ra) # 80000d0e <release>
}
    80001ade:	8526                	mv	a0,s1
    80001ae0:	60e2                	ld	ra,24(sp)
    80001ae2:	6442                	ld	s0,16(sp)
    80001ae4:	64a2                	ld	s1,8(sp)
    80001ae6:	6902                	ld	s2,0(sp)
    80001ae8:	6105                	addi	sp,sp,32
    80001aea:	8082                	ret

0000000080001aec <proc_pagetable>:
{
    80001aec:	1101                	addi	sp,sp,-32
    80001aee:	ec06                	sd	ra,24(sp)
    80001af0:	e822                	sd	s0,16(sp)
    80001af2:	e426                	sd	s1,8(sp)
    80001af4:	e04a                	sd	s2,0(sp)
    80001af6:	1000                	addi	s0,sp,32
    80001af8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	8ea080e7          	jalr	-1814(ra) # 800013e4 <uvmcreate>
    80001b02:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b04:	c121                	beqz	a0,80001b44 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b06:	4729                	li	a4,10
    80001b08:	00005697          	auipc	a3,0x5
    80001b0c:	4f868693          	addi	a3,a3,1272 # 80007000 <_trampoline>
    80001b10:	6605                	lui	a2,0x1
    80001b12:	040005b7          	lui	a1,0x4000
    80001b16:	15fd                	addi	a1,a1,-1
    80001b18:	05b2                	slli	a1,a1,0xc
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	66e080e7          	jalr	1646(ra) # 80001188 <mappages>
    80001b22:	02054863          	bltz	a0,80001b52 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b26:	4719                	li	a4,6
    80001b28:	05893683          	ld	a3,88(s2)
    80001b2c:	6605                	lui	a2,0x1
    80001b2e:	020005b7          	lui	a1,0x2000
    80001b32:	15fd                	addi	a1,a1,-1
    80001b34:	05b6                	slli	a1,a1,0xd
    80001b36:	8526                	mv	a0,s1
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	650080e7          	jalr	1616(ra) # 80001188 <mappages>
    80001b40:	02054163          	bltz	a0,80001b62 <proc_pagetable+0x76>
}
    80001b44:	8526                	mv	a0,s1
    80001b46:	60e2                	ld	ra,24(sp)
    80001b48:	6442                	ld	s0,16(sp)
    80001b4a:	64a2                	ld	s1,8(sp)
    80001b4c:	6902                	ld	s2,0(sp)
    80001b4e:	6105                	addi	sp,sp,32
    80001b50:	8082                	ret
    uvmfree(pagetable, 0);
    80001b52:	4581                	li	a1,0
    80001b54:	8526                	mv	a0,s1
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	a8a080e7          	jalr	-1398(ra) # 800015e0 <uvmfree>
    return 0;
    80001b5e:	4481                	li	s1,0
    80001b60:	b7d5                	j	80001b44 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b62:	4681                	li	a3,0
    80001b64:	4605                	li	a2,1
    80001b66:	040005b7          	lui	a1,0x4000
    80001b6a:	15fd                	addi	a1,a1,-1
    80001b6c:	05b2                	slli	a1,a1,0xc
    80001b6e:	8526                	mv	a0,s1
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	7b0080e7          	jalr	1968(ra) # 80001320 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b78:	4581                	li	a1,0
    80001b7a:	8526                	mv	a0,s1
    80001b7c:	00000097          	auipc	ra,0x0
    80001b80:	a64080e7          	jalr	-1436(ra) # 800015e0 <uvmfree>
    return 0;
    80001b84:	4481                	li	s1,0
    80001b86:	bf7d                	j	80001b44 <proc_pagetable+0x58>

0000000080001b88 <proc_freepagetable>:
{
    80001b88:	1101                	addi	sp,sp,-32
    80001b8a:	ec06                	sd	ra,24(sp)
    80001b8c:	e822                	sd	s0,16(sp)
    80001b8e:	e426                	sd	s1,8(sp)
    80001b90:	e04a                	sd	s2,0(sp)
    80001b92:	1000                	addi	s0,sp,32
    80001b94:	84aa                	mv	s1,a0
    80001b96:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b98:	4681                	li	a3,0
    80001b9a:	4605                	li	a2,1
    80001b9c:	040005b7          	lui	a1,0x4000
    80001ba0:	15fd                	addi	a1,a1,-1
    80001ba2:	05b2                	slli	a1,a1,0xc
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	77c080e7          	jalr	1916(ra) # 80001320 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bac:	4681                	li	a3,0
    80001bae:	4605                	li	a2,1
    80001bb0:	020005b7          	lui	a1,0x2000
    80001bb4:	15fd                	addi	a1,a1,-1
    80001bb6:	05b6                	slli	a1,a1,0xd
    80001bb8:	8526                	mv	a0,s1
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	766080e7          	jalr	1894(ra) # 80001320 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc2:	85ca                	mv	a1,s2
    80001bc4:	8526                	mv	a0,s1
    80001bc6:	00000097          	auipc	ra,0x0
    80001bca:	a1a080e7          	jalr	-1510(ra) # 800015e0 <uvmfree>
}
    80001bce:	60e2                	ld	ra,24(sp)
    80001bd0:	6442                	ld	s0,16(sp)
    80001bd2:	64a2                	ld	s1,8(sp)
    80001bd4:	6902                	ld	s2,0(sp)
    80001bd6:	6105                	addi	sp,sp,32
    80001bd8:	8082                	ret

0000000080001bda <freeproc>:
{
    80001bda:	1101                	addi	sp,sp,-32
    80001bdc:	ec06                	sd	ra,24(sp)
    80001bde:	e822                	sd	s0,16(sp)
    80001be0:	e426                	sd	s1,8(sp)
    80001be2:	1000                	addi	s0,sp,32
    80001be4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001be6:	6d28                	ld	a0,88(a0)
    80001be8:	c509                	beqz	a0,80001bf2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	e3a080e7          	jalr	-454(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001bf2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bf6:	68a8                	ld	a0,80(s1)
    80001bf8:	c511                	beqz	a0,80001c04 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bfa:	64ac                	ld	a1,72(s1)
    80001bfc:	00000097          	auipc	ra,0x0
    80001c00:	f8c080e7          	jalr	-116(ra) # 80001b88 <proc_freepagetable>
  p->pagetable = 0;
    80001c04:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c08:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c0c:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c10:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c14:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c18:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c1c:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c20:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c24:	0004ac23          	sw	zero,24(s1)
}
    80001c28:	60e2                	ld	ra,24(sp)
    80001c2a:	6442                	ld	s0,16(sp)
    80001c2c:	64a2                	ld	s1,8(sp)
    80001c2e:	6105                	addi	sp,sp,32
    80001c30:	8082                	ret

0000000080001c32 <allocproc>:
{
    80001c32:	1101                	addi	sp,sp,-32
    80001c34:	ec06                	sd	ra,24(sp)
    80001c36:	e822                	sd	s0,16(sp)
    80001c38:	e426                	sd	s1,8(sp)
    80001c3a:	e04a                	sd	s2,0(sp)
    80001c3c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c3e:	00010497          	auipc	s1,0x10
    80001c42:	12a48493          	addi	s1,s1,298 # 80011d68 <proc>
    80001c46:	00016917          	auipc	s2,0x16
    80001c4a:	d2290913          	addi	s2,s2,-734 # 80017968 <tickslock>
    acquire(&p->lock);
    80001c4e:	8526                	mv	a0,s1
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	00a080e7          	jalr	10(ra) # 80000c5a <acquire>
    if(p->state == UNUSED) {
    80001c58:	4c9c                	lw	a5,24(s1)
    80001c5a:	cf81                	beqz	a5,80001c72 <allocproc+0x40>
      release(&p->lock);
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	0b0080e7          	jalr	176(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c66:	17048493          	addi	s1,s1,368
    80001c6a:	ff2492e3          	bne	s1,s2,80001c4e <allocproc+0x1c>
  return 0;
    80001c6e:	4481                	li	s1,0
    80001c70:	a889                	j	80001cc2 <allocproc+0x90>
  p->pid = allocpid();
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	e34080e7          	jalr	-460(ra) # 80001aa6 <allocpid>
    80001c7a:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	ea4080e7          	jalr	-348(ra) # 80000b20 <kalloc>
    80001c84:	892a                	mv	s2,a0
    80001c86:	eca8                	sd	a0,88(s1)
    80001c88:	c521                	beqz	a0,80001cd0 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	e60080e7          	jalr	-416(ra) # 80001aec <proc_pagetable>
    80001c94:	892a                	mv	s2,a0
    80001c96:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c98:	c139                	beqz	a0,80001cde <allocproc+0xac>
  memset(&p->context, 0, sizeof(p->context));
    80001c9a:	07000613          	li	a2,112
    80001c9e:	4581                	li	a1,0
    80001ca0:	06048513          	addi	a0,s1,96
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	0b2080e7          	jalr	178(ra) # 80000d56 <memset>
  p->context.ra = (uint64)forkret;
    80001cac:	00000797          	auipc	a5,0x0
    80001cb0:	db478793          	addi	a5,a5,-588 # 80001a60 <forkret>
    80001cb4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cb6:	60bc                	ld	a5,64(s1)
    80001cb8:	6705                	lui	a4,0x1
    80001cba:	97ba                	add	a5,a5,a4
    80001cbc:	f4bc                	sd	a5,104(s1)
  p->tracemask = 0;
    80001cbe:	1604b423          	sd	zero,360(s1)
}
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	60e2                	ld	ra,24(sp)
    80001cc6:	6442                	ld	s0,16(sp)
    80001cc8:	64a2                	ld	s1,8(sp)
    80001cca:	6902                	ld	s2,0(sp)
    80001ccc:	6105                	addi	sp,sp,32
    80001cce:	8082                	ret
    release(&p->lock);
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	03c080e7          	jalr	60(ra) # 80000d0e <release>
    return 0;
    80001cda:	84ca                	mv	s1,s2
    80001cdc:	b7dd                	j	80001cc2 <allocproc+0x90>
    freeproc(p);
    80001cde:	8526                	mv	a0,s1
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	efa080e7          	jalr	-262(ra) # 80001bda <freeproc>
    release(&p->lock);
    80001ce8:	8526                	mv	a0,s1
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	024080e7          	jalr	36(ra) # 80000d0e <release>
    return 0;
    80001cf2:	84ca                	mv	s1,s2
    80001cf4:	b7f9                	j	80001cc2 <allocproc+0x90>

0000000080001cf6 <userinit>:
{
    80001cf6:	1101                	addi	sp,sp,-32
    80001cf8:	ec06                	sd	ra,24(sp)
    80001cfa:	e822                	sd	s0,16(sp)
    80001cfc:	e426                	sd	s1,8(sp)
    80001cfe:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d00:	00000097          	auipc	ra,0x0
    80001d04:	f32080e7          	jalr	-206(ra) # 80001c32 <allocproc>
    80001d08:	84aa                	mv	s1,a0
  initproc = p;
    80001d0a:	00007797          	auipc	a5,0x7
    80001d0e:	30a7b723          	sd	a0,782(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d12:	03400613          	li	a2,52
    80001d16:	00007597          	auipc	a1,0x7
    80001d1a:	c9a58593          	addi	a1,a1,-870 # 800089b0 <initcode>
    80001d1e:	6928                	ld	a0,80(a0)
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	6f2080e7          	jalr	1778(ra) # 80001412 <uvminit>
  p->sz = PGSIZE;
    80001d28:	6785                	lui	a5,0x1
    80001d2a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d2c:	6cb8                	ld	a4,88(s1)
    80001d2e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d32:	6cb8                	ld	a4,88(s1)
    80001d34:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d36:	4641                	li	a2,16
    80001d38:	00006597          	auipc	a1,0x6
    80001d3c:	4b058593          	addi	a1,a1,1200 # 800081e8 <digits+0x1a8>
    80001d40:	15848513          	addi	a0,s1,344
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	168080e7          	jalr	360(ra) # 80000eac <safestrcpy>
  p->cwd = namei("/");
    80001d4c:	00006517          	auipc	a0,0x6
    80001d50:	4ac50513          	addi	a0,a0,1196 # 800081f8 <digits+0x1b8>
    80001d54:	00002097          	auipc	ra,0x2
    80001d58:	1ec080e7          	jalr	492(ra) # 80003f40 <namei>
    80001d5c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d60:	4789                	li	a5,2
    80001d62:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d64:	8526                	mv	a0,s1
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	fa8080e7          	jalr	-88(ra) # 80000d0e <release>
}
    80001d6e:	60e2                	ld	ra,24(sp)
    80001d70:	6442                	ld	s0,16(sp)
    80001d72:	64a2                	ld	s1,8(sp)
    80001d74:	6105                	addi	sp,sp,32
    80001d76:	8082                	ret

0000000080001d78 <growproc>:
{
    80001d78:	1101                	addi	sp,sp,-32
    80001d7a:	ec06                	sd	ra,24(sp)
    80001d7c:	e822                	sd	s0,16(sp)
    80001d7e:	e426                	sd	s1,8(sp)
    80001d80:	e04a                	sd	s2,0(sp)
    80001d82:	1000                	addi	s0,sp,32
    80001d84:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	ca2080e7          	jalr	-862(ra) # 80001a28 <myproc>
    80001d8e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d90:	652c                	ld	a1,72(a0)
    80001d92:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d96:	00904f63          	bgtz	s1,80001db4 <growproc+0x3c>
  } else if(n < 0){
    80001d9a:	0204cc63          	bltz	s1,80001dd2 <growproc+0x5a>
  p->sz = sz;
    80001d9e:	1602                	slli	a2,a2,0x20
    80001da0:	9201                	srli	a2,a2,0x20
    80001da2:	04c93423          	sd	a2,72(s2)
  return 0;
    80001da6:	4501                	li	a0,0
}
    80001da8:	60e2                	ld	ra,24(sp)
    80001daa:	6442                	ld	s0,16(sp)
    80001dac:	64a2                	ld	s1,8(sp)
    80001dae:	6902                	ld	s2,0(sp)
    80001db0:	6105                	addi	sp,sp,32
    80001db2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001db4:	9e25                	addw	a2,a2,s1
    80001db6:	1602                	slli	a2,a2,0x20
    80001db8:	9201                	srli	a2,a2,0x20
    80001dba:	1582                	slli	a1,a1,0x20
    80001dbc:	9181                	srli	a1,a1,0x20
    80001dbe:	6928                	ld	a0,80(a0)
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	70c080e7          	jalr	1804(ra) # 800014cc <uvmalloc>
    80001dc8:	0005061b          	sext.w	a2,a0
    80001dcc:	fa69                	bnez	a2,80001d9e <growproc+0x26>
      return -1;
    80001dce:	557d                	li	a0,-1
    80001dd0:	bfe1                	j	80001da8 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dd2:	9e25                	addw	a2,a2,s1
    80001dd4:	1602                	slli	a2,a2,0x20
    80001dd6:	9201                	srli	a2,a2,0x20
    80001dd8:	1582                	slli	a1,a1,0x20
    80001dda:	9181                	srli	a1,a1,0x20
    80001ddc:	6928                	ld	a0,80(a0)
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	6a6080e7          	jalr	1702(ra) # 80001484 <uvmdealloc>
    80001de6:	0005061b          	sext.w	a2,a0
    80001dea:	bf55                	j	80001d9e <growproc+0x26>

0000000080001dec <fork>:
{
    80001dec:	7179                	addi	sp,sp,-48
    80001dee:	f406                	sd	ra,40(sp)
    80001df0:	f022                	sd	s0,32(sp)
    80001df2:	ec26                	sd	s1,24(sp)
    80001df4:	e84a                	sd	s2,16(sp)
    80001df6:	e44e                	sd	s3,8(sp)
    80001df8:	e052                	sd	s4,0(sp)
    80001dfa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dfc:	00000097          	auipc	ra,0x0
    80001e00:	c2c080e7          	jalr	-980(ra) # 80001a28 <myproc>
    80001e04:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	e2c080e7          	jalr	-468(ra) # 80001c32 <allocproc>
    80001e0e:	c575                	beqz	a0,80001efa <fork+0x10e>
    80001e10:	89aa                	mv	s3,a0
  np->tracemask = p->tracemask;
    80001e12:	16893783          	ld	a5,360(s2)
    80001e16:	16f53423          	sd	a5,360(a0)
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e1a:	04893603          	ld	a2,72(s2)
    80001e1e:	692c                	ld	a1,80(a0)
    80001e20:	05093503          	ld	a0,80(s2)
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	7f4080e7          	jalr	2036(ra) # 80001618 <uvmcopy>
    80001e2c:	04054863          	bltz	a0,80001e7c <fork+0x90>
  np->sz = p->sz;
    80001e30:	04893783          	ld	a5,72(s2)
    80001e34:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e38:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e3c:	05893683          	ld	a3,88(s2)
    80001e40:	87b6                	mv	a5,a3
    80001e42:	0589b703          	ld	a4,88(s3)
    80001e46:	12068693          	addi	a3,a3,288
    80001e4a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e4e:	6788                	ld	a0,8(a5)
    80001e50:	6b8c                	ld	a1,16(a5)
    80001e52:	6f90                	ld	a2,24(a5)
    80001e54:	01073023          	sd	a6,0(a4)
    80001e58:	e708                	sd	a0,8(a4)
    80001e5a:	eb0c                	sd	a1,16(a4)
    80001e5c:	ef10                	sd	a2,24(a4)
    80001e5e:	02078793          	addi	a5,a5,32
    80001e62:	02070713          	addi	a4,a4,32
    80001e66:	fed792e3          	bne	a5,a3,80001e4a <fork+0x5e>
  np->trapframe->a0 = 0;
    80001e6a:	0589b783          	ld	a5,88(s3)
    80001e6e:	0607b823          	sd	zero,112(a5)
    80001e72:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e76:	15000a13          	li	s4,336
    80001e7a:	a03d                	j	80001ea8 <fork+0xbc>
    freeproc(np);
    80001e7c:	854e                	mv	a0,s3
    80001e7e:	00000097          	auipc	ra,0x0
    80001e82:	d5c080e7          	jalr	-676(ra) # 80001bda <freeproc>
    release(&np->lock);
    80001e86:	854e                	mv	a0,s3
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	e86080e7          	jalr	-378(ra) # 80000d0e <release>
    return -1;
    80001e90:	54fd                	li	s1,-1
    80001e92:	a899                	j	80001ee8 <fork+0xfc>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e94:	00002097          	auipc	ra,0x2
    80001e98:	738080e7          	jalr	1848(ra) # 800045cc <filedup>
    80001e9c:	009987b3          	add	a5,s3,s1
    80001ea0:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ea2:	04a1                	addi	s1,s1,8
    80001ea4:	01448763          	beq	s1,s4,80001eb2 <fork+0xc6>
    if(p->ofile[i])
    80001ea8:	009907b3          	add	a5,s2,s1
    80001eac:	6388                	ld	a0,0(a5)
    80001eae:	f17d                	bnez	a0,80001e94 <fork+0xa8>
    80001eb0:	bfcd                	j	80001ea2 <fork+0xb6>
  np->cwd = idup(p->cwd);
    80001eb2:	15093503          	ld	a0,336(s2)
    80001eb6:	00002097          	auipc	ra,0x2
    80001eba:	89c080e7          	jalr	-1892(ra) # 80003752 <idup>
    80001ebe:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ec2:	4641                	li	a2,16
    80001ec4:	15890593          	addi	a1,s2,344
    80001ec8:	15898513          	addi	a0,s3,344
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	fe0080e7          	jalr	-32(ra) # 80000eac <safestrcpy>
  pid = np->pid;
    80001ed4:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ed8:	4789                	li	a5,2
    80001eda:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ede:	854e                	mv	a0,s3
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	e2e080e7          	jalr	-466(ra) # 80000d0e <release>
}
    80001ee8:	8526                	mv	a0,s1
    80001eea:	70a2                	ld	ra,40(sp)
    80001eec:	7402                	ld	s0,32(sp)
    80001eee:	64e2                	ld	s1,24(sp)
    80001ef0:	6942                	ld	s2,16(sp)
    80001ef2:	69a2                	ld	s3,8(sp)
    80001ef4:	6a02                	ld	s4,0(sp)
    80001ef6:	6145                	addi	sp,sp,48
    80001ef8:	8082                	ret
    return -1;
    80001efa:	54fd                	li	s1,-1
    80001efc:	b7f5                	j	80001ee8 <fork+0xfc>

0000000080001efe <reparent>:
{
    80001efe:	7179                	addi	sp,sp,-48
    80001f00:	f406                	sd	ra,40(sp)
    80001f02:	f022                	sd	s0,32(sp)
    80001f04:	ec26                	sd	s1,24(sp)
    80001f06:	e84a                	sd	s2,16(sp)
    80001f08:	e44e                	sd	s3,8(sp)
    80001f0a:	e052                	sd	s4,0(sp)
    80001f0c:	1800                	addi	s0,sp,48
    80001f0e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f10:	00010497          	auipc	s1,0x10
    80001f14:	e5848493          	addi	s1,s1,-424 # 80011d68 <proc>
      pp->parent = initproc;
    80001f18:	00007a17          	auipc	s4,0x7
    80001f1c:	100a0a13          	addi	s4,s4,256 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f20:	00016997          	auipc	s3,0x16
    80001f24:	a4898993          	addi	s3,s3,-1464 # 80017968 <tickslock>
    80001f28:	a029                	j	80001f32 <reparent+0x34>
    80001f2a:	17048493          	addi	s1,s1,368
    80001f2e:	03348363          	beq	s1,s3,80001f54 <reparent+0x56>
    if(pp->parent == p){
    80001f32:	709c                	ld	a5,32(s1)
    80001f34:	ff279be3          	bne	a5,s2,80001f2a <reparent+0x2c>
      acquire(&pp->lock);
    80001f38:	8526                	mv	a0,s1
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	d20080e7          	jalr	-736(ra) # 80000c5a <acquire>
      pp->parent = initproc;
    80001f42:	000a3783          	ld	a5,0(s4)
    80001f46:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f48:	8526                	mv	a0,s1
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	dc4080e7          	jalr	-572(ra) # 80000d0e <release>
    80001f52:	bfe1                	j	80001f2a <reparent+0x2c>
}
    80001f54:	70a2                	ld	ra,40(sp)
    80001f56:	7402                	ld	s0,32(sp)
    80001f58:	64e2                	ld	s1,24(sp)
    80001f5a:	6942                	ld	s2,16(sp)
    80001f5c:	69a2                	ld	s3,8(sp)
    80001f5e:	6a02                	ld	s4,0(sp)
    80001f60:	6145                	addi	sp,sp,48
    80001f62:	8082                	ret

0000000080001f64 <scheduler>:
{
    80001f64:	715d                	addi	sp,sp,-80
    80001f66:	e486                	sd	ra,72(sp)
    80001f68:	e0a2                	sd	s0,64(sp)
    80001f6a:	fc26                	sd	s1,56(sp)
    80001f6c:	f84a                	sd	s2,48(sp)
    80001f6e:	f44e                	sd	s3,40(sp)
    80001f70:	f052                	sd	s4,32(sp)
    80001f72:	ec56                	sd	s5,24(sp)
    80001f74:	e85a                	sd	s6,16(sp)
    80001f76:	e45e                	sd	s7,8(sp)
    80001f78:	e062                	sd	s8,0(sp)
    80001f7a:	0880                	addi	s0,sp,80
    80001f7c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f7e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f80:	00779b13          	slli	s6,a5,0x7
    80001f84:	00010717          	auipc	a4,0x10
    80001f88:	9cc70713          	addi	a4,a4,-1588 # 80011950 <pid_lock>
    80001f8c:	975a                	add	a4,a4,s6
    80001f8e:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f92:	00010717          	auipc	a4,0x10
    80001f96:	9de70713          	addi	a4,a4,-1570 # 80011970 <cpus+0x8>
    80001f9a:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f9c:	4c0d                	li	s8,3
        c->proc = p;
    80001f9e:	079e                	slli	a5,a5,0x7
    80001fa0:	00010a17          	auipc	s4,0x10
    80001fa4:	9b0a0a13          	addi	s4,s4,-1616 # 80011950 <pid_lock>
    80001fa8:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001faa:	00016997          	auipc	s3,0x16
    80001fae:	9be98993          	addi	s3,s3,-1602 # 80017968 <tickslock>
        found = 1;
    80001fb2:	4b85                	li	s7,1
    80001fb4:	a899                	j	8000200a <scheduler+0xa6>
        p->state = RUNNING;
    80001fb6:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001fba:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fbe:	06048593          	addi	a1,s1,96
    80001fc2:	855a                	mv	a0,s6
    80001fc4:	00000097          	auipc	ra,0x0
    80001fc8:	68c080e7          	jalr	1676(ra) # 80002650 <swtch>
        c->proc = 0;
    80001fcc:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001fd0:	8ade                	mv	s5,s7
      release(&p->lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	d3a080e7          	jalr	-710(ra) # 80000d0e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fdc:	17048493          	addi	s1,s1,368
    80001fe0:	01348b63          	beq	s1,s3,80001ff6 <scheduler+0x92>
      acquire(&p->lock);
    80001fe4:	8526                	mv	a0,s1
    80001fe6:	fffff097          	auipc	ra,0xfffff
    80001fea:	c74080e7          	jalr	-908(ra) # 80000c5a <acquire>
      if(p->state == RUNNABLE) {
    80001fee:	4c9c                	lw	a5,24(s1)
    80001ff0:	ff2791e3          	bne	a5,s2,80001fd2 <scheduler+0x6e>
    80001ff4:	b7c9                	j	80001fb6 <scheduler+0x52>
    if(found == 0) {
    80001ff6:	000a9a63          	bnez	s5,8000200a <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ffe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002002:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002006:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000200a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000200e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002012:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002016:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002018:	00010497          	auipc	s1,0x10
    8000201c:	d5048493          	addi	s1,s1,-688 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002020:	4909                	li	s2,2
    80002022:	b7c9                	j	80001fe4 <scheduler+0x80>

0000000080002024 <sched>:
{
    80002024:	7179                	addi	sp,sp,-48
    80002026:	f406                	sd	ra,40(sp)
    80002028:	f022                	sd	s0,32(sp)
    8000202a:	ec26                	sd	s1,24(sp)
    8000202c:	e84a                	sd	s2,16(sp)
    8000202e:	e44e                	sd	s3,8(sp)
    80002030:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002032:	00000097          	auipc	ra,0x0
    80002036:	9f6080e7          	jalr	-1546(ra) # 80001a28 <myproc>
    8000203a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	ba4080e7          	jalr	-1116(ra) # 80000be0 <holding>
    80002044:	c93d                	beqz	a0,800020ba <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002046:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002048:	2781                	sext.w	a5,a5
    8000204a:	079e                	slli	a5,a5,0x7
    8000204c:	00010717          	auipc	a4,0x10
    80002050:	90470713          	addi	a4,a4,-1788 # 80011950 <pid_lock>
    80002054:	97ba                	add	a5,a5,a4
    80002056:	0907a703          	lw	a4,144(a5)
    8000205a:	4785                	li	a5,1
    8000205c:	06f71763          	bne	a4,a5,800020ca <sched+0xa6>
  if(p->state == RUNNING)
    80002060:	4c98                	lw	a4,24(s1)
    80002062:	478d                	li	a5,3
    80002064:	06f70b63          	beq	a4,a5,800020da <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002068:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000206c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000206e:	efb5                	bnez	a5,800020ea <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002070:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002072:	00010917          	auipc	s2,0x10
    80002076:	8de90913          	addi	s2,s2,-1826 # 80011950 <pid_lock>
    8000207a:	2781                	sext.w	a5,a5
    8000207c:	079e                	slli	a5,a5,0x7
    8000207e:	97ca                	add	a5,a5,s2
    80002080:	0947a983          	lw	s3,148(a5)
    80002084:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002086:	2781                	sext.w	a5,a5
    80002088:	079e                	slli	a5,a5,0x7
    8000208a:	00010597          	auipc	a1,0x10
    8000208e:	8e658593          	addi	a1,a1,-1818 # 80011970 <cpus+0x8>
    80002092:	95be                	add	a1,a1,a5
    80002094:	06048513          	addi	a0,s1,96
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	5b8080e7          	jalr	1464(ra) # 80002650 <swtch>
    800020a0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020a2:	2781                	sext.w	a5,a5
    800020a4:	079e                	slli	a5,a5,0x7
    800020a6:	97ca                	add	a5,a5,s2
    800020a8:	0937aa23          	sw	s3,148(a5)
}
    800020ac:	70a2                	ld	ra,40(sp)
    800020ae:	7402                	ld	s0,32(sp)
    800020b0:	64e2                	ld	s1,24(sp)
    800020b2:	6942                	ld	s2,16(sp)
    800020b4:	69a2                	ld	s3,8(sp)
    800020b6:	6145                	addi	sp,sp,48
    800020b8:	8082                	ret
    panic("sched p->lock");
    800020ba:	00006517          	auipc	a0,0x6
    800020be:	14650513          	addi	a0,a0,326 # 80008200 <digits+0x1c0>
    800020c2:	ffffe097          	auipc	ra,0xffffe
    800020c6:	486080e7          	jalr	1158(ra) # 80000548 <panic>
    panic("sched locks");
    800020ca:	00006517          	auipc	a0,0x6
    800020ce:	14650513          	addi	a0,a0,326 # 80008210 <digits+0x1d0>
    800020d2:	ffffe097          	auipc	ra,0xffffe
    800020d6:	476080e7          	jalr	1142(ra) # 80000548 <panic>
    panic("sched running");
    800020da:	00006517          	auipc	a0,0x6
    800020de:	14650513          	addi	a0,a0,326 # 80008220 <digits+0x1e0>
    800020e2:	ffffe097          	auipc	ra,0xffffe
    800020e6:	466080e7          	jalr	1126(ra) # 80000548 <panic>
    panic("sched interruptible");
    800020ea:	00006517          	auipc	a0,0x6
    800020ee:	14650513          	addi	a0,a0,326 # 80008230 <digits+0x1f0>
    800020f2:	ffffe097          	auipc	ra,0xffffe
    800020f6:	456080e7          	jalr	1110(ra) # 80000548 <panic>

00000000800020fa <exit>:
{
    800020fa:	7179                	addi	sp,sp,-48
    800020fc:	f406                	sd	ra,40(sp)
    800020fe:	f022                	sd	s0,32(sp)
    80002100:	ec26                	sd	s1,24(sp)
    80002102:	e84a                	sd	s2,16(sp)
    80002104:	e44e                	sd	s3,8(sp)
    80002106:	e052                	sd	s4,0(sp)
    80002108:	1800                	addi	s0,sp,48
    8000210a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	91c080e7          	jalr	-1764(ra) # 80001a28 <myproc>
    80002114:	89aa                	mv	s3,a0
  if(p == initproc)
    80002116:	00007797          	auipc	a5,0x7
    8000211a:	f027b783          	ld	a5,-254(a5) # 80009018 <initproc>
    8000211e:	0d050493          	addi	s1,a0,208
    80002122:	15050913          	addi	s2,a0,336
    80002126:	02a79363          	bne	a5,a0,8000214c <exit+0x52>
    panic("init exiting");
    8000212a:	00006517          	auipc	a0,0x6
    8000212e:	11e50513          	addi	a0,a0,286 # 80008248 <digits+0x208>
    80002132:	ffffe097          	auipc	ra,0xffffe
    80002136:	416080e7          	jalr	1046(ra) # 80000548 <panic>
      fileclose(f);
    8000213a:	00002097          	auipc	ra,0x2
    8000213e:	4e4080e7          	jalr	1252(ra) # 8000461e <fileclose>
      p->ofile[fd] = 0;
    80002142:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002146:	04a1                	addi	s1,s1,8
    80002148:	01248563          	beq	s1,s2,80002152 <exit+0x58>
    if(p->ofile[fd]){
    8000214c:	6088                	ld	a0,0(s1)
    8000214e:	f575                	bnez	a0,8000213a <exit+0x40>
    80002150:	bfdd                	j	80002146 <exit+0x4c>
  begin_op();
    80002152:	00002097          	auipc	ra,0x2
    80002156:	ffa080e7          	jalr	-6(ra) # 8000414c <begin_op>
  iput(p->cwd);
    8000215a:	1509b503          	ld	a0,336(s3)
    8000215e:	00001097          	auipc	ra,0x1
    80002162:	7ec080e7          	jalr	2028(ra) # 8000394a <iput>
  end_op();
    80002166:	00002097          	auipc	ra,0x2
    8000216a:	066080e7          	jalr	102(ra) # 800041cc <end_op>
  p->cwd = 0;
    8000216e:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002172:	00007497          	auipc	s1,0x7
    80002176:	ea648493          	addi	s1,s1,-346 # 80009018 <initproc>
    8000217a:	6088                	ld	a0,0(s1)
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	ade080e7          	jalr	-1314(ra) # 80000c5a <acquire>
  wakeup1(initproc);
    80002184:	6088                	ld	a0,0(s1)
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	762080e7          	jalr	1890(ra) # 800018e8 <wakeup1>
  release(&initproc->lock);
    8000218e:	6088                	ld	a0,0(s1)
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	b7e080e7          	jalr	-1154(ra) # 80000d0e <release>
  acquire(&p->lock);
    80002198:	854e                	mv	a0,s3
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	ac0080e7          	jalr	-1344(ra) # 80000c5a <acquire>
  struct proc *original_parent = p->parent;
    800021a2:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021a6:	854e                	mv	a0,s3
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	b66080e7          	jalr	-1178(ra) # 80000d0e <release>
  acquire(&original_parent->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	aa8080e7          	jalr	-1368(ra) # 80000c5a <acquire>
  acquire(&p->lock);
    800021ba:	854e                	mv	a0,s3
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	a9e080e7          	jalr	-1378(ra) # 80000c5a <acquire>
  reparent(p);
    800021c4:	854e                	mv	a0,s3
    800021c6:	00000097          	auipc	ra,0x0
    800021ca:	d38080e7          	jalr	-712(ra) # 80001efe <reparent>
  wakeup1(original_parent);
    800021ce:	8526                	mv	a0,s1
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	718080e7          	jalr	1816(ra) # 800018e8 <wakeup1>
  p->xstate = status;
    800021d8:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021dc:	4791                	li	a5,4
    800021de:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021e2:	8526                	mv	a0,s1
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	b2a080e7          	jalr	-1238(ra) # 80000d0e <release>
  sched();
    800021ec:	00000097          	auipc	ra,0x0
    800021f0:	e38080e7          	jalr	-456(ra) # 80002024 <sched>
  panic("zombie exit");
    800021f4:	00006517          	auipc	a0,0x6
    800021f8:	06450513          	addi	a0,a0,100 # 80008258 <digits+0x218>
    800021fc:	ffffe097          	auipc	ra,0xffffe
    80002200:	34c080e7          	jalr	844(ra) # 80000548 <panic>

0000000080002204 <yield>:
{
    80002204:	1101                	addi	sp,sp,-32
    80002206:	ec06                	sd	ra,24(sp)
    80002208:	e822                	sd	s0,16(sp)
    8000220a:	e426                	sd	s1,8(sp)
    8000220c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	81a080e7          	jalr	-2022(ra) # 80001a28 <myproc>
    80002216:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	a42080e7          	jalr	-1470(ra) # 80000c5a <acquire>
  p->state = RUNNABLE;
    80002220:	4789                	li	a5,2
    80002222:	cc9c                	sw	a5,24(s1)
  sched();
    80002224:	00000097          	auipc	ra,0x0
    80002228:	e00080e7          	jalr	-512(ra) # 80002024 <sched>
  release(&p->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	ae0080e7          	jalr	-1312(ra) # 80000d0e <release>
}
    80002236:	60e2                	ld	ra,24(sp)
    80002238:	6442                	ld	s0,16(sp)
    8000223a:	64a2                	ld	s1,8(sp)
    8000223c:	6105                	addi	sp,sp,32
    8000223e:	8082                	ret

0000000080002240 <sleep>:
{
    80002240:	7179                	addi	sp,sp,-48
    80002242:	f406                	sd	ra,40(sp)
    80002244:	f022                	sd	s0,32(sp)
    80002246:	ec26                	sd	s1,24(sp)
    80002248:	e84a                	sd	s2,16(sp)
    8000224a:	e44e                	sd	s3,8(sp)
    8000224c:	1800                	addi	s0,sp,48
    8000224e:	89aa                	mv	s3,a0
    80002250:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	7d6080e7          	jalr	2006(ra) # 80001a28 <myproc>
    8000225a:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000225c:	05250663          	beq	a0,s2,800022a8 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	9fa080e7          	jalr	-1542(ra) # 80000c5a <acquire>
    release(lk);
    80002268:	854a                	mv	a0,s2
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	aa4080e7          	jalr	-1372(ra) # 80000d0e <release>
  p->chan = chan;
    80002272:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002276:	4785                	li	a5,1
    80002278:	cc9c                	sw	a5,24(s1)
  sched();
    8000227a:	00000097          	auipc	ra,0x0
    8000227e:	daa080e7          	jalr	-598(ra) # 80002024 <sched>
  p->chan = 0;
    80002282:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002286:	8526                	mv	a0,s1
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	a86080e7          	jalr	-1402(ra) # 80000d0e <release>
    acquire(lk);
    80002290:	854a                	mv	a0,s2
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	9c8080e7          	jalr	-1592(ra) # 80000c5a <acquire>
}
    8000229a:	70a2                	ld	ra,40(sp)
    8000229c:	7402                	ld	s0,32(sp)
    8000229e:	64e2                	ld	s1,24(sp)
    800022a0:	6942                	ld	s2,16(sp)
    800022a2:	69a2                	ld	s3,8(sp)
    800022a4:	6145                	addi	sp,sp,48
    800022a6:	8082                	ret
  p->chan = chan;
    800022a8:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022ac:	4785                	li	a5,1
    800022ae:	cd1c                	sw	a5,24(a0)
  sched();
    800022b0:	00000097          	auipc	ra,0x0
    800022b4:	d74080e7          	jalr	-652(ra) # 80002024 <sched>
  p->chan = 0;
    800022b8:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022bc:	bff9                	j	8000229a <sleep+0x5a>

00000000800022be <wait>:
{
    800022be:	715d                	addi	sp,sp,-80
    800022c0:	e486                	sd	ra,72(sp)
    800022c2:	e0a2                	sd	s0,64(sp)
    800022c4:	fc26                	sd	s1,56(sp)
    800022c6:	f84a                	sd	s2,48(sp)
    800022c8:	f44e                	sd	s3,40(sp)
    800022ca:	f052                	sd	s4,32(sp)
    800022cc:	ec56                	sd	s5,24(sp)
    800022ce:	e85a                	sd	s6,16(sp)
    800022d0:	e45e                	sd	s7,8(sp)
    800022d2:	e062                	sd	s8,0(sp)
    800022d4:	0880                	addi	s0,sp,80
    800022d6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	750080e7          	jalr	1872(ra) # 80001a28 <myproc>
    800022e0:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022e2:	8c2a                	mv	s8,a0
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	976080e7          	jalr	-1674(ra) # 80000c5a <acquire>
    havekids = 0;
    800022ec:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022ee:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022f0:	00015997          	auipc	s3,0x15
    800022f4:	67898993          	addi	s3,s3,1656 # 80017968 <tickslock>
        havekids = 1;
    800022f8:	4a85                	li	s5,1
    havekids = 0;
    800022fa:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022fc:	00010497          	auipc	s1,0x10
    80002300:	a6c48493          	addi	s1,s1,-1428 # 80011d68 <proc>
    80002304:	a08d                	j	80002366 <wait+0xa8>
          pid = np->pid;
    80002306:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000230a:	000b0e63          	beqz	s6,80002326 <wait+0x68>
    8000230e:	4691                	li	a3,4
    80002310:	03448613          	addi	a2,s1,52
    80002314:	85da                	mv	a1,s6
    80002316:	05093503          	ld	a0,80(s2)
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	402080e7          	jalr	1026(ra) # 8000171c <copyout>
    80002322:	02054263          	bltz	a0,80002346 <wait+0x88>
          freeproc(np);
    80002326:	8526                	mv	a0,s1
    80002328:	00000097          	auipc	ra,0x0
    8000232c:	8b2080e7          	jalr	-1870(ra) # 80001bda <freeproc>
          release(&np->lock);
    80002330:	8526                	mv	a0,s1
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	9dc080e7          	jalr	-1572(ra) # 80000d0e <release>
          release(&p->lock);
    8000233a:	854a                	mv	a0,s2
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	9d2080e7          	jalr	-1582(ra) # 80000d0e <release>
          return pid;
    80002344:	a8a9                	j	8000239e <wait+0xe0>
            release(&np->lock);
    80002346:	8526                	mv	a0,s1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	9c6080e7          	jalr	-1594(ra) # 80000d0e <release>
            release(&p->lock);
    80002350:	854a                	mv	a0,s2
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	9bc080e7          	jalr	-1604(ra) # 80000d0e <release>
            return -1;
    8000235a:	59fd                	li	s3,-1
    8000235c:	a089                	j	8000239e <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000235e:	17048493          	addi	s1,s1,368
    80002362:	03348463          	beq	s1,s3,8000238a <wait+0xcc>
      if(np->parent == p){
    80002366:	709c                	ld	a5,32(s1)
    80002368:	ff279be3          	bne	a5,s2,8000235e <wait+0xa0>
        acquire(&np->lock);
    8000236c:	8526                	mv	a0,s1
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	8ec080e7          	jalr	-1812(ra) # 80000c5a <acquire>
        if(np->state == ZOMBIE){
    80002376:	4c9c                	lw	a5,24(s1)
    80002378:	f94787e3          	beq	a5,s4,80002306 <wait+0x48>
        release(&np->lock);
    8000237c:	8526                	mv	a0,s1
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	990080e7          	jalr	-1648(ra) # 80000d0e <release>
        havekids = 1;
    80002386:	8756                	mv	a4,s5
    80002388:	bfd9                	j	8000235e <wait+0xa0>
    if(!havekids || p->killed){
    8000238a:	c701                	beqz	a4,80002392 <wait+0xd4>
    8000238c:	03092783          	lw	a5,48(s2)
    80002390:	c785                	beqz	a5,800023b8 <wait+0xfa>
      release(&p->lock);
    80002392:	854a                	mv	a0,s2
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	97a080e7          	jalr	-1670(ra) # 80000d0e <release>
      return -1;
    8000239c:	59fd                	li	s3,-1
}
    8000239e:	854e                	mv	a0,s3
    800023a0:	60a6                	ld	ra,72(sp)
    800023a2:	6406                	ld	s0,64(sp)
    800023a4:	74e2                	ld	s1,56(sp)
    800023a6:	7942                	ld	s2,48(sp)
    800023a8:	79a2                	ld	s3,40(sp)
    800023aa:	7a02                	ld	s4,32(sp)
    800023ac:	6ae2                	ld	s5,24(sp)
    800023ae:	6b42                	ld	s6,16(sp)
    800023b0:	6ba2                	ld	s7,8(sp)
    800023b2:	6c02                	ld	s8,0(sp)
    800023b4:	6161                	addi	sp,sp,80
    800023b6:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023b8:	85e2                	mv	a1,s8
    800023ba:	854a                	mv	a0,s2
    800023bc:	00000097          	auipc	ra,0x0
    800023c0:	e84080e7          	jalr	-380(ra) # 80002240 <sleep>
    havekids = 0;
    800023c4:	bf1d                	j	800022fa <wait+0x3c>

00000000800023c6 <wakeup>:
{
    800023c6:	7139                	addi	sp,sp,-64
    800023c8:	fc06                	sd	ra,56(sp)
    800023ca:	f822                	sd	s0,48(sp)
    800023cc:	f426                	sd	s1,40(sp)
    800023ce:	f04a                	sd	s2,32(sp)
    800023d0:	ec4e                	sd	s3,24(sp)
    800023d2:	e852                	sd	s4,16(sp)
    800023d4:	e456                	sd	s5,8(sp)
    800023d6:	0080                	addi	s0,sp,64
    800023d8:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023da:	00010497          	auipc	s1,0x10
    800023de:	98e48493          	addi	s1,s1,-1650 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023e2:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023e4:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e6:	00015917          	auipc	s2,0x15
    800023ea:	58290913          	addi	s2,s2,1410 # 80017968 <tickslock>
    800023ee:	a821                	j	80002406 <wakeup+0x40>
      p->state = RUNNABLE;
    800023f0:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023f4:	8526                	mv	a0,s1
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	918080e7          	jalr	-1768(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023fe:	17048493          	addi	s1,s1,368
    80002402:	01248e63          	beq	s1,s2,8000241e <wakeup+0x58>
    acquire(&p->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	852080e7          	jalr	-1966(ra) # 80000c5a <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002410:	4c9c                	lw	a5,24(s1)
    80002412:	ff3791e3          	bne	a5,s3,800023f4 <wakeup+0x2e>
    80002416:	749c                	ld	a5,40(s1)
    80002418:	fd479ee3          	bne	a5,s4,800023f4 <wakeup+0x2e>
    8000241c:	bfd1                	j	800023f0 <wakeup+0x2a>
}
    8000241e:	70e2                	ld	ra,56(sp)
    80002420:	7442                	ld	s0,48(sp)
    80002422:	74a2                	ld	s1,40(sp)
    80002424:	7902                	ld	s2,32(sp)
    80002426:	69e2                	ld	s3,24(sp)
    80002428:	6a42                	ld	s4,16(sp)
    8000242a:	6aa2                	ld	s5,8(sp)
    8000242c:	6121                	addi	sp,sp,64
    8000242e:	8082                	ret

0000000080002430 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002430:	7179                	addi	sp,sp,-48
    80002432:	f406                	sd	ra,40(sp)
    80002434:	f022                	sd	s0,32(sp)
    80002436:	ec26                	sd	s1,24(sp)
    80002438:	e84a                	sd	s2,16(sp)
    8000243a:	e44e                	sd	s3,8(sp)
    8000243c:	1800                	addi	s0,sp,48
    8000243e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002440:	00010497          	auipc	s1,0x10
    80002444:	92848493          	addi	s1,s1,-1752 # 80011d68 <proc>
    80002448:	00015997          	auipc	s3,0x15
    8000244c:	52098993          	addi	s3,s3,1312 # 80017968 <tickslock>
    acquire(&p->lock);
    80002450:	8526                	mv	a0,s1
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	808080e7          	jalr	-2040(ra) # 80000c5a <acquire>
    if(p->pid == pid){
    8000245a:	5c9c                	lw	a5,56(s1)
    8000245c:	01278d63          	beq	a5,s2,80002476 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002460:	8526                	mv	a0,s1
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	8ac080e7          	jalr	-1876(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000246a:	17048493          	addi	s1,s1,368
    8000246e:	ff3491e3          	bne	s1,s3,80002450 <kill+0x20>
  }
  return -1;
    80002472:	557d                	li	a0,-1
    80002474:	a829                	j	8000248e <kill+0x5e>
      p->killed = 1;
    80002476:	4785                	li	a5,1
    80002478:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000247a:	4c98                	lw	a4,24(s1)
    8000247c:	4785                	li	a5,1
    8000247e:	00f70f63          	beq	a4,a5,8000249c <kill+0x6c>
      release(&p->lock);
    80002482:	8526                	mv	a0,s1
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	88a080e7          	jalr	-1910(ra) # 80000d0e <release>
      return 0;
    8000248c:	4501                	li	a0,0
}
    8000248e:	70a2                	ld	ra,40(sp)
    80002490:	7402                	ld	s0,32(sp)
    80002492:	64e2                	ld	s1,24(sp)
    80002494:	6942                	ld	s2,16(sp)
    80002496:	69a2                	ld	s3,8(sp)
    80002498:	6145                	addi	sp,sp,48
    8000249a:	8082                	ret
        p->state = RUNNABLE;
    8000249c:	4789                	li	a5,2
    8000249e:	cc9c                	sw	a5,24(s1)
    800024a0:	b7cd                	j	80002482 <kill+0x52>

00000000800024a2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024a2:	7179                	addi	sp,sp,-48
    800024a4:	f406                	sd	ra,40(sp)
    800024a6:	f022                	sd	s0,32(sp)
    800024a8:	ec26                	sd	s1,24(sp)
    800024aa:	e84a                	sd	s2,16(sp)
    800024ac:	e44e                	sd	s3,8(sp)
    800024ae:	e052                	sd	s4,0(sp)
    800024b0:	1800                	addi	s0,sp,48
    800024b2:	84aa                	mv	s1,a0
    800024b4:	892e                	mv	s2,a1
    800024b6:	89b2                	mv	s3,a2
    800024b8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ba:	fffff097          	auipc	ra,0xfffff
    800024be:	56e080e7          	jalr	1390(ra) # 80001a28 <myproc>
  if(user_dst){
    800024c2:	c08d                	beqz	s1,800024e4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024c4:	86d2                	mv	a3,s4
    800024c6:	864e                	mv	a2,s3
    800024c8:	85ca                	mv	a1,s2
    800024ca:	6928                	ld	a0,80(a0)
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	250080e7          	jalr	592(ra) # 8000171c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024d4:	70a2                	ld	ra,40(sp)
    800024d6:	7402                	ld	s0,32(sp)
    800024d8:	64e2                	ld	s1,24(sp)
    800024da:	6942                	ld	s2,16(sp)
    800024dc:	69a2                	ld	s3,8(sp)
    800024de:	6a02                	ld	s4,0(sp)
    800024e0:	6145                	addi	sp,sp,48
    800024e2:	8082                	ret
    memmove((char *)dst, src, len);
    800024e4:	000a061b          	sext.w	a2,s4
    800024e8:	85ce                	mv	a1,s3
    800024ea:	854a                	mv	a0,s2
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	8ca080e7          	jalr	-1846(ra) # 80000db6 <memmove>
    return 0;
    800024f4:	8526                	mv	a0,s1
    800024f6:	bff9                	j	800024d4 <either_copyout+0x32>

00000000800024f8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024f8:	7179                	addi	sp,sp,-48
    800024fa:	f406                	sd	ra,40(sp)
    800024fc:	f022                	sd	s0,32(sp)
    800024fe:	ec26                	sd	s1,24(sp)
    80002500:	e84a                	sd	s2,16(sp)
    80002502:	e44e                	sd	s3,8(sp)
    80002504:	e052                	sd	s4,0(sp)
    80002506:	1800                	addi	s0,sp,48
    80002508:	892a                	mv	s2,a0
    8000250a:	84ae                	mv	s1,a1
    8000250c:	89b2                	mv	s3,a2
    8000250e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	518080e7          	jalr	1304(ra) # 80001a28 <myproc>
  if(user_src){
    80002518:	c08d                	beqz	s1,8000253a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000251a:	86d2                	mv	a3,s4
    8000251c:	864e                	mv	a2,s3
    8000251e:	85ca                	mv	a1,s2
    80002520:	6928                	ld	a0,80(a0)
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	286080e7          	jalr	646(ra) # 800017a8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000252a:	70a2                	ld	ra,40(sp)
    8000252c:	7402                	ld	s0,32(sp)
    8000252e:	64e2                	ld	s1,24(sp)
    80002530:	6942                	ld	s2,16(sp)
    80002532:	69a2                	ld	s3,8(sp)
    80002534:	6a02                	ld	s4,0(sp)
    80002536:	6145                	addi	sp,sp,48
    80002538:	8082                	ret
    memmove(dst, (char*)src, len);
    8000253a:	000a061b          	sext.w	a2,s4
    8000253e:	85ce                	mv	a1,s3
    80002540:	854a                	mv	a0,s2
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	874080e7          	jalr	-1932(ra) # 80000db6 <memmove>
    return 0;
    8000254a:	8526                	mv	a0,s1
    8000254c:	bff9                	j	8000252a <either_copyin+0x32>

000000008000254e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000254e:	715d                	addi	sp,sp,-80
    80002550:	e486                	sd	ra,72(sp)
    80002552:	e0a2                	sd	s0,64(sp)
    80002554:	fc26                	sd	s1,56(sp)
    80002556:	f84a                	sd	s2,48(sp)
    80002558:	f44e                	sd	s3,40(sp)
    8000255a:	f052                	sd	s4,32(sp)
    8000255c:	ec56                	sd	s5,24(sp)
    8000255e:	e85a                	sd	s6,16(sp)
    80002560:	e45e                	sd	s7,8(sp)
    80002562:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002564:	00006517          	auipc	a0,0x6
    80002568:	b6450513          	addi	a0,a0,-1180 # 800080c8 <digits+0x88>
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	026080e7          	jalr	38(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002574:	00010497          	auipc	s1,0x10
    80002578:	94c48493          	addi	s1,s1,-1716 # 80011ec0 <proc+0x158>
    8000257c:	00015917          	auipc	s2,0x15
    80002580:	54490913          	addi	s2,s2,1348 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002584:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002586:	00006997          	auipc	s3,0x6
    8000258a:	ce298993          	addi	s3,s3,-798 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000258e:	00006a97          	auipc	s5,0x6
    80002592:	ce2a8a93          	addi	s5,s5,-798 # 80008270 <digits+0x230>
    printf("\n");
    80002596:	00006a17          	auipc	s4,0x6
    8000259a:	b32a0a13          	addi	s4,s4,-1230 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000259e:	00006b97          	auipc	s7,0x6
    800025a2:	d0ab8b93          	addi	s7,s7,-758 # 800082a8 <states.1707>
    800025a6:	a00d                	j	800025c8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025a8:	ee06a583          	lw	a1,-288(a3)
    800025ac:	8556                	mv	a0,s5
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	fe4080e7          	jalr	-28(ra) # 80000592 <printf>
    printf("\n");
    800025b6:	8552                	mv	a0,s4
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	fda080e7          	jalr	-38(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c0:	17048493          	addi	s1,s1,368
    800025c4:	03248163          	beq	s1,s2,800025e6 <procdump+0x98>
    if(p->state == UNUSED)
    800025c8:	86a6                	mv	a3,s1
    800025ca:	ec04a783          	lw	a5,-320(s1)
    800025ce:	dbed                	beqz	a5,800025c0 <procdump+0x72>
      state = "???";
    800025d0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d2:	fcfb6be3          	bltu	s6,a5,800025a8 <procdump+0x5a>
    800025d6:	1782                	slli	a5,a5,0x20
    800025d8:	9381                	srli	a5,a5,0x20
    800025da:	078e                	slli	a5,a5,0x3
    800025dc:	97de                	add	a5,a5,s7
    800025de:	6390                	ld	a2,0(a5)
    800025e0:	f661                	bnez	a2,800025a8 <procdump+0x5a>
      state = "???";
    800025e2:	864e                	mv	a2,s3
    800025e4:	b7d1                	j	800025a8 <procdump+0x5a>
  }
}
    800025e6:	60a6                	ld	ra,72(sp)
    800025e8:	6406                	ld	s0,64(sp)
    800025ea:	74e2                	ld	s1,56(sp)
    800025ec:	7942                	ld	s2,48(sp)
    800025ee:	79a2                	ld	s3,40(sp)
    800025f0:	7a02                	ld	s4,32(sp)
    800025f2:	6ae2                	ld	s5,24(sp)
    800025f4:	6b42                	ld	s6,16(sp)
    800025f6:	6ba2                	ld	s7,8(sp)
    800025f8:	6161                	addi	sp,sp,80
    800025fa:	8082                	ret

00000000800025fc <count_free_proc>:

// Count how many processes are not in the state of UNUSED
uint64
count_free_proc(void) {
    800025fc:	7179                	addi	sp,sp,-48
    800025fe:	f406                	sd	ra,40(sp)
    80002600:	f022                	sd	s0,32(sp)
    80002602:	ec26                	sd	s1,24(sp)
    80002604:	e84a                	sd	s2,16(sp)
    80002606:	e44e                	sd	s3,8(sp)
    80002608:	1800                	addi	s0,sp,48
  struct proc *p;
  uint64 count = 0;
    8000260a:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000260c:	0000f497          	auipc	s1,0xf
    80002610:	75c48493          	addi	s1,s1,1884 # 80011d68 <proc>
    80002614:	00015997          	auipc	s3,0x15
    80002618:	35498993          	addi	s3,s3,852 # 80017968 <tickslock>
    // 此处不一定需要加锁, 因为该函数是只读不写
    // 但proc.c里其他类似的遍历时都加了锁, 那我们也加上
    acquire(&p->lock);
    8000261c:	8526                	mv	a0,s1
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	63c080e7          	jalr	1596(ra) # 80000c5a <acquire>
    if(p->state != UNUSED) {
    80002626:	4c9c                	lw	a5,24(s1)
      count += 1;
    80002628:	00f037b3          	snez	a5,a5
    8000262c:	993e                	add	s2,s2,a5
    }
    release(&p->lock);
    8000262e:	8526                	mv	a0,s1
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	6de080e7          	jalr	1758(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002638:	17048493          	addi	s1,s1,368
    8000263c:	ff3490e3          	bne	s1,s3,8000261c <count_free_proc+0x20>
  }
  return count;
    80002640:	854a                	mv	a0,s2
    80002642:	70a2                	ld	ra,40(sp)
    80002644:	7402                	ld	s0,32(sp)
    80002646:	64e2                	ld	s1,24(sp)
    80002648:	6942                	ld	s2,16(sp)
    8000264a:	69a2                	ld	s3,8(sp)
    8000264c:	6145                	addi	sp,sp,48
    8000264e:	8082                	ret

0000000080002650 <swtch>:
    80002650:	00153023          	sd	ra,0(a0)
    80002654:	00253423          	sd	sp,8(a0)
    80002658:	e900                	sd	s0,16(a0)
    8000265a:	ed04                	sd	s1,24(a0)
    8000265c:	03253023          	sd	s2,32(a0)
    80002660:	03353423          	sd	s3,40(a0)
    80002664:	03453823          	sd	s4,48(a0)
    80002668:	03553c23          	sd	s5,56(a0)
    8000266c:	05653023          	sd	s6,64(a0)
    80002670:	05753423          	sd	s7,72(a0)
    80002674:	05853823          	sd	s8,80(a0)
    80002678:	05953c23          	sd	s9,88(a0)
    8000267c:	07a53023          	sd	s10,96(a0)
    80002680:	07b53423          	sd	s11,104(a0)
    80002684:	0005b083          	ld	ra,0(a1)
    80002688:	0085b103          	ld	sp,8(a1)
    8000268c:	6980                	ld	s0,16(a1)
    8000268e:	6d84                	ld	s1,24(a1)
    80002690:	0205b903          	ld	s2,32(a1)
    80002694:	0285b983          	ld	s3,40(a1)
    80002698:	0305ba03          	ld	s4,48(a1)
    8000269c:	0385ba83          	ld	s5,56(a1)
    800026a0:	0405bb03          	ld	s6,64(a1)
    800026a4:	0485bb83          	ld	s7,72(a1)
    800026a8:	0505bc03          	ld	s8,80(a1)
    800026ac:	0585bc83          	ld	s9,88(a1)
    800026b0:	0605bd03          	ld	s10,96(a1)
    800026b4:	0685bd83          	ld	s11,104(a1)
    800026b8:	8082                	ret

00000000800026ba <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026ba:	1141                	addi	sp,sp,-16
    800026bc:	e406                	sd	ra,8(sp)
    800026be:	e022                	sd	s0,0(sp)
    800026c0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026c2:	00006597          	auipc	a1,0x6
    800026c6:	c0e58593          	addi	a1,a1,-1010 # 800082d0 <states.1707+0x28>
    800026ca:	00015517          	auipc	a0,0x15
    800026ce:	29e50513          	addi	a0,a0,670 # 80017968 <tickslock>
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	4f8080e7          	jalr	1272(ra) # 80000bca <initlock>
}
    800026da:	60a2                	ld	ra,8(sp)
    800026dc:	6402                	ld	s0,0(sp)
    800026de:	0141                	addi	sp,sp,16
    800026e0:	8082                	ret

00000000800026e2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026e2:	1141                	addi	sp,sp,-16
    800026e4:	e422                	sd	s0,8(sp)
    800026e6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026e8:	00003797          	auipc	a5,0x3
    800026ec:	5a878793          	addi	a5,a5,1448 # 80005c90 <kernelvec>
    800026f0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026f4:	6422                	ld	s0,8(sp)
    800026f6:	0141                	addi	sp,sp,16
    800026f8:	8082                	ret

00000000800026fa <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026fa:	1141                	addi	sp,sp,-16
    800026fc:	e406                	sd	ra,8(sp)
    800026fe:	e022                	sd	s0,0(sp)
    80002700:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002702:	fffff097          	auipc	ra,0xfffff
    80002706:	326080e7          	jalr	806(ra) # 80001a28 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000270a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000270e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002710:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002714:	00005617          	auipc	a2,0x5
    80002718:	8ec60613          	addi	a2,a2,-1812 # 80007000 <_trampoline>
    8000271c:	00005697          	auipc	a3,0x5
    80002720:	8e468693          	addi	a3,a3,-1820 # 80007000 <_trampoline>
    80002724:	8e91                	sub	a3,a3,a2
    80002726:	040007b7          	lui	a5,0x4000
    8000272a:	17fd                	addi	a5,a5,-1
    8000272c:	07b2                	slli	a5,a5,0xc
    8000272e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002730:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002734:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002736:	180026f3          	csrr	a3,satp
    8000273a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000273c:	6d38                	ld	a4,88(a0)
    8000273e:	6134                	ld	a3,64(a0)
    80002740:	6585                	lui	a1,0x1
    80002742:	96ae                	add	a3,a3,a1
    80002744:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002746:	6d38                	ld	a4,88(a0)
    80002748:	00000697          	auipc	a3,0x0
    8000274c:	13868693          	addi	a3,a3,312 # 80002880 <usertrap>
    80002750:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002752:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002754:	8692                	mv	a3,tp
    80002756:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002758:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000275c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002760:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002764:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002768:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000276a:	6f18                	ld	a4,24(a4)
    8000276c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002770:	692c                	ld	a1,80(a0)
    80002772:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002774:	00005717          	auipc	a4,0x5
    80002778:	91c70713          	addi	a4,a4,-1764 # 80007090 <userret>
    8000277c:	8f11                	sub	a4,a4,a2
    8000277e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002780:	577d                	li	a4,-1
    80002782:	177e                	slli	a4,a4,0x3f
    80002784:	8dd9                	or	a1,a1,a4
    80002786:	02000537          	lui	a0,0x2000
    8000278a:	157d                	addi	a0,a0,-1
    8000278c:	0536                	slli	a0,a0,0xd
    8000278e:	9782                	jalr	a5
}
    80002790:	60a2                	ld	ra,8(sp)
    80002792:	6402                	ld	s0,0(sp)
    80002794:	0141                	addi	sp,sp,16
    80002796:	8082                	ret

0000000080002798 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002798:	1101                	addi	sp,sp,-32
    8000279a:	ec06                	sd	ra,24(sp)
    8000279c:	e822                	sd	s0,16(sp)
    8000279e:	e426                	sd	s1,8(sp)
    800027a0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027a2:	00015497          	auipc	s1,0x15
    800027a6:	1c648493          	addi	s1,s1,454 # 80017968 <tickslock>
    800027aa:	8526                	mv	a0,s1
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	4ae080e7          	jalr	1198(ra) # 80000c5a <acquire>
  ticks++;
    800027b4:	00007517          	auipc	a0,0x7
    800027b8:	86c50513          	addi	a0,a0,-1940 # 80009020 <ticks>
    800027bc:	411c                	lw	a5,0(a0)
    800027be:	2785                	addiw	a5,a5,1
    800027c0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027c2:	00000097          	auipc	ra,0x0
    800027c6:	c04080e7          	jalr	-1020(ra) # 800023c6 <wakeup>
  release(&tickslock);
    800027ca:	8526                	mv	a0,s1
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	542080e7          	jalr	1346(ra) # 80000d0e <release>
}
    800027d4:	60e2                	ld	ra,24(sp)
    800027d6:	6442                	ld	s0,16(sp)
    800027d8:	64a2                	ld	s1,8(sp)
    800027da:	6105                	addi	sp,sp,32
    800027dc:	8082                	ret

00000000800027de <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027de:	1101                	addi	sp,sp,-32
    800027e0:	ec06                	sd	ra,24(sp)
    800027e2:	e822                	sd	s0,16(sp)
    800027e4:	e426                	sd	s1,8(sp)
    800027e6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027ec:	00074d63          	bltz	a4,80002806 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027f0:	57fd                	li	a5,-1
    800027f2:	17fe                	slli	a5,a5,0x3f
    800027f4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027f6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027f8:	06f70363          	beq	a4,a5,8000285e <devintr+0x80>
  }
}
    800027fc:	60e2                	ld	ra,24(sp)
    800027fe:	6442                	ld	s0,16(sp)
    80002800:	64a2                	ld	s1,8(sp)
    80002802:	6105                	addi	sp,sp,32
    80002804:	8082                	ret
     (scause & 0xff) == 9){
    80002806:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000280a:	46a5                	li	a3,9
    8000280c:	fed792e3          	bne	a5,a3,800027f0 <devintr+0x12>
    int irq = plic_claim();
    80002810:	00003097          	auipc	ra,0x3
    80002814:	588080e7          	jalr	1416(ra) # 80005d98 <plic_claim>
    80002818:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000281a:	47a9                	li	a5,10
    8000281c:	02f50763          	beq	a0,a5,8000284a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002820:	4785                	li	a5,1
    80002822:	02f50963          	beq	a0,a5,80002854 <devintr+0x76>
    return 1;
    80002826:	4505                	li	a0,1
    } else if(irq){
    80002828:	d8f1                	beqz	s1,800027fc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000282a:	85a6                	mv	a1,s1
    8000282c:	00006517          	auipc	a0,0x6
    80002830:	aac50513          	addi	a0,a0,-1364 # 800082d8 <states.1707+0x30>
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	d5e080e7          	jalr	-674(ra) # 80000592 <printf>
      plic_complete(irq);
    8000283c:	8526                	mv	a0,s1
    8000283e:	00003097          	auipc	ra,0x3
    80002842:	57e080e7          	jalr	1406(ra) # 80005dbc <plic_complete>
    return 1;
    80002846:	4505                	li	a0,1
    80002848:	bf55                	j	800027fc <devintr+0x1e>
      uartintr();
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	18a080e7          	jalr	394(ra) # 800009d4 <uartintr>
    80002852:	b7ed                	j	8000283c <devintr+0x5e>
      virtio_disk_intr();
    80002854:	00004097          	auipc	ra,0x4
    80002858:	a02080e7          	jalr	-1534(ra) # 80006256 <virtio_disk_intr>
    8000285c:	b7c5                	j	8000283c <devintr+0x5e>
    if(cpuid() == 0){
    8000285e:	fffff097          	auipc	ra,0xfffff
    80002862:	19e080e7          	jalr	414(ra) # 800019fc <cpuid>
    80002866:	c901                	beqz	a0,80002876 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002868:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000286c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000286e:	14479073          	csrw	sip,a5
    return 2;
    80002872:	4509                	li	a0,2
    80002874:	b761                	j	800027fc <devintr+0x1e>
      clockintr();
    80002876:	00000097          	auipc	ra,0x0
    8000287a:	f22080e7          	jalr	-222(ra) # 80002798 <clockintr>
    8000287e:	b7ed                	j	80002868 <devintr+0x8a>

0000000080002880 <usertrap>:
{
    80002880:	1101                	addi	sp,sp,-32
    80002882:	ec06                	sd	ra,24(sp)
    80002884:	e822                	sd	s0,16(sp)
    80002886:	e426                	sd	s1,8(sp)
    80002888:	e04a                	sd	s2,0(sp)
    8000288a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002890:	1007f793          	andi	a5,a5,256
    80002894:	e3ad                	bnez	a5,800028f6 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002896:	00003797          	auipc	a5,0x3
    8000289a:	3fa78793          	addi	a5,a5,1018 # 80005c90 <kernelvec>
    8000289e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028a2:	fffff097          	auipc	ra,0xfffff
    800028a6:	186080e7          	jalr	390(ra) # 80001a28 <myproc>
    800028aa:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028ac:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ae:	14102773          	csrr	a4,sepc
    800028b2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028b8:	47a1                	li	a5,8
    800028ba:	04f71c63          	bne	a4,a5,80002912 <usertrap+0x92>
    if(p->killed)
    800028be:	591c                	lw	a5,48(a0)
    800028c0:	e3b9                	bnez	a5,80002906 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028c2:	6cb8                	ld	a4,88(s1)
    800028c4:	6f1c                	ld	a5,24(a4)
    800028c6:	0791                	addi	a5,a5,4
    800028c8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028ce:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d2:	10079073          	csrw	sstatus,a5
    syscall();
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	2e0080e7          	jalr	736(ra) # 80002bb6 <syscall>
  if(p->killed)
    800028de:	589c                	lw	a5,48(s1)
    800028e0:	ebc1                	bnez	a5,80002970 <usertrap+0xf0>
  usertrapret();
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	e18080e7          	jalr	-488(ra) # 800026fa <usertrapret>
}
    800028ea:	60e2                	ld	ra,24(sp)
    800028ec:	6442                	ld	s0,16(sp)
    800028ee:	64a2                	ld	s1,8(sp)
    800028f0:	6902                	ld	s2,0(sp)
    800028f2:	6105                	addi	sp,sp,32
    800028f4:	8082                	ret
    panic("usertrap: not from user mode");
    800028f6:	00006517          	auipc	a0,0x6
    800028fa:	a0250513          	addi	a0,a0,-1534 # 800082f8 <states.1707+0x50>
    800028fe:	ffffe097          	auipc	ra,0xffffe
    80002902:	c4a080e7          	jalr	-950(ra) # 80000548 <panic>
      exit(-1);
    80002906:	557d                	li	a0,-1
    80002908:	fffff097          	auipc	ra,0xfffff
    8000290c:	7f2080e7          	jalr	2034(ra) # 800020fa <exit>
    80002910:	bf4d                	j	800028c2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002912:	00000097          	auipc	ra,0x0
    80002916:	ecc080e7          	jalr	-308(ra) # 800027de <devintr>
    8000291a:	892a                	mv	s2,a0
    8000291c:	c501                	beqz	a0,80002924 <usertrap+0xa4>
  if(p->killed)
    8000291e:	589c                	lw	a5,48(s1)
    80002920:	c3a1                	beqz	a5,80002960 <usertrap+0xe0>
    80002922:	a815                	j	80002956 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002924:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002928:	5c90                	lw	a2,56(s1)
    8000292a:	00006517          	auipc	a0,0x6
    8000292e:	9ee50513          	addi	a0,a0,-1554 # 80008318 <states.1707+0x70>
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	c60080e7          	jalr	-928(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000293a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000293e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002942:	00006517          	auipc	a0,0x6
    80002946:	a0650513          	addi	a0,a0,-1530 # 80008348 <states.1707+0xa0>
    8000294a:	ffffe097          	auipc	ra,0xffffe
    8000294e:	c48080e7          	jalr	-952(ra) # 80000592 <printf>
    p->killed = 1;
    80002952:	4785                	li	a5,1
    80002954:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002956:	557d                	li	a0,-1
    80002958:	fffff097          	auipc	ra,0xfffff
    8000295c:	7a2080e7          	jalr	1954(ra) # 800020fa <exit>
  if(which_dev == 2)
    80002960:	4789                	li	a5,2
    80002962:	f8f910e3          	bne	s2,a5,800028e2 <usertrap+0x62>
    yield();
    80002966:	00000097          	auipc	ra,0x0
    8000296a:	89e080e7          	jalr	-1890(ra) # 80002204 <yield>
    8000296e:	bf95                	j	800028e2 <usertrap+0x62>
  int which_dev = 0;
    80002970:	4901                	li	s2,0
    80002972:	b7d5                	j	80002956 <usertrap+0xd6>

0000000080002974 <kerneltrap>:
{
    80002974:	7179                	addi	sp,sp,-48
    80002976:	f406                	sd	ra,40(sp)
    80002978:	f022                	sd	s0,32(sp)
    8000297a:	ec26                	sd	s1,24(sp)
    8000297c:	e84a                	sd	s2,16(sp)
    8000297e:	e44e                	sd	s3,8(sp)
    80002980:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002982:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002986:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000298a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000298e:	1004f793          	andi	a5,s1,256
    80002992:	cb85                	beqz	a5,800029c2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002994:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002998:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000299a:	ef85                	bnez	a5,800029d2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000299c:	00000097          	auipc	ra,0x0
    800029a0:	e42080e7          	jalr	-446(ra) # 800027de <devintr>
    800029a4:	cd1d                	beqz	a0,800029e2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029a6:	4789                	li	a5,2
    800029a8:	06f50a63          	beq	a0,a5,80002a1c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029ac:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b0:	10049073          	csrw	sstatus,s1
}
    800029b4:	70a2                	ld	ra,40(sp)
    800029b6:	7402                	ld	s0,32(sp)
    800029b8:	64e2                	ld	s1,24(sp)
    800029ba:	6942                	ld	s2,16(sp)
    800029bc:	69a2                	ld	s3,8(sp)
    800029be:	6145                	addi	sp,sp,48
    800029c0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029c2:	00006517          	auipc	a0,0x6
    800029c6:	9a650513          	addi	a0,a0,-1626 # 80008368 <states.1707+0xc0>
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	b7e080e7          	jalr	-1154(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    800029d2:	00006517          	auipc	a0,0x6
    800029d6:	9be50513          	addi	a0,a0,-1602 # 80008390 <states.1707+0xe8>
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	b6e080e7          	jalr	-1170(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    800029e2:	85ce                	mv	a1,s3
    800029e4:	00006517          	auipc	a0,0x6
    800029e8:	9cc50513          	addi	a0,a0,-1588 # 800083b0 <states.1707+0x108>
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	ba6080e7          	jalr	-1114(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029f8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029fc:	00006517          	auipc	a0,0x6
    80002a00:	9c450513          	addi	a0,a0,-1596 # 800083c0 <states.1707+0x118>
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	b8e080e7          	jalr	-1138(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002a0c:	00006517          	auipc	a0,0x6
    80002a10:	9cc50513          	addi	a0,a0,-1588 # 800083d8 <states.1707+0x130>
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	b34080e7          	jalr	-1228(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a1c:	fffff097          	auipc	ra,0xfffff
    80002a20:	00c080e7          	jalr	12(ra) # 80001a28 <myproc>
    80002a24:	d541                	beqz	a0,800029ac <kerneltrap+0x38>
    80002a26:	fffff097          	auipc	ra,0xfffff
    80002a2a:	002080e7          	jalr	2(ra) # 80001a28 <myproc>
    80002a2e:	4d18                	lw	a4,24(a0)
    80002a30:	478d                	li	a5,3
    80002a32:	f6f71de3          	bne	a4,a5,800029ac <kerneltrap+0x38>
    yield();
    80002a36:	fffff097          	auipc	ra,0xfffff
    80002a3a:	7ce080e7          	jalr	1998(ra) # 80002204 <yield>
    80002a3e:	b7bd                	j	800029ac <kerneltrap+0x38>

0000000080002a40 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a40:	1101                	addi	sp,sp,-32
    80002a42:	ec06                	sd	ra,24(sp)
    80002a44:	e822                	sd	s0,16(sp)
    80002a46:	e426                	sd	s1,8(sp)
    80002a48:	1000                	addi	s0,sp,32
    80002a4a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	fdc080e7          	jalr	-36(ra) # 80001a28 <myproc>
  switch (n) {
    80002a54:	4795                	li	a5,5
    80002a56:	0497e163          	bltu	a5,s1,80002a98 <argraw+0x58>
    80002a5a:	048a                	slli	s1,s1,0x2
    80002a5c:	00006717          	auipc	a4,0x6
    80002a60:	a7c70713          	addi	a4,a4,-1412 # 800084d8 <states.1707+0x230>
    80002a64:	94ba                	add	s1,s1,a4
    80002a66:	409c                	lw	a5,0(s1)
    80002a68:	97ba                	add	a5,a5,a4
    80002a6a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a6c:	6d3c                	ld	a5,88(a0)
    80002a6e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a70:	60e2                	ld	ra,24(sp)
    80002a72:	6442                	ld	s0,16(sp)
    80002a74:	64a2                	ld	s1,8(sp)
    80002a76:	6105                	addi	sp,sp,32
    80002a78:	8082                	ret
    return p->trapframe->a1;
    80002a7a:	6d3c                	ld	a5,88(a0)
    80002a7c:	7fa8                	ld	a0,120(a5)
    80002a7e:	bfcd                	j	80002a70 <argraw+0x30>
    return p->trapframe->a2;
    80002a80:	6d3c                	ld	a5,88(a0)
    80002a82:	63c8                	ld	a0,128(a5)
    80002a84:	b7f5                	j	80002a70 <argraw+0x30>
    return p->trapframe->a3;
    80002a86:	6d3c                	ld	a5,88(a0)
    80002a88:	67c8                	ld	a0,136(a5)
    80002a8a:	b7dd                	j	80002a70 <argraw+0x30>
    return p->trapframe->a4;
    80002a8c:	6d3c                	ld	a5,88(a0)
    80002a8e:	6bc8                	ld	a0,144(a5)
    80002a90:	b7c5                	j	80002a70 <argraw+0x30>
    return p->trapframe->a5;
    80002a92:	6d3c                	ld	a5,88(a0)
    80002a94:	6fc8                	ld	a0,152(a5)
    80002a96:	bfe9                	j	80002a70 <argraw+0x30>
  panic("argraw");
    80002a98:	00006517          	auipc	a0,0x6
    80002a9c:	95050513          	addi	a0,a0,-1712 # 800083e8 <states.1707+0x140>
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	aa8080e7          	jalr	-1368(ra) # 80000548 <panic>

0000000080002aa8 <fetchaddr>:
{
    80002aa8:	1101                	addi	sp,sp,-32
    80002aaa:	ec06                	sd	ra,24(sp)
    80002aac:	e822                	sd	s0,16(sp)
    80002aae:	e426                	sd	s1,8(sp)
    80002ab0:	e04a                	sd	s2,0(sp)
    80002ab2:	1000                	addi	s0,sp,32
    80002ab4:	84aa                	mv	s1,a0
    80002ab6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ab8:	fffff097          	auipc	ra,0xfffff
    80002abc:	f70080e7          	jalr	-144(ra) # 80001a28 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ac0:	653c                	ld	a5,72(a0)
    80002ac2:	02f4f863          	bgeu	s1,a5,80002af2 <fetchaddr+0x4a>
    80002ac6:	00848713          	addi	a4,s1,8
    80002aca:	02e7e663          	bltu	a5,a4,80002af6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ace:	46a1                	li	a3,8
    80002ad0:	8626                	mv	a2,s1
    80002ad2:	85ca                	mv	a1,s2
    80002ad4:	6928                	ld	a0,80(a0)
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	cd2080e7          	jalr	-814(ra) # 800017a8 <copyin>
    80002ade:	00a03533          	snez	a0,a0
    80002ae2:	40a00533          	neg	a0,a0
}
    80002ae6:	60e2                	ld	ra,24(sp)
    80002ae8:	6442                	ld	s0,16(sp)
    80002aea:	64a2                	ld	s1,8(sp)
    80002aec:	6902                	ld	s2,0(sp)
    80002aee:	6105                	addi	sp,sp,32
    80002af0:	8082                	ret
    return -1;
    80002af2:	557d                	li	a0,-1
    80002af4:	bfcd                	j	80002ae6 <fetchaddr+0x3e>
    80002af6:	557d                	li	a0,-1
    80002af8:	b7fd                	j	80002ae6 <fetchaddr+0x3e>

0000000080002afa <fetchstr>:
{
    80002afa:	7179                	addi	sp,sp,-48
    80002afc:	f406                	sd	ra,40(sp)
    80002afe:	f022                	sd	s0,32(sp)
    80002b00:	ec26                	sd	s1,24(sp)
    80002b02:	e84a                	sd	s2,16(sp)
    80002b04:	e44e                	sd	s3,8(sp)
    80002b06:	1800                	addi	s0,sp,48
    80002b08:	892a                	mv	s2,a0
    80002b0a:	84ae                	mv	s1,a1
    80002b0c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	f1a080e7          	jalr	-230(ra) # 80001a28 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b16:	86ce                	mv	a3,s3
    80002b18:	864a                	mv	a2,s2
    80002b1a:	85a6                	mv	a1,s1
    80002b1c:	6928                	ld	a0,80(a0)
    80002b1e:	fffff097          	auipc	ra,0xfffff
    80002b22:	d16080e7          	jalr	-746(ra) # 80001834 <copyinstr>
  if(err < 0)
    80002b26:	00054763          	bltz	a0,80002b34 <fetchstr+0x3a>
  return strlen(buf);
    80002b2a:	8526                	mv	a0,s1
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	3b2080e7          	jalr	946(ra) # 80000ede <strlen>
}
    80002b34:	70a2                	ld	ra,40(sp)
    80002b36:	7402                	ld	s0,32(sp)
    80002b38:	64e2                	ld	s1,24(sp)
    80002b3a:	6942                	ld	s2,16(sp)
    80002b3c:	69a2                	ld	s3,8(sp)
    80002b3e:	6145                	addi	sp,sp,48
    80002b40:	8082                	ret

0000000080002b42 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b42:	1101                	addi	sp,sp,-32
    80002b44:	ec06                	sd	ra,24(sp)
    80002b46:	e822                	sd	s0,16(sp)
    80002b48:	e426                	sd	s1,8(sp)
    80002b4a:	1000                	addi	s0,sp,32
    80002b4c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b4e:	00000097          	auipc	ra,0x0
    80002b52:	ef2080e7          	jalr	-270(ra) # 80002a40 <argraw>
    80002b56:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b58:	4501                	li	a0,0
    80002b5a:	60e2                	ld	ra,24(sp)
    80002b5c:	6442                	ld	s0,16(sp)
    80002b5e:	64a2                	ld	s1,8(sp)
    80002b60:	6105                	addi	sp,sp,32
    80002b62:	8082                	ret

0000000080002b64 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b64:	1101                	addi	sp,sp,-32
    80002b66:	ec06                	sd	ra,24(sp)
    80002b68:	e822                	sd	s0,16(sp)
    80002b6a:	e426                	sd	s1,8(sp)
    80002b6c:	1000                	addi	s0,sp,32
    80002b6e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b70:	00000097          	auipc	ra,0x0
    80002b74:	ed0080e7          	jalr	-304(ra) # 80002a40 <argraw>
    80002b78:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b7a:	4501                	li	a0,0
    80002b7c:	60e2                	ld	ra,24(sp)
    80002b7e:	6442                	ld	s0,16(sp)
    80002b80:	64a2                	ld	s1,8(sp)
    80002b82:	6105                	addi	sp,sp,32
    80002b84:	8082                	ret

0000000080002b86 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b86:	1101                	addi	sp,sp,-32
    80002b88:	ec06                	sd	ra,24(sp)
    80002b8a:	e822                	sd	s0,16(sp)
    80002b8c:	e426                	sd	s1,8(sp)
    80002b8e:	e04a                	sd	s2,0(sp)
    80002b90:	1000                	addi	s0,sp,32
    80002b92:	84ae                	mv	s1,a1
    80002b94:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b96:	00000097          	auipc	ra,0x0
    80002b9a:	eaa080e7          	jalr	-342(ra) # 80002a40 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b9e:	864a                	mv	a2,s2
    80002ba0:	85a6                	mv	a1,s1
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	f58080e7          	jalr	-168(ra) # 80002afa <fetchstr>
}
    80002baa:	60e2                	ld	ra,24(sp)
    80002bac:	6442                	ld	s0,16(sp)
    80002bae:	64a2                	ld	s1,8(sp)
    80002bb0:	6902                	ld	s2,0(sp)
    80002bb2:	6105                	addi	sp,sp,32
    80002bb4:	8082                	ret

0000000080002bb6 <syscall>:
  "sysinfo",
};

void
syscall(void)
{
    80002bb6:	7179                	addi	sp,sp,-48
    80002bb8:	f406                	sd	ra,40(sp)
    80002bba:	f022                	sd	s0,32(sp)
    80002bbc:	ec26                	sd	s1,24(sp)
    80002bbe:	e84a                	sd	s2,16(sp)
    80002bc0:	e44e                	sd	s3,8(sp)
    80002bc2:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002bc4:	fffff097          	auipc	ra,0xfffff
    80002bc8:	e64080e7          	jalr	-412(ra) # 80001a28 <myproc>
    80002bcc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bce:	05853903          	ld	s2,88(a0)
    80002bd2:	0a893783          	ld	a5,168(s2)
    80002bd6:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bda:	37fd                	addiw	a5,a5,-1
    80002bdc:	4759                	li	a4,22
    80002bde:	04f76963          	bltu	a4,a5,80002c30 <syscall+0x7a>
    80002be2:	00399713          	slli	a4,s3,0x3
    80002be6:	00006797          	auipc	a5,0x6
    80002bea:	90a78793          	addi	a5,a5,-1782 # 800084f0 <syscalls>
    80002bee:	97ba                	add	a5,a5,a4
    80002bf0:	639c                	ld	a5,0(a5)
    80002bf2:	cf9d                	beqz	a5,80002c30 <syscall+0x7a>
    p->trapframe->a0 = syscalls[num]();
    80002bf4:	9782                	jalr	a5
    80002bf6:	06a93823          	sd	a0,112(s2)
    if (p->tracemask & (1 << num)) {
    80002bfa:	4785                	li	a5,1
    80002bfc:	013797bb          	sllw	a5,a5,s3
    80002c00:	1684b703          	ld	a4,360(s1)
    80002c04:	8ff9                	and	a5,a5,a4
    80002c06:	c7a1                	beqz	a5,80002c4e <syscall+0x98>
      //this process traces this sys call num
      printf("%d: syscall %s -> %d\n", p->pid, sysnames[num], p->trapframe->a0);
    80002c08:	6cb8                	ld	a4,88(s1)
    80002c0a:	098e                	slli	s3,s3,0x3
    80002c0c:	00006797          	auipc	a5,0x6
    80002c10:	8e478793          	addi	a5,a5,-1820 # 800084f0 <syscalls>
    80002c14:	99be                	add	s3,s3,a5
    80002c16:	7b34                	ld	a3,112(a4)
    80002c18:	0c09b603          	ld	a2,192(s3)
    80002c1c:	5c8c                	lw	a1,56(s1)
    80002c1e:	00005517          	auipc	a0,0x5
    80002c22:	7d250513          	addi	a0,a0,2002 # 800083f0 <states.1707+0x148>
    80002c26:	ffffe097          	auipc	ra,0xffffe
    80002c2a:	96c080e7          	jalr	-1684(ra) # 80000592 <printf>
    80002c2e:	a005                	j	80002c4e <syscall+0x98>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c30:	86ce                	mv	a3,s3
    80002c32:	15848613          	addi	a2,s1,344
    80002c36:	5c8c                	lw	a1,56(s1)
    80002c38:	00005517          	auipc	a0,0x5
    80002c3c:	7d050513          	addi	a0,a0,2000 # 80008408 <states.1707+0x160>
    80002c40:	ffffe097          	auipc	ra,0xffffe
    80002c44:	952080e7          	jalr	-1710(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c48:	6cbc                	ld	a5,88(s1)
    80002c4a:	577d                	li	a4,-1
    80002c4c:	fbb8                	sd	a4,112(a5)
  }
}
    80002c4e:	70a2                	ld	ra,40(sp)
    80002c50:	7402                	ld	s0,32(sp)
    80002c52:	64e2                	ld	s1,24(sp)
    80002c54:	6942                	ld	s2,16(sp)
    80002c56:	69a2                	ld	s3,8(sp)
    80002c58:	6145                	addi	sp,sp,48
    80002c5a:	8082                	ret

0000000080002c5c <sys_exit>:
#include "proc.h"
#include "sysinfo.h"

uint64
sys_exit(void)
{
    80002c5c:	1101                	addi	sp,sp,-32
    80002c5e:	ec06                	sd	ra,24(sp)
    80002c60:	e822                	sd	s0,16(sp)
    80002c62:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c64:	fec40593          	addi	a1,s0,-20
    80002c68:	4501                	li	a0,0
    80002c6a:	00000097          	auipc	ra,0x0
    80002c6e:	ed8080e7          	jalr	-296(ra) # 80002b42 <argint>
    return -1;
    80002c72:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c74:	00054963          	bltz	a0,80002c86 <sys_exit+0x2a>
  exit(n);
    80002c78:	fec42503          	lw	a0,-20(s0)
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	47e080e7          	jalr	1150(ra) # 800020fa <exit>
  return 0;  // not reached
    80002c84:	4781                	li	a5,0
}
    80002c86:	853e                	mv	a0,a5
    80002c88:	60e2                	ld	ra,24(sp)
    80002c8a:	6442                	ld	s0,16(sp)
    80002c8c:	6105                	addi	sp,sp,32
    80002c8e:	8082                	ret

0000000080002c90 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c90:	1141                	addi	sp,sp,-16
    80002c92:	e406                	sd	ra,8(sp)
    80002c94:	e022                	sd	s0,0(sp)
    80002c96:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c98:	fffff097          	auipc	ra,0xfffff
    80002c9c:	d90080e7          	jalr	-624(ra) # 80001a28 <myproc>
}
    80002ca0:	5d08                	lw	a0,56(a0)
    80002ca2:	60a2                	ld	ra,8(sp)
    80002ca4:	6402                	ld	s0,0(sp)
    80002ca6:	0141                	addi	sp,sp,16
    80002ca8:	8082                	ret

0000000080002caa <sys_fork>:

uint64
sys_fork(void)
{
    80002caa:	1141                	addi	sp,sp,-16
    80002cac:	e406                	sd	ra,8(sp)
    80002cae:	e022                	sd	s0,0(sp)
    80002cb0:	0800                	addi	s0,sp,16
  return fork();
    80002cb2:	fffff097          	auipc	ra,0xfffff
    80002cb6:	13a080e7          	jalr	314(ra) # 80001dec <fork>
}
    80002cba:	60a2                	ld	ra,8(sp)
    80002cbc:	6402                	ld	s0,0(sp)
    80002cbe:	0141                	addi	sp,sp,16
    80002cc0:	8082                	ret

0000000080002cc2 <sys_wait>:

uint64
sys_wait(void)
{
    80002cc2:	1101                	addi	sp,sp,-32
    80002cc4:	ec06                	sd	ra,24(sp)
    80002cc6:	e822                	sd	s0,16(sp)
    80002cc8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cca:	fe840593          	addi	a1,s0,-24
    80002cce:	4501                	li	a0,0
    80002cd0:	00000097          	auipc	ra,0x0
    80002cd4:	e94080e7          	jalr	-364(ra) # 80002b64 <argaddr>
    80002cd8:	87aa                	mv	a5,a0
    return -1;
    80002cda:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cdc:	0007c863          	bltz	a5,80002cec <sys_wait+0x2a>
  return wait(p);
    80002ce0:	fe843503          	ld	a0,-24(s0)
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	5da080e7          	jalr	1498(ra) # 800022be <wait>
}
    80002cec:	60e2                	ld	ra,24(sp)
    80002cee:	6442                	ld	s0,16(sp)
    80002cf0:	6105                	addi	sp,sp,32
    80002cf2:	8082                	ret

0000000080002cf4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cf4:	7179                	addi	sp,sp,-48
    80002cf6:	f406                	sd	ra,40(sp)
    80002cf8:	f022                	sd	s0,32(sp)
    80002cfa:	ec26                	sd	s1,24(sp)
    80002cfc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cfe:	fdc40593          	addi	a1,s0,-36
    80002d02:	4501                	li	a0,0
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	e3e080e7          	jalr	-450(ra) # 80002b42 <argint>
    80002d0c:	87aa                	mv	a5,a0
    return -1;
    80002d0e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d10:	0207c063          	bltz	a5,80002d30 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d14:	fffff097          	auipc	ra,0xfffff
    80002d18:	d14080e7          	jalr	-748(ra) # 80001a28 <myproc>
    80002d1c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d1e:	fdc42503          	lw	a0,-36(s0)
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	056080e7          	jalr	86(ra) # 80001d78 <growproc>
    80002d2a:	00054863          	bltz	a0,80002d3a <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d2e:	8526                	mv	a0,s1
}
    80002d30:	70a2                	ld	ra,40(sp)
    80002d32:	7402                	ld	s0,32(sp)
    80002d34:	64e2                	ld	s1,24(sp)
    80002d36:	6145                	addi	sp,sp,48
    80002d38:	8082                	ret
    return -1;
    80002d3a:	557d                	li	a0,-1
    80002d3c:	bfd5                	j	80002d30 <sys_sbrk+0x3c>

0000000080002d3e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d3e:	7139                	addi	sp,sp,-64
    80002d40:	fc06                	sd	ra,56(sp)
    80002d42:	f822                	sd	s0,48(sp)
    80002d44:	f426                	sd	s1,40(sp)
    80002d46:	f04a                	sd	s2,32(sp)
    80002d48:	ec4e                	sd	s3,24(sp)
    80002d4a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d4c:	fcc40593          	addi	a1,s0,-52
    80002d50:	4501                	li	a0,0
    80002d52:	00000097          	auipc	ra,0x0
    80002d56:	df0080e7          	jalr	-528(ra) # 80002b42 <argint>
    return -1;
    80002d5a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d5c:	06054563          	bltz	a0,80002dc6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d60:	00015517          	auipc	a0,0x15
    80002d64:	c0850513          	addi	a0,a0,-1016 # 80017968 <tickslock>
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	ef2080e7          	jalr	-270(ra) # 80000c5a <acquire>
  ticks0 = ticks;
    80002d70:	00006917          	auipc	s2,0x6
    80002d74:	2b092903          	lw	s2,688(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002d78:	fcc42783          	lw	a5,-52(s0)
    80002d7c:	cf85                	beqz	a5,80002db4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d7e:	00015997          	auipc	s3,0x15
    80002d82:	bea98993          	addi	s3,s3,-1046 # 80017968 <tickslock>
    80002d86:	00006497          	auipc	s1,0x6
    80002d8a:	29a48493          	addi	s1,s1,666 # 80009020 <ticks>
    if(myproc()->killed){
    80002d8e:	fffff097          	auipc	ra,0xfffff
    80002d92:	c9a080e7          	jalr	-870(ra) # 80001a28 <myproc>
    80002d96:	591c                	lw	a5,48(a0)
    80002d98:	ef9d                	bnez	a5,80002dd6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d9a:	85ce                	mv	a1,s3
    80002d9c:	8526                	mv	a0,s1
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	4a2080e7          	jalr	1186(ra) # 80002240 <sleep>
  while(ticks - ticks0 < n){
    80002da6:	409c                	lw	a5,0(s1)
    80002da8:	412787bb          	subw	a5,a5,s2
    80002dac:	fcc42703          	lw	a4,-52(s0)
    80002db0:	fce7efe3          	bltu	a5,a4,80002d8e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002db4:	00015517          	auipc	a0,0x15
    80002db8:	bb450513          	addi	a0,a0,-1100 # 80017968 <tickslock>
    80002dbc:	ffffe097          	auipc	ra,0xffffe
    80002dc0:	f52080e7          	jalr	-174(ra) # 80000d0e <release>
  return 0;
    80002dc4:	4781                	li	a5,0
}
    80002dc6:	853e                	mv	a0,a5
    80002dc8:	70e2                	ld	ra,56(sp)
    80002dca:	7442                	ld	s0,48(sp)
    80002dcc:	74a2                	ld	s1,40(sp)
    80002dce:	7902                	ld	s2,32(sp)
    80002dd0:	69e2                	ld	s3,24(sp)
    80002dd2:	6121                	addi	sp,sp,64
    80002dd4:	8082                	ret
      release(&tickslock);
    80002dd6:	00015517          	auipc	a0,0x15
    80002dda:	b9250513          	addi	a0,a0,-1134 # 80017968 <tickslock>
    80002dde:	ffffe097          	auipc	ra,0xffffe
    80002de2:	f30080e7          	jalr	-208(ra) # 80000d0e <release>
      return -1;
    80002de6:	57fd                	li	a5,-1
    80002de8:	bff9                	j	80002dc6 <sys_sleep+0x88>

0000000080002dea <sys_kill>:

uint64
sys_kill(void)
{
    80002dea:	1101                	addi	sp,sp,-32
    80002dec:	ec06                	sd	ra,24(sp)
    80002dee:	e822                	sd	s0,16(sp)
    80002df0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002df2:	fec40593          	addi	a1,s0,-20
    80002df6:	4501                	li	a0,0
    80002df8:	00000097          	auipc	ra,0x0
    80002dfc:	d4a080e7          	jalr	-694(ra) # 80002b42 <argint>
    80002e00:	87aa                	mv	a5,a0
    return -1;
    80002e02:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e04:	0007c863          	bltz	a5,80002e14 <sys_kill+0x2a>
  return kill(pid);
    80002e08:	fec42503          	lw	a0,-20(s0)
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	624080e7          	jalr	1572(ra) # 80002430 <kill>
}
    80002e14:	60e2                	ld	ra,24(sp)
    80002e16:	6442                	ld	s0,16(sp)
    80002e18:	6105                	addi	sp,sp,32
    80002e1a:	8082                	ret

0000000080002e1c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e1c:	1101                	addi	sp,sp,-32
    80002e1e:	ec06                	sd	ra,24(sp)
    80002e20:	e822                	sd	s0,16(sp)
    80002e22:	e426                	sd	s1,8(sp)
    80002e24:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e26:	00015517          	auipc	a0,0x15
    80002e2a:	b4250513          	addi	a0,a0,-1214 # 80017968 <tickslock>
    80002e2e:	ffffe097          	auipc	ra,0xffffe
    80002e32:	e2c080e7          	jalr	-468(ra) # 80000c5a <acquire>
  xticks = ticks;
    80002e36:	00006497          	auipc	s1,0x6
    80002e3a:	1ea4a483          	lw	s1,490(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e3e:	00015517          	auipc	a0,0x15
    80002e42:	b2a50513          	addi	a0,a0,-1238 # 80017968 <tickslock>
    80002e46:	ffffe097          	auipc	ra,0xffffe
    80002e4a:	ec8080e7          	jalr	-312(ra) # 80000d0e <release>
  return xticks;
}
    80002e4e:	02049513          	slli	a0,s1,0x20
    80002e52:	9101                	srli	a0,a0,0x20
    80002e54:	60e2                	ld	ra,24(sp)
    80002e56:	6442                	ld	s0,16(sp)
    80002e58:	64a2                	ld	s1,8(sp)
    80002e5a:	6105                	addi	sp,sp,32
    80002e5c:	8082                	ret

0000000080002e5e <sys_trace>:

// click the sys call number in p->tracemask
// so as to tracing its calling afterwards
uint64
sys_trace(void) {
    80002e5e:	1101                	addi	sp,sp,-32
    80002e60:	ec06                	sd	ra,24(sp)
    80002e62:	e822                	sd	s0,16(sp)
    80002e64:	1000                	addi	s0,sp,32
  int trace_sys_mask;
  if (argint(0, &trace_sys_mask) < 0)
    80002e66:	fec40593          	addi	a1,s0,-20
    80002e6a:	4501                	li	a0,0
    80002e6c:	00000097          	auipc	ra,0x0
    80002e70:	cd6080e7          	jalr	-810(ra) # 80002b42 <argint>
    return -1;
    80002e74:	57fd                	li	a5,-1
  if (argint(0, &trace_sys_mask) < 0)
    80002e76:	00054e63          	bltz	a0,80002e92 <sys_trace+0x34>
  myproc()->tracemask |= trace_sys_mask;
    80002e7a:	fffff097          	auipc	ra,0xfffff
    80002e7e:	bae080e7          	jalr	-1106(ra) # 80001a28 <myproc>
    80002e82:	fec42703          	lw	a4,-20(s0)
    80002e86:	16853783          	ld	a5,360(a0)
    80002e8a:	8fd9                	or	a5,a5,a4
    80002e8c:	16f53423          	sd	a5,360(a0)
  return 0;
    80002e90:	4781                	li	a5,0
}
    80002e92:	853e                	mv	a0,a5
    80002e94:	60e2                	ld	ra,24(sp)
    80002e96:	6442                	ld	s0,16(sp)
    80002e98:	6105                	addi	sp,sp,32
    80002e9a:	8082                	ret

0000000080002e9c <sys_sysinfo>:

// collect system info
uint64
sys_sysinfo(void) {
    80002e9c:	7139                	addi	sp,sp,-64
    80002e9e:	fc06                	sd	ra,56(sp)
    80002ea0:	f822                	sd	s0,48(sp)
    80002ea2:	f426                	sd	s1,40(sp)
    80002ea4:	0080                	addi	s0,sp,64
  struct proc *my_proc = myproc();
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	b82080e7          	jalr	-1150(ra) # 80001a28 <myproc>
    80002eae:	84aa                	mv	s1,a0
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002eb0:	fd840593          	addi	a1,s0,-40
    80002eb4:	4501                	li	a0,0
    80002eb6:	00000097          	auipc	ra,0x0
    80002eba:	cae080e7          	jalr	-850(ra) # 80002b64 <argaddr>
    return -1;
    80002ebe:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    80002ec0:	02054a63          	bltz	a0,80002ef4 <sys_sysinfo+0x58>
  // construct in kernel first
  struct sysinfo s;
  s.freemem = kfreemem();
    80002ec4:	ffffe097          	auipc	ra,0xffffe
    80002ec8:	cbc080e7          	jalr	-836(ra) # 80000b80 <kfreemem>
    80002ecc:	fca43423          	sd	a0,-56(s0)
  s.nproc = count_free_proc();
    80002ed0:	fffff097          	auipc	ra,0xfffff
    80002ed4:	72c080e7          	jalr	1836(ra) # 800025fc <count_free_proc>
    80002ed8:	fca43823          	sd	a0,-48(s0)
  // copy to user space
  if(copyout(my_proc->pagetable, p, (char *)&s, sizeof(s)) < 0)
    80002edc:	46c1                	li	a3,16
    80002ede:	fc840613          	addi	a2,s0,-56
    80002ee2:	fd843583          	ld	a1,-40(s0)
    80002ee6:	68a8                	ld	a0,80(s1)
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	834080e7          	jalr	-1996(ra) # 8000171c <copyout>
    80002ef0:	43f55793          	srai	a5,a0,0x3f
    return -1;
  return 0;
    80002ef4:	853e                	mv	a0,a5
    80002ef6:	70e2                	ld	ra,56(sp)
    80002ef8:	7442                	ld	s0,48(sp)
    80002efa:	74a2                	ld	s1,40(sp)
    80002efc:	6121                	addi	sp,sp,64
    80002efe:	8082                	ret

0000000080002f00 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f00:	7179                	addi	sp,sp,-48
    80002f02:	f406                	sd	ra,40(sp)
    80002f04:	f022                	sd	s0,32(sp)
    80002f06:	ec26                	sd	s1,24(sp)
    80002f08:	e84a                	sd	s2,16(sp)
    80002f0a:	e44e                	sd	s3,8(sp)
    80002f0c:	e052                	sd	s4,0(sp)
    80002f0e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f10:	00005597          	auipc	a1,0x5
    80002f14:	76058593          	addi	a1,a1,1888 # 80008670 <sysnames+0xc0>
    80002f18:	00015517          	auipc	a0,0x15
    80002f1c:	a6850513          	addi	a0,a0,-1432 # 80017980 <bcache>
    80002f20:	ffffe097          	auipc	ra,0xffffe
    80002f24:	caa080e7          	jalr	-854(ra) # 80000bca <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f28:	0001d797          	auipc	a5,0x1d
    80002f2c:	a5878793          	addi	a5,a5,-1448 # 8001f980 <bcache+0x8000>
    80002f30:	0001d717          	auipc	a4,0x1d
    80002f34:	cb870713          	addi	a4,a4,-840 # 8001fbe8 <bcache+0x8268>
    80002f38:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f3c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f40:	00015497          	auipc	s1,0x15
    80002f44:	a5848493          	addi	s1,s1,-1448 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80002f48:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f4a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f4c:	00005a17          	auipc	s4,0x5
    80002f50:	72ca0a13          	addi	s4,s4,1836 # 80008678 <sysnames+0xc8>
    b->next = bcache.head.next;
    80002f54:	2b893783          	ld	a5,696(s2)
    80002f58:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f5a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f5e:	85d2                	mv	a1,s4
    80002f60:	01048513          	addi	a0,s1,16
    80002f64:	00001097          	auipc	ra,0x1
    80002f68:	4ac080e7          	jalr	1196(ra) # 80004410 <initsleeplock>
    bcache.head.next->prev = b;
    80002f6c:	2b893783          	ld	a5,696(s2)
    80002f70:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f72:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f76:	45848493          	addi	s1,s1,1112
    80002f7a:	fd349de3          	bne	s1,s3,80002f54 <binit+0x54>
  }
}
    80002f7e:	70a2                	ld	ra,40(sp)
    80002f80:	7402                	ld	s0,32(sp)
    80002f82:	64e2                	ld	s1,24(sp)
    80002f84:	6942                	ld	s2,16(sp)
    80002f86:	69a2                	ld	s3,8(sp)
    80002f88:	6a02                	ld	s4,0(sp)
    80002f8a:	6145                	addi	sp,sp,48
    80002f8c:	8082                	ret

0000000080002f8e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f8e:	7179                	addi	sp,sp,-48
    80002f90:	f406                	sd	ra,40(sp)
    80002f92:	f022                	sd	s0,32(sp)
    80002f94:	ec26                	sd	s1,24(sp)
    80002f96:	e84a                	sd	s2,16(sp)
    80002f98:	e44e                	sd	s3,8(sp)
    80002f9a:	1800                	addi	s0,sp,48
    80002f9c:	89aa                	mv	s3,a0
    80002f9e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fa0:	00015517          	auipc	a0,0x15
    80002fa4:	9e050513          	addi	a0,a0,-1568 # 80017980 <bcache>
    80002fa8:	ffffe097          	auipc	ra,0xffffe
    80002fac:	cb2080e7          	jalr	-846(ra) # 80000c5a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fb0:	0001d497          	auipc	s1,0x1d
    80002fb4:	c884b483          	ld	s1,-888(s1) # 8001fc38 <bcache+0x82b8>
    80002fb8:	0001d797          	auipc	a5,0x1d
    80002fbc:	c3078793          	addi	a5,a5,-976 # 8001fbe8 <bcache+0x8268>
    80002fc0:	02f48f63          	beq	s1,a5,80002ffe <bread+0x70>
    80002fc4:	873e                	mv	a4,a5
    80002fc6:	a021                	j	80002fce <bread+0x40>
    80002fc8:	68a4                	ld	s1,80(s1)
    80002fca:	02e48a63          	beq	s1,a4,80002ffe <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fce:	449c                	lw	a5,8(s1)
    80002fd0:	ff379ce3          	bne	a5,s3,80002fc8 <bread+0x3a>
    80002fd4:	44dc                	lw	a5,12(s1)
    80002fd6:	ff2799e3          	bne	a5,s2,80002fc8 <bread+0x3a>
      b->refcnt++;
    80002fda:	40bc                	lw	a5,64(s1)
    80002fdc:	2785                	addiw	a5,a5,1
    80002fde:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe0:	00015517          	auipc	a0,0x15
    80002fe4:	9a050513          	addi	a0,a0,-1632 # 80017980 <bcache>
    80002fe8:	ffffe097          	auipc	ra,0xffffe
    80002fec:	d26080e7          	jalr	-730(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    80002ff0:	01048513          	addi	a0,s1,16
    80002ff4:	00001097          	auipc	ra,0x1
    80002ff8:	456080e7          	jalr	1110(ra) # 8000444a <acquiresleep>
      return b;
    80002ffc:	a8b9                	j	8000305a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ffe:	0001d497          	auipc	s1,0x1d
    80003002:	c324b483          	ld	s1,-974(s1) # 8001fc30 <bcache+0x82b0>
    80003006:	0001d797          	auipc	a5,0x1d
    8000300a:	be278793          	addi	a5,a5,-1054 # 8001fbe8 <bcache+0x8268>
    8000300e:	00f48863          	beq	s1,a5,8000301e <bread+0x90>
    80003012:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003014:	40bc                	lw	a5,64(s1)
    80003016:	cf81                	beqz	a5,8000302e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003018:	64a4                	ld	s1,72(s1)
    8000301a:	fee49de3          	bne	s1,a4,80003014 <bread+0x86>
  panic("bget: no buffers");
    8000301e:	00005517          	auipc	a0,0x5
    80003022:	66250513          	addi	a0,a0,1634 # 80008680 <sysnames+0xd0>
    80003026:	ffffd097          	auipc	ra,0xffffd
    8000302a:	522080e7          	jalr	1314(ra) # 80000548 <panic>
      b->dev = dev;
    8000302e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003032:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003036:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000303a:	4785                	li	a5,1
    8000303c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000303e:	00015517          	auipc	a0,0x15
    80003042:	94250513          	addi	a0,a0,-1726 # 80017980 <bcache>
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	cc8080e7          	jalr	-824(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    8000304e:	01048513          	addi	a0,s1,16
    80003052:	00001097          	auipc	ra,0x1
    80003056:	3f8080e7          	jalr	1016(ra) # 8000444a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000305a:	409c                	lw	a5,0(s1)
    8000305c:	cb89                	beqz	a5,8000306e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000305e:	8526                	mv	a0,s1
    80003060:	70a2                	ld	ra,40(sp)
    80003062:	7402                	ld	s0,32(sp)
    80003064:	64e2                	ld	s1,24(sp)
    80003066:	6942                	ld	s2,16(sp)
    80003068:	69a2                	ld	s3,8(sp)
    8000306a:	6145                	addi	sp,sp,48
    8000306c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000306e:	4581                	li	a1,0
    80003070:	8526                	mv	a0,s1
    80003072:	00003097          	auipc	ra,0x3
    80003076:	f3a080e7          	jalr	-198(ra) # 80005fac <virtio_disk_rw>
    b->valid = 1;
    8000307a:	4785                	li	a5,1
    8000307c:	c09c                	sw	a5,0(s1)
  return b;
    8000307e:	b7c5                	j	8000305e <bread+0xd0>

0000000080003080 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003080:	1101                	addi	sp,sp,-32
    80003082:	ec06                	sd	ra,24(sp)
    80003084:	e822                	sd	s0,16(sp)
    80003086:	e426                	sd	s1,8(sp)
    80003088:	1000                	addi	s0,sp,32
    8000308a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000308c:	0541                	addi	a0,a0,16
    8000308e:	00001097          	auipc	ra,0x1
    80003092:	456080e7          	jalr	1110(ra) # 800044e4 <holdingsleep>
    80003096:	cd01                	beqz	a0,800030ae <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003098:	4585                	li	a1,1
    8000309a:	8526                	mv	a0,s1
    8000309c:	00003097          	auipc	ra,0x3
    800030a0:	f10080e7          	jalr	-240(ra) # 80005fac <virtio_disk_rw>
}
    800030a4:	60e2                	ld	ra,24(sp)
    800030a6:	6442                	ld	s0,16(sp)
    800030a8:	64a2                	ld	s1,8(sp)
    800030aa:	6105                	addi	sp,sp,32
    800030ac:	8082                	ret
    panic("bwrite");
    800030ae:	00005517          	auipc	a0,0x5
    800030b2:	5ea50513          	addi	a0,a0,1514 # 80008698 <sysnames+0xe8>
    800030b6:	ffffd097          	auipc	ra,0xffffd
    800030ba:	492080e7          	jalr	1170(ra) # 80000548 <panic>

00000000800030be <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030be:	1101                	addi	sp,sp,-32
    800030c0:	ec06                	sd	ra,24(sp)
    800030c2:	e822                	sd	s0,16(sp)
    800030c4:	e426                	sd	s1,8(sp)
    800030c6:	e04a                	sd	s2,0(sp)
    800030c8:	1000                	addi	s0,sp,32
    800030ca:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030cc:	01050913          	addi	s2,a0,16
    800030d0:	854a                	mv	a0,s2
    800030d2:	00001097          	auipc	ra,0x1
    800030d6:	412080e7          	jalr	1042(ra) # 800044e4 <holdingsleep>
    800030da:	c92d                	beqz	a0,8000314c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030dc:	854a                	mv	a0,s2
    800030de:	00001097          	auipc	ra,0x1
    800030e2:	3c2080e7          	jalr	962(ra) # 800044a0 <releasesleep>

  acquire(&bcache.lock);
    800030e6:	00015517          	auipc	a0,0x15
    800030ea:	89a50513          	addi	a0,a0,-1894 # 80017980 <bcache>
    800030ee:	ffffe097          	auipc	ra,0xffffe
    800030f2:	b6c080e7          	jalr	-1172(ra) # 80000c5a <acquire>
  b->refcnt--;
    800030f6:	40bc                	lw	a5,64(s1)
    800030f8:	37fd                	addiw	a5,a5,-1
    800030fa:	0007871b          	sext.w	a4,a5
    800030fe:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003100:	eb05                	bnez	a4,80003130 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003102:	68bc                	ld	a5,80(s1)
    80003104:	64b8                	ld	a4,72(s1)
    80003106:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003108:	64bc                	ld	a5,72(s1)
    8000310a:	68b8                	ld	a4,80(s1)
    8000310c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000310e:	0001d797          	auipc	a5,0x1d
    80003112:	87278793          	addi	a5,a5,-1934 # 8001f980 <bcache+0x8000>
    80003116:	2b87b703          	ld	a4,696(a5)
    8000311a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000311c:	0001d717          	auipc	a4,0x1d
    80003120:	acc70713          	addi	a4,a4,-1332 # 8001fbe8 <bcache+0x8268>
    80003124:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003126:	2b87b703          	ld	a4,696(a5)
    8000312a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000312c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003130:	00015517          	auipc	a0,0x15
    80003134:	85050513          	addi	a0,a0,-1968 # 80017980 <bcache>
    80003138:	ffffe097          	auipc	ra,0xffffe
    8000313c:	bd6080e7          	jalr	-1066(ra) # 80000d0e <release>
}
    80003140:	60e2                	ld	ra,24(sp)
    80003142:	6442                	ld	s0,16(sp)
    80003144:	64a2                	ld	s1,8(sp)
    80003146:	6902                	ld	s2,0(sp)
    80003148:	6105                	addi	sp,sp,32
    8000314a:	8082                	ret
    panic("brelse");
    8000314c:	00005517          	auipc	a0,0x5
    80003150:	55450513          	addi	a0,a0,1364 # 800086a0 <sysnames+0xf0>
    80003154:	ffffd097          	auipc	ra,0xffffd
    80003158:	3f4080e7          	jalr	1012(ra) # 80000548 <panic>

000000008000315c <bpin>:

void
bpin(struct buf *b) {
    8000315c:	1101                	addi	sp,sp,-32
    8000315e:	ec06                	sd	ra,24(sp)
    80003160:	e822                	sd	s0,16(sp)
    80003162:	e426                	sd	s1,8(sp)
    80003164:	1000                	addi	s0,sp,32
    80003166:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003168:	00015517          	auipc	a0,0x15
    8000316c:	81850513          	addi	a0,a0,-2024 # 80017980 <bcache>
    80003170:	ffffe097          	auipc	ra,0xffffe
    80003174:	aea080e7          	jalr	-1302(ra) # 80000c5a <acquire>
  b->refcnt++;
    80003178:	40bc                	lw	a5,64(s1)
    8000317a:	2785                	addiw	a5,a5,1
    8000317c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000317e:	00015517          	auipc	a0,0x15
    80003182:	80250513          	addi	a0,a0,-2046 # 80017980 <bcache>
    80003186:	ffffe097          	auipc	ra,0xffffe
    8000318a:	b88080e7          	jalr	-1144(ra) # 80000d0e <release>
}
    8000318e:	60e2                	ld	ra,24(sp)
    80003190:	6442                	ld	s0,16(sp)
    80003192:	64a2                	ld	s1,8(sp)
    80003194:	6105                	addi	sp,sp,32
    80003196:	8082                	ret

0000000080003198 <bunpin>:

void
bunpin(struct buf *b) {
    80003198:	1101                	addi	sp,sp,-32
    8000319a:	ec06                	sd	ra,24(sp)
    8000319c:	e822                	sd	s0,16(sp)
    8000319e:	e426                	sd	s1,8(sp)
    800031a0:	1000                	addi	s0,sp,32
    800031a2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031a4:	00014517          	auipc	a0,0x14
    800031a8:	7dc50513          	addi	a0,a0,2012 # 80017980 <bcache>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	aae080e7          	jalr	-1362(ra) # 80000c5a <acquire>
  b->refcnt--;
    800031b4:	40bc                	lw	a5,64(s1)
    800031b6:	37fd                	addiw	a5,a5,-1
    800031b8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031ba:	00014517          	auipc	a0,0x14
    800031be:	7c650513          	addi	a0,a0,1990 # 80017980 <bcache>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	b4c080e7          	jalr	-1204(ra) # 80000d0e <release>
}
    800031ca:	60e2                	ld	ra,24(sp)
    800031cc:	6442                	ld	s0,16(sp)
    800031ce:	64a2                	ld	s1,8(sp)
    800031d0:	6105                	addi	sp,sp,32
    800031d2:	8082                	ret

00000000800031d4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031d4:	1101                	addi	sp,sp,-32
    800031d6:	ec06                	sd	ra,24(sp)
    800031d8:	e822                	sd	s0,16(sp)
    800031da:	e426                	sd	s1,8(sp)
    800031dc:	e04a                	sd	s2,0(sp)
    800031de:	1000                	addi	s0,sp,32
    800031e0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031e2:	00d5d59b          	srliw	a1,a1,0xd
    800031e6:	0001d797          	auipc	a5,0x1d
    800031ea:	e767a783          	lw	a5,-394(a5) # 8002005c <sb+0x1c>
    800031ee:	9dbd                	addw	a1,a1,a5
    800031f0:	00000097          	auipc	ra,0x0
    800031f4:	d9e080e7          	jalr	-610(ra) # 80002f8e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031f8:	0074f713          	andi	a4,s1,7
    800031fc:	4785                	li	a5,1
    800031fe:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003202:	14ce                	slli	s1,s1,0x33
    80003204:	90d9                	srli	s1,s1,0x36
    80003206:	00950733          	add	a4,a0,s1
    8000320a:	05874703          	lbu	a4,88(a4)
    8000320e:	00e7f6b3          	and	a3,a5,a4
    80003212:	c69d                	beqz	a3,80003240 <bfree+0x6c>
    80003214:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003216:	94aa                	add	s1,s1,a0
    80003218:	fff7c793          	not	a5,a5
    8000321c:	8ff9                	and	a5,a5,a4
    8000321e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003222:	00001097          	auipc	ra,0x1
    80003226:	100080e7          	jalr	256(ra) # 80004322 <log_write>
  brelse(bp);
    8000322a:	854a                	mv	a0,s2
    8000322c:	00000097          	auipc	ra,0x0
    80003230:	e92080e7          	jalr	-366(ra) # 800030be <brelse>
}
    80003234:	60e2                	ld	ra,24(sp)
    80003236:	6442                	ld	s0,16(sp)
    80003238:	64a2                	ld	s1,8(sp)
    8000323a:	6902                	ld	s2,0(sp)
    8000323c:	6105                	addi	sp,sp,32
    8000323e:	8082                	ret
    panic("freeing free block");
    80003240:	00005517          	auipc	a0,0x5
    80003244:	46850513          	addi	a0,a0,1128 # 800086a8 <sysnames+0xf8>
    80003248:	ffffd097          	auipc	ra,0xffffd
    8000324c:	300080e7          	jalr	768(ra) # 80000548 <panic>

0000000080003250 <balloc>:
{
    80003250:	711d                	addi	sp,sp,-96
    80003252:	ec86                	sd	ra,88(sp)
    80003254:	e8a2                	sd	s0,80(sp)
    80003256:	e4a6                	sd	s1,72(sp)
    80003258:	e0ca                	sd	s2,64(sp)
    8000325a:	fc4e                	sd	s3,56(sp)
    8000325c:	f852                	sd	s4,48(sp)
    8000325e:	f456                	sd	s5,40(sp)
    80003260:	f05a                	sd	s6,32(sp)
    80003262:	ec5e                	sd	s7,24(sp)
    80003264:	e862                	sd	s8,16(sp)
    80003266:	e466                	sd	s9,8(sp)
    80003268:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000326a:	0001d797          	auipc	a5,0x1d
    8000326e:	dda7a783          	lw	a5,-550(a5) # 80020044 <sb+0x4>
    80003272:	cbd1                	beqz	a5,80003306 <balloc+0xb6>
    80003274:	8baa                	mv	s7,a0
    80003276:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003278:	0001db17          	auipc	s6,0x1d
    8000327c:	dc8b0b13          	addi	s6,s6,-568 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003280:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003282:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003284:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003286:	6c89                	lui	s9,0x2
    80003288:	a831                	j	800032a4 <balloc+0x54>
    brelse(bp);
    8000328a:	854a                	mv	a0,s2
    8000328c:	00000097          	auipc	ra,0x0
    80003290:	e32080e7          	jalr	-462(ra) # 800030be <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003294:	015c87bb          	addw	a5,s9,s5
    80003298:	00078a9b          	sext.w	s5,a5
    8000329c:	004b2703          	lw	a4,4(s6)
    800032a0:	06eaf363          	bgeu	s5,a4,80003306 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032a4:	41fad79b          	sraiw	a5,s5,0x1f
    800032a8:	0137d79b          	srliw	a5,a5,0x13
    800032ac:	015787bb          	addw	a5,a5,s5
    800032b0:	40d7d79b          	sraiw	a5,a5,0xd
    800032b4:	01cb2583          	lw	a1,28(s6)
    800032b8:	9dbd                	addw	a1,a1,a5
    800032ba:	855e                	mv	a0,s7
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	cd2080e7          	jalr	-814(ra) # 80002f8e <bread>
    800032c4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032c6:	004b2503          	lw	a0,4(s6)
    800032ca:	000a849b          	sext.w	s1,s5
    800032ce:	8662                	mv	a2,s8
    800032d0:	faa4fde3          	bgeu	s1,a0,8000328a <balloc+0x3a>
      m = 1 << (bi % 8);
    800032d4:	41f6579b          	sraiw	a5,a2,0x1f
    800032d8:	01d7d69b          	srliw	a3,a5,0x1d
    800032dc:	00c6873b          	addw	a4,a3,a2
    800032e0:	00777793          	andi	a5,a4,7
    800032e4:	9f95                	subw	a5,a5,a3
    800032e6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032ea:	4037571b          	sraiw	a4,a4,0x3
    800032ee:	00e906b3          	add	a3,s2,a4
    800032f2:	0586c683          	lbu	a3,88(a3)
    800032f6:	00d7f5b3          	and	a1,a5,a3
    800032fa:	cd91                	beqz	a1,80003316 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032fc:	2605                	addiw	a2,a2,1
    800032fe:	2485                	addiw	s1,s1,1
    80003300:	fd4618e3          	bne	a2,s4,800032d0 <balloc+0x80>
    80003304:	b759                	j	8000328a <balloc+0x3a>
  panic("balloc: out of blocks");
    80003306:	00005517          	auipc	a0,0x5
    8000330a:	3ba50513          	addi	a0,a0,954 # 800086c0 <sysnames+0x110>
    8000330e:	ffffd097          	auipc	ra,0xffffd
    80003312:	23a080e7          	jalr	570(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003316:	974a                	add	a4,a4,s2
    80003318:	8fd5                	or	a5,a5,a3
    8000331a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000331e:	854a                	mv	a0,s2
    80003320:	00001097          	auipc	ra,0x1
    80003324:	002080e7          	jalr	2(ra) # 80004322 <log_write>
        brelse(bp);
    80003328:	854a                	mv	a0,s2
    8000332a:	00000097          	auipc	ra,0x0
    8000332e:	d94080e7          	jalr	-620(ra) # 800030be <brelse>
  bp = bread(dev, bno);
    80003332:	85a6                	mv	a1,s1
    80003334:	855e                	mv	a0,s7
    80003336:	00000097          	auipc	ra,0x0
    8000333a:	c58080e7          	jalr	-936(ra) # 80002f8e <bread>
    8000333e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003340:	40000613          	li	a2,1024
    80003344:	4581                	li	a1,0
    80003346:	05850513          	addi	a0,a0,88
    8000334a:	ffffe097          	auipc	ra,0xffffe
    8000334e:	a0c080e7          	jalr	-1524(ra) # 80000d56 <memset>
  log_write(bp);
    80003352:	854a                	mv	a0,s2
    80003354:	00001097          	auipc	ra,0x1
    80003358:	fce080e7          	jalr	-50(ra) # 80004322 <log_write>
  brelse(bp);
    8000335c:	854a                	mv	a0,s2
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	d60080e7          	jalr	-672(ra) # 800030be <brelse>
}
    80003366:	8526                	mv	a0,s1
    80003368:	60e6                	ld	ra,88(sp)
    8000336a:	6446                	ld	s0,80(sp)
    8000336c:	64a6                	ld	s1,72(sp)
    8000336e:	6906                	ld	s2,64(sp)
    80003370:	79e2                	ld	s3,56(sp)
    80003372:	7a42                	ld	s4,48(sp)
    80003374:	7aa2                	ld	s5,40(sp)
    80003376:	7b02                	ld	s6,32(sp)
    80003378:	6be2                	ld	s7,24(sp)
    8000337a:	6c42                	ld	s8,16(sp)
    8000337c:	6ca2                	ld	s9,8(sp)
    8000337e:	6125                	addi	sp,sp,96
    80003380:	8082                	ret

0000000080003382 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003382:	7179                	addi	sp,sp,-48
    80003384:	f406                	sd	ra,40(sp)
    80003386:	f022                	sd	s0,32(sp)
    80003388:	ec26                	sd	s1,24(sp)
    8000338a:	e84a                	sd	s2,16(sp)
    8000338c:	e44e                	sd	s3,8(sp)
    8000338e:	e052                	sd	s4,0(sp)
    80003390:	1800                	addi	s0,sp,48
    80003392:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003394:	47ad                	li	a5,11
    80003396:	04b7fe63          	bgeu	a5,a1,800033f2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000339a:	ff45849b          	addiw	s1,a1,-12
    8000339e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033a2:	0ff00793          	li	a5,255
    800033a6:	0ae7e363          	bltu	a5,a4,8000344c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033aa:	08052583          	lw	a1,128(a0)
    800033ae:	c5ad                	beqz	a1,80003418 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033b0:	00092503          	lw	a0,0(s2)
    800033b4:	00000097          	auipc	ra,0x0
    800033b8:	bda080e7          	jalr	-1062(ra) # 80002f8e <bread>
    800033bc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033be:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033c2:	02049593          	slli	a1,s1,0x20
    800033c6:	9181                	srli	a1,a1,0x20
    800033c8:	058a                	slli	a1,a1,0x2
    800033ca:	00b784b3          	add	s1,a5,a1
    800033ce:	0004a983          	lw	s3,0(s1)
    800033d2:	04098d63          	beqz	s3,8000342c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033d6:	8552                	mv	a0,s4
    800033d8:	00000097          	auipc	ra,0x0
    800033dc:	ce6080e7          	jalr	-794(ra) # 800030be <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033e0:	854e                	mv	a0,s3
    800033e2:	70a2                	ld	ra,40(sp)
    800033e4:	7402                	ld	s0,32(sp)
    800033e6:	64e2                	ld	s1,24(sp)
    800033e8:	6942                	ld	s2,16(sp)
    800033ea:	69a2                	ld	s3,8(sp)
    800033ec:	6a02                	ld	s4,0(sp)
    800033ee:	6145                	addi	sp,sp,48
    800033f0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033f2:	02059493          	slli	s1,a1,0x20
    800033f6:	9081                	srli	s1,s1,0x20
    800033f8:	048a                	slli	s1,s1,0x2
    800033fa:	94aa                	add	s1,s1,a0
    800033fc:	0504a983          	lw	s3,80(s1)
    80003400:	fe0990e3          	bnez	s3,800033e0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003404:	4108                	lw	a0,0(a0)
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	e4a080e7          	jalr	-438(ra) # 80003250 <balloc>
    8000340e:	0005099b          	sext.w	s3,a0
    80003412:	0534a823          	sw	s3,80(s1)
    80003416:	b7e9                	j	800033e0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003418:	4108                	lw	a0,0(a0)
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	e36080e7          	jalr	-458(ra) # 80003250 <balloc>
    80003422:	0005059b          	sext.w	a1,a0
    80003426:	08b92023          	sw	a1,128(s2)
    8000342a:	b759                	j	800033b0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000342c:	00092503          	lw	a0,0(s2)
    80003430:	00000097          	auipc	ra,0x0
    80003434:	e20080e7          	jalr	-480(ra) # 80003250 <balloc>
    80003438:	0005099b          	sext.w	s3,a0
    8000343c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003440:	8552                	mv	a0,s4
    80003442:	00001097          	auipc	ra,0x1
    80003446:	ee0080e7          	jalr	-288(ra) # 80004322 <log_write>
    8000344a:	b771                	j	800033d6 <bmap+0x54>
  panic("bmap: out of range");
    8000344c:	00005517          	auipc	a0,0x5
    80003450:	28c50513          	addi	a0,a0,652 # 800086d8 <sysnames+0x128>
    80003454:	ffffd097          	auipc	ra,0xffffd
    80003458:	0f4080e7          	jalr	244(ra) # 80000548 <panic>

000000008000345c <iget>:
{
    8000345c:	7179                	addi	sp,sp,-48
    8000345e:	f406                	sd	ra,40(sp)
    80003460:	f022                	sd	s0,32(sp)
    80003462:	ec26                	sd	s1,24(sp)
    80003464:	e84a                	sd	s2,16(sp)
    80003466:	e44e                	sd	s3,8(sp)
    80003468:	e052                	sd	s4,0(sp)
    8000346a:	1800                	addi	s0,sp,48
    8000346c:	89aa                	mv	s3,a0
    8000346e:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003470:	0001d517          	auipc	a0,0x1d
    80003474:	bf050513          	addi	a0,a0,-1040 # 80020060 <icache>
    80003478:	ffffd097          	auipc	ra,0xffffd
    8000347c:	7e2080e7          	jalr	2018(ra) # 80000c5a <acquire>
  empty = 0;
    80003480:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003482:	0001d497          	auipc	s1,0x1d
    80003486:	bf648493          	addi	s1,s1,-1034 # 80020078 <icache+0x18>
    8000348a:	0001e697          	auipc	a3,0x1e
    8000348e:	67e68693          	addi	a3,a3,1662 # 80021b08 <log>
    80003492:	a039                	j	800034a0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003494:	02090b63          	beqz	s2,800034ca <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003498:	08848493          	addi	s1,s1,136
    8000349c:	02d48a63          	beq	s1,a3,800034d0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034a0:	449c                	lw	a5,8(s1)
    800034a2:	fef059e3          	blez	a5,80003494 <iget+0x38>
    800034a6:	4098                	lw	a4,0(s1)
    800034a8:	ff3716e3          	bne	a4,s3,80003494 <iget+0x38>
    800034ac:	40d8                	lw	a4,4(s1)
    800034ae:	ff4713e3          	bne	a4,s4,80003494 <iget+0x38>
      ip->ref++;
    800034b2:	2785                	addiw	a5,a5,1
    800034b4:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800034b6:	0001d517          	auipc	a0,0x1d
    800034ba:	baa50513          	addi	a0,a0,-1110 # 80020060 <icache>
    800034be:	ffffe097          	auipc	ra,0xffffe
    800034c2:	850080e7          	jalr	-1968(ra) # 80000d0e <release>
      return ip;
    800034c6:	8926                	mv	s2,s1
    800034c8:	a03d                	j	800034f6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ca:	f7f9                	bnez	a5,80003498 <iget+0x3c>
    800034cc:	8926                	mv	s2,s1
    800034ce:	b7e9                	j	80003498 <iget+0x3c>
  if(empty == 0)
    800034d0:	02090c63          	beqz	s2,80003508 <iget+0xac>
  ip->dev = dev;
    800034d4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034d8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034dc:	4785                	li	a5,1
    800034de:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034e2:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034e6:	0001d517          	auipc	a0,0x1d
    800034ea:	b7a50513          	addi	a0,a0,-1158 # 80020060 <icache>
    800034ee:	ffffe097          	auipc	ra,0xffffe
    800034f2:	820080e7          	jalr	-2016(ra) # 80000d0e <release>
}
    800034f6:	854a                	mv	a0,s2
    800034f8:	70a2                	ld	ra,40(sp)
    800034fa:	7402                	ld	s0,32(sp)
    800034fc:	64e2                	ld	s1,24(sp)
    800034fe:	6942                	ld	s2,16(sp)
    80003500:	69a2                	ld	s3,8(sp)
    80003502:	6a02                	ld	s4,0(sp)
    80003504:	6145                	addi	sp,sp,48
    80003506:	8082                	ret
    panic("iget: no inodes");
    80003508:	00005517          	auipc	a0,0x5
    8000350c:	1e850513          	addi	a0,a0,488 # 800086f0 <sysnames+0x140>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	038080e7          	jalr	56(ra) # 80000548 <panic>

0000000080003518 <fsinit>:
fsinit(int dev) {
    80003518:	7179                	addi	sp,sp,-48
    8000351a:	f406                	sd	ra,40(sp)
    8000351c:	f022                	sd	s0,32(sp)
    8000351e:	ec26                	sd	s1,24(sp)
    80003520:	e84a                	sd	s2,16(sp)
    80003522:	e44e                	sd	s3,8(sp)
    80003524:	1800                	addi	s0,sp,48
    80003526:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003528:	4585                	li	a1,1
    8000352a:	00000097          	auipc	ra,0x0
    8000352e:	a64080e7          	jalr	-1436(ra) # 80002f8e <bread>
    80003532:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003534:	0001d997          	auipc	s3,0x1d
    80003538:	b0c98993          	addi	s3,s3,-1268 # 80020040 <sb>
    8000353c:	02000613          	li	a2,32
    80003540:	05850593          	addi	a1,a0,88
    80003544:	854e                	mv	a0,s3
    80003546:	ffffe097          	auipc	ra,0xffffe
    8000354a:	870080e7          	jalr	-1936(ra) # 80000db6 <memmove>
  brelse(bp);
    8000354e:	8526                	mv	a0,s1
    80003550:	00000097          	auipc	ra,0x0
    80003554:	b6e080e7          	jalr	-1170(ra) # 800030be <brelse>
  if(sb.magic != FSMAGIC)
    80003558:	0009a703          	lw	a4,0(s3)
    8000355c:	102037b7          	lui	a5,0x10203
    80003560:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003564:	02f71263          	bne	a4,a5,80003588 <fsinit+0x70>
  initlog(dev, &sb);
    80003568:	0001d597          	auipc	a1,0x1d
    8000356c:	ad858593          	addi	a1,a1,-1320 # 80020040 <sb>
    80003570:	854a                	mv	a0,s2
    80003572:	00001097          	auipc	ra,0x1
    80003576:	b38080e7          	jalr	-1224(ra) # 800040aa <initlog>
}
    8000357a:	70a2                	ld	ra,40(sp)
    8000357c:	7402                	ld	s0,32(sp)
    8000357e:	64e2                	ld	s1,24(sp)
    80003580:	6942                	ld	s2,16(sp)
    80003582:	69a2                	ld	s3,8(sp)
    80003584:	6145                	addi	sp,sp,48
    80003586:	8082                	ret
    panic("invalid file system");
    80003588:	00005517          	auipc	a0,0x5
    8000358c:	17850513          	addi	a0,a0,376 # 80008700 <sysnames+0x150>
    80003590:	ffffd097          	auipc	ra,0xffffd
    80003594:	fb8080e7          	jalr	-72(ra) # 80000548 <panic>

0000000080003598 <iinit>:
{
    80003598:	7179                	addi	sp,sp,-48
    8000359a:	f406                	sd	ra,40(sp)
    8000359c:	f022                	sd	s0,32(sp)
    8000359e:	ec26                	sd	s1,24(sp)
    800035a0:	e84a                	sd	s2,16(sp)
    800035a2:	e44e                	sd	s3,8(sp)
    800035a4:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800035a6:	00005597          	auipc	a1,0x5
    800035aa:	17258593          	addi	a1,a1,370 # 80008718 <sysnames+0x168>
    800035ae:	0001d517          	auipc	a0,0x1d
    800035b2:	ab250513          	addi	a0,a0,-1358 # 80020060 <icache>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	614080e7          	jalr	1556(ra) # 80000bca <initlock>
  for(i = 0; i < NINODE; i++) {
    800035be:	0001d497          	auipc	s1,0x1d
    800035c2:	aca48493          	addi	s1,s1,-1334 # 80020088 <icache+0x28>
    800035c6:	0001e997          	auipc	s3,0x1e
    800035ca:	55298993          	addi	s3,s3,1362 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035ce:	00005917          	auipc	s2,0x5
    800035d2:	15290913          	addi	s2,s2,338 # 80008720 <sysnames+0x170>
    800035d6:	85ca                	mv	a1,s2
    800035d8:	8526                	mv	a0,s1
    800035da:	00001097          	auipc	ra,0x1
    800035de:	e36080e7          	jalr	-458(ra) # 80004410 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035e2:	08848493          	addi	s1,s1,136
    800035e6:	ff3498e3          	bne	s1,s3,800035d6 <iinit+0x3e>
}
    800035ea:	70a2                	ld	ra,40(sp)
    800035ec:	7402                	ld	s0,32(sp)
    800035ee:	64e2                	ld	s1,24(sp)
    800035f0:	6942                	ld	s2,16(sp)
    800035f2:	69a2                	ld	s3,8(sp)
    800035f4:	6145                	addi	sp,sp,48
    800035f6:	8082                	ret

00000000800035f8 <ialloc>:
{
    800035f8:	715d                	addi	sp,sp,-80
    800035fa:	e486                	sd	ra,72(sp)
    800035fc:	e0a2                	sd	s0,64(sp)
    800035fe:	fc26                	sd	s1,56(sp)
    80003600:	f84a                	sd	s2,48(sp)
    80003602:	f44e                	sd	s3,40(sp)
    80003604:	f052                	sd	s4,32(sp)
    80003606:	ec56                	sd	s5,24(sp)
    80003608:	e85a                	sd	s6,16(sp)
    8000360a:	e45e                	sd	s7,8(sp)
    8000360c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000360e:	0001d717          	auipc	a4,0x1d
    80003612:	a3e72703          	lw	a4,-1474(a4) # 8002004c <sb+0xc>
    80003616:	4785                	li	a5,1
    80003618:	04e7fa63          	bgeu	a5,a4,8000366c <ialloc+0x74>
    8000361c:	8aaa                	mv	s5,a0
    8000361e:	8bae                	mv	s7,a1
    80003620:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003622:	0001da17          	auipc	s4,0x1d
    80003626:	a1ea0a13          	addi	s4,s4,-1506 # 80020040 <sb>
    8000362a:	00048b1b          	sext.w	s6,s1
    8000362e:	0044d593          	srli	a1,s1,0x4
    80003632:	018a2783          	lw	a5,24(s4)
    80003636:	9dbd                	addw	a1,a1,a5
    80003638:	8556                	mv	a0,s5
    8000363a:	00000097          	auipc	ra,0x0
    8000363e:	954080e7          	jalr	-1708(ra) # 80002f8e <bread>
    80003642:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003644:	05850993          	addi	s3,a0,88
    80003648:	00f4f793          	andi	a5,s1,15
    8000364c:	079a                	slli	a5,a5,0x6
    8000364e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003650:	00099783          	lh	a5,0(s3)
    80003654:	c785                	beqz	a5,8000367c <ialloc+0x84>
    brelse(bp);
    80003656:	00000097          	auipc	ra,0x0
    8000365a:	a68080e7          	jalr	-1432(ra) # 800030be <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000365e:	0485                	addi	s1,s1,1
    80003660:	00ca2703          	lw	a4,12(s4)
    80003664:	0004879b          	sext.w	a5,s1
    80003668:	fce7e1e3          	bltu	a5,a4,8000362a <ialloc+0x32>
  panic("ialloc: no inodes");
    8000366c:	00005517          	auipc	a0,0x5
    80003670:	0bc50513          	addi	a0,a0,188 # 80008728 <sysnames+0x178>
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	ed4080e7          	jalr	-300(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    8000367c:	04000613          	li	a2,64
    80003680:	4581                	li	a1,0
    80003682:	854e                	mv	a0,s3
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	6d2080e7          	jalr	1746(ra) # 80000d56 <memset>
      dip->type = type;
    8000368c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003690:	854a                	mv	a0,s2
    80003692:	00001097          	auipc	ra,0x1
    80003696:	c90080e7          	jalr	-880(ra) # 80004322 <log_write>
      brelse(bp);
    8000369a:	854a                	mv	a0,s2
    8000369c:	00000097          	auipc	ra,0x0
    800036a0:	a22080e7          	jalr	-1502(ra) # 800030be <brelse>
      return iget(dev, inum);
    800036a4:	85da                	mv	a1,s6
    800036a6:	8556                	mv	a0,s5
    800036a8:	00000097          	auipc	ra,0x0
    800036ac:	db4080e7          	jalr	-588(ra) # 8000345c <iget>
}
    800036b0:	60a6                	ld	ra,72(sp)
    800036b2:	6406                	ld	s0,64(sp)
    800036b4:	74e2                	ld	s1,56(sp)
    800036b6:	7942                	ld	s2,48(sp)
    800036b8:	79a2                	ld	s3,40(sp)
    800036ba:	7a02                	ld	s4,32(sp)
    800036bc:	6ae2                	ld	s5,24(sp)
    800036be:	6b42                	ld	s6,16(sp)
    800036c0:	6ba2                	ld	s7,8(sp)
    800036c2:	6161                	addi	sp,sp,80
    800036c4:	8082                	ret

00000000800036c6 <iupdate>:
{
    800036c6:	1101                	addi	sp,sp,-32
    800036c8:	ec06                	sd	ra,24(sp)
    800036ca:	e822                	sd	s0,16(sp)
    800036cc:	e426                	sd	s1,8(sp)
    800036ce:	e04a                	sd	s2,0(sp)
    800036d0:	1000                	addi	s0,sp,32
    800036d2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036d4:	415c                	lw	a5,4(a0)
    800036d6:	0047d79b          	srliw	a5,a5,0x4
    800036da:	0001d597          	auipc	a1,0x1d
    800036de:	97e5a583          	lw	a1,-1666(a1) # 80020058 <sb+0x18>
    800036e2:	9dbd                	addw	a1,a1,a5
    800036e4:	4108                	lw	a0,0(a0)
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	8a8080e7          	jalr	-1880(ra) # 80002f8e <bread>
    800036ee:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036f0:	05850793          	addi	a5,a0,88
    800036f4:	40c8                	lw	a0,4(s1)
    800036f6:	893d                	andi	a0,a0,15
    800036f8:	051a                	slli	a0,a0,0x6
    800036fa:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036fc:	04449703          	lh	a4,68(s1)
    80003700:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003704:	04649703          	lh	a4,70(s1)
    80003708:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000370c:	04849703          	lh	a4,72(s1)
    80003710:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003714:	04a49703          	lh	a4,74(s1)
    80003718:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000371c:	44f8                	lw	a4,76(s1)
    8000371e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003720:	03400613          	li	a2,52
    80003724:	05048593          	addi	a1,s1,80
    80003728:	0531                	addi	a0,a0,12
    8000372a:	ffffd097          	auipc	ra,0xffffd
    8000372e:	68c080e7          	jalr	1676(ra) # 80000db6 <memmove>
  log_write(bp);
    80003732:	854a                	mv	a0,s2
    80003734:	00001097          	auipc	ra,0x1
    80003738:	bee080e7          	jalr	-1042(ra) # 80004322 <log_write>
  brelse(bp);
    8000373c:	854a                	mv	a0,s2
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	980080e7          	jalr	-1664(ra) # 800030be <brelse>
}
    80003746:	60e2                	ld	ra,24(sp)
    80003748:	6442                	ld	s0,16(sp)
    8000374a:	64a2                	ld	s1,8(sp)
    8000374c:	6902                	ld	s2,0(sp)
    8000374e:	6105                	addi	sp,sp,32
    80003750:	8082                	ret

0000000080003752 <idup>:
{
    80003752:	1101                	addi	sp,sp,-32
    80003754:	ec06                	sd	ra,24(sp)
    80003756:	e822                	sd	s0,16(sp)
    80003758:	e426                	sd	s1,8(sp)
    8000375a:	1000                	addi	s0,sp,32
    8000375c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000375e:	0001d517          	auipc	a0,0x1d
    80003762:	90250513          	addi	a0,a0,-1790 # 80020060 <icache>
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	4f4080e7          	jalr	1268(ra) # 80000c5a <acquire>
  ip->ref++;
    8000376e:	449c                	lw	a5,8(s1)
    80003770:	2785                	addiw	a5,a5,1
    80003772:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003774:	0001d517          	auipc	a0,0x1d
    80003778:	8ec50513          	addi	a0,a0,-1812 # 80020060 <icache>
    8000377c:	ffffd097          	auipc	ra,0xffffd
    80003780:	592080e7          	jalr	1426(ra) # 80000d0e <release>
}
    80003784:	8526                	mv	a0,s1
    80003786:	60e2                	ld	ra,24(sp)
    80003788:	6442                	ld	s0,16(sp)
    8000378a:	64a2                	ld	s1,8(sp)
    8000378c:	6105                	addi	sp,sp,32
    8000378e:	8082                	ret

0000000080003790 <ilock>:
{
    80003790:	1101                	addi	sp,sp,-32
    80003792:	ec06                	sd	ra,24(sp)
    80003794:	e822                	sd	s0,16(sp)
    80003796:	e426                	sd	s1,8(sp)
    80003798:	e04a                	sd	s2,0(sp)
    8000379a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000379c:	c115                	beqz	a0,800037c0 <ilock+0x30>
    8000379e:	84aa                	mv	s1,a0
    800037a0:	451c                	lw	a5,8(a0)
    800037a2:	00f05f63          	blez	a5,800037c0 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037a6:	0541                	addi	a0,a0,16
    800037a8:	00001097          	auipc	ra,0x1
    800037ac:	ca2080e7          	jalr	-862(ra) # 8000444a <acquiresleep>
  if(ip->valid == 0){
    800037b0:	40bc                	lw	a5,64(s1)
    800037b2:	cf99                	beqz	a5,800037d0 <ilock+0x40>
}
    800037b4:	60e2                	ld	ra,24(sp)
    800037b6:	6442                	ld	s0,16(sp)
    800037b8:	64a2                	ld	s1,8(sp)
    800037ba:	6902                	ld	s2,0(sp)
    800037bc:	6105                	addi	sp,sp,32
    800037be:	8082                	ret
    panic("ilock");
    800037c0:	00005517          	auipc	a0,0x5
    800037c4:	f8050513          	addi	a0,a0,-128 # 80008740 <sysnames+0x190>
    800037c8:	ffffd097          	auipc	ra,0xffffd
    800037cc:	d80080e7          	jalr	-640(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037d0:	40dc                	lw	a5,4(s1)
    800037d2:	0047d79b          	srliw	a5,a5,0x4
    800037d6:	0001d597          	auipc	a1,0x1d
    800037da:	8825a583          	lw	a1,-1918(a1) # 80020058 <sb+0x18>
    800037de:	9dbd                	addw	a1,a1,a5
    800037e0:	4088                	lw	a0,0(s1)
    800037e2:	fffff097          	auipc	ra,0xfffff
    800037e6:	7ac080e7          	jalr	1964(ra) # 80002f8e <bread>
    800037ea:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037ec:	05850593          	addi	a1,a0,88
    800037f0:	40dc                	lw	a5,4(s1)
    800037f2:	8bbd                	andi	a5,a5,15
    800037f4:	079a                	slli	a5,a5,0x6
    800037f6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037f8:	00059783          	lh	a5,0(a1)
    800037fc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003800:	00259783          	lh	a5,2(a1)
    80003804:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003808:	00459783          	lh	a5,4(a1)
    8000380c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003810:	00659783          	lh	a5,6(a1)
    80003814:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003818:	459c                	lw	a5,8(a1)
    8000381a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000381c:	03400613          	li	a2,52
    80003820:	05b1                	addi	a1,a1,12
    80003822:	05048513          	addi	a0,s1,80
    80003826:	ffffd097          	auipc	ra,0xffffd
    8000382a:	590080e7          	jalr	1424(ra) # 80000db6 <memmove>
    brelse(bp);
    8000382e:	854a                	mv	a0,s2
    80003830:	00000097          	auipc	ra,0x0
    80003834:	88e080e7          	jalr	-1906(ra) # 800030be <brelse>
    ip->valid = 1;
    80003838:	4785                	li	a5,1
    8000383a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000383c:	04449783          	lh	a5,68(s1)
    80003840:	fbb5                	bnez	a5,800037b4 <ilock+0x24>
      panic("ilock: no type");
    80003842:	00005517          	auipc	a0,0x5
    80003846:	f0650513          	addi	a0,a0,-250 # 80008748 <sysnames+0x198>
    8000384a:	ffffd097          	auipc	ra,0xffffd
    8000384e:	cfe080e7          	jalr	-770(ra) # 80000548 <panic>

0000000080003852 <iunlock>:
{
    80003852:	1101                	addi	sp,sp,-32
    80003854:	ec06                	sd	ra,24(sp)
    80003856:	e822                	sd	s0,16(sp)
    80003858:	e426                	sd	s1,8(sp)
    8000385a:	e04a                	sd	s2,0(sp)
    8000385c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000385e:	c905                	beqz	a0,8000388e <iunlock+0x3c>
    80003860:	84aa                	mv	s1,a0
    80003862:	01050913          	addi	s2,a0,16
    80003866:	854a                	mv	a0,s2
    80003868:	00001097          	auipc	ra,0x1
    8000386c:	c7c080e7          	jalr	-900(ra) # 800044e4 <holdingsleep>
    80003870:	cd19                	beqz	a0,8000388e <iunlock+0x3c>
    80003872:	449c                	lw	a5,8(s1)
    80003874:	00f05d63          	blez	a5,8000388e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003878:	854a                	mv	a0,s2
    8000387a:	00001097          	auipc	ra,0x1
    8000387e:	c26080e7          	jalr	-986(ra) # 800044a0 <releasesleep>
}
    80003882:	60e2                	ld	ra,24(sp)
    80003884:	6442                	ld	s0,16(sp)
    80003886:	64a2                	ld	s1,8(sp)
    80003888:	6902                	ld	s2,0(sp)
    8000388a:	6105                	addi	sp,sp,32
    8000388c:	8082                	ret
    panic("iunlock");
    8000388e:	00005517          	auipc	a0,0x5
    80003892:	eca50513          	addi	a0,a0,-310 # 80008758 <sysnames+0x1a8>
    80003896:	ffffd097          	auipc	ra,0xffffd
    8000389a:	cb2080e7          	jalr	-846(ra) # 80000548 <panic>

000000008000389e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000389e:	7179                	addi	sp,sp,-48
    800038a0:	f406                	sd	ra,40(sp)
    800038a2:	f022                	sd	s0,32(sp)
    800038a4:	ec26                	sd	s1,24(sp)
    800038a6:	e84a                	sd	s2,16(sp)
    800038a8:	e44e                	sd	s3,8(sp)
    800038aa:	e052                	sd	s4,0(sp)
    800038ac:	1800                	addi	s0,sp,48
    800038ae:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038b0:	05050493          	addi	s1,a0,80
    800038b4:	08050913          	addi	s2,a0,128
    800038b8:	a021                	j	800038c0 <itrunc+0x22>
    800038ba:	0491                	addi	s1,s1,4
    800038bc:	01248d63          	beq	s1,s2,800038d6 <itrunc+0x38>
    if(ip->addrs[i]){
    800038c0:	408c                	lw	a1,0(s1)
    800038c2:	dde5                	beqz	a1,800038ba <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038c4:	0009a503          	lw	a0,0(s3)
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	90c080e7          	jalr	-1780(ra) # 800031d4 <bfree>
      ip->addrs[i] = 0;
    800038d0:	0004a023          	sw	zero,0(s1)
    800038d4:	b7dd                	j	800038ba <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038d6:	0809a583          	lw	a1,128(s3)
    800038da:	e185                	bnez	a1,800038fa <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038dc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038e0:	854e                	mv	a0,s3
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	de4080e7          	jalr	-540(ra) # 800036c6 <iupdate>
}
    800038ea:	70a2                	ld	ra,40(sp)
    800038ec:	7402                	ld	s0,32(sp)
    800038ee:	64e2                	ld	s1,24(sp)
    800038f0:	6942                	ld	s2,16(sp)
    800038f2:	69a2                	ld	s3,8(sp)
    800038f4:	6a02                	ld	s4,0(sp)
    800038f6:	6145                	addi	sp,sp,48
    800038f8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038fa:	0009a503          	lw	a0,0(s3)
    800038fe:	fffff097          	auipc	ra,0xfffff
    80003902:	690080e7          	jalr	1680(ra) # 80002f8e <bread>
    80003906:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003908:	05850493          	addi	s1,a0,88
    8000390c:	45850913          	addi	s2,a0,1112
    80003910:	a811                	j	80003924 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003912:	0009a503          	lw	a0,0(s3)
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	8be080e7          	jalr	-1858(ra) # 800031d4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000391e:	0491                	addi	s1,s1,4
    80003920:	01248563          	beq	s1,s2,8000392a <itrunc+0x8c>
      if(a[j])
    80003924:	408c                	lw	a1,0(s1)
    80003926:	dde5                	beqz	a1,8000391e <itrunc+0x80>
    80003928:	b7ed                	j	80003912 <itrunc+0x74>
    brelse(bp);
    8000392a:	8552                	mv	a0,s4
    8000392c:	fffff097          	auipc	ra,0xfffff
    80003930:	792080e7          	jalr	1938(ra) # 800030be <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003934:	0809a583          	lw	a1,128(s3)
    80003938:	0009a503          	lw	a0,0(s3)
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	898080e7          	jalr	-1896(ra) # 800031d4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003944:	0809a023          	sw	zero,128(s3)
    80003948:	bf51                	j	800038dc <itrunc+0x3e>

000000008000394a <iput>:
{
    8000394a:	1101                	addi	sp,sp,-32
    8000394c:	ec06                	sd	ra,24(sp)
    8000394e:	e822                	sd	s0,16(sp)
    80003950:	e426                	sd	s1,8(sp)
    80003952:	e04a                	sd	s2,0(sp)
    80003954:	1000                	addi	s0,sp,32
    80003956:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003958:	0001c517          	auipc	a0,0x1c
    8000395c:	70850513          	addi	a0,a0,1800 # 80020060 <icache>
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	2fa080e7          	jalr	762(ra) # 80000c5a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003968:	4498                	lw	a4,8(s1)
    8000396a:	4785                	li	a5,1
    8000396c:	02f70363          	beq	a4,a5,80003992 <iput+0x48>
  ip->ref--;
    80003970:	449c                	lw	a5,8(s1)
    80003972:	37fd                	addiw	a5,a5,-1
    80003974:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003976:	0001c517          	auipc	a0,0x1c
    8000397a:	6ea50513          	addi	a0,a0,1770 # 80020060 <icache>
    8000397e:	ffffd097          	auipc	ra,0xffffd
    80003982:	390080e7          	jalr	912(ra) # 80000d0e <release>
}
    80003986:	60e2                	ld	ra,24(sp)
    80003988:	6442                	ld	s0,16(sp)
    8000398a:	64a2                	ld	s1,8(sp)
    8000398c:	6902                	ld	s2,0(sp)
    8000398e:	6105                	addi	sp,sp,32
    80003990:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003992:	40bc                	lw	a5,64(s1)
    80003994:	dff1                	beqz	a5,80003970 <iput+0x26>
    80003996:	04a49783          	lh	a5,74(s1)
    8000399a:	fbf9                	bnez	a5,80003970 <iput+0x26>
    acquiresleep(&ip->lock);
    8000399c:	01048913          	addi	s2,s1,16
    800039a0:	854a                	mv	a0,s2
    800039a2:	00001097          	auipc	ra,0x1
    800039a6:	aa8080e7          	jalr	-1368(ra) # 8000444a <acquiresleep>
    release(&icache.lock);
    800039aa:	0001c517          	auipc	a0,0x1c
    800039ae:	6b650513          	addi	a0,a0,1718 # 80020060 <icache>
    800039b2:	ffffd097          	auipc	ra,0xffffd
    800039b6:	35c080e7          	jalr	860(ra) # 80000d0e <release>
    itrunc(ip);
    800039ba:	8526                	mv	a0,s1
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	ee2080e7          	jalr	-286(ra) # 8000389e <itrunc>
    ip->type = 0;
    800039c4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039c8:	8526                	mv	a0,s1
    800039ca:	00000097          	auipc	ra,0x0
    800039ce:	cfc080e7          	jalr	-772(ra) # 800036c6 <iupdate>
    ip->valid = 0;
    800039d2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039d6:	854a                	mv	a0,s2
    800039d8:	00001097          	auipc	ra,0x1
    800039dc:	ac8080e7          	jalr	-1336(ra) # 800044a0 <releasesleep>
    acquire(&icache.lock);
    800039e0:	0001c517          	auipc	a0,0x1c
    800039e4:	68050513          	addi	a0,a0,1664 # 80020060 <icache>
    800039e8:	ffffd097          	auipc	ra,0xffffd
    800039ec:	272080e7          	jalr	626(ra) # 80000c5a <acquire>
    800039f0:	b741                	j	80003970 <iput+0x26>

00000000800039f2 <iunlockput>:
{
    800039f2:	1101                	addi	sp,sp,-32
    800039f4:	ec06                	sd	ra,24(sp)
    800039f6:	e822                	sd	s0,16(sp)
    800039f8:	e426                	sd	s1,8(sp)
    800039fa:	1000                	addi	s0,sp,32
    800039fc:	84aa                	mv	s1,a0
  iunlock(ip);
    800039fe:	00000097          	auipc	ra,0x0
    80003a02:	e54080e7          	jalr	-428(ra) # 80003852 <iunlock>
  iput(ip);
    80003a06:	8526                	mv	a0,s1
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	f42080e7          	jalr	-190(ra) # 8000394a <iput>
}
    80003a10:	60e2                	ld	ra,24(sp)
    80003a12:	6442                	ld	s0,16(sp)
    80003a14:	64a2                	ld	s1,8(sp)
    80003a16:	6105                	addi	sp,sp,32
    80003a18:	8082                	ret

0000000080003a1a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a1a:	1141                	addi	sp,sp,-16
    80003a1c:	e422                	sd	s0,8(sp)
    80003a1e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a20:	411c                	lw	a5,0(a0)
    80003a22:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a24:	415c                	lw	a5,4(a0)
    80003a26:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a28:	04451783          	lh	a5,68(a0)
    80003a2c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a30:	04a51783          	lh	a5,74(a0)
    80003a34:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a38:	04c56783          	lwu	a5,76(a0)
    80003a3c:	e99c                	sd	a5,16(a1)
}
    80003a3e:	6422                	ld	s0,8(sp)
    80003a40:	0141                	addi	sp,sp,16
    80003a42:	8082                	ret

0000000080003a44 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a44:	457c                	lw	a5,76(a0)
    80003a46:	0ed7e863          	bltu	a5,a3,80003b36 <readi+0xf2>
{
    80003a4a:	7159                	addi	sp,sp,-112
    80003a4c:	f486                	sd	ra,104(sp)
    80003a4e:	f0a2                	sd	s0,96(sp)
    80003a50:	eca6                	sd	s1,88(sp)
    80003a52:	e8ca                	sd	s2,80(sp)
    80003a54:	e4ce                	sd	s3,72(sp)
    80003a56:	e0d2                	sd	s4,64(sp)
    80003a58:	fc56                	sd	s5,56(sp)
    80003a5a:	f85a                	sd	s6,48(sp)
    80003a5c:	f45e                	sd	s7,40(sp)
    80003a5e:	f062                	sd	s8,32(sp)
    80003a60:	ec66                	sd	s9,24(sp)
    80003a62:	e86a                	sd	s10,16(sp)
    80003a64:	e46e                	sd	s11,8(sp)
    80003a66:	1880                	addi	s0,sp,112
    80003a68:	8baa                	mv	s7,a0
    80003a6a:	8c2e                	mv	s8,a1
    80003a6c:	8ab2                	mv	s5,a2
    80003a6e:	84b6                	mv	s1,a3
    80003a70:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a72:	9f35                	addw	a4,a4,a3
    return 0;
    80003a74:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a76:	08d76f63          	bltu	a4,a3,80003b14 <readi+0xd0>
  if(off + n > ip->size)
    80003a7a:	00e7f463          	bgeu	a5,a4,80003a82 <readi+0x3e>
    n = ip->size - off;
    80003a7e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a82:	0a0b0863          	beqz	s6,80003b32 <readi+0xee>
    80003a86:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a88:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a8c:	5cfd                	li	s9,-1
    80003a8e:	a82d                	j	80003ac8 <readi+0x84>
    80003a90:	020a1d93          	slli	s11,s4,0x20
    80003a94:	020ddd93          	srli	s11,s11,0x20
    80003a98:	05890613          	addi	a2,s2,88
    80003a9c:	86ee                	mv	a3,s11
    80003a9e:	963a                	add	a2,a2,a4
    80003aa0:	85d6                	mv	a1,s5
    80003aa2:	8562                	mv	a0,s8
    80003aa4:	fffff097          	auipc	ra,0xfffff
    80003aa8:	9fe080e7          	jalr	-1538(ra) # 800024a2 <either_copyout>
    80003aac:	05950d63          	beq	a0,s9,80003b06 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003ab0:	854a                	mv	a0,s2
    80003ab2:	fffff097          	auipc	ra,0xfffff
    80003ab6:	60c080e7          	jalr	1548(ra) # 800030be <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aba:	013a09bb          	addw	s3,s4,s3
    80003abe:	009a04bb          	addw	s1,s4,s1
    80003ac2:	9aee                	add	s5,s5,s11
    80003ac4:	0569f663          	bgeu	s3,s6,80003b10 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ac8:	000ba903          	lw	s2,0(s7)
    80003acc:	00a4d59b          	srliw	a1,s1,0xa
    80003ad0:	855e                	mv	a0,s7
    80003ad2:	00000097          	auipc	ra,0x0
    80003ad6:	8b0080e7          	jalr	-1872(ra) # 80003382 <bmap>
    80003ada:	0005059b          	sext.w	a1,a0
    80003ade:	854a                	mv	a0,s2
    80003ae0:	fffff097          	auipc	ra,0xfffff
    80003ae4:	4ae080e7          	jalr	1198(ra) # 80002f8e <bread>
    80003ae8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aea:	3ff4f713          	andi	a4,s1,1023
    80003aee:	40ed07bb          	subw	a5,s10,a4
    80003af2:	413b06bb          	subw	a3,s6,s3
    80003af6:	8a3e                	mv	s4,a5
    80003af8:	2781                	sext.w	a5,a5
    80003afa:	0006861b          	sext.w	a2,a3
    80003afe:	f8f679e3          	bgeu	a2,a5,80003a90 <readi+0x4c>
    80003b02:	8a36                	mv	s4,a3
    80003b04:	b771                	j	80003a90 <readi+0x4c>
      brelse(bp);
    80003b06:	854a                	mv	a0,s2
    80003b08:	fffff097          	auipc	ra,0xfffff
    80003b0c:	5b6080e7          	jalr	1462(ra) # 800030be <brelse>
  }
  return tot;
    80003b10:	0009851b          	sext.w	a0,s3
}
    80003b14:	70a6                	ld	ra,104(sp)
    80003b16:	7406                	ld	s0,96(sp)
    80003b18:	64e6                	ld	s1,88(sp)
    80003b1a:	6946                	ld	s2,80(sp)
    80003b1c:	69a6                	ld	s3,72(sp)
    80003b1e:	6a06                	ld	s4,64(sp)
    80003b20:	7ae2                	ld	s5,56(sp)
    80003b22:	7b42                	ld	s6,48(sp)
    80003b24:	7ba2                	ld	s7,40(sp)
    80003b26:	7c02                	ld	s8,32(sp)
    80003b28:	6ce2                	ld	s9,24(sp)
    80003b2a:	6d42                	ld	s10,16(sp)
    80003b2c:	6da2                	ld	s11,8(sp)
    80003b2e:	6165                	addi	sp,sp,112
    80003b30:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b32:	89da                	mv	s3,s6
    80003b34:	bff1                	j	80003b10 <readi+0xcc>
    return 0;
    80003b36:	4501                	li	a0,0
}
    80003b38:	8082                	ret

0000000080003b3a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b3a:	457c                	lw	a5,76(a0)
    80003b3c:	10d7e663          	bltu	a5,a3,80003c48 <writei+0x10e>
{
    80003b40:	7159                	addi	sp,sp,-112
    80003b42:	f486                	sd	ra,104(sp)
    80003b44:	f0a2                	sd	s0,96(sp)
    80003b46:	eca6                	sd	s1,88(sp)
    80003b48:	e8ca                	sd	s2,80(sp)
    80003b4a:	e4ce                	sd	s3,72(sp)
    80003b4c:	e0d2                	sd	s4,64(sp)
    80003b4e:	fc56                	sd	s5,56(sp)
    80003b50:	f85a                	sd	s6,48(sp)
    80003b52:	f45e                	sd	s7,40(sp)
    80003b54:	f062                	sd	s8,32(sp)
    80003b56:	ec66                	sd	s9,24(sp)
    80003b58:	e86a                	sd	s10,16(sp)
    80003b5a:	e46e                	sd	s11,8(sp)
    80003b5c:	1880                	addi	s0,sp,112
    80003b5e:	8baa                	mv	s7,a0
    80003b60:	8c2e                	mv	s8,a1
    80003b62:	8ab2                	mv	s5,a2
    80003b64:	8936                	mv	s2,a3
    80003b66:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b68:	00e687bb          	addw	a5,a3,a4
    80003b6c:	0ed7e063          	bltu	a5,a3,80003c4c <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b70:	00043737          	lui	a4,0x43
    80003b74:	0cf76e63          	bltu	a4,a5,80003c50 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b78:	0a0b0763          	beqz	s6,80003c26 <writei+0xec>
    80003b7c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b7e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b82:	5cfd                	li	s9,-1
    80003b84:	a091                	j	80003bc8 <writei+0x8e>
    80003b86:	02099d93          	slli	s11,s3,0x20
    80003b8a:	020ddd93          	srli	s11,s11,0x20
    80003b8e:	05848513          	addi	a0,s1,88
    80003b92:	86ee                	mv	a3,s11
    80003b94:	8656                	mv	a2,s5
    80003b96:	85e2                	mv	a1,s8
    80003b98:	953a                	add	a0,a0,a4
    80003b9a:	fffff097          	auipc	ra,0xfffff
    80003b9e:	95e080e7          	jalr	-1698(ra) # 800024f8 <either_copyin>
    80003ba2:	07950263          	beq	a0,s9,80003c06 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ba6:	8526                	mv	a0,s1
    80003ba8:	00000097          	auipc	ra,0x0
    80003bac:	77a080e7          	jalr	1914(ra) # 80004322 <log_write>
    brelse(bp);
    80003bb0:	8526                	mv	a0,s1
    80003bb2:	fffff097          	auipc	ra,0xfffff
    80003bb6:	50c080e7          	jalr	1292(ra) # 800030be <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bba:	01498a3b          	addw	s4,s3,s4
    80003bbe:	0129893b          	addw	s2,s3,s2
    80003bc2:	9aee                	add	s5,s5,s11
    80003bc4:	056a7663          	bgeu	s4,s6,80003c10 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bc8:	000ba483          	lw	s1,0(s7)
    80003bcc:	00a9559b          	srliw	a1,s2,0xa
    80003bd0:	855e                	mv	a0,s7
    80003bd2:	fffff097          	auipc	ra,0xfffff
    80003bd6:	7b0080e7          	jalr	1968(ra) # 80003382 <bmap>
    80003bda:	0005059b          	sext.w	a1,a0
    80003bde:	8526                	mv	a0,s1
    80003be0:	fffff097          	auipc	ra,0xfffff
    80003be4:	3ae080e7          	jalr	942(ra) # 80002f8e <bread>
    80003be8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bea:	3ff97713          	andi	a4,s2,1023
    80003bee:	40ed07bb          	subw	a5,s10,a4
    80003bf2:	414b06bb          	subw	a3,s6,s4
    80003bf6:	89be                	mv	s3,a5
    80003bf8:	2781                	sext.w	a5,a5
    80003bfa:	0006861b          	sext.w	a2,a3
    80003bfe:	f8f674e3          	bgeu	a2,a5,80003b86 <writei+0x4c>
    80003c02:	89b6                	mv	s3,a3
    80003c04:	b749                	j	80003b86 <writei+0x4c>
      brelse(bp);
    80003c06:	8526                	mv	a0,s1
    80003c08:	fffff097          	auipc	ra,0xfffff
    80003c0c:	4b6080e7          	jalr	1206(ra) # 800030be <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003c10:	04cba783          	lw	a5,76(s7)
    80003c14:	0127f463          	bgeu	a5,s2,80003c1c <writei+0xe2>
      ip->size = off;
    80003c18:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c1c:	855e                	mv	a0,s7
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	aa8080e7          	jalr	-1368(ra) # 800036c6 <iupdate>
  }

  return n;
    80003c26:	000b051b          	sext.w	a0,s6
}
    80003c2a:	70a6                	ld	ra,104(sp)
    80003c2c:	7406                	ld	s0,96(sp)
    80003c2e:	64e6                	ld	s1,88(sp)
    80003c30:	6946                	ld	s2,80(sp)
    80003c32:	69a6                	ld	s3,72(sp)
    80003c34:	6a06                	ld	s4,64(sp)
    80003c36:	7ae2                	ld	s5,56(sp)
    80003c38:	7b42                	ld	s6,48(sp)
    80003c3a:	7ba2                	ld	s7,40(sp)
    80003c3c:	7c02                	ld	s8,32(sp)
    80003c3e:	6ce2                	ld	s9,24(sp)
    80003c40:	6d42                	ld	s10,16(sp)
    80003c42:	6da2                	ld	s11,8(sp)
    80003c44:	6165                	addi	sp,sp,112
    80003c46:	8082                	ret
    return -1;
    80003c48:	557d                	li	a0,-1
}
    80003c4a:	8082                	ret
    return -1;
    80003c4c:	557d                	li	a0,-1
    80003c4e:	bff1                	j	80003c2a <writei+0xf0>
    return -1;
    80003c50:	557d                	li	a0,-1
    80003c52:	bfe1                	j	80003c2a <writei+0xf0>

0000000080003c54 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c54:	1141                	addi	sp,sp,-16
    80003c56:	e406                	sd	ra,8(sp)
    80003c58:	e022                	sd	s0,0(sp)
    80003c5a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c5c:	4639                	li	a2,14
    80003c5e:	ffffd097          	auipc	ra,0xffffd
    80003c62:	1d4080e7          	jalr	468(ra) # 80000e32 <strncmp>
}
    80003c66:	60a2                	ld	ra,8(sp)
    80003c68:	6402                	ld	s0,0(sp)
    80003c6a:	0141                	addi	sp,sp,16
    80003c6c:	8082                	ret

0000000080003c6e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c6e:	7139                	addi	sp,sp,-64
    80003c70:	fc06                	sd	ra,56(sp)
    80003c72:	f822                	sd	s0,48(sp)
    80003c74:	f426                	sd	s1,40(sp)
    80003c76:	f04a                	sd	s2,32(sp)
    80003c78:	ec4e                	sd	s3,24(sp)
    80003c7a:	e852                	sd	s4,16(sp)
    80003c7c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c7e:	04451703          	lh	a4,68(a0)
    80003c82:	4785                	li	a5,1
    80003c84:	00f71a63          	bne	a4,a5,80003c98 <dirlookup+0x2a>
    80003c88:	892a                	mv	s2,a0
    80003c8a:	89ae                	mv	s3,a1
    80003c8c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c8e:	457c                	lw	a5,76(a0)
    80003c90:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c92:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c94:	e79d                	bnez	a5,80003cc2 <dirlookup+0x54>
    80003c96:	a8a5                	j	80003d0e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c98:	00005517          	auipc	a0,0x5
    80003c9c:	ac850513          	addi	a0,a0,-1336 # 80008760 <sysnames+0x1b0>
    80003ca0:	ffffd097          	auipc	ra,0xffffd
    80003ca4:	8a8080e7          	jalr	-1880(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003ca8:	00005517          	auipc	a0,0x5
    80003cac:	ad050513          	addi	a0,a0,-1328 # 80008778 <sysnames+0x1c8>
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	898080e7          	jalr	-1896(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb8:	24c1                	addiw	s1,s1,16
    80003cba:	04c92783          	lw	a5,76(s2)
    80003cbe:	04f4f763          	bgeu	s1,a5,80003d0c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cc2:	4741                	li	a4,16
    80003cc4:	86a6                	mv	a3,s1
    80003cc6:	fc040613          	addi	a2,s0,-64
    80003cca:	4581                	li	a1,0
    80003ccc:	854a                	mv	a0,s2
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	d76080e7          	jalr	-650(ra) # 80003a44 <readi>
    80003cd6:	47c1                	li	a5,16
    80003cd8:	fcf518e3          	bne	a0,a5,80003ca8 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cdc:	fc045783          	lhu	a5,-64(s0)
    80003ce0:	dfe1                	beqz	a5,80003cb8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ce2:	fc240593          	addi	a1,s0,-62
    80003ce6:	854e                	mv	a0,s3
    80003ce8:	00000097          	auipc	ra,0x0
    80003cec:	f6c080e7          	jalr	-148(ra) # 80003c54 <namecmp>
    80003cf0:	f561                	bnez	a0,80003cb8 <dirlookup+0x4a>
      if(poff)
    80003cf2:	000a0463          	beqz	s4,80003cfa <dirlookup+0x8c>
        *poff = off;
    80003cf6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cfa:	fc045583          	lhu	a1,-64(s0)
    80003cfe:	00092503          	lw	a0,0(s2)
    80003d02:	fffff097          	auipc	ra,0xfffff
    80003d06:	75a080e7          	jalr	1882(ra) # 8000345c <iget>
    80003d0a:	a011                	j	80003d0e <dirlookup+0xa0>
  return 0;
    80003d0c:	4501                	li	a0,0
}
    80003d0e:	70e2                	ld	ra,56(sp)
    80003d10:	7442                	ld	s0,48(sp)
    80003d12:	74a2                	ld	s1,40(sp)
    80003d14:	7902                	ld	s2,32(sp)
    80003d16:	69e2                	ld	s3,24(sp)
    80003d18:	6a42                	ld	s4,16(sp)
    80003d1a:	6121                	addi	sp,sp,64
    80003d1c:	8082                	ret

0000000080003d1e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d1e:	711d                	addi	sp,sp,-96
    80003d20:	ec86                	sd	ra,88(sp)
    80003d22:	e8a2                	sd	s0,80(sp)
    80003d24:	e4a6                	sd	s1,72(sp)
    80003d26:	e0ca                	sd	s2,64(sp)
    80003d28:	fc4e                	sd	s3,56(sp)
    80003d2a:	f852                	sd	s4,48(sp)
    80003d2c:	f456                	sd	s5,40(sp)
    80003d2e:	f05a                	sd	s6,32(sp)
    80003d30:	ec5e                	sd	s7,24(sp)
    80003d32:	e862                	sd	s8,16(sp)
    80003d34:	e466                	sd	s9,8(sp)
    80003d36:	1080                	addi	s0,sp,96
    80003d38:	84aa                	mv	s1,a0
    80003d3a:	8b2e                	mv	s6,a1
    80003d3c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d3e:	00054703          	lbu	a4,0(a0)
    80003d42:	02f00793          	li	a5,47
    80003d46:	02f70363          	beq	a4,a5,80003d6c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d4a:	ffffe097          	auipc	ra,0xffffe
    80003d4e:	cde080e7          	jalr	-802(ra) # 80001a28 <myproc>
    80003d52:	15053503          	ld	a0,336(a0)
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	9fc080e7          	jalr	-1540(ra) # 80003752 <idup>
    80003d5e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d60:	02f00913          	li	s2,47
  len = path - s;
    80003d64:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d66:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d68:	4c05                	li	s8,1
    80003d6a:	a865                	j	80003e22 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d6c:	4585                	li	a1,1
    80003d6e:	4505                	li	a0,1
    80003d70:	fffff097          	auipc	ra,0xfffff
    80003d74:	6ec080e7          	jalr	1772(ra) # 8000345c <iget>
    80003d78:	89aa                	mv	s3,a0
    80003d7a:	b7dd                	j	80003d60 <namex+0x42>
      iunlockput(ip);
    80003d7c:	854e                	mv	a0,s3
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	c74080e7          	jalr	-908(ra) # 800039f2 <iunlockput>
      return 0;
    80003d86:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d88:	854e                	mv	a0,s3
    80003d8a:	60e6                	ld	ra,88(sp)
    80003d8c:	6446                	ld	s0,80(sp)
    80003d8e:	64a6                	ld	s1,72(sp)
    80003d90:	6906                	ld	s2,64(sp)
    80003d92:	79e2                	ld	s3,56(sp)
    80003d94:	7a42                	ld	s4,48(sp)
    80003d96:	7aa2                	ld	s5,40(sp)
    80003d98:	7b02                	ld	s6,32(sp)
    80003d9a:	6be2                	ld	s7,24(sp)
    80003d9c:	6c42                	ld	s8,16(sp)
    80003d9e:	6ca2                	ld	s9,8(sp)
    80003da0:	6125                	addi	sp,sp,96
    80003da2:	8082                	ret
      iunlock(ip);
    80003da4:	854e                	mv	a0,s3
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	aac080e7          	jalr	-1364(ra) # 80003852 <iunlock>
      return ip;
    80003dae:	bfe9                	j	80003d88 <namex+0x6a>
      iunlockput(ip);
    80003db0:	854e                	mv	a0,s3
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	c40080e7          	jalr	-960(ra) # 800039f2 <iunlockput>
      return 0;
    80003dba:	89d2                	mv	s3,s4
    80003dbc:	b7f1                	j	80003d88 <namex+0x6a>
  len = path - s;
    80003dbe:	40b48633          	sub	a2,s1,a1
    80003dc2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dc6:	094cd463          	bge	s9,s4,80003e4e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003dca:	4639                	li	a2,14
    80003dcc:	8556                	mv	a0,s5
    80003dce:	ffffd097          	auipc	ra,0xffffd
    80003dd2:	fe8080e7          	jalr	-24(ra) # 80000db6 <memmove>
  while(*path == '/')
    80003dd6:	0004c783          	lbu	a5,0(s1)
    80003dda:	01279763          	bne	a5,s2,80003de8 <namex+0xca>
    path++;
    80003dde:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003de0:	0004c783          	lbu	a5,0(s1)
    80003de4:	ff278de3          	beq	a5,s2,80003dde <namex+0xc0>
    ilock(ip);
    80003de8:	854e                	mv	a0,s3
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	9a6080e7          	jalr	-1626(ra) # 80003790 <ilock>
    if(ip->type != T_DIR){
    80003df2:	04499783          	lh	a5,68(s3)
    80003df6:	f98793e3          	bne	a5,s8,80003d7c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dfa:	000b0563          	beqz	s6,80003e04 <namex+0xe6>
    80003dfe:	0004c783          	lbu	a5,0(s1)
    80003e02:	d3cd                	beqz	a5,80003da4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e04:	865e                	mv	a2,s7
    80003e06:	85d6                	mv	a1,s5
    80003e08:	854e                	mv	a0,s3
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	e64080e7          	jalr	-412(ra) # 80003c6e <dirlookup>
    80003e12:	8a2a                	mv	s4,a0
    80003e14:	dd51                	beqz	a0,80003db0 <namex+0x92>
    iunlockput(ip);
    80003e16:	854e                	mv	a0,s3
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	bda080e7          	jalr	-1062(ra) # 800039f2 <iunlockput>
    ip = next;
    80003e20:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e22:	0004c783          	lbu	a5,0(s1)
    80003e26:	05279763          	bne	a5,s2,80003e74 <namex+0x156>
    path++;
    80003e2a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e2c:	0004c783          	lbu	a5,0(s1)
    80003e30:	ff278de3          	beq	a5,s2,80003e2a <namex+0x10c>
  if(*path == 0)
    80003e34:	c79d                	beqz	a5,80003e62 <namex+0x144>
    path++;
    80003e36:	85a6                	mv	a1,s1
  len = path - s;
    80003e38:	8a5e                	mv	s4,s7
    80003e3a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e3c:	01278963          	beq	a5,s2,80003e4e <namex+0x130>
    80003e40:	dfbd                	beqz	a5,80003dbe <namex+0xa0>
    path++;
    80003e42:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e44:	0004c783          	lbu	a5,0(s1)
    80003e48:	ff279ce3          	bne	a5,s2,80003e40 <namex+0x122>
    80003e4c:	bf8d                	j	80003dbe <namex+0xa0>
    memmove(name, s, len);
    80003e4e:	2601                	sext.w	a2,a2
    80003e50:	8556                	mv	a0,s5
    80003e52:	ffffd097          	auipc	ra,0xffffd
    80003e56:	f64080e7          	jalr	-156(ra) # 80000db6 <memmove>
    name[len] = 0;
    80003e5a:	9a56                	add	s4,s4,s5
    80003e5c:	000a0023          	sb	zero,0(s4)
    80003e60:	bf9d                	j	80003dd6 <namex+0xb8>
  if(nameiparent){
    80003e62:	f20b03e3          	beqz	s6,80003d88 <namex+0x6a>
    iput(ip);
    80003e66:	854e                	mv	a0,s3
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	ae2080e7          	jalr	-1310(ra) # 8000394a <iput>
    return 0;
    80003e70:	4981                	li	s3,0
    80003e72:	bf19                	j	80003d88 <namex+0x6a>
  if(*path == 0)
    80003e74:	d7fd                	beqz	a5,80003e62 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e76:	0004c783          	lbu	a5,0(s1)
    80003e7a:	85a6                	mv	a1,s1
    80003e7c:	b7d1                	j	80003e40 <namex+0x122>

0000000080003e7e <dirlink>:
{
    80003e7e:	7139                	addi	sp,sp,-64
    80003e80:	fc06                	sd	ra,56(sp)
    80003e82:	f822                	sd	s0,48(sp)
    80003e84:	f426                	sd	s1,40(sp)
    80003e86:	f04a                	sd	s2,32(sp)
    80003e88:	ec4e                	sd	s3,24(sp)
    80003e8a:	e852                	sd	s4,16(sp)
    80003e8c:	0080                	addi	s0,sp,64
    80003e8e:	892a                	mv	s2,a0
    80003e90:	8a2e                	mv	s4,a1
    80003e92:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e94:	4601                	li	a2,0
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	dd8080e7          	jalr	-552(ra) # 80003c6e <dirlookup>
    80003e9e:	e93d                	bnez	a0,80003f14 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ea0:	04c92483          	lw	s1,76(s2)
    80003ea4:	c49d                	beqz	s1,80003ed2 <dirlink+0x54>
    80003ea6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea8:	4741                	li	a4,16
    80003eaa:	86a6                	mv	a3,s1
    80003eac:	fc040613          	addi	a2,s0,-64
    80003eb0:	4581                	li	a1,0
    80003eb2:	854a                	mv	a0,s2
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	b90080e7          	jalr	-1136(ra) # 80003a44 <readi>
    80003ebc:	47c1                	li	a5,16
    80003ebe:	06f51163          	bne	a0,a5,80003f20 <dirlink+0xa2>
    if(de.inum == 0)
    80003ec2:	fc045783          	lhu	a5,-64(s0)
    80003ec6:	c791                	beqz	a5,80003ed2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec8:	24c1                	addiw	s1,s1,16
    80003eca:	04c92783          	lw	a5,76(s2)
    80003ece:	fcf4ede3          	bltu	s1,a5,80003ea8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ed2:	4639                	li	a2,14
    80003ed4:	85d2                	mv	a1,s4
    80003ed6:	fc240513          	addi	a0,s0,-62
    80003eda:	ffffd097          	auipc	ra,0xffffd
    80003ede:	f94080e7          	jalr	-108(ra) # 80000e6e <strncpy>
  de.inum = inum;
    80003ee2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee6:	4741                	li	a4,16
    80003ee8:	86a6                	mv	a3,s1
    80003eea:	fc040613          	addi	a2,s0,-64
    80003eee:	4581                	li	a1,0
    80003ef0:	854a                	mv	a0,s2
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	c48080e7          	jalr	-952(ra) # 80003b3a <writei>
    80003efa:	872a                	mv	a4,a0
    80003efc:	47c1                	li	a5,16
  return 0;
    80003efe:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f00:	02f71863          	bne	a4,a5,80003f30 <dirlink+0xb2>
}
    80003f04:	70e2                	ld	ra,56(sp)
    80003f06:	7442                	ld	s0,48(sp)
    80003f08:	74a2                	ld	s1,40(sp)
    80003f0a:	7902                	ld	s2,32(sp)
    80003f0c:	69e2                	ld	s3,24(sp)
    80003f0e:	6a42                	ld	s4,16(sp)
    80003f10:	6121                	addi	sp,sp,64
    80003f12:	8082                	ret
    iput(ip);
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	a36080e7          	jalr	-1482(ra) # 8000394a <iput>
    return -1;
    80003f1c:	557d                	li	a0,-1
    80003f1e:	b7dd                	j	80003f04 <dirlink+0x86>
      panic("dirlink read");
    80003f20:	00005517          	auipc	a0,0x5
    80003f24:	86850513          	addi	a0,a0,-1944 # 80008788 <sysnames+0x1d8>
    80003f28:	ffffc097          	auipc	ra,0xffffc
    80003f2c:	620080e7          	jalr	1568(ra) # 80000548 <panic>
    panic("dirlink");
    80003f30:	00005517          	auipc	a0,0x5
    80003f34:	97050513          	addi	a0,a0,-1680 # 800088a0 <sysnames+0x2f0>
    80003f38:	ffffc097          	auipc	ra,0xffffc
    80003f3c:	610080e7          	jalr	1552(ra) # 80000548 <panic>

0000000080003f40 <namei>:

struct inode*
namei(char *path)
{
    80003f40:	1101                	addi	sp,sp,-32
    80003f42:	ec06                	sd	ra,24(sp)
    80003f44:	e822                	sd	s0,16(sp)
    80003f46:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f48:	fe040613          	addi	a2,s0,-32
    80003f4c:	4581                	li	a1,0
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	dd0080e7          	jalr	-560(ra) # 80003d1e <namex>
}
    80003f56:	60e2                	ld	ra,24(sp)
    80003f58:	6442                	ld	s0,16(sp)
    80003f5a:	6105                	addi	sp,sp,32
    80003f5c:	8082                	ret

0000000080003f5e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f5e:	1141                	addi	sp,sp,-16
    80003f60:	e406                	sd	ra,8(sp)
    80003f62:	e022                	sd	s0,0(sp)
    80003f64:	0800                	addi	s0,sp,16
    80003f66:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f68:	4585                	li	a1,1
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	db4080e7          	jalr	-588(ra) # 80003d1e <namex>
}
    80003f72:	60a2                	ld	ra,8(sp)
    80003f74:	6402                	ld	s0,0(sp)
    80003f76:	0141                	addi	sp,sp,16
    80003f78:	8082                	ret

0000000080003f7a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f7a:	1101                	addi	sp,sp,-32
    80003f7c:	ec06                	sd	ra,24(sp)
    80003f7e:	e822                	sd	s0,16(sp)
    80003f80:	e426                	sd	s1,8(sp)
    80003f82:	e04a                	sd	s2,0(sp)
    80003f84:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f86:	0001e917          	auipc	s2,0x1e
    80003f8a:	b8290913          	addi	s2,s2,-1150 # 80021b08 <log>
    80003f8e:	01892583          	lw	a1,24(s2)
    80003f92:	02892503          	lw	a0,40(s2)
    80003f96:	fffff097          	auipc	ra,0xfffff
    80003f9a:	ff8080e7          	jalr	-8(ra) # 80002f8e <bread>
    80003f9e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fa0:	02c92683          	lw	a3,44(s2)
    80003fa4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fa6:	02d05763          	blez	a3,80003fd4 <write_head+0x5a>
    80003faa:	0001e797          	auipc	a5,0x1e
    80003fae:	b8e78793          	addi	a5,a5,-1138 # 80021b38 <log+0x30>
    80003fb2:	05c50713          	addi	a4,a0,92
    80003fb6:	36fd                	addiw	a3,a3,-1
    80003fb8:	1682                	slli	a3,a3,0x20
    80003fba:	9281                	srli	a3,a3,0x20
    80003fbc:	068a                	slli	a3,a3,0x2
    80003fbe:	0001e617          	auipc	a2,0x1e
    80003fc2:	b7e60613          	addi	a2,a2,-1154 # 80021b3c <log+0x34>
    80003fc6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fc8:	4390                	lw	a2,0(a5)
    80003fca:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fcc:	0791                	addi	a5,a5,4
    80003fce:	0711                	addi	a4,a4,4
    80003fd0:	fed79ce3          	bne	a5,a3,80003fc8 <write_head+0x4e>
  }
  bwrite(buf);
    80003fd4:	8526                	mv	a0,s1
    80003fd6:	fffff097          	auipc	ra,0xfffff
    80003fda:	0aa080e7          	jalr	170(ra) # 80003080 <bwrite>
  brelse(buf);
    80003fde:	8526                	mv	a0,s1
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	0de080e7          	jalr	222(ra) # 800030be <brelse>
}
    80003fe8:	60e2                	ld	ra,24(sp)
    80003fea:	6442                	ld	s0,16(sp)
    80003fec:	64a2                	ld	s1,8(sp)
    80003fee:	6902                	ld	s2,0(sp)
    80003ff0:	6105                	addi	sp,sp,32
    80003ff2:	8082                	ret

0000000080003ff4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ff4:	0001e797          	auipc	a5,0x1e
    80003ff8:	b407a783          	lw	a5,-1216(a5) # 80021b34 <log+0x2c>
    80003ffc:	0af05663          	blez	a5,800040a8 <install_trans+0xb4>
{
    80004000:	7139                	addi	sp,sp,-64
    80004002:	fc06                	sd	ra,56(sp)
    80004004:	f822                	sd	s0,48(sp)
    80004006:	f426                	sd	s1,40(sp)
    80004008:	f04a                	sd	s2,32(sp)
    8000400a:	ec4e                	sd	s3,24(sp)
    8000400c:	e852                	sd	s4,16(sp)
    8000400e:	e456                	sd	s5,8(sp)
    80004010:	0080                	addi	s0,sp,64
    80004012:	0001ea97          	auipc	s5,0x1e
    80004016:	b26a8a93          	addi	s5,s5,-1242 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000401a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000401c:	0001e997          	auipc	s3,0x1e
    80004020:	aec98993          	addi	s3,s3,-1300 # 80021b08 <log>
    80004024:	0189a583          	lw	a1,24(s3)
    80004028:	014585bb          	addw	a1,a1,s4
    8000402c:	2585                	addiw	a1,a1,1
    8000402e:	0289a503          	lw	a0,40(s3)
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	f5c080e7          	jalr	-164(ra) # 80002f8e <bread>
    8000403a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000403c:	000aa583          	lw	a1,0(s5)
    80004040:	0289a503          	lw	a0,40(s3)
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	f4a080e7          	jalr	-182(ra) # 80002f8e <bread>
    8000404c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000404e:	40000613          	li	a2,1024
    80004052:	05890593          	addi	a1,s2,88
    80004056:	05850513          	addi	a0,a0,88
    8000405a:	ffffd097          	auipc	ra,0xffffd
    8000405e:	d5c080e7          	jalr	-676(ra) # 80000db6 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004062:	8526                	mv	a0,s1
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	01c080e7          	jalr	28(ra) # 80003080 <bwrite>
    bunpin(dbuf);
    8000406c:	8526                	mv	a0,s1
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	12a080e7          	jalr	298(ra) # 80003198 <bunpin>
    brelse(lbuf);
    80004076:	854a                	mv	a0,s2
    80004078:	fffff097          	auipc	ra,0xfffff
    8000407c:	046080e7          	jalr	70(ra) # 800030be <brelse>
    brelse(dbuf);
    80004080:	8526                	mv	a0,s1
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	03c080e7          	jalr	60(ra) # 800030be <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000408a:	2a05                	addiw	s4,s4,1
    8000408c:	0a91                	addi	s5,s5,4
    8000408e:	02c9a783          	lw	a5,44(s3)
    80004092:	f8fa49e3          	blt	s4,a5,80004024 <install_trans+0x30>
}
    80004096:	70e2                	ld	ra,56(sp)
    80004098:	7442                	ld	s0,48(sp)
    8000409a:	74a2                	ld	s1,40(sp)
    8000409c:	7902                	ld	s2,32(sp)
    8000409e:	69e2                	ld	s3,24(sp)
    800040a0:	6a42                	ld	s4,16(sp)
    800040a2:	6aa2                	ld	s5,8(sp)
    800040a4:	6121                	addi	sp,sp,64
    800040a6:	8082                	ret
    800040a8:	8082                	ret

00000000800040aa <initlog>:
{
    800040aa:	7179                	addi	sp,sp,-48
    800040ac:	f406                	sd	ra,40(sp)
    800040ae:	f022                	sd	s0,32(sp)
    800040b0:	ec26                	sd	s1,24(sp)
    800040b2:	e84a                	sd	s2,16(sp)
    800040b4:	e44e                	sd	s3,8(sp)
    800040b6:	1800                	addi	s0,sp,48
    800040b8:	892a                	mv	s2,a0
    800040ba:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040bc:	0001e497          	auipc	s1,0x1e
    800040c0:	a4c48493          	addi	s1,s1,-1460 # 80021b08 <log>
    800040c4:	00004597          	auipc	a1,0x4
    800040c8:	6d458593          	addi	a1,a1,1748 # 80008798 <sysnames+0x1e8>
    800040cc:	8526                	mv	a0,s1
    800040ce:	ffffd097          	auipc	ra,0xffffd
    800040d2:	afc080e7          	jalr	-1284(ra) # 80000bca <initlock>
  log.start = sb->logstart;
    800040d6:	0149a583          	lw	a1,20(s3)
    800040da:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040dc:	0109a783          	lw	a5,16(s3)
    800040e0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040e2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040e6:	854a                	mv	a0,s2
    800040e8:	fffff097          	auipc	ra,0xfffff
    800040ec:	ea6080e7          	jalr	-346(ra) # 80002f8e <bread>
  log.lh.n = lh->n;
    800040f0:	4d3c                	lw	a5,88(a0)
    800040f2:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040f4:	02f05563          	blez	a5,8000411e <initlog+0x74>
    800040f8:	05c50713          	addi	a4,a0,92
    800040fc:	0001e697          	auipc	a3,0x1e
    80004100:	a3c68693          	addi	a3,a3,-1476 # 80021b38 <log+0x30>
    80004104:	37fd                	addiw	a5,a5,-1
    80004106:	1782                	slli	a5,a5,0x20
    80004108:	9381                	srli	a5,a5,0x20
    8000410a:	078a                	slli	a5,a5,0x2
    8000410c:	06050613          	addi	a2,a0,96
    80004110:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004112:	4310                	lw	a2,0(a4)
    80004114:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004116:	0711                	addi	a4,a4,4
    80004118:	0691                	addi	a3,a3,4
    8000411a:	fef71ce3          	bne	a4,a5,80004112 <initlog+0x68>
  brelse(buf);
    8000411e:	fffff097          	auipc	ra,0xfffff
    80004122:	fa0080e7          	jalr	-96(ra) # 800030be <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004126:	00000097          	auipc	ra,0x0
    8000412a:	ece080e7          	jalr	-306(ra) # 80003ff4 <install_trans>
  log.lh.n = 0;
    8000412e:	0001e797          	auipc	a5,0x1e
    80004132:	a007a323          	sw	zero,-1530(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	e44080e7          	jalr	-444(ra) # 80003f7a <write_head>
}
    8000413e:	70a2                	ld	ra,40(sp)
    80004140:	7402                	ld	s0,32(sp)
    80004142:	64e2                	ld	s1,24(sp)
    80004144:	6942                	ld	s2,16(sp)
    80004146:	69a2                	ld	s3,8(sp)
    80004148:	6145                	addi	sp,sp,48
    8000414a:	8082                	ret

000000008000414c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000414c:	1101                	addi	sp,sp,-32
    8000414e:	ec06                	sd	ra,24(sp)
    80004150:	e822                	sd	s0,16(sp)
    80004152:	e426                	sd	s1,8(sp)
    80004154:	e04a                	sd	s2,0(sp)
    80004156:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004158:	0001e517          	auipc	a0,0x1e
    8000415c:	9b050513          	addi	a0,a0,-1616 # 80021b08 <log>
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	afa080e7          	jalr	-1286(ra) # 80000c5a <acquire>
  while(1){
    if(log.committing){
    80004168:	0001e497          	auipc	s1,0x1e
    8000416c:	9a048493          	addi	s1,s1,-1632 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004170:	4979                	li	s2,30
    80004172:	a039                	j	80004180 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004174:	85a6                	mv	a1,s1
    80004176:	8526                	mv	a0,s1
    80004178:	ffffe097          	auipc	ra,0xffffe
    8000417c:	0c8080e7          	jalr	200(ra) # 80002240 <sleep>
    if(log.committing){
    80004180:	50dc                	lw	a5,36(s1)
    80004182:	fbed                	bnez	a5,80004174 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004184:	509c                	lw	a5,32(s1)
    80004186:	0017871b          	addiw	a4,a5,1
    8000418a:	0007069b          	sext.w	a3,a4
    8000418e:	0027179b          	slliw	a5,a4,0x2
    80004192:	9fb9                	addw	a5,a5,a4
    80004194:	0017979b          	slliw	a5,a5,0x1
    80004198:	54d8                	lw	a4,44(s1)
    8000419a:	9fb9                	addw	a5,a5,a4
    8000419c:	00f95963          	bge	s2,a5,800041ae <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041a0:	85a6                	mv	a1,s1
    800041a2:	8526                	mv	a0,s1
    800041a4:	ffffe097          	auipc	ra,0xffffe
    800041a8:	09c080e7          	jalr	156(ra) # 80002240 <sleep>
    800041ac:	bfd1                	j	80004180 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041ae:	0001e517          	auipc	a0,0x1e
    800041b2:	95a50513          	addi	a0,a0,-1702 # 80021b08 <log>
    800041b6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041b8:	ffffd097          	auipc	ra,0xffffd
    800041bc:	b56080e7          	jalr	-1194(ra) # 80000d0e <release>
      break;
    }
  }
}
    800041c0:	60e2                	ld	ra,24(sp)
    800041c2:	6442                	ld	s0,16(sp)
    800041c4:	64a2                	ld	s1,8(sp)
    800041c6:	6902                	ld	s2,0(sp)
    800041c8:	6105                	addi	sp,sp,32
    800041ca:	8082                	ret

00000000800041cc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041cc:	7139                	addi	sp,sp,-64
    800041ce:	fc06                	sd	ra,56(sp)
    800041d0:	f822                	sd	s0,48(sp)
    800041d2:	f426                	sd	s1,40(sp)
    800041d4:	f04a                	sd	s2,32(sp)
    800041d6:	ec4e                	sd	s3,24(sp)
    800041d8:	e852                	sd	s4,16(sp)
    800041da:	e456                	sd	s5,8(sp)
    800041dc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041de:	0001e497          	auipc	s1,0x1e
    800041e2:	92a48493          	addi	s1,s1,-1750 # 80021b08 <log>
    800041e6:	8526                	mv	a0,s1
    800041e8:	ffffd097          	auipc	ra,0xffffd
    800041ec:	a72080e7          	jalr	-1422(ra) # 80000c5a <acquire>
  log.outstanding -= 1;
    800041f0:	509c                	lw	a5,32(s1)
    800041f2:	37fd                	addiw	a5,a5,-1
    800041f4:	0007891b          	sext.w	s2,a5
    800041f8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041fa:	50dc                	lw	a5,36(s1)
    800041fc:	efb9                	bnez	a5,8000425a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041fe:	06091663          	bnez	s2,8000426a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004202:	0001e497          	auipc	s1,0x1e
    80004206:	90648493          	addi	s1,s1,-1786 # 80021b08 <log>
    8000420a:	4785                	li	a5,1
    8000420c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000420e:	8526                	mv	a0,s1
    80004210:	ffffd097          	auipc	ra,0xffffd
    80004214:	afe080e7          	jalr	-1282(ra) # 80000d0e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004218:	54dc                	lw	a5,44(s1)
    8000421a:	06f04763          	bgtz	a5,80004288 <end_op+0xbc>
    acquire(&log.lock);
    8000421e:	0001e497          	auipc	s1,0x1e
    80004222:	8ea48493          	addi	s1,s1,-1814 # 80021b08 <log>
    80004226:	8526                	mv	a0,s1
    80004228:	ffffd097          	auipc	ra,0xffffd
    8000422c:	a32080e7          	jalr	-1486(ra) # 80000c5a <acquire>
    log.committing = 0;
    80004230:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004234:	8526                	mv	a0,s1
    80004236:	ffffe097          	auipc	ra,0xffffe
    8000423a:	190080e7          	jalr	400(ra) # 800023c6 <wakeup>
    release(&log.lock);
    8000423e:	8526                	mv	a0,s1
    80004240:	ffffd097          	auipc	ra,0xffffd
    80004244:	ace080e7          	jalr	-1330(ra) # 80000d0e <release>
}
    80004248:	70e2                	ld	ra,56(sp)
    8000424a:	7442                	ld	s0,48(sp)
    8000424c:	74a2                	ld	s1,40(sp)
    8000424e:	7902                	ld	s2,32(sp)
    80004250:	69e2                	ld	s3,24(sp)
    80004252:	6a42                	ld	s4,16(sp)
    80004254:	6aa2                	ld	s5,8(sp)
    80004256:	6121                	addi	sp,sp,64
    80004258:	8082                	ret
    panic("log.committing");
    8000425a:	00004517          	auipc	a0,0x4
    8000425e:	54650513          	addi	a0,a0,1350 # 800087a0 <sysnames+0x1f0>
    80004262:	ffffc097          	auipc	ra,0xffffc
    80004266:	2e6080e7          	jalr	742(ra) # 80000548 <panic>
    wakeup(&log);
    8000426a:	0001e497          	auipc	s1,0x1e
    8000426e:	89e48493          	addi	s1,s1,-1890 # 80021b08 <log>
    80004272:	8526                	mv	a0,s1
    80004274:	ffffe097          	auipc	ra,0xffffe
    80004278:	152080e7          	jalr	338(ra) # 800023c6 <wakeup>
  release(&log.lock);
    8000427c:	8526                	mv	a0,s1
    8000427e:	ffffd097          	auipc	ra,0xffffd
    80004282:	a90080e7          	jalr	-1392(ra) # 80000d0e <release>
  if(do_commit){
    80004286:	b7c9                	j	80004248 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004288:	0001ea97          	auipc	s5,0x1e
    8000428c:	8b0a8a93          	addi	s5,s5,-1872 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004290:	0001ea17          	auipc	s4,0x1e
    80004294:	878a0a13          	addi	s4,s4,-1928 # 80021b08 <log>
    80004298:	018a2583          	lw	a1,24(s4)
    8000429c:	012585bb          	addw	a1,a1,s2
    800042a0:	2585                	addiw	a1,a1,1
    800042a2:	028a2503          	lw	a0,40(s4)
    800042a6:	fffff097          	auipc	ra,0xfffff
    800042aa:	ce8080e7          	jalr	-792(ra) # 80002f8e <bread>
    800042ae:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042b0:	000aa583          	lw	a1,0(s5)
    800042b4:	028a2503          	lw	a0,40(s4)
    800042b8:	fffff097          	auipc	ra,0xfffff
    800042bc:	cd6080e7          	jalr	-810(ra) # 80002f8e <bread>
    800042c0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042c2:	40000613          	li	a2,1024
    800042c6:	05850593          	addi	a1,a0,88
    800042ca:	05848513          	addi	a0,s1,88
    800042ce:	ffffd097          	auipc	ra,0xffffd
    800042d2:	ae8080e7          	jalr	-1304(ra) # 80000db6 <memmove>
    bwrite(to);  // write the log
    800042d6:	8526                	mv	a0,s1
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	da8080e7          	jalr	-600(ra) # 80003080 <bwrite>
    brelse(from);
    800042e0:	854e                	mv	a0,s3
    800042e2:	fffff097          	auipc	ra,0xfffff
    800042e6:	ddc080e7          	jalr	-548(ra) # 800030be <brelse>
    brelse(to);
    800042ea:	8526                	mv	a0,s1
    800042ec:	fffff097          	auipc	ra,0xfffff
    800042f0:	dd2080e7          	jalr	-558(ra) # 800030be <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042f4:	2905                	addiw	s2,s2,1
    800042f6:	0a91                	addi	s5,s5,4
    800042f8:	02ca2783          	lw	a5,44(s4)
    800042fc:	f8f94ee3          	blt	s2,a5,80004298 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004300:	00000097          	auipc	ra,0x0
    80004304:	c7a080e7          	jalr	-902(ra) # 80003f7a <write_head>
    install_trans(); // Now install writes to home locations
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	cec080e7          	jalr	-788(ra) # 80003ff4 <install_trans>
    log.lh.n = 0;
    80004310:	0001e797          	auipc	a5,0x1e
    80004314:	8207a223          	sw	zero,-2012(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004318:	00000097          	auipc	ra,0x0
    8000431c:	c62080e7          	jalr	-926(ra) # 80003f7a <write_head>
    80004320:	bdfd                	j	8000421e <end_op+0x52>

0000000080004322 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004322:	1101                	addi	sp,sp,-32
    80004324:	ec06                	sd	ra,24(sp)
    80004326:	e822                	sd	s0,16(sp)
    80004328:	e426                	sd	s1,8(sp)
    8000432a:	e04a                	sd	s2,0(sp)
    8000432c:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000432e:	0001e717          	auipc	a4,0x1e
    80004332:	80672703          	lw	a4,-2042(a4) # 80021b34 <log+0x2c>
    80004336:	47f5                	li	a5,29
    80004338:	08e7c063          	blt	a5,a4,800043b8 <log_write+0x96>
    8000433c:	84aa                	mv	s1,a0
    8000433e:	0001d797          	auipc	a5,0x1d
    80004342:	7e67a783          	lw	a5,2022(a5) # 80021b24 <log+0x1c>
    80004346:	37fd                	addiw	a5,a5,-1
    80004348:	06f75863          	bge	a4,a5,800043b8 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000434c:	0001d797          	auipc	a5,0x1d
    80004350:	7dc7a783          	lw	a5,2012(a5) # 80021b28 <log+0x20>
    80004354:	06f05a63          	blez	a5,800043c8 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004358:	0001d917          	auipc	s2,0x1d
    8000435c:	7b090913          	addi	s2,s2,1968 # 80021b08 <log>
    80004360:	854a                	mv	a0,s2
    80004362:	ffffd097          	auipc	ra,0xffffd
    80004366:	8f8080e7          	jalr	-1800(ra) # 80000c5a <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000436a:	02c92603          	lw	a2,44(s2)
    8000436e:	06c05563          	blez	a2,800043d8 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004372:	44cc                	lw	a1,12(s1)
    80004374:	0001d717          	auipc	a4,0x1d
    80004378:	7c470713          	addi	a4,a4,1988 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000437c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000437e:	4314                	lw	a3,0(a4)
    80004380:	04b68d63          	beq	a3,a1,800043da <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004384:	2785                	addiw	a5,a5,1
    80004386:	0711                	addi	a4,a4,4
    80004388:	fec79be3          	bne	a5,a2,8000437e <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000438c:	0621                	addi	a2,a2,8
    8000438e:	060a                	slli	a2,a2,0x2
    80004390:	0001d797          	auipc	a5,0x1d
    80004394:	77878793          	addi	a5,a5,1912 # 80021b08 <log>
    80004398:	963e                	add	a2,a2,a5
    8000439a:	44dc                	lw	a5,12(s1)
    8000439c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000439e:	8526                	mv	a0,s1
    800043a0:	fffff097          	auipc	ra,0xfffff
    800043a4:	dbc080e7          	jalr	-580(ra) # 8000315c <bpin>
    log.lh.n++;
    800043a8:	0001d717          	auipc	a4,0x1d
    800043ac:	76070713          	addi	a4,a4,1888 # 80021b08 <log>
    800043b0:	575c                	lw	a5,44(a4)
    800043b2:	2785                	addiw	a5,a5,1
    800043b4:	d75c                	sw	a5,44(a4)
    800043b6:	a83d                	j	800043f4 <log_write+0xd2>
    panic("too big a transaction");
    800043b8:	00004517          	auipc	a0,0x4
    800043bc:	3f850513          	addi	a0,a0,1016 # 800087b0 <sysnames+0x200>
    800043c0:	ffffc097          	auipc	ra,0xffffc
    800043c4:	188080e7          	jalr	392(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800043c8:	00004517          	auipc	a0,0x4
    800043cc:	40050513          	addi	a0,a0,1024 # 800087c8 <sysnames+0x218>
    800043d0:	ffffc097          	auipc	ra,0xffffc
    800043d4:	178080e7          	jalr	376(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800043d8:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800043da:	00878713          	addi	a4,a5,8
    800043de:	00271693          	slli	a3,a4,0x2
    800043e2:	0001d717          	auipc	a4,0x1d
    800043e6:	72670713          	addi	a4,a4,1830 # 80021b08 <log>
    800043ea:	9736                	add	a4,a4,a3
    800043ec:	44d4                	lw	a3,12(s1)
    800043ee:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043f0:	faf607e3          	beq	a2,a5,8000439e <log_write+0x7c>
  }
  release(&log.lock);
    800043f4:	0001d517          	auipc	a0,0x1d
    800043f8:	71450513          	addi	a0,a0,1812 # 80021b08 <log>
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	912080e7          	jalr	-1774(ra) # 80000d0e <release>
}
    80004404:	60e2                	ld	ra,24(sp)
    80004406:	6442                	ld	s0,16(sp)
    80004408:	64a2                	ld	s1,8(sp)
    8000440a:	6902                	ld	s2,0(sp)
    8000440c:	6105                	addi	sp,sp,32
    8000440e:	8082                	ret

0000000080004410 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004410:	1101                	addi	sp,sp,-32
    80004412:	ec06                	sd	ra,24(sp)
    80004414:	e822                	sd	s0,16(sp)
    80004416:	e426                	sd	s1,8(sp)
    80004418:	e04a                	sd	s2,0(sp)
    8000441a:	1000                	addi	s0,sp,32
    8000441c:	84aa                	mv	s1,a0
    8000441e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004420:	00004597          	auipc	a1,0x4
    80004424:	3c858593          	addi	a1,a1,968 # 800087e8 <sysnames+0x238>
    80004428:	0521                	addi	a0,a0,8
    8000442a:	ffffc097          	auipc	ra,0xffffc
    8000442e:	7a0080e7          	jalr	1952(ra) # 80000bca <initlock>
  lk->name = name;
    80004432:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004436:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000443a:	0204a423          	sw	zero,40(s1)
}
    8000443e:	60e2                	ld	ra,24(sp)
    80004440:	6442                	ld	s0,16(sp)
    80004442:	64a2                	ld	s1,8(sp)
    80004444:	6902                	ld	s2,0(sp)
    80004446:	6105                	addi	sp,sp,32
    80004448:	8082                	ret

000000008000444a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000444a:	1101                	addi	sp,sp,-32
    8000444c:	ec06                	sd	ra,24(sp)
    8000444e:	e822                	sd	s0,16(sp)
    80004450:	e426                	sd	s1,8(sp)
    80004452:	e04a                	sd	s2,0(sp)
    80004454:	1000                	addi	s0,sp,32
    80004456:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004458:	00850913          	addi	s2,a0,8
    8000445c:	854a                	mv	a0,s2
    8000445e:	ffffc097          	auipc	ra,0xffffc
    80004462:	7fc080e7          	jalr	2044(ra) # 80000c5a <acquire>
  while (lk->locked) {
    80004466:	409c                	lw	a5,0(s1)
    80004468:	cb89                	beqz	a5,8000447a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000446a:	85ca                	mv	a1,s2
    8000446c:	8526                	mv	a0,s1
    8000446e:	ffffe097          	auipc	ra,0xffffe
    80004472:	dd2080e7          	jalr	-558(ra) # 80002240 <sleep>
  while (lk->locked) {
    80004476:	409c                	lw	a5,0(s1)
    80004478:	fbed                	bnez	a5,8000446a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000447a:	4785                	li	a5,1
    8000447c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	5aa080e7          	jalr	1450(ra) # 80001a28 <myproc>
    80004486:	5d1c                	lw	a5,56(a0)
    80004488:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000448a:	854a                	mv	a0,s2
    8000448c:	ffffd097          	auipc	ra,0xffffd
    80004490:	882080e7          	jalr	-1918(ra) # 80000d0e <release>
}
    80004494:	60e2                	ld	ra,24(sp)
    80004496:	6442                	ld	s0,16(sp)
    80004498:	64a2                	ld	s1,8(sp)
    8000449a:	6902                	ld	s2,0(sp)
    8000449c:	6105                	addi	sp,sp,32
    8000449e:	8082                	ret

00000000800044a0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044a0:	1101                	addi	sp,sp,-32
    800044a2:	ec06                	sd	ra,24(sp)
    800044a4:	e822                	sd	s0,16(sp)
    800044a6:	e426                	sd	s1,8(sp)
    800044a8:	e04a                	sd	s2,0(sp)
    800044aa:	1000                	addi	s0,sp,32
    800044ac:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ae:	00850913          	addi	s2,a0,8
    800044b2:	854a                	mv	a0,s2
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	7a6080e7          	jalr	1958(ra) # 80000c5a <acquire>
  lk->locked = 0;
    800044bc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044c0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044c4:	8526                	mv	a0,s1
    800044c6:	ffffe097          	auipc	ra,0xffffe
    800044ca:	f00080e7          	jalr	-256(ra) # 800023c6 <wakeup>
  release(&lk->lk);
    800044ce:	854a                	mv	a0,s2
    800044d0:	ffffd097          	auipc	ra,0xffffd
    800044d4:	83e080e7          	jalr	-1986(ra) # 80000d0e <release>
}
    800044d8:	60e2                	ld	ra,24(sp)
    800044da:	6442                	ld	s0,16(sp)
    800044dc:	64a2                	ld	s1,8(sp)
    800044de:	6902                	ld	s2,0(sp)
    800044e0:	6105                	addi	sp,sp,32
    800044e2:	8082                	ret

00000000800044e4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044e4:	7179                	addi	sp,sp,-48
    800044e6:	f406                	sd	ra,40(sp)
    800044e8:	f022                	sd	s0,32(sp)
    800044ea:	ec26                	sd	s1,24(sp)
    800044ec:	e84a                	sd	s2,16(sp)
    800044ee:	e44e                	sd	s3,8(sp)
    800044f0:	1800                	addi	s0,sp,48
    800044f2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044f4:	00850913          	addi	s2,a0,8
    800044f8:	854a                	mv	a0,s2
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	760080e7          	jalr	1888(ra) # 80000c5a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004502:	409c                	lw	a5,0(s1)
    80004504:	ef99                	bnez	a5,80004522 <holdingsleep+0x3e>
    80004506:	4481                	li	s1,0
  release(&lk->lk);
    80004508:	854a                	mv	a0,s2
    8000450a:	ffffd097          	auipc	ra,0xffffd
    8000450e:	804080e7          	jalr	-2044(ra) # 80000d0e <release>
  return r;
}
    80004512:	8526                	mv	a0,s1
    80004514:	70a2                	ld	ra,40(sp)
    80004516:	7402                	ld	s0,32(sp)
    80004518:	64e2                	ld	s1,24(sp)
    8000451a:	6942                	ld	s2,16(sp)
    8000451c:	69a2                	ld	s3,8(sp)
    8000451e:	6145                	addi	sp,sp,48
    80004520:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004522:	0284a983          	lw	s3,40(s1)
    80004526:	ffffd097          	auipc	ra,0xffffd
    8000452a:	502080e7          	jalr	1282(ra) # 80001a28 <myproc>
    8000452e:	5d04                	lw	s1,56(a0)
    80004530:	413484b3          	sub	s1,s1,s3
    80004534:	0014b493          	seqz	s1,s1
    80004538:	bfc1                	j	80004508 <holdingsleep+0x24>

000000008000453a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000453a:	1141                	addi	sp,sp,-16
    8000453c:	e406                	sd	ra,8(sp)
    8000453e:	e022                	sd	s0,0(sp)
    80004540:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004542:	00004597          	auipc	a1,0x4
    80004546:	2b658593          	addi	a1,a1,694 # 800087f8 <sysnames+0x248>
    8000454a:	0001d517          	auipc	a0,0x1d
    8000454e:	70650513          	addi	a0,a0,1798 # 80021c50 <ftable>
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	678080e7          	jalr	1656(ra) # 80000bca <initlock>
}
    8000455a:	60a2                	ld	ra,8(sp)
    8000455c:	6402                	ld	s0,0(sp)
    8000455e:	0141                	addi	sp,sp,16
    80004560:	8082                	ret

0000000080004562 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004562:	1101                	addi	sp,sp,-32
    80004564:	ec06                	sd	ra,24(sp)
    80004566:	e822                	sd	s0,16(sp)
    80004568:	e426                	sd	s1,8(sp)
    8000456a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000456c:	0001d517          	auipc	a0,0x1d
    80004570:	6e450513          	addi	a0,a0,1764 # 80021c50 <ftable>
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	6e6080e7          	jalr	1766(ra) # 80000c5a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000457c:	0001d497          	auipc	s1,0x1d
    80004580:	6ec48493          	addi	s1,s1,1772 # 80021c68 <ftable+0x18>
    80004584:	0001e717          	auipc	a4,0x1e
    80004588:	68470713          	addi	a4,a4,1668 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    8000458c:	40dc                	lw	a5,4(s1)
    8000458e:	cf99                	beqz	a5,800045ac <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004590:	02848493          	addi	s1,s1,40
    80004594:	fee49ce3          	bne	s1,a4,8000458c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004598:	0001d517          	auipc	a0,0x1d
    8000459c:	6b850513          	addi	a0,a0,1720 # 80021c50 <ftable>
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	76e080e7          	jalr	1902(ra) # 80000d0e <release>
  return 0;
    800045a8:	4481                	li	s1,0
    800045aa:	a819                	j	800045c0 <filealloc+0x5e>
      f->ref = 1;
    800045ac:	4785                	li	a5,1
    800045ae:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045b0:	0001d517          	auipc	a0,0x1d
    800045b4:	6a050513          	addi	a0,a0,1696 # 80021c50 <ftable>
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	756080e7          	jalr	1878(ra) # 80000d0e <release>
}
    800045c0:	8526                	mv	a0,s1
    800045c2:	60e2                	ld	ra,24(sp)
    800045c4:	6442                	ld	s0,16(sp)
    800045c6:	64a2                	ld	s1,8(sp)
    800045c8:	6105                	addi	sp,sp,32
    800045ca:	8082                	ret

00000000800045cc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045cc:	1101                	addi	sp,sp,-32
    800045ce:	ec06                	sd	ra,24(sp)
    800045d0:	e822                	sd	s0,16(sp)
    800045d2:	e426                	sd	s1,8(sp)
    800045d4:	1000                	addi	s0,sp,32
    800045d6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045d8:	0001d517          	auipc	a0,0x1d
    800045dc:	67850513          	addi	a0,a0,1656 # 80021c50 <ftable>
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	67a080e7          	jalr	1658(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    800045e8:	40dc                	lw	a5,4(s1)
    800045ea:	02f05263          	blez	a5,8000460e <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045ee:	2785                	addiw	a5,a5,1
    800045f0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045f2:	0001d517          	auipc	a0,0x1d
    800045f6:	65e50513          	addi	a0,a0,1630 # 80021c50 <ftable>
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	714080e7          	jalr	1812(ra) # 80000d0e <release>
  return f;
}
    80004602:	8526                	mv	a0,s1
    80004604:	60e2                	ld	ra,24(sp)
    80004606:	6442                	ld	s0,16(sp)
    80004608:	64a2                	ld	s1,8(sp)
    8000460a:	6105                	addi	sp,sp,32
    8000460c:	8082                	ret
    panic("filedup");
    8000460e:	00004517          	auipc	a0,0x4
    80004612:	1f250513          	addi	a0,a0,498 # 80008800 <sysnames+0x250>
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	f32080e7          	jalr	-206(ra) # 80000548 <panic>

000000008000461e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000461e:	7139                	addi	sp,sp,-64
    80004620:	fc06                	sd	ra,56(sp)
    80004622:	f822                	sd	s0,48(sp)
    80004624:	f426                	sd	s1,40(sp)
    80004626:	f04a                	sd	s2,32(sp)
    80004628:	ec4e                	sd	s3,24(sp)
    8000462a:	e852                	sd	s4,16(sp)
    8000462c:	e456                	sd	s5,8(sp)
    8000462e:	0080                	addi	s0,sp,64
    80004630:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004632:	0001d517          	auipc	a0,0x1d
    80004636:	61e50513          	addi	a0,a0,1566 # 80021c50 <ftable>
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	620080e7          	jalr	1568(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    80004642:	40dc                	lw	a5,4(s1)
    80004644:	06f05163          	blez	a5,800046a6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004648:	37fd                	addiw	a5,a5,-1
    8000464a:	0007871b          	sext.w	a4,a5
    8000464e:	c0dc                	sw	a5,4(s1)
    80004650:	06e04363          	bgtz	a4,800046b6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004654:	0004a903          	lw	s2,0(s1)
    80004658:	0094ca83          	lbu	s5,9(s1)
    8000465c:	0104ba03          	ld	s4,16(s1)
    80004660:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004664:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004668:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000466c:	0001d517          	auipc	a0,0x1d
    80004670:	5e450513          	addi	a0,a0,1508 # 80021c50 <ftable>
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	69a080e7          	jalr	1690(ra) # 80000d0e <release>

  if(ff.type == FD_PIPE){
    8000467c:	4785                	li	a5,1
    8000467e:	04f90d63          	beq	s2,a5,800046d8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004682:	3979                	addiw	s2,s2,-2
    80004684:	4785                	li	a5,1
    80004686:	0527e063          	bltu	a5,s2,800046c6 <fileclose+0xa8>
    begin_op();
    8000468a:	00000097          	auipc	ra,0x0
    8000468e:	ac2080e7          	jalr	-1342(ra) # 8000414c <begin_op>
    iput(ff.ip);
    80004692:	854e                	mv	a0,s3
    80004694:	fffff097          	auipc	ra,0xfffff
    80004698:	2b6080e7          	jalr	694(ra) # 8000394a <iput>
    end_op();
    8000469c:	00000097          	auipc	ra,0x0
    800046a0:	b30080e7          	jalr	-1232(ra) # 800041cc <end_op>
    800046a4:	a00d                	j	800046c6 <fileclose+0xa8>
    panic("fileclose");
    800046a6:	00004517          	auipc	a0,0x4
    800046aa:	16250513          	addi	a0,a0,354 # 80008808 <sysnames+0x258>
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	e9a080e7          	jalr	-358(ra) # 80000548 <panic>
    release(&ftable.lock);
    800046b6:	0001d517          	auipc	a0,0x1d
    800046ba:	59a50513          	addi	a0,a0,1434 # 80021c50 <ftable>
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	650080e7          	jalr	1616(ra) # 80000d0e <release>
  }
}
    800046c6:	70e2                	ld	ra,56(sp)
    800046c8:	7442                	ld	s0,48(sp)
    800046ca:	74a2                	ld	s1,40(sp)
    800046cc:	7902                	ld	s2,32(sp)
    800046ce:	69e2                	ld	s3,24(sp)
    800046d0:	6a42                	ld	s4,16(sp)
    800046d2:	6aa2                	ld	s5,8(sp)
    800046d4:	6121                	addi	sp,sp,64
    800046d6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046d8:	85d6                	mv	a1,s5
    800046da:	8552                	mv	a0,s4
    800046dc:	00000097          	auipc	ra,0x0
    800046e0:	372080e7          	jalr	882(ra) # 80004a4e <pipeclose>
    800046e4:	b7cd                	j	800046c6 <fileclose+0xa8>

00000000800046e6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046e6:	715d                	addi	sp,sp,-80
    800046e8:	e486                	sd	ra,72(sp)
    800046ea:	e0a2                	sd	s0,64(sp)
    800046ec:	fc26                	sd	s1,56(sp)
    800046ee:	f84a                	sd	s2,48(sp)
    800046f0:	f44e                	sd	s3,40(sp)
    800046f2:	0880                	addi	s0,sp,80
    800046f4:	84aa                	mv	s1,a0
    800046f6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046f8:	ffffd097          	auipc	ra,0xffffd
    800046fc:	330080e7          	jalr	816(ra) # 80001a28 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004700:	409c                	lw	a5,0(s1)
    80004702:	37f9                	addiw	a5,a5,-2
    80004704:	4705                	li	a4,1
    80004706:	04f76763          	bltu	a4,a5,80004754 <filestat+0x6e>
    8000470a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000470c:	6c88                	ld	a0,24(s1)
    8000470e:	fffff097          	auipc	ra,0xfffff
    80004712:	082080e7          	jalr	130(ra) # 80003790 <ilock>
    stati(f->ip, &st);
    80004716:	fb840593          	addi	a1,s0,-72
    8000471a:	6c88                	ld	a0,24(s1)
    8000471c:	fffff097          	auipc	ra,0xfffff
    80004720:	2fe080e7          	jalr	766(ra) # 80003a1a <stati>
    iunlock(f->ip);
    80004724:	6c88                	ld	a0,24(s1)
    80004726:	fffff097          	auipc	ra,0xfffff
    8000472a:	12c080e7          	jalr	300(ra) # 80003852 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000472e:	46e1                	li	a3,24
    80004730:	fb840613          	addi	a2,s0,-72
    80004734:	85ce                	mv	a1,s3
    80004736:	05093503          	ld	a0,80(s2)
    8000473a:	ffffd097          	auipc	ra,0xffffd
    8000473e:	fe2080e7          	jalr	-30(ra) # 8000171c <copyout>
    80004742:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004746:	60a6                	ld	ra,72(sp)
    80004748:	6406                	ld	s0,64(sp)
    8000474a:	74e2                	ld	s1,56(sp)
    8000474c:	7942                	ld	s2,48(sp)
    8000474e:	79a2                	ld	s3,40(sp)
    80004750:	6161                	addi	sp,sp,80
    80004752:	8082                	ret
  return -1;
    80004754:	557d                	li	a0,-1
    80004756:	bfc5                	j	80004746 <filestat+0x60>

0000000080004758 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004758:	7179                	addi	sp,sp,-48
    8000475a:	f406                	sd	ra,40(sp)
    8000475c:	f022                	sd	s0,32(sp)
    8000475e:	ec26                	sd	s1,24(sp)
    80004760:	e84a                	sd	s2,16(sp)
    80004762:	e44e                	sd	s3,8(sp)
    80004764:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004766:	00854783          	lbu	a5,8(a0)
    8000476a:	c3d5                	beqz	a5,8000480e <fileread+0xb6>
    8000476c:	84aa                	mv	s1,a0
    8000476e:	89ae                	mv	s3,a1
    80004770:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004772:	411c                	lw	a5,0(a0)
    80004774:	4705                	li	a4,1
    80004776:	04e78963          	beq	a5,a4,800047c8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000477a:	470d                	li	a4,3
    8000477c:	04e78d63          	beq	a5,a4,800047d6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004780:	4709                	li	a4,2
    80004782:	06e79e63          	bne	a5,a4,800047fe <fileread+0xa6>
    ilock(f->ip);
    80004786:	6d08                	ld	a0,24(a0)
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	008080e7          	jalr	8(ra) # 80003790 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004790:	874a                	mv	a4,s2
    80004792:	5094                	lw	a3,32(s1)
    80004794:	864e                	mv	a2,s3
    80004796:	4585                	li	a1,1
    80004798:	6c88                	ld	a0,24(s1)
    8000479a:	fffff097          	auipc	ra,0xfffff
    8000479e:	2aa080e7          	jalr	682(ra) # 80003a44 <readi>
    800047a2:	892a                	mv	s2,a0
    800047a4:	00a05563          	blez	a0,800047ae <fileread+0x56>
      f->off += r;
    800047a8:	509c                	lw	a5,32(s1)
    800047aa:	9fa9                	addw	a5,a5,a0
    800047ac:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047ae:	6c88                	ld	a0,24(s1)
    800047b0:	fffff097          	auipc	ra,0xfffff
    800047b4:	0a2080e7          	jalr	162(ra) # 80003852 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047b8:	854a                	mv	a0,s2
    800047ba:	70a2                	ld	ra,40(sp)
    800047bc:	7402                	ld	s0,32(sp)
    800047be:	64e2                	ld	s1,24(sp)
    800047c0:	6942                	ld	s2,16(sp)
    800047c2:	69a2                	ld	s3,8(sp)
    800047c4:	6145                	addi	sp,sp,48
    800047c6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047c8:	6908                	ld	a0,16(a0)
    800047ca:	00000097          	auipc	ra,0x0
    800047ce:	418080e7          	jalr	1048(ra) # 80004be2 <piperead>
    800047d2:	892a                	mv	s2,a0
    800047d4:	b7d5                	j	800047b8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047d6:	02451783          	lh	a5,36(a0)
    800047da:	03079693          	slli	a3,a5,0x30
    800047de:	92c1                	srli	a3,a3,0x30
    800047e0:	4725                	li	a4,9
    800047e2:	02d76863          	bltu	a4,a3,80004812 <fileread+0xba>
    800047e6:	0792                	slli	a5,a5,0x4
    800047e8:	0001d717          	auipc	a4,0x1d
    800047ec:	3c870713          	addi	a4,a4,968 # 80021bb0 <devsw>
    800047f0:	97ba                	add	a5,a5,a4
    800047f2:	639c                	ld	a5,0(a5)
    800047f4:	c38d                	beqz	a5,80004816 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047f6:	4505                	li	a0,1
    800047f8:	9782                	jalr	a5
    800047fa:	892a                	mv	s2,a0
    800047fc:	bf75                	j	800047b8 <fileread+0x60>
    panic("fileread");
    800047fe:	00004517          	auipc	a0,0x4
    80004802:	01a50513          	addi	a0,a0,26 # 80008818 <sysnames+0x268>
    80004806:	ffffc097          	auipc	ra,0xffffc
    8000480a:	d42080e7          	jalr	-702(ra) # 80000548 <panic>
    return -1;
    8000480e:	597d                	li	s2,-1
    80004810:	b765                	j	800047b8 <fileread+0x60>
      return -1;
    80004812:	597d                	li	s2,-1
    80004814:	b755                	j	800047b8 <fileread+0x60>
    80004816:	597d                	li	s2,-1
    80004818:	b745                	j	800047b8 <fileread+0x60>

000000008000481a <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000481a:	00954783          	lbu	a5,9(a0)
    8000481e:	14078563          	beqz	a5,80004968 <filewrite+0x14e>
{
    80004822:	715d                	addi	sp,sp,-80
    80004824:	e486                	sd	ra,72(sp)
    80004826:	e0a2                	sd	s0,64(sp)
    80004828:	fc26                	sd	s1,56(sp)
    8000482a:	f84a                	sd	s2,48(sp)
    8000482c:	f44e                	sd	s3,40(sp)
    8000482e:	f052                	sd	s4,32(sp)
    80004830:	ec56                	sd	s5,24(sp)
    80004832:	e85a                	sd	s6,16(sp)
    80004834:	e45e                	sd	s7,8(sp)
    80004836:	e062                	sd	s8,0(sp)
    80004838:	0880                	addi	s0,sp,80
    8000483a:	892a                	mv	s2,a0
    8000483c:	8aae                	mv	s5,a1
    8000483e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004840:	411c                	lw	a5,0(a0)
    80004842:	4705                	li	a4,1
    80004844:	02e78263          	beq	a5,a4,80004868 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004848:	470d                	li	a4,3
    8000484a:	02e78563          	beq	a5,a4,80004874 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000484e:	4709                	li	a4,2
    80004850:	10e79463          	bne	a5,a4,80004958 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004854:	0ec05e63          	blez	a2,80004950 <filewrite+0x136>
    int i = 0;
    80004858:	4981                	li	s3,0
    8000485a:	6b05                	lui	s6,0x1
    8000485c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004860:	6b85                	lui	s7,0x1
    80004862:	c00b8b9b          	addiw	s7,s7,-1024
    80004866:	a851                	j	800048fa <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004868:	6908                	ld	a0,16(a0)
    8000486a:	00000097          	auipc	ra,0x0
    8000486e:	254080e7          	jalr	596(ra) # 80004abe <pipewrite>
    80004872:	a85d                	j	80004928 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004874:	02451783          	lh	a5,36(a0)
    80004878:	03079693          	slli	a3,a5,0x30
    8000487c:	92c1                	srli	a3,a3,0x30
    8000487e:	4725                	li	a4,9
    80004880:	0ed76663          	bltu	a4,a3,8000496c <filewrite+0x152>
    80004884:	0792                	slli	a5,a5,0x4
    80004886:	0001d717          	auipc	a4,0x1d
    8000488a:	32a70713          	addi	a4,a4,810 # 80021bb0 <devsw>
    8000488e:	97ba                	add	a5,a5,a4
    80004890:	679c                	ld	a5,8(a5)
    80004892:	cff9                	beqz	a5,80004970 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004894:	4505                	li	a0,1
    80004896:	9782                	jalr	a5
    80004898:	a841                	j	80004928 <filewrite+0x10e>
    8000489a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000489e:	00000097          	auipc	ra,0x0
    800048a2:	8ae080e7          	jalr	-1874(ra) # 8000414c <begin_op>
      ilock(f->ip);
    800048a6:	01893503          	ld	a0,24(s2)
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	ee6080e7          	jalr	-282(ra) # 80003790 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048b2:	8762                	mv	a4,s8
    800048b4:	02092683          	lw	a3,32(s2)
    800048b8:	01598633          	add	a2,s3,s5
    800048bc:	4585                	li	a1,1
    800048be:	01893503          	ld	a0,24(s2)
    800048c2:	fffff097          	auipc	ra,0xfffff
    800048c6:	278080e7          	jalr	632(ra) # 80003b3a <writei>
    800048ca:	84aa                	mv	s1,a0
    800048cc:	02a05f63          	blez	a0,8000490a <filewrite+0xf0>
        f->off += r;
    800048d0:	02092783          	lw	a5,32(s2)
    800048d4:	9fa9                	addw	a5,a5,a0
    800048d6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048da:	01893503          	ld	a0,24(s2)
    800048de:	fffff097          	auipc	ra,0xfffff
    800048e2:	f74080e7          	jalr	-140(ra) # 80003852 <iunlock>
      end_op();
    800048e6:	00000097          	auipc	ra,0x0
    800048ea:	8e6080e7          	jalr	-1818(ra) # 800041cc <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800048ee:	049c1963          	bne	s8,s1,80004940 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800048f2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048f6:	0349d663          	bge	s3,s4,80004922 <filewrite+0x108>
      int n1 = n - i;
    800048fa:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048fe:	84be                	mv	s1,a5
    80004900:	2781                	sext.w	a5,a5
    80004902:	f8fb5ce3          	bge	s6,a5,8000489a <filewrite+0x80>
    80004906:	84de                	mv	s1,s7
    80004908:	bf49                	j	8000489a <filewrite+0x80>
      iunlock(f->ip);
    8000490a:	01893503          	ld	a0,24(s2)
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	f44080e7          	jalr	-188(ra) # 80003852 <iunlock>
      end_op();
    80004916:	00000097          	auipc	ra,0x0
    8000491a:	8b6080e7          	jalr	-1866(ra) # 800041cc <end_op>
      if(r < 0)
    8000491e:	fc04d8e3          	bgez	s1,800048ee <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004922:	8552                	mv	a0,s4
    80004924:	033a1863          	bne	s4,s3,80004954 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004928:	60a6                	ld	ra,72(sp)
    8000492a:	6406                	ld	s0,64(sp)
    8000492c:	74e2                	ld	s1,56(sp)
    8000492e:	7942                	ld	s2,48(sp)
    80004930:	79a2                	ld	s3,40(sp)
    80004932:	7a02                	ld	s4,32(sp)
    80004934:	6ae2                	ld	s5,24(sp)
    80004936:	6b42                	ld	s6,16(sp)
    80004938:	6ba2                	ld	s7,8(sp)
    8000493a:	6c02                	ld	s8,0(sp)
    8000493c:	6161                	addi	sp,sp,80
    8000493e:	8082                	ret
        panic("short filewrite");
    80004940:	00004517          	auipc	a0,0x4
    80004944:	ee850513          	addi	a0,a0,-280 # 80008828 <sysnames+0x278>
    80004948:	ffffc097          	auipc	ra,0xffffc
    8000494c:	c00080e7          	jalr	-1024(ra) # 80000548 <panic>
    int i = 0;
    80004950:	4981                	li	s3,0
    80004952:	bfc1                	j	80004922 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004954:	557d                	li	a0,-1
    80004956:	bfc9                	j	80004928 <filewrite+0x10e>
    panic("filewrite");
    80004958:	00004517          	auipc	a0,0x4
    8000495c:	ee050513          	addi	a0,a0,-288 # 80008838 <sysnames+0x288>
    80004960:	ffffc097          	auipc	ra,0xffffc
    80004964:	be8080e7          	jalr	-1048(ra) # 80000548 <panic>
    return -1;
    80004968:	557d                	li	a0,-1
}
    8000496a:	8082                	ret
      return -1;
    8000496c:	557d                	li	a0,-1
    8000496e:	bf6d                	j	80004928 <filewrite+0x10e>
    80004970:	557d                	li	a0,-1
    80004972:	bf5d                	j	80004928 <filewrite+0x10e>

0000000080004974 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004974:	7179                	addi	sp,sp,-48
    80004976:	f406                	sd	ra,40(sp)
    80004978:	f022                	sd	s0,32(sp)
    8000497a:	ec26                	sd	s1,24(sp)
    8000497c:	e84a                	sd	s2,16(sp)
    8000497e:	e44e                	sd	s3,8(sp)
    80004980:	e052                	sd	s4,0(sp)
    80004982:	1800                	addi	s0,sp,48
    80004984:	84aa                	mv	s1,a0
    80004986:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004988:	0005b023          	sd	zero,0(a1)
    8000498c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004990:	00000097          	auipc	ra,0x0
    80004994:	bd2080e7          	jalr	-1070(ra) # 80004562 <filealloc>
    80004998:	e088                	sd	a0,0(s1)
    8000499a:	c551                	beqz	a0,80004a26 <pipealloc+0xb2>
    8000499c:	00000097          	auipc	ra,0x0
    800049a0:	bc6080e7          	jalr	-1082(ra) # 80004562 <filealloc>
    800049a4:	00aa3023          	sd	a0,0(s4)
    800049a8:	c92d                	beqz	a0,80004a1a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	176080e7          	jalr	374(ra) # 80000b20 <kalloc>
    800049b2:	892a                	mv	s2,a0
    800049b4:	c125                	beqz	a0,80004a14 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049b6:	4985                	li	s3,1
    800049b8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049bc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049c0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049c4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049c8:	00004597          	auipc	a1,0x4
    800049cc:	a7858593          	addi	a1,a1,-1416 # 80008440 <states.1707+0x198>
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	1fa080e7          	jalr	506(ra) # 80000bca <initlock>
  (*f0)->type = FD_PIPE;
    800049d8:	609c                	ld	a5,0(s1)
    800049da:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049de:	609c                	ld	a5,0(s1)
    800049e0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049e4:	609c                	ld	a5,0(s1)
    800049e6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049ea:	609c                	ld	a5,0(s1)
    800049ec:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049f0:	000a3783          	ld	a5,0(s4)
    800049f4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049f8:	000a3783          	ld	a5,0(s4)
    800049fc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a00:	000a3783          	ld	a5,0(s4)
    80004a04:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a08:	000a3783          	ld	a5,0(s4)
    80004a0c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a10:	4501                	li	a0,0
    80004a12:	a025                	j	80004a3a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a14:	6088                	ld	a0,0(s1)
    80004a16:	e501                	bnez	a0,80004a1e <pipealloc+0xaa>
    80004a18:	a039                	j	80004a26 <pipealloc+0xb2>
    80004a1a:	6088                	ld	a0,0(s1)
    80004a1c:	c51d                	beqz	a0,80004a4a <pipealloc+0xd6>
    fileclose(*f0);
    80004a1e:	00000097          	auipc	ra,0x0
    80004a22:	c00080e7          	jalr	-1024(ra) # 8000461e <fileclose>
  if(*f1)
    80004a26:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a2a:	557d                	li	a0,-1
  if(*f1)
    80004a2c:	c799                	beqz	a5,80004a3a <pipealloc+0xc6>
    fileclose(*f1);
    80004a2e:	853e                	mv	a0,a5
    80004a30:	00000097          	auipc	ra,0x0
    80004a34:	bee080e7          	jalr	-1042(ra) # 8000461e <fileclose>
  return -1;
    80004a38:	557d                	li	a0,-1
}
    80004a3a:	70a2                	ld	ra,40(sp)
    80004a3c:	7402                	ld	s0,32(sp)
    80004a3e:	64e2                	ld	s1,24(sp)
    80004a40:	6942                	ld	s2,16(sp)
    80004a42:	69a2                	ld	s3,8(sp)
    80004a44:	6a02                	ld	s4,0(sp)
    80004a46:	6145                	addi	sp,sp,48
    80004a48:	8082                	ret
  return -1;
    80004a4a:	557d                	li	a0,-1
    80004a4c:	b7fd                	j	80004a3a <pipealloc+0xc6>

0000000080004a4e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a4e:	1101                	addi	sp,sp,-32
    80004a50:	ec06                	sd	ra,24(sp)
    80004a52:	e822                	sd	s0,16(sp)
    80004a54:	e426                	sd	s1,8(sp)
    80004a56:	e04a                	sd	s2,0(sp)
    80004a58:	1000                	addi	s0,sp,32
    80004a5a:	84aa                	mv	s1,a0
    80004a5c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	1fc080e7          	jalr	508(ra) # 80000c5a <acquire>
  if(writable){
    80004a66:	02090d63          	beqz	s2,80004aa0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a6a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a6e:	21848513          	addi	a0,s1,536
    80004a72:	ffffe097          	auipc	ra,0xffffe
    80004a76:	954080e7          	jalr	-1708(ra) # 800023c6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a7a:	2204b783          	ld	a5,544(s1)
    80004a7e:	eb95                	bnez	a5,80004ab2 <pipeclose+0x64>
    release(&pi->lock);
    80004a80:	8526                	mv	a0,s1
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	28c080e7          	jalr	652(ra) # 80000d0e <release>
    kfree((char*)pi);
    80004a8a:	8526                	mv	a0,s1
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	f98080e7          	jalr	-104(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004a94:	60e2                	ld	ra,24(sp)
    80004a96:	6442                	ld	s0,16(sp)
    80004a98:	64a2                	ld	s1,8(sp)
    80004a9a:	6902                	ld	s2,0(sp)
    80004a9c:	6105                	addi	sp,sp,32
    80004a9e:	8082                	ret
    pi->readopen = 0;
    80004aa0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004aa4:	21c48513          	addi	a0,s1,540
    80004aa8:	ffffe097          	auipc	ra,0xffffe
    80004aac:	91e080e7          	jalr	-1762(ra) # 800023c6 <wakeup>
    80004ab0:	b7e9                	j	80004a7a <pipeclose+0x2c>
    release(&pi->lock);
    80004ab2:	8526                	mv	a0,s1
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	25a080e7          	jalr	602(ra) # 80000d0e <release>
}
    80004abc:	bfe1                	j	80004a94 <pipeclose+0x46>

0000000080004abe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004abe:	7119                	addi	sp,sp,-128
    80004ac0:	fc86                	sd	ra,120(sp)
    80004ac2:	f8a2                	sd	s0,112(sp)
    80004ac4:	f4a6                	sd	s1,104(sp)
    80004ac6:	f0ca                	sd	s2,96(sp)
    80004ac8:	ecce                	sd	s3,88(sp)
    80004aca:	e8d2                	sd	s4,80(sp)
    80004acc:	e4d6                	sd	s5,72(sp)
    80004ace:	e0da                	sd	s6,64(sp)
    80004ad0:	fc5e                	sd	s7,56(sp)
    80004ad2:	f862                	sd	s8,48(sp)
    80004ad4:	f466                	sd	s9,40(sp)
    80004ad6:	f06a                	sd	s10,32(sp)
    80004ad8:	ec6e                	sd	s11,24(sp)
    80004ada:	0100                	addi	s0,sp,128
    80004adc:	84aa                	mv	s1,a0
    80004ade:	8cae                	mv	s9,a1
    80004ae0:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004ae2:	ffffd097          	auipc	ra,0xffffd
    80004ae6:	f46080e7          	jalr	-186(ra) # 80001a28 <myproc>
    80004aea:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004aec:	8526                	mv	a0,s1
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	16c080e7          	jalr	364(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    80004af6:	0d605963          	blez	s6,80004bc8 <pipewrite+0x10a>
    80004afa:	89a6                	mv	s3,s1
    80004afc:	3b7d                	addiw	s6,s6,-1
    80004afe:	1b02                	slli	s6,s6,0x20
    80004b00:	020b5b13          	srli	s6,s6,0x20
    80004b04:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b06:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b0a:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b0e:	5dfd                	li	s11,-1
    80004b10:	000b8d1b          	sext.w	s10,s7
    80004b14:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b16:	2184a783          	lw	a5,536(s1)
    80004b1a:	21c4a703          	lw	a4,540(s1)
    80004b1e:	2007879b          	addiw	a5,a5,512
    80004b22:	02f71b63          	bne	a4,a5,80004b58 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004b26:	2204a783          	lw	a5,544(s1)
    80004b2a:	cbad                	beqz	a5,80004b9c <pipewrite+0xde>
    80004b2c:	03092783          	lw	a5,48(s2)
    80004b30:	e7b5                	bnez	a5,80004b9c <pipewrite+0xde>
      wakeup(&pi->nread);
    80004b32:	8556                	mv	a0,s5
    80004b34:	ffffe097          	auipc	ra,0xffffe
    80004b38:	892080e7          	jalr	-1902(ra) # 800023c6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b3c:	85ce                	mv	a1,s3
    80004b3e:	8552                	mv	a0,s4
    80004b40:	ffffd097          	auipc	ra,0xffffd
    80004b44:	700080e7          	jalr	1792(ra) # 80002240 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b48:	2184a783          	lw	a5,536(s1)
    80004b4c:	21c4a703          	lw	a4,540(s1)
    80004b50:	2007879b          	addiw	a5,a5,512
    80004b54:	fcf709e3          	beq	a4,a5,80004b26 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b58:	4685                	li	a3,1
    80004b5a:	019b8633          	add	a2,s7,s9
    80004b5e:	f8f40593          	addi	a1,s0,-113
    80004b62:	05093503          	ld	a0,80(s2)
    80004b66:	ffffd097          	auipc	ra,0xffffd
    80004b6a:	c42080e7          	jalr	-958(ra) # 800017a8 <copyin>
    80004b6e:	05b50e63          	beq	a0,s11,80004bca <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b72:	21c4a783          	lw	a5,540(s1)
    80004b76:	0017871b          	addiw	a4,a5,1
    80004b7a:	20e4ae23          	sw	a4,540(s1)
    80004b7e:	1ff7f793          	andi	a5,a5,511
    80004b82:	97a6                	add	a5,a5,s1
    80004b84:	f8f44703          	lbu	a4,-113(s0)
    80004b88:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b8c:	001d0c1b          	addiw	s8,s10,1
    80004b90:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b94:	036b8b63          	beq	s7,s6,80004bca <pipewrite+0x10c>
    80004b98:	8bbe                	mv	s7,a5
    80004b9a:	bf9d                	j	80004b10 <pipewrite+0x52>
        release(&pi->lock);
    80004b9c:	8526                	mv	a0,s1
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	170080e7          	jalr	368(ra) # 80000d0e <release>
        return -1;
    80004ba6:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004ba8:	8562                	mv	a0,s8
    80004baa:	70e6                	ld	ra,120(sp)
    80004bac:	7446                	ld	s0,112(sp)
    80004bae:	74a6                	ld	s1,104(sp)
    80004bb0:	7906                	ld	s2,96(sp)
    80004bb2:	69e6                	ld	s3,88(sp)
    80004bb4:	6a46                	ld	s4,80(sp)
    80004bb6:	6aa6                	ld	s5,72(sp)
    80004bb8:	6b06                	ld	s6,64(sp)
    80004bba:	7be2                	ld	s7,56(sp)
    80004bbc:	7c42                	ld	s8,48(sp)
    80004bbe:	7ca2                	ld	s9,40(sp)
    80004bc0:	7d02                	ld	s10,32(sp)
    80004bc2:	6de2                	ld	s11,24(sp)
    80004bc4:	6109                	addi	sp,sp,128
    80004bc6:	8082                	ret
  for(i = 0; i < n; i++){
    80004bc8:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004bca:	21848513          	addi	a0,s1,536
    80004bce:	ffffd097          	auipc	ra,0xffffd
    80004bd2:	7f8080e7          	jalr	2040(ra) # 800023c6 <wakeup>
  release(&pi->lock);
    80004bd6:	8526                	mv	a0,s1
    80004bd8:	ffffc097          	auipc	ra,0xffffc
    80004bdc:	136080e7          	jalr	310(ra) # 80000d0e <release>
  return i;
    80004be0:	b7e1                	j	80004ba8 <pipewrite+0xea>

0000000080004be2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004be2:	715d                	addi	sp,sp,-80
    80004be4:	e486                	sd	ra,72(sp)
    80004be6:	e0a2                	sd	s0,64(sp)
    80004be8:	fc26                	sd	s1,56(sp)
    80004bea:	f84a                	sd	s2,48(sp)
    80004bec:	f44e                	sd	s3,40(sp)
    80004bee:	f052                	sd	s4,32(sp)
    80004bf0:	ec56                	sd	s5,24(sp)
    80004bf2:	e85a                	sd	s6,16(sp)
    80004bf4:	0880                	addi	s0,sp,80
    80004bf6:	84aa                	mv	s1,a0
    80004bf8:	892e                	mv	s2,a1
    80004bfa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bfc:	ffffd097          	auipc	ra,0xffffd
    80004c00:	e2c080e7          	jalr	-468(ra) # 80001a28 <myproc>
    80004c04:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c06:	8b26                	mv	s6,s1
    80004c08:	8526                	mv	a0,s1
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	050080e7          	jalr	80(ra) # 80000c5a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c12:	2184a703          	lw	a4,536(s1)
    80004c16:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c1a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c1e:	02f71463          	bne	a4,a5,80004c46 <piperead+0x64>
    80004c22:	2244a783          	lw	a5,548(s1)
    80004c26:	c385                	beqz	a5,80004c46 <piperead+0x64>
    if(pr->killed){
    80004c28:	030a2783          	lw	a5,48(s4)
    80004c2c:	ebc1                	bnez	a5,80004cbc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c2e:	85da                	mv	a1,s6
    80004c30:	854e                	mv	a0,s3
    80004c32:	ffffd097          	auipc	ra,0xffffd
    80004c36:	60e080e7          	jalr	1550(ra) # 80002240 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c3a:	2184a703          	lw	a4,536(s1)
    80004c3e:	21c4a783          	lw	a5,540(s1)
    80004c42:	fef700e3          	beq	a4,a5,80004c22 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c46:	09505263          	blez	s5,80004cca <piperead+0xe8>
    80004c4a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c4c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c4e:	2184a783          	lw	a5,536(s1)
    80004c52:	21c4a703          	lw	a4,540(s1)
    80004c56:	02f70d63          	beq	a4,a5,80004c90 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c5a:	0017871b          	addiw	a4,a5,1
    80004c5e:	20e4ac23          	sw	a4,536(s1)
    80004c62:	1ff7f793          	andi	a5,a5,511
    80004c66:	97a6                	add	a5,a5,s1
    80004c68:	0187c783          	lbu	a5,24(a5)
    80004c6c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c70:	4685                	li	a3,1
    80004c72:	fbf40613          	addi	a2,s0,-65
    80004c76:	85ca                	mv	a1,s2
    80004c78:	050a3503          	ld	a0,80(s4)
    80004c7c:	ffffd097          	auipc	ra,0xffffd
    80004c80:	aa0080e7          	jalr	-1376(ra) # 8000171c <copyout>
    80004c84:	01650663          	beq	a0,s6,80004c90 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c88:	2985                	addiw	s3,s3,1
    80004c8a:	0905                	addi	s2,s2,1
    80004c8c:	fd3a91e3          	bne	s5,s3,80004c4e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c90:	21c48513          	addi	a0,s1,540
    80004c94:	ffffd097          	auipc	ra,0xffffd
    80004c98:	732080e7          	jalr	1842(ra) # 800023c6 <wakeup>
  release(&pi->lock);
    80004c9c:	8526                	mv	a0,s1
    80004c9e:	ffffc097          	auipc	ra,0xffffc
    80004ca2:	070080e7          	jalr	112(ra) # 80000d0e <release>
  return i;
}
    80004ca6:	854e                	mv	a0,s3
    80004ca8:	60a6                	ld	ra,72(sp)
    80004caa:	6406                	ld	s0,64(sp)
    80004cac:	74e2                	ld	s1,56(sp)
    80004cae:	7942                	ld	s2,48(sp)
    80004cb0:	79a2                	ld	s3,40(sp)
    80004cb2:	7a02                	ld	s4,32(sp)
    80004cb4:	6ae2                	ld	s5,24(sp)
    80004cb6:	6b42                	ld	s6,16(sp)
    80004cb8:	6161                	addi	sp,sp,80
    80004cba:	8082                	ret
      release(&pi->lock);
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	050080e7          	jalr	80(ra) # 80000d0e <release>
      return -1;
    80004cc6:	59fd                	li	s3,-1
    80004cc8:	bff9                	j	80004ca6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cca:	4981                	li	s3,0
    80004ccc:	b7d1                	j	80004c90 <piperead+0xae>

0000000080004cce <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cce:	df010113          	addi	sp,sp,-528
    80004cd2:	20113423          	sd	ra,520(sp)
    80004cd6:	20813023          	sd	s0,512(sp)
    80004cda:	ffa6                	sd	s1,504(sp)
    80004cdc:	fbca                	sd	s2,496(sp)
    80004cde:	f7ce                	sd	s3,488(sp)
    80004ce0:	f3d2                	sd	s4,480(sp)
    80004ce2:	efd6                	sd	s5,472(sp)
    80004ce4:	ebda                	sd	s6,464(sp)
    80004ce6:	e7de                	sd	s7,456(sp)
    80004ce8:	e3e2                	sd	s8,448(sp)
    80004cea:	ff66                	sd	s9,440(sp)
    80004cec:	fb6a                	sd	s10,432(sp)
    80004cee:	f76e                	sd	s11,424(sp)
    80004cf0:	0c00                	addi	s0,sp,528
    80004cf2:	84aa                	mv	s1,a0
    80004cf4:	dea43c23          	sd	a0,-520(s0)
    80004cf8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	d2c080e7          	jalr	-724(ra) # 80001a28 <myproc>
    80004d04:	892a                	mv	s2,a0

  begin_op();
    80004d06:	fffff097          	auipc	ra,0xfffff
    80004d0a:	446080e7          	jalr	1094(ra) # 8000414c <begin_op>

  if((ip = namei(path)) == 0){
    80004d0e:	8526                	mv	a0,s1
    80004d10:	fffff097          	auipc	ra,0xfffff
    80004d14:	230080e7          	jalr	560(ra) # 80003f40 <namei>
    80004d18:	c92d                	beqz	a0,80004d8a <exec+0xbc>
    80004d1a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d1c:	fffff097          	auipc	ra,0xfffff
    80004d20:	a74080e7          	jalr	-1420(ra) # 80003790 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d24:	04000713          	li	a4,64
    80004d28:	4681                	li	a3,0
    80004d2a:	e4840613          	addi	a2,s0,-440
    80004d2e:	4581                	li	a1,0
    80004d30:	8526                	mv	a0,s1
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	d12080e7          	jalr	-750(ra) # 80003a44 <readi>
    80004d3a:	04000793          	li	a5,64
    80004d3e:	00f51a63          	bne	a0,a5,80004d52 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d42:	e4842703          	lw	a4,-440(s0)
    80004d46:	464c47b7          	lui	a5,0x464c4
    80004d4a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d4e:	04f70463          	beq	a4,a5,80004d96 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d52:	8526                	mv	a0,s1
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	c9e080e7          	jalr	-866(ra) # 800039f2 <iunlockput>
    end_op();
    80004d5c:	fffff097          	auipc	ra,0xfffff
    80004d60:	470080e7          	jalr	1136(ra) # 800041cc <end_op>
  }
  return -1;
    80004d64:	557d                	li	a0,-1
}
    80004d66:	20813083          	ld	ra,520(sp)
    80004d6a:	20013403          	ld	s0,512(sp)
    80004d6e:	74fe                	ld	s1,504(sp)
    80004d70:	795e                	ld	s2,496(sp)
    80004d72:	79be                	ld	s3,488(sp)
    80004d74:	7a1e                	ld	s4,480(sp)
    80004d76:	6afe                	ld	s5,472(sp)
    80004d78:	6b5e                	ld	s6,464(sp)
    80004d7a:	6bbe                	ld	s7,456(sp)
    80004d7c:	6c1e                	ld	s8,448(sp)
    80004d7e:	7cfa                	ld	s9,440(sp)
    80004d80:	7d5a                	ld	s10,432(sp)
    80004d82:	7dba                	ld	s11,424(sp)
    80004d84:	21010113          	addi	sp,sp,528
    80004d88:	8082                	ret
    end_op();
    80004d8a:	fffff097          	auipc	ra,0xfffff
    80004d8e:	442080e7          	jalr	1090(ra) # 800041cc <end_op>
    return -1;
    80004d92:	557d                	li	a0,-1
    80004d94:	bfc9                	j	80004d66 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d96:	854a                	mv	a0,s2
    80004d98:	ffffd097          	auipc	ra,0xffffd
    80004d9c:	d54080e7          	jalr	-684(ra) # 80001aec <proc_pagetable>
    80004da0:	8baa                	mv	s7,a0
    80004da2:	d945                	beqz	a0,80004d52 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004da4:	e6842983          	lw	s3,-408(s0)
    80004da8:	e8045783          	lhu	a5,-384(s0)
    80004dac:	c7ad                	beqz	a5,80004e16 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dae:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004db0:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004db2:	6c85                	lui	s9,0x1
    80004db4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004db8:	def43823          	sd	a5,-528(s0)
    80004dbc:	a42d                	j	80004fe6 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dbe:	00004517          	auipc	a0,0x4
    80004dc2:	a8a50513          	addi	a0,a0,-1398 # 80008848 <sysnames+0x298>
    80004dc6:	ffffb097          	auipc	ra,0xffffb
    80004dca:	782080e7          	jalr	1922(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dce:	8756                	mv	a4,s5
    80004dd0:	012d86bb          	addw	a3,s11,s2
    80004dd4:	4581                	li	a1,0
    80004dd6:	8526                	mv	a0,s1
    80004dd8:	fffff097          	auipc	ra,0xfffff
    80004ddc:	c6c080e7          	jalr	-916(ra) # 80003a44 <readi>
    80004de0:	2501                	sext.w	a0,a0
    80004de2:	1aaa9963          	bne	s5,a0,80004f94 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004de6:	6785                	lui	a5,0x1
    80004de8:	0127893b          	addw	s2,a5,s2
    80004dec:	77fd                	lui	a5,0xfffff
    80004dee:	01478a3b          	addw	s4,a5,s4
    80004df2:	1f897163          	bgeu	s2,s8,80004fd4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004df6:	02091593          	slli	a1,s2,0x20
    80004dfa:	9181                	srli	a1,a1,0x20
    80004dfc:	95ea                	add	a1,a1,s10
    80004dfe:	855e                	mv	a0,s7
    80004e00:	ffffc097          	auipc	ra,0xffffc
    80004e04:	2e8080e7          	jalr	744(ra) # 800010e8 <walkaddr>
    80004e08:	862a                	mv	a2,a0
    if(pa == 0)
    80004e0a:	d955                	beqz	a0,80004dbe <exec+0xf0>
      n = PGSIZE;
    80004e0c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e0e:	fd9a70e3          	bgeu	s4,s9,80004dce <exec+0x100>
      n = sz - i;
    80004e12:	8ad2                	mv	s5,s4
    80004e14:	bf6d                	j	80004dce <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e16:	4901                	li	s2,0
  iunlockput(ip);
    80004e18:	8526                	mv	a0,s1
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	bd8080e7          	jalr	-1064(ra) # 800039f2 <iunlockput>
  end_op();
    80004e22:	fffff097          	auipc	ra,0xfffff
    80004e26:	3aa080e7          	jalr	938(ra) # 800041cc <end_op>
  p = myproc();
    80004e2a:	ffffd097          	auipc	ra,0xffffd
    80004e2e:	bfe080e7          	jalr	-1026(ra) # 80001a28 <myproc>
    80004e32:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e34:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e38:	6785                	lui	a5,0x1
    80004e3a:	17fd                	addi	a5,a5,-1
    80004e3c:	993e                	add	s2,s2,a5
    80004e3e:	757d                	lui	a0,0xfffff
    80004e40:	00a977b3          	and	a5,s2,a0
    80004e44:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e48:	6609                	lui	a2,0x2
    80004e4a:	963e                	add	a2,a2,a5
    80004e4c:	85be                	mv	a1,a5
    80004e4e:	855e                	mv	a0,s7
    80004e50:	ffffc097          	auipc	ra,0xffffc
    80004e54:	67c080e7          	jalr	1660(ra) # 800014cc <uvmalloc>
    80004e58:	8b2a                	mv	s6,a0
  ip = 0;
    80004e5a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e5c:	12050c63          	beqz	a0,80004f94 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e60:	75f9                	lui	a1,0xffffe
    80004e62:	95aa                	add	a1,a1,a0
    80004e64:	855e                	mv	a0,s7
    80004e66:	ffffd097          	auipc	ra,0xffffd
    80004e6a:	884080e7          	jalr	-1916(ra) # 800016ea <uvmclear>
  stackbase = sp - PGSIZE;
    80004e6e:	7c7d                	lui	s8,0xfffff
    80004e70:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e72:	e0043783          	ld	a5,-512(s0)
    80004e76:	6388                	ld	a0,0(a5)
    80004e78:	c535                	beqz	a0,80004ee4 <exec+0x216>
    80004e7a:	e8840993          	addi	s3,s0,-376
    80004e7e:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e82:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e84:	ffffc097          	auipc	ra,0xffffc
    80004e88:	05a080e7          	jalr	90(ra) # 80000ede <strlen>
    80004e8c:	2505                	addiw	a0,a0,1
    80004e8e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e92:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e96:	13896363          	bltu	s2,s8,80004fbc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e9a:	e0043d83          	ld	s11,-512(s0)
    80004e9e:	000dba03          	ld	s4,0(s11)
    80004ea2:	8552                	mv	a0,s4
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	03a080e7          	jalr	58(ra) # 80000ede <strlen>
    80004eac:	0015069b          	addiw	a3,a0,1
    80004eb0:	8652                	mv	a2,s4
    80004eb2:	85ca                	mv	a1,s2
    80004eb4:	855e                	mv	a0,s7
    80004eb6:	ffffd097          	auipc	ra,0xffffd
    80004eba:	866080e7          	jalr	-1946(ra) # 8000171c <copyout>
    80004ebe:	10054363          	bltz	a0,80004fc4 <exec+0x2f6>
    ustack[argc] = sp;
    80004ec2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ec6:	0485                	addi	s1,s1,1
    80004ec8:	008d8793          	addi	a5,s11,8
    80004ecc:	e0f43023          	sd	a5,-512(s0)
    80004ed0:	008db503          	ld	a0,8(s11)
    80004ed4:	c911                	beqz	a0,80004ee8 <exec+0x21a>
    if(argc >= MAXARG)
    80004ed6:	09a1                	addi	s3,s3,8
    80004ed8:	fb3c96e3          	bne	s9,s3,80004e84 <exec+0x1b6>
  sz = sz1;
    80004edc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ee0:	4481                	li	s1,0
    80004ee2:	a84d                	j	80004f94 <exec+0x2c6>
  sp = sz;
    80004ee4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ee6:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ee8:	00349793          	slli	a5,s1,0x3
    80004eec:	f9040713          	addi	a4,s0,-112
    80004ef0:	97ba                	add	a5,a5,a4
    80004ef2:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004ef6:	00148693          	addi	a3,s1,1
    80004efa:	068e                	slli	a3,a3,0x3
    80004efc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f00:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f04:	01897663          	bgeu	s2,s8,80004f10 <exec+0x242>
  sz = sz1;
    80004f08:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f0c:	4481                	li	s1,0
    80004f0e:	a059                	j	80004f94 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f10:	e8840613          	addi	a2,s0,-376
    80004f14:	85ca                	mv	a1,s2
    80004f16:	855e                	mv	a0,s7
    80004f18:	ffffd097          	auipc	ra,0xffffd
    80004f1c:	804080e7          	jalr	-2044(ra) # 8000171c <copyout>
    80004f20:	0a054663          	bltz	a0,80004fcc <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f24:	058ab783          	ld	a5,88(s5)
    80004f28:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f2c:	df843783          	ld	a5,-520(s0)
    80004f30:	0007c703          	lbu	a4,0(a5)
    80004f34:	cf11                	beqz	a4,80004f50 <exec+0x282>
    80004f36:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f38:	02f00693          	li	a3,47
    80004f3c:	a029                	j	80004f46 <exec+0x278>
  for(last=s=path; *s; s++)
    80004f3e:	0785                	addi	a5,a5,1
    80004f40:	fff7c703          	lbu	a4,-1(a5)
    80004f44:	c711                	beqz	a4,80004f50 <exec+0x282>
    if(*s == '/')
    80004f46:	fed71ce3          	bne	a4,a3,80004f3e <exec+0x270>
      last = s+1;
    80004f4a:	def43c23          	sd	a5,-520(s0)
    80004f4e:	bfc5                	j	80004f3e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f50:	4641                	li	a2,16
    80004f52:	df843583          	ld	a1,-520(s0)
    80004f56:	158a8513          	addi	a0,s5,344
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	f52080e7          	jalr	-174(ra) # 80000eac <safestrcpy>
  oldpagetable = p->pagetable;
    80004f62:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f66:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f6a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f6e:	058ab783          	ld	a5,88(s5)
    80004f72:	e6043703          	ld	a4,-416(s0)
    80004f76:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f78:	058ab783          	ld	a5,88(s5)
    80004f7c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f80:	85ea                	mv	a1,s10
    80004f82:	ffffd097          	auipc	ra,0xffffd
    80004f86:	c06080e7          	jalr	-1018(ra) # 80001b88 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f8a:	0004851b          	sext.w	a0,s1
    80004f8e:	bbe1                	j	80004d66 <exec+0x98>
    80004f90:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f94:	e0843583          	ld	a1,-504(s0)
    80004f98:	855e                	mv	a0,s7
    80004f9a:	ffffd097          	auipc	ra,0xffffd
    80004f9e:	bee080e7          	jalr	-1042(ra) # 80001b88 <proc_freepagetable>
  if(ip){
    80004fa2:	da0498e3          	bnez	s1,80004d52 <exec+0x84>
  return -1;
    80004fa6:	557d                	li	a0,-1
    80004fa8:	bb7d                	j	80004d66 <exec+0x98>
    80004faa:	e1243423          	sd	s2,-504(s0)
    80004fae:	b7dd                	j	80004f94 <exec+0x2c6>
    80004fb0:	e1243423          	sd	s2,-504(s0)
    80004fb4:	b7c5                	j	80004f94 <exec+0x2c6>
    80004fb6:	e1243423          	sd	s2,-504(s0)
    80004fba:	bfe9                	j	80004f94 <exec+0x2c6>
  sz = sz1;
    80004fbc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc0:	4481                	li	s1,0
    80004fc2:	bfc9                	j	80004f94 <exec+0x2c6>
  sz = sz1;
    80004fc4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc8:	4481                	li	s1,0
    80004fca:	b7e9                	j	80004f94 <exec+0x2c6>
  sz = sz1;
    80004fcc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fd0:	4481                	li	s1,0
    80004fd2:	b7c9                	j	80004f94 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fd4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd8:	2b05                	addiw	s6,s6,1
    80004fda:	0389899b          	addiw	s3,s3,56
    80004fde:	e8045783          	lhu	a5,-384(s0)
    80004fe2:	e2fb5be3          	bge	s6,a5,80004e18 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fe6:	2981                	sext.w	s3,s3
    80004fe8:	03800713          	li	a4,56
    80004fec:	86ce                	mv	a3,s3
    80004fee:	e1040613          	addi	a2,s0,-496
    80004ff2:	4581                	li	a1,0
    80004ff4:	8526                	mv	a0,s1
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	a4e080e7          	jalr	-1458(ra) # 80003a44 <readi>
    80004ffe:	03800793          	li	a5,56
    80005002:	f8f517e3          	bne	a0,a5,80004f90 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005006:	e1042783          	lw	a5,-496(s0)
    8000500a:	4705                	li	a4,1
    8000500c:	fce796e3          	bne	a5,a4,80004fd8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005010:	e3843603          	ld	a2,-456(s0)
    80005014:	e3043783          	ld	a5,-464(s0)
    80005018:	f8f669e3          	bltu	a2,a5,80004faa <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000501c:	e2043783          	ld	a5,-480(s0)
    80005020:	963e                	add	a2,a2,a5
    80005022:	f8f667e3          	bltu	a2,a5,80004fb0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005026:	85ca                	mv	a1,s2
    80005028:	855e                	mv	a0,s7
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	4a2080e7          	jalr	1186(ra) # 800014cc <uvmalloc>
    80005032:	e0a43423          	sd	a0,-504(s0)
    80005036:	d141                	beqz	a0,80004fb6 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005038:	e2043d03          	ld	s10,-480(s0)
    8000503c:	df043783          	ld	a5,-528(s0)
    80005040:	00fd77b3          	and	a5,s10,a5
    80005044:	fba1                	bnez	a5,80004f94 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005046:	e1842d83          	lw	s11,-488(s0)
    8000504a:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000504e:	f80c03e3          	beqz	s8,80004fd4 <exec+0x306>
    80005052:	8a62                	mv	s4,s8
    80005054:	4901                	li	s2,0
    80005056:	b345                	j	80004df6 <exec+0x128>

0000000080005058 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005058:	7179                	addi	sp,sp,-48
    8000505a:	f406                	sd	ra,40(sp)
    8000505c:	f022                	sd	s0,32(sp)
    8000505e:	ec26                	sd	s1,24(sp)
    80005060:	e84a                	sd	s2,16(sp)
    80005062:	1800                	addi	s0,sp,48
    80005064:	892e                	mv	s2,a1
    80005066:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005068:	fdc40593          	addi	a1,s0,-36
    8000506c:	ffffe097          	auipc	ra,0xffffe
    80005070:	ad6080e7          	jalr	-1322(ra) # 80002b42 <argint>
    80005074:	04054063          	bltz	a0,800050b4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005078:	fdc42703          	lw	a4,-36(s0)
    8000507c:	47bd                	li	a5,15
    8000507e:	02e7ed63          	bltu	a5,a4,800050b8 <argfd+0x60>
    80005082:	ffffd097          	auipc	ra,0xffffd
    80005086:	9a6080e7          	jalr	-1626(ra) # 80001a28 <myproc>
    8000508a:	fdc42703          	lw	a4,-36(s0)
    8000508e:	01a70793          	addi	a5,a4,26
    80005092:	078e                	slli	a5,a5,0x3
    80005094:	953e                	add	a0,a0,a5
    80005096:	611c                	ld	a5,0(a0)
    80005098:	c395                	beqz	a5,800050bc <argfd+0x64>
    return -1;
  if(pfd)
    8000509a:	00090463          	beqz	s2,800050a2 <argfd+0x4a>
    *pfd = fd;
    8000509e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050a2:	4501                	li	a0,0
  if(pf)
    800050a4:	c091                	beqz	s1,800050a8 <argfd+0x50>
    *pf = f;
    800050a6:	e09c                	sd	a5,0(s1)
}
    800050a8:	70a2                	ld	ra,40(sp)
    800050aa:	7402                	ld	s0,32(sp)
    800050ac:	64e2                	ld	s1,24(sp)
    800050ae:	6942                	ld	s2,16(sp)
    800050b0:	6145                	addi	sp,sp,48
    800050b2:	8082                	ret
    return -1;
    800050b4:	557d                	li	a0,-1
    800050b6:	bfcd                	j	800050a8 <argfd+0x50>
    return -1;
    800050b8:	557d                	li	a0,-1
    800050ba:	b7fd                	j	800050a8 <argfd+0x50>
    800050bc:	557d                	li	a0,-1
    800050be:	b7ed                	j	800050a8 <argfd+0x50>

00000000800050c0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050c0:	1101                	addi	sp,sp,-32
    800050c2:	ec06                	sd	ra,24(sp)
    800050c4:	e822                	sd	s0,16(sp)
    800050c6:	e426                	sd	s1,8(sp)
    800050c8:	1000                	addi	s0,sp,32
    800050ca:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050cc:	ffffd097          	auipc	ra,0xffffd
    800050d0:	95c080e7          	jalr	-1700(ra) # 80001a28 <myproc>
    800050d4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050d6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800050da:	4501                	li	a0,0
    800050dc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050de:	6398                	ld	a4,0(a5)
    800050e0:	cb19                	beqz	a4,800050f6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050e2:	2505                	addiw	a0,a0,1
    800050e4:	07a1                	addi	a5,a5,8
    800050e6:	fed51ce3          	bne	a0,a3,800050de <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050ea:	557d                	li	a0,-1
}
    800050ec:	60e2                	ld	ra,24(sp)
    800050ee:	6442                	ld	s0,16(sp)
    800050f0:	64a2                	ld	s1,8(sp)
    800050f2:	6105                	addi	sp,sp,32
    800050f4:	8082                	ret
      p->ofile[fd] = f;
    800050f6:	01a50793          	addi	a5,a0,26
    800050fa:	078e                	slli	a5,a5,0x3
    800050fc:	963e                	add	a2,a2,a5
    800050fe:	e204                	sd	s1,0(a2)
      return fd;
    80005100:	b7f5                	j	800050ec <fdalloc+0x2c>

0000000080005102 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005102:	715d                	addi	sp,sp,-80
    80005104:	e486                	sd	ra,72(sp)
    80005106:	e0a2                	sd	s0,64(sp)
    80005108:	fc26                	sd	s1,56(sp)
    8000510a:	f84a                	sd	s2,48(sp)
    8000510c:	f44e                	sd	s3,40(sp)
    8000510e:	f052                	sd	s4,32(sp)
    80005110:	ec56                	sd	s5,24(sp)
    80005112:	0880                	addi	s0,sp,80
    80005114:	89ae                	mv	s3,a1
    80005116:	8ab2                	mv	s5,a2
    80005118:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000511a:	fb040593          	addi	a1,s0,-80
    8000511e:	fffff097          	auipc	ra,0xfffff
    80005122:	e40080e7          	jalr	-448(ra) # 80003f5e <nameiparent>
    80005126:	892a                	mv	s2,a0
    80005128:	12050f63          	beqz	a0,80005266 <create+0x164>
    return 0;

  ilock(dp);
    8000512c:	ffffe097          	auipc	ra,0xffffe
    80005130:	664080e7          	jalr	1636(ra) # 80003790 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005134:	4601                	li	a2,0
    80005136:	fb040593          	addi	a1,s0,-80
    8000513a:	854a                	mv	a0,s2
    8000513c:	fffff097          	auipc	ra,0xfffff
    80005140:	b32080e7          	jalr	-1230(ra) # 80003c6e <dirlookup>
    80005144:	84aa                	mv	s1,a0
    80005146:	c921                	beqz	a0,80005196 <create+0x94>
    iunlockput(dp);
    80005148:	854a                	mv	a0,s2
    8000514a:	fffff097          	auipc	ra,0xfffff
    8000514e:	8a8080e7          	jalr	-1880(ra) # 800039f2 <iunlockput>
    ilock(ip);
    80005152:	8526                	mv	a0,s1
    80005154:	ffffe097          	auipc	ra,0xffffe
    80005158:	63c080e7          	jalr	1596(ra) # 80003790 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000515c:	2981                	sext.w	s3,s3
    8000515e:	4789                	li	a5,2
    80005160:	02f99463          	bne	s3,a5,80005188 <create+0x86>
    80005164:	0444d783          	lhu	a5,68(s1)
    80005168:	37f9                	addiw	a5,a5,-2
    8000516a:	17c2                	slli	a5,a5,0x30
    8000516c:	93c1                	srli	a5,a5,0x30
    8000516e:	4705                	li	a4,1
    80005170:	00f76c63          	bltu	a4,a5,80005188 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005174:	8526                	mv	a0,s1
    80005176:	60a6                	ld	ra,72(sp)
    80005178:	6406                	ld	s0,64(sp)
    8000517a:	74e2                	ld	s1,56(sp)
    8000517c:	7942                	ld	s2,48(sp)
    8000517e:	79a2                	ld	s3,40(sp)
    80005180:	7a02                	ld	s4,32(sp)
    80005182:	6ae2                	ld	s5,24(sp)
    80005184:	6161                	addi	sp,sp,80
    80005186:	8082                	ret
    iunlockput(ip);
    80005188:	8526                	mv	a0,s1
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	868080e7          	jalr	-1944(ra) # 800039f2 <iunlockput>
    return 0;
    80005192:	4481                	li	s1,0
    80005194:	b7c5                	j	80005174 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005196:	85ce                	mv	a1,s3
    80005198:	00092503          	lw	a0,0(s2)
    8000519c:	ffffe097          	auipc	ra,0xffffe
    800051a0:	45c080e7          	jalr	1116(ra) # 800035f8 <ialloc>
    800051a4:	84aa                	mv	s1,a0
    800051a6:	c529                	beqz	a0,800051f0 <create+0xee>
  ilock(ip);
    800051a8:	ffffe097          	auipc	ra,0xffffe
    800051ac:	5e8080e7          	jalr	1512(ra) # 80003790 <ilock>
  ip->major = major;
    800051b0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051b4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051b8:	4785                	li	a5,1
    800051ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051be:	8526                	mv	a0,s1
    800051c0:	ffffe097          	auipc	ra,0xffffe
    800051c4:	506080e7          	jalr	1286(ra) # 800036c6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051c8:	2981                	sext.w	s3,s3
    800051ca:	4785                	li	a5,1
    800051cc:	02f98a63          	beq	s3,a5,80005200 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051d0:	40d0                	lw	a2,4(s1)
    800051d2:	fb040593          	addi	a1,s0,-80
    800051d6:	854a                	mv	a0,s2
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	ca6080e7          	jalr	-858(ra) # 80003e7e <dirlink>
    800051e0:	06054b63          	bltz	a0,80005256 <create+0x154>
  iunlockput(dp);
    800051e4:	854a                	mv	a0,s2
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	80c080e7          	jalr	-2036(ra) # 800039f2 <iunlockput>
  return ip;
    800051ee:	b759                	j	80005174 <create+0x72>
    panic("create: ialloc");
    800051f0:	00003517          	auipc	a0,0x3
    800051f4:	67850513          	addi	a0,a0,1656 # 80008868 <sysnames+0x2b8>
    800051f8:	ffffb097          	auipc	ra,0xffffb
    800051fc:	350080e7          	jalr	848(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005200:	04a95783          	lhu	a5,74(s2)
    80005204:	2785                	addiw	a5,a5,1
    80005206:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000520a:	854a                	mv	a0,s2
    8000520c:	ffffe097          	auipc	ra,0xffffe
    80005210:	4ba080e7          	jalr	1210(ra) # 800036c6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005214:	40d0                	lw	a2,4(s1)
    80005216:	00003597          	auipc	a1,0x3
    8000521a:	66258593          	addi	a1,a1,1634 # 80008878 <sysnames+0x2c8>
    8000521e:	8526                	mv	a0,s1
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	c5e080e7          	jalr	-930(ra) # 80003e7e <dirlink>
    80005228:	00054f63          	bltz	a0,80005246 <create+0x144>
    8000522c:	00492603          	lw	a2,4(s2)
    80005230:	00003597          	auipc	a1,0x3
    80005234:	65058593          	addi	a1,a1,1616 # 80008880 <sysnames+0x2d0>
    80005238:	8526                	mv	a0,s1
    8000523a:	fffff097          	auipc	ra,0xfffff
    8000523e:	c44080e7          	jalr	-956(ra) # 80003e7e <dirlink>
    80005242:	f80557e3          	bgez	a0,800051d0 <create+0xce>
      panic("create dots");
    80005246:	00003517          	auipc	a0,0x3
    8000524a:	64250513          	addi	a0,a0,1602 # 80008888 <sysnames+0x2d8>
    8000524e:	ffffb097          	auipc	ra,0xffffb
    80005252:	2fa080e7          	jalr	762(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005256:	00003517          	auipc	a0,0x3
    8000525a:	64250513          	addi	a0,a0,1602 # 80008898 <sysnames+0x2e8>
    8000525e:	ffffb097          	auipc	ra,0xffffb
    80005262:	2ea080e7          	jalr	746(ra) # 80000548 <panic>
    return 0;
    80005266:	84aa                	mv	s1,a0
    80005268:	b731                	j	80005174 <create+0x72>

000000008000526a <sys_dup>:
{
    8000526a:	7179                	addi	sp,sp,-48
    8000526c:	f406                	sd	ra,40(sp)
    8000526e:	f022                	sd	s0,32(sp)
    80005270:	ec26                	sd	s1,24(sp)
    80005272:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005274:	fd840613          	addi	a2,s0,-40
    80005278:	4581                	li	a1,0
    8000527a:	4501                	li	a0,0
    8000527c:	00000097          	auipc	ra,0x0
    80005280:	ddc080e7          	jalr	-548(ra) # 80005058 <argfd>
    return -1;
    80005284:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005286:	02054363          	bltz	a0,800052ac <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000528a:	fd843503          	ld	a0,-40(s0)
    8000528e:	00000097          	auipc	ra,0x0
    80005292:	e32080e7          	jalr	-462(ra) # 800050c0 <fdalloc>
    80005296:	84aa                	mv	s1,a0
    return -1;
    80005298:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000529a:	00054963          	bltz	a0,800052ac <sys_dup+0x42>
  filedup(f);
    8000529e:	fd843503          	ld	a0,-40(s0)
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	32a080e7          	jalr	810(ra) # 800045cc <filedup>
  return fd;
    800052aa:	87a6                	mv	a5,s1
}
    800052ac:	853e                	mv	a0,a5
    800052ae:	70a2                	ld	ra,40(sp)
    800052b0:	7402                	ld	s0,32(sp)
    800052b2:	64e2                	ld	s1,24(sp)
    800052b4:	6145                	addi	sp,sp,48
    800052b6:	8082                	ret

00000000800052b8 <sys_read>:
{
    800052b8:	7179                	addi	sp,sp,-48
    800052ba:	f406                	sd	ra,40(sp)
    800052bc:	f022                	sd	s0,32(sp)
    800052be:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c0:	fe840613          	addi	a2,s0,-24
    800052c4:	4581                	li	a1,0
    800052c6:	4501                	li	a0,0
    800052c8:	00000097          	auipc	ra,0x0
    800052cc:	d90080e7          	jalr	-624(ra) # 80005058 <argfd>
    return -1;
    800052d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d2:	04054163          	bltz	a0,80005314 <sys_read+0x5c>
    800052d6:	fe440593          	addi	a1,s0,-28
    800052da:	4509                	li	a0,2
    800052dc:	ffffe097          	auipc	ra,0xffffe
    800052e0:	866080e7          	jalr	-1946(ra) # 80002b42 <argint>
    return -1;
    800052e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e6:	02054763          	bltz	a0,80005314 <sys_read+0x5c>
    800052ea:	fd840593          	addi	a1,s0,-40
    800052ee:	4505                	li	a0,1
    800052f0:	ffffe097          	auipc	ra,0xffffe
    800052f4:	874080e7          	jalr	-1932(ra) # 80002b64 <argaddr>
    return -1;
    800052f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fa:	00054d63          	bltz	a0,80005314 <sys_read+0x5c>
  return fileread(f, p, n);
    800052fe:	fe442603          	lw	a2,-28(s0)
    80005302:	fd843583          	ld	a1,-40(s0)
    80005306:	fe843503          	ld	a0,-24(s0)
    8000530a:	fffff097          	auipc	ra,0xfffff
    8000530e:	44e080e7          	jalr	1102(ra) # 80004758 <fileread>
    80005312:	87aa                	mv	a5,a0
}
    80005314:	853e                	mv	a0,a5
    80005316:	70a2                	ld	ra,40(sp)
    80005318:	7402                	ld	s0,32(sp)
    8000531a:	6145                	addi	sp,sp,48
    8000531c:	8082                	ret

000000008000531e <sys_write>:
{
    8000531e:	7179                	addi	sp,sp,-48
    80005320:	f406                	sd	ra,40(sp)
    80005322:	f022                	sd	s0,32(sp)
    80005324:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005326:	fe840613          	addi	a2,s0,-24
    8000532a:	4581                	li	a1,0
    8000532c:	4501                	li	a0,0
    8000532e:	00000097          	auipc	ra,0x0
    80005332:	d2a080e7          	jalr	-726(ra) # 80005058 <argfd>
    return -1;
    80005336:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005338:	04054163          	bltz	a0,8000537a <sys_write+0x5c>
    8000533c:	fe440593          	addi	a1,s0,-28
    80005340:	4509                	li	a0,2
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	800080e7          	jalr	-2048(ra) # 80002b42 <argint>
    return -1;
    8000534a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000534c:	02054763          	bltz	a0,8000537a <sys_write+0x5c>
    80005350:	fd840593          	addi	a1,s0,-40
    80005354:	4505                	li	a0,1
    80005356:	ffffe097          	auipc	ra,0xffffe
    8000535a:	80e080e7          	jalr	-2034(ra) # 80002b64 <argaddr>
    return -1;
    8000535e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005360:	00054d63          	bltz	a0,8000537a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005364:	fe442603          	lw	a2,-28(s0)
    80005368:	fd843583          	ld	a1,-40(s0)
    8000536c:	fe843503          	ld	a0,-24(s0)
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	4aa080e7          	jalr	1194(ra) # 8000481a <filewrite>
    80005378:	87aa                	mv	a5,a0
}
    8000537a:	853e                	mv	a0,a5
    8000537c:	70a2                	ld	ra,40(sp)
    8000537e:	7402                	ld	s0,32(sp)
    80005380:	6145                	addi	sp,sp,48
    80005382:	8082                	ret

0000000080005384 <sys_close>:
{
    80005384:	1101                	addi	sp,sp,-32
    80005386:	ec06                	sd	ra,24(sp)
    80005388:	e822                	sd	s0,16(sp)
    8000538a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000538c:	fe040613          	addi	a2,s0,-32
    80005390:	fec40593          	addi	a1,s0,-20
    80005394:	4501                	li	a0,0
    80005396:	00000097          	auipc	ra,0x0
    8000539a:	cc2080e7          	jalr	-830(ra) # 80005058 <argfd>
    return -1;
    8000539e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053a0:	02054463          	bltz	a0,800053c8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053a4:	ffffc097          	auipc	ra,0xffffc
    800053a8:	684080e7          	jalr	1668(ra) # 80001a28 <myproc>
    800053ac:	fec42783          	lw	a5,-20(s0)
    800053b0:	07e9                	addi	a5,a5,26
    800053b2:	078e                	slli	a5,a5,0x3
    800053b4:	97aa                	add	a5,a5,a0
    800053b6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053ba:	fe043503          	ld	a0,-32(s0)
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	260080e7          	jalr	608(ra) # 8000461e <fileclose>
  return 0;
    800053c6:	4781                	li	a5,0
}
    800053c8:	853e                	mv	a0,a5
    800053ca:	60e2                	ld	ra,24(sp)
    800053cc:	6442                	ld	s0,16(sp)
    800053ce:	6105                	addi	sp,sp,32
    800053d0:	8082                	ret

00000000800053d2 <sys_fstat>:
{
    800053d2:	1101                	addi	sp,sp,-32
    800053d4:	ec06                	sd	ra,24(sp)
    800053d6:	e822                	sd	s0,16(sp)
    800053d8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053da:	fe840613          	addi	a2,s0,-24
    800053de:	4581                	li	a1,0
    800053e0:	4501                	li	a0,0
    800053e2:	00000097          	auipc	ra,0x0
    800053e6:	c76080e7          	jalr	-906(ra) # 80005058 <argfd>
    return -1;
    800053ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ec:	02054563          	bltz	a0,80005416 <sys_fstat+0x44>
    800053f0:	fe040593          	addi	a1,s0,-32
    800053f4:	4505                	li	a0,1
    800053f6:	ffffd097          	auipc	ra,0xffffd
    800053fa:	76e080e7          	jalr	1902(ra) # 80002b64 <argaddr>
    return -1;
    800053fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005400:	00054b63          	bltz	a0,80005416 <sys_fstat+0x44>
  return filestat(f, st);
    80005404:	fe043583          	ld	a1,-32(s0)
    80005408:	fe843503          	ld	a0,-24(s0)
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	2da080e7          	jalr	730(ra) # 800046e6 <filestat>
    80005414:	87aa                	mv	a5,a0
}
    80005416:	853e                	mv	a0,a5
    80005418:	60e2                	ld	ra,24(sp)
    8000541a:	6442                	ld	s0,16(sp)
    8000541c:	6105                	addi	sp,sp,32
    8000541e:	8082                	ret

0000000080005420 <sys_link>:
{
    80005420:	7169                	addi	sp,sp,-304
    80005422:	f606                	sd	ra,296(sp)
    80005424:	f222                	sd	s0,288(sp)
    80005426:	ee26                	sd	s1,280(sp)
    80005428:	ea4a                	sd	s2,272(sp)
    8000542a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000542c:	08000613          	li	a2,128
    80005430:	ed040593          	addi	a1,s0,-304
    80005434:	4501                	li	a0,0
    80005436:	ffffd097          	auipc	ra,0xffffd
    8000543a:	750080e7          	jalr	1872(ra) # 80002b86 <argstr>
    return -1;
    8000543e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005440:	10054e63          	bltz	a0,8000555c <sys_link+0x13c>
    80005444:	08000613          	li	a2,128
    80005448:	f5040593          	addi	a1,s0,-176
    8000544c:	4505                	li	a0,1
    8000544e:	ffffd097          	auipc	ra,0xffffd
    80005452:	738080e7          	jalr	1848(ra) # 80002b86 <argstr>
    return -1;
    80005456:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005458:	10054263          	bltz	a0,8000555c <sys_link+0x13c>
  begin_op();
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	cf0080e7          	jalr	-784(ra) # 8000414c <begin_op>
  if((ip = namei(old)) == 0){
    80005464:	ed040513          	addi	a0,s0,-304
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	ad8080e7          	jalr	-1320(ra) # 80003f40 <namei>
    80005470:	84aa                	mv	s1,a0
    80005472:	c551                	beqz	a0,800054fe <sys_link+0xde>
  ilock(ip);
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	31c080e7          	jalr	796(ra) # 80003790 <ilock>
  if(ip->type == T_DIR){
    8000547c:	04449703          	lh	a4,68(s1)
    80005480:	4785                	li	a5,1
    80005482:	08f70463          	beq	a4,a5,8000550a <sys_link+0xea>
  ip->nlink++;
    80005486:	04a4d783          	lhu	a5,74(s1)
    8000548a:	2785                	addiw	a5,a5,1
    8000548c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005490:	8526                	mv	a0,s1
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	234080e7          	jalr	564(ra) # 800036c6 <iupdate>
  iunlock(ip);
    8000549a:	8526                	mv	a0,s1
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	3b6080e7          	jalr	950(ra) # 80003852 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054a4:	fd040593          	addi	a1,s0,-48
    800054a8:	f5040513          	addi	a0,s0,-176
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	ab2080e7          	jalr	-1358(ra) # 80003f5e <nameiparent>
    800054b4:	892a                	mv	s2,a0
    800054b6:	c935                	beqz	a0,8000552a <sys_link+0x10a>
  ilock(dp);
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	2d8080e7          	jalr	728(ra) # 80003790 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054c0:	00092703          	lw	a4,0(s2)
    800054c4:	409c                	lw	a5,0(s1)
    800054c6:	04f71d63          	bne	a4,a5,80005520 <sys_link+0x100>
    800054ca:	40d0                	lw	a2,4(s1)
    800054cc:	fd040593          	addi	a1,s0,-48
    800054d0:	854a                	mv	a0,s2
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	9ac080e7          	jalr	-1620(ra) # 80003e7e <dirlink>
    800054da:	04054363          	bltz	a0,80005520 <sys_link+0x100>
  iunlockput(dp);
    800054de:	854a                	mv	a0,s2
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	512080e7          	jalr	1298(ra) # 800039f2 <iunlockput>
  iput(ip);
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	460080e7          	jalr	1120(ra) # 8000394a <iput>
  end_op();
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	cda080e7          	jalr	-806(ra) # 800041cc <end_op>
  return 0;
    800054fa:	4781                	li	a5,0
    800054fc:	a085                	j	8000555c <sys_link+0x13c>
    end_op();
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	cce080e7          	jalr	-818(ra) # 800041cc <end_op>
    return -1;
    80005506:	57fd                	li	a5,-1
    80005508:	a891                	j	8000555c <sys_link+0x13c>
    iunlockput(ip);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	4e6080e7          	jalr	1254(ra) # 800039f2 <iunlockput>
    end_op();
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	cb8080e7          	jalr	-840(ra) # 800041cc <end_op>
    return -1;
    8000551c:	57fd                	li	a5,-1
    8000551e:	a83d                	j	8000555c <sys_link+0x13c>
    iunlockput(dp);
    80005520:	854a                	mv	a0,s2
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	4d0080e7          	jalr	1232(ra) # 800039f2 <iunlockput>
  ilock(ip);
    8000552a:	8526                	mv	a0,s1
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	264080e7          	jalr	612(ra) # 80003790 <ilock>
  ip->nlink--;
    80005534:	04a4d783          	lhu	a5,74(s1)
    80005538:	37fd                	addiw	a5,a5,-1
    8000553a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000553e:	8526                	mv	a0,s1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	186080e7          	jalr	390(ra) # 800036c6 <iupdate>
  iunlockput(ip);
    80005548:	8526                	mv	a0,s1
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	4a8080e7          	jalr	1192(ra) # 800039f2 <iunlockput>
  end_op();
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	c7a080e7          	jalr	-902(ra) # 800041cc <end_op>
  return -1;
    8000555a:	57fd                	li	a5,-1
}
    8000555c:	853e                	mv	a0,a5
    8000555e:	70b2                	ld	ra,296(sp)
    80005560:	7412                	ld	s0,288(sp)
    80005562:	64f2                	ld	s1,280(sp)
    80005564:	6952                	ld	s2,272(sp)
    80005566:	6155                	addi	sp,sp,304
    80005568:	8082                	ret

000000008000556a <sys_unlink>:
{
    8000556a:	7151                	addi	sp,sp,-240
    8000556c:	f586                	sd	ra,232(sp)
    8000556e:	f1a2                	sd	s0,224(sp)
    80005570:	eda6                	sd	s1,216(sp)
    80005572:	e9ca                	sd	s2,208(sp)
    80005574:	e5ce                	sd	s3,200(sp)
    80005576:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005578:	08000613          	li	a2,128
    8000557c:	f3040593          	addi	a1,s0,-208
    80005580:	4501                	li	a0,0
    80005582:	ffffd097          	auipc	ra,0xffffd
    80005586:	604080e7          	jalr	1540(ra) # 80002b86 <argstr>
    8000558a:	18054163          	bltz	a0,8000570c <sys_unlink+0x1a2>
  begin_op();
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	bbe080e7          	jalr	-1090(ra) # 8000414c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005596:	fb040593          	addi	a1,s0,-80
    8000559a:	f3040513          	addi	a0,s0,-208
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	9c0080e7          	jalr	-1600(ra) # 80003f5e <nameiparent>
    800055a6:	84aa                	mv	s1,a0
    800055a8:	c979                	beqz	a0,8000567e <sys_unlink+0x114>
  ilock(dp);
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	1e6080e7          	jalr	486(ra) # 80003790 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055b2:	00003597          	auipc	a1,0x3
    800055b6:	2c658593          	addi	a1,a1,710 # 80008878 <sysnames+0x2c8>
    800055ba:	fb040513          	addi	a0,s0,-80
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	696080e7          	jalr	1686(ra) # 80003c54 <namecmp>
    800055c6:	14050a63          	beqz	a0,8000571a <sys_unlink+0x1b0>
    800055ca:	00003597          	auipc	a1,0x3
    800055ce:	2b658593          	addi	a1,a1,694 # 80008880 <sysnames+0x2d0>
    800055d2:	fb040513          	addi	a0,s0,-80
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	67e080e7          	jalr	1662(ra) # 80003c54 <namecmp>
    800055de:	12050e63          	beqz	a0,8000571a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055e2:	f2c40613          	addi	a2,s0,-212
    800055e6:	fb040593          	addi	a1,s0,-80
    800055ea:	8526                	mv	a0,s1
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	682080e7          	jalr	1666(ra) # 80003c6e <dirlookup>
    800055f4:	892a                	mv	s2,a0
    800055f6:	12050263          	beqz	a0,8000571a <sys_unlink+0x1b0>
  ilock(ip);
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	196080e7          	jalr	406(ra) # 80003790 <ilock>
  if(ip->nlink < 1)
    80005602:	04a91783          	lh	a5,74(s2)
    80005606:	08f05263          	blez	a5,8000568a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000560a:	04491703          	lh	a4,68(s2)
    8000560e:	4785                	li	a5,1
    80005610:	08f70563          	beq	a4,a5,8000569a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005614:	4641                	li	a2,16
    80005616:	4581                	li	a1,0
    80005618:	fc040513          	addi	a0,s0,-64
    8000561c:	ffffb097          	auipc	ra,0xffffb
    80005620:	73a080e7          	jalr	1850(ra) # 80000d56 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005624:	4741                	li	a4,16
    80005626:	f2c42683          	lw	a3,-212(s0)
    8000562a:	fc040613          	addi	a2,s0,-64
    8000562e:	4581                	li	a1,0
    80005630:	8526                	mv	a0,s1
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	508080e7          	jalr	1288(ra) # 80003b3a <writei>
    8000563a:	47c1                	li	a5,16
    8000563c:	0af51563          	bne	a0,a5,800056e6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005640:	04491703          	lh	a4,68(s2)
    80005644:	4785                	li	a5,1
    80005646:	0af70863          	beq	a4,a5,800056f6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000564a:	8526                	mv	a0,s1
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	3a6080e7          	jalr	934(ra) # 800039f2 <iunlockput>
  ip->nlink--;
    80005654:	04a95783          	lhu	a5,74(s2)
    80005658:	37fd                	addiw	a5,a5,-1
    8000565a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000565e:	854a                	mv	a0,s2
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	066080e7          	jalr	102(ra) # 800036c6 <iupdate>
  iunlockput(ip);
    80005668:	854a                	mv	a0,s2
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	388080e7          	jalr	904(ra) # 800039f2 <iunlockput>
  end_op();
    80005672:	fffff097          	auipc	ra,0xfffff
    80005676:	b5a080e7          	jalr	-1190(ra) # 800041cc <end_op>
  return 0;
    8000567a:	4501                	li	a0,0
    8000567c:	a84d                	j	8000572e <sys_unlink+0x1c4>
    end_op();
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	b4e080e7          	jalr	-1202(ra) # 800041cc <end_op>
    return -1;
    80005686:	557d                	li	a0,-1
    80005688:	a05d                	j	8000572e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000568a:	00003517          	auipc	a0,0x3
    8000568e:	21e50513          	addi	a0,a0,542 # 800088a8 <sysnames+0x2f8>
    80005692:	ffffb097          	auipc	ra,0xffffb
    80005696:	eb6080e7          	jalr	-330(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000569a:	04c92703          	lw	a4,76(s2)
    8000569e:	02000793          	li	a5,32
    800056a2:	f6e7f9e3          	bgeu	a5,a4,80005614 <sys_unlink+0xaa>
    800056a6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056aa:	4741                	li	a4,16
    800056ac:	86ce                	mv	a3,s3
    800056ae:	f1840613          	addi	a2,s0,-232
    800056b2:	4581                	li	a1,0
    800056b4:	854a                	mv	a0,s2
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	38e080e7          	jalr	910(ra) # 80003a44 <readi>
    800056be:	47c1                	li	a5,16
    800056c0:	00f51b63          	bne	a0,a5,800056d6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056c4:	f1845783          	lhu	a5,-232(s0)
    800056c8:	e7a1                	bnez	a5,80005710 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ca:	29c1                	addiw	s3,s3,16
    800056cc:	04c92783          	lw	a5,76(s2)
    800056d0:	fcf9ede3          	bltu	s3,a5,800056aa <sys_unlink+0x140>
    800056d4:	b781                	j	80005614 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056d6:	00003517          	auipc	a0,0x3
    800056da:	1ea50513          	addi	a0,a0,490 # 800088c0 <sysnames+0x310>
    800056de:	ffffb097          	auipc	ra,0xffffb
    800056e2:	e6a080e7          	jalr	-406(ra) # 80000548 <panic>
    panic("unlink: writei");
    800056e6:	00003517          	auipc	a0,0x3
    800056ea:	1f250513          	addi	a0,a0,498 # 800088d8 <sysnames+0x328>
    800056ee:	ffffb097          	auipc	ra,0xffffb
    800056f2:	e5a080e7          	jalr	-422(ra) # 80000548 <panic>
    dp->nlink--;
    800056f6:	04a4d783          	lhu	a5,74(s1)
    800056fa:	37fd                	addiw	a5,a5,-1
    800056fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005700:	8526                	mv	a0,s1
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	fc4080e7          	jalr	-60(ra) # 800036c6 <iupdate>
    8000570a:	b781                	j	8000564a <sys_unlink+0xe0>
    return -1;
    8000570c:	557d                	li	a0,-1
    8000570e:	a005                	j	8000572e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005710:	854a                	mv	a0,s2
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	2e0080e7          	jalr	736(ra) # 800039f2 <iunlockput>
  iunlockput(dp);
    8000571a:	8526                	mv	a0,s1
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	2d6080e7          	jalr	726(ra) # 800039f2 <iunlockput>
  end_op();
    80005724:	fffff097          	auipc	ra,0xfffff
    80005728:	aa8080e7          	jalr	-1368(ra) # 800041cc <end_op>
  return -1;
    8000572c:	557d                	li	a0,-1
}
    8000572e:	70ae                	ld	ra,232(sp)
    80005730:	740e                	ld	s0,224(sp)
    80005732:	64ee                	ld	s1,216(sp)
    80005734:	694e                	ld	s2,208(sp)
    80005736:	69ae                	ld	s3,200(sp)
    80005738:	616d                	addi	sp,sp,240
    8000573a:	8082                	ret

000000008000573c <sys_open>:

uint64
sys_open(void)
{
    8000573c:	7131                	addi	sp,sp,-192
    8000573e:	fd06                	sd	ra,184(sp)
    80005740:	f922                	sd	s0,176(sp)
    80005742:	f526                	sd	s1,168(sp)
    80005744:	f14a                	sd	s2,160(sp)
    80005746:	ed4e                	sd	s3,152(sp)
    80005748:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000574a:	08000613          	li	a2,128
    8000574e:	f5040593          	addi	a1,s0,-176
    80005752:	4501                	li	a0,0
    80005754:	ffffd097          	auipc	ra,0xffffd
    80005758:	432080e7          	jalr	1074(ra) # 80002b86 <argstr>
    return -1;
    8000575c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000575e:	0c054163          	bltz	a0,80005820 <sys_open+0xe4>
    80005762:	f4c40593          	addi	a1,s0,-180
    80005766:	4505                	li	a0,1
    80005768:	ffffd097          	auipc	ra,0xffffd
    8000576c:	3da080e7          	jalr	986(ra) # 80002b42 <argint>
    80005770:	0a054863          	bltz	a0,80005820 <sys_open+0xe4>

  begin_op();
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	9d8080e7          	jalr	-1576(ra) # 8000414c <begin_op>

  if(omode & O_CREATE){
    8000577c:	f4c42783          	lw	a5,-180(s0)
    80005780:	2007f793          	andi	a5,a5,512
    80005784:	cbdd                	beqz	a5,8000583a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005786:	4681                	li	a3,0
    80005788:	4601                	li	a2,0
    8000578a:	4589                	li	a1,2
    8000578c:	f5040513          	addi	a0,s0,-176
    80005790:	00000097          	auipc	ra,0x0
    80005794:	972080e7          	jalr	-1678(ra) # 80005102 <create>
    80005798:	892a                	mv	s2,a0
    if(ip == 0){
    8000579a:	c959                	beqz	a0,80005830 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000579c:	04491703          	lh	a4,68(s2)
    800057a0:	478d                	li	a5,3
    800057a2:	00f71763          	bne	a4,a5,800057b0 <sys_open+0x74>
    800057a6:	04695703          	lhu	a4,70(s2)
    800057aa:	47a5                	li	a5,9
    800057ac:	0ce7ec63          	bltu	a5,a4,80005884 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	db2080e7          	jalr	-590(ra) # 80004562 <filealloc>
    800057b8:	89aa                	mv	s3,a0
    800057ba:	10050263          	beqz	a0,800058be <sys_open+0x182>
    800057be:	00000097          	auipc	ra,0x0
    800057c2:	902080e7          	jalr	-1790(ra) # 800050c0 <fdalloc>
    800057c6:	84aa                	mv	s1,a0
    800057c8:	0e054663          	bltz	a0,800058b4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057cc:	04491703          	lh	a4,68(s2)
    800057d0:	478d                	li	a5,3
    800057d2:	0cf70463          	beq	a4,a5,8000589a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057d6:	4789                	li	a5,2
    800057d8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057dc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057e0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057e4:	f4c42783          	lw	a5,-180(s0)
    800057e8:	0017c713          	xori	a4,a5,1
    800057ec:	8b05                	andi	a4,a4,1
    800057ee:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057f2:	0037f713          	andi	a4,a5,3
    800057f6:	00e03733          	snez	a4,a4
    800057fa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057fe:	4007f793          	andi	a5,a5,1024
    80005802:	c791                	beqz	a5,8000580e <sys_open+0xd2>
    80005804:	04491703          	lh	a4,68(s2)
    80005808:	4789                	li	a5,2
    8000580a:	08f70f63          	beq	a4,a5,800058a8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000580e:	854a                	mv	a0,s2
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	042080e7          	jalr	66(ra) # 80003852 <iunlock>
  end_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	9b4080e7          	jalr	-1612(ra) # 800041cc <end_op>

  return fd;
}
    80005820:	8526                	mv	a0,s1
    80005822:	70ea                	ld	ra,184(sp)
    80005824:	744a                	ld	s0,176(sp)
    80005826:	74aa                	ld	s1,168(sp)
    80005828:	790a                	ld	s2,160(sp)
    8000582a:	69ea                	ld	s3,152(sp)
    8000582c:	6129                	addi	sp,sp,192
    8000582e:	8082                	ret
      end_op();
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	99c080e7          	jalr	-1636(ra) # 800041cc <end_op>
      return -1;
    80005838:	b7e5                	j	80005820 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000583a:	f5040513          	addi	a0,s0,-176
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	702080e7          	jalr	1794(ra) # 80003f40 <namei>
    80005846:	892a                	mv	s2,a0
    80005848:	c905                	beqz	a0,80005878 <sys_open+0x13c>
    ilock(ip);
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	f46080e7          	jalr	-186(ra) # 80003790 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005852:	04491703          	lh	a4,68(s2)
    80005856:	4785                	li	a5,1
    80005858:	f4f712e3          	bne	a4,a5,8000579c <sys_open+0x60>
    8000585c:	f4c42783          	lw	a5,-180(s0)
    80005860:	dba1                	beqz	a5,800057b0 <sys_open+0x74>
      iunlockput(ip);
    80005862:	854a                	mv	a0,s2
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	18e080e7          	jalr	398(ra) # 800039f2 <iunlockput>
      end_op();
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	960080e7          	jalr	-1696(ra) # 800041cc <end_op>
      return -1;
    80005874:	54fd                	li	s1,-1
    80005876:	b76d                	j	80005820 <sys_open+0xe4>
      end_op();
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	954080e7          	jalr	-1708(ra) # 800041cc <end_op>
      return -1;
    80005880:	54fd                	li	s1,-1
    80005882:	bf79                	j	80005820 <sys_open+0xe4>
    iunlockput(ip);
    80005884:	854a                	mv	a0,s2
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	16c080e7          	jalr	364(ra) # 800039f2 <iunlockput>
    end_op();
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	93e080e7          	jalr	-1730(ra) # 800041cc <end_op>
    return -1;
    80005896:	54fd                	li	s1,-1
    80005898:	b761                	j	80005820 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000589a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000589e:	04691783          	lh	a5,70(s2)
    800058a2:	02f99223          	sh	a5,36(s3)
    800058a6:	bf2d                	j	800057e0 <sys_open+0xa4>
    itrunc(ip);
    800058a8:	854a                	mv	a0,s2
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	ff4080e7          	jalr	-12(ra) # 8000389e <itrunc>
    800058b2:	bfb1                	j	8000580e <sys_open+0xd2>
      fileclose(f);
    800058b4:	854e                	mv	a0,s3
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	d68080e7          	jalr	-664(ra) # 8000461e <fileclose>
    iunlockput(ip);
    800058be:	854a                	mv	a0,s2
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	132080e7          	jalr	306(ra) # 800039f2 <iunlockput>
    end_op();
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	904080e7          	jalr	-1788(ra) # 800041cc <end_op>
    return -1;
    800058d0:	54fd                	li	s1,-1
    800058d2:	b7b9                	j	80005820 <sys_open+0xe4>

00000000800058d4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058d4:	7175                	addi	sp,sp,-144
    800058d6:	e506                	sd	ra,136(sp)
    800058d8:	e122                	sd	s0,128(sp)
    800058da:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	870080e7          	jalr	-1936(ra) # 8000414c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058e4:	08000613          	li	a2,128
    800058e8:	f7040593          	addi	a1,s0,-144
    800058ec:	4501                	li	a0,0
    800058ee:	ffffd097          	auipc	ra,0xffffd
    800058f2:	298080e7          	jalr	664(ra) # 80002b86 <argstr>
    800058f6:	02054963          	bltz	a0,80005928 <sys_mkdir+0x54>
    800058fa:	4681                	li	a3,0
    800058fc:	4601                	li	a2,0
    800058fe:	4585                	li	a1,1
    80005900:	f7040513          	addi	a0,s0,-144
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	7fe080e7          	jalr	2046(ra) # 80005102 <create>
    8000590c:	cd11                	beqz	a0,80005928 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	0e4080e7          	jalr	228(ra) # 800039f2 <iunlockput>
  end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	8b6080e7          	jalr	-1866(ra) # 800041cc <end_op>
  return 0;
    8000591e:	4501                	li	a0,0
}
    80005920:	60aa                	ld	ra,136(sp)
    80005922:	640a                	ld	s0,128(sp)
    80005924:	6149                	addi	sp,sp,144
    80005926:	8082                	ret
    end_op();
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	8a4080e7          	jalr	-1884(ra) # 800041cc <end_op>
    return -1;
    80005930:	557d                	li	a0,-1
    80005932:	b7fd                	j	80005920 <sys_mkdir+0x4c>

0000000080005934 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005934:	7135                	addi	sp,sp,-160
    80005936:	ed06                	sd	ra,152(sp)
    80005938:	e922                	sd	s0,144(sp)
    8000593a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	810080e7          	jalr	-2032(ra) # 8000414c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005944:	08000613          	li	a2,128
    80005948:	f7040593          	addi	a1,s0,-144
    8000594c:	4501                	li	a0,0
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	238080e7          	jalr	568(ra) # 80002b86 <argstr>
    80005956:	04054a63          	bltz	a0,800059aa <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000595a:	f6c40593          	addi	a1,s0,-148
    8000595e:	4505                	li	a0,1
    80005960:	ffffd097          	auipc	ra,0xffffd
    80005964:	1e2080e7          	jalr	482(ra) # 80002b42 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005968:	04054163          	bltz	a0,800059aa <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000596c:	f6840593          	addi	a1,s0,-152
    80005970:	4509                	li	a0,2
    80005972:	ffffd097          	auipc	ra,0xffffd
    80005976:	1d0080e7          	jalr	464(ra) # 80002b42 <argint>
     argint(1, &major) < 0 ||
    8000597a:	02054863          	bltz	a0,800059aa <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000597e:	f6841683          	lh	a3,-152(s0)
    80005982:	f6c41603          	lh	a2,-148(s0)
    80005986:	458d                	li	a1,3
    80005988:	f7040513          	addi	a0,s0,-144
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	776080e7          	jalr	1910(ra) # 80005102 <create>
     argint(2, &minor) < 0 ||
    80005994:	c919                	beqz	a0,800059aa <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	05c080e7          	jalr	92(ra) # 800039f2 <iunlockput>
  end_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	82e080e7          	jalr	-2002(ra) # 800041cc <end_op>
  return 0;
    800059a6:	4501                	li	a0,0
    800059a8:	a031                	j	800059b4 <sys_mknod+0x80>
    end_op();
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	822080e7          	jalr	-2014(ra) # 800041cc <end_op>
    return -1;
    800059b2:	557d                	li	a0,-1
}
    800059b4:	60ea                	ld	ra,152(sp)
    800059b6:	644a                	ld	s0,144(sp)
    800059b8:	610d                	addi	sp,sp,160
    800059ba:	8082                	ret

00000000800059bc <sys_chdir>:

uint64
sys_chdir(void)
{
    800059bc:	7135                	addi	sp,sp,-160
    800059be:	ed06                	sd	ra,152(sp)
    800059c0:	e922                	sd	s0,144(sp)
    800059c2:	e526                	sd	s1,136(sp)
    800059c4:	e14a                	sd	s2,128(sp)
    800059c6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059c8:	ffffc097          	auipc	ra,0xffffc
    800059cc:	060080e7          	jalr	96(ra) # 80001a28 <myproc>
    800059d0:	892a                	mv	s2,a0
  
  begin_op();
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	77a080e7          	jalr	1914(ra) # 8000414c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059da:	08000613          	li	a2,128
    800059de:	f6040593          	addi	a1,s0,-160
    800059e2:	4501                	li	a0,0
    800059e4:	ffffd097          	auipc	ra,0xffffd
    800059e8:	1a2080e7          	jalr	418(ra) # 80002b86 <argstr>
    800059ec:	04054b63          	bltz	a0,80005a42 <sys_chdir+0x86>
    800059f0:	f6040513          	addi	a0,s0,-160
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	54c080e7          	jalr	1356(ra) # 80003f40 <namei>
    800059fc:	84aa                	mv	s1,a0
    800059fe:	c131                	beqz	a0,80005a42 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	d90080e7          	jalr	-624(ra) # 80003790 <ilock>
  if(ip->type != T_DIR){
    80005a08:	04449703          	lh	a4,68(s1)
    80005a0c:	4785                	li	a5,1
    80005a0e:	04f71063          	bne	a4,a5,80005a4e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a12:	8526                	mv	a0,s1
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	e3e080e7          	jalr	-450(ra) # 80003852 <iunlock>
  iput(p->cwd);
    80005a1c:	15093503          	ld	a0,336(s2)
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	f2a080e7          	jalr	-214(ra) # 8000394a <iput>
  end_op();
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	7a4080e7          	jalr	1956(ra) # 800041cc <end_op>
  p->cwd = ip;
    80005a30:	14993823          	sd	s1,336(s2)
  return 0;
    80005a34:	4501                	li	a0,0
}
    80005a36:	60ea                	ld	ra,152(sp)
    80005a38:	644a                	ld	s0,144(sp)
    80005a3a:	64aa                	ld	s1,136(sp)
    80005a3c:	690a                	ld	s2,128(sp)
    80005a3e:	610d                	addi	sp,sp,160
    80005a40:	8082                	ret
    end_op();
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	78a080e7          	jalr	1930(ra) # 800041cc <end_op>
    return -1;
    80005a4a:	557d                	li	a0,-1
    80005a4c:	b7ed                	j	80005a36 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a4e:	8526                	mv	a0,s1
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	fa2080e7          	jalr	-94(ra) # 800039f2 <iunlockput>
    end_op();
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	774080e7          	jalr	1908(ra) # 800041cc <end_op>
    return -1;
    80005a60:	557d                	li	a0,-1
    80005a62:	bfd1                	j	80005a36 <sys_chdir+0x7a>

0000000080005a64 <sys_exec>:

uint64
sys_exec(void)
{
    80005a64:	7145                	addi	sp,sp,-464
    80005a66:	e786                	sd	ra,456(sp)
    80005a68:	e3a2                	sd	s0,448(sp)
    80005a6a:	ff26                	sd	s1,440(sp)
    80005a6c:	fb4a                	sd	s2,432(sp)
    80005a6e:	f74e                	sd	s3,424(sp)
    80005a70:	f352                	sd	s4,416(sp)
    80005a72:	ef56                	sd	s5,408(sp)
    80005a74:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a76:	08000613          	li	a2,128
    80005a7a:	f4040593          	addi	a1,s0,-192
    80005a7e:	4501                	li	a0,0
    80005a80:	ffffd097          	auipc	ra,0xffffd
    80005a84:	106080e7          	jalr	262(ra) # 80002b86 <argstr>
    return -1;
    80005a88:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a8a:	0c054a63          	bltz	a0,80005b5e <sys_exec+0xfa>
    80005a8e:	e3840593          	addi	a1,s0,-456
    80005a92:	4505                	li	a0,1
    80005a94:	ffffd097          	auipc	ra,0xffffd
    80005a98:	0d0080e7          	jalr	208(ra) # 80002b64 <argaddr>
    80005a9c:	0c054163          	bltz	a0,80005b5e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005aa0:	10000613          	li	a2,256
    80005aa4:	4581                	li	a1,0
    80005aa6:	e4040513          	addi	a0,s0,-448
    80005aaa:	ffffb097          	auipc	ra,0xffffb
    80005aae:	2ac080e7          	jalr	684(ra) # 80000d56 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ab2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ab6:	89a6                	mv	s3,s1
    80005ab8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005aba:	02000a13          	li	s4,32
    80005abe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ac2:	00391513          	slli	a0,s2,0x3
    80005ac6:	e3040593          	addi	a1,s0,-464
    80005aca:	e3843783          	ld	a5,-456(s0)
    80005ace:	953e                	add	a0,a0,a5
    80005ad0:	ffffd097          	auipc	ra,0xffffd
    80005ad4:	fd8080e7          	jalr	-40(ra) # 80002aa8 <fetchaddr>
    80005ad8:	02054a63          	bltz	a0,80005b0c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005adc:	e3043783          	ld	a5,-464(s0)
    80005ae0:	c3b9                	beqz	a5,80005b26 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ae2:	ffffb097          	auipc	ra,0xffffb
    80005ae6:	03e080e7          	jalr	62(ra) # 80000b20 <kalloc>
    80005aea:	85aa                	mv	a1,a0
    80005aec:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005af0:	cd11                	beqz	a0,80005b0c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005af2:	6605                	lui	a2,0x1
    80005af4:	e3043503          	ld	a0,-464(s0)
    80005af8:	ffffd097          	auipc	ra,0xffffd
    80005afc:	002080e7          	jalr	2(ra) # 80002afa <fetchstr>
    80005b00:	00054663          	bltz	a0,80005b0c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b04:	0905                	addi	s2,s2,1
    80005b06:	09a1                	addi	s3,s3,8
    80005b08:	fb491be3          	bne	s2,s4,80005abe <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b0c:	10048913          	addi	s2,s1,256
    80005b10:	6088                	ld	a0,0(s1)
    80005b12:	c529                	beqz	a0,80005b5c <sys_exec+0xf8>
    kfree(argv[i]);
    80005b14:	ffffb097          	auipc	ra,0xffffb
    80005b18:	f10080e7          	jalr	-240(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b1c:	04a1                	addi	s1,s1,8
    80005b1e:	ff2499e3          	bne	s1,s2,80005b10 <sys_exec+0xac>
  return -1;
    80005b22:	597d                	li	s2,-1
    80005b24:	a82d                	j	80005b5e <sys_exec+0xfa>
      argv[i] = 0;
    80005b26:	0a8e                	slli	s5,s5,0x3
    80005b28:	fc040793          	addi	a5,s0,-64
    80005b2c:	9abe                	add	s5,s5,a5
    80005b2e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b32:	e4040593          	addi	a1,s0,-448
    80005b36:	f4040513          	addi	a0,s0,-192
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	194080e7          	jalr	404(ra) # 80004cce <exec>
    80005b42:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b44:	10048993          	addi	s3,s1,256
    80005b48:	6088                	ld	a0,0(s1)
    80005b4a:	c911                	beqz	a0,80005b5e <sys_exec+0xfa>
    kfree(argv[i]);
    80005b4c:	ffffb097          	auipc	ra,0xffffb
    80005b50:	ed8080e7          	jalr	-296(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b54:	04a1                	addi	s1,s1,8
    80005b56:	ff3499e3          	bne	s1,s3,80005b48 <sys_exec+0xe4>
    80005b5a:	a011                	j	80005b5e <sys_exec+0xfa>
  return -1;
    80005b5c:	597d                	li	s2,-1
}
    80005b5e:	854a                	mv	a0,s2
    80005b60:	60be                	ld	ra,456(sp)
    80005b62:	641e                	ld	s0,448(sp)
    80005b64:	74fa                	ld	s1,440(sp)
    80005b66:	795a                	ld	s2,432(sp)
    80005b68:	79ba                	ld	s3,424(sp)
    80005b6a:	7a1a                	ld	s4,416(sp)
    80005b6c:	6afa                	ld	s5,408(sp)
    80005b6e:	6179                	addi	sp,sp,464
    80005b70:	8082                	ret

0000000080005b72 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b72:	7139                	addi	sp,sp,-64
    80005b74:	fc06                	sd	ra,56(sp)
    80005b76:	f822                	sd	s0,48(sp)
    80005b78:	f426                	sd	s1,40(sp)
    80005b7a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b7c:	ffffc097          	auipc	ra,0xffffc
    80005b80:	eac080e7          	jalr	-340(ra) # 80001a28 <myproc>
    80005b84:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b86:	fd840593          	addi	a1,s0,-40
    80005b8a:	4501                	li	a0,0
    80005b8c:	ffffd097          	auipc	ra,0xffffd
    80005b90:	fd8080e7          	jalr	-40(ra) # 80002b64 <argaddr>
    return -1;
    80005b94:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b96:	0e054063          	bltz	a0,80005c76 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b9a:	fc840593          	addi	a1,s0,-56
    80005b9e:	fd040513          	addi	a0,s0,-48
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	dd2080e7          	jalr	-558(ra) # 80004974 <pipealloc>
    return -1;
    80005baa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bac:	0c054563          	bltz	a0,80005c76 <sys_pipe+0x104>
  fd0 = -1;
    80005bb0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bb4:	fd043503          	ld	a0,-48(s0)
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	508080e7          	jalr	1288(ra) # 800050c0 <fdalloc>
    80005bc0:	fca42223          	sw	a0,-60(s0)
    80005bc4:	08054c63          	bltz	a0,80005c5c <sys_pipe+0xea>
    80005bc8:	fc843503          	ld	a0,-56(s0)
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	4f4080e7          	jalr	1268(ra) # 800050c0 <fdalloc>
    80005bd4:	fca42023          	sw	a0,-64(s0)
    80005bd8:	06054863          	bltz	a0,80005c48 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bdc:	4691                	li	a3,4
    80005bde:	fc440613          	addi	a2,s0,-60
    80005be2:	fd843583          	ld	a1,-40(s0)
    80005be6:	68a8                	ld	a0,80(s1)
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	b34080e7          	jalr	-1228(ra) # 8000171c <copyout>
    80005bf0:	02054063          	bltz	a0,80005c10 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bf4:	4691                	li	a3,4
    80005bf6:	fc040613          	addi	a2,s0,-64
    80005bfa:	fd843583          	ld	a1,-40(s0)
    80005bfe:	0591                	addi	a1,a1,4
    80005c00:	68a8                	ld	a0,80(s1)
    80005c02:	ffffc097          	auipc	ra,0xffffc
    80005c06:	b1a080e7          	jalr	-1254(ra) # 8000171c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c0a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c0c:	06055563          	bgez	a0,80005c76 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c10:	fc442783          	lw	a5,-60(s0)
    80005c14:	07e9                	addi	a5,a5,26
    80005c16:	078e                	slli	a5,a5,0x3
    80005c18:	97a6                	add	a5,a5,s1
    80005c1a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c1e:	fc042503          	lw	a0,-64(s0)
    80005c22:	0569                	addi	a0,a0,26
    80005c24:	050e                	slli	a0,a0,0x3
    80005c26:	9526                	add	a0,a0,s1
    80005c28:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c2c:	fd043503          	ld	a0,-48(s0)
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	9ee080e7          	jalr	-1554(ra) # 8000461e <fileclose>
    fileclose(wf);
    80005c38:	fc843503          	ld	a0,-56(s0)
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	9e2080e7          	jalr	-1566(ra) # 8000461e <fileclose>
    return -1;
    80005c44:	57fd                	li	a5,-1
    80005c46:	a805                	j	80005c76 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c48:	fc442783          	lw	a5,-60(s0)
    80005c4c:	0007c863          	bltz	a5,80005c5c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c50:	01a78513          	addi	a0,a5,26
    80005c54:	050e                	slli	a0,a0,0x3
    80005c56:	9526                	add	a0,a0,s1
    80005c58:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c5c:	fd043503          	ld	a0,-48(s0)
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	9be080e7          	jalr	-1602(ra) # 8000461e <fileclose>
    fileclose(wf);
    80005c68:	fc843503          	ld	a0,-56(s0)
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	9b2080e7          	jalr	-1614(ra) # 8000461e <fileclose>
    return -1;
    80005c74:	57fd                	li	a5,-1
}
    80005c76:	853e                	mv	a0,a5
    80005c78:	70e2                	ld	ra,56(sp)
    80005c7a:	7442                	ld	s0,48(sp)
    80005c7c:	74a2                	ld	s1,40(sp)
    80005c7e:	6121                	addi	sp,sp,64
    80005c80:	8082                	ret
	...

0000000080005c90 <kernelvec>:
    80005c90:	7111                	addi	sp,sp,-256
    80005c92:	e006                	sd	ra,0(sp)
    80005c94:	e40a                	sd	sp,8(sp)
    80005c96:	e80e                	sd	gp,16(sp)
    80005c98:	ec12                	sd	tp,24(sp)
    80005c9a:	f016                	sd	t0,32(sp)
    80005c9c:	f41a                	sd	t1,40(sp)
    80005c9e:	f81e                	sd	t2,48(sp)
    80005ca0:	fc22                	sd	s0,56(sp)
    80005ca2:	e0a6                	sd	s1,64(sp)
    80005ca4:	e4aa                	sd	a0,72(sp)
    80005ca6:	e8ae                	sd	a1,80(sp)
    80005ca8:	ecb2                	sd	a2,88(sp)
    80005caa:	f0b6                	sd	a3,96(sp)
    80005cac:	f4ba                	sd	a4,104(sp)
    80005cae:	f8be                	sd	a5,112(sp)
    80005cb0:	fcc2                	sd	a6,120(sp)
    80005cb2:	e146                	sd	a7,128(sp)
    80005cb4:	e54a                	sd	s2,136(sp)
    80005cb6:	e94e                	sd	s3,144(sp)
    80005cb8:	ed52                	sd	s4,152(sp)
    80005cba:	f156                	sd	s5,160(sp)
    80005cbc:	f55a                	sd	s6,168(sp)
    80005cbe:	f95e                	sd	s7,176(sp)
    80005cc0:	fd62                	sd	s8,184(sp)
    80005cc2:	e1e6                	sd	s9,192(sp)
    80005cc4:	e5ea                	sd	s10,200(sp)
    80005cc6:	e9ee                	sd	s11,208(sp)
    80005cc8:	edf2                	sd	t3,216(sp)
    80005cca:	f1f6                	sd	t4,224(sp)
    80005ccc:	f5fa                	sd	t5,232(sp)
    80005cce:	f9fe                	sd	t6,240(sp)
    80005cd0:	ca5fc0ef          	jal	ra,80002974 <kerneltrap>
    80005cd4:	6082                	ld	ra,0(sp)
    80005cd6:	6122                	ld	sp,8(sp)
    80005cd8:	61c2                	ld	gp,16(sp)
    80005cda:	7282                	ld	t0,32(sp)
    80005cdc:	7322                	ld	t1,40(sp)
    80005cde:	73c2                	ld	t2,48(sp)
    80005ce0:	7462                	ld	s0,56(sp)
    80005ce2:	6486                	ld	s1,64(sp)
    80005ce4:	6526                	ld	a0,72(sp)
    80005ce6:	65c6                	ld	a1,80(sp)
    80005ce8:	6666                	ld	a2,88(sp)
    80005cea:	7686                	ld	a3,96(sp)
    80005cec:	7726                	ld	a4,104(sp)
    80005cee:	77c6                	ld	a5,112(sp)
    80005cf0:	7866                	ld	a6,120(sp)
    80005cf2:	688a                	ld	a7,128(sp)
    80005cf4:	692a                	ld	s2,136(sp)
    80005cf6:	69ca                	ld	s3,144(sp)
    80005cf8:	6a6a                	ld	s4,152(sp)
    80005cfa:	7a8a                	ld	s5,160(sp)
    80005cfc:	7b2a                	ld	s6,168(sp)
    80005cfe:	7bca                	ld	s7,176(sp)
    80005d00:	7c6a                	ld	s8,184(sp)
    80005d02:	6c8e                	ld	s9,192(sp)
    80005d04:	6d2e                	ld	s10,200(sp)
    80005d06:	6dce                	ld	s11,208(sp)
    80005d08:	6e6e                	ld	t3,216(sp)
    80005d0a:	7e8e                	ld	t4,224(sp)
    80005d0c:	7f2e                	ld	t5,232(sp)
    80005d0e:	7fce                	ld	t6,240(sp)
    80005d10:	6111                	addi	sp,sp,256
    80005d12:	10200073          	sret
    80005d16:	00000013          	nop
    80005d1a:	00000013          	nop
    80005d1e:	0001                	nop

0000000080005d20 <timervec>:
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	e10c                	sd	a1,0(a0)
    80005d26:	e510                	sd	a2,8(a0)
    80005d28:	e914                	sd	a3,16(a0)
    80005d2a:	710c                	ld	a1,32(a0)
    80005d2c:	7510                	ld	a2,40(a0)
    80005d2e:	6194                	ld	a3,0(a1)
    80005d30:	96b2                	add	a3,a3,a2
    80005d32:	e194                	sd	a3,0(a1)
    80005d34:	4589                	li	a1,2
    80005d36:	14459073          	csrw	sip,a1
    80005d3a:	6914                	ld	a3,16(a0)
    80005d3c:	6510                	ld	a2,8(a0)
    80005d3e:	610c                	ld	a1,0(a0)
    80005d40:	34051573          	csrrw	a0,mscratch,a0
    80005d44:	30200073          	mret
	...

0000000080005d4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d4a:	1141                	addi	sp,sp,-16
    80005d4c:	e422                	sd	s0,8(sp)
    80005d4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d50:	0c0007b7          	lui	a5,0xc000
    80005d54:	4705                	li	a4,1
    80005d56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d58:	c3d8                	sw	a4,4(a5)
}
    80005d5a:	6422                	ld	s0,8(sp)
    80005d5c:	0141                	addi	sp,sp,16
    80005d5e:	8082                	ret

0000000080005d60 <plicinithart>:

void
plicinithart(void)
{
    80005d60:	1141                	addi	sp,sp,-16
    80005d62:	e406                	sd	ra,8(sp)
    80005d64:	e022                	sd	s0,0(sp)
    80005d66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	c94080e7          	jalr	-876(ra) # 800019fc <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d70:	0085171b          	slliw	a4,a0,0x8
    80005d74:	0c0027b7          	lui	a5,0xc002
    80005d78:	97ba                	add	a5,a5,a4
    80005d7a:	40200713          	li	a4,1026
    80005d7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d82:	00d5151b          	slliw	a0,a0,0xd
    80005d86:	0c2017b7          	lui	a5,0xc201
    80005d8a:	953e                	add	a0,a0,a5
    80005d8c:	00052023          	sw	zero,0(a0)
}
    80005d90:	60a2                	ld	ra,8(sp)
    80005d92:	6402                	ld	s0,0(sp)
    80005d94:	0141                	addi	sp,sp,16
    80005d96:	8082                	ret

0000000080005d98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d98:	1141                	addi	sp,sp,-16
    80005d9a:	e406                	sd	ra,8(sp)
    80005d9c:	e022                	sd	s0,0(sp)
    80005d9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005da0:	ffffc097          	auipc	ra,0xffffc
    80005da4:	c5c080e7          	jalr	-932(ra) # 800019fc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005da8:	00d5179b          	slliw	a5,a0,0xd
    80005dac:	0c201537          	lui	a0,0xc201
    80005db0:	953e                	add	a0,a0,a5
  return irq;
}
    80005db2:	4148                	lw	a0,4(a0)
    80005db4:	60a2                	ld	ra,8(sp)
    80005db6:	6402                	ld	s0,0(sp)
    80005db8:	0141                	addi	sp,sp,16
    80005dba:	8082                	ret

0000000080005dbc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dbc:	1101                	addi	sp,sp,-32
    80005dbe:	ec06                	sd	ra,24(sp)
    80005dc0:	e822                	sd	s0,16(sp)
    80005dc2:	e426                	sd	s1,8(sp)
    80005dc4:	1000                	addi	s0,sp,32
    80005dc6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	c34080e7          	jalr	-972(ra) # 800019fc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005dd0:	00d5151b          	slliw	a0,a0,0xd
    80005dd4:	0c2017b7          	lui	a5,0xc201
    80005dd8:	97aa                	add	a5,a5,a0
    80005dda:	c3c4                	sw	s1,4(a5)
}
    80005ddc:	60e2                	ld	ra,24(sp)
    80005dde:	6442                	ld	s0,16(sp)
    80005de0:	64a2                	ld	s1,8(sp)
    80005de2:	6105                	addi	sp,sp,32
    80005de4:	8082                	ret

0000000080005de6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005de6:	1141                	addi	sp,sp,-16
    80005de8:	e406                	sd	ra,8(sp)
    80005dea:	e022                	sd	s0,0(sp)
    80005dec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dee:	479d                	li	a5,7
    80005df0:	04a7cc63          	blt	a5,a0,80005e48 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005df4:	0001d797          	auipc	a5,0x1d
    80005df8:	20c78793          	addi	a5,a5,524 # 80023000 <disk>
    80005dfc:	00a78733          	add	a4,a5,a0
    80005e00:	6789                	lui	a5,0x2
    80005e02:	97ba                	add	a5,a5,a4
    80005e04:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e08:	eba1                	bnez	a5,80005e58 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005e0a:	00451713          	slli	a4,a0,0x4
    80005e0e:	0001f797          	auipc	a5,0x1f
    80005e12:	1f27b783          	ld	a5,498(a5) # 80025000 <disk+0x2000>
    80005e16:	97ba                	add	a5,a5,a4
    80005e18:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005e1c:	0001d797          	auipc	a5,0x1d
    80005e20:	1e478793          	addi	a5,a5,484 # 80023000 <disk>
    80005e24:	97aa                	add	a5,a5,a0
    80005e26:	6509                	lui	a0,0x2
    80005e28:	953e                	add	a0,a0,a5
    80005e2a:	4785                	li	a5,1
    80005e2c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e30:	0001f517          	auipc	a0,0x1f
    80005e34:	1e850513          	addi	a0,a0,488 # 80025018 <disk+0x2018>
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	58e080e7          	jalr	1422(ra) # 800023c6 <wakeup>
}
    80005e40:	60a2                	ld	ra,8(sp)
    80005e42:	6402                	ld	s0,0(sp)
    80005e44:	0141                	addi	sp,sp,16
    80005e46:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e48:	00003517          	auipc	a0,0x3
    80005e4c:	aa050513          	addi	a0,a0,-1376 # 800088e8 <sysnames+0x338>
    80005e50:	ffffa097          	auipc	ra,0xffffa
    80005e54:	6f8080e7          	jalr	1784(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005e58:	00003517          	auipc	a0,0x3
    80005e5c:	aa850513          	addi	a0,a0,-1368 # 80008900 <sysnames+0x350>
    80005e60:	ffffa097          	auipc	ra,0xffffa
    80005e64:	6e8080e7          	jalr	1768(ra) # 80000548 <panic>

0000000080005e68 <virtio_disk_init>:
{
    80005e68:	1101                	addi	sp,sp,-32
    80005e6a:	ec06                	sd	ra,24(sp)
    80005e6c:	e822                	sd	s0,16(sp)
    80005e6e:	e426                	sd	s1,8(sp)
    80005e70:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e72:	00003597          	auipc	a1,0x3
    80005e76:	aa658593          	addi	a1,a1,-1370 # 80008918 <sysnames+0x368>
    80005e7a:	0001f517          	auipc	a0,0x1f
    80005e7e:	22e50513          	addi	a0,a0,558 # 800250a8 <disk+0x20a8>
    80005e82:	ffffb097          	auipc	ra,0xffffb
    80005e86:	d48080e7          	jalr	-696(ra) # 80000bca <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e8a:	100017b7          	lui	a5,0x10001
    80005e8e:	4398                	lw	a4,0(a5)
    80005e90:	2701                	sext.w	a4,a4
    80005e92:	747277b7          	lui	a5,0x74727
    80005e96:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e9a:	0ef71163          	bne	a4,a5,80005f7c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e9e:	100017b7          	lui	a5,0x10001
    80005ea2:	43dc                	lw	a5,4(a5)
    80005ea4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ea6:	4705                	li	a4,1
    80005ea8:	0ce79a63          	bne	a5,a4,80005f7c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eac:	100017b7          	lui	a5,0x10001
    80005eb0:	479c                	lw	a5,8(a5)
    80005eb2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005eb4:	4709                	li	a4,2
    80005eb6:	0ce79363          	bne	a5,a4,80005f7c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eba:	100017b7          	lui	a5,0x10001
    80005ebe:	47d8                	lw	a4,12(a5)
    80005ec0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ec2:	554d47b7          	lui	a5,0x554d4
    80005ec6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eca:	0af71963          	bne	a4,a5,80005f7c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ece:	100017b7          	lui	a5,0x10001
    80005ed2:	4705                	li	a4,1
    80005ed4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed6:	470d                	li	a4,3
    80005ed8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eda:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005edc:	c7ffe737          	lui	a4,0xc7ffe
    80005ee0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ee4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ee6:	2701                	sext.w	a4,a4
    80005ee8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eea:	472d                	li	a4,11
    80005eec:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eee:	473d                	li	a4,15
    80005ef0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ef2:	6705                	lui	a4,0x1
    80005ef4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ef6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005efa:	5bdc                	lw	a5,52(a5)
    80005efc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005efe:	c7d9                	beqz	a5,80005f8c <virtio_disk_init+0x124>
  if(max < NUM)
    80005f00:	471d                	li	a4,7
    80005f02:	08f77d63          	bgeu	a4,a5,80005f9c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f06:	100014b7          	lui	s1,0x10001
    80005f0a:	47a1                	li	a5,8
    80005f0c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f0e:	6609                	lui	a2,0x2
    80005f10:	4581                	li	a1,0
    80005f12:	0001d517          	auipc	a0,0x1d
    80005f16:	0ee50513          	addi	a0,a0,238 # 80023000 <disk>
    80005f1a:	ffffb097          	auipc	ra,0xffffb
    80005f1e:	e3c080e7          	jalr	-452(ra) # 80000d56 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f22:	0001d717          	auipc	a4,0x1d
    80005f26:	0de70713          	addi	a4,a4,222 # 80023000 <disk>
    80005f2a:	00c75793          	srli	a5,a4,0xc
    80005f2e:	2781                	sext.w	a5,a5
    80005f30:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f32:	0001f797          	auipc	a5,0x1f
    80005f36:	0ce78793          	addi	a5,a5,206 # 80025000 <disk+0x2000>
    80005f3a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f3c:	0001d717          	auipc	a4,0x1d
    80005f40:	14470713          	addi	a4,a4,324 # 80023080 <disk+0x80>
    80005f44:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f46:	0001e717          	auipc	a4,0x1e
    80005f4a:	0ba70713          	addi	a4,a4,186 # 80024000 <disk+0x1000>
    80005f4e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f50:	4705                	li	a4,1
    80005f52:	00e78c23          	sb	a4,24(a5)
    80005f56:	00e78ca3          	sb	a4,25(a5)
    80005f5a:	00e78d23          	sb	a4,26(a5)
    80005f5e:	00e78da3          	sb	a4,27(a5)
    80005f62:	00e78e23          	sb	a4,28(a5)
    80005f66:	00e78ea3          	sb	a4,29(a5)
    80005f6a:	00e78f23          	sb	a4,30(a5)
    80005f6e:	00e78fa3          	sb	a4,31(a5)
}
    80005f72:	60e2                	ld	ra,24(sp)
    80005f74:	6442                	ld	s0,16(sp)
    80005f76:	64a2                	ld	s1,8(sp)
    80005f78:	6105                	addi	sp,sp,32
    80005f7a:	8082                	ret
    panic("could not find virtio disk");
    80005f7c:	00003517          	auipc	a0,0x3
    80005f80:	9ac50513          	addi	a0,a0,-1620 # 80008928 <sysnames+0x378>
    80005f84:	ffffa097          	auipc	ra,0xffffa
    80005f88:	5c4080e7          	jalr	1476(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f8c:	00003517          	auipc	a0,0x3
    80005f90:	9bc50513          	addi	a0,a0,-1604 # 80008948 <sysnames+0x398>
    80005f94:	ffffa097          	auipc	ra,0xffffa
    80005f98:	5b4080e7          	jalr	1460(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f9c:	00003517          	auipc	a0,0x3
    80005fa0:	9cc50513          	addi	a0,a0,-1588 # 80008968 <sysnames+0x3b8>
    80005fa4:	ffffa097          	auipc	ra,0xffffa
    80005fa8:	5a4080e7          	jalr	1444(ra) # 80000548 <panic>

0000000080005fac <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fac:	7119                	addi	sp,sp,-128
    80005fae:	fc86                	sd	ra,120(sp)
    80005fb0:	f8a2                	sd	s0,112(sp)
    80005fb2:	f4a6                	sd	s1,104(sp)
    80005fb4:	f0ca                	sd	s2,96(sp)
    80005fb6:	ecce                	sd	s3,88(sp)
    80005fb8:	e8d2                	sd	s4,80(sp)
    80005fba:	e4d6                	sd	s5,72(sp)
    80005fbc:	e0da                	sd	s6,64(sp)
    80005fbe:	fc5e                	sd	s7,56(sp)
    80005fc0:	f862                	sd	s8,48(sp)
    80005fc2:	f466                	sd	s9,40(sp)
    80005fc4:	f06a                	sd	s10,32(sp)
    80005fc6:	0100                	addi	s0,sp,128
    80005fc8:	892a                	mv	s2,a0
    80005fca:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fcc:	00c52c83          	lw	s9,12(a0)
    80005fd0:	001c9c9b          	slliw	s9,s9,0x1
    80005fd4:	1c82                	slli	s9,s9,0x20
    80005fd6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fda:	0001f517          	auipc	a0,0x1f
    80005fde:	0ce50513          	addi	a0,a0,206 # 800250a8 <disk+0x20a8>
    80005fe2:	ffffb097          	auipc	ra,0xffffb
    80005fe6:	c78080e7          	jalr	-904(ra) # 80000c5a <acquire>
  for(int i = 0; i < 3; i++){
    80005fea:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fec:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fee:	0001db97          	auipc	s7,0x1d
    80005ff2:	012b8b93          	addi	s7,s7,18 # 80023000 <disk>
    80005ff6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005ff8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005ffa:	8a4e                	mv	s4,s3
    80005ffc:	a051                	j	80006080 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005ffe:	00fb86b3          	add	a3,s7,a5
    80006002:	96da                	add	a3,a3,s6
    80006004:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006008:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000600a:	0207c563          	bltz	a5,80006034 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000600e:	2485                	addiw	s1,s1,1
    80006010:	0711                	addi	a4,a4,4
    80006012:	23548d63          	beq	s1,s5,8000624c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006016:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006018:	0001f697          	auipc	a3,0x1f
    8000601c:	00068693          	mv	a3,a3
    80006020:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006022:	0006c583          	lbu	a1,0(a3) # 80025018 <disk+0x2018>
    80006026:	fde1                	bnez	a1,80005ffe <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006028:	2785                	addiw	a5,a5,1
    8000602a:	0685                	addi	a3,a3,1
    8000602c:	ff879be3          	bne	a5,s8,80006022 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006030:	57fd                	li	a5,-1
    80006032:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006034:	02905a63          	blez	s1,80006068 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006038:	f9042503          	lw	a0,-112(s0)
    8000603c:	00000097          	auipc	ra,0x0
    80006040:	daa080e7          	jalr	-598(ra) # 80005de6 <free_desc>
      for(int j = 0; j < i; j++)
    80006044:	4785                	li	a5,1
    80006046:	0297d163          	bge	a5,s1,80006068 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000604a:	f9442503          	lw	a0,-108(s0)
    8000604e:	00000097          	auipc	ra,0x0
    80006052:	d98080e7          	jalr	-616(ra) # 80005de6 <free_desc>
      for(int j = 0; j < i; j++)
    80006056:	4789                	li	a5,2
    80006058:	0097d863          	bge	a5,s1,80006068 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000605c:	f9842503          	lw	a0,-104(s0)
    80006060:	00000097          	auipc	ra,0x0
    80006064:	d86080e7          	jalr	-634(ra) # 80005de6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006068:	0001f597          	auipc	a1,0x1f
    8000606c:	04058593          	addi	a1,a1,64 # 800250a8 <disk+0x20a8>
    80006070:	0001f517          	auipc	a0,0x1f
    80006074:	fa850513          	addi	a0,a0,-88 # 80025018 <disk+0x2018>
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	1c8080e7          	jalr	456(ra) # 80002240 <sleep>
  for(int i = 0; i < 3; i++){
    80006080:	f9040713          	addi	a4,s0,-112
    80006084:	84ce                	mv	s1,s3
    80006086:	bf41                	j	80006016 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006088:	4785                	li	a5,1
    8000608a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000608e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006092:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006096:	f9042983          	lw	s3,-112(s0)
    8000609a:	00499493          	slli	s1,s3,0x4
    8000609e:	0001fa17          	auipc	s4,0x1f
    800060a2:	f62a0a13          	addi	s4,s4,-158 # 80025000 <disk+0x2000>
    800060a6:	000a3a83          	ld	s5,0(s4)
    800060aa:	9aa6                	add	s5,s5,s1
    800060ac:	f8040513          	addi	a0,s0,-128
    800060b0:	ffffb097          	auipc	ra,0xffffb
    800060b4:	07a080e7          	jalr	122(ra) # 8000112a <kvmpa>
    800060b8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800060bc:	000a3783          	ld	a5,0(s4)
    800060c0:	97a6                	add	a5,a5,s1
    800060c2:	4741                	li	a4,16
    800060c4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060c6:	000a3783          	ld	a5,0(s4)
    800060ca:	97a6                	add	a5,a5,s1
    800060cc:	4705                	li	a4,1
    800060ce:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800060d2:	f9442703          	lw	a4,-108(s0)
    800060d6:	000a3783          	ld	a5,0(s4)
    800060da:	97a6                	add	a5,a5,s1
    800060dc:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060e0:	0712                	slli	a4,a4,0x4
    800060e2:	000a3783          	ld	a5,0(s4)
    800060e6:	97ba                	add	a5,a5,a4
    800060e8:	05890693          	addi	a3,s2,88
    800060ec:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800060ee:	000a3783          	ld	a5,0(s4)
    800060f2:	97ba                	add	a5,a5,a4
    800060f4:	40000693          	li	a3,1024
    800060f8:	c794                	sw	a3,8(a5)
  if(write)
    800060fa:	100d0a63          	beqz	s10,8000620e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060fe:	0001f797          	auipc	a5,0x1f
    80006102:	f027b783          	ld	a5,-254(a5) # 80025000 <disk+0x2000>
    80006106:	97ba                	add	a5,a5,a4
    80006108:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000610c:	0001d517          	auipc	a0,0x1d
    80006110:	ef450513          	addi	a0,a0,-268 # 80023000 <disk>
    80006114:	0001f797          	auipc	a5,0x1f
    80006118:	eec78793          	addi	a5,a5,-276 # 80025000 <disk+0x2000>
    8000611c:	6394                	ld	a3,0(a5)
    8000611e:	96ba                	add	a3,a3,a4
    80006120:	00c6d603          	lhu	a2,12(a3)
    80006124:	00166613          	ori	a2,a2,1
    80006128:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000612c:	f9842683          	lw	a3,-104(s0)
    80006130:	6390                	ld	a2,0(a5)
    80006132:	9732                	add	a4,a4,a2
    80006134:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006138:	20098613          	addi	a2,s3,512
    8000613c:	0612                	slli	a2,a2,0x4
    8000613e:	962a                	add	a2,a2,a0
    80006140:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006144:	00469713          	slli	a4,a3,0x4
    80006148:	6394                	ld	a3,0(a5)
    8000614a:	96ba                	add	a3,a3,a4
    8000614c:	6589                	lui	a1,0x2
    8000614e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006152:	94ae                	add	s1,s1,a1
    80006154:	94aa                	add	s1,s1,a0
    80006156:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006158:	6394                	ld	a3,0(a5)
    8000615a:	96ba                	add	a3,a3,a4
    8000615c:	4585                	li	a1,1
    8000615e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006160:	6394                	ld	a3,0(a5)
    80006162:	96ba                	add	a3,a3,a4
    80006164:	4509                	li	a0,2
    80006166:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000616a:	6394                	ld	a3,0(a5)
    8000616c:	9736                	add	a4,a4,a3
    8000616e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006172:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006176:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000617a:	6794                	ld	a3,8(a5)
    8000617c:	0026d703          	lhu	a4,2(a3)
    80006180:	8b1d                	andi	a4,a4,7
    80006182:	2709                	addiw	a4,a4,2
    80006184:	0706                	slli	a4,a4,0x1
    80006186:	9736                	add	a4,a4,a3
    80006188:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000618c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006190:	6798                	ld	a4,8(a5)
    80006192:	00275783          	lhu	a5,2(a4)
    80006196:	2785                	addiw	a5,a5,1
    80006198:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000619c:	100017b7          	lui	a5,0x10001
    800061a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061a4:	00492703          	lw	a4,4(s2)
    800061a8:	4785                	li	a5,1
    800061aa:	02f71163          	bne	a4,a5,800061cc <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800061ae:	0001f997          	auipc	s3,0x1f
    800061b2:	efa98993          	addi	s3,s3,-262 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800061b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061b8:	85ce                	mv	a1,s3
    800061ba:	854a                	mv	a0,s2
    800061bc:	ffffc097          	auipc	ra,0xffffc
    800061c0:	084080e7          	jalr	132(ra) # 80002240 <sleep>
  while(b->disk == 1) {
    800061c4:	00492783          	lw	a5,4(s2)
    800061c8:	fe9788e3          	beq	a5,s1,800061b8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800061cc:	f9042483          	lw	s1,-112(s0)
    800061d0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800061d4:	00479713          	slli	a4,a5,0x4
    800061d8:	0001d797          	auipc	a5,0x1d
    800061dc:	e2878793          	addi	a5,a5,-472 # 80023000 <disk>
    800061e0:	97ba                	add	a5,a5,a4
    800061e2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061e6:	0001f917          	auipc	s2,0x1f
    800061ea:	e1a90913          	addi	s2,s2,-486 # 80025000 <disk+0x2000>
    free_desc(i);
    800061ee:	8526                	mv	a0,s1
    800061f0:	00000097          	auipc	ra,0x0
    800061f4:	bf6080e7          	jalr	-1034(ra) # 80005de6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061f8:	0492                	slli	s1,s1,0x4
    800061fa:	00093783          	ld	a5,0(s2)
    800061fe:	94be                	add	s1,s1,a5
    80006200:	00c4d783          	lhu	a5,12(s1)
    80006204:	8b85                	andi	a5,a5,1
    80006206:	cf89                	beqz	a5,80006220 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006208:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000620c:	b7cd                	j	800061ee <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000620e:	0001f797          	auipc	a5,0x1f
    80006212:	df27b783          	ld	a5,-526(a5) # 80025000 <disk+0x2000>
    80006216:	97ba                	add	a5,a5,a4
    80006218:	4689                	li	a3,2
    8000621a:	00d79623          	sh	a3,12(a5)
    8000621e:	b5fd                	j	8000610c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006220:	0001f517          	auipc	a0,0x1f
    80006224:	e8850513          	addi	a0,a0,-376 # 800250a8 <disk+0x20a8>
    80006228:	ffffb097          	auipc	ra,0xffffb
    8000622c:	ae6080e7          	jalr	-1306(ra) # 80000d0e <release>
}
    80006230:	70e6                	ld	ra,120(sp)
    80006232:	7446                	ld	s0,112(sp)
    80006234:	74a6                	ld	s1,104(sp)
    80006236:	7906                	ld	s2,96(sp)
    80006238:	69e6                	ld	s3,88(sp)
    8000623a:	6a46                	ld	s4,80(sp)
    8000623c:	6aa6                	ld	s5,72(sp)
    8000623e:	6b06                	ld	s6,64(sp)
    80006240:	7be2                	ld	s7,56(sp)
    80006242:	7c42                	ld	s8,48(sp)
    80006244:	7ca2                	ld	s9,40(sp)
    80006246:	7d02                	ld	s10,32(sp)
    80006248:	6109                	addi	sp,sp,128
    8000624a:	8082                	ret
  if(write)
    8000624c:	e20d1ee3          	bnez	s10,80006088 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006250:	f8042023          	sw	zero,-128(s0)
    80006254:	bd2d                	j	8000608e <virtio_disk_rw+0xe2>

0000000080006256 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006256:	1101                	addi	sp,sp,-32
    80006258:	ec06                	sd	ra,24(sp)
    8000625a:	e822                	sd	s0,16(sp)
    8000625c:	e426                	sd	s1,8(sp)
    8000625e:	e04a                	sd	s2,0(sp)
    80006260:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006262:	0001f517          	auipc	a0,0x1f
    80006266:	e4650513          	addi	a0,a0,-442 # 800250a8 <disk+0x20a8>
    8000626a:	ffffb097          	auipc	ra,0xffffb
    8000626e:	9f0080e7          	jalr	-1552(ra) # 80000c5a <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006272:	0001f717          	auipc	a4,0x1f
    80006276:	d8e70713          	addi	a4,a4,-626 # 80025000 <disk+0x2000>
    8000627a:	02075783          	lhu	a5,32(a4)
    8000627e:	6b18                	ld	a4,16(a4)
    80006280:	00275683          	lhu	a3,2(a4)
    80006284:	8ebd                	xor	a3,a3,a5
    80006286:	8a9d                	andi	a3,a3,7
    80006288:	cab9                	beqz	a3,800062de <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000628a:	0001d917          	auipc	s2,0x1d
    8000628e:	d7690913          	addi	s2,s2,-650 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006292:	0001f497          	auipc	s1,0x1f
    80006296:	d6e48493          	addi	s1,s1,-658 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000629a:	078e                	slli	a5,a5,0x3
    8000629c:	97ba                	add	a5,a5,a4
    8000629e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800062a0:	20078713          	addi	a4,a5,512
    800062a4:	0712                	slli	a4,a4,0x4
    800062a6:	974a                	add	a4,a4,s2
    800062a8:	03074703          	lbu	a4,48(a4)
    800062ac:	ef21                	bnez	a4,80006304 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800062ae:	20078793          	addi	a5,a5,512
    800062b2:	0792                	slli	a5,a5,0x4
    800062b4:	97ca                	add	a5,a5,s2
    800062b6:	7798                	ld	a4,40(a5)
    800062b8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800062bc:	7788                	ld	a0,40(a5)
    800062be:	ffffc097          	auipc	ra,0xffffc
    800062c2:	108080e7          	jalr	264(ra) # 800023c6 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062c6:	0204d783          	lhu	a5,32(s1)
    800062ca:	2785                	addiw	a5,a5,1
    800062cc:	8b9d                	andi	a5,a5,7
    800062ce:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062d2:	6898                	ld	a4,16(s1)
    800062d4:	00275683          	lhu	a3,2(a4)
    800062d8:	8a9d                	andi	a3,a3,7
    800062da:	fcf690e3          	bne	a3,a5,8000629a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062de:	10001737          	lui	a4,0x10001
    800062e2:	533c                	lw	a5,96(a4)
    800062e4:	8b8d                	andi	a5,a5,3
    800062e6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800062e8:	0001f517          	auipc	a0,0x1f
    800062ec:	dc050513          	addi	a0,a0,-576 # 800250a8 <disk+0x20a8>
    800062f0:	ffffb097          	auipc	ra,0xffffb
    800062f4:	a1e080e7          	jalr	-1506(ra) # 80000d0e <release>
}
    800062f8:	60e2                	ld	ra,24(sp)
    800062fa:	6442                	ld	s0,16(sp)
    800062fc:	64a2                	ld	s1,8(sp)
    800062fe:	6902                	ld	s2,0(sp)
    80006300:	6105                	addi	sp,sp,32
    80006302:	8082                	ret
      panic("virtio_disk_intr status");
    80006304:	00002517          	auipc	a0,0x2
    80006308:	68450513          	addi	a0,a0,1668 # 80008988 <sysnames+0x3d8>
    8000630c:	ffffa097          	auipc	ra,0xffffa
    80006310:	23c080e7          	jalr	572(ra) # 80000548 <panic>
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
