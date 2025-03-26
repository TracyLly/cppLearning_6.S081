
user/_find:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <my_strrchr>:
#include "kernel/fs.h"
#include "kernel/stat.h"
#include "user/user.h"

/* 手动实现 strrchr() */
char *my_strrchr(const char *s, int c) {
   0:	1141                	addi	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	addi	s0,sp,16
    char *last = 0;
    while (*s) {
   6:	00054783          	lbu	a5,0(a0)
   a:	cf89                	beqz	a5,24 <my_strrchr+0x24>
   c:	872a                	mv	a4,a0
    char *last = 0;
   e:	4501                	li	a0,0
  10:	a029                	j	1a <my_strrchr+0x1a>
        if (*s == c)
            last = (char *)s;
        s++;
  12:	0705                	addi	a4,a4,1
    while (*s) {
  14:	00074783          	lbu	a5,0(a4)
  18:	c799                	beqz	a5,26 <my_strrchr+0x26>
        if (*s == c)
  1a:	2781                	sext.w	a5,a5
  1c:	feb79be3          	bne	a5,a1,12 <my_strrchr+0x12>
  20:	853a                	mv	a0,a4
  22:	bfc5                	j	12 <my_strrchr+0x12>
    char *last = 0;
  24:	4501                	li	a0,0
    }
    return last;
}
  26:	6422                	ld	s0,8(sp)
  28:	0141                	addi	sp,sp,16
  2a:	8082                	ret

000000000000002c <basename>:

/* 获取路径中的文件名 */
char *basename(char *pathname) {
  2c:	1101                	addi	sp,sp,-32
  2e:	ec06                	sd	ra,24(sp)
  30:	e822                	sd	s0,16(sp)
  32:	e426                	sd	s1,8(sp)
  34:	1000                	addi	s0,sp,32
  36:	84aa                	mv	s1,a0
    char *last_slash = my_strrchr(pathname, '/');  // 使用 my_strrchr() 替代 strrchr()
  38:	02f00593          	li	a1,47
  3c:	00000097          	auipc	ra,0x0
  40:	fc4080e7          	jalr	-60(ra) # 0 <my_strrchr>
    return (last_slash != 0) ? last_slash + 1 : pathname;
  44:	c519                	beqz	a0,52 <basename+0x26>
  46:	0505                	addi	a0,a0,1
}
  48:	60e2                	ld	ra,24(sp)
  4a:	6442                	ld	s0,16(sp)
  4c:	64a2                	ld	s1,8(sp)
  4e:	6105                	addi	sp,sp,32
  50:	8082                	ret
    return (last_slash != 0) ? last_slash + 1 : pathname;
  52:	8526                	mv	a0,s1
  54:	bfd5                	j	48 <basename+0x1c>

0000000000000056 <my_strncpy>:

/* 手动实现 strncpy() */
void my_strncpy(char *dest, const char *src, int n) {
  56:	1141                	addi	sp,sp,-16
  58:	e422                	sd	s0,8(sp)
  5a:	0800                	addi	s0,sp,16
    int i;
    for (i = 0; i < n && src[i]; i++) {
  5c:	4781                	li	a5,0
  5e:	04c05463          	blez	a2,a6 <my_strncpy+0x50>
  62:	0007869b          	sext.w	a3,a5
  66:	00f58733          	add	a4,a1,a5
  6a:	00074703          	lbu	a4,0(a4)
  6e:	cb19                	beqz	a4,84 <my_strncpy+0x2e>
        dest[i] = src[i];
  70:	00f506b3          	add	a3,a0,a5
  74:	00e68023          	sb	a4,0(a3)
    for (i = 0; i < n && src[i]; i++) {
  78:	0785                	addi	a5,a5,1
  7a:	0007871b          	sext.w	a4,a5
  7e:	fec742e3          	blt	a4,a2,62 <my_strncpy+0xc>
  82:	a015                	j	a6 <my_strncpy+0x50>
    }
    while (i < n) {  // 填充 '\0'
  84:	02c6d163          	bge	a3,a2,a6 <my_strncpy+0x50>
  88:	00d50733          	add	a4,a0,a3
  8c:	0505                	addi	a0,a0,1
  8e:	9536                	add	a0,a0,a3
  90:	367d                	addiw	a2,a2,-1
  92:	40f607bb          	subw	a5,a2,a5
  96:	1782                	slli	a5,a5,0x20
  98:	9381                	srli	a5,a5,0x20
  9a:	97aa                	add	a5,a5,a0
        dest[i++] = '\0';
  9c:	00070023          	sb	zero,0(a4)
    while (i < n) {  // 填充 '\0'
  a0:	0705                	addi	a4,a4,1
  a2:	fef71de3          	bne	a4,a5,9c <my_strncpy+0x46>
    }
}
  a6:	6422                	ld	s0,8(sp)
  a8:	0141                	addi	sp,sp,16
  aa:	8082                	ret

00000000000000ac <find>:

/* 递归查找 */
void find(char *curr_path, char *target) {
  ac:	d9010113          	addi	sp,sp,-624
  b0:	26113423          	sd	ra,616(sp)
  b4:	26813023          	sd	s0,608(sp)
  b8:	24913c23          	sd	s1,600(sp)
  bc:	25213823          	sd	s2,592(sp)
  c0:	25313423          	sd	s3,584(sp)
  c4:	25413023          	sd	s4,576(sp)
  c8:	23513c23          	sd	s5,568(sp)
  cc:	23613823          	sd	s6,560(sp)
  d0:	1c80                	addi	s0,sp,624
  d2:	892a                	mv	s2,a0
  d4:	8a2e                	mv	s4,a1
    char buf[512], *p;
    int fd;
    struct dirent de;
    struct stat st;

    if ((fd = open(curr_path, O_RDONLY)) < 0) {
  d6:	4581                	li	a1,0
  d8:	00000097          	auipc	ra,0x0
  dc:	482080e7          	jalr	1154(ra) # 55a <open>
  e0:	04054663          	bltz	a0,12c <find+0x80>
  e4:	84aa                	mv	s1,a0
        fprintf(2, "find: cannot open %s\n", curr_path);
        return;
    }

    if (fstat(fd, &st) < 0) {
  e6:	d9840593          	addi	a1,s0,-616
  ea:	00000097          	auipc	ra,0x0
  ee:	488080e7          	jalr	1160(ra) # 572 <fstat>
  f2:	06054a63          	bltz	a0,166 <find+0xba>
        fprintf(2, "find: cannot stat %s\n", curr_path);
        close(fd);
        return;
    }

    switch (st.type) {
  f6:	da041783          	lh	a5,-608(s0)
  fa:	0007869b          	sext.w	a3,a5
  fe:	4705                	li	a4,1
 100:	08e68d63          	beq	a3,a4,19a <find+0xee>
 104:	4709                	li	a4,2
 106:	02e69d63          	bne	a3,a4,140 <find+0x94>
    case T_FILE: {
        char *f_name = basename(curr_path);
 10a:	854a                	mv	a0,s2
 10c:	00000097          	auipc	ra,0x0
 110:	f20080e7          	jalr	-224(ra) # 2c <basename>
        if (strcmp(f_name, target) == 0) {
 114:	85d2                	mv	a1,s4
 116:	00000097          	auipc	ra,0x0
 11a:	1aa080e7          	jalr	426(ra) # 2c0 <strcmp>
 11e:	c525                	beqz	a0,186 <find+0xda>
            printf("%s\n", curr_path);
        }
        close(fd);
 120:	8526                	mv	a0,s1
 122:	00000097          	auipc	ra,0x0
 126:	420080e7          	jalr	1056(ra) # 542 <close>
        break;
 12a:	a819                	j	140 <find+0x94>
        fprintf(2, "find: cannot open %s\n", curr_path);
 12c:	864a                	mv	a2,s2
 12e:	00001597          	auipc	a1,0x1
 132:	92a58593          	addi	a1,a1,-1750 # a58 <malloc+0xe8>
 136:	4509                	li	a0,2
 138:	00000097          	auipc	ra,0x0
 13c:	74c080e7          	jalr	1868(ra) # 884 <fprintf>
            find(buf, target);
        }
        close(fd);
        break;
    }
}
 140:	26813083          	ld	ra,616(sp)
 144:	26013403          	ld	s0,608(sp)
 148:	25813483          	ld	s1,600(sp)
 14c:	25013903          	ld	s2,592(sp)
 150:	24813983          	ld	s3,584(sp)
 154:	24013a03          	ld	s4,576(sp)
 158:	23813a83          	ld	s5,568(sp)
 15c:	23013b03          	ld	s6,560(sp)
 160:	27010113          	addi	sp,sp,624
 164:	8082                	ret
        fprintf(2, "find: cannot stat %s\n", curr_path);
 166:	864a                	mv	a2,s2
 168:	00001597          	auipc	a1,0x1
 16c:	90858593          	addi	a1,a1,-1784 # a70 <malloc+0x100>
 170:	4509                	li	a0,2
 172:	00000097          	auipc	ra,0x0
 176:	712080e7          	jalr	1810(ra) # 884 <fprintf>
        close(fd);
 17a:	8526                	mv	a0,s1
 17c:	00000097          	auipc	ra,0x0
 180:	3c6080e7          	jalr	966(ra) # 542 <close>
        return;
 184:	bf75                	j	140 <find+0x94>
            printf("%s\n", curr_path);
 186:	85ca                	mv	a1,s2
 188:	00001517          	auipc	a0,0x1
 18c:	90050513          	addi	a0,a0,-1792 # a88 <malloc+0x118>
 190:	00000097          	auipc	ra,0x0
 194:	722080e7          	jalr	1826(ra) # 8b2 <printf>
 198:	b761                	j	120 <find+0x74>
        memset(buf, 0, sizeof(buf));
 19a:	20000613          	li	a2,512
 19e:	4581                	li	a1,0
 1a0:	dc040513          	addi	a0,s0,-576
 1a4:	00000097          	auipc	ra,0x0
 1a8:	172080e7          	jalr	370(ra) # 316 <memset>
        uint curr_path_len = strlen(curr_path);
 1ac:	854a                	mv	a0,s2
 1ae:	00000097          	auipc	ra,0x0
 1b2:	13e080e7          	jalr	318(ra) # 2ec <strlen>
 1b6:	0005099b          	sext.w	s3,a0
        memcpy(buf, curr_path, curr_path_len);
 1ba:	864e                	mv	a2,s3
 1bc:	85ca                	mv	a1,s2
 1be:	dc040513          	addi	a0,s0,-576
 1c2:	00000097          	auipc	ra,0x0
 1c6:	338080e7          	jalr	824(ra) # 4fa <memcpy>
        buf[curr_path_len] = '/';
 1ca:	1982                	slli	s3,s3,0x20
 1cc:	0209d993          	srli	s3,s3,0x20
 1d0:	fc040793          	addi	a5,s0,-64
 1d4:	97ce                	add	a5,a5,s3
 1d6:	02f00713          	li	a4,47
 1da:	e0e78023          	sb	a4,-512(a5)
        p = buf + curr_path_len + 1;
 1de:	0985                	addi	s3,s3,1
 1e0:	dc040793          	addi	a5,s0,-576
 1e4:	99be                	add	s3,s3,a5
            if (de.inum == 0 || strcmp(de.name, ".") == 0 || strcmp(de.name, "..") == 0)
 1e6:	00001a97          	auipc	s5,0x1
 1ea:	8aaa8a93          	addi	s5,s5,-1878 # a90 <malloc+0x120>
 1ee:	00001b17          	auipc	s6,0x1
 1f2:	8aab0b13          	addi	s6,s6,-1878 # a98 <malloc+0x128>
 1f6:	db240913          	addi	s2,s0,-590
        while (read(fd, &de, sizeof(de)) == sizeof(de)) {
 1fa:	4641                	li	a2,16
 1fc:	db040593          	addi	a1,s0,-592
 200:	8526                	mv	a0,s1
 202:	00000097          	auipc	ra,0x0
 206:	330080e7          	jalr	816(ra) # 532 <read>
 20a:	47c1                	li	a5,16
 20c:	04f51563          	bne	a0,a5,256 <find+0x1aa>
            if (de.inum == 0 || strcmp(de.name, ".") == 0 || strcmp(de.name, "..") == 0)
 210:	db045783          	lhu	a5,-592(s0)
 214:	d3fd                	beqz	a5,1fa <find+0x14e>
 216:	85d6                	mv	a1,s5
 218:	854a                	mv	a0,s2
 21a:	00000097          	auipc	ra,0x0
 21e:	0a6080e7          	jalr	166(ra) # 2c0 <strcmp>
 222:	dd61                	beqz	a0,1fa <find+0x14e>
 224:	85da                	mv	a1,s6
 226:	854a                	mv	a0,s2
 228:	00000097          	auipc	ra,0x0
 22c:	098080e7          	jalr	152(ra) # 2c0 <strcmp>
 230:	d569                	beqz	a0,1fa <find+0x14e>
            my_strncpy(p, de.name, DIRSIZ);  // 替换 strncpy()
 232:	4639                	li	a2,14
 234:	db240593          	addi	a1,s0,-590
 238:	854e                	mv	a0,s3
 23a:	00000097          	auipc	ra,0x0
 23e:	e1c080e7          	jalr	-484(ra) # 56 <my_strncpy>
            p[DIRSIZ] = '\0'; // 确保字符串终止
 242:	00098723          	sb	zero,14(s3)
            find(buf, target);
 246:	85d2                	mv	a1,s4
 248:	dc040513          	addi	a0,s0,-576
 24c:	00000097          	auipc	ra,0x0
 250:	e60080e7          	jalr	-416(ra) # ac <find>
 254:	b75d                	j	1fa <find+0x14e>
        close(fd);
 256:	8526                	mv	a0,s1
 258:	00000097          	auipc	ra,0x0
 25c:	2ea080e7          	jalr	746(ra) # 542 <close>
        break;
 260:	b5c5                	j	140 <find+0x94>

0000000000000262 <main>:

int main(int argc, char *argv[]) {
 262:	1141                	addi	sp,sp,-16
 264:	e406                	sd	ra,8(sp)
 266:	e022                	sd	s0,0(sp)
 268:	0800                	addi	s0,sp,16
    if (argc != 3) {
 26a:	470d                	li	a4,3
 26c:	02e50063          	beq	a0,a4,28c <main+0x2a>
        fprintf(2, "usage: find [directory] [target filename]\n");
 270:	00001597          	auipc	a1,0x1
 274:	83058593          	addi	a1,a1,-2000 # aa0 <malloc+0x130>
 278:	4509                	li	a0,2
 27a:	00000097          	auipc	ra,0x0
 27e:	60a080e7          	jalr	1546(ra) # 884 <fprintf>
        exit(1);
 282:	4505                	li	a0,1
 284:	00000097          	auipc	ra,0x0
 288:	296080e7          	jalr	662(ra) # 51a <exit>
 28c:	87ae                	mv	a5,a1
    }
    find(argv[1], argv[2]);
 28e:	698c                	ld	a1,16(a1)
 290:	6788                	ld	a0,8(a5)
 292:	00000097          	auipc	ra,0x0
 296:	e1a080e7          	jalr	-486(ra) # ac <find>
    exit(0);
 29a:	4501                	li	a0,0
 29c:	00000097          	auipc	ra,0x0
 2a0:	27e080e7          	jalr	638(ra) # 51a <exit>

00000000000002a4 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 2a4:	1141                	addi	sp,sp,-16
 2a6:	e422                	sd	s0,8(sp)
 2a8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2aa:	87aa                	mv	a5,a0
 2ac:	0585                	addi	a1,a1,1
 2ae:	0785                	addi	a5,a5,1
 2b0:	fff5c703          	lbu	a4,-1(a1)
 2b4:	fee78fa3          	sb	a4,-1(a5)
 2b8:	fb75                	bnez	a4,2ac <strcpy+0x8>
    ;
  return os;
}
 2ba:	6422                	ld	s0,8(sp)
 2bc:	0141                	addi	sp,sp,16
 2be:	8082                	ret

00000000000002c0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2c0:	1141                	addi	sp,sp,-16
 2c2:	e422                	sd	s0,8(sp)
 2c4:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2c6:	00054783          	lbu	a5,0(a0)
 2ca:	cb91                	beqz	a5,2de <strcmp+0x1e>
 2cc:	0005c703          	lbu	a4,0(a1)
 2d0:	00f71763          	bne	a4,a5,2de <strcmp+0x1e>
    p++, q++;
 2d4:	0505                	addi	a0,a0,1
 2d6:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2d8:	00054783          	lbu	a5,0(a0)
 2dc:	fbe5                	bnez	a5,2cc <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2de:	0005c503          	lbu	a0,0(a1)
}
 2e2:	40a7853b          	subw	a0,a5,a0
 2e6:	6422                	ld	s0,8(sp)
 2e8:	0141                	addi	sp,sp,16
 2ea:	8082                	ret

00000000000002ec <strlen>:

uint
strlen(const char *s)
{
 2ec:	1141                	addi	sp,sp,-16
 2ee:	e422                	sd	s0,8(sp)
 2f0:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2f2:	00054783          	lbu	a5,0(a0)
 2f6:	cf91                	beqz	a5,312 <strlen+0x26>
 2f8:	0505                	addi	a0,a0,1
 2fa:	87aa                	mv	a5,a0
 2fc:	4685                	li	a3,1
 2fe:	9e89                	subw	a3,a3,a0
 300:	00f6853b          	addw	a0,a3,a5
 304:	0785                	addi	a5,a5,1
 306:	fff7c703          	lbu	a4,-1(a5)
 30a:	fb7d                	bnez	a4,300 <strlen+0x14>
    ;
  return n;
}
 30c:	6422                	ld	s0,8(sp)
 30e:	0141                	addi	sp,sp,16
 310:	8082                	ret
  for(n = 0; s[n]; n++)
 312:	4501                	li	a0,0
 314:	bfe5                	j	30c <strlen+0x20>

0000000000000316 <memset>:

void*
memset(void *dst, int c, uint n)
{
 316:	1141                	addi	sp,sp,-16
 318:	e422                	sd	s0,8(sp)
 31a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 31c:	ce09                	beqz	a2,336 <memset+0x20>
 31e:	87aa                	mv	a5,a0
 320:	fff6071b          	addiw	a4,a2,-1
 324:	1702                	slli	a4,a4,0x20
 326:	9301                	srli	a4,a4,0x20
 328:	0705                	addi	a4,a4,1
 32a:	972a                	add	a4,a4,a0
    cdst[i] = c;
 32c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 330:	0785                	addi	a5,a5,1
 332:	fee79de3          	bne	a5,a4,32c <memset+0x16>
  }
  return dst;
}
 336:	6422                	ld	s0,8(sp)
 338:	0141                	addi	sp,sp,16
 33a:	8082                	ret

000000000000033c <strchr>:

char*
strchr(const char *s, char c)
{
 33c:	1141                	addi	sp,sp,-16
 33e:	e422                	sd	s0,8(sp)
 340:	0800                	addi	s0,sp,16
  for(; *s; s++)
 342:	00054783          	lbu	a5,0(a0)
 346:	cb99                	beqz	a5,35c <strchr+0x20>
    if(*s == c)
 348:	00f58763          	beq	a1,a5,356 <strchr+0x1a>
  for(; *s; s++)
 34c:	0505                	addi	a0,a0,1
 34e:	00054783          	lbu	a5,0(a0)
 352:	fbfd                	bnez	a5,348 <strchr+0xc>
      return (char*)s;
  return 0;
 354:	4501                	li	a0,0
}
 356:	6422                	ld	s0,8(sp)
 358:	0141                	addi	sp,sp,16
 35a:	8082                	ret
  return 0;
 35c:	4501                	li	a0,0
 35e:	bfe5                	j	356 <strchr+0x1a>

0000000000000360 <gets>:

char*
gets(char *buf, int max)
{
 360:	711d                	addi	sp,sp,-96
 362:	ec86                	sd	ra,88(sp)
 364:	e8a2                	sd	s0,80(sp)
 366:	e4a6                	sd	s1,72(sp)
 368:	e0ca                	sd	s2,64(sp)
 36a:	fc4e                	sd	s3,56(sp)
 36c:	f852                	sd	s4,48(sp)
 36e:	f456                	sd	s5,40(sp)
 370:	f05a                	sd	s6,32(sp)
 372:	ec5e                	sd	s7,24(sp)
 374:	1080                	addi	s0,sp,96
 376:	8baa                	mv	s7,a0
 378:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 37a:	892a                	mv	s2,a0
 37c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 37e:	4aa9                	li	s5,10
 380:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 382:	89a6                	mv	s3,s1
 384:	2485                	addiw	s1,s1,1
 386:	0344d863          	bge	s1,s4,3b6 <gets+0x56>
    cc = read(0, &c, 1);
 38a:	4605                	li	a2,1
 38c:	faf40593          	addi	a1,s0,-81
 390:	4501                	li	a0,0
 392:	00000097          	auipc	ra,0x0
 396:	1a0080e7          	jalr	416(ra) # 532 <read>
    if(cc < 1)
 39a:	00a05e63          	blez	a0,3b6 <gets+0x56>
    buf[i++] = c;
 39e:	faf44783          	lbu	a5,-81(s0)
 3a2:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3a6:	01578763          	beq	a5,s5,3b4 <gets+0x54>
 3aa:	0905                	addi	s2,s2,1
 3ac:	fd679be3          	bne	a5,s6,382 <gets+0x22>
  for(i=0; i+1 < max; ){
 3b0:	89a6                	mv	s3,s1
 3b2:	a011                	j	3b6 <gets+0x56>
 3b4:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3b6:	99de                	add	s3,s3,s7
 3b8:	00098023          	sb	zero,0(s3)
  return buf;
}
 3bc:	855e                	mv	a0,s7
 3be:	60e6                	ld	ra,88(sp)
 3c0:	6446                	ld	s0,80(sp)
 3c2:	64a6                	ld	s1,72(sp)
 3c4:	6906                	ld	s2,64(sp)
 3c6:	79e2                	ld	s3,56(sp)
 3c8:	7a42                	ld	s4,48(sp)
 3ca:	7aa2                	ld	s5,40(sp)
 3cc:	7b02                	ld	s6,32(sp)
 3ce:	6be2                	ld	s7,24(sp)
 3d0:	6125                	addi	sp,sp,96
 3d2:	8082                	ret

00000000000003d4 <stat>:

int
stat(const char *n, struct stat *st)
{
 3d4:	1101                	addi	sp,sp,-32
 3d6:	ec06                	sd	ra,24(sp)
 3d8:	e822                	sd	s0,16(sp)
 3da:	e426                	sd	s1,8(sp)
 3dc:	e04a                	sd	s2,0(sp)
 3de:	1000                	addi	s0,sp,32
 3e0:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3e2:	4581                	li	a1,0
 3e4:	00000097          	auipc	ra,0x0
 3e8:	176080e7          	jalr	374(ra) # 55a <open>
  if(fd < 0)
 3ec:	02054563          	bltz	a0,416 <stat+0x42>
 3f0:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3f2:	85ca                	mv	a1,s2
 3f4:	00000097          	auipc	ra,0x0
 3f8:	17e080e7          	jalr	382(ra) # 572 <fstat>
 3fc:	892a                	mv	s2,a0
  close(fd);
 3fe:	8526                	mv	a0,s1
 400:	00000097          	auipc	ra,0x0
 404:	142080e7          	jalr	322(ra) # 542 <close>
  return r;
}
 408:	854a                	mv	a0,s2
 40a:	60e2                	ld	ra,24(sp)
 40c:	6442                	ld	s0,16(sp)
 40e:	64a2                	ld	s1,8(sp)
 410:	6902                	ld	s2,0(sp)
 412:	6105                	addi	sp,sp,32
 414:	8082                	ret
    return -1;
 416:	597d                	li	s2,-1
 418:	bfc5                	j	408 <stat+0x34>

000000000000041a <atoi>:

int
atoi(const char *s)
{
 41a:	1141                	addi	sp,sp,-16
 41c:	e422                	sd	s0,8(sp)
 41e:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 420:	00054603          	lbu	a2,0(a0)
 424:	fd06079b          	addiw	a5,a2,-48
 428:	0ff7f793          	andi	a5,a5,255
 42c:	4725                	li	a4,9
 42e:	02f76963          	bltu	a4,a5,460 <atoi+0x46>
 432:	86aa                	mv	a3,a0
  n = 0;
 434:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 436:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 438:	0685                	addi	a3,a3,1
 43a:	0025179b          	slliw	a5,a0,0x2
 43e:	9fa9                	addw	a5,a5,a0
 440:	0017979b          	slliw	a5,a5,0x1
 444:	9fb1                	addw	a5,a5,a2
 446:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 44a:	0006c603          	lbu	a2,0(a3)
 44e:	fd06071b          	addiw	a4,a2,-48
 452:	0ff77713          	andi	a4,a4,255
 456:	fee5f1e3          	bgeu	a1,a4,438 <atoi+0x1e>
  return n;
}
 45a:	6422                	ld	s0,8(sp)
 45c:	0141                	addi	sp,sp,16
 45e:	8082                	ret
  n = 0;
 460:	4501                	li	a0,0
 462:	bfe5                	j	45a <atoi+0x40>

0000000000000464 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 464:	1141                	addi	sp,sp,-16
 466:	e422                	sd	s0,8(sp)
 468:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 46a:	02b57663          	bgeu	a0,a1,496 <memmove+0x32>
    while(n-- > 0)
 46e:	02c05163          	blez	a2,490 <memmove+0x2c>
 472:	fff6079b          	addiw	a5,a2,-1
 476:	1782                	slli	a5,a5,0x20
 478:	9381                	srli	a5,a5,0x20
 47a:	0785                	addi	a5,a5,1
 47c:	97aa                	add	a5,a5,a0
  dst = vdst;
 47e:	872a                	mv	a4,a0
      *dst++ = *src++;
 480:	0585                	addi	a1,a1,1
 482:	0705                	addi	a4,a4,1
 484:	fff5c683          	lbu	a3,-1(a1)
 488:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 48c:	fee79ae3          	bne	a5,a4,480 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 490:	6422                	ld	s0,8(sp)
 492:	0141                	addi	sp,sp,16
 494:	8082                	ret
    dst += n;
 496:	00c50733          	add	a4,a0,a2
    src += n;
 49a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 49c:	fec05ae3          	blez	a2,490 <memmove+0x2c>
 4a0:	fff6079b          	addiw	a5,a2,-1
 4a4:	1782                	slli	a5,a5,0x20
 4a6:	9381                	srli	a5,a5,0x20
 4a8:	fff7c793          	not	a5,a5
 4ac:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4ae:	15fd                	addi	a1,a1,-1
 4b0:	177d                	addi	a4,a4,-1
 4b2:	0005c683          	lbu	a3,0(a1)
 4b6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4ba:	fee79ae3          	bne	a5,a4,4ae <memmove+0x4a>
 4be:	bfc9                	j	490 <memmove+0x2c>

00000000000004c0 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4c0:	1141                	addi	sp,sp,-16
 4c2:	e422                	sd	s0,8(sp)
 4c4:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4c6:	ca05                	beqz	a2,4f6 <memcmp+0x36>
 4c8:	fff6069b          	addiw	a3,a2,-1
 4cc:	1682                	slli	a3,a3,0x20
 4ce:	9281                	srli	a3,a3,0x20
 4d0:	0685                	addi	a3,a3,1
 4d2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4d4:	00054783          	lbu	a5,0(a0)
 4d8:	0005c703          	lbu	a4,0(a1)
 4dc:	00e79863          	bne	a5,a4,4ec <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4e0:	0505                	addi	a0,a0,1
    p2++;
 4e2:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4e4:	fed518e3          	bne	a0,a3,4d4 <memcmp+0x14>
  }
  return 0;
 4e8:	4501                	li	a0,0
 4ea:	a019                	j	4f0 <memcmp+0x30>
      return *p1 - *p2;
 4ec:	40e7853b          	subw	a0,a5,a4
}
 4f0:	6422                	ld	s0,8(sp)
 4f2:	0141                	addi	sp,sp,16
 4f4:	8082                	ret
  return 0;
 4f6:	4501                	li	a0,0
 4f8:	bfe5                	j	4f0 <memcmp+0x30>

00000000000004fa <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4fa:	1141                	addi	sp,sp,-16
 4fc:	e406                	sd	ra,8(sp)
 4fe:	e022                	sd	s0,0(sp)
 500:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 502:	00000097          	auipc	ra,0x0
 506:	f62080e7          	jalr	-158(ra) # 464 <memmove>
}
 50a:	60a2                	ld	ra,8(sp)
 50c:	6402                	ld	s0,0(sp)
 50e:	0141                	addi	sp,sp,16
 510:	8082                	ret

