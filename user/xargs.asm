
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
  e8:	88c58593          	addi	a1,a1,-1908 # 970 <malloc+0xe6>
  ec:	4509                	li	a0,2
  ee:	00000097          	auipc	ra,0x0
  f2:	6b0080e7          	jalr	1712(ra) # 79e <fprintf>
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
 16a:	82a58593          	addi	a1,a1,-2006 # 990 <malloc+0x106>
 16e:	4509                	li	a0,2
 170:	00000097          	auipc	ra,0x0
 174:	62e080e7          	jalr	1582(ra) # 79e <fprintf>
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

00000000000004f4 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4f4:	1101                	addi	sp,sp,-32
 4f6:	ec06                	sd	ra,24(sp)
 4f8:	e822                	sd	s0,16(sp)
 4fa:	1000                	addi	s0,sp,32
 4fc:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 500:	4605                	li	a2,1
 502:	fef40593          	addi	a1,s0,-17
 506:	00000097          	auipc	ra,0x0
 50a:	f6e080e7          	jalr	-146(ra) # 474 <write>
}
 50e:	60e2                	ld	ra,24(sp)
 510:	6442                	ld	s0,16(sp)
 512:	6105                	addi	sp,sp,32
 514:	8082                	ret

0000000000000516 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 516:	7139                	addi	sp,sp,-64
 518:	fc06                	sd	ra,56(sp)
 51a:	f822                	sd	s0,48(sp)
 51c:	f426                	sd	s1,40(sp)
 51e:	f04a                	sd	s2,32(sp)
 520:	ec4e                	sd	s3,24(sp)
 522:	0080                	addi	s0,sp,64
 524:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 526:	c299                	beqz	a3,52c <printint+0x16>
 528:	0805c863          	bltz	a1,5b8 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 52c:	2581                	sext.w	a1,a1
  neg = 0;
 52e:	4881                	li	a7,0
 530:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 534:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 536:	2601                	sext.w	a2,a2
 538:	00000517          	auipc	a0,0x0
 53c:	48050513          	addi	a0,a0,1152 # 9b8 <digits>
 540:	883a                	mv	a6,a4
 542:	2705                	addiw	a4,a4,1
 544:	02c5f7bb          	remuw	a5,a1,a2
 548:	1782                	slli	a5,a5,0x20
 54a:	9381                	srli	a5,a5,0x20
 54c:	97aa                	add	a5,a5,a0
 54e:	0007c783          	lbu	a5,0(a5)
 552:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 556:	0005879b          	sext.w	a5,a1
 55a:	02c5d5bb          	divuw	a1,a1,a2
 55e:	0685                	addi	a3,a3,1
 560:	fec7f0e3          	bgeu	a5,a2,540 <printint+0x2a>
  if(neg)
 564:	00088b63          	beqz	a7,57a <printint+0x64>
    buf[i++] = '-';
 568:	fd040793          	addi	a5,s0,-48
 56c:	973e                	add	a4,a4,a5
 56e:	02d00793          	li	a5,45
 572:	fef70823          	sb	a5,-16(a4)
 576:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 57a:	02e05863          	blez	a4,5aa <printint+0x94>
 57e:	fc040793          	addi	a5,s0,-64
 582:	00e78933          	add	s2,a5,a4
 586:	fff78993          	addi	s3,a5,-1
 58a:	99ba                	add	s3,s3,a4
 58c:	377d                	addiw	a4,a4,-1
 58e:	1702                	slli	a4,a4,0x20
 590:	9301                	srli	a4,a4,0x20
 592:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 596:	fff94583          	lbu	a1,-1(s2)
 59a:	8526                	mv	a0,s1
 59c:	00000097          	auipc	ra,0x0
 5a0:	f58080e7          	jalr	-168(ra) # 4f4 <putc>
  while(--i >= 0)
 5a4:	197d                	addi	s2,s2,-1
 5a6:	ff3918e3          	bne	s2,s3,596 <printint+0x80>
}
 5aa:	70e2                	ld	ra,56(sp)
 5ac:	7442                	ld	s0,48(sp)
 5ae:	74a2                	ld	s1,40(sp)
 5b0:	7902                	ld	s2,32(sp)
 5b2:	69e2                	ld	s3,24(sp)
 5b4:	6121                	addi	sp,sp,64
 5b6:	8082                	ret
    x = -xx;
 5b8:	40b005bb          	negw	a1,a1
    neg = 1;
 5bc:	4885                	li	a7,1
    x = -xx;
 5be:	bf8d                	j	530 <printint+0x1a>

