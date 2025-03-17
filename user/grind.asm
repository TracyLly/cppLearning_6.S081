
user/_grind:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <do_rand>:
#include "kernel/riscv.h"

// from FreeBSD.
int
do_rand(unsigned long *ctx)
{
       0:	1141                	addi	sp,sp,-16
       2:	e422                	sd	s0,8(sp)
       4:	0800                	addi	s0,sp,16
 * October 1988, p. 1195.
 */
    long hi, lo, x;

    /* Transform to [1, 0x7ffffffe] range. */
    x = (*ctx % 0x7ffffffe) + 1;
       6:	611c                	ld	a5,0(a0)
       8:	80000737          	lui	a4,0x80000
       c:	ffe74713          	xori	a4,a4,-2
      10:	02e7f7b3          	remu	a5,a5,a4
      14:	0785                	addi	a5,a5,1
    hi = x / 127773;
    lo = x % 127773;
      16:	66fd                	lui	a3,0x1f
      18:	31d68693          	addi	a3,a3,797 # 1f31d <__global_pointer$+0x1d401>
      1c:	02d7e733          	rem	a4,a5,a3
    x = 16807 * lo - 2836 * hi;
      20:	6611                	lui	a2,0x4
      22:	1a760613          	addi	a2,a2,423 # 41a7 <__global_pointer$+0x228b>
      26:	02c70733          	mul	a4,a4,a2
    hi = x / 127773;
      2a:	02d7c7b3          	div	a5,a5,a3
    x = 16807 * lo - 2836 * hi;
      2e:	76fd                	lui	a3,0xfffff
      30:	4ec68693          	addi	a3,a3,1260 # fffffffffffff4ec <__global_pointer$+0xffffffffffffd5d0>
      34:	02d787b3          	mul	a5,a5,a3
      38:	97ba                	add	a5,a5,a4
    if (x < 0)
      3a:	0007c963          	bltz	a5,4c <do_rand+0x4c>
        x += 0x7fffffff;
    /* Transform to [0, 0x7ffffffd] range. */
    x--;
      3e:	17fd                	addi	a5,a5,-1
    *ctx = x;
      40:	e11c                	sd	a5,0(a0)
    return (x);
}
      42:	0007851b          	sext.w	a0,a5
      46:	6422                	ld	s0,8(sp)
      48:	0141                	addi	sp,sp,16
      4a:	8082                	ret
        x += 0x7fffffff;
      4c:	80000737          	lui	a4,0x80000
      50:	fff74713          	not	a4,a4
      54:	97ba                	add	a5,a5,a4
      56:	b7e5                	j	3e <do_rand+0x3e>

0000000000000058 <rand>:

unsigned long rand_next = 1;

int
rand(void)
{
      58:	1141                	addi	sp,sp,-16
      5a:	e406                	sd	ra,8(sp)
      5c:	e022                	sd	s0,0(sp)
      5e:	0800                	addi	s0,sp,16
    return (do_rand(&rand_next));
      60:	00001517          	auipc	a0,0x1
      64:	6c050513          	addi	a0,a0,1728 # 1720 <rand_next>
      68:	00000097          	auipc	ra,0x0
      6c:	f98080e7          	jalr	-104(ra) # 0 <do_rand>
}
      70:	60a2                	ld	ra,8(sp)
      72:	6402                	ld	s0,0(sp)
      74:	0141                	addi	sp,sp,16
      76:	8082                	ret

0000000000000078 <go>:

