
user/_pingpong:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
   0:	7139                	addi	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	0080                	addi	s0,sp,64
  int pid;
  int pipes1[2], pipes2[2];
  char buf[] = {'a'};
   a:	06100793          	li	a5,97
   e:	fcf40423          	sb	a5,-56(s0)
  pipe(pipes1);
  12:	fd840513          	addi	a0,s0,-40
  16:	00000097          	auipc	ra,0x0
  1a:	368080e7          	jalr	872(ra) # 37e <pipe>
  pipe(pipes2);
  1e:	fd040513          	addi	a0,s0,-48
  22:	00000097          	auipc	ra,0x0
  26:	35c080e7          	jalr	860(ra) # 37e <pipe>

  int ret = fork();
  2a:	00000097          	auipc	ra,0x0
  2e:	33c080e7          	jalr	828(ra) # 366 <fork>

  // parent send in pipes1[1], child receives in pipes1[0]
  // child send in pipes2[1], parent receives in pipes2[0]
  // should have checked close & read & write return value for error, but i am
  // lazy
  if (ret == 0) {
  32:	e135                	bnez	a0,96 <main+0x96>
    // i am the child
    pid = getpid();
  34:	00000097          	auipc	ra,0x0
  38:	3ba080e7          	jalr	954(ra) # 3ee <getpid>
  3c:	84aa                	mv	s1,a0
    close(pipes1[1]);
  3e:	fdc42503          	lw	a0,-36(s0)
  42:	00000097          	auipc	ra,0x0
  46:	354080e7          	jalr	852(ra) # 396 <close>
    close(pipes2[0]);
  4a:	fd042503          	lw	a0,-48(s0)
  4e:	00000097          	auipc	ra,0x0
  52:	348080e7          	jalr	840(ra) # 396 <close>
    read(pipes1[0], buf, 1);
  56:	4605                	li	a2,1
  58:	fc840593          	addi	a1,s0,-56
  5c:	fd842503          	lw	a0,-40(s0)
  60:	00000097          	auipc	ra,0x0
  64:	326080e7          	jalr	806(ra) # 386 <read>
    printf("%d: received ping\n", pid);
  68:	85a6                	mv	a1,s1
  6a:	00001517          	auipc	a0,0x1
  6e:	8b650513          	addi	a0,a0,-1866 # 920 <statistics+0x88>
  72:	00000097          	auipc	ra,0x0
  76:	684080e7          	jalr	1668(ra) # 6f6 <printf>
    write(pipes2[1], buf, 1);
  7a:	4605                	li	a2,1
  7c:	fc840593          	addi	a1,s0,-56
  80:	fd442503          	lw	a0,-44(s0)
  84:	00000097          	auipc	ra,0x0
  88:	30a080e7          	jalr	778(ra) # 38e <write>
    exit(0);
  8c:	4501                	li	a0,0
  8e:	00000097          	auipc	ra,0x0
  92:	2e0080e7          	jalr	736(ra) # 36e <exit>
  } else {
    // i am the parent
    pid = getpid();
  96:	00000097          	auipc	ra,0x0
  9a:	358080e7          	jalr	856(ra) # 3ee <getpid>
  9e:	84aa                	mv	s1,a0
    close(pipes1[0]);
  a0:	fd842503          	lw	a0,-40(s0)
  a4:	00000097          	auipc	ra,0x0
  a8:	2f2080e7          	jalr	754(ra) # 396 <close>
    close(pipes2[1]);
  ac:	fd442503          	lw	a0,-44(s0)
  b0:	00000097          	auipc	ra,0x0
  b4:	2e6080e7          	jalr	742(ra) # 396 <close>
    write(pipes1[1], buf, 1);
  b8:	4605                	li	a2,1
  ba:	fc840593          	addi	a1,s0,-56
  be:	fdc42503          	lw	a0,-36(s0)
  c2:	00000097          	auipc	ra,0x0
  c6:	2cc080e7          	jalr	716(ra) # 38e <write>
    read(pipes2[0], buf, 1);
  ca:	4605                	li	a2,1
  cc:	fc840593          	addi	a1,s0,-56
  d0:	fd042503          	lw	a0,-48(s0)
  d4:	00000097          	auipc	ra,0x0
  d8:	2b2080e7          	jalr	690(ra) # 386 <read>
    printf("%d: received pong\n", pid);
  dc:	85a6                	mv	a1,s1
  de:	00001517          	auipc	a0,0x1
  e2:	85a50513          	addi	a0,a0,-1958 # 938 <statistics+0xa0>
  e6:	00000097          	auipc	ra,0x0
  ea:	610080e7          	jalr	1552(ra) # 6f6 <printf>
    exit(0);
  ee:	4501                	li	a0,0
  f0:	00000097          	auipc	ra,0x0
  f4:	27e080e7          	jalr	638(ra) # 36e <exit>

00000000000000f8 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  f8:	1141                	addi	sp,sp,-16
  fa:	e422                	sd	s0,8(sp)
  fc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  fe:	87aa                	mv	a5,a0
 100:	0585                	addi	a1,a1,1
 102:	0785                	addi	a5,a5,1
 104:	fff5c703          	lbu	a4,-1(a1)
 108:	fee78fa3          	sb	a4,-1(a5)
 10c:	fb75                	bnez	a4,100 <strcpy+0x8>
    ;
  return os;
}
 10e:	6422                	ld	s0,8(sp)
 110:	0141                	addi	sp,sp,16
 112:	8082                	ret

0000000000000114 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 114:	1141                	addi	sp,sp,-16
 116:	e422                	sd	s0,8(sp)
 118:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 11a:	00054783          	lbu	a5,0(a0)
 11e:	cb91                	beqz	a5,132 <strcmp+0x1e>
 120:	0005c703          	lbu	a4,0(a1)
 124:	00f71763          	bne	a4,a5,132 <strcmp+0x1e>
    p++, q++;
 128:	0505                	addi	a0,a0,1
 12a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 12c:	00054783          	lbu	a5,0(a0)
 130:	fbe5                	bnez	a5,120 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 132:	0005c503          	lbu	a0,0(a1)
}
 136:	40a7853b          	subw	a0,a5,a0
 13a:	6422                	ld	s0,8(sp)
 13c:	0141                	addi	sp,sp,16
 13e:	8082                	ret

