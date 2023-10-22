
user/_filenum:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/param.h"


int
main(int argc, char *argv[])
{  
   0:	1101                	add	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	1000                	add	s0,sp,32
  int files = getfilenum(getpid());
   a:	00000097          	auipc	ra,0x0
   e:	338080e7          	jalr	824(ra) # 342 <getpid>
  12:	00000097          	auipc	ra,0x0
  16:	350080e7          	jalr	848(ra) # 362 <getfilenum>
  1a:	84aa                	mv	s1,a0
  fprintf(1, "%d\n", files);
  1c:	862a                	mv	a2,a0
  1e:	00000597          	auipc	a1,0x0
  22:	7c258593          	add	a1,a1,1986 # 7e0 <malloc+0xe6>
  26:	4505                	li	a0,1
  28:	00000097          	auipc	ra,0x0
  2c:	5ec080e7          	jalr	1516(ra) # 614 <fprintf>
  return files;
  exit(0);
  30:	8526                	mv	a0,s1
  32:	60e2                	ld	ra,24(sp)
  34:	6442                	ld	s0,16(sp)
  36:	64a2                	ld	s1,8(sp)
  38:	6105                	add	sp,sp,32
  3a:	8082                	ret

000000000000003c <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  3c:	1141                	add	sp,sp,-16
  3e:	e406                	sd	ra,8(sp)
  40:	e022                	sd	s0,0(sp)
  42:	0800                	add	s0,sp,16
  extern int main();
  main();
  44:	00000097          	auipc	ra,0x0
  48:	fbc080e7          	jalr	-68(ra) # 0 <main>
  exit(0);
  4c:	4501                	li	a0,0
  4e:	00000097          	auipc	ra,0x0
  52:	274080e7          	jalr	628(ra) # 2c2 <exit>

0000000000000056 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  56:	1141                	add	sp,sp,-16
  58:	e422                	sd	s0,8(sp)
  5a:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  5c:	87aa                	mv	a5,a0
  5e:	0585                	add	a1,a1,1
  60:	0785                	add	a5,a5,1
  62:	fff5c703          	lbu	a4,-1(a1)
  66:	fee78fa3          	sb	a4,-1(a5)
  6a:	fb75                	bnez	a4,5e <strcpy+0x8>
    ;
  return os;
}
  6c:	6422                	ld	s0,8(sp)
  6e:	0141                	add	sp,sp,16
  70:	8082                	ret

0000000000000072 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  72:	1141                	add	sp,sp,-16
  74:	e422                	sd	s0,8(sp)
  76:	0800                	add	s0,sp,16
  while(*p && *p == *q)
  78:	00054783          	lbu	a5,0(a0)
  7c:	cb91                	beqz	a5,90 <strcmp+0x1e>
  7e:	0005c703          	lbu	a4,0(a1)
  82:	00f71763          	bne	a4,a5,90 <strcmp+0x1e>
    p++, q++;
  86:	0505                	add	a0,a0,1
  88:	0585                	add	a1,a1,1
  while(*p && *p == *q)
  8a:	00054783          	lbu	a5,0(a0)
  8e:	fbe5                	bnez	a5,7e <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  90:	0005c503          	lbu	a0,0(a1)
}
  94:	40a7853b          	subw	a0,a5,a0
  98:	6422                	ld	s0,8(sp)
  9a:	0141                	add	sp,sp,16
  9c:	8082                	ret

000000000000009e <strlen>:

uint
strlen(const char *s)
{
  9e:	1141                	add	sp,sp,-16
  a0:	e422                	sd	s0,8(sp)
  a2:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  a4:	00054783          	lbu	a5,0(a0)
  a8:	cf91                	beqz	a5,c4 <strlen+0x26>
  aa:	0505                	add	a0,a0,1
  ac:	87aa                	mv	a5,a0
  ae:	86be                	mv	a3,a5
  b0:	0785                	add	a5,a5,1
  b2:	fff7c703          	lbu	a4,-1(a5)
  b6:	ff65                	bnez	a4,ae <strlen+0x10>
  b8:	40a6853b          	subw	a0,a3,a0
  bc:	2505                	addw	a0,a0,1
    ;
  return n;
}
  be:	6422                	ld	s0,8(sp)
  c0:	0141                	add	sp,sp,16
  c2:	8082                	ret
  for(n = 0; s[n]; n++)
  c4:	4501                	li	a0,0
  c6:	bfe5                	j	be <strlen+0x20>

00000000000000c8 <memset>:

void*
memset(void *dst, int c, uint n)
{
  c8:	1141                	add	sp,sp,-16
  ca:	e422                	sd	s0,8(sp)
  cc:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  ce:	ca19                	beqz	a2,e4 <memset+0x1c>
  d0:	87aa                	mv	a5,a0
  d2:	1602                	sll	a2,a2,0x20
  d4:	9201                	srl	a2,a2,0x20
  d6:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  da:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  de:	0785                	add	a5,a5,1
  e0:	fee79de3          	bne	a5,a4,da <memset+0x12>
  }
  return dst;
}
  e4:	6422                	ld	s0,8(sp)
  e6:	0141                	add	sp,sp,16
  e8:	8082                	ret

