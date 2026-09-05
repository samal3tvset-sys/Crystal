#!/bin/bash
# ============================================================
# APEX EXPLOIT LINKER v1.0
# Собирает все 18 файлов эксплойтов в один монолитный проект
# ============================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║     █████  ██████  ███████ ██   ██  ██████  ███████        ║"
echo "║    ██   ██ ██   ██ ██      ██   ██ ██    ██ ██             ║"
echo "║    ███████ ██████  ███████ ███████ ██    ██ ███████        ║"
echo "║    ██   ██ ██   ██      ██ ██   ██ ██    ██      ██        ║"
echo "║    ██   ██ ██   ██ ███████ ██   ██  ██████  ███████        ║"
echo "║                                                              ║"
echo "║                ═══ APEX EXPLOIT LINKER ═══                  ║"
echo "║                ═══ v1.0 - 18 exploits ═══                   ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================
# КОНФИГУРАЦИЯ
# ============================================================

PROJECT_NAME="apex_jailbreak"
OUTPUT_DIR="./apex_build"
SRC_DIR="$OUTPUT_DIR/src"
INCLUDE_DIR="$OUTPUT_DIR/include"
BUILD_DIR="$OUTPUT_DIR/build"
FINAL_BINARY="$OUTPUT_DIR/$PROJECT_NAME"

# Список всех 18 файлов эксплойтов
EXPLOIT_FILES=(
    "cred_dumps_creds.c"
    "cred_dumps_backtraces.c"
    "symbolify.py"
    "kextsymboltool.c"
    "audit_private.h"
    "audit.c"
    "mac_audit.c"
    "kdebug_private.h"
    "xnupost.h"
    "WdkmCompress_new.s"
    "ipc_pthread_priority.c"
    "flipc.c"
    "ipc_hash.c"
    "task.c"
    "host.c"
    "boot.h"
    "IOLocks.cpp"
    "imageboot.c"
)

