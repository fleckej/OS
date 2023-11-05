
user/_ticketsnum:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <test_getpinfo>:
  exit(0);
}

int
test_getpinfo()
{
   0:	bf010113          	add	sp,sp,-1040
   4:	40113423          	sd	ra,1032(sp)
   8:	40813023          	sd	s0,1024(sp)
   c:	41010413          	add	s0,sp,1040
  struct pstat p;
  int works = getpinfo(&p);
  10:	bf040513          	add	a0,s0,-1040
  14:	00000097          	auipc	ra,0x0
  18:	388080e7          	jalr	904(ra) # 39c <getpinfo>
  if (works != 0){
  1c:	00a03533          	snez	a0,a0
    return -1;
  }
  return 0;
}
  20:	40a00533          	neg	a0,a0
  24:	40813083          	ld	ra,1032(sp)
  28:	40013403          	ld	s0,1024(sp)
  2c:	41010113          	add	sp,sp,1040
  30:	8082                	ret

0000000000000032 <main>:
{ 
  32:	1141                	add	sp,sp,-16
  34:	e406                	sd	ra,8(sp)
  36:	e022                	sd	s0,0(sp)
  38:	0800                	add	s0,sp,16
  int getpinfo = test_getpinfo();
  3a:	00000097          	auipc	ra,0x0
  3e:	fc6080e7          	jalr	-58(ra) # 0 <test_getpinfo>
  if (getpinfo == -1){
  42:	57fd                	li	a5,-1
  44:	00f50763          	beq	a0,a5,52 <main+0x20>
}
  48:	4501                	li	a0,0
  4a:	60a2                	ld	ra,8(sp)
  4c:	6402                	ld	s0,0(sp)
  4e:	0141                	add	sp,sp,16
  50:	8082                	ret
    fprintf(2, "test_getpinfo() failed\n");
  52:	00000597          	auipc	a1,0x0
  56:	7ce58593          	add	a1,a1,1998 # 820 <malloc+0xf4>
  5a:	4509                	li	a0,2
  5c:	00000097          	auipc	ra,0x0
  60:	5ea080e7          	jalr	1514(ra) # 646 <fprintf>
  64:	b7d5                	j	48 <main+0x16>

0000000000000066 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  66:	1141                	add	sp,sp,-16
  68:	e406                	sd	ra,8(sp)
  6a:	e022                	sd	s0,0(sp)
  6c:	0800                	add	s0,sp,16
  extern int main();
  main();
  6e:	00000097          	auipc	ra,0x0
  72:	fc4080e7          	jalr	-60(ra) # 32 <main>
  exit(0);
  76:	4501                	li	a0,0
  78:	00000097          	auipc	ra,0x0
  7c:	274080e7          	jalr	628(ra) # 2ec <exit>

0000000000000080 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  80:	1141                	add	sp,sp,-16
  82:	e422                	sd	s0,8(sp)
  84:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  86:	87aa                	mv	a5,a0
  88:	0585                	add	a1,a1,1
  8a:	0785                	add	a5,a5,1
  8c:	fff5c703          	lbu	a4,-1(a1)
  90:	fee78fa3          	sb	a4,-1(a5)
  94:	fb75                	bnez	a4,88 <strcpy+0x8>
    ;
  return os;
}
  96:	6422                	ld	s0,8(sp)
  98:	0141                	add	sp,sp,16
  9a:	8082                	ret

000000000000009c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  9c:	1141                	add	sp,sp,-16
  9e:	e422                	sd	s0,8(sp)
  a0:	0800                	add	s0,sp,16
  while(*p && *p == *q)
  a2:	00054783          	lbu	a5,0(a0)
  a6:	cb91                	beqz	a5,ba <strcmp+0x1e>
  a8:	0005c703          	lbu	a4,0(a1)
  ac:	00f71763          	bne	a4,a5,ba <strcmp+0x1e>
    p++, q++;
  b0:	0505                	add	a0,a0,1
  b2:	0585                	add	a1,a1,1
  while(*p && *p == *q)
  b4:	00054783          	lbu	a5,0(a0)
  b8:	fbe5                	bnez	a5,a8 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  ba:	0005c503          	lbu	a0,0(a1)
}
  be:	40a7853b          	subw	a0,a5,a0
  c2:	6422                	ld	s0,8(sp)
  c4:	0141                	add	sp,sp,16
  c6:	8082                	ret

00000000000000c8 <strlen>:

uint
strlen(const char *s)
{
  c8:	1141                	add	sp,sp,-16
  ca:	e422                	sd	s0,8(sp)
  cc:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  ce:	00054783          	lbu	a5,0(a0)
  d2:	cf91                	beqz	a5,ee <strlen+0x26>
  d4:	0505                	add	a0,a0,1
  d6:	87aa                	mv	a5,a0
  d8:	86be                	mv	a3,a5
  da:	0785                	add	a5,a5,1
  dc:	fff7c703          	lbu	a4,-1(a5)
  e0:	ff65                	bnez	a4,d8 <strlen+0x10>
  e2:	40a6853b          	subw	a0,a3,a0
  e6:	2505                	addw	a0,a0,1
    ;
  return n;
}
  e8:	6422                	ld	s0,8(sp)
  ea:	0141                	add	sp,sp,16
  ec:	8082                	ret
  for(n = 0; s[n]; n++)
  ee:	4501                	li	a0,0
  f0:	bfe5                	j	e8 <strlen+0x20>