00000000000000ea <strchr>:

char*
strchr(const char *s, char c)
{
  ea:	1141                	add	sp,sp,-16
  ec:	e422                	sd	s0,8(sp)
  ee:	0800                	add	s0,sp,16
  for(; *s; s++)
  f0:	00054783          	lbu	a5,0(a0)
  f4:	cb99                	beqz	a5,10a <strchr+0x20>
    if(*s == c)
  f6:	00f58763          	beq	a1,a5,104 <strchr+0x1a>
  for(; *s; s++)
  fa:	0505                	add	a0,a0,1
  fc:	00054783          	lbu	a5,0(a0)
 100:	fbfd                	bnez	a5,f6 <strchr+0xc>
      return (char*)s;
  return 0;
 102:	4501                	li	a0,0
}
 104:	6422                	ld	s0,8(sp)
 106:	0141                	add	sp,sp,16
 108:	8082                	ret
  return 0;
 10a:	4501                	li	a0,0
 10c:	bfe5                	j	104 <strchr+0x1a>

000000000000010e <gets>:

char*
gets(char *buf, int max)
{
 10e:	711d                	add	sp,sp,-96
 110:	ec86                	sd	ra,88(sp)
 112:	e8a2                	sd	s0,80(sp)
 114:	e4a6                	sd	s1,72(sp)
 116:	e0ca                	sd	s2,64(sp)
 118:	fc4e                	sd	s3,56(sp)
 11a:	f852                	sd	s4,48(sp)
 11c:	f456                	sd	s5,40(sp)
 11e:	f05a                	sd	s6,32(sp)
 120:	ec5e                	sd	s7,24(sp)
 122:	1080                	add	s0,sp,96
 124:	8baa                	mv	s7,a0
 126:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 128:	892a                	mv	s2,a0
 12a:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 12c:	4aa9                	li	s5,10
 12e:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 130:	89a6                	mv	s3,s1
 132:	2485                	addw	s1,s1,1
 134:	0344d863          	bge	s1,s4,164 <gets+0x56>
    cc = read(0, &c, 1);
 138:	4605                	li	a2,1
 13a:	faf40593          	add	a1,s0,-81
 13e:	4501                	li	a0,0
 140:	00000097          	auipc	ra,0x0
 144:	19a080e7          	jalr	410(ra) # 2da <read>
    if(cc < 1)
 148:	00a05e63          	blez	a0,164 <gets+0x56>
    buf[i++] = c;
 14c:	faf44783          	lbu	a5,-81(s0)
 150:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 154:	01578763          	beq	a5,s5,162 <gets+0x54>
 158:	0905                	add	s2,s2,1
 15a:	fd679be3          	bne	a5,s6,130 <gets+0x22>
  for(i=0; i+1 < max; ){
 15e:	89a6                	mv	s3,s1
 160:	a011                	j	164 <gets+0x56>
 162:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 164:	99de                	add	s3,s3,s7
 166:	00098023          	sb	zero,0(s3)
  return buf;
}
 16a:	855e                	mv	a0,s7
 16c:	60e6                	ld	ra,88(sp)
 16e:	6446                	ld	s0,80(sp)
 170:	64a6                	ld	s1,72(sp)
 172:	6906                	ld	s2,64(sp)
 174:	79e2                	ld	s3,56(sp)
 176:	7a42                	ld	s4,48(sp)
 178:	7aa2                	ld	s5,40(sp)
 17a:	7b02                	ld	s6,32(sp)
 17c:	6be2                	ld	s7,24(sp)
 17e:	6125                	add	sp,sp,96
 180:	8082                	ret

0000000000000182 <stat>:

int
stat(const char *n, struct stat *st)
{
 182:	1101                	add	sp,sp,-32
 184:	ec06                	sd	ra,24(sp)
 186:	e822                	sd	s0,16(sp)
 188:	e426                	sd	s1,8(sp)
 18a:	e04a                	sd	s2,0(sp)
 18c:	1000                	add	s0,sp,32
 18e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 190:	4581                	li	a1,0
 192:	00000097          	auipc	ra,0x0
 196:	170080e7          	jalr	368(ra) # 302 <open>
  if(fd < 0)
 19a:	02054563          	bltz	a0,1c4 <stat+0x42>
 19e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1a0:	85ca                	mv	a1,s2
 1a2:	00000097          	auipc	ra,0x0
 1a6:	178080e7          	jalr	376(ra) # 31a <fstat>
 1aa:	892a                	mv	s2,a0
  close(fd);
 1ac:	8526                	mv	a0,s1
 1ae:	00000097          	auipc	ra,0x0
 1b2:	13c080e7          	jalr	316(ra) # 2ea <close>
  return r;
}
 1b6:	854a                	mv	a0,s2
 1b8:	60e2                	ld	ra,24(sp)
 1ba:	6442                	ld	s0,16(sp)
 1bc:	64a2                	ld	s1,8(sp)
 1be:	6902                	ld	s2,0(sp)
 1c0:	6105                	add	sp,sp,32
 1c2:	8082                	ret
    return -1;
 1c4:	597d                	li	s2,-1
 1c6:	bfc5                	j	1b6 <stat+0x34>

00000000000001c8 <atoi>:

int
atoi(const char *s)
{
 1c8:	1141                	add	sp,sp,-16
 1ca:	e422                	sd	s0,8(sp)
 1cc:	0800                	add	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1ce:	00054683          	lbu	a3,0(a0)
 1d2:	fd06879b          	addw	a5,a3,-48
 1d6:	0ff7f793          	zext.b	a5,a5
 1da:	4625                	li	a2,9
 1dc:	02f66863          	bltu	a2,a5,20c <atoi+0x44>
 1e0:	872a                	mv	a4,a0
  n = 0;
 1e2:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1e4:	0705                	add	a4,a4,1
 1e6:	0025179b          	sllw	a5,a0,0x2
 1ea:	9fa9                	addw	a5,a5,a0
 1ec:	0017979b          	sllw	a5,a5,0x1
 1f0:	9fb5                	addw	a5,a5,a3
 1f2:	fd07851b          	addw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1f6:	00074683          	lbu	a3,0(a4)
 1fa:	fd06879b          	addw	a5,a3,-48
 1fe:	0ff7f793          	zext.b	a5,a5
 202:	fef671e3          	bgeu	a2,a5,1e4 <atoi+0x1c>
  return n;
}
 206:	6422                	ld	s0,8(sp)
 208:	0141                	add	sp,sp,16
 20a:	8082                	ret
  n = 0;
 20c:	4501                	li	a0,0
 20e:	bfe5                	j	206 <atoi+0x3e>

0000000000000210 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 210:	1141                	add	sp,sp,-16
 212:	e422                	sd	s0,8(sp)
 214:	0800                	add	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 216:	02b57463          	bgeu	a0,a1,23e <memmove+0x2e>
    while(n-- > 0)
 21a:	00c05f63          	blez	a2,238 <memmove+0x28>
 21e:	1602                	sll	a2,a2,0x20
 220:	9201                	srl	a2,a2,0x20
 222:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 226:	872a                	mv	a4,a0
      *dst++ = *src++;
 228:	0585                	add	a1,a1,1
 22a:	0705                	add	a4,a4,1
 22c:	fff5c683          	lbu	a3,-1(a1)
 230:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 234:	fee79ae3          	bne	a5,a4,228 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 238:	6422                	ld	s0,8(sp)
 23a:	0141                	add	sp,sp,16
 23c:	8082                	ret
    dst += n;
 23e:	00c50733          	add	a4,a0,a2
    src += n;
 242:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 244:	fec05ae3          	blez	a2,238 <memmove+0x28>
 248:	fff6079b          	addw	a5,a2,-1
 24c:	1782                	sll	a5,a5,0x20
 24e:	9381                	srl	a5,a5,0x20
 250:	fff7c793          	not	a5,a5
 254:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 256:	15fd                	add	a1,a1,-1
 258:	177d                	add	a4,a4,-1
 25a:	0005c683          	lbu	a3,0(a1)
 25e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 262:	fee79ae3          	bne	a5,a4,256 <memmove+0x46>
 266:	bfc9                	j	238 <memmove+0x28>

0000000000000268 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 268:	1141                	add	sp,sp,-16
 26a:	e422                	sd	s0,8(sp)
 26c:	0800                	add	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 26e:	ca05                	beqz	a2,29e <memcmp+0x36>
 270:	fff6069b          	addw	a3,a2,-1
 274:	1682                	sll	a3,a3,0x20
 276:	9281                	srl	a3,a3,0x20
 278:	0685                	add	a3,a3,1
 27a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 27c:	00054783          	lbu	a5,0(a0)
 280:	0005c703          	lbu	a4,0(a1)
 284:	00e79863          	bne	a5,a4,294 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 288:	0505                	add	a0,a0,1
    p2++;
 28a:	0585                	add	a1,a1,1
  while (n-- > 0) {
 28c:	fed518e3          	bne	a0,a3,27c <memcmp+0x14>
  }
  return 0;
 290:	4501                	li	a0,0
 292:	a019                	j	298 <memcmp+0x30>
      return *p1 - *p2;
 294:	40e7853b          	subw	a0,a5,a4
}
 298:	6422                	ld	s0,8(sp)
 29a:	0141                	add	sp,sp,16
 29c:	8082                	ret
  return 0;
 29e:	4501                	li	a0,0
 2a0:	bfe5                	j	298 <memcmp+0x30>