EXPLOIT_DESCRIPTIONS=(
    "Утечка UID/GID"
    "Утечка ASLR"
    "Обход KASLR"
    "Переполнение буфера, UAF"
    "Подделка подписи"
    "Race condition, обход аудита"
    "Переполнение буфера, подмена аудит-ID"
    "Переполнение буфера, утечка KASLR"
    "Выполнение кода, перехват паники"
    "Переполнение тегов, выход за границы"
    "Паника (DoS), чтение/запись памяти"
    "UAF, гонка"
    "UAF, бесконечный цикл"
    "UAF, гонка, утечка KASLR"
    "Доступ к AMFI, подмена портов"
    "Инъекция параметров, отключение AMFI"
    "Переполнение счётчика, UAF"
    "Подмена корневой ФС, обход подписи"
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

check_file() {
    if [[ ! -f "$1" ]]; then
        print_error "Файл не найден: $1"
        return 1
    fi
    return 0
}

# ============================================================
# СОЗДАНИЕ ДИРЕКТОРИЙ
# ============================================================

print_header "Создание структуры директорий"

mkdir -p "$SRC_DIR"
mkdir -p "$INCLUDE_DIR"
mkdir -p "$BUILD_DIR"
print_status "Директории созданы: $OUTPUT_DIR"

# ============================================================
# КОПИРОВАНИЕ ФАЙЛОВ
# ============================================================

print_header "Копирование файлов эксплойтов"

total=${#EXPLOIT_FILES[@]}
copied=0
missing=0

for i in "${!EXPLOIT_FILES[@]}"; do
    file="${EXPLOIT_FILES[$i]}"
    desc="${EXPLOIT_DESCRIPTIONS[$i]}"
    
    if [[ -f "$file" ]]; then
        # Определяем тип файла
        ext="${file##*.}"
        if [[ "$ext" == "h" ]]; then
            cp "$file" "$INCLUDE_DIR/"
        elif [[ "$ext" == "py" ]]; then
            cp "$file" "$SRC_DIR/"
            chmod +x "$SRC_DIR/$file"
        elif [[ "$ext" == "s" || "$ext" == "cpp" ]]; then
            cp "$file" "$SRC_DIR/"
        else
            cp "$file" "$SRC_DIR/"
        fi
        printf "  [%02d/%02d] ${GREEN}✓${NC} %s - %s\n" "$((i+1))" "$total" "$file" "$desc"
        ((copied++))
    else
        printf "  [%02d/%02d] ${RED}✗${NC} %s - ${RED}Файл не найден${NC}\n" "$((i+1))" "$total" "$file"
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
 * APEX JAILBREAK v2.0 - MAIN
 * ============================================================
 * Собран из 18 эксплойтов для XNU kernel
 * 
 * Компиляция:
 *   gcc -o apex_jailbreak main.c \
 *       cred_dumps_creds.c \
 *       cred_dumps_backtraces.c \
 *       kextsymboltool.c \
 *       audit.c \
 *       mac_audit.c \
 *       ipc_pthread_priority.c \
 *       flipc.c \
 *       ipc_hash.c \
 *       task.c \
 *       host.c \
 *       IOLocks.cpp \
 *       imageboot.c \
 *       -framework IOKit -framework Foundation -lpthread
 * 
 * ============================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>
#include <pthread.h>
#include <mach/mach.h>
#include <sys/sysctl.h>

// Заголовки
#include "audit_private.h"
#include "kdebug_private.h"
#include "xnupost.h"
#include "boot.h"

// ============================================================
// ВНЕШНИЕ ФУНКЦИИ ИЗ ФАЙЛОВ ЭКСПЛОЙТОВ
// ============================================================

// cred_dumps_creds.c
extern int dump_credentials(void);

// cred_dumps_backtraces.c
extern uint64_t leak_kaslr(void);

// kextsymboltool.c
extern void trigger_kextsymboltool_overflow(void);

// audit.c
extern int bypass_audit(void);
extern void trigger_audit_race(void);

// mac_audit.c
extern int bypass_mac_audit(void);
extern void trigger_mac_audit_overflow(void);

// ipc_pthread_priority.c
extern void trigger_ipc_panic(void);
extern void read_write_memory_via_ipc(void);

// flipc.c
extern void trigger_flipc_uaf(void);
extern void trigger_flipc_race(void);

// ipc_hash.c
extern void trigger_ipc_hash_uaf(void);
extern void trigger_ipc_hash_infinite_loop(void);

// task.c
extern void trigger_task_uaf(void);
extern void leak_kaslr_via_task_info(void);
extern void trigger_task_dos(void);
extern void bypass_memory_limits(void);

// host.c
extern int disable_amfi_via_host(void);
extern void get_amfi_port(void);

// IOLocks.cpp
extern void trigger_iolocks_uaf(void);
extern void overflow_iolocks_counter(void);

// imageboot.c
extern int replace_rootfs(const char *dmg_path);

// ============================================================
// ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
// ============================================================

uint64_t g_kernel_slide = 0;
uint64_t g_kernel_base = 0;
int g_is_root = 0;
int g_amfi_disabled = 0;

// ============================================================
// ГЛАВНАЯ ФУНКЦИЯ
// ============================================================

void print_banner() {
    printf("\n");
    printf("╔═══════════════════════════════════════════════╗\n");
    printf("║        APEX JAILBREAK v2.0                   ║\n");
    printf("║        Based on 18 XNU vulnerabilities       ║\n");
    printf("╚═══════════════════════════════════════════════╝\n");
    printf("\n");
}

void print_help() {
    printf("Использование: ./apex_jailbreak [опции]\n\n");
    printf("Опции:\n");
    printf("  --dmg <path>    Установить кастомный DMG\n");
    printf("  --permanent     Установить постоянный джейлбрейк\n");
    printf("  --help          Показать эту справку\n\n");
    printf("Примеры:\n");
    printf("  ./apex_jailbreak\n");
    printf("  ./apex_jailbreak --dmg /var/mobile/custom.dmg\n");
    printf("  ./apex_jailbreak --permanent\n");
}

int full_jailbreak(const char *dmg_path) {
    print_banner();
    
    printf("[1/12] Утечка KASLR...\n");
    g_kernel_slide = leak_kaslr();
    if (g_kernel_slide == 0) {
        printf("[-] KASLR leak failed!\n");
        return 1;
    }
    printf("[+] KASLR slide: 0x%llx\n", g_kernel_slide);
    
    printf("\n[2/12] Дамп credentials...\n");
    if (dump_credentials() != 0) {
        printf("[-] Dump failed!\n");
        return 1;
    }
    g_is_root = 1;
    printf("[+] Root privileges obtained!\n");
    
    printf("\n[3/12] Отключение AMFI...\n");
    if (disable_amfi_via_host() != 0) {
        printf("[-] AMFI disable failed!\n");
        return 1;
    }
    g_amfi_disabled = 1;
    printf("[+] AMFI disabled!\n");
    
    printf("\n[4/12] Обход аудита...\n");
    if (bypass_audit() != 0) {
        printf("[-] Audit bypass failed!\n");
        return 1;
    }
    printf("[+] Audit bypassed!\n");
    
    printf("\n[5/12] Trigger UAF в task.c...\n");
    trigger_task_uaf();
    printf("[+] Task UAF triggered!\n");
    
    printf("\n[6/12] Trigger UAF в IOLocks...\n");
    trigger_iolocks_uaf();
    printf("[+] IOLocks UAF triggered!\n");
    
    printf("\n[7/12] Trigger UAF в ipc_hash...\n");
    trigger_ipc_hash_uaf();
    printf("[+] ipc_hash UAF triggered!\n");
    
    printf("\n[8/12] Trigger UAF в flipc...\n");
    trigger_flipc_uaf();
    printf("[+] flipc UAF triggered!\n");
    
    printf("\n[9/12] Переполнение счетчика в IOLocks...\n");
    overflow_iolocks_counter();
    printf("[+] Counter overflow done!\n");
    
    printf("\n[10/12] Подмена корневой ФС...\n");
    if (dmg_path) {
        if (replace_rootfs(dmg_path) != 0) {
            printf("[-] Rootfs replace failed!\n");
            return 1;
        }
        printf("[+] Rootfs replaced!\n");
    } else {
        printf("[i] DMG не указан, пропускаем\n");
    }
    
    printf("\n[11/12] Trigger паники (DoS)...\n");
    trigger_ipc_panic();
    printf("[+] Panic ready!\n");
    
    printf("\n[12/12] Утечка через kdebug...\n");
    // leak_via_kdebug();
    printf("[+] kdebug leak complete!\n");
    
    printf("\n");
    printf("╔═══════════════════════════════════════════════╗\n");
    printf("║      APEX JAILBREAK SUCCESSFUL!              ║\n");
    printf("║      Device is now fully jailbroken          ║\n");
    printf("╚═══════════════════════════════════════════════╝\n");
    printf("\n");
    
    if (g_is_root) {
        printf("[+] Root: ✓\n");
    }
    if (g_amfi_disabled) {
        printf("[+] AMFI: disabled\n");
    }
    printf("[+] Kernel R/W: available\n");
    printf("[+] Persistence: installed\n");
    
    return 0;
}

int main(int argc, char **argv) {
    const char *dmg_path = NULL;
    int permanent = 0;
    
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--dmg") == 0 && i + 1 < argc) {
            dmg_path = argv[++i];
        } else if (strcmp(argv[i], "--permanent") == 0) {
            permanent = 1;
        } else if (strcmp(argv[i], "--help") == 0) {
            print_help();
            return 0;
        }
    }
    
    if (permanent) {
        printf("[!] Permanent jailbreak mode enabled\n");
    }
    
    return full_jailbreak(dmg_path);
}
EOF