00000000000000f2 <memset>:

void*
memset(void *dst, int c, uint n)
{
  f2:	1141                	add	sp,sp,-16
  f4:	e422                	sd	s0,8(sp)
  f6:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  f8:	ca19                	beqz	a2,10e <memset+0x1c>
  fa:	87aa                	mv	a5,a0
  fc:	1602                	sll	a2,a2,0x20
  fe:	9201                	srl	a2,a2,0x20
 100:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 104:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 108:	0785                	add	a5,a5,1
 10a:	fee79de3          	bne	a5,a4,104 <memset+0x12>
  }
  return dst;
}
 10e:	6422                	ld	s0,8(sp)
 110:	0141                	add	sp,sp,16
 112:	8082                	ret

0000000000000114 <strchr>:

char*
strchr(const char *s, char c)
{
 114:	1141                	add	sp,sp,-16
 116:	e422                	sd	s0,8(sp)
 118:	0800                	add	s0,sp,16
  for(; *s; s++)
 11a:	00054783          	lbu	a5,0(a0)
 11e:	cb99                	beqz	a5,134 <strchr+0x20>
    if(*s == c)
 120:	00f58763          	beq	a1,a5,12e <strchr+0x1a>
  for(; *s; s++)
 124:	0505                	add	a0,a0,1
 126:	00054783          	lbu	a5,0(a0)
 12a:	fbfd                	bnez	a5,120 <strchr+0xc>
      return (char*)s;
  return 0;
 12c:	4501                	li	a0,0
}
 12e:	6422                	ld	s0,8(sp)
 130:	0141                	add	sp,sp,16
 132:	8082                	ret
  return 0;
 134:	4501                	li	a0,0
 136:	bfe5                	j	12e <strchr+0x1a>

0000000000000138 <gets>:

