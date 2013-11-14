
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 b9 11 f0       	mov    $0xf011b970,%eax
f010004b:	2d 04 b3 11 f0       	sub    $0xf011b304,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 04 b3 11 f0       	push   $0xf011b304
f0100058:	e8 50 25 00 00       	call   f01025ad <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 7f 04 00 00       	call   f01004e1 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 2a 10 f0       	push   $0xf0102a00
f010006f:	e8 04 19 00 00       	call   f0101978 <cprintf>

	cprintf("------------\n");
f0100074:	c7 04 24 1b 2a 10 f0 	movl   $0xf0102a1b,(%esp)
f010007b:	e8 f8 18 00 00       	call   f0101978 <cprintf>
	cprintf("   \033[34mJ \033[32mO \033[31mS \033[37m!\n");
f0100080:	c7 04 24 5c 2a 10 f0 	movl   $0xf0102a5c,(%esp)
f0100087:	e8 ec 18 00 00       	call   f0101978 <cprintf>
	cprintf("------------\n");
f010008c:	c7 04 24 1b 2a 10 f0 	movl   $0xf0102a1b,(%esp)
f0100093:	e8 e0 18 00 00       	call   f0101978 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100098:	e8 b4 0d 00 00       	call   f0100e51 <mem_init>
f010009d:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000a0:	83 ec 0c             	sub    $0xc,%esp
f01000a3:	6a 00                	push   $0x0
f01000a5:	e8 16 07 00 00       	call   f01007c0 <monitor>
f01000aa:	83 c4 10             	add    $0x10,%esp
f01000ad:	eb f1                	jmp    f01000a0 <i386_init+0x60>

f01000af <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000af:	55                   	push   %ebp
f01000b0:	89 e5                	mov    %esp,%ebp
f01000b2:	56                   	push   %esi
f01000b3:	53                   	push   %ebx
f01000b4:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000b7:	83 3d 60 b9 11 f0 00 	cmpl   $0x0,0xf011b960
f01000be:	75 37                	jne    f01000f7 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000c0:	89 35 60 b9 11 f0    	mov    %esi,0xf011b960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000c6:	fa                   	cli    
f01000c7:	fc                   	cld    

	va_start(ap, fmt);
f01000c8:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000cb:	83 ec 04             	sub    $0x4,%esp
f01000ce:	ff 75 0c             	pushl  0xc(%ebp)
f01000d1:	ff 75 08             	pushl  0x8(%ebp)
f01000d4:	68 29 2a 10 f0       	push   $0xf0102a29
f01000d9:	e8 9a 18 00 00       	call   f0101978 <cprintf>
	vcprintf(fmt, ap);
f01000de:	83 c4 08             	add    $0x8,%esp
f01000e1:	53                   	push   %ebx
f01000e2:	56                   	push   %esi
f01000e3:	e8 6a 18 00 00       	call   f0101952 <vcprintf>
	cprintf("\n");
f01000e8:	c7 04 24 86 2a 10 f0 	movl   $0xf0102a86,(%esp)
f01000ef:	e8 84 18 00 00       	call   f0101978 <cprintf>
	va_end(ap);
f01000f4:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000f7:	83 ec 0c             	sub    $0xc,%esp
f01000fa:	6a 00                	push   $0x0
f01000fc:	e8 bf 06 00 00       	call   f01007c0 <monitor>
f0100101:	83 c4 10             	add    $0x10,%esp
f0100104:	eb f1                	jmp    f01000f7 <_panic+0x48>

f0100106 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100106:	55                   	push   %ebp
f0100107:	89 e5                	mov    %esp,%ebp
f0100109:	53                   	push   %ebx
f010010a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010010d:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100110:	ff 75 0c             	pushl  0xc(%ebp)
f0100113:	ff 75 08             	pushl  0x8(%ebp)
f0100116:	68 41 2a 10 f0       	push   $0xf0102a41
f010011b:	e8 58 18 00 00       	call   f0101978 <cprintf>
	vcprintf(fmt, ap);
f0100120:	83 c4 08             	add    $0x8,%esp
f0100123:	53                   	push   %ebx
f0100124:	ff 75 10             	pushl  0x10(%ebp)
f0100127:	e8 26 18 00 00       	call   f0101952 <vcprintf>
	cprintf("\n");
f010012c:	c7 04 24 86 2a 10 f0 	movl   $0xf0102a86,(%esp)
f0100133:	e8 40 18 00 00       	call   f0101978 <cprintf>
	va_end(ap);
f0100138:	83 c4 10             	add    $0x10,%esp
}
f010013b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010013e:	c9                   	leave  
f010013f:	c3                   	ret    

f0100140 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba 84 00 00 00       	mov    $0x84,%edx
f0100148:	ec                   	in     (%dx),%al
f0100149:	ec                   	in     (%dx),%al
f010014a:	ec                   	in     (%dx),%al
f010014b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010014c:	c9                   	leave  
f010014d:	c3                   	ret    

f010014e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
f0100151:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100156:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100157:	a8 01                	test   $0x1,%al
f0100159:	74 08                	je     f0100163 <serial_proc_data+0x15>
f010015b:	b2 f8                	mov    $0xf8,%dl
f010015d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010015e:	0f b6 c0             	movzbl %al,%eax
f0100161:	eb 05                	jmp    f0100168 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100163:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100168:	c9                   	leave  
f0100169:	c3                   	ret    

f010016a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016a:	55                   	push   %ebp
f010016b:	89 e5                	mov    %esp,%ebp
f010016d:	53                   	push   %ebx
f010016e:	83 ec 04             	sub    $0x4,%esp
f0100171:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100173:	eb 29                	jmp    f010019e <cons_intr+0x34>
		if (c == 0)
f0100175:	85 c0                	test   %eax,%eax
f0100177:	74 25                	je     f010019e <cons_intr+0x34>
			continue;
		cons.buf[cons.wpos++] = c;
f0100179:	8b 15 44 b5 11 f0    	mov    0xf011b544,%edx
f010017f:	88 82 40 b3 11 f0    	mov    %al,-0xfee4cc0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
f0100188:	a3 44 b5 11 f0       	mov    %eax,0xf011b544
		if (cons.wpos == CONSBUFSIZE)
f010018d:	3d 00 02 00 00       	cmp    $0x200,%eax
f0100192:	75 0a                	jne    f010019e <cons_intr+0x34>
			cons.wpos = 0;
f0100194:	c7 05 44 b5 11 f0 00 	movl   $0x0,0xf011b544
f010019b:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010019e:	ff d3                	call   *%ebx
f01001a0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001a3:	75 d0                	jne    f0100175 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001a5:	83 c4 04             	add    $0x4,%esp
f01001a8:	5b                   	pop    %ebx
f01001a9:	c9                   	leave  
f01001aa:	c3                   	ret    

f01001ab <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001ab:	55                   	push   %ebp
f01001ac:	89 e5                	mov    %esp,%ebp
f01001ae:	57                   	push   %edi
f01001af:	56                   	push   %esi
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 0c             	sub    $0xc,%esp
f01001b4:	89 c6                	mov    %eax,%esi
f01001b6:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001bb:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001bc:	a8 20                	test   $0x20,%al
f01001be:	75 19                	jne    f01001d9 <cons_putc+0x2e>
f01001c0:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001c5:	bf fd 03 00 00       	mov    $0x3fd,%edi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001ca:	e8 71 ff ff ff       	call   f0100140 <delay>
f01001cf:	89 fa                	mov    %edi,%edx
f01001d1:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001d2:	a8 20                	test   $0x20,%al
f01001d4:	75 03                	jne    f01001d9 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001d6:	4b                   	dec    %ebx
f01001d7:	75 f1                	jne    f01001ca <cons_putc+0x1f>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001d9:	89 f7                	mov    %esi,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001db:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001e0:	89 f0                	mov    %esi,%eax
f01001e2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e3:	b2 79                	mov    $0x79,%dl
f01001e5:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001e6:	84 c0                	test   %al,%al
f01001e8:	78 1d                	js     f0100207 <cons_putc+0x5c>
f01001ea:	bb 00 00 00 00       	mov    $0x0,%ebx
		delay();
f01001ef:	e8 4c ff ff ff       	call   f0100140 <delay>
f01001f4:	ba 79 03 00 00       	mov    $0x379,%edx
f01001f9:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001fa:	84 c0                	test   %al,%al
f01001fc:	78 09                	js     f0100207 <cons_putc+0x5c>
f01001fe:	43                   	inc    %ebx
f01001ff:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f0100205:	75 e8                	jne    f01001ef <cons_putc+0x44>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100207:	ba 78 03 00 00       	mov    $0x378,%edx
f010020c:	89 f8                	mov    %edi,%eax
f010020e:	ee                   	out    %al,(%dx)
f010020f:	b2 7a                	mov    $0x7a,%dl
f0100211:	b0 0d                	mov    $0xd,%al
f0100213:	ee                   	out    %al,(%dx)
f0100214:	b0 08                	mov    $0x8,%al
f0100216:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100217:	f7 c6 00 ff ff ff    	test   $0xffffff00,%esi
f010021d:	75 06                	jne    f0100225 <cons_putc+0x7a>
		c |= 0x0700;
f010021f:	81 ce 00 07 00 00    	or     $0x700,%esi

	switch (c & 0xff) {
f0100225:	89 f0                	mov    %esi,%eax
f0100227:	25 ff 00 00 00       	and    $0xff,%eax
f010022c:	83 f8 09             	cmp    $0x9,%eax
f010022f:	74 78                	je     f01002a9 <cons_putc+0xfe>
f0100231:	83 f8 09             	cmp    $0x9,%eax
f0100234:	7f 0b                	jg     f0100241 <cons_putc+0x96>
f0100236:	83 f8 08             	cmp    $0x8,%eax
f0100239:	0f 85 9e 00 00 00    	jne    f01002dd <cons_putc+0x132>
f010023f:	eb 10                	jmp    f0100251 <cons_putc+0xa6>
f0100241:	83 f8 0a             	cmp    $0xa,%eax
f0100244:	74 39                	je     f010027f <cons_putc+0xd4>
f0100246:	83 f8 0d             	cmp    $0xd,%eax
f0100249:	0f 85 8e 00 00 00    	jne    f01002dd <cons_putc+0x132>
f010024f:	eb 36                	jmp    f0100287 <cons_putc+0xdc>
	case '\b':
		if (crt_pos > 0) {
f0100251:	66 a1 20 b3 11 f0    	mov    0xf011b320,%ax
f0100257:	66 85 c0             	test   %ax,%ax
f010025a:	0f 84 e0 00 00 00    	je     f0100340 <cons_putc+0x195>
			crt_pos--;
f0100260:	48                   	dec    %eax
f0100261:	66 a3 20 b3 11 f0    	mov    %ax,0xf011b320
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100267:	0f b7 c0             	movzwl %ax,%eax
f010026a:	81 e6 00 ff ff ff    	and    $0xffffff00,%esi
f0100270:	83 ce 20             	or     $0x20,%esi
f0100273:	8b 15 24 b3 11 f0    	mov    0xf011b324,%edx
f0100279:	66 89 34 42          	mov    %si,(%edx,%eax,2)
f010027d:	eb 78                	jmp    f01002f7 <cons_putc+0x14c>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010027f:	66 83 05 20 b3 11 f0 	addw   $0x50,0xf011b320
f0100286:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100287:	66 8b 0d 20 b3 11 f0 	mov    0xf011b320,%cx
f010028e:	bb 50 00 00 00       	mov    $0x50,%ebx
f0100293:	89 c8                	mov    %ecx,%eax
f0100295:	ba 00 00 00 00       	mov    $0x0,%edx
f010029a:	66 f7 f3             	div    %bx
f010029d:	66 29 d1             	sub    %dx,%cx
f01002a0:	66 89 0d 20 b3 11 f0 	mov    %cx,0xf011b320
f01002a7:	eb 4e                	jmp    f01002f7 <cons_putc+0x14c>
		break;
	case '\t':
		cons_putc(' ');
f01002a9:	b8 20 00 00 00       	mov    $0x20,%eax
f01002ae:	e8 f8 fe ff ff       	call   f01001ab <cons_putc>
		cons_putc(' ');
f01002b3:	b8 20 00 00 00       	mov    $0x20,%eax
f01002b8:	e8 ee fe ff ff       	call   f01001ab <cons_putc>
		cons_putc(' ');
f01002bd:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c2:	e8 e4 fe ff ff       	call   f01001ab <cons_putc>
		cons_putc(' ');
f01002c7:	b8 20 00 00 00       	mov    $0x20,%eax
f01002cc:	e8 da fe ff ff       	call   f01001ab <cons_putc>
		cons_putc(' ');
f01002d1:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d6:	e8 d0 fe ff ff       	call   f01001ab <cons_putc>
f01002db:	eb 1a                	jmp    f01002f7 <cons_putc+0x14c>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002dd:	66 a1 20 b3 11 f0    	mov    0xf011b320,%ax
f01002e3:	0f b7 c8             	movzwl %ax,%ecx
f01002e6:	8b 15 24 b3 11 f0    	mov    0xf011b324,%edx
f01002ec:	66 89 34 4a          	mov    %si,(%edx,%ecx,2)
f01002f0:	40                   	inc    %eax
f01002f1:	66 a3 20 b3 11 f0    	mov    %ax,0xf011b320
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01002f7:	66 81 3d 20 b3 11 f0 	cmpw   $0x7cf,0xf011b320
f01002fe:	cf 07 
f0100300:	76 3e                	jbe    f0100340 <cons_putc+0x195>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100302:	a1 24 b3 11 f0       	mov    0xf011b324,%eax
f0100307:	83 ec 04             	sub    $0x4,%esp
f010030a:	68 00 0f 00 00       	push   $0xf00
f010030f:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100315:	52                   	push   %edx
f0100316:	50                   	push   %eax
f0100317:	e8 db 22 00 00       	call   f01025f7 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010031c:	8b 15 24 b3 11 f0    	mov    0xf011b324,%edx
f0100322:	83 c4 10             	add    $0x10,%esp
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100325:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010032a:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100330:	40                   	inc    %eax
f0100331:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100336:	75 f2                	jne    f010032a <cons_putc+0x17f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100338:	66 83 2d 20 b3 11 f0 	subw   $0x50,0xf011b320
f010033f:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100340:	8b 0d 28 b3 11 f0    	mov    0xf011b328,%ecx
f0100346:	b0 0e                	mov    $0xe,%al
f0100348:	89 ca                	mov    %ecx,%edx
f010034a:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010034b:	66 8b 35 20 b3 11 f0 	mov    0xf011b320,%si
f0100352:	8d 59 01             	lea    0x1(%ecx),%ebx
f0100355:	89 f0                	mov    %esi,%eax
f0100357:	66 c1 e8 08          	shr    $0x8,%ax
f010035b:	89 da                	mov    %ebx,%edx
f010035d:	ee                   	out    %al,(%dx)
f010035e:	b0 0f                	mov    $0xf,%al
f0100360:	89 ca                	mov    %ecx,%edx
f0100362:	ee                   	out    %al,(%dx)
f0100363:	89 f0                	mov    %esi,%eax
f0100365:	89 da                	mov    %ebx,%edx
f0100367:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100368:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010036b:	5b                   	pop    %ebx
f010036c:	5e                   	pop    %esi
f010036d:	5f                   	pop    %edi
f010036e:	c9                   	leave  
f010036f:	c3                   	ret    

f0100370 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100370:	55                   	push   %ebp
f0100371:	89 e5                	mov    %esp,%ebp
f0100373:	53                   	push   %ebx
f0100374:	83 ec 04             	sub    $0x4,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100377:	ba 64 00 00 00       	mov    $0x64,%edx
f010037c:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010037d:	a8 01                	test   $0x1,%al
f010037f:	0f 84 dc 00 00 00    	je     f0100461 <kbd_proc_data+0xf1>
f0100385:	b2 60                	mov    $0x60,%dl
f0100387:	ec                   	in     (%dx),%al
f0100388:	88 c2                	mov    %al,%dl
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010038a:	3c e0                	cmp    $0xe0,%al
f010038c:	75 11                	jne    f010039f <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f010038e:	83 0d 48 b5 11 f0 40 	orl    $0x40,0xf011b548
		return 0;
f0100395:	bb 00 00 00 00       	mov    $0x0,%ebx
f010039a:	e9 c7 00 00 00       	jmp    f0100466 <kbd_proc_data+0xf6>
	} else if (data & 0x80) {
f010039f:	84 c0                	test   %al,%al
f01003a1:	79 33                	jns    f01003d6 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003a3:	8b 0d 48 b5 11 f0    	mov    0xf011b548,%ecx
f01003a9:	f6 c1 40             	test   $0x40,%cl
f01003ac:	75 05                	jne    f01003b3 <kbd_proc_data+0x43>
f01003ae:	88 c2                	mov    %al,%dl
f01003b0:	83 e2 7f             	and    $0x7f,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003b3:	0f b6 d2             	movzbl %dl,%edx
f01003b6:	8a 82 c0 2a 10 f0    	mov    -0xfefd540(%edx),%al
f01003bc:	83 c8 40             	or     $0x40,%eax
f01003bf:	0f b6 c0             	movzbl %al,%eax
f01003c2:	f7 d0                	not    %eax
f01003c4:	21 c1                	and    %eax,%ecx
f01003c6:	89 0d 48 b5 11 f0    	mov    %ecx,0xf011b548
		return 0;
f01003cc:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003d1:	e9 90 00 00 00       	jmp    f0100466 <kbd_proc_data+0xf6>
	} else if (shift & E0ESC) {
f01003d6:	8b 0d 48 b5 11 f0    	mov    0xf011b548,%ecx
f01003dc:	f6 c1 40             	test   $0x40,%cl
f01003df:	74 0e                	je     f01003ef <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01003e1:	88 c2                	mov    %al,%dl
f01003e3:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f01003e6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01003e9:	89 0d 48 b5 11 f0    	mov    %ecx,0xf011b548
	}

	shift |= shiftcode[data];
f01003ef:	0f b6 d2             	movzbl %dl,%edx
f01003f2:	0f b6 82 c0 2a 10 f0 	movzbl -0xfefd540(%edx),%eax
f01003f9:	0b 05 48 b5 11 f0    	or     0xf011b548,%eax
	shift ^= togglecode[data];
f01003ff:	0f b6 8a c0 2b 10 f0 	movzbl -0xfefd440(%edx),%ecx
f0100406:	31 c8                	xor    %ecx,%eax
f0100408:	a3 48 b5 11 f0       	mov    %eax,0xf011b548

	c = charcode[shift & (CTL | SHIFT)][data];
f010040d:	89 c1                	mov    %eax,%ecx
f010040f:	83 e1 03             	and    $0x3,%ecx
f0100412:	8b 0c 8d c0 2c 10 f0 	mov    -0xfefd340(,%ecx,4),%ecx
f0100419:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f010041d:	a8 08                	test   $0x8,%al
f010041f:	74 18                	je     f0100439 <kbd_proc_data+0xc9>
		if ('a' <= c && c <= 'z')
f0100421:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100424:	83 fa 19             	cmp    $0x19,%edx
f0100427:	77 05                	ja     f010042e <kbd_proc_data+0xbe>
			c += 'A' - 'a';
f0100429:	83 eb 20             	sub    $0x20,%ebx
f010042c:	eb 0b                	jmp    f0100439 <kbd_proc_data+0xc9>
		else if ('A' <= c && c <= 'Z')
f010042e:	8d 53 bf             	lea    -0x41(%ebx),%edx
f0100431:	83 fa 19             	cmp    $0x19,%edx
f0100434:	77 03                	ja     f0100439 <kbd_proc_data+0xc9>
			c += 'a' - 'A';
f0100436:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100439:	f7 d0                	not    %eax
f010043b:	a8 06                	test   $0x6,%al
f010043d:	75 27                	jne    f0100466 <kbd_proc_data+0xf6>
f010043f:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100445:	75 1f                	jne    f0100466 <kbd_proc_data+0xf6>
		cprintf("Rebooting!\n");
f0100447:	83 ec 0c             	sub    $0xc,%esp
f010044a:	68 7c 2a 10 f0       	push   $0xf0102a7c
f010044f:	e8 24 15 00 00       	call   f0101978 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100454:	ba 92 00 00 00       	mov    $0x92,%edx
f0100459:	b0 03                	mov    $0x3,%al
f010045b:	ee                   	out    %al,(%dx)
f010045c:	83 c4 10             	add    $0x10,%esp
f010045f:	eb 05                	jmp    f0100466 <kbd_proc_data+0xf6>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100461:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100466:	89 d8                	mov    %ebx,%eax
f0100468:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010046b:	c9                   	leave  
f010046c:	c3                   	ret    

f010046d <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010046d:	55                   	push   %ebp
f010046e:	89 e5                	mov    %esp,%ebp
f0100470:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100473:	80 3d 2c b3 11 f0 00 	cmpb   $0x0,0xf011b32c
f010047a:	74 0a                	je     f0100486 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f010047c:	b8 4e 01 10 f0       	mov    $0xf010014e,%eax
f0100481:	e8 e4 fc ff ff       	call   f010016a <cons_intr>
}
f0100486:	c9                   	leave  
f0100487:	c3                   	ret    

f0100488 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100488:	55                   	push   %ebp
f0100489:	89 e5                	mov    %esp,%ebp
f010048b:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010048e:	b8 70 03 10 f0       	mov    $0xf0100370,%eax
f0100493:	e8 d2 fc ff ff       	call   f010016a <cons_intr>
}
f0100498:	c9                   	leave  
f0100499:	c3                   	ret    

f010049a <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010049a:	55                   	push   %ebp
f010049b:	89 e5                	mov    %esp,%ebp
f010049d:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004a0:	e8 c8 ff ff ff       	call   f010046d <serial_intr>
	kbd_intr();
f01004a5:	e8 de ff ff ff       	call   f0100488 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004aa:	8b 15 40 b5 11 f0    	mov    0xf011b540,%edx
f01004b0:	3b 15 44 b5 11 f0    	cmp    0xf011b544,%edx
f01004b6:	74 22                	je     f01004da <cons_getc+0x40>
		c = cons.buf[cons.rpos++];
f01004b8:	0f b6 82 40 b3 11 f0 	movzbl -0xfee4cc0(%edx),%eax
f01004bf:	42                   	inc    %edx
f01004c0:	89 15 40 b5 11 f0    	mov    %edx,0xf011b540
		if (cons.rpos == CONSBUFSIZE)
f01004c6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004cc:	75 11                	jne    f01004df <cons_getc+0x45>
			cons.rpos = 0;
f01004ce:	c7 05 40 b5 11 f0 00 	movl   $0x0,0xf011b540
f01004d5:	00 00 00 
f01004d8:	eb 05                	jmp    f01004df <cons_getc+0x45>
		return c;
	}
	return 0;
f01004da:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004df:	c9                   	leave  
f01004e0:	c3                   	ret    

f01004e1 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004e1:	55                   	push   %ebp
f01004e2:	89 e5                	mov    %esp,%ebp
f01004e4:	57                   	push   %edi
f01004e5:	56                   	push   %esi
f01004e6:	53                   	push   %ebx
f01004e7:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004ea:	66 8b 15 00 80 0b f0 	mov    0xf00b8000,%dx
	*cp = (uint16_t) 0xA55A;
f01004f1:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01004f8:	5a a5 
	if (*cp != 0xA55A) {
f01004fa:	66 a1 00 80 0b f0    	mov    0xf00b8000,%ax
f0100500:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100504:	74 11                	je     f0100517 <cons_init+0x36>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100506:	c7 05 28 b3 11 f0 b4 	movl   $0x3b4,0xf011b328
f010050d:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100510:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100515:	eb 16                	jmp    f010052d <cons_init+0x4c>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100517:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010051e:	c7 05 28 b3 11 f0 d4 	movl   $0x3d4,0xf011b328
f0100525:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100528:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010052d:	8b 0d 28 b3 11 f0    	mov    0xf011b328,%ecx
f0100533:	b0 0e                	mov    $0xe,%al
f0100535:	89 ca                	mov    %ecx,%edx
f0100537:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100538:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010053b:	89 da                	mov    %ebx,%edx
f010053d:	ec                   	in     (%dx),%al
f010053e:	0f b6 f8             	movzbl %al,%edi
f0100541:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100544:	b0 0f                	mov    $0xf,%al
f0100546:	89 ca                	mov    %ecx,%edx
f0100548:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100549:	89 da                	mov    %ebx,%edx
f010054b:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010054c:	89 35 24 b3 11 f0    	mov    %esi,0xf011b324

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100552:	0f b6 d8             	movzbl %al,%ebx
f0100555:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100557:	66 89 3d 20 b3 11 f0 	mov    %di,0xf011b320
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055e:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f0100563:	b0 00                	mov    $0x0,%al
f0100565:	89 da                	mov    %ebx,%edx
f0100567:	ee                   	out    %al,(%dx)
f0100568:	b2 fb                	mov    $0xfb,%dl
f010056a:	b0 80                	mov    $0x80,%al
f010056c:	ee                   	out    %al,(%dx)
f010056d:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100572:	b0 0c                	mov    $0xc,%al
f0100574:	89 ca                	mov    %ecx,%edx
f0100576:	ee                   	out    %al,(%dx)
f0100577:	b2 f9                	mov    $0xf9,%dl
f0100579:	b0 00                	mov    $0x0,%al
f010057b:	ee                   	out    %al,(%dx)
f010057c:	b2 fb                	mov    $0xfb,%dl
f010057e:	b0 03                	mov    $0x3,%al
f0100580:	ee                   	out    %al,(%dx)
f0100581:	b2 fc                	mov    $0xfc,%dl
f0100583:	b0 00                	mov    $0x0,%al
f0100585:	ee                   	out    %al,(%dx)
f0100586:	b2 f9                	mov    $0xf9,%dl
f0100588:	b0 01                	mov    $0x1,%al
f010058a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058b:	b2 fd                	mov    $0xfd,%dl
f010058d:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010058e:	3c ff                	cmp    $0xff,%al
f0100590:	0f 95 45 e7          	setne  -0x19(%ebp)
f0100594:	8a 45 e7             	mov    -0x19(%ebp),%al
f0100597:	a2 2c b3 11 f0       	mov    %al,0xf011b32c
f010059c:	89 da                	mov    %ebx,%edx
f010059e:	ec                   	in     (%dx),%al
f010059f:	89 ca                	mov    %ecx,%edx
f01005a1:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005a2:	80 7d e7 00          	cmpb   $0x0,-0x19(%ebp)
f01005a6:	75 10                	jne    f01005b8 <cons_init+0xd7>
		cprintf("Serial port does not exist!\n");
f01005a8:	83 ec 0c             	sub    $0xc,%esp
f01005ab:	68 88 2a 10 f0       	push   $0xf0102a88
f01005b0:	e8 c3 13 00 00       	call   f0101978 <cprintf>
f01005b5:	83 c4 10             	add    $0x10,%esp
}
f01005b8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005bb:	5b                   	pop    %ebx
f01005bc:	5e                   	pop    %esi
f01005bd:	5f                   	pop    %edi
f01005be:	c9                   	leave  
f01005bf:	c3                   	ret    

