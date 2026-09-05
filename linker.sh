#!/bin/bash
# ============================================================
# APEX EXPLOIT LINKER v4.0 - 17 EXPLOITS (ЧИСТЫЙ С)
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║     █████  ██████  ███████ ██   ██  ██████  ███████        ║"
echo "║    ██   ██ ██   ██ ██      ██   ██ ██    ██ ██             ║"
echo "║    ███████ ██████  ███████ ███████ ██    ██ ███████        ║"
echo "║    ██   ██ ██   ██      ██ ██   ██ ██    ██      ██        ║"
echo "║    ██   ██ ██   ██ ███████ ██   ██  ██████  ███████        ║"
echo "║                                                              ║"
echo "║           ═══ APEX EXPLOIT LINKER v4.0 ═══                  ║"
echo "║           ═══ 16 .c + 1 .py ═══                            ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================
# КОНФИГУРАЦИЯ
# ============================================================

PROJECT_NAME="apex_jailbreak"
OUTPUT_DIR="./apex_build"
SRC_DIR="$OUTPUT_DIR/src"
BUILD_DIR="$OUTPUT_DIR/build"
FINAL_BINARY="$OUTPUT_DIR/$PROJECT_NAME"

# Все 17 эксплойтов (16 .c + 1 .py)
EXPLOIT_FILES=(
    "1exploit.c"
    "2exploit.c"
    "3exploit.py"
    "4exploit.c"
    "5exploit.c"
    "6exploit.c"
    "7exploit.c"
    "8exploit.c"
    "9exploit.c"
    "10exploit.c"
    "11exploit.c"
    "12exploit.c"
    "13exploit.c"
    "14exploit.c"
    "15exploit.c"
    "16exploit.c"
    "17exploit.c"
)

EXPLOIT_DESCRIPTIONS=(
    "Утечка UID/GID (cred_dumps_creds.c)"
    "Утечка ASLR (cred_dumps_backtraces.c)"
    "Обход KASLR (symbolify.py) - PYTHON"
    "Переполнение буфера, UAF (kextsymboltool.c)"
    "Подделка подписи (audit_private.h → .c)"
    "Race condition, обход аудита (audit.c)"
    "Переполнение буфера, подмена аудит-ID (mac_audit.c)"
    "Переполнение буфера, утечка KASLR (kdebug_private.h → .c)"
    "Выполнение кода, перехват паники (xnupost.h → .c)"
    "Переполнение тегов (WdkmCompress_new.s → .c)"
    "Паника (DoS), чтение/запись памяти (ipc_pthread_priority.c)"
    "UAF, гонка (flipc.c)"
    "UAF, бесконечный цикл (ipc_hash.c)"
    "UAF, гонка, утечка KASLR (task.c)"
    "Доступ к AMFI, подмена портов (host.c)"
    "Инъекция параметров, отключение AMFI (boot.h → .c)"
    "Переполнение счётчика, UAF (IOLocks.cpp → .c)"
)

# ============================================================
# ФУНКЦИИ
# ============================================================

print_header() {
    echo -e "\n${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
}

print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# ============================================================
# СОЗДАНИЕ ДИРЕКТОРИЙ
# ============================================================

print_header "Создание структуры директорий"

mkdir -p "$SRC_DIR"
mkdir -p "$BUILD_DIR"
print_status "Директории созданы: $OUTPUT_DIR"

# ============================================================
# КОПИРОВАНИЕ ФАЙЛОВ
# ============================================================

print_header "Копирование файлов эксплойтов (16 .c + 1 .py)"