0000000000000140 <strlen>:

uint
strlen(const char *s)
{
 140:	1141                	addi	sp,sp,-16
 142:	e422                	sd	s0,8(sp)
 144:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 146:	00054783          	lbu	a5,0(a0)
 14a:	cf91                	beqz	a5,166 <strlen+0x26>
 14c:	0505                	addi	a0,a0,1
 14e:	87aa                	mv	a5,a0
 150:	4685                	li	a3,1
 152:	9e89                	subw	a3,a3,a0
 154:	00f6853b          	addw	a0,a3,a5
 158:	0785                	addi	a5,a5,1
 15a:	fff7c703          	lbu	a4,-1(a5)
 15e:	fb7d                	bnez	a4,154 <strlen+0x14>
    ;
  return n;
}
 160:	6422                	ld	s0,8(sp)
 162:	0141                	addi	sp,sp,16
 164:	8082                	ret
  for(n = 0; s[n]; n++)
 166:	4501                	li	a0,0
 168:	bfe5                	j	160 <strlen+0x20>

000000000000016a <memset>:

void*
memset(void *dst, int c, uint n)
{
 16a:	1141                	addi	sp,sp,-16
 16c:	e422                	sd	s0,8(sp)
 16e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 170:	ce09                	beqz	a2,18a <memset+0x20>
 172:	87aa                	mv	a5,a0
 174:	fff6071b          	addiw	a4,a2,-1
 178:	1702                	slli	a4,a4,0x20
 17a:	9301                	srli	a4,a4,0x20
 17c:	0705                	addi	a4,a4,1
 17e:	972a                	add	a4,a4,a0
    cdst[i] = c;
 180:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 184:	0785                	addi	a5,a5,1
 186:	fee79de3          	bne	a5,a4,180 <memset+0x16>
  }
  return dst;
}
 18a:	6422                	ld	s0,8(sp)
 18c:	0141                	addi	sp,sp,16
 18e:	8082                	ret

0000000000000190 <strchr>:

char*
strchr(const char *s, char c)
{
 190:	1141                	addi	sp,sp,-16
 192:	e422                	sd	s0,8(sp)
 194:	0800                	addi	s0,sp,16
  for(; *s; s++)
 196:	00054783          	lbu	a5,0(a0)
 19a:	cb99                	beqz	a5,1b0 <strchr+0x20>
    if(*s == c)
 19c:	00f58763          	beq	a1,a5,1aa <strchr+0x1a>
  for(; *s; s++)
 1a0:	0505                	addi	a0,a0,1
 1a2:	00054783          	lbu	a5,0(a0)
 1a6:	fbfd                	bnez	a5,19c <strchr+0xc>
      return (char*)s;
  return 0;
 1a8:	4501                	li	a0,0
}
 1aa:	6422                	ld	s0,8(sp)
 1ac:	0141                	addi	sp,sp,16
 1ae:	8082                	ret
  return 0;
 1b0:	4501                	li	a0,0
 1b2:	bfe5                	j	1aa <strchr+0x1a>

00000000000001b4 <gets>:

char*
gets(char *buf, int max)
{
 1b4:	711d                	addi	sp,sp,-96
 1b6:	ec86                	sd	ra,88(sp)
 1b8:	e8a2                	sd	s0,80(sp)
 1ba:	e4a6                	sd	s1,72(sp)
 1bc:	e0ca                	sd	s2,64(sp)
 1be:	fc4e                	sd	s3,56(sp)
 1c0:	f852                	sd	s4,48(sp)
 1c2:	f456                	sd	s5,40(sp)
 1c4:	f05a                	sd	s6,32(sp)
 1c6:	ec5e                	sd	s7,24(sp)
 1c8:	1080                	addi	s0,sp,96
 1ca:	8baa                	mv	s7,a0
 1cc:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1ce:	892a                	mv	s2,a0
 1d0:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1d2:	4aa9                	li	s5,10
 1d4:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1d6:	89a6                	mv	s3,s1
 1d8:	2485                	addiw	s1,s1,1
 1da:	0344d863          	bge	s1,s4,20a <gets+0x56>
    cc = read(0, &c, 1);
 1de:	4605                	li	a2,1
 1e0:	faf40593          	addi	a1,s0,-81
 1e4:	4501                	li	a0,0
 1e6:	00000097          	auipc	ra,0x0
 1ea:	1a0080e7          	jalr	416(ra) # 386 <read>
    if(cc < 1)
 1ee:	00a05e63          	blez	a0,20a <gets+0x56>
    buf[i++] = c;
 1f2:	faf44783          	lbu	a5,-81(s0)
 1f6:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1fa:	01578763          	beq	a5,s5,208 <gets+0x54>
 1fe:	0905                	addi	s2,s2,1
 200:	fd679be3          	bne	a5,s6,1d6 <gets+0x22>
  for(i=0; i+1 < max; ){
 204:	89a6                	mv	s3,s1
 206:	a011                	j	20a <gets+0x56>
 208:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 20a:	99de                	add	s3,s3,s7
 20c:	00098023          	sb	zero,0(s3)
  return buf;
}
 210:	855e                	mv	a0,s7
 212:	60e6                	ld	ra,88(sp)
 214:	6446                	ld	s0,80(sp)
 216:	64a6                	ld	s1,72(sp)
 218:	6906                	ld	s2,64(sp)
 21a:	79e2                	ld	s3,56(sp)
 21c:	7a42                	ld	s4,48(sp)
 21e:	7aa2                	ld	s5,40(sp)
 220:	7b02                	ld	s6,32(sp)
 222:	6be2                	ld	s7,24(sp)
 224:	6125                	addi	sp,sp,96
 226:	8082                	ret

0000000000000228 <stat>:

int
stat(const char *n, struct stat *st)
{
 228:	1101                	addi	sp,sp,-32
 22a:	ec06                	sd	ra,24(sp)
 22c:	e822                	sd	s0,16(sp)
 22e:	e426                	sd	s1,8(sp)
 230:	e04a                	sd	s2,0(sp)
 232:	1000                	addi	s0,sp,32
 234:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 236:	4581                	li	a1,0
 238:	00000097          	auipc	ra,0x0
 23c:	176080e7          	jalr	374(ra) # 3ae <open>
  if(fd < 0)
 240:	02054563          	bltz	a0,26a <stat+0x42>
 244:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 246:	85ca                	mv	a1,s2
 248:	00000097          	auipc	ra,0x0
 24c:	17e080e7          	jalr	382(ra) # 3c6 <fstat>
 250:	892a                	mv	s2,a0
  close(fd);
 252:	8526                	mv	a0,s1
 254:	00000097          	auipc	ra,0x0
 258:	142080e7          	jalr	322(ra) # 396 <close>
  return r;
}
 25c:	854a                	mv	a0,s2
 25e:	60e2                	ld	ra,24(sp)
 260:	6442                	ld	s0,16(sp)
 262:	64a2                	ld	s1,8(sp)
 264:	6902                	ld	s2,0(sp)
 266:	6105                	addi	sp,sp,32
 268:	8082                	ret
    return -1;
 26a:	597d                	li	s2,-1
 26c:	bfc5                	j	25c <stat+0x34>

000000000000026e <atoi>:

int
atoi(const char *s)
{
 26e:	1141                	addi	sp,sp,-16
 270:	e422                	sd	s0,8(sp)
 272:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 274:	00054603          	lbu	a2,0(a0)
 278:	fd06079b          	addiw	a5,a2,-48
 27c:	0ff7f793          	andi	a5,a5,255
 280:	4725                	li	a4,9
 282:	02f76963          	bltu	a4,a5,2b4 <atoi+0x46>
 286:	86aa                	mv	a3,a0
  n = 0;
 288:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 28a:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 28c:	0685                	addi	a3,a3,1
 28e:	0025179b          	slliw	a5,a0,0x2
 292:	9fa9                	addw	a5,a5,a0
 294:	0017979b          	slliw	a5,a5,0x1
 298:	9fb1                	addw	a5,a5,a2
 29a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 29e:	0006c603          	lbu	a2,0(a3)
 2a2:	fd06071b          	addiw	a4,a2,-48
 2a6:	0ff77713          	andi	a4,a4,255
 2aa:	fee5f1e3          	bgeu	a1,a4,28c <atoi+0x1e>
  return n;
}
 2ae:	6422                	ld	s0,8(sp)
 2b0:	0141                	addi	sp,sp,16
 2b2:	8082                	ret
  n = 0;
 2b4:	4501                	li	a0,0
 2b6:	bfe5                	j	2ae <atoi+0x40>

00000000000002b8 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2b8:	1141                	addi	sp,sp,-16
 2ba:	e422                	sd	s0,8(sp)
 2bc:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2be:	02b57663          	bgeu	a0,a1,2ea <memmove+0x32>
    while(n-- > 0)
 2c2:	02c05163          	blez	a2,2e4 <memmove+0x2c>
 2c6:	fff6079b          	addiw	a5,a2,-1
 2ca:	1782                	slli	a5,a5,0x20
 2cc:	9381                	srli	a5,a5,0x20
 2ce:	0785                	addi	a5,a5,1
 2d0:	97aa                	add	a5,a5,a0
  dst = vdst;
 2d2:	872a                	mv	a4,a0
      *dst++ = *src++;
 2d4:	0585                	addi	a1,a1,1
 2d6:	0705                	addi	a4,a4,1
 2d8:	fff5c683          	lbu	a3,-1(a1)
 2dc:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2e0:	fee79ae3          	bne	a5,a4,2d4 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2e4:	6422                	ld	s0,8(sp)
 2e6:	0141                	addi	sp,sp,16
 2e8:	8082                	ret
    dst += n;
 2ea:	00c50733          	add	a4,a0,a2
    src += n;
 2ee:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2f0:	fec05ae3          	blez	a2,2e4 <memmove+0x2c>
 2f4:	fff6079b          	addiw	a5,a2,-1
 2f8:	1782                	slli	a5,a5,0x20
 2fa:	9381                	srli	a5,a5,0x20
 2fc:	fff7c793          	not	a5,a5
 300:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 302:	15fd                	addi	a1,a1,-1
 304:	177d                	addi	a4,a4,-1
 306:	0005c683          	lbu	a3,0(a1)
 30a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 30e:	fee79ae3          	bne	a5,a4,302 <memmove+0x4a>
 312:	bfc9                	j	2e4 <memmove+0x2c>

0000000000000314 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 314:	1141                	addi	sp,sp,-16
 316:	e422                	sd	s0,8(sp)
 318:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 31a:	ca05                	beqz	a2,34a <memcmp+0x36>
 31c:	fff6069b          	addiw	a3,a2,-1
 320:	1682                	slli	a3,a3,0x20
 322:	9281                	srli	a3,a3,0x20
 324:	0685                	addi	a3,a3,1
 326:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 328:	00054783          	lbu	a5,0(a0)
 32c:	0005c703          	lbu	a4,0(a1)
 330:	00e79863          	bne	a5,a4,340 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 334:	0505                	addi	a0,a0,1
    p2++;
 336:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 338:	fed518e3          	bne	a0,a3,328 <memcmp+0x14>
  }
  return 0;
 33c:	4501                	li	a0,0
 33e:	a019                	j	344 <memcmp+0x30>
      return *p1 - *p2;
 340:	40e7853b          	subw	a0,a5,a4
}
 344:	6422                	ld	s0,8(sp)
 346:	0141                	addi	sp,sp,16
 348:	8082                	ret
  return 0;
 34a:	4501                	li	a0,0
 34c:	bfe5                	j	344 <memcmp+0x30>

