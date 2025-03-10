
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
 132:	91a58593          	addi	a1,a1,-1766 # a48 <malloc+0xe8>
 136:	4509                	li	a0,2
 138:	00000097          	auipc	ra,0x0
 13c:	73c080e7          	jalr	1852(ra) # 874 <fprintf>
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
 16c:	8f858593          	addi	a1,a1,-1800 # a60 <malloc+0x100>
 170:	4509                	li	a0,2
 172:	00000097          	auipc	ra,0x0
 176:	702080e7          	jalr	1794(ra) # 874 <fprintf>
        close(fd);
 17a:	8526                	mv	a0,s1
 17c:	00000097          	auipc	ra,0x0
 180:	3c6080e7          	jalr	966(ra) # 542 <close>
        return;
 184:	bf75                	j	140 <find+0x94>
            printf("%s\n", curr_path);
 186:	85ca                	mv	a1,s2
 188:	00001517          	auipc	a0,0x1
 18c:	8f050513          	addi	a0,a0,-1808 # a78 <malloc+0x118>
 190:	00000097          	auipc	ra,0x0
 194:	712080e7          	jalr	1810(ra) # 8a2 <printf>
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
 1ea:	89aa8a93          	addi	s5,s5,-1894 # a80 <malloc+0x120>
 1ee:	00001b17          	auipc	s6,0x1
 1f2:	89ab0b13          	addi	s6,s6,-1894 # a88 <malloc+0x128>
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
 274:	82058593          	addi	a1,a1,-2016 # a90 <malloc+0x130>
 278:	4509                	li	a0,2
 27a:	00000097          	auipc	ra,0x0
 27e:	5fa080e7          	jalr	1530(ra) # 874 <fprintf>
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

00000000000005ca <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5ca:	1101                	addi	sp,sp,-32
 5cc:	ec06                	sd	ra,24(sp)
 5ce:	e822                	sd	s0,16(sp)
 5d0:	1000                	addi	s0,sp,32
 5d2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5d6:	4605                	li	a2,1
 5d8:	fef40593          	addi	a1,s0,-17
 5dc:	00000097          	auipc	ra,0x0
 5e0:	f5e080e7          	jalr	-162(ra) # 53a <write>
}
 5e4:	60e2                	ld	ra,24(sp)
 5e6:	6442                	ld	s0,16(sp)
 5e8:	6105                	addi	sp,sp,32
 5ea:	8082                	ret

00000000000005ec <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5ec:	7139                	addi	sp,sp,-64
 5ee:	fc06                	sd	ra,56(sp)
 5f0:	f822                	sd	s0,48(sp)
 5f2:	f426                	sd	s1,40(sp)
 5f4:	f04a                	sd	s2,32(sp)
 5f6:	ec4e                	sd	s3,24(sp)
 5f8:	0080                	addi	s0,sp,64
 5fa:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5fc:	c299                	beqz	a3,602 <printint+0x16>
 5fe:	0805c863          	bltz	a1,68e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 602:	2581                	sext.w	a1,a1
  neg = 0;
 604:	4881                	li	a7,0
 606:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 60a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 60c:	2601                	sext.w	a2,a2
 60e:	00000517          	auipc	a0,0x0
 612:	4ba50513          	addi	a0,a0,1210 # ac8 <digits>
 616:	883a                	mv	a6,a4
 618:	2705                	addiw	a4,a4,1
 61a:	02c5f7bb          	remuw	a5,a1,a2
 61e:	1782                	slli	a5,a5,0x20
 620:	9381                	srli	a5,a5,0x20
 622:	97aa                	add	a5,a5,a0
 624:	0007c783          	lbu	a5,0(a5)
 628:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 62c:	0005879b          	sext.w	a5,a1
 630:	02c5d5bb          	divuw	a1,a1,a2
 634:	0685                	addi	a3,a3,1
 636:	fec7f0e3          	bgeu	a5,a2,616 <printint+0x2a>
  if(neg)
 63a:	00088b63          	beqz	a7,650 <printint+0x64>
    buf[i++] = '-';
 63e:	fd040793          	addi	a5,s0,-48
 642:	973e                	add	a4,a4,a5
 644:	02d00793          	li	a5,45
 648:	fef70823          	sb	a5,-16(a4)
 64c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 650:	02e05863          	blez	a4,680 <printint+0x94>
 654:	fc040793          	addi	a5,s0,-64
 658:	00e78933          	add	s2,a5,a4
 65c:	fff78993          	addi	s3,a5,-1
 660:	99ba                	add	s3,s3,a4
 662:	377d                	addiw	a4,a4,-1
 664:	1702                	slli	a4,a4,0x20
 666:	9301                	srli	a4,a4,0x20
 668:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 66c:	fff94583          	lbu	a1,-1(s2)
 670:	8526                	mv	a0,s1
 672:	00000097          	auipc	ra,0x0
 676:	f58080e7          	jalr	-168(ra) # 5ca <putc>
  while(--i >= 0)
 67a:	197d                	addi	s2,s2,-1
 67c:	ff3918e3          	bne	s2,s3,66c <printint+0x80>
}
 680:	70e2                	ld	ra,56(sp)
 682:	7442                	ld	s0,48(sp)
 684:	74a2                	ld	s1,40(sp)
 686:	7902                	ld	s2,32(sp)
 688:	69e2                	ld	s3,24(sp)
 68a:	6121                	addi	sp,sp,64
 68c:	8082                	ret
    x = -xx;
 68e:	40b005bb          	negw	a1,a1
    neg = 1;
 692:	4885                	li	a7,1
    x = -xx;
 694:	bf8d                	j	606 <printint+0x1a>