0000000000000512 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 512:	4885                	li	a7,1
 ecall
 514:	00000073          	ecall
 ret
 518:	8082                	ret

000000000000051a <exit>:
.global exit
exit:
 li a7, SYS_exit
 51a:	4889                	li	a7,2
 ecall
 51c:	00000073          	ecall
 ret
 520:	8082                	ret

0000000000000522 <wait>:
.global wait
wait:
 li a7, SYS_wait
 522:	488d                	li	a7,3
 ecall
 524:	00000073          	ecall
 ret
 528:	8082                	ret

000000000000052a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 52a:	4891                	li	a7,4
 ecall
 52c:	00000073          	ecall
 ret
 530:	8082                	ret

0000000000000532 <read>:
.global read
read:
 li a7, SYS_read
 532:	4895                	li	a7,5
 ecall
 534:	00000073          	ecall
 ret
 538:	8082                	ret

000000000000053a <write>:
.global write
write:
 li a7, SYS_write
 53a:	48c1                	li	a7,16
 ecall
 53c:	00000073          	ecall
 ret
 540:	8082                	ret

0000000000000542 <close>:
.global close
close:
 li a7, SYS_close
 542:	48d5                	li	a7,21
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <kill>:
.global kill
kill:
 li a7, SYS_kill
 54a:	4899                	li	a7,6
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <exec>:
.global exec
exec:
 li a7, SYS_exec
 552:	489d                	li	a7,7
 ecall
 554:	00000073          	ecall
 ret
 558:	8082                	ret