f01005c0 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005c0:	55                   	push   %ebp
f01005c1:	89 e5                	mov    %esp,%ebp
f01005c3:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01005c9:	e8 dd fb ff ff       	call   f01001ab <cons_putc>
}
f01005ce:	c9                   	leave  
f01005cf:	c3                   	ret    

f01005d0 <getchar>:

int
getchar(void)
{
f01005d0:	55                   	push   %ebp
f01005d1:	89 e5                	mov    %esp,%ebp
f01005d3:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01005d6:	e8 bf fe ff ff       	call   f010049a <cons_getc>
f01005db:	85 c0                	test   %eax,%eax
f01005dd:	74 f7                	je     f01005d6 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01005df:	c9                   	leave  
f01005e0:	c3                   	ret    

f01005e1 <iscons>:

int
iscons(int fdnum)
{
f01005e1:	55                   	push   %ebp
f01005e2:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01005e4:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e9:	c9                   	leave  
f01005ea:	c3                   	ret    
	...

f01005ec <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01005ec:	55                   	push   %ebp
f01005ed:	89 e5                	mov    %esp,%ebp
f01005ef:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01005f2:	68 d0 2c 10 f0       	push   $0xf0102cd0
f01005f7:	e8 7c 13 00 00       	call   f0101978 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01005fc:	83 c4 08             	add    $0x8,%esp
f01005ff:	68 0c 00 10 00       	push   $0x10000c
f0100604:	68 90 2d 10 f0       	push   $0xf0102d90
f0100609:	e8 6a 13 00 00       	call   f0101978 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010060e:	83 c4 0c             	add    $0xc,%esp
f0100611:	68 0c 00 10 00       	push   $0x10000c
f0100616:	68 0c 00 10 f0       	push   $0xf010000c
f010061b:	68 b8 2d 10 f0       	push   $0xf0102db8
f0100620:	e8 53 13 00 00       	call   f0101978 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100625:	83 c4 0c             	add    $0xc,%esp
f0100628:	68 fc 29 10 00       	push   $0x1029fc
f010062d:	68 fc 29 10 f0       	push   $0xf01029fc
f0100632:	68 dc 2d 10 f0       	push   $0xf0102ddc
f0100637:	e8 3c 13 00 00       	call   f0101978 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010063c:	83 c4 0c             	add    $0xc,%esp
f010063f:	68 04 b3 11 00       	push   $0x11b304
f0100644:	68 04 b3 11 f0       	push   $0xf011b304
f0100649:	68 00 2e 10 f0       	push   $0xf0102e00
f010064e:	e8 25 13 00 00       	call   f0101978 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100653:	83 c4 0c             	add    $0xc,%esp
f0100656:	68 70 b9 11 00       	push   $0x11b970
f010065b:	68 70 b9 11 f0       	push   $0xf011b970
f0100660:	68 24 2e 10 f0       	push   $0xf0102e24
f0100665:	e8 0e 13 00 00       	call   f0101978 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010066a:	b8 6f bd 11 f0       	mov    $0xf011bd6f,%eax
f010066f:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100674:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100677:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010067c:	89 c2                	mov    %eax,%edx
f010067e:	85 c0                	test   %eax,%eax
f0100680:	79 06                	jns    f0100688 <mon_kerninfo+0x9c>
f0100682:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100688:	c1 fa 0a             	sar    $0xa,%edx
f010068b:	52                   	push   %edx
f010068c:	68 48 2e 10 f0       	push   $0xf0102e48
f0100691:	e8 e2 12 00 00       	call   f0101978 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100696:	b8 00 00 00 00       	mov    $0x0,%eax
f010069b:	c9                   	leave  
f010069c:	c3                   	ret    

f010069d <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010069d:	55                   	push   %ebp
f010069e:	89 e5                	mov    %esp,%ebp
f01006a0:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006a3:	ff 35 84 2f 10 f0    	pushl  0xf0102f84
f01006a9:	ff 35 80 2f 10 f0    	pushl  0xf0102f80
f01006af:	68 e9 2c 10 f0       	push   $0xf0102ce9
f01006b4:	e8 bf 12 00 00       	call   f0101978 <cprintf>
f01006b9:	83 c4 0c             	add    $0xc,%esp
f01006bc:	ff 35 90 2f 10 f0    	pushl  0xf0102f90
f01006c2:	ff 35 8c 2f 10 f0    	pushl  0xf0102f8c
f01006c8:	68 e9 2c 10 f0       	push   $0xf0102ce9
f01006cd:	e8 a6 12 00 00       	call   f0101978 <cprintf>
f01006d2:	83 c4 0c             	add    $0xc,%esp
f01006d5:	ff 35 9c 2f 10 f0    	pushl  0xf0102f9c
f01006db:	ff 35 98 2f 10 f0    	pushl  0xf0102f98
f01006e1:	68 e9 2c 10 f0       	push   $0xf0102ce9
f01006e6:	e8 8d 12 00 00       	call   f0101978 <cprintf>
	return 0;
}
f01006eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f0:	c9                   	leave  
f01006f1:	c3                   	ret    

f01006f2 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01006f2:	55                   	push   %ebp
f01006f3:	89 e5                	mov    %esp,%ebp
f01006f5:	57                   	push   %edi
f01006f6:	56                   	push   %esi
f01006f7:	53                   	push   %ebx
f01006f8:	81 ec 98 00 00 00    	sub    $0x98,%esp
	cprintf("Stack backtrace:\n");
f01006fe:	68 f2 2c 10 f0       	push   $0xf0102cf2
f0100703:	e8 70 12 00 00       	call   f0101978 <cprintf>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100708:	89 e8                	mov    %ebp,%eax
	uint32_t* ebp = (uint32_t*) read_ebp();
f010070a:	89 c3                	mov    %eax,%ebx

	while(ebp)
f010070c:	83 c4 10             	add    $0x10,%esp
f010070f:	85 c0                	test   %eax,%eax
f0100711:	0f 84 9c 00 00 00    	je     f01007b3 <mon_backtrace+0xc1>
		int result = debuginfo_eip(eip, &debug_info);

		if(result >= 0)
		{
			char fn_name_buffer[CMDBUF_SIZE];
			memcpy(fn_name_buffer, debug_info.eip_fn_name, sizeof(char) * debug_info.eip_fn_namelen);
f0100717:	8d bd 6c ff ff ff    	lea    -0x94(%ebp),%edi
	cprintf("Stack backtrace:\n");
	uint32_t* ebp = (uint32_t*) read_ebp();

	while(ebp)
	{
		uint32_t eip = ebp[1];
f010071d:	8b 73 04             	mov    0x4(%ebx),%esi
		uint32_t args[5];

		int i;
		for(i=0; i<5; i++)
f0100720:	b8 00 00 00 00       	mov    $0x0,%eax
			args[i] = ebp[2+i];
f0100725:	8b 54 83 08          	mov    0x8(%ebx,%eax,4),%edx
f0100729:	89 54 85 d4          	mov    %edx,-0x2c(%ebp,%eax,4)
	{
		uint32_t eip = ebp[1];
		uint32_t args[5];

		int i;
		for(i=0; i<5; i++)
f010072d:	40                   	inc    %eax
f010072e:	83 f8 05             	cmp    $0x5,%eax
f0100731:	75 f2                	jne    f0100725 <mon_backtrace+0x33>
			args[i] = ebp[2+i];

		cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",
f0100733:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100736:	ff 75 e0             	pushl  -0x20(%ebp)
f0100739:	ff 75 dc             	pushl  -0x24(%ebp)
f010073c:	ff 75 d8             	pushl  -0x28(%ebp)
f010073f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100742:	56                   	push   %esi
f0100743:	53                   	push   %ebx
f0100744:	68 74 2e 10 f0       	push   $0xf0102e74
f0100749:	e8 2a 12 00 00       	call   f0101978 <cprintf>
		    (uint32_t)ebp,
			eip, args[0], args[1], args[2], args[3], args[4]);

		struct Eipdebuginfo debug_info;
		int result = debuginfo_eip(eip, &debug_info);
f010074e:	83 c4 18             	add    $0x18,%esp
f0100751:	8d 45 bc             	lea    -0x44(%ebp),%eax
f0100754:	50                   	push   %eax
f0100755:	56                   	push   %esi
f0100756:	e8 56 13 00 00       	call   f0101ab1 <debuginfo_eip>

		if(result >= 0)
f010075b:	83 c4 10             	add    $0x10,%esp
f010075e:	85 c0                	test   %eax,%eax
f0100760:	78 36                	js     f0100798 <mon_backtrace+0xa6>
		{
			char fn_name_buffer[CMDBUF_SIZE];
			memcpy(fn_name_buffer, debug_info.eip_fn_name, sizeof(char) * debug_info.eip_fn_namelen);
f0100762:	83 ec 04             	sub    $0x4,%esp
f0100765:	ff 75 c8             	pushl  -0x38(%ebp)
f0100768:	ff 75 c4             	pushl  -0x3c(%ebp)
f010076b:	57                   	push   %edi
f010076c:	e8 f0 1e 00 00       	call   f0102661 <memcpy>
			fn_name_buffer[debug_info.eip_fn_namelen] = '\0';
f0100771:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100774:	c6 84 05 6c ff ff ff 	movb   $0x0,-0x94(%ebp,%eax,1)
f010077b:	00 

            cprintf("          %s:%d: %s+%d\n",
f010077c:	2b 75 cc             	sub    -0x34(%ebp),%esi
f010077f:	89 34 24             	mov    %esi,(%esp)
f0100782:	57                   	push   %edi
f0100783:	ff 75 c0             	pushl  -0x40(%ebp)
f0100786:	ff 75 bc             	pushl  -0x44(%ebp)
f0100789:	68 04 2d 10 f0       	push   $0xf0102d04
f010078e:	e8 e5 11 00 00       	call   f0101978 <cprintf>
f0100793:	83 c4 20             	add    $0x20,%esp
f0100796:	eb 11                	jmp    f01007a9 <mon_backtrace+0xb7>
				eip - (uint32_t)debug_info.eip_fn_addr);

		}
		else
		{
			cprintf("          Exception %d during printing the debug info\n", result);
f0100798:	83 ec 08             	sub    $0x8,%esp
f010079b:	50                   	push   %eax
f010079c:	68 a8 2e 10 f0       	push   $0xf0102ea8
f01007a1:	e8 d2 11 00 00       	call   f0101978 <cprintf>
f01007a6:	83 c4 10             	add    $0x10,%esp
		}

		ebp = (uint32_t*)*ebp;
f01007a9:	8b 1b                	mov    (%ebx),%ebx
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	cprintf("Stack backtrace:\n");
	uint32_t* ebp = (uint32_t*) read_ebp();

	while(ebp)
f01007ab:	85 db                	test   %ebx,%ebx
f01007ad:	0f 85 6a ff ff ff    	jne    f010071d <mon_backtrace+0x2b>

		ebp = (uint32_t*)*ebp;
	}

	return 0;
}
f01007b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007bb:	5b                   	pop    %ebx
f01007bc:	5e                   	pop    %esi
f01007bd:	5f                   	pop    %edi
f01007be:	c9                   	leave  
f01007bf:	c3                   	ret    

f01007c0 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007c0:	55                   	push   %ebp
f01007c1:	89 e5                	mov    %esp,%ebp
f01007c3:	57                   	push   %edi
f01007c4:	56                   	push   %esi
f01007c5:	53                   	push   %ebx
f01007c6:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007c9:	68 e0 2e 10 f0       	push   $0xf0102ee0
f01007ce:	e8 a5 11 00 00       	call   f0101978 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007d3:	c7 04 24 04 2f 10 f0 	movl   $0xf0102f04,(%esp)
f01007da:	e8 99 11 00 00       	call   f0101978 <cprintf>
f01007df:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007e2:	83 ec 0c             	sub    $0xc,%esp
f01007e5:	68 1c 2d 10 f0       	push   $0xf0102d1c
f01007ea:	e8 25 1b 00 00       	call   f0102314 <readline>
f01007ef:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007f1:	83 c4 10             	add    $0x10,%esp
f01007f4:	85 c0                	test   %eax,%eax
f01007f6:	74 ea                	je     f01007e2 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007f8:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007ff:	be 00 00 00 00       	mov    $0x0,%esi
f0100804:	eb 04                	jmp    f010080a <monitor+0x4a>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100806:	c6 03 00             	movb   $0x0,(%ebx)
f0100809:	43                   	inc    %ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010080a:	8a 03                	mov    (%ebx),%al
f010080c:	84 c0                	test   %al,%al
f010080e:	74 64                	je     f0100874 <monitor+0xb4>
f0100810:	83 ec 08             	sub    $0x8,%esp
f0100813:	0f be c0             	movsbl %al,%eax
f0100816:	50                   	push   %eax
f0100817:	68 20 2d 10 f0       	push   $0xf0102d20
f010081c:	e8 3c 1d 00 00       	call   f010255d <strchr>
f0100821:	83 c4 10             	add    $0x10,%esp
f0100824:	85 c0                	test   %eax,%eax
f0100826:	75 de                	jne    f0100806 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100828:	80 3b 00             	cmpb   $0x0,(%ebx)
f010082b:	74 47                	je     f0100874 <monitor+0xb4>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010082d:	83 fe 0f             	cmp    $0xf,%esi
f0100830:	75 14                	jne    f0100846 <monitor+0x86>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100832:	83 ec 08             	sub    $0x8,%esp
f0100835:	6a 10                	push   $0x10
f0100837:	68 25 2d 10 f0       	push   $0xf0102d25
f010083c:	e8 37 11 00 00       	call   f0101978 <cprintf>
f0100841:	83 c4 10             	add    $0x10,%esp
f0100844:	eb 9c                	jmp    f01007e2 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100846:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010084a:	46                   	inc    %esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010084b:	8a 03                	mov    (%ebx),%al
f010084d:	84 c0                	test   %al,%al
f010084f:	75 09                	jne    f010085a <monitor+0x9a>
f0100851:	eb b7                	jmp    f010080a <monitor+0x4a>
			buf++;
f0100853:	43                   	inc    %ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100854:	8a 03                	mov    (%ebx),%al
f0100856:	84 c0                	test   %al,%al
f0100858:	74 b0                	je     f010080a <monitor+0x4a>
f010085a:	83 ec 08             	sub    $0x8,%esp
f010085d:	0f be c0             	movsbl %al,%eax
f0100860:	50                   	push   %eax
f0100861:	68 20 2d 10 f0       	push   $0xf0102d20
f0100866:	e8 f2 1c 00 00       	call   f010255d <strchr>
f010086b:	83 c4 10             	add    $0x10,%esp
f010086e:	85 c0                	test   %eax,%eax
f0100870:	74 e1                	je     f0100853 <monitor+0x93>
f0100872:	eb 96                	jmp    f010080a <monitor+0x4a>
			buf++;
	}
	argv[argc] = 0;
f0100874:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010087b:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010087c:	85 f6                	test   %esi,%esi
f010087e:	0f 84 5e ff ff ff    	je     f01007e2 <monitor+0x22>
f0100884:	bb 80 2f 10 f0       	mov    $0xf0102f80,%ebx
f0100889:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010088e:	83 ec 08             	sub    $0x8,%esp
f0100891:	ff 33                	pushl  (%ebx)
f0100893:	ff 75 a8             	pushl  -0x58(%ebp)
f0100896:	e8 54 1c 00 00       	call   f01024ef <strcmp>
f010089b:	83 c4 10             	add    $0x10,%esp
f010089e:	85 c0                	test   %eax,%eax
f01008a0:	75 20                	jne    f01008c2 <monitor+0x102>
			return commands[i].func(argc, argv, tf);
f01008a2:	83 ec 04             	sub    $0x4,%esp
f01008a5:	6b ff 0c             	imul   $0xc,%edi,%edi
f01008a8:	ff 75 08             	pushl  0x8(%ebp)
f01008ab:	8d 45 a8             	lea    -0x58(%ebp),%eax
f01008ae:	50                   	push   %eax
f01008af:	56                   	push   %esi
f01008b0:	ff 97 88 2f 10 f0    	call   *-0xfefd078(%edi)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008b6:	83 c4 10             	add    $0x10,%esp
f01008b9:	85 c0                	test   %eax,%eax
f01008bb:	78 26                	js     f01008e3 <monitor+0x123>
f01008bd:	e9 20 ff ff ff       	jmp    f01007e2 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008c2:	47                   	inc    %edi
f01008c3:	83 c3 0c             	add    $0xc,%ebx
f01008c6:	83 ff 03             	cmp    $0x3,%edi
f01008c9:	75 c3                	jne    f010088e <monitor+0xce>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008cb:	83 ec 08             	sub    $0x8,%esp
f01008ce:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d1:	68 42 2d 10 f0       	push   $0xf0102d42
f01008d6:	e8 9d 10 00 00       	call   f0101978 <cprintf>
f01008db:	83 c4 10             	add    $0x10,%esp
f01008de:	e9 ff fe ff ff       	jmp    f01007e2 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008e3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008e6:	5b                   	pop    %ebx
f01008e7:	5e                   	pop    %esi
f01008e8:	5f                   	pop    %edi
f01008e9:	c9                   	leave  
f01008ea:	c3                   	ret    
	...

f01008ec <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01008ec:	55                   	push   %ebp
f01008ed:	89 e5                	mov    %esp,%ebp
f01008ef:	83 ec 08             	sub    $0x8,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01008f2:	89 d1                	mov    %edx,%ecx
f01008f4:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f01008f7:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01008fa:	a8 01                	test   $0x1,%al
f01008fc:	74 42                	je     f0100940 <check_va2pa+0x54>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01008fe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100903:	89 c1                	mov    %eax,%ecx
f0100905:	c1 e9 0c             	shr    $0xc,%ecx
f0100908:	3b 0d 64 b9 11 f0    	cmp    0xf011b964,%ecx
f010090e:	72 15                	jb     f0100925 <check_va2pa+0x39>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100910:	50                   	push   %eax
f0100911:	68 a4 2f 10 f0       	push   $0xf0102fa4
f0100916:	68 ab 02 00 00       	push   $0x2ab
f010091b:	68 30 34 10 f0       	push   $0xf0103430
f0100920:	e8 8a f7 ff ff       	call   f01000af <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100925:	c1 ea 0c             	shr    $0xc,%edx
f0100928:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010092e:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100935:	a8 01                	test   $0x1,%al
f0100937:	74 0e                	je     f0100947 <check_va2pa+0x5b>
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100939:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010093e:	eb 0c                	jmp    f010094c <check_va2pa+0x60>
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100940:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100945:	eb 05                	jmp    f010094c <check_va2pa+0x60>
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
f0100947:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return PTE_ADDR(p[PTX(va)]);
}
f010094c:	c9                   	leave  
f010094d:	c3                   	ret    