00000000000002a2 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2a2:	1141                	add	sp,sp,-16
 2a4:	e406                	sd	ra,8(sp)
 2a6:	e022                	sd	s0,0(sp)
 2a8:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
 2aa:	00000097          	auipc	ra,0x0
 2ae:	f66080e7          	jalr	-154(ra) # 210 <memmove>
}
 2b2:	60a2                	ld	ra,8(sp)
 2b4:	6402                	ld	s0,0(sp)
 2b6:	0141                	add	sp,sp,16
 2b8:	8082                	ret

00000000000002ba <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2ba:	4885                	li	a7,1
 ecall
 2bc:	00000073          	ecall
 ret
 2c0:	8082                	ret

00000000000002c2 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2c2:	4889                	li	a7,2
 ecall
 2c4:	00000073          	ecall
 ret
 2c8:	8082                	ret

00000000000002ca <wait>:
.global wait
wait:
 li a7, SYS_wait
 2ca:	488d                	li	a7,3
 ecall
 2cc:	00000073          	ecall
 ret
 2d0:	8082                	ret

00000000000002d2 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2d2:	4891                	li	a7,4
 ecall
 2d4:	00000073          	ecall
 ret
 2d8:	8082                	ret

00000000000002da <read>:
.global read
read:
 li a7, SYS_read
 2da:	4895                	li	a7,5
 ecall
 2dc:	00000073          	ecall
 ret
 2e0:	8082                	ret