char*
gets(char *buf, int max)
{
 138:	711d                	add	sp,sp,-96
 13a:	ec86                	sd	ra,88(sp)
 13c:	e8a2                	sd	s0,80(sp)
 13e:	e4a6                	sd	s1,72(sp)
 140:	e0ca                	sd	s2,64(sp)
 142:	fc4e                	sd	s3,56(sp)
 144:	f852                	sd	s4,48(sp)
 146:	f456                	sd	s5,40(sp)
 148:	f05a                	sd	s6,32(sp)
 14a:	ec5e                	sd	s7,24(sp)
 14c:	1080                	add	s0,sp,96
 14e:	8baa                	mv	s7,a0
 150:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 152:	892a                	mv	s2,a0
 154:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 156:	4aa9                	li	s5,10
 158:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 15a:	89a6                	mv	s3,s1
 15c:	2485                	addw	s1,s1,1
 15e:	0344d863          	bge	s1,s4,18e <gets+0x56>
    cc = read(0, &c, 1);
 162:	4605                	li	a2,1
 164:	faf40593          	add	a1,s0,-81
 168:	4501                	li	a0,0
 16a:	00000097          	auipc	ra,0x0
 16e:	19a080e7          	jalr	410(ra) # 304 <read>
    if(cc < 1)
 172:	00a05e63          	blez	a0,18e <gets+0x56>
    buf[i++] = c;
 176:	faf44783          	lbu	a5,-81(s0)
 17a:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 17e:	01578763          	beq	a5,s5,18c <gets+0x54>
 182:	0905                	add	s2,s2,1
 184:	fd679be3          	bne	a5,s6,15a <gets+0x22>
  for(i=0; i+1 < max; ){
 188:	89a6                	mv	s3,s1
 18a:	a011                	j	18e <gets+0x56>
 18c:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 18e:	99de                	add	s3,s3,s7
 190:	00098023          	sb	zero,0(s3)
  return buf;
}
 194:	855e                	mv	a0,s7
 196:	60e6                	ld	ra,88(sp)
 198:	6446                	ld	s0,80(sp)
 19a:	64a6                	ld	s1,72(sp)
 19c:	6906                	ld	s2,64(sp)
 19e:	79e2                	ld	s3,56(sp)
 1a0:	7a42                	ld	s4,48(sp)
 1a2:	7aa2                	ld	s5,40(sp)
 1a4:	7b02                	ld	s6,32(sp)
 1a6:	6be2                	ld	s7,24(sp)
 1a8:	6125                	add	sp,sp,96
 1aa:	8082                	ret

00000000000001ac <stat>:

int
stat(const char *n, struct stat *st)
{
 1ac:	1101                	add	sp,sp,-32
 1ae:	ec06                	sd	ra,24(sp)
 1b0:	e822                	sd	s0,16(sp)
 1b2:	e426                	sd	s1,8(sp)
 1b4:	e04a                	sd	s2,0(sp)
 1b6:	1000                	add	s0,sp,32
 1b8:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1ba:	4581                	li	a1,0
 1bc:	00000097          	auipc	ra,0x0
 1c0:	170080e7          	jalr	368(ra) # 32c <open>
  if(fd < 0)
 1c4:	02054563          	bltz	a0,1ee <stat+0x42>
 1c8:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1ca:	85ca                	mv	a1,s2
 1cc:	00000097          	auipc	ra,0x0
 1d0:	178080e7          	jalr	376(ra) # 344 <fstat>
 1d4:	892a                	mv	s2,a0
  close(fd);
 1d6:	8526                	mv	a0,s1
 1d8:	00000097          	auipc	ra,0x0
 1dc:	13c080e7          	jalr	316(ra) # 314 <close>
  return r;
}
 1e0:	854a                	mv	a0,s2
 1e2:	60e2                	ld	ra,24(sp)
 1e4:	6442                	ld	s0,16(sp)
 1e6:	64a2                	ld	s1,8(sp)
 1e8:	6902                	ld	s2,0(sp)
 1ea:	6105                	add	sp,sp,32
 1ec:	8082                	ret
    return -1;
 1ee:	597d                	li	s2,-1
 1f0:	bfc5                	j	1e0 <stat+0x34>

00000000000001f2 <atoi>:

int
atoi(const char *s)
{
 1f2:	1141                	add	sp,sp,-16
 1f4:	e422                	sd	s0,8(sp)
 1f6:	0800                	add	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1f8:	00054683          	lbu	a3,0(a0)
 1fc:	fd06879b          	addw	a5,a3,-48
 200:	0ff7f793          	zext.b	a5,a5
 204:	4625                	li	a2,9
 206:	02f66863          	bltu	a2,a5,236 <atoi+0x44>
 20a:	872a                	mv	a4,a0
  n = 0;
 20c:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 20e:	0705                	add	a4,a4,1
 210:	0025179b          	sllw	a5,a0,0x2
 214:	9fa9                	addw	a5,a5,a0
 216:	0017979b          	sllw	a5,a5,0x1
 21a:	9fb5                	addw	a5,a5,a3
 21c:	fd07851b          	addw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 220:	00074683          	lbu	a3,0(a4)
 224:	fd06879b          	addw	a5,a3,-48
 228:	0ff7f793          	zext.b	a5,a5
 22c:	fef671e3          	bgeu	a2,a5,20e <atoi+0x1c>
  return n;
}
 230:	6422                	ld	s0,8(sp)
 232:	0141                	add	sp,sp,16
 234:	8082                	ret
  n = 0;
 236:	4501                	li	a0,0
 238:	bfe5                	j	230 <atoi+0x3e>

000000000000023a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 23a:	1141                	add	sp,sp,-16
 23c:	e422                	sd	s0,8(sp)
 23e:	0800                	add	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 240:	02b57463          	bgeu	a0,a1,268 <memmove+0x2e>
    while(n-- > 0)
 244:	00c05f63          	blez	a2,262 <memmove+0x28>
 248:	1602                	sll	a2,a2,0x20
 24a:	9201                	srl	a2,a2,0x20
 24c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 250:	872a                	mv	a4,a0
      *dst++ = *src++;
 252:	0585                	add	a1,a1,1
 254:	0705                	add	a4,a4,1
 256:	fff5c683          	lbu	a3,-1(a1)
 25a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 25e:	fee79ae3          	bne	a5,a4,252 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 262:	6422                	ld	s0,8(sp)
 264:	0141                	add	sp,sp,16
 266:	8082                	ret
    dst += n;
 268:	00c50733          	add	a4,a0,a2
    src += n;
 26c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 26e:	fec05ae3          	blez	a2,262 <memmove+0x28>
 272:	fff6079b          	addw	a5,a2,-1
 276:	1782                	sll	a5,a5,0x20
 278:	9381                	srl	a5,a5,0x20
 27a:	fff7c793          	not	a5,a5
 27e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 280:	15fd                	add	a1,a1,-1
 282:	177d                	add	a4,a4,-1
 284:	0005c683          	lbu	a3,0(a1)
 288:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 28c:	fee79ae3          	bne	a5,a4,280 <memmove+0x46>
 290:	bfc9                	j	262 <memmove+0x28>

0000000000000292 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 292:	1141                	add	sp,sp,-16
 294:	e422                	sd	s0,8(sp)
 296:	0800                	add	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 298:	ca05                	beqz	a2,2c8 <memcmp+0x36>
 29a:	fff6069b          	addw	a3,a2,-1
 29e:	1682                	sll	a3,a3,0x20
 2a0:	9281                	srl	a3,a3,0x20
 2a2:	0685                	add	a3,a3,1
 2a4:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2a6:	00054783          	lbu	a5,0(a0)
 2aa:	0005c703          	lbu	a4,0(a1)
 2ae:	00e79863          	bne	a5,a4,2be <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2b2:	0505                	add	a0,a0,1
    p2++;
 2b4:	0585                	add	a1,a1,1
  while (n-- > 0) {
 2b6:	fed518e3          	bne	a0,a3,2a6 <memcmp+0x14>
  }
  return 0;
 2ba:	4501                	li	a0,0
 2bc:	a019                	j	2c2 <memcmp+0x30>
      return *p1 - *p2;
 2be:	40e7853b          	subw	a0,a5,a4
}
 2c2:	6422                	ld	s0,8(sp)
 2c4:	0141                	add	sp,sp,16
 2c6:	8082                	ret
  return 0;
 2c8:	4501                	li	a0,0
 2ca:	bfe5                	j	2c2 <memcmp+0x30>