f010094e <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f010094e:	55                   	push   %ebp
f010094f:	89 e5                	mov    %esp,%ebp
f0100951:	53                   	push   %ebx
f0100952:	83 ec 04             	sub    $0x4,%esp
f0100955:	89 c2                	mov    %eax,%edx
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	extern char end[];

	if (!nextfree) {
f0100957:	83 3d 50 b5 11 f0 00 	cmpl   $0x0,0xf011b550
f010095e:	75 0f                	jne    f010096f <boot_alloc+0x21>
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100960:	b8 6f c9 11 f0       	mov    $0xf011c96f,%eax
f0100965:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010096a:	a3 50 b5 11 f0       	mov    %eax,0xf011b550
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	result = nextfree;
f010096f:	a1 50 b5 11 f0       	mov    0xf011b550,%eax

	if(n > 0)
f0100974:	85 d2                	test   %edx,%edx
f0100976:	74 44                	je     f01009bc <boot_alloc+0x6e>
	{
		uint32_t bytesWillAlloc = ROUNDUP(n, PGSIZE);
f0100978:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f010097e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
		uint32_t bytesUsed = nextfree - (char*)end;

		nextfree += bytesWillAlloc;
f0100984:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
f0100987:	89 0d 50 b5 11 f0    	mov    %ecx,0xf011b550
	result = nextfree;

	if(n > 0)
	{
		uint32_t bytesWillAlloc = ROUNDUP(n, PGSIZE);
		uint32_t bytesUsed = nextfree - (char*)end;
f010098d:	89 c1                	mov    %eax,%ecx
f010098f:	81 e9 70 b9 11 f0    	sub    $0xf011b970,%ecx

		nextfree += bytesWillAlloc;
		if(bytesUsed / PGSIZE >= npages)
f0100995:	c1 e9 0c             	shr    $0xc,%ecx
f0100998:	8b 1d 64 b9 11 f0    	mov    0xf011b964,%ebx
f010099e:	39 d9                	cmp    %ebx,%ecx
f01009a0:	72 1a                	jb     f01009bc <boot_alloc+0x6e>
		{
			panic("boot_alloc: Memory overflow. (require %u bytes, aligned to %u pages, mem usage: %u/%u)\n",
f01009a2:	83 ec 08             	sub    $0x8,%esp
f01009a5:	53                   	push   %ebx
f01009a6:	51                   	push   %ecx
f01009a7:	c1 ea 0c             	shr    $0xc,%edx
f01009aa:	52                   	push   %edx
f01009ab:	68 c8 2f 10 f0       	push   $0xf0102fc8
f01009b0:	6a 72                	push   $0x72
f01009b2:	68 30 34 10 f0       	push   $0xf0103430
f01009b7:	e8 f3 f6 ff ff       	call   f01000af <_panic>
		}

	}

	return result;
}
f01009bc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01009bf:	c9                   	leave  
f01009c0:	c3                   	ret    

f01009c1 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01009c1:	55                   	push   %ebp
f01009c2:	89 e5                	mov    %esp,%ebp
f01009c4:	56                   	push   %esi
f01009c5:	53                   	push   %ebx
f01009c6:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009c8:	83 ec 0c             	sub    $0xc,%esp
f01009cb:	50                   	push   %eax
f01009cc:	e8 27 0f 00 00       	call   f01018f8 <mc146818_read>
f01009d1:	89 c6                	mov    %eax,%esi
f01009d3:	43                   	inc    %ebx
f01009d4:	89 1c 24             	mov    %ebx,(%esp)
f01009d7:	e8 1c 0f 00 00       	call   f01018f8 <mc146818_read>
f01009dc:	c1 e0 08             	shl    $0x8,%eax
f01009df:	09 f0                	or     %esi,%eax
}
f01009e1:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01009e4:	5b                   	pop    %ebx
f01009e5:	5e                   	pop    %esi
f01009e6:	c9                   	leave  
f01009e7:	c3                   	ret    

f01009e8 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009e8:	55                   	push   %ebp
f01009e9:	89 e5                	mov    %esp,%ebp
f01009eb:	57                   	push   %edi
f01009ec:	56                   	push   %esi
f01009ed:	53                   	push   %ebx
f01009ee:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009f1:	3c 01                	cmp    $0x1,%al
f01009f3:	19 f6                	sbb    %esi,%esi
f01009f5:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f01009fb:	46                   	inc    %esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f01009fc:	8b 1d 4c b5 11 f0    	mov    0xf011b54c,%ebx
f0100a02:	85 db                	test   %ebx,%ebx
f0100a04:	75 17                	jne    f0100a1d <check_page_free_list+0x35>
		panic("'page_free_list' is a null pointer!");
f0100a06:	83 ec 04             	sub    $0x4,%esp
f0100a09:	68 20 30 10 f0       	push   $0xf0103020
f0100a0e:	68 ec 01 00 00       	push   $0x1ec
f0100a13:	68 30 34 10 f0       	push   $0xf0103430
f0100a18:	e8 92 f6 ff ff       	call   f01000af <_panic>

	if (only_low_memory) {
f0100a1d:	84 c0                	test   %al,%al
f0100a1f:	74 50                	je     f0100a71 <check_page_free_list+0x89>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a21:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100a24:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100a27:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100a2a:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a2d:	89 d8                	mov    %ebx,%eax
f0100a2f:	2b 05 6c b9 11 f0    	sub    0xf011b96c,%eax
f0100a35:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a38:	c1 e8 16             	shr    $0x16,%eax
f0100a3b:	39 c6                	cmp    %eax,%esi
f0100a3d:	0f 96 c0             	setbe  %al
f0100a40:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100a43:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f0100a47:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100a49:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a4d:	8b 1b                	mov    (%ebx),%ebx
f0100a4f:	85 db                	test   %ebx,%ebx
f0100a51:	75 da                	jne    f0100a2d <check_page_free_list+0x45>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a53:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100a56:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a5c:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100a5f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a62:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a64:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a67:	89 1d 4c b5 11 f0    	mov    %ebx,0xf011b54c
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a6d:	85 db                	test   %ebx,%ebx
f0100a6f:	74 57                	je     f0100ac8 <check_page_free_list+0xe0>
f0100a71:	89 d8                	mov    %ebx,%eax
f0100a73:	2b 05 6c b9 11 f0    	sub    0xf011b96c,%eax
f0100a79:	c1 f8 03             	sar    $0x3,%eax
f0100a7c:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a7f:	89 c2                	mov    %eax,%edx
f0100a81:	c1 ea 16             	shr    $0x16,%edx
f0100a84:	39 d6                	cmp    %edx,%esi
f0100a86:	76 3a                	jbe    f0100ac2 <check_page_free_list+0xda>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a88:	89 c2                	mov    %eax,%edx
f0100a8a:	c1 ea 0c             	shr    $0xc,%edx
f0100a8d:	3b 15 64 b9 11 f0    	cmp    0xf011b964,%edx
f0100a93:	72 12                	jb     f0100aa7 <check_page_free_list+0xbf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a95:	50                   	push   %eax
f0100a96:	68 a4 2f 10 f0       	push   $0xf0102fa4
f0100a9b:	6a 52                	push   $0x52
f0100a9d:	68 3c 34 10 f0       	push   $0xf010343c
f0100aa2:	e8 08 f6 ff ff       	call   f01000af <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aa7:	83 ec 04             	sub    $0x4,%esp
f0100aaa:	68 80 00 00 00       	push   $0x80
f0100aaf:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100ab4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ab9:	50                   	push   %eax
f0100aba:	e8 ee 1a 00 00       	call   f01025ad <memset>
f0100abf:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ac2:	8b 1b                	mov    (%ebx),%ebx
f0100ac4:	85 db                	test   %ebx,%ebx
f0100ac6:	75 a9                	jne    f0100a71 <check_page_free_list+0x89>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ac8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100acd:	e8 7c fe ff ff       	call   f010094e <boot_alloc>
f0100ad2:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ad5:	8b 15 4c b5 11 f0    	mov    0xf011b54c,%edx
f0100adb:	85 d2                	test   %edx,%edx
f0100add:	0f 84 d0 01 00 00    	je     f0100cb3 <check_page_free_list+0x2cb>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ae3:	8b 1d 6c b9 11 f0    	mov    0xf011b96c,%ebx
f0100ae9:	39 da                	cmp    %ebx,%edx
f0100aeb:	72 47                	jb     f0100b34 <check_page_free_list+0x14c>
		assert(pp < pages + npages);
f0100aed:	a1 64 b9 11 f0       	mov    0xf011b964,%eax
f0100af2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100af5:	8d 34 c3             	lea    (%ebx,%eax,8),%esi
f0100af8:	39 f2                	cmp    %esi,%edx
f0100afa:	73 55                	jae    f0100b51 <check_page_free_list+0x169>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100afc:	89 df                	mov    %ebx,%edi
f0100afe:	89 d0                	mov    %edx,%eax
f0100b00:	29 d8                	sub    %ebx,%eax
f0100b02:	a8 07                	test   $0x7,%al
f0100b04:	75 6c                	jne    f0100b72 <check_page_free_list+0x18a>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b06:	c1 f8 03             	sar    $0x3,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b09:	c1 e0 0c             	shl    $0xc,%eax
f0100b0c:	0f 84 81 00 00 00    	je     f0100b93 <check_page_free_list+0x1ab>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b12:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b17:	0f 84 96 00 00 00    	je     f0100bb3 <check_page_free_list+0x1cb>
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b1d:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0100b24:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0100b2b:	e9 9c 00 00 00       	jmp    f0100bcc <check_page_free_list+0x1e4>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b30:	39 da                	cmp    %ebx,%edx
f0100b32:	73 19                	jae    f0100b4d <check_page_free_list+0x165>
f0100b34:	68 4a 34 10 f0       	push   $0xf010344a
f0100b39:	68 56 34 10 f0       	push   $0xf0103456
f0100b3e:	68 06 02 00 00       	push   $0x206
f0100b43:	68 30 34 10 f0       	push   $0xf0103430
f0100b48:	e8 62 f5 ff ff       	call   f01000af <_panic>
		assert(pp < pages + npages);
f0100b4d:	39 f2                	cmp    %esi,%edx
f0100b4f:	72 19                	jb     f0100b6a <check_page_free_list+0x182>
f0100b51:	68 6b 34 10 f0       	push   $0xf010346b
f0100b56:	68 56 34 10 f0       	push   $0xf0103456
f0100b5b:	68 07 02 00 00       	push   $0x207
f0100b60:	68 30 34 10 f0       	push   $0xf0103430
f0100b65:	e8 45 f5 ff ff       	call   f01000af <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b6a:	89 d0                	mov    %edx,%eax
f0100b6c:	29 f8                	sub    %edi,%eax
f0100b6e:	a8 07                	test   $0x7,%al
f0100b70:	74 19                	je     f0100b8b <check_page_free_list+0x1a3>
f0100b72:	68 44 30 10 f0       	push   $0xf0103044
f0100b77:	68 56 34 10 f0       	push   $0xf0103456
f0100b7c:	68 08 02 00 00       	push   $0x208
f0100b81:	68 30 34 10 f0       	push   $0xf0103430
f0100b86:	e8 24 f5 ff ff       	call   f01000af <_panic>
f0100b8b:	c1 f8 03             	sar    $0x3,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b8e:	c1 e0 0c             	shl    $0xc,%eax
f0100b91:	75 19                	jne    f0100bac <check_page_free_list+0x1c4>
f0100b93:	68 7f 34 10 f0       	push   $0xf010347f
f0100b98:	68 56 34 10 f0       	push   $0xf0103456
f0100b9d:	68 0b 02 00 00       	push   $0x20b
f0100ba2:	68 30 34 10 f0       	push   $0xf0103430
f0100ba7:	e8 03 f5 ff ff       	call   f01000af <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bac:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bb1:	75 19                	jne    f0100bcc <check_page_free_list+0x1e4>
f0100bb3:	68 90 34 10 f0       	push   $0xf0103490
f0100bb8:	68 56 34 10 f0       	push   $0xf0103456
f0100bbd:	68 0c 02 00 00       	push   $0x20c
f0100bc2:	68 30 34 10 f0       	push   $0xf0103430
f0100bc7:	e8 e3 f4 ff ff       	call   f01000af <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bcc:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bd1:	75 19                	jne    f0100bec <check_page_free_list+0x204>
f0100bd3:	68 78 30 10 f0       	push   $0xf0103078
f0100bd8:	68 56 34 10 f0       	push   $0xf0103456
f0100bdd:	68 0d 02 00 00       	push   $0x20d
f0100be2:	68 30 34 10 f0       	push   $0xf0103430
f0100be7:	e8 c3 f4 ff ff       	call   f01000af <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bec:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bf1:	75 19                	jne    f0100c0c <check_page_free_list+0x224>
f0100bf3:	68 a9 34 10 f0       	push   $0xf01034a9
f0100bf8:	68 56 34 10 f0       	push   $0xf0103456
f0100bfd:	68 0e 02 00 00       	push   $0x20e
f0100c02:	68 30 34 10 f0       	push   $0xf0103430
f0100c07:	e8 a3 f4 ff ff       	call   f01000af <_panic>
f0100c0c:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c0e:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c13:	76 3e                	jbe    f0100c53 <check_page_free_list+0x26b>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c15:	c1 e8 0c             	shr    $0xc,%eax
f0100c18:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c1b:	77 12                	ja     f0100c2f <check_page_free_list+0x247>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c1d:	51                   	push   %ecx
f0100c1e:	68 a4 2f 10 f0       	push   $0xf0102fa4
f0100c23:	6a 52                	push   $0x52
f0100c25:	68 3c 34 10 f0       	push   $0xf010343c
f0100c2a:	e8 80 f4 ff ff       	call   f01000af <_panic>
	return (void *)(pa + KERNBASE);
f0100c2f:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100c35:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100c38:	76 1e                	jbe    f0100c58 <check_page_free_list+0x270>
f0100c3a:	68 9c 30 10 f0       	push   $0xf010309c
f0100c3f:	68 56 34 10 f0       	push   $0xf0103456
f0100c44:	68 0f 02 00 00       	push   $0x20f
f0100c49:	68 30 34 10 f0       	push   $0xf0103430
f0100c4e:	e8 5c f4 ff ff       	call   f01000af <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c53:	ff 45 d0             	incl   -0x30(%ebp)
f0100c56:	eb 03                	jmp    f0100c5b <check_page_free_list+0x273>
		else
			++nfree_extmem;
f0100c58:	ff 45 d4             	incl   -0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c5b:	8b 12                	mov    (%edx),%edx
f0100c5d:	85 d2                	test   %edx,%edx
f0100c5f:	0f 85 cb fe ff ff    	jne    f0100b30 <check_page_free_list+0x148>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	cprintf("#3");
f0100c65:	83 ec 0c             	sub    $0xc,%esp
f0100c68:	68 c3 34 10 f0       	push   $0xf01034c3
f0100c6d:	e8 06 0d 00 00       	call   f0101978 <cprintf>

	assert(nfree_basemem > 0);
f0100c72:	83 c4 10             	add    $0x10,%esp
f0100c75:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100c79:	7f 19                	jg     f0100c94 <check_page_free_list+0x2ac>
f0100c7b:	68 c6 34 10 f0       	push   $0xf01034c6
f0100c80:	68 56 34 10 f0       	push   $0xf0103456
f0100c85:	68 19 02 00 00       	push   $0x219
f0100c8a:	68 30 34 10 f0       	push   $0xf0103430
f0100c8f:	e8 1b f4 ff ff       	call   f01000af <_panic>
	assert(nfree_extmem > 0);
f0100c94:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100c98:	7f 2b                	jg     f0100cc5 <check_page_free_list+0x2dd>
f0100c9a:	68 d8 34 10 f0       	push   $0xf01034d8
f0100c9f:	68 56 34 10 f0       	push   $0xf0103456
f0100ca4:	68 1a 02 00 00       	push   $0x21a
f0100ca9:	68 30 34 10 f0       	push   $0xf0103430
f0100cae:	e8 fc f3 ff ff       	call   f01000af <_panic>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	cprintf("#3");
f0100cb3:	83 ec 0c             	sub    $0xc,%esp
f0100cb6:	68 c3 34 10 f0       	push   $0xf01034c3
f0100cbb:	e8 b8 0c 00 00       	call   f0101978 <cprintf>
f0100cc0:	83 c4 10             	add    $0x10,%esp
f0100cc3:	eb b6                	jmp    f0100c7b <check_page_free_list+0x293>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100cc5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cc8:	5b                   	pop    %ebx
f0100cc9:	5e                   	pop    %esi
f0100cca:	5f                   	pop    %edi
f0100ccb:	c9                   	leave  
f0100ccc:	c3                   	ret    

f0100ccd <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100ccd:	55                   	push   %ebp
f0100cce:	89 e5                	mov    %esp,%ebp
f0100cd0:	56                   	push   %esi
f0100cd1:	53                   	push   %ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!

	int i;
	physaddr_t firstFreePhysAddr = (physaddr_t)PADDR(boot_alloc(0));
f0100cd2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cd7:	e8 72 fc ff ff       	call   f010094e <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100cdc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100ce1:	77 15                	ja     f0100cf8 <page_init+0x2b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ce3:	50                   	push   %eax
f0100ce4:	68 e4 30 10 f0       	push   $0xf01030e4
f0100ce9:	68 0e 01 00 00       	push   $0x10e
f0100cee:	68 30 34 10 f0       	push   $0xf0103430
f0100cf3:	e8 b7 f3 ff ff       	call   f01000af <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100cf8:	8d b0 00 00 00 10    	lea    0x10000000(%eax),%esi
	page_free_list = NULL;
f0100cfe:	c7 05 4c b5 11 f0 00 	movl   $0x0,0xf011b54c
f0100d05:	00 00 00 

	for (i = npages - 1; i >= 0; i--)
f0100d08:	a1 64 b9 11 f0       	mov    0xf011b964,%eax
f0100d0d:	89 c2                	mov    %eax,%edx
f0100d0f:	4a                   	dec    %edx
f0100d10:	78 58                	js     f0100d6a <page_init+0x9d>
f0100d12:	8d 0c c5 f8 ff ff ff 	lea    -0x8(,%eax,8),%ecx
// After this is done, NEVER use boot_alloc again.  ONLY use the page
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
f0100d19:	bb 00 00 00 00       	mov    $0x0,%ebx
	page_free_list = NULL;

	for (i = npages - 1; i >= 0; i--)
	{
		physaddr_t pagePhysAddr = (physaddr_t)PGADDR(0, i, 0);
		if (pagePhysAddr == 0 || (IOPHYSMEM <= pagePhysAddr && pagePhysAddr < firstFreePhysAddr))
f0100d1e:	89 d0                	mov    %edx,%eax
f0100d20:	c1 e0 0c             	shl    $0xc,%eax
f0100d23:	74 0b                	je     f0100d30 <page_init+0x63>
f0100d25:	3d ff ff 09 00       	cmp    $0x9ffff,%eax
f0100d2a:	76 1a                	jbe    f0100d46 <page_init+0x79>
f0100d2c:	39 f0                	cmp    %esi,%eax
f0100d2e:	73 16                	jae    f0100d46 <page_init+0x79>
		{
			pages[i].pp_ref = 1;
f0100d30:	89 c8                	mov    %ecx,%eax
f0100d32:	03 05 6c b9 11 f0    	add    0xf011b96c,%eax
f0100d38:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100d3e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100d44:	eb 18                	jmp    f0100d5e <page_init+0x91>
		}
		else
		{
			pages[i].pp_ref = 0;
f0100d46:	89 c8                	mov    %ecx,%eax
f0100d48:	03 05 6c b9 11 f0    	add    0xf011b96c,%eax
f0100d4e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100d54:	89 18                	mov    %ebx,(%eax)
			page_free_list = &pages[i];
f0100d56:	89 cb                	mov    %ecx,%ebx
f0100d58:	03 1d 6c b9 11 f0    	add    0xf011b96c,%ebx

	int i;
	physaddr_t firstFreePhysAddr = (physaddr_t)PADDR(boot_alloc(0));
	page_free_list = NULL;

	for (i = npages - 1; i >= 0; i--)
f0100d5e:	83 e9 08             	sub    $0x8,%ecx
f0100d61:	4a                   	dec    %edx
f0100d62:	79 ba                	jns    f0100d1e <page_init+0x51>
f0100d64:	89 1d 4c b5 11 f0    	mov    %ebx,0xf011b54c
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100d6a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d6d:	5b                   	pop    %ebx
f0100d6e:	5e                   	pop    %esi
f0100d6f:	c9                   	leave  
f0100d70:	c3                   	ret    

f0100d71 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d71:	55                   	push   %ebp
f0100d72:	89 e5                	mov    %esp,%ebp
f0100d74:	53                   	push   %ebx
f0100d75:	83 ec 04             	sub    $0x4,%esp
	struct PageInfo* pageDesc = page_free_list;
f0100d78:	8b 1d 4c b5 11 f0    	mov    0xf011b54c,%ebx

	if(!pageDesc)
f0100d7e:	85 db                	test   %ebx,%ebx
f0100d80:	74 52                	je     f0100dd4 <page_alloc+0x63>
		return NULL;

	page_free_list = page_free_list->pp_link;
f0100d82:	8b 03                	mov    (%ebx),%eax
f0100d84:	a3 4c b5 11 f0       	mov    %eax,0xf011b54c

	if (alloc_flags & ALLOC_ZERO)
f0100d89:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d8d:	74 45                	je     f0100dd4 <page_alloc+0x63>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d8f:	89 d8                	mov    %ebx,%eax
f0100d91:	2b 05 6c b9 11 f0    	sub    0xf011b96c,%eax
f0100d97:	c1 f8 03             	sar    $0x3,%eax
f0100d9a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d9d:	89 c2                	mov    %eax,%edx
f0100d9f:	c1 ea 0c             	shr    $0xc,%edx
f0100da2:	3b 15 64 b9 11 f0    	cmp    0xf011b964,%edx
f0100da8:	72 12                	jb     f0100dbc <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100daa:	50                   	push   %eax
f0100dab:	68 a4 2f 10 f0       	push   $0xf0102fa4
f0100db0:	6a 52                	push   $0x52
f0100db2:	68 3c 34 10 f0       	push   $0xf010343c
f0100db7:	e8 f3 f2 ff ff       	call   f01000af <_panic>
	{
		void* pageKernAddr = page2kva(pageDesc);
		memset(pageKernAddr, 0x00, PGSIZE);
f0100dbc:	83 ec 04             	sub    $0x4,%esp
f0100dbf:	68 00 10 00 00       	push   $0x1000
f0100dc4:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100dc6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dcb:	50                   	push   %eax
f0100dcc:	e8 dc 17 00 00       	call   f01025ad <memset>
f0100dd1:	83 c4 10             	add    $0x10,%esp
	}

	return pageDesc;
}
f0100dd4:	89 d8                	mov    %ebx,%eax
f0100dd6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100dd9:	c9                   	leave  
f0100dda:	c3                   	ret    

f0100ddb <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100ddb:	55                   	push   %ebp
f0100ddc:	89 e5                	mov    %esp,%ebp
f0100dde:	83 ec 08             	sub    $0x8,%esp
f0100de1:	8b 45 08             	mov    0x8(%ebp),%eax
	if(pp->pp_ref == 0)
f0100de4:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100de9:	75 0f                	jne    f0100dfa <page_free+0x1f>
	{
		pp->pp_link = page_free_list;
f0100deb:	8b 15 4c b5 11 f0    	mov    0xf011b54c,%edx
f0100df1:	89 10                	mov    %edx,(%eax)
		page_free_list = pp;
f0100df3:	a3 4c b5 11 f0       	mov    %eax,0xf011b54c
	}
	else
	{
		panic("page_free: page(desc:%p) still have reference\n", pp);
	}
}
f0100df8:	c9                   	leave  
f0100df9:	c3                   	ret    
		pp->pp_link = page_free_list;
		page_free_list = pp;
	}
	else
	{
		panic("page_free: page(desc:%p) still have reference\n", pp);
f0100dfa:	50                   	push   %eax
f0100dfb:	68 08 31 10 f0       	push   $0xf0103108
f0100e00:	68 4c 01 00 00       	push   $0x14c
f0100e05:	68 30 34 10 f0       	push   $0xf0103430
f0100e0a:	e8 a0 f2 ff ff       	call   f01000af <_panic>

f0100e0f <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e0f:	55                   	push   %ebp
f0100e10:	89 e5                	mov    %esp,%ebp
f0100e12:	83 ec 08             	sub    $0x8,%esp
f0100e15:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100e18:	8b 50 04             	mov    0x4(%eax),%edx
f0100e1b:	4a                   	dec    %edx
f0100e1c:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100e20:	66 85 d2             	test   %dx,%dx
f0100e23:	75 0c                	jne    f0100e31 <page_decref+0x22>
		page_free(pp);
f0100e25:	83 ec 0c             	sub    $0xc,%esp
f0100e28:	50                   	push   %eax
f0100e29:	e8 ad ff ff ff       	call   f0100ddb <page_free>
f0100e2e:	83 c4 10             	add    $0x10,%esp
}
f0100e31:	c9                   	leave  
f0100e32:	c3                   	ret    

f0100e33 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e33:	55                   	push   %ebp
f0100e34:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100e36:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e3b:	c9                   	leave  
f0100e3c:	c3                   	ret    

f0100e3d <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100e3d:	55                   	push   %ebp
f0100e3e:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100e40:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e45:	c9                   	leave  
f0100e46:	c3                   	ret    

f0100e47 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100e47:	55                   	push   %ebp
f0100e48:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100e4a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e4f:	c9                   	leave  
f0100e50:	c3                   	ret    

f0100e51 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100e51:	55                   	push   %ebp
f0100e52:	89 e5                	mov    %esp,%ebp
f0100e54:	57                   	push   %edi
f0100e55:	56                   	push   %esi
f0100e56:	53                   	push   %ebx
f0100e57:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100e5a:	b8 15 00 00 00       	mov    $0x15,%eax
f0100e5f:	e8 5d fb ff ff       	call   f01009c1 <nvram_read>
f0100e64:	c1 e0 0a             	shl    $0xa,%eax
f0100e67:	89 c2                	mov    %eax,%edx
f0100e69:	85 c0                	test   %eax,%eax
f0100e6b:	79 06                	jns    f0100e73 <mem_init+0x22>
f0100e6d:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100e73:	c1 fa 0c             	sar    $0xc,%edx
f0100e76:	89 15 54 b5 11 f0    	mov    %edx,0xf011b554
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100e7c:	b8 17 00 00 00       	mov    $0x17,%eax
f0100e81:	e8 3b fb ff ff       	call   f01009c1 <nvram_read>
f0100e86:	89 c2                	mov    %eax,%edx
f0100e88:	c1 e2 0a             	shl    $0xa,%edx
f0100e8b:	89 d0                	mov    %edx,%eax
f0100e8d:	85 d2                	test   %edx,%edx
f0100e8f:	79 06                	jns    f0100e97 <mem_init+0x46>
f0100e91:	8d 82 ff 0f 00 00    	lea    0xfff(%edx),%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0100e97:	c1 f8 0c             	sar    $0xc,%eax
f0100e9a:	74 0e                	je     f0100eaa <mem_init+0x59>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100e9c:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0100ea2:	89 15 64 b9 11 f0    	mov    %edx,0xf011b964
f0100ea8:	eb 0c                	jmp    f0100eb6 <mem_init+0x65>
	else
		npages = npages_basemem;
f0100eaa:	8b 15 54 b5 11 f0    	mov    0xf011b554,%edx
f0100eb0:	89 15 64 b9 11 f0    	mov    %edx,0xf011b964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0100eb6:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100eb9:	c1 e8 0a             	shr    $0xa,%eax
f0100ebc:	50                   	push   %eax
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0100ebd:	a1 54 b5 11 f0       	mov    0xf011b554,%eax
f0100ec2:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100ec5:	c1 e8 0a             	shr    $0xa,%eax
f0100ec8:	50                   	push   %eax
		npages * PGSIZE / 1024,
f0100ec9:	a1 64 b9 11 f0       	mov    0xf011b964,%eax
f0100ece:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100ed1:	c1 e8 0a             	shr    $0xa,%eax
f0100ed4:	50                   	push   %eax
f0100ed5:	68 38 31 10 f0       	push   $0xf0103138
f0100eda:	e8 99 0a 00 00       	call   f0101978 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100edf:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100ee4:	e8 65 fa ff ff       	call   f010094e <boot_alloc>
f0100ee9:	a3 68 b9 11 f0       	mov    %eax,0xf011b968
	memset(kern_pgdir, 0, PGSIZE);
f0100eee:	83 c4 0c             	add    $0xc,%esp
f0100ef1:	68 00 10 00 00       	push   $0x1000
f0100ef6:	6a 00                	push   $0x0
f0100ef8:	50                   	push   %eax
f0100ef9:	e8 af 16 00 00       	call   f01025ad <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100efe:	a1 68 b9 11 f0       	mov    0xf011b968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100f03:	83 c4 10             	add    $0x10,%esp
f0100f06:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f0b:	77 15                	ja     f0100f22 <mem_init+0xd1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f0d:	50                   	push   %eax
f0100f0e:	68 e4 30 10 f0       	push   $0xf01030e4
f0100f13:	68 9b 00 00 00       	push   $0x9b
f0100f18:	68 30 34 10 f0       	push   $0xf0103430
f0100f1d:	e8 8d f1 ff ff       	call   f01000af <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100f22:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100f28:	83 ca 05             	or     $0x5,%edx
f0100f2b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:

	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f0100f31:	a1 64 b9 11 f0       	mov    0xf011b964,%eax
f0100f36:	c1 e0 03             	shl    $0x3,%eax
f0100f39:	e8 10 fa ff ff       	call   f010094e <boot_alloc>
f0100f3e:	a3 6c b9 11 f0       	mov    %eax,0xf011b96c
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0100f43:	e8 85 fd ff ff       	call   f0100ccd <page_init>

	check_page_free_list(1);
f0100f48:	b8 01 00 00 00       	mov    $0x1,%eax
f0100f4d:	e8 96 fa ff ff       	call   f01009e8 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0100f52:	83 3d 6c b9 11 f0 00 	cmpl   $0x0,0xf011b96c
f0100f59:	75 17                	jne    f0100f72 <mem_init+0x121>
		panic("'pages' is a null pointer!");
f0100f5b:	83 ec 04             	sub    $0x4,%esp
f0100f5e:	68 e9 34 10 f0       	push   $0xf01034e9
f0100f63:	68 2b 02 00 00       	push   $0x22b
f0100f68:	68 30 34 10 f0       	push   $0xf0103430
f0100f6d:	e8 3d f1 ff ff       	call   f01000af <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f72:	a1 4c b5 11 f0       	mov    0xf011b54c,%eax
f0100f77:	85 c0                	test   %eax,%eax
f0100f79:	74 0e                	je     f0100f89 <mem_init+0x138>
f0100f7b:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
f0100f80:	43                   	inc    %ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f81:	8b 00                	mov    (%eax),%eax
f0100f83:	85 c0                	test   %eax,%eax
f0100f85:	75 f9                	jne    f0100f80 <mem_init+0x12f>
f0100f87:	eb 05                	jmp    f0100f8e <mem_init+0x13d>
f0100f89:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0100f8e:	83 ec 0c             	sub    $0xc,%esp
f0100f91:	6a 00                	push   $0x0
f0100f93:	e8 d9 fd ff ff       	call   f0100d71 <page_alloc>
f0100f98:	89 c6                	mov    %eax,%esi
f0100f9a:	83 c4 10             	add    $0x10,%esp
f0100f9d:	85 c0                	test   %eax,%eax
f0100f9f:	75 19                	jne    f0100fba <mem_init+0x169>
f0100fa1:	68 04 35 10 f0       	push   $0xf0103504
f0100fa6:	68 56 34 10 f0       	push   $0xf0103456
f0100fab:	68 33 02 00 00       	push   $0x233
f0100fb0:	68 30 34 10 f0       	push   $0xf0103430
f0100fb5:	e8 f5 f0 ff ff       	call   f01000af <_panic>
	assert((pp1 = page_alloc(0)));
f0100fba:	83 ec 0c             	sub    $0xc,%esp
f0100fbd:	6a 00                	push   $0x0
f0100fbf:	e8 ad fd ff ff       	call   f0100d71 <page_alloc>
f0100fc4:	89 c7                	mov    %eax,%edi
f0100fc6:	83 c4 10             	add    $0x10,%esp
f0100fc9:	85 c0                	test   %eax,%eax
f0100fcb:	75 19                	jne    f0100fe6 <mem_init+0x195>
f0100fcd:	68 1a 35 10 f0       	push   $0xf010351a
f0100fd2:	68 56 34 10 f0       	push   $0xf0103456
f0100fd7:	68 34 02 00 00       	push   $0x234
f0100fdc:	68 30 34 10 f0       	push   $0xf0103430
f0100fe1:	e8 c9 f0 ff ff       	call   f01000af <_panic>
	assert((pp2 = page_alloc(0)));
f0100fe6:	83 ec 0c             	sub    $0xc,%esp
f0100fe9:	6a 00                	push   $0x0
f0100feb:	e8 81 fd ff ff       	call   f0100d71 <page_alloc>
f0100ff0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100ff3:	83 c4 10             	add    $0x10,%esp
f0100ff6:	85 c0                	test   %eax,%eax
f0100ff8:	75 19                	jne    f0101013 <mem_init+0x1c2>
f0100ffa:	68 30 35 10 f0       	push   $0xf0103530
f0100fff:	68 56 34 10 f0       	push   $0xf0103456
f0101004:	68 35 02 00 00       	push   $0x235
f0101009:	68 30 34 10 f0       	push   $0xf0103430
f010100e:	e8 9c f0 ff ff       	call   f01000af <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101013:	39 fe                	cmp    %edi,%esi
f0101015:	75 19                	jne    f0101030 <mem_init+0x1df>
f0101017:	68 46 35 10 f0       	push   $0xf0103546
f010101c:	68 56 34 10 f0       	push   $0xf0103456
f0101021:	68 38 02 00 00       	push   $0x238
f0101026:	68 30 34 10 f0       	push   $0xf0103430
f010102b:	e8 7f f0 ff ff       	call   f01000af <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101030:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101033:	74 05                	je     f010103a <mem_init+0x1e9>
f0101035:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101038:	75 19                	jne    f0101053 <mem_init+0x202>
f010103a:	68 74 31 10 f0       	push   $0xf0103174
f010103f:	68 56 34 10 f0       	push   $0xf0103456
f0101044:	68 39 02 00 00       	push   $0x239
f0101049:	68 30 34 10 f0       	push   $0xf0103430
f010104e:	e8 5c f0 ff ff       	call   f01000af <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101053:	8b 15 6c b9 11 f0    	mov    0xf011b96c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101059:	a1 64 b9 11 f0       	mov    0xf011b964,%eax
f010105e:	c1 e0 0c             	shl    $0xc,%eax
f0101061:	89 f1                	mov    %esi,%ecx
f0101063:	29 d1                	sub    %edx,%ecx
f0101065:	c1 f9 03             	sar    $0x3,%ecx
f0101068:	c1 e1 0c             	shl    $0xc,%ecx
f010106b:	39 c1                	cmp    %eax,%ecx
f010106d:	72 19                	jb     f0101088 <mem_init+0x237>
f010106f:	68 58 35 10 f0       	push   $0xf0103558
f0101074:	68 56 34 10 f0       	push   $0xf0103456
f0101079:	68 3a 02 00 00       	push   $0x23a
f010107e:	68 30 34 10 f0       	push   $0xf0103430
f0101083:	e8 27 f0 ff ff       	call   f01000af <_panic>
f0101088:	89 f9                	mov    %edi,%ecx
f010108a:	29 d1                	sub    %edx,%ecx
f010108c:	c1 f9 03             	sar    $0x3,%ecx
f010108f:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101092:	39 c8                	cmp    %ecx,%eax
f0101094:	77 19                	ja     f01010af <mem_init+0x25e>
f0101096:	68 75 35 10 f0       	push   $0xf0103575
f010109b:	68 56 34 10 f0       	push   $0xf0103456
f01010a0:	68 3b 02 00 00       	push   $0x23b
f01010a5:	68 30 34 10 f0       	push   $0xf0103430
f01010aa:	e8 00 f0 ff ff       	call   f01000af <_panic>
f01010af:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01010b2:	29 d1                	sub    %edx,%ecx
f01010b4:	89 ca                	mov    %ecx,%edx
f01010b6:	c1 fa 03             	sar    $0x3,%edx
f01010b9:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01010bc:	39 d0                	cmp    %edx,%eax
f01010be:	77 19                	ja     f01010d9 <mem_init+0x288>
f01010c0:	68 92 35 10 f0       	push   $0xf0103592
f01010c5:	68 56 34 10 f0       	push   $0xf0103456
f01010ca:	68 3c 02 00 00       	push   $0x23c
f01010cf:	68 30 34 10 f0       	push   $0xf0103430
f01010d4:	e8 d6 ef ff ff       	call   f01000af <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01010d9:	a1 4c b5 11 f0       	mov    0xf011b54c,%eax
f01010de:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01010e1:	c7 05 4c b5 11 f0 00 	movl   $0x0,0xf011b54c
f01010e8:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01010eb:	83 ec 0c             	sub    $0xc,%esp
f01010ee:	6a 00                	push   $0x0
f01010f0:	e8 7c fc ff ff       	call   f0100d71 <page_alloc>
f01010f5:	83 c4 10             	add    $0x10,%esp
f01010f8:	85 c0                	test   %eax,%eax
f01010fa:	74 19                	je     f0101115 <mem_init+0x2c4>
f01010fc:	68 af 35 10 f0       	push   $0xf01035af
f0101101:	68 56 34 10 f0       	push   $0xf0103456
f0101106:	68 43 02 00 00       	push   $0x243
f010110b:	68 30 34 10 f0       	push   $0xf0103430
f0101110:	e8 9a ef ff ff       	call   f01000af <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101115:	83 ec 0c             	sub    $0xc,%esp
f0101118:	56                   	push   %esi
f0101119:	e8 bd fc ff ff       	call   f0100ddb <page_free>
	page_free(pp1);
f010111e:	89 3c 24             	mov    %edi,(%esp)
f0101121:	e8 b5 fc ff ff       	call   f0100ddb <page_free>
	page_free(pp2);
f0101126:	83 c4 04             	add    $0x4,%esp
f0101129:	ff 75 d4             	pushl  -0x2c(%ebp)
f010112c:	e8 aa fc ff ff       	call   f0100ddb <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101131:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101138:	e8 34 fc ff ff       	call   f0100d71 <page_alloc>
f010113d:	89 c6                	mov    %eax,%esi
f010113f:	83 c4 10             	add    $0x10,%esp
f0101142:	85 c0                	test   %eax,%eax
f0101144:	75 19                	jne    f010115f <mem_init+0x30e>
f0101146:	68 04 35 10 f0       	push   $0xf0103504
f010114b:	68 56 34 10 f0       	push   $0xf0103456
f0101150:	68 4a 02 00 00       	push   $0x24a
f0101155:	68 30 34 10 f0       	push   $0xf0103430
f010115a:	e8 50 ef ff ff       	call   f01000af <_panic>
	assert((pp1 = page_alloc(0)));
f010115f:	83 ec 0c             	sub    $0xc,%esp
f0101162:	6a 00                	push   $0x0
f0101164:	e8 08 fc ff ff       	call   f0100d71 <page_alloc>
f0101169:	89 c7                	mov    %eax,%edi
f010116b:	83 c4 10             	add    $0x10,%esp
f010116e:	85 c0                	test   %eax,%eax
f0101170:	75 19                	jne    f010118b <mem_init+0x33a>
f0101172:	68 1a 35 10 f0       	push   $0xf010351a
f0101177:	68 56 34 10 f0       	push   $0xf0103456
f010117c:	68 4b 02 00 00       	push   $0x24b
f0101181:	68 30 34 10 f0       	push   $0xf0103430
f0101186:	e8 24 ef ff ff       	call   f01000af <_panic>
	assert((pp2 = page_alloc(0)));
f010118b:	83 ec 0c             	sub    $0xc,%esp
f010118e:	6a 00                	push   $0x0
f0101190:	e8 dc fb ff ff       	call   f0100d71 <page_alloc>
f0101195:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101198:	83 c4 10             	add    $0x10,%esp
f010119b:	85 c0                	test   %eax,%eax
f010119d:	75 19                	jne    f01011b8 <mem_init+0x367>
f010119f:	68 30 35 10 f0       	push   $0xf0103530
f01011a4:	68 56 34 10 f0       	push   $0xf0103456
f01011a9:	68 4c 02 00 00       	push   $0x24c
f01011ae:	68 30 34 10 f0       	push   $0xf0103430
f01011b3:	e8 f7 ee ff ff       	call   f01000af <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011b8:	39 fe                	cmp    %edi,%esi
f01011ba:	75 19                	jne    f01011d5 <mem_init+0x384>
f01011bc:	68 46 35 10 f0       	push   $0xf0103546
f01011c1:	68 56 34 10 f0       	push   $0xf0103456
f01011c6:	68 4e 02 00 00       	push   $0x24e
f01011cb:	68 30 34 10 f0       	push   $0xf0103430
f01011d0:	e8 da ee ff ff       	call   f01000af <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01011d5:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01011d8:	74 05                	je     f01011df <mem_init+0x38e>
f01011da:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01011dd:	75 19                	jne    f01011f8 <mem_init+0x3a7>
f01011df:	68 74 31 10 f0       	push   $0xf0103174
f01011e4:	68 56 34 10 f0       	push   $0xf0103456
f01011e9:	68 4f 02 00 00       	push   $0x24f
f01011ee:	68 30 34 10 f0       	push   $0xf0103430
f01011f3:	e8 b7 ee ff ff       	call   f01000af <_panic>
	assert(!page_alloc(0));
f01011f8:	83 ec 0c             	sub    $0xc,%esp
f01011fb:	6a 00                	push   $0x0
f01011fd:	e8 6f fb ff ff       	call   f0100d71 <page_alloc>
f0101202:	83 c4 10             	add    $0x10,%esp
f0101205:	85 c0                	test   %eax,%eax
f0101207:	74 19                	je     f0101222 <mem_init+0x3d1>
f0101209:	68 af 35 10 f0       	push   $0xf01035af
f010120e:	68 56 34 10 f0       	push   $0xf0103456
f0101213:	68 50 02 00 00       	push   $0x250
f0101218:	68 30 34 10 f0       	push   $0xf0103430
f010121d:	e8 8d ee ff ff       	call   f01000af <_panic>
f0101222:	89 f0                	mov    %esi,%eax
f0101224:	2b 05 6c b9 11 f0    	sub    0xf011b96c,%eax
f010122a:	c1 f8 03             	sar    $0x3,%eax
f010122d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101230:	89 c2                	mov    %eax,%edx
f0101232:	c1 ea 0c             	shr    $0xc,%edx
f0101235:	3b 15 64 b9 11 f0    	cmp    0xf011b964,%edx
f010123b:	72 12                	jb     f010124f <mem_init+0x3fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010123d:	50                   	push   %eax
f010123e:	68 a4 2f 10 f0       	push   $0xf0102fa4
f0101243:	6a 52                	push   $0x52
f0101245:	68 3c 34 10 f0       	push   $0xf010343c
f010124a:	e8 60 ee ff ff       	call   f01000af <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010124f:	83 ec 04             	sub    $0x4,%esp
f0101252:	68 00 10 00 00       	push   $0x1000
f0101257:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101259:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010125e:	50                   	push   %eax
f010125f:	e8 49 13 00 00       	call   f01025ad <memset>
	page_free(pp0);
f0101264:	89 34 24             	mov    %esi,(%esp)
f0101267:	e8 6f fb ff ff       	call   f0100ddb <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010126c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101273:	e8 f9 fa ff ff       	call   f0100d71 <page_alloc>
f0101278:	83 c4 10             	add    $0x10,%esp
f010127b:	85 c0                	test   %eax,%eax
f010127d:	75 19                	jne    f0101298 <mem_init+0x447>
f010127f:	68 be 35 10 f0       	push   $0xf01035be
f0101284:	68 56 34 10 f0       	push   $0xf0103456
f0101289:	68 55 02 00 00       	push   $0x255
f010128e:	68 30 34 10 f0       	push   $0xf0103430
f0101293:	e8 17 ee ff ff       	call   f01000af <_panic>
	assert(pp && pp0 == pp);
f0101298:	39 c6                	cmp    %eax,%esi
f010129a:	74 19                	je     f01012b5 <mem_init+0x464>
f010129c:	68 dc 35 10 f0       	push   $0xf01035dc
f01012a1:	68 56 34 10 f0       	push   $0xf0103456
f01012a6:	68 56 02 00 00       	push   $0x256
f01012ab:	68 30 34 10 f0       	push   $0xf0103430
f01012b0:	e8 fa ed ff ff       	call   f01000af <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012b5:	89 f2                	mov    %esi,%edx
f01012b7:	2b 15 6c b9 11 f0    	sub    0xf011b96c,%edx
f01012bd:	c1 fa 03             	sar    $0x3,%edx
f01012c0:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012c3:	89 d0                	mov    %edx,%eax
f01012c5:	c1 e8 0c             	shr    $0xc,%eax
f01012c8:	3b 05 64 b9 11 f0    	cmp    0xf011b964,%eax
f01012ce:	72 12                	jb     f01012e2 <mem_init+0x491>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012d0:	52                   	push   %edx
f01012d1:	68 a4 2f 10 f0       	push   $0xf0102fa4
f01012d6:	6a 52                	push   $0x52
f01012d8:	68 3c 34 10 f0       	push   $0xf010343c
f01012dd:	e8 cd ed ff ff       	call   f01000af <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01012e2:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f01012e9:	75 11                	jne    f01012fc <mem_init+0x4ab>
f01012eb:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01012f1:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01012f7:	80 38 00             	cmpb   $0x0,(%eax)
f01012fa:	74 19                	je     f0101315 <mem_init+0x4c4>
f01012fc:	68 ec 35 10 f0       	push   $0xf01035ec
f0101301:	68 56 34 10 f0       	push   $0xf0103456
f0101306:	68 59 02 00 00       	push   $0x259
f010130b:	68 30 34 10 f0       	push   $0xf0103430
f0101310:	e8 9a ed ff ff       	call   f01000af <_panic>
f0101315:	40                   	inc    %eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101316:	39 d0                	cmp    %edx,%eax
f0101318:	75 dd                	jne    f01012f7 <mem_init+0x4a6>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010131a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010131d:	89 0d 4c b5 11 f0    	mov    %ecx,0xf011b54c

	// free the pages we took
	page_free(pp0);
f0101323:	83 ec 0c             	sub    $0xc,%esp
f0101326:	56                   	push   %esi
f0101327:	e8 af fa ff ff       	call   f0100ddb <page_free>
	page_free(pp1);
f010132c:	89 3c 24             	mov    %edi,(%esp)
f010132f:	e8 a7 fa ff ff       	call   f0100ddb <page_free>
	page_free(pp2);
f0101334:	83 c4 04             	add    $0x4,%esp
f0101337:	ff 75 d4             	pushl  -0x2c(%ebp)
f010133a:	e8 9c fa ff ff       	call   f0100ddb <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010133f:	a1 4c b5 11 f0       	mov    0xf011b54c,%eax
f0101344:	83 c4 10             	add    $0x10,%esp
f0101347:	85 c0                	test   %eax,%eax
f0101349:	74 07                	je     f0101352 <mem_init+0x501>
		--nfree;
f010134b:	4b                   	dec    %ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010134c:	8b 00                	mov    (%eax),%eax
f010134e:	85 c0                	test   %eax,%eax
f0101350:	75 f9                	jne    f010134b <mem_init+0x4fa>
		--nfree;
	assert(nfree == 0);
f0101352:	85 db                	test   %ebx,%ebx
f0101354:	74 19                	je     f010136f <mem_init+0x51e>
f0101356:	68 f6 35 10 f0       	push   $0xf01035f6
f010135b:	68 56 34 10 f0       	push   $0xf0103456
f0101360:	68 66 02 00 00       	push   $0x266
f0101365:	68 30 34 10 f0       	push   $0xf0103430
f010136a:	e8 40 ed ff ff       	call   f01000af <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010136f:	83 ec 0c             	sub    $0xc,%esp
f0101372:	68 94 31 10 f0       	push   $0xf0103194
f0101377:	e8 fc 05 00 00       	call   f0101978 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010137c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101383:	e8 e9 f9 ff ff       	call   f0100d71 <page_alloc>
f0101388:	89 c7                	mov    %eax,%edi
f010138a:	83 c4 10             	add    $0x10,%esp
f010138d:	85 c0                	test   %eax,%eax
f010138f:	75 19                	jne    f01013aa <mem_init+0x559>
f0101391:	68 04 35 10 f0       	push   $0xf0103504
f0101396:	68 56 34 10 f0       	push   $0xf0103456
f010139b:	68 bf 02 00 00       	push   $0x2bf
f01013a0:	68 30 34 10 f0       	push   $0xf0103430
f01013a5:	e8 05 ed ff ff       	call   f01000af <_panic>
	assert((pp1 = page_alloc(0)));
f01013aa:	83 ec 0c             	sub    $0xc,%esp
f01013ad:	6a 00                	push   $0x0
f01013af:	e8 bd f9 ff ff       	call   f0100d71 <page_alloc>
f01013b4:	89 c6                	mov    %eax,%esi
f01013b6:	83 c4 10             	add    $0x10,%esp
f01013b9:	85 c0                	test   %eax,%eax
f01013bb:	75 19                	jne    f01013d6 <mem_init+0x585>
f01013bd:	68 1a 35 10 f0       	push   $0xf010351a
f01013c2:	68 56 34 10 f0       	push   $0xf0103456
f01013c7:	68 c0 02 00 00       	push   $0x2c0
f01013cc:	68 30 34 10 f0       	push   $0xf0103430
f01013d1:	e8 d9 ec ff ff       	call   f01000af <_panic>
	assert((pp2 = page_alloc(0)));
f01013d6:	83 ec 0c             	sub    $0xc,%esp
f01013d9:	6a 00                	push   $0x0
f01013db:	e8 91 f9 ff ff       	call   f0100d71 <page_alloc>
f01013e0:	89 c3                	mov    %eax,%ebx
f01013e2:	83 c4 10             	add    $0x10,%esp
f01013e5:	85 c0                	test   %eax,%eax
f01013e7:	75 19                	jne    f0101402 <mem_init+0x5b1>
f01013e9:	68 30 35 10 f0       	push   $0xf0103530
f01013ee:	68 56 34 10 f0       	push   $0xf0103456
f01013f3:	68 c1 02 00 00       	push   $0x2c1
f01013f8:	68 30 34 10 f0       	push   $0xf0103430
f01013fd:	e8 ad ec ff ff       	call   f01000af <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101402:	39 f7                	cmp    %esi,%edi
f0101404:	75 19                	jne    f010141f <mem_init+0x5ce>
f0101406:	68 46 35 10 f0       	push   $0xf0103546
f010140b:	68 56 34 10 f0       	push   $0xf0103456
f0101410:	68 c4 02 00 00       	push   $0x2c4
f0101415:	68 30 34 10 f0       	push   $0xf0103430
f010141a:	e8 90 ec ff ff       	call   f01000af <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010141f:	39 c6                	cmp    %eax,%esi
f0101421:	74 04                	je     f0101427 <mem_init+0x5d6>
f0101423:	39 c7                	cmp    %eax,%edi
f0101425:	75 19                	jne    f0101440 <mem_init+0x5ef>
f0101427:	68 74 31 10 f0       	push   $0xf0103174
f010142c:	68 56 34 10 f0       	push   $0xf0103456
f0101431:	68 c5 02 00 00       	push   $0x2c5
f0101436:	68 30 34 10 f0       	push   $0xf0103430
f010143b:	e8 6f ec ff ff       	call   f01000af <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f0101440:	c7 05 4c b5 11 f0 00 	movl   $0x0,0xf011b54c
f0101447:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010144a:	83 ec 0c             	sub    $0xc,%esp
f010144d:	6a 00                	push   $0x0
f010144f:	e8 1d f9 ff ff       	call   f0100d71 <page_alloc>
f0101454:	83 c4 10             	add    $0x10,%esp
f0101457:	85 c0                	test   %eax,%eax
f0101459:	74 19                	je     f0101474 <mem_init+0x623>
f010145b:	68 af 35 10 f0       	push   $0xf01035af
f0101460:	68 56 34 10 f0       	push   $0xf0103456
f0101465:	68 cc 02 00 00       	push   $0x2cc
f010146a:	68 30 34 10 f0       	push   $0xf0103430
f010146f:	e8 3b ec ff ff       	call   f01000af <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101474:	a1 68 b9 11 f0       	mov    0xf011b968,%eax
f0101479:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010147c:	83 ec 04             	sub    $0x4,%esp
f010147f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101482:	50                   	push   %eax
f0101483:	6a 00                	push   $0x0
f0101485:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101488:	e8 ba f9 ff ff       	call   f0100e47 <page_lookup>
f010148d:	83 c4 10             	add    $0x10,%esp
f0101490:	85 c0                	test   %eax,%eax
f0101492:	74 19                	je     f01014ad <mem_init+0x65c>
f0101494:	68 b4 31 10 f0       	push   $0xf01031b4
f0101499:	68 56 34 10 f0       	push   $0xf0103456
f010149e:	68 cf 02 00 00       	push   $0x2cf
f01014a3:	68 30 34 10 f0       	push   $0xf0103430
f01014a8:	e8 02 ec ff ff       	call   f01000af <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01014ad:	6a 02                	push   $0x2
f01014af:	6a 00                	push   $0x0
f01014b1:	56                   	push   %esi
f01014b2:	ff 75 d4             	pushl  -0x2c(%ebp)
f01014b5:	e8 83 f9 ff ff       	call   f0100e3d <page_insert>
f01014ba:	83 c4 10             	add    $0x10,%esp
f01014bd:	85 c0                	test   %eax,%eax
f01014bf:	78 19                	js     f01014da <mem_init+0x689>
f01014c1:	68 ec 31 10 f0       	push   $0xf01031ec
f01014c6:	68 56 34 10 f0       	push   $0xf0103456
f01014cb:	68 d2 02 00 00       	push   $0x2d2
f01014d0:	68 30 34 10 f0       	push   $0xf0103430
f01014d5:	e8 d5 eb ff ff       	call   f01000af <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01014da:	83 ec 0c             	sub    $0xc,%esp
f01014dd:	57                   	push   %edi
f01014de:	e8 f8 f8 ff ff       	call   f0100ddb <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01014e3:	8b 0d 68 b9 11 f0    	mov    0xf011b968,%ecx
f01014e9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01014ec:	6a 02                	push   $0x2
f01014ee:	6a 00                	push   $0x0
f01014f0:	56                   	push   %esi
f01014f1:	51                   	push   %ecx
f01014f2:	e8 46 f9 ff ff       	call   f0100e3d <page_insert>
f01014f7:	83 c4 20             	add    $0x20,%esp
f01014fa:	85 c0                	test   %eax,%eax
f01014fc:	74 19                	je     f0101517 <mem_init+0x6c6>
f01014fe:	68 1c 32 10 f0       	push   $0xf010321c
f0101503:	68 56 34 10 f0       	push   $0xf0103456
f0101508:	68 d6 02 00 00       	push   $0x2d6
f010150d:	68 30 34 10 f0       	push   $0xf0103430
f0101512:	e8 98 eb ff ff       	call   f01000af <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101517:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010151a:	8b 10                	mov    (%eax),%edx
f010151c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101522:	89 f8                	mov    %edi,%eax
f0101524:	2b 05 6c b9 11 f0    	sub    0xf011b96c,%eax
f010152a:	c1 f8 03             	sar    $0x3,%eax
f010152d:	c1 e0 0c             	shl    $0xc,%eax
f0101530:	39 c2                	cmp    %eax,%edx
f0101532:	74 19                	je     f010154d <mem_init+0x6fc>
f0101534:	68 4c 32 10 f0       	push   $0xf010324c
f0101539:	68 56 34 10 f0       	push   $0xf0103456
f010153e:	68 d7 02 00 00       	push   $0x2d7
f0101543:	68 30 34 10 f0       	push   $0xf0103430
f0101548:	e8 62 eb ff ff       	call   f01000af <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010154d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101552:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101555:	e8 92 f3 ff ff       	call   f01008ec <check_va2pa>
f010155a:	89 f2                	mov    %esi,%edx
f010155c:	2b 15 6c b9 11 f0    	sub    0xf011b96c,%edx
f0101562:	c1 fa 03             	sar    $0x3,%edx
f0101565:	c1 e2 0c             	shl    $0xc,%edx
f0101568:	39 d0                	cmp    %edx,%eax
f010156a:	74 19                	je     f0101585 <mem_init+0x734>
f010156c:	68 74 32 10 f0       	push   $0xf0103274
f0101571:	68 56 34 10 f0       	push   $0xf0103456
f0101576:	68 d8 02 00 00       	push   $0x2d8
f010157b:	68 30 34 10 f0       	push   $0xf0103430
f0101580:	e8 2a eb ff ff       	call   f01000af <_panic>
	assert(pp1->pp_ref == 1);
f0101585:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010158a:	74 19                	je     f01015a5 <mem_init+0x754>
f010158c:	68 01 36 10 f0       	push   $0xf0103601
f0101591:	68 56 34 10 f0       	push   $0xf0103456
f0101596:	68 d9 02 00 00       	push   $0x2d9
f010159b:	68 30 34 10 f0       	push   $0xf0103430
f01015a0:	e8 0a eb ff ff       	call   f01000af <_panic>
	assert(pp0->pp_ref == 1);
f01015a5:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01015aa:	74 19                	je     f01015c5 <mem_init+0x774>
f01015ac:	68 12 36 10 f0       	push   $0xf0103612
f01015b1:	68 56 34 10 f0       	push   $0xf0103456
f01015b6:	68 da 02 00 00       	push   $0x2da
f01015bb:	68 30 34 10 f0       	push   $0xf0103430
f01015c0:	e8 ea ea ff ff       	call   f01000af <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01015c5:	8b 35 68 b9 11 f0    	mov    0xf011b968,%esi
f01015cb:	6a 02                	push   $0x2
f01015cd:	68 00 10 00 00       	push   $0x1000
f01015d2:	53                   	push   %ebx
f01015d3:	56                   	push   %esi
f01015d4:	e8 64 f8 ff ff       	call   f0100e3d <page_insert>
f01015d9:	83 c4 10             	add    $0x10,%esp
f01015dc:	85 c0                	test   %eax,%eax
f01015de:	74 19                	je     f01015f9 <mem_init+0x7a8>
f01015e0:	68 a4 32 10 f0       	push   $0xf01032a4
f01015e5:	68 56 34 10 f0       	push   $0xf0103456
f01015ea:	68 dd 02 00 00       	push   $0x2dd
f01015ef:	68 30 34 10 f0       	push   $0xf0103430
f01015f4:	e8 b6 ea ff ff       	call   f01000af <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01015f9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01015fe:	89 f0                	mov    %esi,%eax
f0101600:	e8 e7 f2 ff ff       	call   f01008ec <check_va2pa>
f0101605:	89 da                	mov    %ebx,%edx
f0101607:	2b 15 6c b9 11 f0    	sub    0xf011b96c,%edx
f010160d:	c1 fa 03             	sar    $0x3,%edx
f0101610:	c1 e2 0c             	shl    $0xc,%edx
f0101613:	39 d0                	cmp    %edx,%eax
f0101615:	74 19                	je     f0101630 <mem_init+0x7df>
f0101617:	68 e0 32 10 f0       	push   $0xf01032e0
f010161c:	68 56 34 10 f0       	push   $0xf0103456
f0101621:	68 de 02 00 00       	push   $0x2de
f0101626:	68 30 34 10 f0       	push   $0xf0103430
f010162b:	e8 7f ea ff ff       	call   f01000af <_panic>
	assert(pp2->pp_ref == 1);
f0101630:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101635:	74 19                	je     f0101650 <mem_init+0x7ff>
f0101637:	68 23 36 10 f0       	push   $0xf0103623
f010163c:	68 56 34 10 f0       	push   $0xf0103456
f0101641:	68 df 02 00 00       	push   $0x2df
f0101646:	68 30 34 10 f0       	push   $0xf0103430
f010164b:	e8 5f ea ff ff       	call   f01000af <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101650:	83 ec 0c             	sub    $0xc,%esp
f0101653:	6a 00                	push   $0x0
f0101655:	e8 17 f7 ff ff       	call   f0100d71 <page_alloc>
f010165a:	83 c4 10             	add    $0x10,%esp
f010165d:	85 c0                	test   %eax,%eax
f010165f:	74 19                	je     f010167a <mem_init+0x829>
f0101661:	68 af 35 10 f0       	push   $0xf01035af
f0101666:	68 56 34 10 f0       	push   $0xf0103456
f010166b:	68 e2 02 00 00       	push   $0x2e2
f0101670:	68 30 34 10 f0       	push   $0xf0103430
f0101675:	e8 35 ea ff ff       	call   f01000af <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010167a:	8b 35 68 b9 11 f0    	mov    0xf011b968,%esi
f0101680:	6a 02                	push   $0x2
f0101682:	68 00 10 00 00       	push   $0x1000
f0101687:	53                   	push   %ebx
f0101688:	56                   	push   %esi
f0101689:	e8 af f7 ff ff       	call   f0100e3d <page_insert>
f010168e:	83 c4 10             	add    $0x10,%esp
f0101691:	85 c0                	test   %eax,%eax
f0101693:	74 19                	je     f01016ae <mem_init+0x85d>
f0101695:	68 a4 32 10 f0       	push   $0xf01032a4
f010169a:	68 56 34 10 f0       	push   $0xf0103456
f010169f:	68 e5 02 00 00       	push   $0x2e5
f01016a4:	68 30 34 10 f0       	push   $0xf0103430
f01016a9:	e8 01 ea ff ff       	call   f01000af <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01016ae:	ba 00 10 00 00       	mov    $0x1000,%edx
f01016b3:	89 f0                	mov    %esi,%eax
f01016b5:	e8 32 f2 ff ff       	call   f01008ec <check_va2pa>
f01016ba:	89 da                	mov    %ebx,%edx
f01016bc:	2b 15 6c b9 11 f0    	sub    0xf011b96c,%edx
f01016c2:	c1 fa 03             	sar    $0x3,%edx
f01016c5:	c1 e2 0c             	shl    $0xc,%edx
f01016c8:	39 d0                	cmp    %edx,%eax
f01016ca:	74 19                	je     f01016e5 <mem_init+0x894>
f01016cc:	68 e0 32 10 f0       	push   $0xf01032e0
f01016d1:	68 56 34 10 f0       	push   $0xf0103456
f01016d6:	68 e6 02 00 00       	push   $0x2e6
f01016db:	68 30 34 10 f0       	push   $0xf0103430
f01016e0:	e8 ca e9 ff ff       	call   f01000af <_panic>
	assert(pp2->pp_ref == 1);
f01016e5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01016ea:	74 19                	je     f0101705 <mem_init+0x8b4>
f01016ec:	68 23 36 10 f0       	push   $0xf0103623
f01016f1:	68 56 34 10 f0       	push   $0xf0103456
f01016f6:	68 e7 02 00 00       	push   $0x2e7
f01016fb:	68 30 34 10 f0       	push   $0xf0103430
f0101700:	e8 aa e9 ff ff       	call   f01000af <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101705:	83 ec 0c             	sub    $0xc,%esp
f0101708:	6a 00                	push   $0x0
f010170a:	e8 62 f6 ff ff       	call   f0100d71 <page_alloc>
f010170f:	83 c4 10             	add    $0x10,%esp
f0101712:	85 c0                	test   %eax,%eax
f0101714:	74 19                	je     f010172f <mem_init+0x8de>
f0101716:	68 af 35 10 f0       	push   $0xf01035af
f010171b:	68 56 34 10 f0       	push   $0xf0103456
f0101720:	68 eb 02 00 00       	push   $0x2eb
f0101725:	68 30 34 10 f0       	push   $0xf0103430
f010172a:	e8 80 e9 ff ff       	call   f01000af <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010172f:	8b 35 68 b9 11 f0    	mov    0xf011b968,%esi
f0101735:	8b 3e                	mov    (%esi),%edi
f0101737:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010173d:	89 f8                	mov    %edi,%eax
f010173f:	c1 e8 0c             	shr    $0xc,%eax
f0101742:	3b 05 64 b9 11 f0    	cmp    0xf011b964,%eax
f0101748:	72 15                	jb     f010175f <mem_init+0x90e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010174a:	57                   	push   %edi
f010174b:	68 a4 2f 10 f0       	push   $0xf0102fa4
f0101750:	68 ee 02 00 00       	push   $0x2ee
f0101755:	68 30 34 10 f0       	push   $0xf0103430
f010175a:	e8 50 e9 ff ff       	call   f01000af <_panic>
	return (void *)(pa + KERNBASE);
f010175f:	8d 87 00 00 00 f0    	lea    -0x10000000(%edi),%eax
f0101765:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101768:	83 ec 04             	sub    $0x4,%esp
f010176b:	6a 00                	push   $0x0
f010176d:	68 00 10 00 00       	push   $0x1000
f0101772:	56                   	push   %esi
f0101773:	e8 bb f6 ff ff       	call   f0100e33 <pgdir_walk>
f0101778:	83 c4 10             	add    $0x10,%esp
f010177b:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0101781:	39 f8                	cmp    %edi,%eax
f0101783:	74 19                	je     f010179e <mem_init+0x94d>
f0101785:	68 10 33 10 f0       	push   $0xf0103310
f010178a:	68 56 34 10 f0       	push   $0xf0103456
f010178f:	68 ef 02 00 00       	push   $0x2ef
f0101794:	68 30 34 10 f0       	push   $0xf0103430
f0101799:	e8 11 e9 ff ff       	call   f01000af <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010179e:	6a 06                	push   $0x6
f01017a0:	68 00 10 00 00       	push   $0x1000
f01017a5:	53                   	push   %ebx
f01017a6:	56                   	push   %esi
f01017a7:	e8 91 f6 ff ff       	call   f0100e3d <page_insert>
f01017ac:	83 c4 10             	add    $0x10,%esp
f01017af:	85 c0                	test   %eax,%eax
f01017b1:	74 19                	je     f01017cc <mem_init+0x97b>
f01017b3:	68 50 33 10 f0       	push   $0xf0103350
f01017b8:	68 56 34 10 f0       	push   $0xf0103456
f01017bd:	68 f2 02 00 00       	push   $0x2f2
f01017c2:	68 30 34 10 f0       	push   $0xf0103430
f01017c7:	e8 e3 e8 ff ff       	call   f01000af <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017cc:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017d1:	89 f0                	mov    %esi,%eax
f01017d3:	e8 14 f1 ff ff       	call   f01008ec <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017d8:	89 da                	mov    %ebx,%edx
f01017da:	2b 15 6c b9 11 f0    	sub    0xf011b96c,%edx
f01017e0:	c1 fa 03             	sar    $0x3,%edx
f01017e3:	c1 e2 0c             	shl    $0xc,%edx
f01017e6:	39 d0                	cmp    %edx,%eax
f01017e8:	74 19                	je     f0101803 <mem_init+0x9b2>
f01017ea:	68 e0 32 10 f0       	push   $0xf01032e0
f01017ef:	68 56 34 10 f0       	push   $0xf0103456
f01017f4:	68 f3 02 00 00       	push   $0x2f3
f01017f9:	68 30 34 10 f0       	push   $0xf0103430
f01017fe:	e8 ac e8 ff ff       	call   f01000af <_panic>
	assert(pp2->pp_ref == 1);
f0101803:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101808:	74 19                	je     f0101823 <mem_init+0x9d2>
f010180a:	68 23 36 10 f0       	push   $0xf0103623
f010180f:	68 56 34 10 f0       	push   $0xf0103456
f0101814:	68 f4 02 00 00       	push   $0x2f4
f0101819:	68 30 34 10 f0       	push   $0xf0103430
f010181e:	e8 8c e8 ff ff       	call   f01000af <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101823:	8b 35 68 b9 11 f0    	mov    0xf011b968,%esi
f0101829:	83 ec 04             	sub    $0x4,%esp
f010182c:	6a 00                	push   $0x0
f010182e:	68 00 10 00 00       	push   $0x1000
f0101833:	56                   	push   %esi
f0101834:	e8 fa f5 ff ff       	call   f0100e33 <pgdir_walk>
f0101839:	83 c4 10             	add    $0x10,%esp
f010183c:	8b 38                	mov    (%eax),%edi
f010183e:	f7 c7 04 00 00 00    	test   $0x4,%edi
f0101844:	75 19                	jne    f010185f <mem_init+0xa0e>
f0101846:	68 90 33 10 f0       	push   $0xf0103390
f010184b:	68 56 34 10 f0       	push   $0xf0103456
f0101850:	68 f5 02 00 00       	push   $0x2f5
f0101855:	68 30 34 10 f0       	push   $0xf0103430
f010185a:	e8 50 e8 ff ff       	call   f01000af <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010185f:	f6 06 04             	testb  $0x4,(%esi)
f0101862:	75 19                	jne    f010187d <mem_init+0xa2c>
f0101864:	68 34 36 10 f0       	push   $0xf0103634
f0101869:	68 56 34 10 f0       	push   $0xf0103456
f010186e:	68 f6 02 00 00       	push   $0x2f6
f0101873:	68 30 34 10 f0       	push   $0xf0103430
f0101878:	e8 32 e8 ff ff       	call   f01000af <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010187d:	6a 02                	push   $0x2
f010187f:	68 00 10 00 00       	push   $0x1000
f0101884:	53                   	push   %ebx
f0101885:	56                   	push   %esi
f0101886:	e8 b2 f5 ff ff       	call   f0100e3d <page_insert>
f010188b:	83 c4 10             	add    $0x10,%esp
f010188e:	85 c0                	test   %eax,%eax
f0101890:	74 19                	je     f01018ab <mem_init+0xa5a>
f0101892:	68 a4 32 10 f0       	push   $0xf01032a4
f0101897:	68 56 34 10 f0       	push   $0xf0103456
f010189c:	68 f9 02 00 00       	push   $0x2f9
f01018a1:	68 30 34 10 f0       	push   $0xf0103430
f01018a6:	e8 04 e8 ff ff       	call   f01000af <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01018ab:	f7 c7 02 00 00 00    	test   $0x2,%edi
f01018b1:	75 19                	jne    f01018cc <mem_init+0xa7b>
f01018b3:	68 c4 33 10 f0       	push   $0xf01033c4
f01018b8:	68 56 34 10 f0       	push   $0xf0103456
f01018bd:	68 fa 02 00 00       	push   $0x2fa
f01018c2:	68 30 34 10 f0       	push   $0xf0103430
f01018c7:	e8 e3 e7 ff ff       	call   f01000af <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01018cc:	68 f8 33 10 f0       	push   $0xf01033f8
f01018d1:	68 56 34 10 f0       	push   $0xf0103456
f01018d6:	68 fb 02 00 00       	push   $0x2fb
f01018db:	68 30 34 10 f0       	push   $0xf0103430
f01018e0:	e8 ca e7 ff ff       	call   f01000af <_panic>

f01018e5 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01018e5:	55                   	push   %ebp
f01018e6:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f01018e8:	c9                   	leave  
f01018e9:	c3                   	ret    

f01018ea <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01018ea:	55                   	push   %ebp
f01018eb:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01018ed:	8b 45 0c             	mov    0xc(%ebp),%eax
f01018f0:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01018f3:	c9                   	leave  
f01018f4:	c3                   	ret    
f01018f5:	00 00                	add    %al,(%eax)
	...

f01018f8 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01018f8:	55                   	push   %ebp
f01018f9:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01018fb:	ba 70 00 00 00       	mov    $0x70,%edx
f0101900:	8b 45 08             	mov    0x8(%ebp),%eax
f0101903:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0101904:	b2 71                	mov    $0x71,%dl
f0101906:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0101907:	0f b6 c0             	movzbl %al,%eax
}
f010190a:	c9                   	leave  
f010190b:	c3                   	ret    