00000000000005c0 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5c0:	7119                	addi	sp,sp,-128
 5c2:	fc86                	sd	ra,120(sp)
 5c4:	f8a2                	sd	s0,112(sp)
 5c6:	f4a6                	sd	s1,104(sp)
 5c8:	f0ca                	sd	s2,96(sp)
 5ca:	ecce                	sd	s3,88(sp)
 5cc:	e8d2                	sd	s4,80(sp)
 5ce:	e4d6                	sd	s5,72(sp)
 5d0:	e0da                	sd	s6,64(sp)
 5d2:	fc5e                	sd	s7,56(sp)
 5d4:	f862                	sd	s8,48(sp)
 5d6:	f466                	sd	s9,40(sp)
 5d8:	f06a                	sd	s10,32(sp)
 5da:	ec6e                	sd	s11,24(sp)
 5dc:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5de:	0005c903          	lbu	s2,0(a1)
 5e2:	18090f63          	beqz	s2,780 <vprintf+0x1c0>
 5e6:	8aaa                	mv	s5,a0
 5e8:	8b32                	mv	s6,a2
 5ea:	00158493          	addi	s1,a1,1
  state = 0;
 5ee:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5f0:	02500a13          	li	s4,37
      if(c == 'd'){
 5f4:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 5f8:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 5fc:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 600:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 604:	00000b97          	auipc	s7,0x0
 608:	3b4b8b93          	addi	s7,s7,948 # 9b8 <digits>
 60c:	a839                	j	62a <vprintf+0x6a>
        putc(fd, c);
 60e:	85ca                	mv	a1,s2
 610:	8556                	mv	a0,s5
 612:	00000097          	auipc	ra,0x0
 616:	ee2080e7          	jalr	-286(ra) # 4f4 <putc>
 61a:	a019                	j	620 <vprintf+0x60>
    } else if(state == '%'){
 61c:	01498f63          	beq	s3,s4,63a <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 620:	0485                	addi	s1,s1,1
 622:	fff4c903          	lbu	s2,-1(s1)
 626:	14090d63          	beqz	s2,780 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 62a:	0009079b          	sext.w	a5,s2
    if(state == 0){
 62e:	fe0997e3          	bnez	s3,61c <vprintf+0x5c>
      if(c == '%'){
 632:	fd479ee3          	bne	a5,s4,60e <vprintf+0x4e>
        state = '%';
 636:	89be                	mv	s3,a5
 638:	b7e5                	j	620 <vprintf+0x60>
      if(c == 'd'){
 63a:	05878063          	beq	a5,s8,67a <vprintf+0xba>
      } else if(c == 'l') {
 63e:	05978c63          	beq	a5,s9,696 <vprintf+0xd6>
      } else if(c == 'x') {
 642:	07a78863          	beq	a5,s10,6b2 <vprintf+0xf2>
      } else if(c == 'p') {
 646:	09b78463          	beq	a5,s11,6ce <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 64a:	07300713          	li	a4,115
 64e:	0ce78663          	beq	a5,a4,71a <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 652:	06300713          	li	a4,99
 656:	0ee78e63          	beq	a5,a4,752 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 65a:	11478863          	beq	a5,s4,76a <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 65e:	85d2                	mv	a1,s4
 660:	8556                	mv	a0,s5
 662:	00000097          	auipc	ra,0x0
 666:	e92080e7          	jalr	-366(ra) # 4f4 <putc>
        putc(fd, c);
 66a:	85ca                	mv	a1,s2
 66c:	8556                	mv	a0,s5
 66e:	00000097          	auipc	ra,0x0
 672:	e86080e7          	jalr	-378(ra) # 4f4 <putc>
      }
      state = 0;
 676:	4981                	li	s3,0
 678:	b765                	j	620 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 67a:	008b0913          	addi	s2,s6,8
 67e:	4685                	li	a3,1
 680:	4629                	li	a2,10
 682:	000b2583          	lw	a1,0(s6)
 686:	8556                	mv	a0,s5
 688:	00000097          	auipc	ra,0x0
 68c:	e8e080e7          	jalr	-370(ra) # 516 <printint>
 690:	8b4a                	mv	s6,s2
      state = 0;
 692:	4981                	li	s3,0
 694:	b771                	j	620 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 696:	008b0913          	addi	s2,s6,8
 69a:	4681                	li	a3,0
 69c:	4629                	li	a2,10
 69e:	000b2583          	lw	a1,0(s6)
 6a2:	8556                	mv	a0,s5
 6a4:	00000097          	auipc	ra,0x0
 6a8:	e72080e7          	jalr	-398(ra) # 516 <printint>
 6ac:	8b4a                	mv	s6,s2
      state = 0;
 6ae:	4981                	li	s3,0
 6b0:	bf85                	j	620 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 6b2:	008b0913          	addi	s2,s6,8
 6b6:	4681                	li	a3,0
 6b8:	4641                	li	a2,16
 6ba:	000b2583          	lw	a1,0(s6)
 6be:	8556                	mv	a0,s5
 6c0:	00000097          	auipc	ra,0x0
 6c4:	e56080e7          	jalr	-426(ra) # 516 <printint>
 6c8:	8b4a                	mv	s6,s2
      state = 0;
 6ca:	4981                	li	s3,0
 6cc:	bf91                	j	620 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6ce:	008b0793          	addi	a5,s6,8
 6d2:	f8f43423          	sd	a5,-120(s0)
 6d6:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6da:	03000593          	li	a1,48
 6de:	8556                	mv	a0,s5
 6e0:	00000097          	auipc	ra,0x0
 6e4:	e14080e7          	jalr	-492(ra) # 4f4 <putc>
  putc(fd, 'x');
 6e8:	85ea                	mv	a1,s10
 6ea:	8556                	mv	a0,s5
 6ec:	00000097          	auipc	ra,0x0
 6f0:	e08080e7          	jalr	-504(ra) # 4f4 <putc>
 6f4:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6f6:	03c9d793          	srli	a5,s3,0x3c
 6fa:	97de                	add	a5,a5,s7
 6fc:	0007c583          	lbu	a1,0(a5)
 700:	8556                	mv	a0,s5
 702:	00000097          	auipc	ra,0x0
 706:	df2080e7          	jalr	-526(ra) # 4f4 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 70a:	0992                	slli	s3,s3,0x4
 70c:	397d                	addiw	s2,s2,-1
 70e:	fe0914e3          	bnez	s2,6f6 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 712:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 716:	4981                	li	s3,0
 718:	b721                	j	620 <vprintf+0x60>
        s = va_arg(ap, char*);
 71a:	008b0993          	addi	s3,s6,8
 71e:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 722:	02090163          	beqz	s2,744 <vprintf+0x184>
        while(*s != 0){
 726:	00094583          	lbu	a1,0(s2)
 72a:	c9a1                	beqz	a1,77a <vprintf+0x1ba>
          putc(fd, *s);
 72c:	8556                	mv	a0,s5
 72e:	00000097          	auipc	ra,0x0
 732:	dc6080e7          	jalr	-570(ra) # 4f4 <putc>
          s++;
 736:	0905                	addi	s2,s2,1
        while(*s != 0){
 738:	00094583          	lbu	a1,0(s2)
 73c:	f9e5                	bnez	a1,72c <vprintf+0x16c>
        s = va_arg(ap, char*);
 73e:	8b4e                	mv	s6,s3
      state = 0;
 740:	4981                	li	s3,0
 742:	bdf9                	j	620 <vprintf+0x60>
          s = "(null)";
 744:	00000917          	auipc	s2,0x0
 748:	26c90913          	addi	s2,s2,620 # 9b0 <malloc+0x126>
        while(*s != 0){
 74c:	02800593          	li	a1,40
 750:	bff1                	j	72c <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 752:	008b0913          	addi	s2,s6,8
 756:	000b4583          	lbu	a1,0(s6)
 75a:	8556                	mv	a0,s5
 75c:	00000097          	auipc	ra,0x0
 760:	d98080e7          	jalr	-616(ra) # 4f4 <putc>
 764:	8b4a                	mv	s6,s2
      state = 0;
 766:	4981                	li	s3,0
 768:	bd65                	j	620 <vprintf+0x60>
        putc(fd, c);
 76a:	85d2                	mv	a1,s4
 76c:	8556                	mv	a0,s5
 76e:	00000097          	auipc	ra,0x0
 772:	d86080e7          	jalr	-634(ra) # 4f4 <putc>
      state = 0;
 776:	4981                	li	s3,0
 778:	b565                	j	620 <vprintf+0x60>
        s = va_arg(ap, char*);
 77a:	8b4e                	mv	s6,s3
      state = 0;
 77c:	4981                	li	s3,0
 77e:	b54d                	j	620 <vprintf+0x60>
    }
  }
}
 780:	70e6                	ld	ra,120(sp)
 782:	7446                	ld	s0,112(sp)
 784:	74a6                	ld	s1,104(sp)
 786:	7906                	ld	s2,96(sp)
 788:	69e6                	ld	s3,88(sp)
 78a:	6a46                	ld	s4,80(sp)
 78c:	6aa6                	ld	s5,72(sp)
 78e:	6b06                	ld	s6,64(sp)
 790:	7be2                	ld	s7,56(sp)
 792:	7c42                	ld	s8,48(sp)
 794:	7ca2                	ld	s9,40(sp)
 796:	7d02                	ld	s10,32(sp)
 798:	6de2                	ld	s11,24(sp)
 79a:	6109                	addi	sp,sp,128
 79c:	8082                	ret

000000000000079e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 79e:	715d                	addi	sp,sp,-80
 7a0:	ec06                	sd	ra,24(sp)
 7a2:	e822                	sd	s0,16(sp)
 7a4:	1000                	addi	s0,sp,32
 7a6:	e010                	sd	a2,0(s0)
 7a8:	e414                	sd	a3,8(s0)
 7aa:	e818                	sd	a4,16(s0)
 7ac:	ec1c                	sd	a5,24(s0)
 7ae:	03043023          	sd	a6,32(s0)
 7b2:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 7b6:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 7ba:	8622                	mv	a2,s0
 7bc:	00000097          	auipc	ra,0x0
 7c0:	e04080e7          	jalr	-508(ra) # 5c0 <vprintf>
}
 7c4:	60e2                	ld	ra,24(sp)
 7c6:	6442                	ld	s0,16(sp)
 7c8:	6161                	addi	sp,sp,80
 7ca:	8082                	ret

00000000000007cc <printf>:

void
printf(const char *fmt, ...)
{
 7cc:	711d                	addi	sp,sp,-96
 7ce:	ec06                	sd	ra,24(sp)
 7d0:	e822                	sd	s0,16(sp)
 7d2:	1000                	addi	s0,sp,32
 7d4:	e40c                	sd	a1,8(s0)
 7d6:	e810                	sd	a2,16(s0)
 7d8:	ec14                	sd	a3,24(s0)
 7da:	f018                	sd	a4,32(s0)
 7dc:	f41c                	sd	a5,40(s0)
 7de:	03043823          	sd	a6,48(s0)
 7e2:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7e6:	00840613          	addi	a2,s0,8
 7ea:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7ee:	85aa                	mv	a1,a0
 7f0:	4505                	li	a0,1
 7f2:	00000097          	auipc	ra,0x0
 7f6:	dce080e7          	jalr	-562(ra) # 5c0 <vprintf>
}
 7fa:	60e2                	ld	ra,24(sp)
 7fc:	6442                	ld	s0,16(sp)
 7fe:	6125                	addi	sp,sp,96
 800:	8082                	ret

0000000000000802 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 802:	1141                	addi	sp,sp,-16
 804:	e422                	sd	s0,8(sp)
 806:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 808:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 80c:	00000797          	auipc	a5,0x0
 810:	1c47b783          	ld	a5,452(a5) # 9d0 <freep>
 814:	a805                	j	844 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 816:	4618                	lw	a4,8(a2)
 818:	9db9                	addw	a1,a1,a4
 81a:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 81e:	6398                	ld	a4,0(a5)
 820:	6318                	ld	a4,0(a4)
 822:	fee53823          	sd	a4,-16(a0)
 826:	a091                	j	86a <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 828:	ff852703          	lw	a4,-8(a0)
 82c:	9e39                	addw	a2,a2,a4
 82e:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 830:	ff053703          	ld	a4,-16(a0)
 834:	e398                	sd	a4,0(a5)
 836:	a099                	j	87c <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 838:	6398                	ld	a4,0(a5)
 83a:	00e7e463          	bltu	a5,a4,842 <free+0x40>
 83e:	00e6ea63          	bltu	a3,a4,852 <free+0x50>
{
 842:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 844:	fed7fae3          	bgeu	a5,a3,838 <free+0x36>
 848:	6398                	ld	a4,0(a5)
 84a:	00e6e463          	bltu	a3,a4,852 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 84e:	fee7eae3          	bltu	a5,a4,842 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 852:	ff852583          	lw	a1,-8(a0)
 856:	6390                	ld	a2,0(a5)
 858:	02059713          	slli	a4,a1,0x20
 85c:	9301                	srli	a4,a4,0x20
 85e:	0712                	slli	a4,a4,0x4
 860:	9736                	add	a4,a4,a3
 862:	fae60ae3          	beq	a2,a4,816 <free+0x14>
    bp->s.ptr = p->s.ptr;
 866:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 86a:	4790                	lw	a2,8(a5)
 86c:	02061713          	slli	a4,a2,0x20
 870:	9301                	srli	a4,a4,0x20
 872:	0712                	slli	a4,a4,0x4
 874:	973e                	add	a4,a4,a5
 876:	fae689e3          	beq	a3,a4,828 <free+0x26>
  } else
    p->s.ptr = bp;
 87a:	e394                	sd	a3,0(a5)
  freep = p;
 87c:	00000717          	auipc	a4,0x0
 880:	14f73a23          	sd	a5,340(a4) # 9d0 <freep>
}
 884:	6422                	ld	s0,8(sp)
 886:	0141                	addi	sp,sp,16
 888:	8082                	ret

000000000000088a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 88a:	7139                	addi	sp,sp,-64
 88c:	fc06                	sd	ra,56(sp)
 88e:	f822                	sd	s0,48(sp)
 890:	f426                	sd	s1,40(sp)
 892:	f04a                	sd	s2,32(sp)
 894:	ec4e                	sd	s3,24(sp)
 896:	e852                	sd	s4,16(sp)
 898:	e456                	sd	s5,8(sp)
 89a:	e05a                	sd	s6,0(sp)
 89c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 89e:	02051493          	slli	s1,a0,0x20
 8a2:	9081                	srli	s1,s1,0x20
 8a4:	04bd                	addi	s1,s1,15
 8a6:	8091                	srli	s1,s1,0x4
 8a8:	0014899b          	addiw	s3,s1,1
 8ac:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 8ae:	00000517          	auipc	a0,0x0
 8b2:	12253503          	ld	a0,290(a0) # 9d0 <freep>
 8b6:	c515                	beqz	a0,8e2 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8b8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8ba:	4798                	lw	a4,8(a5)
 8bc:	02977f63          	bgeu	a4,s1,8fa <malloc+0x70>
 8c0:	8a4e                	mv	s4,s3
 8c2:	0009871b          	sext.w	a4,s3
 8c6:	6685                	lui	a3,0x1
 8c8:	00d77363          	bgeu	a4,a3,8ce <malloc+0x44>
 8cc:	6a05                	lui	s4,0x1
 8ce:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8d2:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8d6:	00000917          	auipc	s2,0x0
 8da:	0fa90913          	addi	s2,s2,250 # 9d0 <freep>
  if(p == (char*)-1)
 8de:	5afd                	li	s5,-1
 8e0:	a88d                	j	952 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 8e2:	00000797          	auipc	a5,0x0
 8e6:	0f678793          	addi	a5,a5,246 # 9d8 <base>
 8ea:	00000717          	auipc	a4,0x0
 8ee:	0ef73323          	sd	a5,230(a4) # 9d0 <freep>
 8f2:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8f4:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8f8:	b7e1                	j	8c0 <malloc+0x36>
      if(p->s.size == nunits)
 8fa:	02e48b63          	beq	s1,a4,930 <malloc+0xa6>
        p->s.size -= nunits;
 8fe:	4137073b          	subw	a4,a4,s3
 902:	c798                	sw	a4,8(a5)
        p += p->s.size;
 904:	1702                	slli	a4,a4,0x20
 906:	9301                	srli	a4,a4,0x20
 908:	0712                	slli	a4,a4,0x4
 90a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 90c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 910:	00000717          	auipc	a4,0x0
 914:	0ca73023          	sd	a0,192(a4) # 9d0 <freep>
      return (void*)(p + 1);
 918:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 91c:	70e2                	ld	ra,56(sp)
 91e:	7442                	ld	s0,48(sp)
 920:	74a2                	ld	s1,40(sp)
 922:	7902                	ld	s2,32(sp)
 924:	69e2                	ld	s3,24(sp)
 926:	6a42                	ld	s4,16(sp)
 928:	6aa2                	ld	s5,8(sp)
 92a:	6b02                	ld	s6,0(sp)
 92c:	6121                	addi	sp,sp,64
 92e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 930:	6398                	ld	a4,0(a5)
 932:	e118                	sd	a4,0(a0)
 934:	bff1                	j	910 <malloc+0x86>
  hp->s.size = nu;
 936:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 93a:	0541                	addi	a0,a0,16
 93c:	00000097          	auipc	ra,0x0
 940:	ec6080e7          	jalr	-314(ra) # 802 <free>
  return freep;
 944:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 948:	d971                	beqz	a0,91c <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 94a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 94c:	4798                	lw	a4,8(a5)
 94e:	fa9776e3          	bgeu	a4,s1,8fa <malloc+0x70>
    if(p == freep)
 952:	00093703          	ld	a4,0(s2)
 956:	853e                	mv	a0,a5
 958:	fef719e3          	bne	a4,a5,94a <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 95c:	8552                	mv	a0,s4
 95e:	00000097          	auipc	ra,0x0
 962:	b7e080e7          	jalr	-1154(ra) # 4dc <sbrk>
  if(p == (char*)-1)
 966:	fd5518e3          	bne	a0,s5,936 <malloc+0xac>
        return 0;
 96a:	4501                	li	a0,0
 96c:	bf45                	j	91c <malloc+0x92>
