
user/_xargs:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

#define buf_size 512

int main(int argc, char *argv[]) {
   0:	a8010113          	addi	sp,sp,-1408
   4:	56113c23          	sd	ra,1400(sp)
   8:	56813823          	sd	s0,1392(sp)
   c:	56913423          	sd	s1,1384(sp)
  10:	57213023          	sd	s2,1376(sp)
  14:	55313c23          	sd	s3,1368(sp)
  18:	55413823          	sd	s4,1360(sp)
  1c:	55513423          	sd	s5,1352(sp)
  20:	55613023          	sd	s6,1344(sp)
  24:	53713c23          	sd	s7,1336(sp)
  28:	53813823          	sd	s8,1328(sp)
  2c:	53913423          	sd	s9,1320(sp)
  30:	58010413          	addi	s0,sp,1408
  34:	8a2a                	mv	s4,a0
  36:	8bae                	mv	s7,a1
  char buf[buf_size + 1] = {0};
  38:	d8043c23          	sd	zero,-616(s0)
  3c:	1f900613          	li	a2,505
  40:	4581                	li	a1,0
  42:	da040513          	addi	a0,s0,-608
  46:	00000097          	auipc	ra,0x0
  4a:	20a080e7          	jalr	522(ra) # 250 <memset>
  uint occupy = 0;
  char *xargv[MAXARG] = {0};
  4e:	10000613          	li	a2,256
  52:	4581                	li	a1,0
  54:	c9840513          	addi	a0,s0,-872
  58:	00000097          	auipc	ra,0x0
  5c:	1f8080e7          	jalr	504(ra) # 250 <memset>
  int stdin_end = 0;

  for (int i = 1; i < argc; i++) {
  60:	4785                	li	a5,1
  62:	0347d463          	bge	a5,s4,8a <main+0x8a>
  66:	008b8693          	addi	a3,s7,8
  6a:	c9840793          	addi	a5,s0,-872
  6e:	ffea071b          	addiw	a4,s4,-2
  72:	1702                	slli	a4,a4,0x20
  74:	9301                	srli	a4,a4,0x20
  76:	070e                	slli	a4,a4,0x3
  78:	ca040613          	addi	a2,s0,-864
  7c:	9732                	add	a4,a4,a2
    xargv[i - 1] = argv[i];
  7e:	6290                	ld	a2,0(a3)
  80:	e390                	sd	a2,0(a5)
  for (int i = 1; i < argc; i++) {
  82:	06a1                	addi	a3,a3,8
  84:	07a1                	addi	a5,a5,8
  86:	fee79ce3          	bne	a5,a4,7e <main+0x7e>
  int stdin_end = 0;
  8a:	4b01                	li	s6,0
  uint occupy = 0;
  8c:	4a81                	li	s5,0
    // process lines read
    char *line_end = strchr(buf, '\n');
    while (line_end) {
      char xbuf[buf_size + 1] = {0};
      memcpy(xbuf, buf, line_end - buf);
      xargv[argc - 1] = xbuf;
  8e:	3a7d                	addiw	s4,s4,-1
  90:	0a0e                	slli	s4,s4,0x3
  92:	fa040793          	addi	a5,s0,-96
  96:	9a3e                	add	s4,s4,a5
  while (!(stdin_end && occupy == 0)) {
  98:	020b0063          	beqz	s6,b8 <main+0xb8>
  9c:	120a8c63          	beqz	s5,1d4 <main+0x1d4>
    char *line_end = strchr(buf, '\n');
  a0:	45a9                	li	a1,10
  a2:	d9840513          	addi	a0,s0,-616
  a6:	00000097          	auipc	ra,0x0
  aa:	1d0080e7          	jalr	464(ra) # 276 <strchr>
  ae:	84aa                	mv	s1,a0
    while (line_end) {
  b0:	d565                	beqz	a0,98 <main+0x98>
      memcpy(xbuf, buf, line_end - buf);
  b2:	d9840993          	addi	s3,s0,-616
  b6:	a0bd                	j	124 <main+0x124>
      int read_bytes = read(0, buf + occupy, remain_size);
  b8:	020a9593          	slli	a1,s5,0x20
  bc:	9181                	srli	a1,a1,0x20
  be:	20000613          	li	a2,512
  c2:	4156063b          	subw	a2,a2,s5
  c6:	d9840793          	addi	a5,s0,-616
  ca:	95be                	add	a1,a1,a5
  cc:	4501                	li	a0,0
  ce:	00000097          	auipc	ra,0x0
  d2:	39e080e7          	jalr	926(ra) # 46c <read>
  d6:	84aa                	mv	s1,a0
      if (read_bytes < 0) {
  d8:	00054663          	bltz	a0,e4 <main+0xe4>
      if (read_bytes == 0) {
  dc:	cd11                	beqz	a0,f8 <main+0xf8>
      occupy += read_bytes;
  de:	01548abb          	addw	s5,s1,s5
  e2:	bf7d                	j	a0 <main+0xa0>
        fprintf(2, "xargs: read returns -1 error\n");
  e4:	00001597          	auipc	a1,0x1
  e8:	92458593          	addi	a1,a1,-1756 # a08 <statistics+0x8a>
  ec:	4509                	li	a0,2
  ee:	00000097          	auipc	ra,0x0
  f2:	6c0080e7          	jalr	1728(ra) # 7ae <fprintf>
      if (read_bytes == 0) {
  f6:	b7e5                	j	de <main+0xde>
        close(0);
  f8:	4501                	li	a0,0
  fa:	00000097          	auipc	ra,0x0
  fe:	382080e7          	jalr	898(ra) # 47c <close>
        stdin_end = 1;
 102:	4b05                	li	s6,1
 104:	bfe9                	j	de <main+0xde>
      int ret = fork();
      if (ret == 0) {
        // i am child
        if (!stdin_end) {
          close(0);
 106:	00000097          	auipc	ra,0x0
 10a:	376080e7          	jalr	886(ra) # 47c <close>
        }
        if (exec(argv[1], xargv) < 0) {
 10e:	c9840593          	addi	a1,s0,-872
 112:	008bb503          	ld	a0,8(s7)
 116:	00000097          	auipc	ra,0x0
 11a:	376080e7          	jalr	886(ra) # 48c <exec>
 11e:	04054463          	bltz	a0,166 <main+0x166>
    while (line_end) {
 122:	d8bd                	beqz	s1,98 <main+0x98>
      char xbuf[buf_size + 1] = {0};
 124:	a8043823          	sd	zero,-1392(s0)
 128:	1f900613          	li	a2,505
 12c:	4581                	li	a1,0
 12e:	a9840513          	addi	a0,s0,-1384
 132:	00000097          	auipc	ra,0x0
 136:	11e080e7          	jalr	286(ra) # 250 <memset>
      memcpy(xbuf, buf, line_end - buf);
 13a:	4134893b          	subw	s2,s1,s3
 13e:	864a                	mv	a2,s2
 140:	85ce                	mv	a1,s3
 142:	a9040513          	addi	a0,s0,-1392
 146:	00000097          	auipc	ra,0x0
 14a:	2ee080e7          	jalr	750(ra) # 434 <memcpy>
      xargv[argc - 1] = xbuf;
 14e:	a9040793          	addi	a5,s0,-1392
 152:	cefa3c23          	sd	a5,-776(s4)
      int ret = fork();
 156:	00000097          	auipc	ra,0x0
 15a:	2f6080e7          	jalr	758(ra) # 44c <fork>
      if (ret == 0) {
 15e:	e115                	bnez	a0,182 <main+0x182>
        if (!stdin_end) {
 160:	fa0b17e3          	bnez	s6,10e <main+0x10e>
 164:	b74d                	j	106 <main+0x106>
          fprintf(2, "xargs: exec fails with -1\n");
 166:	00001597          	auipc	a1,0x1
 16a:	8c258593          	addi	a1,a1,-1854 # a28 <statistics+0xaa>
 16e:	4509                	li	a0,2
 170:	00000097          	auipc	ra,0x0
 174:	63e080e7          	jalr	1598(ra) # 7ae <fprintf>
          exit(1);
 178:	4505                	li	a0,1
 17a:	00000097          	auipc	ra,0x0
 17e:	2da080e7          	jalr	730(ra) # 454 <exit>
        }
      } else {
        // trim out line already processed
        memmove(buf, line_end + 1, occupy - (line_end - buf) - 1);
 182:	fffa8c9b          	addiw	s9,s5,-1
 186:	412c8c3b          	subw	s8,s9,s2
 18a:	000c0a9b          	sext.w	s5,s8
 18e:	8656                	mv	a2,s5
 190:	00148593          	addi	a1,s1,1
 194:	854e                	mv	a0,s3
 196:	00000097          	auipc	ra,0x0
 19a:	208080e7          	jalr	520(ra) # 39e <memmove>
        occupy -= line_end - buf + 1;
        memset(buf + occupy, 0, buf_size - occupy);
 19e:	4199063b          	subw	a2,s2,s9
 1a2:	020c1513          	slli	a0,s8,0x20
 1a6:	9101                	srli	a0,a0,0x20
 1a8:	2006061b          	addiw	a2,a2,512
 1ac:	4581                	li	a1,0
 1ae:	954e                	add	a0,a0,s3
 1b0:	00000097          	auipc	ra,0x0
 1b4:	0a0080e7          	jalr	160(ra) # 250 <memset>
        // harvest zombie
        int pid;
        wait(&pid);
 1b8:	a8c40513          	addi	a0,s0,-1396
 1bc:	00000097          	auipc	ra,0x0
 1c0:	2a0080e7          	jalr	672(ra) # 45c <wait>

        line_end = strchr(buf, '\n');
 1c4:	45a9                	li	a1,10
 1c6:	854e                	mv	a0,s3
 1c8:	00000097          	auipc	ra,0x0
 1cc:	0ae080e7          	jalr	174(ra) # 276 <strchr>
 1d0:	84aa                	mv	s1,a0
 1d2:	bf81                	j	122 <main+0x122>
      }
    }
  }
  exit(0);
 1d4:	4501                	li	a0,0
 1d6:	00000097          	auipc	ra,0x0
 1da:	27e080e7          	jalr	638(ra) # 454 <exit>

00000000000001de <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 1de:	1141                	addi	sp,sp,-16
 1e0:	e422                	sd	s0,8(sp)
 1e2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 1e4:	87aa                	mv	a5,a0
 1e6:	0585                	addi	a1,a1,1
 1e8:	0785                	addi	a5,a5,1
 1ea:	fff5c703          	lbu	a4,-1(a1)
 1ee:	fee78fa3          	sb	a4,-1(a5)
 1f2:	fb75                	bnez	a4,1e6 <strcpy+0x8>
    ;
  return os;
}
 1f4:	6422                	ld	s0,8(sp)
 1f6:	0141                	addi	sp,sp,16
 1f8:	8082                	ret

00000000000001fa <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1fa:	1141                	addi	sp,sp,-16
 1fc:	e422                	sd	s0,8(sp)
 1fe:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 200:	00054783          	lbu	a5,0(a0)
 204:	cb91                	beqz	a5,218 <strcmp+0x1e>
 206:	0005c703          	lbu	a4,0(a1)
 20a:	00f71763          	bne	a4,a5,218 <strcmp+0x1e>
    p++, q++;
 20e:	0505                	addi	a0,a0,1
 210:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 212:	00054783          	lbu	a5,0(a0)
 216:	fbe5                	bnez	a5,206 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 218:	0005c503          	lbu	a0,0(a1)
}
 21c:	40a7853b          	subw	a0,a5,a0
 220:	6422                	ld	s0,8(sp)
 222:	0141                	addi	sp,sp,16
 224:	8082                	ret

0000000000000226 <strlen>:

uint
strlen(const char *s)
{
 226:	1141                	addi	sp,sp,-16
 228:	e422                	sd	s0,8(sp)
 22a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 22c:	00054783          	lbu	a5,0(a0)
 230:	cf91                	beqz	a5,24c <strlen+0x26>
 232:	0505                	addi	a0,a0,1
 234:	87aa                	mv	a5,a0
 236:	4685                	li	a3,1
 238:	9e89                	subw	a3,a3,a0
 23a:	00f6853b          	addw	a0,a3,a5
 23e:	0785                	addi	a5,a5,1
 240:	fff7c703          	lbu	a4,-1(a5)
 244:	fb7d                	bnez	a4,23a <strlen+0x14>
    ;
  return n;
}
 246:	6422                	ld	s0,8(sp)
 248:	0141                	addi	sp,sp,16
 24a:	8082                	ret
  for(n = 0; s[n]; n++)
 24c:	4501                	li	a0,0
 24e:	bfe5                	j	246 <strlen+0x20>

0000000000000250 <memset>:

void*
memset(void *dst, int c, uint n)
{
 250:	1141                	addi	sp,sp,-16
 252:	e422                	sd	s0,8(sp)
 254:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 256:	ce09                	beqz	a2,270 <memset+0x20>
 258:	87aa                	mv	a5,a0
 25a:	fff6071b          	addiw	a4,a2,-1
 25e:	1702                	slli	a4,a4,0x20
 260:	9301                	srli	a4,a4,0x20
 262:	0705                	addi	a4,a4,1
 264:	972a                	add	a4,a4,a0
    cdst[i] = c;
 266:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 26a:	0785                	addi	a5,a5,1
 26c:	fee79de3          	bne	a5,a4,266 <memset+0x16>
  }
  return dst;
}
 270:	6422                	ld	s0,8(sp)
 272:	0141                	addi	sp,sp,16
 274:	8082                	ret

0000000000000276 <strchr>:

char*
strchr(const char *s, char c)
{
 276:	1141                	addi	sp,sp,-16
 278:	e422                	sd	s0,8(sp)
 27a:	0800                	addi	s0,sp,16
  for(; *s; s++)
 27c:	00054783          	lbu	a5,0(a0)
 280:	cb99                	beqz	a5,296 <strchr+0x20>
    if(*s == c)
 282:	00f58763          	beq	a1,a5,290 <strchr+0x1a>
  for(; *s; s++)
 286:	0505                	addi	a0,a0,1
 288:	00054783          	lbu	a5,0(a0)
 28c:	fbfd                	bnez	a5,282 <strchr+0xc>
      return (char*)s;
  return 0;
 28e:	4501                	li	a0,0
}
 290:	6422                	ld	s0,8(sp)
 292:	0141                	addi	sp,sp,16
 294:	8082                	ret
  return 0;
 296:	4501                	li	a0,0
 298:	bfe5                	j	290 <strchr+0x1a>

000000000000029a <gets>:

char*
gets(char *buf, int max)
{
 29a:	711d                	addi	sp,sp,-96
 29c:	ec86                	sd	ra,88(sp)
 29e:	e8a2                	sd	s0,80(sp)
 2a0:	e4a6                	sd	s1,72(sp)
 2a2:	e0ca                	sd	s2,64(sp)
 2a4:	fc4e                	sd	s3,56(sp)
 2a6:	f852                	sd	s4,48(sp)
 2a8:	f456                	sd	s5,40(sp)
 2aa:	f05a                	sd	s6,32(sp)
 2ac:	ec5e                	sd	s7,24(sp)
 2ae:	1080                	addi	s0,sp,96
 2b0:	8baa                	mv	s7,a0
 2b2:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 2b4:	892a                	mv	s2,a0
 2b6:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 2b8:	4aa9                	li	s5,10
 2ba:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 2bc:	89a6                	mv	s3,s1
 2be:	2485                	addiw	s1,s1,1
 2c0:	0344d863          	bge	s1,s4,2f0 <gets+0x56>
    cc = read(0, &c, 1);
 2c4:	4605                	li	a2,1
 2c6:	faf40593          	addi	a1,s0,-81
 2ca:	4501                	li	a0,0
 2cc:	00000097          	auipc	ra,0x0
 2d0:	1a0080e7          	jalr	416(ra) # 46c <read>
    if(cc < 1)
 2d4:	00a05e63          	blez	a0,2f0 <gets+0x56>
    buf[i++] = c;
 2d8:	faf44783          	lbu	a5,-81(s0)
 2dc:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 2e0:	01578763          	beq	a5,s5,2ee <gets+0x54>
 2e4:	0905                	addi	s2,s2,1
 2e6:	fd679be3          	bne	a5,s6,2bc <gets+0x22>
  for(i=0; i+1 < max; ){
 2ea:	89a6                	mv	s3,s1
 2ec:	a011                	j	2f0 <gets+0x56>
 2ee:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2f0:	99de                	add	s3,s3,s7
 2f2:	00098023          	sb	zero,0(s3)
  return buf;
}
 2f6:	855e                	mv	a0,s7
 2f8:	60e6                	ld	ra,88(sp)
 2fa:	6446                	ld	s0,80(sp)
 2fc:	64a6                	ld	s1,72(sp)
 2fe:	6906                	ld	s2,64(sp)
 300:	79e2                	ld	s3,56(sp)
 302:	7a42                	ld	s4,48(sp)
 304:	7aa2                	ld	s5,40(sp)
 306:	7b02                	ld	s6,32(sp)
 308:	6be2                	ld	s7,24(sp)
 30a:	6125                	addi	sp,sp,96
 30c:	8082                	ret

000000000000030e <stat>:

int
stat(const char *n, struct stat *st)
{
 30e:	1101                	addi	sp,sp,-32
 310:	ec06                	sd	ra,24(sp)
 312:	e822                	sd	s0,16(sp)
 314:	e426                	sd	s1,8(sp)
 316:	e04a                	sd	s2,0(sp)
 318:	1000                	addi	s0,sp,32
 31a:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 31c:	4581                	li	a1,0
 31e:	00000097          	auipc	ra,0x0
 322:	176080e7          	jalr	374(ra) # 494 <open>
  if(fd < 0)
 326:	02054563          	bltz	a0,350 <stat+0x42>
 32a:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 32c:	85ca                	mv	a1,s2
 32e:	00000097          	auipc	ra,0x0
 332:	17e080e7          	jalr	382(ra) # 4ac <fstat>
 336:	892a                	mv	s2,a0
  close(fd);
 338:	8526                	mv	a0,s1
 33a:	00000097          	auipc	ra,0x0
 33e:	142080e7          	jalr	322(ra) # 47c <close>
  return r;
}
 342:	854a                	mv	a0,s2
 344:	60e2                	ld	ra,24(sp)
 346:	6442                	ld	s0,16(sp)
 348:	64a2                	ld	s1,8(sp)
 34a:	6902                	ld	s2,0(sp)
 34c:	6105                	addi	sp,sp,32
 34e:	8082                	ret
    return -1;
 350:	597d                	li	s2,-1
 352:	bfc5                	j	342 <stat+0x34>

0000000000000354 <atoi>:

int
atoi(const char *s)
{
 354:	1141                	addi	sp,sp,-16
 356:	e422                	sd	s0,8(sp)
 358:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 35a:	00054603          	lbu	a2,0(a0)
 35e:	fd06079b          	addiw	a5,a2,-48
 362:	0ff7f793          	andi	a5,a5,255
 366:	4725                	li	a4,9
 368:	02f76963          	bltu	a4,a5,39a <atoi+0x46>
 36c:	86aa                	mv	a3,a0
  n = 0;
 36e:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 370:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 372:	0685                	addi	a3,a3,1
 374:	0025179b          	slliw	a5,a0,0x2
 378:	9fa9                	addw	a5,a5,a0
 37a:	0017979b          	slliw	a5,a5,0x1
 37e:	9fb1                	addw	a5,a5,a2
 380:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 384:	0006c603          	lbu	a2,0(a3)
 388:	fd06071b          	addiw	a4,a2,-48
 38c:	0ff77713          	andi	a4,a4,255
 390:	fee5f1e3          	bgeu	a1,a4,372 <atoi+0x1e>
  return n;
}
 394:	6422                	ld	s0,8(sp)
 396:	0141                	addi	sp,sp,16
 398:	8082                	ret
  n = 0;
 39a:	4501                	li	a0,0
 39c:	bfe5                	j	394 <atoi+0x40>

000000000000039e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 39e:	1141                	addi	sp,sp,-16
 3a0:	e422                	sd	s0,8(sp)
 3a2:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 3a4:	02b57663          	bgeu	a0,a1,3d0 <memmove+0x32>
    while(n-- > 0)
 3a8:	02c05163          	blez	a2,3ca <memmove+0x2c>
 3ac:	fff6079b          	addiw	a5,a2,-1
 3b0:	1782                	slli	a5,a5,0x20
 3b2:	9381                	srli	a5,a5,0x20
 3b4:	0785                	addi	a5,a5,1
 3b6:	97aa                	add	a5,a5,a0
  dst = vdst;
 3b8:	872a                	mv	a4,a0
      *dst++ = *src++;
 3ba:	0585                	addi	a1,a1,1
 3bc:	0705                	addi	a4,a4,1
 3be:	fff5c683          	lbu	a3,-1(a1)
 3c2:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 3c6:	fee79ae3          	bne	a5,a4,3ba <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 3ca:	6422                	ld	s0,8(sp)
 3cc:	0141                	addi	sp,sp,16
 3ce:	8082                	ret
    dst += n;
 3d0:	00c50733          	add	a4,a0,a2
    src += n;
 3d4:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 3d6:	fec05ae3          	blez	a2,3ca <memmove+0x2c>
 3da:	fff6079b          	addiw	a5,a2,-1
 3de:	1782                	slli	a5,a5,0x20
 3e0:	9381                	srli	a5,a5,0x20
 3e2:	fff7c793          	not	a5,a5
 3e6:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 3e8:	15fd                	addi	a1,a1,-1
 3ea:	177d                	addi	a4,a4,-1
 3ec:	0005c683          	lbu	a3,0(a1)
 3f0:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3f4:	fee79ae3          	bne	a5,a4,3e8 <memmove+0x4a>
 3f8:	bfc9                	j	3ca <memmove+0x2c>

00000000000003fa <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 3fa:	1141                	addi	sp,sp,-16
 3fc:	e422                	sd	s0,8(sp)
 3fe:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 400:	ca05                	beqz	a2,430 <memcmp+0x36>
 402:	fff6069b          	addiw	a3,a2,-1
 406:	1682                	slli	a3,a3,0x20
 408:	9281                	srli	a3,a3,0x20
 40a:	0685                	addi	a3,a3,1
 40c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 40e:	00054783          	lbu	a5,0(a0)
 412:	0005c703          	lbu	a4,0(a1)
 416:	00e79863          	bne	a5,a4,426 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 41a:	0505                	addi	a0,a0,1
    p2++;
 41c:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 41e:	fed518e3          	bne	a0,a3,40e <memcmp+0x14>
  }
  return 0;
 422:	4501                	li	a0,0
 424:	a019                	j	42a <memcmp+0x30>
      return *p1 - *p2;
 426:	40e7853b          	subw	a0,a5,a4
}
 42a:	6422                	ld	s0,8(sp)
 42c:	0141                	addi	sp,sp,16
 42e:	8082                	ret
  return 0;
 430:	4501                	li	a0,0
 432:	bfe5                	j	42a <memcmp+0x30>

0000000000000434 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 434:	1141                	addi	sp,sp,-16
 436:	e406                	sd	ra,8(sp)
 438:	e022                	sd	s0,0(sp)
 43a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 43c:	00000097          	auipc	ra,0x0
 440:	f62080e7          	jalr	-158(ra) # 39e <memmove>
}
 444:	60a2                	ld	ra,8(sp)
 446:	6402                	ld	s0,0(sp)
 448:	0141                	addi	sp,sp,16
 44a:	8082                	ret

000000000000044c <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 44c:	4885                	li	a7,1
 ecall
 44e:	00000073          	ecall
 ret
 452:	8082                	ret

0000000000000454 <exit>:
.global exit
exit:
 li a7, SYS_exit
 454:	4889                	li	a7,2
 ecall
 456:	00000073          	ecall
 ret
 45a:	8082                	ret

000000000000045c <wait>:
.global wait
wait:
 li a7, SYS_wait
 45c:	488d                	li	a7,3
 ecall
 45e:	00000073          	ecall
 ret
 462:	8082                	ret

0000000000000464 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 464:	4891                	li	a7,4
 ecall
 466:	00000073          	ecall
 ret
 46a:	8082                	ret

000000000000046c <read>:
.global read
read:
 li a7, SYS_read
 46c:	4895                	li	a7,5
 ecall
 46e:	00000073          	ecall
 ret
 472:	8082                	ret

0000000000000474 <write>:
.global write
write:
 li a7, SYS_write
 474:	48c1                	li	a7,16
 ecall
 476:	00000073          	ecall
 ret
 47a:	8082                	ret

000000000000047c <close>:
.global close
close:
 li a7, SYS_close
 47c:	48d5                	li	a7,21
 ecall
 47e:	00000073          	ecall
 ret
 482:	8082                	ret

0000000000000484 <kill>:
.global kill
kill:
 li a7, SYS_kill
 484:	4899                	li	a7,6
 ecall
 486:	00000073          	ecall
 ret
 48a:	8082                	ret

000000000000048c <exec>:
.global exec
exec:
 li a7, SYS_exec
 48c:	489d                	li	a7,7
 ecall
 48e:	00000073          	ecall
 ret
 492:	8082                	ret

0000000000000494 <open>:
.global open
open:
 li a7, SYS_open
 494:	48bd                	li	a7,15
 ecall
 496:	00000073          	ecall
 ret
 49a:	8082                	ret

000000000000049c <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 49c:	48c5                	li	a7,17
 ecall
 49e:	00000073          	ecall
 ret
 4a2:	8082                	ret

00000000000004a4 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 4a4:	48c9                	li	a7,18
 ecall
 4a6:	00000073          	ecall
 ret
 4aa:	8082                	ret

00000000000004ac <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 4ac:	48a1                	li	a7,8
 ecall
 4ae:	00000073          	ecall
 ret
 4b2:	8082                	ret

00000000000004b4 <link>:
.global link
link:
 li a7, SYS_link
 4b4:	48cd                	li	a7,19
 ecall
 4b6:	00000073          	ecall
 ret
 4ba:	8082                	ret

00000000000004bc <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 4bc:	48d1                	li	a7,20
 ecall
 4be:	00000073          	ecall
 ret
 4c2:	8082                	ret

00000000000004c4 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 4c4:	48a5                	li	a7,9
 ecall
 4c6:	00000073          	ecall
 ret
 4ca:	8082                	ret

00000000000004cc <dup>:
.global dup
dup:
 li a7, SYS_dup
 4cc:	48a9                	li	a7,10
 ecall
 4ce:	00000073          	ecall
 ret
 4d2:	8082                	ret

00000000000004d4 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 4d4:	48ad                	li	a7,11
 ecall
 4d6:	00000073          	ecall
 ret
 4da:	8082                	ret

00000000000004dc <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 4dc:	48b1                	li	a7,12
 ecall
 4de:	00000073          	ecall
 ret
 4e2:	8082                	ret

00000000000004e4 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 4e4:	48b5                	li	a7,13
 ecall
 4e6:	00000073          	ecall
 ret
 4ea:	8082                	ret

00000000000004ec <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4ec:	48b9                	li	a7,14
 ecall
 4ee:	00000073          	ecall
 ret
 4f2:	8082                	ret

00000000000004f4 <trace>:
.global trace
trace:
 li a7, SYS_trace
 4f4:	48d9                	li	a7,22
 ecall
 4f6:	00000073          	ecall
 ret
 4fa:	8082                	ret

00000000000004fc <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 4fc:	48dd                	li	a7,23
 ecall
 4fe:	00000073          	ecall
 ret
 502:	8082                	ret

0000000000000504 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 504:	1101                	addi	sp,sp,-32
 506:	ec06                	sd	ra,24(sp)
 508:	e822                	sd	s0,16(sp)
 50a:	1000                	addi	s0,sp,32
 50c:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 510:	4605                	li	a2,1
 512:	fef40593          	addi	a1,s0,-17
 516:	00000097          	auipc	ra,0x0
 51a:	f5e080e7          	jalr	-162(ra) # 474 <write>
}
 51e:	60e2                	ld	ra,24(sp)
 520:	6442                	ld	s0,16(sp)
 522:	6105                	addi	sp,sp,32
 524:	8082                	ret

0000000000000526 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 526:	7139                	addi	sp,sp,-64
 528:	fc06                	sd	ra,56(sp)
 52a:	f822                	sd	s0,48(sp)
 52c:	f426                	sd	s1,40(sp)
 52e:	f04a                	sd	s2,32(sp)
 530:	ec4e                	sd	s3,24(sp)
 532:	0080                	addi	s0,sp,64
 534:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 536:	c299                	beqz	a3,53c <printint+0x16>
 538:	0805c863          	bltz	a1,5c8 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 53c:	2581                	sext.w	a1,a1
  neg = 0;
 53e:	4881                	li	a7,0
 540:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 544:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 546:	2601                	sext.w	a2,a2
 548:	00000517          	auipc	a0,0x0
 54c:	50850513          	addi	a0,a0,1288 # a50 <digits>
 550:	883a                	mv	a6,a4
 552:	2705                	addiw	a4,a4,1
 554:	02c5f7bb          	remuw	a5,a1,a2
 558:	1782                	slli	a5,a5,0x20
 55a:	9381                	srli	a5,a5,0x20
 55c:	97aa                	add	a5,a5,a0
 55e:	0007c783          	lbu	a5,0(a5)
 562:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 566:	0005879b          	sext.w	a5,a1
 56a:	02c5d5bb          	divuw	a1,a1,a2
 56e:	0685                	addi	a3,a3,1
 570:	fec7f0e3          	bgeu	a5,a2,550 <printint+0x2a>
  if(neg)
 574:	00088b63          	beqz	a7,58a <printint+0x64>
    buf[i++] = '-';
 578:	fd040793          	addi	a5,s0,-48
 57c:	973e                	add	a4,a4,a5
 57e:	02d00793          	li	a5,45
 582:	fef70823          	sb	a5,-16(a4)
 586:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 58a:	02e05863          	blez	a4,5ba <printint+0x94>
 58e:	fc040793          	addi	a5,s0,-64
 592:	00e78933          	add	s2,a5,a4
 596:	fff78993          	addi	s3,a5,-1
 59a:	99ba                	add	s3,s3,a4
 59c:	377d                	addiw	a4,a4,-1
 59e:	1702                	slli	a4,a4,0x20
 5a0:	9301                	srli	a4,a4,0x20
 5a2:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 5a6:	fff94583          	lbu	a1,-1(s2)
 5aa:	8526                	mv	a0,s1
 5ac:	00000097          	auipc	ra,0x0
 5b0:	f58080e7          	jalr	-168(ra) # 504 <putc>
  while(--i >= 0)
 5b4:	197d                	addi	s2,s2,-1
 5b6:	ff3918e3          	bne	s2,s3,5a6 <printint+0x80>
}
 5ba:	70e2                	ld	ra,56(sp)
 5bc:	7442                	ld	s0,48(sp)
 5be:	74a2                	ld	s1,40(sp)
 5c0:	7902                	ld	s2,32(sp)
 5c2:	69e2                	ld	s3,24(sp)
 5c4:	6121                	addi	sp,sp,64
 5c6:	8082                	ret
    x = -xx;
 5c8:	40b005bb          	negw	a1,a1
    neg = 1;
 5cc:	4885                	li	a7,1
    x = -xx;
 5ce:	bf8d                	j	540 <printint+0x1a>

00000000000005d0 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5d0:	7119                	addi	sp,sp,-128
 5d2:	fc86                	sd	ra,120(sp)
 5d4:	f8a2                	sd	s0,112(sp)
 5d6:	f4a6                	sd	s1,104(sp)
 5d8:	f0ca                	sd	s2,96(sp)
 5da:	ecce                	sd	s3,88(sp)
 5dc:	e8d2                	sd	s4,80(sp)
 5de:	e4d6                	sd	s5,72(sp)
 5e0:	e0da                	sd	s6,64(sp)
 5e2:	fc5e                	sd	s7,56(sp)
 5e4:	f862                	sd	s8,48(sp)
 5e6:	f466                	sd	s9,40(sp)
 5e8:	f06a                	sd	s10,32(sp)
 5ea:	ec6e                	sd	s11,24(sp)
 5ec:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5ee:	0005c903          	lbu	s2,0(a1)
 5f2:	18090f63          	beqz	s2,790 <vprintf+0x1c0>
 5f6:	8aaa                	mv	s5,a0
 5f8:	8b32                	mv	s6,a2
 5fa:	00158493          	addi	s1,a1,1
  state = 0;
 5fe:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 600:	02500a13          	li	s4,37
      if(c == 'd'){
 604:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 608:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 60c:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 610:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 614:	00000b97          	auipc	s7,0x0
 618:	43cb8b93          	addi	s7,s7,1084 # a50 <digits>
 61c:	a839                	j	63a <vprintf+0x6a>
        putc(fd, c);
 61e:	85ca                	mv	a1,s2
 620:	8556                	mv	a0,s5
 622:	00000097          	auipc	ra,0x0
 626:	ee2080e7          	jalr	-286(ra) # 504 <putc>
 62a:	a019                	j	630 <vprintf+0x60>
    } else if(state == '%'){
 62c:	01498f63          	beq	s3,s4,64a <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 630:	0485                	addi	s1,s1,1
 632:	fff4c903          	lbu	s2,-1(s1)
 636:	14090d63          	beqz	s2,790 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 63a:	0009079b          	sext.w	a5,s2
    if(state == 0){
 63e:	fe0997e3          	bnez	s3,62c <vprintf+0x5c>
      if(c == '%'){
 642:	fd479ee3          	bne	a5,s4,61e <vprintf+0x4e>
        state = '%';
 646:	89be                	mv	s3,a5
 648:	b7e5                	j	630 <vprintf+0x60>
      if(c == 'd'){
 64a:	05878063          	beq	a5,s8,68a <vprintf+0xba>
      } else if(c == 'l') {
 64e:	05978c63          	beq	a5,s9,6a6 <vprintf+0xd6>
      } else if(c == 'x') {
 652:	07a78863          	beq	a5,s10,6c2 <vprintf+0xf2>
      } else if(c == 'p') {
 656:	09b78463          	beq	a5,s11,6de <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 65a:	07300713          	li	a4,115
 65e:	0ce78663          	beq	a5,a4,72a <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 662:	06300713          	li	a4,99
 666:	0ee78e63          	beq	a5,a4,762 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 66a:	11478863          	beq	a5,s4,77a <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 66e:	85d2                	mv	a1,s4
 670:	8556                	mv	a0,s5
 672:	00000097          	auipc	ra,0x0
 676:	e92080e7          	jalr	-366(ra) # 504 <putc>
        putc(fd, c);
 67a:	85ca                	mv	a1,s2
 67c:	8556                	mv	a0,s5
 67e:	00000097          	auipc	ra,0x0
 682:	e86080e7          	jalr	-378(ra) # 504 <putc>
      }
      state = 0;
 686:	4981                	li	s3,0
 688:	b765                	j	630 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 68a:	008b0913          	addi	s2,s6,8
 68e:	4685                	li	a3,1
 690:	4629                	li	a2,10
 692:	000b2583          	lw	a1,0(s6)
 696:	8556                	mv	a0,s5
 698:	00000097          	auipc	ra,0x0
 69c:	e8e080e7          	jalr	-370(ra) # 526 <printint>
 6a0:	8b4a                	mv	s6,s2
      state = 0;
 6a2:	4981                	li	s3,0
 6a4:	b771                	j	630 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 6a6:	008b0913          	addi	s2,s6,8
 6aa:	4681                	li	a3,0
 6ac:	4629                	li	a2,10
 6ae:	000b2583          	lw	a1,0(s6)
 6b2:	8556                	mv	a0,s5
 6b4:	00000097          	auipc	ra,0x0
 6b8:	e72080e7          	jalr	-398(ra) # 526 <printint>
 6bc:	8b4a                	mv	s6,s2
      state = 0;
 6be:	4981                	li	s3,0
 6c0:	bf85                	j	630 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 6c2:	008b0913          	addi	s2,s6,8
 6c6:	4681                	li	a3,0
 6c8:	4641                	li	a2,16
 6ca:	000b2583          	lw	a1,0(s6)
 6ce:	8556                	mv	a0,s5
 6d0:	00000097          	auipc	ra,0x0
 6d4:	e56080e7          	jalr	-426(ra) # 526 <printint>
 6d8:	8b4a                	mv	s6,s2
      state = 0;
 6da:	4981                	li	s3,0
 6dc:	bf91                	j	630 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6de:	008b0793          	addi	a5,s6,8
 6e2:	f8f43423          	sd	a5,-120(s0)
 6e6:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6ea:	03000593          	li	a1,48
 6ee:	8556                	mv	a0,s5
 6f0:	00000097          	auipc	ra,0x0
 6f4:	e14080e7          	jalr	-492(ra) # 504 <putc>
  putc(fd, 'x');
 6f8:	85ea                	mv	a1,s10
 6fa:	8556                	mv	a0,s5
 6fc:	00000097          	auipc	ra,0x0
 700:	e08080e7          	jalr	-504(ra) # 504 <putc>
 704:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 706:	03c9d793          	srli	a5,s3,0x3c
 70a:	97de                	add	a5,a5,s7
 70c:	0007c583          	lbu	a1,0(a5)
 710:	8556                	mv	a0,s5
 712:	00000097          	auipc	ra,0x0
 716:	df2080e7          	jalr	-526(ra) # 504 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 71a:	0992                	slli	s3,s3,0x4
 71c:	397d                	addiw	s2,s2,-1
 71e:	fe0914e3          	bnez	s2,706 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 722:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 726:	4981                	li	s3,0
 728:	b721                	j	630 <vprintf+0x60>
        s = va_arg(ap, char*);
 72a:	008b0993          	addi	s3,s6,8
 72e:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 732:	02090163          	beqz	s2,754 <vprintf+0x184>
        while(*s != 0){
 736:	00094583          	lbu	a1,0(s2)
 73a:	c9a1                	beqz	a1,78a <vprintf+0x1ba>
          putc(fd, *s);
 73c:	8556                	mv	a0,s5
 73e:	00000097          	auipc	ra,0x0
 742:	dc6080e7          	jalr	-570(ra) # 504 <putc>
          s++;
 746:	0905                	addi	s2,s2,1
        while(*s != 0){
 748:	00094583          	lbu	a1,0(s2)
 74c:	f9e5                	bnez	a1,73c <vprintf+0x16c>
        s = va_arg(ap, char*);
 74e:	8b4e                	mv	s6,s3
      state = 0;
 750:	4981                	li	s3,0
 752:	bdf9                	j	630 <vprintf+0x60>
          s = "(null)";
 754:	00000917          	auipc	s2,0x0
 758:	2f490913          	addi	s2,s2,756 # a48 <statistics+0xca>
        while(*s != 0){
 75c:	02800593          	li	a1,40
 760:	bff1                	j	73c <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 762:	008b0913          	addi	s2,s6,8
 766:	000b4583          	lbu	a1,0(s6)
 76a:	8556                	mv	a0,s5
 76c:	00000097          	auipc	ra,0x0
 770:	d98080e7          	jalr	-616(ra) # 504 <putc>
 774:	8b4a                	mv	s6,s2
      state = 0;
 776:	4981                	li	s3,0
 778:	bd65                	j	630 <vprintf+0x60>
        putc(fd, c);
 77a:	85d2                	mv	a1,s4
 77c:	8556                	mv	a0,s5
 77e:	00000097          	auipc	ra,0x0
 782:	d86080e7          	jalr	-634(ra) # 504 <putc>
      state = 0;
 786:	4981                	li	s3,0
 788:	b565                	j	630 <vprintf+0x60>
        s = va_arg(ap, char*);
 78a:	8b4e                	mv	s6,s3
      state = 0;
 78c:	4981                	li	s3,0
 78e:	b54d                	j	630 <vprintf+0x60>
    }
  }
}
 790:	70e6                	ld	ra,120(sp)
 792:	7446                	ld	s0,112(sp)
 794:	74a6                	ld	s1,104(sp)
 796:	7906                	ld	s2,96(sp)
 798:	69e6                	ld	s3,88(sp)
 79a:	6a46                	ld	s4,80(sp)
 79c:	6aa6                	ld	s5,72(sp)
 79e:	6b06                	ld	s6,64(sp)
 7a0:	7be2                	ld	s7,56(sp)
 7a2:	7c42                	ld	s8,48(sp)
 7a4:	7ca2                	ld	s9,40(sp)
 7a6:	7d02                	ld	s10,32(sp)
 7a8:	6de2                	ld	s11,24(sp)
 7aa:	6109                	addi	sp,sp,128
 7ac:	8082                	ret

00000000000007ae <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 7ae:	715d                	addi	sp,sp,-80
 7b0:	ec06                	sd	ra,24(sp)
 7b2:	e822                	sd	s0,16(sp)
 7b4:	1000                	addi	s0,sp,32
 7b6:	e010                	sd	a2,0(s0)
 7b8:	e414                	sd	a3,8(s0)
 7ba:	e818                	sd	a4,16(s0)
 7bc:	ec1c                	sd	a5,24(s0)
 7be:	03043023          	sd	a6,32(s0)
 7c2:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 7c6:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 7ca:	8622                	mv	a2,s0
 7cc:	00000097          	auipc	ra,0x0
 7d0:	e04080e7          	jalr	-508(ra) # 5d0 <vprintf>
}
 7d4:	60e2                	ld	ra,24(sp)
 7d6:	6442                	ld	s0,16(sp)
 7d8:	6161                	addi	sp,sp,80
 7da:	8082                	ret

00000000000007dc <printf>:

void
printf(const char *fmt, ...)
{
 7dc:	711d                	addi	sp,sp,-96
 7de:	ec06                	sd	ra,24(sp)
 7e0:	e822                	sd	s0,16(sp)
 7e2:	1000                	addi	s0,sp,32
 7e4:	e40c                	sd	a1,8(s0)
 7e6:	e810                	sd	a2,16(s0)
 7e8:	ec14                	sd	a3,24(s0)
 7ea:	f018                	sd	a4,32(s0)
 7ec:	f41c                	sd	a5,40(s0)
 7ee:	03043823          	sd	a6,48(s0)
 7f2:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7f6:	00840613          	addi	a2,s0,8
 7fa:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7fe:	85aa                	mv	a1,a0
 800:	4505                	li	a0,1
 802:	00000097          	auipc	ra,0x0
 806:	dce080e7          	jalr	-562(ra) # 5d0 <vprintf>
}
 80a:	60e2                	ld	ra,24(sp)
 80c:	6442                	ld	s0,16(sp)
 80e:	6125                	addi	sp,sp,96
 810:	8082                	ret

0000000000000812 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 812:	1141                	addi	sp,sp,-16
 814:	e422                	sd	s0,8(sp)
 816:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 818:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 81c:	00000797          	auipc	a5,0x0
 820:	2747b783          	ld	a5,628(a5) # a90 <freep>
 824:	a805                	j	854 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 826:	4618                	lw	a4,8(a2)
 828:	9db9                	addw	a1,a1,a4
 82a:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 82e:	6398                	ld	a4,0(a5)
 830:	6318                	ld	a4,0(a4)
 832:	fee53823          	sd	a4,-16(a0)
 836:	a091                	j	87a <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 838:	ff852703          	lw	a4,-8(a0)
 83c:	9e39                	addw	a2,a2,a4
 83e:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 840:	ff053703          	ld	a4,-16(a0)
 844:	e398                	sd	a4,0(a5)
 846:	a099                	j	88c <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 848:	6398                	ld	a4,0(a5)
 84a:	00e7e463          	bltu	a5,a4,852 <free+0x40>
 84e:	00e6ea63          	bltu	a3,a4,862 <free+0x50>
{
 852:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 854:	fed7fae3          	bgeu	a5,a3,848 <free+0x36>
 858:	6398                	ld	a4,0(a5)
 85a:	00e6e463          	bltu	a3,a4,862 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 85e:	fee7eae3          	bltu	a5,a4,852 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 862:	ff852583          	lw	a1,-8(a0)
 866:	6390                	ld	a2,0(a5)
 868:	02059713          	slli	a4,a1,0x20
 86c:	9301                	srli	a4,a4,0x20
 86e:	0712                	slli	a4,a4,0x4
 870:	9736                	add	a4,a4,a3
 872:	fae60ae3          	beq	a2,a4,826 <free+0x14>
    bp->s.ptr = p->s.ptr;
 876:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 87a:	4790                	lw	a2,8(a5)
 87c:	02061713          	slli	a4,a2,0x20
 880:	9301                	srli	a4,a4,0x20
 882:	0712                	slli	a4,a4,0x4
 884:	973e                	add	a4,a4,a5
 886:	fae689e3          	beq	a3,a4,838 <free+0x26>
  } else
    p->s.ptr = bp;
 88a:	e394                	sd	a3,0(a5)
  freep = p;
 88c:	00000717          	auipc	a4,0x0
 890:	20f73223          	sd	a5,516(a4) # a90 <freep>
}
 894:	6422                	ld	s0,8(sp)
 896:	0141                	addi	sp,sp,16
 898:	8082                	ret

000000000000089a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 89a:	7139                	addi	sp,sp,-64
 89c:	fc06                	sd	ra,56(sp)
 89e:	f822                	sd	s0,48(sp)
 8a0:	f426                	sd	s1,40(sp)
 8a2:	f04a                	sd	s2,32(sp)
 8a4:	ec4e                	sd	s3,24(sp)
 8a6:	e852                	sd	s4,16(sp)
 8a8:	e456                	sd	s5,8(sp)
 8aa:	e05a                	sd	s6,0(sp)
 8ac:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 8ae:	02051493          	slli	s1,a0,0x20
 8b2:	9081                	srli	s1,s1,0x20
 8b4:	04bd                	addi	s1,s1,15
 8b6:	8091                	srli	s1,s1,0x4
 8b8:	0014899b          	addiw	s3,s1,1
 8bc:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 8be:	00000517          	auipc	a0,0x0
 8c2:	1d253503          	ld	a0,466(a0) # a90 <freep>
 8c6:	c515                	beqz	a0,8f2 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8c8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8ca:	4798                	lw	a4,8(a5)
 8cc:	02977f63          	bgeu	a4,s1,90a <malloc+0x70>
 8d0:	8a4e                	mv	s4,s3
 8d2:	0009871b          	sext.w	a4,s3
 8d6:	6685                	lui	a3,0x1
 8d8:	00d77363          	bgeu	a4,a3,8de <malloc+0x44>
 8dc:	6a05                	lui	s4,0x1
 8de:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8e2:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8e6:	00000917          	auipc	s2,0x0
 8ea:	1aa90913          	addi	s2,s2,426 # a90 <freep>
  if(p == (char*)-1)
 8ee:	5afd                	li	s5,-1
 8f0:	a88d                	j	962 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 8f2:	00000797          	auipc	a5,0x0
 8f6:	1a678793          	addi	a5,a5,422 # a98 <base>
 8fa:	00000717          	auipc	a4,0x0
 8fe:	18f73b23          	sd	a5,406(a4) # a90 <freep>
 902:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 904:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 908:	b7e1                	j	8d0 <malloc+0x36>
      if(p->s.size == nunits)
 90a:	02e48b63          	beq	s1,a4,940 <malloc+0xa6>
        p->s.size -= nunits;
 90e:	4137073b          	subw	a4,a4,s3
 912:	c798                	sw	a4,8(a5)
        p += p->s.size;
 914:	1702                	slli	a4,a4,0x20
 916:	9301                	srli	a4,a4,0x20
 918:	0712                	slli	a4,a4,0x4
 91a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 91c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 920:	00000717          	auipc	a4,0x0
 924:	16a73823          	sd	a0,368(a4) # a90 <freep>
      return (void*)(p + 1);
 928:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 92c:	70e2                	ld	ra,56(sp)
 92e:	7442                	ld	s0,48(sp)
 930:	74a2                	ld	s1,40(sp)
 932:	7902                	ld	s2,32(sp)
 934:	69e2                	ld	s3,24(sp)
 936:	6a42                	ld	s4,16(sp)
 938:	6aa2                	ld	s5,8(sp)
 93a:	6b02                	ld	s6,0(sp)
 93c:	6121                	addi	sp,sp,64
 93e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 940:	6398                	ld	a4,0(a5)
 942:	e118                	sd	a4,0(a0)
 944:	bff1                	j	920 <malloc+0x86>
  hp->s.size = nu;
 946:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 94a:	0541                	addi	a0,a0,16
 94c:	00000097          	auipc	ra,0x0
 950:	ec6080e7          	jalr	-314(ra) # 812 <free>
  return freep;
 954:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 958:	d971                	beqz	a0,92c <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 95a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 95c:	4798                	lw	a4,8(a5)
 95e:	fa9776e3          	bgeu	a4,s1,90a <malloc+0x70>
    if(p == freep)
 962:	00093703          	ld	a4,0(s2)
 966:	853e                	mv	a0,a5
 968:	fef719e3          	bne	a4,a5,95a <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 96c:	8552                	mv	a0,s4
 96e:	00000097          	auipc	ra,0x0
 972:	b6e080e7          	jalr	-1170(ra) # 4dc <sbrk>
  if(p == (char*)-1)
 976:	fd5518e3          	bne	a0,s5,946 <malloc+0xac>
        return 0;
 97a:	4501                	li	a0,0
 97c:	bf45                	j	92c <malloc+0x92>

000000000000097e <statistics>:
#include "kernel/fcntl.h"
#include "user/user.h"

int
statistics(void *buf, int sz)
{
 97e:	7179                	addi	sp,sp,-48
 980:	f406                	sd	ra,40(sp)
 982:	f022                	sd	s0,32(sp)
 984:	ec26                	sd	s1,24(sp)
 986:	e84a                	sd	s2,16(sp)
 988:	e44e                	sd	s3,8(sp)
 98a:	e052                	sd	s4,0(sp)
 98c:	1800                	addi	s0,sp,48
 98e:	8a2a                	mv	s4,a0
 990:	892e                	mv	s2,a1
  int fd, i, n;
  
  fd = open("statistics", O_RDONLY);
 992:	4581                	li	a1,0
 994:	00000517          	auipc	a0,0x0
 998:	0d450513          	addi	a0,a0,212 # a68 <digits+0x18>
 99c:	00000097          	auipc	ra,0x0
 9a0:	af8080e7          	jalr	-1288(ra) # 494 <open>
  if(fd < 0) {
 9a4:	04054263          	bltz	a0,9e8 <statistics+0x6a>
 9a8:	89aa                	mv	s3,a0
      fprintf(2, "stats: open failed\n");
      exit(1);
  }
  for (i = 0; i < sz; ) {
 9aa:	4481                	li	s1,0
 9ac:	03205063          	blez	s2,9cc <statistics+0x4e>
    if ((n = read(fd, buf+i, sz-i)) < 0) {
 9b0:	4099063b          	subw	a2,s2,s1
 9b4:	009a05b3          	add	a1,s4,s1
 9b8:	854e                	mv	a0,s3
 9ba:	00000097          	auipc	ra,0x0
 9be:	ab2080e7          	jalr	-1358(ra) # 46c <read>
 9c2:	00054563          	bltz	a0,9cc <statistics+0x4e>
      break;
    }
    i += n;
 9c6:	9ca9                	addw	s1,s1,a0
  for (i = 0; i < sz; ) {
 9c8:	ff24c4e3          	blt	s1,s2,9b0 <statistics+0x32>
  }
  close(fd);
 9cc:	854e                	mv	a0,s3
 9ce:	00000097          	auipc	ra,0x0
 9d2:	aae080e7          	jalr	-1362(ra) # 47c <close>
  return i;
}
 9d6:	8526                	mv	a0,s1
 9d8:	70a2                	ld	ra,40(sp)
 9da:	7402                	ld	s0,32(sp)
 9dc:	64e2                	ld	s1,24(sp)
 9de:	6942                	ld	s2,16(sp)
 9e0:	69a2                	ld	s3,8(sp)
 9e2:	6a02                	ld	s4,0(sp)
 9e4:	6145                	addi	sp,sp,48
 9e6:	8082                	ret
      fprintf(2, "stats: open failed\n");
 9e8:	00000597          	auipc	a1,0x0
 9ec:	09058593          	addi	a1,a1,144 # a78 <digits+0x28>
 9f0:	4509                	li	a0,2
 9f2:	00000097          	auipc	ra,0x0
 9f6:	dbc080e7          	jalr	-580(ra) # 7ae <fprintf>
      exit(1);
 9fa:	4505                	li	a0,1
 9fc:	00000097          	auipc	ra,0x0
 a00:	a58080e7          	jalr	-1448(ra) # 454 <exit>
