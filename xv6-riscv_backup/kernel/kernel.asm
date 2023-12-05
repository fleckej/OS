
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a2010113          	add	sp,sp,-1504 # 80008a20 <stack0>
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
    80000054:	89070713          	add	a4,a4,-1904 # 800088e0 <timer_scratch>
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
    80000066:	b4e78793          	add	a5,a5,-1202 # 80005bb0 <timervec>
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
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdcaaf>
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
    8000012e:	3c8080e7          	jalr	968(ra) # 800024f2 <either_copyin>
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
    80000188:	89c50513          	add	a0,a0,-1892 # 80010a20 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	88c48493          	add	s1,s1,-1908 # 80010a20 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	91c90913          	add	s2,s2,-1764 # 80010ab8 <cons+0x98>
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
    800001c0:	13a080e7          	jalr	314(ra) # 800022f6 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	e84080e7          	jalr	-380(ra) # 8000204e <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	84270713          	add	a4,a4,-1982 # 80010a20 <cons>
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
    80000214:	28c080e7          	jalr	652(ra) # 8000249c <either_copyout>
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
    80000228:	00010517          	auipc	a0,0x10
    8000022c:	7f850513          	add	a0,a0,2040 # 80010a20 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00010517          	auipc	a0,0x10
    80000242:	7e250513          	add	a0,a0,2018 # 80010a20 <cons>
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
    80000272:	84f72523          	sw	a5,-1974(a4) # 80010ab8 <cons+0x98>
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
    800002cc:	75850513          	add	a0,a0,1880 # 80010a20 <cons>
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
    800002f2:	25a080e7          	jalr	602(ra) # 80002548 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	72a50513          	add	a0,a0,1834 # 80010a20 <cons>
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
    8000031e:	70670713          	add	a4,a4,1798 # 80010a20 <cons>
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
    80000348:	6dc78793          	add	a5,a5,1756 # 80010a20 <cons>
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
    80000376:	7467a783          	lw	a5,1862(a5) # 80010ab8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	69a70713          	add	a4,a4,1690 # 80010a20 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	68a48493          	add	s1,s1,1674 # 80010a20 <cons>
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
    800003d6:	64e70713          	add	a4,a4,1614 # 80010a20 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	6cf72c23          	sw	a5,1752(a4) # 80010ac0 <cons+0xa0>
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
    80000412:	61278793          	add	a5,a5,1554 # 80010a20 <cons>
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
    80000436:	68c7a523          	sw	a2,1674(a5) # 80010abc <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	67e50513          	add	a0,a0,1662 # 80010ab8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	c70080e7          	jalr	-912(ra) # 800020b2 <wakeup>
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
    80000460:	5c450513          	add	a0,a0,1476 # 80010a20 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00020797          	auipc	a5,0x20
    80000478:	74478793          	add	a5,a5,1860 # 80020bb8 <devsw>
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
    8000054c:	5807ac23          	sw	zero,1432(a5) # 80010ae0 <pr+0x18>
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
    80000580:	32f72223          	sw	a5,804(a4) # 800088a0 <panicked>
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
    800005bc:	528dad83          	lw	s11,1320(s11) # 80010ae0 <pr+0x18>
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
    800005fa:	4d250513          	add	a0,a0,1234 # 80010ac8 <pr>
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
    80000758:	37450513          	add	a0,a0,884 # 80010ac8 <pr>
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
    80000774:	35848493          	add	s1,s1,856 # 80010ac8 <pr>
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
    800007d4:	31850513          	add	a0,a0,792 # 80010ae8 <uart_tx_lock>
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
    80000800:	0a47a783          	lw	a5,164(a5) # 800088a0 <panicked>
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
    80000838:	0747b783          	ld	a5,116(a5) # 800088a8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	07473703          	ld	a4,116(a4) # 800088b0 <uart_tx_w>
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
    80000862:	28aa0a13          	add	s4,s4,650 # 80010ae8 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	04248493          	add	s1,s1,66 # 800088a8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	04298993          	add	s3,s3,66 # 800088b0 <uart_tx_w>
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
    80000894:	822080e7          	jalr	-2014(ra) # 800020b2 <wakeup>
    
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
    800008d0:	21c50513          	add	a0,a0,540 # 80010ae8 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	fc47a783          	lw	a5,-60(a5) # 800088a0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	fca73703          	ld	a4,-54(a4) # 800088b0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	fba7b783          	ld	a5,-70(a5) # 800088a8 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	1ee98993          	add	s3,s3,494 # 80010ae8 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	fa648493          	add	s1,s1,-90 # 800088a8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	fa690913          	add	s2,s2,-90 # 800088b0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	734080e7          	jalr	1844(ra) # 8000204e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	1b848493          	add	s1,s1,440 # 80010ae8 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	f6e7b623          	sd	a4,-148(a5) # 800088b0 <uart_tx_w>
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
    800009ba:	13248493          	add	s1,s1,306 # 80010ae8 <uart_tx_lock>
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
    800009f8:	00021797          	auipc	a5,0x21
    800009fc:	35878793          	add	a5,a5,856 # 80021d50 <end>
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
    80000a1c:	10890913          	add	s2,s2,264 # 80010b20 <kmem>
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
    80000aba:	06a50513          	add	a0,a0,106 # 80010b20 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	sll	a1,a1,0x1b
    80000aca:	00021517          	auipc	a0,0x21
    80000ace:	28650513          	add	a0,a0,646 # 80021d50 <end>
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
    80000af0:	03448493          	add	s1,s1,52 # 80010b20 <kmem>
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
    80000b08:	01c50513          	add	a0,a0,28 # 80010b20 <kmem>
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
    80000b34:	ff050513          	add	a0,a0,-16 # 80010b20 <kmem>
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
    80000d42:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd2b1>
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
    80000e86:	a3670713          	add	a4,a4,-1482 # 800088b8 <started>
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
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	7d2080e7          	jalr	2002(ra) # 8000268a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	d30080e7          	jalr	-720(ra) # 80005bf0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	fd4080e7          	jalr	-44(ra) # 80001e9c <scheduler>
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
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	732080e7          	jalr	1842(ra) # 80002662 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00001097          	auipc	ra,0x1
    80000f3c:	752080e7          	jalr	1874(ra) # 8000268a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	c9a080e7          	jalr	-870(ra) # 80005bda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	ca8080e7          	jalr	-856(ra) # 80005bf0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	ea4080e7          	jalr	-348(ra) # 80002df4 <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	542080e7          	jalr	1346(ra) # 8000349a <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	4b8080e7          	jalr	1208(ra) # 80004418 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	d90080e7          	jalr	-624(ra) # 80005cf8 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d0e080e7          	jalr	-754(ra) # 80001c7e <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	92f72d23          	sw	a5,-1734(a4) # 800088b8 <started>
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
    80000f96:	92e7b783          	ld	a5,-1746(a5) # 800088c0 <kernel_pagetable>
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
    80001010:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd2a7>
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
    80001252:	66a7b923          	sd	a0,1650(a5) # 800088c0 <kernel_pagetable>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd2b0>
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
    80001846:	0000f497          	auipc	s1,0xf
    8000184a:	72a48493          	add	s1,s1,1834 # 80010f70 <proc>
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
    80001864:	110a0a13          	add	s4,s4,272 # 80016970 <tickslock>
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
    800018e6:	25e50513          	add	a0,a0,606 # 80010b40 <pid_lock>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	258080e7          	jalr	600(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f2:	00007597          	auipc	a1,0x7
    800018f6:	8f658593          	add	a1,a1,-1802 # 800081e8 <digits+0x1a8>
    800018fa:	0000f517          	auipc	a0,0xf
    800018fe:	25e50513          	add	a0,a0,606 # 80010b58 <wait_lock>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	240080e7          	jalr	576(ra) # 80000b42 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000190a:	0000f497          	auipc	s1,0xf
    8000190e:	66648493          	add	s1,s1,1638 # 80010f70 <proc>
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
    80001930:	04498993          	add	s3,s3,68 # 80016970 <tickslock>
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
    8000199a:	1da50513          	add	a0,a0,474 # 80010b70 <cpus>
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
    800019c2:	18270713          	add	a4,a4,386 # 80010b40 <pid_lock>
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
    800019fa:	e5a7a783          	lw	a5,-422(a5) # 80008850 <first.1>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	ca2080e7          	jalr	-862(ra) # 800026a2 <usertrapret>
}
    80001a08:	60a2                	ld	ra,8(sp)
    80001a0a:	6402                	ld	s0,0(sp)
    80001a0c:	0141                	add	sp,sp,16
    80001a0e:	8082                	ret
    first = 0;
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	e407a023          	sw	zero,-448(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001a18:	4505                	li	a0,1
    80001a1a:	00002097          	auipc	ra,0x2
    80001a1e:	a00080e7          	jalr	-1536(ra) # 8000341a <fsinit>
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
    80001a34:	11090913          	add	s2,s2,272 # 80010b40 <pid_lock>
    80001a38:	854a                	mv	a0,s2
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	198080e7          	jalr	408(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	e1278793          	add	a5,a5,-494 # 80008854 <nextpid>
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
  p->pagetable = 0;
    80001b82:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b86:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b8a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b8e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b92:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b96:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b9a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b9e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba2:	0004ac23          	sw	zero,24(s1)
}
    80001ba6:	60e2                	ld	ra,24(sp)
    80001ba8:	6442                	ld	s0,16(sp)
    80001baa:	64a2                	ld	s1,8(sp)
    80001bac:	6105                	add	sp,sp,32
    80001bae:	8082                	ret

0000000080001bb0 <allocproc>:
{
    80001bb0:	1101                	add	sp,sp,-32
    80001bb2:	ec06                	sd	ra,24(sp)
    80001bb4:	e822                	sd	s0,16(sp)
    80001bb6:	e426                	sd	s1,8(sp)
    80001bb8:	e04a                	sd	s2,0(sp)
    80001bba:	1000                	add	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bbc:	0000f497          	auipc	s1,0xf
    80001bc0:	3b448493          	add	s1,s1,948 # 80010f70 <proc>
    80001bc4:	00015917          	auipc	s2,0x15
    80001bc8:	dac90913          	add	s2,s2,-596 # 80016970 <tickslock>
    acquire(&p->lock);
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	004080e7          	jalr	4(ra) # 80000bd2 <acquire>
    if(p->state == UNUSED) {
    80001bd6:	4c9c                	lw	a5,24(s1)
    80001bd8:	cf81                	beqz	a5,80001bf0 <allocproc+0x40>
      release(&p->lock);
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	0aa080e7          	jalr	170(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be4:	16848493          	add	s1,s1,360
    80001be8:	ff2492e3          	bne	s1,s2,80001bcc <allocproc+0x1c>
  return 0;
    80001bec:	4481                	li	s1,0
    80001bee:	a889                	j	80001c40 <allocproc+0x90>
  p->pid = allocpid();
    80001bf0:	00000097          	auipc	ra,0x0
    80001bf4:	e34080e7          	jalr	-460(ra) # 80001a24 <allocpid>
    80001bf8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bfa:	4785                	li	a5,1
    80001bfc:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	ee4080e7          	jalr	-284(ra) # 80000ae2 <kalloc>
    80001c06:	892a                	mv	s2,a0
    80001c08:	eca8                	sd	a0,88(s1)
    80001c0a:	c131                	beqz	a0,80001c4e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	00000097          	auipc	ra,0x0
    80001c12:	e5c080e7          	jalr	-420(ra) # 80001a6a <proc_pagetable>
    80001c16:	892a                	mv	s2,a0
    80001c18:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c1a:	c531                	beqz	a0,80001c66 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c1c:	07000613          	li	a2,112
    80001c20:	4581                	li	a1,0
    80001c22:	06048513          	add	a0,s1,96
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	0a8080e7          	jalr	168(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001c2e:	00000797          	auipc	a5,0x0
    80001c32:	db078793          	add	a5,a5,-592 # 800019de <forkret>
    80001c36:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c38:	60bc                	ld	a5,64(s1)
    80001c3a:	6705                	lui	a4,0x1
    80001c3c:	97ba                	add	a5,a5,a4
    80001c3e:	f4bc                	sd	a5,104(s1)
}
    80001c40:	8526                	mv	a0,s1
    80001c42:	60e2                	ld	ra,24(sp)
    80001c44:	6442                	ld	s0,16(sp)
    80001c46:	64a2                	ld	s1,8(sp)
    80001c48:	6902                	ld	s2,0(sp)
    80001c4a:	6105                	add	sp,sp,32
    80001c4c:	8082                	ret
    freeproc(p);
    80001c4e:	8526                	mv	a0,s1
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	f08080e7          	jalr	-248(ra) # 80001b58 <freeproc>
    release(&p->lock);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	02c080e7          	jalr	44(ra) # 80000c86 <release>
    return 0;
    80001c62:	84ca                	mv	s1,s2
    80001c64:	bff1                	j	80001c40 <allocproc+0x90>
    freeproc(p);
    80001c66:	8526                	mv	a0,s1
    80001c68:	00000097          	auipc	ra,0x0
    80001c6c:	ef0080e7          	jalr	-272(ra) # 80001b58 <freeproc>
    release(&p->lock);
    80001c70:	8526                	mv	a0,s1
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	014080e7          	jalr	20(ra) # 80000c86 <release>
    return 0;
    80001c7a:	84ca                	mv	s1,s2
    80001c7c:	b7d1                	j	80001c40 <allocproc+0x90>

0000000080001c7e <userinit>:
{
    80001c7e:	1101                	add	sp,sp,-32
    80001c80:	ec06                	sd	ra,24(sp)
    80001c82:	e822                	sd	s0,16(sp)
    80001c84:	e426                	sd	s1,8(sp)
    80001c86:	1000                	add	s0,sp,32
  p = allocproc();
    80001c88:	00000097          	auipc	ra,0x0
    80001c8c:	f28080e7          	jalr	-216(ra) # 80001bb0 <allocproc>
    80001c90:	84aa                	mv	s1,a0
  initproc = p;
    80001c92:	00007797          	auipc	a5,0x7
    80001c96:	c2a7bb23          	sd	a0,-970(a5) # 800088c8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001c9a:	03400613          	li	a2,52
    80001c9e:	00007597          	auipc	a1,0x7
    80001ca2:	bc258593          	add	a1,a1,-1086 # 80008860 <initcode>
    80001ca6:	6928                	ld	a0,80(a0)
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	6a8080e7          	jalr	1704(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001cb0:	6785                	lui	a5,0x1
    80001cb2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cb4:	6cb8                	ld	a4,88(s1)
    80001cb6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cbe:	4641                	li	a2,16
    80001cc0:	00006597          	auipc	a1,0x6
    80001cc4:	54058593          	add	a1,a1,1344 # 80008200 <digits+0x1c0>
    80001cc8:	15848513          	add	a0,s1,344
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	14a080e7          	jalr	330(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001cd4:	00006517          	auipc	a0,0x6
    80001cd8:	53c50513          	add	a0,a0,1340 # 80008210 <digits+0x1d0>
    80001cdc:	00002097          	auipc	ra,0x2
    80001ce0:	15c080e7          	jalr	348(ra) # 80003e38 <namei>
    80001ce4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ce8:	478d                	li	a5,3
    80001cea:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cec:	8526                	mv	a0,s1
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	f98080e7          	jalr	-104(ra) # 80000c86 <release>
}
    80001cf6:	60e2                	ld	ra,24(sp)
    80001cf8:	6442                	ld	s0,16(sp)
    80001cfa:	64a2                	ld	s1,8(sp)
    80001cfc:	6105                	add	sp,sp,32
    80001cfe:	8082                	ret

0000000080001d00 <growproc>:
{
    80001d00:	1101                	add	sp,sp,-32
    80001d02:	ec06                	sd	ra,24(sp)
    80001d04:	e822                	sd	s0,16(sp)
    80001d06:	e426                	sd	s1,8(sp)
    80001d08:	e04a                	sd	s2,0(sp)
    80001d0a:	1000                	add	s0,sp,32
    80001d0c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d0e:	00000097          	auipc	ra,0x0
    80001d12:	c98080e7          	jalr	-872(ra) # 800019a6 <myproc>
    80001d16:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d18:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d1a:	01204c63          	bgtz	s2,80001d32 <growproc+0x32>
  } else if(n < 0){
    80001d1e:	02094663          	bltz	s2,80001d4a <growproc+0x4a>
  p->sz = sz;
    80001d22:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d24:	4501                	li	a0,0
}
    80001d26:	60e2                	ld	ra,24(sp)
    80001d28:	6442                	ld	s0,16(sp)
    80001d2a:	64a2                	ld	s1,8(sp)
    80001d2c:	6902                	ld	s2,0(sp)
    80001d2e:	6105                	add	sp,sp,32
    80001d30:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d32:	4691                	li	a3,4
    80001d34:	00b90633          	add	a2,s2,a1
    80001d38:	6928                	ld	a0,80(a0)
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	6d0080e7          	jalr	1744(ra) # 8000140a <uvmalloc>
    80001d42:	85aa                	mv	a1,a0
    80001d44:	fd79                	bnez	a0,80001d22 <growproc+0x22>
      return -1;
    80001d46:	557d                	li	a0,-1
    80001d48:	bff9                	j	80001d26 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d4a:	00b90633          	add	a2,s2,a1
    80001d4e:	6928                	ld	a0,80(a0)
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	672080e7          	jalr	1650(ra) # 800013c2 <uvmdealloc>
    80001d58:	85aa                	mv	a1,a0
    80001d5a:	b7e1                	j	80001d22 <growproc+0x22>

0000000080001d5c <fork>:
{
    80001d5c:	7139                	add	sp,sp,-64
    80001d5e:	fc06                	sd	ra,56(sp)
    80001d60:	f822                	sd	s0,48(sp)
    80001d62:	f426                	sd	s1,40(sp)
    80001d64:	f04a                	sd	s2,32(sp)
    80001d66:	ec4e                	sd	s3,24(sp)
    80001d68:	e852                	sd	s4,16(sp)
    80001d6a:	e456                	sd	s5,8(sp)
    80001d6c:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001d6e:	00000097          	auipc	ra,0x0
    80001d72:	c38080e7          	jalr	-968(ra) # 800019a6 <myproc>
    80001d76:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d78:	00000097          	auipc	ra,0x0
    80001d7c:	e38080e7          	jalr	-456(ra) # 80001bb0 <allocproc>
    80001d80:	10050c63          	beqz	a0,80001e98 <fork+0x13c>
    80001d84:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d86:	048ab603          	ld	a2,72(s5)
    80001d8a:	692c                	ld	a1,80(a0)
    80001d8c:	050ab503          	ld	a0,80(s5)
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	7d2080e7          	jalr	2002(ra) # 80001562 <uvmcopy>
    80001d98:	04054863          	bltz	a0,80001de8 <fork+0x8c>
  np->sz = p->sz;
    80001d9c:	048ab783          	ld	a5,72(s5)
    80001da0:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001da4:	058ab683          	ld	a3,88(s5)
    80001da8:	87b6                	mv	a5,a3
    80001daa:	058a3703          	ld	a4,88(s4)
    80001dae:	12068693          	add	a3,a3,288
    80001db2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001db6:	6788                	ld	a0,8(a5)
    80001db8:	6b8c                	ld	a1,16(a5)
    80001dba:	6f90                	ld	a2,24(a5)
    80001dbc:	01073023          	sd	a6,0(a4)
    80001dc0:	e708                	sd	a0,8(a4)
    80001dc2:	eb0c                	sd	a1,16(a4)
    80001dc4:	ef10                	sd	a2,24(a4)
    80001dc6:	02078793          	add	a5,a5,32
    80001dca:	02070713          	add	a4,a4,32
    80001dce:	fed792e3          	bne	a5,a3,80001db2 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd2:	058a3783          	ld	a5,88(s4)
    80001dd6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dda:	0d0a8493          	add	s1,s5,208
    80001dde:	0d0a0913          	add	s2,s4,208
    80001de2:	150a8993          	add	s3,s5,336
    80001de6:	a00d                	j	80001e08 <fork+0xac>
    freeproc(np);
    80001de8:	8552                	mv	a0,s4
    80001dea:	00000097          	auipc	ra,0x0
    80001dee:	d6e080e7          	jalr	-658(ra) # 80001b58 <freeproc>
    release(&np->lock);
    80001df2:	8552                	mv	a0,s4
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	e92080e7          	jalr	-366(ra) # 80000c86 <release>
    return -1;
    80001dfc:	597d                	li	s2,-1
    80001dfe:	a059                	j	80001e84 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e00:	04a1                	add	s1,s1,8
    80001e02:	0921                	add	s2,s2,8
    80001e04:	01348b63          	beq	s1,s3,80001e1a <fork+0xbe>
    if(p->ofile[i])
    80001e08:	6088                	ld	a0,0(s1)
    80001e0a:	d97d                	beqz	a0,80001e00 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e0c:	00002097          	auipc	ra,0x2
    80001e10:	69e080e7          	jalr	1694(ra) # 800044aa <filedup>
    80001e14:	00a93023          	sd	a0,0(s2)
    80001e18:	b7e5                	j	80001e00 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e1a:	150ab503          	ld	a0,336(s5)
    80001e1e:	00002097          	auipc	ra,0x2
    80001e22:	836080e7          	jalr	-1994(ra) # 80003654 <idup>
    80001e26:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e2a:	4641                	li	a2,16
    80001e2c:	158a8593          	add	a1,s5,344
    80001e30:	158a0513          	add	a0,s4,344
    80001e34:	fffff097          	auipc	ra,0xfffff
    80001e38:	fe2080e7          	jalr	-30(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e3c:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e40:	8552                	mv	a0,s4
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	e44080e7          	jalr	-444(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001e4a:	0000f497          	auipc	s1,0xf
    80001e4e:	d0e48493          	add	s1,s1,-754 # 80010b58 <wait_lock>
    80001e52:	8526                	mv	a0,s1
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	d7e080e7          	jalr	-642(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001e5c:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e60:	8526                	mv	a0,s1
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e24080e7          	jalr	-476(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001e6a:	8552                	mv	a0,s4
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	d66080e7          	jalr	-666(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001e74:	478d                	li	a5,3
    80001e76:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e7a:	8552                	mv	a0,s4
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	e0a080e7          	jalr	-502(ra) # 80000c86 <release>
}
    80001e84:	854a                	mv	a0,s2
    80001e86:	70e2                	ld	ra,56(sp)
    80001e88:	7442                	ld	s0,48(sp)
    80001e8a:	74a2                	ld	s1,40(sp)
    80001e8c:	7902                	ld	s2,32(sp)
    80001e8e:	69e2                	ld	s3,24(sp)
    80001e90:	6a42                	ld	s4,16(sp)
    80001e92:	6aa2                	ld	s5,8(sp)
    80001e94:	6121                	add	sp,sp,64
    80001e96:	8082                	ret
    return -1;
    80001e98:	597d                	li	s2,-1
    80001e9a:	b7ed                	j	80001e84 <fork+0x128>

0000000080001e9c <scheduler>:
{
    80001e9c:	7139                	add	sp,sp,-64
    80001e9e:	fc06                	sd	ra,56(sp)
    80001ea0:	f822                	sd	s0,48(sp)
    80001ea2:	f426                	sd	s1,40(sp)
    80001ea4:	f04a                	sd	s2,32(sp)
    80001ea6:	ec4e                	sd	s3,24(sp)
    80001ea8:	e852                	sd	s4,16(sp)
    80001eaa:	e456                	sd	s5,8(sp)
    80001eac:	e05a                	sd	s6,0(sp)
    80001eae:	0080                	add	s0,sp,64
    80001eb0:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eb4:	00779a93          	sll	s5,a5,0x7
    80001eb8:	0000f717          	auipc	a4,0xf
    80001ebc:	c8870713          	add	a4,a4,-888 # 80010b40 <pid_lock>
    80001ec0:	9756                	add	a4,a4,s5
    80001ec2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ec6:	0000f717          	auipc	a4,0xf
    80001eca:	cb270713          	add	a4,a4,-846 # 80010b78 <cpus+0x8>
    80001ece:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed0:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed2:	4b11                	li	s6,4
        c->proc = p;
    80001ed4:	079e                	sll	a5,a5,0x7
    80001ed6:	0000fa17          	auipc	s4,0xf
    80001eda:	c6aa0a13          	add	s4,s4,-918 # 80010b40 <pid_lock>
    80001ede:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee0:	00015917          	auipc	s2,0x15
    80001ee4:	a9090913          	add	s2,s2,-1392 # 80016970 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ee8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001eec:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef0:	10079073          	csrw	sstatus,a5
    80001ef4:	0000f497          	auipc	s1,0xf
    80001ef8:	07c48493          	add	s1,s1,124 # 80010f70 <proc>
    80001efc:	a811                	j	80001f10 <scheduler+0x74>
      release(&p->lock);
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	d86080e7          	jalr	-634(ra) # 80000c86 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f08:	16848493          	add	s1,s1,360
    80001f0c:	fd248ee3          	beq	s1,s2,80001ee8 <scheduler+0x4c>
      acquire(&p->lock);
    80001f10:	8526                	mv	a0,s1
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	cc0080e7          	jalr	-832(ra) # 80000bd2 <acquire>
      if(p->state == RUNNABLE) {
    80001f1a:	4c9c                	lw	a5,24(s1)
    80001f1c:	ff3791e3          	bne	a5,s3,80001efe <scheduler+0x62>
        p->state = RUNNING;
    80001f20:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f24:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f28:	06048593          	add	a1,s1,96
    80001f2c:	8556                	mv	a0,s5
    80001f2e:	00000097          	auipc	ra,0x0
    80001f32:	6ca080e7          	jalr	1738(ra) # 800025f8 <swtch>
        c->proc = 0;
    80001f36:	020a3823          	sd	zero,48(s4)
    80001f3a:	b7d1                	j	80001efe <scheduler+0x62>

0000000080001f3c <sched>:
{
    80001f3c:	7179                	add	sp,sp,-48
    80001f3e:	f406                	sd	ra,40(sp)
    80001f40:	f022                	sd	s0,32(sp)
    80001f42:	ec26                	sd	s1,24(sp)
    80001f44:	e84a                	sd	s2,16(sp)
    80001f46:	e44e                	sd	s3,8(sp)
    80001f48:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    80001f4a:	00000097          	auipc	ra,0x0
    80001f4e:	a5c080e7          	jalr	-1444(ra) # 800019a6 <myproc>
    80001f52:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	c04080e7          	jalr	-1020(ra) # 80000b58 <holding>
    80001f5c:	c93d                	beqz	a0,80001fd2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f5e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f60:	2781                	sext.w	a5,a5
    80001f62:	079e                	sll	a5,a5,0x7
    80001f64:	0000f717          	auipc	a4,0xf
    80001f68:	bdc70713          	add	a4,a4,-1060 # 80010b40 <pid_lock>
    80001f6c:	97ba                	add	a5,a5,a4
    80001f6e:	0a87a703          	lw	a4,168(a5)
    80001f72:	4785                	li	a5,1
    80001f74:	06f71763          	bne	a4,a5,80001fe2 <sched+0xa6>
  if(p->state == RUNNING)
    80001f78:	4c98                	lw	a4,24(s1)
    80001f7a:	4791                	li	a5,4
    80001f7c:	06f70b63          	beq	a4,a5,80001ff2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f80:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f84:	8b89                	and	a5,a5,2
  if(intr_get())
    80001f86:	efb5                	bnez	a5,80002002 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f88:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f8a:	0000f917          	auipc	s2,0xf
    80001f8e:	bb690913          	add	s2,s2,-1098 # 80010b40 <pid_lock>
    80001f92:	2781                	sext.w	a5,a5
    80001f94:	079e                	sll	a5,a5,0x7
    80001f96:	97ca                	add	a5,a5,s2
    80001f98:	0ac7a983          	lw	s3,172(a5)
    80001f9c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f9e:	2781                	sext.w	a5,a5
    80001fa0:	079e                	sll	a5,a5,0x7
    80001fa2:	0000f597          	auipc	a1,0xf
    80001fa6:	bd658593          	add	a1,a1,-1066 # 80010b78 <cpus+0x8>
    80001faa:	95be                	add	a1,a1,a5
    80001fac:	06048513          	add	a0,s1,96
    80001fb0:	00000097          	auipc	ra,0x0
    80001fb4:	648080e7          	jalr	1608(ra) # 800025f8 <swtch>
    80001fb8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fba:	2781                	sext.w	a5,a5
    80001fbc:	079e                	sll	a5,a5,0x7
    80001fbe:	993e                	add	s2,s2,a5
    80001fc0:	0b392623          	sw	s3,172(s2)
}
    80001fc4:	70a2                	ld	ra,40(sp)
    80001fc6:	7402                	ld	s0,32(sp)
    80001fc8:	64e2                	ld	s1,24(sp)
    80001fca:	6942                	ld	s2,16(sp)
    80001fcc:	69a2                	ld	s3,8(sp)
    80001fce:	6145                	add	sp,sp,48
    80001fd0:	8082                	ret
    panic("sched p->lock");
    80001fd2:	00006517          	auipc	a0,0x6
    80001fd6:	24650513          	add	a0,a0,582 # 80008218 <digits+0x1d8>
    80001fda:	ffffe097          	auipc	ra,0xffffe
    80001fde:	562080e7          	jalr	1378(ra) # 8000053c <panic>
    panic("sched locks");
    80001fe2:	00006517          	auipc	a0,0x6
    80001fe6:	24650513          	add	a0,a0,582 # 80008228 <digits+0x1e8>
    80001fea:	ffffe097          	auipc	ra,0xffffe
    80001fee:	552080e7          	jalr	1362(ra) # 8000053c <panic>
    panic("sched running");
    80001ff2:	00006517          	auipc	a0,0x6
    80001ff6:	24650513          	add	a0,a0,582 # 80008238 <digits+0x1f8>
    80001ffa:	ffffe097          	auipc	ra,0xffffe
    80001ffe:	542080e7          	jalr	1346(ra) # 8000053c <panic>
    panic("sched interruptible");
    80002002:	00006517          	auipc	a0,0x6
    80002006:	24650513          	add	a0,a0,582 # 80008248 <digits+0x208>
    8000200a:	ffffe097          	auipc	ra,0xffffe
    8000200e:	532080e7          	jalr	1330(ra) # 8000053c <panic>

0000000080002012 <yield>:
{
    80002012:	1101                	add	sp,sp,-32
    80002014:	ec06                	sd	ra,24(sp)
    80002016:	e822                	sd	s0,16(sp)
    80002018:	e426                	sd	s1,8(sp)
    8000201a:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    8000201c:	00000097          	auipc	ra,0x0
    80002020:	98a080e7          	jalr	-1654(ra) # 800019a6 <myproc>
    80002024:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	bac080e7          	jalr	-1108(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    8000202e:	478d                	li	a5,3
    80002030:	cc9c                	sw	a5,24(s1)
  sched();
    80002032:	00000097          	auipc	ra,0x0
    80002036:	f0a080e7          	jalr	-246(ra) # 80001f3c <sched>
  release(&p->lock);
    8000203a:	8526                	mv	a0,s1
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	c4a080e7          	jalr	-950(ra) # 80000c86 <release>
}
    80002044:	60e2                	ld	ra,24(sp)
    80002046:	6442                	ld	s0,16(sp)
    80002048:	64a2                	ld	s1,8(sp)
    8000204a:	6105                	add	sp,sp,32
    8000204c:	8082                	ret

000000008000204e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000204e:	7179                	add	sp,sp,-48
    80002050:	f406                	sd	ra,40(sp)
    80002052:	f022                	sd	s0,32(sp)
    80002054:	ec26                	sd	s1,24(sp)
    80002056:	e84a                	sd	s2,16(sp)
    80002058:	e44e                	sd	s3,8(sp)
    8000205a:	1800                	add	s0,sp,48
    8000205c:	89aa                	mv	s3,a0
    8000205e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002060:	00000097          	auipc	ra,0x0
    80002064:	946080e7          	jalr	-1722(ra) # 800019a6 <myproc>
    80002068:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	b68080e7          	jalr	-1176(ra) # 80000bd2 <acquire>
  release(lk);
    80002072:	854a                	mv	a0,s2
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	c12080e7          	jalr	-1006(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    8000207c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002080:	4789                	li	a5,2
    80002082:	cc9c                	sw	a5,24(s1)

  sched();
    80002084:	00000097          	auipc	ra,0x0
    80002088:	eb8080e7          	jalr	-328(ra) # 80001f3c <sched>

  // Tidy up.
  p->chan = 0;
    8000208c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002090:	8526                	mv	a0,s1
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	bf4080e7          	jalr	-1036(ra) # 80000c86 <release>
  acquire(lk);
    8000209a:	854a                	mv	a0,s2
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	b36080e7          	jalr	-1226(ra) # 80000bd2 <acquire>
}
    800020a4:	70a2                	ld	ra,40(sp)
    800020a6:	7402                	ld	s0,32(sp)
    800020a8:	64e2                	ld	s1,24(sp)
    800020aa:	6942                	ld	s2,16(sp)
    800020ac:	69a2                	ld	s3,8(sp)
    800020ae:	6145                	add	sp,sp,48
    800020b0:	8082                	ret

00000000800020b2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020b2:	7139                	add	sp,sp,-64
    800020b4:	fc06                	sd	ra,56(sp)
    800020b6:	f822                	sd	s0,48(sp)
    800020b8:	f426                	sd	s1,40(sp)
    800020ba:	f04a                	sd	s2,32(sp)
    800020bc:	ec4e                	sd	s3,24(sp)
    800020be:	e852                	sd	s4,16(sp)
    800020c0:	e456                	sd	s5,8(sp)
    800020c2:	0080                	add	s0,sp,64
    800020c4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020c6:	0000f497          	auipc	s1,0xf
    800020ca:	eaa48493          	add	s1,s1,-342 # 80010f70 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020ce:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020d0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d2:	00015917          	auipc	s2,0x15
    800020d6:	89e90913          	add	s2,s2,-1890 # 80016970 <tickslock>
    800020da:	a811                	j	800020ee <wakeup+0x3c>
      }
      release(&p->lock);
    800020dc:	8526                	mv	a0,s1
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	ba8080e7          	jalr	-1112(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020e6:	16848493          	add	s1,s1,360
    800020ea:	03248663          	beq	s1,s2,80002116 <wakeup+0x64>
    if(p != myproc()){
    800020ee:	00000097          	auipc	ra,0x0
    800020f2:	8b8080e7          	jalr	-1864(ra) # 800019a6 <myproc>
    800020f6:	fea488e3          	beq	s1,a0,800020e6 <wakeup+0x34>
      acquire(&p->lock);
    800020fa:	8526                	mv	a0,s1
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	ad6080e7          	jalr	-1322(ra) # 80000bd2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002104:	4c9c                	lw	a5,24(s1)
    80002106:	fd379be3          	bne	a5,s3,800020dc <wakeup+0x2a>
    8000210a:	709c                	ld	a5,32(s1)
    8000210c:	fd4798e3          	bne	a5,s4,800020dc <wakeup+0x2a>
        p->state = RUNNABLE;
    80002110:	0154ac23          	sw	s5,24(s1)
    80002114:	b7e1                	j	800020dc <wakeup+0x2a>
    }
  }
}
    80002116:	70e2                	ld	ra,56(sp)
    80002118:	7442                	ld	s0,48(sp)
    8000211a:	74a2                	ld	s1,40(sp)
    8000211c:	7902                	ld	s2,32(sp)
    8000211e:	69e2                	ld	s3,24(sp)
    80002120:	6a42                	ld	s4,16(sp)
    80002122:	6aa2                	ld	s5,8(sp)
    80002124:	6121                	add	sp,sp,64
    80002126:	8082                	ret

0000000080002128 <reparent>:
{
    80002128:	7179                	add	sp,sp,-48
    8000212a:	f406                	sd	ra,40(sp)
    8000212c:	f022                	sd	s0,32(sp)
    8000212e:	ec26                	sd	s1,24(sp)
    80002130:	e84a                	sd	s2,16(sp)
    80002132:	e44e                	sd	s3,8(sp)
    80002134:	e052                	sd	s4,0(sp)
    80002136:	1800                	add	s0,sp,48
    80002138:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000213a:	0000f497          	auipc	s1,0xf
    8000213e:	e3648493          	add	s1,s1,-458 # 80010f70 <proc>
      pp->parent = initproc;
    80002142:	00006a17          	auipc	s4,0x6
    80002146:	786a0a13          	add	s4,s4,1926 # 800088c8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000214a:	00015997          	auipc	s3,0x15
    8000214e:	82698993          	add	s3,s3,-2010 # 80016970 <tickslock>
    80002152:	a029                	j	8000215c <reparent+0x34>
    80002154:	16848493          	add	s1,s1,360
    80002158:	01348d63          	beq	s1,s3,80002172 <reparent+0x4a>
    if(pp->parent == p){
    8000215c:	7c9c                	ld	a5,56(s1)
    8000215e:	ff279be3          	bne	a5,s2,80002154 <reparent+0x2c>
      pp->parent = initproc;
    80002162:	000a3503          	ld	a0,0(s4)
    80002166:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002168:	00000097          	auipc	ra,0x0
    8000216c:	f4a080e7          	jalr	-182(ra) # 800020b2 <wakeup>
    80002170:	b7d5                	j	80002154 <reparent+0x2c>
}
    80002172:	70a2                	ld	ra,40(sp)
    80002174:	7402                	ld	s0,32(sp)
    80002176:	64e2                	ld	s1,24(sp)
    80002178:	6942                	ld	s2,16(sp)
    8000217a:	69a2                	ld	s3,8(sp)
    8000217c:	6a02                	ld	s4,0(sp)
    8000217e:	6145                	add	sp,sp,48
    80002180:	8082                	ret

0000000080002182 <exit>:
{
    80002182:	7179                	add	sp,sp,-48
    80002184:	f406                	sd	ra,40(sp)
    80002186:	f022                	sd	s0,32(sp)
    80002188:	ec26                	sd	s1,24(sp)
    8000218a:	e84a                	sd	s2,16(sp)
    8000218c:	e44e                	sd	s3,8(sp)
    8000218e:	e052                	sd	s4,0(sp)
    80002190:	1800                	add	s0,sp,48
    80002192:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002194:	00000097          	auipc	ra,0x0
    80002198:	812080e7          	jalr	-2030(ra) # 800019a6 <myproc>
    8000219c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000219e:	00006797          	auipc	a5,0x6
    800021a2:	72a7b783          	ld	a5,1834(a5) # 800088c8 <initproc>
    800021a6:	0d050493          	add	s1,a0,208
    800021aa:	15050913          	add	s2,a0,336
    800021ae:	02a79363          	bne	a5,a0,800021d4 <exit+0x52>
    panic("init exiting");
    800021b2:	00006517          	auipc	a0,0x6
    800021b6:	0ae50513          	add	a0,a0,174 # 80008260 <digits+0x220>
    800021ba:	ffffe097          	auipc	ra,0xffffe
    800021be:	382080e7          	jalr	898(ra) # 8000053c <panic>
      fileclose(f);
    800021c2:	00002097          	auipc	ra,0x2
    800021c6:	33a080e7          	jalr	826(ra) # 800044fc <fileclose>
      p->ofile[fd] = 0;
    800021ca:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021ce:	04a1                	add	s1,s1,8
    800021d0:	01248563          	beq	s1,s2,800021da <exit+0x58>
    if(p->ofile[fd]){
    800021d4:	6088                	ld	a0,0(s1)
    800021d6:	f575                	bnez	a0,800021c2 <exit+0x40>
    800021d8:	bfdd                	j	800021ce <exit+0x4c>
  begin_op();
    800021da:	00002097          	auipc	ra,0x2
    800021de:	e5e080e7          	jalr	-418(ra) # 80004038 <begin_op>
  iput(p->cwd);
    800021e2:	1509b503          	ld	a0,336(s3)
    800021e6:	00001097          	auipc	ra,0x1
    800021ea:	666080e7          	jalr	1638(ra) # 8000384c <iput>
  end_op();
    800021ee:	00002097          	auipc	ra,0x2
    800021f2:	ec4080e7          	jalr	-316(ra) # 800040b2 <end_op>
  p->cwd = 0;
    800021f6:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800021fa:	0000f497          	auipc	s1,0xf
    800021fe:	95e48493          	add	s1,s1,-1698 # 80010b58 <wait_lock>
    80002202:	8526                	mv	a0,s1
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	9ce080e7          	jalr	-1586(ra) # 80000bd2 <acquire>
  reparent(p);
    8000220c:	854e                	mv	a0,s3
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	f1a080e7          	jalr	-230(ra) # 80002128 <reparent>
  wakeup(p->parent);
    80002216:	0389b503          	ld	a0,56(s3)
    8000221a:	00000097          	auipc	ra,0x0
    8000221e:	e98080e7          	jalr	-360(ra) # 800020b2 <wakeup>
  acquire(&p->lock);
    80002222:	854e                	mv	a0,s3
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	9ae080e7          	jalr	-1618(ra) # 80000bd2 <acquire>
  p->xstate = status;
    8000222c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002230:	4795                	li	a5,5
    80002232:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002236:	8526                	mv	a0,s1
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	a4e080e7          	jalr	-1458(ra) # 80000c86 <release>
  sched();
    80002240:	00000097          	auipc	ra,0x0
    80002244:	cfc080e7          	jalr	-772(ra) # 80001f3c <sched>
  panic("zombie exit");
    80002248:	00006517          	auipc	a0,0x6
    8000224c:	02850513          	add	a0,a0,40 # 80008270 <digits+0x230>
    80002250:	ffffe097          	auipc	ra,0xffffe
    80002254:	2ec080e7          	jalr	748(ra) # 8000053c <panic>

0000000080002258 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002258:	7179                	add	sp,sp,-48
    8000225a:	f406                	sd	ra,40(sp)
    8000225c:	f022                	sd	s0,32(sp)
    8000225e:	ec26                	sd	s1,24(sp)
    80002260:	e84a                	sd	s2,16(sp)
    80002262:	e44e                	sd	s3,8(sp)
    80002264:	1800                	add	s0,sp,48
    80002266:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002268:	0000f497          	auipc	s1,0xf
    8000226c:	d0848493          	add	s1,s1,-760 # 80010f70 <proc>
    80002270:	00014997          	auipc	s3,0x14
    80002274:	70098993          	add	s3,s3,1792 # 80016970 <tickslock>
    acquire(&p->lock);
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	958080e7          	jalr	-1704(ra) # 80000bd2 <acquire>
    if(p->pid == pid){
    80002282:	589c                	lw	a5,48(s1)
    80002284:	01278d63          	beq	a5,s2,8000229e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002288:	8526                	mv	a0,s1
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	9fc080e7          	jalr	-1540(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002292:	16848493          	add	s1,s1,360
    80002296:	ff3491e3          	bne	s1,s3,80002278 <kill+0x20>
  }
  return -1;
    8000229a:	557d                	li	a0,-1
    8000229c:	a829                	j	800022b6 <kill+0x5e>
      p->killed = 1;
    8000229e:	4785                	li	a5,1
    800022a0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022a2:	4c98                	lw	a4,24(s1)
    800022a4:	4789                	li	a5,2
    800022a6:	00f70f63          	beq	a4,a5,800022c4 <kill+0x6c>
      release(&p->lock);
    800022aa:	8526                	mv	a0,s1
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	9da080e7          	jalr	-1574(ra) # 80000c86 <release>
      return 0;
    800022b4:	4501                	li	a0,0
}
    800022b6:	70a2                	ld	ra,40(sp)
    800022b8:	7402                	ld	s0,32(sp)
    800022ba:	64e2                	ld	s1,24(sp)
    800022bc:	6942                	ld	s2,16(sp)
    800022be:	69a2                	ld	s3,8(sp)
    800022c0:	6145                	add	sp,sp,48
    800022c2:	8082                	ret
        p->state = RUNNABLE;
    800022c4:	478d                	li	a5,3
    800022c6:	cc9c                	sw	a5,24(s1)
    800022c8:	b7cd                	j	800022aa <kill+0x52>

00000000800022ca <setkilled>:

void
setkilled(struct proc *p)
{
    800022ca:	1101                	add	sp,sp,-32
    800022cc:	ec06                	sd	ra,24(sp)
    800022ce:	e822                	sd	s0,16(sp)
    800022d0:	e426                	sd	s1,8(sp)
    800022d2:	1000                	add	s0,sp,32
    800022d4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	8fc080e7          	jalr	-1796(ra) # 80000bd2 <acquire>
  p->killed = 1;
    800022de:	4785                	li	a5,1
    800022e0:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	9a2080e7          	jalr	-1630(ra) # 80000c86 <release>
}
    800022ec:	60e2                	ld	ra,24(sp)
    800022ee:	6442                	ld	s0,16(sp)
    800022f0:	64a2                	ld	s1,8(sp)
    800022f2:	6105                	add	sp,sp,32
    800022f4:	8082                	ret

00000000800022f6 <killed>:

int
killed(struct proc *p)
{
    800022f6:	1101                	add	sp,sp,-32
    800022f8:	ec06                	sd	ra,24(sp)
    800022fa:	e822                	sd	s0,16(sp)
    800022fc:	e426                	sd	s1,8(sp)
    800022fe:	e04a                	sd	s2,0(sp)
    80002300:	1000                	add	s0,sp,32
    80002302:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	8ce080e7          	jalr	-1842(ra) # 80000bd2 <acquire>
  k = p->killed;
    8000230c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002310:	8526                	mv	a0,s1
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	974080e7          	jalr	-1676(ra) # 80000c86 <release>
  return k;
}
    8000231a:	854a                	mv	a0,s2
    8000231c:	60e2                	ld	ra,24(sp)
    8000231e:	6442                	ld	s0,16(sp)
    80002320:	64a2                	ld	s1,8(sp)
    80002322:	6902                	ld	s2,0(sp)
    80002324:	6105                	add	sp,sp,32
    80002326:	8082                	ret

0000000080002328 <wait>:
{
    80002328:	715d                	add	sp,sp,-80
    8000232a:	e486                	sd	ra,72(sp)
    8000232c:	e0a2                	sd	s0,64(sp)
    8000232e:	fc26                	sd	s1,56(sp)
    80002330:	f84a                	sd	s2,48(sp)
    80002332:	f44e                	sd	s3,40(sp)
    80002334:	f052                	sd	s4,32(sp)
    80002336:	ec56                	sd	s5,24(sp)
    80002338:	e85a                	sd	s6,16(sp)
    8000233a:	e45e                	sd	s7,8(sp)
    8000233c:	e062                	sd	s8,0(sp)
    8000233e:	0880                	add	s0,sp,80
    80002340:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	664080e7          	jalr	1636(ra) # 800019a6 <myproc>
    8000234a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000234c:	0000f517          	auipc	a0,0xf
    80002350:	80c50513          	add	a0,a0,-2036 # 80010b58 <wait_lock>
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	87e080e7          	jalr	-1922(ra) # 80000bd2 <acquire>
    havekids = 0;
    8000235c:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000235e:	4a15                	li	s4,5
        havekids = 1;
    80002360:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002362:	00014997          	auipc	s3,0x14
    80002366:	60e98993          	add	s3,s3,1550 # 80016970 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000236a:	0000ec17          	auipc	s8,0xe
    8000236e:	7eec0c13          	add	s8,s8,2030 # 80010b58 <wait_lock>
    80002372:	a0d1                	j	80002436 <wait+0x10e>
          pid = pp->pid;
    80002374:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002378:	000b0e63          	beqz	s6,80002394 <wait+0x6c>
    8000237c:	4691                	li	a3,4
    8000237e:	02c48613          	add	a2,s1,44
    80002382:	85da                	mv	a1,s6
    80002384:	05093503          	ld	a0,80(s2)
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	2de080e7          	jalr	734(ra) # 80001666 <copyout>
    80002390:	04054163          	bltz	a0,800023d2 <wait+0xaa>
          freeproc(pp);
    80002394:	8526                	mv	a0,s1
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	7c2080e7          	jalr	1986(ra) # 80001b58 <freeproc>
          release(&pp->lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	8e6080e7          	jalr	-1818(ra) # 80000c86 <release>
          release(&wait_lock);
    800023a8:	0000e517          	auipc	a0,0xe
    800023ac:	7b050513          	add	a0,a0,1968 # 80010b58 <wait_lock>
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8d6080e7          	jalr	-1834(ra) # 80000c86 <release>
}
    800023b8:	854e                	mv	a0,s3
    800023ba:	60a6                	ld	ra,72(sp)
    800023bc:	6406                	ld	s0,64(sp)
    800023be:	74e2                	ld	s1,56(sp)
    800023c0:	7942                	ld	s2,48(sp)
    800023c2:	79a2                	ld	s3,40(sp)
    800023c4:	7a02                	ld	s4,32(sp)
    800023c6:	6ae2                	ld	s5,24(sp)
    800023c8:	6b42                	ld	s6,16(sp)
    800023ca:	6ba2                	ld	s7,8(sp)
    800023cc:	6c02                	ld	s8,0(sp)
    800023ce:	6161                	add	sp,sp,80
    800023d0:	8082                	ret
            release(&pp->lock);
    800023d2:	8526                	mv	a0,s1
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	8b2080e7          	jalr	-1870(ra) # 80000c86 <release>
            release(&wait_lock);
    800023dc:	0000e517          	auipc	a0,0xe
    800023e0:	77c50513          	add	a0,a0,1916 # 80010b58 <wait_lock>
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	8a2080e7          	jalr	-1886(ra) # 80000c86 <release>
            return -1;
    800023ec:	59fd                	li	s3,-1
    800023ee:	b7e9                	j	800023b8 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023f0:	16848493          	add	s1,s1,360
    800023f4:	03348463          	beq	s1,s3,8000241c <wait+0xf4>
      if(pp->parent == p){
    800023f8:	7c9c                	ld	a5,56(s1)
    800023fa:	ff279be3          	bne	a5,s2,800023f0 <wait+0xc8>
        acquire(&pp->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	7d2080e7          	jalr	2002(ra) # 80000bd2 <acquire>
        if(pp->state == ZOMBIE){
    80002408:	4c9c                	lw	a5,24(s1)
    8000240a:	f74785e3          	beq	a5,s4,80002374 <wait+0x4c>
        release(&pp->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	876080e7          	jalr	-1930(ra) # 80000c86 <release>
        havekids = 1;
    80002418:	8756                	mv	a4,s5
    8000241a:	bfd9                	j	800023f0 <wait+0xc8>
    if(!havekids || killed(p)){
    8000241c:	c31d                	beqz	a4,80002442 <wait+0x11a>
    8000241e:	854a                	mv	a0,s2
    80002420:	00000097          	auipc	ra,0x0
    80002424:	ed6080e7          	jalr	-298(ra) # 800022f6 <killed>
    80002428:	ed09                	bnez	a0,80002442 <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000242a:	85e2                	mv	a1,s8
    8000242c:	854a                	mv	a0,s2
    8000242e:	00000097          	auipc	ra,0x0
    80002432:	c20080e7          	jalr	-992(ra) # 8000204e <sleep>
    havekids = 0;
    80002436:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002438:	0000f497          	auipc	s1,0xf
    8000243c:	b3848493          	add	s1,s1,-1224 # 80010f70 <proc>
    80002440:	bf65                	j	800023f8 <wait+0xd0>
      release(&wait_lock);
    80002442:	0000e517          	auipc	a0,0xe
    80002446:	71650513          	add	a0,a0,1814 # 80010b58 <wait_lock>
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	83c080e7          	jalr	-1988(ra) # 80000c86 <release>
      return -1;
    80002452:	59fd                	li	s3,-1
    80002454:	b795                	j	800023b8 <wait+0x90>

0000000080002456 <getfilenum>:

int
getfilenum(int pid)
{
    80002456:	1141                	add	sp,sp,-16
    80002458:	e422                	sd	s0,8(sp)
    8000245a:	0800                	add	s0,sp,16
  struct proc *p;
  int open = 0, fd;
  for(p = proc; p < &proc[NPROC]; p++){
    8000245c:	0000f797          	auipc	a5,0xf
    80002460:	b1478793          	add	a5,a5,-1260 # 80010f70 <proc>
    80002464:	00014697          	auipc	a3,0x14
    80002468:	50c68693          	add	a3,a3,1292 # 80016970 <tickslock>
    if (p->pid == pid){
    8000246c:	5b98                	lw	a4,48(a5)
    8000246e:	00a70a63          	beq	a4,a0,80002482 <getfilenum+0x2c>
  for(p = proc; p < &proc[NPROC]; p++){
    80002472:	16878793          	add	a5,a5,360
    80002476:	fed79be3          	bne	a5,a3,8000246c <getfilenum+0x16>
        }
      }
      return open;
    }
  }
  return -1;
    8000247a:	557d                	li	a0,-1
}
    8000247c:	6422                	ld	s0,8(sp)
    8000247e:	0141                	add	sp,sp,16
    80002480:	8082                	ret
    80002482:	0d078713          	add	a4,a5,208
    80002486:	15078793          	add	a5,a5,336
  int open = 0, fd;
    8000248a:	4501                	li	a0,0
    8000248c:	a029                	j	80002496 <getfilenum+0x40>
          open++;
    8000248e:	2505                	addw	a0,a0,1
      for(fd = 0; fd < NOFILE; fd++){
    80002490:	0721                	add	a4,a4,8
    80002492:	fef705e3          	beq	a4,a5,8000247c <getfilenum+0x26>
        if(p->ofile[fd]){
    80002496:	6314                	ld	a3,0(a4)
    80002498:	fafd                	bnez	a3,8000248e <getfilenum+0x38>
    8000249a:	bfdd                	j	80002490 <getfilenum+0x3a>

000000008000249c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000249c:	7179                	add	sp,sp,-48
    8000249e:	f406                	sd	ra,40(sp)
    800024a0:	f022                	sd	s0,32(sp)
    800024a2:	ec26                	sd	s1,24(sp)
    800024a4:	e84a                	sd	s2,16(sp)
    800024a6:	e44e                	sd	s3,8(sp)
    800024a8:	e052                	sd	s4,0(sp)
    800024aa:	1800                	add	s0,sp,48
    800024ac:	84aa                	mv	s1,a0
    800024ae:	892e                	mv	s2,a1
    800024b0:	89b2                	mv	s3,a2
    800024b2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	4f2080e7          	jalr	1266(ra) # 800019a6 <myproc>
  if(user_dst){
    800024bc:	c08d                	beqz	s1,800024de <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024be:	86d2                	mv	a3,s4
    800024c0:	864e                	mv	a2,s3
    800024c2:	85ca                	mv	a1,s2
    800024c4:	6928                	ld	a0,80(a0)
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	1a0080e7          	jalr	416(ra) # 80001666 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024ce:	70a2                	ld	ra,40(sp)
    800024d0:	7402                	ld	s0,32(sp)
    800024d2:	64e2                	ld	s1,24(sp)
    800024d4:	6942                	ld	s2,16(sp)
    800024d6:	69a2                	ld	s3,8(sp)
    800024d8:	6a02                	ld	s4,0(sp)
    800024da:	6145                	add	sp,sp,48
    800024dc:	8082                	ret
    memmove((char *)dst, src, len);
    800024de:	000a061b          	sext.w	a2,s4
    800024e2:	85ce                	mv	a1,s3
    800024e4:	854a                	mv	a0,s2
    800024e6:	fffff097          	auipc	ra,0xfffff
    800024ea:	844080e7          	jalr	-1980(ra) # 80000d2a <memmove>
    return 0;
    800024ee:	8526                	mv	a0,s1
    800024f0:	bff9                	j	800024ce <either_copyout+0x32>

00000000800024f2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024f2:	7179                	add	sp,sp,-48
    800024f4:	f406                	sd	ra,40(sp)
    800024f6:	f022                	sd	s0,32(sp)
    800024f8:	ec26                	sd	s1,24(sp)
    800024fa:	e84a                	sd	s2,16(sp)
    800024fc:	e44e                	sd	s3,8(sp)
    800024fe:	e052                	sd	s4,0(sp)
    80002500:	1800                	add	s0,sp,48
    80002502:	892a                	mv	s2,a0
    80002504:	84ae                	mv	s1,a1
    80002506:	89b2                	mv	s3,a2
    80002508:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	49c080e7          	jalr	1180(ra) # 800019a6 <myproc>
  if(user_src){
    80002512:	c08d                	beqz	s1,80002534 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002514:	86d2                	mv	a3,s4
    80002516:	864e                	mv	a2,s3
    80002518:	85ca                	mv	a1,s2
    8000251a:	6928                	ld	a0,80(a0)
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	1d6080e7          	jalr	470(ra) # 800016f2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002524:	70a2                	ld	ra,40(sp)
    80002526:	7402                	ld	s0,32(sp)
    80002528:	64e2                	ld	s1,24(sp)
    8000252a:	6942                	ld	s2,16(sp)
    8000252c:	69a2                	ld	s3,8(sp)
    8000252e:	6a02                	ld	s4,0(sp)
    80002530:	6145                	add	sp,sp,48
    80002532:	8082                	ret
    memmove(dst, (char*)src, len);
    80002534:	000a061b          	sext.w	a2,s4
    80002538:	85ce                	mv	a1,s3
    8000253a:	854a                	mv	a0,s2
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	7ee080e7          	jalr	2030(ra) # 80000d2a <memmove>
    return 0;
    80002544:	8526                	mv	a0,s1
    80002546:	bff9                	j	80002524 <either_copyin+0x32>

0000000080002548 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002548:	715d                	add	sp,sp,-80
    8000254a:	e486                	sd	ra,72(sp)
    8000254c:	e0a2                	sd	s0,64(sp)
    8000254e:	fc26                	sd	s1,56(sp)
    80002550:	f84a                	sd	s2,48(sp)
    80002552:	f44e                	sd	s3,40(sp)
    80002554:	f052                	sd	s4,32(sp)
    80002556:	ec56                	sd	s5,24(sp)
    80002558:	e85a                	sd	s6,16(sp)
    8000255a:	e45e                	sd	s7,8(sp)
    8000255c:	0880                	add	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000255e:	00006517          	auipc	a0,0x6
    80002562:	b6a50513          	add	a0,a0,-1174 # 800080c8 <digits+0x88>
    80002566:	ffffe097          	auipc	ra,0xffffe
    8000256a:	020080e7          	jalr	32(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000256e:	0000f497          	auipc	s1,0xf
    80002572:	b5a48493          	add	s1,s1,-1190 # 800110c8 <proc+0x158>
    80002576:	00014917          	auipc	s2,0x14
    8000257a:	55290913          	add	s2,s2,1362 # 80016ac8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000257e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002580:	00006997          	auipc	s3,0x6
    80002584:	d0098993          	add	s3,s3,-768 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002588:	00006a97          	auipc	s5,0x6
    8000258c:	d00a8a93          	add	s5,s5,-768 # 80008288 <digits+0x248>
    printf("\n");
    80002590:	00006a17          	auipc	s4,0x6
    80002594:	b38a0a13          	add	s4,s4,-1224 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002598:	00006b97          	auipc	s7,0x6
    8000259c:	d30b8b93          	add	s7,s7,-720 # 800082c8 <states.0>
    800025a0:	a00d                	j	800025c2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025a2:	ed86a583          	lw	a1,-296(a3)
    800025a6:	8556                	mv	a0,s5
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	fde080e7          	jalr	-34(ra) # 80000586 <printf>
    printf("\n");
    800025b0:	8552                	mv	a0,s4
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	fd4080e7          	jalr	-44(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ba:	16848493          	add	s1,s1,360
    800025be:	03248263          	beq	s1,s2,800025e2 <procdump+0x9a>
    if(p->state == UNUSED)
    800025c2:	86a6                	mv	a3,s1
    800025c4:	ec04a783          	lw	a5,-320(s1)
    800025c8:	dbed                	beqz	a5,800025ba <procdump+0x72>
      state = "???";
    800025ca:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025cc:	fcfb6be3          	bltu	s6,a5,800025a2 <procdump+0x5a>
    800025d0:	02079713          	sll	a4,a5,0x20
    800025d4:	01d75793          	srl	a5,a4,0x1d
    800025d8:	97de                	add	a5,a5,s7
    800025da:	6390                	ld	a2,0(a5)
    800025dc:	f279                	bnez	a2,800025a2 <procdump+0x5a>
      state = "???";
    800025de:	864e                	mv	a2,s3
    800025e0:	b7c9                	j	800025a2 <procdump+0x5a>
  }
}
    800025e2:	60a6                	ld	ra,72(sp)
    800025e4:	6406                	ld	s0,64(sp)
    800025e6:	74e2                	ld	s1,56(sp)
    800025e8:	7942                	ld	s2,48(sp)
    800025ea:	79a2                	ld	s3,40(sp)
    800025ec:	7a02                	ld	s4,32(sp)
    800025ee:	6ae2                	ld	s5,24(sp)
    800025f0:	6b42                	ld	s6,16(sp)
    800025f2:	6ba2                	ld	s7,8(sp)
    800025f4:	6161                	add	sp,sp,80
    800025f6:	8082                	ret

00000000800025f8 <swtch>:
    800025f8:	00153023          	sd	ra,0(a0)
    800025fc:	00253423          	sd	sp,8(a0)
    80002600:	e900                	sd	s0,16(a0)
    80002602:	ed04                	sd	s1,24(a0)
    80002604:	03253023          	sd	s2,32(a0)
    80002608:	03353423          	sd	s3,40(a0)
    8000260c:	03453823          	sd	s4,48(a0)
    80002610:	03553c23          	sd	s5,56(a0)
    80002614:	05653023          	sd	s6,64(a0)
    80002618:	05753423          	sd	s7,72(a0)
    8000261c:	05853823          	sd	s8,80(a0)
    80002620:	05953c23          	sd	s9,88(a0)
    80002624:	07a53023          	sd	s10,96(a0)
    80002628:	07b53423          	sd	s11,104(a0)
    8000262c:	0005b083          	ld	ra,0(a1)
    80002630:	0085b103          	ld	sp,8(a1)
    80002634:	6980                	ld	s0,16(a1)
    80002636:	6d84                	ld	s1,24(a1)
    80002638:	0205b903          	ld	s2,32(a1)
    8000263c:	0285b983          	ld	s3,40(a1)
    80002640:	0305ba03          	ld	s4,48(a1)
    80002644:	0385ba83          	ld	s5,56(a1)
    80002648:	0405bb03          	ld	s6,64(a1)
    8000264c:	0485bb83          	ld	s7,72(a1)
    80002650:	0505bc03          	ld	s8,80(a1)
    80002654:	0585bc83          	ld	s9,88(a1)
    80002658:	0605bd03          	ld	s10,96(a1)
    8000265c:	0685bd83          	ld	s11,104(a1)
    80002660:	8082                	ret

0000000080002662 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002662:	1141                	add	sp,sp,-16
    80002664:	e406                	sd	ra,8(sp)
    80002666:	e022                	sd	s0,0(sp)
    80002668:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    8000266a:	00006597          	auipc	a1,0x6
    8000266e:	c8e58593          	add	a1,a1,-882 # 800082f8 <states.0+0x30>
    80002672:	00014517          	auipc	a0,0x14
    80002676:	2fe50513          	add	a0,a0,766 # 80016970 <tickslock>
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	4c8080e7          	jalr	1224(ra) # 80000b42 <initlock>
}
    80002682:	60a2                	ld	ra,8(sp)
    80002684:	6402                	ld	s0,0(sp)
    80002686:	0141                	add	sp,sp,16
    80002688:	8082                	ret

000000008000268a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000268a:	1141                	add	sp,sp,-16
    8000268c:	e422                	sd	s0,8(sp)
    8000268e:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002690:	00003797          	auipc	a5,0x3
    80002694:	49078793          	add	a5,a5,1168 # 80005b20 <kernelvec>
    80002698:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000269c:	6422                	ld	s0,8(sp)
    8000269e:	0141                	add	sp,sp,16
    800026a0:	8082                	ret

00000000800026a2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026a2:	1141                	add	sp,sp,-16
    800026a4:	e406                	sd	ra,8(sp)
    800026a6:	e022                	sd	s0,0(sp)
    800026a8:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    800026aa:	fffff097          	auipc	ra,0xfffff
    800026ae:	2fc080e7          	jalr	764(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026b2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026b6:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026b8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800026bc:	00005697          	auipc	a3,0x5
    800026c0:	94468693          	add	a3,a3,-1724 # 80007000 <_trampoline>
    800026c4:	00005717          	auipc	a4,0x5
    800026c8:	93c70713          	add	a4,a4,-1732 # 80007000 <_trampoline>
    800026cc:	8f15                	sub	a4,a4,a3
    800026ce:	040007b7          	lui	a5,0x4000
    800026d2:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800026d4:	07b2                	sll	a5,a5,0xc
    800026d6:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026d8:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026dc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026de:	18002673          	csrr	a2,satp
    800026e2:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026e4:	6d30                	ld	a2,88(a0)
    800026e6:	6138                	ld	a4,64(a0)
    800026e8:	6585                	lui	a1,0x1
    800026ea:	972e                	add	a4,a4,a1
    800026ec:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026ee:	6d38                	ld	a4,88(a0)
    800026f0:	00000617          	auipc	a2,0x0
    800026f4:	13460613          	add	a2,a2,308 # 80002824 <usertrap>
    800026f8:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026fa:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026fc:	8612                	mv	a2,tp
    800026fe:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002700:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002704:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002708:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000270c:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002710:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002712:	6f18                	ld	a4,24(a4)
    80002714:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002718:	6928                	ld	a0,80(a0)
    8000271a:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000271c:	00005717          	auipc	a4,0x5
    80002720:	98070713          	add	a4,a4,-1664 # 8000709c <userret>
    80002724:	8f15                	sub	a4,a4,a3
    80002726:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002728:	577d                	li	a4,-1
    8000272a:	177e                	sll	a4,a4,0x3f
    8000272c:	8d59                	or	a0,a0,a4
    8000272e:	9782                	jalr	a5
}
    80002730:	60a2                	ld	ra,8(sp)
    80002732:	6402                	ld	s0,0(sp)
    80002734:	0141                	add	sp,sp,16
    80002736:	8082                	ret

0000000080002738 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002738:	1101                	add	sp,sp,-32
    8000273a:	ec06                	sd	ra,24(sp)
    8000273c:	e822                	sd	s0,16(sp)
    8000273e:	e426                	sd	s1,8(sp)
    80002740:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002742:	00014497          	auipc	s1,0x14
    80002746:	22e48493          	add	s1,s1,558 # 80016970 <tickslock>
    8000274a:	8526                	mv	a0,s1
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	486080e7          	jalr	1158(ra) # 80000bd2 <acquire>
  ticks++;
    80002754:	00006517          	auipc	a0,0x6
    80002758:	17c50513          	add	a0,a0,380 # 800088d0 <ticks>
    8000275c:	411c                	lw	a5,0(a0)
    8000275e:	2785                	addw	a5,a5,1
    80002760:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002762:	00000097          	auipc	ra,0x0
    80002766:	950080e7          	jalr	-1712(ra) # 800020b2 <wakeup>
  release(&tickslock);
    8000276a:	8526                	mv	a0,s1
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	51a080e7          	jalr	1306(ra) # 80000c86 <release>
}
    80002774:	60e2                	ld	ra,24(sp)
    80002776:	6442                	ld	s0,16(sp)
    80002778:	64a2                	ld	s1,8(sp)
    8000277a:	6105                	add	sp,sp,32
    8000277c:	8082                	ret

000000008000277e <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000277e:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002782:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002784:	0807df63          	bgez	a5,80002822 <devintr+0xa4>
{
    80002788:	1101                	add	sp,sp,-32
    8000278a:	ec06                	sd	ra,24(sp)
    8000278c:	e822                	sd	s0,16(sp)
    8000278e:	e426                	sd	s1,8(sp)
    80002790:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    80002792:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002796:	46a5                	li	a3,9
    80002798:	00d70d63          	beq	a4,a3,800027b2 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    8000279c:	577d                	li	a4,-1
    8000279e:	177e                	sll	a4,a4,0x3f
    800027a0:	0705                	add	a4,a4,1
    return 0;
    800027a2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027a4:	04e78e63          	beq	a5,a4,80002800 <devintr+0x82>
  }
}
    800027a8:	60e2                	ld	ra,24(sp)
    800027aa:	6442                	ld	s0,16(sp)
    800027ac:	64a2                	ld	s1,8(sp)
    800027ae:	6105                	add	sp,sp,32
    800027b0:	8082                	ret
    int irq = plic_claim();
    800027b2:	00003097          	auipc	ra,0x3
    800027b6:	476080e7          	jalr	1142(ra) # 80005c28 <plic_claim>
    800027ba:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027bc:	47a9                	li	a5,10
    800027be:	02f50763          	beq	a0,a5,800027ec <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    800027c2:	4785                	li	a5,1
    800027c4:	02f50963          	beq	a0,a5,800027f6 <devintr+0x78>
    return 1;
    800027c8:	4505                	li	a0,1
    } else if(irq){
    800027ca:	dcf9                	beqz	s1,800027a8 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    800027cc:	85a6                	mv	a1,s1
    800027ce:	00006517          	auipc	a0,0x6
    800027d2:	b3250513          	add	a0,a0,-1230 # 80008300 <states.0+0x38>
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	db0080e7          	jalr	-592(ra) # 80000586 <printf>
      plic_complete(irq);
    800027de:	8526                	mv	a0,s1
    800027e0:	00003097          	auipc	ra,0x3
    800027e4:	46c080e7          	jalr	1132(ra) # 80005c4c <plic_complete>
    return 1;
    800027e8:	4505                	li	a0,1
    800027ea:	bf7d                	j	800027a8 <devintr+0x2a>
      uartintr();
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	1a8080e7          	jalr	424(ra) # 80000994 <uartintr>
    if(irq)
    800027f4:	b7ed                	j	800027de <devintr+0x60>
      virtio_disk_intr();
    800027f6:	00004097          	auipc	ra,0x4
    800027fa:	91c080e7          	jalr	-1764(ra) # 80006112 <virtio_disk_intr>
    if(irq)
    800027fe:	b7c5                	j	800027de <devintr+0x60>
    if(cpuid() == 0){
    80002800:	fffff097          	auipc	ra,0xfffff
    80002804:	17a080e7          	jalr	378(ra) # 8000197a <cpuid>
    80002808:	c901                	beqz	a0,80002818 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000280a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000280e:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002810:	14479073          	csrw	sip,a5
    return 2;
    80002814:	4509                	li	a0,2
    80002816:	bf49                	j	800027a8 <devintr+0x2a>
      clockintr();
    80002818:	00000097          	auipc	ra,0x0
    8000281c:	f20080e7          	jalr	-224(ra) # 80002738 <clockintr>
    80002820:	b7ed                	j	8000280a <devintr+0x8c>
}
    80002822:	8082                	ret

0000000080002824 <usertrap>:
{
    80002824:	1101                	add	sp,sp,-32
    80002826:	ec06                	sd	ra,24(sp)
    80002828:	e822                	sd	s0,16(sp)
    8000282a:	e426                	sd	s1,8(sp)
    8000282c:	e04a                	sd	s2,0(sp)
    8000282e:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002830:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002834:	1007f793          	and	a5,a5,256
    80002838:	e3b1                	bnez	a5,8000287c <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000283a:	00003797          	auipc	a5,0x3
    8000283e:	2e678793          	add	a5,a5,742 # 80005b20 <kernelvec>
    80002842:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002846:	fffff097          	auipc	ra,0xfffff
    8000284a:	160080e7          	jalr	352(ra) # 800019a6 <myproc>
    8000284e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002850:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002852:	14102773          	csrr	a4,sepc
    80002856:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002858:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000285c:	47a1                	li	a5,8
    8000285e:	02f70763          	beq	a4,a5,8000288c <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002862:	00000097          	auipc	ra,0x0
    80002866:	f1c080e7          	jalr	-228(ra) # 8000277e <devintr>
    8000286a:	892a                	mv	s2,a0
    8000286c:	c151                	beqz	a0,800028f0 <usertrap+0xcc>
  if(killed(p))
    8000286e:	8526                	mv	a0,s1
    80002870:	00000097          	auipc	ra,0x0
    80002874:	a86080e7          	jalr	-1402(ra) # 800022f6 <killed>
    80002878:	c929                	beqz	a0,800028ca <usertrap+0xa6>
    8000287a:	a099                	j	800028c0 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    8000287c:	00006517          	auipc	a0,0x6
    80002880:	aa450513          	add	a0,a0,-1372 # 80008320 <states.0+0x58>
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	cb8080e7          	jalr	-840(ra) # 8000053c <panic>
    if(killed(p))
    8000288c:	00000097          	auipc	ra,0x0
    80002890:	a6a080e7          	jalr	-1430(ra) # 800022f6 <killed>
    80002894:	e921                	bnez	a0,800028e4 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002896:	6cb8                	ld	a4,88(s1)
    80002898:	6f1c                	ld	a5,24(a4)
    8000289a:	0791                	add	a5,a5,4
    8000289c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028a2:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a6:	10079073          	csrw	sstatus,a5
    syscall();
    800028aa:	00000097          	auipc	ra,0x0
    800028ae:	2d4080e7          	jalr	724(ra) # 80002b7e <syscall>
  if(killed(p))
    800028b2:	8526                	mv	a0,s1
    800028b4:	00000097          	auipc	ra,0x0
    800028b8:	a42080e7          	jalr	-1470(ra) # 800022f6 <killed>
    800028bc:	c911                	beqz	a0,800028d0 <usertrap+0xac>
    800028be:	4901                	li	s2,0
    exit(-1);
    800028c0:	557d                	li	a0,-1
    800028c2:	00000097          	auipc	ra,0x0
    800028c6:	8c0080e7          	jalr	-1856(ra) # 80002182 <exit>
  if(which_dev == 2)
    800028ca:	4789                	li	a5,2
    800028cc:	04f90f63          	beq	s2,a5,8000292a <usertrap+0x106>
  usertrapret();
    800028d0:	00000097          	auipc	ra,0x0
    800028d4:	dd2080e7          	jalr	-558(ra) # 800026a2 <usertrapret>
}
    800028d8:	60e2                	ld	ra,24(sp)
    800028da:	6442                	ld	s0,16(sp)
    800028dc:	64a2                	ld	s1,8(sp)
    800028de:	6902                	ld	s2,0(sp)
    800028e0:	6105                	add	sp,sp,32
    800028e2:	8082                	ret
      exit(-1);
    800028e4:	557d                	li	a0,-1
    800028e6:	00000097          	auipc	ra,0x0
    800028ea:	89c080e7          	jalr	-1892(ra) # 80002182 <exit>
    800028ee:	b765                	j	80002896 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028f4:	5890                	lw	a2,48(s1)
    800028f6:	00006517          	auipc	a0,0x6
    800028fa:	a4a50513          	add	a0,a0,-1462 # 80008340 <states.0+0x78>
    800028fe:	ffffe097          	auipc	ra,0xffffe
    80002902:	c88080e7          	jalr	-888(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002906:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000290a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000290e:	00006517          	auipc	a0,0x6
    80002912:	a6250513          	add	a0,a0,-1438 # 80008370 <states.0+0xa8>
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	c70080e7          	jalr	-912(ra) # 80000586 <printf>
    setkilled(p);
    8000291e:	8526                	mv	a0,s1
    80002920:	00000097          	auipc	ra,0x0
    80002924:	9aa080e7          	jalr	-1622(ra) # 800022ca <setkilled>
    80002928:	b769                	j	800028b2 <usertrap+0x8e>
    yield();
    8000292a:	fffff097          	auipc	ra,0xfffff
    8000292e:	6e8080e7          	jalr	1768(ra) # 80002012 <yield>
    80002932:	bf79                	j	800028d0 <usertrap+0xac>

0000000080002934 <kerneltrap>:
{
    80002934:	7179                	add	sp,sp,-48
    80002936:	f406                	sd	ra,40(sp)
    80002938:	f022                	sd	s0,32(sp)
    8000293a:	ec26                	sd	s1,24(sp)
    8000293c:	e84a                	sd	s2,16(sp)
    8000293e:	e44e                	sd	s3,8(sp)
    80002940:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002942:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002946:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000294a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000294e:	1004f793          	and	a5,s1,256
    80002952:	cb85                	beqz	a5,80002982 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002954:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002958:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    8000295a:	ef85                	bnez	a5,80002992 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000295c:	00000097          	auipc	ra,0x0
    80002960:	e22080e7          	jalr	-478(ra) # 8000277e <devintr>
    80002964:	cd1d                	beqz	a0,800029a2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002966:	4789                	li	a5,2
    80002968:	06f50a63          	beq	a0,a5,800029dc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000296c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002970:	10049073          	csrw	sstatus,s1
}
    80002974:	70a2                	ld	ra,40(sp)
    80002976:	7402                	ld	s0,32(sp)
    80002978:	64e2                	ld	s1,24(sp)
    8000297a:	6942                	ld	s2,16(sp)
    8000297c:	69a2                	ld	s3,8(sp)
    8000297e:	6145                	add	sp,sp,48
    80002980:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002982:	00006517          	auipc	a0,0x6
    80002986:	a0e50513          	add	a0,a0,-1522 # 80008390 <states.0+0xc8>
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	bb2080e7          	jalr	-1102(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002992:	00006517          	auipc	a0,0x6
    80002996:	a2650513          	add	a0,a0,-1498 # 800083b8 <states.0+0xf0>
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	ba2080e7          	jalr	-1118(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    800029a2:	85ce                	mv	a1,s3
    800029a4:	00006517          	auipc	a0,0x6
    800029a8:	a3450513          	add	a0,a0,-1484 # 800083d8 <states.0+0x110>
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	bda080e7          	jalr	-1062(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029b4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029b8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029bc:	00006517          	auipc	a0,0x6
    800029c0:	a2c50513          	add	a0,a0,-1492 # 800083e8 <states.0+0x120>
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	bc2080e7          	jalr	-1086(ra) # 80000586 <printf>
    panic("kerneltrap");
    800029cc:	00006517          	auipc	a0,0x6
    800029d0:	a3450513          	add	a0,a0,-1484 # 80008400 <states.0+0x138>
    800029d4:	ffffe097          	auipc	ra,0xffffe
    800029d8:	b68080e7          	jalr	-1176(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029dc:	fffff097          	auipc	ra,0xfffff
    800029e0:	fca080e7          	jalr	-54(ra) # 800019a6 <myproc>
    800029e4:	d541                	beqz	a0,8000296c <kerneltrap+0x38>
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	fc0080e7          	jalr	-64(ra) # 800019a6 <myproc>
    800029ee:	4d18                	lw	a4,24(a0)
    800029f0:	4791                	li	a5,4
    800029f2:	f6f71de3          	bne	a4,a5,8000296c <kerneltrap+0x38>
    yield();
    800029f6:	fffff097          	auipc	ra,0xfffff
    800029fa:	61c080e7          	jalr	1564(ra) # 80002012 <yield>
    800029fe:	b7bd                	j	8000296c <kerneltrap+0x38>

0000000080002a00 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a00:	1101                	add	sp,sp,-32
    80002a02:	ec06                	sd	ra,24(sp)
    80002a04:	e822                	sd	s0,16(sp)
    80002a06:	e426                	sd	s1,8(sp)
    80002a08:	1000                	add	s0,sp,32
    80002a0a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a0c:	fffff097          	auipc	ra,0xfffff
    80002a10:	f9a080e7          	jalr	-102(ra) # 800019a6 <myproc>
  switch (n) {
    80002a14:	4795                	li	a5,5
    80002a16:	0497e163          	bltu	a5,s1,80002a58 <argraw+0x58>
    80002a1a:	048a                	sll	s1,s1,0x2
    80002a1c:	00006717          	auipc	a4,0x6
    80002a20:	a1c70713          	add	a4,a4,-1508 # 80008438 <states.0+0x170>
    80002a24:	94ba                	add	s1,s1,a4
    80002a26:	409c                	lw	a5,0(s1)
    80002a28:	97ba                	add	a5,a5,a4
    80002a2a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a2c:	6d3c                	ld	a5,88(a0)
    80002a2e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a30:	60e2                	ld	ra,24(sp)
    80002a32:	6442                	ld	s0,16(sp)
    80002a34:	64a2                	ld	s1,8(sp)
    80002a36:	6105                	add	sp,sp,32
    80002a38:	8082                	ret
    return p->trapframe->a1;
    80002a3a:	6d3c                	ld	a5,88(a0)
    80002a3c:	7fa8                	ld	a0,120(a5)
    80002a3e:	bfcd                	j	80002a30 <argraw+0x30>
    return p->trapframe->a2;
    80002a40:	6d3c                	ld	a5,88(a0)
    80002a42:	63c8                	ld	a0,128(a5)
    80002a44:	b7f5                	j	80002a30 <argraw+0x30>
    return p->trapframe->a3;
    80002a46:	6d3c                	ld	a5,88(a0)
    80002a48:	67c8                	ld	a0,136(a5)
    80002a4a:	b7dd                	j	80002a30 <argraw+0x30>
    return p->trapframe->a4;
    80002a4c:	6d3c                	ld	a5,88(a0)
    80002a4e:	6bc8                	ld	a0,144(a5)
    80002a50:	b7c5                	j	80002a30 <argraw+0x30>
    return p->trapframe->a5;
    80002a52:	6d3c                	ld	a5,88(a0)
    80002a54:	6fc8                	ld	a0,152(a5)
    80002a56:	bfe9                	j	80002a30 <argraw+0x30>
  panic("argraw");
    80002a58:	00006517          	auipc	a0,0x6
    80002a5c:	9b850513          	add	a0,a0,-1608 # 80008410 <states.0+0x148>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	adc080e7          	jalr	-1316(ra) # 8000053c <panic>

0000000080002a68 <fetchaddr>:
{
    80002a68:	1101                	add	sp,sp,-32
    80002a6a:	ec06                	sd	ra,24(sp)
    80002a6c:	e822                	sd	s0,16(sp)
    80002a6e:	e426                	sd	s1,8(sp)
    80002a70:	e04a                	sd	s2,0(sp)
    80002a72:	1000                	add	s0,sp,32
    80002a74:	84aa                	mv	s1,a0
    80002a76:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	f2e080e7          	jalr	-210(ra) # 800019a6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a80:	653c                	ld	a5,72(a0)
    80002a82:	02f4f863          	bgeu	s1,a5,80002ab2 <fetchaddr+0x4a>
    80002a86:	00848713          	add	a4,s1,8
    80002a8a:	02e7e663          	bltu	a5,a4,80002ab6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a8e:	46a1                	li	a3,8
    80002a90:	8626                	mv	a2,s1
    80002a92:	85ca                	mv	a1,s2
    80002a94:	6928                	ld	a0,80(a0)
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	c5c080e7          	jalr	-932(ra) # 800016f2 <copyin>
    80002a9e:	00a03533          	snez	a0,a0
    80002aa2:	40a00533          	neg	a0,a0
}
    80002aa6:	60e2                	ld	ra,24(sp)
    80002aa8:	6442                	ld	s0,16(sp)
    80002aaa:	64a2                	ld	s1,8(sp)
    80002aac:	6902                	ld	s2,0(sp)
    80002aae:	6105                	add	sp,sp,32
    80002ab0:	8082                	ret
    return -1;
    80002ab2:	557d                	li	a0,-1
    80002ab4:	bfcd                	j	80002aa6 <fetchaddr+0x3e>
    80002ab6:	557d                	li	a0,-1
    80002ab8:	b7fd                	j	80002aa6 <fetchaddr+0x3e>

0000000080002aba <fetchstr>:
{
    80002aba:	7179                	add	sp,sp,-48
    80002abc:	f406                	sd	ra,40(sp)
    80002abe:	f022                	sd	s0,32(sp)
    80002ac0:	ec26                	sd	s1,24(sp)
    80002ac2:	e84a                	sd	s2,16(sp)
    80002ac4:	e44e                	sd	s3,8(sp)
    80002ac6:	1800                	add	s0,sp,48
    80002ac8:	892a                	mv	s2,a0
    80002aca:	84ae                	mv	s1,a1
    80002acc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	ed8080e7          	jalr	-296(ra) # 800019a6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ad6:	86ce                	mv	a3,s3
    80002ad8:	864a                	mv	a2,s2
    80002ada:	85a6                	mv	a1,s1
    80002adc:	6928                	ld	a0,80(a0)
    80002ade:	fffff097          	auipc	ra,0xfffff
    80002ae2:	ca2080e7          	jalr	-862(ra) # 80001780 <copyinstr>
    80002ae6:	00054e63          	bltz	a0,80002b02 <fetchstr+0x48>
  return strlen(buf);
    80002aea:	8526                	mv	a0,s1
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	35c080e7          	jalr	860(ra) # 80000e48 <strlen>
}
    80002af4:	70a2                	ld	ra,40(sp)
    80002af6:	7402                	ld	s0,32(sp)
    80002af8:	64e2                	ld	s1,24(sp)
    80002afa:	6942                	ld	s2,16(sp)
    80002afc:	69a2                	ld	s3,8(sp)
    80002afe:	6145                	add	sp,sp,48
    80002b00:	8082                	ret
    return -1;
    80002b02:	557d                	li	a0,-1
    80002b04:	bfc5                	j	80002af4 <fetchstr+0x3a>

0000000080002b06 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b06:	1101                	add	sp,sp,-32
    80002b08:	ec06                	sd	ra,24(sp)
    80002b0a:	e822                	sd	s0,16(sp)
    80002b0c:	e426                	sd	s1,8(sp)
    80002b0e:	1000                	add	s0,sp,32
    80002b10:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b12:	00000097          	auipc	ra,0x0
    80002b16:	eee080e7          	jalr	-274(ra) # 80002a00 <argraw>
    80002b1a:	c088                	sw	a0,0(s1)
}
    80002b1c:	60e2                	ld	ra,24(sp)
    80002b1e:	6442                	ld	s0,16(sp)
    80002b20:	64a2                	ld	s1,8(sp)
    80002b22:	6105                	add	sp,sp,32
    80002b24:	8082                	ret

0000000080002b26 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b26:	1101                	add	sp,sp,-32
    80002b28:	ec06                	sd	ra,24(sp)
    80002b2a:	e822                	sd	s0,16(sp)
    80002b2c:	e426                	sd	s1,8(sp)
    80002b2e:	1000                	add	s0,sp,32
    80002b30:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b32:	00000097          	auipc	ra,0x0
    80002b36:	ece080e7          	jalr	-306(ra) # 80002a00 <argraw>
    80002b3a:	e088                	sd	a0,0(s1)
}
    80002b3c:	60e2                	ld	ra,24(sp)
    80002b3e:	6442                	ld	s0,16(sp)
    80002b40:	64a2                	ld	s1,8(sp)
    80002b42:	6105                	add	sp,sp,32
    80002b44:	8082                	ret

0000000080002b46 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b46:	7179                	add	sp,sp,-48
    80002b48:	f406                	sd	ra,40(sp)
    80002b4a:	f022                	sd	s0,32(sp)
    80002b4c:	ec26                	sd	s1,24(sp)
    80002b4e:	e84a                	sd	s2,16(sp)
    80002b50:	1800                	add	s0,sp,48
    80002b52:	84ae                	mv	s1,a1
    80002b54:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b56:	fd840593          	add	a1,s0,-40
    80002b5a:	00000097          	auipc	ra,0x0
    80002b5e:	fcc080e7          	jalr	-52(ra) # 80002b26 <argaddr>
  return fetchstr(addr, buf, max);
    80002b62:	864a                	mv	a2,s2
    80002b64:	85a6                	mv	a1,s1
    80002b66:	fd843503          	ld	a0,-40(s0)
    80002b6a:	00000097          	auipc	ra,0x0
    80002b6e:	f50080e7          	jalr	-176(ra) # 80002aba <fetchstr>
}
    80002b72:	70a2                	ld	ra,40(sp)
    80002b74:	7402                	ld	s0,32(sp)
    80002b76:	64e2                	ld	s1,24(sp)
    80002b78:	6942                	ld	s2,16(sp)
    80002b7a:	6145                	add	sp,sp,48
    80002b7c:	8082                	ret

0000000080002b7e <syscall>:
[SYS_getfilenum]  sys_getfilenum,
};

void
syscall(void)
{
    80002b7e:	1101                	add	sp,sp,-32
    80002b80:	ec06                	sd	ra,24(sp)
    80002b82:	e822                	sd	s0,16(sp)
    80002b84:	e426                	sd	s1,8(sp)
    80002b86:	e04a                	sd	s2,0(sp)
    80002b88:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b8a:	fffff097          	auipc	ra,0xfffff
    80002b8e:	e1c080e7          	jalr	-484(ra) # 800019a6 <myproc>
    80002b92:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b94:	05853903          	ld	s2,88(a0)
    80002b98:	0a893783          	ld	a5,168(s2)
    80002b9c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ba0:	37fd                	addw	a5,a5,-1
    80002ba2:	4755                	li	a4,21
    80002ba4:	00f76f63          	bltu	a4,a5,80002bc2 <syscall+0x44>
    80002ba8:	00369713          	sll	a4,a3,0x3
    80002bac:	00006797          	auipc	a5,0x6
    80002bb0:	8a478793          	add	a5,a5,-1884 # 80008450 <syscalls>
    80002bb4:	97ba                	add	a5,a5,a4
    80002bb6:	639c                	ld	a5,0(a5)
    80002bb8:	c789                	beqz	a5,80002bc2 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002bba:	9782                	jalr	a5
    80002bbc:	06a93823          	sd	a0,112(s2)
    80002bc0:	a839                	j	80002bde <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bc2:	15848613          	add	a2,s1,344
    80002bc6:	588c                	lw	a1,48(s1)
    80002bc8:	00006517          	auipc	a0,0x6
    80002bcc:	85050513          	add	a0,a0,-1968 # 80008418 <states.0+0x150>
    80002bd0:	ffffe097          	auipc	ra,0xffffe
    80002bd4:	9b6080e7          	jalr	-1610(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bd8:	6cbc                	ld	a5,88(s1)
    80002bda:	577d                	li	a4,-1
    80002bdc:	fbb8                	sd	a4,112(a5)
  }
}
    80002bde:	60e2                	ld	ra,24(sp)
    80002be0:	6442                	ld	s0,16(sp)
    80002be2:	64a2                	ld	s1,8(sp)
    80002be4:	6902                	ld	s2,0(sp)
    80002be6:	6105                	add	sp,sp,32
    80002be8:	8082                	ret

0000000080002bea <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bea:	1101                	add	sp,sp,-32
    80002bec:	ec06                	sd	ra,24(sp)
    80002bee:	e822                	sd	s0,16(sp)
    80002bf0:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80002bf2:	fec40593          	add	a1,s0,-20
    80002bf6:	4501                	li	a0,0
    80002bf8:	00000097          	auipc	ra,0x0
    80002bfc:	f0e080e7          	jalr	-242(ra) # 80002b06 <argint>
  exit(n);
    80002c00:	fec42503          	lw	a0,-20(s0)
    80002c04:	fffff097          	auipc	ra,0xfffff
    80002c08:	57e080e7          	jalr	1406(ra) # 80002182 <exit>
  return 0;  // not reached
}
    80002c0c:	4501                	li	a0,0
    80002c0e:	60e2                	ld	ra,24(sp)
    80002c10:	6442                	ld	s0,16(sp)
    80002c12:	6105                	add	sp,sp,32
    80002c14:	8082                	ret

0000000080002c16 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c16:	1141                	add	sp,sp,-16
    80002c18:	e406                	sd	ra,8(sp)
    80002c1a:	e022                	sd	s0,0(sp)
    80002c1c:	0800                	add	s0,sp,16
  return myproc()->pid;
    80002c1e:	fffff097          	auipc	ra,0xfffff
    80002c22:	d88080e7          	jalr	-632(ra) # 800019a6 <myproc>
}
    80002c26:	5908                	lw	a0,48(a0)
    80002c28:	60a2                	ld	ra,8(sp)
    80002c2a:	6402                	ld	s0,0(sp)
    80002c2c:	0141                	add	sp,sp,16
    80002c2e:	8082                	ret

0000000080002c30 <sys_fork>:

uint64
sys_fork(void)
{
    80002c30:	1141                	add	sp,sp,-16
    80002c32:	e406                	sd	ra,8(sp)
    80002c34:	e022                	sd	s0,0(sp)
    80002c36:	0800                	add	s0,sp,16
  return fork();
    80002c38:	fffff097          	auipc	ra,0xfffff
    80002c3c:	124080e7          	jalr	292(ra) # 80001d5c <fork>
}
    80002c40:	60a2                	ld	ra,8(sp)
    80002c42:	6402                	ld	s0,0(sp)
    80002c44:	0141                	add	sp,sp,16
    80002c46:	8082                	ret

0000000080002c48 <sys_wait>:

uint64
sys_wait(void)
{
    80002c48:	1101                	add	sp,sp,-32
    80002c4a:	ec06                	sd	ra,24(sp)
    80002c4c:	e822                	sd	s0,16(sp)
    80002c4e:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c50:	fe840593          	add	a1,s0,-24
    80002c54:	4501                	li	a0,0
    80002c56:	00000097          	auipc	ra,0x0
    80002c5a:	ed0080e7          	jalr	-304(ra) # 80002b26 <argaddr>
  return wait(p);
    80002c5e:	fe843503          	ld	a0,-24(s0)
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	6c6080e7          	jalr	1734(ra) # 80002328 <wait>
}
    80002c6a:	60e2                	ld	ra,24(sp)
    80002c6c:	6442                	ld	s0,16(sp)
    80002c6e:	6105                	add	sp,sp,32
    80002c70:	8082                	ret

0000000080002c72 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c72:	7179                	add	sp,sp,-48
    80002c74:	f406                	sd	ra,40(sp)
    80002c76:	f022                	sd	s0,32(sp)
    80002c78:	ec26                	sd	s1,24(sp)
    80002c7a:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002c7c:	fdc40593          	add	a1,s0,-36
    80002c80:	4501                	li	a0,0
    80002c82:	00000097          	auipc	ra,0x0
    80002c86:	e84080e7          	jalr	-380(ra) # 80002b06 <argint>
  addr = myproc()->sz;
    80002c8a:	fffff097          	auipc	ra,0xfffff
    80002c8e:	d1c080e7          	jalr	-740(ra) # 800019a6 <myproc>
    80002c92:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002c94:	fdc42503          	lw	a0,-36(s0)
    80002c98:	fffff097          	auipc	ra,0xfffff
    80002c9c:	068080e7          	jalr	104(ra) # 80001d00 <growproc>
    80002ca0:	00054863          	bltz	a0,80002cb0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002ca4:	8526                	mv	a0,s1
    80002ca6:	70a2                	ld	ra,40(sp)
    80002ca8:	7402                	ld	s0,32(sp)
    80002caa:	64e2                	ld	s1,24(sp)
    80002cac:	6145                	add	sp,sp,48
    80002cae:	8082                	ret
    return -1;
    80002cb0:	54fd                	li	s1,-1
    80002cb2:	bfcd                	j	80002ca4 <sys_sbrk+0x32>

0000000080002cb4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cb4:	7139                	add	sp,sp,-64
    80002cb6:	fc06                	sd	ra,56(sp)
    80002cb8:	f822                	sd	s0,48(sp)
    80002cba:	f426                	sd	s1,40(sp)
    80002cbc:	f04a                	sd	s2,32(sp)
    80002cbe:	ec4e                	sd	s3,24(sp)
    80002cc0:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002cc2:	fcc40593          	add	a1,s0,-52
    80002cc6:	4501                	li	a0,0
    80002cc8:	00000097          	auipc	ra,0x0
    80002ccc:	e3e080e7          	jalr	-450(ra) # 80002b06 <argint>
  acquire(&tickslock);
    80002cd0:	00014517          	auipc	a0,0x14
    80002cd4:	ca050513          	add	a0,a0,-864 # 80016970 <tickslock>
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	efa080e7          	jalr	-262(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80002ce0:	00006917          	auipc	s2,0x6
    80002ce4:	bf092903          	lw	s2,-1040(s2) # 800088d0 <ticks>
  while(ticks - ticks0 < n){
    80002ce8:	fcc42783          	lw	a5,-52(s0)
    80002cec:	cf9d                	beqz	a5,80002d2a <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002cee:	00014997          	auipc	s3,0x14
    80002cf2:	c8298993          	add	s3,s3,-894 # 80016970 <tickslock>
    80002cf6:	00006497          	auipc	s1,0x6
    80002cfa:	bda48493          	add	s1,s1,-1062 # 800088d0 <ticks>
    if(killed(myproc())){
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	ca8080e7          	jalr	-856(ra) # 800019a6 <myproc>
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	5f0080e7          	jalr	1520(ra) # 800022f6 <killed>
    80002d0e:	ed15                	bnez	a0,80002d4a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d10:	85ce                	mv	a1,s3
    80002d12:	8526                	mv	a0,s1
    80002d14:	fffff097          	auipc	ra,0xfffff
    80002d18:	33a080e7          	jalr	826(ra) # 8000204e <sleep>
  while(ticks - ticks0 < n){
    80002d1c:	409c                	lw	a5,0(s1)
    80002d1e:	412787bb          	subw	a5,a5,s2
    80002d22:	fcc42703          	lw	a4,-52(s0)
    80002d26:	fce7ece3          	bltu	a5,a4,80002cfe <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d2a:	00014517          	auipc	a0,0x14
    80002d2e:	c4650513          	add	a0,a0,-954 # 80016970 <tickslock>
    80002d32:	ffffe097          	auipc	ra,0xffffe
    80002d36:	f54080e7          	jalr	-172(ra) # 80000c86 <release>
  return 0;
    80002d3a:	4501                	li	a0,0
}
    80002d3c:	70e2                	ld	ra,56(sp)
    80002d3e:	7442                	ld	s0,48(sp)
    80002d40:	74a2                	ld	s1,40(sp)
    80002d42:	7902                	ld	s2,32(sp)
    80002d44:	69e2                	ld	s3,24(sp)
    80002d46:	6121                	add	sp,sp,64
    80002d48:	8082                	ret
      release(&tickslock);
    80002d4a:	00014517          	auipc	a0,0x14
    80002d4e:	c2650513          	add	a0,a0,-986 # 80016970 <tickslock>
    80002d52:	ffffe097          	auipc	ra,0xffffe
    80002d56:	f34080e7          	jalr	-204(ra) # 80000c86 <release>
      return -1;
    80002d5a:	557d                	li	a0,-1
    80002d5c:	b7c5                	j	80002d3c <sys_sleep+0x88>

0000000080002d5e <sys_kill>:

uint64
sys_kill(void)
{
    80002d5e:	1101                	add	sp,sp,-32
    80002d60:	ec06                	sd	ra,24(sp)
    80002d62:	e822                	sd	s0,16(sp)
    80002d64:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d66:	fec40593          	add	a1,s0,-20
    80002d6a:	4501                	li	a0,0
    80002d6c:	00000097          	auipc	ra,0x0
    80002d70:	d9a080e7          	jalr	-614(ra) # 80002b06 <argint>
  return kill(pid);
    80002d74:	fec42503          	lw	a0,-20(s0)
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	4e0080e7          	jalr	1248(ra) # 80002258 <kill>
}
    80002d80:	60e2                	ld	ra,24(sp)
    80002d82:	6442                	ld	s0,16(sp)
    80002d84:	6105                	add	sp,sp,32
    80002d86:	8082                	ret

0000000080002d88 <sys_getfilenum>:

uint64
sys_getfilenum(void)
{
    80002d88:	1101                	add	sp,sp,-32
    80002d8a:	ec06                	sd	ra,24(sp)
    80002d8c:	e822                	sd	s0,16(sp)
    80002d8e:	1000                	add	s0,sp,32
  int pid;
  argint(0, &pid);
    80002d90:	fec40593          	add	a1,s0,-20
    80002d94:	4501                	li	a0,0
    80002d96:	00000097          	auipc	ra,0x0
    80002d9a:	d70080e7          	jalr	-656(ra) # 80002b06 <argint>
  return getfilenum(pid);
    80002d9e:	fec42503          	lw	a0,-20(s0)
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	6b4080e7          	jalr	1716(ra) # 80002456 <getfilenum>
}
    80002daa:	60e2                	ld	ra,24(sp)
    80002dac:	6442                	ld	s0,16(sp)
    80002dae:	6105                	add	sp,sp,32
    80002db0:	8082                	ret

0000000080002db2 <sys_uptime>:
// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002db2:	1101                	add	sp,sp,-32
    80002db4:	ec06                	sd	ra,24(sp)
    80002db6:	e822                	sd	s0,16(sp)
    80002db8:	e426                	sd	s1,8(sp)
    80002dba:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dbc:	00014517          	auipc	a0,0x14
    80002dc0:	bb450513          	add	a0,a0,-1100 # 80016970 <tickslock>
    80002dc4:	ffffe097          	auipc	ra,0xffffe
    80002dc8:	e0e080e7          	jalr	-498(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80002dcc:	00006497          	auipc	s1,0x6
    80002dd0:	b044a483          	lw	s1,-1276(s1) # 800088d0 <ticks>
  release(&tickslock);
    80002dd4:	00014517          	auipc	a0,0x14
    80002dd8:	b9c50513          	add	a0,a0,-1124 # 80016970 <tickslock>
    80002ddc:	ffffe097          	auipc	ra,0xffffe
    80002de0:	eaa080e7          	jalr	-342(ra) # 80000c86 <release>
  return xticks;
}
    80002de4:	02049513          	sll	a0,s1,0x20
    80002de8:	9101                	srl	a0,a0,0x20
    80002dea:	60e2                	ld	ra,24(sp)
    80002dec:	6442                	ld	s0,16(sp)
    80002dee:	64a2                	ld	s1,8(sp)
    80002df0:	6105                	add	sp,sp,32
    80002df2:	8082                	ret

0000000080002df4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002df4:	7179                	add	sp,sp,-48
    80002df6:	f406                	sd	ra,40(sp)
    80002df8:	f022                	sd	s0,32(sp)
    80002dfa:	ec26                	sd	s1,24(sp)
    80002dfc:	e84a                	sd	s2,16(sp)
    80002dfe:	e44e                	sd	s3,8(sp)
    80002e00:	e052                	sd	s4,0(sp)
    80002e02:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e04:	00005597          	auipc	a1,0x5
    80002e08:	70458593          	add	a1,a1,1796 # 80008508 <syscalls+0xb8>
    80002e0c:	00014517          	auipc	a0,0x14
    80002e10:	b7c50513          	add	a0,a0,-1156 # 80016988 <bcache>
    80002e14:	ffffe097          	auipc	ra,0xffffe
    80002e18:	d2e080e7          	jalr	-722(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e1c:	0001c797          	auipc	a5,0x1c
    80002e20:	b6c78793          	add	a5,a5,-1172 # 8001e988 <bcache+0x8000>
    80002e24:	0001c717          	auipc	a4,0x1c
    80002e28:	dcc70713          	add	a4,a4,-564 # 8001ebf0 <bcache+0x8268>
    80002e2c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e30:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e34:	00014497          	auipc	s1,0x14
    80002e38:	b6c48493          	add	s1,s1,-1172 # 800169a0 <bcache+0x18>
    b->next = bcache.head.next;
    80002e3c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e3e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e40:	00005a17          	auipc	s4,0x5
    80002e44:	6d0a0a13          	add	s4,s4,1744 # 80008510 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002e48:	2b893783          	ld	a5,696(s2)
    80002e4c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e4e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e52:	85d2                	mv	a1,s4
    80002e54:	01048513          	add	a0,s1,16
    80002e58:	00001097          	auipc	ra,0x1
    80002e5c:	496080e7          	jalr	1174(ra) # 800042ee <initsleeplock>
    bcache.head.next->prev = b;
    80002e60:	2b893783          	ld	a5,696(s2)
    80002e64:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e66:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e6a:	45848493          	add	s1,s1,1112
    80002e6e:	fd349de3          	bne	s1,s3,80002e48 <binit+0x54>
  }
}
    80002e72:	70a2                	ld	ra,40(sp)
    80002e74:	7402                	ld	s0,32(sp)
    80002e76:	64e2                	ld	s1,24(sp)
    80002e78:	6942                	ld	s2,16(sp)
    80002e7a:	69a2                	ld	s3,8(sp)
    80002e7c:	6a02                	ld	s4,0(sp)
    80002e7e:	6145                	add	sp,sp,48
    80002e80:	8082                	ret

0000000080002e82 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e82:	7179                	add	sp,sp,-48
    80002e84:	f406                	sd	ra,40(sp)
    80002e86:	f022                	sd	s0,32(sp)
    80002e88:	ec26                	sd	s1,24(sp)
    80002e8a:	e84a                	sd	s2,16(sp)
    80002e8c:	e44e                	sd	s3,8(sp)
    80002e8e:	1800                	add	s0,sp,48
    80002e90:	892a                	mv	s2,a0
    80002e92:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e94:	00014517          	auipc	a0,0x14
    80002e98:	af450513          	add	a0,a0,-1292 # 80016988 <bcache>
    80002e9c:	ffffe097          	auipc	ra,0xffffe
    80002ea0:	d36080e7          	jalr	-714(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ea4:	0001c497          	auipc	s1,0x1c
    80002ea8:	d9c4b483          	ld	s1,-612(s1) # 8001ec40 <bcache+0x82b8>
    80002eac:	0001c797          	auipc	a5,0x1c
    80002eb0:	d4478793          	add	a5,a5,-700 # 8001ebf0 <bcache+0x8268>
    80002eb4:	02f48f63          	beq	s1,a5,80002ef2 <bread+0x70>
    80002eb8:	873e                	mv	a4,a5
    80002eba:	a021                	j	80002ec2 <bread+0x40>
    80002ebc:	68a4                	ld	s1,80(s1)
    80002ebe:	02e48a63          	beq	s1,a4,80002ef2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ec2:	449c                	lw	a5,8(s1)
    80002ec4:	ff279ce3          	bne	a5,s2,80002ebc <bread+0x3a>
    80002ec8:	44dc                	lw	a5,12(s1)
    80002eca:	ff3799e3          	bne	a5,s3,80002ebc <bread+0x3a>
      b->refcnt++;
    80002ece:	40bc                	lw	a5,64(s1)
    80002ed0:	2785                	addw	a5,a5,1
    80002ed2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ed4:	00014517          	auipc	a0,0x14
    80002ed8:	ab450513          	add	a0,a0,-1356 # 80016988 <bcache>
    80002edc:	ffffe097          	auipc	ra,0xffffe
    80002ee0:	daa080e7          	jalr	-598(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80002ee4:	01048513          	add	a0,s1,16
    80002ee8:	00001097          	auipc	ra,0x1
    80002eec:	440080e7          	jalr	1088(ra) # 80004328 <acquiresleep>
      return b;
    80002ef0:	a8b9                	j	80002f4e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ef2:	0001c497          	auipc	s1,0x1c
    80002ef6:	d464b483          	ld	s1,-698(s1) # 8001ec38 <bcache+0x82b0>
    80002efa:	0001c797          	auipc	a5,0x1c
    80002efe:	cf678793          	add	a5,a5,-778 # 8001ebf0 <bcache+0x8268>
    80002f02:	00f48863          	beq	s1,a5,80002f12 <bread+0x90>
    80002f06:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f08:	40bc                	lw	a5,64(s1)
    80002f0a:	cf81                	beqz	a5,80002f22 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f0c:	64a4                	ld	s1,72(s1)
    80002f0e:	fee49de3          	bne	s1,a4,80002f08 <bread+0x86>
  panic("bget: no buffers");
    80002f12:	00005517          	auipc	a0,0x5
    80002f16:	60650513          	add	a0,a0,1542 # 80008518 <syscalls+0xc8>
    80002f1a:	ffffd097          	auipc	ra,0xffffd
    80002f1e:	622080e7          	jalr	1570(ra) # 8000053c <panic>
      b->dev = dev;
    80002f22:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f26:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f2a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f2e:	4785                	li	a5,1
    80002f30:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f32:	00014517          	auipc	a0,0x14
    80002f36:	a5650513          	add	a0,a0,-1450 # 80016988 <bcache>
    80002f3a:	ffffe097          	auipc	ra,0xffffe
    80002f3e:	d4c080e7          	jalr	-692(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80002f42:	01048513          	add	a0,s1,16
    80002f46:	00001097          	auipc	ra,0x1
    80002f4a:	3e2080e7          	jalr	994(ra) # 80004328 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f4e:	409c                	lw	a5,0(s1)
    80002f50:	cb89                	beqz	a5,80002f62 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f52:	8526                	mv	a0,s1
    80002f54:	70a2                	ld	ra,40(sp)
    80002f56:	7402                	ld	s0,32(sp)
    80002f58:	64e2                	ld	s1,24(sp)
    80002f5a:	6942                	ld	s2,16(sp)
    80002f5c:	69a2                	ld	s3,8(sp)
    80002f5e:	6145                	add	sp,sp,48
    80002f60:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f62:	4581                	li	a1,0
    80002f64:	8526                	mv	a0,s1
    80002f66:	00003097          	auipc	ra,0x3
    80002f6a:	f7c080e7          	jalr	-132(ra) # 80005ee2 <virtio_disk_rw>
    b->valid = 1;
    80002f6e:	4785                	li	a5,1
    80002f70:	c09c                	sw	a5,0(s1)
  return b;
    80002f72:	b7c5                	j	80002f52 <bread+0xd0>

0000000080002f74 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f74:	1101                	add	sp,sp,-32
    80002f76:	ec06                	sd	ra,24(sp)
    80002f78:	e822                	sd	s0,16(sp)
    80002f7a:	e426                	sd	s1,8(sp)
    80002f7c:	1000                	add	s0,sp,32
    80002f7e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f80:	0541                	add	a0,a0,16
    80002f82:	00001097          	auipc	ra,0x1
    80002f86:	440080e7          	jalr	1088(ra) # 800043c2 <holdingsleep>
    80002f8a:	cd01                	beqz	a0,80002fa2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f8c:	4585                	li	a1,1
    80002f8e:	8526                	mv	a0,s1
    80002f90:	00003097          	auipc	ra,0x3
    80002f94:	f52080e7          	jalr	-174(ra) # 80005ee2 <virtio_disk_rw>
}
    80002f98:	60e2                	ld	ra,24(sp)
    80002f9a:	6442                	ld	s0,16(sp)
    80002f9c:	64a2                	ld	s1,8(sp)
    80002f9e:	6105                	add	sp,sp,32
    80002fa0:	8082                	ret
    panic("bwrite");
    80002fa2:	00005517          	auipc	a0,0x5
    80002fa6:	58e50513          	add	a0,a0,1422 # 80008530 <syscalls+0xe0>
    80002faa:	ffffd097          	auipc	ra,0xffffd
    80002fae:	592080e7          	jalr	1426(ra) # 8000053c <panic>

0000000080002fb2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fb2:	1101                	add	sp,sp,-32
    80002fb4:	ec06                	sd	ra,24(sp)
    80002fb6:	e822                	sd	s0,16(sp)
    80002fb8:	e426                	sd	s1,8(sp)
    80002fba:	e04a                	sd	s2,0(sp)
    80002fbc:	1000                	add	s0,sp,32
    80002fbe:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fc0:	01050913          	add	s2,a0,16
    80002fc4:	854a                	mv	a0,s2
    80002fc6:	00001097          	auipc	ra,0x1
    80002fca:	3fc080e7          	jalr	1020(ra) # 800043c2 <holdingsleep>
    80002fce:	c925                	beqz	a0,8000303e <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80002fd0:	854a                	mv	a0,s2
    80002fd2:	00001097          	auipc	ra,0x1
    80002fd6:	3ac080e7          	jalr	940(ra) # 8000437e <releasesleep>

  acquire(&bcache.lock);
    80002fda:	00014517          	auipc	a0,0x14
    80002fde:	9ae50513          	add	a0,a0,-1618 # 80016988 <bcache>
    80002fe2:	ffffe097          	auipc	ra,0xffffe
    80002fe6:	bf0080e7          	jalr	-1040(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80002fea:	40bc                	lw	a5,64(s1)
    80002fec:	37fd                	addw	a5,a5,-1
    80002fee:	0007871b          	sext.w	a4,a5
    80002ff2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002ff4:	e71d                	bnez	a4,80003022 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002ff6:	68b8                	ld	a4,80(s1)
    80002ff8:	64bc                	ld	a5,72(s1)
    80002ffa:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80002ffc:	68b8                	ld	a4,80(s1)
    80002ffe:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003000:	0001c797          	auipc	a5,0x1c
    80003004:	98878793          	add	a5,a5,-1656 # 8001e988 <bcache+0x8000>
    80003008:	2b87b703          	ld	a4,696(a5)
    8000300c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000300e:	0001c717          	auipc	a4,0x1c
    80003012:	be270713          	add	a4,a4,-1054 # 8001ebf0 <bcache+0x8268>
    80003016:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003018:	2b87b703          	ld	a4,696(a5)
    8000301c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000301e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003022:	00014517          	auipc	a0,0x14
    80003026:	96650513          	add	a0,a0,-1690 # 80016988 <bcache>
    8000302a:	ffffe097          	auipc	ra,0xffffe
    8000302e:	c5c080e7          	jalr	-932(ra) # 80000c86 <release>
}
    80003032:	60e2                	ld	ra,24(sp)
    80003034:	6442                	ld	s0,16(sp)
    80003036:	64a2                	ld	s1,8(sp)
    80003038:	6902                	ld	s2,0(sp)
    8000303a:	6105                	add	sp,sp,32
    8000303c:	8082                	ret
    panic("brelse");
    8000303e:	00005517          	auipc	a0,0x5
    80003042:	4fa50513          	add	a0,a0,1274 # 80008538 <syscalls+0xe8>
    80003046:	ffffd097          	auipc	ra,0xffffd
    8000304a:	4f6080e7          	jalr	1270(ra) # 8000053c <panic>

000000008000304e <bpin>:

void
bpin(struct buf *b) {
    8000304e:	1101                	add	sp,sp,-32
    80003050:	ec06                	sd	ra,24(sp)
    80003052:	e822                	sd	s0,16(sp)
    80003054:	e426                	sd	s1,8(sp)
    80003056:	1000                	add	s0,sp,32
    80003058:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000305a:	00014517          	auipc	a0,0x14
    8000305e:	92e50513          	add	a0,a0,-1746 # 80016988 <bcache>
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	b70080e7          	jalr	-1168(ra) # 80000bd2 <acquire>
  b->refcnt++;
    8000306a:	40bc                	lw	a5,64(s1)
    8000306c:	2785                	addw	a5,a5,1
    8000306e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003070:	00014517          	auipc	a0,0x14
    80003074:	91850513          	add	a0,a0,-1768 # 80016988 <bcache>
    80003078:	ffffe097          	auipc	ra,0xffffe
    8000307c:	c0e080e7          	jalr	-1010(ra) # 80000c86 <release>
}
    80003080:	60e2                	ld	ra,24(sp)
    80003082:	6442                	ld	s0,16(sp)
    80003084:	64a2                	ld	s1,8(sp)
    80003086:	6105                	add	sp,sp,32
    80003088:	8082                	ret

000000008000308a <bunpin>:

void
bunpin(struct buf *b) {
    8000308a:	1101                	add	sp,sp,-32
    8000308c:	ec06                	sd	ra,24(sp)
    8000308e:	e822                	sd	s0,16(sp)
    80003090:	e426                	sd	s1,8(sp)
    80003092:	1000                	add	s0,sp,32
    80003094:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003096:	00014517          	auipc	a0,0x14
    8000309a:	8f250513          	add	a0,a0,-1806 # 80016988 <bcache>
    8000309e:	ffffe097          	auipc	ra,0xffffe
    800030a2:	b34080e7          	jalr	-1228(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800030a6:	40bc                	lw	a5,64(s1)
    800030a8:	37fd                	addw	a5,a5,-1
    800030aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030ac:	00014517          	auipc	a0,0x14
    800030b0:	8dc50513          	add	a0,a0,-1828 # 80016988 <bcache>
    800030b4:	ffffe097          	auipc	ra,0xffffe
    800030b8:	bd2080e7          	jalr	-1070(ra) # 80000c86 <release>
}
    800030bc:	60e2                	ld	ra,24(sp)
    800030be:	6442                	ld	s0,16(sp)
    800030c0:	64a2                	ld	s1,8(sp)
    800030c2:	6105                	add	sp,sp,32
    800030c4:	8082                	ret

00000000800030c6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030c6:	1101                	add	sp,sp,-32
    800030c8:	ec06                	sd	ra,24(sp)
    800030ca:	e822                	sd	s0,16(sp)
    800030cc:	e426                	sd	s1,8(sp)
    800030ce:	e04a                	sd	s2,0(sp)
    800030d0:	1000                	add	s0,sp,32
    800030d2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030d4:	00d5d59b          	srlw	a1,a1,0xd
    800030d8:	0001c797          	auipc	a5,0x1c
    800030dc:	f8c7a783          	lw	a5,-116(a5) # 8001f064 <sb+0x1c>
    800030e0:	9dbd                	addw	a1,a1,a5
    800030e2:	00000097          	auipc	ra,0x0
    800030e6:	da0080e7          	jalr	-608(ra) # 80002e82 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030ea:	0074f713          	and	a4,s1,7
    800030ee:	4785                	li	a5,1
    800030f0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030f4:	14ce                	sll	s1,s1,0x33
    800030f6:	90d9                	srl	s1,s1,0x36
    800030f8:	00950733          	add	a4,a0,s1
    800030fc:	05874703          	lbu	a4,88(a4)
    80003100:	00e7f6b3          	and	a3,a5,a4
    80003104:	c69d                	beqz	a3,80003132 <bfree+0x6c>
    80003106:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003108:	94aa                	add	s1,s1,a0
    8000310a:	fff7c793          	not	a5,a5
    8000310e:	8f7d                	and	a4,a4,a5
    80003110:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003114:	00001097          	auipc	ra,0x1
    80003118:	0f6080e7          	jalr	246(ra) # 8000420a <log_write>
  brelse(bp);
    8000311c:	854a                	mv	a0,s2
    8000311e:	00000097          	auipc	ra,0x0
    80003122:	e94080e7          	jalr	-364(ra) # 80002fb2 <brelse>
}
    80003126:	60e2                	ld	ra,24(sp)
    80003128:	6442                	ld	s0,16(sp)
    8000312a:	64a2                	ld	s1,8(sp)
    8000312c:	6902                	ld	s2,0(sp)
    8000312e:	6105                	add	sp,sp,32
    80003130:	8082                	ret
    panic("freeing free block");
    80003132:	00005517          	auipc	a0,0x5
    80003136:	40e50513          	add	a0,a0,1038 # 80008540 <syscalls+0xf0>
    8000313a:	ffffd097          	auipc	ra,0xffffd
    8000313e:	402080e7          	jalr	1026(ra) # 8000053c <panic>

0000000080003142 <balloc>:
{
    80003142:	711d                	add	sp,sp,-96
    80003144:	ec86                	sd	ra,88(sp)
    80003146:	e8a2                	sd	s0,80(sp)
    80003148:	e4a6                	sd	s1,72(sp)
    8000314a:	e0ca                	sd	s2,64(sp)
    8000314c:	fc4e                	sd	s3,56(sp)
    8000314e:	f852                	sd	s4,48(sp)
    80003150:	f456                	sd	s5,40(sp)
    80003152:	f05a                	sd	s6,32(sp)
    80003154:	ec5e                	sd	s7,24(sp)
    80003156:	e862                	sd	s8,16(sp)
    80003158:	e466                	sd	s9,8(sp)
    8000315a:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000315c:	0001c797          	auipc	a5,0x1c
    80003160:	ef07a783          	lw	a5,-272(a5) # 8001f04c <sb+0x4>
    80003164:	cff5                	beqz	a5,80003260 <balloc+0x11e>
    80003166:	8baa                	mv	s7,a0
    80003168:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000316a:	0001cb17          	auipc	s6,0x1c
    8000316e:	edeb0b13          	add	s6,s6,-290 # 8001f048 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003172:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003174:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003176:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003178:	6c89                	lui	s9,0x2
    8000317a:	a061                	j	80003202 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000317c:	97ca                	add	a5,a5,s2
    8000317e:	8e55                	or	a2,a2,a3
    80003180:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003184:	854a                	mv	a0,s2
    80003186:	00001097          	auipc	ra,0x1
    8000318a:	084080e7          	jalr	132(ra) # 8000420a <log_write>
        brelse(bp);
    8000318e:	854a                	mv	a0,s2
    80003190:	00000097          	auipc	ra,0x0
    80003194:	e22080e7          	jalr	-478(ra) # 80002fb2 <brelse>
  bp = bread(dev, bno);
    80003198:	85a6                	mv	a1,s1
    8000319a:	855e                	mv	a0,s7
    8000319c:	00000097          	auipc	ra,0x0
    800031a0:	ce6080e7          	jalr	-794(ra) # 80002e82 <bread>
    800031a4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031a6:	40000613          	li	a2,1024
    800031aa:	4581                	li	a1,0
    800031ac:	05850513          	add	a0,a0,88
    800031b0:	ffffe097          	auipc	ra,0xffffe
    800031b4:	b1e080e7          	jalr	-1250(ra) # 80000cce <memset>
  log_write(bp);
    800031b8:	854a                	mv	a0,s2
    800031ba:	00001097          	auipc	ra,0x1
    800031be:	050080e7          	jalr	80(ra) # 8000420a <log_write>
  brelse(bp);
    800031c2:	854a                	mv	a0,s2
    800031c4:	00000097          	auipc	ra,0x0
    800031c8:	dee080e7          	jalr	-530(ra) # 80002fb2 <brelse>
}
    800031cc:	8526                	mv	a0,s1
    800031ce:	60e6                	ld	ra,88(sp)
    800031d0:	6446                	ld	s0,80(sp)
    800031d2:	64a6                	ld	s1,72(sp)
    800031d4:	6906                	ld	s2,64(sp)
    800031d6:	79e2                	ld	s3,56(sp)
    800031d8:	7a42                	ld	s4,48(sp)
    800031da:	7aa2                	ld	s5,40(sp)
    800031dc:	7b02                	ld	s6,32(sp)
    800031de:	6be2                	ld	s7,24(sp)
    800031e0:	6c42                	ld	s8,16(sp)
    800031e2:	6ca2                	ld	s9,8(sp)
    800031e4:	6125                	add	sp,sp,96
    800031e6:	8082                	ret
    brelse(bp);
    800031e8:	854a                	mv	a0,s2
    800031ea:	00000097          	auipc	ra,0x0
    800031ee:	dc8080e7          	jalr	-568(ra) # 80002fb2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031f2:	015c87bb          	addw	a5,s9,s5
    800031f6:	00078a9b          	sext.w	s5,a5
    800031fa:	004b2703          	lw	a4,4(s6)
    800031fe:	06eaf163          	bgeu	s5,a4,80003260 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003202:	41fad79b          	sraw	a5,s5,0x1f
    80003206:	0137d79b          	srlw	a5,a5,0x13
    8000320a:	015787bb          	addw	a5,a5,s5
    8000320e:	40d7d79b          	sraw	a5,a5,0xd
    80003212:	01cb2583          	lw	a1,28(s6)
    80003216:	9dbd                	addw	a1,a1,a5
    80003218:	855e                	mv	a0,s7
    8000321a:	00000097          	auipc	ra,0x0
    8000321e:	c68080e7          	jalr	-920(ra) # 80002e82 <bread>
    80003222:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003224:	004b2503          	lw	a0,4(s6)
    80003228:	000a849b          	sext.w	s1,s5
    8000322c:	8762                	mv	a4,s8
    8000322e:	faa4fde3          	bgeu	s1,a0,800031e8 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003232:	00777693          	and	a3,a4,7
    80003236:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000323a:	41f7579b          	sraw	a5,a4,0x1f
    8000323e:	01d7d79b          	srlw	a5,a5,0x1d
    80003242:	9fb9                	addw	a5,a5,a4
    80003244:	4037d79b          	sraw	a5,a5,0x3
    80003248:	00f90633          	add	a2,s2,a5
    8000324c:	05864603          	lbu	a2,88(a2)
    80003250:	00c6f5b3          	and	a1,a3,a2
    80003254:	d585                	beqz	a1,8000317c <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003256:	2705                	addw	a4,a4,1
    80003258:	2485                	addw	s1,s1,1
    8000325a:	fd471ae3          	bne	a4,s4,8000322e <balloc+0xec>
    8000325e:	b769                	j	800031e8 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003260:	00005517          	auipc	a0,0x5
    80003264:	2f850513          	add	a0,a0,760 # 80008558 <syscalls+0x108>
    80003268:	ffffd097          	auipc	ra,0xffffd
    8000326c:	31e080e7          	jalr	798(ra) # 80000586 <printf>
  return 0;
    80003270:	4481                	li	s1,0
    80003272:	bfa9                	j	800031cc <balloc+0x8a>

0000000080003274 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003274:	7179                	add	sp,sp,-48
    80003276:	f406                	sd	ra,40(sp)
    80003278:	f022                	sd	s0,32(sp)
    8000327a:	ec26                	sd	s1,24(sp)
    8000327c:	e84a                	sd	s2,16(sp)
    8000327e:	e44e                	sd	s3,8(sp)
    80003280:	e052                	sd	s4,0(sp)
    80003282:	1800                	add	s0,sp,48
    80003284:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003286:	47ad                	li	a5,11
    80003288:	02b7e863          	bltu	a5,a1,800032b8 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000328c:	02059793          	sll	a5,a1,0x20
    80003290:	01e7d593          	srl	a1,a5,0x1e
    80003294:	00b504b3          	add	s1,a0,a1
    80003298:	0504a903          	lw	s2,80(s1)
    8000329c:	06091e63          	bnez	s2,80003318 <bmap+0xa4>
      addr = balloc(ip->dev);
    800032a0:	4108                	lw	a0,0(a0)
    800032a2:	00000097          	auipc	ra,0x0
    800032a6:	ea0080e7          	jalr	-352(ra) # 80003142 <balloc>
    800032aa:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032ae:	06090563          	beqz	s2,80003318 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800032b2:	0524a823          	sw	s2,80(s1)
    800032b6:	a08d                	j	80003318 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800032b8:	ff45849b          	addw	s1,a1,-12
    800032bc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032c0:	0ff00793          	li	a5,255
    800032c4:	08e7e563          	bltu	a5,a4,8000334e <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800032c8:	08052903          	lw	s2,128(a0)
    800032cc:	00091d63          	bnez	s2,800032e6 <bmap+0x72>
      addr = balloc(ip->dev);
    800032d0:	4108                	lw	a0,0(a0)
    800032d2:	00000097          	auipc	ra,0x0
    800032d6:	e70080e7          	jalr	-400(ra) # 80003142 <balloc>
    800032da:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032de:	02090d63          	beqz	s2,80003318 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800032e2:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800032e6:	85ca                	mv	a1,s2
    800032e8:	0009a503          	lw	a0,0(s3)
    800032ec:	00000097          	auipc	ra,0x0
    800032f0:	b96080e7          	jalr	-1130(ra) # 80002e82 <bread>
    800032f4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032f6:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    800032fa:	02049713          	sll	a4,s1,0x20
    800032fe:	01e75593          	srl	a1,a4,0x1e
    80003302:	00b784b3          	add	s1,a5,a1
    80003306:	0004a903          	lw	s2,0(s1)
    8000330a:	02090063          	beqz	s2,8000332a <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000330e:	8552                	mv	a0,s4
    80003310:	00000097          	auipc	ra,0x0
    80003314:	ca2080e7          	jalr	-862(ra) # 80002fb2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003318:	854a                	mv	a0,s2
    8000331a:	70a2                	ld	ra,40(sp)
    8000331c:	7402                	ld	s0,32(sp)
    8000331e:	64e2                	ld	s1,24(sp)
    80003320:	6942                	ld	s2,16(sp)
    80003322:	69a2                	ld	s3,8(sp)
    80003324:	6a02                	ld	s4,0(sp)
    80003326:	6145                	add	sp,sp,48
    80003328:	8082                	ret
      addr = balloc(ip->dev);
    8000332a:	0009a503          	lw	a0,0(s3)
    8000332e:	00000097          	auipc	ra,0x0
    80003332:	e14080e7          	jalr	-492(ra) # 80003142 <balloc>
    80003336:	0005091b          	sext.w	s2,a0
      if(addr){
    8000333a:	fc090ae3          	beqz	s2,8000330e <bmap+0x9a>
        a[bn] = addr;
    8000333e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003342:	8552                	mv	a0,s4
    80003344:	00001097          	auipc	ra,0x1
    80003348:	ec6080e7          	jalr	-314(ra) # 8000420a <log_write>
    8000334c:	b7c9                	j	8000330e <bmap+0x9a>
  panic("bmap: out of range");
    8000334e:	00005517          	auipc	a0,0x5
    80003352:	22250513          	add	a0,a0,546 # 80008570 <syscalls+0x120>
    80003356:	ffffd097          	auipc	ra,0xffffd
    8000335a:	1e6080e7          	jalr	486(ra) # 8000053c <panic>

000000008000335e <iget>:
{
    8000335e:	7179                	add	sp,sp,-48
    80003360:	f406                	sd	ra,40(sp)
    80003362:	f022                	sd	s0,32(sp)
    80003364:	ec26                	sd	s1,24(sp)
    80003366:	e84a                	sd	s2,16(sp)
    80003368:	e44e                	sd	s3,8(sp)
    8000336a:	e052                	sd	s4,0(sp)
    8000336c:	1800                	add	s0,sp,48
    8000336e:	89aa                	mv	s3,a0
    80003370:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003372:	0001c517          	auipc	a0,0x1c
    80003376:	cf650513          	add	a0,a0,-778 # 8001f068 <itable>
    8000337a:	ffffe097          	auipc	ra,0xffffe
    8000337e:	858080e7          	jalr	-1960(ra) # 80000bd2 <acquire>
  empty = 0;
    80003382:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003384:	0001c497          	auipc	s1,0x1c
    80003388:	cfc48493          	add	s1,s1,-772 # 8001f080 <itable+0x18>
    8000338c:	0001d697          	auipc	a3,0x1d
    80003390:	78468693          	add	a3,a3,1924 # 80020b10 <log>
    80003394:	a039                	j	800033a2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003396:	02090b63          	beqz	s2,800033cc <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000339a:	08848493          	add	s1,s1,136
    8000339e:	02d48a63          	beq	s1,a3,800033d2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033a2:	449c                	lw	a5,8(s1)
    800033a4:	fef059e3          	blez	a5,80003396 <iget+0x38>
    800033a8:	4098                	lw	a4,0(s1)
    800033aa:	ff3716e3          	bne	a4,s3,80003396 <iget+0x38>
    800033ae:	40d8                	lw	a4,4(s1)
    800033b0:	ff4713e3          	bne	a4,s4,80003396 <iget+0x38>
      ip->ref++;
    800033b4:	2785                	addw	a5,a5,1
    800033b6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033b8:	0001c517          	auipc	a0,0x1c
    800033bc:	cb050513          	add	a0,a0,-848 # 8001f068 <itable>
    800033c0:	ffffe097          	auipc	ra,0xffffe
    800033c4:	8c6080e7          	jalr	-1850(ra) # 80000c86 <release>
      return ip;
    800033c8:	8926                	mv	s2,s1
    800033ca:	a03d                	j	800033f8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033cc:	f7f9                	bnez	a5,8000339a <iget+0x3c>
    800033ce:	8926                	mv	s2,s1
    800033d0:	b7e9                	j	8000339a <iget+0x3c>
  if(empty == 0)
    800033d2:	02090c63          	beqz	s2,8000340a <iget+0xac>
  ip->dev = dev;
    800033d6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033da:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033de:	4785                	li	a5,1
    800033e0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033e4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033e8:	0001c517          	auipc	a0,0x1c
    800033ec:	c8050513          	add	a0,a0,-896 # 8001f068 <itable>
    800033f0:	ffffe097          	auipc	ra,0xffffe
    800033f4:	896080e7          	jalr	-1898(ra) # 80000c86 <release>
}
    800033f8:	854a                	mv	a0,s2
    800033fa:	70a2                	ld	ra,40(sp)
    800033fc:	7402                	ld	s0,32(sp)
    800033fe:	64e2                	ld	s1,24(sp)
    80003400:	6942                	ld	s2,16(sp)
    80003402:	69a2                	ld	s3,8(sp)
    80003404:	6a02                	ld	s4,0(sp)
    80003406:	6145                	add	sp,sp,48
    80003408:	8082                	ret
    panic("iget: no inodes");
    8000340a:	00005517          	auipc	a0,0x5
    8000340e:	17e50513          	add	a0,a0,382 # 80008588 <syscalls+0x138>
    80003412:	ffffd097          	auipc	ra,0xffffd
    80003416:	12a080e7          	jalr	298(ra) # 8000053c <panic>

000000008000341a <fsinit>:
fsinit(int dev) {
    8000341a:	7179                	add	sp,sp,-48
    8000341c:	f406                	sd	ra,40(sp)
    8000341e:	f022                	sd	s0,32(sp)
    80003420:	ec26                	sd	s1,24(sp)
    80003422:	e84a                	sd	s2,16(sp)
    80003424:	e44e                	sd	s3,8(sp)
    80003426:	1800                	add	s0,sp,48
    80003428:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000342a:	4585                	li	a1,1
    8000342c:	00000097          	auipc	ra,0x0
    80003430:	a56080e7          	jalr	-1450(ra) # 80002e82 <bread>
    80003434:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003436:	0001c997          	auipc	s3,0x1c
    8000343a:	c1298993          	add	s3,s3,-1006 # 8001f048 <sb>
    8000343e:	02000613          	li	a2,32
    80003442:	05850593          	add	a1,a0,88
    80003446:	854e                	mv	a0,s3
    80003448:	ffffe097          	auipc	ra,0xffffe
    8000344c:	8e2080e7          	jalr	-1822(ra) # 80000d2a <memmove>
  brelse(bp);
    80003450:	8526                	mv	a0,s1
    80003452:	00000097          	auipc	ra,0x0
    80003456:	b60080e7          	jalr	-1184(ra) # 80002fb2 <brelse>
  if(sb.magic != FSMAGIC)
    8000345a:	0009a703          	lw	a4,0(s3)
    8000345e:	102037b7          	lui	a5,0x10203
    80003462:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003466:	02f71263          	bne	a4,a5,8000348a <fsinit+0x70>
  initlog(dev, &sb);
    8000346a:	0001c597          	auipc	a1,0x1c
    8000346e:	bde58593          	add	a1,a1,-1058 # 8001f048 <sb>
    80003472:	854a                	mv	a0,s2
    80003474:	00001097          	auipc	ra,0x1
    80003478:	b2c080e7          	jalr	-1236(ra) # 80003fa0 <initlog>
}
    8000347c:	70a2                	ld	ra,40(sp)
    8000347e:	7402                	ld	s0,32(sp)
    80003480:	64e2                	ld	s1,24(sp)
    80003482:	6942                	ld	s2,16(sp)
    80003484:	69a2                	ld	s3,8(sp)
    80003486:	6145                	add	sp,sp,48
    80003488:	8082                	ret
    panic("invalid file system");
    8000348a:	00005517          	auipc	a0,0x5
    8000348e:	10e50513          	add	a0,a0,270 # 80008598 <syscalls+0x148>
    80003492:	ffffd097          	auipc	ra,0xffffd
    80003496:	0aa080e7          	jalr	170(ra) # 8000053c <panic>

000000008000349a <iinit>:
{
    8000349a:	7179                	add	sp,sp,-48
    8000349c:	f406                	sd	ra,40(sp)
    8000349e:	f022                	sd	s0,32(sp)
    800034a0:	ec26                	sd	s1,24(sp)
    800034a2:	e84a                	sd	s2,16(sp)
    800034a4:	e44e                	sd	s3,8(sp)
    800034a6:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    800034a8:	00005597          	auipc	a1,0x5
    800034ac:	10858593          	add	a1,a1,264 # 800085b0 <syscalls+0x160>
    800034b0:	0001c517          	auipc	a0,0x1c
    800034b4:	bb850513          	add	a0,a0,-1096 # 8001f068 <itable>
    800034b8:	ffffd097          	auipc	ra,0xffffd
    800034bc:	68a080e7          	jalr	1674(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034c0:	0001c497          	auipc	s1,0x1c
    800034c4:	bd048493          	add	s1,s1,-1072 # 8001f090 <itable+0x28>
    800034c8:	0001d997          	auipc	s3,0x1d
    800034cc:	65898993          	add	s3,s3,1624 # 80020b20 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800034d0:	00005917          	auipc	s2,0x5
    800034d4:	0e890913          	add	s2,s2,232 # 800085b8 <syscalls+0x168>
    800034d8:	85ca                	mv	a1,s2
    800034da:	8526                	mv	a0,s1
    800034dc:	00001097          	auipc	ra,0x1
    800034e0:	e12080e7          	jalr	-494(ra) # 800042ee <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034e4:	08848493          	add	s1,s1,136
    800034e8:	ff3498e3          	bne	s1,s3,800034d8 <iinit+0x3e>
}
    800034ec:	70a2                	ld	ra,40(sp)
    800034ee:	7402                	ld	s0,32(sp)
    800034f0:	64e2                	ld	s1,24(sp)
    800034f2:	6942                	ld	s2,16(sp)
    800034f4:	69a2                	ld	s3,8(sp)
    800034f6:	6145                	add	sp,sp,48
    800034f8:	8082                	ret

00000000800034fa <ialloc>:
{
    800034fa:	7139                	add	sp,sp,-64
    800034fc:	fc06                	sd	ra,56(sp)
    800034fe:	f822                	sd	s0,48(sp)
    80003500:	f426                	sd	s1,40(sp)
    80003502:	f04a                	sd	s2,32(sp)
    80003504:	ec4e                	sd	s3,24(sp)
    80003506:	e852                	sd	s4,16(sp)
    80003508:	e456                	sd	s5,8(sp)
    8000350a:	e05a                	sd	s6,0(sp)
    8000350c:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    8000350e:	0001c717          	auipc	a4,0x1c
    80003512:	b4672703          	lw	a4,-1210(a4) # 8001f054 <sb+0xc>
    80003516:	4785                	li	a5,1
    80003518:	04e7f863          	bgeu	a5,a4,80003568 <ialloc+0x6e>
    8000351c:	8aaa                	mv	s5,a0
    8000351e:	8b2e                	mv	s6,a1
    80003520:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003522:	0001ca17          	auipc	s4,0x1c
    80003526:	b26a0a13          	add	s4,s4,-1242 # 8001f048 <sb>
    8000352a:	00495593          	srl	a1,s2,0x4
    8000352e:	018a2783          	lw	a5,24(s4)
    80003532:	9dbd                	addw	a1,a1,a5
    80003534:	8556                	mv	a0,s5
    80003536:	00000097          	auipc	ra,0x0
    8000353a:	94c080e7          	jalr	-1716(ra) # 80002e82 <bread>
    8000353e:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003540:	05850993          	add	s3,a0,88
    80003544:	00f97793          	and	a5,s2,15
    80003548:	079a                	sll	a5,a5,0x6
    8000354a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000354c:	00099783          	lh	a5,0(s3)
    80003550:	cf9d                	beqz	a5,8000358e <ialloc+0x94>
    brelse(bp);
    80003552:	00000097          	auipc	ra,0x0
    80003556:	a60080e7          	jalr	-1440(ra) # 80002fb2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000355a:	0905                	add	s2,s2,1
    8000355c:	00ca2703          	lw	a4,12(s4)
    80003560:	0009079b          	sext.w	a5,s2
    80003564:	fce7e3e3          	bltu	a5,a4,8000352a <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003568:	00005517          	auipc	a0,0x5
    8000356c:	05850513          	add	a0,a0,88 # 800085c0 <syscalls+0x170>
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	016080e7          	jalr	22(ra) # 80000586 <printf>
  return 0;
    80003578:	4501                	li	a0,0
}
    8000357a:	70e2                	ld	ra,56(sp)
    8000357c:	7442                	ld	s0,48(sp)
    8000357e:	74a2                	ld	s1,40(sp)
    80003580:	7902                	ld	s2,32(sp)
    80003582:	69e2                	ld	s3,24(sp)
    80003584:	6a42                	ld	s4,16(sp)
    80003586:	6aa2                	ld	s5,8(sp)
    80003588:	6b02                	ld	s6,0(sp)
    8000358a:	6121                	add	sp,sp,64
    8000358c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000358e:	04000613          	li	a2,64
    80003592:	4581                	li	a1,0
    80003594:	854e                	mv	a0,s3
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	738080e7          	jalr	1848(ra) # 80000cce <memset>
      dip->type = type;
    8000359e:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035a2:	8526                	mv	a0,s1
    800035a4:	00001097          	auipc	ra,0x1
    800035a8:	c66080e7          	jalr	-922(ra) # 8000420a <log_write>
      brelse(bp);
    800035ac:	8526                	mv	a0,s1
    800035ae:	00000097          	auipc	ra,0x0
    800035b2:	a04080e7          	jalr	-1532(ra) # 80002fb2 <brelse>
      return iget(dev, inum);
    800035b6:	0009059b          	sext.w	a1,s2
    800035ba:	8556                	mv	a0,s5
    800035bc:	00000097          	auipc	ra,0x0
    800035c0:	da2080e7          	jalr	-606(ra) # 8000335e <iget>
    800035c4:	bf5d                	j	8000357a <ialloc+0x80>

00000000800035c6 <iupdate>:
{
    800035c6:	1101                	add	sp,sp,-32
    800035c8:	ec06                	sd	ra,24(sp)
    800035ca:	e822                	sd	s0,16(sp)
    800035cc:	e426                	sd	s1,8(sp)
    800035ce:	e04a                	sd	s2,0(sp)
    800035d0:	1000                	add	s0,sp,32
    800035d2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035d4:	415c                	lw	a5,4(a0)
    800035d6:	0047d79b          	srlw	a5,a5,0x4
    800035da:	0001c597          	auipc	a1,0x1c
    800035de:	a865a583          	lw	a1,-1402(a1) # 8001f060 <sb+0x18>
    800035e2:	9dbd                	addw	a1,a1,a5
    800035e4:	4108                	lw	a0,0(a0)
    800035e6:	00000097          	auipc	ra,0x0
    800035ea:	89c080e7          	jalr	-1892(ra) # 80002e82 <bread>
    800035ee:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035f0:	05850793          	add	a5,a0,88
    800035f4:	40d8                	lw	a4,4(s1)
    800035f6:	8b3d                	and	a4,a4,15
    800035f8:	071a                	sll	a4,a4,0x6
    800035fa:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800035fc:	04449703          	lh	a4,68(s1)
    80003600:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003604:	04649703          	lh	a4,70(s1)
    80003608:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000360c:	04849703          	lh	a4,72(s1)
    80003610:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003614:	04a49703          	lh	a4,74(s1)
    80003618:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000361c:	44f8                	lw	a4,76(s1)
    8000361e:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003620:	03400613          	li	a2,52
    80003624:	05048593          	add	a1,s1,80
    80003628:	00c78513          	add	a0,a5,12
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	6fe080e7          	jalr	1790(ra) # 80000d2a <memmove>
  log_write(bp);
    80003634:	854a                	mv	a0,s2
    80003636:	00001097          	auipc	ra,0x1
    8000363a:	bd4080e7          	jalr	-1068(ra) # 8000420a <log_write>
  brelse(bp);
    8000363e:	854a                	mv	a0,s2
    80003640:	00000097          	auipc	ra,0x0
    80003644:	972080e7          	jalr	-1678(ra) # 80002fb2 <brelse>
}
    80003648:	60e2                	ld	ra,24(sp)
    8000364a:	6442                	ld	s0,16(sp)
    8000364c:	64a2                	ld	s1,8(sp)
    8000364e:	6902                	ld	s2,0(sp)
    80003650:	6105                	add	sp,sp,32
    80003652:	8082                	ret

0000000080003654 <idup>:
{
    80003654:	1101                	add	sp,sp,-32
    80003656:	ec06                	sd	ra,24(sp)
    80003658:	e822                	sd	s0,16(sp)
    8000365a:	e426                	sd	s1,8(sp)
    8000365c:	1000                	add	s0,sp,32
    8000365e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003660:	0001c517          	auipc	a0,0x1c
    80003664:	a0850513          	add	a0,a0,-1528 # 8001f068 <itable>
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	56a080e7          	jalr	1386(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003670:	449c                	lw	a5,8(s1)
    80003672:	2785                	addw	a5,a5,1
    80003674:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003676:	0001c517          	auipc	a0,0x1c
    8000367a:	9f250513          	add	a0,a0,-1550 # 8001f068 <itable>
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	608080e7          	jalr	1544(ra) # 80000c86 <release>
}
    80003686:	8526                	mv	a0,s1
    80003688:	60e2                	ld	ra,24(sp)
    8000368a:	6442                	ld	s0,16(sp)
    8000368c:	64a2                	ld	s1,8(sp)
    8000368e:	6105                	add	sp,sp,32
    80003690:	8082                	ret

0000000080003692 <ilock>:
{
    80003692:	1101                	add	sp,sp,-32
    80003694:	ec06                	sd	ra,24(sp)
    80003696:	e822                	sd	s0,16(sp)
    80003698:	e426                	sd	s1,8(sp)
    8000369a:	e04a                	sd	s2,0(sp)
    8000369c:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000369e:	c115                	beqz	a0,800036c2 <ilock+0x30>
    800036a0:	84aa                	mv	s1,a0
    800036a2:	451c                	lw	a5,8(a0)
    800036a4:	00f05f63          	blez	a5,800036c2 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036a8:	0541                	add	a0,a0,16
    800036aa:	00001097          	auipc	ra,0x1
    800036ae:	c7e080e7          	jalr	-898(ra) # 80004328 <acquiresleep>
  if(ip->valid == 0){
    800036b2:	40bc                	lw	a5,64(s1)
    800036b4:	cf99                	beqz	a5,800036d2 <ilock+0x40>
}
    800036b6:	60e2                	ld	ra,24(sp)
    800036b8:	6442                	ld	s0,16(sp)
    800036ba:	64a2                	ld	s1,8(sp)
    800036bc:	6902                	ld	s2,0(sp)
    800036be:	6105                	add	sp,sp,32
    800036c0:	8082                	ret
    panic("ilock");
    800036c2:	00005517          	auipc	a0,0x5
    800036c6:	f1650513          	add	a0,a0,-234 # 800085d8 <syscalls+0x188>
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	e72080e7          	jalr	-398(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036d2:	40dc                	lw	a5,4(s1)
    800036d4:	0047d79b          	srlw	a5,a5,0x4
    800036d8:	0001c597          	auipc	a1,0x1c
    800036dc:	9885a583          	lw	a1,-1656(a1) # 8001f060 <sb+0x18>
    800036e0:	9dbd                	addw	a1,a1,a5
    800036e2:	4088                	lw	a0,0(s1)
    800036e4:	fffff097          	auipc	ra,0xfffff
    800036e8:	79e080e7          	jalr	1950(ra) # 80002e82 <bread>
    800036ec:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036ee:	05850593          	add	a1,a0,88
    800036f2:	40dc                	lw	a5,4(s1)
    800036f4:	8bbd                	and	a5,a5,15
    800036f6:	079a                	sll	a5,a5,0x6
    800036f8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036fa:	00059783          	lh	a5,0(a1)
    800036fe:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003702:	00259783          	lh	a5,2(a1)
    80003706:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000370a:	00459783          	lh	a5,4(a1)
    8000370e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003712:	00659783          	lh	a5,6(a1)
    80003716:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000371a:	459c                	lw	a5,8(a1)
    8000371c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000371e:	03400613          	li	a2,52
    80003722:	05b1                	add	a1,a1,12
    80003724:	05048513          	add	a0,s1,80
    80003728:	ffffd097          	auipc	ra,0xffffd
    8000372c:	602080e7          	jalr	1538(ra) # 80000d2a <memmove>
    brelse(bp);
    80003730:	854a                	mv	a0,s2
    80003732:	00000097          	auipc	ra,0x0
    80003736:	880080e7          	jalr	-1920(ra) # 80002fb2 <brelse>
    ip->valid = 1;
    8000373a:	4785                	li	a5,1
    8000373c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000373e:	04449783          	lh	a5,68(s1)
    80003742:	fbb5                	bnez	a5,800036b6 <ilock+0x24>
      panic("ilock: no type");
    80003744:	00005517          	auipc	a0,0x5
    80003748:	e9c50513          	add	a0,a0,-356 # 800085e0 <syscalls+0x190>
    8000374c:	ffffd097          	auipc	ra,0xffffd
    80003750:	df0080e7          	jalr	-528(ra) # 8000053c <panic>

0000000080003754 <iunlock>:
{
    80003754:	1101                	add	sp,sp,-32
    80003756:	ec06                	sd	ra,24(sp)
    80003758:	e822                	sd	s0,16(sp)
    8000375a:	e426                	sd	s1,8(sp)
    8000375c:	e04a                	sd	s2,0(sp)
    8000375e:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003760:	c905                	beqz	a0,80003790 <iunlock+0x3c>
    80003762:	84aa                	mv	s1,a0
    80003764:	01050913          	add	s2,a0,16
    80003768:	854a                	mv	a0,s2
    8000376a:	00001097          	auipc	ra,0x1
    8000376e:	c58080e7          	jalr	-936(ra) # 800043c2 <holdingsleep>
    80003772:	cd19                	beqz	a0,80003790 <iunlock+0x3c>
    80003774:	449c                	lw	a5,8(s1)
    80003776:	00f05d63          	blez	a5,80003790 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000377a:	854a                	mv	a0,s2
    8000377c:	00001097          	auipc	ra,0x1
    80003780:	c02080e7          	jalr	-1022(ra) # 8000437e <releasesleep>
}
    80003784:	60e2                	ld	ra,24(sp)
    80003786:	6442                	ld	s0,16(sp)
    80003788:	64a2                	ld	s1,8(sp)
    8000378a:	6902                	ld	s2,0(sp)
    8000378c:	6105                	add	sp,sp,32
    8000378e:	8082                	ret
    panic("iunlock");
    80003790:	00005517          	auipc	a0,0x5
    80003794:	e6050513          	add	a0,a0,-416 # 800085f0 <syscalls+0x1a0>
    80003798:	ffffd097          	auipc	ra,0xffffd
    8000379c:	da4080e7          	jalr	-604(ra) # 8000053c <panic>

00000000800037a0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037a0:	7179                	add	sp,sp,-48
    800037a2:	f406                	sd	ra,40(sp)
    800037a4:	f022                	sd	s0,32(sp)
    800037a6:	ec26                	sd	s1,24(sp)
    800037a8:	e84a                	sd	s2,16(sp)
    800037aa:	e44e                	sd	s3,8(sp)
    800037ac:	e052                	sd	s4,0(sp)
    800037ae:	1800                	add	s0,sp,48
    800037b0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037b2:	05050493          	add	s1,a0,80
    800037b6:	08050913          	add	s2,a0,128
    800037ba:	a021                	j	800037c2 <itrunc+0x22>
    800037bc:	0491                	add	s1,s1,4
    800037be:	01248d63          	beq	s1,s2,800037d8 <itrunc+0x38>
    if(ip->addrs[i]){
    800037c2:	408c                	lw	a1,0(s1)
    800037c4:	dde5                	beqz	a1,800037bc <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037c6:	0009a503          	lw	a0,0(s3)
    800037ca:	00000097          	auipc	ra,0x0
    800037ce:	8fc080e7          	jalr	-1796(ra) # 800030c6 <bfree>
      ip->addrs[i] = 0;
    800037d2:	0004a023          	sw	zero,0(s1)
    800037d6:	b7dd                	j	800037bc <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037d8:	0809a583          	lw	a1,128(s3)
    800037dc:	e185                	bnez	a1,800037fc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037de:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037e2:	854e                	mv	a0,s3
    800037e4:	00000097          	auipc	ra,0x0
    800037e8:	de2080e7          	jalr	-542(ra) # 800035c6 <iupdate>
}
    800037ec:	70a2                	ld	ra,40(sp)
    800037ee:	7402                	ld	s0,32(sp)
    800037f0:	64e2                	ld	s1,24(sp)
    800037f2:	6942                	ld	s2,16(sp)
    800037f4:	69a2                	ld	s3,8(sp)
    800037f6:	6a02                	ld	s4,0(sp)
    800037f8:	6145                	add	sp,sp,48
    800037fa:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037fc:	0009a503          	lw	a0,0(s3)
    80003800:	fffff097          	auipc	ra,0xfffff
    80003804:	682080e7          	jalr	1666(ra) # 80002e82 <bread>
    80003808:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000380a:	05850493          	add	s1,a0,88
    8000380e:	45850913          	add	s2,a0,1112
    80003812:	a021                	j	8000381a <itrunc+0x7a>
    80003814:	0491                	add	s1,s1,4
    80003816:	01248b63          	beq	s1,s2,8000382c <itrunc+0x8c>
      if(a[j])
    8000381a:	408c                	lw	a1,0(s1)
    8000381c:	dde5                	beqz	a1,80003814 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000381e:	0009a503          	lw	a0,0(s3)
    80003822:	00000097          	auipc	ra,0x0
    80003826:	8a4080e7          	jalr	-1884(ra) # 800030c6 <bfree>
    8000382a:	b7ed                	j	80003814 <itrunc+0x74>
    brelse(bp);
    8000382c:	8552                	mv	a0,s4
    8000382e:	fffff097          	auipc	ra,0xfffff
    80003832:	784080e7          	jalr	1924(ra) # 80002fb2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003836:	0809a583          	lw	a1,128(s3)
    8000383a:	0009a503          	lw	a0,0(s3)
    8000383e:	00000097          	auipc	ra,0x0
    80003842:	888080e7          	jalr	-1912(ra) # 800030c6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003846:	0809a023          	sw	zero,128(s3)
    8000384a:	bf51                	j	800037de <itrunc+0x3e>

000000008000384c <iput>:
{
    8000384c:	1101                	add	sp,sp,-32
    8000384e:	ec06                	sd	ra,24(sp)
    80003850:	e822                	sd	s0,16(sp)
    80003852:	e426                	sd	s1,8(sp)
    80003854:	e04a                	sd	s2,0(sp)
    80003856:	1000                	add	s0,sp,32
    80003858:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000385a:	0001c517          	auipc	a0,0x1c
    8000385e:	80e50513          	add	a0,a0,-2034 # 8001f068 <itable>
    80003862:	ffffd097          	auipc	ra,0xffffd
    80003866:	370080e7          	jalr	880(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000386a:	4498                	lw	a4,8(s1)
    8000386c:	4785                	li	a5,1
    8000386e:	02f70363          	beq	a4,a5,80003894 <iput+0x48>
  ip->ref--;
    80003872:	449c                	lw	a5,8(s1)
    80003874:	37fd                	addw	a5,a5,-1
    80003876:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003878:	0001b517          	auipc	a0,0x1b
    8000387c:	7f050513          	add	a0,a0,2032 # 8001f068 <itable>
    80003880:	ffffd097          	auipc	ra,0xffffd
    80003884:	406080e7          	jalr	1030(ra) # 80000c86 <release>
}
    80003888:	60e2                	ld	ra,24(sp)
    8000388a:	6442                	ld	s0,16(sp)
    8000388c:	64a2                	ld	s1,8(sp)
    8000388e:	6902                	ld	s2,0(sp)
    80003890:	6105                	add	sp,sp,32
    80003892:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003894:	40bc                	lw	a5,64(s1)
    80003896:	dff1                	beqz	a5,80003872 <iput+0x26>
    80003898:	04a49783          	lh	a5,74(s1)
    8000389c:	fbf9                	bnez	a5,80003872 <iput+0x26>
    acquiresleep(&ip->lock);
    8000389e:	01048913          	add	s2,s1,16
    800038a2:	854a                	mv	a0,s2
    800038a4:	00001097          	auipc	ra,0x1
    800038a8:	a84080e7          	jalr	-1404(ra) # 80004328 <acquiresleep>
    release(&itable.lock);
    800038ac:	0001b517          	auipc	a0,0x1b
    800038b0:	7bc50513          	add	a0,a0,1980 # 8001f068 <itable>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	3d2080e7          	jalr	978(ra) # 80000c86 <release>
    itrunc(ip);
    800038bc:	8526                	mv	a0,s1
    800038be:	00000097          	auipc	ra,0x0
    800038c2:	ee2080e7          	jalr	-286(ra) # 800037a0 <itrunc>
    ip->type = 0;
    800038c6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038ca:	8526                	mv	a0,s1
    800038cc:	00000097          	auipc	ra,0x0
    800038d0:	cfa080e7          	jalr	-774(ra) # 800035c6 <iupdate>
    ip->valid = 0;
    800038d4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038d8:	854a                	mv	a0,s2
    800038da:	00001097          	auipc	ra,0x1
    800038de:	aa4080e7          	jalr	-1372(ra) # 8000437e <releasesleep>
    acquire(&itable.lock);
    800038e2:	0001b517          	auipc	a0,0x1b
    800038e6:	78650513          	add	a0,a0,1926 # 8001f068 <itable>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	2e8080e7          	jalr	744(ra) # 80000bd2 <acquire>
    800038f2:	b741                	j	80003872 <iput+0x26>

00000000800038f4 <iunlockput>:
{
    800038f4:	1101                	add	sp,sp,-32
    800038f6:	ec06                	sd	ra,24(sp)
    800038f8:	e822                	sd	s0,16(sp)
    800038fa:	e426                	sd	s1,8(sp)
    800038fc:	1000                	add	s0,sp,32
    800038fe:	84aa                	mv	s1,a0
  iunlock(ip);
    80003900:	00000097          	auipc	ra,0x0
    80003904:	e54080e7          	jalr	-428(ra) # 80003754 <iunlock>
  iput(ip);
    80003908:	8526                	mv	a0,s1
    8000390a:	00000097          	auipc	ra,0x0
    8000390e:	f42080e7          	jalr	-190(ra) # 8000384c <iput>
}
    80003912:	60e2                	ld	ra,24(sp)
    80003914:	6442                	ld	s0,16(sp)
    80003916:	64a2                	ld	s1,8(sp)
    80003918:	6105                	add	sp,sp,32
    8000391a:	8082                	ret

000000008000391c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000391c:	1141                	add	sp,sp,-16
    8000391e:	e422                	sd	s0,8(sp)
    80003920:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003922:	411c                	lw	a5,0(a0)
    80003924:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003926:	415c                	lw	a5,4(a0)
    80003928:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000392a:	04451783          	lh	a5,68(a0)
    8000392e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003932:	04a51783          	lh	a5,74(a0)
    80003936:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000393a:	04c56783          	lwu	a5,76(a0)
    8000393e:	e99c                	sd	a5,16(a1)
}
    80003940:	6422                	ld	s0,8(sp)
    80003942:	0141                	add	sp,sp,16
    80003944:	8082                	ret

0000000080003946 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003946:	457c                	lw	a5,76(a0)
    80003948:	0ed7e963          	bltu	a5,a3,80003a3a <readi+0xf4>
{
    8000394c:	7159                	add	sp,sp,-112
    8000394e:	f486                	sd	ra,104(sp)
    80003950:	f0a2                	sd	s0,96(sp)
    80003952:	eca6                	sd	s1,88(sp)
    80003954:	e8ca                	sd	s2,80(sp)
    80003956:	e4ce                	sd	s3,72(sp)
    80003958:	e0d2                	sd	s4,64(sp)
    8000395a:	fc56                	sd	s5,56(sp)
    8000395c:	f85a                	sd	s6,48(sp)
    8000395e:	f45e                	sd	s7,40(sp)
    80003960:	f062                	sd	s8,32(sp)
    80003962:	ec66                	sd	s9,24(sp)
    80003964:	e86a                	sd	s10,16(sp)
    80003966:	e46e                	sd	s11,8(sp)
    80003968:	1880                	add	s0,sp,112
    8000396a:	8b2a                	mv	s6,a0
    8000396c:	8bae                	mv	s7,a1
    8000396e:	8a32                	mv	s4,a2
    80003970:	84b6                	mv	s1,a3
    80003972:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003974:	9f35                	addw	a4,a4,a3
    return 0;
    80003976:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003978:	0ad76063          	bltu	a4,a3,80003a18 <readi+0xd2>
  if(off + n > ip->size)
    8000397c:	00e7f463          	bgeu	a5,a4,80003984 <readi+0x3e>
    n = ip->size - off;
    80003980:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003984:	0a0a8963          	beqz	s5,80003a36 <readi+0xf0>
    80003988:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000398a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000398e:	5c7d                	li	s8,-1
    80003990:	a82d                	j	800039ca <readi+0x84>
    80003992:	020d1d93          	sll	s11,s10,0x20
    80003996:	020ddd93          	srl	s11,s11,0x20
    8000399a:	05890613          	add	a2,s2,88
    8000399e:	86ee                	mv	a3,s11
    800039a0:	963a                	add	a2,a2,a4
    800039a2:	85d2                	mv	a1,s4
    800039a4:	855e                	mv	a0,s7
    800039a6:	fffff097          	auipc	ra,0xfffff
    800039aa:	af6080e7          	jalr	-1290(ra) # 8000249c <either_copyout>
    800039ae:	05850d63          	beq	a0,s8,80003a08 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800039b2:	854a                	mv	a0,s2
    800039b4:	fffff097          	auipc	ra,0xfffff
    800039b8:	5fe080e7          	jalr	1534(ra) # 80002fb2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039bc:	013d09bb          	addw	s3,s10,s3
    800039c0:	009d04bb          	addw	s1,s10,s1
    800039c4:	9a6e                	add	s4,s4,s11
    800039c6:	0559f763          	bgeu	s3,s5,80003a14 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800039ca:	00a4d59b          	srlw	a1,s1,0xa
    800039ce:	855a                	mv	a0,s6
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	8a4080e7          	jalr	-1884(ra) # 80003274 <bmap>
    800039d8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800039dc:	cd85                	beqz	a1,80003a14 <readi+0xce>
    bp = bread(ip->dev, addr);
    800039de:	000b2503          	lw	a0,0(s6)
    800039e2:	fffff097          	auipc	ra,0xfffff
    800039e6:	4a0080e7          	jalr	1184(ra) # 80002e82 <bread>
    800039ea:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039ec:	3ff4f713          	and	a4,s1,1023
    800039f0:	40ec87bb          	subw	a5,s9,a4
    800039f4:	413a86bb          	subw	a3,s5,s3
    800039f8:	8d3e                	mv	s10,a5
    800039fa:	2781                	sext.w	a5,a5
    800039fc:	0006861b          	sext.w	a2,a3
    80003a00:	f8f679e3          	bgeu	a2,a5,80003992 <readi+0x4c>
    80003a04:	8d36                	mv	s10,a3
    80003a06:	b771                	j	80003992 <readi+0x4c>
      brelse(bp);
    80003a08:	854a                	mv	a0,s2
    80003a0a:	fffff097          	auipc	ra,0xfffff
    80003a0e:	5a8080e7          	jalr	1448(ra) # 80002fb2 <brelse>
      tot = -1;
    80003a12:	59fd                	li	s3,-1
  }
  return tot;
    80003a14:	0009851b          	sext.w	a0,s3
}
    80003a18:	70a6                	ld	ra,104(sp)
    80003a1a:	7406                	ld	s0,96(sp)
    80003a1c:	64e6                	ld	s1,88(sp)
    80003a1e:	6946                	ld	s2,80(sp)
    80003a20:	69a6                	ld	s3,72(sp)
    80003a22:	6a06                	ld	s4,64(sp)
    80003a24:	7ae2                	ld	s5,56(sp)
    80003a26:	7b42                	ld	s6,48(sp)
    80003a28:	7ba2                	ld	s7,40(sp)
    80003a2a:	7c02                	ld	s8,32(sp)
    80003a2c:	6ce2                	ld	s9,24(sp)
    80003a2e:	6d42                	ld	s10,16(sp)
    80003a30:	6da2                	ld	s11,8(sp)
    80003a32:	6165                	add	sp,sp,112
    80003a34:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a36:	89d6                	mv	s3,s5
    80003a38:	bff1                	j	80003a14 <readi+0xce>
    return 0;
    80003a3a:	4501                	li	a0,0
}
    80003a3c:	8082                	ret

0000000080003a3e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a3e:	457c                	lw	a5,76(a0)
    80003a40:	10d7e863          	bltu	a5,a3,80003b50 <writei+0x112>
{
    80003a44:	7159                	add	sp,sp,-112
    80003a46:	f486                	sd	ra,104(sp)
    80003a48:	f0a2                	sd	s0,96(sp)
    80003a4a:	eca6                	sd	s1,88(sp)
    80003a4c:	e8ca                	sd	s2,80(sp)
    80003a4e:	e4ce                	sd	s3,72(sp)
    80003a50:	e0d2                	sd	s4,64(sp)
    80003a52:	fc56                	sd	s5,56(sp)
    80003a54:	f85a                	sd	s6,48(sp)
    80003a56:	f45e                	sd	s7,40(sp)
    80003a58:	f062                	sd	s8,32(sp)
    80003a5a:	ec66                	sd	s9,24(sp)
    80003a5c:	e86a                	sd	s10,16(sp)
    80003a5e:	e46e                	sd	s11,8(sp)
    80003a60:	1880                	add	s0,sp,112
    80003a62:	8aaa                	mv	s5,a0
    80003a64:	8bae                	mv	s7,a1
    80003a66:	8a32                	mv	s4,a2
    80003a68:	8936                	mv	s2,a3
    80003a6a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a6c:	00e687bb          	addw	a5,a3,a4
    80003a70:	0ed7e263          	bltu	a5,a3,80003b54 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a74:	00043737          	lui	a4,0x43
    80003a78:	0ef76063          	bltu	a4,a5,80003b58 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a7c:	0c0b0863          	beqz	s6,80003b4c <writei+0x10e>
    80003a80:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a82:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a86:	5c7d                	li	s8,-1
    80003a88:	a091                	j	80003acc <writei+0x8e>
    80003a8a:	020d1d93          	sll	s11,s10,0x20
    80003a8e:	020ddd93          	srl	s11,s11,0x20
    80003a92:	05848513          	add	a0,s1,88
    80003a96:	86ee                	mv	a3,s11
    80003a98:	8652                	mv	a2,s4
    80003a9a:	85de                	mv	a1,s7
    80003a9c:	953a                	add	a0,a0,a4
    80003a9e:	fffff097          	auipc	ra,0xfffff
    80003aa2:	a54080e7          	jalr	-1452(ra) # 800024f2 <either_copyin>
    80003aa6:	07850263          	beq	a0,s8,80003b0a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003aaa:	8526                	mv	a0,s1
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	75e080e7          	jalr	1886(ra) # 8000420a <log_write>
    brelse(bp);
    80003ab4:	8526                	mv	a0,s1
    80003ab6:	fffff097          	auipc	ra,0xfffff
    80003aba:	4fc080e7          	jalr	1276(ra) # 80002fb2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003abe:	013d09bb          	addw	s3,s10,s3
    80003ac2:	012d093b          	addw	s2,s10,s2
    80003ac6:	9a6e                	add	s4,s4,s11
    80003ac8:	0569f663          	bgeu	s3,s6,80003b14 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003acc:	00a9559b          	srlw	a1,s2,0xa
    80003ad0:	8556                	mv	a0,s5
    80003ad2:	fffff097          	auipc	ra,0xfffff
    80003ad6:	7a2080e7          	jalr	1954(ra) # 80003274 <bmap>
    80003ada:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ade:	c99d                	beqz	a1,80003b14 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003ae0:	000aa503          	lw	a0,0(s5)
    80003ae4:	fffff097          	auipc	ra,0xfffff
    80003ae8:	39e080e7          	jalr	926(ra) # 80002e82 <bread>
    80003aec:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aee:	3ff97713          	and	a4,s2,1023
    80003af2:	40ec87bb          	subw	a5,s9,a4
    80003af6:	413b06bb          	subw	a3,s6,s3
    80003afa:	8d3e                	mv	s10,a5
    80003afc:	2781                	sext.w	a5,a5
    80003afe:	0006861b          	sext.w	a2,a3
    80003b02:	f8f674e3          	bgeu	a2,a5,80003a8a <writei+0x4c>
    80003b06:	8d36                	mv	s10,a3
    80003b08:	b749                	j	80003a8a <writei+0x4c>
      brelse(bp);
    80003b0a:	8526                	mv	a0,s1
    80003b0c:	fffff097          	auipc	ra,0xfffff
    80003b10:	4a6080e7          	jalr	1190(ra) # 80002fb2 <brelse>
  }

  if(off > ip->size)
    80003b14:	04caa783          	lw	a5,76(s5)
    80003b18:	0127f463          	bgeu	a5,s2,80003b20 <writei+0xe2>
    ip->size = off;
    80003b1c:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b20:	8556                	mv	a0,s5
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	aa4080e7          	jalr	-1372(ra) # 800035c6 <iupdate>

  return tot;
    80003b2a:	0009851b          	sext.w	a0,s3
}
    80003b2e:	70a6                	ld	ra,104(sp)
    80003b30:	7406                	ld	s0,96(sp)
    80003b32:	64e6                	ld	s1,88(sp)
    80003b34:	6946                	ld	s2,80(sp)
    80003b36:	69a6                	ld	s3,72(sp)
    80003b38:	6a06                	ld	s4,64(sp)
    80003b3a:	7ae2                	ld	s5,56(sp)
    80003b3c:	7b42                	ld	s6,48(sp)
    80003b3e:	7ba2                	ld	s7,40(sp)
    80003b40:	7c02                	ld	s8,32(sp)
    80003b42:	6ce2                	ld	s9,24(sp)
    80003b44:	6d42                	ld	s10,16(sp)
    80003b46:	6da2                	ld	s11,8(sp)
    80003b48:	6165                	add	sp,sp,112
    80003b4a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b4c:	89da                	mv	s3,s6
    80003b4e:	bfc9                	j	80003b20 <writei+0xe2>
    return -1;
    80003b50:	557d                	li	a0,-1
}
    80003b52:	8082                	ret
    return -1;
    80003b54:	557d                	li	a0,-1
    80003b56:	bfe1                	j	80003b2e <writei+0xf0>
    return -1;
    80003b58:	557d                	li	a0,-1
    80003b5a:	bfd1                	j	80003b2e <writei+0xf0>

0000000080003b5c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b5c:	1141                	add	sp,sp,-16
    80003b5e:	e406                	sd	ra,8(sp)
    80003b60:	e022                	sd	s0,0(sp)
    80003b62:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b64:	4639                	li	a2,14
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	238080e7          	jalr	568(ra) # 80000d9e <strncmp>
}
    80003b6e:	60a2                	ld	ra,8(sp)
    80003b70:	6402                	ld	s0,0(sp)
    80003b72:	0141                	add	sp,sp,16
    80003b74:	8082                	ret

0000000080003b76 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b76:	7139                	add	sp,sp,-64
    80003b78:	fc06                	sd	ra,56(sp)
    80003b7a:	f822                	sd	s0,48(sp)
    80003b7c:	f426                	sd	s1,40(sp)
    80003b7e:	f04a                	sd	s2,32(sp)
    80003b80:	ec4e                	sd	s3,24(sp)
    80003b82:	e852                	sd	s4,16(sp)
    80003b84:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b86:	04451703          	lh	a4,68(a0)
    80003b8a:	4785                	li	a5,1
    80003b8c:	00f71a63          	bne	a4,a5,80003ba0 <dirlookup+0x2a>
    80003b90:	892a                	mv	s2,a0
    80003b92:	89ae                	mv	s3,a1
    80003b94:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b96:	457c                	lw	a5,76(a0)
    80003b98:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b9a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b9c:	e79d                	bnez	a5,80003bca <dirlookup+0x54>
    80003b9e:	a8a5                	j	80003c16 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ba0:	00005517          	auipc	a0,0x5
    80003ba4:	a5850513          	add	a0,a0,-1448 # 800085f8 <syscalls+0x1a8>
    80003ba8:	ffffd097          	auipc	ra,0xffffd
    80003bac:	994080e7          	jalr	-1644(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003bb0:	00005517          	auipc	a0,0x5
    80003bb4:	a6050513          	add	a0,a0,-1440 # 80008610 <syscalls+0x1c0>
    80003bb8:	ffffd097          	auipc	ra,0xffffd
    80003bbc:	984080e7          	jalr	-1660(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bc0:	24c1                	addw	s1,s1,16
    80003bc2:	04c92783          	lw	a5,76(s2)
    80003bc6:	04f4f763          	bgeu	s1,a5,80003c14 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bca:	4741                	li	a4,16
    80003bcc:	86a6                	mv	a3,s1
    80003bce:	fc040613          	add	a2,s0,-64
    80003bd2:	4581                	li	a1,0
    80003bd4:	854a                	mv	a0,s2
    80003bd6:	00000097          	auipc	ra,0x0
    80003bda:	d70080e7          	jalr	-656(ra) # 80003946 <readi>
    80003bde:	47c1                	li	a5,16
    80003be0:	fcf518e3          	bne	a0,a5,80003bb0 <dirlookup+0x3a>
    if(de.inum == 0)
    80003be4:	fc045783          	lhu	a5,-64(s0)
    80003be8:	dfe1                	beqz	a5,80003bc0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003bea:	fc240593          	add	a1,s0,-62
    80003bee:	854e                	mv	a0,s3
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	f6c080e7          	jalr	-148(ra) # 80003b5c <namecmp>
    80003bf8:	f561                	bnez	a0,80003bc0 <dirlookup+0x4a>
      if(poff)
    80003bfa:	000a0463          	beqz	s4,80003c02 <dirlookup+0x8c>
        *poff = off;
    80003bfe:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c02:	fc045583          	lhu	a1,-64(s0)
    80003c06:	00092503          	lw	a0,0(s2)
    80003c0a:	fffff097          	auipc	ra,0xfffff
    80003c0e:	754080e7          	jalr	1876(ra) # 8000335e <iget>
    80003c12:	a011                	j	80003c16 <dirlookup+0xa0>
  return 0;
    80003c14:	4501                	li	a0,0
}
    80003c16:	70e2                	ld	ra,56(sp)
    80003c18:	7442                	ld	s0,48(sp)
    80003c1a:	74a2                	ld	s1,40(sp)
    80003c1c:	7902                	ld	s2,32(sp)
    80003c1e:	69e2                	ld	s3,24(sp)
    80003c20:	6a42                	ld	s4,16(sp)
    80003c22:	6121                	add	sp,sp,64
    80003c24:	8082                	ret

0000000080003c26 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c26:	711d                	add	sp,sp,-96
    80003c28:	ec86                	sd	ra,88(sp)
    80003c2a:	e8a2                	sd	s0,80(sp)
    80003c2c:	e4a6                	sd	s1,72(sp)
    80003c2e:	e0ca                	sd	s2,64(sp)
    80003c30:	fc4e                	sd	s3,56(sp)
    80003c32:	f852                	sd	s4,48(sp)
    80003c34:	f456                	sd	s5,40(sp)
    80003c36:	f05a                	sd	s6,32(sp)
    80003c38:	ec5e                	sd	s7,24(sp)
    80003c3a:	e862                	sd	s8,16(sp)
    80003c3c:	e466                	sd	s9,8(sp)
    80003c3e:	1080                	add	s0,sp,96
    80003c40:	84aa                	mv	s1,a0
    80003c42:	8b2e                	mv	s6,a1
    80003c44:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c46:	00054703          	lbu	a4,0(a0)
    80003c4a:	02f00793          	li	a5,47
    80003c4e:	02f70263          	beq	a4,a5,80003c72 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c52:	ffffe097          	auipc	ra,0xffffe
    80003c56:	d54080e7          	jalr	-684(ra) # 800019a6 <myproc>
    80003c5a:	15053503          	ld	a0,336(a0)
    80003c5e:	00000097          	auipc	ra,0x0
    80003c62:	9f6080e7          	jalr	-1546(ra) # 80003654 <idup>
    80003c66:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003c68:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003c6c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c6e:	4b85                	li	s7,1
    80003c70:	a875                	j	80003d2c <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003c72:	4585                	li	a1,1
    80003c74:	4505                	li	a0,1
    80003c76:	fffff097          	auipc	ra,0xfffff
    80003c7a:	6e8080e7          	jalr	1768(ra) # 8000335e <iget>
    80003c7e:	8a2a                	mv	s4,a0
    80003c80:	b7e5                	j	80003c68 <namex+0x42>
      iunlockput(ip);
    80003c82:	8552                	mv	a0,s4
    80003c84:	00000097          	auipc	ra,0x0
    80003c88:	c70080e7          	jalr	-912(ra) # 800038f4 <iunlockput>
      return 0;
    80003c8c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c8e:	8552                	mv	a0,s4
    80003c90:	60e6                	ld	ra,88(sp)
    80003c92:	6446                	ld	s0,80(sp)
    80003c94:	64a6                	ld	s1,72(sp)
    80003c96:	6906                	ld	s2,64(sp)
    80003c98:	79e2                	ld	s3,56(sp)
    80003c9a:	7a42                	ld	s4,48(sp)
    80003c9c:	7aa2                	ld	s5,40(sp)
    80003c9e:	7b02                	ld	s6,32(sp)
    80003ca0:	6be2                	ld	s7,24(sp)
    80003ca2:	6c42                	ld	s8,16(sp)
    80003ca4:	6ca2                	ld	s9,8(sp)
    80003ca6:	6125                	add	sp,sp,96
    80003ca8:	8082                	ret
      iunlock(ip);
    80003caa:	8552                	mv	a0,s4
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	aa8080e7          	jalr	-1368(ra) # 80003754 <iunlock>
      return ip;
    80003cb4:	bfe9                	j	80003c8e <namex+0x68>
      iunlockput(ip);
    80003cb6:	8552                	mv	a0,s4
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	c3c080e7          	jalr	-964(ra) # 800038f4 <iunlockput>
      return 0;
    80003cc0:	8a4e                	mv	s4,s3
    80003cc2:	b7f1                	j	80003c8e <namex+0x68>
  len = path - s;
    80003cc4:	40998633          	sub	a2,s3,s1
    80003cc8:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003ccc:	099c5863          	bge	s8,s9,80003d5c <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003cd0:	4639                	li	a2,14
    80003cd2:	85a6                	mv	a1,s1
    80003cd4:	8556                	mv	a0,s5
    80003cd6:	ffffd097          	auipc	ra,0xffffd
    80003cda:	054080e7          	jalr	84(ra) # 80000d2a <memmove>
    80003cde:	84ce                	mv	s1,s3
  while(*path == '/')
    80003ce0:	0004c783          	lbu	a5,0(s1)
    80003ce4:	01279763          	bne	a5,s2,80003cf2 <namex+0xcc>
    path++;
    80003ce8:	0485                	add	s1,s1,1
  while(*path == '/')
    80003cea:	0004c783          	lbu	a5,0(s1)
    80003cee:	ff278de3          	beq	a5,s2,80003ce8 <namex+0xc2>
    ilock(ip);
    80003cf2:	8552                	mv	a0,s4
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	99e080e7          	jalr	-1634(ra) # 80003692 <ilock>
    if(ip->type != T_DIR){
    80003cfc:	044a1783          	lh	a5,68(s4)
    80003d00:	f97791e3          	bne	a5,s7,80003c82 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003d04:	000b0563          	beqz	s6,80003d0e <namex+0xe8>
    80003d08:	0004c783          	lbu	a5,0(s1)
    80003d0c:	dfd9                	beqz	a5,80003caa <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d0e:	4601                	li	a2,0
    80003d10:	85d6                	mv	a1,s5
    80003d12:	8552                	mv	a0,s4
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	e62080e7          	jalr	-414(ra) # 80003b76 <dirlookup>
    80003d1c:	89aa                	mv	s3,a0
    80003d1e:	dd41                	beqz	a0,80003cb6 <namex+0x90>
    iunlockput(ip);
    80003d20:	8552                	mv	a0,s4
    80003d22:	00000097          	auipc	ra,0x0
    80003d26:	bd2080e7          	jalr	-1070(ra) # 800038f4 <iunlockput>
    ip = next;
    80003d2a:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003d2c:	0004c783          	lbu	a5,0(s1)
    80003d30:	01279763          	bne	a5,s2,80003d3e <namex+0x118>
    path++;
    80003d34:	0485                	add	s1,s1,1
  while(*path == '/')
    80003d36:	0004c783          	lbu	a5,0(s1)
    80003d3a:	ff278de3          	beq	a5,s2,80003d34 <namex+0x10e>
  if(*path == 0)
    80003d3e:	cb9d                	beqz	a5,80003d74 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003d40:	0004c783          	lbu	a5,0(s1)
    80003d44:	89a6                	mv	s3,s1
  len = path - s;
    80003d46:	4c81                	li	s9,0
    80003d48:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003d4a:	01278963          	beq	a5,s2,80003d5c <namex+0x136>
    80003d4e:	dbbd                	beqz	a5,80003cc4 <namex+0x9e>
    path++;
    80003d50:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80003d52:	0009c783          	lbu	a5,0(s3)
    80003d56:	ff279ce3          	bne	a5,s2,80003d4e <namex+0x128>
    80003d5a:	b7ad                	j	80003cc4 <namex+0x9e>
    memmove(name, s, len);
    80003d5c:	2601                	sext.w	a2,a2
    80003d5e:	85a6                	mv	a1,s1
    80003d60:	8556                	mv	a0,s5
    80003d62:	ffffd097          	auipc	ra,0xffffd
    80003d66:	fc8080e7          	jalr	-56(ra) # 80000d2a <memmove>
    name[len] = 0;
    80003d6a:	9cd6                	add	s9,s9,s5
    80003d6c:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003d70:	84ce                	mv	s1,s3
    80003d72:	b7bd                	j	80003ce0 <namex+0xba>
  if(nameiparent){
    80003d74:	f00b0de3          	beqz	s6,80003c8e <namex+0x68>
    iput(ip);
    80003d78:	8552                	mv	a0,s4
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	ad2080e7          	jalr	-1326(ra) # 8000384c <iput>
    return 0;
    80003d82:	4a01                	li	s4,0
    80003d84:	b729                	j	80003c8e <namex+0x68>

0000000080003d86 <dirlink>:
{
    80003d86:	7139                	add	sp,sp,-64
    80003d88:	fc06                	sd	ra,56(sp)
    80003d8a:	f822                	sd	s0,48(sp)
    80003d8c:	f426                	sd	s1,40(sp)
    80003d8e:	f04a                	sd	s2,32(sp)
    80003d90:	ec4e                	sd	s3,24(sp)
    80003d92:	e852                	sd	s4,16(sp)
    80003d94:	0080                	add	s0,sp,64
    80003d96:	892a                	mv	s2,a0
    80003d98:	8a2e                	mv	s4,a1
    80003d9a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d9c:	4601                	li	a2,0
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	dd8080e7          	jalr	-552(ra) # 80003b76 <dirlookup>
    80003da6:	e93d                	bnez	a0,80003e1c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003da8:	04c92483          	lw	s1,76(s2)
    80003dac:	c49d                	beqz	s1,80003dda <dirlink+0x54>
    80003dae:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003db0:	4741                	li	a4,16
    80003db2:	86a6                	mv	a3,s1
    80003db4:	fc040613          	add	a2,s0,-64
    80003db8:	4581                	li	a1,0
    80003dba:	854a                	mv	a0,s2
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	b8a080e7          	jalr	-1142(ra) # 80003946 <readi>
    80003dc4:	47c1                	li	a5,16
    80003dc6:	06f51163          	bne	a0,a5,80003e28 <dirlink+0xa2>
    if(de.inum == 0)
    80003dca:	fc045783          	lhu	a5,-64(s0)
    80003dce:	c791                	beqz	a5,80003dda <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd0:	24c1                	addw	s1,s1,16
    80003dd2:	04c92783          	lw	a5,76(s2)
    80003dd6:	fcf4ede3          	bltu	s1,a5,80003db0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003dda:	4639                	li	a2,14
    80003ddc:	85d2                	mv	a1,s4
    80003dde:	fc240513          	add	a0,s0,-62
    80003de2:	ffffd097          	auipc	ra,0xffffd
    80003de6:	ff8080e7          	jalr	-8(ra) # 80000dda <strncpy>
  de.inum = inum;
    80003dea:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dee:	4741                	li	a4,16
    80003df0:	86a6                	mv	a3,s1
    80003df2:	fc040613          	add	a2,s0,-64
    80003df6:	4581                	li	a1,0
    80003df8:	854a                	mv	a0,s2
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	c44080e7          	jalr	-956(ra) # 80003a3e <writei>
    80003e02:	1541                	add	a0,a0,-16
    80003e04:	00a03533          	snez	a0,a0
    80003e08:	40a00533          	neg	a0,a0
}
    80003e0c:	70e2                	ld	ra,56(sp)
    80003e0e:	7442                	ld	s0,48(sp)
    80003e10:	74a2                	ld	s1,40(sp)
    80003e12:	7902                	ld	s2,32(sp)
    80003e14:	69e2                	ld	s3,24(sp)
    80003e16:	6a42                	ld	s4,16(sp)
    80003e18:	6121                	add	sp,sp,64
    80003e1a:	8082                	ret
    iput(ip);
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	a30080e7          	jalr	-1488(ra) # 8000384c <iput>
    return -1;
    80003e24:	557d                	li	a0,-1
    80003e26:	b7dd                	j	80003e0c <dirlink+0x86>
      panic("dirlink read");
    80003e28:	00004517          	auipc	a0,0x4
    80003e2c:	7f850513          	add	a0,a0,2040 # 80008620 <syscalls+0x1d0>
    80003e30:	ffffc097          	auipc	ra,0xffffc
    80003e34:	70c080e7          	jalr	1804(ra) # 8000053c <panic>

0000000080003e38 <namei>:

struct inode*
namei(char *path)
{
    80003e38:	1101                	add	sp,sp,-32
    80003e3a:	ec06                	sd	ra,24(sp)
    80003e3c:	e822                	sd	s0,16(sp)
    80003e3e:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e40:	fe040613          	add	a2,s0,-32
    80003e44:	4581                	li	a1,0
    80003e46:	00000097          	auipc	ra,0x0
    80003e4a:	de0080e7          	jalr	-544(ra) # 80003c26 <namex>
}
    80003e4e:	60e2                	ld	ra,24(sp)
    80003e50:	6442                	ld	s0,16(sp)
    80003e52:	6105                	add	sp,sp,32
    80003e54:	8082                	ret

0000000080003e56 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e56:	1141                	add	sp,sp,-16
    80003e58:	e406                	sd	ra,8(sp)
    80003e5a:	e022                	sd	s0,0(sp)
    80003e5c:	0800                	add	s0,sp,16
    80003e5e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e60:	4585                	li	a1,1
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	dc4080e7          	jalr	-572(ra) # 80003c26 <namex>
}
    80003e6a:	60a2                	ld	ra,8(sp)
    80003e6c:	6402                	ld	s0,0(sp)
    80003e6e:	0141                	add	sp,sp,16
    80003e70:	8082                	ret

0000000080003e72 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e72:	1101                	add	sp,sp,-32
    80003e74:	ec06                	sd	ra,24(sp)
    80003e76:	e822                	sd	s0,16(sp)
    80003e78:	e426                	sd	s1,8(sp)
    80003e7a:	e04a                	sd	s2,0(sp)
    80003e7c:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e7e:	0001d917          	auipc	s2,0x1d
    80003e82:	c9290913          	add	s2,s2,-878 # 80020b10 <log>
    80003e86:	01892583          	lw	a1,24(s2)
    80003e8a:	02892503          	lw	a0,40(s2)
    80003e8e:	fffff097          	auipc	ra,0xfffff
    80003e92:	ff4080e7          	jalr	-12(ra) # 80002e82 <bread>
    80003e96:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e98:	02c92603          	lw	a2,44(s2)
    80003e9c:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e9e:	00c05f63          	blez	a2,80003ebc <write_head+0x4a>
    80003ea2:	0001d717          	auipc	a4,0x1d
    80003ea6:	c9e70713          	add	a4,a4,-866 # 80020b40 <log+0x30>
    80003eaa:	87aa                	mv	a5,a0
    80003eac:	060a                	sll	a2,a2,0x2
    80003eae:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003eb0:	4314                	lw	a3,0(a4)
    80003eb2:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003eb4:	0711                	add	a4,a4,4
    80003eb6:	0791                	add	a5,a5,4
    80003eb8:	fec79ce3          	bne	a5,a2,80003eb0 <write_head+0x3e>
  }
  bwrite(buf);
    80003ebc:	8526                	mv	a0,s1
    80003ebe:	fffff097          	auipc	ra,0xfffff
    80003ec2:	0b6080e7          	jalr	182(ra) # 80002f74 <bwrite>
  brelse(buf);
    80003ec6:	8526                	mv	a0,s1
    80003ec8:	fffff097          	auipc	ra,0xfffff
    80003ecc:	0ea080e7          	jalr	234(ra) # 80002fb2 <brelse>
}
    80003ed0:	60e2                	ld	ra,24(sp)
    80003ed2:	6442                	ld	s0,16(sp)
    80003ed4:	64a2                	ld	s1,8(sp)
    80003ed6:	6902                	ld	s2,0(sp)
    80003ed8:	6105                	add	sp,sp,32
    80003eda:	8082                	ret

0000000080003edc <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003edc:	0001d797          	auipc	a5,0x1d
    80003ee0:	c607a783          	lw	a5,-928(a5) # 80020b3c <log+0x2c>
    80003ee4:	0af05d63          	blez	a5,80003f9e <install_trans+0xc2>
{
    80003ee8:	7139                	add	sp,sp,-64
    80003eea:	fc06                	sd	ra,56(sp)
    80003eec:	f822                	sd	s0,48(sp)
    80003eee:	f426                	sd	s1,40(sp)
    80003ef0:	f04a                	sd	s2,32(sp)
    80003ef2:	ec4e                	sd	s3,24(sp)
    80003ef4:	e852                	sd	s4,16(sp)
    80003ef6:	e456                	sd	s5,8(sp)
    80003ef8:	e05a                	sd	s6,0(sp)
    80003efa:	0080                	add	s0,sp,64
    80003efc:	8b2a                	mv	s6,a0
    80003efe:	0001da97          	auipc	s5,0x1d
    80003f02:	c42a8a93          	add	s5,s5,-958 # 80020b40 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f06:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f08:	0001d997          	auipc	s3,0x1d
    80003f0c:	c0898993          	add	s3,s3,-1016 # 80020b10 <log>
    80003f10:	a00d                	j	80003f32 <install_trans+0x56>
    brelse(lbuf);
    80003f12:	854a                	mv	a0,s2
    80003f14:	fffff097          	auipc	ra,0xfffff
    80003f18:	09e080e7          	jalr	158(ra) # 80002fb2 <brelse>
    brelse(dbuf);
    80003f1c:	8526                	mv	a0,s1
    80003f1e:	fffff097          	auipc	ra,0xfffff
    80003f22:	094080e7          	jalr	148(ra) # 80002fb2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f26:	2a05                	addw	s4,s4,1
    80003f28:	0a91                	add	s5,s5,4
    80003f2a:	02c9a783          	lw	a5,44(s3)
    80003f2e:	04fa5e63          	bge	s4,a5,80003f8a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f32:	0189a583          	lw	a1,24(s3)
    80003f36:	014585bb          	addw	a1,a1,s4
    80003f3a:	2585                	addw	a1,a1,1
    80003f3c:	0289a503          	lw	a0,40(s3)
    80003f40:	fffff097          	auipc	ra,0xfffff
    80003f44:	f42080e7          	jalr	-190(ra) # 80002e82 <bread>
    80003f48:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f4a:	000aa583          	lw	a1,0(s5)
    80003f4e:	0289a503          	lw	a0,40(s3)
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	f30080e7          	jalr	-208(ra) # 80002e82 <bread>
    80003f5a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f5c:	40000613          	li	a2,1024
    80003f60:	05890593          	add	a1,s2,88
    80003f64:	05850513          	add	a0,a0,88
    80003f68:	ffffd097          	auipc	ra,0xffffd
    80003f6c:	dc2080e7          	jalr	-574(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f70:	8526                	mv	a0,s1
    80003f72:	fffff097          	auipc	ra,0xfffff
    80003f76:	002080e7          	jalr	2(ra) # 80002f74 <bwrite>
    if(recovering == 0)
    80003f7a:	f80b1ce3          	bnez	s6,80003f12 <install_trans+0x36>
      bunpin(dbuf);
    80003f7e:	8526                	mv	a0,s1
    80003f80:	fffff097          	auipc	ra,0xfffff
    80003f84:	10a080e7          	jalr	266(ra) # 8000308a <bunpin>
    80003f88:	b769                	j	80003f12 <install_trans+0x36>
}
    80003f8a:	70e2                	ld	ra,56(sp)
    80003f8c:	7442                	ld	s0,48(sp)
    80003f8e:	74a2                	ld	s1,40(sp)
    80003f90:	7902                	ld	s2,32(sp)
    80003f92:	69e2                	ld	s3,24(sp)
    80003f94:	6a42                	ld	s4,16(sp)
    80003f96:	6aa2                	ld	s5,8(sp)
    80003f98:	6b02                	ld	s6,0(sp)
    80003f9a:	6121                	add	sp,sp,64
    80003f9c:	8082                	ret
    80003f9e:	8082                	ret

0000000080003fa0 <initlog>:
{
    80003fa0:	7179                	add	sp,sp,-48
    80003fa2:	f406                	sd	ra,40(sp)
    80003fa4:	f022                	sd	s0,32(sp)
    80003fa6:	ec26                	sd	s1,24(sp)
    80003fa8:	e84a                	sd	s2,16(sp)
    80003faa:	e44e                	sd	s3,8(sp)
    80003fac:	1800                	add	s0,sp,48
    80003fae:	892a                	mv	s2,a0
    80003fb0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fb2:	0001d497          	auipc	s1,0x1d
    80003fb6:	b5e48493          	add	s1,s1,-1186 # 80020b10 <log>
    80003fba:	00004597          	auipc	a1,0x4
    80003fbe:	67658593          	add	a1,a1,1654 # 80008630 <syscalls+0x1e0>
    80003fc2:	8526                	mv	a0,s1
    80003fc4:	ffffd097          	auipc	ra,0xffffd
    80003fc8:	b7e080e7          	jalr	-1154(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80003fcc:	0149a583          	lw	a1,20(s3)
    80003fd0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fd2:	0109a783          	lw	a5,16(s3)
    80003fd6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003fd8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fdc:	854a                	mv	a0,s2
    80003fde:	fffff097          	auipc	ra,0xfffff
    80003fe2:	ea4080e7          	jalr	-348(ra) # 80002e82 <bread>
  log.lh.n = lh->n;
    80003fe6:	4d30                	lw	a2,88(a0)
    80003fe8:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fea:	00c05f63          	blez	a2,80004008 <initlog+0x68>
    80003fee:	87aa                	mv	a5,a0
    80003ff0:	0001d717          	auipc	a4,0x1d
    80003ff4:	b5070713          	add	a4,a4,-1200 # 80020b40 <log+0x30>
    80003ff8:	060a                	sll	a2,a2,0x2
    80003ffa:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80003ffc:	4ff4                	lw	a3,92(a5)
    80003ffe:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004000:	0791                	add	a5,a5,4
    80004002:	0711                	add	a4,a4,4
    80004004:	fec79ce3          	bne	a5,a2,80003ffc <initlog+0x5c>
  brelse(buf);
    80004008:	fffff097          	auipc	ra,0xfffff
    8000400c:	faa080e7          	jalr	-86(ra) # 80002fb2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004010:	4505                	li	a0,1
    80004012:	00000097          	auipc	ra,0x0
    80004016:	eca080e7          	jalr	-310(ra) # 80003edc <install_trans>
  log.lh.n = 0;
    8000401a:	0001d797          	auipc	a5,0x1d
    8000401e:	b207a123          	sw	zero,-1246(a5) # 80020b3c <log+0x2c>
  write_head(); // clear the log
    80004022:	00000097          	auipc	ra,0x0
    80004026:	e50080e7          	jalr	-432(ra) # 80003e72 <write_head>
}
    8000402a:	70a2                	ld	ra,40(sp)
    8000402c:	7402                	ld	s0,32(sp)
    8000402e:	64e2                	ld	s1,24(sp)
    80004030:	6942                	ld	s2,16(sp)
    80004032:	69a2                	ld	s3,8(sp)
    80004034:	6145                	add	sp,sp,48
    80004036:	8082                	ret

0000000080004038 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004038:	1101                	add	sp,sp,-32
    8000403a:	ec06                	sd	ra,24(sp)
    8000403c:	e822                	sd	s0,16(sp)
    8000403e:	e426                	sd	s1,8(sp)
    80004040:	e04a                	sd	s2,0(sp)
    80004042:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004044:	0001d517          	auipc	a0,0x1d
    80004048:	acc50513          	add	a0,a0,-1332 # 80020b10 <log>
    8000404c:	ffffd097          	auipc	ra,0xffffd
    80004050:	b86080e7          	jalr	-1146(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004054:	0001d497          	auipc	s1,0x1d
    80004058:	abc48493          	add	s1,s1,-1348 # 80020b10 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000405c:	4979                	li	s2,30
    8000405e:	a039                	j	8000406c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004060:	85a6                	mv	a1,s1
    80004062:	8526                	mv	a0,s1
    80004064:	ffffe097          	auipc	ra,0xffffe
    80004068:	fea080e7          	jalr	-22(ra) # 8000204e <sleep>
    if(log.committing){
    8000406c:	50dc                	lw	a5,36(s1)
    8000406e:	fbed                	bnez	a5,80004060 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004070:	5098                	lw	a4,32(s1)
    80004072:	2705                	addw	a4,a4,1
    80004074:	0027179b          	sllw	a5,a4,0x2
    80004078:	9fb9                	addw	a5,a5,a4
    8000407a:	0017979b          	sllw	a5,a5,0x1
    8000407e:	54d4                	lw	a3,44(s1)
    80004080:	9fb5                	addw	a5,a5,a3
    80004082:	00f95963          	bge	s2,a5,80004094 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004086:	85a6                	mv	a1,s1
    80004088:	8526                	mv	a0,s1
    8000408a:	ffffe097          	auipc	ra,0xffffe
    8000408e:	fc4080e7          	jalr	-60(ra) # 8000204e <sleep>
    80004092:	bfe9                	j	8000406c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004094:	0001d517          	auipc	a0,0x1d
    80004098:	a7c50513          	add	a0,a0,-1412 # 80020b10 <log>
    8000409c:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000409e:	ffffd097          	auipc	ra,0xffffd
    800040a2:	be8080e7          	jalr	-1048(ra) # 80000c86 <release>
      break;
    }
  }
}
    800040a6:	60e2                	ld	ra,24(sp)
    800040a8:	6442                	ld	s0,16(sp)
    800040aa:	64a2                	ld	s1,8(sp)
    800040ac:	6902                	ld	s2,0(sp)
    800040ae:	6105                	add	sp,sp,32
    800040b0:	8082                	ret

00000000800040b2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040b2:	7139                	add	sp,sp,-64
    800040b4:	fc06                	sd	ra,56(sp)
    800040b6:	f822                	sd	s0,48(sp)
    800040b8:	f426                	sd	s1,40(sp)
    800040ba:	f04a                	sd	s2,32(sp)
    800040bc:	ec4e                	sd	s3,24(sp)
    800040be:	e852                	sd	s4,16(sp)
    800040c0:	e456                	sd	s5,8(sp)
    800040c2:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040c4:	0001d497          	auipc	s1,0x1d
    800040c8:	a4c48493          	add	s1,s1,-1460 # 80020b10 <log>
    800040cc:	8526                	mv	a0,s1
    800040ce:	ffffd097          	auipc	ra,0xffffd
    800040d2:	b04080e7          	jalr	-1276(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    800040d6:	509c                	lw	a5,32(s1)
    800040d8:	37fd                	addw	a5,a5,-1
    800040da:	0007891b          	sext.w	s2,a5
    800040de:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040e0:	50dc                	lw	a5,36(s1)
    800040e2:	e7b9                	bnez	a5,80004130 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040e4:	04091e63          	bnez	s2,80004140 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800040e8:	0001d497          	auipc	s1,0x1d
    800040ec:	a2848493          	add	s1,s1,-1496 # 80020b10 <log>
    800040f0:	4785                	li	a5,1
    800040f2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040f4:	8526                	mv	a0,s1
    800040f6:	ffffd097          	auipc	ra,0xffffd
    800040fa:	b90080e7          	jalr	-1136(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040fe:	54dc                	lw	a5,44(s1)
    80004100:	06f04763          	bgtz	a5,8000416e <end_op+0xbc>
    acquire(&log.lock);
    80004104:	0001d497          	auipc	s1,0x1d
    80004108:	a0c48493          	add	s1,s1,-1524 # 80020b10 <log>
    8000410c:	8526                	mv	a0,s1
    8000410e:	ffffd097          	auipc	ra,0xffffd
    80004112:	ac4080e7          	jalr	-1340(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004116:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000411a:	8526                	mv	a0,s1
    8000411c:	ffffe097          	auipc	ra,0xffffe
    80004120:	f96080e7          	jalr	-106(ra) # 800020b2 <wakeup>
    release(&log.lock);
    80004124:	8526                	mv	a0,s1
    80004126:	ffffd097          	auipc	ra,0xffffd
    8000412a:	b60080e7          	jalr	-1184(ra) # 80000c86 <release>
}
    8000412e:	a03d                	j	8000415c <end_op+0xaa>
    panic("log.committing");
    80004130:	00004517          	auipc	a0,0x4
    80004134:	50850513          	add	a0,a0,1288 # 80008638 <syscalls+0x1e8>
    80004138:	ffffc097          	auipc	ra,0xffffc
    8000413c:	404080e7          	jalr	1028(ra) # 8000053c <panic>
    wakeup(&log);
    80004140:	0001d497          	auipc	s1,0x1d
    80004144:	9d048493          	add	s1,s1,-1584 # 80020b10 <log>
    80004148:	8526                	mv	a0,s1
    8000414a:	ffffe097          	auipc	ra,0xffffe
    8000414e:	f68080e7          	jalr	-152(ra) # 800020b2 <wakeup>
  release(&log.lock);
    80004152:	8526                	mv	a0,s1
    80004154:	ffffd097          	auipc	ra,0xffffd
    80004158:	b32080e7          	jalr	-1230(ra) # 80000c86 <release>
}
    8000415c:	70e2                	ld	ra,56(sp)
    8000415e:	7442                	ld	s0,48(sp)
    80004160:	74a2                	ld	s1,40(sp)
    80004162:	7902                	ld	s2,32(sp)
    80004164:	69e2                	ld	s3,24(sp)
    80004166:	6a42                	ld	s4,16(sp)
    80004168:	6aa2                	ld	s5,8(sp)
    8000416a:	6121                	add	sp,sp,64
    8000416c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000416e:	0001da97          	auipc	s5,0x1d
    80004172:	9d2a8a93          	add	s5,s5,-1582 # 80020b40 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004176:	0001da17          	auipc	s4,0x1d
    8000417a:	99aa0a13          	add	s4,s4,-1638 # 80020b10 <log>
    8000417e:	018a2583          	lw	a1,24(s4)
    80004182:	012585bb          	addw	a1,a1,s2
    80004186:	2585                	addw	a1,a1,1
    80004188:	028a2503          	lw	a0,40(s4)
    8000418c:	fffff097          	auipc	ra,0xfffff
    80004190:	cf6080e7          	jalr	-778(ra) # 80002e82 <bread>
    80004194:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004196:	000aa583          	lw	a1,0(s5)
    8000419a:	028a2503          	lw	a0,40(s4)
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	ce4080e7          	jalr	-796(ra) # 80002e82 <bread>
    800041a6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041a8:	40000613          	li	a2,1024
    800041ac:	05850593          	add	a1,a0,88
    800041b0:	05848513          	add	a0,s1,88
    800041b4:	ffffd097          	auipc	ra,0xffffd
    800041b8:	b76080e7          	jalr	-1162(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    800041bc:	8526                	mv	a0,s1
    800041be:	fffff097          	auipc	ra,0xfffff
    800041c2:	db6080e7          	jalr	-586(ra) # 80002f74 <bwrite>
    brelse(from);
    800041c6:	854e                	mv	a0,s3
    800041c8:	fffff097          	auipc	ra,0xfffff
    800041cc:	dea080e7          	jalr	-534(ra) # 80002fb2 <brelse>
    brelse(to);
    800041d0:	8526                	mv	a0,s1
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	de0080e7          	jalr	-544(ra) # 80002fb2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041da:	2905                	addw	s2,s2,1
    800041dc:	0a91                	add	s5,s5,4
    800041de:	02ca2783          	lw	a5,44(s4)
    800041e2:	f8f94ee3          	blt	s2,a5,8000417e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	c8c080e7          	jalr	-884(ra) # 80003e72 <write_head>
    install_trans(0); // Now install writes to home locations
    800041ee:	4501                	li	a0,0
    800041f0:	00000097          	auipc	ra,0x0
    800041f4:	cec080e7          	jalr	-788(ra) # 80003edc <install_trans>
    log.lh.n = 0;
    800041f8:	0001d797          	auipc	a5,0x1d
    800041fc:	9407a223          	sw	zero,-1724(a5) # 80020b3c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004200:	00000097          	auipc	ra,0x0
    80004204:	c72080e7          	jalr	-910(ra) # 80003e72 <write_head>
    80004208:	bdf5                	j	80004104 <end_op+0x52>

000000008000420a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000420a:	1101                	add	sp,sp,-32
    8000420c:	ec06                	sd	ra,24(sp)
    8000420e:	e822                	sd	s0,16(sp)
    80004210:	e426                	sd	s1,8(sp)
    80004212:	e04a                	sd	s2,0(sp)
    80004214:	1000                	add	s0,sp,32
    80004216:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004218:	0001d917          	auipc	s2,0x1d
    8000421c:	8f890913          	add	s2,s2,-1800 # 80020b10 <log>
    80004220:	854a                	mv	a0,s2
    80004222:	ffffd097          	auipc	ra,0xffffd
    80004226:	9b0080e7          	jalr	-1616(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000422a:	02c92603          	lw	a2,44(s2)
    8000422e:	47f5                	li	a5,29
    80004230:	06c7c563          	blt	a5,a2,8000429a <log_write+0x90>
    80004234:	0001d797          	auipc	a5,0x1d
    80004238:	8f87a783          	lw	a5,-1800(a5) # 80020b2c <log+0x1c>
    8000423c:	37fd                	addw	a5,a5,-1
    8000423e:	04f65e63          	bge	a2,a5,8000429a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004242:	0001d797          	auipc	a5,0x1d
    80004246:	8ee7a783          	lw	a5,-1810(a5) # 80020b30 <log+0x20>
    8000424a:	06f05063          	blez	a5,800042aa <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000424e:	4781                	li	a5,0
    80004250:	06c05563          	blez	a2,800042ba <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004254:	44cc                	lw	a1,12(s1)
    80004256:	0001d717          	auipc	a4,0x1d
    8000425a:	8ea70713          	add	a4,a4,-1814 # 80020b40 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000425e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004260:	4314                	lw	a3,0(a4)
    80004262:	04b68c63          	beq	a3,a1,800042ba <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004266:	2785                	addw	a5,a5,1
    80004268:	0711                	add	a4,a4,4
    8000426a:	fef61be3          	bne	a2,a5,80004260 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000426e:	0621                	add	a2,a2,8
    80004270:	060a                	sll	a2,a2,0x2
    80004272:	0001d797          	auipc	a5,0x1d
    80004276:	89e78793          	add	a5,a5,-1890 # 80020b10 <log>
    8000427a:	97b2                	add	a5,a5,a2
    8000427c:	44d8                	lw	a4,12(s1)
    8000427e:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004280:	8526                	mv	a0,s1
    80004282:	fffff097          	auipc	ra,0xfffff
    80004286:	dcc080e7          	jalr	-564(ra) # 8000304e <bpin>
    log.lh.n++;
    8000428a:	0001d717          	auipc	a4,0x1d
    8000428e:	88670713          	add	a4,a4,-1914 # 80020b10 <log>
    80004292:	575c                	lw	a5,44(a4)
    80004294:	2785                	addw	a5,a5,1
    80004296:	d75c                	sw	a5,44(a4)
    80004298:	a82d                	j	800042d2 <log_write+0xc8>
    panic("too big a transaction");
    8000429a:	00004517          	auipc	a0,0x4
    8000429e:	3ae50513          	add	a0,a0,942 # 80008648 <syscalls+0x1f8>
    800042a2:	ffffc097          	auipc	ra,0xffffc
    800042a6:	29a080e7          	jalr	666(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    800042aa:	00004517          	auipc	a0,0x4
    800042ae:	3b650513          	add	a0,a0,950 # 80008660 <syscalls+0x210>
    800042b2:	ffffc097          	auipc	ra,0xffffc
    800042b6:	28a080e7          	jalr	650(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800042ba:	00878693          	add	a3,a5,8
    800042be:	068a                	sll	a3,a3,0x2
    800042c0:	0001d717          	auipc	a4,0x1d
    800042c4:	85070713          	add	a4,a4,-1968 # 80020b10 <log>
    800042c8:	9736                	add	a4,a4,a3
    800042ca:	44d4                	lw	a3,12(s1)
    800042cc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042ce:	faf609e3          	beq	a2,a5,80004280 <log_write+0x76>
  }
  release(&log.lock);
    800042d2:	0001d517          	auipc	a0,0x1d
    800042d6:	83e50513          	add	a0,a0,-1986 # 80020b10 <log>
    800042da:	ffffd097          	auipc	ra,0xffffd
    800042de:	9ac080e7          	jalr	-1620(ra) # 80000c86 <release>
}
    800042e2:	60e2                	ld	ra,24(sp)
    800042e4:	6442                	ld	s0,16(sp)
    800042e6:	64a2                	ld	s1,8(sp)
    800042e8:	6902                	ld	s2,0(sp)
    800042ea:	6105                	add	sp,sp,32
    800042ec:	8082                	ret

00000000800042ee <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042ee:	1101                	add	sp,sp,-32
    800042f0:	ec06                	sd	ra,24(sp)
    800042f2:	e822                	sd	s0,16(sp)
    800042f4:	e426                	sd	s1,8(sp)
    800042f6:	e04a                	sd	s2,0(sp)
    800042f8:	1000                	add	s0,sp,32
    800042fa:	84aa                	mv	s1,a0
    800042fc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800042fe:	00004597          	auipc	a1,0x4
    80004302:	38258593          	add	a1,a1,898 # 80008680 <syscalls+0x230>
    80004306:	0521                	add	a0,a0,8
    80004308:	ffffd097          	auipc	ra,0xffffd
    8000430c:	83a080e7          	jalr	-1990(ra) # 80000b42 <initlock>
  lk->name = name;
    80004310:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004314:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004318:	0204a423          	sw	zero,40(s1)
}
    8000431c:	60e2                	ld	ra,24(sp)
    8000431e:	6442                	ld	s0,16(sp)
    80004320:	64a2                	ld	s1,8(sp)
    80004322:	6902                	ld	s2,0(sp)
    80004324:	6105                	add	sp,sp,32
    80004326:	8082                	ret

0000000080004328 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004328:	1101                	add	sp,sp,-32
    8000432a:	ec06                	sd	ra,24(sp)
    8000432c:	e822                	sd	s0,16(sp)
    8000432e:	e426                	sd	s1,8(sp)
    80004330:	e04a                	sd	s2,0(sp)
    80004332:	1000                	add	s0,sp,32
    80004334:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004336:	00850913          	add	s2,a0,8
    8000433a:	854a                	mv	a0,s2
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	896080e7          	jalr	-1898(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004344:	409c                	lw	a5,0(s1)
    80004346:	cb89                	beqz	a5,80004358 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004348:	85ca                	mv	a1,s2
    8000434a:	8526                	mv	a0,s1
    8000434c:	ffffe097          	auipc	ra,0xffffe
    80004350:	d02080e7          	jalr	-766(ra) # 8000204e <sleep>
  while (lk->locked) {
    80004354:	409c                	lw	a5,0(s1)
    80004356:	fbed                	bnez	a5,80004348 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004358:	4785                	li	a5,1
    8000435a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000435c:	ffffd097          	auipc	ra,0xffffd
    80004360:	64a080e7          	jalr	1610(ra) # 800019a6 <myproc>
    80004364:	591c                	lw	a5,48(a0)
    80004366:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004368:	854a                	mv	a0,s2
    8000436a:	ffffd097          	auipc	ra,0xffffd
    8000436e:	91c080e7          	jalr	-1764(ra) # 80000c86 <release>
}
    80004372:	60e2                	ld	ra,24(sp)
    80004374:	6442                	ld	s0,16(sp)
    80004376:	64a2                	ld	s1,8(sp)
    80004378:	6902                	ld	s2,0(sp)
    8000437a:	6105                	add	sp,sp,32
    8000437c:	8082                	ret

000000008000437e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000437e:	1101                	add	sp,sp,-32
    80004380:	ec06                	sd	ra,24(sp)
    80004382:	e822                	sd	s0,16(sp)
    80004384:	e426                	sd	s1,8(sp)
    80004386:	e04a                	sd	s2,0(sp)
    80004388:	1000                	add	s0,sp,32
    8000438a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000438c:	00850913          	add	s2,a0,8
    80004390:	854a                	mv	a0,s2
    80004392:	ffffd097          	auipc	ra,0xffffd
    80004396:	840080e7          	jalr	-1984(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    8000439a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000439e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043a2:	8526                	mv	a0,s1
    800043a4:	ffffe097          	auipc	ra,0xffffe
    800043a8:	d0e080e7          	jalr	-754(ra) # 800020b2 <wakeup>
  release(&lk->lk);
    800043ac:	854a                	mv	a0,s2
    800043ae:	ffffd097          	auipc	ra,0xffffd
    800043b2:	8d8080e7          	jalr	-1832(ra) # 80000c86 <release>
}
    800043b6:	60e2                	ld	ra,24(sp)
    800043b8:	6442                	ld	s0,16(sp)
    800043ba:	64a2                	ld	s1,8(sp)
    800043bc:	6902                	ld	s2,0(sp)
    800043be:	6105                	add	sp,sp,32
    800043c0:	8082                	ret

00000000800043c2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043c2:	7179                	add	sp,sp,-48
    800043c4:	f406                	sd	ra,40(sp)
    800043c6:	f022                	sd	s0,32(sp)
    800043c8:	ec26                	sd	s1,24(sp)
    800043ca:	e84a                	sd	s2,16(sp)
    800043cc:	e44e                	sd	s3,8(sp)
    800043ce:	1800                	add	s0,sp,48
    800043d0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043d2:	00850913          	add	s2,a0,8
    800043d6:	854a                	mv	a0,s2
    800043d8:	ffffc097          	auipc	ra,0xffffc
    800043dc:	7fa080e7          	jalr	2042(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043e0:	409c                	lw	a5,0(s1)
    800043e2:	ef99                	bnez	a5,80004400 <holdingsleep+0x3e>
    800043e4:	4481                	li	s1,0
  release(&lk->lk);
    800043e6:	854a                	mv	a0,s2
    800043e8:	ffffd097          	auipc	ra,0xffffd
    800043ec:	89e080e7          	jalr	-1890(ra) # 80000c86 <release>
  return r;
}
    800043f0:	8526                	mv	a0,s1
    800043f2:	70a2                	ld	ra,40(sp)
    800043f4:	7402                	ld	s0,32(sp)
    800043f6:	64e2                	ld	s1,24(sp)
    800043f8:	6942                	ld	s2,16(sp)
    800043fa:	69a2                	ld	s3,8(sp)
    800043fc:	6145                	add	sp,sp,48
    800043fe:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004400:	0284a983          	lw	s3,40(s1)
    80004404:	ffffd097          	auipc	ra,0xffffd
    80004408:	5a2080e7          	jalr	1442(ra) # 800019a6 <myproc>
    8000440c:	5904                	lw	s1,48(a0)
    8000440e:	413484b3          	sub	s1,s1,s3
    80004412:	0014b493          	seqz	s1,s1
    80004416:	bfc1                	j	800043e6 <holdingsleep+0x24>

0000000080004418 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004418:	1141                	add	sp,sp,-16
    8000441a:	e406                	sd	ra,8(sp)
    8000441c:	e022                	sd	s0,0(sp)
    8000441e:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004420:	00004597          	auipc	a1,0x4
    80004424:	27058593          	add	a1,a1,624 # 80008690 <syscalls+0x240>
    80004428:	0001d517          	auipc	a0,0x1d
    8000442c:	83050513          	add	a0,a0,-2000 # 80020c58 <ftable>
    80004430:	ffffc097          	auipc	ra,0xffffc
    80004434:	712080e7          	jalr	1810(ra) # 80000b42 <initlock>
}
    80004438:	60a2                	ld	ra,8(sp)
    8000443a:	6402                	ld	s0,0(sp)
    8000443c:	0141                	add	sp,sp,16
    8000443e:	8082                	ret

0000000080004440 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004440:	1101                	add	sp,sp,-32
    80004442:	ec06                	sd	ra,24(sp)
    80004444:	e822                	sd	s0,16(sp)
    80004446:	e426                	sd	s1,8(sp)
    80004448:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000444a:	0001d517          	auipc	a0,0x1d
    8000444e:	80e50513          	add	a0,a0,-2034 # 80020c58 <ftable>
    80004452:	ffffc097          	auipc	ra,0xffffc
    80004456:	780080e7          	jalr	1920(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000445a:	0001d497          	auipc	s1,0x1d
    8000445e:	81648493          	add	s1,s1,-2026 # 80020c70 <ftable+0x18>
    80004462:	0001d717          	auipc	a4,0x1d
    80004466:	7ae70713          	add	a4,a4,1966 # 80021c10 <disk>
    if(f->ref == 0){
    8000446a:	40dc                	lw	a5,4(s1)
    8000446c:	cf99                	beqz	a5,8000448a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000446e:	02848493          	add	s1,s1,40
    80004472:	fee49ce3          	bne	s1,a4,8000446a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004476:	0001c517          	auipc	a0,0x1c
    8000447a:	7e250513          	add	a0,a0,2018 # 80020c58 <ftable>
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	808080e7          	jalr	-2040(ra) # 80000c86 <release>
  return 0;
    80004486:	4481                	li	s1,0
    80004488:	a819                	j	8000449e <filealloc+0x5e>
      f->ref = 1;
    8000448a:	4785                	li	a5,1
    8000448c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000448e:	0001c517          	auipc	a0,0x1c
    80004492:	7ca50513          	add	a0,a0,1994 # 80020c58 <ftable>
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	7f0080e7          	jalr	2032(ra) # 80000c86 <release>
}
    8000449e:	8526                	mv	a0,s1
    800044a0:	60e2                	ld	ra,24(sp)
    800044a2:	6442                	ld	s0,16(sp)
    800044a4:	64a2                	ld	s1,8(sp)
    800044a6:	6105                	add	sp,sp,32
    800044a8:	8082                	ret

00000000800044aa <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044aa:	1101                	add	sp,sp,-32
    800044ac:	ec06                	sd	ra,24(sp)
    800044ae:	e822                	sd	s0,16(sp)
    800044b0:	e426                	sd	s1,8(sp)
    800044b2:	1000                	add	s0,sp,32
    800044b4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044b6:	0001c517          	auipc	a0,0x1c
    800044ba:	7a250513          	add	a0,a0,1954 # 80020c58 <ftable>
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	714080e7          	jalr	1812(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800044c6:	40dc                	lw	a5,4(s1)
    800044c8:	02f05263          	blez	a5,800044ec <filedup+0x42>
    panic("filedup");
  f->ref++;
    800044cc:	2785                	addw	a5,a5,1
    800044ce:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800044d0:	0001c517          	auipc	a0,0x1c
    800044d4:	78850513          	add	a0,a0,1928 # 80020c58 <ftable>
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	7ae080e7          	jalr	1966(ra) # 80000c86 <release>
  return f;
}
    800044e0:	8526                	mv	a0,s1
    800044e2:	60e2                	ld	ra,24(sp)
    800044e4:	6442                	ld	s0,16(sp)
    800044e6:	64a2                	ld	s1,8(sp)
    800044e8:	6105                	add	sp,sp,32
    800044ea:	8082                	ret
    panic("filedup");
    800044ec:	00004517          	auipc	a0,0x4
    800044f0:	1ac50513          	add	a0,a0,428 # 80008698 <syscalls+0x248>
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	048080e7          	jalr	72(ra) # 8000053c <panic>

00000000800044fc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044fc:	7139                	add	sp,sp,-64
    800044fe:	fc06                	sd	ra,56(sp)
    80004500:	f822                	sd	s0,48(sp)
    80004502:	f426                	sd	s1,40(sp)
    80004504:	f04a                	sd	s2,32(sp)
    80004506:	ec4e                	sd	s3,24(sp)
    80004508:	e852                	sd	s4,16(sp)
    8000450a:	e456                	sd	s5,8(sp)
    8000450c:	0080                	add	s0,sp,64
    8000450e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004510:	0001c517          	auipc	a0,0x1c
    80004514:	74850513          	add	a0,a0,1864 # 80020c58 <ftable>
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	6ba080e7          	jalr	1722(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004520:	40dc                	lw	a5,4(s1)
    80004522:	06f05163          	blez	a5,80004584 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004526:	37fd                	addw	a5,a5,-1
    80004528:	0007871b          	sext.w	a4,a5
    8000452c:	c0dc                	sw	a5,4(s1)
    8000452e:	06e04363          	bgtz	a4,80004594 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004532:	0004a903          	lw	s2,0(s1)
    80004536:	0094ca83          	lbu	s5,9(s1)
    8000453a:	0104ba03          	ld	s4,16(s1)
    8000453e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004542:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004546:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000454a:	0001c517          	auipc	a0,0x1c
    8000454e:	70e50513          	add	a0,a0,1806 # 80020c58 <ftable>
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	734080e7          	jalr	1844(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    8000455a:	4785                	li	a5,1
    8000455c:	04f90d63          	beq	s2,a5,800045b6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004560:	3979                	addw	s2,s2,-2
    80004562:	4785                	li	a5,1
    80004564:	0527e063          	bltu	a5,s2,800045a4 <fileclose+0xa8>
    begin_op();
    80004568:	00000097          	auipc	ra,0x0
    8000456c:	ad0080e7          	jalr	-1328(ra) # 80004038 <begin_op>
    iput(ff.ip);
    80004570:	854e                	mv	a0,s3
    80004572:	fffff097          	auipc	ra,0xfffff
    80004576:	2da080e7          	jalr	730(ra) # 8000384c <iput>
    end_op();
    8000457a:	00000097          	auipc	ra,0x0
    8000457e:	b38080e7          	jalr	-1224(ra) # 800040b2 <end_op>
    80004582:	a00d                	j	800045a4 <fileclose+0xa8>
    panic("fileclose");
    80004584:	00004517          	auipc	a0,0x4
    80004588:	11c50513          	add	a0,a0,284 # 800086a0 <syscalls+0x250>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	fb0080e7          	jalr	-80(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004594:	0001c517          	auipc	a0,0x1c
    80004598:	6c450513          	add	a0,a0,1732 # 80020c58 <ftable>
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	6ea080e7          	jalr	1770(ra) # 80000c86 <release>
  }
}
    800045a4:	70e2                	ld	ra,56(sp)
    800045a6:	7442                	ld	s0,48(sp)
    800045a8:	74a2                	ld	s1,40(sp)
    800045aa:	7902                	ld	s2,32(sp)
    800045ac:	69e2                	ld	s3,24(sp)
    800045ae:	6a42                	ld	s4,16(sp)
    800045b0:	6aa2                	ld	s5,8(sp)
    800045b2:	6121                	add	sp,sp,64
    800045b4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045b6:	85d6                	mv	a1,s5
    800045b8:	8552                	mv	a0,s4
    800045ba:	00000097          	auipc	ra,0x0
    800045be:	348080e7          	jalr	840(ra) # 80004902 <pipeclose>
    800045c2:	b7cd                	j	800045a4 <fileclose+0xa8>

00000000800045c4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045c4:	715d                	add	sp,sp,-80
    800045c6:	e486                	sd	ra,72(sp)
    800045c8:	e0a2                	sd	s0,64(sp)
    800045ca:	fc26                	sd	s1,56(sp)
    800045cc:	f84a                	sd	s2,48(sp)
    800045ce:	f44e                	sd	s3,40(sp)
    800045d0:	0880                	add	s0,sp,80
    800045d2:	84aa                	mv	s1,a0
    800045d4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045d6:	ffffd097          	auipc	ra,0xffffd
    800045da:	3d0080e7          	jalr	976(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045de:	409c                	lw	a5,0(s1)
    800045e0:	37f9                	addw	a5,a5,-2
    800045e2:	4705                	li	a4,1
    800045e4:	04f76763          	bltu	a4,a5,80004632 <filestat+0x6e>
    800045e8:	892a                	mv	s2,a0
    ilock(f->ip);
    800045ea:	6c88                	ld	a0,24(s1)
    800045ec:	fffff097          	auipc	ra,0xfffff
    800045f0:	0a6080e7          	jalr	166(ra) # 80003692 <ilock>
    stati(f->ip, &st);
    800045f4:	fb840593          	add	a1,s0,-72
    800045f8:	6c88                	ld	a0,24(s1)
    800045fa:	fffff097          	auipc	ra,0xfffff
    800045fe:	322080e7          	jalr	802(ra) # 8000391c <stati>
    iunlock(f->ip);
    80004602:	6c88                	ld	a0,24(s1)
    80004604:	fffff097          	auipc	ra,0xfffff
    80004608:	150080e7          	jalr	336(ra) # 80003754 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000460c:	46e1                	li	a3,24
    8000460e:	fb840613          	add	a2,s0,-72
    80004612:	85ce                	mv	a1,s3
    80004614:	05093503          	ld	a0,80(s2)
    80004618:	ffffd097          	auipc	ra,0xffffd
    8000461c:	04e080e7          	jalr	78(ra) # 80001666 <copyout>
    80004620:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004624:	60a6                	ld	ra,72(sp)
    80004626:	6406                	ld	s0,64(sp)
    80004628:	74e2                	ld	s1,56(sp)
    8000462a:	7942                	ld	s2,48(sp)
    8000462c:	79a2                	ld	s3,40(sp)
    8000462e:	6161                	add	sp,sp,80
    80004630:	8082                	ret
  return -1;
    80004632:	557d                	li	a0,-1
    80004634:	bfc5                	j	80004624 <filestat+0x60>

0000000080004636 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004636:	7179                	add	sp,sp,-48
    80004638:	f406                	sd	ra,40(sp)
    8000463a:	f022                	sd	s0,32(sp)
    8000463c:	ec26                	sd	s1,24(sp)
    8000463e:	e84a                	sd	s2,16(sp)
    80004640:	e44e                	sd	s3,8(sp)
    80004642:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004644:	00854783          	lbu	a5,8(a0)
    80004648:	c3d5                	beqz	a5,800046ec <fileread+0xb6>
    8000464a:	84aa                	mv	s1,a0
    8000464c:	89ae                	mv	s3,a1
    8000464e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004650:	411c                	lw	a5,0(a0)
    80004652:	4705                	li	a4,1
    80004654:	04e78963          	beq	a5,a4,800046a6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004658:	470d                	li	a4,3
    8000465a:	04e78d63          	beq	a5,a4,800046b4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000465e:	4709                	li	a4,2
    80004660:	06e79e63          	bne	a5,a4,800046dc <fileread+0xa6>
    ilock(f->ip);
    80004664:	6d08                	ld	a0,24(a0)
    80004666:	fffff097          	auipc	ra,0xfffff
    8000466a:	02c080e7          	jalr	44(ra) # 80003692 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000466e:	874a                	mv	a4,s2
    80004670:	5094                	lw	a3,32(s1)
    80004672:	864e                	mv	a2,s3
    80004674:	4585                	li	a1,1
    80004676:	6c88                	ld	a0,24(s1)
    80004678:	fffff097          	auipc	ra,0xfffff
    8000467c:	2ce080e7          	jalr	718(ra) # 80003946 <readi>
    80004680:	892a                	mv	s2,a0
    80004682:	00a05563          	blez	a0,8000468c <fileread+0x56>
      f->off += r;
    80004686:	509c                	lw	a5,32(s1)
    80004688:	9fa9                	addw	a5,a5,a0
    8000468a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000468c:	6c88                	ld	a0,24(s1)
    8000468e:	fffff097          	auipc	ra,0xfffff
    80004692:	0c6080e7          	jalr	198(ra) # 80003754 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004696:	854a                	mv	a0,s2
    80004698:	70a2                	ld	ra,40(sp)
    8000469a:	7402                	ld	s0,32(sp)
    8000469c:	64e2                	ld	s1,24(sp)
    8000469e:	6942                	ld	s2,16(sp)
    800046a0:	69a2                	ld	s3,8(sp)
    800046a2:	6145                	add	sp,sp,48
    800046a4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046a6:	6908                	ld	a0,16(a0)
    800046a8:	00000097          	auipc	ra,0x0
    800046ac:	3c2080e7          	jalr	962(ra) # 80004a6a <piperead>
    800046b0:	892a                	mv	s2,a0
    800046b2:	b7d5                	j	80004696 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046b4:	02451783          	lh	a5,36(a0)
    800046b8:	03079693          	sll	a3,a5,0x30
    800046bc:	92c1                	srl	a3,a3,0x30
    800046be:	4725                	li	a4,9
    800046c0:	02d76863          	bltu	a4,a3,800046f0 <fileread+0xba>
    800046c4:	0792                	sll	a5,a5,0x4
    800046c6:	0001c717          	auipc	a4,0x1c
    800046ca:	4f270713          	add	a4,a4,1266 # 80020bb8 <devsw>
    800046ce:	97ba                	add	a5,a5,a4
    800046d0:	639c                	ld	a5,0(a5)
    800046d2:	c38d                	beqz	a5,800046f4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046d4:	4505                	li	a0,1
    800046d6:	9782                	jalr	a5
    800046d8:	892a                	mv	s2,a0
    800046da:	bf75                	j	80004696 <fileread+0x60>
    panic("fileread");
    800046dc:	00004517          	auipc	a0,0x4
    800046e0:	fd450513          	add	a0,a0,-44 # 800086b0 <syscalls+0x260>
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	e58080e7          	jalr	-424(ra) # 8000053c <panic>
    return -1;
    800046ec:	597d                	li	s2,-1
    800046ee:	b765                	j	80004696 <fileread+0x60>
      return -1;
    800046f0:	597d                	li	s2,-1
    800046f2:	b755                	j	80004696 <fileread+0x60>
    800046f4:	597d                	li	s2,-1
    800046f6:	b745                	j	80004696 <fileread+0x60>

00000000800046f8 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800046f8:	00954783          	lbu	a5,9(a0)
    800046fc:	10078e63          	beqz	a5,80004818 <filewrite+0x120>
{
    80004700:	715d                	add	sp,sp,-80
    80004702:	e486                	sd	ra,72(sp)
    80004704:	e0a2                	sd	s0,64(sp)
    80004706:	fc26                	sd	s1,56(sp)
    80004708:	f84a                	sd	s2,48(sp)
    8000470a:	f44e                	sd	s3,40(sp)
    8000470c:	f052                	sd	s4,32(sp)
    8000470e:	ec56                	sd	s5,24(sp)
    80004710:	e85a                	sd	s6,16(sp)
    80004712:	e45e                	sd	s7,8(sp)
    80004714:	e062                	sd	s8,0(sp)
    80004716:	0880                	add	s0,sp,80
    80004718:	892a                	mv	s2,a0
    8000471a:	8b2e                	mv	s6,a1
    8000471c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000471e:	411c                	lw	a5,0(a0)
    80004720:	4705                	li	a4,1
    80004722:	02e78263          	beq	a5,a4,80004746 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004726:	470d                	li	a4,3
    80004728:	02e78563          	beq	a5,a4,80004752 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000472c:	4709                	li	a4,2
    8000472e:	0ce79d63          	bne	a5,a4,80004808 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004732:	0ac05b63          	blez	a2,800047e8 <filewrite+0xf0>
    int i = 0;
    80004736:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004738:	6b85                	lui	s7,0x1
    8000473a:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000473e:	6c05                	lui	s8,0x1
    80004740:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004744:	a851                	j	800047d8 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004746:	6908                	ld	a0,16(a0)
    80004748:	00000097          	auipc	ra,0x0
    8000474c:	22a080e7          	jalr	554(ra) # 80004972 <pipewrite>
    80004750:	a045                	j	800047f0 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004752:	02451783          	lh	a5,36(a0)
    80004756:	03079693          	sll	a3,a5,0x30
    8000475a:	92c1                	srl	a3,a3,0x30
    8000475c:	4725                	li	a4,9
    8000475e:	0ad76f63          	bltu	a4,a3,8000481c <filewrite+0x124>
    80004762:	0792                	sll	a5,a5,0x4
    80004764:	0001c717          	auipc	a4,0x1c
    80004768:	45470713          	add	a4,a4,1108 # 80020bb8 <devsw>
    8000476c:	97ba                	add	a5,a5,a4
    8000476e:	679c                	ld	a5,8(a5)
    80004770:	cbc5                	beqz	a5,80004820 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004772:	4505                	li	a0,1
    80004774:	9782                	jalr	a5
    80004776:	a8ad                	j	800047f0 <filewrite+0xf8>
      if(n1 > max)
    80004778:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    8000477c:	00000097          	auipc	ra,0x0
    80004780:	8bc080e7          	jalr	-1860(ra) # 80004038 <begin_op>
      ilock(f->ip);
    80004784:	01893503          	ld	a0,24(s2)
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	f0a080e7          	jalr	-246(ra) # 80003692 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004790:	8756                	mv	a4,s5
    80004792:	02092683          	lw	a3,32(s2)
    80004796:	01698633          	add	a2,s3,s6
    8000479a:	4585                	li	a1,1
    8000479c:	01893503          	ld	a0,24(s2)
    800047a0:	fffff097          	auipc	ra,0xfffff
    800047a4:	29e080e7          	jalr	670(ra) # 80003a3e <writei>
    800047a8:	84aa                	mv	s1,a0
    800047aa:	00a05763          	blez	a0,800047b8 <filewrite+0xc0>
        f->off += r;
    800047ae:	02092783          	lw	a5,32(s2)
    800047b2:	9fa9                	addw	a5,a5,a0
    800047b4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047b8:	01893503          	ld	a0,24(s2)
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	f98080e7          	jalr	-104(ra) # 80003754 <iunlock>
      end_op();
    800047c4:	00000097          	auipc	ra,0x0
    800047c8:	8ee080e7          	jalr	-1810(ra) # 800040b2 <end_op>

      if(r != n1){
    800047cc:	009a9f63          	bne	s5,s1,800047ea <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    800047d0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047d4:	0149db63          	bge	s3,s4,800047ea <filewrite+0xf2>
      int n1 = n - i;
    800047d8:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800047dc:	0004879b          	sext.w	a5,s1
    800047e0:	f8fbdce3          	bge	s7,a5,80004778 <filewrite+0x80>
    800047e4:	84e2                	mv	s1,s8
    800047e6:	bf49                	j	80004778 <filewrite+0x80>
    int i = 0;
    800047e8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800047ea:	033a1d63          	bne	s4,s3,80004824 <filewrite+0x12c>
    800047ee:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047f0:	60a6                	ld	ra,72(sp)
    800047f2:	6406                	ld	s0,64(sp)
    800047f4:	74e2                	ld	s1,56(sp)
    800047f6:	7942                	ld	s2,48(sp)
    800047f8:	79a2                	ld	s3,40(sp)
    800047fa:	7a02                	ld	s4,32(sp)
    800047fc:	6ae2                	ld	s5,24(sp)
    800047fe:	6b42                	ld	s6,16(sp)
    80004800:	6ba2                	ld	s7,8(sp)
    80004802:	6c02                	ld	s8,0(sp)
    80004804:	6161                	add	sp,sp,80
    80004806:	8082                	ret
    panic("filewrite");
    80004808:	00004517          	auipc	a0,0x4
    8000480c:	eb850513          	add	a0,a0,-328 # 800086c0 <syscalls+0x270>
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	d2c080e7          	jalr	-724(ra) # 8000053c <panic>
    return -1;
    80004818:	557d                	li	a0,-1
}
    8000481a:	8082                	ret
      return -1;
    8000481c:	557d                	li	a0,-1
    8000481e:	bfc9                	j	800047f0 <filewrite+0xf8>
    80004820:	557d                	li	a0,-1
    80004822:	b7f9                	j	800047f0 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004824:	557d                	li	a0,-1
    80004826:	b7e9                	j	800047f0 <filewrite+0xf8>

0000000080004828 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004828:	7179                	add	sp,sp,-48
    8000482a:	f406                	sd	ra,40(sp)
    8000482c:	f022                	sd	s0,32(sp)
    8000482e:	ec26                	sd	s1,24(sp)
    80004830:	e84a                	sd	s2,16(sp)
    80004832:	e44e                	sd	s3,8(sp)
    80004834:	e052                	sd	s4,0(sp)
    80004836:	1800                	add	s0,sp,48
    80004838:	84aa                	mv	s1,a0
    8000483a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000483c:	0005b023          	sd	zero,0(a1)
    80004840:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004844:	00000097          	auipc	ra,0x0
    80004848:	bfc080e7          	jalr	-1028(ra) # 80004440 <filealloc>
    8000484c:	e088                	sd	a0,0(s1)
    8000484e:	c551                	beqz	a0,800048da <pipealloc+0xb2>
    80004850:	00000097          	auipc	ra,0x0
    80004854:	bf0080e7          	jalr	-1040(ra) # 80004440 <filealloc>
    80004858:	00aa3023          	sd	a0,0(s4)
    8000485c:	c92d                	beqz	a0,800048ce <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	284080e7          	jalr	644(ra) # 80000ae2 <kalloc>
    80004866:	892a                	mv	s2,a0
    80004868:	c125                	beqz	a0,800048c8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000486a:	4985                	li	s3,1
    8000486c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004870:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004874:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004878:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000487c:	00004597          	auipc	a1,0x4
    80004880:	e5458593          	add	a1,a1,-428 # 800086d0 <syscalls+0x280>
    80004884:	ffffc097          	auipc	ra,0xffffc
    80004888:	2be080e7          	jalr	702(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    8000488c:	609c                	ld	a5,0(s1)
    8000488e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004892:	609c                	ld	a5,0(s1)
    80004894:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004898:	609c                	ld	a5,0(s1)
    8000489a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000489e:	609c                	ld	a5,0(s1)
    800048a0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048a4:	000a3783          	ld	a5,0(s4)
    800048a8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048ac:	000a3783          	ld	a5,0(s4)
    800048b0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048b4:	000a3783          	ld	a5,0(s4)
    800048b8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048bc:	000a3783          	ld	a5,0(s4)
    800048c0:	0127b823          	sd	s2,16(a5)
  return 0;
    800048c4:	4501                	li	a0,0
    800048c6:	a025                	j	800048ee <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800048c8:	6088                	ld	a0,0(s1)
    800048ca:	e501                	bnez	a0,800048d2 <pipealloc+0xaa>
    800048cc:	a039                	j	800048da <pipealloc+0xb2>
    800048ce:	6088                	ld	a0,0(s1)
    800048d0:	c51d                	beqz	a0,800048fe <pipealloc+0xd6>
    fileclose(*f0);
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	c2a080e7          	jalr	-982(ra) # 800044fc <fileclose>
  if(*f1)
    800048da:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800048de:	557d                	li	a0,-1
  if(*f1)
    800048e0:	c799                	beqz	a5,800048ee <pipealloc+0xc6>
    fileclose(*f1);
    800048e2:	853e                	mv	a0,a5
    800048e4:	00000097          	auipc	ra,0x0
    800048e8:	c18080e7          	jalr	-1000(ra) # 800044fc <fileclose>
  return -1;
    800048ec:	557d                	li	a0,-1
}
    800048ee:	70a2                	ld	ra,40(sp)
    800048f0:	7402                	ld	s0,32(sp)
    800048f2:	64e2                	ld	s1,24(sp)
    800048f4:	6942                	ld	s2,16(sp)
    800048f6:	69a2                	ld	s3,8(sp)
    800048f8:	6a02                	ld	s4,0(sp)
    800048fa:	6145                	add	sp,sp,48
    800048fc:	8082                	ret
  return -1;
    800048fe:	557d                	li	a0,-1
    80004900:	b7fd                	j	800048ee <pipealloc+0xc6>

0000000080004902 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004902:	1101                	add	sp,sp,-32
    80004904:	ec06                	sd	ra,24(sp)
    80004906:	e822                	sd	s0,16(sp)
    80004908:	e426                	sd	s1,8(sp)
    8000490a:	e04a                	sd	s2,0(sp)
    8000490c:	1000                	add	s0,sp,32
    8000490e:	84aa                	mv	s1,a0
    80004910:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	2c0080e7          	jalr	704(ra) # 80000bd2 <acquire>
  if(writable){
    8000491a:	02090d63          	beqz	s2,80004954 <pipeclose+0x52>
    pi->writeopen = 0;
    8000491e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004922:	21848513          	add	a0,s1,536
    80004926:	ffffd097          	auipc	ra,0xffffd
    8000492a:	78c080e7          	jalr	1932(ra) # 800020b2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000492e:	2204b783          	ld	a5,544(s1)
    80004932:	eb95                	bnez	a5,80004966 <pipeclose+0x64>
    release(&pi->lock);
    80004934:	8526                	mv	a0,s1
    80004936:	ffffc097          	auipc	ra,0xffffc
    8000493a:	350080e7          	jalr	848(ra) # 80000c86 <release>
    kfree((char*)pi);
    8000493e:	8526                	mv	a0,s1
    80004940:	ffffc097          	auipc	ra,0xffffc
    80004944:	0a4080e7          	jalr	164(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004948:	60e2                	ld	ra,24(sp)
    8000494a:	6442                	ld	s0,16(sp)
    8000494c:	64a2                	ld	s1,8(sp)
    8000494e:	6902                	ld	s2,0(sp)
    80004950:	6105                	add	sp,sp,32
    80004952:	8082                	ret
    pi->readopen = 0;
    80004954:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004958:	21c48513          	add	a0,s1,540
    8000495c:	ffffd097          	auipc	ra,0xffffd
    80004960:	756080e7          	jalr	1878(ra) # 800020b2 <wakeup>
    80004964:	b7e9                	j	8000492e <pipeclose+0x2c>
    release(&pi->lock);
    80004966:	8526                	mv	a0,s1
    80004968:	ffffc097          	auipc	ra,0xffffc
    8000496c:	31e080e7          	jalr	798(ra) # 80000c86 <release>
}
    80004970:	bfe1                	j	80004948 <pipeclose+0x46>

0000000080004972 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004972:	711d                	add	sp,sp,-96
    80004974:	ec86                	sd	ra,88(sp)
    80004976:	e8a2                	sd	s0,80(sp)
    80004978:	e4a6                	sd	s1,72(sp)
    8000497a:	e0ca                	sd	s2,64(sp)
    8000497c:	fc4e                	sd	s3,56(sp)
    8000497e:	f852                	sd	s4,48(sp)
    80004980:	f456                	sd	s5,40(sp)
    80004982:	f05a                	sd	s6,32(sp)
    80004984:	ec5e                	sd	s7,24(sp)
    80004986:	e862                	sd	s8,16(sp)
    80004988:	1080                	add	s0,sp,96
    8000498a:	84aa                	mv	s1,a0
    8000498c:	8aae                	mv	s5,a1
    8000498e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004990:	ffffd097          	auipc	ra,0xffffd
    80004994:	016080e7          	jalr	22(ra) # 800019a6 <myproc>
    80004998:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000499a:	8526                	mv	a0,s1
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	236080e7          	jalr	566(ra) # 80000bd2 <acquire>
  while(i < n){
    800049a4:	0b405663          	blez	s4,80004a50 <pipewrite+0xde>
  int i = 0;
    800049a8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049aa:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049ac:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049b0:	21c48b93          	add	s7,s1,540
    800049b4:	a089                	j	800049f6 <pipewrite+0x84>
      release(&pi->lock);
    800049b6:	8526                	mv	a0,s1
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	2ce080e7          	jalr	718(ra) # 80000c86 <release>
      return -1;
    800049c0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800049c2:	854a                	mv	a0,s2
    800049c4:	60e6                	ld	ra,88(sp)
    800049c6:	6446                	ld	s0,80(sp)
    800049c8:	64a6                	ld	s1,72(sp)
    800049ca:	6906                	ld	s2,64(sp)
    800049cc:	79e2                	ld	s3,56(sp)
    800049ce:	7a42                	ld	s4,48(sp)
    800049d0:	7aa2                	ld	s5,40(sp)
    800049d2:	7b02                	ld	s6,32(sp)
    800049d4:	6be2                	ld	s7,24(sp)
    800049d6:	6c42                	ld	s8,16(sp)
    800049d8:	6125                	add	sp,sp,96
    800049da:	8082                	ret
      wakeup(&pi->nread);
    800049dc:	8562                	mv	a0,s8
    800049de:	ffffd097          	auipc	ra,0xffffd
    800049e2:	6d4080e7          	jalr	1748(ra) # 800020b2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049e6:	85a6                	mv	a1,s1
    800049e8:	855e                	mv	a0,s7
    800049ea:	ffffd097          	auipc	ra,0xffffd
    800049ee:	664080e7          	jalr	1636(ra) # 8000204e <sleep>
  while(i < n){
    800049f2:	07495063          	bge	s2,s4,80004a52 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800049f6:	2204a783          	lw	a5,544(s1)
    800049fa:	dfd5                	beqz	a5,800049b6 <pipewrite+0x44>
    800049fc:	854e                	mv	a0,s3
    800049fe:	ffffe097          	auipc	ra,0xffffe
    80004a02:	8f8080e7          	jalr	-1800(ra) # 800022f6 <killed>
    80004a06:	f945                	bnez	a0,800049b6 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a08:	2184a783          	lw	a5,536(s1)
    80004a0c:	21c4a703          	lw	a4,540(s1)
    80004a10:	2007879b          	addw	a5,a5,512
    80004a14:	fcf704e3          	beq	a4,a5,800049dc <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a18:	4685                	li	a3,1
    80004a1a:	01590633          	add	a2,s2,s5
    80004a1e:	faf40593          	add	a1,s0,-81
    80004a22:	0509b503          	ld	a0,80(s3)
    80004a26:	ffffd097          	auipc	ra,0xffffd
    80004a2a:	ccc080e7          	jalr	-820(ra) # 800016f2 <copyin>
    80004a2e:	03650263          	beq	a0,s6,80004a52 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a32:	21c4a783          	lw	a5,540(s1)
    80004a36:	0017871b          	addw	a4,a5,1
    80004a3a:	20e4ae23          	sw	a4,540(s1)
    80004a3e:	1ff7f793          	and	a5,a5,511
    80004a42:	97a6                	add	a5,a5,s1
    80004a44:	faf44703          	lbu	a4,-81(s0)
    80004a48:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a4c:	2905                	addw	s2,s2,1
    80004a4e:	b755                	j	800049f2 <pipewrite+0x80>
  int i = 0;
    80004a50:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004a52:	21848513          	add	a0,s1,536
    80004a56:	ffffd097          	auipc	ra,0xffffd
    80004a5a:	65c080e7          	jalr	1628(ra) # 800020b2 <wakeup>
  release(&pi->lock);
    80004a5e:	8526                	mv	a0,s1
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	226080e7          	jalr	550(ra) # 80000c86 <release>
  return i;
    80004a68:	bfa9                	j	800049c2 <pipewrite+0x50>

0000000080004a6a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a6a:	715d                	add	sp,sp,-80
    80004a6c:	e486                	sd	ra,72(sp)
    80004a6e:	e0a2                	sd	s0,64(sp)
    80004a70:	fc26                	sd	s1,56(sp)
    80004a72:	f84a                	sd	s2,48(sp)
    80004a74:	f44e                	sd	s3,40(sp)
    80004a76:	f052                	sd	s4,32(sp)
    80004a78:	ec56                	sd	s5,24(sp)
    80004a7a:	e85a                	sd	s6,16(sp)
    80004a7c:	0880                	add	s0,sp,80
    80004a7e:	84aa                	mv	s1,a0
    80004a80:	892e                	mv	s2,a1
    80004a82:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a84:	ffffd097          	auipc	ra,0xffffd
    80004a88:	f22080e7          	jalr	-222(ra) # 800019a6 <myproc>
    80004a8c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a8e:	8526                	mv	a0,s1
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	142080e7          	jalr	322(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a98:	2184a703          	lw	a4,536(s1)
    80004a9c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aa0:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004aa4:	02f71763          	bne	a4,a5,80004ad2 <piperead+0x68>
    80004aa8:	2244a783          	lw	a5,548(s1)
    80004aac:	c39d                	beqz	a5,80004ad2 <piperead+0x68>
    if(killed(pr)){
    80004aae:	8552                	mv	a0,s4
    80004ab0:	ffffe097          	auipc	ra,0xffffe
    80004ab4:	846080e7          	jalr	-1978(ra) # 800022f6 <killed>
    80004ab8:	e949                	bnez	a0,80004b4a <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aba:	85a6                	mv	a1,s1
    80004abc:	854e                	mv	a0,s3
    80004abe:	ffffd097          	auipc	ra,0xffffd
    80004ac2:	590080e7          	jalr	1424(ra) # 8000204e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ac6:	2184a703          	lw	a4,536(s1)
    80004aca:	21c4a783          	lw	a5,540(s1)
    80004ace:	fcf70de3          	beq	a4,a5,80004aa8 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ad2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ad4:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ad6:	05505463          	blez	s5,80004b1e <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004ada:	2184a783          	lw	a5,536(s1)
    80004ade:	21c4a703          	lw	a4,540(s1)
    80004ae2:	02f70e63          	beq	a4,a5,80004b1e <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ae6:	0017871b          	addw	a4,a5,1
    80004aea:	20e4ac23          	sw	a4,536(s1)
    80004aee:	1ff7f793          	and	a5,a5,511
    80004af2:	97a6                	add	a5,a5,s1
    80004af4:	0187c783          	lbu	a5,24(a5)
    80004af8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004afc:	4685                	li	a3,1
    80004afe:	fbf40613          	add	a2,s0,-65
    80004b02:	85ca                	mv	a1,s2
    80004b04:	050a3503          	ld	a0,80(s4)
    80004b08:	ffffd097          	auipc	ra,0xffffd
    80004b0c:	b5e080e7          	jalr	-1186(ra) # 80001666 <copyout>
    80004b10:	01650763          	beq	a0,s6,80004b1e <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b14:	2985                	addw	s3,s3,1
    80004b16:	0905                	add	s2,s2,1
    80004b18:	fd3a91e3          	bne	s5,s3,80004ada <piperead+0x70>
    80004b1c:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b1e:	21c48513          	add	a0,s1,540
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	590080e7          	jalr	1424(ra) # 800020b2 <wakeup>
  release(&pi->lock);
    80004b2a:	8526                	mv	a0,s1
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	15a080e7          	jalr	346(ra) # 80000c86 <release>
  return i;
}
    80004b34:	854e                	mv	a0,s3
    80004b36:	60a6                	ld	ra,72(sp)
    80004b38:	6406                	ld	s0,64(sp)
    80004b3a:	74e2                	ld	s1,56(sp)
    80004b3c:	7942                	ld	s2,48(sp)
    80004b3e:	79a2                	ld	s3,40(sp)
    80004b40:	7a02                	ld	s4,32(sp)
    80004b42:	6ae2                	ld	s5,24(sp)
    80004b44:	6b42                	ld	s6,16(sp)
    80004b46:	6161                	add	sp,sp,80
    80004b48:	8082                	ret
      release(&pi->lock);
    80004b4a:	8526                	mv	a0,s1
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	13a080e7          	jalr	314(ra) # 80000c86 <release>
      return -1;
    80004b54:	59fd                	li	s3,-1
    80004b56:	bff9                	j	80004b34 <piperead+0xca>

0000000080004b58 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004b58:	1141                	add	sp,sp,-16
    80004b5a:	e422                	sd	s0,8(sp)
    80004b5c:	0800                	add	s0,sp,16
    80004b5e:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004b60:	8905                	and	a0,a0,1
    80004b62:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004b64:	8b89                	and	a5,a5,2
    80004b66:	c399                	beqz	a5,80004b6c <flags2perm+0x14>
      perm |= PTE_W;
    80004b68:	00456513          	or	a0,a0,4
    return perm;
}
    80004b6c:	6422                	ld	s0,8(sp)
    80004b6e:	0141                	add	sp,sp,16
    80004b70:	8082                	ret

0000000080004b72 <exec>:

int
exec(char *path, char **argv)
{
    80004b72:	df010113          	add	sp,sp,-528
    80004b76:	20113423          	sd	ra,520(sp)
    80004b7a:	20813023          	sd	s0,512(sp)
    80004b7e:	ffa6                	sd	s1,504(sp)
    80004b80:	fbca                	sd	s2,496(sp)
    80004b82:	f7ce                	sd	s3,488(sp)
    80004b84:	f3d2                	sd	s4,480(sp)
    80004b86:	efd6                	sd	s5,472(sp)
    80004b88:	ebda                	sd	s6,464(sp)
    80004b8a:	e7de                	sd	s7,456(sp)
    80004b8c:	e3e2                	sd	s8,448(sp)
    80004b8e:	ff66                	sd	s9,440(sp)
    80004b90:	fb6a                	sd	s10,432(sp)
    80004b92:	f76e                	sd	s11,424(sp)
    80004b94:	0c00                	add	s0,sp,528
    80004b96:	892a                	mv	s2,a0
    80004b98:	dea43c23          	sd	a0,-520(s0)
    80004b9c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ba0:	ffffd097          	auipc	ra,0xffffd
    80004ba4:	e06080e7          	jalr	-506(ra) # 800019a6 <myproc>
    80004ba8:	84aa                	mv	s1,a0

  begin_op();
    80004baa:	fffff097          	auipc	ra,0xfffff
    80004bae:	48e080e7          	jalr	1166(ra) # 80004038 <begin_op>

  if((ip = namei(path)) == 0){
    80004bb2:	854a                	mv	a0,s2
    80004bb4:	fffff097          	auipc	ra,0xfffff
    80004bb8:	284080e7          	jalr	644(ra) # 80003e38 <namei>
    80004bbc:	c92d                	beqz	a0,80004c2e <exec+0xbc>
    80004bbe:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004bc0:	fffff097          	auipc	ra,0xfffff
    80004bc4:	ad2080e7          	jalr	-1326(ra) # 80003692 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004bc8:	04000713          	li	a4,64
    80004bcc:	4681                	li	a3,0
    80004bce:	e5040613          	add	a2,s0,-432
    80004bd2:	4581                	li	a1,0
    80004bd4:	8552                	mv	a0,s4
    80004bd6:	fffff097          	auipc	ra,0xfffff
    80004bda:	d70080e7          	jalr	-656(ra) # 80003946 <readi>
    80004bde:	04000793          	li	a5,64
    80004be2:	00f51a63          	bne	a0,a5,80004bf6 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004be6:	e5042703          	lw	a4,-432(s0)
    80004bea:	464c47b7          	lui	a5,0x464c4
    80004bee:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004bf2:	04f70463          	beq	a4,a5,80004c3a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004bf6:	8552                	mv	a0,s4
    80004bf8:	fffff097          	auipc	ra,0xfffff
    80004bfc:	cfc080e7          	jalr	-772(ra) # 800038f4 <iunlockput>
    end_op();
    80004c00:	fffff097          	auipc	ra,0xfffff
    80004c04:	4b2080e7          	jalr	1202(ra) # 800040b2 <end_op>
  }
  return -1;
    80004c08:	557d                	li	a0,-1
}
    80004c0a:	20813083          	ld	ra,520(sp)
    80004c0e:	20013403          	ld	s0,512(sp)
    80004c12:	74fe                	ld	s1,504(sp)
    80004c14:	795e                	ld	s2,496(sp)
    80004c16:	79be                	ld	s3,488(sp)
    80004c18:	7a1e                	ld	s4,480(sp)
    80004c1a:	6afe                	ld	s5,472(sp)
    80004c1c:	6b5e                	ld	s6,464(sp)
    80004c1e:	6bbe                	ld	s7,456(sp)
    80004c20:	6c1e                	ld	s8,448(sp)
    80004c22:	7cfa                	ld	s9,440(sp)
    80004c24:	7d5a                	ld	s10,432(sp)
    80004c26:	7dba                	ld	s11,424(sp)
    80004c28:	21010113          	add	sp,sp,528
    80004c2c:	8082                	ret
    end_op();
    80004c2e:	fffff097          	auipc	ra,0xfffff
    80004c32:	484080e7          	jalr	1156(ra) # 800040b2 <end_op>
    return -1;
    80004c36:	557d                	li	a0,-1
    80004c38:	bfc9                	j	80004c0a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c3a:	8526                	mv	a0,s1
    80004c3c:	ffffd097          	auipc	ra,0xffffd
    80004c40:	e2e080e7          	jalr	-466(ra) # 80001a6a <proc_pagetable>
    80004c44:	8b2a                	mv	s6,a0
    80004c46:	d945                	beqz	a0,80004bf6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c48:	e7042d03          	lw	s10,-400(s0)
    80004c4c:	e8845783          	lhu	a5,-376(s0)
    80004c50:	10078463          	beqz	a5,80004d58 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c54:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c56:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004c58:	6c85                	lui	s9,0x1
    80004c5a:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004c5e:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004c62:	6a85                	lui	s5,0x1
    80004c64:	a0b5                	j	80004cd0 <exec+0x15e>
      panic("loadseg: address should exist");
    80004c66:	00004517          	auipc	a0,0x4
    80004c6a:	a7250513          	add	a0,a0,-1422 # 800086d8 <syscalls+0x288>
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	8ce080e7          	jalr	-1842(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80004c76:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c78:	8726                	mv	a4,s1
    80004c7a:	012c06bb          	addw	a3,s8,s2
    80004c7e:	4581                	li	a1,0
    80004c80:	8552                	mv	a0,s4
    80004c82:	fffff097          	auipc	ra,0xfffff
    80004c86:	cc4080e7          	jalr	-828(ra) # 80003946 <readi>
    80004c8a:	2501                	sext.w	a0,a0
    80004c8c:	24a49863          	bne	s1,a0,80004edc <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80004c90:	012a893b          	addw	s2,s5,s2
    80004c94:	03397563          	bgeu	s2,s3,80004cbe <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004c98:	02091593          	sll	a1,s2,0x20
    80004c9c:	9181                	srl	a1,a1,0x20
    80004c9e:	95de                	add	a1,a1,s7
    80004ca0:	855a                	mv	a0,s6
    80004ca2:	ffffc097          	auipc	ra,0xffffc
    80004ca6:	3b4080e7          	jalr	948(ra) # 80001056 <walkaddr>
    80004caa:	862a                	mv	a2,a0
    if(pa == 0)
    80004cac:	dd4d                	beqz	a0,80004c66 <exec+0xf4>
    if(sz - i < PGSIZE)
    80004cae:	412984bb          	subw	s1,s3,s2
    80004cb2:	0004879b          	sext.w	a5,s1
    80004cb6:	fcfcf0e3          	bgeu	s9,a5,80004c76 <exec+0x104>
    80004cba:	84d6                	mv	s1,s5
    80004cbc:	bf6d                	j	80004c76 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004cbe:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cc2:	2d85                	addw	s11,s11,1
    80004cc4:	038d0d1b          	addw	s10,s10,56
    80004cc8:	e8845783          	lhu	a5,-376(s0)
    80004ccc:	08fdd763          	bge	s11,a5,80004d5a <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004cd0:	2d01                	sext.w	s10,s10
    80004cd2:	03800713          	li	a4,56
    80004cd6:	86ea                	mv	a3,s10
    80004cd8:	e1840613          	add	a2,s0,-488
    80004cdc:	4581                	li	a1,0
    80004cde:	8552                	mv	a0,s4
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	c66080e7          	jalr	-922(ra) # 80003946 <readi>
    80004ce8:	03800793          	li	a5,56
    80004cec:	1ef51663          	bne	a0,a5,80004ed8 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80004cf0:	e1842783          	lw	a5,-488(s0)
    80004cf4:	4705                	li	a4,1
    80004cf6:	fce796e3          	bne	a5,a4,80004cc2 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004cfa:	e4043483          	ld	s1,-448(s0)
    80004cfe:	e3843783          	ld	a5,-456(s0)
    80004d02:	1ef4e863          	bltu	s1,a5,80004ef2 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004d06:	e2843783          	ld	a5,-472(s0)
    80004d0a:	94be                	add	s1,s1,a5
    80004d0c:	1ef4e663          	bltu	s1,a5,80004ef8 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80004d10:	df043703          	ld	a4,-528(s0)
    80004d14:	8ff9                	and	a5,a5,a4
    80004d16:	1e079463          	bnez	a5,80004efe <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004d1a:	e1c42503          	lw	a0,-484(s0)
    80004d1e:	00000097          	auipc	ra,0x0
    80004d22:	e3a080e7          	jalr	-454(ra) # 80004b58 <flags2perm>
    80004d26:	86aa                	mv	a3,a0
    80004d28:	8626                	mv	a2,s1
    80004d2a:	85ca                	mv	a1,s2
    80004d2c:	855a                	mv	a0,s6
    80004d2e:	ffffc097          	auipc	ra,0xffffc
    80004d32:	6dc080e7          	jalr	1756(ra) # 8000140a <uvmalloc>
    80004d36:	e0a43423          	sd	a0,-504(s0)
    80004d3a:	1c050563          	beqz	a0,80004f04 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004d3e:	e2843b83          	ld	s7,-472(s0)
    80004d42:	e2042c03          	lw	s8,-480(s0)
    80004d46:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004d4a:	00098463          	beqz	s3,80004d52 <exec+0x1e0>
    80004d4e:	4901                	li	s2,0
    80004d50:	b7a1                	j	80004c98 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004d52:	e0843903          	ld	s2,-504(s0)
    80004d56:	b7b5                	j	80004cc2 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d58:	4901                	li	s2,0
  iunlockput(ip);
    80004d5a:	8552                	mv	a0,s4
    80004d5c:	fffff097          	auipc	ra,0xfffff
    80004d60:	b98080e7          	jalr	-1128(ra) # 800038f4 <iunlockput>
  end_op();
    80004d64:	fffff097          	auipc	ra,0xfffff
    80004d68:	34e080e7          	jalr	846(ra) # 800040b2 <end_op>
  p = myproc();
    80004d6c:	ffffd097          	auipc	ra,0xffffd
    80004d70:	c3a080e7          	jalr	-966(ra) # 800019a6 <myproc>
    80004d74:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d76:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004d7a:	6985                	lui	s3,0x1
    80004d7c:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004d7e:	99ca                	add	s3,s3,s2
    80004d80:	77fd                	lui	a5,0xfffff
    80004d82:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d86:	4691                	li	a3,4
    80004d88:	6609                	lui	a2,0x2
    80004d8a:	964e                	add	a2,a2,s3
    80004d8c:	85ce                	mv	a1,s3
    80004d8e:	855a                	mv	a0,s6
    80004d90:	ffffc097          	auipc	ra,0xffffc
    80004d94:	67a080e7          	jalr	1658(ra) # 8000140a <uvmalloc>
    80004d98:	892a                	mv	s2,a0
    80004d9a:	e0a43423          	sd	a0,-504(s0)
    80004d9e:	e509                	bnez	a0,80004da8 <exec+0x236>
  if(pagetable)
    80004da0:	e1343423          	sd	s3,-504(s0)
    80004da4:	4a01                	li	s4,0
    80004da6:	aa1d                	j	80004edc <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004da8:	75f9                	lui	a1,0xffffe
    80004daa:	95aa                	add	a1,a1,a0
    80004dac:	855a                	mv	a0,s6
    80004dae:	ffffd097          	auipc	ra,0xffffd
    80004db2:	886080e7          	jalr	-1914(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    80004db6:	7bfd                	lui	s7,0xfffff
    80004db8:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004dba:	e0043783          	ld	a5,-512(s0)
    80004dbe:	6388                	ld	a0,0(a5)
    80004dc0:	c52d                	beqz	a0,80004e2a <exec+0x2b8>
    80004dc2:	e9040993          	add	s3,s0,-368
    80004dc6:	f9040c13          	add	s8,s0,-112
    80004dca:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004dcc:	ffffc097          	auipc	ra,0xffffc
    80004dd0:	07c080e7          	jalr	124(ra) # 80000e48 <strlen>
    80004dd4:	0015079b          	addw	a5,a0,1
    80004dd8:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ddc:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    80004de0:	13796563          	bltu	s2,s7,80004f0a <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004de4:	e0043d03          	ld	s10,-512(s0)
    80004de8:	000d3a03          	ld	s4,0(s10)
    80004dec:	8552                	mv	a0,s4
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	05a080e7          	jalr	90(ra) # 80000e48 <strlen>
    80004df6:	0015069b          	addw	a3,a0,1
    80004dfa:	8652                	mv	a2,s4
    80004dfc:	85ca                	mv	a1,s2
    80004dfe:	855a                	mv	a0,s6
    80004e00:	ffffd097          	auipc	ra,0xffffd
    80004e04:	866080e7          	jalr	-1946(ra) # 80001666 <copyout>
    80004e08:	10054363          	bltz	a0,80004f0e <exec+0x39c>
    ustack[argc] = sp;
    80004e0c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e10:	0485                	add	s1,s1,1
    80004e12:	008d0793          	add	a5,s10,8
    80004e16:	e0f43023          	sd	a5,-512(s0)
    80004e1a:	008d3503          	ld	a0,8(s10)
    80004e1e:	c909                	beqz	a0,80004e30 <exec+0x2be>
    if(argc >= MAXARG)
    80004e20:	09a1                	add	s3,s3,8
    80004e22:	fb8995e3          	bne	s3,s8,80004dcc <exec+0x25a>
  ip = 0;
    80004e26:	4a01                	li	s4,0
    80004e28:	a855                	j	80004edc <exec+0x36a>
  sp = sz;
    80004e2a:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004e2e:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e30:	00349793          	sll	a5,s1,0x3
    80004e34:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdd240>
    80004e38:	97a2                	add	a5,a5,s0
    80004e3a:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004e3e:	00148693          	add	a3,s1,1
    80004e42:	068e                	sll	a3,a3,0x3
    80004e44:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e48:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80004e4c:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004e50:	f57968e3          	bltu	s2,s7,80004da0 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e54:	e9040613          	add	a2,s0,-368
    80004e58:	85ca                	mv	a1,s2
    80004e5a:	855a                	mv	a0,s6
    80004e5c:	ffffd097          	auipc	ra,0xffffd
    80004e60:	80a080e7          	jalr	-2038(ra) # 80001666 <copyout>
    80004e64:	0a054763          	bltz	a0,80004f12 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80004e68:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004e6c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e70:	df843783          	ld	a5,-520(s0)
    80004e74:	0007c703          	lbu	a4,0(a5)
    80004e78:	cf11                	beqz	a4,80004e94 <exec+0x322>
    80004e7a:	0785                	add	a5,a5,1
    if(*s == '/')
    80004e7c:	02f00693          	li	a3,47
    80004e80:	a039                	j	80004e8e <exec+0x31c>
      last = s+1;
    80004e82:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e86:	0785                	add	a5,a5,1
    80004e88:	fff7c703          	lbu	a4,-1(a5)
    80004e8c:	c701                	beqz	a4,80004e94 <exec+0x322>
    if(*s == '/')
    80004e8e:	fed71ce3          	bne	a4,a3,80004e86 <exec+0x314>
    80004e92:	bfc5                	j	80004e82 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e94:	4641                	li	a2,16
    80004e96:	df843583          	ld	a1,-520(s0)
    80004e9a:	158a8513          	add	a0,s5,344
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	f78080e7          	jalr	-136(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004ea6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004eaa:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004eae:	e0843783          	ld	a5,-504(s0)
    80004eb2:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004eb6:	058ab783          	ld	a5,88(s5)
    80004eba:	e6843703          	ld	a4,-408(s0)
    80004ebe:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ec0:	058ab783          	ld	a5,88(s5)
    80004ec4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ec8:	85e6                	mv	a1,s9
    80004eca:	ffffd097          	auipc	ra,0xffffd
    80004ece:	c3c080e7          	jalr	-964(ra) # 80001b06 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ed2:	0004851b          	sext.w	a0,s1
    80004ed6:	bb15                	j	80004c0a <exec+0x98>
    80004ed8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004edc:	e0843583          	ld	a1,-504(s0)
    80004ee0:	855a                	mv	a0,s6
    80004ee2:	ffffd097          	auipc	ra,0xffffd
    80004ee6:	c24080e7          	jalr	-988(ra) # 80001b06 <proc_freepagetable>
  return -1;
    80004eea:	557d                	li	a0,-1
  if(ip){
    80004eec:	d00a0fe3          	beqz	s4,80004c0a <exec+0x98>
    80004ef0:	b319                	j	80004bf6 <exec+0x84>
    80004ef2:	e1243423          	sd	s2,-504(s0)
    80004ef6:	b7dd                	j	80004edc <exec+0x36a>
    80004ef8:	e1243423          	sd	s2,-504(s0)
    80004efc:	b7c5                	j	80004edc <exec+0x36a>
    80004efe:	e1243423          	sd	s2,-504(s0)
    80004f02:	bfe9                	j	80004edc <exec+0x36a>
    80004f04:	e1243423          	sd	s2,-504(s0)
    80004f08:	bfd1                	j	80004edc <exec+0x36a>
  ip = 0;
    80004f0a:	4a01                	li	s4,0
    80004f0c:	bfc1                	j	80004edc <exec+0x36a>
    80004f0e:	4a01                	li	s4,0
  if(pagetable)
    80004f10:	b7f1                	j	80004edc <exec+0x36a>
  sz = sz1;
    80004f12:	e0843983          	ld	s3,-504(s0)
    80004f16:	b569                	j	80004da0 <exec+0x22e>

0000000080004f18 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f18:	7179                	add	sp,sp,-48
    80004f1a:	f406                	sd	ra,40(sp)
    80004f1c:	f022                	sd	s0,32(sp)
    80004f1e:	ec26                	sd	s1,24(sp)
    80004f20:	e84a                	sd	s2,16(sp)
    80004f22:	1800                	add	s0,sp,48
    80004f24:	892e                	mv	s2,a1
    80004f26:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004f28:	fdc40593          	add	a1,s0,-36
    80004f2c:	ffffe097          	auipc	ra,0xffffe
    80004f30:	bda080e7          	jalr	-1062(ra) # 80002b06 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f34:	fdc42703          	lw	a4,-36(s0)
    80004f38:	47bd                	li	a5,15
    80004f3a:	02e7eb63          	bltu	a5,a4,80004f70 <argfd+0x58>
    80004f3e:	ffffd097          	auipc	ra,0xffffd
    80004f42:	a68080e7          	jalr	-1432(ra) # 800019a6 <myproc>
    80004f46:	fdc42703          	lw	a4,-36(s0)
    80004f4a:	01a70793          	add	a5,a4,26
    80004f4e:	078e                	sll	a5,a5,0x3
    80004f50:	953e                	add	a0,a0,a5
    80004f52:	611c                	ld	a5,0(a0)
    80004f54:	c385                	beqz	a5,80004f74 <argfd+0x5c>
    return -1;
  if(pfd)
    80004f56:	00090463          	beqz	s2,80004f5e <argfd+0x46>
    *pfd = fd;
    80004f5a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f5e:	4501                	li	a0,0
  if(pf)
    80004f60:	c091                	beqz	s1,80004f64 <argfd+0x4c>
    *pf = f;
    80004f62:	e09c                	sd	a5,0(s1)
}
    80004f64:	70a2                	ld	ra,40(sp)
    80004f66:	7402                	ld	s0,32(sp)
    80004f68:	64e2                	ld	s1,24(sp)
    80004f6a:	6942                	ld	s2,16(sp)
    80004f6c:	6145                	add	sp,sp,48
    80004f6e:	8082                	ret
    return -1;
    80004f70:	557d                	li	a0,-1
    80004f72:	bfcd                	j	80004f64 <argfd+0x4c>
    80004f74:	557d                	li	a0,-1
    80004f76:	b7fd                	j	80004f64 <argfd+0x4c>

0000000080004f78 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f78:	1101                	add	sp,sp,-32
    80004f7a:	ec06                	sd	ra,24(sp)
    80004f7c:	e822                	sd	s0,16(sp)
    80004f7e:	e426                	sd	s1,8(sp)
    80004f80:	1000                	add	s0,sp,32
    80004f82:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f84:	ffffd097          	auipc	ra,0xffffd
    80004f88:	a22080e7          	jalr	-1502(ra) # 800019a6 <myproc>
    80004f8c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f8e:	0d050793          	add	a5,a0,208
    80004f92:	4501                	li	a0,0
    80004f94:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f96:	6398                	ld	a4,0(a5)
    80004f98:	cb19                	beqz	a4,80004fae <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f9a:	2505                	addw	a0,a0,1
    80004f9c:	07a1                	add	a5,a5,8
    80004f9e:	fed51ce3          	bne	a0,a3,80004f96 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004fa2:	557d                	li	a0,-1
}
    80004fa4:	60e2                	ld	ra,24(sp)
    80004fa6:	6442                	ld	s0,16(sp)
    80004fa8:	64a2                	ld	s1,8(sp)
    80004faa:	6105                	add	sp,sp,32
    80004fac:	8082                	ret
      p->ofile[fd] = f;
    80004fae:	01a50793          	add	a5,a0,26
    80004fb2:	078e                	sll	a5,a5,0x3
    80004fb4:	963e                	add	a2,a2,a5
    80004fb6:	e204                	sd	s1,0(a2)
      return fd;
    80004fb8:	b7f5                	j	80004fa4 <fdalloc+0x2c>

0000000080004fba <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004fba:	715d                	add	sp,sp,-80
    80004fbc:	e486                	sd	ra,72(sp)
    80004fbe:	e0a2                	sd	s0,64(sp)
    80004fc0:	fc26                	sd	s1,56(sp)
    80004fc2:	f84a                	sd	s2,48(sp)
    80004fc4:	f44e                	sd	s3,40(sp)
    80004fc6:	f052                	sd	s4,32(sp)
    80004fc8:	ec56                	sd	s5,24(sp)
    80004fca:	e85a                	sd	s6,16(sp)
    80004fcc:	0880                	add	s0,sp,80
    80004fce:	8b2e                	mv	s6,a1
    80004fd0:	89b2                	mv	s3,a2
    80004fd2:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004fd4:	fb040593          	add	a1,s0,-80
    80004fd8:	fffff097          	auipc	ra,0xfffff
    80004fdc:	e7e080e7          	jalr	-386(ra) # 80003e56 <nameiparent>
    80004fe0:	84aa                	mv	s1,a0
    80004fe2:	14050b63          	beqz	a0,80005138 <create+0x17e>
    return 0;

  ilock(dp);
    80004fe6:	ffffe097          	auipc	ra,0xffffe
    80004fea:	6ac080e7          	jalr	1708(ra) # 80003692 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004fee:	4601                	li	a2,0
    80004ff0:	fb040593          	add	a1,s0,-80
    80004ff4:	8526                	mv	a0,s1
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	b80080e7          	jalr	-1152(ra) # 80003b76 <dirlookup>
    80004ffe:	8aaa                	mv	s5,a0
    80005000:	c921                	beqz	a0,80005050 <create+0x96>
    iunlockput(dp);
    80005002:	8526                	mv	a0,s1
    80005004:	fffff097          	auipc	ra,0xfffff
    80005008:	8f0080e7          	jalr	-1808(ra) # 800038f4 <iunlockput>
    ilock(ip);
    8000500c:	8556                	mv	a0,s5
    8000500e:	ffffe097          	auipc	ra,0xffffe
    80005012:	684080e7          	jalr	1668(ra) # 80003692 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005016:	4789                	li	a5,2
    80005018:	02fb1563          	bne	s6,a5,80005042 <create+0x88>
    8000501c:	044ad783          	lhu	a5,68(s5)
    80005020:	37f9                	addw	a5,a5,-2
    80005022:	17c2                	sll	a5,a5,0x30
    80005024:	93c1                	srl	a5,a5,0x30
    80005026:	4705                	li	a4,1
    80005028:	00f76d63          	bltu	a4,a5,80005042 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000502c:	8556                	mv	a0,s5
    8000502e:	60a6                	ld	ra,72(sp)
    80005030:	6406                	ld	s0,64(sp)
    80005032:	74e2                	ld	s1,56(sp)
    80005034:	7942                	ld	s2,48(sp)
    80005036:	79a2                	ld	s3,40(sp)
    80005038:	7a02                	ld	s4,32(sp)
    8000503a:	6ae2                	ld	s5,24(sp)
    8000503c:	6b42                	ld	s6,16(sp)
    8000503e:	6161                	add	sp,sp,80
    80005040:	8082                	ret
    iunlockput(ip);
    80005042:	8556                	mv	a0,s5
    80005044:	fffff097          	auipc	ra,0xfffff
    80005048:	8b0080e7          	jalr	-1872(ra) # 800038f4 <iunlockput>
    return 0;
    8000504c:	4a81                	li	s5,0
    8000504e:	bff9                	j	8000502c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005050:	85da                	mv	a1,s6
    80005052:	4088                	lw	a0,0(s1)
    80005054:	ffffe097          	auipc	ra,0xffffe
    80005058:	4a6080e7          	jalr	1190(ra) # 800034fa <ialloc>
    8000505c:	8a2a                	mv	s4,a0
    8000505e:	c529                	beqz	a0,800050a8 <create+0xee>
  ilock(ip);
    80005060:	ffffe097          	auipc	ra,0xffffe
    80005064:	632080e7          	jalr	1586(ra) # 80003692 <ilock>
  ip->major = major;
    80005068:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000506c:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005070:	4905                	li	s2,1
    80005072:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005076:	8552                	mv	a0,s4
    80005078:	ffffe097          	auipc	ra,0xffffe
    8000507c:	54e080e7          	jalr	1358(ra) # 800035c6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005080:	032b0b63          	beq	s6,s2,800050b6 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005084:	004a2603          	lw	a2,4(s4)
    80005088:	fb040593          	add	a1,s0,-80
    8000508c:	8526                	mv	a0,s1
    8000508e:	fffff097          	auipc	ra,0xfffff
    80005092:	cf8080e7          	jalr	-776(ra) # 80003d86 <dirlink>
    80005096:	06054f63          	bltz	a0,80005114 <create+0x15a>
  iunlockput(dp);
    8000509a:	8526                	mv	a0,s1
    8000509c:	fffff097          	auipc	ra,0xfffff
    800050a0:	858080e7          	jalr	-1960(ra) # 800038f4 <iunlockput>
  return ip;
    800050a4:	8ad2                	mv	s5,s4
    800050a6:	b759                	j	8000502c <create+0x72>
    iunlockput(dp);
    800050a8:	8526                	mv	a0,s1
    800050aa:	fffff097          	auipc	ra,0xfffff
    800050ae:	84a080e7          	jalr	-1974(ra) # 800038f4 <iunlockput>
    return 0;
    800050b2:	8ad2                	mv	s5,s4
    800050b4:	bfa5                	j	8000502c <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050b6:	004a2603          	lw	a2,4(s4)
    800050ba:	00003597          	auipc	a1,0x3
    800050be:	63e58593          	add	a1,a1,1598 # 800086f8 <syscalls+0x2a8>
    800050c2:	8552                	mv	a0,s4
    800050c4:	fffff097          	auipc	ra,0xfffff
    800050c8:	cc2080e7          	jalr	-830(ra) # 80003d86 <dirlink>
    800050cc:	04054463          	bltz	a0,80005114 <create+0x15a>
    800050d0:	40d0                	lw	a2,4(s1)
    800050d2:	00003597          	auipc	a1,0x3
    800050d6:	62e58593          	add	a1,a1,1582 # 80008700 <syscalls+0x2b0>
    800050da:	8552                	mv	a0,s4
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	caa080e7          	jalr	-854(ra) # 80003d86 <dirlink>
    800050e4:	02054863          	bltz	a0,80005114 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800050e8:	004a2603          	lw	a2,4(s4)
    800050ec:	fb040593          	add	a1,s0,-80
    800050f0:	8526                	mv	a0,s1
    800050f2:	fffff097          	auipc	ra,0xfffff
    800050f6:	c94080e7          	jalr	-876(ra) # 80003d86 <dirlink>
    800050fa:	00054d63          	bltz	a0,80005114 <create+0x15a>
    dp->nlink++;  // for ".."
    800050fe:	04a4d783          	lhu	a5,74(s1)
    80005102:	2785                	addw	a5,a5,1
    80005104:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005108:	8526                	mv	a0,s1
    8000510a:	ffffe097          	auipc	ra,0xffffe
    8000510e:	4bc080e7          	jalr	1212(ra) # 800035c6 <iupdate>
    80005112:	b761                	j	8000509a <create+0xe0>
  ip->nlink = 0;
    80005114:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005118:	8552                	mv	a0,s4
    8000511a:	ffffe097          	auipc	ra,0xffffe
    8000511e:	4ac080e7          	jalr	1196(ra) # 800035c6 <iupdate>
  iunlockput(ip);
    80005122:	8552                	mv	a0,s4
    80005124:	ffffe097          	auipc	ra,0xffffe
    80005128:	7d0080e7          	jalr	2000(ra) # 800038f4 <iunlockput>
  iunlockput(dp);
    8000512c:	8526                	mv	a0,s1
    8000512e:	ffffe097          	auipc	ra,0xffffe
    80005132:	7c6080e7          	jalr	1990(ra) # 800038f4 <iunlockput>
  return 0;
    80005136:	bddd                	j	8000502c <create+0x72>
    return 0;
    80005138:	8aaa                	mv	s5,a0
    8000513a:	bdcd                	j	8000502c <create+0x72>

000000008000513c <sys_dup>:
{
    8000513c:	7179                	add	sp,sp,-48
    8000513e:	f406                	sd	ra,40(sp)
    80005140:	f022                	sd	s0,32(sp)
    80005142:	ec26                	sd	s1,24(sp)
    80005144:	e84a                	sd	s2,16(sp)
    80005146:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005148:	fd840613          	add	a2,s0,-40
    8000514c:	4581                	li	a1,0
    8000514e:	4501                	li	a0,0
    80005150:	00000097          	auipc	ra,0x0
    80005154:	dc8080e7          	jalr	-568(ra) # 80004f18 <argfd>
    return -1;
    80005158:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000515a:	02054363          	bltz	a0,80005180 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000515e:	fd843903          	ld	s2,-40(s0)
    80005162:	854a                	mv	a0,s2
    80005164:	00000097          	auipc	ra,0x0
    80005168:	e14080e7          	jalr	-492(ra) # 80004f78 <fdalloc>
    8000516c:	84aa                	mv	s1,a0
    return -1;
    8000516e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005170:	00054863          	bltz	a0,80005180 <sys_dup+0x44>
  filedup(f);
    80005174:	854a                	mv	a0,s2
    80005176:	fffff097          	auipc	ra,0xfffff
    8000517a:	334080e7          	jalr	820(ra) # 800044aa <filedup>
  return fd;
    8000517e:	87a6                	mv	a5,s1
}
    80005180:	853e                	mv	a0,a5
    80005182:	70a2                	ld	ra,40(sp)
    80005184:	7402                	ld	s0,32(sp)
    80005186:	64e2                	ld	s1,24(sp)
    80005188:	6942                	ld	s2,16(sp)
    8000518a:	6145                	add	sp,sp,48
    8000518c:	8082                	ret

000000008000518e <sys_read>:
{
    8000518e:	7179                	add	sp,sp,-48
    80005190:	f406                	sd	ra,40(sp)
    80005192:	f022                	sd	s0,32(sp)
    80005194:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005196:	fd840593          	add	a1,s0,-40
    8000519a:	4505                	li	a0,1
    8000519c:	ffffe097          	auipc	ra,0xffffe
    800051a0:	98a080e7          	jalr	-1654(ra) # 80002b26 <argaddr>
  argint(2, &n);
    800051a4:	fe440593          	add	a1,s0,-28
    800051a8:	4509                	li	a0,2
    800051aa:	ffffe097          	auipc	ra,0xffffe
    800051ae:	95c080e7          	jalr	-1700(ra) # 80002b06 <argint>
  if(argfd(0, 0, &f) < 0)
    800051b2:	fe840613          	add	a2,s0,-24
    800051b6:	4581                	li	a1,0
    800051b8:	4501                	li	a0,0
    800051ba:	00000097          	auipc	ra,0x0
    800051be:	d5e080e7          	jalr	-674(ra) # 80004f18 <argfd>
    800051c2:	87aa                	mv	a5,a0
    return -1;
    800051c4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800051c6:	0007cc63          	bltz	a5,800051de <sys_read+0x50>
  return fileread(f, p, n);
    800051ca:	fe442603          	lw	a2,-28(s0)
    800051ce:	fd843583          	ld	a1,-40(s0)
    800051d2:	fe843503          	ld	a0,-24(s0)
    800051d6:	fffff097          	auipc	ra,0xfffff
    800051da:	460080e7          	jalr	1120(ra) # 80004636 <fileread>
}
    800051de:	70a2                	ld	ra,40(sp)
    800051e0:	7402                	ld	s0,32(sp)
    800051e2:	6145                	add	sp,sp,48
    800051e4:	8082                	ret

00000000800051e6 <sys_write>:
{
    800051e6:	7179                	add	sp,sp,-48
    800051e8:	f406                	sd	ra,40(sp)
    800051ea:	f022                	sd	s0,32(sp)
    800051ec:	1800                	add	s0,sp,48
  argaddr(1, &p);
    800051ee:	fd840593          	add	a1,s0,-40
    800051f2:	4505                	li	a0,1
    800051f4:	ffffe097          	auipc	ra,0xffffe
    800051f8:	932080e7          	jalr	-1742(ra) # 80002b26 <argaddr>
  argint(2, &n);
    800051fc:	fe440593          	add	a1,s0,-28
    80005200:	4509                	li	a0,2
    80005202:	ffffe097          	auipc	ra,0xffffe
    80005206:	904080e7          	jalr	-1788(ra) # 80002b06 <argint>
  if(argfd(0, 0, &f) < 0)
    8000520a:	fe840613          	add	a2,s0,-24
    8000520e:	4581                	li	a1,0
    80005210:	4501                	li	a0,0
    80005212:	00000097          	auipc	ra,0x0
    80005216:	d06080e7          	jalr	-762(ra) # 80004f18 <argfd>
    8000521a:	87aa                	mv	a5,a0
    return -1;
    8000521c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000521e:	0007cc63          	bltz	a5,80005236 <sys_write+0x50>
  return filewrite(f, p, n);
    80005222:	fe442603          	lw	a2,-28(s0)
    80005226:	fd843583          	ld	a1,-40(s0)
    8000522a:	fe843503          	ld	a0,-24(s0)
    8000522e:	fffff097          	auipc	ra,0xfffff
    80005232:	4ca080e7          	jalr	1226(ra) # 800046f8 <filewrite>
}
    80005236:	70a2                	ld	ra,40(sp)
    80005238:	7402                	ld	s0,32(sp)
    8000523a:	6145                	add	sp,sp,48
    8000523c:	8082                	ret

000000008000523e <sys_close>:
{
    8000523e:	1101                	add	sp,sp,-32
    80005240:	ec06                	sd	ra,24(sp)
    80005242:	e822                	sd	s0,16(sp)
    80005244:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005246:	fe040613          	add	a2,s0,-32
    8000524a:	fec40593          	add	a1,s0,-20
    8000524e:	4501                	li	a0,0
    80005250:	00000097          	auipc	ra,0x0
    80005254:	cc8080e7          	jalr	-824(ra) # 80004f18 <argfd>
    return -1;
    80005258:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000525a:	02054463          	bltz	a0,80005282 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000525e:	ffffc097          	auipc	ra,0xffffc
    80005262:	748080e7          	jalr	1864(ra) # 800019a6 <myproc>
    80005266:	fec42783          	lw	a5,-20(s0)
    8000526a:	07e9                	add	a5,a5,26
    8000526c:	078e                	sll	a5,a5,0x3
    8000526e:	953e                	add	a0,a0,a5
    80005270:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005274:	fe043503          	ld	a0,-32(s0)
    80005278:	fffff097          	auipc	ra,0xfffff
    8000527c:	284080e7          	jalr	644(ra) # 800044fc <fileclose>
  return 0;
    80005280:	4781                	li	a5,0
}
    80005282:	853e                	mv	a0,a5
    80005284:	60e2                	ld	ra,24(sp)
    80005286:	6442                	ld	s0,16(sp)
    80005288:	6105                	add	sp,sp,32
    8000528a:	8082                	ret

000000008000528c <sys_fstat>:
{
    8000528c:	1101                	add	sp,sp,-32
    8000528e:	ec06                	sd	ra,24(sp)
    80005290:	e822                	sd	s0,16(sp)
    80005292:	1000                	add	s0,sp,32
  argaddr(1, &st);
    80005294:	fe040593          	add	a1,s0,-32
    80005298:	4505                	li	a0,1
    8000529a:	ffffe097          	auipc	ra,0xffffe
    8000529e:	88c080e7          	jalr	-1908(ra) # 80002b26 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800052a2:	fe840613          	add	a2,s0,-24
    800052a6:	4581                	li	a1,0
    800052a8:	4501                	li	a0,0
    800052aa:	00000097          	auipc	ra,0x0
    800052ae:	c6e080e7          	jalr	-914(ra) # 80004f18 <argfd>
    800052b2:	87aa                	mv	a5,a0
    return -1;
    800052b4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052b6:	0007ca63          	bltz	a5,800052ca <sys_fstat+0x3e>
  return filestat(f, st);
    800052ba:	fe043583          	ld	a1,-32(s0)
    800052be:	fe843503          	ld	a0,-24(s0)
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	302080e7          	jalr	770(ra) # 800045c4 <filestat>
}
    800052ca:	60e2                	ld	ra,24(sp)
    800052cc:	6442                	ld	s0,16(sp)
    800052ce:	6105                	add	sp,sp,32
    800052d0:	8082                	ret

00000000800052d2 <sys_link>:
{
    800052d2:	7169                	add	sp,sp,-304
    800052d4:	f606                	sd	ra,296(sp)
    800052d6:	f222                	sd	s0,288(sp)
    800052d8:	ee26                	sd	s1,280(sp)
    800052da:	ea4a                	sd	s2,272(sp)
    800052dc:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052de:	08000613          	li	a2,128
    800052e2:	ed040593          	add	a1,s0,-304
    800052e6:	4501                	li	a0,0
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	85e080e7          	jalr	-1954(ra) # 80002b46 <argstr>
    return -1;
    800052f0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052f2:	10054e63          	bltz	a0,8000540e <sys_link+0x13c>
    800052f6:	08000613          	li	a2,128
    800052fa:	f5040593          	add	a1,s0,-176
    800052fe:	4505                	li	a0,1
    80005300:	ffffe097          	auipc	ra,0xffffe
    80005304:	846080e7          	jalr	-1978(ra) # 80002b46 <argstr>
    return -1;
    80005308:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000530a:	10054263          	bltz	a0,8000540e <sys_link+0x13c>
  begin_op();
    8000530e:	fffff097          	auipc	ra,0xfffff
    80005312:	d2a080e7          	jalr	-726(ra) # 80004038 <begin_op>
  if((ip = namei(old)) == 0){
    80005316:	ed040513          	add	a0,s0,-304
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	b1e080e7          	jalr	-1250(ra) # 80003e38 <namei>
    80005322:	84aa                	mv	s1,a0
    80005324:	c551                	beqz	a0,800053b0 <sys_link+0xde>
  ilock(ip);
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	36c080e7          	jalr	876(ra) # 80003692 <ilock>
  if(ip->type == T_DIR){
    8000532e:	04449703          	lh	a4,68(s1)
    80005332:	4785                	li	a5,1
    80005334:	08f70463          	beq	a4,a5,800053bc <sys_link+0xea>
  ip->nlink++;
    80005338:	04a4d783          	lhu	a5,74(s1)
    8000533c:	2785                	addw	a5,a5,1
    8000533e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005342:	8526                	mv	a0,s1
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	282080e7          	jalr	642(ra) # 800035c6 <iupdate>
  iunlock(ip);
    8000534c:	8526                	mv	a0,s1
    8000534e:	ffffe097          	auipc	ra,0xffffe
    80005352:	406080e7          	jalr	1030(ra) # 80003754 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005356:	fd040593          	add	a1,s0,-48
    8000535a:	f5040513          	add	a0,s0,-176
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	af8080e7          	jalr	-1288(ra) # 80003e56 <nameiparent>
    80005366:	892a                	mv	s2,a0
    80005368:	c935                	beqz	a0,800053dc <sys_link+0x10a>
  ilock(dp);
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	328080e7          	jalr	808(ra) # 80003692 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005372:	00092703          	lw	a4,0(s2)
    80005376:	409c                	lw	a5,0(s1)
    80005378:	04f71d63          	bne	a4,a5,800053d2 <sys_link+0x100>
    8000537c:	40d0                	lw	a2,4(s1)
    8000537e:	fd040593          	add	a1,s0,-48
    80005382:	854a                	mv	a0,s2
    80005384:	fffff097          	auipc	ra,0xfffff
    80005388:	a02080e7          	jalr	-1534(ra) # 80003d86 <dirlink>
    8000538c:	04054363          	bltz	a0,800053d2 <sys_link+0x100>
  iunlockput(dp);
    80005390:	854a                	mv	a0,s2
    80005392:	ffffe097          	auipc	ra,0xffffe
    80005396:	562080e7          	jalr	1378(ra) # 800038f4 <iunlockput>
  iput(ip);
    8000539a:	8526                	mv	a0,s1
    8000539c:	ffffe097          	auipc	ra,0xffffe
    800053a0:	4b0080e7          	jalr	1200(ra) # 8000384c <iput>
  end_op();
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	d0e080e7          	jalr	-754(ra) # 800040b2 <end_op>
  return 0;
    800053ac:	4781                	li	a5,0
    800053ae:	a085                	j	8000540e <sys_link+0x13c>
    end_op();
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	d02080e7          	jalr	-766(ra) # 800040b2 <end_op>
    return -1;
    800053b8:	57fd                	li	a5,-1
    800053ba:	a891                	j	8000540e <sys_link+0x13c>
    iunlockput(ip);
    800053bc:	8526                	mv	a0,s1
    800053be:	ffffe097          	auipc	ra,0xffffe
    800053c2:	536080e7          	jalr	1334(ra) # 800038f4 <iunlockput>
    end_op();
    800053c6:	fffff097          	auipc	ra,0xfffff
    800053ca:	cec080e7          	jalr	-788(ra) # 800040b2 <end_op>
    return -1;
    800053ce:	57fd                	li	a5,-1
    800053d0:	a83d                	j	8000540e <sys_link+0x13c>
    iunlockput(dp);
    800053d2:	854a                	mv	a0,s2
    800053d4:	ffffe097          	auipc	ra,0xffffe
    800053d8:	520080e7          	jalr	1312(ra) # 800038f4 <iunlockput>
  ilock(ip);
    800053dc:	8526                	mv	a0,s1
    800053de:	ffffe097          	auipc	ra,0xffffe
    800053e2:	2b4080e7          	jalr	692(ra) # 80003692 <ilock>
  ip->nlink--;
    800053e6:	04a4d783          	lhu	a5,74(s1)
    800053ea:	37fd                	addw	a5,a5,-1
    800053ec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053f0:	8526                	mv	a0,s1
    800053f2:	ffffe097          	auipc	ra,0xffffe
    800053f6:	1d4080e7          	jalr	468(ra) # 800035c6 <iupdate>
  iunlockput(ip);
    800053fa:	8526                	mv	a0,s1
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	4f8080e7          	jalr	1272(ra) # 800038f4 <iunlockput>
  end_op();
    80005404:	fffff097          	auipc	ra,0xfffff
    80005408:	cae080e7          	jalr	-850(ra) # 800040b2 <end_op>
  return -1;
    8000540c:	57fd                	li	a5,-1
}
    8000540e:	853e                	mv	a0,a5
    80005410:	70b2                	ld	ra,296(sp)
    80005412:	7412                	ld	s0,288(sp)
    80005414:	64f2                	ld	s1,280(sp)
    80005416:	6952                	ld	s2,272(sp)
    80005418:	6155                	add	sp,sp,304
    8000541a:	8082                	ret

000000008000541c <sys_unlink>:
{
    8000541c:	7151                	add	sp,sp,-240
    8000541e:	f586                	sd	ra,232(sp)
    80005420:	f1a2                	sd	s0,224(sp)
    80005422:	eda6                	sd	s1,216(sp)
    80005424:	e9ca                	sd	s2,208(sp)
    80005426:	e5ce                	sd	s3,200(sp)
    80005428:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000542a:	08000613          	li	a2,128
    8000542e:	f3040593          	add	a1,s0,-208
    80005432:	4501                	li	a0,0
    80005434:	ffffd097          	auipc	ra,0xffffd
    80005438:	712080e7          	jalr	1810(ra) # 80002b46 <argstr>
    8000543c:	18054163          	bltz	a0,800055be <sys_unlink+0x1a2>
  begin_op();
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	bf8080e7          	jalr	-1032(ra) # 80004038 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005448:	fb040593          	add	a1,s0,-80
    8000544c:	f3040513          	add	a0,s0,-208
    80005450:	fffff097          	auipc	ra,0xfffff
    80005454:	a06080e7          	jalr	-1530(ra) # 80003e56 <nameiparent>
    80005458:	84aa                	mv	s1,a0
    8000545a:	c979                	beqz	a0,80005530 <sys_unlink+0x114>
  ilock(dp);
    8000545c:	ffffe097          	auipc	ra,0xffffe
    80005460:	236080e7          	jalr	566(ra) # 80003692 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005464:	00003597          	auipc	a1,0x3
    80005468:	29458593          	add	a1,a1,660 # 800086f8 <syscalls+0x2a8>
    8000546c:	fb040513          	add	a0,s0,-80
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	6ec080e7          	jalr	1772(ra) # 80003b5c <namecmp>
    80005478:	14050a63          	beqz	a0,800055cc <sys_unlink+0x1b0>
    8000547c:	00003597          	auipc	a1,0x3
    80005480:	28458593          	add	a1,a1,644 # 80008700 <syscalls+0x2b0>
    80005484:	fb040513          	add	a0,s0,-80
    80005488:	ffffe097          	auipc	ra,0xffffe
    8000548c:	6d4080e7          	jalr	1748(ra) # 80003b5c <namecmp>
    80005490:	12050e63          	beqz	a0,800055cc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005494:	f2c40613          	add	a2,s0,-212
    80005498:	fb040593          	add	a1,s0,-80
    8000549c:	8526                	mv	a0,s1
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	6d8080e7          	jalr	1752(ra) # 80003b76 <dirlookup>
    800054a6:	892a                	mv	s2,a0
    800054a8:	12050263          	beqz	a0,800055cc <sys_unlink+0x1b0>
  ilock(ip);
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	1e6080e7          	jalr	486(ra) # 80003692 <ilock>
  if(ip->nlink < 1)
    800054b4:	04a91783          	lh	a5,74(s2)
    800054b8:	08f05263          	blez	a5,8000553c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800054bc:	04491703          	lh	a4,68(s2)
    800054c0:	4785                	li	a5,1
    800054c2:	08f70563          	beq	a4,a5,8000554c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800054c6:	4641                	li	a2,16
    800054c8:	4581                	li	a1,0
    800054ca:	fc040513          	add	a0,s0,-64
    800054ce:	ffffc097          	auipc	ra,0xffffc
    800054d2:	800080e7          	jalr	-2048(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054d6:	4741                	li	a4,16
    800054d8:	f2c42683          	lw	a3,-212(s0)
    800054dc:	fc040613          	add	a2,s0,-64
    800054e0:	4581                	li	a1,0
    800054e2:	8526                	mv	a0,s1
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	55a080e7          	jalr	1370(ra) # 80003a3e <writei>
    800054ec:	47c1                	li	a5,16
    800054ee:	0af51563          	bne	a0,a5,80005598 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800054f2:	04491703          	lh	a4,68(s2)
    800054f6:	4785                	li	a5,1
    800054f8:	0af70863          	beq	a4,a5,800055a8 <sys_unlink+0x18c>
  iunlockput(dp);
    800054fc:	8526                	mv	a0,s1
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	3f6080e7          	jalr	1014(ra) # 800038f4 <iunlockput>
  ip->nlink--;
    80005506:	04a95783          	lhu	a5,74(s2)
    8000550a:	37fd                	addw	a5,a5,-1
    8000550c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005510:	854a                	mv	a0,s2
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	0b4080e7          	jalr	180(ra) # 800035c6 <iupdate>
  iunlockput(ip);
    8000551a:	854a                	mv	a0,s2
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	3d8080e7          	jalr	984(ra) # 800038f4 <iunlockput>
  end_op();
    80005524:	fffff097          	auipc	ra,0xfffff
    80005528:	b8e080e7          	jalr	-1138(ra) # 800040b2 <end_op>
  return 0;
    8000552c:	4501                	li	a0,0
    8000552e:	a84d                	j	800055e0 <sys_unlink+0x1c4>
    end_op();
    80005530:	fffff097          	auipc	ra,0xfffff
    80005534:	b82080e7          	jalr	-1150(ra) # 800040b2 <end_op>
    return -1;
    80005538:	557d                	li	a0,-1
    8000553a:	a05d                	j	800055e0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000553c:	00003517          	auipc	a0,0x3
    80005540:	1cc50513          	add	a0,a0,460 # 80008708 <syscalls+0x2b8>
    80005544:	ffffb097          	auipc	ra,0xffffb
    80005548:	ff8080e7          	jalr	-8(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000554c:	04c92703          	lw	a4,76(s2)
    80005550:	02000793          	li	a5,32
    80005554:	f6e7f9e3          	bgeu	a5,a4,800054c6 <sys_unlink+0xaa>
    80005558:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000555c:	4741                	li	a4,16
    8000555e:	86ce                	mv	a3,s3
    80005560:	f1840613          	add	a2,s0,-232
    80005564:	4581                	li	a1,0
    80005566:	854a                	mv	a0,s2
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	3de080e7          	jalr	990(ra) # 80003946 <readi>
    80005570:	47c1                	li	a5,16
    80005572:	00f51b63          	bne	a0,a5,80005588 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005576:	f1845783          	lhu	a5,-232(s0)
    8000557a:	e7a1                	bnez	a5,800055c2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000557c:	29c1                	addw	s3,s3,16
    8000557e:	04c92783          	lw	a5,76(s2)
    80005582:	fcf9ede3          	bltu	s3,a5,8000555c <sys_unlink+0x140>
    80005586:	b781                	j	800054c6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005588:	00003517          	auipc	a0,0x3
    8000558c:	19850513          	add	a0,a0,408 # 80008720 <syscalls+0x2d0>
    80005590:	ffffb097          	auipc	ra,0xffffb
    80005594:	fac080e7          	jalr	-84(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005598:	00003517          	auipc	a0,0x3
    8000559c:	1a050513          	add	a0,a0,416 # 80008738 <syscalls+0x2e8>
    800055a0:	ffffb097          	auipc	ra,0xffffb
    800055a4:	f9c080e7          	jalr	-100(ra) # 8000053c <panic>
    dp->nlink--;
    800055a8:	04a4d783          	lhu	a5,74(s1)
    800055ac:	37fd                	addw	a5,a5,-1
    800055ae:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055b2:	8526                	mv	a0,s1
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	012080e7          	jalr	18(ra) # 800035c6 <iupdate>
    800055bc:	b781                	j	800054fc <sys_unlink+0xe0>
    return -1;
    800055be:	557d                	li	a0,-1
    800055c0:	a005                	j	800055e0 <sys_unlink+0x1c4>
    iunlockput(ip);
    800055c2:	854a                	mv	a0,s2
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	330080e7          	jalr	816(ra) # 800038f4 <iunlockput>
  iunlockput(dp);
    800055cc:	8526                	mv	a0,s1
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	326080e7          	jalr	806(ra) # 800038f4 <iunlockput>
  end_op();
    800055d6:	fffff097          	auipc	ra,0xfffff
    800055da:	adc080e7          	jalr	-1316(ra) # 800040b2 <end_op>
  return -1;
    800055de:	557d                	li	a0,-1
}
    800055e0:	70ae                	ld	ra,232(sp)
    800055e2:	740e                	ld	s0,224(sp)
    800055e4:	64ee                	ld	s1,216(sp)
    800055e6:	694e                	ld	s2,208(sp)
    800055e8:	69ae                	ld	s3,200(sp)
    800055ea:	616d                	add	sp,sp,240
    800055ec:	8082                	ret

00000000800055ee <sys_open>:

uint64
sys_open(void)
{
    800055ee:	7131                	add	sp,sp,-192
    800055f0:	fd06                	sd	ra,184(sp)
    800055f2:	f922                	sd	s0,176(sp)
    800055f4:	f526                	sd	s1,168(sp)
    800055f6:	f14a                	sd	s2,160(sp)
    800055f8:	ed4e                	sd	s3,152(sp)
    800055fa:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800055fc:	f4c40593          	add	a1,s0,-180
    80005600:	4505                	li	a0,1
    80005602:	ffffd097          	auipc	ra,0xffffd
    80005606:	504080e7          	jalr	1284(ra) # 80002b06 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000560a:	08000613          	li	a2,128
    8000560e:	f5040593          	add	a1,s0,-176
    80005612:	4501                	li	a0,0
    80005614:	ffffd097          	auipc	ra,0xffffd
    80005618:	532080e7          	jalr	1330(ra) # 80002b46 <argstr>
    8000561c:	87aa                	mv	a5,a0
    return -1;
    8000561e:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005620:	0a07c863          	bltz	a5,800056d0 <sys_open+0xe2>

  begin_op();
    80005624:	fffff097          	auipc	ra,0xfffff
    80005628:	a14080e7          	jalr	-1516(ra) # 80004038 <begin_op>

  if(omode & O_CREATE){
    8000562c:	f4c42783          	lw	a5,-180(s0)
    80005630:	2007f793          	and	a5,a5,512
    80005634:	cbdd                	beqz	a5,800056ea <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005636:	4681                	li	a3,0
    80005638:	4601                	li	a2,0
    8000563a:	4589                	li	a1,2
    8000563c:	f5040513          	add	a0,s0,-176
    80005640:	00000097          	auipc	ra,0x0
    80005644:	97a080e7          	jalr	-1670(ra) # 80004fba <create>
    80005648:	84aa                	mv	s1,a0
    if(ip == 0){
    8000564a:	c951                	beqz	a0,800056de <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000564c:	04449703          	lh	a4,68(s1)
    80005650:	478d                	li	a5,3
    80005652:	00f71763          	bne	a4,a5,80005660 <sys_open+0x72>
    80005656:	0464d703          	lhu	a4,70(s1)
    8000565a:	47a5                	li	a5,9
    8000565c:	0ce7ec63          	bltu	a5,a4,80005734 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	de0080e7          	jalr	-544(ra) # 80004440 <filealloc>
    80005668:	892a                	mv	s2,a0
    8000566a:	c56d                	beqz	a0,80005754 <sys_open+0x166>
    8000566c:	00000097          	auipc	ra,0x0
    80005670:	90c080e7          	jalr	-1780(ra) # 80004f78 <fdalloc>
    80005674:	89aa                	mv	s3,a0
    80005676:	0c054a63          	bltz	a0,8000574a <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000567a:	04449703          	lh	a4,68(s1)
    8000567e:	478d                	li	a5,3
    80005680:	0ef70563          	beq	a4,a5,8000576a <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005684:	4789                	li	a5,2
    80005686:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    8000568a:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    8000568e:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005692:	f4c42783          	lw	a5,-180(s0)
    80005696:	0017c713          	xor	a4,a5,1
    8000569a:	8b05                	and	a4,a4,1
    8000569c:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056a0:	0037f713          	and	a4,a5,3
    800056a4:	00e03733          	snez	a4,a4
    800056a8:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800056ac:	4007f793          	and	a5,a5,1024
    800056b0:	c791                	beqz	a5,800056bc <sys_open+0xce>
    800056b2:	04449703          	lh	a4,68(s1)
    800056b6:	4789                	li	a5,2
    800056b8:	0cf70063          	beq	a4,a5,80005778 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    800056bc:	8526                	mv	a0,s1
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	096080e7          	jalr	150(ra) # 80003754 <iunlock>
  end_op();
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	9ec080e7          	jalr	-1556(ra) # 800040b2 <end_op>

  return fd;
    800056ce:	854e                	mv	a0,s3
}
    800056d0:	70ea                	ld	ra,184(sp)
    800056d2:	744a                	ld	s0,176(sp)
    800056d4:	74aa                	ld	s1,168(sp)
    800056d6:	790a                	ld	s2,160(sp)
    800056d8:	69ea                	ld	s3,152(sp)
    800056da:	6129                	add	sp,sp,192
    800056dc:	8082                	ret
      end_op();
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	9d4080e7          	jalr	-1580(ra) # 800040b2 <end_op>
      return -1;
    800056e6:	557d                	li	a0,-1
    800056e8:	b7e5                	j	800056d0 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    800056ea:	f5040513          	add	a0,s0,-176
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	74a080e7          	jalr	1866(ra) # 80003e38 <namei>
    800056f6:	84aa                	mv	s1,a0
    800056f8:	c905                	beqz	a0,80005728 <sys_open+0x13a>
    ilock(ip);
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	f98080e7          	jalr	-104(ra) # 80003692 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005702:	04449703          	lh	a4,68(s1)
    80005706:	4785                	li	a5,1
    80005708:	f4f712e3          	bne	a4,a5,8000564c <sys_open+0x5e>
    8000570c:	f4c42783          	lw	a5,-180(s0)
    80005710:	dba1                	beqz	a5,80005660 <sys_open+0x72>
      iunlockput(ip);
    80005712:	8526                	mv	a0,s1
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	1e0080e7          	jalr	480(ra) # 800038f4 <iunlockput>
      end_op();
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	996080e7          	jalr	-1642(ra) # 800040b2 <end_op>
      return -1;
    80005724:	557d                	li	a0,-1
    80005726:	b76d                	j	800056d0 <sys_open+0xe2>
      end_op();
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	98a080e7          	jalr	-1654(ra) # 800040b2 <end_op>
      return -1;
    80005730:	557d                	li	a0,-1
    80005732:	bf79                	j	800056d0 <sys_open+0xe2>
    iunlockput(ip);
    80005734:	8526                	mv	a0,s1
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	1be080e7          	jalr	446(ra) # 800038f4 <iunlockput>
    end_op();
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	974080e7          	jalr	-1676(ra) # 800040b2 <end_op>
    return -1;
    80005746:	557d                	li	a0,-1
    80005748:	b761                	j	800056d0 <sys_open+0xe2>
      fileclose(f);
    8000574a:	854a                	mv	a0,s2
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	db0080e7          	jalr	-592(ra) # 800044fc <fileclose>
    iunlockput(ip);
    80005754:	8526                	mv	a0,s1
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	19e080e7          	jalr	414(ra) # 800038f4 <iunlockput>
    end_op();
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	954080e7          	jalr	-1708(ra) # 800040b2 <end_op>
    return -1;
    80005766:	557d                	li	a0,-1
    80005768:	b7a5                	j	800056d0 <sys_open+0xe2>
    f->type = FD_DEVICE;
    8000576a:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    8000576e:	04649783          	lh	a5,70(s1)
    80005772:	02f91223          	sh	a5,36(s2)
    80005776:	bf21                	j	8000568e <sys_open+0xa0>
    itrunc(ip);
    80005778:	8526                	mv	a0,s1
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	026080e7          	jalr	38(ra) # 800037a0 <itrunc>
    80005782:	bf2d                	j	800056bc <sys_open+0xce>

0000000080005784 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005784:	7175                	add	sp,sp,-144
    80005786:	e506                	sd	ra,136(sp)
    80005788:	e122                	sd	s0,128(sp)
    8000578a:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	8ac080e7          	jalr	-1876(ra) # 80004038 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005794:	08000613          	li	a2,128
    80005798:	f7040593          	add	a1,s0,-144
    8000579c:	4501                	li	a0,0
    8000579e:	ffffd097          	auipc	ra,0xffffd
    800057a2:	3a8080e7          	jalr	936(ra) # 80002b46 <argstr>
    800057a6:	02054963          	bltz	a0,800057d8 <sys_mkdir+0x54>
    800057aa:	4681                	li	a3,0
    800057ac:	4601                	li	a2,0
    800057ae:	4585                	li	a1,1
    800057b0:	f7040513          	add	a0,s0,-144
    800057b4:	00000097          	auipc	ra,0x0
    800057b8:	806080e7          	jalr	-2042(ra) # 80004fba <create>
    800057bc:	cd11                	beqz	a0,800057d8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	136080e7          	jalr	310(ra) # 800038f4 <iunlockput>
  end_op();
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	8ec080e7          	jalr	-1812(ra) # 800040b2 <end_op>
  return 0;
    800057ce:	4501                	li	a0,0
}
    800057d0:	60aa                	ld	ra,136(sp)
    800057d2:	640a                	ld	s0,128(sp)
    800057d4:	6149                	add	sp,sp,144
    800057d6:	8082                	ret
    end_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	8da080e7          	jalr	-1830(ra) # 800040b2 <end_op>
    return -1;
    800057e0:	557d                	li	a0,-1
    800057e2:	b7fd                	j	800057d0 <sys_mkdir+0x4c>

00000000800057e4 <sys_mknod>:

uint64
sys_mknod(void)
{
    800057e4:	7135                	add	sp,sp,-160
    800057e6:	ed06                	sd	ra,152(sp)
    800057e8:	e922                	sd	s0,144(sp)
    800057ea:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	84c080e7          	jalr	-1972(ra) # 80004038 <begin_op>
  argint(1, &major);
    800057f4:	f6c40593          	add	a1,s0,-148
    800057f8:	4505                	li	a0,1
    800057fa:	ffffd097          	auipc	ra,0xffffd
    800057fe:	30c080e7          	jalr	780(ra) # 80002b06 <argint>
  argint(2, &minor);
    80005802:	f6840593          	add	a1,s0,-152
    80005806:	4509                	li	a0,2
    80005808:	ffffd097          	auipc	ra,0xffffd
    8000580c:	2fe080e7          	jalr	766(ra) # 80002b06 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005810:	08000613          	li	a2,128
    80005814:	f7040593          	add	a1,s0,-144
    80005818:	4501                	li	a0,0
    8000581a:	ffffd097          	auipc	ra,0xffffd
    8000581e:	32c080e7          	jalr	812(ra) # 80002b46 <argstr>
    80005822:	02054b63          	bltz	a0,80005858 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005826:	f6841683          	lh	a3,-152(s0)
    8000582a:	f6c41603          	lh	a2,-148(s0)
    8000582e:	458d                	li	a1,3
    80005830:	f7040513          	add	a0,s0,-144
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	786080e7          	jalr	1926(ra) # 80004fba <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000583c:	cd11                	beqz	a0,80005858 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	0b6080e7          	jalr	182(ra) # 800038f4 <iunlockput>
  end_op();
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	86c080e7          	jalr	-1940(ra) # 800040b2 <end_op>
  return 0;
    8000584e:	4501                	li	a0,0
}
    80005850:	60ea                	ld	ra,152(sp)
    80005852:	644a                	ld	s0,144(sp)
    80005854:	610d                	add	sp,sp,160
    80005856:	8082                	ret
    end_op();
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	85a080e7          	jalr	-1958(ra) # 800040b2 <end_op>
    return -1;
    80005860:	557d                	li	a0,-1
    80005862:	b7fd                	j	80005850 <sys_mknod+0x6c>

0000000080005864 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005864:	7135                	add	sp,sp,-160
    80005866:	ed06                	sd	ra,152(sp)
    80005868:	e922                	sd	s0,144(sp)
    8000586a:	e526                	sd	s1,136(sp)
    8000586c:	e14a                	sd	s2,128(sp)
    8000586e:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005870:	ffffc097          	auipc	ra,0xffffc
    80005874:	136080e7          	jalr	310(ra) # 800019a6 <myproc>
    80005878:	892a                	mv	s2,a0
  
  begin_op();
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	7be080e7          	jalr	1982(ra) # 80004038 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005882:	08000613          	li	a2,128
    80005886:	f6040593          	add	a1,s0,-160
    8000588a:	4501                	li	a0,0
    8000588c:	ffffd097          	auipc	ra,0xffffd
    80005890:	2ba080e7          	jalr	698(ra) # 80002b46 <argstr>
    80005894:	04054b63          	bltz	a0,800058ea <sys_chdir+0x86>
    80005898:	f6040513          	add	a0,s0,-160
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	59c080e7          	jalr	1436(ra) # 80003e38 <namei>
    800058a4:	84aa                	mv	s1,a0
    800058a6:	c131                	beqz	a0,800058ea <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	dea080e7          	jalr	-534(ra) # 80003692 <ilock>
  if(ip->type != T_DIR){
    800058b0:	04449703          	lh	a4,68(s1)
    800058b4:	4785                	li	a5,1
    800058b6:	04f71063          	bne	a4,a5,800058f6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800058ba:	8526                	mv	a0,s1
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	e98080e7          	jalr	-360(ra) # 80003754 <iunlock>
  iput(p->cwd);
    800058c4:	15093503          	ld	a0,336(s2)
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	f84080e7          	jalr	-124(ra) # 8000384c <iput>
  end_op();
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	7e2080e7          	jalr	2018(ra) # 800040b2 <end_op>
  p->cwd = ip;
    800058d8:	14993823          	sd	s1,336(s2)
  return 0;
    800058dc:	4501                	li	a0,0
}
    800058de:	60ea                	ld	ra,152(sp)
    800058e0:	644a                	ld	s0,144(sp)
    800058e2:	64aa                	ld	s1,136(sp)
    800058e4:	690a                	ld	s2,128(sp)
    800058e6:	610d                	add	sp,sp,160
    800058e8:	8082                	ret
    end_op();
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	7c8080e7          	jalr	1992(ra) # 800040b2 <end_op>
    return -1;
    800058f2:	557d                	li	a0,-1
    800058f4:	b7ed                	j	800058de <sys_chdir+0x7a>
    iunlockput(ip);
    800058f6:	8526                	mv	a0,s1
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	ffc080e7          	jalr	-4(ra) # 800038f4 <iunlockput>
    end_op();
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	7b2080e7          	jalr	1970(ra) # 800040b2 <end_op>
    return -1;
    80005908:	557d                	li	a0,-1
    8000590a:	bfd1                	j	800058de <sys_chdir+0x7a>

000000008000590c <sys_exec>:

uint64
sys_exec(void)
{
    8000590c:	7121                	add	sp,sp,-448
    8000590e:	ff06                	sd	ra,440(sp)
    80005910:	fb22                	sd	s0,432(sp)
    80005912:	f726                	sd	s1,424(sp)
    80005914:	f34a                	sd	s2,416(sp)
    80005916:	ef4e                	sd	s3,408(sp)
    80005918:	eb52                	sd	s4,400(sp)
    8000591a:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000591c:	e4840593          	add	a1,s0,-440
    80005920:	4505                	li	a0,1
    80005922:	ffffd097          	auipc	ra,0xffffd
    80005926:	204080e7          	jalr	516(ra) # 80002b26 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000592a:	08000613          	li	a2,128
    8000592e:	f5040593          	add	a1,s0,-176
    80005932:	4501                	li	a0,0
    80005934:	ffffd097          	auipc	ra,0xffffd
    80005938:	212080e7          	jalr	530(ra) # 80002b46 <argstr>
    8000593c:	87aa                	mv	a5,a0
    return -1;
    8000593e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005940:	0c07c263          	bltz	a5,80005a04 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005944:	10000613          	li	a2,256
    80005948:	4581                	li	a1,0
    8000594a:	e5040513          	add	a0,s0,-432
    8000594e:	ffffb097          	auipc	ra,0xffffb
    80005952:	380080e7          	jalr	896(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005956:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    8000595a:	89a6                	mv	s3,s1
    8000595c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000595e:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005962:	00391513          	sll	a0,s2,0x3
    80005966:	e4040593          	add	a1,s0,-448
    8000596a:	e4843783          	ld	a5,-440(s0)
    8000596e:	953e                	add	a0,a0,a5
    80005970:	ffffd097          	auipc	ra,0xffffd
    80005974:	0f8080e7          	jalr	248(ra) # 80002a68 <fetchaddr>
    80005978:	02054a63          	bltz	a0,800059ac <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    8000597c:	e4043783          	ld	a5,-448(s0)
    80005980:	c3b9                	beqz	a5,800059c6 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005982:	ffffb097          	auipc	ra,0xffffb
    80005986:	160080e7          	jalr	352(ra) # 80000ae2 <kalloc>
    8000598a:	85aa                	mv	a1,a0
    8000598c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005990:	cd11                	beqz	a0,800059ac <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005992:	6605                	lui	a2,0x1
    80005994:	e4043503          	ld	a0,-448(s0)
    80005998:	ffffd097          	auipc	ra,0xffffd
    8000599c:	122080e7          	jalr	290(ra) # 80002aba <fetchstr>
    800059a0:	00054663          	bltz	a0,800059ac <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    800059a4:	0905                	add	s2,s2,1
    800059a6:	09a1                	add	s3,s3,8
    800059a8:	fb491de3          	bne	s2,s4,80005962 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059ac:	f5040913          	add	s2,s0,-176
    800059b0:	6088                	ld	a0,0(s1)
    800059b2:	c921                	beqz	a0,80005a02 <sys_exec+0xf6>
    kfree(argv[i]);
    800059b4:	ffffb097          	auipc	ra,0xffffb
    800059b8:	030080e7          	jalr	48(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059bc:	04a1                	add	s1,s1,8
    800059be:	ff2499e3          	bne	s1,s2,800059b0 <sys_exec+0xa4>
  return -1;
    800059c2:	557d                	li	a0,-1
    800059c4:	a081                	j	80005a04 <sys_exec+0xf8>
      argv[i] = 0;
    800059c6:	0009079b          	sext.w	a5,s2
    800059ca:	078e                	sll	a5,a5,0x3
    800059cc:	fd078793          	add	a5,a5,-48
    800059d0:	97a2                	add	a5,a5,s0
    800059d2:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    800059d6:	e5040593          	add	a1,s0,-432
    800059da:	f5040513          	add	a0,s0,-176
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	194080e7          	jalr	404(ra) # 80004b72 <exec>
    800059e6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059e8:	f5040993          	add	s3,s0,-176
    800059ec:	6088                	ld	a0,0(s1)
    800059ee:	c901                	beqz	a0,800059fe <sys_exec+0xf2>
    kfree(argv[i]);
    800059f0:	ffffb097          	auipc	ra,0xffffb
    800059f4:	ff4080e7          	jalr	-12(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059f8:	04a1                	add	s1,s1,8
    800059fa:	ff3499e3          	bne	s1,s3,800059ec <sys_exec+0xe0>
  return ret;
    800059fe:	854a                	mv	a0,s2
    80005a00:	a011                	j	80005a04 <sys_exec+0xf8>
  return -1;
    80005a02:	557d                	li	a0,-1
}
    80005a04:	70fa                	ld	ra,440(sp)
    80005a06:	745a                	ld	s0,432(sp)
    80005a08:	74ba                	ld	s1,424(sp)
    80005a0a:	791a                	ld	s2,416(sp)
    80005a0c:	69fa                	ld	s3,408(sp)
    80005a0e:	6a5a                	ld	s4,400(sp)
    80005a10:	6139                	add	sp,sp,448
    80005a12:	8082                	ret

0000000080005a14 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a14:	7139                	add	sp,sp,-64
    80005a16:	fc06                	sd	ra,56(sp)
    80005a18:	f822                	sd	s0,48(sp)
    80005a1a:	f426                	sd	s1,40(sp)
    80005a1c:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a1e:	ffffc097          	auipc	ra,0xffffc
    80005a22:	f88080e7          	jalr	-120(ra) # 800019a6 <myproc>
    80005a26:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005a28:	fd840593          	add	a1,s0,-40
    80005a2c:	4501                	li	a0,0
    80005a2e:	ffffd097          	auipc	ra,0xffffd
    80005a32:	0f8080e7          	jalr	248(ra) # 80002b26 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005a36:	fc840593          	add	a1,s0,-56
    80005a3a:	fd040513          	add	a0,s0,-48
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	dea080e7          	jalr	-534(ra) # 80004828 <pipealloc>
    return -1;
    80005a46:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a48:	0c054463          	bltz	a0,80005b10 <sys_pipe+0xfc>
  fd0 = -1;
    80005a4c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a50:	fd043503          	ld	a0,-48(s0)
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	524080e7          	jalr	1316(ra) # 80004f78 <fdalloc>
    80005a5c:	fca42223          	sw	a0,-60(s0)
    80005a60:	08054b63          	bltz	a0,80005af6 <sys_pipe+0xe2>
    80005a64:	fc843503          	ld	a0,-56(s0)
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	510080e7          	jalr	1296(ra) # 80004f78 <fdalloc>
    80005a70:	fca42023          	sw	a0,-64(s0)
    80005a74:	06054863          	bltz	a0,80005ae4 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a78:	4691                	li	a3,4
    80005a7a:	fc440613          	add	a2,s0,-60
    80005a7e:	fd843583          	ld	a1,-40(s0)
    80005a82:	68a8                	ld	a0,80(s1)
    80005a84:	ffffc097          	auipc	ra,0xffffc
    80005a88:	be2080e7          	jalr	-1054(ra) # 80001666 <copyout>
    80005a8c:	02054063          	bltz	a0,80005aac <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a90:	4691                	li	a3,4
    80005a92:	fc040613          	add	a2,s0,-64
    80005a96:	fd843583          	ld	a1,-40(s0)
    80005a9a:	0591                	add	a1,a1,4
    80005a9c:	68a8                	ld	a0,80(s1)
    80005a9e:	ffffc097          	auipc	ra,0xffffc
    80005aa2:	bc8080e7          	jalr	-1080(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005aa6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005aa8:	06055463          	bgez	a0,80005b10 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005aac:	fc442783          	lw	a5,-60(s0)
    80005ab0:	07e9                	add	a5,a5,26
    80005ab2:	078e                	sll	a5,a5,0x3
    80005ab4:	97a6                	add	a5,a5,s1
    80005ab6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005aba:	fc042783          	lw	a5,-64(s0)
    80005abe:	07e9                	add	a5,a5,26
    80005ac0:	078e                	sll	a5,a5,0x3
    80005ac2:	94be                	add	s1,s1,a5
    80005ac4:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ac8:	fd043503          	ld	a0,-48(s0)
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	a30080e7          	jalr	-1488(ra) # 800044fc <fileclose>
    fileclose(wf);
    80005ad4:	fc843503          	ld	a0,-56(s0)
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	a24080e7          	jalr	-1500(ra) # 800044fc <fileclose>
    return -1;
    80005ae0:	57fd                	li	a5,-1
    80005ae2:	a03d                	j	80005b10 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005ae4:	fc442783          	lw	a5,-60(s0)
    80005ae8:	0007c763          	bltz	a5,80005af6 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005aec:	07e9                	add	a5,a5,26
    80005aee:	078e                	sll	a5,a5,0x3
    80005af0:	97a6                	add	a5,a5,s1
    80005af2:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005af6:	fd043503          	ld	a0,-48(s0)
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	a02080e7          	jalr	-1534(ra) # 800044fc <fileclose>
    fileclose(wf);
    80005b02:	fc843503          	ld	a0,-56(s0)
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	9f6080e7          	jalr	-1546(ra) # 800044fc <fileclose>
    return -1;
    80005b0e:	57fd                	li	a5,-1
}
    80005b10:	853e                	mv	a0,a5
    80005b12:	70e2                	ld	ra,56(sp)
    80005b14:	7442                	ld	s0,48(sp)
    80005b16:	74a2                	ld	s1,40(sp)
    80005b18:	6121                	add	sp,sp,64
    80005b1a:	8082                	ret
    80005b1c:	0000                	unimp
	...

0000000080005b20 <kernelvec>:
    80005b20:	7111                	add	sp,sp,-256
    80005b22:	e006                	sd	ra,0(sp)
    80005b24:	e40a                	sd	sp,8(sp)
    80005b26:	e80e                	sd	gp,16(sp)
    80005b28:	ec12                	sd	tp,24(sp)
    80005b2a:	f016                	sd	t0,32(sp)
    80005b2c:	f41a                	sd	t1,40(sp)
    80005b2e:	f81e                	sd	t2,48(sp)
    80005b30:	fc22                	sd	s0,56(sp)
    80005b32:	e0a6                	sd	s1,64(sp)
    80005b34:	e4aa                	sd	a0,72(sp)
    80005b36:	e8ae                	sd	a1,80(sp)
    80005b38:	ecb2                	sd	a2,88(sp)
    80005b3a:	f0b6                	sd	a3,96(sp)
    80005b3c:	f4ba                	sd	a4,104(sp)
    80005b3e:	f8be                	sd	a5,112(sp)
    80005b40:	fcc2                	sd	a6,120(sp)
    80005b42:	e146                	sd	a7,128(sp)
    80005b44:	e54a                	sd	s2,136(sp)
    80005b46:	e94e                	sd	s3,144(sp)
    80005b48:	ed52                	sd	s4,152(sp)
    80005b4a:	f156                	sd	s5,160(sp)
    80005b4c:	f55a                	sd	s6,168(sp)
    80005b4e:	f95e                	sd	s7,176(sp)
    80005b50:	fd62                	sd	s8,184(sp)
    80005b52:	e1e6                	sd	s9,192(sp)
    80005b54:	e5ea                	sd	s10,200(sp)
    80005b56:	e9ee                	sd	s11,208(sp)
    80005b58:	edf2                	sd	t3,216(sp)
    80005b5a:	f1f6                	sd	t4,224(sp)
    80005b5c:	f5fa                	sd	t5,232(sp)
    80005b5e:	f9fe                	sd	t6,240(sp)
    80005b60:	dd5fc0ef          	jal	80002934 <kerneltrap>
    80005b64:	6082                	ld	ra,0(sp)
    80005b66:	6122                	ld	sp,8(sp)
    80005b68:	61c2                	ld	gp,16(sp)
    80005b6a:	7282                	ld	t0,32(sp)
    80005b6c:	7322                	ld	t1,40(sp)
    80005b6e:	73c2                	ld	t2,48(sp)
    80005b70:	7462                	ld	s0,56(sp)
    80005b72:	6486                	ld	s1,64(sp)
    80005b74:	6526                	ld	a0,72(sp)
    80005b76:	65c6                	ld	a1,80(sp)
    80005b78:	6666                	ld	a2,88(sp)
    80005b7a:	7686                	ld	a3,96(sp)
    80005b7c:	7726                	ld	a4,104(sp)
    80005b7e:	77c6                	ld	a5,112(sp)
    80005b80:	7866                	ld	a6,120(sp)
    80005b82:	688a                	ld	a7,128(sp)
    80005b84:	692a                	ld	s2,136(sp)
    80005b86:	69ca                	ld	s3,144(sp)
    80005b88:	6a6a                	ld	s4,152(sp)
    80005b8a:	7a8a                	ld	s5,160(sp)
    80005b8c:	7b2a                	ld	s6,168(sp)
    80005b8e:	7bca                	ld	s7,176(sp)
    80005b90:	7c6a                	ld	s8,184(sp)
    80005b92:	6c8e                	ld	s9,192(sp)
    80005b94:	6d2e                	ld	s10,200(sp)
    80005b96:	6dce                	ld	s11,208(sp)
    80005b98:	6e6e                	ld	t3,216(sp)
    80005b9a:	7e8e                	ld	t4,224(sp)
    80005b9c:	7f2e                	ld	t5,232(sp)
    80005b9e:	7fce                	ld	t6,240(sp)
    80005ba0:	6111                	add	sp,sp,256
    80005ba2:	10200073          	sret
    80005ba6:	00000013          	nop
    80005baa:	00000013          	nop
    80005bae:	0001                	nop

0000000080005bb0 <timervec>:
    80005bb0:	34051573          	csrrw	a0,mscratch,a0
    80005bb4:	e10c                	sd	a1,0(a0)
    80005bb6:	e510                	sd	a2,8(a0)
    80005bb8:	e914                	sd	a3,16(a0)
    80005bba:	6d0c                	ld	a1,24(a0)
    80005bbc:	7110                	ld	a2,32(a0)
    80005bbe:	6194                	ld	a3,0(a1)
    80005bc0:	96b2                	add	a3,a3,a2
    80005bc2:	e194                	sd	a3,0(a1)
    80005bc4:	4589                	li	a1,2
    80005bc6:	14459073          	csrw	sip,a1
    80005bca:	6914                	ld	a3,16(a0)
    80005bcc:	6510                	ld	a2,8(a0)
    80005bce:	610c                	ld	a1,0(a0)
    80005bd0:	34051573          	csrrw	a0,mscratch,a0
    80005bd4:	30200073          	mret
	...

0000000080005bda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005bda:	1141                	add	sp,sp,-16
    80005bdc:	e422                	sd	s0,8(sp)
    80005bde:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005be0:	0c0007b7          	lui	a5,0xc000
    80005be4:	4705                	li	a4,1
    80005be6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005be8:	c3d8                	sw	a4,4(a5)
}
    80005bea:	6422                	ld	s0,8(sp)
    80005bec:	0141                	add	sp,sp,16
    80005bee:	8082                	ret

0000000080005bf0 <plicinithart>:

void
plicinithart(void)
{
    80005bf0:	1141                	add	sp,sp,-16
    80005bf2:	e406                	sd	ra,8(sp)
    80005bf4:	e022                	sd	s0,0(sp)
    80005bf6:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005bf8:	ffffc097          	auipc	ra,0xffffc
    80005bfc:	d82080e7          	jalr	-638(ra) # 8000197a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c00:	0085171b          	sllw	a4,a0,0x8
    80005c04:	0c0027b7          	lui	a5,0xc002
    80005c08:	97ba                	add	a5,a5,a4
    80005c0a:	40200713          	li	a4,1026
    80005c0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c12:	00d5151b          	sllw	a0,a0,0xd
    80005c16:	0c2017b7          	lui	a5,0xc201
    80005c1a:	97aa                	add	a5,a5,a0
    80005c1c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005c20:	60a2                	ld	ra,8(sp)
    80005c22:	6402                	ld	s0,0(sp)
    80005c24:	0141                	add	sp,sp,16
    80005c26:	8082                	ret

0000000080005c28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c28:	1141                	add	sp,sp,-16
    80005c2a:	e406                	sd	ra,8(sp)
    80005c2c:	e022                	sd	s0,0(sp)
    80005c2e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005c30:	ffffc097          	auipc	ra,0xffffc
    80005c34:	d4a080e7          	jalr	-694(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c38:	00d5151b          	sllw	a0,a0,0xd
    80005c3c:	0c2017b7          	lui	a5,0xc201
    80005c40:	97aa                	add	a5,a5,a0
  return irq;
}
    80005c42:	43c8                	lw	a0,4(a5)
    80005c44:	60a2                	ld	ra,8(sp)
    80005c46:	6402                	ld	s0,0(sp)
    80005c48:	0141                	add	sp,sp,16
    80005c4a:	8082                	ret

0000000080005c4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c4c:	1101                	add	sp,sp,-32
    80005c4e:	ec06                	sd	ra,24(sp)
    80005c50:	e822                	sd	s0,16(sp)
    80005c52:	e426                	sd	s1,8(sp)
    80005c54:	1000                	add	s0,sp,32
    80005c56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c58:	ffffc097          	auipc	ra,0xffffc
    80005c5c:	d22080e7          	jalr	-734(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c60:	00d5151b          	sllw	a0,a0,0xd
    80005c64:	0c2017b7          	lui	a5,0xc201
    80005c68:	97aa                	add	a5,a5,a0
    80005c6a:	c3c4                	sw	s1,4(a5)
}
    80005c6c:	60e2                	ld	ra,24(sp)
    80005c6e:	6442                	ld	s0,16(sp)
    80005c70:	64a2                	ld	s1,8(sp)
    80005c72:	6105                	add	sp,sp,32
    80005c74:	8082                	ret

0000000080005c76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c76:	1141                	add	sp,sp,-16
    80005c78:	e406                	sd	ra,8(sp)
    80005c7a:	e022                	sd	s0,0(sp)
    80005c7c:	0800                	add	s0,sp,16
  if(i >= NUM)
    80005c7e:	479d                	li	a5,7
    80005c80:	04a7cc63          	blt	a5,a0,80005cd8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005c84:	0001c797          	auipc	a5,0x1c
    80005c88:	f8c78793          	add	a5,a5,-116 # 80021c10 <disk>
    80005c8c:	97aa                	add	a5,a5,a0
    80005c8e:	0187c783          	lbu	a5,24(a5)
    80005c92:	ebb9                	bnez	a5,80005ce8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c94:	00451693          	sll	a3,a0,0x4
    80005c98:	0001c797          	auipc	a5,0x1c
    80005c9c:	f7878793          	add	a5,a5,-136 # 80021c10 <disk>
    80005ca0:	6398                	ld	a4,0(a5)
    80005ca2:	9736                	add	a4,a4,a3
    80005ca4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005ca8:	6398                	ld	a4,0(a5)
    80005caa:	9736                	add	a4,a4,a3
    80005cac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005cb0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005cb4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005cb8:	97aa                	add	a5,a5,a0
    80005cba:	4705                	li	a4,1
    80005cbc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005cc0:	0001c517          	auipc	a0,0x1c
    80005cc4:	f6850513          	add	a0,a0,-152 # 80021c28 <disk+0x18>
    80005cc8:	ffffc097          	auipc	ra,0xffffc
    80005ccc:	3ea080e7          	jalr	1002(ra) # 800020b2 <wakeup>
}
    80005cd0:	60a2                	ld	ra,8(sp)
    80005cd2:	6402                	ld	s0,0(sp)
    80005cd4:	0141                	add	sp,sp,16
    80005cd6:	8082                	ret
    panic("free_desc 1");
    80005cd8:	00003517          	auipc	a0,0x3
    80005cdc:	a7050513          	add	a0,a0,-1424 # 80008748 <syscalls+0x2f8>
    80005ce0:	ffffb097          	auipc	ra,0xffffb
    80005ce4:	85c080e7          	jalr	-1956(ra) # 8000053c <panic>
    panic("free_desc 2");
    80005ce8:	00003517          	auipc	a0,0x3
    80005cec:	a7050513          	add	a0,a0,-1424 # 80008758 <syscalls+0x308>
    80005cf0:	ffffb097          	auipc	ra,0xffffb
    80005cf4:	84c080e7          	jalr	-1972(ra) # 8000053c <panic>

0000000080005cf8 <virtio_disk_init>:
{
    80005cf8:	1101                	add	sp,sp,-32
    80005cfa:	ec06                	sd	ra,24(sp)
    80005cfc:	e822                	sd	s0,16(sp)
    80005cfe:	e426                	sd	s1,8(sp)
    80005d00:	e04a                	sd	s2,0(sp)
    80005d02:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d04:	00003597          	auipc	a1,0x3
    80005d08:	a6458593          	add	a1,a1,-1436 # 80008768 <syscalls+0x318>
    80005d0c:	0001c517          	auipc	a0,0x1c
    80005d10:	02c50513          	add	a0,a0,44 # 80021d38 <disk+0x128>
    80005d14:	ffffb097          	auipc	ra,0xffffb
    80005d18:	e2e080e7          	jalr	-466(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d1c:	100017b7          	lui	a5,0x10001
    80005d20:	4398                	lw	a4,0(a5)
    80005d22:	2701                	sext.w	a4,a4
    80005d24:	747277b7          	lui	a5,0x74727
    80005d28:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d2c:	14f71b63          	bne	a4,a5,80005e82 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005d30:	100017b7          	lui	a5,0x10001
    80005d34:	43dc                	lw	a5,4(a5)
    80005d36:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d38:	4709                	li	a4,2
    80005d3a:	14e79463          	bne	a5,a4,80005e82 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d3e:	100017b7          	lui	a5,0x10001
    80005d42:	479c                	lw	a5,8(a5)
    80005d44:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005d46:	12e79e63          	bne	a5,a4,80005e82 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d4a:	100017b7          	lui	a5,0x10001
    80005d4e:	47d8                	lw	a4,12(a5)
    80005d50:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d52:	554d47b7          	lui	a5,0x554d4
    80005d56:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d5a:	12f71463          	bne	a4,a5,80005e82 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d5e:	100017b7          	lui	a5,0x10001
    80005d62:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d66:	4705                	li	a4,1
    80005d68:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d6a:	470d                	li	a4,3
    80005d6c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d6e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d70:	c7ffe6b7          	lui	a3,0xc7ffe
    80005d74:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdca0f>
    80005d78:	8f75                	and	a4,a4,a3
    80005d7a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d7c:	472d                	li	a4,11
    80005d7e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005d80:	5bbc                	lw	a5,112(a5)
    80005d82:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005d86:	8ba1                	and	a5,a5,8
    80005d88:	10078563          	beqz	a5,80005e92 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d8c:	100017b7          	lui	a5,0x10001
    80005d90:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005d94:	43fc                	lw	a5,68(a5)
    80005d96:	2781                	sext.w	a5,a5
    80005d98:	10079563          	bnez	a5,80005ea2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d9c:	100017b7          	lui	a5,0x10001
    80005da0:	5bdc                	lw	a5,52(a5)
    80005da2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005da4:	10078763          	beqz	a5,80005eb2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005da8:	471d                	li	a4,7
    80005daa:	10f77c63          	bgeu	a4,a5,80005ec2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005dae:	ffffb097          	auipc	ra,0xffffb
    80005db2:	d34080e7          	jalr	-716(ra) # 80000ae2 <kalloc>
    80005db6:	0001c497          	auipc	s1,0x1c
    80005dba:	e5a48493          	add	s1,s1,-422 # 80021c10 <disk>
    80005dbe:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005dc0:	ffffb097          	auipc	ra,0xffffb
    80005dc4:	d22080e7          	jalr	-734(ra) # 80000ae2 <kalloc>
    80005dc8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005dca:	ffffb097          	auipc	ra,0xffffb
    80005dce:	d18080e7          	jalr	-744(ra) # 80000ae2 <kalloc>
    80005dd2:	87aa                	mv	a5,a0
    80005dd4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005dd6:	6088                	ld	a0,0(s1)
    80005dd8:	cd6d                	beqz	a0,80005ed2 <virtio_disk_init+0x1da>
    80005dda:	0001c717          	auipc	a4,0x1c
    80005dde:	e3e73703          	ld	a4,-450(a4) # 80021c18 <disk+0x8>
    80005de2:	cb65                	beqz	a4,80005ed2 <virtio_disk_init+0x1da>
    80005de4:	c7fd                	beqz	a5,80005ed2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005de6:	6605                	lui	a2,0x1
    80005de8:	4581                	li	a1,0
    80005dea:	ffffb097          	auipc	ra,0xffffb
    80005dee:	ee4080e7          	jalr	-284(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80005df2:	0001c497          	auipc	s1,0x1c
    80005df6:	e1e48493          	add	s1,s1,-482 # 80021c10 <disk>
    80005dfa:	6605                	lui	a2,0x1
    80005dfc:	4581                	li	a1,0
    80005dfe:	6488                	ld	a0,8(s1)
    80005e00:	ffffb097          	auipc	ra,0xffffb
    80005e04:	ece080e7          	jalr	-306(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80005e08:	6605                	lui	a2,0x1
    80005e0a:	4581                	li	a1,0
    80005e0c:	6888                	ld	a0,16(s1)
    80005e0e:	ffffb097          	auipc	ra,0xffffb
    80005e12:	ec0080e7          	jalr	-320(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e16:	100017b7          	lui	a5,0x10001
    80005e1a:	4721                	li	a4,8
    80005e1c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005e1e:	4098                	lw	a4,0(s1)
    80005e20:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005e24:	40d8                	lw	a4,4(s1)
    80005e26:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005e2a:	6498                	ld	a4,8(s1)
    80005e2c:	0007069b          	sext.w	a3,a4
    80005e30:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005e34:	9701                	sra	a4,a4,0x20
    80005e36:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005e3a:	6898                	ld	a4,16(s1)
    80005e3c:	0007069b          	sext.w	a3,a4
    80005e40:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005e44:	9701                	sra	a4,a4,0x20
    80005e46:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005e4a:	4705                	li	a4,1
    80005e4c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005e4e:	00e48c23          	sb	a4,24(s1)
    80005e52:	00e48ca3          	sb	a4,25(s1)
    80005e56:	00e48d23          	sb	a4,26(s1)
    80005e5a:	00e48da3          	sb	a4,27(s1)
    80005e5e:	00e48e23          	sb	a4,28(s1)
    80005e62:	00e48ea3          	sb	a4,29(s1)
    80005e66:	00e48f23          	sb	a4,30(s1)
    80005e6a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005e6e:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e72:	0727a823          	sw	s2,112(a5)
}
    80005e76:	60e2                	ld	ra,24(sp)
    80005e78:	6442                	ld	s0,16(sp)
    80005e7a:	64a2                	ld	s1,8(sp)
    80005e7c:	6902                	ld	s2,0(sp)
    80005e7e:	6105                	add	sp,sp,32
    80005e80:	8082                	ret
    panic("could not find virtio disk");
    80005e82:	00003517          	auipc	a0,0x3
    80005e86:	8f650513          	add	a0,a0,-1802 # 80008778 <syscalls+0x328>
    80005e8a:	ffffa097          	auipc	ra,0xffffa
    80005e8e:	6b2080e7          	jalr	1714(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80005e92:	00003517          	auipc	a0,0x3
    80005e96:	90650513          	add	a0,a0,-1786 # 80008798 <syscalls+0x348>
    80005e9a:	ffffa097          	auipc	ra,0xffffa
    80005e9e:	6a2080e7          	jalr	1698(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80005ea2:	00003517          	auipc	a0,0x3
    80005ea6:	91650513          	add	a0,a0,-1770 # 800087b8 <syscalls+0x368>
    80005eaa:	ffffa097          	auipc	ra,0xffffa
    80005eae:	692080e7          	jalr	1682(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80005eb2:	00003517          	auipc	a0,0x3
    80005eb6:	92650513          	add	a0,a0,-1754 # 800087d8 <syscalls+0x388>
    80005eba:	ffffa097          	auipc	ra,0xffffa
    80005ebe:	682080e7          	jalr	1666(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80005ec2:	00003517          	auipc	a0,0x3
    80005ec6:	93650513          	add	a0,a0,-1738 # 800087f8 <syscalls+0x3a8>
    80005eca:	ffffa097          	auipc	ra,0xffffa
    80005ece:	672080e7          	jalr	1650(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80005ed2:	00003517          	auipc	a0,0x3
    80005ed6:	94650513          	add	a0,a0,-1722 # 80008818 <syscalls+0x3c8>
    80005eda:	ffffa097          	auipc	ra,0xffffa
    80005ede:	662080e7          	jalr	1634(ra) # 8000053c <panic>

0000000080005ee2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ee2:	7159                	add	sp,sp,-112
    80005ee4:	f486                	sd	ra,104(sp)
    80005ee6:	f0a2                	sd	s0,96(sp)
    80005ee8:	eca6                	sd	s1,88(sp)
    80005eea:	e8ca                	sd	s2,80(sp)
    80005eec:	e4ce                	sd	s3,72(sp)
    80005eee:	e0d2                	sd	s4,64(sp)
    80005ef0:	fc56                	sd	s5,56(sp)
    80005ef2:	f85a                	sd	s6,48(sp)
    80005ef4:	f45e                	sd	s7,40(sp)
    80005ef6:	f062                	sd	s8,32(sp)
    80005ef8:	ec66                	sd	s9,24(sp)
    80005efa:	e86a                	sd	s10,16(sp)
    80005efc:	1880                	add	s0,sp,112
    80005efe:	8a2a                	mv	s4,a0
    80005f00:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f02:	00c52c83          	lw	s9,12(a0)
    80005f06:	001c9c9b          	sllw	s9,s9,0x1
    80005f0a:	1c82                	sll	s9,s9,0x20
    80005f0c:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f10:	0001c517          	auipc	a0,0x1c
    80005f14:	e2850513          	add	a0,a0,-472 # 80021d38 <disk+0x128>
    80005f18:	ffffb097          	auipc	ra,0xffffb
    80005f1c:	cba080e7          	jalr	-838(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80005f20:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80005f22:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f24:	0001cb17          	auipc	s6,0x1c
    80005f28:	cecb0b13          	add	s6,s6,-788 # 80021c10 <disk>
  for(int i = 0; i < 3; i++){
    80005f2c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f2e:	0001cc17          	auipc	s8,0x1c
    80005f32:	e0ac0c13          	add	s8,s8,-502 # 80021d38 <disk+0x128>
    80005f36:	a095                	j	80005f9a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80005f38:	00fb0733          	add	a4,s6,a5
    80005f3c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f40:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80005f42:	0207c563          	bltz	a5,80005f6c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80005f46:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80005f48:	0591                	add	a1,a1,4
    80005f4a:	05560d63          	beq	a2,s5,80005fa4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80005f4e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80005f50:	0001c717          	auipc	a4,0x1c
    80005f54:	cc070713          	add	a4,a4,-832 # 80021c10 <disk>
    80005f58:	87ca                	mv	a5,s2
    if(disk.free[i]){
    80005f5a:	01874683          	lbu	a3,24(a4)
    80005f5e:	fee9                	bnez	a3,80005f38 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80005f60:	2785                	addw	a5,a5,1
    80005f62:	0705                	add	a4,a4,1
    80005f64:	fe979be3          	bne	a5,s1,80005f5a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80005f68:	57fd                	li	a5,-1
    80005f6a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    80005f6c:	00c05e63          	blez	a2,80005f88 <virtio_disk_rw+0xa6>
    80005f70:	060a                	sll	a2,a2,0x2
    80005f72:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80005f76:	0009a503          	lw	a0,0(s3)
    80005f7a:	00000097          	auipc	ra,0x0
    80005f7e:	cfc080e7          	jalr	-772(ra) # 80005c76 <free_desc>
      for(int j = 0; j < i; j++)
    80005f82:	0991                	add	s3,s3,4
    80005f84:	ffa999e3          	bne	s3,s10,80005f76 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f88:	85e2                	mv	a1,s8
    80005f8a:	0001c517          	auipc	a0,0x1c
    80005f8e:	c9e50513          	add	a0,a0,-866 # 80021c28 <disk+0x18>
    80005f92:	ffffc097          	auipc	ra,0xffffc
    80005f96:	0bc080e7          	jalr	188(ra) # 8000204e <sleep>
  for(int i = 0; i < 3; i++){
    80005f9a:	f9040993          	add	s3,s0,-112
{
    80005f9e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80005fa0:	864a                	mv	a2,s2
    80005fa2:	b775                	j	80005f4e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005fa4:	f9042503          	lw	a0,-112(s0)
    80005fa8:	00a50713          	add	a4,a0,10
    80005fac:	0712                	sll	a4,a4,0x4

  if(write)
    80005fae:	0001c797          	auipc	a5,0x1c
    80005fb2:	c6278793          	add	a5,a5,-926 # 80021c10 <disk>
    80005fb6:	00e786b3          	add	a3,a5,a4
    80005fba:	01703633          	snez	a2,s7
    80005fbe:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005fc0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80005fc4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005fc8:	f6070613          	add	a2,a4,-160
    80005fcc:	6394                	ld	a3,0(a5)
    80005fce:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005fd0:	00870593          	add	a1,a4,8
    80005fd4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005fd6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005fd8:	0007b803          	ld	a6,0(a5)
    80005fdc:	9642                	add	a2,a2,a6
    80005fde:	46c1                	li	a3,16
    80005fe0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005fe2:	4585                	li	a1,1
    80005fe4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80005fe8:	f9442683          	lw	a3,-108(s0)
    80005fec:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005ff0:	0692                	sll	a3,a3,0x4
    80005ff2:	9836                	add	a6,a6,a3
    80005ff4:	058a0613          	add	a2,s4,88
    80005ff8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80005ffc:	0007b803          	ld	a6,0(a5)
    80006000:	96c2                	add	a3,a3,a6
    80006002:	40000613          	li	a2,1024
    80006006:	c690                	sw	a2,8(a3)
  if(write)
    80006008:	001bb613          	seqz	a2,s7
    8000600c:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006010:	00166613          	or	a2,a2,1
    80006014:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006018:	f9842603          	lw	a2,-104(s0)
    8000601c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006020:	00250693          	add	a3,a0,2
    80006024:	0692                	sll	a3,a3,0x4
    80006026:	96be                	add	a3,a3,a5
    80006028:	58fd                	li	a7,-1
    8000602a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000602e:	0612                	sll	a2,a2,0x4
    80006030:	9832                	add	a6,a6,a2
    80006032:	f9070713          	add	a4,a4,-112
    80006036:	973e                	add	a4,a4,a5
    80006038:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000603c:	6398                	ld	a4,0(a5)
    8000603e:	9732                	add	a4,a4,a2
    80006040:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006042:	4609                	li	a2,2
    80006044:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006048:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000604c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006050:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006054:	6794                	ld	a3,8(a5)
    80006056:	0026d703          	lhu	a4,2(a3)
    8000605a:	8b1d                	and	a4,a4,7
    8000605c:	0706                	sll	a4,a4,0x1
    8000605e:	96ba                	add	a3,a3,a4
    80006060:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006064:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006068:	6798                	ld	a4,8(a5)
    8000606a:	00275783          	lhu	a5,2(a4)
    8000606e:	2785                	addw	a5,a5,1
    80006070:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006074:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006078:	100017b7          	lui	a5,0x10001
    8000607c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006080:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006084:	0001c917          	auipc	s2,0x1c
    80006088:	cb490913          	add	s2,s2,-844 # 80021d38 <disk+0x128>
  while(b->disk == 1) {
    8000608c:	4485                	li	s1,1
    8000608e:	00b79c63          	bne	a5,a1,800060a6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006092:	85ca                	mv	a1,s2
    80006094:	8552                	mv	a0,s4
    80006096:	ffffc097          	auipc	ra,0xffffc
    8000609a:	fb8080e7          	jalr	-72(ra) # 8000204e <sleep>
  while(b->disk == 1) {
    8000609e:	004a2783          	lw	a5,4(s4)
    800060a2:	fe9788e3          	beq	a5,s1,80006092 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800060a6:	f9042903          	lw	s2,-112(s0)
    800060aa:	00290713          	add	a4,s2,2
    800060ae:	0712                	sll	a4,a4,0x4
    800060b0:	0001c797          	auipc	a5,0x1c
    800060b4:	b6078793          	add	a5,a5,-1184 # 80021c10 <disk>
    800060b8:	97ba                	add	a5,a5,a4
    800060ba:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800060be:	0001c997          	auipc	s3,0x1c
    800060c2:	b5298993          	add	s3,s3,-1198 # 80021c10 <disk>
    800060c6:	00491713          	sll	a4,s2,0x4
    800060ca:	0009b783          	ld	a5,0(s3)
    800060ce:	97ba                	add	a5,a5,a4
    800060d0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800060d4:	854a                	mv	a0,s2
    800060d6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060da:	00000097          	auipc	ra,0x0
    800060de:	b9c080e7          	jalr	-1124(ra) # 80005c76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060e2:	8885                	and	s1,s1,1
    800060e4:	f0ed                	bnez	s1,800060c6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060e6:	0001c517          	auipc	a0,0x1c
    800060ea:	c5250513          	add	a0,a0,-942 # 80021d38 <disk+0x128>
    800060ee:	ffffb097          	auipc	ra,0xffffb
    800060f2:	b98080e7          	jalr	-1128(ra) # 80000c86 <release>
}
    800060f6:	70a6                	ld	ra,104(sp)
    800060f8:	7406                	ld	s0,96(sp)
    800060fa:	64e6                	ld	s1,88(sp)
    800060fc:	6946                	ld	s2,80(sp)
    800060fe:	69a6                	ld	s3,72(sp)
    80006100:	6a06                	ld	s4,64(sp)
    80006102:	7ae2                	ld	s5,56(sp)
    80006104:	7b42                	ld	s6,48(sp)
    80006106:	7ba2                	ld	s7,40(sp)
    80006108:	7c02                	ld	s8,32(sp)
    8000610a:	6ce2                	ld	s9,24(sp)
    8000610c:	6d42                	ld	s10,16(sp)
    8000610e:	6165                	add	sp,sp,112
    80006110:	8082                	ret

0000000080006112 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006112:	1101                	add	sp,sp,-32
    80006114:	ec06                	sd	ra,24(sp)
    80006116:	e822                	sd	s0,16(sp)
    80006118:	e426                	sd	s1,8(sp)
    8000611a:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000611c:	0001c497          	auipc	s1,0x1c
    80006120:	af448493          	add	s1,s1,-1292 # 80021c10 <disk>
    80006124:	0001c517          	auipc	a0,0x1c
    80006128:	c1450513          	add	a0,a0,-1004 # 80021d38 <disk+0x128>
    8000612c:	ffffb097          	auipc	ra,0xffffb
    80006130:	aa6080e7          	jalr	-1370(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006134:	10001737          	lui	a4,0x10001
    80006138:	533c                	lw	a5,96(a4)
    8000613a:	8b8d                	and	a5,a5,3
    8000613c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000613e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006142:	689c                	ld	a5,16(s1)
    80006144:	0204d703          	lhu	a4,32(s1)
    80006148:	0027d783          	lhu	a5,2(a5)
    8000614c:	04f70863          	beq	a4,a5,8000619c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006150:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006154:	6898                	ld	a4,16(s1)
    80006156:	0204d783          	lhu	a5,32(s1)
    8000615a:	8b9d                	and	a5,a5,7
    8000615c:	078e                	sll	a5,a5,0x3
    8000615e:	97ba                	add	a5,a5,a4
    80006160:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006162:	00278713          	add	a4,a5,2
    80006166:	0712                	sll	a4,a4,0x4
    80006168:	9726                	add	a4,a4,s1
    8000616a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000616e:	e721                	bnez	a4,800061b6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006170:	0789                	add	a5,a5,2
    80006172:	0792                	sll	a5,a5,0x4
    80006174:	97a6                	add	a5,a5,s1
    80006176:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006178:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000617c:	ffffc097          	auipc	ra,0xffffc
    80006180:	f36080e7          	jalr	-202(ra) # 800020b2 <wakeup>

    disk.used_idx += 1;
    80006184:	0204d783          	lhu	a5,32(s1)
    80006188:	2785                	addw	a5,a5,1
    8000618a:	17c2                	sll	a5,a5,0x30
    8000618c:	93c1                	srl	a5,a5,0x30
    8000618e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006192:	6898                	ld	a4,16(s1)
    80006194:	00275703          	lhu	a4,2(a4)
    80006198:	faf71ce3          	bne	a4,a5,80006150 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000619c:	0001c517          	auipc	a0,0x1c
    800061a0:	b9c50513          	add	a0,a0,-1124 # 80021d38 <disk+0x128>
    800061a4:	ffffb097          	auipc	ra,0xffffb
    800061a8:	ae2080e7          	jalr	-1310(ra) # 80000c86 <release>
}
    800061ac:	60e2                	ld	ra,24(sp)
    800061ae:	6442                	ld	s0,16(sp)
    800061b0:	64a2                	ld	s1,8(sp)
    800061b2:	6105                	add	sp,sp,32
    800061b4:	8082                	ret
      panic("virtio_disk_intr status");
    800061b6:	00002517          	auipc	a0,0x2
    800061ba:	67a50513          	add	a0,a0,1658 # 80008830 <syscalls+0x3e0>
    800061be:	ffffa097          	auipc	ra,0xffffa
    800061c2:	37e080e7          	jalr	894(ra) # 8000053c <panic>
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