f010190c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010190c:	55                   	push   %ebp
f010190d:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010190f:	ba 70 00 00 00       	mov    $0x70,%edx
f0101914:	8b 45 08             	mov    0x8(%ebp),%eax
f0101917:	ee                   	out    %al,(%dx)
f0101918:	b2 71                	mov    $0x71,%dl
f010191a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010191d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010191e:	c9                   	leave  
f010191f:	c3                   	ret    

f0101920 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0101920:	55                   	push   %ebp
f0101921:	89 e5                	mov    %esp,%ebp
f0101923:	83 ec 08             	sub    $0x8,%esp
f0101926:	8b 45 08             	mov    0x8(%ebp),%eax
	static int colors = 0x0700;
	if((ch & 0xff) == '\033')
f0101929:	3c 1b                	cmp    $0x1b,%al
f010192b:	75 0c                	jne    f0101939 <putch+0x19>
	{
		colors = 0xFF00 & ch;
f010192d:	25 00 ff 00 00       	and    $0xff00,%eax
f0101932:	a3 00 b3 11 f0       	mov    %eax,0xf011b300
f0101937:	eb 17                	jmp    f0101950 <putch+0x30>
	}
	else
	{
		if(!(ch & 0xFF00))
f0101939:	f6 c4 ff             	test   $0xff,%ah
f010193c:	75 06                	jne    f0101944 <putch+0x24>
			ch |= colors;
f010193e:	0b 05 00 b3 11 f0    	or     0xf011b300,%eax

		cputchar(ch);
f0101944:	83 ec 0c             	sub    $0xc,%esp
f0101947:	50                   	push   %eax
f0101948:	e8 73 ec ff ff       	call   f01005c0 <cputchar>
f010194d:	83 c4 10             	add    $0x10,%esp
		*cnt++;
	}
}
f0101950:	c9                   	leave  
f0101951:	c3                   	ret    