00000000000002e2 <write>:
.global write
write:
 li a7, SYS_write
 2e2:	48c1                	li	a7,16
 ecall
 2e4:	00000073          	ecall
 ret
 2e8:	8082                	ret

00000000000002ea <close>:
.global close
close:
 li a7, SYS_close
 2ea:	48d5                	li	a7,21
 ecall
 2ec:	00000073          	ecall
 ret
 2f0:	8082                	ret

00000000000002f2 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2f2:	4899                	li	a7,6
 ecall
 2f4:	00000073          	ecall
 ret
 2f8:	8082                	ret

00000000000002fa <exec>:
.global exec
exec:
 li a7, SYS_exec
 2fa:	489d                	li	a7,7
 ecall
 2fc:	00000073          	ecall
 ret
 300:	8082                	ret

0000000000000302 <open>:
.global open
open:
 li a7, SYS_open
 302:	48bd                	li	a7,15
 ecall
 304:	00000073          	ecall
 ret
 308:	8082                	ret

000000000000030a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 30a:	48c5                	li	a7,17
 ecall
 30c:	00000073          	ecall
 ret
 310:	8082                	ret

0000000000000312 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 312:	48c9                	li	a7,18
 ecall
 314:	00000073          	ecall
 ret
 318:	8082                	ret

000000000000031a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 31a:	48a1                	li	a7,8
 ecall
 31c:	00000073          	ecall
 ret
 320:	8082                	ret

0000000000000322 <link>:
.global link
link:
 li a7, SYS_link
 322:	48cd                	li	a7,19
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 32a:	48d1                	li	a7,20
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 332:	48a5                	li	a7,9
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <dup>:
.global dup
dup:
 li a7, SYS_dup
 33a:	48a9                	li	a7,10
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 342:	48ad                	li	a7,11
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 34a:	48b1                	li	a7,12
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 352:	48b5                	li	a7,13
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 35a:	48b9                	li	a7,14
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <getfilenum>:
.global getfilenum
getfilenum:
 li a7, SYS_getfilenum
 362:	48d9                	li	a7,22
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 36a:	48dd                	li	a7,23
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <getpinfo>:
.global getpinfo
getpinfo:
 li a7, SYS_getpinfo
 372:	48e1                	li	a7,24
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 37a:	1101                	add	sp,sp,-32
 37c:	ec06                	sd	ra,24(sp)
 37e:	e822                	sd	s0,16(sp)
 380:	1000                	add	s0,sp,32
 382:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 386:	4605                	li	a2,1
 388:	fef40593          	add	a1,s0,-17
 38c:	00000097          	auipc	ra,0x0
 390:	f56080e7          	jalr	-170(ra) # 2e2 <write>
}
 394:	60e2                	ld	ra,24(sp)
 396:	6442                	ld	s0,16(sp)
 398:	6105                	add	sp,sp,32
 39a:	8082                	ret