void
go(int which_child)
{
      78:	7159                	addi	sp,sp,-112
      7a:	f486                	sd	ra,104(sp)
      7c:	f0a2                	sd	s0,96(sp)
      7e:	eca6                	sd	s1,88(sp)
      80:	e8ca                	sd	s2,80(sp)
      82:	e4ce                	sd	s3,72(sp)
      84:	e0d2                	sd	s4,64(sp)
      86:	fc56                	sd	s5,56(sp)
      88:	f85a                	sd	s6,48(sp)
      8a:	1880                	addi	s0,sp,112
      8c:	84aa                	mv	s1,a0
  int fd = -1;
  static char buf[999];
  char *break0 = sbrk(0);
      8e:	4501                	li	a0,0
      90:	00001097          	auipc	ra,0x1
      94:	e56080e7          	jalr	-426(ra) # ee6 <sbrk>
      98:	8a2a                	mv	s4,a0
  uint64 iters = 0;

  mkdir("grindir");
      9a:	00001517          	auipc	a0,0x1
      9e:	37650513          	addi	a0,a0,886 # 1410 <statistics+0x88>
      a2:	00001097          	auipc	ra,0x1
      a6:	e24080e7          	jalr	-476(ra) # ec6 <mkdir>
  if(chdir("grindir") != 0){
      aa:	00001517          	auipc	a0,0x1
      ae:	36650513          	addi	a0,a0,870 # 1410 <statistics+0x88>
      b2:	00001097          	auipc	ra,0x1
      b6:	e1c080e7          	jalr	-484(ra) # ece <chdir>
      ba:	cd11                	beqz	a0,d6 <go+0x5e>
    printf("chdir grindir failed\n");
      bc:	00001517          	auipc	a0,0x1
      c0:	35c50513          	addi	a0,a0,860 # 1418 <statistics+0x90>
      c4:	00001097          	auipc	ra,0x1
      c8:	122080e7          	jalr	290(ra) # 11e6 <printf>
    exit(1);
      cc:	4505                	li	a0,1
      ce:	00001097          	auipc	ra,0x1
      d2:	d90080e7          	jalr	-624(ra) # e5e <exit>
  }
  chdir("/");
      d6:	00001517          	auipc	a0,0x1
      da:	35a50513          	addi	a0,a0,858 # 1430 <statistics+0xa8>
      de:	00001097          	auipc	ra,0x1
      e2:	df0080e7          	jalr	-528(ra) # ece <chdir>
  
  while(1){
    iters++;
    if((iters % 500) == 0)
      e6:	00001997          	auipc	s3,0x1
      ea:	35a98993          	addi	s3,s3,858 # 1440 <statistics+0xb8>
      ee:	c489                	beqz	s1,f8 <go+0x80>
      f0:	00001997          	auipc	s3,0x1
      f4:	34898993          	addi	s3,s3,840 # 1438 <statistics+0xb0>
    iters++;
      f8:	4485                	li	s1,1
  int fd = -1;
      fa:	597d                	li	s2,-1
        printf("grind: fork failed\n");
        exit(1);
      }
      wait(0);
    } else if(what == 15){
      sbrk(6011);
      fc:	6a85                	lui	s5,0x1
      fe:	77ba8a93          	addi	s5,s5,1915 # 177b <buf.1239+0x4b>
     102:	a825                	j	13a <go+0xc2>
      close(open("grindir/../a", O_CREATE|O_RDWR));
     104:	20200593          	li	a1,514
     108:	00001517          	auipc	a0,0x1
     10c:	34050513          	addi	a0,a0,832 # 1448 <statistics+0xc0>
     110:	00001097          	auipc	ra,0x1
     114:	d8e080e7          	jalr	-626(ra) # e9e <open>
     118:	00001097          	auipc	ra,0x1
     11c:	d6e080e7          	jalr	-658(ra) # e86 <close>
    iters++;
     120:	0485                	addi	s1,s1,1
    if((iters % 500) == 0)
     122:	1f400793          	li	a5,500
     126:	02f4f7b3          	remu	a5,s1,a5
     12a:	eb81                	bnez	a5,13a <go+0xc2>
      write(1, which_child?"B":"A", 1);
     12c:	4605                	li	a2,1
     12e:	85ce                	mv	a1,s3
     130:	4505                	li	a0,1
     132:	00001097          	auipc	ra,0x1
     136:	d4c080e7          	jalr	-692(ra) # e7e <write>
    int what = rand() % 23;
     13a:	00000097          	auipc	ra,0x0
     13e:	f1e080e7          	jalr	-226(ra) # 58 <rand>
     142:	47dd                	li	a5,23
     144:	02f5653b          	remw	a0,a0,a5
    if(what == 1){
     148:	4785                	li	a5,1
     14a:	faf50de3          	beq	a0,a5,104 <go+0x8c>
    } else if(what == 2){
     14e:	4789                	li	a5,2
     150:	16f50e63          	beq	a0,a5,2cc <go+0x254>
    } else if(what == 3){
     154:	478d                	li	a5,3
     156:	18f50a63          	beq	a0,a5,2ea <go+0x272>
    } else if(what == 4){
     15a:	4791                	li	a5,4
     15c:	1af50063          	beq	a0,a5,2fc <go+0x284>
    } else if(what == 5){
     160:	4795                	li	a5,5
     162:	1ef50463          	beq	a0,a5,34a <go+0x2d2>
    } else if(what == 6){
     166:	4799                	li	a5,6
     168:	20f50263          	beq	a0,a5,36c <go+0x2f4>
    } else if(what == 7){
     16c:	479d                	li	a5,7
     16e:	22f50063          	beq	a0,a5,38e <go+0x316>
    } else if(what == 8){
     172:	47a1                	li	a5,8
     174:	22f50963          	beq	a0,a5,3a6 <go+0x32e>
    } else if(what == 9){
     178:	47a5                	li	a5,9
     17a:	24f50263          	beq	a0,a5,3be <go+0x346>
    } else if(what == 10){
     17e:	47a9                	li	a5,10
     180:	26f50e63          	beq	a0,a5,3fc <go+0x384>
    } else if(what == 11){
     184:	47ad                	li	a5,11
     186:	2af50a63          	beq	a0,a5,43a <go+0x3c2>
    } else if(what == 12){
     18a:	47b1                	li	a5,12
     18c:	2cf50c63          	beq	a0,a5,464 <go+0x3ec>
    } else if(what == 13){
     190:	47b5                	li	a5,13
     192:	2ef50e63          	beq	a0,a5,48e <go+0x416>
    } else if(what == 14){
     196:	47b9                	li	a5,14
     198:	32f50963          	beq	a0,a5,4ca <go+0x452>
    } else if(what == 15){
     19c:	47bd                	li	a5,15
     19e:	36f50d63          	beq	a0,a5,518 <go+0x4a0>
    } else if(what == 16){
     1a2:	47c1                	li	a5,16
     1a4:	38f50063          	beq	a0,a5,524 <go+0x4ac>
      if(sbrk(0) > break0)
        sbrk(-(sbrk(0) - break0));
    } else if(what == 17){
     1a8:	47c5                	li	a5,17
     1aa:	3af50063          	beq	a0,a5,54a <go+0x4d2>
        printf("chdir failed\n");
        exit(1);
      }
      kill(pid);
      wait(0);
    } else if(what == 18){
     1ae:	47c9                	li	a5,18
     1b0:	42f50663          	beq	a0,a5,5dc <go+0x564>
      } else if(pid < 0){
        printf("grind: fork failed\n");
        exit(1);
      }
      wait(0);
    } else if(what == 19){
     1b4:	47cd                	li	a5,19
     1b6:	46f50a63          	beq	a0,a5,62a <go+0x5b2>
        exit(1);
      }
      close(fds[0]);
      close(fds[1]);
      wait(0);
    } else if(what == 20){
     1ba:	47d1                	li	a5,20
     1bc:	54f50b63          	beq	a0,a5,712 <go+0x69a>
      } else if(pid < 0){
        printf("fork failed\n");
        exit(1);
      }
      wait(0);
    } else if(what == 21){
     1c0:	47d5                	li	a5,21
     1c2:	5ef50963          	beq	a0,a5,7b4 <go+0x73c>
        printf("fstat reports crazy i-number %d\n", st.ino);
        exit(1);
      }
      close(fd1);
      unlink("c");
    } else if(what == 22){
     1c6:	47d9                	li	a5,22
     1c8:	f4f51ce3          	bne	a0,a5,120 <go+0xa8>
      // echo hi | cat
      int aa[2], bb[2];
      if(pipe(aa) < 0){
     1cc:	f9840513          	addi	a0,s0,-104
     1d0:	00001097          	auipc	ra,0x1
     1d4:	c9e080e7          	jalr	-866(ra) # e6e <pipe>
     1d8:	6e054263          	bltz	a0,8bc <go+0x844>
        fprintf(2, "pipe failed\n");
        exit(1);
      }
      if(pipe(bb) < 0){
     1dc:	fa040513          	addi	a0,s0,-96
     1e0:	00001097          	auipc	ra,0x1
     1e4:	c8e080e7          	jalr	-882(ra) # e6e <pipe>
     1e8:	6e054863          	bltz	a0,8d8 <go+0x860>
        fprintf(2, "pipe failed\n");
        exit(1);
      }
      int pid1 = fork();
     1ec:	00001097          	auipc	ra,0x1
     1f0:	c6a080e7          	jalr	-918(ra) # e56 <fork>
      if(pid1 == 0){
     1f4:	70050063          	beqz	a0,8f4 <go+0x87c>
        close(aa[1]);
        char *args[3] = { "echo", "hi", 0 };
        exec("grindir/../echo", args);
        fprintf(2, "echo: not found\n");
        exit(2);
      } else if(pid1 < 0){
     1f8:	7a054863          	bltz	a0,9a8 <go+0x930>
        fprintf(2, "fork failed\n");
        exit(3);
      }
      int pid2 = fork();
     1fc:	00001097          	auipc	ra,0x1
     200:	c5a080e7          	jalr	-934(ra) # e56 <fork>
      if(pid2 == 0){
     204:	7c050063          	beqz	a0,9c4 <go+0x94c>
        close(bb[1]);
        char *args[2] = { "cat", 0 };
        exec("/cat", args);
        fprintf(2, "cat: not found\n");
        exit(6);
      } else if(pid2 < 0){
     208:	08054ce3          	bltz	a0,aa0 <go+0xa28>
        fprintf(2, "fork failed\n");
        exit(7);
      }
      close(aa[0]);
     20c:	f9842503          	lw	a0,-104(s0)
     210:	00001097          	auipc	ra,0x1
     214:	c76080e7          	jalr	-906(ra) # e86 <close>
      close(aa[1]);
     218:	f9c42503          	lw	a0,-100(s0)
     21c:	00001097          	auipc	ra,0x1
     220:	c6a080e7          	jalr	-918(ra) # e86 <close>
      close(bb[1]);
     224:	fa442503          	lw	a0,-92(s0)
     228:	00001097          	auipc	ra,0x1
     22c:	c5e080e7          	jalr	-930(ra) # e86 <close>
      char buf[3] = { 0, 0, 0 };
     230:	f8041823          	sh	zero,-112(s0)
     234:	f8040923          	sb	zero,-110(s0)
      read(bb[0], buf+0, 1);
     238:	4605                	li	a2,1
     23a:	f9040593          	addi	a1,s0,-112
     23e:	fa042503          	lw	a0,-96(s0)
     242:	00001097          	auipc	ra,0x1
     246:	c34080e7          	jalr	-972(ra) # e76 <read>
      read(bb[0], buf+1, 1);
     24a:	4605                	li	a2,1
     24c:	f9140593          	addi	a1,s0,-111
     250:	fa042503          	lw	a0,-96(s0)
     254:	00001097          	auipc	ra,0x1
     258:	c22080e7          	jalr	-990(ra) # e76 <read>
      close(bb[0]);
     25c:	fa042503          	lw	a0,-96(s0)
     260:	00001097          	auipc	ra,0x1
     264:	c26080e7          	jalr	-986(ra) # e86 <close>
      int st1, st2;
      wait(&st1);
     268:	f9440513          	addi	a0,s0,-108
     26c:	00001097          	auipc	ra,0x1
     270:	bfa080e7          	jalr	-1030(ra) # e66 <wait>
      wait(&st2);
     274:	fa840513          	addi	a0,s0,-88
     278:	00001097          	auipc	ra,0x1
     27c:	bee080e7          	jalr	-1042(ra) # e66 <wait>
      if(st1 != 0 || st2 != 0 || strcmp(buf, "hi") != 0){
     280:	f9442783          	lw	a5,-108(s0)
     284:	fa842703          	lw	a4,-88(s0)
     288:	8fd9                	or	a5,a5,a4
     28a:	2781                	sext.w	a5,a5
     28c:	ef89                	bnez	a5,2a6 <go+0x22e>
     28e:	00001597          	auipc	a1,0x1
     292:	3d258593          	addi	a1,a1,978 # 1660 <statistics+0x2d8>
     296:	f9040513          	addi	a0,s0,-112
     29a:	00001097          	auipc	ra,0x1
     29e:	96a080e7          	jalr	-1686(ra) # c04 <strcmp>
     2a2:	e6050fe3          	beqz	a0,120 <go+0xa8>
        printf("exec pipeline failed %d %d \"%s\"\n", st1, st2, buf);
     2a6:	f9040693          	addi	a3,s0,-112
     2aa:	fa842603          	lw	a2,-88(s0)
     2ae:	f9442583          	lw	a1,-108(s0)
     2b2:	00001517          	auipc	a0,0x1
     2b6:	3fe50513          	addi	a0,a0,1022 # 16b0 <statistics+0x328>
     2ba:	00001097          	auipc	ra,0x1
     2be:	f2c080e7          	jalr	-212(ra) # 11e6 <printf>
        exit(1);
     2c2:	4505                	li	a0,1
     2c4:	00001097          	auipc	ra,0x1
     2c8:	b9a080e7          	jalr	-1126(ra) # e5e <exit>
      close(open("grindir/../grindir/../b", O_CREATE|O_RDWR));
     2cc:	20200593          	li	a1,514
     2d0:	00001517          	auipc	a0,0x1
     2d4:	18850513          	addi	a0,a0,392 # 1458 <statistics+0xd0>
     2d8:	00001097          	auipc	ra,0x1
     2dc:	bc6080e7          	jalr	-1082(ra) # e9e <open>
     2e0:	00001097          	auipc	ra,0x1
     2e4:	ba6080e7          	jalr	-1114(ra) # e86 <close>
     2e8:	bd25                	j	120 <go+0xa8>
      unlink("grindir/../a");
     2ea:	00001517          	auipc	a0,0x1
     2ee:	15e50513          	addi	a0,a0,350 # 1448 <statistics+0xc0>
     2f2:	00001097          	auipc	ra,0x1
     2f6:	bbc080e7          	jalr	-1092(ra) # eae <unlink>
     2fa:	b51d                	j	120 <go+0xa8>
      if(chdir("grindir") != 0){
     2fc:	00001517          	auipc	a0,0x1
     300:	11450513          	addi	a0,a0,276 # 1410 <statistics+0x88>
     304:	00001097          	auipc	ra,0x1
     308:	bca080e7          	jalr	-1078(ra) # ece <chdir>
     30c:	e115                	bnez	a0,330 <go+0x2b8>
      unlink("../b");
     30e:	00001517          	auipc	a0,0x1
     312:	16250513          	addi	a0,a0,354 # 1470 <statistics+0xe8>
     316:	00001097          	auipc	ra,0x1
     31a:	b98080e7          	jalr	-1128(ra) # eae <unlink>
      chdir("/");
     31e:	00001517          	auipc	a0,0x1
     322:	11250513          	addi	a0,a0,274 # 1430 <statistics+0xa8>
     326:	00001097          	auipc	ra,0x1
     32a:	ba8080e7          	jalr	-1112(ra) # ece <chdir>
     32e:	bbcd                	j	120 <go+0xa8>
        printf("chdir grindir failed\n");
     330:	00001517          	auipc	a0,0x1
     334:	0e850513          	addi	a0,a0,232 # 1418 <statistics+0x90>
     338:	00001097          	auipc	ra,0x1
     33c:	eae080e7          	jalr	-338(ra) # 11e6 <printf>
        exit(1);
     340:	4505                	li	a0,1
     342:	00001097          	auipc	ra,0x1
     346:	b1c080e7          	jalr	-1252(ra) # e5e <exit>
      close(fd);
     34a:	854a                	mv	a0,s2
     34c:	00001097          	auipc	ra,0x1
     350:	b3a080e7          	jalr	-1222(ra) # e86 <close>
      fd = open("/grindir/../a", O_CREATE|O_RDWR);
     354:	20200593          	li	a1,514
     358:	00001517          	auipc	a0,0x1
     35c:	12050513          	addi	a0,a0,288 # 1478 <statistics+0xf0>
     360:	00001097          	auipc	ra,0x1
     364:	b3e080e7          	jalr	-1218(ra) # e9e <open>
     368:	892a                	mv	s2,a0
     36a:	bb5d                	j	120 <go+0xa8>
      close(fd);
     36c:	854a                	mv	a0,s2
     36e:	00001097          	auipc	ra,0x1
     372:	b18080e7          	jalr	-1256(ra) # e86 <close>
      fd = open("/./grindir/./../b", O_CREATE|O_RDWR);
     376:	20200593          	li	a1,514
     37a:	00001517          	auipc	a0,0x1
     37e:	10e50513          	addi	a0,a0,270 # 1488 <statistics+0x100>
     382:	00001097          	auipc	ra,0x1
     386:	b1c080e7          	jalr	-1252(ra) # e9e <open>
     38a:	892a                	mv	s2,a0
     38c:	bb51                	j	120 <go+0xa8>
      write(fd, buf, sizeof(buf));
     38e:	3e700613          	li	a2,999
     392:	00001597          	auipc	a1,0x1
     396:	39e58593          	addi	a1,a1,926 # 1730 <buf.1239>
     39a:	854a                	mv	a0,s2
     39c:	00001097          	auipc	ra,0x1
     3a0:	ae2080e7          	jalr	-1310(ra) # e7e <write>
     3a4:	bbb5                	j	120 <go+0xa8>
      read(fd, buf, sizeof(buf));
     3a6:	3e700613          	li	a2,999
     3aa:	00001597          	auipc	a1,0x1
     3ae:	38658593          	addi	a1,a1,902 # 1730 <buf.1239>
     3b2:	854a                	mv	a0,s2
     3b4:	00001097          	auipc	ra,0x1
     3b8:	ac2080e7          	jalr	-1342(ra) # e76 <read>
     3bc:	b395                	j	120 <go+0xa8>
      mkdir("grindir/../a");
     3be:	00001517          	auipc	a0,0x1
     3c2:	08a50513          	addi	a0,a0,138 # 1448 <statistics+0xc0>
     3c6:	00001097          	auipc	ra,0x1
     3ca:	b00080e7          	jalr	-1280(ra) # ec6 <mkdir>
      close(open("a/../a/./a", O_CREATE|O_RDWR));
     3ce:	20200593          	li	a1,514
     3d2:	00001517          	auipc	a0,0x1
     3d6:	0ce50513          	addi	a0,a0,206 # 14a0 <statistics+0x118>
     3da:	00001097          	auipc	ra,0x1
     3de:	ac4080e7          	jalr	-1340(ra) # e9e <open>
     3e2:	00001097          	auipc	ra,0x1
     3e6:	aa4080e7          	jalr	-1372(ra) # e86 <close>
      unlink("a/a");
     3ea:	00001517          	auipc	a0,0x1
     3ee:	0c650513          	addi	a0,a0,198 # 14b0 <statistics+0x128>
     3f2:	00001097          	auipc	ra,0x1
     3f6:	abc080e7          	jalr	-1348(ra) # eae <unlink>
     3fa:	b31d                	j	120 <go+0xa8>
      mkdir("/../b");
     3fc:	00001517          	auipc	a0,0x1
     400:	0bc50513          	addi	a0,a0,188 # 14b8 <statistics+0x130>
     404:	00001097          	auipc	ra,0x1
     408:	ac2080e7          	jalr	-1342(ra) # ec6 <mkdir>
      close(open("grindir/../b/b", O_CREATE|O_RDWR));
     40c:	20200593          	li	a1,514
     410:	00001517          	auipc	a0,0x1
     414:	0b050513          	addi	a0,a0,176 # 14c0 <statistics+0x138>
     418:	00001097          	auipc	ra,0x1
     41c:	a86080e7          	jalr	-1402(ra) # e9e <open>
     420:	00001097          	auipc	ra,0x1
     424:	a66080e7          	jalr	-1434(ra) # e86 <close>
      unlink("b/b");
     428:	00001517          	auipc	a0,0x1
     42c:	0a850513          	addi	a0,a0,168 # 14d0 <statistics+0x148>
     430:	00001097          	auipc	ra,0x1
     434:	a7e080e7          	jalr	-1410(ra) # eae <unlink>
     438:	b1e5                	j	120 <go+0xa8>
      unlink("b");
     43a:	00001517          	auipc	a0,0x1
     43e:	05e50513          	addi	a0,a0,94 # 1498 <statistics+0x110>
     442:	00001097          	auipc	ra,0x1
     446:	a6c080e7          	jalr	-1428(ra) # eae <unlink>
      link("../grindir/./../a", "../b");
     44a:	00001597          	auipc	a1,0x1
     44e:	02658593          	addi	a1,a1,38 # 1470 <statistics+0xe8>
     452:	00001517          	auipc	a0,0x1
     456:	08650513          	addi	a0,a0,134 # 14d8 <statistics+0x150>
     45a:	00001097          	auipc	ra,0x1
     45e:	a64080e7          	jalr	-1436(ra) # ebe <link>
     462:	b97d                	j	120 <go+0xa8>
      unlink("../grindir/../a");
     464:	00001517          	auipc	a0,0x1
     468:	08c50513          	addi	a0,a0,140 # 14f0 <statistics+0x168>
     46c:	00001097          	auipc	ra,0x1
     470:	a42080e7          	jalr	-1470(ra) # eae <unlink>
      link(".././b", "/grindir/../a");
     474:	00001597          	auipc	a1,0x1
     478:	00458593          	addi	a1,a1,4 # 1478 <statistics+0xf0>
     47c:	00001517          	auipc	a0,0x1
     480:	08450513          	addi	a0,a0,132 # 1500 <statistics+0x178>
     484:	00001097          	auipc	ra,0x1
     488:	a3a080e7          	jalr	-1478(ra) # ebe <link>
     48c:	b951                	j	120 <go+0xa8>
      int pid = fork();
     48e:	00001097          	auipc	ra,0x1
     492:	9c8080e7          	jalr	-1592(ra) # e56 <fork>
      if(pid == 0){
     496:	c909                	beqz	a0,4a8 <go+0x430>
      } else if(pid < 0){
     498:	00054c63          	bltz	a0,4b0 <go+0x438>
      wait(0);
     49c:	4501                	li	a0,0
     49e:	00001097          	auipc	ra,0x1
     4a2:	9c8080e7          	jalr	-1592(ra) # e66 <wait>
     4a6:	b9ad                	j	120 <go+0xa8>
        exit(0);
     4a8:	00001097          	auipc	ra,0x1
     4ac:	9b6080e7          	jalr	-1610(ra) # e5e <exit>
        printf("grind: fork failed\n");
     4b0:	00001517          	auipc	a0,0x1
     4b4:	05850513          	addi	a0,a0,88 # 1508 <statistics+0x180>
     4b8:	00001097          	auipc	ra,0x1
     4bc:	d2e080e7          	jalr	-722(ra) # 11e6 <printf>
        exit(1);
     4c0:	4505                	li	a0,1
     4c2:	00001097          	auipc	ra,0x1
     4c6:	99c080e7          	jalr	-1636(ra) # e5e <exit>
      int pid = fork();
     4ca:	00001097          	auipc	ra,0x1
     4ce:	98c080e7          	jalr	-1652(ra) # e56 <fork>
      if(pid == 0){
     4d2:	c909                	beqz	a0,4e4 <go+0x46c>
      } else if(pid < 0){
     4d4:	02054563          	bltz	a0,4fe <go+0x486>
      wait(0);
     4d8:	4501                	li	a0,0
     4da:	00001097          	auipc	ra,0x1
     4de:	98c080e7          	jalr	-1652(ra) # e66 <wait>
     4e2:	b93d                	j	120 <go+0xa8>
        fork();
     4e4:	00001097          	auipc	ra,0x1
     4e8:	972080e7          	jalr	-1678(ra) # e56 <fork>
        fork();
     4ec:	00001097          	auipc	ra,0x1
     4f0:	96a080e7          	jalr	-1686(ra) # e56 <fork>
        exit(0);
     4f4:	4501                	li	a0,0
     4f6:	00001097          	auipc	ra,0x1
     4fa:	968080e7          	jalr	-1688(ra) # e5e <exit>
        printf("grind: fork failed\n");
     4fe:	00001517          	auipc	a0,0x1
     502:	00a50513          	addi	a0,a0,10 # 1508 <statistics+0x180>
     506:	00001097          	auipc	ra,0x1
     50a:	ce0080e7          	jalr	-800(ra) # 11e6 <printf>
        exit(1);
     50e:	4505                	li	a0,1
     510:	00001097          	auipc	ra,0x1
     514:	94e080e7          	jalr	-1714(ra) # e5e <exit>
      sbrk(6011);
     518:	8556                	mv	a0,s5
     51a:	00001097          	auipc	ra,0x1
     51e:	9cc080e7          	jalr	-1588(ra) # ee6 <sbrk>
     522:	befd                	j	120 <go+0xa8>
      if(sbrk(0) > break0)
     524:	4501                	li	a0,0
     526:	00001097          	auipc	ra,0x1
     52a:	9c0080e7          	jalr	-1600(ra) # ee6 <sbrk>
     52e:	beaa79e3          	bgeu	s4,a0,120 <go+0xa8>
        sbrk(-(sbrk(0) - break0));
     532:	4501                	li	a0,0
     534:	00001097          	auipc	ra,0x1
     538:	9b2080e7          	jalr	-1614(ra) # ee6 <sbrk>
     53c:	40aa053b          	subw	a0,s4,a0
     540:	00001097          	auipc	ra,0x1
     544:	9a6080e7          	jalr	-1626(ra) # ee6 <sbrk>
     548:	bee1                	j	120 <go+0xa8>
      int pid = fork();
     54a:	00001097          	auipc	ra,0x1
     54e:	90c080e7          	jalr	-1780(ra) # e56 <fork>
     552:	8b2a                	mv	s6,a0
      if(pid == 0){
     554:	c51d                	beqz	a0,582 <go+0x50a>
      } else if(pid < 0){
     556:	04054963          	bltz	a0,5a8 <go+0x530>
      if(chdir("../grindir/..") != 0){
     55a:	00001517          	auipc	a0,0x1
     55e:	fc650513          	addi	a0,a0,-58 # 1520 <statistics+0x198>
     562:	00001097          	auipc	ra,0x1
     566:	96c080e7          	jalr	-1684(ra) # ece <chdir>
     56a:	ed21                	bnez	a0,5c2 <go+0x54a>
      kill(pid);
     56c:	855a                	mv	a0,s6
     56e:	00001097          	auipc	ra,0x1
     572:	920080e7          	jalr	-1760(ra) # e8e <kill>
      wait(0);
     576:	4501                	li	a0,0
     578:	00001097          	auipc	ra,0x1
     57c:	8ee080e7          	jalr	-1810(ra) # e66 <wait>
     580:	b645                	j	120 <go+0xa8>
        close(open("a", O_CREATE|O_RDWR));
     582:	20200593          	li	a1,514
     586:	00001517          	auipc	a0,0x1
     58a:	f6250513          	addi	a0,a0,-158 # 14e8 <statistics+0x160>
     58e:	00001097          	auipc	ra,0x1
     592:	910080e7          	jalr	-1776(ra) # e9e <open>
     596:	00001097          	auipc	ra,0x1
     59a:	8f0080e7          	jalr	-1808(ra) # e86 <close>
        exit(0);
     59e:	4501                	li	a0,0
     5a0:	00001097          	auipc	ra,0x1
     5a4:	8be080e7          	jalr	-1858(ra) # e5e <exit>
        printf("grind: fork failed\n");
     5a8:	00001517          	auipc	a0,0x1
     5ac:	f6050513          	addi	a0,a0,-160 # 1508 <statistics+0x180>
     5b0:	00001097          	auipc	ra,0x1
     5b4:	c36080e7          	jalr	-970(ra) # 11e6 <printf>
        exit(1);
     5b8:	4505                	li	a0,1
     5ba:	00001097          	auipc	ra,0x1
     5be:	8a4080e7          	jalr	-1884(ra) # e5e <exit>
        printf("chdir failed\n");
     5c2:	00001517          	auipc	a0,0x1
     5c6:	f6e50513          	addi	a0,a0,-146 # 1530 <statistics+0x1a8>
     5ca:	00001097          	auipc	ra,0x1
     5ce:	c1c080e7          	jalr	-996(ra) # 11e6 <printf>
        exit(1);
     5d2:	4505                	li	a0,1
     5d4:	00001097          	auipc	ra,0x1
     5d8:	88a080e7          	jalr	-1910(ra) # e5e <exit>
      int pid = fork();
     5dc:	00001097          	auipc	ra,0x1
     5e0:	87a080e7          	jalr	-1926(ra) # e56 <fork>
      if(pid == 0){
     5e4:	c909                	beqz	a0,5f6 <go+0x57e>
      } else if(pid < 0){
     5e6:	02054563          	bltz	a0,610 <go+0x598>
      wait(0);
     5ea:	4501                	li	a0,0
     5ec:	00001097          	auipc	ra,0x1
     5f0:	87a080e7          	jalr	-1926(ra) # e66 <wait>
     5f4:	b635                	j	120 <go+0xa8>
        kill(getpid());
     5f6:	00001097          	auipc	ra,0x1
     5fa:	8e8080e7          	jalr	-1816(ra) # ede <getpid>
     5fe:	00001097          	auipc	ra,0x1
     602:	890080e7          	jalr	-1904(ra) # e8e <kill>
        exit(0);
     606:	4501                	li	a0,0
     608:	00001097          	auipc	ra,0x1
     60c:	856080e7          	jalr	-1962(ra) # e5e <exit>
        printf("grind: fork failed\n");
     610:	00001517          	auipc	a0,0x1
     614:	ef850513          	addi	a0,a0,-264 # 1508 <statistics+0x180>
     618:	00001097          	auipc	ra,0x1
     61c:	bce080e7          	jalr	-1074(ra) # 11e6 <printf>
        exit(1);
     620:	4505                	li	a0,1
     622:	00001097          	auipc	ra,0x1
     626:	83c080e7          	jalr	-1988(ra) # e5e <exit>
      if(pipe(fds) < 0){
     62a:	fa840513          	addi	a0,s0,-88
     62e:	00001097          	auipc	ra,0x1
     632:	840080e7          	jalr	-1984(ra) # e6e <pipe>
     636:	02054b63          	bltz	a0,66c <go+0x5f4>
      int pid = fork();
     63a:	00001097          	auipc	ra,0x1
     63e:	81c080e7          	jalr	-2020(ra) # e56 <fork>
      if(pid == 0){
     642:	c131                	beqz	a0,686 <go+0x60e>
      } else if(pid < 0){
     644:	0a054a63          	bltz	a0,6f8 <go+0x680>
      close(fds[0]);
     648:	fa842503          	lw	a0,-88(s0)
     64c:	00001097          	auipc	ra,0x1
     650:	83a080e7          	jalr	-1990(ra) # e86 <close>
      close(fds[1]);
     654:	fac42503          	lw	a0,-84(s0)
     658:	00001097          	auipc	ra,0x1
     65c:	82e080e7          	jalr	-2002(ra) # e86 <close>
      wait(0);
     660:	4501                	li	a0,0
     662:	00001097          	auipc	ra,0x1
     666:	804080e7          	jalr	-2044(ra) # e66 <wait>
     66a:	bc5d                	j	120 <go+0xa8>
        printf("grind: pipe failed\n");
     66c:	00001517          	auipc	a0,0x1
     670:	ed450513          	addi	a0,a0,-300 # 1540 <statistics+0x1b8>
     674:	00001097          	auipc	ra,0x1
     678:	b72080e7          	jalr	-1166(ra) # 11e6 <printf>
        exit(1);
     67c:	4505                	li	a0,1
     67e:	00000097          	auipc	ra,0x0
     682:	7e0080e7          	jalr	2016(ra) # e5e <exit>
        fork();
     686:	00000097          	auipc	ra,0x0
     68a:	7d0080e7          	jalr	2000(ra) # e56 <fork>
        fork();
     68e:	00000097          	auipc	ra,0x0
     692:	7c8080e7          	jalr	1992(ra) # e56 <fork>
        if(write(fds[1], "x", 1) != 1)
     696:	4605                	li	a2,1
     698:	00001597          	auipc	a1,0x1
     69c:	ec058593          	addi	a1,a1,-320 # 1558 <statistics+0x1d0>
     6a0:	fac42503          	lw	a0,-84(s0)
     6a4:	00000097          	auipc	ra,0x0
     6a8:	7da080e7          	jalr	2010(ra) # e7e <write>
     6ac:	4785                	li	a5,1
     6ae:	02f51363          	bne	a0,a5,6d4 <go+0x65c>
        if(read(fds[0], &c, 1) != 1)
     6b2:	4605                	li	a2,1
     6b4:	fa040593          	addi	a1,s0,-96
     6b8:	fa842503          	lw	a0,-88(s0)
     6bc:	00000097          	auipc	ra,0x0
     6c0:	7ba080e7          	jalr	1978(ra) # e76 <read>
     6c4:	4785                	li	a5,1
     6c6:	02f51063          	bne	a0,a5,6e6 <go+0x66e>
        exit(0);
     6ca:	4501                	li	a0,0
     6cc:	00000097          	auipc	ra,0x0
     6d0:	792080e7          	jalr	1938(ra) # e5e <exit>
          printf("grind: pipe write failed\n");
     6d4:	00001517          	auipc	a0,0x1
     6d8:	e8c50513          	addi	a0,a0,-372 # 1560 <statistics+0x1d8>
     6dc:	00001097          	auipc	ra,0x1
     6e0:	b0a080e7          	jalr	-1270(ra) # 11e6 <printf>
     6e4:	b7f9                	j	6b2 <go+0x63a>
          printf("grind: pipe read failed\n");
     6e6:	00001517          	auipc	a0,0x1
     6ea:	e9a50513          	addi	a0,a0,-358 # 1580 <statistics+0x1f8>
     6ee:	00001097          	auipc	ra,0x1
     6f2:	af8080e7          	jalr	-1288(ra) # 11e6 <printf>
     6f6:	bfd1                	j	6ca <go+0x652>
        printf("grind: fork failed\n");
     6f8:	00001517          	auipc	a0,0x1
     6fc:	e1050513          	addi	a0,a0,-496 # 1508 <statistics+0x180>
     700:	00001097          	auipc	ra,0x1
     704:	ae6080e7          	jalr	-1306(ra) # 11e6 <printf>
        exit(1);
     708:	4505                	li	a0,1
     70a:	00000097          	auipc	ra,0x0
     70e:	754080e7          	jalr	1876(ra) # e5e <exit>
      int pid = fork();
     712:	00000097          	auipc	ra,0x0
     716:	744080e7          	jalr	1860(ra) # e56 <fork>
      if(pid == 0){
     71a:	c909                	beqz	a0,72c <go+0x6b4>
      } else if(pid < 0){
     71c:	06054f63          	bltz	a0,79a <go+0x722>
      wait(0);
     720:	4501                	li	a0,0
     722:	00000097          	auipc	ra,0x0
     726:	744080e7          	jalr	1860(ra) # e66 <wait>
     72a:	badd                	j	120 <go+0xa8>
        unlink("a");
     72c:	00001517          	auipc	a0,0x1
     730:	dbc50513          	addi	a0,a0,-580 # 14e8 <statistics+0x160>
     734:	00000097          	auipc	ra,0x0
     738:	77a080e7          	jalr	1914(ra) # eae <unlink>
        mkdir("a");
     73c:	00001517          	auipc	a0,0x1
     740:	dac50513          	addi	a0,a0,-596 # 14e8 <statistics+0x160>
     744:	00000097          	auipc	ra,0x0
     748:	782080e7          	jalr	1922(ra) # ec6 <mkdir>
        chdir("a");
     74c:	00001517          	auipc	a0,0x1
     750:	d9c50513          	addi	a0,a0,-612 # 14e8 <statistics+0x160>
     754:	00000097          	auipc	ra,0x0
     758:	77a080e7          	jalr	1914(ra) # ece <chdir>
        unlink("../a");
     75c:	00001517          	auipc	a0,0x1
     760:	cf450513          	addi	a0,a0,-780 # 1450 <statistics+0xc8>
     764:	00000097          	auipc	ra,0x0
     768:	74a080e7          	jalr	1866(ra) # eae <unlink>
        fd = open("x", O_CREATE|O_RDWR);
     76c:	20200593          	li	a1,514
     770:	00001517          	auipc	a0,0x1
     774:	de850513          	addi	a0,a0,-536 # 1558 <statistics+0x1d0>
     778:	00000097          	auipc	ra,0x0
     77c:	726080e7          	jalr	1830(ra) # e9e <open>
        unlink("x");
     780:	00001517          	auipc	a0,0x1
     784:	dd850513          	addi	a0,a0,-552 # 1558 <statistics+0x1d0>
     788:	00000097          	auipc	ra,0x0
     78c:	726080e7          	jalr	1830(ra) # eae <unlink>
        exit(0);
     790:	4501                	li	a0,0
     792:	00000097          	auipc	ra,0x0
     796:	6cc080e7          	jalr	1740(ra) # e5e <exit>
        printf("fork failed\n");
     79a:	00001517          	auipc	a0,0x1
     79e:	e0650513          	addi	a0,a0,-506 # 15a0 <statistics+0x218>
     7a2:	00001097          	auipc	ra,0x1
     7a6:	a44080e7          	jalr	-1468(ra) # 11e6 <printf>
        exit(1);
     7aa:	4505                	li	a0,1
     7ac:	00000097          	auipc	ra,0x0
     7b0:	6b2080e7          	jalr	1714(ra) # e5e <exit>
      unlink("c");
     7b4:	00001517          	auipc	a0,0x1
     7b8:	dfc50513          	addi	a0,a0,-516 # 15b0 <statistics+0x228>
     7bc:	00000097          	auipc	ra,0x0
     7c0:	6f2080e7          	jalr	1778(ra) # eae <unlink>
      int fd1 = open("c", O_CREATE|O_RDWR);
     7c4:	20200593          	li	a1,514
     7c8:	00001517          	auipc	a0,0x1
     7cc:	de850513          	addi	a0,a0,-536 # 15b0 <statistics+0x228>
     7d0:	00000097          	auipc	ra,0x0
     7d4:	6ce080e7          	jalr	1742(ra) # e9e <open>
     7d8:	8b2a                	mv	s6,a0
      if(fd1 < 0){
     7da:	04054f63          	bltz	a0,838 <go+0x7c0>
      if(write(fd1, "x", 1) != 1){
     7de:	4605                	li	a2,1
     7e0:	00001597          	auipc	a1,0x1
     7e4:	d7858593          	addi	a1,a1,-648 # 1558 <statistics+0x1d0>
     7e8:	00000097          	auipc	ra,0x0
     7ec:	696080e7          	jalr	1686(ra) # e7e <write>
     7f0:	4785                	li	a5,1
     7f2:	06f51063          	bne	a0,a5,852 <go+0x7da>
      if(fstat(fd1, &st) != 0){
     7f6:	fa840593          	addi	a1,s0,-88
     7fa:	855a                	mv	a0,s6
     7fc:	00000097          	auipc	ra,0x0
     800:	6ba080e7          	jalr	1722(ra) # eb6 <fstat>
     804:	e525                	bnez	a0,86c <go+0x7f4>
      if(st.size != 1){
     806:	fb843583          	ld	a1,-72(s0)
     80a:	4785                	li	a5,1
     80c:	06f59d63          	bne	a1,a5,886 <go+0x80e>
      if(st.ino > 200){
     810:	fac42583          	lw	a1,-84(s0)
     814:	0c800793          	li	a5,200
     818:	08b7e563          	bltu	a5,a1,8a2 <go+0x82a>
      close(fd1);
     81c:	855a                	mv	a0,s6
     81e:	00000097          	auipc	ra,0x0
     822:	668080e7          	jalr	1640(ra) # e86 <close>
      unlink("c");
     826:	00001517          	auipc	a0,0x1
     82a:	d8a50513          	addi	a0,a0,-630 # 15b0 <statistics+0x228>
     82e:	00000097          	auipc	ra,0x0
     832:	680080e7          	jalr	1664(ra) # eae <unlink>
     836:	b0ed                	j	120 <go+0xa8>
        printf("create c failed\n");
     838:	00001517          	auipc	a0,0x1
     83c:	d8050513          	addi	a0,a0,-640 # 15b8 <statistics+0x230>
     840:	00001097          	auipc	ra,0x1
     844:	9a6080e7          	jalr	-1626(ra) # 11e6 <printf>
        exit(1);
     848:	4505                	li	a0,1
     84a:	00000097          	auipc	ra,0x0
     84e:	614080e7          	jalr	1556(ra) # e5e <exit>
        printf("write c failed\n");
     852:	00001517          	auipc	a0,0x1
     856:	d7e50513          	addi	a0,a0,-642 # 15d0 <statistics+0x248>
     85a:	00001097          	auipc	ra,0x1
     85e:	98c080e7          	jalr	-1652(ra) # 11e6 <printf>
        exit(1);
     862:	4505                	li	a0,1
     864:	00000097          	auipc	ra,0x0
     868:	5fa080e7          	jalr	1530(ra) # e5e <exit>
        printf("fstat failed\n");
     86c:	00001517          	auipc	a0,0x1
     870:	d7450513          	addi	a0,a0,-652 # 15e0 <statistics+0x258>
     874:	00001097          	auipc	ra,0x1
     878:	972080e7          	jalr	-1678(ra) # 11e6 <printf>
        exit(1);
     87c:	4505                	li	a0,1
     87e:	00000097          	auipc	ra,0x0
     882:	5e0080e7          	jalr	1504(ra) # e5e <exit>
        printf("fstat reports wrong size %d\n", (int)st.size);
     886:	2581                	sext.w	a1,a1
     888:	00001517          	auipc	a0,0x1
     88c:	d6850513          	addi	a0,a0,-664 # 15f0 <statistics+0x268>
     890:	00001097          	auipc	ra,0x1
     894:	956080e7          	jalr	-1706(ra) # 11e6 <printf>
        exit(1);
     898:	4505                	li	a0,1
     89a:	00000097          	auipc	ra,0x0
     89e:	5c4080e7          	jalr	1476(ra) # e5e <exit>
        printf("fstat reports crazy i-number %d\n", st.ino);
     8a2:	00001517          	auipc	a0,0x1
     8a6:	d6e50513          	addi	a0,a0,-658 # 1610 <statistics+0x288>
     8aa:	00001097          	auipc	ra,0x1
     8ae:	93c080e7          	jalr	-1732(ra) # 11e6 <printf>
        exit(1);
     8b2:	4505                	li	a0,1
     8b4:	00000097          	auipc	ra,0x0
     8b8:	5aa080e7          	jalr	1450(ra) # e5e <exit>
        fprintf(2, "pipe failed\n");
     8bc:	00001597          	auipc	a1,0x1
     8c0:	d7c58593          	addi	a1,a1,-644 # 1638 <statistics+0x2b0>
     8c4:	4509                	li	a0,2
     8c6:	00001097          	auipc	ra,0x1
     8ca:	8f2080e7          	jalr	-1806(ra) # 11b8 <fprintf>
        exit(1);
     8ce:	4505                	li	a0,1
     8d0:	00000097          	auipc	ra,0x0
     8d4:	58e080e7          	jalr	1422(ra) # e5e <exit>
        fprintf(2, "pipe failed\n");
     8d8:	00001597          	auipc	a1,0x1
     8dc:	d6058593          	addi	a1,a1,-672 # 1638 <statistics+0x2b0>
     8e0:	4509                	li	a0,2
     8e2:	00001097          	auipc	ra,0x1
     8e6:	8d6080e7          	jalr	-1834(ra) # 11b8 <fprintf>
        exit(1);
     8ea:	4505                	li	a0,1
     8ec:	00000097          	auipc	ra,0x0
     8f0:	572080e7          	jalr	1394(ra) # e5e <exit>
        close(bb[0]);
     8f4:	fa042503          	lw	a0,-96(s0)
     8f8:	00000097          	auipc	ra,0x0
     8fc:	58e080e7          	jalr	1422(ra) # e86 <close>
        close(bb[1]);
     900:	fa442503          	lw	a0,-92(s0)
     904:	00000097          	auipc	ra,0x0
     908:	582080e7          	jalr	1410(ra) # e86 <close>
        close(aa[0]);
     90c:	f9842503          	lw	a0,-104(s0)
     910:	00000097          	auipc	ra,0x0
     914:	576080e7          	jalr	1398(ra) # e86 <close>
        close(1);
     918:	4505                	li	a0,1
     91a:	00000097          	auipc	ra,0x0
     91e:	56c080e7          	jalr	1388(ra) # e86 <close>
        if(dup(aa[1]) != 1){
     922:	f9c42503          	lw	a0,-100(s0)
     926:	00000097          	auipc	ra,0x0
     92a:	5b0080e7          	jalr	1456(ra) # ed6 <dup>
     92e:	4785                	li	a5,1
     930:	02f50063          	beq	a0,a5,950 <go+0x8d8>
          fprintf(2, "dup failed\n");
     934:	00001597          	auipc	a1,0x1
     938:	d1458593          	addi	a1,a1,-748 # 1648 <statistics+0x2c0>
     93c:	4509                	li	a0,2
     93e:	00001097          	auipc	ra,0x1
     942:	87a080e7          	jalr	-1926(ra) # 11b8 <fprintf>
          exit(1);
     946:	4505                	li	a0,1
     948:	00000097          	auipc	ra,0x0
     94c:	516080e7          	jalr	1302(ra) # e5e <exit>
        close(aa[1]);
     950:	f9c42503          	lw	a0,-100(s0)
     954:	00000097          	auipc	ra,0x0
     958:	532080e7          	jalr	1330(ra) # e86 <close>
        char *args[3] = { "echo", "hi", 0 };
     95c:	00001797          	auipc	a5,0x1
     960:	cfc78793          	addi	a5,a5,-772 # 1658 <statistics+0x2d0>
     964:	faf43423          	sd	a5,-88(s0)
     968:	00001797          	auipc	a5,0x1
     96c:	cf878793          	addi	a5,a5,-776 # 1660 <statistics+0x2d8>
     970:	faf43823          	sd	a5,-80(s0)
     974:	fa043c23          	sd	zero,-72(s0)
        exec("grindir/../echo", args);
     978:	fa840593          	addi	a1,s0,-88
     97c:	00001517          	auipc	a0,0x1
     980:	cec50513          	addi	a0,a0,-788 # 1668 <statistics+0x2e0>
     984:	00000097          	auipc	ra,0x0
     988:	512080e7          	jalr	1298(ra) # e96 <exec>
        fprintf(2, "echo: not found\n");
     98c:	00001597          	auipc	a1,0x1
     990:	cec58593          	addi	a1,a1,-788 # 1678 <statistics+0x2f0>
     994:	4509                	li	a0,2
     996:	00001097          	auipc	ra,0x1
     99a:	822080e7          	jalr	-2014(ra) # 11b8 <fprintf>
        exit(2);
     99e:	4509                	li	a0,2
     9a0:	00000097          	auipc	ra,0x0
     9a4:	4be080e7          	jalr	1214(ra) # e5e <exit>
        fprintf(2, "fork failed\n");
     9a8:	00001597          	auipc	a1,0x1
     9ac:	bf858593          	addi	a1,a1,-1032 # 15a0 <statistics+0x218>
     9b0:	4509                	li	a0,2
     9b2:	00001097          	auipc	ra,0x1
     9b6:	806080e7          	jalr	-2042(ra) # 11b8 <fprintf>
        exit(3);
     9ba:	450d                	li	a0,3
     9bc:	00000097          	auipc	ra,0x0
     9c0:	4a2080e7          	jalr	1186(ra) # e5e <exit>
        close(aa[1]);
     9c4:	f9c42503          	lw	a0,-100(s0)
     9c8:	00000097          	auipc	ra,0x0
     9cc:	4be080e7          	jalr	1214(ra) # e86 <close>
        close(bb[0]);
     9d0:	fa042503          	lw	a0,-96(s0)
     9d4:	00000097          	auipc	ra,0x0
     9d8:	4b2080e7          	jalr	1202(ra) # e86 <close>
        close(0);
     9dc:	4501                	li	a0,0
     9de:	00000097          	auipc	ra,0x0
     9e2:	4a8080e7          	jalr	1192(ra) # e86 <close>
        if(dup(aa[0]) != 0){
     9e6:	f9842503          	lw	a0,-104(s0)
     9ea:	00000097          	auipc	ra,0x0
     9ee:	4ec080e7          	jalr	1260(ra) # ed6 <dup>
     9f2:	cd19                	beqz	a0,a10 <go+0x998>
          fprintf(2, "dup failed\n");
     9f4:	00001597          	auipc	a1,0x1
     9f8:	c5458593          	addi	a1,a1,-940 # 1648 <statistics+0x2c0>
     9fc:	4509                	li	a0,2
     9fe:	00000097          	auipc	ra,0x0
     a02:	7ba080e7          	jalr	1978(ra) # 11b8 <fprintf>
          exit(4);
     a06:	4511                	li	a0,4
     a08:	00000097          	auipc	ra,0x0
     a0c:	456080e7          	jalr	1110(ra) # e5e <exit>
        close(aa[0]);
     a10:	f9842503          	lw	a0,-104(s0)
     a14:	00000097          	auipc	ra,0x0
     a18:	472080e7          	jalr	1138(ra) # e86 <close>
        close(1);
     a1c:	4505                	li	a0,1
     a1e:	00000097          	auipc	ra,0x0
     a22:	468080e7          	jalr	1128(ra) # e86 <close>
        if(dup(bb[1]) != 1){
     a26:	fa442503          	lw	a0,-92(s0)
     a2a:	00000097          	auipc	ra,0x0
     a2e:	4ac080e7          	jalr	1196(ra) # ed6 <dup>
     a32:	4785                	li	a5,1
     a34:	02f50063          	beq	a0,a5,a54 <go+0x9dc>
          fprintf(2, "dup failed\n");
     a38:	00001597          	auipc	a1,0x1
     a3c:	c1058593          	addi	a1,a1,-1008 # 1648 <statistics+0x2c0>
     a40:	4509                	li	a0,2
     a42:	00000097          	auipc	ra,0x0
     a46:	776080e7          	jalr	1910(ra) # 11b8 <fprintf>
          exit(5);
     a4a:	4515                	li	a0,5
     a4c:	00000097          	auipc	ra,0x0
     a50:	412080e7          	jalr	1042(ra) # e5e <exit>
        close(bb[1]);
     a54:	fa442503          	lw	a0,-92(s0)
     a58:	00000097          	auipc	ra,0x0
     a5c:	42e080e7          	jalr	1070(ra) # e86 <close>
        char *args[2] = { "cat", 0 };
     a60:	00001797          	auipc	a5,0x1
     a64:	c3078793          	addi	a5,a5,-976 # 1690 <statistics+0x308>
     a68:	faf43423          	sd	a5,-88(s0)
     a6c:	fa043823          	sd	zero,-80(s0)
        exec("/cat", args);
     a70:	fa840593          	addi	a1,s0,-88
     a74:	00001517          	auipc	a0,0x1
     a78:	c2450513          	addi	a0,a0,-988 # 1698 <statistics+0x310>
     a7c:	00000097          	auipc	ra,0x0
     a80:	41a080e7          	jalr	1050(ra) # e96 <exec>
        fprintf(2, "cat: not found\n");
     a84:	00001597          	auipc	a1,0x1
     a88:	c1c58593          	addi	a1,a1,-996 # 16a0 <statistics+0x318>
     a8c:	4509                	li	a0,2
     a8e:	00000097          	auipc	ra,0x0
     a92:	72a080e7          	jalr	1834(ra) # 11b8 <fprintf>
        exit(6);
     a96:	4519                	li	a0,6
     a98:	00000097          	auipc	ra,0x0
     a9c:	3c6080e7          	jalr	966(ra) # e5e <exit>
        fprintf(2, "fork failed\n");
     aa0:	00001597          	auipc	a1,0x1
     aa4:	b0058593          	addi	a1,a1,-1280 # 15a0 <statistics+0x218>
     aa8:	4509                	li	a0,2
     aaa:	00000097          	auipc	ra,0x0
     aae:	70e080e7          	jalr	1806(ra) # 11b8 <fprintf>
        exit(7);
     ab2:	451d                	li	a0,7
     ab4:	00000097          	auipc	ra,0x0
     ab8:	3aa080e7          	jalr	938(ra) # e5e <exit>

0000000000000abc <iter>:
  }
}

void
iter()
{
     abc:	7179                	addi	sp,sp,-48
     abe:	f406                	sd	ra,40(sp)
     ac0:	f022                	sd	s0,32(sp)
     ac2:	ec26                	sd	s1,24(sp)
     ac4:	e84a                	sd	s2,16(sp)
     ac6:	1800                	addi	s0,sp,48
  unlink("a");
     ac8:	00001517          	auipc	a0,0x1
     acc:	a2050513          	addi	a0,a0,-1504 # 14e8 <statistics+0x160>
     ad0:	00000097          	auipc	ra,0x0
     ad4:	3de080e7          	jalr	990(ra) # eae <unlink>
  unlink("b");
     ad8:	00001517          	auipc	a0,0x1
     adc:	9c050513          	addi	a0,a0,-1600 # 1498 <statistics+0x110>
     ae0:	00000097          	auipc	ra,0x0
     ae4:	3ce080e7          	jalr	974(ra) # eae <unlink>
  
  int pid1 = fork();
     ae8:	00000097          	auipc	ra,0x0
     aec:	36e080e7          	jalr	878(ra) # e56 <fork>
  if(pid1 < 0){
     af0:	00054e63          	bltz	a0,b0c <iter+0x50>
     af4:	84aa                	mv	s1,a0
    printf("grind: fork failed\n");
    exit(1);
  }
  if(pid1 == 0){
     af6:	e905                	bnez	a0,b26 <iter+0x6a>
    rand_next = 31;
     af8:	47fd                	li	a5,31
     afa:	00001717          	auipc	a4,0x1
     afe:	c2f73323          	sd	a5,-986(a4) # 1720 <rand_next>
    go(0);
     b02:	4501                	li	a0,0
     b04:	fffff097          	auipc	ra,0xfffff
     b08:	574080e7          	jalr	1396(ra) # 78 <go>
    printf("grind: fork failed\n");
     b0c:	00001517          	auipc	a0,0x1
     b10:	9fc50513          	addi	a0,a0,-1540 # 1508 <statistics+0x180>
     b14:	00000097          	auipc	ra,0x0
     b18:	6d2080e7          	jalr	1746(ra) # 11e6 <printf>
    exit(1);
     b1c:	4505                	li	a0,1
     b1e:	00000097          	auipc	ra,0x0
     b22:	340080e7          	jalr	832(ra) # e5e <exit>
    exit(0);
  }

  int pid2 = fork();
     b26:	00000097          	auipc	ra,0x0
     b2a:	330080e7          	jalr	816(ra) # e56 <fork>
     b2e:	892a                	mv	s2,a0
  if(pid2 < 0){
     b30:	00054f63          	bltz	a0,b4e <iter+0x92>
    printf("grind: fork failed\n");
    exit(1);
  }
  if(pid2 == 0){
     b34:	e915                	bnez	a0,b68 <iter+0xac>
    rand_next = 7177;
     b36:	6789                	lui	a5,0x2
     b38:	c0978793          	addi	a5,a5,-1015 # 1c09 <__BSS_END__+0xe1>
     b3c:	00001717          	auipc	a4,0x1
     b40:	bef73223          	sd	a5,-1052(a4) # 1720 <rand_next>
    go(1);
     b44:	4505                	li	a0,1
     b46:	fffff097          	auipc	ra,0xfffff
     b4a:	532080e7          	jalr	1330(ra) # 78 <go>
    printf("grind: fork failed\n");
     b4e:	00001517          	auipc	a0,0x1
     b52:	9ba50513          	addi	a0,a0,-1606 # 1508 <statistics+0x180>
     b56:	00000097          	auipc	ra,0x0
     b5a:	690080e7          	jalr	1680(ra) # 11e6 <printf>
    exit(1);
     b5e:	4505                	li	a0,1
     b60:	00000097          	auipc	ra,0x0
     b64:	2fe080e7          	jalr	766(ra) # e5e <exit>
    exit(0);
  }

  int st1 = -1;
     b68:	57fd                	li	a5,-1
     b6a:	fcf42e23          	sw	a5,-36(s0)
  wait(&st1);
     b6e:	fdc40513          	addi	a0,s0,-36
     b72:	00000097          	auipc	ra,0x0
     b76:	2f4080e7          	jalr	756(ra) # e66 <wait>
  if(st1 != 0){
     b7a:	fdc42783          	lw	a5,-36(s0)
     b7e:	ef99                	bnez	a5,b9c <iter+0xe0>
    kill(pid1);
    kill(pid2);
  }
  int st2 = -1;
     b80:	57fd                	li	a5,-1
     b82:	fcf42c23          	sw	a5,-40(s0)
  wait(&st2);
     b86:	fd840513          	addi	a0,s0,-40
     b8a:	00000097          	auipc	ra,0x0
     b8e:	2dc080e7          	jalr	732(ra) # e66 <wait>

  exit(0);
     b92:	4501                	li	a0,0
     b94:	00000097          	auipc	ra,0x0
     b98:	2ca080e7          	jalr	714(ra) # e5e <exit>
    kill(pid1);
     b9c:	8526                	mv	a0,s1
     b9e:	00000097          	auipc	ra,0x0
     ba2:	2f0080e7          	jalr	752(ra) # e8e <kill>
    kill(pid2);
     ba6:	854a                	mv	a0,s2
     ba8:	00000097          	auipc	ra,0x0
     bac:	2e6080e7          	jalr	742(ra) # e8e <kill>
     bb0:	bfc1                	j	b80 <iter+0xc4>

0000000000000bb2 <main>:
}

int
main()
{
     bb2:	1141                	addi	sp,sp,-16
     bb4:	e406                	sd	ra,8(sp)
     bb6:	e022                	sd	s0,0(sp)
     bb8:	0800                	addi	s0,sp,16
     bba:	a811                	j	bce <main+0x1c>
  while(1){
    int pid = fork();
    if(pid == 0){
      iter();
     bbc:	00000097          	auipc	ra,0x0
     bc0:	f00080e7          	jalr	-256(ra) # abc <iter>
      exit(0);
    }
    if(pid > 0){
      wait(0);
    }
    sleep(20);
     bc4:	4551                	li	a0,20
     bc6:	00000097          	auipc	ra,0x0
     bca:	328080e7          	jalr	808(ra) # eee <sleep>
    int pid = fork();
     bce:	00000097          	auipc	ra,0x0
     bd2:	288080e7          	jalr	648(ra) # e56 <fork>
    if(pid == 0){
     bd6:	d17d                	beqz	a0,bbc <main+0xa>
    if(pid > 0){
     bd8:	fea056e3          	blez	a0,bc4 <main+0x12>
      wait(0);
     bdc:	4501                	li	a0,0
     bde:	00000097          	auipc	ra,0x0
     be2:	288080e7          	jalr	648(ra) # e66 <wait>
     be6:	bff9                	j	bc4 <main+0x12>

0000000000000be8 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
     be8:	1141                	addi	sp,sp,-16
     bea:	e422                	sd	s0,8(sp)
     bec:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
     bee:	87aa                	mv	a5,a0
     bf0:	0585                	addi	a1,a1,1
     bf2:	0785                	addi	a5,a5,1
     bf4:	fff5c703          	lbu	a4,-1(a1)
     bf8:	fee78fa3          	sb	a4,-1(a5)
     bfc:	fb75                	bnez	a4,bf0 <strcpy+0x8>
    ;
  return os;
}
     bfe:	6422                	ld	s0,8(sp)
     c00:	0141                	addi	sp,sp,16
     c02:	8082                	ret

0000000000000c04 <strcmp>:

int
strcmp(const char *p, const char *q)
{
     c04:	1141                	addi	sp,sp,-16
     c06:	e422                	sd	s0,8(sp)
     c08:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
     c0a:	00054783          	lbu	a5,0(a0)
     c0e:	cb91                	beqz	a5,c22 <strcmp+0x1e>
     c10:	0005c703          	lbu	a4,0(a1)
     c14:	00f71763          	bne	a4,a5,c22 <strcmp+0x1e>
    p++, q++;
     c18:	0505                	addi	a0,a0,1
     c1a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
     c1c:	00054783          	lbu	a5,0(a0)
     c20:	fbe5                	bnez	a5,c10 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
     c22:	0005c503          	lbu	a0,0(a1)
}
     c26:	40a7853b          	subw	a0,a5,a0
     c2a:	6422                	ld	s0,8(sp)
     c2c:	0141                	addi	sp,sp,16
     c2e:	8082                	ret

0000000000000c30 <strlen>:

uint
strlen(const char *s)
{
     c30:	1141                	addi	sp,sp,-16
     c32:	e422                	sd	s0,8(sp)
     c34:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
     c36:	00054783          	lbu	a5,0(a0)
     c3a:	cf91                	beqz	a5,c56 <strlen+0x26>
     c3c:	0505                	addi	a0,a0,1
     c3e:	87aa                	mv	a5,a0
     c40:	4685                	li	a3,1
     c42:	9e89                	subw	a3,a3,a0
     c44:	00f6853b          	addw	a0,a3,a5
     c48:	0785                	addi	a5,a5,1
     c4a:	fff7c703          	lbu	a4,-1(a5)
     c4e:	fb7d                	bnez	a4,c44 <strlen+0x14>
    ;
  return n;
}
     c50:	6422                	ld	s0,8(sp)
     c52:	0141                	addi	sp,sp,16
     c54:	8082                	ret
  for(n = 0; s[n]; n++)
     c56:	4501                	li	a0,0
     c58:	bfe5                	j	c50 <strlen+0x20>

0000000000000c5a <memset>:

void*
memset(void *dst, int c, uint n)
{
     c5a:	1141                	addi	sp,sp,-16
     c5c:	e422                	sd	s0,8(sp)
     c5e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
     c60:	ce09                	beqz	a2,c7a <memset+0x20>
     c62:	87aa                	mv	a5,a0
     c64:	fff6071b          	addiw	a4,a2,-1
     c68:	1702                	slli	a4,a4,0x20
     c6a:	9301                	srli	a4,a4,0x20
     c6c:	0705                	addi	a4,a4,1
     c6e:	972a                	add	a4,a4,a0
    cdst[i] = c;
     c70:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
     c74:	0785                	addi	a5,a5,1
     c76:	fee79de3          	bne	a5,a4,c70 <memset+0x16>
  }
  return dst;
}
     c7a:	6422                	ld	s0,8(sp)
     c7c:	0141                	addi	sp,sp,16
     c7e:	8082                	ret

0000000000000c80 <strchr>:

char*
strchr(const char *s, char c)
{
     c80:	1141                	addi	sp,sp,-16
     c82:	e422                	sd	s0,8(sp)
     c84:	0800                	addi	s0,sp,16
  for(; *s; s++)
     c86:	00054783          	lbu	a5,0(a0)
     c8a:	cb99                	beqz	a5,ca0 <strchr+0x20>
    if(*s == c)
     c8c:	00f58763          	beq	a1,a5,c9a <strchr+0x1a>
  for(; *s; s++)
     c90:	0505                	addi	a0,a0,1
     c92:	00054783          	lbu	a5,0(a0)
     c96:	fbfd                	bnez	a5,c8c <strchr+0xc>
      return (char*)s;
  return 0;
     c98:	4501                	li	a0,0
}
     c9a:	6422                	ld	s0,8(sp)
     c9c:	0141                	addi	sp,sp,16
     c9e:	8082                	ret
  return 0;
     ca0:	4501                	li	a0,0
     ca2:	bfe5                	j	c9a <strchr+0x1a>

0000000000000ca4 <gets>:

char*
gets(char *buf, int max)
{
     ca4:	711d                	addi	sp,sp,-96
     ca6:	ec86                	sd	ra,88(sp)
     ca8:	e8a2                	sd	s0,80(sp)
     caa:	e4a6                	sd	s1,72(sp)
     cac:	e0ca                	sd	s2,64(sp)
     cae:	fc4e                	sd	s3,56(sp)
     cb0:	f852                	sd	s4,48(sp)
     cb2:	f456                	sd	s5,40(sp)
     cb4:	f05a                	sd	s6,32(sp)
     cb6:	ec5e                	sd	s7,24(sp)
     cb8:	1080                	addi	s0,sp,96
     cba:	8baa                	mv	s7,a0
     cbc:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
     cbe:	892a                	mv	s2,a0
     cc0:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
     cc2:	4aa9                	li	s5,10
     cc4:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
     cc6:	89a6                	mv	s3,s1
     cc8:	2485                	addiw	s1,s1,1
     cca:	0344d863          	bge	s1,s4,cfa <gets+0x56>
    cc = read(0, &c, 1);
     cce:	4605                	li	a2,1
     cd0:	faf40593          	addi	a1,s0,-81
     cd4:	4501                	li	a0,0
     cd6:	00000097          	auipc	ra,0x0
     cda:	1a0080e7          	jalr	416(ra) # e76 <read>
    if(cc < 1)
     cde:	00a05e63          	blez	a0,cfa <gets+0x56>
    buf[i++] = c;
     ce2:	faf44783          	lbu	a5,-81(s0)
     ce6:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
     cea:	01578763          	beq	a5,s5,cf8 <gets+0x54>
     cee:	0905                	addi	s2,s2,1
     cf0:	fd679be3          	bne	a5,s6,cc6 <gets+0x22>
  for(i=0; i+1 < max; ){
     cf4:	89a6                	mv	s3,s1
     cf6:	a011                	j	cfa <gets+0x56>
     cf8:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
     cfa:	99de                	add	s3,s3,s7
     cfc:	00098023          	sb	zero,0(s3)
  return buf;
}
     d00:	855e                	mv	a0,s7
     d02:	60e6                	ld	ra,88(sp)
     d04:	6446                	ld	s0,80(sp)
     d06:	64a6                	ld	s1,72(sp)
     d08:	6906                	ld	s2,64(sp)
     d0a:	79e2                	ld	s3,56(sp)
     d0c:	7a42                	ld	s4,48(sp)
     d0e:	7aa2                	ld	s5,40(sp)
     d10:	7b02                	ld	s6,32(sp)
     d12:	6be2                	ld	s7,24(sp)
     d14:	6125                	addi	sp,sp,96
     d16:	8082                	ret

0000000000000d18 <stat>:

int
stat(const char *n, struct stat *st)
{
     d18:	1101                	addi	sp,sp,-32
     d1a:	ec06                	sd	ra,24(sp)
     d1c:	e822                	sd	s0,16(sp)
     d1e:	e426                	sd	s1,8(sp)
     d20:	e04a                	sd	s2,0(sp)
     d22:	1000                	addi	s0,sp,32
     d24:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
     d26:	4581                	li	a1,0
     d28:	00000097          	auipc	ra,0x0
     d2c:	176080e7          	jalr	374(ra) # e9e <open>
  if(fd < 0)
     d30:	02054563          	bltz	a0,d5a <stat+0x42>
     d34:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
     d36:	85ca                	mv	a1,s2
     d38:	00000097          	auipc	ra,0x0
     d3c:	17e080e7          	jalr	382(ra) # eb6 <fstat>
     d40:	892a                	mv	s2,a0
  close(fd);
     d42:	8526                	mv	a0,s1
     d44:	00000097          	auipc	ra,0x0
     d48:	142080e7          	jalr	322(ra) # e86 <close>
  return r;
}
     d4c:	854a                	mv	a0,s2
     d4e:	60e2                	ld	ra,24(sp)
     d50:	6442                	ld	s0,16(sp)
     d52:	64a2                	ld	s1,8(sp)
     d54:	6902                	ld	s2,0(sp)
     d56:	6105                	addi	sp,sp,32
     d58:	8082                	ret
    return -1;
     d5a:	597d                	li	s2,-1
     d5c:	bfc5                	j	d4c <stat+0x34>

0000000000000d5e <atoi>:

int
atoi(const char *s)
{
     d5e:	1141                	addi	sp,sp,-16
     d60:	e422                	sd	s0,8(sp)
     d62:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
     d64:	00054603          	lbu	a2,0(a0)
     d68:	fd06079b          	addiw	a5,a2,-48
     d6c:	0ff7f793          	andi	a5,a5,255
     d70:	4725                	li	a4,9
     d72:	02f76963          	bltu	a4,a5,da4 <atoi+0x46>
     d76:	86aa                	mv	a3,a0
  n = 0;
     d78:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
     d7a:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
     d7c:	0685                	addi	a3,a3,1
     d7e:	0025179b          	slliw	a5,a0,0x2
     d82:	9fa9                	addw	a5,a5,a0
     d84:	0017979b          	slliw	a5,a5,0x1
     d88:	9fb1                	addw	a5,a5,a2
     d8a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
     d8e:	0006c603          	lbu	a2,0(a3)
     d92:	fd06071b          	addiw	a4,a2,-48
     d96:	0ff77713          	andi	a4,a4,255
     d9a:	fee5f1e3          	bgeu	a1,a4,d7c <atoi+0x1e>
  return n;
}
     d9e:	6422                	ld	s0,8(sp)
     da0:	0141                	addi	sp,sp,16
     da2:	8082                	ret
  n = 0;
     da4:	4501                	li	a0,0
     da6:	bfe5                	j	d9e <atoi+0x40>

0000000000000da8 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
     da8:	1141                	addi	sp,sp,-16
     daa:	e422                	sd	s0,8(sp)
     dac:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
     dae:	02b57663          	bgeu	a0,a1,dda <memmove+0x32>
    while(n-- > 0)
     db2:	02c05163          	blez	a2,dd4 <memmove+0x2c>
     db6:	fff6079b          	addiw	a5,a2,-1
     dba:	1782                	slli	a5,a5,0x20
     dbc:	9381                	srli	a5,a5,0x20
     dbe:	0785                	addi	a5,a5,1
     dc0:	97aa                	add	a5,a5,a0
  dst = vdst;
     dc2:	872a                	mv	a4,a0
      *dst++ = *src++;
     dc4:	0585                	addi	a1,a1,1
     dc6:	0705                	addi	a4,a4,1
     dc8:	fff5c683          	lbu	a3,-1(a1)
     dcc:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
     dd0:	fee79ae3          	bne	a5,a4,dc4 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
     dd4:	6422                	ld	s0,8(sp)
     dd6:	0141                	addi	sp,sp,16
     dd8:	8082                	ret
    dst += n;
     dda:	00c50733          	add	a4,a0,a2
    src += n;
     dde:	95b2                	add	a1,a1,a2
    while(n-- > 0)
     de0:	fec05ae3          	blez	a2,dd4 <memmove+0x2c>
     de4:	fff6079b          	addiw	a5,a2,-1
     de8:	1782                	slli	a5,a5,0x20
     dea:	9381                	srli	a5,a5,0x20
     dec:	fff7c793          	not	a5,a5
     df0:	97ba                	add	a5,a5,a4
      *--dst = *--src;
     df2:	15fd                	addi	a1,a1,-1
     df4:	177d                	addi	a4,a4,-1
     df6:	0005c683          	lbu	a3,0(a1)
     dfa:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
     dfe:	fee79ae3          	bne	a5,a4,df2 <memmove+0x4a>
     e02:	bfc9                	j	dd4 <memmove+0x2c>

0000000000000e04 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
     e04:	1141                	addi	sp,sp,-16
     e06:	e422                	sd	s0,8(sp)
     e08:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
     e0a:	ca05                	beqz	a2,e3a <memcmp+0x36>
     e0c:	fff6069b          	addiw	a3,a2,-1
     e10:	1682                	slli	a3,a3,0x20
     e12:	9281                	srli	a3,a3,0x20
     e14:	0685                	addi	a3,a3,1
     e16:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
     e18:	00054783          	lbu	a5,0(a0)
     e1c:	0005c703          	lbu	a4,0(a1)
     e20:	00e79863          	bne	a5,a4,e30 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
     e24:	0505                	addi	a0,a0,1
    p2++;
     e26:	0585                	addi	a1,a1,1
  while (n-- > 0) {
     e28:	fed518e3          	bne	a0,a3,e18 <memcmp+0x14>
  }
  return 0;
     e2c:	4501                	li	a0,0
     e2e:	a019                	j	e34 <memcmp+0x30>
      return *p1 - *p2;
     e30:	40e7853b          	subw	a0,a5,a4
}
     e34:	6422                	ld	s0,8(sp)
     e36:	0141                	addi	sp,sp,16
     e38:	8082                	ret
  return 0;
     e3a:	4501                	li	a0,0
     e3c:	bfe5                	j	e34 <memcmp+0x30>

0000000000000e3e <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
     e3e:	1141                	addi	sp,sp,-16
     e40:	e406                	sd	ra,8(sp)
     e42:	e022                	sd	s0,0(sp)
     e44:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
     e46:	00000097          	auipc	ra,0x0
     e4a:	f62080e7          	jalr	-158(ra) # da8 <memmove>
}
     e4e:	60a2                	ld	ra,8(sp)
     e50:	6402                	ld	s0,0(sp)
     e52:	0141                	addi	sp,sp,16
     e54:	8082                	ret

0000000000000e56 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
     e56:	4885                	li	a7,1
 ecall
     e58:	00000073          	ecall
 ret
     e5c:	8082                	ret

0000000000000e5e <exit>:
.global exit
exit:
 li a7, SYS_exit
     e5e:	4889                	li	a7,2
 ecall
     e60:	00000073          	ecall
 ret
     e64:	8082                	ret

0000000000000e66 <wait>:
.global wait
wait:
 li a7, SYS_wait
     e66:	488d                	li	a7,3
 ecall
     e68:	00000073          	ecall
 ret
     e6c:	8082                	ret

0000000000000e6e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
     e6e:	4891                	li	a7,4
 ecall
     e70:	00000073          	ecall
 ret
     e74:	8082                	ret

0000000000000e76 <read>:
.global read
read:
 li a7, SYS_read
     e76:	4895                	li	a7,5
 ecall
     e78:	00000073          	ecall
 ret
     e7c:	8082                	ret

0000000000000e7e <write>:
.global write
write:
 li a7, SYS_write
     e7e:	48c1                	li	a7,16
 ecall
     e80:	00000073          	ecall
 ret
     e84:	8082                	ret

0000000000000e86 <close>:
.global close
close:
 li a7, SYS_close
     e86:	48d5                	li	a7,21
 ecall
     e88:	00000073          	ecall
 ret
     e8c:	8082                	ret

0000000000000e8e <kill>:
.global kill
kill:
 li a7, SYS_kill
     e8e:	4899                	li	a7,6
 ecall
     e90:	00000073          	ecall
 ret
     e94:	8082                	ret

0000000000000e96 <exec>:
.global exec
exec:
 li a7, SYS_exec
     e96:	489d                	li	a7,7
 ecall
     e98:	00000073          	ecall
 ret
     e9c:	8082                	ret

0000000000000e9e <open>:
.global open
open:
 li a7, SYS_open
     e9e:	48bd                	li	a7,15
 ecall
     ea0:	00000073          	ecall
 ret
     ea4:	8082                	ret

0000000000000ea6 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
     ea6:	48c5                	li	a7,17
 ecall
     ea8:	00000073          	ecall
 ret
     eac:	8082                	ret

0000000000000eae <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
     eae:	48c9                	li	a7,18
 ecall
     eb0:	00000073          	ecall
 ret
     eb4:	8082                	ret

0000000000000eb6 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
     eb6:	48a1                	li	a7,8
 ecall
     eb8:	00000073          	ecall
 ret
     ebc:	8082                	ret

0000000000000ebe <link>:
.global link
link:
 li a7, SYS_link
     ebe:	48cd                	li	a7,19
 ecall
     ec0:	00000073          	ecall
 ret
     ec4:	8082                	ret

0000000000000ec6 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
     ec6:	48d1                	li	a7,20
 ecall
     ec8:	00000073          	ecall
 ret
     ecc:	8082                	ret

0000000000000ece <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
     ece:	48a5                	li	a7,9
 ecall
     ed0:	00000073          	ecall
 ret
     ed4:	8082                	ret

0000000000000ed6 <dup>:
.global dup
dup:
 li a7, SYS_dup
     ed6:	48a9                	li	a7,10
 ecall
     ed8:	00000073          	ecall
 ret
     edc:	8082                	ret

0000000000000ede <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
     ede:	48ad                	li	a7,11
 ecall
     ee0:	00000073          	ecall
 ret
     ee4:	8082                	ret

0000000000000ee6 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
     ee6:	48b1                	li	a7,12
 ecall
     ee8:	00000073          	ecall
 ret
     eec:	8082                	ret

0000000000000eee <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
     eee:	48b5                	li	a7,13
 ecall
     ef0:	00000073          	ecall
 ret
     ef4:	8082                	ret

0000000000000ef6 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
     ef6:	48b9                	li	a7,14
 ecall
     ef8:	00000073          	ecall
 ret
     efc:	8082                	ret

0000000000000efe <trace>:
.global trace
trace:
 li a7, SYS_trace
     efe:	48d9                	li	a7,22
 ecall
     f00:	00000073          	ecall
 ret
     f04:	8082                	ret

0000000000000f06 <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
     f06:	48dd                	li	a7,23
 ecall
     f08:	00000073          	ecall
 ret
     f0c:	8082                	ret

0000000000000f0e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
     f0e:	1101                	addi	sp,sp,-32
     f10:	ec06                	sd	ra,24(sp)
     f12:	e822                	sd	s0,16(sp)
     f14:	1000                	addi	s0,sp,32
     f16:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
     f1a:	4605                	li	a2,1
     f1c:	fef40593          	addi	a1,s0,-17
     f20:	00000097          	auipc	ra,0x0
     f24:	f5e080e7          	jalr	-162(ra) # e7e <write>
}
     f28:	60e2                	ld	ra,24(sp)
     f2a:	6442                	ld	s0,16(sp)
     f2c:	6105                	addi	sp,sp,32
     f2e:	8082                	ret

0000000000000f30 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
     f30:	7139                	addi	sp,sp,-64
     f32:	fc06                	sd	ra,56(sp)
     f34:	f822                	sd	s0,48(sp)
     f36:	f426                	sd	s1,40(sp)
     f38:	f04a                	sd	s2,32(sp)
     f3a:	ec4e                	sd	s3,24(sp)
     f3c:	0080                	addi	s0,sp,64
     f3e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
     f40:	c299                	beqz	a3,f46 <printint+0x16>
     f42:	0805c863          	bltz	a1,fd2 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
     f46:	2581                	sext.w	a1,a1
  neg = 0;
     f48:	4881                	li	a7,0
     f4a:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
     f4e:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
     f50:	2601                	sext.w	a2,a2
     f52:	00000517          	auipc	a0,0x0
     f56:	78e50513          	addi	a0,a0,1934 # 16e0 <digits>
     f5a:	883a                	mv	a6,a4
     f5c:	2705                	addiw	a4,a4,1
     f5e:	02c5f7bb          	remuw	a5,a1,a2
     f62:	1782                	slli	a5,a5,0x20
     f64:	9381                	srli	a5,a5,0x20
     f66:	97aa                	add	a5,a5,a0
     f68:	0007c783          	lbu	a5,0(a5)
     f6c:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
     f70:	0005879b          	sext.w	a5,a1
     f74:	02c5d5bb          	divuw	a1,a1,a2
     f78:	0685                	addi	a3,a3,1
     f7a:	fec7f0e3          	bgeu	a5,a2,f5a <printint+0x2a>
  if(neg)
     f7e:	00088b63          	beqz	a7,f94 <printint+0x64>
    buf[i++] = '-';
     f82:	fd040793          	addi	a5,s0,-48
     f86:	973e                	add	a4,a4,a5
     f88:	02d00793          	li	a5,45
     f8c:	fef70823          	sb	a5,-16(a4)
     f90:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
     f94:	02e05863          	blez	a4,fc4 <printint+0x94>
     f98:	fc040793          	addi	a5,s0,-64
     f9c:	00e78933          	add	s2,a5,a4
     fa0:	fff78993          	addi	s3,a5,-1
     fa4:	99ba                	add	s3,s3,a4
     fa6:	377d                	addiw	a4,a4,-1
     fa8:	1702                	slli	a4,a4,0x20
     faa:	9301                	srli	a4,a4,0x20
     fac:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
     fb0:	fff94583          	lbu	a1,-1(s2)
     fb4:	8526                	mv	a0,s1
     fb6:	00000097          	auipc	ra,0x0
     fba:	f58080e7          	jalr	-168(ra) # f0e <putc>
  while(--i >= 0)
     fbe:	197d                	addi	s2,s2,-1
     fc0:	ff3918e3          	bne	s2,s3,fb0 <printint+0x80>
}
     fc4:	70e2                	ld	ra,56(sp)
     fc6:	7442                	ld	s0,48(sp)
     fc8:	74a2                	ld	s1,40(sp)
     fca:	7902                	ld	s2,32(sp)
     fcc:	69e2                	ld	s3,24(sp)
     fce:	6121                	addi	sp,sp,64
     fd0:	8082                	ret
    x = -xx;
     fd2:	40b005bb          	negw	a1,a1
    neg = 1;
     fd6:	4885                	li	a7,1
    x = -xx;
     fd8:	bf8d                	j	f4a <printint+0x1a>

0000000000000fda <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
     fda:	7119                	addi	sp,sp,-128
     fdc:	fc86                	sd	ra,120(sp)
     fde:	f8a2                	sd	s0,112(sp)
     fe0:	f4a6                	sd	s1,104(sp)
     fe2:	f0ca                	sd	s2,96(sp)
     fe4:	ecce                	sd	s3,88(sp)
     fe6:	e8d2                	sd	s4,80(sp)
     fe8:	e4d6                	sd	s5,72(sp)
     fea:	e0da                	sd	s6,64(sp)
     fec:	fc5e                	sd	s7,56(sp)
     fee:	f862                	sd	s8,48(sp)
     ff0:	f466                	sd	s9,40(sp)
     ff2:	f06a                	sd	s10,32(sp)
     ff4:	ec6e                	sd	s11,24(sp)
     ff6:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
     ff8:	0005c903          	lbu	s2,0(a1)
     ffc:	18090f63          	beqz	s2,119a <vprintf+0x1c0>
    1000:	8aaa                	mv	s5,a0
    1002:	8b32                	mv	s6,a2
    1004:	00158493          	addi	s1,a1,1
  state = 0;
    1008:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
    100a:	02500a13          	li	s4,37
      if(c == 'd'){
    100e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
    1012:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
    1016:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
    101a:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    101e:	00000b97          	auipc	s7,0x0
    1022:	6c2b8b93          	addi	s7,s7,1730 # 16e0 <digits>
    1026:	a839                	j	1044 <vprintf+0x6a>
        putc(fd, c);
    1028:	85ca                	mv	a1,s2
    102a:	8556                	mv	a0,s5
    102c:	00000097          	auipc	ra,0x0
    1030:	ee2080e7          	jalr	-286(ra) # f0e <putc>
    1034:	a019                	j	103a <vprintf+0x60>
    } else if(state == '%'){
    1036:	01498f63          	beq	s3,s4,1054 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
    103a:	0485                	addi	s1,s1,1
    103c:	fff4c903          	lbu	s2,-1(s1)
    1040:	14090d63          	beqz	s2,119a <vprintf+0x1c0>
    c = fmt[i] & 0xff;
    1044:	0009079b          	sext.w	a5,s2
    if(state == 0){
    1048:	fe0997e3          	bnez	s3,1036 <vprintf+0x5c>
      if(c == '%'){
    104c:	fd479ee3          	bne	a5,s4,1028 <vprintf+0x4e>
        state = '%';
    1050:	89be                	mv	s3,a5
    1052:	b7e5                	j	103a <vprintf+0x60>
      if(c == 'd'){
    1054:	05878063          	beq	a5,s8,1094 <vprintf+0xba>
      } else if(c == 'l') {
    1058:	05978c63          	beq	a5,s9,10b0 <vprintf+0xd6>
      } else if(c == 'x') {
    105c:	07a78863          	beq	a5,s10,10cc <vprintf+0xf2>
      } else if(c == 'p') {
    1060:	09b78463          	beq	a5,s11,10e8 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
    1064:	07300713          	li	a4,115
    1068:	0ce78663          	beq	a5,a4,1134 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
    106c:	06300713          	li	a4,99
    1070:	0ee78e63          	beq	a5,a4,116c <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
    1074:	11478863          	beq	a5,s4,1184 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
    1078:	85d2                	mv	a1,s4
    107a:	8556                	mv	a0,s5
    107c:	00000097          	auipc	ra,0x0
    1080:	e92080e7          	jalr	-366(ra) # f0e <putc>
        putc(fd, c);
    1084:	85ca                	mv	a1,s2
    1086:	8556                	mv	a0,s5
    1088:	00000097          	auipc	ra,0x0
    108c:	e86080e7          	jalr	-378(ra) # f0e <putc>
      }
      state = 0;
    1090:	4981                	li	s3,0
    1092:	b765                	j	103a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
    1094:	008b0913          	addi	s2,s6,8
    1098:	4685                	li	a3,1
    109a:	4629                	li	a2,10
    109c:	000b2583          	lw	a1,0(s6)
    10a0:	8556                	mv	a0,s5
    10a2:	00000097          	auipc	ra,0x0
    10a6:	e8e080e7          	jalr	-370(ra) # f30 <printint>
    10aa:	8b4a                	mv	s6,s2
      state = 0;
    10ac:	4981                	li	s3,0
    10ae:	b771                	j	103a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
    10b0:	008b0913          	addi	s2,s6,8
    10b4:	4681                	li	a3,0
    10b6:	4629                	li	a2,10
    10b8:	000b2583          	lw	a1,0(s6)
    10bc:	8556                	mv	a0,s5
    10be:	00000097          	auipc	ra,0x0
    10c2:	e72080e7          	jalr	-398(ra) # f30 <printint>
    10c6:	8b4a                	mv	s6,s2
      state = 0;
    10c8:	4981                	li	s3,0
    10ca:	bf85                	j	103a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
    10cc:	008b0913          	addi	s2,s6,8
    10d0:	4681                	li	a3,0
    10d2:	4641                	li	a2,16
    10d4:	000b2583          	lw	a1,0(s6)
    10d8:	8556                	mv	a0,s5
    10da:	00000097          	auipc	ra,0x0
    10de:	e56080e7          	jalr	-426(ra) # f30 <printint>
    10e2:	8b4a                	mv	s6,s2
      state = 0;
    10e4:	4981                	li	s3,0
    10e6:	bf91                	j	103a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
    10e8:	008b0793          	addi	a5,s6,8
    10ec:	f8f43423          	sd	a5,-120(s0)
    10f0:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
    10f4:	03000593          	li	a1,48
    10f8:	8556                	mv	a0,s5
    10fa:	00000097          	auipc	ra,0x0
    10fe:	e14080e7          	jalr	-492(ra) # f0e <putc>
  putc(fd, 'x');
    1102:	85ea                	mv	a1,s10
    1104:	8556                	mv	a0,s5
    1106:	00000097          	auipc	ra,0x0
    110a:	e08080e7          	jalr	-504(ra) # f0e <putc>
    110e:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    1110:	03c9d793          	srli	a5,s3,0x3c
    1114:	97de                	add	a5,a5,s7
    1116:	0007c583          	lbu	a1,0(a5)
    111a:	8556                	mv	a0,s5
    111c:	00000097          	auipc	ra,0x0
    1120:	df2080e7          	jalr	-526(ra) # f0e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    1124:	0992                	slli	s3,s3,0x4
    1126:	397d                	addiw	s2,s2,-1
    1128:	fe0914e3          	bnez	s2,1110 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
    112c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
    1130:	4981                	li	s3,0
    1132:	b721                	j	103a <vprintf+0x60>
        s = va_arg(ap, char*);
    1134:	008b0993          	addi	s3,s6,8
    1138:	000b3903          	ld	s2,0(s6)
        if(s == 0)
    113c:	02090163          	beqz	s2,115e <vprintf+0x184>
        while(*s != 0){
    1140:	00094583          	lbu	a1,0(s2)
    1144:	c9a1                	beqz	a1,1194 <vprintf+0x1ba>
          putc(fd, *s);
    1146:	8556                	mv	a0,s5
    1148:	00000097          	auipc	ra,0x0
    114c:	dc6080e7          	jalr	-570(ra) # f0e <putc>
          s++;
    1150:	0905                	addi	s2,s2,1
        while(*s != 0){
    1152:	00094583          	lbu	a1,0(s2)
    1156:	f9e5                	bnez	a1,1146 <vprintf+0x16c>
        s = va_arg(ap, char*);
    1158:	8b4e                	mv	s6,s3
      state = 0;
    115a:	4981                	li	s3,0
    115c:	bdf9                	j	103a <vprintf+0x60>
          s = "(null)";
    115e:	00000917          	auipc	s2,0x0
    1162:	57a90913          	addi	s2,s2,1402 # 16d8 <statistics+0x350>
        while(*s != 0){
    1166:	02800593          	li	a1,40
    116a:	bff1                	j	1146 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
    116c:	008b0913          	addi	s2,s6,8
    1170:	000b4583          	lbu	a1,0(s6)
    1174:	8556                	mv	a0,s5
    1176:	00000097          	auipc	ra,0x0
    117a:	d98080e7          	jalr	-616(ra) # f0e <putc>
    117e:	8b4a                	mv	s6,s2
      state = 0;
    1180:	4981                	li	s3,0
    1182:	bd65                	j	103a <vprintf+0x60>
        putc(fd, c);
    1184:	85d2                	mv	a1,s4
    1186:	8556                	mv	a0,s5
    1188:	00000097          	auipc	ra,0x0
    118c:	d86080e7          	jalr	-634(ra) # f0e <putc>
      state = 0;
    1190:	4981                	li	s3,0
    1192:	b565                	j	103a <vprintf+0x60>
        s = va_arg(ap, char*);
    1194:	8b4e                	mv	s6,s3
      state = 0;
    1196:	4981                	li	s3,0
    1198:	b54d                	j	103a <vprintf+0x60>
    }
  }
}
    119a:	70e6                	ld	ra,120(sp)
    119c:	7446                	ld	s0,112(sp)
    119e:	74a6                	ld	s1,104(sp)
    11a0:	7906                	ld	s2,96(sp)
    11a2:	69e6                	ld	s3,88(sp)
    11a4:	6a46                	ld	s4,80(sp)
    11a6:	6aa6                	ld	s5,72(sp)
    11a8:	6b06                	ld	s6,64(sp)
    11aa:	7be2                	ld	s7,56(sp)
    11ac:	7c42                	ld	s8,48(sp)
    11ae:	7ca2                	ld	s9,40(sp)
    11b0:	7d02                	ld	s10,32(sp)
    11b2:	6de2                	ld	s11,24(sp)
    11b4:	6109                	addi	sp,sp,128
    11b6:	8082                	ret

00000000000011b8 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
    11b8:	715d                	addi	sp,sp,-80
    11ba:	ec06                	sd	ra,24(sp)
    11bc:	e822                	sd	s0,16(sp)
    11be:	1000                	addi	s0,sp,32
    11c0:	e010                	sd	a2,0(s0)
    11c2:	e414                	sd	a3,8(s0)
    11c4:	e818                	sd	a4,16(s0)
    11c6:	ec1c                	sd	a5,24(s0)
    11c8:	03043023          	sd	a6,32(s0)
    11cc:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
    11d0:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
    11d4:	8622                	mv	a2,s0
    11d6:	00000097          	auipc	ra,0x0
    11da:	e04080e7          	jalr	-508(ra) # fda <vprintf>
}
    11de:	60e2                	ld	ra,24(sp)
    11e0:	6442                	ld	s0,16(sp)
    11e2:	6161                	addi	sp,sp,80
    11e4:	8082                	ret

00000000000011e6 <printf>:

void
printf(const char *fmt, ...)
{
    11e6:	711d                	addi	sp,sp,-96
    11e8:	ec06                	sd	ra,24(sp)
    11ea:	e822                	sd	s0,16(sp)
    11ec:	1000                	addi	s0,sp,32
    11ee:	e40c                	sd	a1,8(s0)
    11f0:	e810                	sd	a2,16(s0)
    11f2:	ec14                	sd	a3,24(s0)
    11f4:	f018                	sd	a4,32(s0)
    11f6:	f41c                	sd	a5,40(s0)
    11f8:	03043823          	sd	a6,48(s0)
    11fc:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
    1200:	00840613          	addi	a2,s0,8
    1204:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
    1208:	85aa                	mv	a1,a0
    120a:	4505                	li	a0,1
    120c:	00000097          	auipc	ra,0x0
    1210:	dce080e7          	jalr	-562(ra) # fda <vprintf>
}
    1214:	60e2                	ld	ra,24(sp)
    1216:	6442                	ld	s0,16(sp)
    1218:	6125                	addi	sp,sp,96
    121a:	8082                	ret

000000000000121c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    121c:	1141                	addi	sp,sp,-16
    121e:	e422                	sd	s0,8(sp)
    1220:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
    1222:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    1226:	00000797          	auipc	a5,0x0
    122a:	5027b783          	ld	a5,1282(a5) # 1728 <freep>
    122e:	a805                	j	125e <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
    1230:	4618                	lw	a4,8(a2)
    1232:	9db9                	addw	a1,a1,a4
    1234:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
    1238:	6398                	ld	a4,0(a5)
    123a:	6318                	ld	a4,0(a4)
    123c:	fee53823          	sd	a4,-16(a0)
    1240:	a091                	j	1284 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
    1242:	ff852703          	lw	a4,-8(a0)
    1246:	9e39                	addw	a2,a2,a4
    1248:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
    124a:	ff053703          	ld	a4,-16(a0)
    124e:	e398                	sd	a4,0(a5)
    1250:	a099                	j	1296 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    1252:	6398                	ld	a4,0(a5)
    1254:	00e7e463          	bltu	a5,a4,125c <free+0x40>
    1258:	00e6ea63          	bltu	a3,a4,126c <free+0x50>
{
    125c:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    125e:	fed7fae3          	bgeu	a5,a3,1252 <free+0x36>
    1262:	6398                	ld	a4,0(a5)
    1264:	00e6e463          	bltu	a3,a4,126c <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    1268:	fee7eae3          	bltu	a5,a4,125c <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
    126c:	ff852583          	lw	a1,-8(a0)
    1270:	6390                	ld	a2,0(a5)
    1272:	02059713          	slli	a4,a1,0x20
    1276:	9301                	srli	a4,a4,0x20
    1278:	0712                	slli	a4,a4,0x4
    127a:	9736                	add	a4,a4,a3
    127c:	fae60ae3          	beq	a2,a4,1230 <free+0x14>
    bp->s.ptr = p->s.ptr;
    1280:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
    1284:	4790                	lw	a2,8(a5)
    1286:	02061713          	slli	a4,a2,0x20
    128a:	9301                	srli	a4,a4,0x20
    128c:	0712                	slli	a4,a4,0x4
    128e:	973e                	add	a4,a4,a5
    1290:	fae689e3          	beq	a3,a4,1242 <free+0x26>
  } else
    p->s.ptr = bp;
    1294:	e394                	sd	a3,0(a5)
  freep = p;
    1296:	00000717          	auipc	a4,0x0
    129a:	48f73923          	sd	a5,1170(a4) # 1728 <freep>
}
    129e:	6422                	ld	s0,8(sp)
    12a0:	0141                	addi	sp,sp,16
    12a2:	8082                	ret

00000000000012a4 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
    12a4:	7139                	addi	sp,sp,-64
    12a6:	fc06                	sd	ra,56(sp)
    12a8:	f822                	sd	s0,48(sp)
    12aa:	f426                	sd	s1,40(sp)
    12ac:	f04a                	sd	s2,32(sp)
    12ae:	ec4e                	sd	s3,24(sp)
    12b0:	e852                	sd	s4,16(sp)
    12b2:	e456                	sd	s5,8(sp)
    12b4:	e05a                	sd	s6,0(sp)
    12b6:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    12b8:	02051493          	slli	s1,a0,0x20
    12bc:	9081                	srli	s1,s1,0x20
    12be:	04bd                	addi	s1,s1,15
    12c0:	8091                	srli	s1,s1,0x4
    12c2:	0014899b          	addiw	s3,s1,1
    12c6:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
    12c8:	00000517          	auipc	a0,0x0
    12cc:	46053503          	ld	a0,1120(a0) # 1728 <freep>
    12d0:	c515                	beqz	a0,12fc <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    12d2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    12d4:	4798                	lw	a4,8(a5)
    12d6:	02977f63          	bgeu	a4,s1,1314 <malloc+0x70>
    12da:	8a4e                	mv	s4,s3
    12dc:	0009871b          	sext.w	a4,s3
    12e0:	6685                	lui	a3,0x1
    12e2:	00d77363          	bgeu	a4,a3,12e8 <malloc+0x44>
    12e6:	6a05                	lui	s4,0x1
    12e8:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
    12ec:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
    12f0:	00000917          	auipc	s2,0x0
    12f4:	43890913          	addi	s2,s2,1080 # 1728 <freep>
  if(p == (char*)-1)
    12f8:	5afd                	li	s5,-1
    12fa:	a88d                	j	136c <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
    12fc:	00001797          	auipc	a5,0x1
    1300:	81c78793          	addi	a5,a5,-2020 # 1b18 <base>
    1304:	00000717          	auipc	a4,0x0
    1308:	42f73223          	sd	a5,1060(a4) # 1728 <freep>
    130c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
    130e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
    1312:	b7e1                	j	12da <malloc+0x36>
      if(p->s.size == nunits)
    1314:	02e48b63          	beq	s1,a4,134a <malloc+0xa6>
        p->s.size -= nunits;
    1318:	4137073b          	subw	a4,a4,s3
    131c:	c798                	sw	a4,8(a5)
        p += p->s.size;
    131e:	1702                	slli	a4,a4,0x20
    1320:	9301                	srli	a4,a4,0x20
    1322:	0712                	slli	a4,a4,0x4
    1324:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
    1326:	0137a423          	sw	s3,8(a5)
      freep = prevp;
    132a:	00000717          	auipc	a4,0x0
    132e:	3ea73f23          	sd	a0,1022(a4) # 1728 <freep>
      return (void*)(p + 1);
    1332:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
    1336:	70e2                	ld	ra,56(sp)
    1338:	7442                	ld	s0,48(sp)
    133a:	74a2                	ld	s1,40(sp)
    133c:	7902                	ld	s2,32(sp)
    133e:	69e2                	ld	s3,24(sp)
    1340:	6a42                	ld	s4,16(sp)
    1342:	6aa2                	ld	s5,8(sp)
    1344:	6b02                	ld	s6,0(sp)
    1346:	6121                	addi	sp,sp,64
    1348:	8082                	ret
        prevp->s.ptr = p->s.ptr;
    134a:	6398                	ld	a4,0(a5)
    134c:	e118                	sd	a4,0(a0)
    134e:	bff1                	j	132a <malloc+0x86>
  hp->s.size = nu;
    1350:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
    1354:	0541                	addi	a0,a0,16
    1356:	00000097          	auipc	ra,0x0
    135a:	ec6080e7          	jalr	-314(ra) # 121c <free>
  return freep;
    135e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
    1362:	d971                	beqz	a0,1336 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    1364:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    1366:	4798                	lw	a4,8(a5)
    1368:	fa9776e3          	bgeu	a4,s1,1314 <malloc+0x70>
    if(p == freep)
    136c:	00093703          	ld	a4,0(s2)
    1370:	853e                	mv	a0,a5
    1372:	fef719e3          	bne	a4,a5,1364 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
    1376:	8552                	mv	a0,s4
    1378:	00000097          	auipc	ra,0x0
    137c:	b6e080e7          	jalr	-1170(ra) # ee6 <sbrk>
  if(p == (char*)-1)
    1380:	fd5518e3          	bne	a0,s5,1350 <malloc+0xac>
        return 0;
    1384:	4501                	li	a0,0
    1386:	bf45                	j	1336 <malloc+0x92>

0000000000001388 <statistics>:
#include "kernel/fcntl.h"
#include "user/user.h"

int
statistics(void *buf, int sz)
{
    1388:	7179                	addi	sp,sp,-48
    138a:	f406                	sd	ra,40(sp)
    138c:	f022                	sd	s0,32(sp)
    138e:	ec26                	sd	s1,24(sp)
    1390:	e84a                	sd	s2,16(sp)
    1392:	e44e                	sd	s3,8(sp)
    1394:	e052                	sd	s4,0(sp)
    1396:	1800                	addi	s0,sp,48
    1398:	8a2a                	mv	s4,a0
    139a:	892e                	mv	s2,a1
  int fd, i, n;
  
  fd = open("statistics", O_RDONLY);
    139c:	4581                	li	a1,0
    139e:	00000517          	auipc	a0,0x0
    13a2:	35a50513          	addi	a0,a0,858 # 16f8 <digits+0x18>
    13a6:	00000097          	auipc	ra,0x0
    13aa:	af8080e7          	jalr	-1288(ra) # e9e <open>
  if(fd < 0) {
    13ae:	04054263          	bltz	a0,13f2 <statistics+0x6a>
    13b2:	89aa                	mv	s3,a0
      fprintf(2, "stats: open failed\n");
      exit(1);
  }
  for (i = 0; i < sz; ) {
    13b4:	4481                	li	s1,0
    13b6:	03205063          	blez	s2,13d6 <statistics+0x4e>
    if ((n = read(fd, buf+i, sz-i)) < 0) {
    13ba:	4099063b          	subw	a2,s2,s1
    13be:	009a05b3          	add	a1,s4,s1
    13c2:	854e                	mv	a0,s3
    13c4:	00000097          	auipc	ra,0x0
    13c8:	ab2080e7          	jalr	-1358(ra) # e76 <read>
    13cc:	00054563          	bltz	a0,13d6 <statistics+0x4e>
      break;
    }
    i += n;
    13d0:	9ca9                	addw	s1,s1,a0
  for (i = 0; i < sz; ) {
    13d2:	ff24c4e3          	blt	s1,s2,13ba <statistics+0x32>
  }
  close(fd);
    13d6:	854e                	mv	a0,s3
    13d8:	00000097          	auipc	ra,0x0
    13dc:	aae080e7          	jalr	-1362(ra) # e86 <close>
  return i;
}
    13e0:	8526                	mv	a0,s1
    13e2:	70a2                	ld	ra,40(sp)
    13e4:	7402                	ld	s0,32(sp)
    13e6:	64e2                	ld	s1,24(sp)
    13e8:	6942                	ld	s2,16(sp)
    13ea:	69a2                	ld	s3,8(sp)
    13ec:	6a02                	ld	s4,0(sp)
    13ee:	6145                	addi	sp,sp,48
    13f0:	8082                	ret
      fprintf(2, "stats: open failed\n");
    13f2:	00000597          	auipc	a1,0x0
    13f6:	31658593          	addi	a1,a1,790 # 1708 <digits+0x28>
    13fa:	4509                	li	a0,2
    13fc:	00000097          	auipc	ra,0x0
    1400:	dbc080e7          	jalr	-580(ra) # 11b8 <fprintf>
      exit(1);
    1404:	4505                	li	a0,1
    1406:	00000097          	auipc	ra,0x0
    140a:	a58080e7          	jalr	-1448(ra) # e5e <exit>
