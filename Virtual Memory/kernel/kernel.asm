
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ab010113          	add	sp,sp,-1360 # 80008ab0 <stack0>
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
    80000054:	92070713          	add	a4,a4,-1760 # 80008970 <timer_scratch>
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
    80000066:	06e78793          	add	a5,a5,110 # 800060d0 <timervec>
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
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd847f>
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
    8000012e:	5e6080e7          	jalr	1510(ra) # 80002710 <either_copyin>
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
    80000188:	92c50513          	add	a0,a0,-1748 # 80010ab0 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	91c48493          	add	s1,s1,-1764 # 80010ab0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	9ac90913          	add	s2,s2,-1620 # 80010b48 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	9aa080e7          	jalr	-1622(ra) # 80001b5e <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	39e080e7          	jalr	926(ra) # 8000255a <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	0e8080e7          	jalr	232(ra) # 800022b2 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	8d270713          	add	a4,a4,-1838 # 80010ab0 <cons>
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
    80000214:	4aa080e7          	jalr	1194(ra) # 800026ba <either_copyout>
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
    8000022c:	88850513          	add	a0,a0,-1912 # 80010ab0 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	87250513          	add	a0,a0,-1934 # 80010ab0 <cons>
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
    80000272:	8cf72d23          	sw	a5,-1830(a4) # 80010b48 <cons+0x98>
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
    800002cc:	7e850513          	add	a0,a0,2024 # 80010ab0 <cons>
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
    800002f2:	478080e7          	jalr	1144(ra) # 80002766 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	7ba50513          	add	a0,a0,1978 # 80010ab0 <cons>
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
    8000031e:	79670713          	add	a4,a4,1942 # 80010ab0 <cons>
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
    80000348:	76c78793          	add	a5,a5,1900 # 80010ab0 <cons>
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
    80000376:	7d67a783          	lw	a5,2006(a5) # 80010b48 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	72a70713          	add	a4,a4,1834 # 80010ab0 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	71a48493          	add	s1,s1,1818 # 80010ab0 <cons>
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
    800003d6:	6de70713          	add	a4,a4,1758 # 80010ab0 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	76f72423          	sw	a5,1896(a4) # 80010b50 <cons+0xa0>
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
    80000412:	6a278793          	add	a5,a5,1698 # 80010ab0 <cons>
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
    80000436:	70c7ad23          	sw	a2,1818(a5) # 80010b4c <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	70e50513          	add	a0,a0,1806 # 80010b48 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	ed4080e7          	jalr	-300(ra) # 80002316 <wakeup>
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
    80000460:	65450513          	add	a0,a0,1620 # 80010ab0 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00021797          	auipc	a5,0x21
    80000478:	bd478793          	add	a5,a5,-1068 # 80021048 <devsw>
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
    8000054c:	6207a423          	sw	zero,1576(a5) # 80010b70 <pr+0x18>
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
    80000580:	3af72223          	sw	a5,932(a4) # 80008920 <panicked>
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
    800005bc:	5b8dad83          	lw	s11,1464(s11) # 80010b70 <pr+0x18>
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
    800005fa:	56250513          	add	a0,a0,1378 # 80010b58 <pr>
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
    80000758:	40450513          	add	a0,a0,1028 # 80010b58 <pr>
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
    80000774:	3e848493          	add	s1,s1,1000 # 80010b58 <pr>
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
    800007d4:	3a850513          	add	a0,a0,936 # 80010b78 <uart_tx_lock>
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
    80000800:	1247a783          	lw	a5,292(a5) # 80008920 <panicked>
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
    80000838:	0f47b783          	ld	a5,244(a5) # 80008928 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	0f473703          	ld	a4,244(a4) # 80008930 <uart_tx_w>
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
    80000862:	31aa0a13          	add	s4,s4,794 # 80010b78 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	0c248493          	add	s1,s1,194 # 80008928 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	0c298993          	add	s3,s3,194 # 80008930 <uart_tx_w>
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
    80000894:	a86080e7          	jalr	-1402(ra) # 80002316 <wakeup>
    
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
    800008d0:	2ac50513          	add	a0,a0,684 # 80010b78 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	0447a783          	lw	a5,68(a5) # 80008920 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	04a73703          	ld	a4,74(a4) # 80008930 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	03a7b783          	ld	a5,58(a5) # 80008928 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	27e98993          	add	s3,s3,638 # 80010b78 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	02648493          	add	s1,s1,38 # 80008928 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	02690913          	add	s2,s2,38 # 80008930 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	998080e7          	jalr	-1640(ra) # 800022b2 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	24848493          	add	s1,s1,584 # 80010b78 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	fee7b623          	sd	a4,-20(a5) # 80008930 <uart_tx_w>
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
    800009ba:	1c248493          	add	s1,s1,450 # 80010b78 <uart_tx_lock>
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
    800009fc:	98878793          	add	a5,a5,-1656 # 80026380 <end>
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
    80000a1c:	19890913          	add	s2,s2,408 # 80010bb0 <kmem>
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
    80000aba:	0fa50513          	add	a0,a0,250 # 80010bb0 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	sll	a1,a1,0x1b
    80000aca:	00026517          	auipc	a0,0x26
    80000ace:	8b650513          	add	a0,a0,-1866 # 80026380 <end>
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
    80000af0:	0c448493          	add	s1,s1,196 # 80010bb0 <kmem>
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
    80000b08:	0ac50513          	add	a0,a0,172 # 80010bb0 <kmem>
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
    80000b34:	08050513          	add	a0,a0,128 # 80010bb0 <kmem>
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
    80000b70:	fd6080e7          	jalr	-42(ra) # 80001b42 <mycpu>
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
    80000ba2:	fa4080e7          	jalr	-92(ra) # 80001b42 <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	f98080e7          	jalr	-104(ra) # 80001b42 <mycpu>
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
    80000bc6:	f80080e7          	jalr	-128(ra) # 80001b42 <mycpu>
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
    80000c06:	f40080e7          	jalr	-192(ra) # 80001b42 <mycpu>
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
    80000c32:	f14080e7          	jalr	-236(ra) # 80001b42 <mycpu>
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
    80000d42:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd8c81>
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
    80000e7e:	cb8080e7          	jalr	-840(ra) # 80001b32 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	ab670713          	add	a4,a4,-1354 # 80008938 <started>
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
    80000e9a:	c9c080e7          	jalr	-868(ra) # 80001b32 <cpuid>
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
    80000ebc:	c22080e7          	jalr	-990(ra) # 80002ada <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	250080e7          	jalr	592(ra) # 80006110 <plicinithart>
  }
  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	238080e7          	jalr	568(ra) # 80002100 <scheduler>
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
    80000f2c:	b56080e7          	jalr	-1194(ra) # 80001a7e <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	b82080e7          	jalr	-1150(ra) # 80002ab2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	ba2080e7          	jalr	-1118(ra) # 80002ada <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	1ba080e7          	jalr	442(ra) # 800060fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	1c8080e7          	jalr	456(ra) # 80006110 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	3a2080e7          	jalr	930(ra) # 800032f2 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	a40080e7          	jalr	-1472(ra) # 80003998 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	9b6080e7          	jalr	-1610(ra) # 80004916 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	2b0080e7          	jalr	688(ra) # 80006218 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	f72080e7          	jalr	-142(ra) # 80001ee2 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	9af72d23          	sw	a5,-1606(a4) # 80008938 <started>
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
    80000f96:	9b67b783          	ld	a5,-1610(a5) # 80008948 <kernel_pagetable>
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
    80001010:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8c77>
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
    8000122c:	7c0080e7          	jalr	1984(ra) # 800019e8 <proc_mapstacks>
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
    80001252:	6ea7bd23          	sd	a0,1786(a5) # 80008948 <kernel_pagetable>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8c80>
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

0000000080001830 <vmprint>:

void
vmprint(pagetable_t pagetable)
{
    80001830:	7159                	add	sp,sp,-112
    80001832:	f486                	sd	ra,104(sp)
    80001834:	f0a2                	sd	s0,96(sp)
    80001836:	eca6                	sd	s1,88(sp)
    80001838:	e8ca                	sd	s2,80(sp)
    8000183a:	e4ce                	sd	s3,72(sp)
    8000183c:	e0d2                	sd	s4,64(sp)
    8000183e:	fc56                	sd	s5,56(sp)
    80001840:	f85a                	sd	s6,48(sp)
    80001842:	f45e                	sd	s7,40(sp)
    80001844:	f062                	sd	s8,32(sp)
    80001846:	ec66                	sd	s9,24(sp)
    80001848:	e86a                	sd	s10,16(sp)
    8000184a:	e46e                	sd	s11,8(sp)
    8000184c:	1880                	add	s0,sp,112
    8000184e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001850:	4981                	li	s3,0
    pte_t pte = pagetable[i];
    if (pte & PTE_V){
      for (int j = 0; j < nests; j++){
    80001852:	00007a97          	auipc	s5,0x7
    80001856:	0eea8a93          	add	s5,s5,238 # 80008940 <nests>
        printf(" ..");
      }
      printf("%d: ", i); // index into page table
    8000185a:	00007d17          	auipc	s10,0x7
    8000185e:	986d0d13          	add	s10,s10,-1658 # 800081e0 <digits+0x1a0>
      printf("pte %p ", pte); // page table entry / virtual address
    80001862:	00007c97          	auipc	s9,0x7
    80001866:	986c8c93          	add	s9,s9,-1658 # 800081e8 <digits+0x1a8>
      printf("pa %p \n", PTE2PA(pte)); // physical address
    8000186a:	00007c17          	auipc	s8,0x7
    8000186e:	986c0c13          	add	s8,s8,-1658 # 800081f0 <digits+0x1b0>
      for (int j = 0; j < nests; j++){
    80001872:	4d81                	li	s11,0
        printf(" ..");
    80001874:	00007b17          	auipc	s6,0x7
    80001878:	964b0b13          	add	s6,s6,-1692 # 800081d8 <digits+0x198>
  for(int i = 0; i < 512; i++){
    8000187c:	20000b93          	li	s7,512
    80001880:	a029                	j	8000188a <vmprint+0x5a>
    80001882:	2985                	addw	s3,s3,1 # 1001 <_entry-0x7fffefff>
    80001884:	0a21                	add	s4,s4,8
    80001886:	09798363          	beq	s3,s7,8000190c <vmprint+0xdc>
    pte_t pte = pagetable[i];
    8000188a:	000a3903          	ld	s2,0(s4)
    if (pte & PTE_V){
    8000188e:	00197793          	and	a5,s2,1
    80001892:	dbe5                	beqz	a5,80001882 <vmprint+0x52>
      for (int j = 0; j < nests; j++){
    80001894:	000aa783          	lw	a5,0(s5)
    80001898:	00f05d63          	blez	a5,800018b2 <vmprint+0x82>
    8000189c:	84ee                	mv	s1,s11
        printf(" ..");
    8000189e:	855a                	mv	a0,s6
    800018a0:	fffff097          	auipc	ra,0xfffff
    800018a4:	ce6080e7          	jalr	-794(ra) # 80000586 <printf>
      for (int j = 0; j < nests; j++){
    800018a8:	2485                	addw	s1,s1,1
    800018aa:	000aa783          	lw	a5,0(s5)
    800018ae:	fef4c8e3          	blt	s1,a5,8000189e <vmprint+0x6e>
      printf("%d: ", i); // index into page table
    800018b2:	85ce                	mv	a1,s3
    800018b4:	856a                	mv	a0,s10
    800018b6:	fffff097          	auipc	ra,0xfffff
    800018ba:	cd0080e7          	jalr	-816(ra) # 80000586 <printf>
      printf("pte %p ", pte); // page table entry / virtual address
    800018be:	85ca                	mv	a1,s2
    800018c0:	8566                	mv	a0,s9
    800018c2:	fffff097          	auipc	ra,0xfffff
    800018c6:	cc4080e7          	jalr	-828(ra) # 80000586 <printf>
      printf("pa %p \n", PTE2PA(pte)); // physical address
    800018ca:	00a95493          	srl	s1,s2,0xa
    800018ce:	04b2                	sll	s1,s1,0xc
    800018d0:	85a6                	mv	a1,s1
    800018d2:	8562                	mv	a0,s8
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	cb2080e7          	jalr	-846(ra) # 80000586 <printf>

      if((pte & (PTE_R|PTE_W|PTE_X)) == 0){ // this has children
    800018dc:	00e97913          	and	s2,s2,14
    800018e0:	fa0911e3          	bnez	s2,80001882 <vmprint+0x52>
        // this PTE points to a lower-level page table
        nests++;
    800018e4:	00007917          	auipc	s2,0x7
    800018e8:	05c90913          	add	s2,s2,92 # 80008940 <nests>
    800018ec:	00092783          	lw	a5,0(s2)
    800018f0:	2785                	addw	a5,a5,1
    800018f2:	00f92023          	sw	a5,0(s2)
        uint64 child = PTE2PA(pte);
        vmprint((pagetable_t)child);
    800018f6:	8526                	mv	a0,s1
    800018f8:	00000097          	auipc	ra,0x0
    800018fc:	f38080e7          	jalr	-200(ra) # 80001830 <vmprint>
        nests--;
    80001900:	00092783          	lw	a5,0(s2)
    80001904:	37fd                	addw	a5,a5,-1
    80001906:	00f92023          	sw	a5,0(s2)
    8000190a:	bfa5                	j	80001882 <vmprint+0x52>
      }
    }
  }
}
    8000190c:	70a6                	ld	ra,104(sp)
    8000190e:	7406                	ld	s0,96(sp)
    80001910:	64e6                	ld	s1,88(sp)
    80001912:	6946                	ld	s2,80(sp)
    80001914:	69a6                	ld	s3,72(sp)
    80001916:	6a06                	ld	s4,64(sp)
    80001918:	7ae2                	ld	s5,56(sp)
    8000191a:	7b42                	ld	s6,48(sp)
    8000191c:	7ba2                	ld	s7,40(sp)
    8000191e:	7c02                	ld	s8,32(sp)
    80001920:	6ce2                	ld	s9,24(sp)
    80001922:	6d42                	ld	s10,16(sp)
    80001924:	6da2                	ld	s11,8(sp)
    80001926:	6165                	add	sp,sp,112
    80001928:	8082                	ret

000000008000192a <vmprint_start>:

void
vmprint_start(pagetable_t pagetable)
{
    8000192a:	1101                	add	sp,sp,-32
    8000192c:	ec06                	sd	ra,24(sp)
    8000192e:	e822                	sd	s0,16(sp)
    80001930:	e426                	sd	s1,8(sp)
    80001932:	1000                	add	s0,sp,32
    80001934:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    80001936:	85aa                	mv	a1,a0
    80001938:	00007517          	auipc	a0,0x7
    8000193c:	8c050513          	add	a0,a0,-1856 # 800081f8 <digits+0x1b8>
    80001940:	fffff097          	auipc	ra,0xfffff
    80001944:	c46080e7          	jalr	-954(ra) # 80000586 <printf>
  vmprint(pagetable);
    80001948:	8526                	mv	a0,s1
    8000194a:	00000097          	auipc	ra,0x0
    8000194e:	ee6080e7          	jalr	-282(ra) # 80001830 <vmprint>
}
    80001952:	60e2                	ld	ra,24(sp)
    80001954:	6442                	ld	s0,16(sp)
    80001956:	64a2                	ld	s1,8(sp)
    80001958:	6105                	add	sp,sp,32
    8000195a:	8082                	ret

000000008000195c <pgaccess>:

// reports which pages have been accessed
int
pgaccess(char * start_va, int num_pages, int* bitmap, pagetable_t table)
{
    8000195c:	715d                	add	sp,sp,-80
    8000195e:	e486                	sd	ra,72(sp)
    80001960:	e0a2                	sd	s0,64(sp)
    80001962:	fc26                	sd	s1,56(sp)
    80001964:	f84a                	sd	s2,48(sp)
    80001966:	f44e                	sd	s3,40(sp)
    80001968:	f052                	sd	s4,32(sp)
    8000196a:	ec56                	sd	s5,24(sp)
    8000196c:	e85a                	sd	s6,16(sp)
    8000196e:	0880                	add	s0,sp,80
    80001970:	8b32                	mv	s6,a2
  pte_t * pte;
  int alloc = 0;
    80001972:	fa042e23          	sw	zero,-68(s0)

  for (int i = 0; i < num_pages; i++)
    80001976:	04b05563          	blez	a1,800019c0 <pgaccess+0x64>
    8000197a:	89b6                	mv	s3,a3
    8000197c:	84aa                	mv	s1,a0
    8000197e:	05b2                	sll	a1,a1,0xc
    80001980:	00b50933          	add	s2,a0,a1
  {
    pte = walk(table, (uint64)start_va + (i * PGSIZE), alloc);
    if (((*pte & PTE_V) && (*pte & PTE_A))){
    80001984:	04100a93          	li	s5,65
  for (int i = 0; i < num_pages; i++)
    80001988:	6a05                	lui	s4,0x1
    8000198a:	a021                	j	80001992 <pgaccess+0x36>
    8000198c:	94d2                	add	s1,s1,s4
    8000198e:	03248963          	beq	s1,s2,800019c0 <pgaccess+0x64>
    pte = walk(table, (uint64)start_va + (i * PGSIZE), alloc);
    80001992:	fbc42603          	lw	a2,-68(s0)
    80001996:	85a6                	mv	a1,s1
    80001998:	854e                	mv	a0,s3
    8000199a:	fffff097          	auipc	ra,0xfffff
    8000199e:	616080e7          	jalr	1558(ra) # 80000fb0 <walk>
    if (((*pte & PTE_V) && (*pte & PTE_A))){
    800019a2:	611c                	ld	a5,0(a0)
    800019a4:	0417f713          	and	a4,a5,65
    800019a8:	ff5712e3          	bne	a4,s5,8000198c <pgaccess+0x30>
      *pte = *pte ^ PTE_A;  // xor unsets bit in pte
    800019ac:	0407c793          	xor	a5,a5,64
    800019b0:	e11c                	sd	a5,0(a0)
      alloc = (alloc | (1UL << 1));
    800019b2:	fbc42783          	lw	a5,-68(s0)
    800019b6:	0027e793          	or	a5,a5,2
    800019ba:	faf42e23          	sw	a5,-68(s0)
    800019be:	b7f9                	j	8000198c <pgaccess+0x30>
    }
  }
  either_copyout(1, (uint64)bitmap, &alloc, sizeof(int));
    800019c0:	4691                	li	a3,4
    800019c2:	fbc40613          	add	a2,s0,-68
    800019c6:	85da                	mv	a1,s6
    800019c8:	4505                	li	a0,1
    800019ca:	00001097          	auipc	ra,0x1
    800019ce:	cf0080e7          	jalr	-784(ra) # 800026ba <either_copyout>
  return 0;
    800019d2:	4501                	li	a0,0
    800019d4:	60a6                	ld	ra,72(sp)
    800019d6:	6406                	ld	s0,64(sp)
    800019d8:	74e2                	ld	s1,56(sp)
    800019da:	7942                	ld	s2,48(sp)
    800019dc:	79a2                	ld	s3,40(sp)
    800019de:	7a02                	ld	s4,32(sp)
    800019e0:	6ae2                	ld	s5,24(sp)
    800019e2:	6b42                	ld	s6,16(sp)
    800019e4:	6161                	add	sp,sp,80
    800019e6:	8082                	ret

00000000800019e8 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    800019e8:	7139                	add	sp,sp,-64
    800019ea:	fc06                	sd	ra,56(sp)
    800019ec:	f822                	sd	s0,48(sp)
    800019ee:	f426                	sd	s1,40(sp)
    800019f0:	f04a                	sd	s2,32(sp)
    800019f2:	ec4e                	sd	s3,24(sp)
    800019f4:	e852                	sd	s4,16(sp)
    800019f6:	e456                	sd	s5,8(sp)
    800019f8:	e05a                	sd	s6,0(sp)
    800019fa:	0080                	add	s0,sp,64
    800019fc:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800019fe:	00010497          	auipc	s1,0x10
    80001a02:	a0248493          	add	s1,s1,-1534 # 80011400 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001a06:	8b26                	mv	s6,s1
    80001a08:	00006a97          	auipc	s5,0x6
    80001a0c:	5f8a8a93          	add	s5,s5,1528 # 80008000 <etext>
    80001a10:	04000937          	lui	s2,0x4000
    80001a14:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a16:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a18:	00015a17          	auipc	s4,0x15
    80001a1c:	3e8a0a13          	add	s4,s4,1000 # 80016e00 <tickslock>
    char *pa = kalloc();
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	0c2080e7          	jalr	194(ra) # 80000ae2 <kalloc>
    80001a28:	862a                	mv	a2,a0
    if(pa == 0)
    80001a2a:	c131                	beqz	a0,80001a6e <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001a2c:	416485b3          	sub	a1,s1,s6
    80001a30:	858d                	sra	a1,a1,0x3
    80001a32:	000ab783          	ld	a5,0(s5)
    80001a36:	02f585b3          	mul	a1,a1,a5
    80001a3a:	2585                	addw	a1,a1,1
    80001a3c:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a40:	4719                	li	a4,6
    80001a42:	6685                	lui	a3,0x1
    80001a44:	40b905b3          	sub	a1,s2,a1
    80001a48:	854e                	mv	a0,s3
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	6ee080e7          	jalr	1774(ra) # 80001138 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a52:	16848493          	add	s1,s1,360
    80001a56:	fd4495e3          	bne	s1,s4,80001a20 <proc_mapstacks+0x38>
  }
}
    80001a5a:	70e2                	ld	ra,56(sp)
    80001a5c:	7442                	ld	s0,48(sp)
    80001a5e:	74a2                	ld	s1,40(sp)
    80001a60:	7902                	ld	s2,32(sp)
    80001a62:	69e2                	ld	s3,24(sp)
    80001a64:	6a42                	ld	s4,16(sp)
    80001a66:	6aa2                	ld	s5,8(sp)
    80001a68:	6b02                	ld	s6,0(sp)
    80001a6a:	6121                	add	sp,sp,64
    80001a6c:	8082                	ret
      panic("kalloc");
    80001a6e:	00006517          	auipc	a0,0x6
    80001a72:	79a50513          	add	a0,a0,1946 # 80008208 <digits+0x1c8>
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	ac6080e7          	jalr	-1338(ra) # 8000053c <panic>

0000000080001a7e <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001a7e:	7139                	add	sp,sp,-64
    80001a80:	fc06                	sd	ra,56(sp)
    80001a82:	f822                	sd	s0,48(sp)
    80001a84:	f426                	sd	s1,40(sp)
    80001a86:	f04a                	sd	s2,32(sp)
    80001a88:	ec4e                	sd	s3,24(sp)
    80001a8a:	e852                	sd	s4,16(sp)
    80001a8c:	e456                	sd	s5,8(sp)
    80001a8e:	e05a                	sd	s6,0(sp)
    80001a90:	0080                	add	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a92:	00006597          	auipc	a1,0x6
    80001a96:	77e58593          	add	a1,a1,1918 # 80008210 <digits+0x1d0>
    80001a9a:	0000f517          	auipc	a0,0xf
    80001a9e:	13650513          	add	a0,a0,310 # 80010bd0 <pid_lock>
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	0a0080e7          	jalr	160(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001aaa:	00006597          	auipc	a1,0x6
    80001aae:	76e58593          	add	a1,a1,1902 # 80008218 <digits+0x1d8>
    80001ab2:	0000f517          	auipc	a0,0xf
    80001ab6:	13650513          	add	a0,a0,310 # 80010be8 <wait_lock>
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	088080e7          	jalr	136(ra) # 80000b42 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ac2:	00010497          	auipc	s1,0x10
    80001ac6:	93e48493          	add	s1,s1,-1730 # 80011400 <proc>
      initlock(&p->lock, "proc");
    80001aca:	00006b17          	auipc	s6,0x6
    80001ace:	75eb0b13          	add	s6,s6,1886 # 80008228 <digits+0x1e8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001ad2:	8aa6                	mv	s5,s1
    80001ad4:	00006a17          	auipc	s4,0x6
    80001ad8:	52ca0a13          	add	s4,s4,1324 # 80008000 <etext>
    80001adc:	04000937          	lui	s2,0x4000
    80001ae0:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001ae2:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ae4:	00015997          	auipc	s3,0x15
    80001ae8:	31c98993          	add	s3,s3,796 # 80016e00 <tickslock>
      initlock(&p->lock, "proc");
    80001aec:	85da                	mv	a1,s6
    80001aee:	8526                	mv	a0,s1
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	052080e7          	jalr	82(ra) # 80000b42 <initlock>
      p->state = UNUSED;
    80001af8:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001afc:	415487b3          	sub	a5,s1,s5
    80001b00:	878d                	sra	a5,a5,0x3
    80001b02:	000a3703          	ld	a4,0(s4)
    80001b06:	02e787b3          	mul	a5,a5,a4
    80001b0a:	2785                	addw	a5,a5,1
    80001b0c:	00d7979b          	sllw	a5,a5,0xd
    80001b10:	40f907b3          	sub	a5,s2,a5
    80001b14:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b16:	16848493          	add	s1,s1,360
    80001b1a:	fd3499e3          	bne	s1,s3,80001aec <procinit+0x6e>
  }
}
    80001b1e:	70e2                	ld	ra,56(sp)
    80001b20:	7442                	ld	s0,48(sp)
    80001b22:	74a2                	ld	s1,40(sp)
    80001b24:	7902                	ld	s2,32(sp)
    80001b26:	69e2                	ld	s3,24(sp)
    80001b28:	6a42                	ld	s4,16(sp)
    80001b2a:	6aa2                	ld	s5,8(sp)
    80001b2c:	6b02                	ld	s6,0(sp)
    80001b2e:	6121                	add	sp,sp,64
    80001b30:	8082                	ret

0000000080001b32 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001b32:	1141                	add	sp,sp,-16
    80001b34:	e422                	sd	s0,8(sp)
    80001b36:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b38:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b3a:	2501                	sext.w	a0,a0
    80001b3c:	6422                	ld	s0,8(sp)
    80001b3e:	0141                	add	sp,sp,16
    80001b40:	8082                	ret

0000000080001b42 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001b42:	1141                	add	sp,sp,-16
    80001b44:	e422                	sd	s0,8(sp)
    80001b46:	0800                	add	s0,sp,16
    80001b48:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b4a:	2781                	sext.w	a5,a5
    80001b4c:	079e                	sll	a5,a5,0x7
  return c;
}
    80001b4e:	0000f517          	auipc	a0,0xf
    80001b52:	0b250513          	add	a0,a0,178 # 80010c00 <cpus>
    80001b56:	953e                	add	a0,a0,a5
    80001b58:	6422                	ld	s0,8(sp)
    80001b5a:	0141                	add	sp,sp,16
    80001b5c:	8082                	ret

0000000080001b5e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001b5e:	1101                	add	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	add	s0,sp,32
  push_off();
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	01e080e7          	jalr	30(ra) # 80000b86 <push_off>
    80001b70:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b72:	2781                	sext.w	a5,a5
    80001b74:	079e                	sll	a5,a5,0x7
    80001b76:	0000f717          	auipc	a4,0xf
    80001b7a:	05a70713          	add	a4,a4,90 # 80010bd0 <pid_lock>
    80001b7e:	97ba                	add	a5,a5,a4
    80001b80:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	0a4080e7          	jalr	164(ra) # 80000c26 <pop_off>
  return p;
}
    80001b8a:	8526                	mv	a0,s1
    80001b8c:	60e2                	ld	ra,24(sp)
    80001b8e:	6442                	ld	s0,16(sp)
    80001b90:	64a2                	ld	s1,8(sp)
    80001b92:	6105                	add	sp,sp,32
    80001b94:	8082                	ret

0000000080001b96 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b96:	1141                	add	sp,sp,-16
    80001b98:	e406                	sd	ra,8(sp)
    80001b9a:	e022                	sd	s0,0(sp)
    80001b9c:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b9e:	00000097          	auipc	ra,0x0
    80001ba2:	fc0080e7          	jalr	-64(ra) # 80001b5e <myproc>
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	0e0080e7          	jalr	224(ra) # 80000c86 <release>

  if (first) {
    80001bae:	00007797          	auipc	a5,0x7
    80001bb2:	d227a783          	lw	a5,-734(a5) # 800088d0 <first.1>
    80001bb6:	eb89                	bnez	a5,80001bc8 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bb8:	00001097          	auipc	ra,0x1
    80001bbc:	f3a080e7          	jalr	-198(ra) # 80002af2 <usertrapret>
}
    80001bc0:	60a2                	ld	ra,8(sp)
    80001bc2:	6402                	ld	s0,0(sp)
    80001bc4:	0141                	add	sp,sp,16
    80001bc6:	8082                	ret
    first = 0;
    80001bc8:	00007797          	auipc	a5,0x7
    80001bcc:	d007a423          	sw	zero,-760(a5) # 800088d0 <first.1>
    fsinit(ROOTDEV);
    80001bd0:	4505                	li	a0,1
    80001bd2:	00002097          	auipc	ra,0x2
    80001bd6:	d46080e7          	jalr	-698(ra) # 80003918 <fsinit>
    80001bda:	bff9                	j	80001bb8 <forkret+0x22>

0000000080001bdc <allocpid>:
{
    80001bdc:	1101                	add	sp,sp,-32
    80001bde:	ec06                	sd	ra,24(sp)
    80001be0:	e822                	sd	s0,16(sp)
    80001be2:	e426                	sd	s1,8(sp)
    80001be4:	e04a                	sd	s2,0(sp)
    80001be6:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001be8:	0000f917          	auipc	s2,0xf
    80001bec:	fe890913          	add	s2,s2,-24 # 80010bd0 <pid_lock>
    80001bf0:	854a                	mv	a0,s2
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	fe0080e7          	jalr	-32(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001bfa:	00007797          	auipc	a5,0x7
    80001bfe:	cda78793          	add	a5,a5,-806 # 800088d4 <nextpid>
    80001c02:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c04:	0014871b          	addw	a4,s1,1
    80001c08:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c0a:	854a                	mv	a0,s2
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	07a080e7          	jalr	122(ra) # 80000c86 <release>
}
    80001c14:	8526                	mv	a0,s1
    80001c16:	60e2                	ld	ra,24(sp)
    80001c18:	6442                	ld	s0,16(sp)
    80001c1a:	64a2                	ld	s1,8(sp)
    80001c1c:	6902                	ld	s2,0(sp)
    80001c1e:	6105                	add	sp,sp,32
    80001c20:	8082                	ret

0000000080001c22 <proc_pagetable>:
{
    80001c22:	1101                	add	sp,sp,-32
    80001c24:	ec06                	sd	ra,24(sp)
    80001c26:	e822                	sd	s0,16(sp)
    80001c28:	e426                	sd	s1,8(sp)
    80001c2a:	e04a                	sd	s2,0(sp)
    80001c2c:	1000                	add	s0,sp,32
    80001c2e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	6f2080e7          	jalr	1778(ra) # 80001322 <uvmcreate>
    80001c38:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c3a:	c121                	beqz	a0,80001c7a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c3c:	4729                	li	a4,10
    80001c3e:	00005697          	auipc	a3,0x5
    80001c42:	3c268693          	add	a3,a3,962 # 80007000 <_trampoline>
    80001c46:	6605                	lui	a2,0x1
    80001c48:	040005b7          	lui	a1,0x4000
    80001c4c:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c4e:	05b2                	sll	a1,a1,0xc
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	448080e7          	jalr	1096(ra) # 80001098 <mappages>
    80001c58:	02054863          	bltz	a0,80001c88 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c5c:	4719                	li	a4,6
    80001c5e:	05893683          	ld	a3,88(s2)
    80001c62:	6605                	lui	a2,0x1
    80001c64:	020005b7          	lui	a1,0x2000
    80001c68:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c6a:	05b6                	sll	a1,a1,0xd
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	42a080e7          	jalr	1066(ra) # 80001098 <mappages>
    80001c76:	02054163          	bltz	a0,80001c98 <proc_pagetable+0x76>
}
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	60e2                	ld	ra,24(sp)
    80001c7e:	6442                	ld	s0,16(sp)
    80001c80:	64a2                	ld	s1,8(sp)
    80001c82:	6902                	ld	s2,0(sp)
    80001c84:	6105                	add	sp,sp,32
    80001c86:	8082                	ret
    uvmfree(pagetable, 0);
    80001c88:	4581                	li	a1,0
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	89c080e7          	jalr	-1892(ra) # 80001528 <uvmfree>
    return 0;
    80001c94:	4481                	li	s1,0
    80001c96:	b7d5                	j	80001c7a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c98:	4681                	li	a3,0
    80001c9a:	4605                	li	a2,1
    80001c9c:	040005b7          	lui	a1,0x4000
    80001ca0:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ca2:	05b2                	sll	a1,a1,0xc
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	5b8080e7          	jalr	1464(ra) # 8000125e <uvmunmap>
    uvmfree(pagetable, 0);
    80001cae:	4581                	li	a1,0
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	876080e7          	jalr	-1930(ra) # 80001528 <uvmfree>
    return 0;
    80001cba:	4481                	li	s1,0
    80001cbc:	bf7d                	j	80001c7a <proc_pagetable+0x58>

0000000080001cbe <proc_freepagetable>:
{
    80001cbe:	1101                	add	sp,sp,-32
    80001cc0:	ec06                	sd	ra,24(sp)
    80001cc2:	e822                	sd	s0,16(sp)
    80001cc4:	e426                	sd	s1,8(sp)
    80001cc6:	e04a                	sd	s2,0(sp)
    80001cc8:	1000                	add	s0,sp,32
    80001cca:	84aa                	mv	s1,a0
    80001ccc:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cce:	4681                	li	a3,0
    80001cd0:	4605                	li	a2,1
    80001cd2:	040005b7          	lui	a1,0x4000
    80001cd6:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cd8:	05b2                	sll	a1,a1,0xc
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	584080e7          	jalr	1412(ra) # 8000125e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ce2:	4681                	li	a3,0
    80001ce4:	4605                	li	a2,1
    80001ce6:	020005b7          	lui	a1,0x2000
    80001cea:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001cec:	05b6                	sll	a1,a1,0xd
    80001cee:	8526                	mv	a0,s1
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	56e080e7          	jalr	1390(ra) # 8000125e <uvmunmap>
  uvmfree(pagetable, sz);
    80001cf8:	85ca                	mv	a1,s2
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	82c080e7          	jalr	-2004(ra) # 80001528 <uvmfree>
}
    80001d04:	60e2                	ld	ra,24(sp)
    80001d06:	6442                	ld	s0,16(sp)
    80001d08:	64a2                	ld	s1,8(sp)
    80001d0a:	6902                	ld	s2,0(sp)
    80001d0c:	6105                	add	sp,sp,32
    80001d0e:	8082                	ret

0000000080001d10 <freeproc>:
{
    80001d10:	1101                	add	sp,sp,-32
    80001d12:	ec06                	sd	ra,24(sp)
    80001d14:	e822                	sd	s0,16(sp)
    80001d16:	e426                	sd	s1,8(sp)
    80001d18:	1000                	add	s0,sp,32
    80001d1a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d1c:	6d28                	ld	a0,88(a0)
    80001d1e:	c509                	beqz	a0,80001d28 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	cc4080e7          	jalr	-828(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001d28:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d2c:	68a8                	ld	a0,80(s1)
    80001d2e:	c511                	beqz	a0,80001d3a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d30:	64ac                	ld	a1,72(s1)
    80001d32:	00000097          	auipc	ra,0x0
    80001d36:	f8c080e7          	jalr	-116(ra) # 80001cbe <proc_freepagetable>
  for (int i = 0; i < NPROC; i++){
    80001d3a:	00007597          	auipc	a1,0x7
    80001d3e:	c1e5a583          	lw	a1,-994(a1) # 80008958 <totaltickets>
    80001d42:	0000f797          	auipc	a5,0xf
    80001d46:	2be78793          	add	a5,a5,702 # 80011000 <s>
    80001d4a:	0000f617          	auipc	a2,0xf
    80001d4e:	3b660613          	add	a2,a2,950 # 80011100 <s+0x100>
{
    80001d52:	4501                	li	a0,0
      (&s)->inuse[i] = 0;
    80001d54:	4805                	li	a6,1
    80001d56:	a021                	j	80001d5e <freeproc+0x4e>
  for (int i = 0; i < NPROC; i++){
    80001d58:	0791                	add	a5,a5,4
    80001d5a:	02c78063          	beq	a5,a2,80001d7a <freeproc+0x6a>
    if (p->pid == (&s)->pid[i]){
    80001d5e:	5894                	lw	a3,48(s1)
    80001d60:	2007a703          	lw	a4,512(a5)
    80001d64:	fee69ae3          	bne	a3,a4,80001d58 <freeproc+0x48>
      totaltickets = totaltickets - (&s)->tickets[i];
    80001d68:	1007a703          	lw	a4,256(a5)
    80001d6c:	9d99                	subw	a1,a1,a4
      (&s)->tickets[i] = 0;
    80001d6e:	1007a023          	sw	zero,256(a5)
      (&s)->inuse[i] = 0;
    80001d72:	0007a023          	sw	zero,0(a5)
    80001d76:	8542                	mv	a0,a6
    80001d78:	b7c5                	j	80001d58 <freeproc+0x48>
    80001d7a:	c509                	beqz	a0,80001d84 <freeproc+0x74>
    80001d7c:	00007797          	auipc	a5,0x7
    80001d80:	bcb7ae23          	sw	a1,-1060(a5) # 80008958 <totaltickets>
  p->pagetable = 0;
    80001d84:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d88:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d8c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d90:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d94:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d98:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d9c:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001da0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001da4:	0004ac23          	sw	zero,24(s1)
}
    80001da8:	60e2                	ld	ra,24(sp)
    80001daa:	6442                	ld	s0,16(sp)
    80001dac:	64a2                	ld	s1,8(sp)
    80001dae:	6105                	add	sp,sp,32
    80001db0:	8082                	ret

0000000080001db2 <allocproc>:
{
    80001db2:	1101                	add	sp,sp,-32
    80001db4:	ec06                	sd	ra,24(sp)
    80001db6:	e822                	sd	s0,16(sp)
    80001db8:	e426                	sd	s1,8(sp)
    80001dba:	e04a                	sd	s2,0(sp)
    80001dbc:	1000                	add	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dbe:	0000f497          	auipc	s1,0xf
    80001dc2:	64248493          	add	s1,s1,1602 # 80011400 <proc>
    80001dc6:	00015917          	auipc	s2,0x15
    80001dca:	03a90913          	add	s2,s2,58 # 80016e00 <tickslock>
    acquire(&p->lock);
    80001dce:	8526                	mv	a0,s1
    80001dd0:	fffff097          	auipc	ra,0xfffff
    80001dd4:	e02080e7          	jalr	-510(ra) # 80000bd2 <acquire>
    if(p->state == UNUSED) {
    80001dd8:	4c9c                	lw	a5,24(s1)
    80001dda:	cf81                	beqz	a5,80001df2 <allocproc+0x40>
      release(&p->lock);
    80001ddc:	8526                	mv	a0,s1
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	ea8080e7          	jalr	-344(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001de6:	16848493          	add	s1,s1,360
    80001dea:	ff2492e3          	bne	s1,s2,80001dce <allocproc+0x1c>
  return 0;
    80001dee:	4481                	li	s1,0
    80001df0:	a855                	j	80001ea4 <allocproc+0xf2>
  p->pid = allocpid();
    80001df2:	00000097          	auipc	ra,0x0
    80001df6:	dea080e7          	jalr	-534(ra) # 80001bdc <allocpid>
    80001dfa:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001dfc:	4785                	li	a5,1
    80001dfe:	cc9c                	sw	a5,24(s1)
  for (int i = 0; i < NPROC; i++){
    80001e00:	0000f717          	auipc	a4,0xf
    80001e04:	20070713          	add	a4,a4,512 # 80011000 <s>
    80001e08:	4781                	li	a5,0
    80001e0a:	04000613          	li	a2,64
    if ((&s)->inuse[i] == 0){
    80001e0e:	4314                	lw	a3,0(a4)
    80001e10:	c691                	beqz	a3,80001e1c <allocproc+0x6a>
  for (int i = 0; i < NPROC; i++){
    80001e12:	2785                	addw	a5,a5,1
    80001e14:	0711                	add	a4,a4,4
    80001e16:	fec79ce3          	bne	a5,a2,80001e0e <allocproc+0x5c>
    80001e1a:	a0a1                	j	80001e62 <allocproc+0xb0>
      totaltickets++;
    80001e1c:	00007697          	auipc	a3,0x7
    80001e20:	b3c68693          	add	a3,a3,-1220 # 80008958 <totaltickets>
    80001e24:	4298                	lw	a4,0(a3)
    80001e26:	2705                	addw	a4,a4,1
    80001e28:	c298                	sw	a4,0(a3)
      (&s)->tickets[i] = 1;
    80001e2a:	0000f717          	auipc	a4,0xf
    80001e2e:	da670713          	add	a4,a4,-602 # 80010bd0 <pid_lock>
    80001e32:	04078693          	add	a3,a5,64
    80001e36:	068a                	sll	a3,a3,0x2
    80001e38:	96ba                	add	a3,a3,a4
    80001e3a:	4605                	li	a2,1
    80001e3c:	42c6a823          	sw	a2,1072(a3)
      (&s)->inuse[i] = 1;
    80001e40:	00279693          	sll	a3,a5,0x2
    80001e44:	96ba                	add	a3,a3,a4
    80001e46:	42c6a823          	sw	a2,1072(a3)
      (&s)->pid[i] = p->pid;
    80001e4a:	08078693          	add	a3,a5,128
    80001e4e:	068a                	sll	a3,a3,0x2
    80001e50:	96ba                	add	a3,a3,a4
    80001e52:	42a6a823          	sw	a0,1072(a3)
      (&s)->ticks[i] = 0;
    80001e56:	0c078793          	add	a5,a5,192
    80001e5a:	078a                	sll	a5,a5,0x2
    80001e5c:	973e                	add	a4,a4,a5
    80001e5e:	42072823          	sw	zero,1072(a4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	c80080e7          	jalr	-896(ra) # 80000ae2 <kalloc>
    80001e6a:	892a                	mv	s2,a0
    80001e6c:	eca8                	sd	a0,88(s1)
    80001e6e:	c131                	beqz	a0,80001eb2 <allocproc+0x100>
  p->pagetable = proc_pagetable(p);
    80001e70:	8526                	mv	a0,s1
    80001e72:	00000097          	auipc	ra,0x0
    80001e76:	db0080e7          	jalr	-592(ra) # 80001c22 <proc_pagetable>
    80001e7a:	892a                	mv	s2,a0
    80001e7c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e7e:	c531                	beqz	a0,80001eca <allocproc+0x118>
  memset(&p->context, 0, sizeof(p->context));
    80001e80:	07000613          	li	a2,112
    80001e84:	4581                	li	a1,0
    80001e86:	06048513          	add	a0,s1,96
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	e44080e7          	jalr	-444(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001e92:	00000797          	auipc	a5,0x0
    80001e96:	d0478793          	add	a5,a5,-764 # 80001b96 <forkret>
    80001e9a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e9c:	60bc                	ld	a5,64(s1)
    80001e9e:	6705                	lui	a4,0x1
    80001ea0:	97ba                	add	a5,a5,a4
    80001ea2:	f4bc                	sd	a5,104(s1)
}
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	60e2                	ld	ra,24(sp)
    80001ea8:	6442                	ld	s0,16(sp)
    80001eaa:	64a2                	ld	s1,8(sp)
    80001eac:	6902                	ld	s2,0(sp)
    80001eae:	6105                	add	sp,sp,32
    80001eb0:	8082                	ret
    freeproc(p);
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	00000097          	auipc	ra,0x0
    80001eb8:	e5c080e7          	jalr	-420(ra) # 80001d10 <freeproc>
    release(&p->lock);
    80001ebc:	8526                	mv	a0,s1
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	dc8080e7          	jalr	-568(ra) # 80000c86 <release>
    return 0;
    80001ec6:	84ca                	mv	s1,s2
    80001ec8:	bff1                	j	80001ea4 <allocproc+0xf2>
    freeproc(p);
    80001eca:	8526                	mv	a0,s1
    80001ecc:	00000097          	auipc	ra,0x0
    80001ed0:	e44080e7          	jalr	-444(ra) # 80001d10 <freeproc>
    release(&p->lock);
    80001ed4:	8526                	mv	a0,s1
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	db0080e7          	jalr	-592(ra) # 80000c86 <release>
    return 0;
    80001ede:	84ca                	mv	s1,s2
    80001ee0:	b7d1                	j	80001ea4 <allocproc+0xf2>

0000000080001ee2 <userinit>:
{
    80001ee2:	1101                	add	sp,sp,-32
    80001ee4:	ec06                	sd	ra,24(sp)
    80001ee6:	e822                	sd	s0,16(sp)
    80001ee8:	e426                	sd	s1,8(sp)
    80001eea:	1000                	add	s0,sp,32
  p = allocproc();
    80001eec:	00000097          	auipc	ra,0x0
    80001ef0:	ec6080e7          	jalr	-314(ra) # 80001db2 <allocproc>
    80001ef4:	84aa                	mv	s1,a0
  initproc = p;
    80001ef6:	00007797          	auipc	a5,0x7
    80001efa:	a4a7bd23          	sd	a0,-1446(a5) # 80008950 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001efe:	03400613          	li	a2,52
    80001f02:	00007597          	auipc	a1,0x7
    80001f06:	9de58593          	add	a1,a1,-1570 # 800088e0 <initcode>
    80001f0a:	6928                	ld	a0,80(a0)
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	444080e7          	jalr	1092(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001f14:	6785                	lui	a5,0x1
    80001f16:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f18:	6cb8                	ld	a4,88(s1)
    80001f1a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f1e:	6cb8                	ld	a4,88(s1)
    80001f20:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f22:	4641                	li	a2,16
    80001f24:	00006597          	auipc	a1,0x6
    80001f28:	30c58593          	add	a1,a1,780 # 80008230 <digits+0x1f0>
    80001f2c:	15848513          	add	a0,s1,344
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	ee6080e7          	jalr	-282(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001f38:	00006517          	auipc	a0,0x6
    80001f3c:	30850513          	add	a0,a0,776 # 80008240 <digits+0x200>
    80001f40:	00002097          	auipc	ra,0x2
    80001f44:	3f6080e7          	jalr	1014(ra) # 80004336 <namei>
    80001f48:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f4c:	478d                	li	a5,3
    80001f4e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f50:	8526                	mv	a0,s1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	d34080e7          	jalr	-716(ra) # 80000c86 <release>
}
    80001f5a:	60e2                	ld	ra,24(sp)
    80001f5c:	6442                	ld	s0,16(sp)
    80001f5e:	64a2                	ld	s1,8(sp)
    80001f60:	6105                	add	sp,sp,32
    80001f62:	8082                	ret

0000000080001f64 <growproc>:
{
    80001f64:	1101                	add	sp,sp,-32
    80001f66:	ec06                	sd	ra,24(sp)
    80001f68:	e822                	sd	s0,16(sp)
    80001f6a:	e426                	sd	s1,8(sp)
    80001f6c:	e04a                	sd	s2,0(sp)
    80001f6e:	1000                	add	s0,sp,32
    80001f70:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	bec080e7          	jalr	-1044(ra) # 80001b5e <myproc>
    80001f7a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f7c:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001f7e:	01204c63          	bgtz	s2,80001f96 <growproc+0x32>
  } else if(n < 0){
    80001f82:	02094663          	bltz	s2,80001fae <growproc+0x4a>
  p->sz = sz;
    80001f86:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f88:	4501                	li	a0,0
}
    80001f8a:	60e2                	ld	ra,24(sp)
    80001f8c:	6442                	ld	s0,16(sp)
    80001f8e:	64a2                	ld	s1,8(sp)
    80001f90:	6902                	ld	s2,0(sp)
    80001f92:	6105                	add	sp,sp,32
    80001f94:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001f96:	4691                	li	a3,4
    80001f98:	00b90633          	add	a2,s2,a1
    80001f9c:	6928                	ld	a0,80(a0)
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	46c080e7          	jalr	1132(ra) # 8000140a <uvmalloc>
    80001fa6:	85aa                	mv	a1,a0
    80001fa8:	fd79                	bnez	a0,80001f86 <growproc+0x22>
      return -1;
    80001faa:	557d                	li	a0,-1
    80001fac:	bff9                	j	80001f8a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fae:	00b90633          	add	a2,s2,a1
    80001fb2:	6928                	ld	a0,80(a0)
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	40e080e7          	jalr	1038(ra) # 800013c2 <uvmdealloc>
    80001fbc:	85aa                	mv	a1,a0
    80001fbe:	b7e1                	j	80001f86 <growproc+0x22>

0000000080001fc0 <fork>:
{
    80001fc0:	7139                	add	sp,sp,-64
    80001fc2:	fc06                	sd	ra,56(sp)
    80001fc4:	f822                	sd	s0,48(sp)
    80001fc6:	f426                	sd	s1,40(sp)
    80001fc8:	f04a                	sd	s2,32(sp)
    80001fca:	ec4e                	sd	s3,24(sp)
    80001fcc:	e852                	sd	s4,16(sp)
    80001fce:	e456                	sd	s5,8(sp)
    80001fd0:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001fd2:	00000097          	auipc	ra,0x0
    80001fd6:	b8c080e7          	jalr	-1140(ra) # 80001b5e <myproc>
    80001fda:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001fdc:	00000097          	auipc	ra,0x0
    80001fe0:	dd6080e7          	jalr	-554(ra) # 80001db2 <allocproc>
    80001fe4:	10050c63          	beqz	a0,800020fc <fork+0x13c>
    80001fe8:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001fea:	048ab603          	ld	a2,72(s5)
    80001fee:	692c                	ld	a1,80(a0)
    80001ff0:	050ab503          	ld	a0,80(s5)
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	56e080e7          	jalr	1390(ra) # 80001562 <uvmcopy>
    80001ffc:	04054863          	bltz	a0,8000204c <fork+0x8c>
  np->sz = p->sz;
    80002000:	048ab783          	ld	a5,72(s5)
    80002004:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80002008:	058ab683          	ld	a3,88(s5)
    8000200c:	87b6                	mv	a5,a3
    8000200e:	058a3703          	ld	a4,88(s4)
    80002012:	12068693          	add	a3,a3,288
    80002016:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000201a:	6788                	ld	a0,8(a5)
    8000201c:	6b8c                	ld	a1,16(a5)
    8000201e:	6f90                	ld	a2,24(a5)
    80002020:	01073023          	sd	a6,0(a4)
    80002024:	e708                	sd	a0,8(a4)
    80002026:	eb0c                	sd	a1,16(a4)
    80002028:	ef10                	sd	a2,24(a4)
    8000202a:	02078793          	add	a5,a5,32
    8000202e:	02070713          	add	a4,a4,32
    80002032:	fed792e3          	bne	a5,a3,80002016 <fork+0x56>
  np->trapframe->a0 = 0;
    80002036:	058a3783          	ld	a5,88(s4)
    8000203a:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000203e:	0d0a8493          	add	s1,s5,208
    80002042:	0d0a0913          	add	s2,s4,208
    80002046:	150a8993          	add	s3,s5,336
    8000204a:	a00d                	j	8000206c <fork+0xac>
    freeproc(np);
    8000204c:	8552                	mv	a0,s4
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	cc2080e7          	jalr	-830(ra) # 80001d10 <freeproc>
    release(&np->lock);
    80002056:	8552                	mv	a0,s4
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	c2e080e7          	jalr	-978(ra) # 80000c86 <release>
    return -1;
    80002060:	597d                	li	s2,-1
    80002062:	a059                	j	800020e8 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80002064:	04a1                	add	s1,s1,8
    80002066:	0921                	add	s2,s2,8
    80002068:	01348b63          	beq	s1,s3,8000207e <fork+0xbe>
    if(p->ofile[i])
    8000206c:	6088                	ld	a0,0(s1)
    8000206e:	d97d                	beqz	a0,80002064 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002070:	00003097          	auipc	ra,0x3
    80002074:	938080e7          	jalr	-1736(ra) # 800049a8 <filedup>
    80002078:	00a93023          	sd	a0,0(s2)
    8000207c:	b7e5                	j	80002064 <fork+0xa4>
  np->cwd = idup(p->cwd);
    8000207e:	150ab503          	ld	a0,336(s5)
    80002082:	00002097          	auipc	ra,0x2
    80002086:	ad0080e7          	jalr	-1328(ra) # 80003b52 <idup>
    8000208a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000208e:	4641                	li	a2,16
    80002090:	158a8593          	add	a1,s5,344
    80002094:	158a0513          	add	a0,s4,344
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	d7e080e7          	jalr	-642(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    800020a0:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    800020a4:	8552                	mv	a0,s4
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	be0080e7          	jalr	-1056(ra) # 80000c86 <release>
  acquire(&wait_lock);
    800020ae:	0000f497          	auipc	s1,0xf
    800020b2:	b3a48493          	add	s1,s1,-1222 # 80010be8 <wait_lock>
    800020b6:	8526                	mv	a0,s1
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	b1a080e7          	jalr	-1254(ra) # 80000bd2 <acquire>
  np->parent = p;
    800020c0:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    800020c4:	8526                	mv	a0,s1
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	bc0080e7          	jalr	-1088(ra) # 80000c86 <release>
  acquire(&np->lock);
    800020ce:	8552                	mv	a0,s4
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	b02080e7          	jalr	-1278(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    800020d8:	478d                	li	a5,3
    800020da:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    800020de:	8552                	mv	a0,s4
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	ba6080e7          	jalr	-1114(ra) # 80000c86 <release>
}
    800020e8:	854a                	mv	a0,s2
    800020ea:	70e2                	ld	ra,56(sp)
    800020ec:	7442                	ld	s0,48(sp)
    800020ee:	74a2                	ld	s1,40(sp)
    800020f0:	7902                	ld	s2,32(sp)
    800020f2:	69e2                	ld	s3,24(sp)
    800020f4:	6a42                	ld	s4,16(sp)
    800020f6:	6aa2                	ld	s5,8(sp)
    800020f8:	6121                	add	sp,sp,64
    800020fa:	8082                	ret
    return -1;
    800020fc:	597d                	li	s2,-1
    800020fe:	b7ed                	j	800020e8 <fork+0x128>

0000000080002100 <scheduler>:
{
    80002100:	7139                	add	sp,sp,-64
    80002102:	fc06                	sd	ra,56(sp)
    80002104:	f822                	sd	s0,48(sp)
    80002106:	f426                	sd	s1,40(sp)
    80002108:	f04a                	sd	s2,32(sp)
    8000210a:	ec4e                	sd	s3,24(sp)
    8000210c:	e852                	sd	s4,16(sp)
    8000210e:	e456                	sd	s5,8(sp)
    80002110:	e05a                	sd	s6,0(sp)
    80002112:	0080                	add	s0,sp,64
    80002114:	8792                	mv	a5,tp
  int id = r_tp();
    80002116:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002118:	00779a93          	sll	s5,a5,0x7
    8000211c:	0000f717          	auipc	a4,0xf
    80002120:	ab470713          	add	a4,a4,-1356 # 80010bd0 <pid_lock>
    80002124:	9756                	add	a4,a4,s5
    80002126:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    8000212a:	0000f717          	auipc	a4,0xf
    8000212e:	ade70713          	add	a4,a4,-1314 # 80010c08 <cpus+0x8>
    80002132:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002134:	498d                	li	s3,3
        p->state = RUNNING;
    80002136:	4b11                	li	s6,4
        c->proc = p;
    80002138:	079e                	sll	a5,a5,0x7
    8000213a:	0000fa17          	auipc	s4,0xf
    8000213e:	a96a0a13          	add	s4,s4,-1386 # 80010bd0 <pid_lock>
    80002142:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002144:	00015917          	auipc	s2,0x15
    80002148:	cbc90913          	add	s2,s2,-836 # 80016e00 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000214c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002150:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002154:	10079073          	csrw	sstatus,a5
    80002158:	0000f497          	auipc	s1,0xf
    8000215c:	2a848493          	add	s1,s1,680 # 80011400 <proc>
    80002160:	a811                	j	80002174 <scheduler+0x74>
      release(&p->lock);
    80002162:	8526                	mv	a0,s1
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	b22080e7          	jalr	-1246(ra) # 80000c86 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000216c:	16848493          	add	s1,s1,360
    80002170:	fd248ee3          	beq	s1,s2,8000214c <scheduler+0x4c>
      acquire(&p->lock);
    80002174:	8526                	mv	a0,s1
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	a5c080e7          	jalr	-1444(ra) # 80000bd2 <acquire>
      if(p->state == RUNNABLE) {
    8000217e:	4c9c                	lw	a5,24(s1)
    80002180:	ff3791e3          	bne	a5,s3,80002162 <scheduler+0x62>
        p->state = RUNNING;
    80002184:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002188:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000218c:	06048593          	add	a1,s1,96
    80002190:	8556                	mv	a0,s5
    80002192:	00001097          	auipc	ra,0x1
    80002196:	8b6080e7          	jalr	-1866(ra) # 80002a48 <swtch>
        c->proc = 0;
    8000219a:	020a3823          	sd	zero,48(s4)
    8000219e:	b7d1                	j	80002162 <scheduler+0x62>

00000000800021a0 <sched>:
{
    800021a0:	7179                	add	sp,sp,-48
    800021a2:	f406                	sd	ra,40(sp)
    800021a4:	f022                	sd	s0,32(sp)
    800021a6:	ec26                	sd	s1,24(sp)
    800021a8:	e84a                	sd	s2,16(sp)
    800021aa:	e44e                	sd	s3,8(sp)
    800021ac:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    800021ae:	00000097          	auipc	ra,0x0
    800021b2:	9b0080e7          	jalr	-1616(ra) # 80001b5e <myproc>
    800021b6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	9a0080e7          	jalr	-1632(ra) # 80000b58 <holding>
    800021c0:	c93d                	beqz	a0,80002236 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021c2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021c4:	2781                	sext.w	a5,a5
    800021c6:	079e                	sll	a5,a5,0x7
    800021c8:	0000f717          	auipc	a4,0xf
    800021cc:	a0870713          	add	a4,a4,-1528 # 80010bd0 <pid_lock>
    800021d0:	97ba                	add	a5,a5,a4
    800021d2:	0a87a703          	lw	a4,168(a5)
    800021d6:	4785                	li	a5,1
    800021d8:	06f71763          	bne	a4,a5,80002246 <sched+0xa6>
  if(p->state == RUNNING)
    800021dc:	4c98                	lw	a4,24(s1)
    800021de:	4791                	li	a5,4
    800021e0:	06f70b63          	beq	a4,a5,80002256 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021e4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021e8:	8b89                	and	a5,a5,2
  if(intr_get())
    800021ea:	efb5                	bnez	a5,80002266 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021ec:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021ee:	0000f917          	auipc	s2,0xf
    800021f2:	9e290913          	add	s2,s2,-1566 # 80010bd0 <pid_lock>
    800021f6:	2781                	sext.w	a5,a5
    800021f8:	079e                	sll	a5,a5,0x7
    800021fa:	97ca                	add	a5,a5,s2
    800021fc:	0ac7a983          	lw	s3,172(a5)
    80002200:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002202:	2781                	sext.w	a5,a5
    80002204:	079e                	sll	a5,a5,0x7
    80002206:	0000f597          	auipc	a1,0xf
    8000220a:	a0258593          	add	a1,a1,-1534 # 80010c08 <cpus+0x8>
    8000220e:	95be                	add	a1,a1,a5
    80002210:	06048513          	add	a0,s1,96
    80002214:	00001097          	auipc	ra,0x1
    80002218:	834080e7          	jalr	-1996(ra) # 80002a48 <swtch>
    8000221c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000221e:	2781                	sext.w	a5,a5
    80002220:	079e                	sll	a5,a5,0x7
    80002222:	993e                	add	s2,s2,a5
    80002224:	0b392623          	sw	s3,172(s2)
}
    80002228:	70a2                	ld	ra,40(sp)
    8000222a:	7402                	ld	s0,32(sp)
    8000222c:	64e2                	ld	s1,24(sp)
    8000222e:	6942                	ld	s2,16(sp)
    80002230:	69a2                	ld	s3,8(sp)
    80002232:	6145                	add	sp,sp,48
    80002234:	8082                	ret
    panic("sched p->lock");
    80002236:	00006517          	auipc	a0,0x6
    8000223a:	01250513          	add	a0,a0,18 # 80008248 <digits+0x208>
    8000223e:	ffffe097          	auipc	ra,0xffffe
    80002242:	2fe080e7          	jalr	766(ra) # 8000053c <panic>
    panic("sched locks");
    80002246:	00006517          	auipc	a0,0x6
    8000224a:	01250513          	add	a0,a0,18 # 80008258 <digits+0x218>
    8000224e:	ffffe097          	auipc	ra,0xffffe
    80002252:	2ee080e7          	jalr	750(ra) # 8000053c <panic>
    panic("sched running");
    80002256:	00006517          	auipc	a0,0x6
    8000225a:	01250513          	add	a0,a0,18 # 80008268 <digits+0x228>
    8000225e:	ffffe097          	auipc	ra,0xffffe
    80002262:	2de080e7          	jalr	734(ra) # 8000053c <panic>
    panic("sched interruptible");
    80002266:	00006517          	auipc	a0,0x6
    8000226a:	01250513          	add	a0,a0,18 # 80008278 <digits+0x238>
    8000226e:	ffffe097          	auipc	ra,0xffffe
    80002272:	2ce080e7          	jalr	718(ra) # 8000053c <panic>

0000000080002276 <yield>:
{
    80002276:	1101                	add	sp,sp,-32
    80002278:	ec06                	sd	ra,24(sp)
    8000227a:	e822                	sd	s0,16(sp)
    8000227c:	e426                	sd	s1,8(sp)
    8000227e:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80002280:	00000097          	auipc	ra,0x0
    80002284:	8de080e7          	jalr	-1826(ra) # 80001b5e <myproc>
    80002288:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	948080e7          	jalr	-1720(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    80002292:	478d                	li	a5,3
    80002294:	cc9c                	sw	a5,24(s1)
  sched();
    80002296:	00000097          	auipc	ra,0x0
    8000229a:	f0a080e7          	jalr	-246(ra) # 800021a0 <sched>
  release(&p->lock);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	9e6080e7          	jalr	-1562(ra) # 80000c86 <release>
}
    800022a8:	60e2                	ld	ra,24(sp)
    800022aa:	6442                	ld	s0,16(sp)
    800022ac:	64a2                	ld	s1,8(sp)
    800022ae:	6105                	add	sp,sp,32
    800022b0:	8082                	ret

00000000800022b2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800022b2:	7179                	add	sp,sp,-48
    800022b4:	f406                	sd	ra,40(sp)
    800022b6:	f022                	sd	s0,32(sp)
    800022b8:	ec26                	sd	s1,24(sp)
    800022ba:	e84a                	sd	s2,16(sp)
    800022bc:	e44e                	sd	s3,8(sp)
    800022be:	1800                	add	s0,sp,48
    800022c0:	89aa                	mv	s3,a0
    800022c2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	89a080e7          	jalr	-1894(ra) # 80001b5e <myproc>
    800022cc:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	904080e7          	jalr	-1788(ra) # 80000bd2 <acquire>
  release(lk);
    800022d6:	854a                	mv	a0,s2
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	9ae080e7          	jalr	-1618(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    800022e0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800022e4:	4789                	li	a5,2
    800022e6:	cc9c                	sw	a5,24(s1)

  sched();
    800022e8:	00000097          	auipc	ra,0x0
    800022ec:	eb8080e7          	jalr	-328(ra) # 800021a0 <sched>

  // Tidy up.
  p->chan = 0;
    800022f0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800022f4:	8526                	mv	a0,s1
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	990080e7          	jalr	-1648(ra) # 80000c86 <release>
  acquire(lk);
    800022fe:	854a                	mv	a0,s2
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	8d2080e7          	jalr	-1838(ra) # 80000bd2 <acquire>
}
    80002308:	70a2                	ld	ra,40(sp)
    8000230a:	7402                	ld	s0,32(sp)
    8000230c:	64e2                	ld	s1,24(sp)
    8000230e:	6942                	ld	s2,16(sp)
    80002310:	69a2                	ld	s3,8(sp)
    80002312:	6145                	add	sp,sp,48
    80002314:	8082                	ret

0000000080002316 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002316:	7139                	add	sp,sp,-64
    80002318:	fc06                	sd	ra,56(sp)
    8000231a:	f822                	sd	s0,48(sp)
    8000231c:	f426                	sd	s1,40(sp)
    8000231e:	f04a                	sd	s2,32(sp)
    80002320:	ec4e                	sd	s3,24(sp)
    80002322:	e852                	sd	s4,16(sp)
    80002324:	e456                	sd	s5,8(sp)
    80002326:	0080                	add	s0,sp,64
    80002328:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000232a:	0000f497          	auipc	s1,0xf
    8000232e:	0d648493          	add	s1,s1,214 # 80011400 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002332:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002334:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002336:	00015917          	auipc	s2,0x15
    8000233a:	aca90913          	add	s2,s2,-1334 # 80016e00 <tickslock>
    8000233e:	a811                	j	80002352 <wakeup+0x3c>
      }
      release(&p->lock);
    80002340:	8526                	mv	a0,s1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	944080e7          	jalr	-1724(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000234a:	16848493          	add	s1,s1,360
    8000234e:	03248663          	beq	s1,s2,8000237a <wakeup+0x64>
    if(p != myproc()){
    80002352:	00000097          	auipc	ra,0x0
    80002356:	80c080e7          	jalr	-2036(ra) # 80001b5e <myproc>
    8000235a:	fea488e3          	beq	s1,a0,8000234a <wakeup+0x34>
      acquire(&p->lock);
    8000235e:	8526                	mv	a0,s1
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	872080e7          	jalr	-1934(ra) # 80000bd2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002368:	4c9c                	lw	a5,24(s1)
    8000236a:	fd379be3          	bne	a5,s3,80002340 <wakeup+0x2a>
    8000236e:	709c                	ld	a5,32(s1)
    80002370:	fd4798e3          	bne	a5,s4,80002340 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002374:	0154ac23          	sw	s5,24(s1)
    80002378:	b7e1                	j	80002340 <wakeup+0x2a>
    }
  }
}
    8000237a:	70e2                	ld	ra,56(sp)
    8000237c:	7442                	ld	s0,48(sp)
    8000237e:	74a2                	ld	s1,40(sp)
    80002380:	7902                	ld	s2,32(sp)
    80002382:	69e2                	ld	s3,24(sp)
    80002384:	6a42                	ld	s4,16(sp)
    80002386:	6aa2                	ld	s5,8(sp)
    80002388:	6121                	add	sp,sp,64
    8000238a:	8082                	ret

000000008000238c <reparent>:
{
    8000238c:	7179                	add	sp,sp,-48
    8000238e:	f406                	sd	ra,40(sp)
    80002390:	f022                	sd	s0,32(sp)
    80002392:	ec26                	sd	s1,24(sp)
    80002394:	e84a                	sd	s2,16(sp)
    80002396:	e44e                	sd	s3,8(sp)
    80002398:	e052                	sd	s4,0(sp)
    8000239a:	1800                	add	s0,sp,48
    8000239c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000239e:	0000f497          	auipc	s1,0xf
    800023a2:	06248493          	add	s1,s1,98 # 80011400 <proc>
      pp->parent = initproc;
    800023a6:	00006a17          	auipc	s4,0x6
    800023aa:	5aaa0a13          	add	s4,s4,1450 # 80008950 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023ae:	00015997          	auipc	s3,0x15
    800023b2:	a5298993          	add	s3,s3,-1454 # 80016e00 <tickslock>
    800023b6:	a029                	j	800023c0 <reparent+0x34>
    800023b8:	16848493          	add	s1,s1,360
    800023bc:	01348d63          	beq	s1,s3,800023d6 <reparent+0x4a>
    if(pp->parent == p){
    800023c0:	7c9c                	ld	a5,56(s1)
    800023c2:	ff279be3          	bne	a5,s2,800023b8 <reparent+0x2c>
      pp->parent = initproc;
    800023c6:	000a3503          	ld	a0,0(s4)
    800023ca:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023cc:	00000097          	auipc	ra,0x0
    800023d0:	f4a080e7          	jalr	-182(ra) # 80002316 <wakeup>
    800023d4:	b7d5                	j	800023b8 <reparent+0x2c>
}
    800023d6:	70a2                	ld	ra,40(sp)
    800023d8:	7402                	ld	s0,32(sp)
    800023da:	64e2                	ld	s1,24(sp)
    800023dc:	6942                	ld	s2,16(sp)
    800023de:	69a2                	ld	s3,8(sp)
    800023e0:	6a02                	ld	s4,0(sp)
    800023e2:	6145                	add	sp,sp,48
    800023e4:	8082                	ret

00000000800023e6 <exit>:
{
    800023e6:	7179                	add	sp,sp,-48
    800023e8:	f406                	sd	ra,40(sp)
    800023ea:	f022                	sd	s0,32(sp)
    800023ec:	ec26                	sd	s1,24(sp)
    800023ee:	e84a                	sd	s2,16(sp)
    800023f0:	e44e                	sd	s3,8(sp)
    800023f2:	e052                	sd	s4,0(sp)
    800023f4:	1800                	add	s0,sp,48
    800023f6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	766080e7          	jalr	1894(ra) # 80001b5e <myproc>
    80002400:	89aa                	mv	s3,a0
  if(p == initproc)
    80002402:	00006797          	auipc	a5,0x6
    80002406:	54e7b783          	ld	a5,1358(a5) # 80008950 <initproc>
    8000240a:	0d050493          	add	s1,a0,208
    8000240e:	15050913          	add	s2,a0,336
    80002412:	02a79363          	bne	a5,a0,80002438 <exit+0x52>
    panic("init exiting");
    80002416:	00006517          	auipc	a0,0x6
    8000241a:	e7a50513          	add	a0,a0,-390 # 80008290 <digits+0x250>
    8000241e:	ffffe097          	auipc	ra,0xffffe
    80002422:	11e080e7          	jalr	286(ra) # 8000053c <panic>
      fileclose(f);
    80002426:	00002097          	auipc	ra,0x2
    8000242a:	5d4080e7          	jalr	1492(ra) # 800049fa <fileclose>
      p->ofile[fd] = 0;
    8000242e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002432:	04a1                	add	s1,s1,8
    80002434:	01248563          	beq	s1,s2,8000243e <exit+0x58>
    if(p->ofile[fd]){
    80002438:	6088                	ld	a0,0(s1)
    8000243a:	f575                	bnez	a0,80002426 <exit+0x40>
    8000243c:	bfdd                	j	80002432 <exit+0x4c>
  begin_op();
    8000243e:	00002097          	auipc	ra,0x2
    80002442:	0f8080e7          	jalr	248(ra) # 80004536 <begin_op>
  iput(p->cwd);
    80002446:	1509b503          	ld	a0,336(s3)
    8000244a:	00002097          	auipc	ra,0x2
    8000244e:	900080e7          	jalr	-1792(ra) # 80003d4a <iput>
  end_op();
    80002452:	00002097          	auipc	ra,0x2
    80002456:	15e080e7          	jalr	350(ra) # 800045b0 <end_op>
  p->cwd = 0;
    8000245a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000245e:	0000e497          	auipc	s1,0xe
    80002462:	78a48493          	add	s1,s1,1930 # 80010be8 <wait_lock>
    80002466:	8526                	mv	a0,s1
    80002468:	ffffe097          	auipc	ra,0xffffe
    8000246c:	76a080e7          	jalr	1898(ra) # 80000bd2 <acquire>
  reparent(p);
    80002470:	854e                	mv	a0,s3
    80002472:	00000097          	auipc	ra,0x0
    80002476:	f1a080e7          	jalr	-230(ra) # 8000238c <reparent>
  wakeup(p->parent);
    8000247a:	0389b503          	ld	a0,56(s3)
    8000247e:	00000097          	auipc	ra,0x0
    80002482:	e98080e7          	jalr	-360(ra) # 80002316 <wakeup>
  acquire(&p->lock);
    80002486:	854e                	mv	a0,s3
    80002488:	ffffe097          	auipc	ra,0xffffe
    8000248c:	74a080e7          	jalr	1866(ra) # 80000bd2 <acquire>
  p->xstate = status;
    80002490:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002494:	4795                	li	a5,5
    80002496:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000249a:	8526                	mv	a0,s1
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	7ea080e7          	jalr	2026(ra) # 80000c86 <release>
  sched();
    800024a4:	00000097          	auipc	ra,0x0
    800024a8:	cfc080e7          	jalr	-772(ra) # 800021a0 <sched>
  panic("zombie exit");
    800024ac:	00006517          	auipc	a0,0x6
    800024b0:	df450513          	add	a0,a0,-524 # 800082a0 <digits+0x260>
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	088080e7          	jalr	136(ra) # 8000053c <panic>

00000000800024bc <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024bc:	7179                	add	sp,sp,-48
    800024be:	f406                	sd	ra,40(sp)
    800024c0:	f022                	sd	s0,32(sp)
    800024c2:	ec26                	sd	s1,24(sp)
    800024c4:	e84a                	sd	s2,16(sp)
    800024c6:	e44e                	sd	s3,8(sp)
    800024c8:	1800                	add	s0,sp,48
    800024ca:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024cc:	0000f497          	auipc	s1,0xf
    800024d0:	f3448493          	add	s1,s1,-204 # 80011400 <proc>
    800024d4:	00015997          	auipc	s3,0x15
    800024d8:	92c98993          	add	s3,s3,-1748 # 80016e00 <tickslock>
    acquire(&p->lock);
    800024dc:	8526                	mv	a0,s1
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	6f4080e7          	jalr	1780(ra) # 80000bd2 <acquire>
    if(p->pid == pid){
    800024e6:	589c                	lw	a5,48(s1)
    800024e8:	01278d63          	beq	a5,s2,80002502 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024ec:	8526                	mv	a0,s1
    800024ee:	ffffe097          	auipc	ra,0xffffe
    800024f2:	798080e7          	jalr	1944(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024f6:	16848493          	add	s1,s1,360
    800024fa:	ff3491e3          	bne	s1,s3,800024dc <kill+0x20>
  }
  return -1;
    800024fe:	557d                	li	a0,-1
    80002500:	a829                	j	8000251a <kill+0x5e>
      p->killed = 1;
    80002502:	4785                	li	a5,1
    80002504:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002506:	4c98                	lw	a4,24(s1)
    80002508:	4789                	li	a5,2
    8000250a:	00f70f63          	beq	a4,a5,80002528 <kill+0x6c>
      release(&p->lock);
    8000250e:	8526                	mv	a0,s1
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	776080e7          	jalr	1910(ra) # 80000c86 <release>
      return 0;
    80002518:	4501                	li	a0,0
}
    8000251a:	70a2                	ld	ra,40(sp)
    8000251c:	7402                	ld	s0,32(sp)
    8000251e:	64e2                	ld	s1,24(sp)
    80002520:	6942                	ld	s2,16(sp)
    80002522:	69a2                	ld	s3,8(sp)
    80002524:	6145                	add	sp,sp,48
    80002526:	8082                	ret
        p->state = RUNNABLE;
    80002528:	478d                	li	a5,3
    8000252a:	cc9c                	sw	a5,24(s1)
    8000252c:	b7cd                	j	8000250e <kill+0x52>

000000008000252e <setkilled>:

void
setkilled(struct proc *p)
{
    8000252e:	1101                	add	sp,sp,-32
    80002530:	ec06                	sd	ra,24(sp)
    80002532:	e822                	sd	s0,16(sp)
    80002534:	e426                	sd	s1,8(sp)
    80002536:	1000                	add	s0,sp,32
    80002538:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000253a:	ffffe097          	auipc	ra,0xffffe
    8000253e:	698080e7          	jalr	1688(ra) # 80000bd2 <acquire>
  p->killed = 1;
    80002542:	4785                	li	a5,1
    80002544:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002546:	8526                	mv	a0,s1
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	73e080e7          	jalr	1854(ra) # 80000c86 <release>
}
    80002550:	60e2                	ld	ra,24(sp)
    80002552:	6442                	ld	s0,16(sp)
    80002554:	64a2                	ld	s1,8(sp)
    80002556:	6105                	add	sp,sp,32
    80002558:	8082                	ret

000000008000255a <killed>:

int
killed(struct proc *p)
{
    8000255a:	1101                	add	sp,sp,-32
    8000255c:	ec06                	sd	ra,24(sp)
    8000255e:	e822                	sd	s0,16(sp)
    80002560:	e426                	sd	s1,8(sp)
    80002562:	e04a                	sd	s2,0(sp)
    80002564:	1000                	add	s0,sp,32
    80002566:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	66a080e7          	jalr	1642(ra) # 80000bd2 <acquire>
  k = p->killed;
    80002570:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002574:	8526                	mv	a0,s1
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	710080e7          	jalr	1808(ra) # 80000c86 <release>
  return k;
}
    8000257e:	854a                	mv	a0,s2
    80002580:	60e2                	ld	ra,24(sp)
    80002582:	6442                	ld	s0,16(sp)
    80002584:	64a2                	ld	s1,8(sp)
    80002586:	6902                	ld	s2,0(sp)
    80002588:	6105                	add	sp,sp,32
    8000258a:	8082                	ret

000000008000258c <wait>:
{
    8000258c:	715d                	add	sp,sp,-80
    8000258e:	e486                	sd	ra,72(sp)
    80002590:	e0a2                	sd	s0,64(sp)
    80002592:	fc26                	sd	s1,56(sp)
    80002594:	f84a                	sd	s2,48(sp)
    80002596:	f44e                	sd	s3,40(sp)
    80002598:	f052                	sd	s4,32(sp)
    8000259a:	ec56                	sd	s5,24(sp)
    8000259c:	e85a                	sd	s6,16(sp)
    8000259e:	e45e                	sd	s7,8(sp)
    800025a0:	e062                	sd	s8,0(sp)
    800025a2:	0880                	add	s0,sp,80
    800025a4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025a6:	fffff097          	auipc	ra,0xfffff
    800025aa:	5b8080e7          	jalr	1464(ra) # 80001b5e <myproc>
    800025ae:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800025b0:	0000e517          	auipc	a0,0xe
    800025b4:	63850513          	add	a0,a0,1592 # 80010be8 <wait_lock>
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	61a080e7          	jalr	1562(ra) # 80000bd2 <acquire>
    havekids = 0;
    800025c0:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800025c2:	4a15                	li	s4,5
        havekids = 1;
    800025c4:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800025c6:	00015997          	auipc	s3,0x15
    800025ca:	83a98993          	add	s3,s3,-1990 # 80016e00 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025ce:	0000ec17          	auipc	s8,0xe
    800025d2:	61ac0c13          	add	s8,s8,1562 # 80010be8 <wait_lock>
    800025d6:	a0d1                	j	8000269a <wait+0x10e>
          pid = pp->pid;
    800025d8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800025dc:	000b0e63          	beqz	s6,800025f8 <wait+0x6c>
    800025e0:	4691                	li	a3,4
    800025e2:	02c48613          	add	a2,s1,44
    800025e6:	85da                	mv	a1,s6
    800025e8:	05093503          	ld	a0,80(s2)
    800025ec:	fffff097          	auipc	ra,0xfffff
    800025f0:	07a080e7          	jalr	122(ra) # 80001666 <copyout>
    800025f4:	04054163          	bltz	a0,80002636 <wait+0xaa>
          freeproc(pp);
    800025f8:	8526                	mv	a0,s1
    800025fa:	fffff097          	auipc	ra,0xfffff
    800025fe:	716080e7          	jalr	1814(ra) # 80001d10 <freeproc>
          release(&pp->lock);
    80002602:	8526                	mv	a0,s1
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	682080e7          	jalr	1666(ra) # 80000c86 <release>
          release(&wait_lock);
    8000260c:	0000e517          	auipc	a0,0xe
    80002610:	5dc50513          	add	a0,a0,1500 # 80010be8 <wait_lock>
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	672080e7          	jalr	1650(ra) # 80000c86 <release>
}
    8000261c:	854e                	mv	a0,s3
    8000261e:	60a6                	ld	ra,72(sp)
    80002620:	6406                	ld	s0,64(sp)
    80002622:	74e2                	ld	s1,56(sp)
    80002624:	7942                	ld	s2,48(sp)
    80002626:	79a2                	ld	s3,40(sp)
    80002628:	7a02                	ld	s4,32(sp)
    8000262a:	6ae2                	ld	s5,24(sp)
    8000262c:	6b42                	ld	s6,16(sp)
    8000262e:	6ba2                	ld	s7,8(sp)
    80002630:	6c02                	ld	s8,0(sp)
    80002632:	6161                	add	sp,sp,80
    80002634:	8082                	ret
            release(&pp->lock);
    80002636:	8526                	mv	a0,s1
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	64e080e7          	jalr	1614(ra) # 80000c86 <release>
            release(&wait_lock);
    80002640:	0000e517          	auipc	a0,0xe
    80002644:	5a850513          	add	a0,a0,1448 # 80010be8 <wait_lock>
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	63e080e7          	jalr	1598(ra) # 80000c86 <release>
            return -1;
    80002650:	59fd                	li	s3,-1
    80002652:	b7e9                	j	8000261c <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002654:	16848493          	add	s1,s1,360
    80002658:	03348463          	beq	s1,s3,80002680 <wait+0xf4>
      if(pp->parent == p){
    8000265c:	7c9c                	ld	a5,56(s1)
    8000265e:	ff279be3          	bne	a5,s2,80002654 <wait+0xc8>
        acquire(&pp->lock);
    80002662:	8526                	mv	a0,s1
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	56e080e7          	jalr	1390(ra) # 80000bd2 <acquire>
        if(pp->state == ZOMBIE){
    8000266c:	4c9c                	lw	a5,24(s1)
    8000266e:	f74785e3          	beq	a5,s4,800025d8 <wait+0x4c>
        release(&pp->lock);
    80002672:	8526                	mv	a0,s1
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	612080e7          	jalr	1554(ra) # 80000c86 <release>
        havekids = 1;
    8000267c:	8756                	mv	a4,s5
    8000267e:	bfd9                	j	80002654 <wait+0xc8>
    if(!havekids || killed(p)){
    80002680:	c31d                	beqz	a4,800026a6 <wait+0x11a>
    80002682:	854a                	mv	a0,s2
    80002684:	00000097          	auipc	ra,0x0
    80002688:	ed6080e7          	jalr	-298(ra) # 8000255a <killed>
    8000268c:	ed09                	bnez	a0,800026a6 <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000268e:	85e2                	mv	a1,s8
    80002690:	854a                	mv	a0,s2
    80002692:	00000097          	auipc	ra,0x0
    80002696:	c20080e7          	jalr	-992(ra) # 800022b2 <sleep>
    havekids = 0;
    8000269a:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000269c:	0000f497          	auipc	s1,0xf
    800026a0:	d6448493          	add	s1,s1,-668 # 80011400 <proc>
    800026a4:	bf65                	j	8000265c <wait+0xd0>
      release(&wait_lock);
    800026a6:	0000e517          	auipc	a0,0xe
    800026aa:	54250513          	add	a0,a0,1346 # 80010be8 <wait_lock>
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	5d8080e7          	jalr	1496(ra) # 80000c86 <release>
      return -1;
    800026b6:	59fd                	li	s3,-1
    800026b8:	b795                	j	8000261c <wait+0x90>

00000000800026ba <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026ba:	7179                	add	sp,sp,-48
    800026bc:	f406                	sd	ra,40(sp)
    800026be:	f022                	sd	s0,32(sp)
    800026c0:	ec26                	sd	s1,24(sp)
    800026c2:	e84a                	sd	s2,16(sp)
    800026c4:	e44e                	sd	s3,8(sp)
    800026c6:	e052                	sd	s4,0(sp)
    800026c8:	1800                	add	s0,sp,48
    800026ca:	84aa                	mv	s1,a0
    800026cc:	892e                	mv	s2,a1
    800026ce:	89b2                	mv	s3,a2
    800026d0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026d2:	fffff097          	auipc	ra,0xfffff
    800026d6:	48c080e7          	jalr	1164(ra) # 80001b5e <myproc>
  if(user_dst){
    800026da:	c08d                	beqz	s1,800026fc <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026dc:	86d2                	mv	a3,s4
    800026de:	864e                	mv	a2,s3
    800026e0:	85ca                	mv	a1,s2
    800026e2:	6928                	ld	a0,80(a0)
    800026e4:	fffff097          	auipc	ra,0xfffff
    800026e8:	f82080e7          	jalr	-126(ra) # 80001666 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026ec:	70a2                	ld	ra,40(sp)
    800026ee:	7402                	ld	s0,32(sp)
    800026f0:	64e2                	ld	s1,24(sp)
    800026f2:	6942                	ld	s2,16(sp)
    800026f4:	69a2                	ld	s3,8(sp)
    800026f6:	6a02                	ld	s4,0(sp)
    800026f8:	6145                	add	sp,sp,48
    800026fa:	8082                	ret
    memmove((char *)dst, src, len);
    800026fc:	000a061b          	sext.w	a2,s4
    80002700:	85ce                	mv	a1,s3
    80002702:	854a                	mv	a0,s2
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	626080e7          	jalr	1574(ra) # 80000d2a <memmove>
    return 0;
    8000270c:	8526                	mv	a0,s1
    8000270e:	bff9                	j	800026ec <either_copyout+0x32>

0000000080002710 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002710:	7179                	add	sp,sp,-48
    80002712:	f406                	sd	ra,40(sp)
    80002714:	f022                	sd	s0,32(sp)
    80002716:	ec26                	sd	s1,24(sp)
    80002718:	e84a                	sd	s2,16(sp)
    8000271a:	e44e                	sd	s3,8(sp)
    8000271c:	e052                	sd	s4,0(sp)
    8000271e:	1800                	add	s0,sp,48
    80002720:	892a                	mv	s2,a0
    80002722:	84ae                	mv	s1,a1
    80002724:	89b2                	mv	s3,a2
    80002726:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002728:	fffff097          	auipc	ra,0xfffff
    8000272c:	436080e7          	jalr	1078(ra) # 80001b5e <myproc>
  if(user_src){
    80002730:	c08d                	beqz	s1,80002752 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002732:	86d2                	mv	a3,s4
    80002734:	864e                	mv	a2,s3
    80002736:	85ca                	mv	a1,s2
    80002738:	6928                	ld	a0,80(a0)
    8000273a:	fffff097          	auipc	ra,0xfffff
    8000273e:	fb8080e7          	jalr	-72(ra) # 800016f2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002742:	70a2                	ld	ra,40(sp)
    80002744:	7402                	ld	s0,32(sp)
    80002746:	64e2                	ld	s1,24(sp)
    80002748:	6942                	ld	s2,16(sp)
    8000274a:	69a2                	ld	s3,8(sp)
    8000274c:	6a02                	ld	s4,0(sp)
    8000274e:	6145                	add	sp,sp,48
    80002750:	8082                	ret
    memmove(dst, (char*)src, len);
    80002752:	000a061b          	sext.w	a2,s4
    80002756:	85ce                	mv	a1,s3
    80002758:	854a                	mv	a0,s2
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	5d0080e7          	jalr	1488(ra) # 80000d2a <memmove>
    return 0;
    80002762:	8526                	mv	a0,s1
    80002764:	bff9                	j	80002742 <either_copyin+0x32>

0000000080002766 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002766:	715d                	add	sp,sp,-80
    80002768:	e486                	sd	ra,72(sp)
    8000276a:	e0a2                	sd	s0,64(sp)
    8000276c:	fc26                	sd	s1,56(sp)
    8000276e:	f84a                	sd	s2,48(sp)
    80002770:	f44e                	sd	s3,40(sp)
    80002772:	f052                	sd	s4,32(sp)
    80002774:	ec56                	sd	s5,24(sp)
    80002776:	e85a                	sd	s6,16(sp)
    80002778:	e45e                	sd	s7,8(sp)
    8000277a:	0880                	add	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000277c:	00006517          	auipc	a0,0x6
    80002780:	94c50513          	add	a0,a0,-1716 # 800080c8 <digits+0x88>
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	e02080e7          	jalr	-510(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000278c:	0000f497          	auipc	s1,0xf
    80002790:	dcc48493          	add	s1,s1,-564 # 80011558 <proc+0x158>
    80002794:	00014917          	auipc	s2,0x14
    80002798:	7c490913          	add	s2,s2,1988 # 80016f58 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000279c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000279e:	00006997          	auipc	s3,0x6
    800027a2:	b1298993          	add	s3,s3,-1262 # 800082b0 <digits+0x270>
    printf("%d %s %s", p->pid, state, p->name);
    800027a6:	00006a97          	auipc	s5,0x6
    800027aa:	b12a8a93          	add	s5,s5,-1262 # 800082b8 <digits+0x278>
    printf("\n");
    800027ae:	00006a17          	auipc	s4,0x6
    800027b2:	91aa0a13          	add	s4,s4,-1766 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027b6:	00006b97          	auipc	s7,0x6
    800027ba:	b7ab8b93          	add	s7,s7,-1158 # 80008330 <states.0>
    800027be:	a00d                	j	800027e0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027c0:	ed86a583          	lw	a1,-296(a3)
    800027c4:	8556                	mv	a0,s5
    800027c6:	ffffe097          	auipc	ra,0xffffe
    800027ca:	dc0080e7          	jalr	-576(ra) # 80000586 <printf>
    printf("\n");
    800027ce:	8552                	mv	a0,s4
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	db6080e7          	jalr	-586(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027d8:	16848493          	add	s1,s1,360
    800027dc:	03248263          	beq	s1,s2,80002800 <procdump+0x9a>
    if(p->state == UNUSED)
    800027e0:	86a6                	mv	a3,s1
    800027e2:	ec04a783          	lw	a5,-320(s1)
    800027e6:	dbed                	beqz	a5,800027d8 <procdump+0x72>
      state = "???";
    800027e8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ea:	fcfb6be3          	bltu	s6,a5,800027c0 <procdump+0x5a>
    800027ee:	02079713          	sll	a4,a5,0x20
    800027f2:	01d75793          	srl	a5,a4,0x1d
    800027f6:	97de                	add	a5,a5,s7
    800027f8:	6390                	ld	a2,0(a5)
    800027fa:	f279                	bnez	a2,800027c0 <procdump+0x5a>
      state = "???";
    800027fc:	864e                	mv	a2,s3
    800027fe:	b7c9                	j	800027c0 <procdump+0x5a>
  }
}
    80002800:	60a6                	ld	ra,72(sp)
    80002802:	6406                	ld	s0,64(sp)
    80002804:	74e2                	ld	s1,56(sp)
    80002806:	7942                	ld	s2,48(sp)
    80002808:	79a2                	ld	s3,40(sp)
    8000280a:	7a02                	ld	s4,32(sp)
    8000280c:	6ae2                	ld	s5,24(sp)
    8000280e:	6b42                	ld	s6,16(sp)
    80002810:	6ba2                	ld	s7,8(sp)
    80002812:	6161                	add	sp,sp,80
    80002814:	8082                	ret

0000000080002816 <getfilenum>:

int
getfilenum(int pid)
{
    80002816:	1141                	add	sp,sp,-16
    80002818:	e422                	sd	s0,8(sp)
    8000281a:	0800                	add	s0,sp,16
  struct proc *p;
  int open = 0, fd;

  for(p = proc; p < &proc[NPROC]; p++){
    8000281c:	0000f797          	auipc	a5,0xf
    80002820:	be478793          	add	a5,a5,-1052 # 80011400 <proc>
    80002824:	00014697          	auipc	a3,0x14
    80002828:	5dc68693          	add	a3,a3,1500 # 80016e00 <tickslock>
    if (p->pid == pid){
    8000282c:	5b98                	lw	a4,48(a5)
    8000282e:	00a70a63          	beq	a4,a0,80002842 <getfilenum+0x2c>
  for(p = proc; p < &proc[NPROC]; p++){
    80002832:	16878793          	add	a5,a5,360
    80002836:	fed79be3          	bne	a5,a3,8000282c <getfilenum+0x16>
        }
      }
      return open;
    }
  }
  return -1;
    8000283a:	557d                	li	a0,-1
}
    8000283c:	6422                	ld	s0,8(sp)
    8000283e:	0141                	add	sp,sp,16
    80002840:	8082                	ret
    80002842:	0d078713          	add	a4,a5,208
    80002846:	15078793          	add	a5,a5,336
  int open = 0, fd;
    8000284a:	4501                	li	a0,0
    8000284c:	a029                	j	80002856 <getfilenum+0x40>
          open++;
    8000284e:	2505                	addw	a0,a0,1
      for(fd = 0; fd < NOFILE; fd++){
    80002850:	0721                	add	a4,a4,8
    80002852:	fef705e3          	beq	a4,a5,8000283c <getfilenum+0x26>
        if(p->ofile[fd]){
    80002856:	6314                	ld	a3,0(a4)
    80002858:	fafd                	bnez	a3,8000284e <getfilenum+0x38>
    8000285a:	bfdd                	j	80002850 <getfilenum+0x3a>

000000008000285c <settickets>:

int
settickets(int number, struct proc* p)
{
    8000285c:	1141                	add	sp,sp,-16
    8000285e:	e422                	sd	s0,8(sp)
    80002860:	0800                	add	s0,sp,16
  // cap for number is 70; tickets > 70 cause the shell to stall or infinite loop
  for (int i = 0; i < NPROC; i++){
    if ((&s)->pid[i] == p->pid && number > 0 && number <= 70){
    80002862:	5990                	lw	a2,48(a1)
    80002864:	0000f717          	auipc	a4,0xf
    80002868:	99c70713          	add	a4,a4,-1636 # 80011200 <s+0x200>
  for (int i = 0; i < NPROC; i++){
    8000286c:	4781                	li	a5,0
    if ((&s)->pid[i] == p->pid && number > 0 && number <= 70){
    8000286e:	fff5089b          	addw	a7,a0,-1
    80002872:	04500813          	li	a6,69
  for (int i = 0; i < NPROC; i++){
    80002876:	04000593          	li	a1,64
    8000287a:	a029                	j	80002884 <settickets+0x28>
    8000287c:	2785                	addw	a5,a5,1
    8000287e:	0711                	add	a4,a4,4
    80002880:	02b78c63          	beq	a5,a1,800028b8 <settickets+0x5c>
    if ((&s)->pid[i] == p->pid && number > 0 && number <= 70){
    80002884:	4314                	lw	a3,0(a4)
    80002886:	fec69be3          	bne	a3,a2,8000287c <settickets+0x20>
    8000288a:	ff1869e3          	bltu	a6,a7,8000287c <settickets+0x20>
      (&s)->tickets[i] = number;
    8000288e:	04078793          	add	a5,a5,64
    80002892:	078a                	sll	a5,a5,0x2
    80002894:	0000e717          	auipc	a4,0xe
    80002898:	33c70713          	add	a4,a4,828 # 80010bd0 <pid_lock>
    8000289c:	97ba                	add	a5,a5,a4
    8000289e:	42a7a823          	sw	a0,1072(a5)
      totaltickets += number - 1; // it was previously set to one so subtract that and add number
    800028a2:	00006717          	auipc	a4,0x6
    800028a6:	0b670713          	add	a4,a4,182 # 80008958 <totaltickets>
    800028aa:	fff5079b          	addw	a5,a0,-1
    800028ae:	4314                	lw	a3,0(a4)
    800028b0:	9fb5                	addw	a5,a5,a3
    800028b2:	c31c                	sw	a5,0(a4)
      return 0;
    800028b4:	4501                	li	a0,0
    800028b6:	a011                	j	800028ba <settickets+0x5e>
    }
  }
  return -1;
    800028b8:	557d                	li	a0,-1
}
    800028ba:	6422                	ld	s0,8(sp)
    800028bc:	0141                	add	sp,sp,16
    800028be:	8082                	ret

00000000800028c0 <getpinfo>:

// Add each process to the pstats, s
int
getpinfo()
{
    800028c0:	7179                	add	sp,sp,-48
    800028c2:	f406                	sd	ra,40(sp)
    800028c4:	f022                	sd	s0,32(sp)
    800028c6:	ec26                	sd	s1,24(sp)
    800028c8:	e84a                	sd	s2,16(sp)
    800028ca:	e44e                	sd	s3,8(sp)
    800028cc:	e052                	sd	s4,0(sp)
    800028ce:	1800                	add	s0,sp,48
  struct proc *p;
  for(int i = 0; i < NPROC; i++){
    800028d0:	0000e497          	auipc	s1,0xe
    800028d4:	73048493          	add	s1,s1,1840 # 80011000 <s>
    800028d8:	0000f917          	auipc	s2,0xf
    800028dc:	c8090913          	add	s2,s2,-896 # 80011558 <proc+0x158>
    800028e0:	0000f997          	auipc	s3,0xf
    800028e4:	82098993          	add	s3,s3,-2016 # 80011100 <s+0x100>
    if ((&s)->pid[i] || (&s)->tickets[i] || (&s)->ticks[i] || (&s)->inuse[i]){
      p = &proc[i];
      printf("pid: %d, tickets: %d, ticks: %d, inuse: %d, proc: %s\n", 
    800028e8:	00006a17          	auipc	s4,0x6
    800028ec:	9e0a0a13          	add	s4,s4,-1568 # 800082c8 <digits+0x288>
    800028f0:	a00d                	j	80002912 <getpinfo+0x52>
    800028f2:	87ca                	mv	a5,s2
    800028f4:	4218                	lw	a4,0(a2)
    800028f6:	30062683          	lw	a3,768(a2)
    800028fa:	10062603          	lw	a2,256(a2)
    800028fe:	8552                	mv	a0,s4
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	c86080e7          	jalr	-890(ra) # 80000586 <printf>
  for(int i = 0; i < NPROC; i++){
    80002908:	0491                	add	s1,s1,4
    8000290a:	16890913          	add	s2,s2,360
    8000290e:	01348f63          	beq	s1,s3,8000292c <getpinfo+0x6c>
    if ((&s)->pid[i] || (&s)->tickets[i] || (&s)->ticks[i] || (&s)->inuse[i]){
    80002912:	8626                	mv	a2,s1
    80002914:	2004a583          	lw	a1,512(s1)
    80002918:	fde9                	bnez	a1,800028f2 <getpinfo+0x32>
    8000291a:	1004a783          	lw	a5,256(s1)
    8000291e:	fbf1                	bnez	a5,800028f2 <getpinfo+0x32>
    80002920:	3004a783          	lw	a5,768(s1)
    80002924:	f7f9                	bnez	a5,800028f2 <getpinfo+0x32>
    80002926:	409c                	lw	a5,0(s1)
    80002928:	d3e5                	beqz	a5,80002908 <getpinfo+0x48>
    8000292a:	b7e1                	j	800028f2 <getpinfo+0x32>
      (&s)->pid[i], (&s)->tickets[i], (&s)->ticks[i], (&s)->inuse[i], p->name);
    }
  }
  return 0;
}
    8000292c:	4501                	li	a0,0
    8000292e:	70a2                	ld	ra,40(sp)
    80002930:	7402                	ld	s0,32(sp)
    80002932:	64e2                	ld	s1,24(sp)
    80002934:	6942                	ld	s2,16(sp)
    80002936:	69a2                	ld	s3,8(sp)
    80002938:	6a02                	ld	s4,0(sp)
    8000293a:	6145                	add	sp,sp,48
    8000293c:	8082                	ret

000000008000293e <lottery_scheduler>:
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
lottery_scheduler(void)
{
    8000293e:	7119                	add	sp,sp,-128
    80002940:	fc86                	sd	ra,120(sp)
    80002942:	f8a2                	sd	s0,112(sp)
    80002944:	f4a6                	sd	s1,104(sp)
    80002946:	f0ca                	sd	s2,96(sp)
    80002948:	ecce                	sd	s3,88(sp)
    8000294a:	e8d2                	sd	s4,80(sp)
    8000294c:	e4d6                	sd	s5,72(sp)
    8000294e:	e0da                	sd	s6,64(sp)
    80002950:	fc5e                	sd	s7,56(sp)
    80002952:	f862                	sd	s8,48(sp)
    80002954:	f466                	sd	s9,40(sp)
    80002956:	f06a                	sd	s10,32(sp)
    80002958:	ec6e                	sd	s11,24(sp)
    8000295a:	0100                	add	s0,sp,128
    8000295c:	8492                	mv	s1,tp
  int id = r_tp();
    8000295e:	2481                	sext.w	s1,s1
  struct proc *p;
  struct cpu *c = mycpu();
  rand_init(10);
    80002960:	4529                	li	a0,10
    80002962:	00004097          	auipc	ra,0x4
    80002966:	03a080e7          	jalr	58(ra) # 8000699c <rand_init>
  
  c->proc = 0;
    8000296a:	00749713          	sll	a4,s1,0x7
    8000296e:	0000e797          	auipc	a5,0xe
    80002972:	26278793          	add	a5,a5,610 # 80010bd0 <pid_lock>
    80002976:	97ba                	add	a5,a5,a4
    80002978:	0207b823          	sd	zero,48(a5)
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);
    8000297c:	0000e797          	auipc	a5,0xe
    80002980:	28c78793          	add	a5,a5,652 # 80010c08 <cpus+0x8>
    80002984:	97ba                	add	a5,a5,a4
    80002986:	f8f43423          	sd	a5,-120(s0)
    8000298a:	00014b97          	auipc	s7,0x14
    8000298e:	476b8b93          	add	s7,s7,1142 # 80016e00 <tickslock>
      if (count >= chosenticket && p->state == RUNNABLE){
    80002992:	4c0d                	li	s8,3
        c->proc = p;
    80002994:	0000ec97          	auipc	s9,0xe
    80002998:	23cc8c93          	add	s9,s9,572 # 80010bd0 <pid_lock>
    8000299c:	9cba                	add	s9,s9,a4
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000299e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029a2:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029a6:	10079073          	csrw	sstatus,a5
    int chosenticket = scaled_random(0, totaltickets);
    800029aa:	00006797          	auipc	a5,0x6
    800029ae:	fae78793          	add	a5,a5,-82 # 80008958 <totaltickets>
    800029b2:	438c                	lw	a1,0(a5)
    800029b4:	4501                	li	a0,0
    800029b6:	00004097          	auipc	ra,0x4
    800029ba:	ffe080e7          	jalr	-2(ra) # 800069b4 <scaled_random>
    800029be:	8b2a                	mv	s6,a0
    for(int i = 0; i < NPROC; i++) {
    800029c0:	0000f497          	auipc	s1,0xf
    800029c4:	a4048493          	add	s1,s1,-1472 # 80011400 <proc>
    800029c8:	0000f917          	auipc	s2,0xf
    800029cc:	93890913          	add	s2,s2,-1736 # 80011300 <s+0x300>
    int count = 0;
    800029d0:	4981                	li	s3,0
        p->state = RUNNING;
    800029d2:	4d91                	li	s11,4
        // It should have changed its p->state before coming back.
        c->proc = 0;

        // Increment the process ticks
        (&s)->ticks[i]++;        
        if ((&s)->ticks[i] > 5){
    800029d4:	4d15                	li	s10,5
    800029d6:	a819                	j	800029ec <lottery_scheduler+0xae>
          settickets((&s)->ticks[i] - 5, p);
        }
      }
      release(&p->lock);
    800029d8:	8552                	mv	a0,s4
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	2ac080e7          	jalr	684(ra) # 80000c86 <release>
    for(int i = 0; i < NPROC; i++) {
    800029e2:	16848493          	add	s1,s1,360
    800029e6:	0911                	add	s2,s2,4
    800029e8:	fb748be3          	beq	s1,s7,8000299e <lottery_scheduler+0x60>
      count += (&s)->tickets[i];
    800029ec:	e0092783          	lw	a5,-512(s2)
    800029f0:	013789bb          	addw	s3,a5,s3
      p = &proc[i];
    800029f4:	8a26                	mv	s4,s1
      acquire(&p->lock);
    800029f6:	8526                	mv	a0,s1
    800029f8:	ffffe097          	auipc	ra,0xffffe
    800029fc:	1da080e7          	jalr	474(ra) # 80000bd2 <acquire>
      if (count >= chosenticket && p->state == RUNNABLE){
    80002a00:	fd69cce3          	blt	s3,s6,800029d8 <lottery_scheduler+0x9a>
    80002a04:	4c9c                	lw	a5,24(s1)
    80002a06:	fd8799e3          	bne	a5,s8,800029d8 <lottery_scheduler+0x9a>
        p->state = RUNNING;
    80002a0a:	01b4ac23          	sw	s11,24(s1)
        c->proc = p;
    80002a0e:	029cb823          	sd	s1,48(s9)
        swtch(&c->context, &p->context);
    80002a12:	06048593          	add	a1,s1,96
    80002a16:	f8843503          	ld	a0,-120(s0)
    80002a1a:	00000097          	auipc	ra,0x0
    80002a1e:	02e080e7          	jalr	46(ra) # 80002a48 <swtch>
        c->proc = 0;
    80002a22:	020cb823          	sd	zero,48(s9)
        (&s)->ticks[i]++;        
    80002a26:	00092503          	lw	a0,0(s2)
    80002a2a:	0015079b          	addw	a5,a0,1
    80002a2e:	0007871b          	sext.w	a4,a5
    80002a32:	00f92023          	sw	a5,0(s2)
        if ((&s)->ticks[i] > 5){
    80002a36:	faed51e3          	bge	s10,a4,800029d8 <lottery_scheduler+0x9a>
          settickets((&s)->ticks[i] - 5, p);
    80002a3a:	85a6                	mv	a1,s1
    80002a3c:	3571                	addw	a0,a0,-4
    80002a3e:	00000097          	auipc	ra,0x0
    80002a42:	e1e080e7          	jalr	-482(ra) # 8000285c <settickets>
    80002a46:	bf49                	j	800029d8 <lottery_scheduler+0x9a>

0000000080002a48 <swtch>:
    80002a48:	00153023          	sd	ra,0(a0)
    80002a4c:	00253423          	sd	sp,8(a0)
    80002a50:	e900                	sd	s0,16(a0)
    80002a52:	ed04                	sd	s1,24(a0)
    80002a54:	03253023          	sd	s2,32(a0)
    80002a58:	03353423          	sd	s3,40(a0)
    80002a5c:	03453823          	sd	s4,48(a0)
    80002a60:	03553c23          	sd	s5,56(a0)
    80002a64:	05653023          	sd	s6,64(a0)
    80002a68:	05753423          	sd	s7,72(a0)
    80002a6c:	05853823          	sd	s8,80(a0)
    80002a70:	05953c23          	sd	s9,88(a0)
    80002a74:	07a53023          	sd	s10,96(a0)
    80002a78:	07b53423          	sd	s11,104(a0)
    80002a7c:	0005b083          	ld	ra,0(a1)
    80002a80:	0085b103          	ld	sp,8(a1)
    80002a84:	6980                	ld	s0,16(a1)
    80002a86:	6d84                	ld	s1,24(a1)
    80002a88:	0205b903          	ld	s2,32(a1)
    80002a8c:	0285b983          	ld	s3,40(a1)
    80002a90:	0305ba03          	ld	s4,48(a1)
    80002a94:	0385ba83          	ld	s5,56(a1)
    80002a98:	0405bb03          	ld	s6,64(a1)
    80002a9c:	0485bb83          	ld	s7,72(a1)
    80002aa0:	0505bc03          	ld	s8,80(a1)
    80002aa4:	0585bc83          	ld	s9,88(a1)
    80002aa8:	0605bd03          	ld	s10,96(a1)
    80002aac:	0685bd83          	ld	s11,104(a1)
    80002ab0:	8082                	ret

0000000080002ab2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002ab2:	1141                	add	sp,sp,-16
    80002ab4:	e406                	sd	ra,8(sp)
    80002ab6:	e022                	sd	s0,0(sp)
    80002ab8:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002aba:	00006597          	auipc	a1,0x6
    80002abe:	8a658593          	add	a1,a1,-1882 # 80008360 <states.0+0x30>
    80002ac2:	00014517          	auipc	a0,0x14
    80002ac6:	33e50513          	add	a0,a0,830 # 80016e00 <tickslock>
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	078080e7          	jalr	120(ra) # 80000b42 <initlock>
}
    80002ad2:	60a2                	ld	ra,8(sp)
    80002ad4:	6402                	ld	s0,0(sp)
    80002ad6:	0141                	add	sp,sp,16
    80002ad8:	8082                	ret

0000000080002ada <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ada:	1141                	add	sp,sp,-16
    80002adc:	e422                	sd	s0,8(sp)
    80002ade:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ae0:	00003797          	auipc	a5,0x3
    80002ae4:	56078793          	add	a5,a5,1376 # 80006040 <kernelvec>
    80002ae8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002aec:	6422                	ld	s0,8(sp)
    80002aee:	0141                	add	sp,sp,16
    80002af0:	8082                	ret

0000000080002af2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002af2:	1141                	add	sp,sp,-16
    80002af4:	e406                	sd	ra,8(sp)
    80002af6:	e022                	sd	s0,0(sp)
    80002af8:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002afa:	fffff097          	auipc	ra,0xfffff
    80002afe:	064080e7          	jalr	100(ra) # 80001b5e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b02:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b06:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b08:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b0c:	00004697          	auipc	a3,0x4
    80002b10:	4f468693          	add	a3,a3,1268 # 80007000 <_trampoline>
    80002b14:	00004717          	auipc	a4,0x4
    80002b18:	4ec70713          	add	a4,a4,1260 # 80007000 <_trampoline>
    80002b1c:	8f15                	sub	a4,a4,a3
    80002b1e:	040007b7          	lui	a5,0x4000
    80002b22:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002b24:	07b2                	sll	a5,a5,0xc
    80002b26:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b28:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b2c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b2e:	18002673          	csrr	a2,satp
    80002b32:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b34:	6d30                	ld	a2,88(a0)
    80002b36:	6138                	ld	a4,64(a0)
    80002b38:	6585                	lui	a1,0x1
    80002b3a:	972e                	add	a4,a4,a1
    80002b3c:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b3e:	6d38                	ld	a4,88(a0)
    80002b40:	00000617          	auipc	a2,0x0
    80002b44:	13460613          	add	a2,a2,308 # 80002c74 <usertrap>
    80002b48:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b4a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b4c:	8612                	mv	a2,tp
    80002b4e:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b50:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b54:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b58:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b5c:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b60:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b62:	6f18                	ld	a4,24(a4)
    80002b64:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b68:	6928                	ld	a0,80(a0)
    80002b6a:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b6c:	00004717          	auipc	a4,0x4
    80002b70:	53070713          	add	a4,a4,1328 # 8000709c <userret>
    80002b74:	8f15                	sub	a4,a4,a3
    80002b76:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b78:	577d                	li	a4,-1
    80002b7a:	177e                	sll	a4,a4,0x3f
    80002b7c:	8d59                	or	a0,a0,a4
    80002b7e:	9782                	jalr	a5
}
    80002b80:	60a2                	ld	ra,8(sp)
    80002b82:	6402                	ld	s0,0(sp)
    80002b84:	0141                	add	sp,sp,16
    80002b86:	8082                	ret

0000000080002b88 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b88:	1101                	add	sp,sp,-32
    80002b8a:	ec06                	sd	ra,24(sp)
    80002b8c:	e822                	sd	s0,16(sp)
    80002b8e:	e426                	sd	s1,8(sp)
    80002b90:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002b92:	00014497          	auipc	s1,0x14
    80002b96:	26e48493          	add	s1,s1,622 # 80016e00 <tickslock>
    80002b9a:	8526                	mv	a0,s1
    80002b9c:	ffffe097          	auipc	ra,0xffffe
    80002ba0:	036080e7          	jalr	54(ra) # 80000bd2 <acquire>
  ticks++;
    80002ba4:	00006517          	auipc	a0,0x6
    80002ba8:	db850513          	add	a0,a0,-584 # 8000895c <ticks>
    80002bac:	411c                	lw	a5,0(a0)
    80002bae:	2785                	addw	a5,a5,1
    80002bb0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002bb2:	fffff097          	auipc	ra,0xfffff
    80002bb6:	764080e7          	jalr	1892(ra) # 80002316 <wakeup>
  release(&tickslock);
    80002bba:	8526                	mv	a0,s1
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	0ca080e7          	jalr	202(ra) # 80000c86 <release>
}
    80002bc4:	60e2                	ld	ra,24(sp)
    80002bc6:	6442                	ld	s0,16(sp)
    80002bc8:	64a2                	ld	s1,8(sp)
    80002bca:	6105                	add	sp,sp,32
    80002bcc:	8082                	ret

0000000080002bce <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bce:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002bd2:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002bd4:	0807df63          	bgez	a5,80002c72 <devintr+0xa4>
{
    80002bd8:	1101                	add	sp,sp,-32
    80002bda:	ec06                	sd	ra,24(sp)
    80002bdc:	e822                	sd	s0,16(sp)
    80002bde:	e426                	sd	s1,8(sp)
    80002be0:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    80002be2:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002be6:	46a5                	li	a3,9
    80002be8:	00d70d63          	beq	a4,a3,80002c02 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002bec:	577d                	li	a4,-1
    80002bee:	177e                	sll	a4,a4,0x3f
    80002bf0:	0705                	add	a4,a4,1
    return 0;
    80002bf2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002bf4:	04e78e63          	beq	a5,a4,80002c50 <devintr+0x82>
  }
}
    80002bf8:	60e2                	ld	ra,24(sp)
    80002bfa:	6442                	ld	s0,16(sp)
    80002bfc:	64a2                	ld	s1,8(sp)
    80002bfe:	6105                	add	sp,sp,32
    80002c00:	8082                	ret
    int irq = plic_claim();
    80002c02:	00003097          	auipc	ra,0x3
    80002c06:	546080e7          	jalr	1350(ra) # 80006148 <plic_claim>
    80002c0a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c0c:	47a9                	li	a5,10
    80002c0e:	02f50763          	beq	a0,a5,80002c3c <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002c12:	4785                	li	a5,1
    80002c14:	02f50963          	beq	a0,a5,80002c46 <devintr+0x78>
    return 1;
    80002c18:	4505                	li	a0,1
    } else if(irq){
    80002c1a:	dcf9                	beqz	s1,80002bf8 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c1c:	85a6                	mv	a1,s1
    80002c1e:	00005517          	auipc	a0,0x5
    80002c22:	74a50513          	add	a0,a0,1866 # 80008368 <states.0+0x38>
    80002c26:	ffffe097          	auipc	ra,0xffffe
    80002c2a:	960080e7          	jalr	-1696(ra) # 80000586 <printf>
      plic_complete(irq);
    80002c2e:	8526                	mv	a0,s1
    80002c30:	00003097          	auipc	ra,0x3
    80002c34:	53c080e7          	jalr	1340(ra) # 8000616c <plic_complete>
    return 1;
    80002c38:	4505                	li	a0,1
    80002c3a:	bf7d                	j	80002bf8 <devintr+0x2a>
      uartintr();
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	d58080e7          	jalr	-680(ra) # 80000994 <uartintr>
    if(irq)
    80002c44:	b7ed                	j	80002c2e <devintr+0x60>
      virtio_disk_intr();
    80002c46:	00004097          	auipc	ra,0x4
    80002c4a:	9ec080e7          	jalr	-1556(ra) # 80006632 <virtio_disk_intr>
    if(irq)
    80002c4e:	b7c5                	j	80002c2e <devintr+0x60>
    if(cpuid() == 0){
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	ee2080e7          	jalr	-286(ra) # 80001b32 <cpuid>
    80002c58:	c901                	beqz	a0,80002c68 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c5a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c5e:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c60:	14479073          	csrw	sip,a5
    return 2;
    80002c64:	4509                	li	a0,2
    80002c66:	bf49                	j	80002bf8 <devintr+0x2a>
      clockintr();
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	f20080e7          	jalr	-224(ra) # 80002b88 <clockintr>
    80002c70:	b7ed                	j	80002c5a <devintr+0x8c>
}
    80002c72:	8082                	ret

0000000080002c74 <usertrap>:
{
    80002c74:	1101                	add	sp,sp,-32
    80002c76:	ec06                	sd	ra,24(sp)
    80002c78:	e822                	sd	s0,16(sp)
    80002c7a:	e426                	sd	s1,8(sp)
    80002c7c:	e04a                	sd	s2,0(sp)
    80002c7e:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c80:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c84:	1007f793          	and	a5,a5,256
    80002c88:	e3b1                	bnez	a5,80002ccc <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c8a:	00003797          	auipc	a5,0x3
    80002c8e:	3b678793          	add	a5,a5,950 # 80006040 <kernelvec>
    80002c92:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c96:	fffff097          	auipc	ra,0xfffff
    80002c9a:	ec8080e7          	jalr	-312(ra) # 80001b5e <myproc>
    80002c9e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ca0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ca2:	14102773          	csrr	a4,sepc
    80002ca6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ca8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002cac:	47a1                	li	a5,8
    80002cae:	02f70763          	beq	a4,a5,80002cdc <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002cb2:	00000097          	auipc	ra,0x0
    80002cb6:	f1c080e7          	jalr	-228(ra) # 80002bce <devintr>
    80002cba:	892a                	mv	s2,a0
    80002cbc:	c151                	beqz	a0,80002d40 <usertrap+0xcc>
  if(killed(p))
    80002cbe:	8526                	mv	a0,s1
    80002cc0:	00000097          	auipc	ra,0x0
    80002cc4:	89a080e7          	jalr	-1894(ra) # 8000255a <killed>
    80002cc8:	c929                	beqz	a0,80002d1a <usertrap+0xa6>
    80002cca:	a099                	j	80002d10 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002ccc:	00005517          	auipc	a0,0x5
    80002cd0:	6bc50513          	add	a0,a0,1724 # 80008388 <states.0+0x58>
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	868080e7          	jalr	-1944(ra) # 8000053c <panic>
    if(killed(p))
    80002cdc:	00000097          	auipc	ra,0x0
    80002ce0:	87e080e7          	jalr	-1922(ra) # 8000255a <killed>
    80002ce4:	e921                	bnez	a0,80002d34 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002ce6:	6cb8                	ld	a4,88(s1)
    80002ce8:	6f1c                	ld	a5,24(a4)
    80002cea:	0791                	add	a5,a5,4
    80002cec:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002cf2:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cf6:	10079073          	csrw	sstatus,a5
    syscall();
    80002cfa:	00000097          	auipc	ra,0x0
    80002cfe:	2d4080e7          	jalr	724(ra) # 80002fce <syscall>
  if(killed(p))
    80002d02:	8526                	mv	a0,s1
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	856080e7          	jalr	-1962(ra) # 8000255a <killed>
    80002d0c:	c911                	beqz	a0,80002d20 <usertrap+0xac>
    80002d0e:	4901                	li	s2,0
    exit(-1);
    80002d10:	557d                	li	a0,-1
    80002d12:	fffff097          	auipc	ra,0xfffff
    80002d16:	6d4080e7          	jalr	1748(ra) # 800023e6 <exit>
  if(which_dev == 2)
    80002d1a:	4789                	li	a5,2
    80002d1c:	04f90f63          	beq	s2,a5,80002d7a <usertrap+0x106>
  usertrapret();
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	dd2080e7          	jalr	-558(ra) # 80002af2 <usertrapret>
}
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	64a2                	ld	s1,8(sp)
    80002d2e:	6902                	ld	s2,0(sp)
    80002d30:	6105                	add	sp,sp,32
    80002d32:	8082                	ret
      exit(-1);
    80002d34:	557d                	li	a0,-1
    80002d36:	fffff097          	auipc	ra,0xfffff
    80002d3a:	6b0080e7          	jalr	1712(ra) # 800023e6 <exit>
    80002d3e:	b765                	j	80002ce6 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d40:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d44:	5890                	lw	a2,48(s1)
    80002d46:	00005517          	auipc	a0,0x5
    80002d4a:	66250513          	add	a0,a0,1634 # 800083a8 <states.0+0x78>
    80002d4e:	ffffe097          	auipc	ra,0xffffe
    80002d52:	838080e7          	jalr	-1992(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d56:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d5a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d5e:	00005517          	auipc	a0,0x5
    80002d62:	67a50513          	add	a0,a0,1658 # 800083d8 <states.0+0xa8>
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	820080e7          	jalr	-2016(ra) # 80000586 <printf>
    setkilled(p);
    80002d6e:	8526                	mv	a0,s1
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	7be080e7          	jalr	1982(ra) # 8000252e <setkilled>
    80002d78:	b769                	j	80002d02 <usertrap+0x8e>
    yield();
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	4fc080e7          	jalr	1276(ra) # 80002276 <yield>
    80002d82:	bf79                	j	80002d20 <usertrap+0xac>

0000000080002d84 <kerneltrap>:
{
    80002d84:	7179                	add	sp,sp,-48
    80002d86:	f406                	sd	ra,40(sp)
    80002d88:	f022                	sd	s0,32(sp)
    80002d8a:	ec26                	sd	s1,24(sp)
    80002d8c:	e84a                	sd	s2,16(sp)
    80002d8e:	e44e                	sd	s3,8(sp)
    80002d90:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d92:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d96:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d9a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d9e:	1004f793          	and	a5,s1,256
    80002da2:	cb85                	beqz	a5,80002dd2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002da4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002da8:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80002daa:	ef85                	bnez	a5,80002de2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002dac:	00000097          	auipc	ra,0x0
    80002db0:	e22080e7          	jalr	-478(ra) # 80002bce <devintr>
    80002db4:	cd1d                	beqz	a0,80002df2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002db6:	4789                	li	a5,2
    80002db8:	06f50a63          	beq	a0,a5,80002e2c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dbc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dc0:	10049073          	csrw	sstatus,s1
}
    80002dc4:	70a2                	ld	ra,40(sp)
    80002dc6:	7402                	ld	s0,32(sp)
    80002dc8:	64e2                	ld	s1,24(sp)
    80002dca:	6942                	ld	s2,16(sp)
    80002dcc:	69a2                	ld	s3,8(sp)
    80002dce:	6145                	add	sp,sp,48
    80002dd0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002dd2:	00005517          	auipc	a0,0x5
    80002dd6:	62650513          	add	a0,a0,1574 # 800083f8 <states.0+0xc8>
    80002dda:	ffffd097          	auipc	ra,0xffffd
    80002dde:	762080e7          	jalr	1890(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002de2:	00005517          	auipc	a0,0x5
    80002de6:	63e50513          	add	a0,a0,1598 # 80008420 <states.0+0xf0>
    80002dea:	ffffd097          	auipc	ra,0xffffd
    80002dee:	752080e7          	jalr	1874(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002df2:	85ce                	mv	a1,s3
    80002df4:	00005517          	auipc	a0,0x5
    80002df8:	64c50513          	add	a0,a0,1612 # 80008440 <states.0+0x110>
    80002dfc:	ffffd097          	auipc	ra,0xffffd
    80002e00:	78a080e7          	jalr	1930(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e04:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e08:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e0c:	00005517          	auipc	a0,0x5
    80002e10:	64450513          	add	a0,a0,1604 # 80008450 <states.0+0x120>
    80002e14:	ffffd097          	auipc	ra,0xffffd
    80002e18:	772080e7          	jalr	1906(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002e1c:	00005517          	auipc	a0,0x5
    80002e20:	64c50513          	add	a0,a0,1612 # 80008468 <states.0+0x138>
    80002e24:	ffffd097          	auipc	ra,0xffffd
    80002e28:	718080e7          	jalr	1816(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e2c:	fffff097          	auipc	ra,0xfffff
    80002e30:	d32080e7          	jalr	-718(ra) # 80001b5e <myproc>
    80002e34:	d541                	beqz	a0,80002dbc <kerneltrap+0x38>
    80002e36:	fffff097          	auipc	ra,0xfffff
    80002e3a:	d28080e7          	jalr	-728(ra) # 80001b5e <myproc>
    80002e3e:	4d18                	lw	a4,24(a0)
    80002e40:	4791                	li	a5,4
    80002e42:	f6f71de3          	bne	a4,a5,80002dbc <kerneltrap+0x38>
    yield();
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	430080e7          	jalr	1072(ra) # 80002276 <yield>
    80002e4e:	b7bd                	j	80002dbc <kerneltrap+0x38>

0000000080002e50 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e50:	1101                	add	sp,sp,-32
    80002e52:	ec06                	sd	ra,24(sp)
    80002e54:	e822                	sd	s0,16(sp)
    80002e56:	e426                	sd	s1,8(sp)
    80002e58:	1000                	add	s0,sp,32
    80002e5a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e5c:	fffff097          	auipc	ra,0xfffff
    80002e60:	d02080e7          	jalr	-766(ra) # 80001b5e <myproc>
  switch (n) {
    80002e64:	4795                	li	a5,5
    80002e66:	0497e163          	bltu	a5,s1,80002ea8 <argraw+0x58>
    80002e6a:	048a                	sll	s1,s1,0x2
    80002e6c:	00005717          	auipc	a4,0x5
    80002e70:	63470713          	add	a4,a4,1588 # 800084a0 <states.0+0x170>
    80002e74:	94ba                	add	s1,s1,a4
    80002e76:	409c                	lw	a5,0(s1)
    80002e78:	97ba                	add	a5,a5,a4
    80002e7a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e7c:	6d3c                	ld	a5,88(a0)
    80002e7e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e80:	60e2                	ld	ra,24(sp)
    80002e82:	6442                	ld	s0,16(sp)
    80002e84:	64a2                	ld	s1,8(sp)
    80002e86:	6105                	add	sp,sp,32
    80002e88:	8082                	ret
    return p->trapframe->a1;
    80002e8a:	6d3c                	ld	a5,88(a0)
    80002e8c:	7fa8                	ld	a0,120(a5)
    80002e8e:	bfcd                	j	80002e80 <argraw+0x30>
    return p->trapframe->a2;
    80002e90:	6d3c                	ld	a5,88(a0)
    80002e92:	63c8                	ld	a0,128(a5)
    80002e94:	b7f5                	j	80002e80 <argraw+0x30>
    return p->trapframe->a3;
    80002e96:	6d3c                	ld	a5,88(a0)
    80002e98:	67c8                	ld	a0,136(a5)
    80002e9a:	b7dd                	j	80002e80 <argraw+0x30>
    return p->trapframe->a4;
    80002e9c:	6d3c                	ld	a5,88(a0)
    80002e9e:	6bc8                	ld	a0,144(a5)
    80002ea0:	b7c5                	j	80002e80 <argraw+0x30>
    return p->trapframe->a5;
    80002ea2:	6d3c                	ld	a5,88(a0)
    80002ea4:	6fc8                	ld	a0,152(a5)
    80002ea6:	bfe9                	j	80002e80 <argraw+0x30>
  panic("argraw");
    80002ea8:	00005517          	auipc	a0,0x5
    80002eac:	5d050513          	add	a0,a0,1488 # 80008478 <states.0+0x148>
    80002eb0:	ffffd097          	auipc	ra,0xffffd
    80002eb4:	68c080e7          	jalr	1676(ra) # 8000053c <panic>

0000000080002eb8 <fetchaddr>:
{
    80002eb8:	1101                	add	sp,sp,-32
    80002eba:	ec06                	sd	ra,24(sp)
    80002ebc:	e822                	sd	s0,16(sp)
    80002ebe:	e426                	sd	s1,8(sp)
    80002ec0:	e04a                	sd	s2,0(sp)
    80002ec2:	1000                	add	s0,sp,32
    80002ec4:	84aa                	mv	s1,a0
    80002ec6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	c96080e7          	jalr	-874(ra) # 80001b5e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ed0:	653c                	ld	a5,72(a0)
    80002ed2:	02f4f863          	bgeu	s1,a5,80002f02 <fetchaddr+0x4a>
    80002ed6:	00848713          	add	a4,s1,8
    80002eda:	02e7e663          	bltu	a5,a4,80002f06 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ede:	46a1                	li	a3,8
    80002ee0:	8626                	mv	a2,s1
    80002ee2:	85ca                	mv	a1,s2
    80002ee4:	6928                	ld	a0,80(a0)
    80002ee6:	fffff097          	auipc	ra,0xfffff
    80002eea:	80c080e7          	jalr	-2036(ra) # 800016f2 <copyin>
    80002eee:	00a03533          	snez	a0,a0
    80002ef2:	40a00533          	neg	a0,a0
}
    80002ef6:	60e2                	ld	ra,24(sp)
    80002ef8:	6442                	ld	s0,16(sp)
    80002efa:	64a2                	ld	s1,8(sp)
    80002efc:	6902                	ld	s2,0(sp)
    80002efe:	6105                	add	sp,sp,32
    80002f00:	8082                	ret
    return -1;
    80002f02:	557d                	li	a0,-1
    80002f04:	bfcd                	j	80002ef6 <fetchaddr+0x3e>
    80002f06:	557d                	li	a0,-1
    80002f08:	b7fd                	j	80002ef6 <fetchaddr+0x3e>

0000000080002f0a <fetchstr>:
{
    80002f0a:	7179                	add	sp,sp,-48
    80002f0c:	f406                	sd	ra,40(sp)
    80002f0e:	f022                	sd	s0,32(sp)
    80002f10:	ec26                	sd	s1,24(sp)
    80002f12:	e84a                	sd	s2,16(sp)
    80002f14:	e44e                	sd	s3,8(sp)
    80002f16:	1800                	add	s0,sp,48
    80002f18:	892a                	mv	s2,a0
    80002f1a:	84ae                	mv	s1,a1
    80002f1c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f1e:	fffff097          	auipc	ra,0xfffff
    80002f22:	c40080e7          	jalr	-960(ra) # 80001b5e <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002f26:	86ce                	mv	a3,s3
    80002f28:	864a                	mv	a2,s2
    80002f2a:	85a6                	mv	a1,s1
    80002f2c:	6928                	ld	a0,80(a0)
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	852080e7          	jalr	-1966(ra) # 80001780 <copyinstr>
    80002f36:	00054e63          	bltz	a0,80002f52 <fetchstr+0x48>
  return strlen(buf);
    80002f3a:	8526                	mv	a0,s1
    80002f3c:	ffffe097          	auipc	ra,0xffffe
    80002f40:	f0c080e7          	jalr	-244(ra) # 80000e48 <strlen>
}
    80002f44:	70a2                	ld	ra,40(sp)
    80002f46:	7402                	ld	s0,32(sp)
    80002f48:	64e2                	ld	s1,24(sp)
    80002f4a:	6942                	ld	s2,16(sp)
    80002f4c:	69a2                	ld	s3,8(sp)
    80002f4e:	6145                	add	sp,sp,48
    80002f50:	8082                	ret
    return -1;
    80002f52:	557d                	li	a0,-1
    80002f54:	bfc5                	j	80002f44 <fetchstr+0x3a>

0000000080002f56 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002f56:	1101                	add	sp,sp,-32
    80002f58:	ec06                	sd	ra,24(sp)
    80002f5a:	e822                	sd	s0,16(sp)
    80002f5c:	e426                	sd	s1,8(sp)
    80002f5e:	1000                	add	s0,sp,32
    80002f60:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f62:	00000097          	auipc	ra,0x0
    80002f66:	eee080e7          	jalr	-274(ra) # 80002e50 <argraw>
    80002f6a:	c088                	sw	a0,0(s1)
}
    80002f6c:	60e2                	ld	ra,24(sp)
    80002f6e:	6442                	ld	s0,16(sp)
    80002f70:	64a2                	ld	s1,8(sp)
    80002f72:	6105                	add	sp,sp,32
    80002f74:	8082                	ret

0000000080002f76 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002f76:	1101                	add	sp,sp,-32
    80002f78:	ec06                	sd	ra,24(sp)
    80002f7a:	e822                	sd	s0,16(sp)
    80002f7c:	e426                	sd	s1,8(sp)
    80002f7e:	1000                	add	s0,sp,32
    80002f80:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f82:	00000097          	auipc	ra,0x0
    80002f86:	ece080e7          	jalr	-306(ra) # 80002e50 <argraw>
    80002f8a:	e088                	sd	a0,0(s1)
}
    80002f8c:	60e2                	ld	ra,24(sp)
    80002f8e:	6442                	ld	s0,16(sp)
    80002f90:	64a2                	ld	s1,8(sp)
    80002f92:	6105                	add	sp,sp,32
    80002f94:	8082                	ret

0000000080002f96 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f96:	7179                	add	sp,sp,-48
    80002f98:	f406                	sd	ra,40(sp)
    80002f9a:	f022                	sd	s0,32(sp)
    80002f9c:	ec26                	sd	s1,24(sp)
    80002f9e:	e84a                	sd	s2,16(sp)
    80002fa0:	1800                	add	s0,sp,48
    80002fa2:	84ae                	mv	s1,a1
    80002fa4:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002fa6:	fd840593          	add	a1,s0,-40
    80002faa:	00000097          	auipc	ra,0x0
    80002fae:	fcc080e7          	jalr	-52(ra) # 80002f76 <argaddr>
  return fetchstr(addr, buf, max);
    80002fb2:	864a                	mv	a2,s2
    80002fb4:	85a6                	mv	a1,s1
    80002fb6:	fd843503          	ld	a0,-40(s0)
    80002fba:	00000097          	auipc	ra,0x0
    80002fbe:	f50080e7          	jalr	-176(ra) # 80002f0a <fetchstr>
}
    80002fc2:	70a2                	ld	ra,40(sp)
    80002fc4:	7402                	ld	s0,32(sp)
    80002fc6:	64e2                	ld	s1,24(sp)
    80002fc8:	6942                	ld	s2,16(sp)
    80002fca:	6145                	add	sp,sp,48
    80002fcc:	8082                	ret

0000000080002fce <syscall>:
[SYS_pgaccess]  sys_pgaccess,
};

void
syscall(void)
{
    80002fce:	1101                	add	sp,sp,-32
    80002fd0:	ec06                	sd	ra,24(sp)
    80002fd2:	e822                	sd	s0,16(sp)
    80002fd4:	e426                	sd	s1,8(sp)
    80002fd6:	e04a                	sd	s2,0(sp)
    80002fd8:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002fda:	fffff097          	auipc	ra,0xfffff
    80002fde:	b84080e7          	jalr	-1148(ra) # 80001b5e <myproc>
    80002fe2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fe4:	05853903          	ld	s2,88(a0)
    80002fe8:	0a893783          	ld	a5,168(s2)
    80002fec:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ff0:	37fd                	addw	a5,a5,-1
    80002ff2:	4761                	li	a4,24
    80002ff4:	00f76f63          	bltu	a4,a5,80003012 <syscall+0x44>
    80002ff8:	00369713          	sll	a4,a3,0x3
    80002ffc:	00005797          	auipc	a5,0x5
    80003000:	4bc78793          	add	a5,a5,1212 # 800084b8 <syscalls>
    80003004:	97ba                	add	a5,a5,a4
    80003006:	639c                	ld	a5,0(a5)
    80003008:	c789                	beqz	a5,80003012 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    8000300a:	9782                	jalr	a5
    8000300c:	06a93823          	sd	a0,112(s2)
    80003010:	a839                	j	8000302e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003012:	15848613          	add	a2,s1,344
    80003016:	588c                	lw	a1,48(s1)
    80003018:	00005517          	auipc	a0,0x5
    8000301c:	46850513          	add	a0,a0,1128 # 80008480 <states.0+0x150>
    80003020:	ffffd097          	auipc	ra,0xffffd
    80003024:	566080e7          	jalr	1382(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003028:	6cbc                	ld	a5,88(s1)
    8000302a:	577d                	li	a4,-1
    8000302c:	fbb8                	sd	a4,112(a5)
  }
}
    8000302e:	60e2                	ld	ra,24(sp)
    80003030:	6442                	ld	s0,16(sp)
    80003032:	64a2                	ld	s1,8(sp)
    80003034:	6902                	ld	s2,0(sp)
    80003036:	6105                	add	sp,sp,32
    80003038:	8082                	ret

000000008000303a <sys_exit>:
#include "pstat.h"
#include "random.h"

uint64
sys_exit(void)
{
    8000303a:	1101                	add	sp,sp,-32
    8000303c:	ec06                	sd	ra,24(sp)
    8000303e:	e822                	sd	s0,16(sp)
    80003040:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80003042:	fec40593          	add	a1,s0,-20
    80003046:	4501                	li	a0,0
    80003048:	00000097          	auipc	ra,0x0
    8000304c:	f0e080e7          	jalr	-242(ra) # 80002f56 <argint>
  exit(n);
    80003050:	fec42503          	lw	a0,-20(s0)
    80003054:	fffff097          	auipc	ra,0xfffff
    80003058:	392080e7          	jalr	914(ra) # 800023e6 <exit>
  return 0;  // not reached
}
    8000305c:	4501                	li	a0,0
    8000305e:	60e2                	ld	ra,24(sp)
    80003060:	6442                	ld	s0,16(sp)
    80003062:	6105                	add	sp,sp,32
    80003064:	8082                	ret

0000000080003066 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003066:	1141                	add	sp,sp,-16
    80003068:	e406                	sd	ra,8(sp)
    8000306a:	e022                	sd	s0,0(sp)
    8000306c:	0800                	add	s0,sp,16
  return myproc()->pid;
    8000306e:	fffff097          	auipc	ra,0xfffff
    80003072:	af0080e7          	jalr	-1296(ra) # 80001b5e <myproc>
}
    80003076:	5908                	lw	a0,48(a0)
    80003078:	60a2                	ld	ra,8(sp)
    8000307a:	6402                	ld	s0,0(sp)
    8000307c:	0141                	add	sp,sp,16
    8000307e:	8082                	ret

0000000080003080 <sys_fork>:

uint64
sys_fork(void)
{
    80003080:	1141                	add	sp,sp,-16
    80003082:	e406                	sd	ra,8(sp)
    80003084:	e022                	sd	s0,0(sp)
    80003086:	0800                	add	s0,sp,16
  return fork();
    80003088:	fffff097          	auipc	ra,0xfffff
    8000308c:	f38080e7          	jalr	-200(ra) # 80001fc0 <fork>
}
    80003090:	60a2                	ld	ra,8(sp)
    80003092:	6402                	ld	s0,0(sp)
    80003094:	0141                	add	sp,sp,16
    80003096:	8082                	ret

0000000080003098 <sys_wait>:

uint64
sys_wait(void)
{
    80003098:	1101                	add	sp,sp,-32
    8000309a:	ec06                	sd	ra,24(sp)
    8000309c:	e822                	sd	s0,16(sp)
    8000309e:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800030a0:	fe840593          	add	a1,s0,-24
    800030a4:	4501                	li	a0,0
    800030a6:	00000097          	auipc	ra,0x0
    800030aa:	ed0080e7          	jalr	-304(ra) # 80002f76 <argaddr>
  return wait(p);
    800030ae:	fe843503          	ld	a0,-24(s0)
    800030b2:	fffff097          	auipc	ra,0xfffff
    800030b6:	4da080e7          	jalr	1242(ra) # 8000258c <wait>
}
    800030ba:	60e2                	ld	ra,24(sp)
    800030bc:	6442                	ld	s0,16(sp)
    800030be:	6105                	add	sp,sp,32
    800030c0:	8082                	ret

00000000800030c2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800030c2:	7179                	add	sp,sp,-48
    800030c4:	f406                	sd	ra,40(sp)
    800030c6:	f022                	sd	s0,32(sp)
    800030c8:	ec26                	sd	s1,24(sp)
    800030ca:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800030cc:	fdc40593          	add	a1,s0,-36
    800030d0:	4501                	li	a0,0
    800030d2:	00000097          	auipc	ra,0x0
    800030d6:	e84080e7          	jalr	-380(ra) # 80002f56 <argint>
  addr = myproc()->sz;
    800030da:	fffff097          	auipc	ra,0xfffff
    800030de:	a84080e7          	jalr	-1404(ra) # 80001b5e <myproc>
    800030e2:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    800030e4:	fdc42503          	lw	a0,-36(s0)
    800030e8:	fffff097          	auipc	ra,0xfffff
    800030ec:	e7c080e7          	jalr	-388(ra) # 80001f64 <growproc>
    800030f0:	00054863          	bltz	a0,80003100 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800030f4:	8526                	mv	a0,s1
    800030f6:	70a2                	ld	ra,40(sp)
    800030f8:	7402                	ld	s0,32(sp)
    800030fa:	64e2                	ld	s1,24(sp)
    800030fc:	6145                	add	sp,sp,48
    800030fe:	8082                	ret
    return -1;
    80003100:	54fd                	li	s1,-1
    80003102:	bfcd                	j	800030f4 <sys_sbrk+0x32>

0000000080003104 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003104:	7139                	add	sp,sp,-64
    80003106:	fc06                	sd	ra,56(sp)
    80003108:	f822                	sd	s0,48(sp)
    8000310a:	f426                	sd	s1,40(sp)
    8000310c:	f04a                	sd	s2,32(sp)
    8000310e:	ec4e                	sd	s3,24(sp)
    80003110:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003112:	fcc40593          	add	a1,s0,-52
    80003116:	4501                	li	a0,0
    80003118:	00000097          	auipc	ra,0x0
    8000311c:	e3e080e7          	jalr	-450(ra) # 80002f56 <argint>
  acquire(&tickslock);
    80003120:	00014517          	auipc	a0,0x14
    80003124:	ce050513          	add	a0,a0,-800 # 80016e00 <tickslock>
    80003128:	ffffe097          	auipc	ra,0xffffe
    8000312c:	aaa080e7          	jalr	-1366(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80003130:	00006917          	auipc	s2,0x6
    80003134:	82c92903          	lw	s2,-2004(s2) # 8000895c <ticks>
  while(ticks - ticks0 < n){
    80003138:	fcc42783          	lw	a5,-52(s0)
    8000313c:	cf9d                	beqz	a5,8000317a <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000313e:	00014997          	auipc	s3,0x14
    80003142:	cc298993          	add	s3,s3,-830 # 80016e00 <tickslock>
    80003146:	00006497          	auipc	s1,0x6
    8000314a:	81648493          	add	s1,s1,-2026 # 8000895c <ticks>
    if(killed(myproc())){
    8000314e:	fffff097          	auipc	ra,0xfffff
    80003152:	a10080e7          	jalr	-1520(ra) # 80001b5e <myproc>
    80003156:	fffff097          	auipc	ra,0xfffff
    8000315a:	404080e7          	jalr	1028(ra) # 8000255a <killed>
    8000315e:	ed15                	bnez	a0,8000319a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003160:	85ce                	mv	a1,s3
    80003162:	8526                	mv	a0,s1
    80003164:	fffff097          	auipc	ra,0xfffff
    80003168:	14e080e7          	jalr	334(ra) # 800022b2 <sleep>
  while(ticks - ticks0 < n){
    8000316c:	409c                	lw	a5,0(s1)
    8000316e:	412787bb          	subw	a5,a5,s2
    80003172:	fcc42703          	lw	a4,-52(s0)
    80003176:	fce7ece3          	bltu	a5,a4,8000314e <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000317a:	00014517          	auipc	a0,0x14
    8000317e:	c8650513          	add	a0,a0,-890 # 80016e00 <tickslock>
    80003182:	ffffe097          	auipc	ra,0xffffe
    80003186:	b04080e7          	jalr	-1276(ra) # 80000c86 <release>
  return 0;
    8000318a:	4501                	li	a0,0
}
    8000318c:	70e2                	ld	ra,56(sp)
    8000318e:	7442                	ld	s0,48(sp)
    80003190:	74a2                	ld	s1,40(sp)
    80003192:	7902                	ld	s2,32(sp)
    80003194:	69e2                	ld	s3,24(sp)
    80003196:	6121                	add	sp,sp,64
    80003198:	8082                	ret
      release(&tickslock);
    8000319a:	00014517          	auipc	a0,0x14
    8000319e:	c6650513          	add	a0,a0,-922 # 80016e00 <tickslock>
    800031a2:	ffffe097          	auipc	ra,0xffffe
    800031a6:	ae4080e7          	jalr	-1308(ra) # 80000c86 <release>
      return -1;
    800031aa:	557d                	li	a0,-1
    800031ac:	b7c5                	j	8000318c <sys_sleep+0x88>

00000000800031ae <sys_kill>:

uint64
sys_kill(void)
{
    800031ae:	1101                	add	sp,sp,-32
    800031b0:	ec06                	sd	ra,24(sp)
    800031b2:	e822                	sd	s0,16(sp)
    800031b4:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    800031b6:	fec40593          	add	a1,s0,-20
    800031ba:	4501                	li	a0,0
    800031bc:	00000097          	auipc	ra,0x0
    800031c0:	d9a080e7          	jalr	-614(ra) # 80002f56 <argint>
  return kill(pid);
    800031c4:	fec42503          	lw	a0,-20(s0)
    800031c8:	fffff097          	auipc	ra,0xfffff
    800031cc:	2f4080e7          	jalr	756(ra) # 800024bc <kill>
}
    800031d0:	60e2                	ld	ra,24(sp)
    800031d2:	6442                	ld	s0,16(sp)
    800031d4:	6105                	add	sp,sp,32
    800031d6:	8082                	ret

00000000800031d8 <sys_getfilenum>:

uint64
sys_getfilenum(void)
{
    800031d8:	1101                	add	sp,sp,-32
    800031da:	ec06                	sd	ra,24(sp)
    800031dc:	e822                	sd	s0,16(sp)
    800031de:	1000                	add	s0,sp,32
  int pid;
  argint(0, &pid);
    800031e0:	fec40593          	add	a1,s0,-20
    800031e4:	4501                	li	a0,0
    800031e6:	00000097          	auipc	ra,0x0
    800031ea:	d70080e7          	jalr	-656(ra) # 80002f56 <argint>
  return getfilenum(pid);
    800031ee:	fec42503          	lw	a0,-20(s0)
    800031f2:	fffff097          	auipc	ra,0xfffff
    800031f6:	624080e7          	jalr	1572(ra) # 80002816 <getfilenum>
}
    800031fa:	60e2                	ld	ra,24(sp)
    800031fc:	6442                	ld	s0,16(sp)
    800031fe:	6105                	add	sp,sp,32
    80003200:	8082                	ret

0000000080003202 <sys_uptime>:
// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003202:	1101                	add	sp,sp,-32
    80003204:	ec06                	sd	ra,24(sp)
    80003206:	e822                	sd	s0,16(sp)
    80003208:	e426                	sd	s1,8(sp)
    8000320a:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000320c:	00014517          	auipc	a0,0x14
    80003210:	bf450513          	add	a0,a0,-1036 # 80016e00 <tickslock>
    80003214:	ffffe097          	auipc	ra,0xffffe
    80003218:	9be080e7          	jalr	-1602(ra) # 80000bd2 <acquire>
  xticks = ticks;
    8000321c:	00005497          	auipc	s1,0x5
    80003220:	7404a483          	lw	s1,1856(s1) # 8000895c <ticks>
  release(&tickslock);
    80003224:	00014517          	auipc	a0,0x14
    80003228:	bdc50513          	add	a0,a0,-1060 # 80016e00 <tickslock>
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	a5a080e7          	jalr	-1446(ra) # 80000c86 <release>
  return xticks;
}
    80003234:	02049513          	sll	a0,s1,0x20
    80003238:	9101                	srl	a0,a0,0x20
    8000323a:	60e2                	ld	ra,24(sp)
    8000323c:	6442                	ld	s0,16(sp)
    8000323e:	64a2                	ld	s1,8(sp)
    80003240:	6105                	add	sp,sp,32
    80003242:	8082                	ret

0000000080003244 <sys_settickets>:

uint64
sys_settickets(void)
{
    80003244:	1101                	add	sp,sp,-32
    80003246:	ec06                	sd	ra,24(sp)
    80003248:	e822                	sd	s0,16(sp)
    8000324a:	1000                	add	s0,sp,32
  int number;
  struct proc *p = 0;
  argint(0, &number);
    8000324c:	fec40593          	add	a1,s0,-20
    80003250:	4501                	li	a0,0
    80003252:	00000097          	auipc	ra,0x0
    80003256:	d04080e7          	jalr	-764(ra) # 80002f56 <argint>
  return settickets(number, p);
    8000325a:	4581                	li	a1,0
    8000325c:	fec42503          	lw	a0,-20(s0)
    80003260:	fffff097          	auipc	ra,0xfffff
    80003264:	5fc080e7          	jalr	1532(ra) # 8000285c <settickets>
}
    80003268:	60e2                	ld	ra,24(sp)
    8000326a:	6442                	ld	s0,16(sp)
    8000326c:	6105                	add	sp,sp,32
    8000326e:	8082                	ret

0000000080003270 <sys_getpinfo>:

uint64
sys_getpinfo(void)
{
    80003270:	1141                	add	sp,sp,-16
    80003272:	e406                	sd	ra,8(sp)
    80003274:	e022                	sd	s0,0(sp)
    80003276:	0800                	add	s0,sp,16
  return getpinfo();
    80003278:	fffff097          	auipc	ra,0xfffff
    8000327c:	648080e7          	jalr	1608(ra) # 800028c0 <getpinfo>
}
    80003280:	60a2                	ld	ra,8(sp)
    80003282:	6402                	ld	s0,0(sp)
    80003284:	0141                	add	sp,sp,16
    80003286:	8082                	ret

0000000080003288 <sys_pgaccess>:

uint64
sys_pgaccess(void)
{
    80003288:	715d                	add	sp,sp,-80
    8000328a:	e486                	sd	ra,72(sp)
    8000328c:	e0a2                	sd	s0,64(sp)
    8000328e:	fc26                	sd	s1,56(sp)
    80003290:	f84a                	sd	s2,48(sp)
    80003292:	f44e                	sd	s3,40(sp)
    80003294:	0880                	add	s0,sp,80
  uint64 start_va; // starting virtual address of the first user page to check
  int num_pages; // number of pages to check
  uint64 bitmap; // user address to store the results into a bitmask

  argaddr(0, &start_va);
    80003296:	fc840593          	add	a1,s0,-56
    8000329a:	4501                	li	a0,0
    8000329c:	00000097          	auipc	ra,0x0
    800032a0:	cda080e7          	jalr	-806(ra) # 80002f76 <argaddr>
  argint(1, &num_pages);
    800032a4:	fc440593          	add	a1,s0,-60
    800032a8:	4505                	li	a0,1
    800032aa:	00000097          	auipc	ra,0x0
    800032ae:	cac080e7          	jalr	-852(ra) # 80002f56 <argint>
  argaddr(2, &bitmap);
    800032b2:	fb840593          	add	a1,s0,-72
    800032b6:	4509                	li	a0,2
    800032b8:	00000097          	auipc	ra,0x0
    800032bc:	cbe080e7          	jalr	-834(ra) # 80002f76 <argaddr>
  
  return pgaccess((char*)start_va, num_pages, (int*)bitmap, myproc()->pagetable);
    800032c0:	fc843483          	ld	s1,-56(s0)
    800032c4:	fc442903          	lw	s2,-60(s0)
    800032c8:	fb843983          	ld	s3,-72(s0)
    800032cc:	fffff097          	auipc	ra,0xfffff
    800032d0:	892080e7          	jalr	-1902(ra) # 80001b5e <myproc>
    800032d4:	6934                	ld	a3,80(a0)
    800032d6:	864e                	mv	a2,s3
    800032d8:	85ca                	mv	a1,s2
    800032da:	8526                	mv	a0,s1
    800032dc:	ffffe097          	auipc	ra,0xffffe
    800032e0:	680080e7          	jalr	1664(ra) # 8000195c <pgaccess>
    800032e4:	60a6                	ld	ra,72(sp)
    800032e6:	6406                	ld	s0,64(sp)
    800032e8:	74e2                	ld	s1,56(sp)
    800032ea:	7942                	ld	s2,48(sp)
    800032ec:	79a2                	ld	s3,40(sp)
    800032ee:	6161                	add	sp,sp,80
    800032f0:	8082                	ret

00000000800032f2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032f2:	7179                	add	sp,sp,-48
    800032f4:	f406                	sd	ra,40(sp)
    800032f6:	f022                	sd	s0,32(sp)
    800032f8:	ec26                	sd	s1,24(sp)
    800032fa:	e84a                	sd	s2,16(sp)
    800032fc:	e44e                	sd	s3,8(sp)
    800032fe:	e052                	sd	s4,0(sp)
    80003300:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003302:	00005597          	auipc	a1,0x5
    80003306:	28658593          	add	a1,a1,646 # 80008588 <syscalls+0xd0>
    8000330a:	00014517          	auipc	a0,0x14
    8000330e:	b0e50513          	add	a0,a0,-1266 # 80016e18 <bcache>
    80003312:	ffffe097          	auipc	ra,0xffffe
    80003316:	830080e7          	jalr	-2000(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000331a:	0001c797          	auipc	a5,0x1c
    8000331e:	afe78793          	add	a5,a5,-1282 # 8001ee18 <bcache+0x8000>
    80003322:	0001c717          	auipc	a4,0x1c
    80003326:	d5e70713          	add	a4,a4,-674 # 8001f080 <bcache+0x8268>
    8000332a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000332e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003332:	00014497          	auipc	s1,0x14
    80003336:	afe48493          	add	s1,s1,-1282 # 80016e30 <bcache+0x18>
    b->next = bcache.head.next;
    8000333a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000333c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000333e:	00005a17          	auipc	s4,0x5
    80003342:	252a0a13          	add	s4,s4,594 # 80008590 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003346:	2b893783          	ld	a5,696(s2)
    8000334a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000334c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003350:	85d2                	mv	a1,s4
    80003352:	01048513          	add	a0,s1,16
    80003356:	00001097          	auipc	ra,0x1
    8000335a:	496080e7          	jalr	1174(ra) # 800047ec <initsleeplock>
    bcache.head.next->prev = b;
    8000335e:	2b893783          	ld	a5,696(s2)
    80003362:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003364:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003368:	45848493          	add	s1,s1,1112
    8000336c:	fd349de3          	bne	s1,s3,80003346 <binit+0x54>
  }
}
    80003370:	70a2                	ld	ra,40(sp)
    80003372:	7402                	ld	s0,32(sp)
    80003374:	64e2                	ld	s1,24(sp)
    80003376:	6942                	ld	s2,16(sp)
    80003378:	69a2                	ld	s3,8(sp)
    8000337a:	6a02                	ld	s4,0(sp)
    8000337c:	6145                	add	sp,sp,48
    8000337e:	8082                	ret

0000000080003380 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003380:	7179                	add	sp,sp,-48
    80003382:	f406                	sd	ra,40(sp)
    80003384:	f022                	sd	s0,32(sp)
    80003386:	ec26                	sd	s1,24(sp)
    80003388:	e84a                	sd	s2,16(sp)
    8000338a:	e44e                	sd	s3,8(sp)
    8000338c:	1800                	add	s0,sp,48
    8000338e:	892a                	mv	s2,a0
    80003390:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003392:	00014517          	auipc	a0,0x14
    80003396:	a8650513          	add	a0,a0,-1402 # 80016e18 <bcache>
    8000339a:	ffffe097          	auipc	ra,0xffffe
    8000339e:	838080e7          	jalr	-1992(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033a2:	0001c497          	auipc	s1,0x1c
    800033a6:	d2e4b483          	ld	s1,-722(s1) # 8001f0d0 <bcache+0x82b8>
    800033aa:	0001c797          	auipc	a5,0x1c
    800033ae:	cd678793          	add	a5,a5,-810 # 8001f080 <bcache+0x8268>
    800033b2:	02f48f63          	beq	s1,a5,800033f0 <bread+0x70>
    800033b6:	873e                	mv	a4,a5
    800033b8:	a021                	j	800033c0 <bread+0x40>
    800033ba:	68a4                	ld	s1,80(s1)
    800033bc:	02e48a63          	beq	s1,a4,800033f0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033c0:	449c                	lw	a5,8(s1)
    800033c2:	ff279ce3          	bne	a5,s2,800033ba <bread+0x3a>
    800033c6:	44dc                	lw	a5,12(s1)
    800033c8:	ff3799e3          	bne	a5,s3,800033ba <bread+0x3a>
      b->refcnt++;
    800033cc:	40bc                	lw	a5,64(s1)
    800033ce:	2785                	addw	a5,a5,1
    800033d0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033d2:	00014517          	auipc	a0,0x14
    800033d6:	a4650513          	add	a0,a0,-1466 # 80016e18 <bcache>
    800033da:	ffffe097          	auipc	ra,0xffffe
    800033de:	8ac080e7          	jalr	-1876(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800033e2:	01048513          	add	a0,s1,16
    800033e6:	00001097          	auipc	ra,0x1
    800033ea:	440080e7          	jalr	1088(ra) # 80004826 <acquiresleep>
      return b;
    800033ee:	a8b9                	j	8000344c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033f0:	0001c497          	auipc	s1,0x1c
    800033f4:	cd84b483          	ld	s1,-808(s1) # 8001f0c8 <bcache+0x82b0>
    800033f8:	0001c797          	auipc	a5,0x1c
    800033fc:	c8878793          	add	a5,a5,-888 # 8001f080 <bcache+0x8268>
    80003400:	00f48863          	beq	s1,a5,80003410 <bread+0x90>
    80003404:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003406:	40bc                	lw	a5,64(s1)
    80003408:	cf81                	beqz	a5,80003420 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000340a:	64a4                	ld	s1,72(s1)
    8000340c:	fee49de3          	bne	s1,a4,80003406 <bread+0x86>
  panic("bget: no buffers");
    80003410:	00005517          	auipc	a0,0x5
    80003414:	18850513          	add	a0,a0,392 # 80008598 <syscalls+0xe0>
    80003418:	ffffd097          	auipc	ra,0xffffd
    8000341c:	124080e7          	jalr	292(ra) # 8000053c <panic>
      b->dev = dev;
    80003420:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003424:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003428:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000342c:	4785                	li	a5,1
    8000342e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003430:	00014517          	auipc	a0,0x14
    80003434:	9e850513          	add	a0,a0,-1560 # 80016e18 <bcache>
    80003438:	ffffe097          	auipc	ra,0xffffe
    8000343c:	84e080e7          	jalr	-1970(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003440:	01048513          	add	a0,s1,16
    80003444:	00001097          	auipc	ra,0x1
    80003448:	3e2080e7          	jalr	994(ra) # 80004826 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000344c:	409c                	lw	a5,0(s1)
    8000344e:	cb89                	beqz	a5,80003460 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003450:	8526                	mv	a0,s1
    80003452:	70a2                	ld	ra,40(sp)
    80003454:	7402                	ld	s0,32(sp)
    80003456:	64e2                	ld	s1,24(sp)
    80003458:	6942                	ld	s2,16(sp)
    8000345a:	69a2                	ld	s3,8(sp)
    8000345c:	6145                	add	sp,sp,48
    8000345e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003460:	4581                	li	a1,0
    80003462:	8526                	mv	a0,s1
    80003464:	00003097          	auipc	ra,0x3
    80003468:	f9e080e7          	jalr	-98(ra) # 80006402 <virtio_disk_rw>
    b->valid = 1;
    8000346c:	4785                	li	a5,1
    8000346e:	c09c                	sw	a5,0(s1)
  return b;
    80003470:	b7c5                	j	80003450 <bread+0xd0>

0000000080003472 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003472:	1101                	add	sp,sp,-32
    80003474:	ec06                	sd	ra,24(sp)
    80003476:	e822                	sd	s0,16(sp)
    80003478:	e426                	sd	s1,8(sp)
    8000347a:	1000                	add	s0,sp,32
    8000347c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000347e:	0541                	add	a0,a0,16
    80003480:	00001097          	auipc	ra,0x1
    80003484:	440080e7          	jalr	1088(ra) # 800048c0 <holdingsleep>
    80003488:	cd01                	beqz	a0,800034a0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000348a:	4585                	li	a1,1
    8000348c:	8526                	mv	a0,s1
    8000348e:	00003097          	auipc	ra,0x3
    80003492:	f74080e7          	jalr	-140(ra) # 80006402 <virtio_disk_rw>
}
    80003496:	60e2                	ld	ra,24(sp)
    80003498:	6442                	ld	s0,16(sp)
    8000349a:	64a2                	ld	s1,8(sp)
    8000349c:	6105                	add	sp,sp,32
    8000349e:	8082                	ret
    panic("bwrite");
    800034a0:	00005517          	auipc	a0,0x5
    800034a4:	11050513          	add	a0,a0,272 # 800085b0 <syscalls+0xf8>
    800034a8:	ffffd097          	auipc	ra,0xffffd
    800034ac:	094080e7          	jalr	148(ra) # 8000053c <panic>

00000000800034b0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034b0:	1101                	add	sp,sp,-32
    800034b2:	ec06                	sd	ra,24(sp)
    800034b4:	e822                	sd	s0,16(sp)
    800034b6:	e426                	sd	s1,8(sp)
    800034b8:	e04a                	sd	s2,0(sp)
    800034ba:	1000                	add	s0,sp,32
    800034bc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034be:	01050913          	add	s2,a0,16
    800034c2:	854a                	mv	a0,s2
    800034c4:	00001097          	auipc	ra,0x1
    800034c8:	3fc080e7          	jalr	1020(ra) # 800048c0 <holdingsleep>
    800034cc:	c925                	beqz	a0,8000353c <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800034ce:	854a                	mv	a0,s2
    800034d0:	00001097          	auipc	ra,0x1
    800034d4:	3ac080e7          	jalr	940(ra) # 8000487c <releasesleep>

  acquire(&bcache.lock);
    800034d8:	00014517          	auipc	a0,0x14
    800034dc:	94050513          	add	a0,a0,-1728 # 80016e18 <bcache>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	6f2080e7          	jalr	1778(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800034e8:	40bc                	lw	a5,64(s1)
    800034ea:	37fd                	addw	a5,a5,-1
    800034ec:	0007871b          	sext.w	a4,a5
    800034f0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034f2:	e71d                	bnez	a4,80003520 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034f4:	68b8                	ld	a4,80(s1)
    800034f6:	64bc                	ld	a5,72(s1)
    800034f8:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800034fa:	68b8                	ld	a4,80(s1)
    800034fc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034fe:	0001c797          	auipc	a5,0x1c
    80003502:	91a78793          	add	a5,a5,-1766 # 8001ee18 <bcache+0x8000>
    80003506:	2b87b703          	ld	a4,696(a5)
    8000350a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000350c:	0001c717          	auipc	a4,0x1c
    80003510:	b7470713          	add	a4,a4,-1164 # 8001f080 <bcache+0x8268>
    80003514:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003516:	2b87b703          	ld	a4,696(a5)
    8000351a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000351c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003520:	00014517          	auipc	a0,0x14
    80003524:	8f850513          	add	a0,a0,-1800 # 80016e18 <bcache>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	75e080e7          	jalr	1886(ra) # 80000c86 <release>
}
    80003530:	60e2                	ld	ra,24(sp)
    80003532:	6442                	ld	s0,16(sp)
    80003534:	64a2                	ld	s1,8(sp)
    80003536:	6902                	ld	s2,0(sp)
    80003538:	6105                	add	sp,sp,32
    8000353a:	8082                	ret
    panic("brelse");
    8000353c:	00005517          	auipc	a0,0x5
    80003540:	07c50513          	add	a0,a0,124 # 800085b8 <syscalls+0x100>
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	ff8080e7          	jalr	-8(ra) # 8000053c <panic>

000000008000354c <bpin>:

void
bpin(struct buf *b) {
    8000354c:	1101                	add	sp,sp,-32
    8000354e:	ec06                	sd	ra,24(sp)
    80003550:	e822                	sd	s0,16(sp)
    80003552:	e426                	sd	s1,8(sp)
    80003554:	1000                	add	s0,sp,32
    80003556:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003558:	00014517          	auipc	a0,0x14
    8000355c:	8c050513          	add	a0,a0,-1856 # 80016e18 <bcache>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	672080e7          	jalr	1650(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003568:	40bc                	lw	a5,64(s1)
    8000356a:	2785                	addw	a5,a5,1
    8000356c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000356e:	00014517          	auipc	a0,0x14
    80003572:	8aa50513          	add	a0,a0,-1878 # 80016e18 <bcache>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	710080e7          	jalr	1808(ra) # 80000c86 <release>
}
    8000357e:	60e2                	ld	ra,24(sp)
    80003580:	6442                	ld	s0,16(sp)
    80003582:	64a2                	ld	s1,8(sp)
    80003584:	6105                	add	sp,sp,32
    80003586:	8082                	ret

0000000080003588 <bunpin>:

void
bunpin(struct buf *b) {
    80003588:	1101                	add	sp,sp,-32
    8000358a:	ec06                	sd	ra,24(sp)
    8000358c:	e822                	sd	s0,16(sp)
    8000358e:	e426                	sd	s1,8(sp)
    80003590:	1000                	add	s0,sp,32
    80003592:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003594:	00014517          	auipc	a0,0x14
    80003598:	88450513          	add	a0,a0,-1916 # 80016e18 <bcache>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	636080e7          	jalr	1590(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800035a4:	40bc                	lw	a5,64(s1)
    800035a6:	37fd                	addw	a5,a5,-1
    800035a8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035aa:	00014517          	auipc	a0,0x14
    800035ae:	86e50513          	add	a0,a0,-1938 # 80016e18 <bcache>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	6d4080e7          	jalr	1748(ra) # 80000c86 <release>
}
    800035ba:	60e2                	ld	ra,24(sp)
    800035bc:	6442                	ld	s0,16(sp)
    800035be:	64a2                	ld	s1,8(sp)
    800035c0:	6105                	add	sp,sp,32
    800035c2:	8082                	ret

00000000800035c4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035c4:	1101                	add	sp,sp,-32
    800035c6:	ec06                	sd	ra,24(sp)
    800035c8:	e822                	sd	s0,16(sp)
    800035ca:	e426                	sd	s1,8(sp)
    800035cc:	e04a                	sd	s2,0(sp)
    800035ce:	1000                	add	s0,sp,32
    800035d0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035d2:	00d5d59b          	srlw	a1,a1,0xd
    800035d6:	0001c797          	auipc	a5,0x1c
    800035da:	f1e7a783          	lw	a5,-226(a5) # 8001f4f4 <sb+0x1c>
    800035de:	9dbd                	addw	a1,a1,a5
    800035e0:	00000097          	auipc	ra,0x0
    800035e4:	da0080e7          	jalr	-608(ra) # 80003380 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035e8:	0074f713          	and	a4,s1,7
    800035ec:	4785                	li	a5,1
    800035ee:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035f2:	14ce                	sll	s1,s1,0x33
    800035f4:	90d9                	srl	s1,s1,0x36
    800035f6:	00950733          	add	a4,a0,s1
    800035fa:	05874703          	lbu	a4,88(a4)
    800035fe:	00e7f6b3          	and	a3,a5,a4
    80003602:	c69d                	beqz	a3,80003630 <bfree+0x6c>
    80003604:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003606:	94aa                	add	s1,s1,a0
    80003608:	fff7c793          	not	a5,a5
    8000360c:	8f7d                	and	a4,a4,a5
    8000360e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003612:	00001097          	auipc	ra,0x1
    80003616:	0f6080e7          	jalr	246(ra) # 80004708 <log_write>
  brelse(bp);
    8000361a:	854a                	mv	a0,s2
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	e94080e7          	jalr	-364(ra) # 800034b0 <brelse>
}
    80003624:	60e2                	ld	ra,24(sp)
    80003626:	6442                	ld	s0,16(sp)
    80003628:	64a2                	ld	s1,8(sp)
    8000362a:	6902                	ld	s2,0(sp)
    8000362c:	6105                	add	sp,sp,32
    8000362e:	8082                	ret
    panic("freeing free block");
    80003630:	00005517          	auipc	a0,0x5
    80003634:	f9050513          	add	a0,a0,-112 # 800085c0 <syscalls+0x108>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	f04080e7          	jalr	-252(ra) # 8000053c <panic>

0000000080003640 <balloc>:
{
    80003640:	711d                	add	sp,sp,-96
    80003642:	ec86                	sd	ra,88(sp)
    80003644:	e8a2                	sd	s0,80(sp)
    80003646:	e4a6                	sd	s1,72(sp)
    80003648:	e0ca                	sd	s2,64(sp)
    8000364a:	fc4e                	sd	s3,56(sp)
    8000364c:	f852                	sd	s4,48(sp)
    8000364e:	f456                	sd	s5,40(sp)
    80003650:	f05a                	sd	s6,32(sp)
    80003652:	ec5e                	sd	s7,24(sp)
    80003654:	e862                	sd	s8,16(sp)
    80003656:	e466                	sd	s9,8(sp)
    80003658:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000365a:	0001c797          	auipc	a5,0x1c
    8000365e:	e827a783          	lw	a5,-382(a5) # 8001f4dc <sb+0x4>
    80003662:	cff5                	beqz	a5,8000375e <balloc+0x11e>
    80003664:	8baa                	mv	s7,a0
    80003666:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003668:	0001cb17          	auipc	s6,0x1c
    8000366c:	e70b0b13          	add	s6,s6,-400 # 8001f4d8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003670:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003672:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003674:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003676:	6c89                	lui	s9,0x2
    80003678:	a061                	j	80003700 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000367a:	97ca                	add	a5,a5,s2
    8000367c:	8e55                	or	a2,a2,a3
    8000367e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003682:	854a                	mv	a0,s2
    80003684:	00001097          	auipc	ra,0x1
    80003688:	084080e7          	jalr	132(ra) # 80004708 <log_write>
        brelse(bp);
    8000368c:	854a                	mv	a0,s2
    8000368e:	00000097          	auipc	ra,0x0
    80003692:	e22080e7          	jalr	-478(ra) # 800034b0 <brelse>
  bp = bread(dev, bno);
    80003696:	85a6                	mv	a1,s1
    80003698:	855e                	mv	a0,s7
    8000369a:	00000097          	auipc	ra,0x0
    8000369e:	ce6080e7          	jalr	-794(ra) # 80003380 <bread>
    800036a2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036a4:	40000613          	li	a2,1024
    800036a8:	4581                	li	a1,0
    800036aa:	05850513          	add	a0,a0,88
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	620080e7          	jalr	1568(ra) # 80000cce <memset>
  log_write(bp);
    800036b6:	854a                	mv	a0,s2
    800036b8:	00001097          	auipc	ra,0x1
    800036bc:	050080e7          	jalr	80(ra) # 80004708 <log_write>
  brelse(bp);
    800036c0:	854a                	mv	a0,s2
    800036c2:	00000097          	auipc	ra,0x0
    800036c6:	dee080e7          	jalr	-530(ra) # 800034b0 <brelse>
}
    800036ca:	8526                	mv	a0,s1
    800036cc:	60e6                	ld	ra,88(sp)
    800036ce:	6446                	ld	s0,80(sp)
    800036d0:	64a6                	ld	s1,72(sp)
    800036d2:	6906                	ld	s2,64(sp)
    800036d4:	79e2                	ld	s3,56(sp)
    800036d6:	7a42                	ld	s4,48(sp)
    800036d8:	7aa2                	ld	s5,40(sp)
    800036da:	7b02                	ld	s6,32(sp)
    800036dc:	6be2                	ld	s7,24(sp)
    800036de:	6c42                	ld	s8,16(sp)
    800036e0:	6ca2                	ld	s9,8(sp)
    800036e2:	6125                	add	sp,sp,96
    800036e4:	8082                	ret
    brelse(bp);
    800036e6:	854a                	mv	a0,s2
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	dc8080e7          	jalr	-568(ra) # 800034b0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036f0:	015c87bb          	addw	a5,s9,s5
    800036f4:	00078a9b          	sext.w	s5,a5
    800036f8:	004b2703          	lw	a4,4(s6)
    800036fc:	06eaf163          	bgeu	s5,a4,8000375e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003700:	41fad79b          	sraw	a5,s5,0x1f
    80003704:	0137d79b          	srlw	a5,a5,0x13
    80003708:	015787bb          	addw	a5,a5,s5
    8000370c:	40d7d79b          	sraw	a5,a5,0xd
    80003710:	01cb2583          	lw	a1,28(s6)
    80003714:	9dbd                	addw	a1,a1,a5
    80003716:	855e                	mv	a0,s7
    80003718:	00000097          	auipc	ra,0x0
    8000371c:	c68080e7          	jalr	-920(ra) # 80003380 <bread>
    80003720:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003722:	004b2503          	lw	a0,4(s6)
    80003726:	000a849b          	sext.w	s1,s5
    8000372a:	8762                	mv	a4,s8
    8000372c:	faa4fde3          	bgeu	s1,a0,800036e6 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003730:	00777693          	and	a3,a4,7
    80003734:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003738:	41f7579b          	sraw	a5,a4,0x1f
    8000373c:	01d7d79b          	srlw	a5,a5,0x1d
    80003740:	9fb9                	addw	a5,a5,a4
    80003742:	4037d79b          	sraw	a5,a5,0x3
    80003746:	00f90633          	add	a2,s2,a5
    8000374a:	05864603          	lbu	a2,88(a2)
    8000374e:	00c6f5b3          	and	a1,a3,a2
    80003752:	d585                	beqz	a1,8000367a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003754:	2705                	addw	a4,a4,1
    80003756:	2485                	addw	s1,s1,1
    80003758:	fd471ae3          	bne	a4,s4,8000372c <balloc+0xec>
    8000375c:	b769                	j	800036e6 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000375e:	00005517          	auipc	a0,0x5
    80003762:	e7a50513          	add	a0,a0,-390 # 800085d8 <syscalls+0x120>
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	e20080e7          	jalr	-480(ra) # 80000586 <printf>
  return 0;
    8000376e:	4481                	li	s1,0
    80003770:	bfa9                	j	800036ca <balloc+0x8a>

0000000080003772 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003772:	7179                	add	sp,sp,-48
    80003774:	f406                	sd	ra,40(sp)
    80003776:	f022                	sd	s0,32(sp)
    80003778:	ec26                	sd	s1,24(sp)
    8000377a:	e84a                	sd	s2,16(sp)
    8000377c:	e44e                	sd	s3,8(sp)
    8000377e:	e052                	sd	s4,0(sp)
    80003780:	1800                	add	s0,sp,48
    80003782:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003784:	47ad                	li	a5,11
    80003786:	02b7e863          	bltu	a5,a1,800037b6 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000378a:	02059793          	sll	a5,a1,0x20
    8000378e:	01e7d593          	srl	a1,a5,0x1e
    80003792:	00b504b3          	add	s1,a0,a1
    80003796:	0504a903          	lw	s2,80(s1)
    8000379a:	06091e63          	bnez	s2,80003816 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000379e:	4108                	lw	a0,0(a0)
    800037a0:	00000097          	auipc	ra,0x0
    800037a4:	ea0080e7          	jalr	-352(ra) # 80003640 <balloc>
    800037a8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037ac:	06090563          	beqz	s2,80003816 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800037b0:	0524a823          	sw	s2,80(s1)
    800037b4:	a08d                	j	80003816 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800037b6:	ff45849b          	addw	s1,a1,-12
    800037ba:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037be:	0ff00793          	li	a5,255
    800037c2:	08e7e563          	bltu	a5,a4,8000384c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800037c6:	08052903          	lw	s2,128(a0)
    800037ca:	00091d63          	bnez	s2,800037e4 <bmap+0x72>
      addr = balloc(ip->dev);
    800037ce:	4108                	lw	a0,0(a0)
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	e70080e7          	jalr	-400(ra) # 80003640 <balloc>
    800037d8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037dc:	02090d63          	beqz	s2,80003816 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800037e0:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800037e4:	85ca                	mv	a1,s2
    800037e6:	0009a503          	lw	a0,0(s3)
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	b96080e7          	jalr	-1130(ra) # 80003380 <bread>
    800037f2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037f4:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    800037f8:	02049713          	sll	a4,s1,0x20
    800037fc:	01e75593          	srl	a1,a4,0x1e
    80003800:	00b784b3          	add	s1,a5,a1
    80003804:	0004a903          	lw	s2,0(s1)
    80003808:	02090063          	beqz	s2,80003828 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000380c:	8552                	mv	a0,s4
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	ca2080e7          	jalr	-862(ra) # 800034b0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003816:	854a                	mv	a0,s2
    80003818:	70a2                	ld	ra,40(sp)
    8000381a:	7402                	ld	s0,32(sp)
    8000381c:	64e2                	ld	s1,24(sp)
    8000381e:	6942                	ld	s2,16(sp)
    80003820:	69a2                	ld	s3,8(sp)
    80003822:	6a02                	ld	s4,0(sp)
    80003824:	6145                	add	sp,sp,48
    80003826:	8082                	ret
      addr = balloc(ip->dev);
    80003828:	0009a503          	lw	a0,0(s3)
    8000382c:	00000097          	auipc	ra,0x0
    80003830:	e14080e7          	jalr	-492(ra) # 80003640 <balloc>
    80003834:	0005091b          	sext.w	s2,a0
      if(addr){
    80003838:	fc090ae3          	beqz	s2,8000380c <bmap+0x9a>
        a[bn] = addr;
    8000383c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003840:	8552                	mv	a0,s4
    80003842:	00001097          	auipc	ra,0x1
    80003846:	ec6080e7          	jalr	-314(ra) # 80004708 <log_write>
    8000384a:	b7c9                	j	8000380c <bmap+0x9a>
  panic("bmap: out of range");
    8000384c:	00005517          	auipc	a0,0x5
    80003850:	da450513          	add	a0,a0,-604 # 800085f0 <syscalls+0x138>
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	ce8080e7          	jalr	-792(ra) # 8000053c <panic>

000000008000385c <iget>:
{
    8000385c:	7179                	add	sp,sp,-48
    8000385e:	f406                	sd	ra,40(sp)
    80003860:	f022                	sd	s0,32(sp)
    80003862:	ec26                	sd	s1,24(sp)
    80003864:	e84a                	sd	s2,16(sp)
    80003866:	e44e                	sd	s3,8(sp)
    80003868:	e052                	sd	s4,0(sp)
    8000386a:	1800                	add	s0,sp,48
    8000386c:	89aa                	mv	s3,a0
    8000386e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003870:	0001c517          	auipc	a0,0x1c
    80003874:	c8850513          	add	a0,a0,-888 # 8001f4f8 <itable>
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	35a080e7          	jalr	858(ra) # 80000bd2 <acquire>
  empty = 0;
    80003880:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003882:	0001c497          	auipc	s1,0x1c
    80003886:	c8e48493          	add	s1,s1,-882 # 8001f510 <itable+0x18>
    8000388a:	0001d697          	auipc	a3,0x1d
    8000388e:	71668693          	add	a3,a3,1814 # 80020fa0 <log>
    80003892:	a039                	j	800038a0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003894:	02090b63          	beqz	s2,800038ca <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003898:	08848493          	add	s1,s1,136
    8000389c:	02d48a63          	beq	s1,a3,800038d0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038a0:	449c                	lw	a5,8(s1)
    800038a2:	fef059e3          	blez	a5,80003894 <iget+0x38>
    800038a6:	4098                	lw	a4,0(s1)
    800038a8:	ff3716e3          	bne	a4,s3,80003894 <iget+0x38>
    800038ac:	40d8                	lw	a4,4(s1)
    800038ae:	ff4713e3          	bne	a4,s4,80003894 <iget+0x38>
      ip->ref++;
    800038b2:	2785                	addw	a5,a5,1
    800038b4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038b6:	0001c517          	auipc	a0,0x1c
    800038ba:	c4250513          	add	a0,a0,-958 # 8001f4f8 <itable>
    800038be:	ffffd097          	auipc	ra,0xffffd
    800038c2:	3c8080e7          	jalr	968(ra) # 80000c86 <release>
      return ip;
    800038c6:	8926                	mv	s2,s1
    800038c8:	a03d                	j	800038f6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038ca:	f7f9                	bnez	a5,80003898 <iget+0x3c>
    800038cc:	8926                	mv	s2,s1
    800038ce:	b7e9                	j	80003898 <iget+0x3c>
  if(empty == 0)
    800038d0:	02090c63          	beqz	s2,80003908 <iget+0xac>
  ip->dev = dev;
    800038d4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038d8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038dc:	4785                	li	a5,1
    800038de:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038e2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038e6:	0001c517          	auipc	a0,0x1c
    800038ea:	c1250513          	add	a0,a0,-1006 # 8001f4f8 <itable>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	398080e7          	jalr	920(ra) # 80000c86 <release>
}
    800038f6:	854a                	mv	a0,s2
    800038f8:	70a2                	ld	ra,40(sp)
    800038fa:	7402                	ld	s0,32(sp)
    800038fc:	64e2                	ld	s1,24(sp)
    800038fe:	6942                	ld	s2,16(sp)
    80003900:	69a2                	ld	s3,8(sp)
    80003902:	6a02                	ld	s4,0(sp)
    80003904:	6145                	add	sp,sp,48
    80003906:	8082                	ret
    panic("iget: no inodes");
    80003908:	00005517          	auipc	a0,0x5
    8000390c:	d0050513          	add	a0,a0,-768 # 80008608 <syscalls+0x150>
    80003910:	ffffd097          	auipc	ra,0xffffd
    80003914:	c2c080e7          	jalr	-980(ra) # 8000053c <panic>

0000000080003918 <fsinit>:
fsinit(int dev) {
    80003918:	7179                	add	sp,sp,-48
    8000391a:	f406                	sd	ra,40(sp)
    8000391c:	f022                	sd	s0,32(sp)
    8000391e:	ec26                	sd	s1,24(sp)
    80003920:	e84a                	sd	s2,16(sp)
    80003922:	e44e                	sd	s3,8(sp)
    80003924:	1800                	add	s0,sp,48
    80003926:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003928:	4585                	li	a1,1
    8000392a:	00000097          	auipc	ra,0x0
    8000392e:	a56080e7          	jalr	-1450(ra) # 80003380 <bread>
    80003932:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003934:	0001c997          	auipc	s3,0x1c
    80003938:	ba498993          	add	s3,s3,-1116 # 8001f4d8 <sb>
    8000393c:	02000613          	li	a2,32
    80003940:	05850593          	add	a1,a0,88
    80003944:	854e                	mv	a0,s3
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	3e4080e7          	jalr	996(ra) # 80000d2a <memmove>
  brelse(bp);
    8000394e:	8526                	mv	a0,s1
    80003950:	00000097          	auipc	ra,0x0
    80003954:	b60080e7          	jalr	-1184(ra) # 800034b0 <brelse>
  if(sb.magic != FSMAGIC)
    80003958:	0009a703          	lw	a4,0(s3)
    8000395c:	102037b7          	lui	a5,0x10203
    80003960:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003964:	02f71263          	bne	a4,a5,80003988 <fsinit+0x70>
  initlog(dev, &sb);
    80003968:	0001c597          	auipc	a1,0x1c
    8000396c:	b7058593          	add	a1,a1,-1168 # 8001f4d8 <sb>
    80003970:	854a                	mv	a0,s2
    80003972:	00001097          	auipc	ra,0x1
    80003976:	b2c080e7          	jalr	-1236(ra) # 8000449e <initlog>
}
    8000397a:	70a2                	ld	ra,40(sp)
    8000397c:	7402                	ld	s0,32(sp)
    8000397e:	64e2                	ld	s1,24(sp)
    80003980:	6942                	ld	s2,16(sp)
    80003982:	69a2                	ld	s3,8(sp)
    80003984:	6145                	add	sp,sp,48
    80003986:	8082                	ret
    panic("invalid file system");
    80003988:	00005517          	auipc	a0,0x5
    8000398c:	c9050513          	add	a0,a0,-880 # 80008618 <syscalls+0x160>
    80003990:	ffffd097          	auipc	ra,0xffffd
    80003994:	bac080e7          	jalr	-1108(ra) # 8000053c <panic>

0000000080003998 <iinit>:
{
    80003998:	7179                	add	sp,sp,-48
    8000399a:	f406                	sd	ra,40(sp)
    8000399c:	f022                	sd	s0,32(sp)
    8000399e:	ec26                	sd	s1,24(sp)
    800039a0:	e84a                	sd	s2,16(sp)
    800039a2:	e44e                	sd	s3,8(sp)
    800039a4:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    800039a6:	00005597          	auipc	a1,0x5
    800039aa:	c8a58593          	add	a1,a1,-886 # 80008630 <syscalls+0x178>
    800039ae:	0001c517          	auipc	a0,0x1c
    800039b2:	b4a50513          	add	a0,a0,-1206 # 8001f4f8 <itable>
    800039b6:	ffffd097          	auipc	ra,0xffffd
    800039ba:	18c080e7          	jalr	396(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039be:	0001c497          	auipc	s1,0x1c
    800039c2:	b6248493          	add	s1,s1,-1182 # 8001f520 <itable+0x28>
    800039c6:	0001d997          	auipc	s3,0x1d
    800039ca:	5ea98993          	add	s3,s3,1514 # 80020fb0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039ce:	00005917          	auipc	s2,0x5
    800039d2:	c6a90913          	add	s2,s2,-918 # 80008638 <syscalls+0x180>
    800039d6:	85ca                	mv	a1,s2
    800039d8:	8526                	mv	a0,s1
    800039da:	00001097          	auipc	ra,0x1
    800039de:	e12080e7          	jalr	-494(ra) # 800047ec <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039e2:	08848493          	add	s1,s1,136
    800039e6:	ff3498e3          	bne	s1,s3,800039d6 <iinit+0x3e>
}
    800039ea:	70a2                	ld	ra,40(sp)
    800039ec:	7402                	ld	s0,32(sp)
    800039ee:	64e2                	ld	s1,24(sp)
    800039f0:	6942                	ld	s2,16(sp)
    800039f2:	69a2                	ld	s3,8(sp)
    800039f4:	6145                	add	sp,sp,48
    800039f6:	8082                	ret

00000000800039f8 <ialloc>:
{
    800039f8:	7139                	add	sp,sp,-64
    800039fa:	fc06                	sd	ra,56(sp)
    800039fc:	f822                	sd	s0,48(sp)
    800039fe:	f426                	sd	s1,40(sp)
    80003a00:	f04a                	sd	s2,32(sp)
    80003a02:	ec4e                	sd	s3,24(sp)
    80003a04:	e852                	sd	s4,16(sp)
    80003a06:	e456                	sd	s5,8(sp)
    80003a08:	e05a                	sd	s6,0(sp)
    80003a0a:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a0c:	0001c717          	auipc	a4,0x1c
    80003a10:	ad872703          	lw	a4,-1320(a4) # 8001f4e4 <sb+0xc>
    80003a14:	4785                	li	a5,1
    80003a16:	04e7f863          	bgeu	a5,a4,80003a66 <ialloc+0x6e>
    80003a1a:	8aaa                	mv	s5,a0
    80003a1c:	8b2e                	mv	s6,a1
    80003a1e:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a20:	0001ca17          	auipc	s4,0x1c
    80003a24:	ab8a0a13          	add	s4,s4,-1352 # 8001f4d8 <sb>
    80003a28:	00495593          	srl	a1,s2,0x4
    80003a2c:	018a2783          	lw	a5,24(s4)
    80003a30:	9dbd                	addw	a1,a1,a5
    80003a32:	8556                	mv	a0,s5
    80003a34:	00000097          	auipc	ra,0x0
    80003a38:	94c080e7          	jalr	-1716(ra) # 80003380 <bread>
    80003a3c:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a3e:	05850993          	add	s3,a0,88
    80003a42:	00f97793          	and	a5,s2,15
    80003a46:	079a                	sll	a5,a5,0x6
    80003a48:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a4a:	00099783          	lh	a5,0(s3)
    80003a4e:	cf9d                	beqz	a5,80003a8c <ialloc+0x94>
    brelse(bp);
    80003a50:	00000097          	auipc	ra,0x0
    80003a54:	a60080e7          	jalr	-1440(ra) # 800034b0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a58:	0905                	add	s2,s2,1
    80003a5a:	00ca2703          	lw	a4,12(s4)
    80003a5e:	0009079b          	sext.w	a5,s2
    80003a62:	fce7e3e3          	bltu	a5,a4,80003a28 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003a66:	00005517          	auipc	a0,0x5
    80003a6a:	bda50513          	add	a0,a0,-1062 # 80008640 <syscalls+0x188>
    80003a6e:	ffffd097          	auipc	ra,0xffffd
    80003a72:	b18080e7          	jalr	-1256(ra) # 80000586 <printf>
  return 0;
    80003a76:	4501                	li	a0,0
}
    80003a78:	70e2                	ld	ra,56(sp)
    80003a7a:	7442                	ld	s0,48(sp)
    80003a7c:	74a2                	ld	s1,40(sp)
    80003a7e:	7902                	ld	s2,32(sp)
    80003a80:	69e2                	ld	s3,24(sp)
    80003a82:	6a42                	ld	s4,16(sp)
    80003a84:	6aa2                	ld	s5,8(sp)
    80003a86:	6b02                	ld	s6,0(sp)
    80003a88:	6121                	add	sp,sp,64
    80003a8a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003a8c:	04000613          	li	a2,64
    80003a90:	4581                	li	a1,0
    80003a92:	854e                	mv	a0,s3
    80003a94:	ffffd097          	auipc	ra,0xffffd
    80003a98:	23a080e7          	jalr	570(ra) # 80000cce <memset>
      dip->type = type;
    80003a9c:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003aa0:	8526                	mv	a0,s1
    80003aa2:	00001097          	auipc	ra,0x1
    80003aa6:	c66080e7          	jalr	-922(ra) # 80004708 <log_write>
      brelse(bp);
    80003aaa:	8526                	mv	a0,s1
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	a04080e7          	jalr	-1532(ra) # 800034b0 <brelse>
      return iget(dev, inum);
    80003ab4:	0009059b          	sext.w	a1,s2
    80003ab8:	8556                	mv	a0,s5
    80003aba:	00000097          	auipc	ra,0x0
    80003abe:	da2080e7          	jalr	-606(ra) # 8000385c <iget>
    80003ac2:	bf5d                	j	80003a78 <ialloc+0x80>

0000000080003ac4 <iupdate>:
{
    80003ac4:	1101                	add	sp,sp,-32
    80003ac6:	ec06                	sd	ra,24(sp)
    80003ac8:	e822                	sd	s0,16(sp)
    80003aca:	e426                	sd	s1,8(sp)
    80003acc:	e04a                	sd	s2,0(sp)
    80003ace:	1000                	add	s0,sp,32
    80003ad0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ad2:	415c                	lw	a5,4(a0)
    80003ad4:	0047d79b          	srlw	a5,a5,0x4
    80003ad8:	0001c597          	auipc	a1,0x1c
    80003adc:	a185a583          	lw	a1,-1512(a1) # 8001f4f0 <sb+0x18>
    80003ae0:	9dbd                	addw	a1,a1,a5
    80003ae2:	4108                	lw	a0,0(a0)
    80003ae4:	00000097          	auipc	ra,0x0
    80003ae8:	89c080e7          	jalr	-1892(ra) # 80003380 <bread>
    80003aec:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003aee:	05850793          	add	a5,a0,88
    80003af2:	40d8                	lw	a4,4(s1)
    80003af4:	8b3d                	and	a4,a4,15
    80003af6:	071a                	sll	a4,a4,0x6
    80003af8:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003afa:	04449703          	lh	a4,68(s1)
    80003afe:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003b02:	04649703          	lh	a4,70(s1)
    80003b06:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003b0a:	04849703          	lh	a4,72(s1)
    80003b0e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003b12:	04a49703          	lh	a4,74(s1)
    80003b16:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003b1a:	44f8                	lw	a4,76(s1)
    80003b1c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b1e:	03400613          	li	a2,52
    80003b22:	05048593          	add	a1,s1,80
    80003b26:	00c78513          	add	a0,a5,12
    80003b2a:	ffffd097          	auipc	ra,0xffffd
    80003b2e:	200080e7          	jalr	512(ra) # 80000d2a <memmove>
  log_write(bp);
    80003b32:	854a                	mv	a0,s2
    80003b34:	00001097          	auipc	ra,0x1
    80003b38:	bd4080e7          	jalr	-1068(ra) # 80004708 <log_write>
  brelse(bp);
    80003b3c:	854a                	mv	a0,s2
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	972080e7          	jalr	-1678(ra) # 800034b0 <brelse>
}
    80003b46:	60e2                	ld	ra,24(sp)
    80003b48:	6442                	ld	s0,16(sp)
    80003b4a:	64a2                	ld	s1,8(sp)
    80003b4c:	6902                	ld	s2,0(sp)
    80003b4e:	6105                	add	sp,sp,32
    80003b50:	8082                	ret

0000000080003b52 <idup>:
{
    80003b52:	1101                	add	sp,sp,-32
    80003b54:	ec06                	sd	ra,24(sp)
    80003b56:	e822                	sd	s0,16(sp)
    80003b58:	e426                	sd	s1,8(sp)
    80003b5a:	1000                	add	s0,sp,32
    80003b5c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b5e:	0001c517          	auipc	a0,0x1c
    80003b62:	99a50513          	add	a0,a0,-1638 # 8001f4f8 <itable>
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	06c080e7          	jalr	108(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003b6e:	449c                	lw	a5,8(s1)
    80003b70:	2785                	addw	a5,a5,1
    80003b72:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b74:	0001c517          	auipc	a0,0x1c
    80003b78:	98450513          	add	a0,a0,-1660 # 8001f4f8 <itable>
    80003b7c:	ffffd097          	auipc	ra,0xffffd
    80003b80:	10a080e7          	jalr	266(ra) # 80000c86 <release>
}
    80003b84:	8526                	mv	a0,s1
    80003b86:	60e2                	ld	ra,24(sp)
    80003b88:	6442                	ld	s0,16(sp)
    80003b8a:	64a2                	ld	s1,8(sp)
    80003b8c:	6105                	add	sp,sp,32
    80003b8e:	8082                	ret

0000000080003b90 <ilock>:
{
    80003b90:	1101                	add	sp,sp,-32
    80003b92:	ec06                	sd	ra,24(sp)
    80003b94:	e822                	sd	s0,16(sp)
    80003b96:	e426                	sd	s1,8(sp)
    80003b98:	e04a                	sd	s2,0(sp)
    80003b9a:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b9c:	c115                	beqz	a0,80003bc0 <ilock+0x30>
    80003b9e:	84aa                	mv	s1,a0
    80003ba0:	451c                	lw	a5,8(a0)
    80003ba2:	00f05f63          	blez	a5,80003bc0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ba6:	0541                	add	a0,a0,16
    80003ba8:	00001097          	auipc	ra,0x1
    80003bac:	c7e080e7          	jalr	-898(ra) # 80004826 <acquiresleep>
  if(ip->valid == 0){
    80003bb0:	40bc                	lw	a5,64(s1)
    80003bb2:	cf99                	beqz	a5,80003bd0 <ilock+0x40>
}
    80003bb4:	60e2                	ld	ra,24(sp)
    80003bb6:	6442                	ld	s0,16(sp)
    80003bb8:	64a2                	ld	s1,8(sp)
    80003bba:	6902                	ld	s2,0(sp)
    80003bbc:	6105                	add	sp,sp,32
    80003bbe:	8082                	ret
    panic("ilock");
    80003bc0:	00005517          	auipc	a0,0x5
    80003bc4:	a9850513          	add	a0,a0,-1384 # 80008658 <syscalls+0x1a0>
    80003bc8:	ffffd097          	auipc	ra,0xffffd
    80003bcc:	974080e7          	jalr	-1676(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bd0:	40dc                	lw	a5,4(s1)
    80003bd2:	0047d79b          	srlw	a5,a5,0x4
    80003bd6:	0001c597          	auipc	a1,0x1c
    80003bda:	91a5a583          	lw	a1,-1766(a1) # 8001f4f0 <sb+0x18>
    80003bde:	9dbd                	addw	a1,a1,a5
    80003be0:	4088                	lw	a0,0(s1)
    80003be2:	fffff097          	auipc	ra,0xfffff
    80003be6:	79e080e7          	jalr	1950(ra) # 80003380 <bread>
    80003bea:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bec:	05850593          	add	a1,a0,88
    80003bf0:	40dc                	lw	a5,4(s1)
    80003bf2:	8bbd                	and	a5,a5,15
    80003bf4:	079a                	sll	a5,a5,0x6
    80003bf6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003bf8:	00059783          	lh	a5,0(a1)
    80003bfc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c00:	00259783          	lh	a5,2(a1)
    80003c04:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c08:	00459783          	lh	a5,4(a1)
    80003c0c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c10:	00659783          	lh	a5,6(a1)
    80003c14:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c18:	459c                	lw	a5,8(a1)
    80003c1a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c1c:	03400613          	li	a2,52
    80003c20:	05b1                	add	a1,a1,12
    80003c22:	05048513          	add	a0,s1,80
    80003c26:	ffffd097          	auipc	ra,0xffffd
    80003c2a:	104080e7          	jalr	260(ra) # 80000d2a <memmove>
    brelse(bp);
    80003c2e:	854a                	mv	a0,s2
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	880080e7          	jalr	-1920(ra) # 800034b0 <brelse>
    ip->valid = 1;
    80003c38:	4785                	li	a5,1
    80003c3a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c3c:	04449783          	lh	a5,68(s1)
    80003c40:	fbb5                	bnez	a5,80003bb4 <ilock+0x24>
      panic("ilock: no type");
    80003c42:	00005517          	auipc	a0,0x5
    80003c46:	a1e50513          	add	a0,a0,-1506 # 80008660 <syscalls+0x1a8>
    80003c4a:	ffffd097          	auipc	ra,0xffffd
    80003c4e:	8f2080e7          	jalr	-1806(ra) # 8000053c <panic>

0000000080003c52 <iunlock>:
{
    80003c52:	1101                	add	sp,sp,-32
    80003c54:	ec06                	sd	ra,24(sp)
    80003c56:	e822                	sd	s0,16(sp)
    80003c58:	e426                	sd	s1,8(sp)
    80003c5a:	e04a                	sd	s2,0(sp)
    80003c5c:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c5e:	c905                	beqz	a0,80003c8e <iunlock+0x3c>
    80003c60:	84aa                	mv	s1,a0
    80003c62:	01050913          	add	s2,a0,16
    80003c66:	854a                	mv	a0,s2
    80003c68:	00001097          	auipc	ra,0x1
    80003c6c:	c58080e7          	jalr	-936(ra) # 800048c0 <holdingsleep>
    80003c70:	cd19                	beqz	a0,80003c8e <iunlock+0x3c>
    80003c72:	449c                	lw	a5,8(s1)
    80003c74:	00f05d63          	blez	a5,80003c8e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c78:	854a                	mv	a0,s2
    80003c7a:	00001097          	auipc	ra,0x1
    80003c7e:	c02080e7          	jalr	-1022(ra) # 8000487c <releasesleep>
}
    80003c82:	60e2                	ld	ra,24(sp)
    80003c84:	6442                	ld	s0,16(sp)
    80003c86:	64a2                	ld	s1,8(sp)
    80003c88:	6902                	ld	s2,0(sp)
    80003c8a:	6105                	add	sp,sp,32
    80003c8c:	8082                	ret
    panic("iunlock");
    80003c8e:	00005517          	auipc	a0,0x5
    80003c92:	9e250513          	add	a0,a0,-1566 # 80008670 <syscalls+0x1b8>
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	8a6080e7          	jalr	-1882(ra) # 8000053c <panic>

0000000080003c9e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c9e:	7179                	add	sp,sp,-48
    80003ca0:	f406                	sd	ra,40(sp)
    80003ca2:	f022                	sd	s0,32(sp)
    80003ca4:	ec26                	sd	s1,24(sp)
    80003ca6:	e84a                	sd	s2,16(sp)
    80003ca8:	e44e                	sd	s3,8(sp)
    80003caa:	e052                	sd	s4,0(sp)
    80003cac:	1800                	add	s0,sp,48
    80003cae:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cb0:	05050493          	add	s1,a0,80
    80003cb4:	08050913          	add	s2,a0,128
    80003cb8:	a021                	j	80003cc0 <itrunc+0x22>
    80003cba:	0491                	add	s1,s1,4
    80003cbc:	01248d63          	beq	s1,s2,80003cd6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003cc0:	408c                	lw	a1,0(s1)
    80003cc2:	dde5                	beqz	a1,80003cba <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cc4:	0009a503          	lw	a0,0(s3)
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	8fc080e7          	jalr	-1796(ra) # 800035c4 <bfree>
      ip->addrs[i] = 0;
    80003cd0:	0004a023          	sw	zero,0(s1)
    80003cd4:	b7dd                	j	80003cba <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cd6:	0809a583          	lw	a1,128(s3)
    80003cda:	e185                	bnez	a1,80003cfa <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cdc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ce0:	854e                	mv	a0,s3
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	de2080e7          	jalr	-542(ra) # 80003ac4 <iupdate>
}
    80003cea:	70a2                	ld	ra,40(sp)
    80003cec:	7402                	ld	s0,32(sp)
    80003cee:	64e2                	ld	s1,24(sp)
    80003cf0:	6942                	ld	s2,16(sp)
    80003cf2:	69a2                	ld	s3,8(sp)
    80003cf4:	6a02                	ld	s4,0(sp)
    80003cf6:	6145                	add	sp,sp,48
    80003cf8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cfa:	0009a503          	lw	a0,0(s3)
    80003cfe:	fffff097          	auipc	ra,0xfffff
    80003d02:	682080e7          	jalr	1666(ra) # 80003380 <bread>
    80003d06:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d08:	05850493          	add	s1,a0,88
    80003d0c:	45850913          	add	s2,a0,1112
    80003d10:	a021                	j	80003d18 <itrunc+0x7a>
    80003d12:	0491                	add	s1,s1,4
    80003d14:	01248b63          	beq	s1,s2,80003d2a <itrunc+0x8c>
      if(a[j])
    80003d18:	408c                	lw	a1,0(s1)
    80003d1a:	dde5                	beqz	a1,80003d12 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d1c:	0009a503          	lw	a0,0(s3)
    80003d20:	00000097          	auipc	ra,0x0
    80003d24:	8a4080e7          	jalr	-1884(ra) # 800035c4 <bfree>
    80003d28:	b7ed                	j	80003d12 <itrunc+0x74>
    brelse(bp);
    80003d2a:	8552                	mv	a0,s4
    80003d2c:	fffff097          	auipc	ra,0xfffff
    80003d30:	784080e7          	jalr	1924(ra) # 800034b0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d34:	0809a583          	lw	a1,128(s3)
    80003d38:	0009a503          	lw	a0,0(s3)
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	888080e7          	jalr	-1912(ra) # 800035c4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d44:	0809a023          	sw	zero,128(s3)
    80003d48:	bf51                	j	80003cdc <itrunc+0x3e>

0000000080003d4a <iput>:
{
    80003d4a:	1101                	add	sp,sp,-32
    80003d4c:	ec06                	sd	ra,24(sp)
    80003d4e:	e822                	sd	s0,16(sp)
    80003d50:	e426                	sd	s1,8(sp)
    80003d52:	e04a                	sd	s2,0(sp)
    80003d54:	1000                	add	s0,sp,32
    80003d56:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d58:	0001b517          	auipc	a0,0x1b
    80003d5c:	7a050513          	add	a0,a0,1952 # 8001f4f8 <itable>
    80003d60:	ffffd097          	auipc	ra,0xffffd
    80003d64:	e72080e7          	jalr	-398(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d68:	4498                	lw	a4,8(s1)
    80003d6a:	4785                	li	a5,1
    80003d6c:	02f70363          	beq	a4,a5,80003d92 <iput+0x48>
  ip->ref--;
    80003d70:	449c                	lw	a5,8(s1)
    80003d72:	37fd                	addw	a5,a5,-1
    80003d74:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d76:	0001b517          	auipc	a0,0x1b
    80003d7a:	78250513          	add	a0,a0,1922 # 8001f4f8 <itable>
    80003d7e:	ffffd097          	auipc	ra,0xffffd
    80003d82:	f08080e7          	jalr	-248(ra) # 80000c86 <release>
}
    80003d86:	60e2                	ld	ra,24(sp)
    80003d88:	6442                	ld	s0,16(sp)
    80003d8a:	64a2                	ld	s1,8(sp)
    80003d8c:	6902                	ld	s2,0(sp)
    80003d8e:	6105                	add	sp,sp,32
    80003d90:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d92:	40bc                	lw	a5,64(s1)
    80003d94:	dff1                	beqz	a5,80003d70 <iput+0x26>
    80003d96:	04a49783          	lh	a5,74(s1)
    80003d9a:	fbf9                	bnez	a5,80003d70 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d9c:	01048913          	add	s2,s1,16
    80003da0:	854a                	mv	a0,s2
    80003da2:	00001097          	auipc	ra,0x1
    80003da6:	a84080e7          	jalr	-1404(ra) # 80004826 <acquiresleep>
    release(&itable.lock);
    80003daa:	0001b517          	auipc	a0,0x1b
    80003dae:	74e50513          	add	a0,a0,1870 # 8001f4f8 <itable>
    80003db2:	ffffd097          	auipc	ra,0xffffd
    80003db6:	ed4080e7          	jalr	-300(ra) # 80000c86 <release>
    itrunc(ip);
    80003dba:	8526                	mv	a0,s1
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	ee2080e7          	jalr	-286(ra) # 80003c9e <itrunc>
    ip->type = 0;
    80003dc4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003dc8:	8526                	mv	a0,s1
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	cfa080e7          	jalr	-774(ra) # 80003ac4 <iupdate>
    ip->valid = 0;
    80003dd2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003dd6:	854a                	mv	a0,s2
    80003dd8:	00001097          	auipc	ra,0x1
    80003ddc:	aa4080e7          	jalr	-1372(ra) # 8000487c <releasesleep>
    acquire(&itable.lock);
    80003de0:	0001b517          	auipc	a0,0x1b
    80003de4:	71850513          	add	a0,a0,1816 # 8001f4f8 <itable>
    80003de8:	ffffd097          	auipc	ra,0xffffd
    80003dec:	dea080e7          	jalr	-534(ra) # 80000bd2 <acquire>
    80003df0:	b741                	j	80003d70 <iput+0x26>

0000000080003df2 <iunlockput>:
{
    80003df2:	1101                	add	sp,sp,-32
    80003df4:	ec06                	sd	ra,24(sp)
    80003df6:	e822                	sd	s0,16(sp)
    80003df8:	e426                	sd	s1,8(sp)
    80003dfa:	1000                	add	s0,sp,32
    80003dfc:	84aa                	mv	s1,a0
  iunlock(ip);
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	e54080e7          	jalr	-428(ra) # 80003c52 <iunlock>
  iput(ip);
    80003e06:	8526                	mv	a0,s1
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	f42080e7          	jalr	-190(ra) # 80003d4a <iput>
}
    80003e10:	60e2                	ld	ra,24(sp)
    80003e12:	6442                	ld	s0,16(sp)
    80003e14:	64a2                	ld	s1,8(sp)
    80003e16:	6105                	add	sp,sp,32
    80003e18:	8082                	ret

0000000080003e1a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e1a:	1141                	add	sp,sp,-16
    80003e1c:	e422                	sd	s0,8(sp)
    80003e1e:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003e20:	411c                	lw	a5,0(a0)
    80003e22:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e24:	415c                	lw	a5,4(a0)
    80003e26:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e28:	04451783          	lh	a5,68(a0)
    80003e2c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e30:	04a51783          	lh	a5,74(a0)
    80003e34:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e38:	04c56783          	lwu	a5,76(a0)
    80003e3c:	e99c                	sd	a5,16(a1)
}
    80003e3e:	6422                	ld	s0,8(sp)
    80003e40:	0141                	add	sp,sp,16
    80003e42:	8082                	ret

0000000080003e44 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e44:	457c                	lw	a5,76(a0)
    80003e46:	0ed7e963          	bltu	a5,a3,80003f38 <readi+0xf4>
{
    80003e4a:	7159                	add	sp,sp,-112
    80003e4c:	f486                	sd	ra,104(sp)
    80003e4e:	f0a2                	sd	s0,96(sp)
    80003e50:	eca6                	sd	s1,88(sp)
    80003e52:	e8ca                	sd	s2,80(sp)
    80003e54:	e4ce                	sd	s3,72(sp)
    80003e56:	e0d2                	sd	s4,64(sp)
    80003e58:	fc56                	sd	s5,56(sp)
    80003e5a:	f85a                	sd	s6,48(sp)
    80003e5c:	f45e                	sd	s7,40(sp)
    80003e5e:	f062                	sd	s8,32(sp)
    80003e60:	ec66                	sd	s9,24(sp)
    80003e62:	e86a                	sd	s10,16(sp)
    80003e64:	e46e                	sd	s11,8(sp)
    80003e66:	1880                	add	s0,sp,112
    80003e68:	8b2a                	mv	s6,a0
    80003e6a:	8bae                	mv	s7,a1
    80003e6c:	8a32                	mv	s4,a2
    80003e6e:	84b6                	mv	s1,a3
    80003e70:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003e72:	9f35                	addw	a4,a4,a3
    return 0;
    80003e74:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e76:	0ad76063          	bltu	a4,a3,80003f16 <readi+0xd2>
  if(off + n > ip->size)
    80003e7a:	00e7f463          	bgeu	a5,a4,80003e82 <readi+0x3e>
    n = ip->size - off;
    80003e7e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e82:	0a0a8963          	beqz	s5,80003f34 <readi+0xf0>
    80003e86:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e88:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e8c:	5c7d                	li	s8,-1
    80003e8e:	a82d                	j	80003ec8 <readi+0x84>
    80003e90:	020d1d93          	sll	s11,s10,0x20
    80003e94:	020ddd93          	srl	s11,s11,0x20
    80003e98:	05890613          	add	a2,s2,88
    80003e9c:	86ee                	mv	a3,s11
    80003e9e:	963a                	add	a2,a2,a4
    80003ea0:	85d2                	mv	a1,s4
    80003ea2:	855e                	mv	a0,s7
    80003ea4:	fffff097          	auipc	ra,0xfffff
    80003ea8:	816080e7          	jalr	-2026(ra) # 800026ba <either_copyout>
    80003eac:	05850d63          	beq	a0,s8,80003f06 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003eb0:	854a                	mv	a0,s2
    80003eb2:	fffff097          	auipc	ra,0xfffff
    80003eb6:	5fe080e7          	jalr	1534(ra) # 800034b0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eba:	013d09bb          	addw	s3,s10,s3
    80003ebe:	009d04bb          	addw	s1,s10,s1
    80003ec2:	9a6e                	add	s4,s4,s11
    80003ec4:	0559f763          	bgeu	s3,s5,80003f12 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ec8:	00a4d59b          	srlw	a1,s1,0xa
    80003ecc:	855a                	mv	a0,s6
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	8a4080e7          	jalr	-1884(ra) # 80003772 <bmap>
    80003ed6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003eda:	cd85                	beqz	a1,80003f12 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003edc:	000b2503          	lw	a0,0(s6)
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	4a0080e7          	jalr	1184(ra) # 80003380 <bread>
    80003ee8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eea:	3ff4f713          	and	a4,s1,1023
    80003eee:	40ec87bb          	subw	a5,s9,a4
    80003ef2:	413a86bb          	subw	a3,s5,s3
    80003ef6:	8d3e                	mv	s10,a5
    80003ef8:	2781                	sext.w	a5,a5
    80003efa:	0006861b          	sext.w	a2,a3
    80003efe:	f8f679e3          	bgeu	a2,a5,80003e90 <readi+0x4c>
    80003f02:	8d36                	mv	s10,a3
    80003f04:	b771                	j	80003e90 <readi+0x4c>
      brelse(bp);
    80003f06:	854a                	mv	a0,s2
    80003f08:	fffff097          	auipc	ra,0xfffff
    80003f0c:	5a8080e7          	jalr	1448(ra) # 800034b0 <brelse>
      tot = -1;
    80003f10:	59fd                	li	s3,-1
  }
  return tot;
    80003f12:	0009851b          	sext.w	a0,s3
}
    80003f16:	70a6                	ld	ra,104(sp)
    80003f18:	7406                	ld	s0,96(sp)
    80003f1a:	64e6                	ld	s1,88(sp)
    80003f1c:	6946                	ld	s2,80(sp)
    80003f1e:	69a6                	ld	s3,72(sp)
    80003f20:	6a06                	ld	s4,64(sp)
    80003f22:	7ae2                	ld	s5,56(sp)
    80003f24:	7b42                	ld	s6,48(sp)
    80003f26:	7ba2                	ld	s7,40(sp)
    80003f28:	7c02                	ld	s8,32(sp)
    80003f2a:	6ce2                	ld	s9,24(sp)
    80003f2c:	6d42                	ld	s10,16(sp)
    80003f2e:	6da2                	ld	s11,8(sp)
    80003f30:	6165                	add	sp,sp,112
    80003f32:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f34:	89d6                	mv	s3,s5
    80003f36:	bff1                	j	80003f12 <readi+0xce>
    return 0;
    80003f38:	4501                	li	a0,0
}
    80003f3a:	8082                	ret

0000000080003f3c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f3c:	457c                	lw	a5,76(a0)
    80003f3e:	10d7e863          	bltu	a5,a3,8000404e <writei+0x112>
{
    80003f42:	7159                	add	sp,sp,-112
    80003f44:	f486                	sd	ra,104(sp)
    80003f46:	f0a2                	sd	s0,96(sp)
    80003f48:	eca6                	sd	s1,88(sp)
    80003f4a:	e8ca                	sd	s2,80(sp)
    80003f4c:	e4ce                	sd	s3,72(sp)
    80003f4e:	e0d2                	sd	s4,64(sp)
    80003f50:	fc56                	sd	s5,56(sp)
    80003f52:	f85a                	sd	s6,48(sp)
    80003f54:	f45e                	sd	s7,40(sp)
    80003f56:	f062                	sd	s8,32(sp)
    80003f58:	ec66                	sd	s9,24(sp)
    80003f5a:	e86a                	sd	s10,16(sp)
    80003f5c:	e46e                	sd	s11,8(sp)
    80003f5e:	1880                	add	s0,sp,112
    80003f60:	8aaa                	mv	s5,a0
    80003f62:	8bae                	mv	s7,a1
    80003f64:	8a32                	mv	s4,a2
    80003f66:	8936                	mv	s2,a3
    80003f68:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f6a:	00e687bb          	addw	a5,a3,a4
    80003f6e:	0ed7e263          	bltu	a5,a3,80004052 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f72:	00043737          	lui	a4,0x43
    80003f76:	0ef76063          	bltu	a4,a5,80004056 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f7a:	0c0b0863          	beqz	s6,8000404a <writei+0x10e>
    80003f7e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f80:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f84:	5c7d                	li	s8,-1
    80003f86:	a091                	j	80003fca <writei+0x8e>
    80003f88:	020d1d93          	sll	s11,s10,0x20
    80003f8c:	020ddd93          	srl	s11,s11,0x20
    80003f90:	05848513          	add	a0,s1,88
    80003f94:	86ee                	mv	a3,s11
    80003f96:	8652                	mv	a2,s4
    80003f98:	85de                	mv	a1,s7
    80003f9a:	953a                	add	a0,a0,a4
    80003f9c:	ffffe097          	auipc	ra,0xffffe
    80003fa0:	774080e7          	jalr	1908(ra) # 80002710 <either_copyin>
    80003fa4:	07850263          	beq	a0,s8,80004008 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003fa8:	8526                	mv	a0,s1
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	75e080e7          	jalr	1886(ra) # 80004708 <log_write>
    brelse(bp);
    80003fb2:	8526                	mv	a0,s1
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	4fc080e7          	jalr	1276(ra) # 800034b0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fbc:	013d09bb          	addw	s3,s10,s3
    80003fc0:	012d093b          	addw	s2,s10,s2
    80003fc4:	9a6e                	add	s4,s4,s11
    80003fc6:	0569f663          	bgeu	s3,s6,80004012 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003fca:	00a9559b          	srlw	a1,s2,0xa
    80003fce:	8556                	mv	a0,s5
    80003fd0:	fffff097          	auipc	ra,0xfffff
    80003fd4:	7a2080e7          	jalr	1954(ra) # 80003772 <bmap>
    80003fd8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003fdc:	c99d                	beqz	a1,80004012 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003fde:	000aa503          	lw	a0,0(s5)
    80003fe2:	fffff097          	auipc	ra,0xfffff
    80003fe6:	39e080e7          	jalr	926(ra) # 80003380 <bread>
    80003fea:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fec:	3ff97713          	and	a4,s2,1023
    80003ff0:	40ec87bb          	subw	a5,s9,a4
    80003ff4:	413b06bb          	subw	a3,s6,s3
    80003ff8:	8d3e                	mv	s10,a5
    80003ffa:	2781                	sext.w	a5,a5
    80003ffc:	0006861b          	sext.w	a2,a3
    80004000:	f8f674e3          	bgeu	a2,a5,80003f88 <writei+0x4c>
    80004004:	8d36                	mv	s10,a3
    80004006:	b749                	j	80003f88 <writei+0x4c>
      brelse(bp);
    80004008:	8526                	mv	a0,s1
    8000400a:	fffff097          	auipc	ra,0xfffff
    8000400e:	4a6080e7          	jalr	1190(ra) # 800034b0 <brelse>
  }

  if(off > ip->size)
    80004012:	04caa783          	lw	a5,76(s5)
    80004016:	0127f463          	bgeu	a5,s2,8000401e <writei+0xe2>
    ip->size = off;
    8000401a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000401e:	8556                	mv	a0,s5
    80004020:	00000097          	auipc	ra,0x0
    80004024:	aa4080e7          	jalr	-1372(ra) # 80003ac4 <iupdate>

  return tot;
    80004028:	0009851b          	sext.w	a0,s3
}
    8000402c:	70a6                	ld	ra,104(sp)
    8000402e:	7406                	ld	s0,96(sp)
    80004030:	64e6                	ld	s1,88(sp)
    80004032:	6946                	ld	s2,80(sp)
    80004034:	69a6                	ld	s3,72(sp)
    80004036:	6a06                	ld	s4,64(sp)
    80004038:	7ae2                	ld	s5,56(sp)
    8000403a:	7b42                	ld	s6,48(sp)
    8000403c:	7ba2                	ld	s7,40(sp)
    8000403e:	7c02                	ld	s8,32(sp)
    80004040:	6ce2                	ld	s9,24(sp)
    80004042:	6d42                	ld	s10,16(sp)
    80004044:	6da2                	ld	s11,8(sp)
    80004046:	6165                	add	sp,sp,112
    80004048:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000404a:	89da                	mv	s3,s6
    8000404c:	bfc9                	j	8000401e <writei+0xe2>
    return -1;
    8000404e:	557d                	li	a0,-1
}
    80004050:	8082                	ret
    return -1;
    80004052:	557d                	li	a0,-1
    80004054:	bfe1                	j	8000402c <writei+0xf0>
    return -1;
    80004056:	557d                	li	a0,-1
    80004058:	bfd1                	j	8000402c <writei+0xf0>

000000008000405a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000405a:	1141                	add	sp,sp,-16
    8000405c:	e406                	sd	ra,8(sp)
    8000405e:	e022                	sd	s0,0(sp)
    80004060:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004062:	4639                	li	a2,14
    80004064:	ffffd097          	auipc	ra,0xffffd
    80004068:	d3a080e7          	jalr	-710(ra) # 80000d9e <strncmp>
}
    8000406c:	60a2                	ld	ra,8(sp)
    8000406e:	6402                	ld	s0,0(sp)
    80004070:	0141                	add	sp,sp,16
    80004072:	8082                	ret

0000000080004074 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004074:	7139                	add	sp,sp,-64
    80004076:	fc06                	sd	ra,56(sp)
    80004078:	f822                	sd	s0,48(sp)
    8000407a:	f426                	sd	s1,40(sp)
    8000407c:	f04a                	sd	s2,32(sp)
    8000407e:	ec4e                	sd	s3,24(sp)
    80004080:	e852                	sd	s4,16(sp)
    80004082:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004084:	04451703          	lh	a4,68(a0)
    80004088:	4785                	li	a5,1
    8000408a:	00f71a63          	bne	a4,a5,8000409e <dirlookup+0x2a>
    8000408e:	892a                	mv	s2,a0
    80004090:	89ae                	mv	s3,a1
    80004092:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004094:	457c                	lw	a5,76(a0)
    80004096:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004098:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000409a:	e79d                	bnez	a5,800040c8 <dirlookup+0x54>
    8000409c:	a8a5                	j	80004114 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000409e:	00004517          	auipc	a0,0x4
    800040a2:	5da50513          	add	a0,a0,1498 # 80008678 <syscalls+0x1c0>
    800040a6:	ffffc097          	auipc	ra,0xffffc
    800040aa:	496080e7          	jalr	1174(ra) # 8000053c <panic>
      panic("dirlookup read");
    800040ae:	00004517          	auipc	a0,0x4
    800040b2:	5e250513          	add	a0,a0,1506 # 80008690 <syscalls+0x1d8>
    800040b6:	ffffc097          	auipc	ra,0xffffc
    800040ba:	486080e7          	jalr	1158(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040be:	24c1                	addw	s1,s1,16
    800040c0:	04c92783          	lw	a5,76(s2)
    800040c4:	04f4f763          	bgeu	s1,a5,80004112 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040c8:	4741                	li	a4,16
    800040ca:	86a6                	mv	a3,s1
    800040cc:	fc040613          	add	a2,s0,-64
    800040d0:	4581                	li	a1,0
    800040d2:	854a                	mv	a0,s2
    800040d4:	00000097          	auipc	ra,0x0
    800040d8:	d70080e7          	jalr	-656(ra) # 80003e44 <readi>
    800040dc:	47c1                	li	a5,16
    800040de:	fcf518e3          	bne	a0,a5,800040ae <dirlookup+0x3a>
    if(de.inum == 0)
    800040e2:	fc045783          	lhu	a5,-64(s0)
    800040e6:	dfe1                	beqz	a5,800040be <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040e8:	fc240593          	add	a1,s0,-62
    800040ec:	854e                	mv	a0,s3
    800040ee:	00000097          	auipc	ra,0x0
    800040f2:	f6c080e7          	jalr	-148(ra) # 8000405a <namecmp>
    800040f6:	f561                	bnez	a0,800040be <dirlookup+0x4a>
      if(poff)
    800040f8:	000a0463          	beqz	s4,80004100 <dirlookup+0x8c>
        *poff = off;
    800040fc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004100:	fc045583          	lhu	a1,-64(s0)
    80004104:	00092503          	lw	a0,0(s2)
    80004108:	fffff097          	auipc	ra,0xfffff
    8000410c:	754080e7          	jalr	1876(ra) # 8000385c <iget>
    80004110:	a011                	j	80004114 <dirlookup+0xa0>
  return 0;
    80004112:	4501                	li	a0,0
}
    80004114:	70e2                	ld	ra,56(sp)
    80004116:	7442                	ld	s0,48(sp)
    80004118:	74a2                	ld	s1,40(sp)
    8000411a:	7902                	ld	s2,32(sp)
    8000411c:	69e2                	ld	s3,24(sp)
    8000411e:	6a42                	ld	s4,16(sp)
    80004120:	6121                	add	sp,sp,64
    80004122:	8082                	ret

0000000080004124 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004124:	711d                	add	sp,sp,-96
    80004126:	ec86                	sd	ra,88(sp)
    80004128:	e8a2                	sd	s0,80(sp)
    8000412a:	e4a6                	sd	s1,72(sp)
    8000412c:	e0ca                	sd	s2,64(sp)
    8000412e:	fc4e                	sd	s3,56(sp)
    80004130:	f852                	sd	s4,48(sp)
    80004132:	f456                	sd	s5,40(sp)
    80004134:	f05a                	sd	s6,32(sp)
    80004136:	ec5e                	sd	s7,24(sp)
    80004138:	e862                	sd	s8,16(sp)
    8000413a:	e466                	sd	s9,8(sp)
    8000413c:	1080                	add	s0,sp,96
    8000413e:	84aa                	mv	s1,a0
    80004140:	8b2e                	mv	s6,a1
    80004142:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004144:	00054703          	lbu	a4,0(a0)
    80004148:	02f00793          	li	a5,47
    8000414c:	02f70263          	beq	a4,a5,80004170 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004150:	ffffe097          	auipc	ra,0xffffe
    80004154:	a0e080e7          	jalr	-1522(ra) # 80001b5e <myproc>
    80004158:	15053503          	ld	a0,336(a0)
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	9f6080e7          	jalr	-1546(ra) # 80003b52 <idup>
    80004164:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004166:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000416a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000416c:	4b85                	li	s7,1
    8000416e:	a875                	j	8000422a <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004170:	4585                	li	a1,1
    80004172:	4505                	li	a0,1
    80004174:	fffff097          	auipc	ra,0xfffff
    80004178:	6e8080e7          	jalr	1768(ra) # 8000385c <iget>
    8000417c:	8a2a                	mv	s4,a0
    8000417e:	b7e5                	j	80004166 <namex+0x42>
      iunlockput(ip);
    80004180:	8552                	mv	a0,s4
    80004182:	00000097          	auipc	ra,0x0
    80004186:	c70080e7          	jalr	-912(ra) # 80003df2 <iunlockput>
      return 0;
    8000418a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000418c:	8552                	mv	a0,s4
    8000418e:	60e6                	ld	ra,88(sp)
    80004190:	6446                	ld	s0,80(sp)
    80004192:	64a6                	ld	s1,72(sp)
    80004194:	6906                	ld	s2,64(sp)
    80004196:	79e2                	ld	s3,56(sp)
    80004198:	7a42                	ld	s4,48(sp)
    8000419a:	7aa2                	ld	s5,40(sp)
    8000419c:	7b02                	ld	s6,32(sp)
    8000419e:	6be2                	ld	s7,24(sp)
    800041a0:	6c42                	ld	s8,16(sp)
    800041a2:	6ca2                	ld	s9,8(sp)
    800041a4:	6125                	add	sp,sp,96
    800041a6:	8082                	ret
      iunlock(ip);
    800041a8:	8552                	mv	a0,s4
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	aa8080e7          	jalr	-1368(ra) # 80003c52 <iunlock>
      return ip;
    800041b2:	bfe9                	j	8000418c <namex+0x68>
      iunlockput(ip);
    800041b4:	8552                	mv	a0,s4
    800041b6:	00000097          	auipc	ra,0x0
    800041ba:	c3c080e7          	jalr	-964(ra) # 80003df2 <iunlockput>
      return 0;
    800041be:	8a4e                	mv	s4,s3
    800041c0:	b7f1                	j	8000418c <namex+0x68>
  len = path - s;
    800041c2:	40998633          	sub	a2,s3,s1
    800041c6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800041ca:	099c5863          	bge	s8,s9,8000425a <namex+0x136>
    memmove(name, s, DIRSIZ);
    800041ce:	4639                	li	a2,14
    800041d0:	85a6                	mv	a1,s1
    800041d2:	8556                	mv	a0,s5
    800041d4:	ffffd097          	auipc	ra,0xffffd
    800041d8:	b56080e7          	jalr	-1194(ra) # 80000d2a <memmove>
    800041dc:	84ce                	mv	s1,s3
  while(*path == '/')
    800041de:	0004c783          	lbu	a5,0(s1)
    800041e2:	01279763          	bne	a5,s2,800041f0 <namex+0xcc>
    path++;
    800041e6:	0485                	add	s1,s1,1
  while(*path == '/')
    800041e8:	0004c783          	lbu	a5,0(s1)
    800041ec:	ff278de3          	beq	a5,s2,800041e6 <namex+0xc2>
    ilock(ip);
    800041f0:	8552                	mv	a0,s4
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	99e080e7          	jalr	-1634(ra) # 80003b90 <ilock>
    if(ip->type != T_DIR){
    800041fa:	044a1783          	lh	a5,68(s4)
    800041fe:	f97791e3          	bne	a5,s7,80004180 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004202:	000b0563          	beqz	s6,8000420c <namex+0xe8>
    80004206:	0004c783          	lbu	a5,0(s1)
    8000420a:	dfd9                	beqz	a5,800041a8 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000420c:	4601                	li	a2,0
    8000420e:	85d6                	mv	a1,s5
    80004210:	8552                	mv	a0,s4
    80004212:	00000097          	auipc	ra,0x0
    80004216:	e62080e7          	jalr	-414(ra) # 80004074 <dirlookup>
    8000421a:	89aa                	mv	s3,a0
    8000421c:	dd41                	beqz	a0,800041b4 <namex+0x90>
    iunlockput(ip);
    8000421e:	8552                	mv	a0,s4
    80004220:	00000097          	auipc	ra,0x0
    80004224:	bd2080e7          	jalr	-1070(ra) # 80003df2 <iunlockput>
    ip = next;
    80004228:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000422a:	0004c783          	lbu	a5,0(s1)
    8000422e:	01279763          	bne	a5,s2,8000423c <namex+0x118>
    path++;
    80004232:	0485                	add	s1,s1,1
  while(*path == '/')
    80004234:	0004c783          	lbu	a5,0(s1)
    80004238:	ff278de3          	beq	a5,s2,80004232 <namex+0x10e>
  if(*path == 0)
    8000423c:	cb9d                	beqz	a5,80004272 <namex+0x14e>
  while(*path != '/' && *path != 0)
    8000423e:	0004c783          	lbu	a5,0(s1)
    80004242:	89a6                	mv	s3,s1
  len = path - s;
    80004244:	4c81                	li	s9,0
    80004246:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004248:	01278963          	beq	a5,s2,8000425a <namex+0x136>
    8000424c:	dbbd                	beqz	a5,800041c2 <namex+0x9e>
    path++;
    8000424e:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80004250:	0009c783          	lbu	a5,0(s3)
    80004254:	ff279ce3          	bne	a5,s2,8000424c <namex+0x128>
    80004258:	b7ad                	j	800041c2 <namex+0x9e>
    memmove(name, s, len);
    8000425a:	2601                	sext.w	a2,a2
    8000425c:	85a6                	mv	a1,s1
    8000425e:	8556                	mv	a0,s5
    80004260:	ffffd097          	auipc	ra,0xffffd
    80004264:	aca080e7          	jalr	-1334(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004268:	9cd6                	add	s9,s9,s5
    8000426a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000426e:	84ce                	mv	s1,s3
    80004270:	b7bd                	j	800041de <namex+0xba>
  if(nameiparent){
    80004272:	f00b0de3          	beqz	s6,8000418c <namex+0x68>
    iput(ip);
    80004276:	8552                	mv	a0,s4
    80004278:	00000097          	auipc	ra,0x0
    8000427c:	ad2080e7          	jalr	-1326(ra) # 80003d4a <iput>
    return 0;
    80004280:	4a01                	li	s4,0
    80004282:	b729                	j	8000418c <namex+0x68>

0000000080004284 <dirlink>:
{
    80004284:	7139                	add	sp,sp,-64
    80004286:	fc06                	sd	ra,56(sp)
    80004288:	f822                	sd	s0,48(sp)
    8000428a:	f426                	sd	s1,40(sp)
    8000428c:	f04a                	sd	s2,32(sp)
    8000428e:	ec4e                	sd	s3,24(sp)
    80004290:	e852                	sd	s4,16(sp)
    80004292:	0080                	add	s0,sp,64
    80004294:	892a                	mv	s2,a0
    80004296:	8a2e                	mv	s4,a1
    80004298:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000429a:	4601                	li	a2,0
    8000429c:	00000097          	auipc	ra,0x0
    800042a0:	dd8080e7          	jalr	-552(ra) # 80004074 <dirlookup>
    800042a4:	e93d                	bnez	a0,8000431a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042a6:	04c92483          	lw	s1,76(s2)
    800042aa:	c49d                	beqz	s1,800042d8 <dirlink+0x54>
    800042ac:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ae:	4741                	li	a4,16
    800042b0:	86a6                	mv	a3,s1
    800042b2:	fc040613          	add	a2,s0,-64
    800042b6:	4581                	li	a1,0
    800042b8:	854a                	mv	a0,s2
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	b8a080e7          	jalr	-1142(ra) # 80003e44 <readi>
    800042c2:	47c1                	li	a5,16
    800042c4:	06f51163          	bne	a0,a5,80004326 <dirlink+0xa2>
    if(de.inum == 0)
    800042c8:	fc045783          	lhu	a5,-64(s0)
    800042cc:	c791                	beqz	a5,800042d8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ce:	24c1                	addw	s1,s1,16
    800042d0:	04c92783          	lw	a5,76(s2)
    800042d4:	fcf4ede3          	bltu	s1,a5,800042ae <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042d8:	4639                	li	a2,14
    800042da:	85d2                	mv	a1,s4
    800042dc:	fc240513          	add	a0,s0,-62
    800042e0:	ffffd097          	auipc	ra,0xffffd
    800042e4:	afa080e7          	jalr	-1286(ra) # 80000dda <strncpy>
  de.inum = inum;
    800042e8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ec:	4741                	li	a4,16
    800042ee:	86a6                	mv	a3,s1
    800042f0:	fc040613          	add	a2,s0,-64
    800042f4:	4581                	li	a1,0
    800042f6:	854a                	mv	a0,s2
    800042f8:	00000097          	auipc	ra,0x0
    800042fc:	c44080e7          	jalr	-956(ra) # 80003f3c <writei>
    80004300:	1541                	add	a0,a0,-16
    80004302:	00a03533          	snez	a0,a0
    80004306:	40a00533          	neg	a0,a0
}
    8000430a:	70e2                	ld	ra,56(sp)
    8000430c:	7442                	ld	s0,48(sp)
    8000430e:	74a2                	ld	s1,40(sp)
    80004310:	7902                	ld	s2,32(sp)
    80004312:	69e2                	ld	s3,24(sp)
    80004314:	6a42                	ld	s4,16(sp)
    80004316:	6121                	add	sp,sp,64
    80004318:	8082                	ret
    iput(ip);
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	a30080e7          	jalr	-1488(ra) # 80003d4a <iput>
    return -1;
    80004322:	557d                	li	a0,-1
    80004324:	b7dd                	j	8000430a <dirlink+0x86>
      panic("dirlink read");
    80004326:	00004517          	auipc	a0,0x4
    8000432a:	37a50513          	add	a0,a0,890 # 800086a0 <syscalls+0x1e8>
    8000432e:	ffffc097          	auipc	ra,0xffffc
    80004332:	20e080e7          	jalr	526(ra) # 8000053c <panic>

0000000080004336 <namei>:

struct inode*
namei(char *path)
{
    80004336:	1101                	add	sp,sp,-32
    80004338:	ec06                	sd	ra,24(sp)
    8000433a:	e822                	sd	s0,16(sp)
    8000433c:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000433e:	fe040613          	add	a2,s0,-32
    80004342:	4581                	li	a1,0
    80004344:	00000097          	auipc	ra,0x0
    80004348:	de0080e7          	jalr	-544(ra) # 80004124 <namex>
}
    8000434c:	60e2                	ld	ra,24(sp)
    8000434e:	6442                	ld	s0,16(sp)
    80004350:	6105                	add	sp,sp,32
    80004352:	8082                	ret

0000000080004354 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004354:	1141                	add	sp,sp,-16
    80004356:	e406                	sd	ra,8(sp)
    80004358:	e022                	sd	s0,0(sp)
    8000435a:	0800                	add	s0,sp,16
    8000435c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000435e:	4585                	li	a1,1
    80004360:	00000097          	auipc	ra,0x0
    80004364:	dc4080e7          	jalr	-572(ra) # 80004124 <namex>
}
    80004368:	60a2                	ld	ra,8(sp)
    8000436a:	6402                	ld	s0,0(sp)
    8000436c:	0141                	add	sp,sp,16
    8000436e:	8082                	ret

0000000080004370 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004370:	1101                	add	sp,sp,-32
    80004372:	ec06                	sd	ra,24(sp)
    80004374:	e822                	sd	s0,16(sp)
    80004376:	e426                	sd	s1,8(sp)
    80004378:	e04a                	sd	s2,0(sp)
    8000437a:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000437c:	0001d917          	auipc	s2,0x1d
    80004380:	c2490913          	add	s2,s2,-988 # 80020fa0 <log>
    80004384:	01892583          	lw	a1,24(s2)
    80004388:	02892503          	lw	a0,40(s2)
    8000438c:	fffff097          	auipc	ra,0xfffff
    80004390:	ff4080e7          	jalr	-12(ra) # 80003380 <bread>
    80004394:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004396:	02c92603          	lw	a2,44(s2)
    8000439a:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000439c:	00c05f63          	blez	a2,800043ba <write_head+0x4a>
    800043a0:	0001d717          	auipc	a4,0x1d
    800043a4:	c3070713          	add	a4,a4,-976 # 80020fd0 <log+0x30>
    800043a8:	87aa                	mv	a5,a0
    800043aa:	060a                	sll	a2,a2,0x2
    800043ac:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800043ae:	4314                	lw	a3,0(a4)
    800043b0:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800043b2:	0711                	add	a4,a4,4
    800043b4:	0791                	add	a5,a5,4
    800043b6:	fec79ce3          	bne	a5,a2,800043ae <write_head+0x3e>
  }
  bwrite(buf);
    800043ba:	8526                	mv	a0,s1
    800043bc:	fffff097          	auipc	ra,0xfffff
    800043c0:	0b6080e7          	jalr	182(ra) # 80003472 <bwrite>
  brelse(buf);
    800043c4:	8526                	mv	a0,s1
    800043c6:	fffff097          	auipc	ra,0xfffff
    800043ca:	0ea080e7          	jalr	234(ra) # 800034b0 <brelse>
}
    800043ce:	60e2                	ld	ra,24(sp)
    800043d0:	6442                	ld	s0,16(sp)
    800043d2:	64a2                	ld	s1,8(sp)
    800043d4:	6902                	ld	s2,0(sp)
    800043d6:	6105                	add	sp,sp,32
    800043d8:	8082                	ret

00000000800043da <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043da:	0001d797          	auipc	a5,0x1d
    800043de:	bf27a783          	lw	a5,-1038(a5) # 80020fcc <log+0x2c>
    800043e2:	0af05d63          	blez	a5,8000449c <install_trans+0xc2>
{
    800043e6:	7139                	add	sp,sp,-64
    800043e8:	fc06                	sd	ra,56(sp)
    800043ea:	f822                	sd	s0,48(sp)
    800043ec:	f426                	sd	s1,40(sp)
    800043ee:	f04a                	sd	s2,32(sp)
    800043f0:	ec4e                	sd	s3,24(sp)
    800043f2:	e852                	sd	s4,16(sp)
    800043f4:	e456                	sd	s5,8(sp)
    800043f6:	e05a                	sd	s6,0(sp)
    800043f8:	0080                	add	s0,sp,64
    800043fa:	8b2a                	mv	s6,a0
    800043fc:	0001da97          	auipc	s5,0x1d
    80004400:	bd4a8a93          	add	s5,s5,-1068 # 80020fd0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004404:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004406:	0001d997          	auipc	s3,0x1d
    8000440a:	b9a98993          	add	s3,s3,-1126 # 80020fa0 <log>
    8000440e:	a00d                	j	80004430 <install_trans+0x56>
    brelse(lbuf);
    80004410:	854a                	mv	a0,s2
    80004412:	fffff097          	auipc	ra,0xfffff
    80004416:	09e080e7          	jalr	158(ra) # 800034b0 <brelse>
    brelse(dbuf);
    8000441a:	8526                	mv	a0,s1
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	094080e7          	jalr	148(ra) # 800034b0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004424:	2a05                	addw	s4,s4,1
    80004426:	0a91                	add	s5,s5,4
    80004428:	02c9a783          	lw	a5,44(s3)
    8000442c:	04fa5e63          	bge	s4,a5,80004488 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004430:	0189a583          	lw	a1,24(s3)
    80004434:	014585bb          	addw	a1,a1,s4
    80004438:	2585                	addw	a1,a1,1
    8000443a:	0289a503          	lw	a0,40(s3)
    8000443e:	fffff097          	auipc	ra,0xfffff
    80004442:	f42080e7          	jalr	-190(ra) # 80003380 <bread>
    80004446:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004448:	000aa583          	lw	a1,0(s5)
    8000444c:	0289a503          	lw	a0,40(s3)
    80004450:	fffff097          	auipc	ra,0xfffff
    80004454:	f30080e7          	jalr	-208(ra) # 80003380 <bread>
    80004458:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000445a:	40000613          	li	a2,1024
    8000445e:	05890593          	add	a1,s2,88
    80004462:	05850513          	add	a0,a0,88
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	8c4080e7          	jalr	-1852(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    8000446e:	8526                	mv	a0,s1
    80004470:	fffff097          	auipc	ra,0xfffff
    80004474:	002080e7          	jalr	2(ra) # 80003472 <bwrite>
    if(recovering == 0)
    80004478:	f80b1ce3          	bnez	s6,80004410 <install_trans+0x36>
      bunpin(dbuf);
    8000447c:	8526                	mv	a0,s1
    8000447e:	fffff097          	auipc	ra,0xfffff
    80004482:	10a080e7          	jalr	266(ra) # 80003588 <bunpin>
    80004486:	b769                	j	80004410 <install_trans+0x36>
}
    80004488:	70e2                	ld	ra,56(sp)
    8000448a:	7442                	ld	s0,48(sp)
    8000448c:	74a2                	ld	s1,40(sp)
    8000448e:	7902                	ld	s2,32(sp)
    80004490:	69e2                	ld	s3,24(sp)
    80004492:	6a42                	ld	s4,16(sp)
    80004494:	6aa2                	ld	s5,8(sp)
    80004496:	6b02                	ld	s6,0(sp)
    80004498:	6121                	add	sp,sp,64
    8000449a:	8082                	ret
    8000449c:	8082                	ret

000000008000449e <initlog>:
{
    8000449e:	7179                	add	sp,sp,-48
    800044a0:	f406                	sd	ra,40(sp)
    800044a2:	f022                	sd	s0,32(sp)
    800044a4:	ec26                	sd	s1,24(sp)
    800044a6:	e84a                	sd	s2,16(sp)
    800044a8:	e44e                	sd	s3,8(sp)
    800044aa:	1800                	add	s0,sp,48
    800044ac:	892a                	mv	s2,a0
    800044ae:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044b0:	0001d497          	auipc	s1,0x1d
    800044b4:	af048493          	add	s1,s1,-1296 # 80020fa0 <log>
    800044b8:	00004597          	auipc	a1,0x4
    800044bc:	1f858593          	add	a1,a1,504 # 800086b0 <syscalls+0x1f8>
    800044c0:	8526                	mv	a0,s1
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	680080e7          	jalr	1664(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    800044ca:	0149a583          	lw	a1,20(s3)
    800044ce:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044d0:	0109a783          	lw	a5,16(s3)
    800044d4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044d6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044da:	854a                	mv	a0,s2
    800044dc:	fffff097          	auipc	ra,0xfffff
    800044e0:	ea4080e7          	jalr	-348(ra) # 80003380 <bread>
  log.lh.n = lh->n;
    800044e4:	4d30                	lw	a2,88(a0)
    800044e6:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044e8:	00c05f63          	blez	a2,80004506 <initlog+0x68>
    800044ec:	87aa                	mv	a5,a0
    800044ee:	0001d717          	auipc	a4,0x1d
    800044f2:	ae270713          	add	a4,a4,-1310 # 80020fd0 <log+0x30>
    800044f6:	060a                	sll	a2,a2,0x2
    800044f8:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800044fa:	4ff4                	lw	a3,92(a5)
    800044fc:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044fe:	0791                	add	a5,a5,4
    80004500:	0711                	add	a4,a4,4
    80004502:	fec79ce3          	bne	a5,a2,800044fa <initlog+0x5c>
  brelse(buf);
    80004506:	fffff097          	auipc	ra,0xfffff
    8000450a:	faa080e7          	jalr	-86(ra) # 800034b0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000450e:	4505                	li	a0,1
    80004510:	00000097          	auipc	ra,0x0
    80004514:	eca080e7          	jalr	-310(ra) # 800043da <install_trans>
  log.lh.n = 0;
    80004518:	0001d797          	auipc	a5,0x1d
    8000451c:	aa07aa23          	sw	zero,-1356(a5) # 80020fcc <log+0x2c>
  write_head(); // clear the log
    80004520:	00000097          	auipc	ra,0x0
    80004524:	e50080e7          	jalr	-432(ra) # 80004370 <write_head>
}
    80004528:	70a2                	ld	ra,40(sp)
    8000452a:	7402                	ld	s0,32(sp)
    8000452c:	64e2                	ld	s1,24(sp)
    8000452e:	6942                	ld	s2,16(sp)
    80004530:	69a2                	ld	s3,8(sp)
    80004532:	6145                	add	sp,sp,48
    80004534:	8082                	ret

0000000080004536 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004536:	1101                	add	sp,sp,-32
    80004538:	ec06                	sd	ra,24(sp)
    8000453a:	e822                	sd	s0,16(sp)
    8000453c:	e426                	sd	s1,8(sp)
    8000453e:	e04a                	sd	s2,0(sp)
    80004540:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004542:	0001d517          	auipc	a0,0x1d
    80004546:	a5e50513          	add	a0,a0,-1442 # 80020fa0 <log>
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	688080e7          	jalr	1672(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004552:	0001d497          	auipc	s1,0x1d
    80004556:	a4e48493          	add	s1,s1,-1458 # 80020fa0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000455a:	4979                	li	s2,30
    8000455c:	a039                	j	8000456a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000455e:	85a6                	mv	a1,s1
    80004560:	8526                	mv	a0,s1
    80004562:	ffffe097          	auipc	ra,0xffffe
    80004566:	d50080e7          	jalr	-688(ra) # 800022b2 <sleep>
    if(log.committing){
    8000456a:	50dc                	lw	a5,36(s1)
    8000456c:	fbed                	bnez	a5,8000455e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000456e:	5098                	lw	a4,32(s1)
    80004570:	2705                	addw	a4,a4,1
    80004572:	0027179b          	sllw	a5,a4,0x2
    80004576:	9fb9                	addw	a5,a5,a4
    80004578:	0017979b          	sllw	a5,a5,0x1
    8000457c:	54d4                	lw	a3,44(s1)
    8000457e:	9fb5                	addw	a5,a5,a3
    80004580:	00f95963          	bge	s2,a5,80004592 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004584:	85a6                	mv	a1,s1
    80004586:	8526                	mv	a0,s1
    80004588:	ffffe097          	auipc	ra,0xffffe
    8000458c:	d2a080e7          	jalr	-726(ra) # 800022b2 <sleep>
    80004590:	bfe9                	j	8000456a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004592:	0001d517          	auipc	a0,0x1d
    80004596:	a0e50513          	add	a0,a0,-1522 # 80020fa0 <log>
    8000459a:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	6ea080e7          	jalr	1770(ra) # 80000c86 <release>
      break;
    }
  }
}
    800045a4:	60e2                	ld	ra,24(sp)
    800045a6:	6442                	ld	s0,16(sp)
    800045a8:	64a2                	ld	s1,8(sp)
    800045aa:	6902                	ld	s2,0(sp)
    800045ac:	6105                	add	sp,sp,32
    800045ae:	8082                	ret

00000000800045b0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045b0:	7139                	add	sp,sp,-64
    800045b2:	fc06                	sd	ra,56(sp)
    800045b4:	f822                	sd	s0,48(sp)
    800045b6:	f426                	sd	s1,40(sp)
    800045b8:	f04a                	sd	s2,32(sp)
    800045ba:	ec4e                	sd	s3,24(sp)
    800045bc:	e852                	sd	s4,16(sp)
    800045be:	e456                	sd	s5,8(sp)
    800045c0:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045c2:	0001d497          	auipc	s1,0x1d
    800045c6:	9de48493          	add	s1,s1,-1570 # 80020fa0 <log>
    800045ca:	8526                	mv	a0,s1
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	606080e7          	jalr	1542(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    800045d4:	509c                	lw	a5,32(s1)
    800045d6:	37fd                	addw	a5,a5,-1
    800045d8:	0007891b          	sext.w	s2,a5
    800045dc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800045de:	50dc                	lw	a5,36(s1)
    800045e0:	e7b9                	bnez	a5,8000462e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045e2:	04091e63          	bnez	s2,8000463e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800045e6:	0001d497          	auipc	s1,0x1d
    800045ea:	9ba48493          	add	s1,s1,-1606 # 80020fa0 <log>
    800045ee:	4785                	li	a5,1
    800045f0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045f2:	8526                	mv	a0,s1
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	692080e7          	jalr	1682(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045fc:	54dc                	lw	a5,44(s1)
    800045fe:	06f04763          	bgtz	a5,8000466c <end_op+0xbc>
    acquire(&log.lock);
    80004602:	0001d497          	auipc	s1,0x1d
    80004606:	99e48493          	add	s1,s1,-1634 # 80020fa0 <log>
    8000460a:	8526                	mv	a0,s1
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	5c6080e7          	jalr	1478(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004614:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004618:	8526                	mv	a0,s1
    8000461a:	ffffe097          	auipc	ra,0xffffe
    8000461e:	cfc080e7          	jalr	-772(ra) # 80002316 <wakeup>
    release(&log.lock);
    80004622:	8526                	mv	a0,s1
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	662080e7          	jalr	1634(ra) # 80000c86 <release>
}
    8000462c:	a03d                	j	8000465a <end_op+0xaa>
    panic("log.committing");
    8000462e:	00004517          	auipc	a0,0x4
    80004632:	08a50513          	add	a0,a0,138 # 800086b8 <syscalls+0x200>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	f06080e7          	jalr	-250(ra) # 8000053c <panic>
    wakeup(&log);
    8000463e:	0001d497          	auipc	s1,0x1d
    80004642:	96248493          	add	s1,s1,-1694 # 80020fa0 <log>
    80004646:	8526                	mv	a0,s1
    80004648:	ffffe097          	auipc	ra,0xffffe
    8000464c:	cce080e7          	jalr	-818(ra) # 80002316 <wakeup>
  release(&log.lock);
    80004650:	8526                	mv	a0,s1
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	634080e7          	jalr	1588(ra) # 80000c86 <release>
}
    8000465a:	70e2                	ld	ra,56(sp)
    8000465c:	7442                	ld	s0,48(sp)
    8000465e:	74a2                	ld	s1,40(sp)
    80004660:	7902                	ld	s2,32(sp)
    80004662:	69e2                	ld	s3,24(sp)
    80004664:	6a42                	ld	s4,16(sp)
    80004666:	6aa2                	ld	s5,8(sp)
    80004668:	6121                	add	sp,sp,64
    8000466a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000466c:	0001da97          	auipc	s5,0x1d
    80004670:	964a8a93          	add	s5,s5,-1692 # 80020fd0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004674:	0001da17          	auipc	s4,0x1d
    80004678:	92ca0a13          	add	s4,s4,-1748 # 80020fa0 <log>
    8000467c:	018a2583          	lw	a1,24(s4)
    80004680:	012585bb          	addw	a1,a1,s2
    80004684:	2585                	addw	a1,a1,1
    80004686:	028a2503          	lw	a0,40(s4)
    8000468a:	fffff097          	auipc	ra,0xfffff
    8000468e:	cf6080e7          	jalr	-778(ra) # 80003380 <bread>
    80004692:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004694:	000aa583          	lw	a1,0(s5)
    80004698:	028a2503          	lw	a0,40(s4)
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	ce4080e7          	jalr	-796(ra) # 80003380 <bread>
    800046a4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046a6:	40000613          	li	a2,1024
    800046aa:	05850593          	add	a1,a0,88
    800046ae:	05848513          	add	a0,s1,88
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	678080e7          	jalr	1656(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    800046ba:	8526                	mv	a0,s1
    800046bc:	fffff097          	auipc	ra,0xfffff
    800046c0:	db6080e7          	jalr	-586(ra) # 80003472 <bwrite>
    brelse(from);
    800046c4:	854e                	mv	a0,s3
    800046c6:	fffff097          	auipc	ra,0xfffff
    800046ca:	dea080e7          	jalr	-534(ra) # 800034b0 <brelse>
    brelse(to);
    800046ce:	8526                	mv	a0,s1
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	de0080e7          	jalr	-544(ra) # 800034b0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046d8:	2905                	addw	s2,s2,1
    800046da:	0a91                	add	s5,s5,4
    800046dc:	02ca2783          	lw	a5,44(s4)
    800046e0:	f8f94ee3          	blt	s2,a5,8000467c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800046e4:	00000097          	auipc	ra,0x0
    800046e8:	c8c080e7          	jalr	-884(ra) # 80004370 <write_head>
    install_trans(0); // Now install writes to home locations
    800046ec:	4501                	li	a0,0
    800046ee:	00000097          	auipc	ra,0x0
    800046f2:	cec080e7          	jalr	-788(ra) # 800043da <install_trans>
    log.lh.n = 0;
    800046f6:	0001d797          	auipc	a5,0x1d
    800046fa:	8c07ab23          	sw	zero,-1834(a5) # 80020fcc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800046fe:	00000097          	auipc	ra,0x0
    80004702:	c72080e7          	jalr	-910(ra) # 80004370 <write_head>
    80004706:	bdf5                	j	80004602 <end_op+0x52>

0000000080004708 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004708:	1101                	add	sp,sp,-32
    8000470a:	ec06                	sd	ra,24(sp)
    8000470c:	e822                	sd	s0,16(sp)
    8000470e:	e426                	sd	s1,8(sp)
    80004710:	e04a                	sd	s2,0(sp)
    80004712:	1000                	add	s0,sp,32
    80004714:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004716:	0001d917          	auipc	s2,0x1d
    8000471a:	88a90913          	add	s2,s2,-1910 # 80020fa0 <log>
    8000471e:	854a                	mv	a0,s2
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	4b2080e7          	jalr	1202(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004728:	02c92603          	lw	a2,44(s2)
    8000472c:	47f5                	li	a5,29
    8000472e:	06c7c563          	blt	a5,a2,80004798 <log_write+0x90>
    80004732:	0001d797          	auipc	a5,0x1d
    80004736:	88a7a783          	lw	a5,-1910(a5) # 80020fbc <log+0x1c>
    8000473a:	37fd                	addw	a5,a5,-1
    8000473c:	04f65e63          	bge	a2,a5,80004798 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004740:	0001d797          	auipc	a5,0x1d
    80004744:	8807a783          	lw	a5,-1920(a5) # 80020fc0 <log+0x20>
    80004748:	06f05063          	blez	a5,800047a8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000474c:	4781                	li	a5,0
    8000474e:	06c05563          	blez	a2,800047b8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004752:	44cc                	lw	a1,12(s1)
    80004754:	0001d717          	auipc	a4,0x1d
    80004758:	87c70713          	add	a4,a4,-1924 # 80020fd0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000475c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000475e:	4314                	lw	a3,0(a4)
    80004760:	04b68c63          	beq	a3,a1,800047b8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004764:	2785                	addw	a5,a5,1
    80004766:	0711                	add	a4,a4,4
    80004768:	fef61be3          	bne	a2,a5,8000475e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000476c:	0621                	add	a2,a2,8
    8000476e:	060a                	sll	a2,a2,0x2
    80004770:	0001d797          	auipc	a5,0x1d
    80004774:	83078793          	add	a5,a5,-2000 # 80020fa0 <log>
    80004778:	97b2                	add	a5,a5,a2
    8000477a:	44d8                	lw	a4,12(s1)
    8000477c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000477e:	8526                	mv	a0,s1
    80004780:	fffff097          	auipc	ra,0xfffff
    80004784:	dcc080e7          	jalr	-564(ra) # 8000354c <bpin>
    log.lh.n++;
    80004788:	0001d717          	auipc	a4,0x1d
    8000478c:	81870713          	add	a4,a4,-2024 # 80020fa0 <log>
    80004790:	575c                	lw	a5,44(a4)
    80004792:	2785                	addw	a5,a5,1
    80004794:	d75c                	sw	a5,44(a4)
    80004796:	a82d                	j	800047d0 <log_write+0xc8>
    panic("too big a transaction");
    80004798:	00004517          	auipc	a0,0x4
    8000479c:	f3050513          	add	a0,a0,-208 # 800086c8 <syscalls+0x210>
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	d9c080e7          	jalr	-612(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    800047a8:	00004517          	auipc	a0,0x4
    800047ac:	f3850513          	add	a0,a0,-200 # 800086e0 <syscalls+0x228>
    800047b0:	ffffc097          	auipc	ra,0xffffc
    800047b4:	d8c080e7          	jalr	-628(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800047b8:	00878693          	add	a3,a5,8
    800047bc:	068a                	sll	a3,a3,0x2
    800047be:	0001c717          	auipc	a4,0x1c
    800047c2:	7e270713          	add	a4,a4,2018 # 80020fa0 <log>
    800047c6:	9736                	add	a4,a4,a3
    800047c8:	44d4                	lw	a3,12(s1)
    800047ca:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047cc:	faf609e3          	beq	a2,a5,8000477e <log_write+0x76>
  }
  release(&log.lock);
    800047d0:	0001c517          	auipc	a0,0x1c
    800047d4:	7d050513          	add	a0,a0,2000 # 80020fa0 <log>
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	4ae080e7          	jalr	1198(ra) # 80000c86 <release>
}
    800047e0:	60e2                	ld	ra,24(sp)
    800047e2:	6442                	ld	s0,16(sp)
    800047e4:	64a2                	ld	s1,8(sp)
    800047e6:	6902                	ld	s2,0(sp)
    800047e8:	6105                	add	sp,sp,32
    800047ea:	8082                	ret

00000000800047ec <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047ec:	1101                	add	sp,sp,-32
    800047ee:	ec06                	sd	ra,24(sp)
    800047f0:	e822                	sd	s0,16(sp)
    800047f2:	e426                	sd	s1,8(sp)
    800047f4:	e04a                	sd	s2,0(sp)
    800047f6:	1000                	add	s0,sp,32
    800047f8:	84aa                	mv	s1,a0
    800047fa:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047fc:	00004597          	auipc	a1,0x4
    80004800:	f0458593          	add	a1,a1,-252 # 80008700 <syscalls+0x248>
    80004804:	0521                	add	a0,a0,8
    80004806:	ffffc097          	auipc	ra,0xffffc
    8000480a:	33c080e7          	jalr	828(ra) # 80000b42 <initlock>
  lk->name = name;
    8000480e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004812:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004816:	0204a423          	sw	zero,40(s1)
}
    8000481a:	60e2                	ld	ra,24(sp)
    8000481c:	6442                	ld	s0,16(sp)
    8000481e:	64a2                	ld	s1,8(sp)
    80004820:	6902                	ld	s2,0(sp)
    80004822:	6105                	add	sp,sp,32
    80004824:	8082                	ret

0000000080004826 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004826:	1101                	add	sp,sp,-32
    80004828:	ec06                	sd	ra,24(sp)
    8000482a:	e822                	sd	s0,16(sp)
    8000482c:	e426                	sd	s1,8(sp)
    8000482e:	e04a                	sd	s2,0(sp)
    80004830:	1000                	add	s0,sp,32
    80004832:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004834:	00850913          	add	s2,a0,8
    80004838:	854a                	mv	a0,s2
    8000483a:	ffffc097          	auipc	ra,0xffffc
    8000483e:	398080e7          	jalr	920(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004842:	409c                	lw	a5,0(s1)
    80004844:	cb89                	beqz	a5,80004856 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004846:	85ca                	mv	a1,s2
    80004848:	8526                	mv	a0,s1
    8000484a:	ffffe097          	auipc	ra,0xffffe
    8000484e:	a68080e7          	jalr	-1432(ra) # 800022b2 <sleep>
  while (lk->locked) {
    80004852:	409c                	lw	a5,0(s1)
    80004854:	fbed                	bnez	a5,80004846 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004856:	4785                	li	a5,1
    80004858:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000485a:	ffffd097          	auipc	ra,0xffffd
    8000485e:	304080e7          	jalr	772(ra) # 80001b5e <myproc>
    80004862:	591c                	lw	a5,48(a0)
    80004864:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004866:	854a                	mv	a0,s2
    80004868:	ffffc097          	auipc	ra,0xffffc
    8000486c:	41e080e7          	jalr	1054(ra) # 80000c86 <release>
}
    80004870:	60e2                	ld	ra,24(sp)
    80004872:	6442                	ld	s0,16(sp)
    80004874:	64a2                	ld	s1,8(sp)
    80004876:	6902                	ld	s2,0(sp)
    80004878:	6105                	add	sp,sp,32
    8000487a:	8082                	ret

000000008000487c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000487c:	1101                	add	sp,sp,-32
    8000487e:	ec06                	sd	ra,24(sp)
    80004880:	e822                	sd	s0,16(sp)
    80004882:	e426                	sd	s1,8(sp)
    80004884:	e04a                	sd	s2,0(sp)
    80004886:	1000                	add	s0,sp,32
    80004888:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000488a:	00850913          	add	s2,a0,8
    8000488e:	854a                	mv	a0,s2
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	342080e7          	jalr	834(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004898:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000489c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048a0:	8526                	mv	a0,s1
    800048a2:	ffffe097          	auipc	ra,0xffffe
    800048a6:	a74080e7          	jalr	-1420(ra) # 80002316 <wakeup>
  release(&lk->lk);
    800048aa:	854a                	mv	a0,s2
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	3da080e7          	jalr	986(ra) # 80000c86 <release>
}
    800048b4:	60e2                	ld	ra,24(sp)
    800048b6:	6442                	ld	s0,16(sp)
    800048b8:	64a2                	ld	s1,8(sp)
    800048ba:	6902                	ld	s2,0(sp)
    800048bc:	6105                	add	sp,sp,32
    800048be:	8082                	ret

00000000800048c0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048c0:	7179                	add	sp,sp,-48
    800048c2:	f406                	sd	ra,40(sp)
    800048c4:	f022                	sd	s0,32(sp)
    800048c6:	ec26                	sd	s1,24(sp)
    800048c8:	e84a                	sd	s2,16(sp)
    800048ca:	e44e                	sd	s3,8(sp)
    800048cc:	1800                	add	s0,sp,48
    800048ce:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048d0:	00850913          	add	s2,a0,8
    800048d4:	854a                	mv	a0,s2
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	2fc080e7          	jalr	764(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800048de:	409c                	lw	a5,0(s1)
    800048e0:	ef99                	bnez	a5,800048fe <holdingsleep+0x3e>
    800048e2:	4481                	li	s1,0
  release(&lk->lk);
    800048e4:	854a                	mv	a0,s2
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	3a0080e7          	jalr	928(ra) # 80000c86 <release>
  return r;
}
    800048ee:	8526                	mv	a0,s1
    800048f0:	70a2                	ld	ra,40(sp)
    800048f2:	7402                	ld	s0,32(sp)
    800048f4:	64e2                	ld	s1,24(sp)
    800048f6:	6942                	ld	s2,16(sp)
    800048f8:	69a2                	ld	s3,8(sp)
    800048fa:	6145                	add	sp,sp,48
    800048fc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048fe:	0284a983          	lw	s3,40(s1)
    80004902:	ffffd097          	auipc	ra,0xffffd
    80004906:	25c080e7          	jalr	604(ra) # 80001b5e <myproc>
    8000490a:	5904                	lw	s1,48(a0)
    8000490c:	413484b3          	sub	s1,s1,s3
    80004910:	0014b493          	seqz	s1,s1
    80004914:	bfc1                	j	800048e4 <holdingsleep+0x24>

0000000080004916 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004916:	1141                	add	sp,sp,-16
    80004918:	e406                	sd	ra,8(sp)
    8000491a:	e022                	sd	s0,0(sp)
    8000491c:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000491e:	00004597          	auipc	a1,0x4
    80004922:	df258593          	add	a1,a1,-526 # 80008710 <syscalls+0x258>
    80004926:	0001c517          	auipc	a0,0x1c
    8000492a:	7c250513          	add	a0,a0,1986 # 800210e8 <ftable>
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	214080e7          	jalr	532(ra) # 80000b42 <initlock>
}
    80004936:	60a2                	ld	ra,8(sp)
    80004938:	6402                	ld	s0,0(sp)
    8000493a:	0141                	add	sp,sp,16
    8000493c:	8082                	ret

000000008000493e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000493e:	1101                	add	sp,sp,-32
    80004940:	ec06                	sd	ra,24(sp)
    80004942:	e822                	sd	s0,16(sp)
    80004944:	e426                	sd	s1,8(sp)
    80004946:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004948:	0001c517          	auipc	a0,0x1c
    8000494c:	7a050513          	add	a0,a0,1952 # 800210e8 <ftable>
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	282080e7          	jalr	642(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004958:	0001c497          	auipc	s1,0x1c
    8000495c:	7a848493          	add	s1,s1,1960 # 80021100 <ftable+0x18>
    80004960:	0001d717          	auipc	a4,0x1d
    80004964:	74070713          	add	a4,a4,1856 # 800220a0 <disk>
    if(f->ref == 0){
    80004968:	40dc                	lw	a5,4(s1)
    8000496a:	cf99                	beqz	a5,80004988 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000496c:	02848493          	add	s1,s1,40
    80004970:	fee49ce3          	bne	s1,a4,80004968 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004974:	0001c517          	auipc	a0,0x1c
    80004978:	77450513          	add	a0,a0,1908 # 800210e8 <ftable>
    8000497c:	ffffc097          	auipc	ra,0xffffc
    80004980:	30a080e7          	jalr	778(ra) # 80000c86 <release>
  return 0;
    80004984:	4481                	li	s1,0
    80004986:	a819                	j	8000499c <filealloc+0x5e>
      f->ref = 1;
    80004988:	4785                	li	a5,1
    8000498a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000498c:	0001c517          	auipc	a0,0x1c
    80004990:	75c50513          	add	a0,a0,1884 # 800210e8 <ftable>
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	2f2080e7          	jalr	754(ra) # 80000c86 <release>
}
    8000499c:	8526                	mv	a0,s1
    8000499e:	60e2                	ld	ra,24(sp)
    800049a0:	6442                	ld	s0,16(sp)
    800049a2:	64a2                	ld	s1,8(sp)
    800049a4:	6105                	add	sp,sp,32
    800049a6:	8082                	ret

00000000800049a8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049a8:	1101                	add	sp,sp,-32
    800049aa:	ec06                	sd	ra,24(sp)
    800049ac:	e822                	sd	s0,16(sp)
    800049ae:	e426                	sd	s1,8(sp)
    800049b0:	1000                	add	s0,sp,32
    800049b2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049b4:	0001c517          	auipc	a0,0x1c
    800049b8:	73450513          	add	a0,a0,1844 # 800210e8 <ftable>
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	216080e7          	jalr	534(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800049c4:	40dc                	lw	a5,4(s1)
    800049c6:	02f05263          	blez	a5,800049ea <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049ca:	2785                	addw	a5,a5,1
    800049cc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049ce:	0001c517          	auipc	a0,0x1c
    800049d2:	71a50513          	add	a0,a0,1818 # 800210e8 <ftable>
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	2b0080e7          	jalr	688(ra) # 80000c86 <release>
  return f;
}
    800049de:	8526                	mv	a0,s1
    800049e0:	60e2                	ld	ra,24(sp)
    800049e2:	6442                	ld	s0,16(sp)
    800049e4:	64a2                	ld	s1,8(sp)
    800049e6:	6105                	add	sp,sp,32
    800049e8:	8082                	ret
    panic("filedup");
    800049ea:	00004517          	auipc	a0,0x4
    800049ee:	d2e50513          	add	a0,a0,-722 # 80008718 <syscalls+0x260>
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	b4a080e7          	jalr	-1206(ra) # 8000053c <panic>

00000000800049fa <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049fa:	7139                	add	sp,sp,-64
    800049fc:	fc06                	sd	ra,56(sp)
    800049fe:	f822                	sd	s0,48(sp)
    80004a00:	f426                	sd	s1,40(sp)
    80004a02:	f04a                	sd	s2,32(sp)
    80004a04:	ec4e                	sd	s3,24(sp)
    80004a06:	e852                	sd	s4,16(sp)
    80004a08:	e456                	sd	s5,8(sp)
    80004a0a:	0080                	add	s0,sp,64
    80004a0c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a0e:	0001c517          	auipc	a0,0x1c
    80004a12:	6da50513          	add	a0,a0,1754 # 800210e8 <ftable>
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	1bc080e7          	jalr	444(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004a1e:	40dc                	lw	a5,4(s1)
    80004a20:	06f05163          	blez	a5,80004a82 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a24:	37fd                	addw	a5,a5,-1
    80004a26:	0007871b          	sext.w	a4,a5
    80004a2a:	c0dc                	sw	a5,4(s1)
    80004a2c:	06e04363          	bgtz	a4,80004a92 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a30:	0004a903          	lw	s2,0(s1)
    80004a34:	0094ca83          	lbu	s5,9(s1)
    80004a38:	0104ba03          	ld	s4,16(s1)
    80004a3c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a40:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a44:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a48:	0001c517          	auipc	a0,0x1c
    80004a4c:	6a050513          	add	a0,a0,1696 # 800210e8 <ftable>
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	236080e7          	jalr	566(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004a58:	4785                	li	a5,1
    80004a5a:	04f90d63          	beq	s2,a5,80004ab4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a5e:	3979                	addw	s2,s2,-2
    80004a60:	4785                	li	a5,1
    80004a62:	0527e063          	bltu	a5,s2,80004aa2 <fileclose+0xa8>
    begin_op();
    80004a66:	00000097          	auipc	ra,0x0
    80004a6a:	ad0080e7          	jalr	-1328(ra) # 80004536 <begin_op>
    iput(ff.ip);
    80004a6e:	854e                	mv	a0,s3
    80004a70:	fffff097          	auipc	ra,0xfffff
    80004a74:	2da080e7          	jalr	730(ra) # 80003d4a <iput>
    end_op();
    80004a78:	00000097          	auipc	ra,0x0
    80004a7c:	b38080e7          	jalr	-1224(ra) # 800045b0 <end_op>
    80004a80:	a00d                	j	80004aa2 <fileclose+0xa8>
    panic("fileclose");
    80004a82:	00004517          	auipc	a0,0x4
    80004a86:	c9e50513          	add	a0,a0,-866 # 80008720 <syscalls+0x268>
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	ab2080e7          	jalr	-1358(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004a92:	0001c517          	auipc	a0,0x1c
    80004a96:	65650513          	add	a0,a0,1622 # 800210e8 <ftable>
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	1ec080e7          	jalr	492(ra) # 80000c86 <release>
  }
}
    80004aa2:	70e2                	ld	ra,56(sp)
    80004aa4:	7442                	ld	s0,48(sp)
    80004aa6:	74a2                	ld	s1,40(sp)
    80004aa8:	7902                	ld	s2,32(sp)
    80004aaa:	69e2                	ld	s3,24(sp)
    80004aac:	6a42                	ld	s4,16(sp)
    80004aae:	6aa2                	ld	s5,8(sp)
    80004ab0:	6121                	add	sp,sp,64
    80004ab2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ab4:	85d6                	mv	a1,s5
    80004ab6:	8552                	mv	a0,s4
    80004ab8:	00000097          	auipc	ra,0x0
    80004abc:	348080e7          	jalr	840(ra) # 80004e00 <pipeclose>
    80004ac0:	b7cd                	j	80004aa2 <fileclose+0xa8>

0000000080004ac2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ac2:	715d                	add	sp,sp,-80
    80004ac4:	e486                	sd	ra,72(sp)
    80004ac6:	e0a2                	sd	s0,64(sp)
    80004ac8:	fc26                	sd	s1,56(sp)
    80004aca:	f84a                	sd	s2,48(sp)
    80004acc:	f44e                	sd	s3,40(sp)
    80004ace:	0880                	add	s0,sp,80
    80004ad0:	84aa                	mv	s1,a0
    80004ad2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ad4:	ffffd097          	auipc	ra,0xffffd
    80004ad8:	08a080e7          	jalr	138(ra) # 80001b5e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004adc:	409c                	lw	a5,0(s1)
    80004ade:	37f9                	addw	a5,a5,-2
    80004ae0:	4705                	li	a4,1
    80004ae2:	04f76763          	bltu	a4,a5,80004b30 <filestat+0x6e>
    80004ae6:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ae8:	6c88                	ld	a0,24(s1)
    80004aea:	fffff097          	auipc	ra,0xfffff
    80004aee:	0a6080e7          	jalr	166(ra) # 80003b90 <ilock>
    stati(f->ip, &st);
    80004af2:	fb840593          	add	a1,s0,-72
    80004af6:	6c88                	ld	a0,24(s1)
    80004af8:	fffff097          	auipc	ra,0xfffff
    80004afc:	322080e7          	jalr	802(ra) # 80003e1a <stati>
    iunlock(f->ip);
    80004b00:	6c88                	ld	a0,24(s1)
    80004b02:	fffff097          	auipc	ra,0xfffff
    80004b06:	150080e7          	jalr	336(ra) # 80003c52 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b0a:	46e1                	li	a3,24
    80004b0c:	fb840613          	add	a2,s0,-72
    80004b10:	85ce                	mv	a1,s3
    80004b12:	05093503          	ld	a0,80(s2)
    80004b16:	ffffd097          	auipc	ra,0xffffd
    80004b1a:	b50080e7          	jalr	-1200(ra) # 80001666 <copyout>
    80004b1e:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b22:	60a6                	ld	ra,72(sp)
    80004b24:	6406                	ld	s0,64(sp)
    80004b26:	74e2                	ld	s1,56(sp)
    80004b28:	7942                	ld	s2,48(sp)
    80004b2a:	79a2                	ld	s3,40(sp)
    80004b2c:	6161                	add	sp,sp,80
    80004b2e:	8082                	ret
  return -1;
    80004b30:	557d                	li	a0,-1
    80004b32:	bfc5                	j	80004b22 <filestat+0x60>

0000000080004b34 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b34:	7179                	add	sp,sp,-48
    80004b36:	f406                	sd	ra,40(sp)
    80004b38:	f022                	sd	s0,32(sp)
    80004b3a:	ec26                	sd	s1,24(sp)
    80004b3c:	e84a                	sd	s2,16(sp)
    80004b3e:	e44e                	sd	s3,8(sp)
    80004b40:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b42:	00854783          	lbu	a5,8(a0)
    80004b46:	c3d5                	beqz	a5,80004bea <fileread+0xb6>
    80004b48:	84aa                	mv	s1,a0
    80004b4a:	89ae                	mv	s3,a1
    80004b4c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b4e:	411c                	lw	a5,0(a0)
    80004b50:	4705                	li	a4,1
    80004b52:	04e78963          	beq	a5,a4,80004ba4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b56:	470d                	li	a4,3
    80004b58:	04e78d63          	beq	a5,a4,80004bb2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b5c:	4709                	li	a4,2
    80004b5e:	06e79e63          	bne	a5,a4,80004bda <fileread+0xa6>
    ilock(f->ip);
    80004b62:	6d08                	ld	a0,24(a0)
    80004b64:	fffff097          	auipc	ra,0xfffff
    80004b68:	02c080e7          	jalr	44(ra) # 80003b90 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b6c:	874a                	mv	a4,s2
    80004b6e:	5094                	lw	a3,32(s1)
    80004b70:	864e                	mv	a2,s3
    80004b72:	4585                	li	a1,1
    80004b74:	6c88                	ld	a0,24(s1)
    80004b76:	fffff097          	auipc	ra,0xfffff
    80004b7a:	2ce080e7          	jalr	718(ra) # 80003e44 <readi>
    80004b7e:	892a                	mv	s2,a0
    80004b80:	00a05563          	blez	a0,80004b8a <fileread+0x56>
      f->off += r;
    80004b84:	509c                	lw	a5,32(s1)
    80004b86:	9fa9                	addw	a5,a5,a0
    80004b88:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b8a:	6c88                	ld	a0,24(s1)
    80004b8c:	fffff097          	auipc	ra,0xfffff
    80004b90:	0c6080e7          	jalr	198(ra) # 80003c52 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b94:	854a                	mv	a0,s2
    80004b96:	70a2                	ld	ra,40(sp)
    80004b98:	7402                	ld	s0,32(sp)
    80004b9a:	64e2                	ld	s1,24(sp)
    80004b9c:	6942                	ld	s2,16(sp)
    80004b9e:	69a2                	ld	s3,8(sp)
    80004ba0:	6145                	add	sp,sp,48
    80004ba2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004ba4:	6908                	ld	a0,16(a0)
    80004ba6:	00000097          	auipc	ra,0x0
    80004baa:	3c2080e7          	jalr	962(ra) # 80004f68 <piperead>
    80004bae:	892a                	mv	s2,a0
    80004bb0:	b7d5                	j	80004b94 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bb2:	02451783          	lh	a5,36(a0)
    80004bb6:	03079693          	sll	a3,a5,0x30
    80004bba:	92c1                	srl	a3,a3,0x30
    80004bbc:	4725                	li	a4,9
    80004bbe:	02d76863          	bltu	a4,a3,80004bee <fileread+0xba>
    80004bc2:	0792                	sll	a5,a5,0x4
    80004bc4:	0001c717          	auipc	a4,0x1c
    80004bc8:	48470713          	add	a4,a4,1156 # 80021048 <devsw>
    80004bcc:	97ba                	add	a5,a5,a4
    80004bce:	639c                	ld	a5,0(a5)
    80004bd0:	c38d                	beqz	a5,80004bf2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bd2:	4505                	li	a0,1
    80004bd4:	9782                	jalr	a5
    80004bd6:	892a                	mv	s2,a0
    80004bd8:	bf75                	j	80004b94 <fileread+0x60>
    panic("fileread");
    80004bda:	00004517          	auipc	a0,0x4
    80004bde:	b5650513          	add	a0,a0,-1194 # 80008730 <syscalls+0x278>
    80004be2:	ffffc097          	auipc	ra,0xffffc
    80004be6:	95a080e7          	jalr	-1702(ra) # 8000053c <panic>
    return -1;
    80004bea:	597d                	li	s2,-1
    80004bec:	b765                	j	80004b94 <fileread+0x60>
      return -1;
    80004bee:	597d                	li	s2,-1
    80004bf0:	b755                	j	80004b94 <fileread+0x60>
    80004bf2:	597d                	li	s2,-1
    80004bf4:	b745                	j	80004b94 <fileread+0x60>

0000000080004bf6 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004bf6:	00954783          	lbu	a5,9(a0)
    80004bfa:	10078e63          	beqz	a5,80004d16 <filewrite+0x120>
{
    80004bfe:	715d                	add	sp,sp,-80
    80004c00:	e486                	sd	ra,72(sp)
    80004c02:	e0a2                	sd	s0,64(sp)
    80004c04:	fc26                	sd	s1,56(sp)
    80004c06:	f84a                	sd	s2,48(sp)
    80004c08:	f44e                	sd	s3,40(sp)
    80004c0a:	f052                	sd	s4,32(sp)
    80004c0c:	ec56                	sd	s5,24(sp)
    80004c0e:	e85a                	sd	s6,16(sp)
    80004c10:	e45e                	sd	s7,8(sp)
    80004c12:	e062                	sd	s8,0(sp)
    80004c14:	0880                	add	s0,sp,80
    80004c16:	892a                	mv	s2,a0
    80004c18:	8b2e                	mv	s6,a1
    80004c1a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c1c:	411c                	lw	a5,0(a0)
    80004c1e:	4705                	li	a4,1
    80004c20:	02e78263          	beq	a5,a4,80004c44 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c24:	470d                	li	a4,3
    80004c26:	02e78563          	beq	a5,a4,80004c50 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c2a:	4709                	li	a4,2
    80004c2c:	0ce79d63          	bne	a5,a4,80004d06 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c30:	0ac05b63          	blez	a2,80004ce6 <filewrite+0xf0>
    int i = 0;
    80004c34:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004c36:	6b85                	lui	s7,0x1
    80004c38:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004c3c:	6c05                	lui	s8,0x1
    80004c3e:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004c42:	a851                	j	80004cd6 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004c44:	6908                	ld	a0,16(a0)
    80004c46:	00000097          	auipc	ra,0x0
    80004c4a:	22a080e7          	jalr	554(ra) # 80004e70 <pipewrite>
    80004c4e:	a045                	j	80004cee <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c50:	02451783          	lh	a5,36(a0)
    80004c54:	03079693          	sll	a3,a5,0x30
    80004c58:	92c1                	srl	a3,a3,0x30
    80004c5a:	4725                	li	a4,9
    80004c5c:	0ad76f63          	bltu	a4,a3,80004d1a <filewrite+0x124>
    80004c60:	0792                	sll	a5,a5,0x4
    80004c62:	0001c717          	auipc	a4,0x1c
    80004c66:	3e670713          	add	a4,a4,998 # 80021048 <devsw>
    80004c6a:	97ba                	add	a5,a5,a4
    80004c6c:	679c                	ld	a5,8(a5)
    80004c6e:	cbc5                	beqz	a5,80004d1e <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004c70:	4505                	li	a0,1
    80004c72:	9782                	jalr	a5
    80004c74:	a8ad                	j	80004cee <filewrite+0xf8>
      if(n1 > max)
    80004c76:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004c7a:	00000097          	auipc	ra,0x0
    80004c7e:	8bc080e7          	jalr	-1860(ra) # 80004536 <begin_op>
      ilock(f->ip);
    80004c82:	01893503          	ld	a0,24(s2)
    80004c86:	fffff097          	auipc	ra,0xfffff
    80004c8a:	f0a080e7          	jalr	-246(ra) # 80003b90 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c8e:	8756                	mv	a4,s5
    80004c90:	02092683          	lw	a3,32(s2)
    80004c94:	01698633          	add	a2,s3,s6
    80004c98:	4585                	li	a1,1
    80004c9a:	01893503          	ld	a0,24(s2)
    80004c9e:	fffff097          	auipc	ra,0xfffff
    80004ca2:	29e080e7          	jalr	670(ra) # 80003f3c <writei>
    80004ca6:	84aa                	mv	s1,a0
    80004ca8:	00a05763          	blez	a0,80004cb6 <filewrite+0xc0>
        f->off += r;
    80004cac:	02092783          	lw	a5,32(s2)
    80004cb0:	9fa9                	addw	a5,a5,a0
    80004cb2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cb6:	01893503          	ld	a0,24(s2)
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	f98080e7          	jalr	-104(ra) # 80003c52 <iunlock>
      end_op();
    80004cc2:	00000097          	auipc	ra,0x0
    80004cc6:	8ee080e7          	jalr	-1810(ra) # 800045b0 <end_op>

      if(r != n1){
    80004cca:	009a9f63          	bne	s5,s1,80004ce8 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004cce:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cd2:	0149db63          	bge	s3,s4,80004ce8 <filewrite+0xf2>
      int n1 = n - i;
    80004cd6:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004cda:	0004879b          	sext.w	a5,s1
    80004cde:	f8fbdce3          	bge	s7,a5,80004c76 <filewrite+0x80>
    80004ce2:	84e2                	mv	s1,s8
    80004ce4:	bf49                	j	80004c76 <filewrite+0x80>
    int i = 0;
    80004ce6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ce8:	033a1d63          	bne	s4,s3,80004d22 <filewrite+0x12c>
    80004cec:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004cee:	60a6                	ld	ra,72(sp)
    80004cf0:	6406                	ld	s0,64(sp)
    80004cf2:	74e2                	ld	s1,56(sp)
    80004cf4:	7942                	ld	s2,48(sp)
    80004cf6:	79a2                	ld	s3,40(sp)
    80004cf8:	7a02                	ld	s4,32(sp)
    80004cfa:	6ae2                	ld	s5,24(sp)
    80004cfc:	6b42                	ld	s6,16(sp)
    80004cfe:	6ba2                	ld	s7,8(sp)
    80004d00:	6c02                	ld	s8,0(sp)
    80004d02:	6161                	add	sp,sp,80
    80004d04:	8082                	ret
    panic("filewrite");
    80004d06:	00004517          	auipc	a0,0x4
    80004d0a:	a3a50513          	add	a0,a0,-1478 # 80008740 <syscalls+0x288>
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	82e080e7          	jalr	-2002(ra) # 8000053c <panic>
    return -1;
    80004d16:	557d                	li	a0,-1
}
    80004d18:	8082                	ret
      return -1;
    80004d1a:	557d                	li	a0,-1
    80004d1c:	bfc9                	j	80004cee <filewrite+0xf8>
    80004d1e:	557d                	li	a0,-1
    80004d20:	b7f9                	j	80004cee <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004d22:	557d                	li	a0,-1
    80004d24:	b7e9                	j	80004cee <filewrite+0xf8>

0000000080004d26 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d26:	7179                	add	sp,sp,-48
    80004d28:	f406                	sd	ra,40(sp)
    80004d2a:	f022                	sd	s0,32(sp)
    80004d2c:	ec26                	sd	s1,24(sp)
    80004d2e:	e84a                	sd	s2,16(sp)
    80004d30:	e44e                	sd	s3,8(sp)
    80004d32:	e052                	sd	s4,0(sp)
    80004d34:	1800                	add	s0,sp,48
    80004d36:	84aa                	mv	s1,a0
    80004d38:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d3a:	0005b023          	sd	zero,0(a1)
    80004d3e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d42:	00000097          	auipc	ra,0x0
    80004d46:	bfc080e7          	jalr	-1028(ra) # 8000493e <filealloc>
    80004d4a:	e088                	sd	a0,0(s1)
    80004d4c:	c551                	beqz	a0,80004dd8 <pipealloc+0xb2>
    80004d4e:	00000097          	auipc	ra,0x0
    80004d52:	bf0080e7          	jalr	-1040(ra) # 8000493e <filealloc>
    80004d56:	00aa3023          	sd	a0,0(s4)
    80004d5a:	c92d                	beqz	a0,80004dcc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d5c:	ffffc097          	auipc	ra,0xffffc
    80004d60:	d86080e7          	jalr	-634(ra) # 80000ae2 <kalloc>
    80004d64:	892a                	mv	s2,a0
    80004d66:	c125                	beqz	a0,80004dc6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d68:	4985                	li	s3,1
    80004d6a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d6e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d72:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d76:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d7a:	00004597          	auipc	a1,0x4
    80004d7e:	9d658593          	add	a1,a1,-1578 # 80008750 <syscalls+0x298>
    80004d82:	ffffc097          	auipc	ra,0xffffc
    80004d86:	dc0080e7          	jalr	-576(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004d8a:	609c                	ld	a5,0(s1)
    80004d8c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d90:	609c                	ld	a5,0(s1)
    80004d92:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d96:	609c                	ld	a5,0(s1)
    80004d98:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d9c:	609c                	ld	a5,0(s1)
    80004d9e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004da2:	000a3783          	ld	a5,0(s4)
    80004da6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004daa:	000a3783          	ld	a5,0(s4)
    80004dae:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004db2:	000a3783          	ld	a5,0(s4)
    80004db6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004dba:	000a3783          	ld	a5,0(s4)
    80004dbe:	0127b823          	sd	s2,16(a5)
  return 0;
    80004dc2:	4501                	li	a0,0
    80004dc4:	a025                	j	80004dec <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004dc6:	6088                	ld	a0,0(s1)
    80004dc8:	e501                	bnez	a0,80004dd0 <pipealloc+0xaa>
    80004dca:	a039                	j	80004dd8 <pipealloc+0xb2>
    80004dcc:	6088                	ld	a0,0(s1)
    80004dce:	c51d                	beqz	a0,80004dfc <pipealloc+0xd6>
    fileclose(*f0);
    80004dd0:	00000097          	auipc	ra,0x0
    80004dd4:	c2a080e7          	jalr	-982(ra) # 800049fa <fileclose>
  if(*f1)
    80004dd8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ddc:	557d                	li	a0,-1
  if(*f1)
    80004dde:	c799                	beqz	a5,80004dec <pipealloc+0xc6>
    fileclose(*f1);
    80004de0:	853e                	mv	a0,a5
    80004de2:	00000097          	auipc	ra,0x0
    80004de6:	c18080e7          	jalr	-1000(ra) # 800049fa <fileclose>
  return -1;
    80004dea:	557d                	li	a0,-1
}
    80004dec:	70a2                	ld	ra,40(sp)
    80004dee:	7402                	ld	s0,32(sp)
    80004df0:	64e2                	ld	s1,24(sp)
    80004df2:	6942                	ld	s2,16(sp)
    80004df4:	69a2                	ld	s3,8(sp)
    80004df6:	6a02                	ld	s4,0(sp)
    80004df8:	6145                	add	sp,sp,48
    80004dfa:	8082                	ret
  return -1;
    80004dfc:	557d                	li	a0,-1
    80004dfe:	b7fd                	j	80004dec <pipealloc+0xc6>

0000000080004e00 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e00:	1101                	add	sp,sp,-32
    80004e02:	ec06                	sd	ra,24(sp)
    80004e04:	e822                	sd	s0,16(sp)
    80004e06:	e426                	sd	s1,8(sp)
    80004e08:	e04a                	sd	s2,0(sp)
    80004e0a:	1000                	add	s0,sp,32
    80004e0c:	84aa                	mv	s1,a0
    80004e0e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e10:	ffffc097          	auipc	ra,0xffffc
    80004e14:	dc2080e7          	jalr	-574(ra) # 80000bd2 <acquire>
  if(writable){
    80004e18:	02090d63          	beqz	s2,80004e52 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e1c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e20:	21848513          	add	a0,s1,536
    80004e24:	ffffd097          	auipc	ra,0xffffd
    80004e28:	4f2080e7          	jalr	1266(ra) # 80002316 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e2c:	2204b783          	ld	a5,544(s1)
    80004e30:	eb95                	bnez	a5,80004e64 <pipeclose+0x64>
    release(&pi->lock);
    80004e32:	8526                	mv	a0,s1
    80004e34:	ffffc097          	auipc	ra,0xffffc
    80004e38:	e52080e7          	jalr	-430(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004e3c:	8526                	mv	a0,s1
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	ba6080e7          	jalr	-1114(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004e46:	60e2                	ld	ra,24(sp)
    80004e48:	6442                	ld	s0,16(sp)
    80004e4a:	64a2                	ld	s1,8(sp)
    80004e4c:	6902                	ld	s2,0(sp)
    80004e4e:	6105                	add	sp,sp,32
    80004e50:	8082                	ret
    pi->readopen = 0;
    80004e52:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e56:	21c48513          	add	a0,s1,540
    80004e5a:	ffffd097          	auipc	ra,0xffffd
    80004e5e:	4bc080e7          	jalr	1212(ra) # 80002316 <wakeup>
    80004e62:	b7e9                	j	80004e2c <pipeclose+0x2c>
    release(&pi->lock);
    80004e64:	8526                	mv	a0,s1
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	e20080e7          	jalr	-480(ra) # 80000c86 <release>
}
    80004e6e:	bfe1                	j	80004e46 <pipeclose+0x46>

0000000080004e70 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e70:	711d                	add	sp,sp,-96
    80004e72:	ec86                	sd	ra,88(sp)
    80004e74:	e8a2                	sd	s0,80(sp)
    80004e76:	e4a6                	sd	s1,72(sp)
    80004e78:	e0ca                	sd	s2,64(sp)
    80004e7a:	fc4e                	sd	s3,56(sp)
    80004e7c:	f852                	sd	s4,48(sp)
    80004e7e:	f456                	sd	s5,40(sp)
    80004e80:	f05a                	sd	s6,32(sp)
    80004e82:	ec5e                	sd	s7,24(sp)
    80004e84:	e862                	sd	s8,16(sp)
    80004e86:	1080                	add	s0,sp,96
    80004e88:	84aa                	mv	s1,a0
    80004e8a:	8aae                	mv	s5,a1
    80004e8c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e8e:	ffffd097          	auipc	ra,0xffffd
    80004e92:	cd0080e7          	jalr	-816(ra) # 80001b5e <myproc>
    80004e96:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e98:	8526                	mv	a0,s1
    80004e9a:	ffffc097          	auipc	ra,0xffffc
    80004e9e:	d38080e7          	jalr	-712(ra) # 80000bd2 <acquire>
  while(i < n){
    80004ea2:	0b405663          	blez	s4,80004f4e <pipewrite+0xde>
  int i = 0;
    80004ea6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ea8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004eaa:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004eae:	21c48b93          	add	s7,s1,540
    80004eb2:	a089                	j	80004ef4 <pipewrite+0x84>
      release(&pi->lock);
    80004eb4:	8526                	mv	a0,s1
    80004eb6:	ffffc097          	auipc	ra,0xffffc
    80004eba:	dd0080e7          	jalr	-560(ra) # 80000c86 <release>
      return -1;
    80004ebe:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ec0:	854a                	mv	a0,s2
    80004ec2:	60e6                	ld	ra,88(sp)
    80004ec4:	6446                	ld	s0,80(sp)
    80004ec6:	64a6                	ld	s1,72(sp)
    80004ec8:	6906                	ld	s2,64(sp)
    80004eca:	79e2                	ld	s3,56(sp)
    80004ecc:	7a42                	ld	s4,48(sp)
    80004ece:	7aa2                	ld	s5,40(sp)
    80004ed0:	7b02                	ld	s6,32(sp)
    80004ed2:	6be2                	ld	s7,24(sp)
    80004ed4:	6c42                	ld	s8,16(sp)
    80004ed6:	6125                	add	sp,sp,96
    80004ed8:	8082                	ret
      wakeup(&pi->nread);
    80004eda:	8562                	mv	a0,s8
    80004edc:	ffffd097          	auipc	ra,0xffffd
    80004ee0:	43a080e7          	jalr	1082(ra) # 80002316 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ee4:	85a6                	mv	a1,s1
    80004ee6:	855e                	mv	a0,s7
    80004ee8:	ffffd097          	auipc	ra,0xffffd
    80004eec:	3ca080e7          	jalr	970(ra) # 800022b2 <sleep>
  while(i < n){
    80004ef0:	07495063          	bge	s2,s4,80004f50 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004ef4:	2204a783          	lw	a5,544(s1)
    80004ef8:	dfd5                	beqz	a5,80004eb4 <pipewrite+0x44>
    80004efa:	854e                	mv	a0,s3
    80004efc:	ffffd097          	auipc	ra,0xffffd
    80004f00:	65e080e7          	jalr	1630(ra) # 8000255a <killed>
    80004f04:	f945                	bnez	a0,80004eb4 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f06:	2184a783          	lw	a5,536(s1)
    80004f0a:	21c4a703          	lw	a4,540(s1)
    80004f0e:	2007879b          	addw	a5,a5,512
    80004f12:	fcf704e3          	beq	a4,a5,80004eda <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f16:	4685                	li	a3,1
    80004f18:	01590633          	add	a2,s2,s5
    80004f1c:	faf40593          	add	a1,s0,-81
    80004f20:	0509b503          	ld	a0,80(s3)
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	7ce080e7          	jalr	1998(ra) # 800016f2 <copyin>
    80004f2c:	03650263          	beq	a0,s6,80004f50 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f30:	21c4a783          	lw	a5,540(s1)
    80004f34:	0017871b          	addw	a4,a5,1
    80004f38:	20e4ae23          	sw	a4,540(s1)
    80004f3c:	1ff7f793          	and	a5,a5,511
    80004f40:	97a6                	add	a5,a5,s1
    80004f42:	faf44703          	lbu	a4,-81(s0)
    80004f46:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f4a:	2905                	addw	s2,s2,1
    80004f4c:	b755                	j	80004ef0 <pipewrite+0x80>
  int i = 0;
    80004f4e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f50:	21848513          	add	a0,s1,536
    80004f54:	ffffd097          	auipc	ra,0xffffd
    80004f58:	3c2080e7          	jalr	962(ra) # 80002316 <wakeup>
  release(&pi->lock);
    80004f5c:	8526                	mv	a0,s1
    80004f5e:	ffffc097          	auipc	ra,0xffffc
    80004f62:	d28080e7          	jalr	-728(ra) # 80000c86 <release>
  return i;
    80004f66:	bfa9                	j	80004ec0 <pipewrite+0x50>

0000000080004f68 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f68:	715d                	add	sp,sp,-80
    80004f6a:	e486                	sd	ra,72(sp)
    80004f6c:	e0a2                	sd	s0,64(sp)
    80004f6e:	fc26                	sd	s1,56(sp)
    80004f70:	f84a                	sd	s2,48(sp)
    80004f72:	f44e                	sd	s3,40(sp)
    80004f74:	f052                	sd	s4,32(sp)
    80004f76:	ec56                	sd	s5,24(sp)
    80004f78:	e85a                	sd	s6,16(sp)
    80004f7a:	0880                	add	s0,sp,80
    80004f7c:	84aa                	mv	s1,a0
    80004f7e:	892e                	mv	s2,a1
    80004f80:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f82:	ffffd097          	auipc	ra,0xffffd
    80004f86:	bdc080e7          	jalr	-1060(ra) # 80001b5e <myproc>
    80004f8a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f8c:	8526                	mv	a0,s1
    80004f8e:	ffffc097          	auipc	ra,0xffffc
    80004f92:	c44080e7          	jalr	-956(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f96:	2184a703          	lw	a4,536(s1)
    80004f9a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f9e:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fa2:	02f71763          	bne	a4,a5,80004fd0 <piperead+0x68>
    80004fa6:	2244a783          	lw	a5,548(s1)
    80004faa:	c39d                	beqz	a5,80004fd0 <piperead+0x68>
    if(killed(pr)){
    80004fac:	8552                	mv	a0,s4
    80004fae:	ffffd097          	auipc	ra,0xffffd
    80004fb2:	5ac080e7          	jalr	1452(ra) # 8000255a <killed>
    80004fb6:	e949                	bnez	a0,80005048 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fb8:	85a6                	mv	a1,s1
    80004fba:	854e                	mv	a0,s3
    80004fbc:	ffffd097          	auipc	ra,0xffffd
    80004fc0:	2f6080e7          	jalr	758(ra) # 800022b2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fc4:	2184a703          	lw	a4,536(s1)
    80004fc8:	21c4a783          	lw	a5,540(s1)
    80004fcc:	fcf70de3          	beq	a4,a5,80004fa6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fd0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fd2:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fd4:	05505463          	blez	s5,8000501c <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004fd8:	2184a783          	lw	a5,536(s1)
    80004fdc:	21c4a703          	lw	a4,540(s1)
    80004fe0:	02f70e63          	beq	a4,a5,8000501c <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004fe4:	0017871b          	addw	a4,a5,1
    80004fe8:	20e4ac23          	sw	a4,536(s1)
    80004fec:	1ff7f793          	and	a5,a5,511
    80004ff0:	97a6                	add	a5,a5,s1
    80004ff2:	0187c783          	lbu	a5,24(a5)
    80004ff6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ffa:	4685                	li	a3,1
    80004ffc:	fbf40613          	add	a2,s0,-65
    80005000:	85ca                	mv	a1,s2
    80005002:	050a3503          	ld	a0,80(s4)
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	660080e7          	jalr	1632(ra) # 80001666 <copyout>
    8000500e:	01650763          	beq	a0,s6,8000501c <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005012:	2985                	addw	s3,s3,1
    80005014:	0905                	add	s2,s2,1
    80005016:	fd3a91e3          	bne	s5,s3,80004fd8 <piperead+0x70>
    8000501a:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000501c:	21c48513          	add	a0,s1,540
    80005020:	ffffd097          	auipc	ra,0xffffd
    80005024:	2f6080e7          	jalr	758(ra) # 80002316 <wakeup>
  release(&pi->lock);
    80005028:	8526                	mv	a0,s1
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	c5c080e7          	jalr	-932(ra) # 80000c86 <release>
  return i;
}
    80005032:	854e                	mv	a0,s3
    80005034:	60a6                	ld	ra,72(sp)
    80005036:	6406                	ld	s0,64(sp)
    80005038:	74e2                	ld	s1,56(sp)
    8000503a:	7942                	ld	s2,48(sp)
    8000503c:	79a2                	ld	s3,40(sp)
    8000503e:	7a02                	ld	s4,32(sp)
    80005040:	6ae2                	ld	s5,24(sp)
    80005042:	6b42                	ld	s6,16(sp)
    80005044:	6161                	add	sp,sp,80
    80005046:	8082                	ret
      release(&pi->lock);
    80005048:	8526                	mv	a0,s1
    8000504a:	ffffc097          	auipc	ra,0xffffc
    8000504e:	c3c080e7          	jalr	-964(ra) # 80000c86 <release>
      return -1;
    80005052:	59fd                	li	s3,-1
    80005054:	bff9                	j	80005032 <piperead+0xca>

0000000080005056 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005056:	1141                	add	sp,sp,-16
    80005058:	e422                	sd	s0,8(sp)
    8000505a:	0800                	add	s0,sp,16
    8000505c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000505e:	8905                	and	a0,a0,1
    80005060:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005062:	8b89                	and	a5,a5,2
    80005064:	c399                	beqz	a5,8000506a <flags2perm+0x14>
      perm |= PTE_W;
    80005066:	00456513          	or	a0,a0,4
    return perm;
}
    8000506a:	6422                	ld	s0,8(sp)
    8000506c:	0141                	add	sp,sp,16
    8000506e:	8082                	ret

0000000080005070 <exec>:

int
exec(char *path, char **argv)
{
    80005070:	df010113          	add	sp,sp,-528
    80005074:	20113423          	sd	ra,520(sp)
    80005078:	20813023          	sd	s0,512(sp)
    8000507c:	ffa6                	sd	s1,504(sp)
    8000507e:	fbca                	sd	s2,496(sp)
    80005080:	f7ce                	sd	s3,488(sp)
    80005082:	f3d2                	sd	s4,480(sp)
    80005084:	efd6                	sd	s5,472(sp)
    80005086:	ebda                	sd	s6,464(sp)
    80005088:	e7de                	sd	s7,456(sp)
    8000508a:	e3e2                	sd	s8,448(sp)
    8000508c:	ff66                	sd	s9,440(sp)
    8000508e:	fb6a                	sd	s10,432(sp)
    80005090:	f76e                	sd	s11,424(sp)
    80005092:	0c00                	add	s0,sp,528
    80005094:	892a                	mv	s2,a0
    80005096:	dea43c23          	sd	a0,-520(s0)
    8000509a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000509e:	ffffd097          	auipc	ra,0xffffd
    800050a2:	ac0080e7          	jalr	-1344(ra) # 80001b5e <myproc>
    800050a6:	84aa                	mv	s1,a0

  begin_op();
    800050a8:	fffff097          	auipc	ra,0xfffff
    800050ac:	48e080e7          	jalr	1166(ra) # 80004536 <begin_op>

  if((ip = namei(path)) == 0){
    800050b0:	854a                	mv	a0,s2
    800050b2:	fffff097          	auipc	ra,0xfffff
    800050b6:	284080e7          	jalr	644(ra) # 80004336 <namei>
    800050ba:	c92d                	beqz	a0,8000512c <exec+0xbc>
    800050bc:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050be:	fffff097          	auipc	ra,0xfffff
    800050c2:	ad2080e7          	jalr	-1326(ra) # 80003b90 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050c6:	04000713          	li	a4,64
    800050ca:	4681                	li	a3,0
    800050cc:	e5040613          	add	a2,s0,-432
    800050d0:	4581                	li	a1,0
    800050d2:	8552                	mv	a0,s4
    800050d4:	fffff097          	auipc	ra,0xfffff
    800050d8:	d70080e7          	jalr	-656(ra) # 80003e44 <readi>
    800050dc:	04000793          	li	a5,64
    800050e0:	00f51a63          	bne	a0,a5,800050f4 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800050e4:	e5042703          	lw	a4,-432(s0)
    800050e8:	464c47b7          	lui	a5,0x464c4
    800050ec:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050f0:	04f70463          	beq	a4,a5,80005138 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050f4:	8552                	mv	a0,s4
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	cfc080e7          	jalr	-772(ra) # 80003df2 <iunlockput>
    end_op();
    800050fe:	fffff097          	auipc	ra,0xfffff
    80005102:	4b2080e7          	jalr	1202(ra) # 800045b0 <end_op>
  }
  return -1;
    80005106:	557d                	li	a0,-1
}
    80005108:	20813083          	ld	ra,520(sp)
    8000510c:	20013403          	ld	s0,512(sp)
    80005110:	74fe                	ld	s1,504(sp)
    80005112:	795e                	ld	s2,496(sp)
    80005114:	79be                	ld	s3,488(sp)
    80005116:	7a1e                	ld	s4,480(sp)
    80005118:	6afe                	ld	s5,472(sp)
    8000511a:	6b5e                	ld	s6,464(sp)
    8000511c:	6bbe                	ld	s7,456(sp)
    8000511e:	6c1e                	ld	s8,448(sp)
    80005120:	7cfa                	ld	s9,440(sp)
    80005122:	7d5a                	ld	s10,432(sp)
    80005124:	7dba                	ld	s11,424(sp)
    80005126:	21010113          	add	sp,sp,528
    8000512a:	8082                	ret
    end_op();
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	484080e7          	jalr	1156(ra) # 800045b0 <end_op>
    return -1;
    80005134:	557d                	li	a0,-1
    80005136:	bfc9                	j	80005108 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005138:	8526                	mv	a0,s1
    8000513a:	ffffd097          	auipc	ra,0xffffd
    8000513e:	ae8080e7          	jalr	-1304(ra) # 80001c22 <proc_pagetable>
    80005142:	8b2a                	mv	s6,a0
    80005144:	d945                	beqz	a0,800050f4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005146:	e7042d03          	lw	s10,-400(s0)
    8000514a:	e8845783          	lhu	a5,-376(s0)
    8000514e:	10078463          	beqz	a5,80005256 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005152:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005154:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005156:	6c85                	lui	s9,0x1
    80005158:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000515c:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005160:	6a85                	lui	s5,0x1
    80005162:	a0b5                	j	800051ce <exec+0x15e>
      panic("loadseg: address should exist");
    80005164:	00003517          	auipc	a0,0x3
    80005168:	5f450513          	add	a0,a0,1524 # 80008758 <syscalls+0x2a0>
    8000516c:	ffffb097          	auipc	ra,0xffffb
    80005170:	3d0080e7          	jalr	976(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005174:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005176:	8726                	mv	a4,s1
    80005178:	012c06bb          	addw	a3,s8,s2
    8000517c:	4581                	li	a1,0
    8000517e:	8552                	mv	a0,s4
    80005180:	fffff097          	auipc	ra,0xfffff
    80005184:	cc4080e7          	jalr	-828(ra) # 80003e44 <readi>
    80005188:	2501                	sext.w	a0,a0
    8000518a:	26a49463          	bne	s1,a0,800053f2 <exec+0x382>
  for(i = 0; i < sz; i += PGSIZE){
    8000518e:	012a893b          	addw	s2,s5,s2
    80005192:	03397563          	bgeu	s2,s3,800051bc <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005196:	02091593          	sll	a1,s2,0x20
    8000519a:	9181                	srl	a1,a1,0x20
    8000519c:	95de                	add	a1,a1,s7
    8000519e:	855a                	mv	a0,s6
    800051a0:	ffffc097          	auipc	ra,0xffffc
    800051a4:	eb6080e7          	jalr	-330(ra) # 80001056 <walkaddr>
    800051a8:	862a                	mv	a2,a0
    if(pa == 0)
    800051aa:	dd4d                	beqz	a0,80005164 <exec+0xf4>
    if(sz - i < PGSIZE)
    800051ac:	412984bb          	subw	s1,s3,s2
    800051b0:	0004879b          	sext.w	a5,s1
    800051b4:	fcfcf0e3          	bgeu	s9,a5,80005174 <exec+0x104>
    800051b8:	84d6                	mv	s1,s5
    800051ba:	bf6d                	j	80005174 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051bc:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051c0:	2d85                	addw	s11,s11,1
    800051c2:	038d0d1b          	addw	s10,s10,56
    800051c6:	e8845783          	lhu	a5,-376(s0)
    800051ca:	08fdd763          	bge	s11,a5,80005258 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051ce:	2d01                	sext.w	s10,s10
    800051d0:	03800713          	li	a4,56
    800051d4:	86ea                	mv	a3,s10
    800051d6:	e1840613          	add	a2,s0,-488
    800051da:	4581                	li	a1,0
    800051dc:	8552                	mv	a0,s4
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	c66080e7          	jalr	-922(ra) # 80003e44 <readi>
    800051e6:	03800793          	li	a5,56
    800051ea:	20f51263          	bne	a0,a5,800053ee <exec+0x37e>
    if(ph.type != ELF_PROG_LOAD)
    800051ee:	e1842783          	lw	a5,-488(s0)
    800051f2:	4705                	li	a4,1
    800051f4:	fce796e3          	bne	a5,a4,800051c0 <exec+0x150>
    if(ph.memsz < ph.filesz)
    800051f8:	e4043483          	ld	s1,-448(s0)
    800051fc:	e3843783          	ld	a5,-456(s0)
    80005200:	20f4e463          	bltu	s1,a5,80005408 <exec+0x398>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005204:	e2843783          	ld	a5,-472(s0)
    80005208:	94be                	add	s1,s1,a5
    8000520a:	20f4e263          	bltu	s1,a5,8000540e <exec+0x39e>
    if(ph.vaddr % PGSIZE != 0)
    8000520e:	df043703          	ld	a4,-528(s0)
    80005212:	8ff9                	and	a5,a5,a4
    80005214:	20079063          	bnez	a5,80005414 <exec+0x3a4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005218:	e1c42503          	lw	a0,-484(s0)
    8000521c:	00000097          	auipc	ra,0x0
    80005220:	e3a080e7          	jalr	-454(ra) # 80005056 <flags2perm>
    80005224:	86aa                	mv	a3,a0
    80005226:	8626                	mv	a2,s1
    80005228:	85ca                	mv	a1,s2
    8000522a:	855a                	mv	a0,s6
    8000522c:	ffffc097          	auipc	ra,0xffffc
    80005230:	1de080e7          	jalr	478(ra) # 8000140a <uvmalloc>
    80005234:	e0a43423          	sd	a0,-504(s0)
    80005238:	1e050163          	beqz	a0,8000541a <exec+0x3aa>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000523c:	e2843b83          	ld	s7,-472(s0)
    80005240:	e2042c03          	lw	s8,-480(s0)
    80005244:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005248:	00098463          	beqz	s3,80005250 <exec+0x1e0>
    8000524c:	4901                	li	s2,0
    8000524e:	b7a1                	j	80005196 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005250:	e0843903          	ld	s2,-504(s0)
    80005254:	b7b5                	j	800051c0 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005256:	4901                	li	s2,0
  iunlockput(ip);
    80005258:	8552                	mv	a0,s4
    8000525a:	fffff097          	auipc	ra,0xfffff
    8000525e:	b98080e7          	jalr	-1128(ra) # 80003df2 <iunlockput>
  end_op();
    80005262:	fffff097          	auipc	ra,0xfffff
    80005266:	34e080e7          	jalr	846(ra) # 800045b0 <end_op>
  p = myproc();
    8000526a:	ffffd097          	auipc	ra,0xffffd
    8000526e:	8f4080e7          	jalr	-1804(ra) # 80001b5e <myproc>
    80005272:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005274:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005278:	6985                	lui	s3,0x1
    8000527a:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    8000527c:	99ca                	add	s3,s3,s2
    8000527e:	77fd                	lui	a5,0xfffff
    80005280:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005284:	4691                	li	a3,4
    80005286:	6609                	lui	a2,0x2
    80005288:	964e                	add	a2,a2,s3
    8000528a:	85ce                	mv	a1,s3
    8000528c:	855a                	mv	a0,s6
    8000528e:	ffffc097          	auipc	ra,0xffffc
    80005292:	17c080e7          	jalr	380(ra) # 8000140a <uvmalloc>
    80005296:	892a                	mv	s2,a0
    80005298:	e0a43423          	sd	a0,-504(s0)
    8000529c:	e509                	bnez	a0,800052a6 <exec+0x236>
  if(pagetable)
    8000529e:	e1343423          	sd	s3,-504(s0)
    800052a2:	4a01                	li	s4,0
    800052a4:	a2b9                	j	800053f2 <exec+0x382>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052a6:	75f9                	lui	a1,0xffffe
    800052a8:	95aa                	add	a1,a1,a0
    800052aa:	855a                	mv	a0,s6
    800052ac:	ffffc097          	auipc	ra,0xffffc
    800052b0:	388080e7          	jalr	904(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    800052b4:	7bfd                	lui	s7,0xfffff
    800052b6:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800052b8:	e0043783          	ld	a5,-512(s0)
    800052bc:	6388                	ld	a0,0(a5)
    800052be:	c52d                	beqz	a0,80005328 <exec+0x2b8>
    800052c0:	e9040993          	add	s3,s0,-368
    800052c4:	f9040c13          	add	s8,s0,-112
    800052c8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800052ca:	ffffc097          	auipc	ra,0xffffc
    800052ce:	b7e080e7          	jalr	-1154(ra) # 80000e48 <strlen>
    800052d2:	0015079b          	addw	a5,a0,1
    800052d6:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052da:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    800052de:	15796163          	bltu	s2,s7,80005420 <exec+0x3b0>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052e2:	e0043d03          	ld	s10,-512(s0)
    800052e6:	000d3a03          	ld	s4,0(s10)
    800052ea:	8552                	mv	a0,s4
    800052ec:	ffffc097          	auipc	ra,0xffffc
    800052f0:	b5c080e7          	jalr	-1188(ra) # 80000e48 <strlen>
    800052f4:	0015069b          	addw	a3,a0,1
    800052f8:	8652                	mv	a2,s4
    800052fa:	85ca                	mv	a1,s2
    800052fc:	855a                	mv	a0,s6
    800052fe:	ffffc097          	auipc	ra,0xffffc
    80005302:	368080e7          	jalr	872(ra) # 80001666 <copyout>
    80005306:	10054f63          	bltz	a0,80005424 <exec+0x3b4>
    ustack[argc] = sp;
    8000530a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000530e:	0485                	add	s1,s1,1
    80005310:	008d0793          	add	a5,s10,8
    80005314:	e0f43023          	sd	a5,-512(s0)
    80005318:	008d3503          	ld	a0,8(s10)
    8000531c:	c909                	beqz	a0,8000532e <exec+0x2be>
    if(argc >= MAXARG)
    8000531e:	09a1                	add	s3,s3,8
    80005320:	fb8995e3          	bne	s3,s8,800052ca <exec+0x25a>
  ip = 0;
    80005324:	4a01                	li	s4,0
    80005326:	a0f1                	j	800053f2 <exec+0x382>
  sp = sz;
    80005328:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000532c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000532e:	00349793          	sll	a5,s1,0x3
    80005332:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd8c10>
    80005336:	97a2                	add	a5,a5,s0
    80005338:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000533c:	00148693          	add	a3,s1,1
    80005340:	068e                	sll	a3,a3,0x3
    80005342:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005346:	ff097913          	and	s2,s2,-16
  sz = sz1;
    8000534a:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000534e:	f57968e3          	bltu	s2,s7,8000529e <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005352:	e9040613          	add	a2,s0,-368
    80005356:	85ca                	mv	a1,s2
    80005358:	855a                	mv	a0,s6
    8000535a:	ffffc097          	auipc	ra,0xffffc
    8000535e:	30c080e7          	jalr	780(ra) # 80001666 <copyout>
    80005362:	0c054363          	bltz	a0,80005428 <exec+0x3b8>
  p->trapframe->a1 = sp;
    80005366:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    8000536a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000536e:	df843783          	ld	a5,-520(s0)
    80005372:	0007c703          	lbu	a4,0(a5)
    80005376:	cf11                	beqz	a4,80005392 <exec+0x322>
    80005378:	0785                	add	a5,a5,1
    if(*s == '/')
    8000537a:	02f00693          	li	a3,47
    8000537e:	a039                	j	8000538c <exec+0x31c>
      last = s+1;
    80005380:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005384:	0785                	add	a5,a5,1
    80005386:	fff7c703          	lbu	a4,-1(a5)
    8000538a:	c701                	beqz	a4,80005392 <exec+0x322>
    if(*s == '/')
    8000538c:	fed71ce3          	bne	a4,a3,80005384 <exec+0x314>
    80005390:	bfc5                	j	80005380 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80005392:	4641                	li	a2,16
    80005394:	df843583          	ld	a1,-520(s0)
    80005398:	158a8513          	add	a0,s5,344
    8000539c:	ffffc097          	auipc	ra,0xffffc
    800053a0:	a7a080e7          	jalr	-1414(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800053a4:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800053a8:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800053ac:	e0843783          	ld	a5,-504(s0)
    800053b0:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053b4:	058ab783          	ld	a5,88(s5)
    800053b8:	e6843703          	ld	a4,-408(s0)
    800053bc:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053be:	058ab783          	ld	a5,88(s5)
    800053c2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053c6:	85e6                	mv	a1,s9
    800053c8:	ffffd097          	auipc	ra,0xffffd
    800053cc:	8f6080e7          	jalr	-1802(ra) # 80001cbe <proc_freepagetable>
  if(p->pid==1) vmprint_start(p->pagetable);
    800053d0:	030aa703          	lw	a4,48(s5)
    800053d4:	4785                	li	a5,1
    800053d6:	00f70563          	beq	a4,a5,800053e0 <exec+0x370>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053da:	0004851b          	sext.w	a0,s1
    800053de:	b32d                	j	80005108 <exec+0x98>
  if(p->pid==1) vmprint_start(p->pagetable);
    800053e0:	050ab503          	ld	a0,80(s5)
    800053e4:	ffffc097          	auipc	ra,0xffffc
    800053e8:	546080e7          	jalr	1350(ra) # 8000192a <vmprint_start>
    800053ec:	b7fd                	j	800053da <exec+0x36a>
    800053ee:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800053f2:	e0843583          	ld	a1,-504(s0)
    800053f6:	855a                	mv	a0,s6
    800053f8:	ffffd097          	auipc	ra,0xffffd
    800053fc:	8c6080e7          	jalr	-1850(ra) # 80001cbe <proc_freepagetable>
  return -1;
    80005400:	557d                	li	a0,-1
  if(ip){
    80005402:	d00a03e3          	beqz	s4,80005108 <exec+0x98>
    80005406:	b1fd                	j	800050f4 <exec+0x84>
    80005408:	e1243423          	sd	s2,-504(s0)
    8000540c:	b7dd                	j	800053f2 <exec+0x382>
    8000540e:	e1243423          	sd	s2,-504(s0)
    80005412:	b7c5                	j	800053f2 <exec+0x382>
    80005414:	e1243423          	sd	s2,-504(s0)
    80005418:	bfe9                	j	800053f2 <exec+0x382>
    8000541a:	e1243423          	sd	s2,-504(s0)
    8000541e:	bfd1                	j	800053f2 <exec+0x382>
  ip = 0;
    80005420:	4a01                	li	s4,0
    80005422:	bfc1                	j	800053f2 <exec+0x382>
    80005424:	4a01                	li	s4,0
  if(pagetable)
    80005426:	b7f1                	j	800053f2 <exec+0x382>
  sz = sz1;
    80005428:	e0843983          	ld	s3,-504(s0)
    8000542c:	bd8d                	j	8000529e <exec+0x22e>

000000008000542e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000542e:	7179                	add	sp,sp,-48
    80005430:	f406                	sd	ra,40(sp)
    80005432:	f022                	sd	s0,32(sp)
    80005434:	ec26                	sd	s1,24(sp)
    80005436:	e84a                	sd	s2,16(sp)
    80005438:	1800                	add	s0,sp,48
    8000543a:	892e                	mv	s2,a1
    8000543c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000543e:	fdc40593          	add	a1,s0,-36
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	b14080e7          	jalr	-1260(ra) # 80002f56 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000544a:	fdc42703          	lw	a4,-36(s0)
    8000544e:	47bd                	li	a5,15
    80005450:	02e7eb63          	bltu	a5,a4,80005486 <argfd+0x58>
    80005454:	ffffc097          	auipc	ra,0xffffc
    80005458:	70a080e7          	jalr	1802(ra) # 80001b5e <myproc>
    8000545c:	fdc42703          	lw	a4,-36(s0)
    80005460:	01a70793          	add	a5,a4,26
    80005464:	078e                	sll	a5,a5,0x3
    80005466:	953e                	add	a0,a0,a5
    80005468:	611c                	ld	a5,0(a0)
    8000546a:	c385                	beqz	a5,8000548a <argfd+0x5c>
    return -1;
  if(pfd)
    8000546c:	00090463          	beqz	s2,80005474 <argfd+0x46>
    *pfd = fd;
    80005470:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005474:	4501                	li	a0,0
  if(pf)
    80005476:	c091                	beqz	s1,8000547a <argfd+0x4c>
    *pf = f;
    80005478:	e09c                	sd	a5,0(s1)
}
    8000547a:	70a2                	ld	ra,40(sp)
    8000547c:	7402                	ld	s0,32(sp)
    8000547e:	64e2                	ld	s1,24(sp)
    80005480:	6942                	ld	s2,16(sp)
    80005482:	6145                	add	sp,sp,48
    80005484:	8082                	ret
    return -1;
    80005486:	557d                	li	a0,-1
    80005488:	bfcd                	j	8000547a <argfd+0x4c>
    8000548a:	557d                	li	a0,-1
    8000548c:	b7fd                	j	8000547a <argfd+0x4c>

000000008000548e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000548e:	1101                	add	sp,sp,-32
    80005490:	ec06                	sd	ra,24(sp)
    80005492:	e822                	sd	s0,16(sp)
    80005494:	e426                	sd	s1,8(sp)
    80005496:	1000                	add	s0,sp,32
    80005498:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000549a:	ffffc097          	auipc	ra,0xffffc
    8000549e:	6c4080e7          	jalr	1732(ra) # 80001b5e <myproc>
    800054a2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054a4:	0d050793          	add	a5,a0,208
    800054a8:	4501                	li	a0,0
    800054aa:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054ac:	6398                	ld	a4,0(a5)
    800054ae:	cb19                	beqz	a4,800054c4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054b0:	2505                	addw	a0,a0,1
    800054b2:	07a1                	add	a5,a5,8
    800054b4:	fed51ce3          	bne	a0,a3,800054ac <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054b8:	557d                	li	a0,-1
}
    800054ba:	60e2                	ld	ra,24(sp)
    800054bc:	6442                	ld	s0,16(sp)
    800054be:	64a2                	ld	s1,8(sp)
    800054c0:	6105                	add	sp,sp,32
    800054c2:	8082                	ret
      p->ofile[fd] = f;
    800054c4:	01a50793          	add	a5,a0,26
    800054c8:	078e                	sll	a5,a5,0x3
    800054ca:	963e                	add	a2,a2,a5
    800054cc:	e204                	sd	s1,0(a2)
      return fd;
    800054ce:	b7f5                	j	800054ba <fdalloc+0x2c>

00000000800054d0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054d0:	715d                	add	sp,sp,-80
    800054d2:	e486                	sd	ra,72(sp)
    800054d4:	e0a2                	sd	s0,64(sp)
    800054d6:	fc26                	sd	s1,56(sp)
    800054d8:	f84a                	sd	s2,48(sp)
    800054da:	f44e                	sd	s3,40(sp)
    800054dc:	f052                	sd	s4,32(sp)
    800054de:	ec56                	sd	s5,24(sp)
    800054e0:	e85a                	sd	s6,16(sp)
    800054e2:	0880                	add	s0,sp,80
    800054e4:	8b2e                	mv	s6,a1
    800054e6:	89b2                	mv	s3,a2
    800054e8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054ea:	fb040593          	add	a1,s0,-80
    800054ee:	fffff097          	auipc	ra,0xfffff
    800054f2:	e66080e7          	jalr	-410(ra) # 80004354 <nameiparent>
    800054f6:	84aa                	mv	s1,a0
    800054f8:	14050b63          	beqz	a0,8000564e <create+0x17e>
    return 0;

  ilock(dp);
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	694080e7          	jalr	1684(ra) # 80003b90 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005504:	4601                	li	a2,0
    80005506:	fb040593          	add	a1,s0,-80
    8000550a:	8526                	mv	a0,s1
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	b68080e7          	jalr	-1176(ra) # 80004074 <dirlookup>
    80005514:	8aaa                	mv	s5,a0
    80005516:	c921                	beqz	a0,80005566 <create+0x96>
    iunlockput(dp);
    80005518:	8526                	mv	a0,s1
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	8d8080e7          	jalr	-1832(ra) # 80003df2 <iunlockput>
    ilock(ip);
    80005522:	8556                	mv	a0,s5
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	66c080e7          	jalr	1644(ra) # 80003b90 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000552c:	4789                	li	a5,2
    8000552e:	02fb1563          	bne	s6,a5,80005558 <create+0x88>
    80005532:	044ad783          	lhu	a5,68(s5)
    80005536:	37f9                	addw	a5,a5,-2
    80005538:	17c2                	sll	a5,a5,0x30
    8000553a:	93c1                	srl	a5,a5,0x30
    8000553c:	4705                	li	a4,1
    8000553e:	00f76d63          	bltu	a4,a5,80005558 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005542:	8556                	mv	a0,s5
    80005544:	60a6                	ld	ra,72(sp)
    80005546:	6406                	ld	s0,64(sp)
    80005548:	74e2                	ld	s1,56(sp)
    8000554a:	7942                	ld	s2,48(sp)
    8000554c:	79a2                	ld	s3,40(sp)
    8000554e:	7a02                	ld	s4,32(sp)
    80005550:	6ae2                	ld	s5,24(sp)
    80005552:	6b42                	ld	s6,16(sp)
    80005554:	6161                	add	sp,sp,80
    80005556:	8082                	ret
    iunlockput(ip);
    80005558:	8556                	mv	a0,s5
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	898080e7          	jalr	-1896(ra) # 80003df2 <iunlockput>
    return 0;
    80005562:	4a81                	li	s5,0
    80005564:	bff9                	j	80005542 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005566:	85da                	mv	a1,s6
    80005568:	4088                	lw	a0,0(s1)
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	48e080e7          	jalr	1166(ra) # 800039f8 <ialloc>
    80005572:	8a2a                	mv	s4,a0
    80005574:	c529                	beqz	a0,800055be <create+0xee>
  ilock(ip);
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	61a080e7          	jalr	1562(ra) # 80003b90 <ilock>
  ip->major = major;
    8000557e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005582:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005586:	4905                	li	s2,1
    80005588:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000558c:	8552                	mv	a0,s4
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	536080e7          	jalr	1334(ra) # 80003ac4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005596:	032b0b63          	beq	s6,s2,800055cc <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000559a:	004a2603          	lw	a2,4(s4)
    8000559e:	fb040593          	add	a1,s0,-80
    800055a2:	8526                	mv	a0,s1
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	ce0080e7          	jalr	-800(ra) # 80004284 <dirlink>
    800055ac:	06054f63          	bltz	a0,8000562a <create+0x15a>
  iunlockput(dp);
    800055b0:	8526                	mv	a0,s1
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	840080e7          	jalr	-1984(ra) # 80003df2 <iunlockput>
  return ip;
    800055ba:	8ad2                	mv	s5,s4
    800055bc:	b759                	j	80005542 <create+0x72>
    iunlockput(dp);
    800055be:	8526                	mv	a0,s1
    800055c0:	fffff097          	auipc	ra,0xfffff
    800055c4:	832080e7          	jalr	-1998(ra) # 80003df2 <iunlockput>
    return 0;
    800055c8:	8ad2                	mv	s5,s4
    800055ca:	bfa5                	j	80005542 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055cc:	004a2603          	lw	a2,4(s4)
    800055d0:	00003597          	auipc	a1,0x3
    800055d4:	1a858593          	add	a1,a1,424 # 80008778 <syscalls+0x2c0>
    800055d8:	8552                	mv	a0,s4
    800055da:	fffff097          	auipc	ra,0xfffff
    800055de:	caa080e7          	jalr	-854(ra) # 80004284 <dirlink>
    800055e2:	04054463          	bltz	a0,8000562a <create+0x15a>
    800055e6:	40d0                	lw	a2,4(s1)
    800055e8:	00003597          	auipc	a1,0x3
    800055ec:	19858593          	add	a1,a1,408 # 80008780 <syscalls+0x2c8>
    800055f0:	8552                	mv	a0,s4
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	c92080e7          	jalr	-878(ra) # 80004284 <dirlink>
    800055fa:	02054863          	bltz	a0,8000562a <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800055fe:	004a2603          	lw	a2,4(s4)
    80005602:	fb040593          	add	a1,s0,-80
    80005606:	8526                	mv	a0,s1
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	c7c080e7          	jalr	-900(ra) # 80004284 <dirlink>
    80005610:	00054d63          	bltz	a0,8000562a <create+0x15a>
    dp->nlink++;  // for ".."
    80005614:	04a4d783          	lhu	a5,74(s1)
    80005618:	2785                	addw	a5,a5,1
    8000561a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000561e:	8526                	mv	a0,s1
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	4a4080e7          	jalr	1188(ra) # 80003ac4 <iupdate>
    80005628:	b761                	j	800055b0 <create+0xe0>
  ip->nlink = 0;
    8000562a:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000562e:	8552                	mv	a0,s4
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	494080e7          	jalr	1172(ra) # 80003ac4 <iupdate>
  iunlockput(ip);
    80005638:	8552                	mv	a0,s4
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	7b8080e7          	jalr	1976(ra) # 80003df2 <iunlockput>
  iunlockput(dp);
    80005642:	8526                	mv	a0,s1
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	7ae080e7          	jalr	1966(ra) # 80003df2 <iunlockput>
  return 0;
    8000564c:	bddd                	j	80005542 <create+0x72>
    return 0;
    8000564e:	8aaa                	mv	s5,a0
    80005650:	bdcd                	j	80005542 <create+0x72>

0000000080005652 <sys_dup>:
{
    80005652:	7179                	add	sp,sp,-48
    80005654:	f406                	sd	ra,40(sp)
    80005656:	f022                	sd	s0,32(sp)
    80005658:	ec26                	sd	s1,24(sp)
    8000565a:	e84a                	sd	s2,16(sp)
    8000565c:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000565e:	fd840613          	add	a2,s0,-40
    80005662:	4581                	li	a1,0
    80005664:	4501                	li	a0,0
    80005666:	00000097          	auipc	ra,0x0
    8000566a:	dc8080e7          	jalr	-568(ra) # 8000542e <argfd>
    return -1;
    8000566e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005670:	02054363          	bltz	a0,80005696 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005674:	fd843903          	ld	s2,-40(s0)
    80005678:	854a                	mv	a0,s2
    8000567a:	00000097          	auipc	ra,0x0
    8000567e:	e14080e7          	jalr	-492(ra) # 8000548e <fdalloc>
    80005682:	84aa                	mv	s1,a0
    return -1;
    80005684:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005686:	00054863          	bltz	a0,80005696 <sys_dup+0x44>
  filedup(f);
    8000568a:	854a                	mv	a0,s2
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	31c080e7          	jalr	796(ra) # 800049a8 <filedup>
  return fd;
    80005694:	87a6                	mv	a5,s1
}
    80005696:	853e                	mv	a0,a5
    80005698:	70a2                	ld	ra,40(sp)
    8000569a:	7402                	ld	s0,32(sp)
    8000569c:	64e2                	ld	s1,24(sp)
    8000569e:	6942                	ld	s2,16(sp)
    800056a0:	6145                	add	sp,sp,48
    800056a2:	8082                	ret

00000000800056a4 <sys_read>:
{
    800056a4:	7179                	add	sp,sp,-48
    800056a6:	f406                	sd	ra,40(sp)
    800056a8:	f022                	sd	s0,32(sp)
    800056aa:	1800                	add	s0,sp,48
  argaddr(1, &p);
    800056ac:	fd840593          	add	a1,s0,-40
    800056b0:	4505                	li	a0,1
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	8c4080e7          	jalr	-1852(ra) # 80002f76 <argaddr>
  argint(2, &n);
    800056ba:	fe440593          	add	a1,s0,-28
    800056be:	4509                	li	a0,2
    800056c0:	ffffe097          	auipc	ra,0xffffe
    800056c4:	896080e7          	jalr	-1898(ra) # 80002f56 <argint>
  if(argfd(0, 0, &f) < 0)
    800056c8:	fe840613          	add	a2,s0,-24
    800056cc:	4581                	li	a1,0
    800056ce:	4501                	li	a0,0
    800056d0:	00000097          	auipc	ra,0x0
    800056d4:	d5e080e7          	jalr	-674(ra) # 8000542e <argfd>
    800056d8:	87aa                	mv	a5,a0
    return -1;
    800056da:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056dc:	0007cc63          	bltz	a5,800056f4 <sys_read+0x50>
  return fileread(f, p, n);
    800056e0:	fe442603          	lw	a2,-28(s0)
    800056e4:	fd843583          	ld	a1,-40(s0)
    800056e8:	fe843503          	ld	a0,-24(s0)
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	448080e7          	jalr	1096(ra) # 80004b34 <fileread>
}
    800056f4:	70a2                	ld	ra,40(sp)
    800056f6:	7402                	ld	s0,32(sp)
    800056f8:	6145                	add	sp,sp,48
    800056fa:	8082                	ret

00000000800056fc <sys_write>:
{
    800056fc:	7179                	add	sp,sp,-48
    800056fe:	f406                	sd	ra,40(sp)
    80005700:	f022                	sd	s0,32(sp)
    80005702:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005704:	fd840593          	add	a1,s0,-40
    80005708:	4505                	li	a0,1
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	86c080e7          	jalr	-1940(ra) # 80002f76 <argaddr>
  argint(2, &n);
    80005712:	fe440593          	add	a1,s0,-28
    80005716:	4509                	li	a0,2
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	83e080e7          	jalr	-1986(ra) # 80002f56 <argint>
  if(argfd(0, 0, &f) < 0)
    80005720:	fe840613          	add	a2,s0,-24
    80005724:	4581                	li	a1,0
    80005726:	4501                	li	a0,0
    80005728:	00000097          	auipc	ra,0x0
    8000572c:	d06080e7          	jalr	-762(ra) # 8000542e <argfd>
    80005730:	87aa                	mv	a5,a0
    return -1;
    80005732:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005734:	0007cc63          	bltz	a5,8000574c <sys_write+0x50>
  return filewrite(f, p, n);
    80005738:	fe442603          	lw	a2,-28(s0)
    8000573c:	fd843583          	ld	a1,-40(s0)
    80005740:	fe843503          	ld	a0,-24(s0)
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	4b2080e7          	jalr	1202(ra) # 80004bf6 <filewrite>
}
    8000574c:	70a2                	ld	ra,40(sp)
    8000574e:	7402                	ld	s0,32(sp)
    80005750:	6145                	add	sp,sp,48
    80005752:	8082                	ret

0000000080005754 <sys_close>:
{
    80005754:	1101                	add	sp,sp,-32
    80005756:	ec06                	sd	ra,24(sp)
    80005758:	e822                	sd	s0,16(sp)
    8000575a:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000575c:	fe040613          	add	a2,s0,-32
    80005760:	fec40593          	add	a1,s0,-20
    80005764:	4501                	li	a0,0
    80005766:	00000097          	auipc	ra,0x0
    8000576a:	cc8080e7          	jalr	-824(ra) # 8000542e <argfd>
    return -1;
    8000576e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005770:	02054463          	bltz	a0,80005798 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005774:	ffffc097          	auipc	ra,0xffffc
    80005778:	3ea080e7          	jalr	1002(ra) # 80001b5e <myproc>
    8000577c:	fec42783          	lw	a5,-20(s0)
    80005780:	07e9                	add	a5,a5,26
    80005782:	078e                	sll	a5,a5,0x3
    80005784:	953e                	add	a0,a0,a5
    80005786:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000578a:	fe043503          	ld	a0,-32(s0)
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	26c080e7          	jalr	620(ra) # 800049fa <fileclose>
  return 0;
    80005796:	4781                	li	a5,0
}
    80005798:	853e                	mv	a0,a5
    8000579a:	60e2                	ld	ra,24(sp)
    8000579c:	6442                	ld	s0,16(sp)
    8000579e:	6105                	add	sp,sp,32
    800057a0:	8082                	ret

00000000800057a2 <sys_fstat>:
{
    800057a2:	1101                	add	sp,sp,-32
    800057a4:	ec06                	sd	ra,24(sp)
    800057a6:	e822                	sd	s0,16(sp)
    800057a8:	1000                	add	s0,sp,32
  argaddr(1, &st);
    800057aa:	fe040593          	add	a1,s0,-32
    800057ae:	4505                	li	a0,1
    800057b0:	ffffd097          	auipc	ra,0xffffd
    800057b4:	7c6080e7          	jalr	1990(ra) # 80002f76 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800057b8:	fe840613          	add	a2,s0,-24
    800057bc:	4581                	li	a1,0
    800057be:	4501                	li	a0,0
    800057c0:	00000097          	auipc	ra,0x0
    800057c4:	c6e080e7          	jalr	-914(ra) # 8000542e <argfd>
    800057c8:	87aa                	mv	a5,a0
    return -1;
    800057ca:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057cc:	0007ca63          	bltz	a5,800057e0 <sys_fstat+0x3e>
  return filestat(f, st);
    800057d0:	fe043583          	ld	a1,-32(s0)
    800057d4:	fe843503          	ld	a0,-24(s0)
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	2ea080e7          	jalr	746(ra) # 80004ac2 <filestat>
}
    800057e0:	60e2                	ld	ra,24(sp)
    800057e2:	6442                	ld	s0,16(sp)
    800057e4:	6105                	add	sp,sp,32
    800057e6:	8082                	ret

00000000800057e8 <sys_link>:
{
    800057e8:	7169                	add	sp,sp,-304
    800057ea:	f606                	sd	ra,296(sp)
    800057ec:	f222                	sd	s0,288(sp)
    800057ee:	ee26                	sd	s1,280(sp)
    800057f0:	ea4a                	sd	s2,272(sp)
    800057f2:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057f4:	08000613          	li	a2,128
    800057f8:	ed040593          	add	a1,s0,-304
    800057fc:	4501                	li	a0,0
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	798080e7          	jalr	1944(ra) # 80002f96 <argstr>
    return -1;
    80005806:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005808:	10054e63          	bltz	a0,80005924 <sys_link+0x13c>
    8000580c:	08000613          	li	a2,128
    80005810:	f5040593          	add	a1,s0,-176
    80005814:	4505                	li	a0,1
    80005816:	ffffd097          	auipc	ra,0xffffd
    8000581a:	780080e7          	jalr	1920(ra) # 80002f96 <argstr>
    return -1;
    8000581e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005820:	10054263          	bltz	a0,80005924 <sys_link+0x13c>
  begin_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	d12080e7          	jalr	-750(ra) # 80004536 <begin_op>
  if((ip = namei(old)) == 0){
    8000582c:	ed040513          	add	a0,s0,-304
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	b06080e7          	jalr	-1274(ra) # 80004336 <namei>
    80005838:	84aa                	mv	s1,a0
    8000583a:	c551                	beqz	a0,800058c6 <sys_link+0xde>
  ilock(ip);
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	354080e7          	jalr	852(ra) # 80003b90 <ilock>
  if(ip->type == T_DIR){
    80005844:	04449703          	lh	a4,68(s1)
    80005848:	4785                	li	a5,1
    8000584a:	08f70463          	beq	a4,a5,800058d2 <sys_link+0xea>
  ip->nlink++;
    8000584e:	04a4d783          	lhu	a5,74(s1)
    80005852:	2785                	addw	a5,a5,1
    80005854:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005858:	8526                	mv	a0,s1
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	26a080e7          	jalr	618(ra) # 80003ac4 <iupdate>
  iunlock(ip);
    80005862:	8526                	mv	a0,s1
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	3ee080e7          	jalr	1006(ra) # 80003c52 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000586c:	fd040593          	add	a1,s0,-48
    80005870:	f5040513          	add	a0,s0,-176
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	ae0080e7          	jalr	-1312(ra) # 80004354 <nameiparent>
    8000587c:	892a                	mv	s2,a0
    8000587e:	c935                	beqz	a0,800058f2 <sys_link+0x10a>
  ilock(dp);
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	310080e7          	jalr	784(ra) # 80003b90 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005888:	00092703          	lw	a4,0(s2)
    8000588c:	409c                	lw	a5,0(s1)
    8000588e:	04f71d63          	bne	a4,a5,800058e8 <sys_link+0x100>
    80005892:	40d0                	lw	a2,4(s1)
    80005894:	fd040593          	add	a1,s0,-48
    80005898:	854a                	mv	a0,s2
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	9ea080e7          	jalr	-1558(ra) # 80004284 <dirlink>
    800058a2:	04054363          	bltz	a0,800058e8 <sys_link+0x100>
  iunlockput(dp);
    800058a6:	854a                	mv	a0,s2
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	54a080e7          	jalr	1354(ra) # 80003df2 <iunlockput>
  iput(ip);
    800058b0:	8526                	mv	a0,s1
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	498080e7          	jalr	1176(ra) # 80003d4a <iput>
  end_op();
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	cf6080e7          	jalr	-778(ra) # 800045b0 <end_op>
  return 0;
    800058c2:	4781                	li	a5,0
    800058c4:	a085                	j	80005924 <sys_link+0x13c>
    end_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	cea080e7          	jalr	-790(ra) # 800045b0 <end_op>
    return -1;
    800058ce:	57fd                	li	a5,-1
    800058d0:	a891                	j	80005924 <sys_link+0x13c>
    iunlockput(ip);
    800058d2:	8526                	mv	a0,s1
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	51e080e7          	jalr	1310(ra) # 80003df2 <iunlockput>
    end_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	cd4080e7          	jalr	-812(ra) # 800045b0 <end_op>
    return -1;
    800058e4:	57fd                	li	a5,-1
    800058e6:	a83d                	j	80005924 <sys_link+0x13c>
    iunlockput(dp);
    800058e8:	854a                	mv	a0,s2
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	508080e7          	jalr	1288(ra) # 80003df2 <iunlockput>
  ilock(ip);
    800058f2:	8526                	mv	a0,s1
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	29c080e7          	jalr	668(ra) # 80003b90 <ilock>
  ip->nlink--;
    800058fc:	04a4d783          	lhu	a5,74(s1)
    80005900:	37fd                	addw	a5,a5,-1
    80005902:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005906:	8526                	mv	a0,s1
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	1bc080e7          	jalr	444(ra) # 80003ac4 <iupdate>
  iunlockput(ip);
    80005910:	8526                	mv	a0,s1
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	4e0080e7          	jalr	1248(ra) # 80003df2 <iunlockput>
  end_op();
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	c96080e7          	jalr	-874(ra) # 800045b0 <end_op>
  return -1;
    80005922:	57fd                	li	a5,-1
}
    80005924:	853e                	mv	a0,a5
    80005926:	70b2                	ld	ra,296(sp)
    80005928:	7412                	ld	s0,288(sp)
    8000592a:	64f2                	ld	s1,280(sp)
    8000592c:	6952                	ld	s2,272(sp)
    8000592e:	6155                	add	sp,sp,304
    80005930:	8082                	ret

0000000080005932 <sys_unlink>:
{
    80005932:	7151                	add	sp,sp,-240
    80005934:	f586                	sd	ra,232(sp)
    80005936:	f1a2                	sd	s0,224(sp)
    80005938:	eda6                	sd	s1,216(sp)
    8000593a:	e9ca                	sd	s2,208(sp)
    8000593c:	e5ce                	sd	s3,200(sp)
    8000593e:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005940:	08000613          	li	a2,128
    80005944:	f3040593          	add	a1,s0,-208
    80005948:	4501                	li	a0,0
    8000594a:	ffffd097          	auipc	ra,0xffffd
    8000594e:	64c080e7          	jalr	1612(ra) # 80002f96 <argstr>
    80005952:	18054163          	bltz	a0,80005ad4 <sys_unlink+0x1a2>
  begin_op();
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	be0080e7          	jalr	-1056(ra) # 80004536 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000595e:	fb040593          	add	a1,s0,-80
    80005962:	f3040513          	add	a0,s0,-208
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	9ee080e7          	jalr	-1554(ra) # 80004354 <nameiparent>
    8000596e:	84aa                	mv	s1,a0
    80005970:	c979                	beqz	a0,80005a46 <sys_unlink+0x114>
  ilock(dp);
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	21e080e7          	jalr	542(ra) # 80003b90 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000597a:	00003597          	auipc	a1,0x3
    8000597e:	dfe58593          	add	a1,a1,-514 # 80008778 <syscalls+0x2c0>
    80005982:	fb040513          	add	a0,s0,-80
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	6d4080e7          	jalr	1748(ra) # 8000405a <namecmp>
    8000598e:	14050a63          	beqz	a0,80005ae2 <sys_unlink+0x1b0>
    80005992:	00003597          	auipc	a1,0x3
    80005996:	dee58593          	add	a1,a1,-530 # 80008780 <syscalls+0x2c8>
    8000599a:	fb040513          	add	a0,s0,-80
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	6bc080e7          	jalr	1724(ra) # 8000405a <namecmp>
    800059a6:	12050e63          	beqz	a0,80005ae2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059aa:	f2c40613          	add	a2,s0,-212
    800059ae:	fb040593          	add	a1,s0,-80
    800059b2:	8526                	mv	a0,s1
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	6c0080e7          	jalr	1728(ra) # 80004074 <dirlookup>
    800059bc:	892a                	mv	s2,a0
    800059be:	12050263          	beqz	a0,80005ae2 <sys_unlink+0x1b0>
  ilock(ip);
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	1ce080e7          	jalr	462(ra) # 80003b90 <ilock>
  if(ip->nlink < 1)
    800059ca:	04a91783          	lh	a5,74(s2)
    800059ce:	08f05263          	blez	a5,80005a52 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059d2:	04491703          	lh	a4,68(s2)
    800059d6:	4785                	li	a5,1
    800059d8:	08f70563          	beq	a4,a5,80005a62 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059dc:	4641                	li	a2,16
    800059de:	4581                	li	a1,0
    800059e0:	fc040513          	add	a0,s0,-64
    800059e4:	ffffb097          	auipc	ra,0xffffb
    800059e8:	2ea080e7          	jalr	746(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059ec:	4741                	li	a4,16
    800059ee:	f2c42683          	lw	a3,-212(s0)
    800059f2:	fc040613          	add	a2,s0,-64
    800059f6:	4581                	li	a1,0
    800059f8:	8526                	mv	a0,s1
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	542080e7          	jalr	1346(ra) # 80003f3c <writei>
    80005a02:	47c1                	li	a5,16
    80005a04:	0af51563          	bne	a0,a5,80005aae <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a08:	04491703          	lh	a4,68(s2)
    80005a0c:	4785                	li	a5,1
    80005a0e:	0af70863          	beq	a4,a5,80005abe <sys_unlink+0x18c>
  iunlockput(dp);
    80005a12:	8526                	mv	a0,s1
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	3de080e7          	jalr	990(ra) # 80003df2 <iunlockput>
  ip->nlink--;
    80005a1c:	04a95783          	lhu	a5,74(s2)
    80005a20:	37fd                	addw	a5,a5,-1
    80005a22:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a26:	854a                	mv	a0,s2
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	09c080e7          	jalr	156(ra) # 80003ac4 <iupdate>
  iunlockput(ip);
    80005a30:	854a                	mv	a0,s2
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	3c0080e7          	jalr	960(ra) # 80003df2 <iunlockput>
  end_op();
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	b76080e7          	jalr	-1162(ra) # 800045b0 <end_op>
  return 0;
    80005a42:	4501                	li	a0,0
    80005a44:	a84d                	j	80005af6 <sys_unlink+0x1c4>
    end_op();
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	b6a080e7          	jalr	-1174(ra) # 800045b0 <end_op>
    return -1;
    80005a4e:	557d                	li	a0,-1
    80005a50:	a05d                	j	80005af6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a52:	00003517          	auipc	a0,0x3
    80005a56:	d3650513          	add	a0,a0,-714 # 80008788 <syscalls+0x2d0>
    80005a5a:	ffffb097          	auipc	ra,0xffffb
    80005a5e:	ae2080e7          	jalr	-1310(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a62:	04c92703          	lw	a4,76(s2)
    80005a66:	02000793          	li	a5,32
    80005a6a:	f6e7f9e3          	bgeu	a5,a4,800059dc <sys_unlink+0xaa>
    80005a6e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a72:	4741                	li	a4,16
    80005a74:	86ce                	mv	a3,s3
    80005a76:	f1840613          	add	a2,s0,-232
    80005a7a:	4581                	li	a1,0
    80005a7c:	854a                	mv	a0,s2
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	3c6080e7          	jalr	966(ra) # 80003e44 <readi>
    80005a86:	47c1                	li	a5,16
    80005a88:	00f51b63          	bne	a0,a5,80005a9e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a8c:	f1845783          	lhu	a5,-232(s0)
    80005a90:	e7a1                	bnez	a5,80005ad8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a92:	29c1                	addw	s3,s3,16
    80005a94:	04c92783          	lw	a5,76(s2)
    80005a98:	fcf9ede3          	bltu	s3,a5,80005a72 <sys_unlink+0x140>
    80005a9c:	b781                	j	800059dc <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a9e:	00003517          	auipc	a0,0x3
    80005aa2:	d0250513          	add	a0,a0,-766 # 800087a0 <syscalls+0x2e8>
    80005aa6:	ffffb097          	auipc	ra,0xffffb
    80005aaa:	a96080e7          	jalr	-1386(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005aae:	00003517          	auipc	a0,0x3
    80005ab2:	d0a50513          	add	a0,a0,-758 # 800087b8 <syscalls+0x300>
    80005ab6:	ffffb097          	auipc	ra,0xffffb
    80005aba:	a86080e7          	jalr	-1402(ra) # 8000053c <panic>
    dp->nlink--;
    80005abe:	04a4d783          	lhu	a5,74(s1)
    80005ac2:	37fd                	addw	a5,a5,-1
    80005ac4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ac8:	8526                	mv	a0,s1
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	ffa080e7          	jalr	-6(ra) # 80003ac4 <iupdate>
    80005ad2:	b781                	j	80005a12 <sys_unlink+0xe0>
    return -1;
    80005ad4:	557d                	li	a0,-1
    80005ad6:	a005                	j	80005af6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ad8:	854a                	mv	a0,s2
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	318080e7          	jalr	792(ra) # 80003df2 <iunlockput>
  iunlockput(dp);
    80005ae2:	8526                	mv	a0,s1
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	30e080e7          	jalr	782(ra) # 80003df2 <iunlockput>
  end_op();
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	ac4080e7          	jalr	-1340(ra) # 800045b0 <end_op>
  return -1;
    80005af4:	557d                	li	a0,-1
}
    80005af6:	70ae                	ld	ra,232(sp)
    80005af8:	740e                	ld	s0,224(sp)
    80005afa:	64ee                	ld	s1,216(sp)
    80005afc:	694e                	ld	s2,208(sp)
    80005afe:	69ae                	ld	s3,200(sp)
    80005b00:	616d                	add	sp,sp,240
    80005b02:	8082                	ret

0000000080005b04 <sys_open>:

uint64
sys_open(void)
{
    80005b04:	7131                	add	sp,sp,-192
    80005b06:	fd06                	sd	ra,184(sp)
    80005b08:	f922                	sd	s0,176(sp)
    80005b0a:	f526                	sd	s1,168(sp)
    80005b0c:	f14a                	sd	s2,160(sp)
    80005b0e:	ed4e                	sd	s3,152(sp)
    80005b10:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005b12:	f4c40593          	add	a1,s0,-180
    80005b16:	4505                	li	a0,1
    80005b18:	ffffd097          	auipc	ra,0xffffd
    80005b1c:	43e080e7          	jalr	1086(ra) # 80002f56 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b20:	08000613          	li	a2,128
    80005b24:	f5040593          	add	a1,s0,-176
    80005b28:	4501                	li	a0,0
    80005b2a:	ffffd097          	auipc	ra,0xffffd
    80005b2e:	46c080e7          	jalr	1132(ra) # 80002f96 <argstr>
    80005b32:	87aa                	mv	a5,a0
    return -1;
    80005b34:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b36:	0a07c863          	bltz	a5,80005be6 <sys_open+0xe2>

  begin_op();
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	9fc080e7          	jalr	-1540(ra) # 80004536 <begin_op>

  if(omode & O_CREATE){
    80005b42:	f4c42783          	lw	a5,-180(s0)
    80005b46:	2007f793          	and	a5,a5,512
    80005b4a:	cbdd                	beqz	a5,80005c00 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005b4c:	4681                	li	a3,0
    80005b4e:	4601                	li	a2,0
    80005b50:	4589                	li	a1,2
    80005b52:	f5040513          	add	a0,s0,-176
    80005b56:	00000097          	auipc	ra,0x0
    80005b5a:	97a080e7          	jalr	-1670(ra) # 800054d0 <create>
    80005b5e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b60:	c951                	beqz	a0,80005bf4 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b62:	04449703          	lh	a4,68(s1)
    80005b66:	478d                	li	a5,3
    80005b68:	00f71763          	bne	a4,a5,80005b76 <sys_open+0x72>
    80005b6c:	0464d703          	lhu	a4,70(s1)
    80005b70:	47a5                	li	a5,9
    80005b72:	0ce7ec63          	bltu	a5,a4,80005c4a <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	dc8080e7          	jalr	-568(ra) # 8000493e <filealloc>
    80005b7e:	892a                	mv	s2,a0
    80005b80:	c56d                	beqz	a0,80005c6a <sys_open+0x166>
    80005b82:	00000097          	auipc	ra,0x0
    80005b86:	90c080e7          	jalr	-1780(ra) # 8000548e <fdalloc>
    80005b8a:	89aa                	mv	s3,a0
    80005b8c:	0c054a63          	bltz	a0,80005c60 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b90:	04449703          	lh	a4,68(s1)
    80005b94:	478d                	li	a5,3
    80005b96:	0ef70563          	beq	a4,a5,80005c80 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b9a:	4789                	li	a5,2
    80005b9c:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005ba0:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005ba4:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005ba8:	f4c42783          	lw	a5,-180(s0)
    80005bac:	0017c713          	xor	a4,a5,1
    80005bb0:	8b05                	and	a4,a4,1
    80005bb2:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bb6:	0037f713          	and	a4,a5,3
    80005bba:	00e03733          	snez	a4,a4
    80005bbe:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bc2:	4007f793          	and	a5,a5,1024
    80005bc6:	c791                	beqz	a5,80005bd2 <sys_open+0xce>
    80005bc8:	04449703          	lh	a4,68(s1)
    80005bcc:	4789                	li	a5,2
    80005bce:	0cf70063          	beq	a4,a5,80005c8e <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005bd2:	8526                	mv	a0,s1
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	07e080e7          	jalr	126(ra) # 80003c52 <iunlock>
  end_op();
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	9d4080e7          	jalr	-1580(ra) # 800045b0 <end_op>

  return fd;
    80005be4:	854e                	mv	a0,s3
}
    80005be6:	70ea                	ld	ra,184(sp)
    80005be8:	744a                	ld	s0,176(sp)
    80005bea:	74aa                	ld	s1,168(sp)
    80005bec:	790a                	ld	s2,160(sp)
    80005bee:	69ea                	ld	s3,152(sp)
    80005bf0:	6129                	add	sp,sp,192
    80005bf2:	8082                	ret
      end_op();
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	9bc080e7          	jalr	-1604(ra) # 800045b0 <end_op>
      return -1;
    80005bfc:	557d                	li	a0,-1
    80005bfe:	b7e5                	j	80005be6 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005c00:	f5040513          	add	a0,s0,-176
    80005c04:	ffffe097          	auipc	ra,0xffffe
    80005c08:	732080e7          	jalr	1842(ra) # 80004336 <namei>
    80005c0c:	84aa                	mv	s1,a0
    80005c0e:	c905                	beqz	a0,80005c3e <sys_open+0x13a>
    ilock(ip);
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	f80080e7          	jalr	-128(ra) # 80003b90 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c18:	04449703          	lh	a4,68(s1)
    80005c1c:	4785                	li	a5,1
    80005c1e:	f4f712e3          	bne	a4,a5,80005b62 <sys_open+0x5e>
    80005c22:	f4c42783          	lw	a5,-180(s0)
    80005c26:	dba1                	beqz	a5,80005b76 <sys_open+0x72>
      iunlockput(ip);
    80005c28:	8526                	mv	a0,s1
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	1c8080e7          	jalr	456(ra) # 80003df2 <iunlockput>
      end_op();
    80005c32:	fffff097          	auipc	ra,0xfffff
    80005c36:	97e080e7          	jalr	-1666(ra) # 800045b0 <end_op>
      return -1;
    80005c3a:	557d                	li	a0,-1
    80005c3c:	b76d                	j	80005be6 <sys_open+0xe2>
      end_op();
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	972080e7          	jalr	-1678(ra) # 800045b0 <end_op>
      return -1;
    80005c46:	557d                	li	a0,-1
    80005c48:	bf79                	j	80005be6 <sys_open+0xe2>
    iunlockput(ip);
    80005c4a:	8526                	mv	a0,s1
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	1a6080e7          	jalr	422(ra) # 80003df2 <iunlockput>
    end_op();
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	95c080e7          	jalr	-1700(ra) # 800045b0 <end_op>
    return -1;
    80005c5c:	557d                	li	a0,-1
    80005c5e:	b761                	j	80005be6 <sys_open+0xe2>
      fileclose(f);
    80005c60:	854a                	mv	a0,s2
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	d98080e7          	jalr	-616(ra) # 800049fa <fileclose>
    iunlockput(ip);
    80005c6a:	8526                	mv	a0,s1
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	186080e7          	jalr	390(ra) # 80003df2 <iunlockput>
    end_op();
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	93c080e7          	jalr	-1732(ra) # 800045b0 <end_op>
    return -1;
    80005c7c:	557d                	li	a0,-1
    80005c7e:	b7a5                	j	80005be6 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005c80:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005c84:	04649783          	lh	a5,70(s1)
    80005c88:	02f91223          	sh	a5,36(s2)
    80005c8c:	bf21                	j	80005ba4 <sys_open+0xa0>
    itrunc(ip);
    80005c8e:	8526                	mv	a0,s1
    80005c90:	ffffe097          	auipc	ra,0xffffe
    80005c94:	00e080e7          	jalr	14(ra) # 80003c9e <itrunc>
    80005c98:	bf2d                	j	80005bd2 <sys_open+0xce>

0000000080005c9a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c9a:	7175                	add	sp,sp,-144
    80005c9c:	e506                	sd	ra,136(sp)
    80005c9e:	e122                	sd	s0,128(sp)
    80005ca0:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	894080e7          	jalr	-1900(ra) # 80004536 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005caa:	08000613          	li	a2,128
    80005cae:	f7040593          	add	a1,s0,-144
    80005cb2:	4501                	li	a0,0
    80005cb4:	ffffd097          	auipc	ra,0xffffd
    80005cb8:	2e2080e7          	jalr	738(ra) # 80002f96 <argstr>
    80005cbc:	02054963          	bltz	a0,80005cee <sys_mkdir+0x54>
    80005cc0:	4681                	li	a3,0
    80005cc2:	4601                	li	a2,0
    80005cc4:	4585                	li	a1,1
    80005cc6:	f7040513          	add	a0,s0,-144
    80005cca:	00000097          	auipc	ra,0x0
    80005cce:	806080e7          	jalr	-2042(ra) # 800054d0 <create>
    80005cd2:	cd11                	beqz	a0,80005cee <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cd4:	ffffe097          	auipc	ra,0xffffe
    80005cd8:	11e080e7          	jalr	286(ra) # 80003df2 <iunlockput>
  end_op();
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	8d4080e7          	jalr	-1836(ra) # 800045b0 <end_op>
  return 0;
    80005ce4:	4501                	li	a0,0
}
    80005ce6:	60aa                	ld	ra,136(sp)
    80005ce8:	640a                	ld	s0,128(sp)
    80005cea:	6149                	add	sp,sp,144
    80005cec:	8082                	ret
    end_op();
    80005cee:	fffff097          	auipc	ra,0xfffff
    80005cf2:	8c2080e7          	jalr	-1854(ra) # 800045b0 <end_op>
    return -1;
    80005cf6:	557d                	li	a0,-1
    80005cf8:	b7fd                	j	80005ce6 <sys_mkdir+0x4c>

0000000080005cfa <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cfa:	7135                	add	sp,sp,-160
    80005cfc:	ed06                	sd	ra,152(sp)
    80005cfe:	e922                	sd	s0,144(sp)
    80005d00:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	834080e7          	jalr	-1996(ra) # 80004536 <begin_op>
  argint(1, &major);
    80005d0a:	f6c40593          	add	a1,s0,-148
    80005d0e:	4505                	li	a0,1
    80005d10:	ffffd097          	auipc	ra,0xffffd
    80005d14:	246080e7          	jalr	582(ra) # 80002f56 <argint>
  argint(2, &minor);
    80005d18:	f6840593          	add	a1,s0,-152
    80005d1c:	4509                	li	a0,2
    80005d1e:	ffffd097          	auipc	ra,0xffffd
    80005d22:	238080e7          	jalr	568(ra) # 80002f56 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d26:	08000613          	li	a2,128
    80005d2a:	f7040593          	add	a1,s0,-144
    80005d2e:	4501                	li	a0,0
    80005d30:	ffffd097          	auipc	ra,0xffffd
    80005d34:	266080e7          	jalr	614(ra) # 80002f96 <argstr>
    80005d38:	02054b63          	bltz	a0,80005d6e <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d3c:	f6841683          	lh	a3,-152(s0)
    80005d40:	f6c41603          	lh	a2,-148(s0)
    80005d44:	458d                	li	a1,3
    80005d46:	f7040513          	add	a0,s0,-144
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	786080e7          	jalr	1926(ra) # 800054d0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d52:	cd11                	beqz	a0,80005d6e <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d54:	ffffe097          	auipc	ra,0xffffe
    80005d58:	09e080e7          	jalr	158(ra) # 80003df2 <iunlockput>
  end_op();
    80005d5c:	fffff097          	auipc	ra,0xfffff
    80005d60:	854080e7          	jalr	-1964(ra) # 800045b0 <end_op>
  return 0;
    80005d64:	4501                	li	a0,0
}
    80005d66:	60ea                	ld	ra,152(sp)
    80005d68:	644a                	ld	s0,144(sp)
    80005d6a:	610d                	add	sp,sp,160
    80005d6c:	8082                	ret
    end_op();
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	842080e7          	jalr	-1982(ra) # 800045b0 <end_op>
    return -1;
    80005d76:	557d                	li	a0,-1
    80005d78:	b7fd                	j	80005d66 <sys_mknod+0x6c>

0000000080005d7a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d7a:	7135                	add	sp,sp,-160
    80005d7c:	ed06                	sd	ra,152(sp)
    80005d7e:	e922                	sd	s0,144(sp)
    80005d80:	e526                	sd	s1,136(sp)
    80005d82:	e14a                	sd	s2,128(sp)
    80005d84:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d86:	ffffc097          	auipc	ra,0xffffc
    80005d8a:	dd8080e7          	jalr	-552(ra) # 80001b5e <myproc>
    80005d8e:	892a                	mv	s2,a0
  
  begin_op();
    80005d90:	ffffe097          	auipc	ra,0xffffe
    80005d94:	7a6080e7          	jalr	1958(ra) # 80004536 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d98:	08000613          	li	a2,128
    80005d9c:	f6040593          	add	a1,s0,-160
    80005da0:	4501                	li	a0,0
    80005da2:	ffffd097          	auipc	ra,0xffffd
    80005da6:	1f4080e7          	jalr	500(ra) # 80002f96 <argstr>
    80005daa:	04054b63          	bltz	a0,80005e00 <sys_chdir+0x86>
    80005dae:	f6040513          	add	a0,s0,-160
    80005db2:	ffffe097          	auipc	ra,0xffffe
    80005db6:	584080e7          	jalr	1412(ra) # 80004336 <namei>
    80005dba:	84aa                	mv	s1,a0
    80005dbc:	c131                	beqz	a0,80005e00 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	dd2080e7          	jalr	-558(ra) # 80003b90 <ilock>
  if(ip->type != T_DIR){
    80005dc6:	04449703          	lh	a4,68(s1)
    80005dca:	4785                	li	a5,1
    80005dcc:	04f71063          	bne	a4,a5,80005e0c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005dd0:	8526                	mv	a0,s1
    80005dd2:	ffffe097          	auipc	ra,0xffffe
    80005dd6:	e80080e7          	jalr	-384(ra) # 80003c52 <iunlock>
  iput(p->cwd);
    80005dda:	15093503          	ld	a0,336(s2)
    80005dde:	ffffe097          	auipc	ra,0xffffe
    80005de2:	f6c080e7          	jalr	-148(ra) # 80003d4a <iput>
  end_op();
    80005de6:	ffffe097          	auipc	ra,0xffffe
    80005dea:	7ca080e7          	jalr	1994(ra) # 800045b0 <end_op>
  p->cwd = ip;
    80005dee:	14993823          	sd	s1,336(s2)
  return 0;
    80005df2:	4501                	li	a0,0
}
    80005df4:	60ea                	ld	ra,152(sp)
    80005df6:	644a                	ld	s0,144(sp)
    80005df8:	64aa                	ld	s1,136(sp)
    80005dfa:	690a                	ld	s2,128(sp)
    80005dfc:	610d                	add	sp,sp,160
    80005dfe:	8082                	ret
    end_op();
    80005e00:	ffffe097          	auipc	ra,0xffffe
    80005e04:	7b0080e7          	jalr	1968(ra) # 800045b0 <end_op>
    return -1;
    80005e08:	557d                	li	a0,-1
    80005e0a:	b7ed                	j	80005df4 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e0c:	8526                	mv	a0,s1
    80005e0e:	ffffe097          	auipc	ra,0xffffe
    80005e12:	fe4080e7          	jalr	-28(ra) # 80003df2 <iunlockput>
    end_op();
    80005e16:	ffffe097          	auipc	ra,0xffffe
    80005e1a:	79a080e7          	jalr	1946(ra) # 800045b0 <end_op>
    return -1;
    80005e1e:	557d                	li	a0,-1
    80005e20:	bfd1                	j	80005df4 <sys_chdir+0x7a>

0000000080005e22 <sys_exec>:

uint64
sys_exec(void)
{
    80005e22:	7121                	add	sp,sp,-448
    80005e24:	ff06                	sd	ra,440(sp)
    80005e26:	fb22                	sd	s0,432(sp)
    80005e28:	f726                	sd	s1,424(sp)
    80005e2a:	f34a                	sd	s2,416(sp)
    80005e2c:	ef4e                	sd	s3,408(sp)
    80005e2e:	eb52                	sd	s4,400(sp)
    80005e30:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005e32:	e4840593          	add	a1,s0,-440
    80005e36:	4505                	li	a0,1
    80005e38:	ffffd097          	auipc	ra,0xffffd
    80005e3c:	13e080e7          	jalr	318(ra) # 80002f76 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005e40:	08000613          	li	a2,128
    80005e44:	f5040593          	add	a1,s0,-176
    80005e48:	4501                	li	a0,0
    80005e4a:	ffffd097          	auipc	ra,0xffffd
    80005e4e:	14c080e7          	jalr	332(ra) # 80002f96 <argstr>
    80005e52:	87aa                	mv	a5,a0
    return -1;
    80005e54:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e56:	0c07c263          	bltz	a5,80005f1a <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005e5a:	10000613          	li	a2,256
    80005e5e:	4581                	li	a1,0
    80005e60:	e5040513          	add	a0,s0,-432
    80005e64:	ffffb097          	auipc	ra,0xffffb
    80005e68:	e6a080e7          	jalr	-406(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e6c:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005e70:	89a6                	mv	s3,s1
    80005e72:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e74:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e78:	00391513          	sll	a0,s2,0x3
    80005e7c:	e4040593          	add	a1,s0,-448
    80005e80:	e4843783          	ld	a5,-440(s0)
    80005e84:	953e                	add	a0,a0,a5
    80005e86:	ffffd097          	auipc	ra,0xffffd
    80005e8a:	032080e7          	jalr	50(ra) # 80002eb8 <fetchaddr>
    80005e8e:	02054a63          	bltz	a0,80005ec2 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005e92:	e4043783          	ld	a5,-448(s0)
    80005e96:	c3b9                	beqz	a5,80005edc <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e98:	ffffb097          	auipc	ra,0xffffb
    80005e9c:	c4a080e7          	jalr	-950(ra) # 80000ae2 <kalloc>
    80005ea0:	85aa                	mv	a1,a0
    80005ea2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ea6:	cd11                	beqz	a0,80005ec2 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ea8:	6605                	lui	a2,0x1
    80005eaa:	e4043503          	ld	a0,-448(s0)
    80005eae:	ffffd097          	auipc	ra,0xffffd
    80005eb2:	05c080e7          	jalr	92(ra) # 80002f0a <fetchstr>
    80005eb6:	00054663          	bltz	a0,80005ec2 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005eba:	0905                	add	s2,s2,1
    80005ebc:	09a1                	add	s3,s3,8
    80005ebe:	fb491de3          	bne	s2,s4,80005e78 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ec2:	f5040913          	add	s2,s0,-176
    80005ec6:	6088                	ld	a0,0(s1)
    80005ec8:	c921                	beqz	a0,80005f18 <sys_exec+0xf6>
    kfree(argv[i]);
    80005eca:	ffffb097          	auipc	ra,0xffffb
    80005ece:	b1a080e7          	jalr	-1254(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ed2:	04a1                	add	s1,s1,8
    80005ed4:	ff2499e3          	bne	s1,s2,80005ec6 <sys_exec+0xa4>
  return -1;
    80005ed8:	557d                	li	a0,-1
    80005eda:	a081                	j	80005f1a <sys_exec+0xf8>
      argv[i] = 0;
    80005edc:	0009079b          	sext.w	a5,s2
    80005ee0:	078e                	sll	a5,a5,0x3
    80005ee2:	fd078793          	add	a5,a5,-48
    80005ee6:	97a2                	add	a5,a5,s0
    80005ee8:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005eec:	e5040593          	add	a1,s0,-432
    80005ef0:	f5040513          	add	a0,s0,-176
    80005ef4:	fffff097          	auipc	ra,0xfffff
    80005ef8:	17c080e7          	jalr	380(ra) # 80005070 <exec>
    80005efc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005efe:	f5040993          	add	s3,s0,-176
    80005f02:	6088                	ld	a0,0(s1)
    80005f04:	c901                	beqz	a0,80005f14 <sys_exec+0xf2>
    kfree(argv[i]);
    80005f06:	ffffb097          	auipc	ra,0xffffb
    80005f0a:	ade080e7          	jalr	-1314(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f0e:	04a1                	add	s1,s1,8
    80005f10:	ff3499e3          	bne	s1,s3,80005f02 <sys_exec+0xe0>
  return ret;
    80005f14:	854a                	mv	a0,s2
    80005f16:	a011                	j	80005f1a <sys_exec+0xf8>
  return -1;
    80005f18:	557d                	li	a0,-1
}
    80005f1a:	70fa                	ld	ra,440(sp)
    80005f1c:	745a                	ld	s0,432(sp)
    80005f1e:	74ba                	ld	s1,424(sp)
    80005f20:	791a                	ld	s2,416(sp)
    80005f22:	69fa                	ld	s3,408(sp)
    80005f24:	6a5a                	ld	s4,400(sp)
    80005f26:	6139                	add	sp,sp,448
    80005f28:	8082                	ret

0000000080005f2a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f2a:	7139                	add	sp,sp,-64
    80005f2c:	fc06                	sd	ra,56(sp)
    80005f2e:	f822                	sd	s0,48(sp)
    80005f30:	f426                	sd	s1,40(sp)
    80005f32:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f34:	ffffc097          	auipc	ra,0xffffc
    80005f38:	c2a080e7          	jalr	-982(ra) # 80001b5e <myproc>
    80005f3c:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005f3e:	fd840593          	add	a1,s0,-40
    80005f42:	4501                	li	a0,0
    80005f44:	ffffd097          	auipc	ra,0xffffd
    80005f48:	032080e7          	jalr	50(ra) # 80002f76 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005f4c:	fc840593          	add	a1,s0,-56
    80005f50:	fd040513          	add	a0,s0,-48
    80005f54:	fffff097          	auipc	ra,0xfffff
    80005f58:	dd2080e7          	jalr	-558(ra) # 80004d26 <pipealloc>
    return -1;
    80005f5c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f5e:	0c054463          	bltz	a0,80006026 <sys_pipe+0xfc>
  fd0 = -1;
    80005f62:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f66:	fd043503          	ld	a0,-48(s0)
    80005f6a:	fffff097          	auipc	ra,0xfffff
    80005f6e:	524080e7          	jalr	1316(ra) # 8000548e <fdalloc>
    80005f72:	fca42223          	sw	a0,-60(s0)
    80005f76:	08054b63          	bltz	a0,8000600c <sys_pipe+0xe2>
    80005f7a:	fc843503          	ld	a0,-56(s0)
    80005f7e:	fffff097          	auipc	ra,0xfffff
    80005f82:	510080e7          	jalr	1296(ra) # 8000548e <fdalloc>
    80005f86:	fca42023          	sw	a0,-64(s0)
    80005f8a:	06054863          	bltz	a0,80005ffa <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f8e:	4691                	li	a3,4
    80005f90:	fc440613          	add	a2,s0,-60
    80005f94:	fd843583          	ld	a1,-40(s0)
    80005f98:	68a8                	ld	a0,80(s1)
    80005f9a:	ffffb097          	auipc	ra,0xffffb
    80005f9e:	6cc080e7          	jalr	1740(ra) # 80001666 <copyout>
    80005fa2:	02054063          	bltz	a0,80005fc2 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fa6:	4691                	li	a3,4
    80005fa8:	fc040613          	add	a2,s0,-64
    80005fac:	fd843583          	ld	a1,-40(s0)
    80005fb0:	0591                	add	a1,a1,4
    80005fb2:	68a8                	ld	a0,80(s1)
    80005fb4:	ffffb097          	auipc	ra,0xffffb
    80005fb8:	6b2080e7          	jalr	1714(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fbc:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fbe:	06055463          	bgez	a0,80006026 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005fc2:	fc442783          	lw	a5,-60(s0)
    80005fc6:	07e9                	add	a5,a5,26
    80005fc8:	078e                	sll	a5,a5,0x3
    80005fca:	97a6                	add	a5,a5,s1
    80005fcc:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fd0:	fc042783          	lw	a5,-64(s0)
    80005fd4:	07e9                	add	a5,a5,26
    80005fd6:	078e                	sll	a5,a5,0x3
    80005fd8:	94be                	add	s1,s1,a5
    80005fda:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005fde:	fd043503          	ld	a0,-48(s0)
    80005fe2:	fffff097          	auipc	ra,0xfffff
    80005fe6:	a18080e7          	jalr	-1512(ra) # 800049fa <fileclose>
    fileclose(wf);
    80005fea:	fc843503          	ld	a0,-56(s0)
    80005fee:	fffff097          	auipc	ra,0xfffff
    80005ff2:	a0c080e7          	jalr	-1524(ra) # 800049fa <fileclose>
    return -1;
    80005ff6:	57fd                	li	a5,-1
    80005ff8:	a03d                	j	80006026 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005ffa:	fc442783          	lw	a5,-60(s0)
    80005ffe:	0007c763          	bltz	a5,8000600c <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006002:	07e9                	add	a5,a5,26
    80006004:	078e                	sll	a5,a5,0x3
    80006006:	97a6                	add	a5,a5,s1
    80006008:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    8000600c:	fd043503          	ld	a0,-48(s0)
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	9ea080e7          	jalr	-1558(ra) # 800049fa <fileclose>
    fileclose(wf);
    80006018:	fc843503          	ld	a0,-56(s0)
    8000601c:	fffff097          	auipc	ra,0xfffff
    80006020:	9de080e7          	jalr	-1570(ra) # 800049fa <fileclose>
    return -1;
    80006024:	57fd                	li	a5,-1
}
    80006026:	853e                	mv	a0,a5
    80006028:	70e2                	ld	ra,56(sp)
    8000602a:	7442                	ld	s0,48(sp)
    8000602c:	74a2                	ld	s1,40(sp)
    8000602e:	6121                	add	sp,sp,64
    80006030:	8082                	ret
	...

0000000080006040 <kernelvec>:
    80006040:	7111                	add	sp,sp,-256
    80006042:	e006                	sd	ra,0(sp)
    80006044:	e40a                	sd	sp,8(sp)
    80006046:	e80e                	sd	gp,16(sp)
    80006048:	ec12                	sd	tp,24(sp)
    8000604a:	f016                	sd	t0,32(sp)
    8000604c:	f41a                	sd	t1,40(sp)
    8000604e:	f81e                	sd	t2,48(sp)
    80006050:	fc22                	sd	s0,56(sp)
    80006052:	e0a6                	sd	s1,64(sp)
    80006054:	e4aa                	sd	a0,72(sp)
    80006056:	e8ae                	sd	a1,80(sp)
    80006058:	ecb2                	sd	a2,88(sp)
    8000605a:	f0b6                	sd	a3,96(sp)
    8000605c:	f4ba                	sd	a4,104(sp)
    8000605e:	f8be                	sd	a5,112(sp)
    80006060:	fcc2                	sd	a6,120(sp)
    80006062:	e146                	sd	a7,128(sp)
    80006064:	e54a                	sd	s2,136(sp)
    80006066:	e94e                	sd	s3,144(sp)
    80006068:	ed52                	sd	s4,152(sp)
    8000606a:	f156                	sd	s5,160(sp)
    8000606c:	f55a                	sd	s6,168(sp)
    8000606e:	f95e                	sd	s7,176(sp)
    80006070:	fd62                	sd	s8,184(sp)
    80006072:	e1e6                	sd	s9,192(sp)
    80006074:	e5ea                	sd	s10,200(sp)
    80006076:	e9ee                	sd	s11,208(sp)
    80006078:	edf2                	sd	t3,216(sp)
    8000607a:	f1f6                	sd	t4,224(sp)
    8000607c:	f5fa                	sd	t5,232(sp)
    8000607e:	f9fe                	sd	t6,240(sp)
    80006080:	d05fc0ef          	jal	80002d84 <kerneltrap>
    80006084:	6082                	ld	ra,0(sp)
    80006086:	6122                	ld	sp,8(sp)
    80006088:	61c2                	ld	gp,16(sp)
    8000608a:	7282                	ld	t0,32(sp)
    8000608c:	7322                	ld	t1,40(sp)
    8000608e:	73c2                	ld	t2,48(sp)
    80006090:	7462                	ld	s0,56(sp)
    80006092:	6486                	ld	s1,64(sp)
    80006094:	6526                	ld	a0,72(sp)
    80006096:	65c6                	ld	a1,80(sp)
    80006098:	6666                	ld	a2,88(sp)
    8000609a:	7686                	ld	a3,96(sp)
    8000609c:	7726                	ld	a4,104(sp)
    8000609e:	77c6                	ld	a5,112(sp)
    800060a0:	7866                	ld	a6,120(sp)
    800060a2:	688a                	ld	a7,128(sp)
    800060a4:	692a                	ld	s2,136(sp)
    800060a6:	69ca                	ld	s3,144(sp)
    800060a8:	6a6a                	ld	s4,152(sp)
    800060aa:	7a8a                	ld	s5,160(sp)
    800060ac:	7b2a                	ld	s6,168(sp)
    800060ae:	7bca                	ld	s7,176(sp)
    800060b0:	7c6a                	ld	s8,184(sp)
    800060b2:	6c8e                	ld	s9,192(sp)
    800060b4:	6d2e                	ld	s10,200(sp)
    800060b6:	6dce                	ld	s11,208(sp)
    800060b8:	6e6e                	ld	t3,216(sp)
    800060ba:	7e8e                	ld	t4,224(sp)
    800060bc:	7f2e                	ld	t5,232(sp)
    800060be:	7fce                	ld	t6,240(sp)
    800060c0:	6111                	add	sp,sp,256
    800060c2:	10200073          	sret
    800060c6:	00000013          	nop
    800060ca:	00000013          	nop
    800060ce:	0001                	nop

00000000800060d0 <timervec>:
    800060d0:	34051573          	csrrw	a0,mscratch,a0
    800060d4:	e10c                	sd	a1,0(a0)
    800060d6:	e510                	sd	a2,8(a0)
    800060d8:	e914                	sd	a3,16(a0)
    800060da:	6d0c                	ld	a1,24(a0)
    800060dc:	7110                	ld	a2,32(a0)
    800060de:	6194                	ld	a3,0(a1)
    800060e0:	96b2                	add	a3,a3,a2
    800060e2:	e194                	sd	a3,0(a1)
    800060e4:	4589                	li	a1,2
    800060e6:	14459073          	csrw	sip,a1
    800060ea:	6914                	ld	a3,16(a0)
    800060ec:	6510                	ld	a2,8(a0)
    800060ee:	610c                	ld	a1,0(a0)
    800060f0:	34051573          	csrrw	a0,mscratch,a0
    800060f4:	30200073          	mret
	...

00000000800060fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060fa:	1141                	add	sp,sp,-16
    800060fc:	e422                	sd	s0,8(sp)
    800060fe:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006100:	0c0007b7          	lui	a5,0xc000
    80006104:	4705                	li	a4,1
    80006106:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006108:	c3d8                	sw	a4,4(a5)
}
    8000610a:	6422                	ld	s0,8(sp)
    8000610c:	0141                	add	sp,sp,16
    8000610e:	8082                	ret

0000000080006110 <plicinithart>:

void
plicinithart(void)
{
    80006110:	1141                	add	sp,sp,-16
    80006112:	e406                	sd	ra,8(sp)
    80006114:	e022                	sd	s0,0(sp)
    80006116:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006118:	ffffc097          	auipc	ra,0xffffc
    8000611c:	a1a080e7          	jalr	-1510(ra) # 80001b32 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006120:	0085171b          	sllw	a4,a0,0x8
    80006124:	0c0027b7          	lui	a5,0xc002
    80006128:	97ba                	add	a5,a5,a4
    8000612a:	40200713          	li	a4,1026
    8000612e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006132:	00d5151b          	sllw	a0,a0,0xd
    80006136:	0c2017b7          	lui	a5,0xc201
    8000613a:	97aa                	add	a5,a5,a0
    8000613c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006140:	60a2                	ld	ra,8(sp)
    80006142:	6402                	ld	s0,0(sp)
    80006144:	0141                	add	sp,sp,16
    80006146:	8082                	ret

0000000080006148 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006148:	1141                	add	sp,sp,-16
    8000614a:	e406                	sd	ra,8(sp)
    8000614c:	e022                	sd	s0,0(sp)
    8000614e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006150:	ffffc097          	auipc	ra,0xffffc
    80006154:	9e2080e7          	jalr	-1566(ra) # 80001b32 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006158:	00d5151b          	sllw	a0,a0,0xd
    8000615c:	0c2017b7          	lui	a5,0xc201
    80006160:	97aa                	add	a5,a5,a0
  return irq;
}
    80006162:	43c8                	lw	a0,4(a5)
    80006164:	60a2                	ld	ra,8(sp)
    80006166:	6402                	ld	s0,0(sp)
    80006168:	0141                	add	sp,sp,16
    8000616a:	8082                	ret

000000008000616c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000616c:	1101                	add	sp,sp,-32
    8000616e:	ec06                	sd	ra,24(sp)
    80006170:	e822                	sd	s0,16(sp)
    80006172:	e426                	sd	s1,8(sp)
    80006174:	1000                	add	s0,sp,32
    80006176:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006178:	ffffc097          	auipc	ra,0xffffc
    8000617c:	9ba080e7          	jalr	-1606(ra) # 80001b32 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006180:	00d5151b          	sllw	a0,a0,0xd
    80006184:	0c2017b7          	lui	a5,0xc201
    80006188:	97aa                	add	a5,a5,a0
    8000618a:	c3c4                	sw	s1,4(a5)
}
    8000618c:	60e2                	ld	ra,24(sp)
    8000618e:	6442                	ld	s0,16(sp)
    80006190:	64a2                	ld	s1,8(sp)
    80006192:	6105                	add	sp,sp,32
    80006194:	8082                	ret

0000000080006196 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006196:	1141                	add	sp,sp,-16
    80006198:	e406                	sd	ra,8(sp)
    8000619a:	e022                	sd	s0,0(sp)
    8000619c:	0800                	add	s0,sp,16
  if(i >= NUM)
    8000619e:	479d                	li	a5,7
    800061a0:	04a7cc63          	blt	a5,a0,800061f8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800061a4:	0001c797          	auipc	a5,0x1c
    800061a8:	efc78793          	add	a5,a5,-260 # 800220a0 <disk>
    800061ac:	97aa                	add	a5,a5,a0
    800061ae:	0187c783          	lbu	a5,24(a5)
    800061b2:	ebb9                	bnez	a5,80006208 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061b4:	00451693          	sll	a3,a0,0x4
    800061b8:	0001c797          	auipc	a5,0x1c
    800061bc:	ee878793          	add	a5,a5,-280 # 800220a0 <disk>
    800061c0:	6398                	ld	a4,0(a5)
    800061c2:	9736                	add	a4,a4,a3
    800061c4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800061c8:	6398                	ld	a4,0(a5)
    800061ca:	9736                	add	a4,a4,a3
    800061cc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800061d0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800061d4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800061d8:	97aa                	add	a5,a5,a0
    800061da:	4705                	li	a4,1
    800061dc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800061e0:	0001c517          	auipc	a0,0x1c
    800061e4:	ed850513          	add	a0,a0,-296 # 800220b8 <disk+0x18>
    800061e8:	ffffc097          	auipc	ra,0xffffc
    800061ec:	12e080e7          	jalr	302(ra) # 80002316 <wakeup>
}
    800061f0:	60a2                	ld	ra,8(sp)
    800061f2:	6402                	ld	s0,0(sp)
    800061f4:	0141                	add	sp,sp,16
    800061f6:	8082                	ret
    panic("free_desc 1");
    800061f8:	00002517          	auipc	a0,0x2
    800061fc:	5d050513          	add	a0,a0,1488 # 800087c8 <syscalls+0x310>
    80006200:	ffffa097          	auipc	ra,0xffffa
    80006204:	33c080e7          	jalr	828(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006208:	00002517          	auipc	a0,0x2
    8000620c:	5d050513          	add	a0,a0,1488 # 800087d8 <syscalls+0x320>
    80006210:	ffffa097          	auipc	ra,0xffffa
    80006214:	32c080e7          	jalr	812(ra) # 8000053c <panic>

0000000080006218 <virtio_disk_init>:
{
    80006218:	1101                	add	sp,sp,-32
    8000621a:	ec06                	sd	ra,24(sp)
    8000621c:	e822                	sd	s0,16(sp)
    8000621e:	e426                	sd	s1,8(sp)
    80006220:	e04a                	sd	s2,0(sp)
    80006222:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006224:	00002597          	auipc	a1,0x2
    80006228:	5c458593          	add	a1,a1,1476 # 800087e8 <syscalls+0x330>
    8000622c:	0001c517          	auipc	a0,0x1c
    80006230:	f9c50513          	add	a0,a0,-100 # 800221c8 <disk+0x128>
    80006234:	ffffb097          	auipc	ra,0xffffb
    80006238:	90e080e7          	jalr	-1778(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000623c:	100017b7          	lui	a5,0x10001
    80006240:	4398                	lw	a4,0(a5)
    80006242:	2701                	sext.w	a4,a4
    80006244:	747277b7          	lui	a5,0x74727
    80006248:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000624c:	14f71b63          	bne	a4,a5,800063a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006250:	100017b7          	lui	a5,0x10001
    80006254:	43dc                	lw	a5,4(a5)
    80006256:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006258:	4709                	li	a4,2
    8000625a:	14e79463          	bne	a5,a4,800063a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000625e:	100017b7          	lui	a5,0x10001
    80006262:	479c                	lw	a5,8(a5)
    80006264:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006266:	12e79e63          	bne	a5,a4,800063a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000626a:	100017b7          	lui	a5,0x10001
    8000626e:	47d8                	lw	a4,12(a5)
    80006270:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006272:	554d47b7          	lui	a5,0x554d4
    80006276:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000627a:	12f71463          	bne	a4,a5,800063a2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000627e:	100017b7          	lui	a5,0x10001
    80006282:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006286:	4705                	li	a4,1
    80006288:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000628a:	470d                	li	a4,3
    8000628c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000628e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006290:	c7ffe6b7          	lui	a3,0xc7ffe
    80006294:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd83df>
    80006298:	8f75                	and	a4,a4,a3
    8000629a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000629c:	472d                	li	a4,11
    8000629e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800062a0:	5bbc                	lw	a5,112(a5)
    800062a2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800062a6:	8ba1                	and	a5,a5,8
    800062a8:	10078563          	beqz	a5,800063b2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062ac:	100017b7          	lui	a5,0x10001
    800062b0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800062b4:	43fc                	lw	a5,68(a5)
    800062b6:	2781                	sext.w	a5,a5
    800062b8:	10079563          	bnez	a5,800063c2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062bc:	100017b7          	lui	a5,0x10001
    800062c0:	5bdc                	lw	a5,52(a5)
    800062c2:	2781                	sext.w	a5,a5
  if(max == 0)
    800062c4:	10078763          	beqz	a5,800063d2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800062c8:	471d                	li	a4,7
    800062ca:	10f77c63          	bgeu	a4,a5,800063e2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800062ce:	ffffb097          	auipc	ra,0xffffb
    800062d2:	814080e7          	jalr	-2028(ra) # 80000ae2 <kalloc>
    800062d6:	0001c497          	auipc	s1,0x1c
    800062da:	dca48493          	add	s1,s1,-566 # 800220a0 <disk>
    800062de:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800062e0:	ffffb097          	auipc	ra,0xffffb
    800062e4:	802080e7          	jalr	-2046(ra) # 80000ae2 <kalloc>
    800062e8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800062ea:	ffffa097          	auipc	ra,0xffffa
    800062ee:	7f8080e7          	jalr	2040(ra) # 80000ae2 <kalloc>
    800062f2:	87aa                	mv	a5,a0
    800062f4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800062f6:	6088                	ld	a0,0(s1)
    800062f8:	cd6d                	beqz	a0,800063f2 <virtio_disk_init+0x1da>
    800062fa:	0001c717          	auipc	a4,0x1c
    800062fe:	dae73703          	ld	a4,-594(a4) # 800220a8 <disk+0x8>
    80006302:	cb65                	beqz	a4,800063f2 <virtio_disk_init+0x1da>
    80006304:	c7fd                	beqz	a5,800063f2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006306:	6605                	lui	a2,0x1
    80006308:	4581                	li	a1,0
    8000630a:	ffffb097          	auipc	ra,0xffffb
    8000630e:	9c4080e7          	jalr	-1596(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80006312:	0001c497          	auipc	s1,0x1c
    80006316:	d8e48493          	add	s1,s1,-626 # 800220a0 <disk>
    8000631a:	6605                	lui	a2,0x1
    8000631c:	4581                	li	a1,0
    8000631e:	6488                	ld	a0,8(s1)
    80006320:	ffffb097          	auipc	ra,0xffffb
    80006324:	9ae080e7          	jalr	-1618(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006328:	6605                	lui	a2,0x1
    8000632a:	4581                	li	a1,0
    8000632c:	6888                	ld	a0,16(s1)
    8000632e:	ffffb097          	auipc	ra,0xffffb
    80006332:	9a0080e7          	jalr	-1632(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006336:	100017b7          	lui	a5,0x10001
    8000633a:	4721                	li	a4,8
    8000633c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000633e:	4098                	lw	a4,0(s1)
    80006340:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006344:	40d8                	lw	a4,4(s1)
    80006346:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000634a:	6498                	ld	a4,8(s1)
    8000634c:	0007069b          	sext.w	a3,a4
    80006350:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006354:	9701                	sra	a4,a4,0x20
    80006356:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000635a:	6898                	ld	a4,16(s1)
    8000635c:	0007069b          	sext.w	a3,a4
    80006360:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006364:	9701                	sra	a4,a4,0x20
    80006366:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000636a:	4705                	li	a4,1
    8000636c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000636e:	00e48c23          	sb	a4,24(s1)
    80006372:	00e48ca3          	sb	a4,25(s1)
    80006376:	00e48d23          	sb	a4,26(s1)
    8000637a:	00e48da3          	sb	a4,27(s1)
    8000637e:	00e48e23          	sb	a4,28(s1)
    80006382:	00e48ea3          	sb	a4,29(s1)
    80006386:	00e48f23          	sb	a4,30(s1)
    8000638a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000638e:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006392:	0727a823          	sw	s2,112(a5)
}
    80006396:	60e2                	ld	ra,24(sp)
    80006398:	6442                	ld	s0,16(sp)
    8000639a:	64a2                	ld	s1,8(sp)
    8000639c:	6902                	ld	s2,0(sp)
    8000639e:	6105                	add	sp,sp,32
    800063a0:	8082                	ret
    panic("could not find virtio disk");
    800063a2:	00002517          	auipc	a0,0x2
    800063a6:	45650513          	add	a0,a0,1110 # 800087f8 <syscalls+0x340>
    800063aa:	ffffa097          	auipc	ra,0xffffa
    800063ae:	192080e7          	jalr	402(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800063b2:	00002517          	auipc	a0,0x2
    800063b6:	46650513          	add	a0,a0,1126 # 80008818 <syscalls+0x360>
    800063ba:	ffffa097          	auipc	ra,0xffffa
    800063be:	182080e7          	jalr	386(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800063c2:	00002517          	auipc	a0,0x2
    800063c6:	47650513          	add	a0,a0,1142 # 80008838 <syscalls+0x380>
    800063ca:	ffffa097          	auipc	ra,0xffffa
    800063ce:	172080e7          	jalr	370(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800063d2:	00002517          	auipc	a0,0x2
    800063d6:	48650513          	add	a0,a0,1158 # 80008858 <syscalls+0x3a0>
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	162080e7          	jalr	354(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800063e2:	00002517          	auipc	a0,0x2
    800063e6:	49650513          	add	a0,a0,1174 # 80008878 <syscalls+0x3c0>
    800063ea:	ffffa097          	auipc	ra,0xffffa
    800063ee:	152080e7          	jalr	338(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800063f2:	00002517          	auipc	a0,0x2
    800063f6:	4a650513          	add	a0,a0,1190 # 80008898 <syscalls+0x3e0>
    800063fa:	ffffa097          	auipc	ra,0xffffa
    800063fe:	142080e7          	jalr	322(ra) # 8000053c <panic>

0000000080006402 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006402:	7159                	add	sp,sp,-112
    80006404:	f486                	sd	ra,104(sp)
    80006406:	f0a2                	sd	s0,96(sp)
    80006408:	eca6                	sd	s1,88(sp)
    8000640a:	e8ca                	sd	s2,80(sp)
    8000640c:	e4ce                	sd	s3,72(sp)
    8000640e:	e0d2                	sd	s4,64(sp)
    80006410:	fc56                	sd	s5,56(sp)
    80006412:	f85a                	sd	s6,48(sp)
    80006414:	f45e                	sd	s7,40(sp)
    80006416:	f062                	sd	s8,32(sp)
    80006418:	ec66                	sd	s9,24(sp)
    8000641a:	e86a                	sd	s10,16(sp)
    8000641c:	1880                	add	s0,sp,112
    8000641e:	8a2a                	mv	s4,a0
    80006420:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006422:	00c52c83          	lw	s9,12(a0)
    80006426:	001c9c9b          	sllw	s9,s9,0x1
    8000642a:	1c82                	sll	s9,s9,0x20
    8000642c:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006430:	0001c517          	auipc	a0,0x1c
    80006434:	d9850513          	add	a0,a0,-616 # 800221c8 <disk+0x128>
    80006438:	ffffa097          	auipc	ra,0xffffa
    8000643c:	79a080e7          	jalr	1946(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006440:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006442:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006444:	0001cb17          	auipc	s6,0x1c
    80006448:	c5cb0b13          	add	s6,s6,-932 # 800220a0 <disk>
  for(int i = 0; i < 3; i++){
    8000644c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000644e:	0001cc17          	auipc	s8,0x1c
    80006452:	d7ac0c13          	add	s8,s8,-646 # 800221c8 <disk+0x128>
    80006456:	a095                	j	800064ba <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006458:	00fb0733          	add	a4,s6,a5
    8000645c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006460:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006462:	0207c563          	bltz	a5,8000648c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006466:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006468:	0591                	add	a1,a1,4
    8000646a:	05560d63          	beq	a2,s5,800064c4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000646e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006470:	0001c717          	auipc	a4,0x1c
    80006474:	c3070713          	add	a4,a4,-976 # 800220a0 <disk>
    80006478:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000647a:	01874683          	lbu	a3,24(a4)
    8000647e:	fee9                	bnez	a3,80006458 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006480:	2785                	addw	a5,a5,1
    80006482:	0705                	add	a4,a4,1
    80006484:	fe979be3          	bne	a5,s1,8000647a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006488:	57fd                	li	a5,-1
    8000648a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000648c:	00c05e63          	blez	a2,800064a8 <virtio_disk_rw+0xa6>
    80006490:	060a                	sll	a2,a2,0x2
    80006492:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006496:	0009a503          	lw	a0,0(s3)
    8000649a:	00000097          	auipc	ra,0x0
    8000649e:	cfc080e7          	jalr	-772(ra) # 80006196 <free_desc>
      for(int j = 0; j < i; j++)
    800064a2:	0991                	add	s3,s3,4
    800064a4:	ffa999e3          	bne	s3,s10,80006496 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064a8:	85e2                	mv	a1,s8
    800064aa:	0001c517          	auipc	a0,0x1c
    800064ae:	c0e50513          	add	a0,a0,-1010 # 800220b8 <disk+0x18>
    800064b2:	ffffc097          	auipc	ra,0xffffc
    800064b6:	e00080e7          	jalr	-512(ra) # 800022b2 <sleep>
  for(int i = 0; i < 3; i++){
    800064ba:	f9040993          	add	s3,s0,-112
{
    800064be:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800064c0:	864a                	mv	a2,s2
    800064c2:	b775                	j	8000646e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064c4:	f9042503          	lw	a0,-112(s0)
    800064c8:	00a50713          	add	a4,a0,10
    800064cc:	0712                	sll	a4,a4,0x4

  if(write)
    800064ce:	0001c797          	auipc	a5,0x1c
    800064d2:	bd278793          	add	a5,a5,-1070 # 800220a0 <disk>
    800064d6:	00e786b3          	add	a3,a5,a4
    800064da:	01703633          	snez	a2,s7
    800064de:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064e0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800064e4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064e8:	f6070613          	add	a2,a4,-160
    800064ec:	6394                	ld	a3,0(a5)
    800064ee:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064f0:	00870593          	add	a1,a4,8
    800064f4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800064f6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064f8:	0007b803          	ld	a6,0(a5)
    800064fc:	9642                	add	a2,a2,a6
    800064fe:	46c1                	li	a3,16
    80006500:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006502:	4585                	li	a1,1
    80006504:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006508:	f9442683          	lw	a3,-108(s0)
    8000650c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006510:	0692                	sll	a3,a3,0x4
    80006512:	9836                	add	a6,a6,a3
    80006514:	058a0613          	add	a2,s4,88
    80006518:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000651c:	0007b803          	ld	a6,0(a5)
    80006520:	96c2                	add	a3,a3,a6
    80006522:	40000613          	li	a2,1024
    80006526:	c690                	sw	a2,8(a3)
  if(write)
    80006528:	001bb613          	seqz	a2,s7
    8000652c:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006530:	00166613          	or	a2,a2,1
    80006534:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006538:	f9842603          	lw	a2,-104(s0)
    8000653c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006540:	00250693          	add	a3,a0,2
    80006544:	0692                	sll	a3,a3,0x4
    80006546:	96be                	add	a3,a3,a5
    80006548:	58fd                	li	a7,-1
    8000654a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000654e:	0612                	sll	a2,a2,0x4
    80006550:	9832                	add	a6,a6,a2
    80006552:	f9070713          	add	a4,a4,-112
    80006556:	973e                	add	a4,a4,a5
    80006558:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000655c:	6398                	ld	a4,0(a5)
    8000655e:	9732                	add	a4,a4,a2
    80006560:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006562:	4609                	li	a2,2
    80006564:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006568:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000656c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006570:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006574:	6794                	ld	a3,8(a5)
    80006576:	0026d703          	lhu	a4,2(a3)
    8000657a:	8b1d                	and	a4,a4,7
    8000657c:	0706                	sll	a4,a4,0x1
    8000657e:	96ba                	add	a3,a3,a4
    80006580:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006584:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006588:	6798                	ld	a4,8(a5)
    8000658a:	00275783          	lhu	a5,2(a4)
    8000658e:	2785                	addw	a5,a5,1
    80006590:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006594:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006598:	100017b7          	lui	a5,0x10001
    8000659c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065a0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800065a4:	0001c917          	auipc	s2,0x1c
    800065a8:	c2490913          	add	s2,s2,-988 # 800221c8 <disk+0x128>
  while(b->disk == 1) {
    800065ac:	4485                	li	s1,1
    800065ae:	00b79c63          	bne	a5,a1,800065c6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800065b2:	85ca                	mv	a1,s2
    800065b4:	8552                	mv	a0,s4
    800065b6:	ffffc097          	auipc	ra,0xffffc
    800065ba:	cfc080e7          	jalr	-772(ra) # 800022b2 <sleep>
  while(b->disk == 1) {
    800065be:	004a2783          	lw	a5,4(s4)
    800065c2:	fe9788e3          	beq	a5,s1,800065b2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800065c6:	f9042903          	lw	s2,-112(s0)
    800065ca:	00290713          	add	a4,s2,2
    800065ce:	0712                	sll	a4,a4,0x4
    800065d0:	0001c797          	auipc	a5,0x1c
    800065d4:	ad078793          	add	a5,a5,-1328 # 800220a0 <disk>
    800065d8:	97ba                	add	a5,a5,a4
    800065da:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800065de:	0001c997          	auipc	s3,0x1c
    800065e2:	ac298993          	add	s3,s3,-1342 # 800220a0 <disk>
    800065e6:	00491713          	sll	a4,s2,0x4
    800065ea:	0009b783          	ld	a5,0(s3)
    800065ee:	97ba                	add	a5,a5,a4
    800065f0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065f4:	854a                	mv	a0,s2
    800065f6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065fa:	00000097          	auipc	ra,0x0
    800065fe:	b9c080e7          	jalr	-1124(ra) # 80006196 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006602:	8885                	and	s1,s1,1
    80006604:	f0ed                	bnez	s1,800065e6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006606:	0001c517          	auipc	a0,0x1c
    8000660a:	bc250513          	add	a0,a0,-1086 # 800221c8 <disk+0x128>
    8000660e:	ffffa097          	auipc	ra,0xffffa
    80006612:	678080e7          	jalr	1656(ra) # 80000c86 <release>
}
    80006616:	70a6                	ld	ra,104(sp)
    80006618:	7406                	ld	s0,96(sp)
    8000661a:	64e6                	ld	s1,88(sp)
    8000661c:	6946                	ld	s2,80(sp)
    8000661e:	69a6                	ld	s3,72(sp)
    80006620:	6a06                	ld	s4,64(sp)
    80006622:	7ae2                	ld	s5,56(sp)
    80006624:	7b42                	ld	s6,48(sp)
    80006626:	7ba2                	ld	s7,40(sp)
    80006628:	7c02                	ld	s8,32(sp)
    8000662a:	6ce2                	ld	s9,24(sp)
    8000662c:	6d42                	ld	s10,16(sp)
    8000662e:	6165                	add	sp,sp,112
    80006630:	8082                	ret

0000000080006632 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006632:	1101                	add	sp,sp,-32
    80006634:	ec06                	sd	ra,24(sp)
    80006636:	e822                	sd	s0,16(sp)
    80006638:	e426                	sd	s1,8(sp)
    8000663a:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000663c:	0001c497          	auipc	s1,0x1c
    80006640:	a6448493          	add	s1,s1,-1436 # 800220a0 <disk>
    80006644:	0001c517          	auipc	a0,0x1c
    80006648:	b8450513          	add	a0,a0,-1148 # 800221c8 <disk+0x128>
    8000664c:	ffffa097          	auipc	ra,0xffffa
    80006650:	586080e7          	jalr	1414(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006654:	10001737          	lui	a4,0x10001
    80006658:	533c                	lw	a5,96(a4)
    8000665a:	8b8d                	and	a5,a5,3
    8000665c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000665e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006662:	689c                	ld	a5,16(s1)
    80006664:	0204d703          	lhu	a4,32(s1)
    80006668:	0027d783          	lhu	a5,2(a5)
    8000666c:	04f70863          	beq	a4,a5,800066bc <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006670:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006674:	6898                	ld	a4,16(s1)
    80006676:	0204d783          	lhu	a5,32(s1)
    8000667a:	8b9d                	and	a5,a5,7
    8000667c:	078e                	sll	a5,a5,0x3
    8000667e:	97ba                	add	a5,a5,a4
    80006680:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006682:	00278713          	add	a4,a5,2
    80006686:	0712                	sll	a4,a4,0x4
    80006688:	9726                	add	a4,a4,s1
    8000668a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000668e:	e721                	bnez	a4,800066d6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006690:	0789                	add	a5,a5,2
    80006692:	0792                	sll	a5,a5,0x4
    80006694:	97a6                	add	a5,a5,s1
    80006696:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006698:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000669c:	ffffc097          	auipc	ra,0xffffc
    800066a0:	c7a080e7          	jalr	-902(ra) # 80002316 <wakeup>

    disk.used_idx += 1;
    800066a4:	0204d783          	lhu	a5,32(s1)
    800066a8:	2785                	addw	a5,a5,1
    800066aa:	17c2                	sll	a5,a5,0x30
    800066ac:	93c1                	srl	a5,a5,0x30
    800066ae:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066b2:	6898                	ld	a4,16(s1)
    800066b4:	00275703          	lhu	a4,2(a4)
    800066b8:	faf71ce3          	bne	a4,a5,80006670 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800066bc:	0001c517          	auipc	a0,0x1c
    800066c0:	b0c50513          	add	a0,a0,-1268 # 800221c8 <disk+0x128>
    800066c4:	ffffa097          	auipc	ra,0xffffa
    800066c8:	5c2080e7          	jalr	1474(ra) # 80000c86 <release>
}
    800066cc:	60e2                	ld	ra,24(sp)
    800066ce:	6442                	ld	s0,16(sp)
    800066d0:	64a2                	ld	s1,8(sp)
    800066d2:	6105                	add	sp,sp,32
    800066d4:	8082                	ret
      panic("virtio_disk_intr status");
    800066d6:	00002517          	auipc	a0,0x2
    800066da:	1da50513          	add	a0,a0,474 # 800088b0 <syscalls+0x3f8>
    800066de:	ffffa097          	auipc	ra,0xffffa
    800066e2:	e5e080e7          	jalr	-418(ra) # 8000053c <panic>

00000000800066e6 <ran_array>:
long ran_x[KK];
long aa[2000];
int rand_index = 0;
void main();
void ran_array(long aa[], int n)
{
    800066e6:	1141                	add	sp,sp,-16
    800066e8:	e422                	sd	s0,8(sp)
    800066ea:	0800                	add	s0,sp,16
    register int i, j;
    for (j = 0; j < KK; j++)
    800066ec:	0001c897          	auipc	a7,0x1c
    800066f0:	af488893          	add	a7,a7,-1292 # 800221e0 <ran_x>
    800066f4:	882a                	mv	a6,a0
    800066f6:	0001c617          	auipc	a2,0x1c
    800066fa:	e0a60613          	add	a2,a2,-502 # 80022500 <aa>
{
    800066fe:	872a                	mv	a4,a0
    80006700:	87c6                	mv	a5,a7
        aa[j] = ran_x[j];
    80006702:	6394                	ld	a3,0(a5)
    80006704:	e314                	sd	a3,0(a4)
    for (j = 0; j < KK; j++)
    80006706:	07a1                	add	a5,a5,8
    80006708:	0721                	add	a4,a4,8
    8000670a:	fec79ce3          	bne	a5,a2,80006702 <ran_array+0x1c>
    for (; j < n; j++)
    8000670e:	06400793          	li	a5,100
    80006712:	08b7d863          	bge	a5,a1,800067a2 <ran_array+0xbc>
    80006716:	f9b5869b          	addw	a3,a1,-101
    8000671a:	02069793          	sll	a5,a3,0x20
    8000671e:	01d7d693          	srl	a3,a5,0x1d
    80006722:	00850793          	add	a5,a0,8
    80006726:	96be                	add	a3,a3,a5
        aa[j] = mod_diff(aa[j - KK], aa[j - LL]);
    80006728:	40000637          	lui	a2,0x40000
    8000672c:	167d                	add	a2,a2,-1 # 3fffffff <_entry-0x40000001>
    8000672e:	00083783          	ld	a5,0(a6)
    80006732:	1f883703          	ld	a4,504(a6)
    80006736:	8f99                	sub	a5,a5,a4
    80006738:	8ff1                	and	a5,a5,a2
    8000673a:	32f83023          	sd	a5,800(a6)
    for (; j < n; j++)
    8000673e:	0821                	add	a6,a6,8
    80006740:	fed817e3          	bne	a6,a3,8000672e <ran_array+0x48>
    for (i = 0; i < LL; i++, j++)
    80006744:	00359313          	sll	t1,a1,0x3
    80006748:	ce030713          	add	a4,t1,-800
    8000674c:	972a                	add	a4,a4,a0
    8000674e:	0001c817          	auipc	a6,0x1c
    80006752:	bba80813          	add	a6,a6,-1094 # 80022308 <ran_x+0x128>
    for (j = 0; j < KK; j++)
    80006756:	86c6                	mv	a3,a7
        ran_x[i] = mod_diff(aa[j - KK], aa[j - LL]);
    80006758:	400005b7          	lui	a1,0x40000
    8000675c:	15fd                	add	a1,a1,-1 # 3fffffff <_entry-0x40000001>
    8000675e:	631c                	ld	a5,0(a4)
    80006760:	1f873603          	ld	a2,504(a4)
    80006764:	8f91                	sub	a5,a5,a2
    80006766:	8fed                	and	a5,a5,a1
    80006768:	e29c                	sd	a5,0(a3)
    for (i = 0; i < LL; i++, j++)
    8000676a:	0721                	add	a4,a4,8
    8000676c:	06a1                	add	a3,a3,8
    8000676e:	ff0698e3          	bne	a3,a6,8000675e <ran_array+0x78>
    for (; i < KK; i++, j++)
    80006772:	e0830593          	add	a1,t1,-504
    80006776:	952e                	add	a0,a0,a1
    80006778:	0001c617          	auipc	a2,0x1c
    8000677c:	c6060613          	add	a2,a2,-928 # 800223d8 <ran_x+0x1f8>
        ran_x[i] = mod_diff(aa[j - KK], ran_x[i - LL]);
    80006780:	400006b7          	lui	a3,0x40000
    80006784:	16fd                	add	a3,a3,-1 # 3fffffff <_entry-0x40000001>
    80006786:	611c                	ld	a5,0(a0)
    80006788:	0008b703          	ld	a4,0(a7)
    8000678c:	8f99                	sub	a5,a5,a4
    8000678e:	8ff5                	and	a5,a5,a3
    80006790:	12f8b423          	sd	a5,296(a7)
    for (; i < KK; i++, j++)
    80006794:	0521                	add	a0,a0,8
    80006796:	08a1                	add	a7,a7,8
    80006798:	fec897e3          	bne	a7,a2,80006786 <ran_array+0xa0>
}
    8000679c:	6422                	ld	s0,8(sp)
    8000679e:	0141                	add	sp,sp,16
    800067a0:	8082                	ret
    for (j = 0; j < KK; j++)
    800067a2:	06400593          	li	a1,100
    800067a6:	bf79                	j	80006744 <ran_array+0x5e>

00000000800067a8 <ran_start>:
void ran_start(int seed)
{
    800067a8:	9b010113          	add	sp,sp,-1616
    800067ac:	64113423          	sd	ra,1608(sp)
    800067b0:	64813023          	sd	s0,1600(sp)
    800067b4:	65010413          	add	s0,sp,1616
    800067b8:	882a                	mv	a6,a0
    register int t, j;
    long x[KK + KK - 1];
    register long ss = evenize(seed + 2);
    800067ba:	0025079b          	addw	a5,a0,2
    800067be:	40000737          	lui	a4,0x40000
    800067c2:	1779                	add	a4,a4,-2 # 3ffffffe <_entry-0x40000002>
    800067c4:	8ff9                	and	a5,a5,a4
    800067c6:	2781                	sext.w	a5,a5
    for (j = 0; j < KK; j++)
    800067c8:	9b840613          	add	a2,s0,-1608
    800067cc:	cd840593          	add	a1,s0,-808
    register long ss = evenize(seed + 2);
    800067d0:	8732                	mv	a4,a2
    {
        x[j] = ss;
        ss <<= 1;
        if (ss >= MM)
    800067d2:	400006b7          	lui	a3,0x40000
            ss -= MM - 2;
    800067d6:	c0000537          	lui	a0,0xc0000
    800067da:	0509                	add	a0,a0,2 # ffffffffc0000002 <end+0xffffffff3ffd9c82>
    800067dc:	a021                	j	800067e4 <ran_start+0x3c>
    for (j = 0; j < KK; j++)
    800067de:	0721                	add	a4,a4,8
    800067e0:	00b70863          	beq	a4,a1,800067f0 <ran_start+0x48>
        x[j] = ss;
    800067e4:	e31c                	sd	a5,0(a4)
        ss <<= 1;
    800067e6:	0786                	sll	a5,a5,0x1
        if (ss >= MM)
    800067e8:	fed7cbe3          	blt	a5,a3,800067de <ran_start+0x36>
            ss -= MM - 2;
    800067ec:	97aa                	add	a5,a5,a0
    800067ee:	bfc5                	j	800067de <ran_start+0x36>
    }
    for (; j < KK + KK - 1; j++)
    800067f0:	cd840793          	add	a5,s0,-808
    800067f4:	63860713          	add	a4,a2,1592
        x[j] = 0;
    800067f8:	0007b023          	sd	zero,0(a5)
    for (; j < KK + KK - 1; j++)
    800067fc:	07a1                	add	a5,a5,8
    800067fe:	fee79de3          	bne	a5,a4,800067f8 <ran_start+0x50>
    x[1]++;
    80006802:	9c043783          	ld	a5,-1600(s0)
    80006806:	0785                	add	a5,a5,1
    80006808:	9cf43023          	sd	a5,-1600(s0)
    ss = seed & (MM - 1);
    8000680c:	180a                	sll	a6,a6,0x22
    8000680e:	02285e13          	srl	t3,a6,0x22
    t = TT - 1;
    80006812:	04500e93          	li	t4,69
    80006816:	1f060313          	add	t1,a2,496
    while (t)
    {
        for (j = KK - 1; j > 0; j--)
            x[j + j] = x[j];
        for (j = KK + KK - 2; j > KK - LL; j -= 2)
            x[KK + KK - 1 - j] = evenize(x[j]);
    8000681a:	40000837          	lui	a6,0x40000
    8000681e:	ffe80893          	add	a7,a6,-2 # 3ffffffe <_entry-0x40000002>
        for (j = KK + KK - 2; j >= KK; j--)
            if (is_odd(x[j]))
            {
                x[j - (KK - LL)] = mod_diff(x[j - (KK - LL)], x[j]);
    80006822:	187d                	add	a6,a6,-1
    80006824:	a885                	j	80006894 <ran_start+0xec>
        for (j = KK + KK - 2; j >= KK; j--)
    80006826:	ff878713          	add	a4,a5,-8
    8000682a:	02c78563          	beq	a5,a2,80006854 <ran_start+0xac>
    8000682e:	87ba                	mv	a5,a4
            if (is_odd(x[j]))
    80006830:	3207b683          	ld	a3,800(a5)
    80006834:	0016f713          	and	a4,a3,1
    80006838:	d77d                	beqz	a4,80006826 <ran_start+0x7e>
                x[j - (KK - LL)] = mod_diff(x[j - (KK - LL)], x[j]);
    8000683a:	1287b703          	ld	a4,296(a5)
    8000683e:	8f15                	sub	a4,a4,a3
    80006840:	01077733          	and	a4,a4,a6
    80006844:	12e7b423          	sd	a4,296(a5)
                x[j - KK] = mod_diff(x[j - KK], x[j]);
    80006848:	6398                	ld	a4,0(a5)
    8000684a:	8f15                	sub	a4,a4,a3
    8000684c:	01077733          	and	a4,a4,a6
    80006850:	e398                	sd	a4,0(a5)
    80006852:	bfd1                	j	80006826 <ran_start+0x7e>
            }
        if (is_odd(ss))
    80006854:	001e7793          	and	a5,t3,1
    80006858:	e789                	bnez	a5,80006862 <ran_start+0xba>
                x[j] = x[j - 1];
            x[0] = x[KK];
            if (is_odd(x[KK]))
                x[LL] = mod_diff(x[LL], x[KK]);
        }
        if (ss)
    8000685a:	020e1963          	bnez	t3,8000688c <ran_start+0xe4>
            ss >>= 1;
        else
            t--;
    8000685e:	3efd                	addw	t4,t4,-1
    80006860:	a805                	j	80006890 <ran_start+0xe8>
                x[j] = x[j - 1];
    80006862:	87aa                	mv	a5,a0
    80006864:	6118                	ld	a4,0(a0)
    80006866:	e518                	sd	a4,8(a0)
            for (j = KK; j > 0; j--)
    80006868:	1561                	add	a0,a0,-8
    8000686a:	fec79ce3          	bne	a5,a2,80006862 <ran_start+0xba>
            x[0] = x[KK];
    8000686e:	cd843783          	ld	a5,-808(s0)
    80006872:	9af43c23          	sd	a5,-1608(s0)
            if (is_odd(x[KK]))
    80006876:	0017f713          	and	a4,a5,1
    8000687a:	cb09                	beqz	a4,8000688c <ran_start+0xe4>
                x[LL] = mod_diff(x[LL], x[KK]);
    8000687c:	ae043703          	ld	a4,-1312(s0)
    80006880:	40f707b3          	sub	a5,a4,a5
    80006884:	0107f7b3          	and	a5,a5,a6
    80006888:	aef43023          	sd	a5,-1312(s0)
            ss >>= 1;
    8000688c:	401e5e13          	sra	t3,t3,0x1
    while (t)
    80006890:	020e8b63          	beqz	t4,800068c6 <ran_start+0x11e>
        for (j = KK - 1; j > 0; j--)
    80006894:	cd040513          	add	a0,s0,-816
    80006898:	fe840693          	add	a3,s0,-24
    register long ss = evenize(seed + 2);
    8000689c:	87b6                	mv	a5,a3
    8000689e:	872a                	mv	a4,a0
            x[j + j] = x[j];
    800068a0:	630c                	ld	a1,0(a4)
    800068a2:	e38c                	sd	a1,0(a5)
        for (j = KK - 1; j > 0; j--)
    800068a4:	1761                	add	a4,a4,-8
    800068a6:	17c1                	add	a5,a5,-16
    800068a8:	fec79ce3          	bne	a5,a2,800068a0 <ran_start+0xf8>
    800068ac:	9c040713          	add	a4,s0,-1600
            x[KK + KK - 1 - j] = evenize(x[j]);
    800068b0:	629c                	ld	a5,0(a3)
    800068b2:	0117f7b3          	and	a5,a5,a7
    800068b6:	e31c                	sd	a5,0(a4)
        for (j = KK + KK - 2; j > KK - LL; j -= 2)
    800068b8:	16c1                	add	a3,a3,-16 # 3ffffff0 <_entry-0x40000010>
    800068ba:	0741                	add	a4,a4,16
    800068bc:	fe669ae3          	bne	a3,t1,800068b0 <ran_start+0x108>
    800068c0:	cc840793          	add	a5,s0,-824
    800068c4:	b7b5                	j	80006830 <ran_start+0x88>
    800068c6:	0001c797          	auipc	a5,0x1c
    800068ca:	b1278793          	add	a5,a5,-1262 # 800223d8 <ran_x+0x1f8>
    800068ce:	12860693          	add	a3,a2,296
    }
    for (j = 0; j < LL; j++)
        ran_x[j + KK - LL] = x[j];
    800068d2:	6218                	ld	a4,0(a2)
    800068d4:	e398                	sd	a4,0(a5)
    for (j = 0; j < LL; j++)
    800068d6:	0621                	add	a2,a2,8
    800068d8:	07a1                	add	a5,a5,8
    800068da:	fec69ce3          	bne	a3,a2,800068d2 <ran_start+0x12a>
    for (; j < KK; j++)
    800068de:	ae040713          	add	a4,s0,-1312
    800068e2:	0001c797          	auipc	a5,0x1c
    800068e6:	8fe78793          	add	a5,a5,-1794 # 800221e0 <ran_x>
    800068ea:	0001c617          	auipc	a2,0x1c
    800068ee:	aee60613          	add	a2,a2,-1298 # 800223d8 <ran_x+0x1f8>
        ran_x[j - LL] = x[j];
    800068f2:	6314                	ld	a3,0(a4)
    800068f4:	e394                	sd	a3,0(a5)
    for (; j < KK; j++)
    800068f6:	0721                	add	a4,a4,8
    800068f8:	07a1                	add	a5,a5,8
    800068fa:	fec79ce3          	bne	a5,a2,800068f2 <ran_start+0x14a>
    ran_array(aa, 1009);
    800068fe:	3f100593          	li	a1,1009
    80006902:	0001c517          	auipc	a0,0x1c
    80006906:	bfe50513          	add	a0,a0,-1026 # 80022500 <aa>
    8000690a:	00000097          	auipc	ra,0x0
    8000690e:	ddc080e7          	jalr	-548(ra) # 800066e6 <ran_array>
    rand_index = 0;
    80006912:	00002797          	auipc	a5,0x2
    80006916:	0407a723          	sw	zero,78(a5) # 80008960 <rand_index>
}
    8000691a:	64813083          	ld	ra,1608(sp)
    8000691e:	64013403          	ld	s0,1600(sp)
    80006922:	65010113          	add	sp,sp,1616
    80006926:	8082                	ret

0000000080006928 <nextRand>:
int nextRand()
{
    if (++rand_index > 100)
    80006928:	00002717          	auipc	a4,0x2
    8000692c:	03870713          	add	a4,a4,56 # 80008960 <rand_index>
    80006930:	431c                	lw	a5,0(a4)
    80006932:	2785                	addw	a5,a5,1
    80006934:	0007869b          	sext.w	a3,a5
    80006938:	c31c                	sw	a5,0(a4)
    8000693a:	06400793          	li	a5,100
    8000693e:	00d7ce63          	blt	a5,a3,8000695a <nextRand+0x32>
    {
        ran_array(aa, 1009);
        rand_index = 0;
    }
    return aa[rand_index];
    80006942:	00002717          	auipc	a4,0x2
    80006946:	01e72703          	lw	a4,30(a4) # 80008960 <rand_index>
    8000694a:	070e                	sll	a4,a4,0x3
    8000694c:	0001c797          	auipc	a5,0x1c
    80006950:	bb478793          	add	a5,a5,-1100 # 80022500 <aa>
    80006954:	97ba                	add	a5,a5,a4
}
    80006956:	4388                	lw	a0,0(a5)
    80006958:	8082                	ret
{
    8000695a:	1141                	add	sp,sp,-16
    8000695c:	e406                	sd	ra,8(sp)
    8000695e:	e022                	sd	s0,0(sp)
    80006960:	0800                	add	s0,sp,16
        ran_array(aa, 1009);
    80006962:	3f100593          	li	a1,1009
    80006966:	0001c517          	auipc	a0,0x1c
    8000696a:	b9a50513          	add	a0,a0,-1126 # 80022500 <aa>
    8000696e:	00000097          	auipc	ra,0x0
    80006972:	d78080e7          	jalr	-648(ra) # 800066e6 <ran_array>
        rand_index = 0;
    80006976:	00002797          	auipc	a5,0x2
    8000697a:	fe07a523          	sw	zero,-22(a5) # 80008960 <rand_index>
    return aa[rand_index];
    8000697e:	00002717          	auipc	a4,0x2
    80006982:	fe272703          	lw	a4,-30(a4) # 80008960 <rand_index>
    80006986:	070e                	sll	a4,a4,0x3
    80006988:	0001c797          	auipc	a5,0x1c
    8000698c:	b7878793          	add	a5,a5,-1160 # 80022500 <aa>
    80006990:	97ba                	add	a5,a5,a4
}
    80006992:	4388                	lw	a0,0(a5)
    80006994:	60a2                	ld	ra,8(sp)
    80006996:	6402                	ld	s0,0(sp)
    80006998:	0141                	add	sp,sp,16
    8000699a:	8082                	ret

000000008000699c <rand_init>:
void rand_init(int seed)
{
    8000699c:	1141                	add	sp,sp,-16
    8000699e:	e406                	sd	ra,8(sp)
    800069a0:	e022                	sd	s0,0(sp)
    800069a2:	0800                	add	s0,sp,16
    ran_start(seed);
    800069a4:	00000097          	auipc	ra,0x0
    800069a8:	e04080e7          	jalr	-508(ra) # 800067a8 <ran_start>
}
    800069ac:	60a2                	ld	ra,8(sp)
    800069ae:	6402                	ld	s0,0(sp)
    800069b0:	0141                	add	sp,sp,16
    800069b2:	8082                	ret

00000000800069b4 <scaled_random>:
int scaled_random(int low, int high)
{
    800069b4:	1101                	add	sp,sp,-32
    800069b6:	ec06                	sd	ra,24(sp)
    800069b8:	e822                	sd	s0,16(sp)
    800069ba:	e426                	sd	s1,8(sp)
    800069bc:	e04a                	sd	s2,0(sp)
    800069be:	1000                	add	s0,sp,32
    800069c0:	892a                	mv	s2,a0
    800069c2:	84ae                	mv	s1,a1
    int range = (high - low + 1);
    int val = nextRand();
    800069c4:	00000097          	auipc	ra,0x0
    800069c8:	f64080e7          	jalr	-156(ra) # 80006928 <nextRand>
    int range = (high - low + 1);
    800069cc:	412484bb          	subw	s1,s1,s2
    800069d0:	2485                	addw	s1,s1,1
    return (val % range) + low;
    800069d2:	0295653b          	remw	a0,a0,s1
}
    800069d6:	0125053b          	addw	a0,a0,s2
    800069da:	60e2                	ld	ra,24(sp)
    800069dc:	6442                	ld	s0,16(sp)
    800069de:	64a2                	ld	s1,8(sp)
    800069e0:	6902                	ld	s2,0(sp)
    800069e2:	6105                	add	sp,sp,32
    800069e4:	8082                	ret
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