000000000000039c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 39c:	7139                	add	sp,sp,-64
 39e:	fc06                	sd	ra,56(sp)
 3a0:	f822                	sd	s0,48(sp)
 3a2:	f426                	sd	s1,40(sp)
 3a4:	f04a                	sd	s2,32(sp)
 3a6:	ec4e                	sd	s3,24(sp)
 3a8:	0080                	add	s0,sp,64
 3aa:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3ac:	c299                	beqz	a3,3b2 <printint+0x16>
 3ae:	0805c963          	bltz	a1,440 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3b2:	2581                	sext.w	a1,a1
  neg = 0;
 3b4:	4881                	li	a7,0
 3b6:	fc040693          	add	a3,s0,-64
  }

  i = 0;
 3ba:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3bc:	2601                	sext.w	a2,a2
 3be:	00000517          	auipc	a0,0x0
 3c2:	48a50513          	add	a0,a0,1162 # 848 <digits>
 3c6:	883a                	mv	a6,a4
 3c8:	2705                	addw	a4,a4,1
 3ca:	02c5f7bb          	remuw	a5,a1,a2
 3ce:	1782                	sll	a5,a5,0x20
 3d0:	9381                	srl	a5,a5,0x20
 3d2:	97aa                	add	a5,a5,a0
 3d4:	0007c783          	lbu	a5,0(a5)
 3d8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3dc:	0005879b          	sext.w	a5,a1
 3e0:	02c5d5bb          	divuw	a1,a1,a2
 3e4:	0685                	add	a3,a3,1
 3e6:	fec7f0e3          	bgeu	a5,a2,3c6 <printint+0x2a>
  if(neg)
 3ea:	00088c63          	beqz	a7,402 <printint+0x66>
    buf[i++] = '-';
 3ee:	fd070793          	add	a5,a4,-48
 3f2:	00878733          	add	a4,a5,s0
 3f6:	02d00793          	li	a5,45
 3fa:	fef70823          	sb	a5,-16(a4)
 3fe:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
 402:	02e05863          	blez	a4,432 <printint+0x96>
 406:	fc040793          	add	a5,s0,-64
 40a:	00e78933          	add	s2,a5,a4
 40e:	fff78993          	add	s3,a5,-1
 412:	99ba                	add	s3,s3,a4
 414:	377d                	addw	a4,a4,-1
 416:	1702                	sll	a4,a4,0x20
 418:	9301                	srl	a4,a4,0x20
 41a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 41e:	fff94583          	lbu	a1,-1(s2)
 422:	8526                	mv	a0,s1
 424:	00000097          	auipc	ra,0x0
 428:	f56080e7          	jalr	-170(ra) # 37a <putc>
  while(--i >= 0)
 42c:	197d                	add	s2,s2,-1
 42e:	ff3918e3          	bne	s2,s3,41e <printint+0x82>
}
 432:	70e2                	ld	ra,56(sp)
 434:	7442                	ld	s0,48(sp)
 436:	74a2                	ld	s1,40(sp)
 438:	7902                	ld	s2,32(sp)
 43a:	69e2                	ld	s3,24(sp)
 43c:	6121                	add	sp,sp,64
 43e:	8082                	ret
    x = -xx;
 440:	40b005bb          	negw	a1,a1
    neg = 1;
 444:	4885                	li	a7,1
    x = -xx;
 446:	bf85                	j	3b6 <printint+0x1a>