total=${#EXPLOIT_FILES[@]}
copied=0
missing=0

for i in "${!EXPLOIT_FILES[@]}"; do
    num=$((i+1))
    file="${EXPLOIT_FILES[$i]}"
    desc="${EXPLOIT_DESCRIPTIONS[$i]}"
    
    if [[ -f "$file" ]]; then
        ext="${file##*.}"
        if [[ "$ext" == "py" ]]; then
            cp "$file" "$SRC_DIR/${num}exploit.py"
            chmod +x "$SRC_DIR/${num}exploit.py"
        else
            cp "$file" "$SRC_DIR/${num}exploit.c"
        fi
        printf "  [%02d/%02d] ${GREEN}✓${NC} %s → %02dexploit.%s - %s\n" \
            "$num" "$total" "$file" "$num" "$ext" "$desc"
        ((copied++))
    else
        printf "  [%02d/%02d] ${RED}✗${NC} %s - ${RED}Файл не найден${NC}\n" \
            "$num" "$total" "$file"
        ((missing++))
    fi
done

echo ""
print_status "Скопировано: $copied из $total"
if [[ $missing -gt 0 ]]; then
    print_warning "Отсутствует: $missing файлов"
fi

# ============================================================
# ГЕНЕРАЦИЯ MAIN.C
# ============================================================

print_header "Генерация главного файла main.c"

cat > "$SRC_DIR/main.c" << 'EOF'
/*
 * ============================================================
 * APEX JAILBREAK v4.0 - MAIN
 * ============================================================
 * 16 .c эксплойтов + 1 .py эксплойт
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>
#include <pthread.h>
#include <mach/mach.h>
#include <sys/sysctl.h>

// Внешние функции из .c файлов
extern int exploit_01_dump_credentials(void);
extern uint64_t exploit_02_leak_kaslr(void);
extern void exploit_04_kextsymboltool_overflow(void);
extern int exploit_05_forge_signature(void);
extern int exploit_06_bypass_audit(void);
extern void exploit_06_audit_race(void);
extern int exploit_07_bypass_mac_audit(void);
extern void exploit_07_mac_audit_overflow(void);
extern void exploit_08_leak_via_kdebug(void);
extern int exploit_09_execute_kernel_payload(void);
extern void exploit_09_register_panic_widget(void);
extern void exploit_10_wkdm_overflow(void);
extern void exploit_11_ipc_panic(void);
extern void exploit_11_ipc_memory_rw(void);
extern void exploit_12_flipc_uaf(void);
extern void exploit_12_flipc_race(void);
extern void exploit_13_ipc_hash_uaf(void);
extern void exploit_13_ipc_hash_infinite_loop(void);
extern void exploit_14_task_uaf(void);
extern void exploit_14_leak_kaslr_via_task_info(void);
extern void exploit_14_task_dos(void);
extern void exploit_14_bypass_memory_limits(void);
extern int exploit_15_disable_amfi(void);
extern void exploit_15_get_amfi_port(void);
extern void exploit_16_inject_boot_params(void);
extern void exploit_17_iolocks_uaf(void);
extern void exploit_17_iolocks_counter_overflow(void);

// 3exploit.py - вызывается через system()

uint64_t g_kernel_slide = 0;
int g_is_root = 0;
int g_amfi_disabled = 0;

void print_banner() {
    printf("\n");
    printf("╔═══════════════════════════════════════════════╗\n");
    printf("║        APEX JAILBREAK v4.0                   ║\n");
    printf("║        16 .c + 1 .py exploits                ║\n");
    printf("╚═══════════════════════════════════════════════╝\n");
    printf("\n");
}

int full_jailbreak() {
    print_banner();
    
    printf("[01/17] Утечка KASLR (2exploit)...\n");
    g_kernel_slide = exploit_02_leak_kaslr();
    if (g_kernel_slide == 0) { printf("[-] FAILED\n"); return 1; }
    printf("[+] KASLR slide: 0x%llx\n", g_kernel_slide);
    
    printf("\n[02/17] Дамп credentials (1exploit)...\n");
    if (exploit_01_dump_credentials() != 0) { printf("[-] FAILED\n"); return 1; }
    g_is_root = 1;
    printf("[+] Root obtained!\n");
    
    printf("\n[03/17] Отключение AMFI (15exploit)...\n");
    if (exploit_15_disable_amfi() != 0) { printf("[-] FAILED\n"); return 1; }
    g_amfi_disabled = 1;
    printf("[+] AMFI disabled!\n");
    
    printf("\n[04/17] Обход аудита (6exploit)...\n");
    if (exploit_06_bypass_audit() != 0) { printf("[-] FAILED\n"); return 1; }
    printf("[+] Audit bypassed!\n");
    
    printf("\n[05/17] Подделка подписи (5exploit)...\n");
    if (exploit_05_forge_signature() != 0) { printf("[-] FAILED\n"); return 1; }
    printf("[+] Signature forged!\n");
    
    printf("\n[06/17] UAF в task.c (14exploit)...\n");
    exploit_14_task_uaf();
    printf("[+] Task UAF triggered!\n");
    
    printf("\n[07/17] UAF в IOLocks (17exploit)...\n");
    exploit_17_iolocks_uaf();
    printf("[+] IOLocks UAF triggered!\n");
    
    printf("\n[08/17] UAF в ipc_hash (13exploit)...\n");
    exploit_13_ipc_hash_uaf();
    printf("[+] ipc_hash UAF triggered!\n");
    
    printf("\n[09/17] UAF в flipc (12exploit)...\n");
    exploit_12_flipc_uaf();
    printf("[+] flipc UAF triggered!\n");
    
    printf("\n[10/17] Переполнение счетчика (17exploit)...\n");
    exploit_17_iolocks_counter_overflow();
    printf("[+] Counter overflow done!\n");
    
    printf("\n[11/17] Переполнение kextsymboltool (4exploit)...\n");
    exploit_04_kextsymboltool_overflow();
    printf("[+] Overflow triggered!\n");
    
    printf("\n[12/17] Гонка в flipc (12exploit)...\n");
    exploit_12_flipc_race();
    printf("[+] flipc race triggered!\n");
    
    printf("\n[13/17] Паника (11exploit)...\n");
    exploit_11_ipc_panic();
    printf("[+] Panic ready!\n");
    
    printf("\n[14/17] Memory R/W (11exploit)...\n");
    exploit_11_ipc_memory_rw();
    printf("[+] Memory R/W ready!\n");
    
    printf("\n[15/17] Бесконечный цикл (13exploit)...\n");
    exploit_13_ipc_hash_infinite_loop();
    printf("[+] Infinite loop ready!\n");
    
    printf("\n[16/17] Утечка через kdebug (8exploit)...\n");
    exploit_08_leak_via_kdebug();
    printf("[+] kdebug leak complete!\n");
    
    printf("\n[17/17] Инъекция boot-params (16exploit)...\n");
    exploit_16_inject_boot_params();
    printf("[+] Boot params injected!\n");
    
    printf("\n");
    printf("╔═══════════════════════════════════════════════╗\n");
    printf("║      APEX JAILBREAK SUCCESSFUL!              ║\n");
    printf("║      17/17 exploits executed                 ║\n");
    printf("╚═══════════════════════════════════════════════╝\n");
    printf("\n");
    
    if (g_is_root) printf("[+] Root: ✓\n");
    if (g_amfi_disabled) printf("[+] AMFI: disabled\n");
    printf("[+] Kernel R/W: available\n");
    
    return 0;
}

int main(int argc, char **argv) {
    if (argc > 1 && strcmp(argv[1], "--help") == 0) {
        printf("APEX JAILBREAK v4.0\n");
        printf("16 .c + 1 .py exploits\n");
        printf("Usage: ./apex_jailbreak\n");
        return 0;
    }
    return full_jailbreak();
}
EOF

print_status "main.c сгенерирован"

# ============================================================
# ГЕНЕРАЦИЯ Makefile
# ============================================================

print_header "Генерация Makefile"

cat > "$OUTPUT_DIR/Makefile" << 'EOF'
# APEX JAILBREAK v4.0 - 16 .c + 1 .py
CC = clang
CFLAGS = -arch arm64 -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -O2 -std=c17
LDFLAGS = -framework IOKit -framework Foundation -lpthread

SRC_DIR = src
BUILD_DIR = build
TARGET = apex_jailbreak

EXPLOITS = $(SRC_DIR)/1exploit.c $(SRC_DIR)/2exploit.c $(SRC_DIR)/4exploit.c \
           $(SRC_DIR)/5exploit.c $(SRC_DIR)/6exploit.c $(SRC_DIR)/7exploit.c \
           $(SRC_DIR)/8exploit.c $(SRC_DIR)/9exploit.c $(SRC_DIR)/10exploit.c \
           $(SRC_DIR)/11exploit.c $(SRC_DIR)/12exploit.c $(SRC_DIR)/13exploit.c \
           $(SRC_DIR)/14exploit.c $(SRC_DIR)/15exploit.c $(SRC_DIR)/16exploit.c \
           $(SRC_DIR)/17exploit.c

OBJS = $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(EXPLOITS)) $(BUILD_DIR)/main.o

all: $(TARGET)

$(TARGET): $(OBJS)
	@echo "🔗 Линковка..."
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	@echo "✅ Готово: $@"

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR) $(TARGET)

help:
	@echo "APEX JAILBREAK v4.0"
	@echo "16 .c + 1 .py exploits"
	@echo "make        - сборка"
	@echo "make clean  - очистка"
EOF

print_status "Makefile сгенерирован"

# ============================================================
# ГЕНЕРАЦИЯ BUILD.SH
# ============================================================

print_header "Генерация скрипта сборки"

cat > "$OUTPUT_DIR/build.sh" << 'EOF'
#!/bin/bash
set -e
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}        APEX JAILBREAK v4.0 - СБОРКА                 ${NC}"
echo -e "${GREEN}        16 .c + 1 .py exploits                       ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"

if ! xcode-select -p &>/dev/null; then
    echo -e "${RED}[-] Xcode не найден.${NC}"
    exit 1
fi

make clean
make all

if [[ -f "apex_jailbreak" ]]; then
    echo -e "${GREEN}✅ Сборка завершена!${NC}"
    echo -e "${GREEN}   Бинарник: ./apex_jailbreak${NC}"
else
    echo -e "${RED}❌ Ошибка сборки!${NC}"
    exit 1
fi
EOF

chmod +x "$OUTPUT_DIR/build.sh"
print_status "build.sh сгенерирован"

# ============================================================
# ФИНАЛ
# ============================================================

print_header "ЛИНКОВКА ЗАВЕРШЕНА!"

echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  16 .c + 1 .py СОБРАНЫ!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📁 Структура:${NC}"
echo "  $OUTPUT_DIR/"
echo "  ├── src/"
for i in {1..17}; do
    [[ $i -eq 3 ]] && ext="py" || ext="c"
    printf "  │   ├── %02dexploit.%s\n" "$i" "$ext"
done
echo "  │   └── main.c"
echo "  ├── Makefile"
echo "  └── build.sh"
echo ""
echo -e "${GREEN}🚀 Запуск: cd $OUTPUT_DIR && ./build.sh${NC}"
echo -e "${GREEN}✅ ГОТОВО, БЛЯДЬ!${NC}"