00000000000002cc <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2cc:	1141                	add	sp,sp,-16
 2ce:	e406                	sd	ra,8(sp)
 2d0:	e022                	sd	s0,0(sp)
 2d2:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
 2d4:	00000097          	auipc	ra,0x0
 2d8:	f66080e7          	jalr	-154(ra) # 23a <memmove>
}
 2dc:	60a2                	ld	ra,8(sp)
 2de:	6402                	ld	s0,0(sp)
 2e0:	0141                	add	sp,sp,16
 2e2:	8082                	ret

00000000000002e4 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2e4:	4885                	li	a7,1
 ecall
 2e6:	00000073          	ecall
 ret
 2ea:	8082                	ret

00000000000002ec <exit>:
.global exit
exit:
 li a7, SYS_exit
 2ec:	4889                	li	a7,2
 ecall
 2ee:	00000073          	ecall
 ret
 2f2:	8082                	ret

00000000000002f4 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2f4:	488d                	li	a7,3
 ecall
 2f6:	00000073          	ecall
 ret
 2fa:	8082                	ret

00000000000002fc <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2fc:	4891                	li	a7,4
 ecall
 2fe:	00000073          	ecall
 ret
 302:	8082                	ret

0000000000000304 <read>:
.global read
read:
 li a7, SYS_read
 304:	4895                	li	a7,5
 ecall
 306:	00000073          	ecall
 ret
 30a:	8082                	ret

000000000000030c <write>:
.global write
write:
 li a7, SYS_write
 30c:	48c1                	li	a7,16
 ecall
 30e:	00000073          	ecall
 ret
 312:	8082                	ret

0000000000000314 <close>:
.global close
close:
 li a7, SYS_close
 314:	48d5                	li	a7,21
 ecall
 316:	00000073          	ecall
 ret
 31a:	8082                	ret

000000000000031c <kill>:
.global kill
kill:
 li a7, SYS_kill
 31c:	4899                	li	a7,6
 ecall
 31e:	00000073          	ecall
 ret
 322:	8082                	ret

0000000000000324 <exec>:
.global exec
exec:
 li a7, SYS_exec
 324:	489d                	li	a7,7
 ecall
 326:	00000073          	ecall
 ret
 32a:	8082                	ret

000000000000032c <open>:
.global open
open:
 li a7, SYS_open
 32c:	48bd                	li	a7,15
 ecall
 32e:	00000073          	ecall
 ret
 332:	8082                	ret

0000000000000334 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 334:	48c5                	li	a7,17
 ecall
 336:	00000073          	ecall
 ret
 33a:	8082                	ret

000000000000033c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 33c:	48c9                	li	a7,18
 ecall
 33e:	00000073          	ecall
 ret
 342:	8082                	ret

0000000000000344 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 344:	48a1                	li	a7,8
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <link>:
.global link
link:
 li a7, SYS_link
 34c:	48cd                	li	a7,19
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 354:	48d1                	li	a7,20
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 35c:	48a5                	li	a7,9
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <dup>:
.global dup
dup:
 li a7, SYS_dup
 364:	48a9                	li	a7,10
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 36c:	48ad                	li	a7,11
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 374:	48b1                	li	a7,12
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 37c:	48b5                	li	a7,13
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 384:	48b9                	li	a7,14
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <getfilenum>:
.global getfilenum
getfilenum:
 li a7, SYS_getfilenum
 38c:	48d9                	li	a7,22
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 394:	48dd                	li	a7,23
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <getpinfo>:
.global getpinfo
getpinfo:
 li a7, SYS_getpinfo
 39c:	48e1                	li	a7,24
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <pgaccess>:
.global pgaccess
pgaccess:
 li a7, SYS_pgaccess
 3a4:	48e5                	li	a7,25
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3ac:	1101                	add	sp,sp,-32
 3ae:	ec06                	sd	ra,24(sp)
 3b0:	e822                	sd	s0,16(sp)
 3b2:	1000                	add	s0,sp,32
 3b4:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3b8:	4605                	li	a2,1
 3ba:	fef40593          	add	a1,s0,-17
 3be:	00000097          	auipc	ra,0x0
 3c2:	f4e080e7          	jalr	-178(ra) # 30c <write>
}
 3c6:	60e2                	ld	ra,24(sp)
 3c8:	6442                	ld	s0,16(sp)
 3ca:	6105                	add	sp,sp,32
 3cc:	8082                	ret