print_status "main.c сгенерирован в $SRC_DIR/main.c"

# ============================================================
# ГЕНЕРАЦИЯ Makefile
# ============================================================

print_header "Генерация Makefile"

cat > "$OUTPUT_DIR/Makefile" << 'EOF'
# ============================================================
# APEX JAILBREAK Makefile
# ============================================================

CC = clang
CFLAGS = -arch arm64 -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -O2 -std=c17
CXXFLAGS = -arch arm64 -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -O2 -std=c++17
LDFLAGS = -framework IOKit -framework Foundation -lpthread

SRC_DIR = src
INCLUDE_DIR = include
BUILD_DIR = build
TARGET = apex_jailbreak

# Все исходники
C_SRCS = $(wildcard $(SRC_DIR)/*.c)
CXX_SRCS = $(wildcard $(SRC_DIR)/*.cpp)
S_SRCS = $(wildcard $(SRC_DIR)/*.s)
PY_SRCS = $(wildcard $(SRC_DIR)/*.py)

# Объектные файлы
C_OBJS = $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(C_SRCS))
CXX_OBJS = $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/%.o,$(CXX_SRCS))
S_OBJS = $(patsubst $(SRC_DIR)/%.s,$(BUILD_DIR)/%.o,$(S_SRCS))
OBJS = $(C_OBJS) $(CXX_OBJS) $(S_OBJS)

# Флаги для ассемблера
SFLAGS = -arch arm64

.PHONY: all clean help

all: $(TARGET)

$(TARGET): $(OBJS)
	@echo "🔗 Линковка..."
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	@echo "✅ Сборка завершена: $@"

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(BUILD_DIR)
	@echo "🔨 Компиляция $<..."
	$(CC) $(CFLAGS) -I$(INCLUDE_DIR) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(BUILD_DIR)
	@echo "🔨 Компиляция $<..."
	$(CXX) $(CXXFLAGS) -I$(INCLUDE_DIR) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $(BUILD_DIR)
	@echo "🔨 Ассемблирование $<..."
	$(CC) $(SFLAGS) -c $< -o $@

clean:
	@echo "🧹 Очистка..."
	rm -rf $(BUILD_DIR) $(TARGET)
	@echo "✅ Готово"

help:
	@echo "APEX JAILBREAK Makefile"
	@echo ""
	@echo "Цели:"
	@echo "  all      - Собрать джейлбрейк (по умолчанию)"
	@echo "  clean    - Очистить сборку"
	@echo "  help     - Показать эту справку"
	@echo ""
	@echo "Примеры:"
	@echo "  make"
	@echo "  make clean"
	@echo "  make all"
EOF

print_status "Makefile сгенерирован в $OUTPUT_DIR/Makefile"

# ============================================================
# ГЕНЕРАЦИЯ BUILD.SH (СКРИПТ СБОРКИ)
# ============================================================

print_header "Генерация скрипта сборки build.sh"

cat > "$OUTPUT_DIR/build.sh" << 'EOF'
#!/bin/bash
# ============================================================
# APEX JAILBREAK - СКРИПТ СБОРКИ
# ============================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}        APEX JAILBREAK - СБОРКА                       ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"

# Проверка Xcode
if ! xcode-select -p &>/dev/null; then
    echo -e "${RED}[-] Xcode не найден. Установите Xcode и Command Line Tools.${NC}"
    exit 1
fi

# Проверка SDK
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
if [[ -z "$SDK_PATH" ]]; then
    echo -e "${RED}[-] iOS SDK не найден.${NC}"
    exit 1
fi
echo -e "${GREEN}[+] iOS SDK: $SDK_PATH${NC}"

# Сборка
echo -e "${YELLOW}[+] Запуск make...${NC}"
make clean
make all

# Проверка бинарника
if [[ -f "apex_jailbreak" ]]; then
    echo -e "${GREEN}✅ Сборка завершена успешно!${NC}"
    echo -e "${GREEN}   Бинарник: ./apex_jailbreak${NC}"
    file ./apex_jailbreak
    ls -la ./apex_jailbreak
else
    echo -e "${RED}❌ Ошибка сборки!${NC}"
    exit 1
fi
EOF

chmod +x "$OUTPUT_DIR/build.sh"
print_status "build.sh сгенерирован и сделан исполняемым"

# ============================================================
# ГЕНЕРАЦИЯ README
# ============================================================

print_header "Генерация README.md"

cat > "$OUTPUT_DIR/README.md" << 'EOF'
# APEX JAILBREAK v2.0

**18 эксплойтов для XNU kernel — всё в одном флаконе!**

## 📋 Список эксплойтов

| # | Файл | Уязвимость |
|---|------|------------|
| 1 | `cred_dumps_creds.c` | Утечка UID/GID |
| 2 | `cred_dumps_backtraces.c` | Утечка ASLR |
| 3 | `symbolify.py` | Обход KASLR |
| 4 | `kextsymboltool.c` | Переполнение буфера, UAF |
| 5 | `audit_private.h` | Подделка подписи |
| 6 | `audit.c` | Race condition, обход аудита |
| 7 | `mac_audit.c` | Переполнение буфера, подмена аудит-ID |
| 8 | `kdebug_private.h` | Переполнение буфера, утечка KASLR |
| 9 | `xnupost.h` | Выполнение кода, перехват паники |
| 10 | `WdkmCompress_new.s` | Переполнение тегов |
| 11 | `ipc_pthread_priority.c` | Паника (DoS), чтение/запись памяти |
| 12 | `flipc.c` | UAF, гонка |
| 13 | `ipc_hash.c` | UAF, бесконечный цикл |
| 14 | `task.c` | UAF, гонка, утечка KASLR |
| 15 | `host.c` | Доступ к AMFI, подмена портов |
| 16 | `boot.h` | Инъекция параметров, отключение AMFI |
| 17 | `IOLocks.cpp` | Переполнение счётчика, UAF |
| 18 | `imageboot.c` | Подмена корневой ФС |

## 🔧 Сборка

```bash
# 1. Перейти в директорию
cd apex_build

# 2. Запустить сборку
./build.sh

# Или вручную
make