f0101952 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101952:	55                   	push   %ebp
f0101953:	89 e5                	mov    %esp,%ebp
f0101955:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0101958:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010195f:	ff 75 0c             	pushl  0xc(%ebp)
f0101962:	ff 75 08             	pushl  0x8(%ebp)
f0101965:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101968:	50                   	push   %eax
f0101969:	68 20 19 10 f0       	push   $0xf0101920
f010196e:	e8 a2 04 00 00       	call   f0101e15 <vprintfmt>
	return cnt;
}
f0101973:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101976:	c9                   	leave  
f0101977:	c3                   	ret    

f0101978 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0101978:	55                   	push   %ebp
f0101979:	89 e5                	mov    %esp,%ebp
f010197b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010197e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101981:	50                   	push   %eax
f0101982:	ff 75 08             	pushl  0x8(%ebp)
f0101985:	e8 c8 ff ff ff       	call   f0101952 <vcprintf>
	va_end(ap);

	return cnt;
}
f010198a:	c9                   	leave  
f010198b:	c3                   	ret    

f010198c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010198c:	55                   	push   %ebp
f010198d:	89 e5                	mov    %esp,%ebp
f010198f:	57                   	push   %edi
f0101990:	56                   	push   %esi
f0101991:	53                   	push   %ebx
f0101992:	83 ec 14             	sub    $0x14,%esp
f0101995:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101998:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010199b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010199e:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01019a1:	8b 1a                	mov    (%edx),%ebx
f01019a3:	8b 01                	mov    (%ecx),%eax
f01019a5:	89 45 ec             	mov    %eax,-0x14(%ebp)

	while (l <= r) {
f01019a8:	39 c3                	cmp    %eax,%ebx
f01019aa:	0f 8f 97 00 00 00    	jg     f0101a47 <stab_binsearch+0xbb>
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
f01019b0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f01019b7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01019ba:	01 d8                	add    %ebx,%eax
f01019bc:	89 c7                	mov    %eax,%edi
f01019be:	c1 ef 1f             	shr    $0x1f,%edi
f01019c1:	01 c7                	add    %eax,%edi
f01019c3:	d1 ff                	sar    %edi

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01019c5:	39 df                	cmp    %ebx,%edi
f01019c7:	7c 31                	jl     f01019fa <stab_binsearch+0x6e>
f01019c9:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01019cc:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01019cf:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f01019d4:	39 f0                	cmp    %esi,%eax
f01019d6:	0f 84 b3 00 00 00    	je     f0101a8f <stab_binsearch+0x103>
f01019dc:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01019e0:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f01019e4:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01019e6:	48                   	dec    %eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01019e7:	39 d8                	cmp    %ebx,%eax
f01019e9:	7c 0f                	jl     f01019fa <stab_binsearch+0x6e>
f01019eb:	0f b6 0a             	movzbl (%edx),%ecx
f01019ee:	83 ea 0c             	sub    $0xc,%edx
f01019f1:	39 f1                	cmp    %esi,%ecx
f01019f3:	75 f1                	jne    f01019e6 <stab_binsearch+0x5a>
f01019f5:	e9 97 00 00 00       	jmp    f0101a91 <stab_binsearch+0x105>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01019fa:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01019fd:	eb 39                	jmp    f0101a38 <stab_binsearch+0xac>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01019ff:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0101a02:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
f0101a04:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101a07:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0101a0e:	eb 28                	jmp    f0101a38 <stab_binsearch+0xac>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0101a10:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0101a13:	76 12                	jbe    f0101a27 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0101a15:	48                   	dec    %eax
f0101a16:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101a19:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101a1c:	89 02                	mov    %eax,(%edx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101a1e:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0101a25:	eb 11                	jmp    f0101a38 <stab_binsearch+0xac>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0101a27:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0101a2a:	89 01                	mov    %eax,(%ecx)
			l = m;
			addr++;
f0101a2c:	ff 45 0c             	incl   0xc(%ebp)
f0101a2f:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101a31:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0101a38:	39 5d ec             	cmp    %ebx,-0x14(%ebp)
f0101a3b:	0f 8d 76 ff ff ff    	jge    f01019b7 <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0101a41:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101a45:	75 0d                	jne    f0101a54 <stab_binsearch+0xc8>
		*region_right = *region_left - 1;
f0101a47:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0101a4a:	8b 03                	mov    (%ebx),%eax
f0101a4c:	48                   	dec    %eax
f0101a4d:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101a50:	89 02                	mov    %eax,(%edx)
f0101a52:	eb 55                	jmp    f0101aa9 <stab_binsearch+0x11d>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101a54:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101a57:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101a59:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0101a5c:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101a5e:	39 c1                	cmp    %eax,%ecx
f0101a60:	7d 26                	jge    f0101a88 <stab_binsearch+0xfc>
		     l > *region_left && stabs[l].n_type != type;
f0101a62:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101a65:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0101a68:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0101a6d:	39 f2                	cmp    %esi,%edx
f0101a6f:	74 17                	je     f0101a88 <stab_binsearch+0xfc>
f0101a71:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0101a75:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0101a79:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101a7a:	39 c1                	cmp    %eax,%ecx
f0101a7c:	7d 0a                	jge    f0101a88 <stab_binsearch+0xfc>
		     l > *region_left && stabs[l].n_type != type;
f0101a7e:	0f b6 1a             	movzbl (%edx),%ebx
f0101a81:	83 ea 0c             	sub    $0xc,%edx
f0101a84:	39 f3                	cmp    %esi,%ebx
f0101a86:	75 f1                	jne    f0101a79 <stab_binsearch+0xed>
		     l--)
			/* do nothing */;
		*region_left = l;
f0101a88:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101a8b:	89 02                	mov    %eax,(%edx)
f0101a8d:	eb 1a                	jmp    f0101aa9 <stab_binsearch+0x11d>
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0101a8f:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101a91:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101a94:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0101a97:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0101a9b:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0101a9e:	0f 82 5b ff ff ff    	jb     f01019ff <stab_binsearch+0x73>
f0101aa4:	e9 67 ff ff ff       	jmp    f0101a10 <stab_binsearch+0x84>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0101aa9:	83 c4 14             	add    $0x14,%esp
f0101aac:	5b                   	pop    %ebx
f0101aad:	5e                   	pop    %esi
f0101aae:	5f                   	pop    %edi
f0101aaf:	c9                   	leave  
f0101ab0:	c3                   	ret    

f0101ab1 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0101ab1:	55                   	push   %ebp
f0101ab2:	89 e5                	mov    %esp,%ebp
f0101ab4:	57                   	push   %edi
f0101ab5:	56                   	push   %esi
f0101ab6:	53                   	push   %ebx
f0101ab7:	83 ec 3c             	sub    $0x3c,%esp
f0101aba:	8b 75 08             	mov    0x8(%ebp),%esi
f0101abd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101ac0:	c7 03 4a 36 10 f0    	movl   $0xf010364a,(%ebx)
	info->eip_line = 0;
f0101ac6:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0101acd:	c7 43 08 4a 36 10 f0 	movl   $0xf010364a,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0101ad4:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0101adb:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0101ade:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101ae5:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0101aeb:	76 12                	jbe    f0101aff <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101aed:	b8 b8 0d 11 f0       	mov    $0xf0110db8,%eax
f0101af2:	3d 6d 95 10 f0       	cmp    $0xf010956d,%eax
f0101af7:	0f 86 97 01 00 00    	jbe    f0101c94 <debuginfo_eip+0x1e3>
f0101afd:	eb 14                	jmp    f0101b13 <debuginfo_eip+0x62>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0101aff:	83 ec 04             	sub    $0x4,%esp
f0101b02:	68 54 36 10 f0       	push   $0xf0103654
f0101b07:	6a 7f                	push   $0x7f
f0101b09:	68 61 36 10 f0       	push   $0xf0103661
f0101b0e:	e8 9c e5 ff ff       	call   f01000af <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0101b13:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101b18:	80 3d b7 0d 11 f0 00 	cmpb   $0x0,0xf0110db7
f0101b1f:	0f 85 7b 01 00 00    	jne    f0101ca0 <debuginfo_eip+0x1ef>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0101b25:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0101b2c:	b8 6c 95 10 f0       	mov    $0xf010956c,%eax
f0101b31:	2d 40 37 10 f0       	sub    $0xf0103740,%eax
f0101b36:	c1 f8 02             	sar    $0x2,%eax
f0101b39:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0101b3f:	48                   	dec    %eax
f0101b40:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0101b43:	83 ec 08             	sub    $0x8,%esp
f0101b46:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0101b49:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0101b4c:	56                   	push   %esi
f0101b4d:	6a 64                	push   $0x64
f0101b4f:	b8 40 37 10 f0       	mov    $0xf0103740,%eax
f0101b54:	e8 33 fe ff ff       	call   f010198c <stab_binsearch>
	if (lfile == 0)
f0101b59:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101b5c:	83 c4 10             	add    $0x10,%esp
		return -1;
f0101b5f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0101b64:	85 d2                	test   %edx,%edx
f0101b66:	0f 84 34 01 00 00    	je     f0101ca0 <debuginfo_eip+0x1ef>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0101b6c:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0101b6f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101b72:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101b75:	83 ec 08             	sub    $0x8,%esp
f0101b78:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101b7b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101b7e:	56                   	push   %esi
f0101b7f:	6a 24                	push   $0x24
f0101b81:	b8 40 37 10 f0       	mov    $0xf0103740,%eax
f0101b86:	e8 01 fe ff ff       	call   f010198c <stab_binsearch>

	if (lfun <= rfun) {
f0101b8b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101b8e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101b91:	83 c4 10             	add    $0x10,%esp
f0101b94:	39 d0                	cmp    %edx,%eax
f0101b96:	7f 37                	jg     f0101bcf <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0101b98:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0101b9b:	8b 89 40 37 10 f0    	mov    -0xfefc8c0(%ecx),%ecx
f0101ba1:	bf b8 0d 11 f0       	mov    $0xf0110db8,%edi
f0101ba6:	81 ef 6d 95 10 f0    	sub    $0xf010956d,%edi
f0101bac:	39 f9                	cmp    %edi,%ecx
f0101bae:	73 09                	jae    f0101bb9 <debuginfo_eip+0x108>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101bb0:	81 c1 6d 95 10 f0    	add    $0xf010956d,%ecx
f0101bb6:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101bb9:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0101bbc:	8b 89 48 37 10 f0    	mov    -0xfefc8b8(%ecx),%ecx
f0101bc2:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0101bc5:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0101bc7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0101bca:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101bcd:	eb 0f                	jmp    f0101bde <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101bcf:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0101bd2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101bd5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0101bd8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101bdb:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101bde:	83 ec 08             	sub    $0x8,%esp
f0101be1:	6a 3a                	push   $0x3a
f0101be3:	ff 73 08             	pushl  0x8(%ebx)
f0101be6:	e8 a0 09 00 00       	call   f010258b <strfind>
f0101beb:	2b 43 08             	sub    0x8(%ebx),%eax
f0101bee:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0101bf1:	83 c4 08             	add    $0x8,%esp
f0101bf4:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0101bf7:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0101bfa:	56                   	push   %esi
f0101bfb:	6a 44                	push   $0x44
f0101bfd:	b8 40 37 10 f0       	mov    $0xf0103740,%eax
f0101c02:	e8 85 fd ff ff       	call   f010198c <stab_binsearch>

	if(lline <= rline)
f0101c07:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101c0a:	83 c4 10             	add    $0x10,%esp
	{
		info->eip_line = (int)stabs[lline].n_value;
	}
	else
	{
		return -1;
f0101c0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);

	if(lline <= rline)
f0101c12:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0101c15:	0f 8f 85 00 00 00    	jg     f0101ca0 <debuginfo_eip+0x1ef>
	{
		info->eip_line = (int)stabs[lline].n_value;
f0101c1b:	6b d2 0c             	imul   $0xc,%edx,%edx
f0101c1e:	8b 82 48 37 10 f0    	mov    -0xfefc8b8(%edx),%eax
f0101c24:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101c27:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101c2a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0101c2d:	81 c2 48 37 10 f0    	add    $0xf0103748,%edx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101c33:	eb 04                	jmp    f0101c39 <debuginfo_eip+0x188>
f0101c35:	48                   	dec    %eax
f0101c36:	83 ea 0c             	sub    $0xc,%edx
f0101c39:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0101c3c:	39 c6                	cmp    %eax,%esi
f0101c3e:	7f 1b                	jg     f0101c5b <debuginfo_eip+0x1aa>
	       && stabs[lline].n_type != N_SOL
f0101c40:	8a 4a fc             	mov    -0x4(%edx),%cl
f0101c43:	80 f9 84             	cmp    $0x84,%cl
f0101c46:	74 60                	je     f0101ca8 <debuginfo_eip+0x1f7>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101c48:	80 f9 64             	cmp    $0x64,%cl
f0101c4b:	75 e8                	jne    f0101c35 <debuginfo_eip+0x184>
f0101c4d:	83 3a 00             	cmpl   $0x0,(%edx)
f0101c50:	74 e3                	je     f0101c35 <debuginfo_eip+0x184>
f0101c52:	eb 54                	jmp    f0101ca8 <debuginfo_eip+0x1f7>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101c54:	05 6d 95 10 f0       	add    $0xf010956d,%eax
f0101c59:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101c5b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101c5e:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101c61:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101c66:	39 ca                	cmp    %ecx,%edx
f0101c68:	7d 36                	jge    f0101ca0 <debuginfo_eip+0x1ef>
		for (lline = lfun + 1;
f0101c6a:	8d 42 01             	lea    0x1(%edx),%eax
f0101c6d:	89 c2                	mov    %eax,%edx
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0101c6f:	6b c0 0c             	imul   $0xc,%eax,%eax
f0101c72:	05 44 37 10 f0       	add    $0xf0103744,%eax
f0101c77:	89 ce                	mov    %ecx,%esi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0101c79:	eb 03                	jmp    f0101c7e <debuginfo_eip+0x1cd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0101c7b:	ff 43 14             	incl   0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0101c7e:	39 f2                	cmp    %esi,%edx
f0101c80:	7d 19                	jge    f0101c9b <debuginfo_eip+0x1ea>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101c82:	8a 08                	mov    (%eax),%cl
f0101c84:	42                   	inc    %edx
f0101c85:	83 c0 0c             	add    $0xc,%eax
f0101c88:	80 f9 a0             	cmp    $0xa0,%cl
f0101c8b:	74 ee                	je     f0101c7b <debuginfo_eip+0x1ca>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101c8d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101c92:	eb 0c                	jmp    f0101ca0 <debuginfo_eip+0x1ef>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0101c94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101c99:	eb 05                	jmp    f0101ca0 <debuginfo_eip+0x1ef>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101c9b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101ca0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101ca3:	5b                   	pop    %ebx
f0101ca4:	5e                   	pop    %esi
f0101ca5:	5f                   	pop    %edi
f0101ca6:	c9                   	leave  
f0101ca7:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101ca8:	6b 45 c4 0c          	imul   $0xc,-0x3c(%ebp),%eax
f0101cac:	8b 80 40 37 10 f0    	mov    -0xfefc8c0(%eax),%eax
f0101cb2:	ba b8 0d 11 f0       	mov    $0xf0110db8,%edx
f0101cb7:	81 ea 6d 95 10 f0    	sub    $0xf010956d,%edx
f0101cbd:	39 d0                	cmp    %edx,%eax
f0101cbf:	72 93                	jb     f0101c54 <debuginfo_eip+0x1a3>
f0101cc1:	eb 98                	jmp    f0101c5b <debuginfo_eip+0x1aa>
	...

f0101cc4 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101cc4:	55                   	push   %ebp
f0101cc5:	89 e5                	mov    %esp,%ebp
f0101cc7:	57                   	push   %edi
f0101cc8:	56                   	push   %esi
f0101cc9:	53                   	push   %ebx
f0101cca:	83 ec 2c             	sub    $0x2c,%esp
f0101ccd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101cd0:	89 d6                	mov    %edx,%esi
f0101cd2:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cd5:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101cd8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101cdb:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101cde:	8b 45 10             	mov    0x10(%ebp),%eax
f0101ce1:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0101ce4:	8b 7d 18             	mov    0x18(%ebp),%edi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101ce7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101cea:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0101cf1:	39 55 d4             	cmp    %edx,-0x2c(%ebp)
f0101cf4:	72 0c                	jb     f0101d02 <printnum+0x3e>
f0101cf6:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0101cf9:	76 07                	jbe    f0101d02 <printnum+0x3e>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101cfb:	4b                   	dec    %ebx
f0101cfc:	85 db                	test   %ebx,%ebx
f0101cfe:	7f 31                	jg     f0101d31 <printnum+0x6d>
f0101d00:	eb 3f                	jmp    f0101d41 <printnum+0x7d>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101d02:	83 ec 0c             	sub    $0xc,%esp
f0101d05:	57                   	push   %edi
f0101d06:	4b                   	dec    %ebx
f0101d07:	53                   	push   %ebx
f0101d08:	50                   	push   %eax
f0101d09:	83 ec 08             	sub    $0x8,%esp
f0101d0c:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d0f:	ff 75 d0             	pushl  -0x30(%ebp)
f0101d12:	ff 75 dc             	pushl  -0x24(%ebp)
f0101d15:	ff 75 d8             	pushl  -0x28(%ebp)
f0101d18:	e8 97 0a 00 00       	call   f01027b4 <__udivdi3>
f0101d1d:	83 c4 18             	add    $0x18,%esp
f0101d20:	52                   	push   %edx
f0101d21:	50                   	push   %eax
f0101d22:	89 f2                	mov    %esi,%edx
f0101d24:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101d27:	e8 98 ff ff ff       	call   f0101cc4 <printnum>
f0101d2c:	83 c4 20             	add    $0x20,%esp
f0101d2f:	eb 10                	jmp    f0101d41 <printnum+0x7d>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101d31:	83 ec 08             	sub    $0x8,%esp
f0101d34:	56                   	push   %esi
f0101d35:	57                   	push   %edi
f0101d36:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101d39:	4b                   	dec    %ebx
f0101d3a:	83 c4 10             	add    $0x10,%esp
f0101d3d:	85 db                	test   %ebx,%ebx
f0101d3f:	7f f0                	jg     f0101d31 <printnum+0x6d>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101d41:	83 ec 08             	sub    $0x8,%esp
f0101d44:	56                   	push   %esi
f0101d45:	83 ec 04             	sub    $0x4,%esp
f0101d48:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d4b:	ff 75 d0             	pushl  -0x30(%ebp)
f0101d4e:	ff 75 dc             	pushl  -0x24(%ebp)
f0101d51:	ff 75 d8             	pushl  -0x28(%ebp)
f0101d54:	e8 77 0b 00 00       	call   f01028d0 <__umoddi3>
f0101d59:	83 c4 14             	add    $0x14,%esp
f0101d5c:	0f be 80 6f 36 10 f0 	movsbl -0xfefc991(%eax),%eax
f0101d63:	50                   	push   %eax
f0101d64:	ff 55 e4             	call   *-0x1c(%ebp)
f0101d67:	83 c4 10             	add    $0x10,%esp
}
f0101d6a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101d6d:	5b                   	pop    %ebx
f0101d6e:	5e                   	pop    %esi
f0101d6f:	5f                   	pop    %edi
f0101d70:	c9                   	leave  
f0101d71:	c3                   	ret    

f0101d72 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0101d72:	55                   	push   %ebp
f0101d73:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101d75:	83 fa 01             	cmp    $0x1,%edx
f0101d78:	7e 0e                	jle    f0101d88 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0101d7a:	8b 10                	mov    (%eax),%edx
f0101d7c:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101d7f:	89 08                	mov    %ecx,(%eax)
f0101d81:	8b 02                	mov    (%edx),%eax
f0101d83:	8b 52 04             	mov    0x4(%edx),%edx
f0101d86:	eb 22                	jmp    f0101daa <getuint+0x38>
	else if (lflag)
f0101d88:	85 d2                	test   %edx,%edx
f0101d8a:	74 10                	je     f0101d9c <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0101d8c:	8b 10                	mov    (%eax),%edx
f0101d8e:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101d91:	89 08                	mov    %ecx,(%eax)
f0101d93:	8b 02                	mov    (%edx),%eax
f0101d95:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d9a:	eb 0e                	jmp    f0101daa <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0101d9c:	8b 10                	mov    (%eax),%edx
f0101d9e:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101da1:	89 08                	mov    %ecx,(%eax)
f0101da3:	8b 02                	mov    (%edx),%eax
f0101da5:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0101daa:	c9                   	leave  
f0101dab:	c3                   	ret    

f0101dac <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0101dac:	55                   	push   %ebp
f0101dad:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101daf:	83 fa 01             	cmp    $0x1,%edx
f0101db2:	7e 0e                	jle    f0101dc2 <getint+0x16>
		return va_arg(*ap, long long);
f0101db4:	8b 10                	mov    (%eax),%edx
f0101db6:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101db9:	89 08                	mov    %ecx,(%eax)
f0101dbb:	8b 02                	mov    (%edx),%eax
f0101dbd:	8b 52 04             	mov    0x4(%edx),%edx
f0101dc0:	eb 1a                	jmp    f0101ddc <getint+0x30>
	else if (lflag)
f0101dc2:	85 d2                	test   %edx,%edx
f0101dc4:	74 0c                	je     f0101dd2 <getint+0x26>
		return va_arg(*ap, long);
f0101dc6:	8b 10                	mov    (%eax),%edx
f0101dc8:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101dcb:	89 08                	mov    %ecx,(%eax)
f0101dcd:	8b 02                	mov    (%edx),%eax
f0101dcf:	99                   	cltd   
f0101dd0:	eb 0a                	jmp    f0101ddc <getint+0x30>
	else
		return va_arg(*ap, int);
f0101dd2:	8b 10                	mov    (%eax),%edx
f0101dd4:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101dd7:	89 08                	mov    %ecx,(%eax)
f0101dd9:	8b 02                	mov    (%edx),%eax
f0101ddb:	99                   	cltd   
}
f0101ddc:	c9                   	leave  
f0101ddd:	c3                   	ret    

f0101dde <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101dde:	55                   	push   %ebp
f0101ddf:	89 e5                	mov    %esp,%ebp
f0101de1:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101de4:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f0101de7:	8b 10                	mov    (%eax),%edx
f0101de9:	3b 50 04             	cmp    0x4(%eax),%edx
f0101dec:	73 08                	jae    f0101df6 <sprintputch+0x18>
		*b->buf++ = ch;
f0101dee:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101df1:	88 0a                	mov    %cl,(%edx)
f0101df3:	42                   	inc    %edx
f0101df4:	89 10                	mov    %edx,(%eax)
}
f0101df6:	c9                   	leave  
f0101df7:	c3                   	ret    

f0101df8 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101df8:	55                   	push   %ebp
f0101df9:	89 e5                	mov    %esp,%ebp
f0101dfb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0101dfe:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101e01:	50                   	push   %eax
f0101e02:	ff 75 10             	pushl  0x10(%ebp)
f0101e05:	ff 75 0c             	pushl  0xc(%ebp)
f0101e08:	ff 75 08             	pushl  0x8(%ebp)
f0101e0b:	e8 05 00 00 00       	call   f0101e15 <vprintfmt>
	va_end(ap);
f0101e10:	83 c4 10             	add    $0x10,%esp
}
f0101e13:	c9                   	leave  
f0101e14:	c3                   	ret    