00000000000003ce <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3ce:	7139                	add	sp,sp,-64
 3d0:	fc06                	sd	ra,56(sp)
 3d2:	f822                	sd	s0,48(sp)
 3d4:	f426                	sd	s1,40(sp)
 3d6:	f04a                	sd	s2,32(sp)
 3d8:	ec4e                	sd	s3,24(sp)
 3da:	0080                	add	s0,sp,64
 3dc:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3de:	c299                	beqz	a3,3e4 <printint+0x16>
 3e0:	0805c963          	bltz	a1,472 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3e4:	2581                	sext.w	a1,a1
  neg = 0;
 3e6:	4881                	li	a7,0
 3e8:	fc040693          	add	a3,s0,-64
  }

  i = 0;
 3ec:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3ee:	2601                	sext.w	a2,a2
 3f0:	00000517          	auipc	a0,0x0
 3f4:	4a850513          	add	a0,a0,1192 # 898 <digits>
 3f8:	883a                	mv	a6,a4
 3fa:	2705                	addw	a4,a4,1
 3fc:	02c5f7bb          	remuw	a5,a1,a2
 400:	1782                	sll	a5,a5,0x20
 402:	9381                	srl	a5,a5,0x20
 404:	97aa                	add	a5,a5,a0
 406:	0007c783          	lbu	a5,0(a5)
 40a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 40e:	0005879b          	sext.w	a5,a1
 412:	02c5d5bb          	divuw	a1,a1,a2
 416:	0685                	add	a3,a3,1
 418:	fec7f0e3          	bgeu	a5,a2,3f8 <printint+0x2a>
  if(neg)
 41c:	00088c63          	beqz	a7,434 <printint+0x66>
    buf[i++] = '-';
 420:	fd070793          	add	a5,a4,-48
 424:	00878733          	add	a4,a5,s0
 428:	02d00793          	li	a5,45
 42c:	fef70823          	sb	a5,-16(a4)
 430:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
 434:	02e05863          	blez	a4,464 <printint+0x96>
 438:	fc040793          	add	a5,s0,-64
 43c:	00e78933          	add	s2,a5,a4
 440:	fff78993          	add	s3,a5,-1
 444:	99ba                	add	s3,s3,a4
 446:	377d                	addw	a4,a4,-1
 448:	1702                	sll	a4,a4,0x20
 44a:	9301                	srl	a4,a4,0x20
 44c:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 450:	fff94583          	lbu	a1,-1(s2)
 454:	8526                	mv	a0,s1
 456:	00000097          	auipc	ra,0x0
 45a:	f56080e7          	jalr	-170(ra) # 3ac <putc>
  while(--i >= 0)
 45e:	197d                	add	s2,s2,-1
 460:	ff3918e3          	bne	s2,s3,450 <printint+0x82>
}
 464:	70e2                	ld	ra,56(sp)
 466:	7442                	ld	s0,48(sp)
 468:	74a2                	ld	s1,40(sp)
 46a:	7902                	ld	s2,32(sp)
 46c:	69e2                	ld	s3,24(sp)
 46e:	6121                	add	sp,sp,64
 470:	8082                	ret
    x = -xx;
 472:	40b005bb          	negw	a1,a1
    neg = 1;
 476:	4885                	li	a7,1
    x = -xx;
 478:	bf85                	j	3e8 <printint+0x1a>