000000000000055a <open>:
.global open
open:
 li a7, SYS_open
 55a:	48bd                	li	a7,15
 ecall
 55c:	00000073          	ecall
 ret
 560:	8082                	ret

0000000000000562 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 562:	48c5                	li	a7,17
 ecall
 564:	00000073          	ecall
 ret
 568:	8082                	ret

000000000000056a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 56a:	48c9                	li	a7,18
 ecall
 56c:	00000073          	ecall
 ret
 570:	8082                	ret

0000000000000572 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 572:	48a1                	li	a7,8
 ecall
 574:	00000073          	ecall
 ret
 578:	8082                	ret

000000000000057a <link>:
.global link
link:
 li a7, SYS_link
 57a:	48cd                	li	a7,19
 ecall
 57c:	00000073          	ecall
 ret
 580:	8082                	ret

0000000000000582 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 582:	48d1                	li	a7,20
 ecall
 584:	00000073          	ecall
 ret
 588:	8082                	ret

000000000000058a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 58a:	48a5                	li	a7,9
 ecall
 58c:	00000073          	ecall
 ret
 590:	8082                	ret

0000000000000592 <dup>:
.global dup
dup:
 li a7, SYS_dup
 592:	48a9                	li	a7,10
 ecall
 594:	00000073          	ecall
 ret
 598:	8082                	ret