0000000000000696 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 696:	7119                	addi	sp,sp,-128
 698:	fc86                	sd	ra,120(sp)
 69a:	f8a2                	sd	s0,112(sp)
 69c:	f4a6                	sd	s1,104(sp)
 69e:	f0ca                	sd	s2,96(sp)
 6a0:	ecce                	sd	s3,88(sp)
 6a2:	e8d2                	sd	s4,80(sp)
 6a4:	e4d6                	sd	s5,72(sp)
 6a6:	e0da                	sd	s6,64(sp)
 6a8:	fc5e                	sd	s7,56(sp)
 6aa:	f862                	sd	s8,48(sp)
 6ac:	f466                	sd	s9,40(sp)
 6ae:	f06a                	sd	s10,32(sp)
 6b0:	ec6e                	sd	s11,24(sp)
 6b2:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6b4:	0005c903          	lbu	s2,0(a1)
 6b8:	18090f63          	beqz	s2,856 <vprintf+0x1c0>
 6bc:	8aaa                	mv	s5,a0
 6be:	8b32                	mv	s6,a2
 6c0:	00158493          	addi	s1,a1,1
  state = 0;
 6c4:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6c6:	02500a13          	li	s4,37
      if(c == 'd'){
 6ca:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6ce:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6d2:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6d6:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6da:	00000b97          	auipc	s7,0x0
 6de:	3eeb8b93          	addi	s7,s7,1006 # ac8 <digits>
 6e2:	a839                	j	700 <vprintf+0x6a>
        putc(fd, c);
 6e4:	85ca                	mv	a1,s2
 6e6:	8556                	mv	a0,s5
 6e8:	00000097          	auipc	ra,0x0
 6ec:	ee2080e7          	jalr	-286(ra) # 5ca <putc>
 6f0:	a019                	j	6f6 <vprintf+0x60>
    } else if(state == '%'){
 6f2:	01498f63          	beq	s3,s4,710 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6f6:	0485                	addi	s1,s1,1
 6f8:	fff4c903          	lbu	s2,-1(s1)
 6fc:	14090d63          	beqz	s2,856 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 700:	0009079b          	sext.w	a5,s2
    if(state == 0){
 704:	fe0997e3          	bnez	s3,6f2 <vprintf+0x5c>
      if(c == '%'){
 708:	fd479ee3          	bne	a5,s4,6e4 <vprintf+0x4e>
        state = '%';
 70c:	89be                	mv	s3,a5
 70e:	b7e5                	j	6f6 <vprintf+0x60>
      if(c == 'd'){
 710:	05878063          	beq	a5,s8,750 <vprintf+0xba>
      } else if(c == 'l') {
 714:	05978c63          	beq	a5,s9,76c <vprintf+0xd6>
      } else if(c == 'x') {
 718:	07a78863          	beq	a5,s10,788 <vprintf+0xf2>
      } else if(c == 'p') {
 71c:	09b78463          	beq	a5,s11,7a4 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 720:	07300713          	li	a4,115
 724:	0ce78663          	beq	a5,a4,7f0 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 728:	06300713          	li	a4,99
 72c:	0ee78e63          	beq	a5,a4,828 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 730:	11478863          	beq	a5,s4,840 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 734:	85d2                	mv	a1,s4
 736:	8556                	mv	a0,s5
 738:	00000097          	auipc	ra,0x0
 73c:	e92080e7          	jalr	-366(ra) # 5ca <putc>
        putc(fd, c);
 740:	85ca                	mv	a1,s2
 742:	8556                	mv	a0,s5
 744:	00000097          	auipc	ra,0x0
 748:	e86080e7          	jalr	-378(ra) # 5ca <putc>
      }
      state = 0;
 74c:	4981                	li	s3,0
 74e:	b765                	j	6f6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 750:	008b0913          	addi	s2,s6,8
 754:	4685                	li	a3,1
 756:	4629                	li	a2,10
 758:	000b2583          	lw	a1,0(s6)
 75c:	8556                	mv	a0,s5
 75e:	00000097          	auipc	ra,0x0
 762:	e8e080e7          	jalr	-370(ra) # 5ec <printint>
 766:	8b4a                	mv	s6,s2
      state = 0;
 768:	4981                	li	s3,0
 76a:	b771                	j	6f6 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 76c:	008b0913          	addi	s2,s6,8
 770:	4681                	li	a3,0
 772:	4629                	li	a2,10
 774:	000b2583          	lw	a1,0(s6)
 778:	8556                	mv	a0,s5
 77a:	00000097          	auipc	ra,0x0
 77e:	e72080e7          	jalr	-398(ra) # 5ec <printint>
 782:	8b4a                	mv	s6,s2
      state = 0;
 784:	4981                	li	s3,0
 786:	bf85                	j	6f6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 788:	008b0913          	addi	s2,s6,8
 78c:	4681                	li	a3,0
 78e:	4641                	li	a2,16
 790:	000b2583          	lw	a1,0(s6)
 794:	8556                	mv	a0,s5
 796:	00000097          	auipc	ra,0x0
 79a:	e56080e7          	jalr	-426(ra) # 5ec <printint>
 79e:	8b4a                	mv	s6,s2
      state = 0;
 7a0:	4981                	li	s3,0
 7a2:	bf91                	j	6f6 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7a4:	008b0793          	addi	a5,s6,8
 7a8:	f8f43423          	sd	a5,-120(s0)
 7ac:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7b0:	03000593          	li	a1,48
 7b4:	8556                	mv	a0,s5
 7b6:	00000097          	auipc	ra,0x0
 7ba:	e14080e7          	jalr	-492(ra) # 5ca <putc>
  putc(fd, 'x');
 7be:	85ea                	mv	a1,s10
 7c0:	8556                	mv	a0,s5
 7c2:	00000097          	auipc	ra,0x0
 7c6:	e08080e7          	jalr	-504(ra) # 5ca <putc>
 7ca:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7cc:	03c9d793          	srli	a5,s3,0x3c
 7d0:	97de                	add	a5,a5,s7
 7d2:	0007c583          	lbu	a1,0(a5)
 7d6:	8556                	mv	a0,s5
 7d8:	00000097          	auipc	ra,0x0
 7dc:	df2080e7          	jalr	-526(ra) # 5ca <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7e0:	0992                	slli	s3,s3,0x4
 7e2:	397d                	addiw	s2,s2,-1
 7e4:	fe0914e3          	bnez	s2,7cc <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7e8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7ec:	4981                	li	s3,0
 7ee:	b721                	j	6f6 <vprintf+0x60>
        s = va_arg(ap, char*);
 7f0:	008b0993          	addi	s3,s6,8
 7f4:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 7f8:	02090163          	beqz	s2,81a <vprintf+0x184>
        while(*s != 0){
 7fc:	00094583          	lbu	a1,0(s2)
 800:	c9a1                	beqz	a1,850 <vprintf+0x1ba>
          putc(fd, *s);
 802:	8556                	mv	a0,s5
 804:	00000097          	auipc	ra,0x0
 808:	dc6080e7          	jalr	-570(ra) # 5ca <putc>
          s++;
 80c:	0905                	addi	s2,s2,1
        while(*s != 0){
 80e:	00094583          	lbu	a1,0(s2)
 812:	f9e5                	bnez	a1,802 <vprintf+0x16c>
        s = va_arg(ap, char*);
 814:	8b4e                	mv	s6,s3
      state = 0;
 816:	4981                	li	s3,0
 818:	bdf9                	j	6f6 <vprintf+0x60>
          s = "(null)";
 81a:	00000917          	auipc	s2,0x0
 81e:	2a690913          	addi	s2,s2,678 # ac0 <malloc+0x160>
        while(*s != 0){
 822:	02800593          	li	a1,40
 826:	bff1                	j	802 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 828:	008b0913          	addi	s2,s6,8
 82c:	000b4583          	lbu	a1,0(s6)
 830:	8556                	mv	a0,s5
 832:	00000097          	auipc	ra,0x0
 836:	d98080e7          	jalr	-616(ra) # 5ca <putc>
 83a:	8b4a                	mv	s6,s2
      state = 0;
 83c:	4981                	li	s3,0
 83e:	bd65                	j	6f6 <vprintf+0x60>
        putc(fd, c);
 840:	85d2                	mv	a1,s4
 842:	8556                	mv	a0,s5
 844:	00000097          	auipc	ra,0x0
 848:	d86080e7          	jalr	-634(ra) # 5ca <putc>
      state = 0;
 84c:	4981                	li	s3,0
 84e:	b565                	j	6f6 <vprintf+0x60>
        s = va_arg(ap, char*);
 850:	8b4e                	mv	s6,s3
      state = 0;
 852:	4981                	li	s3,0
 854:	b54d                	j	6f6 <vprintf+0x60>
    }
  }
}
 856:	70e6                	ld	ra,120(sp)
 858:	7446                	ld	s0,112(sp)
 85a:	74a6                	ld	s1,104(sp)
 85c:	7906                	ld	s2,96(sp)
 85e:	69e6                	ld	s3,88(sp)
 860:	6a46                	ld	s4,80(sp)
 862:	6aa6                	ld	s5,72(sp)
 864:	6b06                	ld	s6,64(sp)
 866:	7be2                	ld	s7,56(sp)
 868:	7c42                	ld	s8,48(sp)
 86a:	7ca2                	ld	s9,40(sp)
 86c:	7d02                	ld	s10,32(sp)
 86e:	6de2                	ld	s11,24(sp)
 870:	6109                	addi	sp,sp,128
 872:	8082                	ret

0000000000000874 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 874:	715d                	addi	sp,sp,-80
 876:	ec06                	sd	ra,24(sp)
 878:	e822                	sd	s0,16(sp)
 87a:	1000                	addi	s0,sp,32
 87c:	e010                	sd	a2,0(s0)
 87e:	e414                	sd	a3,8(s0)
 880:	e818                	sd	a4,16(s0)
 882:	ec1c                	sd	a5,24(s0)
 884:	03043023          	sd	a6,32(s0)
 888:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 88c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 890:	8622                	mv	a2,s0
 892:	00000097          	auipc	ra,0x0
 896:	e04080e7          	jalr	-508(ra) # 696 <vprintf>
}
 89a:	60e2                	ld	ra,24(sp)
 89c:	6442                	ld	s0,16(sp)
 89e:	6161                	addi	sp,sp,80
 8a0:	8082                	ret

00000000000008a2 <printf>:

void
printf(const char *fmt, ...)
{
 8a2:	711d                	addi	sp,sp,-96
 8a4:	ec06                	sd	ra,24(sp)
 8a6:	e822                	sd	s0,16(sp)
 8a8:	1000                	addi	s0,sp,32
 8aa:	e40c                	sd	a1,8(s0)
 8ac:	e810                	sd	a2,16(s0)
 8ae:	ec14                	sd	a3,24(s0)
 8b0:	f018                	sd	a4,32(s0)
 8b2:	f41c                	sd	a5,40(s0)
 8b4:	03043823          	sd	a6,48(s0)
 8b8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8bc:	00840613          	addi	a2,s0,8
 8c0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8c4:	85aa                	mv	a1,a0
 8c6:	4505                	li	a0,1
 8c8:	00000097          	auipc	ra,0x0
 8cc:	dce080e7          	jalr	-562(ra) # 696 <vprintf>
}
 8d0:	60e2                	ld	ra,24(sp)
 8d2:	6442                	ld	s0,16(sp)
 8d4:	6125                	addi	sp,sp,96
 8d6:	8082                	ret

00000000000008d8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8d8:	1141                	addi	sp,sp,-16
 8da:	e422                	sd	s0,8(sp)
 8dc:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8de:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8e2:	00000797          	auipc	a5,0x0
 8e6:	1fe7b783          	ld	a5,510(a5) # ae0 <freep>
 8ea:	a805                	j	91a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8ec:	4618                	lw	a4,8(a2)
 8ee:	9db9                	addw	a1,a1,a4
 8f0:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 8f4:	6398                	ld	a4,0(a5)
 8f6:	6318                	ld	a4,0(a4)
 8f8:	fee53823          	sd	a4,-16(a0)
 8fc:	a091                	j	940 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8fe:	ff852703          	lw	a4,-8(a0)
 902:	9e39                	addw	a2,a2,a4
 904:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 906:	ff053703          	ld	a4,-16(a0)
 90a:	e398                	sd	a4,0(a5)
 90c:	a099                	j	952 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 90e:	6398                	ld	a4,0(a5)
 910:	00e7e463          	bltu	a5,a4,918 <free+0x40>
 914:	00e6ea63          	bltu	a3,a4,928 <free+0x50>
{
 918:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 91a:	fed7fae3          	bgeu	a5,a3,90e <free+0x36>
 91e:	6398                	ld	a4,0(a5)
 920:	00e6e463          	bltu	a3,a4,928 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 924:	fee7eae3          	bltu	a5,a4,918 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 928:	ff852583          	lw	a1,-8(a0)
 92c:	6390                	ld	a2,0(a5)
 92e:	02059713          	slli	a4,a1,0x20
 932:	9301                	srli	a4,a4,0x20
 934:	0712                	slli	a4,a4,0x4
 936:	9736                	add	a4,a4,a3
 938:	fae60ae3          	beq	a2,a4,8ec <free+0x14>
    bp->s.ptr = p->s.ptr;
 93c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 940:	4790                	lw	a2,8(a5)
 942:	02061713          	slli	a4,a2,0x20
 946:	9301                	srli	a4,a4,0x20
 948:	0712                	slli	a4,a4,0x4
 94a:	973e                	add	a4,a4,a5
 94c:	fae689e3          	beq	a3,a4,8fe <free+0x26>
  } else
    p->s.ptr = bp;
 950:	e394                	sd	a3,0(a5)
  freep = p;
 952:	00000717          	auipc	a4,0x0
 956:	18f73723          	sd	a5,398(a4) # ae0 <freep>
}
 95a:	6422                	ld	s0,8(sp)
 95c:	0141                	addi	sp,sp,16
 95e:	8082                	ret

0000000000000960 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 960:	7139                	addi	sp,sp,-64
 962:	fc06                	sd	ra,56(sp)
 964:	f822                	sd	s0,48(sp)
 966:	f426                	sd	s1,40(sp)
 968:	f04a                	sd	s2,32(sp)
 96a:	ec4e                	sd	s3,24(sp)
 96c:	e852                	sd	s4,16(sp)
 96e:	e456                	sd	s5,8(sp)
 970:	e05a                	sd	s6,0(sp)
 972:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 974:	02051493          	slli	s1,a0,0x20
 978:	9081                	srli	s1,s1,0x20
 97a:	04bd                	addi	s1,s1,15
 97c:	8091                	srli	s1,s1,0x4
 97e:	0014899b          	addiw	s3,s1,1
 982:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 984:	00000517          	auipc	a0,0x0
 988:	15c53503          	ld	a0,348(a0) # ae0 <freep>
 98c:	c515                	beqz	a0,9b8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 98e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 990:	4798                	lw	a4,8(a5)
 992:	02977f63          	bgeu	a4,s1,9d0 <malloc+0x70>
 996:	8a4e                	mv	s4,s3
 998:	0009871b          	sext.w	a4,s3
 99c:	6685                	lui	a3,0x1
 99e:	00d77363          	bgeu	a4,a3,9a4 <malloc+0x44>
 9a2:	6a05                	lui	s4,0x1
 9a4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9a8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9ac:	00000917          	auipc	s2,0x0
 9b0:	13490913          	addi	s2,s2,308 # ae0 <freep>
  if(p == (char*)-1)
 9b4:	5afd                	li	s5,-1
 9b6:	a88d                	j	a28 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 9b8:	00000797          	auipc	a5,0x0
 9bc:	13078793          	addi	a5,a5,304 # ae8 <base>
 9c0:	00000717          	auipc	a4,0x0
 9c4:	12f73023          	sd	a5,288(a4) # ae0 <freep>
 9c8:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9ca:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9ce:	b7e1                	j	996 <malloc+0x36>
      if(p->s.size == nunits)
 9d0:	02e48b63          	beq	s1,a4,a06 <malloc+0xa6>
        p->s.size -= nunits;
 9d4:	4137073b          	subw	a4,a4,s3
 9d8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9da:	1702                	slli	a4,a4,0x20
 9dc:	9301                	srli	a4,a4,0x20
 9de:	0712                	slli	a4,a4,0x4
 9e0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9e2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9e6:	00000717          	auipc	a4,0x0
 9ea:	0ea73d23          	sd	a0,250(a4) # ae0 <freep>
      return (void*)(p + 1);
 9ee:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 9f2:	70e2                	ld	ra,56(sp)
 9f4:	7442                	ld	s0,48(sp)
 9f6:	74a2                	ld	s1,40(sp)
 9f8:	7902                	ld	s2,32(sp)
 9fa:	69e2                	ld	s3,24(sp)
 9fc:	6a42                	ld	s4,16(sp)
 9fe:	6aa2                	ld	s5,8(sp)
 a00:	6b02                	ld	s6,0(sp)
 a02:	6121                	addi	sp,sp,64
 a04:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a06:	6398                	ld	a4,0(a5)
 a08:	e118                	sd	a4,0(a0)
 a0a:	bff1                	j	9e6 <malloc+0x86>
  hp->s.size = nu;
 a0c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a10:	0541                	addi	a0,a0,16
 a12:	00000097          	auipc	ra,0x0
 a16:	ec6080e7          	jalr	-314(ra) # 8d8 <free>
  return freep;
 a1a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a1e:	d971                	beqz	a0,9f2 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a20:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a22:	4798                	lw	a4,8(a5)
 a24:	fa9776e3          	bgeu	a4,s1,9d0 <malloc+0x70>
    if(p == freep)
 a28:	00093703          	ld	a4,0(s2)
 a2c:	853e                	mv	a0,a5
 a2e:	fef719e3          	bne	a4,a5,a20 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a32:	8552                	mv	a0,s4
 a34:	00000097          	auipc	ra,0x0
 a38:	b6e080e7          	jalr	-1170(ra) # 5a2 <sbrk>
  if(p == (char*)-1)
 a3c:	fd5518e3          	bne	a0,s5,a0c <malloc+0xac>
        return 0;
 a40:	4501                	li	a0,0
 a42:	bf45                	j	9f2 <malloc+0x92>