f0101e15 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101e15:	55                   	push   %ebp
f0101e16:	89 e5                	mov    %esp,%ebp
f0101e18:	57                   	push   %edi
f0101e19:	56                   	push   %esi
f0101e1a:	53                   	push   %ebx
f0101e1b:	83 ec 1c             	sub    $0x1c,%esp
f0101e1e:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101e21:	e9 d7 00 00 00       	jmp    f0101efd <vprintfmt+0xe8>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0101e26:	85 c0                	test   %eax,%eax
f0101e28:	0f 84 6d 04 00 00    	je     f010229b <vprintfmt+0x486>
				return;

			if (ch == '\033')
f0101e2e:	83 f8 1b             	cmp    $0x1b,%eax
f0101e31:	0f 85 b9 00 00 00    	jne    f0101ef0 <vprintfmt+0xdb>
f0101e37:	b0 01                	mov    $0x1,%al
f0101e39:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101e3e:	be 07 00 00 00       	mov    $0x7,%esi
f0101e43:	bb 00 00 00 00       	mov    $0x0,%ebx
				int color_back = 0;
				int color_fore = 7;
			
				while(state != 6)
				{
					switch(state)
f0101e48:	83 f8 05             	cmp    $0x5,%eax
f0101e4b:	77 fb                	ja     f0101e48 <vprintfmt+0x33>
f0101e4d:	ff 24 85 fc 36 10 f0 	jmp    *-0xfefc904(,%eax,4)
					{
						case 1:
							EAT(fmt, '[');
f0101e54:	80 3f 5b             	cmpb   $0x5b,(%edi)
f0101e57:	75 70                	jne    f0101ec9 <vprintfmt+0xb4>
f0101e59:	47                   	inc    %edi
							state = 2;
f0101e5a:	b8 02 00 00 00       	mov    $0x2,%eax
							break;
f0101e5f:	eb e7                	jmp    f0101e48 <vprintfmt+0x33>

						case 2:
							switch(POP(fmt))
f0101e61:	8a 07                	mov    (%edi),%al
f0101e63:	47                   	inc    %edi
f0101e64:	3c 33                	cmp    $0x33,%al
f0101e66:	0f 84 16 04 00 00    	je     f0102282 <vprintfmt+0x46d>
f0101e6c:	3c 34                	cmp    $0x34,%al
f0101e6e:	75 59                	jne    f0101ec9 <vprintfmt+0xb4>
f0101e70:	eb 62                	jmp    f0101ed4 <vprintfmt+0xbf>
								default: goto ERROR;
							}
							break;

						case 3:
							ch = POP(fmt);
f0101e72:	0f b6 07             	movzbl (%edi),%eax
f0101e75:	47                   	inc    %edi
							if('0' <= ch && ch <= '9')
f0101e76:	8d 50 d0             	lea    -0x30(%eax),%edx
f0101e79:	83 fa 09             	cmp    $0x9,%edx
f0101e7c:	77 4b                	ja     f0101ec9 <vprintfmt+0xb4>
							{
								switch(subtype)
f0101e7e:	83 f9 01             	cmp    $0x1,%ecx
f0101e81:	74 07                	je     f0101e8a <vprintfmt+0x75>
f0101e83:	83 f9 02             	cmp    $0x2,%ecx
f0101e86:	75 41                	jne    f0101ec9 <vprintfmt+0xb4>
f0101e88:	eb 0a                	jmp    f0101e94 <vprintfmt+0x7f>
								{
									case 1: color_fore = ch - '0'; break;
f0101e8a:	8d 70 d0             	lea    -0x30(%eax),%esi
									case 2: color_back = ch - '0'; break;
									default: goto ERROR;
								}
								state = 4;
f0101e8d:	b8 04 00 00 00       	mov    $0x4,%eax
							ch = POP(fmt);
							if('0' <= ch && ch <= '9')
							{
								switch(subtype)
								{
									case 1: color_fore = ch - '0'; break;
f0101e92:	eb b4                	jmp    f0101e48 <vprintfmt+0x33>
									case 2: color_back = ch - '0'; break;
f0101e94:	8d 58 d0             	lea    -0x30(%eax),%ebx
									default: goto ERROR;
								}
								state = 4;
f0101e97:	b8 04 00 00 00       	mov    $0x4,%eax
							if('0' <= ch && ch <= '9')
							{
								switch(subtype)
								{
									case 1: color_fore = ch - '0'; break;
									case 2: color_back = ch - '0'; break;
f0101e9c:	eb aa                	jmp    f0101e48 <vprintfmt+0x33>
							}
							else goto ERROR;
							break;
							
						case 4:
							switch(POP(fmt))
f0101e9e:	8a 07                	mov    (%edi),%al
f0101ea0:	47                   	inc    %edi
f0101ea1:	3c 3b                	cmp    $0x3b,%al
f0101ea3:	74 3b                	je     f0101ee0 <vprintfmt+0xcb>
f0101ea5:	3c 6d                	cmp    $0x6d,%al
f0101ea7:	75 20                	jne    f0101ec9 <vprintfmt+0xb4>
f0101ea9:	e9 e3 03 00 00       	jmp    f0102291 <vprintfmt+0x47c>
								default: goto ERROR;
							}
							break;
						case 5:
							//send color to tty
							putch((color_fore << 8) | (color_back << 10) | '\033', NULL);
f0101eae:	83 ec 08             	sub    $0x8,%esp
f0101eb1:	6a 00                	push   $0x0
f0101eb3:	c1 e6 08             	shl    $0x8,%esi
f0101eb6:	c1 e3 0a             	shl    $0xa,%ebx
f0101eb9:	09 f3                	or     %esi,%ebx
f0101ebb:	83 cb 1b             	or     $0x1b,%ebx
f0101ebe:	53                   	push   %ebx
f0101ebf:	ff 55 08             	call   *0x8(%ebp)
							state = 6;
							break;
f0101ec2:	83 c4 10             	add    $0x10,%esp
f0101ec5:	eb 36                	jmp    f0101efd <vprintfmt+0xe8>

						ERROR:
							while(fmt[-1] != '\033') fmt--;
f0101ec7:	89 c7                	mov    %eax,%edi
f0101ec9:	8d 47 ff             	lea    -0x1(%edi),%eax
f0101ecc:	80 7f ff 1b          	cmpb   $0x1b,-0x1(%edi)
f0101ed0:	75 f5                	jne    f0101ec7 <vprintfmt+0xb2>
f0101ed2:	eb 29                	jmp    f0101efd <vprintfmt+0xe8>

						case 2:
							switch(POP(fmt))
							{
								case '3': state = 3; subtype = 1; break;
								case '4': state = 3; subtype = 2; break;
f0101ed4:	b9 02 00 00 00       	mov    $0x2,%ecx
f0101ed9:	b8 03 00 00 00       	mov    $0x3,%eax
f0101ede:	eb 05                	jmp    f0101ee5 <vprintfmt+0xd0>
							
						case 4:
							switch(POP(fmt))
							{
								case 'm': state = 5; break;
								case ';': state = 2; break;
f0101ee0:	b8 02 00 00 00       	mov    $0x2,%eax
				int state = 1;
				int subtype = 0;
				int color_back = 0;
				int color_fore = 7;
			
				while(state != 6)
f0101ee5:	83 f8 06             	cmp    $0x6,%eax
f0101ee8:	0f 85 5a ff ff ff    	jne    f0101e48 <vprintfmt+0x33>
f0101eee:	eb 0d                	jmp    f0101efd <vprintfmt+0xe8>


			}
			else
			{
				putch(ch, putdat);
f0101ef0:	83 ec 08             	sub    $0x8,%esp
f0101ef3:	ff 75 0c             	pushl  0xc(%ebp)
f0101ef6:	50                   	push   %eax
f0101ef7:	ff 55 08             	call   *0x8(%ebp)
f0101efa:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101efd:	0f b6 07             	movzbl (%edi),%eax
f0101f00:	47                   	inc    %edi
f0101f01:	83 f8 25             	cmp    $0x25,%eax
f0101f04:	0f 85 1c ff ff ff    	jne    f0101e26 <vprintfmt+0x11>
f0101f0a:	89 fb                	mov    %edi,%ebx
f0101f0c:	c6 45 df 20          	movb   $0x20,-0x21(%ebp)
f0101f10:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0101f17:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0101f1c:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0101f23:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f28:	eb 16                	jmp    f0101f40 <vprintfmt+0x12b>
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {

		// flag to pad on the right
		case '-':
			padc = '-';
f0101f2a:	c6 45 df 2d          	movb   $0x2d,-0x21(%ebp)
f0101f2e:	eb 0e                	jmp    f0101f3e <vprintfmt+0x129>
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101f30:	c6 45 df 30          	movb   $0x30,-0x21(%ebp)
f0101f34:	eb 08                	jmp    f0101f3e <vprintfmt+0x129>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0101f36:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101f39:	be ff ff ff ff       	mov    $0xffffffff,%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101f3e:	89 fb                	mov    %edi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101f40:	8a 03                	mov    (%ebx),%al
f0101f42:	0f b6 c8             	movzbl %al,%ecx
f0101f45:	8d 7b 01             	lea    0x1(%ebx),%edi
f0101f48:	3c 64                	cmp    $0x64,%al
f0101f4a:	0f 84 20 02 00 00    	je     f0102170 <vprintfmt+0x35b>
f0101f50:	3c 64                	cmp    $0x64,%al
f0101f52:	77 48                	ja     f0101f9c <vprintfmt+0x187>
f0101f54:	3c 30                	cmp    $0x30,%al
f0101f56:	74 d8                	je     f0101f30 <vprintfmt+0x11b>
f0101f58:	3c 30                	cmp    $0x30,%al
f0101f5a:	77 2f                	ja     f0101f8b <vprintfmt+0x176>
f0101f5c:	3c 2a                	cmp    $0x2a,%al
f0101f5e:	0f 84 98 00 00 00    	je     f0101ffc <vprintfmt+0x1e7>
f0101f64:	3c 2a                	cmp    $0x2a,%al
f0101f66:	77 15                	ja     f0101f7d <vprintfmt+0x168>
f0101f68:	3c 23                	cmp    $0x23,%al
f0101f6a:	0f 84 a9 00 00 00    	je     f0102019 <vprintfmt+0x204>
f0101f70:	3c 25                	cmp    $0x25,%al
f0101f72:	0f 85 e8 02 00 00    	jne    f0102260 <vprintfmt+0x44b>
f0101f78:	e9 d1 02 00 00       	jmp    f010224e <vprintfmt+0x439>
f0101f7d:	3c 2d                	cmp    $0x2d,%al
f0101f7f:	74 a9                	je     f0101f2a <vprintfmt+0x115>
f0101f81:	3c 2e                	cmp    $0x2e,%al
f0101f83:	0f 85 d7 02 00 00    	jne    f0102260 <vprintfmt+0x44b>
f0101f89:	eb 7e                	jmp    f0102009 <vprintfmt+0x1f4>
f0101f8b:	3c 39                	cmp    $0x39,%al
f0101f8d:	76 53                	jbe    f0101fe2 <vprintfmt+0x1cd>
f0101f8f:	3c 63                	cmp    $0x63,%al
f0101f91:	0f 85 c9 02 00 00    	jne    f0102260 <vprintfmt+0x44b>
f0101f97:	e9 9e 00 00 00       	jmp    f010203a <vprintfmt+0x225>
f0101f9c:	3c 70                	cmp    $0x70,%al
f0101f9e:	0f 84 48 02 00 00    	je     f01021ec <vprintfmt+0x3d7>
f0101fa4:	3c 70                	cmp    $0x70,%al
f0101fa6:	77 1d                	ja     f0101fc5 <vprintfmt+0x1b0>
f0101fa8:	3c 6c                	cmp    $0x6c,%al
f0101faa:	0f 84 84 00 00 00    	je     f0102034 <vprintfmt+0x21f>
f0101fb0:	3c 6f                	cmp    $0x6f,%al
f0101fb2:	0f 84 03 02 00 00    	je     f01021bb <vprintfmt+0x3a6>
f0101fb8:	3c 65                	cmp    $0x65,%al
f0101fba:	0f 85 a0 02 00 00    	jne    f0102260 <vprintfmt+0x44b>
f0101fc0:	e9 91 00 00 00       	jmp    f0102056 <vprintfmt+0x241>
f0101fc5:	3c 75                	cmp    $0x75,%al
f0101fc7:	0f 84 db 01 00 00    	je     f01021a8 <vprintfmt+0x393>
f0101fcd:	3c 78                	cmp    $0x78,%al
f0101fcf:	0f 84 47 02 00 00    	je     f010221c <vprintfmt+0x407>
f0101fd5:	3c 73                	cmp    $0x73,%al
f0101fd7:	0f 85 83 02 00 00    	jne    f0102260 <vprintfmt+0x44b>
f0101fdd:	e9 c6 00 00 00       	jmp    f01020a8 <vprintfmt+0x293>
f0101fe2:	be 00 00 00 00       	mov    $0x0,%esi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101fe7:	6b f6 0a             	imul   $0xa,%esi,%esi
f0101fea:	8d 74 31 d0          	lea    -0x30(%ecx,%esi,1),%esi
				ch = *fmt;
f0101fee:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0101ff1:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0101ff4:	83 f8 09             	cmp    $0x9,%eax
f0101ff7:	77 2c                	ja     f0102025 <vprintfmt+0x210>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101ff9:	47                   	inc    %edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0101ffa:	eb eb                	jmp    f0101fe7 <vprintfmt+0x1d2>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101ffc:	8b 45 14             	mov    0x14(%ebp),%eax
f0101fff:	8d 48 04             	lea    0x4(%eax),%ecx
f0102002:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102005:	8b 30                	mov    (%eax),%esi
			goto process_precision;
f0102007:	eb 1c                	jmp    f0102025 <vprintfmt+0x210>

		case '.':
			if (width < 0)
				width = 0;
f0102009:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010200c:	f7 d0                	not    %eax
f010200e:	c1 f8 1f             	sar    $0x1f,%eax
f0102011:	21 45 e4             	and    %eax,-0x1c(%ebp)
f0102014:	e9 25 ff ff ff       	jmp    f0101f3e <vprintfmt+0x129>
			goto reswitch;

		case '#':
			altflag = 1;
f0102019:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102020:	e9 19 ff ff ff       	jmp    f0101f3e <vprintfmt+0x129>

		process_precision:
			if (width < 0)
f0102025:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0102029:	0f 89 0f ff ff ff    	jns    f0101f3e <vprintfmt+0x129>
f010202f:	e9 02 ff ff ff       	jmp    f0101f36 <vprintfmt+0x121>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102034:	42                   	inc    %edx
			goto reswitch;
f0102035:	e9 04 ff ff ff       	jmp    f0101f3e <vprintfmt+0x129>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010203a:	8b 45 14             	mov    0x14(%ebp),%eax
f010203d:	8d 50 04             	lea    0x4(%eax),%edx
f0102040:	89 55 14             	mov    %edx,0x14(%ebp)
f0102043:	83 ec 08             	sub    $0x8,%esp
f0102046:	ff 75 0c             	pushl  0xc(%ebp)
f0102049:	ff 30                	pushl  (%eax)
f010204b:	ff 55 08             	call   *0x8(%ebp)
			break;
f010204e:	83 c4 10             	add    $0x10,%esp
f0102051:	e9 a7 fe ff ff       	jmp    f0101efd <vprintfmt+0xe8>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102056:	8b 45 14             	mov    0x14(%ebp),%eax
f0102059:	8d 50 04             	lea    0x4(%eax),%edx
f010205c:	89 55 14             	mov    %edx,0x14(%ebp)
f010205f:	8b 00                	mov    (%eax),%eax
f0102061:	99                   	cltd   
f0102062:	31 d0                	xor    %edx,%eax
f0102064:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102066:	83 f8 06             	cmp    $0x6,%eax
f0102069:	7f 0b                	jg     f0102076 <vprintfmt+0x261>
f010206b:	8b 14 85 14 37 10 f0 	mov    -0xfefc8ec(,%eax,4),%edx
f0102072:	85 d2                	test   %edx,%edx
f0102074:	75 19                	jne    f010208f <vprintfmt+0x27a>
				printfmt(putch, putdat, "error %d", err);
f0102076:	50                   	push   %eax
f0102077:	68 87 36 10 f0       	push   $0xf0103687
f010207c:	ff 75 0c             	pushl  0xc(%ebp)
f010207f:	ff 75 08             	pushl  0x8(%ebp)
f0102082:	e8 71 fd ff ff       	call   f0101df8 <printfmt>
f0102087:	83 c4 10             	add    $0x10,%esp
f010208a:	e9 6e fe ff ff       	jmp    f0101efd <vprintfmt+0xe8>
			else
				printfmt(putch, putdat, "%s", p);
f010208f:	52                   	push   %edx
f0102090:	68 68 34 10 f0       	push   $0xf0103468
f0102095:	ff 75 0c             	pushl  0xc(%ebp)
f0102098:	ff 75 08             	pushl  0x8(%ebp)
f010209b:	e8 58 fd ff ff       	call   f0101df8 <printfmt>
f01020a0:	83 c4 10             	add    $0x10,%esp
f01020a3:	e9 55 fe ff ff       	jmp    f0101efd <vprintfmt+0xe8>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01020a8:	89 f1                	mov    %esi,%ecx
f01020aa:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01020ad:	8b 45 14             	mov    0x14(%ebp),%eax
f01020b0:	8d 50 04             	lea    0x4(%eax),%edx
f01020b3:	89 55 14             	mov    %edx,0x14(%ebp)
f01020b6:	8b 00                	mov    (%eax),%eax
f01020b8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01020bb:	85 c0                	test   %eax,%eax
f01020bd:	75 07                	jne    f01020c6 <vprintfmt+0x2b1>
				p = "(null)";
f01020bf:	c7 45 e0 80 36 10 f0 	movl   $0xf0103680,-0x20(%ebp)
			if (width > 0 && padc != '-')
f01020c6:	85 db                	test   %ebx,%ebx
f01020c8:	7e 67                	jle    f0102131 <vprintfmt+0x31c>
f01020ca:	80 7d df 2d          	cmpb   $0x2d,-0x21(%ebp)
f01020ce:	74 66                	je     f0102136 <vprintfmt+0x321>
				for (width -= strnlen(p, precision); width > 0; width--)
f01020d0:	83 ec 08             	sub    $0x8,%esp
f01020d3:	51                   	push   %ecx
f01020d4:	ff 75 e0             	pushl  -0x20(%ebp)
f01020d7:	e8 28 03 00 00       	call   f0102404 <strnlen>
f01020dc:	29 c3                	sub    %eax,%ebx
f01020de:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01020e1:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01020e4:	0f be 5d df          	movsbl -0x21(%ebp),%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01020e8:	eb 10                	jmp    f01020fa <vprintfmt+0x2e5>
					putch(padc, putdat);
f01020ea:	83 ec 08             	sub    $0x8,%esp
f01020ed:	ff 75 0c             	pushl  0xc(%ebp)
f01020f0:	53                   	push   %ebx
f01020f1:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01020f4:	ff 4d e4             	decl   -0x1c(%ebp)
f01020f7:	83 c4 10             	add    $0x10,%esp
f01020fa:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01020fe:	7f ea                	jg     f01020ea <vprintfmt+0x2d5>
f0102100:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102103:	eb 34                	jmp    f0102139 <vprintfmt+0x324>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102105:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102109:	74 16                	je     f0102121 <vprintfmt+0x30c>
f010210b:	8d 50 e0             	lea    -0x20(%eax),%edx
f010210e:	83 fa 5e             	cmp    $0x5e,%edx
f0102111:	76 0e                	jbe    f0102121 <vprintfmt+0x30c>
					putch('?', putdat);
f0102113:	83 ec 08             	sub    $0x8,%esp
f0102116:	53                   	push   %ebx
f0102117:	6a 3f                	push   $0x3f
f0102119:	ff 55 08             	call   *0x8(%ebp)
f010211c:	83 c4 10             	add    $0x10,%esp
f010211f:	eb 0b                	jmp    f010212c <vprintfmt+0x317>
				else
					putch(ch, putdat);
f0102121:	83 ec 08             	sub    $0x8,%esp
f0102124:	53                   	push   %ebx
f0102125:	50                   	push   %eax
f0102126:	ff 55 08             	call   *0x8(%ebp)
f0102129:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010212c:	ff 4d e4             	decl   -0x1c(%ebp)
f010212f:	eb 08                	jmp    f0102139 <vprintfmt+0x324>
f0102131:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102134:	eb 03                	jmp    f0102139 <vprintfmt+0x324>
f0102136:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102139:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010213c:	0f be 02             	movsbl (%edx),%eax
f010213f:	42                   	inc    %edx
f0102140:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0102143:	85 c0                	test   %eax,%eax
f0102145:	74 1d                	je     f0102164 <vprintfmt+0x34f>
f0102147:	85 f6                	test   %esi,%esi
f0102149:	78 ba                	js     f0102105 <vprintfmt+0x2f0>
f010214b:	4e                   	dec    %esi
f010214c:	79 b7                	jns    f0102105 <vprintfmt+0x2f0>
f010214e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102151:	eb 14                	jmp    f0102167 <vprintfmt+0x352>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102153:	83 ec 08             	sub    $0x8,%esp
f0102156:	ff 75 0c             	pushl  0xc(%ebp)
f0102159:	6a 20                	push   $0x20
f010215b:	ff 55 08             	call   *0x8(%ebp)
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010215e:	4b                   	dec    %ebx
f010215f:	83 c4 10             	add    $0x10,%esp
f0102162:	eb 03                	jmp    f0102167 <vprintfmt+0x352>
f0102164:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102167:	85 db                	test   %ebx,%ebx
f0102169:	7f e8                	jg     f0102153 <vprintfmt+0x33e>
f010216b:	e9 8d fd ff ff       	jmp    f0101efd <vprintfmt+0xe8>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102170:	8d 45 14             	lea    0x14(%ebp),%eax
f0102173:	e8 34 fc ff ff       	call   f0101dac <getint>
f0102178:	89 c3                	mov    %eax,%ebx
f010217a:	89 d6                	mov    %edx,%esi
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010217c:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102181:	85 d2                	test   %edx,%edx
f0102183:	0f 89 a4 00 00 00    	jns    f010222d <vprintfmt+0x418>
				putch('-', putdat);
f0102189:	83 ec 08             	sub    $0x8,%esp
f010218c:	ff 75 0c             	pushl  0xc(%ebp)
f010218f:	6a 2d                	push   $0x2d
f0102191:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0102194:	f7 db                	neg    %ebx
f0102196:	83 d6 00             	adc    $0x0,%esi
f0102199:	f7 de                	neg    %esi
f010219b:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010219e:	b8 0a 00 00 00       	mov    $0xa,%eax
f01021a3:	e9 85 00 00 00       	jmp    f010222d <vprintfmt+0x418>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01021a8:	8d 45 14             	lea    0x14(%ebp),%eax
f01021ab:	e8 c2 fb ff ff       	call   f0101d72 <getuint>
f01021b0:	89 c3                	mov    %eax,%ebx
f01021b2:	89 d6                	mov    %edx,%esi
			base = 10;
f01021b4:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f01021b9:	eb 72                	jmp    f010222d <vprintfmt+0x418>
			//// Replace this with your code.
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getint(&ap, lflag);
f01021bb:	8d 45 14             	lea    0x14(%ebp),%eax
f01021be:	e8 e9 fb ff ff       	call   f0101dac <getint>
f01021c3:	89 c3                	mov    %eax,%ebx
f01021c5:	89 d6                	mov    %edx,%esi
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 8;
f01021c7:	b8 08 00 00 00       	mov    $0x8,%eax
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01021cc:	85 d2                	test   %edx,%edx
f01021ce:	79 5d                	jns    f010222d <vprintfmt+0x418>
				putch('-', putdat);
f01021d0:	83 ec 08             	sub    $0x8,%esp
f01021d3:	ff 75 0c             	pushl  0xc(%ebp)
f01021d6:	6a 2d                	push   $0x2d
f01021d8:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01021db:	f7 db                	neg    %ebx
f01021dd:	83 d6 00             	adc    $0x0,%esi
f01021e0:	f7 de                	neg    %esi
f01021e2:	83 c4 10             	add    $0x10,%esp
			}
			base = 8;
f01021e5:	b8 08 00 00 00       	mov    $0x8,%eax
f01021ea:	eb 41                	jmp    f010222d <vprintfmt+0x418>
			goto number;

		// pointer
		case 'p':
			putch('0', putdat);
f01021ec:	83 ec 08             	sub    $0x8,%esp
f01021ef:	ff 75 0c             	pushl  0xc(%ebp)
f01021f2:	6a 30                	push   $0x30
f01021f4:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01021f7:	83 c4 08             	add    $0x8,%esp
f01021fa:	ff 75 0c             	pushl  0xc(%ebp)
f01021fd:	6a 78                	push   $0x78
f01021ff:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102202:	8b 45 14             	mov    0x14(%ebp),%eax
f0102205:	8d 50 04             	lea    0x4(%eax),%edx
f0102208:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010220b:	8b 18                	mov    (%eax),%ebx
f010220d:	be 00 00 00 00       	mov    $0x0,%esi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102212:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102215:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010221a:	eb 11                	jmp    f010222d <vprintfmt+0x418>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010221c:	8d 45 14             	lea    0x14(%ebp),%eax
f010221f:	e8 4e fb ff ff       	call   f0101d72 <getuint>
f0102224:	89 c3                	mov    %eax,%ebx
f0102226:	89 d6                	mov    %edx,%esi
			base = 16;
f0102228:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f010222d:	83 ec 0c             	sub    $0xc,%esp
f0102230:	0f be 55 df          	movsbl -0x21(%ebp),%edx
f0102234:	52                   	push   %edx
f0102235:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102238:	50                   	push   %eax
f0102239:	56                   	push   %esi
f010223a:	53                   	push   %ebx
f010223b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010223e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102241:	e8 7e fa ff ff       	call   f0101cc4 <printnum>
			break;
f0102246:	83 c4 20             	add    $0x20,%esp
f0102249:	e9 af fc ff ff       	jmp    f0101efd <vprintfmt+0xe8>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010224e:	83 ec 08             	sub    $0x8,%esp
f0102251:	ff 75 0c             	pushl  0xc(%ebp)
f0102254:	51                   	push   %ecx
f0102255:	ff 55 08             	call   *0x8(%ebp)
			break;
f0102258:	83 c4 10             	add    $0x10,%esp
f010225b:	e9 9d fc ff ff       	jmp    f0101efd <vprintfmt+0xe8>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102260:	83 ec 08             	sub    $0x8,%esp
f0102263:	ff 75 0c             	pushl  0xc(%ebp)
f0102266:	6a 25                	push   $0x25
f0102268:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010226b:	83 c4 10             	add    $0x10,%esp
f010226e:	89 df                	mov    %ebx,%edi
f0102270:	eb 02                	jmp    f0102274 <vprintfmt+0x45f>
f0102272:	89 c7                	mov    %eax,%edi
f0102274:	8d 47 ff             	lea    -0x1(%edi),%eax
f0102277:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010227b:	75 f5                	jne    f0102272 <vprintfmt+0x45d>
f010227d:	e9 7b fc ff ff       	jmp    f0101efd <vprintfmt+0xe8>
							break;

						case 2:
							switch(POP(fmt))
							{
								case '3': state = 3; subtype = 1; break;
f0102282:	b9 01 00 00 00       	mov    $0x1,%ecx
f0102287:	b8 03 00 00 00       	mov    $0x3,%eax
f010228c:	e9 b7 fb ff ff       	jmp    f0101e48 <vprintfmt+0x33>
							break;
							
						case 4:
							switch(POP(fmt))
							{
								case 'm': state = 5; break;
f0102291:	b8 05 00 00 00       	mov    $0x5,%eax
f0102296:	e9 ad fb ff ff       	jmp    f0101e48 <vprintfmt+0x33>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f010229b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010229e:	5b                   	pop    %ebx
f010229f:	5e                   	pop    %esi
f01022a0:	5f                   	pop    %edi
f01022a1:	c9                   	leave  
f01022a2:	c3                   	ret    

f01022a3 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01022a3:	55                   	push   %ebp
f01022a4:	89 e5                	mov    %esp,%ebp
f01022a6:	83 ec 18             	sub    $0x18,%esp
f01022a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01022ac:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01022af:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01022b2:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01022b6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01022b9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01022c0:	85 c0                	test   %eax,%eax
f01022c2:	74 26                	je     f01022ea <vsnprintf+0x47>
f01022c4:	85 d2                	test   %edx,%edx
f01022c6:	7e 29                	jle    f01022f1 <vsnprintf+0x4e>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01022c8:	ff 75 14             	pushl  0x14(%ebp)
f01022cb:	ff 75 10             	pushl  0x10(%ebp)
f01022ce:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01022d1:	50                   	push   %eax
f01022d2:	68 de 1d 10 f0       	push   $0xf0101dde
f01022d7:	e8 39 fb ff ff       	call   f0101e15 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01022dc:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01022df:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01022e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01022e5:	83 c4 10             	add    $0x10,%esp
f01022e8:	eb 0c                	jmp    f01022f6 <vsnprintf+0x53>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01022ea:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01022ef:	eb 05                	jmp    f01022f6 <vsnprintf+0x53>
f01022f1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01022f6:	c9                   	leave  
f01022f7:	c3                   	ret    

f01022f8 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01022f8:	55                   	push   %ebp
f01022f9:	89 e5                	mov    %esp,%ebp
f01022fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01022fe:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102301:	50                   	push   %eax
f0102302:	ff 75 10             	pushl  0x10(%ebp)
f0102305:	ff 75 0c             	pushl  0xc(%ebp)
f0102308:	ff 75 08             	pushl  0x8(%ebp)
f010230b:	e8 93 ff ff ff       	call   f01022a3 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102310:	c9                   	leave  
f0102311:	c3                   	ret    
	...

f0102314 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102314:	55                   	push   %ebp
f0102315:	89 e5                	mov    %esp,%ebp
f0102317:	57                   	push   %edi
f0102318:	56                   	push   %esi
f0102319:	53                   	push   %ebx
f010231a:	83 ec 0c             	sub    $0xc,%esp
f010231d:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102320:	85 c0                	test   %eax,%eax
f0102322:	74 11                	je     f0102335 <readline+0x21>
		cprintf("%s", prompt);
f0102324:	83 ec 08             	sub    $0x8,%esp
f0102327:	50                   	push   %eax
f0102328:	68 68 34 10 f0       	push   $0xf0103468
f010232d:	e8 46 f6 ff ff       	call   f0101978 <cprintf>
f0102332:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102335:	83 ec 0c             	sub    $0xc,%esp
f0102338:	6a 00                	push   $0x0
f010233a:	e8 a2 e2 ff ff       	call   f01005e1 <iscons>
f010233f:	89 c7                	mov    %eax,%edi
f0102341:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102344:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102349:	e8 82 e2 ff ff       	call   f01005d0 <getchar>
f010234e:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102350:	85 c0                	test   %eax,%eax
f0102352:	79 18                	jns    f010236c <readline+0x58>
			cprintf("read error: %e\n", c);
f0102354:	83 ec 08             	sub    $0x8,%esp
f0102357:	50                   	push   %eax
f0102358:	68 30 37 10 f0       	push   $0xf0103730
f010235d:	e8 16 f6 ff ff       	call   f0101978 <cprintf>
			return NULL;
f0102362:	83 c4 10             	add    $0x10,%esp
f0102365:	b8 00 00 00 00       	mov    $0x0,%eax
f010236a:	eb 6f                	jmp    f01023db <readline+0xc7>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010236c:	83 f8 08             	cmp    $0x8,%eax
f010236f:	74 05                	je     f0102376 <readline+0x62>
f0102371:	83 f8 7f             	cmp    $0x7f,%eax
f0102374:	75 18                	jne    f010238e <readline+0x7a>
f0102376:	85 f6                	test   %esi,%esi
f0102378:	7e 14                	jle    f010238e <readline+0x7a>
			if (echoing)
f010237a:	85 ff                	test   %edi,%edi
f010237c:	74 0d                	je     f010238b <readline+0x77>
				cputchar('\b');
f010237e:	83 ec 0c             	sub    $0xc,%esp
f0102381:	6a 08                	push   $0x8
f0102383:	e8 38 e2 ff ff       	call   f01005c0 <cputchar>
f0102388:	83 c4 10             	add    $0x10,%esp
			i--;
f010238b:	4e                   	dec    %esi
f010238c:	eb bb                	jmp    f0102349 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010238e:	83 fb 1f             	cmp    $0x1f,%ebx
f0102391:	7e 21                	jle    f01023b4 <readline+0xa0>
f0102393:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102399:	7f 19                	jg     f01023b4 <readline+0xa0>
			if (echoing)
f010239b:	85 ff                	test   %edi,%edi
f010239d:	74 0c                	je     f01023ab <readline+0x97>
				cputchar(c);
f010239f:	83 ec 0c             	sub    $0xc,%esp
f01023a2:	53                   	push   %ebx
f01023a3:	e8 18 e2 ff ff       	call   f01005c0 <cputchar>
f01023a8:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01023ab:	88 9e 60 b5 11 f0    	mov    %bl,-0xfee4aa0(%esi)
f01023b1:	46                   	inc    %esi
f01023b2:	eb 95                	jmp    f0102349 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01023b4:	83 fb 0a             	cmp    $0xa,%ebx
f01023b7:	74 05                	je     f01023be <readline+0xaa>
f01023b9:	83 fb 0d             	cmp    $0xd,%ebx
f01023bc:	75 8b                	jne    f0102349 <readline+0x35>
			if (echoing)
f01023be:	85 ff                	test   %edi,%edi
f01023c0:	74 0d                	je     f01023cf <readline+0xbb>
				cputchar('\n');
f01023c2:	83 ec 0c             	sub    $0xc,%esp
f01023c5:	6a 0a                	push   $0xa
f01023c7:	e8 f4 e1 ff ff       	call   f01005c0 <cputchar>
f01023cc:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01023cf:	c6 86 60 b5 11 f0 00 	movb   $0x0,-0xfee4aa0(%esi)
			return buf;
f01023d6:	b8 60 b5 11 f0       	mov    $0xf011b560,%eax
		}
	}
}
f01023db:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01023de:	5b                   	pop    %ebx
f01023df:	5e                   	pop    %esi
f01023e0:	5f                   	pop    %edi
f01023e1:	c9                   	leave  
f01023e2:	c3                   	ret    
	...

f01023e4 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01023e4:	55                   	push   %ebp
f01023e5:	89 e5                	mov    %esp,%ebp
f01023e7:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01023ea:	80 3a 00             	cmpb   $0x0,(%edx)
f01023ed:	74 0e                	je     f01023fd <strlen+0x19>
f01023ef:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01023f4:	40                   	inc    %eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01023f5:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01023f9:	75 f9                	jne    f01023f4 <strlen+0x10>
f01023fb:	eb 05                	jmp    f0102402 <strlen+0x1e>
f01023fd:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0102402:	c9                   	leave  
f0102403:	c3                   	ret    

f0102404 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102404:	55                   	push   %ebp
f0102405:	89 e5                	mov    %esp,%ebp
f0102407:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010240a:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010240d:	85 d2                	test   %edx,%edx
f010240f:	74 17                	je     f0102428 <strnlen+0x24>
f0102411:	80 39 00             	cmpb   $0x0,(%ecx)
f0102414:	74 19                	je     f010242f <strnlen+0x2b>
f0102416:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f010241b:	40                   	inc    %eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010241c:	39 d0                	cmp    %edx,%eax
f010241e:	74 14                	je     f0102434 <strnlen+0x30>
f0102420:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0102424:	75 f5                	jne    f010241b <strnlen+0x17>
f0102426:	eb 0c                	jmp    f0102434 <strnlen+0x30>
f0102428:	b8 00 00 00 00       	mov    $0x0,%eax
f010242d:	eb 05                	jmp    f0102434 <strnlen+0x30>
f010242f:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0102434:	c9                   	leave  
f0102435:	c3                   	ret    

f0102436 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102436:	55                   	push   %ebp
f0102437:	89 e5                	mov    %esp,%ebp
f0102439:	53                   	push   %ebx
f010243a:	8b 45 08             	mov    0x8(%ebp),%eax
f010243d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0102440:	ba 00 00 00 00       	mov    $0x0,%edx
f0102445:	8a 0c 13             	mov    (%ebx,%edx,1),%cl
f0102448:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f010244b:	42                   	inc    %edx
f010244c:	84 c9                	test   %cl,%cl
f010244e:	75 f5                	jne    f0102445 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0102450:	5b                   	pop    %ebx
f0102451:	c9                   	leave  
f0102452:	c3                   	ret    

f0102453 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0102453:	55                   	push   %ebp
f0102454:	89 e5                	mov    %esp,%ebp
f0102456:	53                   	push   %ebx
f0102457:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010245a:	53                   	push   %ebx
f010245b:	e8 84 ff ff ff       	call   f01023e4 <strlen>
f0102460:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0102463:	ff 75 0c             	pushl  0xc(%ebp)
f0102466:	8d 04 03             	lea    (%ebx,%eax,1),%eax
f0102469:	50                   	push   %eax
f010246a:	e8 c7 ff ff ff       	call   f0102436 <strcpy>
	return dst;
}
f010246f:	89 d8                	mov    %ebx,%eax
f0102471:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102474:	c9                   	leave  
f0102475:	c3                   	ret    

f0102476 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102476:	55                   	push   %ebp
f0102477:	89 e5                	mov    %esp,%ebp
f0102479:	56                   	push   %esi
f010247a:	53                   	push   %ebx
f010247b:	8b 45 08             	mov    0x8(%ebp),%eax
f010247e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102481:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102484:	85 f6                	test   %esi,%esi
f0102486:	74 15                	je     f010249d <strncpy+0x27>
f0102488:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f010248d:	8a 1a                	mov    (%edx),%bl
f010248f:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0102492:	80 3a 01             	cmpb   $0x1,(%edx)
f0102495:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102498:	41                   	inc    %ecx
f0102499:	39 ce                	cmp    %ecx,%esi
f010249b:	77 f0                	ja     f010248d <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010249d:	5b                   	pop    %ebx
f010249e:	5e                   	pop    %esi
f010249f:	c9                   	leave  
f01024a0:	c3                   	ret    

f01024a1 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01024a1:	55                   	push   %ebp
f01024a2:	89 e5                	mov    %esp,%ebp
f01024a4:	57                   	push   %edi
f01024a5:	56                   	push   %esi
f01024a6:	53                   	push   %ebx
f01024a7:	8b 7d 08             	mov    0x8(%ebp),%edi
f01024aa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01024ad:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01024b0:	85 f6                	test   %esi,%esi
f01024b2:	74 32                	je     f01024e6 <strlcpy+0x45>
		while (--size > 0 && *src != '\0')
f01024b4:	83 fe 01             	cmp    $0x1,%esi
f01024b7:	74 22                	je     f01024db <strlcpy+0x3a>
f01024b9:	8a 0b                	mov    (%ebx),%cl
f01024bb:	84 c9                	test   %cl,%cl
f01024bd:	74 20                	je     f01024df <strlcpy+0x3e>
f01024bf:	89 f8                	mov    %edi,%eax
f01024c1:	ba 00 00 00 00       	mov    $0x0,%edx
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01024c6:	83 ee 02             	sub    $0x2,%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01024c9:	88 08                	mov    %cl,(%eax)
f01024cb:	40                   	inc    %eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01024cc:	39 f2                	cmp    %esi,%edx
f01024ce:	74 11                	je     f01024e1 <strlcpy+0x40>
f01024d0:	8a 4c 13 01          	mov    0x1(%ebx,%edx,1),%cl
f01024d4:	42                   	inc    %edx
f01024d5:	84 c9                	test   %cl,%cl
f01024d7:	75 f0                	jne    f01024c9 <strlcpy+0x28>
f01024d9:	eb 06                	jmp    f01024e1 <strlcpy+0x40>
f01024db:	89 f8                	mov    %edi,%eax
f01024dd:	eb 02                	jmp    f01024e1 <strlcpy+0x40>
f01024df:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01024e1:	c6 00 00             	movb   $0x0,(%eax)
f01024e4:	eb 02                	jmp    f01024e8 <strlcpy+0x47>
strlcpy(char *dst, const char *src, size_t size)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01024e6:	89 f8                	mov    %edi,%eax
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
		*dst = '\0';
	}
	return dst - dst_in;
f01024e8:	29 f8                	sub    %edi,%eax
}
f01024ea:	5b                   	pop    %ebx
f01024eb:	5e                   	pop    %esi
f01024ec:	5f                   	pop    %edi
f01024ed:	c9                   	leave  
f01024ee:	c3                   	ret    

f01024ef <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01024ef:	55                   	push   %ebp
f01024f0:	89 e5                	mov    %esp,%ebp
f01024f2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01024f5:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01024f8:	8a 01                	mov    (%ecx),%al
f01024fa:	84 c0                	test   %al,%al
f01024fc:	74 10                	je     f010250e <strcmp+0x1f>
f01024fe:	3a 02                	cmp    (%edx),%al
f0102500:	75 0c                	jne    f010250e <strcmp+0x1f>
		p++, q++;
f0102502:	41                   	inc    %ecx
f0102503:	42                   	inc    %edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0102504:	8a 01                	mov    (%ecx),%al
f0102506:	84 c0                	test   %al,%al
f0102508:	74 04                	je     f010250e <strcmp+0x1f>
f010250a:	3a 02                	cmp    (%edx),%al
f010250c:	74 f4                	je     f0102502 <strcmp+0x13>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010250e:	0f b6 c0             	movzbl %al,%eax
f0102511:	0f b6 12             	movzbl (%edx),%edx
f0102514:	29 d0                	sub    %edx,%eax
}
f0102516:	c9                   	leave  
f0102517:	c3                   	ret    