000000000000059a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 59a:	48ad                	li	a7,11
 ecall
 59c:	00000073          	ecall
 ret
 5a0:	8082                	ret

00000000000005a2 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5a2:	48b1                	li	a7,12
 ecall
 5a4:	00000073          	ecall
 ret
 5a8:	8082                	ret

00000000000005aa <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5aa:	48b5                	li	a7,13
 ecall
 5ac:	00000073          	ecall
 ret
 5b0:	8082                	ret

00000000000005b2 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5b2:	48b9                	li	a7,14
 ecall
 5b4:	00000073          	ecall
 ret
 5b8:	8082                	ret

00000000000005ba <trace>:
.global trace
trace:
 li a7, SYS_trace
 5ba:	48d9                	li	a7,22
 ecall
 5bc:	00000073          	ecall
 ret
 5c0:	8082                	ret

00000000000005c2 <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 5c2:	48dd                	li	a7,23
 ecall
 5c4:	00000073          	ecall
 ret
 5c8:	8082                	ret

00000000000005ca <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 5ca:	48e1                	li	a7,24
 ecall
 5cc:	00000073          	ecall
 ret
 5d0:	8082                	ret

00000000000005d2 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 5d2:	48e5                	li	a7,25
 ecall
 5d4:	00000073          	ecall
 ret
 5d8:	8082                	ret

