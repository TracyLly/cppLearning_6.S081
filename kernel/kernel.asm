
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	17010113          	addi	sp,sp,368 # 80009170 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fde70713          	addi	a4,a4,-34 # 80009030 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	f9c78793          	addi	a5,a5,-100 # 80006000 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffcc7d7>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	21278793          	addi	a5,a5,530 # 800012c0 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
    80000106:	8a2a                	mv	s4,a0
    80000108:	84ae                	mv	s1,a1
    8000010a:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    8000010c:	00011517          	auipc	a0,0x11
    80000110:	06450513          	addi	a0,a0,100 # 80011170 <cons>
    80000114:	00001097          	auipc	ra,0x1
    80000118:	c1a080e7          	jalr	-998(ra) # 80000d2e <acquire>
  for(i = 0; i < n; i++){
    8000011c:	05305b63          	blez	s3,80000172 <consolewrite+0x7e>
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	710080e7          	jalr	1808(ra) # 8000283e <either_copyin>
    80000136:	01550c63          	beq	a0,s5,8000014e <consolewrite+0x5a>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7aa080e7          	jalr	1962(ra) # 800008e8 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x30>
  }
  release(&cons.lock);
    8000014e:	00011517          	auipc	a0,0x11
    80000152:	02250513          	addi	a0,a0,34 # 80011170 <cons>
    80000156:	00001097          	auipc	ra,0x1
    8000015a:	ca8080e7          	jalr	-856(ra) # 80000dfe <release>

  return i;
}
    8000015e:	854a                	mv	a0,s2
    80000160:	60a6                	ld	ra,72(sp)
    80000162:	6406                	ld	s0,64(sp)
    80000164:	74e2                	ld	s1,56(sp)
    80000166:	7942                	ld	s2,48(sp)
    80000168:	79a2                	ld	s3,40(sp)
    8000016a:	7a02                	ld	s4,32(sp)
    8000016c:	6ae2                	ld	s5,24(sp)
    8000016e:	6161                	addi	sp,sp,80
    80000170:	8082                	ret
  for(i = 0; i < n; i++){
    80000172:	4901                	li	s2,0
    80000174:	bfe9                	j	8000014e <consolewrite+0x5a>

0000000080000176 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000176:	7119                	addi	sp,sp,-128
    80000178:	fc86                	sd	ra,120(sp)
    8000017a:	f8a2                	sd	s0,112(sp)
    8000017c:	f4a6                	sd	s1,104(sp)
    8000017e:	f0ca                	sd	s2,96(sp)
    80000180:	ecce                	sd	s3,88(sp)
    80000182:	e8d2                	sd	s4,80(sp)
    80000184:	e4d6                	sd	s5,72(sp)
    80000186:	e0da                	sd	s6,64(sp)
    80000188:	fc5e                	sd	s7,56(sp)
    8000018a:	f862                	sd	s8,48(sp)
    8000018c:	f466                	sd	s9,40(sp)
    8000018e:	f06a                	sd	s10,32(sp)
    80000190:	ec6e                	sd	s11,24(sp)
    80000192:	0100                	addi	s0,sp,128
    80000194:	8b2a                	mv	s6,a0
    80000196:	8aae                	mv	s5,a1
    80000198:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000019a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000019e:	00011517          	auipc	a0,0x11
    800001a2:	fd250513          	addi	a0,a0,-46 # 80011170 <cons>
    800001a6:	00001097          	auipc	ra,0x1
    800001aa:	b88080e7          	jalr	-1144(ra) # 80000d2e <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001ae:	00011497          	auipc	s1,0x11
    800001b2:	fc248493          	addi	s1,s1,-62 # 80011170 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b6:	89a6                	mv	s3,s1
    800001b8:	00011917          	auipc	s2,0x11
    800001bc:	05890913          	addi	s2,s2,88 # 80011210 <cons+0xa0>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001c0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001c2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001c4:	4da9                	li	s11,10
  while(n > 0){
    800001c6:	07405863          	blez	s4,80000236 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001ca:	0a04a783          	lw	a5,160(s1)
    800001ce:	0a44a703          	lw	a4,164(s1)
    800001d2:	02f71463          	bne	a4,a5,800001fa <consoleread+0x84>
      if(myproc()->killed){
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ba0080e7          	jalr	-1120(ra) # 80001d76 <myproc>
    800001de:	5d1c                	lw	a5,56(a0)
    800001e0:	e7b5                	bnez	a5,8000024c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001e2:	85ce                	mv	a1,s3
    800001e4:	854a                	mv	a0,s2
    800001e6:	00002097          	auipc	ra,0x2
    800001ea:	3a0080e7          	jalr	928(ra) # 80002586 <sleep>
    while(cons.r == cons.w){
    800001ee:	0a04a783          	lw	a5,160(s1)
    800001f2:	0a44a703          	lw	a4,164(s1)
    800001f6:	fef700e3          	beq	a4,a5,800001d6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001fa:	0017871b          	addiw	a4,a5,1
    800001fe:	0ae4a023          	sw	a4,160(s1)
    80000202:	07f7f713          	andi	a4,a5,127
    80000206:	9726                	add	a4,a4,s1
    80000208:	02074703          	lbu	a4,32(a4)
    8000020c:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000210:	079c0663          	beq	s8,s9,8000027c <consoleread+0x106>
    cbuf = c;
    80000214:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000218:	4685                	li	a3,1
    8000021a:	f8f40613          	addi	a2,s0,-113
    8000021e:	85d6                	mv	a1,s5
    80000220:	855a                	mv	a0,s6
    80000222:	00002097          	auipc	ra,0x2
    80000226:	5c6080e7          	jalr	1478(ra) # 800027e8 <either_copyout>
    8000022a:	01a50663          	beq	a0,s10,80000236 <consoleread+0xc0>
    dst++;
    8000022e:	0a85                	addi	s5,s5,1
    --n;
    80000230:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000232:	f9bc1ae3          	bne	s8,s11,800001c6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f3a50513          	addi	a0,a0,-198 # 80011170 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	bc0080e7          	jalr	-1088(ra) # 80000dfe <release>

  return target - n;
    80000246:	414b853b          	subw	a0,s7,s4
    8000024a:	a811                	j	8000025e <consoleread+0xe8>
        release(&cons.lock);
    8000024c:	00011517          	auipc	a0,0x11
    80000250:	f2450513          	addi	a0,a0,-220 # 80011170 <cons>
    80000254:	00001097          	auipc	ra,0x1
    80000258:	baa080e7          	jalr	-1110(ra) # 80000dfe <release>
        return -1;
    8000025c:	557d                	li	a0,-1
}
    8000025e:	70e6                	ld	ra,120(sp)
    80000260:	7446                	ld	s0,112(sp)
    80000262:	74a6                	ld	s1,104(sp)
    80000264:	7906                	ld	s2,96(sp)
    80000266:	69e6                	ld	s3,88(sp)
    80000268:	6a46                	ld	s4,80(sp)
    8000026a:	6aa6                	ld	s5,72(sp)
    8000026c:	6b06                	ld	s6,64(sp)
    8000026e:	7be2                	ld	s7,56(sp)
    80000270:	7c42                	ld	s8,48(sp)
    80000272:	7ca2                	ld	s9,40(sp)
    80000274:	7d02                	ld	s10,32(sp)
    80000276:	6de2                	ld	s11,24(sp)
    80000278:	6109                	addi	sp,sp,128
    8000027a:	8082                	ret
      if(n < target){
    8000027c:	000a071b          	sext.w	a4,s4
    80000280:	fb777be3          	bgeu	a4,s7,80000236 <consoleread+0xc0>
        cons.r--;
    80000284:	00011717          	auipc	a4,0x11
    80000288:	f8f72623          	sw	a5,-116(a4) # 80011210 <cons+0xa0>
    8000028c:	b76d                	j	80000236 <consoleread+0xc0>

000000008000028e <consputc>:
{
    8000028e:	1141                	addi	sp,sp,-16
    80000290:	e406                	sd	ra,8(sp)
    80000292:	e022                	sd	s0,0(sp)
    80000294:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000296:	10000793          	li	a5,256
    8000029a:	00f50a63          	beq	a0,a5,800002ae <consputc+0x20>
    uartputc_sync(c);
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	564080e7          	jalr	1380(ra) # 80000802 <uartputc_sync>
}
    800002a6:	60a2                	ld	ra,8(sp)
    800002a8:	6402                	ld	s0,0(sp)
    800002aa:	0141                	addi	sp,sp,16
    800002ac:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	552080e7          	jalr	1362(ra) # 80000802 <uartputc_sync>
    800002b8:	02000513          	li	a0,32
    800002bc:	00000097          	auipc	ra,0x0
    800002c0:	546080e7          	jalr	1350(ra) # 80000802 <uartputc_sync>
    800002c4:	4521                	li	a0,8
    800002c6:	00000097          	auipc	ra,0x0
    800002ca:	53c080e7          	jalr	1340(ra) # 80000802 <uartputc_sync>
    800002ce:	bfe1                	j	800002a6 <consputc+0x18>

00000000800002d0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d0:	1101                	addi	sp,sp,-32
    800002d2:	ec06                	sd	ra,24(sp)
    800002d4:	e822                	sd	s0,16(sp)
    800002d6:	e426                	sd	s1,8(sp)
    800002d8:	e04a                	sd	s2,0(sp)
    800002da:	1000                	addi	s0,sp,32
    800002dc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002de:	00011517          	auipc	a0,0x11
    800002e2:	e9250513          	addi	a0,a0,-366 # 80011170 <cons>
    800002e6:	00001097          	auipc	ra,0x1
    800002ea:	a48080e7          	jalr	-1464(ra) # 80000d2e <acquire>

  switch(c){
    800002ee:	47d5                	li	a5,21
    800002f0:	0af48663          	beq	s1,a5,8000039c <consoleintr+0xcc>
    800002f4:	0297ca63          	blt	a5,s1,80000328 <consoleintr+0x58>
    800002f8:	47a1                	li	a5,8
    800002fa:	0ef48763          	beq	s1,a5,800003e8 <consoleintr+0x118>
    800002fe:	47c1                	li	a5,16
    80000300:	10f49a63          	bne	s1,a5,80000414 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    80000304:	00002097          	auipc	ra,0x2
    80000308:	590080e7          	jalr	1424(ra) # 80002894 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000030c:	00011517          	auipc	a0,0x11
    80000310:	e6450513          	addi	a0,a0,-412 # 80011170 <cons>
    80000314:	00001097          	auipc	ra,0x1
    80000318:	aea080e7          	jalr	-1302(ra) # 80000dfe <release>
}
    8000031c:	60e2                	ld	ra,24(sp)
    8000031e:	6442                	ld	s0,16(sp)
    80000320:	64a2                	ld	s1,8(sp)
    80000322:	6902                	ld	s2,0(sp)
    80000324:	6105                	addi	sp,sp,32
    80000326:	8082                	ret
  switch(c){
    80000328:	07f00793          	li	a5,127
    8000032c:	0af48e63          	beq	s1,a5,800003e8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000330:	00011717          	auipc	a4,0x11
    80000334:	e4070713          	addi	a4,a4,-448 # 80011170 <cons>
    80000338:	0a872783          	lw	a5,168(a4)
    8000033c:	0a072703          	lw	a4,160(a4)
    80000340:	9f99                	subw	a5,a5,a4
    80000342:	07f00713          	li	a4,127
    80000346:	fcf763e3          	bltu	a4,a5,8000030c <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000034a:	47b5                	li	a5,13
    8000034c:	0cf48763          	beq	s1,a5,8000041a <consoleintr+0x14a>
      consputc(c);
    80000350:	8526                	mv	a0,s1
    80000352:	00000097          	auipc	ra,0x0
    80000356:	f3c080e7          	jalr	-196(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000035a:	00011797          	auipc	a5,0x11
    8000035e:	e1678793          	addi	a5,a5,-490 # 80011170 <cons>
    80000362:	0a87a703          	lw	a4,168(a5)
    80000366:	0017069b          	addiw	a3,a4,1
    8000036a:	0006861b          	sext.w	a2,a3
    8000036e:	0ad7a423          	sw	a3,168(a5)
    80000372:	07f77713          	andi	a4,a4,127
    80000376:	97ba                	add	a5,a5,a4
    80000378:	02978023          	sb	s1,32(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000037c:	47a9                	li	a5,10
    8000037e:	0cf48563          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000382:	4791                	li	a5,4
    80000384:	0cf48263          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000388:	00011797          	auipc	a5,0x11
    8000038c:	e887a783          	lw	a5,-376(a5) # 80011210 <cons+0xa0>
    80000390:	0807879b          	addiw	a5,a5,128
    80000394:	f6f61ce3          	bne	a2,a5,8000030c <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000398:	863e                	mv	a2,a5
    8000039a:	a07d                	j	80000448 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000039c:	00011717          	auipc	a4,0x11
    800003a0:	dd470713          	addi	a4,a4,-556 # 80011170 <cons>
    800003a4:	0a872783          	lw	a5,168(a4)
    800003a8:	0a472703          	lw	a4,164(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	00011497          	auipc	s1,0x11
    800003b0:	dc448493          	addi	s1,s1,-572 # 80011170 <cons>
    while(cons.e != cons.w &&
    800003b4:	4929                	li	s2,10
    800003b6:	f4f70be3          	beq	a4,a5,8000030c <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ba:	37fd                	addiw	a5,a5,-1
    800003bc:	07f7f713          	andi	a4,a5,127
    800003c0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c2:	02074703          	lbu	a4,32(a4)
    800003c6:	f52703e3          	beq	a4,s2,8000030c <consoleintr+0x3c>
      cons.e--;
    800003ca:	0af4a423          	sw	a5,168(s1)
      consputc(BACKSPACE);
    800003ce:	10000513          	li	a0,256
    800003d2:	00000097          	auipc	ra,0x0
    800003d6:	ebc080e7          	jalr	-324(ra) # 8000028e <consputc>
    while(cons.e != cons.w &&
    800003da:	0a84a783          	lw	a5,168(s1)
    800003de:	0a44a703          	lw	a4,164(s1)
    800003e2:	fcf71ce3          	bne	a4,a5,800003ba <consoleintr+0xea>
    800003e6:	b71d                	j	8000030c <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	d8870713          	addi	a4,a4,-632 # 80011170 <cons>
    800003f0:	0a872783          	lw	a5,168(a4)
    800003f4:	0a472703          	lw	a4,164(a4)
    800003f8:	f0f70ae3          	beq	a4,a5,8000030c <consoleintr+0x3c>
      cons.e--;
    800003fc:	37fd                	addiw	a5,a5,-1
    800003fe:	00011717          	auipc	a4,0x11
    80000402:	e0f72d23          	sw	a5,-486(a4) # 80011218 <cons+0xa8>
      consputc(BACKSPACE);
    80000406:	10000513          	li	a0,256
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e84080e7          	jalr	-380(ra) # 8000028e <consputc>
    80000412:	bded                	j	8000030c <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000414:	ee048ce3          	beqz	s1,8000030c <consoleintr+0x3c>
    80000418:	bf21                	j	80000330 <consoleintr+0x60>
      consputc(c);
    8000041a:	4529                	li	a0,10
    8000041c:	00000097          	auipc	ra,0x0
    80000420:	e72080e7          	jalr	-398(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000424:	00011797          	auipc	a5,0x11
    80000428:	d4c78793          	addi	a5,a5,-692 # 80011170 <cons>
    8000042c:	0a87a703          	lw	a4,168(a5)
    80000430:	0017069b          	addiw	a3,a4,1
    80000434:	0006861b          	sext.w	a2,a3
    80000438:	0ad7a423          	sw	a3,168(a5)
    8000043c:	07f77713          	andi	a4,a4,127
    80000440:	97ba                	add	a5,a5,a4
    80000442:	4729                	li	a4,10
    80000444:	02e78023          	sb	a4,32(a5)
        cons.w = cons.e;
    80000448:	00011797          	auipc	a5,0x11
    8000044c:	dcc7a623          	sw	a2,-564(a5) # 80011214 <cons+0xa4>
        wakeup(&cons.r);
    80000450:	00011517          	auipc	a0,0x11
    80000454:	dc050513          	addi	a0,a0,-576 # 80011210 <cons+0xa0>
    80000458:	00002097          	auipc	ra,0x2
    8000045c:	2b4080e7          	jalr	692(ra) # 8000270c <wakeup>
    80000460:	b575                	j	8000030c <consoleintr+0x3c>

0000000080000462 <consoleinit>:

void
consoleinit(void)
{
    80000462:	1141                	addi	sp,sp,-16
    80000464:	e406                	sd	ra,8(sp)
    80000466:	e022                	sd	s0,0(sp)
    80000468:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000046a:	00008597          	auipc	a1,0x8
    8000046e:	ba658593          	addi	a1,a1,-1114 # 80008010 <etext+0x10>
    80000472:	00011517          	auipc	a0,0x11
    80000476:	cfe50513          	addi	a0,a0,-770 # 80011170 <cons>
    8000047a:	00001097          	auipc	ra,0x1
    8000047e:	a30080e7          	jalr	-1488(ra) # 80000eaa <initlock>

  uartinit();
    80000482:	00000097          	auipc	ra,0x0
    80000486:	330080e7          	jalr	816(ra) # 800007b2 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000048a:	0002c797          	auipc	a5,0x2c
    8000048e:	c5678793          	addi	a5,a5,-938 # 8002c0e0 <devsw>
    80000492:	00000717          	auipc	a4,0x0
    80000496:	ce470713          	addi	a4,a4,-796 # 80000176 <consoleread>
    8000049a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000049c:	00000717          	auipc	a4,0x0
    800004a0:	c5870713          	addi	a4,a4,-936 # 800000f4 <consolewrite>
    800004a4:	ef98                	sd	a4,24(a5)
}
    800004a6:	60a2                	ld	ra,8(sp)
    800004a8:	6402                	ld	s0,0(sp)
    800004aa:	0141                	addi	sp,sp,16
    800004ac:	8082                	ret

00000000800004ae <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004ae:	7179                	addi	sp,sp,-48
    800004b0:	f406                	sd	ra,40(sp)
    800004b2:	f022                	sd	s0,32(sp)
    800004b4:	ec26                	sd	s1,24(sp)
    800004b6:	e84a                	sd	s2,16(sp)
    800004b8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ba:	c219                	beqz	a2,800004c0 <printint+0x12>
    800004bc:	08054663          	bltz	a0,80000548 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004c0:	2501                	sext.w	a0,a0
    800004c2:	4881                	li	a7,0
    800004c4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004ca:	2581                	sext.w	a1,a1
    800004cc:	00008617          	auipc	a2,0x8
    800004d0:	b7460613          	addi	a2,a2,-1164 # 80008040 <digits>
    800004d4:	883a                	mv	a6,a4
    800004d6:	2705                	addiw	a4,a4,1
    800004d8:	02b577bb          	remuw	a5,a0,a1
    800004dc:	1782                	slli	a5,a5,0x20
    800004de:	9381                	srli	a5,a5,0x20
    800004e0:	97b2                	add	a5,a5,a2
    800004e2:	0007c783          	lbu	a5,0(a5)
    800004e6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ea:	0005079b          	sext.w	a5,a0
    800004ee:	02b5553b          	divuw	a0,a0,a1
    800004f2:	0685                	addi	a3,a3,1
    800004f4:	feb7f0e3          	bgeu	a5,a1,800004d4 <printint+0x26>

  if(sign)
    800004f8:	00088b63          	beqz	a7,8000050e <printint+0x60>
    buf[i++] = '-';
    800004fc:	fe040793          	addi	a5,s0,-32
    80000500:	973e                	add	a4,a4,a5
    80000502:	02d00793          	li	a5,45
    80000506:	fef70823          	sb	a5,-16(a4)
    8000050a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000050e:	02e05763          	blez	a4,8000053c <printint+0x8e>
    80000512:	fd040793          	addi	a5,s0,-48
    80000516:	00e784b3          	add	s1,a5,a4
    8000051a:	fff78913          	addi	s2,a5,-1
    8000051e:	993a                	add	s2,s2,a4
    80000520:	377d                	addiw	a4,a4,-1
    80000522:	1702                	slli	a4,a4,0x20
    80000524:	9301                	srli	a4,a4,0x20
    80000526:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000052a:	fff4c503          	lbu	a0,-1(s1)
    8000052e:	00000097          	auipc	ra,0x0
    80000532:	d60080e7          	jalr	-672(ra) # 8000028e <consputc>
  while(--i >= 0)
    80000536:	14fd                	addi	s1,s1,-1
    80000538:	ff2499e3          	bne	s1,s2,8000052a <printint+0x7c>
}
    8000053c:	70a2                	ld	ra,40(sp)
    8000053e:	7402                	ld	s0,32(sp)
    80000540:	64e2                	ld	s1,24(sp)
    80000542:	6942                	ld	s2,16(sp)
    80000544:	6145                	addi	sp,sp,48
    80000546:	8082                	ret
    x = -xx;
    80000548:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000054c:	4885                	li	a7,1
    x = -xx;
    8000054e:	bf9d                	j	800004c4 <printint+0x16>

0000000080000550 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000550:	1101                	addi	sp,sp,-32
    80000552:	ec06                	sd	ra,24(sp)
    80000554:	e822                	sd	s0,16(sp)
    80000556:	e426                	sd	s1,8(sp)
    80000558:	1000                	addi	s0,sp,32
    8000055a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000055c:	00011797          	auipc	a5,0x11
    80000560:	ce07a223          	sw	zero,-796(a5) # 80011240 <pr+0x20>
  printf("panic: ");
    80000564:	00008517          	auipc	a0,0x8
    80000568:	ab450513          	addi	a0,a0,-1356 # 80008018 <etext+0x18>
    8000056c:	00000097          	auipc	ra,0x0
    80000570:	02e080e7          	jalr	46(ra) # 8000059a <printf>
  printf(s);
    80000574:	8526                	mv	a0,s1
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	024080e7          	jalr	36(ra) # 8000059a <printf>
  printf("\n");
    8000057e:	00008517          	auipc	a0,0x8
    80000582:	be250513          	addi	a0,a0,-1054 # 80008160 <digits+0x120>
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	014080e7          	jalr	20(ra) # 8000059a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000058e:	4785                	li	a5,1
    80000590:	00009717          	auipc	a4,0x9
    80000594:	a6f72823          	sw	a5,-1424(a4) # 80009000 <panicked>
  for(;;)
    80000598:	a001                	j	80000598 <panic+0x48>

000000008000059a <printf>:
{
    8000059a:	7131                	addi	sp,sp,-192
    8000059c:	fc86                	sd	ra,120(sp)
    8000059e:	f8a2                	sd	s0,112(sp)
    800005a0:	f4a6                	sd	s1,104(sp)
    800005a2:	f0ca                	sd	s2,96(sp)
    800005a4:	ecce                	sd	s3,88(sp)
    800005a6:	e8d2                	sd	s4,80(sp)
    800005a8:	e4d6                	sd	s5,72(sp)
    800005aa:	e0da                	sd	s6,64(sp)
    800005ac:	fc5e                	sd	s7,56(sp)
    800005ae:	f862                	sd	s8,48(sp)
    800005b0:	f466                	sd	s9,40(sp)
    800005b2:	f06a                	sd	s10,32(sp)
    800005b4:	ec6e                	sd	s11,24(sp)
    800005b6:	0100                	addi	s0,sp,128
    800005b8:	8a2a                	mv	s4,a0
    800005ba:	e40c                	sd	a1,8(s0)
    800005bc:	e810                	sd	a2,16(s0)
    800005be:	ec14                	sd	a3,24(s0)
    800005c0:	f018                	sd	a4,32(s0)
    800005c2:	f41c                	sd	a5,40(s0)
    800005c4:	03043823          	sd	a6,48(s0)
    800005c8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005cc:	00011d97          	auipc	s11,0x11
    800005d0:	c74dad83          	lw	s11,-908(s11) # 80011240 <pr+0x20>
  if(locking)
    800005d4:	020d9b63          	bnez	s11,8000060a <printf+0x70>
  if (fmt == 0)
    800005d8:	040a0263          	beqz	s4,8000061c <printf+0x82>
  va_start(ap, fmt);
    800005dc:	00840793          	addi	a5,s0,8
    800005e0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e4:	000a4503          	lbu	a0,0(s4)
    800005e8:	16050263          	beqz	a0,8000074c <printf+0x1b2>
    800005ec:	4481                	li	s1,0
    if(c != '%'){
    800005ee:	02500a93          	li	s5,37
    switch(c){
    800005f2:	07000b13          	li	s6,112
  consputc('x');
    800005f6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f8:	00008b97          	auipc	s7,0x8
    800005fc:	a48b8b93          	addi	s7,s7,-1464 # 80008040 <digits>
    switch(c){
    80000600:	07300c93          	li	s9,115
    80000604:	06400c13          	li	s8,100
    80000608:	a82d                	j	80000642 <printf+0xa8>
    acquire(&pr.lock);
    8000060a:	00011517          	auipc	a0,0x11
    8000060e:	c1650513          	addi	a0,a0,-1002 # 80011220 <pr>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	71c080e7          	jalr	1820(ra) # 80000d2e <acquire>
    8000061a:	bf7d                	j	800005d8 <printf+0x3e>
    panic("null fmt");
    8000061c:	00008517          	auipc	a0,0x8
    80000620:	a0c50513          	addi	a0,a0,-1524 # 80008028 <etext+0x28>
    80000624:	00000097          	auipc	ra,0x0
    80000628:	f2c080e7          	jalr	-212(ra) # 80000550 <panic>
      consputc(c);
    8000062c:	00000097          	auipc	ra,0x0
    80000630:	c62080e7          	jalr	-926(ra) # 8000028e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c503          	lbu	a0,0(a5)
    8000063e:	10050763          	beqz	a0,8000074c <printf+0x1b2>
    if(c != '%'){
    80000642:	ff5515e3          	bne	a0,s5,8000062c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000646:	2485                	addiw	s1,s1,1
    80000648:	009a07b3          	add	a5,s4,s1
    8000064c:	0007c783          	lbu	a5,0(a5)
    80000650:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000654:	cfe5                	beqz	a5,8000074c <printf+0x1b2>
    switch(c){
    80000656:	05678a63          	beq	a5,s6,800006aa <printf+0x110>
    8000065a:	02fb7663          	bgeu	s6,a5,80000686 <printf+0xec>
    8000065e:	09978963          	beq	a5,s9,800006f0 <printf+0x156>
    80000662:	07800713          	li	a4,120
    80000666:	0ce79863          	bne	a5,a4,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000066a:	f8843783          	ld	a5,-120(s0)
    8000066e:	00878713          	addi	a4,a5,8
    80000672:	f8e43423          	sd	a4,-120(s0)
    80000676:	4605                	li	a2,1
    80000678:	85ea                	mv	a1,s10
    8000067a:	4388                	lw	a0,0(a5)
    8000067c:	00000097          	auipc	ra,0x0
    80000680:	e32080e7          	jalr	-462(ra) # 800004ae <printint>
      break;
    80000684:	bf45                	j	80000634 <printf+0x9a>
    switch(c){
    80000686:	0b578263          	beq	a5,s5,8000072a <printf+0x190>
    8000068a:	0b879663          	bne	a5,s8,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	45a9                	li	a1,10
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e0e080e7          	jalr	-498(ra) # 800004ae <printint>
      break;
    800006a8:	b771                	j	80000634 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006aa:	f8843783          	ld	a5,-120(s0)
    800006ae:	00878713          	addi	a4,a5,8
    800006b2:	f8e43423          	sd	a4,-120(s0)
    800006b6:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ba:	03000513          	li	a0,48
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bd0080e7          	jalr	-1072(ra) # 8000028e <consputc>
  consputc('x');
    800006c6:	07800513          	li	a0,120
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bc4080e7          	jalr	-1084(ra) # 8000028e <consputc>
    800006d2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d4:	03c9d793          	srli	a5,s3,0x3c
    800006d8:	97de                	add	a5,a5,s7
    800006da:	0007c503          	lbu	a0,0(a5)
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	bb0080e7          	jalr	-1104(ra) # 8000028e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e6:	0992                	slli	s3,s3,0x4
    800006e8:	397d                	addiw	s2,s2,-1
    800006ea:	fe0915e3          	bnez	s2,800006d4 <printf+0x13a>
    800006ee:	b799                	j	80000634 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006f0:	f8843783          	ld	a5,-120(s0)
    800006f4:	00878713          	addi	a4,a5,8
    800006f8:	f8e43423          	sd	a4,-120(s0)
    800006fc:	0007b903          	ld	s2,0(a5)
    80000700:	00090e63          	beqz	s2,8000071c <printf+0x182>
      for(; *s; s++)
    80000704:	00094503          	lbu	a0,0(s2)
    80000708:	d515                	beqz	a0,80000634 <printf+0x9a>
        consputc(*s);
    8000070a:	00000097          	auipc	ra,0x0
    8000070e:	b84080e7          	jalr	-1148(ra) # 8000028e <consputc>
      for(; *s; s++)
    80000712:	0905                	addi	s2,s2,1
    80000714:	00094503          	lbu	a0,0(s2)
    80000718:	f96d                	bnez	a0,8000070a <printf+0x170>
    8000071a:	bf29                	j	80000634 <printf+0x9a>
        s = "(null)";
    8000071c:	00008917          	auipc	s2,0x8
    80000720:	90490913          	addi	s2,s2,-1788 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000724:	02800513          	li	a0,40
    80000728:	b7cd                	j	8000070a <printf+0x170>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b62080e7          	jalr	-1182(ra) # 8000028e <consputc>
      break;
    80000734:	b701                	j	80000634 <printf+0x9a>
      consputc('%');
    80000736:	8556                	mv	a0,s5
    80000738:	00000097          	auipc	ra,0x0
    8000073c:	b56080e7          	jalr	-1194(ra) # 8000028e <consputc>
      consputc(c);
    80000740:	854a                	mv	a0,s2
    80000742:	00000097          	auipc	ra,0x0
    80000746:	b4c080e7          	jalr	-1204(ra) # 8000028e <consputc>
      break;
    8000074a:	b5ed                	j	80000634 <printf+0x9a>
  if(locking)
    8000074c:	020d9163          	bnez	s11,8000076e <printf+0x1d4>
}
    80000750:	70e6                	ld	ra,120(sp)
    80000752:	7446                	ld	s0,112(sp)
    80000754:	74a6                	ld	s1,104(sp)
    80000756:	7906                	ld	s2,96(sp)
    80000758:	69e6                	ld	s3,88(sp)
    8000075a:	6a46                	ld	s4,80(sp)
    8000075c:	6aa6                	ld	s5,72(sp)
    8000075e:	6b06                	ld	s6,64(sp)
    80000760:	7be2                	ld	s7,56(sp)
    80000762:	7c42                	ld	s8,48(sp)
    80000764:	7ca2                	ld	s9,40(sp)
    80000766:	7d02                	ld	s10,32(sp)
    80000768:	6de2                	ld	s11,24(sp)
    8000076a:	6129                	addi	sp,sp,192
    8000076c:	8082                	ret
    release(&pr.lock);
    8000076e:	00011517          	auipc	a0,0x11
    80000772:	ab250513          	addi	a0,a0,-1358 # 80011220 <pr>
    80000776:	00000097          	auipc	ra,0x0
    8000077a:	688080e7          	jalr	1672(ra) # 80000dfe <release>
}
    8000077e:	bfc9                	j	80000750 <printf+0x1b6>

0000000080000780 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000780:	1101                	addi	sp,sp,-32
    80000782:	ec06                	sd	ra,24(sp)
    80000784:	e822                	sd	s0,16(sp)
    80000786:	e426                	sd	s1,8(sp)
    80000788:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000078a:	00011497          	auipc	s1,0x11
    8000078e:	a9648493          	addi	s1,s1,-1386 # 80011220 <pr>
    80000792:	00008597          	auipc	a1,0x8
    80000796:	8a658593          	addi	a1,a1,-1882 # 80008038 <etext+0x38>
    8000079a:	8526                	mv	a0,s1
    8000079c:	00000097          	auipc	ra,0x0
    800007a0:	70e080e7          	jalr	1806(ra) # 80000eaa <initlock>
  pr.locking = 1;
    800007a4:	4785                	li	a5,1
    800007a6:	d09c                	sw	a5,32(s1)
}
    800007a8:	60e2                	ld	ra,24(sp)
    800007aa:	6442                	ld	s0,16(sp)
    800007ac:	64a2                	ld	s1,8(sp)
    800007ae:	6105                	addi	sp,sp,32
    800007b0:	8082                	ret

00000000800007b2 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007b2:	1141                	addi	sp,sp,-16
    800007b4:	e406                	sd	ra,8(sp)
    800007b6:	e022                	sd	s0,0(sp)
    800007b8:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ba:	100007b7          	lui	a5,0x10000
    800007be:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007c2:	f8000713          	li	a4,-128
    800007c6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ca:	470d                	li	a4,3
    800007cc:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007d0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007d4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d8:	469d                	li	a3,7
    800007da:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007de:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007e2:	00008597          	auipc	a1,0x8
    800007e6:	87658593          	addi	a1,a1,-1930 # 80008058 <digits+0x18>
    800007ea:	00011517          	auipc	a0,0x11
    800007ee:	a5e50513          	addi	a0,a0,-1442 # 80011248 <uart_tx_lock>
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	6b8080e7          	jalr	1720(ra) # 80000eaa <initlock>
}
    800007fa:	60a2                	ld	ra,8(sp)
    800007fc:	6402                	ld	s0,0(sp)
    800007fe:	0141                	addi	sp,sp,16
    80000800:	8082                	ret

0000000080000802 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000802:	1101                	addi	sp,sp,-32
    80000804:	ec06                	sd	ra,24(sp)
    80000806:	e822                	sd	s0,16(sp)
    80000808:	e426                	sd	s1,8(sp)
    8000080a:	1000                	addi	s0,sp,32
    8000080c:	84aa                	mv	s1,a0
  push_off();
    8000080e:	00000097          	auipc	ra,0x0
    80000812:	4d4080e7          	jalr	1236(ra) # 80000ce2 <push_off>

  if(panicked){
    80000816:	00008797          	auipc	a5,0x8
    8000081a:	7ea7a783          	lw	a5,2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000822:	c391                	beqz	a5,80000826 <uartputc_sync+0x24>
    for(;;)
    80000824:	a001                	j	80000824 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000826:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000082a:	0ff7f793          	andi	a5,a5,255
    8000082e:	0207f793          	andi	a5,a5,32
    80000832:	dbf5                	beqz	a5,80000826 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000834:	0ff4f793          	andi	a5,s1,255
    80000838:	10000737          	lui	a4,0x10000
    8000083c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000840:	00000097          	auipc	ra,0x0
    80000844:	55e080e7          	jalr	1374(ra) # 80000d9e <pop_off>
}
    80000848:	60e2                	ld	ra,24(sp)
    8000084a:	6442                	ld	s0,16(sp)
    8000084c:	64a2                	ld	s1,8(sp)
    8000084e:	6105                	addi	sp,sp,32
    80000850:	8082                	ret

0000000080000852 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000852:	00008797          	auipc	a5,0x8
    80000856:	7b27a783          	lw	a5,1970(a5) # 80009004 <uart_tx_r>
    8000085a:	00008717          	auipc	a4,0x8
    8000085e:	7ae72703          	lw	a4,1966(a4) # 80009008 <uart_tx_w>
    80000862:	08f70263          	beq	a4,a5,800008e6 <uartstart+0x94>
{
    80000866:	7139                	addi	sp,sp,-64
    80000868:	fc06                	sd	ra,56(sp)
    8000086a:	f822                	sd	s0,48(sp)
    8000086c:	f426                	sd	s1,40(sp)
    8000086e:	f04a                	sd	s2,32(sp)
    80000870:	ec4e                	sd	s3,24(sp)
    80000872:	e852                	sd	s4,16(sp)
    80000874:	e456                	sd	s5,8(sp)
    80000876:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    8000087c:	00011a17          	auipc	s4,0x11
    80000880:	9cca0a13          	addi	s4,s4,-1588 # 80011248 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000884:	00008497          	auipc	s1,0x8
    80000888:	78048493          	addi	s1,s1,1920 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000088c:	00008997          	auipc	s3,0x8
    80000890:	77c98993          	addi	s3,s3,1916 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000894:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000898:	0ff77713          	andi	a4,a4,255
    8000089c:	02077713          	andi	a4,a4,32
    800008a0:	cb15                	beqz	a4,800008d4 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008a2:	00fa0733          	add	a4,s4,a5
    800008a6:	02074a83          	lbu	s5,32(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008aa:	2785                	addiw	a5,a5,1
    800008ac:	41f7d71b          	sraiw	a4,a5,0x1f
    800008b0:	01b7571b          	srliw	a4,a4,0x1b
    800008b4:	9fb9                	addw	a5,a5,a4
    800008b6:	8bfd                	andi	a5,a5,31
    800008b8:	9f99                	subw	a5,a5,a4
    800008ba:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008bc:	8526                	mv	a0,s1
    800008be:	00002097          	auipc	ra,0x2
    800008c2:	e4e080e7          	jalr	-434(ra) # 8000270c <wakeup>
    
    WriteReg(THR, c);
    800008c6:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ca:	409c                	lw	a5,0(s1)
    800008cc:	0009a703          	lw	a4,0(s3)
    800008d0:	fcf712e3          	bne	a4,a5,80000894 <uartstart+0x42>
  }
}
    800008d4:	70e2                	ld	ra,56(sp)
    800008d6:	7442                	ld	s0,48(sp)
    800008d8:	74a2                	ld	s1,40(sp)
    800008da:	7902                	ld	s2,32(sp)
    800008dc:	69e2                	ld	s3,24(sp)
    800008de:	6a42                	ld	s4,16(sp)
    800008e0:	6aa2                	ld	s5,8(sp)
    800008e2:	6121                	addi	sp,sp,64
    800008e4:	8082                	ret
    800008e6:	8082                	ret

00000000800008e8 <uartputc>:
{
    800008e8:	7179                	addi	sp,sp,-48
    800008ea:	f406                	sd	ra,40(sp)
    800008ec:	f022                	sd	s0,32(sp)
    800008ee:	ec26                	sd	s1,24(sp)
    800008f0:	e84a                	sd	s2,16(sp)
    800008f2:	e44e                	sd	s3,8(sp)
    800008f4:	e052                	sd	s4,0(sp)
    800008f6:	1800                	addi	s0,sp,48
    800008f8:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008fa:	00011517          	auipc	a0,0x11
    800008fe:	94e50513          	addi	a0,a0,-1714 # 80011248 <uart_tx_lock>
    80000902:	00000097          	auipc	ra,0x0
    80000906:	42c080e7          	jalr	1068(ra) # 80000d2e <acquire>
  if(panicked){
    8000090a:	00008797          	auipc	a5,0x8
    8000090e:	6f67a783          	lw	a5,1782(a5) # 80009000 <panicked>
    80000912:	c391                	beqz	a5,80000916 <uartputc+0x2e>
    for(;;)
    80000914:	a001                	j	80000914 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000916:	00008717          	auipc	a4,0x8
    8000091a:	6f272703          	lw	a4,1778(a4) # 80009008 <uart_tx_w>
    8000091e:	0017079b          	addiw	a5,a4,1
    80000922:	41f7d69b          	sraiw	a3,a5,0x1f
    80000926:	01b6d69b          	srliw	a3,a3,0x1b
    8000092a:	9fb5                	addw	a5,a5,a3
    8000092c:	8bfd                	andi	a5,a5,31
    8000092e:	9f95                	subw	a5,a5,a3
    80000930:	00008697          	auipc	a3,0x8
    80000934:	6d46a683          	lw	a3,1748(a3) # 80009004 <uart_tx_r>
    80000938:	04f69263          	bne	a3,a5,8000097c <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000093c:	00011a17          	auipc	s4,0x11
    80000940:	90ca0a13          	addi	s4,s4,-1780 # 80011248 <uart_tx_lock>
    80000944:	00008497          	auipc	s1,0x8
    80000948:	6c048493          	addi	s1,s1,1728 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000094c:	00008917          	auipc	s2,0x8
    80000950:	6bc90913          	addi	s2,s2,1724 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000954:	85d2                	mv	a1,s4
    80000956:	8526                	mv	a0,s1
    80000958:	00002097          	auipc	ra,0x2
    8000095c:	c2e080e7          	jalr	-978(ra) # 80002586 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000960:	00092703          	lw	a4,0(s2)
    80000964:	0017079b          	addiw	a5,a4,1
    80000968:	41f7d69b          	sraiw	a3,a5,0x1f
    8000096c:	01b6d69b          	srliw	a3,a3,0x1b
    80000970:	9fb5                	addw	a5,a5,a3
    80000972:	8bfd                	andi	a5,a5,31
    80000974:	9f95                	subw	a5,a5,a3
    80000976:	4094                	lw	a3,0(s1)
    80000978:	fcf68ee3          	beq	a3,a5,80000954 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    8000097c:	00011497          	auipc	s1,0x11
    80000980:	8cc48493          	addi	s1,s1,-1844 # 80011248 <uart_tx_lock>
    80000984:	9726                	add	a4,a4,s1
    80000986:	03370023          	sb	s3,32(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    8000098a:	00008717          	auipc	a4,0x8
    8000098e:	66f72f23          	sw	a5,1662(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000992:	00000097          	auipc	ra,0x0
    80000996:	ec0080e7          	jalr	-320(ra) # 80000852 <uartstart>
      release(&uart_tx_lock);
    8000099a:	8526                	mv	a0,s1
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	462080e7          	jalr	1122(ra) # 80000dfe <release>
}
    800009a4:	70a2                	ld	ra,40(sp)
    800009a6:	7402                	ld	s0,32(sp)
    800009a8:	64e2                	ld	s1,24(sp)
    800009aa:	6942                	ld	s2,16(sp)
    800009ac:	69a2                	ld	s3,8(sp)
    800009ae:	6a02                	ld	s4,0(sp)
    800009b0:	6145                	addi	sp,sp,48
    800009b2:	8082                	ret

00000000800009b4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009b4:	1141                	addi	sp,sp,-16
    800009b6:	e422                	sd	s0,8(sp)
    800009b8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009c2:	8b85                	andi	a5,a5,1
    800009c4:	cb91                	beqz	a5,800009d8 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009c6:	100007b7          	lui	a5,0x10000
    800009ca:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009ce:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009d2:	6422                	ld	s0,8(sp)
    800009d4:	0141                	addi	sp,sp,16
    800009d6:	8082                	ret
    return -1;
    800009d8:	557d                	li	a0,-1
    800009da:	bfe5                	j	800009d2 <uartgetc+0x1e>

00000000800009dc <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009dc:	1101                	addi	sp,sp,-32
    800009de:	ec06                	sd	ra,24(sp)
    800009e0:	e822                	sd	s0,16(sp)
    800009e2:	e426                	sd	s1,8(sp)
    800009e4:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009e6:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	fcc080e7          	jalr	-52(ra) # 800009b4 <uartgetc>
    if(c == -1)
    800009f0:	00950763          	beq	a0,s1,800009fe <uartintr+0x22>
      break;
    consoleintr(c);
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	8dc080e7          	jalr	-1828(ra) # 800002d0 <consoleintr>
  while(1){
    800009fc:	b7f5                	j	800009e8 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009fe:	00011497          	auipc	s1,0x11
    80000a02:	84a48493          	addi	s1,s1,-1974 # 80011248 <uart_tx_lock>
    80000a06:	8526                	mv	a0,s1
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	326080e7          	jalr	806(ra) # 80000d2e <acquire>
  uartstart();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	e42080e7          	jalr	-446(ra) # 80000852 <uartstart>
  release(&uart_tx_lock);
    80000a18:	8526                	mv	a0,s1
    80000a1a:	00000097          	auipc	ra,0x0
    80000a1e:	3e4080e7          	jalr	996(ra) # 80000dfe <release>
}
    80000a22:	60e2                	ld	ra,24(sp)
    80000a24:	6442                	ld	s0,16(sp)
    80000a26:	64a2                	ld	s1,8(sp)
    80000a28:	6105                	addi	sp,sp,32
    80000a2a:	8082                	ret

0000000080000a2c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a2c:	7139                	addi	sp,sp,-64
    80000a2e:	fc06                	sd	ra,56(sp)
    80000a30:	f822                	sd	s0,48(sp)
    80000a32:	f426                	sd	s1,40(sp)
    80000a34:	f04a                	sd	s2,32(sp)
    80000a36:	ec4e                	sd	s3,24(sp)
    80000a38:	e852                	sd	s4,16(sp)
    80000a3a:	e456                	sd	s5,8(sp)
    80000a3c:	0080                	addi	s0,sp,64
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a3e:	03451793          	slli	a5,a0,0x34
    80000a42:	e3d1                	bnez	a5,80000ac6 <kfree+0x9a>
    80000a44:	84aa                	mv	s1,a0
    80000a46:	00031797          	auipc	a5,0x31
    80000a4a:	5e278793          	addi	a5,a5,1506 # 80032028 <end>
    80000a4e:	06f56c63          	bltu	a0,a5,80000ac6 <kfree+0x9a>
    80000a52:	47c5                	li	a5,17
    80000a54:	07ee                	slli	a5,a5,0x1b
    80000a56:	06f57863          	bgeu	a0,a5,80000ac6 <kfree+0x9a>
    panic("kfree");

  push_off();
    80000a5a:	00000097          	auipc	ra,0x0
    80000a5e:	288080e7          	jalr	648(ra) # 80000ce2 <push_off>
  int cpu = cpuid();
    80000a62:	00001097          	auipc	ra,0x1
    80000a66:	2e8080e7          	jalr	744(ra) # 80001d4a <cpuid>
    80000a6a:	8a2a                	mv	s4,a0
  memset(pa, 1, PGSIZE);
    80000a6c:	6605                	lui	a2,0x1
    80000a6e:	4585                	li	a1,1
    80000a70:	8526                	mv	a0,s1
    80000a72:	00000097          	auipc	ra,0x0
    80000a76:	69c080e7          	jalr	1692(ra) # 8000110e <memset>
  r = (struct run*)pa;
  // --- critical session ---
  acquire(&kmem[cpu].lock);
    80000a7a:	00011a97          	auipc	s5,0x11
    80000a7e:	80ea8a93          	addi	s5,s5,-2034 # 80011288 <kmem>
    80000a82:	002a1993          	slli	s3,s4,0x2
    80000a86:	01498933          	add	s2,s3,s4
    80000a8a:	090e                	slli	s2,s2,0x3
    80000a8c:	9956                	add	s2,s2,s5
    80000a8e:	854a                	mv	a0,s2
    80000a90:	00000097          	auipc	ra,0x0
    80000a94:	29e080e7          	jalr	670(ra) # 80000d2e <acquire>
  r->next = kmem[cpu].freelist;
    80000a98:	02093783          	ld	a5,32(s2)
    80000a9c:	e09c                	sd	a5,0(s1)
  kmem[cpu].freelist = r;
    80000a9e:	02993023          	sd	s1,32(s2)
  release(&kmem[cpu].lock);
    80000aa2:	854a                	mv	a0,s2
    80000aa4:	00000097          	auipc	ra,0x0
    80000aa8:	35a080e7          	jalr	858(ra) # 80000dfe <release>
  // --- end of critical session ---
  pop_off();
    80000aac:	00000097          	auipc	ra,0x0
    80000ab0:	2f2080e7          	jalr	754(ra) # 80000d9e <pop_off>
}
    80000ab4:	70e2                	ld	ra,56(sp)
    80000ab6:	7442                	ld	s0,48(sp)
    80000ab8:	74a2                	ld	s1,40(sp)
    80000aba:	7902                	ld	s2,32(sp)
    80000abc:	69e2                	ld	s3,24(sp)
    80000abe:	6a42                	ld	s4,16(sp)
    80000ac0:	6aa2                	ld	s5,8(sp)
    80000ac2:	6121                	addi	sp,sp,64
    80000ac4:	8082                	ret
    panic("kfree");
    80000ac6:	00007517          	auipc	a0,0x7
    80000aca:	59a50513          	addi	a0,a0,1434 # 80008060 <digits+0x20>
    80000ace:	00000097          	auipc	ra,0x0
    80000ad2:	a82080e7          	jalr	-1406(ra) # 80000550 <panic>

0000000080000ad6 <freerange>:
{
    80000ad6:	7179                	addi	sp,sp,-48
    80000ad8:	f406                	sd	ra,40(sp)
    80000ada:	f022                	sd	s0,32(sp)
    80000adc:	ec26                	sd	s1,24(sp)
    80000ade:	e84a                	sd	s2,16(sp)
    80000ae0:	e44e                	sd	s3,8(sp)
    80000ae2:	e052                	sd	s4,0(sp)
    80000ae4:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae6:	6785                	lui	a5,0x1
    80000ae8:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000aec:	94aa                	add	s1,s1,a0
    80000aee:	757d                	lui	a0,0xfffff
    80000af0:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af2:	94be                	add	s1,s1,a5
    80000af4:	0095ee63          	bltu	a1,s1,80000b10 <freerange+0x3a>
    80000af8:	892e                	mv	s2,a1
    kfree(p);
    80000afa:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000afc:	6985                	lui	s3,0x1
    kfree(p);
    80000afe:	01448533          	add	a0,s1,s4
    80000b02:	00000097          	auipc	ra,0x0
    80000b06:	f2a080e7          	jalr	-214(ra) # 80000a2c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b0a:	94ce                	add	s1,s1,s3
    80000b0c:	fe9979e3          	bgeu	s2,s1,80000afe <freerange+0x28>
}
    80000b10:	70a2                	ld	ra,40(sp)
    80000b12:	7402                	ld	s0,32(sp)
    80000b14:	64e2                	ld	s1,24(sp)
    80000b16:	6942                	ld	s2,16(sp)
    80000b18:	69a2                	ld	s3,8(sp)
    80000b1a:	6a02                	ld	s4,0(sp)
    80000b1c:	6145                	addi	sp,sp,48
    80000b1e:	8082                	ret

0000000080000b20 <kinit>:
{
    80000b20:	7179                	addi	sp,sp,-48
    80000b22:	f406                	sd	ra,40(sp)
    80000b24:	f022                	sd	s0,32(sp)
    80000b26:	ec26                	sd	s1,24(sp)
    80000b28:	e84a                	sd	s2,16(sp)
    80000b2a:	e44e                	sd	s3,8(sp)
    80000b2c:	1800                	addi	s0,sp,48
  for (int i = 0; i < NCPU; i++) {
    80000b2e:	00010497          	auipc	s1,0x10
    80000b32:	75a48493          	addi	s1,s1,1882 # 80011288 <kmem>
    80000b36:	00011997          	auipc	s3,0x11
    80000b3a:	89298993          	addi	s3,s3,-1902 # 800113c8 <lock_locks>
    initlock(&kmem[i].lock, "kmem");
    80000b3e:	00007917          	auipc	s2,0x7
    80000b42:	52a90913          	addi	s2,s2,1322 # 80008068 <digits+0x28>
    80000b46:	85ca                	mv	a1,s2
    80000b48:	8526                	mv	a0,s1
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	360080e7          	jalr	864(ra) # 80000eaa <initlock>
  for (int i = 0; i < NCPU; i++) {
    80000b52:	02848493          	addi	s1,s1,40
    80000b56:	ff3498e3          	bne	s1,s3,80000b46 <kinit+0x26>
  freerange(end, (void*)PHYSTOP);
    80000b5a:	45c5                	li	a1,17
    80000b5c:	05ee                	slli	a1,a1,0x1b
    80000b5e:	00031517          	auipc	a0,0x31
    80000b62:	4ca50513          	addi	a0,a0,1226 # 80032028 <end>
    80000b66:	00000097          	auipc	ra,0x0
    80000b6a:	f70080e7          	jalr	-144(ra) # 80000ad6 <freerange>
}
    80000b6e:	70a2                	ld	ra,40(sp)
    80000b70:	7402                	ld	s0,32(sp)
    80000b72:	64e2                	ld	s1,24(sp)
    80000b74:	6942                	ld	s2,16(sp)
    80000b76:	69a2                	ld	s3,8(sp)
    80000b78:	6145                	addi	sp,sp,48
    80000b7a:	8082                	ret

0000000080000b7c <ksteal>:

// Try steal a free physical memory page from another core
// interrupt should already be turned off
// return NULL if not found free page
void *
ksteal(int cpu) {
    80000b7c:	7139                	addi	sp,sp,-64
    80000b7e:	fc06                	sd	ra,56(sp)
    80000b80:	f822                	sd	s0,48(sp)
    80000b82:	f426                	sd	s1,40(sp)
    80000b84:	f04a                	sd	s2,32(sp)
    80000b86:	ec4e                	sd	s3,24(sp)
    80000b88:	e852                	sd	s4,16(sp)
    80000b8a:	e456                	sd	s5,8(sp)
    80000b8c:	e05a                	sd	s6,0(sp)
    80000b8e:	0080                	addi	s0,sp,64
  struct run *r;
  for (int i = 1; i < NCPU; i++) {
    80000b90:	0015099b          	addiw	s3,a0,1
    80000b94:	00850a1b          	addiw	s4,a0,8
    int next_cpu = (cpu + i) % NCPU;
    // --- critical session ---
    acquire(&kmem[next_cpu].lock);
    80000b98:	00010a97          	auipc	s5,0x10
    80000b9c:	6f0a8a93          	addi	s5,s5,1776 # 80011288 <kmem>
    80000ba0:	a809                	j	80000bb2 <ksteal+0x36>
    r = kmem[next_cpu].freelist;
    if (r) {
      // steal one page
      kmem[next_cpu].freelist = r->next;
    }
    release(&kmem[next_cpu].lock);
    80000ba2:	8526                	mv	a0,s1
    80000ba4:	00000097          	auipc	ra,0x0
    80000ba8:	25a080e7          	jalr	602(ra) # 80000dfe <release>
  for (int i = 1; i < NCPU; i++) {
    80000bac:	2985                	addiw	s3,s3,1
    80000bae:	05498c63          	beq	s3,s4,80000c06 <ksteal+0x8a>
    int next_cpu = (cpu + i) % NCPU;
    80000bb2:	41f9d91b          	sraiw	s2,s3,0x1f
    80000bb6:	01d9579b          	srliw	a5,s2,0x1d
    80000bba:	0137893b          	addw	s2,a5,s3
    80000bbe:	00797913          	andi	s2,s2,7
    80000bc2:	40f9093b          	subw	s2,s2,a5
    acquire(&kmem[next_cpu].lock);
    80000bc6:	00291493          	slli	s1,s2,0x2
    80000bca:	94ca                	add	s1,s1,s2
    80000bcc:	048e                	slli	s1,s1,0x3
    80000bce:	94d6                	add	s1,s1,s5
    80000bd0:	8526                	mv	a0,s1
    80000bd2:	00000097          	auipc	ra,0x0
    80000bd6:	15c080e7          	jalr	348(ra) # 80000d2e <acquire>
    r = kmem[next_cpu].freelist;
    80000bda:	0204bb03          	ld	s6,32(s1)
    if (r) {
    80000bde:	fc0b02e3          	beqz	s6,80000ba2 <ksteal+0x26>
      kmem[next_cpu].freelist = r->next;
    80000be2:	000b3703          	ld	a4,0(s6)
    80000be6:	00291793          	slli	a5,s2,0x2
    80000bea:	993e                	add	s2,s2,a5
    80000bec:	090e                	slli	s2,s2,0x3
    80000bee:	00010797          	auipc	a5,0x10
    80000bf2:	69a78793          	addi	a5,a5,1690 # 80011288 <kmem>
    80000bf6:	993e                	add	s2,s2,a5
    80000bf8:	02e93023          	sd	a4,32(s2)
    release(&kmem[next_cpu].lock);
    80000bfc:	8526                	mv	a0,s1
    80000bfe:	00000097          	auipc	ra,0x0
    80000c02:	200080e7          	jalr	512(ra) # 80000dfe <release>
    if (r) {
      break;
    }
  }
  return r;
}
    80000c06:	855a                	mv	a0,s6
    80000c08:	70e2                	ld	ra,56(sp)
    80000c0a:	7442                	ld	s0,48(sp)
    80000c0c:	74a2                	ld	s1,40(sp)
    80000c0e:	7902                	ld	s2,32(sp)
    80000c10:	69e2                	ld	s3,24(sp)
    80000c12:	6a42                	ld	s4,16(sp)
    80000c14:	6aa2                	ld	s5,8(sp)
    80000c16:	6b02                	ld	s6,0(sp)
    80000c18:	6121                	addi	sp,sp,64
    80000c1a:	8082                	ret

0000000080000c1c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000c1c:	7179                	addi	sp,sp,-48
    80000c1e:	f406                	sd	ra,40(sp)
    80000c20:	f022                	sd	s0,32(sp)
    80000c22:	ec26                	sd	s1,24(sp)
    80000c24:	e84a                	sd	s2,16(sp)
    80000c26:	e44e                	sd	s3,8(sp)
    80000c28:	1800                	addi	s0,sp,48
  struct run *r;

  push_off();
    80000c2a:	00000097          	auipc	ra,0x0
    80000c2e:	0b8080e7          	jalr	184(ra) # 80000ce2 <push_off>

  int cpu = cpuid();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	118080e7          	jalr	280(ra) # 80001d4a <cpuid>
    80000c3a:	84aa                	mv	s1,a0
  // --- critical session ---
  acquire(&kmem[cpu].lock);
    80000c3c:	00251913          	slli	s2,a0,0x2
    80000c40:	992a                	add	s2,s2,a0
    80000c42:	00391793          	slli	a5,s2,0x3
    80000c46:	00010917          	auipc	s2,0x10
    80000c4a:	64290913          	addi	s2,s2,1602 # 80011288 <kmem>
    80000c4e:	993e                	add	s2,s2,a5
    80000c50:	854a                	mv	a0,s2
    80000c52:	00000097          	auipc	ra,0x0
    80000c56:	0dc080e7          	jalr	220(ra) # 80000d2e <acquire>
  r = kmem[cpu].freelist;
    80000c5a:	02093983          	ld	s3,32(s2)
  if (r) {
    80000c5e:	02098e63          	beqz	s3,80000c9a <kalloc+0x7e>
    kmem[cpu].freelist = r->next;
    80000c62:	0009b703          	ld	a4,0(s3)
    80000c66:	02e93023          	sd	a4,32(s2)
  }
  release(&kmem[cpu].lock);
    80000c6a:	854a                	mv	a0,s2
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	192080e7          	jalr	402(ra) # 80000dfe <release>
  if (r == 0) {
    r = ksteal(cpu);
  }

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c74:	6605                	lui	a2,0x1
    80000c76:	4595                	li	a1,5
    80000c78:	854e                	mv	a0,s3
    80000c7a:	00000097          	auipc	ra,0x0
    80000c7e:	494080e7          	jalr	1172(ra) # 8000110e <memset>

  pop_off();
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	11c080e7          	jalr	284(ra) # 80000d9e <pop_off>
  return (void*)r;
}
    80000c8a:	854e                	mv	a0,s3
    80000c8c:	70a2                	ld	ra,40(sp)
    80000c8e:	7402                	ld	s0,32(sp)
    80000c90:	64e2                	ld	s1,24(sp)
    80000c92:	6942                	ld	s2,16(sp)
    80000c94:	69a2                	ld	s3,8(sp)
    80000c96:	6145                	addi	sp,sp,48
    80000c98:	8082                	ret
  release(&kmem[cpu].lock);
    80000c9a:	854a                	mv	a0,s2
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	162080e7          	jalr	354(ra) # 80000dfe <release>
    r = ksteal(cpu);
    80000ca4:	8526                	mv	a0,s1
    80000ca6:	00000097          	auipc	ra,0x0
    80000caa:	ed6080e7          	jalr	-298(ra) # 80000b7c <ksteal>
    80000cae:	89aa                	mv	s3,a0
  if(r)
    80000cb0:	d969                	beqz	a0,80000c82 <kalloc+0x66>
    80000cb2:	b7c9                	j	80000c74 <kalloc+0x58>

0000000080000cb4 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000cb4:	411c                	lw	a5,0(a0)
    80000cb6:	e399                	bnez	a5,80000cbc <holding+0x8>
    80000cb8:	4501                	li	a0,0
  return r;
}
    80000cba:	8082                	ret
{
    80000cbc:	1101                	addi	sp,sp,-32
    80000cbe:	ec06                	sd	ra,24(sp)
    80000cc0:	e822                	sd	s0,16(sp)
    80000cc2:	e426                	sd	s1,8(sp)
    80000cc4:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000cc6:	6904                	ld	s1,16(a0)
    80000cc8:	00001097          	auipc	ra,0x1
    80000ccc:	092080e7          	jalr	146(ra) # 80001d5a <mycpu>
    80000cd0:	40a48533          	sub	a0,s1,a0
    80000cd4:	00153513          	seqz	a0,a0
}
    80000cd8:	60e2                	ld	ra,24(sp)
    80000cda:	6442                	ld	s0,16(sp)
    80000cdc:	64a2                	ld	s1,8(sp)
    80000cde:	6105                	addi	sp,sp,32
    80000ce0:	8082                	ret

0000000080000ce2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000ce2:	1101                	addi	sp,sp,-32
    80000ce4:	ec06                	sd	ra,24(sp)
    80000ce6:	e822                	sd	s0,16(sp)
    80000ce8:	e426                	sd	s1,8(sp)
    80000cea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cec:	100024f3          	csrr	s1,sstatus
    80000cf0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cf4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cf6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cfa:	00001097          	auipc	ra,0x1
    80000cfe:	060080e7          	jalr	96(ra) # 80001d5a <mycpu>
    80000d02:	5d3c                	lw	a5,120(a0)
    80000d04:	cf89                	beqz	a5,80000d1e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d06:	00001097          	auipc	ra,0x1
    80000d0a:	054080e7          	jalr	84(ra) # 80001d5a <mycpu>
    80000d0e:	5d3c                	lw	a5,120(a0)
    80000d10:	2785                	addiw	a5,a5,1
    80000d12:	dd3c                	sw	a5,120(a0)
}
    80000d14:	60e2                	ld	ra,24(sp)
    80000d16:	6442                	ld	s0,16(sp)
    80000d18:	64a2                	ld	s1,8(sp)
    80000d1a:	6105                	addi	sp,sp,32
    80000d1c:	8082                	ret
    mycpu()->intena = old;
    80000d1e:	00001097          	auipc	ra,0x1
    80000d22:	03c080e7          	jalr	60(ra) # 80001d5a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d26:	8085                	srli	s1,s1,0x1
    80000d28:	8885                	andi	s1,s1,1
    80000d2a:	dd64                	sw	s1,124(a0)
    80000d2c:	bfe9                	j	80000d06 <push_off+0x24>

0000000080000d2e <acquire>:
{
    80000d2e:	1101                	addi	sp,sp,-32
    80000d30:	ec06                	sd	ra,24(sp)
    80000d32:	e822                	sd	s0,16(sp)
    80000d34:	e426                	sd	s1,8(sp)
    80000d36:	1000                	addi	s0,sp,32
    80000d38:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d3a:	00000097          	auipc	ra,0x0
    80000d3e:	fa8080e7          	jalr	-88(ra) # 80000ce2 <push_off>
  if(holding(lk))
    80000d42:	8526                	mv	a0,s1
    80000d44:	00000097          	auipc	ra,0x0
    80000d48:	f70080e7          	jalr	-144(ra) # 80000cb4 <holding>
    80000d4c:	e911                	bnez	a0,80000d60 <acquire+0x32>
    __sync_fetch_and_add(&(lk->n), 1);
    80000d4e:	4785                	li	a5,1
    80000d50:	01c48713          	addi	a4,s1,28
    80000d54:	0f50000f          	fence	iorw,ow
    80000d58:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d5c:	4705                	li	a4,1
    80000d5e:	a839                	j	80000d7c <acquire+0x4e>
    panic("acquire");
    80000d60:	00007517          	auipc	a0,0x7
    80000d64:	31050513          	addi	a0,a0,784 # 80008070 <digits+0x30>
    80000d68:	fffff097          	auipc	ra,0xfffff
    80000d6c:	7e8080e7          	jalr	2024(ra) # 80000550 <panic>
    __sync_fetch_and_add(&(lk->nts), 1);
    80000d70:	01848793          	addi	a5,s1,24
    80000d74:	0f50000f          	fence	iorw,ow
    80000d78:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d7c:	87ba                	mv	a5,a4
    80000d7e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d82:	2781                	sext.w	a5,a5
    80000d84:	f7f5                	bnez	a5,80000d70 <acquire+0x42>
  __sync_synchronize();
    80000d86:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d8a:	00001097          	auipc	ra,0x1
    80000d8e:	fd0080e7          	jalr	-48(ra) # 80001d5a <mycpu>
    80000d92:	e888                	sd	a0,16(s1)
}
    80000d94:	60e2                	ld	ra,24(sp)
    80000d96:	6442                	ld	s0,16(sp)
    80000d98:	64a2                	ld	s1,8(sp)
    80000d9a:	6105                	addi	sp,sp,32
    80000d9c:	8082                	ret

0000000080000d9e <pop_off>:

void
pop_off(void)
{
    80000d9e:	1141                	addi	sp,sp,-16
    80000da0:	e406                	sd	ra,8(sp)
    80000da2:	e022                	sd	s0,0(sp)
    80000da4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000da6:	00001097          	auipc	ra,0x1
    80000daa:	fb4080e7          	jalr	-76(ra) # 80001d5a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dae:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000db2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000db4:	e78d                	bnez	a5,80000dde <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000db6:	5d3c                	lw	a5,120(a0)
    80000db8:	02f05b63          	blez	a5,80000dee <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000dbc:	37fd                	addiw	a5,a5,-1
    80000dbe:	0007871b          	sext.w	a4,a5
    80000dc2:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000dc4:	eb09                	bnez	a4,80000dd6 <pop_off+0x38>
    80000dc6:	5d7c                	lw	a5,124(a0)
    80000dc8:	c799                	beqz	a5,80000dd6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000dce:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000dd2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000dd6:	60a2                	ld	ra,8(sp)
    80000dd8:	6402                	ld	s0,0(sp)
    80000dda:	0141                	addi	sp,sp,16
    80000ddc:	8082                	ret
    panic("pop_off - interruptible");
    80000dde:	00007517          	auipc	a0,0x7
    80000de2:	29a50513          	addi	a0,a0,666 # 80008078 <digits+0x38>
    80000de6:	fffff097          	auipc	ra,0xfffff
    80000dea:	76a080e7          	jalr	1898(ra) # 80000550 <panic>
    panic("pop_off");
    80000dee:	00007517          	auipc	a0,0x7
    80000df2:	2a250513          	addi	a0,a0,674 # 80008090 <digits+0x50>
    80000df6:	fffff097          	auipc	ra,0xfffff
    80000dfa:	75a080e7          	jalr	1882(ra) # 80000550 <panic>

0000000080000dfe <release>:
{
    80000dfe:	1101                	addi	sp,sp,-32
    80000e00:	ec06                	sd	ra,24(sp)
    80000e02:	e822                	sd	s0,16(sp)
    80000e04:	e426                	sd	s1,8(sp)
    80000e06:	1000                	addi	s0,sp,32
    80000e08:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e0a:	00000097          	auipc	ra,0x0
    80000e0e:	eaa080e7          	jalr	-342(ra) # 80000cb4 <holding>
    80000e12:	c115                	beqz	a0,80000e36 <release+0x38>
  lk->cpu = 0;
    80000e14:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e18:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e1c:	0f50000f          	fence	iorw,ow
    80000e20:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e24:	00000097          	auipc	ra,0x0
    80000e28:	f7a080e7          	jalr	-134(ra) # 80000d9e <pop_off>
}
    80000e2c:	60e2                	ld	ra,24(sp)
    80000e2e:	6442                	ld	s0,16(sp)
    80000e30:	64a2                	ld	s1,8(sp)
    80000e32:	6105                	addi	sp,sp,32
    80000e34:	8082                	ret
    panic("release");
    80000e36:	00007517          	auipc	a0,0x7
    80000e3a:	26250513          	addi	a0,a0,610 # 80008098 <digits+0x58>
    80000e3e:	fffff097          	auipc	ra,0xfffff
    80000e42:	712080e7          	jalr	1810(ra) # 80000550 <panic>

0000000080000e46 <freelock>:
{
    80000e46:	1101                	addi	sp,sp,-32
    80000e48:	ec06                	sd	ra,24(sp)
    80000e4a:	e822                	sd	s0,16(sp)
    80000e4c:	e426                	sd	s1,8(sp)
    80000e4e:	1000                	addi	s0,sp,32
    80000e50:	84aa                	mv	s1,a0
  acquire(&lock_locks);
    80000e52:	00010517          	auipc	a0,0x10
    80000e56:	57650513          	addi	a0,a0,1398 # 800113c8 <lock_locks>
    80000e5a:	00000097          	auipc	ra,0x0
    80000e5e:	ed4080e7          	jalr	-300(ra) # 80000d2e <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e62:	00010717          	auipc	a4,0x10
    80000e66:	58670713          	addi	a4,a4,1414 # 800113e8 <locks>
    80000e6a:	4781                	li	a5,0
    80000e6c:	1f400613          	li	a2,500
    if(locks[i] == lk) {
    80000e70:	6314                	ld	a3,0(a4)
    80000e72:	00968763          	beq	a3,s1,80000e80 <freelock+0x3a>
  for (i = 0; i < NLOCK; i++) {
    80000e76:	2785                	addiw	a5,a5,1
    80000e78:	0721                	addi	a4,a4,8
    80000e7a:	fec79be3          	bne	a5,a2,80000e70 <freelock+0x2a>
    80000e7e:	a809                	j	80000e90 <freelock+0x4a>
      locks[i] = 0;
    80000e80:	078e                	slli	a5,a5,0x3
    80000e82:	00010717          	auipc	a4,0x10
    80000e86:	56670713          	addi	a4,a4,1382 # 800113e8 <locks>
    80000e8a:	97ba                	add	a5,a5,a4
    80000e8c:	0007b023          	sd	zero,0(a5)
  release(&lock_locks);
    80000e90:	00010517          	auipc	a0,0x10
    80000e94:	53850513          	addi	a0,a0,1336 # 800113c8 <lock_locks>
    80000e98:	00000097          	auipc	ra,0x0
    80000e9c:	f66080e7          	jalr	-154(ra) # 80000dfe <release>
}
    80000ea0:	60e2                	ld	ra,24(sp)
    80000ea2:	6442                	ld	s0,16(sp)
    80000ea4:	64a2                	ld	s1,8(sp)
    80000ea6:	6105                	addi	sp,sp,32
    80000ea8:	8082                	ret

0000000080000eaa <initlock>:
{
    80000eaa:	1101                	addi	sp,sp,-32
    80000eac:	ec06                	sd	ra,24(sp)
    80000eae:	e822                	sd	s0,16(sp)
    80000eb0:	e426                	sd	s1,8(sp)
    80000eb2:	1000                	addi	s0,sp,32
    80000eb4:	84aa                	mv	s1,a0
  lk->name = name;
    80000eb6:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000eb8:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000ebc:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80000ec0:	00052c23          	sw	zero,24(a0)
  lk->n = 0;
    80000ec4:	00052e23          	sw	zero,28(a0)
  acquire(&lock_locks);
    80000ec8:	00010517          	auipc	a0,0x10
    80000ecc:	50050513          	addi	a0,a0,1280 # 800113c8 <lock_locks>
    80000ed0:	00000097          	auipc	ra,0x0
    80000ed4:	e5e080e7          	jalr	-418(ra) # 80000d2e <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000ed8:	00010717          	auipc	a4,0x10
    80000edc:	51070713          	addi	a4,a4,1296 # 800113e8 <locks>
    80000ee0:	4781                	li	a5,0
    80000ee2:	1f400693          	li	a3,500
    if(locks[i] == 0) {
    80000ee6:	6310                	ld	a2,0(a4)
    80000ee8:	ce09                	beqz	a2,80000f02 <initlock+0x58>
  for (i = 0; i < NLOCK; i++) {
    80000eea:	2785                	addiw	a5,a5,1
    80000eec:	0721                	addi	a4,a4,8
    80000eee:	fed79ce3          	bne	a5,a3,80000ee6 <initlock+0x3c>
  panic("findslot");
    80000ef2:	00007517          	auipc	a0,0x7
    80000ef6:	1ae50513          	addi	a0,a0,430 # 800080a0 <digits+0x60>
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	656080e7          	jalr	1622(ra) # 80000550 <panic>
      locks[i] = lk;
    80000f02:	078e                	slli	a5,a5,0x3
    80000f04:	00010717          	auipc	a4,0x10
    80000f08:	4e470713          	addi	a4,a4,1252 # 800113e8 <locks>
    80000f0c:	97ba                	add	a5,a5,a4
    80000f0e:	e384                	sd	s1,0(a5)
      release(&lock_locks);
    80000f10:	00010517          	auipc	a0,0x10
    80000f14:	4b850513          	addi	a0,a0,1208 # 800113c8 <lock_locks>
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	ee6080e7          	jalr	-282(ra) # 80000dfe <release>
}
    80000f20:	60e2                	ld	ra,24(sp)
    80000f22:	6442                	ld	s0,16(sp)
    80000f24:	64a2                	ld	s1,8(sp)
    80000f26:	6105                	addi	sp,sp,32
    80000f28:	8082                	ret

0000000080000f2a <snprint_lock>:
#ifdef LAB_LOCK
int
snprint_lock(char *buf, int sz, struct spinlock *lk)
{
  int n = 0;
  if(lk->n > 0) {
    80000f2a:	4e5c                	lw	a5,28(a2)
    80000f2c:	00f04463          	bgtz	a5,80000f34 <snprint_lock+0xa>
  int n = 0;
    80000f30:	4501                	li	a0,0
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
                 lk->name, lk->nts, lk->n);
  }
  return n;
}
    80000f32:	8082                	ret
{
    80000f34:	1141                	addi	sp,sp,-16
    80000f36:	e406                	sd	ra,8(sp)
    80000f38:	e022                	sd	s0,0(sp)
    80000f3a:	0800                	addi	s0,sp,16
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
    80000f3c:	4e18                	lw	a4,24(a2)
    80000f3e:	6614                	ld	a3,8(a2)
    80000f40:	00007617          	auipc	a2,0x7
    80000f44:	17060613          	addi	a2,a2,368 # 800080b0 <digits+0x70>
    80000f48:	00006097          	auipc	ra,0x6
    80000f4c:	8ba080e7          	jalr	-1862(ra) # 80006802 <snprintf>
}
    80000f50:	60a2                	ld	ra,8(sp)
    80000f52:	6402                	ld	s0,0(sp)
    80000f54:	0141                	addi	sp,sp,16
    80000f56:	8082                	ret

0000000080000f58 <statslock>:

int
statslock(char *buf, int sz) {
    80000f58:	7159                	addi	sp,sp,-112
    80000f5a:	f486                	sd	ra,104(sp)
    80000f5c:	f0a2                	sd	s0,96(sp)
    80000f5e:	eca6                	sd	s1,88(sp)
    80000f60:	e8ca                	sd	s2,80(sp)
    80000f62:	e4ce                	sd	s3,72(sp)
    80000f64:	e0d2                	sd	s4,64(sp)
    80000f66:	fc56                	sd	s5,56(sp)
    80000f68:	f85a                	sd	s6,48(sp)
    80000f6a:	f45e                	sd	s7,40(sp)
    80000f6c:	f062                	sd	s8,32(sp)
    80000f6e:	ec66                	sd	s9,24(sp)
    80000f70:	e86a                	sd	s10,16(sp)
    80000f72:	e46e                	sd	s11,8(sp)
    80000f74:	1880                	addi	s0,sp,112
    80000f76:	8aaa                	mv	s5,a0
    80000f78:	8b2e                	mv	s6,a1
  int n;
  int tot = 0;

  acquire(&lock_locks);
    80000f7a:	00010517          	auipc	a0,0x10
    80000f7e:	44e50513          	addi	a0,a0,1102 # 800113c8 <lock_locks>
    80000f82:	00000097          	auipc	ra,0x0
    80000f86:	dac080e7          	jalr	-596(ra) # 80000d2e <acquire>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f8a:	00007617          	auipc	a2,0x7
    80000f8e:	15660613          	addi	a2,a2,342 # 800080e0 <digits+0xa0>
    80000f92:	85da                	mv	a1,s6
    80000f94:	8556                	mv	a0,s5
    80000f96:	00006097          	auipc	ra,0x6
    80000f9a:	86c080e7          	jalr	-1940(ra) # 80006802 <snprintf>
    80000f9e:	892a                	mv	s2,a0
  for(int i = 0; i < NLOCK; i++) {
    80000fa0:	00010c97          	auipc	s9,0x10
    80000fa4:	448c8c93          	addi	s9,s9,1096 # 800113e8 <locks>
    80000fa8:	00011c17          	auipc	s8,0x11
    80000fac:	3e0c0c13          	addi	s8,s8,992 # 80012388 <pid_lock>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000fb0:	84e6                	mv	s1,s9
  int tot = 0;
    80000fb2:	4a01                	li	s4,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000fb4:	00007b97          	auipc	s7,0x7
    80000fb8:	14cb8b93          	addi	s7,s7,332 # 80008100 <digits+0xc0>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000fbc:	00007d17          	auipc	s10,0x7
    80000fc0:	0acd0d13          	addi	s10,s10,172 # 80008068 <digits+0x28>
    80000fc4:	a01d                	j	80000fea <statslock+0x92>
      tot += locks[i]->nts;
    80000fc6:	0009b603          	ld	a2,0(s3)
    80000fca:	4e1c                	lw	a5,24(a2)
    80000fcc:	01478a3b          	addw	s4,a5,s4
      n += snprint_lock(buf +n, sz-n, locks[i]);
    80000fd0:	412b05bb          	subw	a1,s6,s2
    80000fd4:	012a8533          	add	a0,s5,s2
    80000fd8:	00000097          	auipc	ra,0x0
    80000fdc:	f52080e7          	jalr	-174(ra) # 80000f2a <snprint_lock>
    80000fe0:	0125093b          	addw	s2,a0,s2
  for(int i = 0; i < NLOCK; i++) {
    80000fe4:	04a1                	addi	s1,s1,8
    80000fe6:	05848763          	beq	s1,s8,80001034 <statslock+0xdc>
    if(locks[i] == 0)
    80000fea:	89a6                	mv	s3,s1
    80000fec:	609c                	ld	a5,0(s1)
    80000fee:	c3b9                	beqz	a5,80001034 <statslock+0xdc>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000ff0:	0087bd83          	ld	s11,8(a5)
    80000ff4:	855e                	mv	a0,s7
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	2a0080e7          	jalr	672(ra) # 80001296 <strlen>
    80000ffe:	0005061b          	sext.w	a2,a0
    80001002:	85de                	mv	a1,s7
    80001004:	856e                	mv	a0,s11
    80001006:	00000097          	auipc	ra,0x0
    8000100a:	1e4080e7          	jalr	484(ra) # 800011ea <strncmp>
    8000100e:	dd45                	beqz	a0,80000fc6 <statslock+0x6e>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80001010:	609c                	ld	a5,0(s1)
    80001012:	0087bd83          	ld	s11,8(a5)
    80001016:	856a                	mv	a0,s10
    80001018:	00000097          	auipc	ra,0x0
    8000101c:	27e080e7          	jalr	638(ra) # 80001296 <strlen>
    80001020:	0005061b          	sext.w	a2,a0
    80001024:	85ea                	mv	a1,s10
    80001026:	856e                	mv	a0,s11
    80001028:	00000097          	auipc	ra,0x0
    8000102c:	1c2080e7          	jalr	450(ra) # 800011ea <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80001030:	f955                	bnez	a0,80000fe4 <statslock+0x8c>
    80001032:	bf51                	j	80000fc6 <statslock+0x6e>
    }
  }
  
  n += snprintf(buf+n, sz-n, "--- top 5 contended locks:\n");
    80001034:	00007617          	auipc	a2,0x7
    80001038:	0d460613          	addi	a2,a2,212 # 80008108 <digits+0xc8>
    8000103c:	412b05bb          	subw	a1,s6,s2
    80001040:	012a8533          	add	a0,s5,s2
    80001044:	00005097          	auipc	ra,0x5
    80001048:	7be080e7          	jalr	1982(ra) # 80006802 <snprintf>
    8000104c:	012509bb          	addw	s3,a0,s2
    80001050:	4b95                	li	s7,5
  int last = 100000000;
    80001052:	05f5e537          	lui	a0,0x5f5e
    80001056:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t = 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    8000105a:	4c01                	li	s8,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    8000105c:	00010497          	auipc	s1,0x10
    80001060:	38c48493          	addi	s1,s1,908 # 800113e8 <locks>
    for(int i = 0; i < NLOCK; i++) {
    80001064:	1f400913          	li	s2,500
    80001068:	a881                	j	800010b8 <statslock+0x160>
    8000106a:	2705                	addiw	a4,a4,1
    8000106c:	06a1                	addi	a3,a3,8
    8000106e:	03270063          	beq	a4,s2,8000108e <statslock+0x136>
      if(locks[i] == 0)
    80001072:	629c                	ld	a5,0(a3)
    80001074:	cf89                	beqz	a5,8000108e <statslock+0x136>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80001076:	4f90                	lw	a2,24(a5)
    80001078:	00359793          	slli	a5,a1,0x3
    8000107c:	97a6                	add	a5,a5,s1
    8000107e:	639c                	ld	a5,0(a5)
    80001080:	4f9c                	lw	a5,24(a5)
    80001082:	fec7d4e3          	bge	a5,a2,8000106a <statslock+0x112>
    80001086:	fea652e3          	bge	a2,a0,8000106a <statslock+0x112>
    8000108a:	85ba                	mv	a1,a4
    8000108c:	bff9                	j	8000106a <statslock+0x112>
        top = i;
      }
    }
    n += snprint_lock(buf+n, sz-n, locks[top]);
    8000108e:	058e                	slli	a1,a1,0x3
    80001090:	00b48d33          	add	s10,s1,a1
    80001094:	000d3603          	ld	a2,0(s10)
    80001098:	413b05bb          	subw	a1,s6,s3
    8000109c:	013a8533          	add	a0,s5,s3
    800010a0:	00000097          	auipc	ra,0x0
    800010a4:	e8a080e7          	jalr	-374(ra) # 80000f2a <snprint_lock>
    800010a8:	013509bb          	addw	s3,a0,s3
    last = locks[top]->nts;
    800010ac:	000d3783          	ld	a5,0(s10)
    800010b0:	4f88                	lw	a0,24(a5)
  for(int t = 0; t < 5; t++) {
    800010b2:	3bfd                	addiw	s7,s7,-1
    800010b4:	000b8663          	beqz	s7,800010c0 <statslock+0x168>
  int tot = 0;
    800010b8:	86e6                	mv	a3,s9
    for(int i = 0; i < NLOCK; i++) {
    800010ba:	8762                	mv	a4,s8
    int top = 0;
    800010bc:	85e2                	mv	a1,s8
    800010be:	bf55                	j	80001072 <statslock+0x11a>
  }
  n += snprintf(buf+n, sz-n, "tot= %d\n", tot);
    800010c0:	86d2                	mv	a3,s4
    800010c2:	00007617          	auipc	a2,0x7
    800010c6:	06660613          	addi	a2,a2,102 # 80008128 <digits+0xe8>
    800010ca:	413b05bb          	subw	a1,s6,s3
    800010ce:	013a8533          	add	a0,s5,s3
    800010d2:	00005097          	auipc	ra,0x5
    800010d6:	730080e7          	jalr	1840(ra) # 80006802 <snprintf>
    800010da:	013509bb          	addw	s3,a0,s3
  release(&lock_locks);  
    800010de:	00010517          	auipc	a0,0x10
    800010e2:	2ea50513          	addi	a0,a0,746 # 800113c8 <lock_locks>
    800010e6:	00000097          	auipc	ra,0x0
    800010ea:	d18080e7          	jalr	-744(ra) # 80000dfe <release>
  return n;
}
    800010ee:	854e                	mv	a0,s3
    800010f0:	70a6                	ld	ra,104(sp)
    800010f2:	7406                	ld	s0,96(sp)
    800010f4:	64e6                	ld	s1,88(sp)
    800010f6:	6946                	ld	s2,80(sp)
    800010f8:	69a6                	ld	s3,72(sp)
    800010fa:	6a06                	ld	s4,64(sp)
    800010fc:	7ae2                	ld	s5,56(sp)
    800010fe:	7b42                	ld	s6,48(sp)
    80001100:	7ba2                	ld	s7,40(sp)
    80001102:	7c02                	ld	s8,32(sp)
    80001104:	6ce2                	ld	s9,24(sp)
    80001106:	6d42                	ld	s10,16(sp)
    80001108:	6da2                	ld	s11,8(sp)
    8000110a:	6165                	addi	sp,sp,112
    8000110c:	8082                	ret

000000008000110e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    8000110e:	1141                	addi	sp,sp,-16
    80001110:	e422                	sd	s0,8(sp)
    80001112:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80001114:	ce09                	beqz	a2,8000112e <memset+0x20>
    80001116:	87aa                	mv	a5,a0
    80001118:	fff6071b          	addiw	a4,a2,-1
    8000111c:	1702                	slli	a4,a4,0x20
    8000111e:	9301                	srli	a4,a4,0x20
    80001120:	0705                	addi	a4,a4,1
    80001122:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80001124:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80001128:	0785                	addi	a5,a5,1
    8000112a:	fee79de3          	bne	a5,a4,80001124 <memset+0x16>
  }
  return dst;
}
    8000112e:	6422                	ld	s0,8(sp)
    80001130:	0141                	addi	sp,sp,16
    80001132:	8082                	ret

0000000080001134 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e422                	sd	s0,8(sp)
    80001138:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    8000113a:	ca05                	beqz	a2,8000116a <memcmp+0x36>
    8000113c:	fff6069b          	addiw	a3,a2,-1
    80001140:	1682                	slli	a3,a3,0x20
    80001142:	9281                	srli	a3,a3,0x20
    80001144:	0685                	addi	a3,a3,1
    80001146:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80001148:	00054783          	lbu	a5,0(a0)
    8000114c:	0005c703          	lbu	a4,0(a1)
    80001150:	00e79863          	bne	a5,a4,80001160 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80001154:	0505                	addi	a0,a0,1
    80001156:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80001158:	fed518e3          	bne	a0,a3,80001148 <memcmp+0x14>
  }

  return 0;
    8000115c:	4501                	li	a0,0
    8000115e:	a019                	j	80001164 <memcmp+0x30>
      return *s1 - *s2;
    80001160:	40e7853b          	subw	a0,a5,a4
}
    80001164:	6422                	ld	s0,8(sp)
    80001166:	0141                	addi	sp,sp,16
    80001168:	8082                	ret
  return 0;
    8000116a:	4501                	li	a0,0
    8000116c:	bfe5                	j	80001164 <memcmp+0x30>

000000008000116e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    8000116e:	1141                	addi	sp,sp,-16
    80001170:	e422                	sd	s0,8(sp)
    80001172:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80001174:	00a5f963          	bgeu	a1,a0,80001186 <memmove+0x18>
    80001178:	02061713          	slli	a4,a2,0x20
    8000117c:	9301                	srli	a4,a4,0x20
    8000117e:	00e587b3          	add	a5,a1,a4
    80001182:	02f56563          	bltu	a0,a5,800011ac <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80001186:	fff6069b          	addiw	a3,a2,-1
    8000118a:	ce11                	beqz	a2,800011a6 <memmove+0x38>
    8000118c:	1682                	slli	a3,a3,0x20
    8000118e:	9281                	srli	a3,a3,0x20
    80001190:	0685                	addi	a3,a3,1
    80001192:	96ae                	add	a3,a3,a1
    80001194:	87aa                	mv	a5,a0
      *d++ = *s++;
    80001196:	0585                	addi	a1,a1,1
    80001198:	0785                	addi	a5,a5,1
    8000119a:	fff5c703          	lbu	a4,-1(a1)
    8000119e:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    800011a2:	fed59ae3          	bne	a1,a3,80001196 <memmove+0x28>

  return dst;
}
    800011a6:	6422                	ld	s0,8(sp)
    800011a8:	0141                	addi	sp,sp,16
    800011aa:	8082                	ret
    d += n;
    800011ac:	972a                	add	a4,a4,a0
    while(n-- > 0)
    800011ae:	fff6069b          	addiw	a3,a2,-1
    800011b2:	da75                	beqz	a2,800011a6 <memmove+0x38>
    800011b4:	02069613          	slli	a2,a3,0x20
    800011b8:	9201                	srli	a2,a2,0x20
    800011ba:	fff64613          	not	a2,a2
    800011be:	963e                	add	a2,a2,a5
      *--d = *--s;
    800011c0:	17fd                	addi	a5,a5,-1
    800011c2:	177d                	addi	a4,a4,-1
    800011c4:	0007c683          	lbu	a3,0(a5)
    800011c8:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    800011cc:	fec79ae3          	bne	a5,a2,800011c0 <memmove+0x52>
    800011d0:	bfd9                	j	800011a6 <memmove+0x38>

00000000800011d2 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    800011d2:	1141                	addi	sp,sp,-16
    800011d4:	e406                	sd	ra,8(sp)
    800011d6:	e022                	sd	s0,0(sp)
    800011d8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    800011da:	00000097          	auipc	ra,0x0
    800011de:	f94080e7          	jalr	-108(ra) # 8000116e <memmove>
}
    800011e2:	60a2                	ld	ra,8(sp)
    800011e4:	6402                	ld	s0,0(sp)
    800011e6:	0141                	addi	sp,sp,16
    800011e8:	8082                	ret

00000000800011ea <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    800011ea:	1141                	addi	sp,sp,-16
    800011ec:	e422                	sd	s0,8(sp)
    800011ee:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    800011f0:	ce11                	beqz	a2,8000120c <strncmp+0x22>
    800011f2:	00054783          	lbu	a5,0(a0)
    800011f6:	cf89                	beqz	a5,80001210 <strncmp+0x26>
    800011f8:	0005c703          	lbu	a4,0(a1)
    800011fc:	00f71a63          	bne	a4,a5,80001210 <strncmp+0x26>
    n--, p++, q++;
    80001200:	367d                	addiw	a2,a2,-1
    80001202:	0505                	addi	a0,a0,1
    80001204:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80001206:	f675                	bnez	a2,800011f2 <strncmp+0x8>
  if(n == 0)
    return 0;
    80001208:	4501                	li	a0,0
    8000120a:	a809                	j	8000121c <strncmp+0x32>
    8000120c:	4501                	li	a0,0
    8000120e:	a039                	j	8000121c <strncmp+0x32>
  if(n == 0)
    80001210:	ca09                	beqz	a2,80001222 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80001212:	00054503          	lbu	a0,0(a0)
    80001216:	0005c783          	lbu	a5,0(a1)
    8000121a:	9d1d                	subw	a0,a0,a5
}
    8000121c:	6422                	ld	s0,8(sp)
    8000121e:	0141                	addi	sp,sp,16
    80001220:	8082                	ret
    return 0;
    80001222:	4501                	li	a0,0
    80001224:	bfe5                	j	8000121c <strncmp+0x32>

0000000080001226 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80001226:	1141                	addi	sp,sp,-16
    80001228:	e422                	sd	s0,8(sp)
    8000122a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    8000122c:	872a                	mv	a4,a0
    8000122e:	8832                	mv	a6,a2
    80001230:	367d                	addiw	a2,a2,-1
    80001232:	01005963          	blez	a6,80001244 <strncpy+0x1e>
    80001236:	0705                	addi	a4,a4,1
    80001238:	0005c783          	lbu	a5,0(a1)
    8000123c:	fef70fa3          	sb	a5,-1(a4)
    80001240:	0585                	addi	a1,a1,1
    80001242:	f7f5                	bnez	a5,8000122e <strncpy+0x8>
    ;
  while(n-- > 0)
    80001244:	00c05d63          	blez	a2,8000125e <strncpy+0x38>
    80001248:	86ba                	mv	a3,a4
    *s++ = 0;
    8000124a:	0685                	addi	a3,a3,1
    8000124c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80001250:	fff6c793          	not	a5,a3
    80001254:	9fb9                	addw	a5,a5,a4
    80001256:	010787bb          	addw	a5,a5,a6
    8000125a:	fef048e3          	bgtz	a5,8000124a <strncpy+0x24>
  return os;
}
    8000125e:	6422                	ld	s0,8(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80001264:	1141                	addi	sp,sp,-16
    80001266:	e422                	sd	s0,8(sp)
    80001268:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    8000126a:	02c05363          	blez	a2,80001290 <safestrcpy+0x2c>
    8000126e:	fff6069b          	addiw	a3,a2,-1
    80001272:	1682                	slli	a3,a3,0x20
    80001274:	9281                	srli	a3,a3,0x20
    80001276:	96ae                	add	a3,a3,a1
    80001278:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    8000127a:	00d58963          	beq	a1,a3,8000128c <safestrcpy+0x28>
    8000127e:	0585                	addi	a1,a1,1
    80001280:	0785                	addi	a5,a5,1
    80001282:	fff5c703          	lbu	a4,-1(a1)
    80001286:	fee78fa3          	sb	a4,-1(a5)
    8000128a:	fb65                	bnez	a4,8000127a <safestrcpy+0x16>
    ;
  *s = 0;
    8000128c:	00078023          	sb	zero,0(a5)
  return os;
}
    80001290:	6422                	ld	s0,8(sp)
    80001292:	0141                	addi	sp,sp,16
    80001294:	8082                	ret

0000000080001296 <strlen>:

int
strlen(const char *s)
{
    80001296:	1141                	addi	sp,sp,-16
    80001298:	e422                	sd	s0,8(sp)
    8000129a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    8000129c:	00054783          	lbu	a5,0(a0)
    800012a0:	cf91                	beqz	a5,800012bc <strlen+0x26>
    800012a2:	0505                	addi	a0,a0,1
    800012a4:	87aa                	mv	a5,a0
    800012a6:	4685                	li	a3,1
    800012a8:	9e89                	subw	a3,a3,a0
    800012aa:	00f6853b          	addw	a0,a3,a5
    800012ae:	0785                	addi	a5,a5,1
    800012b0:	fff7c703          	lbu	a4,-1(a5)
    800012b4:	fb7d                	bnez	a4,800012aa <strlen+0x14>
    ;
  return n;
}
    800012b6:	6422                	ld	s0,8(sp)
    800012b8:	0141                	addi	sp,sp,16
    800012ba:	8082                	ret
  for(n = 0; s[n]; n++)
    800012bc:	4501                	li	a0,0
    800012be:	bfe5                	j	800012b6 <strlen+0x20>

00000000800012c0 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    800012c0:	1141                	addi	sp,sp,-16
    800012c2:	e406                	sd	ra,8(sp)
    800012c4:	e022                	sd	s0,0(sp)
    800012c6:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    800012c8:	00001097          	auipc	ra,0x1
    800012cc:	a82080e7          	jalr	-1406(ra) # 80001d4a <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    800012d0:	00008717          	auipc	a4,0x8
    800012d4:	d3c70713          	addi	a4,a4,-708 # 8000900c <started>
  if(cpuid() == 0){
    800012d8:	c139                	beqz	a0,8000131e <main+0x5e>
    while(started == 0)
    800012da:	431c                	lw	a5,0(a4)
    800012dc:	2781                	sext.w	a5,a5
    800012de:	dff5                	beqz	a5,800012da <main+0x1a>
      ;
    __sync_synchronize();
    800012e0:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    800012e4:	00001097          	auipc	ra,0x1
    800012e8:	a66080e7          	jalr	-1434(ra) # 80001d4a <cpuid>
    800012ec:	85aa                	mv	a1,a0
    800012ee:	00007517          	auipc	a0,0x7
    800012f2:	e6250513          	addi	a0,a0,-414 # 80008150 <digits+0x110>
    800012f6:	fffff097          	auipc	ra,0xfffff
    800012fa:	2a4080e7          	jalr	676(ra) # 8000059a <printf>
    kvminithart();    // turn on paging
    800012fe:	00000097          	auipc	ra,0x0
    80001302:	186080e7          	jalr	390(ra) # 80001484 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001306:	00001097          	auipc	ra,0x1
    8000130a:	6ce080e7          	jalr	1742(ra) # 800029d4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000130e:	00005097          	auipc	ra,0x5
    80001312:	d32080e7          	jalr	-718(ra) # 80006040 <plicinithart>
  }

  scheduler();        
    80001316:	00001097          	auipc	ra,0x1
    8000131a:	f90080e7          	jalr	-112(ra) # 800022a6 <scheduler>
    consoleinit();
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	144080e7          	jalr	324(ra) # 80000462 <consoleinit>
    statsinit();
    80001326:	00005097          	auipc	ra,0x5
    8000132a:	400080e7          	jalr	1024(ra) # 80006726 <statsinit>
    printfinit();
    8000132e:	fffff097          	auipc	ra,0xfffff
    80001332:	452080e7          	jalr	1106(ra) # 80000780 <printfinit>
    printf("\n");
    80001336:	00007517          	auipc	a0,0x7
    8000133a:	e2a50513          	addi	a0,a0,-470 # 80008160 <digits+0x120>
    8000133e:	fffff097          	auipc	ra,0xfffff
    80001342:	25c080e7          	jalr	604(ra) # 8000059a <printf>
    printf("xv6 kernel is booting\n");
    80001346:	00007517          	auipc	a0,0x7
    8000134a:	df250513          	addi	a0,a0,-526 # 80008138 <digits+0xf8>
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	24c080e7          	jalr	588(ra) # 8000059a <printf>
    printf("\n");
    80001356:	00007517          	auipc	a0,0x7
    8000135a:	e0a50513          	addi	a0,a0,-502 # 80008160 <digits+0x120>
    8000135e:	fffff097          	auipc	ra,0xfffff
    80001362:	23c080e7          	jalr	572(ra) # 8000059a <printf>
    kinit();         // physical page allocator
    80001366:	fffff097          	auipc	ra,0xfffff
    8000136a:	7ba080e7          	jalr	1978(ra) # 80000b20 <kinit>
    kvminit();       // create kernel page table
    8000136e:	00000097          	auipc	ra,0x0
    80001372:	242080e7          	jalr	578(ra) # 800015b0 <kvminit>
    kvminithart();   // turn on paging
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	10e080e7          	jalr	270(ra) # 80001484 <kvminithart>
    procinit();      // process table
    8000137e:	00001097          	auipc	ra,0x1
    80001382:	8fc080e7          	jalr	-1796(ra) # 80001c7a <procinit>
    trapinit();      // trap vectors
    80001386:	00001097          	auipc	ra,0x1
    8000138a:	626080e7          	jalr	1574(ra) # 800029ac <trapinit>
    trapinithart();  // install kernel trap vector
    8000138e:	00001097          	auipc	ra,0x1
    80001392:	646080e7          	jalr	1606(ra) # 800029d4 <trapinithart>
    plicinit();      // set up interrupt controller
    80001396:	00005097          	auipc	ra,0x5
    8000139a:	c94080e7          	jalr	-876(ra) # 8000602a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000139e:	00005097          	auipc	ra,0x5
    800013a2:	ca2080e7          	jalr	-862(ra) # 80006040 <plicinithart>
    binit();         // buffer cache
    800013a6:	00002097          	auipc	ra,0x2
    800013aa:	d82080e7          	jalr	-638(ra) # 80003128 <binit>
    iinit();         // inode cache
    800013ae:	00002097          	auipc	ra,0x2
    800013b2:	4b8080e7          	jalr	1208(ra) # 80003866 <iinit>
    fileinit();      // file table
    800013b6:	00003097          	auipc	ra,0x3
    800013ba:	468080e7          	jalr	1128(ra) # 8000481e <fileinit>
    virtio_disk_init(); // emulated hard disk
    800013be:	00005097          	auipc	ra,0x5
    800013c2:	da4080e7          	jalr	-604(ra) # 80006162 <virtio_disk_init>
    userinit();      // first user process
    800013c6:	00001097          	auipc	ra,0x1
    800013ca:	c7a080e7          	jalr	-902(ra) # 80002040 <userinit>
    __sync_synchronize();
    800013ce:	0ff0000f          	fence
    started = 1;
    800013d2:	4785                	li	a5,1
    800013d4:	00008717          	auipc	a4,0x8
    800013d8:	c2f72c23          	sw	a5,-968(a4) # 8000900c <started>
    800013dc:	bf2d                	j	80001316 <main+0x56>

00000000800013de <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800013de:	7139                	addi	sp,sp,-64
    800013e0:	fc06                	sd	ra,56(sp)
    800013e2:	f822                	sd	s0,48(sp)
    800013e4:	f426                	sd	s1,40(sp)
    800013e6:	f04a                	sd	s2,32(sp)
    800013e8:	ec4e                	sd	s3,24(sp)
    800013ea:	e852                	sd	s4,16(sp)
    800013ec:	e456                	sd	s5,8(sp)
    800013ee:	e05a                	sd	s6,0(sp)
    800013f0:	0080                	addi	s0,sp,64
    800013f2:	84aa                	mv	s1,a0
    800013f4:	89ae                	mv	s3,a1
    800013f6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800013f8:	57fd                	li	a5,-1
    800013fa:	83e9                	srli	a5,a5,0x1a
    800013fc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800013fe:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001400:	04b7f263          	bgeu	a5,a1,80001444 <walk+0x66>
    panic("walk");
    80001404:	00007517          	auipc	a0,0x7
    80001408:	d6450513          	addi	a0,a0,-668 # 80008168 <digits+0x128>
    8000140c:	fffff097          	auipc	ra,0xfffff
    80001410:	144080e7          	jalr	324(ra) # 80000550 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001414:	060a8663          	beqz	s5,80001480 <walk+0xa2>
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	804080e7          	jalr	-2044(ra) # 80000c1c <kalloc>
    80001420:	84aa                	mv	s1,a0
    80001422:	c529                	beqz	a0,8000146c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001424:	6605                	lui	a2,0x1
    80001426:	4581                	li	a1,0
    80001428:	00000097          	auipc	ra,0x0
    8000142c:	ce6080e7          	jalr	-794(ra) # 8000110e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001430:	00c4d793          	srli	a5,s1,0xc
    80001434:	07aa                	slli	a5,a5,0xa
    80001436:	0017e793          	ori	a5,a5,1
    8000143a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000143e:	3a5d                	addiw	s4,s4,-9
    80001440:	036a0063          	beq	s4,s6,80001460 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001444:	0149d933          	srl	s2,s3,s4
    80001448:	1ff97913          	andi	s2,s2,511
    8000144c:	090e                	slli	s2,s2,0x3
    8000144e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001450:	00093483          	ld	s1,0(s2)
    80001454:	0014f793          	andi	a5,s1,1
    80001458:	dfd5                	beqz	a5,80001414 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000145a:	80a9                	srli	s1,s1,0xa
    8000145c:	04b2                	slli	s1,s1,0xc
    8000145e:	b7c5                	j	8000143e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001460:	00c9d513          	srli	a0,s3,0xc
    80001464:	1ff57513          	andi	a0,a0,511
    80001468:	050e                	slli	a0,a0,0x3
    8000146a:	9526                	add	a0,a0,s1
}
    8000146c:	70e2                	ld	ra,56(sp)
    8000146e:	7442                	ld	s0,48(sp)
    80001470:	74a2                	ld	s1,40(sp)
    80001472:	7902                	ld	s2,32(sp)
    80001474:	69e2                	ld	s3,24(sp)
    80001476:	6a42                	ld	s4,16(sp)
    80001478:	6aa2                	ld	s5,8(sp)
    8000147a:	6b02                	ld	s6,0(sp)
    8000147c:	6121                	addi	sp,sp,64
    8000147e:	8082                	ret
        return 0;
    80001480:	4501                	li	a0,0
    80001482:	b7ed                	j	8000146c <walk+0x8e>

0000000080001484 <kvminithart>:
{
    80001484:	1141                	addi	sp,sp,-16
    80001486:	e422                	sd	s0,8(sp)
    80001488:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000148a:	00008797          	auipc	a5,0x8
    8000148e:	b867b783          	ld	a5,-1146(a5) # 80009010 <kernel_pagetable>
    80001492:	83b1                	srli	a5,a5,0xc
    80001494:	577d                	li	a4,-1
    80001496:	177e                	slli	a4,a4,0x3f
    80001498:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000149a:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000149e:	12000073          	sfence.vma
}
    800014a2:	6422                	ld	s0,8(sp)
    800014a4:	0141                	addi	sp,sp,16
    800014a6:	8082                	ret

00000000800014a8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800014a8:	57fd                	li	a5,-1
    800014aa:	83e9                	srli	a5,a5,0x1a
    800014ac:	00b7f463          	bgeu	a5,a1,800014b4 <walkaddr+0xc>
    return 0;
    800014b0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800014b2:	8082                	ret
{
    800014b4:	1141                	addi	sp,sp,-16
    800014b6:	e406                	sd	ra,8(sp)
    800014b8:	e022                	sd	s0,0(sp)
    800014ba:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800014bc:	4601                	li	a2,0
    800014be:	00000097          	auipc	ra,0x0
    800014c2:	f20080e7          	jalr	-224(ra) # 800013de <walk>
  if(pte == 0)
    800014c6:	c105                	beqz	a0,800014e6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800014c8:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800014ca:	0117f693          	andi	a3,a5,17
    800014ce:	4745                	li	a4,17
    return 0;
    800014d0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800014d2:	00e68663          	beq	a3,a4,800014de <walkaddr+0x36>
}
    800014d6:	60a2                	ld	ra,8(sp)
    800014d8:	6402                	ld	s0,0(sp)
    800014da:	0141                	addi	sp,sp,16
    800014dc:	8082                	ret
  pa = PTE2PA(*pte);
    800014de:	00a7d513          	srli	a0,a5,0xa
    800014e2:	0532                	slli	a0,a0,0xc
  return pa;
    800014e4:	bfcd                	j	800014d6 <walkaddr+0x2e>
    return 0;
    800014e6:	4501                	li	a0,0
    800014e8:	b7fd                	j	800014d6 <walkaddr+0x2e>

00000000800014ea <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800014ea:	715d                	addi	sp,sp,-80
    800014ec:	e486                	sd	ra,72(sp)
    800014ee:	e0a2                	sd	s0,64(sp)
    800014f0:	fc26                	sd	s1,56(sp)
    800014f2:	f84a                	sd	s2,48(sp)
    800014f4:	f44e                	sd	s3,40(sp)
    800014f6:	f052                	sd	s4,32(sp)
    800014f8:	ec56                	sd	s5,24(sp)
    800014fa:	e85a                	sd	s6,16(sp)
    800014fc:	e45e                	sd	s7,8(sp)
    800014fe:	0880                	addi	s0,sp,80
    80001500:	8aaa                	mv	s5,a0
    80001502:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001504:	777d                	lui	a4,0xfffff
    80001506:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000150a:	167d                	addi	a2,a2,-1
    8000150c:	00b609b3          	add	s3,a2,a1
    80001510:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001514:	893e                	mv	s2,a5
    80001516:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000151a:	6b85                	lui	s7,0x1
    8000151c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001520:	4605                	li	a2,1
    80001522:	85ca                	mv	a1,s2
    80001524:	8556                	mv	a0,s5
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	eb8080e7          	jalr	-328(ra) # 800013de <walk>
    8000152e:	c51d                	beqz	a0,8000155c <mappages+0x72>
    if(*pte & PTE_V)
    80001530:	611c                	ld	a5,0(a0)
    80001532:	8b85                	andi	a5,a5,1
    80001534:	ef81                	bnez	a5,8000154c <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001536:	80b1                	srli	s1,s1,0xc
    80001538:	04aa                	slli	s1,s1,0xa
    8000153a:	0164e4b3          	or	s1,s1,s6
    8000153e:	0014e493          	ori	s1,s1,1
    80001542:	e104                	sd	s1,0(a0)
    if(a == last)
    80001544:	03390863          	beq	s2,s3,80001574 <mappages+0x8a>
    a += PGSIZE;
    80001548:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000154a:	bfc9                	j	8000151c <mappages+0x32>
      panic("remap");
    8000154c:	00007517          	auipc	a0,0x7
    80001550:	c2450513          	addi	a0,a0,-988 # 80008170 <digits+0x130>
    80001554:	fffff097          	auipc	ra,0xfffff
    80001558:	ffc080e7          	jalr	-4(ra) # 80000550 <panic>
      return -1;
    8000155c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000155e:	60a6                	ld	ra,72(sp)
    80001560:	6406                	ld	s0,64(sp)
    80001562:	74e2                	ld	s1,56(sp)
    80001564:	7942                	ld	s2,48(sp)
    80001566:	79a2                	ld	s3,40(sp)
    80001568:	7a02                	ld	s4,32(sp)
    8000156a:	6ae2                	ld	s5,24(sp)
    8000156c:	6b42                	ld	s6,16(sp)
    8000156e:	6ba2                	ld	s7,8(sp)
    80001570:	6161                	addi	sp,sp,80
    80001572:	8082                	ret
  return 0;
    80001574:	4501                	li	a0,0
    80001576:	b7e5                	j	8000155e <mappages+0x74>

0000000080001578 <kvmmap>:
{
    80001578:	1141                	addi	sp,sp,-16
    8000157a:	e406                	sd	ra,8(sp)
    8000157c:	e022                	sd	s0,0(sp)
    8000157e:	0800                	addi	s0,sp,16
    80001580:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001582:	86ae                	mv	a3,a1
    80001584:	85aa                	mv	a1,a0
    80001586:	00008517          	auipc	a0,0x8
    8000158a:	a8a53503          	ld	a0,-1398(a0) # 80009010 <kernel_pagetable>
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	f5c080e7          	jalr	-164(ra) # 800014ea <mappages>
    80001596:	e509                	bnez	a0,800015a0 <kvmmap+0x28>
}
    80001598:	60a2                	ld	ra,8(sp)
    8000159a:	6402                	ld	s0,0(sp)
    8000159c:	0141                	addi	sp,sp,16
    8000159e:	8082                	ret
    panic("kvmmap");
    800015a0:	00007517          	auipc	a0,0x7
    800015a4:	bd850513          	addi	a0,a0,-1064 # 80008178 <digits+0x138>
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	fa8080e7          	jalr	-88(ra) # 80000550 <panic>

00000000800015b0 <kvminit>:
{
    800015b0:	1101                	addi	sp,sp,-32
    800015b2:	ec06                	sd	ra,24(sp)
    800015b4:	e822                	sd	s0,16(sp)
    800015b6:	e426                	sd	s1,8(sp)
    800015b8:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	662080e7          	jalr	1634(ra) # 80000c1c <kalloc>
    800015c2:	00008797          	auipc	a5,0x8
    800015c6:	a4a7b723          	sd	a0,-1458(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800015ca:	6605                	lui	a2,0x1
    800015cc:	4581                	li	a1,0
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	b40080e7          	jalr	-1216(ra) # 8000110e <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800015d6:	4699                	li	a3,6
    800015d8:	6605                	lui	a2,0x1
    800015da:	100005b7          	lui	a1,0x10000
    800015de:	10000537          	lui	a0,0x10000
    800015e2:	00000097          	auipc	ra,0x0
    800015e6:	f96080e7          	jalr	-106(ra) # 80001578 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800015ea:	4699                	li	a3,6
    800015ec:	6605                	lui	a2,0x1
    800015ee:	100015b7          	lui	a1,0x10001
    800015f2:	10001537          	lui	a0,0x10001
    800015f6:	00000097          	auipc	ra,0x0
    800015fa:	f82080e7          	jalr	-126(ra) # 80001578 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800015fe:	4699                	li	a3,6
    80001600:	00400637          	lui	a2,0x400
    80001604:	0c0005b7          	lui	a1,0xc000
    80001608:	0c000537          	lui	a0,0xc000
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	f6c080e7          	jalr	-148(ra) # 80001578 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001614:	00007497          	auipc	s1,0x7
    80001618:	9ec48493          	addi	s1,s1,-1556 # 80008000 <etext>
    8000161c:	46a9                	li	a3,10
    8000161e:	80007617          	auipc	a2,0x80007
    80001622:	9e260613          	addi	a2,a2,-1566 # 8000 <_entry-0x7fff8000>
    80001626:	4585                	li	a1,1
    80001628:	05fe                	slli	a1,a1,0x1f
    8000162a:	852e                	mv	a0,a1
    8000162c:	00000097          	auipc	ra,0x0
    80001630:	f4c080e7          	jalr	-180(ra) # 80001578 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001634:	4699                	li	a3,6
    80001636:	4645                	li	a2,17
    80001638:	066e                	slli	a2,a2,0x1b
    8000163a:	8e05                	sub	a2,a2,s1
    8000163c:	85a6                	mv	a1,s1
    8000163e:	8526                	mv	a0,s1
    80001640:	00000097          	auipc	ra,0x0
    80001644:	f38080e7          	jalr	-200(ra) # 80001578 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001648:	46a9                	li	a3,10
    8000164a:	6605                	lui	a2,0x1
    8000164c:	00006597          	auipc	a1,0x6
    80001650:	9b458593          	addi	a1,a1,-1612 # 80007000 <_trampoline>
    80001654:	04000537          	lui	a0,0x4000
    80001658:	157d                	addi	a0,a0,-1
    8000165a:	0532                	slli	a0,a0,0xc
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	f1c080e7          	jalr	-228(ra) # 80001578 <kvmmap>
}
    80001664:	60e2                	ld	ra,24(sp)
    80001666:	6442                	ld	s0,16(sp)
    80001668:	64a2                	ld	s1,8(sp)
    8000166a:	6105                	addi	sp,sp,32
    8000166c:	8082                	ret

000000008000166e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001684:	03459793          	slli	a5,a1,0x34
    80001688:	e795                	bnez	a5,800016b4 <uvmunmap+0x46>
    8000168a:	8a2a                	mv	s4,a0
    8000168c:	892e                	mv	s2,a1
    8000168e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001690:	0632                	slli	a2,a2,0xc
    80001692:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001696:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001698:	6b05                	lui	s6,0x1
    8000169a:	0735e863          	bltu	a1,s3,8000170a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000169e:	60a6                	ld	ra,72(sp)
    800016a0:	6406                	ld	s0,64(sp)
    800016a2:	74e2                	ld	s1,56(sp)
    800016a4:	7942                	ld	s2,48(sp)
    800016a6:	79a2                	ld	s3,40(sp)
    800016a8:	7a02                	ld	s4,32(sp)
    800016aa:	6ae2                	ld	s5,24(sp)
    800016ac:	6b42                	ld	s6,16(sp)
    800016ae:	6ba2                	ld	s7,8(sp)
    800016b0:	6161                	addi	sp,sp,80
    800016b2:	8082                	ret
    panic("uvmunmap: not aligned");
    800016b4:	00007517          	auipc	a0,0x7
    800016b8:	acc50513          	addi	a0,a0,-1332 # 80008180 <digits+0x140>
    800016bc:	fffff097          	auipc	ra,0xfffff
    800016c0:	e94080e7          	jalr	-364(ra) # 80000550 <panic>
      panic("uvmunmap: walk");
    800016c4:	00007517          	auipc	a0,0x7
    800016c8:	ad450513          	addi	a0,a0,-1324 # 80008198 <digits+0x158>
    800016cc:	fffff097          	auipc	ra,0xfffff
    800016d0:	e84080e7          	jalr	-380(ra) # 80000550 <panic>
      panic("uvmunmap: not mapped");
    800016d4:	00007517          	auipc	a0,0x7
    800016d8:	ad450513          	addi	a0,a0,-1324 # 800081a8 <digits+0x168>
    800016dc:	fffff097          	auipc	ra,0xfffff
    800016e0:	e74080e7          	jalr	-396(ra) # 80000550 <panic>
      panic("uvmunmap: not a leaf");
    800016e4:	00007517          	auipc	a0,0x7
    800016e8:	adc50513          	addi	a0,a0,-1316 # 800081c0 <digits+0x180>
    800016ec:	fffff097          	auipc	ra,0xfffff
    800016f0:	e64080e7          	jalr	-412(ra) # 80000550 <panic>
      uint64 pa = PTE2PA(*pte);
    800016f4:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800016f6:	0532                	slli	a0,a0,0xc
    800016f8:	fffff097          	auipc	ra,0xfffff
    800016fc:	334080e7          	jalr	820(ra) # 80000a2c <kfree>
    *pte = 0;
    80001700:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001704:	995a                	add	s2,s2,s6
    80001706:	f9397ce3          	bgeu	s2,s3,8000169e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000170a:	4601                	li	a2,0
    8000170c:	85ca                	mv	a1,s2
    8000170e:	8552                	mv	a0,s4
    80001710:	00000097          	auipc	ra,0x0
    80001714:	cce080e7          	jalr	-818(ra) # 800013de <walk>
    80001718:	84aa                	mv	s1,a0
    8000171a:	d54d                	beqz	a0,800016c4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000171c:	6108                	ld	a0,0(a0)
    8000171e:	00157793          	andi	a5,a0,1
    80001722:	dbcd                	beqz	a5,800016d4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001724:	3ff57793          	andi	a5,a0,1023
    80001728:	fb778ee3          	beq	a5,s7,800016e4 <uvmunmap+0x76>
    if(do_free){
    8000172c:	fc0a8ae3          	beqz	s5,80001700 <uvmunmap+0x92>
    80001730:	b7d1                	j	800016f4 <uvmunmap+0x86>

0000000080001732 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001732:	1101                	addi	sp,sp,-32
    80001734:	ec06                	sd	ra,24(sp)
    80001736:	e822                	sd	s0,16(sp)
    80001738:	e426                	sd	s1,8(sp)
    8000173a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000173c:	fffff097          	auipc	ra,0xfffff
    80001740:	4e0080e7          	jalr	1248(ra) # 80000c1c <kalloc>
    80001744:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001746:	c519                	beqz	a0,80001754 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001748:	6605                	lui	a2,0x1
    8000174a:	4581                	li	a1,0
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	9c2080e7          	jalr	-1598(ra) # 8000110e <memset>
  return pagetable;
}
    80001754:	8526                	mv	a0,s1
    80001756:	60e2                	ld	ra,24(sp)
    80001758:	6442                	ld	s0,16(sp)
    8000175a:	64a2                	ld	s1,8(sp)
    8000175c:	6105                	addi	sp,sp,32
    8000175e:	8082                	ret

0000000080001760 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001760:	7179                	addi	sp,sp,-48
    80001762:	f406                	sd	ra,40(sp)
    80001764:	f022                	sd	s0,32(sp)
    80001766:	ec26                	sd	s1,24(sp)
    80001768:	e84a                	sd	s2,16(sp)
    8000176a:	e44e                	sd	s3,8(sp)
    8000176c:	e052                	sd	s4,0(sp)
    8000176e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001770:	6785                	lui	a5,0x1
    80001772:	04f67863          	bgeu	a2,a5,800017c2 <uvminit+0x62>
    80001776:	8a2a                	mv	s4,a0
    80001778:	89ae                	mv	s3,a1
    8000177a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000177c:	fffff097          	auipc	ra,0xfffff
    80001780:	4a0080e7          	jalr	1184(ra) # 80000c1c <kalloc>
    80001784:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001786:	6605                	lui	a2,0x1
    80001788:	4581                	li	a1,0
    8000178a:	00000097          	auipc	ra,0x0
    8000178e:	984080e7          	jalr	-1660(ra) # 8000110e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001792:	4779                	li	a4,30
    80001794:	86ca                	mv	a3,s2
    80001796:	6605                	lui	a2,0x1
    80001798:	4581                	li	a1,0
    8000179a:	8552                	mv	a0,s4
    8000179c:	00000097          	auipc	ra,0x0
    800017a0:	d4e080e7          	jalr	-690(ra) # 800014ea <mappages>
  memmove(mem, src, sz);
    800017a4:	8626                	mv	a2,s1
    800017a6:	85ce                	mv	a1,s3
    800017a8:	854a                	mv	a0,s2
    800017aa:	00000097          	auipc	ra,0x0
    800017ae:	9c4080e7          	jalr	-1596(ra) # 8000116e <memmove>
}
    800017b2:	70a2                	ld	ra,40(sp)
    800017b4:	7402                	ld	s0,32(sp)
    800017b6:	64e2                	ld	s1,24(sp)
    800017b8:	6942                	ld	s2,16(sp)
    800017ba:	69a2                	ld	s3,8(sp)
    800017bc:	6a02                	ld	s4,0(sp)
    800017be:	6145                	addi	sp,sp,48
    800017c0:	8082                	ret
    panic("inituvm: more than a page");
    800017c2:	00007517          	auipc	a0,0x7
    800017c6:	a1650513          	addi	a0,a0,-1514 # 800081d8 <digits+0x198>
    800017ca:	fffff097          	auipc	ra,0xfffff
    800017ce:	d86080e7          	jalr	-634(ra) # 80000550 <panic>

00000000800017d2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800017d2:	1101                	addi	sp,sp,-32
    800017d4:	ec06                	sd	ra,24(sp)
    800017d6:	e822                	sd	s0,16(sp)
    800017d8:	e426                	sd	s1,8(sp)
    800017da:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800017dc:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800017de:	00b67d63          	bgeu	a2,a1,800017f8 <uvmdealloc+0x26>
    800017e2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800017e4:	6785                	lui	a5,0x1
    800017e6:	17fd                	addi	a5,a5,-1
    800017e8:	00f60733          	add	a4,a2,a5
    800017ec:	767d                	lui	a2,0xfffff
    800017ee:	8f71                	and	a4,a4,a2
    800017f0:	97ae                	add	a5,a5,a1
    800017f2:	8ff1                	and	a5,a5,a2
    800017f4:	00f76863          	bltu	a4,a5,80001804 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800017f8:	8526                	mv	a0,s1
    800017fa:	60e2                	ld	ra,24(sp)
    800017fc:	6442                	ld	s0,16(sp)
    800017fe:	64a2                	ld	s1,8(sp)
    80001800:	6105                	addi	sp,sp,32
    80001802:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001804:	8f99                	sub	a5,a5,a4
    80001806:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001808:	4685                	li	a3,1
    8000180a:	0007861b          	sext.w	a2,a5
    8000180e:	85ba                	mv	a1,a4
    80001810:	00000097          	auipc	ra,0x0
    80001814:	e5e080e7          	jalr	-418(ra) # 8000166e <uvmunmap>
    80001818:	b7c5                	j	800017f8 <uvmdealloc+0x26>

000000008000181a <uvmalloc>:
  if(newsz < oldsz)
    8000181a:	0ab66163          	bltu	a2,a1,800018bc <uvmalloc+0xa2>
{
    8000181e:	7139                	addi	sp,sp,-64
    80001820:	fc06                	sd	ra,56(sp)
    80001822:	f822                	sd	s0,48(sp)
    80001824:	f426                	sd	s1,40(sp)
    80001826:	f04a                	sd	s2,32(sp)
    80001828:	ec4e                	sd	s3,24(sp)
    8000182a:	e852                	sd	s4,16(sp)
    8000182c:	e456                	sd	s5,8(sp)
    8000182e:	0080                	addi	s0,sp,64
    80001830:	8aaa                	mv	s5,a0
    80001832:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001834:	6985                	lui	s3,0x1
    80001836:	19fd                	addi	s3,s3,-1
    80001838:	95ce                	add	a1,a1,s3
    8000183a:	79fd                	lui	s3,0xfffff
    8000183c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001840:	08c9f063          	bgeu	s3,a2,800018c0 <uvmalloc+0xa6>
    80001844:	894e                	mv	s2,s3
    mem = kalloc();
    80001846:	fffff097          	auipc	ra,0xfffff
    8000184a:	3d6080e7          	jalr	982(ra) # 80000c1c <kalloc>
    8000184e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001850:	c51d                	beqz	a0,8000187e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001852:	6605                	lui	a2,0x1
    80001854:	4581                	li	a1,0
    80001856:	00000097          	auipc	ra,0x0
    8000185a:	8b8080e7          	jalr	-1864(ra) # 8000110e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000185e:	4779                	li	a4,30
    80001860:	86a6                	mv	a3,s1
    80001862:	6605                	lui	a2,0x1
    80001864:	85ca                	mv	a1,s2
    80001866:	8556                	mv	a0,s5
    80001868:	00000097          	auipc	ra,0x0
    8000186c:	c82080e7          	jalr	-894(ra) # 800014ea <mappages>
    80001870:	e905                	bnez	a0,800018a0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001872:	6785                	lui	a5,0x1
    80001874:	993e                	add	s2,s2,a5
    80001876:	fd4968e3          	bltu	s2,s4,80001846 <uvmalloc+0x2c>
  return newsz;
    8000187a:	8552                	mv	a0,s4
    8000187c:	a809                	j	8000188e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000187e:	864e                	mv	a2,s3
    80001880:	85ca                	mv	a1,s2
    80001882:	8556                	mv	a0,s5
    80001884:	00000097          	auipc	ra,0x0
    80001888:	f4e080e7          	jalr	-178(ra) # 800017d2 <uvmdealloc>
      return 0;
    8000188c:	4501                	li	a0,0
}
    8000188e:	70e2                	ld	ra,56(sp)
    80001890:	7442                	ld	s0,48(sp)
    80001892:	74a2                	ld	s1,40(sp)
    80001894:	7902                	ld	s2,32(sp)
    80001896:	69e2                	ld	s3,24(sp)
    80001898:	6a42                	ld	s4,16(sp)
    8000189a:	6aa2                	ld	s5,8(sp)
    8000189c:	6121                	addi	sp,sp,64
    8000189e:	8082                	ret
      kfree(mem);
    800018a0:	8526                	mv	a0,s1
    800018a2:	fffff097          	auipc	ra,0xfffff
    800018a6:	18a080e7          	jalr	394(ra) # 80000a2c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800018aa:	864e                	mv	a2,s3
    800018ac:	85ca                	mv	a1,s2
    800018ae:	8556                	mv	a0,s5
    800018b0:	00000097          	auipc	ra,0x0
    800018b4:	f22080e7          	jalr	-222(ra) # 800017d2 <uvmdealloc>
      return 0;
    800018b8:	4501                	li	a0,0
    800018ba:	bfd1                	j	8000188e <uvmalloc+0x74>
    return oldsz;
    800018bc:	852e                	mv	a0,a1
}
    800018be:	8082                	ret
  return newsz;
    800018c0:	8532                	mv	a0,a2
    800018c2:	b7f1                	j	8000188e <uvmalloc+0x74>

00000000800018c4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800018c4:	7179                	addi	sp,sp,-48
    800018c6:	f406                	sd	ra,40(sp)
    800018c8:	f022                	sd	s0,32(sp)
    800018ca:	ec26                	sd	s1,24(sp)
    800018cc:	e84a                	sd	s2,16(sp)
    800018ce:	e44e                	sd	s3,8(sp)
    800018d0:	e052                	sd	s4,0(sp)
    800018d2:	1800                	addi	s0,sp,48
    800018d4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800018d6:	84aa                	mv	s1,a0
    800018d8:	6905                	lui	s2,0x1
    800018da:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018dc:	4985                	li	s3,1
    800018de:	a821                	j	800018f6 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800018e0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800018e2:	0532                	slli	a0,a0,0xc
    800018e4:	00000097          	auipc	ra,0x0
    800018e8:	fe0080e7          	jalr	-32(ra) # 800018c4 <freewalk>
      pagetable[i] = 0;
    800018ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800018f0:	04a1                	addi	s1,s1,8
    800018f2:	03248163          	beq	s1,s2,80001914 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800018f6:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018f8:	00f57793          	andi	a5,a0,15
    800018fc:	ff3782e3          	beq	a5,s3,800018e0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001900:	8905                	andi	a0,a0,1
    80001902:	d57d                	beqz	a0,800018f0 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001904:	00007517          	auipc	a0,0x7
    80001908:	8f450513          	addi	a0,a0,-1804 # 800081f8 <digits+0x1b8>
    8000190c:	fffff097          	auipc	ra,0xfffff
    80001910:	c44080e7          	jalr	-956(ra) # 80000550 <panic>
    }
  }
  kfree((void*)pagetable);
    80001914:	8552                	mv	a0,s4
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	116080e7          	jalr	278(ra) # 80000a2c <kfree>
}
    8000191e:	70a2                	ld	ra,40(sp)
    80001920:	7402                	ld	s0,32(sp)
    80001922:	64e2                	ld	s1,24(sp)
    80001924:	6942                	ld	s2,16(sp)
    80001926:	69a2                	ld	s3,8(sp)
    80001928:	6a02                	ld	s4,0(sp)
    8000192a:	6145                	addi	sp,sp,48
    8000192c:	8082                	ret

000000008000192e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000192e:	1101                	addi	sp,sp,-32
    80001930:	ec06                	sd	ra,24(sp)
    80001932:	e822                	sd	s0,16(sp)
    80001934:	e426                	sd	s1,8(sp)
    80001936:	1000                	addi	s0,sp,32
    80001938:	84aa                	mv	s1,a0
  if(sz > 0)
    8000193a:	e999                	bnez	a1,80001950 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000193c:	8526                	mv	a0,s1
    8000193e:	00000097          	auipc	ra,0x0
    80001942:	f86080e7          	jalr	-122(ra) # 800018c4 <freewalk>
}
    80001946:	60e2                	ld	ra,24(sp)
    80001948:	6442                	ld	s0,16(sp)
    8000194a:	64a2                	ld	s1,8(sp)
    8000194c:	6105                	addi	sp,sp,32
    8000194e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001950:	6605                	lui	a2,0x1
    80001952:	167d                	addi	a2,a2,-1
    80001954:	962e                	add	a2,a2,a1
    80001956:	4685                	li	a3,1
    80001958:	8231                	srli	a2,a2,0xc
    8000195a:	4581                	li	a1,0
    8000195c:	00000097          	auipc	ra,0x0
    80001960:	d12080e7          	jalr	-750(ra) # 8000166e <uvmunmap>
    80001964:	bfe1                	j	8000193c <uvmfree+0xe>

0000000080001966 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001966:	c679                	beqz	a2,80001a34 <uvmcopy+0xce>
{
    80001968:	715d                	addi	sp,sp,-80
    8000196a:	e486                	sd	ra,72(sp)
    8000196c:	e0a2                	sd	s0,64(sp)
    8000196e:	fc26                	sd	s1,56(sp)
    80001970:	f84a                	sd	s2,48(sp)
    80001972:	f44e                	sd	s3,40(sp)
    80001974:	f052                	sd	s4,32(sp)
    80001976:	ec56                	sd	s5,24(sp)
    80001978:	e85a                	sd	s6,16(sp)
    8000197a:	e45e                	sd	s7,8(sp)
    8000197c:	0880                	addi	s0,sp,80
    8000197e:	8b2a                	mv	s6,a0
    80001980:	8aae                	mv	s5,a1
    80001982:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001984:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001986:	4601                	li	a2,0
    80001988:	85ce                	mv	a1,s3
    8000198a:	855a                	mv	a0,s6
    8000198c:	00000097          	auipc	ra,0x0
    80001990:	a52080e7          	jalr	-1454(ra) # 800013de <walk>
    80001994:	c531                	beqz	a0,800019e0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001996:	6118                	ld	a4,0(a0)
    80001998:	00177793          	andi	a5,a4,1
    8000199c:	cbb1                	beqz	a5,800019f0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000199e:	00a75593          	srli	a1,a4,0xa
    800019a2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800019a6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	272080e7          	jalr	626(ra) # 80000c1c <kalloc>
    800019b2:	892a                	mv	s2,a0
    800019b4:	c939                	beqz	a0,80001a0a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800019b6:	6605                	lui	a2,0x1
    800019b8:	85de                	mv	a1,s7
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	7b4080e7          	jalr	1972(ra) # 8000116e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800019c2:	8726                	mv	a4,s1
    800019c4:	86ca                	mv	a3,s2
    800019c6:	6605                	lui	a2,0x1
    800019c8:	85ce                	mv	a1,s3
    800019ca:	8556                	mv	a0,s5
    800019cc:	00000097          	auipc	ra,0x0
    800019d0:	b1e080e7          	jalr	-1250(ra) # 800014ea <mappages>
    800019d4:	e515                	bnez	a0,80001a00 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800019d6:	6785                	lui	a5,0x1
    800019d8:	99be                	add	s3,s3,a5
    800019da:	fb49e6e3          	bltu	s3,s4,80001986 <uvmcopy+0x20>
    800019de:	a081                	j	80001a1e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800019e0:	00007517          	auipc	a0,0x7
    800019e4:	82850513          	addi	a0,a0,-2008 # 80008208 <digits+0x1c8>
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	b68080e7          	jalr	-1176(ra) # 80000550 <panic>
      panic("uvmcopy: page not present");
    800019f0:	00007517          	auipc	a0,0x7
    800019f4:	83850513          	addi	a0,a0,-1992 # 80008228 <digits+0x1e8>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	b58080e7          	jalr	-1192(ra) # 80000550 <panic>
      kfree(mem);
    80001a00:	854a                	mv	a0,s2
    80001a02:	fffff097          	auipc	ra,0xfffff
    80001a06:	02a080e7          	jalr	42(ra) # 80000a2c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001a0a:	4685                	li	a3,1
    80001a0c:	00c9d613          	srli	a2,s3,0xc
    80001a10:	4581                	li	a1,0
    80001a12:	8556                	mv	a0,s5
    80001a14:	00000097          	auipc	ra,0x0
    80001a18:	c5a080e7          	jalr	-934(ra) # 8000166e <uvmunmap>
  return -1;
    80001a1c:	557d                	li	a0,-1
}
    80001a1e:	60a6                	ld	ra,72(sp)
    80001a20:	6406                	ld	s0,64(sp)
    80001a22:	74e2                	ld	s1,56(sp)
    80001a24:	7942                	ld	s2,48(sp)
    80001a26:	79a2                	ld	s3,40(sp)
    80001a28:	7a02                	ld	s4,32(sp)
    80001a2a:	6ae2                	ld	s5,24(sp)
    80001a2c:	6b42                	ld	s6,16(sp)
    80001a2e:	6ba2                	ld	s7,8(sp)
    80001a30:	6161                	addi	sp,sp,80
    80001a32:	8082                	ret
  return 0;
    80001a34:	4501                	li	a0,0
}
    80001a36:	8082                	ret

0000000080001a38 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001a38:	1141                	addi	sp,sp,-16
    80001a3a:	e406                	sd	ra,8(sp)
    80001a3c:	e022                	sd	s0,0(sp)
    80001a3e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001a40:	4601                	li	a2,0
    80001a42:	00000097          	auipc	ra,0x0
    80001a46:	99c080e7          	jalr	-1636(ra) # 800013de <walk>
  if(pte == 0)
    80001a4a:	c901                	beqz	a0,80001a5a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001a4c:	611c                	ld	a5,0(a0)
    80001a4e:	9bbd                	andi	a5,a5,-17
    80001a50:	e11c                	sd	a5,0(a0)
}
    80001a52:	60a2                	ld	ra,8(sp)
    80001a54:	6402                	ld	s0,0(sp)
    80001a56:	0141                	addi	sp,sp,16
    80001a58:	8082                	ret
    panic("uvmclear");
    80001a5a:	00006517          	auipc	a0,0x6
    80001a5e:	7ee50513          	addi	a0,a0,2030 # 80008248 <digits+0x208>
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	aee080e7          	jalr	-1298(ra) # 80000550 <panic>

0000000080001a6a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a6a:	c6bd                	beqz	a3,80001ad8 <copyout+0x6e>
{
    80001a6c:	715d                	addi	sp,sp,-80
    80001a6e:	e486                	sd	ra,72(sp)
    80001a70:	e0a2                	sd	s0,64(sp)
    80001a72:	fc26                	sd	s1,56(sp)
    80001a74:	f84a                	sd	s2,48(sp)
    80001a76:	f44e                	sd	s3,40(sp)
    80001a78:	f052                	sd	s4,32(sp)
    80001a7a:	ec56                	sd	s5,24(sp)
    80001a7c:	e85a                	sd	s6,16(sp)
    80001a7e:	e45e                	sd	s7,8(sp)
    80001a80:	e062                	sd	s8,0(sp)
    80001a82:	0880                	addi	s0,sp,80
    80001a84:	8b2a                	mv	s6,a0
    80001a86:	8c2e                	mv	s8,a1
    80001a88:	8a32                	mv	s4,a2
    80001a8a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001a8c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001a8e:	6a85                	lui	s5,0x1
    80001a90:	a015                	j	80001ab4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001a92:	9562                	add	a0,a0,s8
    80001a94:	0004861b          	sext.w	a2,s1
    80001a98:	85d2                	mv	a1,s4
    80001a9a:	41250533          	sub	a0,a0,s2
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	6d0080e7          	jalr	1744(ra) # 8000116e <memmove>

    len -= n;
    80001aa6:	409989b3          	sub	s3,s3,s1
    src += n;
    80001aaa:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001aac:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001ab0:	02098263          	beqz	s3,80001ad4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001ab4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001ab8:	85ca                	mv	a1,s2
    80001aba:	855a                	mv	a0,s6
    80001abc:	00000097          	auipc	ra,0x0
    80001ac0:	9ec080e7          	jalr	-1556(ra) # 800014a8 <walkaddr>
    if(pa0 == 0)
    80001ac4:	cd01                	beqz	a0,80001adc <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001ac6:	418904b3          	sub	s1,s2,s8
    80001aca:	94d6                	add	s1,s1,s5
    if(n > len)
    80001acc:	fc99f3e3          	bgeu	s3,s1,80001a92 <copyout+0x28>
    80001ad0:	84ce                	mv	s1,s3
    80001ad2:	b7c1                	j	80001a92 <copyout+0x28>
  }
  return 0;
    80001ad4:	4501                	li	a0,0
    80001ad6:	a021                	j	80001ade <copyout+0x74>
    80001ad8:	4501                	li	a0,0
}
    80001ada:	8082                	ret
      return -1;
    80001adc:	557d                	li	a0,-1
}
    80001ade:	60a6                	ld	ra,72(sp)
    80001ae0:	6406                	ld	s0,64(sp)
    80001ae2:	74e2                	ld	s1,56(sp)
    80001ae4:	7942                	ld	s2,48(sp)
    80001ae6:	79a2                	ld	s3,40(sp)
    80001ae8:	7a02                	ld	s4,32(sp)
    80001aea:	6ae2                	ld	s5,24(sp)
    80001aec:	6b42                	ld	s6,16(sp)
    80001aee:	6ba2                	ld	s7,8(sp)
    80001af0:	6c02                	ld	s8,0(sp)
    80001af2:	6161                	addi	sp,sp,80
    80001af4:	8082                	ret

0000000080001af6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001af6:	c6bd                	beqz	a3,80001b64 <copyin+0x6e>
{
    80001af8:	715d                	addi	sp,sp,-80
    80001afa:	e486                	sd	ra,72(sp)
    80001afc:	e0a2                	sd	s0,64(sp)
    80001afe:	fc26                	sd	s1,56(sp)
    80001b00:	f84a                	sd	s2,48(sp)
    80001b02:	f44e                	sd	s3,40(sp)
    80001b04:	f052                	sd	s4,32(sp)
    80001b06:	ec56                	sd	s5,24(sp)
    80001b08:	e85a                	sd	s6,16(sp)
    80001b0a:	e45e                	sd	s7,8(sp)
    80001b0c:	e062                	sd	s8,0(sp)
    80001b0e:	0880                	addi	s0,sp,80
    80001b10:	8b2a                	mv	s6,a0
    80001b12:	8a2e                	mv	s4,a1
    80001b14:	8c32                	mv	s8,a2
    80001b16:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001b18:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b1a:	6a85                	lui	s5,0x1
    80001b1c:	a015                	j	80001b40 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001b1e:	9562                	add	a0,a0,s8
    80001b20:	0004861b          	sext.w	a2,s1
    80001b24:	412505b3          	sub	a1,a0,s2
    80001b28:	8552                	mv	a0,s4
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	644080e7          	jalr	1604(ra) # 8000116e <memmove>

    len -= n;
    80001b32:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001b36:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001b38:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001b3c:	02098263          	beqz	s3,80001b60 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001b40:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001b44:	85ca                	mv	a1,s2
    80001b46:	855a                	mv	a0,s6
    80001b48:	00000097          	auipc	ra,0x0
    80001b4c:	960080e7          	jalr	-1696(ra) # 800014a8 <walkaddr>
    if(pa0 == 0)
    80001b50:	cd01                	beqz	a0,80001b68 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001b52:	418904b3          	sub	s1,s2,s8
    80001b56:	94d6                	add	s1,s1,s5
    if(n > len)
    80001b58:	fc99f3e3          	bgeu	s3,s1,80001b1e <copyin+0x28>
    80001b5c:	84ce                	mv	s1,s3
    80001b5e:	b7c1                	j	80001b1e <copyin+0x28>
  }
  return 0;
    80001b60:	4501                	li	a0,0
    80001b62:	a021                	j	80001b6a <copyin+0x74>
    80001b64:	4501                	li	a0,0
}
    80001b66:	8082                	ret
      return -1;
    80001b68:	557d                	li	a0,-1
}
    80001b6a:	60a6                	ld	ra,72(sp)
    80001b6c:	6406                	ld	s0,64(sp)
    80001b6e:	74e2                	ld	s1,56(sp)
    80001b70:	7942                	ld	s2,48(sp)
    80001b72:	79a2                	ld	s3,40(sp)
    80001b74:	7a02                	ld	s4,32(sp)
    80001b76:	6ae2                	ld	s5,24(sp)
    80001b78:	6b42                	ld	s6,16(sp)
    80001b7a:	6ba2                	ld	s7,8(sp)
    80001b7c:	6c02                	ld	s8,0(sp)
    80001b7e:	6161                	addi	sp,sp,80
    80001b80:	8082                	ret

0000000080001b82 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001b82:	c6c5                	beqz	a3,80001c2a <copyinstr+0xa8>
{
    80001b84:	715d                	addi	sp,sp,-80
    80001b86:	e486                	sd	ra,72(sp)
    80001b88:	e0a2                	sd	s0,64(sp)
    80001b8a:	fc26                	sd	s1,56(sp)
    80001b8c:	f84a                	sd	s2,48(sp)
    80001b8e:	f44e                	sd	s3,40(sp)
    80001b90:	f052                	sd	s4,32(sp)
    80001b92:	ec56                	sd	s5,24(sp)
    80001b94:	e85a                	sd	s6,16(sp)
    80001b96:	e45e                	sd	s7,8(sp)
    80001b98:	0880                	addi	s0,sp,80
    80001b9a:	8a2a                	mv	s4,a0
    80001b9c:	8b2e                	mv	s6,a1
    80001b9e:	8bb2                	mv	s7,a2
    80001ba0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001ba2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001ba4:	6985                	lui	s3,0x1
    80001ba6:	a035                	j	80001bd2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001ba8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001bac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001bae:	0017b793          	seqz	a5,a5
    80001bb2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001bb6:	60a6                	ld	ra,72(sp)
    80001bb8:	6406                	ld	s0,64(sp)
    80001bba:	74e2                	ld	s1,56(sp)
    80001bbc:	7942                	ld	s2,48(sp)
    80001bbe:	79a2                	ld	s3,40(sp)
    80001bc0:	7a02                	ld	s4,32(sp)
    80001bc2:	6ae2                	ld	s5,24(sp)
    80001bc4:	6b42                	ld	s6,16(sp)
    80001bc6:	6ba2                	ld	s7,8(sp)
    80001bc8:	6161                	addi	sp,sp,80
    80001bca:	8082                	ret
    srcva = va0 + PGSIZE;
    80001bcc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001bd0:	c8a9                	beqz	s1,80001c22 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001bd2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001bd6:	85ca                	mv	a1,s2
    80001bd8:	8552                	mv	a0,s4
    80001bda:	00000097          	auipc	ra,0x0
    80001bde:	8ce080e7          	jalr	-1842(ra) # 800014a8 <walkaddr>
    if(pa0 == 0)
    80001be2:	c131                	beqz	a0,80001c26 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001be4:	41790833          	sub	a6,s2,s7
    80001be8:	984e                	add	a6,a6,s3
    if(n > max)
    80001bea:	0104f363          	bgeu	s1,a6,80001bf0 <copyinstr+0x6e>
    80001bee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001bf0:	955e                	add	a0,a0,s7
    80001bf2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001bf6:	fc080be3          	beqz	a6,80001bcc <copyinstr+0x4a>
    80001bfa:	985a                	add	a6,a6,s6
    80001bfc:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001bfe:	41650633          	sub	a2,a0,s6
    80001c02:	14fd                	addi	s1,s1,-1
    80001c04:	9b26                	add	s6,s6,s1
    80001c06:	00f60733          	add	a4,a2,a5
    80001c0a:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffccfd8>
    80001c0e:	df49                	beqz	a4,80001ba8 <copyinstr+0x26>
        *dst = *p;
    80001c10:	00e78023          	sb	a4,0(a5)
      --max;
    80001c14:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001c18:	0785                	addi	a5,a5,1
    while(n > 0){
    80001c1a:	ff0796e3          	bne	a5,a6,80001c06 <copyinstr+0x84>
      dst++;
    80001c1e:	8b42                	mv	s6,a6
    80001c20:	b775                	j	80001bcc <copyinstr+0x4a>
    80001c22:	4781                	li	a5,0
    80001c24:	b769                	j	80001bae <copyinstr+0x2c>
      return -1;
    80001c26:	557d                	li	a0,-1
    80001c28:	b779                	j	80001bb6 <copyinstr+0x34>
  int got_null = 0;
    80001c2a:	4781                	li	a5,0
  if(got_null){
    80001c2c:	0017b793          	seqz	a5,a5
    80001c30:	40f00533          	neg	a0,a5
}
    80001c34:	8082                	ret

0000000080001c36 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001c36:	1101                	addi	sp,sp,-32
    80001c38:	ec06                	sd	ra,24(sp)
    80001c3a:	e822                	sd	s0,16(sp)
    80001c3c:	e426                	sd	s1,8(sp)
    80001c3e:	1000                	addi	s0,sp,32
    80001c40:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	072080e7          	jalr	114(ra) # 80000cb4 <holding>
    80001c4a:	c909                	beqz	a0,80001c5c <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001c4c:	789c                	ld	a5,48(s1)
    80001c4e:	00978f63          	beq	a5,s1,80001c6c <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001c52:	60e2                	ld	ra,24(sp)
    80001c54:	6442                	ld	s0,16(sp)
    80001c56:	64a2                	ld	s1,8(sp)
    80001c58:	6105                	addi	sp,sp,32
    80001c5a:	8082                	ret
    panic("wakeup1");
    80001c5c:	00006517          	auipc	a0,0x6
    80001c60:	5fc50513          	addi	a0,a0,1532 # 80008258 <digits+0x218>
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	8ec080e7          	jalr	-1812(ra) # 80000550 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001c6c:	5098                	lw	a4,32(s1)
    80001c6e:	4785                	li	a5,1
    80001c70:	fef711e3          	bne	a4,a5,80001c52 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001c74:	4789                	li	a5,2
    80001c76:	d09c                	sw	a5,32(s1)
}
    80001c78:	bfe9                	j	80001c52 <wakeup1+0x1c>

0000000080001c7a <procinit>:
{
    80001c7a:	715d                	addi	sp,sp,-80
    80001c7c:	e486                	sd	ra,72(sp)
    80001c7e:	e0a2                	sd	s0,64(sp)
    80001c80:	fc26                	sd	s1,56(sp)
    80001c82:	f84a                	sd	s2,48(sp)
    80001c84:	f44e                	sd	s3,40(sp)
    80001c86:	f052                	sd	s4,32(sp)
    80001c88:	ec56                	sd	s5,24(sp)
    80001c8a:	e85a                	sd	s6,16(sp)
    80001c8c:	e45e                	sd	s7,8(sp)
    80001c8e:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001c90:	00006597          	auipc	a1,0x6
    80001c94:	5d058593          	addi	a1,a1,1488 # 80008260 <digits+0x220>
    80001c98:	00010517          	auipc	a0,0x10
    80001c9c:	6f050513          	addi	a0,a0,1776 # 80012388 <pid_lock>
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	20a080e7          	jalr	522(ra) # 80000eaa <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ca8:	00011917          	auipc	s2,0x11
    80001cac:	b0090913          	addi	s2,s2,-1280 # 800127a8 <proc>
      initlock(&p->lock, "proc");
    80001cb0:	00006b97          	auipc	s7,0x6
    80001cb4:	5b8b8b93          	addi	s7,s7,1464 # 80008268 <digits+0x228>
      uint64 va = KSTACK((int) (p - proc));
    80001cb8:	8b4a                	mv	s6,s2
    80001cba:	00006a97          	auipc	s5,0x6
    80001cbe:	346a8a93          	addi	s5,s5,838 # 80008000 <etext>
    80001cc2:	040009b7          	lui	s3,0x4000
    80001cc6:	19fd                	addi	s3,s3,-1
    80001cc8:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cca:	00016a17          	auipc	s4,0x16
    80001cce:	6dea0a13          	addi	s4,s4,1758 # 800183a8 <tickslock>
      initlock(&p->lock, "proc");
    80001cd2:	85de                	mv	a1,s7
    80001cd4:	854a                	mv	a0,s2
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	1d4080e7          	jalr	468(ra) # 80000eaa <initlock>
      char *pa = kalloc();
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	f3e080e7          	jalr	-194(ra) # 80000c1c <kalloc>
    80001ce6:	85aa                	mv	a1,a0
      if(pa == 0)
    80001ce8:	c929                	beqz	a0,80001d3a <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001cea:	416904b3          	sub	s1,s2,s6
    80001cee:	8491                	srai	s1,s1,0x4
    80001cf0:	000ab783          	ld	a5,0(s5)
    80001cf4:	02f484b3          	mul	s1,s1,a5
    80001cf8:	2485                	addiw	s1,s1,1
    80001cfa:	00d4949b          	slliw	s1,s1,0xd
    80001cfe:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001d02:	4699                	li	a3,6
    80001d04:	6605                	lui	a2,0x1
    80001d06:	8526                	mv	a0,s1
    80001d08:	00000097          	auipc	ra,0x0
    80001d0c:	870080e7          	jalr	-1936(ra) # 80001578 <kvmmap>
      p->kstack = va;
    80001d10:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d14:	17090913          	addi	s2,s2,368
    80001d18:	fb491de3          	bne	s2,s4,80001cd2 <procinit+0x58>
  kvminithart();
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	768080e7          	jalr	1896(ra) # 80001484 <kvminithart>
}
    80001d24:	60a6                	ld	ra,72(sp)
    80001d26:	6406                	ld	s0,64(sp)
    80001d28:	74e2                	ld	s1,56(sp)
    80001d2a:	7942                	ld	s2,48(sp)
    80001d2c:	79a2                	ld	s3,40(sp)
    80001d2e:	7a02                	ld	s4,32(sp)
    80001d30:	6ae2                	ld	s5,24(sp)
    80001d32:	6b42                	ld	s6,16(sp)
    80001d34:	6ba2                	ld	s7,8(sp)
    80001d36:	6161                	addi	sp,sp,80
    80001d38:	8082                	ret
        panic("kalloc");
    80001d3a:	00006517          	auipc	a0,0x6
    80001d3e:	53650513          	addi	a0,a0,1334 # 80008270 <digits+0x230>
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	80e080e7          	jalr	-2034(ra) # 80000550 <panic>

0000000080001d4a <cpuid>:
{
    80001d4a:	1141                	addi	sp,sp,-16
    80001d4c:	e422                	sd	s0,8(sp)
    80001d4e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d50:	8512                	mv	a0,tp
}
    80001d52:	2501                	sext.w	a0,a0
    80001d54:	6422                	ld	s0,8(sp)
    80001d56:	0141                	addi	sp,sp,16
    80001d58:	8082                	ret

0000000080001d5a <mycpu>:
mycpu(void) {
    80001d5a:	1141                	addi	sp,sp,-16
    80001d5c:	e422                	sd	s0,8(sp)
    80001d5e:	0800                	addi	s0,sp,16
    80001d60:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001d62:	2781                	sext.w	a5,a5
    80001d64:	079e                	slli	a5,a5,0x7
}
    80001d66:	00010517          	auipc	a0,0x10
    80001d6a:	64250513          	addi	a0,a0,1602 # 800123a8 <cpus>
    80001d6e:	953e                	add	a0,a0,a5
    80001d70:	6422                	ld	s0,8(sp)
    80001d72:	0141                	addi	sp,sp,16
    80001d74:	8082                	ret

0000000080001d76 <myproc>:
myproc(void) {
    80001d76:	1101                	addi	sp,sp,-32
    80001d78:	ec06                	sd	ra,24(sp)
    80001d7a:	e822                	sd	s0,16(sp)
    80001d7c:	e426                	sd	s1,8(sp)
    80001d7e:	1000                	addi	s0,sp,32
  push_off();
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	f62080e7          	jalr	-158(ra) # 80000ce2 <push_off>
    80001d88:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001d8a:	2781                	sext.w	a5,a5
    80001d8c:	079e                	slli	a5,a5,0x7
    80001d8e:	00010717          	auipc	a4,0x10
    80001d92:	5fa70713          	addi	a4,a4,1530 # 80012388 <pid_lock>
    80001d96:	97ba                	add	a5,a5,a4
    80001d98:	7384                	ld	s1,32(a5)
  pop_off();
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	004080e7          	jalr	4(ra) # 80000d9e <pop_off>
}
    80001da2:	8526                	mv	a0,s1
    80001da4:	60e2                	ld	ra,24(sp)
    80001da6:	6442                	ld	s0,16(sp)
    80001da8:	64a2                	ld	s1,8(sp)
    80001daa:	6105                	addi	sp,sp,32
    80001dac:	8082                	ret

0000000080001dae <forkret>:
{
    80001dae:	1141                	addi	sp,sp,-16
    80001db0:	e406                	sd	ra,8(sp)
    80001db2:	e022                	sd	s0,0(sp)
    80001db4:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001db6:	00000097          	auipc	ra,0x0
    80001dba:	fc0080e7          	jalr	-64(ra) # 80001d76 <myproc>
    80001dbe:	fffff097          	auipc	ra,0xfffff
    80001dc2:	040080e7          	jalr	64(ra) # 80000dfe <release>
  if (first) {
    80001dc6:	00007797          	auipc	a5,0x7
    80001dca:	b0a7a783          	lw	a5,-1270(a5) # 800088d0 <first.1672>
    80001dce:	eb89                	bnez	a5,80001de0 <forkret+0x32>
  usertrapret();
    80001dd0:	00001097          	auipc	ra,0x1
    80001dd4:	c1c080e7          	jalr	-996(ra) # 800029ec <usertrapret>
}
    80001dd8:	60a2                	ld	ra,8(sp)
    80001dda:	6402                	ld	s0,0(sp)
    80001ddc:	0141                	addi	sp,sp,16
    80001dde:	8082                	ret
    first = 0;
    80001de0:	00007797          	auipc	a5,0x7
    80001de4:	ae07a823          	sw	zero,-1296(a5) # 800088d0 <first.1672>
    fsinit(ROOTDEV);
    80001de8:	4505                	li	a0,1
    80001dea:	00002097          	auipc	ra,0x2
    80001dee:	9fc080e7          	jalr	-1540(ra) # 800037e6 <fsinit>
    80001df2:	bff9                	j	80001dd0 <forkret+0x22>

0000000080001df4 <allocpid>:
allocpid() {
    80001df4:	1101                	addi	sp,sp,-32
    80001df6:	ec06                	sd	ra,24(sp)
    80001df8:	e822                	sd	s0,16(sp)
    80001dfa:	e426                	sd	s1,8(sp)
    80001dfc:	e04a                	sd	s2,0(sp)
    80001dfe:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001e00:	00010917          	auipc	s2,0x10
    80001e04:	58890913          	addi	s2,s2,1416 # 80012388 <pid_lock>
    80001e08:	854a                	mv	a0,s2
    80001e0a:	fffff097          	auipc	ra,0xfffff
    80001e0e:	f24080e7          	jalr	-220(ra) # 80000d2e <acquire>
  pid = nextpid;
    80001e12:	00007797          	auipc	a5,0x7
    80001e16:	ac278793          	addi	a5,a5,-1342 # 800088d4 <nextpid>
    80001e1a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001e1c:	0014871b          	addiw	a4,s1,1
    80001e20:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001e22:	854a                	mv	a0,s2
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	fda080e7          	jalr	-38(ra) # 80000dfe <release>
}
    80001e2c:	8526                	mv	a0,s1
    80001e2e:	60e2                	ld	ra,24(sp)
    80001e30:	6442                	ld	s0,16(sp)
    80001e32:	64a2                	ld	s1,8(sp)
    80001e34:	6902                	ld	s2,0(sp)
    80001e36:	6105                	addi	sp,sp,32
    80001e38:	8082                	ret

0000000080001e3a <proc_pagetable>:
{
    80001e3a:	1101                	addi	sp,sp,-32
    80001e3c:	ec06                	sd	ra,24(sp)
    80001e3e:	e822                	sd	s0,16(sp)
    80001e40:	e426                	sd	s1,8(sp)
    80001e42:	e04a                	sd	s2,0(sp)
    80001e44:	1000                	addi	s0,sp,32
    80001e46:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e48:	00000097          	auipc	ra,0x0
    80001e4c:	8ea080e7          	jalr	-1814(ra) # 80001732 <uvmcreate>
    80001e50:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e52:	c121                	beqz	a0,80001e92 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e54:	4729                	li	a4,10
    80001e56:	00005697          	auipc	a3,0x5
    80001e5a:	1aa68693          	addi	a3,a3,426 # 80007000 <_trampoline>
    80001e5e:	6605                	lui	a2,0x1
    80001e60:	040005b7          	lui	a1,0x4000
    80001e64:	15fd                	addi	a1,a1,-1
    80001e66:	05b2                	slli	a1,a1,0xc
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	682080e7          	jalr	1666(ra) # 800014ea <mappages>
    80001e70:	02054863          	bltz	a0,80001ea0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e74:	4719                	li	a4,6
    80001e76:	06093683          	ld	a3,96(s2)
    80001e7a:	6605                	lui	a2,0x1
    80001e7c:	020005b7          	lui	a1,0x2000
    80001e80:	15fd                	addi	a1,a1,-1
    80001e82:	05b6                	slli	a1,a1,0xd
    80001e84:	8526                	mv	a0,s1
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	664080e7          	jalr	1636(ra) # 800014ea <mappages>
    80001e8e:	02054163          	bltz	a0,80001eb0 <proc_pagetable+0x76>
}
    80001e92:	8526                	mv	a0,s1
    80001e94:	60e2                	ld	ra,24(sp)
    80001e96:	6442                	ld	s0,16(sp)
    80001e98:	64a2                	ld	s1,8(sp)
    80001e9a:	6902                	ld	s2,0(sp)
    80001e9c:	6105                	addi	sp,sp,32
    80001e9e:	8082                	ret
    uvmfree(pagetable, 0);
    80001ea0:	4581                	li	a1,0
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	00000097          	auipc	ra,0x0
    80001ea8:	a8a080e7          	jalr	-1398(ra) # 8000192e <uvmfree>
    return 0;
    80001eac:	4481                	li	s1,0
    80001eae:	b7d5                	j	80001e92 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001eb0:	4681                	li	a3,0
    80001eb2:	4605                	li	a2,1
    80001eb4:	040005b7          	lui	a1,0x4000
    80001eb8:	15fd                	addi	a1,a1,-1
    80001eba:	05b2                	slli	a1,a1,0xc
    80001ebc:	8526                	mv	a0,s1
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	7b0080e7          	jalr	1968(ra) # 8000166e <uvmunmap>
    uvmfree(pagetable, 0);
    80001ec6:	4581                	li	a1,0
    80001ec8:	8526                	mv	a0,s1
    80001eca:	00000097          	auipc	ra,0x0
    80001ece:	a64080e7          	jalr	-1436(ra) # 8000192e <uvmfree>
    return 0;
    80001ed2:	4481                	li	s1,0
    80001ed4:	bf7d                	j	80001e92 <proc_pagetable+0x58>

0000000080001ed6 <proc_freepagetable>:
{
    80001ed6:	1101                	addi	sp,sp,-32
    80001ed8:	ec06                	sd	ra,24(sp)
    80001eda:	e822                	sd	s0,16(sp)
    80001edc:	e426                	sd	s1,8(sp)
    80001ede:	e04a                	sd	s2,0(sp)
    80001ee0:	1000                	addi	s0,sp,32
    80001ee2:	84aa                	mv	s1,a0
    80001ee4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ee6:	4681                	li	a3,0
    80001ee8:	4605                	li	a2,1
    80001eea:	040005b7          	lui	a1,0x4000
    80001eee:	15fd                	addi	a1,a1,-1
    80001ef0:	05b2                	slli	a1,a1,0xc
    80001ef2:	fffff097          	auipc	ra,0xfffff
    80001ef6:	77c080e7          	jalr	1916(ra) # 8000166e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001efa:	4681                	li	a3,0
    80001efc:	4605                	li	a2,1
    80001efe:	020005b7          	lui	a1,0x2000
    80001f02:	15fd                	addi	a1,a1,-1
    80001f04:	05b6                	slli	a1,a1,0xd
    80001f06:	8526                	mv	a0,s1
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	766080e7          	jalr	1894(ra) # 8000166e <uvmunmap>
  uvmfree(pagetable, sz);
    80001f10:	85ca                	mv	a1,s2
    80001f12:	8526                	mv	a0,s1
    80001f14:	00000097          	auipc	ra,0x0
    80001f18:	a1a080e7          	jalr	-1510(ra) # 8000192e <uvmfree>
}
    80001f1c:	60e2                	ld	ra,24(sp)
    80001f1e:	6442                	ld	s0,16(sp)
    80001f20:	64a2                	ld	s1,8(sp)
    80001f22:	6902                	ld	s2,0(sp)
    80001f24:	6105                	addi	sp,sp,32
    80001f26:	8082                	ret

0000000080001f28 <freeproc>:
{
    80001f28:	1101                	addi	sp,sp,-32
    80001f2a:	ec06                	sd	ra,24(sp)
    80001f2c:	e822                	sd	s0,16(sp)
    80001f2e:	e426                	sd	s1,8(sp)
    80001f30:	1000                	addi	s0,sp,32
    80001f32:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001f34:	7128                	ld	a0,96(a0)
    80001f36:	c509                	beqz	a0,80001f40 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	af4080e7          	jalr	-1292(ra) # 80000a2c <kfree>
  p->trapframe = 0;
    80001f40:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001f44:	6ca8                	ld	a0,88(s1)
    80001f46:	c511                	beqz	a0,80001f52 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f48:	68ac                	ld	a1,80(s1)
    80001f4a:	00000097          	auipc	ra,0x0
    80001f4e:	f8c080e7          	jalr	-116(ra) # 80001ed6 <proc_freepagetable>
  p->pagetable = 0;
    80001f52:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001f56:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001f5a:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001f5e:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001f62:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001f66:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001f6a:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001f6e:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001f72:	0204a023          	sw	zero,32(s1)
}
    80001f76:	60e2                	ld	ra,24(sp)
    80001f78:	6442                	ld	s0,16(sp)
    80001f7a:	64a2                	ld	s1,8(sp)
    80001f7c:	6105                	addi	sp,sp,32
    80001f7e:	8082                	ret

0000000080001f80 <allocproc>:
{
    80001f80:	1101                	addi	sp,sp,-32
    80001f82:	ec06                	sd	ra,24(sp)
    80001f84:	e822                	sd	s0,16(sp)
    80001f86:	e426                	sd	s1,8(sp)
    80001f88:	e04a                	sd	s2,0(sp)
    80001f8a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f8c:	00011497          	auipc	s1,0x11
    80001f90:	81c48493          	addi	s1,s1,-2020 # 800127a8 <proc>
    80001f94:	00016917          	auipc	s2,0x16
    80001f98:	41490913          	addi	s2,s2,1044 # 800183a8 <tickslock>
    acquire(&p->lock);
    80001f9c:	8526                	mv	a0,s1
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	d90080e7          	jalr	-624(ra) # 80000d2e <acquire>
    if(p->state == UNUSED) {
    80001fa6:	509c                	lw	a5,32(s1)
    80001fa8:	cf81                	beqz	a5,80001fc0 <allocproc+0x40>
      release(&p->lock);
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	e52080e7          	jalr	-430(ra) # 80000dfe <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fb4:	17048493          	addi	s1,s1,368
    80001fb8:	ff2492e3          	bne	s1,s2,80001f9c <allocproc+0x1c>
  return 0;
    80001fbc:	4481                	li	s1,0
    80001fbe:	a0b9                	j	8000200c <allocproc+0x8c>
  p->pid = allocpid();
    80001fc0:	00000097          	auipc	ra,0x0
    80001fc4:	e34080e7          	jalr	-460(ra) # 80001df4 <allocpid>
    80001fc8:	c0a8                	sw	a0,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001fca:	fffff097          	auipc	ra,0xfffff
    80001fce:	c52080e7          	jalr	-942(ra) # 80000c1c <kalloc>
    80001fd2:	892a                	mv	s2,a0
    80001fd4:	f0a8                	sd	a0,96(s1)
    80001fd6:	c131                	beqz	a0,8000201a <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001fd8:	8526                	mv	a0,s1
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	e60080e7          	jalr	-416(ra) # 80001e3a <proc_pagetable>
    80001fe2:	892a                	mv	s2,a0
    80001fe4:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001fe6:	c129                	beqz	a0,80002028 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001fe8:	07000613          	li	a2,112
    80001fec:	4581                	li	a1,0
    80001fee:	06848513          	addi	a0,s1,104
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	11c080e7          	jalr	284(ra) # 8000110e <memset>
  p->context.ra = (uint64)forkret;
    80001ffa:	00000797          	auipc	a5,0x0
    80001ffe:	db478793          	addi	a5,a5,-588 # 80001dae <forkret>
    80002002:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002004:	64bc                	ld	a5,72(s1)
    80002006:	6705                	lui	a4,0x1
    80002008:	97ba                	add	a5,a5,a4
    8000200a:	f8bc                	sd	a5,112(s1)
}
    8000200c:	8526                	mv	a0,s1
    8000200e:	60e2                	ld	ra,24(sp)
    80002010:	6442                	ld	s0,16(sp)
    80002012:	64a2                	ld	s1,8(sp)
    80002014:	6902                	ld	s2,0(sp)
    80002016:	6105                	addi	sp,sp,32
    80002018:	8082                	ret
    release(&p->lock);
    8000201a:	8526                	mv	a0,s1
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	de2080e7          	jalr	-542(ra) # 80000dfe <release>
    return 0;
    80002024:	84ca                	mv	s1,s2
    80002026:	b7dd                	j	8000200c <allocproc+0x8c>
    freeproc(p);
    80002028:	8526                	mv	a0,s1
    8000202a:	00000097          	auipc	ra,0x0
    8000202e:	efe080e7          	jalr	-258(ra) # 80001f28 <freeproc>
    release(&p->lock);
    80002032:	8526                	mv	a0,s1
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	dca080e7          	jalr	-566(ra) # 80000dfe <release>
    return 0;
    8000203c:	84ca                	mv	s1,s2
    8000203e:	b7f9                	j	8000200c <allocproc+0x8c>

0000000080002040 <userinit>:
{
    80002040:	1101                	addi	sp,sp,-32
    80002042:	ec06                	sd	ra,24(sp)
    80002044:	e822                	sd	s0,16(sp)
    80002046:	e426                	sd	s1,8(sp)
    80002048:	1000                	addi	s0,sp,32
  p = allocproc();
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	f36080e7          	jalr	-202(ra) # 80001f80 <allocproc>
    80002052:	84aa                	mv	s1,a0
  initproc = p;
    80002054:	00007797          	auipc	a5,0x7
    80002058:	fca7b223          	sd	a0,-60(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000205c:	03400613          	li	a2,52
    80002060:	00007597          	auipc	a1,0x7
    80002064:	88058593          	addi	a1,a1,-1920 # 800088e0 <initcode>
    80002068:	6d28                	ld	a0,88(a0)
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	6f6080e7          	jalr	1782(ra) # 80001760 <uvminit>
  p->sz = PGSIZE;
    80002072:	6785                	lui	a5,0x1
    80002074:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80002076:	70b8                	ld	a4,96(s1)
    80002078:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000207c:	70b8                	ld	a4,96(s1)
    8000207e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002080:	4641                	li	a2,16
    80002082:	00006597          	auipc	a1,0x6
    80002086:	1f658593          	addi	a1,a1,502 # 80008278 <digits+0x238>
    8000208a:	16048513          	addi	a0,s1,352
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	1d6080e7          	jalr	470(ra) # 80001264 <safestrcpy>
  p->cwd = namei("/");
    80002096:	00006517          	auipc	a0,0x6
    8000209a:	1f250513          	addi	a0,a0,498 # 80008288 <digits+0x248>
    8000209e:	00002097          	auipc	ra,0x2
    800020a2:	174080e7          	jalr	372(ra) # 80004212 <namei>
    800020a6:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    800020aa:	4789                	li	a5,2
    800020ac:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    800020ae:	8526                	mv	a0,s1
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	d4e080e7          	jalr	-690(ra) # 80000dfe <release>
}
    800020b8:	60e2                	ld	ra,24(sp)
    800020ba:	6442                	ld	s0,16(sp)
    800020bc:	64a2                	ld	s1,8(sp)
    800020be:	6105                	addi	sp,sp,32
    800020c0:	8082                	ret

00000000800020c2 <growproc>:
{
    800020c2:	1101                	addi	sp,sp,-32
    800020c4:	ec06                	sd	ra,24(sp)
    800020c6:	e822                	sd	s0,16(sp)
    800020c8:	e426                	sd	s1,8(sp)
    800020ca:	e04a                	sd	s2,0(sp)
    800020cc:	1000                	addi	s0,sp,32
    800020ce:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	ca6080e7          	jalr	-858(ra) # 80001d76 <myproc>
    800020d8:	892a                	mv	s2,a0
  sz = p->sz;
    800020da:	692c                	ld	a1,80(a0)
    800020dc:	0005861b          	sext.w	a2,a1
  if(n > 0){
    800020e0:	00904f63          	bgtz	s1,800020fe <growproc+0x3c>
  } else if(n < 0){
    800020e4:	0204cc63          	bltz	s1,8000211c <growproc+0x5a>
  p->sz = sz;
    800020e8:	1602                	slli	a2,a2,0x20
    800020ea:	9201                	srli	a2,a2,0x20
    800020ec:	04c93823          	sd	a2,80(s2)
  return 0;
    800020f0:	4501                	li	a0,0
}
    800020f2:	60e2                	ld	ra,24(sp)
    800020f4:	6442                	ld	s0,16(sp)
    800020f6:	64a2                	ld	s1,8(sp)
    800020f8:	6902                	ld	s2,0(sp)
    800020fa:	6105                	addi	sp,sp,32
    800020fc:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800020fe:	9e25                	addw	a2,a2,s1
    80002100:	1602                	slli	a2,a2,0x20
    80002102:	9201                	srli	a2,a2,0x20
    80002104:	1582                	slli	a1,a1,0x20
    80002106:	9181                	srli	a1,a1,0x20
    80002108:	6d28                	ld	a0,88(a0)
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	710080e7          	jalr	1808(ra) # 8000181a <uvmalloc>
    80002112:	0005061b          	sext.w	a2,a0
    80002116:	fa69                	bnez	a2,800020e8 <growproc+0x26>
      return -1;
    80002118:	557d                	li	a0,-1
    8000211a:	bfe1                	j	800020f2 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000211c:	9e25                	addw	a2,a2,s1
    8000211e:	1602                	slli	a2,a2,0x20
    80002120:	9201                	srli	a2,a2,0x20
    80002122:	1582                	slli	a1,a1,0x20
    80002124:	9181                	srli	a1,a1,0x20
    80002126:	6d28                	ld	a0,88(a0)
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	6aa080e7          	jalr	1706(ra) # 800017d2 <uvmdealloc>
    80002130:	0005061b          	sext.w	a2,a0
    80002134:	bf55                	j	800020e8 <growproc+0x26>

0000000080002136 <fork>:
{
    80002136:	7179                	addi	sp,sp,-48
    80002138:	f406                	sd	ra,40(sp)
    8000213a:	f022                	sd	s0,32(sp)
    8000213c:	ec26                	sd	s1,24(sp)
    8000213e:	e84a                	sd	s2,16(sp)
    80002140:	e44e                	sd	s3,8(sp)
    80002142:	e052                	sd	s4,0(sp)
    80002144:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002146:	00000097          	auipc	ra,0x0
    8000214a:	c30080e7          	jalr	-976(ra) # 80001d76 <myproc>
    8000214e:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002150:	00000097          	auipc	ra,0x0
    80002154:	e30080e7          	jalr	-464(ra) # 80001f80 <allocproc>
    80002158:	c175                	beqz	a0,8000223c <fork+0x106>
    8000215a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000215c:	05093603          	ld	a2,80(s2)
    80002160:	6d2c                	ld	a1,88(a0)
    80002162:	05893503          	ld	a0,88(s2)
    80002166:	00000097          	auipc	ra,0x0
    8000216a:	800080e7          	jalr	-2048(ra) # 80001966 <uvmcopy>
    8000216e:	04054863          	bltz	a0,800021be <fork+0x88>
  np->sz = p->sz;
    80002172:	05093783          	ld	a5,80(s2)
    80002176:	04f9b823          	sd	a5,80(s3) # 4000050 <_entry-0x7bffffb0>
  np->parent = p;
    8000217a:	0329b423          	sd	s2,40(s3)
  *(np->trapframe) = *(p->trapframe);
    8000217e:	06093683          	ld	a3,96(s2)
    80002182:	87b6                	mv	a5,a3
    80002184:	0609b703          	ld	a4,96(s3)
    80002188:	12068693          	addi	a3,a3,288
    8000218c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002190:	6788                	ld	a0,8(a5)
    80002192:	6b8c                	ld	a1,16(a5)
    80002194:	6f90                	ld	a2,24(a5)
    80002196:	01073023          	sd	a6,0(a4)
    8000219a:	e708                	sd	a0,8(a4)
    8000219c:	eb0c                	sd	a1,16(a4)
    8000219e:	ef10                	sd	a2,24(a4)
    800021a0:	02078793          	addi	a5,a5,32
    800021a4:	02070713          	addi	a4,a4,32
    800021a8:	fed792e3          	bne	a5,a3,8000218c <fork+0x56>
  np->trapframe->a0 = 0;
    800021ac:	0609b783          	ld	a5,96(s3)
    800021b0:	0607b823          	sd	zero,112(a5)
    800021b4:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    800021b8:	15800a13          	li	s4,344
    800021bc:	a03d                	j	800021ea <fork+0xb4>
    freeproc(np);
    800021be:	854e                	mv	a0,s3
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	d68080e7          	jalr	-664(ra) # 80001f28 <freeproc>
    release(&np->lock);
    800021c8:	854e                	mv	a0,s3
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	c34080e7          	jalr	-972(ra) # 80000dfe <release>
    return -1;
    800021d2:	54fd                	li	s1,-1
    800021d4:	a899                	j	8000222a <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    800021d6:	00002097          	auipc	ra,0x2
    800021da:	6da080e7          	jalr	1754(ra) # 800048b0 <filedup>
    800021de:	009987b3          	add	a5,s3,s1
    800021e2:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800021e4:	04a1                	addi	s1,s1,8
    800021e6:	01448763          	beq	s1,s4,800021f4 <fork+0xbe>
    if(p->ofile[i])
    800021ea:	009907b3          	add	a5,s2,s1
    800021ee:	6388                	ld	a0,0(a5)
    800021f0:	f17d                	bnez	a0,800021d6 <fork+0xa0>
    800021f2:	bfcd                	j	800021e4 <fork+0xae>
  np->cwd = idup(p->cwd);
    800021f4:	15893503          	ld	a0,344(s2)
    800021f8:	00002097          	auipc	ra,0x2
    800021fc:	828080e7          	jalr	-2008(ra) # 80003a20 <idup>
    80002200:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002204:	4641                	li	a2,16
    80002206:	16090593          	addi	a1,s2,352
    8000220a:	16098513          	addi	a0,s3,352
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	056080e7          	jalr	86(ra) # 80001264 <safestrcpy>
  pid = np->pid;
    80002216:	0409a483          	lw	s1,64(s3)
  np->state = RUNNABLE;
    8000221a:	4789                	li	a5,2
    8000221c:	02f9a023          	sw	a5,32(s3)
  release(&np->lock);
    80002220:	854e                	mv	a0,s3
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	bdc080e7          	jalr	-1060(ra) # 80000dfe <release>
}
    8000222a:	8526                	mv	a0,s1
    8000222c:	70a2                	ld	ra,40(sp)
    8000222e:	7402                	ld	s0,32(sp)
    80002230:	64e2                	ld	s1,24(sp)
    80002232:	6942                	ld	s2,16(sp)
    80002234:	69a2                	ld	s3,8(sp)
    80002236:	6a02                	ld	s4,0(sp)
    80002238:	6145                	addi	sp,sp,48
    8000223a:	8082                	ret
    return -1;
    8000223c:	54fd                	li	s1,-1
    8000223e:	b7f5                	j	8000222a <fork+0xf4>

0000000080002240 <reparent>:
{
    80002240:	7179                	addi	sp,sp,-48
    80002242:	f406                	sd	ra,40(sp)
    80002244:	f022                	sd	s0,32(sp)
    80002246:	ec26                	sd	s1,24(sp)
    80002248:	e84a                	sd	s2,16(sp)
    8000224a:	e44e                	sd	s3,8(sp)
    8000224c:	e052                	sd	s4,0(sp)
    8000224e:	1800                	addi	s0,sp,48
    80002250:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002252:	00010497          	auipc	s1,0x10
    80002256:	55648493          	addi	s1,s1,1366 # 800127a8 <proc>
      pp->parent = initproc;
    8000225a:	00007a17          	auipc	s4,0x7
    8000225e:	dbea0a13          	addi	s4,s4,-578 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002262:	00016997          	auipc	s3,0x16
    80002266:	14698993          	addi	s3,s3,326 # 800183a8 <tickslock>
    8000226a:	a029                	j	80002274 <reparent+0x34>
    8000226c:	17048493          	addi	s1,s1,368
    80002270:	03348363          	beq	s1,s3,80002296 <reparent+0x56>
    if(pp->parent == p){
    80002274:	749c                	ld	a5,40(s1)
    80002276:	ff279be3          	bne	a5,s2,8000226c <reparent+0x2c>
      acquire(&pp->lock);
    8000227a:	8526                	mv	a0,s1
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	ab2080e7          	jalr	-1358(ra) # 80000d2e <acquire>
      pp->parent = initproc;
    80002284:	000a3783          	ld	a5,0(s4)
    80002288:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    8000228a:	8526                	mv	a0,s1
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	b72080e7          	jalr	-1166(ra) # 80000dfe <release>
    80002294:	bfe1                	j	8000226c <reparent+0x2c>
}
    80002296:	70a2                	ld	ra,40(sp)
    80002298:	7402                	ld	s0,32(sp)
    8000229a:	64e2                	ld	s1,24(sp)
    8000229c:	6942                	ld	s2,16(sp)
    8000229e:	69a2                	ld	s3,8(sp)
    800022a0:	6a02                	ld	s4,0(sp)
    800022a2:	6145                	addi	sp,sp,48
    800022a4:	8082                	ret

00000000800022a6 <scheduler>:
{
    800022a6:	711d                	addi	sp,sp,-96
    800022a8:	ec86                	sd	ra,88(sp)
    800022aa:	e8a2                	sd	s0,80(sp)
    800022ac:	e4a6                	sd	s1,72(sp)
    800022ae:	e0ca                	sd	s2,64(sp)
    800022b0:	fc4e                	sd	s3,56(sp)
    800022b2:	f852                	sd	s4,48(sp)
    800022b4:	f456                	sd	s5,40(sp)
    800022b6:	f05a                	sd	s6,32(sp)
    800022b8:	ec5e                	sd	s7,24(sp)
    800022ba:	e862                	sd	s8,16(sp)
    800022bc:	e466                	sd	s9,8(sp)
    800022be:	1080                	addi	s0,sp,96
    800022c0:	8792                	mv	a5,tp
  int id = r_tp();
    800022c2:	2781                	sext.w	a5,a5
  c->proc = 0;
    800022c4:	00779c13          	slli	s8,a5,0x7
    800022c8:	00010717          	auipc	a4,0x10
    800022cc:	0c070713          	addi	a4,a4,192 # 80012388 <pid_lock>
    800022d0:	9762                	add	a4,a4,s8
    800022d2:	02073023          	sd	zero,32(a4)
        swtch(&c->context, &p->context);
    800022d6:	00010717          	auipc	a4,0x10
    800022da:	0da70713          	addi	a4,a4,218 # 800123b0 <cpus+0x8>
    800022de:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    800022e0:	4a89                	li	s5,2
        c->proc = p;
    800022e2:	079e                	slli	a5,a5,0x7
    800022e4:	00010b17          	auipc	s6,0x10
    800022e8:	0a4b0b13          	addi	s6,s6,164 # 80012388 <pid_lock>
    800022ec:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800022ee:	00016a17          	auipc	s4,0x16
    800022f2:	0baa0a13          	addi	s4,s4,186 # 800183a8 <tickslock>
    int nproc = 0;
    800022f6:	4c81                	li	s9,0
    800022f8:	a8a1                	j	80002350 <scheduler+0xaa>
        p->state = RUNNING;
    800022fa:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    800022fe:	029b3023          	sd	s1,32(s6)
        swtch(&c->context, &p->context);
    80002302:	06848593          	addi	a1,s1,104
    80002306:	8562                	mv	a0,s8
    80002308:	00000097          	auipc	ra,0x0
    8000230c:	63a080e7          	jalr	1594(ra) # 80002942 <swtch>
        c->proc = 0;
    80002310:	020b3023          	sd	zero,32(s6)
      release(&p->lock);
    80002314:	8526                	mv	a0,s1
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	ae8080e7          	jalr	-1304(ra) # 80000dfe <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000231e:	17048493          	addi	s1,s1,368
    80002322:	01448d63          	beq	s1,s4,8000233c <scheduler+0x96>
      acquire(&p->lock);
    80002326:	8526                	mv	a0,s1
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	a06080e7          	jalr	-1530(ra) # 80000d2e <acquire>
      if(p->state != UNUSED) {
    80002330:	509c                	lw	a5,32(s1)
    80002332:	d3ed                	beqz	a5,80002314 <scheduler+0x6e>
        nproc++;
    80002334:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80002336:	fd579fe3          	bne	a5,s5,80002314 <scheduler+0x6e>
    8000233a:	b7c1                	j	800022fa <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    8000233c:	013aca63          	blt	s5,s3,80002350 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002340:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002344:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002348:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000234c:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002350:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002354:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002358:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    8000235c:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    8000235e:	00010497          	auipc	s1,0x10
    80002362:	44a48493          	addi	s1,s1,1098 # 800127a8 <proc>
        p->state = RUNNING;
    80002366:	4b8d                	li	s7,3
    80002368:	bf7d                	j	80002326 <scheduler+0x80>

000000008000236a <sched>:
{
    8000236a:	7179                	addi	sp,sp,-48
    8000236c:	f406                	sd	ra,40(sp)
    8000236e:	f022                	sd	s0,32(sp)
    80002370:	ec26                	sd	s1,24(sp)
    80002372:	e84a                	sd	s2,16(sp)
    80002374:	e44e                	sd	s3,8(sp)
    80002376:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002378:	00000097          	auipc	ra,0x0
    8000237c:	9fe080e7          	jalr	-1538(ra) # 80001d76 <myproc>
    80002380:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	932080e7          	jalr	-1742(ra) # 80000cb4 <holding>
    8000238a:	c93d                	beqz	a0,80002400 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000238c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000238e:	2781                	sext.w	a5,a5
    80002390:	079e                	slli	a5,a5,0x7
    80002392:	00010717          	auipc	a4,0x10
    80002396:	ff670713          	addi	a4,a4,-10 # 80012388 <pid_lock>
    8000239a:	97ba                	add	a5,a5,a4
    8000239c:	0987a703          	lw	a4,152(a5)
    800023a0:	4785                	li	a5,1
    800023a2:	06f71763          	bne	a4,a5,80002410 <sched+0xa6>
  if(p->state == RUNNING)
    800023a6:	5098                	lw	a4,32(s1)
    800023a8:	478d                	li	a5,3
    800023aa:	06f70b63          	beq	a4,a5,80002420 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023ae:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023b2:	8b89                	andi	a5,a5,2
  if(intr_get())
    800023b4:	efb5                	bnez	a5,80002430 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023b6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800023b8:	00010917          	auipc	s2,0x10
    800023bc:	fd090913          	addi	s2,s2,-48 # 80012388 <pid_lock>
    800023c0:	2781                	sext.w	a5,a5
    800023c2:	079e                	slli	a5,a5,0x7
    800023c4:	97ca                	add	a5,a5,s2
    800023c6:	09c7a983          	lw	s3,156(a5)
    800023ca:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800023cc:	2781                	sext.w	a5,a5
    800023ce:	079e                	slli	a5,a5,0x7
    800023d0:	00010597          	auipc	a1,0x10
    800023d4:	fe058593          	addi	a1,a1,-32 # 800123b0 <cpus+0x8>
    800023d8:	95be                	add	a1,a1,a5
    800023da:	06848513          	addi	a0,s1,104
    800023de:	00000097          	auipc	ra,0x0
    800023e2:	564080e7          	jalr	1380(ra) # 80002942 <swtch>
    800023e6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023e8:	2781                	sext.w	a5,a5
    800023ea:	079e                	slli	a5,a5,0x7
    800023ec:	97ca                	add	a5,a5,s2
    800023ee:	0937ae23          	sw	s3,156(a5)
}
    800023f2:	70a2                	ld	ra,40(sp)
    800023f4:	7402                	ld	s0,32(sp)
    800023f6:	64e2                	ld	s1,24(sp)
    800023f8:	6942                	ld	s2,16(sp)
    800023fa:	69a2                	ld	s3,8(sp)
    800023fc:	6145                	addi	sp,sp,48
    800023fe:	8082                	ret
    panic("sched p->lock");
    80002400:	00006517          	auipc	a0,0x6
    80002404:	e9050513          	addi	a0,a0,-368 # 80008290 <digits+0x250>
    80002408:	ffffe097          	auipc	ra,0xffffe
    8000240c:	148080e7          	jalr	328(ra) # 80000550 <panic>
    panic("sched locks");
    80002410:	00006517          	auipc	a0,0x6
    80002414:	e9050513          	addi	a0,a0,-368 # 800082a0 <digits+0x260>
    80002418:	ffffe097          	auipc	ra,0xffffe
    8000241c:	138080e7          	jalr	312(ra) # 80000550 <panic>
    panic("sched running");
    80002420:	00006517          	auipc	a0,0x6
    80002424:	e9050513          	addi	a0,a0,-368 # 800082b0 <digits+0x270>
    80002428:	ffffe097          	auipc	ra,0xffffe
    8000242c:	128080e7          	jalr	296(ra) # 80000550 <panic>
    panic("sched interruptible");
    80002430:	00006517          	auipc	a0,0x6
    80002434:	e9050513          	addi	a0,a0,-368 # 800082c0 <digits+0x280>
    80002438:	ffffe097          	auipc	ra,0xffffe
    8000243c:	118080e7          	jalr	280(ra) # 80000550 <panic>

0000000080002440 <exit>:
{
    80002440:	7179                	addi	sp,sp,-48
    80002442:	f406                	sd	ra,40(sp)
    80002444:	f022                	sd	s0,32(sp)
    80002446:	ec26                	sd	s1,24(sp)
    80002448:	e84a                	sd	s2,16(sp)
    8000244a:	e44e                	sd	s3,8(sp)
    8000244c:	e052                	sd	s4,0(sp)
    8000244e:	1800                	addi	s0,sp,48
    80002450:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002452:	00000097          	auipc	ra,0x0
    80002456:	924080e7          	jalr	-1756(ra) # 80001d76 <myproc>
    8000245a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000245c:	00007797          	auipc	a5,0x7
    80002460:	bbc7b783          	ld	a5,-1092(a5) # 80009018 <initproc>
    80002464:	0d850493          	addi	s1,a0,216
    80002468:	15850913          	addi	s2,a0,344
    8000246c:	02a79363          	bne	a5,a0,80002492 <exit+0x52>
    panic("init exiting");
    80002470:	00006517          	auipc	a0,0x6
    80002474:	e6850513          	addi	a0,a0,-408 # 800082d8 <digits+0x298>
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	0d8080e7          	jalr	216(ra) # 80000550 <panic>
      fileclose(f);
    80002480:	00002097          	auipc	ra,0x2
    80002484:	482080e7          	jalr	1154(ra) # 80004902 <fileclose>
      p->ofile[fd] = 0;
    80002488:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000248c:	04a1                	addi	s1,s1,8
    8000248e:	01248563          	beq	s1,s2,80002498 <exit+0x58>
    if(p->ofile[fd]){
    80002492:	6088                	ld	a0,0(s1)
    80002494:	f575                	bnez	a0,80002480 <exit+0x40>
    80002496:	bfdd                	j	8000248c <exit+0x4c>
  begin_op();
    80002498:	00002097          	auipc	ra,0x2
    8000249c:	f96080e7          	jalr	-106(ra) # 8000442e <begin_op>
  iput(p->cwd);
    800024a0:	1589b503          	ld	a0,344(s3)
    800024a4:	00001097          	auipc	ra,0x1
    800024a8:	774080e7          	jalr	1908(ra) # 80003c18 <iput>
  end_op();
    800024ac:	00002097          	auipc	ra,0x2
    800024b0:	002080e7          	jalr	2(ra) # 800044ae <end_op>
  p->cwd = 0;
    800024b4:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    800024b8:	00007497          	auipc	s1,0x7
    800024bc:	b6048493          	addi	s1,s1,-1184 # 80009018 <initproc>
    800024c0:	6088                	ld	a0,0(s1)
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	86c080e7          	jalr	-1940(ra) # 80000d2e <acquire>
  wakeup1(initproc);
    800024ca:	6088                	ld	a0,0(s1)
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	76a080e7          	jalr	1898(ra) # 80001c36 <wakeup1>
  release(&initproc->lock);
    800024d4:	6088                	ld	a0,0(s1)
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	928080e7          	jalr	-1752(ra) # 80000dfe <release>
  acquire(&p->lock);
    800024de:	854e                	mv	a0,s3
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	84e080e7          	jalr	-1970(ra) # 80000d2e <acquire>
  struct proc *original_parent = p->parent;
    800024e8:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    800024ec:	854e                	mv	a0,s3
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	910080e7          	jalr	-1776(ra) # 80000dfe <release>
  acquire(&original_parent->lock);
    800024f6:	8526                	mv	a0,s1
    800024f8:	fffff097          	auipc	ra,0xfffff
    800024fc:	836080e7          	jalr	-1994(ra) # 80000d2e <acquire>
  acquire(&p->lock);
    80002500:	854e                	mv	a0,s3
    80002502:	fffff097          	auipc	ra,0xfffff
    80002506:	82c080e7          	jalr	-2004(ra) # 80000d2e <acquire>
  reparent(p);
    8000250a:	854e                	mv	a0,s3
    8000250c:	00000097          	auipc	ra,0x0
    80002510:	d34080e7          	jalr	-716(ra) # 80002240 <reparent>
  wakeup1(original_parent);
    80002514:	8526                	mv	a0,s1
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	720080e7          	jalr	1824(ra) # 80001c36 <wakeup1>
  p->xstate = status;
    8000251e:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    80002522:	4791                	li	a5,4
    80002524:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    80002528:	8526                	mv	a0,s1
    8000252a:	fffff097          	auipc	ra,0xfffff
    8000252e:	8d4080e7          	jalr	-1836(ra) # 80000dfe <release>
  sched();
    80002532:	00000097          	auipc	ra,0x0
    80002536:	e38080e7          	jalr	-456(ra) # 8000236a <sched>
  panic("zombie exit");
    8000253a:	00006517          	auipc	a0,0x6
    8000253e:	dae50513          	addi	a0,a0,-594 # 800082e8 <digits+0x2a8>
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	00e080e7          	jalr	14(ra) # 80000550 <panic>

000000008000254a <yield>:
{
    8000254a:	1101                	addi	sp,sp,-32
    8000254c:	ec06                	sd	ra,24(sp)
    8000254e:	e822                	sd	s0,16(sp)
    80002550:	e426                	sd	s1,8(sp)
    80002552:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002554:	00000097          	auipc	ra,0x0
    80002558:	822080e7          	jalr	-2014(ra) # 80001d76 <myproc>
    8000255c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	7d0080e7          	jalr	2000(ra) # 80000d2e <acquire>
  p->state = RUNNABLE;
    80002566:	4789                	li	a5,2
    80002568:	d09c                	sw	a5,32(s1)
  sched();
    8000256a:	00000097          	auipc	ra,0x0
    8000256e:	e00080e7          	jalr	-512(ra) # 8000236a <sched>
  release(&p->lock);
    80002572:	8526                	mv	a0,s1
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	88a080e7          	jalr	-1910(ra) # 80000dfe <release>
}
    8000257c:	60e2                	ld	ra,24(sp)
    8000257e:	6442                	ld	s0,16(sp)
    80002580:	64a2                	ld	s1,8(sp)
    80002582:	6105                	addi	sp,sp,32
    80002584:	8082                	ret

0000000080002586 <sleep>:
{
    80002586:	7179                	addi	sp,sp,-48
    80002588:	f406                	sd	ra,40(sp)
    8000258a:	f022                	sd	s0,32(sp)
    8000258c:	ec26                	sd	s1,24(sp)
    8000258e:	e84a                	sd	s2,16(sp)
    80002590:	e44e                	sd	s3,8(sp)
    80002592:	1800                	addi	s0,sp,48
    80002594:	89aa                	mv	s3,a0
    80002596:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002598:	fffff097          	auipc	ra,0xfffff
    8000259c:	7de080e7          	jalr	2014(ra) # 80001d76 <myproc>
    800025a0:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800025a2:	05250663          	beq	a0,s2,800025ee <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	788080e7          	jalr	1928(ra) # 80000d2e <acquire>
    release(lk);
    800025ae:	854a                	mv	a0,s2
    800025b0:	fffff097          	auipc	ra,0xfffff
    800025b4:	84e080e7          	jalr	-1970(ra) # 80000dfe <release>
  p->chan = chan;
    800025b8:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    800025bc:	4785                	li	a5,1
    800025be:	d09c                	sw	a5,32(s1)
  sched();
    800025c0:	00000097          	auipc	ra,0x0
    800025c4:	daa080e7          	jalr	-598(ra) # 8000236a <sched>
  p->chan = 0;
    800025c8:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    800025cc:	8526                	mv	a0,s1
    800025ce:	fffff097          	auipc	ra,0xfffff
    800025d2:	830080e7          	jalr	-2000(ra) # 80000dfe <release>
    acquire(lk);
    800025d6:	854a                	mv	a0,s2
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	756080e7          	jalr	1878(ra) # 80000d2e <acquire>
}
    800025e0:	70a2                	ld	ra,40(sp)
    800025e2:	7402                	ld	s0,32(sp)
    800025e4:	64e2                	ld	s1,24(sp)
    800025e6:	6942                	ld	s2,16(sp)
    800025e8:	69a2                	ld	s3,8(sp)
    800025ea:	6145                	addi	sp,sp,48
    800025ec:	8082                	ret
  p->chan = chan;
    800025ee:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    800025f2:	4785                	li	a5,1
    800025f4:	d11c                	sw	a5,32(a0)
  sched();
    800025f6:	00000097          	auipc	ra,0x0
    800025fa:	d74080e7          	jalr	-652(ra) # 8000236a <sched>
  p->chan = 0;
    800025fe:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    80002602:	bff9                	j	800025e0 <sleep+0x5a>

0000000080002604 <wait>:
{
    80002604:	715d                	addi	sp,sp,-80
    80002606:	e486                	sd	ra,72(sp)
    80002608:	e0a2                	sd	s0,64(sp)
    8000260a:	fc26                	sd	s1,56(sp)
    8000260c:	f84a                	sd	s2,48(sp)
    8000260e:	f44e                	sd	s3,40(sp)
    80002610:	f052                	sd	s4,32(sp)
    80002612:	ec56                	sd	s5,24(sp)
    80002614:	e85a                	sd	s6,16(sp)
    80002616:	e45e                	sd	s7,8(sp)
    80002618:	e062                	sd	s8,0(sp)
    8000261a:	0880                	addi	s0,sp,80
    8000261c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000261e:	fffff097          	auipc	ra,0xfffff
    80002622:	758080e7          	jalr	1880(ra) # 80001d76 <myproc>
    80002626:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002628:	8c2a                	mv	s8,a0
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	704080e7          	jalr	1796(ra) # 80000d2e <acquire>
    havekids = 0;
    80002632:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002634:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002636:	00016997          	auipc	s3,0x16
    8000263a:	d7298993          	addi	s3,s3,-654 # 800183a8 <tickslock>
        havekids = 1;
    8000263e:	4a85                	li	s5,1
    havekids = 0;
    80002640:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002642:	00010497          	auipc	s1,0x10
    80002646:	16648493          	addi	s1,s1,358 # 800127a8 <proc>
    8000264a:	a08d                	j	800026ac <wait+0xa8>
          pid = np->pid;
    8000264c:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002650:	000b0e63          	beqz	s6,8000266c <wait+0x68>
    80002654:	4691                	li	a3,4
    80002656:	03c48613          	addi	a2,s1,60
    8000265a:	85da                	mv	a1,s6
    8000265c:	05893503          	ld	a0,88(s2)
    80002660:	fffff097          	auipc	ra,0xfffff
    80002664:	40a080e7          	jalr	1034(ra) # 80001a6a <copyout>
    80002668:	02054263          	bltz	a0,8000268c <wait+0x88>
          freeproc(np);
    8000266c:	8526                	mv	a0,s1
    8000266e:	00000097          	auipc	ra,0x0
    80002672:	8ba080e7          	jalr	-1862(ra) # 80001f28 <freeproc>
          release(&np->lock);
    80002676:	8526                	mv	a0,s1
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	786080e7          	jalr	1926(ra) # 80000dfe <release>
          release(&p->lock);
    80002680:	854a                	mv	a0,s2
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	77c080e7          	jalr	1916(ra) # 80000dfe <release>
          return pid;
    8000268a:	a8a9                	j	800026e4 <wait+0xe0>
            release(&np->lock);
    8000268c:	8526                	mv	a0,s1
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	770080e7          	jalr	1904(ra) # 80000dfe <release>
            release(&p->lock);
    80002696:	854a                	mv	a0,s2
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	766080e7          	jalr	1894(ra) # 80000dfe <release>
            return -1;
    800026a0:	59fd                	li	s3,-1
    800026a2:	a089                	j	800026e4 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800026a4:	17048493          	addi	s1,s1,368
    800026a8:	03348463          	beq	s1,s3,800026d0 <wait+0xcc>
      if(np->parent == p){
    800026ac:	749c                	ld	a5,40(s1)
    800026ae:	ff279be3          	bne	a5,s2,800026a4 <wait+0xa0>
        acquire(&np->lock);
    800026b2:	8526                	mv	a0,s1
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	67a080e7          	jalr	1658(ra) # 80000d2e <acquire>
        if(np->state == ZOMBIE){
    800026bc:	509c                	lw	a5,32(s1)
    800026be:	f94787e3          	beq	a5,s4,8000264c <wait+0x48>
        release(&np->lock);
    800026c2:	8526                	mv	a0,s1
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	73a080e7          	jalr	1850(ra) # 80000dfe <release>
        havekids = 1;
    800026cc:	8756                	mv	a4,s5
    800026ce:	bfd9                	j	800026a4 <wait+0xa0>
    if(!havekids || p->killed){
    800026d0:	c701                	beqz	a4,800026d8 <wait+0xd4>
    800026d2:	03892783          	lw	a5,56(s2)
    800026d6:	c785                	beqz	a5,800026fe <wait+0xfa>
      release(&p->lock);
    800026d8:	854a                	mv	a0,s2
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	724080e7          	jalr	1828(ra) # 80000dfe <release>
      return -1;
    800026e2:	59fd                	li	s3,-1
}
    800026e4:	854e                	mv	a0,s3
    800026e6:	60a6                	ld	ra,72(sp)
    800026e8:	6406                	ld	s0,64(sp)
    800026ea:	74e2                	ld	s1,56(sp)
    800026ec:	7942                	ld	s2,48(sp)
    800026ee:	79a2                	ld	s3,40(sp)
    800026f0:	7a02                	ld	s4,32(sp)
    800026f2:	6ae2                	ld	s5,24(sp)
    800026f4:	6b42                	ld	s6,16(sp)
    800026f6:	6ba2                	ld	s7,8(sp)
    800026f8:	6c02                	ld	s8,0(sp)
    800026fa:	6161                	addi	sp,sp,80
    800026fc:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800026fe:	85e2                	mv	a1,s8
    80002700:	854a                	mv	a0,s2
    80002702:	00000097          	auipc	ra,0x0
    80002706:	e84080e7          	jalr	-380(ra) # 80002586 <sleep>
    havekids = 0;
    8000270a:	bf1d                	j	80002640 <wait+0x3c>

000000008000270c <wakeup>:
{
    8000270c:	7139                	addi	sp,sp,-64
    8000270e:	fc06                	sd	ra,56(sp)
    80002710:	f822                	sd	s0,48(sp)
    80002712:	f426                	sd	s1,40(sp)
    80002714:	f04a                	sd	s2,32(sp)
    80002716:	ec4e                	sd	s3,24(sp)
    80002718:	e852                	sd	s4,16(sp)
    8000271a:	e456                	sd	s5,8(sp)
    8000271c:	0080                	addi	s0,sp,64
    8000271e:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002720:	00010497          	auipc	s1,0x10
    80002724:	08848493          	addi	s1,s1,136 # 800127a8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002728:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000272a:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000272c:	00016917          	auipc	s2,0x16
    80002730:	c7c90913          	addi	s2,s2,-900 # 800183a8 <tickslock>
    80002734:	a821                	j	8000274c <wakeup+0x40>
      p->state = RUNNABLE;
    80002736:	0354a023          	sw	s5,32(s1)
    release(&p->lock);
    8000273a:	8526                	mv	a0,s1
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	6c2080e7          	jalr	1730(ra) # 80000dfe <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002744:	17048493          	addi	s1,s1,368
    80002748:	01248e63          	beq	s1,s2,80002764 <wakeup+0x58>
    acquire(&p->lock);
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	5e0080e7          	jalr	1504(ra) # 80000d2e <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002756:	509c                	lw	a5,32(s1)
    80002758:	ff3791e3          	bne	a5,s3,8000273a <wakeup+0x2e>
    8000275c:	789c                	ld	a5,48(s1)
    8000275e:	fd479ee3          	bne	a5,s4,8000273a <wakeup+0x2e>
    80002762:	bfd1                	j	80002736 <wakeup+0x2a>
}
    80002764:	70e2                	ld	ra,56(sp)
    80002766:	7442                	ld	s0,48(sp)
    80002768:	74a2                	ld	s1,40(sp)
    8000276a:	7902                	ld	s2,32(sp)
    8000276c:	69e2                	ld	s3,24(sp)
    8000276e:	6a42                	ld	s4,16(sp)
    80002770:	6aa2                	ld	s5,8(sp)
    80002772:	6121                	addi	sp,sp,64
    80002774:	8082                	ret

0000000080002776 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002776:	7179                	addi	sp,sp,-48
    80002778:	f406                	sd	ra,40(sp)
    8000277a:	f022                	sd	s0,32(sp)
    8000277c:	ec26                	sd	s1,24(sp)
    8000277e:	e84a                	sd	s2,16(sp)
    80002780:	e44e                	sd	s3,8(sp)
    80002782:	1800                	addi	s0,sp,48
    80002784:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002786:	00010497          	auipc	s1,0x10
    8000278a:	02248493          	addi	s1,s1,34 # 800127a8 <proc>
    8000278e:	00016997          	auipc	s3,0x16
    80002792:	c1a98993          	addi	s3,s3,-998 # 800183a8 <tickslock>
    acquire(&p->lock);
    80002796:	8526                	mv	a0,s1
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	596080e7          	jalr	1430(ra) # 80000d2e <acquire>
    if(p->pid == pid){
    800027a0:	40bc                	lw	a5,64(s1)
    800027a2:	01278d63          	beq	a5,s2,800027bc <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027a6:	8526                	mv	a0,s1
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	656080e7          	jalr	1622(ra) # 80000dfe <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027b0:	17048493          	addi	s1,s1,368
    800027b4:	ff3491e3          	bne	s1,s3,80002796 <kill+0x20>
  }
  return -1;
    800027b8:	557d                	li	a0,-1
    800027ba:	a829                	j	800027d4 <kill+0x5e>
      p->killed = 1;
    800027bc:	4785                	li	a5,1
    800027be:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    800027c0:	5098                	lw	a4,32(s1)
    800027c2:	4785                	li	a5,1
    800027c4:	00f70f63          	beq	a4,a5,800027e2 <kill+0x6c>
      release(&p->lock);
    800027c8:	8526                	mv	a0,s1
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	634080e7          	jalr	1588(ra) # 80000dfe <release>
      return 0;
    800027d2:	4501                	li	a0,0
}
    800027d4:	70a2                	ld	ra,40(sp)
    800027d6:	7402                	ld	s0,32(sp)
    800027d8:	64e2                	ld	s1,24(sp)
    800027da:	6942                	ld	s2,16(sp)
    800027dc:	69a2                	ld	s3,8(sp)
    800027de:	6145                	addi	sp,sp,48
    800027e0:	8082                	ret
        p->state = RUNNABLE;
    800027e2:	4789                	li	a5,2
    800027e4:	d09c                	sw	a5,32(s1)
    800027e6:	b7cd                	j	800027c8 <kill+0x52>

00000000800027e8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027e8:	7179                	addi	sp,sp,-48
    800027ea:	f406                	sd	ra,40(sp)
    800027ec:	f022                	sd	s0,32(sp)
    800027ee:	ec26                	sd	s1,24(sp)
    800027f0:	e84a                	sd	s2,16(sp)
    800027f2:	e44e                	sd	s3,8(sp)
    800027f4:	e052                	sd	s4,0(sp)
    800027f6:	1800                	addi	s0,sp,48
    800027f8:	84aa                	mv	s1,a0
    800027fa:	892e                	mv	s2,a1
    800027fc:	89b2                	mv	s3,a2
    800027fe:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002800:	fffff097          	auipc	ra,0xfffff
    80002804:	576080e7          	jalr	1398(ra) # 80001d76 <myproc>
  if(user_dst){
    80002808:	c08d                	beqz	s1,8000282a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000280a:	86d2                	mv	a3,s4
    8000280c:	864e                	mv	a2,s3
    8000280e:	85ca                	mv	a1,s2
    80002810:	6d28                	ld	a0,88(a0)
    80002812:	fffff097          	auipc	ra,0xfffff
    80002816:	258080e7          	jalr	600(ra) # 80001a6a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000281a:	70a2                	ld	ra,40(sp)
    8000281c:	7402                	ld	s0,32(sp)
    8000281e:	64e2                	ld	s1,24(sp)
    80002820:	6942                	ld	s2,16(sp)
    80002822:	69a2                	ld	s3,8(sp)
    80002824:	6a02                	ld	s4,0(sp)
    80002826:	6145                	addi	sp,sp,48
    80002828:	8082                	ret
    memmove((char *)dst, src, len);
    8000282a:	000a061b          	sext.w	a2,s4
    8000282e:	85ce                	mv	a1,s3
    80002830:	854a                	mv	a0,s2
    80002832:	fffff097          	auipc	ra,0xfffff
    80002836:	93c080e7          	jalr	-1732(ra) # 8000116e <memmove>
    return 0;
    8000283a:	8526                	mv	a0,s1
    8000283c:	bff9                	j	8000281a <either_copyout+0x32>

000000008000283e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000283e:	7179                	addi	sp,sp,-48
    80002840:	f406                	sd	ra,40(sp)
    80002842:	f022                	sd	s0,32(sp)
    80002844:	ec26                	sd	s1,24(sp)
    80002846:	e84a                	sd	s2,16(sp)
    80002848:	e44e                	sd	s3,8(sp)
    8000284a:	e052                	sd	s4,0(sp)
    8000284c:	1800                	addi	s0,sp,48
    8000284e:	892a                	mv	s2,a0
    80002850:	84ae                	mv	s1,a1
    80002852:	89b2                	mv	s3,a2
    80002854:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002856:	fffff097          	auipc	ra,0xfffff
    8000285a:	520080e7          	jalr	1312(ra) # 80001d76 <myproc>
  if(user_src){
    8000285e:	c08d                	beqz	s1,80002880 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002860:	86d2                	mv	a3,s4
    80002862:	864e                	mv	a2,s3
    80002864:	85ca                	mv	a1,s2
    80002866:	6d28                	ld	a0,88(a0)
    80002868:	fffff097          	auipc	ra,0xfffff
    8000286c:	28e080e7          	jalr	654(ra) # 80001af6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002870:	70a2                	ld	ra,40(sp)
    80002872:	7402                	ld	s0,32(sp)
    80002874:	64e2                	ld	s1,24(sp)
    80002876:	6942                	ld	s2,16(sp)
    80002878:	69a2                	ld	s3,8(sp)
    8000287a:	6a02                	ld	s4,0(sp)
    8000287c:	6145                	addi	sp,sp,48
    8000287e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002880:	000a061b          	sext.w	a2,s4
    80002884:	85ce                	mv	a1,s3
    80002886:	854a                	mv	a0,s2
    80002888:	fffff097          	auipc	ra,0xfffff
    8000288c:	8e6080e7          	jalr	-1818(ra) # 8000116e <memmove>
    return 0;
    80002890:	8526                	mv	a0,s1
    80002892:	bff9                	j	80002870 <either_copyin+0x32>

0000000080002894 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002894:	715d                	addi	sp,sp,-80
    80002896:	e486                	sd	ra,72(sp)
    80002898:	e0a2                	sd	s0,64(sp)
    8000289a:	fc26                	sd	s1,56(sp)
    8000289c:	f84a                	sd	s2,48(sp)
    8000289e:	f44e                	sd	s3,40(sp)
    800028a0:	f052                	sd	s4,32(sp)
    800028a2:	ec56                	sd	s5,24(sp)
    800028a4:	e85a                	sd	s6,16(sp)
    800028a6:	e45e                	sd	s7,8(sp)
    800028a8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800028aa:	00006517          	auipc	a0,0x6
    800028ae:	8b650513          	addi	a0,a0,-1866 # 80008160 <digits+0x120>
    800028b2:	ffffe097          	auipc	ra,0xffffe
    800028b6:	ce8080e7          	jalr	-792(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028ba:	00010497          	auipc	s1,0x10
    800028be:	04e48493          	addi	s1,s1,78 # 80012908 <proc+0x160>
    800028c2:	00016917          	auipc	s2,0x16
    800028c6:	c4690913          	addi	s2,s2,-954 # 80018508 <bcachebucket+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ca:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800028cc:	00006997          	auipc	s3,0x6
    800028d0:	a2c98993          	addi	s3,s3,-1492 # 800082f8 <digits+0x2b8>
    printf("%d %s %s", p->pid, state, p->name);
    800028d4:	00006a97          	auipc	s5,0x6
    800028d8:	a2ca8a93          	addi	s5,s5,-1492 # 80008300 <digits+0x2c0>
    printf("\n");
    800028dc:	00006a17          	auipc	s4,0x6
    800028e0:	884a0a13          	addi	s4,s4,-1916 # 80008160 <digits+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028e4:	00006b97          	auipc	s7,0x6
    800028e8:	a54b8b93          	addi	s7,s7,-1452 # 80008338 <states.1712>
    800028ec:	a00d                	j	8000290e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028ee:	ee06a583          	lw	a1,-288(a3)
    800028f2:	8556                	mv	a0,s5
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	ca6080e7          	jalr	-858(ra) # 8000059a <printf>
    printf("\n");
    800028fc:	8552                	mv	a0,s4
    800028fe:	ffffe097          	auipc	ra,0xffffe
    80002902:	c9c080e7          	jalr	-868(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002906:	17048493          	addi	s1,s1,368
    8000290a:	03248163          	beq	s1,s2,8000292c <procdump+0x98>
    if(p->state == UNUSED)
    8000290e:	86a6                	mv	a3,s1
    80002910:	ec04a783          	lw	a5,-320(s1)
    80002914:	dbed                	beqz	a5,80002906 <procdump+0x72>
      state = "???";
    80002916:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002918:	fcfb6be3          	bltu	s6,a5,800028ee <procdump+0x5a>
    8000291c:	1782                	slli	a5,a5,0x20
    8000291e:	9381                	srli	a5,a5,0x20
    80002920:	078e                	slli	a5,a5,0x3
    80002922:	97de                	add	a5,a5,s7
    80002924:	6390                	ld	a2,0(a5)
    80002926:	f661                	bnez	a2,800028ee <procdump+0x5a>
      state = "???";
    80002928:	864e                	mv	a2,s3
    8000292a:	b7d1                	j	800028ee <procdump+0x5a>
  }
}
    8000292c:	60a6                	ld	ra,72(sp)
    8000292e:	6406                	ld	s0,64(sp)
    80002930:	74e2                	ld	s1,56(sp)
    80002932:	7942                	ld	s2,48(sp)
    80002934:	79a2                	ld	s3,40(sp)
    80002936:	7a02                	ld	s4,32(sp)
    80002938:	6ae2                	ld	s5,24(sp)
    8000293a:	6b42                	ld	s6,16(sp)
    8000293c:	6ba2                	ld	s7,8(sp)
    8000293e:	6161                	addi	sp,sp,80
    80002940:	8082                	ret

0000000080002942 <swtch>:
    80002942:	00153023          	sd	ra,0(a0)
    80002946:	00253423          	sd	sp,8(a0)
    8000294a:	e900                	sd	s0,16(a0)
    8000294c:	ed04                	sd	s1,24(a0)
    8000294e:	03253023          	sd	s2,32(a0)
    80002952:	03353423          	sd	s3,40(a0)
    80002956:	03453823          	sd	s4,48(a0)
    8000295a:	03553c23          	sd	s5,56(a0)
    8000295e:	05653023          	sd	s6,64(a0)
    80002962:	05753423          	sd	s7,72(a0)
    80002966:	05853823          	sd	s8,80(a0)
    8000296a:	05953c23          	sd	s9,88(a0)
    8000296e:	07a53023          	sd	s10,96(a0)
    80002972:	07b53423          	sd	s11,104(a0)
    80002976:	0005b083          	ld	ra,0(a1)
    8000297a:	0085b103          	ld	sp,8(a1)
    8000297e:	6980                	ld	s0,16(a1)
    80002980:	6d84                	ld	s1,24(a1)
    80002982:	0205b903          	ld	s2,32(a1)
    80002986:	0285b983          	ld	s3,40(a1)
    8000298a:	0305ba03          	ld	s4,48(a1)
    8000298e:	0385ba83          	ld	s5,56(a1)
    80002992:	0405bb03          	ld	s6,64(a1)
    80002996:	0485bb83          	ld	s7,72(a1)
    8000299a:	0505bc03          	ld	s8,80(a1)
    8000299e:	0585bc83          	ld	s9,88(a1)
    800029a2:	0605bd03          	ld	s10,96(a1)
    800029a6:	0685bd83          	ld	s11,104(a1)
    800029aa:	8082                	ret

00000000800029ac <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029ac:	1141                	addi	sp,sp,-16
    800029ae:	e406                	sd	ra,8(sp)
    800029b0:	e022                	sd	s0,0(sp)
    800029b2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029b4:	00006597          	auipc	a1,0x6
    800029b8:	9ac58593          	addi	a1,a1,-1620 # 80008360 <states.1712+0x28>
    800029bc:	00016517          	auipc	a0,0x16
    800029c0:	9ec50513          	addi	a0,a0,-1556 # 800183a8 <tickslock>
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	4e6080e7          	jalr	1254(ra) # 80000eaa <initlock>
}
    800029cc:	60a2                	ld	ra,8(sp)
    800029ce:	6402                	ld	s0,0(sp)
    800029d0:	0141                	addi	sp,sp,16
    800029d2:	8082                	ret

00000000800029d4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029d4:	1141                	addi	sp,sp,-16
    800029d6:	e422                	sd	s0,8(sp)
    800029d8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029da:	00003797          	auipc	a5,0x3
    800029de:	59678793          	addi	a5,a5,1430 # 80005f70 <kernelvec>
    800029e2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029e6:	6422                	ld	s0,8(sp)
    800029e8:	0141                	addi	sp,sp,16
    800029ea:	8082                	ret

00000000800029ec <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029ec:	1141                	addi	sp,sp,-16
    800029ee:	e406                	sd	ra,8(sp)
    800029f0:	e022                	sd	s0,0(sp)
    800029f2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029f4:	fffff097          	auipc	ra,0xfffff
    800029f8:	382080e7          	jalr	898(ra) # 80001d76 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a00:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a02:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a06:	00004617          	auipc	a2,0x4
    80002a0a:	5fa60613          	addi	a2,a2,1530 # 80007000 <_trampoline>
    80002a0e:	00004697          	auipc	a3,0x4
    80002a12:	5f268693          	addi	a3,a3,1522 # 80007000 <_trampoline>
    80002a16:	8e91                	sub	a3,a3,a2
    80002a18:	040007b7          	lui	a5,0x4000
    80002a1c:	17fd                	addi	a5,a5,-1
    80002a1e:	07b2                	slli	a5,a5,0xc
    80002a20:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a22:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a26:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a28:	180026f3          	csrr	a3,satp
    80002a2c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a2e:	7138                	ld	a4,96(a0)
    80002a30:	6534                	ld	a3,72(a0)
    80002a32:	6585                	lui	a1,0x1
    80002a34:	96ae                	add	a3,a3,a1
    80002a36:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a38:	7138                	ld	a4,96(a0)
    80002a3a:	00000697          	auipc	a3,0x0
    80002a3e:	13868693          	addi	a3,a3,312 # 80002b72 <usertrap>
    80002a42:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a44:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a46:	8692                	mv	a3,tp
    80002a48:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a4a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a4e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a52:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a56:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a5a:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a5c:	6f18                	ld	a4,24(a4)
    80002a5e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a62:	6d2c                	ld	a1,88(a0)
    80002a64:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a66:	00004717          	auipc	a4,0x4
    80002a6a:	62a70713          	addi	a4,a4,1578 # 80007090 <userret>
    80002a6e:	8f11                	sub	a4,a4,a2
    80002a70:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a72:	577d                	li	a4,-1
    80002a74:	177e                	slli	a4,a4,0x3f
    80002a76:	8dd9                	or	a1,a1,a4
    80002a78:	02000537          	lui	a0,0x2000
    80002a7c:	157d                	addi	a0,a0,-1
    80002a7e:	0536                	slli	a0,a0,0xd
    80002a80:	9782                	jalr	a5
}
    80002a82:	60a2                	ld	ra,8(sp)
    80002a84:	6402                	ld	s0,0(sp)
    80002a86:	0141                	addi	sp,sp,16
    80002a88:	8082                	ret

0000000080002a8a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a8a:	1101                	addi	sp,sp,-32
    80002a8c:	ec06                	sd	ra,24(sp)
    80002a8e:	e822                	sd	s0,16(sp)
    80002a90:	e426                	sd	s1,8(sp)
    80002a92:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a94:	00016497          	auipc	s1,0x16
    80002a98:	91448493          	addi	s1,s1,-1772 # 800183a8 <tickslock>
    80002a9c:	8526                	mv	a0,s1
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	290080e7          	jalr	656(ra) # 80000d2e <acquire>
  ticks++;
    80002aa6:	00006517          	auipc	a0,0x6
    80002aaa:	57a50513          	addi	a0,a0,1402 # 80009020 <ticks>
    80002aae:	411c                	lw	a5,0(a0)
    80002ab0:	2785                	addiw	a5,a5,1
    80002ab2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002ab4:	00000097          	auipc	ra,0x0
    80002ab8:	c58080e7          	jalr	-936(ra) # 8000270c <wakeup>
  release(&tickslock);
    80002abc:	8526                	mv	a0,s1
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	340080e7          	jalr	832(ra) # 80000dfe <release>
}
    80002ac6:	60e2                	ld	ra,24(sp)
    80002ac8:	6442                	ld	s0,16(sp)
    80002aca:	64a2                	ld	s1,8(sp)
    80002acc:	6105                	addi	sp,sp,32
    80002ace:	8082                	ret

0000000080002ad0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ad0:	1101                	addi	sp,sp,-32
    80002ad2:	ec06                	sd	ra,24(sp)
    80002ad4:	e822                	sd	s0,16(sp)
    80002ad6:	e426                	sd	s1,8(sp)
    80002ad8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ada:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ade:	00074d63          	bltz	a4,80002af8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002ae2:	57fd                	li	a5,-1
    80002ae4:	17fe                	slli	a5,a5,0x3f
    80002ae6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ae8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002aea:	06f70363          	beq	a4,a5,80002b50 <devintr+0x80>
  }
}
    80002aee:	60e2                	ld	ra,24(sp)
    80002af0:	6442                	ld	s0,16(sp)
    80002af2:	64a2                	ld	s1,8(sp)
    80002af4:	6105                	addi	sp,sp,32
    80002af6:	8082                	ret
     (scause & 0xff) == 9){
    80002af8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002afc:	46a5                	li	a3,9
    80002afe:	fed792e3          	bne	a5,a3,80002ae2 <devintr+0x12>
    int irq = plic_claim();
    80002b02:	00003097          	auipc	ra,0x3
    80002b06:	576080e7          	jalr	1398(ra) # 80006078 <plic_claim>
    80002b0a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b0c:	47a9                	li	a5,10
    80002b0e:	02f50763          	beq	a0,a5,80002b3c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b12:	4785                	li	a5,1
    80002b14:	02f50963          	beq	a0,a5,80002b46 <devintr+0x76>
    return 1;
    80002b18:	4505                	li	a0,1
    } else if(irq){
    80002b1a:	d8f1                	beqz	s1,80002aee <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b1c:	85a6                	mv	a1,s1
    80002b1e:	00006517          	auipc	a0,0x6
    80002b22:	84a50513          	addi	a0,a0,-1974 # 80008368 <states.1712+0x30>
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	a74080e7          	jalr	-1420(ra) # 8000059a <printf>
      plic_complete(irq);
    80002b2e:	8526                	mv	a0,s1
    80002b30:	00003097          	auipc	ra,0x3
    80002b34:	56c080e7          	jalr	1388(ra) # 8000609c <plic_complete>
    return 1;
    80002b38:	4505                	li	a0,1
    80002b3a:	bf55                	j	80002aee <devintr+0x1e>
      uartintr();
    80002b3c:	ffffe097          	auipc	ra,0xffffe
    80002b40:	ea0080e7          	jalr	-352(ra) # 800009dc <uartintr>
    80002b44:	b7ed                	j	80002b2e <devintr+0x5e>
      virtio_disk_intr();
    80002b46:	00004097          	auipc	ra,0x4
    80002b4a:	a36080e7          	jalr	-1482(ra) # 8000657c <virtio_disk_intr>
    80002b4e:	b7c5                	j	80002b2e <devintr+0x5e>
    if(cpuid() == 0){
    80002b50:	fffff097          	auipc	ra,0xfffff
    80002b54:	1fa080e7          	jalr	506(ra) # 80001d4a <cpuid>
    80002b58:	c901                	beqz	a0,80002b68 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b5a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b5e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b60:	14479073          	csrw	sip,a5
    return 2;
    80002b64:	4509                	li	a0,2
    80002b66:	b761                	j	80002aee <devintr+0x1e>
      clockintr();
    80002b68:	00000097          	auipc	ra,0x0
    80002b6c:	f22080e7          	jalr	-222(ra) # 80002a8a <clockintr>
    80002b70:	b7ed                	j	80002b5a <devintr+0x8a>

0000000080002b72 <usertrap>:
{
    80002b72:	1101                	addi	sp,sp,-32
    80002b74:	ec06                	sd	ra,24(sp)
    80002b76:	e822                	sd	s0,16(sp)
    80002b78:	e426                	sd	s1,8(sp)
    80002b7a:	e04a                	sd	s2,0(sp)
    80002b7c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b7e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b82:	1007f793          	andi	a5,a5,256
    80002b86:	e3ad                	bnez	a5,80002be8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b88:	00003797          	auipc	a5,0x3
    80002b8c:	3e878793          	addi	a5,a5,1000 # 80005f70 <kernelvec>
    80002b90:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b94:	fffff097          	auipc	ra,0xfffff
    80002b98:	1e2080e7          	jalr	482(ra) # 80001d76 <myproc>
    80002b9c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b9e:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ba0:	14102773          	csrr	a4,sepc
    80002ba4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ba6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002baa:	47a1                	li	a5,8
    80002bac:	04f71c63          	bne	a4,a5,80002c04 <usertrap+0x92>
    if(p->killed)
    80002bb0:	5d1c                	lw	a5,56(a0)
    80002bb2:	e3b9                	bnez	a5,80002bf8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002bb4:	70b8                	ld	a4,96(s1)
    80002bb6:	6f1c                	ld	a5,24(a4)
    80002bb8:	0791                	addi	a5,a5,4
    80002bba:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bbc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bc0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bc4:	10079073          	csrw	sstatus,a5
    syscall();
    80002bc8:	00000097          	auipc	ra,0x0
    80002bcc:	2e0080e7          	jalr	736(ra) # 80002ea8 <syscall>
  if(p->killed)
    80002bd0:	5c9c                	lw	a5,56(s1)
    80002bd2:	ebc1                	bnez	a5,80002c62 <usertrap+0xf0>
  usertrapret();
    80002bd4:	00000097          	auipc	ra,0x0
    80002bd8:	e18080e7          	jalr	-488(ra) # 800029ec <usertrapret>
}
    80002bdc:	60e2                	ld	ra,24(sp)
    80002bde:	6442                	ld	s0,16(sp)
    80002be0:	64a2                	ld	s1,8(sp)
    80002be2:	6902                	ld	s2,0(sp)
    80002be4:	6105                	addi	sp,sp,32
    80002be6:	8082                	ret
    panic("usertrap: not from user mode");
    80002be8:	00005517          	auipc	a0,0x5
    80002bec:	7a050513          	addi	a0,a0,1952 # 80008388 <states.1712+0x50>
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	960080e7          	jalr	-1696(ra) # 80000550 <panic>
      exit(-1);
    80002bf8:	557d                	li	a0,-1
    80002bfa:	00000097          	auipc	ra,0x0
    80002bfe:	846080e7          	jalr	-1978(ra) # 80002440 <exit>
    80002c02:	bf4d                	j	80002bb4 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	ecc080e7          	jalr	-308(ra) # 80002ad0 <devintr>
    80002c0c:	892a                	mv	s2,a0
    80002c0e:	c501                	beqz	a0,80002c16 <usertrap+0xa4>
  if(p->killed)
    80002c10:	5c9c                	lw	a5,56(s1)
    80002c12:	c3a1                	beqz	a5,80002c52 <usertrap+0xe0>
    80002c14:	a815                	j	80002c48 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c16:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c1a:	40b0                	lw	a2,64(s1)
    80002c1c:	00005517          	auipc	a0,0x5
    80002c20:	78c50513          	addi	a0,a0,1932 # 800083a8 <states.1712+0x70>
    80002c24:	ffffe097          	auipc	ra,0xffffe
    80002c28:	976080e7          	jalr	-1674(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c2c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c30:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c34:	00005517          	auipc	a0,0x5
    80002c38:	7a450513          	addi	a0,a0,1956 # 800083d8 <states.1712+0xa0>
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	95e080e7          	jalr	-1698(ra) # 8000059a <printf>
    p->killed = 1;
    80002c44:	4785                	li	a5,1
    80002c46:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002c48:	557d                	li	a0,-1
    80002c4a:	fffff097          	auipc	ra,0xfffff
    80002c4e:	7f6080e7          	jalr	2038(ra) # 80002440 <exit>
  if(which_dev == 2)
    80002c52:	4789                	li	a5,2
    80002c54:	f8f910e3          	bne	s2,a5,80002bd4 <usertrap+0x62>
    yield();
    80002c58:	00000097          	auipc	ra,0x0
    80002c5c:	8f2080e7          	jalr	-1806(ra) # 8000254a <yield>
    80002c60:	bf95                	j	80002bd4 <usertrap+0x62>
  int which_dev = 0;
    80002c62:	4901                	li	s2,0
    80002c64:	b7d5                	j	80002c48 <usertrap+0xd6>

0000000080002c66 <kerneltrap>:
{
    80002c66:	7179                	addi	sp,sp,-48
    80002c68:	f406                	sd	ra,40(sp)
    80002c6a:	f022                	sd	s0,32(sp)
    80002c6c:	ec26                	sd	s1,24(sp)
    80002c6e:	e84a                	sd	s2,16(sp)
    80002c70:	e44e                	sd	s3,8(sp)
    80002c72:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c74:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c78:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c7c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c80:	1004f793          	andi	a5,s1,256
    80002c84:	cb85                	beqz	a5,80002cb4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c8a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c8c:	ef85                	bnez	a5,80002cc4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c8e:	00000097          	auipc	ra,0x0
    80002c92:	e42080e7          	jalr	-446(ra) # 80002ad0 <devintr>
    80002c96:	cd1d                	beqz	a0,80002cd4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c98:	4789                	li	a5,2
    80002c9a:	06f50a63          	beq	a0,a5,80002d0e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c9e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ca2:	10049073          	csrw	sstatus,s1
}
    80002ca6:	70a2                	ld	ra,40(sp)
    80002ca8:	7402                	ld	s0,32(sp)
    80002caa:	64e2                	ld	s1,24(sp)
    80002cac:	6942                	ld	s2,16(sp)
    80002cae:	69a2                	ld	s3,8(sp)
    80002cb0:	6145                	addi	sp,sp,48
    80002cb2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cb4:	00005517          	auipc	a0,0x5
    80002cb8:	74450513          	addi	a0,a0,1860 # 800083f8 <states.1712+0xc0>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	894080e7          	jalr	-1900(ra) # 80000550 <panic>
    panic("kerneltrap: interrupts enabled");
    80002cc4:	00005517          	auipc	a0,0x5
    80002cc8:	75c50513          	addi	a0,a0,1884 # 80008420 <states.1712+0xe8>
    80002ccc:	ffffe097          	auipc	ra,0xffffe
    80002cd0:	884080e7          	jalr	-1916(ra) # 80000550 <panic>
    printf("scause %p\n", scause);
    80002cd4:	85ce                	mv	a1,s3
    80002cd6:	00005517          	auipc	a0,0x5
    80002cda:	76a50513          	addi	a0,a0,1898 # 80008440 <states.1712+0x108>
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	8bc080e7          	jalr	-1860(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ce6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cea:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cee:	00005517          	auipc	a0,0x5
    80002cf2:	76250513          	addi	a0,a0,1890 # 80008450 <states.1712+0x118>
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	8a4080e7          	jalr	-1884(ra) # 8000059a <printf>
    panic("kerneltrap");
    80002cfe:	00005517          	auipc	a0,0x5
    80002d02:	76a50513          	addi	a0,a0,1898 # 80008468 <states.1712+0x130>
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	84a080e7          	jalr	-1974(ra) # 80000550 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	068080e7          	jalr	104(ra) # 80001d76 <myproc>
    80002d16:	d541                	beqz	a0,80002c9e <kerneltrap+0x38>
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	05e080e7          	jalr	94(ra) # 80001d76 <myproc>
    80002d20:	5118                	lw	a4,32(a0)
    80002d22:	478d                	li	a5,3
    80002d24:	f6f71de3          	bne	a4,a5,80002c9e <kerneltrap+0x38>
    yield();
    80002d28:	00000097          	auipc	ra,0x0
    80002d2c:	822080e7          	jalr	-2014(ra) # 8000254a <yield>
    80002d30:	b7bd                	j	80002c9e <kerneltrap+0x38>

0000000080002d32 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d32:	1101                	addi	sp,sp,-32
    80002d34:	ec06                	sd	ra,24(sp)
    80002d36:	e822                	sd	s0,16(sp)
    80002d38:	e426                	sd	s1,8(sp)
    80002d3a:	1000                	addi	s0,sp,32
    80002d3c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	038080e7          	jalr	56(ra) # 80001d76 <myproc>
  switch (n) {
    80002d46:	4795                	li	a5,5
    80002d48:	0497e163          	bltu	a5,s1,80002d8a <argraw+0x58>
    80002d4c:	048a                	slli	s1,s1,0x2
    80002d4e:	00005717          	auipc	a4,0x5
    80002d52:	75270713          	addi	a4,a4,1874 # 800084a0 <states.1712+0x168>
    80002d56:	94ba                	add	s1,s1,a4
    80002d58:	409c                	lw	a5,0(s1)
    80002d5a:	97ba                	add	a5,a5,a4
    80002d5c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d5e:	713c                	ld	a5,96(a0)
    80002d60:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d62:	60e2                	ld	ra,24(sp)
    80002d64:	6442                	ld	s0,16(sp)
    80002d66:	64a2                	ld	s1,8(sp)
    80002d68:	6105                	addi	sp,sp,32
    80002d6a:	8082                	ret
    return p->trapframe->a1;
    80002d6c:	713c                	ld	a5,96(a0)
    80002d6e:	7fa8                	ld	a0,120(a5)
    80002d70:	bfcd                	j	80002d62 <argraw+0x30>
    return p->trapframe->a2;
    80002d72:	713c                	ld	a5,96(a0)
    80002d74:	63c8                	ld	a0,128(a5)
    80002d76:	b7f5                	j	80002d62 <argraw+0x30>
    return p->trapframe->a3;
    80002d78:	713c                	ld	a5,96(a0)
    80002d7a:	67c8                	ld	a0,136(a5)
    80002d7c:	b7dd                	j	80002d62 <argraw+0x30>
    return p->trapframe->a4;
    80002d7e:	713c                	ld	a5,96(a0)
    80002d80:	6bc8                	ld	a0,144(a5)
    80002d82:	b7c5                	j	80002d62 <argraw+0x30>
    return p->trapframe->a5;
    80002d84:	713c                	ld	a5,96(a0)
    80002d86:	6fc8                	ld	a0,152(a5)
    80002d88:	bfe9                	j	80002d62 <argraw+0x30>
  panic("argraw");
    80002d8a:	00005517          	auipc	a0,0x5
    80002d8e:	6ee50513          	addi	a0,a0,1774 # 80008478 <states.1712+0x140>
    80002d92:	ffffd097          	auipc	ra,0xffffd
    80002d96:	7be080e7          	jalr	1982(ra) # 80000550 <panic>

0000000080002d9a <fetchaddr>:
{
    80002d9a:	1101                	addi	sp,sp,-32
    80002d9c:	ec06                	sd	ra,24(sp)
    80002d9e:	e822                	sd	s0,16(sp)
    80002da0:	e426                	sd	s1,8(sp)
    80002da2:	e04a                	sd	s2,0(sp)
    80002da4:	1000                	addi	s0,sp,32
    80002da6:	84aa                	mv	s1,a0
    80002da8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002daa:	fffff097          	auipc	ra,0xfffff
    80002dae:	fcc080e7          	jalr	-52(ra) # 80001d76 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002db2:	693c                	ld	a5,80(a0)
    80002db4:	02f4f863          	bgeu	s1,a5,80002de4 <fetchaddr+0x4a>
    80002db8:	00848713          	addi	a4,s1,8
    80002dbc:	02e7e663          	bltu	a5,a4,80002de8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002dc0:	46a1                	li	a3,8
    80002dc2:	8626                	mv	a2,s1
    80002dc4:	85ca                	mv	a1,s2
    80002dc6:	6d28                	ld	a0,88(a0)
    80002dc8:	fffff097          	auipc	ra,0xfffff
    80002dcc:	d2e080e7          	jalr	-722(ra) # 80001af6 <copyin>
    80002dd0:	00a03533          	snez	a0,a0
    80002dd4:	40a00533          	neg	a0,a0
}
    80002dd8:	60e2                	ld	ra,24(sp)
    80002dda:	6442                	ld	s0,16(sp)
    80002ddc:	64a2                	ld	s1,8(sp)
    80002dde:	6902                	ld	s2,0(sp)
    80002de0:	6105                	addi	sp,sp,32
    80002de2:	8082                	ret
    return -1;
    80002de4:	557d                	li	a0,-1
    80002de6:	bfcd                	j	80002dd8 <fetchaddr+0x3e>
    80002de8:	557d                	li	a0,-1
    80002dea:	b7fd                	j	80002dd8 <fetchaddr+0x3e>

0000000080002dec <fetchstr>:
{
    80002dec:	7179                	addi	sp,sp,-48
    80002dee:	f406                	sd	ra,40(sp)
    80002df0:	f022                	sd	s0,32(sp)
    80002df2:	ec26                	sd	s1,24(sp)
    80002df4:	e84a                	sd	s2,16(sp)
    80002df6:	e44e                	sd	s3,8(sp)
    80002df8:	1800                	addi	s0,sp,48
    80002dfa:	892a                	mv	s2,a0
    80002dfc:	84ae                	mv	s1,a1
    80002dfe:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	f76080e7          	jalr	-138(ra) # 80001d76 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e08:	86ce                	mv	a3,s3
    80002e0a:	864a                	mv	a2,s2
    80002e0c:	85a6                	mv	a1,s1
    80002e0e:	6d28                	ld	a0,88(a0)
    80002e10:	fffff097          	auipc	ra,0xfffff
    80002e14:	d72080e7          	jalr	-654(ra) # 80001b82 <copyinstr>
  if(err < 0)
    80002e18:	00054763          	bltz	a0,80002e26 <fetchstr+0x3a>
  return strlen(buf);
    80002e1c:	8526                	mv	a0,s1
    80002e1e:	ffffe097          	auipc	ra,0xffffe
    80002e22:	478080e7          	jalr	1144(ra) # 80001296 <strlen>
}
    80002e26:	70a2                	ld	ra,40(sp)
    80002e28:	7402                	ld	s0,32(sp)
    80002e2a:	64e2                	ld	s1,24(sp)
    80002e2c:	6942                	ld	s2,16(sp)
    80002e2e:	69a2                	ld	s3,8(sp)
    80002e30:	6145                	addi	sp,sp,48
    80002e32:	8082                	ret

0000000080002e34 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e34:	1101                	addi	sp,sp,-32
    80002e36:	ec06                	sd	ra,24(sp)
    80002e38:	e822                	sd	s0,16(sp)
    80002e3a:	e426                	sd	s1,8(sp)
    80002e3c:	1000                	addi	s0,sp,32
    80002e3e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e40:	00000097          	auipc	ra,0x0
    80002e44:	ef2080e7          	jalr	-270(ra) # 80002d32 <argraw>
    80002e48:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e4a:	4501                	li	a0,0
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	64a2                	ld	s1,8(sp)
    80002e52:	6105                	addi	sp,sp,32
    80002e54:	8082                	ret

0000000080002e56 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e56:	1101                	addi	sp,sp,-32
    80002e58:	ec06                	sd	ra,24(sp)
    80002e5a:	e822                	sd	s0,16(sp)
    80002e5c:	e426                	sd	s1,8(sp)
    80002e5e:	1000                	addi	s0,sp,32
    80002e60:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e62:	00000097          	auipc	ra,0x0
    80002e66:	ed0080e7          	jalr	-304(ra) # 80002d32 <argraw>
    80002e6a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e6c:	4501                	li	a0,0
    80002e6e:	60e2                	ld	ra,24(sp)
    80002e70:	6442                	ld	s0,16(sp)
    80002e72:	64a2                	ld	s1,8(sp)
    80002e74:	6105                	addi	sp,sp,32
    80002e76:	8082                	ret

0000000080002e78 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e78:	1101                	addi	sp,sp,-32
    80002e7a:	ec06                	sd	ra,24(sp)
    80002e7c:	e822                	sd	s0,16(sp)
    80002e7e:	e426                	sd	s1,8(sp)
    80002e80:	e04a                	sd	s2,0(sp)
    80002e82:	1000                	addi	s0,sp,32
    80002e84:	84ae                	mv	s1,a1
    80002e86:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	eaa080e7          	jalr	-342(ra) # 80002d32 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e90:	864a                	mv	a2,s2
    80002e92:	85a6                	mv	a1,s1
    80002e94:	00000097          	auipc	ra,0x0
    80002e98:	f58080e7          	jalr	-168(ra) # 80002dec <fetchstr>
}
    80002e9c:	60e2                	ld	ra,24(sp)
    80002e9e:	6442                	ld	s0,16(sp)
    80002ea0:	64a2                	ld	s1,8(sp)
    80002ea2:	6902                	ld	s2,0(sp)
    80002ea4:	6105                	addi	sp,sp,32
    80002ea6:	8082                	ret

0000000080002ea8 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002ea8:	1101                	addi	sp,sp,-32
    80002eaa:	ec06                	sd	ra,24(sp)
    80002eac:	e822                	sd	s0,16(sp)
    80002eae:	e426                	sd	s1,8(sp)
    80002eb0:	e04a                	sd	s2,0(sp)
    80002eb2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	ec2080e7          	jalr	-318(ra) # 80001d76 <myproc>
    80002ebc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ebe:	06053903          	ld	s2,96(a0)
    80002ec2:	0a893783          	ld	a5,168(s2)
    80002ec6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002eca:	37fd                	addiw	a5,a5,-1
    80002ecc:	4751                	li	a4,20
    80002ece:	00f76f63          	bltu	a4,a5,80002eec <syscall+0x44>
    80002ed2:	00369713          	slli	a4,a3,0x3
    80002ed6:	00005797          	auipc	a5,0x5
    80002eda:	5e278793          	addi	a5,a5,1506 # 800084b8 <syscalls>
    80002ede:	97ba                	add	a5,a5,a4
    80002ee0:	639c                	ld	a5,0(a5)
    80002ee2:	c789                	beqz	a5,80002eec <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ee4:	9782                	jalr	a5
    80002ee6:	06a93823          	sd	a0,112(s2)
    80002eea:	a839                	j	80002f08 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002eec:	16048613          	addi	a2,s1,352
    80002ef0:	40ac                	lw	a1,64(s1)
    80002ef2:	00005517          	auipc	a0,0x5
    80002ef6:	58e50513          	addi	a0,a0,1422 # 80008480 <states.1712+0x148>
    80002efa:	ffffd097          	auipc	ra,0xffffd
    80002efe:	6a0080e7          	jalr	1696(ra) # 8000059a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f02:	70bc                	ld	a5,96(s1)
    80002f04:	577d                	li	a4,-1
    80002f06:	fbb8                	sd	a4,112(a5)
  }
}
    80002f08:	60e2                	ld	ra,24(sp)
    80002f0a:	6442                	ld	s0,16(sp)
    80002f0c:	64a2                	ld	s1,8(sp)
    80002f0e:	6902                	ld	s2,0(sp)
    80002f10:	6105                	addi	sp,sp,32
    80002f12:	8082                	ret

0000000080002f14 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f14:	1101                	addi	sp,sp,-32
    80002f16:	ec06                	sd	ra,24(sp)
    80002f18:	e822                	sd	s0,16(sp)
    80002f1a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f1c:	fec40593          	addi	a1,s0,-20
    80002f20:	4501                	li	a0,0
    80002f22:	00000097          	auipc	ra,0x0
    80002f26:	f12080e7          	jalr	-238(ra) # 80002e34 <argint>
    return -1;
    80002f2a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f2c:	00054963          	bltz	a0,80002f3e <sys_exit+0x2a>
  exit(n);
    80002f30:	fec42503          	lw	a0,-20(s0)
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	50c080e7          	jalr	1292(ra) # 80002440 <exit>
  return 0;  // not reached
    80002f3c:	4781                	li	a5,0
}
    80002f3e:	853e                	mv	a0,a5
    80002f40:	60e2                	ld	ra,24(sp)
    80002f42:	6442                	ld	s0,16(sp)
    80002f44:	6105                	addi	sp,sp,32
    80002f46:	8082                	ret

0000000080002f48 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f48:	1141                	addi	sp,sp,-16
    80002f4a:	e406                	sd	ra,8(sp)
    80002f4c:	e022                	sd	s0,0(sp)
    80002f4e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f50:	fffff097          	auipc	ra,0xfffff
    80002f54:	e26080e7          	jalr	-474(ra) # 80001d76 <myproc>
}
    80002f58:	4128                	lw	a0,64(a0)
    80002f5a:	60a2                	ld	ra,8(sp)
    80002f5c:	6402                	ld	s0,0(sp)
    80002f5e:	0141                	addi	sp,sp,16
    80002f60:	8082                	ret

0000000080002f62 <sys_fork>:

uint64
sys_fork(void)
{
    80002f62:	1141                	addi	sp,sp,-16
    80002f64:	e406                	sd	ra,8(sp)
    80002f66:	e022                	sd	s0,0(sp)
    80002f68:	0800                	addi	s0,sp,16
  return fork();
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	1cc080e7          	jalr	460(ra) # 80002136 <fork>
}
    80002f72:	60a2                	ld	ra,8(sp)
    80002f74:	6402                	ld	s0,0(sp)
    80002f76:	0141                	addi	sp,sp,16
    80002f78:	8082                	ret

0000000080002f7a <sys_wait>:

uint64
sys_wait(void)
{
    80002f7a:	1101                	addi	sp,sp,-32
    80002f7c:	ec06                	sd	ra,24(sp)
    80002f7e:	e822                	sd	s0,16(sp)
    80002f80:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f82:	fe840593          	addi	a1,s0,-24
    80002f86:	4501                	li	a0,0
    80002f88:	00000097          	auipc	ra,0x0
    80002f8c:	ece080e7          	jalr	-306(ra) # 80002e56 <argaddr>
    80002f90:	87aa                	mv	a5,a0
    return -1;
    80002f92:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f94:	0007c863          	bltz	a5,80002fa4 <sys_wait+0x2a>
  return wait(p);
    80002f98:	fe843503          	ld	a0,-24(s0)
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	668080e7          	jalr	1640(ra) # 80002604 <wait>
}
    80002fa4:	60e2                	ld	ra,24(sp)
    80002fa6:	6442                	ld	s0,16(sp)
    80002fa8:	6105                	addi	sp,sp,32
    80002faa:	8082                	ret

0000000080002fac <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fac:	7179                	addi	sp,sp,-48
    80002fae:	f406                	sd	ra,40(sp)
    80002fb0:	f022                	sd	s0,32(sp)
    80002fb2:	ec26                	sd	s1,24(sp)
    80002fb4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002fb6:	fdc40593          	addi	a1,s0,-36
    80002fba:	4501                	li	a0,0
    80002fbc:	00000097          	auipc	ra,0x0
    80002fc0:	e78080e7          	jalr	-392(ra) # 80002e34 <argint>
    80002fc4:	87aa                	mv	a5,a0
    return -1;
    80002fc6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002fc8:	0207c063          	bltz	a5,80002fe8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002fcc:	fffff097          	auipc	ra,0xfffff
    80002fd0:	daa080e7          	jalr	-598(ra) # 80001d76 <myproc>
    80002fd4:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002fd6:	fdc42503          	lw	a0,-36(s0)
    80002fda:	fffff097          	auipc	ra,0xfffff
    80002fde:	0e8080e7          	jalr	232(ra) # 800020c2 <growproc>
    80002fe2:	00054863          	bltz	a0,80002ff2 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002fe6:	8526                	mv	a0,s1
}
    80002fe8:	70a2                	ld	ra,40(sp)
    80002fea:	7402                	ld	s0,32(sp)
    80002fec:	64e2                	ld	s1,24(sp)
    80002fee:	6145                	addi	sp,sp,48
    80002ff0:	8082                	ret
    return -1;
    80002ff2:	557d                	li	a0,-1
    80002ff4:	bfd5                	j	80002fe8 <sys_sbrk+0x3c>

0000000080002ff6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ff6:	7139                	addi	sp,sp,-64
    80002ff8:	fc06                	sd	ra,56(sp)
    80002ffa:	f822                	sd	s0,48(sp)
    80002ffc:	f426                	sd	s1,40(sp)
    80002ffe:	f04a                	sd	s2,32(sp)
    80003000:	ec4e                	sd	s3,24(sp)
    80003002:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003004:	fcc40593          	addi	a1,s0,-52
    80003008:	4501                	li	a0,0
    8000300a:	00000097          	auipc	ra,0x0
    8000300e:	e2a080e7          	jalr	-470(ra) # 80002e34 <argint>
    return -1;
    80003012:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003014:	06054563          	bltz	a0,8000307e <sys_sleep+0x88>
  acquire(&tickslock);
    80003018:	00015517          	auipc	a0,0x15
    8000301c:	39050513          	addi	a0,a0,912 # 800183a8 <tickslock>
    80003020:	ffffe097          	auipc	ra,0xffffe
    80003024:	d0e080e7          	jalr	-754(ra) # 80000d2e <acquire>
  ticks0 = ticks;
    80003028:	00006917          	auipc	s2,0x6
    8000302c:	ff892903          	lw	s2,-8(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80003030:	fcc42783          	lw	a5,-52(s0)
    80003034:	cf85                	beqz	a5,8000306c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003036:	00015997          	auipc	s3,0x15
    8000303a:	37298993          	addi	s3,s3,882 # 800183a8 <tickslock>
    8000303e:	00006497          	auipc	s1,0x6
    80003042:	fe248493          	addi	s1,s1,-30 # 80009020 <ticks>
    if(myproc()->killed){
    80003046:	fffff097          	auipc	ra,0xfffff
    8000304a:	d30080e7          	jalr	-720(ra) # 80001d76 <myproc>
    8000304e:	5d1c                	lw	a5,56(a0)
    80003050:	ef9d                	bnez	a5,8000308e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003052:	85ce                	mv	a1,s3
    80003054:	8526                	mv	a0,s1
    80003056:	fffff097          	auipc	ra,0xfffff
    8000305a:	530080e7          	jalr	1328(ra) # 80002586 <sleep>
  while(ticks - ticks0 < n){
    8000305e:	409c                	lw	a5,0(s1)
    80003060:	412787bb          	subw	a5,a5,s2
    80003064:	fcc42703          	lw	a4,-52(s0)
    80003068:	fce7efe3          	bltu	a5,a4,80003046 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000306c:	00015517          	auipc	a0,0x15
    80003070:	33c50513          	addi	a0,a0,828 # 800183a8 <tickslock>
    80003074:	ffffe097          	auipc	ra,0xffffe
    80003078:	d8a080e7          	jalr	-630(ra) # 80000dfe <release>
  return 0;
    8000307c:	4781                	li	a5,0
}
    8000307e:	853e                	mv	a0,a5
    80003080:	70e2                	ld	ra,56(sp)
    80003082:	7442                	ld	s0,48(sp)
    80003084:	74a2                	ld	s1,40(sp)
    80003086:	7902                	ld	s2,32(sp)
    80003088:	69e2                	ld	s3,24(sp)
    8000308a:	6121                	addi	sp,sp,64
    8000308c:	8082                	ret
      release(&tickslock);
    8000308e:	00015517          	auipc	a0,0x15
    80003092:	31a50513          	addi	a0,a0,794 # 800183a8 <tickslock>
    80003096:	ffffe097          	auipc	ra,0xffffe
    8000309a:	d68080e7          	jalr	-664(ra) # 80000dfe <release>
      return -1;
    8000309e:	57fd                	li	a5,-1
    800030a0:	bff9                	j	8000307e <sys_sleep+0x88>

00000000800030a2 <sys_kill>:

uint64
sys_kill(void)
{
    800030a2:	1101                	addi	sp,sp,-32
    800030a4:	ec06                	sd	ra,24(sp)
    800030a6:	e822                	sd	s0,16(sp)
    800030a8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030aa:	fec40593          	addi	a1,s0,-20
    800030ae:	4501                	li	a0,0
    800030b0:	00000097          	auipc	ra,0x0
    800030b4:	d84080e7          	jalr	-636(ra) # 80002e34 <argint>
    800030b8:	87aa                	mv	a5,a0
    return -1;
    800030ba:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030bc:	0007c863          	bltz	a5,800030cc <sys_kill+0x2a>
  return kill(pid);
    800030c0:	fec42503          	lw	a0,-20(s0)
    800030c4:	fffff097          	auipc	ra,0xfffff
    800030c8:	6b2080e7          	jalr	1714(ra) # 80002776 <kill>
}
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	6105                	addi	sp,sp,32
    800030d2:	8082                	ret

00000000800030d4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030d4:	1101                	addi	sp,sp,-32
    800030d6:	ec06                	sd	ra,24(sp)
    800030d8:	e822                	sd	s0,16(sp)
    800030da:	e426                	sd	s1,8(sp)
    800030dc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030de:	00015517          	auipc	a0,0x15
    800030e2:	2ca50513          	addi	a0,a0,714 # 800183a8 <tickslock>
    800030e6:	ffffe097          	auipc	ra,0xffffe
    800030ea:	c48080e7          	jalr	-952(ra) # 80000d2e <acquire>
  xticks = ticks;
    800030ee:	00006497          	auipc	s1,0x6
    800030f2:	f324a483          	lw	s1,-206(s1) # 80009020 <ticks>
  release(&tickslock);
    800030f6:	00015517          	auipc	a0,0x15
    800030fa:	2b250513          	addi	a0,a0,690 # 800183a8 <tickslock>
    800030fe:	ffffe097          	auipc	ra,0xffffe
    80003102:	d00080e7          	jalr	-768(ra) # 80000dfe <release>
  return xticks;
}
    80003106:	02049513          	slli	a0,s1,0x20
    8000310a:	9101                	srli	a0,a0,0x20
    8000310c:	60e2                	ld	ra,24(sp)
    8000310e:	6442                	ld	s0,16(sp)
    80003110:	64a2                	ld	s1,8(sp)
    80003112:	6105                	addi	sp,sp,32
    80003114:	8082                	ret

0000000080003116 <hash>:
  struct buf buf[BUFFERSIZE];
} bcachebucket[BUCKETSIZE];

int
hash(uint blockno)
{
    80003116:	1141                	addi	sp,sp,-16
    80003118:	e422                	sd	s0,8(sp)
    8000311a:	0800                	addi	s0,sp,16
  return blockno % BUCKETSIZE;
}
    8000311c:	47b5                	li	a5,13
    8000311e:	02f5753b          	remuw	a0,a0,a5
    80003122:	6422                	ld	s0,8(sp)
    80003124:	0141                	addi	sp,sp,16
    80003126:	8082                	ret

0000000080003128 <binit>:

void
binit(void)
{
    80003128:	715d                	addi	sp,sp,-80
    8000312a:	e486                	sd	ra,72(sp)
    8000312c:	e0a2                	sd	s0,64(sp)
    8000312e:	fc26                	sd	s1,56(sp)
    80003130:	f84a                	sd	s2,48(sp)
    80003132:	f44e                	sd	s3,40(sp)
    80003134:	f052                	sd	s4,32(sp)
    80003136:	ec56                	sd	s5,24(sp)
    80003138:	e85a                	sd	s6,16(sp)
    8000313a:	e45e                	sd	s7,8(sp)
    8000313c:	e062                	sd	s8,0(sp)
    8000313e:	0880                	addi	s0,sp,80
  for (int i = 0; i < BUCKETSIZE; i++) {
    80003140:	00017917          	auipc	s2,0x17
    80003144:	8c090913          	addi	s2,s2,-1856 # 80019a00 <bcachebucket+0x1638>
    80003148:	00029c17          	auipc	s8,0x29
    8000314c:	8c0c0c13          	addi	s8,s8,-1856 # 8002ba08 <icache+0x1618>
    initlock(&bcachebucket[i].lock, "bcachebucket");
    80003150:	7a7d                	lui	s4,0xfffff
    80003152:	9c8a0b93          	addi	s7,s4,-1592 # ffffffffffffe9c8 <end+0xffffffff7ffcc9a0>
    80003156:	00005b17          	auipc	s6,0x5
    8000315a:	412b0b13          	addi	s6,s6,1042 # 80008568 <syscalls+0xb0>
    8000315e:	9f8a0a13          	addi	s4,s4,-1544
    for (int j = 0; j < BUFFERSIZE; j++) {
      initsleeplock(&bcachebucket[i].buf[j].lock, "buffer");
    80003162:	00005997          	auipc	s3,0x5
    80003166:	41698993          	addi	s3,s3,1046 # 80008578 <syscalls+0xc0>
    8000316a:	6a85                	lui	s5,0x1
    8000316c:	628a8a93          	addi	s5,s5,1576 # 1628 <_entry-0x7fffe9d8>
    80003170:	a021                	j	80003178 <binit+0x50>
  for (int i = 0; i < BUCKETSIZE; i++) {
    80003172:	9956                	add	s2,s2,s5
    80003174:	03890663          	beq	s2,s8,800031a0 <binit+0x78>
    initlock(&bcachebucket[i].lock, "bcachebucket");
    80003178:	85da                	mv	a1,s6
    8000317a:	01790533          	add	a0,s2,s7
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	d2c080e7          	jalr	-724(ra) # 80000eaa <initlock>
    for (int j = 0; j < BUFFERSIZE; j++) {
    80003186:	014904b3          	add	s1,s2,s4
      initsleeplock(&bcachebucket[i].buf[j].lock, "buffer");
    8000318a:	85ce                	mv	a1,s3
    8000318c:	8526                	mv	a0,s1
    8000318e:	00001097          	auipc	ra,0x1
    80003192:	566080e7          	jalr	1382(ra) # 800046f4 <initsleeplock>
    for (int j = 0; j < BUFFERSIZE; j++) {
    80003196:	46848493          	addi	s1,s1,1128
    8000319a:	ff2498e3          	bne	s1,s2,8000318a <binit+0x62>
    8000319e:	bfd1                	j	80003172 <binit+0x4a>
    }
  }
}
    800031a0:	60a6                	ld	ra,72(sp)
    800031a2:	6406                	ld	s0,64(sp)
    800031a4:	74e2                	ld	s1,56(sp)
    800031a6:	7942                	ld	s2,48(sp)
    800031a8:	79a2                	ld	s3,40(sp)
    800031aa:	7a02                	ld	s4,32(sp)
    800031ac:	6ae2                	ld	s5,24(sp)
    800031ae:	6b42                	ld	s6,16(sp)
    800031b0:	6ba2                	ld	s7,8(sp)
    800031b2:	6c02                	ld	s8,0(sp)
    800031b4:	6161                	addi	sp,sp,80
    800031b6:	8082                	ret

00000000800031b8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031b8:	715d                	addi	sp,sp,-80
    800031ba:	e486                	sd	ra,72(sp)
    800031bc:	e0a2                	sd	s0,64(sp)
    800031be:	fc26                	sd	s1,56(sp)
    800031c0:	f84a                	sd	s2,48(sp)
    800031c2:	f44e                	sd	s3,40(sp)
    800031c4:	f052                	sd	s4,32(sp)
    800031c6:	ec56                	sd	s5,24(sp)
    800031c8:	e85a                	sd	s6,16(sp)
    800031ca:	e45e                	sd	s7,8(sp)
    800031cc:	e062                	sd	s8,0(sp)
    800031ce:	0880                	addi	s0,sp,80
    800031d0:	8c2a                	mv	s8,a0
    800031d2:	8bae                	mv	s7,a1
  return blockno % BUCKETSIZE;
    800031d4:	44b5                	li	s1,13
    800031d6:	0295f4bb          	remuw	s1,a1,s1
  acquire(&bcachebucket[bucket].lock);
    800031da:	6905                	lui	s2,0x1
    800031dc:	62890913          	addi	s2,s2,1576 # 1628 <_entry-0x7fffe9d8>
    800031e0:	03248933          	mul	s2,s1,s2
    800031e4:	00015a97          	auipc	s5,0x15
    800031e8:	1e4a8a93          	addi	s5,s5,484 # 800183c8 <bcachebucket>
    800031ec:	9aca                	add	s5,s5,s2
    800031ee:	8556                	mv	a0,s5
    800031f0:	ffffe097          	auipc	ra,0xffffe
    800031f4:	b3e080e7          	jalr	-1218(ra) # 80000d2e <acquire>
  for (int i = 0; i < BUFFERSIZE; i++) {
    800031f8:	87d6                	mv	a5,s5
  acquire(&bcachebucket[bucket].lock);
    800031fa:	8756                	mv	a4,s5
  for (int i = 0; i < BUFFERSIZE; i++) {
    800031fc:	4501                	li	a0,0
    800031fe:	4695                	li	a3,5
    80003200:	a031                	j	8000320c <bread+0x54>
    80003202:	2505                	addiw	a0,a0,1
    80003204:	46870713          	addi	a4,a4,1128
    80003208:	06d50263          	beq	a0,a3,8000326c <bread+0xb4>
    if (b->dev == dev && b->blockno == blockno) {
    8000320c:	5710                	lw	a2,40(a4)
    8000320e:	ff861ae3          	bne	a2,s8,80003202 <bread+0x4a>
    80003212:	5750                	lw	a2,44(a4)
    80003214:	ff7617e3          	bne	a2,s7,80003202 <bread+0x4a>
    80003218:	46800a13          	li	s4,1128
    8000321c:	03450a33          	mul	s4,a0,s4
    b = &bcachebucket[bucket].buf[i];
    80003220:	02090993          	addi	s3,s2,32
    80003224:	99d2                	add	s3,s3,s4
    80003226:	00015b17          	auipc	s6,0x15
    8000322a:	1a2b0b13          	addi	s6,s6,418 # 800183c8 <bcachebucket>
    8000322e:	99da                	add	s3,s3,s6
      b->refcnt++;
    80003230:	6785                	lui	a5,0x1
    80003232:	62878793          	addi	a5,a5,1576 # 1628 <_entry-0x7fffe9d8>
    80003236:	02f484b3          	mul	s1,s1,a5
    8000323a:	94d2                	add	s1,s1,s4
    8000323c:	94da                	add	s1,s1,s6
    8000323e:	54bc                	lw	a5,104(s1)
    80003240:	2785                	addiw	a5,a5,1
    80003242:	d4bc                	sw	a5,104(s1)
      b->lastuse = ticks;
    80003244:	00006797          	auipc	a5,0x6
    80003248:	ddc7a783          	lw	a5,-548(a5) # 80009020 <ticks>
    8000324c:	48f4a023          	sw	a5,1152(s1)
      release(&bcachebucket[bucket].lock);
    80003250:	8556                	mv	a0,s5
    80003252:	ffffe097          	auipc	ra,0xffffe
    80003256:	bac080e7          	jalr	-1108(ra) # 80000dfe <release>
      acquiresleep(&b->lock);
    8000325a:	03090513          	addi	a0,s2,48
    8000325e:	9552                	add	a0,a0,s4
    80003260:	955a                	add	a0,a0,s6
    80003262:	00001097          	auipc	ra,0x1
    80003266:	4cc080e7          	jalr	1228(ra) # 8000472e <acquiresleep>
      return b;
    8000326a:	a069                	j	800032f4 <bread+0x13c>
  int least_idx = -1;
    8000326c:	557d                	li	a0,-1
  uint least = 0xffffffff;
    8000326e:	567d                	li	a2,-1
  for (int i = 0; i < BUFFERSIZE; i++) {
    80003270:	4701                	li	a4,0
    80003272:	4595                	li	a1,5
    80003274:	a031                	j	80003280 <bread+0xc8>
    80003276:	2705                	addiw	a4,a4,1
    80003278:	46878793          	addi	a5,a5,1128
    8000327c:	00b70b63          	beq	a4,a1,80003292 <bread+0xda>
    if(b->refcnt == 0 && b->lastuse < least) {
    80003280:	57b4                	lw	a3,104(a5)
    80003282:	faf5                	bnez	a3,80003276 <bread+0xbe>
    80003284:	4807a683          	lw	a3,1152(a5)
    80003288:	fec6f7e3          	bgeu	a3,a2,80003276 <bread+0xbe>
    8000328c:	853a                	mv	a0,a4
      least = b->lastuse;
    8000328e:	8636                	mv	a2,a3
    80003290:	b7dd                	j	80003276 <bread+0xbe>
  if (least_idx == -1) {
    80003292:	57fd                	li	a5,-1
    80003294:	08f50063          	beq	a0,a5,80003314 <bread+0x15c>
  b = &bcachebucket[bucket].buf[least_idx];
    80003298:	46800a13          	li	s4,1128
    8000329c:	03450a33          	mul	s4,a0,s4
    800032a0:	02090993          	addi	s3,s2,32
    800032a4:	99d2                	add	s3,s3,s4
    800032a6:	00015b17          	auipc	s6,0x15
    800032aa:	122b0b13          	addi	s6,s6,290 # 800183c8 <bcachebucket>
    800032ae:	99da                	add	s3,s3,s6
  b->dev = dev;
    800032b0:	6785                	lui	a5,0x1
    800032b2:	62878793          	addi	a5,a5,1576 # 1628 <_entry-0x7fffe9d8>
    800032b6:	02f487b3          	mul	a5,s1,a5
    800032ba:	97d2                	add	a5,a5,s4
    800032bc:	97da                	add	a5,a5,s6
    800032be:	0387a423          	sw	s8,40(a5)
  b->blockno = blockno;
    800032c2:	0377a623          	sw	s7,44(a5)
  b->lastuse = ticks;
    800032c6:	00006717          	auipc	a4,0x6
    800032ca:	d5a72703          	lw	a4,-678(a4) # 80009020 <ticks>
    800032ce:	48e7a023          	sw	a4,1152(a5)
  b->valid = 0;
    800032d2:	0207a023          	sw	zero,32(a5)
  b->refcnt = 1;
    800032d6:	4705                	li	a4,1
    800032d8:	d7b8                	sw	a4,104(a5)
  release(&bcachebucket[bucket].lock);
    800032da:	8556                	mv	a0,s5
    800032dc:	ffffe097          	auipc	ra,0xffffe
    800032e0:	b22080e7          	jalr	-1246(ra) # 80000dfe <release>
  acquiresleep(&b->lock);
    800032e4:	03090513          	addi	a0,s2,48
    800032e8:	9552                	add	a0,a0,s4
    800032ea:	955a                	add	a0,a0,s6
    800032ec:	00001097          	auipc	ra,0x1
    800032f0:	442080e7          	jalr	1090(ra) # 8000472e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800032f4:	0009a783          	lw	a5,0(s3)
    800032f8:	c795                	beqz	a5,80003324 <bread+0x16c>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032fa:	854e                	mv	a0,s3
    800032fc:	60a6                	ld	ra,72(sp)
    800032fe:	6406                	ld	s0,64(sp)
    80003300:	74e2                	ld	s1,56(sp)
    80003302:	7942                	ld	s2,48(sp)
    80003304:	79a2                	ld	s3,40(sp)
    80003306:	7a02                	ld	s4,32(sp)
    80003308:	6ae2                	ld	s5,24(sp)
    8000330a:	6b42                	ld	s6,16(sp)
    8000330c:	6ba2                	ld	s7,8(sp)
    8000330e:	6c02                	ld	s8,0(sp)
    80003310:	6161                	addi	sp,sp,80
    80003312:	8082                	ret
    panic("bget: no unused buffer for recycle");
    80003314:	00005517          	auipc	a0,0x5
    80003318:	26c50513          	addi	a0,a0,620 # 80008580 <syscalls+0xc8>
    8000331c:	ffffd097          	auipc	ra,0xffffd
    80003320:	234080e7          	jalr	564(ra) # 80000550 <panic>
    virtio_disk_rw(b, 0);
    80003324:	4581                	li	a1,0
    80003326:	854e                	mv	a0,s3
    80003328:	00003097          	auipc	ra,0x3
    8000332c:	f7e080e7          	jalr	-130(ra) # 800062a6 <virtio_disk_rw>
    b->valid = 1;
    80003330:	4785                	li	a5,1
    80003332:	00f9a023          	sw	a5,0(s3)
  return b;
    80003336:	b7d1                	j	800032fa <bread+0x142>

0000000080003338 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003338:	1101                	addi	sp,sp,-32
    8000333a:	ec06                	sd	ra,24(sp)
    8000333c:	e822                	sd	s0,16(sp)
    8000333e:	e426                	sd	s1,8(sp)
    80003340:	1000                	addi	s0,sp,32
    80003342:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003344:	0541                	addi	a0,a0,16
    80003346:	00001097          	auipc	ra,0x1
    8000334a:	482080e7          	jalr	1154(ra) # 800047c8 <holdingsleep>
    8000334e:	cd01                	beqz	a0,80003366 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003350:	4585                	li	a1,1
    80003352:	8526                	mv	a0,s1
    80003354:	00003097          	auipc	ra,0x3
    80003358:	f52080e7          	jalr	-174(ra) # 800062a6 <virtio_disk_rw>
}
    8000335c:	60e2                	ld	ra,24(sp)
    8000335e:	6442                	ld	s0,16(sp)
    80003360:	64a2                	ld	s1,8(sp)
    80003362:	6105                	addi	sp,sp,32
    80003364:	8082                	ret
    panic("bwrite");
    80003366:	00005517          	auipc	a0,0x5
    8000336a:	24250513          	addi	a0,a0,578 # 800085a8 <syscalls+0xf0>
    8000336e:	ffffd097          	auipc	ra,0xffffd
    80003372:	1e2080e7          	jalr	482(ra) # 80000550 <panic>

0000000080003376 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003376:	7179                	addi	sp,sp,-48
    80003378:	f406                	sd	ra,40(sp)
    8000337a:	f022                	sd	s0,32(sp)
    8000337c:	ec26                	sd	s1,24(sp)
    8000337e:	e84a                	sd	s2,16(sp)
    80003380:	e44e                	sd	s3,8(sp)
    80003382:	1800                	addi	s0,sp,48
    80003384:	892a                	mv	s2,a0
  if(!holdingsleep(&b->lock))
    80003386:	01050993          	addi	s3,a0,16
    8000338a:	854e                	mv	a0,s3
    8000338c:	00001097          	auipc	ra,0x1
    80003390:	43c080e7          	jalr	1084(ra) # 800047c8 <holdingsleep>
    80003394:	c939                	beqz	a0,800033ea <brelse+0x74>
  return blockno % BUCKETSIZE;
    80003396:	00c92483          	lw	s1,12(s2)
    panic("brelse");


  int bucket = hash(b->blockno);
  acquire(&bcachebucket[bucket].lock);
    8000339a:	47b5                	li	a5,13
    8000339c:	02f4f4bb          	remuw	s1,s1,a5
    800033a0:	6785                	lui	a5,0x1
    800033a2:	62878793          	addi	a5,a5,1576 # 1628 <_entry-0x7fffe9d8>
    800033a6:	02f484b3          	mul	s1,s1,a5
    800033aa:	00015797          	auipc	a5,0x15
    800033ae:	01e78793          	addi	a5,a5,30 # 800183c8 <bcachebucket>
    800033b2:	94be                	add	s1,s1,a5
    800033b4:	8526                	mv	a0,s1
    800033b6:	ffffe097          	auipc	ra,0xffffe
    800033ba:	978080e7          	jalr	-1672(ra) # 80000d2e <acquire>
  b->refcnt--;
    800033be:	04892783          	lw	a5,72(s2)
    800033c2:	37fd                	addiw	a5,a5,-1
    800033c4:	04f92423          	sw	a5,72(s2)
  release(&bcachebucket[bucket].lock);
    800033c8:	8526                	mv	a0,s1
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	a34080e7          	jalr	-1484(ra) # 80000dfe <release>
  releasesleep(&b->lock);
    800033d2:	854e                	mv	a0,s3
    800033d4:	00001097          	auipc	ra,0x1
    800033d8:	3b0080e7          	jalr	944(ra) # 80004784 <releasesleep>
}
    800033dc:	70a2                	ld	ra,40(sp)
    800033de:	7402                	ld	s0,32(sp)
    800033e0:	64e2                	ld	s1,24(sp)
    800033e2:	6942                	ld	s2,16(sp)
    800033e4:	69a2                	ld	s3,8(sp)
    800033e6:	6145                	addi	sp,sp,48
    800033e8:	8082                	ret
    panic("brelse");
    800033ea:	00005517          	auipc	a0,0x5
    800033ee:	1c650513          	addi	a0,a0,454 # 800085b0 <syscalls+0xf8>
    800033f2:	ffffd097          	auipc	ra,0xffffd
    800033f6:	15e080e7          	jalr	350(ra) # 80000550 <panic>

00000000800033fa <bpin>:

void
bpin(struct buf *b) {
    800033fa:	1101                	addi	sp,sp,-32
    800033fc:	ec06                	sd	ra,24(sp)
    800033fe:	e822                	sd	s0,16(sp)
    80003400:	e426                	sd	s1,8(sp)
    80003402:	e04a                	sd	s2,0(sp)
    80003404:	1000                	addi	s0,sp,32
    80003406:	892a                	mv	s2,a0
  return blockno % BUCKETSIZE;
    80003408:	4544                	lw	s1,12(a0)
  int bucket = hash(b->blockno);
  acquire(&bcachebucket[bucket].lock);
    8000340a:	47b5                	li	a5,13
    8000340c:	02f4f4bb          	remuw	s1,s1,a5
    80003410:	6785                	lui	a5,0x1
    80003412:	62878793          	addi	a5,a5,1576 # 1628 <_entry-0x7fffe9d8>
    80003416:	02f484b3          	mul	s1,s1,a5
    8000341a:	00015797          	auipc	a5,0x15
    8000341e:	fae78793          	addi	a5,a5,-82 # 800183c8 <bcachebucket>
    80003422:	94be                	add	s1,s1,a5
    80003424:	8526                	mv	a0,s1
    80003426:	ffffe097          	auipc	ra,0xffffe
    8000342a:	908080e7          	jalr	-1784(ra) # 80000d2e <acquire>
  b->refcnt++;
    8000342e:	04892783          	lw	a5,72(s2)
    80003432:	2785                	addiw	a5,a5,1
    80003434:	04f92423          	sw	a5,72(s2)
  release(&bcachebucket[bucket].lock);
    80003438:	8526                	mv	a0,s1
    8000343a:	ffffe097          	auipc	ra,0xffffe
    8000343e:	9c4080e7          	jalr	-1596(ra) # 80000dfe <release>
}
    80003442:	60e2                	ld	ra,24(sp)
    80003444:	6442                	ld	s0,16(sp)
    80003446:	64a2                	ld	s1,8(sp)
    80003448:	6902                	ld	s2,0(sp)
    8000344a:	6105                	addi	sp,sp,32
    8000344c:	8082                	ret

000000008000344e <bunpin>:

void
bunpin(struct buf *b) {
    8000344e:	1101                	addi	sp,sp,-32
    80003450:	ec06                	sd	ra,24(sp)
    80003452:	e822                	sd	s0,16(sp)
    80003454:	e426                	sd	s1,8(sp)
    80003456:	e04a                	sd	s2,0(sp)
    80003458:	1000                	addi	s0,sp,32
    8000345a:	892a                	mv	s2,a0
  return blockno % BUCKETSIZE;
    8000345c:	4544                	lw	s1,12(a0)
  int bucket = hash(b->blockno);
  acquire(&bcachebucket[bucket].lock);
    8000345e:	47b5                	li	a5,13
    80003460:	02f4f4bb          	remuw	s1,s1,a5
    80003464:	6785                	lui	a5,0x1
    80003466:	62878793          	addi	a5,a5,1576 # 1628 <_entry-0x7fffe9d8>
    8000346a:	02f484b3          	mul	s1,s1,a5
    8000346e:	00015797          	auipc	a5,0x15
    80003472:	f5a78793          	addi	a5,a5,-166 # 800183c8 <bcachebucket>
    80003476:	94be                	add	s1,s1,a5
    80003478:	8526                	mv	a0,s1
    8000347a:	ffffe097          	auipc	ra,0xffffe
    8000347e:	8b4080e7          	jalr	-1868(ra) # 80000d2e <acquire>
  b->refcnt--;
    80003482:	04892783          	lw	a5,72(s2)
    80003486:	37fd                	addiw	a5,a5,-1
    80003488:	04f92423          	sw	a5,72(s2)
  release(&bcachebucket[bucket].lock);
    8000348c:	8526                	mv	a0,s1
    8000348e:	ffffe097          	auipc	ra,0xffffe
    80003492:	970080e7          	jalr	-1680(ra) # 80000dfe <release>
}
    80003496:	60e2                	ld	ra,24(sp)
    80003498:	6442                	ld	s0,16(sp)
    8000349a:	64a2                	ld	s1,8(sp)
    8000349c:	6902                	ld	s2,0(sp)
    8000349e:	6105                	addi	sp,sp,32
    800034a0:	8082                	ret

00000000800034a2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800034a2:	1101                	addi	sp,sp,-32
    800034a4:	ec06                	sd	ra,24(sp)
    800034a6:	e822                	sd	s0,16(sp)
    800034a8:	e426                	sd	s1,8(sp)
    800034aa:	e04a                	sd	s2,0(sp)
    800034ac:	1000                	addi	s0,sp,32
    800034ae:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800034b0:	00d5d59b          	srliw	a1,a1,0xd
    800034b4:	00027797          	auipc	a5,0x27
    800034b8:	f387a783          	lw	a5,-200(a5) # 8002a3ec <sb+0x1c>
    800034bc:	9dbd                	addw	a1,a1,a5
    800034be:	00000097          	auipc	ra,0x0
    800034c2:	cfa080e7          	jalr	-774(ra) # 800031b8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034c6:	0074f713          	andi	a4,s1,7
    800034ca:	4785                	li	a5,1
    800034cc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800034d0:	14ce                	slli	s1,s1,0x33
    800034d2:	90d9                	srli	s1,s1,0x36
    800034d4:	00950733          	add	a4,a0,s1
    800034d8:	06074703          	lbu	a4,96(a4)
    800034dc:	00e7f6b3          	and	a3,a5,a4
    800034e0:	c69d                	beqz	a3,8000350e <bfree+0x6c>
    800034e2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034e4:	94aa                	add	s1,s1,a0
    800034e6:	fff7c793          	not	a5,a5
    800034ea:	8ff9                	and	a5,a5,a4
    800034ec:	06f48023          	sb	a5,96(s1)
  log_write(bp);
    800034f0:	00001097          	auipc	ra,0x1
    800034f4:	116080e7          	jalr	278(ra) # 80004606 <log_write>
  brelse(bp);
    800034f8:	854a                	mv	a0,s2
    800034fa:	00000097          	auipc	ra,0x0
    800034fe:	e7c080e7          	jalr	-388(ra) # 80003376 <brelse>
}
    80003502:	60e2                	ld	ra,24(sp)
    80003504:	6442                	ld	s0,16(sp)
    80003506:	64a2                	ld	s1,8(sp)
    80003508:	6902                	ld	s2,0(sp)
    8000350a:	6105                	addi	sp,sp,32
    8000350c:	8082                	ret
    panic("freeing free block");
    8000350e:	00005517          	auipc	a0,0x5
    80003512:	0aa50513          	addi	a0,a0,170 # 800085b8 <syscalls+0x100>
    80003516:	ffffd097          	auipc	ra,0xffffd
    8000351a:	03a080e7          	jalr	58(ra) # 80000550 <panic>

000000008000351e <balloc>:
{
    8000351e:	711d                	addi	sp,sp,-96
    80003520:	ec86                	sd	ra,88(sp)
    80003522:	e8a2                	sd	s0,80(sp)
    80003524:	e4a6                	sd	s1,72(sp)
    80003526:	e0ca                	sd	s2,64(sp)
    80003528:	fc4e                	sd	s3,56(sp)
    8000352a:	f852                	sd	s4,48(sp)
    8000352c:	f456                	sd	s5,40(sp)
    8000352e:	f05a                	sd	s6,32(sp)
    80003530:	ec5e                	sd	s7,24(sp)
    80003532:	e862                	sd	s8,16(sp)
    80003534:	e466                	sd	s9,8(sp)
    80003536:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003538:	00027797          	auipc	a5,0x27
    8000353c:	e9c7a783          	lw	a5,-356(a5) # 8002a3d4 <sb+0x4>
    80003540:	cbd1                	beqz	a5,800035d4 <balloc+0xb6>
    80003542:	8baa                	mv	s7,a0
    80003544:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003546:	00027b17          	auipc	s6,0x27
    8000354a:	e8ab0b13          	addi	s6,s6,-374 # 8002a3d0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000354e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003550:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003552:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003554:	6c89                	lui	s9,0x2
    80003556:	a831                	j	80003572 <balloc+0x54>
    brelse(bp);
    80003558:	854a                	mv	a0,s2
    8000355a:	00000097          	auipc	ra,0x0
    8000355e:	e1c080e7          	jalr	-484(ra) # 80003376 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003562:	015c87bb          	addw	a5,s9,s5
    80003566:	00078a9b          	sext.w	s5,a5
    8000356a:	004b2703          	lw	a4,4(s6)
    8000356e:	06eaf363          	bgeu	s5,a4,800035d4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003572:	41fad79b          	sraiw	a5,s5,0x1f
    80003576:	0137d79b          	srliw	a5,a5,0x13
    8000357a:	015787bb          	addw	a5,a5,s5
    8000357e:	40d7d79b          	sraiw	a5,a5,0xd
    80003582:	01cb2583          	lw	a1,28(s6)
    80003586:	9dbd                	addw	a1,a1,a5
    80003588:	855e                	mv	a0,s7
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	c2e080e7          	jalr	-978(ra) # 800031b8 <bread>
    80003592:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003594:	004b2503          	lw	a0,4(s6)
    80003598:	000a849b          	sext.w	s1,s5
    8000359c:	8662                	mv	a2,s8
    8000359e:	faa4fde3          	bgeu	s1,a0,80003558 <balloc+0x3a>
      m = 1 << (bi % 8);
    800035a2:	41f6579b          	sraiw	a5,a2,0x1f
    800035a6:	01d7d69b          	srliw	a3,a5,0x1d
    800035aa:	00c6873b          	addw	a4,a3,a2
    800035ae:	00777793          	andi	a5,a4,7
    800035b2:	9f95                	subw	a5,a5,a3
    800035b4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035b8:	4037571b          	sraiw	a4,a4,0x3
    800035bc:	00e906b3          	add	a3,s2,a4
    800035c0:	0606c683          	lbu	a3,96(a3)
    800035c4:	00d7f5b3          	and	a1,a5,a3
    800035c8:	cd91                	beqz	a1,800035e4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035ca:	2605                	addiw	a2,a2,1
    800035cc:	2485                	addiw	s1,s1,1
    800035ce:	fd4618e3          	bne	a2,s4,8000359e <balloc+0x80>
    800035d2:	b759                	j	80003558 <balloc+0x3a>
  panic("balloc: out of blocks");
    800035d4:	00005517          	auipc	a0,0x5
    800035d8:	ffc50513          	addi	a0,a0,-4 # 800085d0 <syscalls+0x118>
    800035dc:	ffffd097          	auipc	ra,0xffffd
    800035e0:	f74080e7          	jalr	-140(ra) # 80000550 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035e4:	974a                	add	a4,a4,s2
    800035e6:	8fd5                	or	a5,a5,a3
    800035e8:	06f70023          	sb	a5,96(a4)
        log_write(bp);
    800035ec:	854a                	mv	a0,s2
    800035ee:	00001097          	auipc	ra,0x1
    800035f2:	018080e7          	jalr	24(ra) # 80004606 <log_write>
        brelse(bp);
    800035f6:	854a                	mv	a0,s2
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	d7e080e7          	jalr	-642(ra) # 80003376 <brelse>
  bp = bread(dev, bno);
    80003600:	85a6                	mv	a1,s1
    80003602:	855e                	mv	a0,s7
    80003604:	00000097          	auipc	ra,0x0
    80003608:	bb4080e7          	jalr	-1100(ra) # 800031b8 <bread>
    8000360c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000360e:	40000613          	li	a2,1024
    80003612:	4581                	li	a1,0
    80003614:	06050513          	addi	a0,a0,96
    80003618:	ffffe097          	auipc	ra,0xffffe
    8000361c:	af6080e7          	jalr	-1290(ra) # 8000110e <memset>
  log_write(bp);
    80003620:	854a                	mv	a0,s2
    80003622:	00001097          	auipc	ra,0x1
    80003626:	fe4080e7          	jalr	-28(ra) # 80004606 <log_write>
  brelse(bp);
    8000362a:	854a                	mv	a0,s2
    8000362c:	00000097          	auipc	ra,0x0
    80003630:	d4a080e7          	jalr	-694(ra) # 80003376 <brelse>
}
    80003634:	8526                	mv	a0,s1
    80003636:	60e6                	ld	ra,88(sp)
    80003638:	6446                	ld	s0,80(sp)
    8000363a:	64a6                	ld	s1,72(sp)
    8000363c:	6906                	ld	s2,64(sp)
    8000363e:	79e2                	ld	s3,56(sp)
    80003640:	7a42                	ld	s4,48(sp)
    80003642:	7aa2                	ld	s5,40(sp)
    80003644:	7b02                	ld	s6,32(sp)
    80003646:	6be2                	ld	s7,24(sp)
    80003648:	6c42                	ld	s8,16(sp)
    8000364a:	6ca2                	ld	s9,8(sp)
    8000364c:	6125                	addi	sp,sp,96
    8000364e:	8082                	ret

0000000080003650 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003650:	7179                	addi	sp,sp,-48
    80003652:	f406                	sd	ra,40(sp)
    80003654:	f022                	sd	s0,32(sp)
    80003656:	ec26                	sd	s1,24(sp)
    80003658:	e84a                	sd	s2,16(sp)
    8000365a:	e44e                	sd	s3,8(sp)
    8000365c:	e052                	sd	s4,0(sp)
    8000365e:	1800                	addi	s0,sp,48
    80003660:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003662:	47ad                	li	a5,11
    80003664:	04b7fe63          	bgeu	a5,a1,800036c0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003668:	ff45849b          	addiw	s1,a1,-12
    8000366c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003670:	0ff00793          	li	a5,255
    80003674:	0ae7e363          	bltu	a5,a4,8000371a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003678:	08852583          	lw	a1,136(a0)
    8000367c:	c5ad                	beqz	a1,800036e6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000367e:	00092503          	lw	a0,0(s2)
    80003682:	00000097          	auipc	ra,0x0
    80003686:	b36080e7          	jalr	-1226(ra) # 800031b8 <bread>
    8000368a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000368c:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    80003690:	02049593          	slli	a1,s1,0x20
    80003694:	9181                	srli	a1,a1,0x20
    80003696:	058a                	slli	a1,a1,0x2
    80003698:	00b784b3          	add	s1,a5,a1
    8000369c:	0004a983          	lw	s3,0(s1)
    800036a0:	04098d63          	beqz	s3,800036fa <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800036a4:	8552                	mv	a0,s4
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	cd0080e7          	jalr	-816(ra) # 80003376 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036ae:	854e                	mv	a0,s3
    800036b0:	70a2                	ld	ra,40(sp)
    800036b2:	7402                	ld	s0,32(sp)
    800036b4:	64e2                	ld	s1,24(sp)
    800036b6:	6942                	ld	s2,16(sp)
    800036b8:	69a2                	ld	s3,8(sp)
    800036ba:	6a02                	ld	s4,0(sp)
    800036bc:	6145                	addi	sp,sp,48
    800036be:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800036c0:	02059493          	slli	s1,a1,0x20
    800036c4:	9081                	srli	s1,s1,0x20
    800036c6:	048a                	slli	s1,s1,0x2
    800036c8:	94aa                	add	s1,s1,a0
    800036ca:	0584a983          	lw	s3,88(s1)
    800036ce:	fe0990e3          	bnez	s3,800036ae <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800036d2:	4108                	lw	a0,0(a0)
    800036d4:	00000097          	auipc	ra,0x0
    800036d8:	e4a080e7          	jalr	-438(ra) # 8000351e <balloc>
    800036dc:	0005099b          	sext.w	s3,a0
    800036e0:	0534ac23          	sw	s3,88(s1)
    800036e4:	b7e9                	j	800036ae <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800036e6:	4108                	lw	a0,0(a0)
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	e36080e7          	jalr	-458(ra) # 8000351e <balloc>
    800036f0:	0005059b          	sext.w	a1,a0
    800036f4:	08b92423          	sw	a1,136(s2)
    800036f8:	b759                	j	8000367e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800036fa:	00092503          	lw	a0,0(s2)
    800036fe:	00000097          	auipc	ra,0x0
    80003702:	e20080e7          	jalr	-480(ra) # 8000351e <balloc>
    80003706:	0005099b          	sext.w	s3,a0
    8000370a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000370e:	8552                	mv	a0,s4
    80003710:	00001097          	auipc	ra,0x1
    80003714:	ef6080e7          	jalr	-266(ra) # 80004606 <log_write>
    80003718:	b771                	j	800036a4 <bmap+0x54>
  panic("bmap: out of range");
    8000371a:	00005517          	auipc	a0,0x5
    8000371e:	ece50513          	addi	a0,a0,-306 # 800085e8 <syscalls+0x130>
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	e2e080e7          	jalr	-466(ra) # 80000550 <panic>

000000008000372a <iget>:
{
    8000372a:	7179                	addi	sp,sp,-48
    8000372c:	f406                	sd	ra,40(sp)
    8000372e:	f022                	sd	s0,32(sp)
    80003730:	ec26                	sd	s1,24(sp)
    80003732:	e84a                	sd	s2,16(sp)
    80003734:	e44e                	sd	s3,8(sp)
    80003736:	e052                	sd	s4,0(sp)
    80003738:	1800                	addi	s0,sp,48
    8000373a:	89aa                	mv	s3,a0
    8000373c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000373e:	00027517          	auipc	a0,0x27
    80003742:	cb250513          	addi	a0,a0,-846 # 8002a3f0 <icache>
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	5e8080e7          	jalr	1512(ra) # 80000d2e <acquire>
  empty = 0;
    8000374e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003750:	00027497          	auipc	s1,0x27
    80003754:	cc048493          	addi	s1,s1,-832 # 8002a410 <icache+0x20>
    80003758:	00029697          	auipc	a3,0x29
    8000375c:	8d868693          	addi	a3,a3,-1832 # 8002c030 <log>
    80003760:	a039                	j	8000376e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003762:	02090b63          	beqz	s2,80003798 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003766:	09048493          	addi	s1,s1,144
    8000376a:	02d48a63          	beq	s1,a3,8000379e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000376e:	449c                	lw	a5,8(s1)
    80003770:	fef059e3          	blez	a5,80003762 <iget+0x38>
    80003774:	4098                	lw	a4,0(s1)
    80003776:	ff3716e3          	bne	a4,s3,80003762 <iget+0x38>
    8000377a:	40d8                	lw	a4,4(s1)
    8000377c:	ff4713e3          	bne	a4,s4,80003762 <iget+0x38>
      ip->ref++;
    80003780:	2785                	addiw	a5,a5,1
    80003782:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003784:	00027517          	auipc	a0,0x27
    80003788:	c6c50513          	addi	a0,a0,-916 # 8002a3f0 <icache>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	672080e7          	jalr	1650(ra) # 80000dfe <release>
      return ip;
    80003794:	8926                	mv	s2,s1
    80003796:	a03d                	j	800037c4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003798:	f7f9                	bnez	a5,80003766 <iget+0x3c>
    8000379a:	8926                	mv	s2,s1
    8000379c:	b7e9                	j	80003766 <iget+0x3c>
  if(empty == 0)
    8000379e:	02090c63          	beqz	s2,800037d6 <iget+0xac>
  ip->dev = dev;
    800037a2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800037a6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800037aa:	4785                	li	a5,1
    800037ac:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800037b0:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    800037b4:	00027517          	auipc	a0,0x27
    800037b8:	c3c50513          	addi	a0,a0,-964 # 8002a3f0 <icache>
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	642080e7          	jalr	1602(ra) # 80000dfe <release>
}
    800037c4:	854a                	mv	a0,s2
    800037c6:	70a2                	ld	ra,40(sp)
    800037c8:	7402                	ld	s0,32(sp)
    800037ca:	64e2                	ld	s1,24(sp)
    800037cc:	6942                	ld	s2,16(sp)
    800037ce:	69a2                	ld	s3,8(sp)
    800037d0:	6a02                	ld	s4,0(sp)
    800037d2:	6145                	addi	sp,sp,48
    800037d4:	8082                	ret
    panic("iget: no inodes");
    800037d6:	00005517          	auipc	a0,0x5
    800037da:	e2a50513          	addi	a0,a0,-470 # 80008600 <syscalls+0x148>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	d72080e7          	jalr	-654(ra) # 80000550 <panic>

00000000800037e6 <fsinit>:
fsinit(int dev) {
    800037e6:	7179                	addi	sp,sp,-48
    800037e8:	f406                	sd	ra,40(sp)
    800037ea:	f022                	sd	s0,32(sp)
    800037ec:	ec26                	sd	s1,24(sp)
    800037ee:	e84a                	sd	s2,16(sp)
    800037f0:	e44e                	sd	s3,8(sp)
    800037f2:	1800                	addi	s0,sp,48
    800037f4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037f6:	4585                	li	a1,1
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	9c0080e7          	jalr	-1600(ra) # 800031b8 <bread>
    80003800:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003802:	00027997          	auipc	s3,0x27
    80003806:	bce98993          	addi	s3,s3,-1074 # 8002a3d0 <sb>
    8000380a:	02000613          	li	a2,32
    8000380e:	06050593          	addi	a1,a0,96
    80003812:	854e                	mv	a0,s3
    80003814:	ffffe097          	auipc	ra,0xffffe
    80003818:	95a080e7          	jalr	-1702(ra) # 8000116e <memmove>
  brelse(bp);
    8000381c:	8526                	mv	a0,s1
    8000381e:	00000097          	auipc	ra,0x0
    80003822:	b58080e7          	jalr	-1192(ra) # 80003376 <brelse>
  if(sb.magic != FSMAGIC)
    80003826:	0009a703          	lw	a4,0(s3)
    8000382a:	102037b7          	lui	a5,0x10203
    8000382e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003832:	02f71263          	bne	a4,a5,80003856 <fsinit+0x70>
  initlog(dev, &sb);
    80003836:	00027597          	auipc	a1,0x27
    8000383a:	b9a58593          	addi	a1,a1,-1126 # 8002a3d0 <sb>
    8000383e:	854a                	mv	a0,s2
    80003840:	00001097          	auipc	ra,0x1
    80003844:	b4a080e7          	jalr	-1206(ra) # 8000438a <initlog>
}
    80003848:	70a2                	ld	ra,40(sp)
    8000384a:	7402                	ld	s0,32(sp)
    8000384c:	64e2                	ld	s1,24(sp)
    8000384e:	6942                	ld	s2,16(sp)
    80003850:	69a2                	ld	s3,8(sp)
    80003852:	6145                	addi	sp,sp,48
    80003854:	8082                	ret
    panic("invalid file system");
    80003856:	00005517          	auipc	a0,0x5
    8000385a:	dba50513          	addi	a0,a0,-582 # 80008610 <syscalls+0x158>
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	cf2080e7          	jalr	-782(ra) # 80000550 <panic>

0000000080003866 <iinit>:
{
    80003866:	7179                	addi	sp,sp,-48
    80003868:	f406                	sd	ra,40(sp)
    8000386a:	f022                	sd	s0,32(sp)
    8000386c:	ec26                	sd	s1,24(sp)
    8000386e:	e84a                	sd	s2,16(sp)
    80003870:	e44e                	sd	s3,8(sp)
    80003872:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003874:	00005597          	auipc	a1,0x5
    80003878:	db458593          	addi	a1,a1,-588 # 80008628 <syscalls+0x170>
    8000387c:	00027517          	auipc	a0,0x27
    80003880:	b7450513          	addi	a0,a0,-1164 # 8002a3f0 <icache>
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	626080e7          	jalr	1574(ra) # 80000eaa <initlock>
  for(i = 0; i < NINODE; i++) {
    8000388c:	00027497          	auipc	s1,0x27
    80003890:	b9448493          	addi	s1,s1,-1132 # 8002a420 <icache+0x30>
    80003894:	00028997          	auipc	s3,0x28
    80003898:	7ac98993          	addi	s3,s3,1964 # 8002c040 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000389c:	00005917          	auipc	s2,0x5
    800038a0:	d9490913          	addi	s2,s2,-620 # 80008630 <syscalls+0x178>
    800038a4:	85ca                	mv	a1,s2
    800038a6:	8526                	mv	a0,s1
    800038a8:	00001097          	auipc	ra,0x1
    800038ac:	e4c080e7          	jalr	-436(ra) # 800046f4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800038b0:	09048493          	addi	s1,s1,144
    800038b4:	ff3498e3          	bne	s1,s3,800038a4 <iinit+0x3e>
}
    800038b8:	70a2                	ld	ra,40(sp)
    800038ba:	7402                	ld	s0,32(sp)
    800038bc:	64e2                	ld	s1,24(sp)
    800038be:	6942                	ld	s2,16(sp)
    800038c0:	69a2                	ld	s3,8(sp)
    800038c2:	6145                	addi	sp,sp,48
    800038c4:	8082                	ret

00000000800038c6 <ialloc>:
{
    800038c6:	715d                	addi	sp,sp,-80
    800038c8:	e486                	sd	ra,72(sp)
    800038ca:	e0a2                	sd	s0,64(sp)
    800038cc:	fc26                	sd	s1,56(sp)
    800038ce:	f84a                	sd	s2,48(sp)
    800038d0:	f44e                	sd	s3,40(sp)
    800038d2:	f052                	sd	s4,32(sp)
    800038d4:	ec56                	sd	s5,24(sp)
    800038d6:	e85a                	sd	s6,16(sp)
    800038d8:	e45e                	sd	s7,8(sp)
    800038da:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800038dc:	00027717          	auipc	a4,0x27
    800038e0:	b0072703          	lw	a4,-1280(a4) # 8002a3dc <sb+0xc>
    800038e4:	4785                	li	a5,1
    800038e6:	04e7fa63          	bgeu	a5,a4,8000393a <ialloc+0x74>
    800038ea:	8aaa                	mv	s5,a0
    800038ec:	8bae                	mv	s7,a1
    800038ee:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038f0:	00027a17          	auipc	s4,0x27
    800038f4:	ae0a0a13          	addi	s4,s4,-1312 # 8002a3d0 <sb>
    800038f8:	00048b1b          	sext.w	s6,s1
    800038fc:	0044d593          	srli	a1,s1,0x4
    80003900:	018a2783          	lw	a5,24(s4)
    80003904:	9dbd                	addw	a1,a1,a5
    80003906:	8556                	mv	a0,s5
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	8b0080e7          	jalr	-1872(ra) # 800031b8 <bread>
    80003910:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003912:	06050993          	addi	s3,a0,96
    80003916:	00f4f793          	andi	a5,s1,15
    8000391a:	079a                	slli	a5,a5,0x6
    8000391c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000391e:	00099783          	lh	a5,0(s3)
    80003922:	c785                	beqz	a5,8000394a <ialloc+0x84>
    brelse(bp);
    80003924:	00000097          	auipc	ra,0x0
    80003928:	a52080e7          	jalr	-1454(ra) # 80003376 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000392c:	0485                	addi	s1,s1,1
    8000392e:	00ca2703          	lw	a4,12(s4)
    80003932:	0004879b          	sext.w	a5,s1
    80003936:	fce7e1e3          	bltu	a5,a4,800038f8 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000393a:	00005517          	auipc	a0,0x5
    8000393e:	cfe50513          	addi	a0,a0,-770 # 80008638 <syscalls+0x180>
    80003942:	ffffd097          	auipc	ra,0xffffd
    80003946:	c0e080e7          	jalr	-1010(ra) # 80000550 <panic>
      memset(dip, 0, sizeof(*dip));
    8000394a:	04000613          	li	a2,64
    8000394e:	4581                	li	a1,0
    80003950:	854e                	mv	a0,s3
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	7bc080e7          	jalr	1980(ra) # 8000110e <memset>
      dip->type = type;
    8000395a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000395e:	854a                	mv	a0,s2
    80003960:	00001097          	auipc	ra,0x1
    80003964:	ca6080e7          	jalr	-858(ra) # 80004606 <log_write>
      brelse(bp);
    80003968:	854a                	mv	a0,s2
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	a0c080e7          	jalr	-1524(ra) # 80003376 <brelse>
      return iget(dev, inum);
    80003972:	85da                	mv	a1,s6
    80003974:	8556                	mv	a0,s5
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	db4080e7          	jalr	-588(ra) # 8000372a <iget>
}
    8000397e:	60a6                	ld	ra,72(sp)
    80003980:	6406                	ld	s0,64(sp)
    80003982:	74e2                	ld	s1,56(sp)
    80003984:	7942                	ld	s2,48(sp)
    80003986:	79a2                	ld	s3,40(sp)
    80003988:	7a02                	ld	s4,32(sp)
    8000398a:	6ae2                	ld	s5,24(sp)
    8000398c:	6b42                	ld	s6,16(sp)
    8000398e:	6ba2                	ld	s7,8(sp)
    80003990:	6161                	addi	sp,sp,80
    80003992:	8082                	ret

0000000080003994 <iupdate>:
{
    80003994:	1101                	addi	sp,sp,-32
    80003996:	ec06                	sd	ra,24(sp)
    80003998:	e822                	sd	s0,16(sp)
    8000399a:	e426                	sd	s1,8(sp)
    8000399c:	e04a                	sd	s2,0(sp)
    8000399e:	1000                	addi	s0,sp,32
    800039a0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039a2:	415c                	lw	a5,4(a0)
    800039a4:	0047d79b          	srliw	a5,a5,0x4
    800039a8:	00027597          	auipc	a1,0x27
    800039ac:	a405a583          	lw	a1,-1472(a1) # 8002a3e8 <sb+0x18>
    800039b0:	9dbd                	addw	a1,a1,a5
    800039b2:	4108                	lw	a0,0(a0)
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	804080e7          	jalr	-2044(ra) # 800031b8 <bread>
    800039bc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039be:	06050793          	addi	a5,a0,96
    800039c2:	40c8                	lw	a0,4(s1)
    800039c4:	893d                	andi	a0,a0,15
    800039c6:	051a                	slli	a0,a0,0x6
    800039c8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800039ca:	04c49703          	lh	a4,76(s1)
    800039ce:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800039d2:	04e49703          	lh	a4,78(s1)
    800039d6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800039da:	05049703          	lh	a4,80(s1)
    800039de:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800039e2:	05249703          	lh	a4,82(s1)
    800039e6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800039ea:	48f8                	lw	a4,84(s1)
    800039ec:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039ee:	03400613          	li	a2,52
    800039f2:	05848593          	addi	a1,s1,88
    800039f6:	0531                	addi	a0,a0,12
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	776080e7          	jalr	1910(ra) # 8000116e <memmove>
  log_write(bp);
    80003a00:	854a                	mv	a0,s2
    80003a02:	00001097          	auipc	ra,0x1
    80003a06:	c04080e7          	jalr	-1020(ra) # 80004606 <log_write>
  brelse(bp);
    80003a0a:	854a                	mv	a0,s2
    80003a0c:	00000097          	auipc	ra,0x0
    80003a10:	96a080e7          	jalr	-1686(ra) # 80003376 <brelse>
}
    80003a14:	60e2                	ld	ra,24(sp)
    80003a16:	6442                	ld	s0,16(sp)
    80003a18:	64a2                	ld	s1,8(sp)
    80003a1a:	6902                	ld	s2,0(sp)
    80003a1c:	6105                	addi	sp,sp,32
    80003a1e:	8082                	ret

0000000080003a20 <idup>:
{
    80003a20:	1101                	addi	sp,sp,-32
    80003a22:	ec06                	sd	ra,24(sp)
    80003a24:	e822                	sd	s0,16(sp)
    80003a26:	e426                	sd	s1,8(sp)
    80003a28:	1000                	addi	s0,sp,32
    80003a2a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a2c:	00027517          	auipc	a0,0x27
    80003a30:	9c450513          	addi	a0,a0,-1596 # 8002a3f0 <icache>
    80003a34:	ffffd097          	auipc	ra,0xffffd
    80003a38:	2fa080e7          	jalr	762(ra) # 80000d2e <acquire>
  ip->ref++;
    80003a3c:	449c                	lw	a5,8(s1)
    80003a3e:	2785                	addiw	a5,a5,1
    80003a40:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a42:	00027517          	auipc	a0,0x27
    80003a46:	9ae50513          	addi	a0,a0,-1618 # 8002a3f0 <icache>
    80003a4a:	ffffd097          	auipc	ra,0xffffd
    80003a4e:	3b4080e7          	jalr	948(ra) # 80000dfe <release>
}
    80003a52:	8526                	mv	a0,s1
    80003a54:	60e2                	ld	ra,24(sp)
    80003a56:	6442                	ld	s0,16(sp)
    80003a58:	64a2                	ld	s1,8(sp)
    80003a5a:	6105                	addi	sp,sp,32
    80003a5c:	8082                	ret

0000000080003a5e <ilock>:
{
    80003a5e:	1101                	addi	sp,sp,-32
    80003a60:	ec06                	sd	ra,24(sp)
    80003a62:	e822                	sd	s0,16(sp)
    80003a64:	e426                	sd	s1,8(sp)
    80003a66:	e04a                	sd	s2,0(sp)
    80003a68:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a6a:	c115                	beqz	a0,80003a8e <ilock+0x30>
    80003a6c:	84aa                	mv	s1,a0
    80003a6e:	451c                	lw	a5,8(a0)
    80003a70:	00f05f63          	blez	a5,80003a8e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a74:	0541                	addi	a0,a0,16
    80003a76:	00001097          	auipc	ra,0x1
    80003a7a:	cb8080e7          	jalr	-840(ra) # 8000472e <acquiresleep>
  if(ip->valid == 0){
    80003a7e:	44bc                	lw	a5,72(s1)
    80003a80:	cf99                	beqz	a5,80003a9e <ilock+0x40>
}
    80003a82:	60e2                	ld	ra,24(sp)
    80003a84:	6442                	ld	s0,16(sp)
    80003a86:	64a2                	ld	s1,8(sp)
    80003a88:	6902                	ld	s2,0(sp)
    80003a8a:	6105                	addi	sp,sp,32
    80003a8c:	8082                	ret
    panic("ilock");
    80003a8e:	00005517          	auipc	a0,0x5
    80003a92:	bc250513          	addi	a0,a0,-1086 # 80008650 <syscalls+0x198>
    80003a96:	ffffd097          	auipc	ra,0xffffd
    80003a9a:	aba080e7          	jalr	-1350(ra) # 80000550 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a9e:	40dc                	lw	a5,4(s1)
    80003aa0:	0047d79b          	srliw	a5,a5,0x4
    80003aa4:	00027597          	auipc	a1,0x27
    80003aa8:	9445a583          	lw	a1,-1724(a1) # 8002a3e8 <sb+0x18>
    80003aac:	9dbd                	addw	a1,a1,a5
    80003aae:	4088                	lw	a0,0(s1)
    80003ab0:	fffff097          	auipc	ra,0xfffff
    80003ab4:	708080e7          	jalr	1800(ra) # 800031b8 <bread>
    80003ab8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003aba:	06050593          	addi	a1,a0,96
    80003abe:	40dc                	lw	a5,4(s1)
    80003ac0:	8bbd                	andi	a5,a5,15
    80003ac2:	079a                	slli	a5,a5,0x6
    80003ac4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ac6:	00059783          	lh	a5,0(a1)
    80003aca:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    80003ace:	00259783          	lh	a5,2(a1)
    80003ad2:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    80003ad6:	00459783          	lh	a5,4(a1)
    80003ada:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    80003ade:	00659783          	lh	a5,6(a1)
    80003ae2:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    80003ae6:	459c                	lw	a5,8(a1)
    80003ae8:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003aea:	03400613          	li	a2,52
    80003aee:	05b1                	addi	a1,a1,12
    80003af0:	05848513          	addi	a0,s1,88
    80003af4:	ffffd097          	auipc	ra,0xffffd
    80003af8:	67a080e7          	jalr	1658(ra) # 8000116e <memmove>
    brelse(bp);
    80003afc:	854a                	mv	a0,s2
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	878080e7          	jalr	-1928(ra) # 80003376 <brelse>
    ip->valid = 1;
    80003b06:	4785                	li	a5,1
    80003b08:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    80003b0a:	04c49783          	lh	a5,76(s1)
    80003b0e:	fbb5                	bnez	a5,80003a82 <ilock+0x24>
      panic("ilock: no type");
    80003b10:	00005517          	auipc	a0,0x5
    80003b14:	b4850513          	addi	a0,a0,-1208 # 80008658 <syscalls+0x1a0>
    80003b18:	ffffd097          	auipc	ra,0xffffd
    80003b1c:	a38080e7          	jalr	-1480(ra) # 80000550 <panic>

0000000080003b20 <iunlock>:
{
    80003b20:	1101                	addi	sp,sp,-32
    80003b22:	ec06                	sd	ra,24(sp)
    80003b24:	e822                	sd	s0,16(sp)
    80003b26:	e426                	sd	s1,8(sp)
    80003b28:	e04a                	sd	s2,0(sp)
    80003b2a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b2c:	c905                	beqz	a0,80003b5c <iunlock+0x3c>
    80003b2e:	84aa                	mv	s1,a0
    80003b30:	01050913          	addi	s2,a0,16
    80003b34:	854a                	mv	a0,s2
    80003b36:	00001097          	auipc	ra,0x1
    80003b3a:	c92080e7          	jalr	-878(ra) # 800047c8 <holdingsleep>
    80003b3e:	cd19                	beqz	a0,80003b5c <iunlock+0x3c>
    80003b40:	449c                	lw	a5,8(s1)
    80003b42:	00f05d63          	blez	a5,80003b5c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b46:	854a                	mv	a0,s2
    80003b48:	00001097          	auipc	ra,0x1
    80003b4c:	c3c080e7          	jalr	-964(ra) # 80004784 <releasesleep>
}
    80003b50:	60e2                	ld	ra,24(sp)
    80003b52:	6442                	ld	s0,16(sp)
    80003b54:	64a2                	ld	s1,8(sp)
    80003b56:	6902                	ld	s2,0(sp)
    80003b58:	6105                	addi	sp,sp,32
    80003b5a:	8082                	ret
    panic("iunlock");
    80003b5c:	00005517          	auipc	a0,0x5
    80003b60:	b0c50513          	addi	a0,a0,-1268 # 80008668 <syscalls+0x1b0>
    80003b64:	ffffd097          	auipc	ra,0xffffd
    80003b68:	9ec080e7          	jalr	-1556(ra) # 80000550 <panic>

0000000080003b6c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b6c:	7179                	addi	sp,sp,-48
    80003b6e:	f406                	sd	ra,40(sp)
    80003b70:	f022                	sd	s0,32(sp)
    80003b72:	ec26                	sd	s1,24(sp)
    80003b74:	e84a                	sd	s2,16(sp)
    80003b76:	e44e                	sd	s3,8(sp)
    80003b78:	e052                	sd	s4,0(sp)
    80003b7a:	1800                	addi	s0,sp,48
    80003b7c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b7e:	05850493          	addi	s1,a0,88
    80003b82:	08850913          	addi	s2,a0,136
    80003b86:	a021                	j	80003b8e <itrunc+0x22>
    80003b88:	0491                	addi	s1,s1,4
    80003b8a:	01248d63          	beq	s1,s2,80003ba4 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b8e:	408c                	lw	a1,0(s1)
    80003b90:	dde5                	beqz	a1,80003b88 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b92:	0009a503          	lw	a0,0(s3)
    80003b96:	00000097          	auipc	ra,0x0
    80003b9a:	90c080e7          	jalr	-1780(ra) # 800034a2 <bfree>
      ip->addrs[i] = 0;
    80003b9e:	0004a023          	sw	zero,0(s1)
    80003ba2:	b7dd                	j	80003b88 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ba4:	0889a583          	lw	a1,136(s3)
    80003ba8:	e185                	bnez	a1,80003bc8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003baa:	0409aa23          	sw	zero,84(s3)
  iupdate(ip);
    80003bae:	854e                	mv	a0,s3
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	de4080e7          	jalr	-540(ra) # 80003994 <iupdate>
}
    80003bb8:	70a2                	ld	ra,40(sp)
    80003bba:	7402                	ld	s0,32(sp)
    80003bbc:	64e2                	ld	s1,24(sp)
    80003bbe:	6942                	ld	s2,16(sp)
    80003bc0:	69a2                	ld	s3,8(sp)
    80003bc2:	6a02                	ld	s4,0(sp)
    80003bc4:	6145                	addi	sp,sp,48
    80003bc6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003bc8:	0009a503          	lw	a0,0(s3)
    80003bcc:	fffff097          	auipc	ra,0xfffff
    80003bd0:	5ec080e7          	jalr	1516(ra) # 800031b8 <bread>
    80003bd4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003bd6:	06050493          	addi	s1,a0,96
    80003bda:	46050913          	addi	s2,a0,1120
    80003bde:	a811                	j	80003bf2 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003be0:	0009a503          	lw	a0,0(s3)
    80003be4:	00000097          	auipc	ra,0x0
    80003be8:	8be080e7          	jalr	-1858(ra) # 800034a2 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003bec:	0491                	addi	s1,s1,4
    80003bee:	01248563          	beq	s1,s2,80003bf8 <itrunc+0x8c>
      if(a[j])
    80003bf2:	408c                	lw	a1,0(s1)
    80003bf4:	dde5                	beqz	a1,80003bec <itrunc+0x80>
    80003bf6:	b7ed                	j	80003be0 <itrunc+0x74>
    brelse(bp);
    80003bf8:	8552                	mv	a0,s4
    80003bfa:	fffff097          	auipc	ra,0xfffff
    80003bfe:	77c080e7          	jalr	1916(ra) # 80003376 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c02:	0889a583          	lw	a1,136(s3)
    80003c06:	0009a503          	lw	a0,0(s3)
    80003c0a:	00000097          	auipc	ra,0x0
    80003c0e:	898080e7          	jalr	-1896(ra) # 800034a2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c12:	0809a423          	sw	zero,136(s3)
    80003c16:	bf51                	j	80003baa <itrunc+0x3e>

0000000080003c18 <iput>:
{
    80003c18:	1101                	addi	sp,sp,-32
    80003c1a:	ec06                	sd	ra,24(sp)
    80003c1c:	e822                	sd	s0,16(sp)
    80003c1e:	e426                	sd	s1,8(sp)
    80003c20:	e04a                	sd	s2,0(sp)
    80003c22:	1000                	addi	s0,sp,32
    80003c24:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003c26:	00026517          	auipc	a0,0x26
    80003c2a:	7ca50513          	addi	a0,a0,1994 # 8002a3f0 <icache>
    80003c2e:	ffffd097          	auipc	ra,0xffffd
    80003c32:	100080e7          	jalr	256(ra) # 80000d2e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c36:	4498                	lw	a4,8(s1)
    80003c38:	4785                	li	a5,1
    80003c3a:	02f70363          	beq	a4,a5,80003c60 <iput+0x48>
  ip->ref--;
    80003c3e:	449c                	lw	a5,8(s1)
    80003c40:	37fd                	addiw	a5,a5,-1
    80003c42:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003c44:	00026517          	auipc	a0,0x26
    80003c48:	7ac50513          	addi	a0,a0,1964 # 8002a3f0 <icache>
    80003c4c:	ffffd097          	auipc	ra,0xffffd
    80003c50:	1b2080e7          	jalr	434(ra) # 80000dfe <release>
}
    80003c54:	60e2                	ld	ra,24(sp)
    80003c56:	6442                	ld	s0,16(sp)
    80003c58:	64a2                	ld	s1,8(sp)
    80003c5a:	6902                	ld	s2,0(sp)
    80003c5c:	6105                	addi	sp,sp,32
    80003c5e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c60:	44bc                	lw	a5,72(s1)
    80003c62:	dff1                	beqz	a5,80003c3e <iput+0x26>
    80003c64:	05249783          	lh	a5,82(s1)
    80003c68:	fbf9                	bnez	a5,80003c3e <iput+0x26>
    acquiresleep(&ip->lock);
    80003c6a:	01048913          	addi	s2,s1,16
    80003c6e:	854a                	mv	a0,s2
    80003c70:	00001097          	auipc	ra,0x1
    80003c74:	abe080e7          	jalr	-1346(ra) # 8000472e <acquiresleep>
    release(&icache.lock);
    80003c78:	00026517          	auipc	a0,0x26
    80003c7c:	77850513          	addi	a0,a0,1912 # 8002a3f0 <icache>
    80003c80:	ffffd097          	auipc	ra,0xffffd
    80003c84:	17e080e7          	jalr	382(ra) # 80000dfe <release>
    itrunc(ip);
    80003c88:	8526                	mv	a0,s1
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	ee2080e7          	jalr	-286(ra) # 80003b6c <itrunc>
    ip->type = 0;
    80003c92:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    80003c96:	8526                	mv	a0,s1
    80003c98:	00000097          	auipc	ra,0x0
    80003c9c:	cfc080e7          	jalr	-772(ra) # 80003994 <iupdate>
    ip->valid = 0;
    80003ca0:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003ca4:	854a                	mv	a0,s2
    80003ca6:	00001097          	auipc	ra,0x1
    80003caa:	ade080e7          	jalr	-1314(ra) # 80004784 <releasesleep>
    acquire(&icache.lock);
    80003cae:	00026517          	auipc	a0,0x26
    80003cb2:	74250513          	addi	a0,a0,1858 # 8002a3f0 <icache>
    80003cb6:	ffffd097          	auipc	ra,0xffffd
    80003cba:	078080e7          	jalr	120(ra) # 80000d2e <acquire>
    80003cbe:	b741                	j	80003c3e <iput+0x26>

0000000080003cc0 <iunlockput>:
{
    80003cc0:	1101                	addi	sp,sp,-32
    80003cc2:	ec06                	sd	ra,24(sp)
    80003cc4:	e822                	sd	s0,16(sp)
    80003cc6:	e426                	sd	s1,8(sp)
    80003cc8:	1000                	addi	s0,sp,32
    80003cca:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	e54080e7          	jalr	-428(ra) # 80003b20 <iunlock>
  iput(ip);
    80003cd4:	8526                	mv	a0,s1
    80003cd6:	00000097          	auipc	ra,0x0
    80003cda:	f42080e7          	jalr	-190(ra) # 80003c18 <iput>
}
    80003cde:	60e2                	ld	ra,24(sp)
    80003ce0:	6442                	ld	s0,16(sp)
    80003ce2:	64a2                	ld	s1,8(sp)
    80003ce4:	6105                	addi	sp,sp,32
    80003ce6:	8082                	ret

0000000080003ce8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ce8:	1141                	addi	sp,sp,-16
    80003cea:	e422                	sd	s0,8(sp)
    80003cec:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003cee:	411c                	lw	a5,0(a0)
    80003cf0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003cf2:	415c                	lw	a5,4(a0)
    80003cf4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003cf6:	04c51783          	lh	a5,76(a0)
    80003cfa:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003cfe:	05251783          	lh	a5,82(a0)
    80003d02:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d06:	05456783          	lwu	a5,84(a0)
    80003d0a:	e99c                	sd	a5,16(a1)
}
    80003d0c:	6422                	ld	s0,8(sp)
    80003d0e:	0141                	addi	sp,sp,16
    80003d10:	8082                	ret

0000000080003d12 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d12:	497c                	lw	a5,84(a0)
    80003d14:	0ed7e963          	bltu	a5,a3,80003e06 <readi+0xf4>
{
    80003d18:	7159                	addi	sp,sp,-112
    80003d1a:	f486                	sd	ra,104(sp)
    80003d1c:	f0a2                	sd	s0,96(sp)
    80003d1e:	eca6                	sd	s1,88(sp)
    80003d20:	e8ca                	sd	s2,80(sp)
    80003d22:	e4ce                	sd	s3,72(sp)
    80003d24:	e0d2                	sd	s4,64(sp)
    80003d26:	fc56                	sd	s5,56(sp)
    80003d28:	f85a                	sd	s6,48(sp)
    80003d2a:	f45e                	sd	s7,40(sp)
    80003d2c:	f062                	sd	s8,32(sp)
    80003d2e:	ec66                	sd	s9,24(sp)
    80003d30:	e86a                	sd	s10,16(sp)
    80003d32:	e46e                	sd	s11,8(sp)
    80003d34:	1880                	addi	s0,sp,112
    80003d36:	8baa                	mv	s7,a0
    80003d38:	8c2e                	mv	s8,a1
    80003d3a:	8ab2                	mv	s5,a2
    80003d3c:	84b6                	mv	s1,a3
    80003d3e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d40:	9f35                	addw	a4,a4,a3
    return 0;
    80003d42:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d44:	0ad76063          	bltu	a4,a3,80003de4 <readi+0xd2>
  if(off + n > ip->size)
    80003d48:	00e7f463          	bgeu	a5,a4,80003d50 <readi+0x3e>
    n = ip->size - off;
    80003d4c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d50:	0a0b0963          	beqz	s6,80003e02 <readi+0xf0>
    80003d54:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d56:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d5a:	5cfd                	li	s9,-1
    80003d5c:	a82d                	j	80003d96 <readi+0x84>
    80003d5e:	020a1d93          	slli	s11,s4,0x20
    80003d62:	020ddd93          	srli	s11,s11,0x20
    80003d66:	06090613          	addi	a2,s2,96
    80003d6a:	86ee                	mv	a3,s11
    80003d6c:	963a                	add	a2,a2,a4
    80003d6e:	85d6                	mv	a1,s5
    80003d70:	8562                	mv	a0,s8
    80003d72:	fffff097          	auipc	ra,0xfffff
    80003d76:	a76080e7          	jalr	-1418(ra) # 800027e8 <either_copyout>
    80003d7a:	05950d63          	beq	a0,s9,80003dd4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d7e:	854a                	mv	a0,s2
    80003d80:	fffff097          	auipc	ra,0xfffff
    80003d84:	5f6080e7          	jalr	1526(ra) # 80003376 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d88:	013a09bb          	addw	s3,s4,s3
    80003d8c:	009a04bb          	addw	s1,s4,s1
    80003d90:	9aee                	add	s5,s5,s11
    80003d92:	0569f763          	bgeu	s3,s6,80003de0 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d96:	000ba903          	lw	s2,0(s7)
    80003d9a:	00a4d59b          	srliw	a1,s1,0xa
    80003d9e:	855e                	mv	a0,s7
    80003da0:	00000097          	auipc	ra,0x0
    80003da4:	8b0080e7          	jalr	-1872(ra) # 80003650 <bmap>
    80003da8:	0005059b          	sext.w	a1,a0
    80003dac:	854a                	mv	a0,s2
    80003dae:	fffff097          	auipc	ra,0xfffff
    80003db2:	40a080e7          	jalr	1034(ra) # 800031b8 <bread>
    80003db6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003db8:	3ff4f713          	andi	a4,s1,1023
    80003dbc:	40ed07bb          	subw	a5,s10,a4
    80003dc0:	413b06bb          	subw	a3,s6,s3
    80003dc4:	8a3e                	mv	s4,a5
    80003dc6:	2781                	sext.w	a5,a5
    80003dc8:	0006861b          	sext.w	a2,a3
    80003dcc:	f8f679e3          	bgeu	a2,a5,80003d5e <readi+0x4c>
    80003dd0:	8a36                	mv	s4,a3
    80003dd2:	b771                	j	80003d5e <readi+0x4c>
      brelse(bp);
    80003dd4:	854a                	mv	a0,s2
    80003dd6:	fffff097          	auipc	ra,0xfffff
    80003dda:	5a0080e7          	jalr	1440(ra) # 80003376 <brelse>
      tot = -1;
    80003dde:	59fd                	li	s3,-1
  }
  return tot;
    80003de0:	0009851b          	sext.w	a0,s3
}
    80003de4:	70a6                	ld	ra,104(sp)
    80003de6:	7406                	ld	s0,96(sp)
    80003de8:	64e6                	ld	s1,88(sp)
    80003dea:	6946                	ld	s2,80(sp)
    80003dec:	69a6                	ld	s3,72(sp)
    80003dee:	6a06                	ld	s4,64(sp)
    80003df0:	7ae2                	ld	s5,56(sp)
    80003df2:	7b42                	ld	s6,48(sp)
    80003df4:	7ba2                	ld	s7,40(sp)
    80003df6:	7c02                	ld	s8,32(sp)
    80003df8:	6ce2                	ld	s9,24(sp)
    80003dfa:	6d42                	ld	s10,16(sp)
    80003dfc:	6da2                	ld	s11,8(sp)
    80003dfe:	6165                	addi	sp,sp,112
    80003e00:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e02:	89da                	mv	s3,s6
    80003e04:	bff1                	j	80003de0 <readi+0xce>
    return 0;
    80003e06:	4501                	li	a0,0
}
    80003e08:	8082                	ret

0000000080003e0a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e0a:	497c                	lw	a5,84(a0)
    80003e0c:	10d7e763          	bltu	a5,a3,80003f1a <writei+0x110>
{
    80003e10:	7159                	addi	sp,sp,-112
    80003e12:	f486                	sd	ra,104(sp)
    80003e14:	f0a2                	sd	s0,96(sp)
    80003e16:	eca6                	sd	s1,88(sp)
    80003e18:	e8ca                	sd	s2,80(sp)
    80003e1a:	e4ce                	sd	s3,72(sp)
    80003e1c:	e0d2                	sd	s4,64(sp)
    80003e1e:	fc56                	sd	s5,56(sp)
    80003e20:	f85a                	sd	s6,48(sp)
    80003e22:	f45e                	sd	s7,40(sp)
    80003e24:	f062                	sd	s8,32(sp)
    80003e26:	ec66                	sd	s9,24(sp)
    80003e28:	e86a                	sd	s10,16(sp)
    80003e2a:	e46e                	sd	s11,8(sp)
    80003e2c:	1880                	addi	s0,sp,112
    80003e2e:	8baa                	mv	s7,a0
    80003e30:	8c2e                	mv	s8,a1
    80003e32:	8ab2                	mv	s5,a2
    80003e34:	8936                	mv	s2,a3
    80003e36:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e38:	00e687bb          	addw	a5,a3,a4
    80003e3c:	0ed7e163          	bltu	a5,a3,80003f1e <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e40:	00043737          	lui	a4,0x43
    80003e44:	0cf76f63          	bltu	a4,a5,80003f22 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e48:	0a0b0863          	beqz	s6,80003ef8 <writei+0xee>
    80003e4c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e4e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e52:	5cfd                	li	s9,-1
    80003e54:	a091                	j	80003e98 <writei+0x8e>
    80003e56:	02099d93          	slli	s11,s3,0x20
    80003e5a:	020ddd93          	srli	s11,s11,0x20
    80003e5e:	06048513          	addi	a0,s1,96
    80003e62:	86ee                	mv	a3,s11
    80003e64:	8656                	mv	a2,s5
    80003e66:	85e2                	mv	a1,s8
    80003e68:	953a                	add	a0,a0,a4
    80003e6a:	fffff097          	auipc	ra,0xfffff
    80003e6e:	9d4080e7          	jalr	-1580(ra) # 8000283e <either_copyin>
    80003e72:	07950263          	beq	a0,s9,80003ed6 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003e76:	8526                	mv	a0,s1
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	78e080e7          	jalr	1934(ra) # 80004606 <log_write>
    brelse(bp);
    80003e80:	8526                	mv	a0,s1
    80003e82:	fffff097          	auipc	ra,0xfffff
    80003e86:	4f4080e7          	jalr	1268(ra) # 80003376 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e8a:	01498a3b          	addw	s4,s3,s4
    80003e8e:	0129893b          	addw	s2,s3,s2
    80003e92:	9aee                	add	s5,s5,s11
    80003e94:	056a7763          	bgeu	s4,s6,80003ee2 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e98:	000ba483          	lw	s1,0(s7)
    80003e9c:	00a9559b          	srliw	a1,s2,0xa
    80003ea0:	855e                	mv	a0,s7
    80003ea2:	fffff097          	auipc	ra,0xfffff
    80003ea6:	7ae080e7          	jalr	1966(ra) # 80003650 <bmap>
    80003eaa:	0005059b          	sext.w	a1,a0
    80003eae:	8526                	mv	a0,s1
    80003eb0:	fffff097          	auipc	ra,0xfffff
    80003eb4:	308080e7          	jalr	776(ra) # 800031b8 <bread>
    80003eb8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eba:	3ff97713          	andi	a4,s2,1023
    80003ebe:	40ed07bb          	subw	a5,s10,a4
    80003ec2:	414b06bb          	subw	a3,s6,s4
    80003ec6:	89be                	mv	s3,a5
    80003ec8:	2781                	sext.w	a5,a5
    80003eca:	0006861b          	sext.w	a2,a3
    80003ece:	f8f674e3          	bgeu	a2,a5,80003e56 <writei+0x4c>
    80003ed2:	89b6                	mv	s3,a3
    80003ed4:	b749                	j	80003e56 <writei+0x4c>
      brelse(bp);
    80003ed6:	8526                	mv	a0,s1
    80003ed8:	fffff097          	auipc	ra,0xfffff
    80003edc:	49e080e7          	jalr	1182(ra) # 80003376 <brelse>
      n = -1;
    80003ee0:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003ee2:	054ba783          	lw	a5,84(s7)
    80003ee6:	0127f463          	bgeu	a5,s2,80003eee <writei+0xe4>
      ip->size = off;
    80003eea:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003eee:	855e                	mv	a0,s7
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	aa4080e7          	jalr	-1372(ra) # 80003994 <iupdate>
  }

  return n;
    80003ef8:	000b051b          	sext.w	a0,s6
}
    80003efc:	70a6                	ld	ra,104(sp)
    80003efe:	7406                	ld	s0,96(sp)
    80003f00:	64e6                	ld	s1,88(sp)
    80003f02:	6946                	ld	s2,80(sp)
    80003f04:	69a6                	ld	s3,72(sp)
    80003f06:	6a06                	ld	s4,64(sp)
    80003f08:	7ae2                	ld	s5,56(sp)
    80003f0a:	7b42                	ld	s6,48(sp)
    80003f0c:	7ba2                	ld	s7,40(sp)
    80003f0e:	7c02                	ld	s8,32(sp)
    80003f10:	6ce2                	ld	s9,24(sp)
    80003f12:	6d42                	ld	s10,16(sp)
    80003f14:	6da2                	ld	s11,8(sp)
    80003f16:	6165                	addi	sp,sp,112
    80003f18:	8082                	ret
    return -1;
    80003f1a:	557d                	li	a0,-1
}
    80003f1c:	8082                	ret
    return -1;
    80003f1e:	557d                	li	a0,-1
    80003f20:	bff1                	j	80003efc <writei+0xf2>
    return -1;
    80003f22:	557d                	li	a0,-1
    80003f24:	bfe1                	j	80003efc <writei+0xf2>

0000000080003f26 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f26:	1141                	addi	sp,sp,-16
    80003f28:	e406                	sd	ra,8(sp)
    80003f2a:	e022                	sd	s0,0(sp)
    80003f2c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f2e:	4639                	li	a2,14
    80003f30:	ffffd097          	auipc	ra,0xffffd
    80003f34:	2ba080e7          	jalr	698(ra) # 800011ea <strncmp>
}
    80003f38:	60a2                	ld	ra,8(sp)
    80003f3a:	6402                	ld	s0,0(sp)
    80003f3c:	0141                	addi	sp,sp,16
    80003f3e:	8082                	ret

0000000080003f40 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f40:	7139                	addi	sp,sp,-64
    80003f42:	fc06                	sd	ra,56(sp)
    80003f44:	f822                	sd	s0,48(sp)
    80003f46:	f426                	sd	s1,40(sp)
    80003f48:	f04a                	sd	s2,32(sp)
    80003f4a:	ec4e                	sd	s3,24(sp)
    80003f4c:	e852                	sd	s4,16(sp)
    80003f4e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f50:	04c51703          	lh	a4,76(a0)
    80003f54:	4785                	li	a5,1
    80003f56:	00f71a63          	bne	a4,a5,80003f6a <dirlookup+0x2a>
    80003f5a:	892a                	mv	s2,a0
    80003f5c:	89ae                	mv	s3,a1
    80003f5e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f60:	497c                	lw	a5,84(a0)
    80003f62:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f64:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f66:	e79d                	bnez	a5,80003f94 <dirlookup+0x54>
    80003f68:	a8a5                	j	80003fe0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f6a:	00004517          	auipc	a0,0x4
    80003f6e:	70650513          	addi	a0,a0,1798 # 80008670 <syscalls+0x1b8>
    80003f72:	ffffc097          	auipc	ra,0xffffc
    80003f76:	5de080e7          	jalr	1502(ra) # 80000550 <panic>
      panic("dirlookup read");
    80003f7a:	00004517          	auipc	a0,0x4
    80003f7e:	70e50513          	addi	a0,a0,1806 # 80008688 <syscalls+0x1d0>
    80003f82:	ffffc097          	auipc	ra,0xffffc
    80003f86:	5ce080e7          	jalr	1486(ra) # 80000550 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f8a:	24c1                	addiw	s1,s1,16
    80003f8c:	05492783          	lw	a5,84(s2)
    80003f90:	04f4f763          	bgeu	s1,a5,80003fde <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f94:	4741                	li	a4,16
    80003f96:	86a6                	mv	a3,s1
    80003f98:	fc040613          	addi	a2,s0,-64
    80003f9c:	4581                	li	a1,0
    80003f9e:	854a                	mv	a0,s2
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	d72080e7          	jalr	-654(ra) # 80003d12 <readi>
    80003fa8:	47c1                	li	a5,16
    80003faa:	fcf518e3          	bne	a0,a5,80003f7a <dirlookup+0x3a>
    if(de.inum == 0)
    80003fae:	fc045783          	lhu	a5,-64(s0)
    80003fb2:	dfe1                	beqz	a5,80003f8a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003fb4:	fc240593          	addi	a1,s0,-62
    80003fb8:	854e                	mv	a0,s3
    80003fba:	00000097          	auipc	ra,0x0
    80003fbe:	f6c080e7          	jalr	-148(ra) # 80003f26 <namecmp>
    80003fc2:	f561                	bnez	a0,80003f8a <dirlookup+0x4a>
      if(poff)
    80003fc4:	000a0463          	beqz	s4,80003fcc <dirlookup+0x8c>
        *poff = off;
    80003fc8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fcc:	fc045583          	lhu	a1,-64(s0)
    80003fd0:	00092503          	lw	a0,0(s2)
    80003fd4:	fffff097          	auipc	ra,0xfffff
    80003fd8:	756080e7          	jalr	1878(ra) # 8000372a <iget>
    80003fdc:	a011                	j	80003fe0 <dirlookup+0xa0>
  return 0;
    80003fde:	4501                	li	a0,0
}
    80003fe0:	70e2                	ld	ra,56(sp)
    80003fe2:	7442                	ld	s0,48(sp)
    80003fe4:	74a2                	ld	s1,40(sp)
    80003fe6:	7902                	ld	s2,32(sp)
    80003fe8:	69e2                	ld	s3,24(sp)
    80003fea:	6a42                	ld	s4,16(sp)
    80003fec:	6121                	addi	sp,sp,64
    80003fee:	8082                	ret

0000000080003ff0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ff0:	711d                	addi	sp,sp,-96
    80003ff2:	ec86                	sd	ra,88(sp)
    80003ff4:	e8a2                	sd	s0,80(sp)
    80003ff6:	e4a6                	sd	s1,72(sp)
    80003ff8:	e0ca                	sd	s2,64(sp)
    80003ffa:	fc4e                	sd	s3,56(sp)
    80003ffc:	f852                	sd	s4,48(sp)
    80003ffe:	f456                	sd	s5,40(sp)
    80004000:	f05a                	sd	s6,32(sp)
    80004002:	ec5e                	sd	s7,24(sp)
    80004004:	e862                	sd	s8,16(sp)
    80004006:	e466                	sd	s9,8(sp)
    80004008:	1080                	addi	s0,sp,96
    8000400a:	84aa                	mv	s1,a0
    8000400c:	8b2e                	mv	s6,a1
    8000400e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004010:	00054703          	lbu	a4,0(a0)
    80004014:	02f00793          	li	a5,47
    80004018:	02f70363          	beq	a4,a5,8000403e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000401c:	ffffe097          	auipc	ra,0xffffe
    80004020:	d5a080e7          	jalr	-678(ra) # 80001d76 <myproc>
    80004024:	15853503          	ld	a0,344(a0)
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	9f8080e7          	jalr	-1544(ra) # 80003a20 <idup>
    80004030:	89aa                	mv	s3,a0
  while(*path == '/')
    80004032:	02f00913          	li	s2,47
  len = path - s;
    80004036:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004038:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000403a:	4c05                	li	s8,1
    8000403c:	a865                	j	800040f4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000403e:	4585                	li	a1,1
    80004040:	4505                	li	a0,1
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	6e8080e7          	jalr	1768(ra) # 8000372a <iget>
    8000404a:	89aa                	mv	s3,a0
    8000404c:	b7dd                	j	80004032 <namex+0x42>
      iunlockput(ip);
    8000404e:	854e                	mv	a0,s3
    80004050:	00000097          	auipc	ra,0x0
    80004054:	c70080e7          	jalr	-912(ra) # 80003cc0 <iunlockput>
      return 0;
    80004058:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000405a:	854e                	mv	a0,s3
    8000405c:	60e6                	ld	ra,88(sp)
    8000405e:	6446                	ld	s0,80(sp)
    80004060:	64a6                	ld	s1,72(sp)
    80004062:	6906                	ld	s2,64(sp)
    80004064:	79e2                	ld	s3,56(sp)
    80004066:	7a42                	ld	s4,48(sp)
    80004068:	7aa2                	ld	s5,40(sp)
    8000406a:	7b02                	ld	s6,32(sp)
    8000406c:	6be2                	ld	s7,24(sp)
    8000406e:	6c42                	ld	s8,16(sp)
    80004070:	6ca2                	ld	s9,8(sp)
    80004072:	6125                	addi	sp,sp,96
    80004074:	8082                	ret
      iunlock(ip);
    80004076:	854e                	mv	a0,s3
    80004078:	00000097          	auipc	ra,0x0
    8000407c:	aa8080e7          	jalr	-1368(ra) # 80003b20 <iunlock>
      return ip;
    80004080:	bfe9                	j	8000405a <namex+0x6a>
      iunlockput(ip);
    80004082:	854e                	mv	a0,s3
    80004084:	00000097          	auipc	ra,0x0
    80004088:	c3c080e7          	jalr	-964(ra) # 80003cc0 <iunlockput>
      return 0;
    8000408c:	89d2                	mv	s3,s4
    8000408e:	b7f1                	j	8000405a <namex+0x6a>
  len = path - s;
    80004090:	40b48633          	sub	a2,s1,a1
    80004094:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004098:	094cd463          	bge	s9,s4,80004120 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000409c:	4639                	li	a2,14
    8000409e:	8556                	mv	a0,s5
    800040a0:	ffffd097          	auipc	ra,0xffffd
    800040a4:	0ce080e7          	jalr	206(ra) # 8000116e <memmove>
  while(*path == '/')
    800040a8:	0004c783          	lbu	a5,0(s1)
    800040ac:	01279763          	bne	a5,s2,800040ba <namex+0xca>
    path++;
    800040b0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040b2:	0004c783          	lbu	a5,0(s1)
    800040b6:	ff278de3          	beq	a5,s2,800040b0 <namex+0xc0>
    ilock(ip);
    800040ba:	854e                	mv	a0,s3
    800040bc:	00000097          	auipc	ra,0x0
    800040c0:	9a2080e7          	jalr	-1630(ra) # 80003a5e <ilock>
    if(ip->type != T_DIR){
    800040c4:	04c99783          	lh	a5,76(s3)
    800040c8:	f98793e3          	bne	a5,s8,8000404e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800040cc:	000b0563          	beqz	s6,800040d6 <namex+0xe6>
    800040d0:	0004c783          	lbu	a5,0(s1)
    800040d4:	d3cd                	beqz	a5,80004076 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040d6:	865e                	mv	a2,s7
    800040d8:	85d6                	mv	a1,s5
    800040da:	854e                	mv	a0,s3
    800040dc:	00000097          	auipc	ra,0x0
    800040e0:	e64080e7          	jalr	-412(ra) # 80003f40 <dirlookup>
    800040e4:	8a2a                	mv	s4,a0
    800040e6:	dd51                	beqz	a0,80004082 <namex+0x92>
    iunlockput(ip);
    800040e8:	854e                	mv	a0,s3
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	bd6080e7          	jalr	-1066(ra) # 80003cc0 <iunlockput>
    ip = next;
    800040f2:	89d2                	mv	s3,s4
  while(*path == '/')
    800040f4:	0004c783          	lbu	a5,0(s1)
    800040f8:	05279763          	bne	a5,s2,80004146 <namex+0x156>
    path++;
    800040fc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040fe:	0004c783          	lbu	a5,0(s1)
    80004102:	ff278de3          	beq	a5,s2,800040fc <namex+0x10c>
  if(*path == 0)
    80004106:	c79d                	beqz	a5,80004134 <namex+0x144>
    path++;
    80004108:	85a6                	mv	a1,s1
  len = path - s;
    8000410a:	8a5e                	mv	s4,s7
    8000410c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000410e:	01278963          	beq	a5,s2,80004120 <namex+0x130>
    80004112:	dfbd                	beqz	a5,80004090 <namex+0xa0>
    path++;
    80004114:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004116:	0004c783          	lbu	a5,0(s1)
    8000411a:	ff279ce3          	bne	a5,s2,80004112 <namex+0x122>
    8000411e:	bf8d                	j	80004090 <namex+0xa0>
    memmove(name, s, len);
    80004120:	2601                	sext.w	a2,a2
    80004122:	8556                	mv	a0,s5
    80004124:	ffffd097          	auipc	ra,0xffffd
    80004128:	04a080e7          	jalr	74(ra) # 8000116e <memmove>
    name[len] = 0;
    8000412c:	9a56                	add	s4,s4,s5
    8000412e:	000a0023          	sb	zero,0(s4)
    80004132:	bf9d                	j	800040a8 <namex+0xb8>
  if(nameiparent){
    80004134:	f20b03e3          	beqz	s6,8000405a <namex+0x6a>
    iput(ip);
    80004138:	854e                	mv	a0,s3
    8000413a:	00000097          	auipc	ra,0x0
    8000413e:	ade080e7          	jalr	-1314(ra) # 80003c18 <iput>
    return 0;
    80004142:	4981                	li	s3,0
    80004144:	bf19                	j	8000405a <namex+0x6a>
  if(*path == 0)
    80004146:	d7fd                	beqz	a5,80004134 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004148:	0004c783          	lbu	a5,0(s1)
    8000414c:	85a6                	mv	a1,s1
    8000414e:	b7d1                	j	80004112 <namex+0x122>

0000000080004150 <dirlink>:
{
    80004150:	7139                	addi	sp,sp,-64
    80004152:	fc06                	sd	ra,56(sp)
    80004154:	f822                	sd	s0,48(sp)
    80004156:	f426                	sd	s1,40(sp)
    80004158:	f04a                	sd	s2,32(sp)
    8000415a:	ec4e                	sd	s3,24(sp)
    8000415c:	e852                	sd	s4,16(sp)
    8000415e:	0080                	addi	s0,sp,64
    80004160:	892a                	mv	s2,a0
    80004162:	8a2e                	mv	s4,a1
    80004164:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004166:	4601                	li	a2,0
    80004168:	00000097          	auipc	ra,0x0
    8000416c:	dd8080e7          	jalr	-552(ra) # 80003f40 <dirlookup>
    80004170:	e93d                	bnez	a0,800041e6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004172:	05492483          	lw	s1,84(s2)
    80004176:	c49d                	beqz	s1,800041a4 <dirlink+0x54>
    80004178:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000417a:	4741                	li	a4,16
    8000417c:	86a6                	mv	a3,s1
    8000417e:	fc040613          	addi	a2,s0,-64
    80004182:	4581                	li	a1,0
    80004184:	854a                	mv	a0,s2
    80004186:	00000097          	auipc	ra,0x0
    8000418a:	b8c080e7          	jalr	-1140(ra) # 80003d12 <readi>
    8000418e:	47c1                	li	a5,16
    80004190:	06f51163          	bne	a0,a5,800041f2 <dirlink+0xa2>
    if(de.inum == 0)
    80004194:	fc045783          	lhu	a5,-64(s0)
    80004198:	c791                	beqz	a5,800041a4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000419a:	24c1                	addiw	s1,s1,16
    8000419c:	05492783          	lw	a5,84(s2)
    800041a0:	fcf4ede3          	bltu	s1,a5,8000417a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800041a4:	4639                	li	a2,14
    800041a6:	85d2                	mv	a1,s4
    800041a8:	fc240513          	addi	a0,s0,-62
    800041ac:	ffffd097          	auipc	ra,0xffffd
    800041b0:	07a080e7          	jalr	122(ra) # 80001226 <strncpy>
  de.inum = inum;
    800041b4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041b8:	4741                	li	a4,16
    800041ba:	86a6                	mv	a3,s1
    800041bc:	fc040613          	addi	a2,s0,-64
    800041c0:	4581                	li	a1,0
    800041c2:	854a                	mv	a0,s2
    800041c4:	00000097          	auipc	ra,0x0
    800041c8:	c46080e7          	jalr	-954(ra) # 80003e0a <writei>
    800041cc:	872a                	mv	a4,a0
    800041ce:	47c1                	li	a5,16
  return 0;
    800041d0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041d2:	02f71863          	bne	a4,a5,80004202 <dirlink+0xb2>
}
    800041d6:	70e2                	ld	ra,56(sp)
    800041d8:	7442                	ld	s0,48(sp)
    800041da:	74a2                	ld	s1,40(sp)
    800041dc:	7902                	ld	s2,32(sp)
    800041de:	69e2                	ld	s3,24(sp)
    800041e0:	6a42                	ld	s4,16(sp)
    800041e2:	6121                	addi	sp,sp,64
    800041e4:	8082                	ret
    iput(ip);
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	a32080e7          	jalr	-1486(ra) # 80003c18 <iput>
    return -1;
    800041ee:	557d                	li	a0,-1
    800041f0:	b7dd                	j	800041d6 <dirlink+0x86>
      panic("dirlink read");
    800041f2:	00004517          	auipc	a0,0x4
    800041f6:	4a650513          	addi	a0,a0,1190 # 80008698 <syscalls+0x1e0>
    800041fa:	ffffc097          	auipc	ra,0xffffc
    800041fe:	356080e7          	jalr	854(ra) # 80000550 <panic>
    panic("dirlink");
    80004202:	00004517          	auipc	a0,0x4
    80004206:	5b650513          	addi	a0,a0,1462 # 800087b8 <syscalls+0x300>
    8000420a:	ffffc097          	auipc	ra,0xffffc
    8000420e:	346080e7          	jalr	838(ra) # 80000550 <panic>

0000000080004212 <namei>:

struct inode*
namei(char *path)
{
    80004212:	1101                	addi	sp,sp,-32
    80004214:	ec06                	sd	ra,24(sp)
    80004216:	e822                	sd	s0,16(sp)
    80004218:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000421a:	fe040613          	addi	a2,s0,-32
    8000421e:	4581                	li	a1,0
    80004220:	00000097          	auipc	ra,0x0
    80004224:	dd0080e7          	jalr	-560(ra) # 80003ff0 <namex>
}
    80004228:	60e2                	ld	ra,24(sp)
    8000422a:	6442                	ld	s0,16(sp)
    8000422c:	6105                	addi	sp,sp,32
    8000422e:	8082                	ret

0000000080004230 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004230:	1141                	addi	sp,sp,-16
    80004232:	e406                	sd	ra,8(sp)
    80004234:	e022                	sd	s0,0(sp)
    80004236:	0800                	addi	s0,sp,16
    80004238:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000423a:	4585                	li	a1,1
    8000423c:	00000097          	auipc	ra,0x0
    80004240:	db4080e7          	jalr	-588(ra) # 80003ff0 <namex>
}
    80004244:	60a2                	ld	ra,8(sp)
    80004246:	6402                	ld	s0,0(sp)
    80004248:	0141                	addi	sp,sp,16
    8000424a:	8082                	ret

000000008000424c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000424c:	1101                	addi	sp,sp,-32
    8000424e:	ec06                	sd	ra,24(sp)
    80004250:	e822                	sd	s0,16(sp)
    80004252:	e426                	sd	s1,8(sp)
    80004254:	e04a                	sd	s2,0(sp)
    80004256:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004258:	00028917          	auipc	s2,0x28
    8000425c:	dd890913          	addi	s2,s2,-552 # 8002c030 <log>
    80004260:	02092583          	lw	a1,32(s2)
    80004264:	03092503          	lw	a0,48(s2)
    80004268:	fffff097          	auipc	ra,0xfffff
    8000426c:	f50080e7          	jalr	-176(ra) # 800031b8 <bread>
    80004270:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004272:	03492683          	lw	a3,52(s2)
    80004276:	d134                	sw	a3,96(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004278:	02d05763          	blez	a3,800042a6 <write_head+0x5a>
    8000427c:	00028797          	auipc	a5,0x28
    80004280:	dec78793          	addi	a5,a5,-532 # 8002c068 <log+0x38>
    80004284:	06450713          	addi	a4,a0,100
    80004288:	36fd                	addiw	a3,a3,-1
    8000428a:	1682                	slli	a3,a3,0x20
    8000428c:	9281                	srli	a3,a3,0x20
    8000428e:	068a                	slli	a3,a3,0x2
    80004290:	00028617          	auipc	a2,0x28
    80004294:	ddc60613          	addi	a2,a2,-548 # 8002c06c <log+0x3c>
    80004298:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000429a:	4390                	lw	a2,0(a5)
    8000429c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000429e:	0791                	addi	a5,a5,4
    800042a0:	0711                	addi	a4,a4,4
    800042a2:	fed79ce3          	bne	a5,a3,8000429a <write_head+0x4e>
  }
  bwrite(buf);
    800042a6:	8526                	mv	a0,s1
    800042a8:	fffff097          	auipc	ra,0xfffff
    800042ac:	090080e7          	jalr	144(ra) # 80003338 <bwrite>
  brelse(buf);
    800042b0:	8526                	mv	a0,s1
    800042b2:	fffff097          	auipc	ra,0xfffff
    800042b6:	0c4080e7          	jalr	196(ra) # 80003376 <brelse>
}
    800042ba:	60e2                	ld	ra,24(sp)
    800042bc:	6442                	ld	s0,16(sp)
    800042be:	64a2                	ld	s1,8(sp)
    800042c0:	6902                	ld	s2,0(sp)
    800042c2:	6105                	addi	sp,sp,32
    800042c4:	8082                	ret

00000000800042c6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c6:	00028797          	auipc	a5,0x28
    800042ca:	d9e7a783          	lw	a5,-610(a5) # 8002c064 <log+0x34>
    800042ce:	0af05d63          	blez	a5,80004388 <install_trans+0xc2>
{
    800042d2:	7139                	addi	sp,sp,-64
    800042d4:	fc06                	sd	ra,56(sp)
    800042d6:	f822                	sd	s0,48(sp)
    800042d8:	f426                	sd	s1,40(sp)
    800042da:	f04a                	sd	s2,32(sp)
    800042dc:	ec4e                	sd	s3,24(sp)
    800042de:	e852                	sd	s4,16(sp)
    800042e0:	e456                	sd	s5,8(sp)
    800042e2:	e05a                	sd	s6,0(sp)
    800042e4:	0080                	addi	s0,sp,64
    800042e6:	8b2a                	mv	s6,a0
    800042e8:	00028a97          	auipc	s5,0x28
    800042ec:	d80a8a93          	addi	s5,s5,-640 # 8002c068 <log+0x38>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042f0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042f2:	00028997          	auipc	s3,0x28
    800042f6:	d3e98993          	addi	s3,s3,-706 # 8002c030 <log>
    800042fa:	a035                	j	80004326 <install_trans+0x60>
      bunpin(dbuf);
    800042fc:	8526                	mv	a0,s1
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	150080e7          	jalr	336(ra) # 8000344e <bunpin>
    brelse(lbuf);
    80004306:	854a                	mv	a0,s2
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	06e080e7          	jalr	110(ra) # 80003376 <brelse>
    brelse(dbuf);
    80004310:	8526                	mv	a0,s1
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	064080e7          	jalr	100(ra) # 80003376 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000431a:	2a05                	addiw	s4,s4,1
    8000431c:	0a91                	addi	s5,s5,4
    8000431e:	0349a783          	lw	a5,52(s3)
    80004322:	04fa5963          	bge	s4,a5,80004374 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004326:	0209a583          	lw	a1,32(s3)
    8000432a:	014585bb          	addw	a1,a1,s4
    8000432e:	2585                	addiw	a1,a1,1
    80004330:	0309a503          	lw	a0,48(s3)
    80004334:	fffff097          	auipc	ra,0xfffff
    80004338:	e84080e7          	jalr	-380(ra) # 800031b8 <bread>
    8000433c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000433e:	000aa583          	lw	a1,0(s5)
    80004342:	0309a503          	lw	a0,48(s3)
    80004346:	fffff097          	auipc	ra,0xfffff
    8000434a:	e72080e7          	jalr	-398(ra) # 800031b8 <bread>
    8000434e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004350:	40000613          	li	a2,1024
    80004354:	06090593          	addi	a1,s2,96
    80004358:	06050513          	addi	a0,a0,96
    8000435c:	ffffd097          	auipc	ra,0xffffd
    80004360:	e12080e7          	jalr	-494(ra) # 8000116e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004364:	8526                	mv	a0,s1
    80004366:	fffff097          	auipc	ra,0xfffff
    8000436a:	fd2080e7          	jalr	-46(ra) # 80003338 <bwrite>
    if(recovering == 0)
    8000436e:	f80b1ce3          	bnez	s6,80004306 <install_trans+0x40>
    80004372:	b769                	j	800042fc <install_trans+0x36>
}
    80004374:	70e2                	ld	ra,56(sp)
    80004376:	7442                	ld	s0,48(sp)
    80004378:	74a2                	ld	s1,40(sp)
    8000437a:	7902                	ld	s2,32(sp)
    8000437c:	69e2                	ld	s3,24(sp)
    8000437e:	6a42                	ld	s4,16(sp)
    80004380:	6aa2                	ld	s5,8(sp)
    80004382:	6b02                	ld	s6,0(sp)
    80004384:	6121                	addi	sp,sp,64
    80004386:	8082                	ret
    80004388:	8082                	ret

000000008000438a <initlog>:
{
    8000438a:	7179                	addi	sp,sp,-48
    8000438c:	f406                	sd	ra,40(sp)
    8000438e:	f022                	sd	s0,32(sp)
    80004390:	ec26                	sd	s1,24(sp)
    80004392:	e84a                	sd	s2,16(sp)
    80004394:	e44e                	sd	s3,8(sp)
    80004396:	1800                	addi	s0,sp,48
    80004398:	892a                	mv	s2,a0
    8000439a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000439c:	00028497          	auipc	s1,0x28
    800043a0:	c9448493          	addi	s1,s1,-876 # 8002c030 <log>
    800043a4:	00004597          	auipc	a1,0x4
    800043a8:	30458593          	addi	a1,a1,772 # 800086a8 <syscalls+0x1f0>
    800043ac:	8526                	mv	a0,s1
    800043ae:	ffffd097          	auipc	ra,0xffffd
    800043b2:	afc080e7          	jalr	-1284(ra) # 80000eaa <initlock>
  log.start = sb->logstart;
    800043b6:	0149a583          	lw	a1,20(s3)
    800043ba:	d08c                	sw	a1,32(s1)
  log.size = sb->nlog;
    800043bc:	0109a783          	lw	a5,16(s3)
    800043c0:	d0dc                	sw	a5,36(s1)
  log.dev = dev;
    800043c2:	0324a823          	sw	s2,48(s1)
  struct buf *buf = bread(log.dev, log.start);
    800043c6:	854a                	mv	a0,s2
    800043c8:	fffff097          	auipc	ra,0xfffff
    800043cc:	df0080e7          	jalr	-528(ra) # 800031b8 <bread>
  log.lh.n = lh->n;
    800043d0:	513c                	lw	a5,96(a0)
    800043d2:	d8dc                	sw	a5,52(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043d4:	02f05563          	blez	a5,800043fe <initlog+0x74>
    800043d8:	06450713          	addi	a4,a0,100
    800043dc:	00028697          	auipc	a3,0x28
    800043e0:	c8c68693          	addi	a3,a3,-884 # 8002c068 <log+0x38>
    800043e4:	37fd                	addiw	a5,a5,-1
    800043e6:	1782                	slli	a5,a5,0x20
    800043e8:	9381                	srli	a5,a5,0x20
    800043ea:	078a                	slli	a5,a5,0x2
    800043ec:	06850613          	addi	a2,a0,104
    800043f0:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800043f2:	4310                	lw	a2,0(a4)
    800043f4:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800043f6:	0711                	addi	a4,a4,4
    800043f8:	0691                	addi	a3,a3,4
    800043fa:	fef71ce3          	bne	a4,a5,800043f2 <initlog+0x68>
  brelse(buf);
    800043fe:	fffff097          	auipc	ra,0xfffff
    80004402:	f78080e7          	jalr	-136(ra) # 80003376 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004406:	4505                	li	a0,1
    80004408:	00000097          	auipc	ra,0x0
    8000440c:	ebe080e7          	jalr	-322(ra) # 800042c6 <install_trans>
  log.lh.n = 0;
    80004410:	00028797          	auipc	a5,0x28
    80004414:	c407aa23          	sw	zero,-940(a5) # 8002c064 <log+0x34>
  write_head(); // clear the log
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	e34080e7          	jalr	-460(ra) # 8000424c <write_head>
}
    80004420:	70a2                	ld	ra,40(sp)
    80004422:	7402                	ld	s0,32(sp)
    80004424:	64e2                	ld	s1,24(sp)
    80004426:	6942                	ld	s2,16(sp)
    80004428:	69a2                	ld	s3,8(sp)
    8000442a:	6145                	addi	sp,sp,48
    8000442c:	8082                	ret

000000008000442e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000442e:	1101                	addi	sp,sp,-32
    80004430:	ec06                	sd	ra,24(sp)
    80004432:	e822                	sd	s0,16(sp)
    80004434:	e426                	sd	s1,8(sp)
    80004436:	e04a                	sd	s2,0(sp)
    80004438:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000443a:	00028517          	auipc	a0,0x28
    8000443e:	bf650513          	addi	a0,a0,-1034 # 8002c030 <log>
    80004442:	ffffd097          	auipc	ra,0xffffd
    80004446:	8ec080e7          	jalr	-1812(ra) # 80000d2e <acquire>
  while(1){
    if(log.committing){
    8000444a:	00028497          	auipc	s1,0x28
    8000444e:	be648493          	addi	s1,s1,-1050 # 8002c030 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004452:	4979                	li	s2,30
    80004454:	a039                	j	80004462 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004456:	85a6                	mv	a1,s1
    80004458:	8526                	mv	a0,s1
    8000445a:	ffffe097          	auipc	ra,0xffffe
    8000445e:	12c080e7          	jalr	300(ra) # 80002586 <sleep>
    if(log.committing){
    80004462:	54dc                	lw	a5,44(s1)
    80004464:	fbed                	bnez	a5,80004456 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004466:	549c                	lw	a5,40(s1)
    80004468:	0017871b          	addiw	a4,a5,1
    8000446c:	0007069b          	sext.w	a3,a4
    80004470:	0027179b          	slliw	a5,a4,0x2
    80004474:	9fb9                	addw	a5,a5,a4
    80004476:	0017979b          	slliw	a5,a5,0x1
    8000447a:	58d8                	lw	a4,52(s1)
    8000447c:	9fb9                	addw	a5,a5,a4
    8000447e:	00f95963          	bge	s2,a5,80004490 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004482:	85a6                	mv	a1,s1
    80004484:	8526                	mv	a0,s1
    80004486:	ffffe097          	auipc	ra,0xffffe
    8000448a:	100080e7          	jalr	256(ra) # 80002586 <sleep>
    8000448e:	bfd1                	j	80004462 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004490:	00028517          	auipc	a0,0x28
    80004494:	ba050513          	addi	a0,a0,-1120 # 8002c030 <log>
    80004498:	d514                	sw	a3,40(a0)
      release(&log.lock);
    8000449a:	ffffd097          	auipc	ra,0xffffd
    8000449e:	964080e7          	jalr	-1692(ra) # 80000dfe <release>
      break;
    }
  }
}
    800044a2:	60e2                	ld	ra,24(sp)
    800044a4:	6442                	ld	s0,16(sp)
    800044a6:	64a2                	ld	s1,8(sp)
    800044a8:	6902                	ld	s2,0(sp)
    800044aa:	6105                	addi	sp,sp,32
    800044ac:	8082                	ret

00000000800044ae <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800044ae:	7139                	addi	sp,sp,-64
    800044b0:	fc06                	sd	ra,56(sp)
    800044b2:	f822                	sd	s0,48(sp)
    800044b4:	f426                	sd	s1,40(sp)
    800044b6:	f04a                	sd	s2,32(sp)
    800044b8:	ec4e                	sd	s3,24(sp)
    800044ba:	e852                	sd	s4,16(sp)
    800044bc:	e456                	sd	s5,8(sp)
    800044be:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800044c0:	00028497          	auipc	s1,0x28
    800044c4:	b7048493          	addi	s1,s1,-1168 # 8002c030 <log>
    800044c8:	8526                	mv	a0,s1
    800044ca:	ffffd097          	auipc	ra,0xffffd
    800044ce:	864080e7          	jalr	-1948(ra) # 80000d2e <acquire>
  log.outstanding -= 1;
    800044d2:	549c                	lw	a5,40(s1)
    800044d4:	37fd                	addiw	a5,a5,-1
    800044d6:	0007891b          	sext.w	s2,a5
    800044da:	d49c                	sw	a5,40(s1)
  if(log.committing)
    800044dc:	54dc                	lw	a5,44(s1)
    800044de:	efb9                	bnez	a5,8000453c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044e0:	06091663          	bnez	s2,8000454c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800044e4:	00028497          	auipc	s1,0x28
    800044e8:	b4c48493          	addi	s1,s1,-1204 # 8002c030 <log>
    800044ec:	4785                	li	a5,1
    800044ee:	d4dc                	sw	a5,44(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044f0:	8526                	mv	a0,s1
    800044f2:	ffffd097          	auipc	ra,0xffffd
    800044f6:	90c080e7          	jalr	-1780(ra) # 80000dfe <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044fa:	58dc                	lw	a5,52(s1)
    800044fc:	06f04763          	bgtz	a5,8000456a <end_op+0xbc>
    acquire(&log.lock);
    80004500:	00028497          	auipc	s1,0x28
    80004504:	b3048493          	addi	s1,s1,-1232 # 8002c030 <log>
    80004508:	8526                	mv	a0,s1
    8000450a:	ffffd097          	auipc	ra,0xffffd
    8000450e:	824080e7          	jalr	-2012(ra) # 80000d2e <acquire>
    log.committing = 0;
    80004512:	0204a623          	sw	zero,44(s1)
    wakeup(&log);
    80004516:	8526                	mv	a0,s1
    80004518:	ffffe097          	auipc	ra,0xffffe
    8000451c:	1f4080e7          	jalr	500(ra) # 8000270c <wakeup>
    release(&log.lock);
    80004520:	8526                	mv	a0,s1
    80004522:	ffffd097          	auipc	ra,0xffffd
    80004526:	8dc080e7          	jalr	-1828(ra) # 80000dfe <release>
}
    8000452a:	70e2                	ld	ra,56(sp)
    8000452c:	7442                	ld	s0,48(sp)
    8000452e:	74a2                	ld	s1,40(sp)
    80004530:	7902                	ld	s2,32(sp)
    80004532:	69e2                	ld	s3,24(sp)
    80004534:	6a42                	ld	s4,16(sp)
    80004536:	6aa2                	ld	s5,8(sp)
    80004538:	6121                	addi	sp,sp,64
    8000453a:	8082                	ret
    panic("log.committing");
    8000453c:	00004517          	auipc	a0,0x4
    80004540:	17450513          	addi	a0,a0,372 # 800086b0 <syscalls+0x1f8>
    80004544:	ffffc097          	auipc	ra,0xffffc
    80004548:	00c080e7          	jalr	12(ra) # 80000550 <panic>
    wakeup(&log);
    8000454c:	00028497          	auipc	s1,0x28
    80004550:	ae448493          	addi	s1,s1,-1308 # 8002c030 <log>
    80004554:	8526                	mv	a0,s1
    80004556:	ffffe097          	auipc	ra,0xffffe
    8000455a:	1b6080e7          	jalr	438(ra) # 8000270c <wakeup>
  release(&log.lock);
    8000455e:	8526                	mv	a0,s1
    80004560:	ffffd097          	auipc	ra,0xffffd
    80004564:	89e080e7          	jalr	-1890(ra) # 80000dfe <release>
  if(do_commit){
    80004568:	b7c9                	j	8000452a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000456a:	00028a97          	auipc	s5,0x28
    8000456e:	afea8a93          	addi	s5,s5,-1282 # 8002c068 <log+0x38>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004572:	00028a17          	auipc	s4,0x28
    80004576:	abea0a13          	addi	s4,s4,-1346 # 8002c030 <log>
    8000457a:	020a2583          	lw	a1,32(s4)
    8000457e:	012585bb          	addw	a1,a1,s2
    80004582:	2585                	addiw	a1,a1,1
    80004584:	030a2503          	lw	a0,48(s4)
    80004588:	fffff097          	auipc	ra,0xfffff
    8000458c:	c30080e7          	jalr	-976(ra) # 800031b8 <bread>
    80004590:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004592:	000aa583          	lw	a1,0(s5)
    80004596:	030a2503          	lw	a0,48(s4)
    8000459a:	fffff097          	auipc	ra,0xfffff
    8000459e:	c1e080e7          	jalr	-994(ra) # 800031b8 <bread>
    800045a2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800045a4:	40000613          	li	a2,1024
    800045a8:	06050593          	addi	a1,a0,96
    800045ac:	06048513          	addi	a0,s1,96
    800045b0:	ffffd097          	auipc	ra,0xffffd
    800045b4:	bbe080e7          	jalr	-1090(ra) # 8000116e <memmove>
    bwrite(to);  // write the log
    800045b8:	8526                	mv	a0,s1
    800045ba:	fffff097          	auipc	ra,0xfffff
    800045be:	d7e080e7          	jalr	-642(ra) # 80003338 <bwrite>
    brelse(from);
    800045c2:	854e                	mv	a0,s3
    800045c4:	fffff097          	auipc	ra,0xfffff
    800045c8:	db2080e7          	jalr	-590(ra) # 80003376 <brelse>
    brelse(to);
    800045cc:	8526                	mv	a0,s1
    800045ce:	fffff097          	auipc	ra,0xfffff
    800045d2:	da8080e7          	jalr	-600(ra) # 80003376 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045d6:	2905                	addiw	s2,s2,1
    800045d8:	0a91                	addi	s5,s5,4
    800045da:	034a2783          	lw	a5,52(s4)
    800045de:	f8f94ee3          	blt	s2,a5,8000457a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045e2:	00000097          	auipc	ra,0x0
    800045e6:	c6a080e7          	jalr	-918(ra) # 8000424c <write_head>
    install_trans(0); // Now install writes to home locations
    800045ea:	4501                	li	a0,0
    800045ec:	00000097          	auipc	ra,0x0
    800045f0:	cda080e7          	jalr	-806(ra) # 800042c6 <install_trans>
    log.lh.n = 0;
    800045f4:	00028797          	auipc	a5,0x28
    800045f8:	a607a823          	sw	zero,-1424(a5) # 8002c064 <log+0x34>
    write_head();    // Erase the transaction from the log
    800045fc:	00000097          	auipc	ra,0x0
    80004600:	c50080e7          	jalr	-944(ra) # 8000424c <write_head>
    80004604:	bdf5                	j	80004500 <end_op+0x52>

0000000080004606 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004606:	1101                	addi	sp,sp,-32
    80004608:	ec06                	sd	ra,24(sp)
    8000460a:	e822                	sd	s0,16(sp)
    8000460c:	e426                	sd	s1,8(sp)
    8000460e:	e04a                	sd	s2,0(sp)
    80004610:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004612:	00028717          	auipc	a4,0x28
    80004616:	a5272703          	lw	a4,-1454(a4) # 8002c064 <log+0x34>
    8000461a:	47f5                	li	a5,29
    8000461c:	08e7c063          	blt	a5,a4,8000469c <log_write+0x96>
    80004620:	84aa                	mv	s1,a0
    80004622:	00028797          	auipc	a5,0x28
    80004626:	a327a783          	lw	a5,-1486(a5) # 8002c054 <log+0x24>
    8000462a:	37fd                	addiw	a5,a5,-1
    8000462c:	06f75863          	bge	a4,a5,8000469c <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004630:	00028797          	auipc	a5,0x28
    80004634:	a287a783          	lw	a5,-1496(a5) # 8002c058 <log+0x28>
    80004638:	06f05a63          	blez	a5,800046ac <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000463c:	00028917          	auipc	s2,0x28
    80004640:	9f490913          	addi	s2,s2,-1548 # 8002c030 <log>
    80004644:	854a                	mv	a0,s2
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	6e8080e7          	jalr	1768(ra) # 80000d2e <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000464e:	03492603          	lw	a2,52(s2)
    80004652:	06c05563          	blez	a2,800046bc <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004656:	44cc                	lw	a1,12(s1)
    80004658:	00028717          	auipc	a4,0x28
    8000465c:	a1070713          	addi	a4,a4,-1520 # 8002c068 <log+0x38>
  for (i = 0; i < log.lh.n; i++) {
    80004660:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004662:	4314                	lw	a3,0(a4)
    80004664:	04b68d63          	beq	a3,a1,800046be <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004668:	2785                	addiw	a5,a5,1
    8000466a:	0711                	addi	a4,a4,4
    8000466c:	fec79be3          	bne	a5,a2,80004662 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004670:	0631                	addi	a2,a2,12
    80004672:	060a                	slli	a2,a2,0x2
    80004674:	00028797          	auipc	a5,0x28
    80004678:	9bc78793          	addi	a5,a5,-1604 # 8002c030 <log>
    8000467c:	963e                	add	a2,a2,a5
    8000467e:	44dc                	lw	a5,12(s1)
    80004680:	c61c                	sw	a5,8(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004682:	8526                	mv	a0,s1
    80004684:	fffff097          	auipc	ra,0xfffff
    80004688:	d76080e7          	jalr	-650(ra) # 800033fa <bpin>
    log.lh.n++;
    8000468c:	00028717          	auipc	a4,0x28
    80004690:	9a470713          	addi	a4,a4,-1628 # 8002c030 <log>
    80004694:	5b5c                	lw	a5,52(a4)
    80004696:	2785                	addiw	a5,a5,1
    80004698:	db5c                	sw	a5,52(a4)
    8000469a:	a83d                	j	800046d8 <log_write+0xd2>
    panic("too big a transaction");
    8000469c:	00004517          	auipc	a0,0x4
    800046a0:	02450513          	addi	a0,a0,36 # 800086c0 <syscalls+0x208>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	eac080e7          	jalr	-340(ra) # 80000550 <panic>
    panic("log_write outside of trans");
    800046ac:	00004517          	auipc	a0,0x4
    800046b0:	02c50513          	addi	a0,a0,44 # 800086d8 <syscalls+0x220>
    800046b4:	ffffc097          	auipc	ra,0xffffc
    800046b8:	e9c080e7          	jalr	-356(ra) # 80000550 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800046bc:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800046be:	00c78713          	addi	a4,a5,12
    800046c2:	00271693          	slli	a3,a4,0x2
    800046c6:	00028717          	auipc	a4,0x28
    800046ca:	96a70713          	addi	a4,a4,-1686 # 8002c030 <log>
    800046ce:	9736                	add	a4,a4,a3
    800046d0:	44d4                	lw	a3,12(s1)
    800046d2:	c714                	sw	a3,8(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800046d4:	faf607e3          	beq	a2,a5,80004682 <log_write+0x7c>
  }
  release(&log.lock);
    800046d8:	00028517          	auipc	a0,0x28
    800046dc:	95850513          	addi	a0,a0,-1704 # 8002c030 <log>
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	71e080e7          	jalr	1822(ra) # 80000dfe <release>
}
    800046e8:	60e2                	ld	ra,24(sp)
    800046ea:	6442                	ld	s0,16(sp)
    800046ec:	64a2                	ld	s1,8(sp)
    800046ee:	6902                	ld	s2,0(sp)
    800046f0:	6105                	addi	sp,sp,32
    800046f2:	8082                	ret

00000000800046f4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046f4:	1101                	addi	sp,sp,-32
    800046f6:	ec06                	sd	ra,24(sp)
    800046f8:	e822                	sd	s0,16(sp)
    800046fa:	e426                	sd	s1,8(sp)
    800046fc:	e04a                	sd	s2,0(sp)
    800046fe:	1000                	addi	s0,sp,32
    80004700:	84aa                	mv	s1,a0
    80004702:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004704:	00004597          	auipc	a1,0x4
    80004708:	ff458593          	addi	a1,a1,-12 # 800086f8 <syscalls+0x240>
    8000470c:	0521                	addi	a0,a0,8
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	79c080e7          	jalr	1948(ra) # 80000eaa <initlock>
  lk->name = name;
    80004716:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    8000471a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000471e:	0204a823          	sw	zero,48(s1)
}
    80004722:	60e2                	ld	ra,24(sp)
    80004724:	6442                	ld	s0,16(sp)
    80004726:	64a2                	ld	s1,8(sp)
    80004728:	6902                	ld	s2,0(sp)
    8000472a:	6105                	addi	sp,sp,32
    8000472c:	8082                	ret

000000008000472e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000472e:	1101                	addi	sp,sp,-32
    80004730:	ec06                	sd	ra,24(sp)
    80004732:	e822                	sd	s0,16(sp)
    80004734:	e426                	sd	s1,8(sp)
    80004736:	e04a                	sd	s2,0(sp)
    80004738:	1000                	addi	s0,sp,32
    8000473a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000473c:	00850913          	addi	s2,a0,8
    80004740:	854a                	mv	a0,s2
    80004742:	ffffc097          	auipc	ra,0xffffc
    80004746:	5ec080e7          	jalr	1516(ra) # 80000d2e <acquire>
  while (lk->locked) {
    8000474a:	409c                	lw	a5,0(s1)
    8000474c:	cb89                	beqz	a5,8000475e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000474e:	85ca                	mv	a1,s2
    80004750:	8526                	mv	a0,s1
    80004752:	ffffe097          	auipc	ra,0xffffe
    80004756:	e34080e7          	jalr	-460(ra) # 80002586 <sleep>
  while (lk->locked) {
    8000475a:	409c                	lw	a5,0(s1)
    8000475c:	fbed                	bnez	a5,8000474e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000475e:	4785                	li	a5,1
    80004760:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004762:	ffffd097          	auipc	ra,0xffffd
    80004766:	614080e7          	jalr	1556(ra) # 80001d76 <myproc>
    8000476a:	413c                	lw	a5,64(a0)
    8000476c:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    8000476e:	854a                	mv	a0,s2
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	68e080e7          	jalr	1678(ra) # 80000dfe <release>
}
    80004778:	60e2                	ld	ra,24(sp)
    8000477a:	6442                	ld	s0,16(sp)
    8000477c:	64a2                	ld	s1,8(sp)
    8000477e:	6902                	ld	s2,0(sp)
    80004780:	6105                	addi	sp,sp,32
    80004782:	8082                	ret

0000000080004784 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004784:	1101                	addi	sp,sp,-32
    80004786:	ec06                	sd	ra,24(sp)
    80004788:	e822                	sd	s0,16(sp)
    8000478a:	e426                	sd	s1,8(sp)
    8000478c:	e04a                	sd	s2,0(sp)
    8000478e:	1000                	addi	s0,sp,32
    80004790:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004792:	00850913          	addi	s2,a0,8
    80004796:	854a                	mv	a0,s2
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	596080e7          	jalr	1430(ra) # 80000d2e <acquire>
  lk->locked = 0;
    800047a0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047a4:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    800047a8:	8526                	mv	a0,s1
    800047aa:	ffffe097          	auipc	ra,0xffffe
    800047ae:	f62080e7          	jalr	-158(ra) # 8000270c <wakeup>
  release(&lk->lk);
    800047b2:	854a                	mv	a0,s2
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	64a080e7          	jalr	1610(ra) # 80000dfe <release>
}
    800047bc:	60e2                	ld	ra,24(sp)
    800047be:	6442                	ld	s0,16(sp)
    800047c0:	64a2                	ld	s1,8(sp)
    800047c2:	6902                	ld	s2,0(sp)
    800047c4:	6105                	addi	sp,sp,32
    800047c6:	8082                	ret

00000000800047c8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800047c8:	7179                	addi	sp,sp,-48
    800047ca:	f406                	sd	ra,40(sp)
    800047cc:	f022                	sd	s0,32(sp)
    800047ce:	ec26                	sd	s1,24(sp)
    800047d0:	e84a                	sd	s2,16(sp)
    800047d2:	e44e                	sd	s3,8(sp)
    800047d4:	1800                	addi	s0,sp,48
    800047d6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800047d8:	00850913          	addi	s2,a0,8
    800047dc:	854a                	mv	a0,s2
    800047de:	ffffc097          	auipc	ra,0xffffc
    800047e2:	550080e7          	jalr	1360(ra) # 80000d2e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047e6:	409c                	lw	a5,0(s1)
    800047e8:	ef99                	bnez	a5,80004806 <holdingsleep+0x3e>
    800047ea:	4481                	li	s1,0
  release(&lk->lk);
    800047ec:	854a                	mv	a0,s2
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	610080e7          	jalr	1552(ra) # 80000dfe <release>
  return r;
}
    800047f6:	8526                	mv	a0,s1
    800047f8:	70a2                	ld	ra,40(sp)
    800047fa:	7402                	ld	s0,32(sp)
    800047fc:	64e2                	ld	s1,24(sp)
    800047fe:	6942                	ld	s2,16(sp)
    80004800:	69a2                	ld	s3,8(sp)
    80004802:	6145                	addi	sp,sp,48
    80004804:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004806:	0304a983          	lw	s3,48(s1)
    8000480a:	ffffd097          	auipc	ra,0xffffd
    8000480e:	56c080e7          	jalr	1388(ra) # 80001d76 <myproc>
    80004812:	4124                	lw	s1,64(a0)
    80004814:	413484b3          	sub	s1,s1,s3
    80004818:	0014b493          	seqz	s1,s1
    8000481c:	bfc1                	j	800047ec <holdingsleep+0x24>

000000008000481e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000481e:	1141                	addi	sp,sp,-16
    80004820:	e406                	sd	ra,8(sp)
    80004822:	e022                	sd	s0,0(sp)
    80004824:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004826:	00004597          	auipc	a1,0x4
    8000482a:	ee258593          	addi	a1,a1,-286 # 80008708 <syscalls+0x250>
    8000482e:	00028517          	auipc	a0,0x28
    80004832:	95250513          	addi	a0,a0,-1710 # 8002c180 <ftable>
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	674080e7          	jalr	1652(ra) # 80000eaa <initlock>
}
    8000483e:	60a2                	ld	ra,8(sp)
    80004840:	6402                	ld	s0,0(sp)
    80004842:	0141                	addi	sp,sp,16
    80004844:	8082                	ret

0000000080004846 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004846:	1101                	addi	sp,sp,-32
    80004848:	ec06                	sd	ra,24(sp)
    8000484a:	e822                	sd	s0,16(sp)
    8000484c:	e426                	sd	s1,8(sp)
    8000484e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004850:	00028517          	auipc	a0,0x28
    80004854:	93050513          	addi	a0,a0,-1744 # 8002c180 <ftable>
    80004858:	ffffc097          	auipc	ra,0xffffc
    8000485c:	4d6080e7          	jalr	1238(ra) # 80000d2e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004860:	00028497          	auipc	s1,0x28
    80004864:	94048493          	addi	s1,s1,-1728 # 8002c1a0 <ftable+0x20>
    80004868:	00029717          	auipc	a4,0x29
    8000486c:	8d870713          	addi	a4,a4,-1832 # 8002d140 <ftable+0xfc0>
    if(f->ref == 0){
    80004870:	40dc                	lw	a5,4(s1)
    80004872:	cf99                	beqz	a5,80004890 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004874:	02848493          	addi	s1,s1,40
    80004878:	fee49ce3          	bne	s1,a4,80004870 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000487c:	00028517          	auipc	a0,0x28
    80004880:	90450513          	addi	a0,a0,-1788 # 8002c180 <ftable>
    80004884:	ffffc097          	auipc	ra,0xffffc
    80004888:	57a080e7          	jalr	1402(ra) # 80000dfe <release>
  return 0;
    8000488c:	4481                	li	s1,0
    8000488e:	a819                	j	800048a4 <filealloc+0x5e>
      f->ref = 1;
    80004890:	4785                	li	a5,1
    80004892:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004894:	00028517          	auipc	a0,0x28
    80004898:	8ec50513          	addi	a0,a0,-1812 # 8002c180 <ftable>
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	562080e7          	jalr	1378(ra) # 80000dfe <release>
}
    800048a4:	8526                	mv	a0,s1
    800048a6:	60e2                	ld	ra,24(sp)
    800048a8:	6442                	ld	s0,16(sp)
    800048aa:	64a2                	ld	s1,8(sp)
    800048ac:	6105                	addi	sp,sp,32
    800048ae:	8082                	ret

00000000800048b0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800048b0:	1101                	addi	sp,sp,-32
    800048b2:	ec06                	sd	ra,24(sp)
    800048b4:	e822                	sd	s0,16(sp)
    800048b6:	e426                	sd	s1,8(sp)
    800048b8:	1000                	addi	s0,sp,32
    800048ba:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800048bc:	00028517          	auipc	a0,0x28
    800048c0:	8c450513          	addi	a0,a0,-1852 # 8002c180 <ftable>
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	46a080e7          	jalr	1130(ra) # 80000d2e <acquire>
  if(f->ref < 1)
    800048cc:	40dc                	lw	a5,4(s1)
    800048ce:	02f05263          	blez	a5,800048f2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800048d2:	2785                	addiw	a5,a5,1
    800048d4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800048d6:	00028517          	auipc	a0,0x28
    800048da:	8aa50513          	addi	a0,a0,-1878 # 8002c180 <ftable>
    800048de:	ffffc097          	auipc	ra,0xffffc
    800048e2:	520080e7          	jalr	1312(ra) # 80000dfe <release>
  return f;
}
    800048e6:	8526                	mv	a0,s1
    800048e8:	60e2                	ld	ra,24(sp)
    800048ea:	6442                	ld	s0,16(sp)
    800048ec:	64a2                	ld	s1,8(sp)
    800048ee:	6105                	addi	sp,sp,32
    800048f0:	8082                	ret
    panic("filedup");
    800048f2:	00004517          	auipc	a0,0x4
    800048f6:	e1e50513          	addi	a0,a0,-482 # 80008710 <syscalls+0x258>
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	c56080e7          	jalr	-938(ra) # 80000550 <panic>

0000000080004902 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004902:	7139                	addi	sp,sp,-64
    80004904:	fc06                	sd	ra,56(sp)
    80004906:	f822                	sd	s0,48(sp)
    80004908:	f426                	sd	s1,40(sp)
    8000490a:	f04a                	sd	s2,32(sp)
    8000490c:	ec4e                	sd	s3,24(sp)
    8000490e:	e852                	sd	s4,16(sp)
    80004910:	e456                	sd	s5,8(sp)
    80004912:	0080                	addi	s0,sp,64
    80004914:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004916:	00028517          	auipc	a0,0x28
    8000491a:	86a50513          	addi	a0,a0,-1942 # 8002c180 <ftable>
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	410080e7          	jalr	1040(ra) # 80000d2e <acquire>
  if(f->ref < 1)
    80004926:	40dc                	lw	a5,4(s1)
    80004928:	06f05163          	blez	a5,8000498a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000492c:	37fd                	addiw	a5,a5,-1
    8000492e:	0007871b          	sext.w	a4,a5
    80004932:	c0dc                	sw	a5,4(s1)
    80004934:	06e04363          	bgtz	a4,8000499a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004938:	0004a903          	lw	s2,0(s1)
    8000493c:	0094ca83          	lbu	s5,9(s1)
    80004940:	0104ba03          	ld	s4,16(s1)
    80004944:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004948:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000494c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004950:	00028517          	auipc	a0,0x28
    80004954:	83050513          	addi	a0,a0,-2000 # 8002c180 <ftable>
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	4a6080e7          	jalr	1190(ra) # 80000dfe <release>

  if(ff.type == FD_PIPE){
    80004960:	4785                	li	a5,1
    80004962:	04f90d63          	beq	s2,a5,800049bc <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004966:	3979                	addiw	s2,s2,-2
    80004968:	4785                	li	a5,1
    8000496a:	0527e063          	bltu	a5,s2,800049aa <fileclose+0xa8>
    begin_op();
    8000496e:	00000097          	auipc	ra,0x0
    80004972:	ac0080e7          	jalr	-1344(ra) # 8000442e <begin_op>
    iput(ff.ip);
    80004976:	854e                	mv	a0,s3
    80004978:	fffff097          	auipc	ra,0xfffff
    8000497c:	2a0080e7          	jalr	672(ra) # 80003c18 <iput>
    end_op();
    80004980:	00000097          	auipc	ra,0x0
    80004984:	b2e080e7          	jalr	-1234(ra) # 800044ae <end_op>
    80004988:	a00d                	j	800049aa <fileclose+0xa8>
    panic("fileclose");
    8000498a:	00004517          	auipc	a0,0x4
    8000498e:	d8e50513          	addi	a0,a0,-626 # 80008718 <syscalls+0x260>
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	bbe080e7          	jalr	-1090(ra) # 80000550 <panic>
    release(&ftable.lock);
    8000499a:	00027517          	auipc	a0,0x27
    8000499e:	7e650513          	addi	a0,a0,2022 # 8002c180 <ftable>
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	45c080e7          	jalr	1116(ra) # 80000dfe <release>
  }
}
    800049aa:	70e2                	ld	ra,56(sp)
    800049ac:	7442                	ld	s0,48(sp)
    800049ae:	74a2                	ld	s1,40(sp)
    800049b0:	7902                	ld	s2,32(sp)
    800049b2:	69e2                	ld	s3,24(sp)
    800049b4:	6a42                	ld	s4,16(sp)
    800049b6:	6aa2                	ld	s5,8(sp)
    800049b8:	6121                	addi	sp,sp,64
    800049ba:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800049bc:	85d6                	mv	a1,s5
    800049be:	8552                	mv	a0,s4
    800049c0:	00000097          	auipc	ra,0x0
    800049c4:	372080e7          	jalr	882(ra) # 80004d32 <pipeclose>
    800049c8:	b7cd                	j	800049aa <fileclose+0xa8>

00000000800049ca <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800049ca:	715d                	addi	sp,sp,-80
    800049cc:	e486                	sd	ra,72(sp)
    800049ce:	e0a2                	sd	s0,64(sp)
    800049d0:	fc26                	sd	s1,56(sp)
    800049d2:	f84a                	sd	s2,48(sp)
    800049d4:	f44e                	sd	s3,40(sp)
    800049d6:	0880                	addi	s0,sp,80
    800049d8:	84aa                	mv	s1,a0
    800049da:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800049dc:	ffffd097          	auipc	ra,0xffffd
    800049e0:	39a080e7          	jalr	922(ra) # 80001d76 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049e4:	409c                	lw	a5,0(s1)
    800049e6:	37f9                	addiw	a5,a5,-2
    800049e8:	4705                	li	a4,1
    800049ea:	04f76763          	bltu	a4,a5,80004a38 <filestat+0x6e>
    800049ee:	892a                	mv	s2,a0
    ilock(f->ip);
    800049f0:	6c88                	ld	a0,24(s1)
    800049f2:	fffff097          	auipc	ra,0xfffff
    800049f6:	06c080e7          	jalr	108(ra) # 80003a5e <ilock>
    stati(f->ip, &st);
    800049fa:	fb840593          	addi	a1,s0,-72
    800049fe:	6c88                	ld	a0,24(s1)
    80004a00:	fffff097          	auipc	ra,0xfffff
    80004a04:	2e8080e7          	jalr	744(ra) # 80003ce8 <stati>
    iunlock(f->ip);
    80004a08:	6c88                	ld	a0,24(s1)
    80004a0a:	fffff097          	auipc	ra,0xfffff
    80004a0e:	116080e7          	jalr	278(ra) # 80003b20 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a12:	46e1                	li	a3,24
    80004a14:	fb840613          	addi	a2,s0,-72
    80004a18:	85ce                	mv	a1,s3
    80004a1a:	05893503          	ld	a0,88(s2)
    80004a1e:	ffffd097          	auipc	ra,0xffffd
    80004a22:	04c080e7          	jalr	76(ra) # 80001a6a <copyout>
    80004a26:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a2a:	60a6                	ld	ra,72(sp)
    80004a2c:	6406                	ld	s0,64(sp)
    80004a2e:	74e2                	ld	s1,56(sp)
    80004a30:	7942                	ld	s2,48(sp)
    80004a32:	79a2                	ld	s3,40(sp)
    80004a34:	6161                	addi	sp,sp,80
    80004a36:	8082                	ret
  return -1;
    80004a38:	557d                	li	a0,-1
    80004a3a:	bfc5                	j	80004a2a <filestat+0x60>

0000000080004a3c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a3c:	7179                	addi	sp,sp,-48
    80004a3e:	f406                	sd	ra,40(sp)
    80004a40:	f022                	sd	s0,32(sp)
    80004a42:	ec26                	sd	s1,24(sp)
    80004a44:	e84a                	sd	s2,16(sp)
    80004a46:	e44e                	sd	s3,8(sp)
    80004a48:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a4a:	00854783          	lbu	a5,8(a0)
    80004a4e:	c3d5                	beqz	a5,80004af2 <fileread+0xb6>
    80004a50:	84aa                	mv	s1,a0
    80004a52:	89ae                	mv	s3,a1
    80004a54:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a56:	411c                	lw	a5,0(a0)
    80004a58:	4705                	li	a4,1
    80004a5a:	04e78963          	beq	a5,a4,80004aac <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a5e:	470d                	li	a4,3
    80004a60:	04e78d63          	beq	a5,a4,80004aba <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a64:	4709                	li	a4,2
    80004a66:	06e79e63          	bne	a5,a4,80004ae2 <fileread+0xa6>
    ilock(f->ip);
    80004a6a:	6d08                	ld	a0,24(a0)
    80004a6c:	fffff097          	auipc	ra,0xfffff
    80004a70:	ff2080e7          	jalr	-14(ra) # 80003a5e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a74:	874a                	mv	a4,s2
    80004a76:	5094                	lw	a3,32(s1)
    80004a78:	864e                	mv	a2,s3
    80004a7a:	4585                	li	a1,1
    80004a7c:	6c88                	ld	a0,24(s1)
    80004a7e:	fffff097          	auipc	ra,0xfffff
    80004a82:	294080e7          	jalr	660(ra) # 80003d12 <readi>
    80004a86:	892a                	mv	s2,a0
    80004a88:	00a05563          	blez	a0,80004a92 <fileread+0x56>
      f->off += r;
    80004a8c:	509c                	lw	a5,32(s1)
    80004a8e:	9fa9                	addw	a5,a5,a0
    80004a90:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a92:	6c88                	ld	a0,24(s1)
    80004a94:	fffff097          	auipc	ra,0xfffff
    80004a98:	08c080e7          	jalr	140(ra) # 80003b20 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a9c:	854a                	mv	a0,s2
    80004a9e:	70a2                	ld	ra,40(sp)
    80004aa0:	7402                	ld	s0,32(sp)
    80004aa2:	64e2                	ld	s1,24(sp)
    80004aa4:	6942                	ld	s2,16(sp)
    80004aa6:	69a2                	ld	s3,8(sp)
    80004aa8:	6145                	addi	sp,sp,48
    80004aaa:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004aac:	6908                	ld	a0,16(a0)
    80004aae:	00000097          	auipc	ra,0x0
    80004ab2:	422080e7          	jalr	1058(ra) # 80004ed0 <piperead>
    80004ab6:	892a                	mv	s2,a0
    80004ab8:	b7d5                	j	80004a9c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004aba:	02451783          	lh	a5,36(a0)
    80004abe:	03079693          	slli	a3,a5,0x30
    80004ac2:	92c1                	srli	a3,a3,0x30
    80004ac4:	4725                	li	a4,9
    80004ac6:	02d76863          	bltu	a4,a3,80004af6 <fileread+0xba>
    80004aca:	0792                	slli	a5,a5,0x4
    80004acc:	00027717          	auipc	a4,0x27
    80004ad0:	61470713          	addi	a4,a4,1556 # 8002c0e0 <devsw>
    80004ad4:	97ba                	add	a5,a5,a4
    80004ad6:	639c                	ld	a5,0(a5)
    80004ad8:	c38d                	beqz	a5,80004afa <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ada:	4505                	li	a0,1
    80004adc:	9782                	jalr	a5
    80004ade:	892a                	mv	s2,a0
    80004ae0:	bf75                	j	80004a9c <fileread+0x60>
    panic("fileread");
    80004ae2:	00004517          	auipc	a0,0x4
    80004ae6:	c4650513          	addi	a0,a0,-954 # 80008728 <syscalls+0x270>
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	a66080e7          	jalr	-1434(ra) # 80000550 <panic>
    return -1;
    80004af2:	597d                	li	s2,-1
    80004af4:	b765                	j	80004a9c <fileread+0x60>
      return -1;
    80004af6:	597d                	li	s2,-1
    80004af8:	b755                	j	80004a9c <fileread+0x60>
    80004afa:	597d                	li	s2,-1
    80004afc:	b745                	j	80004a9c <fileread+0x60>

0000000080004afe <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004afe:	00954783          	lbu	a5,9(a0)
    80004b02:	14078563          	beqz	a5,80004c4c <filewrite+0x14e>
{
    80004b06:	715d                	addi	sp,sp,-80
    80004b08:	e486                	sd	ra,72(sp)
    80004b0a:	e0a2                	sd	s0,64(sp)
    80004b0c:	fc26                	sd	s1,56(sp)
    80004b0e:	f84a                	sd	s2,48(sp)
    80004b10:	f44e                	sd	s3,40(sp)
    80004b12:	f052                	sd	s4,32(sp)
    80004b14:	ec56                	sd	s5,24(sp)
    80004b16:	e85a                	sd	s6,16(sp)
    80004b18:	e45e                	sd	s7,8(sp)
    80004b1a:	e062                	sd	s8,0(sp)
    80004b1c:	0880                	addi	s0,sp,80
    80004b1e:	892a                	mv	s2,a0
    80004b20:	8aae                	mv	s5,a1
    80004b22:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b24:	411c                	lw	a5,0(a0)
    80004b26:	4705                	li	a4,1
    80004b28:	02e78263          	beq	a5,a4,80004b4c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b2c:	470d                	li	a4,3
    80004b2e:	02e78563          	beq	a5,a4,80004b58 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b32:	4709                	li	a4,2
    80004b34:	10e79463          	bne	a5,a4,80004c3c <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b38:	0ec05e63          	blez	a2,80004c34 <filewrite+0x136>
    int i = 0;
    80004b3c:	4981                	li	s3,0
    80004b3e:	6b05                	lui	s6,0x1
    80004b40:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004b44:	6b85                	lui	s7,0x1
    80004b46:	c00b8b9b          	addiw	s7,s7,-1024
    80004b4a:	a851                	j	80004bde <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004b4c:	6908                	ld	a0,16(a0)
    80004b4e:	00000097          	auipc	ra,0x0
    80004b52:	25e080e7          	jalr	606(ra) # 80004dac <pipewrite>
    80004b56:	a85d                	j	80004c0c <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b58:	02451783          	lh	a5,36(a0)
    80004b5c:	03079693          	slli	a3,a5,0x30
    80004b60:	92c1                	srli	a3,a3,0x30
    80004b62:	4725                	li	a4,9
    80004b64:	0ed76663          	bltu	a4,a3,80004c50 <filewrite+0x152>
    80004b68:	0792                	slli	a5,a5,0x4
    80004b6a:	00027717          	auipc	a4,0x27
    80004b6e:	57670713          	addi	a4,a4,1398 # 8002c0e0 <devsw>
    80004b72:	97ba                	add	a5,a5,a4
    80004b74:	679c                	ld	a5,8(a5)
    80004b76:	cff9                	beqz	a5,80004c54 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004b78:	4505                	li	a0,1
    80004b7a:	9782                	jalr	a5
    80004b7c:	a841                	j	80004c0c <filewrite+0x10e>
    80004b7e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b82:	00000097          	auipc	ra,0x0
    80004b86:	8ac080e7          	jalr	-1876(ra) # 8000442e <begin_op>
      ilock(f->ip);
    80004b8a:	01893503          	ld	a0,24(s2)
    80004b8e:	fffff097          	auipc	ra,0xfffff
    80004b92:	ed0080e7          	jalr	-304(ra) # 80003a5e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b96:	8762                	mv	a4,s8
    80004b98:	02092683          	lw	a3,32(s2)
    80004b9c:	01598633          	add	a2,s3,s5
    80004ba0:	4585                	li	a1,1
    80004ba2:	01893503          	ld	a0,24(s2)
    80004ba6:	fffff097          	auipc	ra,0xfffff
    80004baa:	264080e7          	jalr	612(ra) # 80003e0a <writei>
    80004bae:	84aa                	mv	s1,a0
    80004bb0:	02a05f63          	blez	a0,80004bee <filewrite+0xf0>
        f->off += r;
    80004bb4:	02092783          	lw	a5,32(s2)
    80004bb8:	9fa9                	addw	a5,a5,a0
    80004bba:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004bbe:	01893503          	ld	a0,24(s2)
    80004bc2:	fffff097          	auipc	ra,0xfffff
    80004bc6:	f5e080e7          	jalr	-162(ra) # 80003b20 <iunlock>
      end_op();
    80004bca:	00000097          	auipc	ra,0x0
    80004bce:	8e4080e7          	jalr	-1820(ra) # 800044ae <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004bd2:	049c1963          	bne	s8,s1,80004c24 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004bd6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004bda:	0349d663          	bge	s3,s4,80004c06 <filewrite+0x108>
      int n1 = n - i;
    80004bde:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004be2:	84be                	mv	s1,a5
    80004be4:	2781                	sext.w	a5,a5
    80004be6:	f8fb5ce3          	bge	s6,a5,80004b7e <filewrite+0x80>
    80004bea:	84de                	mv	s1,s7
    80004bec:	bf49                	j	80004b7e <filewrite+0x80>
      iunlock(f->ip);
    80004bee:	01893503          	ld	a0,24(s2)
    80004bf2:	fffff097          	auipc	ra,0xfffff
    80004bf6:	f2e080e7          	jalr	-210(ra) # 80003b20 <iunlock>
      end_op();
    80004bfa:	00000097          	auipc	ra,0x0
    80004bfe:	8b4080e7          	jalr	-1868(ra) # 800044ae <end_op>
      if(r < 0)
    80004c02:	fc04d8e3          	bgez	s1,80004bd2 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004c06:	8552                	mv	a0,s4
    80004c08:	033a1863          	bne	s4,s3,80004c38 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c0c:	60a6                	ld	ra,72(sp)
    80004c0e:	6406                	ld	s0,64(sp)
    80004c10:	74e2                	ld	s1,56(sp)
    80004c12:	7942                	ld	s2,48(sp)
    80004c14:	79a2                	ld	s3,40(sp)
    80004c16:	7a02                	ld	s4,32(sp)
    80004c18:	6ae2                	ld	s5,24(sp)
    80004c1a:	6b42                	ld	s6,16(sp)
    80004c1c:	6ba2                	ld	s7,8(sp)
    80004c1e:	6c02                	ld	s8,0(sp)
    80004c20:	6161                	addi	sp,sp,80
    80004c22:	8082                	ret
        panic("short filewrite");
    80004c24:	00004517          	auipc	a0,0x4
    80004c28:	b1450513          	addi	a0,a0,-1260 # 80008738 <syscalls+0x280>
    80004c2c:	ffffc097          	auipc	ra,0xffffc
    80004c30:	924080e7          	jalr	-1756(ra) # 80000550 <panic>
    int i = 0;
    80004c34:	4981                	li	s3,0
    80004c36:	bfc1                	j	80004c06 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004c38:	557d                	li	a0,-1
    80004c3a:	bfc9                	j	80004c0c <filewrite+0x10e>
    panic("filewrite");
    80004c3c:	00004517          	auipc	a0,0x4
    80004c40:	b0c50513          	addi	a0,a0,-1268 # 80008748 <syscalls+0x290>
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	90c080e7          	jalr	-1780(ra) # 80000550 <panic>
    return -1;
    80004c4c:	557d                	li	a0,-1
}
    80004c4e:	8082                	ret
      return -1;
    80004c50:	557d                	li	a0,-1
    80004c52:	bf6d                	j	80004c0c <filewrite+0x10e>
    80004c54:	557d                	li	a0,-1
    80004c56:	bf5d                	j	80004c0c <filewrite+0x10e>

0000000080004c58 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c58:	7179                	addi	sp,sp,-48
    80004c5a:	f406                	sd	ra,40(sp)
    80004c5c:	f022                	sd	s0,32(sp)
    80004c5e:	ec26                	sd	s1,24(sp)
    80004c60:	e84a                	sd	s2,16(sp)
    80004c62:	e44e                	sd	s3,8(sp)
    80004c64:	e052                	sd	s4,0(sp)
    80004c66:	1800                	addi	s0,sp,48
    80004c68:	84aa                	mv	s1,a0
    80004c6a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c6c:	0005b023          	sd	zero,0(a1)
    80004c70:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c74:	00000097          	auipc	ra,0x0
    80004c78:	bd2080e7          	jalr	-1070(ra) # 80004846 <filealloc>
    80004c7c:	e088                	sd	a0,0(s1)
    80004c7e:	c551                	beqz	a0,80004d0a <pipealloc+0xb2>
    80004c80:	00000097          	auipc	ra,0x0
    80004c84:	bc6080e7          	jalr	-1082(ra) # 80004846 <filealloc>
    80004c88:	00aa3023          	sd	a0,0(s4)
    80004c8c:	c92d                	beqz	a0,80004cfe <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	f8e080e7          	jalr	-114(ra) # 80000c1c <kalloc>
    80004c96:	892a                	mv	s2,a0
    80004c98:	c125                	beqz	a0,80004cf8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c9a:	4985                	li	s3,1
    80004c9c:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004ca0:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004ca4:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004ca8:	22052023          	sw	zero,544(a0)
  initlock(&pi->lock, "pipe");
    80004cac:	00004597          	auipc	a1,0x4
    80004cb0:	aac58593          	addi	a1,a1,-1364 # 80008758 <syscalls+0x2a0>
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	1f6080e7          	jalr	502(ra) # 80000eaa <initlock>
  (*f0)->type = FD_PIPE;
    80004cbc:	609c                	ld	a5,0(s1)
    80004cbe:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004cc2:	609c                	ld	a5,0(s1)
    80004cc4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004cc8:	609c                	ld	a5,0(s1)
    80004cca:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004cce:	609c                	ld	a5,0(s1)
    80004cd0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004cd4:	000a3783          	ld	a5,0(s4)
    80004cd8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004cdc:	000a3783          	ld	a5,0(s4)
    80004ce0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ce4:	000a3783          	ld	a5,0(s4)
    80004ce8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004cec:	000a3783          	ld	a5,0(s4)
    80004cf0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004cf4:	4501                	li	a0,0
    80004cf6:	a025                	j	80004d1e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004cf8:	6088                	ld	a0,0(s1)
    80004cfa:	e501                	bnez	a0,80004d02 <pipealloc+0xaa>
    80004cfc:	a039                	j	80004d0a <pipealloc+0xb2>
    80004cfe:	6088                	ld	a0,0(s1)
    80004d00:	c51d                	beqz	a0,80004d2e <pipealloc+0xd6>
    fileclose(*f0);
    80004d02:	00000097          	auipc	ra,0x0
    80004d06:	c00080e7          	jalr	-1024(ra) # 80004902 <fileclose>
  if(*f1)
    80004d0a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d0e:	557d                	li	a0,-1
  if(*f1)
    80004d10:	c799                	beqz	a5,80004d1e <pipealloc+0xc6>
    fileclose(*f1);
    80004d12:	853e                	mv	a0,a5
    80004d14:	00000097          	auipc	ra,0x0
    80004d18:	bee080e7          	jalr	-1042(ra) # 80004902 <fileclose>
  return -1;
    80004d1c:	557d                	li	a0,-1
}
    80004d1e:	70a2                	ld	ra,40(sp)
    80004d20:	7402                	ld	s0,32(sp)
    80004d22:	64e2                	ld	s1,24(sp)
    80004d24:	6942                	ld	s2,16(sp)
    80004d26:	69a2                	ld	s3,8(sp)
    80004d28:	6a02                	ld	s4,0(sp)
    80004d2a:	6145                	addi	sp,sp,48
    80004d2c:	8082                	ret
  return -1;
    80004d2e:	557d                	li	a0,-1
    80004d30:	b7fd                	j	80004d1e <pipealloc+0xc6>

0000000080004d32 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d32:	1101                	addi	sp,sp,-32
    80004d34:	ec06                	sd	ra,24(sp)
    80004d36:	e822                	sd	s0,16(sp)
    80004d38:	e426                	sd	s1,8(sp)
    80004d3a:	e04a                	sd	s2,0(sp)
    80004d3c:	1000                	addi	s0,sp,32
    80004d3e:	84aa                	mv	s1,a0
    80004d40:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d42:	ffffc097          	auipc	ra,0xffffc
    80004d46:	fec080e7          	jalr	-20(ra) # 80000d2e <acquire>
  if(writable){
    80004d4a:	04090263          	beqz	s2,80004d8e <pipeclose+0x5c>
    pi->writeopen = 0;
    80004d4e:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004d52:	22048513          	addi	a0,s1,544
    80004d56:	ffffe097          	auipc	ra,0xffffe
    80004d5a:	9b6080e7          	jalr	-1610(ra) # 8000270c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d5e:	2284b783          	ld	a5,552(s1)
    80004d62:	ef9d                	bnez	a5,80004da0 <pipeclose+0x6e>
    release(&pi->lock);
    80004d64:	8526                	mv	a0,s1
    80004d66:	ffffc097          	auipc	ra,0xffffc
    80004d6a:	098080e7          	jalr	152(ra) # 80000dfe <release>
#ifdef LAB_LOCK
    freelock(&pi->lock);
    80004d6e:	8526                	mv	a0,s1
    80004d70:	ffffc097          	auipc	ra,0xffffc
    80004d74:	0d6080e7          	jalr	214(ra) # 80000e46 <freelock>
#endif    
    kfree((char*)pi);
    80004d78:	8526                	mv	a0,s1
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	cb2080e7          	jalr	-846(ra) # 80000a2c <kfree>
  } else
    release(&pi->lock);
}
    80004d82:	60e2                	ld	ra,24(sp)
    80004d84:	6442                	ld	s0,16(sp)
    80004d86:	64a2                	ld	s1,8(sp)
    80004d88:	6902                	ld	s2,0(sp)
    80004d8a:	6105                	addi	sp,sp,32
    80004d8c:	8082                	ret
    pi->readopen = 0;
    80004d8e:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004d92:	22448513          	addi	a0,s1,548
    80004d96:	ffffe097          	auipc	ra,0xffffe
    80004d9a:	976080e7          	jalr	-1674(ra) # 8000270c <wakeup>
    80004d9e:	b7c1                	j	80004d5e <pipeclose+0x2c>
    release(&pi->lock);
    80004da0:	8526                	mv	a0,s1
    80004da2:	ffffc097          	auipc	ra,0xffffc
    80004da6:	05c080e7          	jalr	92(ra) # 80000dfe <release>
}
    80004daa:	bfe1                	j	80004d82 <pipeclose+0x50>

0000000080004dac <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004dac:	7119                	addi	sp,sp,-128
    80004dae:	fc86                	sd	ra,120(sp)
    80004db0:	f8a2                	sd	s0,112(sp)
    80004db2:	f4a6                	sd	s1,104(sp)
    80004db4:	f0ca                	sd	s2,96(sp)
    80004db6:	ecce                	sd	s3,88(sp)
    80004db8:	e8d2                	sd	s4,80(sp)
    80004dba:	e4d6                	sd	s5,72(sp)
    80004dbc:	e0da                	sd	s6,64(sp)
    80004dbe:	fc5e                	sd	s7,56(sp)
    80004dc0:	f862                	sd	s8,48(sp)
    80004dc2:	f466                	sd	s9,40(sp)
    80004dc4:	f06a                	sd	s10,32(sp)
    80004dc6:	ec6e                	sd	s11,24(sp)
    80004dc8:	0100                	addi	s0,sp,128
    80004dca:	84aa                	mv	s1,a0
    80004dcc:	8cae                	mv	s9,a1
    80004dce:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004dd0:	ffffd097          	auipc	ra,0xffffd
    80004dd4:	fa6080e7          	jalr	-90(ra) # 80001d76 <myproc>
    80004dd8:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004dda:	8526                	mv	a0,s1
    80004ddc:	ffffc097          	auipc	ra,0xffffc
    80004de0:	f52080e7          	jalr	-174(ra) # 80000d2e <acquire>
  for(i = 0; i < n; i++){
    80004de4:	0d605963          	blez	s6,80004eb6 <pipewrite+0x10a>
    80004de8:	89a6                	mv	s3,s1
    80004dea:	3b7d                	addiw	s6,s6,-1
    80004dec:	1b02                	slli	s6,s6,0x20
    80004dee:	020b5b13          	srli	s6,s6,0x20
    80004df2:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004df4:	22048a93          	addi	s5,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004df8:	22448a13          	addi	s4,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dfc:	5dfd                	li	s11,-1
    80004dfe:	000b8d1b          	sext.w	s10,s7
    80004e02:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004e04:	2204a783          	lw	a5,544(s1)
    80004e08:	2244a703          	lw	a4,548(s1)
    80004e0c:	2007879b          	addiw	a5,a5,512
    80004e10:	02f71b63          	bne	a4,a5,80004e46 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004e14:	2284a783          	lw	a5,552(s1)
    80004e18:	cbad                	beqz	a5,80004e8a <pipewrite+0xde>
    80004e1a:	03892783          	lw	a5,56(s2)
    80004e1e:	e7b5                	bnez	a5,80004e8a <pipewrite+0xde>
      wakeup(&pi->nread);
    80004e20:	8556                	mv	a0,s5
    80004e22:	ffffe097          	auipc	ra,0xffffe
    80004e26:	8ea080e7          	jalr	-1814(ra) # 8000270c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e2a:	85ce                	mv	a1,s3
    80004e2c:	8552                	mv	a0,s4
    80004e2e:	ffffd097          	auipc	ra,0xffffd
    80004e32:	758080e7          	jalr	1880(ra) # 80002586 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004e36:	2204a783          	lw	a5,544(s1)
    80004e3a:	2244a703          	lw	a4,548(s1)
    80004e3e:	2007879b          	addiw	a5,a5,512
    80004e42:	fcf709e3          	beq	a4,a5,80004e14 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e46:	4685                	li	a3,1
    80004e48:	019b8633          	add	a2,s7,s9
    80004e4c:	f8f40593          	addi	a1,s0,-113
    80004e50:	05893503          	ld	a0,88(s2)
    80004e54:	ffffd097          	auipc	ra,0xffffd
    80004e58:	ca2080e7          	jalr	-862(ra) # 80001af6 <copyin>
    80004e5c:	05b50e63          	beq	a0,s11,80004eb8 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e60:	2244a783          	lw	a5,548(s1)
    80004e64:	0017871b          	addiw	a4,a5,1
    80004e68:	22e4a223          	sw	a4,548(s1)
    80004e6c:	1ff7f793          	andi	a5,a5,511
    80004e70:	97a6                	add	a5,a5,s1
    80004e72:	f8f44703          	lbu	a4,-113(s0)
    80004e76:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80004e7a:	001d0c1b          	addiw	s8,s10,1
    80004e7e:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004e82:	036b8b63          	beq	s7,s6,80004eb8 <pipewrite+0x10c>
    80004e86:	8bbe                	mv	s7,a5
    80004e88:	bf9d                	j	80004dfe <pipewrite+0x52>
        release(&pi->lock);
    80004e8a:	8526                	mv	a0,s1
    80004e8c:	ffffc097          	auipc	ra,0xffffc
    80004e90:	f72080e7          	jalr	-142(ra) # 80000dfe <release>
        return -1;
    80004e94:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004e96:	8562                	mv	a0,s8
    80004e98:	70e6                	ld	ra,120(sp)
    80004e9a:	7446                	ld	s0,112(sp)
    80004e9c:	74a6                	ld	s1,104(sp)
    80004e9e:	7906                	ld	s2,96(sp)
    80004ea0:	69e6                	ld	s3,88(sp)
    80004ea2:	6a46                	ld	s4,80(sp)
    80004ea4:	6aa6                	ld	s5,72(sp)
    80004ea6:	6b06                	ld	s6,64(sp)
    80004ea8:	7be2                	ld	s7,56(sp)
    80004eaa:	7c42                	ld	s8,48(sp)
    80004eac:	7ca2                	ld	s9,40(sp)
    80004eae:	7d02                	ld	s10,32(sp)
    80004eb0:	6de2                	ld	s11,24(sp)
    80004eb2:	6109                	addi	sp,sp,128
    80004eb4:	8082                	ret
  for(i = 0; i < n; i++){
    80004eb6:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004eb8:	22048513          	addi	a0,s1,544
    80004ebc:	ffffe097          	auipc	ra,0xffffe
    80004ec0:	850080e7          	jalr	-1968(ra) # 8000270c <wakeup>
  release(&pi->lock);
    80004ec4:	8526                	mv	a0,s1
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	f38080e7          	jalr	-200(ra) # 80000dfe <release>
  return i;
    80004ece:	b7e1                	j	80004e96 <pipewrite+0xea>

0000000080004ed0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ed0:	715d                	addi	sp,sp,-80
    80004ed2:	e486                	sd	ra,72(sp)
    80004ed4:	e0a2                	sd	s0,64(sp)
    80004ed6:	fc26                	sd	s1,56(sp)
    80004ed8:	f84a                	sd	s2,48(sp)
    80004eda:	f44e                	sd	s3,40(sp)
    80004edc:	f052                	sd	s4,32(sp)
    80004ede:	ec56                	sd	s5,24(sp)
    80004ee0:	e85a                	sd	s6,16(sp)
    80004ee2:	0880                	addi	s0,sp,80
    80004ee4:	84aa                	mv	s1,a0
    80004ee6:	892e                	mv	s2,a1
    80004ee8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004eea:	ffffd097          	auipc	ra,0xffffd
    80004eee:	e8c080e7          	jalr	-372(ra) # 80001d76 <myproc>
    80004ef2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ef4:	8b26                	mv	s6,s1
    80004ef6:	8526                	mv	a0,s1
    80004ef8:	ffffc097          	auipc	ra,0xffffc
    80004efc:	e36080e7          	jalr	-458(ra) # 80000d2e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f00:	2204a703          	lw	a4,544(s1)
    80004f04:	2244a783          	lw	a5,548(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f08:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f0c:	02f71463          	bne	a4,a5,80004f34 <piperead+0x64>
    80004f10:	22c4a783          	lw	a5,556(s1)
    80004f14:	c385                	beqz	a5,80004f34 <piperead+0x64>
    if(pr->killed){
    80004f16:	038a2783          	lw	a5,56(s4)
    80004f1a:	ebc1                	bnez	a5,80004faa <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f1c:	85da                	mv	a1,s6
    80004f1e:	854e                	mv	a0,s3
    80004f20:	ffffd097          	auipc	ra,0xffffd
    80004f24:	666080e7          	jalr	1638(ra) # 80002586 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f28:	2204a703          	lw	a4,544(s1)
    80004f2c:	2244a783          	lw	a5,548(s1)
    80004f30:	fef700e3          	beq	a4,a5,80004f10 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f34:	09505263          	blez	s5,80004fb8 <piperead+0xe8>
    80004f38:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f3a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004f3c:	2204a783          	lw	a5,544(s1)
    80004f40:	2244a703          	lw	a4,548(s1)
    80004f44:	02f70d63          	beq	a4,a5,80004f7e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f48:	0017871b          	addiw	a4,a5,1
    80004f4c:	22e4a023          	sw	a4,544(s1)
    80004f50:	1ff7f793          	andi	a5,a5,511
    80004f54:	97a6                	add	a5,a5,s1
    80004f56:	0207c783          	lbu	a5,32(a5)
    80004f5a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f5e:	4685                	li	a3,1
    80004f60:	fbf40613          	addi	a2,s0,-65
    80004f64:	85ca                	mv	a1,s2
    80004f66:	058a3503          	ld	a0,88(s4)
    80004f6a:	ffffd097          	auipc	ra,0xffffd
    80004f6e:	b00080e7          	jalr	-1280(ra) # 80001a6a <copyout>
    80004f72:	01650663          	beq	a0,s6,80004f7e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f76:	2985                	addiw	s3,s3,1
    80004f78:	0905                	addi	s2,s2,1
    80004f7a:	fd3a91e3          	bne	s5,s3,80004f3c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f7e:	22448513          	addi	a0,s1,548
    80004f82:	ffffd097          	auipc	ra,0xffffd
    80004f86:	78a080e7          	jalr	1930(ra) # 8000270c <wakeup>
  release(&pi->lock);
    80004f8a:	8526                	mv	a0,s1
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	e72080e7          	jalr	-398(ra) # 80000dfe <release>
  return i;
}
    80004f94:	854e                	mv	a0,s3
    80004f96:	60a6                	ld	ra,72(sp)
    80004f98:	6406                	ld	s0,64(sp)
    80004f9a:	74e2                	ld	s1,56(sp)
    80004f9c:	7942                	ld	s2,48(sp)
    80004f9e:	79a2                	ld	s3,40(sp)
    80004fa0:	7a02                	ld	s4,32(sp)
    80004fa2:	6ae2                	ld	s5,24(sp)
    80004fa4:	6b42                	ld	s6,16(sp)
    80004fa6:	6161                	addi	sp,sp,80
    80004fa8:	8082                	ret
      release(&pi->lock);
    80004faa:	8526                	mv	a0,s1
    80004fac:	ffffc097          	auipc	ra,0xffffc
    80004fb0:	e52080e7          	jalr	-430(ra) # 80000dfe <release>
      return -1;
    80004fb4:	59fd                	li	s3,-1
    80004fb6:	bff9                	j	80004f94 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fb8:	4981                	li	s3,0
    80004fba:	b7d1                	j	80004f7e <piperead+0xae>

0000000080004fbc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004fbc:	df010113          	addi	sp,sp,-528
    80004fc0:	20113423          	sd	ra,520(sp)
    80004fc4:	20813023          	sd	s0,512(sp)
    80004fc8:	ffa6                	sd	s1,504(sp)
    80004fca:	fbca                	sd	s2,496(sp)
    80004fcc:	f7ce                	sd	s3,488(sp)
    80004fce:	f3d2                	sd	s4,480(sp)
    80004fd0:	efd6                	sd	s5,472(sp)
    80004fd2:	ebda                	sd	s6,464(sp)
    80004fd4:	e7de                	sd	s7,456(sp)
    80004fd6:	e3e2                	sd	s8,448(sp)
    80004fd8:	ff66                	sd	s9,440(sp)
    80004fda:	fb6a                	sd	s10,432(sp)
    80004fdc:	f76e                	sd	s11,424(sp)
    80004fde:	0c00                	addi	s0,sp,528
    80004fe0:	84aa                	mv	s1,a0
    80004fe2:	dea43c23          	sd	a0,-520(s0)
    80004fe6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004fea:	ffffd097          	auipc	ra,0xffffd
    80004fee:	d8c080e7          	jalr	-628(ra) # 80001d76 <myproc>
    80004ff2:	892a                	mv	s2,a0

  begin_op();
    80004ff4:	fffff097          	auipc	ra,0xfffff
    80004ff8:	43a080e7          	jalr	1082(ra) # 8000442e <begin_op>

  if((ip = namei(path)) == 0){
    80004ffc:	8526                	mv	a0,s1
    80004ffe:	fffff097          	auipc	ra,0xfffff
    80005002:	214080e7          	jalr	532(ra) # 80004212 <namei>
    80005006:	c92d                	beqz	a0,80005078 <exec+0xbc>
    80005008:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000500a:	fffff097          	auipc	ra,0xfffff
    8000500e:	a54080e7          	jalr	-1452(ra) # 80003a5e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005012:	04000713          	li	a4,64
    80005016:	4681                	li	a3,0
    80005018:	e4840613          	addi	a2,s0,-440
    8000501c:	4581                	li	a1,0
    8000501e:	8526                	mv	a0,s1
    80005020:	fffff097          	auipc	ra,0xfffff
    80005024:	cf2080e7          	jalr	-782(ra) # 80003d12 <readi>
    80005028:	04000793          	li	a5,64
    8000502c:	00f51a63          	bne	a0,a5,80005040 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005030:	e4842703          	lw	a4,-440(s0)
    80005034:	464c47b7          	lui	a5,0x464c4
    80005038:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000503c:	04f70463          	beq	a4,a5,80005084 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005040:	8526                	mv	a0,s1
    80005042:	fffff097          	auipc	ra,0xfffff
    80005046:	c7e080e7          	jalr	-898(ra) # 80003cc0 <iunlockput>
    end_op();
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	464080e7          	jalr	1124(ra) # 800044ae <end_op>
  }
  return -1;
    80005052:	557d                	li	a0,-1
}
    80005054:	20813083          	ld	ra,520(sp)
    80005058:	20013403          	ld	s0,512(sp)
    8000505c:	74fe                	ld	s1,504(sp)
    8000505e:	795e                	ld	s2,496(sp)
    80005060:	79be                	ld	s3,488(sp)
    80005062:	7a1e                	ld	s4,480(sp)
    80005064:	6afe                	ld	s5,472(sp)
    80005066:	6b5e                	ld	s6,464(sp)
    80005068:	6bbe                	ld	s7,456(sp)
    8000506a:	6c1e                	ld	s8,448(sp)
    8000506c:	7cfa                	ld	s9,440(sp)
    8000506e:	7d5a                	ld	s10,432(sp)
    80005070:	7dba                	ld	s11,424(sp)
    80005072:	21010113          	addi	sp,sp,528
    80005076:	8082                	ret
    end_op();
    80005078:	fffff097          	auipc	ra,0xfffff
    8000507c:	436080e7          	jalr	1078(ra) # 800044ae <end_op>
    return -1;
    80005080:	557d                	li	a0,-1
    80005082:	bfc9                	j	80005054 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005084:	854a                	mv	a0,s2
    80005086:	ffffd097          	auipc	ra,0xffffd
    8000508a:	db4080e7          	jalr	-588(ra) # 80001e3a <proc_pagetable>
    8000508e:	8baa                	mv	s7,a0
    80005090:	d945                	beqz	a0,80005040 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005092:	e6842983          	lw	s3,-408(s0)
    80005096:	e8045783          	lhu	a5,-384(s0)
    8000509a:	c7ad                	beqz	a5,80005104 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000509c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000509e:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    800050a0:	6c85                	lui	s9,0x1
    800050a2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800050a6:	def43823          	sd	a5,-528(s0)
    800050aa:	a42d                	j	800052d4 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050ac:	00003517          	auipc	a0,0x3
    800050b0:	6b450513          	addi	a0,a0,1716 # 80008760 <syscalls+0x2a8>
    800050b4:	ffffb097          	auipc	ra,0xffffb
    800050b8:	49c080e7          	jalr	1180(ra) # 80000550 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050bc:	8756                	mv	a4,s5
    800050be:	012d86bb          	addw	a3,s11,s2
    800050c2:	4581                	li	a1,0
    800050c4:	8526                	mv	a0,s1
    800050c6:	fffff097          	auipc	ra,0xfffff
    800050ca:	c4c080e7          	jalr	-948(ra) # 80003d12 <readi>
    800050ce:	2501                	sext.w	a0,a0
    800050d0:	1aaa9963          	bne	s5,a0,80005282 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800050d4:	6785                	lui	a5,0x1
    800050d6:	0127893b          	addw	s2,a5,s2
    800050da:	77fd                	lui	a5,0xfffff
    800050dc:	01478a3b          	addw	s4,a5,s4
    800050e0:	1f897163          	bgeu	s2,s8,800052c2 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800050e4:	02091593          	slli	a1,s2,0x20
    800050e8:	9181                	srli	a1,a1,0x20
    800050ea:	95ea                	add	a1,a1,s10
    800050ec:	855e                	mv	a0,s7
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	3ba080e7          	jalr	954(ra) # 800014a8 <walkaddr>
    800050f6:	862a                	mv	a2,a0
    if(pa == 0)
    800050f8:	d955                	beqz	a0,800050ac <exec+0xf0>
      n = PGSIZE;
    800050fa:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800050fc:	fd9a70e3          	bgeu	s4,s9,800050bc <exec+0x100>
      n = sz - i;
    80005100:	8ad2                	mv	s5,s4
    80005102:	bf6d                	j	800050bc <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005104:	4901                	li	s2,0
  iunlockput(ip);
    80005106:	8526                	mv	a0,s1
    80005108:	fffff097          	auipc	ra,0xfffff
    8000510c:	bb8080e7          	jalr	-1096(ra) # 80003cc0 <iunlockput>
  end_op();
    80005110:	fffff097          	auipc	ra,0xfffff
    80005114:	39e080e7          	jalr	926(ra) # 800044ae <end_op>
  p = myproc();
    80005118:	ffffd097          	auipc	ra,0xffffd
    8000511c:	c5e080e7          	jalr	-930(ra) # 80001d76 <myproc>
    80005120:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005122:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80005126:	6785                	lui	a5,0x1
    80005128:	17fd                	addi	a5,a5,-1
    8000512a:	993e                	add	s2,s2,a5
    8000512c:	757d                	lui	a0,0xfffff
    8000512e:	00a977b3          	and	a5,s2,a0
    80005132:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005136:	6609                	lui	a2,0x2
    80005138:	963e                	add	a2,a2,a5
    8000513a:	85be                	mv	a1,a5
    8000513c:	855e                	mv	a0,s7
    8000513e:	ffffc097          	auipc	ra,0xffffc
    80005142:	6dc080e7          	jalr	1756(ra) # 8000181a <uvmalloc>
    80005146:	8b2a                	mv	s6,a0
  ip = 0;
    80005148:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000514a:	12050c63          	beqz	a0,80005282 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000514e:	75f9                	lui	a1,0xffffe
    80005150:	95aa                	add	a1,a1,a0
    80005152:	855e                	mv	a0,s7
    80005154:	ffffd097          	auipc	ra,0xffffd
    80005158:	8e4080e7          	jalr	-1820(ra) # 80001a38 <uvmclear>
  stackbase = sp - PGSIZE;
    8000515c:	7c7d                	lui	s8,0xfffff
    8000515e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005160:	e0043783          	ld	a5,-512(s0)
    80005164:	6388                	ld	a0,0(a5)
    80005166:	c535                	beqz	a0,800051d2 <exec+0x216>
    80005168:	e8840993          	addi	s3,s0,-376
    8000516c:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005170:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005172:	ffffc097          	auipc	ra,0xffffc
    80005176:	124080e7          	jalr	292(ra) # 80001296 <strlen>
    8000517a:	2505                	addiw	a0,a0,1
    8000517c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005180:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005184:	13896363          	bltu	s2,s8,800052aa <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005188:	e0043d83          	ld	s11,-512(s0)
    8000518c:	000dba03          	ld	s4,0(s11)
    80005190:	8552                	mv	a0,s4
    80005192:	ffffc097          	auipc	ra,0xffffc
    80005196:	104080e7          	jalr	260(ra) # 80001296 <strlen>
    8000519a:	0015069b          	addiw	a3,a0,1
    8000519e:	8652                	mv	a2,s4
    800051a0:	85ca                	mv	a1,s2
    800051a2:	855e                	mv	a0,s7
    800051a4:	ffffd097          	auipc	ra,0xffffd
    800051a8:	8c6080e7          	jalr	-1850(ra) # 80001a6a <copyout>
    800051ac:	10054363          	bltz	a0,800052b2 <exec+0x2f6>
    ustack[argc] = sp;
    800051b0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051b4:	0485                	addi	s1,s1,1
    800051b6:	008d8793          	addi	a5,s11,8
    800051ba:	e0f43023          	sd	a5,-512(s0)
    800051be:	008db503          	ld	a0,8(s11)
    800051c2:	c911                	beqz	a0,800051d6 <exec+0x21a>
    if(argc >= MAXARG)
    800051c4:	09a1                	addi	s3,s3,8
    800051c6:	fb3c96e3          	bne	s9,s3,80005172 <exec+0x1b6>
  sz = sz1;
    800051ca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051ce:	4481                	li	s1,0
    800051d0:	a84d                	j	80005282 <exec+0x2c6>
  sp = sz;
    800051d2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800051d4:	4481                	li	s1,0
  ustack[argc] = 0;
    800051d6:	00349793          	slli	a5,s1,0x3
    800051da:	f9040713          	addi	a4,s0,-112
    800051de:	97ba                	add	a5,a5,a4
    800051e0:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    800051e4:	00148693          	addi	a3,s1,1
    800051e8:	068e                	slli	a3,a3,0x3
    800051ea:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800051ee:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800051f2:	01897663          	bgeu	s2,s8,800051fe <exec+0x242>
  sz = sz1;
    800051f6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051fa:	4481                	li	s1,0
    800051fc:	a059                	j	80005282 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800051fe:	e8840613          	addi	a2,s0,-376
    80005202:	85ca                	mv	a1,s2
    80005204:	855e                	mv	a0,s7
    80005206:	ffffd097          	auipc	ra,0xffffd
    8000520a:	864080e7          	jalr	-1948(ra) # 80001a6a <copyout>
    8000520e:	0a054663          	bltz	a0,800052ba <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005212:	060ab783          	ld	a5,96(s5)
    80005216:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000521a:	df843783          	ld	a5,-520(s0)
    8000521e:	0007c703          	lbu	a4,0(a5)
    80005222:	cf11                	beqz	a4,8000523e <exec+0x282>
    80005224:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005226:	02f00693          	li	a3,47
    8000522a:	a029                	j	80005234 <exec+0x278>
  for(last=s=path; *s; s++)
    8000522c:	0785                	addi	a5,a5,1
    8000522e:	fff7c703          	lbu	a4,-1(a5)
    80005232:	c711                	beqz	a4,8000523e <exec+0x282>
    if(*s == '/')
    80005234:	fed71ce3          	bne	a4,a3,8000522c <exec+0x270>
      last = s+1;
    80005238:	def43c23          	sd	a5,-520(s0)
    8000523c:	bfc5                	j	8000522c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000523e:	4641                	li	a2,16
    80005240:	df843583          	ld	a1,-520(s0)
    80005244:	160a8513          	addi	a0,s5,352
    80005248:	ffffc097          	auipc	ra,0xffffc
    8000524c:	01c080e7          	jalr	28(ra) # 80001264 <safestrcpy>
  oldpagetable = p->pagetable;
    80005250:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    80005254:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    80005258:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000525c:	060ab783          	ld	a5,96(s5)
    80005260:	e6043703          	ld	a4,-416(s0)
    80005264:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005266:	060ab783          	ld	a5,96(s5)
    8000526a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000526e:	85ea                	mv	a1,s10
    80005270:	ffffd097          	auipc	ra,0xffffd
    80005274:	c66080e7          	jalr	-922(ra) # 80001ed6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005278:	0004851b          	sext.w	a0,s1
    8000527c:	bbe1                	j	80005054 <exec+0x98>
    8000527e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005282:	e0843583          	ld	a1,-504(s0)
    80005286:	855e                	mv	a0,s7
    80005288:	ffffd097          	auipc	ra,0xffffd
    8000528c:	c4e080e7          	jalr	-946(ra) # 80001ed6 <proc_freepagetable>
  if(ip){
    80005290:	da0498e3          	bnez	s1,80005040 <exec+0x84>
  return -1;
    80005294:	557d                	li	a0,-1
    80005296:	bb7d                	j	80005054 <exec+0x98>
    80005298:	e1243423          	sd	s2,-504(s0)
    8000529c:	b7dd                	j	80005282 <exec+0x2c6>
    8000529e:	e1243423          	sd	s2,-504(s0)
    800052a2:	b7c5                	j	80005282 <exec+0x2c6>
    800052a4:	e1243423          	sd	s2,-504(s0)
    800052a8:	bfe9                	j	80005282 <exec+0x2c6>
  sz = sz1;
    800052aa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052ae:	4481                	li	s1,0
    800052b0:	bfc9                	j	80005282 <exec+0x2c6>
  sz = sz1;
    800052b2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052b6:	4481                	li	s1,0
    800052b8:	b7e9                	j	80005282 <exec+0x2c6>
  sz = sz1;
    800052ba:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052be:	4481                	li	s1,0
    800052c0:	b7c9                	j	80005282 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052c2:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052c6:	2b05                	addiw	s6,s6,1
    800052c8:	0389899b          	addiw	s3,s3,56
    800052cc:	e8045783          	lhu	a5,-384(s0)
    800052d0:	e2fb5be3          	bge	s6,a5,80005106 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800052d4:	2981                	sext.w	s3,s3
    800052d6:	03800713          	li	a4,56
    800052da:	86ce                	mv	a3,s3
    800052dc:	e1040613          	addi	a2,s0,-496
    800052e0:	4581                	li	a1,0
    800052e2:	8526                	mv	a0,s1
    800052e4:	fffff097          	auipc	ra,0xfffff
    800052e8:	a2e080e7          	jalr	-1490(ra) # 80003d12 <readi>
    800052ec:	03800793          	li	a5,56
    800052f0:	f8f517e3          	bne	a0,a5,8000527e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800052f4:	e1042783          	lw	a5,-496(s0)
    800052f8:	4705                	li	a4,1
    800052fa:	fce796e3          	bne	a5,a4,800052c6 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800052fe:	e3843603          	ld	a2,-456(s0)
    80005302:	e3043783          	ld	a5,-464(s0)
    80005306:	f8f669e3          	bltu	a2,a5,80005298 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000530a:	e2043783          	ld	a5,-480(s0)
    8000530e:	963e                	add	a2,a2,a5
    80005310:	f8f667e3          	bltu	a2,a5,8000529e <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005314:	85ca                	mv	a1,s2
    80005316:	855e                	mv	a0,s7
    80005318:	ffffc097          	auipc	ra,0xffffc
    8000531c:	502080e7          	jalr	1282(ra) # 8000181a <uvmalloc>
    80005320:	e0a43423          	sd	a0,-504(s0)
    80005324:	d141                	beqz	a0,800052a4 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005326:	e2043d03          	ld	s10,-480(s0)
    8000532a:	df043783          	ld	a5,-528(s0)
    8000532e:	00fd77b3          	and	a5,s10,a5
    80005332:	fba1                	bnez	a5,80005282 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005334:	e1842d83          	lw	s11,-488(s0)
    80005338:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000533c:	f80c03e3          	beqz	s8,800052c2 <exec+0x306>
    80005340:	8a62                	mv	s4,s8
    80005342:	4901                	li	s2,0
    80005344:	b345                	j	800050e4 <exec+0x128>

0000000080005346 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005346:	7179                	addi	sp,sp,-48
    80005348:	f406                	sd	ra,40(sp)
    8000534a:	f022                	sd	s0,32(sp)
    8000534c:	ec26                	sd	s1,24(sp)
    8000534e:	e84a                	sd	s2,16(sp)
    80005350:	1800                	addi	s0,sp,48
    80005352:	892e                	mv	s2,a1
    80005354:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005356:	fdc40593          	addi	a1,s0,-36
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	ada080e7          	jalr	-1318(ra) # 80002e34 <argint>
    80005362:	04054063          	bltz	a0,800053a2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005366:	fdc42703          	lw	a4,-36(s0)
    8000536a:	47bd                	li	a5,15
    8000536c:	02e7ed63          	bltu	a5,a4,800053a6 <argfd+0x60>
    80005370:	ffffd097          	auipc	ra,0xffffd
    80005374:	a06080e7          	jalr	-1530(ra) # 80001d76 <myproc>
    80005378:	fdc42703          	lw	a4,-36(s0)
    8000537c:	01a70793          	addi	a5,a4,26
    80005380:	078e                	slli	a5,a5,0x3
    80005382:	953e                	add	a0,a0,a5
    80005384:	651c                	ld	a5,8(a0)
    80005386:	c395                	beqz	a5,800053aa <argfd+0x64>
    return -1;
  if(pfd)
    80005388:	00090463          	beqz	s2,80005390 <argfd+0x4a>
    *pfd = fd;
    8000538c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005390:	4501                	li	a0,0
  if(pf)
    80005392:	c091                	beqz	s1,80005396 <argfd+0x50>
    *pf = f;
    80005394:	e09c                	sd	a5,0(s1)
}
    80005396:	70a2                	ld	ra,40(sp)
    80005398:	7402                	ld	s0,32(sp)
    8000539a:	64e2                	ld	s1,24(sp)
    8000539c:	6942                	ld	s2,16(sp)
    8000539e:	6145                	addi	sp,sp,48
    800053a0:	8082                	ret
    return -1;
    800053a2:	557d                	li	a0,-1
    800053a4:	bfcd                	j	80005396 <argfd+0x50>
    return -1;
    800053a6:	557d                	li	a0,-1
    800053a8:	b7fd                	j	80005396 <argfd+0x50>
    800053aa:	557d                	li	a0,-1
    800053ac:	b7ed                	j	80005396 <argfd+0x50>

00000000800053ae <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053ae:	1101                	addi	sp,sp,-32
    800053b0:	ec06                	sd	ra,24(sp)
    800053b2:	e822                	sd	s0,16(sp)
    800053b4:	e426                	sd	s1,8(sp)
    800053b6:	1000                	addi	s0,sp,32
    800053b8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053ba:	ffffd097          	auipc	ra,0xffffd
    800053be:	9bc080e7          	jalr	-1604(ra) # 80001d76 <myproc>
    800053c2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800053c4:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffcd0b0>
    800053c8:	4501                	li	a0,0
    800053ca:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800053cc:	6398                	ld	a4,0(a5)
    800053ce:	cb19                	beqz	a4,800053e4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800053d0:	2505                	addiw	a0,a0,1
    800053d2:	07a1                	addi	a5,a5,8
    800053d4:	fed51ce3          	bne	a0,a3,800053cc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053d8:	557d                	li	a0,-1
}
    800053da:	60e2                	ld	ra,24(sp)
    800053dc:	6442                	ld	s0,16(sp)
    800053de:	64a2                	ld	s1,8(sp)
    800053e0:	6105                	addi	sp,sp,32
    800053e2:	8082                	ret
      p->ofile[fd] = f;
    800053e4:	01a50793          	addi	a5,a0,26
    800053e8:	078e                	slli	a5,a5,0x3
    800053ea:	963e                	add	a2,a2,a5
    800053ec:	e604                	sd	s1,8(a2)
      return fd;
    800053ee:	b7f5                	j	800053da <fdalloc+0x2c>

00000000800053f0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800053f0:	715d                	addi	sp,sp,-80
    800053f2:	e486                	sd	ra,72(sp)
    800053f4:	e0a2                	sd	s0,64(sp)
    800053f6:	fc26                	sd	s1,56(sp)
    800053f8:	f84a                	sd	s2,48(sp)
    800053fa:	f44e                	sd	s3,40(sp)
    800053fc:	f052                	sd	s4,32(sp)
    800053fe:	ec56                	sd	s5,24(sp)
    80005400:	0880                	addi	s0,sp,80
    80005402:	89ae                	mv	s3,a1
    80005404:	8ab2                	mv	s5,a2
    80005406:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005408:	fb040593          	addi	a1,s0,-80
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	e24080e7          	jalr	-476(ra) # 80004230 <nameiparent>
    80005414:	892a                	mv	s2,a0
    80005416:	12050f63          	beqz	a0,80005554 <create+0x164>
    return 0;

  ilock(dp);
    8000541a:	ffffe097          	auipc	ra,0xffffe
    8000541e:	644080e7          	jalr	1604(ra) # 80003a5e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005422:	4601                	li	a2,0
    80005424:	fb040593          	addi	a1,s0,-80
    80005428:	854a                	mv	a0,s2
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	b16080e7          	jalr	-1258(ra) # 80003f40 <dirlookup>
    80005432:	84aa                	mv	s1,a0
    80005434:	c921                	beqz	a0,80005484 <create+0x94>
    iunlockput(dp);
    80005436:	854a                	mv	a0,s2
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	888080e7          	jalr	-1912(ra) # 80003cc0 <iunlockput>
    ilock(ip);
    80005440:	8526                	mv	a0,s1
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	61c080e7          	jalr	1564(ra) # 80003a5e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000544a:	2981                	sext.w	s3,s3
    8000544c:	4789                	li	a5,2
    8000544e:	02f99463          	bne	s3,a5,80005476 <create+0x86>
    80005452:	04c4d783          	lhu	a5,76(s1)
    80005456:	37f9                	addiw	a5,a5,-2
    80005458:	17c2                	slli	a5,a5,0x30
    8000545a:	93c1                	srli	a5,a5,0x30
    8000545c:	4705                	li	a4,1
    8000545e:	00f76c63          	bltu	a4,a5,80005476 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005462:	8526                	mv	a0,s1
    80005464:	60a6                	ld	ra,72(sp)
    80005466:	6406                	ld	s0,64(sp)
    80005468:	74e2                	ld	s1,56(sp)
    8000546a:	7942                	ld	s2,48(sp)
    8000546c:	79a2                	ld	s3,40(sp)
    8000546e:	7a02                	ld	s4,32(sp)
    80005470:	6ae2                	ld	s5,24(sp)
    80005472:	6161                	addi	sp,sp,80
    80005474:	8082                	ret
    iunlockput(ip);
    80005476:	8526                	mv	a0,s1
    80005478:	fffff097          	auipc	ra,0xfffff
    8000547c:	848080e7          	jalr	-1976(ra) # 80003cc0 <iunlockput>
    return 0;
    80005480:	4481                	li	s1,0
    80005482:	b7c5                	j	80005462 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005484:	85ce                	mv	a1,s3
    80005486:	00092503          	lw	a0,0(s2)
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	43c080e7          	jalr	1084(ra) # 800038c6 <ialloc>
    80005492:	84aa                	mv	s1,a0
    80005494:	c529                	beqz	a0,800054de <create+0xee>
  ilock(ip);
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	5c8080e7          	jalr	1480(ra) # 80003a5e <ilock>
  ip->major = major;
    8000549e:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    800054a2:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    800054a6:	4785                	li	a5,1
    800054a8:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    800054ac:	8526                	mv	a0,s1
    800054ae:	ffffe097          	auipc	ra,0xffffe
    800054b2:	4e6080e7          	jalr	1254(ra) # 80003994 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054b6:	2981                	sext.w	s3,s3
    800054b8:	4785                	li	a5,1
    800054ba:	02f98a63          	beq	s3,a5,800054ee <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800054be:	40d0                	lw	a2,4(s1)
    800054c0:	fb040593          	addi	a1,s0,-80
    800054c4:	854a                	mv	a0,s2
    800054c6:	fffff097          	auipc	ra,0xfffff
    800054ca:	c8a080e7          	jalr	-886(ra) # 80004150 <dirlink>
    800054ce:	06054b63          	bltz	a0,80005544 <create+0x154>
  iunlockput(dp);
    800054d2:	854a                	mv	a0,s2
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	7ec080e7          	jalr	2028(ra) # 80003cc0 <iunlockput>
  return ip;
    800054dc:	b759                	j	80005462 <create+0x72>
    panic("create: ialloc");
    800054de:	00003517          	auipc	a0,0x3
    800054e2:	2a250513          	addi	a0,a0,674 # 80008780 <syscalls+0x2c8>
    800054e6:	ffffb097          	auipc	ra,0xffffb
    800054ea:	06a080e7          	jalr	106(ra) # 80000550 <panic>
    dp->nlink++;  // for ".."
    800054ee:	05295783          	lhu	a5,82(s2)
    800054f2:	2785                	addiw	a5,a5,1
    800054f4:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    800054f8:	854a                	mv	a0,s2
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	49a080e7          	jalr	1178(ra) # 80003994 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005502:	40d0                	lw	a2,4(s1)
    80005504:	00003597          	auipc	a1,0x3
    80005508:	28c58593          	addi	a1,a1,652 # 80008790 <syscalls+0x2d8>
    8000550c:	8526                	mv	a0,s1
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	c42080e7          	jalr	-958(ra) # 80004150 <dirlink>
    80005516:	00054f63          	bltz	a0,80005534 <create+0x144>
    8000551a:	00492603          	lw	a2,4(s2)
    8000551e:	00003597          	auipc	a1,0x3
    80005522:	27a58593          	addi	a1,a1,634 # 80008798 <syscalls+0x2e0>
    80005526:	8526                	mv	a0,s1
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	c28080e7          	jalr	-984(ra) # 80004150 <dirlink>
    80005530:	f80557e3          	bgez	a0,800054be <create+0xce>
      panic("create dots");
    80005534:	00003517          	auipc	a0,0x3
    80005538:	26c50513          	addi	a0,a0,620 # 800087a0 <syscalls+0x2e8>
    8000553c:	ffffb097          	auipc	ra,0xffffb
    80005540:	014080e7          	jalr	20(ra) # 80000550 <panic>
    panic("create: dirlink");
    80005544:	00003517          	auipc	a0,0x3
    80005548:	26c50513          	addi	a0,a0,620 # 800087b0 <syscalls+0x2f8>
    8000554c:	ffffb097          	auipc	ra,0xffffb
    80005550:	004080e7          	jalr	4(ra) # 80000550 <panic>
    return 0;
    80005554:	84aa                	mv	s1,a0
    80005556:	b731                	j	80005462 <create+0x72>

0000000080005558 <sys_dup>:
{
    80005558:	7179                	addi	sp,sp,-48
    8000555a:	f406                	sd	ra,40(sp)
    8000555c:	f022                	sd	s0,32(sp)
    8000555e:	ec26                	sd	s1,24(sp)
    80005560:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005562:	fd840613          	addi	a2,s0,-40
    80005566:	4581                	li	a1,0
    80005568:	4501                	li	a0,0
    8000556a:	00000097          	auipc	ra,0x0
    8000556e:	ddc080e7          	jalr	-548(ra) # 80005346 <argfd>
    return -1;
    80005572:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005574:	02054363          	bltz	a0,8000559a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005578:	fd843503          	ld	a0,-40(s0)
    8000557c:	00000097          	auipc	ra,0x0
    80005580:	e32080e7          	jalr	-462(ra) # 800053ae <fdalloc>
    80005584:	84aa                	mv	s1,a0
    return -1;
    80005586:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005588:	00054963          	bltz	a0,8000559a <sys_dup+0x42>
  filedup(f);
    8000558c:	fd843503          	ld	a0,-40(s0)
    80005590:	fffff097          	auipc	ra,0xfffff
    80005594:	320080e7          	jalr	800(ra) # 800048b0 <filedup>
  return fd;
    80005598:	87a6                	mv	a5,s1
}
    8000559a:	853e                	mv	a0,a5
    8000559c:	70a2                	ld	ra,40(sp)
    8000559e:	7402                	ld	s0,32(sp)
    800055a0:	64e2                	ld	s1,24(sp)
    800055a2:	6145                	addi	sp,sp,48
    800055a4:	8082                	ret

00000000800055a6 <sys_read>:
{
    800055a6:	7179                	addi	sp,sp,-48
    800055a8:	f406                	sd	ra,40(sp)
    800055aa:	f022                	sd	s0,32(sp)
    800055ac:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ae:	fe840613          	addi	a2,s0,-24
    800055b2:	4581                	li	a1,0
    800055b4:	4501                	li	a0,0
    800055b6:	00000097          	auipc	ra,0x0
    800055ba:	d90080e7          	jalr	-624(ra) # 80005346 <argfd>
    return -1;
    800055be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055c0:	04054163          	bltz	a0,80005602 <sys_read+0x5c>
    800055c4:	fe440593          	addi	a1,s0,-28
    800055c8:	4509                	li	a0,2
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	86a080e7          	jalr	-1942(ra) # 80002e34 <argint>
    return -1;
    800055d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055d4:	02054763          	bltz	a0,80005602 <sys_read+0x5c>
    800055d8:	fd840593          	addi	a1,s0,-40
    800055dc:	4505                	li	a0,1
    800055de:	ffffe097          	auipc	ra,0xffffe
    800055e2:	878080e7          	jalr	-1928(ra) # 80002e56 <argaddr>
    return -1;
    800055e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055e8:	00054d63          	bltz	a0,80005602 <sys_read+0x5c>
  return fileread(f, p, n);
    800055ec:	fe442603          	lw	a2,-28(s0)
    800055f0:	fd843583          	ld	a1,-40(s0)
    800055f4:	fe843503          	ld	a0,-24(s0)
    800055f8:	fffff097          	auipc	ra,0xfffff
    800055fc:	444080e7          	jalr	1092(ra) # 80004a3c <fileread>
    80005600:	87aa                	mv	a5,a0
}
    80005602:	853e                	mv	a0,a5
    80005604:	70a2                	ld	ra,40(sp)
    80005606:	7402                	ld	s0,32(sp)
    80005608:	6145                	addi	sp,sp,48
    8000560a:	8082                	ret

000000008000560c <sys_write>:
{
    8000560c:	7179                	addi	sp,sp,-48
    8000560e:	f406                	sd	ra,40(sp)
    80005610:	f022                	sd	s0,32(sp)
    80005612:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005614:	fe840613          	addi	a2,s0,-24
    80005618:	4581                	li	a1,0
    8000561a:	4501                	li	a0,0
    8000561c:	00000097          	auipc	ra,0x0
    80005620:	d2a080e7          	jalr	-726(ra) # 80005346 <argfd>
    return -1;
    80005624:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005626:	04054163          	bltz	a0,80005668 <sys_write+0x5c>
    8000562a:	fe440593          	addi	a1,s0,-28
    8000562e:	4509                	li	a0,2
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	804080e7          	jalr	-2044(ra) # 80002e34 <argint>
    return -1;
    80005638:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000563a:	02054763          	bltz	a0,80005668 <sys_write+0x5c>
    8000563e:	fd840593          	addi	a1,s0,-40
    80005642:	4505                	li	a0,1
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	812080e7          	jalr	-2030(ra) # 80002e56 <argaddr>
    return -1;
    8000564c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000564e:	00054d63          	bltz	a0,80005668 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005652:	fe442603          	lw	a2,-28(s0)
    80005656:	fd843583          	ld	a1,-40(s0)
    8000565a:	fe843503          	ld	a0,-24(s0)
    8000565e:	fffff097          	auipc	ra,0xfffff
    80005662:	4a0080e7          	jalr	1184(ra) # 80004afe <filewrite>
    80005666:	87aa                	mv	a5,a0
}
    80005668:	853e                	mv	a0,a5
    8000566a:	70a2                	ld	ra,40(sp)
    8000566c:	7402                	ld	s0,32(sp)
    8000566e:	6145                	addi	sp,sp,48
    80005670:	8082                	ret

0000000080005672 <sys_close>:
{
    80005672:	1101                	addi	sp,sp,-32
    80005674:	ec06                	sd	ra,24(sp)
    80005676:	e822                	sd	s0,16(sp)
    80005678:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000567a:	fe040613          	addi	a2,s0,-32
    8000567e:	fec40593          	addi	a1,s0,-20
    80005682:	4501                	li	a0,0
    80005684:	00000097          	auipc	ra,0x0
    80005688:	cc2080e7          	jalr	-830(ra) # 80005346 <argfd>
    return -1;
    8000568c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000568e:	02054463          	bltz	a0,800056b6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005692:	ffffc097          	auipc	ra,0xffffc
    80005696:	6e4080e7          	jalr	1764(ra) # 80001d76 <myproc>
    8000569a:	fec42783          	lw	a5,-20(s0)
    8000569e:	07e9                	addi	a5,a5,26
    800056a0:	078e                	slli	a5,a5,0x3
    800056a2:	97aa                	add	a5,a5,a0
    800056a4:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800056a8:	fe043503          	ld	a0,-32(s0)
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	256080e7          	jalr	598(ra) # 80004902 <fileclose>
  return 0;
    800056b4:	4781                	li	a5,0
}
    800056b6:	853e                	mv	a0,a5
    800056b8:	60e2                	ld	ra,24(sp)
    800056ba:	6442                	ld	s0,16(sp)
    800056bc:	6105                	addi	sp,sp,32
    800056be:	8082                	ret

00000000800056c0 <sys_fstat>:
{
    800056c0:	1101                	addi	sp,sp,-32
    800056c2:	ec06                	sd	ra,24(sp)
    800056c4:	e822                	sd	s0,16(sp)
    800056c6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056c8:	fe840613          	addi	a2,s0,-24
    800056cc:	4581                	li	a1,0
    800056ce:	4501                	li	a0,0
    800056d0:	00000097          	auipc	ra,0x0
    800056d4:	c76080e7          	jalr	-906(ra) # 80005346 <argfd>
    return -1;
    800056d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056da:	02054563          	bltz	a0,80005704 <sys_fstat+0x44>
    800056de:	fe040593          	addi	a1,s0,-32
    800056e2:	4505                	li	a0,1
    800056e4:	ffffd097          	auipc	ra,0xffffd
    800056e8:	772080e7          	jalr	1906(ra) # 80002e56 <argaddr>
    return -1;
    800056ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056ee:	00054b63          	bltz	a0,80005704 <sys_fstat+0x44>
  return filestat(f, st);
    800056f2:	fe043583          	ld	a1,-32(s0)
    800056f6:	fe843503          	ld	a0,-24(s0)
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	2d0080e7          	jalr	720(ra) # 800049ca <filestat>
    80005702:	87aa                	mv	a5,a0
}
    80005704:	853e                	mv	a0,a5
    80005706:	60e2                	ld	ra,24(sp)
    80005708:	6442                	ld	s0,16(sp)
    8000570a:	6105                	addi	sp,sp,32
    8000570c:	8082                	ret

000000008000570e <sys_link>:
{
    8000570e:	7169                	addi	sp,sp,-304
    80005710:	f606                	sd	ra,296(sp)
    80005712:	f222                	sd	s0,288(sp)
    80005714:	ee26                	sd	s1,280(sp)
    80005716:	ea4a                	sd	s2,272(sp)
    80005718:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000571a:	08000613          	li	a2,128
    8000571e:	ed040593          	addi	a1,s0,-304
    80005722:	4501                	li	a0,0
    80005724:	ffffd097          	auipc	ra,0xffffd
    80005728:	754080e7          	jalr	1876(ra) # 80002e78 <argstr>
    return -1;
    8000572c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000572e:	10054e63          	bltz	a0,8000584a <sys_link+0x13c>
    80005732:	08000613          	li	a2,128
    80005736:	f5040593          	addi	a1,s0,-176
    8000573a:	4505                	li	a0,1
    8000573c:	ffffd097          	auipc	ra,0xffffd
    80005740:	73c080e7          	jalr	1852(ra) # 80002e78 <argstr>
    return -1;
    80005744:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005746:	10054263          	bltz	a0,8000584a <sys_link+0x13c>
  begin_op();
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	ce4080e7          	jalr	-796(ra) # 8000442e <begin_op>
  if((ip = namei(old)) == 0){
    80005752:	ed040513          	addi	a0,s0,-304
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	abc080e7          	jalr	-1348(ra) # 80004212 <namei>
    8000575e:	84aa                	mv	s1,a0
    80005760:	c551                	beqz	a0,800057ec <sys_link+0xde>
  ilock(ip);
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	2fc080e7          	jalr	764(ra) # 80003a5e <ilock>
  if(ip->type == T_DIR){
    8000576a:	04c49703          	lh	a4,76(s1)
    8000576e:	4785                	li	a5,1
    80005770:	08f70463          	beq	a4,a5,800057f8 <sys_link+0xea>
  ip->nlink++;
    80005774:	0524d783          	lhu	a5,82(s1)
    80005778:	2785                	addiw	a5,a5,1
    8000577a:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    8000577e:	8526                	mv	a0,s1
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	214080e7          	jalr	532(ra) # 80003994 <iupdate>
  iunlock(ip);
    80005788:	8526                	mv	a0,s1
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	396080e7          	jalr	918(ra) # 80003b20 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005792:	fd040593          	addi	a1,s0,-48
    80005796:	f5040513          	addi	a0,s0,-176
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	a96080e7          	jalr	-1386(ra) # 80004230 <nameiparent>
    800057a2:	892a                	mv	s2,a0
    800057a4:	c935                	beqz	a0,80005818 <sys_link+0x10a>
  ilock(dp);
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	2b8080e7          	jalr	696(ra) # 80003a5e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057ae:	00092703          	lw	a4,0(s2)
    800057b2:	409c                	lw	a5,0(s1)
    800057b4:	04f71d63          	bne	a4,a5,8000580e <sys_link+0x100>
    800057b8:	40d0                	lw	a2,4(s1)
    800057ba:	fd040593          	addi	a1,s0,-48
    800057be:	854a                	mv	a0,s2
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	990080e7          	jalr	-1648(ra) # 80004150 <dirlink>
    800057c8:	04054363          	bltz	a0,8000580e <sys_link+0x100>
  iunlockput(dp);
    800057cc:	854a                	mv	a0,s2
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	4f2080e7          	jalr	1266(ra) # 80003cc0 <iunlockput>
  iput(ip);
    800057d6:	8526                	mv	a0,s1
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	440080e7          	jalr	1088(ra) # 80003c18 <iput>
  end_op();
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	cce080e7          	jalr	-818(ra) # 800044ae <end_op>
  return 0;
    800057e8:	4781                	li	a5,0
    800057ea:	a085                	j	8000584a <sys_link+0x13c>
    end_op();
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	cc2080e7          	jalr	-830(ra) # 800044ae <end_op>
    return -1;
    800057f4:	57fd                	li	a5,-1
    800057f6:	a891                	j	8000584a <sys_link+0x13c>
    iunlockput(ip);
    800057f8:	8526                	mv	a0,s1
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	4c6080e7          	jalr	1222(ra) # 80003cc0 <iunlockput>
    end_op();
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	cac080e7          	jalr	-852(ra) # 800044ae <end_op>
    return -1;
    8000580a:	57fd                	li	a5,-1
    8000580c:	a83d                	j	8000584a <sys_link+0x13c>
    iunlockput(dp);
    8000580e:	854a                	mv	a0,s2
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	4b0080e7          	jalr	1200(ra) # 80003cc0 <iunlockput>
  ilock(ip);
    80005818:	8526                	mv	a0,s1
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	244080e7          	jalr	580(ra) # 80003a5e <ilock>
  ip->nlink--;
    80005822:	0524d783          	lhu	a5,82(s1)
    80005826:	37fd                	addiw	a5,a5,-1
    80005828:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	166080e7          	jalr	358(ra) # 80003994 <iupdate>
  iunlockput(ip);
    80005836:	8526                	mv	a0,s1
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	488080e7          	jalr	1160(ra) # 80003cc0 <iunlockput>
  end_op();
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	c6e080e7          	jalr	-914(ra) # 800044ae <end_op>
  return -1;
    80005848:	57fd                	li	a5,-1
}
    8000584a:	853e                	mv	a0,a5
    8000584c:	70b2                	ld	ra,296(sp)
    8000584e:	7412                	ld	s0,288(sp)
    80005850:	64f2                	ld	s1,280(sp)
    80005852:	6952                	ld	s2,272(sp)
    80005854:	6155                	addi	sp,sp,304
    80005856:	8082                	ret

0000000080005858 <sys_unlink>:
{
    80005858:	7151                	addi	sp,sp,-240
    8000585a:	f586                	sd	ra,232(sp)
    8000585c:	f1a2                	sd	s0,224(sp)
    8000585e:	eda6                	sd	s1,216(sp)
    80005860:	e9ca                	sd	s2,208(sp)
    80005862:	e5ce                	sd	s3,200(sp)
    80005864:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005866:	08000613          	li	a2,128
    8000586a:	f3040593          	addi	a1,s0,-208
    8000586e:	4501                	li	a0,0
    80005870:	ffffd097          	auipc	ra,0xffffd
    80005874:	608080e7          	jalr	1544(ra) # 80002e78 <argstr>
    80005878:	18054163          	bltz	a0,800059fa <sys_unlink+0x1a2>
  begin_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	bb2080e7          	jalr	-1102(ra) # 8000442e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005884:	fb040593          	addi	a1,s0,-80
    80005888:	f3040513          	addi	a0,s0,-208
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	9a4080e7          	jalr	-1628(ra) # 80004230 <nameiparent>
    80005894:	84aa                	mv	s1,a0
    80005896:	c979                	beqz	a0,8000596c <sys_unlink+0x114>
  ilock(dp);
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	1c6080e7          	jalr	454(ra) # 80003a5e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058a0:	00003597          	auipc	a1,0x3
    800058a4:	ef058593          	addi	a1,a1,-272 # 80008790 <syscalls+0x2d8>
    800058a8:	fb040513          	addi	a0,s0,-80
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	67a080e7          	jalr	1658(ra) # 80003f26 <namecmp>
    800058b4:	14050a63          	beqz	a0,80005a08 <sys_unlink+0x1b0>
    800058b8:	00003597          	auipc	a1,0x3
    800058bc:	ee058593          	addi	a1,a1,-288 # 80008798 <syscalls+0x2e0>
    800058c0:	fb040513          	addi	a0,s0,-80
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	662080e7          	jalr	1634(ra) # 80003f26 <namecmp>
    800058cc:	12050e63          	beqz	a0,80005a08 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800058d0:	f2c40613          	addi	a2,s0,-212
    800058d4:	fb040593          	addi	a1,s0,-80
    800058d8:	8526                	mv	a0,s1
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	666080e7          	jalr	1638(ra) # 80003f40 <dirlookup>
    800058e2:	892a                	mv	s2,a0
    800058e4:	12050263          	beqz	a0,80005a08 <sys_unlink+0x1b0>
  ilock(ip);
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	176080e7          	jalr	374(ra) # 80003a5e <ilock>
  if(ip->nlink < 1)
    800058f0:	05291783          	lh	a5,82(s2)
    800058f4:	08f05263          	blez	a5,80005978 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800058f8:	04c91703          	lh	a4,76(s2)
    800058fc:	4785                	li	a5,1
    800058fe:	08f70563          	beq	a4,a5,80005988 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005902:	4641                	li	a2,16
    80005904:	4581                	li	a1,0
    80005906:	fc040513          	addi	a0,s0,-64
    8000590a:	ffffc097          	auipc	ra,0xffffc
    8000590e:	804080e7          	jalr	-2044(ra) # 8000110e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005912:	4741                	li	a4,16
    80005914:	f2c42683          	lw	a3,-212(s0)
    80005918:	fc040613          	addi	a2,s0,-64
    8000591c:	4581                	li	a1,0
    8000591e:	8526                	mv	a0,s1
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	4ea080e7          	jalr	1258(ra) # 80003e0a <writei>
    80005928:	47c1                	li	a5,16
    8000592a:	0af51563          	bne	a0,a5,800059d4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000592e:	04c91703          	lh	a4,76(s2)
    80005932:	4785                	li	a5,1
    80005934:	0af70863          	beq	a4,a5,800059e4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005938:	8526                	mv	a0,s1
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	386080e7          	jalr	902(ra) # 80003cc0 <iunlockput>
  ip->nlink--;
    80005942:	05295783          	lhu	a5,82(s2)
    80005946:	37fd                	addiw	a5,a5,-1
    80005948:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    8000594c:	854a                	mv	a0,s2
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	046080e7          	jalr	70(ra) # 80003994 <iupdate>
  iunlockput(ip);
    80005956:	854a                	mv	a0,s2
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	368080e7          	jalr	872(ra) # 80003cc0 <iunlockput>
  end_op();
    80005960:	fffff097          	auipc	ra,0xfffff
    80005964:	b4e080e7          	jalr	-1202(ra) # 800044ae <end_op>
  return 0;
    80005968:	4501                	li	a0,0
    8000596a:	a84d                	j	80005a1c <sys_unlink+0x1c4>
    end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	b42080e7          	jalr	-1214(ra) # 800044ae <end_op>
    return -1;
    80005974:	557d                	li	a0,-1
    80005976:	a05d                	j	80005a1c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005978:	00003517          	auipc	a0,0x3
    8000597c:	e4850513          	addi	a0,a0,-440 # 800087c0 <syscalls+0x308>
    80005980:	ffffb097          	auipc	ra,0xffffb
    80005984:	bd0080e7          	jalr	-1072(ra) # 80000550 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005988:	05492703          	lw	a4,84(s2)
    8000598c:	02000793          	li	a5,32
    80005990:	f6e7f9e3          	bgeu	a5,a4,80005902 <sys_unlink+0xaa>
    80005994:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005998:	4741                	li	a4,16
    8000599a:	86ce                	mv	a3,s3
    8000599c:	f1840613          	addi	a2,s0,-232
    800059a0:	4581                	li	a1,0
    800059a2:	854a                	mv	a0,s2
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	36e080e7          	jalr	878(ra) # 80003d12 <readi>
    800059ac:	47c1                	li	a5,16
    800059ae:	00f51b63          	bne	a0,a5,800059c4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800059b2:	f1845783          	lhu	a5,-232(s0)
    800059b6:	e7a1                	bnez	a5,800059fe <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059b8:	29c1                	addiw	s3,s3,16
    800059ba:	05492783          	lw	a5,84(s2)
    800059be:	fcf9ede3          	bltu	s3,a5,80005998 <sys_unlink+0x140>
    800059c2:	b781                	j	80005902 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059c4:	00003517          	auipc	a0,0x3
    800059c8:	e1450513          	addi	a0,a0,-492 # 800087d8 <syscalls+0x320>
    800059cc:	ffffb097          	auipc	ra,0xffffb
    800059d0:	b84080e7          	jalr	-1148(ra) # 80000550 <panic>
    panic("unlink: writei");
    800059d4:	00003517          	auipc	a0,0x3
    800059d8:	e1c50513          	addi	a0,a0,-484 # 800087f0 <syscalls+0x338>
    800059dc:	ffffb097          	auipc	ra,0xffffb
    800059e0:	b74080e7          	jalr	-1164(ra) # 80000550 <panic>
    dp->nlink--;
    800059e4:	0524d783          	lhu	a5,82(s1)
    800059e8:	37fd                	addiw	a5,a5,-1
    800059ea:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    800059ee:	8526                	mv	a0,s1
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	fa4080e7          	jalr	-92(ra) # 80003994 <iupdate>
    800059f8:	b781                	j	80005938 <sys_unlink+0xe0>
    return -1;
    800059fa:	557d                	li	a0,-1
    800059fc:	a005                	j	80005a1c <sys_unlink+0x1c4>
    iunlockput(ip);
    800059fe:	854a                	mv	a0,s2
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	2c0080e7          	jalr	704(ra) # 80003cc0 <iunlockput>
  iunlockput(dp);
    80005a08:	8526                	mv	a0,s1
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	2b6080e7          	jalr	694(ra) # 80003cc0 <iunlockput>
  end_op();
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	a9c080e7          	jalr	-1380(ra) # 800044ae <end_op>
  return -1;
    80005a1a:	557d                	li	a0,-1
}
    80005a1c:	70ae                	ld	ra,232(sp)
    80005a1e:	740e                	ld	s0,224(sp)
    80005a20:	64ee                	ld	s1,216(sp)
    80005a22:	694e                	ld	s2,208(sp)
    80005a24:	69ae                	ld	s3,200(sp)
    80005a26:	616d                	addi	sp,sp,240
    80005a28:	8082                	ret

0000000080005a2a <sys_open>:

uint64
sys_open(void)
{
    80005a2a:	7131                	addi	sp,sp,-192
    80005a2c:	fd06                	sd	ra,184(sp)
    80005a2e:	f922                	sd	s0,176(sp)
    80005a30:	f526                	sd	s1,168(sp)
    80005a32:	f14a                	sd	s2,160(sp)
    80005a34:	ed4e                	sd	s3,152(sp)
    80005a36:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a38:	08000613          	li	a2,128
    80005a3c:	f5040593          	addi	a1,s0,-176
    80005a40:	4501                	li	a0,0
    80005a42:	ffffd097          	auipc	ra,0xffffd
    80005a46:	436080e7          	jalr	1078(ra) # 80002e78 <argstr>
    return -1;
    80005a4a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a4c:	0c054163          	bltz	a0,80005b0e <sys_open+0xe4>
    80005a50:	f4c40593          	addi	a1,s0,-180
    80005a54:	4505                	li	a0,1
    80005a56:	ffffd097          	auipc	ra,0xffffd
    80005a5a:	3de080e7          	jalr	990(ra) # 80002e34 <argint>
    80005a5e:	0a054863          	bltz	a0,80005b0e <sys_open+0xe4>

  begin_op();
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	9cc080e7          	jalr	-1588(ra) # 8000442e <begin_op>

  if(omode & O_CREATE){
    80005a6a:	f4c42783          	lw	a5,-180(s0)
    80005a6e:	2007f793          	andi	a5,a5,512
    80005a72:	cbdd                	beqz	a5,80005b28 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a74:	4681                	li	a3,0
    80005a76:	4601                	li	a2,0
    80005a78:	4589                	li	a1,2
    80005a7a:	f5040513          	addi	a0,s0,-176
    80005a7e:	00000097          	auipc	ra,0x0
    80005a82:	972080e7          	jalr	-1678(ra) # 800053f0 <create>
    80005a86:	892a                	mv	s2,a0
    if(ip == 0){
    80005a88:	c959                	beqz	a0,80005b1e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a8a:	04c91703          	lh	a4,76(s2)
    80005a8e:	478d                	li	a5,3
    80005a90:	00f71763          	bne	a4,a5,80005a9e <sys_open+0x74>
    80005a94:	04e95703          	lhu	a4,78(s2)
    80005a98:	47a5                	li	a5,9
    80005a9a:	0ce7ec63          	bltu	a5,a4,80005b72 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	da8080e7          	jalr	-600(ra) # 80004846 <filealloc>
    80005aa6:	89aa                	mv	s3,a0
    80005aa8:	10050263          	beqz	a0,80005bac <sys_open+0x182>
    80005aac:	00000097          	auipc	ra,0x0
    80005ab0:	902080e7          	jalr	-1790(ra) # 800053ae <fdalloc>
    80005ab4:	84aa                	mv	s1,a0
    80005ab6:	0e054663          	bltz	a0,80005ba2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005aba:	04c91703          	lh	a4,76(s2)
    80005abe:	478d                	li	a5,3
    80005ac0:	0cf70463          	beq	a4,a5,80005b88 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ac4:	4789                	li	a5,2
    80005ac6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005aca:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ace:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ad2:	f4c42783          	lw	a5,-180(s0)
    80005ad6:	0017c713          	xori	a4,a5,1
    80005ada:	8b05                	andi	a4,a4,1
    80005adc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ae0:	0037f713          	andi	a4,a5,3
    80005ae4:	00e03733          	snez	a4,a4
    80005ae8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005aec:	4007f793          	andi	a5,a5,1024
    80005af0:	c791                	beqz	a5,80005afc <sys_open+0xd2>
    80005af2:	04c91703          	lh	a4,76(s2)
    80005af6:	4789                	li	a5,2
    80005af8:	08f70f63          	beq	a4,a5,80005b96 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005afc:	854a                	mv	a0,s2
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	022080e7          	jalr	34(ra) # 80003b20 <iunlock>
  end_op();
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	9a8080e7          	jalr	-1624(ra) # 800044ae <end_op>

  return fd;
}
    80005b0e:	8526                	mv	a0,s1
    80005b10:	70ea                	ld	ra,184(sp)
    80005b12:	744a                	ld	s0,176(sp)
    80005b14:	74aa                	ld	s1,168(sp)
    80005b16:	790a                	ld	s2,160(sp)
    80005b18:	69ea                	ld	s3,152(sp)
    80005b1a:	6129                	addi	sp,sp,192
    80005b1c:	8082                	ret
      end_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	990080e7          	jalr	-1648(ra) # 800044ae <end_op>
      return -1;
    80005b26:	b7e5                	j	80005b0e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b28:	f5040513          	addi	a0,s0,-176
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	6e6080e7          	jalr	1766(ra) # 80004212 <namei>
    80005b34:	892a                	mv	s2,a0
    80005b36:	c905                	beqz	a0,80005b66 <sys_open+0x13c>
    ilock(ip);
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	f26080e7          	jalr	-218(ra) # 80003a5e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b40:	04c91703          	lh	a4,76(s2)
    80005b44:	4785                	li	a5,1
    80005b46:	f4f712e3          	bne	a4,a5,80005a8a <sys_open+0x60>
    80005b4a:	f4c42783          	lw	a5,-180(s0)
    80005b4e:	dba1                	beqz	a5,80005a9e <sys_open+0x74>
      iunlockput(ip);
    80005b50:	854a                	mv	a0,s2
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	16e080e7          	jalr	366(ra) # 80003cc0 <iunlockput>
      end_op();
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	954080e7          	jalr	-1708(ra) # 800044ae <end_op>
      return -1;
    80005b62:	54fd                	li	s1,-1
    80005b64:	b76d                	j	80005b0e <sys_open+0xe4>
      end_op();
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	948080e7          	jalr	-1720(ra) # 800044ae <end_op>
      return -1;
    80005b6e:	54fd                	li	s1,-1
    80005b70:	bf79                	j	80005b0e <sys_open+0xe4>
    iunlockput(ip);
    80005b72:	854a                	mv	a0,s2
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	14c080e7          	jalr	332(ra) # 80003cc0 <iunlockput>
    end_op();
    80005b7c:	fffff097          	auipc	ra,0xfffff
    80005b80:	932080e7          	jalr	-1742(ra) # 800044ae <end_op>
    return -1;
    80005b84:	54fd                	li	s1,-1
    80005b86:	b761                	j	80005b0e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b88:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b8c:	04e91783          	lh	a5,78(s2)
    80005b90:	02f99223          	sh	a5,36(s3)
    80005b94:	bf2d                	j	80005ace <sys_open+0xa4>
    itrunc(ip);
    80005b96:	854a                	mv	a0,s2
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	fd4080e7          	jalr	-44(ra) # 80003b6c <itrunc>
    80005ba0:	bfb1                	j	80005afc <sys_open+0xd2>
      fileclose(f);
    80005ba2:	854e                	mv	a0,s3
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	d5e080e7          	jalr	-674(ra) # 80004902 <fileclose>
    iunlockput(ip);
    80005bac:	854a                	mv	a0,s2
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	112080e7          	jalr	274(ra) # 80003cc0 <iunlockput>
    end_op();
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	8f8080e7          	jalr	-1800(ra) # 800044ae <end_op>
    return -1;
    80005bbe:	54fd                	li	s1,-1
    80005bc0:	b7b9                	j	80005b0e <sys_open+0xe4>

0000000080005bc2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005bc2:	7175                	addi	sp,sp,-144
    80005bc4:	e506                	sd	ra,136(sp)
    80005bc6:	e122                	sd	s0,128(sp)
    80005bc8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	864080e7          	jalr	-1948(ra) # 8000442e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005bd2:	08000613          	li	a2,128
    80005bd6:	f7040593          	addi	a1,s0,-144
    80005bda:	4501                	li	a0,0
    80005bdc:	ffffd097          	auipc	ra,0xffffd
    80005be0:	29c080e7          	jalr	668(ra) # 80002e78 <argstr>
    80005be4:	02054963          	bltz	a0,80005c16 <sys_mkdir+0x54>
    80005be8:	4681                	li	a3,0
    80005bea:	4601                	li	a2,0
    80005bec:	4585                	li	a1,1
    80005bee:	f7040513          	addi	a0,s0,-144
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	7fe080e7          	jalr	2046(ra) # 800053f0 <create>
    80005bfa:	cd11                	beqz	a0,80005c16 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	0c4080e7          	jalr	196(ra) # 80003cc0 <iunlockput>
  end_op();
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	8aa080e7          	jalr	-1878(ra) # 800044ae <end_op>
  return 0;
    80005c0c:	4501                	li	a0,0
}
    80005c0e:	60aa                	ld	ra,136(sp)
    80005c10:	640a                	ld	s0,128(sp)
    80005c12:	6149                	addi	sp,sp,144
    80005c14:	8082                	ret
    end_op();
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	898080e7          	jalr	-1896(ra) # 800044ae <end_op>
    return -1;
    80005c1e:	557d                	li	a0,-1
    80005c20:	b7fd                	j	80005c0e <sys_mkdir+0x4c>

0000000080005c22 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c22:	7135                	addi	sp,sp,-160
    80005c24:	ed06                	sd	ra,152(sp)
    80005c26:	e922                	sd	s0,144(sp)
    80005c28:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c2a:	fffff097          	auipc	ra,0xfffff
    80005c2e:	804080e7          	jalr	-2044(ra) # 8000442e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c32:	08000613          	li	a2,128
    80005c36:	f7040593          	addi	a1,s0,-144
    80005c3a:	4501                	li	a0,0
    80005c3c:	ffffd097          	auipc	ra,0xffffd
    80005c40:	23c080e7          	jalr	572(ra) # 80002e78 <argstr>
    80005c44:	04054a63          	bltz	a0,80005c98 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c48:	f6c40593          	addi	a1,s0,-148
    80005c4c:	4505                	li	a0,1
    80005c4e:	ffffd097          	auipc	ra,0xffffd
    80005c52:	1e6080e7          	jalr	486(ra) # 80002e34 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c56:	04054163          	bltz	a0,80005c98 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005c5a:	f6840593          	addi	a1,s0,-152
    80005c5e:	4509                	li	a0,2
    80005c60:	ffffd097          	auipc	ra,0xffffd
    80005c64:	1d4080e7          	jalr	468(ra) # 80002e34 <argint>
     argint(1, &major) < 0 ||
    80005c68:	02054863          	bltz	a0,80005c98 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c6c:	f6841683          	lh	a3,-152(s0)
    80005c70:	f6c41603          	lh	a2,-148(s0)
    80005c74:	458d                	li	a1,3
    80005c76:	f7040513          	addi	a0,s0,-144
    80005c7a:	fffff097          	auipc	ra,0xfffff
    80005c7e:	776080e7          	jalr	1910(ra) # 800053f0 <create>
     argint(2, &minor) < 0 ||
    80005c82:	c919                	beqz	a0,80005c98 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	03c080e7          	jalr	60(ra) # 80003cc0 <iunlockput>
  end_op();
    80005c8c:	fffff097          	auipc	ra,0xfffff
    80005c90:	822080e7          	jalr	-2014(ra) # 800044ae <end_op>
  return 0;
    80005c94:	4501                	li	a0,0
    80005c96:	a031                	j	80005ca2 <sys_mknod+0x80>
    end_op();
    80005c98:	fffff097          	auipc	ra,0xfffff
    80005c9c:	816080e7          	jalr	-2026(ra) # 800044ae <end_op>
    return -1;
    80005ca0:	557d                	li	a0,-1
}
    80005ca2:	60ea                	ld	ra,152(sp)
    80005ca4:	644a                	ld	s0,144(sp)
    80005ca6:	610d                	addi	sp,sp,160
    80005ca8:	8082                	ret

0000000080005caa <sys_chdir>:

uint64
sys_chdir(void)
{
    80005caa:	7135                	addi	sp,sp,-160
    80005cac:	ed06                	sd	ra,152(sp)
    80005cae:	e922                	sd	s0,144(sp)
    80005cb0:	e526                	sd	s1,136(sp)
    80005cb2:	e14a                	sd	s2,128(sp)
    80005cb4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005cb6:	ffffc097          	auipc	ra,0xffffc
    80005cba:	0c0080e7          	jalr	192(ra) # 80001d76 <myproc>
    80005cbe:	892a                	mv	s2,a0
  
  begin_op();
    80005cc0:	ffffe097          	auipc	ra,0xffffe
    80005cc4:	76e080e7          	jalr	1902(ra) # 8000442e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005cc8:	08000613          	li	a2,128
    80005ccc:	f6040593          	addi	a1,s0,-160
    80005cd0:	4501                	li	a0,0
    80005cd2:	ffffd097          	auipc	ra,0xffffd
    80005cd6:	1a6080e7          	jalr	422(ra) # 80002e78 <argstr>
    80005cda:	04054b63          	bltz	a0,80005d30 <sys_chdir+0x86>
    80005cde:	f6040513          	addi	a0,s0,-160
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	530080e7          	jalr	1328(ra) # 80004212 <namei>
    80005cea:	84aa                	mv	s1,a0
    80005cec:	c131                	beqz	a0,80005d30 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005cee:	ffffe097          	auipc	ra,0xffffe
    80005cf2:	d70080e7          	jalr	-656(ra) # 80003a5e <ilock>
  if(ip->type != T_DIR){
    80005cf6:	04c49703          	lh	a4,76(s1)
    80005cfa:	4785                	li	a5,1
    80005cfc:	04f71063          	bne	a4,a5,80005d3c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d00:	8526                	mv	a0,s1
    80005d02:	ffffe097          	auipc	ra,0xffffe
    80005d06:	e1e080e7          	jalr	-482(ra) # 80003b20 <iunlock>
  iput(p->cwd);
    80005d0a:	15893503          	ld	a0,344(s2)
    80005d0e:	ffffe097          	auipc	ra,0xffffe
    80005d12:	f0a080e7          	jalr	-246(ra) # 80003c18 <iput>
  end_op();
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	798080e7          	jalr	1944(ra) # 800044ae <end_op>
  p->cwd = ip;
    80005d1e:	14993c23          	sd	s1,344(s2)
  return 0;
    80005d22:	4501                	li	a0,0
}
    80005d24:	60ea                	ld	ra,152(sp)
    80005d26:	644a                	ld	s0,144(sp)
    80005d28:	64aa                	ld	s1,136(sp)
    80005d2a:	690a                	ld	s2,128(sp)
    80005d2c:	610d                	addi	sp,sp,160
    80005d2e:	8082                	ret
    end_op();
    80005d30:	ffffe097          	auipc	ra,0xffffe
    80005d34:	77e080e7          	jalr	1918(ra) # 800044ae <end_op>
    return -1;
    80005d38:	557d                	li	a0,-1
    80005d3a:	b7ed                	j	80005d24 <sys_chdir+0x7a>
    iunlockput(ip);
    80005d3c:	8526                	mv	a0,s1
    80005d3e:	ffffe097          	auipc	ra,0xffffe
    80005d42:	f82080e7          	jalr	-126(ra) # 80003cc0 <iunlockput>
    end_op();
    80005d46:	ffffe097          	auipc	ra,0xffffe
    80005d4a:	768080e7          	jalr	1896(ra) # 800044ae <end_op>
    return -1;
    80005d4e:	557d                	li	a0,-1
    80005d50:	bfd1                	j	80005d24 <sys_chdir+0x7a>

0000000080005d52 <sys_exec>:

uint64
sys_exec(void)
{
    80005d52:	7145                	addi	sp,sp,-464
    80005d54:	e786                	sd	ra,456(sp)
    80005d56:	e3a2                	sd	s0,448(sp)
    80005d58:	ff26                	sd	s1,440(sp)
    80005d5a:	fb4a                	sd	s2,432(sp)
    80005d5c:	f74e                	sd	s3,424(sp)
    80005d5e:	f352                	sd	s4,416(sp)
    80005d60:	ef56                	sd	s5,408(sp)
    80005d62:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d64:	08000613          	li	a2,128
    80005d68:	f4040593          	addi	a1,s0,-192
    80005d6c:	4501                	li	a0,0
    80005d6e:	ffffd097          	auipc	ra,0xffffd
    80005d72:	10a080e7          	jalr	266(ra) # 80002e78 <argstr>
    return -1;
    80005d76:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d78:	0c054a63          	bltz	a0,80005e4c <sys_exec+0xfa>
    80005d7c:	e3840593          	addi	a1,s0,-456
    80005d80:	4505                	li	a0,1
    80005d82:	ffffd097          	auipc	ra,0xffffd
    80005d86:	0d4080e7          	jalr	212(ra) # 80002e56 <argaddr>
    80005d8a:	0c054163          	bltz	a0,80005e4c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d8e:	10000613          	li	a2,256
    80005d92:	4581                	li	a1,0
    80005d94:	e4040513          	addi	a0,s0,-448
    80005d98:	ffffb097          	auipc	ra,0xffffb
    80005d9c:	376080e7          	jalr	886(ra) # 8000110e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005da0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005da4:	89a6                	mv	s3,s1
    80005da6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005da8:	02000a13          	li	s4,32
    80005dac:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005db0:	00391513          	slli	a0,s2,0x3
    80005db4:	e3040593          	addi	a1,s0,-464
    80005db8:	e3843783          	ld	a5,-456(s0)
    80005dbc:	953e                	add	a0,a0,a5
    80005dbe:	ffffd097          	auipc	ra,0xffffd
    80005dc2:	fdc080e7          	jalr	-36(ra) # 80002d9a <fetchaddr>
    80005dc6:	02054a63          	bltz	a0,80005dfa <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005dca:	e3043783          	ld	a5,-464(s0)
    80005dce:	c3b9                	beqz	a5,80005e14 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005dd0:	ffffb097          	auipc	ra,0xffffb
    80005dd4:	e4c080e7          	jalr	-436(ra) # 80000c1c <kalloc>
    80005dd8:	85aa                	mv	a1,a0
    80005dda:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005dde:	cd11                	beqz	a0,80005dfa <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005de0:	6605                	lui	a2,0x1
    80005de2:	e3043503          	ld	a0,-464(s0)
    80005de6:	ffffd097          	auipc	ra,0xffffd
    80005dea:	006080e7          	jalr	6(ra) # 80002dec <fetchstr>
    80005dee:	00054663          	bltz	a0,80005dfa <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005df2:	0905                	addi	s2,s2,1
    80005df4:	09a1                	addi	s3,s3,8
    80005df6:	fb491be3          	bne	s2,s4,80005dac <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dfa:	10048913          	addi	s2,s1,256
    80005dfe:	6088                	ld	a0,0(s1)
    80005e00:	c529                	beqz	a0,80005e4a <sys_exec+0xf8>
    kfree(argv[i]);
    80005e02:	ffffb097          	auipc	ra,0xffffb
    80005e06:	c2a080e7          	jalr	-982(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e0a:	04a1                	addi	s1,s1,8
    80005e0c:	ff2499e3          	bne	s1,s2,80005dfe <sys_exec+0xac>
  return -1;
    80005e10:	597d                	li	s2,-1
    80005e12:	a82d                	j	80005e4c <sys_exec+0xfa>
      argv[i] = 0;
    80005e14:	0a8e                	slli	s5,s5,0x3
    80005e16:	fc040793          	addi	a5,s0,-64
    80005e1a:	9abe                	add	s5,s5,a5
    80005e1c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e20:	e4040593          	addi	a1,s0,-448
    80005e24:	f4040513          	addi	a0,s0,-192
    80005e28:	fffff097          	auipc	ra,0xfffff
    80005e2c:	194080e7          	jalr	404(ra) # 80004fbc <exec>
    80005e30:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e32:	10048993          	addi	s3,s1,256
    80005e36:	6088                	ld	a0,0(s1)
    80005e38:	c911                	beqz	a0,80005e4c <sys_exec+0xfa>
    kfree(argv[i]);
    80005e3a:	ffffb097          	auipc	ra,0xffffb
    80005e3e:	bf2080e7          	jalr	-1038(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e42:	04a1                	addi	s1,s1,8
    80005e44:	ff3499e3          	bne	s1,s3,80005e36 <sys_exec+0xe4>
    80005e48:	a011                	j	80005e4c <sys_exec+0xfa>
  return -1;
    80005e4a:	597d                	li	s2,-1
}
    80005e4c:	854a                	mv	a0,s2
    80005e4e:	60be                	ld	ra,456(sp)
    80005e50:	641e                	ld	s0,448(sp)
    80005e52:	74fa                	ld	s1,440(sp)
    80005e54:	795a                	ld	s2,432(sp)
    80005e56:	79ba                	ld	s3,424(sp)
    80005e58:	7a1a                	ld	s4,416(sp)
    80005e5a:	6afa                	ld	s5,408(sp)
    80005e5c:	6179                	addi	sp,sp,464
    80005e5e:	8082                	ret

0000000080005e60 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e60:	7139                	addi	sp,sp,-64
    80005e62:	fc06                	sd	ra,56(sp)
    80005e64:	f822                	sd	s0,48(sp)
    80005e66:	f426                	sd	s1,40(sp)
    80005e68:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e6a:	ffffc097          	auipc	ra,0xffffc
    80005e6e:	f0c080e7          	jalr	-244(ra) # 80001d76 <myproc>
    80005e72:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e74:	fd840593          	addi	a1,s0,-40
    80005e78:	4501                	li	a0,0
    80005e7a:	ffffd097          	auipc	ra,0xffffd
    80005e7e:	fdc080e7          	jalr	-36(ra) # 80002e56 <argaddr>
    return -1;
    80005e82:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e84:	0e054063          	bltz	a0,80005f64 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005e88:	fc840593          	addi	a1,s0,-56
    80005e8c:	fd040513          	addi	a0,s0,-48
    80005e90:	fffff097          	auipc	ra,0xfffff
    80005e94:	dc8080e7          	jalr	-568(ra) # 80004c58 <pipealloc>
    return -1;
    80005e98:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e9a:	0c054563          	bltz	a0,80005f64 <sys_pipe+0x104>
  fd0 = -1;
    80005e9e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ea2:	fd043503          	ld	a0,-48(s0)
    80005ea6:	fffff097          	auipc	ra,0xfffff
    80005eaa:	508080e7          	jalr	1288(ra) # 800053ae <fdalloc>
    80005eae:	fca42223          	sw	a0,-60(s0)
    80005eb2:	08054c63          	bltz	a0,80005f4a <sys_pipe+0xea>
    80005eb6:	fc843503          	ld	a0,-56(s0)
    80005eba:	fffff097          	auipc	ra,0xfffff
    80005ebe:	4f4080e7          	jalr	1268(ra) # 800053ae <fdalloc>
    80005ec2:	fca42023          	sw	a0,-64(s0)
    80005ec6:	06054863          	bltz	a0,80005f36 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005eca:	4691                	li	a3,4
    80005ecc:	fc440613          	addi	a2,s0,-60
    80005ed0:	fd843583          	ld	a1,-40(s0)
    80005ed4:	6ca8                	ld	a0,88(s1)
    80005ed6:	ffffc097          	auipc	ra,0xffffc
    80005eda:	b94080e7          	jalr	-1132(ra) # 80001a6a <copyout>
    80005ede:	02054063          	bltz	a0,80005efe <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ee2:	4691                	li	a3,4
    80005ee4:	fc040613          	addi	a2,s0,-64
    80005ee8:	fd843583          	ld	a1,-40(s0)
    80005eec:	0591                	addi	a1,a1,4
    80005eee:	6ca8                	ld	a0,88(s1)
    80005ef0:	ffffc097          	auipc	ra,0xffffc
    80005ef4:	b7a080e7          	jalr	-1158(ra) # 80001a6a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ef8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005efa:	06055563          	bgez	a0,80005f64 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005efe:	fc442783          	lw	a5,-60(s0)
    80005f02:	07e9                	addi	a5,a5,26
    80005f04:	078e                	slli	a5,a5,0x3
    80005f06:	97a6                	add	a5,a5,s1
    80005f08:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005f0c:	fc042503          	lw	a0,-64(s0)
    80005f10:	0569                	addi	a0,a0,26
    80005f12:	050e                	slli	a0,a0,0x3
    80005f14:	9526                	add	a0,a0,s1
    80005f16:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005f1a:	fd043503          	ld	a0,-48(s0)
    80005f1e:	fffff097          	auipc	ra,0xfffff
    80005f22:	9e4080e7          	jalr	-1564(ra) # 80004902 <fileclose>
    fileclose(wf);
    80005f26:	fc843503          	ld	a0,-56(s0)
    80005f2a:	fffff097          	auipc	ra,0xfffff
    80005f2e:	9d8080e7          	jalr	-1576(ra) # 80004902 <fileclose>
    return -1;
    80005f32:	57fd                	li	a5,-1
    80005f34:	a805                	j	80005f64 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005f36:	fc442783          	lw	a5,-60(s0)
    80005f3a:	0007c863          	bltz	a5,80005f4a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005f3e:	01a78513          	addi	a0,a5,26
    80005f42:	050e                	slli	a0,a0,0x3
    80005f44:	9526                	add	a0,a0,s1
    80005f46:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005f4a:	fd043503          	ld	a0,-48(s0)
    80005f4e:	fffff097          	auipc	ra,0xfffff
    80005f52:	9b4080e7          	jalr	-1612(ra) # 80004902 <fileclose>
    fileclose(wf);
    80005f56:	fc843503          	ld	a0,-56(s0)
    80005f5a:	fffff097          	auipc	ra,0xfffff
    80005f5e:	9a8080e7          	jalr	-1624(ra) # 80004902 <fileclose>
    return -1;
    80005f62:	57fd                	li	a5,-1
}
    80005f64:	853e                	mv	a0,a5
    80005f66:	70e2                	ld	ra,56(sp)
    80005f68:	7442                	ld	s0,48(sp)
    80005f6a:	74a2                	ld	s1,40(sp)
    80005f6c:	6121                	addi	sp,sp,64
    80005f6e:	8082                	ret

0000000080005f70 <kernelvec>:
    80005f70:	7111                	addi	sp,sp,-256
    80005f72:	e006                	sd	ra,0(sp)
    80005f74:	e40a                	sd	sp,8(sp)
    80005f76:	e80e                	sd	gp,16(sp)
    80005f78:	ec12                	sd	tp,24(sp)
    80005f7a:	f016                	sd	t0,32(sp)
    80005f7c:	f41a                	sd	t1,40(sp)
    80005f7e:	f81e                	sd	t2,48(sp)
    80005f80:	fc22                	sd	s0,56(sp)
    80005f82:	e0a6                	sd	s1,64(sp)
    80005f84:	e4aa                	sd	a0,72(sp)
    80005f86:	e8ae                	sd	a1,80(sp)
    80005f88:	ecb2                	sd	a2,88(sp)
    80005f8a:	f0b6                	sd	a3,96(sp)
    80005f8c:	f4ba                	sd	a4,104(sp)
    80005f8e:	f8be                	sd	a5,112(sp)
    80005f90:	fcc2                	sd	a6,120(sp)
    80005f92:	e146                	sd	a7,128(sp)
    80005f94:	e54a                	sd	s2,136(sp)
    80005f96:	e94e                	sd	s3,144(sp)
    80005f98:	ed52                	sd	s4,152(sp)
    80005f9a:	f156                	sd	s5,160(sp)
    80005f9c:	f55a                	sd	s6,168(sp)
    80005f9e:	f95e                	sd	s7,176(sp)
    80005fa0:	fd62                	sd	s8,184(sp)
    80005fa2:	e1e6                	sd	s9,192(sp)
    80005fa4:	e5ea                	sd	s10,200(sp)
    80005fa6:	e9ee                	sd	s11,208(sp)
    80005fa8:	edf2                	sd	t3,216(sp)
    80005faa:	f1f6                	sd	t4,224(sp)
    80005fac:	f5fa                	sd	t5,232(sp)
    80005fae:	f9fe                	sd	t6,240(sp)
    80005fb0:	cb7fc0ef          	jal	ra,80002c66 <kerneltrap>
    80005fb4:	6082                	ld	ra,0(sp)
    80005fb6:	6122                	ld	sp,8(sp)
    80005fb8:	61c2                	ld	gp,16(sp)
    80005fba:	7282                	ld	t0,32(sp)
    80005fbc:	7322                	ld	t1,40(sp)
    80005fbe:	73c2                	ld	t2,48(sp)
    80005fc0:	7462                	ld	s0,56(sp)
    80005fc2:	6486                	ld	s1,64(sp)
    80005fc4:	6526                	ld	a0,72(sp)
    80005fc6:	65c6                	ld	a1,80(sp)
    80005fc8:	6666                	ld	a2,88(sp)
    80005fca:	7686                	ld	a3,96(sp)
    80005fcc:	7726                	ld	a4,104(sp)
    80005fce:	77c6                	ld	a5,112(sp)
    80005fd0:	7866                	ld	a6,120(sp)
    80005fd2:	688a                	ld	a7,128(sp)
    80005fd4:	692a                	ld	s2,136(sp)
    80005fd6:	69ca                	ld	s3,144(sp)
    80005fd8:	6a6a                	ld	s4,152(sp)
    80005fda:	7a8a                	ld	s5,160(sp)
    80005fdc:	7b2a                	ld	s6,168(sp)
    80005fde:	7bca                	ld	s7,176(sp)
    80005fe0:	7c6a                	ld	s8,184(sp)
    80005fe2:	6c8e                	ld	s9,192(sp)
    80005fe4:	6d2e                	ld	s10,200(sp)
    80005fe6:	6dce                	ld	s11,208(sp)
    80005fe8:	6e6e                	ld	t3,216(sp)
    80005fea:	7e8e                	ld	t4,224(sp)
    80005fec:	7f2e                	ld	t5,232(sp)
    80005fee:	7fce                	ld	t6,240(sp)
    80005ff0:	6111                	addi	sp,sp,256
    80005ff2:	10200073          	sret
    80005ff6:	00000013          	nop
    80005ffa:	00000013          	nop
    80005ffe:	0001                	nop

0000000080006000 <timervec>:
    80006000:	34051573          	csrrw	a0,mscratch,a0
    80006004:	e10c                	sd	a1,0(a0)
    80006006:	e510                	sd	a2,8(a0)
    80006008:	e914                	sd	a3,16(a0)
    8000600a:	6d0c                	ld	a1,24(a0)
    8000600c:	7110                	ld	a2,32(a0)
    8000600e:	6194                	ld	a3,0(a1)
    80006010:	96b2                	add	a3,a3,a2
    80006012:	e194                	sd	a3,0(a1)
    80006014:	4589                	li	a1,2
    80006016:	14459073          	csrw	sip,a1
    8000601a:	6914                	ld	a3,16(a0)
    8000601c:	6510                	ld	a2,8(a0)
    8000601e:	610c                	ld	a1,0(a0)
    80006020:	34051573          	csrrw	a0,mscratch,a0
    80006024:	30200073          	mret
	...

000000008000602a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000602a:	1141                	addi	sp,sp,-16
    8000602c:	e422                	sd	s0,8(sp)
    8000602e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006030:	0c0007b7          	lui	a5,0xc000
    80006034:	4705                	li	a4,1
    80006036:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006038:	c3d8                	sw	a4,4(a5)
}
    8000603a:	6422                	ld	s0,8(sp)
    8000603c:	0141                	addi	sp,sp,16
    8000603e:	8082                	ret

0000000080006040 <plicinithart>:

void
plicinithart(void)
{
    80006040:	1141                	addi	sp,sp,-16
    80006042:	e406                	sd	ra,8(sp)
    80006044:	e022                	sd	s0,0(sp)
    80006046:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006048:	ffffc097          	auipc	ra,0xffffc
    8000604c:	d02080e7          	jalr	-766(ra) # 80001d4a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006050:	0085171b          	slliw	a4,a0,0x8
    80006054:	0c0027b7          	lui	a5,0xc002
    80006058:	97ba                	add	a5,a5,a4
    8000605a:	40200713          	li	a4,1026
    8000605e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006062:	00d5151b          	slliw	a0,a0,0xd
    80006066:	0c2017b7          	lui	a5,0xc201
    8000606a:	953e                	add	a0,a0,a5
    8000606c:	00052023          	sw	zero,0(a0)
}
    80006070:	60a2                	ld	ra,8(sp)
    80006072:	6402                	ld	s0,0(sp)
    80006074:	0141                	addi	sp,sp,16
    80006076:	8082                	ret

0000000080006078 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006078:	1141                	addi	sp,sp,-16
    8000607a:	e406                	sd	ra,8(sp)
    8000607c:	e022                	sd	s0,0(sp)
    8000607e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006080:	ffffc097          	auipc	ra,0xffffc
    80006084:	cca080e7          	jalr	-822(ra) # 80001d4a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006088:	00d5179b          	slliw	a5,a0,0xd
    8000608c:	0c201537          	lui	a0,0xc201
    80006090:	953e                	add	a0,a0,a5
  return irq;
}
    80006092:	4148                	lw	a0,4(a0)
    80006094:	60a2                	ld	ra,8(sp)
    80006096:	6402                	ld	s0,0(sp)
    80006098:	0141                	addi	sp,sp,16
    8000609a:	8082                	ret

000000008000609c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000609c:	1101                	addi	sp,sp,-32
    8000609e:	ec06                	sd	ra,24(sp)
    800060a0:	e822                	sd	s0,16(sp)
    800060a2:	e426                	sd	s1,8(sp)
    800060a4:	1000                	addi	s0,sp,32
    800060a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060a8:	ffffc097          	auipc	ra,0xffffc
    800060ac:	ca2080e7          	jalr	-862(ra) # 80001d4a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800060b0:	00d5151b          	slliw	a0,a0,0xd
    800060b4:	0c2017b7          	lui	a5,0xc201
    800060b8:	97aa                	add	a5,a5,a0
    800060ba:	c3c4                	sw	s1,4(a5)
}
    800060bc:	60e2                	ld	ra,24(sp)
    800060be:	6442                	ld	s0,16(sp)
    800060c0:	64a2                	ld	s1,8(sp)
    800060c2:	6105                	addi	sp,sp,32
    800060c4:	8082                	ret

00000000800060c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800060c6:	1141                	addi	sp,sp,-16
    800060c8:	e406                	sd	ra,8(sp)
    800060ca:	e022                	sd	s0,0(sp)
    800060cc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800060ce:	479d                	li	a5,7
    800060d0:	06a7c963          	blt	a5,a0,80006142 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800060d4:	00028797          	auipc	a5,0x28
    800060d8:	f2c78793          	addi	a5,a5,-212 # 8002e000 <disk>
    800060dc:	00a78733          	add	a4,a5,a0
    800060e0:	6789                	lui	a5,0x2
    800060e2:	97ba                	add	a5,a5,a4
    800060e4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800060e8:	e7ad                	bnez	a5,80006152 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800060ea:	00451793          	slli	a5,a0,0x4
    800060ee:	0002a717          	auipc	a4,0x2a
    800060f2:	f1270713          	addi	a4,a4,-238 # 80030000 <disk+0x2000>
    800060f6:	6314                	ld	a3,0(a4)
    800060f8:	96be                	add	a3,a3,a5
    800060fa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800060fe:	6314                	ld	a3,0(a4)
    80006100:	96be                	add	a3,a3,a5
    80006102:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006106:	6314                	ld	a3,0(a4)
    80006108:	96be                	add	a3,a3,a5
    8000610a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000610e:	6318                	ld	a4,0(a4)
    80006110:	97ba                	add	a5,a5,a4
    80006112:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006116:	00028797          	auipc	a5,0x28
    8000611a:	eea78793          	addi	a5,a5,-278 # 8002e000 <disk>
    8000611e:	97aa                	add	a5,a5,a0
    80006120:	6509                	lui	a0,0x2
    80006122:	953e                	add	a0,a0,a5
    80006124:	4785                	li	a5,1
    80006126:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000612a:	0002a517          	auipc	a0,0x2a
    8000612e:	eee50513          	addi	a0,a0,-274 # 80030018 <disk+0x2018>
    80006132:	ffffc097          	auipc	ra,0xffffc
    80006136:	5da080e7          	jalr	1498(ra) # 8000270c <wakeup>
}
    8000613a:	60a2                	ld	ra,8(sp)
    8000613c:	6402                	ld	s0,0(sp)
    8000613e:	0141                	addi	sp,sp,16
    80006140:	8082                	ret
    panic("free_desc 1");
    80006142:	00002517          	auipc	a0,0x2
    80006146:	6be50513          	addi	a0,a0,1726 # 80008800 <syscalls+0x348>
    8000614a:	ffffa097          	auipc	ra,0xffffa
    8000614e:	406080e7          	jalr	1030(ra) # 80000550 <panic>
    panic("free_desc 2");
    80006152:	00002517          	auipc	a0,0x2
    80006156:	6be50513          	addi	a0,a0,1726 # 80008810 <syscalls+0x358>
    8000615a:	ffffa097          	auipc	ra,0xffffa
    8000615e:	3f6080e7          	jalr	1014(ra) # 80000550 <panic>

0000000080006162 <virtio_disk_init>:
{
    80006162:	1101                	addi	sp,sp,-32
    80006164:	ec06                	sd	ra,24(sp)
    80006166:	e822                	sd	s0,16(sp)
    80006168:	e426                	sd	s1,8(sp)
    8000616a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000616c:	00002597          	auipc	a1,0x2
    80006170:	6b458593          	addi	a1,a1,1716 # 80008820 <syscalls+0x368>
    80006174:	0002a517          	auipc	a0,0x2a
    80006178:	fb450513          	addi	a0,a0,-76 # 80030128 <disk+0x2128>
    8000617c:	ffffb097          	auipc	ra,0xffffb
    80006180:	d2e080e7          	jalr	-722(ra) # 80000eaa <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006184:	100017b7          	lui	a5,0x10001
    80006188:	4398                	lw	a4,0(a5)
    8000618a:	2701                	sext.w	a4,a4
    8000618c:	747277b7          	lui	a5,0x74727
    80006190:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006194:	0ef71163          	bne	a4,a5,80006276 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006198:	100017b7          	lui	a5,0x10001
    8000619c:	43dc                	lw	a5,4(a5)
    8000619e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061a0:	4705                	li	a4,1
    800061a2:	0ce79a63          	bne	a5,a4,80006276 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061a6:	100017b7          	lui	a5,0x10001
    800061aa:	479c                	lw	a5,8(a5)
    800061ac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061ae:	4709                	li	a4,2
    800061b0:	0ce79363          	bne	a5,a4,80006276 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061b4:	100017b7          	lui	a5,0x10001
    800061b8:	47d8                	lw	a4,12(a5)
    800061ba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061bc:	554d47b7          	lui	a5,0x554d4
    800061c0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800061c4:	0af71963          	bne	a4,a5,80006276 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061c8:	100017b7          	lui	a5,0x10001
    800061cc:	4705                	li	a4,1
    800061ce:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061d0:	470d                	li	a4,3
    800061d2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800061d4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800061d6:	c7ffe737          	lui	a4,0xc7ffe
    800061da:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcc737>
    800061de:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800061e0:	2701                	sext.w	a4,a4
    800061e2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061e4:	472d                	li	a4,11
    800061e6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061e8:	473d                	li	a4,15
    800061ea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800061ec:	6705                	lui	a4,0x1
    800061ee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800061f0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800061f4:	5bdc                	lw	a5,52(a5)
    800061f6:	2781                	sext.w	a5,a5
  if(max == 0)
    800061f8:	c7d9                	beqz	a5,80006286 <virtio_disk_init+0x124>
  if(max < NUM)
    800061fa:	471d                	li	a4,7
    800061fc:	08f77d63          	bgeu	a4,a5,80006296 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006200:	100014b7          	lui	s1,0x10001
    80006204:	47a1                	li	a5,8
    80006206:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006208:	6609                	lui	a2,0x2
    8000620a:	4581                	li	a1,0
    8000620c:	00028517          	auipc	a0,0x28
    80006210:	df450513          	addi	a0,a0,-524 # 8002e000 <disk>
    80006214:	ffffb097          	auipc	ra,0xffffb
    80006218:	efa080e7          	jalr	-262(ra) # 8000110e <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000621c:	00028717          	auipc	a4,0x28
    80006220:	de470713          	addi	a4,a4,-540 # 8002e000 <disk>
    80006224:	00c75793          	srli	a5,a4,0xc
    80006228:	2781                	sext.w	a5,a5
    8000622a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000622c:	0002a797          	auipc	a5,0x2a
    80006230:	dd478793          	addi	a5,a5,-556 # 80030000 <disk+0x2000>
    80006234:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006236:	00028717          	auipc	a4,0x28
    8000623a:	e4a70713          	addi	a4,a4,-438 # 8002e080 <disk+0x80>
    8000623e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006240:	00029717          	auipc	a4,0x29
    80006244:	dc070713          	addi	a4,a4,-576 # 8002f000 <disk+0x1000>
    80006248:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000624a:	4705                	li	a4,1
    8000624c:	00e78c23          	sb	a4,24(a5)
    80006250:	00e78ca3          	sb	a4,25(a5)
    80006254:	00e78d23          	sb	a4,26(a5)
    80006258:	00e78da3          	sb	a4,27(a5)
    8000625c:	00e78e23          	sb	a4,28(a5)
    80006260:	00e78ea3          	sb	a4,29(a5)
    80006264:	00e78f23          	sb	a4,30(a5)
    80006268:	00e78fa3          	sb	a4,31(a5)
}
    8000626c:	60e2                	ld	ra,24(sp)
    8000626e:	6442                	ld	s0,16(sp)
    80006270:	64a2                	ld	s1,8(sp)
    80006272:	6105                	addi	sp,sp,32
    80006274:	8082                	ret
    panic("could not find virtio disk");
    80006276:	00002517          	auipc	a0,0x2
    8000627a:	5ba50513          	addi	a0,a0,1466 # 80008830 <syscalls+0x378>
    8000627e:	ffffa097          	auipc	ra,0xffffa
    80006282:	2d2080e7          	jalr	722(ra) # 80000550 <panic>
    panic("virtio disk has no queue 0");
    80006286:	00002517          	auipc	a0,0x2
    8000628a:	5ca50513          	addi	a0,a0,1482 # 80008850 <syscalls+0x398>
    8000628e:	ffffa097          	auipc	ra,0xffffa
    80006292:	2c2080e7          	jalr	706(ra) # 80000550 <panic>
    panic("virtio disk max queue too short");
    80006296:	00002517          	auipc	a0,0x2
    8000629a:	5da50513          	addi	a0,a0,1498 # 80008870 <syscalls+0x3b8>
    8000629e:	ffffa097          	auipc	ra,0xffffa
    800062a2:	2b2080e7          	jalr	690(ra) # 80000550 <panic>

00000000800062a6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062a6:	7159                	addi	sp,sp,-112
    800062a8:	f486                	sd	ra,104(sp)
    800062aa:	f0a2                	sd	s0,96(sp)
    800062ac:	eca6                	sd	s1,88(sp)
    800062ae:	e8ca                	sd	s2,80(sp)
    800062b0:	e4ce                	sd	s3,72(sp)
    800062b2:	e0d2                	sd	s4,64(sp)
    800062b4:	fc56                	sd	s5,56(sp)
    800062b6:	f85a                	sd	s6,48(sp)
    800062b8:	f45e                	sd	s7,40(sp)
    800062ba:	f062                	sd	s8,32(sp)
    800062bc:	ec66                	sd	s9,24(sp)
    800062be:	e86a                	sd	s10,16(sp)
    800062c0:	1880                	addi	s0,sp,112
    800062c2:	892a                	mv	s2,a0
    800062c4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062c6:	00c52c83          	lw	s9,12(a0)
    800062ca:	001c9c9b          	slliw	s9,s9,0x1
    800062ce:	1c82                	slli	s9,s9,0x20
    800062d0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800062d4:	0002a517          	auipc	a0,0x2a
    800062d8:	e5450513          	addi	a0,a0,-428 # 80030128 <disk+0x2128>
    800062dc:	ffffb097          	auipc	ra,0xffffb
    800062e0:	a52080e7          	jalr	-1454(ra) # 80000d2e <acquire>
  for(int i = 0; i < 3; i++){
    800062e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062e6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800062e8:	00028b97          	auipc	s7,0x28
    800062ec:	d18b8b93          	addi	s7,s7,-744 # 8002e000 <disk>
    800062f0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800062f2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800062f4:	8a4e                	mv	s4,s3
    800062f6:	a051                	j	8000637a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800062f8:	00fb86b3          	add	a3,s7,a5
    800062fc:	96da                	add	a3,a3,s6
    800062fe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006302:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006304:	0207c563          	bltz	a5,8000632e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006308:	2485                	addiw	s1,s1,1
    8000630a:	0711                	addi	a4,a4,4
    8000630c:	25548063          	beq	s1,s5,8000654c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006310:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006312:	0002a697          	auipc	a3,0x2a
    80006316:	d0668693          	addi	a3,a3,-762 # 80030018 <disk+0x2018>
    8000631a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000631c:	0006c583          	lbu	a1,0(a3)
    80006320:	fde1                	bnez	a1,800062f8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006322:	2785                	addiw	a5,a5,1
    80006324:	0685                	addi	a3,a3,1
    80006326:	ff879be3          	bne	a5,s8,8000631c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000632a:	57fd                	li	a5,-1
    8000632c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000632e:	02905a63          	blez	s1,80006362 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006332:	f9042503          	lw	a0,-112(s0)
    80006336:	00000097          	auipc	ra,0x0
    8000633a:	d90080e7          	jalr	-624(ra) # 800060c6 <free_desc>
      for(int j = 0; j < i; j++)
    8000633e:	4785                	li	a5,1
    80006340:	0297d163          	bge	a5,s1,80006362 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006344:	f9442503          	lw	a0,-108(s0)
    80006348:	00000097          	auipc	ra,0x0
    8000634c:	d7e080e7          	jalr	-642(ra) # 800060c6 <free_desc>
      for(int j = 0; j < i; j++)
    80006350:	4789                	li	a5,2
    80006352:	0097d863          	bge	a5,s1,80006362 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006356:	f9842503          	lw	a0,-104(s0)
    8000635a:	00000097          	auipc	ra,0x0
    8000635e:	d6c080e7          	jalr	-660(ra) # 800060c6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006362:	0002a597          	auipc	a1,0x2a
    80006366:	dc658593          	addi	a1,a1,-570 # 80030128 <disk+0x2128>
    8000636a:	0002a517          	auipc	a0,0x2a
    8000636e:	cae50513          	addi	a0,a0,-850 # 80030018 <disk+0x2018>
    80006372:	ffffc097          	auipc	ra,0xffffc
    80006376:	214080e7          	jalr	532(ra) # 80002586 <sleep>
  for(int i = 0; i < 3; i++){
    8000637a:	f9040713          	addi	a4,s0,-112
    8000637e:	84ce                	mv	s1,s3
    80006380:	bf41                	j	80006310 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006382:	20058713          	addi	a4,a1,512
    80006386:	00471693          	slli	a3,a4,0x4
    8000638a:	00028717          	auipc	a4,0x28
    8000638e:	c7670713          	addi	a4,a4,-906 # 8002e000 <disk>
    80006392:	9736                	add	a4,a4,a3
    80006394:	4685                	li	a3,1
    80006396:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000639a:	20058713          	addi	a4,a1,512
    8000639e:	00471693          	slli	a3,a4,0x4
    800063a2:	00028717          	auipc	a4,0x28
    800063a6:	c5e70713          	addi	a4,a4,-930 # 8002e000 <disk>
    800063aa:	9736                	add	a4,a4,a3
    800063ac:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800063b0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063b4:	7679                	lui	a2,0xffffe
    800063b6:	963e                	add	a2,a2,a5
    800063b8:	0002a697          	auipc	a3,0x2a
    800063bc:	c4868693          	addi	a3,a3,-952 # 80030000 <disk+0x2000>
    800063c0:	6298                	ld	a4,0(a3)
    800063c2:	9732                	add	a4,a4,a2
    800063c4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063c6:	6298                	ld	a4,0(a3)
    800063c8:	9732                	add	a4,a4,a2
    800063ca:	4541                	li	a0,16
    800063cc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063ce:	6298                	ld	a4,0(a3)
    800063d0:	9732                	add	a4,a4,a2
    800063d2:	4505                	li	a0,1
    800063d4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800063d8:	f9442703          	lw	a4,-108(s0)
    800063dc:	6288                	ld	a0,0(a3)
    800063de:	962a                	add	a2,a2,a0
    800063e0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffcbfe6>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063e4:	0712                	slli	a4,a4,0x4
    800063e6:	6290                	ld	a2,0(a3)
    800063e8:	963a                	add	a2,a2,a4
    800063ea:	06090513          	addi	a0,s2,96
    800063ee:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800063f0:	6294                	ld	a3,0(a3)
    800063f2:	96ba                	add	a3,a3,a4
    800063f4:	40000613          	li	a2,1024
    800063f8:	c690                	sw	a2,8(a3)
  if(write)
    800063fa:	140d0063          	beqz	s10,8000653a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800063fe:	0002a697          	auipc	a3,0x2a
    80006402:	c026b683          	ld	a3,-1022(a3) # 80030000 <disk+0x2000>
    80006406:	96ba                	add	a3,a3,a4
    80006408:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000640c:	00028817          	auipc	a6,0x28
    80006410:	bf480813          	addi	a6,a6,-1036 # 8002e000 <disk>
    80006414:	0002a517          	auipc	a0,0x2a
    80006418:	bec50513          	addi	a0,a0,-1044 # 80030000 <disk+0x2000>
    8000641c:	6114                	ld	a3,0(a0)
    8000641e:	96ba                	add	a3,a3,a4
    80006420:	00c6d603          	lhu	a2,12(a3)
    80006424:	00166613          	ori	a2,a2,1
    80006428:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000642c:	f9842683          	lw	a3,-104(s0)
    80006430:	6110                	ld	a2,0(a0)
    80006432:	9732                	add	a4,a4,a2
    80006434:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006438:	20058613          	addi	a2,a1,512
    8000643c:	0612                	slli	a2,a2,0x4
    8000643e:	9642                	add	a2,a2,a6
    80006440:	577d                	li	a4,-1
    80006442:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006446:	00469713          	slli	a4,a3,0x4
    8000644a:	6114                	ld	a3,0(a0)
    8000644c:	96ba                	add	a3,a3,a4
    8000644e:	03078793          	addi	a5,a5,48
    80006452:	97c2                	add	a5,a5,a6
    80006454:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006456:	611c                	ld	a5,0(a0)
    80006458:	97ba                	add	a5,a5,a4
    8000645a:	4685                	li	a3,1
    8000645c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000645e:	611c                	ld	a5,0(a0)
    80006460:	97ba                	add	a5,a5,a4
    80006462:	4809                	li	a6,2
    80006464:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006468:	611c                	ld	a5,0(a0)
    8000646a:	973e                	add	a4,a4,a5
    8000646c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006470:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006474:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006478:	6518                	ld	a4,8(a0)
    8000647a:	00275783          	lhu	a5,2(a4)
    8000647e:	8b9d                	andi	a5,a5,7
    80006480:	0786                	slli	a5,a5,0x1
    80006482:	97ba                	add	a5,a5,a4
    80006484:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006488:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000648c:	6518                	ld	a4,8(a0)
    8000648e:	00275783          	lhu	a5,2(a4)
    80006492:	2785                	addiw	a5,a5,1
    80006494:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006498:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000649c:	100017b7          	lui	a5,0x10001
    800064a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800064a4:	00492703          	lw	a4,4(s2)
    800064a8:	4785                	li	a5,1
    800064aa:	02f71163          	bne	a4,a5,800064cc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800064ae:	0002a997          	auipc	s3,0x2a
    800064b2:	c7a98993          	addi	s3,s3,-902 # 80030128 <disk+0x2128>
  while(b->disk == 1) {
    800064b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800064b8:	85ce                	mv	a1,s3
    800064ba:	854a                	mv	a0,s2
    800064bc:	ffffc097          	auipc	ra,0xffffc
    800064c0:	0ca080e7          	jalr	202(ra) # 80002586 <sleep>
  while(b->disk == 1) {
    800064c4:	00492783          	lw	a5,4(s2)
    800064c8:	fe9788e3          	beq	a5,s1,800064b8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800064cc:	f9042903          	lw	s2,-112(s0)
    800064d0:	20090793          	addi	a5,s2,512
    800064d4:	00479713          	slli	a4,a5,0x4
    800064d8:	00028797          	auipc	a5,0x28
    800064dc:	b2878793          	addi	a5,a5,-1240 # 8002e000 <disk>
    800064e0:	97ba                	add	a5,a5,a4
    800064e2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800064e6:	0002a997          	auipc	s3,0x2a
    800064ea:	b1a98993          	addi	s3,s3,-1254 # 80030000 <disk+0x2000>
    800064ee:	00491713          	slli	a4,s2,0x4
    800064f2:	0009b783          	ld	a5,0(s3)
    800064f6:	97ba                	add	a5,a5,a4
    800064f8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064fc:	854a                	mv	a0,s2
    800064fe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006502:	00000097          	auipc	ra,0x0
    80006506:	bc4080e7          	jalr	-1084(ra) # 800060c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000650a:	8885                	andi	s1,s1,1
    8000650c:	f0ed                	bnez	s1,800064ee <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000650e:	0002a517          	auipc	a0,0x2a
    80006512:	c1a50513          	addi	a0,a0,-998 # 80030128 <disk+0x2128>
    80006516:	ffffb097          	auipc	ra,0xffffb
    8000651a:	8e8080e7          	jalr	-1816(ra) # 80000dfe <release>
}
    8000651e:	70a6                	ld	ra,104(sp)
    80006520:	7406                	ld	s0,96(sp)
    80006522:	64e6                	ld	s1,88(sp)
    80006524:	6946                	ld	s2,80(sp)
    80006526:	69a6                	ld	s3,72(sp)
    80006528:	6a06                	ld	s4,64(sp)
    8000652a:	7ae2                	ld	s5,56(sp)
    8000652c:	7b42                	ld	s6,48(sp)
    8000652e:	7ba2                	ld	s7,40(sp)
    80006530:	7c02                	ld	s8,32(sp)
    80006532:	6ce2                	ld	s9,24(sp)
    80006534:	6d42                	ld	s10,16(sp)
    80006536:	6165                	addi	sp,sp,112
    80006538:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000653a:	0002a697          	auipc	a3,0x2a
    8000653e:	ac66b683          	ld	a3,-1338(a3) # 80030000 <disk+0x2000>
    80006542:	96ba                	add	a3,a3,a4
    80006544:	4609                	li	a2,2
    80006546:	00c69623          	sh	a2,12(a3)
    8000654a:	b5c9                	j	8000640c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000654c:	f9042583          	lw	a1,-112(s0)
    80006550:	20058793          	addi	a5,a1,512
    80006554:	0792                	slli	a5,a5,0x4
    80006556:	00028517          	auipc	a0,0x28
    8000655a:	b5250513          	addi	a0,a0,-1198 # 8002e0a8 <disk+0xa8>
    8000655e:	953e                	add	a0,a0,a5
  if(write)
    80006560:	e20d11e3          	bnez	s10,80006382 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006564:	20058713          	addi	a4,a1,512
    80006568:	00471693          	slli	a3,a4,0x4
    8000656c:	00028717          	auipc	a4,0x28
    80006570:	a9470713          	addi	a4,a4,-1388 # 8002e000 <disk>
    80006574:	9736                	add	a4,a4,a3
    80006576:	0a072423          	sw	zero,168(a4)
    8000657a:	b505                	j	8000639a <virtio_disk_rw+0xf4>

000000008000657c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000657c:	1101                	addi	sp,sp,-32
    8000657e:	ec06                	sd	ra,24(sp)
    80006580:	e822                	sd	s0,16(sp)
    80006582:	e426                	sd	s1,8(sp)
    80006584:	e04a                	sd	s2,0(sp)
    80006586:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006588:	0002a517          	auipc	a0,0x2a
    8000658c:	ba050513          	addi	a0,a0,-1120 # 80030128 <disk+0x2128>
    80006590:	ffffa097          	auipc	ra,0xffffa
    80006594:	79e080e7          	jalr	1950(ra) # 80000d2e <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006598:	10001737          	lui	a4,0x10001
    8000659c:	533c                	lw	a5,96(a4)
    8000659e:	8b8d                	andi	a5,a5,3
    800065a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065a6:	0002a797          	auipc	a5,0x2a
    800065aa:	a5a78793          	addi	a5,a5,-1446 # 80030000 <disk+0x2000>
    800065ae:	6b94                	ld	a3,16(a5)
    800065b0:	0207d703          	lhu	a4,32(a5)
    800065b4:	0026d783          	lhu	a5,2(a3)
    800065b8:	06f70163          	beq	a4,a5,8000661a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065bc:	00028917          	auipc	s2,0x28
    800065c0:	a4490913          	addi	s2,s2,-1468 # 8002e000 <disk>
    800065c4:	0002a497          	auipc	s1,0x2a
    800065c8:	a3c48493          	addi	s1,s1,-1476 # 80030000 <disk+0x2000>
    __sync_synchronize();
    800065cc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065d0:	6898                	ld	a4,16(s1)
    800065d2:	0204d783          	lhu	a5,32(s1)
    800065d6:	8b9d                	andi	a5,a5,7
    800065d8:	078e                	slli	a5,a5,0x3
    800065da:	97ba                	add	a5,a5,a4
    800065dc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800065de:	20078713          	addi	a4,a5,512
    800065e2:	0712                	slli	a4,a4,0x4
    800065e4:	974a                	add	a4,a4,s2
    800065e6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800065ea:	e731                	bnez	a4,80006636 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800065ec:	20078793          	addi	a5,a5,512
    800065f0:	0792                	slli	a5,a5,0x4
    800065f2:	97ca                	add	a5,a5,s2
    800065f4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800065f6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800065fa:	ffffc097          	auipc	ra,0xffffc
    800065fe:	112080e7          	jalr	274(ra) # 8000270c <wakeup>

    disk.used_idx += 1;
    80006602:	0204d783          	lhu	a5,32(s1)
    80006606:	2785                	addiw	a5,a5,1
    80006608:	17c2                	slli	a5,a5,0x30
    8000660a:	93c1                	srli	a5,a5,0x30
    8000660c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006610:	6898                	ld	a4,16(s1)
    80006612:	00275703          	lhu	a4,2(a4)
    80006616:	faf71be3          	bne	a4,a5,800065cc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000661a:	0002a517          	auipc	a0,0x2a
    8000661e:	b0e50513          	addi	a0,a0,-1266 # 80030128 <disk+0x2128>
    80006622:	ffffa097          	auipc	ra,0xffffa
    80006626:	7dc080e7          	jalr	2012(ra) # 80000dfe <release>
}
    8000662a:	60e2                	ld	ra,24(sp)
    8000662c:	6442                	ld	s0,16(sp)
    8000662e:	64a2                	ld	s1,8(sp)
    80006630:	6902                	ld	s2,0(sp)
    80006632:	6105                	addi	sp,sp,32
    80006634:	8082                	ret
      panic("virtio_disk_intr status");
    80006636:	00002517          	auipc	a0,0x2
    8000663a:	25a50513          	addi	a0,a0,602 # 80008890 <syscalls+0x3d8>
    8000663e:	ffffa097          	auipc	ra,0xffffa
    80006642:	f12080e7          	jalr	-238(ra) # 80000550 <panic>

0000000080006646 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006646:	1141                	addi	sp,sp,-16
    80006648:	e422                	sd	s0,8(sp)
    8000664a:	0800                	addi	s0,sp,16
  return -1;
}
    8000664c:	557d                	li	a0,-1
    8000664e:	6422                	ld	s0,8(sp)
    80006650:	0141                	addi	sp,sp,16
    80006652:	8082                	ret

0000000080006654 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006654:	7179                	addi	sp,sp,-48
    80006656:	f406                	sd	ra,40(sp)
    80006658:	f022                	sd	s0,32(sp)
    8000665a:	ec26                	sd	s1,24(sp)
    8000665c:	e84a                	sd	s2,16(sp)
    8000665e:	e44e                	sd	s3,8(sp)
    80006660:	e052                	sd	s4,0(sp)
    80006662:	1800                	addi	s0,sp,48
    80006664:	892a                	mv	s2,a0
    80006666:	89ae                	mv	s3,a1
    80006668:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    8000666a:	0002b517          	auipc	a0,0x2b
    8000666e:	99650513          	addi	a0,a0,-1642 # 80031000 <stats>
    80006672:	ffffa097          	auipc	ra,0xffffa
    80006676:	6bc080e7          	jalr	1724(ra) # 80000d2e <acquire>

  if(stats.sz == 0) {
    8000667a:	0002c797          	auipc	a5,0x2c
    8000667e:	9a67a783          	lw	a5,-1626(a5) # 80032020 <stats+0x1020>
    80006682:	cbb5                	beqz	a5,800066f6 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006684:	0002c797          	auipc	a5,0x2c
    80006688:	97c78793          	addi	a5,a5,-1668 # 80032000 <stats+0x1000>
    8000668c:	53d8                	lw	a4,36(a5)
    8000668e:	539c                	lw	a5,32(a5)
    80006690:	9f99                	subw	a5,a5,a4
    80006692:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006696:	06d05e63          	blez	a3,80006712 <statsread+0xbe>
    if(m > n)
    8000669a:	8a3e                	mv	s4,a5
    8000669c:	00d4d363          	bge	s1,a3,800066a2 <statsread+0x4e>
    800066a0:	8a26                	mv	s4,s1
    800066a2:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800066a6:	86a6                	mv	a3,s1
    800066a8:	0002b617          	auipc	a2,0x2b
    800066ac:	97860613          	addi	a2,a2,-1672 # 80031020 <stats+0x20>
    800066b0:	963a                	add	a2,a2,a4
    800066b2:	85ce                	mv	a1,s3
    800066b4:	854a                	mv	a0,s2
    800066b6:	ffffc097          	auipc	ra,0xffffc
    800066ba:	132080e7          	jalr	306(ra) # 800027e8 <either_copyout>
    800066be:	57fd                	li	a5,-1
    800066c0:	00f50a63          	beq	a0,a5,800066d4 <statsread+0x80>
      stats.off += m;
    800066c4:	0002c717          	auipc	a4,0x2c
    800066c8:	93c70713          	addi	a4,a4,-1732 # 80032000 <stats+0x1000>
    800066cc:	535c                	lw	a5,36(a4)
    800066ce:	014787bb          	addw	a5,a5,s4
    800066d2:	d35c                	sw	a5,36(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800066d4:	0002b517          	auipc	a0,0x2b
    800066d8:	92c50513          	addi	a0,a0,-1748 # 80031000 <stats>
    800066dc:	ffffa097          	auipc	ra,0xffffa
    800066e0:	722080e7          	jalr	1826(ra) # 80000dfe <release>
  return m;
}
    800066e4:	8526                	mv	a0,s1
    800066e6:	70a2                	ld	ra,40(sp)
    800066e8:	7402                	ld	s0,32(sp)
    800066ea:	64e2                	ld	s1,24(sp)
    800066ec:	6942                	ld	s2,16(sp)
    800066ee:	69a2                	ld	s3,8(sp)
    800066f0:	6a02                	ld	s4,0(sp)
    800066f2:	6145                	addi	sp,sp,48
    800066f4:	8082                	ret
    stats.sz = statslock(stats.buf, BUFSZ);
    800066f6:	6585                	lui	a1,0x1
    800066f8:	0002b517          	auipc	a0,0x2b
    800066fc:	92850513          	addi	a0,a0,-1752 # 80031020 <stats+0x20>
    80006700:	ffffb097          	auipc	ra,0xffffb
    80006704:	858080e7          	jalr	-1960(ra) # 80000f58 <statslock>
    80006708:	0002c797          	auipc	a5,0x2c
    8000670c:	90a7ac23          	sw	a0,-1768(a5) # 80032020 <stats+0x1020>
    80006710:	bf95                	j	80006684 <statsread+0x30>
    stats.sz = 0;
    80006712:	0002c797          	auipc	a5,0x2c
    80006716:	8ee78793          	addi	a5,a5,-1810 # 80032000 <stats+0x1000>
    8000671a:	0207a023          	sw	zero,32(a5)
    stats.off = 0;
    8000671e:	0207a223          	sw	zero,36(a5)
    m = -1;
    80006722:	54fd                	li	s1,-1
    80006724:	bf45                	j	800066d4 <statsread+0x80>

0000000080006726 <statsinit>:

void
statsinit(void)
{
    80006726:	1141                	addi	sp,sp,-16
    80006728:	e406                	sd	ra,8(sp)
    8000672a:	e022                	sd	s0,0(sp)
    8000672c:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000672e:	00002597          	auipc	a1,0x2
    80006732:	17a58593          	addi	a1,a1,378 # 800088a8 <syscalls+0x3f0>
    80006736:	0002b517          	auipc	a0,0x2b
    8000673a:	8ca50513          	addi	a0,a0,-1846 # 80031000 <stats>
    8000673e:	ffffa097          	auipc	ra,0xffffa
    80006742:	76c080e7          	jalr	1900(ra) # 80000eaa <initlock>

  devsw[STATS].read = statsread;
    80006746:	00026797          	auipc	a5,0x26
    8000674a:	99a78793          	addi	a5,a5,-1638 # 8002c0e0 <devsw>
    8000674e:	00000717          	auipc	a4,0x0
    80006752:	f0670713          	addi	a4,a4,-250 # 80006654 <statsread>
    80006756:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006758:	00000717          	auipc	a4,0x0
    8000675c:	eee70713          	addi	a4,a4,-274 # 80006646 <statswrite>
    80006760:	f798                	sd	a4,40(a5)
}
    80006762:	60a2                	ld	ra,8(sp)
    80006764:	6402                	ld	s0,0(sp)
    80006766:	0141                	addi	sp,sp,16
    80006768:	8082                	ret

000000008000676a <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    8000676a:	1101                	addi	sp,sp,-32
    8000676c:	ec22                	sd	s0,24(sp)
    8000676e:	1000                	addi	s0,sp,32
    80006770:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    80006772:	c299                	beqz	a3,80006778 <sprintint+0xe>
    80006774:	0805c163          	bltz	a1,800067f6 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006778:	2581                	sext.w	a1,a1
    8000677a:	4301                	li	t1,0

  i = 0;
    8000677c:	fe040713          	addi	a4,s0,-32
    80006780:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    80006782:	2601                	sext.w	a2,a2
    80006784:	00002697          	auipc	a3,0x2
    80006788:	12c68693          	addi	a3,a3,300 # 800088b0 <digits>
    8000678c:	88aa                	mv	a7,a0
    8000678e:	2505                	addiw	a0,a0,1
    80006790:	02c5f7bb          	remuw	a5,a1,a2
    80006794:	1782                	slli	a5,a5,0x20
    80006796:	9381                	srli	a5,a5,0x20
    80006798:	97b6                	add	a5,a5,a3
    8000679a:	0007c783          	lbu	a5,0(a5)
    8000679e:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800067a2:	0005879b          	sext.w	a5,a1
    800067a6:	02c5d5bb          	divuw	a1,a1,a2
    800067aa:	0705                	addi	a4,a4,1
    800067ac:	fec7f0e3          	bgeu	a5,a2,8000678c <sprintint+0x22>

  if(sign)
    800067b0:	00030b63          	beqz	t1,800067c6 <sprintint+0x5c>
    buf[i++] = '-';
    800067b4:	ff040793          	addi	a5,s0,-16
    800067b8:	97aa                	add	a5,a5,a0
    800067ba:	02d00713          	li	a4,45
    800067be:	fee78823          	sb	a4,-16(a5)
    800067c2:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800067c6:	02a05c63          	blez	a0,800067fe <sprintint+0x94>
    800067ca:	fe040793          	addi	a5,s0,-32
    800067ce:	00a78733          	add	a4,a5,a0
    800067d2:	87c2                	mv	a5,a6
    800067d4:	0805                	addi	a6,a6,1
    800067d6:	fff5061b          	addiw	a2,a0,-1
    800067da:	1602                	slli	a2,a2,0x20
    800067dc:	9201                	srli	a2,a2,0x20
    800067de:	9642                	add	a2,a2,a6
  *s = c;
    800067e0:	fff74683          	lbu	a3,-1(a4)
    800067e4:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    800067e8:	177d                	addi	a4,a4,-1
    800067ea:	0785                	addi	a5,a5,1
    800067ec:	fec79ae3          	bne	a5,a2,800067e0 <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    800067f0:	6462                	ld	s0,24(sp)
    800067f2:	6105                	addi	sp,sp,32
    800067f4:	8082                	ret
    x = -xx;
    800067f6:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    800067fa:	4305                	li	t1,1
    x = -xx;
    800067fc:	b741                	j	8000677c <sprintint+0x12>
  while(--i >= 0)
    800067fe:	4501                	li	a0,0
    80006800:	bfc5                	j	800067f0 <sprintint+0x86>

0000000080006802 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006802:	7171                	addi	sp,sp,-176
    80006804:	fc86                	sd	ra,120(sp)
    80006806:	f8a2                	sd	s0,112(sp)
    80006808:	f4a6                	sd	s1,104(sp)
    8000680a:	f0ca                	sd	s2,96(sp)
    8000680c:	ecce                	sd	s3,88(sp)
    8000680e:	e8d2                	sd	s4,80(sp)
    80006810:	e4d6                	sd	s5,72(sp)
    80006812:	e0da                	sd	s6,64(sp)
    80006814:	fc5e                	sd	s7,56(sp)
    80006816:	f862                	sd	s8,48(sp)
    80006818:	f466                	sd	s9,40(sp)
    8000681a:	f06a                	sd	s10,32(sp)
    8000681c:	ec6e                	sd	s11,24(sp)
    8000681e:	0100                	addi	s0,sp,128
    80006820:	e414                	sd	a3,8(s0)
    80006822:	e818                	sd	a4,16(s0)
    80006824:	ec1c                	sd	a5,24(s0)
    80006826:	03043023          	sd	a6,32(s0)
    8000682a:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000682e:	ca0d                	beqz	a2,80006860 <snprintf+0x5e>
    80006830:	8baa                	mv	s7,a0
    80006832:	89ae                	mv	s3,a1
    80006834:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006836:	00840793          	addi	a5,s0,8
    8000683a:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    8000683e:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006840:	4901                	li	s2,0
    80006842:	02b05763          	blez	a1,80006870 <snprintf+0x6e>
    if(c != '%'){
    80006846:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    8000684a:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000684e:	02800d93          	li	s11,40
  *s = c;
    80006852:	02500d13          	li	s10,37
    switch(c){
    80006856:	07800c93          	li	s9,120
    8000685a:	06400c13          	li	s8,100
    8000685e:	a01d                	j	80006884 <snprintf+0x82>
    panic("null fmt");
    80006860:	00001517          	auipc	a0,0x1
    80006864:	7c850513          	addi	a0,a0,1992 # 80008028 <etext+0x28>
    80006868:	ffffa097          	auipc	ra,0xffffa
    8000686c:	ce8080e7          	jalr	-792(ra) # 80000550 <panic>
  int off = 0;
    80006870:	4481                	li	s1,0
    80006872:	a86d                	j	8000692c <snprintf+0x12a>
  *s = c;
    80006874:	009b8733          	add	a4,s7,s1
    80006878:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    8000687c:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000687e:	2905                	addiw	s2,s2,1
    80006880:	0b34d663          	bge	s1,s3,8000692c <snprintf+0x12a>
    80006884:	012a07b3          	add	a5,s4,s2
    80006888:	0007c783          	lbu	a5,0(a5)
    8000688c:	0007871b          	sext.w	a4,a5
    80006890:	cfd1                	beqz	a5,8000692c <snprintf+0x12a>
    if(c != '%'){
    80006892:	ff5711e3          	bne	a4,s5,80006874 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    80006896:	2905                	addiw	s2,s2,1
    80006898:	012a07b3          	add	a5,s4,s2
    8000689c:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800068a0:	c7d1                	beqz	a5,8000692c <snprintf+0x12a>
    switch(c){
    800068a2:	05678c63          	beq	a5,s6,800068fa <snprintf+0xf8>
    800068a6:	02fb6763          	bltu	s6,a5,800068d4 <snprintf+0xd2>
    800068aa:	0b578763          	beq	a5,s5,80006958 <snprintf+0x156>
    800068ae:	0b879b63          	bne	a5,s8,80006964 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800068b2:	f8843783          	ld	a5,-120(s0)
    800068b6:	00878713          	addi	a4,a5,8
    800068ba:	f8e43423          	sd	a4,-120(s0)
    800068be:	4685                	li	a3,1
    800068c0:	4629                	li	a2,10
    800068c2:	438c                	lw	a1,0(a5)
    800068c4:	009b8533          	add	a0,s7,s1
    800068c8:	00000097          	auipc	ra,0x0
    800068cc:	ea2080e7          	jalr	-350(ra) # 8000676a <sprintint>
    800068d0:	9ca9                	addw	s1,s1,a0
      break;
    800068d2:	b775                	j	8000687e <snprintf+0x7c>
    switch(c){
    800068d4:	09979863          	bne	a5,s9,80006964 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    800068d8:	f8843783          	ld	a5,-120(s0)
    800068dc:	00878713          	addi	a4,a5,8
    800068e0:	f8e43423          	sd	a4,-120(s0)
    800068e4:	4685                	li	a3,1
    800068e6:	4641                	li	a2,16
    800068e8:	438c                	lw	a1,0(a5)
    800068ea:	009b8533          	add	a0,s7,s1
    800068ee:	00000097          	auipc	ra,0x0
    800068f2:	e7c080e7          	jalr	-388(ra) # 8000676a <sprintint>
    800068f6:	9ca9                	addw	s1,s1,a0
      break;
    800068f8:	b759                	j	8000687e <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    800068fa:	f8843783          	ld	a5,-120(s0)
    800068fe:	00878713          	addi	a4,a5,8
    80006902:	f8e43423          	sd	a4,-120(s0)
    80006906:	639c                	ld	a5,0(a5)
    80006908:	c3b1                	beqz	a5,8000694c <snprintf+0x14a>
      for(; *s && off < sz; s++)
    8000690a:	0007c703          	lbu	a4,0(a5)
    8000690e:	db25                	beqz	a4,8000687e <snprintf+0x7c>
    80006910:	0134de63          	bge	s1,s3,8000692c <snprintf+0x12a>
    80006914:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006918:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    8000691c:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    8000691e:	0785                	addi	a5,a5,1
    80006920:	0007c703          	lbu	a4,0(a5)
    80006924:	df29                	beqz	a4,8000687e <snprintf+0x7c>
    80006926:	0685                	addi	a3,a3,1
    80006928:	fe9998e3          	bne	s3,s1,80006918 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    8000692c:	8526                	mv	a0,s1
    8000692e:	70e6                	ld	ra,120(sp)
    80006930:	7446                	ld	s0,112(sp)
    80006932:	74a6                	ld	s1,104(sp)
    80006934:	7906                	ld	s2,96(sp)
    80006936:	69e6                	ld	s3,88(sp)
    80006938:	6a46                	ld	s4,80(sp)
    8000693a:	6aa6                	ld	s5,72(sp)
    8000693c:	6b06                	ld	s6,64(sp)
    8000693e:	7be2                	ld	s7,56(sp)
    80006940:	7c42                	ld	s8,48(sp)
    80006942:	7ca2                	ld	s9,40(sp)
    80006944:	7d02                	ld	s10,32(sp)
    80006946:	6de2                	ld	s11,24(sp)
    80006948:	614d                	addi	sp,sp,176
    8000694a:	8082                	ret
        s = "(null)";
    8000694c:	00001797          	auipc	a5,0x1
    80006950:	6d478793          	addi	a5,a5,1748 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006954:	876e                	mv	a4,s11
    80006956:	bf6d                	j	80006910 <snprintf+0x10e>
  *s = c;
    80006958:	009b87b3          	add	a5,s7,s1
    8000695c:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    80006960:	2485                	addiw	s1,s1,1
      break;
    80006962:	bf31                	j	8000687e <snprintf+0x7c>
  *s = c;
    80006964:	009b8733          	add	a4,s7,s1
    80006968:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    8000696c:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006970:	975e                	add	a4,a4,s7
    80006972:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006976:	2489                	addiw	s1,s1,2
      break;
    80006978:	b719                	j	8000687e <snprintf+0x7c>
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
