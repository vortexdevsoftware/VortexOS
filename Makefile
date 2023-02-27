# My sincere apologies to anyone reading this Makefile
# Packages: rust, qemu-system-x86, binutils, libc6-dev-i386, nasm, mtools, xorriso...

arch ?= x86_64
kernel := build/kernel-$(arch).bin
iso := build/vortex-os-$(arch).iso

linker_script := src/platform/$(arch)/link.ld
grub_cfg := src/platform/grub/.

asm_src := $(wildcard src/platform/$(arch)/*.asm)
asm_obj := $(patsubst src/platform/$(arch)/%.asm, build/$(arch)/obj/%.o, $(asm_src))

c_src := $(wildcard *.c)
c_obj := $(patsubst %.c, build/$(arch)/obj/%.o, $(c_src))

.PHONY: all clean run iso kernel

all: $(kernel) iso run

clean:
	@rm -r build || true
	@cargo clean

run: $(iso)
	@qemu-system-x86_64 -cdrom $(iso)


iso: $(iso)

$(iso): $(kernel) $(grub_cfg)
	@mkdir -p build/isofiles/boot/grub
	@cp build/kernel.bin build/isofiles/boot/kernel.bin
	@cp -a $(grub_cfg) build/isofiles/boot/grub
	@grub-mkrescue --output=$(iso) build/isofiles

kernel:
# Compile assembly
	@for file in src/platform/$(arch)/*.asm; do \
		nasm -f elf64 $$file -o build/$(arch)/obj/`basename $$file .asm`.o; \
	done
# Compile C source

# Compile rust source
	@cargo build
	@mkdir -p build/$(arch)/obj


$(kernel): kernel $(asm_obj)
# link, create kernel.bin
	@ld -n --gc-sections -T src/platform/$(arch)/link.ld -o build/kernel.bin \
		$(asm_obj) target/buildspec/debug/libvortex_os.a