00000000000005da <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5da:	1101                	addi	sp,sp,-32
 5dc:	ec06                	sd	ra,24(sp)
 5de:	e822                	sd	s0,16(sp)
 5e0:	1000                	addi	s0,sp,32
 5e2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5e6:	4605                	li	a2,1
 5e8:	fef40593          	addi	a1,s0,-17
 5ec:	00000097          	auipc	ra,0x0
 5f0:	f4e080e7          	jalr	-178(ra) # 53a <write>
}
 5f4:	60e2                	ld	ra,24(sp)
 5f6:	6442                	ld	s0,16(sp)
 5f8:	6105                	addi	sp,sp,32
 5fa:	8082                	ret

00000000000005fc <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5fc:	7139                	addi	sp,sp,-64
 5fe:	fc06                	sd	ra,56(sp)
 600:	f822                	sd	s0,48(sp)
 602:	f426                	sd	s1,40(sp)
 604:	f04a                	sd	s2,32(sp)
 606:	ec4e                	sd	s3,24(sp)
 608:	0080                	addi	s0,sp,64
 60a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 60c:	c299                	beqz	a3,612 <printint+0x16>
 60e:	0805c863          	bltz	a1,69e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 612:	2581                	sext.w	a1,a1
  neg = 0;
 614:	4881                	li	a7,0
 616:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 61a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 61c:	2601                	sext.w	a2,a2
 61e:	00000517          	auipc	a0,0x0
 622:	4ba50513          	addi	a0,a0,1210 # ad8 <digits>
 626:	883a                	mv	a6,a4
 628:	2705                	addiw	a4,a4,1
 62a:	02c5f7bb          	remuw	a5,a1,a2
 62e:	1782                	slli	a5,a5,0x20
 630:	9381                	srli	a5,a5,0x20
 632:	97aa                	add	a5,a5,a0
 634:	0007c783          	lbu	a5,0(a5)
 638:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 63c:	0005879b          	sext.w	a5,a1
 640:	02c5d5bb          	divuw	a1,a1,a2
 644:	0685                	addi	a3,a3,1
 646:	fec7f0e3          	bgeu	a5,a2,626 <printint+0x2a>
  if(neg)
 64a:	00088b63          	beqz	a7,660 <printint+0x64>
    buf[i++] = '-';
 64e:	fd040793          	addi	a5,s0,-48
 652:	973e                	add	a4,a4,a5
 654:	02d00793          	li	a5,45
 658:	fef70823          	sb	a5,-16(a4)
 65c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 660:	02e05863          	blez	a4,690 <printint+0x94>
 664:	fc040793          	addi	a5,s0,-64
 668:	00e78933          	add	s2,a5,a4
 66c:	fff78993          	addi	s3,a5,-1
 670:	99ba                	add	s3,s3,a4
 672:	377d                	addiw	a4,a4,-1
 674:	1702                	slli	a4,a4,0x20
 676:	9301                	srli	a4,a4,0x20
 678:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 67c:	fff94583          	lbu	a1,-1(s2)
 680:	8526                	mv	a0,s1
 682:	00000097          	auipc	ra,0x0
 686:	f58080e7          	jalr	-168(ra) # 5da <putc>
  while(--i >= 0)
 68a:	197d                	addi	s2,s2,-1
 68c:	ff3918e3          	bne	s2,s3,67c <printint+0x80>
}
 690:	70e2                	ld	ra,56(sp)
 692:	7442                	ld	s0,48(sp)
 694:	74a2                	ld	s1,40(sp)
 696:	7902                	ld	s2,32(sp)
 698:	69e2                	ld	s3,24(sp)
 69a:	6121                	addi	sp,sp,64
 69c:	8082                	ret
    x = -xx;
 69e:	40b005bb          	negw	a1,a1
    neg = 1;
 6a2:	4885                	li	a7,1
    x = -xx;
 6a4:	bf8d                	j	616 <printint+0x1a>