f0102518 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0102518:	55                   	push   %ebp
f0102519:	89 e5                	mov    %esp,%ebp
f010251b:	53                   	push   %ebx
f010251c:	8b 55 08             	mov    0x8(%ebp),%edx
f010251f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102522:	8b 45 10             	mov    0x10(%ebp),%eax
	while (n > 0 && *p && *p == *q)
f0102525:	85 c0                	test   %eax,%eax
f0102527:	74 1b                	je     f0102544 <strncmp+0x2c>
f0102529:	8a 1a                	mov    (%edx),%bl
f010252b:	84 db                	test   %bl,%bl
f010252d:	74 24                	je     f0102553 <strncmp+0x3b>
f010252f:	3a 19                	cmp    (%ecx),%bl
f0102531:	75 20                	jne    f0102553 <strncmp+0x3b>
f0102533:	48                   	dec    %eax
f0102534:	74 15                	je     f010254b <strncmp+0x33>
		n--, p++, q++;
f0102536:	42                   	inc    %edx
f0102537:	41                   	inc    %ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0102538:	8a 1a                	mov    (%edx),%bl
f010253a:	84 db                	test   %bl,%bl
f010253c:	74 15                	je     f0102553 <strncmp+0x3b>
f010253e:	3a 19                	cmp    (%ecx),%bl
f0102540:	74 f1                	je     f0102533 <strncmp+0x1b>
f0102542:	eb 0f                	jmp    f0102553 <strncmp+0x3b>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0102544:	b8 00 00 00 00       	mov    $0x0,%eax
f0102549:	eb 05                	jmp    f0102550 <strncmp+0x38>
f010254b:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0102550:	5b                   	pop    %ebx
f0102551:	c9                   	leave  
f0102552:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0102553:	0f b6 02             	movzbl (%edx),%eax
f0102556:	0f b6 11             	movzbl (%ecx),%edx
f0102559:	29 d0                	sub    %edx,%eax
f010255b:	eb f3                	jmp    f0102550 <strncmp+0x38>

f010255d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010255d:	55                   	push   %ebp
f010255e:	89 e5                	mov    %esp,%ebp
f0102560:	8b 45 08             	mov    0x8(%ebp),%eax
f0102563:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f0102566:	8a 10                	mov    (%eax),%dl
f0102568:	84 d2                	test   %dl,%dl
f010256a:	74 18                	je     f0102584 <strchr+0x27>
		if (*s == c)
f010256c:	38 ca                	cmp    %cl,%dl
f010256e:	75 06                	jne    f0102576 <strchr+0x19>
f0102570:	eb 17                	jmp    f0102589 <strchr+0x2c>
f0102572:	38 ca                	cmp    %cl,%dl
f0102574:	74 13                	je     f0102589 <strchr+0x2c>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0102576:	40                   	inc    %eax
f0102577:	8a 10                	mov    (%eax),%dl
f0102579:	84 d2                	test   %dl,%dl
f010257b:	75 f5                	jne    f0102572 <strchr+0x15>
		if (*s == c)
			return (char *) s;
	return 0;
f010257d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102582:	eb 05                	jmp    f0102589 <strchr+0x2c>
f0102584:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102589:	c9                   	leave  
f010258a:	c3                   	ret    

f010258b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010258b:	55                   	push   %ebp
f010258c:	89 e5                	mov    %esp,%ebp
f010258e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102591:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f0102594:	8a 10                	mov    (%eax),%dl
f0102596:	84 d2                	test   %dl,%dl
f0102598:	74 11                	je     f01025ab <strfind+0x20>
		if (*s == c)
f010259a:	38 ca                	cmp    %cl,%dl
f010259c:	75 06                	jne    f01025a4 <strfind+0x19>
f010259e:	eb 0b                	jmp    f01025ab <strfind+0x20>
f01025a0:	38 ca                	cmp    %cl,%dl
f01025a2:	74 07                	je     f01025ab <strfind+0x20>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01025a4:	40                   	inc    %eax
f01025a5:	8a 10                	mov    (%eax),%dl
f01025a7:	84 d2                	test   %dl,%dl
f01025a9:	75 f5                	jne    f01025a0 <strfind+0x15>
		if (*s == c)
			break;
	return (char *) s;
}
f01025ab:	c9                   	leave  
f01025ac:	c3                   	ret    