000000000000034e <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 34e:	1141                	addi	sp,sp,-16
 350:	e406                	sd	ra,8(sp)
 352:	e022                	sd	s0,0(sp)
 354:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 356:	00000097          	auipc	ra,0x0
 35a:	f62080e7          	jalr	-158(ra) # 2b8 <memmove>
}
 35e:	60a2                	ld	ra,8(sp)
 360:	6402                	ld	s0,0(sp)
 362:	0141                	addi	sp,sp,16
 364:	8082                	ret

0000000000000366 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 366:	4885                	li	a7,1
 ecall
 368:	00000073          	ecall
 ret
 36c:	8082                	ret

000000000000036e <exit>:
.global exit
exit:
 li a7, SYS_exit
 36e:	4889                	li	a7,2
 ecall
 370:	00000073          	ecall
 ret
 374:	8082                	ret

0000000000000376 <wait>:
.global wait
wait:
 li a7, SYS_wait
 376:	488d                	li	a7,3
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 37e:	4891                	li	a7,4
 ecall
 380:	00000073          	ecall
 ret
 384:	8082                	ret

0000000000000386 <read>:
.global read
read:
 li a7, SYS_read
 386:	4895                	li	a7,5
 ecall
 388:	00000073          	ecall
 ret
 38c:	8082                	ret

000000000000038e <write>:
.global write
write:
 li a7, SYS_write
 38e:	48c1                	li	a7,16
 ecall
 390:	00000073          	ecall
 ret
 394:	8082                	ret

0000000000000396 <close>:
.global close
close:
 li a7, SYS_close
 396:	48d5                	li	a7,21
 ecall
 398:	00000073          	ecall
 ret
 39c:	8082                	ret

000000000000039e <kill>:
.global kill
kill:
 li a7, SYS_kill
 39e:	4899                	li	a7,6
 ecall
 3a0:	00000073          	ecall
 ret
 3a4:	8082                	ret

00000000000003a6 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3a6:	489d                	li	a7,7
 ecall
 3a8:	00000073          	ecall
 ret
 3ac:	8082                	ret

00000000000003ae <open>:
.global open
open:
 li a7, SYS_open
 3ae:	48bd                	li	a7,15
 ecall
 3b0:	00000073          	ecall
 ret
 3b4:	8082                	ret

00000000000003b6 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3b6:	48c5                	li	a7,17
 ecall
 3b8:	00000073          	ecall
 ret
 3bc:	8082                	ret

00000000000003be <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3be:	48c9                	li	a7,18
 ecall
 3c0:	00000073          	ecall
 ret
 3c4:	8082                	ret

00000000000003c6 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3c6:	48a1                	li	a7,8
 ecall
 3c8:	00000073          	ecall
 ret
 3cc:	8082                	ret

00000000000003ce <link>:
.global link
link:
 li a7, SYS_link
 3ce:	48cd                	li	a7,19
 ecall
 3d0:	00000073          	ecall
 ret
 3d4:	8082                	ret

00000000000003d6 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3d6:	48d1                	li	a7,20
 ecall
 3d8:	00000073          	ecall
 ret
 3dc:	8082                	ret

00000000000003de <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3de:	48a5                	li	a7,9
 ecall
 3e0:	00000073          	ecall
 ret
 3e4:	8082                	ret

00000000000003e6 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3e6:	48a9                	li	a7,10
 ecall
 3e8:	00000073          	ecall
 ret
 3ec:	8082                	ret

00000000000003ee <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3ee:	48ad                	li	a7,11
 ecall
 3f0:	00000073          	ecall
 ret
 3f4:	8082                	ret

00000000000003f6 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3f6:	48b1                	li	a7,12
 ecall
 3f8:	00000073          	ecall
 ret
 3fc:	8082                	ret

00000000000003fe <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3fe:	48b5                	li	a7,13
 ecall
 400:	00000073          	ecall
 ret
 404:	8082                	ret

0000000000000406 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 406:	48b9                	li	a7,14
 ecall
 408:	00000073          	ecall
 ret
 40c:	8082                	ret

000000000000040e <trace>:
.global trace
trace:
 li a7, SYS_trace
 40e:	48d9                	li	a7,22
 ecall
 410:	00000073          	ecall
 ret
 414:	8082                	ret

0000000000000416 <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 416:	48dd                	li	a7,23
 ecall
 418:	00000073          	ecall
 ret
 41c:	8082                	ret

000000000000041e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 41e:	1101                	addi	sp,sp,-32
 420:	ec06                	sd	ra,24(sp)
 422:	e822                	sd	s0,16(sp)
 424:	1000                	addi	s0,sp,32
 426:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 42a:	4605                	li	a2,1
 42c:	fef40593          	addi	a1,s0,-17
 430:	00000097          	auipc	ra,0x0
 434:	f5e080e7          	jalr	-162(ra) # 38e <write>
}
 438:	60e2                	ld	ra,24(sp)
 43a:	6442                	ld	s0,16(sp)
 43c:	6105                	addi	sp,sp,32
 43e:	8082                	ret