00000000000006a6 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6a6:	7119                	addi	sp,sp,-128
 6a8:	fc86                	sd	ra,120(sp)
 6aa:	f8a2                	sd	s0,112(sp)
 6ac:	f4a6                	sd	s1,104(sp)
 6ae:	f0ca                	sd	s2,96(sp)
 6b0:	ecce                	sd	s3,88(sp)
 6b2:	e8d2                	sd	s4,80(sp)
 6b4:	e4d6                	sd	s5,72(sp)
 6b6:	e0da                	sd	s6,64(sp)
 6b8:	fc5e                	sd	s7,56(sp)
 6ba:	f862                	sd	s8,48(sp)
 6bc:	f466                	sd	s9,40(sp)
 6be:	f06a                	sd	s10,32(sp)
 6c0:	ec6e                	sd	s11,24(sp)
 6c2:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6c4:	0005c903          	lbu	s2,0(a1)
 6c8:	18090f63          	beqz	s2,866 <vprintf+0x1c0>
 6cc:	8aaa                	mv	s5,a0
 6ce:	8b32                	mv	s6,a2
 6d0:	00158493          	addi	s1,a1,1
  state = 0;
 6d4:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6d6:	02500a13          	li	s4,37
      if(c == 'd'){
 6da:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6de:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6e2:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6e6:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6ea:	00000b97          	auipc	s7,0x0
 6ee:	3eeb8b93          	addi	s7,s7,1006 # ad8 <digits>
 6f2:	a839                	j	710 <vprintf+0x6a>
        putc(fd, c);
 6f4:	85ca                	mv	a1,s2
 6f6:	8556                	mv	a0,s5
 6f8:	00000097          	auipc	ra,0x0
 6fc:	ee2080e7          	jalr	-286(ra) # 5da <putc>
 700:	a019                	j	706 <vprintf+0x60>
    } else if(state == '%'){
 702:	01498f63          	beq	s3,s4,720 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 706:	0485                	addi	s1,s1,1
 708:	fff4c903          	lbu	s2,-1(s1)
 70c:	14090d63          	beqz	s2,866 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 710:	0009079b          	sext.w	a5,s2
    if(state == 0){
 714:	fe0997e3          	bnez	s3,702 <vprintf+0x5c>
      if(c == '%'){
 718:	fd479ee3          	bne	a5,s4,6f4 <vprintf+0x4e>
        state = '%';
 71c:	89be                	mv	s3,a5
 71e:	b7e5                	j	706 <vprintf+0x60>
      if(c == 'd'){
 720:	05878063          	beq	a5,s8,760 <vprintf+0xba>
      } else if(c == 'l') {
 724:	05978c63          	beq	a5,s9,77c <vprintf+0xd6>
      } else if(c == 'x') {
 728:	07a78863          	beq	a5,s10,798 <vprintf+0xf2>
      } else if(c == 'p') {
 72c:	09b78463          	beq	a5,s11,7b4 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 730:	07300713          	li	a4,115
 734:	0ce78663          	beq	a5,a4,800 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 738:	06300713          	li	a4,99
 73c:	0ee78e63          	beq	a5,a4,838 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 740:	11478863          	beq	a5,s4,850 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 744:	85d2                	mv	a1,s4
 746:	8556                	mv	a0,s5
 748:	00000097          	auipc	ra,0x0
 74c:	e92080e7          	jalr	-366(ra) # 5da <putc>
        putc(fd, c);
 750:	85ca                	mv	a1,s2
 752:	8556                	mv	a0,s5
 754:	00000097          	auipc	ra,0x0
 758:	e86080e7          	jalr	-378(ra) # 5da <putc>
      }
      state = 0;
 75c:	4981                	li	s3,0
 75e:	b765                	j	706 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 760:	008b0913          	addi	s2,s6,8
 764:	4685                	li	a3,1
 766:	4629                	li	a2,10
 768:	000b2583          	lw	a1,0(s6)
 76c:	8556                	mv	a0,s5
 76e:	00000097          	auipc	ra,0x0
 772:	e8e080e7          	jalr	-370(ra) # 5fc <printint>
 776:	8b4a                	mv	s6,s2
      state = 0;
 778:	4981                	li	s3,0
 77a:	b771                	j	706 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 77c:	008b0913          	addi	s2,s6,8
 780:	4681                	li	a3,0
 782:	4629                	li	a2,10
 784:	000b2583          	lw	a1,0(s6)
 788:	8556                	mv	a0,s5
 78a:	00000097          	auipc	ra,0x0
 78e:	e72080e7          	jalr	-398(ra) # 5fc <printint>
 792:	8b4a                	mv	s6,s2
      state = 0;
 794:	4981                	li	s3,0
 796:	bf85                	j	706 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 798:	008b0913          	addi	s2,s6,8
 79c:	4681                	li	a3,0
 79e:	4641                	li	a2,16
 7a0:	000b2583          	lw	a1,0(s6)
 7a4:	8556                	mv	a0,s5
 7a6:	00000097          	auipc	ra,0x0
 7aa:	e56080e7          	jalr	-426(ra) # 5fc <printint>
 7ae:	8b4a                	mv	s6,s2
      state = 0;
 7b0:	4981                	li	s3,0
 7b2:	bf91                	j	706 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7b4:	008b0793          	addi	a5,s6,8
 7b8:	f8f43423          	sd	a5,-120(s0)
 7bc:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7c0:	03000593          	li	a1,48
 7c4:	8556                	mv	a0,s5
 7c6:	00000097          	auipc	ra,0x0
 7ca:	e14080e7          	jalr	-492(ra) # 5da <putc>
  putc(fd, 'x');
 7ce:	85ea                	mv	a1,s10
 7d0:	8556                	mv	a0,s5
 7d2:	00000097          	auipc	ra,0x0
 7d6:	e08080e7          	jalr	-504(ra) # 5da <putc>
 7da:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7dc:	03c9d793          	srli	a5,s3,0x3c
 7e0:	97de                	add	a5,a5,s7
 7e2:	0007c583          	lbu	a1,0(a5)
 7e6:	8556                	mv	a0,s5
 7e8:	00000097          	auipc	ra,0x0
 7ec:	df2080e7          	jalr	-526(ra) # 5da <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7f0:	0992                	slli	s3,s3,0x4
 7f2:	397d                	addiw	s2,s2,-1
 7f4:	fe0914e3          	bnez	s2,7dc <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7f8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7fc:	4981                	li	s3,0
 7fe:	b721                	j	706 <vprintf+0x60>
        s = va_arg(ap, char*);
 800:	008b0993          	addi	s3,s6,8
 804:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 808:	02090163          	beqz	s2,82a <vprintf+0x184>
        while(*s != 0){
 80c:	00094583          	lbu	a1,0(s2)
 810:	c9a1                	beqz	a1,860 <vprintf+0x1ba>
          putc(fd, *s);
 812:	8556                	mv	a0,s5
 814:	00000097          	auipc	ra,0x0
 818:	dc6080e7          	jalr	-570(ra) # 5da <putc>
          s++;
 81c:	0905                	addi	s2,s2,1
        while(*s != 0){
 81e:	00094583          	lbu	a1,0(s2)
 822:	f9e5                	bnez	a1,812 <vprintf+0x16c>
        s = va_arg(ap, char*);
 824:	8b4e                	mv	s6,s3
      state = 0;
 826:	4981                	li	s3,0
 828:	bdf9                	j	706 <vprintf+0x60>
          s = "(null)";
 82a:	00000917          	auipc	s2,0x0
 82e:	2a690913          	addi	s2,s2,678 # ad0 <malloc+0x160>
        while(*s != 0){
 832:	02800593          	li	a1,40
 836:	bff1                	j	812 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 838:	008b0913          	addi	s2,s6,8
 83c:	000b4583          	lbu	a1,0(s6)
 840:	8556                	mv	a0,s5
 842:	00000097          	auipc	ra,0x0
 846:	d98080e7          	jalr	-616(ra) # 5da <putc>
 84a:	8b4a                	mv	s6,s2
      state = 0;
 84c:	4981                	li	s3,0
 84e:	bd65                	j	706 <vprintf+0x60>
        putc(fd, c);
 850:	85d2                	mv	a1,s4
 852:	8556                	mv	a0,s5
 854:	00000097          	auipc	ra,0x0
 858:	d86080e7          	jalr	-634(ra) # 5da <putc>
      state = 0;
 85c:	4981                	li	s3,0
 85e:	b565                	j	706 <vprintf+0x60>
        s = va_arg(ap, char*);
 860:	8b4e                	mv	s6,s3
      state = 0;
 862:	4981                	li	s3,0
 864:	b54d                	j	706 <vprintf+0x60>
    }
  }
}
 866:	70e6                	ld	ra,120(sp)
 868:	7446                	ld	s0,112(sp)
 86a:	74a6                	ld	s1,104(sp)
 86c:	7906                	ld	s2,96(sp)
 86e:	69e6                	ld	s3,88(sp)
 870:	6a46                	ld	s4,80(sp)
 872:	6aa6                	ld	s5,72(sp)
 874:	6b06                	ld	s6,64(sp)
 876:	7be2                	ld	s7,56(sp)
 878:	7c42                	ld	s8,48(sp)
 87a:	7ca2                	ld	s9,40(sp)
 87c:	7d02                	ld	s10,32(sp)
 87e:	6de2                	ld	s11,24(sp)
 880:	6109                	addi	sp,sp,128
 882:	8082                	ret

0000000000000884 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 884:	715d                	addi	sp,sp,-80
 886:	ec06                	sd	ra,24(sp)
 888:	e822                	sd	s0,16(sp)
 88a:	1000                	addi	s0,sp,32
 88c:	e010                	sd	a2,0(s0)
 88e:	e414                	sd	a3,8(s0)
 890:	e818                	sd	a4,16(s0)
 892:	ec1c                	sd	a5,24(s0)
 894:	03043023          	sd	a6,32(s0)
 898:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 89c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8a0:	8622                	mv	a2,s0
 8a2:	00000097          	auipc	ra,0x0
 8a6:	e04080e7          	jalr	-508(ra) # 6a6 <vprintf>
}
 8aa:	60e2                	ld	ra,24(sp)
 8ac:	6442                	ld	s0,16(sp)
 8ae:	6161                	addi	sp,sp,80
 8b0:	8082                	ret

00000000000008b2 <printf>:

void
printf(const char *fmt, ...)
{
 8b2:	711d                	addi	sp,sp,-96
 8b4:	ec06                	sd	ra,24(sp)
 8b6:	e822                	sd	s0,16(sp)
 8b8:	1000                	addi	s0,sp,32
 8ba:	e40c                	sd	a1,8(s0)
 8bc:	e810                	sd	a2,16(s0)
 8be:	ec14                	sd	a3,24(s0)
 8c0:	f018                	sd	a4,32(s0)
 8c2:	f41c                	sd	a5,40(s0)
 8c4:	03043823          	sd	a6,48(s0)
 8c8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8cc:	00840613          	addi	a2,s0,8
 8d0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8d4:	85aa                	mv	a1,a0
 8d6:	4505                	li	a0,1
 8d8:	00000097          	auipc	ra,0x0
 8dc:	dce080e7          	jalr	-562(ra) # 6a6 <vprintf>
}
 8e0:	60e2                	ld	ra,24(sp)
 8e2:	6442                	ld	s0,16(sp)
 8e4:	6125                	addi	sp,sp,96
 8e6:	8082                	ret

00000000000008e8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8e8:	1141                	addi	sp,sp,-16
 8ea:	e422                	sd	s0,8(sp)
 8ec:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8ee:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8f2:	00000797          	auipc	a5,0x0
 8f6:	1fe7b783          	ld	a5,510(a5) # af0 <freep>
 8fa:	a805                	j	92a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8fc:	4618                	lw	a4,8(a2)
 8fe:	9db9                	addw	a1,a1,a4
 900:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 904:	6398                	ld	a4,0(a5)
 906:	6318                	ld	a4,0(a4)
 908:	fee53823          	sd	a4,-16(a0)
 90c:	a091                	j	950 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 90e:	ff852703          	lw	a4,-8(a0)
 912:	9e39                	addw	a2,a2,a4
 914:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 916:	ff053703          	ld	a4,-16(a0)
 91a:	e398                	sd	a4,0(a5)
 91c:	a099                	j	962 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 91e:	6398                	ld	a4,0(a5)
 920:	00e7e463          	bltu	a5,a4,928 <free+0x40>
 924:	00e6ea63          	bltu	a3,a4,938 <free+0x50>
{
 928:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 92a:	fed7fae3          	bgeu	a5,a3,91e <free+0x36>
 92e:	6398                	ld	a4,0(a5)
 930:	00e6e463          	bltu	a3,a4,938 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 934:	fee7eae3          	bltu	a5,a4,928 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 938:	ff852583          	lw	a1,-8(a0)
 93c:	6390                	ld	a2,0(a5)
 93e:	02059713          	slli	a4,a1,0x20
 942:	9301                	srli	a4,a4,0x20
 944:	0712                	slli	a4,a4,0x4
 946:	9736                	add	a4,a4,a3
 948:	fae60ae3          	beq	a2,a4,8fc <free+0x14>
    bp->s.ptr = p->s.ptr;
 94c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 950:	4790                	lw	a2,8(a5)
 952:	02061713          	slli	a4,a2,0x20
 956:	9301                	srli	a4,a4,0x20
 958:	0712                	slli	a4,a4,0x4
 95a:	973e                	add	a4,a4,a5
 95c:	fae689e3          	beq	a3,a4,90e <free+0x26>
  } else
    p->s.ptr = bp;
 960:	e394                	sd	a3,0(a5)
  freep = p;
 962:	00000717          	auipc	a4,0x0
 966:	18f73723          	sd	a5,398(a4) # af0 <freep>
}
 96a:	6422                	ld	s0,8(sp)
 96c:	0141                	addi	sp,sp,16
 96e:	8082                	ret

0000000000000970 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 970:	7139                	addi	sp,sp,-64
 972:	fc06                	sd	ra,56(sp)
 974:	f822                	sd	s0,48(sp)
 976:	f426                	sd	s1,40(sp)
 978:	f04a                	sd	s2,32(sp)
 97a:	ec4e                	sd	s3,24(sp)
 97c:	e852                	sd	s4,16(sp)
 97e:	e456                	sd	s5,8(sp)
 980:	e05a                	sd	s6,0(sp)
 982:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 984:	02051493          	slli	s1,a0,0x20
 988:	9081                	srli	s1,s1,0x20
 98a:	04bd                	addi	s1,s1,15
 98c:	8091                	srli	s1,s1,0x4
 98e:	0014899b          	addiw	s3,s1,1
 992:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 994:	00000517          	auipc	a0,0x0
 998:	15c53503          	ld	a0,348(a0) # af0 <freep>
 99c:	c515                	beqz	a0,9c8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 99e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9a0:	4798                	lw	a4,8(a5)
 9a2:	02977f63          	bgeu	a4,s1,9e0 <malloc+0x70>
 9a6:	8a4e                	mv	s4,s3
 9a8:	0009871b          	sext.w	a4,s3
 9ac:	6685                	lui	a3,0x1
 9ae:	00d77363          	bgeu	a4,a3,9b4 <malloc+0x44>
 9b2:	6a05                	lui	s4,0x1
 9b4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9b8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9bc:	00000917          	auipc	s2,0x0
 9c0:	13490913          	addi	s2,s2,308 # af0 <freep>
  if(p == (char*)-1)
 9c4:	5afd                	li	s5,-1
 9c6:	a88d                	j	a38 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 9c8:	00000797          	auipc	a5,0x0
 9cc:	13078793          	addi	a5,a5,304 # af8 <base>
 9d0:	00000717          	auipc	a4,0x0
 9d4:	12f73023          	sd	a5,288(a4) # af0 <freep>
 9d8:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9da:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9de:	b7e1                	j	9a6 <malloc+0x36>
      if(p->s.size == nunits)
 9e0:	02e48b63          	beq	s1,a4,a16 <malloc+0xa6>
        p->s.size -= nunits;
 9e4:	4137073b          	subw	a4,a4,s3
 9e8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9ea:	1702                	slli	a4,a4,0x20
 9ec:	9301                	srli	a4,a4,0x20
 9ee:	0712                	slli	a4,a4,0x4
 9f0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9f2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9f6:	00000717          	auipc	a4,0x0
 9fa:	0ea73d23          	sd	a0,250(a4) # af0 <freep>
      return (void*)(p + 1);
 9fe:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a02:	70e2                	ld	ra,56(sp)
 a04:	7442                	ld	s0,48(sp)
 a06:	74a2                	ld	s1,40(sp)
 a08:	7902                	ld	s2,32(sp)
 a0a:	69e2                	ld	s3,24(sp)
 a0c:	6a42                	ld	s4,16(sp)
 a0e:	6aa2                	ld	s5,8(sp)
 a10:	6b02                	ld	s6,0(sp)
 a12:	6121                	addi	sp,sp,64
 a14:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a16:	6398                	ld	a4,0(a5)
 a18:	e118                	sd	a4,0(a0)
 a1a:	bff1                	j	9f6 <malloc+0x86>
  hp->s.size = nu;
 a1c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a20:	0541                	addi	a0,a0,16
 a22:	00000097          	auipc	ra,0x0
 a26:	ec6080e7          	jalr	-314(ra) # 8e8 <free>
  return freep;
 a2a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a2e:	d971                	beqz	a0,a02 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a30:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a32:	4798                	lw	a4,8(a5)
 a34:	fa9776e3          	bgeu	a4,s1,9e0 <malloc+0x70>
    if(p == freep)
 a38:	00093703          	ld	a4,0(s2)
 a3c:	853e                	mv	a0,a5
 a3e:	fef719e3          	bne	a4,a5,a30 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a42:	8552                	mv	a0,s4
 a44:	00000097          	auipc	ra,0x0
 a48:	b5e080e7          	jalr	-1186(ra) # 5a2 <sbrk>
  if(p == (char*)-1)
 a4c:	fd5518e3          	bne	a0,s5,a1c <malloc+0xac>
        return 0;
 a50:	4501                	li	a0,0
 a52:	bf45                	j	a02 <malloc+0x92>