0000000000000448 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 448:	715d                	add	sp,sp,-80
 44a:	e486                	sd	ra,72(sp)
 44c:	e0a2                	sd	s0,64(sp)
 44e:	fc26                	sd	s1,56(sp)
 450:	f84a                	sd	s2,48(sp)
 452:	f44e                	sd	s3,40(sp)
 454:	f052                	sd	s4,32(sp)
 456:	ec56                	sd	s5,24(sp)
 458:	e85a                	sd	s6,16(sp)
 45a:	e45e                	sd	s7,8(sp)
 45c:	e062                	sd	s8,0(sp)
 45e:	0880                	add	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 460:	0005c903          	lbu	s2,0(a1)
 464:	18090c63          	beqz	s2,5fc <vprintf+0x1b4>
 468:	8aaa                	mv	s5,a0
 46a:	8bb2                	mv	s7,a2
 46c:	00158493          	add	s1,a1,1
  state = 0;
 470:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 472:	02500a13          	li	s4,37
 476:	4b55                	li	s6,21
 478:	a839                	j	496 <vprintf+0x4e>
        putc(fd, c);
 47a:	85ca                	mv	a1,s2
 47c:	8556                	mv	a0,s5
 47e:	00000097          	auipc	ra,0x0
 482:	efc080e7          	jalr	-260(ra) # 37a <putc>
 486:	a019                	j	48c <vprintf+0x44>
    } else if(state == '%'){
 488:	01498d63          	beq	s3,s4,4a2 <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 48c:	0485                	add	s1,s1,1
 48e:	fff4c903          	lbu	s2,-1(s1)
 492:	16090563          	beqz	s2,5fc <vprintf+0x1b4>
    if(state == 0){
 496:	fe0999e3          	bnez	s3,488 <vprintf+0x40>
      if(c == '%'){
 49a:	ff4910e3          	bne	s2,s4,47a <vprintf+0x32>
        state = '%';
 49e:	89d2                	mv	s3,s4
 4a0:	b7f5                	j	48c <vprintf+0x44>
      if(c == 'd'){
 4a2:	13490263          	beq	s2,s4,5c6 <vprintf+0x17e>
 4a6:	f9d9079b          	addw	a5,s2,-99
 4aa:	0ff7f793          	zext.b	a5,a5
 4ae:	12fb6563          	bltu	s6,a5,5d8 <vprintf+0x190>
 4b2:	f9d9079b          	addw	a5,s2,-99
 4b6:	0ff7f713          	zext.b	a4,a5
 4ba:	10eb6f63          	bltu	s6,a4,5d8 <vprintf+0x190>
 4be:	00271793          	sll	a5,a4,0x2
 4c2:	00000717          	auipc	a4,0x0
 4c6:	32e70713          	add	a4,a4,814 # 7f0 <malloc+0xf6>
 4ca:	97ba                	add	a5,a5,a4
 4cc:	439c                	lw	a5,0(a5)
 4ce:	97ba                	add	a5,a5,a4
 4d0:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4d2:	008b8913          	add	s2,s7,8
 4d6:	4685                	li	a3,1
 4d8:	4629                	li	a2,10
 4da:	000ba583          	lw	a1,0(s7)
 4de:	8556                	mv	a0,s5
 4e0:	00000097          	auipc	ra,0x0
 4e4:	ebc080e7          	jalr	-324(ra) # 39c <printint>
 4e8:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 4ea:	4981                	li	s3,0
 4ec:	b745                	j	48c <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4ee:	008b8913          	add	s2,s7,8
 4f2:	4681                	li	a3,0
 4f4:	4629                	li	a2,10
 4f6:	000ba583          	lw	a1,0(s7)
 4fa:	8556                	mv	a0,s5
 4fc:	00000097          	auipc	ra,0x0
 500:	ea0080e7          	jalr	-352(ra) # 39c <printint>
 504:	8bca                	mv	s7,s2
      state = 0;
 506:	4981                	li	s3,0
 508:	b751                	j	48c <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 50a:	008b8913          	add	s2,s7,8
 50e:	4681                	li	a3,0
 510:	4641                	li	a2,16
 512:	000ba583          	lw	a1,0(s7)
 516:	8556                	mv	a0,s5
 518:	00000097          	auipc	ra,0x0
 51c:	e84080e7          	jalr	-380(ra) # 39c <printint>
 520:	8bca                	mv	s7,s2
      state = 0;
 522:	4981                	li	s3,0
 524:	b7a5                	j	48c <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 526:	008b8c13          	add	s8,s7,8
 52a:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 52e:	03000593          	li	a1,48
 532:	8556                	mv	a0,s5
 534:	00000097          	auipc	ra,0x0
 538:	e46080e7          	jalr	-442(ra) # 37a <putc>
  putc(fd, 'x');
 53c:	07800593          	li	a1,120
 540:	8556                	mv	a0,s5
 542:	00000097          	auipc	ra,0x0
 546:	e38080e7          	jalr	-456(ra) # 37a <putc>
 54a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 54c:	00000b97          	auipc	s7,0x0
 550:	2fcb8b93          	add	s7,s7,764 # 848 <digits>
 554:	03c9d793          	srl	a5,s3,0x3c
 558:	97de                	add	a5,a5,s7
 55a:	0007c583          	lbu	a1,0(a5)
 55e:	8556                	mv	a0,s5
 560:	00000097          	auipc	ra,0x0
 564:	e1a080e7          	jalr	-486(ra) # 37a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 568:	0992                	sll	s3,s3,0x4
 56a:	397d                	addw	s2,s2,-1
 56c:	fe0914e3          	bnez	s2,554 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 570:	8be2                	mv	s7,s8
      state = 0;
 572:	4981                	li	s3,0
 574:	bf21                	j	48c <vprintf+0x44>
        s = va_arg(ap, char*);
 576:	008b8993          	add	s3,s7,8
 57a:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 57e:	02090163          	beqz	s2,5a0 <vprintf+0x158>
        while(*s != 0){
 582:	00094583          	lbu	a1,0(s2)
 586:	c9a5                	beqz	a1,5f6 <vprintf+0x1ae>
          putc(fd, *s);
 588:	8556                	mv	a0,s5
 58a:	00000097          	auipc	ra,0x0
 58e:	df0080e7          	jalr	-528(ra) # 37a <putc>
          s++;
 592:	0905                	add	s2,s2,1
        while(*s != 0){
 594:	00094583          	lbu	a1,0(s2)
 598:	f9e5                	bnez	a1,588 <vprintf+0x140>
        s = va_arg(ap, char*);
 59a:	8bce                	mv	s7,s3
      state = 0;
 59c:	4981                	li	s3,0
 59e:	b5fd                	j	48c <vprintf+0x44>
          s = "(null)";
 5a0:	00000917          	auipc	s2,0x0
 5a4:	24890913          	add	s2,s2,584 # 7e8 <malloc+0xee>
        while(*s != 0){
 5a8:	02800593          	li	a1,40
 5ac:	bff1                	j	588 <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 5ae:	008b8913          	add	s2,s7,8
 5b2:	000bc583          	lbu	a1,0(s7)
 5b6:	8556                	mv	a0,s5
 5b8:	00000097          	auipc	ra,0x0
 5bc:	dc2080e7          	jalr	-574(ra) # 37a <putc>
 5c0:	8bca                	mv	s7,s2
      state = 0;
 5c2:	4981                	li	s3,0
 5c4:	b5e1                	j	48c <vprintf+0x44>
        putc(fd, c);
 5c6:	02500593          	li	a1,37
 5ca:	8556                	mv	a0,s5
 5cc:	00000097          	auipc	ra,0x0
 5d0:	dae080e7          	jalr	-594(ra) # 37a <putc>
      state = 0;
 5d4:	4981                	li	s3,0
 5d6:	bd5d                	j	48c <vprintf+0x44>
        putc(fd, '%');
 5d8:	02500593          	li	a1,37
 5dc:	8556                	mv	a0,s5
 5de:	00000097          	auipc	ra,0x0
 5e2:	d9c080e7          	jalr	-612(ra) # 37a <putc>
        putc(fd, c);
 5e6:	85ca                	mv	a1,s2
 5e8:	8556                	mv	a0,s5
 5ea:	00000097          	auipc	ra,0x0
 5ee:	d90080e7          	jalr	-624(ra) # 37a <putc>
      state = 0;
 5f2:	4981                	li	s3,0
 5f4:	bd61                	j	48c <vprintf+0x44>
        s = va_arg(ap, char*);
 5f6:	8bce                	mv	s7,s3
      state = 0;
 5f8:	4981                	li	s3,0
 5fa:	bd49                	j	48c <vprintf+0x44>
    }
  }
}
 5fc:	60a6                	ld	ra,72(sp)
 5fe:	6406                	ld	s0,64(sp)
 600:	74e2                	ld	s1,56(sp)
 602:	7942                	ld	s2,48(sp)
 604:	79a2                	ld	s3,40(sp)
 606:	7a02                	ld	s4,32(sp)
 608:	6ae2                	ld	s5,24(sp)
 60a:	6b42                	ld	s6,16(sp)
 60c:	6ba2                	ld	s7,8(sp)
 60e:	6c02                	ld	s8,0(sp)
 610:	6161                	add	sp,sp,80
 612:	8082                	ret

0000000000000614 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 614:	715d                	add	sp,sp,-80
 616:	ec06                	sd	ra,24(sp)
 618:	e822                	sd	s0,16(sp)
 61a:	1000                	add	s0,sp,32
 61c:	e010                	sd	a2,0(s0)
 61e:	e414                	sd	a3,8(s0)
 620:	e818                	sd	a4,16(s0)
 622:	ec1c                	sd	a5,24(s0)
 624:	03043023          	sd	a6,32(s0)
 628:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 62c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 630:	8622                	mv	a2,s0
 632:	00000097          	auipc	ra,0x0
 636:	e16080e7          	jalr	-490(ra) # 448 <vprintf>
}
 63a:	60e2                	ld	ra,24(sp)
 63c:	6442                	ld	s0,16(sp)
 63e:	6161                	add	sp,sp,80
 640:	8082                	ret

0000000000000642 <printf>:

void
printf(const char *fmt, ...)
{
 642:	711d                	add	sp,sp,-96
 644:	ec06                	sd	ra,24(sp)
 646:	e822                	sd	s0,16(sp)
 648:	1000                	add	s0,sp,32
 64a:	e40c                	sd	a1,8(s0)
 64c:	e810                	sd	a2,16(s0)
 64e:	ec14                	sd	a3,24(s0)
 650:	f018                	sd	a4,32(s0)
 652:	f41c                	sd	a5,40(s0)
 654:	03043823          	sd	a6,48(s0)
 658:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 65c:	00840613          	add	a2,s0,8
 660:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 664:	85aa                	mv	a1,a0
 666:	4505                	li	a0,1
 668:	00000097          	auipc	ra,0x0
 66c:	de0080e7          	jalr	-544(ra) # 448 <vprintf>
}
 670:	60e2                	ld	ra,24(sp)
 672:	6442                	ld	s0,16(sp)
 674:	6125                	add	sp,sp,96
 676:	8082                	ret

0000000000000678 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 678:	1141                	add	sp,sp,-16
 67a:	e422                	sd	s0,8(sp)
 67c:	0800                	add	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 67e:	ff050693          	add	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 682:	00001797          	auipc	a5,0x1
 686:	97e7b783          	ld	a5,-1666(a5) # 1000 <freep>
 68a:	a02d                	j	6b4 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 68c:	4618                	lw	a4,8(a2)
 68e:	9f2d                	addw	a4,a4,a1
 690:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 694:	6398                	ld	a4,0(a5)
 696:	6310                	ld	a2,0(a4)
 698:	a83d                	j	6d6 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 69a:	ff852703          	lw	a4,-8(a0)
 69e:	9f31                	addw	a4,a4,a2
 6a0:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6a2:	ff053683          	ld	a3,-16(a0)
 6a6:	a091                	j	6ea <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6a8:	6398                	ld	a4,0(a5)
 6aa:	00e7e463          	bltu	a5,a4,6b2 <free+0x3a>
 6ae:	00e6ea63          	bltu	a3,a4,6c2 <free+0x4a>
{
 6b2:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6b4:	fed7fae3          	bgeu	a5,a3,6a8 <free+0x30>
 6b8:	6398                	ld	a4,0(a5)
 6ba:	00e6e463          	bltu	a3,a4,6c2 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6be:	fee7eae3          	bltu	a5,a4,6b2 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6c2:	ff852583          	lw	a1,-8(a0)
 6c6:	6390                	ld	a2,0(a5)
 6c8:	02059813          	sll	a6,a1,0x20
 6cc:	01c85713          	srl	a4,a6,0x1c
 6d0:	9736                	add	a4,a4,a3
 6d2:	fae60de3          	beq	a2,a4,68c <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6d6:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6da:	4790                	lw	a2,8(a5)
 6dc:	02061593          	sll	a1,a2,0x20
 6e0:	01c5d713          	srl	a4,a1,0x1c
 6e4:	973e                	add	a4,a4,a5
 6e6:	fae68ae3          	beq	a3,a4,69a <free+0x22>
    p->s.ptr = bp->s.ptr;
 6ea:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 6ec:	00001717          	auipc	a4,0x1
 6f0:	90f73a23          	sd	a5,-1772(a4) # 1000 <freep>
}
 6f4:	6422                	ld	s0,8(sp)
 6f6:	0141                	add	sp,sp,16
 6f8:	8082                	ret

00000000000006fa <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6fa:	7139                	add	sp,sp,-64
 6fc:	fc06                	sd	ra,56(sp)
 6fe:	f822                	sd	s0,48(sp)
 700:	f426                	sd	s1,40(sp)
 702:	f04a                	sd	s2,32(sp)
 704:	ec4e                	sd	s3,24(sp)
 706:	e852                	sd	s4,16(sp)
 708:	e456                	sd	s5,8(sp)
 70a:	e05a                	sd	s6,0(sp)
 70c:	0080                	add	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 70e:	02051493          	sll	s1,a0,0x20
 712:	9081                	srl	s1,s1,0x20
 714:	04bd                	add	s1,s1,15
 716:	8091                	srl	s1,s1,0x4
 718:	0014899b          	addw	s3,s1,1
 71c:	0485                	add	s1,s1,1
  if((prevp = freep) == 0){
 71e:	00001517          	auipc	a0,0x1
 722:	8e253503          	ld	a0,-1822(a0) # 1000 <freep>
 726:	c515                	beqz	a0,752 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 728:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 72a:	4798                	lw	a4,8(a5)
 72c:	02977f63          	bgeu	a4,s1,76a <malloc+0x70>
  if(nu < 4096)
 730:	8a4e                	mv	s4,s3
 732:	0009871b          	sext.w	a4,s3
 736:	6685                	lui	a3,0x1
 738:	00d77363          	bgeu	a4,a3,73e <malloc+0x44>
 73c:	6a05                	lui	s4,0x1
 73e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 742:	004a1a1b          	sllw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 746:	00001917          	auipc	s2,0x1
 74a:	8ba90913          	add	s2,s2,-1862 # 1000 <freep>
  if(p == (char*)-1)
 74e:	5afd                	li	s5,-1
 750:	a895                	j	7c4 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 752:	00001797          	auipc	a5,0x1
 756:	8be78793          	add	a5,a5,-1858 # 1010 <base>
 75a:	00001717          	auipc	a4,0x1
 75e:	8af73323          	sd	a5,-1882(a4) # 1000 <freep>
 762:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 764:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 768:	b7e1                	j	730 <malloc+0x36>
      if(p->s.size == nunits)
 76a:	02e48c63          	beq	s1,a4,7a2 <malloc+0xa8>
        p->s.size -= nunits;
 76e:	4137073b          	subw	a4,a4,s3
 772:	c798                	sw	a4,8(a5)
        p += p->s.size;
 774:	02071693          	sll	a3,a4,0x20
 778:	01c6d713          	srl	a4,a3,0x1c
 77c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 77e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 782:	00001717          	auipc	a4,0x1
 786:	86a73f23          	sd	a0,-1922(a4) # 1000 <freep>
      return (void*)(p + 1);
 78a:	01078513          	add	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 78e:	70e2                	ld	ra,56(sp)
 790:	7442                	ld	s0,48(sp)
 792:	74a2                	ld	s1,40(sp)
 794:	7902                	ld	s2,32(sp)
 796:	69e2                	ld	s3,24(sp)
 798:	6a42                	ld	s4,16(sp)
 79a:	6aa2                	ld	s5,8(sp)
 79c:	6b02                	ld	s6,0(sp)
 79e:	6121                	add	sp,sp,64
 7a0:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7a2:	6398                	ld	a4,0(a5)
 7a4:	e118                	sd	a4,0(a0)
 7a6:	bff1                	j	782 <malloc+0x88>
  hp->s.size = nu;
 7a8:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7ac:	0541                	add	a0,a0,16
 7ae:	00000097          	auipc	ra,0x0
 7b2:	eca080e7          	jalr	-310(ra) # 678 <free>
  return freep;
 7b6:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7ba:	d971                	beqz	a0,78e <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7bc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7be:	4798                	lw	a4,8(a5)
 7c0:	fa9775e3          	bgeu	a4,s1,76a <malloc+0x70>
    if(p == freep)
 7c4:	00093703          	ld	a4,0(s2)
 7c8:	853e                	mv	a0,a5
 7ca:	fef719e3          	bne	a4,a5,7bc <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7ce:	8552                	mv	a0,s4
 7d0:	00000097          	auipc	ra,0x0
 7d4:	b7a080e7          	jalr	-1158(ra) # 34a <sbrk>
  if(p == (char*)-1)
 7d8:	fd5518e3          	bne	a0,s5,7a8 <malloc+0xae>
        return 0;
 7dc:	4501                	li	a0,0
 7de:	bf45                	j	78e <malloc+0x94>