0000000000000440 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 440:	7139                	addi	sp,sp,-64
 442:	fc06                	sd	ra,56(sp)
 444:	f822                	sd	s0,48(sp)
 446:	f426                	sd	s1,40(sp)
 448:	f04a                	sd	s2,32(sp)
 44a:	ec4e                	sd	s3,24(sp)
 44c:	0080                	addi	s0,sp,64
 44e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 450:	c299                	beqz	a3,456 <printint+0x16>
 452:	0805c863          	bltz	a1,4e2 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 456:	2581                	sext.w	a1,a1
  neg = 0;
 458:	4881                	li	a7,0
 45a:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 45e:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 460:	2601                	sext.w	a2,a2
 462:	00000517          	auipc	a0,0x0
 466:	4f650513          	addi	a0,a0,1270 # 958 <digits>
 46a:	883a                	mv	a6,a4
 46c:	2705                	addiw	a4,a4,1
 46e:	02c5f7bb          	remuw	a5,a1,a2
 472:	1782                	slli	a5,a5,0x20
 474:	9381                	srli	a5,a5,0x20
 476:	97aa                	add	a5,a5,a0
 478:	0007c783          	lbu	a5,0(a5)
 47c:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 480:	0005879b          	sext.w	a5,a1
 484:	02c5d5bb          	divuw	a1,a1,a2
 488:	0685                	addi	a3,a3,1
 48a:	fec7f0e3          	bgeu	a5,a2,46a <printint+0x2a>
  if(neg)
 48e:	00088b63          	beqz	a7,4a4 <printint+0x64>
    buf[i++] = '-';
 492:	fd040793          	addi	a5,s0,-48
 496:	973e                	add	a4,a4,a5
 498:	02d00793          	li	a5,45
 49c:	fef70823          	sb	a5,-16(a4)
 4a0:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4a4:	02e05863          	blez	a4,4d4 <printint+0x94>
 4a8:	fc040793          	addi	a5,s0,-64
 4ac:	00e78933          	add	s2,a5,a4
 4b0:	fff78993          	addi	s3,a5,-1
 4b4:	99ba                	add	s3,s3,a4
 4b6:	377d                	addiw	a4,a4,-1
 4b8:	1702                	slli	a4,a4,0x20
 4ba:	9301                	srli	a4,a4,0x20
 4bc:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4c0:	fff94583          	lbu	a1,-1(s2)
 4c4:	8526                	mv	a0,s1
 4c6:	00000097          	auipc	ra,0x0
 4ca:	f58080e7          	jalr	-168(ra) # 41e <putc>
  while(--i >= 0)
 4ce:	197d                	addi	s2,s2,-1
 4d0:	ff3918e3          	bne	s2,s3,4c0 <printint+0x80>
}
 4d4:	70e2                	ld	ra,56(sp)
 4d6:	7442                	ld	s0,48(sp)
 4d8:	74a2                	ld	s1,40(sp)
 4da:	7902                	ld	s2,32(sp)
 4dc:	69e2                	ld	s3,24(sp)
 4de:	6121                	addi	sp,sp,64
 4e0:	8082                	ret
    x = -xx;
 4e2:	40b005bb          	negw	a1,a1
    neg = 1;
 4e6:	4885                	li	a7,1
    x = -xx;
 4e8:	bf8d                	j	45a <printint+0x1a>