f01025ad <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01025ad:	55                   	push   %ebp
f01025ae:	89 e5                	mov    %esp,%ebp
f01025b0:	57                   	push   %edi
f01025b1:	56                   	push   %esi
f01025b2:	53                   	push   %ebx
f01025b3:	8b 7d 08             	mov    0x8(%ebp),%edi
f01025b6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025b9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01025bc:	85 c9                	test   %ecx,%ecx
f01025be:	74 30                	je     f01025f0 <memset+0x43>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01025c0:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01025c6:	75 25                	jne    f01025ed <memset+0x40>
f01025c8:	f6 c1 03             	test   $0x3,%cl
f01025cb:	75 20                	jne    f01025ed <memset+0x40>
		c &= 0xFF;
f01025cd:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01025d0:	89 d3                	mov    %edx,%ebx
f01025d2:	c1 e3 08             	shl    $0x8,%ebx
f01025d5:	89 d6                	mov    %edx,%esi
f01025d7:	c1 e6 18             	shl    $0x18,%esi
f01025da:	89 d0                	mov    %edx,%eax
f01025dc:	c1 e0 10             	shl    $0x10,%eax
f01025df:	09 f0                	or     %esi,%eax
f01025e1:	09 d0                	or     %edx,%eax
f01025e3:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01025e5:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01025e8:	fc                   	cld    
f01025e9:	f3 ab                	rep stos %eax,%es:(%edi)
f01025eb:	eb 03                	jmp    f01025f0 <memset+0x43>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01025ed:	fc                   	cld    
f01025ee:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01025f0:	89 f8                	mov    %edi,%eax
f01025f2:	5b                   	pop    %ebx
f01025f3:	5e                   	pop    %esi
f01025f4:	5f                   	pop    %edi
f01025f5:	c9                   	leave  
f01025f6:	c3                   	ret    

f01025f7 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01025f7:	55                   	push   %ebp
f01025f8:	89 e5                	mov    %esp,%ebp
f01025fa:	57                   	push   %edi
f01025fb:	56                   	push   %esi
f01025fc:	8b 45 08             	mov    0x8(%ebp),%eax
f01025ff:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102602:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0102605:	39 c6                	cmp    %eax,%esi
f0102607:	73 34                	jae    f010263d <memmove+0x46>
f0102609:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010260c:	39 d0                	cmp    %edx,%eax
f010260e:	73 2d                	jae    f010263d <memmove+0x46>
		s += n;
		d += n;
f0102610:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102613:	f6 c2 03             	test   $0x3,%dl
f0102616:	75 1b                	jne    f0102633 <memmove+0x3c>
f0102618:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010261e:	75 13                	jne    f0102633 <memmove+0x3c>
f0102620:	f6 c1 03             	test   $0x3,%cl
f0102623:	75 0e                	jne    f0102633 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0102625:	83 ef 04             	sub    $0x4,%edi
f0102628:	8d 72 fc             	lea    -0x4(%edx),%esi
f010262b:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010262e:	fd                   	std    
f010262f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102631:	eb 07                	jmp    f010263a <memmove+0x43>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0102633:	4f                   	dec    %edi
f0102634:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0102637:	fd                   	std    
f0102638:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010263a:	fc                   	cld    
f010263b:	eb 20                	jmp    f010265d <memmove+0x66>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010263d:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0102643:	75 13                	jne    f0102658 <memmove+0x61>
f0102645:	a8 03                	test   $0x3,%al
f0102647:	75 0f                	jne    f0102658 <memmove+0x61>
f0102649:	f6 c1 03             	test   $0x3,%cl
f010264c:	75 0a                	jne    f0102658 <memmove+0x61>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010264e:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0102651:	89 c7                	mov    %eax,%edi
f0102653:	fc                   	cld    
f0102654:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102656:	eb 05                	jmp    f010265d <memmove+0x66>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0102658:	89 c7                	mov    %eax,%edi
f010265a:	fc                   	cld    
f010265b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010265d:	5e                   	pop    %esi
f010265e:	5f                   	pop    %edi
f010265f:	c9                   	leave  
f0102660:	c3                   	ret    

f0102661 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0102661:	55                   	push   %ebp
f0102662:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0102664:	ff 75 10             	pushl  0x10(%ebp)
f0102667:	ff 75 0c             	pushl  0xc(%ebp)
f010266a:	ff 75 08             	pushl  0x8(%ebp)
f010266d:	e8 85 ff ff ff       	call   f01025f7 <memmove>
}
f0102672:	c9                   	leave  
f0102673:	c3                   	ret    

f0102674 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0102674:	55                   	push   %ebp
f0102675:	89 e5                	mov    %esp,%ebp
f0102677:	57                   	push   %edi
f0102678:	56                   	push   %esi
f0102679:	53                   	push   %ebx
f010267a:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010267d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102680:	8b 7d 10             	mov    0x10(%ebp),%edi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102683:	85 ff                	test   %edi,%edi
f0102685:	74 32                	je     f01026b9 <memcmp+0x45>
		if (*s1 != *s2)
f0102687:	8a 03                	mov    (%ebx),%al
f0102689:	8a 0e                	mov    (%esi),%cl
f010268b:	38 c8                	cmp    %cl,%al
f010268d:	74 19                	je     f01026a8 <memcmp+0x34>
f010268f:	eb 0d                	jmp    f010269e <memcmp+0x2a>
f0102691:	8a 44 13 01          	mov    0x1(%ebx,%edx,1),%al
f0102695:	8a 4c 16 01          	mov    0x1(%esi,%edx,1),%cl
f0102699:	42                   	inc    %edx
f010269a:	38 c8                	cmp    %cl,%al
f010269c:	74 10                	je     f01026ae <memcmp+0x3a>
			return (int) *s1 - (int) *s2;
f010269e:	0f b6 c0             	movzbl %al,%eax
f01026a1:	0f b6 c9             	movzbl %cl,%ecx
f01026a4:	29 c8                	sub    %ecx,%eax
f01026a6:	eb 16                	jmp    f01026be <memcmp+0x4a>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01026a8:	4f                   	dec    %edi
f01026a9:	ba 00 00 00 00       	mov    $0x0,%edx
f01026ae:	39 fa                	cmp    %edi,%edx
f01026b0:	75 df                	jne    f0102691 <memcmp+0x1d>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01026b2:	b8 00 00 00 00       	mov    $0x0,%eax
f01026b7:	eb 05                	jmp    f01026be <memcmp+0x4a>
f01026b9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01026be:	5b                   	pop    %ebx
f01026bf:	5e                   	pop    %esi
f01026c0:	5f                   	pop    %edi
f01026c1:	c9                   	leave  
f01026c2:	c3                   	ret    

f01026c3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01026c3:	55                   	push   %ebp
f01026c4:	89 e5                	mov    %esp,%ebp
f01026c6:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01026c9:	89 c2                	mov    %eax,%edx
f01026cb:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01026ce:	39 d0                	cmp    %edx,%eax
f01026d0:	73 12                	jae    f01026e4 <memfind+0x21>
		if (*(const unsigned char *) s == (unsigned char) c)
f01026d2:	8a 4d 0c             	mov    0xc(%ebp),%cl
f01026d5:	38 08                	cmp    %cl,(%eax)
f01026d7:	75 06                	jne    f01026df <memfind+0x1c>
f01026d9:	eb 09                	jmp    f01026e4 <memfind+0x21>
f01026db:	38 08                	cmp    %cl,(%eax)
f01026dd:	74 05                	je     f01026e4 <memfind+0x21>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01026df:	40                   	inc    %eax
f01026e0:	39 c2                	cmp    %eax,%edx
f01026e2:	77 f7                	ja     f01026db <memfind+0x18>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01026e4:	c9                   	leave  
f01026e5:	c3                   	ret    

f01026e6 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01026e6:	55                   	push   %ebp
f01026e7:	89 e5                	mov    %esp,%ebp
f01026e9:	57                   	push   %edi
f01026ea:	56                   	push   %esi
f01026eb:	53                   	push   %ebx
f01026ec:	8b 55 08             	mov    0x8(%ebp),%edx
f01026ef:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01026f2:	eb 01                	jmp    f01026f5 <strtol+0xf>
		s++;
f01026f4:	42                   	inc    %edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01026f5:	8a 02                	mov    (%edx),%al
f01026f7:	3c 20                	cmp    $0x20,%al
f01026f9:	74 f9                	je     f01026f4 <strtol+0xe>
f01026fb:	3c 09                	cmp    $0x9,%al
f01026fd:	74 f5                	je     f01026f4 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01026ff:	3c 2b                	cmp    $0x2b,%al
f0102701:	75 08                	jne    f010270b <strtol+0x25>
		s++;
f0102703:	42                   	inc    %edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0102704:	bf 00 00 00 00       	mov    $0x0,%edi
f0102709:	eb 13                	jmp    f010271e <strtol+0x38>
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010270b:	3c 2d                	cmp    $0x2d,%al
f010270d:	75 0a                	jne    f0102719 <strtol+0x33>
		s++, neg = 1;
f010270f:	8d 52 01             	lea    0x1(%edx),%edx
f0102712:	bf 01 00 00 00       	mov    $0x1,%edi
f0102717:	eb 05                	jmp    f010271e <strtol+0x38>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0102719:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010271e:	85 db                	test   %ebx,%ebx
f0102720:	74 05                	je     f0102727 <strtol+0x41>
f0102722:	83 fb 10             	cmp    $0x10,%ebx
f0102725:	75 28                	jne    f010274f <strtol+0x69>
f0102727:	8a 02                	mov    (%edx),%al
f0102729:	3c 30                	cmp    $0x30,%al
f010272b:	75 10                	jne    f010273d <strtol+0x57>
f010272d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0102731:	75 0a                	jne    f010273d <strtol+0x57>
		s += 2, base = 16;
f0102733:	83 c2 02             	add    $0x2,%edx
f0102736:	bb 10 00 00 00       	mov    $0x10,%ebx
f010273b:	eb 12                	jmp    f010274f <strtol+0x69>
	else if (base == 0 && s[0] == '0')
f010273d:	85 db                	test   %ebx,%ebx
f010273f:	75 0e                	jne    f010274f <strtol+0x69>
f0102741:	3c 30                	cmp    $0x30,%al
f0102743:	75 05                	jne    f010274a <strtol+0x64>
		s++, base = 8;
f0102745:	42                   	inc    %edx
f0102746:	b3 08                	mov    $0x8,%bl
f0102748:	eb 05                	jmp    f010274f <strtol+0x69>
	else if (base == 0)
		base = 10;
f010274a:	bb 0a 00 00 00       	mov    $0xa,%ebx
f010274f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102754:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0102756:	8a 0a                	mov    (%edx),%cl
f0102758:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f010275b:	80 fb 09             	cmp    $0x9,%bl
f010275e:	77 08                	ja     f0102768 <strtol+0x82>
			dig = *s - '0';
f0102760:	0f be c9             	movsbl %cl,%ecx
f0102763:	83 e9 30             	sub    $0x30,%ecx
f0102766:	eb 1e                	jmp    f0102786 <strtol+0xa0>
		else if (*s >= 'a' && *s <= 'z')
f0102768:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f010276b:	80 fb 19             	cmp    $0x19,%bl
f010276e:	77 08                	ja     f0102778 <strtol+0x92>
			dig = *s - 'a' + 10;
f0102770:	0f be c9             	movsbl %cl,%ecx
f0102773:	83 e9 57             	sub    $0x57,%ecx
f0102776:	eb 0e                	jmp    f0102786 <strtol+0xa0>
		else if (*s >= 'A' && *s <= 'Z')
f0102778:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f010277b:	80 fb 19             	cmp    $0x19,%bl
f010277e:	77 13                	ja     f0102793 <strtol+0xad>
			dig = *s - 'A' + 10;
f0102780:	0f be c9             	movsbl %cl,%ecx
f0102783:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0102786:	39 f1                	cmp    %esi,%ecx
f0102788:	7d 0d                	jge    f0102797 <strtol+0xb1>
			break;
		s++, val = (val * base) + dig;
f010278a:	42                   	inc    %edx
f010278b:	0f af c6             	imul   %esi,%eax
f010278e:	8d 04 01             	lea    (%ecx,%eax,1),%eax
		// we don't properly detect overflow!
	}
f0102791:	eb c3                	jmp    f0102756 <strtol+0x70>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0102793:	89 c1                	mov    %eax,%ecx
f0102795:	eb 02                	jmp    f0102799 <strtol+0xb3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0102797:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0102799:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010279d:	74 05                	je     f01027a4 <strtol+0xbe>
		*endptr = (char *) s;
f010279f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01027a2:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01027a4:	85 ff                	test   %edi,%edi
f01027a6:	74 04                	je     f01027ac <strtol+0xc6>
f01027a8:	89 c8                	mov    %ecx,%eax
f01027aa:	f7 d8                	neg    %eax
}
f01027ac:	5b                   	pop    %ebx
f01027ad:	5e                   	pop    %esi
f01027ae:	5f                   	pop    %edi
f01027af:	c9                   	leave  
f01027b0:	c3                   	ret    
f01027b1:	00 00                	add    %al,(%eax)
	...

f01027b4 <__udivdi3>:
f01027b4:	55                   	push   %ebp
f01027b5:	89 e5                	mov    %esp,%ebp
f01027b7:	57                   	push   %edi
f01027b8:	56                   	push   %esi
f01027b9:	83 ec 10             	sub    $0x10,%esp
f01027bc:	8b 7d 08             	mov    0x8(%ebp),%edi
f01027bf:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01027c2:	89 7d f0             	mov    %edi,-0x10(%ebp)
f01027c5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01027c8:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f01027cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01027ce:	85 c0                	test   %eax,%eax
f01027d0:	75 2e                	jne    f0102800 <__udivdi3+0x4c>
f01027d2:	39 f1                	cmp    %esi,%ecx
f01027d4:	77 5a                	ja     f0102830 <__udivdi3+0x7c>
f01027d6:	85 c9                	test   %ecx,%ecx
f01027d8:	75 0b                	jne    f01027e5 <__udivdi3+0x31>
f01027da:	b8 01 00 00 00       	mov    $0x1,%eax
f01027df:	31 d2                	xor    %edx,%edx
f01027e1:	f7 f1                	div    %ecx
f01027e3:	89 c1                	mov    %eax,%ecx
f01027e5:	31 d2                	xor    %edx,%edx
f01027e7:	89 f0                	mov    %esi,%eax
f01027e9:	f7 f1                	div    %ecx
f01027eb:	89 c6                	mov    %eax,%esi
f01027ed:	89 f8                	mov    %edi,%eax
f01027ef:	f7 f1                	div    %ecx
f01027f1:	89 c7                	mov    %eax,%edi
f01027f3:	89 f8                	mov    %edi,%eax
f01027f5:	89 f2                	mov    %esi,%edx
f01027f7:	83 c4 10             	add    $0x10,%esp
f01027fa:	5e                   	pop    %esi
f01027fb:	5f                   	pop    %edi
f01027fc:	c9                   	leave  
f01027fd:	c3                   	ret    
f01027fe:	66 90                	xchg   %ax,%ax
f0102800:	39 f0                	cmp    %esi,%eax
f0102802:	77 1c                	ja     f0102820 <__udivdi3+0x6c>
f0102804:	0f bd f8             	bsr    %eax,%edi
f0102807:	83 f7 1f             	xor    $0x1f,%edi
f010280a:	75 3c                	jne    f0102848 <__udivdi3+0x94>
f010280c:	39 f0                	cmp    %esi,%eax
f010280e:	0f 82 90 00 00 00    	jb     f01028a4 <__udivdi3+0xf0>
f0102814:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0102817:	39 55 f4             	cmp    %edx,-0xc(%ebp)
f010281a:	0f 86 84 00 00 00    	jbe    f01028a4 <__udivdi3+0xf0>
f0102820:	31 f6                	xor    %esi,%esi
f0102822:	31 ff                	xor    %edi,%edi
f0102824:	89 f8                	mov    %edi,%eax
f0102826:	89 f2                	mov    %esi,%edx
f0102828:	83 c4 10             	add    $0x10,%esp
f010282b:	5e                   	pop    %esi
f010282c:	5f                   	pop    %edi
f010282d:	c9                   	leave  
f010282e:	c3                   	ret    
f010282f:	90                   	nop
f0102830:	89 f2                	mov    %esi,%edx
f0102832:	89 f8                	mov    %edi,%eax
f0102834:	f7 f1                	div    %ecx
f0102836:	89 c7                	mov    %eax,%edi
f0102838:	31 f6                	xor    %esi,%esi
f010283a:	89 f8                	mov    %edi,%eax
f010283c:	89 f2                	mov    %esi,%edx
f010283e:	83 c4 10             	add    $0x10,%esp
f0102841:	5e                   	pop    %esi
f0102842:	5f                   	pop    %edi
f0102843:	c9                   	leave  
f0102844:	c3                   	ret    
f0102845:	8d 76 00             	lea    0x0(%esi),%esi
f0102848:	89 f9                	mov    %edi,%ecx
f010284a:	d3 e0                	shl    %cl,%eax
f010284c:	89 45 e8             	mov    %eax,-0x18(%ebp)
f010284f:	b8 20 00 00 00       	mov    $0x20,%eax
f0102854:	29 f8                	sub    %edi,%eax
f0102856:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102859:	88 c1                	mov    %al,%cl
f010285b:	d3 ea                	shr    %cl,%edx
f010285d:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102860:	09 ca                	or     %ecx,%edx
f0102862:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0102865:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102868:	89 f9                	mov    %edi,%ecx
f010286a:	d3 e2                	shl    %cl,%edx
f010286c:	89 55 f4             	mov    %edx,-0xc(%ebp)
f010286f:	89 f2                	mov    %esi,%edx
f0102871:	88 c1                	mov    %al,%cl
f0102873:	d3 ea                	shr    %cl,%edx
f0102875:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102878:	89 f2                	mov    %esi,%edx
f010287a:	89 f9                	mov    %edi,%ecx
f010287c:	d3 e2                	shl    %cl,%edx
f010287e:	8b 75 f0             	mov    -0x10(%ebp),%esi
f0102881:	88 c1                	mov    %al,%cl
f0102883:	d3 ee                	shr    %cl,%esi
f0102885:	09 d6                	or     %edx,%esi
f0102887:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f010288a:	89 f0                	mov    %esi,%eax
f010288c:	89 ca                	mov    %ecx,%edx
f010288e:	f7 75 ec             	divl   -0x14(%ebp)
f0102891:	89 d1                	mov    %edx,%ecx
f0102893:	89 c6                	mov    %eax,%esi
f0102895:	f7 65 f4             	mull   -0xc(%ebp)
f0102898:	39 d1                	cmp    %edx,%ecx
f010289a:	72 28                	jb     f01028c4 <__udivdi3+0x110>
f010289c:	74 1a                	je     f01028b8 <__udivdi3+0x104>
f010289e:	89 f7                	mov    %esi,%edi
f01028a0:	31 f6                	xor    %esi,%esi
f01028a2:	eb 80                	jmp    f0102824 <__udivdi3+0x70>
f01028a4:	31 f6                	xor    %esi,%esi
f01028a6:	bf 01 00 00 00       	mov    $0x1,%edi
f01028ab:	89 f8                	mov    %edi,%eax
f01028ad:	89 f2                	mov    %esi,%edx
f01028af:	83 c4 10             	add    $0x10,%esp
f01028b2:	5e                   	pop    %esi
f01028b3:	5f                   	pop    %edi
f01028b4:	c9                   	leave  
f01028b5:	c3                   	ret    
f01028b6:	66 90                	xchg   %ax,%ax
f01028b8:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01028bb:	89 f9                	mov    %edi,%ecx
f01028bd:	d3 e2                	shl    %cl,%edx
f01028bf:	39 c2                	cmp    %eax,%edx
f01028c1:	73 db                	jae    f010289e <__udivdi3+0xea>
f01028c3:	90                   	nop
f01028c4:	8d 7e ff             	lea    -0x1(%esi),%edi
f01028c7:	31 f6                	xor    %esi,%esi
f01028c9:	e9 56 ff ff ff       	jmp    f0102824 <__udivdi3+0x70>
	...

f01028d0 <__umoddi3>:
f01028d0:	55                   	push   %ebp
f01028d1:	89 e5                	mov    %esp,%ebp
f01028d3:	57                   	push   %edi
f01028d4:	56                   	push   %esi
f01028d5:	83 ec 20             	sub    $0x20,%esp
f01028d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01028db:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01028de:	89 45 e8             	mov    %eax,-0x18(%ebp)
f01028e1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01028e4:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f01028e7:	8b 7d 14             	mov    0x14(%ebp),%edi
f01028ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01028ed:	89 f2                	mov    %esi,%edx
f01028ef:	85 ff                	test   %edi,%edi
f01028f1:	75 15                	jne    f0102908 <__umoddi3+0x38>
f01028f3:	39 f1                	cmp    %esi,%ecx
f01028f5:	0f 86 99 00 00 00    	jbe    f0102994 <__umoddi3+0xc4>
f01028fb:	f7 f1                	div    %ecx
f01028fd:	89 d0                	mov    %edx,%eax
f01028ff:	31 d2                	xor    %edx,%edx
f0102901:	83 c4 20             	add    $0x20,%esp
f0102904:	5e                   	pop    %esi
f0102905:	5f                   	pop    %edi
f0102906:	c9                   	leave  
f0102907:	c3                   	ret    
f0102908:	39 f7                	cmp    %esi,%edi
f010290a:	0f 87 a4 00 00 00    	ja     f01029b4 <__umoddi3+0xe4>
f0102910:	0f bd c7             	bsr    %edi,%eax
f0102913:	83 f0 1f             	xor    $0x1f,%eax
f0102916:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102919:	0f 84 a1 00 00 00    	je     f01029c0 <__umoddi3+0xf0>
f010291f:	89 f8                	mov    %edi,%eax
f0102921:	8a 4d ec             	mov    -0x14(%ebp),%cl
f0102924:	d3 e0                	shl    %cl,%eax
f0102926:	bf 20 00 00 00       	mov    $0x20,%edi
f010292b:	2b 7d ec             	sub    -0x14(%ebp),%edi
f010292e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102931:	89 f9                	mov    %edi,%ecx
f0102933:	d3 ea                	shr    %cl,%edx
f0102935:	09 c2                	or     %eax,%edx
f0102937:	89 55 f0             	mov    %edx,-0x10(%ebp)
f010293a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010293d:	8a 4d ec             	mov    -0x14(%ebp),%cl
f0102940:	d3 e0                	shl    %cl,%eax
f0102942:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0102945:	89 f2                	mov    %esi,%edx
f0102947:	d3 e2                	shl    %cl,%edx
f0102949:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010294c:	d3 e0                	shl    %cl,%eax
f010294e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102951:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102954:	89 f9                	mov    %edi,%ecx
f0102956:	d3 e8                	shr    %cl,%eax
f0102958:	09 d0                	or     %edx,%eax
f010295a:	d3 ee                	shr    %cl,%esi
f010295c:	89 f2                	mov    %esi,%edx
f010295e:	f7 75 f0             	divl   -0x10(%ebp)
f0102961:	89 d6                	mov    %edx,%esi
f0102963:	f7 65 f4             	mull   -0xc(%ebp)
f0102966:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102969:	89 c1                	mov    %eax,%ecx
f010296b:	39 d6                	cmp    %edx,%esi
f010296d:	72 71                	jb     f01029e0 <__umoddi3+0x110>
f010296f:	74 7f                	je     f01029f0 <__umoddi3+0x120>
f0102971:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102974:	29 c8                	sub    %ecx,%eax
f0102976:	19 d6                	sbb    %edx,%esi
f0102978:	8a 4d ec             	mov    -0x14(%ebp),%cl
f010297b:	d3 e8                	shr    %cl,%eax
f010297d:	89 f2                	mov    %esi,%edx
f010297f:	89 f9                	mov    %edi,%ecx
f0102981:	d3 e2                	shl    %cl,%edx
f0102983:	09 d0                	or     %edx,%eax
f0102985:	89 f2                	mov    %esi,%edx
f0102987:	8a 4d ec             	mov    -0x14(%ebp),%cl
f010298a:	d3 ea                	shr    %cl,%edx
f010298c:	83 c4 20             	add    $0x20,%esp
f010298f:	5e                   	pop    %esi
f0102990:	5f                   	pop    %edi
f0102991:	c9                   	leave  
f0102992:	c3                   	ret    
f0102993:	90                   	nop
f0102994:	85 c9                	test   %ecx,%ecx
f0102996:	75 0b                	jne    f01029a3 <__umoddi3+0xd3>
f0102998:	b8 01 00 00 00       	mov    $0x1,%eax
f010299d:	31 d2                	xor    %edx,%edx
f010299f:	f7 f1                	div    %ecx
f01029a1:	89 c1                	mov    %eax,%ecx
f01029a3:	89 f0                	mov    %esi,%eax
f01029a5:	31 d2                	xor    %edx,%edx
f01029a7:	f7 f1                	div    %ecx
f01029a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01029ac:	f7 f1                	div    %ecx
f01029ae:	e9 4a ff ff ff       	jmp    f01028fd <__umoddi3+0x2d>
f01029b3:	90                   	nop
f01029b4:	89 f2                	mov    %esi,%edx
f01029b6:	83 c4 20             	add    $0x20,%esp
f01029b9:	5e                   	pop    %esi
f01029ba:	5f                   	pop    %edi
f01029bb:	c9                   	leave  
f01029bc:	c3                   	ret    
f01029bd:	8d 76 00             	lea    0x0(%esi),%esi
f01029c0:	39 f7                	cmp    %esi,%edi
f01029c2:	72 05                	jb     f01029c9 <__umoddi3+0xf9>
f01029c4:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f01029c7:	77 0c                	ja     f01029d5 <__umoddi3+0x105>
f01029c9:	89 f2                	mov    %esi,%edx
f01029cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01029ce:	29 c8                	sub    %ecx,%eax
f01029d0:	19 fa                	sbb    %edi,%edx
f01029d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01029d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01029d8:	83 c4 20             	add    $0x20,%esp
f01029db:	5e                   	pop    %esi
f01029dc:	5f                   	pop    %edi
f01029dd:	c9                   	leave  
f01029de:	c3                   	ret    
f01029df:	90                   	nop
f01029e0:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01029e3:	89 c1                	mov    %eax,%ecx
f01029e5:	2b 4d f4             	sub    -0xc(%ebp),%ecx
f01029e8:	1b 55 f0             	sbb    -0x10(%ebp),%edx
f01029eb:	eb 84                	jmp    f0102971 <__umoddi3+0xa1>
f01029ed:	8d 76 00             	lea    0x0(%esi),%esi
f01029f0:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01029f3:	72 eb                	jb     f01029e0 <__umoddi3+0x110>
f01029f5:	89 f2                	mov    %esi,%edx
f01029f7:	e9 75 ff ff ff       	jmp    f0102971 <__umoddi3+0xa1>