000000000000047a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 47a:	715d                	add	sp,sp,-80
 47c:	e486                	sd	ra,72(sp)
 47e:	e0a2                	sd	s0,64(sp)
 480:	fc26                	sd	s1,56(sp)
 482:	f84a                	sd	s2,48(sp)
 484:	f44e                	sd	s3,40(sp)
 486:	f052                	sd	s4,32(sp)
 488:	ec56                	sd	s5,24(sp)
 48a:	e85a                	sd	s6,16(sp)
 48c:	e45e                	sd	s7,8(sp)
 48e:	e062                	sd	s8,0(sp)
 490:	0880                	add	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 492:	0005c903          	lbu	s2,0(a1)
 496:	18090c63          	beqz	s2,62e <vprintf+0x1b4>
 49a:	8aaa                	mv	s5,a0
 49c:	8bb2                	mv	s7,a2
 49e:	00158493          	add	s1,a1,1
  state = 0;
 4a2:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4a4:	02500a13          	li	s4,37
 4a8:	4b55                	li	s6,21
 4aa:	a839                	j	4c8 <vprintf+0x4e>
        putc(fd, c);
 4ac:	85ca                	mv	a1,s2
 4ae:	8556                	mv	a0,s5
 4b0:	00000097          	auipc	ra,0x0
 4b4:	efc080e7          	jalr	-260(ra) # 3ac <putc>
 4b8:	a019                	j	4be <vprintf+0x44>
    } else if(state == '%'){
 4ba:	01498d63          	beq	s3,s4,4d4 <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 4be:	0485                	add	s1,s1,1
 4c0:	fff4c903          	lbu	s2,-1(s1)
 4c4:	16090563          	beqz	s2,62e <vprintf+0x1b4>
    if(state == 0){
 4c8:	fe0999e3          	bnez	s3,4ba <vprintf+0x40>
      if(c == '%'){
 4cc:	ff4910e3          	bne	s2,s4,4ac <vprintf+0x32>
        state = '%';
 4d0:	89d2                	mv	s3,s4
 4d2:	b7f5                	j	4be <vprintf+0x44>
      if(c == 'd'){
 4d4:	13490263          	beq	s2,s4,5f8 <vprintf+0x17e>
 4d8:	f9d9079b          	addw	a5,s2,-99
 4dc:	0ff7f793          	zext.b	a5,a5
 4e0:	12fb6563          	bltu	s6,a5,60a <vprintf+0x190>
 4e4:	f9d9079b          	addw	a5,s2,-99
 4e8:	0ff7f713          	zext.b	a4,a5
 4ec:	10eb6f63          	bltu	s6,a4,60a <vprintf+0x190>
 4f0:	00271793          	sll	a5,a4,0x2
 4f4:	00000717          	auipc	a4,0x0
 4f8:	34c70713          	add	a4,a4,844 # 840 <malloc+0x114>
 4fc:	97ba                	add	a5,a5,a4
 4fe:	439c                	lw	a5,0(a5)
 500:	97ba                	add	a5,a5,a4
 502:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 504:	008b8913          	add	s2,s7,8
 508:	4685                	li	a3,1
 50a:	4629                	li	a2,10
 50c:	000ba583          	lw	a1,0(s7)
 510:	8556                	mv	a0,s5
 512:	00000097          	auipc	ra,0x0
 516:	ebc080e7          	jalr	-324(ra) # 3ce <printint>
 51a:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 51c:	4981                	li	s3,0
 51e:	b745                	j	4be <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 520:	008b8913          	add	s2,s7,8
 524:	4681                	li	a3,0
 526:	4629                	li	a2,10
 528:	000ba583          	lw	a1,0(s7)
 52c:	8556                	mv	a0,s5
 52e:	00000097          	auipc	ra,0x0
 532:	ea0080e7          	jalr	-352(ra) # 3ce <printint>
 536:	8bca                	mv	s7,s2
      state = 0;
 538:	4981                	li	s3,0
 53a:	b751                	j	4be <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 53c:	008b8913          	add	s2,s7,8
 540:	4681                	li	a3,0
 542:	4641                	li	a2,16
 544:	000ba583          	lw	a1,0(s7)
 548:	8556                	mv	a0,s5
 54a:	00000097          	auipc	ra,0x0
 54e:	e84080e7          	jalr	-380(ra) # 3ce <printint>
 552:	8bca                	mv	s7,s2
      state = 0;
 554:	4981                	li	s3,0
 556:	b7a5                	j	4be <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 558:	008b8c13          	add	s8,s7,8
 55c:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 560:	03000593          	li	a1,48
 564:	8556                	mv	a0,s5
 566:	00000097          	auipc	ra,0x0
 56a:	e46080e7          	jalr	-442(ra) # 3ac <putc>
  putc(fd, 'x');
 56e:	07800593          	li	a1,120
 572:	8556                	mv	a0,s5
 574:	00000097          	auipc	ra,0x0
 578:	e38080e7          	jalr	-456(ra) # 3ac <putc>
 57c:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 57e:	00000b97          	auipc	s7,0x0
 582:	31ab8b93          	add	s7,s7,794 # 898 <digits>
 586:	03c9d793          	srl	a5,s3,0x3c
 58a:	97de                	add	a5,a5,s7
 58c:	0007c583          	lbu	a1,0(a5)
 590:	8556                	mv	a0,s5
 592:	00000097          	auipc	ra,0x0
 596:	e1a080e7          	jalr	-486(ra) # 3ac <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 59a:	0992                	sll	s3,s3,0x4
 59c:	397d                	addw	s2,s2,-1
 59e:	fe0914e3          	bnez	s2,586 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 5a2:	8be2                	mv	s7,s8
      state = 0;
 5a4:	4981                	li	s3,0
 5a6:	bf21                	j	4be <vprintf+0x44>
        s = va_arg(ap, char*);
 5a8:	008b8993          	add	s3,s7,8
 5ac:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 5b0:	02090163          	beqz	s2,5d2 <vprintf+0x158>
        while(*s != 0){
 5b4:	00094583          	lbu	a1,0(s2)
 5b8:	c9a5                	beqz	a1,628 <vprintf+0x1ae>
          putc(fd, *s);
 5ba:	8556                	mv	a0,s5
 5bc:	00000097          	auipc	ra,0x0
 5c0:	df0080e7          	jalr	-528(ra) # 3ac <putc>
          s++;
 5c4:	0905                	add	s2,s2,1
        while(*s != 0){
 5c6:	00094583          	lbu	a1,0(s2)
 5ca:	f9e5                	bnez	a1,5ba <vprintf+0x140>
        s = va_arg(ap, char*);
 5cc:	8bce                	mv	s7,s3
      state = 0;
 5ce:	4981                	li	s3,0
 5d0:	b5fd                	j	4be <vprintf+0x44>
          s = "(null)";
 5d2:	00000917          	auipc	s2,0x0
 5d6:	26690913          	add	s2,s2,614 # 838 <malloc+0x10c>
        while(*s != 0){
 5da:	02800593          	li	a1,40
 5de:	bff1                	j	5ba <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 5e0:	008b8913          	add	s2,s7,8
 5e4:	000bc583          	lbu	a1,0(s7)
 5e8:	8556                	mv	a0,s5
 5ea:	00000097          	auipc	ra,0x0
 5ee:	dc2080e7          	jalr	-574(ra) # 3ac <putc>
 5f2:	8bca                	mv	s7,s2
      state = 0;
 5f4:	4981                	li	s3,0
 5f6:	b5e1                	j	4be <vprintf+0x44>
        putc(fd, c);
 5f8:	02500593          	li	a1,37
 5fc:	8556                	mv	a0,s5
 5fe:	00000097          	auipc	ra,0x0
 602:	dae080e7          	jalr	-594(ra) # 3ac <putc>
      state = 0;
 606:	4981                	li	s3,0
 608:	bd5d                	j	4be <vprintf+0x44>
        putc(fd, '%');
 60a:	02500593          	li	a1,37
 60e:	8556                	mv	a0,s5
 610:	00000097          	auipc	ra,0x0
 614:	d9c080e7          	jalr	-612(ra) # 3ac <putc>
        putc(fd, c);
 618:	85ca                	mv	a1,s2
 61a:	8556                	mv	a0,s5
 61c:	00000097          	auipc	ra,0x0
 620:	d90080e7          	jalr	-624(ra) # 3ac <putc>
      state = 0;
 624:	4981                	li	s3,0
 626:	bd61                	j	4be <vprintf+0x44>
        s = va_arg(ap, char*);
 628:	8bce                	mv	s7,s3
      state = 0;
 62a:	4981                	li	s3,0
 62c:	bd49                	j	4be <vprintf+0x44>
    }
  }
}
 62e:	60a6                	ld	ra,72(sp)
 630:	6406                	ld	s0,64(sp)
 632:	74e2                	ld	s1,56(sp)
 634:	7942                	ld	s2,48(sp)
 636:	79a2                	ld	s3,40(sp)
 638:	7a02                	ld	s4,32(sp)
 63a:	6ae2                	ld	s5,24(sp)
 63c:	6b42                	ld	s6,16(sp)
 63e:	6ba2                	ld	s7,8(sp)
 640:	6c02                	ld	s8,0(sp)
 642:	6161                	add	sp,sp,80
 644:	8082                	ret

0000000000000646 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 646:	715d                	add	sp,sp,-80
 648:	ec06                	sd	ra,24(sp)
 64a:	e822                	sd	s0,16(sp)
 64c:	1000                	add	s0,sp,32
 64e:	e010                	sd	a2,0(s0)
 650:	e414                	sd	a3,8(s0)
 652:	e818                	sd	a4,16(s0)
 654:	ec1c                	sd	a5,24(s0)
 656:	03043023          	sd	a6,32(s0)
 65a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 65e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 662:	8622                	mv	a2,s0
 664:	00000097          	auipc	ra,0x0
 668:	e16080e7          	jalr	-490(ra) # 47a <vprintf>
}
 66c:	60e2                	ld	ra,24(sp)
 66e:	6442                	ld	s0,16(sp)
 670:	6161                	add	sp,sp,80
 672:	8082                	ret

0000000000000674 <printf>:

void
printf(const char *fmt, ...)
{
 674:	711d                	add	sp,sp,-96
 676:	ec06                	sd	ra,24(sp)
 678:	e822                	sd	s0,16(sp)
 67a:	1000                	add	s0,sp,32
 67c:	e40c                	sd	a1,8(s0)
 67e:	e810                	sd	a2,16(s0)
 680:	ec14                	sd	a3,24(s0)
 682:	f018                	sd	a4,32(s0)
 684:	f41c                	sd	a5,40(s0)
 686:	03043823          	sd	a6,48(s0)
 68a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 68e:	00840613          	add	a2,s0,8
 692:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 696:	85aa                	mv	a1,a0
 698:	4505                	li	a0,1
 69a:	00000097          	auipc	ra,0x0
 69e:	de0080e7          	jalr	-544(ra) # 47a <vprintf>
}
 6a2:	60e2                	ld	ra,24(sp)
 6a4:	6442                	ld	s0,16(sp)
 6a6:	6125                	add	sp,sp,96
 6a8:	8082                	ret

00000000000006aa <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6aa:	1141                	add	sp,sp,-16
 6ac:	e422                	sd	s0,8(sp)
 6ae:	0800                	add	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6b0:	ff050693          	add	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6b4:	00001797          	auipc	a5,0x1
 6b8:	94c7b783          	ld	a5,-1716(a5) # 1000 <freep>
 6bc:	a02d                	j	6e6 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6be:	4618                	lw	a4,8(a2)
 6c0:	9f2d                	addw	a4,a4,a1
 6c2:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6c6:	6398                	ld	a4,0(a5)
 6c8:	6310                	ld	a2,0(a4)
 6ca:	a83d                	j	708 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6cc:	ff852703          	lw	a4,-8(a0)
 6d0:	9f31                	addw	a4,a4,a2
 6d2:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6d4:	ff053683          	ld	a3,-16(a0)
 6d8:	a091                	j	71c <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6da:	6398                	ld	a4,0(a5)
 6dc:	00e7e463          	bltu	a5,a4,6e4 <free+0x3a>
 6e0:	00e6ea63          	bltu	a3,a4,6f4 <free+0x4a>
{
 6e4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6e6:	fed7fae3          	bgeu	a5,a3,6da <free+0x30>
 6ea:	6398                	ld	a4,0(a5)
 6ec:	00e6e463          	bltu	a3,a4,6f4 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6f0:	fee7eae3          	bltu	a5,a4,6e4 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6f4:	ff852583          	lw	a1,-8(a0)
 6f8:	6390                	ld	a2,0(a5)
 6fa:	02059813          	sll	a6,a1,0x20
 6fe:	01c85713          	srl	a4,a6,0x1c
 702:	9736                	add	a4,a4,a3
 704:	fae60de3          	beq	a2,a4,6be <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 708:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 70c:	4790                	lw	a2,8(a5)
 70e:	02061593          	sll	a1,a2,0x20
 712:	01c5d713          	srl	a4,a1,0x1c
 716:	973e                	add	a4,a4,a5
 718:	fae68ae3          	beq	a3,a4,6cc <free+0x22>
    p->s.ptr = bp->s.ptr;
 71c:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 71e:	00001717          	auipc	a4,0x1
 722:	8ef73123          	sd	a5,-1822(a4) # 1000 <freep>
}
 726:	6422                	ld	s0,8(sp)
 728:	0141                	add	sp,sp,16
 72a:	8082                	ret

000000000000072c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 72c:	7139                	add	sp,sp,-64
 72e:	fc06                	sd	ra,56(sp)
 730:	f822                	sd	s0,48(sp)
 732:	f426                	sd	s1,40(sp)
 734:	f04a                	sd	s2,32(sp)
 736:	ec4e                	sd	s3,24(sp)
 738:	e852                	sd	s4,16(sp)
 73a:	e456                	sd	s5,8(sp)
 73c:	e05a                	sd	s6,0(sp)
 73e:	0080                	add	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 740:	02051493          	sll	s1,a0,0x20
 744:	9081                	srl	s1,s1,0x20
 746:	04bd                	add	s1,s1,15
 748:	8091                	srl	s1,s1,0x4
 74a:	0014899b          	addw	s3,s1,1
 74e:	0485                	add	s1,s1,1
  if((prevp = freep) == 0){
 750:	00001517          	auipc	a0,0x1
 754:	8b053503          	ld	a0,-1872(a0) # 1000 <freep>
 758:	c515                	beqz	a0,784 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 75a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 75c:	4798                	lw	a4,8(a5)
 75e:	02977f63          	bgeu	a4,s1,79c <malloc+0x70>
  if(nu < 4096)
 762:	8a4e                	mv	s4,s3
 764:	0009871b          	sext.w	a4,s3
 768:	6685                	lui	a3,0x1
 76a:	00d77363          	bgeu	a4,a3,770 <malloc+0x44>
 76e:	6a05                	lui	s4,0x1
 770:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 774:	004a1a1b          	sllw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 778:	00001917          	auipc	s2,0x1
 77c:	88890913          	add	s2,s2,-1912 # 1000 <freep>
  if(p == (char*)-1)
 780:	5afd                	li	s5,-1
 782:	a895                	j	7f6 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 784:	00001797          	auipc	a5,0x1
 788:	c8c78793          	add	a5,a5,-884 # 1410 <base>
 78c:	00001717          	auipc	a4,0x1
 790:	86f73a23          	sd	a5,-1932(a4) # 1000 <freep>
 794:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 796:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 79a:	b7e1                	j	762 <malloc+0x36>
      if(p->s.size == nunits)
 79c:	02e48c63          	beq	s1,a4,7d4 <malloc+0xa8>
        p->s.size -= nunits;
 7a0:	4137073b          	subw	a4,a4,s3
 7a4:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7a6:	02071693          	sll	a3,a4,0x20
 7aa:	01c6d713          	srl	a4,a3,0x1c
 7ae:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7b0:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7b4:	00001717          	auipc	a4,0x1
 7b8:	84a73623          	sd	a0,-1972(a4) # 1000 <freep>
      return (void*)(p + 1);
 7bc:	01078513          	add	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7c0:	70e2                	ld	ra,56(sp)
 7c2:	7442                	ld	s0,48(sp)
 7c4:	74a2                	ld	s1,40(sp)
 7c6:	7902                	ld	s2,32(sp)
 7c8:	69e2                	ld	s3,24(sp)
 7ca:	6a42                	ld	s4,16(sp)
 7cc:	6aa2                	ld	s5,8(sp)
 7ce:	6b02                	ld	s6,0(sp)
 7d0:	6121                	add	sp,sp,64
 7d2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7d4:	6398                	ld	a4,0(a5)
 7d6:	e118                	sd	a4,0(a0)
 7d8:	bff1                	j	7b4 <malloc+0x88>
  hp->s.size = nu;
 7da:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7de:	0541                	add	a0,a0,16
 7e0:	00000097          	auipc	ra,0x0
 7e4:	eca080e7          	jalr	-310(ra) # 6aa <free>
  return freep;
 7e8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7ec:	d971                	beqz	a0,7c0 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7ee:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7f0:	4798                	lw	a4,8(a5)
 7f2:	fa9775e3          	bgeu	a4,s1,79c <malloc+0x70>
    if(p == freep)
 7f6:	00093703          	ld	a4,0(s2)
 7fa:	853e                	mv	a0,a5
 7fc:	fef719e3          	bne	a4,a5,7ee <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 800:	8552                	mv	a0,s4
 802:	00000097          	auipc	ra,0x0
 806:	b72080e7          	jalr	-1166(ra) # 374 <sbrk>
  if(p == (char*)-1)
 80a:	fd5518e3          	bne	a0,s5,7da <malloc+0xae>
        return 0;
 80e:	4501                	li	a0,0
 810:	bf45                	j	7c0 <malloc+0x94>
