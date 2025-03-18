
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b3013103          	ld	sp,-1232(sp) # 80008b30 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000060:	32478793          	addi	a5,a5,804 # 80006380 <timervec>
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
    80000126:	00003097          	auipc	ra,0x3
    8000012a:	a26080e7          	jalr	-1498(ra) # 80002b4c <either_copyin>
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
    800001d2:	d2e080e7          	jalr	-722(ra) # 80001efc <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	6b6080e7          	jalr	1718(ra) # 80002894 <sleep>
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
    8000021a:	00003097          	auipc	ra,0x3
    8000021e:	8dc080e7          	jalr	-1828(ra) # 80002af6 <either_copyout>
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
    800002fc:	00003097          	auipc	ra,0x3
    80000300:	8a6080e7          	jalr	-1882(ra) # 80002ba2 <procdump>
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
    80000454:	5ca080e7          	jalr	1482(ra) # 80002a1a <wakeup>
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
    80000482:	00022797          	auipc	a5,0x22
    80000486:	92e78793          	addi	a5,a5,-1746 # 80021db0 <devsw>
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
    800008ba:	164080e7          	jalr	356(ra) # 80002a1a <wakeup>
    
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
    80000954:	f44080e7          	jalr	-188(ra) # 80002894 <sleep>
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
    80000bf8:	2ec080e7          	jalr	748(ra) # 80001ee0 <mycpu>
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
    80000c2a:	2ba080e7          	jalr	698(ra) # 80001ee0 <mycpu>
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	cf89                	beqz	a5,80000c4a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	2ae080e7          	jalr	686(ra) # 80001ee0 <mycpu>
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
    80000c4e:	296080e7          	jalr	662(ra) # 80001ee0 <mycpu>
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
    80000c8e:	256080e7          	jalr	598(ra) # 80001ee0 <mycpu>
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
    80000cba:	22a080e7          	jalr	554(ra) # 80001ee0 <mycpu>
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
    80000f14:	fc0080e7          	jalr	-64(ra) # 80001ed0 <cpuid>
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
    80000f30:	fa4080e7          	jalr	-92(ra) # 80001ed0 <cpuid>
    80000f34:	85aa                	mv	a1,a0
    80000f36:	00007517          	auipc	a0,0x7
    80000f3a:	18250513          	addi	a0,a0,386 # 800080b8 <digits+0x78>
    80000f3e:	fffff097          	auipc	ra,0xfffff
    80000f42:	654080e7          	jalr	1620(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	0fc080e7          	jalr	252(ra) # 80001042 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f4e:	00002097          	auipc	ra,0x2
    80000f52:	de8080e7          	jalr	-536(ra) # 80002d36 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f56:	00005097          	auipc	ra,0x5
    80000f5a:	46a080e7          	jalr	1130(ra) # 800063c0 <plicinithart>
  }

  scheduler();        
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	646080e7          	jalr	1606(ra) # 800025a4 <scheduler>
    consoleinit();
    80000f66:	fffff097          	auipc	ra,0xfffff
    80000f6a:	4f4080e7          	jalr	1268(ra) # 8000045a <consoleinit>
    statsinit();
    80000f6e:	00006097          	auipc	ra,0x6
    80000f72:	c14080e7          	jalr	-1004(ra) # 80006b82 <statsinit>
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
    80000fba:	2bc080e7          	jalr	700(ra) # 80001272 <kvminit>
    kvminithart();   // turn on paging
    80000fbe:	00000097          	auipc	ra,0x0
    80000fc2:	084080e7          	jalr	132(ra) # 80001042 <kvminithart>
    procinit();      // process table
    80000fc6:	00001097          	auipc	ra,0x1
    80000fca:	e3a080e7          	jalr	-454(ra) # 80001e00 <procinit>
    trapinit();      // trap vectors
    80000fce:	00002097          	auipc	ra,0x2
    80000fd2:	d40080e7          	jalr	-704(ra) # 80002d0e <trapinit>
    trapinithart();  // install kernel trap vector
    80000fd6:	00002097          	auipc	ra,0x2
    80000fda:	d60080e7          	jalr	-672(ra) # 80002d36 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	3cc080e7          	jalr	972(ra) # 800063aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fe6:	00005097          	auipc	ra,0x5
    80000fea:	3da080e7          	jalr	986(ra) # 800063c0 <plicinithart>
    binit();         // buffer cache
    80000fee:	00002097          	auipc	ra,0x2
    80000ff2:	566080e7          	jalr	1382(ra) # 80003554 <binit>
    iinit();         // inode cache
    80000ff6:	00003097          	auipc	ra,0x3
    80000ffa:	bf6080e7          	jalr	-1034(ra) # 80003bec <iinit>
    fileinit();      // file table
    80000ffe:	00004097          	auipc	ra,0x4
    80001002:	b90080e7          	jalr	-1136(ra) # 80004b8e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001006:	00005097          	auipc	ra,0x5
    8000100a:	4c2080e7          	jalr	1218(ra) # 800064c8 <virtio_disk_init>
    userinit();      // first user process
    8000100e:	00001097          	auipc	ra,0x1
    80001012:	260080e7          	jalr	608(ra) # 8000226e <userinit>
    __sync_synchronize();
    80001016:	0ff0000f          	fence
    started = 1;
    8000101a:	4785                	li	a5,1
    8000101c:	00008717          	auipc	a4,0x8
    80001020:	fef72823          	sw	a5,-16(a4) # 8000900c <started>
    80001024:	bf2d                	j	80000f5e <main+0x56>

0000000080001026 <ukvminithard>:
  // the highest virtual address in the kernel.
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
}

// refresh the TLB to refer the page as virtual memory mapping table
void ukvminithard(pagetable_t page) {
    80001026:	1141                	addi	sp,sp,-16
    80001028:	e422                	sd	s0,8(sp)
    8000102a:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(page));
    8000102c:	8131                	srli	a0,a0,0xc
    8000102e:	57fd                	li	a5,-1
    80001030:	17fe                	slli	a5,a5,0x3f
    80001032:	8d5d                	or	a0,a0,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    80001034:	18051073          	csrw	satp,a0
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

0000000080001042 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001042:	1141                	addi	sp,sp,-16
    80001044:	e422                	sd	s0,8(sp)
    80001046:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001048:	00008797          	auipc	a5,0x8
    8000104c:	fc87b783          	ld	a5,-56(a5) # 80009010 <kernel_pagetable>
    80001050:	83b1                	srli	a5,a5,0xc
    80001052:	577d                	li	a4,-1
    80001054:	177e                	slli	a4,a4,0x3f
    80001056:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001058:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000105c:	12000073          	sfence.vma
  sfence_vma();
}
    80001060:	6422                	ld	s0,8(sp)
    80001062:	0141                	addi	sp,sp,16
    80001064:	8082                	ret

0000000080001066 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001066:	7139                	addi	sp,sp,-64
    80001068:	fc06                	sd	ra,56(sp)
    8000106a:	f822                	sd	s0,48(sp)
    8000106c:	f426                	sd	s1,40(sp)
    8000106e:	f04a                	sd	s2,32(sp)
    80001070:	ec4e                	sd	s3,24(sp)
    80001072:	e852                	sd	s4,16(sp)
    80001074:	e456                	sd	s5,8(sp)
    80001076:	e05a                	sd	s6,0(sp)
    80001078:	0080                	addi	s0,sp,64
    8000107a:	84aa                	mv	s1,a0
    8000107c:	89ae                	mv	s3,a1
    8000107e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001080:	57fd                	li	a5,-1
    80001082:	83e9                	srli	a5,a5,0x1a
    80001084:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001086:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001088:	04b7f263          	bgeu	a5,a1,800010cc <walk+0x66>
    panic("walk");
    8000108c:	00007517          	auipc	a0,0x7
    80001090:	04450513          	addi	a0,a0,68 # 800080d0 <digits+0x90>
    80001094:	fffff097          	auipc	ra,0xfffff
    80001098:	4b4080e7          	jalr	1204(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000109c:	060a8663          	beqz	s5,80001108 <walk+0xa2>
    800010a0:	00000097          	auipc	ra,0x0
    800010a4:	a80080e7          	jalr	-1408(ra) # 80000b20 <kalloc>
    800010a8:	84aa                	mv	s1,a0
    800010aa:	c529                	beqz	a0,800010f4 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010ac:	6605                	lui	a2,0x1
    800010ae:	4581                	li	a1,0
    800010b0:	00000097          	auipc	ra,0x0
    800010b4:	ca6080e7          	jalr	-858(ra) # 80000d56 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010b8:	00c4d793          	srli	a5,s1,0xc
    800010bc:	07aa                	slli	a5,a5,0xa
    800010be:	0017e793          	ori	a5,a5,1
    800010c2:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010c6:	3a5d                	addiw	s4,s4,-9
    800010c8:	036a0063          	beq	s4,s6,800010e8 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010cc:	0149d933          	srl	s2,s3,s4
    800010d0:	1ff97913          	andi	s2,s2,511
    800010d4:	090e                	slli	s2,s2,0x3
    800010d6:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010d8:	00093483          	ld	s1,0(s2)
    800010dc:	0014f793          	andi	a5,s1,1
    800010e0:	dfd5                	beqz	a5,8000109c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010e2:	80a9                	srli	s1,s1,0xa
    800010e4:	04b2                	slli	s1,s1,0xc
    800010e6:	b7c5                	j	800010c6 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010e8:	00c9d513          	srli	a0,s3,0xc
    800010ec:	1ff57513          	andi	a0,a0,511
    800010f0:	050e                	slli	a0,a0,0x3
    800010f2:	9526                	add	a0,a0,s1
}
    800010f4:	70e2                	ld	ra,56(sp)
    800010f6:	7442                	ld	s0,48(sp)
    800010f8:	74a2                	ld	s1,40(sp)
    800010fa:	7902                	ld	s2,32(sp)
    800010fc:	69e2                	ld	s3,24(sp)
    800010fe:	6a42                	ld	s4,16(sp)
    80001100:	6aa2                	ld	s5,8(sp)
    80001102:	6b02                	ld	s6,0(sp)
    80001104:	6121                	addi	sp,sp,64
    80001106:	8082                	ret
        return 0;
    80001108:	4501                	li	a0,0
    8000110a:	b7ed                	j	800010f4 <walk+0x8e>

000000008000110c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000110c:	57fd                	li	a5,-1
    8000110e:	83e9                	srli	a5,a5,0x1a
    80001110:	00b7f463          	bgeu	a5,a1,80001118 <walkaddr+0xc>
    return 0;
    80001114:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001116:	8082                	ret
{
    80001118:	1141                	addi	sp,sp,-16
    8000111a:	e406                	sd	ra,8(sp)
    8000111c:	e022                	sd	s0,0(sp)
    8000111e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001120:	4601                	li	a2,0
    80001122:	00000097          	auipc	ra,0x0
    80001126:	f44080e7          	jalr	-188(ra) # 80001066 <walk>
  if(pte == 0)
    8000112a:	c105                	beqz	a0,8000114a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000112c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000112e:	0117f693          	andi	a3,a5,17
    80001132:	4745                	li	a4,17
    return 0;
    80001134:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001136:	00e68663          	beq	a3,a4,80001142 <walkaddr+0x36>
}
    8000113a:	60a2                	ld	ra,8(sp)
    8000113c:	6402                	ld	s0,0(sp)
    8000113e:	0141                	addi	sp,sp,16
    80001140:	8082                	ret
  pa = PTE2PA(*pte);
    80001142:	00a7d513          	srli	a0,a5,0xa
    80001146:	0532                	slli	a0,a0,0xc
  return pa;
    80001148:	bfcd                	j	8000113a <walkaddr+0x2e>
    return 0;
    8000114a:	4501                	li	a0,0
    8000114c:	b7fd                	j	8000113a <walkaddr+0x2e>

000000008000114e <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000114e:	1101                	addi	sp,sp,-32
    80001150:	ec06                	sd	ra,24(sp)
    80001152:	e822                	sd	s0,16(sp)
    80001154:	e426                	sd	s1,8(sp)
    80001156:	1000                	addi	s0,sp,32
    80001158:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    8000115a:	1552                	slli	a0,a0,0x34
    8000115c:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001160:	4601                	li	a2,0
    80001162:	00008517          	auipc	a0,0x8
    80001166:	eae53503          	ld	a0,-338(a0) # 80009010 <kernel_pagetable>
    8000116a:	00000097          	auipc	ra,0x0
    8000116e:	efc080e7          	jalr	-260(ra) # 80001066 <walk>
  if(pte == 0)
    80001172:	cd09                	beqz	a0,8000118c <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001174:	6108                	ld	a0,0(a0)
    80001176:	00157793          	andi	a5,a0,1
    8000117a:	c38d                	beqz	a5,8000119c <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000117c:	8129                	srli	a0,a0,0xa
    8000117e:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001180:	9526                	add	a0,a0,s1
    80001182:	60e2                	ld	ra,24(sp)
    80001184:	6442                	ld	s0,16(sp)
    80001186:	64a2                	ld	s1,8(sp)
    80001188:	6105                	addi	sp,sp,32
    8000118a:	8082                	ret
    panic("kvmpa");
    8000118c:	00007517          	auipc	a0,0x7
    80001190:	f4c50513          	addi	a0,a0,-180 # 800080d8 <digits+0x98>
    80001194:	fffff097          	auipc	ra,0xfffff
    80001198:	3b4080e7          	jalr	948(ra) # 80000548 <panic>
    panic("kvmpa");
    8000119c:	00007517          	auipc	a0,0x7
    800011a0:	f3c50513          	addi	a0,a0,-196 # 800080d8 <digits+0x98>
    800011a4:	fffff097          	auipc	ra,0xfffff
    800011a8:	3a4080e7          	jalr	932(ra) # 80000548 <panic>

00000000800011ac <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011ac:	715d                	addi	sp,sp,-80
    800011ae:	e486                	sd	ra,72(sp)
    800011b0:	e0a2                	sd	s0,64(sp)
    800011b2:	fc26                	sd	s1,56(sp)
    800011b4:	f84a                	sd	s2,48(sp)
    800011b6:	f44e                	sd	s3,40(sp)
    800011b8:	f052                	sd	s4,32(sp)
    800011ba:	ec56                	sd	s5,24(sp)
    800011bc:	e85a                	sd	s6,16(sp)
    800011be:	e45e                	sd	s7,8(sp)
    800011c0:	0880                	addi	s0,sp,80
    800011c2:	8aaa                	mv	s5,a0
    800011c4:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011c6:	777d                	lui	a4,0xfffff
    800011c8:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011cc:	167d                	addi	a2,a2,-1
    800011ce:	00b609b3          	add	s3,a2,a1
    800011d2:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011d6:	893e                	mv	s2,a5
    800011d8:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011dc:	6b85                	lui	s7,0x1
    800011de:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011e2:	4605                	li	a2,1
    800011e4:	85ca                	mv	a1,s2
    800011e6:	8556                	mv	a0,s5
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	e7e080e7          	jalr	-386(ra) # 80001066 <walk>
    800011f0:	c51d                	beqz	a0,8000121e <mappages+0x72>
    if(*pte & PTE_V)
    800011f2:	611c                	ld	a5,0(a0)
    800011f4:	8b85                	andi	a5,a5,1
    800011f6:	ef81                	bnez	a5,8000120e <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011f8:	80b1                	srli	s1,s1,0xc
    800011fa:	04aa                	slli	s1,s1,0xa
    800011fc:	0164e4b3          	or	s1,s1,s6
    80001200:	0014e493          	ori	s1,s1,1
    80001204:	e104                	sd	s1,0(a0)
    if(a == last)
    80001206:	03390863          	beq	s2,s3,80001236 <mappages+0x8a>
    a += PGSIZE;
    8000120a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000120c:	bfc9                	j	800011de <mappages+0x32>
      panic("remap");
    8000120e:	00007517          	auipc	a0,0x7
    80001212:	ed250513          	addi	a0,a0,-302 # 800080e0 <digits+0xa0>
    80001216:	fffff097          	auipc	ra,0xfffff
    8000121a:	332080e7          	jalr	818(ra) # 80000548 <panic>
      return -1;
    8000121e:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001220:	60a6                	ld	ra,72(sp)
    80001222:	6406                	ld	s0,64(sp)
    80001224:	74e2                	ld	s1,56(sp)
    80001226:	7942                	ld	s2,48(sp)
    80001228:	79a2                	ld	s3,40(sp)
    8000122a:	7a02                	ld	s4,32(sp)
    8000122c:	6ae2                	ld	s5,24(sp)
    8000122e:	6b42                	ld	s6,16(sp)
    80001230:	6ba2                	ld	s7,8(sp)
    80001232:	6161                	addi	sp,sp,80
    80001234:	8082                	ret
  return 0;
    80001236:	4501                	li	a0,0
    80001238:	b7e5                	j	80001220 <mappages+0x74>

000000008000123a <kvmmap>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
    80001242:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001244:	86ae                	mv	a3,a1
    80001246:	85aa                	mv	a1,a0
    80001248:	00008517          	auipc	a0,0x8
    8000124c:	dc853503          	ld	a0,-568(a0) # 80009010 <kernel_pagetable>
    80001250:	00000097          	auipc	ra,0x0
    80001254:	f5c080e7          	jalr	-164(ra) # 800011ac <mappages>
    80001258:	e509                	bnez	a0,80001262 <kvmmap+0x28>
}
    8000125a:	60a2                	ld	ra,8(sp)
    8000125c:	6402                	ld	s0,0(sp)
    8000125e:	0141                	addi	sp,sp,16
    80001260:	8082                	ret
    panic("kvmmap");
    80001262:	00007517          	auipc	a0,0x7
    80001266:	e8650513          	addi	a0,a0,-378 # 800080e8 <digits+0xa8>
    8000126a:	fffff097          	auipc	ra,0xfffff
    8000126e:	2de080e7          	jalr	734(ra) # 80000548 <panic>

0000000080001272 <kvminit>:
{
    80001272:	1101                	addi	sp,sp,-32
    80001274:	ec06                	sd	ra,24(sp)
    80001276:	e822                	sd	s0,16(sp)
    80001278:	e426                	sd	s1,8(sp)
    8000127a:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	8a4080e7          	jalr	-1884(ra) # 80000b20 <kalloc>
    80001284:	00008797          	auipc	a5,0x8
    80001288:	d8a7b623          	sd	a0,-628(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000128c:	6605                	lui	a2,0x1
    8000128e:	4581                	li	a1,0
    80001290:	00000097          	auipc	ra,0x0
    80001294:	ac6080e7          	jalr	-1338(ra) # 80000d56 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001298:	4699                	li	a3,6
    8000129a:	6605                	lui	a2,0x1
    8000129c:	100005b7          	lui	a1,0x10000
    800012a0:	10000537          	lui	a0,0x10000
    800012a4:	00000097          	auipc	ra,0x0
    800012a8:	f96080e7          	jalr	-106(ra) # 8000123a <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012ac:	4699                	li	a3,6
    800012ae:	6605                	lui	a2,0x1
    800012b0:	100015b7          	lui	a1,0x10001
    800012b4:	10001537          	lui	a0,0x10001
    800012b8:	00000097          	auipc	ra,0x0
    800012bc:	f82080e7          	jalr	-126(ra) # 8000123a <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012c0:	4699                	li	a3,6
    800012c2:	6641                	lui	a2,0x10
    800012c4:	020005b7          	lui	a1,0x2000
    800012c8:	02000537          	lui	a0,0x2000
    800012cc:	00000097          	auipc	ra,0x0
    800012d0:	f6e080e7          	jalr	-146(ra) # 8000123a <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012d4:	4699                	li	a3,6
    800012d6:	00400637          	lui	a2,0x400
    800012da:	0c0005b7          	lui	a1,0xc000
    800012de:	0c000537          	lui	a0,0xc000
    800012e2:	00000097          	auipc	ra,0x0
    800012e6:	f58080e7          	jalr	-168(ra) # 8000123a <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012ea:	00007497          	auipc	s1,0x7
    800012ee:	d1648493          	addi	s1,s1,-746 # 80008000 <etext>
    800012f2:	46a9                	li	a3,10
    800012f4:	80007617          	auipc	a2,0x80007
    800012f8:	d0c60613          	addi	a2,a2,-756 # 8000 <_entry-0x7fff8000>
    800012fc:	4585                	li	a1,1
    800012fe:	05fe                	slli	a1,a1,0x1f
    80001300:	852e                	mv	a0,a1
    80001302:	00000097          	auipc	ra,0x0
    80001306:	f38080e7          	jalr	-200(ra) # 8000123a <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000130a:	4699                	li	a3,6
    8000130c:	4645                	li	a2,17
    8000130e:	066e                	slli	a2,a2,0x1b
    80001310:	8e05                	sub	a2,a2,s1
    80001312:	85a6                	mv	a1,s1
    80001314:	8526                	mv	a0,s1
    80001316:	00000097          	auipc	ra,0x0
    8000131a:	f24080e7          	jalr	-220(ra) # 8000123a <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000131e:	46a9                	li	a3,10
    80001320:	6605                	lui	a2,0x1
    80001322:	00006597          	auipc	a1,0x6
    80001326:	cde58593          	addi	a1,a1,-802 # 80007000 <_trampoline>
    8000132a:	04000537          	lui	a0,0x4000
    8000132e:	157d                	addi	a0,a0,-1
    80001330:	0532                	slli	a0,a0,0xc
    80001332:	00000097          	auipc	ra,0x0
    80001336:	f08080e7          	jalr	-248(ra) # 8000123a <kvmmap>
}
    8000133a:	60e2                	ld	ra,24(sp)
    8000133c:	6442                	ld	s0,16(sp)
    8000133e:	64a2                	ld	s1,8(sp)
    80001340:	6105                	addi	sp,sp,32
    80001342:	8082                	ret

0000000080001344 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001344:	715d                	addi	sp,sp,-80
    80001346:	e486                	sd	ra,72(sp)
    80001348:	e0a2                	sd	s0,64(sp)
    8000134a:	fc26                	sd	s1,56(sp)
    8000134c:	f84a                	sd	s2,48(sp)
    8000134e:	f44e                	sd	s3,40(sp)
    80001350:	f052                	sd	s4,32(sp)
    80001352:	ec56                	sd	s5,24(sp)
    80001354:	e85a                	sd	s6,16(sp)
    80001356:	e45e                	sd	s7,8(sp)
    80001358:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000135a:	03459793          	slli	a5,a1,0x34
    8000135e:	e795                	bnez	a5,8000138a <uvmunmap+0x46>
    80001360:	8a2a                	mv	s4,a0
    80001362:	892e                	mv	s2,a1
    80001364:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001366:	0632                	slli	a2,a2,0xc
    80001368:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000136c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000136e:	6b05                	lui	s6,0x1
    80001370:	0735e863          	bltu	a1,s3,800013e0 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001374:	60a6                	ld	ra,72(sp)
    80001376:	6406                	ld	s0,64(sp)
    80001378:	74e2                	ld	s1,56(sp)
    8000137a:	7942                	ld	s2,48(sp)
    8000137c:	79a2                	ld	s3,40(sp)
    8000137e:	7a02                	ld	s4,32(sp)
    80001380:	6ae2                	ld	s5,24(sp)
    80001382:	6b42                	ld	s6,16(sp)
    80001384:	6ba2                	ld	s7,8(sp)
    80001386:	6161                	addi	sp,sp,80
    80001388:	8082                	ret
    panic("uvmunmap: not aligned");
    8000138a:	00007517          	auipc	a0,0x7
    8000138e:	d6650513          	addi	a0,a0,-666 # 800080f0 <digits+0xb0>
    80001392:	fffff097          	auipc	ra,0xfffff
    80001396:	1b6080e7          	jalr	438(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    8000139a:	00007517          	auipc	a0,0x7
    8000139e:	d6e50513          	addi	a0,a0,-658 # 80008108 <digits+0xc8>
    800013a2:	fffff097          	auipc	ra,0xfffff
    800013a6:	1a6080e7          	jalr	422(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    800013aa:	00007517          	auipc	a0,0x7
    800013ae:	d6e50513          	addi	a0,a0,-658 # 80008118 <digits+0xd8>
    800013b2:	fffff097          	auipc	ra,0xfffff
    800013b6:	196080e7          	jalr	406(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    800013ba:	00007517          	auipc	a0,0x7
    800013be:	d7650513          	addi	a0,a0,-650 # 80008130 <digits+0xf0>
    800013c2:	fffff097          	auipc	ra,0xfffff
    800013c6:	186080e7          	jalr	390(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800013ca:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013cc:	0532                	slli	a0,a0,0xc
    800013ce:	fffff097          	auipc	ra,0xfffff
    800013d2:	656080e7          	jalr	1622(ra) # 80000a24 <kfree>
    *pte = 0;
    800013d6:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013da:	995a                	add	s2,s2,s6
    800013dc:	f9397ce3          	bgeu	s2,s3,80001374 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013e0:	4601                	li	a2,0
    800013e2:	85ca                	mv	a1,s2
    800013e4:	8552                	mv	a0,s4
    800013e6:	00000097          	auipc	ra,0x0
    800013ea:	c80080e7          	jalr	-896(ra) # 80001066 <walk>
    800013ee:	84aa                	mv	s1,a0
    800013f0:	d54d                	beqz	a0,8000139a <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013f2:	6108                	ld	a0,0(a0)
    800013f4:	00157793          	andi	a5,a0,1
    800013f8:	dbcd                	beqz	a5,800013aa <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013fa:	3ff57793          	andi	a5,a0,1023
    800013fe:	fb778ee3          	beq	a5,s7,800013ba <uvmunmap+0x76>
    if(do_free){
    80001402:	fc0a8ae3          	beqz	s5,800013d6 <uvmunmap+0x92>
    80001406:	b7d1                	j	800013ca <uvmunmap+0x86>

0000000080001408 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001408:	1101                	addi	sp,sp,-32
    8000140a:	ec06                	sd	ra,24(sp)
    8000140c:	e822                	sd	s0,16(sp)
    8000140e:	e426                	sd	s1,8(sp)
    80001410:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001412:	fffff097          	auipc	ra,0xfffff
    80001416:	70e080e7          	jalr	1806(ra) # 80000b20 <kalloc>
    8000141a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000141c:	c519                	beqz	a0,8000142a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000141e:	6605                	lui	a2,0x1
    80001420:	4581                	li	a1,0
    80001422:	00000097          	auipc	ra,0x0
    80001426:	934080e7          	jalr	-1740(ra) # 80000d56 <memset>
  return pagetable;
}
    8000142a:	8526                	mv	a0,s1
    8000142c:	60e2                	ld	ra,24(sp)
    8000142e:	6442                	ld	s0,16(sp)
    80001430:	64a2                	ld	s1,8(sp)
    80001432:	6105                	addi	sp,sp,32
    80001434:	8082                	ret

0000000080001436 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001436:	7179                	addi	sp,sp,-48
    80001438:	f406                	sd	ra,40(sp)
    8000143a:	f022                	sd	s0,32(sp)
    8000143c:	ec26                	sd	s1,24(sp)
    8000143e:	e84a                	sd	s2,16(sp)
    80001440:	e44e                	sd	s3,8(sp)
    80001442:	e052                	sd	s4,0(sp)
    80001444:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001446:	6785                	lui	a5,0x1
    80001448:	04f67863          	bgeu	a2,a5,80001498 <uvminit+0x62>
    8000144c:	8a2a                	mv	s4,a0
    8000144e:	89ae                	mv	s3,a1
    80001450:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001452:	fffff097          	auipc	ra,0xfffff
    80001456:	6ce080e7          	jalr	1742(ra) # 80000b20 <kalloc>
    8000145a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000145c:	6605                	lui	a2,0x1
    8000145e:	4581                	li	a1,0
    80001460:	00000097          	auipc	ra,0x0
    80001464:	8f6080e7          	jalr	-1802(ra) # 80000d56 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001468:	4779                	li	a4,30
    8000146a:	86ca                	mv	a3,s2
    8000146c:	6605                	lui	a2,0x1
    8000146e:	4581                	li	a1,0
    80001470:	8552                	mv	a0,s4
    80001472:	00000097          	auipc	ra,0x0
    80001476:	d3a080e7          	jalr	-710(ra) # 800011ac <mappages>
  memmove(mem, src, sz);
    8000147a:	8626                	mv	a2,s1
    8000147c:	85ce                	mv	a1,s3
    8000147e:	854a                	mv	a0,s2
    80001480:	00000097          	auipc	ra,0x0
    80001484:	936080e7          	jalr	-1738(ra) # 80000db6 <memmove>
}
    80001488:	70a2                	ld	ra,40(sp)
    8000148a:	7402                	ld	s0,32(sp)
    8000148c:	64e2                	ld	s1,24(sp)
    8000148e:	6942                	ld	s2,16(sp)
    80001490:	69a2                	ld	s3,8(sp)
    80001492:	6a02                	ld	s4,0(sp)
    80001494:	6145                	addi	sp,sp,48
    80001496:	8082                	ret
    panic("inituvm: more than a page");
    80001498:	00007517          	auipc	a0,0x7
    8000149c:	cb050513          	addi	a0,a0,-848 # 80008148 <digits+0x108>
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	0a8080e7          	jalr	168(ra) # 80000548 <panic>

00000000800014a8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014a8:	1101                	addi	sp,sp,-32
    800014aa:	ec06                	sd	ra,24(sp)
    800014ac:	e822                	sd	s0,16(sp)
    800014ae:	e426                	sd	s1,8(sp)
    800014b0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014b2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014b4:	00b67d63          	bgeu	a2,a1,800014ce <uvmdealloc+0x26>
    800014b8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014ba:	6785                	lui	a5,0x1
    800014bc:	17fd                	addi	a5,a5,-1
    800014be:	00f60733          	add	a4,a2,a5
    800014c2:	767d                	lui	a2,0xfffff
    800014c4:	8f71                	and	a4,a4,a2
    800014c6:	97ae                	add	a5,a5,a1
    800014c8:	8ff1                	and	a5,a5,a2
    800014ca:	00f76863          	bltu	a4,a5,800014da <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014ce:	8526                	mv	a0,s1
    800014d0:	60e2                	ld	ra,24(sp)
    800014d2:	6442                	ld	s0,16(sp)
    800014d4:	64a2                	ld	s1,8(sp)
    800014d6:	6105                	addi	sp,sp,32
    800014d8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014da:	8f99                	sub	a5,a5,a4
    800014dc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014de:	4685                	li	a3,1
    800014e0:	0007861b          	sext.w	a2,a5
    800014e4:	85ba                	mv	a1,a4
    800014e6:	00000097          	auipc	ra,0x0
    800014ea:	e5e080e7          	jalr	-418(ra) # 80001344 <uvmunmap>
    800014ee:	b7c5                	j	800014ce <uvmdealloc+0x26>

00000000800014f0 <uvmalloc>:
  if(newsz < oldsz)
    800014f0:	0ab66163          	bltu	a2,a1,80001592 <uvmalloc+0xa2>
{
    800014f4:	7139                	addi	sp,sp,-64
    800014f6:	fc06                	sd	ra,56(sp)
    800014f8:	f822                	sd	s0,48(sp)
    800014fa:	f426                	sd	s1,40(sp)
    800014fc:	f04a                	sd	s2,32(sp)
    800014fe:	ec4e                	sd	s3,24(sp)
    80001500:	e852                	sd	s4,16(sp)
    80001502:	e456                	sd	s5,8(sp)
    80001504:	0080                	addi	s0,sp,64
    80001506:	8aaa                	mv	s5,a0
    80001508:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000150a:	6985                	lui	s3,0x1
    8000150c:	19fd                	addi	s3,s3,-1
    8000150e:	95ce                	add	a1,a1,s3
    80001510:	79fd                	lui	s3,0xfffff
    80001512:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001516:	08c9f063          	bgeu	s3,a2,80001596 <uvmalloc+0xa6>
    8000151a:	894e                	mv	s2,s3
    mem = kalloc();
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	604080e7          	jalr	1540(ra) # 80000b20 <kalloc>
    80001524:	84aa                	mv	s1,a0
    if(mem == 0){
    80001526:	c51d                	beqz	a0,80001554 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001528:	6605                	lui	a2,0x1
    8000152a:	4581                	li	a1,0
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	82a080e7          	jalr	-2006(ra) # 80000d56 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001534:	4779                	li	a4,30
    80001536:	86a6                	mv	a3,s1
    80001538:	6605                	lui	a2,0x1
    8000153a:	85ca                	mv	a1,s2
    8000153c:	8556                	mv	a0,s5
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	c6e080e7          	jalr	-914(ra) # 800011ac <mappages>
    80001546:	e905                	bnez	a0,80001576 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001548:	6785                	lui	a5,0x1
    8000154a:	993e                	add	s2,s2,a5
    8000154c:	fd4968e3          	bltu	s2,s4,8000151c <uvmalloc+0x2c>
  return newsz;
    80001550:	8552                	mv	a0,s4
    80001552:	a809                	j	80001564 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001554:	864e                	mv	a2,s3
    80001556:	85ca                	mv	a1,s2
    80001558:	8556                	mv	a0,s5
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	f4e080e7          	jalr	-178(ra) # 800014a8 <uvmdealloc>
      return 0;
    80001562:	4501                	li	a0,0
}
    80001564:	70e2                	ld	ra,56(sp)
    80001566:	7442                	ld	s0,48(sp)
    80001568:	74a2                	ld	s1,40(sp)
    8000156a:	7902                	ld	s2,32(sp)
    8000156c:	69e2                	ld	s3,24(sp)
    8000156e:	6a42                	ld	s4,16(sp)
    80001570:	6aa2                	ld	s5,8(sp)
    80001572:	6121                	addi	sp,sp,64
    80001574:	8082                	ret
      kfree(mem);
    80001576:	8526                	mv	a0,s1
    80001578:	fffff097          	auipc	ra,0xfffff
    8000157c:	4ac080e7          	jalr	1196(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001580:	864e                	mv	a2,s3
    80001582:	85ca                	mv	a1,s2
    80001584:	8556                	mv	a0,s5
    80001586:	00000097          	auipc	ra,0x0
    8000158a:	f22080e7          	jalr	-222(ra) # 800014a8 <uvmdealloc>
      return 0;
    8000158e:	4501                	li	a0,0
    80001590:	bfd1                	j	80001564 <uvmalloc+0x74>
    return oldsz;
    80001592:	852e                	mv	a0,a1
}
    80001594:	8082                	ret
  return newsz;
    80001596:	8532                	mv	a0,a2
    80001598:	b7f1                	j	80001564 <uvmalloc+0x74>

000000008000159a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000159a:	7179                	addi	sp,sp,-48
    8000159c:	f406                	sd	ra,40(sp)
    8000159e:	f022                	sd	s0,32(sp)
    800015a0:	ec26                	sd	s1,24(sp)
    800015a2:	e84a                	sd	s2,16(sp)
    800015a4:	e44e                	sd	s3,8(sp)
    800015a6:	e052                	sd	s4,0(sp)
    800015a8:	1800                	addi	s0,sp,48
    800015aa:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015ac:	84aa                	mv	s1,a0
    800015ae:	6905                	lui	s2,0x1
    800015b0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015b2:	4985                	li	s3,1
    800015b4:	a821                	j	800015cc <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015b6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015b8:	0532                	slli	a0,a0,0xc
    800015ba:	00000097          	auipc	ra,0x0
    800015be:	fe0080e7          	jalr	-32(ra) # 8000159a <freewalk>
      pagetable[i] = 0;
    800015c2:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015c6:	04a1                	addi	s1,s1,8
    800015c8:	03248163          	beq	s1,s2,800015ea <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015cc:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ce:	00f57793          	andi	a5,a0,15
    800015d2:	ff3782e3          	beq	a5,s3,800015b6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015d6:	8905                	andi	a0,a0,1
    800015d8:	d57d                	beqz	a0,800015c6 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015da:	00007517          	auipc	a0,0x7
    800015de:	b8e50513          	addi	a0,a0,-1138 # 80008168 <digits+0x128>
    800015e2:	fffff097          	auipc	ra,0xfffff
    800015e6:	f66080e7          	jalr	-154(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015ea:	8552                	mv	a0,s4
    800015ec:	fffff097          	auipc	ra,0xfffff
    800015f0:	438080e7          	jalr	1080(ra) # 80000a24 <kfree>
}
    800015f4:	70a2                	ld	ra,40(sp)
    800015f6:	7402                	ld	s0,32(sp)
    800015f8:	64e2                	ld	s1,24(sp)
    800015fa:	6942                	ld	s2,16(sp)
    800015fc:	69a2                	ld	s3,8(sp)
    800015fe:	6a02                	ld	s4,0(sp)
    80001600:	6145                	addi	sp,sp,48
    80001602:	8082                	ret

0000000080001604 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001604:	1101                	addi	sp,sp,-32
    80001606:	ec06                	sd	ra,24(sp)
    80001608:	e822                	sd	s0,16(sp)
    8000160a:	e426                	sd	s1,8(sp)
    8000160c:	1000                	addi	s0,sp,32
    8000160e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001610:	e999                	bnez	a1,80001626 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001612:	8526                	mv	a0,s1
    80001614:	00000097          	auipc	ra,0x0
    80001618:	f86080e7          	jalr	-122(ra) # 8000159a <freewalk>
}
    8000161c:	60e2                	ld	ra,24(sp)
    8000161e:	6442                	ld	s0,16(sp)
    80001620:	64a2                	ld	s1,8(sp)
    80001622:	6105                	addi	sp,sp,32
    80001624:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001626:	6605                	lui	a2,0x1
    80001628:	167d                	addi	a2,a2,-1
    8000162a:	962e                	add	a2,a2,a1
    8000162c:	4685                	li	a3,1
    8000162e:	8231                	srli	a2,a2,0xc
    80001630:	4581                	li	a1,0
    80001632:	00000097          	auipc	ra,0x0
    80001636:	d12080e7          	jalr	-750(ra) # 80001344 <uvmunmap>
    8000163a:	bfe1                	j	80001612 <uvmfree+0xe>

000000008000163c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000163c:	c679                	beqz	a2,8000170a <uvmcopy+0xce>
{
    8000163e:	715d                	addi	sp,sp,-80
    80001640:	e486                	sd	ra,72(sp)
    80001642:	e0a2                	sd	s0,64(sp)
    80001644:	fc26                	sd	s1,56(sp)
    80001646:	f84a                	sd	s2,48(sp)
    80001648:	f44e                	sd	s3,40(sp)
    8000164a:	f052                	sd	s4,32(sp)
    8000164c:	ec56                	sd	s5,24(sp)
    8000164e:	e85a                	sd	s6,16(sp)
    80001650:	e45e                	sd	s7,8(sp)
    80001652:	0880                	addi	s0,sp,80
    80001654:	8b2a                	mv	s6,a0
    80001656:	8aae                	mv	s5,a1
    80001658:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000165a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000165c:	4601                	li	a2,0
    8000165e:	85ce                	mv	a1,s3
    80001660:	855a                	mv	a0,s6
    80001662:	00000097          	auipc	ra,0x0
    80001666:	a04080e7          	jalr	-1532(ra) # 80001066 <walk>
    8000166a:	c531                	beqz	a0,800016b6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000166c:	6118                	ld	a4,0(a0)
    8000166e:	00177793          	andi	a5,a4,1
    80001672:	cbb1                	beqz	a5,800016c6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001674:	00a75593          	srli	a1,a4,0xa
    80001678:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000167c:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001680:	fffff097          	auipc	ra,0xfffff
    80001684:	4a0080e7          	jalr	1184(ra) # 80000b20 <kalloc>
    80001688:	892a                	mv	s2,a0
    8000168a:	c939                	beqz	a0,800016e0 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000168c:	6605                	lui	a2,0x1
    8000168e:	85de                	mv	a1,s7
    80001690:	fffff097          	auipc	ra,0xfffff
    80001694:	726080e7          	jalr	1830(ra) # 80000db6 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001698:	8726                	mv	a4,s1
    8000169a:	86ca                	mv	a3,s2
    8000169c:	6605                	lui	a2,0x1
    8000169e:	85ce                	mv	a1,s3
    800016a0:	8556                	mv	a0,s5
    800016a2:	00000097          	auipc	ra,0x0
    800016a6:	b0a080e7          	jalr	-1270(ra) # 800011ac <mappages>
    800016aa:	e515                	bnez	a0,800016d6 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016ac:	6785                	lui	a5,0x1
    800016ae:	99be                	add	s3,s3,a5
    800016b0:	fb49e6e3          	bltu	s3,s4,8000165c <uvmcopy+0x20>
    800016b4:	a081                	j	800016f4 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016b6:	00007517          	auipc	a0,0x7
    800016ba:	ac250513          	addi	a0,a0,-1342 # 80008178 <digits+0x138>
    800016be:	fffff097          	auipc	ra,0xfffff
    800016c2:	e8a080e7          	jalr	-374(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800016c6:	00007517          	auipc	a0,0x7
    800016ca:	ad250513          	addi	a0,a0,-1326 # 80008198 <digits+0x158>
    800016ce:	fffff097          	auipc	ra,0xfffff
    800016d2:	e7a080e7          	jalr	-390(ra) # 80000548 <panic>
      kfree(mem);
    800016d6:	854a                	mv	a0,s2
    800016d8:	fffff097          	auipc	ra,0xfffff
    800016dc:	34c080e7          	jalr	844(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016e0:	4685                	li	a3,1
    800016e2:	00c9d613          	srli	a2,s3,0xc
    800016e6:	4581                	li	a1,0
    800016e8:	8556                	mv	a0,s5
    800016ea:	00000097          	auipc	ra,0x0
    800016ee:	c5a080e7          	jalr	-934(ra) # 80001344 <uvmunmap>
  return -1;
    800016f2:	557d                	li	a0,-1
}
    800016f4:	60a6                	ld	ra,72(sp)
    800016f6:	6406                	ld	s0,64(sp)
    800016f8:	74e2                	ld	s1,56(sp)
    800016fa:	7942                	ld	s2,48(sp)
    800016fc:	79a2                	ld	s3,40(sp)
    800016fe:	7a02                	ld	s4,32(sp)
    80001700:	6ae2                	ld	s5,24(sp)
    80001702:	6b42                	ld	s6,16(sp)
    80001704:	6ba2                	ld	s7,8(sp)
    80001706:	6161                	addi	sp,sp,80
    80001708:	8082                	ret
  return 0;
    8000170a:	4501                	li	a0,0
}
    8000170c:	8082                	ret

000000008000170e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000170e:	1141                	addi	sp,sp,-16
    80001710:	e406                	sd	ra,8(sp)
    80001712:	e022                	sd	s0,0(sp)
    80001714:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001716:	4601                	li	a2,0
    80001718:	00000097          	auipc	ra,0x0
    8000171c:	94e080e7          	jalr	-1714(ra) # 80001066 <walk>
  if(pte == 0)
    80001720:	c901                	beqz	a0,80001730 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001722:	611c                	ld	a5,0(a0)
    80001724:	9bbd                	andi	a5,a5,-17
    80001726:	e11c                	sd	a5,0(a0)
}
    80001728:	60a2                	ld	ra,8(sp)
    8000172a:	6402                	ld	s0,0(sp)
    8000172c:	0141                	addi	sp,sp,16
    8000172e:	8082                	ret
    panic("uvmclear");
    80001730:	00007517          	auipc	a0,0x7
    80001734:	a8850513          	addi	a0,a0,-1400 # 800081b8 <digits+0x178>
    80001738:	fffff097          	auipc	ra,0xfffff
    8000173c:	e10080e7          	jalr	-496(ra) # 80000548 <panic>

0000000080001740 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001740:	c6bd                	beqz	a3,800017ae <copyout+0x6e>
{
    80001742:	715d                	addi	sp,sp,-80
    80001744:	e486                	sd	ra,72(sp)
    80001746:	e0a2                	sd	s0,64(sp)
    80001748:	fc26                	sd	s1,56(sp)
    8000174a:	f84a                	sd	s2,48(sp)
    8000174c:	f44e                	sd	s3,40(sp)
    8000174e:	f052                	sd	s4,32(sp)
    80001750:	ec56                	sd	s5,24(sp)
    80001752:	e85a                	sd	s6,16(sp)
    80001754:	e45e                	sd	s7,8(sp)
    80001756:	e062                	sd	s8,0(sp)
    80001758:	0880                	addi	s0,sp,80
    8000175a:	8b2a                	mv	s6,a0
    8000175c:	8c2e                	mv	s8,a1
    8000175e:	8a32                	mv	s4,a2
    80001760:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001762:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001764:	6a85                	lui	s5,0x1
    80001766:	a015                	j	8000178a <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001768:	9562                	add	a0,a0,s8
    8000176a:	0004861b          	sext.w	a2,s1
    8000176e:	85d2                	mv	a1,s4
    80001770:	41250533          	sub	a0,a0,s2
    80001774:	fffff097          	auipc	ra,0xfffff
    80001778:	642080e7          	jalr	1602(ra) # 80000db6 <memmove>

    len -= n;
    8000177c:	409989b3          	sub	s3,s3,s1
    src += n;
    80001780:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001782:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001786:	02098263          	beqz	s3,800017aa <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000178a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000178e:	85ca                	mv	a1,s2
    80001790:	855a                	mv	a0,s6
    80001792:	00000097          	auipc	ra,0x0
    80001796:	97a080e7          	jalr	-1670(ra) # 8000110c <walkaddr>
    if(pa0 == 0)
    8000179a:	cd01                	beqz	a0,800017b2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000179c:	418904b3          	sub	s1,s2,s8
    800017a0:	94d6                	add	s1,s1,s5
    if(n > len)
    800017a2:	fc99f3e3          	bgeu	s3,s1,80001768 <copyout+0x28>
    800017a6:	84ce                	mv	s1,s3
    800017a8:	b7c1                	j	80001768 <copyout+0x28>
  }
  return 0;
    800017aa:	4501                	li	a0,0
    800017ac:	a021                	j	800017b4 <copyout+0x74>
    800017ae:	4501                	li	a0,0
}
    800017b0:	8082                	ret
      return -1;
    800017b2:	557d                	li	a0,-1
}
    800017b4:	60a6                	ld	ra,72(sp)
    800017b6:	6406                	ld	s0,64(sp)
    800017b8:	74e2                	ld	s1,56(sp)
    800017ba:	7942                	ld	s2,48(sp)
    800017bc:	79a2                	ld	s3,40(sp)
    800017be:	7a02                	ld	s4,32(sp)
    800017c0:	6ae2                	ld	s5,24(sp)
    800017c2:	6b42                	ld	s6,16(sp)
    800017c4:	6ba2                	ld	s7,8(sp)
    800017c6:	6c02                	ld	s8,0(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret

00000000800017cc <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017cc:	c6bd                	beqz	a3,8000183a <copyin+0x6e>
{
    800017ce:	715d                	addi	sp,sp,-80
    800017d0:	e486                	sd	ra,72(sp)
    800017d2:	e0a2                	sd	s0,64(sp)
    800017d4:	fc26                	sd	s1,56(sp)
    800017d6:	f84a                	sd	s2,48(sp)
    800017d8:	f44e                	sd	s3,40(sp)
    800017da:	f052                	sd	s4,32(sp)
    800017dc:	ec56                	sd	s5,24(sp)
    800017de:	e85a                	sd	s6,16(sp)
    800017e0:	e45e                	sd	s7,8(sp)
    800017e2:	e062                	sd	s8,0(sp)
    800017e4:	0880                	addi	s0,sp,80
    800017e6:	8b2a                	mv	s6,a0
    800017e8:	8a2e                	mv	s4,a1
    800017ea:	8c32                	mv	s8,a2
    800017ec:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017ee:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017f0:	6a85                	lui	s5,0x1
    800017f2:	a015                	j	80001816 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017f4:	9562                	add	a0,a0,s8
    800017f6:	0004861b          	sext.w	a2,s1
    800017fa:	412505b3          	sub	a1,a0,s2
    800017fe:	8552                	mv	a0,s4
    80001800:	fffff097          	auipc	ra,0xfffff
    80001804:	5b6080e7          	jalr	1462(ra) # 80000db6 <memmove>

    len -= n;
    80001808:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000180c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000180e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001812:	02098263          	beqz	s3,80001836 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001816:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000181a:	85ca                	mv	a1,s2
    8000181c:	855a                	mv	a0,s6
    8000181e:	00000097          	auipc	ra,0x0
    80001822:	8ee080e7          	jalr	-1810(ra) # 8000110c <walkaddr>
    if(pa0 == 0)
    80001826:	cd01                	beqz	a0,8000183e <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001828:	418904b3          	sub	s1,s2,s8
    8000182c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000182e:	fc99f3e3          	bgeu	s3,s1,800017f4 <copyin+0x28>
    80001832:	84ce                	mv	s1,s3
    80001834:	b7c1                	j	800017f4 <copyin+0x28>
  }
  return 0;
    80001836:	4501                	li	a0,0
    80001838:	a021                	j	80001840 <copyin+0x74>
    8000183a:	4501                	li	a0,0
}
    8000183c:	8082                	ret
      return -1;
    8000183e:	557d                	li	a0,-1
}
    80001840:	60a6                	ld	ra,72(sp)
    80001842:	6406                	ld	s0,64(sp)
    80001844:	74e2                	ld	s1,56(sp)
    80001846:	7942                	ld	s2,48(sp)
    80001848:	79a2                	ld	s3,40(sp)
    8000184a:	7a02                	ld	s4,32(sp)
    8000184c:	6ae2                	ld	s5,24(sp)
    8000184e:	6b42                	ld	s6,16(sp)
    80001850:	6ba2                	ld	s7,8(sp)
    80001852:	6c02                	ld	s8,0(sp)
    80001854:	6161                	addi	sp,sp,80
    80001856:	8082                	ret

0000000080001858 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001858:	c6c5                	beqz	a3,80001900 <copyinstr+0xa8>
{
    8000185a:	715d                	addi	sp,sp,-80
    8000185c:	e486                	sd	ra,72(sp)
    8000185e:	e0a2                	sd	s0,64(sp)
    80001860:	fc26                	sd	s1,56(sp)
    80001862:	f84a                	sd	s2,48(sp)
    80001864:	f44e                	sd	s3,40(sp)
    80001866:	f052                	sd	s4,32(sp)
    80001868:	ec56                	sd	s5,24(sp)
    8000186a:	e85a                	sd	s6,16(sp)
    8000186c:	e45e                	sd	s7,8(sp)
    8000186e:	0880                	addi	s0,sp,80
    80001870:	8a2a                	mv	s4,a0
    80001872:	8b2e                	mv	s6,a1
    80001874:	8bb2                	mv	s7,a2
    80001876:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001878:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000187a:	6985                	lui	s3,0x1
    8000187c:	a035                	j	800018a8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000187e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001882:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001884:	0017b793          	seqz	a5,a5
    80001888:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000188c:	60a6                	ld	ra,72(sp)
    8000188e:	6406                	ld	s0,64(sp)
    80001890:	74e2                	ld	s1,56(sp)
    80001892:	7942                	ld	s2,48(sp)
    80001894:	79a2                	ld	s3,40(sp)
    80001896:	7a02                	ld	s4,32(sp)
    80001898:	6ae2                	ld	s5,24(sp)
    8000189a:	6b42                	ld	s6,16(sp)
    8000189c:	6ba2                	ld	s7,8(sp)
    8000189e:	6161                	addi	sp,sp,80
    800018a0:	8082                	ret
    srcva = va0 + PGSIZE;
    800018a2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018a6:	c8a9                	beqz	s1,800018f8 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018a8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018ac:	85ca                	mv	a1,s2
    800018ae:	8552                	mv	a0,s4
    800018b0:	00000097          	auipc	ra,0x0
    800018b4:	85c080e7          	jalr	-1956(ra) # 8000110c <walkaddr>
    if(pa0 == 0)
    800018b8:	c131                	beqz	a0,800018fc <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018ba:	41790833          	sub	a6,s2,s7
    800018be:	984e                	add	a6,a6,s3
    if(n > max)
    800018c0:	0104f363          	bgeu	s1,a6,800018c6 <copyinstr+0x6e>
    800018c4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018c6:	955e                	add	a0,a0,s7
    800018c8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018cc:	fc080be3          	beqz	a6,800018a2 <copyinstr+0x4a>
    800018d0:	985a                	add	a6,a6,s6
    800018d2:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018d4:	41650633          	sub	a2,a0,s6
    800018d8:	14fd                	addi	s1,s1,-1
    800018da:	9b26                	add	s6,s6,s1
    800018dc:	00f60733          	add	a4,a2,a5
    800018e0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    800018e4:	df49                	beqz	a4,8000187e <copyinstr+0x26>
        *dst = *p;
    800018e6:	00e78023          	sb	a4,0(a5)
      --max;
    800018ea:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018ee:	0785                	addi	a5,a5,1
    while(n > 0){
    800018f0:	ff0796e3          	bne	a5,a6,800018dc <copyinstr+0x84>
      dst++;
    800018f4:	8b42                	mv	s6,a6
    800018f6:	b775                	j	800018a2 <copyinstr+0x4a>
    800018f8:	4781                	li	a5,0
    800018fa:	b769                	j	80001884 <copyinstr+0x2c>
      return -1;
    800018fc:	557d                	li	a0,-1
    800018fe:	b779                	j	8000188c <copyinstr+0x34>
  int got_null = 0;
    80001900:	4781                	li	a5,0
  if(got_null){
    80001902:	0017b793          	seqz	a5,a5
    80001906:	40f00533          	neg	a0,a5
}
    8000190a:	8082                	ret

000000008000190c <vmprint_helper>:

// Recursive helper
void vmprint_helper(pagetable_t pagetable, int depth) {
    8000190c:	715d                	addi	sp,sp,-80
    8000190e:	e486                	sd	ra,72(sp)
    80001910:	e0a2                	sd	s0,64(sp)
    80001912:	fc26                	sd	s1,56(sp)
    80001914:	f84a                	sd	s2,48(sp)
    80001916:	f44e                	sd	s3,40(sp)
    80001918:	f052                	sd	s4,32(sp)
    8000191a:	ec56                	sd	s5,24(sp)
    8000191c:	e85a                	sd	s6,16(sp)
    8000191e:	e45e                	sd	s7,8(sp)
    80001920:	e062                	sd	s8,0(sp)
    80001922:	0880                	addi	s0,sp,80
      "",
      "..",
      ".. ..",
      ".. .. .."
  };
  if (depth <= 0 || depth >= 4) {
    80001924:	fff5871b          	addiw	a4,a1,-1
    80001928:	4789                	li	a5,2
    8000192a:	02e7e463          	bltu	a5,a4,80001952 <vmprint_helper+0x46>
    8000192e:	89aa                	mv	s3,a0
    80001930:	4901                	li	s2,0
  }
  // there are 2^9 = 512 PTES in a page table.
  for (int i = 0; i < 512; i++) {
    pte_t pte = pagetable[i];
    if (pte & PTE_V) {
      printf("%s%d: pte %p pa %p\n", indent[depth], i, pte, PTE2PA(pte));
    80001932:	00359793          	slli	a5,a1,0x3
    80001936:	00007b17          	auipc	s6,0x7
    8000193a:	97ab0b13          	addi	s6,s6,-1670 # 800082b0 <indent.1779>
    8000193e:	9b3e                	add	s6,s6,a5
    80001940:	00007b97          	auipc	s7,0x7
    80001944:	8b0b8b93          	addi	s7,s7,-1872 # 800081f0 <digits+0x1b0>
      if ((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
        // points to a lower-level page table
        uint64 child = PTE2PA(pte);
        vmprint_helper((pagetable_t)child, depth+1);
    80001948:	00158c1b          	addiw	s8,a1,1
  for (int i = 0; i < 512; i++) {
    8000194c:	20000a93          	li	s5,512
    80001950:	a01d                	j	80001976 <vmprint_helper+0x6a>
    panic("vmprint_helper: depth not in {1, 2, 3}");
    80001952:	00007517          	auipc	a0,0x7
    80001956:	87650513          	addi	a0,a0,-1930 # 800081c8 <digits+0x188>
    8000195a:	fffff097          	auipc	ra,0xfffff
    8000195e:	bee080e7          	jalr	-1042(ra) # 80000548 <panic>
        vmprint_helper((pagetable_t)child, depth+1);
    80001962:	85e2                	mv	a1,s8
    80001964:	8552                	mv	a0,s4
    80001966:	00000097          	auipc	ra,0x0
    8000196a:	fa6080e7          	jalr	-90(ra) # 8000190c <vmprint_helper>
  for (int i = 0; i < 512; i++) {
    8000196e:	2905                	addiw	s2,s2,1
    80001970:	09a1                	addi	s3,s3,8
    80001972:	03590763          	beq	s2,s5,800019a0 <vmprint_helper+0x94>
    pte_t pte = pagetable[i];
    80001976:	0009b483          	ld	s1,0(s3) # 1000 <_entry-0x7ffff000>
    if (pte & PTE_V) {
    8000197a:	0014f793          	andi	a5,s1,1
    8000197e:	dbe5                	beqz	a5,8000196e <vmprint_helper+0x62>
      printf("%s%d: pte %p pa %p\n", indent[depth], i, pte, PTE2PA(pte));
    80001980:	00a4da13          	srli	s4,s1,0xa
    80001984:	0a32                	slli	s4,s4,0xc
    80001986:	8752                	mv	a4,s4
    80001988:	86a6                	mv	a3,s1
    8000198a:	864a                	mv	a2,s2
    8000198c:	000b3583          	ld	a1,0(s6)
    80001990:	855e                	mv	a0,s7
    80001992:	fffff097          	auipc	ra,0xfffff
    80001996:	c00080e7          	jalr	-1024(ra) # 80000592 <printf>
      if ((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
    8000199a:	88b9                	andi	s1,s1,14
    8000199c:	f8e9                	bnez	s1,8000196e <vmprint_helper+0x62>
    8000199e:	b7d1                	j	80001962 <vmprint_helper+0x56>
      }
    }
  }
}
    800019a0:	60a6                	ld	ra,72(sp)
    800019a2:	6406                	ld	s0,64(sp)
    800019a4:	74e2                	ld	s1,56(sp)
    800019a6:	7942                	ld	s2,48(sp)
    800019a8:	79a2                	ld	s3,40(sp)
    800019aa:	7a02                	ld	s4,32(sp)
    800019ac:	6ae2                	ld	s5,24(sp)
    800019ae:	6b42                	ld	s6,16(sp)
    800019b0:	6ba2                	ld	s7,8(sp)
    800019b2:	6c02                	ld	s8,0(sp)
    800019b4:	6161                	addi	sp,sp,80
    800019b6:	8082                	ret

00000000800019b8 <vmprint>:

// Utility func to print the valid
// PTEs within a page table recursively
void vmprint(pagetable_t pagetable) {
    800019b8:	1101                	addi	sp,sp,-32
    800019ba:	ec06                	sd	ra,24(sp)
    800019bc:	e822                	sd	s0,16(sp)
    800019be:	e426                	sd	s1,8(sp)
    800019c0:	1000                	addi	s0,sp,32
    800019c2:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    800019c4:	85aa                	mv	a1,a0
    800019c6:	00007517          	auipc	a0,0x7
    800019ca:	84250513          	addi	a0,a0,-1982 # 80008208 <digits+0x1c8>
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	bc4080e7          	jalr	-1084(ra) # 80000592 <printf>
  vmprint_helper(pagetable, 1);
    800019d6:	4585                	li	a1,1
    800019d8:	8526                	mv	a0,s1
    800019da:	00000097          	auipc	ra,0x0
    800019de:	f32080e7          	jalr	-206(ra) # 8000190c <vmprint_helper>
}
    800019e2:	60e2                	ld	ra,24(sp)
    800019e4:	6442                	ld	s0,16(sp)
    800019e6:	64a2                	ld	s1,8(sp)
    800019e8:	6105                	addi	sp,sp,32
    800019ea:	8082                	ret

00000000800019ec <ukvmunmap>:
// Unmap the leaf node mapping
// of the per-process kernel page table
// so that we could call freewalk on that
void
ukvmunmap(pagetable_t pagetable, uint64 va, uint64 npages)
{
    800019ec:	7139                	addi	sp,sp,-64
    800019ee:	fc06                	sd	ra,56(sp)
    800019f0:	f822                	sd	s0,48(sp)
    800019f2:	f426                	sd	s1,40(sp)
    800019f4:	f04a                	sd	s2,32(sp)
    800019f6:	ec4e                	sd	s3,24(sp)
    800019f8:	e852                	sd	s4,16(sp)
    800019fa:	e456                	sd	s5,8(sp)
    800019fc:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800019fe:	03459793          	slli	a5,a1,0x34
    80001a02:	e39d                	bnez	a5,80001a28 <ukvmunmap+0x3c>
    80001a04:	89aa                	mv	s3,a0
    80001a06:	84ae                	mv	s1,a1
    panic("ukvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001a08:	00c61913          	slli	s2,a2,0xc
    80001a0c:	992e                	add	s2,s2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      goto clean;
    if((*pte & PTE_V) == 0)
      goto clean;
    if(PTE_FLAGS(*pte) == PTE_V)
    80001a0e:	4a85                	li	s5,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001a10:	6a05                	lui	s4,0x1
    80001a12:	0325e863          	bltu	a1,s2,80001a42 <ukvmunmap+0x56>
      panic("ukvmunmap: not a leaf");

    clean:
      *pte = 0;
  }
}
    80001a16:	70e2                	ld	ra,56(sp)
    80001a18:	7442                	ld	s0,48(sp)
    80001a1a:	74a2                	ld	s1,40(sp)
    80001a1c:	7902                	ld	s2,32(sp)
    80001a1e:	69e2                	ld	s3,24(sp)
    80001a20:	6a42                	ld	s4,16(sp)
    80001a22:	6aa2                	ld	s5,8(sp)
    80001a24:	6121                	addi	sp,sp,64
    80001a26:	8082                	ret
    panic("ukvmunmap: not aligned");
    80001a28:	00006517          	auipc	a0,0x6
    80001a2c:	7f050513          	addi	a0,a0,2032 # 80008218 <digits+0x1d8>
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	b18080e7          	jalr	-1256(ra) # 80000548 <panic>
      *pte = 0;
    80001a38:	00053023          	sd	zero,0(a0)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001a3c:	94d2                	add	s1,s1,s4
    80001a3e:	fd24fce3          	bgeu	s1,s2,80001a16 <ukvmunmap+0x2a>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001a42:	4601                	li	a2,0
    80001a44:	85a6                	mv	a1,s1
    80001a46:	854e                	mv	a0,s3
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	61e080e7          	jalr	1566(ra) # 80001066 <walk>
    80001a50:	d565                	beqz	a0,80001a38 <ukvmunmap+0x4c>
    if((*pte & PTE_V) == 0)
    80001a52:	611c                	ld	a5,0(a0)
    80001a54:	0017f713          	andi	a4,a5,1
    80001a58:	d365                	beqz	a4,80001a38 <ukvmunmap+0x4c>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001a5a:	3ff7f793          	andi	a5,a5,1023
    80001a5e:	fd579de3          	bne	a5,s5,80001a38 <ukvmunmap+0x4c>
      panic("ukvmunmap: not a leaf");
    80001a62:	00006517          	auipc	a0,0x6
    80001a66:	7ce50513          	addi	a0,a0,1998 # 80008230 <digits+0x1f0>
    80001a6a:	fffff097          	auipc	ra,0xfffff
    80001a6e:	ade080e7          	jalr	-1314(ra) # 80000548 <panic>

0000000080001a72 <ufreewalk>:

// Recursively free page-table pages similar to freewalk
// not need to already free leaf node
void
ufreewalk(pagetable_t pagetable)
{
    80001a72:	7139                	addi	sp,sp,-64
    80001a74:	fc06                	sd	ra,56(sp)
    80001a76:	f822                	sd	s0,48(sp)
    80001a78:	f426                	sd	s1,40(sp)
    80001a7a:	f04a                	sd	s2,32(sp)
    80001a7c:	ec4e                	sd	s3,24(sp)
    80001a7e:	e852                	sd	s4,16(sp)
    80001a80:	e456                	sd	s5,8(sp)
    80001a82:	0080                	addi	s0,sp,64
    80001a84:	8aaa                	mv	s5,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001a86:	84aa                	mv	s1,a0
    80001a88:	6985                	lui	s3,0x1
    80001a8a:	99aa                	add	s3,s3,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001a8c:	4a05                	li	s4,1
    80001a8e:	a821                	j	80001aa6 <ufreewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001a90:	8129                	srli	a0,a0,0xa
      ufreewalk((pagetable_t)child);
    80001a92:	0532                	slli	a0,a0,0xc
    80001a94:	00000097          	auipc	ra,0x0
    80001a98:	fde080e7          	jalr	-34(ra) # 80001a72 <ufreewalk>
      pagetable[i] = 0;
    }
    pagetable[i] = 0;
    80001a9c:	00093023          	sd	zero,0(s2) # 1000 <_entry-0x7ffff000>
  for(int i = 0; i < 512; i++){
    80001aa0:	04a1                	addi	s1,s1,8
    80001aa2:	01348963          	beq	s1,s3,80001ab4 <ufreewalk+0x42>
    pte_t pte = pagetable[i];
    80001aa6:	8926                	mv	s2,s1
    80001aa8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001aaa:	00f57793          	andi	a5,a0,15
    80001aae:	ff4797e3          	bne	a5,s4,80001a9c <ufreewalk+0x2a>
    80001ab2:	bff9                	j	80001a90 <ufreewalk+0x1e>
  }
  kfree((void*)pagetable);
    80001ab4:	8556                	mv	a0,s5
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	f6e080e7          	jalr	-146(ra) # 80000a24 <kfree>
}
    80001abe:	70e2                	ld	ra,56(sp)
    80001ac0:	7442                	ld	s0,48(sp)
    80001ac2:	74a2                	ld	s1,40(sp)
    80001ac4:	7902                	ld	s2,32(sp)
    80001ac6:	69e2                	ld	s3,24(sp)
    80001ac8:	6a42                	ld	s4,16(sp)
    80001aca:	6aa2                	ld	s5,8(sp)
    80001acc:	6121                	addi	sp,sp,64
    80001ace:	8082                	ret

0000000080001ad0 <freeprockvm>:

// helper function to first free all leaf mapping
// of a per-process kernel table but do not free the physical address
// and then remove all 3-levels indirection and the physical address
// for this kernel page itself
void freeprockvm(struct proc* p) {
    80001ad0:	1101                	addi	sp,sp,-32
    80001ad2:	ec06                	sd	ra,24(sp)
    80001ad4:	e822                	sd	s0,16(sp)
    80001ad6:	e426                	sd	s1,8(sp)
    80001ad8:	1000                	addi	s0,sp,32
  pagetable_t kpagetable = p->kpagetable;
    80001ada:	17053483          	ld	s1,368(a0)
  // reverse order of allocation
  // 按分配顺序的逆序来销毁映射, 但不回收物理地址
  ukvmunmap(kpagetable, p->kstack, PGSIZE/PGSIZE);
    80001ade:	4605                	li	a2,1
    80001ae0:	612c                	ld	a1,64(a0)
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	00000097          	auipc	ra,0x0
    80001ae8:	f08080e7          	jalr	-248(ra) # 800019ec <ukvmunmap>
  ukvmunmap(kpagetable, TRAMPOLINE, PGSIZE/PGSIZE);
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	00000097          	auipc	ra,0x0
    80001afc:	ef4080e7          	jalr	-268(ra) # 800019ec <ukvmunmap>
  ukvmunmap(kpagetable, (uint64)etext, (PHYSTOP-(uint64)etext)/PGSIZE);
    80001b00:	00006597          	auipc	a1,0x6
    80001b04:	50058593          	addi	a1,a1,1280 # 80008000 <etext>
    80001b08:	4645                	li	a2,17
    80001b0a:	066e                	slli	a2,a2,0x1b
    80001b0c:	8e0d                	sub	a2,a2,a1
    80001b0e:	8231                	srli	a2,a2,0xc
    80001b10:	8526                	mv	a0,s1
    80001b12:	00000097          	auipc	ra,0x0
    80001b16:	eda080e7          	jalr	-294(ra) # 800019ec <ukvmunmap>
  ukvmunmap(kpagetable, KERNBASE, ((uint64)etext-KERNBASE)/PGSIZE);
    80001b1a:	80006617          	auipc	a2,0x80006
    80001b1e:	4e660613          	addi	a2,a2,1254 # 8000 <_entry-0x7fff8000>
    80001b22:	8231                	srli	a2,a2,0xc
    80001b24:	4585                	li	a1,1
    80001b26:	05fe                	slli	a1,a1,0x1f
    80001b28:	8526                	mv	a0,s1
    80001b2a:	00000097          	auipc	ra,0x0
    80001b2e:	ec2080e7          	jalr	-318(ra) # 800019ec <ukvmunmap>
  ukvmunmap(kpagetable, PLIC, 0x400000/PGSIZE);
    80001b32:	40000613          	li	a2,1024
    80001b36:	0c0005b7          	lui	a1,0xc000
    80001b3a:	8526                	mv	a0,s1
    80001b3c:	00000097          	auipc	ra,0x0
    80001b40:	eb0080e7          	jalr	-336(ra) # 800019ec <ukvmunmap>
  ukvmunmap(kpagetable, CLINT, 0x10000/PGSIZE);
    80001b44:	4641                	li	a2,16
    80001b46:	020005b7          	lui	a1,0x2000
    80001b4a:	8526                	mv	a0,s1
    80001b4c:	00000097          	auipc	ra,0x0
    80001b50:	ea0080e7          	jalr	-352(ra) # 800019ec <ukvmunmap>
  ukvmunmap(kpagetable, VIRTIO0, PGSIZE/PGSIZE);
    80001b54:	4605                	li	a2,1
    80001b56:	100015b7          	lui	a1,0x10001
    80001b5a:	8526                	mv	a0,s1
    80001b5c:	00000097          	auipc	ra,0x0
    80001b60:	e90080e7          	jalr	-368(ra) # 800019ec <ukvmunmap>
  ukvmunmap(kpagetable, UART0, PGSIZE/PGSIZE);
    80001b64:	4605                	li	a2,1
    80001b66:	100005b7          	lui	a1,0x10000
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	00000097          	auipc	ra,0x0
    80001b70:	e80080e7          	jalr	-384(ra) # 800019ec <ukvmunmap>
  ufreewalk(kpagetable);
    80001b74:	8526                	mv	a0,s1
    80001b76:	00000097          	auipc	ra,0x0
    80001b7a:	efc080e7          	jalr	-260(ra) # 80001a72 <ufreewalk>
}
    80001b7e:	60e2                	ld	ra,24(sp)
    80001b80:	6442                	ld	s0,16(sp)
    80001b82:	64a2                	ld	s1,8(sp)
    80001b84:	6105                	addi	sp,sp,32
    80001b86:	8082                	ret

0000000080001b88 <ukvmmap>:

// add a mapping to the per-process kernel page table.
void
ukvmmap(pagetable_t kpagetable, uint64 va, uint64 pa, uint64 sz, int perm)
{
    80001b88:	1141                	addi	sp,sp,-16
    80001b8a:	e406                	sd	ra,8(sp)
    80001b8c:	e022                	sd	s0,0(sp)
    80001b8e:	0800                	addi	s0,sp,16
    80001b90:	87b6                	mv	a5,a3
  if(mappages(kpagetable, va, sz, pa, perm) != 0)
    80001b92:	86b2                	mv	a3,a2
    80001b94:	863e                	mv	a2,a5
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	616080e7          	jalr	1558(ra) # 800011ac <mappages>
    80001b9e:	e509                	bnez	a0,80001ba8 <ukvmmap+0x20>
    panic("ukvmmap");
}
    80001ba0:	60a2                	ld	ra,8(sp)
    80001ba2:	6402                	ld	s0,0(sp)
    80001ba4:	0141                	addi	sp,sp,16
    80001ba6:	8082                	ret
    panic("ukvmmap");
    80001ba8:	00006517          	auipc	a0,0x6
    80001bac:	6a050513          	addi	a0,a0,1696 # 80008248 <digits+0x208>
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	998080e7          	jalr	-1640(ra) # 80000548 <panic>

0000000080001bb8 <ukvminit>:
 * create a direct-map page table for the per-process kernel page table.
 * return nullptr when kalloc fails
 */
pagetable_t
ukvminit()
{
    80001bb8:	1101                	addi	sp,sp,-32
    80001bba:	ec06                	sd	ra,24(sp)
    80001bbc:	e822                	sd	s0,16(sp)
    80001bbe:	e426                	sd	s1,8(sp)
    80001bc0:	e04a                	sd	s2,0(sp)
    80001bc2:	1000                	addi	s0,sp,32
  pagetable_t kpagetable = (pagetable_t) kalloc();
    80001bc4:	fffff097          	auipc	ra,0xfffff
    80001bc8:	f5c080e7          	jalr	-164(ra) # 80000b20 <kalloc>
    80001bcc:	84aa                	mv	s1,a0
  if (kpagetable == 0) {
    80001bce:	c161                	beqz	a0,80001c8e <ukvminit+0xd6>
    return kpagetable;
  }
  memset(kpagetable, 0, PGSIZE);
    80001bd0:	6605                	lui	a2,0x1
    80001bd2:	4581                	li	a1,0
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	182080e7          	jalr	386(ra) # 80000d56 <memset>
  // 把固定的常数映射照旧搬运过来
  // uart registers
  ukvmmap(kpagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001bdc:	4719                	li	a4,6
    80001bde:	6685                	lui	a3,0x1
    80001be0:	10000637          	lui	a2,0x10000
    80001be4:	100005b7          	lui	a1,0x10000
    80001be8:	8526                	mv	a0,s1
    80001bea:	00000097          	auipc	ra,0x0
    80001bee:	f9e080e7          	jalr	-98(ra) # 80001b88 <ukvmmap>
  // virtio mmio disk interface
  ukvmmap(kpagetable, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001bf2:	4719                	li	a4,6
    80001bf4:	6685                	lui	a3,0x1
    80001bf6:	10001637          	lui	a2,0x10001
    80001bfa:	100015b7          	lui	a1,0x10001
    80001bfe:	8526                	mv	a0,s1
    80001c00:	00000097          	auipc	ra,0x0
    80001c04:	f88080e7          	jalr	-120(ra) # 80001b88 <ukvmmap>
  // CLINT
  ukvmmap(kpagetable, CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001c08:	4719                	li	a4,6
    80001c0a:	66c1                	lui	a3,0x10
    80001c0c:	02000637          	lui	a2,0x2000
    80001c10:	020005b7          	lui	a1,0x2000
    80001c14:	8526                	mv	a0,s1
    80001c16:	00000097          	auipc	ra,0x0
    80001c1a:	f72080e7          	jalr	-142(ra) # 80001b88 <ukvmmap>
  // PLIC
  ukvmmap(kpagetable, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001c1e:	4719                	li	a4,6
    80001c20:	004006b7          	lui	a3,0x400
    80001c24:	0c000637          	lui	a2,0xc000
    80001c28:	0c0005b7          	lui	a1,0xc000
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	f5a080e7          	jalr	-166(ra) # 80001b88 <ukvmmap>
  // map kernel text executable and read-only.
  ukvmmap(kpagetable, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001c36:	00006917          	auipc	s2,0x6
    80001c3a:	3ca90913          	addi	s2,s2,970 # 80008000 <etext>
    80001c3e:	4729                	li	a4,10
    80001c40:	80006697          	auipc	a3,0x80006
    80001c44:	3c068693          	addi	a3,a3,960 # 8000 <_entry-0x7fff8000>
    80001c48:	4605                	li	a2,1
    80001c4a:	067e                	slli	a2,a2,0x1f
    80001c4c:	85b2                	mv	a1,a2
    80001c4e:	8526                	mv	a0,s1
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	f38080e7          	jalr	-200(ra) # 80001b88 <ukvmmap>
  // map kernel data and the physical RAM we'll make use of.
  ukvmmap(kpagetable, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001c58:	4719                	li	a4,6
    80001c5a:	46c5                	li	a3,17
    80001c5c:	06ee                	slli	a3,a3,0x1b
    80001c5e:	412686b3          	sub	a3,a3,s2
    80001c62:	864a                	mv	a2,s2
    80001c64:	85ca                	mv	a1,s2
    80001c66:	8526                	mv	a0,s1
    80001c68:	00000097          	auipc	ra,0x0
    80001c6c:	f20080e7          	jalr	-224(ra) # 80001b88 <ukvmmap>
  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  ukvmmap(kpagetable, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001c70:	4729                	li	a4,10
    80001c72:	6685                	lui	a3,0x1
    80001c74:	00005617          	auipc	a2,0x5
    80001c78:	38c60613          	addi	a2,a2,908 # 80007000 <_trampoline>
    80001c7c:	040005b7          	lui	a1,0x4000
    80001c80:	15fd                	addi	a1,a1,-1
    80001c82:	05b2                	slli	a1,a1,0xc
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	f02080e7          	jalr	-254(ra) # 80001b88 <ukvmmap>
  return kpagetable;
}
    80001c8e:	8526                	mv	a0,s1
    80001c90:	60e2                	ld	ra,24(sp)
    80001c92:	6442                	ld	s0,16(sp)
    80001c94:	64a2                	ld	s1,8(sp)
    80001c96:	6902                	ld	s2,0(sp)
    80001c98:	6105                	addi	sp,sp,32
    80001c9a:	8082                	ret

0000000080001c9c <umappages>:

// Same as mappages without panic on remapping
int umappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm) {
    80001c9c:	715d                	addi	sp,sp,-80
    80001c9e:	e486                	sd	ra,72(sp)
    80001ca0:	e0a2                	sd	s0,64(sp)
    80001ca2:	fc26                	sd	s1,56(sp)
    80001ca4:	f84a                	sd	s2,48(sp)
    80001ca6:	f44e                	sd	s3,40(sp)
    80001ca8:	f052                	sd	s4,32(sp)
    80001caa:	ec56                	sd	s5,24(sp)
    80001cac:	e85a                	sd	s6,16(sp)
    80001cae:	e45e                	sd	s7,8(sp)
    80001cb0:	0880                	addi	s0,sp,80
    80001cb2:	8aaa                	mv	s5,a0
    80001cb4:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001cb6:	777d                	lui	a4,0xfffff
    80001cb8:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001cbc:	167d                	addi	a2,a2,-1
    80001cbe:	00b609b3          	add	s3,a2,a1
    80001cc2:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001cc6:	893e                	mv	s2,a5
    80001cc8:	40f68a33          	sub	s4,a3,a5
    if((pte = walk(pagetable, a, 1)) == 0)
      return -1;
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001ccc:	6b85                	lui	s7,0x1
    80001cce:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001cd2:	4605                	li	a2,1
    80001cd4:	85ca                	mv	a1,s2
    80001cd6:	8556                	mv	a0,s5
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	38e080e7          	jalr	910(ra) # 80001066 <walk>
    80001ce0:	cd01                	beqz	a0,80001cf8 <umappages+0x5c>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001ce2:	80b1                	srli	s1,s1,0xc
    80001ce4:	04aa                	slli	s1,s1,0xa
    80001ce6:	0164e4b3          	or	s1,s1,s6
    80001cea:	0014e493          	ori	s1,s1,1
    80001cee:	e104                	sd	s1,0(a0)
    if(a == last)
    80001cf0:	03390063          	beq	s2,s3,80001d10 <umappages+0x74>
    a += PGSIZE;
    80001cf4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001cf6:	bfe1                	j	80001cce <umappages+0x32>
      return -1;
    80001cf8:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001cfa:	60a6                	ld	ra,72(sp)
    80001cfc:	6406                	ld	s0,64(sp)
    80001cfe:	74e2                	ld	s1,56(sp)
    80001d00:	7942                	ld	s2,48(sp)
    80001d02:	79a2                	ld	s3,40(sp)
    80001d04:	7a02                	ld	s4,32(sp)
    80001d06:	6ae2                	ld	s5,24(sp)
    80001d08:	6b42                	ld	s6,16(sp)
    80001d0a:	6ba2                	ld	s7,8(sp)
    80001d0c:	6161                	addi	sp,sp,80
    80001d0e:	8082                	ret
  return 0;
    80001d10:	4501                	li	a0,0
    80001d12:	b7e5                	j	80001cfa <umappages+0x5e>

0000000080001d14 <pagecopy>:

// copying from old page to new page from
// begin in old page to new in old page
// and mask off PTE_U bit
int
pagecopy(pagetable_t oldpage, pagetable_t newpage, uint64 begin, uint64 end) {
    80001d14:	7179                	addi	sp,sp,-48
    80001d16:	f406                	sd	ra,40(sp)
    80001d18:	f022                	sd	s0,32(sp)
    80001d1a:	ec26                	sd	s1,24(sp)
    80001d1c:	e84a                	sd	s2,16(sp)
    80001d1e:	e44e                	sd	s3,8(sp)
    80001d20:	e052                	sd	s4,0(sp)
    80001d22:	1800                	addi	s0,sp,48
    80001d24:	8a2a                	mv	s4,a0
    80001d26:	89ae                	mv	s3,a1
    80001d28:	8936                	mv	s2,a3
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  begin = PGROUNDUP(begin);
    80001d2a:	6485                	lui	s1,0x1
    80001d2c:	14fd                	addi	s1,s1,-1
    80001d2e:	9626                	add	a2,a2,s1
    80001d30:	74fd                	lui	s1,0xfffff
    80001d32:	8cf1                	and	s1,s1,a2

  for (i = begin; i < end; i += PGSIZE) {
    80001d34:	08d4f263          	bgeu	s1,a3,80001db8 <pagecopy+0xa4>
    if ((pte = walk(oldpage, i, 0)) == 0)
    80001d38:	4601                	li	a2,0
    80001d3a:	85a6                	mv	a1,s1
    80001d3c:	8552                	mv	a0,s4
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	328080e7          	jalr	808(ra) # 80001066 <walk>
    80001d46:	c51d                	beqz	a0,80001d74 <pagecopy+0x60>
      panic("pagecopy walk oldpage nullptr");
    if ((*pte & PTE_V) == 0)
    80001d48:	6118                	ld	a4,0(a0)
    80001d4a:	00177793          	andi	a5,a4,1
    80001d4e:	cb9d                	beqz	a5,80001d84 <pagecopy+0x70>
      panic("pagecopy oldpage pte not valid");
    pa = PTE2PA(*pte);
    80001d50:	00a75693          	srli	a3,a4,0xa
    flags = PTE_FLAGS(*pte) & (~PTE_U); // 把U flag抹去
    if (umappages(newpage, i, PGSIZE, pa, flags) != 0) {
    80001d54:	3ef77713          	andi	a4,a4,1007
    80001d58:	06b2                	slli	a3,a3,0xc
    80001d5a:	6605                	lui	a2,0x1
    80001d5c:	85a6                	mv	a1,s1
    80001d5e:	854e                	mv	a0,s3
    80001d60:	00000097          	auipc	ra,0x0
    80001d64:	f3c080e7          	jalr	-196(ra) # 80001c9c <umappages>
    80001d68:	e515                	bnez	a0,80001d94 <pagecopy+0x80>
  for (i = begin; i < end; i += PGSIZE) {
    80001d6a:	6785                	lui	a5,0x1
    80001d6c:	94be                	add	s1,s1,a5
    80001d6e:	fd24e5e3          	bltu	s1,s2,80001d38 <pagecopy+0x24>
    80001d72:	a81d                	j	80001da8 <pagecopy+0x94>
      panic("pagecopy walk oldpage nullptr");
    80001d74:	00006517          	auipc	a0,0x6
    80001d78:	4dc50513          	addi	a0,a0,1244 # 80008250 <digits+0x210>
    80001d7c:	ffffe097          	auipc	ra,0xffffe
    80001d80:	7cc080e7          	jalr	1996(ra) # 80000548 <panic>
      panic("pagecopy oldpage pte not valid");
    80001d84:	00006517          	auipc	a0,0x6
    80001d88:	4ec50513          	addi	a0,a0,1260 # 80008270 <digits+0x230>
    80001d8c:	ffffe097          	auipc	ra,0xffffe
    80001d90:	7bc080e7          	jalr	1980(ra) # 80000548 <panic>
    }
  }
  return 0;

err:
  uvmunmap(newpage, 0, i / PGSIZE, 1);
    80001d94:	4685                	li	a3,1
    80001d96:	00c4d613          	srli	a2,s1,0xc
    80001d9a:	4581                	li	a1,0
    80001d9c:	854e                	mv	a0,s3
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	5a6080e7          	jalr	1446(ra) # 80001344 <uvmunmap>
  return -1;
    80001da6:	557d                	li	a0,-1
    80001da8:	70a2                	ld	ra,40(sp)
    80001daa:	7402                	ld	s0,32(sp)
    80001dac:	64e2                	ld	s1,24(sp)
    80001dae:	6942                	ld	s2,16(sp)
    80001db0:	69a2                	ld	s3,8(sp)
    80001db2:	6a02                	ld	s4,0(sp)
    80001db4:	6145                	addi	sp,sp,48
    80001db6:	8082                	ret
  return 0;
    80001db8:	4501                	li	a0,0
    80001dba:	b7fd                	j	80001da8 <pagecopy+0x94>

0000000080001dbc <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001dbc:	1101                	addi	sp,sp,-32
    80001dbe:	ec06                	sd	ra,24(sp)
    80001dc0:	e822                	sd	s0,16(sp)
    80001dc2:	e426                	sd	s1,8(sp)
    80001dc4:	1000                	addi	s0,sp,32
    80001dc6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	e18080e7          	jalr	-488(ra) # 80000be0 <holding>
    80001dd0:	c909                	beqz	a0,80001de2 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001dd2:	749c                	ld	a5,40(s1)
    80001dd4:	00978f63          	beq	a5,s1,80001df2 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001dd8:	60e2                	ld	ra,24(sp)
    80001dda:	6442                	ld	s0,16(sp)
    80001ddc:	64a2                	ld	s1,8(sp)
    80001dde:	6105                	addi	sp,sp,32
    80001de0:	8082                	ret
    panic("wakeup1");
    80001de2:	00006517          	auipc	a0,0x6
    80001de6:	4ee50513          	addi	a0,a0,1262 # 800082d0 <indent.1779+0x20>
    80001dea:	ffffe097          	auipc	ra,0xffffe
    80001dee:	75e080e7          	jalr	1886(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001df2:	4c98                	lw	a4,24(s1)
    80001df4:	4785                	li	a5,1
    80001df6:	fef711e3          	bne	a4,a5,80001dd8 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001dfa:	4789                	li	a5,2
    80001dfc:	cc9c                	sw	a5,24(s1)
}
    80001dfe:	bfe9                	j	80001dd8 <wakeup1+0x1c>

0000000080001e00 <procinit>:
{
    80001e00:	715d                	addi	sp,sp,-80
    80001e02:	e486                	sd	ra,72(sp)
    80001e04:	e0a2                	sd	s0,64(sp)
    80001e06:	fc26                	sd	s1,56(sp)
    80001e08:	f84a                	sd	s2,48(sp)
    80001e0a:	f44e                	sd	s3,40(sp)
    80001e0c:	f052                	sd	s4,32(sp)
    80001e0e:	ec56                	sd	s5,24(sp)
    80001e10:	e85a                	sd	s6,16(sp)
    80001e12:	e45e                	sd	s7,8(sp)
    80001e14:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001e16:	00006597          	auipc	a1,0x6
    80001e1a:	4c258593          	addi	a1,a1,1218 # 800082d8 <indent.1779+0x28>
    80001e1e:	00010517          	auipc	a0,0x10
    80001e22:	b3250513          	addi	a0,a0,-1230 # 80011950 <pid_lock>
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	da4080e7          	jalr	-604(ra) # 80000bca <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e2e:	00010917          	auipc	s2,0x10
    80001e32:	f3a90913          	addi	s2,s2,-198 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001e36:	00006b97          	auipc	s7,0x6
    80001e3a:	4aab8b93          	addi	s7,s7,1194 # 800082e0 <indent.1779+0x30>
      uint64 va = KSTACK((int) (p - proc));
    80001e3e:	8b4a                	mv	s6,s2
    80001e40:	00006a97          	auipc	s5,0x6
    80001e44:	1c0a8a93          	addi	s5,s5,448 # 80008000 <etext>
    80001e48:	040009b7          	lui	s3,0x4000
    80001e4c:	19fd                	addi	s3,s3,-1
    80001e4e:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e50:	00016a17          	auipc	s4,0x16
    80001e54:	d18a0a13          	addi	s4,s4,-744 # 80017b68 <tickslock>
      initlock(&p->lock, "proc");
    80001e58:	85de                	mv	a1,s7
    80001e5a:	854a                	mv	a0,s2
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	d6e080e7          	jalr	-658(ra) # 80000bca <initlock>
      char *pa = kalloc();
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	cbc080e7          	jalr	-836(ra) # 80000b20 <kalloc>
    80001e6c:	85aa                	mv	a1,a0
      if(pa == 0)
    80001e6e:	c929                	beqz	a0,80001ec0 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001e70:	416904b3          	sub	s1,s2,s6
    80001e74:	848d                	srai	s1,s1,0x3
    80001e76:	000ab783          	ld	a5,0(s5)
    80001e7a:	02f484b3          	mul	s1,s1,a5
    80001e7e:	2485                	addiw	s1,s1,1
    80001e80:	00d4949b          	slliw	s1,s1,0xd
    80001e84:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001e88:	4699                	li	a3,6
    80001e8a:	6605                	lui	a2,0x1
    80001e8c:	8526                	mv	a0,s1
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	3ac080e7          	jalr	940(ra) # 8000123a <kvmmap>
      p->kstack = va;
    80001e96:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e9a:	17890913          	addi	s2,s2,376
    80001e9e:	fb491de3          	bne	s2,s4,80001e58 <procinit+0x58>
  kvminithart();
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	1a0080e7          	jalr	416(ra) # 80001042 <kvminithart>
}
    80001eaa:	60a6                	ld	ra,72(sp)
    80001eac:	6406                	ld	s0,64(sp)
    80001eae:	74e2                	ld	s1,56(sp)
    80001eb0:	7942                	ld	s2,48(sp)
    80001eb2:	79a2                	ld	s3,40(sp)
    80001eb4:	7a02                	ld	s4,32(sp)
    80001eb6:	6ae2                	ld	s5,24(sp)
    80001eb8:	6b42                	ld	s6,16(sp)
    80001eba:	6ba2                	ld	s7,8(sp)
    80001ebc:	6161                	addi	sp,sp,80
    80001ebe:	8082                	ret
        panic("kalloc");
    80001ec0:	00006517          	auipc	a0,0x6
    80001ec4:	42850513          	addi	a0,a0,1064 # 800082e8 <indent.1779+0x38>
    80001ec8:	ffffe097          	auipc	ra,0xffffe
    80001ecc:	680080e7          	jalr	1664(ra) # 80000548 <panic>

0000000080001ed0 <cpuid>:
{
    80001ed0:	1141                	addi	sp,sp,-16
    80001ed2:	e422                	sd	s0,8(sp)
    80001ed4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ed6:	8512                	mv	a0,tp
}
    80001ed8:	2501                	sext.w	a0,a0
    80001eda:	6422                	ld	s0,8(sp)
    80001edc:	0141                	addi	sp,sp,16
    80001ede:	8082                	ret

0000000080001ee0 <mycpu>:
mycpu(void) {
    80001ee0:	1141                	addi	sp,sp,-16
    80001ee2:	e422                	sd	s0,8(sp)
    80001ee4:	0800                	addi	s0,sp,16
    80001ee6:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ee8:	2781                	sext.w	a5,a5
    80001eea:	079e                	slli	a5,a5,0x7
}
    80001eec:	00010517          	auipc	a0,0x10
    80001ef0:	a7c50513          	addi	a0,a0,-1412 # 80011968 <cpus>
    80001ef4:	953e                	add	a0,a0,a5
    80001ef6:	6422                	ld	s0,8(sp)
    80001ef8:	0141                	addi	sp,sp,16
    80001efa:	8082                	ret

0000000080001efc <myproc>:
myproc(void) {
    80001efc:	1101                	addi	sp,sp,-32
    80001efe:	ec06                	sd	ra,24(sp)
    80001f00:	e822                	sd	s0,16(sp)
    80001f02:	e426                	sd	s1,8(sp)
    80001f04:	1000                	addi	s0,sp,32
  push_off();
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d08080e7          	jalr	-760(ra) # 80000c0e <push_off>
    80001f0e:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001f10:	2781                	sext.w	a5,a5
    80001f12:	079e                	slli	a5,a5,0x7
    80001f14:	00010717          	auipc	a4,0x10
    80001f18:	a3c70713          	addi	a4,a4,-1476 # 80011950 <pid_lock>
    80001f1c:	97ba                	add	a5,a5,a4
    80001f1e:	6f84                	ld	s1,24(a5)
  pop_off();
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	d8e080e7          	jalr	-626(ra) # 80000cae <pop_off>
}
    80001f28:	8526                	mv	a0,s1
    80001f2a:	60e2                	ld	ra,24(sp)
    80001f2c:	6442                	ld	s0,16(sp)
    80001f2e:	64a2                	ld	s1,8(sp)
    80001f30:	6105                	addi	sp,sp,32
    80001f32:	8082                	ret

0000000080001f34 <forkret>:
{
    80001f34:	1141                	addi	sp,sp,-16
    80001f36:	e406                	sd	ra,8(sp)
    80001f38:	e022                	sd	s0,0(sp)
    80001f3a:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001f3c:	00000097          	auipc	ra,0x0
    80001f40:	fc0080e7          	jalr	-64(ra) # 80001efc <myproc>
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	dca080e7          	jalr	-566(ra) # 80000d0e <release>
  if (first) {
    80001f4c:	00007797          	auipc	a5,0x7
    80001f50:	b947a783          	lw	a5,-1132(a5) # 80008ae0 <first.1700>
    80001f54:	eb89                	bnez	a5,80001f66 <forkret+0x32>
  usertrapret();
    80001f56:	00001097          	auipc	ra,0x1
    80001f5a:	df8080e7          	jalr	-520(ra) # 80002d4e <usertrapret>
}
    80001f5e:	60a2                	ld	ra,8(sp)
    80001f60:	6402                	ld	s0,0(sp)
    80001f62:	0141                	addi	sp,sp,16
    80001f64:	8082                	ret
    first = 0;
    80001f66:	00007797          	auipc	a5,0x7
    80001f6a:	b607ad23          	sw	zero,-1158(a5) # 80008ae0 <first.1700>
    fsinit(ROOTDEV);
    80001f6e:	4505                	li	a0,1
    80001f70:	00002097          	auipc	ra,0x2
    80001f74:	bfc080e7          	jalr	-1028(ra) # 80003b6c <fsinit>
    80001f78:	bff9                	j	80001f56 <forkret+0x22>

0000000080001f7a <allocpid>:
allocpid() {
    80001f7a:	1101                	addi	sp,sp,-32
    80001f7c:	ec06                	sd	ra,24(sp)
    80001f7e:	e822                	sd	s0,16(sp)
    80001f80:	e426                	sd	s1,8(sp)
    80001f82:	e04a                	sd	s2,0(sp)
    80001f84:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001f86:	00010917          	auipc	s2,0x10
    80001f8a:	9ca90913          	addi	s2,s2,-1590 # 80011950 <pid_lock>
    80001f8e:	854a                	mv	a0,s2
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	cca080e7          	jalr	-822(ra) # 80000c5a <acquire>
  pid = nextpid;
    80001f98:	00007797          	auipc	a5,0x7
    80001f9c:	b4c78793          	addi	a5,a5,-1204 # 80008ae4 <nextpid>
    80001fa0:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001fa2:	0014871b          	addiw	a4,s1,1
    80001fa6:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001fa8:	854a                	mv	a0,s2
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	d64080e7          	jalr	-668(ra) # 80000d0e <release>
}
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	60e2                	ld	ra,24(sp)
    80001fb6:	6442                	ld	s0,16(sp)
    80001fb8:	64a2                	ld	s1,8(sp)
    80001fba:	6902                	ld	s2,0(sp)
    80001fbc:	6105                	addi	sp,sp,32
    80001fbe:	8082                	ret

0000000080001fc0 <proc_pagetable>:
{
    80001fc0:	1101                	addi	sp,sp,-32
    80001fc2:	ec06                	sd	ra,24(sp)
    80001fc4:	e822                	sd	s0,16(sp)
    80001fc6:	e426                	sd	s1,8(sp)
    80001fc8:	e04a                	sd	s2,0(sp)
    80001fca:	1000                	addi	s0,sp,32
    80001fcc:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	43a080e7          	jalr	1082(ra) # 80001408 <uvmcreate>
    80001fd6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001fd8:	c121                	beqz	a0,80002018 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001fda:	4729                	li	a4,10
    80001fdc:	00005697          	auipc	a3,0x5
    80001fe0:	02468693          	addi	a3,a3,36 # 80007000 <_trampoline>
    80001fe4:	6605                	lui	a2,0x1
    80001fe6:	040005b7          	lui	a1,0x4000
    80001fea:	15fd                	addi	a1,a1,-1
    80001fec:	05b2                	slli	a1,a1,0xc
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	1be080e7          	jalr	446(ra) # 800011ac <mappages>
    80001ff6:	02054863          	bltz	a0,80002026 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ffa:	4719                	li	a4,6
    80001ffc:	05893683          	ld	a3,88(s2)
    80002000:	6605                	lui	a2,0x1
    80002002:	020005b7          	lui	a1,0x2000
    80002006:	15fd                	addi	a1,a1,-1
    80002008:	05b6                	slli	a1,a1,0xd
    8000200a:	8526                	mv	a0,s1
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	1a0080e7          	jalr	416(ra) # 800011ac <mappages>
    80002014:	02054163          	bltz	a0,80002036 <proc_pagetable+0x76>
}
    80002018:	8526                	mv	a0,s1
    8000201a:	60e2                	ld	ra,24(sp)
    8000201c:	6442                	ld	s0,16(sp)
    8000201e:	64a2                	ld	s1,8(sp)
    80002020:	6902                	ld	s2,0(sp)
    80002022:	6105                	addi	sp,sp,32
    80002024:	8082                	ret
    uvmfree(pagetable, 0);
    80002026:	4581                	li	a1,0
    80002028:	8526                	mv	a0,s1
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	5da080e7          	jalr	1498(ra) # 80001604 <uvmfree>
    return 0;
    80002032:	4481                	li	s1,0
    80002034:	b7d5                	j	80002018 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002036:	4681                	li	a3,0
    80002038:	4605                	li	a2,1
    8000203a:	040005b7          	lui	a1,0x4000
    8000203e:	15fd                	addi	a1,a1,-1
    80002040:	05b2                	slli	a1,a1,0xc
    80002042:	8526                	mv	a0,s1
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	300080e7          	jalr	768(ra) # 80001344 <uvmunmap>
    uvmfree(pagetable, 0);
    8000204c:	4581                	li	a1,0
    8000204e:	8526                	mv	a0,s1
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	5b4080e7          	jalr	1460(ra) # 80001604 <uvmfree>
    return 0;
    80002058:	4481                	li	s1,0
    8000205a:	bf7d                	j	80002018 <proc_pagetable+0x58>

000000008000205c <proc_freepagetable>:
{
    8000205c:	1101                	addi	sp,sp,-32
    8000205e:	ec06                	sd	ra,24(sp)
    80002060:	e822                	sd	s0,16(sp)
    80002062:	e426                	sd	s1,8(sp)
    80002064:	e04a                	sd	s2,0(sp)
    80002066:	1000                	addi	s0,sp,32
    80002068:	84aa                	mv	s1,a0
    8000206a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000206c:	4681                	li	a3,0
    8000206e:	4605                	li	a2,1
    80002070:	040005b7          	lui	a1,0x4000
    80002074:	15fd                	addi	a1,a1,-1
    80002076:	05b2                	slli	a1,a1,0xc
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	2cc080e7          	jalr	716(ra) # 80001344 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002080:	4681                	li	a3,0
    80002082:	4605                	li	a2,1
    80002084:	020005b7          	lui	a1,0x2000
    80002088:	15fd                	addi	a1,a1,-1
    8000208a:	05b6                	slli	a1,a1,0xd
    8000208c:	8526                	mv	a0,s1
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	2b6080e7          	jalr	694(ra) # 80001344 <uvmunmap>
  uvmfree(pagetable, sz);
    80002096:	85ca                	mv	a1,s2
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	56a080e7          	jalr	1386(ra) # 80001604 <uvmfree>
}
    800020a2:	60e2                	ld	ra,24(sp)
    800020a4:	6442                	ld	s0,16(sp)
    800020a6:	64a2                	ld	s1,8(sp)
    800020a8:	6902                	ld	s2,0(sp)
    800020aa:	6105                	addi	sp,sp,32
    800020ac:	8082                	ret

00000000800020ae <freeproc>:
{
    800020ae:	1101                	addi	sp,sp,-32
    800020b0:	ec06                	sd	ra,24(sp)
    800020b2:	e822                	sd	s0,16(sp)
    800020b4:	e426                	sd	s1,8(sp)
    800020b6:	1000                	addi	s0,sp,32
    800020b8:	84aa                	mv	s1,a0
  if(p->trapframe)
    800020ba:	6d28                	ld	a0,88(a0)
    800020bc:	c509                	beqz	a0,800020c6 <freeproc+0x18>
    kfree((void*)p->trapframe);
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	966080e7          	jalr	-1690(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    800020c6:	0404bc23          	sd	zero,88(s1) # fffffffffffff058 <end+0xffffffff7ffd8038>
  if(p->pagetable)
    800020ca:	68a8                	ld	a0,80(s1)
    800020cc:	c511                	beqz	a0,800020d8 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    800020ce:	64ac                	ld	a1,72(s1)
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	f8c080e7          	jalr	-116(ra) # 8000205c <proc_freepagetable>
  p->pagetable = 0;
    800020d8:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    800020dc:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    800020e0:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    800020e4:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    800020e8:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    800020ec:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    800020f0:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    800020f4:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    800020f8:	0004ac23          	sw	zero,24(s1)
  if (p->kpagetable) {
    800020fc:	1704b783          	ld	a5,368(s1)
    80002100:	cb81                	beqz	a5,80002110 <freeproc+0x62>
    freeprockvm(p);
    80002102:	8526                	mv	a0,s1
    80002104:	00000097          	auipc	ra,0x0
    80002108:	9cc080e7          	jalr	-1588(ra) # 80001ad0 <freeprockvm>
    p->kpagetable = 0;
    8000210c:	1604b823          	sd	zero,368(s1)
  if (p->kstack) {
    80002110:	60bc                	ld	a5,64(s1)
    80002112:	c399                	beqz	a5,80002118 <freeproc+0x6a>
    p->kstack = 0;
    80002114:	0404b023          	sd	zero,64(s1)
}
    80002118:	60e2                	ld	ra,24(sp)
    8000211a:	6442                	ld	s0,16(sp)
    8000211c:	64a2                	ld	s1,8(sp)
    8000211e:	6105                	addi	sp,sp,32
    80002120:	8082                	ret

0000000080002122 <allocproc>:
{
    80002122:	7179                	addi	sp,sp,-48
    80002124:	f406                	sd	ra,40(sp)
    80002126:	f022                	sd	s0,32(sp)
    80002128:	ec26                	sd	s1,24(sp)
    8000212a:	e84a                	sd	s2,16(sp)
    8000212c:	e44e                	sd	s3,8(sp)
    8000212e:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80002130:	00010497          	auipc	s1,0x10
    80002134:	c3848493          	addi	s1,s1,-968 # 80011d68 <proc>
    80002138:	00016917          	auipc	s2,0x16
    8000213c:	a3090913          	addi	s2,s2,-1488 # 80017b68 <tickslock>
    acquire(&p->lock);
    80002140:	8526                	mv	a0,s1
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	b18080e7          	jalr	-1256(ra) # 80000c5a <acquire>
    if(p->state == UNUSED) {
    8000214a:	4c9c                	lw	a5,24(s1)
    8000214c:	cf81                	beqz	a5,80002164 <allocproc+0x42>
      release(&p->lock);
    8000214e:	8526                	mv	a0,s1
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	bbe080e7          	jalr	-1090(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002158:	17848493          	addi	s1,s1,376
    8000215c:	ff2492e3          	bne	s1,s2,80002140 <allocproc+0x1e>
  return 0;
    80002160:	4481                	li	s1,0
    80002162:	a87d                	j	80002220 <allocproc+0xfe>
  p->pid = allocpid();
    80002164:	00000097          	auipc	ra,0x0
    80002168:	e16080e7          	jalr	-490(ra) # 80001f7a <allocpid>
    8000216c:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	9b2080e7          	jalr	-1614(ra) # 80000b20 <kalloc>
    80002176:	892a                	mv	s2,a0
    80002178:	eca8                	sd	a0,88(s1)
    8000217a:	c95d                	beqz	a0,80002230 <allocproc+0x10e>
  p->pagetable = proc_pagetable(p);
    8000217c:	8526                	mv	a0,s1
    8000217e:	00000097          	auipc	ra,0x0
    80002182:	e42080e7          	jalr	-446(ra) # 80001fc0 <proc_pagetable>
    80002186:	892a                	mv	s2,a0
    80002188:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    8000218a:	c955                	beqz	a0,8000223e <allocproc+0x11c>
  p->kpagetable = ukvminit();
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	a2c080e7          	jalr	-1492(ra) # 80001bb8 <ukvminit>
    80002194:	892a                	mv	s2,a0
    80002196:	16a4b823          	sd	a0,368(s1)
  if(p->kpagetable == 0) {
    8000219a:	cd55                	beqz	a0,80002256 <allocproc+0x134>
  uint64 va = KSTACK((int) (p - proc));
    8000219c:	00010797          	auipc	a5,0x10
    800021a0:	bcc78793          	addi	a5,a5,-1076 # 80011d68 <proc>
    800021a4:	40f487b3          	sub	a5,s1,a5
    800021a8:	878d                	srai	a5,a5,0x3
    800021aa:	00006717          	auipc	a4,0x6
    800021ae:	e5673703          	ld	a4,-426(a4) # 80008000 <etext>
    800021b2:	02e787b3          	mul	a5,a5,a4
    800021b6:	2785                	addiw	a5,a5,1
    800021b8:	00d7979b          	slliw	a5,a5,0xd
    800021bc:	04000937          	lui	s2,0x4000
    800021c0:	197d                	addi	s2,s2,-1
    800021c2:	0932                	slli	s2,s2,0xc
    800021c4:	40f90933          	sub	s2,s2,a5
  pte_t pa = kvmpa(va);
    800021c8:	854a                	mv	a0,s2
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	f84080e7          	jalr	-124(ra) # 8000114e <kvmpa>
    800021d2:	89aa                	mv	s3,a0
  memset((void *)pa, 0, PGSIZE); 
    800021d4:	6605                	lui	a2,0x1
    800021d6:	4581                	li	a1,0
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	b7e080e7          	jalr	-1154(ra) # 80000d56 <memset>
  ukvmmap(p->kpagetable, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800021e0:	4719                	li	a4,6
    800021e2:	6685                	lui	a3,0x1
    800021e4:	864e                	mv	a2,s3
    800021e6:	85ca                	mv	a1,s2
    800021e8:	1704b503          	ld	a0,368(s1)
    800021ec:	00000097          	auipc	ra,0x0
    800021f0:	99c080e7          	jalr	-1636(ra) # 80001b88 <ukvmmap>
  p->kstack = va;
    800021f4:	0524b023          	sd	s2,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    800021f8:	07000613          	li	a2,112
    800021fc:	4581                	li	a1,0
    800021fe:	06048513          	addi	a0,s1,96
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	b54080e7          	jalr	-1196(ra) # 80000d56 <memset>
  p->context.ra = (uint64)forkret;
    8000220a:	00000797          	auipc	a5,0x0
    8000220e:	d2a78793          	addi	a5,a5,-726 # 80001f34 <forkret>
    80002212:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002214:	60bc                	ld	a5,64(s1)
    80002216:	6705                	lui	a4,0x1
    80002218:	97ba                	add	a5,a5,a4
    8000221a:	f4bc                	sd	a5,104(s1)
  p->tracemask = 0;
    8000221c:	1604b423          	sd	zero,360(s1)
}
    80002220:	8526                	mv	a0,s1
    80002222:	70a2                	ld	ra,40(sp)
    80002224:	7402                	ld	s0,32(sp)
    80002226:	64e2                	ld	s1,24(sp)
    80002228:	6942                	ld	s2,16(sp)
    8000222a:	69a2                	ld	s3,8(sp)
    8000222c:	6145                	addi	sp,sp,48
    8000222e:	8082                	ret
    release(&p->lock);
    80002230:	8526                	mv	a0,s1
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	adc080e7          	jalr	-1316(ra) # 80000d0e <release>
    return 0;
    8000223a:	84ca                	mv	s1,s2
    8000223c:	b7d5                	j	80002220 <allocproc+0xfe>
    freeproc(p);
    8000223e:	8526                	mv	a0,s1
    80002240:	00000097          	auipc	ra,0x0
    80002244:	e6e080e7          	jalr	-402(ra) # 800020ae <freeproc>
    release(&p->lock);
    80002248:	8526                	mv	a0,s1
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	ac4080e7          	jalr	-1340(ra) # 80000d0e <release>
    return 0;
    80002252:	84ca                	mv	s1,s2
    80002254:	b7f1                	j	80002220 <allocproc+0xfe>
    freeproc(p);
    80002256:	8526                	mv	a0,s1
    80002258:	00000097          	auipc	ra,0x0
    8000225c:	e56080e7          	jalr	-426(ra) # 800020ae <freeproc>
    release(&p->lock);
    80002260:	8526                	mv	a0,s1
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	aac080e7          	jalr	-1364(ra) # 80000d0e <release>
    return 0;
    8000226a:	84ca                	mv	s1,s2
    8000226c:	bf55                	j	80002220 <allocproc+0xfe>

000000008000226e <userinit>:
{
    8000226e:	1101                	addi	sp,sp,-32
    80002270:	ec06                	sd	ra,24(sp)
    80002272:	e822                	sd	s0,16(sp)
    80002274:	e426                	sd	s1,8(sp)
    80002276:	e04a                	sd	s2,0(sp)
    80002278:	1000                	addi	s0,sp,32
  p = allocproc();
    8000227a:	00000097          	auipc	ra,0x0
    8000227e:	ea8080e7          	jalr	-344(ra) # 80002122 <allocproc>
    80002282:	84aa                	mv	s1,a0
  initproc = p;
    80002284:	00007797          	auipc	a5,0x7
    80002288:	d8a7ba23          	sd	a0,-620(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000228c:	03400613          	li	a2,52
    80002290:	00007597          	auipc	a1,0x7
    80002294:	86058593          	addi	a1,a1,-1952 # 80008af0 <initcode>
    80002298:	6928                	ld	a0,80(a0)
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	19c080e7          	jalr	412(ra) # 80001436 <uvminit>
  p->sz = PGSIZE;
    800022a2:	6905                	lui	s2,0x1
    800022a4:	0524b423          	sd	s2,72(s1)
  pagecopy(p->pagetable, p->kpagetable, 0, p->sz);
    800022a8:	6685                	lui	a3,0x1
    800022aa:	4601                	li	a2,0
    800022ac:	1704b583          	ld	a1,368(s1)
    800022b0:	68a8                	ld	a0,80(s1)
    800022b2:	00000097          	auipc	ra,0x0
    800022b6:	a62080e7          	jalr	-1438(ra) # 80001d14 <pagecopy>
  p->trapframe->epc = 0;      // user program counter
    800022ba:	6cbc                	ld	a5,88(s1)
    800022bc:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800022c0:	6cbc                	ld	a5,88(s1)
    800022c2:	0327b823          	sd	s2,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800022c6:	4641                	li	a2,16
    800022c8:	00006597          	auipc	a1,0x6
    800022cc:	02858593          	addi	a1,a1,40 # 800082f0 <indent.1779+0x40>
    800022d0:	15848513          	addi	a0,s1,344
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	bd8080e7          	jalr	-1064(ra) # 80000eac <safestrcpy>
  p->cwd = namei("/");
    800022dc:	00006517          	auipc	a0,0x6
    800022e0:	02450513          	addi	a0,a0,36 # 80008300 <indent.1779+0x50>
    800022e4:	00002097          	auipc	ra,0x2
    800022e8:	2b0080e7          	jalr	688(ra) # 80004594 <namei>
    800022ec:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800022f0:	4789                	li	a5,2
    800022f2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800022f4:	8526                	mv	a0,s1
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	a18080e7          	jalr	-1512(ra) # 80000d0e <release>
}
    800022fe:	60e2                	ld	ra,24(sp)
    80002300:	6442                	ld	s0,16(sp)
    80002302:	64a2                	ld	s1,8(sp)
    80002304:	6902                	ld	s2,0(sp)
    80002306:	6105                	addi	sp,sp,32
    80002308:	8082                	ret

000000008000230a <growproc>:
{
    8000230a:	7179                	addi	sp,sp,-48
    8000230c:	f406                	sd	ra,40(sp)
    8000230e:	f022                	sd	s0,32(sp)
    80002310:	ec26                	sd	s1,24(sp)
    80002312:	e84a                	sd	s2,16(sp)
    80002314:	e44e                	sd	s3,8(sp)
    80002316:	1800                	addi	s0,sp,48
    80002318:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000231a:	00000097          	auipc	ra,0x0
    8000231e:	be2080e7          	jalr	-1054(ra) # 80001efc <myproc>
    80002322:	84aa                	mv	s1,a0
  sz = p->sz;
    80002324:	652c                	ld	a1,72(a0)
    80002326:	0005899b          	sext.w	s3,a1
  if(n > 0){
    8000232a:	07205663          	blez	s2,80002396 <growproc+0x8c>
    if (sz + n > PLIC || (sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000232e:	0139093b          	addw	s2,s2,s3
    80002332:	0009071b          	sext.w	a4,s2
    80002336:	0c0007b7          	lui	a5,0xc000
    8000233a:	0ae7ec63          	bltu	a5,a4,800023f2 <growproc+0xe8>
    8000233e:	02091613          	slli	a2,s2,0x20
    80002342:	9201                	srli	a2,a2,0x20
    80002344:	1582                	slli	a1,a1,0x20
    80002346:	9181                	srli	a1,a1,0x20
    80002348:	6928                	ld	a0,80(a0)
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	1a6080e7          	jalr	422(ra) # 800014f0 <uvmalloc>
    80002352:	0005099b          	sext.w	s3,a0
    80002356:	0a098063          	beqz	s3,800023f6 <growproc+0xec>
    if (pagecopy(p->pagetable, p->kpagetable, p->sz, sz) != 0) {
    8000235a:	02051693          	slli	a3,a0,0x20
    8000235e:	9281                	srli	a3,a3,0x20
    80002360:	64b0                	ld	a2,72(s1)
    80002362:	1704b583          	ld	a1,368(s1)
    80002366:	68a8                	ld	a0,80(s1)
    80002368:	00000097          	auipc	ra,0x0
    8000236c:	9ac080e7          	jalr	-1620(ra) # 80001d14 <pagecopy>
    80002370:	e549                	bnez	a0,800023fa <growproc+0xf0>
  ukvminithard(p->kpagetable);
    80002372:	1704b503          	ld	a0,368(s1)
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	cb0080e7          	jalr	-848(ra) # 80001026 <ukvminithard>
  p->sz = sz;
    8000237e:	02099613          	slli	a2,s3,0x20
    80002382:	9201                	srli	a2,a2,0x20
    80002384:	e4b0                	sd	a2,72(s1)
  return 0;
    80002386:	4501                	li	a0,0
}
    80002388:	70a2                	ld	ra,40(sp)
    8000238a:	7402                	ld	s0,32(sp)
    8000238c:	64e2                	ld	s1,24(sp)
    8000238e:	6942                	ld	s2,16(sp)
    80002390:	69a2                	ld	s3,8(sp)
    80002392:	6145                	addi	sp,sp,48
    80002394:	8082                	ret
  } else if(n < 0){
    80002396:	fc095ee3          	bgez	s2,80002372 <growproc+0x68>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000239a:	0139063b          	addw	a2,s2,s3
    8000239e:	557d                	li	a0,-1
    800023a0:	02055913          	srli	s2,a0,0x20
    800023a4:	1602                	slli	a2,a2,0x20
    800023a6:	9201                	srli	a2,a2,0x20
    800023a8:	0125f5b3          	and	a1,a1,s2
    800023ac:	68a8                	ld	a0,80(s1)
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	0fa080e7          	jalr	250(ra) # 800014a8 <uvmdealloc>
    800023b6:	0005099b          	sext.w	s3,a0
    if (sz != p->sz) {
    800023ba:	64bc                	ld	a5,72(s1)
    800023bc:	01257533          	and	a0,a0,s2
    800023c0:	faa789e3          	beq	a5,a0,80002372 <growproc+0x68>
      uvmunmap(p->kpagetable, PGROUNDUP(sz), (PGROUNDUP(p->sz) - PGROUNDUP(sz)) / PGSIZE, 0);
    800023c4:	6585                	lui	a1,0x1
    800023c6:	35fd                	addiw	a1,a1,-1
    800023c8:	00b985bb          	addw	a1,s3,a1
    800023cc:	777d                	lui	a4,0xfffff
    800023ce:	8df9                	and	a1,a1,a4
    800023d0:	1582                	slli	a1,a1,0x20
    800023d2:	9181                	srli	a1,a1,0x20
    800023d4:	6605                	lui	a2,0x1
    800023d6:	167d                	addi	a2,a2,-1
    800023d8:	963e                	add	a2,a2,a5
    800023da:	77fd                	lui	a5,0xfffff
    800023dc:	8e7d                	and	a2,a2,a5
    800023de:	8e0d                	sub	a2,a2,a1
    800023e0:	4681                	li	a3,0
    800023e2:	8231                	srli	a2,a2,0xc
    800023e4:	1704b503          	ld	a0,368(s1)
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	f5c080e7          	jalr	-164(ra) # 80001344 <uvmunmap>
    800023f0:	b749                	j	80002372 <growproc+0x68>
      return -1;
    800023f2:	557d                	li	a0,-1
    800023f4:	bf51                	j	80002388 <growproc+0x7e>
    800023f6:	557d                	li	a0,-1
    800023f8:	bf41                	j	80002388 <growproc+0x7e>
      return -1;
    800023fa:	557d                	li	a0,-1
    800023fc:	b771                	j	80002388 <growproc+0x7e>

00000000800023fe <fork>:
{
    800023fe:	7179                	addi	sp,sp,-48
    80002400:	f406                	sd	ra,40(sp)
    80002402:	f022                	sd	s0,32(sp)
    80002404:	ec26                	sd	s1,24(sp)
    80002406:	e84a                	sd	s2,16(sp)
    80002408:	e44e                	sd	s3,8(sp)
    8000240a:	e052                	sd	s4,0(sp)
    8000240c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000240e:	00000097          	auipc	ra,0x0
    80002412:	aee080e7          	jalr	-1298(ra) # 80001efc <myproc>
    80002416:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	d0a080e7          	jalr	-758(ra) # 80002122 <allocproc>
    80002420:	10050d63          	beqz	a0,8000253a <fork+0x13c>
    80002424:	89aa                	mv	s3,a0
  np->tracemask = p->tracemask;
    80002426:	16893783          	ld	a5,360(s2) # 1168 <_entry-0x7fffee98>
    8000242a:	16f53423          	sd	a5,360(a0)
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000242e:	04893603          	ld	a2,72(s2)
    80002432:	692c                	ld	a1,80(a0)
    80002434:	05093503          	ld	a0,80(s2)
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	204080e7          	jalr	516(ra) # 8000163c <uvmcopy>
    80002440:	06054263          	bltz	a0,800024a4 <fork+0xa6>
  np->sz = p->sz;
    80002444:	04893683          	ld	a3,72(s2)
    80002448:	04d9b423          	sd	a3,72(s3) # 4000048 <_entry-0x7bffffb8>
  if (pagecopy(np->pagetable, np->kpagetable, 0, np->sz) != 0) {
    8000244c:	4601                	li	a2,0
    8000244e:	1709b583          	ld	a1,368(s3)
    80002452:	0509b503          	ld	a0,80(s3)
    80002456:	00000097          	auipc	ra,0x0
    8000245a:	8be080e7          	jalr	-1858(ra) # 80001d14 <pagecopy>
    8000245e:	ed39                	bnez	a0,800024bc <fork+0xbe>
  np->parent = p;
    80002460:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80002464:	05893683          	ld	a3,88(s2)
    80002468:	87b6                	mv	a5,a3
    8000246a:	0589b703          	ld	a4,88(s3)
    8000246e:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    80002472:	0007b803          	ld	a6,0(a5) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    80002476:	6788                	ld	a0,8(a5)
    80002478:	6b8c                	ld	a1,16(a5)
    8000247a:	6f90                	ld	a2,24(a5)
    8000247c:	01073023          	sd	a6,0(a4) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    80002480:	e708                	sd	a0,8(a4)
    80002482:	eb0c                	sd	a1,16(a4)
    80002484:	ef10                	sd	a2,24(a4)
    80002486:	02078793          	addi	a5,a5,32
    8000248a:	02070713          	addi	a4,a4,32
    8000248e:	fed792e3          	bne	a5,a3,80002472 <fork+0x74>
  np->trapframe->a0 = 0;
    80002492:	0589b783          	ld	a5,88(s3)
    80002496:	0607b823          	sd	zero,112(a5)
    8000249a:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    8000249e:	15000a13          	li	s4,336
    800024a2:	a099                	j	800024e8 <fork+0xea>
    freeproc(np);
    800024a4:	854e                	mv	a0,s3
    800024a6:	00000097          	auipc	ra,0x0
    800024aa:	c08080e7          	jalr	-1016(ra) # 800020ae <freeproc>
    release(&np->lock);
    800024ae:	854e                	mv	a0,s3
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	85e080e7          	jalr	-1954(ra) # 80000d0e <release>
    return -1;
    800024b8:	54fd                	li	s1,-1
    800024ba:	a0bd                	j	80002528 <fork+0x12a>
    freeproc(np);
    800024bc:	854e                	mv	a0,s3
    800024be:	00000097          	auipc	ra,0x0
    800024c2:	bf0080e7          	jalr	-1040(ra) # 800020ae <freeproc>
    release(&np->lock);
    800024c6:	854e                	mv	a0,s3
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	846080e7          	jalr	-1978(ra) # 80000d0e <release>
    return -1;
    800024d0:	54fd                	li	s1,-1
    800024d2:	a899                	j	80002528 <fork+0x12a>
      np->ofile[i] = filedup(p->ofile[i]);
    800024d4:	00002097          	auipc	ra,0x2
    800024d8:	74c080e7          	jalr	1868(ra) # 80004c20 <filedup>
    800024dc:	009987b3          	add	a5,s3,s1
    800024e0:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800024e2:	04a1                	addi	s1,s1,8
    800024e4:	01448763          	beq	s1,s4,800024f2 <fork+0xf4>
    if(p->ofile[i])
    800024e8:	009907b3          	add	a5,s2,s1
    800024ec:	6388                	ld	a0,0(a5)
    800024ee:	f17d                	bnez	a0,800024d4 <fork+0xd6>
    800024f0:	bfcd                	j	800024e2 <fork+0xe4>
  np->cwd = idup(p->cwd);
    800024f2:	15093503          	ld	a0,336(s2)
    800024f6:	00002097          	auipc	ra,0x2
    800024fa:	8b0080e7          	jalr	-1872(ra) # 80003da6 <idup>
    800024fe:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002502:	4641                	li	a2,16
    80002504:	15890593          	addi	a1,s2,344
    80002508:	15898513          	addi	a0,s3,344
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	9a0080e7          	jalr	-1632(ra) # 80000eac <safestrcpy>
  pid = np->pid;
    80002514:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80002518:	4789                	li	a5,2
    8000251a:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000251e:	854e                	mv	a0,s3
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	7ee080e7          	jalr	2030(ra) # 80000d0e <release>
}
    80002528:	8526                	mv	a0,s1
    8000252a:	70a2                	ld	ra,40(sp)
    8000252c:	7402                	ld	s0,32(sp)
    8000252e:	64e2                	ld	s1,24(sp)
    80002530:	6942                	ld	s2,16(sp)
    80002532:	69a2                	ld	s3,8(sp)
    80002534:	6a02                	ld	s4,0(sp)
    80002536:	6145                	addi	sp,sp,48
    80002538:	8082                	ret
    return -1;
    8000253a:	54fd                	li	s1,-1
    8000253c:	b7f5                	j	80002528 <fork+0x12a>

000000008000253e <reparent>:
{
    8000253e:	7179                	addi	sp,sp,-48
    80002540:	f406                	sd	ra,40(sp)
    80002542:	f022                	sd	s0,32(sp)
    80002544:	ec26                	sd	s1,24(sp)
    80002546:	e84a                	sd	s2,16(sp)
    80002548:	e44e                	sd	s3,8(sp)
    8000254a:	e052                	sd	s4,0(sp)
    8000254c:	1800                	addi	s0,sp,48
    8000254e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002550:	00010497          	auipc	s1,0x10
    80002554:	81848493          	addi	s1,s1,-2024 # 80011d68 <proc>
      pp->parent = initproc;
    80002558:	00007a17          	auipc	s4,0x7
    8000255c:	ac0a0a13          	addi	s4,s4,-1344 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002560:	00015997          	auipc	s3,0x15
    80002564:	60898993          	addi	s3,s3,1544 # 80017b68 <tickslock>
    80002568:	a029                	j	80002572 <reparent+0x34>
    8000256a:	17848493          	addi	s1,s1,376
    8000256e:	03348363          	beq	s1,s3,80002594 <reparent+0x56>
    if(pp->parent == p){
    80002572:	709c                	ld	a5,32(s1)
    80002574:	ff279be3          	bne	a5,s2,8000256a <reparent+0x2c>
      acquire(&pp->lock);
    80002578:	8526                	mv	a0,s1
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	6e0080e7          	jalr	1760(ra) # 80000c5a <acquire>
      pp->parent = initproc;
    80002582:	000a3783          	ld	a5,0(s4)
    80002586:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002588:	8526                	mv	a0,s1
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	784080e7          	jalr	1924(ra) # 80000d0e <release>
    80002592:	bfe1                	j	8000256a <reparent+0x2c>
}
    80002594:	70a2                	ld	ra,40(sp)
    80002596:	7402                	ld	s0,32(sp)
    80002598:	64e2                	ld	s1,24(sp)
    8000259a:	6942                	ld	s2,16(sp)
    8000259c:	69a2                	ld	s3,8(sp)
    8000259e:	6a02                	ld	s4,0(sp)
    800025a0:	6145                	addi	sp,sp,48
    800025a2:	8082                	ret

00000000800025a4 <scheduler>:
{
    800025a4:	715d                	addi	sp,sp,-80
    800025a6:	e486                	sd	ra,72(sp)
    800025a8:	e0a2                	sd	s0,64(sp)
    800025aa:	fc26                	sd	s1,56(sp)
    800025ac:	f84a                	sd	s2,48(sp)
    800025ae:	f44e                	sd	s3,40(sp)
    800025b0:	f052                	sd	s4,32(sp)
    800025b2:	ec56                	sd	s5,24(sp)
    800025b4:	e85a                	sd	s6,16(sp)
    800025b6:	e45e                	sd	s7,8(sp)
    800025b8:	e062                	sd	s8,0(sp)
    800025ba:	0880                	addi	s0,sp,80
    800025bc:	8792                	mv	a5,tp
  int id = r_tp();
    800025be:	2781                	sext.w	a5,a5
  c->proc = 0;
    800025c0:	00779b13          	slli	s6,a5,0x7
    800025c4:	0000f717          	auipc	a4,0xf
    800025c8:	38c70713          	addi	a4,a4,908 # 80011950 <pid_lock>
    800025cc:	975a                	add	a4,a4,s6
    800025ce:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    800025d2:	0000f717          	auipc	a4,0xf
    800025d6:	39e70713          	addi	a4,a4,926 # 80011970 <cpus+0x8>
    800025da:	9b3a                	add	s6,s6,a4
        c->proc = p;
    800025dc:	079e                	slli	a5,a5,0x7
    800025de:	0000fa17          	auipc	s4,0xf
    800025e2:	372a0a13          	addi	s4,s4,882 # 80011950 <pid_lock>
    800025e6:	9a3e                	add	s4,s4,a5
        w_satp(MAKE_SATP(p->kpagetable));
    800025e8:	5bfd                	li	s7,-1
    800025ea:	1bfe                	slli	s7,s7,0x3f
    for(p = proc; p < &proc[NPROC]; p++) {
    800025ec:	00015997          	auipc	s3,0x15
    800025f0:	57c98993          	addi	s3,s3,1404 # 80017b68 <tickslock>
    800025f4:	a0a5                	j	8000265c <scheduler+0xb8>
        p->state = RUNNING;
    800025f6:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    800025fa:	009a3c23          	sd	s1,24(s4)
        w_satp(MAKE_SATP(p->kpagetable));
    800025fe:	1704b783          	ld	a5,368(s1)
    80002602:	83b1                	srli	a5,a5,0xc
    80002604:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    80002608:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000260c:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    80002610:	06048593          	addi	a1,s1,96
    80002614:	855a                	mv	a0,s6
    80002616:	00000097          	auipc	ra,0x0
    8000261a:	68e080e7          	jalr	1678(ra) # 80002ca4 <swtch>
        c->proc = 0;
    8000261e:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80002622:	4c05                	li	s8,1
      release(&p->lock);
    80002624:	8526                	mv	a0,s1
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	6e8080e7          	jalr	1768(ra) # 80000d0e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000262e:	17848493          	addi	s1,s1,376
    80002632:	01348b63          	beq	s1,s3,80002648 <scheduler+0xa4>
      acquire(&p->lock);
    80002636:	8526                	mv	a0,s1
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	622080e7          	jalr	1570(ra) # 80000c5a <acquire>
      if(p->state == RUNNABLE) {
    80002640:	4c9c                	lw	a5,24(s1)
    80002642:	ff2791e3          	bne	a5,s2,80002624 <scheduler+0x80>
    80002646:	bf45                	j	800025f6 <scheduler+0x52>
    if(found == 0) {
    80002648:	000c1a63          	bnez	s8,8000265c <scheduler+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000264c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002650:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002654:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002658:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000265c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002660:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002664:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002668:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    8000266a:	0000f497          	auipc	s1,0xf
    8000266e:	6fe48493          	addi	s1,s1,1790 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002672:	4909                	li	s2,2
        p->state = RUNNING;
    80002674:	4a8d                	li	s5,3
    80002676:	b7c1                	j	80002636 <scheduler+0x92>

0000000080002678 <sched>:
{
    80002678:	7179                	addi	sp,sp,-48
    8000267a:	f406                	sd	ra,40(sp)
    8000267c:	f022                	sd	s0,32(sp)
    8000267e:	ec26                	sd	s1,24(sp)
    80002680:	e84a                	sd	s2,16(sp)
    80002682:	e44e                	sd	s3,8(sp)
    80002684:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002686:	00000097          	auipc	ra,0x0
    8000268a:	876080e7          	jalr	-1930(ra) # 80001efc <myproc>
    8000268e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002690:	ffffe097          	auipc	ra,0xffffe
    80002694:	550080e7          	jalr	1360(ra) # 80000be0 <holding>
    80002698:	c93d                	beqz	a0,8000270e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000269a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000269c:	2781                	sext.w	a5,a5
    8000269e:	079e                	slli	a5,a5,0x7
    800026a0:	0000f717          	auipc	a4,0xf
    800026a4:	2b070713          	addi	a4,a4,688 # 80011950 <pid_lock>
    800026a8:	97ba                	add	a5,a5,a4
    800026aa:	0907a703          	lw	a4,144(a5)
    800026ae:	4785                	li	a5,1
    800026b0:	06f71763          	bne	a4,a5,8000271e <sched+0xa6>
  if(p->state == RUNNING)
    800026b4:	4c98                	lw	a4,24(s1)
    800026b6:	478d                	li	a5,3
    800026b8:	06f70b63          	beq	a4,a5,8000272e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026bc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800026c0:	8b89                	andi	a5,a5,2
  if(intr_get())
    800026c2:	efb5                	bnez	a5,8000273e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800026c4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800026c6:	0000f917          	auipc	s2,0xf
    800026ca:	28a90913          	addi	s2,s2,650 # 80011950 <pid_lock>
    800026ce:	2781                	sext.w	a5,a5
    800026d0:	079e                	slli	a5,a5,0x7
    800026d2:	97ca                	add	a5,a5,s2
    800026d4:	0947a983          	lw	s3,148(a5)
    800026d8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800026da:	2781                	sext.w	a5,a5
    800026dc:	079e                	slli	a5,a5,0x7
    800026de:	0000f597          	auipc	a1,0xf
    800026e2:	29258593          	addi	a1,a1,658 # 80011970 <cpus+0x8>
    800026e6:	95be                	add	a1,a1,a5
    800026e8:	06048513          	addi	a0,s1,96
    800026ec:	00000097          	auipc	ra,0x0
    800026f0:	5b8080e7          	jalr	1464(ra) # 80002ca4 <swtch>
    800026f4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800026f6:	2781                	sext.w	a5,a5
    800026f8:	079e                	slli	a5,a5,0x7
    800026fa:	97ca                	add	a5,a5,s2
    800026fc:	0937aa23          	sw	s3,148(a5)
}
    80002700:	70a2                	ld	ra,40(sp)
    80002702:	7402                	ld	s0,32(sp)
    80002704:	64e2                	ld	s1,24(sp)
    80002706:	6942                	ld	s2,16(sp)
    80002708:	69a2                	ld	s3,8(sp)
    8000270a:	6145                	addi	sp,sp,48
    8000270c:	8082                	ret
    panic("sched p->lock");
    8000270e:	00006517          	auipc	a0,0x6
    80002712:	bfa50513          	addi	a0,a0,-1030 # 80008308 <indent.1779+0x58>
    80002716:	ffffe097          	auipc	ra,0xffffe
    8000271a:	e32080e7          	jalr	-462(ra) # 80000548 <panic>
    panic("sched locks");
    8000271e:	00006517          	auipc	a0,0x6
    80002722:	bfa50513          	addi	a0,a0,-1030 # 80008318 <indent.1779+0x68>
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	e22080e7          	jalr	-478(ra) # 80000548 <panic>
    panic("sched running");
    8000272e:	00006517          	auipc	a0,0x6
    80002732:	bfa50513          	addi	a0,a0,-1030 # 80008328 <indent.1779+0x78>
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	e12080e7          	jalr	-494(ra) # 80000548 <panic>
    panic("sched interruptible");
    8000273e:	00006517          	auipc	a0,0x6
    80002742:	bfa50513          	addi	a0,a0,-1030 # 80008338 <indent.1779+0x88>
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	e02080e7          	jalr	-510(ra) # 80000548 <panic>

000000008000274e <exit>:
{
    8000274e:	7179                	addi	sp,sp,-48
    80002750:	f406                	sd	ra,40(sp)
    80002752:	f022                	sd	s0,32(sp)
    80002754:	ec26                	sd	s1,24(sp)
    80002756:	e84a                	sd	s2,16(sp)
    80002758:	e44e                	sd	s3,8(sp)
    8000275a:	e052                	sd	s4,0(sp)
    8000275c:	1800                	addi	s0,sp,48
    8000275e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002760:	fffff097          	auipc	ra,0xfffff
    80002764:	79c080e7          	jalr	1948(ra) # 80001efc <myproc>
    80002768:	89aa                	mv	s3,a0
  if(p == initproc)
    8000276a:	00007797          	auipc	a5,0x7
    8000276e:	8ae7b783          	ld	a5,-1874(a5) # 80009018 <initproc>
    80002772:	0d050493          	addi	s1,a0,208
    80002776:	15050913          	addi	s2,a0,336
    8000277a:	02a79363          	bne	a5,a0,800027a0 <exit+0x52>
    panic("init exiting");
    8000277e:	00006517          	auipc	a0,0x6
    80002782:	bd250513          	addi	a0,a0,-1070 # 80008350 <indent.1779+0xa0>
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	dc2080e7          	jalr	-574(ra) # 80000548 <panic>
      fileclose(f);
    8000278e:	00002097          	auipc	ra,0x2
    80002792:	4e4080e7          	jalr	1252(ra) # 80004c72 <fileclose>
      p->ofile[fd] = 0;
    80002796:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000279a:	04a1                	addi	s1,s1,8
    8000279c:	01248563          	beq	s1,s2,800027a6 <exit+0x58>
    if(p->ofile[fd]){
    800027a0:	6088                	ld	a0,0(s1)
    800027a2:	f575                	bnez	a0,8000278e <exit+0x40>
    800027a4:	bfdd                	j	8000279a <exit+0x4c>
  begin_op();
    800027a6:	00002097          	auipc	ra,0x2
    800027aa:	ffa080e7          	jalr	-6(ra) # 800047a0 <begin_op>
  iput(p->cwd);
    800027ae:	1509b503          	ld	a0,336(s3)
    800027b2:	00001097          	auipc	ra,0x1
    800027b6:	7ec080e7          	jalr	2028(ra) # 80003f9e <iput>
  end_op();
    800027ba:	00002097          	auipc	ra,0x2
    800027be:	066080e7          	jalr	102(ra) # 80004820 <end_op>
  p->cwd = 0;
    800027c2:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800027c6:	00007497          	auipc	s1,0x7
    800027ca:	85248493          	addi	s1,s1,-1966 # 80009018 <initproc>
    800027ce:	6088                	ld	a0,0(s1)
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	48a080e7          	jalr	1162(ra) # 80000c5a <acquire>
  wakeup1(initproc);
    800027d8:	6088                	ld	a0,0(s1)
    800027da:	fffff097          	auipc	ra,0xfffff
    800027de:	5e2080e7          	jalr	1506(ra) # 80001dbc <wakeup1>
  release(&initproc->lock);
    800027e2:	6088                	ld	a0,0(s1)
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	52a080e7          	jalr	1322(ra) # 80000d0e <release>
  acquire(&p->lock);
    800027ec:	854e                	mv	a0,s3
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	46c080e7          	jalr	1132(ra) # 80000c5a <acquire>
  struct proc *original_parent = p->parent;
    800027f6:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800027fa:	854e                	mv	a0,s3
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	512080e7          	jalr	1298(ra) # 80000d0e <release>
  acquire(&original_parent->lock);
    80002804:	8526                	mv	a0,s1
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	454080e7          	jalr	1108(ra) # 80000c5a <acquire>
  acquire(&p->lock);
    8000280e:	854e                	mv	a0,s3
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	44a080e7          	jalr	1098(ra) # 80000c5a <acquire>
  reparent(p);
    80002818:	854e                	mv	a0,s3
    8000281a:	00000097          	auipc	ra,0x0
    8000281e:	d24080e7          	jalr	-732(ra) # 8000253e <reparent>
  wakeup1(original_parent);
    80002822:	8526                	mv	a0,s1
    80002824:	fffff097          	auipc	ra,0xfffff
    80002828:	598080e7          	jalr	1432(ra) # 80001dbc <wakeup1>
  p->xstate = status;
    8000282c:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002830:	4791                	li	a5,4
    80002832:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002836:	8526                	mv	a0,s1
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	4d6080e7          	jalr	1238(ra) # 80000d0e <release>
  sched();
    80002840:	00000097          	auipc	ra,0x0
    80002844:	e38080e7          	jalr	-456(ra) # 80002678 <sched>
  panic("zombie exit");
    80002848:	00006517          	auipc	a0,0x6
    8000284c:	b1850513          	addi	a0,a0,-1256 # 80008360 <indent.1779+0xb0>
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	cf8080e7          	jalr	-776(ra) # 80000548 <panic>

0000000080002858 <yield>:
{
    80002858:	1101                	addi	sp,sp,-32
    8000285a:	ec06                	sd	ra,24(sp)
    8000285c:	e822                	sd	s0,16(sp)
    8000285e:	e426                	sd	s1,8(sp)
    80002860:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002862:	fffff097          	auipc	ra,0xfffff
    80002866:	69a080e7          	jalr	1690(ra) # 80001efc <myproc>
    8000286a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	3ee080e7          	jalr	1006(ra) # 80000c5a <acquire>
  p->state = RUNNABLE;
    80002874:	4789                	li	a5,2
    80002876:	cc9c                	sw	a5,24(s1)
  sched();
    80002878:	00000097          	auipc	ra,0x0
    8000287c:	e00080e7          	jalr	-512(ra) # 80002678 <sched>
  release(&p->lock);
    80002880:	8526                	mv	a0,s1
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	48c080e7          	jalr	1164(ra) # 80000d0e <release>
}
    8000288a:	60e2                	ld	ra,24(sp)
    8000288c:	6442                	ld	s0,16(sp)
    8000288e:	64a2                	ld	s1,8(sp)
    80002890:	6105                	addi	sp,sp,32
    80002892:	8082                	ret

0000000080002894 <sleep>:
{
    80002894:	7179                	addi	sp,sp,-48
    80002896:	f406                	sd	ra,40(sp)
    80002898:	f022                	sd	s0,32(sp)
    8000289a:	ec26                	sd	s1,24(sp)
    8000289c:	e84a                	sd	s2,16(sp)
    8000289e:	e44e                	sd	s3,8(sp)
    800028a0:	1800                	addi	s0,sp,48
    800028a2:	89aa                	mv	s3,a0
    800028a4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800028a6:	fffff097          	auipc	ra,0xfffff
    800028aa:	656080e7          	jalr	1622(ra) # 80001efc <myproc>
    800028ae:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800028b0:	05250663          	beq	a0,s2,800028fc <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	3a6080e7          	jalr	934(ra) # 80000c5a <acquire>
    release(lk);
    800028bc:	854a                	mv	a0,s2
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	450080e7          	jalr	1104(ra) # 80000d0e <release>
  p->chan = chan;
    800028c6:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800028ca:	4785                	li	a5,1
    800028cc:	cc9c                	sw	a5,24(s1)
  sched();
    800028ce:	00000097          	auipc	ra,0x0
    800028d2:	daa080e7          	jalr	-598(ra) # 80002678 <sched>
  p->chan = 0;
    800028d6:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800028da:	8526                	mv	a0,s1
    800028dc:	ffffe097          	auipc	ra,0xffffe
    800028e0:	432080e7          	jalr	1074(ra) # 80000d0e <release>
    acquire(lk);
    800028e4:	854a                	mv	a0,s2
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	374080e7          	jalr	884(ra) # 80000c5a <acquire>
}
    800028ee:	70a2                	ld	ra,40(sp)
    800028f0:	7402                	ld	s0,32(sp)
    800028f2:	64e2                	ld	s1,24(sp)
    800028f4:	6942                	ld	s2,16(sp)
    800028f6:	69a2                	ld	s3,8(sp)
    800028f8:	6145                	addi	sp,sp,48
    800028fa:	8082                	ret
  p->chan = chan;
    800028fc:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002900:	4785                	li	a5,1
    80002902:	cd1c                	sw	a5,24(a0)
  sched();
    80002904:	00000097          	auipc	ra,0x0
    80002908:	d74080e7          	jalr	-652(ra) # 80002678 <sched>
  p->chan = 0;
    8000290c:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002910:	bff9                	j	800028ee <sleep+0x5a>

0000000080002912 <wait>:
{
    80002912:	715d                	addi	sp,sp,-80
    80002914:	e486                	sd	ra,72(sp)
    80002916:	e0a2                	sd	s0,64(sp)
    80002918:	fc26                	sd	s1,56(sp)
    8000291a:	f84a                	sd	s2,48(sp)
    8000291c:	f44e                	sd	s3,40(sp)
    8000291e:	f052                	sd	s4,32(sp)
    80002920:	ec56                	sd	s5,24(sp)
    80002922:	e85a                	sd	s6,16(sp)
    80002924:	e45e                	sd	s7,8(sp)
    80002926:	e062                	sd	s8,0(sp)
    80002928:	0880                	addi	s0,sp,80
    8000292a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000292c:	fffff097          	auipc	ra,0xfffff
    80002930:	5d0080e7          	jalr	1488(ra) # 80001efc <myproc>
    80002934:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002936:	8c2a                	mv	s8,a0
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	322080e7          	jalr	802(ra) # 80000c5a <acquire>
    havekids = 0;
    80002940:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002942:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002944:	00015997          	auipc	s3,0x15
    80002948:	22498993          	addi	s3,s3,548 # 80017b68 <tickslock>
        havekids = 1;
    8000294c:	4a85                	li	s5,1
    havekids = 0;
    8000294e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002950:	0000f497          	auipc	s1,0xf
    80002954:	41848493          	addi	s1,s1,1048 # 80011d68 <proc>
    80002958:	a08d                	j	800029ba <wait+0xa8>
          pid = np->pid;
    8000295a:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000295e:	000b0e63          	beqz	s6,8000297a <wait+0x68>
    80002962:	4691                	li	a3,4
    80002964:	03448613          	addi	a2,s1,52
    80002968:	85da                	mv	a1,s6
    8000296a:	05093503          	ld	a0,80(s2)
    8000296e:	fffff097          	auipc	ra,0xfffff
    80002972:	dd2080e7          	jalr	-558(ra) # 80001740 <copyout>
    80002976:	02054263          	bltz	a0,8000299a <wait+0x88>
          freeproc(np);
    8000297a:	8526                	mv	a0,s1
    8000297c:	fffff097          	auipc	ra,0xfffff
    80002980:	732080e7          	jalr	1842(ra) # 800020ae <freeproc>
          release(&np->lock);
    80002984:	8526                	mv	a0,s1
    80002986:	ffffe097          	auipc	ra,0xffffe
    8000298a:	388080e7          	jalr	904(ra) # 80000d0e <release>
          release(&p->lock);
    8000298e:	854a                	mv	a0,s2
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	37e080e7          	jalr	894(ra) # 80000d0e <release>
          return pid;
    80002998:	a8a9                	j	800029f2 <wait+0xe0>
            release(&np->lock);
    8000299a:	8526                	mv	a0,s1
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	372080e7          	jalr	882(ra) # 80000d0e <release>
            release(&p->lock);
    800029a4:	854a                	mv	a0,s2
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	368080e7          	jalr	872(ra) # 80000d0e <release>
            return -1;
    800029ae:	59fd                	li	s3,-1
    800029b0:	a089                	j	800029f2 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800029b2:	17848493          	addi	s1,s1,376
    800029b6:	03348463          	beq	s1,s3,800029de <wait+0xcc>
      if(np->parent == p){
    800029ba:	709c                	ld	a5,32(s1)
    800029bc:	ff279be3          	bne	a5,s2,800029b2 <wait+0xa0>
        acquire(&np->lock);
    800029c0:	8526                	mv	a0,s1
    800029c2:	ffffe097          	auipc	ra,0xffffe
    800029c6:	298080e7          	jalr	664(ra) # 80000c5a <acquire>
        if(np->state == ZOMBIE){
    800029ca:	4c9c                	lw	a5,24(s1)
    800029cc:	f94787e3          	beq	a5,s4,8000295a <wait+0x48>
        release(&np->lock);
    800029d0:	8526                	mv	a0,s1
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	33c080e7          	jalr	828(ra) # 80000d0e <release>
        havekids = 1;
    800029da:	8756                	mv	a4,s5
    800029dc:	bfd9                	j	800029b2 <wait+0xa0>
    if(!havekids || p->killed){
    800029de:	c701                	beqz	a4,800029e6 <wait+0xd4>
    800029e0:	03092783          	lw	a5,48(s2)
    800029e4:	c785                	beqz	a5,80002a0c <wait+0xfa>
      release(&p->lock);
    800029e6:	854a                	mv	a0,s2
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	326080e7          	jalr	806(ra) # 80000d0e <release>
      return -1;
    800029f0:	59fd                	li	s3,-1
}
    800029f2:	854e                	mv	a0,s3
    800029f4:	60a6                	ld	ra,72(sp)
    800029f6:	6406                	ld	s0,64(sp)
    800029f8:	74e2                	ld	s1,56(sp)
    800029fa:	7942                	ld	s2,48(sp)
    800029fc:	79a2                	ld	s3,40(sp)
    800029fe:	7a02                	ld	s4,32(sp)
    80002a00:	6ae2                	ld	s5,24(sp)
    80002a02:	6b42                	ld	s6,16(sp)
    80002a04:	6ba2                	ld	s7,8(sp)
    80002a06:	6c02                	ld	s8,0(sp)
    80002a08:	6161                	addi	sp,sp,80
    80002a0a:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002a0c:	85e2                	mv	a1,s8
    80002a0e:	854a                	mv	a0,s2
    80002a10:	00000097          	auipc	ra,0x0
    80002a14:	e84080e7          	jalr	-380(ra) # 80002894 <sleep>
    havekids = 0;
    80002a18:	bf1d                	j	8000294e <wait+0x3c>

0000000080002a1a <wakeup>:
{
    80002a1a:	7139                	addi	sp,sp,-64
    80002a1c:	fc06                	sd	ra,56(sp)
    80002a1e:	f822                	sd	s0,48(sp)
    80002a20:	f426                	sd	s1,40(sp)
    80002a22:	f04a                	sd	s2,32(sp)
    80002a24:	ec4e                	sd	s3,24(sp)
    80002a26:	e852                	sd	s4,16(sp)
    80002a28:	e456                	sd	s5,8(sp)
    80002a2a:	0080                	addi	s0,sp,64
    80002a2c:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002a2e:	0000f497          	auipc	s1,0xf
    80002a32:	33a48493          	addi	s1,s1,826 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002a36:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002a38:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002a3a:	00015917          	auipc	s2,0x15
    80002a3e:	12e90913          	addi	s2,s2,302 # 80017b68 <tickslock>
    80002a42:	a821                	j	80002a5a <wakeup+0x40>
      p->state = RUNNABLE;
    80002a44:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002a48:	8526                	mv	a0,s1
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	2c4080e7          	jalr	708(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002a52:	17848493          	addi	s1,s1,376
    80002a56:	01248e63          	beq	s1,s2,80002a72 <wakeup+0x58>
    acquire(&p->lock);
    80002a5a:	8526                	mv	a0,s1
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	1fe080e7          	jalr	510(ra) # 80000c5a <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002a64:	4c9c                	lw	a5,24(s1)
    80002a66:	ff3791e3          	bne	a5,s3,80002a48 <wakeup+0x2e>
    80002a6a:	749c                	ld	a5,40(s1)
    80002a6c:	fd479ee3          	bne	a5,s4,80002a48 <wakeup+0x2e>
    80002a70:	bfd1                	j	80002a44 <wakeup+0x2a>
}
    80002a72:	70e2                	ld	ra,56(sp)
    80002a74:	7442                	ld	s0,48(sp)
    80002a76:	74a2                	ld	s1,40(sp)
    80002a78:	7902                	ld	s2,32(sp)
    80002a7a:	69e2                	ld	s3,24(sp)
    80002a7c:	6a42                	ld	s4,16(sp)
    80002a7e:	6aa2                	ld	s5,8(sp)
    80002a80:	6121                	addi	sp,sp,64
    80002a82:	8082                	ret

0000000080002a84 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002a84:	7179                	addi	sp,sp,-48
    80002a86:	f406                	sd	ra,40(sp)
    80002a88:	f022                	sd	s0,32(sp)
    80002a8a:	ec26                	sd	s1,24(sp)
    80002a8c:	e84a                	sd	s2,16(sp)
    80002a8e:	e44e                	sd	s3,8(sp)
    80002a90:	1800                	addi	s0,sp,48
    80002a92:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002a94:	0000f497          	auipc	s1,0xf
    80002a98:	2d448493          	addi	s1,s1,724 # 80011d68 <proc>
    80002a9c:	00015997          	auipc	s3,0x15
    80002aa0:	0cc98993          	addi	s3,s3,204 # 80017b68 <tickslock>
    acquire(&p->lock);
    80002aa4:	8526                	mv	a0,s1
    80002aa6:	ffffe097          	auipc	ra,0xffffe
    80002aaa:	1b4080e7          	jalr	436(ra) # 80000c5a <acquire>
    if(p->pid == pid){
    80002aae:	5c9c                	lw	a5,56(s1)
    80002ab0:	01278d63          	beq	a5,s2,80002aca <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002ab4:	8526                	mv	a0,s1
    80002ab6:	ffffe097          	auipc	ra,0xffffe
    80002aba:	258080e7          	jalr	600(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002abe:	17848493          	addi	s1,s1,376
    80002ac2:	ff3491e3          	bne	s1,s3,80002aa4 <kill+0x20>
  }
  return -1;
    80002ac6:	557d                	li	a0,-1
    80002ac8:	a829                	j	80002ae2 <kill+0x5e>
      p->killed = 1;
    80002aca:	4785                	li	a5,1
    80002acc:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002ace:	4c98                	lw	a4,24(s1)
    80002ad0:	4785                	li	a5,1
    80002ad2:	00f70f63          	beq	a4,a5,80002af0 <kill+0x6c>
      release(&p->lock);
    80002ad6:	8526                	mv	a0,s1
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	236080e7          	jalr	566(ra) # 80000d0e <release>
      return 0;
    80002ae0:	4501                	li	a0,0
}
    80002ae2:	70a2                	ld	ra,40(sp)
    80002ae4:	7402                	ld	s0,32(sp)
    80002ae6:	64e2                	ld	s1,24(sp)
    80002ae8:	6942                	ld	s2,16(sp)
    80002aea:	69a2                	ld	s3,8(sp)
    80002aec:	6145                	addi	sp,sp,48
    80002aee:	8082                	ret
        p->state = RUNNABLE;
    80002af0:	4789                	li	a5,2
    80002af2:	cc9c                	sw	a5,24(s1)
    80002af4:	b7cd                	j	80002ad6 <kill+0x52>

0000000080002af6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002af6:	7179                	addi	sp,sp,-48
    80002af8:	f406                	sd	ra,40(sp)
    80002afa:	f022                	sd	s0,32(sp)
    80002afc:	ec26                	sd	s1,24(sp)
    80002afe:	e84a                	sd	s2,16(sp)
    80002b00:	e44e                	sd	s3,8(sp)
    80002b02:	e052                	sd	s4,0(sp)
    80002b04:	1800                	addi	s0,sp,48
    80002b06:	84aa                	mv	s1,a0
    80002b08:	892e                	mv	s2,a1
    80002b0a:	89b2                	mv	s3,a2
    80002b0c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	3ee080e7          	jalr	1006(ra) # 80001efc <myproc>
  if(user_dst){
    80002b16:	c08d                	beqz	s1,80002b38 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002b18:	86d2                	mv	a3,s4
    80002b1a:	864e                	mv	a2,s3
    80002b1c:	85ca                	mv	a1,s2
    80002b1e:	6928                	ld	a0,80(a0)
    80002b20:	fffff097          	auipc	ra,0xfffff
    80002b24:	c20080e7          	jalr	-992(ra) # 80001740 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002b28:	70a2                	ld	ra,40(sp)
    80002b2a:	7402                	ld	s0,32(sp)
    80002b2c:	64e2                	ld	s1,24(sp)
    80002b2e:	6942                	ld	s2,16(sp)
    80002b30:	69a2                	ld	s3,8(sp)
    80002b32:	6a02                	ld	s4,0(sp)
    80002b34:	6145                	addi	sp,sp,48
    80002b36:	8082                	ret
    memmove((char *)dst, src, len);
    80002b38:	000a061b          	sext.w	a2,s4
    80002b3c:	85ce                	mv	a1,s3
    80002b3e:	854a                	mv	a0,s2
    80002b40:	ffffe097          	auipc	ra,0xffffe
    80002b44:	276080e7          	jalr	630(ra) # 80000db6 <memmove>
    return 0;
    80002b48:	8526                	mv	a0,s1
    80002b4a:	bff9                	j	80002b28 <either_copyout+0x32>

0000000080002b4c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002b4c:	7179                	addi	sp,sp,-48
    80002b4e:	f406                	sd	ra,40(sp)
    80002b50:	f022                	sd	s0,32(sp)
    80002b52:	ec26                	sd	s1,24(sp)
    80002b54:	e84a                	sd	s2,16(sp)
    80002b56:	e44e                	sd	s3,8(sp)
    80002b58:	e052                	sd	s4,0(sp)
    80002b5a:	1800                	addi	s0,sp,48
    80002b5c:	892a                	mv	s2,a0
    80002b5e:	84ae                	mv	s1,a1
    80002b60:	89b2                	mv	s3,a2
    80002b62:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002b64:	fffff097          	auipc	ra,0xfffff
    80002b68:	398080e7          	jalr	920(ra) # 80001efc <myproc>
  if(user_src){
    80002b6c:	c08d                	beqz	s1,80002b8e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002b6e:	86d2                	mv	a3,s4
    80002b70:	864e                	mv	a2,s3
    80002b72:	85ca                	mv	a1,s2
    80002b74:	6928                	ld	a0,80(a0)
    80002b76:	fffff097          	auipc	ra,0xfffff
    80002b7a:	c56080e7          	jalr	-938(ra) # 800017cc <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002b7e:	70a2                	ld	ra,40(sp)
    80002b80:	7402                	ld	s0,32(sp)
    80002b82:	64e2                	ld	s1,24(sp)
    80002b84:	6942                	ld	s2,16(sp)
    80002b86:	69a2                	ld	s3,8(sp)
    80002b88:	6a02                	ld	s4,0(sp)
    80002b8a:	6145                	addi	sp,sp,48
    80002b8c:	8082                	ret
    memmove(dst, (char*)src, len);
    80002b8e:	000a061b          	sext.w	a2,s4
    80002b92:	85ce                	mv	a1,s3
    80002b94:	854a                	mv	a0,s2
    80002b96:	ffffe097          	auipc	ra,0xffffe
    80002b9a:	220080e7          	jalr	544(ra) # 80000db6 <memmove>
    return 0;
    80002b9e:	8526                	mv	a0,s1
    80002ba0:	bff9                	j	80002b7e <either_copyin+0x32>

0000000080002ba2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002ba2:	715d                	addi	sp,sp,-80
    80002ba4:	e486                	sd	ra,72(sp)
    80002ba6:	e0a2                	sd	s0,64(sp)
    80002ba8:	fc26                	sd	s1,56(sp)
    80002baa:	f84a                	sd	s2,48(sp)
    80002bac:	f44e                	sd	s3,40(sp)
    80002bae:	f052                	sd	s4,32(sp)
    80002bb0:	ec56                	sd	s5,24(sp)
    80002bb2:	e85a                	sd	s6,16(sp)
    80002bb4:	e45e                	sd	s7,8(sp)
    80002bb6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002bb8:	00005517          	auipc	a0,0x5
    80002bbc:	51050513          	addi	a0,a0,1296 # 800080c8 <digits+0x88>
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	9d2080e7          	jalr	-1582(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002bc8:	0000f497          	auipc	s1,0xf
    80002bcc:	2f848493          	addi	s1,s1,760 # 80011ec0 <proc+0x158>
    80002bd0:	00015917          	auipc	s2,0x15
    80002bd4:	0f090913          	addi	s2,s2,240 # 80017cc0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bd8:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002bda:	00005997          	auipc	s3,0x5
    80002bde:	79698993          	addi	s3,s3,1942 # 80008370 <indent.1779+0xc0>
    printf("%d %s %s", p->pid, state, p->name);
    80002be2:	00005a97          	auipc	s5,0x5
    80002be6:	796a8a93          	addi	s5,s5,1942 # 80008378 <indent.1779+0xc8>
    printf("\n");
    80002bea:	00005a17          	auipc	s4,0x5
    80002bee:	4dea0a13          	addi	s4,s4,1246 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bf2:	00005b97          	auipc	s7,0x5
    80002bf6:	7beb8b93          	addi	s7,s7,1982 # 800083b0 <states.1740>
    80002bfa:	a00d                	j	80002c1c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002bfc:	ee06a583          	lw	a1,-288(a3)
    80002c00:	8556                	mv	a0,s5
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	990080e7          	jalr	-1648(ra) # 80000592 <printf>
    printf("\n");
    80002c0a:	8552                	mv	a0,s4
    80002c0c:	ffffe097          	auipc	ra,0xffffe
    80002c10:	986080e7          	jalr	-1658(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002c14:	17848493          	addi	s1,s1,376
    80002c18:	03248163          	beq	s1,s2,80002c3a <procdump+0x98>
    if(p->state == UNUSED)
    80002c1c:	86a6                	mv	a3,s1
    80002c1e:	ec04a783          	lw	a5,-320(s1)
    80002c22:	dbed                	beqz	a5,80002c14 <procdump+0x72>
      state = "???";
    80002c24:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c26:	fcfb6be3          	bltu	s6,a5,80002bfc <procdump+0x5a>
    80002c2a:	1782                	slli	a5,a5,0x20
    80002c2c:	9381                	srli	a5,a5,0x20
    80002c2e:	078e                	slli	a5,a5,0x3
    80002c30:	97de                	add	a5,a5,s7
    80002c32:	6390                	ld	a2,0(a5)
    80002c34:	f661                	bnez	a2,80002bfc <procdump+0x5a>
      state = "???";
    80002c36:	864e                	mv	a2,s3
    80002c38:	b7d1                	j	80002bfc <procdump+0x5a>
  }
}
    80002c3a:	60a6                	ld	ra,72(sp)
    80002c3c:	6406                	ld	s0,64(sp)
    80002c3e:	74e2                	ld	s1,56(sp)
    80002c40:	7942                	ld	s2,48(sp)
    80002c42:	79a2                	ld	s3,40(sp)
    80002c44:	7a02                	ld	s4,32(sp)
    80002c46:	6ae2                	ld	s5,24(sp)
    80002c48:	6b42                	ld	s6,16(sp)
    80002c4a:	6ba2                	ld	s7,8(sp)
    80002c4c:	6161                	addi	sp,sp,80
    80002c4e:	8082                	ret

0000000080002c50 <count_free_proc>:

// Count how many processes are not in the state of UNUSED
uint64
count_free_proc(void) {
    80002c50:	7179                	addi	sp,sp,-48
    80002c52:	f406                	sd	ra,40(sp)
    80002c54:	f022                	sd	s0,32(sp)
    80002c56:	ec26                	sd	s1,24(sp)
    80002c58:	e84a                	sd	s2,16(sp)
    80002c5a:	e44e                	sd	s3,8(sp)
    80002c5c:	1800                	addi	s0,sp,48
  struct proc *p;
  uint64 count = 0;
    80002c5e:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002c60:	0000f497          	auipc	s1,0xf
    80002c64:	10848493          	addi	s1,s1,264 # 80011d68 <proc>
    80002c68:	00015997          	auipc	s3,0x15
    80002c6c:	f0098993          	addi	s3,s3,-256 # 80017b68 <tickslock>
    acquire(&p->lock);
    80002c70:	8526                	mv	a0,s1
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	fe8080e7          	jalr	-24(ra) # 80000c5a <acquire>
    if(p->state != UNUSED) {
    80002c7a:	4c9c                	lw	a5,24(s1)
      count += 1;
    80002c7c:	00f037b3          	snez	a5,a5
    80002c80:	993e                	add	s2,s2,a5
    }
    release(&p->lock);
    80002c82:	8526                	mv	a0,s1
    80002c84:	ffffe097          	auipc	ra,0xffffe
    80002c88:	08a080e7          	jalr	138(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002c8c:	17848493          	addi	s1,s1,376
    80002c90:	ff3490e3          	bne	s1,s3,80002c70 <count_free_proc+0x20>
  }
  return count;
}
    80002c94:	854a                	mv	a0,s2
    80002c96:	70a2                	ld	ra,40(sp)
    80002c98:	7402                	ld	s0,32(sp)
    80002c9a:	64e2                	ld	s1,24(sp)
    80002c9c:	6942                	ld	s2,16(sp)
    80002c9e:	69a2                	ld	s3,8(sp)
    80002ca0:	6145                	addi	sp,sp,48
    80002ca2:	8082                	ret

0000000080002ca4 <swtch>:
    80002ca4:	00153023          	sd	ra,0(a0)
    80002ca8:	00253423          	sd	sp,8(a0)
    80002cac:	e900                	sd	s0,16(a0)
    80002cae:	ed04                	sd	s1,24(a0)
    80002cb0:	03253023          	sd	s2,32(a0)
    80002cb4:	03353423          	sd	s3,40(a0)
    80002cb8:	03453823          	sd	s4,48(a0)
    80002cbc:	03553c23          	sd	s5,56(a0)
    80002cc0:	05653023          	sd	s6,64(a0)
    80002cc4:	05753423          	sd	s7,72(a0)
    80002cc8:	05853823          	sd	s8,80(a0)
    80002ccc:	05953c23          	sd	s9,88(a0)
    80002cd0:	07a53023          	sd	s10,96(a0)
    80002cd4:	07b53423          	sd	s11,104(a0)
    80002cd8:	0005b083          	ld	ra,0(a1)
    80002cdc:	0085b103          	ld	sp,8(a1)
    80002ce0:	6980                	ld	s0,16(a1)
    80002ce2:	6d84                	ld	s1,24(a1)
    80002ce4:	0205b903          	ld	s2,32(a1)
    80002ce8:	0285b983          	ld	s3,40(a1)
    80002cec:	0305ba03          	ld	s4,48(a1)
    80002cf0:	0385ba83          	ld	s5,56(a1)
    80002cf4:	0405bb03          	ld	s6,64(a1)
    80002cf8:	0485bb83          	ld	s7,72(a1)
    80002cfc:	0505bc03          	ld	s8,80(a1)
    80002d00:	0585bc83          	ld	s9,88(a1)
    80002d04:	0605bd03          	ld	s10,96(a1)
    80002d08:	0685bd83          	ld	s11,104(a1)
    80002d0c:	8082                	ret

0000000080002d0e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002d0e:	1141                	addi	sp,sp,-16
    80002d10:	e406                	sd	ra,8(sp)
    80002d12:	e022                	sd	s0,0(sp)
    80002d14:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002d16:	00005597          	auipc	a1,0x5
    80002d1a:	6c258593          	addi	a1,a1,1730 # 800083d8 <states.1740+0x28>
    80002d1e:	00015517          	auipc	a0,0x15
    80002d22:	e4a50513          	addi	a0,a0,-438 # 80017b68 <tickslock>
    80002d26:	ffffe097          	auipc	ra,0xffffe
    80002d2a:	ea4080e7          	jalr	-348(ra) # 80000bca <initlock>
}
    80002d2e:	60a2                	ld	ra,8(sp)
    80002d30:	6402                	ld	s0,0(sp)
    80002d32:	0141                	addi	sp,sp,16
    80002d34:	8082                	ret

0000000080002d36 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002d36:	1141                	addi	sp,sp,-16
    80002d38:	e422                	sd	s0,8(sp)
    80002d3a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d3c:	00003797          	auipc	a5,0x3
    80002d40:	5b478793          	addi	a5,a5,1460 # 800062f0 <kernelvec>
    80002d44:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002d48:	6422                	ld	s0,8(sp)
    80002d4a:	0141                	addi	sp,sp,16
    80002d4c:	8082                	ret

0000000080002d4e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002d4e:	1141                	addi	sp,sp,-16
    80002d50:	e406                	sd	ra,8(sp)
    80002d52:	e022                	sd	s0,0(sp)
    80002d54:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	1a6080e7          	jalr	422(ra) # 80001efc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d5e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d62:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d64:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002d68:	00004617          	auipc	a2,0x4
    80002d6c:	29860613          	addi	a2,a2,664 # 80007000 <_trampoline>
    80002d70:	00004697          	auipc	a3,0x4
    80002d74:	29068693          	addi	a3,a3,656 # 80007000 <_trampoline>
    80002d78:	8e91                	sub	a3,a3,a2
    80002d7a:	040007b7          	lui	a5,0x4000
    80002d7e:	17fd                	addi	a5,a5,-1
    80002d80:	07b2                	slli	a5,a5,0xc
    80002d82:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d84:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d88:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d8a:	180026f3          	csrr	a3,satp
    80002d8e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d90:	6d38                	ld	a4,88(a0)
    80002d92:	6134                	ld	a3,64(a0)
    80002d94:	6585                	lui	a1,0x1
    80002d96:	96ae                	add	a3,a3,a1
    80002d98:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d9a:	6d38                	ld	a4,88(a0)
    80002d9c:	00000697          	auipc	a3,0x0
    80002da0:	13868693          	addi	a3,a3,312 # 80002ed4 <usertrap>
    80002da4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002da6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002da8:	8692                	mv	a3,tp
    80002daa:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dac:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002db0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002db4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002db8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002dbc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dbe:	6f18                	ld	a4,24(a4)
    80002dc0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002dc4:	692c                	ld	a1,80(a0)
    80002dc6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002dc8:	00004717          	auipc	a4,0x4
    80002dcc:	2c870713          	addi	a4,a4,712 # 80007090 <userret>
    80002dd0:	8f11                	sub	a4,a4,a2
    80002dd2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002dd4:	577d                	li	a4,-1
    80002dd6:	177e                	slli	a4,a4,0x3f
    80002dd8:	8dd9                	or	a1,a1,a4
    80002dda:	02000537          	lui	a0,0x2000
    80002dde:	157d                	addi	a0,a0,-1
    80002de0:	0536                	slli	a0,a0,0xd
    80002de2:	9782                	jalr	a5
}
    80002de4:	60a2                	ld	ra,8(sp)
    80002de6:	6402                	ld	s0,0(sp)
    80002de8:	0141                	addi	sp,sp,16
    80002dea:	8082                	ret

0000000080002dec <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002dec:	1101                	addi	sp,sp,-32
    80002dee:	ec06                	sd	ra,24(sp)
    80002df0:	e822                	sd	s0,16(sp)
    80002df2:	e426                	sd	s1,8(sp)
    80002df4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002df6:	00015497          	auipc	s1,0x15
    80002dfa:	d7248493          	addi	s1,s1,-654 # 80017b68 <tickslock>
    80002dfe:	8526                	mv	a0,s1
    80002e00:	ffffe097          	auipc	ra,0xffffe
    80002e04:	e5a080e7          	jalr	-422(ra) # 80000c5a <acquire>
  ticks++;
    80002e08:	00006517          	auipc	a0,0x6
    80002e0c:	21850513          	addi	a0,a0,536 # 80009020 <ticks>
    80002e10:	411c                	lw	a5,0(a0)
    80002e12:	2785                	addiw	a5,a5,1
    80002e14:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002e16:	00000097          	auipc	ra,0x0
    80002e1a:	c04080e7          	jalr	-1020(ra) # 80002a1a <wakeup>
  release(&tickslock);
    80002e1e:	8526                	mv	a0,s1
    80002e20:	ffffe097          	auipc	ra,0xffffe
    80002e24:	eee080e7          	jalr	-274(ra) # 80000d0e <release>
}
    80002e28:	60e2                	ld	ra,24(sp)
    80002e2a:	6442                	ld	s0,16(sp)
    80002e2c:	64a2                	ld	s1,8(sp)
    80002e2e:	6105                	addi	sp,sp,32
    80002e30:	8082                	ret

0000000080002e32 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002e32:	1101                	addi	sp,sp,-32
    80002e34:	ec06                	sd	ra,24(sp)
    80002e36:	e822                	sd	s0,16(sp)
    80002e38:	e426                	sd	s1,8(sp)
    80002e3a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e3c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002e40:	00074d63          	bltz	a4,80002e5a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002e44:	57fd                	li	a5,-1
    80002e46:	17fe                	slli	a5,a5,0x3f
    80002e48:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002e4a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002e4c:	06f70363          	beq	a4,a5,80002eb2 <devintr+0x80>
  }
}
    80002e50:	60e2                	ld	ra,24(sp)
    80002e52:	6442                	ld	s0,16(sp)
    80002e54:	64a2                	ld	s1,8(sp)
    80002e56:	6105                	addi	sp,sp,32
    80002e58:	8082                	ret
     (scause & 0xff) == 9){
    80002e5a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002e5e:	46a5                	li	a3,9
    80002e60:	fed792e3          	bne	a5,a3,80002e44 <devintr+0x12>
    int irq = plic_claim();
    80002e64:	00003097          	auipc	ra,0x3
    80002e68:	594080e7          	jalr	1428(ra) # 800063f8 <plic_claim>
    80002e6c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e6e:	47a9                	li	a5,10
    80002e70:	02f50763          	beq	a0,a5,80002e9e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002e74:	4785                	li	a5,1
    80002e76:	02f50963          	beq	a0,a5,80002ea8 <devintr+0x76>
    return 1;
    80002e7a:	4505                	li	a0,1
    } else if(irq){
    80002e7c:	d8f1                	beqz	s1,80002e50 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e7e:	85a6                	mv	a1,s1
    80002e80:	00005517          	auipc	a0,0x5
    80002e84:	56050513          	addi	a0,a0,1376 # 800083e0 <states.1740+0x30>
    80002e88:	ffffd097          	auipc	ra,0xffffd
    80002e8c:	70a080e7          	jalr	1802(ra) # 80000592 <printf>
      plic_complete(irq);
    80002e90:	8526                	mv	a0,s1
    80002e92:	00003097          	auipc	ra,0x3
    80002e96:	58a080e7          	jalr	1418(ra) # 8000641c <plic_complete>
    return 1;
    80002e9a:	4505                	li	a0,1
    80002e9c:	bf55                	j	80002e50 <devintr+0x1e>
      uartintr();
    80002e9e:	ffffe097          	auipc	ra,0xffffe
    80002ea2:	b36080e7          	jalr	-1226(ra) # 800009d4 <uartintr>
    80002ea6:	b7ed                	j	80002e90 <devintr+0x5e>
      virtio_disk_intr();
    80002ea8:	00004097          	auipc	ra,0x4
    80002eac:	a0e080e7          	jalr	-1522(ra) # 800068b6 <virtio_disk_intr>
    80002eb0:	b7c5                	j	80002e90 <devintr+0x5e>
    if(cpuid() == 0){
    80002eb2:	fffff097          	auipc	ra,0xfffff
    80002eb6:	01e080e7          	jalr	30(ra) # 80001ed0 <cpuid>
    80002eba:	c901                	beqz	a0,80002eca <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ebc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ec0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ec2:	14479073          	csrw	sip,a5
    return 2;
    80002ec6:	4509                	li	a0,2
    80002ec8:	b761                	j	80002e50 <devintr+0x1e>
      clockintr();
    80002eca:	00000097          	auipc	ra,0x0
    80002ece:	f22080e7          	jalr	-222(ra) # 80002dec <clockintr>
    80002ed2:	b7ed                	j	80002ebc <devintr+0x8a>

0000000080002ed4 <usertrap>:
{
    80002ed4:	1101                	addi	sp,sp,-32
    80002ed6:	ec06                	sd	ra,24(sp)
    80002ed8:	e822                	sd	s0,16(sp)
    80002eda:	e426                	sd	s1,8(sp)
    80002edc:	e04a                	sd	s2,0(sp)
    80002ede:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ee0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ee4:	1007f793          	andi	a5,a5,256
    80002ee8:	e3ad                	bnez	a5,80002f4a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002eea:	00003797          	auipc	a5,0x3
    80002eee:	40678793          	addi	a5,a5,1030 # 800062f0 <kernelvec>
    80002ef2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	006080e7          	jalr	6(ra) # 80001efc <myproc>
    80002efe:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002f00:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f02:	14102773          	csrr	a4,sepc
    80002f06:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f08:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002f0c:	47a1                	li	a5,8
    80002f0e:	04f71c63          	bne	a4,a5,80002f66 <usertrap+0x92>
    if(p->killed)
    80002f12:	591c                	lw	a5,48(a0)
    80002f14:	e3b9                	bnez	a5,80002f5a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002f16:	6cb8                	ld	a4,88(s1)
    80002f18:	6f1c                	ld	a5,24(a4)
    80002f1a:	0791                	addi	a5,a5,4
    80002f1c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f22:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f26:	10079073          	csrw	sstatus,a5
    syscall();
    80002f2a:	00000097          	auipc	ra,0x0
    80002f2e:	2e0080e7          	jalr	736(ra) # 8000320a <syscall>
  if(p->killed)
    80002f32:	589c                	lw	a5,48(s1)
    80002f34:	ebc1                	bnez	a5,80002fc4 <usertrap+0xf0>
  usertrapret();
    80002f36:	00000097          	auipc	ra,0x0
    80002f3a:	e18080e7          	jalr	-488(ra) # 80002d4e <usertrapret>
}
    80002f3e:	60e2                	ld	ra,24(sp)
    80002f40:	6442                	ld	s0,16(sp)
    80002f42:	64a2                	ld	s1,8(sp)
    80002f44:	6902                	ld	s2,0(sp)
    80002f46:	6105                	addi	sp,sp,32
    80002f48:	8082                	ret
    panic("usertrap: not from user mode");
    80002f4a:	00005517          	auipc	a0,0x5
    80002f4e:	4b650513          	addi	a0,a0,1206 # 80008400 <states.1740+0x50>
    80002f52:	ffffd097          	auipc	ra,0xffffd
    80002f56:	5f6080e7          	jalr	1526(ra) # 80000548 <panic>
      exit(-1);
    80002f5a:	557d                	li	a0,-1
    80002f5c:	fffff097          	auipc	ra,0xfffff
    80002f60:	7f2080e7          	jalr	2034(ra) # 8000274e <exit>
    80002f64:	bf4d                	j	80002f16 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002f66:	00000097          	auipc	ra,0x0
    80002f6a:	ecc080e7          	jalr	-308(ra) # 80002e32 <devintr>
    80002f6e:	892a                	mv	s2,a0
    80002f70:	c501                	beqz	a0,80002f78 <usertrap+0xa4>
  if(p->killed)
    80002f72:	589c                	lw	a5,48(s1)
    80002f74:	c3a1                	beqz	a5,80002fb4 <usertrap+0xe0>
    80002f76:	a815                	j	80002faa <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f78:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f7c:	5c90                	lw	a2,56(s1)
    80002f7e:	00005517          	auipc	a0,0x5
    80002f82:	4a250513          	addi	a0,a0,1186 # 80008420 <states.1740+0x70>
    80002f86:	ffffd097          	auipc	ra,0xffffd
    80002f8a:	60c080e7          	jalr	1548(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f8e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f92:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f96:	00005517          	auipc	a0,0x5
    80002f9a:	4ba50513          	addi	a0,a0,1210 # 80008450 <states.1740+0xa0>
    80002f9e:	ffffd097          	auipc	ra,0xffffd
    80002fa2:	5f4080e7          	jalr	1524(ra) # 80000592 <printf>
    p->killed = 1;
    80002fa6:	4785                	li	a5,1
    80002fa8:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002faa:	557d                	li	a0,-1
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	7a2080e7          	jalr	1954(ra) # 8000274e <exit>
  if(which_dev == 2)
    80002fb4:	4789                	li	a5,2
    80002fb6:	f8f910e3          	bne	s2,a5,80002f36 <usertrap+0x62>
    yield();
    80002fba:	00000097          	auipc	ra,0x0
    80002fbe:	89e080e7          	jalr	-1890(ra) # 80002858 <yield>
    80002fc2:	bf95                	j	80002f36 <usertrap+0x62>
  int which_dev = 0;
    80002fc4:	4901                	li	s2,0
    80002fc6:	b7d5                	j	80002faa <usertrap+0xd6>

0000000080002fc8 <kerneltrap>:
{
    80002fc8:	7179                	addi	sp,sp,-48
    80002fca:	f406                	sd	ra,40(sp)
    80002fcc:	f022                	sd	s0,32(sp)
    80002fce:	ec26                	sd	s1,24(sp)
    80002fd0:	e84a                	sd	s2,16(sp)
    80002fd2:	e44e                	sd	s3,8(sp)
    80002fd4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fd6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fda:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fde:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002fe2:	1004f793          	andi	a5,s1,256
    80002fe6:	cb85                	beqz	a5,80003016 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fe8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fec:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002fee:	ef85                	bnez	a5,80003026 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ff0:	00000097          	auipc	ra,0x0
    80002ff4:	e42080e7          	jalr	-446(ra) # 80002e32 <devintr>
    80002ff8:	cd1d                	beqz	a0,80003036 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ffa:	4789                	li	a5,2
    80002ffc:	06f50a63          	beq	a0,a5,80003070 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003000:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003004:	10049073          	csrw	sstatus,s1
}
    80003008:	70a2                	ld	ra,40(sp)
    8000300a:	7402                	ld	s0,32(sp)
    8000300c:	64e2                	ld	s1,24(sp)
    8000300e:	6942                	ld	s2,16(sp)
    80003010:	69a2                	ld	s3,8(sp)
    80003012:	6145                	addi	sp,sp,48
    80003014:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003016:	00005517          	auipc	a0,0x5
    8000301a:	45a50513          	addi	a0,a0,1114 # 80008470 <states.1740+0xc0>
    8000301e:	ffffd097          	auipc	ra,0xffffd
    80003022:	52a080e7          	jalr	1322(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80003026:	00005517          	auipc	a0,0x5
    8000302a:	47250513          	addi	a0,a0,1138 # 80008498 <states.1740+0xe8>
    8000302e:	ffffd097          	auipc	ra,0xffffd
    80003032:	51a080e7          	jalr	1306(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80003036:	85ce                	mv	a1,s3
    80003038:	00005517          	auipc	a0,0x5
    8000303c:	48050513          	addi	a0,a0,1152 # 800084b8 <states.1740+0x108>
    80003040:	ffffd097          	auipc	ra,0xffffd
    80003044:	552080e7          	jalr	1362(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003048:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000304c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003050:	00005517          	auipc	a0,0x5
    80003054:	47850513          	addi	a0,a0,1144 # 800084c8 <states.1740+0x118>
    80003058:	ffffd097          	auipc	ra,0xffffd
    8000305c:	53a080e7          	jalr	1338(ra) # 80000592 <printf>
    panic("kerneltrap");
    80003060:	00005517          	auipc	a0,0x5
    80003064:	48050513          	addi	a0,a0,1152 # 800084e0 <states.1740+0x130>
    80003068:	ffffd097          	auipc	ra,0xffffd
    8000306c:	4e0080e7          	jalr	1248(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003070:	fffff097          	auipc	ra,0xfffff
    80003074:	e8c080e7          	jalr	-372(ra) # 80001efc <myproc>
    80003078:	d541                	beqz	a0,80003000 <kerneltrap+0x38>
    8000307a:	fffff097          	auipc	ra,0xfffff
    8000307e:	e82080e7          	jalr	-382(ra) # 80001efc <myproc>
    80003082:	4d18                	lw	a4,24(a0)
    80003084:	478d                	li	a5,3
    80003086:	f6f71de3          	bne	a4,a5,80003000 <kerneltrap+0x38>
    yield();
    8000308a:	fffff097          	auipc	ra,0xfffff
    8000308e:	7ce080e7          	jalr	1998(ra) # 80002858 <yield>
    80003092:	b7bd                	j	80003000 <kerneltrap+0x38>

0000000080003094 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003094:	1101                	addi	sp,sp,-32
    80003096:	ec06                	sd	ra,24(sp)
    80003098:	e822                	sd	s0,16(sp)
    8000309a:	e426                	sd	s1,8(sp)
    8000309c:	1000                	addi	s0,sp,32
    8000309e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800030a0:	fffff097          	auipc	ra,0xfffff
    800030a4:	e5c080e7          	jalr	-420(ra) # 80001efc <myproc>
  switch (n) {
    800030a8:	4795                	li	a5,5
    800030aa:	0497e163          	bltu	a5,s1,800030ec <argraw+0x58>
    800030ae:	048a                	slli	s1,s1,0x2
    800030b0:	00005717          	auipc	a4,0x5
    800030b4:	53070713          	addi	a4,a4,1328 # 800085e0 <states.1740+0x230>
    800030b8:	94ba                	add	s1,s1,a4
    800030ba:	409c                	lw	a5,0(s1)
    800030bc:	97ba                	add	a5,a5,a4
    800030be:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800030c0:	6d3c                	ld	a5,88(a0)
    800030c2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030c4:	60e2                	ld	ra,24(sp)
    800030c6:	6442                	ld	s0,16(sp)
    800030c8:	64a2                	ld	s1,8(sp)
    800030ca:	6105                	addi	sp,sp,32
    800030cc:	8082                	ret
    return p->trapframe->a1;
    800030ce:	6d3c                	ld	a5,88(a0)
    800030d0:	7fa8                	ld	a0,120(a5)
    800030d2:	bfcd                	j	800030c4 <argraw+0x30>
    return p->trapframe->a2;
    800030d4:	6d3c                	ld	a5,88(a0)
    800030d6:	63c8                	ld	a0,128(a5)
    800030d8:	b7f5                	j	800030c4 <argraw+0x30>
    return p->trapframe->a3;
    800030da:	6d3c                	ld	a5,88(a0)
    800030dc:	67c8                	ld	a0,136(a5)
    800030de:	b7dd                	j	800030c4 <argraw+0x30>
    return p->trapframe->a4;
    800030e0:	6d3c                	ld	a5,88(a0)
    800030e2:	6bc8                	ld	a0,144(a5)
    800030e4:	b7c5                	j	800030c4 <argraw+0x30>
    return p->trapframe->a5;
    800030e6:	6d3c                	ld	a5,88(a0)
    800030e8:	6fc8                	ld	a0,152(a5)
    800030ea:	bfe9                	j	800030c4 <argraw+0x30>
  panic("argraw");
    800030ec:	00005517          	auipc	a0,0x5
    800030f0:	40450513          	addi	a0,a0,1028 # 800084f0 <states.1740+0x140>
    800030f4:	ffffd097          	auipc	ra,0xffffd
    800030f8:	454080e7          	jalr	1108(ra) # 80000548 <panic>

00000000800030fc <fetchaddr>:
{
    800030fc:	1101                	addi	sp,sp,-32
    800030fe:	ec06                	sd	ra,24(sp)
    80003100:	e822                	sd	s0,16(sp)
    80003102:	e426                	sd	s1,8(sp)
    80003104:	e04a                	sd	s2,0(sp)
    80003106:	1000                	addi	s0,sp,32
    80003108:	84aa                	mv	s1,a0
    8000310a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000310c:	fffff097          	auipc	ra,0xfffff
    80003110:	df0080e7          	jalr	-528(ra) # 80001efc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003114:	653c                	ld	a5,72(a0)
    80003116:	02f4f863          	bgeu	s1,a5,80003146 <fetchaddr+0x4a>
    8000311a:	00848713          	addi	a4,s1,8
    8000311e:	02e7e663          	bltu	a5,a4,8000314a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003122:	46a1                	li	a3,8
    80003124:	8626                	mv	a2,s1
    80003126:	85ca                	mv	a1,s2
    80003128:	6928                	ld	a0,80(a0)
    8000312a:	ffffe097          	auipc	ra,0xffffe
    8000312e:	6a2080e7          	jalr	1698(ra) # 800017cc <copyin>
    80003132:	00a03533          	snez	a0,a0
    80003136:	40a00533          	neg	a0,a0
}
    8000313a:	60e2                	ld	ra,24(sp)
    8000313c:	6442                	ld	s0,16(sp)
    8000313e:	64a2                	ld	s1,8(sp)
    80003140:	6902                	ld	s2,0(sp)
    80003142:	6105                	addi	sp,sp,32
    80003144:	8082                	ret
    return -1;
    80003146:	557d                	li	a0,-1
    80003148:	bfcd                	j	8000313a <fetchaddr+0x3e>
    8000314a:	557d                	li	a0,-1
    8000314c:	b7fd                	j	8000313a <fetchaddr+0x3e>

000000008000314e <fetchstr>:
{
    8000314e:	7179                	addi	sp,sp,-48
    80003150:	f406                	sd	ra,40(sp)
    80003152:	f022                	sd	s0,32(sp)
    80003154:	ec26                	sd	s1,24(sp)
    80003156:	e84a                	sd	s2,16(sp)
    80003158:	e44e                	sd	s3,8(sp)
    8000315a:	1800                	addi	s0,sp,48
    8000315c:	892a                	mv	s2,a0
    8000315e:	84ae                	mv	s1,a1
    80003160:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003162:	fffff097          	auipc	ra,0xfffff
    80003166:	d9a080e7          	jalr	-614(ra) # 80001efc <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000316a:	86ce                	mv	a3,s3
    8000316c:	864a                	mv	a2,s2
    8000316e:	85a6                	mv	a1,s1
    80003170:	6928                	ld	a0,80(a0)
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	6e6080e7          	jalr	1766(ra) # 80001858 <copyinstr>
  if(err < 0)
    8000317a:	00054763          	bltz	a0,80003188 <fetchstr+0x3a>
  return strlen(buf);
    8000317e:	8526                	mv	a0,s1
    80003180:	ffffe097          	auipc	ra,0xffffe
    80003184:	d5e080e7          	jalr	-674(ra) # 80000ede <strlen>
}
    80003188:	70a2                	ld	ra,40(sp)
    8000318a:	7402                	ld	s0,32(sp)
    8000318c:	64e2                	ld	s1,24(sp)
    8000318e:	6942                	ld	s2,16(sp)
    80003190:	69a2                	ld	s3,8(sp)
    80003192:	6145                	addi	sp,sp,48
    80003194:	8082                	ret

0000000080003196 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003196:	1101                	addi	sp,sp,-32
    80003198:	ec06                	sd	ra,24(sp)
    8000319a:	e822                	sd	s0,16(sp)
    8000319c:	e426                	sd	s1,8(sp)
    8000319e:	1000                	addi	s0,sp,32
    800031a0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031a2:	00000097          	auipc	ra,0x0
    800031a6:	ef2080e7          	jalr	-270(ra) # 80003094 <argraw>
    800031aa:	c088                	sw	a0,0(s1)
  return 0;
}
    800031ac:	4501                	li	a0,0
    800031ae:	60e2                	ld	ra,24(sp)
    800031b0:	6442                	ld	s0,16(sp)
    800031b2:	64a2                	ld	s1,8(sp)
    800031b4:	6105                	addi	sp,sp,32
    800031b6:	8082                	ret

00000000800031b8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800031b8:	1101                	addi	sp,sp,-32
    800031ba:	ec06                	sd	ra,24(sp)
    800031bc:	e822                	sd	s0,16(sp)
    800031be:	e426                	sd	s1,8(sp)
    800031c0:	1000                	addi	s0,sp,32
    800031c2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031c4:	00000097          	auipc	ra,0x0
    800031c8:	ed0080e7          	jalr	-304(ra) # 80003094 <argraw>
    800031cc:	e088                	sd	a0,0(s1)
  return 0;
}
    800031ce:	4501                	li	a0,0
    800031d0:	60e2                	ld	ra,24(sp)
    800031d2:	6442                	ld	s0,16(sp)
    800031d4:	64a2                	ld	s1,8(sp)
    800031d6:	6105                	addi	sp,sp,32
    800031d8:	8082                	ret

00000000800031da <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031da:	1101                	addi	sp,sp,-32
    800031dc:	ec06                	sd	ra,24(sp)
    800031de:	e822                	sd	s0,16(sp)
    800031e0:	e426                	sd	s1,8(sp)
    800031e2:	e04a                	sd	s2,0(sp)
    800031e4:	1000                	addi	s0,sp,32
    800031e6:	84ae                	mv	s1,a1
    800031e8:	8932                	mv	s2,a2
  *ip = argraw(n);
    800031ea:	00000097          	auipc	ra,0x0
    800031ee:	eaa080e7          	jalr	-342(ra) # 80003094 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800031f2:	864a                	mv	a2,s2
    800031f4:	85a6                	mv	a1,s1
    800031f6:	00000097          	auipc	ra,0x0
    800031fa:	f58080e7          	jalr	-168(ra) # 8000314e <fetchstr>
}
    800031fe:	60e2                	ld	ra,24(sp)
    80003200:	6442                	ld	s0,16(sp)
    80003202:	64a2                	ld	s1,8(sp)
    80003204:	6902                	ld	s2,0(sp)
    80003206:	6105                	addi	sp,sp,32
    80003208:	8082                	ret

000000008000320a <syscall>:
    "sysinfo",
};

void
syscall(void)
{
    8000320a:	7179                	addi	sp,sp,-48
    8000320c:	f406                	sd	ra,40(sp)
    8000320e:	f022                	sd	s0,32(sp)
    80003210:	ec26                	sd	s1,24(sp)
    80003212:	e84a                	sd	s2,16(sp)
    80003214:	e44e                	sd	s3,8(sp)
    80003216:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80003218:	fffff097          	auipc	ra,0xfffff
    8000321c:	ce4080e7          	jalr	-796(ra) # 80001efc <myproc>
    80003220:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003222:	05853903          	ld	s2,88(a0)
    80003226:	0a893783          	ld	a5,168(s2)
    8000322a:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000322e:	37fd                	addiw	a5,a5,-1
    80003230:	4759                	li	a4,22
    80003232:	04f76963          	bltu	a4,a5,80003284 <syscall+0x7a>
    80003236:	00399713          	slli	a4,s3,0x3
    8000323a:	00005797          	auipc	a5,0x5
    8000323e:	3be78793          	addi	a5,a5,958 # 800085f8 <syscalls>
    80003242:	97ba                	add	a5,a5,a4
    80003244:	639c                	ld	a5,0(a5)
    80003246:	cf9d                	beqz	a5,80003284 <syscall+0x7a>
    p->trapframe->a0 = syscalls[num]();
    80003248:	9782                	jalr	a5
    8000324a:	06a93823          	sd	a0,112(s2)
    if (p->tracemask & (1 << num)) {
    8000324e:	4785                	li	a5,1
    80003250:	013797bb          	sllw	a5,a5,s3
    80003254:	1684b703          	ld	a4,360(s1)
    80003258:	8ff9                	and	a5,a5,a4
    8000325a:	c7a1                	beqz	a5,800032a2 <syscall+0x98>
      // this process traces this sys call num
      printf("%d: syscall %s -> %d\n", p->pid, sysnames[num], p->trapframe->a0);
    8000325c:	6cb8                	ld	a4,88(s1)
    8000325e:	098e                	slli	s3,s3,0x3
    80003260:	00005797          	auipc	a5,0x5
    80003264:	39878793          	addi	a5,a5,920 # 800085f8 <syscalls>
    80003268:	99be                	add	s3,s3,a5
    8000326a:	7b34                	ld	a3,112(a4)
    8000326c:	0c09b603          	ld	a2,192(s3)
    80003270:	5c8c                	lw	a1,56(s1)
    80003272:	00005517          	auipc	a0,0x5
    80003276:	28650513          	addi	a0,a0,646 # 800084f8 <states.1740+0x148>
    8000327a:	ffffd097          	auipc	ra,0xffffd
    8000327e:	318080e7          	jalr	792(ra) # 80000592 <printf>
    80003282:	a005                	j	800032a2 <syscall+0x98>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003284:	86ce                	mv	a3,s3
    80003286:	15848613          	addi	a2,s1,344
    8000328a:	5c8c                	lw	a1,56(s1)
    8000328c:	00005517          	auipc	a0,0x5
    80003290:	28450513          	addi	a0,a0,644 # 80008510 <states.1740+0x160>
    80003294:	ffffd097          	auipc	ra,0xffffd
    80003298:	2fe080e7          	jalr	766(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000329c:	6cbc                	ld	a5,88(s1)
    8000329e:	577d                	li	a4,-1
    800032a0:	fbb8                	sd	a4,112(a5)
  }
}
    800032a2:	70a2                	ld	ra,40(sp)
    800032a4:	7402                	ld	s0,32(sp)
    800032a6:	64e2                	ld	s1,24(sp)
    800032a8:	6942                	ld	s2,16(sp)
    800032aa:	69a2                	ld	s3,8(sp)
    800032ac:	6145                	addi	sp,sp,48
    800032ae:	8082                	ret

00000000800032b0 <sys_exit>:
#include "sysinfo.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800032b0:	1101                	addi	sp,sp,-32
    800032b2:	ec06                	sd	ra,24(sp)
    800032b4:	e822                	sd	s0,16(sp)
    800032b6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800032b8:	fec40593          	addi	a1,s0,-20
    800032bc:	4501                	li	a0,0
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	ed8080e7          	jalr	-296(ra) # 80003196 <argint>
    return -1;
    800032c6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032c8:	00054963          	bltz	a0,800032da <sys_exit+0x2a>
  exit(n);
    800032cc:	fec42503          	lw	a0,-20(s0)
    800032d0:	fffff097          	auipc	ra,0xfffff
    800032d4:	47e080e7          	jalr	1150(ra) # 8000274e <exit>
  return 0;  // not reached
    800032d8:	4781                	li	a5,0
}
    800032da:	853e                	mv	a0,a5
    800032dc:	60e2                	ld	ra,24(sp)
    800032de:	6442                	ld	s0,16(sp)
    800032e0:	6105                	addi	sp,sp,32
    800032e2:	8082                	ret

00000000800032e4 <sys_getpid>:

uint64
sys_getpid(void)
{
    800032e4:	1141                	addi	sp,sp,-16
    800032e6:	e406                	sd	ra,8(sp)
    800032e8:	e022                	sd	s0,0(sp)
    800032ea:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032ec:	fffff097          	auipc	ra,0xfffff
    800032f0:	c10080e7          	jalr	-1008(ra) # 80001efc <myproc>
}
    800032f4:	5d08                	lw	a0,56(a0)
    800032f6:	60a2                	ld	ra,8(sp)
    800032f8:	6402                	ld	s0,0(sp)
    800032fa:	0141                	addi	sp,sp,16
    800032fc:	8082                	ret

00000000800032fe <sys_fork>:

uint64
sys_fork(void)
{
    800032fe:	1141                	addi	sp,sp,-16
    80003300:	e406                	sd	ra,8(sp)
    80003302:	e022                	sd	s0,0(sp)
    80003304:	0800                	addi	s0,sp,16
  return fork();
    80003306:	fffff097          	auipc	ra,0xfffff
    8000330a:	0f8080e7          	jalr	248(ra) # 800023fe <fork>
}
    8000330e:	60a2                	ld	ra,8(sp)
    80003310:	6402                	ld	s0,0(sp)
    80003312:	0141                	addi	sp,sp,16
    80003314:	8082                	ret

0000000080003316 <sys_wait>:

uint64
sys_wait(void)
{
    80003316:	1101                	addi	sp,sp,-32
    80003318:	ec06                	sd	ra,24(sp)
    8000331a:	e822                	sd	s0,16(sp)
    8000331c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000331e:	fe840593          	addi	a1,s0,-24
    80003322:	4501                	li	a0,0
    80003324:	00000097          	auipc	ra,0x0
    80003328:	e94080e7          	jalr	-364(ra) # 800031b8 <argaddr>
    8000332c:	87aa                	mv	a5,a0
    return -1;
    8000332e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003330:	0007c863          	bltz	a5,80003340 <sys_wait+0x2a>
  return wait(p);
    80003334:	fe843503          	ld	a0,-24(s0)
    80003338:	fffff097          	auipc	ra,0xfffff
    8000333c:	5da080e7          	jalr	1498(ra) # 80002912 <wait>
}
    80003340:	60e2                	ld	ra,24(sp)
    80003342:	6442                	ld	s0,16(sp)
    80003344:	6105                	addi	sp,sp,32
    80003346:	8082                	ret

0000000080003348 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003348:	7179                	addi	sp,sp,-48
    8000334a:	f406                	sd	ra,40(sp)
    8000334c:	f022                	sd	s0,32(sp)
    8000334e:	ec26                	sd	s1,24(sp)
    80003350:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003352:	fdc40593          	addi	a1,s0,-36
    80003356:	4501                	li	a0,0
    80003358:	00000097          	auipc	ra,0x0
    8000335c:	e3e080e7          	jalr	-450(ra) # 80003196 <argint>
    80003360:	87aa                	mv	a5,a0
    return -1;
    80003362:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003364:	0207c063          	bltz	a5,80003384 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003368:	fffff097          	auipc	ra,0xfffff
    8000336c:	b94080e7          	jalr	-1132(ra) # 80001efc <myproc>
    80003370:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003372:	fdc42503          	lw	a0,-36(s0)
    80003376:	fffff097          	auipc	ra,0xfffff
    8000337a:	f94080e7          	jalr	-108(ra) # 8000230a <growproc>
    8000337e:	00054863          	bltz	a0,8000338e <sys_sbrk+0x46>
    return -1;
  return addr;
    80003382:	8526                	mv	a0,s1
}
    80003384:	70a2                	ld	ra,40(sp)
    80003386:	7402                	ld	s0,32(sp)
    80003388:	64e2                	ld	s1,24(sp)
    8000338a:	6145                	addi	sp,sp,48
    8000338c:	8082                	ret
    return -1;
    8000338e:	557d                	li	a0,-1
    80003390:	bfd5                	j	80003384 <sys_sbrk+0x3c>

0000000080003392 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003392:	7139                	addi	sp,sp,-64
    80003394:	fc06                	sd	ra,56(sp)
    80003396:	f822                	sd	s0,48(sp)
    80003398:	f426                	sd	s1,40(sp)
    8000339a:	f04a                	sd	s2,32(sp)
    8000339c:	ec4e                	sd	s3,24(sp)
    8000339e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800033a0:	fcc40593          	addi	a1,s0,-52
    800033a4:	4501                	li	a0,0
    800033a6:	00000097          	auipc	ra,0x0
    800033aa:	df0080e7          	jalr	-528(ra) # 80003196 <argint>
    return -1;
    800033ae:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800033b0:	06054563          	bltz	a0,8000341a <sys_sleep+0x88>
  acquire(&tickslock);
    800033b4:	00014517          	auipc	a0,0x14
    800033b8:	7b450513          	addi	a0,a0,1972 # 80017b68 <tickslock>
    800033bc:	ffffe097          	auipc	ra,0xffffe
    800033c0:	89e080e7          	jalr	-1890(ra) # 80000c5a <acquire>
  ticks0 = ticks;
    800033c4:	00006917          	auipc	s2,0x6
    800033c8:	c5c92903          	lw	s2,-932(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    800033cc:	fcc42783          	lw	a5,-52(s0)
    800033d0:	cf85                	beqz	a5,80003408 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033d2:	00014997          	auipc	s3,0x14
    800033d6:	79698993          	addi	s3,s3,1942 # 80017b68 <tickslock>
    800033da:	00006497          	auipc	s1,0x6
    800033de:	c4648493          	addi	s1,s1,-954 # 80009020 <ticks>
    if(myproc()->killed){
    800033e2:	fffff097          	auipc	ra,0xfffff
    800033e6:	b1a080e7          	jalr	-1254(ra) # 80001efc <myproc>
    800033ea:	591c                	lw	a5,48(a0)
    800033ec:	ef9d                	bnez	a5,8000342a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800033ee:	85ce                	mv	a1,s3
    800033f0:	8526                	mv	a0,s1
    800033f2:	fffff097          	auipc	ra,0xfffff
    800033f6:	4a2080e7          	jalr	1186(ra) # 80002894 <sleep>
  while(ticks - ticks0 < n){
    800033fa:	409c                	lw	a5,0(s1)
    800033fc:	412787bb          	subw	a5,a5,s2
    80003400:	fcc42703          	lw	a4,-52(s0)
    80003404:	fce7efe3          	bltu	a5,a4,800033e2 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003408:	00014517          	auipc	a0,0x14
    8000340c:	76050513          	addi	a0,a0,1888 # 80017b68 <tickslock>
    80003410:	ffffe097          	auipc	ra,0xffffe
    80003414:	8fe080e7          	jalr	-1794(ra) # 80000d0e <release>
  return 0;
    80003418:	4781                	li	a5,0
}
    8000341a:	853e                	mv	a0,a5
    8000341c:	70e2                	ld	ra,56(sp)
    8000341e:	7442                	ld	s0,48(sp)
    80003420:	74a2                	ld	s1,40(sp)
    80003422:	7902                	ld	s2,32(sp)
    80003424:	69e2                	ld	s3,24(sp)
    80003426:	6121                	addi	sp,sp,64
    80003428:	8082                	ret
      release(&tickslock);
    8000342a:	00014517          	auipc	a0,0x14
    8000342e:	73e50513          	addi	a0,a0,1854 # 80017b68 <tickslock>
    80003432:	ffffe097          	auipc	ra,0xffffe
    80003436:	8dc080e7          	jalr	-1828(ra) # 80000d0e <release>
      return -1;
    8000343a:	57fd                	li	a5,-1
    8000343c:	bff9                	j	8000341a <sys_sleep+0x88>

000000008000343e <sys_kill>:

uint64
sys_kill(void)
{
    8000343e:	1101                	addi	sp,sp,-32
    80003440:	ec06                	sd	ra,24(sp)
    80003442:	e822                	sd	s0,16(sp)
    80003444:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003446:	fec40593          	addi	a1,s0,-20
    8000344a:	4501                	li	a0,0
    8000344c:	00000097          	auipc	ra,0x0
    80003450:	d4a080e7          	jalr	-694(ra) # 80003196 <argint>
    80003454:	87aa                	mv	a5,a0
    return -1;
    80003456:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003458:	0007c863          	bltz	a5,80003468 <sys_kill+0x2a>
  return kill(pid);
    8000345c:	fec42503          	lw	a0,-20(s0)
    80003460:	fffff097          	auipc	ra,0xfffff
    80003464:	624080e7          	jalr	1572(ra) # 80002a84 <kill>
}
    80003468:	60e2                	ld	ra,24(sp)
    8000346a:	6442                	ld	s0,16(sp)
    8000346c:	6105                	addi	sp,sp,32
    8000346e:	8082                	ret

0000000080003470 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003470:	1101                	addi	sp,sp,-32
    80003472:	ec06                	sd	ra,24(sp)
    80003474:	e822                	sd	s0,16(sp)
    80003476:	e426                	sd	s1,8(sp)
    80003478:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000347a:	00014517          	auipc	a0,0x14
    8000347e:	6ee50513          	addi	a0,a0,1774 # 80017b68 <tickslock>
    80003482:	ffffd097          	auipc	ra,0xffffd
    80003486:	7d8080e7          	jalr	2008(ra) # 80000c5a <acquire>
  xticks = ticks;
    8000348a:	00006497          	auipc	s1,0x6
    8000348e:	b964a483          	lw	s1,-1130(s1) # 80009020 <ticks>
  release(&tickslock);
    80003492:	00014517          	auipc	a0,0x14
    80003496:	6d650513          	addi	a0,a0,1750 # 80017b68 <tickslock>
    8000349a:	ffffe097          	auipc	ra,0xffffe
    8000349e:	874080e7          	jalr	-1932(ra) # 80000d0e <release>
  return xticks;
}
    800034a2:	02049513          	slli	a0,s1,0x20
    800034a6:	9101                	srli	a0,a0,0x20
    800034a8:	60e2                	ld	ra,24(sp)
    800034aa:	6442                	ld	s0,16(sp)
    800034ac:	64a2                	ld	s1,8(sp)
    800034ae:	6105                	addi	sp,sp,32
    800034b0:	8082                	ret

00000000800034b2 <sys_trace>:

// click the sys call number in p->tracemask
// so as to tracing its calling afterwards
uint64
sys_trace(void) {
    800034b2:	1101                	addi	sp,sp,-32
    800034b4:	ec06                	sd	ra,24(sp)
    800034b6:	e822                	sd	s0,16(sp)
    800034b8:	1000                	addi	s0,sp,32
  int trace_sys_mask;
  if (argint(0, &trace_sys_mask) < 0)
    800034ba:	fec40593          	addi	a1,s0,-20
    800034be:	4501                	li	a0,0
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	cd6080e7          	jalr	-810(ra) # 80003196 <argint>
    return -1;
    800034c8:	57fd                	li	a5,-1
  if (argint(0, &trace_sys_mask) < 0)
    800034ca:	00054e63          	bltz	a0,800034e6 <sys_trace+0x34>
  myproc()->tracemask |= trace_sys_mask;
    800034ce:	fffff097          	auipc	ra,0xfffff
    800034d2:	a2e080e7          	jalr	-1490(ra) # 80001efc <myproc>
    800034d6:	fec42703          	lw	a4,-20(s0)
    800034da:	16853783          	ld	a5,360(a0)
    800034de:	8fd9                	or	a5,a5,a4
    800034e0:	16f53423          	sd	a5,360(a0)
  return 0;
    800034e4:	4781                	li	a5,0
}
    800034e6:	853e                	mv	a0,a5
    800034e8:	60e2                	ld	ra,24(sp)
    800034ea:	6442                	ld	s0,16(sp)
    800034ec:	6105                	addi	sp,sp,32
    800034ee:	8082                	ret

00000000800034f0 <sys_sysinfo>:

// collect system info
uint64
sys_sysinfo(void) {
    800034f0:	7139                	addi	sp,sp,-64
    800034f2:	fc06                	sd	ra,56(sp)
    800034f4:	f822                	sd	s0,48(sp)
    800034f6:	f426                	sd	s1,40(sp)
    800034f8:	0080                	addi	s0,sp,64
  struct proc *my_proc = myproc();
    800034fa:	fffff097          	auipc	ra,0xfffff
    800034fe:	a02080e7          	jalr	-1534(ra) # 80001efc <myproc>
    80003502:	84aa                	mv	s1,a0
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003504:	fd840593          	addi	a1,s0,-40
    80003508:	4501                	li	a0,0
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	cae080e7          	jalr	-850(ra) # 800031b8 <argaddr>
    return -1;
    80003512:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    80003514:	02054a63          	bltz	a0,80003548 <sys_sysinfo+0x58>
  // construct in kernel first
  struct sysinfo s;
  s.freemem = kfreemem();
    80003518:	ffffd097          	auipc	ra,0xffffd
    8000351c:	668080e7          	jalr	1640(ra) # 80000b80 <kfreemem>
    80003520:	fca43423          	sd	a0,-56(s0)
  s.nproc = count_free_proc();
    80003524:	fffff097          	auipc	ra,0xfffff
    80003528:	72c080e7          	jalr	1836(ra) # 80002c50 <count_free_proc>
    8000352c:	fca43823          	sd	a0,-48(s0)
  // copy to user space
  if(copyout(my_proc->pagetable, p, (char *)&s, sizeof(s)) < 0)
    80003530:	46c1                	li	a3,16
    80003532:	fc840613          	addi	a2,s0,-56
    80003536:	fd843583          	ld	a1,-40(s0)
    8000353a:	68a8                	ld	a0,80(s1)
    8000353c:	ffffe097          	auipc	ra,0xffffe
    80003540:	204080e7          	jalr	516(ra) # 80001740 <copyout>
    80003544:	43f55793          	srai	a5,a0,0x3f
    return -1;
  return 0;
}
    80003548:	853e                	mv	a0,a5
    8000354a:	70e2                	ld	ra,56(sp)
    8000354c:	7442                	ld	s0,48(sp)
    8000354e:	74a2                	ld	s1,40(sp)
    80003550:	6121                	addi	sp,sp,64
    80003552:	8082                	ret

0000000080003554 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003554:	7179                	addi	sp,sp,-48
    80003556:	f406                	sd	ra,40(sp)
    80003558:	f022                	sd	s0,32(sp)
    8000355a:	ec26                	sd	s1,24(sp)
    8000355c:	e84a                	sd	s2,16(sp)
    8000355e:	e44e                	sd	s3,8(sp)
    80003560:	e052                	sd	s4,0(sp)
    80003562:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003564:	00005597          	auipc	a1,0x5
    80003568:	21458593          	addi	a1,a1,532 # 80008778 <sysnames+0xc0>
    8000356c:	00014517          	auipc	a0,0x14
    80003570:	61450513          	addi	a0,a0,1556 # 80017b80 <bcache>
    80003574:	ffffd097          	auipc	ra,0xffffd
    80003578:	656080e7          	jalr	1622(ra) # 80000bca <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000357c:	0001c797          	auipc	a5,0x1c
    80003580:	60478793          	addi	a5,a5,1540 # 8001fb80 <bcache+0x8000>
    80003584:	0001d717          	auipc	a4,0x1d
    80003588:	86470713          	addi	a4,a4,-1948 # 8001fde8 <bcache+0x8268>
    8000358c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003590:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003594:	00014497          	auipc	s1,0x14
    80003598:	60448493          	addi	s1,s1,1540 # 80017b98 <bcache+0x18>
    b->next = bcache.head.next;
    8000359c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000359e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035a0:	00005a17          	auipc	s4,0x5
    800035a4:	1e0a0a13          	addi	s4,s4,480 # 80008780 <sysnames+0xc8>
    b->next = bcache.head.next;
    800035a8:	2b893783          	ld	a5,696(s2)
    800035ac:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035ae:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035b2:	85d2                	mv	a1,s4
    800035b4:	01048513          	addi	a0,s1,16
    800035b8:	00001097          	auipc	ra,0x1
    800035bc:	4ac080e7          	jalr	1196(ra) # 80004a64 <initsleeplock>
    bcache.head.next->prev = b;
    800035c0:	2b893783          	ld	a5,696(s2)
    800035c4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035c6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035ca:	45848493          	addi	s1,s1,1112
    800035ce:	fd349de3          	bne	s1,s3,800035a8 <binit+0x54>
  }
}
    800035d2:	70a2                	ld	ra,40(sp)
    800035d4:	7402                	ld	s0,32(sp)
    800035d6:	64e2                	ld	s1,24(sp)
    800035d8:	6942                	ld	s2,16(sp)
    800035da:	69a2                	ld	s3,8(sp)
    800035dc:	6a02                	ld	s4,0(sp)
    800035de:	6145                	addi	sp,sp,48
    800035e0:	8082                	ret

00000000800035e2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035e2:	7179                	addi	sp,sp,-48
    800035e4:	f406                	sd	ra,40(sp)
    800035e6:	f022                	sd	s0,32(sp)
    800035e8:	ec26                	sd	s1,24(sp)
    800035ea:	e84a                	sd	s2,16(sp)
    800035ec:	e44e                	sd	s3,8(sp)
    800035ee:	1800                	addi	s0,sp,48
    800035f0:	89aa                	mv	s3,a0
    800035f2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800035f4:	00014517          	auipc	a0,0x14
    800035f8:	58c50513          	addi	a0,a0,1420 # 80017b80 <bcache>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	65e080e7          	jalr	1630(ra) # 80000c5a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003604:	0001d497          	auipc	s1,0x1d
    80003608:	8344b483          	ld	s1,-1996(s1) # 8001fe38 <bcache+0x82b8>
    8000360c:	0001c797          	auipc	a5,0x1c
    80003610:	7dc78793          	addi	a5,a5,2012 # 8001fde8 <bcache+0x8268>
    80003614:	02f48f63          	beq	s1,a5,80003652 <bread+0x70>
    80003618:	873e                	mv	a4,a5
    8000361a:	a021                	j	80003622 <bread+0x40>
    8000361c:	68a4                	ld	s1,80(s1)
    8000361e:	02e48a63          	beq	s1,a4,80003652 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003622:	449c                	lw	a5,8(s1)
    80003624:	ff379ce3          	bne	a5,s3,8000361c <bread+0x3a>
    80003628:	44dc                	lw	a5,12(s1)
    8000362a:	ff2799e3          	bne	a5,s2,8000361c <bread+0x3a>
      b->refcnt++;
    8000362e:	40bc                	lw	a5,64(s1)
    80003630:	2785                	addiw	a5,a5,1
    80003632:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003634:	00014517          	auipc	a0,0x14
    80003638:	54c50513          	addi	a0,a0,1356 # 80017b80 <bcache>
    8000363c:	ffffd097          	auipc	ra,0xffffd
    80003640:	6d2080e7          	jalr	1746(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    80003644:	01048513          	addi	a0,s1,16
    80003648:	00001097          	auipc	ra,0x1
    8000364c:	456080e7          	jalr	1110(ra) # 80004a9e <acquiresleep>
      return b;
    80003650:	a8b9                	j	800036ae <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003652:	0001c497          	auipc	s1,0x1c
    80003656:	7de4b483          	ld	s1,2014(s1) # 8001fe30 <bcache+0x82b0>
    8000365a:	0001c797          	auipc	a5,0x1c
    8000365e:	78e78793          	addi	a5,a5,1934 # 8001fde8 <bcache+0x8268>
    80003662:	00f48863          	beq	s1,a5,80003672 <bread+0x90>
    80003666:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003668:	40bc                	lw	a5,64(s1)
    8000366a:	cf81                	beqz	a5,80003682 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000366c:	64a4                	ld	s1,72(s1)
    8000366e:	fee49de3          	bne	s1,a4,80003668 <bread+0x86>
  panic("bget: no buffers");
    80003672:	00005517          	auipc	a0,0x5
    80003676:	11650513          	addi	a0,a0,278 # 80008788 <sysnames+0xd0>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	ece080e7          	jalr	-306(ra) # 80000548 <panic>
      b->dev = dev;
    80003682:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003686:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000368a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000368e:	4785                	li	a5,1
    80003690:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003692:	00014517          	auipc	a0,0x14
    80003696:	4ee50513          	addi	a0,a0,1262 # 80017b80 <bcache>
    8000369a:	ffffd097          	auipc	ra,0xffffd
    8000369e:	674080e7          	jalr	1652(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    800036a2:	01048513          	addi	a0,s1,16
    800036a6:	00001097          	auipc	ra,0x1
    800036aa:	3f8080e7          	jalr	1016(ra) # 80004a9e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036ae:	409c                	lw	a5,0(s1)
    800036b0:	cb89                	beqz	a5,800036c2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036b2:	8526                	mv	a0,s1
    800036b4:	70a2                	ld	ra,40(sp)
    800036b6:	7402                	ld	s0,32(sp)
    800036b8:	64e2                	ld	s1,24(sp)
    800036ba:	6942                	ld	s2,16(sp)
    800036bc:	69a2                	ld	s3,8(sp)
    800036be:	6145                	addi	sp,sp,48
    800036c0:	8082                	ret
    virtio_disk_rw(b, 0);
    800036c2:	4581                	li	a1,0
    800036c4:	8526                	mv	a0,s1
    800036c6:	00003097          	auipc	ra,0x3
    800036ca:	f46080e7          	jalr	-186(ra) # 8000660c <virtio_disk_rw>
    b->valid = 1;
    800036ce:	4785                	li	a5,1
    800036d0:	c09c                	sw	a5,0(s1)
  return b;
    800036d2:	b7c5                	j	800036b2 <bread+0xd0>

00000000800036d4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036d4:	1101                	addi	sp,sp,-32
    800036d6:	ec06                	sd	ra,24(sp)
    800036d8:	e822                	sd	s0,16(sp)
    800036da:	e426                	sd	s1,8(sp)
    800036dc:	1000                	addi	s0,sp,32
    800036de:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036e0:	0541                	addi	a0,a0,16
    800036e2:	00001097          	auipc	ra,0x1
    800036e6:	456080e7          	jalr	1110(ra) # 80004b38 <holdingsleep>
    800036ea:	cd01                	beqz	a0,80003702 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036ec:	4585                	li	a1,1
    800036ee:	8526                	mv	a0,s1
    800036f0:	00003097          	auipc	ra,0x3
    800036f4:	f1c080e7          	jalr	-228(ra) # 8000660c <virtio_disk_rw>
}
    800036f8:	60e2                	ld	ra,24(sp)
    800036fa:	6442                	ld	s0,16(sp)
    800036fc:	64a2                	ld	s1,8(sp)
    800036fe:	6105                	addi	sp,sp,32
    80003700:	8082                	ret
    panic("bwrite");
    80003702:	00005517          	auipc	a0,0x5
    80003706:	09e50513          	addi	a0,a0,158 # 800087a0 <sysnames+0xe8>
    8000370a:	ffffd097          	auipc	ra,0xffffd
    8000370e:	e3e080e7          	jalr	-450(ra) # 80000548 <panic>

0000000080003712 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003712:	1101                	addi	sp,sp,-32
    80003714:	ec06                	sd	ra,24(sp)
    80003716:	e822                	sd	s0,16(sp)
    80003718:	e426                	sd	s1,8(sp)
    8000371a:	e04a                	sd	s2,0(sp)
    8000371c:	1000                	addi	s0,sp,32
    8000371e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003720:	01050913          	addi	s2,a0,16
    80003724:	854a                	mv	a0,s2
    80003726:	00001097          	auipc	ra,0x1
    8000372a:	412080e7          	jalr	1042(ra) # 80004b38 <holdingsleep>
    8000372e:	c92d                	beqz	a0,800037a0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003730:	854a                	mv	a0,s2
    80003732:	00001097          	auipc	ra,0x1
    80003736:	3c2080e7          	jalr	962(ra) # 80004af4 <releasesleep>

  acquire(&bcache.lock);
    8000373a:	00014517          	auipc	a0,0x14
    8000373e:	44650513          	addi	a0,a0,1094 # 80017b80 <bcache>
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	518080e7          	jalr	1304(ra) # 80000c5a <acquire>
  b->refcnt--;
    8000374a:	40bc                	lw	a5,64(s1)
    8000374c:	37fd                	addiw	a5,a5,-1
    8000374e:	0007871b          	sext.w	a4,a5
    80003752:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003754:	eb05                	bnez	a4,80003784 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003756:	68bc                	ld	a5,80(s1)
    80003758:	64b8                	ld	a4,72(s1)
    8000375a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000375c:	64bc                	ld	a5,72(s1)
    8000375e:	68b8                	ld	a4,80(s1)
    80003760:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003762:	0001c797          	auipc	a5,0x1c
    80003766:	41e78793          	addi	a5,a5,1054 # 8001fb80 <bcache+0x8000>
    8000376a:	2b87b703          	ld	a4,696(a5)
    8000376e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003770:	0001c717          	auipc	a4,0x1c
    80003774:	67870713          	addi	a4,a4,1656 # 8001fde8 <bcache+0x8268>
    80003778:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000377a:	2b87b703          	ld	a4,696(a5)
    8000377e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003780:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003784:	00014517          	auipc	a0,0x14
    80003788:	3fc50513          	addi	a0,a0,1020 # 80017b80 <bcache>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	582080e7          	jalr	1410(ra) # 80000d0e <release>
}
    80003794:	60e2                	ld	ra,24(sp)
    80003796:	6442                	ld	s0,16(sp)
    80003798:	64a2                	ld	s1,8(sp)
    8000379a:	6902                	ld	s2,0(sp)
    8000379c:	6105                	addi	sp,sp,32
    8000379e:	8082                	ret
    panic("brelse");
    800037a0:	00005517          	auipc	a0,0x5
    800037a4:	00850513          	addi	a0,a0,8 # 800087a8 <sysnames+0xf0>
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	da0080e7          	jalr	-608(ra) # 80000548 <panic>

00000000800037b0 <bpin>:

void
bpin(struct buf *b) {
    800037b0:	1101                	addi	sp,sp,-32
    800037b2:	ec06                	sd	ra,24(sp)
    800037b4:	e822                	sd	s0,16(sp)
    800037b6:	e426                	sd	s1,8(sp)
    800037b8:	1000                	addi	s0,sp,32
    800037ba:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037bc:	00014517          	auipc	a0,0x14
    800037c0:	3c450513          	addi	a0,a0,964 # 80017b80 <bcache>
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	496080e7          	jalr	1174(ra) # 80000c5a <acquire>
  b->refcnt++;
    800037cc:	40bc                	lw	a5,64(s1)
    800037ce:	2785                	addiw	a5,a5,1
    800037d0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037d2:	00014517          	auipc	a0,0x14
    800037d6:	3ae50513          	addi	a0,a0,942 # 80017b80 <bcache>
    800037da:	ffffd097          	auipc	ra,0xffffd
    800037de:	534080e7          	jalr	1332(ra) # 80000d0e <release>
}
    800037e2:	60e2                	ld	ra,24(sp)
    800037e4:	6442                	ld	s0,16(sp)
    800037e6:	64a2                	ld	s1,8(sp)
    800037e8:	6105                	addi	sp,sp,32
    800037ea:	8082                	ret

00000000800037ec <bunpin>:

void
bunpin(struct buf *b) {
    800037ec:	1101                	addi	sp,sp,-32
    800037ee:	ec06                	sd	ra,24(sp)
    800037f0:	e822                	sd	s0,16(sp)
    800037f2:	e426                	sd	s1,8(sp)
    800037f4:	1000                	addi	s0,sp,32
    800037f6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037f8:	00014517          	auipc	a0,0x14
    800037fc:	38850513          	addi	a0,a0,904 # 80017b80 <bcache>
    80003800:	ffffd097          	auipc	ra,0xffffd
    80003804:	45a080e7          	jalr	1114(ra) # 80000c5a <acquire>
  b->refcnt--;
    80003808:	40bc                	lw	a5,64(s1)
    8000380a:	37fd                	addiw	a5,a5,-1
    8000380c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000380e:	00014517          	auipc	a0,0x14
    80003812:	37250513          	addi	a0,a0,882 # 80017b80 <bcache>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	4f8080e7          	jalr	1272(ra) # 80000d0e <release>
}
    8000381e:	60e2                	ld	ra,24(sp)
    80003820:	6442                	ld	s0,16(sp)
    80003822:	64a2                	ld	s1,8(sp)
    80003824:	6105                	addi	sp,sp,32
    80003826:	8082                	ret

0000000080003828 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003828:	1101                	addi	sp,sp,-32
    8000382a:	ec06                	sd	ra,24(sp)
    8000382c:	e822                	sd	s0,16(sp)
    8000382e:	e426                	sd	s1,8(sp)
    80003830:	e04a                	sd	s2,0(sp)
    80003832:	1000                	addi	s0,sp,32
    80003834:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003836:	00d5d59b          	srliw	a1,a1,0xd
    8000383a:	0001d797          	auipc	a5,0x1d
    8000383e:	a227a783          	lw	a5,-1502(a5) # 8002025c <sb+0x1c>
    80003842:	9dbd                	addw	a1,a1,a5
    80003844:	00000097          	auipc	ra,0x0
    80003848:	d9e080e7          	jalr	-610(ra) # 800035e2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000384c:	0074f713          	andi	a4,s1,7
    80003850:	4785                	li	a5,1
    80003852:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003856:	14ce                	slli	s1,s1,0x33
    80003858:	90d9                	srli	s1,s1,0x36
    8000385a:	00950733          	add	a4,a0,s1
    8000385e:	05874703          	lbu	a4,88(a4)
    80003862:	00e7f6b3          	and	a3,a5,a4
    80003866:	c69d                	beqz	a3,80003894 <bfree+0x6c>
    80003868:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000386a:	94aa                	add	s1,s1,a0
    8000386c:	fff7c793          	not	a5,a5
    80003870:	8ff9                	and	a5,a5,a4
    80003872:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003876:	00001097          	auipc	ra,0x1
    8000387a:	100080e7          	jalr	256(ra) # 80004976 <log_write>
  brelse(bp);
    8000387e:	854a                	mv	a0,s2
    80003880:	00000097          	auipc	ra,0x0
    80003884:	e92080e7          	jalr	-366(ra) # 80003712 <brelse>
}
    80003888:	60e2                	ld	ra,24(sp)
    8000388a:	6442                	ld	s0,16(sp)
    8000388c:	64a2                	ld	s1,8(sp)
    8000388e:	6902                	ld	s2,0(sp)
    80003890:	6105                	addi	sp,sp,32
    80003892:	8082                	ret
    panic("freeing free block");
    80003894:	00005517          	auipc	a0,0x5
    80003898:	f1c50513          	addi	a0,a0,-228 # 800087b0 <sysnames+0xf8>
    8000389c:	ffffd097          	auipc	ra,0xffffd
    800038a0:	cac080e7          	jalr	-852(ra) # 80000548 <panic>

00000000800038a4 <balloc>:
{
    800038a4:	711d                	addi	sp,sp,-96
    800038a6:	ec86                	sd	ra,88(sp)
    800038a8:	e8a2                	sd	s0,80(sp)
    800038aa:	e4a6                	sd	s1,72(sp)
    800038ac:	e0ca                	sd	s2,64(sp)
    800038ae:	fc4e                	sd	s3,56(sp)
    800038b0:	f852                	sd	s4,48(sp)
    800038b2:	f456                	sd	s5,40(sp)
    800038b4:	f05a                	sd	s6,32(sp)
    800038b6:	ec5e                	sd	s7,24(sp)
    800038b8:	e862                	sd	s8,16(sp)
    800038ba:	e466                	sd	s9,8(sp)
    800038bc:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038be:	0001d797          	auipc	a5,0x1d
    800038c2:	9867a783          	lw	a5,-1658(a5) # 80020244 <sb+0x4>
    800038c6:	cbd1                	beqz	a5,8000395a <balloc+0xb6>
    800038c8:	8baa                	mv	s7,a0
    800038ca:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038cc:	0001db17          	auipc	s6,0x1d
    800038d0:	974b0b13          	addi	s6,s6,-1676 # 80020240 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038d4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038d6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038d8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038da:	6c89                	lui	s9,0x2
    800038dc:	a831                	j	800038f8 <balloc+0x54>
    brelse(bp);
    800038de:	854a                	mv	a0,s2
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	e32080e7          	jalr	-462(ra) # 80003712 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038e8:	015c87bb          	addw	a5,s9,s5
    800038ec:	00078a9b          	sext.w	s5,a5
    800038f0:	004b2703          	lw	a4,4(s6)
    800038f4:	06eaf363          	bgeu	s5,a4,8000395a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800038f8:	41fad79b          	sraiw	a5,s5,0x1f
    800038fc:	0137d79b          	srliw	a5,a5,0x13
    80003900:	015787bb          	addw	a5,a5,s5
    80003904:	40d7d79b          	sraiw	a5,a5,0xd
    80003908:	01cb2583          	lw	a1,28(s6)
    8000390c:	9dbd                	addw	a1,a1,a5
    8000390e:	855e                	mv	a0,s7
    80003910:	00000097          	auipc	ra,0x0
    80003914:	cd2080e7          	jalr	-814(ra) # 800035e2 <bread>
    80003918:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000391a:	004b2503          	lw	a0,4(s6)
    8000391e:	000a849b          	sext.w	s1,s5
    80003922:	8662                	mv	a2,s8
    80003924:	faa4fde3          	bgeu	s1,a0,800038de <balloc+0x3a>
      m = 1 << (bi % 8);
    80003928:	41f6579b          	sraiw	a5,a2,0x1f
    8000392c:	01d7d69b          	srliw	a3,a5,0x1d
    80003930:	00c6873b          	addw	a4,a3,a2
    80003934:	00777793          	andi	a5,a4,7
    80003938:	9f95                	subw	a5,a5,a3
    8000393a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000393e:	4037571b          	sraiw	a4,a4,0x3
    80003942:	00e906b3          	add	a3,s2,a4
    80003946:	0586c683          	lbu	a3,88(a3)
    8000394a:	00d7f5b3          	and	a1,a5,a3
    8000394e:	cd91                	beqz	a1,8000396a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003950:	2605                	addiw	a2,a2,1
    80003952:	2485                	addiw	s1,s1,1
    80003954:	fd4618e3          	bne	a2,s4,80003924 <balloc+0x80>
    80003958:	b759                	j	800038de <balloc+0x3a>
  panic("balloc: out of blocks");
    8000395a:	00005517          	auipc	a0,0x5
    8000395e:	e6e50513          	addi	a0,a0,-402 # 800087c8 <sysnames+0x110>
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	be6080e7          	jalr	-1050(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000396a:	974a                	add	a4,a4,s2
    8000396c:	8fd5                	or	a5,a5,a3
    8000396e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003972:	854a                	mv	a0,s2
    80003974:	00001097          	auipc	ra,0x1
    80003978:	002080e7          	jalr	2(ra) # 80004976 <log_write>
        brelse(bp);
    8000397c:	854a                	mv	a0,s2
    8000397e:	00000097          	auipc	ra,0x0
    80003982:	d94080e7          	jalr	-620(ra) # 80003712 <brelse>
  bp = bread(dev, bno);
    80003986:	85a6                	mv	a1,s1
    80003988:	855e                	mv	a0,s7
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	c58080e7          	jalr	-936(ra) # 800035e2 <bread>
    80003992:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003994:	40000613          	li	a2,1024
    80003998:	4581                	li	a1,0
    8000399a:	05850513          	addi	a0,a0,88
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	3b8080e7          	jalr	952(ra) # 80000d56 <memset>
  log_write(bp);
    800039a6:	854a                	mv	a0,s2
    800039a8:	00001097          	auipc	ra,0x1
    800039ac:	fce080e7          	jalr	-50(ra) # 80004976 <log_write>
  brelse(bp);
    800039b0:	854a                	mv	a0,s2
    800039b2:	00000097          	auipc	ra,0x0
    800039b6:	d60080e7          	jalr	-672(ra) # 80003712 <brelse>
}
    800039ba:	8526                	mv	a0,s1
    800039bc:	60e6                	ld	ra,88(sp)
    800039be:	6446                	ld	s0,80(sp)
    800039c0:	64a6                	ld	s1,72(sp)
    800039c2:	6906                	ld	s2,64(sp)
    800039c4:	79e2                	ld	s3,56(sp)
    800039c6:	7a42                	ld	s4,48(sp)
    800039c8:	7aa2                	ld	s5,40(sp)
    800039ca:	7b02                	ld	s6,32(sp)
    800039cc:	6be2                	ld	s7,24(sp)
    800039ce:	6c42                	ld	s8,16(sp)
    800039d0:	6ca2                	ld	s9,8(sp)
    800039d2:	6125                	addi	sp,sp,96
    800039d4:	8082                	ret

00000000800039d6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800039d6:	7179                	addi	sp,sp,-48
    800039d8:	f406                	sd	ra,40(sp)
    800039da:	f022                	sd	s0,32(sp)
    800039dc:	ec26                	sd	s1,24(sp)
    800039de:	e84a                	sd	s2,16(sp)
    800039e0:	e44e                	sd	s3,8(sp)
    800039e2:	e052                	sd	s4,0(sp)
    800039e4:	1800                	addi	s0,sp,48
    800039e6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039e8:	47ad                	li	a5,11
    800039ea:	04b7fe63          	bgeu	a5,a1,80003a46 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800039ee:	ff45849b          	addiw	s1,a1,-12
    800039f2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039f6:	0ff00793          	li	a5,255
    800039fa:	0ae7e363          	bltu	a5,a4,80003aa0 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800039fe:	08052583          	lw	a1,128(a0)
    80003a02:	c5ad                	beqz	a1,80003a6c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a04:	00092503          	lw	a0,0(s2)
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	bda080e7          	jalr	-1062(ra) # 800035e2 <bread>
    80003a10:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a12:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a16:	02049593          	slli	a1,s1,0x20
    80003a1a:	9181                	srli	a1,a1,0x20
    80003a1c:	058a                	slli	a1,a1,0x2
    80003a1e:	00b784b3          	add	s1,a5,a1
    80003a22:	0004a983          	lw	s3,0(s1)
    80003a26:	04098d63          	beqz	s3,80003a80 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a2a:	8552                	mv	a0,s4
    80003a2c:	00000097          	auipc	ra,0x0
    80003a30:	ce6080e7          	jalr	-794(ra) # 80003712 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a34:	854e                	mv	a0,s3
    80003a36:	70a2                	ld	ra,40(sp)
    80003a38:	7402                	ld	s0,32(sp)
    80003a3a:	64e2                	ld	s1,24(sp)
    80003a3c:	6942                	ld	s2,16(sp)
    80003a3e:	69a2                	ld	s3,8(sp)
    80003a40:	6a02                	ld	s4,0(sp)
    80003a42:	6145                	addi	sp,sp,48
    80003a44:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a46:	02059493          	slli	s1,a1,0x20
    80003a4a:	9081                	srli	s1,s1,0x20
    80003a4c:	048a                	slli	s1,s1,0x2
    80003a4e:	94aa                	add	s1,s1,a0
    80003a50:	0504a983          	lw	s3,80(s1)
    80003a54:	fe0990e3          	bnez	s3,80003a34 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003a58:	4108                	lw	a0,0(a0)
    80003a5a:	00000097          	auipc	ra,0x0
    80003a5e:	e4a080e7          	jalr	-438(ra) # 800038a4 <balloc>
    80003a62:	0005099b          	sext.w	s3,a0
    80003a66:	0534a823          	sw	s3,80(s1)
    80003a6a:	b7e9                	j	80003a34 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003a6c:	4108                	lw	a0,0(a0)
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	e36080e7          	jalr	-458(ra) # 800038a4 <balloc>
    80003a76:	0005059b          	sext.w	a1,a0
    80003a7a:	08b92023          	sw	a1,128(s2)
    80003a7e:	b759                	j	80003a04 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003a80:	00092503          	lw	a0,0(s2)
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	e20080e7          	jalr	-480(ra) # 800038a4 <balloc>
    80003a8c:	0005099b          	sext.w	s3,a0
    80003a90:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003a94:	8552                	mv	a0,s4
    80003a96:	00001097          	auipc	ra,0x1
    80003a9a:	ee0080e7          	jalr	-288(ra) # 80004976 <log_write>
    80003a9e:	b771                	j	80003a2a <bmap+0x54>
  panic("bmap: out of range");
    80003aa0:	00005517          	auipc	a0,0x5
    80003aa4:	d4050513          	addi	a0,a0,-704 # 800087e0 <sysnames+0x128>
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	aa0080e7          	jalr	-1376(ra) # 80000548 <panic>

0000000080003ab0 <iget>:
{
    80003ab0:	7179                	addi	sp,sp,-48
    80003ab2:	f406                	sd	ra,40(sp)
    80003ab4:	f022                	sd	s0,32(sp)
    80003ab6:	ec26                	sd	s1,24(sp)
    80003ab8:	e84a                	sd	s2,16(sp)
    80003aba:	e44e                	sd	s3,8(sp)
    80003abc:	e052                	sd	s4,0(sp)
    80003abe:	1800                	addi	s0,sp,48
    80003ac0:	89aa                	mv	s3,a0
    80003ac2:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003ac4:	0001c517          	auipc	a0,0x1c
    80003ac8:	79c50513          	addi	a0,a0,1948 # 80020260 <icache>
    80003acc:	ffffd097          	auipc	ra,0xffffd
    80003ad0:	18e080e7          	jalr	398(ra) # 80000c5a <acquire>
  empty = 0;
    80003ad4:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003ad6:	0001c497          	auipc	s1,0x1c
    80003ada:	7a248493          	addi	s1,s1,1954 # 80020278 <icache+0x18>
    80003ade:	0001e697          	auipc	a3,0x1e
    80003ae2:	22a68693          	addi	a3,a3,554 # 80021d08 <log>
    80003ae6:	a039                	j	80003af4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ae8:	02090b63          	beqz	s2,80003b1e <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003aec:	08848493          	addi	s1,s1,136
    80003af0:	02d48a63          	beq	s1,a3,80003b24 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003af4:	449c                	lw	a5,8(s1)
    80003af6:	fef059e3          	blez	a5,80003ae8 <iget+0x38>
    80003afa:	4098                	lw	a4,0(s1)
    80003afc:	ff3716e3          	bne	a4,s3,80003ae8 <iget+0x38>
    80003b00:	40d8                	lw	a4,4(s1)
    80003b02:	ff4713e3          	bne	a4,s4,80003ae8 <iget+0x38>
      ip->ref++;
    80003b06:	2785                	addiw	a5,a5,1
    80003b08:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003b0a:	0001c517          	auipc	a0,0x1c
    80003b0e:	75650513          	addi	a0,a0,1878 # 80020260 <icache>
    80003b12:	ffffd097          	auipc	ra,0xffffd
    80003b16:	1fc080e7          	jalr	508(ra) # 80000d0e <release>
      return ip;
    80003b1a:	8926                	mv	s2,s1
    80003b1c:	a03d                	j	80003b4a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b1e:	f7f9                	bnez	a5,80003aec <iget+0x3c>
    80003b20:	8926                	mv	s2,s1
    80003b22:	b7e9                	j	80003aec <iget+0x3c>
  if(empty == 0)
    80003b24:	02090c63          	beqz	s2,80003b5c <iget+0xac>
  ip->dev = dev;
    80003b28:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b2c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b30:	4785                	li	a5,1
    80003b32:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b36:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003b3a:	0001c517          	auipc	a0,0x1c
    80003b3e:	72650513          	addi	a0,a0,1830 # 80020260 <icache>
    80003b42:	ffffd097          	auipc	ra,0xffffd
    80003b46:	1cc080e7          	jalr	460(ra) # 80000d0e <release>
}
    80003b4a:	854a                	mv	a0,s2
    80003b4c:	70a2                	ld	ra,40(sp)
    80003b4e:	7402                	ld	s0,32(sp)
    80003b50:	64e2                	ld	s1,24(sp)
    80003b52:	6942                	ld	s2,16(sp)
    80003b54:	69a2                	ld	s3,8(sp)
    80003b56:	6a02                	ld	s4,0(sp)
    80003b58:	6145                	addi	sp,sp,48
    80003b5a:	8082                	ret
    panic("iget: no inodes");
    80003b5c:	00005517          	auipc	a0,0x5
    80003b60:	c9c50513          	addi	a0,a0,-868 # 800087f8 <sysnames+0x140>
    80003b64:	ffffd097          	auipc	ra,0xffffd
    80003b68:	9e4080e7          	jalr	-1564(ra) # 80000548 <panic>

0000000080003b6c <fsinit>:
fsinit(int dev) {
    80003b6c:	7179                	addi	sp,sp,-48
    80003b6e:	f406                	sd	ra,40(sp)
    80003b70:	f022                	sd	s0,32(sp)
    80003b72:	ec26                	sd	s1,24(sp)
    80003b74:	e84a                	sd	s2,16(sp)
    80003b76:	e44e                	sd	s3,8(sp)
    80003b78:	1800                	addi	s0,sp,48
    80003b7a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b7c:	4585                	li	a1,1
    80003b7e:	00000097          	auipc	ra,0x0
    80003b82:	a64080e7          	jalr	-1436(ra) # 800035e2 <bread>
    80003b86:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b88:	0001c997          	auipc	s3,0x1c
    80003b8c:	6b898993          	addi	s3,s3,1720 # 80020240 <sb>
    80003b90:	02000613          	li	a2,32
    80003b94:	05850593          	addi	a1,a0,88
    80003b98:	854e                	mv	a0,s3
    80003b9a:	ffffd097          	auipc	ra,0xffffd
    80003b9e:	21c080e7          	jalr	540(ra) # 80000db6 <memmove>
  brelse(bp);
    80003ba2:	8526                	mv	a0,s1
    80003ba4:	00000097          	auipc	ra,0x0
    80003ba8:	b6e080e7          	jalr	-1170(ra) # 80003712 <brelse>
  if(sb.magic != FSMAGIC)
    80003bac:	0009a703          	lw	a4,0(s3)
    80003bb0:	102037b7          	lui	a5,0x10203
    80003bb4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003bb8:	02f71263          	bne	a4,a5,80003bdc <fsinit+0x70>
  initlog(dev, &sb);
    80003bbc:	0001c597          	auipc	a1,0x1c
    80003bc0:	68458593          	addi	a1,a1,1668 # 80020240 <sb>
    80003bc4:	854a                	mv	a0,s2
    80003bc6:	00001097          	auipc	ra,0x1
    80003bca:	b38080e7          	jalr	-1224(ra) # 800046fe <initlog>
}
    80003bce:	70a2                	ld	ra,40(sp)
    80003bd0:	7402                	ld	s0,32(sp)
    80003bd2:	64e2                	ld	s1,24(sp)
    80003bd4:	6942                	ld	s2,16(sp)
    80003bd6:	69a2                	ld	s3,8(sp)
    80003bd8:	6145                	addi	sp,sp,48
    80003bda:	8082                	ret
    panic("invalid file system");
    80003bdc:	00005517          	auipc	a0,0x5
    80003be0:	c2c50513          	addi	a0,a0,-980 # 80008808 <sysnames+0x150>
    80003be4:	ffffd097          	auipc	ra,0xffffd
    80003be8:	964080e7          	jalr	-1692(ra) # 80000548 <panic>

0000000080003bec <iinit>:
{
    80003bec:	7179                	addi	sp,sp,-48
    80003bee:	f406                	sd	ra,40(sp)
    80003bf0:	f022                	sd	s0,32(sp)
    80003bf2:	ec26                	sd	s1,24(sp)
    80003bf4:	e84a                	sd	s2,16(sp)
    80003bf6:	e44e                	sd	s3,8(sp)
    80003bf8:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003bfa:	00005597          	auipc	a1,0x5
    80003bfe:	c2658593          	addi	a1,a1,-986 # 80008820 <sysnames+0x168>
    80003c02:	0001c517          	auipc	a0,0x1c
    80003c06:	65e50513          	addi	a0,a0,1630 # 80020260 <icache>
    80003c0a:	ffffd097          	auipc	ra,0xffffd
    80003c0e:	fc0080e7          	jalr	-64(ra) # 80000bca <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c12:	0001c497          	auipc	s1,0x1c
    80003c16:	67648493          	addi	s1,s1,1654 # 80020288 <icache+0x28>
    80003c1a:	0001e997          	auipc	s3,0x1e
    80003c1e:	0fe98993          	addi	s3,s3,254 # 80021d18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003c22:	00005917          	auipc	s2,0x5
    80003c26:	c0690913          	addi	s2,s2,-1018 # 80008828 <sysnames+0x170>
    80003c2a:	85ca                	mv	a1,s2
    80003c2c:	8526                	mv	a0,s1
    80003c2e:	00001097          	auipc	ra,0x1
    80003c32:	e36080e7          	jalr	-458(ra) # 80004a64 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c36:	08848493          	addi	s1,s1,136
    80003c3a:	ff3498e3          	bne	s1,s3,80003c2a <iinit+0x3e>
}
    80003c3e:	70a2                	ld	ra,40(sp)
    80003c40:	7402                	ld	s0,32(sp)
    80003c42:	64e2                	ld	s1,24(sp)
    80003c44:	6942                	ld	s2,16(sp)
    80003c46:	69a2                	ld	s3,8(sp)
    80003c48:	6145                	addi	sp,sp,48
    80003c4a:	8082                	ret

0000000080003c4c <ialloc>:
{
    80003c4c:	715d                	addi	sp,sp,-80
    80003c4e:	e486                	sd	ra,72(sp)
    80003c50:	e0a2                	sd	s0,64(sp)
    80003c52:	fc26                	sd	s1,56(sp)
    80003c54:	f84a                	sd	s2,48(sp)
    80003c56:	f44e                	sd	s3,40(sp)
    80003c58:	f052                	sd	s4,32(sp)
    80003c5a:	ec56                	sd	s5,24(sp)
    80003c5c:	e85a                	sd	s6,16(sp)
    80003c5e:	e45e                	sd	s7,8(sp)
    80003c60:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c62:	0001c717          	auipc	a4,0x1c
    80003c66:	5ea72703          	lw	a4,1514(a4) # 8002024c <sb+0xc>
    80003c6a:	4785                	li	a5,1
    80003c6c:	04e7fa63          	bgeu	a5,a4,80003cc0 <ialloc+0x74>
    80003c70:	8aaa                	mv	s5,a0
    80003c72:	8bae                	mv	s7,a1
    80003c74:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c76:	0001ca17          	auipc	s4,0x1c
    80003c7a:	5caa0a13          	addi	s4,s4,1482 # 80020240 <sb>
    80003c7e:	00048b1b          	sext.w	s6,s1
    80003c82:	0044d593          	srli	a1,s1,0x4
    80003c86:	018a2783          	lw	a5,24(s4)
    80003c8a:	9dbd                	addw	a1,a1,a5
    80003c8c:	8556                	mv	a0,s5
    80003c8e:	00000097          	auipc	ra,0x0
    80003c92:	954080e7          	jalr	-1708(ra) # 800035e2 <bread>
    80003c96:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c98:	05850993          	addi	s3,a0,88
    80003c9c:	00f4f793          	andi	a5,s1,15
    80003ca0:	079a                	slli	a5,a5,0x6
    80003ca2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ca4:	00099783          	lh	a5,0(s3)
    80003ca8:	c785                	beqz	a5,80003cd0 <ialloc+0x84>
    brelse(bp);
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	a68080e7          	jalr	-1432(ra) # 80003712 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cb2:	0485                	addi	s1,s1,1
    80003cb4:	00ca2703          	lw	a4,12(s4)
    80003cb8:	0004879b          	sext.w	a5,s1
    80003cbc:	fce7e1e3          	bltu	a5,a4,80003c7e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003cc0:	00005517          	auipc	a0,0x5
    80003cc4:	b7050513          	addi	a0,a0,-1168 # 80008830 <sysnames+0x178>
    80003cc8:	ffffd097          	auipc	ra,0xffffd
    80003ccc:	880080e7          	jalr	-1920(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003cd0:	04000613          	li	a2,64
    80003cd4:	4581                	li	a1,0
    80003cd6:	854e                	mv	a0,s3
    80003cd8:	ffffd097          	auipc	ra,0xffffd
    80003cdc:	07e080e7          	jalr	126(ra) # 80000d56 <memset>
      dip->type = type;
    80003ce0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ce4:	854a                	mv	a0,s2
    80003ce6:	00001097          	auipc	ra,0x1
    80003cea:	c90080e7          	jalr	-880(ra) # 80004976 <log_write>
      brelse(bp);
    80003cee:	854a                	mv	a0,s2
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	a22080e7          	jalr	-1502(ra) # 80003712 <brelse>
      return iget(dev, inum);
    80003cf8:	85da                	mv	a1,s6
    80003cfa:	8556                	mv	a0,s5
    80003cfc:	00000097          	auipc	ra,0x0
    80003d00:	db4080e7          	jalr	-588(ra) # 80003ab0 <iget>
}
    80003d04:	60a6                	ld	ra,72(sp)
    80003d06:	6406                	ld	s0,64(sp)
    80003d08:	74e2                	ld	s1,56(sp)
    80003d0a:	7942                	ld	s2,48(sp)
    80003d0c:	79a2                	ld	s3,40(sp)
    80003d0e:	7a02                	ld	s4,32(sp)
    80003d10:	6ae2                	ld	s5,24(sp)
    80003d12:	6b42                	ld	s6,16(sp)
    80003d14:	6ba2                	ld	s7,8(sp)
    80003d16:	6161                	addi	sp,sp,80
    80003d18:	8082                	ret

0000000080003d1a <iupdate>:
{
    80003d1a:	1101                	addi	sp,sp,-32
    80003d1c:	ec06                	sd	ra,24(sp)
    80003d1e:	e822                	sd	s0,16(sp)
    80003d20:	e426                	sd	s1,8(sp)
    80003d22:	e04a                	sd	s2,0(sp)
    80003d24:	1000                	addi	s0,sp,32
    80003d26:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d28:	415c                	lw	a5,4(a0)
    80003d2a:	0047d79b          	srliw	a5,a5,0x4
    80003d2e:	0001c597          	auipc	a1,0x1c
    80003d32:	52a5a583          	lw	a1,1322(a1) # 80020258 <sb+0x18>
    80003d36:	9dbd                	addw	a1,a1,a5
    80003d38:	4108                	lw	a0,0(a0)
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	8a8080e7          	jalr	-1880(ra) # 800035e2 <bread>
    80003d42:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d44:	05850793          	addi	a5,a0,88
    80003d48:	40c8                	lw	a0,4(s1)
    80003d4a:	893d                	andi	a0,a0,15
    80003d4c:	051a                	slli	a0,a0,0x6
    80003d4e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d50:	04449703          	lh	a4,68(s1)
    80003d54:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d58:	04649703          	lh	a4,70(s1)
    80003d5c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d60:	04849703          	lh	a4,72(s1)
    80003d64:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d68:	04a49703          	lh	a4,74(s1)
    80003d6c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d70:	44f8                	lw	a4,76(s1)
    80003d72:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d74:	03400613          	li	a2,52
    80003d78:	05048593          	addi	a1,s1,80
    80003d7c:	0531                	addi	a0,a0,12
    80003d7e:	ffffd097          	auipc	ra,0xffffd
    80003d82:	038080e7          	jalr	56(ra) # 80000db6 <memmove>
  log_write(bp);
    80003d86:	854a                	mv	a0,s2
    80003d88:	00001097          	auipc	ra,0x1
    80003d8c:	bee080e7          	jalr	-1042(ra) # 80004976 <log_write>
  brelse(bp);
    80003d90:	854a                	mv	a0,s2
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	980080e7          	jalr	-1664(ra) # 80003712 <brelse>
}
    80003d9a:	60e2                	ld	ra,24(sp)
    80003d9c:	6442                	ld	s0,16(sp)
    80003d9e:	64a2                	ld	s1,8(sp)
    80003da0:	6902                	ld	s2,0(sp)
    80003da2:	6105                	addi	sp,sp,32
    80003da4:	8082                	ret

0000000080003da6 <idup>:
{
    80003da6:	1101                	addi	sp,sp,-32
    80003da8:	ec06                	sd	ra,24(sp)
    80003daa:	e822                	sd	s0,16(sp)
    80003dac:	e426                	sd	s1,8(sp)
    80003dae:	1000                	addi	s0,sp,32
    80003db0:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003db2:	0001c517          	auipc	a0,0x1c
    80003db6:	4ae50513          	addi	a0,a0,1198 # 80020260 <icache>
    80003dba:	ffffd097          	auipc	ra,0xffffd
    80003dbe:	ea0080e7          	jalr	-352(ra) # 80000c5a <acquire>
  ip->ref++;
    80003dc2:	449c                	lw	a5,8(s1)
    80003dc4:	2785                	addiw	a5,a5,1
    80003dc6:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003dc8:	0001c517          	auipc	a0,0x1c
    80003dcc:	49850513          	addi	a0,a0,1176 # 80020260 <icache>
    80003dd0:	ffffd097          	auipc	ra,0xffffd
    80003dd4:	f3e080e7          	jalr	-194(ra) # 80000d0e <release>
}
    80003dd8:	8526                	mv	a0,s1
    80003dda:	60e2                	ld	ra,24(sp)
    80003ddc:	6442                	ld	s0,16(sp)
    80003dde:	64a2                	ld	s1,8(sp)
    80003de0:	6105                	addi	sp,sp,32
    80003de2:	8082                	ret

0000000080003de4 <ilock>:
{
    80003de4:	1101                	addi	sp,sp,-32
    80003de6:	ec06                	sd	ra,24(sp)
    80003de8:	e822                	sd	s0,16(sp)
    80003dea:	e426                	sd	s1,8(sp)
    80003dec:	e04a                	sd	s2,0(sp)
    80003dee:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003df0:	c115                	beqz	a0,80003e14 <ilock+0x30>
    80003df2:	84aa                	mv	s1,a0
    80003df4:	451c                	lw	a5,8(a0)
    80003df6:	00f05f63          	blez	a5,80003e14 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003dfa:	0541                	addi	a0,a0,16
    80003dfc:	00001097          	auipc	ra,0x1
    80003e00:	ca2080e7          	jalr	-862(ra) # 80004a9e <acquiresleep>
  if(ip->valid == 0){
    80003e04:	40bc                	lw	a5,64(s1)
    80003e06:	cf99                	beqz	a5,80003e24 <ilock+0x40>
}
    80003e08:	60e2                	ld	ra,24(sp)
    80003e0a:	6442                	ld	s0,16(sp)
    80003e0c:	64a2                	ld	s1,8(sp)
    80003e0e:	6902                	ld	s2,0(sp)
    80003e10:	6105                	addi	sp,sp,32
    80003e12:	8082                	ret
    panic("ilock");
    80003e14:	00005517          	auipc	a0,0x5
    80003e18:	a3450513          	addi	a0,a0,-1484 # 80008848 <sysnames+0x190>
    80003e1c:	ffffc097          	auipc	ra,0xffffc
    80003e20:	72c080e7          	jalr	1836(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e24:	40dc                	lw	a5,4(s1)
    80003e26:	0047d79b          	srliw	a5,a5,0x4
    80003e2a:	0001c597          	auipc	a1,0x1c
    80003e2e:	42e5a583          	lw	a1,1070(a1) # 80020258 <sb+0x18>
    80003e32:	9dbd                	addw	a1,a1,a5
    80003e34:	4088                	lw	a0,0(s1)
    80003e36:	fffff097          	auipc	ra,0xfffff
    80003e3a:	7ac080e7          	jalr	1964(ra) # 800035e2 <bread>
    80003e3e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e40:	05850593          	addi	a1,a0,88
    80003e44:	40dc                	lw	a5,4(s1)
    80003e46:	8bbd                	andi	a5,a5,15
    80003e48:	079a                	slli	a5,a5,0x6
    80003e4a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e4c:	00059783          	lh	a5,0(a1)
    80003e50:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e54:	00259783          	lh	a5,2(a1)
    80003e58:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e5c:	00459783          	lh	a5,4(a1)
    80003e60:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e64:	00659783          	lh	a5,6(a1)
    80003e68:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e6c:	459c                	lw	a5,8(a1)
    80003e6e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e70:	03400613          	li	a2,52
    80003e74:	05b1                	addi	a1,a1,12
    80003e76:	05048513          	addi	a0,s1,80
    80003e7a:	ffffd097          	auipc	ra,0xffffd
    80003e7e:	f3c080e7          	jalr	-196(ra) # 80000db6 <memmove>
    brelse(bp);
    80003e82:	854a                	mv	a0,s2
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	88e080e7          	jalr	-1906(ra) # 80003712 <brelse>
    ip->valid = 1;
    80003e8c:	4785                	li	a5,1
    80003e8e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e90:	04449783          	lh	a5,68(s1)
    80003e94:	fbb5                	bnez	a5,80003e08 <ilock+0x24>
      panic("ilock: no type");
    80003e96:	00005517          	auipc	a0,0x5
    80003e9a:	9ba50513          	addi	a0,a0,-1606 # 80008850 <sysnames+0x198>
    80003e9e:	ffffc097          	auipc	ra,0xffffc
    80003ea2:	6aa080e7          	jalr	1706(ra) # 80000548 <panic>

0000000080003ea6 <iunlock>:
{
    80003ea6:	1101                	addi	sp,sp,-32
    80003ea8:	ec06                	sd	ra,24(sp)
    80003eaa:	e822                	sd	s0,16(sp)
    80003eac:	e426                	sd	s1,8(sp)
    80003eae:	e04a                	sd	s2,0(sp)
    80003eb0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003eb2:	c905                	beqz	a0,80003ee2 <iunlock+0x3c>
    80003eb4:	84aa                	mv	s1,a0
    80003eb6:	01050913          	addi	s2,a0,16
    80003eba:	854a                	mv	a0,s2
    80003ebc:	00001097          	auipc	ra,0x1
    80003ec0:	c7c080e7          	jalr	-900(ra) # 80004b38 <holdingsleep>
    80003ec4:	cd19                	beqz	a0,80003ee2 <iunlock+0x3c>
    80003ec6:	449c                	lw	a5,8(s1)
    80003ec8:	00f05d63          	blez	a5,80003ee2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ecc:	854a                	mv	a0,s2
    80003ece:	00001097          	auipc	ra,0x1
    80003ed2:	c26080e7          	jalr	-986(ra) # 80004af4 <releasesleep>
}
    80003ed6:	60e2                	ld	ra,24(sp)
    80003ed8:	6442                	ld	s0,16(sp)
    80003eda:	64a2                	ld	s1,8(sp)
    80003edc:	6902                	ld	s2,0(sp)
    80003ede:	6105                	addi	sp,sp,32
    80003ee0:	8082                	ret
    panic("iunlock");
    80003ee2:	00005517          	auipc	a0,0x5
    80003ee6:	97e50513          	addi	a0,a0,-1666 # 80008860 <sysnames+0x1a8>
    80003eea:	ffffc097          	auipc	ra,0xffffc
    80003eee:	65e080e7          	jalr	1630(ra) # 80000548 <panic>

0000000080003ef2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ef2:	7179                	addi	sp,sp,-48
    80003ef4:	f406                	sd	ra,40(sp)
    80003ef6:	f022                	sd	s0,32(sp)
    80003ef8:	ec26                	sd	s1,24(sp)
    80003efa:	e84a                	sd	s2,16(sp)
    80003efc:	e44e                	sd	s3,8(sp)
    80003efe:	e052                	sd	s4,0(sp)
    80003f00:	1800                	addi	s0,sp,48
    80003f02:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f04:	05050493          	addi	s1,a0,80
    80003f08:	08050913          	addi	s2,a0,128
    80003f0c:	a021                	j	80003f14 <itrunc+0x22>
    80003f0e:	0491                	addi	s1,s1,4
    80003f10:	01248d63          	beq	s1,s2,80003f2a <itrunc+0x38>
    if(ip->addrs[i]){
    80003f14:	408c                	lw	a1,0(s1)
    80003f16:	dde5                	beqz	a1,80003f0e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f18:	0009a503          	lw	a0,0(s3)
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	90c080e7          	jalr	-1780(ra) # 80003828 <bfree>
      ip->addrs[i] = 0;
    80003f24:	0004a023          	sw	zero,0(s1)
    80003f28:	b7dd                	j	80003f0e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f2a:	0809a583          	lw	a1,128(s3)
    80003f2e:	e185                	bnez	a1,80003f4e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f30:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f34:	854e                	mv	a0,s3
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	de4080e7          	jalr	-540(ra) # 80003d1a <iupdate>
}
    80003f3e:	70a2                	ld	ra,40(sp)
    80003f40:	7402                	ld	s0,32(sp)
    80003f42:	64e2                	ld	s1,24(sp)
    80003f44:	6942                	ld	s2,16(sp)
    80003f46:	69a2                	ld	s3,8(sp)
    80003f48:	6a02                	ld	s4,0(sp)
    80003f4a:	6145                	addi	sp,sp,48
    80003f4c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f4e:	0009a503          	lw	a0,0(s3)
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	690080e7          	jalr	1680(ra) # 800035e2 <bread>
    80003f5a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f5c:	05850493          	addi	s1,a0,88
    80003f60:	45850913          	addi	s2,a0,1112
    80003f64:	a811                	j	80003f78 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003f66:	0009a503          	lw	a0,0(s3)
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	8be080e7          	jalr	-1858(ra) # 80003828 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003f72:	0491                	addi	s1,s1,4
    80003f74:	01248563          	beq	s1,s2,80003f7e <itrunc+0x8c>
      if(a[j])
    80003f78:	408c                	lw	a1,0(s1)
    80003f7a:	dde5                	beqz	a1,80003f72 <itrunc+0x80>
    80003f7c:	b7ed                	j	80003f66 <itrunc+0x74>
    brelse(bp);
    80003f7e:	8552                	mv	a0,s4
    80003f80:	fffff097          	auipc	ra,0xfffff
    80003f84:	792080e7          	jalr	1938(ra) # 80003712 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f88:	0809a583          	lw	a1,128(s3)
    80003f8c:	0009a503          	lw	a0,0(s3)
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	898080e7          	jalr	-1896(ra) # 80003828 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f98:	0809a023          	sw	zero,128(s3)
    80003f9c:	bf51                	j	80003f30 <itrunc+0x3e>

0000000080003f9e <iput>:
{
    80003f9e:	1101                	addi	sp,sp,-32
    80003fa0:	ec06                	sd	ra,24(sp)
    80003fa2:	e822                	sd	s0,16(sp)
    80003fa4:	e426                	sd	s1,8(sp)
    80003fa6:	e04a                	sd	s2,0(sp)
    80003fa8:	1000                	addi	s0,sp,32
    80003faa:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003fac:	0001c517          	auipc	a0,0x1c
    80003fb0:	2b450513          	addi	a0,a0,692 # 80020260 <icache>
    80003fb4:	ffffd097          	auipc	ra,0xffffd
    80003fb8:	ca6080e7          	jalr	-858(ra) # 80000c5a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fbc:	4498                	lw	a4,8(s1)
    80003fbe:	4785                	li	a5,1
    80003fc0:	02f70363          	beq	a4,a5,80003fe6 <iput+0x48>
  ip->ref--;
    80003fc4:	449c                	lw	a5,8(s1)
    80003fc6:	37fd                	addiw	a5,a5,-1
    80003fc8:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003fca:	0001c517          	auipc	a0,0x1c
    80003fce:	29650513          	addi	a0,a0,662 # 80020260 <icache>
    80003fd2:	ffffd097          	auipc	ra,0xffffd
    80003fd6:	d3c080e7          	jalr	-708(ra) # 80000d0e <release>
}
    80003fda:	60e2                	ld	ra,24(sp)
    80003fdc:	6442                	ld	s0,16(sp)
    80003fde:	64a2                	ld	s1,8(sp)
    80003fe0:	6902                	ld	s2,0(sp)
    80003fe2:	6105                	addi	sp,sp,32
    80003fe4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fe6:	40bc                	lw	a5,64(s1)
    80003fe8:	dff1                	beqz	a5,80003fc4 <iput+0x26>
    80003fea:	04a49783          	lh	a5,74(s1)
    80003fee:	fbf9                	bnez	a5,80003fc4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ff0:	01048913          	addi	s2,s1,16
    80003ff4:	854a                	mv	a0,s2
    80003ff6:	00001097          	auipc	ra,0x1
    80003ffa:	aa8080e7          	jalr	-1368(ra) # 80004a9e <acquiresleep>
    release(&icache.lock);
    80003ffe:	0001c517          	auipc	a0,0x1c
    80004002:	26250513          	addi	a0,a0,610 # 80020260 <icache>
    80004006:	ffffd097          	auipc	ra,0xffffd
    8000400a:	d08080e7          	jalr	-760(ra) # 80000d0e <release>
    itrunc(ip);
    8000400e:	8526                	mv	a0,s1
    80004010:	00000097          	auipc	ra,0x0
    80004014:	ee2080e7          	jalr	-286(ra) # 80003ef2 <itrunc>
    ip->type = 0;
    80004018:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000401c:	8526                	mv	a0,s1
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	cfc080e7          	jalr	-772(ra) # 80003d1a <iupdate>
    ip->valid = 0;
    80004026:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000402a:	854a                	mv	a0,s2
    8000402c:	00001097          	auipc	ra,0x1
    80004030:	ac8080e7          	jalr	-1336(ra) # 80004af4 <releasesleep>
    acquire(&icache.lock);
    80004034:	0001c517          	auipc	a0,0x1c
    80004038:	22c50513          	addi	a0,a0,556 # 80020260 <icache>
    8000403c:	ffffd097          	auipc	ra,0xffffd
    80004040:	c1e080e7          	jalr	-994(ra) # 80000c5a <acquire>
    80004044:	b741                	j	80003fc4 <iput+0x26>

0000000080004046 <iunlockput>:
{
    80004046:	1101                	addi	sp,sp,-32
    80004048:	ec06                	sd	ra,24(sp)
    8000404a:	e822                	sd	s0,16(sp)
    8000404c:	e426                	sd	s1,8(sp)
    8000404e:	1000                	addi	s0,sp,32
    80004050:	84aa                	mv	s1,a0
  iunlock(ip);
    80004052:	00000097          	auipc	ra,0x0
    80004056:	e54080e7          	jalr	-428(ra) # 80003ea6 <iunlock>
  iput(ip);
    8000405a:	8526                	mv	a0,s1
    8000405c:	00000097          	auipc	ra,0x0
    80004060:	f42080e7          	jalr	-190(ra) # 80003f9e <iput>
}
    80004064:	60e2                	ld	ra,24(sp)
    80004066:	6442                	ld	s0,16(sp)
    80004068:	64a2                	ld	s1,8(sp)
    8000406a:	6105                	addi	sp,sp,32
    8000406c:	8082                	ret

000000008000406e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000406e:	1141                	addi	sp,sp,-16
    80004070:	e422                	sd	s0,8(sp)
    80004072:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004074:	411c                	lw	a5,0(a0)
    80004076:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004078:	415c                	lw	a5,4(a0)
    8000407a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000407c:	04451783          	lh	a5,68(a0)
    80004080:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004084:	04a51783          	lh	a5,74(a0)
    80004088:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000408c:	04c56783          	lwu	a5,76(a0)
    80004090:	e99c                	sd	a5,16(a1)
}
    80004092:	6422                	ld	s0,8(sp)
    80004094:	0141                	addi	sp,sp,16
    80004096:	8082                	ret

0000000080004098 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004098:	457c                	lw	a5,76(a0)
    8000409a:	0ed7e863          	bltu	a5,a3,8000418a <readi+0xf2>
{
    8000409e:	7159                	addi	sp,sp,-112
    800040a0:	f486                	sd	ra,104(sp)
    800040a2:	f0a2                	sd	s0,96(sp)
    800040a4:	eca6                	sd	s1,88(sp)
    800040a6:	e8ca                	sd	s2,80(sp)
    800040a8:	e4ce                	sd	s3,72(sp)
    800040aa:	e0d2                	sd	s4,64(sp)
    800040ac:	fc56                	sd	s5,56(sp)
    800040ae:	f85a                	sd	s6,48(sp)
    800040b0:	f45e                	sd	s7,40(sp)
    800040b2:	f062                	sd	s8,32(sp)
    800040b4:	ec66                	sd	s9,24(sp)
    800040b6:	e86a                	sd	s10,16(sp)
    800040b8:	e46e                	sd	s11,8(sp)
    800040ba:	1880                	addi	s0,sp,112
    800040bc:	8baa                	mv	s7,a0
    800040be:	8c2e                	mv	s8,a1
    800040c0:	8ab2                	mv	s5,a2
    800040c2:	84b6                	mv	s1,a3
    800040c4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040c6:	9f35                	addw	a4,a4,a3
    return 0;
    800040c8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040ca:	08d76f63          	bltu	a4,a3,80004168 <readi+0xd0>
  if(off + n > ip->size)
    800040ce:	00e7f463          	bgeu	a5,a4,800040d6 <readi+0x3e>
    n = ip->size - off;
    800040d2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040d6:	0a0b0863          	beqz	s6,80004186 <readi+0xee>
    800040da:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040dc:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040e0:	5cfd                	li	s9,-1
    800040e2:	a82d                	j	8000411c <readi+0x84>
    800040e4:	020a1d93          	slli	s11,s4,0x20
    800040e8:	020ddd93          	srli	s11,s11,0x20
    800040ec:	05890613          	addi	a2,s2,88
    800040f0:	86ee                	mv	a3,s11
    800040f2:	963a                	add	a2,a2,a4
    800040f4:	85d6                	mv	a1,s5
    800040f6:	8562                	mv	a0,s8
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	9fe080e7          	jalr	-1538(ra) # 80002af6 <either_copyout>
    80004100:	05950d63          	beq	a0,s9,8000415a <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80004104:	854a                	mv	a0,s2
    80004106:	fffff097          	auipc	ra,0xfffff
    8000410a:	60c080e7          	jalr	1548(ra) # 80003712 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000410e:	013a09bb          	addw	s3,s4,s3
    80004112:	009a04bb          	addw	s1,s4,s1
    80004116:	9aee                	add	s5,s5,s11
    80004118:	0569f663          	bgeu	s3,s6,80004164 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000411c:	000ba903          	lw	s2,0(s7)
    80004120:	00a4d59b          	srliw	a1,s1,0xa
    80004124:	855e                	mv	a0,s7
    80004126:	00000097          	auipc	ra,0x0
    8000412a:	8b0080e7          	jalr	-1872(ra) # 800039d6 <bmap>
    8000412e:	0005059b          	sext.w	a1,a0
    80004132:	854a                	mv	a0,s2
    80004134:	fffff097          	auipc	ra,0xfffff
    80004138:	4ae080e7          	jalr	1198(ra) # 800035e2 <bread>
    8000413c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000413e:	3ff4f713          	andi	a4,s1,1023
    80004142:	40ed07bb          	subw	a5,s10,a4
    80004146:	413b06bb          	subw	a3,s6,s3
    8000414a:	8a3e                	mv	s4,a5
    8000414c:	2781                	sext.w	a5,a5
    8000414e:	0006861b          	sext.w	a2,a3
    80004152:	f8f679e3          	bgeu	a2,a5,800040e4 <readi+0x4c>
    80004156:	8a36                	mv	s4,a3
    80004158:	b771                	j	800040e4 <readi+0x4c>
      brelse(bp);
    8000415a:	854a                	mv	a0,s2
    8000415c:	fffff097          	auipc	ra,0xfffff
    80004160:	5b6080e7          	jalr	1462(ra) # 80003712 <brelse>
  }
  return tot;
    80004164:	0009851b          	sext.w	a0,s3
}
    80004168:	70a6                	ld	ra,104(sp)
    8000416a:	7406                	ld	s0,96(sp)
    8000416c:	64e6                	ld	s1,88(sp)
    8000416e:	6946                	ld	s2,80(sp)
    80004170:	69a6                	ld	s3,72(sp)
    80004172:	6a06                	ld	s4,64(sp)
    80004174:	7ae2                	ld	s5,56(sp)
    80004176:	7b42                	ld	s6,48(sp)
    80004178:	7ba2                	ld	s7,40(sp)
    8000417a:	7c02                	ld	s8,32(sp)
    8000417c:	6ce2                	ld	s9,24(sp)
    8000417e:	6d42                	ld	s10,16(sp)
    80004180:	6da2                	ld	s11,8(sp)
    80004182:	6165                	addi	sp,sp,112
    80004184:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004186:	89da                	mv	s3,s6
    80004188:	bff1                	j	80004164 <readi+0xcc>
    return 0;
    8000418a:	4501                	li	a0,0
}
    8000418c:	8082                	ret

000000008000418e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000418e:	457c                	lw	a5,76(a0)
    80004190:	10d7e663          	bltu	a5,a3,8000429c <writei+0x10e>
{
    80004194:	7159                	addi	sp,sp,-112
    80004196:	f486                	sd	ra,104(sp)
    80004198:	f0a2                	sd	s0,96(sp)
    8000419a:	eca6                	sd	s1,88(sp)
    8000419c:	e8ca                	sd	s2,80(sp)
    8000419e:	e4ce                	sd	s3,72(sp)
    800041a0:	e0d2                	sd	s4,64(sp)
    800041a2:	fc56                	sd	s5,56(sp)
    800041a4:	f85a                	sd	s6,48(sp)
    800041a6:	f45e                	sd	s7,40(sp)
    800041a8:	f062                	sd	s8,32(sp)
    800041aa:	ec66                	sd	s9,24(sp)
    800041ac:	e86a                	sd	s10,16(sp)
    800041ae:	e46e                	sd	s11,8(sp)
    800041b0:	1880                	addi	s0,sp,112
    800041b2:	8baa                	mv	s7,a0
    800041b4:	8c2e                	mv	s8,a1
    800041b6:	8ab2                	mv	s5,a2
    800041b8:	8936                	mv	s2,a3
    800041ba:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800041bc:	00e687bb          	addw	a5,a3,a4
    800041c0:	0ed7e063          	bltu	a5,a3,800042a0 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041c4:	00043737          	lui	a4,0x43
    800041c8:	0cf76e63          	bltu	a4,a5,800042a4 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041cc:	0a0b0763          	beqz	s6,8000427a <writei+0xec>
    800041d0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041d2:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041d6:	5cfd                	li	s9,-1
    800041d8:	a091                	j	8000421c <writei+0x8e>
    800041da:	02099d93          	slli	s11,s3,0x20
    800041de:	020ddd93          	srli	s11,s11,0x20
    800041e2:	05848513          	addi	a0,s1,88
    800041e6:	86ee                	mv	a3,s11
    800041e8:	8656                	mv	a2,s5
    800041ea:	85e2                	mv	a1,s8
    800041ec:	953a                	add	a0,a0,a4
    800041ee:	fffff097          	auipc	ra,0xfffff
    800041f2:	95e080e7          	jalr	-1698(ra) # 80002b4c <either_copyin>
    800041f6:	07950263          	beq	a0,s9,8000425a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041fa:	8526                	mv	a0,s1
    800041fc:	00000097          	auipc	ra,0x0
    80004200:	77a080e7          	jalr	1914(ra) # 80004976 <log_write>
    brelse(bp);
    80004204:	8526                	mv	a0,s1
    80004206:	fffff097          	auipc	ra,0xfffff
    8000420a:	50c080e7          	jalr	1292(ra) # 80003712 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000420e:	01498a3b          	addw	s4,s3,s4
    80004212:	0129893b          	addw	s2,s3,s2
    80004216:	9aee                	add	s5,s5,s11
    80004218:	056a7663          	bgeu	s4,s6,80004264 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000421c:	000ba483          	lw	s1,0(s7)
    80004220:	00a9559b          	srliw	a1,s2,0xa
    80004224:	855e                	mv	a0,s7
    80004226:	fffff097          	auipc	ra,0xfffff
    8000422a:	7b0080e7          	jalr	1968(ra) # 800039d6 <bmap>
    8000422e:	0005059b          	sext.w	a1,a0
    80004232:	8526                	mv	a0,s1
    80004234:	fffff097          	auipc	ra,0xfffff
    80004238:	3ae080e7          	jalr	942(ra) # 800035e2 <bread>
    8000423c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000423e:	3ff97713          	andi	a4,s2,1023
    80004242:	40ed07bb          	subw	a5,s10,a4
    80004246:	414b06bb          	subw	a3,s6,s4
    8000424a:	89be                	mv	s3,a5
    8000424c:	2781                	sext.w	a5,a5
    8000424e:	0006861b          	sext.w	a2,a3
    80004252:	f8f674e3          	bgeu	a2,a5,800041da <writei+0x4c>
    80004256:	89b6                	mv	s3,a3
    80004258:	b749                	j	800041da <writei+0x4c>
      brelse(bp);
    8000425a:	8526                	mv	a0,s1
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	4b6080e7          	jalr	1206(ra) # 80003712 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80004264:	04cba783          	lw	a5,76(s7)
    80004268:	0127f463          	bgeu	a5,s2,80004270 <writei+0xe2>
      ip->size = off;
    8000426c:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80004270:	855e                	mv	a0,s7
    80004272:	00000097          	auipc	ra,0x0
    80004276:	aa8080e7          	jalr	-1368(ra) # 80003d1a <iupdate>
  }

  return n;
    8000427a:	000b051b          	sext.w	a0,s6
}
    8000427e:	70a6                	ld	ra,104(sp)
    80004280:	7406                	ld	s0,96(sp)
    80004282:	64e6                	ld	s1,88(sp)
    80004284:	6946                	ld	s2,80(sp)
    80004286:	69a6                	ld	s3,72(sp)
    80004288:	6a06                	ld	s4,64(sp)
    8000428a:	7ae2                	ld	s5,56(sp)
    8000428c:	7b42                	ld	s6,48(sp)
    8000428e:	7ba2                	ld	s7,40(sp)
    80004290:	7c02                	ld	s8,32(sp)
    80004292:	6ce2                	ld	s9,24(sp)
    80004294:	6d42                	ld	s10,16(sp)
    80004296:	6da2                	ld	s11,8(sp)
    80004298:	6165                	addi	sp,sp,112
    8000429a:	8082                	ret
    return -1;
    8000429c:	557d                	li	a0,-1
}
    8000429e:	8082                	ret
    return -1;
    800042a0:	557d                	li	a0,-1
    800042a2:	bff1                	j	8000427e <writei+0xf0>
    return -1;
    800042a4:	557d                	li	a0,-1
    800042a6:	bfe1                	j	8000427e <writei+0xf0>

00000000800042a8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042a8:	1141                	addi	sp,sp,-16
    800042aa:	e406                	sd	ra,8(sp)
    800042ac:	e022                	sd	s0,0(sp)
    800042ae:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042b0:	4639                	li	a2,14
    800042b2:	ffffd097          	auipc	ra,0xffffd
    800042b6:	b80080e7          	jalr	-1152(ra) # 80000e32 <strncmp>
}
    800042ba:	60a2                	ld	ra,8(sp)
    800042bc:	6402                	ld	s0,0(sp)
    800042be:	0141                	addi	sp,sp,16
    800042c0:	8082                	ret

00000000800042c2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042c2:	7139                	addi	sp,sp,-64
    800042c4:	fc06                	sd	ra,56(sp)
    800042c6:	f822                	sd	s0,48(sp)
    800042c8:	f426                	sd	s1,40(sp)
    800042ca:	f04a                	sd	s2,32(sp)
    800042cc:	ec4e                	sd	s3,24(sp)
    800042ce:	e852                	sd	s4,16(sp)
    800042d0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042d2:	04451703          	lh	a4,68(a0)
    800042d6:	4785                	li	a5,1
    800042d8:	00f71a63          	bne	a4,a5,800042ec <dirlookup+0x2a>
    800042dc:	892a                	mv	s2,a0
    800042de:	89ae                	mv	s3,a1
    800042e0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042e2:	457c                	lw	a5,76(a0)
    800042e4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042e6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042e8:	e79d                	bnez	a5,80004316 <dirlookup+0x54>
    800042ea:	a8a5                	j	80004362 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042ec:	00004517          	auipc	a0,0x4
    800042f0:	57c50513          	addi	a0,a0,1404 # 80008868 <sysnames+0x1b0>
    800042f4:	ffffc097          	auipc	ra,0xffffc
    800042f8:	254080e7          	jalr	596(ra) # 80000548 <panic>
      panic("dirlookup read");
    800042fc:	00004517          	auipc	a0,0x4
    80004300:	58450513          	addi	a0,a0,1412 # 80008880 <sysnames+0x1c8>
    80004304:	ffffc097          	auipc	ra,0xffffc
    80004308:	244080e7          	jalr	580(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000430c:	24c1                	addiw	s1,s1,16
    8000430e:	04c92783          	lw	a5,76(s2)
    80004312:	04f4f763          	bgeu	s1,a5,80004360 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004316:	4741                	li	a4,16
    80004318:	86a6                	mv	a3,s1
    8000431a:	fc040613          	addi	a2,s0,-64
    8000431e:	4581                	li	a1,0
    80004320:	854a                	mv	a0,s2
    80004322:	00000097          	auipc	ra,0x0
    80004326:	d76080e7          	jalr	-650(ra) # 80004098 <readi>
    8000432a:	47c1                	li	a5,16
    8000432c:	fcf518e3          	bne	a0,a5,800042fc <dirlookup+0x3a>
    if(de.inum == 0)
    80004330:	fc045783          	lhu	a5,-64(s0)
    80004334:	dfe1                	beqz	a5,8000430c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004336:	fc240593          	addi	a1,s0,-62
    8000433a:	854e                	mv	a0,s3
    8000433c:	00000097          	auipc	ra,0x0
    80004340:	f6c080e7          	jalr	-148(ra) # 800042a8 <namecmp>
    80004344:	f561                	bnez	a0,8000430c <dirlookup+0x4a>
      if(poff)
    80004346:	000a0463          	beqz	s4,8000434e <dirlookup+0x8c>
        *poff = off;
    8000434a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000434e:	fc045583          	lhu	a1,-64(s0)
    80004352:	00092503          	lw	a0,0(s2)
    80004356:	fffff097          	auipc	ra,0xfffff
    8000435a:	75a080e7          	jalr	1882(ra) # 80003ab0 <iget>
    8000435e:	a011                	j	80004362 <dirlookup+0xa0>
  return 0;
    80004360:	4501                	li	a0,0
}
    80004362:	70e2                	ld	ra,56(sp)
    80004364:	7442                	ld	s0,48(sp)
    80004366:	74a2                	ld	s1,40(sp)
    80004368:	7902                	ld	s2,32(sp)
    8000436a:	69e2                	ld	s3,24(sp)
    8000436c:	6a42                	ld	s4,16(sp)
    8000436e:	6121                	addi	sp,sp,64
    80004370:	8082                	ret

0000000080004372 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004372:	711d                	addi	sp,sp,-96
    80004374:	ec86                	sd	ra,88(sp)
    80004376:	e8a2                	sd	s0,80(sp)
    80004378:	e4a6                	sd	s1,72(sp)
    8000437a:	e0ca                	sd	s2,64(sp)
    8000437c:	fc4e                	sd	s3,56(sp)
    8000437e:	f852                	sd	s4,48(sp)
    80004380:	f456                	sd	s5,40(sp)
    80004382:	f05a                	sd	s6,32(sp)
    80004384:	ec5e                	sd	s7,24(sp)
    80004386:	e862                	sd	s8,16(sp)
    80004388:	e466                	sd	s9,8(sp)
    8000438a:	1080                	addi	s0,sp,96
    8000438c:	84aa                	mv	s1,a0
    8000438e:	8b2e                	mv	s6,a1
    80004390:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004392:	00054703          	lbu	a4,0(a0)
    80004396:	02f00793          	li	a5,47
    8000439a:	02f70363          	beq	a4,a5,800043c0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000439e:	ffffe097          	auipc	ra,0xffffe
    800043a2:	b5e080e7          	jalr	-1186(ra) # 80001efc <myproc>
    800043a6:	15053503          	ld	a0,336(a0)
    800043aa:	00000097          	auipc	ra,0x0
    800043ae:	9fc080e7          	jalr	-1540(ra) # 80003da6 <idup>
    800043b2:	89aa                	mv	s3,a0
  while(*path == '/')
    800043b4:	02f00913          	li	s2,47
  len = path - s;
    800043b8:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800043ba:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043bc:	4c05                	li	s8,1
    800043be:	a865                	j	80004476 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800043c0:	4585                	li	a1,1
    800043c2:	4505                	li	a0,1
    800043c4:	fffff097          	auipc	ra,0xfffff
    800043c8:	6ec080e7          	jalr	1772(ra) # 80003ab0 <iget>
    800043cc:	89aa                	mv	s3,a0
    800043ce:	b7dd                	j	800043b4 <namex+0x42>
      iunlockput(ip);
    800043d0:	854e                	mv	a0,s3
    800043d2:	00000097          	auipc	ra,0x0
    800043d6:	c74080e7          	jalr	-908(ra) # 80004046 <iunlockput>
      return 0;
    800043da:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043dc:	854e                	mv	a0,s3
    800043de:	60e6                	ld	ra,88(sp)
    800043e0:	6446                	ld	s0,80(sp)
    800043e2:	64a6                	ld	s1,72(sp)
    800043e4:	6906                	ld	s2,64(sp)
    800043e6:	79e2                	ld	s3,56(sp)
    800043e8:	7a42                	ld	s4,48(sp)
    800043ea:	7aa2                	ld	s5,40(sp)
    800043ec:	7b02                	ld	s6,32(sp)
    800043ee:	6be2                	ld	s7,24(sp)
    800043f0:	6c42                	ld	s8,16(sp)
    800043f2:	6ca2                	ld	s9,8(sp)
    800043f4:	6125                	addi	sp,sp,96
    800043f6:	8082                	ret
      iunlock(ip);
    800043f8:	854e                	mv	a0,s3
    800043fa:	00000097          	auipc	ra,0x0
    800043fe:	aac080e7          	jalr	-1364(ra) # 80003ea6 <iunlock>
      return ip;
    80004402:	bfe9                	j	800043dc <namex+0x6a>
      iunlockput(ip);
    80004404:	854e                	mv	a0,s3
    80004406:	00000097          	auipc	ra,0x0
    8000440a:	c40080e7          	jalr	-960(ra) # 80004046 <iunlockput>
      return 0;
    8000440e:	89d2                	mv	s3,s4
    80004410:	b7f1                	j	800043dc <namex+0x6a>
  len = path - s;
    80004412:	40b48633          	sub	a2,s1,a1
    80004416:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000441a:	094cd463          	bge	s9,s4,800044a2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000441e:	4639                	li	a2,14
    80004420:	8556                	mv	a0,s5
    80004422:	ffffd097          	auipc	ra,0xffffd
    80004426:	994080e7          	jalr	-1644(ra) # 80000db6 <memmove>
  while(*path == '/')
    8000442a:	0004c783          	lbu	a5,0(s1)
    8000442e:	01279763          	bne	a5,s2,8000443c <namex+0xca>
    path++;
    80004432:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004434:	0004c783          	lbu	a5,0(s1)
    80004438:	ff278de3          	beq	a5,s2,80004432 <namex+0xc0>
    ilock(ip);
    8000443c:	854e                	mv	a0,s3
    8000443e:	00000097          	auipc	ra,0x0
    80004442:	9a6080e7          	jalr	-1626(ra) # 80003de4 <ilock>
    if(ip->type != T_DIR){
    80004446:	04499783          	lh	a5,68(s3)
    8000444a:	f98793e3          	bne	a5,s8,800043d0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000444e:	000b0563          	beqz	s6,80004458 <namex+0xe6>
    80004452:	0004c783          	lbu	a5,0(s1)
    80004456:	d3cd                	beqz	a5,800043f8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004458:	865e                	mv	a2,s7
    8000445a:	85d6                	mv	a1,s5
    8000445c:	854e                	mv	a0,s3
    8000445e:	00000097          	auipc	ra,0x0
    80004462:	e64080e7          	jalr	-412(ra) # 800042c2 <dirlookup>
    80004466:	8a2a                	mv	s4,a0
    80004468:	dd51                	beqz	a0,80004404 <namex+0x92>
    iunlockput(ip);
    8000446a:	854e                	mv	a0,s3
    8000446c:	00000097          	auipc	ra,0x0
    80004470:	bda080e7          	jalr	-1062(ra) # 80004046 <iunlockput>
    ip = next;
    80004474:	89d2                	mv	s3,s4
  while(*path == '/')
    80004476:	0004c783          	lbu	a5,0(s1)
    8000447a:	05279763          	bne	a5,s2,800044c8 <namex+0x156>
    path++;
    8000447e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004480:	0004c783          	lbu	a5,0(s1)
    80004484:	ff278de3          	beq	a5,s2,8000447e <namex+0x10c>
  if(*path == 0)
    80004488:	c79d                	beqz	a5,800044b6 <namex+0x144>
    path++;
    8000448a:	85a6                	mv	a1,s1
  len = path - s;
    8000448c:	8a5e                	mv	s4,s7
    8000448e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004490:	01278963          	beq	a5,s2,800044a2 <namex+0x130>
    80004494:	dfbd                	beqz	a5,80004412 <namex+0xa0>
    path++;
    80004496:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004498:	0004c783          	lbu	a5,0(s1)
    8000449c:	ff279ce3          	bne	a5,s2,80004494 <namex+0x122>
    800044a0:	bf8d                	j	80004412 <namex+0xa0>
    memmove(name, s, len);
    800044a2:	2601                	sext.w	a2,a2
    800044a4:	8556                	mv	a0,s5
    800044a6:	ffffd097          	auipc	ra,0xffffd
    800044aa:	910080e7          	jalr	-1776(ra) # 80000db6 <memmove>
    name[len] = 0;
    800044ae:	9a56                	add	s4,s4,s5
    800044b0:	000a0023          	sb	zero,0(s4)
    800044b4:	bf9d                	j	8000442a <namex+0xb8>
  if(nameiparent){
    800044b6:	f20b03e3          	beqz	s6,800043dc <namex+0x6a>
    iput(ip);
    800044ba:	854e                	mv	a0,s3
    800044bc:	00000097          	auipc	ra,0x0
    800044c0:	ae2080e7          	jalr	-1310(ra) # 80003f9e <iput>
    return 0;
    800044c4:	4981                	li	s3,0
    800044c6:	bf19                	j	800043dc <namex+0x6a>
  if(*path == 0)
    800044c8:	d7fd                	beqz	a5,800044b6 <namex+0x144>
  while(*path != '/' && *path != 0)
    800044ca:	0004c783          	lbu	a5,0(s1)
    800044ce:	85a6                	mv	a1,s1
    800044d0:	b7d1                	j	80004494 <namex+0x122>

00000000800044d2 <dirlink>:
{
    800044d2:	7139                	addi	sp,sp,-64
    800044d4:	fc06                	sd	ra,56(sp)
    800044d6:	f822                	sd	s0,48(sp)
    800044d8:	f426                	sd	s1,40(sp)
    800044da:	f04a                	sd	s2,32(sp)
    800044dc:	ec4e                	sd	s3,24(sp)
    800044de:	e852                	sd	s4,16(sp)
    800044e0:	0080                	addi	s0,sp,64
    800044e2:	892a                	mv	s2,a0
    800044e4:	8a2e                	mv	s4,a1
    800044e6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044e8:	4601                	li	a2,0
    800044ea:	00000097          	auipc	ra,0x0
    800044ee:	dd8080e7          	jalr	-552(ra) # 800042c2 <dirlookup>
    800044f2:	e93d                	bnez	a0,80004568 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044f4:	04c92483          	lw	s1,76(s2)
    800044f8:	c49d                	beqz	s1,80004526 <dirlink+0x54>
    800044fa:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044fc:	4741                	li	a4,16
    800044fe:	86a6                	mv	a3,s1
    80004500:	fc040613          	addi	a2,s0,-64
    80004504:	4581                	li	a1,0
    80004506:	854a                	mv	a0,s2
    80004508:	00000097          	auipc	ra,0x0
    8000450c:	b90080e7          	jalr	-1136(ra) # 80004098 <readi>
    80004510:	47c1                	li	a5,16
    80004512:	06f51163          	bne	a0,a5,80004574 <dirlink+0xa2>
    if(de.inum == 0)
    80004516:	fc045783          	lhu	a5,-64(s0)
    8000451a:	c791                	beqz	a5,80004526 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000451c:	24c1                	addiw	s1,s1,16
    8000451e:	04c92783          	lw	a5,76(s2)
    80004522:	fcf4ede3          	bltu	s1,a5,800044fc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004526:	4639                	li	a2,14
    80004528:	85d2                	mv	a1,s4
    8000452a:	fc240513          	addi	a0,s0,-62
    8000452e:	ffffd097          	auipc	ra,0xffffd
    80004532:	940080e7          	jalr	-1728(ra) # 80000e6e <strncpy>
  de.inum = inum;
    80004536:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000453a:	4741                	li	a4,16
    8000453c:	86a6                	mv	a3,s1
    8000453e:	fc040613          	addi	a2,s0,-64
    80004542:	4581                	li	a1,0
    80004544:	854a                	mv	a0,s2
    80004546:	00000097          	auipc	ra,0x0
    8000454a:	c48080e7          	jalr	-952(ra) # 8000418e <writei>
    8000454e:	872a                	mv	a4,a0
    80004550:	47c1                	li	a5,16
  return 0;
    80004552:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004554:	02f71863          	bne	a4,a5,80004584 <dirlink+0xb2>
}
    80004558:	70e2                	ld	ra,56(sp)
    8000455a:	7442                	ld	s0,48(sp)
    8000455c:	74a2                	ld	s1,40(sp)
    8000455e:	7902                	ld	s2,32(sp)
    80004560:	69e2                	ld	s3,24(sp)
    80004562:	6a42                	ld	s4,16(sp)
    80004564:	6121                	addi	sp,sp,64
    80004566:	8082                	ret
    iput(ip);
    80004568:	00000097          	auipc	ra,0x0
    8000456c:	a36080e7          	jalr	-1482(ra) # 80003f9e <iput>
    return -1;
    80004570:	557d                	li	a0,-1
    80004572:	b7dd                	j	80004558 <dirlink+0x86>
      panic("dirlink read");
    80004574:	00004517          	auipc	a0,0x4
    80004578:	31c50513          	addi	a0,a0,796 # 80008890 <sysnames+0x1d8>
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	fcc080e7          	jalr	-52(ra) # 80000548 <panic>
    panic("dirlink");
    80004584:	00004517          	auipc	a0,0x4
    80004588:	41c50513          	addi	a0,a0,1052 # 800089a0 <sysnames+0x2e8>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	fbc080e7          	jalr	-68(ra) # 80000548 <panic>

0000000080004594 <namei>:

struct inode*
namei(char *path)
{
    80004594:	1101                	addi	sp,sp,-32
    80004596:	ec06                	sd	ra,24(sp)
    80004598:	e822                	sd	s0,16(sp)
    8000459a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000459c:	fe040613          	addi	a2,s0,-32
    800045a0:	4581                	li	a1,0
    800045a2:	00000097          	auipc	ra,0x0
    800045a6:	dd0080e7          	jalr	-560(ra) # 80004372 <namex>
}
    800045aa:	60e2                	ld	ra,24(sp)
    800045ac:	6442                	ld	s0,16(sp)
    800045ae:	6105                	addi	sp,sp,32
    800045b0:	8082                	ret

00000000800045b2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045b2:	1141                	addi	sp,sp,-16
    800045b4:	e406                	sd	ra,8(sp)
    800045b6:	e022                	sd	s0,0(sp)
    800045b8:	0800                	addi	s0,sp,16
    800045ba:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045bc:	4585                	li	a1,1
    800045be:	00000097          	auipc	ra,0x0
    800045c2:	db4080e7          	jalr	-588(ra) # 80004372 <namex>
}
    800045c6:	60a2                	ld	ra,8(sp)
    800045c8:	6402                	ld	s0,0(sp)
    800045ca:	0141                	addi	sp,sp,16
    800045cc:	8082                	ret

00000000800045ce <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045ce:	1101                	addi	sp,sp,-32
    800045d0:	ec06                	sd	ra,24(sp)
    800045d2:	e822                	sd	s0,16(sp)
    800045d4:	e426                	sd	s1,8(sp)
    800045d6:	e04a                	sd	s2,0(sp)
    800045d8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045da:	0001d917          	auipc	s2,0x1d
    800045de:	72e90913          	addi	s2,s2,1838 # 80021d08 <log>
    800045e2:	01892583          	lw	a1,24(s2)
    800045e6:	02892503          	lw	a0,40(s2)
    800045ea:	fffff097          	auipc	ra,0xfffff
    800045ee:	ff8080e7          	jalr	-8(ra) # 800035e2 <bread>
    800045f2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045f4:	02c92683          	lw	a3,44(s2)
    800045f8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800045fa:	02d05763          	blez	a3,80004628 <write_head+0x5a>
    800045fe:	0001d797          	auipc	a5,0x1d
    80004602:	73a78793          	addi	a5,a5,1850 # 80021d38 <log+0x30>
    80004606:	05c50713          	addi	a4,a0,92
    8000460a:	36fd                	addiw	a3,a3,-1
    8000460c:	1682                	slli	a3,a3,0x20
    8000460e:	9281                	srli	a3,a3,0x20
    80004610:	068a                	slli	a3,a3,0x2
    80004612:	0001d617          	auipc	a2,0x1d
    80004616:	72a60613          	addi	a2,a2,1834 # 80021d3c <log+0x34>
    8000461a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000461c:	4390                	lw	a2,0(a5)
    8000461e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004620:	0791                	addi	a5,a5,4
    80004622:	0711                	addi	a4,a4,4
    80004624:	fed79ce3          	bne	a5,a3,8000461c <write_head+0x4e>
  }
  bwrite(buf);
    80004628:	8526                	mv	a0,s1
    8000462a:	fffff097          	auipc	ra,0xfffff
    8000462e:	0aa080e7          	jalr	170(ra) # 800036d4 <bwrite>
  brelse(buf);
    80004632:	8526                	mv	a0,s1
    80004634:	fffff097          	auipc	ra,0xfffff
    80004638:	0de080e7          	jalr	222(ra) # 80003712 <brelse>
}
    8000463c:	60e2                	ld	ra,24(sp)
    8000463e:	6442                	ld	s0,16(sp)
    80004640:	64a2                	ld	s1,8(sp)
    80004642:	6902                	ld	s2,0(sp)
    80004644:	6105                	addi	sp,sp,32
    80004646:	8082                	ret

0000000080004648 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004648:	0001d797          	auipc	a5,0x1d
    8000464c:	6ec7a783          	lw	a5,1772(a5) # 80021d34 <log+0x2c>
    80004650:	0af05663          	blez	a5,800046fc <install_trans+0xb4>
{
    80004654:	7139                	addi	sp,sp,-64
    80004656:	fc06                	sd	ra,56(sp)
    80004658:	f822                	sd	s0,48(sp)
    8000465a:	f426                	sd	s1,40(sp)
    8000465c:	f04a                	sd	s2,32(sp)
    8000465e:	ec4e                	sd	s3,24(sp)
    80004660:	e852                	sd	s4,16(sp)
    80004662:	e456                	sd	s5,8(sp)
    80004664:	0080                	addi	s0,sp,64
    80004666:	0001da97          	auipc	s5,0x1d
    8000466a:	6d2a8a93          	addi	s5,s5,1746 # 80021d38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000466e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004670:	0001d997          	auipc	s3,0x1d
    80004674:	69898993          	addi	s3,s3,1688 # 80021d08 <log>
    80004678:	0189a583          	lw	a1,24(s3)
    8000467c:	014585bb          	addw	a1,a1,s4
    80004680:	2585                	addiw	a1,a1,1
    80004682:	0289a503          	lw	a0,40(s3)
    80004686:	fffff097          	auipc	ra,0xfffff
    8000468a:	f5c080e7          	jalr	-164(ra) # 800035e2 <bread>
    8000468e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004690:	000aa583          	lw	a1,0(s5)
    80004694:	0289a503          	lw	a0,40(s3)
    80004698:	fffff097          	auipc	ra,0xfffff
    8000469c:	f4a080e7          	jalr	-182(ra) # 800035e2 <bread>
    800046a0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046a2:	40000613          	li	a2,1024
    800046a6:	05890593          	addi	a1,s2,88
    800046aa:	05850513          	addi	a0,a0,88
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	708080e7          	jalr	1800(ra) # 80000db6 <memmove>
    bwrite(dbuf);  // write dst to disk
    800046b6:	8526                	mv	a0,s1
    800046b8:	fffff097          	auipc	ra,0xfffff
    800046bc:	01c080e7          	jalr	28(ra) # 800036d4 <bwrite>
    bunpin(dbuf);
    800046c0:	8526                	mv	a0,s1
    800046c2:	fffff097          	auipc	ra,0xfffff
    800046c6:	12a080e7          	jalr	298(ra) # 800037ec <bunpin>
    brelse(lbuf);
    800046ca:	854a                	mv	a0,s2
    800046cc:	fffff097          	auipc	ra,0xfffff
    800046d0:	046080e7          	jalr	70(ra) # 80003712 <brelse>
    brelse(dbuf);
    800046d4:	8526                	mv	a0,s1
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	03c080e7          	jalr	60(ra) # 80003712 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046de:	2a05                	addiw	s4,s4,1
    800046e0:	0a91                	addi	s5,s5,4
    800046e2:	02c9a783          	lw	a5,44(s3)
    800046e6:	f8fa49e3          	blt	s4,a5,80004678 <install_trans+0x30>
}
    800046ea:	70e2                	ld	ra,56(sp)
    800046ec:	7442                	ld	s0,48(sp)
    800046ee:	74a2                	ld	s1,40(sp)
    800046f0:	7902                	ld	s2,32(sp)
    800046f2:	69e2                	ld	s3,24(sp)
    800046f4:	6a42                	ld	s4,16(sp)
    800046f6:	6aa2                	ld	s5,8(sp)
    800046f8:	6121                	addi	sp,sp,64
    800046fa:	8082                	ret
    800046fc:	8082                	ret

00000000800046fe <initlog>:
{
    800046fe:	7179                	addi	sp,sp,-48
    80004700:	f406                	sd	ra,40(sp)
    80004702:	f022                	sd	s0,32(sp)
    80004704:	ec26                	sd	s1,24(sp)
    80004706:	e84a                	sd	s2,16(sp)
    80004708:	e44e                	sd	s3,8(sp)
    8000470a:	1800                	addi	s0,sp,48
    8000470c:	892a                	mv	s2,a0
    8000470e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004710:	0001d497          	auipc	s1,0x1d
    80004714:	5f848493          	addi	s1,s1,1528 # 80021d08 <log>
    80004718:	00004597          	auipc	a1,0x4
    8000471c:	18858593          	addi	a1,a1,392 # 800088a0 <sysnames+0x1e8>
    80004720:	8526                	mv	a0,s1
    80004722:	ffffc097          	auipc	ra,0xffffc
    80004726:	4a8080e7          	jalr	1192(ra) # 80000bca <initlock>
  log.start = sb->logstart;
    8000472a:	0149a583          	lw	a1,20(s3)
    8000472e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004730:	0109a783          	lw	a5,16(s3)
    80004734:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004736:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000473a:	854a                	mv	a0,s2
    8000473c:	fffff097          	auipc	ra,0xfffff
    80004740:	ea6080e7          	jalr	-346(ra) # 800035e2 <bread>
  log.lh.n = lh->n;
    80004744:	4d3c                	lw	a5,88(a0)
    80004746:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004748:	02f05563          	blez	a5,80004772 <initlog+0x74>
    8000474c:	05c50713          	addi	a4,a0,92
    80004750:	0001d697          	auipc	a3,0x1d
    80004754:	5e868693          	addi	a3,a3,1512 # 80021d38 <log+0x30>
    80004758:	37fd                	addiw	a5,a5,-1
    8000475a:	1782                	slli	a5,a5,0x20
    8000475c:	9381                	srli	a5,a5,0x20
    8000475e:	078a                	slli	a5,a5,0x2
    80004760:	06050613          	addi	a2,a0,96
    80004764:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004766:	4310                	lw	a2,0(a4)
    80004768:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000476a:	0711                	addi	a4,a4,4
    8000476c:	0691                	addi	a3,a3,4
    8000476e:	fef71ce3          	bne	a4,a5,80004766 <initlog+0x68>
  brelse(buf);
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	fa0080e7          	jalr	-96(ra) # 80003712 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000477a:	00000097          	auipc	ra,0x0
    8000477e:	ece080e7          	jalr	-306(ra) # 80004648 <install_trans>
  log.lh.n = 0;
    80004782:	0001d797          	auipc	a5,0x1d
    80004786:	5a07a923          	sw	zero,1458(a5) # 80021d34 <log+0x2c>
  write_head(); // clear the log
    8000478a:	00000097          	auipc	ra,0x0
    8000478e:	e44080e7          	jalr	-444(ra) # 800045ce <write_head>
}
    80004792:	70a2                	ld	ra,40(sp)
    80004794:	7402                	ld	s0,32(sp)
    80004796:	64e2                	ld	s1,24(sp)
    80004798:	6942                	ld	s2,16(sp)
    8000479a:	69a2                	ld	s3,8(sp)
    8000479c:	6145                	addi	sp,sp,48
    8000479e:	8082                	ret

00000000800047a0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047a0:	1101                	addi	sp,sp,-32
    800047a2:	ec06                	sd	ra,24(sp)
    800047a4:	e822                	sd	s0,16(sp)
    800047a6:	e426                	sd	s1,8(sp)
    800047a8:	e04a                	sd	s2,0(sp)
    800047aa:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047ac:	0001d517          	auipc	a0,0x1d
    800047b0:	55c50513          	addi	a0,a0,1372 # 80021d08 <log>
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	4a6080e7          	jalr	1190(ra) # 80000c5a <acquire>
  while(1){
    if(log.committing){
    800047bc:	0001d497          	auipc	s1,0x1d
    800047c0:	54c48493          	addi	s1,s1,1356 # 80021d08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047c4:	4979                	li	s2,30
    800047c6:	a039                	j	800047d4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800047c8:	85a6                	mv	a1,s1
    800047ca:	8526                	mv	a0,s1
    800047cc:	ffffe097          	auipc	ra,0xffffe
    800047d0:	0c8080e7          	jalr	200(ra) # 80002894 <sleep>
    if(log.committing){
    800047d4:	50dc                	lw	a5,36(s1)
    800047d6:	fbed                	bnez	a5,800047c8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047d8:	509c                	lw	a5,32(s1)
    800047da:	0017871b          	addiw	a4,a5,1
    800047de:	0007069b          	sext.w	a3,a4
    800047e2:	0027179b          	slliw	a5,a4,0x2
    800047e6:	9fb9                	addw	a5,a5,a4
    800047e8:	0017979b          	slliw	a5,a5,0x1
    800047ec:	54d8                	lw	a4,44(s1)
    800047ee:	9fb9                	addw	a5,a5,a4
    800047f0:	00f95963          	bge	s2,a5,80004802 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800047f4:	85a6                	mv	a1,s1
    800047f6:	8526                	mv	a0,s1
    800047f8:	ffffe097          	auipc	ra,0xffffe
    800047fc:	09c080e7          	jalr	156(ra) # 80002894 <sleep>
    80004800:	bfd1                	j	800047d4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004802:	0001d517          	auipc	a0,0x1d
    80004806:	50650513          	addi	a0,a0,1286 # 80021d08 <log>
    8000480a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	502080e7          	jalr	1282(ra) # 80000d0e <release>
      break;
    }
  }
}
    80004814:	60e2                	ld	ra,24(sp)
    80004816:	6442                	ld	s0,16(sp)
    80004818:	64a2                	ld	s1,8(sp)
    8000481a:	6902                	ld	s2,0(sp)
    8000481c:	6105                	addi	sp,sp,32
    8000481e:	8082                	ret

0000000080004820 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004820:	7139                	addi	sp,sp,-64
    80004822:	fc06                	sd	ra,56(sp)
    80004824:	f822                	sd	s0,48(sp)
    80004826:	f426                	sd	s1,40(sp)
    80004828:	f04a                	sd	s2,32(sp)
    8000482a:	ec4e                	sd	s3,24(sp)
    8000482c:	e852                	sd	s4,16(sp)
    8000482e:	e456                	sd	s5,8(sp)
    80004830:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004832:	0001d497          	auipc	s1,0x1d
    80004836:	4d648493          	addi	s1,s1,1238 # 80021d08 <log>
    8000483a:	8526                	mv	a0,s1
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	41e080e7          	jalr	1054(ra) # 80000c5a <acquire>
  log.outstanding -= 1;
    80004844:	509c                	lw	a5,32(s1)
    80004846:	37fd                	addiw	a5,a5,-1
    80004848:	0007891b          	sext.w	s2,a5
    8000484c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000484e:	50dc                	lw	a5,36(s1)
    80004850:	efb9                	bnez	a5,800048ae <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004852:	06091663          	bnez	s2,800048be <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004856:	0001d497          	auipc	s1,0x1d
    8000485a:	4b248493          	addi	s1,s1,1202 # 80021d08 <log>
    8000485e:	4785                	li	a5,1
    80004860:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004862:	8526                	mv	a0,s1
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	4aa080e7          	jalr	1194(ra) # 80000d0e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000486c:	54dc                	lw	a5,44(s1)
    8000486e:	06f04763          	bgtz	a5,800048dc <end_op+0xbc>
    acquire(&log.lock);
    80004872:	0001d497          	auipc	s1,0x1d
    80004876:	49648493          	addi	s1,s1,1174 # 80021d08 <log>
    8000487a:	8526                	mv	a0,s1
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	3de080e7          	jalr	990(ra) # 80000c5a <acquire>
    log.committing = 0;
    80004884:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004888:	8526                	mv	a0,s1
    8000488a:	ffffe097          	auipc	ra,0xffffe
    8000488e:	190080e7          	jalr	400(ra) # 80002a1a <wakeup>
    release(&log.lock);
    80004892:	8526                	mv	a0,s1
    80004894:	ffffc097          	auipc	ra,0xffffc
    80004898:	47a080e7          	jalr	1146(ra) # 80000d0e <release>
}
    8000489c:	70e2                	ld	ra,56(sp)
    8000489e:	7442                	ld	s0,48(sp)
    800048a0:	74a2                	ld	s1,40(sp)
    800048a2:	7902                	ld	s2,32(sp)
    800048a4:	69e2                	ld	s3,24(sp)
    800048a6:	6a42                	ld	s4,16(sp)
    800048a8:	6aa2                	ld	s5,8(sp)
    800048aa:	6121                	addi	sp,sp,64
    800048ac:	8082                	ret
    panic("log.committing");
    800048ae:	00004517          	auipc	a0,0x4
    800048b2:	ffa50513          	addi	a0,a0,-6 # 800088a8 <sysnames+0x1f0>
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	c92080e7          	jalr	-878(ra) # 80000548 <panic>
    wakeup(&log);
    800048be:	0001d497          	auipc	s1,0x1d
    800048c2:	44a48493          	addi	s1,s1,1098 # 80021d08 <log>
    800048c6:	8526                	mv	a0,s1
    800048c8:	ffffe097          	auipc	ra,0xffffe
    800048cc:	152080e7          	jalr	338(ra) # 80002a1a <wakeup>
  release(&log.lock);
    800048d0:	8526                	mv	a0,s1
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	43c080e7          	jalr	1084(ra) # 80000d0e <release>
  if(do_commit){
    800048da:	b7c9                	j	8000489c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048dc:	0001da97          	auipc	s5,0x1d
    800048e0:	45ca8a93          	addi	s5,s5,1116 # 80021d38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048e4:	0001da17          	auipc	s4,0x1d
    800048e8:	424a0a13          	addi	s4,s4,1060 # 80021d08 <log>
    800048ec:	018a2583          	lw	a1,24(s4)
    800048f0:	012585bb          	addw	a1,a1,s2
    800048f4:	2585                	addiw	a1,a1,1
    800048f6:	028a2503          	lw	a0,40(s4)
    800048fa:	fffff097          	auipc	ra,0xfffff
    800048fe:	ce8080e7          	jalr	-792(ra) # 800035e2 <bread>
    80004902:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004904:	000aa583          	lw	a1,0(s5)
    80004908:	028a2503          	lw	a0,40(s4)
    8000490c:	fffff097          	auipc	ra,0xfffff
    80004910:	cd6080e7          	jalr	-810(ra) # 800035e2 <bread>
    80004914:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004916:	40000613          	li	a2,1024
    8000491a:	05850593          	addi	a1,a0,88
    8000491e:	05848513          	addi	a0,s1,88
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	494080e7          	jalr	1172(ra) # 80000db6 <memmove>
    bwrite(to);  // write the log
    8000492a:	8526                	mv	a0,s1
    8000492c:	fffff097          	auipc	ra,0xfffff
    80004930:	da8080e7          	jalr	-600(ra) # 800036d4 <bwrite>
    brelse(from);
    80004934:	854e                	mv	a0,s3
    80004936:	fffff097          	auipc	ra,0xfffff
    8000493a:	ddc080e7          	jalr	-548(ra) # 80003712 <brelse>
    brelse(to);
    8000493e:	8526                	mv	a0,s1
    80004940:	fffff097          	auipc	ra,0xfffff
    80004944:	dd2080e7          	jalr	-558(ra) # 80003712 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004948:	2905                	addiw	s2,s2,1
    8000494a:	0a91                	addi	s5,s5,4
    8000494c:	02ca2783          	lw	a5,44(s4)
    80004950:	f8f94ee3          	blt	s2,a5,800048ec <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004954:	00000097          	auipc	ra,0x0
    80004958:	c7a080e7          	jalr	-902(ra) # 800045ce <write_head>
    install_trans(); // Now install writes to home locations
    8000495c:	00000097          	auipc	ra,0x0
    80004960:	cec080e7          	jalr	-788(ra) # 80004648 <install_trans>
    log.lh.n = 0;
    80004964:	0001d797          	auipc	a5,0x1d
    80004968:	3c07a823          	sw	zero,976(a5) # 80021d34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000496c:	00000097          	auipc	ra,0x0
    80004970:	c62080e7          	jalr	-926(ra) # 800045ce <write_head>
    80004974:	bdfd                	j	80004872 <end_op+0x52>

0000000080004976 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004976:	1101                	addi	sp,sp,-32
    80004978:	ec06                	sd	ra,24(sp)
    8000497a:	e822                	sd	s0,16(sp)
    8000497c:	e426                	sd	s1,8(sp)
    8000497e:	e04a                	sd	s2,0(sp)
    80004980:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004982:	0001d717          	auipc	a4,0x1d
    80004986:	3b272703          	lw	a4,946(a4) # 80021d34 <log+0x2c>
    8000498a:	47f5                	li	a5,29
    8000498c:	08e7c063          	blt	a5,a4,80004a0c <log_write+0x96>
    80004990:	84aa                	mv	s1,a0
    80004992:	0001d797          	auipc	a5,0x1d
    80004996:	3927a783          	lw	a5,914(a5) # 80021d24 <log+0x1c>
    8000499a:	37fd                	addiw	a5,a5,-1
    8000499c:	06f75863          	bge	a4,a5,80004a0c <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049a0:	0001d797          	auipc	a5,0x1d
    800049a4:	3887a783          	lw	a5,904(a5) # 80021d28 <log+0x20>
    800049a8:	06f05a63          	blez	a5,80004a1c <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800049ac:	0001d917          	auipc	s2,0x1d
    800049b0:	35c90913          	addi	s2,s2,860 # 80021d08 <log>
    800049b4:	854a                	mv	a0,s2
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	2a4080e7          	jalr	676(ra) # 80000c5a <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800049be:	02c92603          	lw	a2,44(s2)
    800049c2:	06c05563          	blez	a2,80004a2c <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800049c6:	44cc                	lw	a1,12(s1)
    800049c8:	0001d717          	auipc	a4,0x1d
    800049cc:	37070713          	addi	a4,a4,880 # 80021d38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049d0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800049d2:	4314                	lw	a3,0(a4)
    800049d4:	04b68d63          	beq	a3,a1,80004a2e <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800049d8:	2785                	addiw	a5,a5,1
    800049da:	0711                	addi	a4,a4,4
    800049dc:	fec79be3          	bne	a5,a2,800049d2 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049e0:	0621                	addi	a2,a2,8
    800049e2:	060a                	slli	a2,a2,0x2
    800049e4:	0001d797          	auipc	a5,0x1d
    800049e8:	32478793          	addi	a5,a5,804 # 80021d08 <log>
    800049ec:	963e                	add	a2,a2,a5
    800049ee:	44dc                	lw	a5,12(s1)
    800049f0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800049f2:	8526                	mv	a0,s1
    800049f4:	fffff097          	auipc	ra,0xfffff
    800049f8:	dbc080e7          	jalr	-580(ra) # 800037b0 <bpin>
    log.lh.n++;
    800049fc:	0001d717          	auipc	a4,0x1d
    80004a00:	30c70713          	addi	a4,a4,780 # 80021d08 <log>
    80004a04:	575c                	lw	a5,44(a4)
    80004a06:	2785                	addiw	a5,a5,1
    80004a08:	d75c                	sw	a5,44(a4)
    80004a0a:	a83d                	j	80004a48 <log_write+0xd2>
    panic("too big a transaction");
    80004a0c:	00004517          	auipc	a0,0x4
    80004a10:	eac50513          	addi	a0,a0,-340 # 800088b8 <sysnames+0x200>
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	b34080e7          	jalr	-1228(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004a1c:	00004517          	auipc	a0,0x4
    80004a20:	eb450513          	addi	a0,a0,-332 # 800088d0 <sysnames+0x218>
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	b24080e7          	jalr	-1244(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004a2c:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004a2e:	00878713          	addi	a4,a5,8
    80004a32:	00271693          	slli	a3,a4,0x2
    80004a36:	0001d717          	auipc	a4,0x1d
    80004a3a:	2d270713          	addi	a4,a4,722 # 80021d08 <log>
    80004a3e:	9736                	add	a4,a4,a3
    80004a40:	44d4                	lw	a3,12(s1)
    80004a42:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a44:	faf607e3          	beq	a2,a5,800049f2 <log_write+0x7c>
  }
  release(&log.lock);
    80004a48:	0001d517          	auipc	a0,0x1d
    80004a4c:	2c050513          	addi	a0,a0,704 # 80021d08 <log>
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	2be080e7          	jalr	702(ra) # 80000d0e <release>
}
    80004a58:	60e2                	ld	ra,24(sp)
    80004a5a:	6442                	ld	s0,16(sp)
    80004a5c:	64a2                	ld	s1,8(sp)
    80004a5e:	6902                	ld	s2,0(sp)
    80004a60:	6105                	addi	sp,sp,32
    80004a62:	8082                	ret

0000000080004a64 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a64:	1101                	addi	sp,sp,-32
    80004a66:	ec06                	sd	ra,24(sp)
    80004a68:	e822                	sd	s0,16(sp)
    80004a6a:	e426                	sd	s1,8(sp)
    80004a6c:	e04a                	sd	s2,0(sp)
    80004a6e:	1000                	addi	s0,sp,32
    80004a70:	84aa                	mv	s1,a0
    80004a72:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a74:	00004597          	auipc	a1,0x4
    80004a78:	e7c58593          	addi	a1,a1,-388 # 800088f0 <sysnames+0x238>
    80004a7c:	0521                	addi	a0,a0,8
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	14c080e7          	jalr	332(ra) # 80000bca <initlock>
  lk->name = name;
    80004a86:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a8a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a8e:	0204a423          	sw	zero,40(s1)
}
    80004a92:	60e2                	ld	ra,24(sp)
    80004a94:	6442                	ld	s0,16(sp)
    80004a96:	64a2                	ld	s1,8(sp)
    80004a98:	6902                	ld	s2,0(sp)
    80004a9a:	6105                	addi	sp,sp,32
    80004a9c:	8082                	ret

0000000080004a9e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a9e:	1101                	addi	sp,sp,-32
    80004aa0:	ec06                	sd	ra,24(sp)
    80004aa2:	e822                	sd	s0,16(sp)
    80004aa4:	e426                	sd	s1,8(sp)
    80004aa6:	e04a                	sd	s2,0(sp)
    80004aa8:	1000                	addi	s0,sp,32
    80004aaa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004aac:	00850913          	addi	s2,a0,8
    80004ab0:	854a                	mv	a0,s2
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	1a8080e7          	jalr	424(ra) # 80000c5a <acquire>
  while (lk->locked) {
    80004aba:	409c                	lw	a5,0(s1)
    80004abc:	cb89                	beqz	a5,80004ace <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004abe:	85ca                	mv	a1,s2
    80004ac0:	8526                	mv	a0,s1
    80004ac2:	ffffe097          	auipc	ra,0xffffe
    80004ac6:	dd2080e7          	jalr	-558(ra) # 80002894 <sleep>
  while (lk->locked) {
    80004aca:	409c                	lw	a5,0(s1)
    80004acc:	fbed                	bnez	a5,80004abe <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004ace:	4785                	li	a5,1
    80004ad0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ad2:	ffffd097          	auipc	ra,0xffffd
    80004ad6:	42a080e7          	jalr	1066(ra) # 80001efc <myproc>
    80004ada:	5d1c                	lw	a5,56(a0)
    80004adc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004ade:	854a                	mv	a0,s2
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	22e080e7          	jalr	558(ra) # 80000d0e <release>
}
    80004ae8:	60e2                	ld	ra,24(sp)
    80004aea:	6442                	ld	s0,16(sp)
    80004aec:	64a2                	ld	s1,8(sp)
    80004aee:	6902                	ld	s2,0(sp)
    80004af0:	6105                	addi	sp,sp,32
    80004af2:	8082                	ret

0000000080004af4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004af4:	1101                	addi	sp,sp,-32
    80004af6:	ec06                	sd	ra,24(sp)
    80004af8:	e822                	sd	s0,16(sp)
    80004afa:	e426                	sd	s1,8(sp)
    80004afc:	e04a                	sd	s2,0(sp)
    80004afe:	1000                	addi	s0,sp,32
    80004b00:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b02:	00850913          	addi	s2,a0,8
    80004b06:	854a                	mv	a0,s2
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	152080e7          	jalr	338(ra) # 80000c5a <acquire>
  lk->locked = 0;
    80004b10:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b14:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b18:	8526                	mv	a0,s1
    80004b1a:	ffffe097          	auipc	ra,0xffffe
    80004b1e:	f00080e7          	jalr	-256(ra) # 80002a1a <wakeup>
  release(&lk->lk);
    80004b22:	854a                	mv	a0,s2
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	1ea080e7          	jalr	490(ra) # 80000d0e <release>
}
    80004b2c:	60e2                	ld	ra,24(sp)
    80004b2e:	6442                	ld	s0,16(sp)
    80004b30:	64a2                	ld	s1,8(sp)
    80004b32:	6902                	ld	s2,0(sp)
    80004b34:	6105                	addi	sp,sp,32
    80004b36:	8082                	ret

0000000080004b38 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b38:	7179                	addi	sp,sp,-48
    80004b3a:	f406                	sd	ra,40(sp)
    80004b3c:	f022                	sd	s0,32(sp)
    80004b3e:	ec26                	sd	s1,24(sp)
    80004b40:	e84a                	sd	s2,16(sp)
    80004b42:	e44e                	sd	s3,8(sp)
    80004b44:	1800                	addi	s0,sp,48
    80004b46:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b48:	00850913          	addi	s2,a0,8
    80004b4c:	854a                	mv	a0,s2
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	10c080e7          	jalr	268(ra) # 80000c5a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b56:	409c                	lw	a5,0(s1)
    80004b58:	ef99                	bnez	a5,80004b76 <holdingsleep+0x3e>
    80004b5a:	4481                	li	s1,0
  release(&lk->lk);
    80004b5c:	854a                	mv	a0,s2
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	1b0080e7          	jalr	432(ra) # 80000d0e <release>
  return r;
}
    80004b66:	8526                	mv	a0,s1
    80004b68:	70a2                	ld	ra,40(sp)
    80004b6a:	7402                	ld	s0,32(sp)
    80004b6c:	64e2                	ld	s1,24(sp)
    80004b6e:	6942                	ld	s2,16(sp)
    80004b70:	69a2                	ld	s3,8(sp)
    80004b72:	6145                	addi	sp,sp,48
    80004b74:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b76:	0284a983          	lw	s3,40(s1)
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	382080e7          	jalr	898(ra) # 80001efc <myproc>
    80004b82:	5d04                	lw	s1,56(a0)
    80004b84:	413484b3          	sub	s1,s1,s3
    80004b88:	0014b493          	seqz	s1,s1
    80004b8c:	bfc1                	j	80004b5c <holdingsleep+0x24>

0000000080004b8e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b8e:	1141                	addi	sp,sp,-16
    80004b90:	e406                	sd	ra,8(sp)
    80004b92:	e022                	sd	s0,0(sp)
    80004b94:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b96:	00004597          	auipc	a1,0x4
    80004b9a:	d6a58593          	addi	a1,a1,-662 # 80008900 <sysnames+0x248>
    80004b9e:	0001d517          	auipc	a0,0x1d
    80004ba2:	2b250513          	addi	a0,a0,690 # 80021e50 <ftable>
    80004ba6:	ffffc097          	auipc	ra,0xffffc
    80004baa:	024080e7          	jalr	36(ra) # 80000bca <initlock>
}
    80004bae:	60a2                	ld	ra,8(sp)
    80004bb0:	6402                	ld	s0,0(sp)
    80004bb2:	0141                	addi	sp,sp,16
    80004bb4:	8082                	ret

0000000080004bb6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bb6:	1101                	addi	sp,sp,-32
    80004bb8:	ec06                	sd	ra,24(sp)
    80004bba:	e822                	sd	s0,16(sp)
    80004bbc:	e426                	sd	s1,8(sp)
    80004bbe:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bc0:	0001d517          	auipc	a0,0x1d
    80004bc4:	29050513          	addi	a0,a0,656 # 80021e50 <ftable>
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	092080e7          	jalr	146(ra) # 80000c5a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bd0:	0001d497          	auipc	s1,0x1d
    80004bd4:	29848493          	addi	s1,s1,664 # 80021e68 <ftable+0x18>
    80004bd8:	0001e717          	auipc	a4,0x1e
    80004bdc:	23070713          	addi	a4,a4,560 # 80022e08 <ftable+0xfb8>
    if(f->ref == 0){
    80004be0:	40dc                	lw	a5,4(s1)
    80004be2:	cf99                	beqz	a5,80004c00 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004be4:	02848493          	addi	s1,s1,40
    80004be8:	fee49ce3          	bne	s1,a4,80004be0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004bec:	0001d517          	auipc	a0,0x1d
    80004bf0:	26450513          	addi	a0,a0,612 # 80021e50 <ftable>
    80004bf4:	ffffc097          	auipc	ra,0xffffc
    80004bf8:	11a080e7          	jalr	282(ra) # 80000d0e <release>
  return 0;
    80004bfc:	4481                	li	s1,0
    80004bfe:	a819                	j	80004c14 <filealloc+0x5e>
      f->ref = 1;
    80004c00:	4785                	li	a5,1
    80004c02:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c04:	0001d517          	auipc	a0,0x1d
    80004c08:	24c50513          	addi	a0,a0,588 # 80021e50 <ftable>
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	102080e7          	jalr	258(ra) # 80000d0e <release>
}
    80004c14:	8526                	mv	a0,s1
    80004c16:	60e2                	ld	ra,24(sp)
    80004c18:	6442                	ld	s0,16(sp)
    80004c1a:	64a2                	ld	s1,8(sp)
    80004c1c:	6105                	addi	sp,sp,32
    80004c1e:	8082                	ret

0000000080004c20 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c20:	1101                	addi	sp,sp,-32
    80004c22:	ec06                	sd	ra,24(sp)
    80004c24:	e822                	sd	s0,16(sp)
    80004c26:	e426                	sd	s1,8(sp)
    80004c28:	1000                	addi	s0,sp,32
    80004c2a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c2c:	0001d517          	auipc	a0,0x1d
    80004c30:	22450513          	addi	a0,a0,548 # 80021e50 <ftable>
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	026080e7          	jalr	38(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    80004c3c:	40dc                	lw	a5,4(s1)
    80004c3e:	02f05263          	blez	a5,80004c62 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c42:	2785                	addiw	a5,a5,1
    80004c44:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c46:	0001d517          	auipc	a0,0x1d
    80004c4a:	20a50513          	addi	a0,a0,522 # 80021e50 <ftable>
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	0c0080e7          	jalr	192(ra) # 80000d0e <release>
  return f;
}
    80004c56:	8526                	mv	a0,s1
    80004c58:	60e2                	ld	ra,24(sp)
    80004c5a:	6442                	ld	s0,16(sp)
    80004c5c:	64a2                	ld	s1,8(sp)
    80004c5e:	6105                	addi	sp,sp,32
    80004c60:	8082                	ret
    panic("filedup");
    80004c62:	00004517          	auipc	a0,0x4
    80004c66:	ca650513          	addi	a0,a0,-858 # 80008908 <sysnames+0x250>
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	8de080e7          	jalr	-1826(ra) # 80000548 <panic>

0000000080004c72 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c72:	7139                	addi	sp,sp,-64
    80004c74:	fc06                	sd	ra,56(sp)
    80004c76:	f822                	sd	s0,48(sp)
    80004c78:	f426                	sd	s1,40(sp)
    80004c7a:	f04a                	sd	s2,32(sp)
    80004c7c:	ec4e                	sd	s3,24(sp)
    80004c7e:	e852                	sd	s4,16(sp)
    80004c80:	e456                	sd	s5,8(sp)
    80004c82:	0080                	addi	s0,sp,64
    80004c84:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c86:	0001d517          	auipc	a0,0x1d
    80004c8a:	1ca50513          	addi	a0,a0,458 # 80021e50 <ftable>
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	fcc080e7          	jalr	-52(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    80004c96:	40dc                	lw	a5,4(s1)
    80004c98:	06f05163          	blez	a5,80004cfa <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c9c:	37fd                	addiw	a5,a5,-1
    80004c9e:	0007871b          	sext.w	a4,a5
    80004ca2:	c0dc                	sw	a5,4(s1)
    80004ca4:	06e04363          	bgtz	a4,80004d0a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ca8:	0004a903          	lw	s2,0(s1)
    80004cac:	0094ca83          	lbu	s5,9(s1)
    80004cb0:	0104ba03          	ld	s4,16(s1)
    80004cb4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004cb8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cbc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004cc0:	0001d517          	auipc	a0,0x1d
    80004cc4:	19050513          	addi	a0,a0,400 # 80021e50 <ftable>
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	046080e7          	jalr	70(ra) # 80000d0e <release>

  if(ff.type == FD_PIPE){
    80004cd0:	4785                	li	a5,1
    80004cd2:	04f90d63          	beq	s2,a5,80004d2c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004cd6:	3979                	addiw	s2,s2,-2
    80004cd8:	4785                	li	a5,1
    80004cda:	0527e063          	bltu	a5,s2,80004d1a <fileclose+0xa8>
    begin_op();
    80004cde:	00000097          	auipc	ra,0x0
    80004ce2:	ac2080e7          	jalr	-1342(ra) # 800047a0 <begin_op>
    iput(ff.ip);
    80004ce6:	854e                	mv	a0,s3
    80004ce8:	fffff097          	auipc	ra,0xfffff
    80004cec:	2b6080e7          	jalr	694(ra) # 80003f9e <iput>
    end_op();
    80004cf0:	00000097          	auipc	ra,0x0
    80004cf4:	b30080e7          	jalr	-1232(ra) # 80004820 <end_op>
    80004cf8:	a00d                	j	80004d1a <fileclose+0xa8>
    panic("fileclose");
    80004cfa:	00004517          	auipc	a0,0x4
    80004cfe:	c1650513          	addi	a0,a0,-1002 # 80008910 <sysnames+0x258>
    80004d02:	ffffc097          	auipc	ra,0xffffc
    80004d06:	846080e7          	jalr	-1978(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004d0a:	0001d517          	auipc	a0,0x1d
    80004d0e:	14650513          	addi	a0,a0,326 # 80021e50 <ftable>
    80004d12:	ffffc097          	auipc	ra,0xffffc
    80004d16:	ffc080e7          	jalr	-4(ra) # 80000d0e <release>
  }
}
    80004d1a:	70e2                	ld	ra,56(sp)
    80004d1c:	7442                	ld	s0,48(sp)
    80004d1e:	74a2                	ld	s1,40(sp)
    80004d20:	7902                	ld	s2,32(sp)
    80004d22:	69e2                	ld	s3,24(sp)
    80004d24:	6a42                	ld	s4,16(sp)
    80004d26:	6aa2                	ld	s5,8(sp)
    80004d28:	6121                	addi	sp,sp,64
    80004d2a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d2c:	85d6                	mv	a1,s5
    80004d2e:	8552                	mv	a0,s4
    80004d30:	00000097          	auipc	ra,0x0
    80004d34:	372080e7          	jalr	882(ra) # 800050a2 <pipeclose>
    80004d38:	b7cd                	j	80004d1a <fileclose+0xa8>

0000000080004d3a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d3a:	715d                	addi	sp,sp,-80
    80004d3c:	e486                	sd	ra,72(sp)
    80004d3e:	e0a2                	sd	s0,64(sp)
    80004d40:	fc26                	sd	s1,56(sp)
    80004d42:	f84a                	sd	s2,48(sp)
    80004d44:	f44e                	sd	s3,40(sp)
    80004d46:	0880                	addi	s0,sp,80
    80004d48:	84aa                	mv	s1,a0
    80004d4a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d4c:	ffffd097          	auipc	ra,0xffffd
    80004d50:	1b0080e7          	jalr	432(ra) # 80001efc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d54:	409c                	lw	a5,0(s1)
    80004d56:	37f9                	addiw	a5,a5,-2
    80004d58:	4705                	li	a4,1
    80004d5a:	04f76763          	bltu	a4,a5,80004da8 <filestat+0x6e>
    80004d5e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d60:	6c88                	ld	a0,24(s1)
    80004d62:	fffff097          	auipc	ra,0xfffff
    80004d66:	082080e7          	jalr	130(ra) # 80003de4 <ilock>
    stati(f->ip, &st);
    80004d6a:	fb840593          	addi	a1,s0,-72
    80004d6e:	6c88                	ld	a0,24(s1)
    80004d70:	fffff097          	auipc	ra,0xfffff
    80004d74:	2fe080e7          	jalr	766(ra) # 8000406e <stati>
    iunlock(f->ip);
    80004d78:	6c88                	ld	a0,24(s1)
    80004d7a:	fffff097          	auipc	ra,0xfffff
    80004d7e:	12c080e7          	jalr	300(ra) # 80003ea6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d82:	46e1                	li	a3,24
    80004d84:	fb840613          	addi	a2,s0,-72
    80004d88:	85ce                	mv	a1,s3
    80004d8a:	05093503          	ld	a0,80(s2)
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	9b2080e7          	jalr	-1614(ra) # 80001740 <copyout>
    80004d96:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d9a:	60a6                	ld	ra,72(sp)
    80004d9c:	6406                	ld	s0,64(sp)
    80004d9e:	74e2                	ld	s1,56(sp)
    80004da0:	7942                	ld	s2,48(sp)
    80004da2:	79a2                	ld	s3,40(sp)
    80004da4:	6161                	addi	sp,sp,80
    80004da6:	8082                	ret
  return -1;
    80004da8:	557d                	li	a0,-1
    80004daa:	bfc5                	j	80004d9a <filestat+0x60>

0000000080004dac <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004dac:	7179                	addi	sp,sp,-48
    80004dae:	f406                	sd	ra,40(sp)
    80004db0:	f022                	sd	s0,32(sp)
    80004db2:	ec26                	sd	s1,24(sp)
    80004db4:	e84a                	sd	s2,16(sp)
    80004db6:	e44e                	sd	s3,8(sp)
    80004db8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004dba:	00854783          	lbu	a5,8(a0)
    80004dbe:	c3d5                	beqz	a5,80004e62 <fileread+0xb6>
    80004dc0:	84aa                	mv	s1,a0
    80004dc2:	89ae                	mv	s3,a1
    80004dc4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dc6:	411c                	lw	a5,0(a0)
    80004dc8:	4705                	li	a4,1
    80004dca:	04e78963          	beq	a5,a4,80004e1c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dce:	470d                	li	a4,3
    80004dd0:	04e78d63          	beq	a5,a4,80004e2a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dd4:	4709                	li	a4,2
    80004dd6:	06e79e63          	bne	a5,a4,80004e52 <fileread+0xa6>
    ilock(f->ip);
    80004dda:	6d08                	ld	a0,24(a0)
    80004ddc:	fffff097          	auipc	ra,0xfffff
    80004de0:	008080e7          	jalr	8(ra) # 80003de4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004de4:	874a                	mv	a4,s2
    80004de6:	5094                	lw	a3,32(s1)
    80004de8:	864e                	mv	a2,s3
    80004dea:	4585                	li	a1,1
    80004dec:	6c88                	ld	a0,24(s1)
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	2aa080e7          	jalr	682(ra) # 80004098 <readi>
    80004df6:	892a                	mv	s2,a0
    80004df8:	00a05563          	blez	a0,80004e02 <fileread+0x56>
      f->off += r;
    80004dfc:	509c                	lw	a5,32(s1)
    80004dfe:	9fa9                	addw	a5,a5,a0
    80004e00:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e02:	6c88                	ld	a0,24(s1)
    80004e04:	fffff097          	auipc	ra,0xfffff
    80004e08:	0a2080e7          	jalr	162(ra) # 80003ea6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e0c:	854a                	mv	a0,s2
    80004e0e:	70a2                	ld	ra,40(sp)
    80004e10:	7402                	ld	s0,32(sp)
    80004e12:	64e2                	ld	s1,24(sp)
    80004e14:	6942                	ld	s2,16(sp)
    80004e16:	69a2                	ld	s3,8(sp)
    80004e18:	6145                	addi	sp,sp,48
    80004e1a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e1c:	6908                	ld	a0,16(a0)
    80004e1e:	00000097          	auipc	ra,0x0
    80004e22:	418080e7          	jalr	1048(ra) # 80005236 <piperead>
    80004e26:	892a                	mv	s2,a0
    80004e28:	b7d5                	j	80004e0c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e2a:	02451783          	lh	a5,36(a0)
    80004e2e:	03079693          	slli	a3,a5,0x30
    80004e32:	92c1                	srli	a3,a3,0x30
    80004e34:	4725                	li	a4,9
    80004e36:	02d76863          	bltu	a4,a3,80004e66 <fileread+0xba>
    80004e3a:	0792                	slli	a5,a5,0x4
    80004e3c:	0001d717          	auipc	a4,0x1d
    80004e40:	f7470713          	addi	a4,a4,-140 # 80021db0 <devsw>
    80004e44:	97ba                	add	a5,a5,a4
    80004e46:	639c                	ld	a5,0(a5)
    80004e48:	c38d                	beqz	a5,80004e6a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e4a:	4505                	li	a0,1
    80004e4c:	9782                	jalr	a5
    80004e4e:	892a                	mv	s2,a0
    80004e50:	bf75                	j	80004e0c <fileread+0x60>
    panic("fileread");
    80004e52:	00004517          	auipc	a0,0x4
    80004e56:	ace50513          	addi	a0,a0,-1330 # 80008920 <sysnames+0x268>
    80004e5a:	ffffb097          	auipc	ra,0xffffb
    80004e5e:	6ee080e7          	jalr	1774(ra) # 80000548 <panic>
    return -1;
    80004e62:	597d                	li	s2,-1
    80004e64:	b765                	j	80004e0c <fileread+0x60>
      return -1;
    80004e66:	597d                	li	s2,-1
    80004e68:	b755                	j	80004e0c <fileread+0x60>
    80004e6a:	597d                	li	s2,-1
    80004e6c:	b745                	j	80004e0c <fileread+0x60>

0000000080004e6e <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004e6e:	00954783          	lbu	a5,9(a0)
    80004e72:	14078563          	beqz	a5,80004fbc <filewrite+0x14e>
{
    80004e76:	715d                	addi	sp,sp,-80
    80004e78:	e486                	sd	ra,72(sp)
    80004e7a:	e0a2                	sd	s0,64(sp)
    80004e7c:	fc26                	sd	s1,56(sp)
    80004e7e:	f84a                	sd	s2,48(sp)
    80004e80:	f44e                	sd	s3,40(sp)
    80004e82:	f052                	sd	s4,32(sp)
    80004e84:	ec56                	sd	s5,24(sp)
    80004e86:	e85a                	sd	s6,16(sp)
    80004e88:	e45e                	sd	s7,8(sp)
    80004e8a:	e062                	sd	s8,0(sp)
    80004e8c:	0880                	addi	s0,sp,80
    80004e8e:	892a                	mv	s2,a0
    80004e90:	8aae                	mv	s5,a1
    80004e92:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e94:	411c                	lw	a5,0(a0)
    80004e96:	4705                	li	a4,1
    80004e98:	02e78263          	beq	a5,a4,80004ebc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e9c:	470d                	li	a4,3
    80004e9e:	02e78563          	beq	a5,a4,80004ec8 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ea2:	4709                	li	a4,2
    80004ea4:	10e79463          	bne	a5,a4,80004fac <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ea8:	0ec05e63          	blez	a2,80004fa4 <filewrite+0x136>
    int i = 0;
    80004eac:	4981                	li	s3,0
    80004eae:	6b05                	lui	s6,0x1
    80004eb0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004eb4:	6b85                	lui	s7,0x1
    80004eb6:	c00b8b9b          	addiw	s7,s7,-1024
    80004eba:	a851                	j	80004f4e <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004ebc:	6908                	ld	a0,16(a0)
    80004ebe:	00000097          	auipc	ra,0x0
    80004ec2:	254080e7          	jalr	596(ra) # 80005112 <pipewrite>
    80004ec6:	a85d                	j	80004f7c <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ec8:	02451783          	lh	a5,36(a0)
    80004ecc:	03079693          	slli	a3,a5,0x30
    80004ed0:	92c1                	srli	a3,a3,0x30
    80004ed2:	4725                	li	a4,9
    80004ed4:	0ed76663          	bltu	a4,a3,80004fc0 <filewrite+0x152>
    80004ed8:	0792                	slli	a5,a5,0x4
    80004eda:	0001d717          	auipc	a4,0x1d
    80004ede:	ed670713          	addi	a4,a4,-298 # 80021db0 <devsw>
    80004ee2:	97ba                	add	a5,a5,a4
    80004ee4:	679c                	ld	a5,8(a5)
    80004ee6:	cff9                	beqz	a5,80004fc4 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004ee8:	4505                	li	a0,1
    80004eea:	9782                	jalr	a5
    80004eec:	a841                	j	80004f7c <filewrite+0x10e>
    80004eee:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ef2:	00000097          	auipc	ra,0x0
    80004ef6:	8ae080e7          	jalr	-1874(ra) # 800047a0 <begin_op>
      ilock(f->ip);
    80004efa:	01893503          	ld	a0,24(s2)
    80004efe:	fffff097          	auipc	ra,0xfffff
    80004f02:	ee6080e7          	jalr	-282(ra) # 80003de4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f06:	8762                	mv	a4,s8
    80004f08:	02092683          	lw	a3,32(s2)
    80004f0c:	01598633          	add	a2,s3,s5
    80004f10:	4585                	li	a1,1
    80004f12:	01893503          	ld	a0,24(s2)
    80004f16:	fffff097          	auipc	ra,0xfffff
    80004f1a:	278080e7          	jalr	632(ra) # 8000418e <writei>
    80004f1e:	84aa                	mv	s1,a0
    80004f20:	02a05f63          	blez	a0,80004f5e <filewrite+0xf0>
        f->off += r;
    80004f24:	02092783          	lw	a5,32(s2)
    80004f28:	9fa9                	addw	a5,a5,a0
    80004f2a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f2e:	01893503          	ld	a0,24(s2)
    80004f32:	fffff097          	auipc	ra,0xfffff
    80004f36:	f74080e7          	jalr	-140(ra) # 80003ea6 <iunlock>
      end_op();
    80004f3a:	00000097          	auipc	ra,0x0
    80004f3e:	8e6080e7          	jalr	-1818(ra) # 80004820 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004f42:	049c1963          	bne	s8,s1,80004f94 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004f46:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f4a:	0349d663          	bge	s3,s4,80004f76 <filewrite+0x108>
      int n1 = n - i;
    80004f4e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f52:	84be                	mv	s1,a5
    80004f54:	2781                	sext.w	a5,a5
    80004f56:	f8fb5ce3          	bge	s6,a5,80004eee <filewrite+0x80>
    80004f5a:	84de                	mv	s1,s7
    80004f5c:	bf49                	j	80004eee <filewrite+0x80>
      iunlock(f->ip);
    80004f5e:	01893503          	ld	a0,24(s2)
    80004f62:	fffff097          	auipc	ra,0xfffff
    80004f66:	f44080e7          	jalr	-188(ra) # 80003ea6 <iunlock>
      end_op();
    80004f6a:	00000097          	auipc	ra,0x0
    80004f6e:	8b6080e7          	jalr	-1866(ra) # 80004820 <end_op>
      if(r < 0)
    80004f72:	fc04d8e3          	bgez	s1,80004f42 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004f76:	8552                	mv	a0,s4
    80004f78:	033a1863          	bne	s4,s3,80004fa8 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f7c:	60a6                	ld	ra,72(sp)
    80004f7e:	6406                	ld	s0,64(sp)
    80004f80:	74e2                	ld	s1,56(sp)
    80004f82:	7942                	ld	s2,48(sp)
    80004f84:	79a2                	ld	s3,40(sp)
    80004f86:	7a02                	ld	s4,32(sp)
    80004f88:	6ae2                	ld	s5,24(sp)
    80004f8a:	6b42                	ld	s6,16(sp)
    80004f8c:	6ba2                	ld	s7,8(sp)
    80004f8e:	6c02                	ld	s8,0(sp)
    80004f90:	6161                	addi	sp,sp,80
    80004f92:	8082                	ret
        panic("short filewrite");
    80004f94:	00004517          	auipc	a0,0x4
    80004f98:	99c50513          	addi	a0,a0,-1636 # 80008930 <sysnames+0x278>
    80004f9c:	ffffb097          	auipc	ra,0xffffb
    80004fa0:	5ac080e7          	jalr	1452(ra) # 80000548 <panic>
    int i = 0;
    80004fa4:	4981                	li	s3,0
    80004fa6:	bfc1                	j	80004f76 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004fa8:	557d                	li	a0,-1
    80004faa:	bfc9                	j	80004f7c <filewrite+0x10e>
    panic("filewrite");
    80004fac:	00004517          	auipc	a0,0x4
    80004fb0:	99450513          	addi	a0,a0,-1644 # 80008940 <sysnames+0x288>
    80004fb4:	ffffb097          	auipc	ra,0xffffb
    80004fb8:	594080e7          	jalr	1428(ra) # 80000548 <panic>
    return -1;
    80004fbc:	557d                	li	a0,-1
}
    80004fbe:	8082                	ret
      return -1;
    80004fc0:	557d                	li	a0,-1
    80004fc2:	bf6d                	j	80004f7c <filewrite+0x10e>
    80004fc4:	557d                	li	a0,-1
    80004fc6:	bf5d                	j	80004f7c <filewrite+0x10e>

0000000080004fc8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004fc8:	7179                	addi	sp,sp,-48
    80004fca:	f406                	sd	ra,40(sp)
    80004fcc:	f022                	sd	s0,32(sp)
    80004fce:	ec26                	sd	s1,24(sp)
    80004fd0:	e84a                	sd	s2,16(sp)
    80004fd2:	e44e                	sd	s3,8(sp)
    80004fd4:	e052                	sd	s4,0(sp)
    80004fd6:	1800                	addi	s0,sp,48
    80004fd8:	84aa                	mv	s1,a0
    80004fda:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004fdc:	0005b023          	sd	zero,0(a1)
    80004fe0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004fe4:	00000097          	auipc	ra,0x0
    80004fe8:	bd2080e7          	jalr	-1070(ra) # 80004bb6 <filealloc>
    80004fec:	e088                	sd	a0,0(s1)
    80004fee:	c551                	beqz	a0,8000507a <pipealloc+0xb2>
    80004ff0:	00000097          	auipc	ra,0x0
    80004ff4:	bc6080e7          	jalr	-1082(ra) # 80004bb6 <filealloc>
    80004ff8:	00aa3023          	sd	a0,0(s4)
    80004ffc:	c92d                	beqz	a0,8000506e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ffe:	ffffc097          	auipc	ra,0xffffc
    80005002:	b22080e7          	jalr	-1246(ra) # 80000b20 <kalloc>
    80005006:	892a                	mv	s2,a0
    80005008:	c125                	beqz	a0,80005068 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000500a:	4985                	li	s3,1
    8000500c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005010:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005014:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005018:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000501c:	00003597          	auipc	a1,0x3
    80005020:	52c58593          	addi	a1,a1,1324 # 80008548 <states.1740+0x198>
    80005024:	ffffc097          	auipc	ra,0xffffc
    80005028:	ba6080e7          	jalr	-1114(ra) # 80000bca <initlock>
  (*f0)->type = FD_PIPE;
    8000502c:	609c                	ld	a5,0(s1)
    8000502e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005032:	609c                	ld	a5,0(s1)
    80005034:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005038:	609c                	ld	a5,0(s1)
    8000503a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000503e:	609c                	ld	a5,0(s1)
    80005040:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005044:	000a3783          	ld	a5,0(s4)
    80005048:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000504c:	000a3783          	ld	a5,0(s4)
    80005050:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005054:	000a3783          	ld	a5,0(s4)
    80005058:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000505c:	000a3783          	ld	a5,0(s4)
    80005060:	0127b823          	sd	s2,16(a5)
  return 0;
    80005064:	4501                	li	a0,0
    80005066:	a025                	j	8000508e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005068:	6088                	ld	a0,0(s1)
    8000506a:	e501                	bnez	a0,80005072 <pipealloc+0xaa>
    8000506c:	a039                	j	8000507a <pipealloc+0xb2>
    8000506e:	6088                	ld	a0,0(s1)
    80005070:	c51d                	beqz	a0,8000509e <pipealloc+0xd6>
    fileclose(*f0);
    80005072:	00000097          	auipc	ra,0x0
    80005076:	c00080e7          	jalr	-1024(ra) # 80004c72 <fileclose>
  if(*f1)
    8000507a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000507e:	557d                	li	a0,-1
  if(*f1)
    80005080:	c799                	beqz	a5,8000508e <pipealloc+0xc6>
    fileclose(*f1);
    80005082:	853e                	mv	a0,a5
    80005084:	00000097          	auipc	ra,0x0
    80005088:	bee080e7          	jalr	-1042(ra) # 80004c72 <fileclose>
  return -1;
    8000508c:	557d                	li	a0,-1
}
    8000508e:	70a2                	ld	ra,40(sp)
    80005090:	7402                	ld	s0,32(sp)
    80005092:	64e2                	ld	s1,24(sp)
    80005094:	6942                	ld	s2,16(sp)
    80005096:	69a2                	ld	s3,8(sp)
    80005098:	6a02                	ld	s4,0(sp)
    8000509a:	6145                	addi	sp,sp,48
    8000509c:	8082                	ret
  return -1;
    8000509e:	557d                	li	a0,-1
    800050a0:	b7fd                	j	8000508e <pipealloc+0xc6>

00000000800050a2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050a2:	1101                	addi	sp,sp,-32
    800050a4:	ec06                	sd	ra,24(sp)
    800050a6:	e822                	sd	s0,16(sp)
    800050a8:	e426                	sd	s1,8(sp)
    800050aa:	e04a                	sd	s2,0(sp)
    800050ac:	1000                	addi	s0,sp,32
    800050ae:	84aa                	mv	s1,a0
    800050b0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800050b2:	ffffc097          	auipc	ra,0xffffc
    800050b6:	ba8080e7          	jalr	-1112(ra) # 80000c5a <acquire>
  if(writable){
    800050ba:	02090d63          	beqz	s2,800050f4 <pipeclose+0x52>
    pi->writeopen = 0;
    800050be:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050c2:	21848513          	addi	a0,s1,536
    800050c6:	ffffe097          	auipc	ra,0xffffe
    800050ca:	954080e7          	jalr	-1708(ra) # 80002a1a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050ce:	2204b783          	ld	a5,544(s1)
    800050d2:	eb95                	bnez	a5,80005106 <pipeclose+0x64>
    release(&pi->lock);
    800050d4:	8526                	mv	a0,s1
    800050d6:	ffffc097          	auipc	ra,0xffffc
    800050da:	c38080e7          	jalr	-968(ra) # 80000d0e <release>
    kfree((char*)pi);
    800050de:	8526                	mv	a0,s1
    800050e0:	ffffc097          	auipc	ra,0xffffc
    800050e4:	944080e7          	jalr	-1724(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    800050e8:	60e2                	ld	ra,24(sp)
    800050ea:	6442                	ld	s0,16(sp)
    800050ec:	64a2                	ld	s1,8(sp)
    800050ee:	6902                	ld	s2,0(sp)
    800050f0:	6105                	addi	sp,sp,32
    800050f2:	8082                	ret
    pi->readopen = 0;
    800050f4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050f8:	21c48513          	addi	a0,s1,540
    800050fc:	ffffe097          	auipc	ra,0xffffe
    80005100:	91e080e7          	jalr	-1762(ra) # 80002a1a <wakeup>
    80005104:	b7e9                	j	800050ce <pipeclose+0x2c>
    release(&pi->lock);
    80005106:	8526                	mv	a0,s1
    80005108:	ffffc097          	auipc	ra,0xffffc
    8000510c:	c06080e7          	jalr	-1018(ra) # 80000d0e <release>
}
    80005110:	bfe1                	j	800050e8 <pipeclose+0x46>

0000000080005112 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005112:	7119                	addi	sp,sp,-128
    80005114:	fc86                	sd	ra,120(sp)
    80005116:	f8a2                	sd	s0,112(sp)
    80005118:	f4a6                	sd	s1,104(sp)
    8000511a:	f0ca                	sd	s2,96(sp)
    8000511c:	ecce                	sd	s3,88(sp)
    8000511e:	e8d2                	sd	s4,80(sp)
    80005120:	e4d6                	sd	s5,72(sp)
    80005122:	e0da                	sd	s6,64(sp)
    80005124:	fc5e                	sd	s7,56(sp)
    80005126:	f862                	sd	s8,48(sp)
    80005128:	f466                	sd	s9,40(sp)
    8000512a:	f06a                	sd	s10,32(sp)
    8000512c:	ec6e                	sd	s11,24(sp)
    8000512e:	0100                	addi	s0,sp,128
    80005130:	84aa                	mv	s1,a0
    80005132:	8cae                	mv	s9,a1
    80005134:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80005136:	ffffd097          	auipc	ra,0xffffd
    8000513a:	dc6080e7          	jalr	-570(ra) # 80001efc <myproc>
    8000513e:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80005140:	8526                	mv	a0,s1
    80005142:	ffffc097          	auipc	ra,0xffffc
    80005146:	b18080e7          	jalr	-1256(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    8000514a:	0d605963          	blez	s6,8000521c <pipewrite+0x10a>
    8000514e:	89a6                	mv	s3,s1
    80005150:	3b7d                	addiw	s6,s6,-1
    80005152:	1b02                	slli	s6,s6,0x20
    80005154:	020b5b13          	srli	s6,s6,0x20
    80005158:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    8000515a:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000515e:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005162:	5dfd                	li	s11,-1
    80005164:	000b8d1b          	sext.w	s10,s7
    80005168:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    8000516a:	2184a783          	lw	a5,536(s1)
    8000516e:	21c4a703          	lw	a4,540(s1)
    80005172:	2007879b          	addiw	a5,a5,512
    80005176:	02f71b63          	bne	a4,a5,800051ac <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    8000517a:	2204a783          	lw	a5,544(s1)
    8000517e:	cbad                	beqz	a5,800051f0 <pipewrite+0xde>
    80005180:	03092783          	lw	a5,48(s2)
    80005184:	e7b5                	bnez	a5,800051f0 <pipewrite+0xde>
      wakeup(&pi->nread);
    80005186:	8556                	mv	a0,s5
    80005188:	ffffe097          	auipc	ra,0xffffe
    8000518c:	892080e7          	jalr	-1902(ra) # 80002a1a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005190:	85ce                	mv	a1,s3
    80005192:	8552                	mv	a0,s4
    80005194:	ffffd097          	auipc	ra,0xffffd
    80005198:	700080e7          	jalr	1792(ra) # 80002894 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    8000519c:	2184a783          	lw	a5,536(s1)
    800051a0:	21c4a703          	lw	a4,540(s1)
    800051a4:	2007879b          	addiw	a5,a5,512
    800051a8:	fcf709e3          	beq	a4,a5,8000517a <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051ac:	4685                	li	a3,1
    800051ae:	019b8633          	add	a2,s7,s9
    800051b2:	f8f40593          	addi	a1,s0,-113
    800051b6:	05093503          	ld	a0,80(s2)
    800051ba:	ffffc097          	auipc	ra,0xffffc
    800051be:	612080e7          	jalr	1554(ra) # 800017cc <copyin>
    800051c2:	05b50e63          	beq	a0,s11,8000521e <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051c6:	21c4a783          	lw	a5,540(s1)
    800051ca:	0017871b          	addiw	a4,a5,1
    800051ce:	20e4ae23          	sw	a4,540(s1)
    800051d2:	1ff7f793          	andi	a5,a5,511
    800051d6:	97a6                	add	a5,a5,s1
    800051d8:	f8f44703          	lbu	a4,-113(s0)
    800051dc:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    800051e0:	001d0c1b          	addiw	s8,s10,1
    800051e4:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    800051e8:	036b8b63          	beq	s7,s6,8000521e <pipewrite+0x10c>
    800051ec:	8bbe                	mv	s7,a5
    800051ee:	bf9d                	j	80005164 <pipewrite+0x52>
        release(&pi->lock);
    800051f0:	8526                	mv	a0,s1
    800051f2:	ffffc097          	auipc	ra,0xffffc
    800051f6:	b1c080e7          	jalr	-1252(ra) # 80000d0e <release>
        return -1;
    800051fa:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    800051fc:	8562                	mv	a0,s8
    800051fe:	70e6                	ld	ra,120(sp)
    80005200:	7446                	ld	s0,112(sp)
    80005202:	74a6                	ld	s1,104(sp)
    80005204:	7906                	ld	s2,96(sp)
    80005206:	69e6                	ld	s3,88(sp)
    80005208:	6a46                	ld	s4,80(sp)
    8000520a:	6aa6                	ld	s5,72(sp)
    8000520c:	6b06                	ld	s6,64(sp)
    8000520e:	7be2                	ld	s7,56(sp)
    80005210:	7c42                	ld	s8,48(sp)
    80005212:	7ca2                	ld	s9,40(sp)
    80005214:	7d02                	ld	s10,32(sp)
    80005216:	6de2                	ld	s11,24(sp)
    80005218:	6109                	addi	sp,sp,128
    8000521a:	8082                	ret
  for(i = 0; i < n; i++){
    8000521c:	4c01                	li	s8,0
  wakeup(&pi->nread);
    8000521e:	21848513          	addi	a0,s1,536
    80005222:	ffffd097          	auipc	ra,0xffffd
    80005226:	7f8080e7          	jalr	2040(ra) # 80002a1a <wakeup>
  release(&pi->lock);
    8000522a:	8526                	mv	a0,s1
    8000522c:	ffffc097          	auipc	ra,0xffffc
    80005230:	ae2080e7          	jalr	-1310(ra) # 80000d0e <release>
  return i;
    80005234:	b7e1                	j	800051fc <pipewrite+0xea>

0000000080005236 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005236:	715d                	addi	sp,sp,-80
    80005238:	e486                	sd	ra,72(sp)
    8000523a:	e0a2                	sd	s0,64(sp)
    8000523c:	fc26                	sd	s1,56(sp)
    8000523e:	f84a                	sd	s2,48(sp)
    80005240:	f44e                	sd	s3,40(sp)
    80005242:	f052                	sd	s4,32(sp)
    80005244:	ec56                	sd	s5,24(sp)
    80005246:	e85a                	sd	s6,16(sp)
    80005248:	0880                	addi	s0,sp,80
    8000524a:	84aa                	mv	s1,a0
    8000524c:	892e                	mv	s2,a1
    8000524e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005250:	ffffd097          	auipc	ra,0xffffd
    80005254:	cac080e7          	jalr	-852(ra) # 80001efc <myproc>
    80005258:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000525a:	8b26                	mv	s6,s1
    8000525c:	8526                	mv	a0,s1
    8000525e:	ffffc097          	auipc	ra,0xffffc
    80005262:	9fc080e7          	jalr	-1540(ra) # 80000c5a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005266:	2184a703          	lw	a4,536(s1)
    8000526a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000526e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005272:	02f71463          	bne	a4,a5,8000529a <piperead+0x64>
    80005276:	2244a783          	lw	a5,548(s1)
    8000527a:	c385                	beqz	a5,8000529a <piperead+0x64>
    if(pr->killed){
    8000527c:	030a2783          	lw	a5,48(s4)
    80005280:	ebc1                	bnez	a5,80005310 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005282:	85da                	mv	a1,s6
    80005284:	854e                	mv	a0,s3
    80005286:	ffffd097          	auipc	ra,0xffffd
    8000528a:	60e080e7          	jalr	1550(ra) # 80002894 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000528e:	2184a703          	lw	a4,536(s1)
    80005292:	21c4a783          	lw	a5,540(s1)
    80005296:	fef700e3          	beq	a4,a5,80005276 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000529a:	09505263          	blez	s5,8000531e <piperead+0xe8>
    8000529e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052a0:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800052a2:	2184a783          	lw	a5,536(s1)
    800052a6:	21c4a703          	lw	a4,540(s1)
    800052aa:	02f70d63          	beq	a4,a5,800052e4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800052ae:	0017871b          	addiw	a4,a5,1
    800052b2:	20e4ac23          	sw	a4,536(s1)
    800052b6:	1ff7f793          	andi	a5,a5,511
    800052ba:	97a6                	add	a5,a5,s1
    800052bc:	0187c783          	lbu	a5,24(a5)
    800052c0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052c4:	4685                	li	a3,1
    800052c6:	fbf40613          	addi	a2,s0,-65
    800052ca:	85ca                	mv	a1,s2
    800052cc:	050a3503          	ld	a0,80(s4)
    800052d0:	ffffc097          	auipc	ra,0xffffc
    800052d4:	470080e7          	jalr	1136(ra) # 80001740 <copyout>
    800052d8:	01650663          	beq	a0,s6,800052e4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052dc:	2985                	addiw	s3,s3,1
    800052de:	0905                	addi	s2,s2,1
    800052e0:	fd3a91e3          	bne	s5,s3,800052a2 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052e4:	21c48513          	addi	a0,s1,540
    800052e8:	ffffd097          	auipc	ra,0xffffd
    800052ec:	732080e7          	jalr	1842(ra) # 80002a1a <wakeup>
  release(&pi->lock);
    800052f0:	8526                	mv	a0,s1
    800052f2:	ffffc097          	auipc	ra,0xffffc
    800052f6:	a1c080e7          	jalr	-1508(ra) # 80000d0e <release>
  return i;
}
    800052fa:	854e                	mv	a0,s3
    800052fc:	60a6                	ld	ra,72(sp)
    800052fe:	6406                	ld	s0,64(sp)
    80005300:	74e2                	ld	s1,56(sp)
    80005302:	7942                	ld	s2,48(sp)
    80005304:	79a2                	ld	s3,40(sp)
    80005306:	7a02                	ld	s4,32(sp)
    80005308:	6ae2                	ld	s5,24(sp)
    8000530a:	6b42                	ld	s6,16(sp)
    8000530c:	6161                	addi	sp,sp,80
    8000530e:	8082                	ret
      release(&pi->lock);
    80005310:	8526                	mv	a0,s1
    80005312:	ffffc097          	auipc	ra,0xffffc
    80005316:	9fc080e7          	jalr	-1540(ra) # 80000d0e <release>
      return -1;
    8000531a:	59fd                	li	s3,-1
    8000531c:	bff9                	j	800052fa <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000531e:	4981                	li	s3,0
    80005320:	b7d1                	j	800052e4 <piperead+0xae>

0000000080005322 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005322:	df010113          	addi	sp,sp,-528
    80005326:	20113423          	sd	ra,520(sp)
    8000532a:	20813023          	sd	s0,512(sp)
    8000532e:	ffa6                	sd	s1,504(sp)
    80005330:	fbca                	sd	s2,496(sp)
    80005332:	f7ce                	sd	s3,488(sp)
    80005334:	f3d2                	sd	s4,480(sp)
    80005336:	efd6                	sd	s5,472(sp)
    80005338:	ebda                	sd	s6,464(sp)
    8000533a:	e7de                	sd	s7,456(sp)
    8000533c:	e3e2                	sd	s8,448(sp)
    8000533e:	ff66                	sd	s9,440(sp)
    80005340:	fb6a                	sd	s10,432(sp)
    80005342:	f76e                	sd	s11,424(sp)
    80005344:	0c00                	addi	s0,sp,528
    80005346:	84aa                	mv	s1,a0
    80005348:	dea43c23          	sd	a0,-520(s0)
    8000534c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005350:	ffffd097          	auipc	ra,0xffffd
    80005354:	bac080e7          	jalr	-1108(ra) # 80001efc <myproc>
    80005358:	892a                	mv	s2,a0

  begin_op();
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	446080e7          	jalr	1094(ra) # 800047a0 <begin_op>

  if((ip = namei(path)) == 0){
    80005362:	8526                	mv	a0,s1
    80005364:	fffff097          	auipc	ra,0xfffff
    80005368:	230080e7          	jalr	560(ra) # 80004594 <namei>
    8000536c:	c92d                	beqz	a0,800053de <exec+0xbc>
    8000536e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	a74080e7          	jalr	-1420(ra) # 80003de4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005378:	04000713          	li	a4,64
    8000537c:	4681                	li	a3,0
    8000537e:	e4840613          	addi	a2,s0,-440
    80005382:	4581                	li	a1,0
    80005384:	8526                	mv	a0,s1
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	d12080e7          	jalr	-750(ra) # 80004098 <readi>
    8000538e:	04000793          	li	a5,64
    80005392:	00f51a63          	bne	a0,a5,800053a6 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005396:	e4842703          	lw	a4,-440(s0)
    8000539a:	464c47b7          	lui	a5,0x464c4
    8000539e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800053a2:	04f70463          	beq	a4,a5,800053ea <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800053a6:	8526                	mv	a0,s1
    800053a8:	fffff097          	auipc	ra,0xfffff
    800053ac:	c9e080e7          	jalr	-866(ra) # 80004046 <iunlockput>
    end_op();
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	470080e7          	jalr	1136(ra) # 80004820 <end_op>
  }
  return -1;
    800053b8:	557d                	li	a0,-1
}
    800053ba:	20813083          	ld	ra,520(sp)
    800053be:	20013403          	ld	s0,512(sp)
    800053c2:	74fe                	ld	s1,504(sp)
    800053c4:	795e                	ld	s2,496(sp)
    800053c6:	79be                	ld	s3,488(sp)
    800053c8:	7a1e                	ld	s4,480(sp)
    800053ca:	6afe                	ld	s5,472(sp)
    800053cc:	6b5e                	ld	s6,464(sp)
    800053ce:	6bbe                	ld	s7,456(sp)
    800053d0:	6c1e                	ld	s8,448(sp)
    800053d2:	7cfa                	ld	s9,440(sp)
    800053d4:	7d5a                	ld	s10,432(sp)
    800053d6:	7dba                	ld	s11,424(sp)
    800053d8:	21010113          	addi	sp,sp,528
    800053dc:	8082                	ret
    end_op();
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	442080e7          	jalr	1090(ra) # 80004820 <end_op>
    return -1;
    800053e6:	557d                	li	a0,-1
    800053e8:	bfc9                	j	800053ba <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800053ea:	854a                	mv	a0,s2
    800053ec:	ffffd097          	auipc	ra,0xffffd
    800053f0:	bd4080e7          	jalr	-1068(ra) # 80001fc0 <proc_pagetable>
    800053f4:	8baa                	mv	s7,a0
    800053f6:	d945                	beqz	a0,800053a6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053f8:	e6842983          	lw	s3,-408(s0)
    800053fc:	e8045783          	lhu	a5,-384(s0)
    80005400:	c7ad                	beqz	a5,8000546a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005402:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005404:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005406:	6c85                	lui	s9,0x1
    80005408:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000540c:	def43823          	sd	a5,-528(s0)
    80005410:	a489                	j	80005652 <exec+0x330>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005412:	00003517          	auipc	a0,0x3
    80005416:	53e50513          	addi	a0,a0,1342 # 80008950 <sysnames+0x298>
    8000541a:	ffffb097          	auipc	ra,0xffffb
    8000541e:	12e080e7          	jalr	302(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005422:	8756                	mv	a4,s5
    80005424:	012d86bb          	addw	a3,s11,s2
    80005428:	4581                	li	a1,0
    8000542a:	8526                	mv	a0,s1
    8000542c:	fffff097          	auipc	ra,0xfffff
    80005430:	c6c080e7          	jalr	-916(ra) # 80004098 <readi>
    80005434:	2501                	sext.w	a0,a0
    80005436:	1caa9563          	bne	s5,a0,80005600 <exec+0x2de>
  for(i = 0; i < sz; i += PGSIZE){
    8000543a:	6785                	lui	a5,0x1
    8000543c:	0127893b          	addw	s2,a5,s2
    80005440:	77fd                	lui	a5,0xfffff
    80005442:	01478a3b          	addw	s4,a5,s4
    80005446:	1f897d63          	bgeu	s2,s8,80005640 <exec+0x31e>
    pa = walkaddr(pagetable, va + i);
    8000544a:	02091593          	slli	a1,s2,0x20
    8000544e:	9181                	srli	a1,a1,0x20
    80005450:	95ea                	add	a1,a1,s10
    80005452:	855e                	mv	a0,s7
    80005454:	ffffc097          	auipc	ra,0xffffc
    80005458:	cb8080e7          	jalr	-840(ra) # 8000110c <walkaddr>
    8000545c:	862a                	mv	a2,a0
    if(pa == 0)
    8000545e:	d955                	beqz	a0,80005412 <exec+0xf0>
      n = PGSIZE;
    80005460:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005462:	fd9a70e3          	bgeu	s4,s9,80005422 <exec+0x100>
      n = sz - i;
    80005466:	8ad2                	mv	s5,s4
    80005468:	bf6d                	j	80005422 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000546a:	4901                	li	s2,0
  iunlockput(ip);
    8000546c:	8526                	mv	a0,s1
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	bd8080e7          	jalr	-1064(ra) # 80004046 <iunlockput>
  end_op();
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	3aa080e7          	jalr	938(ra) # 80004820 <end_op>
  p = myproc();
    8000547e:	ffffd097          	auipc	ra,0xffffd
    80005482:	a7e080e7          	jalr	-1410(ra) # 80001efc <myproc>
    80005486:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005488:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000548c:	6785                	lui	a5,0x1
    8000548e:	17fd                	addi	a5,a5,-1
    80005490:	993e                	add	s2,s2,a5
    80005492:	757d                	lui	a0,0xfffff
    80005494:	00a977b3          	and	a5,s2,a0
    80005498:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000549c:	6609                	lui	a2,0x2
    8000549e:	963e                	add	a2,a2,a5
    800054a0:	85be                	mv	a1,a5
    800054a2:	855e                	mv	a0,s7
    800054a4:	ffffc097          	auipc	ra,0xffffc
    800054a8:	04c080e7          	jalr	76(ra) # 800014f0 <uvmalloc>
    800054ac:	8b2a                	mv	s6,a0
  ip = 0;
    800054ae:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054b0:	14050863          	beqz	a0,80005600 <exec+0x2de>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054b4:	75f9                	lui	a1,0xffffe
    800054b6:	95aa                	add	a1,a1,a0
    800054b8:	855e                	mv	a0,s7
    800054ba:	ffffc097          	auipc	ra,0xffffc
    800054be:	254080e7          	jalr	596(ra) # 8000170e <uvmclear>
  stackbase = sp - PGSIZE;
    800054c2:	7c7d                	lui	s8,0xfffff
    800054c4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800054c6:	e0043783          	ld	a5,-512(s0)
    800054ca:	6388                	ld	a0,0(a5)
    800054cc:	c535                	beqz	a0,80005538 <exec+0x216>
    800054ce:	e8840993          	addi	s3,s0,-376
    800054d2:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800054d6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800054d8:	ffffc097          	auipc	ra,0xffffc
    800054dc:	a06080e7          	jalr	-1530(ra) # 80000ede <strlen>
    800054e0:	2505                	addiw	a0,a0,1
    800054e2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054e6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800054ea:	13896f63          	bltu	s2,s8,80005628 <exec+0x306>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054ee:	e0043d83          	ld	s11,-512(s0)
    800054f2:	000dba03          	ld	s4,0(s11)
    800054f6:	8552                	mv	a0,s4
    800054f8:	ffffc097          	auipc	ra,0xffffc
    800054fc:	9e6080e7          	jalr	-1562(ra) # 80000ede <strlen>
    80005500:	0015069b          	addiw	a3,a0,1
    80005504:	8652                	mv	a2,s4
    80005506:	85ca                	mv	a1,s2
    80005508:	855e                	mv	a0,s7
    8000550a:	ffffc097          	auipc	ra,0xffffc
    8000550e:	236080e7          	jalr	566(ra) # 80001740 <copyout>
    80005512:	10054f63          	bltz	a0,80005630 <exec+0x30e>
    ustack[argc] = sp;
    80005516:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000551a:	0485                	addi	s1,s1,1
    8000551c:	008d8793          	addi	a5,s11,8
    80005520:	e0f43023          	sd	a5,-512(s0)
    80005524:	008db503          	ld	a0,8(s11)
    80005528:	c911                	beqz	a0,8000553c <exec+0x21a>
    if(argc >= MAXARG)
    8000552a:	09a1                	addi	s3,s3,8
    8000552c:	fb3c96e3          	bne	s9,s3,800054d8 <exec+0x1b6>
  sz = sz1;
    80005530:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005534:	4481                	li	s1,0
    80005536:	a0e9                	j	80005600 <exec+0x2de>
  sp = sz;
    80005538:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000553a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000553c:	00349793          	slli	a5,s1,0x3
    80005540:	f9040713          	addi	a4,s0,-112
    80005544:	97ba                	add	a5,a5,a4
    80005546:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    8000554a:	00148693          	addi	a3,s1,1
    8000554e:	068e                	slli	a3,a3,0x3
    80005550:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005554:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005558:	01897663          	bgeu	s2,s8,80005564 <exec+0x242>
  sz = sz1;
    8000555c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005560:	4481                	li	s1,0
    80005562:	a879                	j	80005600 <exec+0x2de>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005564:	e8840613          	addi	a2,s0,-376
    80005568:	85ca                	mv	a1,s2
    8000556a:	855e                	mv	a0,s7
    8000556c:	ffffc097          	auipc	ra,0xffffc
    80005570:	1d4080e7          	jalr	468(ra) # 80001740 <copyout>
    80005574:	0c054263          	bltz	a0,80005638 <exec+0x316>
  p->trapframe->a1 = sp;
    80005578:	058ab783          	ld	a5,88(s5)
    8000557c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005580:	df843783          	ld	a5,-520(s0)
    80005584:	0007c703          	lbu	a4,0(a5)
    80005588:	cf11                	beqz	a4,800055a4 <exec+0x282>
    8000558a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000558c:	02f00693          	li	a3,47
    80005590:	a029                	j	8000559a <exec+0x278>
  for(last=s=path; *s; s++)
    80005592:	0785                	addi	a5,a5,1
    80005594:	fff7c703          	lbu	a4,-1(a5)
    80005598:	c711                	beqz	a4,800055a4 <exec+0x282>
    if(*s == '/')
    8000559a:	fed71ce3          	bne	a4,a3,80005592 <exec+0x270>
      last = s+1;
    8000559e:	def43c23          	sd	a5,-520(s0)
    800055a2:	bfc5                	j	80005592 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800055a4:	4641                	li	a2,16
    800055a6:	df843583          	ld	a1,-520(s0)
    800055aa:	158a8513          	addi	a0,s5,344
    800055ae:	ffffc097          	auipc	ra,0xffffc
    800055b2:	8fe080e7          	jalr	-1794(ra) # 80000eac <safestrcpy>
  oldpagetable = p->pagetable;
    800055b6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800055ba:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800055be:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055c2:	058ab783          	ld	a5,88(s5)
    800055c6:	e6043703          	ld	a4,-416(s0)
    800055ca:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055cc:	058ab783          	ld	a5,88(s5)
    800055d0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055d4:	85ea                	mv	a1,s10
    800055d6:	ffffd097          	auipc	ra,0xffffd
    800055da:	a86080e7          	jalr	-1402(ra) # 8000205c <proc_freepagetable>
  if (p->pid == 1)
    800055de:	038aa703          	lw	a4,56(s5)
    800055e2:	4785                	li	a5,1
    800055e4:	00f70563          	beq	a4,a5,800055ee <exec+0x2cc>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055e8:	0004851b          	sext.w	a0,s1
    800055ec:	b3f9                	j	800053ba <exec+0x98>
    vmprint(p->pagetable);
    800055ee:	050ab503          	ld	a0,80(s5)
    800055f2:	ffffc097          	auipc	ra,0xffffc
    800055f6:	3c6080e7          	jalr	966(ra) # 800019b8 <vmprint>
    800055fa:	b7fd                	j	800055e8 <exec+0x2c6>
    800055fc:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005600:	e0843583          	ld	a1,-504(s0)
    80005604:	855e                	mv	a0,s7
    80005606:	ffffd097          	auipc	ra,0xffffd
    8000560a:	a56080e7          	jalr	-1450(ra) # 8000205c <proc_freepagetable>
  if(ip){
    8000560e:	d8049ce3          	bnez	s1,800053a6 <exec+0x84>
  return -1;
    80005612:	557d                	li	a0,-1
    80005614:	b35d                	j	800053ba <exec+0x98>
    80005616:	e1243423          	sd	s2,-504(s0)
    8000561a:	b7dd                	j	80005600 <exec+0x2de>
    8000561c:	e1243423          	sd	s2,-504(s0)
    80005620:	b7c5                	j	80005600 <exec+0x2de>
    80005622:	e1243423          	sd	s2,-504(s0)
    80005626:	bfe9                	j	80005600 <exec+0x2de>
  sz = sz1;
    80005628:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000562c:	4481                	li	s1,0
    8000562e:	bfc9                	j	80005600 <exec+0x2de>
  sz = sz1;
    80005630:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005634:	4481                	li	s1,0
    80005636:	b7e9                	j	80005600 <exec+0x2de>
  sz = sz1;
    80005638:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000563c:	4481                	li	s1,0
    8000563e:	b7c9                	j	80005600 <exec+0x2de>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005640:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005644:	2b05                	addiw	s6,s6,1
    80005646:	0389899b          	addiw	s3,s3,56
    8000564a:	e8045783          	lhu	a5,-384(s0)
    8000564e:	e0fb5fe3          	bge	s6,a5,8000546c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005652:	2981                	sext.w	s3,s3
    80005654:	03800713          	li	a4,56
    80005658:	86ce                	mv	a3,s3
    8000565a:	e1040613          	addi	a2,s0,-496
    8000565e:	4581                	li	a1,0
    80005660:	8526                	mv	a0,s1
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	a36080e7          	jalr	-1482(ra) # 80004098 <readi>
    8000566a:	03800793          	li	a5,56
    8000566e:	f8f517e3          	bne	a0,a5,800055fc <exec+0x2da>
    if(ph.type != ELF_PROG_LOAD)
    80005672:	e1042783          	lw	a5,-496(s0)
    80005676:	4705                	li	a4,1
    80005678:	fce796e3          	bne	a5,a4,80005644 <exec+0x322>
    if(ph.memsz < ph.filesz)
    8000567c:	e3843603          	ld	a2,-456(s0)
    80005680:	e3043783          	ld	a5,-464(s0)
    80005684:	f8f669e3          	bltu	a2,a5,80005616 <exec+0x2f4>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005688:	e2043783          	ld	a5,-480(s0)
    8000568c:	963e                	add	a2,a2,a5
    8000568e:	f8f667e3          	bltu	a2,a5,8000561c <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005692:	85ca                	mv	a1,s2
    80005694:	855e                	mv	a0,s7
    80005696:	ffffc097          	auipc	ra,0xffffc
    8000569a:	e5a080e7          	jalr	-422(ra) # 800014f0 <uvmalloc>
    8000569e:	e0a43423          	sd	a0,-504(s0)
    800056a2:	d141                	beqz	a0,80005622 <exec+0x300>
    if(ph.vaddr % PGSIZE != 0)
    800056a4:	e2043d03          	ld	s10,-480(s0)
    800056a8:	df043783          	ld	a5,-528(s0)
    800056ac:	00fd77b3          	and	a5,s10,a5
    800056b0:	fba1                	bnez	a5,80005600 <exec+0x2de>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800056b2:	e1842d83          	lw	s11,-488(s0)
    800056b6:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800056ba:	f80c03e3          	beqz	s8,80005640 <exec+0x31e>
    800056be:	8a62                	mv	s4,s8
    800056c0:	4901                	li	s2,0
    800056c2:	b361                	j	8000544a <exec+0x128>

00000000800056c4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056c4:	7179                	addi	sp,sp,-48
    800056c6:	f406                	sd	ra,40(sp)
    800056c8:	f022                	sd	s0,32(sp)
    800056ca:	ec26                	sd	s1,24(sp)
    800056cc:	e84a                	sd	s2,16(sp)
    800056ce:	1800                	addi	s0,sp,48
    800056d0:	892e                	mv	s2,a1
    800056d2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800056d4:	fdc40593          	addi	a1,s0,-36
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	abe080e7          	jalr	-1346(ra) # 80003196 <argint>
    800056e0:	04054063          	bltz	a0,80005720 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800056e4:	fdc42703          	lw	a4,-36(s0)
    800056e8:	47bd                	li	a5,15
    800056ea:	02e7ed63          	bltu	a5,a4,80005724 <argfd+0x60>
    800056ee:	ffffd097          	auipc	ra,0xffffd
    800056f2:	80e080e7          	jalr	-2034(ra) # 80001efc <myproc>
    800056f6:	fdc42703          	lw	a4,-36(s0)
    800056fa:	01a70793          	addi	a5,a4,26
    800056fe:	078e                	slli	a5,a5,0x3
    80005700:	953e                	add	a0,a0,a5
    80005702:	611c                	ld	a5,0(a0)
    80005704:	c395                	beqz	a5,80005728 <argfd+0x64>
    return -1;
  if(pfd)
    80005706:	00090463          	beqz	s2,8000570e <argfd+0x4a>
    *pfd = fd;
    8000570a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000570e:	4501                	li	a0,0
  if(pf)
    80005710:	c091                	beqz	s1,80005714 <argfd+0x50>
    *pf = f;
    80005712:	e09c                	sd	a5,0(s1)
}
    80005714:	70a2                	ld	ra,40(sp)
    80005716:	7402                	ld	s0,32(sp)
    80005718:	64e2                	ld	s1,24(sp)
    8000571a:	6942                	ld	s2,16(sp)
    8000571c:	6145                	addi	sp,sp,48
    8000571e:	8082                	ret
    return -1;
    80005720:	557d                	li	a0,-1
    80005722:	bfcd                	j	80005714 <argfd+0x50>
    return -1;
    80005724:	557d                	li	a0,-1
    80005726:	b7fd                	j	80005714 <argfd+0x50>
    80005728:	557d                	li	a0,-1
    8000572a:	b7ed                	j	80005714 <argfd+0x50>

000000008000572c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000572c:	1101                	addi	sp,sp,-32
    8000572e:	ec06                	sd	ra,24(sp)
    80005730:	e822                	sd	s0,16(sp)
    80005732:	e426                	sd	s1,8(sp)
    80005734:	1000                	addi	s0,sp,32
    80005736:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005738:	ffffc097          	auipc	ra,0xffffc
    8000573c:	7c4080e7          	jalr	1988(ra) # 80001efc <myproc>
    80005740:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005742:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80b0>
    80005746:	4501                	li	a0,0
    80005748:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000574a:	6398                	ld	a4,0(a5)
    8000574c:	cb19                	beqz	a4,80005762 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000574e:	2505                	addiw	a0,a0,1
    80005750:	07a1                	addi	a5,a5,8
    80005752:	fed51ce3          	bne	a0,a3,8000574a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005756:	557d                	li	a0,-1
}
    80005758:	60e2                	ld	ra,24(sp)
    8000575a:	6442                	ld	s0,16(sp)
    8000575c:	64a2                	ld	s1,8(sp)
    8000575e:	6105                	addi	sp,sp,32
    80005760:	8082                	ret
      p->ofile[fd] = f;
    80005762:	01a50793          	addi	a5,a0,26
    80005766:	078e                	slli	a5,a5,0x3
    80005768:	963e                	add	a2,a2,a5
    8000576a:	e204                	sd	s1,0(a2)
      return fd;
    8000576c:	b7f5                	j	80005758 <fdalloc+0x2c>

000000008000576e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000576e:	715d                	addi	sp,sp,-80
    80005770:	e486                	sd	ra,72(sp)
    80005772:	e0a2                	sd	s0,64(sp)
    80005774:	fc26                	sd	s1,56(sp)
    80005776:	f84a                	sd	s2,48(sp)
    80005778:	f44e                	sd	s3,40(sp)
    8000577a:	f052                	sd	s4,32(sp)
    8000577c:	ec56                	sd	s5,24(sp)
    8000577e:	0880                	addi	s0,sp,80
    80005780:	89ae                	mv	s3,a1
    80005782:	8ab2                	mv	s5,a2
    80005784:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005786:	fb040593          	addi	a1,s0,-80
    8000578a:	fffff097          	auipc	ra,0xfffff
    8000578e:	e28080e7          	jalr	-472(ra) # 800045b2 <nameiparent>
    80005792:	892a                	mv	s2,a0
    80005794:	12050f63          	beqz	a0,800058d2 <create+0x164>
    return 0;

  ilock(dp);
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	64c080e7          	jalr	1612(ra) # 80003de4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800057a0:	4601                	li	a2,0
    800057a2:	fb040593          	addi	a1,s0,-80
    800057a6:	854a                	mv	a0,s2
    800057a8:	fffff097          	auipc	ra,0xfffff
    800057ac:	b1a080e7          	jalr	-1254(ra) # 800042c2 <dirlookup>
    800057b0:	84aa                	mv	s1,a0
    800057b2:	c921                	beqz	a0,80005802 <create+0x94>
    iunlockput(dp);
    800057b4:	854a                	mv	a0,s2
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	890080e7          	jalr	-1904(ra) # 80004046 <iunlockput>
    ilock(ip);
    800057be:	8526                	mv	a0,s1
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	624080e7          	jalr	1572(ra) # 80003de4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057c8:	2981                	sext.w	s3,s3
    800057ca:	4789                	li	a5,2
    800057cc:	02f99463          	bne	s3,a5,800057f4 <create+0x86>
    800057d0:	0444d783          	lhu	a5,68(s1)
    800057d4:	37f9                	addiw	a5,a5,-2
    800057d6:	17c2                	slli	a5,a5,0x30
    800057d8:	93c1                	srli	a5,a5,0x30
    800057da:	4705                	li	a4,1
    800057dc:	00f76c63          	bltu	a4,a5,800057f4 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800057e0:	8526                	mv	a0,s1
    800057e2:	60a6                	ld	ra,72(sp)
    800057e4:	6406                	ld	s0,64(sp)
    800057e6:	74e2                	ld	s1,56(sp)
    800057e8:	7942                	ld	s2,48(sp)
    800057ea:	79a2                	ld	s3,40(sp)
    800057ec:	7a02                	ld	s4,32(sp)
    800057ee:	6ae2                	ld	s5,24(sp)
    800057f0:	6161                	addi	sp,sp,80
    800057f2:	8082                	ret
    iunlockput(ip);
    800057f4:	8526                	mv	a0,s1
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	850080e7          	jalr	-1968(ra) # 80004046 <iunlockput>
    return 0;
    800057fe:	4481                	li	s1,0
    80005800:	b7c5                	j	800057e0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005802:	85ce                	mv	a1,s3
    80005804:	00092503          	lw	a0,0(s2)
    80005808:	ffffe097          	auipc	ra,0xffffe
    8000580c:	444080e7          	jalr	1092(ra) # 80003c4c <ialloc>
    80005810:	84aa                	mv	s1,a0
    80005812:	c529                	beqz	a0,8000585c <create+0xee>
  ilock(ip);
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	5d0080e7          	jalr	1488(ra) # 80003de4 <ilock>
  ip->major = major;
    8000581c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005820:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005824:	4785                	li	a5,1
    80005826:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000582a:	8526                	mv	a0,s1
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	4ee080e7          	jalr	1262(ra) # 80003d1a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005834:	2981                	sext.w	s3,s3
    80005836:	4785                	li	a5,1
    80005838:	02f98a63          	beq	s3,a5,8000586c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000583c:	40d0                	lw	a2,4(s1)
    8000583e:	fb040593          	addi	a1,s0,-80
    80005842:	854a                	mv	a0,s2
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	c8e080e7          	jalr	-882(ra) # 800044d2 <dirlink>
    8000584c:	06054b63          	bltz	a0,800058c2 <create+0x154>
  iunlockput(dp);
    80005850:	854a                	mv	a0,s2
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	7f4080e7          	jalr	2036(ra) # 80004046 <iunlockput>
  return ip;
    8000585a:	b759                	j	800057e0 <create+0x72>
    panic("create: ialloc");
    8000585c:	00003517          	auipc	a0,0x3
    80005860:	11450513          	addi	a0,a0,276 # 80008970 <sysnames+0x2b8>
    80005864:	ffffb097          	auipc	ra,0xffffb
    80005868:	ce4080e7          	jalr	-796(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    8000586c:	04a95783          	lhu	a5,74(s2)
    80005870:	2785                	addiw	a5,a5,1
    80005872:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005876:	854a                	mv	a0,s2
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	4a2080e7          	jalr	1186(ra) # 80003d1a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005880:	40d0                	lw	a2,4(s1)
    80005882:	00003597          	auipc	a1,0x3
    80005886:	0fe58593          	addi	a1,a1,254 # 80008980 <sysnames+0x2c8>
    8000588a:	8526                	mv	a0,s1
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	c46080e7          	jalr	-954(ra) # 800044d2 <dirlink>
    80005894:	00054f63          	bltz	a0,800058b2 <create+0x144>
    80005898:	00492603          	lw	a2,4(s2)
    8000589c:	00003597          	auipc	a1,0x3
    800058a0:	9f458593          	addi	a1,a1,-1548 # 80008290 <digits+0x250>
    800058a4:	8526                	mv	a0,s1
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	c2c080e7          	jalr	-980(ra) # 800044d2 <dirlink>
    800058ae:	f80557e3          	bgez	a0,8000583c <create+0xce>
      panic("create dots");
    800058b2:	00003517          	auipc	a0,0x3
    800058b6:	0d650513          	addi	a0,a0,214 # 80008988 <sysnames+0x2d0>
    800058ba:	ffffb097          	auipc	ra,0xffffb
    800058be:	c8e080e7          	jalr	-882(ra) # 80000548 <panic>
    panic("create: dirlink");
    800058c2:	00003517          	auipc	a0,0x3
    800058c6:	0d650513          	addi	a0,a0,214 # 80008998 <sysnames+0x2e0>
    800058ca:	ffffb097          	auipc	ra,0xffffb
    800058ce:	c7e080e7          	jalr	-898(ra) # 80000548 <panic>
    return 0;
    800058d2:	84aa                	mv	s1,a0
    800058d4:	b731                	j	800057e0 <create+0x72>

00000000800058d6 <sys_dup>:
{
    800058d6:	7179                	addi	sp,sp,-48
    800058d8:	f406                	sd	ra,40(sp)
    800058da:	f022                	sd	s0,32(sp)
    800058dc:	ec26                	sd	s1,24(sp)
    800058de:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058e0:	fd840613          	addi	a2,s0,-40
    800058e4:	4581                	li	a1,0
    800058e6:	4501                	li	a0,0
    800058e8:	00000097          	auipc	ra,0x0
    800058ec:	ddc080e7          	jalr	-548(ra) # 800056c4 <argfd>
    return -1;
    800058f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058f2:	02054363          	bltz	a0,80005918 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800058f6:	fd843503          	ld	a0,-40(s0)
    800058fa:	00000097          	auipc	ra,0x0
    800058fe:	e32080e7          	jalr	-462(ra) # 8000572c <fdalloc>
    80005902:	84aa                	mv	s1,a0
    return -1;
    80005904:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005906:	00054963          	bltz	a0,80005918 <sys_dup+0x42>
  filedup(f);
    8000590a:	fd843503          	ld	a0,-40(s0)
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	312080e7          	jalr	786(ra) # 80004c20 <filedup>
  return fd;
    80005916:	87a6                	mv	a5,s1
}
    80005918:	853e                	mv	a0,a5
    8000591a:	70a2                	ld	ra,40(sp)
    8000591c:	7402                	ld	s0,32(sp)
    8000591e:	64e2                	ld	s1,24(sp)
    80005920:	6145                	addi	sp,sp,48
    80005922:	8082                	ret

0000000080005924 <sys_read>:
{
    80005924:	7179                	addi	sp,sp,-48
    80005926:	f406                	sd	ra,40(sp)
    80005928:	f022                	sd	s0,32(sp)
    8000592a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000592c:	fe840613          	addi	a2,s0,-24
    80005930:	4581                	li	a1,0
    80005932:	4501                	li	a0,0
    80005934:	00000097          	auipc	ra,0x0
    80005938:	d90080e7          	jalr	-624(ra) # 800056c4 <argfd>
    return -1;
    8000593c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000593e:	04054163          	bltz	a0,80005980 <sys_read+0x5c>
    80005942:	fe440593          	addi	a1,s0,-28
    80005946:	4509                	li	a0,2
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	84e080e7          	jalr	-1970(ra) # 80003196 <argint>
    return -1;
    80005950:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005952:	02054763          	bltz	a0,80005980 <sys_read+0x5c>
    80005956:	fd840593          	addi	a1,s0,-40
    8000595a:	4505                	li	a0,1
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	85c080e7          	jalr	-1956(ra) # 800031b8 <argaddr>
    return -1;
    80005964:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005966:	00054d63          	bltz	a0,80005980 <sys_read+0x5c>
  return fileread(f, p, n);
    8000596a:	fe442603          	lw	a2,-28(s0)
    8000596e:	fd843583          	ld	a1,-40(s0)
    80005972:	fe843503          	ld	a0,-24(s0)
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	436080e7          	jalr	1078(ra) # 80004dac <fileread>
    8000597e:	87aa                	mv	a5,a0
}
    80005980:	853e                	mv	a0,a5
    80005982:	70a2                	ld	ra,40(sp)
    80005984:	7402                	ld	s0,32(sp)
    80005986:	6145                	addi	sp,sp,48
    80005988:	8082                	ret

000000008000598a <sys_write>:
{
    8000598a:	7179                	addi	sp,sp,-48
    8000598c:	f406                	sd	ra,40(sp)
    8000598e:	f022                	sd	s0,32(sp)
    80005990:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005992:	fe840613          	addi	a2,s0,-24
    80005996:	4581                	li	a1,0
    80005998:	4501                	li	a0,0
    8000599a:	00000097          	auipc	ra,0x0
    8000599e:	d2a080e7          	jalr	-726(ra) # 800056c4 <argfd>
    return -1;
    800059a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059a4:	04054163          	bltz	a0,800059e6 <sys_write+0x5c>
    800059a8:	fe440593          	addi	a1,s0,-28
    800059ac:	4509                	li	a0,2
    800059ae:	ffffd097          	auipc	ra,0xffffd
    800059b2:	7e8080e7          	jalr	2024(ra) # 80003196 <argint>
    return -1;
    800059b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059b8:	02054763          	bltz	a0,800059e6 <sys_write+0x5c>
    800059bc:	fd840593          	addi	a1,s0,-40
    800059c0:	4505                	li	a0,1
    800059c2:	ffffd097          	auipc	ra,0xffffd
    800059c6:	7f6080e7          	jalr	2038(ra) # 800031b8 <argaddr>
    return -1;
    800059ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059cc:	00054d63          	bltz	a0,800059e6 <sys_write+0x5c>
  return filewrite(f, p, n);
    800059d0:	fe442603          	lw	a2,-28(s0)
    800059d4:	fd843583          	ld	a1,-40(s0)
    800059d8:	fe843503          	ld	a0,-24(s0)
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	492080e7          	jalr	1170(ra) # 80004e6e <filewrite>
    800059e4:	87aa                	mv	a5,a0
}
    800059e6:	853e                	mv	a0,a5
    800059e8:	70a2                	ld	ra,40(sp)
    800059ea:	7402                	ld	s0,32(sp)
    800059ec:	6145                	addi	sp,sp,48
    800059ee:	8082                	ret

00000000800059f0 <sys_close>:
{
    800059f0:	1101                	addi	sp,sp,-32
    800059f2:	ec06                	sd	ra,24(sp)
    800059f4:	e822                	sd	s0,16(sp)
    800059f6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059f8:	fe040613          	addi	a2,s0,-32
    800059fc:	fec40593          	addi	a1,s0,-20
    80005a00:	4501                	li	a0,0
    80005a02:	00000097          	auipc	ra,0x0
    80005a06:	cc2080e7          	jalr	-830(ra) # 800056c4 <argfd>
    return -1;
    80005a0a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a0c:	02054463          	bltz	a0,80005a34 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a10:	ffffc097          	auipc	ra,0xffffc
    80005a14:	4ec080e7          	jalr	1260(ra) # 80001efc <myproc>
    80005a18:	fec42783          	lw	a5,-20(s0)
    80005a1c:	07e9                	addi	a5,a5,26
    80005a1e:	078e                	slli	a5,a5,0x3
    80005a20:	97aa                	add	a5,a5,a0
    80005a22:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005a26:	fe043503          	ld	a0,-32(s0)
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	248080e7          	jalr	584(ra) # 80004c72 <fileclose>
  return 0;
    80005a32:	4781                	li	a5,0
}
    80005a34:	853e                	mv	a0,a5
    80005a36:	60e2                	ld	ra,24(sp)
    80005a38:	6442                	ld	s0,16(sp)
    80005a3a:	6105                	addi	sp,sp,32
    80005a3c:	8082                	ret

0000000080005a3e <sys_fstat>:
{
    80005a3e:	1101                	addi	sp,sp,-32
    80005a40:	ec06                	sd	ra,24(sp)
    80005a42:	e822                	sd	s0,16(sp)
    80005a44:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a46:	fe840613          	addi	a2,s0,-24
    80005a4a:	4581                	li	a1,0
    80005a4c:	4501                	li	a0,0
    80005a4e:	00000097          	auipc	ra,0x0
    80005a52:	c76080e7          	jalr	-906(ra) # 800056c4 <argfd>
    return -1;
    80005a56:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a58:	02054563          	bltz	a0,80005a82 <sys_fstat+0x44>
    80005a5c:	fe040593          	addi	a1,s0,-32
    80005a60:	4505                	li	a0,1
    80005a62:	ffffd097          	auipc	ra,0xffffd
    80005a66:	756080e7          	jalr	1878(ra) # 800031b8 <argaddr>
    return -1;
    80005a6a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a6c:	00054b63          	bltz	a0,80005a82 <sys_fstat+0x44>
  return filestat(f, st);
    80005a70:	fe043583          	ld	a1,-32(s0)
    80005a74:	fe843503          	ld	a0,-24(s0)
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	2c2080e7          	jalr	706(ra) # 80004d3a <filestat>
    80005a80:	87aa                	mv	a5,a0
}
    80005a82:	853e                	mv	a0,a5
    80005a84:	60e2                	ld	ra,24(sp)
    80005a86:	6442                	ld	s0,16(sp)
    80005a88:	6105                	addi	sp,sp,32
    80005a8a:	8082                	ret

0000000080005a8c <sys_link>:
{
    80005a8c:	7169                	addi	sp,sp,-304
    80005a8e:	f606                	sd	ra,296(sp)
    80005a90:	f222                	sd	s0,288(sp)
    80005a92:	ee26                	sd	s1,280(sp)
    80005a94:	ea4a                	sd	s2,272(sp)
    80005a96:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a98:	08000613          	li	a2,128
    80005a9c:	ed040593          	addi	a1,s0,-304
    80005aa0:	4501                	li	a0,0
    80005aa2:	ffffd097          	auipc	ra,0xffffd
    80005aa6:	738080e7          	jalr	1848(ra) # 800031da <argstr>
    return -1;
    80005aaa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005aac:	10054e63          	bltz	a0,80005bc8 <sys_link+0x13c>
    80005ab0:	08000613          	li	a2,128
    80005ab4:	f5040593          	addi	a1,s0,-176
    80005ab8:	4505                	li	a0,1
    80005aba:	ffffd097          	auipc	ra,0xffffd
    80005abe:	720080e7          	jalr	1824(ra) # 800031da <argstr>
    return -1;
    80005ac2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ac4:	10054263          	bltz	a0,80005bc8 <sys_link+0x13c>
  begin_op();
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	cd8080e7          	jalr	-808(ra) # 800047a0 <begin_op>
  if((ip = namei(old)) == 0){
    80005ad0:	ed040513          	addi	a0,s0,-304
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	ac0080e7          	jalr	-1344(ra) # 80004594 <namei>
    80005adc:	84aa                	mv	s1,a0
    80005ade:	c551                	beqz	a0,80005b6a <sys_link+0xde>
  ilock(ip);
    80005ae0:	ffffe097          	auipc	ra,0xffffe
    80005ae4:	304080e7          	jalr	772(ra) # 80003de4 <ilock>
  if(ip->type == T_DIR){
    80005ae8:	04449703          	lh	a4,68(s1)
    80005aec:	4785                	li	a5,1
    80005aee:	08f70463          	beq	a4,a5,80005b76 <sys_link+0xea>
  ip->nlink++;
    80005af2:	04a4d783          	lhu	a5,74(s1)
    80005af6:	2785                	addiw	a5,a5,1
    80005af8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005afc:	8526                	mv	a0,s1
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	21c080e7          	jalr	540(ra) # 80003d1a <iupdate>
  iunlock(ip);
    80005b06:	8526                	mv	a0,s1
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	39e080e7          	jalr	926(ra) # 80003ea6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b10:	fd040593          	addi	a1,s0,-48
    80005b14:	f5040513          	addi	a0,s0,-176
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	a9a080e7          	jalr	-1382(ra) # 800045b2 <nameiparent>
    80005b20:	892a                	mv	s2,a0
    80005b22:	c935                	beqz	a0,80005b96 <sys_link+0x10a>
  ilock(dp);
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	2c0080e7          	jalr	704(ra) # 80003de4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b2c:	00092703          	lw	a4,0(s2)
    80005b30:	409c                	lw	a5,0(s1)
    80005b32:	04f71d63          	bne	a4,a5,80005b8c <sys_link+0x100>
    80005b36:	40d0                	lw	a2,4(s1)
    80005b38:	fd040593          	addi	a1,s0,-48
    80005b3c:	854a                	mv	a0,s2
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	994080e7          	jalr	-1644(ra) # 800044d2 <dirlink>
    80005b46:	04054363          	bltz	a0,80005b8c <sys_link+0x100>
  iunlockput(dp);
    80005b4a:	854a                	mv	a0,s2
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	4fa080e7          	jalr	1274(ra) # 80004046 <iunlockput>
  iput(ip);
    80005b54:	8526                	mv	a0,s1
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	448080e7          	jalr	1096(ra) # 80003f9e <iput>
  end_op();
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	cc2080e7          	jalr	-830(ra) # 80004820 <end_op>
  return 0;
    80005b66:	4781                	li	a5,0
    80005b68:	a085                	j	80005bc8 <sys_link+0x13c>
    end_op();
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	cb6080e7          	jalr	-842(ra) # 80004820 <end_op>
    return -1;
    80005b72:	57fd                	li	a5,-1
    80005b74:	a891                	j	80005bc8 <sys_link+0x13c>
    iunlockput(ip);
    80005b76:	8526                	mv	a0,s1
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	4ce080e7          	jalr	1230(ra) # 80004046 <iunlockput>
    end_op();
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	ca0080e7          	jalr	-864(ra) # 80004820 <end_op>
    return -1;
    80005b88:	57fd                	li	a5,-1
    80005b8a:	a83d                	j	80005bc8 <sys_link+0x13c>
    iunlockput(dp);
    80005b8c:	854a                	mv	a0,s2
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	4b8080e7          	jalr	1208(ra) # 80004046 <iunlockput>
  ilock(ip);
    80005b96:	8526                	mv	a0,s1
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	24c080e7          	jalr	588(ra) # 80003de4 <ilock>
  ip->nlink--;
    80005ba0:	04a4d783          	lhu	a5,74(s1)
    80005ba4:	37fd                	addiw	a5,a5,-1
    80005ba6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005baa:	8526                	mv	a0,s1
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	16e080e7          	jalr	366(ra) # 80003d1a <iupdate>
  iunlockput(ip);
    80005bb4:	8526                	mv	a0,s1
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	490080e7          	jalr	1168(ra) # 80004046 <iunlockput>
  end_op();
    80005bbe:	fffff097          	auipc	ra,0xfffff
    80005bc2:	c62080e7          	jalr	-926(ra) # 80004820 <end_op>
  return -1;
    80005bc6:	57fd                	li	a5,-1
}
    80005bc8:	853e                	mv	a0,a5
    80005bca:	70b2                	ld	ra,296(sp)
    80005bcc:	7412                	ld	s0,288(sp)
    80005bce:	64f2                	ld	s1,280(sp)
    80005bd0:	6952                	ld	s2,272(sp)
    80005bd2:	6155                	addi	sp,sp,304
    80005bd4:	8082                	ret

0000000080005bd6 <sys_unlink>:
{
    80005bd6:	7151                	addi	sp,sp,-240
    80005bd8:	f586                	sd	ra,232(sp)
    80005bda:	f1a2                	sd	s0,224(sp)
    80005bdc:	eda6                	sd	s1,216(sp)
    80005bde:	e9ca                	sd	s2,208(sp)
    80005be0:	e5ce                	sd	s3,200(sp)
    80005be2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005be4:	08000613          	li	a2,128
    80005be8:	f3040593          	addi	a1,s0,-208
    80005bec:	4501                	li	a0,0
    80005bee:	ffffd097          	auipc	ra,0xffffd
    80005bf2:	5ec080e7          	jalr	1516(ra) # 800031da <argstr>
    80005bf6:	18054163          	bltz	a0,80005d78 <sys_unlink+0x1a2>
  begin_op();
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	ba6080e7          	jalr	-1114(ra) # 800047a0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c02:	fb040593          	addi	a1,s0,-80
    80005c06:	f3040513          	addi	a0,s0,-208
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	9a8080e7          	jalr	-1624(ra) # 800045b2 <nameiparent>
    80005c12:	84aa                	mv	s1,a0
    80005c14:	c979                	beqz	a0,80005cea <sys_unlink+0x114>
  ilock(dp);
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	1ce080e7          	jalr	462(ra) # 80003de4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c1e:	00003597          	auipc	a1,0x3
    80005c22:	d6258593          	addi	a1,a1,-670 # 80008980 <sysnames+0x2c8>
    80005c26:	fb040513          	addi	a0,s0,-80
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	67e080e7          	jalr	1662(ra) # 800042a8 <namecmp>
    80005c32:	14050a63          	beqz	a0,80005d86 <sys_unlink+0x1b0>
    80005c36:	00002597          	auipc	a1,0x2
    80005c3a:	65a58593          	addi	a1,a1,1626 # 80008290 <digits+0x250>
    80005c3e:	fb040513          	addi	a0,s0,-80
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	666080e7          	jalr	1638(ra) # 800042a8 <namecmp>
    80005c4a:	12050e63          	beqz	a0,80005d86 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c4e:	f2c40613          	addi	a2,s0,-212
    80005c52:	fb040593          	addi	a1,s0,-80
    80005c56:	8526                	mv	a0,s1
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	66a080e7          	jalr	1642(ra) # 800042c2 <dirlookup>
    80005c60:	892a                	mv	s2,a0
    80005c62:	12050263          	beqz	a0,80005d86 <sys_unlink+0x1b0>
  ilock(ip);
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	17e080e7          	jalr	382(ra) # 80003de4 <ilock>
  if(ip->nlink < 1)
    80005c6e:	04a91783          	lh	a5,74(s2)
    80005c72:	08f05263          	blez	a5,80005cf6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c76:	04491703          	lh	a4,68(s2)
    80005c7a:	4785                	li	a5,1
    80005c7c:	08f70563          	beq	a4,a5,80005d06 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c80:	4641                	li	a2,16
    80005c82:	4581                	li	a1,0
    80005c84:	fc040513          	addi	a0,s0,-64
    80005c88:	ffffb097          	auipc	ra,0xffffb
    80005c8c:	0ce080e7          	jalr	206(ra) # 80000d56 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c90:	4741                	li	a4,16
    80005c92:	f2c42683          	lw	a3,-212(s0)
    80005c96:	fc040613          	addi	a2,s0,-64
    80005c9a:	4581                	li	a1,0
    80005c9c:	8526                	mv	a0,s1
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	4f0080e7          	jalr	1264(ra) # 8000418e <writei>
    80005ca6:	47c1                	li	a5,16
    80005ca8:	0af51563          	bne	a0,a5,80005d52 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005cac:	04491703          	lh	a4,68(s2)
    80005cb0:	4785                	li	a5,1
    80005cb2:	0af70863          	beq	a4,a5,80005d62 <sys_unlink+0x18c>
  iunlockput(dp);
    80005cb6:	8526                	mv	a0,s1
    80005cb8:	ffffe097          	auipc	ra,0xffffe
    80005cbc:	38e080e7          	jalr	910(ra) # 80004046 <iunlockput>
  ip->nlink--;
    80005cc0:	04a95783          	lhu	a5,74(s2)
    80005cc4:	37fd                	addiw	a5,a5,-1
    80005cc6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005cca:	854a                	mv	a0,s2
    80005ccc:	ffffe097          	auipc	ra,0xffffe
    80005cd0:	04e080e7          	jalr	78(ra) # 80003d1a <iupdate>
  iunlockput(ip);
    80005cd4:	854a                	mv	a0,s2
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	370080e7          	jalr	880(ra) # 80004046 <iunlockput>
  end_op();
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	b42080e7          	jalr	-1214(ra) # 80004820 <end_op>
  return 0;
    80005ce6:	4501                	li	a0,0
    80005ce8:	a84d                	j	80005d9a <sys_unlink+0x1c4>
    end_op();
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	b36080e7          	jalr	-1226(ra) # 80004820 <end_op>
    return -1;
    80005cf2:	557d                	li	a0,-1
    80005cf4:	a05d                	j	80005d9a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005cf6:	00003517          	auipc	a0,0x3
    80005cfa:	cb250513          	addi	a0,a0,-846 # 800089a8 <sysnames+0x2f0>
    80005cfe:	ffffb097          	auipc	ra,0xffffb
    80005d02:	84a080e7          	jalr	-1974(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d06:	04c92703          	lw	a4,76(s2)
    80005d0a:	02000793          	li	a5,32
    80005d0e:	f6e7f9e3          	bgeu	a5,a4,80005c80 <sys_unlink+0xaa>
    80005d12:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d16:	4741                	li	a4,16
    80005d18:	86ce                	mv	a3,s3
    80005d1a:	f1840613          	addi	a2,s0,-232
    80005d1e:	4581                	li	a1,0
    80005d20:	854a                	mv	a0,s2
    80005d22:	ffffe097          	auipc	ra,0xffffe
    80005d26:	376080e7          	jalr	886(ra) # 80004098 <readi>
    80005d2a:	47c1                	li	a5,16
    80005d2c:	00f51b63          	bne	a0,a5,80005d42 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d30:	f1845783          	lhu	a5,-232(s0)
    80005d34:	e7a1                	bnez	a5,80005d7c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d36:	29c1                	addiw	s3,s3,16
    80005d38:	04c92783          	lw	a5,76(s2)
    80005d3c:	fcf9ede3          	bltu	s3,a5,80005d16 <sys_unlink+0x140>
    80005d40:	b781                	j	80005c80 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d42:	00003517          	auipc	a0,0x3
    80005d46:	c7e50513          	addi	a0,a0,-898 # 800089c0 <sysnames+0x308>
    80005d4a:	ffffa097          	auipc	ra,0xffffa
    80005d4e:	7fe080e7          	jalr	2046(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005d52:	00003517          	auipc	a0,0x3
    80005d56:	c8650513          	addi	a0,a0,-890 # 800089d8 <sysnames+0x320>
    80005d5a:	ffffa097          	auipc	ra,0xffffa
    80005d5e:	7ee080e7          	jalr	2030(ra) # 80000548 <panic>
    dp->nlink--;
    80005d62:	04a4d783          	lhu	a5,74(s1)
    80005d66:	37fd                	addiw	a5,a5,-1
    80005d68:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d6c:	8526                	mv	a0,s1
    80005d6e:	ffffe097          	auipc	ra,0xffffe
    80005d72:	fac080e7          	jalr	-84(ra) # 80003d1a <iupdate>
    80005d76:	b781                	j	80005cb6 <sys_unlink+0xe0>
    return -1;
    80005d78:	557d                	li	a0,-1
    80005d7a:	a005                	j	80005d9a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d7c:	854a                	mv	a0,s2
    80005d7e:	ffffe097          	auipc	ra,0xffffe
    80005d82:	2c8080e7          	jalr	712(ra) # 80004046 <iunlockput>
  iunlockput(dp);
    80005d86:	8526                	mv	a0,s1
    80005d88:	ffffe097          	auipc	ra,0xffffe
    80005d8c:	2be080e7          	jalr	702(ra) # 80004046 <iunlockput>
  end_op();
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	a90080e7          	jalr	-1392(ra) # 80004820 <end_op>
  return -1;
    80005d98:	557d                	li	a0,-1
}
    80005d9a:	70ae                	ld	ra,232(sp)
    80005d9c:	740e                	ld	s0,224(sp)
    80005d9e:	64ee                	ld	s1,216(sp)
    80005da0:	694e                	ld	s2,208(sp)
    80005da2:	69ae                	ld	s3,200(sp)
    80005da4:	616d                	addi	sp,sp,240
    80005da6:	8082                	ret

0000000080005da8 <sys_open>:

uint64
sys_open(void)
{
    80005da8:	7131                	addi	sp,sp,-192
    80005daa:	fd06                	sd	ra,184(sp)
    80005dac:	f922                	sd	s0,176(sp)
    80005dae:	f526                	sd	s1,168(sp)
    80005db0:	f14a                	sd	s2,160(sp)
    80005db2:	ed4e                	sd	s3,152(sp)
    80005db4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005db6:	08000613          	li	a2,128
    80005dba:	f5040593          	addi	a1,s0,-176
    80005dbe:	4501                	li	a0,0
    80005dc0:	ffffd097          	auipc	ra,0xffffd
    80005dc4:	41a080e7          	jalr	1050(ra) # 800031da <argstr>
    return -1;
    80005dc8:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005dca:	0c054163          	bltz	a0,80005e8c <sys_open+0xe4>
    80005dce:	f4c40593          	addi	a1,s0,-180
    80005dd2:	4505                	li	a0,1
    80005dd4:	ffffd097          	auipc	ra,0xffffd
    80005dd8:	3c2080e7          	jalr	962(ra) # 80003196 <argint>
    80005ddc:	0a054863          	bltz	a0,80005e8c <sys_open+0xe4>

  begin_op();
    80005de0:	fffff097          	auipc	ra,0xfffff
    80005de4:	9c0080e7          	jalr	-1600(ra) # 800047a0 <begin_op>

  if(omode & O_CREATE){
    80005de8:	f4c42783          	lw	a5,-180(s0)
    80005dec:	2007f793          	andi	a5,a5,512
    80005df0:	cbdd                	beqz	a5,80005ea6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005df2:	4681                	li	a3,0
    80005df4:	4601                	li	a2,0
    80005df6:	4589                	li	a1,2
    80005df8:	f5040513          	addi	a0,s0,-176
    80005dfc:	00000097          	auipc	ra,0x0
    80005e00:	972080e7          	jalr	-1678(ra) # 8000576e <create>
    80005e04:	892a                	mv	s2,a0
    if(ip == 0){
    80005e06:	c959                	beqz	a0,80005e9c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e08:	04491703          	lh	a4,68(s2)
    80005e0c:	478d                	li	a5,3
    80005e0e:	00f71763          	bne	a4,a5,80005e1c <sys_open+0x74>
    80005e12:	04695703          	lhu	a4,70(s2)
    80005e16:	47a5                	li	a5,9
    80005e18:	0ce7ec63          	bltu	a5,a4,80005ef0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	d9a080e7          	jalr	-614(ra) # 80004bb6 <filealloc>
    80005e24:	89aa                	mv	s3,a0
    80005e26:	10050263          	beqz	a0,80005f2a <sys_open+0x182>
    80005e2a:	00000097          	auipc	ra,0x0
    80005e2e:	902080e7          	jalr	-1790(ra) # 8000572c <fdalloc>
    80005e32:	84aa                	mv	s1,a0
    80005e34:	0e054663          	bltz	a0,80005f20 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e38:	04491703          	lh	a4,68(s2)
    80005e3c:	478d                	li	a5,3
    80005e3e:	0cf70463          	beq	a4,a5,80005f06 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e42:	4789                	li	a5,2
    80005e44:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e48:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e4c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e50:	f4c42783          	lw	a5,-180(s0)
    80005e54:	0017c713          	xori	a4,a5,1
    80005e58:	8b05                	andi	a4,a4,1
    80005e5a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e5e:	0037f713          	andi	a4,a5,3
    80005e62:	00e03733          	snez	a4,a4
    80005e66:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e6a:	4007f793          	andi	a5,a5,1024
    80005e6e:	c791                	beqz	a5,80005e7a <sys_open+0xd2>
    80005e70:	04491703          	lh	a4,68(s2)
    80005e74:	4789                	li	a5,2
    80005e76:	08f70f63          	beq	a4,a5,80005f14 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e7a:	854a                	mv	a0,s2
    80005e7c:	ffffe097          	auipc	ra,0xffffe
    80005e80:	02a080e7          	jalr	42(ra) # 80003ea6 <iunlock>
  end_op();
    80005e84:	fffff097          	auipc	ra,0xfffff
    80005e88:	99c080e7          	jalr	-1636(ra) # 80004820 <end_op>

  return fd;
}
    80005e8c:	8526                	mv	a0,s1
    80005e8e:	70ea                	ld	ra,184(sp)
    80005e90:	744a                	ld	s0,176(sp)
    80005e92:	74aa                	ld	s1,168(sp)
    80005e94:	790a                	ld	s2,160(sp)
    80005e96:	69ea                	ld	s3,152(sp)
    80005e98:	6129                	addi	sp,sp,192
    80005e9a:	8082                	ret
      end_op();
    80005e9c:	fffff097          	auipc	ra,0xfffff
    80005ea0:	984080e7          	jalr	-1660(ra) # 80004820 <end_op>
      return -1;
    80005ea4:	b7e5                	j	80005e8c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ea6:	f5040513          	addi	a0,s0,-176
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	6ea080e7          	jalr	1770(ra) # 80004594 <namei>
    80005eb2:	892a                	mv	s2,a0
    80005eb4:	c905                	beqz	a0,80005ee4 <sys_open+0x13c>
    ilock(ip);
    80005eb6:	ffffe097          	auipc	ra,0xffffe
    80005eba:	f2e080e7          	jalr	-210(ra) # 80003de4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ebe:	04491703          	lh	a4,68(s2)
    80005ec2:	4785                	li	a5,1
    80005ec4:	f4f712e3          	bne	a4,a5,80005e08 <sys_open+0x60>
    80005ec8:	f4c42783          	lw	a5,-180(s0)
    80005ecc:	dba1                	beqz	a5,80005e1c <sys_open+0x74>
      iunlockput(ip);
    80005ece:	854a                	mv	a0,s2
    80005ed0:	ffffe097          	auipc	ra,0xffffe
    80005ed4:	176080e7          	jalr	374(ra) # 80004046 <iunlockput>
      end_op();
    80005ed8:	fffff097          	auipc	ra,0xfffff
    80005edc:	948080e7          	jalr	-1720(ra) # 80004820 <end_op>
      return -1;
    80005ee0:	54fd                	li	s1,-1
    80005ee2:	b76d                	j	80005e8c <sys_open+0xe4>
      end_op();
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	93c080e7          	jalr	-1732(ra) # 80004820 <end_op>
      return -1;
    80005eec:	54fd                	li	s1,-1
    80005eee:	bf79                	j	80005e8c <sys_open+0xe4>
    iunlockput(ip);
    80005ef0:	854a                	mv	a0,s2
    80005ef2:	ffffe097          	auipc	ra,0xffffe
    80005ef6:	154080e7          	jalr	340(ra) # 80004046 <iunlockput>
    end_op();
    80005efa:	fffff097          	auipc	ra,0xfffff
    80005efe:	926080e7          	jalr	-1754(ra) # 80004820 <end_op>
    return -1;
    80005f02:	54fd                	li	s1,-1
    80005f04:	b761                	j	80005e8c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f06:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f0a:	04691783          	lh	a5,70(s2)
    80005f0e:	02f99223          	sh	a5,36(s3)
    80005f12:	bf2d                	j	80005e4c <sys_open+0xa4>
    itrunc(ip);
    80005f14:	854a                	mv	a0,s2
    80005f16:	ffffe097          	auipc	ra,0xffffe
    80005f1a:	fdc080e7          	jalr	-36(ra) # 80003ef2 <itrunc>
    80005f1e:	bfb1                	j	80005e7a <sys_open+0xd2>
      fileclose(f);
    80005f20:	854e                	mv	a0,s3
    80005f22:	fffff097          	auipc	ra,0xfffff
    80005f26:	d50080e7          	jalr	-688(ra) # 80004c72 <fileclose>
    iunlockput(ip);
    80005f2a:	854a                	mv	a0,s2
    80005f2c:	ffffe097          	auipc	ra,0xffffe
    80005f30:	11a080e7          	jalr	282(ra) # 80004046 <iunlockput>
    end_op();
    80005f34:	fffff097          	auipc	ra,0xfffff
    80005f38:	8ec080e7          	jalr	-1812(ra) # 80004820 <end_op>
    return -1;
    80005f3c:	54fd                	li	s1,-1
    80005f3e:	b7b9                	j	80005e8c <sys_open+0xe4>

0000000080005f40 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f40:	7175                	addi	sp,sp,-144
    80005f42:	e506                	sd	ra,136(sp)
    80005f44:	e122                	sd	s0,128(sp)
    80005f46:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f48:	fffff097          	auipc	ra,0xfffff
    80005f4c:	858080e7          	jalr	-1960(ra) # 800047a0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f50:	08000613          	li	a2,128
    80005f54:	f7040593          	addi	a1,s0,-144
    80005f58:	4501                	li	a0,0
    80005f5a:	ffffd097          	auipc	ra,0xffffd
    80005f5e:	280080e7          	jalr	640(ra) # 800031da <argstr>
    80005f62:	02054963          	bltz	a0,80005f94 <sys_mkdir+0x54>
    80005f66:	4681                	li	a3,0
    80005f68:	4601                	li	a2,0
    80005f6a:	4585                	li	a1,1
    80005f6c:	f7040513          	addi	a0,s0,-144
    80005f70:	fffff097          	auipc	ra,0xfffff
    80005f74:	7fe080e7          	jalr	2046(ra) # 8000576e <create>
    80005f78:	cd11                	beqz	a0,80005f94 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f7a:	ffffe097          	auipc	ra,0xffffe
    80005f7e:	0cc080e7          	jalr	204(ra) # 80004046 <iunlockput>
  end_op();
    80005f82:	fffff097          	auipc	ra,0xfffff
    80005f86:	89e080e7          	jalr	-1890(ra) # 80004820 <end_op>
  return 0;
    80005f8a:	4501                	li	a0,0
}
    80005f8c:	60aa                	ld	ra,136(sp)
    80005f8e:	640a                	ld	s0,128(sp)
    80005f90:	6149                	addi	sp,sp,144
    80005f92:	8082                	ret
    end_op();
    80005f94:	fffff097          	auipc	ra,0xfffff
    80005f98:	88c080e7          	jalr	-1908(ra) # 80004820 <end_op>
    return -1;
    80005f9c:	557d                	li	a0,-1
    80005f9e:	b7fd                	j	80005f8c <sys_mkdir+0x4c>

0000000080005fa0 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005fa0:	7135                	addi	sp,sp,-160
    80005fa2:	ed06                	sd	ra,152(sp)
    80005fa4:	e922                	sd	s0,144(sp)
    80005fa6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005fa8:	ffffe097          	auipc	ra,0xffffe
    80005fac:	7f8080e7          	jalr	2040(ra) # 800047a0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fb0:	08000613          	li	a2,128
    80005fb4:	f7040593          	addi	a1,s0,-144
    80005fb8:	4501                	li	a0,0
    80005fba:	ffffd097          	auipc	ra,0xffffd
    80005fbe:	220080e7          	jalr	544(ra) # 800031da <argstr>
    80005fc2:	04054a63          	bltz	a0,80006016 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005fc6:	f6c40593          	addi	a1,s0,-148
    80005fca:	4505                	li	a0,1
    80005fcc:	ffffd097          	auipc	ra,0xffffd
    80005fd0:	1ca080e7          	jalr	458(ra) # 80003196 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fd4:	04054163          	bltz	a0,80006016 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005fd8:	f6840593          	addi	a1,s0,-152
    80005fdc:	4509                	li	a0,2
    80005fde:	ffffd097          	auipc	ra,0xffffd
    80005fe2:	1b8080e7          	jalr	440(ra) # 80003196 <argint>
     argint(1, &major) < 0 ||
    80005fe6:	02054863          	bltz	a0,80006016 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005fea:	f6841683          	lh	a3,-152(s0)
    80005fee:	f6c41603          	lh	a2,-148(s0)
    80005ff2:	458d                	li	a1,3
    80005ff4:	f7040513          	addi	a0,s0,-144
    80005ff8:	fffff097          	auipc	ra,0xfffff
    80005ffc:	776080e7          	jalr	1910(ra) # 8000576e <create>
     argint(2, &minor) < 0 ||
    80006000:	c919                	beqz	a0,80006016 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006002:	ffffe097          	auipc	ra,0xffffe
    80006006:	044080e7          	jalr	68(ra) # 80004046 <iunlockput>
  end_op();
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	816080e7          	jalr	-2026(ra) # 80004820 <end_op>
  return 0;
    80006012:	4501                	li	a0,0
    80006014:	a031                	j	80006020 <sys_mknod+0x80>
    end_op();
    80006016:	fffff097          	auipc	ra,0xfffff
    8000601a:	80a080e7          	jalr	-2038(ra) # 80004820 <end_op>
    return -1;
    8000601e:	557d                	li	a0,-1
}
    80006020:	60ea                	ld	ra,152(sp)
    80006022:	644a                	ld	s0,144(sp)
    80006024:	610d                	addi	sp,sp,160
    80006026:	8082                	ret

0000000080006028 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006028:	7135                	addi	sp,sp,-160
    8000602a:	ed06                	sd	ra,152(sp)
    8000602c:	e922                	sd	s0,144(sp)
    8000602e:	e526                	sd	s1,136(sp)
    80006030:	e14a                	sd	s2,128(sp)
    80006032:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006034:	ffffc097          	auipc	ra,0xffffc
    80006038:	ec8080e7          	jalr	-312(ra) # 80001efc <myproc>
    8000603c:	892a                	mv	s2,a0
  
  begin_op();
    8000603e:	ffffe097          	auipc	ra,0xffffe
    80006042:	762080e7          	jalr	1890(ra) # 800047a0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006046:	08000613          	li	a2,128
    8000604a:	f6040593          	addi	a1,s0,-160
    8000604e:	4501                	li	a0,0
    80006050:	ffffd097          	auipc	ra,0xffffd
    80006054:	18a080e7          	jalr	394(ra) # 800031da <argstr>
    80006058:	04054b63          	bltz	a0,800060ae <sys_chdir+0x86>
    8000605c:	f6040513          	addi	a0,s0,-160
    80006060:	ffffe097          	auipc	ra,0xffffe
    80006064:	534080e7          	jalr	1332(ra) # 80004594 <namei>
    80006068:	84aa                	mv	s1,a0
    8000606a:	c131                	beqz	a0,800060ae <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000606c:	ffffe097          	auipc	ra,0xffffe
    80006070:	d78080e7          	jalr	-648(ra) # 80003de4 <ilock>
  if(ip->type != T_DIR){
    80006074:	04449703          	lh	a4,68(s1)
    80006078:	4785                	li	a5,1
    8000607a:	04f71063          	bne	a4,a5,800060ba <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000607e:	8526                	mv	a0,s1
    80006080:	ffffe097          	auipc	ra,0xffffe
    80006084:	e26080e7          	jalr	-474(ra) # 80003ea6 <iunlock>
  iput(p->cwd);
    80006088:	15093503          	ld	a0,336(s2)
    8000608c:	ffffe097          	auipc	ra,0xffffe
    80006090:	f12080e7          	jalr	-238(ra) # 80003f9e <iput>
  end_op();
    80006094:	ffffe097          	auipc	ra,0xffffe
    80006098:	78c080e7          	jalr	1932(ra) # 80004820 <end_op>
  p->cwd = ip;
    8000609c:	14993823          	sd	s1,336(s2)
  return 0;
    800060a0:	4501                	li	a0,0
}
    800060a2:	60ea                	ld	ra,152(sp)
    800060a4:	644a                	ld	s0,144(sp)
    800060a6:	64aa                	ld	s1,136(sp)
    800060a8:	690a                	ld	s2,128(sp)
    800060aa:	610d                	addi	sp,sp,160
    800060ac:	8082                	ret
    end_op();
    800060ae:	ffffe097          	auipc	ra,0xffffe
    800060b2:	772080e7          	jalr	1906(ra) # 80004820 <end_op>
    return -1;
    800060b6:	557d                	li	a0,-1
    800060b8:	b7ed                	j	800060a2 <sys_chdir+0x7a>
    iunlockput(ip);
    800060ba:	8526                	mv	a0,s1
    800060bc:	ffffe097          	auipc	ra,0xffffe
    800060c0:	f8a080e7          	jalr	-118(ra) # 80004046 <iunlockput>
    end_op();
    800060c4:	ffffe097          	auipc	ra,0xffffe
    800060c8:	75c080e7          	jalr	1884(ra) # 80004820 <end_op>
    return -1;
    800060cc:	557d                	li	a0,-1
    800060ce:	bfd1                	j	800060a2 <sys_chdir+0x7a>

00000000800060d0 <sys_exec>:

uint64
sys_exec(void)
{
    800060d0:	7145                	addi	sp,sp,-464
    800060d2:	e786                	sd	ra,456(sp)
    800060d4:	e3a2                	sd	s0,448(sp)
    800060d6:	ff26                	sd	s1,440(sp)
    800060d8:	fb4a                	sd	s2,432(sp)
    800060da:	f74e                	sd	s3,424(sp)
    800060dc:	f352                	sd	s4,416(sp)
    800060de:	ef56                	sd	s5,408(sp)
    800060e0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060e2:	08000613          	li	a2,128
    800060e6:	f4040593          	addi	a1,s0,-192
    800060ea:	4501                	li	a0,0
    800060ec:	ffffd097          	auipc	ra,0xffffd
    800060f0:	0ee080e7          	jalr	238(ra) # 800031da <argstr>
    return -1;
    800060f4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060f6:	0c054a63          	bltz	a0,800061ca <sys_exec+0xfa>
    800060fa:	e3840593          	addi	a1,s0,-456
    800060fe:	4505                	li	a0,1
    80006100:	ffffd097          	auipc	ra,0xffffd
    80006104:	0b8080e7          	jalr	184(ra) # 800031b8 <argaddr>
    80006108:	0c054163          	bltz	a0,800061ca <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000610c:	10000613          	li	a2,256
    80006110:	4581                	li	a1,0
    80006112:	e4040513          	addi	a0,s0,-448
    80006116:	ffffb097          	auipc	ra,0xffffb
    8000611a:	c40080e7          	jalr	-960(ra) # 80000d56 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000611e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006122:	89a6                	mv	s3,s1
    80006124:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006126:	02000a13          	li	s4,32
    8000612a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000612e:	00391513          	slli	a0,s2,0x3
    80006132:	e3040593          	addi	a1,s0,-464
    80006136:	e3843783          	ld	a5,-456(s0)
    8000613a:	953e                	add	a0,a0,a5
    8000613c:	ffffd097          	auipc	ra,0xffffd
    80006140:	fc0080e7          	jalr	-64(ra) # 800030fc <fetchaddr>
    80006144:	02054a63          	bltz	a0,80006178 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006148:	e3043783          	ld	a5,-464(s0)
    8000614c:	c3b9                	beqz	a5,80006192 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000614e:	ffffb097          	auipc	ra,0xffffb
    80006152:	9d2080e7          	jalr	-1582(ra) # 80000b20 <kalloc>
    80006156:	85aa                	mv	a1,a0
    80006158:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000615c:	cd11                	beqz	a0,80006178 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000615e:	6605                	lui	a2,0x1
    80006160:	e3043503          	ld	a0,-464(s0)
    80006164:	ffffd097          	auipc	ra,0xffffd
    80006168:	fea080e7          	jalr	-22(ra) # 8000314e <fetchstr>
    8000616c:	00054663          	bltz	a0,80006178 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006170:	0905                	addi	s2,s2,1
    80006172:	09a1                	addi	s3,s3,8
    80006174:	fb491be3          	bne	s2,s4,8000612a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006178:	10048913          	addi	s2,s1,256
    8000617c:	6088                	ld	a0,0(s1)
    8000617e:	c529                	beqz	a0,800061c8 <sys_exec+0xf8>
    kfree(argv[i]);
    80006180:	ffffb097          	auipc	ra,0xffffb
    80006184:	8a4080e7          	jalr	-1884(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006188:	04a1                	addi	s1,s1,8
    8000618a:	ff2499e3          	bne	s1,s2,8000617c <sys_exec+0xac>
  return -1;
    8000618e:	597d                	li	s2,-1
    80006190:	a82d                	j	800061ca <sys_exec+0xfa>
      argv[i] = 0;
    80006192:	0a8e                	slli	s5,s5,0x3
    80006194:	fc040793          	addi	a5,s0,-64
    80006198:	9abe                	add	s5,s5,a5
    8000619a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000619e:	e4040593          	addi	a1,s0,-448
    800061a2:	f4040513          	addi	a0,s0,-192
    800061a6:	fffff097          	auipc	ra,0xfffff
    800061aa:	17c080e7          	jalr	380(ra) # 80005322 <exec>
    800061ae:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061b0:	10048993          	addi	s3,s1,256
    800061b4:	6088                	ld	a0,0(s1)
    800061b6:	c911                	beqz	a0,800061ca <sys_exec+0xfa>
    kfree(argv[i]);
    800061b8:	ffffb097          	auipc	ra,0xffffb
    800061bc:	86c080e7          	jalr	-1940(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061c0:	04a1                	addi	s1,s1,8
    800061c2:	ff3499e3          	bne	s1,s3,800061b4 <sys_exec+0xe4>
    800061c6:	a011                	j	800061ca <sys_exec+0xfa>
  return -1;
    800061c8:	597d                	li	s2,-1
}
    800061ca:	854a                	mv	a0,s2
    800061cc:	60be                	ld	ra,456(sp)
    800061ce:	641e                	ld	s0,448(sp)
    800061d0:	74fa                	ld	s1,440(sp)
    800061d2:	795a                	ld	s2,432(sp)
    800061d4:	79ba                	ld	s3,424(sp)
    800061d6:	7a1a                	ld	s4,416(sp)
    800061d8:	6afa                	ld	s5,408(sp)
    800061da:	6179                	addi	sp,sp,464
    800061dc:	8082                	ret

00000000800061de <sys_pipe>:

uint64
sys_pipe(void)
{
    800061de:	7139                	addi	sp,sp,-64
    800061e0:	fc06                	sd	ra,56(sp)
    800061e2:	f822                	sd	s0,48(sp)
    800061e4:	f426                	sd	s1,40(sp)
    800061e6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800061e8:	ffffc097          	auipc	ra,0xffffc
    800061ec:	d14080e7          	jalr	-748(ra) # 80001efc <myproc>
    800061f0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800061f2:	fd840593          	addi	a1,s0,-40
    800061f6:	4501                	li	a0,0
    800061f8:	ffffd097          	auipc	ra,0xffffd
    800061fc:	fc0080e7          	jalr	-64(ra) # 800031b8 <argaddr>
    return -1;
    80006200:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006202:	0e054063          	bltz	a0,800062e2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006206:	fc840593          	addi	a1,s0,-56
    8000620a:	fd040513          	addi	a0,s0,-48
    8000620e:	fffff097          	auipc	ra,0xfffff
    80006212:	dba080e7          	jalr	-582(ra) # 80004fc8 <pipealloc>
    return -1;
    80006216:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006218:	0c054563          	bltz	a0,800062e2 <sys_pipe+0x104>
  fd0 = -1;
    8000621c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006220:	fd043503          	ld	a0,-48(s0)
    80006224:	fffff097          	auipc	ra,0xfffff
    80006228:	508080e7          	jalr	1288(ra) # 8000572c <fdalloc>
    8000622c:	fca42223          	sw	a0,-60(s0)
    80006230:	08054c63          	bltz	a0,800062c8 <sys_pipe+0xea>
    80006234:	fc843503          	ld	a0,-56(s0)
    80006238:	fffff097          	auipc	ra,0xfffff
    8000623c:	4f4080e7          	jalr	1268(ra) # 8000572c <fdalloc>
    80006240:	fca42023          	sw	a0,-64(s0)
    80006244:	06054863          	bltz	a0,800062b4 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006248:	4691                	li	a3,4
    8000624a:	fc440613          	addi	a2,s0,-60
    8000624e:	fd843583          	ld	a1,-40(s0)
    80006252:	68a8                	ld	a0,80(s1)
    80006254:	ffffb097          	auipc	ra,0xffffb
    80006258:	4ec080e7          	jalr	1260(ra) # 80001740 <copyout>
    8000625c:	02054063          	bltz	a0,8000627c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006260:	4691                	li	a3,4
    80006262:	fc040613          	addi	a2,s0,-64
    80006266:	fd843583          	ld	a1,-40(s0)
    8000626a:	0591                	addi	a1,a1,4
    8000626c:	68a8                	ld	a0,80(s1)
    8000626e:	ffffb097          	auipc	ra,0xffffb
    80006272:	4d2080e7          	jalr	1234(ra) # 80001740 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006276:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006278:	06055563          	bgez	a0,800062e2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000627c:	fc442783          	lw	a5,-60(s0)
    80006280:	07e9                	addi	a5,a5,26
    80006282:	078e                	slli	a5,a5,0x3
    80006284:	97a6                	add	a5,a5,s1
    80006286:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000628a:	fc042503          	lw	a0,-64(s0)
    8000628e:	0569                	addi	a0,a0,26
    80006290:	050e                	slli	a0,a0,0x3
    80006292:	9526                	add	a0,a0,s1
    80006294:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006298:	fd043503          	ld	a0,-48(s0)
    8000629c:	fffff097          	auipc	ra,0xfffff
    800062a0:	9d6080e7          	jalr	-1578(ra) # 80004c72 <fileclose>
    fileclose(wf);
    800062a4:	fc843503          	ld	a0,-56(s0)
    800062a8:	fffff097          	auipc	ra,0xfffff
    800062ac:	9ca080e7          	jalr	-1590(ra) # 80004c72 <fileclose>
    return -1;
    800062b0:	57fd                	li	a5,-1
    800062b2:	a805                	j	800062e2 <sys_pipe+0x104>
    if(fd0 >= 0)
    800062b4:	fc442783          	lw	a5,-60(s0)
    800062b8:	0007c863          	bltz	a5,800062c8 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800062bc:	01a78513          	addi	a0,a5,26
    800062c0:	050e                	slli	a0,a0,0x3
    800062c2:	9526                	add	a0,a0,s1
    800062c4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800062c8:	fd043503          	ld	a0,-48(s0)
    800062cc:	fffff097          	auipc	ra,0xfffff
    800062d0:	9a6080e7          	jalr	-1626(ra) # 80004c72 <fileclose>
    fileclose(wf);
    800062d4:	fc843503          	ld	a0,-56(s0)
    800062d8:	fffff097          	auipc	ra,0xfffff
    800062dc:	99a080e7          	jalr	-1638(ra) # 80004c72 <fileclose>
    return -1;
    800062e0:	57fd                	li	a5,-1
}
    800062e2:	853e                	mv	a0,a5
    800062e4:	70e2                	ld	ra,56(sp)
    800062e6:	7442                	ld	s0,48(sp)
    800062e8:	74a2                	ld	s1,40(sp)
    800062ea:	6121                	addi	sp,sp,64
    800062ec:	8082                	ret
	...

00000000800062f0 <kernelvec>:
    800062f0:	7111                	addi	sp,sp,-256
    800062f2:	e006                	sd	ra,0(sp)
    800062f4:	e40a                	sd	sp,8(sp)
    800062f6:	e80e                	sd	gp,16(sp)
    800062f8:	ec12                	sd	tp,24(sp)
    800062fa:	f016                	sd	t0,32(sp)
    800062fc:	f41a                	sd	t1,40(sp)
    800062fe:	f81e                	sd	t2,48(sp)
    80006300:	fc22                	sd	s0,56(sp)
    80006302:	e0a6                	sd	s1,64(sp)
    80006304:	e4aa                	sd	a0,72(sp)
    80006306:	e8ae                	sd	a1,80(sp)
    80006308:	ecb2                	sd	a2,88(sp)
    8000630a:	f0b6                	sd	a3,96(sp)
    8000630c:	f4ba                	sd	a4,104(sp)
    8000630e:	f8be                	sd	a5,112(sp)
    80006310:	fcc2                	sd	a6,120(sp)
    80006312:	e146                	sd	a7,128(sp)
    80006314:	e54a                	sd	s2,136(sp)
    80006316:	e94e                	sd	s3,144(sp)
    80006318:	ed52                	sd	s4,152(sp)
    8000631a:	f156                	sd	s5,160(sp)
    8000631c:	f55a                	sd	s6,168(sp)
    8000631e:	f95e                	sd	s7,176(sp)
    80006320:	fd62                	sd	s8,184(sp)
    80006322:	e1e6                	sd	s9,192(sp)
    80006324:	e5ea                	sd	s10,200(sp)
    80006326:	e9ee                	sd	s11,208(sp)
    80006328:	edf2                	sd	t3,216(sp)
    8000632a:	f1f6                	sd	t4,224(sp)
    8000632c:	f5fa                	sd	t5,232(sp)
    8000632e:	f9fe                	sd	t6,240(sp)
    80006330:	c99fc0ef          	jal	ra,80002fc8 <kerneltrap>
    80006334:	6082                	ld	ra,0(sp)
    80006336:	6122                	ld	sp,8(sp)
    80006338:	61c2                	ld	gp,16(sp)
    8000633a:	7282                	ld	t0,32(sp)
    8000633c:	7322                	ld	t1,40(sp)
    8000633e:	73c2                	ld	t2,48(sp)
    80006340:	7462                	ld	s0,56(sp)
    80006342:	6486                	ld	s1,64(sp)
    80006344:	6526                	ld	a0,72(sp)
    80006346:	65c6                	ld	a1,80(sp)
    80006348:	6666                	ld	a2,88(sp)
    8000634a:	7686                	ld	a3,96(sp)
    8000634c:	7726                	ld	a4,104(sp)
    8000634e:	77c6                	ld	a5,112(sp)
    80006350:	7866                	ld	a6,120(sp)
    80006352:	688a                	ld	a7,128(sp)
    80006354:	692a                	ld	s2,136(sp)
    80006356:	69ca                	ld	s3,144(sp)
    80006358:	6a6a                	ld	s4,152(sp)
    8000635a:	7a8a                	ld	s5,160(sp)
    8000635c:	7b2a                	ld	s6,168(sp)
    8000635e:	7bca                	ld	s7,176(sp)
    80006360:	7c6a                	ld	s8,184(sp)
    80006362:	6c8e                	ld	s9,192(sp)
    80006364:	6d2e                	ld	s10,200(sp)
    80006366:	6dce                	ld	s11,208(sp)
    80006368:	6e6e                	ld	t3,216(sp)
    8000636a:	7e8e                	ld	t4,224(sp)
    8000636c:	7f2e                	ld	t5,232(sp)
    8000636e:	7fce                	ld	t6,240(sp)
    80006370:	6111                	addi	sp,sp,256
    80006372:	10200073          	sret
    80006376:	00000013          	nop
    8000637a:	00000013          	nop
    8000637e:	0001                	nop

0000000080006380 <timervec>:
    80006380:	34051573          	csrrw	a0,mscratch,a0
    80006384:	e10c                	sd	a1,0(a0)
    80006386:	e510                	sd	a2,8(a0)
    80006388:	e914                	sd	a3,16(a0)
    8000638a:	710c                	ld	a1,32(a0)
    8000638c:	7510                	ld	a2,40(a0)
    8000638e:	6194                	ld	a3,0(a1)
    80006390:	96b2                	add	a3,a3,a2
    80006392:	e194                	sd	a3,0(a1)
    80006394:	4589                	li	a1,2
    80006396:	14459073          	csrw	sip,a1
    8000639a:	6914                	ld	a3,16(a0)
    8000639c:	6510                	ld	a2,8(a0)
    8000639e:	610c                	ld	a1,0(a0)
    800063a0:	34051573          	csrrw	a0,mscratch,a0
    800063a4:	30200073          	mret
	...

00000000800063aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800063aa:	1141                	addi	sp,sp,-16
    800063ac:	e422                	sd	s0,8(sp)
    800063ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800063b0:	0c0007b7          	lui	a5,0xc000
    800063b4:	4705                	li	a4,1
    800063b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800063b8:	c3d8                	sw	a4,4(a5)
}
    800063ba:	6422                	ld	s0,8(sp)
    800063bc:	0141                	addi	sp,sp,16
    800063be:	8082                	ret

00000000800063c0 <plicinithart>:

void
plicinithart(void)
{
    800063c0:	1141                	addi	sp,sp,-16
    800063c2:	e406                	sd	ra,8(sp)
    800063c4:	e022                	sd	s0,0(sp)
    800063c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063c8:	ffffc097          	auipc	ra,0xffffc
    800063cc:	b08080e7          	jalr	-1272(ra) # 80001ed0 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800063d0:	0085171b          	slliw	a4,a0,0x8
    800063d4:	0c0027b7          	lui	a5,0xc002
    800063d8:	97ba                	add	a5,a5,a4
    800063da:	40200713          	li	a4,1026
    800063de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800063e2:	00d5151b          	slliw	a0,a0,0xd
    800063e6:	0c2017b7          	lui	a5,0xc201
    800063ea:	953e                	add	a0,a0,a5
    800063ec:	00052023          	sw	zero,0(a0)
}
    800063f0:	60a2                	ld	ra,8(sp)
    800063f2:	6402                	ld	s0,0(sp)
    800063f4:	0141                	addi	sp,sp,16
    800063f6:	8082                	ret

00000000800063f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063f8:	1141                	addi	sp,sp,-16
    800063fa:	e406                	sd	ra,8(sp)
    800063fc:	e022                	sd	s0,0(sp)
    800063fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006400:	ffffc097          	auipc	ra,0xffffc
    80006404:	ad0080e7          	jalr	-1328(ra) # 80001ed0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006408:	00d5179b          	slliw	a5,a0,0xd
    8000640c:	0c201537          	lui	a0,0xc201
    80006410:	953e                	add	a0,a0,a5
  return irq;
}
    80006412:	4148                	lw	a0,4(a0)
    80006414:	60a2                	ld	ra,8(sp)
    80006416:	6402                	ld	s0,0(sp)
    80006418:	0141                	addi	sp,sp,16
    8000641a:	8082                	ret

000000008000641c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000641c:	1101                	addi	sp,sp,-32
    8000641e:	ec06                	sd	ra,24(sp)
    80006420:	e822                	sd	s0,16(sp)
    80006422:	e426                	sd	s1,8(sp)
    80006424:	1000                	addi	s0,sp,32
    80006426:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006428:	ffffc097          	auipc	ra,0xffffc
    8000642c:	aa8080e7          	jalr	-1368(ra) # 80001ed0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006430:	00d5151b          	slliw	a0,a0,0xd
    80006434:	0c2017b7          	lui	a5,0xc201
    80006438:	97aa                	add	a5,a5,a0
    8000643a:	c3c4                	sw	s1,4(a5)
}
    8000643c:	60e2                	ld	ra,24(sp)
    8000643e:	6442                	ld	s0,16(sp)
    80006440:	64a2                	ld	s1,8(sp)
    80006442:	6105                	addi	sp,sp,32
    80006444:	8082                	ret

0000000080006446 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006446:	1141                	addi	sp,sp,-16
    80006448:	e406                	sd	ra,8(sp)
    8000644a:	e022                	sd	s0,0(sp)
    8000644c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000644e:	479d                	li	a5,7
    80006450:	04a7cc63          	blt	a5,a0,800064a8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80006454:	0001d797          	auipc	a5,0x1d
    80006458:	bac78793          	addi	a5,a5,-1108 # 80023000 <disk>
    8000645c:	00a78733          	add	a4,a5,a0
    80006460:	6789                	lui	a5,0x2
    80006462:	97ba                	add	a5,a5,a4
    80006464:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006468:	eba1                	bnez	a5,800064b8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    8000646a:	00451713          	slli	a4,a0,0x4
    8000646e:	0001f797          	auipc	a5,0x1f
    80006472:	b927b783          	ld	a5,-1134(a5) # 80025000 <disk+0x2000>
    80006476:	97ba                	add	a5,a5,a4
    80006478:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    8000647c:	0001d797          	auipc	a5,0x1d
    80006480:	b8478793          	addi	a5,a5,-1148 # 80023000 <disk>
    80006484:	97aa                	add	a5,a5,a0
    80006486:	6509                	lui	a0,0x2
    80006488:	953e                	add	a0,a0,a5
    8000648a:	4785                	li	a5,1
    8000648c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006490:	0001f517          	auipc	a0,0x1f
    80006494:	b8850513          	addi	a0,a0,-1144 # 80025018 <disk+0x2018>
    80006498:	ffffc097          	auipc	ra,0xffffc
    8000649c:	582080e7          	jalr	1410(ra) # 80002a1a <wakeup>
}
    800064a0:	60a2                	ld	ra,8(sp)
    800064a2:	6402                	ld	s0,0(sp)
    800064a4:	0141                	addi	sp,sp,16
    800064a6:	8082                	ret
    panic("virtio_disk_intr 1");
    800064a8:	00002517          	auipc	a0,0x2
    800064ac:	54050513          	addi	a0,a0,1344 # 800089e8 <sysnames+0x330>
    800064b0:	ffffa097          	auipc	ra,0xffffa
    800064b4:	098080e7          	jalr	152(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    800064b8:	00002517          	auipc	a0,0x2
    800064bc:	54850513          	addi	a0,a0,1352 # 80008a00 <sysnames+0x348>
    800064c0:	ffffa097          	auipc	ra,0xffffa
    800064c4:	088080e7          	jalr	136(ra) # 80000548 <panic>

00000000800064c8 <virtio_disk_init>:
{
    800064c8:	1101                	addi	sp,sp,-32
    800064ca:	ec06                	sd	ra,24(sp)
    800064cc:	e822                	sd	s0,16(sp)
    800064ce:	e426                	sd	s1,8(sp)
    800064d0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800064d2:	00002597          	auipc	a1,0x2
    800064d6:	54658593          	addi	a1,a1,1350 # 80008a18 <sysnames+0x360>
    800064da:	0001f517          	auipc	a0,0x1f
    800064de:	bce50513          	addi	a0,a0,-1074 # 800250a8 <disk+0x20a8>
    800064e2:	ffffa097          	auipc	ra,0xffffa
    800064e6:	6e8080e7          	jalr	1768(ra) # 80000bca <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064ea:	100017b7          	lui	a5,0x10001
    800064ee:	4398                	lw	a4,0(a5)
    800064f0:	2701                	sext.w	a4,a4
    800064f2:	747277b7          	lui	a5,0x74727
    800064f6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064fa:	0ef71163          	bne	a4,a5,800065dc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064fe:	100017b7          	lui	a5,0x10001
    80006502:	43dc                	lw	a5,4(a5)
    80006504:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006506:	4705                	li	a4,1
    80006508:	0ce79a63          	bne	a5,a4,800065dc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000650c:	100017b7          	lui	a5,0x10001
    80006510:	479c                	lw	a5,8(a5)
    80006512:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006514:	4709                	li	a4,2
    80006516:	0ce79363          	bne	a5,a4,800065dc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000651a:	100017b7          	lui	a5,0x10001
    8000651e:	47d8                	lw	a4,12(a5)
    80006520:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006522:	554d47b7          	lui	a5,0x554d4
    80006526:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000652a:	0af71963          	bne	a4,a5,800065dc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000652e:	100017b7          	lui	a5,0x10001
    80006532:	4705                	li	a4,1
    80006534:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006536:	470d                	li	a4,3
    80006538:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000653a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000653c:	c7ffe737          	lui	a4,0xc7ffe
    80006540:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80006544:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006546:	2701                	sext.w	a4,a4
    80006548:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000654a:	472d                	li	a4,11
    8000654c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000654e:	473d                	li	a4,15
    80006550:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006552:	6705                	lui	a4,0x1
    80006554:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006556:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000655a:	5bdc                	lw	a5,52(a5)
    8000655c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000655e:	c7d9                	beqz	a5,800065ec <virtio_disk_init+0x124>
  if(max < NUM)
    80006560:	471d                	li	a4,7
    80006562:	08f77d63          	bgeu	a4,a5,800065fc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006566:	100014b7          	lui	s1,0x10001
    8000656a:	47a1                	li	a5,8
    8000656c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000656e:	6609                	lui	a2,0x2
    80006570:	4581                	li	a1,0
    80006572:	0001d517          	auipc	a0,0x1d
    80006576:	a8e50513          	addi	a0,a0,-1394 # 80023000 <disk>
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	7dc080e7          	jalr	2012(ra) # 80000d56 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006582:	0001d717          	auipc	a4,0x1d
    80006586:	a7e70713          	addi	a4,a4,-1410 # 80023000 <disk>
    8000658a:	00c75793          	srli	a5,a4,0xc
    8000658e:	2781                	sext.w	a5,a5
    80006590:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006592:	0001f797          	auipc	a5,0x1f
    80006596:	a6e78793          	addi	a5,a5,-1426 # 80025000 <disk+0x2000>
    8000659a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000659c:	0001d717          	auipc	a4,0x1d
    800065a0:	ae470713          	addi	a4,a4,-1308 # 80023080 <disk+0x80>
    800065a4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    800065a6:	0001e717          	auipc	a4,0x1e
    800065aa:	a5a70713          	addi	a4,a4,-1446 # 80024000 <disk+0x1000>
    800065ae:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800065b0:	4705                	li	a4,1
    800065b2:	00e78c23          	sb	a4,24(a5)
    800065b6:	00e78ca3          	sb	a4,25(a5)
    800065ba:	00e78d23          	sb	a4,26(a5)
    800065be:	00e78da3          	sb	a4,27(a5)
    800065c2:	00e78e23          	sb	a4,28(a5)
    800065c6:	00e78ea3          	sb	a4,29(a5)
    800065ca:	00e78f23          	sb	a4,30(a5)
    800065ce:	00e78fa3          	sb	a4,31(a5)
}
    800065d2:	60e2                	ld	ra,24(sp)
    800065d4:	6442                	ld	s0,16(sp)
    800065d6:	64a2                	ld	s1,8(sp)
    800065d8:	6105                	addi	sp,sp,32
    800065da:	8082                	ret
    panic("could not find virtio disk");
    800065dc:	00002517          	auipc	a0,0x2
    800065e0:	44c50513          	addi	a0,a0,1100 # 80008a28 <sysnames+0x370>
    800065e4:	ffffa097          	auipc	ra,0xffffa
    800065e8:	f64080e7          	jalr	-156(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    800065ec:	00002517          	auipc	a0,0x2
    800065f0:	45c50513          	addi	a0,a0,1116 # 80008a48 <sysnames+0x390>
    800065f4:	ffffa097          	auipc	ra,0xffffa
    800065f8:	f54080e7          	jalr	-172(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    800065fc:	00002517          	auipc	a0,0x2
    80006600:	46c50513          	addi	a0,a0,1132 # 80008a68 <sysnames+0x3b0>
    80006604:	ffffa097          	auipc	ra,0xffffa
    80006608:	f44080e7          	jalr	-188(ra) # 80000548 <panic>

000000008000660c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000660c:	7119                	addi	sp,sp,-128
    8000660e:	fc86                	sd	ra,120(sp)
    80006610:	f8a2                	sd	s0,112(sp)
    80006612:	f4a6                	sd	s1,104(sp)
    80006614:	f0ca                	sd	s2,96(sp)
    80006616:	ecce                	sd	s3,88(sp)
    80006618:	e8d2                	sd	s4,80(sp)
    8000661a:	e4d6                	sd	s5,72(sp)
    8000661c:	e0da                	sd	s6,64(sp)
    8000661e:	fc5e                	sd	s7,56(sp)
    80006620:	f862                	sd	s8,48(sp)
    80006622:	f466                	sd	s9,40(sp)
    80006624:	f06a                	sd	s10,32(sp)
    80006626:	0100                	addi	s0,sp,128
    80006628:	892a                	mv	s2,a0
    8000662a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000662c:	00c52c83          	lw	s9,12(a0)
    80006630:	001c9c9b          	slliw	s9,s9,0x1
    80006634:	1c82                	slli	s9,s9,0x20
    80006636:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000663a:	0001f517          	auipc	a0,0x1f
    8000663e:	a6e50513          	addi	a0,a0,-1426 # 800250a8 <disk+0x20a8>
    80006642:	ffffa097          	auipc	ra,0xffffa
    80006646:	618080e7          	jalr	1560(ra) # 80000c5a <acquire>
  for(int i = 0; i < 3; i++){
    8000664a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000664c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000664e:	0001db97          	auipc	s7,0x1d
    80006652:	9b2b8b93          	addi	s7,s7,-1614 # 80023000 <disk>
    80006656:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006658:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000665a:	8a4e                	mv	s4,s3
    8000665c:	a051                	j	800066e0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000665e:	00fb86b3          	add	a3,s7,a5
    80006662:	96da                	add	a3,a3,s6
    80006664:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006668:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000666a:	0207c563          	bltz	a5,80006694 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000666e:	2485                	addiw	s1,s1,1
    80006670:	0711                	addi	a4,a4,4
    80006672:	23548d63          	beq	s1,s5,800068ac <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006676:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006678:	0001f697          	auipc	a3,0x1f
    8000667c:	9a068693          	addi	a3,a3,-1632 # 80025018 <disk+0x2018>
    80006680:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006682:	0006c583          	lbu	a1,0(a3)
    80006686:	fde1                	bnez	a1,8000665e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006688:	2785                	addiw	a5,a5,1
    8000668a:	0685                	addi	a3,a3,1
    8000668c:	ff879be3          	bne	a5,s8,80006682 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006690:	57fd                	li	a5,-1
    80006692:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006694:	02905a63          	blez	s1,800066c8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006698:	f9042503          	lw	a0,-112(s0)
    8000669c:	00000097          	auipc	ra,0x0
    800066a0:	daa080e7          	jalr	-598(ra) # 80006446 <free_desc>
      for(int j = 0; j < i; j++)
    800066a4:	4785                	li	a5,1
    800066a6:	0297d163          	bge	a5,s1,800066c8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066aa:	f9442503          	lw	a0,-108(s0)
    800066ae:	00000097          	auipc	ra,0x0
    800066b2:	d98080e7          	jalr	-616(ra) # 80006446 <free_desc>
      for(int j = 0; j < i; j++)
    800066b6:	4789                	li	a5,2
    800066b8:	0097d863          	bge	a5,s1,800066c8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066bc:	f9842503          	lw	a0,-104(s0)
    800066c0:	00000097          	auipc	ra,0x0
    800066c4:	d86080e7          	jalr	-634(ra) # 80006446 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066c8:	0001f597          	auipc	a1,0x1f
    800066cc:	9e058593          	addi	a1,a1,-1568 # 800250a8 <disk+0x20a8>
    800066d0:	0001f517          	auipc	a0,0x1f
    800066d4:	94850513          	addi	a0,a0,-1720 # 80025018 <disk+0x2018>
    800066d8:	ffffc097          	auipc	ra,0xffffc
    800066dc:	1bc080e7          	jalr	444(ra) # 80002894 <sleep>
  for(int i = 0; i < 3; i++){
    800066e0:	f9040713          	addi	a4,s0,-112
    800066e4:	84ce                	mv	s1,s3
    800066e6:	bf41                	j	80006676 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    800066e8:	4785                	li	a5,1
    800066ea:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    800066ee:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800066f2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800066f6:	f9042983          	lw	s3,-112(s0)
    800066fa:	00499493          	slli	s1,s3,0x4
    800066fe:	0001fa17          	auipc	s4,0x1f
    80006702:	902a0a13          	addi	s4,s4,-1790 # 80025000 <disk+0x2000>
    80006706:	000a3a83          	ld	s5,0(s4)
    8000670a:	9aa6                	add	s5,s5,s1
    8000670c:	f8040513          	addi	a0,s0,-128
    80006710:	ffffb097          	auipc	ra,0xffffb
    80006714:	a3e080e7          	jalr	-1474(ra) # 8000114e <kvmpa>
    80006718:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000671c:	000a3783          	ld	a5,0(s4)
    80006720:	97a6                	add	a5,a5,s1
    80006722:	4741                	li	a4,16
    80006724:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006726:	000a3783          	ld	a5,0(s4)
    8000672a:	97a6                	add	a5,a5,s1
    8000672c:	4705                	li	a4,1
    8000672e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006732:	f9442703          	lw	a4,-108(s0)
    80006736:	000a3783          	ld	a5,0(s4)
    8000673a:	97a6                	add	a5,a5,s1
    8000673c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006740:	0712                	slli	a4,a4,0x4
    80006742:	000a3783          	ld	a5,0(s4)
    80006746:	97ba                	add	a5,a5,a4
    80006748:	05890693          	addi	a3,s2,88
    8000674c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000674e:	000a3783          	ld	a5,0(s4)
    80006752:	97ba                	add	a5,a5,a4
    80006754:	40000693          	li	a3,1024
    80006758:	c794                	sw	a3,8(a5)
  if(write)
    8000675a:	100d0a63          	beqz	s10,8000686e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000675e:	0001f797          	auipc	a5,0x1f
    80006762:	8a27b783          	ld	a5,-1886(a5) # 80025000 <disk+0x2000>
    80006766:	97ba                	add	a5,a5,a4
    80006768:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000676c:	0001d517          	auipc	a0,0x1d
    80006770:	89450513          	addi	a0,a0,-1900 # 80023000 <disk>
    80006774:	0001f797          	auipc	a5,0x1f
    80006778:	88c78793          	addi	a5,a5,-1908 # 80025000 <disk+0x2000>
    8000677c:	6394                	ld	a3,0(a5)
    8000677e:	96ba                	add	a3,a3,a4
    80006780:	00c6d603          	lhu	a2,12(a3)
    80006784:	00166613          	ori	a2,a2,1
    80006788:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000678c:	f9842683          	lw	a3,-104(s0)
    80006790:	6390                	ld	a2,0(a5)
    80006792:	9732                	add	a4,a4,a2
    80006794:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006798:	20098613          	addi	a2,s3,512
    8000679c:	0612                	slli	a2,a2,0x4
    8000679e:	962a                	add	a2,a2,a0
    800067a0:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067a4:	00469713          	slli	a4,a3,0x4
    800067a8:	6394                	ld	a3,0(a5)
    800067aa:	96ba                	add	a3,a3,a4
    800067ac:	6589                	lui	a1,0x2
    800067ae:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800067b2:	94ae                	add	s1,s1,a1
    800067b4:	94aa                	add	s1,s1,a0
    800067b6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800067b8:	6394                	ld	a3,0(a5)
    800067ba:	96ba                	add	a3,a3,a4
    800067bc:	4585                	li	a1,1
    800067be:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067c0:	6394                	ld	a3,0(a5)
    800067c2:	96ba                	add	a3,a3,a4
    800067c4:	4509                	li	a0,2
    800067c6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800067ca:	6394                	ld	a3,0(a5)
    800067cc:	9736                	add	a4,a4,a3
    800067ce:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067d2:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800067d6:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800067da:	6794                	ld	a3,8(a5)
    800067dc:	0026d703          	lhu	a4,2(a3)
    800067e0:	8b1d                	andi	a4,a4,7
    800067e2:	2709                	addiw	a4,a4,2
    800067e4:	0706                	slli	a4,a4,0x1
    800067e6:	9736                	add	a4,a4,a3
    800067e8:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800067ec:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800067f0:	6798                	ld	a4,8(a5)
    800067f2:	00275783          	lhu	a5,2(a4)
    800067f6:	2785                	addiw	a5,a5,1
    800067f8:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067fc:	100017b7          	lui	a5,0x10001
    80006800:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006804:	00492703          	lw	a4,4(s2)
    80006808:	4785                	li	a5,1
    8000680a:	02f71163          	bne	a4,a5,8000682c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000680e:	0001f997          	auipc	s3,0x1f
    80006812:	89a98993          	addi	s3,s3,-1894 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006816:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006818:	85ce                	mv	a1,s3
    8000681a:	854a                	mv	a0,s2
    8000681c:	ffffc097          	auipc	ra,0xffffc
    80006820:	078080e7          	jalr	120(ra) # 80002894 <sleep>
  while(b->disk == 1) {
    80006824:	00492783          	lw	a5,4(s2)
    80006828:	fe9788e3          	beq	a5,s1,80006818 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000682c:	f9042483          	lw	s1,-112(s0)
    80006830:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006834:	00479713          	slli	a4,a5,0x4
    80006838:	0001c797          	auipc	a5,0x1c
    8000683c:	7c878793          	addi	a5,a5,1992 # 80023000 <disk>
    80006840:	97ba                	add	a5,a5,a4
    80006842:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006846:	0001e917          	auipc	s2,0x1e
    8000684a:	7ba90913          	addi	s2,s2,1978 # 80025000 <disk+0x2000>
    free_desc(i);
    8000684e:	8526                	mv	a0,s1
    80006850:	00000097          	auipc	ra,0x0
    80006854:	bf6080e7          	jalr	-1034(ra) # 80006446 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006858:	0492                	slli	s1,s1,0x4
    8000685a:	00093783          	ld	a5,0(s2)
    8000685e:	94be                	add	s1,s1,a5
    80006860:	00c4d783          	lhu	a5,12(s1)
    80006864:	8b85                	andi	a5,a5,1
    80006866:	cf89                	beqz	a5,80006880 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006868:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000686c:	b7cd                	j	8000684e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000686e:	0001e797          	auipc	a5,0x1e
    80006872:	7927b783          	ld	a5,1938(a5) # 80025000 <disk+0x2000>
    80006876:	97ba                	add	a5,a5,a4
    80006878:	4689                	li	a3,2
    8000687a:	00d79623          	sh	a3,12(a5)
    8000687e:	b5fd                	j	8000676c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006880:	0001f517          	auipc	a0,0x1f
    80006884:	82850513          	addi	a0,a0,-2008 # 800250a8 <disk+0x20a8>
    80006888:	ffffa097          	auipc	ra,0xffffa
    8000688c:	486080e7          	jalr	1158(ra) # 80000d0e <release>
}
    80006890:	70e6                	ld	ra,120(sp)
    80006892:	7446                	ld	s0,112(sp)
    80006894:	74a6                	ld	s1,104(sp)
    80006896:	7906                	ld	s2,96(sp)
    80006898:	69e6                	ld	s3,88(sp)
    8000689a:	6a46                	ld	s4,80(sp)
    8000689c:	6aa6                	ld	s5,72(sp)
    8000689e:	6b06                	ld	s6,64(sp)
    800068a0:	7be2                	ld	s7,56(sp)
    800068a2:	7c42                	ld	s8,48(sp)
    800068a4:	7ca2                	ld	s9,40(sp)
    800068a6:	7d02                	ld	s10,32(sp)
    800068a8:	6109                	addi	sp,sp,128
    800068aa:	8082                	ret
  if(write)
    800068ac:	e20d1ee3          	bnez	s10,800066e8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800068b0:	f8042023          	sw	zero,-128(s0)
    800068b4:	bd2d                	j	800066ee <virtio_disk_rw+0xe2>

00000000800068b6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068b6:	1101                	addi	sp,sp,-32
    800068b8:	ec06                	sd	ra,24(sp)
    800068ba:	e822                	sd	s0,16(sp)
    800068bc:	e426                	sd	s1,8(sp)
    800068be:	e04a                	sd	s2,0(sp)
    800068c0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068c2:	0001e517          	auipc	a0,0x1e
    800068c6:	7e650513          	addi	a0,a0,2022 # 800250a8 <disk+0x20a8>
    800068ca:	ffffa097          	auipc	ra,0xffffa
    800068ce:	390080e7          	jalr	912(ra) # 80000c5a <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800068d2:	0001e717          	auipc	a4,0x1e
    800068d6:	72e70713          	addi	a4,a4,1838 # 80025000 <disk+0x2000>
    800068da:	02075783          	lhu	a5,32(a4)
    800068de:	6b18                	ld	a4,16(a4)
    800068e0:	00275683          	lhu	a3,2(a4)
    800068e4:	8ebd                	xor	a3,a3,a5
    800068e6:	8a9d                	andi	a3,a3,7
    800068e8:	cab9                	beqz	a3,8000693e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800068ea:	0001c917          	auipc	s2,0x1c
    800068ee:	71690913          	addi	s2,s2,1814 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800068f2:	0001e497          	auipc	s1,0x1e
    800068f6:	70e48493          	addi	s1,s1,1806 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800068fa:	078e                	slli	a5,a5,0x3
    800068fc:	97ba                	add	a5,a5,a4
    800068fe:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006900:	20078713          	addi	a4,a5,512
    80006904:	0712                	slli	a4,a4,0x4
    80006906:	974a                	add	a4,a4,s2
    80006908:	03074703          	lbu	a4,48(a4)
    8000690c:	ef21                	bnez	a4,80006964 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000690e:	20078793          	addi	a5,a5,512
    80006912:	0792                	slli	a5,a5,0x4
    80006914:	97ca                	add	a5,a5,s2
    80006916:	7798                	ld	a4,40(a5)
    80006918:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000691c:	7788                	ld	a0,40(a5)
    8000691e:	ffffc097          	auipc	ra,0xffffc
    80006922:	0fc080e7          	jalr	252(ra) # 80002a1a <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006926:	0204d783          	lhu	a5,32(s1)
    8000692a:	2785                	addiw	a5,a5,1
    8000692c:	8b9d                	andi	a5,a5,7
    8000692e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006932:	6898                	ld	a4,16(s1)
    80006934:	00275683          	lhu	a3,2(a4)
    80006938:	8a9d                	andi	a3,a3,7
    8000693a:	fcf690e3          	bne	a3,a5,800068fa <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000693e:	10001737          	lui	a4,0x10001
    80006942:	533c                	lw	a5,96(a4)
    80006944:	8b8d                	andi	a5,a5,3
    80006946:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006948:	0001e517          	auipc	a0,0x1e
    8000694c:	76050513          	addi	a0,a0,1888 # 800250a8 <disk+0x20a8>
    80006950:	ffffa097          	auipc	ra,0xffffa
    80006954:	3be080e7          	jalr	958(ra) # 80000d0e <release>
}
    80006958:	60e2                	ld	ra,24(sp)
    8000695a:	6442                	ld	s0,16(sp)
    8000695c:	64a2                	ld	s1,8(sp)
    8000695e:	6902                	ld	s2,0(sp)
    80006960:	6105                	addi	sp,sp,32
    80006962:	8082                	ret
      panic("virtio_disk_intr status");
    80006964:	00002517          	auipc	a0,0x2
    80006968:	12450513          	addi	a0,a0,292 # 80008a88 <sysnames+0x3d0>
    8000696c:	ffffa097          	auipc	ra,0xffffa
    80006970:	bdc080e7          	jalr	-1060(ra) # 80000548 <panic>

0000000080006974 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    80006974:	7179                	addi	sp,sp,-48
    80006976:	f406                	sd	ra,40(sp)
    80006978:	f022                	sd	s0,32(sp)
    8000697a:	ec26                	sd	s1,24(sp)
    8000697c:	e84a                	sd	s2,16(sp)
    8000697e:	e44e                	sd	s3,8(sp)
    80006980:	e052                	sd	s4,0(sp)
    80006982:	1800                	addi	s0,sp,48
    80006984:	892a                	mv	s2,a0
    80006986:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006988:	00002a17          	auipc	s4,0x2
    8000698c:	6a0a0a13          	addi	s4,s4,1696 # 80009028 <stats>
    80006990:	000a2683          	lw	a3,0(s4)
    80006994:	00002617          	auipc	a2,0x2
    80006998:	10c60613          	addi	a2,a2,268 # 80008aa0 <sysnames+0x3e8>
    8000699c:	00000097          	auipc	ra,0x0
    800069a0:	2c2080e7          	jalr	706(ra) # 80006c5e <snprintf>
    800069a4:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    800069a6:	004a2683          	lw	a3,4(s4)
    800069aa:	00002617          	auipc	a2,0x2
    800069ae:	10660613          	addi	a2,a2,262 # 80008ab0 <sysnames+0x3f8>
    800069b2:	85ce                	mv	a1,s3
    800069b4:	954a                	add	a0,a0,s2
    800069b6:	00000097          	auipc	ra,0x0
    800069ba:	2a8080e7          	jalr	680(ra) # 80006c5e <snprintf>
  return n;
}
    800069be:	9d25                	addw	a0,a0,s1
    800069c0:	70a2                	ld	ra,40(sp)
    800069c2:	7402                	ld	s0,32(sp)
    800069c4:	64e2                	ld	s1,24(sp)
    800069c6:	6942                	ld	s2,16(sp)
    800069c8:	69a2                	ld	s3,8(sp)
    800069ca:	6a02                	ld	s4,0(sp)
    800069cc:	6145                	addi	sp,sp,48
    800069ce:	8082                	ret

00000000800069d0 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800069d0:	7179                	addi	sp,sp,-48
    800069d2:	f406                	sd	ra,40(sp)
    800069d4:	f022                	sd	s0,32(sp)
    800069d6:	ec26                	sd	s1,24(sp)
    800069d8:	e84a                	sd	s2,16(sp)
    800069da:	e44e                	sd	s3,8(sp)
    800069dc:	1800                	addi	s0,sp,48
    800069de:	89ae                	mv	s3,a1
    800069e0:	84b2                	mv	s1,a2
    800069e2:	8936                	mv	s2,a3
  struct proc *p = myproc();
    800069e4:	ffffb097          	auipc	ra,0xffffb
    800069e8:	518080e7          	jalr	1304(ra) # 80001efc <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    800069ec:	653c                	ld	a5,72(a0)
    800069ee:	02f4ff63          	bgeu	s1,a5,80006a2c <copyin_new+0x5c>
    800069f2:	01248733          	add	a4,s1,s2
    800069f6:	02f77d63          	bgeu	a4,a5,80006a30 <copyin_new+0x60>
    800069fa:	02976d63          	bltu	a4,s1,80006a34 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    800069fe:	0009061b          	sext.w	a2,s2
    80006a02:	85a6                	mv	a1,s1
    80006a04:	854e                	mv	a0,s3
    80006a06:	ffffa097          	auipc	ra,0xffffa
    80006a0a:	3b0080e7          	jalr	944(ra) # 80000db6 <memmove>
  stats.ncopyin++;   // XXX lock
    80006a0e:	00002717          	auipc	a4,0x2
    80006a12:	61a70713          	addi	a4,a4,1562 # 80009028 <stats>
    80006a16:	431c                	lw	a5,0(a4)
    80006a18:	2785                	addiw	a5,a5,1
    80006a1a:	c31c                	sw	a5,0(a4)
  return 0;
    80006a1c:	4501                	li	a0,0
}
    80006a1e:	70a2                	ld	ra,40(sp)
    80006a20:	7402                	ld	s0,32(sp)
    80006a22:	64e2                	ld	s1,24(sp)
    80006a24:	6942                	ld	s2,16(sp)
    80006a26:	69a2                	ld	s3,8(sp)
    80006a28:	6145                	addi	sp,sp,48
    80006a2a:	8082                	ret
    return -1;
    80006a2c:	557d                	li	a0,-1
    80006a2e:	bfc5                	j	80006a1e <copyin_new+0x4e>
    80006a30:	557d                	li	a0,-1
    80006a32:	b7f5                	j	80006a1e <copyin_new+0x4e>
    80006a34:	557d                	li	a0,-1
    80006a36:	b7e5                	j	80006a1e <copyin_new+0x4e>

0000000080006a38 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80006a38:	7179                	addi	sp,sp,-48
    80006a3a:	f406                	sd	ra,40(sp)
    80006a3c:	f022                	sd	s0,32(sp)
    80006a3e:	ec26                	sd	s1,24(sp)
    80006a40:	e84a                	sd	s2,16(sp)
    80006a42:	e44e                	sd	s3,8(sp)
    80006a44:	1800                	addi	s0,sp,48
    80006a46:	89ae                	mv	s3,a1
    80006a48:	8932                	mv	s2,a2
    80006a4a:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    80006a4c:	ffffb097          	auipc	ra,0xffffb
    80006a50:	4b0080e7          	jalr	1200(ra) # 80001efc <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    80006a54:	00002717          	auipc	a4,0x2
    80006a58:	5d470713          	addi	a4,a4,1492 # 80009028 <stats>
    80006a5c:	435c                	lw	a5,4(a4)
    80006a5e:	2785                	addiw	a5,a5,1
    80006a60:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006a62:	cc85                	beqz	s1,80006a9a <copyinstr_new+0x62>
    80006a64:	00990833          	add	a6,s2,s1
    80006a68:	87ca                	mv	a5,s2
    80006a6a:	6538                	ld	a4,72(a0)
    80006a6c:	00e7ff63          	bgeu	a5,a4,80006a8a <copyinstr_new+0x52>
    dst[i] = s[i];
    80006a70:	0007c683          	lbu	a3,0(a5)
    80006a74:	41278733          	sub	a4,a5,s2
    80006a78:	974e                	add	a4,a4,s3
    80006a7a:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    80006a7e:	c285                	beqz	a3,80006a9e <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006a80:	0785                	addi	a5,a5,1
    80006a82:	ff0794e3          	bne	a5,a6,80006a6a <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    80006a86:	557d                	li	a0,-1
    80006a88:	a011                	j	80006a8c <copyinstr_new+0x54>
    80006a8a:	557d                	li	a0,-1
}
    80006a8c:	70a2                	ld	ra,40(sp)
    80006a8e:	7402                	ld	s0,32(sp)
    80006a90:	64e2                	ld	s1,24(sp)
    80006a92:	6942                	ld	s2,16(sp)
    80006a94:	69a2                	ld	s3,8(sp)
    80006a96:	6145                	addi	sp,sp,48
    80006a98:	8082                	ret
  return -1;
    80006a9a:	557d                	li	a0,-1
    80006a9c:	bfc5                	j	80006a8c <copyinstr_new+0x54>
      return 0;
    80006a9e:	4501                	li	a0,0
    80006aa0:	b7f5                	j	80006a8c <copyinstr_new+0x54>

0000000080006aa2 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006aa2:	1141                	addi	sp,sp,-16
    80006aa4:	e422                	sd	s0,8(sp)
    80006aa6:	0800                	addi	s0,sp,16
  return -1;
}
    80006aa8:	557d                	li	a0,-1
    80006aaa:	6422                	ld	s0,8(sp)
    80006aac:	0141                	addi	sp,sp,16
    80006aae:	8082                	ret

0000000080006ab0 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006ab0:	7179                	addi	sp,sp,-48
    80006ab2:	f406                	sd	ra,40(sp)
    80006ab4:	f022                	sd	s0,32(sp)
    80006ab6:	ec26                	sd	s1,24(sp)
    80006ab8:	e84a                	sd	s2,16(sp)
    80006aba:	e44e                	sd	s3,8(sp)
    80006abc:	e052                	sd	s4,0(sp)
    80006abe:	1800                	addi	s0,sp,48
    80006ac0:	892a                	mv	s2,a0
    80006ac2:	89ae                	mv	s3,a1
    80006ac4:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    80006ac6:	0001f517          	auipc	a0,0x1f
    80006aca:	53a50513          	addi	a0,a0,1338 # 80026000 <stats>
    80006ace:	ffffa097          	auipc	ra,0xffffa
    80006ad2:	18c080e7          	jalr	396(ra) # 80000c5a <acquire>

  if(stats.sz == 0) {
    80006ad6:	00020797          	auipc	a5,0x20
    80006ada:	5427a783          	lw	a5,1346(a5) # 80027018 <stats+0x1018>
    80006ade:	cbb5                	beqz	a5,80006b52 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006ae0:	00020797          	auipc	a5,0x20
    80006ae4:	52078793          	addi	a5,a5,1312 # 80027000 <stats+0x1000>
    80006ae8:	4fd8                	lw	a4,28(a5)
    80006aea:	4f9c                	lw	a5,24(a5)
    80006aec:	9f99                	subw	a5,a5,a4
    80006aee:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006af2:	06d05e63          	blez	a3,80006b6e <statsread+0xbe>
    if(m > n)
    80006af6:	8a3e                	mv	s4,a5
    80006af8:	00d4d363          	bge	s1,a3,80006afe <statsread+0x4e>
    80006afc:	8a26                	mv	s4,s1
    80006afe:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006b02:	86a6                	mv	a3,s1
    80006b04:	0001f617          	auipc	a2,0x1f
    80006b08:	51460613          	addi	a2,a2,1300 # 80026018 <stats+0x18>
    80006b0c:	963a                	add	a2,a2,a4
    80006b0e:	85ce                	mv	a1,s3
    80006b10:	854a                	mv	a0,s2
    80006b12:	ffffc097          	auipc	ra,0xffffc
    80006b16:	fe4080e7          	jalr	-28(ra) # 80002af6 <either_copyout>
    80006b1a:	57fd                	li	a5,-1
    80006b1c:	00f50a63          	beq	a0,a5,80006b30 <statsread+0x80>
      stats.off += m;
    80006b20:	00020717          	auipc	a4,0x20
    80006b24:	4e070713          	addi	a4,a4,1248 # 80027000 <stats+0x1000>
    80006b28:	4f5c                	lw	a5,28(a4)
    80006b2a:	014787bb          	addw	a5,a5,s4
    80006b2e:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006b30:	0001f517          	auipc	a0,0x1f
    80006b34:	4d050513          	addi	a0,a0,1232 # 80026000 <stats>
    80006b38:	ffffa097          	auipc	ra,0xffffa
    80006b3c:	1d6080e7          	jalr	470(ra) # 80000d0e <release>
  return m;
}
    80006b40:	8526                	mv	a0,s1
    80006b42:	70a2                	ld	ra,40(sp)
    80006b44:	7402                	ld	s0,32(sp)
    80006b46:	64e2                	ld	s1,24(sp)
    80006b48:	6942                	ld	s2,16(sp)
    80006b4a:	69a2                	ld	s3,8(sp)
    80006b4c:	6a02                	ld	s4,0(sp)
    80006b4e:	6145                	addi	sp,sp,48
    80006b50:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    80006b52:	6585                	lui	a1,0x1
    80006b54:	0001f517          	auipc	a0,0x1f
    80006b58:	4c450513          	addi	a0,a0,1220 # 80026018 <stats+0x18>
    80006b5c:	00000097          	auipc	ra,0x0
    80006b60:	e18080e7          	jalr	-488(ra) # 80006974 <statscopyin>
    80006b64:	00020797          	auipc	a5,0x20
    80006b68:	4aa7aa23          	sw	a0,1204(a5) # 80027018 <stats+0x1018>
    80006b6c:	bf95                	j	80006ae0 <statsread+0x30>
    stats.sz = 0;
    80006b6e:	00020797          	auipc	a5,0x20
    80006b72:	49278793          	addi	a5,a5,1170 # 80027000 <stats+0x1000>
    80006b76:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    80006b7a:	0007ae23          	sw	zero,28(a5)
    m = -1;
    80006b7e:	54fd                	li	s1,-1
    80006b80:	bf45                	j	80006b30 <statsread+0x80>

0000000080006b82 <statsinit>:

void
statsinit(void)
{
    80006b82:	1141                	addi	sp,sp,-16
    80006b84:	e406                	sd	ra,8(sp)
    80006b86:	e022                	sd	s0,0(sp)
    80006b88:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    80006b8a:	00002597          	auipc	a1,0x2
    80006b8e:	f3658593          	addi	a1,a1,-202 # 80008ac0 <sysnames+0x408>
    80006b92:	0001f517          	auipc	a0,0x1f
    80006b96:	46e50513          	addi	a0,a0,1134 # 80026000 <stats>
    80006b9a:	ffffa097          	auipc	ra,0xffffa
    80006b9e:	030080e7          	jalr	48(ra) # 80000bca <initlock>

  devsw[STATS].read = statsread;
    80006ba2:	0001b797          	auipc	a5,0x1b
    80006ba6:	20e78793          	addi	a5,a5,526 # 80021db0 <devsw>
    80006baa:	00000717          	auipc	a4,0x0
    80006bae:	f0670713          	addi	a4,a4,-250 # 80006ab0 <statsread>
    80006bb2:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006bb4:	00000717          	auipc	a4,0x0
    80006bb8:	eee70713          	addi	a4,a4,-274 # 80006aa2 <statswrite>
    80006bbc:	f798                	sd	a4,40(a5)
}
    80006bbe:	60a2                	ld	ra,8(sp)
    80006bc0:	6402                	ld	s0,0(sp)
    80006bc2:	0141                	addi	sp,sp,16
    80006bc4:	8082                	ret

0000000080006bc6 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006bc6:	1101                	addi	sp,sp,-32
    80006bc8:	ec22                	sd	s0,24(sp)
    80006bca:	1000                	addi	s0,sp,32
    80006bcc:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    80006bce:	c299                	beqz	a3,80006bd4 <sprintint+0xe>
    80006bd0:	0805c163          	bltz	a1,80006c52 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006bd4:	2581                	sext.w	a1,a1
    80006bd6:	4301                	li	t1,0

  i = 0;
    80006bd8:	fe040713          	addi	a4,s0,-32
    80006bdc:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    80006bde:	2601                	sext.w	a2,a2
    80006be0:	00002697          	auipc	a3,0x2
    80006be4:	ee868693          	addi	a3,a3,-280 # 80008ac8 <digits>
    80006be8:	88aa                	mv	a7,a0
    80006bea:	2505                	addiw	a0,a0,1
    80006bec:	02c5f7bb          	remuw	a5,a1,a2
    80006bf0:	1782                	slli	a5,a5,0x20
    80006bf2:	9381                	srli	a5,a5,0x20
    80006bf4:	97b6                	add	a5,a5,a3
    80006bf6:	0007c783          	lbu	a5,0(a5)
    80006bfa:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    80006bfe:	0005879b          	sext.w	a5,a1
    80006c02:	02c5d5bb          	divuw	a1,a1,a2
    80006c06:	0705                	addi	a4,a4,1
    80006c08:	fec7f0e3          	bgeu	a5,a2,80006be8 <sprintint+0x22>

  if(sign)
    80006c0c:	00030b63          	beqz	t1,80006c22 <sprintint+0x5c>
    buf[i++] = '-';
    80006c10:	ff040793          	addi	a5,s0,-16
    80006c14:	97aa                	add	a5,a5,a0
    80006c16:	02d00713          	li	a4,45
    80006c1a:	fee78823          	sb	a4,-16(a5)
    80006c1e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006c22:	02a05c63          	blez	a0,80006c5a <sprintint+0x94>
    80006c26:	fe040793          	addi	a5,s0,-32
    80006c2a:	00a78733          	add	a4,a5,a0
    80006c2e:	87c2                	mv	a5,a6
    80006c30:	0805                	addi	a6,a6,1
    80006c32:	fff5061b          	addiw	a2,a0,-1
    80006c36:	1602                	slli	a2,a2,0x20
    80006c38:	9201                	srli	a2,a2,0x20
    80006c3a:	9642                	add	a2,a2,a6
  *s = c;
    80006c3c:	fff74683          	lbu	a3,-1(a4)
    80006c40:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006c44:	177d                	addi	a4,a4,-1
    80006c46:	0785                	addi	a5,a5,1
    80006c48:	fec79ae3          	bne	a5,a2,80006c3c <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    80006c4c:	6462                	ld	s0,24(sp)
    80006c4e:	6105                	addi	sp,sp,32
    80006c50:	8082                	ret
    x = -xx;
    80006c52:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006c56:	4305                	li	t1,1
    x = -xx;
    80006c58:	b741                	j	80006bd8 <sprintint+0x12>
  while(--i >= 0)
    80006c5a:	4501                	li	a0,0
    80006c5c:	bfc5                	j	80006c4c <sprintint+0x86>

0000000080006c5e <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006c5e:	7171                	addi	sp,sp,-176
    80006c60:	fc86                	sd	ra,120(sp)
    80006c62:	f8a2                	sd	s0,112(sp)
    80006c64:	f4a6                	sd	s1,104(sp)
    80006c66:	f0ca                	sd	s2,96(sp)
    80006c68:	ecce                	sd	s3,88(sp)
    80006c6a:	e8d2                	sd	s4,80(sp)
    80006c6c:	e4d6                	sd	s5,72(sp)
    80006c6e:	e0da                	sd	s6,64(sp)
    80006c70:	fc5e                	sd	s7,56(sp)
    80006c72:	f862                	sd	s8,48(sp)
    80006c74:	f466                	sd	s9,40(sp)
    80006c76:	f06a                	sd	s10,32(sp)
    80006c78:	ec6e                	sd	s11,24(sp)
    80006c7a:	0100                	addi	s0,sp,128
    80006c7c:	e414                	sd	a3,8(s0)
    80006c7e:	e818                	sd	a4,16(s0)
    80006c80:	ec1c                	sd	a5,24(s0)
    80006c82:	03043023          	sd	a6,32(s0)
    80006c86:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    80006c8a:	ca0d                	beqz	a2,80006cbc <snprintf+0x5e>
    80006c8c:	8baa                	mv	s7,a0
    80006c8e:	89ae                	mv	s3,a1
    80006c90:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006c92:	00840793          	addi	a5,s0,8
    80006c96:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    80006c9a:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006c9c:	4901                	li	s2,0
    80006c9e:	02b05763          	blez	a1,80006ccc <snprintf+0x6e>
    if(c != '%'){
    80006ca2:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006ca6:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    80006caa:	02800d93          	li	s11,40
  *s = c;
    80006cae:	02500d13          	li	s10,37
    switch(c){
    80006cb2:	07800c93          	li	s9,120
    80006cb6:	06400c13          	li	s8,100
    80006cba:	a01d                	j	80006ce0 <snprintf+0x82>
    panic("null fmt");
    80006cbc:	00001517          	auipc	a0,0x1
    80006cc0:	36c50513          	addi	a0,a0,876 # 80008028 <etext+0x28>
    80006cc4:	ffffa097          	auipc	ra,0xffffa
    80006cc8:	884080e7          	jalr	-1916(ra) # 80000548 <panic>
  int off = 0;
    80006ccc:	4481                	li	s1,0
    80006cce:	a86d                	j	80006d88 <snprintf+0x12a>
  *s = c;
    80006cd0:	009b8733          	add	a4,s7,s1
    80006cd4:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006cd8:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006cda:	2905                	addiw	s2,s2,1
    80006cdc:	0b34d663          	bge	s1,s3,80006d88 <snprintf+0x12a>
    80006ce0:	012a07b3          	add	a5,s4,s2
    80006ce4:	0007c783          	lbu	a5,0(a5)
    80006ce8:	0007871b          	sext.w	a4,a5
    80006cec:	cfd1                	beqz	a5,80006d88 <snprintf+0x12a>
    if(c != '%'){
    80006cee:	ff5711e3          	bne	a4,s5,80006cd0 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    80006cf2:	2905                	addiw	s2,s2,1
    80006cf4:	012a07b3          	add	a5,s4,s2
    80006cf8:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    80006cfc:	c7d1                	beqz	a5,80006d88 <snprintf+0x12a>
    switch(c){
    80006cfe:	05678c63          	beq	a5,s6,80006d56 <snprintf+0xf8>
    80006d02:	02fb6763          	bltu	s6,a5,80006d30 <snprintf+0xd2>
    80006d06:	0b578763          	beq	a5,s5,80006db4 <snprintf+0x156>
    80006d0a:	0b879b63          	bne	a5,s8,80006dc0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    80006d0e:	f8843783          	ld	a5,-120(s0)
    80006d12:	00878713          	addi	a4,a5,8
    80006d16:	f8e43423          	sd	a4,-120(s0)
    80006d1a:	4685                	li	a3,1
    80006d1c:	4629                	li	a2,10
    80006d1e:	438c                	lw	a1,0(a5)
    80006d20:	009b8533          	add	a0,s7,s1
    80006d24:	00000097          	auipc	ra,0x0
    80006d28:	ea2080e7          	jalr	-350(ra) # 80006bc6 <sprintint>
    80006d2c:	9ca9                	addw	s1,s1,a0
      break;
    80006d2e:	b775                	j	80006cda <snprintf+0x7c>
    switch(c){
    80006d30:	09979863          	bne	a5,s9,80006dc0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006d34:	f8843783          	ld	a5,-120(s0)
    80006d38:	00878713          	addi	a4,a5,8
    80006d3c:	f8e43423          	sd	a4,-120(s0)
    80006d40:	4685                	li	a3,1
    80006d42:	4641                	li	a2,16
    80006d44:	438c                	lw	a1,0(a5)
    80006d46:	009b8533          	add	a0,s7,s1
    80006d4a:	00000097          	auipc	ra,0x0
    80006d4e:	e7c080e7          	jalr	-388(ra) # 80006bc6 <sprintint>
    80006d52:	9ca9                	addw	s1,s1,a0
      break;
    80006d54:	b759                	j	80006cda <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006d56:	f8843783          	ld	a5,-120(s0)
    80006d5a:	00878713          	addi	a4,a5,8
    80006d5e:	f8e43423          	sd	a4,-120(s0)
    80006d62:	639c                	ld	a5,0(a5)
    80006d64:	c3b1                	beqz	a5,80006da8 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006d66:	0007c703          	lbu	a4,0(a5)
    80006d6a:	db25                	beqz	a4,80006cda <snprintf+0x7c>
    80006d6c:	0134de63          	bge	s1,s3,80006d88 <snprintf+0x12a>
    80006d70:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006d74:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006d78:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006d7a:	0785                	addi	a5,a5,1
    80006d7c:	0007c703          	lbu	a4,0(a5)
    80006d80:	df29                	beqz	a4,80006cda <snprintf+0x7c>
    80006d82:	0685                	addi	a3,a3,1
    80006d84:	fe9998e3          	bne	s3,s1,80006d74 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006d88:	8526                	mv	a0,s1
    80006d8a:	70e6                	ld	ra,120(sp)
    80006d8c:	7446                	ld	s0,112(sp)
    80006d8e:	74a6                	ld	s1,104(sp)
    80006d90:	7906                	ld	s2,96(sp)
    80006d92:	69e6                	ld	s3,88(sp)
    80006d94:	6a46                	ld	s4,80(sp)
    80006d96:	6aa6                	ld	s5,72(sp)
    80006d98:	6b06                	ld	s6,64(sp)
    80006d9a:	7be2                	ld	s7,56(sp)
    80006d9c:	7c42                	ld	s8,48(sp)
    80006d9e:	7ca2                	ld	s9,40(sp)
    80006da0:	7d02                	ld	s10,32(sp)
    80006da2:	6de2                	ld	s11,24(sp)
    80006da4:	614d                	addi	sp,sp,176
    80006da6:	8082                	ret
        s = "(null)";
    80006da8:	00001797          	auipc	a5,0x1
    80006dac:	27878793          	addi	a5,a5,632 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006db0:	876e                	mv	a4,s11
    80006db2:	bf6d                	j	80006d6c <snprintf+0x10e>
  *s = c;
    80006db4:	009b87b3          	add	a5,s7,s1
    80006db8:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    80006dbc:	2485                	addiw	s1,s1,1
      break;
    80006dbe:	bf31                	j	80006cda <snprintf+0x7c>
  *s = c;
    80006dc0:	009b8733          	add	a4,s7,s1
    80006dc4:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006dc8:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006dcc:	975e                	add	a4,a4,s7
    80006dce:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006dd2:	2489                	addiw	s1,s1,2
      break;
    80006dd4:	b719                	j	80006cda <snprintf+0x7c>
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