00000000000004ea <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4ea:	7119                	addi	sp,sp,-128
 4ec:	fc86                	sd	ra,120(sp)
 4ee:	f8a2                	sd	s0,112(sp)
 4f0:	f4a6                	sd	s1,104(sp)
 4f2:	f0ca                	sd	s2,96(sp)
 4f4:	ecce                	sd	s3,88(sp)
 4f6:	e8d2                	sd	s4,80(sp)
 4f8:	e4d6                	sd	s5,72(sp)
 4fa:	e0da                	sd	s6,64(sp)
 4fc:	fc5e                	sd	s7,56(sp)
 4fe:	f862                	sd	s8,48(sp)
 500:	f466                	sd	s9,40(sp)
 502:	f06a                	sd	s10,32(sp)
 504:	ec6e                	sd	s11,24(sp)
 506:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 508:	0005c903          	lbu	s2,0(a1)
 50c:	18090f63          	beqz	s2,6aa <vprintf+0x1c0>
 510:	8aaa                	mv	s5,a0
 512:	8b32                	mv	s6,a2
 514:	00158493          	addi	s1,a1,1
  state = 0;
 518:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 51a:	02500a13          	li	s4,37
      if(c == 'd'){
 51e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 522:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 526:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 52a:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 52e:	00000b97          	auipc	s7,0x0
 532:	42ab8b93          	addi	s7,s7,1066 # 958 <digits>
 536:	a839                	j	554 <vprintf+0x6a>
        putc(fd, c);
 538:	85ca                	mv	a1,s2
 53a:	8556                	mv	a0,s5
 53c:	00000097          	auipc	ra,0x0
 540:	ee2080e7          	jalr	-286(ra) # 41e <putc>
 544:	a019                	j	54a <vprintf+0x60>
    } else if(state == '%'){
 546:	01498f63          	beq	s3,s4,564 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 54a:	0485                	addi	s1,s1,1
 54c:	fff4c903          	lbu	s2,-1(s1)
 550:	14090d63          	beqz	s2,6aa <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 554:	0009079b          	sext.w	a5,s2
    if(state == 0){
 558:	fe0997e3          	bnez	s3,546 <vprintf+0x5c>
      if(c == '%'){
 55c:	fd479ee3          	bne	a5,s4,538 <vprintf+0x4e>
        state = '%';
 560:	89be                	mv	s3,a5
 562:	b7e5                	j	54a <vprintf+0x60>
      if(c == 'd'){
 564:	05878063          	beq	a5,s8,5a4 <vprintf+0xba>
      } else if(c == 'l') {
 568:	05978c63          	beq	a5,s9,5c0 <vprintf+0xd6>
      } else if(c == 'x') {
 56c:	07a78863          	beq	a5,s10,5dc <vprintf+0xf2>
      } else if(c == 'p') {
 570:	09b78463          	beq	a5,s11,5f8 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 574:	07300713          	li	a4,115
 578:	0ce78663          	beq	a5,a4,644 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 57c:	06300713          	li	a4,99
 580:	0ee78e63          	beq	a5,a4,67c <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 584:	11478863          	beq	a5,s4,694 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 588:	85d2                	mv	a1,s4
 58a:	8556                	mv	a0,s5
 58c:	00000097          	auipc	ra,0x0
 590:	e92080e7          	jalr	-366(ra) # 41e <putc>
        putc(fd, c);
 594:	85ca                	mv	a1,s2
 596:	8556                	mv	a0,s5
 598:	00000097          	auipc	ra,0x0
 59c:	e86080e7          	jalr	-378(ra) # 41e <putc>
      }
      state = 0;
 5a0:	4981                	li	s3,0
 5a2:	b765                	j	54a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5a4:	008b0913          	addi	s2,s6,8
 5a8:	4685                	li	a3,1
 5aa:	4629                	li	a2,10
 5ac:	000b2583          	lw	a1,0(s6)
 5b0:	8556                	mv	a0,s5
 5b2:	00000097          	auipc	ra,0x0
 5b6:	e8e080e7          	jalr	-370(ra) # 440 <printint>
 5ba:	8b4a                	mv	s6,s2
      state = 0;
 5bc:	4981                	li	s3,0
 5be:	b771                	j	54a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5c0:	008b0913          	addi	s2,s6,8
 5c4:	4681                	li	a3,0
 5c6:	4629                	li	a2,10
 5c8:	000b2583          	lw	a1,0(s6)
 5cc:	8556                	mv	a0,s5
 5ce:	00000097          	auipc	ra,0x0
 5d2:	e72080e7          	jalr	-398(ra) # 440 <printint>
 5d6:	8b4a                	mv	s6,s2
      state = 0;
 5d8:	4981                	li	s3,0
 5da:	bf85                	j	54a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5dc:	008b0913          	addi	s2,s6,8
 5e0:	4681                	li	a3,0
 5e2:	4641                	li	a2,16
 5e4:	000b2583          	lw	a1,0(s6)
 5e8:	8556                	mv	a0,s5
 5ea:	00000097          	auipc	ra,0x0
 5ee:	e56080e7          	jalr	-426(ra) # 440 <printint>
 5f2:	8b4a                	mv	s6,s2
      state = 0;
 5f4:	4981                	li	s3,0
 5f6:	bf91                	j	54a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5f8:	008b0793          	addi	a5,s6,8
 5fc:	f8f43423          	sd	a5,-120(s0)
 600:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 604:	03000593          	li	a1,48
 608:	8556                	mv	a0,s5
 60a:	00000097          	auipc	ra,0x0
 60e:	e14080e7          	jalr	-492(ra) # 41e <putc>
  putc(fd, 'x');
 612:	85ea                	mv	a1,s10
 614:	8556                	mv	a0,s5
 616:	00000097          	auipc	ra,0x0
 61a:	e08080e7          	jalr	-504(ra) # 41e <putc>
 61e:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 620:	03c9d793          	srli	a5,s3,0x3c
 624:	97de                	add	a5,a5,s7
 626:	0007c583          	lbu	a1,0(a5)
 62a:	8556                	mv	a0,s5
 62c:	00000097          	auipc	ra,0x0
 630:	df2080e7          	jalr	-526(ra) # 41e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 634:	0992                	slli	s3,s3,0x4
 636:	397d                	addiw	s2,s2,-1
 638:	fe0914e3          	bnez	s2,620 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 63c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 640:	4981                	li	s3,0
 642:	b721                	j	54a <vprintf+0x60>
        s = va_arg(ap, char*);
 644:	008b0993          	addi	s3,s6,8
 648:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 64c:	02090163          	beqz	s2,66e <vprintf+0x184>
        while(*s != 0){
 650:	00094583          	lbu	a1,0(s2)
 654:	c9a1                	beqz	a1,6a4 <vprintf+0x1ba>
          putc(fd, *s);
 656:	8556                	mv	a0,s5
 658:	00000097          	auipc	ra,0x0
 65c:	dc6080e7          	jalr	-570(ra) # 41e <putc>
          s++;
 660:	0905                	addi	s2,s2,1
        while(*s != 0){
 662:	00094583          	lbu	a1,0(s2)
 666:	f9e5                	bnez	a1,656 <vprintf+0x16c>
        s = va_arg(ap, char*);
 668:	8b4e                	mv	s6,s3
      state = 0;
 66a:	4981                	li	s3,0
 66c:	bdf9                	j	54a <vprintf+0x60>
          s = "(null)";
 66e:	00000917          	auipc	s2,0x0
 672:	2e290913          	addi	s2,s2,738 # 950 <statistics+0xb8>
        while(*s != 0){
 676:	02800593          	li	a1,40
 67a:	bff1                	j	656 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 67c:	008b0913          	addi	s2,s6,8
 680:	000b4583          	lbu	a1,0(s6)
 684:	8556                	mv	a0,s5
 686:	00000097          	auipc	ra,0x0
 68a:	d98080e7          	jalr	-616(ra) # 41e <putc>
 68e:	8b4a                	mv	s6,s2
      state = 0;
 690:	4981                	li	s3,0
 692:	bd65                	j	54a <vprintf+0x60>
        putc(fd, c);
 694:	85d2                	mv	a1,s4
 696:	8556                	mv	a0,s5
 698:	00000097          	auipc	ra,0x0
 69c:	d86080e7          	jalr	-634(ra) # 41e <putc>
      state = 0;
 6a0:	4981                	li	s3,0
 6a2:	b565                	j	54a <vprintf+0x60>
        s = va_arg(ap, char*);
 6a4:	8b4e                	mv	s6,s3
      state = 0;
 6a6:	4981                	li	s3,0
 6a8:	b54d                	j	54a <vprintf+0x60>
    }
  }
}
 6aa:	70e6                	ld	ra,120(sp)
 6ac:	7446                	ld	s0,112(sp)
 6ae:	74a6                	ld	s1,104(sp)
 6b0:	7906                	ld	s2,96(sp)
 6b2:	69e6                	ld	s3,88(sp)
 6b4:	6a46                	ld	s4,80(sp)
 6b6:	6aa6                	ld	s5,72(sp)
 6b8:	6b06                	ld	s6,64(sp)
 6ba:	7be2                	ld	s7,56(sp)
 6bc:	7c42                	ld	s8,48(sp)
 6be:	7ca2                	ld	s9,40(sp)
 6c0:	7d02                	ld	s10,32(sp)
 6c2:	6de2                	ld	s11,24(sp)
 6c4:	6109                	addi	sp,sp,128
 6c6:	8082                	ret

00000000000006c8 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6c8:	715d                	addi	sp,sp,-80
 6ca:	ec06                	sd	ra,24(sp)
 6cc:	e822                	sd	s0,16(sp)
 6ce:	1000                	addi	s0,sp,32
 6d0:	e010                	sd	a2,0(s0)
 6d2:	e414                	sd	a3,8(s0)
 6d4:	e818                	sd	a4,16(s0)
 6d6:	ec1c                	sd	a5,24(s0)
 6d8:	03043023          	sd	a6,32(s0)
 6dc:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6e0:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6e4:	8622                	mv	a2,s0
 6e6:	00000097          	auipc	ra,0x0
 6ea:	e04080e7          	jalr	-508(ra) # 4ea <vprintf>
}
 6ee:	60e2                	ld	ra,24(sp)
 6f0:	6442                	ld	s0,16(sp)
 6f2:	6161                	addi	sp,sp,80
 6f4:	8082                	ret

00000000000006f6 <printf>:

void
printf(const char *fmt, ...)
{
 6f6:	711d                	addi	sp,sp,-96
 6f8:	ec06                	sd	ra,24(sp)
 6fa:	e822                	sd	s0,16(sp)
 6fc:	1000                	addi	s0,sp,32
 6fe:	e40c                	sd	a1,8(s0)
 700:	e810                	sd	a2,16(s0)
 702:	ec14                	sd	a3,24(s0)
 704:	f018                	sd	a4,32(s0)
 706:	f41c                	sd	a5,40(s0)
 708:	03043823          	sd	a6,48(s0)
 70c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 710:	00840613          	addi	a2,s0,8
 714:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 718:	85aa                	mv	a1,a0
 71a:	4505                	li	a0,1
 71c:	00000097          	auipc	ra,0x0
 720:	dce080e7          	jalr	-562(ra) # 4ea <vprintf>
}
 724:	60e2                	ld	ra,24(sp)
 726:	6442                	ld	s0,16(sp)
 728:	6125                	addi	sp,sp,96
 72a:	8082                	ret

000000000000072c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 72c:	1141                	addi	sp,sp,-16
 72e:	e422                	sd	s0,8(sp)
 730:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 732:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 736:	00000797          	auipc	a5,0x0
 73a:	2627b783          	ld	a5,610(a5) # 998 <freep>
 73e:	a805                	j	76e <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 740:	4618                	lw	a4,8(a2)
 742:	9db9                	addw	a1,a1,a4
 744:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 748:	6398                	ld	a4,0(a5)
 74a:	6318                	ld	a4,0(a4)
 74c:	fee53823          	sd	a4,-16(a0)
 750:	a091                	j	794 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 752:	ff852703          	lw	a4,-8(a0)
 756:	9e39                	addw	a2,a2,a4
 758:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 75a:	ff053703          	ld	a4,-16(a0)
 75e:	e398                	sd	a4,0(a5)
 760:	a099                	j	7a6 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 762:	6398                	ld	a4,0(a5)
 764:	00e7e463          	bltu	a5,a4,76c <free+0x40>
 768:	00e6ea63          	bltu	a3,a4,77c <free+0x50>
{
 76c:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 76e:	fed7fae3          	bgeu	a5,a3,762 <free+0x36>
 772:	6398                	ld	a4,0(a5)
 774:	00e6e463          	bltu	a3,a4,77c <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 778:	fee7eae3          	bltu	a5,a4,76c <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 77c:	ff852583          	lw	a1,-8(a0)
 780:	6390                	ld	a2,0(a5)
 782:	02059713          	slli	a4,a1,0x20
 786:	9301                	srli	a4,a4,0x20
 788:	0712                	slli	a4,a4,0x4
 78a:	9736                	add	a4,a4,a3
 78c:	fae60ae3          	beq	a2,a4,740 <free+0x14>
    bp->s.ptr = p->s.ptr;
 790:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 794:	4790                	lw	a2,8(a5)
 796:	02061713          	slli	a4,a2,0x20
 79a:	9301                	srli	a4,a4,0x20
 79c:	0712                	slli	a4,a4,0x4
 79e:	973e                	add	a4,a4,a5
 7a0:	fae689e3          	beq	a3,a4,752 <free+0x26>
  } else
    p->s.ptr = bp;
 7a4:	e394                	sd	a3,0(a5)
  freep = p;
 7a6:	00000717          	auipc	a4,0x0
 7aa:	1ef73923          	sd	a5,498(a4) # 998 <freep>
}
 7ae:	6422                	ld	s0,8(sp)
 7b0:	0141                	addi	sp,sp,16
 7b2:	8082                	ret

00000000000007b4 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7b4:	7139                	addi	sp,sp,-64
 7b6:	fc06                	sd	ra,56(sp)
 7b8:	f822                	sd	s0,48(sp)
 7ba:	f426                	sd	s1,40(sp)
 7bc:	f04a                	sd	s2,32(sp)
 7be:	ec4e                	sd	s3,24(sp)
 7c0:	e852                	sd	s4,16(sp)
 7c2:	e456                	sd	s5,8(sp)
 7c4:	e05a                	sd	s6,0(sp)
 7c6:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7c8:	02051493          	slli	s1,a0,0x20
 7cc:	9081                	srli	s1,s1,0x20
 7ce:	04bd                	addi	s1,s1,15
 7d0:	8091                	srli	s1,s1,0x4
 7d2:	0014899b          	addiw	s3,s1,1
 7d6:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7d8:	00000517          	auipc	a0,0x0
 7dc:	1c053503          	ld	a0,448(a0) # 998 <freep>
 7e0:	c515                	beqz	a0,80c <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7e2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7e4:	4798                	lw	a4,8(a5)
 7e6:	02977f63          	bgeu	a4,s1,824 <malloc+0x70>
 7ea:	8a4e                	mv	s4,s3
 7ec:	0009871b          	sext.w	a4,s3
 7f0:	6685                	lui	a3,0x1
 7f2:	00d77363          	bgeu	a4,a3,7f8 <malloc+0x44>
 7f6:	6a05                	lui	s4,0x1
 7f8:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7fc:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 800:	00000917          	auipc	s2,0x0
 804:	19890913          	addi	s2,s2,408 # 998 <freep>
  if(p == (char*)-1)
 808:	5afd                	li	s5,-1
 80a:	a88d                	j	87c <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 80c:	00000797          	auipc	a5,0x0
 810:	19478793          	addi	a5,a5,404 # 9a0 <base>
 814:	00000717          	auipc	a4,0x0
 818:	18f73223          	sd	a5,388(a4) # 998 <freep>
 81c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 81e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 822:	b7e1                	j	7ea <malloc+0x36>
      if(p->s.size == nunits)
 824:	02e48b63          	beq	s1,a4,85a <malloc+0xa6>
        p->s.size -= nunits;
 828:	4137073b          	subw	a4,a4,s3
 82c:	c798                	sw	a4,8(a5)
        p += p->s.size;
 82e:	1702                	slli	a4,a4,0x20
 830:	9301                	srli	a4,a4,0x20
 832:	0712                	slli	a4,a4,0x4
 834:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 836:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 83a:	00000717          	auipc	a4,0x0
 83e:	14a73f23          	sd	a0,350(a4) # 998 <freep>
      return (void*)(p + 1);
 842:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 846:	70e2                	ld	ra,56(sp)
 848:	7442                	ld	s0,48(sp)
 84a:	74a2                	ld	s1,40(sp)
 84c:	7902                	ld	s2,32(sp)
 84e:	69e2                	ld	s3,24(sp)
 850:	6a42                	ld	s4,16(sp)
 852:	6aa2                	ld	s5,8(sp)
 854:	6b02                	ld	s6,0(sp)
 856:	6121                	addi	sp,sp,64
 858:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 85a:	6398                	ld	a4,0(a5)
 85c:	e118                	sd	a4,0(a0)
 85e:	bff1                	j	83a <malloc+0x86>
  hp->s.size = nu;
 860:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 864:	0541                	addi	a0,a0,16
 866:	00000097          	auipc	ra,0x0
 86a:	ec6080e7          	jalr	-314(ra) # 72c <free>
  return freep;
 86e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 872:	d971                	beqz	a0,846 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 874:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 876:	4798                	lw	a4,8(a5)
 878:	fa9776e3          	bgeu	a4,s1,824 <malloc+0x70>
    if(p == freep)
 87c:	00093703          	ld	a4,0(s2)
 880:	853e                	mv	a0,a5
 882:	fef719e3          	bne	a4,a5,874 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 886:	8552                	mv	a0,s4
 888:	00000097          	auipc	ra,0x0
 88c:	b6e080e7          	jalr	-1170(ra) # 3f6 <sbrk>
  if(p == (char*)-1)
 890:	fd5518e3          	bne	a0,s5,860 <malloc+0xac>
        return 0;
 894:	4501                	li	a0,0
 896:	bf45                	j	846 <malloc+0x92>

0000000000000898 <statistics>:
#include "kernel/fcntl.h"
#include "user/user.h"

int
statistics(void *buf, int sz)
{
 898:	7179                	addi	sp,sp,-48
 89a:	f406                	sd	ra,40(sp)
 89c:	f022                	sd	s0,32(sp)
 89e:	ec26                	sd	s1,24(sp)
 8a0:	e84a                	sd	s2,16(sp)
 8a2:	e44e                	sd	s3,8(sp)
 8a4:	e052                	sd	s4,0(sp)
 8a6:	1800                	addi	s0,sp,48
 8a8:	8a2a                	mv	s4,a0
 8aa:	892e                	mv	s2,a1
  int fd, i, n;
  
  fd = open("statistics", O_RDONLY);
 8ac:	4581                	li	a1,0
 8ae:	00000517          	auipc	a0,0x0
 8b2:	0c250513          	addi	a0,a0,194 # 970 <digits+0x18>
 8b6:	00000097          	auipc	ra,0x0
 8ba:	af8080e7          	jalr	-1288(ra) # 3ae <open>
  if(fd < 0) {
 8be:	04054263          	bltz	a0,902 <statistics+0x6a>
 8c2:	89aa                	mv	s3,a0
      fprintf(2, "stats: open failed\n");
      exit(1);
  }
  for (i = 0; i < sz; ) {
 8c4:	4481                	li	s1,0
 8c6:	03205063          	blez	s2,8e6 <statistics+0x4e>
    if ((n = read(fd, buf+i, sz-i)) < 0) {
 8ca:	4099063b          	subw	a2,s2,s1
 8ce:	009a05b3          	add	a1,s4,s1
 8d2:	854e                	mv	a0,s3
 8d4:	00000097          	auipc	ra,0x0
 8d8:	ab2080e7          	jalr	-1358(ra) # 386 <read>
 8dc:	00054563          	bltz	a0,8e6 <statistics+0x4e>
      break;
    }
    i += n;
 8e0:	9ca9                	addw	s1,s1,a0
  for (i = 0; i < sz; ) {
 8e2:	ff24c4e3          	blt	s1,s2,8ca <statistics+0x32>
  }
  close(fd);
 8e6:	854e                	mv	a0,s3
 8e8:	00000097          	auipc	ra,0x0
 8ec:	aae080e7          	jalr	-1362(ra) # 396 <close>
  return i;
}
 8f0:	8526                	mv	a0,s1
 8f2:	70a2                	ld	ra,40(sp)
 8f4:	7402                	ld	s0,32(sp)
 8f6:	64e2                	ld	s1,24(sp)
 8f8:	6942                	ld	s2,16(sp)
 8fa:	69a2                	ld	s3,8(sp)
 8fc:	6a02                	ld	s4,0(sp)
 8fe:	6145                	addi	sp,sp,48
 900:	8082                	ret
      fprintf(2, "stats: open failed\n");
 902:	00000597          	auipc	a1,0x0
 906:	07e58593          	addi	a1,a1,126 # 980 <digits+0x28>
 90a:	4509                	li	a0,2
 90c:	00000097          	auipc	ra,0x0
 910:	dbc080e7          	jalr	-580(ra) # 6c8 <fprintf>
      exit(1);
 914:	4505                	li	a0,1
 916:	00000097          	auipc	ra,0x0
 91a:	a58080e7          	jalr	-1448(ra) # 36e <exit>
