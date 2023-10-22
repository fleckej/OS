
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a9010113          	add	sp,sp,-1392 # 80008a90 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	add	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	add	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	add	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	sllw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	add	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	sll	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	sll	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	90070713          	add	a4,a4,-1792 # 80008950 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	e5e78793          	add	a5,a5,-418 # 80005ec0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	add	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	add	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd849f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	add	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srl	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	add	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	add	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	add	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	add	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	474080e7          	jalr	1140(ra) # 8000259e <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	780080e7          	jalr	1920(ra) # 800008ba <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addw	s2,s2,1
    80000144:	0485                	add	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	add	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	add	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	add	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000180:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	90c50513          	add	a0,a0,-1780 # 80010a90 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	8fc48493          	add	s1,s1,-1796 # 80010a90 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	98c90913          	add	s2,s2,-1652 # 80010b28 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00001097          	auipc	ra,0x1
    800001b8:	7f2080e7          	jalr	2034(ra) # 800019a6 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	1e6080e7          	jalr	486(ra) # 800023a2 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	f30080e7          	jalr	-208(ra) # 800020fa <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	8b270713          	add	a4,a4,-1870 # 80010a90 <cons>
    800001e6:	0017869b          	addw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	and	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	add	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	338080e7          	jalr	824(ra) # 80002548 <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
      break;

    dst++;
    8000021e:	0a05                	add	s4,s4,1
    --n;
    80000220:	39fd                	addw	s3,s3,-1

    if(c == '\n'){
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	86850513          	add	a0,a0,-1944 # 80010a90 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	85250513          	add	a0,a0,-1966 # 80010a90 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	a40080e7          	jalr	-1472(ra) # 80000c86 <release>
        return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	add	sp,sp,96
    80000264:	8082                	ret
      if(n < target){
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
        cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	8af72d23          	sw	a5,-1862(a4) # 80010b28 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	add	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
    uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	560080e7          	jalr	1376(ra) # 800007e8 <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	add	sp,sp,16
    80000296:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	54e080e7          	jalr	1358(ra) # 800007e8 <uartputc_sync>
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	542080e7          	jalr	1346(ra) # 800007e8 <uartputc_sync>
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	538080e7          	jalr	1336(ra) # 800007e8 <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ba:	1101                	add	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	add	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c8:	00010517          	auipc	a0,0x10
    800002cc:	7c850513          	add	a0,a0,1992 # 80010a90 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	902080e7          	jalr	-1790(ra) # 80000bd2 <acquire>

  switch(c){
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	306080e7          	jalr	774(ra) # 800025f4 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	79a50513          	add	a0,a0,1946 # 80010a90 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	988080e7          	jalr	-1656(ra) # 80000c86 <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	add	sp,sp,32
    80000310:	8082                	ret
  switch(c){
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031a:	00010717          	auipc	a4,0x10
    8000031e:	77670713          	add	a4,a4,1910 # 80010a90 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
      consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00010797          	auipc	a5,0x10
    80000348:	74c78793          	add	a5,a5,1868 # 80010a90 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	and	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00010797          	auipc	a5,0x10
    80000376:	7b67a783          	lw	a5,1974(a5) # 80010b28 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	70a70713          	add	a4,a4,1802 # 80010a90 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	6fa48493          	add	s1,s1,1786 # 80010a90 <cons>
    while(cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a4:	37fd                	addw	a5,a5,-1
    800003a6:	07f7f713          	and	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
    while(cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	6be70713          	add	a4,a4,1726 # 80010a90 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	74f72423          	sw	a5,1864(a4) # 80010b30 <cons+0xa0>
      consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
      consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	68278793          	add	a5,a5,1666 # 80010a90 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	and	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	6ec7ad23          	sw	a2,1786(a5) # 80010b2c <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	6ee50513          	add	a0,a0,1774 # 80010b28 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	d1c080e7          	jalr	-740(ra) # 8000215e <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void
consoleinit(void)
{
    8000044c:	1141                	add	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	add	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	63450513          	add	a0,a0,1588 # 80010a90 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00021797          	auipc	a5,0x21
    80000478:	bb478793          	add	a5,a5,-1100 # 80021028 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	add	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	add	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	add	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	add	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	add	a3,s0,-48

  i = 0;
    800004b2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b8a60613          	add	a2,a2,-1142 # 80008040 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	sll	a5,a5,0x20
    800004c8:	9381                	srl	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	add	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

  if(sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
    buf[i++] = '-';
    800004e6:	fe070793          	add	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	add	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	add	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addw	a4,a4,-1
    8000050e:	1702                	sll	a4,a4,0x20
    80000510:	9301                	srl	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
  while(--i >= 0)
    80000522:	14fd                	add	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	add	sp,sp,48
    80000532:	8082                	ret
    x = -xx;
    80000534:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
    x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053c:	1101                	add	sp,sp,-32
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	add	s0,sp,32
    80000546:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000548:	00010797          	auipc	a5,0x10
    8000054c:	6007a423          	sw	zero,1544(a5) # 80010b50 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ac850513          	add	a0,a0,-1336 # 80008018 <etext+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	b5e50513          	add	a0,a0,-1186 # 800080c8 <digits+0x88>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	38f72a23          	sw	a5,916(a4) # 80008910 <panicked>
  for(;;)
    80000584:	a001                	j	80000584 <panic+0x48>

0000000080000586 <printf>:
{
    80000586:	7131                	add	sp,sp,-192
    80000588:	fc86                	sd	ra,120(sp)
    8000058a:	f8a2                	sd	s0,112(sp)
    8000058c:	f4a6                	sd	s1,104(sp)
    8000058e:	f0ca                	sd	s2,96(sp)
    80000590:	ecce                	sd	s3,88(sp)
    80000592:	e8d2                	sd	s4,80(sp)
    80000594:	e4d6                	sd	s5,72(sp)
    80000596:	e0da                	sd	s6,64(sp)
    80000598:	fc5e                	sd	s7,56(sp)
    8000059a:	f862                	sd	s8,48(sp)
    8000059c:	f466                	sd	s9,40(sp)
    8000059e:	f06a                	sd	s10,32(sp)
    800005a0:	ec6e                	sd	s11,24(sp)
    800005a2:	0100                	add	s0,sp,128
    800005a4:	8a2a                	mv	s4,a0
    800005a6:	e40c                	sd	a1,8(s0)
    800005a8:	e810                	sd	a2,16(s0)
    800005aa:	ec14                	sd	a3,24(s0)
    800005ac:	f018                	sd	a4,32(s0)
    800005ae:	f41c                	sd	a5,40(s0)
    800005b0:	03043823          	sd	a6,48(s0)
    800005b4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b8:	00010d97          	auipc	s11,0x10
    800005bc:	598dad83          	lw	s11,1432(s11) # 80010b50 <pr+0x18>
  if(locking)
    800005c0:	020d9b63          	bnez	s11,800005f6 <printf+0x70>
  if (fmt == 0)
    800005c4:	040a0263          	beqz	s4,80000608 <printf+0x82>
  va_start(ap, fmt);
    800005c8:	00840793          	add	a5,s0,8
    800005cc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d0:	000a4503          	lbu	a0,0(s4)
    800005d4:	14050f63          	beqz	a0,80000732 <printf+0x1ac>
    800005d8:	4981                	li	s3,0
    if(c != '%'){
    800005da:	02500a93          	li	s5,37
    switch(c){
    800005de:	07000b93          	li	s7,112
  consputc('x');
    800005e2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e4:	00008b17          	auipc	s6,0x8
    800005e8:	a5cb0b13          	add	s6,s6,-1444 # 80008040 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00010517          	auipc	a0,0x10
    800005fa:	54250513          	add	a0,a0,1346 # 80010b38 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	5d4080e7          	jalr	1492(ra) # 80000bd2 <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a2050513          	add	a0,a0,-1504 # 80008028 <etext+0x28>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      consputc(c);
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	c60080e7          	jalr	-928(ra) # 80000278 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	2985                	addw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c503          	lbu	a0,0(a5)
    8000062a:	10050463          	beqz	a0,80000732 <printf+0x1ac>
    if(c != '%'){
    8000062e:	ff5515e3          	bne	a0,s5,80000618 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000632:	2985                	addw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c783          	lbu	a5,0(a5)
    8000063c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000640:	cbed                	beqz	a5,80000732 <printf+0x1ac>
    switch(c){
    80000642:	05778a63          	beq	a5,s7,80000696 <printf+0x110>
    80000646:	02fbf663          	bgeu	s7,a5,80000672 <printf+0xec>
    8000064a:	09978863          	beq	a5,s9,800006da <printf+0x154>
    8000064e:	07800713          	li	a4,120
    80000652:	0ce79563          	bne	a5,a4,8000071c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000656:	f8843783          	ld	a5,-120(s0)
    8000065a:	00878713          	add	a4,a5,8
    8000065e:	f8e43423          	sd	a4,-120(s0)
    80000662:	4605                	li	a2,1
    80000664:	85ea                	mv	a1,s10
    80000666:	4388                	lw	a0,0(a5)
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	e30080e7          	jalr	-464(ra) # 80000498 <printint>
      break;
    80000670:	bf45                	j	80000620 <printf+0x9a>
    switch(c){
    80000672:	09578f63          	beq	a5,s5,80000710 <printf+0x18a>
    80000676:	0b879363          	bne	a5,s8,8000071c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	add	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4605                	li	a2,1
    80000688:	45a9                	li	a1,10
    8000068a:	4388                	lw	a0,0(a5)
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	e0c080e7          	jalr	-500(ra) # 80000498 <printint>
      break;
    80000694:	b771                	j	80000620 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	add	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a6:	03000513          	li	a0,48
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bce080e7          	jalr	-1074(ra) # 80000278 <consputc>
  consputc('x');
    800006b2:	07800513          	li	a0,120
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bc2080e7          	jalr	-1086(ra) # 80000278 <consputc>
    800006be:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c0:	03c95793          	srl	a5,s2,0x3c
    800006c4:	97da                	add	a5,a5,s6
    800006c6:	0007c503          	lbu	a0,0(a5)
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bae080e7          	jalr	-1106(ra) # 80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d2:	0912                	sll	s2,s2,0x4
    800006d4:	34fd                	addw	s1,s1,-1
    800006d6:	f4ed                	bnez	s1,800006c0 <printf+0x13a>
    800006d8:	b7a1                	j	80000620 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006da:	f8843783          	ld	a5,-120(s0)
    800006de:	00878713          	add	a4,a5,8
    800006e2:	f8e43423          	sd	a4,-120(s0)
    800006e6:	6384                	ld	s1,0(a5)
    800006e8:	cc89                	beqz	s1,80000702 <printf+0x17c>
      for(; *s; s++)
    800006ea:	0004c503          	lbu	a0,0(s1)
    800006ee:	d90d                	beqz	a0,80000620 <printf+0x9a>
        consputc(*s);
    800006f0:	00000097          	auipc	ra,0x0
    800006f4:	b88080e7          	jalr	-1144(ra) # 80000278 <consputc>
      for(; *s; s++)
    800006f8:	0485                	add	s1,s1,1
    800006fa:	0004c503          	lbu	a0,0(s1)
    800006fe:	f96d                	bnez	a0,800006f0 <printf+0x16a>
    80000700:	b705                	j	80000620 <printf+0x9a>
        s = "(null)";
    80000702:	00008497          	auipc	s1,0x8
    80000706:	91e48493          	add	s1,s1,-1762 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070a:	02800513          	li	a0,40
    8000070e:	b7cd                	j	800006f0 <printf+0x16a>
      consputc('%');
    80000710:	8556                	mv	a0,s5
    80000712:	00000097          	auipc	ra,0x0
    80000716:	b66080e7          	jalr	-1178(ra) # 80000278 <consputc>
      break;
    8000071a:	b719                	j	80000620 <printf+0x9a>
      consputc('%');
    8000071c:	8556                	mv	a0,s5
    8000071e:	00000097          	auipc	ra,0x0
    80000722:	b5a080e7          	jalr	-1190(ra) # 80000278 <consputc>
      consputc(c);
    80000726:	8526                	mv	a0,s1
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b50080e7          	jalr	-1200(ra) # 80000278 <consputc>
      break;
    80000730:	bdc5                	j	80000620 <printf+0x9a>
  if(locking)
    80000732:	020d9163          	bnez	s11,80000754 <printf+0x1ce>
}
    80000736:	70e6                	ld	ra,120(sp)
    80000738:	7446                	ld	s0,112(sp)
    8000073a:	74a6                	ld	s1,104(sp)
    8000073c:	7906                	ld	s2,96(sp)
    8000073e:	69e6                	ld	s3,88(sp)
    80000740:	6a46                	ld	s4,80(sp)
    80000742:	6aa6                	ld	s5,72(sp)
    80000744:	6b06                	ld	s6,64(sp)
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	7c42                	ld	s8,48(sp)
    8000074a:	7ca2                	ld	s9,40(sp)
    8000074c:	7d02                	ld	s10,32(sp)
    8000074e:	6de2                	ld	s11,24(sp)
    80000750:	6129                	add	sp,sp,192
    80000752:	8082                	ret
    release(&pr.lock);
    80000754:	00010517          	auipc	a0,0x10
    80000758:	3e450513          	add	a0,a0,996 # 80010b38 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	52a080e7          	jalr	1322(ra) # 80000c86 <release>
}
    80000764:	bfc9                	j	80000736 <printf+0x1b0>

0000000080000766 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000766:	1101                	add	sp,sp,-32
    80000768:	ec06                	sd	ra,24(sp)
    8000076a:	e822                	sd	s0,16(sp)
    8000076c:	e426                	sd	s1,8(sp)
    8000076e:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    80000770:	00010497          	auipc	s1,0x10
    80000774:	3c848493          	add	s1,s1,968 # 80010b38 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	add	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	3c0080e7          	jalr	960(ra) # 80000b42 <initlock>
  pr.locking = 1;
    8000078a:	4785                	li	a5,1
    8000078c:	cc9c                	sw	a5,24(s1)
}
    8000078e:	60e2                	ld	ra,24(sp)
    80000790:	6442                	ld	s0,16(sp)
    80000792:	64a2                	ld	s1,8(sp)
    80000794:	6105                	add	sp,sp,32
    80000796:	8082                	ret

0000000080000798 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000798:	1141                	add	sp,sp,-16
    8000079a:	e406                	sd	ra,8(sp)
    8000079c:	e022                	sd	s0,0(sp)
    8000079e:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a0:	100007b7          	lui	a5,0x10000
    800007a4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a8:	f8000713          	li	a4,-128
    800007ac:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b0:	470d                	li	a4,3
    800007b2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ba:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007be:	469d                	li	a3,7
    800007c0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c8:	00008597          	auipc	a1,0x8
    800007cc:	89058593          	add	a1,a1,-1904 # 80008058 <digits+0x18>
    800007d0:	00010517          	auipc	a0,0x10
    800007d4:	38850513          	add	a0,a0,904 # 80010b58 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	36a080e7          	jalr	874(ra) # 80000b42 <initlock>
}
    800007e0:	60a2                	ld	ra,8(sp)
    800007e2:	6402                	ld	s0,0(sp)
    800007e4:	0141                	add	sp,sp,16
    800007e6:	8082                	ret

00000000800007e8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e8:	1101                	add	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	add	s0,sp,32
    800007f2:	84aa                	mv	s1,a0
  push_off();
    800007f4:	00000097          	auipc	ra,0x0
    800007f8:	392080e7          	jalr	914(ra) # 80000b86 <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	1147a783          	lw	a5,276(a5) # 80008910 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000804:	10000737          	lui	a4,0x10000
  if(panicked){
    80000808:	c391                	beqz	a5,8000080c <uartputc_sync+0x24>
    for(;;)
    8000080a:	a001                	j	8000080a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000810:	0207f793          	and	a5,a5,32
    80000814:	dfe5                	beqz	a5,8000080c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000816:	0ff4f513          	zext.b	a0,s1
    8000081a:	100007b7          	lui	a5,0x10000
    8000081e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000822:	00000097          	auipc	ra,0x0
    80000826:	404080e7          	jalr	1028(ra) # 80000c26 <pop_off>
}
    8000082a:	60e2                	ld	ra,24(sp)
    8000082c:	6442                	ld	s0,16(sp)
    8000082e:	64a2                	ld	s1,8(sp)
    80000830:	6105                	add	sp,sp,32
    80000832:	8082                	ret

0000000080000834 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000834:	00008797          	auipc	a5,0x8
    80000838:	0e47b783          	ld	a5,228(a5) # 80008918 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	0e473703          	ld	a4,228(a4) # 80008920 <uart_tx_w>
    80000844:	06f70a63          	beq	a4,a5,800008b8 <uartstart+0x84>
{
    80000848:	7139                	add	sp,sp,-64
    8000084a:	fc06                	sd	ra,56(sp)
    8000084c:	f822                	sd	s0,48(sp)
    8000084e:	f426                	sd	s1,40(sp)
    80000850:	f04a                	sd	s2,32(sp)
    80000852:	ec4e                	sd	s3,24(sp)
    80000854:	e852                	sd	s4,16(sp)
    80000856:	e456                	sd	s5,8(sp)
    80000858:	0080                	add	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085e:	00010a17          	auipc	s4,0x10
    80000862:	2faa0a13          	add	s4,s4,762 # 80010b58 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	0b248493          	add	s1,s1,178 # 80008918 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	0b298993          	add	s3,s3,178 # 80008920 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000876:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087a:	02077713          	and	a4,a4,32
    8000087e:	c705                	beqz	a4,800008a6 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000880:	01f7f713          	and	a4,a5,31
    80000884:	9752                	add	a4,a4,s4
    80000886:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088a:	0785                	add	a5,a5,1
    8000088c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088e:	8526                	mv	a0,s1
    80000890:	00002097          	auipc	ra,0x2
    80000894:	8ce080e7          	jalr	-1842(ra) # 8000215e <wakeup>
    
    WriteReg(THR, c);
    80000898:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089c:	609c                	ld	a5,0(s1)
    8000089e:	0009b703          	ld	a4,0(s3)
    800008a2:	fcf71ae3          	bne	a4,a5,80000876 <uartstart+0x42>
  }
}
    800008a6:	70e2                	ld	ra,56(sp)
    800008a8:	7442                	ld	s0,48(sp)
    800008aa:	74a2                	ld	s1,40(sp)
    800008ac:	7902                	ld	s2,32(sp)
    800008ae:	69e2                	ld	s3,24(sp)
    800008b0:	6a42                	ld	s4,16(sp)
    800008b2:	6aa2                	ld	s5,8(sp)
    800008b4:	6121                	add	sp,sp,64
    800008b6:	8082                	ret
    800008b8:	8082                	ret

00000000800008ba <uartputc>:
{
    800008ba:	7179                	add	sp,sp,-48
    800008bc:	f406                	sd	ra,40(sp)
    800008be:	f022                	sd	s0,32(sp)
    800008c0:	ec26                	sd	s1,24(sp)
    800008c2:	e84a                	sd	s2,16(sp)
    800008c4:	e44e                	sd	s3,8(sp)
    800008c6:	e052                	sd	s4,0(sp)
    800008c8:	1800                	add	s0,sp,48
    800008ca:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008cc:	00010517          	auipc	a0,0x10
    800008d0:	28c50513          	add	a0,a0,652 # 80010b58 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	0347a783          	lw	a5,52(a5) # 80008910 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	03a73703          	ld	a4,58(a4) # 80008920 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	02a7b783          	ld	a5,42(a5) # 80008918 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	25e98993          	add	s3,s3,606 # 80010b58 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	01648493          	add	s1,s1,22 # 80008918 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	01690913          	add	s2,s2,22 # 80008920 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	7e0080e7          	jalr	2016(ra) # 800020fa <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	22848493          	add	s1,s1,552 # 80010b58 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	fce7be23          	sd	a4,-36(a5) # 80008920 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	330080e7          	jalr	816(ra) # 80000c86 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	add	sp,sp,48
    8000096c:	8082                	ret
    for(;;)
    8000096e:	a001                	j	8000096e <uartputc+0xb4>

0000000080000970 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000970:	1141                	add	sp,sp,-16
    80000972:	e422                	sd	s0,8(sp)
    80000974:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000976:	100007b7          	lui	a5,0x10000
    8000097a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097e:	8b85                	and	a5,a5,1
    80000980:	cb81                	beqz	a5,80000990 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000982:	100007b7          	lui	a5,0x10000
    80000986:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	add	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1a>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000994:	1101                	add	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	add	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	918080e7          	jalr	-1768(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc6080e7          	jalr	-58(ra) # 80000970 <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00010497          	auipc	s1,0x10
    800009ba:	1a248493          	add	s1,s1,418 # 80010b58 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	212080e7          	jalr	530(ra) # 80000bd2 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2b4080e7          	jalr	692(ra) # 80000c86 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	add	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	add	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	sll	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00026797          	auipc	a5,0x26
    800009fc:	96878793          	add	a5,a5,-1688 # 80026360 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	sll	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	2be080e7          	jalr	702(ra) # 80000cce <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00010917          	auipc	s2,0x10
    80000a1c:	17890913          	add	s2,s2,376 # 80010b90 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1b0080e7          	jalr	432(ra) # 80000bd2 <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	250080e7          	jalr	592(ra) # 80000c86 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	add	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	add	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	aea080e7          	jalr	-1302(ra) # 8000053c <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	add	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	00e504b3          	add	s1,a0,a4
    80000a74:	777d                	lui	a4,0xfffff
    80000a76:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a78:	94be                	add	s1,s1,a5
    80000a7a:	0095ee63          	bltu	a1,s1,80000a96 <freerange+0x3c>
    80000a7e:	892e                	mv	s2,a1
    kfree(p);
    80000a80:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a82:	6985                	lui	s3,0x1
    kfree(p);
    80000a84:	01448533          	add	a0,s1,s4
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	f5c080e7          	jalr	-164(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94ce                	add	s1,s1,s3
    80000a92:	fe9979e3          	bgeu	s2,s1,80000a84 <freerange+0x2a>
}
    80000a96:	70a2                	ld	ra,40(sp)
    80000a98:	7402                	ld	s0,32(sp)
    80000a9a:	64e2                	ld	s1,24(sp)
    80000a9c:	6942                	ld	s2,16(sp)
    80000a9e:	69a2                	ld	s3,8(sp)
    80000aa0:	6a02                	ld	s4,0(sp)
    80000aa2:	6145                	add	sp,sp,48
    80000aa4:	8082                	ret

0000000080000aa6 <kinit>:
{
    80000aa6:	1141                	add	sp,sp,-16
    80000aa8:	e406                	sd	ra,8(sp)
    80000aaa:	e022                	sd	s0,0(sp)
    80000aac:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aae:	00007597          	auipc	a1,0x7
    80000ab2:	5ba58593          	add	a1,a1,1466 # 80008068 <digits+0x28>
    80000ab6:	00010517          	auipc	a0,0x10
    80000aba:	0da50513          	add	a0,a0,218 # 80010b90 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	sll	a1,a1,0x1b
    80000aca:	00026517          	auipc	a0,0x26
    80000ace:	89650513          	add	a0,a0,-1898 # 80026360 <end>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	f88080e7          	jalr	-120(ra) # 80000a5a <freerange>
}
    80000ada:	60a2                	ld	ra,8(sp)
    80000adc:	6402                	ld	s0,0(sp)
    80000ade:	0141                	add	sp,sp,16
    80000ae0:	8082                	ret

0000000080000ae2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae2:	1101                	add	sp,sp,-32
    80000ae4:	ec06                	sd	ra,24(sp)
    80000ae6:	e822                	sd	s0,16(sp)
    80000ae8:	e426                	sd	s1,8(sp)
    80000aea:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aec:	00010497          	auipc	s1,0x10
    80000af0:	0a448493          	add	s1,s1,164 # 80010b90 <kmem>
    80000af4:	8526                	mv	a0,s1
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	0dc080e7          	jalr	220(ra) # 80000bd2 <acquire>
  r = kmem.freelist;
    80000afe:	6c84                	ld	s1,24(s1)
  if(r)
    80000b00:	c885                	beqz	s1,80000b30 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b02:	609c                	ld	a5,0(s1)
    80000b04:	00010517          	auipc	a0,0x10
    80000b08:	08c50513          	add	a0,a0,140 # 80010b90 <kmem>
    80000b0c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	178080e7          	jalr	376(ra) # 80000c86 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b16:	6605                	lui	a2,0x1
    80000b18:	4595                	li	a1,5
    80000b1a:	8526                	mv	a0,s1
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	1b2080e7          	jalr	434(ra) # 80000cce <memset>
  return (void*)r;
}
    80000b24:	8526                	mv	a0,s1
    80000b26:	60e2                	ld	ra,24(sp)
    80000b28:	6442                	ld	s0,16(sp)
    80000b2a:	64a2                	ld	s1,8(sp)
    80000b2c:	6105                	add	sp,sp,32
    80000b2e:	8082                	ret
  release(&kmem.lock);
    80000b30:	00010517          	auipc	a0,0x10
    80000b34:	06050513          	add	a0,a0,96 # 80010b90 <kmem>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	14e080e7          	jalr	334(ra) # 80000c86 <release>
  if(r)
    80000b40:	b7d5                	j	80000b24 <kalloc+0x42>

0000000080000b42 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b42:	1141                	add	sp,sp,-16
    80000b44:	e422                	sd	s0,8(sp)
    80000b46:	0800                	add	s0,sp,16
  lk->name = name;
    80000b48:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4e:	00053823          	sd	zero,16(a0)
}
    80000b52:	6422                	ld	s0,8(sp)
    80000b54:	0141                	add	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b58:	411c                	lw	a5,0(a0)
    80000b5a:	e399                	bnez	a5,80000b60 <holding+0x8>
    80000b5c:	4501                	li	a0,0
  return r;
}
    80000b5e:	8082                	ret
{
    80000b60:	1101                	add	sp,sp,-32
    80000b62:	ec06                	sd	ra,24(sp)
    80000b64:	e822                	sd	s0,16(sp)
    80000b66:	e426                	sd	s1,8(sp)
    80000b68:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	6904                	ld	s1,16(a0)
    80000b6c:	00001097          	auipc	ra,0x1
    80000b70:	e1e080e7          	jalr	-482(ra) # 8000198a <mycpu>
    80000b74:	40a48533          	sub	a0,s1,a0
    80000b78:	00153513          	seqz	a0,a0
}
    80000b7c:	60e2                	ld	ra,24(sp)
    80000b7e:	6442                	ld	s0,16(sp)
    80000b80:	64a2                	ld	s1,8(sp)
    80000b82:	6105                	add	sp,sp,32
    80000b84:	8082                	ret

0000000080000b86 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b86:	1101                	add	sp,sp,-32
    80000b88:	ec06                	sd	ra,24(sp)
    80000b8a:	e822                	sd	s0,16(sp)
    80000b8c:	e426                	sd	s1,8(sp)
    80000b8e:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b90:	100024f3          	csrr	s1,sstatus
    80000b94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b98:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9e:	00001097          	auipc	ra,0x1
    80000ba2:	dec080e7          	jalr	-532(ra) # 8000198a <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	de0080e7          	jalr	-544(ra) # 8000198a <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	add	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	dc8080e7          	jalr	-568(ra) # 8000198a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bca:	8085                	srl	s1,s1,0x1
    80000bcc:	8885                	and	s1,s1,1
    80000bce:	dd64                	sw	s1,124(a0)
    80000bd0:	bfe9                	j	80000baa <push_off+0x24>

0000000080000bd2 <acquire>:
{
    80000bd2:	1101                	add	sp,sp,-32
    80000bd4:	ec06                	sd	ra,24(sp)
    80000bd6:	e822                	sd	s0,16(sp)
    80000bd8:	e426                	sd	s1,8(sp)
    80000bda:	1000                	add	s0,sp,32
    80000bdc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bde:	00000097          	auipc	ra,0x0
    80000be2:	fa8080e7          	jalr	-88(ra) # 80000b86 <push_off>
  if(holding(lk))
    80000be6:	8526                	mv	a0,s1
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	f70080e7          	jalr	-144(ra) # 80000b58 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf0:	4705                	li	a4,1
  if(holding(lk))
    80000bf2:	e115                	bnez	a0,80000c16 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	87ba                	mv	a5,a4
    80000bf6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfa:	2781                	sext.w	a5,a5
    80000bfc:	ffe5                	bnez	a5,80000bf4 <acquire+0x22>
  __sync_synchronize();
    80000bfe:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c02:	00001097          	auipc	ra,0x1
    80000c06:	d88080e7          	jalr	-632(ra) # 8000198a <mycpu>
    80000c0a:	e888                	sd	a0,16(s1)
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	add	sp,sp,32
    80000c14:	8082                	ret
    panic("acquire");
    80000c16:	00007517          	auipc	a0,0x7
    80000c1a:	45a50513          	add	a0,a0,1114 # 80008070 <digits+0x30>
    80000c1e:	00000097          	auipc	ra,0x0
    80000c22:	91e080e7          	jalr	-1762(ra) # 8000053c <panic>

0000000080000c26 <pop_off>:

void
pop_off(void)
{
    80000c26:	1141                	add	sp,sp,-16
    80000c28:	e406                	sd	ra,8(sp)
    80000c2a:	e022                	sd	s0,0(sp)
    80000c2c:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	d5c080e7          	jalr	-676(ra) # 8000198a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3a:	8b89                	and	a5,a5,2
  if(intr_get())
    80000c3c:	e78d                	bnez	a5,80000c66 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3e:	5d3c                	lw	a5,120(a0)
    80000c40:	02f05b63          	blez	a5,80000c76 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c44:	37fd                	addw	a5,a5,-1
    80000c46:	0007871b          	sext.w	a4,a5
    80000c4a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4c:	eb09                	bnez	a4,80000c5e <pop_off+0x38>
    80000c4e:	5d7c                	lw	a5,124(a0)
    80000c50:	c799                	beqz	a5,80000c5e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c56:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5e:	60a2                	ld	ra,8(sp)
    80000c60:	6402                	ld	s0,0(sp)
    80000c62:	0141                	add	sp,sp,16
    80000c64:	8082                	ret
    panic("pop_off - interruptible");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	41250513          	add	a0,a0,1042 # 80008078 <digits+0x38>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8ce080e7          	jalr	-1842(ra) # 8000053c <panic>
    panic("pop_off");
    80000c76:	00007517          	auipc	a0,0x7
    80000c7a:	41a50513          	add	a0,a0,1050 # 80008090 <digits+0x50>
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	8be080e7          	jalr	-1858(ra) # 8000053c <panic>

0000000080000c86 <release>:
{
    80000c86:	1101                	add	sp,sp,-32
    80000c88:	ec06                	sd	ra,24(sp)
    80000c8a:	e822                	sd	s0,16(sp)
    80000c8c:	e426                	sd	s1,8(sp)
    80000c8e:	1000                	add	s0,sp,32
    80000c90:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	ec6080e7          	jalr	-314(ra) # 80000b58 <holding>
    80000c9a:	c115                	beqz	a0,80000cbe <release+0x38>
  lk->cpu = 0;
    80000c9c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca4:	0f50000f          	fence	iorw,ow
    80000ca8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	f7a080e7          	jalr	-134(ra) # 80000c26 <pop_off>
}
    80000cb4:	60e2                	ld	ra,24(sp)
    80000cb6:	6442                	ld	s0,16(sp)
    80000cb8:	64a2                	ld	s1,8(sp)
    80000cba:	6105                	add	sp,sp,32
    80000cbc:	8082                	ret
    panic("release");
    80000cbe:	00007517          	auipc	a0,0x7
    80000cc2:	3da50513          	add	a0,a0,986 # 80008098 <digits+0x58>
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	876080e7          	jalr	-1930(ra) # 8000053c <panic>

0000000080000cce <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cce:	1141                	add	sp,sp,-16
    80000cd0:	e422                	sd	s0,8(sp)
    80000cd2:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd4:	ca19                	beqz	a2,80000cea <memset+0x1c>
    80000cd6:	87aa                	mv	a5,a0
    80000cd8:	1602                	sll	a2,a2,0x20
    80000cda:	9201                	srl	a2,a2,0x20
    80000cdc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce4:	0785                	add	a5,a5,1
    80000ce6:	fee79de3          	bne	a5,a4,80000ce0 <memset+0x12>
  }
  return dst;
}
    80000cea:	6422                	ld	s0,8(sp)
    80000cec:	0141                	add	sp,sp,16
    80000cee:	8082                	ret

0000000080000cf0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf0:	1141                	add	sp,sp,-16
    80000cf2:	e422                	sd	s0,8(sp)
    80000cf4:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf6:	ca05                	beqz	a2,80000d26 <memcmp+0x36>
    80000cf8:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfc:	1682                	sll	a3,a3,0x20
    80000cfe:	9281                	srl	a3,a3,0x20
    80000d00:	0685                	add	a3,a3,1
    80000d02:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d04:	00054783          	lbu	a5,0(a0)
    80000d08:	0005c703          	lbu	a4,0(a1)
    80000d0c:	00e79863          	bne	a5,a4,80000d1c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d10:	0505                	add	a0,a0,1
    80000d12:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000d14:	fed518e3          	bne	a0,a3,80000d04 <memcmp+0x14>
  }

  return 0;
    80000d18:	4501                	li	a0,0
    80000d1a:	a019                	j	80000d20 <memcmp+0x30>
      return *s1 - *s2;
    80000d1c:	40e7853b          	subw	a0,a5,a4
}
    80000d20:	6422                	ld	s0,8(sp)
    80000d22:	0141                	add	sp,sp,16
    80000d24:	8082                	ret
  return 0;
    80000d26:	4501                	li	a0,0
    80000d28:	bfe5                	j	80000d20 <memcmp+0x30>

0000000080000d2a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2a:	1141                	add	sp,sp,-16
    80000d2c:	e422                	sd	s0,8(sp)
    80000d2e:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d30:	c205                	beqz	a2,80000d50 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d32:	02a5e263          	bltu	a1,a0,80000d56 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d36:	1602                	sll	a2,a2,0x20
    80000d38:	9201                	srl	a2,a2,0x20
    80000d3a:	00c587b3          	add	a5,a1,a2
{
    80000d3e:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d40:	0585                	add	a1,a1,1
    80000d42:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd8ca1>
    80000d44:	fff5c683          	lbu	a3,-1(a1)
    80000d48:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4c:	fef59ae3          	bne	a1,a5,80000d40 <memmove+0x16>

  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	add	sp,sp,16
    80000d54:	8082                	ret
  if(s < d && s + n > d){
    80000d56:	02061693          	sll	a3,a2,0x20
    80000d5a:	9281                	srl	a3,a3,0x20
    80000d5c:	00d58733          	add	a4,a1,a3
    80000d60:	fce57be3          	bgeu	a0,a4,80000d36 <memmove+0xc>
    d += n;
    80000d64:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d66:	fff6079b          	addw	a5,a2,-1
    80000d6a:	1782                	sll	a5,a5,0x20
    80000d6c:	9381                	srl	a5,a5,0x20
    80000d6e:	fff7c793          	not	a5,a5
    80000d72:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d74:	177d                	add	a4,a4,-1
    80000d76:	16fd                	add	a3,a3,-1
    80000d78:	00074603          	lbu	a2,0(a4)
    80000d7c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d80:	fee79ae3          	bne	a5,a4,80000d74 <memmove+0x4a>
    80000d84:	b7f1                	j	80000d50 <memmove+0x26>

0000000080000d86 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d86:	1141                	add	sp,sp,-16
    80000d88:	e406                	sd	ra,8(sp)
    80000d8a:	e022                	sd	s0,0(sp)
    80000d8c:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000d8e:	00000097          	auipc	ra,0x0
    80000d92:	f9c080e7          	jalr	-100(ra) # 80000d2a <memmove>
}
    80000d96:	60a2                	ld	ra,8(sp)
    80000d98:	6402                	ld	s0,0(sp)
    80000d9a:	0141                	add	sp,sp,16
    80000d9c:	8082                	ret

0000000080000d9e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9e:	1141                	add	sp,sp,-16
    80000da0:	e422                	sd	s0,8(sp)
    80000da2:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da4:	ce11                	beqz	a2,80000dc0 <strncmp+0x22>
    80000da6:	00054783          	lbu	a5,0(a0)
    80000daa:	cf89                	beqz	a5,80000dc4 <strncmp+0x26>
    80000dac:	0005c703          	lbu	a4,0(a1)
    80000db0:	00f71a63          	bne	a4,a5,80000dc4 <strncmp+0x26>
    n--, p++, q++;
    80000db4:	367d                	addw	a2,a2,-1
    80000db6:	0505                	add	a0,a0,1
    80000db8:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dba:	f675                	bnez	a2,80000da6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dbc:	4501                	li	a0,0
    80000dbe:	a809                	j	80000dd0 <strncmp+0x32>
    80000dc0:	4501                	li	a0,0
    80000dc2:	a039                	j	80000dd0 <strncmp+0x32>
  if(n == 0)
    80000dc4:	ca09                	beqz	a2,80000dd6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc6:	00054503          	lbu	a0,0(a0)
    80000dca:	0005c783          	lbu	a5,0(a1)
    80000dce:	9d1d                	subw	a0,a0,a5
}
    80000dd0:	6422                	ld	s0,8(sp)
    80000dd2:	0141                	add	sp,sp,16
    80000dd4:	8082                	ret
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	bfe5                	j	80000dd0 <strncmp+0x32>

0000000080000dda <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dda:	1141                	add	sp,sp,-16
    80000ddc:	e422                	sd	s0,8(sp)
    80000dde:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de0:	87aa                	mv	a5,a0
    80000de2:	86b2                	mv	a3,a2
    80000de4:	367d                	addw	a2,a2,-1
    80000de6:	00d05963          	blez	a3,80000df8 <strncpy+0x1e>
    80000dea:	0785                	add	a5,a5,1
    80000dec:	0005c703          	lbu	a4,0(a1)
    80000df0:	fee78fa3          	sb	a4,-1(a5)
    80000df4:	0585                	add	a1,a1,1
    80000df6:	f775                	bnez	a4,80000de2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df8:	873e                	mv	a4,a5
    80000dfa:	9fb5                	addw	a5,a5,a3
    80000dfc:	37fd                	addw	a5,a5,-1
    80000dfe:	00c05963          	blez	a2,80000e10 <strncpy+0x36>
    *s++ = 0;
    80000e02:	0705                	add	a4,a4,1
    80000e04:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e08:	40e786bb          	subw	a3,a5,a4
    80000e0c:	fed04be3          	bgtz	a3,80000e02 <strncpy+0x28>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	add	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	add	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addw	a3,a2,-1
    80000e24:	1682                	sll	a3,a3,0x20
    80000e26:	9281                	srl	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	add	a1,a1,1
    80000e32:	0785                	add	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	add	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	add	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	add	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86be                	mv	a3,a5
    80000e5a:	0785                	add	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	ff65                	bnez	a4,80000e58 <strlen+0x10>
    80000e62:	40a6853b          	subw	a0,a3,a0
    80000e66:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	add	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	add	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	b00080e7          	jalr	-1280(ra) # 8000197a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	aa670713          	add	a4,a4,-1370 # 80008928 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ae4080e7          	jalr	-1308(ra) # 8000197a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	add	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6de080e7          	jalr	1758(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	aa2080e7          	jalr	-1374(ra) # 8000295a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	040080e7          	jalr	64(ra) # 80005f00 <plicinithart>
  }

  lottery_scheduler();        
    80000ec8:	00002097          	auipc	ra,0x2
    80000ecc:	840080e7          	jalr	-1984(ra) # 80002708 <lottery_scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57c080e7          	jalr	1404(ra) # 8000044c <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88e080e7          	jalr	-1906(ra) # 80000766 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	add	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69e080e7          	jalr	1694(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	add	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68e080e7          	jalr	1678(ra) # 80000586 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	add	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67e080e7          	jalr	1662(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b96080e7          	jalr	-1130(ra) # 80000aa6 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	326080e7          	jalr	806(ra) # 8000123e <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	99e080e7          	jalr	-1634(ra) # 800018c6 <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	a02080e7          	jalr	-1534(ra) # 80002932 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	a22080e7          	jalr	-1502(ra) # 8000295a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	faa080e7          	jalr	-86(ra) # 80005eea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	fb8080e7          	jalr	-72(ra) # 80005f00 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	1b8080e7          	jalr	440(ra) # 80003108 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	856080e7          	jalr	-1962(ra) # 800037ae <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	7cc080e7          	jalr	1996(ra) # 8000472c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	0a0080e7          	jalr	160(ra) # 80006008 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	dba080e7          	jalr	-582(ra) # 80001d2a <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	9af72523          	sw	a5,-1622(a4) # 80008928 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	add	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f8e:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f92:	00008797          	auipc	a5,0x8
    80000f96:	99e7b783          	ld	a5,-1634(a5) # 80008930 <kernel_pagetable>
    80000f9a:	83b1                	srl	a5,a5,0xc
    80000f9c:	577d                	li	a4,-1
    80000f9e:	177e                	sll	a4,a4,0x3f
    80000fa0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa2:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fa6:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000faa:	6422                	ld	s0,8(sp)
    80000fac:	0141                	add	sp,sp,16
    80000fae:	8082                	ret

0000000080000fb0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb0:	7139                	add	sp,sp,-64
    80000fb2:	fc06                	sd	ra,56(sp)
    80000fb4:	f822                	sd	s0,48(sp)
    80000fb6:	f426                	sd	s1,40(sp)
    80000fb8:	f04a                	sd	s2,32(sp)
    80000fba:	ec4e                	sd	s3,24(sp)
    80000fbc:	e852                	sd	s4,16(sp)
    80000fbe:	e456                	sd	s5,8(sp)
    80000fc0:	e05a                	sd	s6,0(sp)
    80000fc2:	0080                	add	s0,sp,64
    80000fc4:	84aa                	mv	s1,a0
    80000fc6:	89ae                	mv	s3,a1
    80000fc8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fca:	57fd                	li	a5,-1
    80000fcc:	83e9                	srl	a5,a5,0x1a
    80000fce:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd2:	04b7f263          	bgeu	a5,a1,80001016 <walk+0x66>
    panic("walk");
    80000fd6:	00007517          	auipc	a0,0x7
    80000fda:	0fa50513          	add	a0,a0,250 # 800080d0 <digits+0x90>
    80000fde:	fffff097          	auipc	ra,0xfffff
    80000fe2:	55e080e7          	jalr	1374(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe6:	060a8663          	beqz	s5,80001052 <walk+0xa2>
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	af8080e7          	jalr	-1288(ra) # 80000ae2 <kalloc>
    80000ff2:	84aa                	mv	s1,a0
    80000ff4:	c529                	beqz	a0,8000103e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff6:	6605                	lui	a2,0x1
    80000ff8:	4581                	li	a1,0
    80000ffa:	00000097          	auipc	ra,0x0
    80000ffe:	cd4080e7          	jalr	-812(ra) # 80000cce <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001002:	00c4d793          	srl	a5,s1,0xc
    80001006:	07aa                	sll	a5,a5,0xa
    80001008:	0017e793          	or	a5,a5,1
    8000100c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001010:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8c97>
    80001012:	036a0063          	beq	s4,s6,80001032 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001016:	0149d933          	srl	s2,s3,s4
    8000101a:	1ff97913          	and	s2,s2,511
    8000101e:	090e                	sll	s2,s2,0x3
    80001020:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001022:	00093483          	ld	s1,0(s2)
    80001026:	0014f793          	and	a5,s1,1
    8000102a:	dfd5                	beqz	a5,80000fe6 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000102c:	80a9                	srl	s1,s1,0xa
    8000102e:	04b2                	sll	s1,s1,0xc
    80001030:	b7c5                	j	80001010 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001032:	00c9d513          	srl	a0,s3,0xc
    80001036:	1ff57513          	and	a0,a0,511
    8000103a:	050e                	sll	a0,a0,0x3
    8000103c:	9526                	add	a0,a0,s1
}
    8000103e:	70e2                	ld	ra,56(sp)
    80001040:	7442                	ld	s0,48(sp)
    80001042:	74a2                	ld	s1,40(sp)
    80001044:	7902                	ld	s2,32(sp)
    80001046:	69e2                	ld	s3,24(sp)
    80001048:	6a42                	ld	s4,16(sp)
    8000104a:	6aa2                	ld	s5,8(sp)
    8000104c:	6b02                	ld	s6,0(sp)
    8000104e:	6121                	add	sp,sp,64
    80001050:	8082                	ret
        return 0;
    80001052:	4501                	li	a0,0
    80001054:	b7ed                	j	8000103e <walk+0x8e>

0000000080001056 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001056:	57fd                	li	a5,-1
    80001058:	83e9                	srl	a5,a5,0x1a
    8000105a:	00b7f463          	bgeu	a5,a1,80001062 <walkaddr+0xc>
    return 0;
    8000105e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001060:	8082                	ret
{
    80001062:	1141                	add	sp,sp,-16
    80001064:	e406                	sd	ra,8(sp)
    80001066:	e022                	sd	s0,0(sp)
    80001068:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000106a:	4601                	li	a2,0
    8000106c:	00000097          	auipc	ra,0x0
    80001070:	f44080e7          	jalr	-188(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001074:	c105                	beqz	a0,80001094 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001076:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001078:	0117f693          	and	a3,a5,17
    8000107c:	4745                	li	a4,17
    return 0;
    8000107e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001080:	00e68663          	beq	a3,a4,8000108c <walkaddr+0x36>
}
    80001084:	60a2                	ld	ra,8(sp)
    80001086:	6402                	ld	s0,0(sp)
    80001088:	0141                	add	sp,sp,16
    8000108a:	8082                	ret
  pa = PTE2PA(*pte);
    8000108c:	83a9                	srl	a5,a5,0xa
    8000108e:	00c79513          	sll	a0,a5,0xc
  return pa;
    80001092:	bfcd                	j	80001084 <walkaddr+0x2e>
    return 0;
    80001094:	4501                	li	a0,0
    80001096:	b7fd                	j	80001084 <walkaddr+0x2e>

0000000080001098 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001098:	715d                	add	sp,sp,-80
    8000109a:	e486                	sd	ra,72(sp)
    8000109c:	e0a2                	sd	s0,64(sp)
    8000109e:	fc26                	sd	s1,56(sp)
    800010a0:	f84a                	sd	s2,48(sp)
    800010a2:	f44e                	sd	s3,40(sp)
    800010a4:	f052                	sd	s4,32(sp)
    800010a6:	ec56                	sd	s5,24(sp)
    800010a8:	e85a                	sd	s6,16(sp)
    800010aa:	e45e                	sd	s7,8(sp)
    800010ac:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ae:	c639                	beqz	a2,800010fc <mappages+0x64>
    800010b0:	8aaa                	mv	s5,a0
    800010b2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b4:	777d                	lui	a4,0xfffff
    800010b6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ba:	fff58993          	add	s3,a1,-1
    800010be:	99b2                	add	s3,s3,a2
    800010c0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c4:	893e                	mv	s2,a5
    800010c6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ca:	6b85                	lui	s7,0x1
    800010cc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d0:	4605                	li	a2,1
    800010d2:	85ca                	mv	a1,s2
    800010d4:	8556                	mv	a0,s5
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	eda080e7          	jalr	-294(ra) # 80000fb0 <walk>
    800010de:	cd1d                	beqz	a0,8000111c <mappages+0x84>
    if(*pte & PTE_V)
    800010e0:	611c                	ld	a5,0(a0)
    800010e2:	8b85                	and	a5,a5,1
    800010e4:	e785                	bnez	a5,8000110c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e6:	80b1                	srl	s1,s1,0xc
    800010e8:	04aa                	sll	s1,s1,0xa
    800010ea:	0164e4b3          	or	s1,s1,s6
    800010ee:	0014e493          	or	s1,s1,1
    800010f2:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f4:	05390063          	beq	s2,s3,80001134 <mappages+0x9c>
    a += PGSIZE;
    800010f8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010fa:	bfc9                	j	800010cc <mappages+0x34>
    panic("mappages: size");
    800010fc:	00007517          	auipc	a0,0x7
    80001100:	fdc50513          	add	a0,a0,-36 # 800080d8 <digits+0x98>
    80001104:	fffff097          	auipc	ra,0xfffff
    80001108:	438080e7          	jalr	1080(ra) # 8000053c <panic>
      panic("mappages: remap");
    8000110c:	00007517          	auipc	a0,0x7
    80001110:	fdc50513          	add	a0,a0,-36 # 800080e8 <digits+0xa8>
    80001114:	fffff097          	auipc	ra,0xfffff
    80001118:	428080e7          	jalr	1064(ra) # 8000053c <panic>
      return -1;
    8000111c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111e:	60a6                	ld	ra,72(sp)
    80001120:	6406                	ld	s0,64(sp)
    80001122:	74e2                	ld	s1,56(sp)
    80001124:	7942                	ld	s2,48(sp)
    80001126:	79a2                	ld	s3,40(sp)
    80001128:	7a02                	ld	s4,32(sp)
    8000112a:	6ae2                	ld	s5,24(sp)
    8000112c:	6b42                	ld	s6,16(sp)
    8000112e:	6ba2                	ld	s7,8(sp)
    80001130:	6161                	add	sp,sp,80
    80001132:	8082                	ret
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	b7e5                	j	8000111e <mappages+0x86>

0000000080001138 <kvmmap>:
{
    80001138:	1141                	add	sp,sp,-16
    8000113a:	e406                	sd	ra,8(sp)
    8000113c:	e022                	sd	s0,0(sp)
    8000113e:	0800                	add	s0,sp,16
    80001140:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001142:	86b2                	mv	a3,a2
    80001144:	863e                	mv	a2,a5
    80001146:	00000097          	auipc	ra,0x0
    8000114a:	f52080e7          	jalr	-174(ra) # 80001098 <mappages>
    8000114e:	e509                	bnez	a0,80001158 <kvmmap+0x20>
}
    80001150:	60a2                	ld	ra,8(sp)
    80001152:	6402                	ld	s0,0(sp)
    80001154:	0141                	add	sp,sp,16
    80001156:	8082                	ret
    panic("kvmmap");
    80001158:	00007517          	auipc	a0,0x7
    8000115c:	fa050513          	add	a0,a0,-96 # 800080f8 <digits+0xb8>
    80001160:	fffff097          	auipc	ra,0xfffff
    80001164:	3dc080e7          	jalr	988(ra) # 8000053c <panic>

0000000080001168 <kvmmake>:
{
    80001168:	1101                	add	sp,sp,-32
    8000116a:	ec06                	sd	ra,24(sp)
    8000116c:	e822                	sd	s0,16(sp)
    8000116e:	e426                	sd	s1,8(sp)
    80001170:	e04a                	sd	s2,0(sp)
    80001172:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001174:	00000097          	auipc	ra,0x0
    80001178:	96e080e7          	jalr	-1682(ra) # 80000ae2 <kalloc>
    8000117c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117e:	6605                	lui	a2,0x1
    80001180:	4581                	li	a1,0
    80001182:	00000097          	auipc	ra,0x0
    80001186:	b4c080e7          	jalr	-1204(ra) # 80000cce <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000118a:	4719                	li	a4,6
    8000118c:	6685                	lui	a3,0x1
    8000118e:	10000637          	lui	a2,0x10000
    80001192:	100005b7          	lui	a1,0x10000
    80001196:	8526                	mv	a0,s1
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	fa0080e7          	jalr	-96(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a0:	4719                	li	a4,6
    800011a2:	6685                	lui	a3,0x1
    800011a4:	10001637          	lui	a2,0x10001
    800011a8:	100015b7          	lui	a1,0x10001
    800011ac:	8526                	mv	a0,s1
    800011ae:	00000097          	auipc	ra,0x0
    800011b2:	f8a080e7          	jalr	-118(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b6:	4719                	li	a4,6
    800011b8:	004006b7          	lui	a3,0x400
    800011bc:	0c000637          	lui	a2,0xc000
    800011c0:	0c0005b7          	lui	a1,0xc000
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f72080e7          	jalr	-142(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ce:	00007917          	auipc	s2,0x7
    800011d2:	e3290913          	add	s2,s2,-462 # 80008000 <etext>
    800011d6:	4729                	li	a4,10
    800011d8:	80007697          	auipc	a3,0x80007
    800011dc:	e2868693          	add	a3,a3,-472 # 8000 <_entry-0x7fff8000>
    800011e0:	4605                	li	a2,1
    800011e2:	067e                	sll	a2,a2,0x1f
    800011e4:	85b2                	mv	a1,a2
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f50080e7          	jalr	-176(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f0:	4719                	li	a4,6
    800011f2:	46c5                	li	a3,17
    800011f4:	06ee                	sll	a3,a3,0x1b
    800011f6:	412686b3          	sub	a3,a3,s2
    800011fa:	864a                	mv	a2,s2
    800011fc:	85ca                	mv	a1,s2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f38080e7          	jalr	-200(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001208:	4729                	li	a4,10
    8000120a:	6685                	lui	a3,0x1
    8000120c:	00006617          	auipc	a2,0x6
    80001210:	df460613          	add	a2,a2,-524 # 80007000 <_trampoline>
    80001214:	040005b7          	lui	a1,0x4000
    80001218:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000121a:	05b2                	sll	a1,a1,0xc
    8000121c:	8526                	mv	a0,s1
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	f1a080e7          	jalr	-230(ra) # 80001138 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001226:	8526                	mv	a0,s1
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	608080e7          	jalr	1544(ra) # 80001830 <proc_mapstacks>
}
    80001230:	8526                	mv	a0,s1
    80001232:	60e2                	ld	ra,24(sp)
    80001234:	6442                	ld	s0,16(sp)
    80001236:	64a2                	ld	s1,8(sp)
    80001238:	6902                	ld	s2,0(sp)
    8000123a:	6105                	add	sp,sp,32
    8000123c:	8082                	ret

000000008000123e <kvminit>:
{
    8000123e:	1141                	add	sp,sp,-16
    80001240:	e406                	sd	ra,8(sp)
    80001242:	e022                	sd	s0,0(sp)
    80001244:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f22080e7          	jalr	-222(ra) # 80001168 <kvmmake>
    8000124e:	00007797          	auipc	a5,0x7
    80001252:	6ea7b123          	sd	a0,1762(a5) # 80008930 <kernel_pagetable>
}
    80001256:	60a2                	ld	ra,8(sp)
    80001258:	6402                	ld	s0,0(sp)
    8000125a:	0141                	add	sp,sp,16
    8000125c:	8082                	ret

000000008000125e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125e:	715d                	add	sp,sp,-80
    80001260:	e486                	sd	ra,72(sp)
    80001262:	e0a2                	sd	s0,64(sp)
    80001264:	fc26                	sd	s1,56(sp)
    80001266:	f84a                	sd	s2,48(sp)
    80001268:	f44e                	sd	s3,40(sp)
    8000126a:	f052                	sd	s4,32(sp)
    8000126c:	ec56                	sd	s5,24(sp)
    8000126e:	e85a                	sd	s6,16(sp)
    80001270:	e45e                	sd	s7,8(sp)
    80001272:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001274:	03459793          	sll	a5,a1,0x34
    80001278:	e795                	bnez	a5,800012a4 <uvmunmap+0x46>
    8000127a:	8a2a                	mv	s4,a0
    8000127c:	892e                	mv	s2,a1
    8000127e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001280:	0632                	sll	a2,a2,0xc
    80001282:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001286:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001288:	6b05                	lui	s6,0x1
    8000128a:	0735e263          	bltu	a1,s3,800012ee <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128e:	60a6                	ld	ra,72(sp)
    80001290:	6406                	ld	s0,64(sp)
    80001292:	74e2                	ld	s1,56(sp)
    80001294:	7942                	ld	s2,48(sp)
    80001296:	79a2                	ld	s3,40(sp)
    80001298:	7a02                	ld	s4,32(sp)
    8000129a:	6ae2                	ld	s5,24(sp)
    8000129c:	6b42                	ld	s6,16(sp)
    8000129e:	6ba2                	ld	s7,8(sp)
    800012a0:	6161                	add	sp,sp,80
    800012a2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a4:	00007517          	auipc	a0,0x7
    800012a8:	e5c50513          	add	a0,a0,-420 # 80008100 <digits+0xc0>
    800012ac:	fffff097          	auipc	ra,0xfffff
    800012b0:	290080e7          	jalr	656(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    800012b4:	00007517          	auipc	a0,0x7
    800012b8:	e6450513          	add	a0,a0,-412 # 80008118 <digits+0xd8>
    800012bc:	fffff097          	auipc	ra,0xfffff
    800012c0:	280080e7          	jalr	640(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e6450513          	add	a0,a0,-412 # 80008128 <digits+0xe8>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	270080e7          	jalr	624(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e6c50513          	add	a0,a0,-404 # 80008140 <digits+0x100>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	260080e7          	jalr	608(ra) # 8000053c <panic>
    *pte = 0;
    800012e4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e8:	995a                	add	s2,s2,s6
    800012ea:	fb3972e3          	bgeu	s2,s3,8000128e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ee:	4601                	li	a2,0
    800012f0:	85ca                	mv	a1,s2
    800012f2:	8552                	mv	a0,s4
    800012f4:	00000097          	auipc	ra,0x0
    800012f8:	cbc080e7          	jalr	-836(ra) # 80000fb0 <walk>
    800012fc:	84aa                	mv	s1,a0
    800012fe:	d95d                	beqz	a0,800012b4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001300:	6108                	ld	a0,0(a0)
    80001302:	00157793          	and	a5,a0,1
    80001306:	dfdd                	beqz	a5,800012c4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001308:	3ff57793          	and	a5,a0,1023
    8000130c:	fd7784e3          	beq	a5,s7,800012d4 <uvmunmap+0x76>
    if(do_free){
    80001310:	fc0a8ae3          	beqz	s5,800012e4 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001314:	8129                	srl	a0,a0,0xa
      kfree((void*)pa);
    80001316:	0532                	sll	a0,a0,0xc
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	6cc080e7          	jalr	1740(ra) # 800009e4 <kfree>
    80001320:	b7d1                	j	800012e4 <uvmunmap+0x86>

0000000080001322 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001322:	1101                	add	sp,sp,-32
    80001324:	ec06                	sd	ra,24(sp)
    80001326:	e822                	sd	s0,16(sp)
    80001328:	e426                	sd	s1,8(sp)
    8000132a:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	7b6080e7          	jalr	1974(ra) # 80000ae2 <kalloc>
    80001334:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001336:	c519                	beqz	a0,80001344 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001338:	6605                	lui	a2,0x1
    8000133a:	4581                	li	a1,0
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	992080e7          	jalr	-1646(ra) # 80000cce <memset>
  return pagetable;
}
    80001344:	8526                	mv	a0,s1
    80001346:	60e2                	ld	ra,24(sp)
    80001348:	6442                	ld	s0,16(sp)
    8000134a:	64a2                	ld	s1,8(sp)
    8000134c:	6105                	add	sp,sp,32
    8000134e:	8082                	ret

0000000080001350 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001350:	7179                	add	sp,sp,-48
    80001352:	f406                	sd	ra,40(sp)
    80001354:	f022                	sd	s0,32(sp)
    80001356:	ec26                	sd	s1,24(sp)
    80001358:	e84a                	sd	s2,16(sp)
    8000135a:	e44e                	sd	s3,8(sp)
    8000135c:	e052                	sd	s4,0(sp)
    8000135e:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001360:	6785                	lui	a5,0x1
    80001362:	04f67863          	bgeu	a2,a5,800013b2 <uvmfirst+0x62>
    80001366:	8a2a                	mv	s4,a0
    80001368:	89ae                	mv	s3,a1
    8000136a:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000136c:	fffff097          	auipc	ra,0xfffff
    80001370:	776080e7          	jalr	1910(ra) # 80000ae2 <kalloc>
    80001374:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001376:	6605                	lui	a2,0x1
    80001378:	4581                	li	a1,0
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	954080e7          	jalr	-1708(ra) # 80000cce <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001382:	4779                	li	a4,30
    80001384:	86ca                	mv	a3,s2
    80001386:	6605                	lui	a2,0x1
    80001388:	4581                	li	a1,0
    8000138a:	8552                	mv	a0,s4
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	d0c080e7          	jalr	-756(ra) # 80001098 <mappages>
  memmove(mem, src, sz);
    80001394:	8626                	mv	a2,s1
    80001396:	85ce                	mv	a1,s3
    80001398:	854a                	mv	a0,s2
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	990080e7          	jalr	-1648(ra) # 80000d2a <memmove>
}
    800013a2:	70a2                	ld	ra,40(sp)
    800013a4:	7402                	ld	s0,32(sp)
    800013a6:	64e2                	ld	s1,24(sp)
    800013a8:	6942                	ld	s2,16(sp)
    800013aa:	69a2                	ld	s3,8(sp)
    800013ac:	6a02                	ld	s4,0(sp)
    800013ae:	6145                	add	sp,sp,48
    800013b0:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b2:	00007517          	auipc	a0,0x7
    800013b6:	da650513          	add	a0,a0,-602 # 80008158 <digits+0x118>
    800013ba:	fffff097          	auipc	ra,0xfffff
    800013be:	182080e7          	jalr	386(ra) # 8000053c <panic>

00000000800013c2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c2:	1101                	add	sp,sp,-32
    800013c4:	ec06                	sd	ra,24(sp)
    800013c6:	e822                	sd	s0,16(sp)
    800013c8:	e426                	sd	s1,8(sp)
    800013ca:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013cc:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ce:	00b67d63          	bgeu	a2,a1,800013e8 <uvmdealloc+0x26>
    800013d2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d4:	6785                	lui	a5,0x1
    800013d6:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d8:	00f60733          	add	a4,a2,a5
    800013dc:	76fd                	lui	a3,0xfffff
    800013de:	8f75                	and	a4,a4,a3
    800013e0:	97ae                	add	a5,a5,a1
    800013e2:	8ff5                	and	a5,a5,a3
    800013e4:	00f76863          	bltu	a4,a5,800013f4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e8:	8526                	mv	a0,s1
    800013ea:	60e2                	ld	ra,24(sp)
    800013ec:	6442                	ld	s0,16(sp)
    800013ee:	64a2                	ld	s1,8(sp)
    800013f0:	6105                	add	sp,sp,32
    800013f2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f4:	8f99                	sub	a5,a5,a4
    800013f6:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f8:	4685                	li	a3,1
    800013fa:	0007861b          	sext.w	a2,a5
    800013fe:	85ba                	mv	a1,a4
    80001400:	00000097          	auipc	ra,0x0
    80001404:	e5e080e7          	jalr	-418(ra) # 8000125e <uvmunmap>
    80001408:	b7c5                	j	800013e8 <uvmdealloc+0x26>

000000008000140a <uvmalloc>:
  if(newsz < oldsz)
    8000140a:	0ab66563          	bltu	a2,a1,800014b4 <uvmalloc+0xaa>
{
    8000140e:	7139                	add	sp,sp,-64
    80001410:	fc06                	sd	ra,56(sp)
    80001412:	f822                	sd	s0,48(sp)
    80001414:	f426                	sd	s1,40(sp)
    80001416:	f04a                	sd	s2,32(sp)
    80001418:	ec4e                	sd	s3,24(sp)
    8000141a:	e852                	sd	s4,16(sp)
    8000141c:	e456                	sd	s5,8(sp)
    8000141e:	e05a                	sd	s6,0(sp)
    80001420:	0080                	add	s0,sp,64
    80001422:	8aaa                	mv	s5,a0
    80001424:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001426:	6785                	lui	a5,0x1
    80001428:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000142a:	95be                	add	a1,a1,a5
    8000142c:	77fd                	lui	a5,0xfffff
    8000142e:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001432:	08c9f363          	bgeu	s3,a2,800014b8 <uvmalloc+0xae>
    80001436:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001438:	0126eb13          	or	s6,a3,18
    mem = kalloc();
    8000143c:	fffff097          	auipc	ra,0xfffff
    80001440:	6a6080e7          	jalr	1702(ra) # 80000ae2 <kalloc>
    80001444:	84aa                	mv	s1,a0
    if(mem == 0){
    80001446:	c51d                	beqz	a0,80001474 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	882080e7          	jalr	-1918(ra) # 80000cce <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001454:	875a                	mv	a4,s6
    80001456:	86a6                	mv	a3,s1
    80001458:	6605                	lui	a2,0x1
    8000145a:	85ca                	mv	a1,s2
    8000145c:	8556                	mv	a0,s5
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	c3a080e7          	jalr	-966(ra) # 80001098 <mappages>
    80001466:	e90d                	bnez	a0,80001498 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001468:	6785                	lui	a5,0x1
    8000146a:	993e                	add	s2,s2,a5
    8000146c:	fd4968e3          	bltu	s2,s4,8000143c <uvmalloc+0x32>
  return newsz;
    80001470:	8552                	mv	a0,s4
    80001472:	a809                	j	80001484 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001474:	864e                	mv	a2,s3
    80001476:	85ca                	mv	a1,s2
    80001478:	8556                	mv	a0,s5
    8000147a:	00000097          	auipc	ra,0x0
    8000147e:	f48080e7          	jalr	-184(ra) # 800013c2 <uvmdealloc>
      return 0;
    80001482:	4501                	li	a0,0
}
    80001484:	70e2                	ld	ra,56(sp)
    80001486:	7442                	ld	s0,48(sp)
    80001488:	74a2                	ld	s1,40(sp)
    8000148a:	7902                	ld	s2,32(sp)
    8000148c:	69e2                	ld	s3,24(sp)
    8000148e:	6a42                	ld	s4,16(sp)
    80001490:	6aa2                	ld	s5,8(sp)
    80001492:	6b02                	ld	s6,0(sp)
    80001494:	6121                	add	sp,sp,64
    80001496:	8082                	ret
      kfree(mem);
    80001498:	8526                	mv	a0,s1
    8000149a:	fffff097          	auipc	ra,0xfffff
    8000149e:	54a080e7          	jalr	1354(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a2:	864e                	mv	a2,s3
    800014a4:	85ca                	mv	a1,s2
    800014a6:	8556                	mv	a0,s5
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	f1a080e7          	jalr	-230(ra) # 800013c2 <uvmdealloc>
      return 0;
    800014b0:	4501                	li	a0,0
    800014b2:	bfc9                	j	80001484 <uvmalloc+0x7a>
    return oldsz;
    800014b4:	852e                	mv	a0,a1
}
    800014b6:	8082                	ret
  return newsz;
    800014b8:	8532                	mv	a0,a2
    800014ba:	b7e9                	j	80001484 <uvmalloc+0x7a>

00000000800014bc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014bc:	7179                	add	sp,sp,-48
    800014be:	f406                	sd	ra,40(sp)
    800014c0:	f022                	sd	s0,32(sp)
    800014c2:	ec26                	sd	s1,24(sp)
    800014c4:	e84a                	sd	s2,16(sp)
    800014c6:	e44e                	sd	s3,8(sp)
    800014c8:	e052                	sd	s4,0(sp)
    800014ca:	1800                	add	s0,sp,48
    800014cc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ce:	84aa                	mv	s1,a0
    800014d0:	6905                	lui	s2,0x1
    800014d2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014d4:	4985                	li	s3,1
    800014d6:	a829                	j	800014f0 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014d8:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014da:	00c79513          	sll	a0,a5,0xc
    800014de:	00000097          	auipc	ra,0x0
    800014e2:	fde080e7          	jalr	-34(ra) # 800014bc <freewalk>
      pagetable[i] = 0;
    800014e6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ea:	04a1                	add	s1,s1,8
    800014ec:	03248163          	beq	s1,s2,8000150e <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f0:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f2:	00f7f713          	and	a4,a5,15
    800014f6:	ff3701e3          	beq	a4,s3,800014d8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fa:	8b85                	and	a5,a5,1
    800014fc:	d7fd                	beqz	a5,800014ea <freewalk+0x2e>
      panic("freewalk: leaf");
    800014fe:	00007517          	auipc	a0,0x7
    80001502:	c7a50513          	add	a0,a0,-902 # 80008178 <digits+0x138>
    80001506:	fffff097          	auipc	ra,0xfffff
    8000150a:	036080e7          	jalr	54(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    8000150e:	8552                	mv	a0,s4
    80001510:	fffff097          	auipc	ra,0xfffff
    80001514:	4d4080e7          	jalr	1236(ra) # 800009e4 <kfree>
}
    80001518:	70a2                	ld	ra,40(sp)
    8000151a:	7402                	ld	s0,32(sp)
    8000151c:	64e2                	ld	s1,24(sp)
    8000151e:	6942                	ld	s2,16(sp)
    80001520:	69a2                	ld	s3,8(sp)
    80001522:	6a02                	ld	s4,0(sp)
    80001524:	6145                	add	sp,sp,48
    80001526:	8082                	ret

0000000080001528 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001528:	1101                	add	sp,sp,-32
    8000152a:	ec06                	sd	ra,24(sp)
    8000152c:	e822                	sd	s0,16(sp)
    8000152e:	e426                	sd	s1,8(sp)
    80001530:	1000                	add	s0,sp,32
    80001532:	84aa                	mv	s1,a0
  if(sz > 0)
    80001534:	e999                	bnez	a1,8000154a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001536:	8526                	mv	a0,s1
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	f84080e7          	jalr	-124(ra) # 800014bc <freewalk>
}
    80001540:	60e2                	ld	ra,24(sp)
    80001542:	6442                	ld	s0,16(sp)
    80001544:	64a2                	ld	s1,8(sp)
    80001546:	6105                	add	sp,sp,32
    80001548:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154a:	6785                	lui	a5,0x1
    8000154c:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000154e:	95be                	add	a1,a1,a5
    80001550:	4685                	li	a3,1
    80001552:	00c5d613          	srl	a2,a1,0xc
    80001556:	4581                	li	a1,0
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	d06080e7          	jalr	-762(ra) # 8000125e <uvmunmap>
    80001560:	bfd9                	j	80001536 <uvmfree+0xe>

0000000080001562 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001562:	c679                	beqz	a2,80001630 <uvmcopy+0xce>
{
    80001564:	715d                	add	sp,sp,-80
    80001566:	e486                	sd	ra,72(sp)
    80001568:	e0a2                	sd	s0,64(sp)
    8000156a:	fc26                	sd	s1,56(sp)
    8000156c:	f84a                	sd	s2,48(sp)
    8000156e:	f44e                	sd	s3,40(sp)
    80001570:	f052                	sd	s4,32(sp)
    80001572:	ec56                	sd	s5,24(sp)
    80001574:	e85a                	sd	s6,16(sp)
    80001576:	e45e                	sd	s7,8(sp)
    80001578:	0880                	add	s0,sp,80
    8000157a:	8b2a                	mv	s6,a0
    8000157c:	8aae                	mv	s5,a1
    8000157e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001580:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001582:	4601                	li	a2,0
    80001584:	85ce                	mv	a1,s3
    80001586:	855a                	mv	a0,s6
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	a28080e7          	jalr	-1496(ra) # 80000fb0 <walk>
    80001590:	c531                	beqz	a0,800015dc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001592:	6118                	ld	a4,0(a0)
    80001594:	00177793          	and	a5,a4,1
    80001598:	cbb1                	beqz	a5,800015ec <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159a:	00a75593          	srl	a1,a4,0xa
    8000159e:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a2:	3ff77493          	and	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	53c080e7          	jalr	1340(ra) # 80000ae2 <kalloc>
    800015ae:	892a                	mv	s2,a0
    800015b0:	c939                	beqz	a0,80001606 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85de                	mv	a1,s7
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	774080e7          	jalr	1908(ra) # 80000d2a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015be:	8726                	mv	a4,s1
    800015c0:	86ca                	mv	a3,s2
    800015c2:	6605                	lui	a2,0x1
    800015c4:	85ce                	mv	a1,s3
    800015c6:	8556                	mv	a0,s5
    800015c8:	00000097          	auipc	ra,0x0
    800015cc:	ad0080e7          	jalr	-1328(ra) # 80001098 <mappages>
    800015d0:	e515                	bnez	a0,800015fc <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d2:	6785                	lui	a5,0x1
    800015d4:	99be                	add	s3,s3,a5
    800015d6:	fb49e6e3          	bltu	s3,s4,80001582 <uvmcopy+0x20>
    800015da:	a081                	j	8000161a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bac50513          	add	a0,a0,-1108 # 80008188 <digits+0x148>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f58080e7          	jalr	-168(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800015ec:	00007517          	auipc	a0,0x7
    800015f0:	bbc50513          	add	a0,a0,-1092 # 800081a8 <digits+0x168>
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	f48080e7          	jalr	-184(ra) # 8000053c <panic>
      kfree(mem);
    800015fc:	854a                	mv	a0,s2
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	3e6080e7          	jalr	998(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001606:	4685                	li	a3,1
    80001608:	00c9d613          	srl	a2,s3,0xc
    8000160c:	4581                	li	a1,0
    8000160e:	8556                	mv	a0,s5
    80001610:	00000097          	auipc	ra,0x0
    80001614:	c4e080e7          	jalr	-946(ra) # 8000125e <uvmunmap>
  return -1;
    80001618:	557d                	li	a0,-1
}
    8000161a:	60a6                	ld	ra,72(sp)
    8000161c:	6406                	ld	s0,64(sp)
    8000161e:	74e2                	ld	s1,56(sp)
    80001620:	7942                	ld	s2,48(sp)
    80001622:	79a2                	ld	s3,40(sp)
    80001624:	7a02                	ld	s4,32(sp)
    80001626:	6ae2                	ld	s5,24(sp)
    80001628:	6b42                	ld	s6,16(sp)
    8000162a:	6ba2                	ld	s7,8(sp)
    8000162c:	6161                	add	sp,sp,80
    8000162e:	8082                	ret
  return 0;
    80001630:	4501                	li	a0,0
}
    80001632:	8082                	ret

0000000080001634 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001634:	1141                	add	sp,sp,-16
    80001636:	e406                	sd	ra,8(sp)
    80001638:	e022                	sd	s0,0(sp)
    8000163a:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163c:	4601                	li	a2,0
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	972080e7          	jalr	-1678(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001646:	c901                	beqz	a0,80001656 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001648:	611c                	ld	a5,0(a0)
    8000164a:	9bbd                	and	a5,a5,-17
    8000164c:	e11c                	sd	a5,0(a0)
}
    8000164e:	60a2                	ld	ra,8(sp)
    80001650:	6402                	ld	s0,0(sp)
    80001652:	0141                	add	sp,sp,16
    80001654:	8082                	ret
    panic("uvmclear");
    80001656:	00007517          	auipc	a0,0x7
    8000165a:	b7250513          	add	a0,a0,-1166 # 800081c8 <digits+0x188>
    8000165e:	fffff097          	auipc	ra,0xfffff
    80001662:	ede080e7          	jalr	-290(ra) # 8000053c <panic>

0000000080001666 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001666:	c6bd                	beqz	a3,800016d4 <copyout+0x6e>
{
    80001668:	715d                	add	sp,sp,-80
    8000166a:	e486                	sd	ra,72(sp)
    8000166c:	e0a2                	sd	s0,64(sp)
    8000166e:	fc26                	sd	s1,56(sp)
    80001670:	f84a                	sd	s2,48(sp)
    80001672:	f44e                	sd	s3,40(sp)
    80001674:	f052                	sd	s4,32(sp)
    80001676:	ec56                	sd	s5,24(sp)
    80001678:	e85a                	sd	s6,16(sp)
    8000167a:	e45e                	sd	s7,8(sp)
    8000167c:	e062                	sd	s8,0(sp)
    8000167e:	0880                	add	s0,sp,80
    80001680:	8b2a                	mv	s6,a0
    80001682:	8c2e                	mv	s8,a1
    80001684:	8a32                	mv	s4,a2
    80001686:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001688:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168a:	6a85                	lui	s5,0x1
    8000168c:	a015                	j	800016b0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000168e:	9562                	add	a0,a0,s8
    80001690:	0004861b          	sext.w	a2,s1
    80001694:	85d2                	mv	a1,s4
    80001696:	41250533          	sub	a0,a0,s2
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	690080e7          	jalr	1680(ra) # 80000d2a <memmove>

    len -= n;
    800016a2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016a8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ac:	02098263          	beqz	s3,800016d0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b4:	85ca                	mv	a1,s2
    800016b6:	855a                	mv	a0,s6
    800016b8:	00000097          	auipc	ra,0x0
    800016bc:	99e080e7          	jalr	-1634(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    800016c0:	cd01                	beqz	a0,800016d8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c2:	418904b3          	sub	s1,s2,s8
    800016c6:	94d6                	add	s1,s1,s5
    800016c8:	fc99f3e3          	bgeu	s3,s1,8000168e <copyout+0x28>
    800016cc:	84ce                	mv	s1,s3
    800016ce:	b7c1                	j	8000168e <copyout+0x28>
  }
  return 0;
    800016d0:	4501                	li	a0,0
    800016d2:	a021                	j	800016da <copyout+0x74>
    800016d4:	4501                	li	a0,0
}
    800016d6:	8082                	ret
      return -1;
    800016d8:	557d                	li	a0,-1
}
    800016da:	60a6                	ld	ra,72(sp)
    800016dc:	6406                	ld	s0,64(sp)
    800016de:	74e2                	ld	s1,56(sp)
    800016e0:	7942                	ld	s2,48(sp)
    800016e2:	79a2                	ld	s3,40(sp)
    800016e4:	7a02                	ld	s4,32(sp)
    800016e6:	6ae2                	ld	s5,24(sp)
    800016e8:	6b42                	ld	s6,16(sp)
    800016ea:	6ba2                	ld	s7,8(sp)
    800016ec:	6c02                	ld	s8,0(sp)
    800016ee:	6161                	add	sp,sp,80
    800016f0:	8082                	ret

00000000800016f2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f2:	caa5                	beqz	a3,80001762 <copyin+0x70>
{
    800016f4:	715d                	add	sp,sp,-80
    800016f6:	e486                	sd	ra,72(sp)
    800016f8:	e0a2                	sd	s0,64(sp)
    800016fa:	fc26                	sd	s1,56(sp)
    800016fc:	f84a                	sd	s2,48(sp)
    800016fe:	f44e                	sd	s3,40(sp)
    80001700:	f052                	sd	s4,32(sp)
    80001702:	ec56                	sd	s5,24(sp)
    80001704:	e85a                	sd	s6,16(sp)
    80001706:	e45e                	sd	s7,8(sp)
    80001708:	e062                	sd	s8,0(sp)
    8000170a:	0880                	add	s0,sp,80
    8000170c:	8b2a                	mv	s6,a0
    8000170e:	8a2e                	mv	s4,a1
    80001710:	8c32                	mv	s8,a2
    80001712:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001714:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001716:	6a85                	lui	s5,0x1
    80001718:	a01d                	j	8000173e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171a:	018505b3          	add	a1,a0,s8
    8000171e:	0004861b          	sext.w	a2,s1
    80001722:	412585b3          	sub	a1,a1,s2
    80001726:	8552                	mv	a0,s4
    80001728:	fffff097          	auipc	ra,0xfffff
    8000172c:	602080e7          	jalr	1538(ra) # 80000d2a <memmove>

    len -= n;
    80001730:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001734:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001736:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173a:	02098263          	beqz	s3,8000175e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000173e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001742:	85ca                	mv	a1,s2
    80001744:	855a                	mv	a0,s6
    80001746:	00000097          	auipc	ra,0x0
    8000174a:	910080e7          	jalr	-1776(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    8000174e:	cd01                	beqz	a0,80001766 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001750:	418904b3          	sub	s1,s2,s8
    80001754:	94d6                	add	s1,s1,s5
    80001756:	fc99f2e3          	bgeu	s3,s1,8000171a <copyin+0x28>
    8000175a:	84ce                	mv	s1,s3
    8000175c:	bf7d                	j	8000171a <copyin+0x28>
  }
  return 0;
    8000175e:	4501                	li	a0,0
    80001760:	a021                	j	80001768 <copyin+0x76>
    80001762:	4501                	li	a0,0
}
    80001764:	8082                	ret
      return -1;
    80001766:	557d                	li	a0,-1
}
    80001768:	60a6                	ld	ra,72(sp)
    8000176a:	6406                	ld	s0,64(sp)
    8000176c:	74e2                	ld	s1,56(sp)
    8000176e:	7942                	ld	s2,48(sp)
    80001770:	79a2                	ld	s3,40(sp)
    80001772:	7a02                	ld	s4,32(sp)
    80001774:	6ae2                	ld	s5,24(sp)
    80001776:	6b42                	ld	s6,16(sp)
    80001778:	6ba2                	ld	s7,8(sp)
    8000177a:	6c02                	ld	s8,0(sp)
    8000177c:	6161                	add	sp,sp,80
    8000177e:	8082                	ret

0000000080001780 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001780:	c2dd                	beqz	a3,80001826 <copyinstr+0xa6>
{
    80001782:	715d                	add	sp,sp,-80
    80001784:	e486                	sd	ra,72(sp)
    80001786:	e0a2                	sd	s0,64(sp)
    80001788:	fc26                	sd	s1,56(sp)
    8000178a:	f84a                	sd	s2,48(sp)
    8000178c:	f44e                	sd	s3,40(sp)
    8000178e:	f052                	sd	s4,32(sp)
    80001790:	ec56                	sd	s5,24(sp)
    80001792:	e85a                	sd	s6,16(sp)
    80001794:	e45e                	sd	s7,8(sp)
    80001796:	0880                	add	s0,sp,80
    80001798:	8a2a                	mv	s4,a0
    8000179a:	8b2e                	mv	s6,a1
    8000179c:	8bb2                	mv	s7,a2
    8000179e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a2:	6985                	lui	s3,0x1
    800017a4:	a02d                	j	800017ce <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017aa:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ac:	37fd                	addw	a5,a5,-1
    800017ae:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b2:	60a6                	ld	ra,72(sp)
    800017b4:	6406                	ld	s0,64(sp)
    800017b6:	74e2                	ld	s1,56(sp)
    800017b8:	7942                	ld	s2,48(sp)
    800017ba:	79a2                	ld	s3,40(sp)
    800017bc:	7a02                	ld	s4,32(sp)
    800017be:	6ae2                	ld	s5,24(sp)
    800017c0:	6b42                	ld	s6,16(sp)
    800017c2:	6ba2                	ld	s7,8(sp)
    800017c4:	6161                	add	sp,sp,80
    800017c6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017c8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017cc:	c8a9                	beqz	s1,8000181e <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017ce:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d2:	85ca                	mv	a1,s2
    800017d4:	8552                	mv	a0,s4
    800017d6:	00000097          	auipc	ra,0x0
    800017da:	880080e7          	jalr	-1920(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    800017de:	c131                	beqz	a0,80001822 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e0:	417906b3          	sub	a3,s2,s7
    800017e4:	96ce                	add	a3,a3,s3
    800017e6:	00d4f363          	bgeu	s1,a3,800017ec <copyinstr+0x6c>
    800017ea:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017ec:	955e                	add	a0,a0,s7
    800017ee:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f2:	daf9                	beqz	a3,800017c8 <copyinstr+0x48>
    800017f4:	87da                	mv	a5,s6
    800017f6:	885a                	mv	a6,s6
      if(*p == '\0'){
    800017f8:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800017fc:	96da                	add	a3,a3,s6
    800017fe:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001800:	00f60733          	add	a4,a2,a5
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8ca0>
    80001808:	df59                	beqz	a4,800017a6 <copyinstr+0x26>
        *dst = *p;
    8000180a:	00e78023          	sb	a4,0(a5)
      dst++;
    8000180e:	0785                	add	a5,a5,1
    while(n > 0){
    80001810:	fed797e3          	bne	a5,a3,800017fe <copyinstr+0x7e>
    80001814:	14fd                	add	s1,s1,-1
    80001816:	94c2                	add	s1,s1,a6
      --max;
    80001818:	8c8d                	sub	s1,s1,a1
      dst++;
    8000181a:	8b3e                	mv	s6,a5
    8000181c:	b775                	j	800017c8 <copyinstr+0x48>
    8000181e:	4781                	li	a5,0
    80001820:	b771                	j	800017ac <copyinstr+0x2c>
      return -1;
    80001822:	557d                	li	a0,-1
    80001824:	b779                	j	800017b2 <copyinstr+0x32>
  int got_null = 0;
    80001826:	4781                	li	a5,0
  if(got_null){
    80001828:	37fd                	addw	a5,a5,-1
    8000182a:	0007851b          	sext.w	a0,a5
}
    8000182e:	8082                	ret

0000000080001830 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001830:	7139                	add	sp,sp,-64
    80001832:	fc06                	sd	ra,56(sp)
    80001834:	f822                	sd	s0,48(sp)
    80001836:	f426                	sd	s1,40(sp)
    80001838:	f04a                	sd	s2,32(sp)
    8000183a:	ec4e                	sd	s3,24(sp)
    8000183c:	e852                	sd	s4,16(sp)
    8000183e:	e456                	sd	s5,8(sp)
    80001840:	e05a                	sd	s6,0(sp)
    80001842:	0080                	add	s0,sp,64
    80001844:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001846:	00010497          	auipc	s1,0x10
    8000184a:	b9a48493          	add	s1,s1,-1126 # 800113e0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000184e:	8b26                	mv	s6,s1
    80001850:	00006a97          	auipc	s5,0x6
    80001854:	7b0a8a93          	add	s5,s5,1968 # 80008000 <etext>
    80001858:	04000937          	lui	s2,0x4000
    8000185c:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000185e:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001860:	00015a17          	auipc	s4,0x15
    80001864:	580a0a13          	add	s4,s4,1408 # 80016de0 <tickslock>
    char *pa = kalloc();
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	27a080e7          	jalr	634(ra) # 80000ae2 <kalloc>
    80001870:	862a                	mv	a2,a0
    if(pa == 0)
    80001872:	c131                	beqz	a0,800018b6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001874:	416485b3          	sub	a1,s1,s6
    80001878:	858d                	sra	a1,a1,0x3
    8000187a:	000ab783          	ld	a5,0(s5)
    8000187e:	02f585b3          	mul	a1,a1,a5
    80001882:	2585                	addw	a1,a1,1
    80001884:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001888:	4719                	li	a4,6
    8000188a:	6685                	lui	a3,0x1
    8000188c:	40b905b3          	sub	a1,s2,a1
    80001890:	854e                	mv	a0,s3
    80001892:	00000097          	auipc	ra,0x0
    80001896:	8a6080e7          	jalr	-1882(ra) # 80001138 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000189a:	16848493          	add	s1,s1,360
    8000189e:	fd4495e3          	bne	s1,s4,80001868 <proc_mapstacks+0x38>
  }
}
    800018a2:	70e2                	ld	ra,56(sp)
    800018a4:	7442                	ld	s0,48(sp)
    800018a6:	74a2                	ld	s1,40(sp)
    800018a8:	7902                	ld	s2,32(sp)
    800018aa:	69e2                	ld	s3,24(sp)
    800018ac:	6a42                	ld	s4,16(sp)
    800018ae:	6aa2                	ld	s5,8(sp)
    800018b0:	6b02                	ld	s6,0(sp)
    800018b2:	6121                	add	sp,sp,64
    800018b4:	8082                	ret
      panic("kalloc");
    800018b6:	00007517          	auipc	a0,0x7
    800018ba:	92250513          	add	a0,a0,-1758 # 800081d8 <digits+0x198>
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	c7e080e7          	jalr	-898(ra) # 8000053c <panic>

00000000800018c6 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018c6:	7139                	add	sp,sp,-64
    800018c8:	fc06                	sd	ra,56(sp)
    800018ca:	f822                	sd	s0,48(sp)
    800018cc:	f426                	sd	s1,40(sp)
    800018ce:	f04a                	sd	s2,32(sp)
    800018d0:	ec4e                	sd	s3,24(sp)
    800018d2:	e852                	sd	s4,16(sp)
    800018d4:	e456                	sd	s5,8(sp)
    800018d6:	e05a                	sd	s6,0(sp)
    800018d8:	0080                	add	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018da:	00007597          	auipc	a1,0x7
    800018de:	90658593          	add	a1,a1,-1786 # 800081e0 <digits+0x1a0>
    800018e2:	0000f517          	auipc	a0,0xf
    800018e6:	2ce50513          	add	a0,a0,718 # 80010bb0 <pid_lock>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	258080e7          	jalr	600(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f2:	00007597          	auipc	a1,0x7
    800018f6:	8f658593          	add	a1,a1,-1802 # 800081e8 <digits+0x1a8>
    800018fa:	0000f517          	auipc	a0,0xf
    800018fe:	2ce50513          	add	a0,a0,718 # 80010bc8 <wait_lock>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	240080e7          	jalr	576(ra) # 80000b42 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000190a:	00010497          	auipc	s1,0x10
    8000190e:	ad648493          	add	s1,s1,-1322 # 800113e0 <proc>
      initlock(&p->lock, "proc");
    80001912:	00007b17          	auipc	s6,0x7
    80001916:	8e6b0b13          	add	s6,s6,-1818 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000191a:	8aa6                	mv	s5,s1
    8000191c:	00006a17          	auipc	s4,0x6
    80001920:	6e4a0a13          	add	s4,s4,1764 # 80008000 <etext>
    80001924:	04000937          	lui	s2,0x4000
    80001928:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000192a:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192c:	00015997          	auipc	s3,0x15
    80001930:	4b498993          	add	s3,s3,1204 # 80016de0 <tickslock>
      initlock(&p->lock, "proc");
    80001934:	85da                	mv	a1,s6
    80001936:	8526                	mv	a0,s1
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	20a080e7          	jalr	522(ra) # 80000b42 <initlock>
      p->state = UNUSED;
    80001940:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001944:	415487b3          	sub	a5,s1,s5
    80001948:	878d                	sra	a5,a5,0x3
    8000194a:	000a3703          	ld	a4,0(s4)
    8000194e:	02e787b3          	mul	a5,a5,a4
    80001952:	2785                	addw	a5,a5,1
    80001954:	00d7979b          	sllw	a5,a5,0xd
    80001958:	40f907b3          	sub	a5,s2,a5
    8000195c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195e:	16848493          	add	s1,s1,360
    80001962:	fd3499e3          	bne	s1,s3,80001934 <procinit+0x6e>
  }
}
    80001966:	70e2                	ld	ra,56(sp)
    80001968:	7442                	ld	s0,48(sp)
    8000196a:	74a2                	ld	s1,40(sp)
    8000196c:	7902                	ld	s2,32(sp)
    8000196e:	69e2                	ld	s3,24(sp)
    80001970:	6a42                	ld	s4,16(sp)
    80001972:	6aa2                	ld	s5,8(sp)
    80001974:	6b02                	ld	s6,0(sp)
    80001976:	6121                	add	sp,sp,64
    80001978:	8082                	ret

000000008000197a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000197a:	1141                	add	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001980:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001982:	2501                	sext.w	a0,a0
    80001984:	6422                	ld	s0,8(sp)
    80001986:	0141                	add	sp,sp,16
    80001988:	8082                	ret

000000008000198a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    8000198a:	1141                	add	sp,sp,-16
    8000198c:	e422                	sd	s0,8(sp)
    8000198e:	0800                	add	s0,sp,16
    80001990:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001992:	2781                	sext.w	a5,a5
    80001994:	079e                	sll	a5,a5,0x7
  return c;
}
    80001996:	0000f517          	auipc	a0,0xf
    8000199a:	24a50513          	add	a0,a0,586 # 80010be0 <cpus>
    8000199e:	953e                	add	a0,a0,a5
    800019a0:	6422                	ld	s0,8(sp)
    800019a2:	0141                	add	sp,sp,16
    800019a4:	8082                	ret

00000000800019a6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019a6:	1101                	add	sp,sp,-32
    800019a8:	ec06                	sd	ra,24(sp)
    800019aa:	e822                	sd	s0,16(sp)
    800019ac:	e426                	sd	s1,8(sp)
    800019ae:	1000                	add	s0,sp,32
  push_off();
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	1d6080e7          	jalr	470(ra) # 80000b86 <push_off>
    800019b8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019ba:	2781                	sext.w	a5,a5
    800019bc:	079e                	sll	a5,a5,0x7
    800019be:	0000f717          	auipc	a4,0xf
    800019c2:	1f270713          	add	a4,a4,498 # 80010bb0 <pid_lock>
    800019c6:	97ba                	add	a5,a5,a4
    800019c8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	25c080e7          	jalr	604(ra) # 80000c26 <pop_off>
  return p;
}
    800019d2:	8526                	mv	a0,s1
    800019d4:	60e2                	ld	ra,24(sp)
    800019d6:	6442                	ld	s0,16(sp)
    800019d8:	64a2                	ld	s1,8(sp)
    800019da:	6105                	add	sp,sp,32
    800019dc:	8082                	ret

00000000800019de <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019de:	1141                	add	sp,sp,-16
    800019e0:	e406                	sd	ra,8(sp)
    800019e2:	e022                	sd	s0,0(sp)
    800019e4:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019e6:	00000097          	auipc	ra,0x0
    800019ea:	fc0080e7          	jalr	-64(ra) # 800019a6 <myproc>
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	298080e7          	jalr	664(ra) # 80000c86 <release>

  if (first) {
    800019f6:	00007797          	auipc	a5,0x7
    800019fa:	eca7a783          	lw	a5,-310(a5) # 800088c0 <first.1>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	f72080e7          	jalr	-142(ra) # 80002972 <usertrapret>
}
    80001a08:	60a2                	ld	ra,8(sp)
    80001a0a:	6402                	ld	s0,0(sp)
    80001a0c:	0141                	add	sp,sp,16
    80001a0e:	8082                	ret
    first = 0;
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	ea07a823          	sw	zero,-336(a5) # 800088c0 <first.1>
    fsinit(ROOTDEV);
    80001a18:	4505                	li	a0,1
    80001a1a:	00002097          	auipc	ra,0x2
    80001a1e:	d14080e7          	jalr	-748(ra) # 8000372e <fsinit>
    80001a22:	bff9                	j	80001a00 <forkret+0x22>

0000000080001a24 <allocpid>:
{
    80001a24:	1101                	add	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	e04a                	sd	s2,0(sp)
    80001a2e:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001a30:	0000f917          	auipc	s2,0xf
    80001a34:	18090913          	add	s2,s2,384 # 80010bb0 <pid_lock>
    80001a38:	854a                	mv	a0,s2
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	198080e7          	jalr	408(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	e8278793          	add	a5,a5,-382 # 800088c4 <nextpid>
    80001a4a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a4c:	0014871b          	addw	a4,s1,1
    80001a50:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a52:	854a                	mv	a0,s2
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	232080e7          	jalr	562(ra) # 80000c86 <release>
}
    80001a5c:	8526                	mv	a0,s1
    80001a5e:	60e2                	ld	ra,24(sp)
    80001a60:	6442                	ld	s0,16(sp)
    80001a62:	64a2                	ld	s1,8(sp)
    80001a64:	6902                	ld	s2,0(sp)
    80001a66:	6105                	add	sp,sp,32
    80001a68:	8082                	ret

0000000080001a6a <proc_pagetable>:
{
    80001a6a:	1101                	add	sp,sp,-32
    80001a6c:	ec06                	sd	ra,24(sp)
    80001a6e:	e822                	sd	s0,16(sp)
    80001a70:	e426                	sd	s1,8(sp)
    80001a72:	e04a                	sd	s2,0(sp)
    80001a74:	1000                	add	s0,sp,32
    80001a76:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a78:	00000097          	auipc	ra,0x0
    80001a7c:	8aa080e7          	jalr	-1878(ra) # 80001322 <uvmcreate>
    80001a80:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a82:	c121                	beqz	a0,80001ac2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a84:	4729                	li	a4,10
    80001a86:	00005697          	auipc	a3,0x5
    80001a8a:	57a68693          	add	a3,a3,1402 # 80007000 <_trampoline>
    80001a8e:	6605                	lui	a2,0x1
    80001a90:	040005b7          	lui	a1,0x4000
    80001a94:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a96:	05b2                	sll	a1,a1,0xc
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	600080e7          	jalr	1536(ra) # 80001098 <mappages>
    80001aa0:	02054863          	bltz	a0,80001ad0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aa4:	4719                	li	a4,6
    80001aa6:	05893683          	ld	a3,88(s2)
    80001aaa:	6605                	lui	a2,0x1
    80001aac:	020005b7          	lui	a1,0x2000
    80001ab0:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab2:	05b6                	sll	a1,a1,0xd
    80001ab4:	8526                	mv	a0,s1
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	5e2080e7          	jalr	1506(ra) # 80001098 <mappages>
    80001abe:	02054163          	bltz	a0,80001ae0 <proc_pagetable+0x76>
}
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	60e2                	ld	ra,24(sp)
    80001ac6:	6442                	ld	s0,16(sp)
    80001ac8:	64a2                	ld	s1,8(sp)
    80001aca:	6902                	ld	s2,0(sp)
    80001acc:	6105                	add	sp,sp,32
    80001ace:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad0:	4581                	li	a1,0
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	a54080e7          	jalr	-1452(ra) # 80001528 <uvmfree>
    return 0;
    80001adc:	4481                	li	s1,0
    80001ade:	b7d5                	j	80001ac2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae0:	4681                	li	a3,0
    80001ae2:	4605                	li	a2,1
    80001ae4:	040005b7          	lui	a1,0x4000
    80001ae8:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aea:	05b2                	sll	a1,a1,0xc
    80001aec:	8526                	mv	a0,s1
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	770080e7          	jalr	1904(ra) # 8000125e <uvmunmap>
    uvmfree(pagetable, 0);
    80001af6:	4581                	li	a1,0
    80001af8:	8526                	mv	a0,s1
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	a2e080e7          	jalr	-1490(ra) # 80001528 <uvmfree>
    return 0;
    80001b02:	4481                	li	s1,0
    80001b04:	bf7d                	j	80001ac2 <proc_pagetable+0x58>

0000000080001b06 <proc_freepagetable>:
{
    80001b06:	1101                	add	sp,sp,-32
    80001b08:	ec06                	sd	ra,24(sp)
    80001b0a:	e822                	sd	s0,16(sp)
    80001b0c:	e426                	sd	s1,8(sp)
    80001b0e:	e04a                	sd	s2,0(sp)
    80001b10:	1000                	add	s0,sp,32
    80001b12:	84aa                	mv	s1,a0
    80001b14:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b16:	4681                	li	a3,0
    80001b18:	4605                	li	a2,1
    80001b1a:	040005b7          	lui	a1,0x4000
    80001b1e:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b20:	05b2                	sll	a1,a1,0xc
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	73c080e7          	jalr	1852(ra) # 8000125e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b2a:	4681                	li	a3,0
    80001b2c:	4605                	li	a2,1
    80001b2e:	020005b7          	lui	a1,0x2000
    80001b32:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b34:	05b6                	sll	a1,a1,0xd
    80001b36:	8526                	mv	a0,s1
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	726080e7          	jalr	1830(ra) # 8000125e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b40:	85ca                	mv	a1,s2
    80001b42:	8526                	mv	a0,s1
    80001b44:	00000097          	auipc	ra,0x0
    80001b48:	9e4080e7          	jalr	-1564(ra) # 80001528 <uvmfree>
}
    80001b4c:	60e2                	ld	ra,24(sp)
    80001b4e:	6442                	ld	s0,16(sp)
    80001b50:	64a2                	ld	s1,8(sp)
    80001b52:	6902                	ld	s2,0(sp)
    80001b54:	6105                	add	sp,sp,32
    80001b56:	8082                	ret

0000000080001b58 <freeproc>:
{
    80001b58:	1101                	add	sp,sp,-32
    80001b5a:	ec06                	sd	ra,24(sp)
    80001b5c:	e822                	sd	s0,16(sp)
    80001b5e:	e426                	sd	s1,8(sp)
    80001b60:	1000                	add	s0,sp,32
    80001b62:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b64:	6d28                	ld	a0,88(a0)
    80001b66:	c509                	beqz	a0,80001b70 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	e7c080e7          	jalr	-388(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001b70:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b74:	68a8                	ld	a0,80(s1)
    80001b76:	c511                	beqz	a0,80001b82 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b78:	64ac                	ld	a1,72(s1)
    80001b7a:	00000097          	auipc	ra,0x0
    80001b7e:	f8c080e7          	jalr	-116(ra) # 80001b06 <proc_freepagetable>
  for (int i = 0; i < NPROC; i++){
    80001b82:	00007597          	auipc	a1,0x7
    80001b86:	dbe5a583          	lw	a1,-578(a1) # 80008940 <totaltickets>
    80001b8a:	0000f797          	auipc	a5,0xf
    80001b8e:	45678793          	add	a5,a5,1110 # 80010fe0 <s>
    80001b92:	0000f617          	auipc	a2,0xf
    80001b96:	54e60613          	add	a2,a2,1358 # 800110e0 <s+0x100>
{
    80001b9a:	4501                	li	a0,0
      (&s)->inuse[i] = 0;
    80001b9c:	4805                	li	a6,1
    80001b9e:	a021                	j	80001ba6 <freeproc+0x4e>
  for (int i = 0; i < NPROC; i++){
    80001ba0:	0791                	add	a5,a5,4
    80001ba2:	02c78063          	beq	a5,a2,80001bc2 <freeproc+0x6a>
    if (p->pid == (&s)->pid[i]){
    80001ba6:	5894                	lw	a3,48(s1)
    80001ba8:	2007a703          	lw	a4,512(a5)
    80001bac:	fee69ae3          	bne	a3,a4,80001ba0 <freeproc+0x48>
      totaltickets = totaltickets - (&s)->tickets[i];
    80001bb0:	1007a703          	lw	a4,256(a5)
    80001bb4:	9d99                	subw	a1,a1,a4
      (&s)->tickets[i] = 0;
    80001bb6:	1007a023          	sw	zero,256(a5)
      (&s)->inuse[i] = 0;
    80001bba:	0007a023          	sw	zero,0(a5)
    80001bbe:	8542                	mv	a0,a6
    80001bc0:	b7c5                	j	80001ba0 <freeproc+0x48>
    80001bc2:	c509                	beqz	a0,80001bcc <freeproc+0x74>
    80001bc4:	00007797          	auipc	a5,0x7
    80001bc8:	d6b7ae23          	sw	a1,-644(a5) # 80008940 <totaltickets>
  p->pagetable = 0;
    80001bcc:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bd0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bd4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bd8:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bdc:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001be0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001be4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001be8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bec:	0004ac23          	sw	zero,24(s1)
}
    80001bf0:	60e2                	ld	ra,24(sp)
    80001bf2:	6442                	ld	s0,16(sp)
    80001bf4:	64a2                	ld	s1,8(sp)
    80001bf6:	6105                	add	sp,sp,32
    80001bf8:	8082                	ret

0000000080001bfa <allocproc>:
{
    80001bfa:	1101                	add	sp,sp,-32
    80001bfc:	ec06                	sd	ra,24(sp)
    80001bfe:	e822                	sd	s0,16(sp)
    80001c00:	e426                	sd	s1,8(sp)
    80001c02:	e04a                	sd	s2,0(sp)
    80001c04:	1000                	add	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c06:	0000f497          	auipc	s1,0xf
    80001c0a:	7da48493          	add	s1,s1,2010 # 800113e0 <proc>
    80001c0e:	00015917          	auipc	s2,0x15
    80001c12:	1d290913          	add	s2,s2,466 # 80016de0 <tickslock>
    acquire(&p->lock);
    80001c16:	8526                	mv	a0,s1
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	fba080e7          	jalr	-70(ra) # 80000bd2 <acquire>
    if(p->state == UNUSED) {
    80001c20:	4c9c                	lw	a5,24(s1)
    80001c22:	cf81                	beqz	a5,80001c3a <allocproc+0x40>
      release(&p->lock);
    80001c24:	8526                	mv	a0,s1
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	060080e7          	jalr	96(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c2e:	16848493          	add	s1,s1,360
    80001c32:	ff2492e3          	bne	s1,s2,80001c16 <allocproc+0x1c>
  return 0;
    80001c36:	4481                	li	s1,0
    80001c38:	a855                	j	80001cec <allocproc+0xf2>
  p->pid = allocpid();
    80001c3a:	00000097          	auipc	ra,0x0
    80001c3e:	dea080e7          	jalr	-534(ra) # 80001a24 <allocpid>
    80001c42:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c44:	4785                	li	a5,1
    80001c46:	cc9c                	sw	a5,24(s1)
  for (int i = 0; i < NPROC; i++){
    80001c48:	0000f717          	auipc	a4,0xf
    80001c4c:	39870713          	add	a4,a4,920 # 80010fe0 <s>
    80001c50:	4781                	li	a5,0
    80001c52:	04000613          	li	a2,64
    if ((&s)->inuse[i] == 0){
    80001c56:	4314                	lw	a3,0(a4)
    80001c58:	c691                	beqz	a3,80001c64 <allocproc+0x6a>
  for (int i = 0; i < NPROC; i++){
    80001c5a:	2785                	addw	a5,a5,1
    80001c5c:	0711                	add	a4,a4,4
    80001c5e:	fec79ce3          	bne	a5,a2,80001c56 <allocproc+0x5c>
    80001c62:	a0a1                	j	80001caa <allocproc+0xb0>
      totaltickets++;
    80001c64:	00007697          	auipc	a3,0x7
    80001c68:	cdc68693          	add	a3,a3,-804 # 80008940 <totaltickets>
    80001c6c:	4298                	lw	a4,0(a3)
    80001c6e:	2705                	addw	a4,a4,1
    80001c70:	c298                	sw	a4,0(a3)
      (&s)->tickets[i] = 1;
    80001c72:	0000f717          	auipc	a4,0xf
    80001c76:	f3e70713          	add	a4,a4,-194 # 80010bb0 <pid_lock>
    80001c7a:	04078693          	add	a3,a5,64
    80001c7e:	068a                	sll	a3,a3,0x2
    80001c80:	96ba                	add	a3,a3,a4
    80001c82:	4605                	li	a2,1
    80001c84:	42c6a823          	sw	a2,1072(a3)
      (&s)->inuse[i] = 1;
    80001c88:	00279693          	sll	a3,a5,0x2
    80001c8c:	96ba                	add	a3,a3,a4
    80001c8e:	42c6a823          	sw	a2,1072(a3)
      (&s)->pid[i] = p->pid;
    80001c92:	08078693          	add	a3,a5,128
    80001c96:	068a                	sll	a3,a3,0x2
    80001c98:	96ba                	add	a3,a3,a4
    80001c9a:	42a6a823          	sw	a0,1072(a3)
      (&s)->ticks[i] = 0;
    80001c9e:	0c078793          	add	a5,a5,192
    80001ca2:	078a                	sll	a5,a5,0x2
    80001ca4:	973e                	add	a4,a4,a5
    80001ca6:	42072823          	sw	zero,1072(a4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	e38080e7          	jalr	-456(ra) # 80000ae2 <kalloc>
    80001cb2:	892a                	mv	s2,a0
    80001cb4:	eca8                	sd	a0,88(s1)
    80001cb6:	c131                	beqz	a0,80001cfa <allocproc+0x100>
  p->pagetable = proc_pagetable(p);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	db0080e7          	jalr	-592(ra) # 80001a6a <proc_pagetable>
    80001cc2:	892a                	mv	s2,a0
    80001cc4:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cc6:	c531                	beqz	a0,80001d12 <allocproc+0x118>
  memset(&p->context, 0, sizeof(p->context));
    80001cc8:	07000613          	li	a2,112
    80001ccc:	4581                	li	a1,0
    80001cce:	06048513          	add	a0,s1,96
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	ffc080e7          	jalr	-4(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001cda:	00000797          	auipc	a5,0x0
    80001cde:	d0478793          	add	a5,a5,-764 # 800019de <forkret>
    80001ce2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ce4:	60bc                	ld	a5,64(s1)
    80001ce6:	6705                	lui	a4,0x1
    80001ce8:	97ba                	add	a5,a5,a4
    80001cea:	f4bc                	sd	a5,104(s1)
}
    80001cec:	8526                	mv	a0,s1
    80001cee:	60e2                	ld	ra,24(sp)
    80001cf0:	6442                	ld	s0,16(sp)
    80001cf2:	64a2                	ld	s1,8(sp)
    80001cf4:	6902                	ld	s2,0(sp)
    80001cf6:	6105                	add	sp,sp,32
    80001cf8:	8082                	ret
    freeproc(p);
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	e5c080e7          	jalr	-420(ra) # 80001b58 <freeproc>
    release(&p->lock);
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	f80080e7          	jalr	-128(ra) # 80000c86 <release>
    return 0;
    80001d0e:	84ca                	mv	s1,s2
    80001d10:	bff1                	j	80001cec <allocproc+0xf2>
    freeproc(p);
    80001d12:	8526                	mv	a0,s1
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	e44080e7          	jalr	-444(ra) # 80001b58 <freeproc>
    release(&p->lock);
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	f68080e7          	jalr	-152(ra) # 80000c86 <release>
    return 0;
    80001d26:	84ca                	mv	s1,s2
    80001d28:	b7d1                	j	80001cec <allocproc+0xf2>

0000000080001d2a <userinit>:
{
    80001d2a:	1101                	add	sp,sp,-32
    80001d2c:	ec06                	sd	ra,24(sp)
    80001d2e:	e822                	sd	s0,16(sp)
    80001d30:	e426                	sd	s1,8(sp)
    80001d32:	1000                	add	s0,sp,32
  p = allocproc();
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	ec6080e7          	jalr	-314(ra) # 80001bfa <allocproc>
    80001d3c:	84aa                	mv	s1,a0
  initproc = p;
    80001d3e:	00007797          	auipc	a5,0x7
    80001d42:	bea7bd23          	sd	a0,-1030(a5) # 80008938 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d46:	03400613          	li	a2,52
    80001d4a:	00007597          	auipc	a1,0x7
    80001d4e:	b8658593          	add	a1,a1,-1146 # 800088d0 <initcode>
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	5fc080e7          	jalr	1532(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001d5c:	6785                	lui	a5,0x1
    80001d5e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d60:	6cb8                	ld	a4,88(s1)
    80001d62:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d66:	6cb8                	ld	a4,88(s1)
    80001d68:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d6a:	4641                	li	a2,16
    80001d6c:	00006597          	auipc	a1,0x6
    80001d70:	49458593          	add	a1,a1,1172 # 80008200 <digits+0x1c0>
    80001d74:	15848513          	add	a0,s1,344
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	09e080e7          	jalr	158(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d80:	00006517          	auipc	a0,0x6
    80001d84:	49050513          	add	a0,a0,1168 # 80008210 <digits+0x1d0>
    80001d88:	00002097          	auipc	ra,0x2
    80001d8c:	3c4080e7          	jalr	964(ra) # 8000414c <namei>
    80001d90:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d94:	478d                	li	a5,3
    80001d96:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d98:	8526                	mv	a0,s1
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	eec080e7          	jalr	-276(ra) # 80000c86 <release>
}
    80001da2:	60e2                	ld	ra,24(sp)
    80001da4:	6442                	ld	s0,16(sp)
    80001da6:	64a2                	ld	s1,8(sp)
    80001da8:	6105                	add	sp,sp,32
    80001daa:	8082                	ret

0000000080001dac <growproc>:
{
    80001dac:	1101                	add	sp,sp,-32
    80001dae:	ec06                	sd	ra,24(sp)
    80001db0:	e822                	sd	s0,16(sp)
    80001db2:	e426                	sd	s1,8(sp)
    80001db4:	e04a                	sd	s2,0(sp)
    80001db6:	1000                	add	s0,sp,32
    80001db8:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dba:	00000097          	auipc	ra,0x0
    80001dbe:	bec080e7          	jalr	-1044(ra) # 800019a6 <myproc>
    80001dc2:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dc4:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001dc6:	01204c63          	bgtz	s2,80001dde <growproc+0x32>
  } else if(n < 0){
    80001dca:	02094663          	bltz	s2,80001df6 <growproc+0x4a>
  p->sz = sz;
    80001dce:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dd0:	4501                	li	a0,0
}
    80001dd2:	60e2                	ld	ra,24(sp)
    80001dd4:	6442                	ld	s0,16(sp)
    80001dd6:	64a2                	ld	s1,8(sp)
    80001dd8:	6902                	ld	s2,0(sp)
    80001dda:	6105                	add	sp,sp,32
    80001ddc:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001dde:	4691                	li	a3,4
    80001de0:	00b90633          	add	a2,s2,a1
    80001de4:	6928                	ld	a0,80(a0)
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	624080e7          	jalr	1572(ra) # 8000140a <uvmalloc>
    80001dee:	85aa                	mv	a1,a0
    80001df0:	fd79                	bnez	a0,80001dce <growproc+0x22>
      return -1;
    80001df2:	557d                	li	a0,-1
    80001df4:	bff9                	j	80001dd2 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001df6:	00b90633          	add	a2,s2,a1
    80001dfa:	6928                	ld	a0,80(a0)
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	5c6080e7          	jalr	1478(ra) # 800013c2 <uvmdealloc>
    80001e04:	85aa                	mv	a1,a0
    80001e06:	b7e1                	j	80001dce <growproc+0x22>

0000000080001e08 <fork>:
{
    80001e08:	7139                	add	sp,sp,-64
    80001e0a:	fc06                	sd	ra,56(sp)
    80001e0c:	f822                	sd	s0,48(sp)
    80001e0e:	f426                	sd	s1,40(sp)
    80001e10:	f04a                	sd	s2,32(sp)
    80001e12:	ec4e                	sd	s3,24(sp)
    80001e14:	e852                	sd	s4,16(sp)
    80001e16:	e456                	sd	s5,8(sp)
    80001e18:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	b8c080e7          	jalr	-1140(ra) # 800019a6 <myproc>
    80001e22:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	dd6080e7          	jalr	-554(ra) # 80001bfa <allocproc>
    80001e2c:	10050c63          	beqz	a0,80001f44 <fork+0x13c>
    80001e30:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e32:	048ab603          	ld	a2,72(s5)
    80001e36:	692c                	ld	a1,80(a0)
    80001e38:	050ab503          	ld	a0,80(s5)
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	726080e7          	jalr	1830(ra) # 80001562 <uvmcopy>
    80001e44:	04054863          	bltz	a0,80001e94 <fork+0x8c>
  np->sz = p->sz;
    80001e48:	048ab783          	ld	a5,72(s5)
    80001e4c:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e50:	058ab683          	ld	a3,88(s5)
    80001e54:	87b6                	mv	a5,a3
    80001e56:	058a3703          	ld	a4,88(s4)
    80001e5a:	12068693          	add	a3,a3,288
    80001e5e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e62:	6788                	ld	a0,8(a5)
    80001e64:	6b8c                	ld	a1,16(a5)
    80001e66:	6f90                	ld	a2,24(a5)
    80001e68:	01073023          	sd	a6,0(a4)
    80001e6c:	e708                	sd	a0,8(a4)
    80001e6e:	eb0c                	sd	a1,16(a4)
    80001e70:	ef10                	sd	a2,24(a4)
    80001e72:	02078793          	add	a5,a5,32
    80001e76:	02070713          	add	a4,a4,32
    80001e7a:	fed792e3          	bne	a5,a3,80001e5e <fork+0x56>
  np->trapframe->a0 = 0;
    80001e7e:	058a3783          	ld	a5,88(s4)
    80001e82:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e86:	0d0a8493          	add	s1,s5,208
    80001e8a:	0d0a0913          	add	s2,s4,208
    80001e8e:	150a8993          	add	s3,s5,336
    80001e92:	a00d                	j	80001eb4 <fork+0xac>
    freeproc(np);
    80001e94:	8552                	mv	a0,s4
    80001e96:	00000097          	auipc	ra,0x0
    80001e9a:	cc2080e7          	jalr	-830(ra) # 80001b58 <freeproc>
    release(&np->lock);
    80001e9e:	8552                	mv	a0,s4
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	de6080e7          	jalr	-538(ra) # 80000c86 <release>
    return -1;
    80001ea8:	597d                	li	s2,-1
    80001eaa:	a059                	j	80001f30 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001eac:	04a1                	add	s1,s1,8
    80001eae:	0921                	add	s2,s2,8
    80001eb0:	01348b63          	beq	s1,s3,80001ec6 <fork+0xbe>
    if(p->ofile[i])
    80001eb4:	6088                	ld	a0,0(s1)
    80001eb6:	d97d                	beqz	a0,80001eac <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eb8:	00003097          	auipc	ra,0x3
    80001ebc:	906080e7          	jalr	-1786(ra) # 800047be <filedup>
    80001ec0:	00a93023          	sd	a0,0(s2)
    80001ec4:	b7e5                	j	80001eac <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ec6:	150ab503          	ld	a0,336(s5)
    80001eca:	00002097          	auipc	ra,0x2
    80001ece:	a9e080e7          	jalr	-1378(ra) # 80003968 <idup>
    80001ed2:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ed6:	4641                	li	a2,16
    80001ed8:	158a8593          	add	a1,s5,344
    80001edc:	158a0513          	add	a0,s4,344
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	f36080e7          	jalr	-202(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001ee8:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001eec:	8552                	mv	a0,s4
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	d98080e7          	jalr	-616(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001ef6:	0000f497          	auipc	s1,0xf
    80001efa:	cd248493          	add	s1,s1,-814 # 80010bc8 <wait_lock>
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	cd2080e7          	jalr	-814(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001f08:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	d78080e7          	jalr	-648(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001f16:	8552                	mv	a0,s4
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cba080e7          	jalr	-838(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001f20:	478d                	li	a5,3
    80001f22:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f26:	8552                	mv	a0,s4
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	d5e080e7          	jalr	-674(ra) # 80000c86 <release>
}
    80001f30:	854a                	mv	a0,s2
    80001f32:	70e2                	ld	ra,56(sp)
    80001f34:	7442                	ld	s0,48(sp)
    80001f36:	74a2                	ld	s1,40(sp)
    80001f38:	7902                	ld	s2,32(sp)
    80001f3a:	69e2                	ld	s3,24(sp)
    80001f3c:	6a42                	ld	s4,16(sp)
    80001f3e:	6aa2                	ld	s5,8(sp)
    80001f40:	6121                	add	sp,sp,64
    80001f42:	8082                	ret
    return -1;
    80001f44:	597d                	li	s2,-1
    80001f46:	b7ed                	j	80001f30 <fork+0x128>

0000000080001f48 <scheduler>:
{
    80001f48:	7139                	add	sp,sp,-64
    80001f4a:	fc06                	sd	ra,56(sp)
    80001f4c:	f822                	sd	s0,48(sp)
    80001f4e:	f426                	sd	s1,40(sp)
    80001f50:	f04a                	sd	s2,32(sp)
    80001f52:	ec4e                	sd	s3,24(sp)
    80001f54:	e852                	sd	s4,16(sp)
    80001f56:	e456                	sd	s5,8(sp)
    80001f58:	e05a                	sd	s6,0(sp)
    80001f5a:	0080                	add	s0,sp,64
    80001f5c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f5e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f60:	00779a93          	sll	s5,a5,0x7
    80001f64:	0000f717          	auipc	a4,0xf
    80001f68:	c4c70713          	add	a4,a4,-948 # 80010bb0 <pid_lock>
    80001f6c:	9756                	add	a4,a4,s5
    80001f6e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f72:	0000f717          	auipc	a4,0xf
    80001f76:	c7670713          	add	a4,a4,-906 # 80010be8 <cpus+0x8>
    80001f7a:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f7c:	498d                	li	s3,3
        p->state = RUNNING;
    80001f7e:	4b11                	li	s6,4
        c->proc = p;
    80001f80:	079e                	sll	a5,a5,0x7
    80001f82:	0000fa17          	auipc	s4,0xf
    80001f86:	c2ea0a13          	add	s4,s4,-978 # 80010bb0 <pid_lock>
    80001f8a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f8c:	00015917          	auipc	s2,0x15
    80001f90:	e5490913          	add	s2,s2,-428 # 80016de0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f98:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f9c:	10079073          	csrw	sstatus,a5
    80001fa0:	0000f497          	auipc	s1,0xf
    80001fa4:	44048493          	add	s1,s1,1088 # 800113e0 <proc>
    80001fa8:	a811                	j	80001fbc <scheduler+0x74>
      release(&p->lock);
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	cda080e7          	jalr	-806(ra) # 80000c86 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb4:	16848493          	add	s1,s1,360
    80001fb8:	fd248ee3          	beq	s1,s2,80001f94 <scheduler+0x4c>
      acquire(&p->lock);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	c14080e7          	jalr	-1004(ra) # 80000bd2 <acquire>
      if(p->state == RUNNABLE) {
    80001fc6:	4c9c                	lw	a5,24(s1)
    80001fc8:	ff3791e3          	bne	a5,s3,80001faa <scheduler+0x62>
        p->state = RUNNING;
    80001fcc:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fd0:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fd4:	06048593          	add	a1,s1,96
    80001fd8:	8556                	mv	a0,s5
    80001fda:	00001097          	auipc	ra,0x1
    80001fde:	8ee080e7          	jalr	-1810(ra) # 800028c8 <swtch>
        c->proc = 0;
    80001fe2:	020a3823          	sd	zero,48(s4)
    80001fe6:	b7d1                	j	80001faa <scheduler+0x62>

0000000080001fe8 <sched>:
{
    80001fe8:	7179                	add	sp,sp,-48
    80001fea:	f406                	sd	ra,40(sp)
    80001fec:	f022                	sd	s0,32(sp)
    80001fee:	ec26                	sd	s1,24(sp)
    80001ff0:	e84a                	sd	s2,16(sp)
    80001ff2:	e44e                	sd	s3,8(sp)
    80001ff4:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	9b0080e7          	jalr	-1616(ra) # 800019a6 <myproc>
    80001ffe:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	b58080e7          	jalr	-1192(ra) # 80000b58 <holding>
    80002008:	c93d                	beqz	a0,8000207e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000200a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	sll	a5,a5,0x7
    80002010:	0000f717          	auipc	a4,0xf
    80002014:	ba070713          	add	a4,a4,-1120 # 80010bb0 <pid_lock>
    80002018:	97ba                	add	a5,a5,a4
    8000201a:	0a87a703          	lw	a4,168(a5)
    8000201e:	4785                	li	a5,1
    80002020:	06f71763          	bne	a4,a5,8000208e <sched+0xa6>
  if(p->state == RUNNING)
    80002024:	4c98                	lw	a4,24(s1)
    80002026:	4791                	li	a5,4
    80002028:	06f70b63          	beq	a4,a5,8000209e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002030:	8b89                	and	a5,a5,2
  if(intr_get())
    80002032:	efb5                	bnez	a5,800020ae <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002034:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002036:	0000f917          	auipc	s2,0xf
    8000203a:	b7a90913          	add	s2,s2,-1158 # 80010bb0 <pid_lock>
    8000203e:	2781                	sext.w	a5,a5
    80002040:	079e                	sll	a5,a5,0x7
    80002042:	97ca                	add	a5,a5,s2
    80002044:	0ac7a983          	lw	s3,172(a5)
    80002048:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000204a:	2781                	sext.w	a5,a5
    8000204c:	079e                	sll	a5,a5,0x7
    8000204e:	0000f597          	auipc	a1,0xf
    80002052:	b9a58593          	add	a1,a1,-1126 # 80010be8 <cpus+0x8>
    80002056:	95be                	add	a1,a1,a5
    80002058:	06048513          	add	a0,s1,96
    8000205c:	00001097          	auipc	ra,0x1
    80002060:	86c080e7          	jalr	-1940(ra) # 800028c8 <swtch>
    80002064:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	sll	a5,a5,0x7
    8000206a:	993e                	add	s2,s2,a5
    8000206c:	0b392623          	sw	s3,172(s2)
}
    80002070:	70a2                	ld	ra,40(sp)
    80002072:	7402                	ld	s0,32(sp)
    80002074:	64e2                	ld	s1,24(sp)
    80002076:	6942                	ld	s2,16(sp)
    80002078:	69a2                	ld	s3,8(sp)
    8000207a:	6145                	add	sp,sp,48
    8000207c:	8082                	ret
    panic("sched p->lock");
    8000207e:	00006517          	auipc	a0,0x6
    80002082:	19a50513          	add	a0,a0,410 # 80008218 <digits+0x1d8>
    80002086:	ffffe097          	auipc	ra,0xffffe
    8000208a:	4b6080e7          	jalr	1206(ra) # 8000053c <panic>
    panic("sched locks");
    8000208e:	00006517          	auipc	a0,0x6
    80002092:	19a50513          	add	a0,a0,410 # 80008228 <digits+0x1e8>
    80002096:	ffffe097          	auipc	ra,0xffffe
    8000209a:	4a6080e7          	jalr	1190(ra) # 8000053c <panic>
    panic("sched running");
    8000209e:	00006517          	auipc	a0,0x6
    800020a2:	19a50513          	add	a0,a0,410 # 80008238 <digits+0x1f8>
    800020a6:	ffffe097          	auipc	ra,0xffffe
    800020aa:	496080e7          	jalr	1174(ra) # 8000053c <panic>
    panic("sched interruptible");
    800020ae:	00006517          	auipc	a0,0x6
    800020b2:	19a50513          	add	a0,a0,410 # 80008248 <digits+0x208>
    800020b6:	ffffe097          	auipc	ra,0xffffe
    800020ba:	486080e7          	jalr	1158(ra) # 8000053c <panic>

00000000800020be <yield>:
{
    800020be:	1101                	add	sp,sp,-32
    800020c0:	ec06                	sd	ra,24(sp)
    800020c2:	e822                	sd	s0,16(sp)
    800020c4:	e426                	sd	s1,8(sp)
    800020c6:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	8de080e7          	jalr	-1826(ra) # 800019a6 <myproc>
    800020d0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b00080e7          	jalr	-1280(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    800020da:	478d                	li	a5,3
    800020dc:	cc9c                	sw	a5,24(s1)
  sched();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	f0a080e7          	jalr	-246(ra) # 80001fe8 <sched>
  release(&p->lock);
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	b9e080e7          	jalr	-1122(ra) # 80000c86 <release>
}
    800020f0:	60e2                	ld	ra,24(sp)
    800020f2:	6442                	ld	s0,16(sp)
    800020f4:	64a2                	ld	s1,8(sp)
    800020f6:	6105                	add	sp,sp,32
    800020f8:	8082                	ret

00000000800020fa <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020fa:	7179                	add	sp,sp,-48
    800020fc:	f406                	sd	ra,40(sp)
    800020fe:	f022                	sd	s0,32(sp)
    80002100:	ec26                	sd	s1,24(sp)
    80002102:	e84a                	sd	s2,16(sp)
    80002104:	e44e                	sd	s3,8(sp)
    80002106:	1800                	add	s0,sp,48
    80002108:	89aa                	mv	s3,a0
    8000210a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	89a080e7          	jalr	-1894(ra) # 800019a6 <myproc>
    80002114:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	abc080e7          	jalr	-1348(ra) # 80000bd2 <acquire>
  release(lk);
    8000211e:	854a                	mv	a0,s2
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	b66080e7          	jalr	-1178(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    80002128:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000212c:	4789                	li	a5,2
    8000212e:	cc9c                	sw	a5,24(s1)

  sched();
    80002130:	00000097          	auipc	ra,0x0
    80002134:	eb8080e7          	jalr	-328(ra) # 80001fe8 <sched>

  // Tidy up.
  p->chan = 0;
    80002138:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	b48080e7          	jalr	-1208(ra) # 80000c86 <release>
  acquire(lk);
    80002146:	854a                	mv	a0,s2
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	a8a080e7          	jalr	-1398(ra) # 80000bd2 <acquire>
}
    80002150:	70a2                	ld	ra,40(sp)
    80002152:	7402                	ld	s0,32(sp)
    80002154:	64e2                	ld	s1,24(sp)
    80002156:	6942                	ld	s2,16(sp)
    80002158:	69a2                	ld	s3,8(sp)
    8000215a:	6145                	add	sp,sp,48
    8000215c:	8082                	ret

000000008000215e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000215e:	7139                	add	sp,sp,-64
    80002160:	fc06                	sd	ra,56(sp)
    80002162:	f822                	sd	s0,48(sp)
    80002164:	f426                	sd	s1,40(sp)
    80002166:	f04a                	sd	s2,32(sp)
    80002168:	ec4e                	sd	s3,24(sp)
    8000216a:	e852                	sd	s4,16(sp)
    8000216c:	e456                	sd	s5,8(sp)
    8000216e:	0080                	add	s0,sp,64
    80002170:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002172:	0000f497          	auipc	s1,0xf
    80002176:	26e48493          	add	s1,s1,622 # 800113e0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000217a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000217c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000217e:	00015917          	auipc	s2,0x15
    80002182:	c6290913          	add	s2,s2,-926 # 80016de0 <tickslock>
    80002186:	a811                	j	8000219a <wakeup+0x3c>
      }
      release(&p->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	afc080e7          	jalr	-1284(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002192:	16848493          	add	s1,s1,360
    80002196:	03248663          	beq	s1,s2,800021c2 <wakeup+0x64>
    if(p != myproc()){
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	80c080e7          	jalr	-2036(ra) # 800019a6 <myproc>
    800021a2:	fea488e3          	beq	s1,a0,80002192 <wakeup+0x34>
      acquire(&p->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	a2a080e7          	jalr	-1494(ra) # 80000bd2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021b0:	4c9c                	lw	a5,24(s1)
    800021b2:	fd379be3          	bne	a5,s3,80002188 <wakeup+0x2a>
    800021b6:	709c                	ld	a5,32(s1)
    800021b8:	fd4798e3          	bne	a5,s4,80002188 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021bc:	0154ac23          	sw	s5,24(s1)
    800021c0:	b7e1                	j	80002188 <wakeup+0x2a>
    }
  }
}
    800021c2:	70e2                	ld	ra,56(sp)
    800021c4:	7442                	ld	s0,48(sp)
    800021c6:	74a2                	ld	s1,40(sp)
    800021c8:	7902                	ld	s2,32(sp)
    800021ca:	69e2                	ld	s3,24(sp)
    800021cc:	6a42                	ld	s4,16(sp)
    800021ce:	6aa2                	ld	s5,8(sp)
    800021d0:	6121                	add	sp,sp,64
    800021d2:	8082                	ret

00000000800021d4 <reparent>:
{
    800021d4:	7179                	add	sp,sp,-48
    800021d6:	f406                	sd	ra,40(sp)
    800021d8:	f022                	sd	s0,32(sp)
    800021da:	ec26                	sd	s1,24(sp)
    800021dc:	e84a                	sd	s2,16(sp)
    800021de:	e44e                	sd	s3,8(sp)
    800021e0:	e052                	sd	s4,0(sp)
    800021e2:	1800                	add	s0,sp,48
    800021e4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021e6:	0000f497          	auipc	s1,0xf
    800021ea:	1fa48493          	add	s1,s1,506 # 800113e0 <proc>
      pp->parent = initproc;
    800021ee:	00006a17          	auipc	s4,0x6
    800021f2:	74aa0a13          	add	s4,s4,1866 # 80008938 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f6:	00015997          	auipc	s3,0x15
    800021fa:	bea98993          	add	s3,s3,-1046 # 80016de0 <tickslock>
    800021fe:	a029                	j	80002208 <reparent+0x34>
    80002200:	16848493          	add	s1,s1,360
    80002204:	01348d63          	beq	s1,s3,8000221e <reparent+0x4a>
    if(pp->parent == p){
    80002208:	7c9c                	ld	a5,56(s1)
    8000220a:	ff279be3          	bne	a5,s2,80002200 <reparent+0x2c>
      pp->parent = initproc;
    8000220e:	000a3503          	ld	a0,0(s4)
    80002212:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f4a080e7          	jalr	-182(ra) # 8000215e <wakeup>
    8000221c:	b7d5                	j	80002200 <reparent+0x2c>
}
    8000221e:	70a2                	ld	ra,40(sp)
    80002220:	7402                	ld	s0,32(sp)
    80002222:	64e2                	ld	s1,24(sp)
    80002224:	6942                	ld	s2,16(sp)
    80002226:	69a2                	ld	s3,8(sp)
    80002228:	6a02                	ld	s4,0(sp)
    8000222a:	6145                	add	sp,sp,48
    8000222c:	8082                	ret

000000008000222e <exit>:
{
    8000222e:	7179                	add	sp,sp,-48
    80002230:	f406                	sd	ra,40(sp)
    80002232:	f022                	sd	s0,32(sp)
    80002234:	ec26                	sd	s1,24(sp)
    80002236:	e84a                	sd	s2,16(sp)
    80002238:	e44e                	sd	s3,8(sp)
    8000223a:	e052                	sd	s4,0(sp)
    8000223c:	1800                	add	s0,sp,48
    8000223e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	766080e7          	jalr	1894(ra) # 800019a6 <myproc>
    80002248:	89aa                	mv	s3,a0
  if(p == initproc)
    8000224a:	00006797          	auipc	a5,0x6
    8000224e:	6ee7b783          	ld	a5,1774(a5) # 80008938 <initproc>
    80002252:	0d050493          	add	s1,a0,208
    80002256:	15050913          	add	s2,a0,336
    8000225a:	02a79363          	bne	a5,a0,80002280 <exit+0x52>
    panic("init exiting");
    8000225e:	00006517          	auipc	a0,0x6
    80002262:	00250513          	add	a0,a0,2 # 80008260 <digits+0x220>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	2d6080e7          	jalr	726(ra) # 8000053c <panic>
      fileclose(f);
    8000226e:	00002097          	auipc	ra,0x2
    80002272:	5a2080e7          	jalr	1442(ra) # 80004810 <fileclose>
      p->ofile[fd] = 0;
    80002276:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000227a:	04a1                	add	s1,s1,8
    8000227c:	01248563          	beq	s1,s2,80002286 <exit+0x58>
    if(p->ofile[fd]){
    80002280:	6088                	ld	a0,0(s1)
    80002282:	f575                	bnez	a0,8000226e <exit+0x40>
    80002284:	bfdd                	j	8000227a <exit+0x4c>
  begin_op();
    80002286:	00002097          	auipc	ra,0x2
    8000228a:	0c6080e7          	jalr	198(ra) # 8000434c <begin_op>
  iput(p->cwd);
    8000228e:	1509b503          	ld	a0,336(s3)
    80002292:	00002097          	auipc	ra,0x2
    80002296:	8ce080e7          	jalr	-1842(ra) # 80003b60 <iput>
  end_op();
    8000229a:	00002097          	auipc	ra,0x2
    8000229e:	12c080e7          	jalr	300(ra) # 800043c6 <end_op>
  p->cwd = 0;
    800022a2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022a6:	0000f497          	auipc	s1,0xf
    800022aa:	92248493          	add	s1,s1,-1758 # 80010bc8 <wait_lock>
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	922080e7          	jalr	-1758(ra) # 80000bd2 <acquire>
  reparent(p);
    800022b8:	854e                	mv	a0,s3
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	f1a080e7          	jalr	-230(ra) # 800021d4 <reparent>
  wakeup(p->parent);
    800022c2:	0389b503          	ld	a0,56(s3)
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	e98080e7          	jalr	-360(ra) # 8000215e <wakeup>
  acquire(&p->lock);
    800022ce:	854e                	mv	a0,s3
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	902080e7          	jalr	-1790(ra) # 80000bd2 <acquire>
  p->xstate = status;
    800022d8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022dc:	4795                	li	a5,5
    800022de:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	9a2080e7          	jalr	-1630(ra) # 80000c86 <release>
  sched();
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	cfc080e7          	jalr	-772(ra) # 80001fe8 <sched>
  panic("zombie exit");
    800022f4:	00006517          	auipc	a0,0x6
    800022f8:	f7c50513          	add	a0,a0,-132 # 80008270 <digits+0x230>
    800022fc:	ffffe097          	auipc	ra,0xffffe
    80002300:	240080e7          	jalr	576(ra) # 8000053c <panic>

0000000080002304 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002304:	7179                	add	sp,sp,-48
    80002306:	f406                	sd	ra,40(sp)
    80002308:	f022                	sd	s0,32(sp)
    8000230a:	ec26                	sd	s1,24(sp)
    8000230c:	e84a                	sd	s2,16(sp)
    8000230e:	e44e                	sd	s3,8(sp)
    80002310:	1800                	add	s0,sp,48
    80002312:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002314:	0000f497          	auipc	s1,0xf
    80002318:	0cc48493          	add	s1,s1,204 # 800113e0 <proc>
    8000231c:	00015997          	auipc	s3,0x15
    80002320:	ac498993          	add	s3,s3,-1340 # 80016de0 <tickslock>
    acquire(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	8ac080e7          	jalr	-1876(ra) # 80000bd2 <acquire>
    if(p->pid == pid){
    8000232e:	589c                	lw	a5,48(s1)
    80002330:	01278d63          	beq	a5,s2,8000234a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	950080e7          	jalr	-1712(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000233e:	16848493          	add	s1,s1,360
    80002342:	ff3491e3          	bne	s1,s3,80002324 <kill+0x20>
  }
  return -1;
    80002346:	557d                	li	a0,-1
    80002348:	a829                	j	80002362 <kill+0x5e>
      p->killed = 1;
    8000234a:	4785                	li	a5,1
    8000234c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000234e:	4c98                	lw	a4,24(s1)
    80002350:	4789                	li	a5,2
    80002352:	00f70f63          	beq	a4,a5,80002370 <kill+0x6c>
      release(&p->lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	92e080e7          	jalr	-1746(ra) # 80000c86 <release>
      return 0;
    80002360:	4501                	li	a0,0
}
    80002362:	70a2                	ld	ra,40(sp)
    80002364:	7402                	ld	s0,32(sp)
    80002366:	64e2                	ld	s1,24(sp)
    80002368:	6942                	ld	s2,16(sp)
    8000236a:	69a2                	ld	s3,8(sp)
    8000236c:	6145                	add	sp,sp,48
    8000236e:	8082                	ret
        p->state = RUNNABLE;
    80002370:	478d                	li	a5,3
    80002372:	cc9c                	sw	a5,24(s1)
    80002374:	b7cd                	j	80002356 <kill+0x52>

0000000080002376 <setkilled>:

void
setkilled(struct proc *p)
{
    80002376:	1101                	add	sp,sp,-32
    80002378:	ec06                	sd	ra,24(sp)
    8000237a:	e822                	sd	s0,16(sp)
    8000237c:	e426                	sd	s1,8(sp)
    8000237e:	1000                	add	s0,sp,32
    80002380:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	850080e7          	jalr	-1968(ra) # 80000bd2 <acquire>
  p->killed = 1;
    8000238a:	4785                	li	a5,1
    8000238c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	8f6080e7          	jalr	-1802(ra) # 80000c86 <release>
}
    80002398:	60e2                	ld	ra,24(sp)
    8000239a:	6442                	ld	s0,16(sp)
    8000239c:	64a2                	ld	s1,8(sp)
    8000239e:	6105                	add	sp,sp,32
    800023a0:	8082                	ret

00000000800023a2 <killed>:

int
killed(struct proc *p)
{
    800023a2:	1101                	add	sp,sp,-32
    800023a4:	ec06                	sd	ra,24(sp)
    800023a6:	e822                	sd	s0,16(sp)
    800023a8:	e426                	sd	s1,8(sp)
    800023aa:	e04a                	sd	s2,0(sp)
    800023ac:	1000                	add	s0,sp,32
    800023ae:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	822080e7          	jalr	-2014(ra) # 80000bd2 <acquire>
  k = p->killed;
    800023b8:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	8c8080e7          	jalr	-1848(ra) # 80000c86 <release>
  return k;
}
    800023c6:	854a                	mv	a0,s2
    800023c8:	60e2                	ld	ra,24(sp)
    800023ca:	6442                	ld	s0,16(sp)
    800023cc:	64a2                	ld	s1,8(sp)
    800023ce:	6902                	ld	s2,0(sp)
    800023d0:	6105                	add	sp,sp,32
    800023d2:	8082                	ret

00000000800023d4 <wait>:
{
    800023d4:	715d                	add	sp,sp,-80
    800023d6:	e486                	sd	ra,72(sp)
    800023d8:	e0a2                	sd	s0,64(sp)
    800023da:	fc26                	sd	s1,56(sp)
    800023dc:	f84a                	sd	s2,48(sp)
    800023de:	f44e                	sd	s3,40(sp)
    800023e0:	f052                	sd	s4,32(sp)
    800023e2:	ec56                	sd	s5,24(sp)
    800023e4:	e85a                	sd	s6,16(sp)
    800023e6:	e45e                	sd	s7,8(sp)
    800023e8:	e062                	sd	s8,0(sp)
    800023ea:	0880                	add	s0,sp,80
    800023ec:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	5b8080e7          	jalr	1464(ra) # 800019a6 <myproc>
    800023f6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023f8:	0000e517          	auipc	a0,0xe
    800023fc:	7d050513          	add	a0,a0,2000 # 80010bc8 <wait_lock>
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	7d2080e7          	jalr	2002(ra) # 80000bd2 <acquire>
    havekids = 0;
    80002408:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000240a:	4a15                	li	s4,5
        havekids = 1;
    8000240c:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000240e:	00015997          	auipc	s3,0x15
    80002412:	9d298993          	add	s3,s3,-1582 # 80016de0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002416:	0000ec17          	auipc	s8,0xe
    8000241a:	7b2c0c13          	add	s8,s8,1970 # 80010bc8 <wait_lock>
    8000241e:	a0d1                	j	800024e2 <wait+0x10e>
          pid = pp->pid;
    80002420:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002424:	000b0e63          	beqz	s6,80002440 <wait+0x6c>
    80002428:	4691                	li	a3,4
    8000242a:	02c48613          	add	a2,s1,44
    8000242e:	85da                	mv	a1,s6
    80002430:	05093503          	ld	a0,80(s2)
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	232080e7          	jalr	562(ra) # 80001666 <copyout>
    8000243c:	04054163          	bltz	a0,8000247e <wait+0xaa>
          freeproc(pp);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	716080e7          	jalr	1814(ra) # 80001b58 <freeproc>
          release(&pp->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	83a080e7          	jalr	-1990(ra) # 80000c86 <release>
          release(&wait_lock);
    80002454:	0000e517          	auipc	a0,0xe
    80002458:	77450513          	add	a0,a0,1908 # 80010bc8 <wait_lock>
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	82a080e7          	jalr	-2006(ra) # 80000c86 <release>
}
    80002464:	854e                	mv	a0,s3
    80002466:	60a6                	ld	ra,72(sp)
    80002468:	6406                	ld	s0,64(sp)
    8000246a:	74e2                	ld	s1,56(sp)
    8000246c:	7942                	ld	s2,48(sp)
    8000246e:	79a2                	ld	s3,40(sp)
    80002470:	7a02                	ld	s4,32(sp)
    80002472:	6ae2                	ld	s5,24(sp)
    80002474:	6b42                	ld	s6,16(sp)
    80002476:	6ba2                	ld	s7,8(sp)
    80002478:	6c02                	ld	s8,0(sp)
    8000247a:	6161                	add	sp,sp,80
    8000247c:	8082                	ret
            release(&pp->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	806080e7          	jalr	-2042(ra) # 80000c86 <release>
            release(&wait_lock);
    80002488:	0000e517          	auipc	a0,0xe
    8000248c:	74050513          	add	a0,a0,1856 # 80010bc8 <wait_lock>
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	7f6080e7          	jalr	2038(ra) # 80000c86 <release>
            return -1;
    80002498:	59fd                	li	s3,-1
    8000249a:	b7e9                	j	80002464 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000249c:	16848493          	add	s1,s1,360
    800024a0:	03348463          	beq	s1,s3,800024c8 <wait+0xf4>
      if(pp->parent == p){
    800024a4:	7c9c                	ld	a5,56(s1)
    800024a6:	ff279be3          	bne	a5,s2,8000249c <wait+0xc8>
        acquire(&pp->lock);
    800024aa:	8526                	mv	a0,s1
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	726080e7          	jalr	1830(ra) # 80000bd2 <acquire>
        if(pp->state == ZOMBIE){
    800024b4:	4c9c                	lw	a5,24(s1)
    800024b6:	f74785e3          	beq	a5,s4,80002420 <wait+0x4c>
        release(&pp->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7ca080e7          	jalr	1994(ra) # 80000c86 <release>
        havekids = 1;
    800024c4:	8756                	mv	a4,s5
    800024c6:	bfd9                	j	8000249c <wait+0xc8>
    if(!havekids || killed(p)){
    800024c8:	c31d                	beqz	a4,800024ee <wait+0x11a>
    800024ca:	854a                	mv	a0,s2
    800024cc:	00000097          	auipc	ra,0x0
    800024d0:	ed6080e7          	jalr	-298(ra) # 800023a2 <killed>
    800024d4:	ed09                	bnez	a0,800024ee <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024d6:	85e2                	mv	a1,s8
    800024d8:	854a                	mv	a0,s2
    800024da:	00000097          	auipc	ra,0x0
    800024de:	c20080e7          	jalr	-992(ra) # 800020fa <sleep>
    havekids = 0;
    800024e2:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024e4:	0000f497          	auipc	s1,0xf
    800024e8:	efc48493          	add	s1,s1,-260 # 800113e0 <proc>
    800024ec:	bf65                	j	800024a4 <wait+0xd0>
      release(&wait_lock);
    800024ee:	0000e517          	auipc	a0,0xe
    800024f2:	6da50513          	add	a0,a0,1754 # 80010bc8 <wait_lock>
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	790080e7          	jalr	1936(ra) # 80000c86 <release>
      return -1;
    800024fe:	59fd                	li	s3,-1
    80002500:	b795                	j	80002464 <wait+0x90>

0000000080002502 <getfilenum>:

int
getfilenum(int pid)
{
    80002502:	1141                	add	sp,sp,-16
    80002504:	e422                	sd	s0,8(sp)
    80002506:	0800                	add	s0,sp,16
  struct proc *p;
  int open = 0, fd;

  for(p = proc; p < &proc[NPROC]; p++){
    80002508:	0000f797          	auipc	a5,0xf
    8000250c:	ed878793          	add	a5,a5,-296 # 800113e0 <proc>
    80002510:	00015697          	auipc	a3,0x15
    80002514:	8d068693          	add	a3,a3,-1840 # 80016de0 <tickslock>
    if (p->pid == pid){
    80002518:	5b98                	lw	a4,48(a5)
    8000251a:	00a70a63          	beq	a4,a0,8000252e <getfilenum+0x2c>
  for(p = proc; p < &proc[NPROC]; p++){
    8000251e:	16878793          	add	a5,a5,360
    80002522:	fed79be3          	bne	a5,a3,80002518 <getfilenum+0x16>
        }
      }
      return open;
    }
  }
  return -1;
    80002526:	557d                	li	a0,-1
}
    80002528:	6422                	ld	s0,8(sp)
    8000252a:	0141                	add	sp,sp,16
    8000252c:	8082                	ret
    8000252e:	0d078713          	add	a4,a5,208
    80002532:	15078793          	add	a5,a5,336
  int open = 0, fd;
    80002536:	4501                	li	a0,0
    80002538:	a029                	j	80002542 <getfilenum+0x40>
          open++;
    8000253a:	2505                	addw	a0,a0,1
      for(fd = 0; fd < NOFILE; fd++){
    8000253c:	0721                	add	a4,a4,8
    8000253e:	fef705e3          	beq	a4,a5,80002528 <getfilenum+0x26>
        if(p->ofile[fd]){
    80002542:	6314                	ld	a3,0(a4)
    80002544:	fafd                	bnez	a3,8000253a <getfilenum+0x38>
    80002546:	bfdd                	j	8000253c <getfilenum+0x3a>

0000000080002548 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002548:	7179                	add	sp,sp,-48
    8000254a:	f406                	sd	ra,40(sp)
    8000254c:	f022                	sd	s0,32(sp)
    8000254e:	ec26                	sd	s1,24(sp)
    80002550:	e84a                	sd	s2,16(sp)
    80002552:	e44e                	sd	s3,8(sp)
    80002554:	e052                	sd	s4,0(sp)
    80002556:	1800                	add	s0,sp,48
    80002558:	84aa                	mv	s1,a0
    8000255a:	892e                	mv	s2,a1
    8000255c:	89b2                	mv	s3,a2
    8000255e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002560:	fffff097          	auipc	ra,0xfffff
    80002564:	446080e7          	jalr	1094(ra) # 800019a6 <myproc>
  if(user_dst){
    80002568:	c08d                	beqz	s1,8000258a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000256a:	86d2                	mv	a3,s4
    8000256c:	864e                	mv	a2,s3
    8000256e:	85ca                	mv	a1,s2
    80002570:	6928                	ld	a0,80(a0)
    80002572:	fffff097          	auipc	ra,0xfffff
    80002576:	0f4080e7          	jalr	244(ra) # 80001666 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000257a:	70a2                	ld	ra,40(sp)
    8000257c:	7402                	ld	s0,32(sp)
    8000257e:	64e2                	ld	s1,24(sp)
    80002580:	6942                	ld	s2,16(sp)
    80002582:	69a2                	ld	s3,8(sp)
    80002584:	6a02                	ld	s4,0(sp)
    80002586:	6145                	add	sp,sp,48
    80002588:	8082                	ret
    memmove((char *)dst, src, len);
    8000258a:	000a061b          	sext.w	a2,s4
    8000258e:	85ce                	mv	a1,s3
    80002590:	854a                	mv	a0,s2
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	798080e7          	jalr	1944(ra) # 80000d2a <memmove>
    return 0;
    8000259a:	8526                	mv	a0,s1
    8000259c:	bff9                	j	8000257a <either_copyout+0x32>

000000008000259e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000259e:	7179                	add	sp,sp,-48
    800025a0:	f406                	sd	ra,40(sp)
    800025a2:	f022                	sd	s0,32(sp)
    800025a4:	ec26                	sd	s1,24(sp)
    800025a6:	e84a                	sd	s2,16(sp)
    800025a8:	e44e                	sd	s3,8(sp)
    800025aa:	e052                	sd	s4,0(sp)
    800025ac:	1800                	add	s0,sp,48
    800025ae:	892a                	mv	s2,a0
    800025b0:	84ae                	mv	s1,a1
    800025b2:	89b2                	mv	s3,a2
    800025b4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025b6:	fffff097          	auipc	ra,0xfffff
    800025ba:	3f0080e7          	jalr	1008(ra) # 800019a6 <myproc>
  if(user_src){
    800025be:	c08d                	beqz	s1,800025e0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025c0:	86d2                	mv	a3,s4
    800025c2:	864e                	mv	a2,s3
    800025c4:	85ca                	mv	a1,s2
    800025c6:	6928                	ld	a0,80(a0)
    800025c8:	fffff097          	auipc	ra,0xfffff
    800025cc:	12a080e7          	jalr	298(ra) # 800016f2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025d0:	70a2                	ld	ra,40(sp)
    800025d2:	7402                	ld	s0,32(sp)
    800025d4:	64e2                	ld	s1,24(sp)
    800025d6:	6942                	ld	s2,16(sp)
    800025d8:	69a2                	ld	s3,8(sp)
    800025da:	6a02                	ld	s4,0(sp)
    800025dc:	6145                	add	sp,sp,48
    800025de:	8082                	ret
    memmove(dst, (char*)src, len);
    800025e0:	000a061b          	sext.w	a2,s4
    800025e4:	85ce                	mv	a1,s3
    800025e6:	854a                	mv	a0,s2
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	742080e7          	jalr	1858(ra) # 80000d2a <memmove>
    return 0;
    800025f0:	8526                	mv	a0,s1
    800025f2:	bff9                	j	800025d0 <either_copyin+0x32>

00000000800025f4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025f4:	715d                	add	sp,sp,-80
    800025f6:	e486                	sd	ra,72(sp)
    800025f8:	e0a2                	sd	s0,64(sp)
    800025fa:	fc26                	sd	s1,56(sp)
    800025fc:	f84a                	sd	s2,48(sp)
    800025fe:	f44e                	sd	s3,40(sp)
    80002600:	f052                	sd	s4,32(sp)
    80002602:	ec56                	sd	s5,24(sp)
    80002604:	e85a                	sd	s6,16(sp)
    80002606:	e45e                	sd	s7,8(sp)
    80002608:	0880                	add	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000260a:	00006517          	auipc	a0,0x6
    8000260e:	abe50513          	add	a0,a0,-1346 # 800080c8 <digits+0x88>
    80002612:	ffffe097          	auipc	ra,0xffffe
    80002616:	f74080e7          	jalr	-140(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000261a:	0000f497          	auipc	s1,0xf
    8000261e:	f1e48493          	add	s1,s1,-226 # 80011538 <proc+0x158>
    80002622:	00015917          	auipc	s2,0x15
    80002626:	91690913          	add	s2,s2,-1770 # 80016f38 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000262a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000262c:	00006997          	auipc	s3,0x6
    80002630:	c5498993          	add	s3,s3,-940 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002634:	00006a97          	auipc	s5,0x6
    80002638:	c54a8a93          	add	s5,s5,-940 # 80008288 <digits+0x248>
    printf("\n");
    8000263c:	00006a17          	auipc	s4,0x6
    80002640:	a8ca0a13          	add	s4,s4,-1396 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002644:	00006b97          	auipc	s7,0x6
    80002648:	cecb8b93          	add	s7,s7,-788 # 80008330 <states.0>
    8000264c:	a00d                	j	8000266e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000264e:	ed86a583          	lw	a1,-296(a3)
    80002652:	8556                	mv	a0,s5
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	f32080e7          	jalr	-206(ra) # 80000586 <printf>
    printf("\n");
    8000265c:	8552                	mv	a0,s4
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	f28080e7          	jalr	-216(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002666:	16848493          	add	s1,s1,360
    8000266a:	03248263          	beq	s1,s2,8000268e <procdump+0x9a>
    if(p->state == UNUSED)
    8000266e:	86a6                	mv	a3,s1
    80002670:	ec04a783          	lw	a5,-320(s1)
    80002674:	dbed                	beqz	a5,80002666 <procdump+0x72>
      state = "???";
    80002676:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002678:	fcfb6be3          	bltu	s6,a5,8000264e <procdump+0x5a>
    8000267c:	02079713          	sll	a4,a5,0x20
    80002680:	01d75793          	srl	a5,a4,0x1d
    80002684:	97de                	add	a5,a5,s7
    80002686:	6390                	ld	a2,0(a5)
    80002688:	f279                	bnez	a2,8000264e <procdump+0x5a>
      state = "???";
    8000268a:	864e                	mv	a2,s3
    8000268c:	b7c9                	j	8000264e <procdump+0x5a>
  }
}
    8000268e:	60a6                	ld	ra,72(sp)
    80002690:	6406                	ld	s0,64(sp)
    80002692:	74e2                	ld	s1,56(sp)
    80002694:	7942                	ld	s2,48(sp)
    80002696:	79a2                	ld	s3,40(sp)
    80002698:	7a02                	ld	s4,32(sp)
    8000269a:	6ae2                	ld	s5,24(sp)
    8000269c:	6b42                	ld	s6,16(sp)
    8000269e:	6ba2                	ld	s7,8(sp)
    800026a0:	6161                	add	sp,sp,80
    800026a2:	8082                	ret

00000000800026a4 <settickets>:

int
settickets(int number, struct proc* p)
{
    800026a4:	1141                	add	sp,sp,-16
    800026a6:	e422                	sd	s0,8(sp)
    800026a8:	0800                	add	s0,sp,16
  // cap for number is 70; tickets > 70 cause the shell to stall or infinite loop
  for (int i = 0; i < NPROC; i++){
    if ((&s)->pid[i] == p->pid && number > 0 && number <= 70){
    800026aa:	5990                	lw	a2,48(a1)
    800026ac:	0000f717          	auipc	a4,0xf
    800026b0:	b3470713          	add	a4,a4,-1228 # 800111e0 <s+0x200>
  for (int i = 0; i < NPROC; i++){
    800026b4:	4781                	li	a5,0
    if ((&s)->pid[i] == p->pid && number > 0 && number <= 70){
    800026b6:	fff5089b          	addw	a7,a0,-1
    800026ba:	04500813          	li	a6,69
  for (int i = 0; i < NPROC; i++){
    800026be:	04000593          	li	a1,64
    800026c2:	a029                	j	800026cc <settickets+0x28>
    800026c4:	2785                	addw	a5,a5,1
    800026c6:	0711                	add	a4,a4,4
    800026c8:	02b78c63          	beq	a5,a1,80002700 <settickets+0x5c>
    if ((&s)->pid[i] == p->pid && number > 0 && number <= 70){
    800026cc:	4314                	lw	a3,0(a4)
    800026ce:	fec69be3          	bne	a3,a2,800026c4 <settickets+0x20>
    800026d2:	ff1869e3          	bltu	a6,a7,800026c4 <settickets+0x20>
      (&s)->tickets[i] = number;
    800026d6:	04078793          	add	a5,a5,64
    800026da:	078a                	sll	a5,a5,0x2
    800026dc:	0000e717          	auipc	a4,0xe
    800026e0:	4d470713          	add	a4,a4,1236 # 80010bb0 <pid_lock>
    800026e4:	97ba                	add	a5,a5,a4
    800026e6:	42a7a823          	sw	a0,1072(a5)
      totaltickets += number - 1; // it was previously set to one so subtract that and add number
    800026ea:	00006717          	auipc	a4,0x6
    800026ee:	25670713          	add	a4,a4,598 # 80008940 <totaltickets>
    800026f2:	fff5079b          	addw	a5,a0,-1
    800026f6:	4314                	lw	a3,0(a4)
    800026f8:	9fb5                	addw	a5,a5,a3
    800026fa:	c31c                	sw	a5,0(a4)
      return 0;
    800026fc:	4501                	li	a0,0
    800026fe:	a011                	j	80002702 <settickets+0x5e>
    }
  }
  return -1;
    80002700:	557d                	li	a0,-1
}
    80002702:	6422                	ld	s0,8(sp)
    80002704:	0141                	add	sp,sp,16
    80002706:	8082                	ret

0000000080002708 <lottery_scheduler>:
{
    80002708:	7119                	add	sp,sp,-128
    8000270a:	fc86                	sd	ra,120(sp)
    8000270c:	f8a2                	sd	s0,112(sp)
    8000270e:	f4a6                	sd	s1,104(sp)
    80002710:	f0ca                	sd	s2,96(sp)
    80002712:	ecce                	sd	s3,88(sp)
    80002714:	e8d2                	sd	s4,80(sp)
    80002716:	e4d6                	sd	s5,72(sp)
    80002718:	e0da                	sd	s6,64(sp)
    8000271a:	fc5e                	sd	s7,56(sp)
    8000271c:	f862                	sd	s8,48(sp)
    8000271e:	f466                	sd	s9,40(sp)
    80002720:	f06a                	sd	s10,32(sp)
    80002722:	ec6e                	sd	s11,24(sp)
    80002724:	0100                	add	s0,sp,128
    80002726:	8492                	mv	s1,tp
  int id = r_tp();
    80002728:	2481                	sext.w	s1,s1
  rand_init(10);
    8000272a:	4529                	li	a0,10
    8000272c:	00004097          	auipc	ra,0x4
    80002730:	060080e7          	jalr	96(ra) # 8000678c <rand_init>
  c->proc = 0;
    80002734:	00749713          	sll	a4,s1,0x7
    80002738:	0000e797          	auipc	a5,0xe
    8000273c:	47878793          	add	a5,a5,1144 # 80010bb0 <pid_lock>
    80002740:	97ba                	add	a5,a5,a4
    80002742:	0207b823          	sd	zero,48(a5)
        swtch(&c->context, &p->context);
    80002746:	0000e797          	auipc	a5,0xe
    8000274a:	4a278793          	add	a5,a5,1186 # 80010be8 <cpus+0x8>
    8000274e:	97ba                	add	a5,a5,a4
    80002750:	f8f43423          	sd	a5,-120(s0)
    80002754:	00014b97          	auipc	s7,0x14
    80002758:	68cb8b93          	add	s7,s7,1676 # 80016de0 <tickslock>
      if (count >= chosenticket && p->state == RUNNABLE){
    8000275c:	4c0d                	li	s8,3
        c->proc = p;
    8000275e:	0000ec97          	auipc	s9,0xe
    80002762:	452c8c93          	add	s9,s9,1106 # 80010bb0 <pid_lock>
    80002766:	9cba                	add	s9,s9,a4
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002768:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000276c:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002770:	10079073          	csrw	sstatus,a5
    int chosenticket = scaled_random(0, totaltickets);
    80002774:	00006797          	auipc	a5,0x6
    80002778:	1cc78793          	add	a5,a5,460 # 80008940 <totaltickets>
    8000277c:	438c                	lw	a1,0(a5)
    8000277e:	4501                	li	a0,0
    80002780:	00004097          	auipc	ra,0x4
    80002784:	024080e7          	jalr	36(ra) # 800067a4 <scaled_random>
    80002788:	8b2a                	mv	s6,a0
    for(int i = 0; i < NPROC; i++) {
    8000278a:	0000f917          	auipc	s2,0xf
    8000278e:	85690913          	add	s2,s2,-1962 # 80010fe0 <s>
    80002792:	0000f497          	auipc	s1,0xf
    80002796:	c4e48493          	add	s1,s1,-946 # 800113e0 <proc>
    int count = 0;
    8000279a:	4981                	li	s3,0
        p->state = RUNNING;
    8000279c:	4d91                	li	s11,4
        if ((&s)->ticks[i] > 5){
    8000279e:	4d15                	li	s10,5
    800027a0:	a08d                	j	80002802 <lottery_scheduler+0xfa>
          printf("pid: %d, tickets: %d, ticks: %d, proc: %s\n", (&s)->pid[i], (&s)->tickets[i], (&s)->ticks[i], p->name);
    800027a2:	15848713          	add	a4,s1,344
    800027a6:	300aa683          	lw	a3,768(s5)
    800027aa:	100aa603          	lw	a2,256(s5)
    800027ae:	00006517          	auipc	a0,0x6
    800027b2:	aea50513          	add	a0,a0,-1302 # 80008298 <digits+0x258>
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	dd0080e7          	jalr	-560(ra) # 80000586 <printf>
        p->state = RUNNING;
    800027be:	01ba2c23          	sw	s11,24(s4)
        c->proc = p;
    800027c2:	034cb823          	sd	s4,48(s9)
        swtch(&c->context, &p->context);
    800027c6:	06048593          	add	a1,s1,96
    800027ca:	f8843503          	ld	a0,-120(s0)
    800027ce:	00000097          	auipc	ra,0x0
    800027d2:	0fa080e7          	jalr	250(ra) # 800028c8 <swtch>
        c->proc = 0;
    800027d6:	020cb823          	sd	zero,48(s9)
        (&s)->ticks[i]++;        
    800027da:	300aa503          	lw	a0,768(s5)
    800027de:	0015079b          	addw	a5,a0,1
    800027e2:	0007871b          	sext.w	a4,a5
    800027e6:	30faa023          	sw	a5,768(s5)
        if ((&s)->ticks[i] > 5){
    800027ea:	04ed4963          	blt	s10,a4,8000283c <lottery_scheduler+0x134>
      release(&p->lock);
    800027ee:	8552                	mv	a0,s4
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	496080e7          	jalr	1174(ra) # 80000c86 <release>
    for(int i = 0; i < NPROC; i++) {
    800027f8:	0911                	add	s2,s2,4
    800027fa:	16848493          	add	s1,s1,360
    800027fe:	f77485e3          	beq	s1,s7,80002768 <lottery_scheduler+0x60>
      count += (&s)->tickets[i];
    80002802:	8aca                	mv	s5,s2
    80002804:	10092783          	lw	a5,256(s2)
    80002808:	013789bb          	addw	s3,a5,s3
      p = &proc[i];
    8000280c:	8a26                	mv	s4,s1
      acquire(&p->lock);
    8000280e:	8526                	mv	a0,s1
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	3c2080e7          	jalr	962(ra) # 80000bd2 <acquire>
      if (count >= chosenticket && p->state == RUNNABLE){
    80002818:	fd69cbe3          	blt	s3,s6,800027ee <lottery_scheduler+0xe6>
    8000281c:	4c9c                	lw	a5,24(s1)
    8000281e:	fd8798e3          	bne	a5,s8,800027ee <lottery_scheduler+0xe6>
        if ((&s)->pid[i] || (&s)->tickets[i] || (&s)->ticks[i] || (&s)->inuse[i]){
    80002822:	20092583          	lw	a1,512(s2)
    80002826:	fdb5                	bnez	a1,800027a2 <lottery_scheduler+0x9a>
    80002828:	10092783          	lw	a5,256(s2)
    8000282c:	fbbd                	bnez	a5,800027a2 <lottery_scheduler+0x9a>
    8000282e:	30092783          	lw	a5,768(s2)
    80002832:	fba5                	bnez	a5,800027a2 <lottery_scheduler+0x9a>
    80002834:	00092783          	lw	a5,0(s2)
    80002838:	d3d9                	beqz	a5,800027be <lottery_scheduler+0xb6>
    8000283a:	b7a5                	j	800027a2 <lottery_scheduler+0x9a>
          settickets((&s)->ticks[i] - 5, p);
    8000283c:	85d2                	mv	a1,s4
    8000283e:	3571                	addw	a0,a0,-4
    80002840:	00000097          	auipc	ra,0x0
    80002844:	e64080e7          	jalr	-412(ra) # 800026a4 <settickets>
    80002848:	b75d                	j	800027ee <lottery_scheduler+0xe6>

000000008000284a <getpinfo>:

// Add each process to the pstats, s
int
getpinfo()
{
    8000284a:	7179                	add	sp,sp,-48
    8000284c:	f406                	sd	ra,40(sp)
    8000284e:	f022                	sd	s0,32(sp)
    80002850:	ec26                	sd	s1,24(sp)
    80002852:	e84a                	sd	s2,16(sp)
    80002854:	e44e                	sd	s3,8(sp)
    80002856:	e052                	sd	s4,0(sp)
    80002858:	1800                	add	s0,sp,48
  struct proc *p;
  for(int i = 0; i < NPROC; i++){
    8000285a:	0000e497          	auipc	s1,0xe
    8000285e:	78648493          	add	s1,s1,1926 # 80010fe0 <s>
    80002862:	0000f917          	auipc	s2,0xf
    80002866:	cd690913          	add	s2,s2,-810 # 80011538 <proc+0x158>
    8000286a:	0000f997          	auipc	s3,0xf
    8000286e:	87698993          	add	s3,s3,-1930 # 800110e0 <s+0x100>
    if ((&s)->pid[i] || (&s)->tickets[i] || (&s)->ticks[i] || (&s)->inuse[i]){
      p = &proc[i];
      printf("pid: %d, tickets: %d, ticks: %d, inuse: %d, proc: %s\n", 
    80002872:	00006a17          	auipc	s4,0x6
    80002876:	a56a0a13          	add	s4,s4,-1450 # 800082c8 <digits+0x288>
    8000287a:	a00d                	j	8000289c <getpinfo+0x52>
    8000287c:	87ca                	mv	a5,s2
    8000287e:	4218                	lw	a4,0(a2)
    80002880:	30062683          	lw	a3,768(a2)
    80002884:	10062603          	lw	a2,256(a2)
    80002888:	8552                	mv	a0,s4
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	cfc080e7          	jalr	-772(ra) # 80000586 <printf>
  for(int i = 0; i < NPROC; i++){
    80002892:	0491                	add	s1,s1,4
    80002894:	16890913          	add	s2,s2,360
    80002898:	01348f63          	beq	s1,s3,800028b6 <getpinfo+0x6c>
    if ((&s)->pid[i] || (&s)->tickets[i] || (&s)->ticks[i] || (&s)->inuse[i]){
    8000289c:	8626                	mv	a2,s1
    8000289e:	2004a583          	lw	a1,512(s1)
    800028a2:	fde9                	bnez	a1,8000287c <getpinfo+0x32>
    800028a4:	1004a783          	lw	a5,256(s1)
    800028a8:	fbf1                	bnez	a5,8000287c <getpinfo+0x32>
    800028aa:	3004a783          	lw	a5,768(s1)
    800028ae:	f7f9                	bnez	a5,8000287c <getpinfo+0x32>
    800028b0:	409c                	lw	a5,0(s1)
    800028b2:	d3e5                	beqz	a5,80002892 <getpinfo+0x48>
    800028b4:	b7e1                	j	8000287c <getpinfo+0x32>
    }
  }
  

  return 0;
    800028b6:	4501                	li	a0,0
    800028b8:	70a2                	ld	ra,40(sp)
    800028ba:	7402                	ld	s0,32(sp)
    800028bc:	64e2                	ld	s1,24(sp)
    800028be:	6942                	ld	s2,16(sp)
    800028c0:	69a2                	ld	s3,8(sp)
    800028c2:	6a02                	ld	s4,0(sp)
    800028c4:	6145                	add	sp,sp,48
    800028c6:	8082                	ret

00000000800028c8 <swtch>:
    800028c8:	00153023          	sd	ra,0(a0)
    800028cc:	00253423          	sd	sp,8(a0)
    800028d0:	e900                	sd	s0,16(a0)
    800028d2:	ed04                	sd	s1,24(a0)
    800028d4:	03253023          	sd	s2,32(a0)
    800028d8:	03353423          	sd	s3,40(a0)
    800028dc:	03453823          	sd	s4,48(a0)
    800028e0:	03553c23          	sd	s5,56(a0)
    800028e4:	05653023          	sd	s6,64(a0)
    800028e8:	05753423          	sd	s7,72(a0)
    800028ec:	05853823          	sd	s8,80(a0)
    800028f0:	05953c23          	sd	s9,88(a0)
    800028f4:	07a53023          	sd	s10,96(a0)
    800028f8:	07b53423          	sd	s11,104(a0)
    800028fc:	0005b083          	ld	ra,0(a1)
    80002900:	0085b103          	ld	sp,8(a1)
    80002904:	6980                	ld	s0,16(a1)
    80002906:	6d84                	ld	s1,24(a1)
    80002908:	0205b903          	ld	s2,32(a1)
    8000290c:	0285b983          	ld	s3,40(a1)
    80002910:	0305ba03          	ld	s4,48(a1)
    80002914:	0385ba83          	ld	s5,56(a1)
    80002918:	0405bb03          	ld	s6,64(a1)
    8000291c:	0485bb83          	ld	s7,72(a1)
    80002920:	0505bc03          	ld	s8,80(a1)
    80002924:	0585bc83          	ld	s9,88(a1)
    80002928:	0605bd03          	ld	s10,96(a1)
    8000292c:	0685bd83          	ld	s11,104(a1)
    80002930:	8082                	ret

0000000080002932 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002932:	1141                	add	sp,sp,-16
    80002934:	e406                	sd	ra,8(sp)
    80002936:	e022                	sd	s0,0(sp)
    80002938:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    8000293a:	00006597          	auipc	a1,0x6
    8000293e:	a2658593          	add	a1,a1,-1498 # 80008360 <states.0+0x30>
    80002942:	00014517          	auipc	a0,0x14
    80002946:	49e50513          	add	a0,a0,1182 # 80016de0 <tickslock>
    8000294a:	ffffe097          	auipc	ra,0xffffe
    8000294e:	1f8080e7          	jalr	504(ra) # 80000b42 <initlock>
}
    80002952:	60a2                	ld	ra,8(sp)
    80002954:	6402                	ld	s0,0(sp)
    80002956:	0141                	add	sp,sp,16
    80002958:	8082                	ret

000000008000295a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000295a:	1141                	add	sp,sp,-16
    8000295c:	e422                	sd	s0,8(sp)
    8000295e:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002960:	00003797          	auipc	a5,0x3
    80002964:	4d078793          	add	a5,a5,1232 # 80005e30 <kernelvec>
    80002968:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000296c:	6422                	ld	s0,8(sp)
    8000296e:	0141                	add	sp,sp,16
    80002970:	8082                	ret

0000000080002972 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002972:	1141                	add	sp,sp,-16
    80002974:	e406                	sd	ra,8(sp)
    80002976:	e022                	sd	s0,0(sp)
    80002978:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    8000297a:	fffff097          	auipc	ra,0xfffff
    8000297e:	02c080e7          	jalr	44(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002982:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002986:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002988:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000298c:	00004697          	auipc	a3,0x4
    80002990:	67468693          	add	a3,a3,1652 # 80007000 <_trampoline>
    80002994:	00004717          	auipc	a4,0x4
    80002998:	66c70713          	add	a4,a4,1644 # 80007000 <_trampoline>
    8000299c:	8f15                	sub	a4,a4,a3
    8000299e:	040007b7          	lui	a5,0x4000
    800029a2:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029a4:	07b2                	sll	a5,a5,0xc
    800029a6:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a8:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029ac:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029ae:	18002673          	csrr	a2,satp
    800029b2:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029b4:	6d30                	ld	a2,88(a0)
    800029b6:	6138                	ld	a4,64(a0)
    800029b8:	6585                	lui	a1,0x1
    800029ba:	972e                	add	a4,a4,a1
    800029bc:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029be:	6d38                	ld	a4,88(a0)
    800029c0:	00000617          	auipc	a2,0x0
    800029c4:	13460613          	add	a2,a2,308 # 80002af4 <usertrap>
    800029c8:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029ca:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029cc:	8612                	mv	a2,tp
    800029ce:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d0:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029d4:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029d8:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029dc:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029e0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029e2:	6f18                	ld	a4,24(a4)
    800029e4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029e8:	6928                	ld	a0,80(a0)
    800029ea:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800029ec:	00004717          	auipc	a4,0x4
    800029f0:	6b070713          	add	a4,a4,1712 # 8000709c <userret>
    800029f4:	8f15                	sub	a4,a4,a3
    800029f6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800029f8:	577d                	li	a4,-1
    800029fa:	177e                	sll	a4,a4,0x3f
    800029fc:	8d59                	or	a0,a0,a4
    800029fe:	9782                	jalr	a5
}
    80002a00:	60a2                	ld	ra,8(sp)
    80002a02:	6402                	ld	s0,0(sp)
    80002a04:	0141                	add	sp,sp,16
    80002a06:	8082                	ret

0000000080002a08 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a08:	1101                	add	sp,sp,-32
    80002a0a:	ec06                	sd	ra,24(sp)
    80002a0c:	e822                	sd	s0,16(sp)
    80002a0e:	e426                	sd	s1,8(sp)
    80002a10:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002a12:	00014497          	auipc	s1,0x14
    80002a16:	3ce48493          	add	s1,s1,974 # 80016de0 <tickslock>
    80002a1a:	8526                	mv	a0,s1
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	1b6080e7          	jalr	438(ra) # 80000bd2 <acquire>
  ticks++;
    80002a24:	00006517          	auipc	a0,0x6
    80002a28:	f2050513          	add	a0,a0,-224 # 80008944 <ticks>
    80002a2c:	411c                	lw	a5,0(a0)
    80002a2e:	2785                	addw	a5,a5,1
    80002a30:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	72c080e7          	jalr	1836(ra) # 8000215e <wakeup>
  release(&tickslock);
    80002a3a:	8526                	mv	a0,s1
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	24a080e7          	jalr	586(ra) # 80000c86 <release>
}
    80002a44:	60e2                	ld	ra,24(sp)
    80002a46:	6442                	ld	s0,16(sp)
    80002a48:	64a2                	ld	s1,8(sp)
    80002a4a:	6105                	add	sp,sp,32
    80002a4c:	8082                	ret

0000000080002a4e <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a4e:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a52:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002a54:	0807df63          	bgez	a5,80002af2 <devintr+0xa4>
{
    80002a58:	1101                	add	sp,sp,-32
    80002a5a:	ec06                	sd	ra,24(sp)
    80002a5c:	e822                	sd	s0,16(sp)
    80002a5e:	e426                	sd	s1,8(sp)
    80002a60:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    80002a62:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002a66:	46a5                	li	a3,9
    80002a68:	00d70d63          	beq	a4,a3,80002a82 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002a6c:	577d                	li	a4,-1
    80002a6e:	177e                	sll	a4,a4,0x3f
    80002a70:	0705                	add	a4,a4,1
    return 0;
    80002a72:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a74:	04e78e63          	beq	a5,a4,80002ad0 <devintr+0x82>
  }
}
    80002a78:	60e2                	ld	ra,24(sp)
    80002a7a:	6442                	ld	s0,16(sp)
    80002a7c:	64a2                	ld	s1,8(sp)
    80002a7e:	6105                	add	sp,sp,32
    80002a80:	8082                	ret
    int irq = plic_claim();
    80002a82:	00003097          	auipc	ra,0x3
    80002a86:	4b6080e7          	jalr	1206(ra) # 80005f38 <plic_claim>
    80002a8a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a8c:	47a9                	li	a5,10
    80002a8e:	02f50763          	beq	a0,a5,80002abc <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002a92:	4785                	li	a5,1
    80002a94:	02f50963          	beq	a0,a5,80002ac6 <devintr+0x78>
    return 1;
    80002a98:	4505                	li	a0,1
    } else if(irq){
    80002a9a:	dcf9                	beqz	s1,80002a78 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a9c:	85a6                	mv	a1,s1
    80002a9e:	00006517          	auipc	a0,0x6
    80002aa2:	8ca50513          	add	a0,a0,-1846 # 80008368 <states.0+0x38>
    80002aa6:	ffffe097          	auipc	ra,0xffffe
    80002aaa:	ae0080e7          	jalr	-1312(ra) # 80000586 <printf>
      plic_complete(irq);
    80002aae:	8526                	mv	a0,s1
    80002ab0:	00003097          	auipc	ra,0x3
    80002ab4:	4ac080e7          	jalr	1196(ra) # 80005f5c <plic_complete>
    return 1;
    80002ab8:	4505                	li	a0,1
    80002aba:	bf7d                	j	80002a78 <devintr+0x2a>
      uartintr();
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	ed8080e7          	jalr	-296(ra) # 80000994 <uartintr>
    if(irq)
    80002ac4:	b7ed                	j	80002aae <devintr+0x60>
      virtio_disk_intr();
    80002ac6:	00004097          	auipc	ra,0x4
    80002aca:	95c080e7          	jalr	-1700(ra) # 80006422 <virtio_disk_intr>
    if(irq)
    80002ace:	b7c5                	j	80002aae <devintr+0x60>
    if(cpuid() == 0){
    80002ad0:	fffff097          	auipc	ra,0xfffff
    80002ad4:	eaa080e7          	jalr	-342(ra) # 8000197a <cpuid>
    80002ad8:	c901                	beqz	a0,80002ae8 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ada:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ade:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ae0:	14479073          	csrw	sip,a5
    return 2;
    80002ae4:	4509                	li	a0,2
    80002ae6:	bf49                	j	80002a78 <devintr+0x2a>
      clockintr();
    80002ae8:	00000097          	auipc	ra,0x0
    80002aec:	f20080e7          	jalr	-224(ra) # 80002a08 <clockintr>
    80002af0:	b7ed                	j	80002ada <devintr+0x8c>
}
    80002af2:	8082                	ret

0000000080002af4 <usertrap>:
{
    80002af4:	1101                	add	sp,sp,-32
    80002af6:	ec06                	sd	ra,24(sp)
    80002af8:	e822                	sd	s0,16(sp)
    80002afa:	e426                	sd	s1,8(sp)
    80002afc:	e04a                	sd	s2,0(sp)
    80002afe:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b00:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b04:	1007f793          	and	a5,a5,256
    80002b08:	e3b1                	bnez	a5,80002b4c <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b0a:	00003797          	auipc	a5,0x3
    80002b0e:	32678793          	add	a5,a5,806 # 80005e30 <kernelvec>
    80002b12:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	e90080e7          	jalr	-368(ra) # 800019a6 <myproc>
    80002b1e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b20:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b22:	14102773          	csrr	a4,sepc
    80002b26:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b28:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b2c:	47a1                	li	a5,8
    80002b2e:	02f70763          	beq	a4,a5,80002b5c <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002b32:	00000097          	auipc	ra,0x0
    80002b36:	f1c080e7          	jalr	-228(ra) # 80002a4e <devintr>
    80002b3a:	892a                	mv	s2,a0
    80002b3c:	c151                	beqz	a0,80002bc0 <usertrap+0xcc>
  if(killed(p))
    80002b3e:	8526                	mv	a0,s1
    80002b40:	00000097          	auipc	ra,0x0
    80002b44:	862080e7          	jalr	-1950(ra) # 800023a2 <killed>
    80002b48:	c929                	beqz	a0,80002b9a <usertrap+0xa6>
    80002b4a:	a099                	j	80002b90 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002b4c:	00006517          	auipc	a0,0x6
    80002b50:	83c50513          	add	a0,a0,-1988 # 80008388 <states.0+0x58>
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	9e8080e7          	jalr	-1560(ra) # 8000053c <panic>
    if(killed(p))
    80002b5c:	00000097          	auipc	ra,0x0
    80002b60:	846080e7          	jalr	-1978(ra) # 800023a2 <killed>
    80002b64:	e921                	bnez	a0,80002bb4 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002b66:	6cb8                	ld	a4,88(s1)
    80002b68:	6f1c                	ld	a5,24(a4)
    80002b6a:	0791                	add	a5,a5,4
    80002b6c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b6e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b72:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b76:	10079073          	csrw	sstatus,a5
    syscall();
    80002b7a:	00000097          	auipc	ra,0x0
    80002b7e:	2d4080e7          	jalr	724(ra) # 80002e4e <syscall>
  if(killed(p))
    80002b82:	8526                	mv	a0,s1
    80002b84:	00000097          	auipc	ra,0x0
    80002b88:	81e080e7          	jalr	-2018(ra) # 800023a2 <killed>
    80002b8c:	c911                	beqz	a0,80002ba0 <usertrap+0xac>
    80002b8e:	4901                	li	s2,0
    exit(-1);
    80002b90:	557d                	li	a0,-1
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	69c080e7          	jalr	1692(ra) # 8000222e <exit>
  if(which_dev == 2)
    80002b9a:	4789                	li	a5,2
    80002b9c:	04f90f63          	beq	s2,a5,80002bfa <usertrap+0x106>
  usertrapret();
    80002ba0:	00000097          	auipc	ra,0x0
    80002ba4:	dd2080e7          	jalr	-558(ra) # 80002972 <usertrapret>
}
    80002ba8:	60e2                	ld	ra,24(sp)
    80002baa:	6442                	ld	s0,16(sp)
    80002bac:	64a2                	ld	s1,8(sp)
    80002bae:	6902                	ld	s2,0(sp)
    80002bb0:	6105                	add	sp,sp,32
    80002bb2:	8082                	ret
      exit(-1);
    80002bb4:	557d                	li	a0,-1
    80002bb6:	fffff097          	auipc	ra,0xfffff
    80002bba:	678080e7          	jalr	1656(ra) # 8000222e <exit>
    80002bbe:	b765                	j	80002b66 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bc0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bc4:	5890                	lw	a2,48(s1)
    80002bc6:	00005517          	auipc	a0,0x5
    80002bca:	7e250513          	add	a0,a0,2018 # 800083a8 <states.0+0x78>
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	9b8080e7          	jalr	-1608(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bda:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bde:	00005517          	auipc	a0,0x5
    80002be2:	7fa50513          	add	a0,a0,2042 # 800083d8 <states.0+0xa8>
    80002be6:	ffffe097          	auipc	ra,0xffffe
    80002bea:	9a0080e7          	jalr	-1632(ra) # 80000586 <printf>
    setkilled(p);
    80002bee:	8526                	mv	a0,s1
    80002bf0:	fffff097          	auipc	ra,0xfffff
    80002bf4:	786080e7          	jalr	1926(ra) # 80002376 <setkilled>
    80002bf8:	b769                	j	80002b82 <usertrap+0x8e>
    yield();
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	4c4080e7          	jalr	1220(ra) # 800020be <yield>
    80002c02:	bf79                	j	80002ba0 <usertrap+0xac>

0000000080002c04 <kerneltrap>:
{
    80002c04:	7179                	add	sp,sp,-48
    80002c06:	f406                	sd	ra,40(sp)
    80002c08:	f022                	sd	s0,32(sp)
    80002c0a:	ec26                	sd	s1,24(sp)
    80002c0c:	e84a                	sd	s2,16(sp)
    80002c0e:	e44e                	sd	s3,8(sp)
    80002c10:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c12:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c16:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c1a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c1e:	1004f793          	and	a5,s1,256
    80002c22:	cb85                	beqz	a5,80002c52 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c24:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c28:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80002c2a:	ef85                	bnez	a5,80002c62 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c2c:	00000097          	auipc	ra,0x0
    80002c30:	e22080e7          	jalr	-478(ra) # 80002a4e <devintr>
    80002c34:	cd1d                	beqz	a0,80002c72 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c36:	4789                	li	a5,2
    80002c38:	06f50a63          	beq	a0,a5,80002cac <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c3c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c40:	10049073          	csrw	sstatus,s1
}
    80002c44:	70a2                	ld	ra,40(sp)
    80002c46:	7402                	ld	s0,32(sp)
    80002c48:	64e2                	ld	s1,24(sp)
    80002c4a:	6942                	ld	s2,16(sp)
    80002c4c:	69a2                	ld	s3,8(sp)
    80002c4e:	6145                	add	sp,sp,48
    80002c50:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c52:	00005517          	auipc	a0,0x5
    80002c56:	7a650513          	add	a0,a0,1958 # 800083f8 <states.0+0xc8>
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	8e2080e7          	jalr	-1822(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002c62:	00005517          	auipc	a0,0x5
    80002c66:	7be50513          	add	a0,a0,1982 # 80008420 <states.0+0xf0>
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	8d2080e7          	jalr	-1838(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002c72:	85ce                	mv	a1,s3
    80002c74:	00005517          	auipc	a0,0x5
    80002c78:	7cc50513          	add	a0,a0,1996 # 80008440 <states.0+0x110>
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	90a080e7          	jalr	-1782(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c84:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c88:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c8c:	00005517          	auipc	a0,0x5
    80002c90:	7c450513          	add	a0,a0,1988 # 80008450 <states.0+0x120>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	8f2080e7          	jalr	-1806(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002c9c:	00005517          	auipc	a0,0x5
    80002ca0:	7cc50513          	add	a0,a0,1996 # 80008468 <states.0+0x138>
    80002ca4:	ffffe097          	auipc	ra,0xffffe
    80002ca8:	898080e7          	jalr	-1896(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cac:	fffff097          	auipc	ra,0xfffff
    80002cb0:	cfa080e7          	jalr	-774(ra) # 800019a6 <myproc>
    80002cb4:	d541                	beqz	a0,80002c3c <kerneltrap+0x38>
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	cf0080e7          	jalr	-784(ra) # 800019a6 <myproc>
    80002cbe:	4d18                	lw	a4,24(a0)
    80002cc0:	4791                	li	a5,4
    80002cc2:	f6f71de3          	bne	a4,a5,80002c3c <kerneltrap+0x38>
    yield();
    80002cc6:	fffff097          	auipc	ra,0xfffff
    80002cca:	3f8080e7          	jalr	1016(ra) # 800020be <yield>
    80002cce:	b7bd                	j	80002c3c <kerneltrap+0x38>

0000000080002cd0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cd0:	1101                	add	sp,sp,-32
    80002cd2:	ec06                	sd	ra,24(sp)
    80002cd4:	e822                	sd	s0,16(sp)
    80002cd6:	e426                	sd	s1,8(sp)
    80002cd8:	1000                	add	s0,sp,32
    80002cda:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	cca080e7          	jalr	-822(ra) # 800019a6 <myproc>
  switch (n) {
    80002ce4:	4795                	li	a5,5
    80002ce6:	0497e163          	bltu	a5,s1,80002d28 <argraw+0x58>
    80002cea:	048a                	sll	s1,s1,0x2
    80002cec:	00005717          	auipc	a4,0x5
    80002cf0:	7b470713          	add	a4,a4,1972 # 800084a0 <states.0+0x170>
    80002cf4:	94ba                	add	s1,s1,a4
    80002cf6:	409c                	lw	a5,0(s1)
    80002cf8:	97ba                	add	a5,a5,a4
    80002cfa:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cfc:	6d3c                	ld	a5,88(a0)
    80002cfe:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d00:	60e2                	ld	ra,24(sp)
    80002d02:	6442                	ld	s0,16(sp)
    80002d04:	64a2                	ld	s1,8(sp)
    80002d06:	6105                	add	sp,sp,32
    80002d08:	8082                	ret
    return p->trapframe->a1;
    80002d0a:	6d3c                	ld	a5,88(a0)
    80002d0c:	7fa8                	ld	a0,120(a5)
    80002d0e:	bfcd                	j	80002d00 <argraw+0x30>
    return p->trapframe->a2;
    80002d10:	6d3c                	ld	a5,88(a0)
    80002d12:	63c8                	ld	a0,128(a5)
    80002d14:	b7f5                	j	80002d00 <argraw+0x30>
    return p->trapframe->a3;
    80002d16:	6d3c                	ld	a5,88(a0)
    80002d18:	67c8                	ld	a0,136(a5)
    80002d1a:	b7dd                	j	80002d00 <argraw+0x30>
    return p->trapframe->a4;
    80002d1c:	6d3c                	ld	a5,88(a0)
    80002d1e:	6bc8                	ld	a0,144(a5)
    80002d20:	b7c5                	j	80002d00 <argraw+0x30>
    return p->trapframe->a5;
    80002d22:	6d3c                	ld	a5,88(a0)
    80002d24:	6fc8                	ld	a0,152(a5)
    80002d26:	bfe9                	j	80002d00 <argraw+0x30>
  panic("argraw");
    80002d28:	00005517          	auipc	a0,0x5
    80002d2c:	75050513          	add	a0,a0,1872 # 80008478 <states.0+0x148>
    80002d30:	ffffe097          	auipc	ra,0xffffe
    80002d34:	80c080e7          	jalr	-2036(ra) # 8000053c <panic>

0000000080002d38 <fetchaddr>:
{
    80002d38:	1101                	add	sp,sp,-32
    80002d3a:	ec06                	sd	ra,24(sp)
    80002d3c:	e822                	sd	s0,16(sp)
    80002d3e:	e426                	sd	s1,8(sp)
    80002d40:	e04a                	sd	s2,0(sp)
    80002d42:	1000                	add	s0,sp,32
    80002d44:	84aa                	mv	s1,a0
    80002d46:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d48:	fffff097          	auipc	ra,0xfffff
    80002d4c:	c5e080e7          	jalr	-930(ra) # 800019a6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d50:	653c                	ld	a5,72(a0)
    80002d52:	02f4f863          	bgeu	s1,a5,80002d82 <fetchaddr+0x4a>
    80002d56:	00848713          	add	a4,s1,8
    80002d5a:	02e7e663          	bltu	a5,a4,80002d86 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d5e:	46a1                	li	a3,8
    80002d60:	8626                	mv	a2,s1
    80002d62:	85ca                	mv	a1,s2
    80002d64:	6928                	ld	a0,80(a0)
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	98c080e7          	jalr	-1652(ra) # 800016f2 <copyin>
    80002d6e:	00a03533          	snez	a0,a0
    80002d72:	40a00533          	neg	a0,a0
}
    80002d76:	60e2                	ld	ra,24(sp)
    80002d78:	6442                	ld	s0,16(sp)
    80002d7a:	64a2                	ld	s1,8(sp)
    80002d7c:	6902                	ld	s2,0(sp)
    80002d7e:	6105                	add	sp,sp,32
    80002d80:	8082                	ret
    return -1;
    80002d82:	557d                	li	a0,-1
    80002d84:	bfcd                	j	80002d76 <fetchaddr+0x3e>
    80002d86:	557d                	li	a0,-1
    80002d88:	b7fd                	j	80002d76 <fetchaddr+0x3e>

0000000080002d8a <fetchstr>:
{
    80002d8a:	7179                	add	sp,sp,-48
    80002d8c:	f406                	sd	ra,40(sp)
    80002d8e:	f022                	sd	s0,32(sp)
    80002d90:	ec26                	sd	s1,24(sp)
    80002d92:	e84a                	sd	s2,16(sp)
    80002d94:	e44e                	sd	s3,8(sp)
    80002d96:	1800                	add	s0,sp,48
    80002d98:	892a                	mv	s2,a0
    80002d9a:	84ae                	mv	s1,a1
    80002d9c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	c08080e7          	jalr	-1016(ra) # 800019a6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002da6:	86ce                	mv	a3,s3
    80002da8:	864a                	mv	a2,s2
    80002daa:	85a6                	mv	a1,s1
    80002dac:	6928                	ld	a0,80(a0)
    80002dae:	fffff097          	auipc	ra,0xfffff
    80002db2:	9d2080e7          	jalr	-1582(ra) # 80001780 <copyinstr>
    80002db6:	00054e63          	bltz	a0,80002dd2 <fetchstr+0x48>
  return strlen(buf);
    80002dba:	8526                	mv	a0,s1
    80002dbc:	ffffe097          	auipc	ra,0xffffe
    80002dc0:	08c080e7          	jalr	140(ra) # 80000e48 <strlen>
}
    80002dc4:	70a2                	ld	ra,40(sp)
    80002dc6:	7402                	ld	s0,32(sp)
    80002dc8:	64e2                	ld	s1,24(sp)
    80002dca:	6942                	ld	s2,16(sp)
    80002dcc:	69a2                	ld	s3,8(sp)
    80002dce:	6145                	add	sp,sp,48
    80002dd0:	8082                	ret
    return -1;
    80002dd2:	557d                	li	a0,-1
    80002dd4:	bfc5                	j	80002dc4 <fetchstr+0x3a>

0000000080002dd6 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002dd6:	1101                	add	sp,sp,-32
    80002dd8:	ec06                	sd	ra,24(sp)
    80002dda:	e822                	sd	s0,16(sp)
    80002ddc:	e426                	sd	s1,8(sp)
    80002dde:	1000                	add	s0,sp,32
    80002de0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002de2:	00000097          	auipc	ra,0x0
    80002de6:	eee080e7          	jalr	-274(ra) # 80002cd0 <argraw>
    80002dea:	c088                	sw	a0,0(s1)
}
    80002dec:	60e2                	ld	ra,24(sp)
    80002dee:	6442                	ld	s0,16(sp)
    80002df0:	64a2                	ld	s1,8(sp)
    80002df2:	6105                	add	sp,sp,32
    80002df4:	8082                	ret

0000000080002df6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002df6:	1101                	add	sp,sp,-32
    80002df8:	ec06                	sd	ra,24(sp)
    80002dfa:	e822                	sd	s0,16(sp)
    80002dfc:	e426                	sd	s1,8(sp)
    80002dfe:	1000                	add	s0,sp,32
    80002e00:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	ece080e7          	jalr	-306(ra) # 80002cd0 <argraw>
    80002e0a:	e088                	sd	a0,0(s1)
}
    80002e0c:	60e2                	ld	ra,24(sp)
    80002e0e:	6442                	ld	s0,16(sp)
    80002e10:	64a2                	ld	s1,8(sp)
    80002e12:	6105                	add	sp,sp,32
    80002e14:	8082                	ret

0000000080002e16 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e16:	7179                	add	sp,sp,-48
    80002e18:	f406                	sd	ra,40(sp)
    80002e1a:	f022                	sd	s0,32(sp)
    80002e1c:	ec26                	sd	s1,24(sp)
    80002e1e:	e84a                	sd	s2,16(sp)
    80002e20:	1800                	add	s0,sp,48
    80002e22:	84ae                	mv	s1,a1
    80002e24:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002e26:	fd840593          	add	a1,s0,-40
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	fcc080e7          	jalr	-52(ra) # 80002df6 <argaddr>
  return fetchstr(addr, buf, max);
    80002e32:	864a                	mv	a2,s2
    80002e34:	85a6                	mv	a1,s1
    80002e36:	fd843503          	ld	a0,-40(s0)
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	f50080e7          	jalr	-176(ra) # 80002d8a <fetchstr>
}
    80002e42:	70a2                	ld	ra,40(sp)
    80002e44:	7402                	ld	s0,32(sp)
    80002e46:	64e2                	ld	s1,24(sp)
    80002e48:	6942                	ld	s2,16(sp)
    80002e4a:	6145                	add	sp,sp,48
    80002e4c:	8082                	ret

0000000080002e4e <syscall>:
[SYS_getpinfo]  sys_getpinfo,
};

void
syscall(void)
{
    80002e4e:	1101                	add	sp,sp,-32
    80002e50:	ec06                	sd	ra,24(sp)
    80002e52:	e822                	sd	s0,16(sp)
    80002e54:	e426                	sd	s1,8(sp)
    80002e56:	e04a                	sd	s2,0(sp)
    80002e58:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e5a:	fffff097          	auipc	ra,0xfffff
    80002e5e:	b4c080e7          	jalr	-1204(ra) # 800019a6 <myproc>
    80002e62:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e64:	05853903          	ld	s2,88(a0)
    80002e68:	0a893783          	ld	a5,168(s2)
    80002e6c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e70:	37fd                	addw	a5,a5,-1
    80002e72:	475d                	li	a4,23
    80002e74:	00f76f63          	bltu	a4,a5,80002e92 <syscall+0x44>
    80002e78:	00369713          	sll	a4,a3,0x3
    80002e7c:	00005797          	auipc	a5,0x5
    80002e80:	63c78793          	add	a5,a5,1596 # 800084b8 <syscalls>
    80002e84:	97ba                	add	a5,a5,a4
    80002e86:	639c                	ld	a5,0(a5)
    80002e88:	c789                	beqz	a5,80002e92 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002e8a:	9782                	jalr	a5
    80002e8c:	06a93823          	sd	a0,112(s2)
    80002e90:	a839                	j	80002eae <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e92:	15848613          	add	a2,s1,344
    80002e96:	588c                	lw	a1,48(s1)
    80002e98:	00005517          	auipc	a0,0x5
    80002e9c:	5e850513          	add	a0,a0,1512 # 80008480 <states.0+0x150>
    80002ea0:	ffffd097          	auipc	ra,0xffffd
    80002ea4:	6e6080e7          	jalr	1766(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ea8:	6cbc                	ld	a5,88(s1)
    80002eaa:	577d                	li	a4,-1
    80002eac:	fbb8                	sd	a4,112(a5)
  }
}
    80002eae:	60e2                	ld	ra,24(sp)
    80002eb0:	6442                	ld	s0,16(sp)
    80002eb2:	64a2                	ld	s1,8(sp)
    80002eb4:	6902                	ld	s2,0(sp)
    80002eb6:	6105                	add	sp,sp,32
    80002eb8:	8082                	ret

0000000080002eba <sys_exit>:
#include "pstat.h"
#include "random.h"

uint64
sys_exit(void)
{
    80002eba:	1101                	add	sp,sp,-32
    80002ebc:	ec06                	sd	ra,24(sp)
    80002ebe:	e822                	sd	s0,16(sp)
    80002ec0:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80002ec2:	fec40593          	add	a1,s0,-20
    80002ec6:	4501                	li	a0,0
    80002ec8:	00000097          	auipc	ra,0x0
    80002ecc:	f0e080e7          	jalr	-242(ra) # 80002dd6 <argint>
  exit(n);
    80002ed0:	fec42503          	lw	a0,-20(s0)
    80002ed4:	fffff097          	auipc	ra,0xfffff
    80002ed8:	35a080e7          	jalr	858(ra) # 8000222e <exit>
  return 0;  // not reached
}
    80002edc:	4501                	li	a0,0
    80002ede:	60e2                	ld	ra,24(sp)
    80002ee0:	6442                	ld	s0,16(sp)
    80002ee2:	6105                	add	sp,sp,32
    80002ee4:	8082                	ret

0000000080002ee6 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ee6:	1141                	add	sp,sp,-16
    80002ee8:	e406                	sd	ra,8(sp)
    80002eea:	e022                	sd	s0,0(sp)
    80002eec:	0800                	add	s0,sp,16
  return myproc()->pid;
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	ab8080e7          	jalr	-1352(ra) # 800019a6 <myproc>
}
    80002ef6:	5908                	lw	a0,48(a0)
    80002ef8:	60a2                	ld	ra,8(sp)
    80002efa:	6402                	ld	s0,0(sp)
    80002efc:	0141                	add	sp,sp,16
    80002efe:	8082                	ret

0000000080002f00 <sys_fork>:

uint64
sys_fork(void)
{
    80002f00:	1141                	add	sp,sp,-16
    80002f02:	e406                	sd	ra,8(sp)
    80002f04:	e022                	sd	s0,0(sp)
    80002f06:	0800                	add	s0,sp,16
  return fork();
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	f00080e7          	jalr	-256(ra) # 80001e08 <fork>
}
    80002f10:	60a2                	ld	ra,8(sp)
    80002f12:	6402                	ld	s0,0(sp)
    80002f14:	0141                	add	sp,sp,16
    80002f16:	8082                	ret

0000000080002f18 <sys_wait>:

uint64
sys_wait(void)
{
    80002f18:	1101                	add	sp,sp,-32
    80002f1a:	ec06                	sd	ra,24(sp)
    80002f1c:	e822                	sd	s0,16(sp)
    80002f1e:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002f20:	fe840593          	add	a1,s0,-24
    80002f24:	4501                	li	a0,0
    80002f26:	00000097          	auipc	ra,0x0
    80002f2a:	ed0080e7          	jalr	-304(ra) # 80002df6 <argaddr>
  return wait(p);
    80002f2e:	fe843503          	ld	a0,-24(s0)
    80002f32:	fffff097          	auipc	ra,0xfffff
    80002f36:	4a2080e7          	jalr	1186(ra) # 800023d4 <wait>
}
    80002f3a:	60e2                	ld	ra,24(sp)
    80002f3c:	6442                	ld	s0,16(sp)
    80002f3e:	6105                	add	sp,sp,32
    80002f40:	8082                	ret

0000000080002f42 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f42:	7179                	add	sp,sp,-48
    80002f44:	f406                	sd	ra,40(sp)
    80002f46:	f022                	sd	s0,32(sp)
    80002f48:	ec26                	sd	s1,24(sp)
    80002f4a:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f4c:	fdc40593          	add	a1,s0,-36
    80002f50:	4501                	li	a0,0
    80002f52:	00000097          	auipc	ra,0x0
    80002f56:	e84080e7          	jalr	-380(ra) # 80002dd6 <argint>
  addr = myproc()->sz;
    80002f5a:	fffff097          	auipc	ra,0xfffff
    80002f5e:	a4c080e7          	jalr	-1460(ra) # 800019a6 <myproc>
    80002f62:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002f64:	fdc42503          	lw	a0,-36(s0)
    80002f68:	fffff097          	auipc	ra,0xfffff
    80002f6c:	e44080e7          	jalr	-444(ra) # 80001dac <growproc>
    80002f70:	00054863          	bltz	a0,80002f80 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002f74:	8526                	mv	a0,s1
    80002f76:	70a2                	ld	ra,40(sp)
    80002f78:	7402                	ld	s0,32(sp)
    80002f7a:	64e2                	ld	s1,24(sp)
    80002f7c:	6145                	add	sp,sp,48
    80002f7e:	8082                	ret
    return -1;
    80002f80:	54fd                	li	s1,-1
    80002f82:	bfcd                	j	80002f74 <sys_sbrk+0x32>

0000000080002f84 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f84:	7139                	add	sp,sp,-64
    80002f86:	fc06                	sd	ra,56(sp)
    80002f88:	f822                	sd	s0,48(sp)
    80002f8a:	f426                	sd	s1,40(sp)
    80002f8c:	f04a                	sd	s2,32(sp)
    80002f8e:	ec4e                	sd	s3,24(sp)
    80002f90:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002f92:	fcc40593          	add	a1,s0,-52
    80002f96:	4501                	li	a0,0
    80002f98:	00000097          	auipc	ra,0x0
    80002f9c:	e3e080e7          	jalr	-450(ra) # 80002dd6 <argint>
  acquire(&tickslock);
    80002fa0:	00014517          	auipc	a0,0x14
    80002fa4:	e4050513          	add	a0,a0,-448 # 80016de0 <tickslock>
    80002fa8:	ffffe097          	auipc	ra,0xffffe
    80002fac:	c2a080e7          	jalr	-982(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80002fb0:	00006917          	auipc	s2,0x6
    80002fb4:	99492903          	lw	s2,-1644(s2) # 80008944 <ticks>
  while(ticks - ticks0 < n){
    80002fb8:	fcc42783          	lw	a5,-52(s0)
    80002fbc:	cf9d                	beqz	a5,80002ffa <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fbe:	00014997          	auipc	s3,0x14
    80002fc2:	e2298993          	add	s3,s3,-478 # 80016de0 <tickslock>
    80002fc6:	00006497          	auipc	s1,0x6
    80002fca:	97e48493          	add	s1,s1,-1666 # 80008944 <ticks>
    if(killed(myproc())){
    80002fce:	fffff097          	auipc	ra,0xfffff
    80002fd2:	9d8080e7          	jalr	-1576(ra) # 800019a6 <myproc>
    80002fd6:	fffff097          	auipc	ra,0xfffff
    80002fda:	3cc080e7          	jalr	972(ra) # 800023a2 <killed>
    80002fde:	ed15                	bnez	a0,8000301a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002fe0:	85ce                	mv	a1,s3
    80002fe2:	8526                	mv	a0,s1
    80002fe4:	fffff097          	auipc	ra,0xfffff
    80002fe8:	116080e7          	jalr	278(ra) # 800020fa <sleep>
  while(ticks - ticks0 < n){
    80002fec:	409c                	lw	a5,0(s1)
    80002fee:	412787bb          	subw	a5,a5,s2
    80002ff2:	fcc42703          	lw	a4,-52(s0)
    80002ff6:	fce7ece3          	bltu	a5,a4,80002fce <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ffa:	00014517          	auipc	a0,0x14
    80002ffe:	de650513          	add	a0,a0,-538 # 80016de0 <tickslock>
    80003002:	ffffe097          	auipc	ra,0xffffe
    80003006:	c84080e7          	jalr	-892(ra) # 80000c86 <release>
  return 0;
    8000300a:	4501                	li	a0,0
}
    8000300c:	70e2                	ld	ra,56(sp)
    8000300e:	7442                	ld	s0,48(sp)
    80003010:	74a2                	ld	s1,40(sp)
    80003012:	7902                	ld	s2,32(sp)
    80003014:	69e2                	ld	s3,24(sp)
    80003016:	6121                	add	sp,sp,64
    80003018:	8082                	ret
      release(&tickslock);
    8000301a:	00014517          	auipc	a0,0x14
    8000301e:	dc650513          	add	a0,a0,-570 # 80016de0 <tickslock>
    80003022:	ffffe097          	auipc	ra,0xffffe
    80003026:	c64080e7          	jalr	-924(ra) # 80000c86 <release>
      return -1;
    8000302a:	557d                	li	a0,-1
    8000302c:	b7c5                	j	8000300c <sys_sleep+0x88>

000000008000302e <sys_kill>:

uint64
sys_kill(void)
{
    8000302e:	1101                	add	sp,sp,-32
    80003030:	ec06                	sd	ra,24(sp)
    80003032:	e822                	sd	s0,16(sp)
    80003034:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    80003036:	fec40593          	add	a1,s0,-20
    8000303a:	4501                	li	a0,0
    8000303c:	00000097          	auipc	ra,0x0
    80003040:	d9a080e7          	jalr	-614(ra) # 80002dd6 <argint>
  return kill(pid);
    80003044:	fec42503          	lw	a0,-20(s0)
    80003048:	fffff097          	auipc	ra,0xfffff
    8000304c:	2bc080e7          	jalr	700(ra) # 80002304 <kill>
}
    80003050:	60e2                	ld	ra,24(sp)
    80003052:	6442                	ld	s0,16(sp)
    80003054:	6105                	add	sp,sp,32
    80003056:	8082                	ret

0000000080003058 <sys_getfilenum>:

uint64
sys_getfilenum(void)
{
    80003058:	1101                	add	sp,sp,-32
    8000305a:	ec06                	sd	ra,24(sp)
    8000305c:	e822                	sd	s0,16(sp)
    8000305e:	1000                	add	s0,sp,32
  int pid;
  argint(0, &pid);
    80003060:	fec40593          	add	a1,s0,-20
    80003064:	4501                	li	a0,0
    80003066:	00000097          	auipc	ra,0x0
    8000306a:	d70080e7          	jalr	-656(ra) # 80002dd6 <argint>
  return getfilenum(pid);
    8000306e:	fec42503          	lw	a0,-20(s0)
    80003072:	fffff097          	auipc	ra,0xfffff
    80003076:	490080e7          	jalr	1168(ra) # 80002502 <getfilenum>
}
    8000307a:	60e2                	ld	ra,24(sp)
    8000307c:	6442                	ld	s0,16(sp)
    8000307e:	6105                	add	sp,sp,32
    80003080:	8082                	ret

0000000080003082 <sys_uptime>:
// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003082:	1101                	add	sp,sp,-32
    80003084:	ec06                	sd	ra,24(sp)
    80003086:	e822                	sd	s0,16(sp)
    80003088:	e426                	sd	s1,8(sp)
    8000308a:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000308c:	00014517          	auipc	a0,0x14
    80003090:	d5450513          	add	a0,a0,-684 # 80016de0 <tickslock>
    80003094:	ffffe097          	auipc	ra,0xffffe
    80003098:	b3e080e7          	jalr	-1218(ra) # 80000bd2 <acquire>
  xticks = ticks;
    8000309c:	00006497          	auipc	s1,0x6
    800030a0:	8a84a483          	lw	s1,-1880(s1) # 80008944 <ticks>
  release(&tickslock);
    800030a4:	00014517          	auipc	a0,0x14
    800030a8:	d3c50513          	add	a0,a0,-708 # 80016de0 <tickslock>
    800030ac:	ffffe097          	auipc	ra,0xffffe
    800030b0:	bda080e7          	jalr	-1062(ra) # 80000c86 <release>
  return xticks;
}
    800030b4:	02049513          	sll	a0,s1,0x20
    800030b8:	9101                	srl	a0,a0,0x20
    800030ba:	60e2                	ld	ra,24(sp)
    800030bc:	6442                	ld	s0,16(sp)
    800030be:	64a2                	ld	s1,8(sp)
    800030c0:	6105                	add	sp,sp,32
    800030c2:	8082                	ret

00000000800030c4 <sys_settickets>:

uint64
sys_settickets(void)
{
    800030c4:	1101                	add	sp,sp,-32
    800030c6:	ec06                	sd	ra,24(sp)
    800030c8:	e822                	sd	s0,16(sp)
    800030ca:	1000                	add	s0,sp,32
  int number;
  struct proc *p = 0;
  argint(0, &number);
    800030cc:	fec40593          	add	a1,s0,-20
    800030d0:	4501                	li	a0,0
    800030d2:	00000097          	auipc	ra,0x0
    800030d6:	d04080e7          	jalr	-764(ra) # 80002dd6 <argint>
  return settickets(number, p);
    800030da:	4581                	li	a1,0
    800030dc:	fec42503          	lw	a0,-20(s0)
    800030e0:	fffff097          	auipc	ra,0xfffff
    800030e4:	5c4080e7          	jalr	1476(ra) # 800026a4 <settickets>
}
    800030e8:	60e2                	ld	ra,24(sp)
    800030ea:	6442                	ld	s0,16(sp)
    800030ec:	6105                	add	sp,sp,32
    800030ee:	8082                	ret

00000000800030f0 <sys_getpinfo>:

uint64
sys_getpinfo(void)
{
    800030f0:	1141                	add	sp,sp,-16
    800030f2:	e406                	sd	ra,8(sp)
    800030f4:	e022                	sd	s0,0(sp)
    800030f6:	0800                	add	s0,sp,16
  return getpinfo();
    800030f8:	fffff097          	auipc	ra,0xfffff
    800030fc:	752080e7          	jalr	1874(ra) # 8000284a <getpinfo>
    80003100:	60a2                	ld	ra,8(sp)
    80003102:	6402                	ld	s0,0(sp)
    80003104:	0141                	add	sp,sp,16
    80003106:	8082                	ret

0000000080003108 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003108:	7179                	add	sp,sp,-48
    8000310a:	f406                	sd	ra,40(sp)
    8000310c:	f022                	sd	s0,32(sp)
    8000310e:	ec26                	sd	s1,24(sp)
    80003110:	e84a                	sd	s2,16(sp)
    80003112:	e44e                	sd	s3,8(sp)
    80003114:	e052                	sd	s4,0(sp)
    80003116:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003118:	00005597          	auipc	a1,0x5
    8000311c:	46858593          	add	a1,a1,1128 # 80008580 <syscalls+0xc8>
    80003120:	00014517          	auipc	a0,0x14
    80003124:	cd850513          	add	a0,a0,-808 # 80016df8 <bcache>
    80003128:	ffffe097          	auipc	ra,0xffffe
    8000312c:	a1a080e7          	jalr	-1510(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003130:	0001c797          	auipc	a5,0x1c
    80003134:	cc878793          	add	a5,a5,-824 # 8001edf8 <bcache+0x8000>
    80003138:	0001c717          	auipc	a4,0x1c
    8000313c:	f2870713          	add	a4,a4,-216 # 8001f060 <bcache+0x8268>
    80003140:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003144:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003148:	00014497          	auipc	s1,0x14
    8000314c:	cc848493          	add	s1,s1,-824 # 80016e10 <bcache+0x18>
    b->next = bcache.head.next;
    80003150:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003152:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003154:	00005a17          	auipc	s4,0x5
    80003158:	434a0a13          	add	s4,s4,1076 # 80008588 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000315c:	2b893783          	ld	a5,696(s2)
    80003160:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003162:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003166:	85d2                	mv	a1,s4
    80003168:	01048513          	add	a0,s1,16
    8000316c:	00001097          	auipc	ra,0x1
    80003170:	496080e7          	jalr	1174(ra) # 80004602 <initsleeplock>
    bcache.head.next->prev = b;
    80003174:	2b893783          	ld	a5,696(s2)
    80003178:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000317a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000317e:	45848493          	add	s1,s1,1112
    80003182:	fd349de3          	bne	s1,s3,8000315c <binit+0x54>
  }
}
    80003186:	70a2                	ld	ra,40(sp)
    80003188:	7402                	ld	s0,32(sp)
    8000318a:	64e2                	ld	s1,24(sp)
    8000318c:	6942                	ld	s2,16(sp)
    8000318e:	69a2                	ld	s3,8(sp)
    80003190:	6a02                	ld	s4,0(sp)
    80003192:	6145                	add	sp,sp,48
    80003194:	8082                	ret

0000000080003196 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003196:	7179                	add	sp,sp,-48
    80003198:	f406                	sd	ra,40(sp)
    8000319a:	f022                	sd	s0,32(sp)
    8000319c:	ec26                	sd	s1,24(sp)
    8000319e:	e84a                	sd	s2,16(sp)
    800031a0:	e44e                	sd	s3,8(sp)
    800031a2:	1800                	add	s0,sp,48
    800031a4:	892a                	mv	s2,a0
    800031a6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800031a8:	00014517          	auipc	a0,0x14
    800031ac:	c5050513          	add	a0,a0,-944 # 80016df8 <bcache>
    800031b0:	ffffe097          	auipc	ra,0xffffe
    800031b4:	a22080e7          	jalr	-1502(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031b8:	0001c497          	auipc	s1,0x1c
    800031bc:	ef84b483          	ld	s1,-264(s1) # 8001f0b0 <bcache+0x82b8>
    800031c0:	0001c797          	auipc	a5,0x1c
    800031c4:	ea078793          	add	a5,a5,-352 # 8001f060 <bcache+0x8268>
    800031c8:	02f48f63          	beq	s1,a5,80003206 <bread+0x70>
    800031cc:	873e                	mv	a4,a5
    800031ce:	a021                	j	800031d6 <bread+0x40>
    800031d0:	68a4                	ld	s1,80(s1)
    800031d2:	02e48a63          	beq	s1,a4,80003206 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031d6:	449c                	lw	a5,8(s1)
    800031d8:	ff279ce3          	bne	a5,s2,800031d0 <bread+0x3a>
    800031dc:	44dc                	lw	a5,12(s1)
    800031de:	ff3799e3          	bne	a5,s3,800031d0 <bread+0x3a>
      b->refcnt++;
    800031e2:	40bc                	lw	a5,64(s1)
    800031e4:	2785                	addw	a5,a5,1
    800031e6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031e8:	00014517          	auipc	a0,0x14
    800031ec:	c1050513          	add	a0,a0,-1008 # 80016df8 <bcache>
    800031f0:	ffffe097          	auipc	ra,0xffffe
    800031f4:	a96080e7          	jalr	-1386(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800031f8:	01048513          	add	a0,s1,16
    800031fc:	00001097          	auipc	ra,0x1
    80003200:	440080e7          	jalr	1088(ra) # 8000463c <acquiresleep>
      return b;
    80003204:	a8b9                	j	80003262 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003206:	0001c497          	auipc	s1,0x1c
    8000320a:	ea24b483          	ld	s1,-350(s1) # 8001f0a8 <bcache+0x82b0>
    8000320e:	0001c797          	auipc	a5,0x1c
    80003212:	e5278793          	add	a5,a5,-430 # 8001f060 <bcache+0x8268>
    80003216:	00f48863          	beq	s1,a5,80003226 <bread+0x90>
    8000321a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000321c:	40bc                	lw	a5,64(s1)
    8000321e:	cf81                	beqz	a5,80003236 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003220:	64a4                	ld	s1,72(s1)
    80003222:	fee49de3          	bne	s1,a4,8000321c <bread+0x86>
  panic("bget: no buffers");
    80003226:	00005517          	auipc	a0,0x5
    8000322a:	36a50513          	add	a0,a0,874 # 80008590 <syscalls+0xd8>
    8000322e:	ffffd097          	auipc	ra,0xffffd
    80003232:	30e080e7          	jalr	782(ra) # 8000053c <panic>
      b->dev = dev;
    80003236:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000323a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000323e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003242:	4785                	li	a5,1
    80003244:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003246:	00014517          	auipc	a0,0x14
    8000324a:	bb250513          	add	a0,a0,-1102 # 80016df8 <bcache>
    8000324e:	ffffe097          	auipc	ra,0xffffe
    80003252:	a38080e7          	jalr	-1480(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003256:	01048513          	add	a0,s1,16
    8000325a:	00001097          	auipc	ra,0x1
    8000325e:	3e2080e7          	jalr	994(ra) # 8000463c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003262:	409c                	lw	a5,0(s1)
    80003264:	cb89                	beqz	a5,80003276 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003266:	8526                	mv	a0,s1
    80003268:	70a2                	ld	ra,40(sp)
    8000326a:	7402                	ld	s0,32(sp)
    8000326c:	64e2                	ld	s1,24(sp)
    8000326e:	6942                	ld	s2,16(sp)
    80003270:	69a2                	ld	s3,8(sp)
    80003272:	6145                	add	sp,sp,48
    80003274:	8082                	ret
    virtio_disk_rw(b, 0);
    80003276:	4581                	li	a1,0
    80003278:	8526                	mv	a0,s1
    8000327a:	00003097          	auipc	ra,0x3
    8000327e:	f78080e7          	jalr	-136(ra) # 800061f2 <virtio_disk_rw>
    b->valid = 1;
    80003282:	4785                	li	a5,1
    80003284:	c09c                	sw	a5,0(s1)
  return b;
    80003286:	b7c5                	j	80003266 <bread+0xd0>

0000000080003288 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003288:	1101                	add	sp,sp,-32
    8000328a:	ec06                	sd	ra,24(sp)
    8000328c:	e822                	sd	s0,16(sp)
    8000328e:	e426                	sd	s1,8(sp)
    80003290:	1000                	add	s0,sp,32
    80003292:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003294:	0541                	add	a0,a0,16
    80003296:	00001097          	auipc	ra,0x1
    8000329a:	440080e7          	jalr	1088(ra) # 800046d6 <holdingsleep>
    8000329e:	cd01                	beqz	a0,800032b6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032a0:	4585                	li	a1,1
    800032a2:	8526                	mv	a0,s1
    800032a4:	00003097          	auipc	ra,0x3
    800032a8:	f4e080e7          	jalr	-178(ra) # 800061f2 <virtio_disk_rw>
}
    800032ac:	60e2                	ld	ra,24(sp)
    800032ae:	6442                	ld	s0,16(sp)
    800032b0:	64a2                	ld	s1,8(sp)
    800032b2:	6105                	add	sp,sp,32
    800032b4:	8082                	ret
    panic("bwrite");
    800032b6:	00005517          	auipc	a0,0x5
    800032ba:	2f250513          	add	a0,a0,754 # 800085a8 <syscalls+0xf0>
    800032be:	ffffd097          	auipc	ra,0xffffd
    800032c2:	27e080e7          	jalr	638(ra) # 8000053c <panic>

00000000800032c6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032c6:	1101                	add	sp,sp,-32
    800032c8:	ec06                	sd	ra,24(sp)
    800032ca:	e822                	sd	s0,16(sp)
    800032cc:	e426                	sd	s1,8(sp)
    800032ce:	e04a                	sd	s2,0(sp)
    800032d0:	1000                	add	s0,sp,32
    800032d2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032d4:	01050913          	add	s2,a0,16
    800032d8:	854a                	mv	a0,s2
    800032da:	00001097          	auipc	ra,0x1
    800032de:	3fc080e7          	jalr	1020(ra) # 800046d6 <holdingsleep>
    800032e2:	c925                	beqz	a0,80003352 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800032e4:	854a                	mv	a0,s2
    800032e6:	00001097          	auipc	ra,0x1
    800032ea:	3ac080e7          	jalr	940(ra) # 80004692 <releasesleep>

  acquire(&bcache.lock);
    800032ee:	00014517          	auipc	a0,0x14
    800032f2:	b0a50513          	add	a0,a0,-1270 # 80016df8 <bcache>
    800032f6:	ffffe097          	auipc	ra,0xffffe
    800032fa:	8dc080e7          	jalr	-1828(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800032fe:	40bc                	lw	a5,64(s1)
    80003300:	37fd                	addw	a5,a5,-1
    80003302:	0007871b          	sext.w	a4,a5
    80003306:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003308:	e71d                	bnez	a4,80003336 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000330a:	68b8                	ld	a4,80(s1)
    8000330c:	64bc                	ld	a5,72(s1)
    8000330e:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003310:	68b8                	ld	a4,80(s1)
    80003312:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003314:	0001c797          	auipc	a5,0x1c
    80003318:	ae478793          	add	a5,a5,-1308 # 8001edf8 <bcache+0x8000>
    8000331c:	2b87b703          	ld	a4,696(a5)
    80003320:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003322:	0001c717          	auipc	a4,0x1c
    80003326:	d3e70713          	add	a4,a4,-706 # 8001f060 <bcache+0x8268>
    8000332a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000332c:	2b87b703          	ld	a4,696(a5)
    80003330:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003332:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003336:	00014517          	auipc	a0,0x14
    8000333a:	ac250513          	add	a0,a0,-1342 # 80016df8 <bcache>
    8000333e:	ffffe097          	auipc	ra,0xffffe
    80003342:	948080e7          	jalr	-1720(ra) # 80000c86 <release>
}
    80003346:	60e2                	ld	ra,24(sp)
    80003348:	6442                	ld	s0,16(sp)
    8000334a:	64a2                	ld	s1,8(sp)
    8000334c:	6902                	ld	s2,0(sp)
    8000334e:	6105                	add	sp,sp,32
    80003350:	8082                	ret
    panic("brelse");
    80003352:	00005517          	auipc	a0,0x5
    80003356:	25e50513          	add	a0,a0,606 # 800085b0 <syscalls+0xf8>
    8000335a:	ffffd097          	auipc	ra,0xffffd
    8000335e:	1e2080e7          	jalr	482(ra) # 8000053c <panic>

0000000080003362 <bpin>:

void
bpin(struct buf *b) {
    80003362:	1101                	add	sp,sp,-32
    80003364:	ec06                	sd	ra,24(sp)
    80003366:	e822                	sd	s0,16(sp)
    80003368:	e426                	sd	s1,8(sp)
    8000336a:	1000                	add	s0,sp,32
    8000336c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000336e:	00014517          	auipc	a0,0x14
    80003372:	a8a50513          	add	a0,a0,-1398 # 80016df8 <bcache>
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	85c080e7          	jalr	-1956(ra) # 80000bd2 <acquire>
  b->refcnt++;
    8000337e:	40bc                	lw	a5,64(s1)
    80003380:	2785                	addw	a5,a5,1
    80003382:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003384:	00014517          	auipc	a0,0x14
    80003388:	a7450513          	add	a0,a0,-1420 # 80016df8 <bcache>
    8000338c:	ffffe097          	auipc	ra,0xffffe
    80003390:	8fa080e7          	jalr	-1798(ra) # 80000c86 <release>
}
    80003394:	60e2                	ld	ra,24(sp)
    80003396:	6442                	ld	s0,16(sp)
    80003398:	64a2                	ld	s1,8(sp)
    8000339a:	6105                	add	sp,sp,32
    8000339c:	8082                	ret

000000008000339e <bunpin>:

void
bunpin(struct buf *b) {
    8000339e:	1101                	add	sp,sp,-32
    800033a0:	ec06                	sd	ra,24(sp)
    800033a2:	e822                	sd	s0,16(sp)
    800033a4:	e426                	sd	s1,8(sp)
    800033a6:	1000                	add	s0,sp,32
    800033a8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033aa:	00014517          	auipc	a0,0x14
    800033ae:	a4e50513          	add	a0,a0,-1458 # 80016df8 <bcache>
    800033b2:	ffffe097          	auipc	ra,0xffffe
    800033b6:	820080e7          	jalr	-2016(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800033ba:	40bc                	lw	a5,64(s1)
    800033bc:	37fd                	addw	a5,a5,-1
    800033be:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033c0:	00014517          	auipc	a0,0x14
    800033c4:	a3850513          	add	a0,a0,-1480 # 80016df8 <bcache>
    800033c8:	ffffe097          	auipc	ra,0xffffe
    800033cc:	8be080e7          	jalr	-1858(ra) # 80000c86 <release>
}
    800033d0:	60e2                	ld	ra,24(sp)
    800033d2:	6442                	ld	s0,16(sp)
    800033d4:	64a2                	ld	s1,8(sp)
    800033d6:	6105                	add	sp,sp,32
    800033d8:	8082                	ret

00000000800033da <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033da:	1101                	add	sp,sp,-32
    800033dc:	ec06                	sd	ra,24(sp)
    800033de:	e822                	sd	s0,16(sp)
    800033e0:	e426                	sd	s1,8(sp)
    800033e2:	e04a                	sd	s2,0(sp)
    800033e4:	1000                	add	s0,sp,32
    800033e6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033e8:	00d5d59b          	srlw	a1,a1,0xd
    800033ec:	0001c797          	auipc	a5,0x1c
    800033f0:	0e87a783          	lw	a5,232(a5) # 8001f4d4 <sb+0x1c>
    800033f4:	9dbd                	addw	a1,a1,a5
    800033f6:	00000097          	auipc	ra,0x0
    800033fa:	da0080e7          	jalr	-608(ra) # 80003196 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033fe:	0074f713          	and	a4,s1,7
    80003402:	4785                	li	a5,1
    80003404:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003408:	14ce                	sll	s1,s1,0x33
    8000340a:	90d9                	srl	s1,s1,0x36
    8000340c:	00950733          	add	a4,a0,s1
    80003410:	05874703          	lbu	a4,88(a4)
    80003414:	00e7f6b3          	and	a3,a5,a4
    80003418:	c69d                	beqz	a3,80003446 <bfree+0x6c>
    8000341a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000341c:	94aa                	add	s1,s1,a0
    8000341e:	fff7c793          	not	a5,a5
    80003422:	8f7d                	and	a4,a4,a5
    80003424:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003428:	00001097          	auipc	ra,0x1
    8000342c:	0f6080e7          	jalr	246(ra) # 8000451e <log_write>
  brelse(bp);
    80003430:	854a                	mv	a0,s2
    80003432:	00000097          	auipc	ra,0x0
    80003436:	e94080e7          	jalr	-364(ra) # 800032c6 <brelse>
}
    8000343a:	60e2                	ld	ra,24(sp)
    8000343c:	6442                	ld	s0,16(sp)
    8000343e:	64a2                	ld	s1,8(sp)
    80003440:	6902                	ld	s2,0(sp)
    80003442:	6105                	add	sp,sp,32
    80003444:	8082                	ret
    panic("freeing free block");
    80003446:	00005517          	auipc	a0,0x5
    8000344a:	17250513          	add	a0,a0,370 # 800085b8 <syscalls+0x100>
    8000344e:	ffffd097          	auipc	ra,0xffffd
    80003452:	0ee080e7          	jalr	238(ra) # 8000053c <panic>

0000000080003456 <balloc>:
{
    80003456:	711d                	add	sp,sp,-96
    80003458:	ec86                	sd	ra,88(sp)
    8000345a:	e8a2                	sd	s0,80(sp)
    8000345c:	e4a6                	sd	s1,72(sp)
    8000345e:	e0ca                	sd	s2,64(sp)
    80003460:	fc4e                	sd	s3,56(sp)
    80003462:	f852                	sd	s4,48(sp)
    80003464:	f456                	sd	s5,40(sp)
    80003466:	f05a                	sd	s6,32(sp)
    80003468:	ec5e                	sd	s7,24(sp)
    8000346a:	e862                	sd	s8,16(sp)
    8000346c:	e466                	sd	s9,8(sp)
    8000346e:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003470:	0001c797          	auipc	a5,0x1c
    80003474:	04c7a783          	lw	a5,76(a5) # 8001f4bc <sb+0x4>
    80003478:	cff5                	beqz	a5,80003574 <balloc+0x11e>
    8000347a:	8baa                	mv	s7,a0
    8000347c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000347e:	0001cb17          	auipc	s6,0x1c
    80003482:	03ab0b13          	add	s6,s6,58 # 8001f4b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003486:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003488:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000348a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000348c:	6c89                	lui	s9,0x2
    8000348e:	a061                	j	80003516 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003490:	97ca                	add	a5,a5,s2
    80003492:	8e55                	or	a2,a2,a3
    80003494:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003498:	854a                	mv	a0,s2
    8000349a:	00001097          	auipc	ra,0x1
    8000349e:	084080e7          	jalr	132(ra) # 8000451e <log_write>
        brelse(bp);
    800034a2:	854a                	mv	a0,s2
    800034a4:	00000097          	auipc	ra,0x0
    800034a8:	e22080e7          	jalr	-478(ra) # 800032c6 <brelse>
  bp = bread(dev, bno);
    800034ac:	85a6                	mv	a1,s1
    800034ae:	855e                	mv	a0,s7
    800034b0:	00000097          	auipc	ra,0x0
    800034b4:	ce6080e7          	jalr	-794(ra) # 80003196 <bread>
    800034b8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034ba:	40000613          	li	a2,1024
    800034be:	4581                	li	a1,0
    800034c0:	05850513          	add	a0,a0,88
    800034c4:	ffffe097          	auipc	ra,0xffffe
    800034c8:	80a080e7          	jalr	-2038(ra) # 80000cce <memset>
  log_write(bp);
    800034cc:	854a                	mv	a0,s2
    800034ce:	00001097          	auipc	ra,0x1
    800034d2:	050080e7          	jalr	80(ra) # 8000451e <log_write>
  brelse(bp);
    800034d6:	854a                	mv	a0,s2
    800034d8:	00000097          	auipc	ra,0x0
    800034dc:	dee080e7          	jalr	-530(ra) # 800032c6 <brelse>
}
    800034e0:	8526                	mv	a0,s1
    800034e2:	60e6                	ld	ra,88(sp)
    800034e4:	6446                	ld	s0,80(sp)
    800034e6:	64a6                	ld	s1,72(sp)
    800034e8:	6906                	ld	s2,64(sp)
    800034ea:	79e2                	ld	s3,56(sp)
    800034ec:	7a42                	ld	s4,48(sp)
    800034ee:	7aa2                	ld	s5,40(sp)
    800034f0:	7b02                	ld	s6,32(sp)
    800034f2:	6be2                	ld	s7,24(sp)
    800034f4:	6c42                	ld	s8,16(sp)
    800034f6:	6ca2                	ld	s9,8(sp)
    800034f8:	6125                	add	sp,sp,96
    800034fa:	8082                	ret
    brelse(bp);
    800034fc:	854a                	mv	a0,s2
    800034fe:	00000097          	auipc	ra,0x0
    80003502:	dc8080e7          	jalr	-568(ra) # 800032c6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003506:	015c87bb          	addw	a5,s9,s5
    8000350a:	00078a9b          	sext.w	s5,a5
    8000350e:	004b2703          	lw	a4,4(s6)
    80003512:	06eaf163          	bgeu	s5,a4,80003574 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003516:	41fad79b          	sraw	a5,s5,0x1f
    8000351a:	0137d79b          	srlw	a5,a5,0x13
    8000351e:	015787bb          	addw	a5,a5,s5
    80003522:	40d7d79b          	sraw	a5,a5,0xd
    80003526:	01cb2583          	lw	a1,28(s6)
    8000352a:	9dbd                	addw	a1,a1,a5
    8000352c:	855e                	mv	a0,s7
    8000352e:	00000097          	auipc	ra,0x0
    80003532:	c68080e7          	jalr	-920(ra) # 80003196 <bread>
    80003536:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003538:	004b2503          	lw	a0,4(s6)
    8000353c:	000a849b          	sext.w	s1,s5
    80003540:	8762                	mv	a4,s8
    80003542:	faa4fde3          	bgeu	s1,a0,800034fc <balloc+0xa6>
      m = 1 << (bi % 8);
    80003546:	00777693          	and	a3,a4,7
    8000354a:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000354e:	41f7579b          	sraw	a5,a4,0x1f
    80003552:	01d7d79b          	srlw	a5,a5,0x1d
    80003556:	9fb9                	addw	a5,a5,a4
    80003558:	4037d79b          	sraw	a5,a5,0x3
    8000355c:	00f90633          	add	a2,s2,a5
    80003560:	05864603          	lbu	a2,88(a2)
    80003564:	00c6f5b3          	and	a1,a3,a2
    80003568:	d585                	beqz	a1,80003490 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000356a:	2705                	addw	a4,a4,1
    8000356c:	2485                	addw	s1,s1,1
    8000356e:	fd471ae3          	bne	a4,s4,80003542 <balloc+0xec>
    80003572:	b769                	j	800034fc <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003574:	00005517          	auipc	a0,0x5
    80003578:	05c50513          	add	a0,a0,92 # 800085d0 <syscalls+0x118>
    8000357c:	ffffd097          	auipc	ra,0xffffd
    80003580:	00a080e7          	jalr	10(ra) # 80000586 <printf>
  return 0;
    80003584:	4481                	li	s1,0
    80003586:	bfa9                	j	800034e0 <balloc+0x8a>

0000000080003588 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003588:	7179                	add	sp,sp,-48
    8000358a:	f406                	sd	ra,40(sp)
    8000358c:	f022                	sd	s0,32(sp)
    8000358e:	ec26                	sd	s1,24(sp)
    80003590:	e84a                	sd	s2,16(sp)
    80003592:	e44e                	sd	s3,8(sp)
    80003594:	e052                	sd	s4,0(sp)
    80003596:	1800                	add	s0,sp,48
    80003598:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000359a:	47ad                	li	a5,11
    8000359c:	02b7e863          	bltu	a5,a1,800035cc <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800035a0:	02059793          	sll	a5,a1,0x20
    800035a4:	01e7d593          	srl	a1,a5,0x1e
    800035a8:	00b504b3          	add	s1,a0,a1
    800035ac:	0504a903          	lw	s2,80(s1)
    800035b0:	06091e63          	bnez	s2,8000362c <bmap+0xa4>
      addr = balloc(ip->dev);
    800035b4:	4108                	lw	a0,0(a0)
    800035b6:	00000097          	auipc	ra,0x0
    800035ba:	ea0080e7          	jalr	-352(ra) # 80003456 <balloc>
    800035be:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800035c2:	06090563          	beqz	s2,8000362c <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800035c6:	0524a823          	sw	s2,80(s1)
    800035ca:	a08d                	j	8000362c <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800035cc:	ff45849b          	addw	s1,a1,-12
    800035d0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035d4:	0ff00793          	li	a5,255
    800035d8:	08e7e563          	bltu	a5,a4,80003662 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800035dc:	08052903          	lw	s2,128(a0)
    800035e0:	00091d63          	bnez	s2,800035fa <bmap+0x72>
      addr = balloc(ip->dev);
    800035e4:	4108                	lw	a0,0(a0)
    800035e6:	00000097          	auipc	ra,0x0
    800035ea:	e70080e7          	jalr	-400(ra) # 80003456 <balloc>
    800035ee:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800035f2:	02090d63          	beqz	s2,8000362c <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800035f6:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800035fa:	85ca                	mv	a1,s2
    800035fc:	0009a503          	lw	a0,0(s3)
    80003600:	00000097          	auipc	ra,0x0
    80003604:	b96080e7          	jalr	-1130(ra) # 80003196 <bread>
    80003608:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000360a:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    8000360e:	02049713          	sll	a4,s1,0x20
    80003612:	01e75593          	srl	a1,a4,0x1e
    80003616:	00b784b3          	add	s1,a5,a1
    8000361a:	0004a903          	lw	s2,0(s1)
    8000361e:	02090063          	beqz	s2,8000363e <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003622:	8552                	mv	a0,s4
    80003624:	00000097          	auipc	ra,0x0
    80003628:	ca2080e7          	jalr	-862(ra) # 800032c6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000362c:	854a                	mv	a0,s2
    8000362e:	70a2                	ld	ra,40(sp)
    80003630:	7402                	ld	s0,32(sp)
    80003632:	64e2                	ld	s1,24(sp)
    80003634:	6942                	ld	s2,16(sp)
    80003636:	69a2                	ld	s3,8(sp)
    80003638:	6a02                	ld	s4,0(sp)
    8000363a:	6145                	add	sp,sp,48
    8000363c:	8082                	ret
      addr = balloc(ip->dev);
    8000363e:	0009a503          	lw	a0,0(s3)
    80003642:	00000097          	auipc	ra,0x0
    80003646:	e14080e7          	jalr	-492(ra) # 80003456 <balloc>
    8000364a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000364e:	fc090ae3          	beqz	s2,80003622 <bmap+0x9a>
        a[bn] = addr;
    80003652:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003656:	8552                	mv	a0,s4
    80003658:	00001097          	auipc	ra,0x1
    8000365c:	ec6080e7          	jalr	-314(ra) # 8000451e <log_write>
    80003660:	b7c9                	j	80003622 <bmap+0x9a>
  panic("bmap: out of range");
    80003662:	00005517          	auipc	a0,0x5
    80003666:	f8650513          	add	a0,a0,-122 # 800085e8 <syscalls+0x130>
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	ed2080e7          	jalr	-302(ra) # 8000053c <panic>

0000000080003672 <iget>:
{
    80003672:	7179                	add	sp,sp,-48
    80003674:	f406                	sd	ra,40(sp)
    80003676:	f022                	sd	s0,32(sp)
    80003678:	ec26                	sd	s1,24(sp)
    8000367a:	e84a                	sd	s2,16(sp)
    8000367c:	e44e                	sd	s3,8(sp)
    8000367e:	e052                	sd	s4,0(sp)
    80003680:	1800                	add	s0,sp,48
    80003682:	89aa                	mv	s3,a0
    80003684:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003686:	0001c517          	auipc	a0,0x1c
    8000368a:	e5250513          	add	a0,a0,-430 # 8001f4d8 <itable>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	544080e7          	jalr	1348(ra) # 80000bd2 <acquire>
  empty = 0;
    80003696:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003698:	0001c497          	auipc	s1,0x1c
    8000369c:	e5848493          	add	s1,s1,-424 # 8001f4f0 <itable+0x18>
    800036a0:	0001e697          	auipc	a3,0x1e
    800036a4:	8e068693          	add	a3,a3,-1824 # 80020f80 <log>
    800036a8:	a039                	j	800036b6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036aa:	02090b63          	beqz	s2,800036e0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036ae:	08848493          	add	s1,s1,136
    800036b2:	02d48a63          	beq	s1,a3,800036e6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036b6:	449c                	lw	a5,8(s1)
    800036b8:	fef059e3          	blez	a5,800036aa <iget+0x38>
    800036bc:	4098                	lw	a4,0(s1)
    800036be:	ff3716e3          	bne	a4,s3,800036aa <iget+0x38>
    800036c2:	40d8                	lw	a4,4(s1)
    800036c4:	ff4713e3          	bne	a4,s4,800036aa <iget+0x38>
      ip->ref++;
    800036c8:	2785                	addw	a5,a5,1
    800036ca:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036cc:	0001c517          	auipc	a0,0x1c
    800036d0:	e0c50513          	add	a0,a0,-500 # 8001f4d8 <itable>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	5b2080e7          	jalr	1458(ra) # 80000c86 <release>
      return ip;
    800036dc:	8926                	mv	s2,s1
    800036de:	a03d                	j	8000370c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036e0:	f7f9                	bnez	a5,800036ae <iget+0x3c>
    800036e2:	8926                	mv	s2,s1
    800036e4:	b7e9                	j	800036ae <iget+0x3c>
  if(empty == 0)
    800036e6:	02090c63          	beqz	s2,8000371e <iget+0xac>
  ip->dev = dev;
    800036ea:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036ee:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036f2:	4785                	li	a5,1
    800036f4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036f8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036fc:	0001c517          	auipc	a0,0x1c
    80003700:	ddc50513          	add	a0,a0,-548 # 8001f4d8 <itable>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	582080e7          	jalr	1410(ra) # 80000c86 <release>
}
    8000370c:	854a                	mv	a0,s2
    8000370e:	70a2                	ld	ra,40(sp)
    80003710:	7402                	ld	s0,32(sp)
    80003712:	64e2                	ld	s1,24(sp)
    80003714:	6942                	ld	s2,16(sp)
    80003716:	69a2                	ld	s3,8(sp)
    80003718:	6a02                	ld	s4,0(sp)
    8000371a:	6145                	add	sp,sp,48
    8000371c:	8082                	ret
    panic("iget: no inodes");
    8000371e:	00005517          	auipc	a0,0x5
    80003722:	ee250513          	add	a0,a0,-286 # 80008600 <syscalls+0x148>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	e16080e7          	jalr	-490(ra) # 8000053c <panic>

000000008000372e <fsinit>:
fsinit(int dev) {
    8000372e:	7179                	add	sp,sp,-48
    80003730:	f406                	sd	ra,40(sp)
    80003732:	f022                	sd	s0,32(sp)
    80003734:	ec26                	sd	s1,24(sp)
    80003736:	e84a                	sd	s2,16(sp)
    80003738:	e44e                	sd	s3,8(sp)
    8000373a:	1800                	add	s0,sp,48
    8000373c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000373e:	4585                	li	a1,1
    80003740:	00000097          	auipc	ra,0x0
    80003744:	a56080e7          	jalr	-1450(ra) # 80003196 <bread>
    80003748:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000374a:	0001c997          	auipc	s3,0x1c
    8000374e:	d6e98993          	add	s3,s3,-658 # 8001f4b8 <sb>
    80003752:	02000613          	li	a2,32
    80003756:	05850593          	add	a1,a0,88
    8000375a:	854e                	mv	a0,s3
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	5ce080e7          	jalr	1486(ra) # 80000d2a <memmove>
  brelse(bp);
    80003764:	8526                	mv	a0,s1
    80003766:	00000097          	auipc	ra,0x0
    8000376a:	b60080e7          	jalr	-1184(ra) # 800032c6 <brelse>
  if(sb.magic != FSMAGIC)
    8000376e:	0009a703          	lw	a4,0(s3)
    80003772:	102037b7          	lui	a5,0x10203
    80003776:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000377a:	02f71263          	bne	a4,a5,8000379e <fsinit+0x70>
  initlog(dev, &sb);
    8000377e:	0001c597          	auipc	a1,0x1c
    80003782:	d3a58593          	add	a1,a1,-710 # 8001f4b8 <sb>
    80003786:	854a                	mv	a0,s2
    80003788:	00001097          	auipc	ra,0x1
    8000378c:	b2c080e7          	jalr	-1236(ra) # 800042b4 <initlog>
}
    80003790:	70a2                	ld	ra,40(sp)
    80003792:	7402                	ld	s0,32(sp)
    80003794:	64e2                	ld	s1,24(sp)
    80003796:	6942                	ld	s2,16(sp)
    80003798:	69a2                	ld	s3,8(sp)
    8000379a:	6145                	add	sp,sp,48
    8000379c:	8082                	ret
    panic("invalid file system");
    8000379e:	00005517          	auipc	a0,0x5
    800037a2:	e7250513          	add	a0,a0,-398 # 80008610 <syscalls+0x158>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	d96080e7          	jalr	-618(ra) # 8000053c <panic>

00000000800037ae <iinit>:
{
    800037ae:	7179                	add	sp,sp,-48
    800037b0:	f406                	sd	ra,40(sp)
    800037b2:	f022                	sd	s0,32(sp)
    800037b4:	ec26                	sd	s1,24(sp)
    800037b6:	e84a                	sd	s2,16(sp)
    800037b8:	e44e                	sd	s3,8(sp)
    800037ba:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    800037bc:	00005597          	auipc	a1,0x5
    800037c0:	e6c58593          	add	a1,a1,-404 # 80008628 <syscalls+0x170>
    800037c4:	0001c517          	auipc	a0,0x1c
    800037c8:	d1450513          	add	a0,a0,-748 # 8001f4d8 <itable>
    800037cc:	ffffd097          	auipc	ra,0xffffd
    800037d0:	376080e7          	jalr	886(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037d4:	0001c497          	auipc	s1,0x1c
    800037d8:	d2c48493          	add	s1,s1,-724 # 8001f500 <itable+0x28>
    800037dc:	0001d997          	auipc	s3,0x1d
    800037e0:	7b498993          	add	s3,s3,1972 # 80020f90 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037e4:	00005917          	auipc	s2,0x5
    800037e8:	e4c90913          	add	s2,s2,-436 # 80008630 <syscalls+0x178>
    800037ec:	85ca                	mv	a1,s2
    800037ee:	8526                	mv	a0,s1
    800037f0:	00001097          	auipc	ra,0x1
    800037f4:	e12080e7          	jalr	-494(ra) # 80004602 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037f8:	08848493          	add	s1,s1,136
    800037fc:	ff3498e3          	bne	s1,s3,800037ec <iinit+0x3e>
}
    80003800:	70a2                	ld	ra,40(sp)
    80003802:	7402                	ld	s0,32(sp)
    80003804:	64e2                	ld	s1,24(sp)
    80003806:	6942                	ld	s2,16(sp)
    80003808:	69a2                	ld	s3,8(sp)
    8000380a:	6145                	add	sp,sp,48
    8000380c:	8082                	ret

000000008000380e <ialloc>:
{
    8000380e:	7139                	add	sp,sp,-64
    80003810:	fc06                	sd	ra,56(sp)
    80003812:	f822                	sd	s0,48(sp)
    80003814:	f426                	sd	s1,40(sp)
    80003816:	f04a                	sd	s2,32(sp)
    80003818:	ec4e                	sd	s3,24(sp)
    8000381a:	e852                	sd	s4,16(sp)
    8000381c:	e456                	sd	s5,8(sp)
    8000381e:	e05a                	sd	s6,0(sp)
    80003820:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003822:	0001c717          	auipc	a4,0x1c
    80003826:	ca272703          	lw	a4,-862(a4) # 8001f4c4 <sb+0xc>
    8000382a:	4785                	li	a5,1
    8000382c:	04e7f863          	bgeu	a5,a4,8000387c <ialloc+0x6e>
    80003830:	8aaa                	mv	s5,a0
    80003832:	8b2e                	mv	s6,a1
    80003834:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003836:	0001ca17          	auipc	s4,0x1c
    8000383a:	c82a0a13          	add	s4,s4,-894 # 8001f4b8 <sb>
    8000383e:	00495593          	srl	a1,s2,0x4
    80003842:	018a2783          	lw	a5,24(s4)
    80003846:	9dbd                	addw	a1,a1,a5
    80003848:	8556                	mv	a0,s5
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	94c080e7          	jalr	-1716(ra) # 80003196 <bread>
    80003852:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003854:	05850993          	add	s3,a0,88
    80003858:	00f97793          	and	a5,s2,15
    8000385c:	079a                	sll	a5,a5,0x6
    8000385e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003860:	00099783          	lh	a5,0(s3)
    80003864:	cf9d                	beqz	a5,800038a2 <ialloc+0x94>
    brelse(bp);
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	a60080e7          	jalr	-1440(ra) # 800032c6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000386e:	0905                	add	s2,s2,1
    80003870:	00ca2703          	lw	a4,12(s4)
    80003874:	0009079b          	sext.w	a5,s2
    80003878:	fce7e3e3          	bltu	a5,a4,8000383e <ialloc+0x30>
  printf("ialloc: no inodes\n");
    8000387c:	00005517          	auipc	a0,0x5
    80003880:	dbc50513          	add	a0,a0,-580 # 80008638 <syscalls+0x180>
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	d02080e7          	jalr	-766(ra) # 80000586 <printf>
  return 0;
    8000388c:	4501                	li	a0,0
}
    8000388e:	70e2                	ld	ra,56(sp)
    80003890:	7442                	ld	s0,48(sp)
    80003892:	74a2                	ld	s1,40(sp)
    80003894:	7902                	ld	s2,32(sp)
    80003896:	69e2                	ld	s3,24(sp)
    80003898:	6a42                	ld	s4,16(sp)
    8000389a:	6aa2                	ld	s5,8(sp)
    8000389c:	6b02                	ld	s6,0(sp)
    8000389e:	6121                	add	sp,sp,64
    800038a0:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800038a2:	04000613          	li	a2,64
    800038a6:	4581                	li	a1,0
    800038a8:	854e                	mv	a0,s3
    800038aa:	ffffd097          	auipc	ra,0xffffd
    800038ae:	424080e7          	jalr	1060(ra) # 80000cce <memset>
      dip->type = type;
    800038b2:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038b6:	8526                	mv	a0,s1
    800038b8:	00001097          	auipc	ra,0x1
    800038bc:	c66080e7          	jalr	-922(ra) # 8000451e <log_write>
      brelse(bp);
    800038c0:	8526                	mv	a0,s1
    800038c2:	00000097          	auipc	ra,0x0
    800038c6:	a04080e7          	jalr	-1532(ra) # 800032c6 <brelse>
      return iget(dev, inum);
    800038ca:	0009059b          	sext.w	a1,s2
    800038ce:	8556                	mv	a0,s5
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	da2080e7          	jalr	-606(ra) # 80003672 <iget>
    800038d8:	bf5d                	j	8000388e <ialloc+0x80>

00000000800038da <iupdate>:
{
    800038da:	1101                	add	sp,sp,-32
    800038dc:	ec06                	sd	ra,24(sp)
    800038de:	e822                	sd	s0,16(sp)
    800038e0:	e426                	sd	s1,8(sp)
    800038e2:	e04a                	sd	s2,0(sp)
    800038e4:	1000                	add	s0,sp,32
    800038e6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038e8:	415c                	lw	a5,4(a0)
    800038ea:	0047d79b          	srlw	a5,a5,0x4
    800038ee:	0001c597          	auipc	a1,0x1c
    800038f2:	be25a583          	lw	a1,-1054(a1) # 8001f4d0 <sb+0x18>
    800038f6:	9dbd                	addw	a1,a1,a5
    800038f8:	4108                	lw	a0,0(a0)
    800038fa:	00000097          	auipc	ra,0x0
    800038fe:	89c080e7          	jalr	-1892(ra) # 80003196 <bread>
    80003902:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003904:	05850793          	add	a5,a0,88
    80003908:	40d8                	lw	a4,4(s1)
    8000390a:	8b3d                	and	a4,a4,15
    8000390c:	071a                	sll	a4,a4,0x6
    8000390e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003910:	04449703          	lh	a4,68(s1)
    80003914:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003918:	04649703          	lh	a4,70(s1)
    8000391c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003920:	04849703          	lh	a4,72(s1)
    80003924:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003928:	04a49703          	lh	a4,74(s1)
    8000392c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003930:	44f8                	lw	a4,76(s1)
    80003932:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003934:	03400613          	li	a2,52
    80003938:	05048593          	add	a1,s1,80
    8000393c:	00c78513          	add	a0,a5,12
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	3ea080e7          	jalr	1002(ra) # 80000d2a <memmove>
  log_write(bp);
    80003948:	854a                	mv	a0,s2
    8000394a:	00001097          	auipc	ra,0x1
    8000394e:	bd4080e7          	jalr	-1068(ra) # 8000451e <log_write>
  brelse(bp);
    80003952:	854a                	mv	a0,s2
    80003954:	00000097          	auipc	ra,0x0
    80003958:	972080e7          	jalr	-1678(ra) # 800032c6 <brelse>
}
    8000395c:	60e2                	ld	ra,24(sp)
    8000395e:	6442                	ld	s0,16(sp)
    80003960:	64a2                	ld	s1,8(sp)
    80003962:	6902                	ld	s2,0(sp)
    80003964:	6105                	add	sp,sp,32
    80003966:	8082                	ret

0000000080003968 <idup>:
{
    80003968:	1101                	add	sp,sp,-32
    8000396a:	ec06                	sd	ra,24(sp)
    8000396c:	e822                	sd	s0,16(sp)
    8000396e:	e426                	sd	s1,8(sp)
    80003970:	1000                	add	s0,sp,32
    80003972:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003974:	0001c517          	auipc	a0,0x1c
    80003978:	b6450513          	add	a0,a0,-1180 # 8001f4d8 <itable>
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	256080e7          	jalr	598(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003984:	449c                	lw	a5,8(s1)
    80003986:	2785                	addw	a5,a5,1
    80003988:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000398a:	0001c517          	auipc	a0,0x1c
    8000398e:	b4e50513          	add	a0,a0,-1202 # 8001f4d8 <itable>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	2f4080e7          	jalr	756(ra) # 80000c86 <release>
}
    8000399a:	8526                	mv	a0,s1
    8000399c:	60e2                	ld	ra,24(sp)
    8000399e:	6442                	ld	s0,16(sp)
    800039a0:	64a2                	ld	s1,8(sp)
    800039a2:	6105                	add	sp,sp,32
    800039a4:	8082                	ret

00000000800039a6 <ilock>:
{
    800039a6:	1101                	add	sp,sp,-32
    800039a8:	ec06                	sd	ra,24(sp)
    800039aa:	e822                	sd	s0,16(sp)
    800039ac:	e426                	sd	s1,8(sp)
    800039ae:	e04a                	sd	s2,0(sp)
    800039b0:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039b2:	c115                	beqz	a0,800039d6 <ilock+0x30>
    800039b4:	84aa                	mv	s1,a0
    800039b6:	451c                	lw	a5,8(a0)
    800039b8:	00f05f63          	blez	a5,800039d6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039bc:	0541                	add	a0,a0,16
    800039be:	00001097          	auipc	ra,0x1
    800039c2:	c7e080e7          	jalr	-898(ra) # 8000463c <acquiresleep>
  if(ip->valid == 0){
    800039c6:	40bc                	lw	a5,64(s1)
    800039c8:	cf99                	beqz	a5,800039e6 <ilock+0x40>
}
    800039ca:	60e2                	ld	ra,24(sp)
    800039cc:	6442                	ld	s0,16(sp)
    800039ce:	64a2                	ld	s1,8(sp)
    800039d0:	6902                	ld	s2,0(sp)
    800039d2:	6105                	add	sp,sp,32
    800039d4:	8082                	ret
    panic("ilock");
    800039d6:	00005517          	auipc	a0,0x5
    800039da:	c7a50513          	add	a0,a0,-902 # 80008650 <syscalls+0x198>
    800039de:	ffffd097          	auipc	ra,0xffffd
    800039e2:	b5e080e7          	jalr	-1186(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039e6:	40dc                	lw	a5,4(s1)
    800039e8:	0047d79b          	srlw	a5,a5,0x4
    800039ec:	0001c597          	auipc	a1,0x1c
    800039f0:	ae45a583          	lw	a1,-1308(a1) # 8001f4d0 <sb+0x18>
    800039f4:	9dbd                	addw	a1,a1,a5
    800039f6:	4088                	lw	a0,0(s1)
    800039f8:	fffff097          	auipc	ra,0xfffff
    800039fc:	79e080e7          	jalr	1950(ra) # 80003196 <bread>
    80003a00:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a02:	05850593          	add	a1,a0,88
    80003a06:	40dc                	lw	a5,4(s1)
    80003a08:	8bbd                	and	a5,a5,15
    80003a0a:	079a                	sll	a5,a5,0x6
    80003a0c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a0e:	00059783          	lh	a5,0(a1)
    80003a12:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a16:	00259783          	lh	a5,2(a1)
    80003a1a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a1e:	00459783          	lh	a5,4(a1)
    80003a22:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a26:	00659783          	lh	a5,6(a1)
    80003a2a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a2e:	459c                	lw	a5,8(a1)
    80003a30:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a32:	03400613          	li	a2,52
    80003a36:	05b1                	add	a1,a1,12
    80003a38:	05048513          	add	a0,s1,80
    80003a3c:	ffffd097          	auipc	ra,0xffffd
    80003a40:	2ee080e7          	jalr	750(ra) # 80000d2a <memmove>
    brelse(bp);
    80003a44:	854a                	mv	a0,s2
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	880080e7          	jalr	-1920(ra) # 800032c6 <brelse>
    ip->valid = 1;
    80003a4e:	4785                	li	a5,1
    80003a50:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a52:	04449783          	lh	a5,68(s1)
    80003a56:	fbb5                	bnez	a5,800039ca <ilock+0x24>
      panic("ilock: no type");
    80003a58:	00005517          	auipc	a0,0x5
    80003a5c:	c0050513          	add	a0,a0,-1024 # 80008658 <syscalls+0x1a0>
    80003a60:	ffffd097          	auipc	ra,0xffffd
    80003a64:	adc080e7          	jalr	-1316(ra) # 8000053c <panic>

0000000080003a68 <iunlock>:
{
    80003a68:	1101                	add	sp,sp,-32
    80003a6a:	ec06                	sd	ra,24(sp)
    80003a6c:	e822                	sd	s0,16(sp)
    80003a6e:	e426                	sd	s1,8(sp)
    80003a70:	e04a                	sd	s2,0(sp)
    80003a72:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a74:	c905                	beqz	a0,80003aa4 <iunlock+0x3c>
    80003a76:	84aa                	mv	s1,a0
    80003a78:	01050913          	add	s2,a0,16
    80003a7c:	854a                	mv	a0,s2
    80003a7e:	00001097          	auipc	ra,0x1
    80003a82:	c58080e7          	jalr	-936(ra) # 800046d6 <holdingsleep>
    80003a86:	cd19                	beqz	a0,80003aa4 <iunlock+0x3c>
    80003a88:	449c                	lw	a5,8(s1)
    80003a8a:	00f05d63          	blez	a5,80003aa4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a8e:	854a                	mv	a0,s2
    80003a90:	00001097          	auipc	ra,0x1
    80003a94:	c02080e7          	jalr	-1022(ra) # 80004692 <releasesleep>
}
    80003a98:	60e2                	ld	ra,24(sp)
    80003a9a:	6442                	ld	s0,16(sp)
    80003a9c:	64a2                	ld	s1,8(sp)
    80003a9e:	6902                	ld	s2,0(sp)
    80003aa0:	6105                	add	sp,sp,32
    80003aa2:	8082                	ret
    panic("iunlock");
    80003aa4:	00005517          	auipc	a0,0x5
    80003aa8:	bc450513          	add	a0,a0,-1084 # 80008668 <syscalls+0x1b0>
    80003aac:	ffffd097          	auipc	ra,0xffffd
    80003ab0:	a90080e7          	jalr	-1392(ra) # 8000053c <panic>

0000000080003ab4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ab4:	7179                	add	sp,sp,-48
    80003ab6:	f406                	sd	ra,40(sp)
    80003ab8:	f022                	sd	s0,32(sp)
    80003aba:	ec26                	sd	s1,24(sp)
    80003abc:	e84a                	sd	s2,16(sp)
    80003abe:	e44e                	sd	s3,8(sp)
    80003ac0:	e052                	sd	s4,0(sp)
    80003ac2:	1800                	add	s0,sp,48
    80003ac4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ac6:	05050493          	add	s1,a0,80
    80003aca:	08050913          	add	s2,a0,128
    80003ace:	a021                	j	80003ad6 <itrunc+0x22>
    80003ad0:	0491                	add	s1,s1,4
    80003ad2:	01248d63          	beq	s1,s2,80003aec <itrunc+0x38>
    if(ip->addrs[i]){
    80003ad6:	408c                	lw	a1,0(s1)
    80003ad8:	dde5                	beqz	a1,80003ad0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ada:	0009a503          	lw	a0,0(s3)
    80003ade:	00000097          	auipc	ra,0x0
    80003ae2:	8fc080e7          	jalr	-1796(ra) # 800033da <bfree>
      ip->addrs[i] = 0;
    80003ae6:	0004a023          	sw	zero,0(s1)
    80003aea:	b7dd                	j	80003ad0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003aec:	0809a583          	lw	a1,128(s3)
    80003af0:	e185                	bnez	a1,80003b10 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003af2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003af6:	854e                	mv	a0,s3
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	de2080e7          	jalr	-542(ra) # 800038da <iupdate>
}
    80003b00:	70a2                	ld	ra,40(sp)
    80003b02:	7402                	ld	s0,32(sp)
    80003b04:	64e2                	ld	s1,24(sp)
    80003b06:	6942                	ld	s2,16(sp)
    80003b08:	69a2                	ld	s3,8(sp)
    80003b0a:	6a02                	ld	s4,0(sp)
    80003b0c:	6145                	add	sp,sp,48
    80003b0e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b10:	0009a503          	lw	a0,0(s3)
    80003b14:	fffff097          	auipc	ra,0xfffff
    80003b18:	682080e7          	jalr	1666(ra) # 80003196 <bread>
    80003b1c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b1e:	05850493          	add	s1,a0,88
    80003b22:	45850913          	add	s2,a0,1112
    80003b26:	a021                	j	80003b2e <itrunc+0x7a>
    80003b28:	0491                	add	s1,s1,4
    80003b2a:	01248b63          	beq	s1,s2,80003b40 <itrunc+0x8c>
      if(a[j])
    80003b2e:	408c                	lw	a1,0(s1)
    80003b30:	dde5                	beqz	a1,80003b28 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b32:	0009a503          	lw	a0,0(s3)
    80003b36:	00000097          	auipc	ra,0x0
    80003b3a:	8a4080e7          	jalr	-1884(ra) # 800033da <bfree>
    80003b3e:	b7ed                	j	80003b28 <itrunc+0x74>
    brelse(bp);
    80003b40:	8552                	mv	a0,s4
    80003b42:	fffff097          	auipc	ra,0xfffff
    80003b46:	784080e7          	jalr	1924(ra) # 800032c6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b4a:	0809a583          	lw	a1,128(s3)
    80003b4e:	0009a503          	lw	a0,0(s3)
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	888080e7          	jalr	-1912(ra) # 800033da <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b5a:	0809a023          	sw	zero,128(s3)
    80003b5e:	bf51                	j	80003af2 <itrunc+0x3e>

0000000080003b60 <iput>:
{
    80003b60:	1101                	add	sp,sp,-32
    80003b62:	ec06                	sd	ra,24(sp)
    80003b64:	e822                	sd	s0,16(sp)
    80003b66:	e426                	sd	s1,8(sp)
    80003b68:	e04a                	sd	s2,0(sp)
    80003b6a:	1000                	add	s0,sp,32
    80003b6c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b6e:	0001c517          	auipc	a0,0x1c
    80003b72:	96a50513          	add	a0,a0,-1686 # 8001f4d8 <itable>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	05c080e7          	jalr	92(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b7e:	4498                	lw	a4,8(s1)
    80003b80:	4785                	li	a5,1
    80003b82:	02f70363          	beq	a4,a5,80003ba8 <iput+0x48>
  ip->ref--;
    80003b86:	449c                	lw	a5,8(s1)
    80003b88:	37fd                	addw	a5,a5,-1
    80003b8a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b8c:	0001c517          	auipc	a0,0x1c
    80003b90:	94c50513          	add	a0,a0,-1716 # 8001f4d8 <itable>
    80003b94:	ffffd097          	auipc	ra,0xffffd
    80003b98:	0f2080e7          	jalr	242(ra) # 80000c86 <release>
}
    80003b9c:	60e2                	ld	ra,24(sp)
    80003b9e:	6442                	ld	s0,16(sp)
    80003ba0:	64a2                	ld	s1,8(sp)
    80003ba2:	6902                	ld	s2,0(sp)
    80003ba4:	6105                	add	sp,sp,32
    80003ba6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ba8:	40bc                	lw	a5,64(s1)
    80003baa:	dff1                	beqz	a5,80003b86 <iput+0x26>
    80003bac:	04a49783          	lh	a5,74(s1)
    80003bb0:	fbf9                	bnez	a5,80003b86 <iput+0x26>
    acquiresleep(&ip->lock);
    80003bb2:	01048913          	add	s2,s1,16
    80003bb6:	854a                	mv	a0,s2
    80003bb8:	00001097          	auipc	ra,0x1
    80003bbc:	a84080e7          	jalr	-1404(ra) # 8000463c <acquiresleep>
    release(&itable.lock);
    80003bc0:	0001c517          	auipc	a0,0x1c
    80003bc4:	91850513          	add	a0,a0,-1768 # 8001f4d8 <itable>
    80003bc8:	ffffd097          	auipc	ra,0xffffd
    80003bcc:	0be080e7          	jalr	190(ra) # 80000c86 <release>
    itrunc(ip);
    80003bd0:	8526                	mv	a0,s1
    80003bd2:	00000097          	auipc	ra,0x0
    80003bd6:	ee2080e7          	jalr	-286(ra) # 80003ab4 <itrunc>
    ip->type = 0;
    80003bda:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bde:	8526                	mv	a0,s1
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	cfa080e7          	jalr	-774(ra) # 800038da <iupdate>
    ip->valid = 0;
    80003be8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bec:	854a                	mv	a0,s2
    80003bee:	00001097          	auipc	ra,0x1
    80003bf2:	aa4080e7          	jalr	-1372(ra) # 80004692 <releasesleep>
    acquire(&itable.lock);
    80003bf6:	0001c517          	auipc	a0,0x1c
    80003bfa:	8e250513          	add	a0,a0,-1822 # 8001f4d8 <itable>
    80003bfe:	ffffd097          	auipc	ra,0xffffd
    80003c02:	fd4080e7          	jalr	-44(ra) # 80000bd2 <acquire>
    80003c06:	b741                	j	80003b86 <iput+0x26>

0000000080003c08 <iunlockput>:
{
    80003c08:	1101                	add	sp,sp,-32
    80003c0a:	ec06                	sd	ra,24(sp)
    80003c0c:	e822                	sd	s0,16(sp)
    80003c0e:	e426                	sd	s1,8(sp)
    80003c10:	1000                	add	s0,sp,32
    80003c12:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	e54080e7          	jalr	-428(ra) # 80003a68 <iunlock>
  iput(ip);
    80003c1c:	8526                	mv	a0,s1
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	f42080e7          	jalr	-190(ra) # 80003b60 <iput>
}
    80003c26:	60e2                	ld	ra,24(sp)
    80003c28:	6442                	ld	s0,16(sp)
    80003c2a:	64a2                	ld	s1,8(sp)
    80003c2c:	6105                	add	sp,sp,32
    80003c2e:	8082                	ret

0000000080003c30 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c30:	1141                	add	sp,sp,-16
    80003c32:	e422                	sd	s0,8(sp)
    80003c34:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003c36:	411c                	lw	a5,0(a0)
    80003c38:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c3a:	415c                	lw	a5,4(a0)
    80003c3c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c3e:	04451783          	lh	a5,68(a0)
    80003c42:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c46:	04a51783          	lh	a5,74(a0)
    80003c4a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c4e:	04c56783          	lwu	a5,76(a0)
    80003c52:	e99c                	sd	a5,16(a1)
}
    80003c54:	6422                	ld	s0,8(sp)
    80003c56:	0141                	add	sp,sp,16
    80003c58:	8082                	ret

0000000080003c5a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c5a:	457c                	lw	a5,76(a0)
    80003c5c:	0ed7e963          	bltu	a5,a3,80003d4e <readi+0xf4>
{
    80003c60:	7159                	add	sp,sp,-112
    80003c62:	f486                	sd	ra,104(sp)
    80003c64:	f0a2                	sd	s0,96(sp)
    80003c66:	eca6                	sd	s1,88(sp)
    80003c68:	e8ca                	sd	s2,80(sp)
    80003c6a:	e4ce                	sd	s3,72(sp)
    80003c6c:	e0d2                	sd	s4,64(sp)
    80003c6e:	fc56                	sd	s5,56(sp)
    80003c70:	f85a                	sd	s6,48(sp)
    80003c72:	f45e                	sd	s7,40(sp)
    80003c74:	f062                	sd	s8,32(sp)
    80003c76:	ec66                	sd	s9,24(sp)
    80003c78:	e86a                	sd	s10,16(sp)
    80003c7a:	e46e                	sd	s11,8(sp)
    80003c7c:	1880                	add	s0,sp,112
    80003c7e:	8b2a                	mv	s6,a0
    80003c80:	8bae                	mv	s7,a1
    80003c82:	8a32                	mv	s4,a2
    80003c84:	84b6                	mv	s1,a3
    80003c86:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003c88:	9f35                	addw	a4,a4,a3
    return 0;
    80003c8a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c8c:	0ad76063          	bltu	a4,a3,80003d2c <readi+0xd2>
  if(off + n > ip->size)
    80003c90:	00e7f463          	bgeu	a5,a4,80003c98 <readi+0x3e>
    n = ip->size - off;
    80003c94:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c98:	0a0a8963          	beqz	s5,80003d4a <readi+0xf0>
    80003c9c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c9e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ca2:	5c7d                	li	s8,-1
    80003ca4:	a82d                	j	80003cde <readi+0x84>
    80003ca6:	020d1d93          	sll	s11,s10,0x20
    80003caa:	020ddd93          	srl	s11,s11,0x20
    80003cae:	05890613          	add	a2,s2,88
    80003cb2:	86ee                	mv	a3,s11
    80003cb4:	963a                	add	a2,a2,a4
    80003cb6:	85d2                	mv	a1,s4
    80003cb8:	855e                	mv	a0,s7
    80003cba:	fffff097          	auipc	ra,0xfffff
    80003cbe:	88e080e7          	jalr	-1906(ra) # 80002548 <either_copyout>
    80003cc2:	05850d63          	beq	a0,s8,80003d1c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003cc6:	854a                	mv	a0,s2
    80003cc8:	fffff097          	auipc	ra,0xfffff
    80003ccc:	5fe080e7          	jalr	1534(ra) # 800032c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cd0:	013d09bb          	addw	s3,s10,s3
    80003cd4:	009d04bb          	addw	s1,s10,s1
    80003cd8:	9a6e                	add	s4,s4,s11
    80003cda:	0559f763          	bgeu	s3,s5,80003d28 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003cde:	00a4d59b          	srlw	a1,s1,0xa
    80003ce2:	855a                	mv	a0,s6
    80003ce4:	00000097          	auipc	ra,0x0
    80003ce8:	8a4080e7          	jalr	-1884(ra) # 80003588 <bmap>
    80003cec:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003cf0:	cd85                	beqz	a1,80003d28 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003cf2:	000b2503          	lw	a0,0(s6)
    80003cf6:	fffff097          	auipc	ra,0xfffff
    80003cfa:	4a0080e7          	jalr	1184(ra) # 80003196 <bread>
    80003cfe:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d00:	3ff4f713          	and	a4,s1,1023
    80003d04:	40ec87bb          	subw	a5,s9,a4
    80003d08:	413a86bb          	subw	a3,s5,s3
    80003d0c:	8d3e                	mv	s10,a5
    80003d0e:	2781                	sext.w	a5,a5
    80003d10:	0006861b          	sext.w	a2,a3
    80003d14:	f8f679e3          	bgeu	a2,a5,80003ca6 <readi+0x4c>
    80003d18:	8d36                	mv	s10,a3
    80003d1a:	b771                	j	80003ca6 <readi+0x4c>
      brelse(bp);
    80003d1c:	854a                	mv	a0,s2
    80003d1e:	fffff097          	auipc	ra,0xfffff
    80003d22:	5a8080e7          	jalr	1448(ra) # 800032c6 <brelse>
      tot = -1;
    80003d26:	59fd                	li	s3,-1
  }
  return tot;
    80003d28:	0009851b          	sext.w	a0,s3
}
    80003d2c:	70a6                	ld	ra,104(sp)
    80003d2e:	7406                	ld	s0,96(sp)
    80003d30:	64e6                	ld	s1,88(sp)
    80003d32:	6946                	ld	s2,80(sp)
    80003d34:	69a6                	ld	s3,72(sp)
    80003d36:	6a06                	ld	s4,64(sp)
    80003d38:	7ae2                	ld	s5,56(sp)
    80003d3a:	7b42                	ld	s6,48(sp)
    80003d3c:	7ba2                	ld	s7,40(sp)
    80003d3e:	7c02                	ld	s8,32(sp)
    80003d40:	6ce2                	ld	s9,24(sp)
    80003d42:	6d42                	ld	s10,16(sp)
    80003d44:	6da2                	ld	s11,8(sp)
    80003d46:	6165                	add	sp,sp,112
    80003d48:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d4a:	89d6                	mv	s3,s5
    80003d4c:	bff1                	j	80003d28 <readi+0xce>
    return 0;
    80003d4e:	4501                	li	a0,0
}
    80003d50:	8082                	ret

0000000080003d52 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d52:	457c                	lw	a5,76(a0)
    80003d54:	10d7e863          	bltu	a5,a3,80003e64 <writei+0x112>
{
    80003d58:	7159                	add	sp,sp,-112
    80003d5a:	f486                	sd	ra,104(sp)
    80003d5c:	f0a2                	sd	s0,96(sp)
    80003d5e:	eca6                	sd	s1,88(sp)
    80003d60:	e8ca                	sd	s2,80(sp)
    80003d62:	e4ce                	sd	s3,72(sp)
    80003d64:	e0d2                	sd	s4,64(sp)
    80003d66:	fc56                	sd	s5,56(sp)
    80003d68:	f85a                	sd	s6,48(sp)
    80003d6a:	f45e                	sd	s7,40(sp)
    80003d6c:	f062                	sd	s8,32(sp)
    80003d6e:	ec66                	sd	s9,24(sp)
    80003d70:	e86a                	sd	s10,16(sp)
    80003d72:	e46e                	sd	s11,8(sp)
    80003d74:	1880                	add	s0,sp,112
    80003d76:	8aaa                	mv	s5,a0
    80003d78:	8bae                	mv	s7,a1
    80003d7a:	8a32                	mv	s4,a2
    80003d7c:	8936                	mv	s2,a3
    80003d7e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d80:	00e687bb          	addw	a5,a3,a4
    80003d84:	0ed7e263          	bltu	a5,a3,80003e68 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d88:	00043737          	lui	a4,0x43
    80003d8c:	0ef76063          	bltu	a4,a5,80003e6c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d90:	0c0b0863          	beqz	s6,80003e60 <writei+0x10e>
    80003d94:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d96:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d9a:	5c7d                	li	s8,-1
    80003d9c:	a091                	j	80003de0 <writei+0x8e>
    80003d9e:	020d1d93          	sll	s11,s10,0x20
    80003da2:	020ddd93          	srl	s11,s11,0x20
    80003da6:	05848513          	add	a0,s1,88
    80003daa:	86ee                	mv	a3,s11
    80003dac:	8652                	mv	a2,s4
    80003dae:	85de                	mv	a1,s7
    80003db0:	953a                	add	a0,a0,a4
    80003db2:	ffffe097          	auipc	ra,0xffffe
    80003db6:	7ec080e7          	jalr	2028(ra) # 8000259e <either_copyin>
    80003dba:	07850263          	beq	a0,s8,80003e1e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003dbe:	8526                	mv	a0,s1
    80003dc0:	00000097          	auipc	ra,0x0
    80003dc4:	75e080e7          	jalr	1886(ra) # 8000451e <log_write>
    brelse(bp);
    80003dc8:	8526                	mv	a0,s1
    80003dca:	fffff097          	auipc	ra,0xfffff
    80003dce:	4fc080e7          	jalr	1276(ra) # 800032c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dd2:	013d09bb          	addw	s3,s10,s3
    80003dd6:	012d093b          	addw	s2,s10,s2
    80003dda:	9a6e                	add	s4,s4,s11
    80003ddc:	0569f663          	bgeu	s3,s6,80003e28 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003de0:	00a9559b          	srlw	a1,s2,0xa
    80003de4:	8556                	mv	a0,s5
    80003de6:	fffff097          	auipc	ra,0xfffff
    80003dea:	7a2080e7          	jalr	1954(ra) # 80003588 <bmap>
    80003dee:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003df2:	c99d                	beqz	a1,80003e28 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003df4:	000aa503          	lw	a0,0(s5)
    80003df8:	fffff097          	auipc	ra,0xfffff
    80003dfc:	39e080e7          	jalr	926(ra) # 80003196 <bread>
    80003e00:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e02:	3ff97713          	and	a4,s2,1023
    80003e06:	40ec87bb          	subw	a5,s9,a4
    80003e0a:	413b06bb          	subw	a3,s6,s3
    80003e0e:	8d3e                	mv	s10,a5
    80003e10:	2781                	sext.w	a5,a5
    80003e12:	0006861b          	sext.w	a2,a3
    80003e16:	f8f674e3          	bgeu	a2,a5,80003d9e <writei+0x4c>
    80003e1a:	8d36                	mv	s10,a3
    80003e1c:	b749                	j	80003d9e <writei+0x4c>
      brelse(bp);
    80003e1e:	8526                	mv	a0,s1
    80003e20:	fffff097          	auipc	ra,0xfffff
    80003e24:	4a6080e7          	jalr	1190(ra) # 800032c6 <brelse>
  }

  if(off > ip->size)
    80003e28:	04caa783          	lw	a5,76(s5)
    80003e2c:	0127f463          	bgeu	a5,s2,80003e34 <writei+0xe2>
    ip->size = off;
    80003e30:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e34:	8556                	mv	a0,s5
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	aa4080e7          	jalr	-1372(ra) # 800038da <iupdate>

  return tot;
    80003e3e:	0009851b          	sext.w	a0,s3
}
    80003e42:	70a6                	ld	ra,104(sp)
    80003e44:	7406                	ld	s0,96(sp)
    80003e46:	64e6                	ld	s1,88(sp)
    80003e48:	6946                	ld	s2,80(sp)
    80003e4a:	69a6                	ld	s3,72(sp)
    80003e4c:	6a06                	ld	s4,64(sp)
    80003e4e:	7ae2                	ld	s5,56(sp)
    80003e50:	7b42                	ld	s6,48(sp)
    80003e52:	7ba2                	ld	s7,40(sp)
    80003e54:	7c02                	ld	s8,32(sp)
    80003e56:	6ce2                	ld	s9,24(sp)
    80003e58:	6d42                	ld	s10,16(sp)
    80003e5a:	6da2                	ld	s11,8(sp)
    80003e5c:	6165                	add	sp,sp,112
    80003e5e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e60:	89da                	mv	s3,s6
    80003e62:	bfc9                	j	80003e34 <writei+0xe2>
    return -1;
    80003e64:	557d                	li	a0,-1
}
    80003e66:	8082                	ret
    return -1;
    80003e68:	557d                	li	a0,-1
    80003e6a:	bfe1                	j	80003e42 <writei+0xf0>
    return -1;
    80003e6c:	557d                	li	a0,-1
    80003e6e:	bfd1                	j	80003e42 <writei+0xf0>

0000000080003e70 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e70:	1141                	add	sp,sp,-16
    80003e72:	e406                	sd	ra,8(sp)
    80003e74:	e022                	sd	s0,0(sp)
    80003e76:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e78:	4639                	li	a2,14
    80003e7a:	ffffd097          	auipc	ra,0xffffd
    80003e7e:	f24080e7          	jalr	-220(ra) # 80000d9e <strncmp>
}
    80003e82:	60a2                	ld	ra,8(sp)
    80003e84:	6402                	ld	s0,0(sp)
    80003e86:	0141                	add	sp,sp,16
    80003e88:	8082                	ret

0000000080003e8a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e8a:	7139                	add	sp,sp,-64
    80003e8c:	fc06                	sd	ra,56(sp)
    80003e8e:	f822                	sd	s0,48(sp)
    80003e90:	f426                	sd	s1,40(sp)
    80003e92:	f04a                	sd	s2,32(sp)
    80003e94:	ec4e                	sd	s3,24(sp)
    80003e96:	e852                	sd	s4,16(sp)
    80003e98:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e9a:	04451703          	lh	a4,68(a0)
    80003e9e:	4785                	li	a5,1
    80003ea0:	00f71a63          	bne	a4,a5,80003eb4 <dirlookup+0x2a>
    80003ea4:	892a                	mv	s2,a0
    80003ea6:	89ae                	mv	s3,a1
    80003ea8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eaa:	457c                	lw	a5,76(a0)
    80003eac:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003eae:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb0:	e79d                	bnez	a5,80003ede <dirlookup+0x54>
    80003eb2:	a8a5                	j	80003f2a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003eb4:	00004517          	auipc	a0,0x4
    80003eb8:	7bc50513          	add	a0,a0,1980 # 80008670 <syscalls+0x1b8>
    80003ebc:	ffffc097          	auipc	ra,0xffffc
    80003ec0:	680080e7          	jalr	1664(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003ec4:	00004517          	auipc	a0,0x4
    80003ec8:	7c450513          	add	a0,a0,1988 # 80008688 <syscalls+0x1d0>
    80003ecc:	ffffc097          	auipc	ra,0xffffc
    80003ed0:	670080e7          	jalr	1648(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed4:	24c1                	addw	s1,s1,16
    80003ed6:	04c92783          	lw	a5,76(s2)
    80003eda:	04f4f763          	bgeu	s1,a5,80003f28 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ede:	4741                	li	a4,16
    80003ee0:	86a6                	mv	a3,s1
    80003ee2:	fc040613          	add	a2,s0,-64
    80003ee6:	4581                	li	a1,0
    80003ee8:	854a                	mv	a0,s2
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	d70080e7          	jalr	-656(ra) # 80003c5a <readi>
    80003ef2:	47c1                	li	a5,16
    80003ef4:	fcf518e3          	bne	a0,a5,80003ec4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ef8:	fc045783          	lhu	a5,-64(s0)
    80003efc:	dfe1                	beqz	a5,80003ed4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003efe:	fc240593          	add	a1,s0,-62
    80003f02:	854e                	mv	a0,s3
    80003f04:	00000097          	auipc	ra,0x0
    80003f08:	f6c080e7          	jalr	-148(ra) # 80003e70 <namecmp>
    80003f0c:	f561                	bnez	a0,80003ed4 <dirlookup+0x4a>
      if(poff)
    80003f0e:	000a0463          	beqz	s4,80003f16 <dirlookup+0x8c>
        *poff = off;
    80003f12:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f16:	fc045583          	lhu	a1,-64(s0)
    80003f1a:	00092503          	lw	a0,0(s2)
    80003f1e:	fffff097          	auipc	ra,0xfffff
    80003f22:	754080e7          	jalr	1876(ra) # 80003672 <iget>
    80003f26:	a011                	j	80003f2a <dirlookup+0xa0>
  return 0;
    80003f28:	4501                	li	a0,0
}
    80003f2a:	70e2                	ld	ra,56(sp)
    80003f2c:	7442                	ld	s0,48(sp)
    80003f2e:	74a2                	ld	s1,40(sp)
    80003f30:	7902                	ld	s2,32(sp)
    80003f32:	69e2                	ld	s3,24(sp)
    80003f34:	6a42                	ld	s4,16(sp)
    80003f36:	6121                	add	sp,sp,64
    80003f38:	8082                	ret

0000000080003f3a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f3a:	711d                	add	sp,sp,-96
    80003f3c:	ec86                	sd	ra,88(sp)
    80003f3e:	e8a2                	sd	s0,80(sp)
    80003f40:	e4a6                	sd	s1,72(sp)
    80003f42:	e0ca                	sd	s2,64(sp)
    80003f44:	fc4e                	sd	s3,56(sp)
    80003f46:	f852                	sd	s4,48(sp)
    80003f48:	f456                	sd	s5,40(sp)
    80003f4a:	f05a                	sd	s6,32(sp)
    80003f4c:	ec5e                	sd	s7,24(sp)
    80003f4e:	e862                	sd	s8,16(sp)
    80003f50:	e466                	sd	s9,8(sp)
    80003f52:	1080                	add	s0,sp,96
    80003f54:	84aa                	mv	s1,a0
    80003f56:	8b2e                	mv	s6,a1
    80003f58:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f5a:	00054703          	lbu	a4,0(a0)
    80003f5e:	02f00793          	li	a5,47
    80003f62:	02f70263          	beq	a4,a5,80003f86 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f66:	ffffe097          	auipc	ra,0xffffe
    80003f6a:	a40080e7          	jalr	-1472(ra) # 800019a6 <myproc>
    80003f6e:	15053503          	ld	a0,336(a0)
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	9f6080e7          	jalr	-1546(ra) # 80003968 <idup>
    80003f7a:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003f7c:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003f80:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f82:	4b85                	li	s7,1
    80003f84:	a875                	j	80004040 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003f86:	4585                	li	a1,1
    80003f88:	4505                	li	a0,1
    80003f8a:	fffff097          	auipc	ra,0xfffff
    80003f8e:	6e8080e7          	jalr	1768(ra) # 80003672 <iget>
    80003f92:	8a2a                	mv	s4,a0
    80003f94:	b7e5                	j	80003f7c <namex+0x42>
      iunlockput(ip);
    80003f96:	8552                	mv	a0,s4
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	c70080e7          	jalr	-912(ra) # 80003c08 <iunlockput>
      return 0;
    80003fa0:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fa2:	8552                	mv	a0,s4
    80003fa4:	60e6                	ld	ra,88(sp)
    80003fa6:	6446                	ld	s0,80(sp)
    80003fa8:	64a6                	ld	s1,72(sp)
    80003faa:	6906                	ld	s2,64(sp)
    80003fac:	79e2                	ld	s3,56(sp)
    80003fae:	7a42                	ld	s4,48(sp)
    80003fb0:	7aa2                	ld	s5,40(sp)
    80003fb2:	7b02                	ld	s6,32(sp)
    80003fb4:	6be2                	ld	s7,24(sp)
    80003fb6:	6c42                	ld	s8,16(sp)
    80003fb8:	6ca2                	ld	s9,8(sp)
    80003fba:	6125                	add	sp,sp,96
    80003fbc:	8082                	ret
      iunlock(ip);
    80003fbe:	8552                	mv	a0,s4
    80003fc0:	00000097          	auipc	ra,0x0
    80003fc4:	aa8080e7          	jalr	-1368(ra) # 80003a68 <iunlock>
      return ip;
    80003fc8:	bfe9                	j	80003fa2 <namex+0x68>
      iunlockput(ip);
    80003fca:	8552                	mv	a0,s4
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	c3c080e7          	jalr	-964(ra) # 80003c08 <iunlockput>
      return 0;
    80003fd4:	8a4e                	mv	s4,s3
    80003fd6:	b7f1                	j	80003fa2 <namex+0x68>
  len = path - s;
    80003fd8:	40998633          	sub	a2,s3,s1
    80003fdc:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003fe0:	099c5863          	bge	s8,s9,80004070 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003fe4:	4639                	li	a2,14
    80003fe6:	85a6                	mv	a1,s1
    80003fe8:	8556                	mv	a0,s5
    80003fea:	ffffd097          	auipc	ra,0xffffd
    80003fee:	d40080e7          	jalr	-704(ra) # 80000d2a <memmove>
    80003ff2:	84ce                	mv	s1,s3
  while(*path == '/')
    80003ff4:	0004c783          	lbu	a5,0(s1)
    80003ff8:	01279763          	bne	a5,s2,80004006 <namex+0xcc>
    path++;
    80003ffc:	0485                	add	s1,s1,1
  while(*path == '/')
    80003ffe:	0004c783          	lbu	a5,0(s1)
    80004002:	ff278de3          	beq	a5,s2,80003ffc <namex+0xc2>
    ilock(ip);
    80004006:	8552                	mv	a0,s4
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	99e080e7          	jalr	-1634(ra) # 800039a6 <ilock>
    if(ip->type != T_DIR){
    80004010:	044a1783          	lh	a5,68(s4)
    80004014:	f97791e3          	bne	a5,s7,80003f96 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004018:	000b0563          	beqz	s6,80004022 <namex+0xe8>
    8000401c:	0004c783          	lbu	a5,0(s1)
    80004020:	dfd9                	beqz	a5,80003fbe <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004022:	4601                	li	a2,0
    80004024:	85d6                	mv	a1,s5
    80004026:	8552                	mv	a0,s4
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	e62080e7          	jalr	-414(ra) # 80003e8a <dirlookup>
    80004030:	89aa                	mv	s3,a0
    80004032:	dd41                	beqz	a0,80003fca <namex+0x90>
    iunlockput(ip);
    80004034:	8552                	mv	a0,s4
    80004036:	00000097          	auipc	ra,0x0
    8000403a:	bd2080e7          	jalr	-1070(ra) # 80003c08 <iunlockput>
    ip = next;
    8000403e:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004040:	0004c783          	lbu	a5,0(s1)
    80004044:	01279763          	bne	a5,s2,80004052 <namex+0x118>
    path++;
    80004048:	0485                	add	s1,s1,1
  while(*path == '/')
    8000404a:	0004c783          	lbu	a5,0(s1)
    8000404e:	ff278de3          	beq	a5,s2,80004048 <namex+0x10e>
  if(*path == 0)
    80004052:	cb9d                	beqz	a5,80004088 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004054:	0004c783          	lbu	a5,0(s1)
    80004058:	89a6                	mv	s3,s1
  len = path - s;
    8000405a:	4c81                	li	s9,0
    8000405c:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    8000405e:	01278963          	beq	a5,s2,80004070 <namex+0x136>
    80004062:	dbbd                	beqz	a5,80003fd8 <namex+0x9e>
    path++;
    80004064:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80004066:	0009c783          	lbu	a5,0(s3)
    8000406a:	ff279ce3          	bne	a5,s2,80004062 <namex+0x128>
    8000406e:	b7ad                	j	80003fd8 <namex+0x9e>
    memmove(name, s, len);
    80004070:	2601                	sext.w	a2,a2
    80004072:	85a6                	mv	a1,s1
    80004074:	8556                	mv	a0,s5
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	cb4080e7          	jalr	-844(ra) # 80000d2a <memmove>
    name[len] = 0;
    8000407e:	9cd6                	add	s9,s9,s5
    80004080:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004084:	84ce                	mv	s1,s3
    80004086:	b7bd                	j	80003ff4 <namex+0xba>
  if(nameiparent){
    80004088:	f00b0de3          	beqz	s6,80003fa2 <namex+0x68>
    iput(ip);
    8000408c:	8552                	mv	a0,s4
    8000408e:	00000097          	auipc	ra,0x0
    80004092:	ad2080e7          	jalr	-1326(ra) # 80003b60 <iput>
    return 0;
    80004096:	4a01                	li	s4,0
    80004098:	b729                	j	80003fa2 <namex+0x68>

000000008000409a <dirlink>:
{
    8000409a:	7139                	add	sp,sp,-64
    8000409c:	fc06                	sd	ra,56(sp)
    8000409e:	f822                	sd	s0,48(sp)
    800040a0:	f426                	sd	s1,40(sp)
    800040a2:	f04a                	sd	s2,32(sp)
    800040a4:	ec4e                	sd	s3,24(sp)
    800040a6:	e852                	sd	s4,16(sp)
    800040a8:	0080                	add	s0,sp,64
    800040aa:	892a                	mv	s2,a0
    800040ac:	8a2e                	mv	s4,a1
    800040ae:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040b0:	4601                	li	a2,0
    800040b2:	00000097          	auipc	ra,0x0
    800040b6:	dd8080e7          	jalr	-552(ra) # 80003e8a <dirlookup>
    800040ba:	e93d                	bnez	a0,80004130 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040bc:	04c92483          	lw	s1,76(s2)
    800040c0:	c49d                	beqz	s1,800040ee <dirlink+0x54>
    800040c2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040c4:	4741                	li	a4,16
    800040c6:	86a6                	mv	a3,s1
    800040c8:	fc040613          	add	a2,s0,-64
    800040cc:	4581                	li	a1,0
    800040ce:	854a                	mv	a0,s2
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	b8a080e7          	jalr	-1142(ra) # 80003c5a <readi>
    800040d8:	47c1                	li	a5,16
    800040da:	06f51163          	bne	a0,a5,8000413c <dirlink+0xa2>
    if(de.inum == 0)
    800040de:	fc045783          	lhu	a5,-64(s0)
    800040e2:	c791                	beqz	a5,800040ee <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040e4:	24c1                	addw	s1,s1,16
    800040e6:	04c92783          	lw	a5,76(s2)
    800040ea:	fcf4ede3          	bltu	s1,a5,800040c4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040ee:	4639                	li	a2,14
    800040f0:	85d2                	mv	a1,s4
    800040f2:	fc240513          	add	a0,s0,-62
    800040f6:	ffffd097          	auipc	ra,0xffffd
    800040fa:	ce4080e7          	jalr	-796(ra) # 80000dda <strncpy>
  de.inum = inum;
    800040fe:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004102:	4741                	li	a4,16
    80004104:	86a6                	mv	a3,s1
    80004106:	fc040613          	add	a2,s0,-64
    8000410a:	4581                	li	a1,0
    8000410c:	854a                	mv	a0,s2
    8000410e:	00000097          	auipc	ra,0x0
    80004112:	c44080e7          	jalr	-956(ra) # 80003d52 <writei>
    80004116:	1541                	add	a0,a0,-16
    80004118:	00a03533          	snez	a0,a0
    8000411c:	40a00533          	neg	a0,a0
}
    80004120:	70e2                	ld	ra,56(sp)
    80004122:	7442                	ld	s0,48(sp)
    80004124:	74a2                	ld	s1,40(sp)
    80004126:	7902                	ld	s2,32(sp)
    80004128:	69e2                	ld	s3,24(sp)
    8000412a:	6a42                	ld	s4,16(sp)
    8000412c:	6121                	add	sp,sp,64
    8000412e:	8082                	ret
    iput(ip);
    80004130:	00000097          	auipc	ra,0x0
    80004134:	a30080e7          	jalr	-1488(ra) # 80003b60 <iput>
    return -1;
    80004138:	557d                	li	a0,-1
    8000413a:	b7dd                	j	80004120 <dirlink+0x86>
      panic("dirlink read");
    8000413c:	00004517          	auipc	a0,0x4
    80004140:	55c50513          	add	a0,a0,1372 # 80008698 <syscalls+0x1e0>
    80004144:	ffffc097          	auipc	ra,0xffffc
    80004148:	3f8080e7          	jalr	1016(ra) # 8000053c <panic>

000000008000414c <namei>:

struct inode*
namei(char *path)
{
    8000414c:	1101                	add	sp,sp,-32
    8000414e:	ec06                	sd	ra,24(sp)
    80004150:	e822                	sd	s0,16(sp)
    80004152:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004154:	fe040613          	add	a2,s0,-32
    80004158:	4581                	li	a1,0
    8000415a:	00000097          	auipc	ra,0x0
    8000415e:	de0080e7          	jalr	-544(ra) # 80003f3a <namex>
}
    80004162:	60e2                	ld	ra,24(sp)
    80004164:	6442                	ld	s0,16(sp)
    80004166:	6105                	add	sp,sp,32
    80004168:	8082                	ret

000000008000416a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000416a:	1141                	add	sp,sp,-16
    8000416c:	e406                	sd	ra,8(sp)
    8000416e:	e022                	sd	s0,0(sp)
    80004170:	0800                	add	s0,sp,16
    80004172:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004174:	4585                	li	a1,1
    80004176:	00000097          	auipc	ra,0x0
    8000417a:	dc4080e7          	jalr	-572(ra) # 80003f3a <namex>
}
    8000417e:	60a2                	ld	ra,8(sp)
    80004180:	6402                	ld	s0,0(sp)
    80004182:	0141                	add	sp,sp,16
    80004184:	8082                	ret

0000000080004186 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004186:	1101                	add	sp,sp,-32
    80004188:	ec06                	sd	ra,24(sp)
    8000418a:	e822                	sd	s0,16(sp)
    8000418c:	e426                	sd	s1,8(sp)
    8000418e:	e04a                	sd	s2,0(sp)
    80004190:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004192:	0001d917          	auipc	s2,0x1d
    80004196:	dee90913          	add	s2,s2,-530 # 80020f80 <log>
    8000419a:	01892583          	lw	a1,24(s2)
    8000419e:	02892503          	lw	a0,40(s2)
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	ff4080e7          	jalr	-12(ra) # 80003196 <bread>
    800041aa:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041ac:	02c92603          	lw	a2,44(s2)
    800041b0:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041b2:	00c05f63          	blez	a2,800041d0 <write_head+0x4a>
    800041b6:	0001d717          	auipc	a4,0x1d
    800041ba:	dfa70713          	add	a4,a4,-518 # 80020fb0 <log+0x30>
    800041be:	87aa                	mv	a5,a0
    800041c0:	060a                	sll	a2,a2,0x2
    800041c2:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800041c4:	4314                	lw	a3,0(a4)
    800041c6:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800041c8:	0711                	add	a4,a4,4
    800041ca:	0791                	add	a5,a5,4
    800041cc:	fec79ce3          	bne	a5,a2,800041c4 <write_head+0x3e>
  }
  bwrite(buf);
    800041d0:	8526                	mv	a0,s1
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	0b6080e7          	jalr	182(ra) # 80003288 <bwrite>
  brelse(buf);
    800041da:	8526                	mv	a0,s1
    800041dc:	fffff097          	auipc	ra,0xfffff
    800041e0:	0ea080e7          	jalr	234(ra) # 800032c6 <brelse>
}
    800041e4:	60e2                	ld	ra,24(sp)
    800041e6:	6442                	ld	s0,16(sp)
    800041e8:	64a2                	ld	s1,8(sp)
    800041ea:	6902                	ld	s2,0(sp)
    800041ec:	6105                	add	sp,sp,32
    800041ee:	8082                	ret

00000000800041f0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041f0:	0001d797          	auipc	a5,0x1d
    800041f4:	dbc7a783          	lw	a5,-580(a5) # 80020fac <log+0x2c>
    800041f8:	0af05d63          	blez	a5,800042b2 <install_trans+0xc2>
{
    800041fc:	7139                	add	sp,sp,-64
    800041fe:	fc06                	sd	ra,56(sp)
    80004200:	f822                	sd	s0,48(sp)
    80004202:	f426                	sd	s1,40(sp)
    80004204:	f04a                	sd	s2,32(sp)
    80004206:	ec4e                	sd	s3,24(sp)
    80004208:	e852                	sd	s4,16(sp)
    8000420a:	e456                	sd	s5,8(sp)
    8000420c:	e05a                	sd	s6,0(sp)
    8000420e:	0080                	add	s0,sp,64
    80004210:	8b2a                	mv	s6,a0
    80004212:	0001da97          	auipc	s5,0x1d
    80004216:	d9ea8a93          	add	s5,s5,-610 # 80020fb0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000421a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000421c:	0001d997          	auipc	s3,0x1d
    80004220:	d6498993          	add	s3,s3,-668 # 80020f80 <log>
    80004224:	a00d                	j	80004246 <install_trans+0x56>
    brelse(lbuf);
    80004226:	854a                	mv	a0,s2
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	09e080e7          	jalr	158(ra) # 800032c6 <brelse>
    brelse(dbuf);
    80004230:	8526                	mv	a0,s1
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	094080e7          	jalr	148(ra) # 800032c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000423a:	2a05                	addw	s4,s4,1
    8000423c:	0a91                	add	s5,s5,4
    8000423e:	02c9a783          	lw	a5,44(s3)
    80004242:	04fa5e63          	bge	s4,a5,8000429e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004246:	0189a583          	lw	a1,24(s3)
    8000424a:	014585bb          	addw	a1,a1,s4
    8000424e:	2585                	addw	a1,a1,1
    80004250:	0289a503          	lw	a0,40(s3)
    80004254:	fffff097          	auipc	ra,0xfffff
    80004258:	f42080e7          	jalr	-190(ra) # 80003196 <bread>
    8000425c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000425e:	000aa583          	lw	a1,0(s5)
    80004262:	0289a503          	lw	a0,40(s3)
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	f30080e7          	jalr	-208(ra) # 80003196 <bread>
    8000426e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004270:	40000613          	li	a2,1024
    80004274:	05890593          	add	a1,s2,88
    80004278:	05850513          	add	a0,a0,88
    8000427c:	ffffd097          	auipc	ra,0xffffd
    80004280:	aae080e7          	jalr	-1362(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004284:	8526                	mv	a0,s1
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	002080e7          	jalr	2(ra) # 80003288 <bwrite>
    if(recovering == 0)
    8000428e:	f80b1ce3          	bnez	s6,80004226 <install_trans+0x36>
      bunpin(dbuf);
    80004292:	8526                	mv	a0,s1
    80004294:	fffff097          	auipc	ra,0xfffff
    80004298:	10a080e7          	jalr	266(ra) # 8000339e <bunpin>
    8000429c:	b769                	j	80004226 <install_trans+0x36>
}
    8000429e:	70e2                	ld	ra,56(sp)
    800042a0:	7442                	ld	s0,48(sp)
    800042a2:	74a2                	ld	s1,40(sp)
    800042a4:	7902                	ld	s2,32(sp)
    800042a6:	69e2                	ld	s3,24(sp)
    800042a8:	6a42                	ld	s4,16(sp)
    800042aa:	6aa2                	ld	s5,8(sp)
    800042ac:	6b02                	ld	s6,0(sp)
    800042ae:	6121                	add	sp,sp,64
    800042b0:	8082                	ret
    800042b2:	8082                	ret

00000000800042b4 <initlog>:
{
    800042b4:	7179                	add	sp,sp,-48
    800042b6:	f406                	sd	ra,40(sp)
    800042b8:	f022                	sd	s0,32(sp)
    800042ba:	ec26                	sd	s1,24(sp)
    800042bc:	e84a                	sd	s2,16(sp)
    800042be:	e44e                	sd	s3,8(sp)
    800042c0:	1800                	add	s0,sp,48
    800042c2:	892a                	mv	s2,a0
    800042c4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042c6:	0001d497          	auipc	s1,0x1d
    800042ca:	cba48493          	add	s1,s1,-838 # 80020f80 <log>
    800042ce:	00004597          	auipc	a1,0x4
    800042d2:	3da58593          	add	a1,a1,986 # 800086a8 <syscalls+0x1f0>
    800042d6:	8526                	mv	a0,s1
    800042d8:	ffffd097          	auipc	ra,0xffffd
    800042dc:	86a080e7          	jalr	-1942(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    800042e0:	0149a583          	lw	a1,20(s3)
    800042e4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042e6:	0109a783          	lw	a5,16(s3)
    800042ea:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042ec:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042f0:	854a                	mv	a0,s2
    800042f2:	fffff097          	auipc	ra,0xfffff
    800042f6:	ea4080e7          	jalr	-348(ra) # 80003196 <bread>
  log.lh.n = lh->n;
    800042fa:	4d30                	lw	a2,88(a0)
    800042fc:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042fe:	00c05f63          	blez	a2,8000431c <initlog+0x68>
    80004302:	87aa                	mv	a5,a0
    80004304:	0001d717          	auipc	a4,0x1d
    80004308:	cac70713          	add	a4,a4,-852 # 80020fb0 <log+0x30>
    8000430c:	060a                	sll	a2,a2,0x2
    8000430e:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004310:	4ff4                	lw	a3,92(a5)
    80004312:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004314:	0791                	add	a5,a5,4
    80004316:	0711                	add	a4,a4,4
    80004318:	fec79ce3          	bne	a5,a2,80004310 <initlog+0x5c>
  brelse(buf);
    8000431c:	fffff097          	auipc	ra,0xfffff
    80004320:	faa080e7          	jalr	-86(ra) # 800032c6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004324:	4505                	li	a0,1
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	eca080e7          	jalr	-310(ra) # 800041f0 <install_trans>
  log.lh.n = 0;
    8000432e:	0001d797          	auipc	a5,0x1d
    80004332:	c607af23          	sw	zero,-898(a5) # 80020fac <log+0x2c>
  write_head(); // clear the log
    80004336:	00000097          	auipc	ra,0x0
    8000433a:	e50080e7          	jalr	-432(ra) # 80004186 <write_head>
}
    8000433e:	70a2                	ld	ra,40(sp)
    80004340:	7402                	ld	s0,32(sp)
    80004342:	64e2                	ld	s1,24(sp)
    80004344:	6942                	ld	s2,16(sp)
    80004346:	69a2                	ld	s3,8(sp)
    80004348:	6145                	add	sp,sp,48
    8000434a:	8082                	ret

000000008000434c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000434c:	1101                	add	sp,sp,-32
    8000434e:	ec06                	sd	ra,24(sp)
    80004350:	e822                	sd	s0,16(sp)
    80004352:	e426                	sd	s1,8(sp)
    80004354:	e04a                	sd	s2,0(sp)
    80004356:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004358:	0001d517          	auipc	a0,0x1d
    8000435c:	c2850513          	add	a0,a0,-984 # 80020f80 <log>
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	872080e7          	jalr	-1934(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004368:	0001d497          	auipc	s1,0x1d
    8000436c:	c1848493          	add	s1,s1,-1000 # 80020f80 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004370:	4979                	li	s2,30
    80004372:	a039                	j	80004380 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004374:	85a6                	mv	a1,s1
    80004376:	8526                	mv	a0,s1
    80004378:	ffffe097          	auipc	ra,0xffffe
    8000437c:	d82080e7          	jalr	-638(ra) # 800020fa <sleep>
    if(log.committing){
    80004380:	50dc                	lw	a5,36(s1)
    80004382:	fbed                	bnez	a5,80004374 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004384:	5098                	lw	a4,32(s1)
    80004386:	2705                	addw	a4,a4,1
    80004388:	0027179b          	sllw	a5,a4,0x2
    8000438c:	9fb9                	addw	a5,a5,a4
    8000438e:	0017979b          	sllw	a5,a5,0x1
    80004392:	54d4                	lw	a3,44(s1)
    80004394:	9fb5                	addw	a5,a5,a3
    80004396:	00f95963          	bge	s2,a5,800043a8 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000439a:	85a6                	mv	a1,s1
    8000439c:	8526                	mv	a0,s1
    8000439e:	ffffe097          	auipc	ra,0xffffe
    800043a2:	d5c080e7          	jalr	-676(ra) # 800020fa <sleep>
    800043a6:	bfe9                	j	80004380 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043a8:	0001d517          	auipc	a0,0x1d
    800043ac:	bd850513          	add	a0,a0,-1064 # 80020f80 <log>
    800043b0:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	8d4080e7          	jalr	-1836(ra) # 80000c86 <release>
      break;
    }
  }
}
    800043ba:	60e2                	ld	ra,24(sp)
    800043bc:	6442                	ld	s0,16(sp)
    800043be:	64a2                	ld	s1,8(sp)
    800043c0:	6902                	ld	s2,0(sp)
    800043c2:	6105                	add	sp,sp,32
    800043c4:	8082                	ret

00000000800043c6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043c6:	7139                	add	sp,sp,-64
    800043c8:	fc06                	sd	ra,56(sp)
    800043ca:	f822                	sd	s0,48(sp)
    800043cc:	f426                	sd	s1,40(sp)
    800043ce:	f04a                	sd	s2,32(sp)
    800043d0:	ec4e                	sd	s3,24(sp)
    800043d2:	e852                	sd	s4,16(sp)
    800043d4:	e456                	sd	s5,8(sp)
    800043d6:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043d8:	0001d497          	auipc	s1,0x1d
    800043dc:	ba848493          	add	s1,s1,-1112 # 80020f80 <log>
    800043e0:	8526                	mv	a0,s1
    800043e2:	ffffc097          	auipc	ra,0xffffc
    800043e6:	7f0080e7          	jalr	2032(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    800043ea:	509c                	lw	a5,32(s1)
    800043ec:	37fd                	addw	a5,a5,-1
    800043ee:	0007891b          	sext.w	s2,a5
    800043f2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043f4:	50dc                	lw	a5,36(s1)
    800043f6:	e7b9                	bnez	a5,80004444 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043f8:	04091e63          	bnez	s2,80004454 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043fc:	0001d497          	auipc	s1,0x1d
    80004400:	b8448493          	add	s1,s1,-1148 # 80020f80 <log>
    80004404:	4785                	li	a5,1
    80004406:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004408:	8526                	mv	a0,s1
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	87c080e7          	jalr	-1924(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004412:	54dc                	lw	a5,44(s1)
    80004414:	06f04763          	bgtz	a5,80004482 <end_op+0xbc>
    acquire(&log.lock);
    80004418:	0001d497          	auipc	s1,0x1d
    8000441c:	b6848493          	add	s1,s1,-1176 # 80020f80 <log>
    80004420:	8526                	mv	a0,s1
    80004422:	ffffc097          	auipc	ra,0xffffc
    80004426:	7b0080e7          	jalr	1968(ra) # 80000bd2 <acquire>
    log.committing = 0;
    8000442a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000442e:	8526                	mv	a0,s1
    80004430:	ffffe097          	auipc	ra,0xffffe
    80004434:	d2e080e7          	jalr	-722(ra) # 8000215e <wakeup>
    release(&log.lock);
    80004438:	8526                	mv	a0,s1
    8000443a:	ffffd097          	auipc	ra,0xffffd
    8000443e:	84c080e7          	jalr	-1972(ra) # 80000c86 <release>
}
    80004442:	a03d                	j	80004470 <end_op+0xaa>
    panic("log.committing");
    80004444:	00004517          	auipc	a0,0x4
    80004448:	26c50513          	add	a0,a0,620 # 800086b0 <syscalls+0x1f8>
    8000444c:	ffffc097          	auipc	ra,0xffffc
    80004450:	0f0080e7          	jalr	240(ra) # 8000053c <panic>
    wakeup(&log);
    80004454:	0001d497          	auipc	s1,0x1d
    80004458:	b2c48493          	add	s1,s1,-1236 # 80020f80 <log>
    8000445c:	8526                	mv	a0,s1
    8000445e:	ffffe097          	auipc	ra,0xffffe
    80004462:	d00080e7          	jalr	-768(ra) # 8000215e <wakeup>
  release(&log.lock);
    80004466:	8526                	mv	a0,s1
    80004468:	ffffd097          	auipc	ra,0xffffd
    8000446c:	81e080e7          	jalr	-2018(ra) # 80000c86 <release>
}
    80004470:	70e2                	ld	ra,56(sp)
    80004472:	7442                	ld	s0,48(sp)
    80004474:	74a2                	ld	s1,40(sp)
    80004476:	7902                	ld	s2,32(sp)
    80004478:	69e2                	ld	s3,24(sp)
    8000447a:	6a42                	ld	s4,16(sp)
    8000447c:	6aa2                	ld	s5,8(sp)
    8000447e:	6121                	add	sp,sp,64
    80004480:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004482:	0001da97          	auipc	s5,0x1d
    80004486:	b2ea8a93          	add	s5,s5,-1234 # 80020fb0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000448a:	0001da17          	auipc	s4,0x1d
    8000448e:	af6a0a13          	add	s4,s4,-1290 # 80020f80 <log>
    80004492:	018a2583          	lw	a1,24(s4)
    80004496:	012585bb          	addw	a1,a1,s2
    8000449a:	2585                	addw	a1,a1,1
    8000449c:	028a2503          	lw	a0,40(s4)
    800044a0:	fffff097          	auipc	ra,0xfffff
    800044a4:	cf6080e7          	jalr	-778(ra) # 80003196 <bread>
    800044a8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044aa:	000aa583          	lw	a1,0(s5)
    800044ae:	028a2503          	lw	a0,40(s4)
    800044b2:	fffff097          	auipc	ra,0xfffff
    800044b6:	ce4080e7          	jalr	-796(ra) # 80003196 <bread>
    800044ba:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044bc:	40000613          	li	a2,1024
    800044c0:	05850593          	add	a1,a0,88
    800044c4:	05848513          	add	a0,s1,88
    800044c8:	ffffd097          	auipc	ra,0xffffd
    800044cc:	862080e7          	jalr	-1950(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    800044d0:	8526                	mv	a0,s1
    800044d2:	fffff097          	auipc	ra,0xfffff
    800044d6:	db6080e7          	jalr	-586(ra) # 80003288 <bwrite>
    brelse(from);
    800044da:	854e                	mv	a0,s3
    800044dc:	fffff097          	auipc	ra,0xfffff
    800044e0:	dea080e7          	jalr	-534(ra) # 800032c6 <brelse>
    brelse(to);
    800044e4:	8526                	mv	a0,s1
    800044e6:	fffff097          	auipc	ra,0xfffff
    800044ea:	de0080e7          	jalr	-544(ra) # 800032c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ee:	2905                	addw	s2,s2,1
    800044f0:	0a91                	add	s5,s5,4
    800044f2:	02ca2783          	lw	a5,44(s4)
    800044f6:	f8f94ee3          	blt	s2,a5,80004492 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	c8c080e7          	jalr	-884(ra) # 80004186 <write_head>
    install_trans(0); // Now install writes to home locations
    80004502:	4501                	li	a0,0
    80004504:	00000097          	auipc	ra,0x0
    80004508:	cec080e7          	jalr	-788(ra) # 800041f0 <install_trans>
    log.lh.n = 0;
    8000450c:	0001d797          	auipc	a5,0x1d
    80004510:	aa07a023          	sw	zero,-1376(a5) # 80020fac <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004514:	00000097          	auipc	ra,0x0
    80004518:	c72080e7          	jalr	-910(ra) # 80004186 <write_head>
    8000451c:	bdf5                	j	80004418 <end_op+0x52>

000000008000451e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000451e:	1101                	add	sp,sp,-32
    80004520:	ec06                	sd	ra,24(sp)
    80004522:	e822                	sd	s0,16(sp)
    80004524:	e426                	sd	s1,8(sp)
    80004526:	e04a                	sd	s2,0(sp)
    80004528:	1000                	add	s0,sp,32
    8000452a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000452c:	0001d917          	auipc	s2,0x1d
    80004530:	a5490913          	add	s2,s2,-1452 # 80020f80 <log>
    80004534:	854a                	mv	a0,s2
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	69c080e7          	jalr	1692(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000453e:	02c92603          	lw	a2,44(s2)
    80004542:	47f5                	li	a5,29
    80004544:	06c7c563          	blt	a5,a2,800045ae <log_write+0x90>
    80004548:	0001d797          	auipc	a5,0x1d
    8000454c:	a547a783          	lw	a5,-1452(a5) # 80020f9c <log+0x1c>
    80004550:	37fd                	addw	a5,a5,-1
    80004552:	04f65e63          	bge	a2,a5,800045ae <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004556:	0001d797          	auipc	a5,0x1d
    8000455a:	a4a7a783          	lw	a5,-1462(a5) # 80020fa0 <log+0x20>
    8000455e:	06f05063          	blez	a5,800045be <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004562:	4781                	li	a5,0
    80004564:	06c05563          	blez	a2,800045ce <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004568:	44cc                	lw	a1,12(s1)
    8000456a:	0001d717          	auipc	a4,0x1d
    8000456e:	a4670713          	add	a4,a4,-1466 # 80020fb0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004572:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004574:	4314                	lw	a3,0(a4)
    80004576:	04b68c63          	beq	a3,a1,800045ce <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000457a:	2785                	addw	a5,a5,1
    8000457c:	0711                	add	a4,a4,4
    8000457e:	fef61be3          	bne	a2,a5,80004574 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004582:	0621                	add	a2,a2,8
    80004584:	060a                	sll	a2,a2,0x2
    80004586:	0001d797          	auipc	a5,0x1d
    8000458a:	9fa78793          	add	a5,a5,-1542 # 80020f80 <log>
    8000458e:	97b2                	add	a5,a5,a2
    80004590:	44d8                	lw	a4,12(s1)
    80004592:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004594:	8526                	mv	a0,s1
    80004596:	fffff097          	auipc	ra,0xfffff
    8000459a:	dcc080e7          	jalr	-564(ra) # 80003362 <bpin>
    log.lh.n++;
    8000459e:	0001d717          	auipc	a4,0x1d
    800045a2:	9e270713          	add	a4,a4,-1566 # 80020f80 <log>
    800045a6:	575c                	lw	a5,44(a4)
    800045a8:	2785                	addw	a5,a5,1
    800045aa:	d75c                	sw	a5,44(a4)
    800045ac:	a82d                	j	800045e6 <log_write+0xc8>
    panic("too big a transaction");
    800045ae:	00004517          	auipc	a0,0x4
    800045b2:	11250513          	add	a0,a0,274 # 800086c0 <syscalls+0x208>
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	f86080e7          	jalr	-122(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    800045be:	00004517          	auipc	a0,0x4
    800045c2:	11a50513          	add	a0,a0,282 # 800086d8 <syscalls+0x220>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	f76080e7          	jalr	-138(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800045ce:	00878693          	add	a3,a5,8
    800045d2:	068a                	sll	a3,a3,0x2
    800045d4:	0001d717          	auipc	a4,0x1d
    800045d8:	9ac70713          	add	a4,a4,-1620 # 80020f80 <log>
    800045dc:	9736                	add	a4,a4,a3
    800045de:	44d4                	lw	a3,12(s1)
    800045e0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045e2:	faf609e3          	beq	a2,a5,80004594 <log_write+0x76>
  }
  release(&log.lock);
    800045e6:	0001d517          	auipc	a0,0x1d
    800045ea:	99a50513          	add	a0,a0,-1638 # 80020f80 <log>
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	698080e7          	jalr	1688(ra) # 80000c86 <release>
}
    800045f6:	60e2                	ld	ra,24(sp)
    800045f8:	6442                	ld	s0,16(sp)
    800045fa:	64a2                	ld	s1,8(sp)
    800045fc:	6902                	ld	s2,0(sp)
    800045fe:	6105                	add	sp,sp,32
    80004600:	8082                	ret

0000000080004602 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004602:	1101                	add	sp,sp,-32
    80004604:	ec06                	sd	ra,24(sp)
    80004606:	e822                	sd	s0,16(sp)
    80004608:	e426                	sd	s1,8(sp)
    8000460a:	e04a                	sd	s2,0(sp)
    8000460c:	1000                	add	s0,sp,32
    8000460e:	84aa                	mv	s1,a0
    80004610:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004612:	00004597          	auipc	a1,0x4
    80004616:	0e658593          	add	a1,a1,230 # 800086f8 <syscalls+0x240>
    8000461a:	0521                	add	a0,a0,8
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	526080e7          	jalr	1318(ra) # 80000b42 <initlock>
  lk->name = name;
    80004624:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004628:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000462c:	0204a423          	sw	zero,40(s1)
}
    80004630:	60e2                	ld	ra,24(sp)
    80004632:	6442                	ld	s0,16(sp)
    80004634:	64a2                	ld	s1,8(sp)
    80004636:	6902                	ld	s2,0(sp)
    80004638:	6105                	add	sp,sp,32
    8000463a:	8082                	ret

000000008000463c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000463c:	1101                	add	sp,sp,-32
    8000463e:	ec06                	sd	ra,24(sp)
    80004640:	e822                	sd	s0,16(sp)
    80004642:	e426                	sd	s1,8(sp)
    80004644:	e04a                	sd	s2,0(sp)
    80004646:	1000                	add	s0,sp,32
    80004648:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000464a:	00850913          	add	s2,a0,8
    8000464e:	854a                	mv	a0,s2
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	582080e7          	jalr	1410(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004658:	409c                	lw	a5,0(s1)
    8000465a:	cb89                	beqz	a5,8000466c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000465c:	85ca                	mv	a1,s2
    8000465e:	8526                	mv	a0,s1
    80004660:	ffffe097          	auipc	ra,0xffffe
    80004664:	a9a080e7          	jalr	-1382(ra) # 800020fa <sleep>
  while (lk->locked) {
    80004668:	409c                	lw	a5,0(s1)
    8000466a:	fbed                	bnez	a5,8000465c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000466c:	4785                	li	a5,1
    8000466e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004670:	ffffd097          	auipc	ra,0xffffd
    80004674:	336080e7          	jalr	822(ra) # 800019a6 <myproc>
    80004678:	591c                	lw	a5,48(a0)
    8000467a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000467c:	854a                	mv	a0,s2
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	608080e7          	jalr	1544(ra) # 80000c86 <release>
}
    80004686:	60e2                	ld	ra,24(sp)
    80004688:	6442                	ld	s0,16(sp)
    8000468a:	64a2                	ld	s1,8(sp)
    8000468c:	6902                	ld	s2,0(sp)
    8000468e:	6105                	add	sp,sp,32
    80004690:	8082                	ret

0000000080004692 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004692:	1101                	add	sp,sp,-32
    80004694:	ec06                	sd	ra,24(sp)
    80004696:	e822                	sd	s0,16(sp)
    80004698:	e426                	sd	s1,8(sp)
    8000469a:	e04a                	sd	s2,0(sp)
    8000469c:	1000                	add	s0,sp,32
    8000469e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046a0:	00850913          	add	s2,a0,8
    800046a4:	854a                	mv	a0,s2
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	52c080e7          	jalr	1324(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    800046ae:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046b2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046b6:	8526                	mv	a0,s1
    800046b8:	ffffe097          	auipc	ra,0xffffe
    800046bc:	aa6080e7          	jalr	-1370(ra) # 8000215e <wakeup>
  release(&lk->lk);
    800046c0:	854a                	mv	a0,s2
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	5c4080e7          	jalr	1476(ra) # 80000c86 <release>
}
    800046ca:	60e2                	ld	ra,24(sp)
    800046cc:	6442                	ld	s0,16(sp)
    800046ce:	64a2                	ld	s1,8(sp)
    800046d0:	6902                	ld	s2,0(sp)
    800046d2:	6105                	add	sp,sp,32
    800046d4:	8082                	ret

00000000800046d6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046d6:	7179                	add	sp,sp,-48
    800046d8:	f406                	sd	ra,40(sp)
    800046da:	f022                	sd	s0,32(sp)
    800046dc:	ec26                	sd	s1,24(sp)
    800046de:	e84a                	sd	s2,16(sp)
    800046e0:	e44e                	sd	s3,8(sp)
    800046e2:	1800                	add	s0,sp,48
    800046e4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046e6:	00850913          	add	s2,a0,8
    800046ea:	854a                	mv	a0,s2
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	4e6080e7          	jalr	1254(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046f4:	409c                	lw	a5,0(s1)
    800046f6:	ef99                	bnez	a5,80004714 <holdingsleep+0x3e>
    800046f8:	4481                	li	s1,0
  release(&lk->lk);
    800046fa:	854a                	mv	a0,s2
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	58a080e7          	jalr	1418(ra) # 80000c86 <release>
  return r;
}
    80004704:	8526                	mv	a0,s1
    80004706:	70a2                	ld	ra,40(sp)
    80004708:	7402                	ld	s0,32(sp)
    8000470a:	64e2                	ld	s1,24(sp)
    8000470c:	6942                	ld	s2,16(sp)
    8000470e:	69a2                	ld	s3,8(sp)
    80004710:	6145                	add	sp,sp,48
    80004712:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004714:	0284a983          	lw	s3,40(s1)
    80004718:	ffffd097          	auipc	ra,0xffffd
    8000471c:	28e080e7          	jalr	654(ra) # 800019a6 <myproc>
    80004720:	5904                	lw	s1,48(a0)
    80004722:	413484b3          	sub	s1,s1,s3
    80004726:	0014b493          	seqz	s1,s1
    8000472a:	bfc1                	j	800046fa <holdingsleep+0x24>

000000008000472c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000472c:	1141                	add	sp,sp,-16
    8000472e:	e406                	sd	ra,8(sp)
    80004730:	e022                	sd	s0,0(sp)
    80004732:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004734:	00004597          	auipc	a1,0x4
    80004738:	fd458593          	add	a1,a1,-44 # 80008708 <syscalls+0x250>
    8000473c:	0001d517          	auipc	a0,0x1d
    80004740:	98c50513          	add	a0,a0,-1652 # 800210c8 <ftable>
    80004744:	ffffc097          	auipc	ra,0xffffc
    80004748:	3fe080e7          	jalr	1022(ra) # 80000b42 <initlock>
}
    8000474c:	60a2                	ld	ra,8(sp)
    8000474e:	6402                	ld	s0,0(sp)
    80004750:	0141                	add	sp,sp,16
    80004752:	8082                	ret

0000000080004754 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004754:	1101                	add	sp,sp,-32
    80004756:	ec06                	sd	ra,24(sp)
    80004758:	e822                	sd	s0,16(sp)
    8000475a:	e426                	sd	s1,8(sp)
    8000475c:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000475e:	0001d517          	auipc	a0,0x1d
    80004762:	96a50513          	add	a0,a0,-1686 # 800210c8 <ftable>
    80004766:	ffffc097          	auipc	ra,0xffffc
    8000476a:	46c080e7          	jalr	1132(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000476e:	0001d497          	auipc	s1,0x1d
    80004772:	97248493          	add	s1,s1,-1678 # 800210e0 <ftable+0x18>
    80004776:	0001e717          	auipc	a4,0x1e
    8000477a:	90a70713          	add	a4,a4,-1782 # 80022080 <disk>
    if(f->ref == 0){
    8000477e:	40dc                	lw	a5,4(s1)
    80004780:	cf99                	beqz	a5,8000479e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004782:	02848493          	add	s1,s1,40
    80004786:	fee49ce3          	bne	s1,a4,8000477e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000478a:	0001d517          	auipc	a0,0x1d
    8000478e:	93e50513          	add	a0,a0,-1730 # 800210c8 <ftable>
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	4f4080e7          	jalr	1268(ra) # 80000c86 <release>
  return 0;
    8000479a:	4481                	li	s1,0
    8000479c:	a819                	j	800047b2 <filealloc+0x5e>
      f->ref = 1;
    8000479e:	4785                	li	a5,1
    800047a0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047a2:	0001d517          	auipc	a0,0x1d
    800047a6:	92650513          	add	a0,a0,-1754 # 800210c8 <ftable>
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	4dc080e7          	jalr	1244(ra) # 80000c86 <release>
}
    800047b2:	8526                	mv	a0,s1
    800047b4:	60e2                	ld	ra,24(sp)
    800047b6:	6442                	ld	s0,16(sp)
    800047b8:	64a2                	ld	s1,8(sp)
    800047ba:	6105                	add	sp,sp,32
    800047bc:	8082                	ret

00000000800047be <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047be:	1101                	add	sp,sp,-32
    800047c0:	ec06                	sd	ra,24(sp)
    800047c2:	e822                	sd	s0,16(sp)
    800047c4:	e426                	sd	s1,8(sp)
    800047c6:	1000                	add	s0,sp,32
    800047c8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047ca:	0001d517          	auipc	a0,0x1d
    800047ce:	8fe50513          	add	a0,a0,-1794 # 800210c8 <ftable>
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	400080e7          	jalr	1024(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800047da:	40dc                	lw	a5,4(s1)
    800047dc:	02f05263          	blez	a5,80004800 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047e0:	2785                	addw	a5,a5,1
    800047e2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047e4:	0001d517          	auipc	a0,0x1d
    800047e8:	8e450513          	add	a0,a0,-1820 # 800210c8 <ftable>
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	49a080e7          	jalr	1178(ra) # 80000c86 <release>
  return f;
}
    800047f4:	8526                	mv	a0,s1
    800047f6:	60e2                	ld	ra,24(sp)
    800047f8:	6442                	ld	s0,16(sp)
    800047fa:	64a2                	ld	s1,8(sp)
    800047fc:	6105                	add	sp,sp,32
    800047fe:	8082                	ret
    panic("filedup");
    80004800:	00004517          	auipc	a0,0x4
    80004804:	f1050513          	add	a0,a0,-240 # 80008710 <syscalls+0x258>
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	d34080e7          	jalr	-716(ra) # 8000053c <panic>

0000000080004810 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004810:	7139                	add	sp,sp,-64
    80004812:	fc06                	sd	ra,56(sp)
    80004814:	f822                	sd	s0,48(sp)
    80004816:	f426                	sd	s1,40(sp)
    80004818:	f04a                	sd	s2,32(sp)
    8000481a:	ec4e                	sd	s3,24(sp)
    8000481c:	e852                	sd	s4,16(sp)
    8000481e:	e456                	sd	s5,8(sp)
    80004820:	0080                	add	s0,sp,64
    80004822:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004824:	0001d517          	auipc	a0,0x1d
    80004828:	8a450513          	add	a0,a0,-1884 # 800210c8 <ftable>
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	3a6080e7          	jalr	934(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004834:	40dc                	lw	a5,4(s1)
    80004836:	06f05163          	blez	a5,80004898 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000483a:	37fd                	addw	a5,a5,-1
    8000483c:	0007871b          	sext.w	a4,a5
    80004840:	c0dc                	sw	a5,4(s1)
    80004842:	06e04363          	bgtz	a4,800048a8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004846:	0004a903          	lw	s2,0(s1)
    8000484a:	0094ca83          	lbu	s5,9(s1)
    8000484e:	0104ba03          	ld	s4,16(s1)
    80004852:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004856:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000485a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000485e:	0001d517          	auipc	a0,0x1d
    80004862:	86a50513          	add	a0,a0,-1942 # 800210c8 <ftable>
    80004866:	ffffc097          	auipc	ra,0xffffc
    8000486a:	420080e7          	jalr	1056(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    8000486e:	4785                	li	a5,1
    80004870:	04f90d63          	beq	s2,a5,800048ca <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004874:	3979                	addw	s2,s2,-2
    80004876:	4785                	li	a5,1
    80004878:	0527e063          	bltu	a5,s2,800048b8 <fileclose+0xa8>
    begin_op();
    8000487c:	00000097          	auipc	ra,0x0
    80004880:	ad0080e7          	jalr	-1328(ra) # 8000434c <begin_op>
    iput(ff.ip);
    80004884:	854e                	mv	a0,s3
    80004886:	fffff097          	auipc	ra,0xfffff
    8000488a:	2da080e7          	jalr	730(ra) # 80003b60 <iput>
    end_op();
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	b38080e7          	jalr	-1224(ra) # 800043c6 <end_op>
    80004896:	a00d                	j	800048b8 <fileclose+0xa8>
    panic("fileclose");
    80004898:	00004517          	auipc	a0,0x4
    8000489c:	e8050513          	add	a0,a0,-384 # 80008718 <syscalls+0x260>
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	c9c080e7          	jalr	-868(ra) # 8000053c <panic>
    release(&ftable.lock);
    800048a8:	0001d517          	auipc	a0,0x1d
    800048ac:	82050513          	add	a0,a0,-2016 # 800210c8 <ftable>
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	3d6080e7          	jalr	982(ra) # 80000c86 <release>
  }
}
    800048b8:	70e2                	ld	ra,56(sp)
    800048ba:	7442                	ld	s0,48(sp)
    800048bc:	74a2                	ld	s1,40(sp)
    800048be:	7902                	ld	s2,32(sp)
    800048c0:	69e2                	ld	s3,24(sp)
    800048c2:	6a42                	ld	s4,16(sp)
    800048c4:	6aa2                	ld	s5,8(sp)
    800048c6:	6121                	add	sp,sp,64
    800048c8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048ca:	85d6                	mv	a1,s5
    800048cc:	8552                	mv	a0,s4
    800048ce:	00000097          	auipc	ra,0x0
    800048d2:	348080e7          	jalr	840(ra) # 80004c16 <pipeclose>
    800048d6:	b7cd                	j	800048b8 <fileclose+0xa8>

00000000800048d8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048d8:	715d                	add	sp,sp,-80
    800048da:	e486                	sd	ra,72(sp)
    800048dc:	e0a2                	sd	s0,64(sp)
    800048de:	fc26                	sd	s1,56(sp)
    800048e0:	f84a                	sd	s2,48(sp)
    800048e2:	f44e                	sd	s3,40(sp)
    800048e4:	0880                	add	s0,sp,80
    800048e6:	84aa                	mv	s1,a0
    800048e8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048ea:	ffffd097          	auipc	ra,0xffffd
    800048ee:	0bc080e7          	jalr	188(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048f2:	409c                	lw	a5,0(s1)
    800048f4:	37f9                	addw	a5,a5,-2
    800048f6:	4705                	li	a4,1
    800048f8:	04f76763          	bltu	a4,a5,80004946 <filestat+0x6e>
    800048fc:	892a                	mv	s2,a0
    ilock(f->ip);
    800048fe:	6c88                	ld	a0,24(s1)
    80004900:	fffff097          	auipc	ra,0xfffff
    80004904:	0a6080e7          	jalr	166(ra) # 800039a6 <ilock>
    stati(f->ip, &st);
    80004908:	fb840593          	add	a1,s0,-72
    8000490c:	6c88                	ld	a0,24(s1)
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	322080e7          	jalr	802(ra) # 80003c30 <stati>
    iunlock(f->ip);
    80004916:	6c88                	ld	a0,24(s1)
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	150080e7          	jalr	336(ra) # 80003a68 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004920:	46e1                	li	a3,24
    80004922:	fb840613          	add	a2,s0,-72
    80004926:	85ce                	mv	a1,s3
    80004928:	05093503          	ld	a0,80(s2)
    8000492c:	ffffd097          	auipc	ra,0xffffd
    80004930:	d3a080e7          	jalr	-710(ra) # 80001666 <copyout>
    80004934:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004938:	60a6                	ld	ra,72(sp)
    8000493a:	6406                	ld	s0,64(sp)
    8000493c:	74e2                	ld	s1,56(sp)
    8000493e:	7942                	ld	s2,48(sp)
    80004940:	79a2                	ld	s3,40(sp)
    80004942:	6161                	add	sp,sp,80
    80004944:	8082                	ret
  return -1;
    80004946:	557d                	li	a0,-1
    80004948:	bfc5                	j	80004938 <filestat+0x60>

000000008000494a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000494a:	7179                	add	sp,sp,-48
    8000494c:	f406                	sd	ra,40(sp)
    8000494e:	f022                	sd	s0,32(sp)
    80004950:	ec26                	sd	s1,24(sp)
    80004952:	e84a                	sd	s2,16(sp)
    80004954:	e44e                	sd	s3,8(sp)
    80004956:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004958:	00854783          	lbu	a5,8(a0)
    8000495c:	c3d5                	beqz	a5,80004a00 <fileread+0xb6>
    8000495e:	84aa                	mv	s1,a0
    80004960:	89ae                	mv	s3,a1
    80004962:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004964:	411c                	lw	a5,0(a0)
    80004966:	4705                	li	a4,1
    80004968:	04e78963          	beq	a5,a4,800049ba <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000496c:	470d                	li	a4,3
    8000496e:	04e78d63          	beq	a5,a4,800049c8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004972:	4709                	li	a4,2
    80004974:	06e79e63          	bne	a5,a4,800049f0 <fileread+0xa6>
    ilock(f->ip);
    80004978:	6d08                	ld	a0,24(a0)
    8000497a:	fffff097          	auipc	ra,0xfffff
    8000497e:	02c080e7          	jalr	44(ra) # 800039a6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004982:	874a                	mv	a4,s2
    80004984:	5094                	lw	a3,32(s1)
    80004986:	864e                	mv	a2,s3
    80004988:	4585                	li	a1,1
    8000498a:	6c88                	ld	a0,24(s1)
    8000498c:	fffff097          	auipc	ra,0xfffff
    80004990:	2ce080e7          	jalr	718(ra) # 80003c5a <readi>
    80004994:	892a                	mv	s2,a0
    80004996:	00a05563          	blez	a0,800049a0 <fileread+0x56>
      f->off += r;
    8000499a:	509c                	lw	a5,32(s1)
    8000499c:	9fa9                	addw	a5,a5,a0
    8000499e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049a0:	6c88                	ld	a0,24(s1)
    800049a2:	fffff097          	auipc	ra,0xfffff
    800049a6:	0c6080e7          	jalr	198(ra) # 80003a68 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049aa:	854a                	mv	a0,s2
    800049ac:	70a2                	ld	ra,40(sp)
    800049ae:	7402                	ld	s0,32(sp)
    800049b0:	64e2                	ld	s1,24(sp)
    800049b2:	6942                	ld	s2,16(sp)
    800049b4:	69a2                	ld	s3,8(sp)
    800049b6:	6145                	add	sp,sp,48
    800049b8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049ba:	6908                	ld	a0,16(a0)
    800049bc:	00000097          	auipc	ra,0x0
    800049c0:	3c2080e7          	jalr	962(ra) # 80004d7e <piperead>
    800049c4:	892a                	mv	s2,a0
    800049c6:	b7d5                	j	800049aa <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049c8:	02451783          	lh	a5,36(a0)
    800049cc:	03079693          	sll	a3,a5,0x30
    800049d0:	92c1                	srl	a3,a3,0x30
    800049d2:	4725                	li	a4,9
    800049d4:	02d76863          	bltu	a4,a3,80004a04 <fileread+0xba>
    800049d8:	0792                	sll	a5,a5,0x4
    800049da:	0001c717          	auipc	a4,0x1c
    800049de:	64e70713          	add	a4,a4,1614 # 80021028 <devsw>
    800049e2:	97ba                	add	a5,a5,a4
    800049e4:	639c                	ld	a5,0(a5)
    800049e6:	c38d                	beqz	a5,80004a08 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049e8:	4505                	li	a0,1
    800049ea:	9782                	jalr	a5
    800049ec:	892a                	mv	s2,a0
    800049ee:	bf75                	j	800049aa <fileread+0x60>
    panic("fileread");
    800049f0:	00004517          	auipc	a0,0x4
    800049f4:	d3850513          	add	a0,a0,-712 # 80008728 <syscalls+0x270>
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	b44080e7          	jalr	-1212(ra) # 8000053c <panic>
    return -1;
    80004a00:	597d                	li	s2,-1
    80004a02:	b765                	j	800049aa <fileread+0x60>
      return -1;
    80004a04:	597d                	li	s2,-1
    80004a06:	b755                	j	800049aa <fileread+0x60>
    80004a08:	597d                	li	s2,-1
    80004a0a:	b745                	j	800049aa <fileread+0x60>

0000000080004a0c <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a0c:	00954783          	lbu	a5,9(a0)
    80004a10:	10078e63          	beqz	a5,80004b2c <filewrite+0x120>
{
    80004a14:	715d                	add	sp,sp,-80
    80004a16:	e486                	sd	ra,72(sp)
    80004a18:	e0a2                	sd	s0,64(sp)
    80004a1a:	fc26                	sd	s1,56(sp)
    80004a1c:	f84a                	sd	s2,48(sp)
    80004a1e:	f44e                	sd	s3,40(sp)
    80004a20:	f052                	sd	s4,32(sp)
    80004a22:	ec56                	sd	s5,24(sp)
    80004a24:	e85a                	sd	s6,16(sp)
    80004a26:	e45e                	sd	s7,8(sp)
    80004a28:	e062                	sd	s8,0(sp)
    80004a2a:	0880                	add	s0,sp,80
    80004a2c:	892a                	mv	s2,a0
    80004a2e:	8b2e                	mv	s6,a1
    80004a30:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a32:	411c                	lw	a5,0(a0)
    80004a34:	4705                	li	a4,1
    80004a36:	02e78263          	beq	a5,a4,80004a5a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a3a:	470d                	li	a4,3
    80004a3c:	02e78563          	beq	a5,a4,80004a66 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a40:	4709                	li	a4,2
    80004a42:	0ce79d63          	bne	a5,a4,80004b1c <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a46:	0ac05b63          	blez	a2,80004afc <filewrite+0xf0>
    int i = 0;
    80004a4a:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004a4c:	6b85                	lui	s7,0x1
    80004a4e:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004a52:	6c05                	lui	s8,0x1
    80004a54:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004a58:	a851                	j	80004aec <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a5a:	6908                	ld	a0,16(a0)
    80004a5c:	00000097          	auipc	ra,0x0
    80004a60:	22a080e7          	jalr	554(ra) # 80004c86 <pipewrite>
    80004a64:	a045                	j	80004b04 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a66:	02451783          	lh	a5,36(a0)
    80004a6a:	03079693          	sll	a3,a5,0x30
    80004a6e:	92c1                	srl	a3,a3,0x30
    80004a70:	4725                	li	a4,9
    80004a72:	0ad76f63          	bltu	a4,a3,80004b30 <filewrite+0x124>
    80004a76:	0792                	sll	a5,a5,0x4
    80004a78:	0001c717          	auipc	a4,0x1c
    80004a7c:	5b070713          	add	a4,a4,1456 # 80021028 <devsw>
    80004a80:	97ba                	add	a5,a5,a4
    80004a82:	679c                	ld	a5,8(a5)
    80004a84:	cbc5                	beqz	a5,80004b34 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004a86:	4505                	li	a0,1
    80004a88:	9782                	jalr	a5
    80004a8a:	a8ad                	j	80004b04 <filewrite+0xf8>
      if(n1 > max)
    80004a8c:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004a90:	00000097          	auipc	ra,0x0
    80004a94:	8bc080e7          	jalr	-1860(ra) # 8000434c <begin_op>
      ilock(f->ip);
    80004a98:	01893503          	ld	a0,24(s2)
    80004a9c:	fffff097          	auipc	ra,0xfffff
    80004aa0:	f0a080e7          	jalr	-246(ra) # 800039a6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aa4:	8756                	mv	a4,s5
    80004aa6:	02092683          	lw	a3,32(s2)
    80004aaa:	01698633          	add	a2,s3,s6
    80004aae:	4585                	li	a1,1
    80004ab0:	01893503          	ld	a0,24(s2)
    80004ab4:	fffff097          	auipc	ra,0xfffff
    80004ab8:	29e080e7          	jalr	670(ra) # 80003d52 <writei>
    80004abc:	84aa                	mv	s1,a0
    80004abe:	00a05763          	blez	a0,80004acc <filewrite+0xc0>
        f->off += r;
    80004ac2:	02092783          	lw	a5,32(s2)
    80004ac6:	9fa9                	addw	a5,a5,a0
    80004ac8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004acc:	01893503          	ld	a0,24(s2)
    80004ad0:	fffff097          	auipc	ra,0xfffff
    80004ad4:	f98080e7          	jalr	-104(ra) # 80003a68 <iunlock>
      end_op();
    80004ad8:	00000097          	auipc	ra,0x0
    80004adc:	8ee080e7          	jalr	-1810(ra) # 800043c6 <end_op>

      if(r != n1){
    80004ae0:	009a9f63          	bne	s5,s1,80004afe <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004ae4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ae8:	0149db63          	bge	s3,s4,80004afe <filewrite+0xf2>
      int n1 = n - i;
    80004aec:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004af0:	0004879b          	sext.w	a5,s1
    80004af4:	f8fbdce3          	bge	s7,a5,80004a8c <filewrite+0x80>
    80004af8:	84e2                	mv	s1,s8
    80004afa:	bf49                	j	80004a8c <filewrite+0x80>
    int i = 0;
    80004afc:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004afe:	033a1d63          	bne	s4,s3,80004b38 <filewrite+0x12c>
    80004b02:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b04:	60a6                	ld	ra,72(sp)
    80004b06:	6406                	ld	s0,64(sp)
    80004b08:	74e2                	ld	s1,56(sp)
    80004b0a:	7942                	ld	s2,48(sp)
    80004b0c:	79a2                	ld	s3,40(sp)
    80004b0e:	7a02                	ld	s4,32(sp)
    80004b10:	6ae2                	ld	s5,24(sp)
    80004b12:	6b42                	ld	s6,16(sp)
    80004b14:	6ba2                	ld	s7,8(sp)
    80004b16:	6c02                	ld	s8,0(sp)
    80004b18:	6161                	add	sp,sp,80
    80004b1a:	8082                	ret
    panic("filewrite");
    80004b1c:	00004517          	auipc	a0,0x4
    80004b20:	c1c50513          	add	a0,a0,-996 # 80008738 <syscalls+0x280>
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	a18080e7          	jalr	-1512(ra) # 8000053c <panic>
    return -1;
    80004b2c:	557d                	li	a0,-1
}
    80004b2e:	8082                	ret
      return -1;
    80004b30:	557d                	li	a0,-1
    80004b32:	bfc9                	j	80004b04 <filewrite+0xf8>
    80004b34:	557d                	li	a0,-1
    80004b36:	b7f9                	j	80004b04 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004b38:	557d                	li	a0,-1
    80004b3a:	b7e9                	j	80004b04 <filewrite+0xf8>

0000000080004b3c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b3c:	7179                	add	sp,sp,-48
    80004b3e:	f406                	sd	ra,40(sp)
    80004b40:	f022                	sd	s0,32(sp)
    80004b42:	ec26                	sd	s1,24(sp)
    80004b44:	e84a                	sd	s2,16(sp)
    80004b46:	e44e                	sd	s3,8(sp)
    80004b48:	e052                	sd	s4,0(sp)
    80004b4a:	1800                	add	s0,sp,48
    80004b4c:	84aa                	mv	s1,a0
    80004b4e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b50:	0005b023          	sd	zero,0(a1)
    80004b54:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b58:	00000097          	auipc	ra,0x0
    80004b5c:	bfc080e7          	jalr	-1028(ra) # 80004754 <filealloc>
    80004b60:	e088                	sd	a0,0(s1)
    80004b62:	c551                	beqz	a0,80004bee <pipealloc+0xb2>
    80004b64:	00000097          	auipc	ra,0x0
    80004b68:	bf0080e7          	jalr	-1040(ra) # 80004754 <filealloc>
    80004b6c:	00aa3023          	sd	a0,0(s4)
    80004b70:	c92d                	beqz	a0,80004be2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b72:	ffffc097          	auipc	ra,0xffffc
    80004b76:	f70080e7          	jalr	-144(ra) # 80000ae2 <kalloc>
    80004b7a:	892a                	mv	s2,a0
    80004b7c:	c125                	beqz	a0,80004bdc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b7e:	4985                	li	s3,1
    80004b80:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b84:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b88:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b8c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b90:	00004597          	auipc	a1,0x4
    80004b94:	bb858593          	add	a1,a1,-1096 # 80008748 <syscalls+0x290>
    80004b98:	ffffc097          	auipc	ra,0xffffc
    80004b9c:	faa080e7          	jalr	-86(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004ba0:	609c                	ld	a5,0(s1)
    80004ba2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ba6:	609c                	ld	a5,0(s1)
    80004ba8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bac:	609c                	ld	a5,0(s1)
    80004bae:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bb2:	609c                	ld	a5,0(s1)
    80004bb4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bb8:	000a3783          	ld	a5,0(s4)
    80004bbc:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bc0:	000a3783          	ld	a5,0(s4)
    80004bc4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bc8:	000a3783          	ld	a5,0(s4)
    80004bcc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bd0:	000a3783          	ld	a5,0(s4)
    80004bd4:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bd8:	4501                	li	a0,0
    80004bda:	a025                	j	80004c02 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bdc:	6088                	ld	a0,0(s1)
    80004bde:	e501                	bnez	a0,80004be6 <pipealloc+0xaa>
    80004be0:	a039                	j	80004bee <pipealloc+0xb2>
    80004be2:	6088                	ld	a0,0(s1)
    80004be4:	c51d                	beqz	a0,80004c12 <pipealloc+0xd6>
    fileclose(*f0);
    80004be6:	00000097          	auipc	ra,0x0
    80004bea:	c2a080e7          	jalr	-982(ra) # 80004810 <fileclose>
  if(*f1)
    80004bee:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bf2:	557d                	li	a0,-1
  if(*f1)
    80004bf4:	c799                	beqz	a5,80004c02 <pipealloc+0xc6>
    fileclose(*f1);
    80004bf6:	853e                	mv	a0,a5
    80004bf8:	00000097          	auipc	ra,0x0
    80004bfc:	c18080e7          	jalr	-1000(ra) # 80004810 <fileclose>
  return -1;
    80004c00:	557d                	li	a0,-1
}
    80004c02:	70a2                	ld	ra,40(sp)
    80004c04:	7402                	ld	s0,32(sp)
    80004c06:	64e2                	ld	s1,24(sp)
    80004c08:	6942                	ld	s2,16(sp)
    80004c0a:	69a2                	ld	s3,8(sp)
    80004c0c:	6a02                	ld	s4,0(sp)
    80004c0e:	6145                	add	sp,sp,48
    80004c10:	8082                	ret
  return -1;
    80004c12:	557d                	li	a0,-1
    80004c14:	b7fd                	j	80004c02 <pipealloc+0xc6>

0000000080004c16 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c16:	1101                	add	sp,sp,-32
    80004c18:	ec06                	sd	ra,24(sp)
    80004c1a:	e822                	sd	s0,16(sp)
    80004c1c:	e426                	sd	s1,8(sp)
    80004c1e:	e04a                	sd	s2,0(sp)
    80004c20:	1000                	add	s0,sp,32
    80004c22:	84aa                	mv	s1,a0
    80004c24:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c26:	ffffc097          	auipc	ra,0xffffc
    80004c2a:	fac080e7          	jalr	-84(ra) # 80000bd2 <acquire>
  if(writable){
    80004c2e:	02090d63          	beqz	s2,80004c68 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c32:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c36:	21848513          	add	a0,s1,536
    80004c3a:	ffffd097          	auipc	ra,0xffffd
    80004c3e:	524080e7          	jalr	1316(ra) # 8000215e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c42:	2204b783          	ld	a5,544(s1)
    80004c46:	eb95                	bnez	a5,80004c7a <pipeclose+0x64>
    release(&pi->lock);
    80004c48:	8526                	mv	a0,s1
    80004c4a:	ffffc097          	auipc	ra,0xffffc
    80004c4e:	03c080e7          	jalr	60(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004c52:	8526                	mv	a0,s1
    80004c54:	ffffc097          	auipc	ra,0xffffc
    80004c58:	d90080e7          	jalr	-624(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004c5c:	60e2                	ld	ra,24(sp)
    80004c5e:	6442                	ld	s0,16(sp)
    80004c60:	64a2                	ld	s1,8(sp)
    80004c62:	6902                	ld	s2,0(sp)
    80004c64:	6105                	add	sp,sp,32
    80004c66:	8082                	ret
    pi->readopen = 0;
    80004c68:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c6c:	21c48513          	add	a0,s1,540
    80004c70:	ffffd097          	auipc	ra,0xffffd
    80004c74:	4ee080e7          	jalr	1262(ra) # 8000215e <wakeup>
    80004c78:	b7e9                	j	80004c42 <pipeclose+0x2c>
    release(&pi->lock);
    80004c7a:	8526                	mv	a0,s1
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	00a080e7          	jalr	10(ra) # 80000c86 <release>
}
    80004c84:	bfe1                	j	80004c5c <pipeclose+0x46>

0000000080004c86 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c86:	711d                	add	sp,sp,-96
    80004c88:	ec86                	sd	ra,88(sp)
    80004c8a:	e8a2                	sd	s0,80(sp)
    80004c8c:	e4a6                	sd	s1,72(sp)
    80004c8e:	e0ca                	sd	s2,64(sp)
    80004c90:	fc4e                	sd	s3,56(sp)
    80004c92:	f852                	sd	s4,48(sp)
    80004c94:	f456                	sd	s5,40(sp)
    80004c96:	f05a                	sd	s6,32(sp)
    80004c98:	ec5e                	sd	s7,24(sp)
    80004c9a:	e862                	sd	s8,16(sp)
    80004c9c:	1080                	add	s0,sp,96
    80004c9e:	84aa                	mv	s1,a0
    80004ca0:	8aae                	mv	s5,a1
    80004ca2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ca4:	ffffd097          	auipc	ra,0xffffd
    80004ca8:	d02080e7          	jalr	-766(ra) # 800019a6 <myproc>
    80004cac:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cae:	8526                	mv	a0,s1
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	f22080e7          	jalr	-222(ra) # 80000bd2 <acquire>
  while(i < n){
    80004cb8:	0b405663          	blez	s4,80004d64 <pipewrite+0xde>
  int i = 0;
    80004cbc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cbe:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004cc0:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cc4:	21c48b93          	add	s7,s1,540
    80004cc8:	a089                	j	80004d0a <pipewrite+0x84>
      release(&pi->lock);
    80004cca:	8526                	mv	a0,s1
    80004ccc:	ffffc097          	auipc	ra,0xffffc
    80004cd0:	fba080e7          	jalr	-70(ra) # 80000c86 <release>
      return -1;
    80004cd4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cd6:	854a                	mv	a0,s2
    80004cd8:	60e6                	ld	ra,88(sp)
    80004cda:	6446                	ld	s0,80(sp)
    80004cdc:	64a6                	ld	s1,72(sp)
    80004cde:	6906                	ld	s2,64(sp)
    80004ce0:	79e2                	ld	s3,56(sp)
    80004ce2:	7a42                	ld	s4,48(sp)
    80004ce4:	7aa2                	ld	s5,40(sp)
    80004ce6:	7b02                	ld	s6,32(sp)
    80004ce8:	6be2                	ld	s7,24(sp)
    80004cea:	6c42                	ld	s8,16(sp)
    80004cec:	6125                	add	sp,sp,96
    80004cee:	8082                	ret
      wakeup(&pi->nread);
    80004cf0:	8562                	mv	a0,s8
    80004cf2:	ffffd097          	auipc	ra,0xffffd
    80004cf6:	46c080e7          	jalr	1132(ra) # 8000215e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cfa:	85a6                	mv	a1,s1
    80004cfc:	855e                	mv	a0,s7
    80004cfe:	ffffd097          	auipc	ra,0xffffd
    80004d02:	3fc080e7          	jalr	1020(ra) # 800020fa <sleep>
  while(i < n){
    80004d06:	07495063          	bge	s2,s4,80004d66 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004d0a:	2204a783          	lw	a5,544(s1)
    80004d0e:	dfd5                	beqz	a5,80004cca <pipewrite+0x44>
    80004d10:	854e                	mv	a0,s3
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	690080e7          	jalr	1680(ra) # 800023a2 <killed>
    80004d1a:	f945                	bnez	a0,80004cca <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d1c:	2184a783          	lw	a5,536(s1)
    80004d20:	21c4a703          	lw	a4,540(s1)
    80004d24:	2007879b          	addw	a5,a5,512
    80004d28:	fcf704e3          	beq	a4,a5,80004cf0 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d2c:	4685                	li	a3,1
    80004d2e:	01590633          	add	a2,s2,s5
    80004d32:	faf40593          	add	a1,s0,-81
    80004d36:	0509b503          	ld	a0,80(s3)
    80004d3a:	ffffd097          	auipc	ra,0xffffd
    80004d3e:	9b8080e7          	jalr	-1608(ra) # 800016f2 <copyin>
    80004d42:	03650263          	beq	a0,s6,80004d66 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d46:	21c4a783          	lw	a5,540(s1)
    80004d4a:	0017871b          	addw	a4,a5,1
    80004d4e:	20e4ae23          	sw	a4,540(s1)
    80004d52:	1ff7f793          	and	a5,a5,511
    80004d56:	97a6                	add	a5,a5,s1
    80004d58:	faf44703          	lbu	a4,-81(s0)
    80004d5c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d60:	2905                	addw	s2,s2,1
    80004d62:	b755                	j	80004d06 <pipewrite+0x80>
  int i = 0;
    80004d64:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004d66:	21848513          	add	a0,s1,536
    80004d6a:	ffffd097          	auipc	ra,0xffffd
    80004d6e:	3f4080e7          	jalr	1012(ra) # 8000215e <wakeup>
  release(&pi->lock);
    80004d72:	8526                	mv	a0,s1
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	f12080e7          	jalr	-238(ra) # 80000c86 <release>
  return i;
    80004d7c:	bfa9                	j	80004cd6 <pipewrite+0x50>

0000000080004d7e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d7e:	715d                	add	sp,sp,-80
    80004d80:	e486                	sd	ra,72(sp)
    80004d82:	e0a2                	sd	s0,64(sp)
    80004d84:	fc26                	sd	s1,56(sp)
    80004d86:	f84a                	sd	s2,48(sp)
    80004d88:	f44e                	sd	s3,40(sp)
    80004d8a:	f052                	sd	s4,32(sp)
    80004d8c:	ec56                	sd	s5,24(sp)
    80004d8e:	e85a                	sd	s6,16(sp)
    80004d90:	0880                	add	s0,sp,80
    80004d92:	84aa                	mv	s1,a0
    80004d94:	892e                	mv	s2,a1
    80004d96:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d98:	ffffd097          	auipc	ra,0xffffd
    80004d9c:	c0e080e7          	jalr	-1010(ra) # 800019a6 <myproc>
    80004da0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004da2:	8526                	mv	a0,s1
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	e2e080e7          	jalr	-466(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dac:	2184a703          	lw	a4,536(s1)
    80004db0:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004db4:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004db8:	02f71763          	bne	a4,a5,80004de6 <piperead+0x68>
    80004dbc:	2244a783          	lw	a5,548(s1)
    80004dc0:	c39d                	beqz	a5,80004de6 <piperead+0x68>
    if(killed(pr)){
    80004dc2:	8552                	mv	a0,s4
    80004dc4:	ffffd097          	auipc	ra,0xffffd
    80004dc8:	5de080e7          	jalr	1502(ra) # 800023a2 <killed>
    80004dcc:	e949                	bnez	a0,80004e5e <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dce:	85a6                	mv	a1,s1
    80004dd0:	854e                	mv	a0,s3
    80004dd2:	ffffd097          	auipc	ra,0xffffd
    80004dd6:	328080e7          	jalr	808(ra) # 800020fa <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dda:	2184a703          	lw	a4,536(s1)
    80004dde:	21c4a783          	lw	a5,540(s1)
    80004de2:	fcf70de3          	beq	a4,a5,80004dbc <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004de6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004de8:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dea:	05505463          	blez	s5,80004e32 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004dee:	2184a783          	lw	a5,536(s1)
    80004df2:	21c4a703          	lw	a4,540(s1)
    80004df6:	02f70e63          	beq	a4,a5,80004e32 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dfa:	0017871b          	addw	a4,a5,1
    80004dfe:	20e4ac23          	sw	a4,536(s1)
    80004e02:	1ff7f793          	and	a5,a5,511
    80004e06:	97a6                	add	a5,a5,s1
    80004e08:	0187c783          	lbu	a5,24(a5)
    80004e0c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e10:	4685                	li	a3,1
    80004e12:	fbf40613          	add	a2,s0,-65
    80004e16:	85ca                	mv	a1,s2
    80004e18:	050a3503          	ld	a0,80(s4)
    80004e1c:	ffffd097          	auipc	ra,0xffffd
    80004e20:	84a080e7          	jalr	-1974(ra) # 80001666 <copyout>
    80004e24:	01650763          	beq	a0,s6,80004e32 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e28:	2985                	addw	s3,s3,1
    80004e2a:	0905                	add	s2,s2,1
    80004e2c:	fd3a91e3          	bne	s5,s3,80004dee <piperead+0x70>
    80004e30:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e32:	21c48513          	add	a0,s1,540
    80004e36:	ffffd097          	auipc	ra,0xffffd
    80004e3a:	328080e7          	jalr	808(ra) # 8000215e <wakeup>
  release(&pi->lock);
    80004e3e:	8526                	mv	a0,s1
    80004e40:	ffffc097          	auipc	ra,0xffffc
    80004e44:	e46080e7          	jalr	-442(ra) # 80000c86 <release>
  return i;
}
    80004e48:	854e                	mv	a0,s3
    80004e4a:	60a6                	ld	ra,72(sp)
    80004e4c:	6406                	ld	s0,64(sp)
    80004e4e:	74e2                	ld	s1,56(sp)
    80004e50:	7942                	ld	s2,48(sp)
    80004e52:	79a2                	ld	s3,40(sp)
    80004e54:	7a02                	ld	s4,32(sp)
    80004e56:	6ae2                	ld	s5,24(sp)
    80004e58:	6b42                	ld	s6,16(sp)
    80004e5a:	6161                	add	sp,sp,80
    80004e5c:	8082                	ret
      release(&pi->lock);
    80004e5e:	8526                	mv	a0,s1
    80004e60:	ffffc097          	auipc	ra,0xffffc
    80004e64:	e26080e7          	jalr	-474(ra) # 80000c86 <release>
      return -1;
    80004e68:	59fd                	li	s3,-1
    80004e6a:	bff9                	j	80004e48 <piperead+0xca>

0000000080004e6c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004e6c:	1141                	add	sp,sp,-16
    80004e6e:	e422                	sd	s0,8(sp)
    80004e70:	0800                	add	s0,sp,16
    80004e72:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e74:	8905                	and	a0,a0,1
    80004e76:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004e78:	8b89                	and	a5,a5,2
    80004e7a:	c399                	beqz	a5,80004e80 <flags2perm+0x14>
      perm |= PTE_W;
    80004e7c:	00456513          	or	a0,a0,4
    return perm;
}
    80004e80:	6422                	ld	s0,8(sp)
    80004e82:	0141                	add	sp,sp,16
    80004e84:	8082                	ret

0000000080004e86 <exec>:

int
exec(char *path, char **argv)
{
    80004e86:	df010113          	add	sp,sp,-528
    80004e8a:	20113423          	sd	ra,520(sp)
    80004e8e:	20813023          	sd	s0,512(sp)
    80004e92:	ffa6                	sd	s1,504(sp)
    80004e94:	fbca                	sd	s2,496(sp)
    80004e96:	f7ce                	sd	s3,488(sp)
    80004e98:	f3d2                	sd	s4,480(sp)
    80004e9a:	efd6                	sd	s5,472(sp)
    80004e9c:	ebda                	sd	s6,464(sp)
    80004e9e:	e7de                	sd	s7,456(sp)
    80004ea0:	e3e2                	sd	s8,448(sp)
    80004ea2:	ff66                	sd	s9,440(sp)
    80004ea4:	fb6a                	sd	s10,432(sp)
    80004ea6:	f76e                	sd	s11,424(sp)
    80004ea8:	0c00                	add	s0,sp,528
    80004eaa:	892a                	mv	s2,a0
    80004eac:	dea43c23          	sd	a0,-520(s0)
    80004eb0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004eb4:	ffffd097          	auipc	ra,0xffffd
    80004eb8:	af2080e7          	jalr	-1294(ra) # 800019a6 <myproc>
    80004ebc:	84aa                	mv	s1,a0

  begin_op();
    80004ebe:	fffff097          	auipc	ra,0xfffff
    80004ec2:	48e080e7          	jalr	1166(ra) # 8000434c <begin_op>

  if((ip = namei(path)) == 0){
    80004ec6:	854a                	mv	a0,s2
    80004ec8:	fffff097          	auipc	ra,0xfffff
    80004ecc:	284080e7          	jalr	644(ra) # 8000414c <namei>
    80004ed0:	c92d                	beqz	a0,80004f42 <exec+0xbc>
    80004ed2:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	ad2080e7          	jalr	-1326(ra) # 800039a6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004edc:	04000713          	li	a4,64
    80004ee0:	4681                	li	a3,0
    80004ee2:	e5040613          	add	a2,s0,-432
    80004ee6:	4581                	li	a1,0
    80004ee8:	8552                	mv	a0,s4
    80004eea:	fffff097          	auipc	ra,0xfffff
    80004eee:	d70080e7          	jalr	-656(ra) # 80003c5a <readi>
    80004ef2:	04000793          	li	a5,64
    80004ef6:	00f51a63          	bne	a0,a5,80004f0a <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004efa:	e5042703          	lw	a4,-432(s0)
    80004efe:	464c47b7          	lui	a5,0x464c4
    80004f02:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f06:	04f70463          	beq	a4,a5,80004f4e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f0a:	8552                	mv	a0,s4
    80004f0c:	fffff097          	auipc	ra,0xfffff
    80004f10:	cfc080e7          	jalr	-772(ra) # 80003c08 <iunlockput>
    end_op();
    80004f14:	fffff097          	auipc	ra,0xfffff
    80004f18:	4b2080e7          	jalr	1202(ra) # 800043c6 <end_op>
  }
  return -1;
    80004f1c:	557d                	li	a0,-1
}
    80004f1e:	20813083          	ld	ra,520(sp)
    80004f22:	20013403          	ld	s0,512(sp)
    80004f26:	74fe                	ld	s1,504(sp)
    80004f28:	795e                	ld	s2,496(sp)
    80004f2a:	79be                	ld	s3,488(sp)
    80004f2c:	7a1e                	ld	s4,480(sp)
    80004f2e:	6afe                	ld	s5,472(sp)
    80004f30:	6b5e                	ld	s6,464(sp)
    80004f32:	6bbe                	ld	s7,456(sp)
    80004f34:	6c1e                	ld	s8,448(sp)
    80004f36:	7cfa                	ld	s9,440(sp)
    80004f38:	7d5a                	ld	s10,432(sp)
    80004f3a:	7dba                	ld	s11,424(sp)
    80004f3c:	21010113          	add	sp,sp,528
    80004f40:	8082                	ret
    end_op();
    80004f42:	fffff097          	auipc	ra,0xfffff
    80004f46:	484080e7          	jalr	1156(ra) # 800043c6 <end_op>
    return -1;
    80004f4a:	557d                	li	a0,-1
    80004f4c:	bfc9                	j	80004f1e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f4e:	8526                	mv	a0,s1
    80004f50:	ffffd097          	auipc	ra,0xffffd
    80004f54:	b1a080e7          	jalr	-1254(ra) # 80001a6a <proc_pagetable>
    80004f58:	8b2a                	mv	s6,a0
    80004f5a:	d945                	beqz	a0,80004f0a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f5c:	e7042d03          	lw	s10,-400(s0)
    80004f60:	e8845783          	lhu	a5,-376(s0)
    80004f64:	10078463          	beqz	a5,8000506c <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f68:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f6a:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004f6c:	6c85                	lui	s9,0x1
    80004f6e:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f72:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004f76:	6a85                	lui	s5,0x1
    80004f78:	a0b5                	j	80004fe4 <exec+0x15e>
      panic("loadseg: address should exist");
    80004f7a:	00003517          	auipc	a0,0x3
    80004f7e:	7d650513          	add	a0,a0,2006 # 80008750 <syscalls+0x298>
    80004f82:	ffffb097          	auipc	ra,0xffffb
    80004f86:	5ba080e7          	jalr	1466(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80004f8a:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f8c:	8726                	mv	a4,s1
    80004f8e:	012c06bb          	addw	a3,s8,s2
    80004f92:	4581                	li	a1,0
    80004f94:	8552                	mv	a0,s4
    80004f96:	fffff097          	auipc	ra,0xfffff
    80004f9a:	cc4080e7          	jalr	-828(ra) # 80003c5a <readi>
    80004f9e:	2501                	sext.w	a0,a0
    80004fa0:	24a49863          	bne	s1,a0,800051f0 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80004fa4:	012a893b          	addw	s2,s5,s2
    80004fa8:	03397563          	bgeu	s2,s3,80004fd2 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004fac:	02091593          	sll	a1,s2,0x20
    80004fb0:	9181                	srl	a1,a1,0x20
    80004fb2:	95de                	add	a1,a1,s7
    80004fb4:	855a                	mv	a0,s6
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	0a0080e7          	jalr	160(ra) # 80001056 <walkaddr>
    80004fbe:	862a                	mv	a2,a0
    if(pa == 0)
    80004fc0:	dd4d                	beqz	a0,80004f7a <exec+0xf4>
    if(sz - i < PGSIZE)
    80004fc2:	412984bb          	subw	s1,s3,s2
    80004fc6:	0004879b          	sext.w	a5,s1
    80004fca:	fcfcf0e3          	bgeu	s9,a5,80004f8a <exec+0x104>
    80004fce:	84d6                	mv	s1,s5
    80004fd0:	bf6d                	j	80004f8a <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fd2:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd6:	2d85                	addw	s11,s11,1
    80004fd8:	038d0d1b          	addw	s10,s10,56
    80004fdc:	e8845783          	lhu	a5,-376(s0)
    80004fe0:	08fdd763          	bge	s11,a5,8000506e <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fe4:	2d01                	sext.w	s10,s10
    80004fe6:	03800713          	li	a4,56
    80004fea:	86ea                	mv	a3,s10
    80004fec:	e1840613          	add	a2,s0,-488
    80004ff0:	4581                	li	a1,0
    80004ff2:	8552                	mv	a0,s4
    80004ff4:	fffff097          	auipc	ra,0xfffff
    80004ff8:	c66080e7          	jalr	-922(ra) # 80003c5a <readi>
    80004ffc:	03800793          	li	a5,56
    80005000:	1ef51663          	bne	a0,a5,800051ec <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80005004:	e1842783          	lw	a5,-488(s0)
    80005008:	4705                	li	a4,1
    8000500a:	fce796e3          	bne	a5,a4,80004fd6 <exec+0x150>
    if(ph.memsz < ph.filesz)
    8000500e:	e4043483          	ld	s1,-448(s0)
    80005012:	e3843783          	ld	a5,-456(s0)
    80005016:	1ef4e863          	bltu	s1,a5,80005206 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000501a:	e2843783          	ld	a5,-472(s0)
    8000501e:	94be                	add	s1,s1,a5
    80005020:	1ef4e663          	bltu	s1,a5,8000520c <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80005024:	df043703          	ld	a4,-528(s0)
    80005028:	8ff9                	and	a5,a5,a4
    8000502a:	1e079463          	bnez	a5,80005212 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000502e:	e1c42503          	lw	a0,-484(s0)
    80005032:	00000097          	auipc	ra,0x0
    80005036:	e3a080e7          	jalr	-454(ra) # 80004e6c <flags2perm>
    8000503a:	86aa                	mv	a3,a0
    8000503c:	8626                	mv	a2,s1
    8000503e:	85ca                	mv	a1,s2
    80005040:	855a                	mv	a0,s6
    80005042:	ffffc097          	auipc	ra,0xffffc
    80005046:	3c8080e7          	jalr	968(ra) # 8000140a <uvmalloc>
    8000504a:	e0a43423          	sd	a0,-504(s0)
    8000504e:	1c050563          	beqz	a0,80005218 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005052:	e2843b83          	ld	s7,-472(s0)
    80005056:	e2042c03          	lw	s8,-480(s0)
    8000505a:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000505e:	00098463          	beqz	s3,80005066 <exec+0x1e0>
    80005062:	4901                	li	s2,0
    80005064:	b7a1                	j	80004fac <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005066:	e0843903          	ld	s2,-504(s0)
    8000506a:	b7b5                	j	80004fd6 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000506c:	4901                	li	s2,0
  iunlockput(ip);
    8000506e:	8552                	mv	a0,s4
    80005070:	fffff097          	auipc	ra,0xfffff
    80005074:	b98080e7          	jalr	-1128(ra) # 80003c08 <iunlockput>
  end_op();
    80005078:	fffff097          	auipc	ra,0xfffff
    8000507c:	34e080e7          	jalr	846(ra) # 800043c6 <end_op>
  p = myproc();
    80005080:	ffffd097          	auipc	ra,0xffffd
    80005084:	926080e7          	jalr	-1754(ra) # 800019a6 <myproc>
    80005088:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000508a:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    8000508e:	6985                	lui	s3,0x1
    80005090:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005092:	99ca                	add	s3,s3,s2
    80005094:	77fd                	lui	a5,0xfffff
    80005096:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000509a:	4691                	li	a3,4
    8000509c:	6609                	lui	a2,0x2
    8000509e:	964e                	add	a2,a2,s3
    800050a0:	85ce                	mv	a1,s3
    800050a2:	855a                	mv	a0,s6
    800050a4:	ffffc097          	auipc	ra,0xffffc
    800050a8:	366080e7          	jalr	870(ra) # 8000140a <uvmalloc>
    800050ac:	892a                	mv	s2,a0
    800050ae:	e0a43423          	sd	a0,-504(s0)
    800050b2:	e509                	bnez	a0,800050bc <exec+0x236>
  if(pagetable)
    800050b4:	e1343423          	sd	s3,-504(s0)
    800050b8:	4a01                	li	s4,0
    800050ba:	aa1d                	j	800051f0 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050bc:	75f9                	lui	a1,0xffffe
    800050be:	95aa                	add	a1,a1,a0
    800050c0:	855a                	mv	a0,s6
    800050c2:	ffffc097          	auipc	ra,0xffffc
    800050c6:	572080e7          	jalr	1394(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    800050ca:	7bfd                	lui	s7,0xfffff
    800050cc:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800050ce:	e0043783          	ld	a5,-512(s0)
    800050d2:	6388                	ld	a0,0(a5)
    800050d4:	c52d                	beqz	a0,8000513e <exec+0x2b8>
    800050d6:	e9040993          	add	s3,s0,-368
    800050da:	f9040c13          	add	s8,s0,-112
    800050de:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050e0:	ffffc097          	auipc	ra,0xffffc
    800050e4:	d68080e7          	jalr	-664(ra) # 80000e48 <strlen>
    800050e8:	0015079b          	addw	a5,a0,1
    800050ec:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050f0:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    800050f4:	13796563          	bltu	s2,s7,8000521e <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050f8:	e0043d03          	ld	s10,-512(s0)
    800050fc:	000d3a03          	ld	s4,0(s10)
    80005100:	8552                	mv	a0,s4
    80005102:	ffffc097          	auipc	ra,0xffffc
    80005106:	d46080e7          	jalr	-698(ra) # 80000e48 <strlen>
    8000510a:	0015069b          	addw	a3,a0,1
    8000510e:	8652                	mv	a2,s4
    80005110:	85ca                	mv	a1,s2
    80005112:	855a                	mv	a0,s6
    80005114:	ffffc097          	auipc	ra,0xffffc
    80005118:	552080e7          	jalr	1362(ra) # 80001666 <copyout>
    8000511c:	10054363          	bltz	a0,80005222 <exec+0x39c>
    ustack[argc] = sp;
    80005120:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005124:	0485                	add	s1,s1,1
    80005126:	008d0793          	add	a5,s10,8
    8000512a:	e0f43023          	sd	a5,-512(s0)
    8000512e:	008d3503          	ld	a0,8(s10)
    80005132:	c909                	beqz	a0,80005144 <exec+0x2be>
    if(argc >= MAXARG)
    80005134:	09a1                	add	s3,s3,8
    80005136:	fb8995e3          	bne	s3,s8,800050e0 <exec+0x25a>
  ip = 0;
    8000513a:	4a01                	li	s4,0
    8000513c:	a855                	j	800051f0 <exec+0x36a>
  sp = sz;
    8000513e:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005142:	4481                	li	s1,0
  ustack[argc] = 0;
    80005144:	00349793          	sll	a5,s1,0x3
    80005148:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd8c30>
    8000514c:	97a2                	add	a5,a5,s0
    8000514e:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005152:	00148693          	add	a3,s1,1
    80005156:	068e                	sll	a3,a3,0x3
    80005158:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000515c:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80005160:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005164:	f57968e3          	bltu	s2,s7,800050b4 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005168:	e9040613          	add	a2,s0,-368
    8000516c:	85ca                	mv	a1,s2
    8000516e:	855a                	mv	a0,s6
    80005170:	ffffc097          	auipc	ra,0xffffc
    80005174:	4f6080e7          	jalr	1270(ra) # 80001666 <copyout>
    80005178:	0a054763          	bltz	a0,80005226 <exec+0x3a0>
  p->trapframe->a1 = sp;
    8000517c:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005180:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005184:	df843783          	ld	a5,-520(s0)
    80005188:	0007c703          	lbu	a4,0(a5)
    8000518c:	cf11                	beqz	a4,800051a8 <exec+0x322>
    8000518e:	0785                	add	a5,a5,1
    if(*s == '/')
    80005190:	02f00693          	li	a3,47
    80005194:	a039                	j	800051a2 <exec+0x31c>
      last = s+1;
    80005196:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000519a:	0785                	add	a5,a5,1
    8000519c:	fff7c703          	lbu	a4,-1(a5)
    800051a0:	c701                	beqz	a4,800051a8 <exec+0x322>
    if(*s == '/')
    800051a2:	fed71ce3          	bne	a4,a3,8000519a <exec+0x314>
    800051a6:	bfc5                	j	80005196 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800051a8:	4641                	li	a2,16
    800051aa:	df843583          	ld	a1,-520(s0)
    800051ae:	158a8513          	add	a0,s5,344
    800051b2:	ffffc097          	auipc	ra,0xffffc
    800051b6:	c64080e7          	jalr	-924(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800051ba:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800051be:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800051c2:	e0843783          	ld	a5,-504(s0)
    800051c6:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051ca:	058ab783          	ld	a5,88(s5)
    800051ce:	e6843703          	ld	a4,-408(s0)
    800051d2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051d4:	058ab783          	ld	a5,88(s5)
    800051d8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051dc:	85e6                	mv	a1,s9
    800051de:	ffffd097          	auipc	ra,0xffffd
    800051e2:	928080e7          	jalr	-1752(ra) # 80001b06 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051e6:	0004851b          	sext.w	a0,s1
    800051ea:	bb15                	j	80004f1e <exec+0x98>
    800051ec:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800051f0:	e0843583          	ld	a1,-504(s0)
    800051f4:	855a                	mv	a0,s6
    800051f6:	ffffd097          	auipc	ra,0xffffd
    800051fa:	910080e7          	jalr	-1776(ra) # 80001b06 <proc_freepagetable>
  return -1;
    800051fe:	557d                	li	a0,-1
  if(ip){
    80005200:	d00a0fe3          	beqz	s4,80004f1e <exec+0x98>
    80005204:	b319                	j	80004f0a <exec+0x84>
    80005206:	e1243423          	sd	s2,-504(s0)
    8000520a:	b7dd                	j	800051f0 <exec+0x36a>
    8000520c:	e1243423          	sd	s2,-504(s0)
    80005210:	b7c5                	j	800051f0 <exec+0x36a>
    80005212:	e1243423          	sd	s2,-504(s0)
    80005216:	bfe9                	j	800051f0 <exec+0x36a>
    80005218:	e1243423          	sd	s2,-504(s0)
    8000521c:	bfd1                	j	800051f0 <exec+0x36a>
  ip = 0;
    8000521e:	4a01                	li	s4,0
    80005220:	bfc1                	j	800051f0 <exec+0x36a>
    80005222:	4a01                	li	s4,0
  if(pagetable)
    80005224:	b7f1                	j	800051f0 <exec+0x36a>
  sz = sz1;
    80005226:	e0843983          	ld	s3,-504(s0)
    8000522a:	b569                	j	800050b4 <exec+0x22e>

000000008000522c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000522c:	7179                	add	sp,sp,-48
    8000522e:	f406                	sd	ra,40(sp)
    80005230:	f022                	sd	s0,32(sp)
    80005232:	ec26                	sd	s1,24(sp)
    80005234:	e84a                	sd	s2,16(sp)
    80005236:	1800                	add	s0,sp,48
    80005238:	892e                	mv	s2,a1
    8000523a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000523c:	fdc40593          	add	a1,s0,-36
    80005240:	ffffe097          	auipc	ra,0xffffe
    80005244:	b96080e7          	jalr	-1130(ra) # 80002dd6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005248:	fdc42703          	lw	a4,-36(s0)
    8000524c:	47bd                	li	a5,15
    8000524e:	02e7eb63          	bltu	a5,a4,80005284 <argfd+0x58>
    80005252:	ffffc097          	auipc	ra,0xffffc
    80005256:	754080e7          	jalr	1876(ra) # 800019a6 <myproc>
    8000525a:	fdc42703          	lw	a4,-36(s0)
    8000525e:	01a70793          	add	a5,a4,26
    80005262:	078e                	sll	a5,a5,0x3
    80005264:	953e                	add	a0,a0,a5
    80005266:	611c                	ld	a5,0(a0)
    80005268:	c385                	beqz	a5,80005288 <argfd+0x5c>
    return -1;
  if(pfd)
    8000526a:	00090463          	beqz	s2,80005272 <argfd+0x46>
    *pfd = fd;
    8000526e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005272:	4501                	li	a0,0
  if(pf)
    80005274:	c091                	beqz	s1,80005278 <argfd+0x4c>
    *pf = f;
    80005276:	e09c                	sd	a5,0(s1)
}
    80005278:	70a2                	ld	ra,40(sp)
    8000527a:	7402                	ld	s0,32(sp)
    8000527c:	64e2                	ld	s1,24(sp)
    8000527e:	6942                	ld	s2,16(sp)
    80005280:	6145                	add	sp,sp,48
    80005282:	8082                	ret
    return -1;
    80005284:	557d                	li	a0,-1
    80005286:	bfcd                	j	80005278 <argfd+0x4c>
    80005288:	557d                	li	a0,-1
    8000528a:	b7fd                	j	80005278 <argfd+0x4c>

000000008000528c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000528c:	1101                	add	sp,sp,-32
    8000528e:	ec06                	sd	ra,24(sp)
    80005290:	e822                	sd	s0,16(sp)
    80005292:	e426                	sd	s1,8(sp)
    80005294:	1000                	add	s0,sp,32
    80005296:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005298:	ffffc097          	auipc	ra,0xffffc
    8000529c:	70e080e7          	jalr	1806(ra) # 800019a6 <myproc>
    800052a0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052a2:	0d050793          	add	a5,a0,208
    800052a6:	4501                	li	a0,0
    800052a8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052aa:	6398                	ld	a4,0(a5)
    800052ac:	cb19                	beqz	a4,800052c2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052ae:	2505                	addw	a0,a0,1
    800052b0:	07a1                	add	a5,a5,8
    800052b2:	fed51ce3          	bne	a0,a3,800052aa <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052b6:	557d                	li	a0,-1
}
    800052b8:	60e2                	ld	ra,24(sp)
    800052ba:	6442                	ld	s0,16(sp)
    800052bc:	64a2                	ld	s1,8(sp)
    800052be:	6105                	add	sp,sp,32
    800052c0:	8082                	ret
      p->ofile[fd] = f;
    800052c2:	01a50793          	add	a5,a0,26
    800052c6:	078e                	sll	a5,a5,0x3
    800052c8:	963e                	add	a2,a2,a5
    800052ca:	e204                	sd	s1,0(a2)
      return fd;
    800052cc:	b7f5                	j	800052b8 <fdalloc+0x2c>

00000000800052ce <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052ce:	715d                	add	sp,sp,-80
    800052d0:	e486                	sd	ra,72(sp)
    800052d2:	e0a2                	sd	s0,64(sp)
    800052d4:	fc26                	sd	s1,56(sp)
    800052d6:	f84a                	sd	s2,48(sp)
    800052d8:	f44e                	sd	s3,40(sp)
    800052da:	f052                	sd	s4,32(sp)
    800052dc:	ec56                	sd	s5,24(sp)
    800052de:	e85a                	sd	s6,16(sp)
    800052e0:	0880                	add	s0,sp,80
    800052e2:	8b2e                	mv	s6,a1
    800052e4:	89b2                	mv	s3,a2
    800052e6:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052e8:	fb040593          	add	a1,s0,-80
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	e7e080e7          	jalr	-386(ra) # 8000416a <nameiparent>
    800052f4:	84aa                	mv	s1,a0
    800052f6:	14050b63          	beqz	a0,8000544c <create+0x17e>
    return 0;

  ilock(dp);
    800052fa:	ffffe097          	auipc	ra,0xffffe
    800052fe:	6ac080e7          	jalr	1708(ra) # 800039a6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005302:	4601                	li	a2,0
    80005304:	fb040593          	add	a1,s0,-80
    80005308:	8526                	mv	a0,s1
    8000530a:	fffff097          	auipc	ra,0xfffff
    8000530e:	b80080e7          	jalr	-1152(ra) # 80003e8a <dirlookup>
    80005312:	8aaa                	mv	s5,a0
    80005314:	c921                	beqz	a0,80005364 <create+0x96>
    iunlockput(dp);
    80005316:	8526                	mv	a0,s1
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	8f0080e7          	jalr	-1808(ra) # 80003c08 <iunlockput>
    ilock(ip);
    80005320:	8556                	mv	a0,s5
    80005322:	ffffe097          	auipc	ra,0xffffe
    80005326:	684080e7          	jalr	1668(ra) # 800039a6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000532a:	4789                	li	a5,2
    8000532c:	02fb1563          	bne	s6,a5,80005356 <create+0x88>
    80005330:	044ad783          	lhu	a5,68(s5)
    80005334:	37f9                	addw	a5,a5,-2
    80005336:	17c2                	sll	a5,a5,0x30
    80005338:	93c1                	srl	a5,a5,0x30
    8000533a:	4705                	li	a4,1
    8000533c:	00f76d63          	bltu	a4,a5,80005356 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005340:	8556                	mv	a0,s5
    80005342:	60a6                	ld	ra,72(sp)
    80005344:	6406                	ld	s0,64(sp)
    80005346:	74e2                	ld	s1,56(sp)
    80005348:	7942                	ld	s2,48(sp)
    8000534a:	79a2                	ld	s3,40(sp)
    8000534c:	7a02                	ld	s4,32(sp)
    8000534e:	6ae2                	ld	s5,24(sp)
    80005350:	6b42                	ld	s6,16(sp)
    80005352:	6161                	add	sp,sp,80
    80005354:	8082                	ret
    iunlockput(ip);
    80005356:	8556                	mv	a0,s5
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	8b0080e7          	jalr	-1872(ra) # 80003c08 <iunlockput>
    return 0;
    80005360:	4a81                	li	s5,0
    80005362:	bff9                	j	80005340 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005364:	85da                	mv	a1,s6
    80005366:	4088                	lw	a0,0(s1)
    80005368:	ffffe097          	auipc	ra,0xffffe
    8000536c:	4a6080e7          	jalr	1190(ra) # 8000380e <ialloc>
    80005370:	8a2a                	mv	s4,a0
    80005372:	c529                	beqz	a0,800053bc <create+0xee>
  ilock(ip);
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	632080e7          	jalr	1586(ra) # 800039a6 <ilock>
  ip->major = major;
    8000537c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005380:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005384:	4905                	li	s2,1
    80005386:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000538a:	8552                	mv	a0,s4
    8000538c:	ffffe097          	auipc	ra,0xffffe
    80005390:	54e080e7          	jalr	1358(ra) # 800038da <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005394:	032b0b63          	beq	s6,s2,800053ca <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005398:	004a2603          	lw	a2,4(s4)
    8000539c:	fb040593          	add	a1,s0,-80
    800053a0:	8526                	mv	a0,s1
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	cf8080e7          	jalr	-776(ra) # 8000409a <dirlink>
    800053aa:	06054f63          	bltz	a0,80005428 <create+0x15a>
  iunlockput(dp);
    800053ae:	8526                	mv	a0,s1
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	858080e7          	jalr	-1960(ra) # 80003c08 <iunlockput>
  return ip;
    800053b8:	8ad2                	mv	s5,s4
    800053ba:	b759                	j	80005340 <create+0x72>
    iunlockput(dp);
    800053bc:	8526                	mv	a0,s1
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	84a080e7          	jalr	-1974(ra) # 80003c08 <iunlockput>
    return 0;
    800053c6:	8ad2                	mv	s5,s4
    800053c8:	bfa5                	j	80005340 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053ca:	004a2603          	lw	a2,4(s4)
    800053ce:	00003597          	auipc	a1,0x3
    800053d2:	3a258593          	add	a1,a1,930 # 80008770 <syscalls+0x2b8>
    800053d6:	8552                	mv	a0,s4
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	cc2080e7          	jalr	-830(ra) # 8000409a <dirlink>
    800053e0:	04054463          	bltz	a0,80005428 <create+0x15a>
    800053e4:	40d0                	lw	a2,4(s1)
    800053e6:	00003597          	auipc	a1,0x3
    800053ea:	39258593          	add	a1,a1,914 # 80008778 <syscalls+0x2c0>
    800053ee:	8552                	mv	a0,s4
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	caa080e7          	jalr	-854(ra) # 8000409a <dirlink>
    800053f8:	02054863          	bltz	a0,80005428 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800053fc:	004a2603          	lw	a2,4(s4)
    80005400:	fb040593          	add	a1,s0,-80
    80005404:	8526                	mv	a0,s1
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	c94080e7          	jalr	-876(ra) # 8000409a <dirlink>
    8000540e:	00054d63          	bltz	a0,80005428 <create+0x15a>
    dp->nlink++;  // for ".."
    80005412:	04a4d783          	lhu	a5,74(s1)
    80005416:	2785                	addw	a5,a5,1
    80005418:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000541c:	8526                	mv	a0,s1
    8000541e:	ffffe097          	auipc	ra,0xffffe
    80005422:	4bc080e7          	jalr	1212(ra) # 800038da <iupdate>
    80005426:	b761                	j	800053ae <create+0xe0>
  ip->nlink = 0;
    80005428:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000542c:	8552                	mv	a0,s4
    8000542e:	ffffe097          	auipc	ra,0xffffe
    80005432:	4ac080e7          	jalr	1196(ra) # 800038da <iupdate>
  iunlockput(ip);
    80005436:	8552                	mv	a0,s4
    80005438:	ffffe097          	auipc	ra,0xffffe
    8000543c:	7d0080e7          	jalr	2000(ra) # 80003c08 <iunlockput>
  iunlockput(dp);
    80005440:	8526                	mv	a0,s1
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	7c6080e7          	jalr	1990(ra) # 80003c08 <iunlockput>
  return 0;
    8000544a:	bddd                	j	80005340 <create+0x72>
    return 0;
    8000544c:	8aaa                	mv	s5,a0
    8000544e:	bdcd                	j	80005340 <create+0x72>

0000000080005450 <sys_dup>:
{
    80005450:	7179                	add	sp,sp,-48
    80005452:	f406                	sd	ra,40(sp)
    80005454:	f022                	sd	s0,32(sp)
    80005456:	ec26                	sd	s1,24(sp)
    80005458:	e84a                	sd	s2,16(sp)
    8000545a:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000545c:	fd840613          	add	a2,s0,-40
    80005460:	4581                	li	a1,0
    80005462:	4501                	li	a0,0
    80005464:	00000097          	auipc	ra,0x0
    80005468:	dc8080e7          	jalr	-568(ra) # 8000522c <argfd>
    return -1;
    8000546c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000546e:	02054363          	bltz	a0,80005494 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005472:	fd843903          	ld	s2,-40(s0)
    80005476:	854a                	mv	a0,s2
    80005478:	00000097          	auipc	ra,0x0
    8000547c:	e14080e7          	jalr	-492(ra) # 8000528c <fdalloc>
    80005480:	84aa                	mv	s1,a0
    return -1;
    80005482:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005484:	00054863          	bltz	a0,80005494 <sys_dup+0x44>
  filedup(f);
    80005488:	854a                	mv	a0,s2
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	334080e7          	jalr	820(ra) # 800047be <filedup>
  return fd;
    80005492:	87a6                	mv	a5,s1
}
    80005494:	853e                	mv	a0,a5
    80005496:	70a2                	ld	ra,40(sp)
    80005498:	7402                	ld	s0,32(sp)
    8000549a:	64e2                	ld	s1,24(sp)
    8000549c:	6942                	ld	s2,16(sp)
    8000549e:	6145                	add	sp,sp,48
    800054a0:	8082                	ret

00000000800054a2 <sys_read>:
{
    800054a2:	7179                	add	sp,sp,-48
    800054a4:	f406                	sd	ra,40(sp)
    800054a6:	f022                	sd	s0,32(sp)
    800054a8:	1800                	add	s0,sp,48
  argaddr(1, &p);
    800054aa:	fd840593          	add	a1,s0,-40
    800054ae:	4505                	li	a0,1
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	946080e7          	jalr	-1722(ra) # 80002df6 <argaddr>
  argint(2, &n);
    800054b8:	fe440593          	add	a1,s0,-28
    800054bc:	4509                	li	a0,2
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	918080e7          	jalr	-1768(ra) # 80002dd6 <argint>
  if(argfd(0, 0, &f) < 0)
    800054c6:	fe840613          	add	a2,s0,-24
    800054ca:	4581                	li	a1,0
    800054cc:	4501                	li	a0,0
    800054ce:	00000097          	auipc	ra,0x0
    800054d2:	d5e080e7          	jalr	-674(ra) # 8000522c <argfd>
    800054d6:	87aa                	mv	a5,a0
    return -1;
    800054d8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054da:	0007cc63          	bltz	a5,800054f2 <sys_read+0x50>
  return fileread(f, p, n);
    800054de:	fe442603          	lw	a2,-28(s0)
    800054e2:	fd843583          	ld	a1,-40(s0)
    800054e6:	fe843503          	ld	a0,-24(s0)
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	460080e7          	jalr	1120(ra) # 8000494a <fileread>
}
    800054f2:	70a2                	ld	ra,40(sp)
    800054f4:	7402                	ld	s0,32(sp)
    800054f6:	6145                	add	sp,sp,48
    800054f8:	8082                	ret

00000000800054fa <sys_write>:
{
    800054fa:	7179                	add	sp,sp,-48
    800054fc:	f406                	sd	ra,40(sp)
    800054fe:	f022                	sd	s0,32(sp)
    80005500:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005502:	fd840593          	add	a1,s0,-40
    80005506:	4505                	li	a0,1
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	8ee080e7          	jalr	-1810(ra) # 80002df6 <argaddr>
  argint(2, &n);
    80005510:	fe440593          	add	a1,s0,-28
    80005514:	4509                	li	a0,2
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	8c0080e7          	jalr	-1856(ra) # 80002dd6 <argint>
  if(argfd(0, 0, &f) < 0)
    8000551e:	fe840613          	add	a2,s0,-24
    80005522:	4581                	li	a1,0
    80005524:	4501                	li	a0,0
    80005526:	00000097          	auipc	ra,0x0
    8000552a:	d06080e7          	jalr	-762(ra) # 8000522c <argfd>
    8000552e:	87aa                	mv	a5,a0
    return -1;
    80005530:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005532:	0007cc63          	bltz	a5,8000554a <sys_write+0x50>
  return filewrite(f, p, n);
    80005536:	fe442603          	lw	a2,-28(s0)
    8000553a:	fd843583          	ld	a1,-40(s0)
    8000553e:	fe843503          	ld	a0,-24(s0)
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	4ca080e7          	jalr	1226(ra) # 80004a0c <filewrite>
}
    8000554a:	70a2                	ld	ra,40(sp)
    8000554c:	7402                	ld	s0,32(sp)
    8000554e:	6145                	add	sp,sp,48
    80005550:	8082                	ret

0000000080005552 <sys_close>:
{
    80005552:	1101                	add	sp,sp,-32
    80005554:	ec06                	sd	ra,24(sp)
    80005556:	e822                	sd	s0,16(sp)
    80005558:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000555a:	fe040613          	add	a2,s0,-32
    8000555e:	fec40593          	add	a1,s0,-20
    80005562:	4501                	li	a0,0
    80005564:	00000097          	auipc	ra,0x0
    80005568:	cc8080e7          	jalr	-824(ra) # 8000522c <argfd>
    return -1;
    8000556c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000556e:	02054463          	bltz	a0,80005596 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005572:	ffffc097          	auipc	ra,0xffffc
    80005576:	434080e7          	jalr	1076(ra) # 800019a6 <myproc>
    8000557a:	fec42783          	lw	a5,-20(s0)
    8000557e:	07e9                	add	a5,a5,26
    80005580:	078e                	sll	a5,a5,0x3
    80005582:	953e                	add	a0,a0,a5
    80005584:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005588:	fe043503          	ld	a0,-32(s0)
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	284080e7          	jalr	644(ra) # 80004810 <fileclose>
  return 0;
    80005594:	4781                	li	a5,0
}
    80005596:	853e                	mv	a0,a5
    80005598:	60e2                	ld	ra,24(sp)
    8000559a:	6442                	ld	s0,16(sp)
    8000559c:	6105                	add	sp,sp,32
    8000559e:	8082                	ret

00000000800055a0 <sys_fstat>:
{
    800055a0:	1101                	add	sp,sp,-32
    800055a2:	ec06                	sd	ra,24(sp)
    800055a4:	e822                	sd	s0,16(sp)
    800055a6:	1000                	add	s0,sp,32
  argaddr(1, &st);
    800055a8:	fe040593          	add	a1,s0,-32
    800055ac:	4505                	li	a0,1
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	848080e7          	jalr	-1976(ra) # 80002df6 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800055b6:	fe840613          	add	a2,s0,-24
    800055ba:	4581                	li	a1,0
    800055bc:	4501                	li	a0,0
    800055be:	00000097          	auipc	ra,0x0
    800055c2:	c6e080e7          	jalr	-914(ra) # 8000522c <argfd>
    800055c6:	87aa                	mv	a5,a0
    return -1;
    800055c8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055ca:	0007ca63          	bltz	a5,800055de <sys_fstat+0x3e>
  return filestat(f, st);
    800055ce:	fe043583          	ld	a1,-32(s0)
    800055d2:	fe843503          	ld	a0,-24(s0)
    800055d6:	fffff097          	auipc	ra,0xfffff
    800055da:	302080e7          	jalr	770(ra) # 800048d8 <filestat>
}
    800055de:	60e2                	ld	ra,24(sp)
    800055e0:	6442                	ld	s0,16(sp)
    800055e2:	6105                	add	sp,sp,32
    800055e4:	8082                	ret

00000000800055e6 <sys_link>:
{
    800055e6:	7169                	add	sp,sp,-304
    800055e8:	f606                	sd	ra,296(sp)
    800055ea:	f222                	sd	s0,288(sp)
    800055ec:	ee26                	sd	s1,280(sp)
    800055ee:	ea4a                	sd	s2,272(sp)
    800055f0:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055f2:	08000613          	li	a2,128
    800055f6:	ed040593          	add	a1,s0,-304
    800055fa:	4501                	li	a0,0
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	81a080e7          	jalr	-2022(ra) # 80002e16 <argstr>
    return -1;
    80005604:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005606:	10054e63          	bltz	a0,80005722 <sys_link+0x13c>
    8000560a:	08000613          	li	a2,128
    8000560e:	f5040593          	add	a1,s0,-176
    80005612:	4505                	li	a0,1
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	802080e7          	jalr	-2046(ra) # 80002e16 <argstr>
    return -1;
    8000561c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000561e:	10054263          	bltz	a0,80005722 <sys_link+0x13c>
  begin_op();
    80005622:	fffff097          	auipc	ra,0xfffff
    80005626:	d2a080e7          	jalr	-726(ra) # 8000434c <begin_op>
  if((ip = namei(old)) == 0){
    8000562a:	ed040513          	add	a0,s0,-304
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	b1e080e7          	jalr	-1250(ra) # 8000414c <namei>
    80005636:	84aa                	mv	s1,a0
    80005638:	c551                	beqz	a0,800056c4 <sys_link+0xde>
  ilock(ip);
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	36c080e7          	jalr	876(ra) # 800039a6 <ilock>
  if(ip->type == T_DIR){
    80005642:	04449703          	lh	a4,68(s1)
    80005646:	4785                	li	a5,1
    80005648:	08f70463          	beq	a4,a5,800056d0 <sys_link+0xea>
  ip->nlink++;
    8000564c:	04a4d783          	lhu	a5,74(s1)
    80005650:	2785                	addw	a5,a5,1
    80005652:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005656:	8526                	mv	a0,s1
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	282080e7          	jalr	642(ra) # 800038da <iupdate>
  iunlock(ip);
    80005660:	8526                	mv	a0,s1
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	406080e7          	jalr	1030(ra) # 80003a68 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000566a:	fd040593          	add	a1,s0,-48
    8000566e:	f5040513          	add	a0,s0,-176
    80005672:	fffff097          	auipc	ra,0xfffff
    80005676:	af8080e7          	jalr	-1288(ra) # 8000416a <nameiparent>
    8000567a:	892a                	mv	s2,a0
    8000567c:	c935                	beqz	a0,800056f0 <sys_link+0x10a>
  ilock(dp);
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	328080e7          	jalr	808(ra) # 800039a6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005686:	00092703          	lw	a4,0(s2)
    8000568a:	409c                	lw	a5,0(s1)
    8000568c:	04f71d63          	bne	a4,a5,800056e6 <sys_link+0x100>
    80005690:	40d0                	lw	a2,4(s1)
    80005692:	fd040593          	add	a1,s0,-48
    80005696:	854a                	mv	a0,s2
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	a02080e7          	jalr	-1534(ra) # 8000409a <dirlink>
    800056a0:	04054363          	bltz	a0,800056e6 <sys_link+0x100>
  iunlockput(dp);
    800056a4:	854a                	mv	a0,s2
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	562080e7          	jalr	1378(ra) # 80003c08 <iunlockput>
  iput(ip);
    800056ae:	8526                	mv	a0,s1
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	4b0080e7          	jalr	1200(ra) # 80003b60 <iput>
  end_op();
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	d0e080e7          	jalr	-754(ra) # 800043c6 <end_op>
  return 0;
    800056c0:	4781                	li	a5,0
    800056c2:	a085                	j	80005722 <sys_link+0x13c>
    end_op();
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	d02080e7          	jalr	-766(ra) # 800043c6 <end_op>
    return -1;
    800056cc:	57fd                	li	a5,-1
    800056ce:	a891                	j	80005722 <sys_link+0x13c>
    iunlockput(ip);
    800056d0:	8526                	mv	a0,s1
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	536080e7          	jalr	1334(ra) # 80003c08 <iunlockput>
    end_op();
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	cec080e7          	jalr	-788(ra) # 800043c6 <end_op>
    return -1;
    800056e2:	57fd                	li	a5,-1
    800056e4:	a83d                	j	80005722 <sys_link+0x13c>
    iunlockput(dp);
    800056e6:	854a                	mv	a0,s2
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	520080e7          	jalr	1312(ra) # 80003c08 <iunlockput>
  ilock(ip);
    800056f0:	8526                	mv	a0,s1
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	2b4080e7          	jalr	692(ra) # 800039a6 <ilock>
  ip->nlink--;
    800056fa:	04a4d783          	lhu	a5,74(s1)
    800056fe:	37fd                	addw	a5,a5,-1
    80005700:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005704:	8526                	mv	a0,s1
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	1d4080e7          	jalr	468(ra) # 800038da <iupdate>
  iunlockput(ip);
    8000570e:	8526                	mv	a0,s1
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	4f8080e7          	jalr	1272(ra) # 80003c08 <iunlockput>
  end_op();
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	cae080e7          	jalr	-850(ra) # 800043c6 <end_op>
  return -1;
    80005720:	57fd                	li	a5,-1
}
    80005722:	853e                	mv	a0,a5
    80005724:	70b2                	ld	ra,296(sp)
    80005726:	7412                	ld	s0,288(sp)
    80005728:	64f2                	ld	s1,280(sp)
    8000572a:	6952                	ld	s2,272(sp)
    8000572c:	6155                	add	sp,sp,304
    8000572e:	8082                	ret

0000000080005730 <sys_unlink>:
{
    80005730:	7151                	add	sp,sp,-240
    80005732:	f586                	sd	ra,232(sp)
    80005734:	f1a2                	sd	s0,224(sp)
    80005736:	eda6                	sd	s1,216(sp)
    80005738:	e9ca                	sd	s2,208(sp)
    8000573a:	e5ce                	sd	s3,200(sp)
    8000573c:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000573e:	08000613          	li	a2,128
    80005742:	f3040593          	add	a1,s0,-208
    80005746:	4501                	li	a0,0
    80005748:	ffffd097          	auipc	ra,0xffffd
    8000574c:	6ce080e7          	jalr	1742(ra) # 80002e16 <argstr>
    80005750:	18054163          	bltz	a0,800058d2 <sys_unlink+0x1a2>
  begin_op();
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	bf8080e7          	jalr	-1032(ra) # 8000434c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000575c:	fb040593          	add	a1,s0,-80
    80005760:	f3040513          	add	a0,s0,-208
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	a06080e7          	jalr	-1530(ra) # 8000416a <nameiparent>
    8000576c:	84aa                	mv	s1,a0
    8000576e:	c979                	beqz	a0,80005844 <sys_unlink+0x114>
  ilock(dp);
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	236080e7          	jalr	566(ra) # 800039a6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005778:	00003597          	auipc	a1,0x3
    8000577c:	ff858593          	add	a1,a1,-8 # 80008770 <syscalls+0x2b8>
    80005780:	fb040513          	add	a0,s0,-80
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	6ec080e7          	jalr	1772(ra) # 80003e70 <namecmp>
    8000578c:	14050a63          	beqz	a0,800058e0 <sys_unlink+0x1b0>
    80005790:	00003597          	auipc	a1,0x3
    80005794:	fe858593          	add	a1,a1,-24 # 80008778 <syscalls+0x2c0>
    80005798:	fb040513          	add	a0,s0,-80
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	6d4080e7          	jalr	1748(ra) # 80003e70 <namecmp>
    800057a4:	12050e63          	beqz	a0,800058e0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057a8:	f2c40613          	add	a2,s0,-212
    800057ac:	fb040593          	add	a1,s0,-80
    800057b0:	8526                	mv	a0,s1
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	6d8080e7          	jalr	1752(ra) # 80003e8a <dirlookup>
    800057ba:	892a                	mv	s2,a0
    800057bc:	12050263          	beqz	a0,800058e0 <sys_unlink+0x1b0>
  ilock(ip);
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	1e6080e7          	jalr	486(ra) # 800039a6 <ilock>
  if(ip->nlink < 1)
    800057c8:	04a91783          	lh	a5,74(s2)
    800057cc:	08f05263          	blez	a5,80005850 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057d0:	04491703          	lh	a4,68(s2)
    800057d4:	4785                	li	a5,1
    800057d6:	08f70563          	beq	a4,a5,80005860 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057da:	4641                	li	a2,16
    800057dc:	4581                	li	a1,0
    800057de:	fc040513          	add	a0,s0,-64
    800057e2:	ffffb097          	auipc	ra,0xffffb
    800057e6:	4ec080e7          	jalr	1260(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057ea:	4741                	li	a4,16
    800057ec:	f2c42683          	lw	a3,-212(s0)
    800057f0:	fc040613          	add	a2,s0,-64
    800057f4:	4581                	li	a1,0
    800057f6:	8526                	mv	a0,s1
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	55a080e7          	jalr	1370(ra) # 80003d52 <writei>
    80005800:	47c1                	li	a5,16
    80005802:	0af51563          	bne	a0,a5,800058ac <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005806:	04491703          	lh	a4,68(s2)
    8000580a:	4785                	li	a5,1
    8000580c:	0af70863          	beq	a4,a5,800058bc <sys_unlink+0x18c>
  iunlockput(dp);
    80005810:	8526                	mv	a0,s1
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	3f6080e7          	jalr	1014(ra) # 80003c08 <iunlockput>
  ip->nlink--;
    8000581a:	04a95783          	lhu	a5,74(s2)
    8000581e:	37fd                	addw	a5,a5,-1
    80005820:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005824:	854a                	mv	a0,s2
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	0b4080e7          	jalr	180(ra) # 800038da <iupdate>
  iunlockput(ip);
    8000582e:	854a                	mv	a0,s2
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	3d8080e7          	jalr	984(ra) # 80003c08 <iunlockput>
  end_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	b8e080e7          	jalr	-1138(ra) # 800043c6 <end_op>
  return 0;
    80005840:	4501                	li	a0,0
    80005842:	a84d                	j	800058f4 <sys_unlink+0x1c4>
    end_op();
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	b82080e7          	jalr	-1150(ra) # 800043c6 <end_op>
    return -1;
    8000584c:	557d                	li	a0,-1
    8000584e:	a05d                	j	800058f4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005850:	00003517          	auipc	a0,0x3
    80005854:	f3050513          	add	a0,a0,-208 # 80008780 <syscalls+0x2c8>
    80005858:	ffffb097          	auipc	ra,0xffffb
    8000585c:	ce4080e7          	jalr	-796(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005860:	04c92703          	lw	a4,76(s2)
    80005864:	02000793          	li	a5,32
    80005868:	f6e7f9e3          	bgeu	a5,a4,800057da <sys_unlink+0xaa>
    8000586c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005870:	4741                	li	a4,16
    80005872:	86ce                	mv	a3,s3
    80005874:	f1840613          	add	a2,s0,-232
    80005878:	4581                	li	a1,0
    8000587a:	854a                	mv	a0,s2
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	3de080e7          	jalr	990(ra) # 80003c5a <readi>
    80005884:	47c1                	li	a5,16
    80005886:	00f51b63          	bne	a0,a5,8000589c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000588a:	f1845783          	lhu	a5,-232(s0)
    8000588e:	e7a1                	bnez	a5,800058d6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005890:	29c1                	addw	s3,s3,16
    80005892:	04c92783          	lw	a5,76(s2)
    80005896:	fcf9ede3          	bltu	s3,a5,80005870 <sys_unlink+0x140>
    8000589a:	b781                	j	800057da <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000589c:	00003517          	auipc	a0,0x3
    800058a0:	efc50513          	add	a0,a0,-260 # 80008798 <syscalls+0x2e0>
    800058a4:	ffffb097          	auipc	ra,0xffffb
    800058a8:	c98080e7          	jalr	-872(ra) # 8000053c <panic>
    panic("unlink: writei");
    800058ac:	00003517          	auipc	a0,0x3
    800058b0:	f0450513          	add	a0,a0,-252 # 800087b0 <syscalls+0x2f8>
    800058b4:	ffffb097          	auipc	ra,0xffffb
    800058b8:	c88080e7          	jalr	-888(ra) # 8000053c <panic>
    dp->nlink--;
    800058bc:	04a4d783          	lhu	a5,74(s1)
    800058c0:	37fd                	addw	a5,a5,-1
    800058c2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058c6:	8526                	mv	a0,s1
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	012080e7          	jalr	18(ra) # 800038da <iupdate>
    800058d0:	b781                	j	80005810 <sys_unlink+0xe0>
    return -1;
    800058d2:	557d                	li	a0,-1
    800058d4:	a005                	j	800058f4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058d6:	854a                	mv	a0,s2
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	330080e7          	jalr	816(ra) # 80003c08 <iunlockput>
  iunlockput(dp);
    800058e0:	8526                	mv	a0,s1
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	326080e7          	jalr	806(ra) # 80003c08 <iunlockput>
  end_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	adc080e7          	jalr	-1316(ra) # 800043c6 <end_op>
  return -1;
    800058f2:	557d                	li	a0,-1
}
    800058f4:	70ae                	ld	ra,232(sp)
    800058f6:	740e                	ld	s0,224(sp)
    800058f8:	64ee                	ld	s1,216(sp)
    800058fa:	694e                	ld	s2,208(sp)
    800058fc:	69ae                	ld	s3,200(sp)
    800058fe:	616d                	add	sp,sp,240
    80005900:	8082                	ret

0000000080005902 <sys_open>:

uint64
sys_open(void)
{
    80005902:	7131                	add	sp,sp,-192
    80005904:	fd06                	sd	ra,184(sp)
    80005906:	f922                	sd	s0,176(sp)
    80005908:	f526                	sd	s1,168(sp)
    8000590a:	f14a                	sd	s2,160(sp)
    8000590c:	ed4e                	sd	s3,152(sp)
    8000590e:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005910:	f4c40593          	add	a1,s0,-180
    80005914:	4505                	li	a0,1
    80005916:	ffffd097          	auipc	ra,0xffffd
    8000591a:	4c0080e7          	jalr	1216(ra) # 80002dd6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000591e:	08000613          	li	a2,128
    80005922:	f5040593          	add	a1,s0,-176
    80005926:	4501                	li	a0,0
    80005928:	ffffd097          	auipc	ra,0xffffd
    8000592c:	4ee080e7          	jalr	1262(ra) # 80002e16 <argstr>
    80005930:	87aa                	mv	a5,a0
    return -1;
    80005932:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005934:	0a07c863          	bltz	a5,800059e4 <sys_open+0xe2>

  begin_op();
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	a14080e7          	jalr	-1516(ra) # 8000434c <begin_op>

  if(omode & O_CREATE){
    80005940:	f4c42783          	lw	a5,-180(s0)
    80005944:	2007f793          	and	a5,a5,512
    80005948:	cbdd                	beqz	a5,800059fe <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    8000594a:	4681                	li	a3,0
    8000594c:	4601                	li	a2,0
    8000594e:	4589                	li	a1,2
    80005950:	f5040513          	add	a0,s0,-176
    80005954:	00000097          	auipc	ra,0x0
    80005958:	97a080e7          	jalr	-1670(ra) # 800052ce <create>
    8000595c:	84aa                	mv	s1,a0
    if(ip == 0){
    8000595e:	c951                	beqz	a0,800059f2 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005960:	04449703          	lh	a4,68(s1)
    80005964:	478d                	li	a5,3
    80005966:	00f71763          	bne	a4,a5,80005974 <sys_open+0x72>
    8000596a:	0464d703          	lhu	a4,70(s1)
    8000596e:	47a5                	li	a5,9
    80005970:	0ce7ec63          	bltu	a5,a4,80005a48 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	de0080e7          	jalr	-544(ra) # 80004754 <filealloc>
    8000597c:	892a                	mv	s2,a0
    8000597e:	c56d                	beqz	a0,80005a68 <sys_open+0x166>
    80005980:	00000097          	auipc	ra,0x0
    80005984:	90c080e7          	jalr	-1780(ra) # 8000528c <fdalloc>
    80005988:	89aa                	mv	s3,a0
    8000598a:	0c054a63          	bltz	a0,80005a5e <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000598e:	04449703          	lh	a4,68(s1)
    80005992:	478d                	li	a5,3
    80005994:	0ef70563          	beq	a4,a5,80005a7e <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005998:	4789                	li	a5,2
    8000599a:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    8000599e:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    800059a2:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800059a6:	f4c42783          	lw	a5,-180(s0)
    800059aa:	0017c713          	xor	a4,a5,1
    800059ae:	8b05                	and	a4,a4,1
    800059b0:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059b4:	0037f713          	and	a4,a5,3
    800059b8:	00e03733          	snez	a4,a4
    800059bc:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059c0:	4007f793          	and	a5,a5,1024
    800059c4:	c791                	beqz	a5,800059d0 <sys_open+0xce>
    800059c6:	04449703          	lh	a4,68(s1)
    800059ca:	4789                	li	a5,2
    800059cc:	0cf70063          	beq	a4,a5,80005a8c <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    800059d0:	8526                	mv	a0,s1
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	096080e7          	jalr	150(ra) # 80003a68 <iunlock>
  end_op();
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	9ec080e7          	jalr	-1556(ra) # 800043c6 <end_op>

  return fd;
    800059e2:	854e                	mv	a0,s3
}
    800059e4:	70ea                	ld	ra,184(sp)
    800059e6:	744a                	ld	s0,176(sp)
    800059e8:	74aa                	ld	s1,168(sp)
    800059ea:	790a                	ld	s2,160(sp)
    800059ec:	69ea                	ld	s3,152(sp)
    800059ee:	6129                	add	sp,sp,192
    800059f0:	8082                	ret
      end_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	9d4080e7          	jalr	-1580(ra) # 800043c6 <end_op>
      return -1;
    800059fa:	557d                	li	a0,-1
    800059fc:	b7e5                	j	800059e4 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    800059fe:	f5040513          	add	a0,s0,-176
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	74a080e7          	jalr	1866(ra) # 8000414c <namei>
    80005a0a:	84aa                	mv	s1,a0
    80005a0c:	c905                	beqz	a0,80005a3c <sys_open+0x13a>
    ilock(ip);
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	f98080e7          	jalr	-104(ra) # 800039a6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a16:	04449703          	lh	a4,68(s1)
    80005a1a:	4785                	li	a5,1
    80005a1c:	f4f712e3          	bne	a4,a5,80005960 <sys_open+0x5e>
    80005a20:	f4c42783          	lw	a5,-180(s0)
    80005a24:	dba1                	beqz	a5,80005974 <sys_open+0x72>
      iunlockput(ip);
    80005a26:	8526                	mv	a0,s1
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	1e0080e7          	jalr	480(ra) # 80003c08 <iunlockput>
      end_op();
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	996080e7          	jalr	-1642(ra) # 800043c6 <end_op>
      return -1;
    80005a38:	557d                	li	a0,-1
    80005a3a:	b76d                	j	800059e4 <sys_open+0xe2>
      end_op();
    80005a3c:	fffff097          	auipc	ra,0xfffff
    80005a40:	98a080e7          	jalr	-1654(ra) # 800043c6 <end_op>
      return -1;
    80005a44:	557d                	li	a0,-1
    80005a46:	bf79                	j	800059e4 <sys_open+0xe2>
    iunlockput(ip);
    80005a48:	8526                	mv	a0,s1
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	1be080e7          	jalr	446(ra) # 80003c08 <iunlockput>
    end_op();
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	974080e7          	jalr	-1676(ra) # 800043c6 <end_op>
    return -1;
    80005a5a:	557d                	li	a0,-1
    80005a5c:	b761                	j	800059e4 <sys_open+0xe2>
      fileclose(f);
    80005a5e:	854a                	mv	a0,s2
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	db0080e7          	jalr	-592(ra) # 80004810 <fileclose>
    iunlockput(ip);
    80005a68:	8526                	mv	a0,s1
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	19e080e7          	jalr	414(ra) # 80003c08 <iunlockput>
    end_op();
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	954080e7          	jalr	-1708(ra) # 800043c6 <end_op>
    return -1;
    80005a7a:	557d                	li	a0,-1
    80005a7c:	b7a5                	j	800059e4 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005a7e:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005a82:	04649783          	lh	a5,70(s1)
    80005a86:	02f91223          	sh	a5,36(s2)
    80005a8a:	bf21                	j	800059a2 <sys_open+0xa0>
    itrunc(ip);
    80005a8c:	8526                	mv	a0,s1
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	026080e7          	jalr	38(ra) # 80003ab4 <itrunc>
    80005a96:	bf2d                	j	800059d0 <sys_open+0xce>

0000000080005a98 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a98:	7175                	add	sp,sp,-144
    80005a9a:	e506                	sd	ra,136(sp)
    80005a9c:	e122                	sd	s0,128(sp)
    80005a9e:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	8ac080e7          	jalr	-1876(ra) # 8000434c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005aa8:	08000613          	li	a2,128
    80005aac:	f7040593          	add	a1,s0,-144
    80005ab0:	4501                	li	a0,0
    80005ab2:	ffffd097          	auipc	ra,0xffffd
    80005ab6:	364080e7          	jalr	868(ra) # 80002e16 <argstr>
    80005aba:	02054963          	bltz	a0,80005aec <sys_mkdir+0x54>
    80005abe:	4681                	li	a3,0
    80005ac0:	4601                	li	a2,0
    80005ac2:	4585                	li	a1,1
    80005ac4:	f7040513          	add	a0,s0,-144
    80005ac8:	00000097          	auipc	ra,0x0
    80005acc:	806080e7          	jalr	-2042(ra) # 800052ce <create>
    80005ad0:	cd11                	beqz	a0,80005aec <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	136080e7          	jalr	310(ra) # 80003c08 <iunlockput>
  end_op();
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	8ec080e7          	jalr	-1812(ra) # 800043c6 <end_op>
  return 0;
    80005ae2:	4501                	li	a0,0
}
    80005ae4:	60aa                	ld	ra,136(sp)
    80005ae6:	640a                	ld	s0,128(sp)
    80005ae8:	6149                	add	sp,sp,144
    80005aea:	8082                	ret
    end_op();
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	8da080e7          	jalr	-1830(ra) # 800043c6 <end_op>
    return -1;
    80005af4:	557d                	li	a0,-1
    80005af6:	b7fd                	j	80005ae4 <sys_mkdir+0x4c>

0000000080005af8 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005af8:	7135                	add	sp,sp,-160
    80005afa:	ed06                	sd	ra,152(sp)
    80005afc:	e922                	sd	s0,144(sp)
    80005afe:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	84c080e7          	jalr	-1972(ra) # 8000434c <begin_op>
  argint(1, &major);
    80005b08:	f6c40593          	add	a1,s0,-148
    80005b0c:	4505                	li	a0,1
    80005b0e:	ffffd097          	auipc	ra,0xffffd
    80005b12:	2c8080e7          	jalr	712(ra) # 80002dd6 <argint>
  argint(2, &minor);
    80005b16:	f6840593          	add	a1,s0,-152
    80005b1a:	4509                	li	a0,2
    80005b1c:	ffffd097          	auipc	ra,0xffffd
    80005b20:	2ba080e7          	jalr	698(ra) # 80002dd6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b24:	08000613          	li	a2,128
    80005b28:	f7040593          	add	a1,s0,-144
    80005b2c:	4501                	li	a0,0
    80005b2e:	ffffd097          	auipc	ra,0xffffd
    80005b32:	2e8080e7          	jalr	744(ra) # 80002e16 <argstr>
    80005b36:	02054b63          	bltz	a0,80005b6c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b3a:	f6841683          	lh	a3,-152(s0)
    80005b3e:	f6c41603          	lh	a2,-148(s0)
    80005b42:	458d                	li	a1,3
    80005b44:	f7040513          	add	a0,s0,-144
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	786080e7          	jalr	1926(ra) # 800052ce <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b50:	cd11                	beqz	a0,80005b6c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	0b6080e7          	jalr	182(ra) # 80003c08 <iunlockput>
  end_op();
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	86c080e7          	jalr	-1940(ra) # 800043c6 <end_op>
  return 0;
    80005b62:	4501                	li	a0,0
}
    80005b64:	60ea                	ld	ra,152(sp)
    80005b66:	644a                	ld	s0,144(sp)
    80005b68:	610d                	add	sp,sp,160
    80005b6a:	8082                	ret
    end_op();
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	85a080e7          	jalr	-1958(ra) # 800043c6 <end_op>
    return -1;
    80005b74:	557d                	li	a0,-1
    80005b76:	b7fd                	j	80005b64 <sys_mknod+0x6c>

0000000080005b78 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b78:	7135                	add	sp,sp,-160
    80005b7a:	ed06                	sd	ra,152(sp)
    80005b7c:	e922                	sd	s0,144(sp)
    80005b7e:	e526                	sd	s1,136(sp)
    80005b80:	e14a                	sd	s2,128(sp)
    80005b82:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b84:	ffffc097          	auipc	ra,0xffffc
    80005b88:	e22080e7          	jalr	-478(ra) # 800019a6 <myproc>
    80005b8c:	892a                	mv	s2,a0
  
  begin_op();
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	7be080e7          	jalr	1982(ra) # 8000434c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b96:	08000613          	li	a2,128
    80005b9a:	f6040593          	add	a1,s0,-160
    80005b9e:	4501                	li	a0,0
    80005ba0:	ffffd097          	auipc	ra,0xffffd
    80005ba4:	276080e7          	jalr	630(ra) # 80002e16 <argstr>
    80005ba8:	04054b63          	bltz	a0,80005bfe <sys_chdir+0x86>
    80005bac:	f6040513          	add	a0,s0,-160
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	59c080e7          	jalr	1436(ra) # 8000414c <namei>
    80005bb8:	84aa                	mv	s1,a0
    80005bba:	c131                	beqz	a0,80005bfe <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	dea080e7          	jalr	-534(ra) # 800039a6 <ilock>
  if(ip->type != T_DIR){
    80005bc4:	04449703          	lh	a4,68(s1)
    80005bc8:	4785                	li	a5,1
    80005bca:	04f71063          	bne	a4,a5,80005c0a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bce:	8526                	mv	a0,s1
    80005bd0:	ffffe097          	auipc	ra,0xffffe
    80005bd4:	e98080e7          	jalr	-360(ra) # 80003a68 <iunlock>
  iput(p->cwd);
    80005bd8:	15093503          	ld	a0,336(s2)
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	f84080e7          	jalr	-124(ra) # 80003b60 <iput>
  end_op();
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	7e2080e7          	jalr	2018(ra) # 800043c6 <end_op>
  p->cwd = ip;
    80005bec:	14993823          	sd	s1,336(s2)
  return 0;
    80005bf0:	4501                	li	a0,0
}
    80005bf2:	60ea                	ld	ra,152(sp)
    80005bf4:	644a                	ld	s0,144(sp)
    80005bf6:	64aa                	ld	s1,136(sp)
    80005bf8:	690a                	ld	s2,128(sp)
    80005bfa:	610d                	add	sp,sp,160
    80005bfc:	8082                	ret
    end_op();
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	7c8080e7          	jalr	1992(ra) # 800043c6 <end_op>
    return -1;
    80005c06:	557d                	li	a0,-1
    80005c08:	b7ed                	j	80005bf2 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c0a:	8526                	mv	a0,s1
    80005c0c:	ffffe097          	auipc	ra,0xffffe
    80005c10:	ffc080e7          	jalr	-4(ra) # 80003c08 <iunlockput>
    end_op();
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	7b2080e7          	jalr	1970(ra) # 800043c6 <end_op>
    return -1;
    80005c1c:	557d                	li	a0,-1
    80005c1e:	bfd1                	j	80005bf2 <sys_chdir+0x7a>

0000000080005c20 <sys_exec>:

uint64
sys_exec(void)
{
    80005c20:	7121                	add	sp,sp,-448
    80005c22:	ff06                	sd	ra,440(sp)
    80005c24:	fb22                	sd	s0,432(sp)
    80005c26:	f726                	sd	s1,424(sp)
    80005c28:	f34a                	sd	s2,416(sp)
    80005c2a:	ef4e                	sd	s3,408(sp)
    80005c2c:	eb52                	sd	s4,400(sp)
    80005c2e:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005c30:	e4840593          	add	a1,s0,-440
    80005c34:	4505                	li	a0,1
    80005c36:	ffffd097          	auipc	ra,0xffffd
    80005c3a:	1c0080e7          	jalr	448(ra) # 80002df6 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005c3e:	08000613          	li	a2,128
    80005c42:	f5040593          	add	a1,s0,-176
    80005c46:	4501                	li	a0,0
    80005c48:	ffffd097          	auipc	ra,0xffffd
    80005c4c:	1ce080e7          	jalr	462(ra) # 80002e16 <argstr>
    80005c50:	87aa                	mv	a5,a0
    return -1;
    80005c52:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c54:	0c07c263          	bltz	a5,80005d18 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005c58:	10000613          	li	a2,256
    80005c5c:	4581                	li	a1,0
    80005c5e:	e5040513          	add	a0,s0,-432
    80005c62:	ffffb097          	auipc	ra,0xffffb
    80005c66:	06c080e7          	jalr	108(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c6a:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005c6e:	89a6                	mv	s3,s1
    80005c70:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c72:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c76:	00391513          	sll	a0,s2,0x3
    80005c7a:	e4040593          	add	a1,s0,-448
    80005c7e:	e4843783          	ld	a5,-440(s0)
    80005c82:	953e                	add	a0,a0,a5
    80005c84:	ffffd097          	auipc	ra,0xffffd
    80005c88:	0b4080e7          	jalr	180(ra) # 80002d38 <fetchaddr>
    80005c8c:	02054a63          	bltz	a0,80005cc0 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005c90:	e4043783          	ld	a5,-448(s0)
    80005c94:	c3b9                	beqz	a5,80005cda <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c96:	ffffb097          	auipc	ra,0xffffb
    80005c9a:	e4c080e7          	jalr	-436(ra) # 80000ae2 <kalloc>
    80005c9e:	85aa                	mv	a1,a0
    80005ca0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ca4:	cd11                	beqz	a0,80005cc0 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ca6:	6605                	lui	a2,0x1
    80005ca8:	e4043503          	ld	a0,-448(s0)
    80005cac:	ffffd097          	auipc	ra,0xffffd
    80005cb0:	0de080e7          	jalr	222(ra) # 80002d8a <fetchstr>
    80005cb4:	00054663          	bltz	a0,80005cc0 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005cb8:	0905                	add	s2,s2,1
    80005cba:	09a1                	add	s3,s3,8
    80005cbc:	fb491de3          	bne	s2,s4,80005c76 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cc0:	f5040913          	add	s2,s0,-176
    80005cc4:	6088                	ld	a0,0(s1)
    80005cc6:	c921                	beqz	a0,80005d16 <sys_exec+0xf6>
    kfree(argv[i]);
    80005cc8:	ffffb097          	auipc	ra,0xffffb
    80005ccc:	d1c080e7          	jalr	-740(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cd0:	04a1                	add	s1,s1,8
    80005cd2:	ff2499e3          	bne	s1,s2,80005cc4 <sys_exec+0xa4>
  return -1;
    80005cd6:	557d                	li	a0,-1
    80005cd8:	a081                	j	80005d18 <sys_exec+0xf8>
      argv[i] = 0;
    80005cda:	0009079b          	sext.w	a5,s2
    80005cde:	078e                	sll	a5,a5,0x3
    80005ce0:	fd078793          	add	a5,a5,-48
    80005ce4:	97a2                	add	a5,a5,s0
    80005ce6:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005cea:	e5040593          	add	a1,s0,-432
    80005cee:	f5040513          	add	a0,s0,-176
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	194080e7          	jalr	404(ra) # 80004e86 <exec>
    80005cfa:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cfc:	f5040993          	add	s3,s0,-176
    80005d00:	6088                	ld	a0,0(s1)
    80005d02:	c901                	beqz	a0,80005d12 <sys_exec+0xf2>
    kfree(argv[i]);
    80005d04:	ffffb097          	auipc	ra,0xffffb
    80005d08:	ce0080e7          	jalr	-800(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d0c:	04a1                	add	s1,s1,8
    80005d0e:	ff3499e3          	bne	s1,s3,80005d00 <sys_exec+0xe0>
  return ret;
    80005d12:	854a                	mv	a0,s2
    80005d14:	a011                	j	80005d18 <sys_exec+0xf8>
  return -1;
    80005d16:	557d                	li	a0,-1
}
    80005d18:	70fa                	ld	ra,440(sp)
    80005d1a:	745a                	ld	s0,432(sp)
    80005d1c:	74ba                	ld	s1,424(sp)
    80005d1e:	791a                	ld	s2,416(sp)
    80005d20:	69fa                	ld	s3,408(sp)
    80005d22:	6a5a                	ld	s4,400(sp)
    80005d24:	6139                	add	sp,sp,448
    80005d26:	8082                	ret

0000000080005d28 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d28:	7139                	add	sp,sp,-64
    80005d2a:	fc06                	sd	ra,56(sp)
    80005d2c:	f822                	sd	s0,48(sp)
    80005d2e:	f426                	sd	s1,40(sp)
    80005d30:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d32:	ffffc097          	auipc	ra,0xffffc
    80005d36:	c74080e7          	jalr	-908(ra) # 800019a6 <myproc>
    80005d3a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005d3c:	fd840593          	add	a1,s0,-40
    80005d40:	4501                	li	a0,0
    80005d42:	ffffd097          	auipc	ra,0xffffd
    80005d46:	0b4080e7          	jalr	180(ra) # 80002df6 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d4a:	fc840593          	add	a1,s0,-56
    80005d4e:	fd040513          	add	a0,s0,-48
    80005d52:	fffff097          	auipc	ra,0xfffff
    80005d56:	dea080e7          	jalr	-534(ra) # 80004b3c <pipealloc>
    return -1;
    80005d5a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d5c:	0c054463          	bltz	a0,80005e24 <sys_pipe+0xfc>
  fd0 = -1;
    80005d60:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d64:	fd043503          	ld	a0,-48(s0)
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	524080e7          	jalr	1316(ra) # 8000528c <fdalloc>
    80005d70:	fca42223          	sw	a0,-60(s0)
    80005d74:	08054b63          	bltz	a0,80005e0a <sys_pipe+0xe2>
    80005d78:	fc843503          	ld	a0,-56(s0)
    80005d7c:	fffff097          	auipc	ra,0xfffff
    80005d80:	510080e7          	jalr	1296(ra) # 8000528c <fdalloc>
    80005d84:	fca42023          	sw	a0,-64(s0)
    80005d88:	06054863          	bltz	a0,80005df8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d8c:	4691                	li	a3,4
    80005d8e:	fc440613          	add	a2,s0,-60
    80005d92:	fd843583          	ld	a1,-40(s0)
    80005d96:	68a8                	ld	a0,80(s1)
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	8ce080e7          	jalr	-1842(ra) # 80001666 <copyout>
    80005da0:	02054063          	bltz	a0,80005dc0 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005da4:	4691                	li	a3,4
    80005da6:	fc040613          	add	a2,s0,-64
    80005daa:	fd843583          	ld	a1,-40(s0)
    80005dae:	0591                	add	a1,a1,4
    80005db0:	68a8                	ld	a0,80(s1)
    80005db2:	ffffc097          	auipc	ra,0xffffc
    80005db6:	8b4080e7          	jalr	-1868(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005dba:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dbc:	06055463          	bgez	a0,80005e24 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005dc0:	fc442783          	lw	a5,-60(s0)
    80005dc4:	07e9                	add	a5,a5,26
    80005dc6:	078e                	sll	a5,a5,0x3
    80005dc8:	97a6                	add	a5,a5,s1
    80005dca:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005dce:	fc042783          	lw	a5,-64(s0)
    80005dd2:	07e9                	add	a5,a5,26
    80005dd4:	078e                	sll	a5,a5,0x3
    80005dd6:	94be                	add	s1,s1,a5
    80005dd8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ddc:	fd043503          	ld	a0,-48(s0)
    80005de0:	fffff097          	auipc	ra,0xfffff
    80005de4:	a30080e7          	jalr	-1488(ra) # 80004810 <fileclose>
    fileclose(wf);
    80005de8:	fc843503          	ld	a0,-56(s0)
    80005dec:	fffff097          	auipc	ra,0xfffff
    80005df0:	a24080e7          	jalr	-1500(ra) # 80004810 <fileclose>
    return -1;
    80005df4:	57fd                	li	a5,-1
    80005df6:	a03d                	j	80005e24 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005df8:	fc442783          	lw	a5,-60(s0)
    80005dfc:	0007c763          	bltz	a5,80005e0a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005e00:	07e9                	add	a5,a5,26
    80005e02:	078e                	sll	a5,a5,0x3
    80005e04:	97a6                	add	a5,a5,s1
    80005e06:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005e0a:	fd043503          	ld	a0,-48(s0)
    80005e0e:	fffff097          	auipc	ra,0xfffff
    80005e12:	a02080e7          	jalr	-1534(ra) # 80004810 <fileclose>
    fileclose(wf);
    80005e16:	fc843503          	ld	a0,-56(s0)
    80005e1a:	fffff097          	auipc	ra,0xfffff
    80005e1e:	9f6080e7          	jalr	-1546(ra) # 80004810 <fileclose>
    return -1;
    80005e22:	57fd                	li	a5,-1
}
    80005e24:	853e                	mv	a0,a5
    80005e26:	70e2                	ld	ra,56(sp)
    80005e28:	7442                	ld	s0,48(sp)
    80005e2a:	74a2                	ld	s1,40(sp)
    80005e2c:	6121                	add	sp,sp,64
    80005e2e:	8082                	ret

0000000080005e30 <kernelvec>:
    80005e30:	7111                	add	sp,sp,-256
    80005e32:	e006                	sd	ra,0(sp)
    80005e34:	e40a                	sd	sp,8(sp)
    80005e36:	e80e                	sd	gp,16(sp)
    80005e38:	ec12                	sd	tp,24(sp)
    80005e3a:	f016                	sd	t0,32(sp)
    80005e3c:	f41a                	sd	t1,40(sp)
    80005e3e:	f81e                	sd	t2,48(sp)
    80005e40:	fc22                	sd	s0,56(sp)
    80005e42:	e0a6                	sd	s1,64(sp)
    80005e44:	e4aa                	sd	a0,72(sp)
    80005e46:	e8ae                	sd	a1,80(sp)
    80005e48:	ecb2                	sd	a2,88(sp)
    80005e4a:	f0b6                	sd	a3,96(sp)
    80005e4c:	f4ba                	sd	a4,104(sp)
    80005e4e:	f8be                	sd	a5,112(sp)
    80005e50:	fcc2                	sd	a6,120(sp)
    80005e52:	e146                	sd	a7,128(sp)
    80005e54:	e54a                	sd	s2,136(sp)
    80005e56:	e94e                	sd	s3,144(sp)
    80005e58:	ed52                	sd	s4,152(sp)
    80005e5a:	f156                	sd	s5,160(sp)
    80005e5c:	f55a                	sd	s6,168(sp)
    80005e5e:	f95e                	sd	s7,176(sp)
    80005e60:	fd62                	sd	s8,184(sp)
    80005e62:	e1e6                	sd	s9,192(sp)
    80005e64:	e5ea                	sd	s10,200(sp)
    80005e66:	e9ee                	sd	s11,208(sp)
    80005e68:	edf2                	sd	t3,216(sp)
    80005e6a:	f1f6                	sd	t4,224(sp)
    80005e6c:	f5fa                	sd	t5,232(sp)
    80005e6e:	f9fe                	sd	t6,240(sp)
    80005e70:	d95fc0ef          	jal	80002c04 <kerneltrap>
    80005e74:	6082                	ld	ra,0(sp)
    80005e76:	6122                	ld	sp,8(sp)
    80005e78:	61c2                	ld	gp,16(sp)
    80005e7a:	7282                	ld	t0,32(sp)
    80005e7c:	7322                	ld	t1,40(sp)
    80005e7e:	73c2                	ld	t2,48(sp)
    80005e80:	7462                	ld	s0,56(sp)
    80005e82:	6486                	ld	s1,64(sp)
    80005e84:	6526                	ld	a0,72(sp)
    80005e86:	65c6                	ld	a1,80(sp)
    80005e88:	6666                	ld	a2,88(sp)
    80005e8a:	7686                	ld	a3,96(sp)
    80005e8c:	7726                	ld	a4,104(sp)
    80005e8e:	77c6                	ld	a5,112(sp)
    80005e90:	7866                	ld	a6,120(sp)
    80005e92:	688a                	ld	a7,128(sp)
    80005e94:	692a                	ld	s2,136(sp)
    80005e96:	69ca                	ld	s3,144(sp)
    80005e98:	6a6a                	ld	s4,152(sp)
    80005e9a:	7a8a                	ld	s5,160(sp)
    80005e9c:	7b2a                	ld	s6,168(sp)
    80005e9e:	7bca                	ld	s7,176(sp)
    80005ea0:	7c6a                	ld	s8,184(sp)
    80005ea2:	6c8e                	ld	s9,192(sp)
    80005ea4:	6d2e                	ld	s10,200(sp)
    80005ea6:	6dce                	ld	s11,208(sp)
    80005ea8:	6e6e                	ld	t3,216(sp)
    80005eaa:	7e8e                	ld	t4,224(sp)
    80005eac:	7f2e                	ld	t5,232(sp)
    80005eae:	7fce                	ld	t6,240(sp)
    80005eb0:	6111                	add	sp,sp,256
    80005eb2:	10200073          	sret
    80005eb6:	00000013          	nop
    80005eba:	00000013          	nop
    80005ebe:	0001                	nop

0000000080005ec0 <timervec>:
    80005ec0:	34051573          	csrrw	a0,mscratch,a0
    80005ec4:	e10c                	sd	a1,0(a0)
    80005ec6:	e510                	sd	a2,8(a0)
    80005ec8:	e914                	sd	a3,16(a0)
    80005eca:	6d0c                	ld	a1,24(a0)
    80005ecc:	7110                	ld	a2,32(a0)
    80005ece:	6194                	ld	a3,0(a1)
    80005ed0:	96b2                	add	a3,a3,a2
    80005ed2:	e194                	sd	a3,0(a1)
    80005ed4:	4589                	li	a1,2
    80005ed6:	14459073          	csrw	sip,a1
    80005eda:	6914                	ld	a3,16(a0)
    80005edc:	6510                	ld	a2,8(a0)
    80005ede:	610c                	ld	a1,0(a0)
    80005ee0:	34051573          	csrrw	a0,mscratch,a0
    80005ee4:	30200073          	mret
	...

0000000080005eea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eea:	1141                	add	sp,sp,-16
    80005eec:	e422                	sd	s0,8(sp)
    80005eee:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ef0:	0c0007b7          	lui	a5,0xc000
    80005ef4:	4705                	li	a4,1
    80005ef6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ef8:	c3d8                	sw	a4,4(a5)
}
    80005efa:	6422                	ld	s0,8(sp)
    80005efc:	0141                	add	sp,sp,16
    80005efe:	8082                	ret

0000000080005f00 <plicinithart>:

void
plicinithart(void)
{
    80005f00:	1141                	add	sp,sp,-16
    80005f02:	e406                	sd	ra,8(sp)
    80005f04:	e022                	sd	s0,0(sp)
    80005f06:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005f08:	ffffc097          	auipc	ra,0xffffc
    80005f0c:	a72080e7          	jalr	-1422(ra) # 8000197a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f10:	0085171b          	sllw	a4,a0,0x8
    80005f14:	0c0027b7          	lui	a5,0xc002
    80005f18:	97ba                	add	a5,a5,a4
    80005f1a:	40200713          	li	a4,1026
    80005f1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f22:	00d5151b          	sllw	a0,a0,0xd
    80005f26:	0c2017b7          	lui	a5,0xc201
    80005f2a:	97aa                	add	a5,a5,a0
    80005f2c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005f30:	60a2                	ld	ra,8(sp)
    80005f32:	6402                	ld	s0,0(sp)
    80005f34:	0141                	add	sp,sp,16
    80005f36:	8082                	ret

0000000080005f38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f38:	1141                	add	sp,sp,-16
    80005f3a:	e406                	sd	ra,8(sp)
    80005f3c:	e022                	sd	s0,0(sp)
    80005f3e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005f40:	ffffc097          	auipc	ra,0xffffc
    80005f44:	a3a080e7          	jalr	-1478(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f48:	00d5151b          	sllw	a0,a0,0xd
    80005f4c:	0c2017b7          	lui	a5,0xc201
    80005f50:	97aa                	add	a5,a5,a0
  return irq;
}
    80005f52:	43c8                	lw	a0,4(a5)
    80005f54:	60a2                	ld	ra,8(sp)
    80005f56:	6402                	ld	s0,0(sp)
    80005f58:	0141                	add	sp,sp,16
    80005f5a:	8082                	ret

0000000080005f5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f5c:	1101                	add	sp,sp,-32
    80005f5e:	ec06                	sd	ra,24(sp)
    80005f60:	e822                	sd	s0,16(sp)
    80005f62:	e426                	sd	s1,8(sp)
    80005f64:	1000                	add	s0,sp,32
    80005f66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f68:	ffffc097          	auipc	ra,0xffffc
    80005f6c:	a12080e7          	jalr	-1518(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f70:	00d5151b          	sllw	a0,a0,0xd
    80005f74:	0c2017b7          	lui	a5,0xc201
    80005f78:	97aa                	add	a5,a5,a0
    80005f7a:	c3c4                	sw	s1,4(a5)
}
    80005f7c:	60e2                	ld	ra,24(sp)
    80005f7e:	6442                	ld	s0,16(sp)
    80005f80:	64a2                	ld	s1,8(sp)
    80005f82:	6105                	add	sp,sp,32
    80005f84:	8082                	ret

0000000080005f86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f86:	1141                	add	sp,sp,-16
    80005f88:	e406                	sd	ra,8(sp)
    80005f8a:	e022                	sd	s0,0(sp)
    80005f8c:	0800                	add	s0,sp,16
  if(i >= NUM)
    80005f8e:	479d                	li	a5,7
    80005f90:	04a7cc63          	blt	a5,a0,80005fe8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f94:	0001c797          	auipc	a5,0x1c
    80005f98:	0ec78793          	add	a5,a5,236 # 80022080 <disk>
    80005f9c:	97aa                	add	a5,a5,a0
    80005f9e:	0187c783          	lbu	a5,24(a5)
    80005fa2:	ebb9                	bnez	a5,80005ff8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005fa4:	00451693          	sll	a3,a0,0x4
    80005fa8:	0001c797          	auipc	a5,0x1c
    80005fac:	0d878793          	add	a5,a5,216 # 80022080 <disk>
    80005fb0:	6398                	ld	a4,0(a5)
    80005fb2:	9736                	add	a4,a4,a3
    80005fb4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005fb8:	6398                	ld	a4,0(a5)
    80005fba:	9736                	add	a4,a4,a3
    80005fbc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005fc0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005fc4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005fc8:	97aa                	add	a5,a5,a0
    80005fca:	4705                	li	a4,1
    80005fcc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005fd0:	0001c517          	auipc	a0,0x1c
    80005fd4:	0c850513          	add	a0,a0,200 # 80022098 <disk+0x18>
    80005fd8:	ffffc097          	auipc	ra,0xffffc
    80005fdc:	186080e7          	jalr	390(ra) # 8000215e <wakeup>
}
    80005fe0:	60a2                	ld	ra,8(sp)
    80005fe2:	6402                	ld	s0,0(sp)
    80005fe4:	0141                	add	sp,sp,16
    80005fe6:	8082                	ret
    panic("free_desc 1");
    80005fe8:	00002517          	auipc	a0,0x2
    80005fec:	7d850513          	add	a0,a0,2008 # 800087c0 <syscalls+0x308>
    80005ff0:	ffffa097          	auipc	ra,0xffffa
    80005ff4:	54c080e7          	jalr	1356(ra) # 8000053c <panic>
    panic("free_desc 2");
    80005ff8:	00002517          	auipc	a0,0x2
    80005ffc:	7d850513          	add	a0,a0,2008 # 800087d0 <syscalls+0x318>
    80006000:	ffffa097          	auipc	ra,0xffffa
    80006004:	53c080e7          	jalr	1340(ra) # 8000053c <panic>

0000000080006008 <virtio_disk_init>:
{
    80006008:	1101                	add	sp,sp,-32
    8000600a:	ec06                	sd	ra,24(sp)
    8000600c:	e822                	sd	s0,16(sp)
    8000600e:	e426                	sd	s1,8(sp)
    80006010:	e04a                	sd	s2,0(sp)
    80006012:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006014:	00002597          	auipc	a1,0x2
    80006018:	7cc58593          	add	a1,a1,1996 # 800087e0 <syscalls+0x328>
    8000601c:	0001c517          	auipc	a0,0x1c
    80006020:	18c50513          	add	a0,a0,396 # 800221a8 <disk+0x128>
    80006024:	ffffb097          	auipc	ra,0xffffb
    80006028:	b1e080e7          	jalr	-1250(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000602c:	100017b7          	lui	a5,0x10001
    80006030:	4398                	lw	a4,0(a5)
    80006032:	2701                	sext.w	a4,a4
    80006034:	747277b7          	lui	a5,0x74727
    80006038:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000603c:	14f71b63          	bne	a4,a5,80006192 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006040:	100017b7          	lui	a5,0x10001
    80006044:	43dc                	lw	a5,4(a5)
    80006046:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006048:	4709                	li	a4,2
    8000604a:	14e79463          	bne	a5,a4,80006192 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000604e:	100017b7          	lui	a5,0x10001
    80006052:	479c                	lw	a5,8(a5)
    80006054:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006056:	12e79e63          	bne	a5,a4,80006192 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000605a:	100017b7          	lui	a5,0x10001
    8000605e:	47d8                	lw	a4,12(a5)
    80006060:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006062:	554d47b7          	lui	a5,0x554d4
    80006066:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000606a:	12f71463          	bne	a4,a5,80006192 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000606e:	100017b7          	lui	a5,0x10001
    80006072:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006076:	4705                	li	a4,1
    80006078:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607a:	470d                	li	a4,3
    8000607c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000607e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006080:	c7ffe6b7          	lui	a3,0xc7ffe
    80006084:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd83ff>
    80006088:	8f75                	and	a4,a4,a3
    8000608a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000608c:	472d                	li	a4,11
    8000608e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006090:	5bbc                	lw	a5,112(a5)
    80006092:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006096:	8ba1                	and	a5,a5,8
    80006098:	10078563          	beqz	a5,800061a2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000609c:	100017b7          	lui	a5,0x10001
    800060a0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800060a4:	43fc                	lw	a5,68(a5)
    800060a6:	2781                	sext.w	a5,a5
    800060a8:	10079563          	bnez	a5,800061b2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060ac:	100017b7          	lui	a5,0x10001
    800060b0:	5bdc                	lw	a5,52(a5)
    800060b2:	2781                	sext.w	a5,a5
  if(max == 0)
    800060b4:	10078763          	beqz	a5,800061c2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800060b8:	471d                	li	a4,7
    800060ba:	10f77c63          	bgeu	a4,a5,800061d2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800060be:	ffffb097          	auipc	ra,0xffffb
    800060c2:	a24080e7          	jalr	-1500(ra) # 80000ae2 <kalloc>
    800060c6:	0001c497          	auipc	s1,0x1c
    800060ca:	fba48493          	add	s1,s1,-70 # 80022080 <disk>
    800060ce:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800060d0:	ffffb097          	auipc	ra,0xffffb
    800060d4:	a12080e7          	jalr	-1518(ra) # 80000ae2 <kalloc>
    800060d8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800060da:	ffffb097          	auipc	ra,0xffffb
    800060de:	a08080e7          	jalr	-1528(ra) # 80000ae2 <kalloc>
    800060e2:	87aa                	mv	a5,a0
    800060e4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800060e6:	6088                	ld	a0,0(s1)
    800060e8:	cd6d                	beqz	a0,800061e2 <virtio_disk_init+0x1da>
    800060ea:	0001c717          	auipc	a4,0x1c
    800060ee:	f9e73703          	ld	a4,-98(a4) # 80022088 <disk+0x8>
    800060f2:	cb65                	beqz	a4,800061e2 <virtio_disk_init+0x1da>
    800060f4:	c7fd                	beqz	a5,800061e2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800060f6:	6605                	lui	a2,0x1
    800060f8:	4581                	li	a1,0
    800060fa:	ffffb097          	auipc	ra,0xffffb
    800060fe:	bd4080e7          	jalr	-1068(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80006102:	0001c497          	auipc	s1,0x1c
    80006106:	f7e48493          	add	s1,s1,-130 # 80022080 <disk>
    8000610a:	6605                	lui	a2,0x1
    8000610c:	4581                	li	a1,0
    8000610e:	6488                	ld	a0,8(s1)
    80006110:	ffffb097          	auipc	ra,0xffffb
    80006114:	bbe080e7          	jalr	-1090(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006118:	6605                	lui	a2,0x1
    8000611a:	4581                	li	a1,0
    8000611c:	6888                	ld	a0,16(s1)
    8000611e:	ffffb097          	auipc	ra,0xffffb
    80006122:	bb0080e7          	jalr	-1104(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006126:	100017b7          	lui	a5,0x10001
    8000612a:	4721                	li	a4,8
    8000612c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000612e:	4098                	lw	a4,0(s1)
    80006130:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006134:	40d8                	lw	a4,4(s1)
    80006136:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000613a:	6498                	ld	a4,8(s1)
    8000613c:	0007069b          	sext.w	a3,a4
    80006140:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006144:	9701                	sra	a4,a4,0x20
    80006146:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000614a:	6898                	ld	a4,16(s1)
    8000614c:	0007069b          	sext.w	a3,a4
    80006150:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006154:	9701                	sra	a4,a4,0x20
    80006156:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000615a:	4705                	li	a4,1
    8000615c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000615e:	00e48c23          	sb	a4,24(s1)
    80006162:	00e48ca3          	sb	a4,25(s1)
    80006166:	00e48d23          	sb	a4,26(s1)
    8000616a:	00e48da3          	sb	a4,27(s1)
    8000616e:	00e48e23          	sb	a4,28(s1)
    80006172:	00e48ea3          	sb	a4,29(s1)
    80006176:	00e48f23          	sb	a4,30(s1)
    8000617a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000617e:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006182:	0727a823          	sw	s2,112(a5)
}
    80006186:	60e2                	ld	ra,24(sp)
    80006188:	6442                	ld	s0,16(sp)
    8000618a:	64a2                	ld	s1,8(sp)
    8000618c:	6902                	ld	s2,0(sp)
    8000618e:	6105                	add	sp,sp,32
    80006190:	8082                	ret
    panic("could not find virtio disk");
    80006192:	00002517          	auipc	a0,0x2
    80006196:	65e50513          	add	a0,a0,1630 # 800087f0 <syscalls+0x338>
    8000619a:	ffffa097          	auipc	ra,0xffffa
    8000619e:	3a2080e7          	jalr	930(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800061a2:	00002517          	auipc	a0,0x2
    800061a6:	66e50513          	add	a0,a0,1646 # 80008810 <syscalls+0x358>
    800061aa:	ffffa097          	auipc	ra,0xffffa
    800061ae:	392080e7          	jalr	914(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800061b2:	00002517          	auipc	a0,0x2
    800061b6:	67e50513          	add	a0,a0,1662 # 80008830 <syscalls+0x378>
    800061ba:	ffffa097          	auipc	ra,0xffffa
    800061be:	382080e7          	jalr	898(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800061c2:	00002517          	auipc	a0,0x2
    800061c6:	68e50513          	add	a0,a0,1678 # 80008850 <syscalls+0x398>
    800061ca:	ffffa097          	auipc	ra,0xffffa
    800061ce:	372080e7          	jalr	882(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800061d2:	00002517          	auipc	a0,0x2
    800061d6:	69e50513          	add	a0,a0,1694 # 80008870 <syscalls+0x3b8>
    800061da:	ffffa097          	auipc	ra,0xffffa
    800061de:	362080e7          	jalr	866(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800061e2:	00002517          	auipc	a0,0x2
    800061e6:	6ae50513          	add	a0,a0,1710 # 80008890 <syscalls+0x3d8>
    800061ea:	ffffa097          	auipc	ra,0xffffa
    800061ee:	352080e7          	jalr	850(ra) # 8000053c <panic>

00000000800061f2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061f2:	7159                	add	sp,sp,-112
    800061f4:	f486                	sd	ra,104(sp)
    800061f6:	f0a2                	sd	s0,96(sp)
    800061f8:	eca6                	sd	s1,88(sp)
    800061fa:	e8ca                	sd	s2,80(sp)
    800061fc:	e4ce                	sd	s3,72(sp)
    800061fe:	e0d2                	sd	s4,64(sp)
    80006200:	fc56                	sd	s5,56(sp)
    80006202:	f85a                	sd	s6,48(sp)
    80006204:	f45e                	sd	s7,40(sp)
    80006206:	f062                	sd	s8,32(sp)
    80006208:	ec66                	sd	s9,24(sp)
    8000620a:	e86a                	sd	s10,16(sp)
    8000620c:	1880                	add	s0,sp,112
    8000620e:	8a2a                	mv	s4,a0
    80006210:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006212:	00c52c83          	lw	s9,12(a0)
    80006216:	001c9c9b          	sllw	s9,s9,0x1
    8000621a:	1c82                	sll	s9,s9,0x20
    8000621c:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006220:	0001c517          	auipc	a0,0x1c
    80006224:	f8850513          	add	a0,a0,-120 # 800221a8 <disk+0x128>
    80006228:	ffffb097          	auipc	ra,0xffffb
    8000622c:	9aa080e7          	jalr	-1622(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006230:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006232:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006234:	0001cb17          	auipc	s6,0x1c
    80006238:	e4cb0b13          	add	s6,s6,-436 # 80022080 <disk>
  for(int i = 0; i < 3; i++){
    8000623c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000623e:	0001cc17          	auipc	s8,0x1c
    80006242:	f6ac0c13          	add	s8,s8,-150 # 800221a8 <disk+0x128>
    80006246:	a095                	j	800062aa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006248:	00fb0733          	add	a4,s6,a5
    8000624c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006250:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006252:	0207c563          	bltz	a5,8000627c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006256:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006258:	0591                	add	a1,a1,4
    8000625a:	05560d63          	beq	a2,s5,800062b4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000625e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006260:	0001c717          	auipc	a4,0x1c
    80006264:	e2070713          	add	a4,a4,-480 # 80022080 <disk>
    80006268:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000626a:	01874683          	lbu	a3,24(a4)
    8000626e:	fee9                	bnez	a3,80006248 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006270:	2785                	addw	a5,a5,1
    80006272:	0705                	add	a4,a4,1
    80006274:	fe979be3          	bne	a5,s1,8000626a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006278:	57fd                	li	a5,-1
    8000627a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000627c:	00c05e63          	blez	a2,80006298 <virtio_disk_rw+0xa6>
    80006280:	060a                	sll	a2,a2,0x2
    80006282:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006286:	0009a503          	lw	a0,0(s3)
    8000628a:	00000097          	auipc	ra,0x0
    8000628e:	cfc080e7          	jalr	-772(ra) # 80005f86 <free_desc>
      for(int j = 0; j < i; j++)
    80006292:	0991                	add	s3,s3,4
    80006294:	ffa999e3          	bne	s3,s10,80006286 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006298:	85e2                	mv	a1,s8
    8000629a:	0001c517          	auipc	a0,0x1c
    8000629e:	dfe50513          	add	a0,a0,-514 # 80022098 <disk+0x18>
    800062a2:	ffffc097          	auipc	ra,0xffffc
    800062a6:	e58080e7          	jalr	-424(ra) # 800020fa <sleep>
  for(int i = 0; i < 3; i++){
    800062aa:	f9040993          	add	s3,s0,-112
{
    800062ae:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800062b0:	864a                	mv	a2,s2
    800062b2:	b775                	j	8000625e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062b4:	f9042503          	lw	a0,-112(s0)
    800062b8:	00a50713          	add	a4,a0,10
    800062bc:	0712                	sll	a4,a4,0x4

  if(write)
    800062be:	0001c797          	auipc	a5,0x1c
    800062c2:	dc278793          	add	a5,a5,-574 # 80022080 <disk>
    800062c6:	00e786b3          	add	a3,a5,a4
    800062ca:	01703633          	snez	a2,s7
    800062ce:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062d0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800062d4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062d8:	f6070613          	add	a2,a4,-160
    800062dc:	6394                	ld	a3,0(a5)
    800062de:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062e0:	00870593          	add	a1,a4,8
    800062e4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062e6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062e8:	0007b803          	ld	a6,0(a5)
    800062ec:	9642                	add	a2,a2,a6
    800062ee:	46c1                	li	a3,16
    800062f0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062f2:	4585                	li	a1,1
    800062f4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800062f8:	f9442683          	lw	a3,-108(s0)
    800062fc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006300:	0692                	sll	a3,a3,0x4
    80006302:	9836                	add	a6,a6,a3
    80006304:	058a0613          	add	a2,s4,88
    80006308:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000630c:	0007b803          	ld	a6,0(a5)
    80006310:	96c2                	add	a3,a3,a6
    80006312:	40000613          	li	a2,1024
    80006316:	c690                	sw	a2,8(a3)
  if(write)
    80006318:	001bb613          	seqz	a2,s7
    8000631c:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006320:	00166613          	or	a2,a2,1
    80006324:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006328:	f9842603          	lw	a2,-104(s0)
    8000632c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006330:	00250693          	add	a3,a0,2
    80006334:	0692                	sll	a3,a3,0x4
    80006336:	96be                	add	a3,a3,a5
    80006338:	58fd                	li	a7,-1
    8000633a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000633e:	0612                	sll	a2,a2,0x4
    80006340:	9832                	add	a6,a6,a2
    80006342:	f9070713          	add	a4,a4,-112
    80006346:	973e                	add	a4,a4,a5
    80006348:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000634c:	6398                	ld	a4,0(a5)
    8000634e:	9732                	add	a4,a4,a2
    80006350:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006352:	4609                	li	a2,2
    80006354:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006358:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000635c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006360:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006364:	6794                	ld	a3,8(a5)
    80006366:	0026d703          	lhu	a4,2(a3)
    8000636a:	8b1d                	and	a4,a4,7
    8000636c:	0706                	sll	a4,a4,0x1
    8000636e:	96ba                	add	a3,a3,a4
    80006370:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006374:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006378:	6798                	ld	a4,8(a5)
    8000637a:	00275783          	lhu	a5,2(a4)
    8000637e:	2785                	addw	a5,a5,1
    80006380:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006384:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006388:	100017b7          	lui	a5,0x10001
    8000638c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006390:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006394:	0001c917          	auipc	s2,0x1c
    80006398:	e1490913          	add	s2,s2,-492 # 800221a8 <disk+0x128>
  while(b->disk == 1) {
    8000639c:	4485                	li	s1,1
    8000639e:	00b79c63          	bne	a5,a1,800063b6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800063a2:	85ca                	mv	a1,s2
    800063a4:	8552                	mv	a0,s4
    800063a6:	ffffc097          	auipc	ra,0xffffc
    800063aa:	d54080e7          	jalr	-684(ra) # 800020fa <sleep>
  while(b->disk == 1) {
    800063ae:	004a2783          	lw	a5,4(s4)
    800063b2:	fe9788e3          	beq	a5,s1,800063a2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800063b6:	f9042903          	lw	s2,-112(s0)
    800063ba:	00290713          	add	a4,s2,2
    800063be:	0712                	sll	a4,a4,0x4
    800063c0:	0001c797          	auipc	a5,0x1c
    800063c4:	cc078793          	add	a5,a5,-832 # 80022080 <disk>
    800063c8:	97ba                	add	a5,a5,a4
    800063ca:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800063ce:	0001c997          	auipc	s3,0x1c
    800063d2:	cb298993          	add	s3,s3,-846 # 80022080 <disk>
    800063d6:	00491713          	sll	a4,s2,0x4
    800063da:	0009b783          	ld	a5,0(s3)
    800063de:	97ba                	add	a5,a5,a4
    800063e0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063e4:	854a                	mv	a0,s2
    800063e6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063ea:	00000097          	auipc	ra,0x0
    800063ee:	b9c080e7          	jalr	-1124(ra) # 80005f86 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063f2:	8885                	and	s1,s1,1
    800063f4:	f0ed                	bnez	s1,800063d6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063f6:	0001c517          	auipc	a0,0x1c
    800063fa:	db250513          	add	a0,a0,-590 # 800221a8 <disk+0x128>
    800063fe:	ffffb097          	auipc	ra,0xffffb
    80006402:	888080e7          	jalr	-1912(ra) # 80000c86 <release>
}
    80006406:	70a6                	ld	ra,104(sp)
    80006408:	7406                	ld	s0,96(sp)
    8000640a:	64e6                	ld	s1,88(sp)
    8000640c:	6946                	ld	s2,80(sp)
    8000640e:	69a6                	ld	s3,72(sp)
    80006410:	6a06                	ld	s4,64(sp)
    80006412:	7ae2                	ld	s5,56(sp)
    80006414:	7b42                	ld	s6,48(sp)
    80006416:	7ba2                	ld	s7,40(sp)
    80006418:	7c02                	ld	s8,32(sp)
    8000641a:	6ce2                	ld	s9,24(sp)
    8000641c:	6d42                	ld	s10,16(sp)
    8000641e:	6165                	add	sp,sp,112
    80006420:	8082                	ret

0000000080006422 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006422:	1101                	add	sp,sp,-32
    80006424:	ec06                	sd	ra,24(sp)
    80006426:	e822                	sd	s0,16(sp)
    80006428:	e426                	sd	s1,8(sp)
    8000642a:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000642c:	0001c497          	auipc	s1,0x1c
    80006430:	c5448493          	add	s1,s1,-940 # 80022080 <disk>
    80006434:	0001c517          	auipc	a0,0x1c
    80006438:	d7450513          	add	a0,a0,-652 # 800221a8 <disk+0x128>
    8000643c:	ffffa097          	auipc	ra,0xffffa
    80006440:	796080e7          	jalr	1942(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006444:	10001737          	lui	a4,0x10001
    80006448:	533c                	lw	a5,96(a4)
    8000644a:	8b8d                	and	a5,a5,3
    8000644c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000644e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006452:	689c                	ld	a5,16(s1)
    80006454:	0204d703          	lhu	a4,32(s1)
    80006458:	0027d783          	lhu	a5,2(a5)
    8000645c:	04f70863          	beq	a4,a5,800064ac <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006460:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006464:	6898                	ld	a4,16(s1)
    80006466:	0204d783          	lhu	a5,32(s1)
    8000646a:	8b9d                	and	a5,a5,7
    8000646c:	078e                	sll	a5,a5,0x3
    8000646e:	97ba                	add	a5,a5,a4
    80006470:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006472:	00278713          	add	a4,a5,2
    80006476:	0712                	sll	a4,a4,0x4
    80006478:	9726                	add	a4,a4,s1
    8000647a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000647e:	e721                	bnez	a4,800064c6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006480:	0789                	add	a5,a5,2
    80006482:	0792                	sll	a5,a5,0x4
    80006484:	97a6                	add	a5,a5,s1
    80006486:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006488:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000648c:	ffffc097          	auipc	ra,0xffffc
    80006490:	cd2080e7          	jalr	-814(ra) # 8000215e <wakeup>

    disk.used_idx += 1;
    80006494:	0204d783          	lhu	a5,32(s1)
    80006498:	2785                	addw	a5,a5,1
    8000649a:	17c2                	sll	a5,a5,0x30
    8000649c:	93c1                	srl	a5,a5,0x30
    8000649e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064a2:	6898                	ld	a4,16(s1)
    800064a4:	00275703          	lhu	a4,2(a4)
    800064a8:	faf71ce3          	bne	a4,a5,80006460 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800064ac:	0001c517          	auipc	a0,0x1c
    800064b0:	cfc50513          	add	a0,a0,-772 # 800221a8 <disk+0x128>
    800064b4:	ffffa097          	auipc	ra,0xffffa
    800064b8:	7d2080e7          	jalr	2002(ra) # 80000c86 <release>
}
    800064bc:	60e2                	ld	ra,24(sp)
    800064be:	6442                	ld	s0,16(sp)
    800064c0:	64a2                	ld	s1,8(sp)
    800064c2:	6105                	add	sp,sp,32
    800064c4:	8082                	ret
      panic("virtio_disk_intr status");
    800064c6:	00002517          	auipc	a0,0x2
    800064ca:	3e250513          	add	a0,a0,994 # 800088a8 <syscalls+0x3f0>
    800064ce:	ffffa097          	auipc	ra,0xffffa
    800064d2:	06e080e7          	jalr	110(ra) # 8000053c <panic>

00000000800064d6 <ran_array>:
long ran_x[KK];
long aa[2000];
int rand_index = 0;
void main();
void ran_array(long aa[], int n)
{
    800064d6:	1141                	add	sp,sp,-16
    800064d8:	e422                	sd	s0,8(sp)
    800064da:	0800                	add	s0,sp,16
    register int i, j;
    for (j = 0; j < KK; j++)
    800064dc:	0001c897          	auipc	a7,0x1c
    800064e0:	ce488893          	add	a7,a7,-796 # 800221c0 <ran_x>
    800064e4:	882a                	mv	a6,a0
    800064e6:	0001c617          	auipc	a2,0x1c
    800064ea:	ffa60613          	add	a2,a2,-6 # 800224e0 <aa>
{
    800064ee:	872a                	mv	a4,a0
    800064f0:	87c6                	mv	a5,a7
        aa[j] = ran_x[j];
    800064f2:	6394                	ld	a3,0(a5)
    800064f4:	e314                	sd	a3,0(a4)
    for (j = 0; j < KK; j++)
    800064f6:	07a1                	add	a5,a5,8
    800064f8:	0721                	add	a4,a4,8
    800064fa:	fec79ce3          	bne	a5,a2,800064f2 <ran_array+0x1c>
    for (; j < n; j++)
    800064fe:	06400793          	li	a5,100
    80006502:	08b7d863          	bge	a5,a1,80006592 <ran_array+0xbc>
    80006506:	f9b5869b          	addw	a3,a1,-101
    8000650a:	02069793          	sll	a5,a3,0x20
    8000650e:	01d7d693          	srl	a3,a5,0x1d
    80006512:	00850793          	add	a5,a0,8
    80006516:	96be                	add	a3,a3,a5
        aa[j] = mod_diff(aa[j - KK], aa[j - LL]);
    80006518:	40000637          	lui	a2,0x40000
    8000651c:	167d                	add	a2,a2,-1 # 3fffffff <_entry-0x40000001>
    8000651e:	00083783          	ld	a5,0(a6)
    80006522:	1f883703          	ld	a4,504(a6)
    80006526:	8f99                	sub	a5,a5,a4
    80006528:	8ff1                	and	a5,a5,a2
    8000652a:	32f83023          	sd	a5,800(a6)
    for (; j < n; j++)
    8000652e:	0821                	add	a6,a6,8
    80006530:	fed817e3          	bne	a6,a3,8000651e <ran_array+0x48>
    for (i = 0; i < LL; i++, j++)
    80006534:	00359313          	sll	t1,a1,0x3
    80006538:	ce030713          	add	a4,t1,-800
    8000653c:	972a                	add	a4,a4,a0
    8000653e:	0001c817          	auipc	a6,0x1c
    80006542:	daa80813          	add	a6,a6,-598 # 800222e8 <ran_x+0x128>
    for (j = 0; j < KK; j++)
    80006546:	86c6                	mv	a3,a7
        ran_x[i] = mod_diff(aa[j - KK], aa[j - LL]);
    80006548:	400005b7          	lui	a1,0x40000
    8000654c:	15fd                	add	a1,a1,-1 # 3fffffff <_entry-0x40000001>
    8000654e:	631c                	ld	a5,0(a4)
    80006550:	1f873603          	ld	a2,504(a4)
    80006554:	8f91                	sub	a5,a5,a2
    80006556:	8fed                	and	a5,a5,a1
    80006558:	e29c                	sd	a5,0(a3)
    for (i = 0; i < LL; i++, j++)
    8000655a:	0721                	add	a4,a4,8
    8000655c:	06a1                	add	a3,a3,8
    8000655e:	ff0698e3          	bne	a3,a6,8000654e <ran_array+0x78>
    for (; i < KK; i++, j++)
    80006562:	e0830593          	add	a1,t1,-504
    80006566:	952e                	add	a0,a0,a1
    80006568:	0001c617          	auipc	a2,0x1c
    8000656c:	e5060613          	add	a2,a2,-432 # 800223b8 <ran_x+0x1f8>
        ran_x[i] = mod_diff(aa[j - KK], ran_x[i - LL]);
    80006570:	400006b7          	lui	a3,0x40000
    80006574:	16fd                	add	a3,a3,-1 # 3fffffff <_entry-0x40000001>
    80006576:	611c                	ld	a5,0(a0)
    80006578:	0008b703          	ld	a4,0(a7)
    8000657c:	8f99                	sub	a5,a5,a4
    8000657e:	8ff5                	and	a5,a5,a3
    80006580:	12f8b423          	sd	a5,296(a7)
    for (; i < KK; i++, j++)
    80006584:	0521                	add	a0,a0,8
    80006586:	08a1                	add	a7,a7,8
    80006588:	fec897e3          	bne	a7,a2,80006576 <ran_array+0xa0>
}
    8000658c:	6422                	ld	s0,8(sp)
    8000658e:	0141                	add	sp,sp,16
    80006590:	8082                	ret
    for (j = 0; j < KK; j++)
    80006592:	06400593          	li	a1,100
    80006596:	bf79                	j	80006534 <ran_array+0x5e>

0000000080006598 <ran_start>:
void ran_start(int seed)
{
    80006598:	9b010113          	add	sp,sp,-1616
    8000659c:	64113423          	sd	ra,1608(sp)
    800065a0:	64813023          	sd	s0,1600(sp)
    800065a4:	65010413          	add	s0,sp,1616
    800065a8:	882a                	mv	a6,a0
    register int t, j;
    long x[KK + KK - 1];
    register long ss = evenize(seed + 2);
    800065aa:	0025079b          	addw	a5,a0,2
    800065ae:	40000737          	lui	a4,0x40000
    800065b2:	1779                	add	a4,a4,-2 # 3ffffffe <_entry-0x40000002>
    800065b4:	8ff9                	and	a5,a5,a4
    800065b6:	2781                	sext.w	a5,a5
    for (j = 0; j < KK; j++)
    800065b8:	9b840613          	add	a2,s0,-1608
    800065bc:	cd840593          	add	a1,s0,-808
    register long ss = evenize(seed + 2);
    800065c0:	8732                	mv	a4,a2
    {
        x[j] = ss;
        ss <<= 1;
        if (ss >= MM)
    800065c2:	400006b7          	lui	a3,0x40000
            ss -= MM - 2;
    800065c6:	c0000537          	lui	a0,0xc0000
    800065ca:	0509                	add	a0,a0,2 # ffffffffc0000002 <end+0xffffffff3ffd9ca2>
    800065cc:	a021                	j	800065d4 <ran_start+0x3c>
    for (j = 0; j < KK; j++)
    800065ce:	0721                	add	a4,a4,8
    800065d0:	00b70863          	beq	a4,a1,800065e0 <ran_start+0x48>
        x[j] = ss;
    800065d4:	e31c                	sd	a5,0(a4)
        ss <<= 1;
    800065d6:	0786                	sll	a5,a5,0x1
        if (ss >= MM)
    800065d8:	fed7cbe3          	blt	a5,a3,800065ce <ran_start+0x36>
            ss -= MM - 2;
    800065dc:	97aa                	add	a5,a5,a0
    800065de:	bfc5                	j	800065ce <ran_start+0x36>
    }
    for (; j < KK + KK - 1; j++)
    800065e0:	cd840793          	add	a5,s0,-808
    800065e4:	63860713          	add	a4,a2,1592
        x[j] = 0;
    800065e8:	0007b023          	sd	zero,0(a5)
    for (; j < KK + KK - 1; j++)
    800065ec:	07a1                	add	a5,a5,8
    800065ee:	fee79de3          	bne	a5,a4,800065e8 <ran_start+0x50>
    x[1]++;
    800065f2:	9c043783          	ld	a5,-1600(s0)
    800065f6:	0785                	add	a5,a5,1
    800065f8:	9cf43023          	sd	a5,-1600(s0)
    ss = seed & (MM - 1);
    800065fc:	180a                	sll	a6,a6,0x22
    800065fe:	02285e13          	srl	t3,a6,0x22
    t = TT - 1;
    80006602:	04500e93          	li	t4,69
    80006606:	1f060313          	add	t1,a2,496
    while (t)
    {
        for (j = KK - 1; j > 0; j--)
            x[j + j] = x[j];
        for (j = KK + KK - 2; j > KK - LL; j -= 2)
            x[KK + KK - 1 - j] = evenize(x[j]);
    8000660a:	40000837          	lui	a6,0x40000
    8000660e:	ffe80893          	add	a7,a6,-2 # 3ffffffe <_entry-0x40000002>
        for (j = KK + KK - 2; j >= KK; j--)
            if (is_odd(x[j]))
            {
                x[j - (KK - LL)] = mod_diff(x[j - (KK - LL)], x[j]);
    80006612:	187d                	add	a6,a6,-1
    80006614:	a885                	j	80006684 <ran_start+0xec>
        for (j = KK + KK - 2; j >= KK; j--)
    80006616:	ff878713          	add	a4,a5,-8
    8000661a:	02c78563          	beq	a5,a2,80006644 <ran_start+0xac>
    8000661e:	87ba                	mv	a5,a4
            if (is_odd(x[j]))
    80006620:	3207b683          	ld	a3,800(a5)
    80006624:	0016f713          	and	a4,a3,1
    80006628:	d77d                	beqz	a4,80006616 <ran_start+0x7e>
                x[j - (KK - LL)] = mod_diff(x[j - (KK - LL)], x[j]);
    8000662a:	1287b703          	ld	a4,296(a5)
    8000662e:	8f15                	sub	a4,a4,a3
    80006630:	01077733          	and	a4,a4,a6
    80006634:	12e7b423          	sd	a4,296(a5)
                x[j - KK] = mod_diff(x[j - KK], x[j]);
    80006638:	6398                	ld	a4,0(a5)
    8000663a:	8f15                	sub	a4,a4,a3
    8000663c:	01077733          	and	a4,a4,a6
    80006640:	e398                	sd	a4,0(a5)
    80006642:	bfd1                	j	80006616 <ran_start+0x7e>
            }
        if (is_odd(ss))
    80006644:	001e7793          	and	a5,t3,1
    80006648:	e789                	bnez	a5,80006652 <ran_start+0xba>
                x[j] = x[j - 1];
            x[0] = x[KK];
            if (is_odd(x[KK]))
                x[LL] = mod_diff(x[LL], x[KK]);
        }
        if (ss)
    8000664a:	020e1963          	bnez	t3,8000667c <ran_start+0xe4>
            ss >>= 1;
        else
            t--;
    8000664e:	3efd                	addw	t4,t4,-1
    80006650:	a805                	j	80006680 <ran_start+0xe8>
                x[j] = x[j - 1];
    80006652:	87aa                	mv	a5,a0
    80006654:	6118                	ld	a4,0(a0)
    80006656:	e518                	sd	a4,8(a0)
            for (j = KK; j > 0; j--)
    80006658:	1561                	add	a0,a0,-8
    8000665a:	fec79ce3          	bne	a5,a2,80006652 <ran_start+0xba>
            x[0] = x[KK];
    8000665e:	cd843783          	ld	a5,-808(s0)
    80006662:	9af43c23          	sd	a5,-1608(s0)
            if (is_odd(x[KK]))
    80006666:	0017f713          	and	a4,a5,1
    8000666a:	cb09                	beqz	a4,8000667c <ran_start+0xe4>
                x[LL] = mod_diff(x[LL], x[KK]);
    8000666c:	ae043703          	ld	a4,-1312(s0)
    80006670:	40f707b3          	sub	a5,a4,a5
    80006674:	0107f7b3          	and	a5,a5,a6
    80006678:	aef43023          	sd	a5,-1312(s0)
            ss >>= 1;
    8000667c:	401e5e13          	sra	t3,t3,0x1
    while (t)
    80006680:	020e8b63          	beqz	t4,800066b6 <ran_start+0x11e>
        for (j = KK - 1; j > 0; j--)
    80006684:	cd040513          	add	a0,s0,-816
    80006688:	fe840693          	add	a3,s0,-24
    register long ss = evenize(seed + 2);
    8000668c:	87b6                	mv	a5,a3
    8000668e:	872a                	mv	a4,a0
            x[j + j] = x[j];
    80006690:	630c                	ld	a1,0(a4)
    80006692:	e38c                	sd	a1,0(a5)
        for (j = KK - 1; j > 0; j--)
    80006694:	1761                	add	a4,a4,-8
    80006696:	17c1                	add	a5,a5,-16
    80006698:	fec79ce3          	bne	a5,a2,80006690 <ran_start+0xf8>
    8000669c:	9c040713          	add	a4,s0,-1600
            x[KK + KK - 1 - j] = evenize(x[j]);
    800066a0:	629c                	ld	a5,0(a3)
    800066a2:	0117f7b3          	and	a5,a5,a7
    800066a6:	e31c                	sd	a5,0(a4)
        for (j = KK + KK - 2; j > KK - LL; j -= 2)
    800066a8:	16c1                	add	a3,a3,-16 # 3ffffff0 <_entry-0x40000010>
    800066aa:	0741                	add	a4,a4,16
    800066ac:	fe669ae3          	bne	a3,t1,800066a0 <ran_start+0x108>
    800066b0:	cc840793          	add	a5,s0,-824
    800066b4:	b7b5                	j	80006620 <ran_start+0x88>
    800066b6:	0001c797          	auipc	a5,0x1c
    800066ba:	d0278793          	add	a5,a5,-766 # 800223b8 <ran_x+0x1f8>
    800066be:	12860693          	add	a3,a2,296
    }
    for (j = 0; j < LL; j++)
        ran_x[j + KK - LL] = x[j];
    800066c2:	6218                	ld	a4,0(a2)
    800066c4:	e398                	sd	a4,0(a5)
    for (j = 0; j < LL; j++)
    800066c6:	0621                	add	a2,a2,8
    800066c8:	07a1                	add	a5,a5,8
    800066ca:	fec69ce3          	bne	a3,a2,800066c2 <ran_start+0x12a>
    for (; j < KK; j++)
    800066ce:	ae040713          	add	a4,s0,-1312
    800066d2:	0001c797          	auipc	a5,0x1c
    800066d6:	aee78793          	add	a5,a5,-1298 # 800221c0 <ran_x>
    800066da:	0001c617          	auipc	a2,0x1c
    800066de:	cde60613          	add	a2,a2,-802 # 800223b8 <ran_x+0x1f8>
        ran_x[j - LL] = x[j];
    800066e2:	6314                	ld	a3,0(a4)
    800066e4:	e394                	sd	a3,0(a5)
    for (; j < KK; j++)
    800066e6:	0721                	add	a4,a4,8
    800066e8:	07a1                	add	a5,a5,8
    800066ea:	fec79ce3          	bne	a5,a2,800066e2 <ran_start+0x14a>
    ran_array(aa, 1009);
    800066ee:	3f100593          	li	a1,1009
    800066f2:	0001c517          	auipc	a0,0x1c
    800066f6:	dee50513          	add	a0,a0,-530 # 800224e0 <aa>
    800066fa:	00000097          	auipc	ra,0x0
    800066fe:	ddc080e7          	jalr	-548(ra) # 800064d6 <ran_array>
    rand_index = 0;
    80006702:	00002797          	auipc	a5,0x2
    80006706:	2407a323          	sw	zero,582(a5) # 80008948 <rand_index>
}
    8000670a:	64813083          	ld	ra,1608(sp)
    8000670e:	64013403          	ld	s0,1600(sp)
    80006712:	65010113          	add	sp,sp,1616
    80006716:	8082                	ret

0000000080006718 <nextRand>:
int nextRand()
{
    if (++rand_index > 100)
    80006718:	00002717          	auipc	a4,0x2
    8000671c:	23070713          	add	a4,a4,560 # 80008948 <rand_index>
    80006720:	431c                	lw	a5,0(a4)
    80006722:	2785                	addw	a5,a5,1
    80006724:	0007869b          	sext.w	a3,a5
    80006728:	c31c                	sw	a5,0(a4)
    8000672a:	06400793          	li	a5,100
    8000672e:	00d7ce63          	blt	a5,a3,8000674a <nextRand+0x32>
    {
        ran_array(aa, 1009);
        rand_index = 0;
    }
    return aa[rand_index];
    80006732:	00002717          	auipc	a4,0x2
    80006736:	21672703          	lw	a4,534(a4) # 80008948 <rand_index>
    8000673a:	070e                	sll	a4,a4,0x3
    8000673c:	0001c797          	auipc	a5,0x1c
    80006740:	da478793          	add	a5,a5,-604 # 800224e0 <aa>
    80006744:	97ba                	add	a5,a5,a4
}
    80006746:	4388                	lw	a0,0(a5)
    80006748:	8082                	ret
{
    8000674a:	1141                	add	sp,sp,-16
    8000674c:	e406                	sd	ra,8(sp)
    8000674e:	e022                	sd	s0,0(sp)
    80006750:	0800                	add	s0,sp,16
        ran_array(aa, 1009);
    80006752:	3f100593          	li	a1,1009
    80006756:	0001c517          	auipc	a0,0x1c
    8000675a:	d8a50513          	add	a0,a0,-630 # 800224e0 <aa>
    8000675e:	00000097          	auipc	ra,0x0
    80006762:	d78080e7          	jalr	-648(ra) # 800064d6 <ran_array>
        rand_index = 0;
    80006766:	00002797          	auipc	a5,0x2
    8000676a:	1e07a123          	sw	zero,482(a5) # 80008948 <rand_index>
    return aa[rand_index];
    8000676e:	00002717          	auipc	a4,0x2
    80006772:	1da72703          	lw	a4,474(a4) # 80008948 <rand_index>
    80006776:	070e                	sll	a4,a4,0x3
    80006778:	0001c797          	auipc	a5,0x1c
    8000677c:	d6878793          	add	a5,a5,-664 # 800224e0 <aa>
    80006780:	97ba                	add	a5,a5,a4
}
    80006782:	4388                	lw	a0,0(a5)
    80006784:	60a2                	ld	ra,8(sp)
    80006786:	6402                	ld	s0,0(sp)
    80006788:	0141                	add	sp,sp,16
    8000678a:	8082                	ret

000000008000678c <rand_init>:
void rand_init(int seed)
{
    8000678c:	1141                	add	sp,sp,-16
    8000678e:	e406                	sd	ra,8(sp)
    80006790:	e022                	sd	s0,0(sp)
    80006792:	0800                	add	s0,sp,16
    ran_start(seed);
    80006794:	00000097          	auipc	ra,0x0
    80006798:	e04080e7          	jalr	-508(ra) # 80006598 <ran_start>
}
    8000679c:	60a2                	ld	ra,8(sp)
    8000679e:	6402                	ld	s0,0(sp)
    800067a0:	0141                	add	sp,sp,16
    800067a2:	8082                	ret

00000000800067a4 <scaled_random>:
int scaled_random(int low, int high)
{
    800067a4:	1101                	add	sp,sp,-32
    800067a6:	ec06                	sd	ra,24(sp)
    800067a8:	e822                	sd	s0,16(sp)
    800067aa:	e426                	sd	s1,8(sp)
    800067ac:	e04a                	sd	s2,0(sp)
    800067ae:	1000                	add	s0,sp,32
    800067b0:	892a                	mv	s2,a0
    800067b2:	84ae                	mv	s1,a1
    int range = (high - low + 1);
    int val = nextRand();
    800067b4:	00000097          	auipc	ra,0x0
    800067b8:	f64080e7          	jalr	-156(ra) # 80006718 <nextRand>
    int range = (high - low + 1);
    800067bc:	412484bb          	subw	s1,s1,s2
    800067c0:	2485                	addw	s1,s1,1
    return (val % range) + low;
    800067c2:	0295653b          	remw	a0,a0,s1
}
    800067c6:	0125053b          	addw	a0,a0,s2
    800067ca:	60e2                	ld	ra,24(sp)
    800067cc:	6442                	ld	s0,16(sp)
    800067ce:	64a2                	ld	s1,8(sp)
    800067d0:	6902                	ld	s2,0(sp)
    800067d2:	6105                	add	sp,sp,32
    800067d4:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	sll	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	sll	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
