PROJECT = blink
# SRCS: all source files from src directory
SRCS = $(wildcard src/*.c) \
		$(wildcard libs/*.c) 
		
# CONTEXT_SWITCH = libs/context_switch.s

# S_SRCS =  $(wildcard aeabi-cortexm0/*.S)
# S_SRCS = aeabi-cortexm0/uread4.S aeabi-cortexm0/memmove4.S 
# \



PRE_OBJS = $(wildcard precompiled/*.o)

LIB_ASSM = $(wildcard assembly/*.a)

S_ASSM = $(addprefix -l,$(LIB_ASSM)))

OBJ = obj/

# OBJS: list of object files
OBJS = $(addprefix $(OBJ),$(notdir $(SRCS:.c=.o)))

S_OBJS = $(addprefix $(assembly/made/),$(notdir $(S_SRCS:.S=.o)))

C_SWITCH_OBJS = $(addprefix $(OBJ),$(notdir $(CONTEXT_SWITCH:.s=.o)))


# ! NOTE ARM_TOOLCHAIN_VERSION and ARM_TOOLCHAIN_PATH are set in .vscode/tasks.json envs variable
#Flag points to the INC folder containing header files
INC = -Ilibinc/Library/Bluetooth_LE/library/static_stack \
	-Ilibinc/Library/BLE_Application/Profile_Central/includes \
	-Ilibinc/Library/Bluetooth_LE/library/static_stack \
	-I./inc \
	-Ilibinc/Library/hal/inc \
	-Ilibinc/Library/BlueNRG1_Periph_Driver/inc \
	-Ilibinc/Library/Bluetooth_LE/inc \
	-Ilibinc/Library/CMSIS/Include \
	-Ilibinc/Library/CMSIS/Device/ST/BlueNRG1/Include \
	-Ilibinc/Library/SDK_Eval_BlueNRG1/inc \
	-Ilibinc/Library/BLE_Application/OTA/inc \
	-Ilibinc/Library/BLE_Application/Utils/inc \
	-Ilibinc/Library/BLE_Application/layers_inc \
	-I${ARM_TOOLCHAIN_PATH}/../lib/gcc/arm-none-eabi/${ARM_TOOLCHAIN_VERSION}/include \
	-I${ARM_TOOLCHAIN_PATH}/../lib/gcc/arm-none-eabi/${ARM_TOOLCHAIN_VERSION}/include-fixed \
	-I${ARM_TOOLCHAIN_PATH}/../arm-none-eabi/include \
	-I${ARM_TOOLCHAIN_PATH}/../arm-none-eabi/include/machine \
	-I${ARM_TOOLCHAIN_PATH}/../arm-none-eabi/include/newlib-nano \
	-I${ARM_TOOLCHAIN_PATH}/../arm-none-eabi/include/sys

# LD_SCRIPT: linker script
LD_SCRIPT=./BlueNRG1.ld


#UTILITY VARIABLES
CC = arm-none-eabi-gcc #compiler
LD = arm-none-eabi-gcc#arm-none-eabi-ld #linker
AS = arm-none-eabi-as
OBJCOPY = arm-none-eabi-objcopy #final executable builder
# FLASHER = lm4flash #flashing utility
RM      = rmdir /s
# MKDIR   = @mkdir -p $(@D) #creates folders if not present

DEFINES = -DBLUENRG1_DEVICE -DDEBUG -DHS_SPEED_XTAL=HS_SPEED_XTAL_16MHZ -DLS_SOURCE=LS_SOURCE_INTERNAL_RO -DSMPS_INDUCTOR=SMPS_INDUCTOR_4_7uH -DUSER_BUTTON=BUTTON_1 -Dmcpu=cortexm0

#GCC FLAGS
CFLAGS = -mthumb -mcpu=cortex-m0 $(DEFINES) -specs=nano.specs -mfloat-abi=soft#-specs=nano.specs 
CFLAGS +=  -MD -std=c99 -c -fdata-sections -ffunction-sections  -Og -fdata-sections -g -fstack-usage -Wall

ASFLAGS = -Wall -ggdb -mthumb

SFLAGS =  -mthumb -mcpu=cortex-m0 -g -Wa,--no-warn -x assembler-with-cpp # -specs=nano.specs

# LDFLAGS = -T$(LD_SCRIPT) -g -mthumb  -nostartfiles -mcpu=cortex-m0 -Wl,--gc-sections -Wl,--defsym=malloc_getpagesize_P=0x80 -nodefaultlibs -static -L./assembly  -Wl,--start-group -lc -lm -Wl,--end-group -lbluenrg1_stack -lcrypto -specs=nano.specs
# BETTER LDFLAGS = -T$(LD_SCRIPT) -g  -nostartfiles --gc-sections --defsym=malloc_getpagesize_P=0x80 -static -L./assembly -nodefaultlibs "-Map=BLE_Beacon.map" --cref --start-group -lc -lgcc -lm --end-group -lbluenrg1_stack -lcrypto #-specs=nano.specs
# LDFLAGS = -T$(LD_SCRIPT) -g  --gc-sections --defsym=malloc_getpagesize_P=0x80  -L./assembly -nodefaultlibs "-Map=BLE_Beacon.map" --cref --start-group -lc -lgcc -lm --end-group -lbluenrg1_stack -lcrypto
LDFLAGS = -T$(LD_SCRIPT) -mthumb -mfloat-abi=soft -specs=nano.specs -nostartfiles -mcpu=cortex-m0 -Wl,--gc-sections -Wl,--defsym=malloc_getpagesize_P=0x80 -nodefaultlibs "-Wl,-Map=BLE_Beacon.map" -static -Wl,--cref  -static -L./assembly  -Wl,--start-group -lc -lm -Wl,--end-group -lbluenrg1_stack -lcrypto



# Rules to build bin
# all: bin/$(PROJECT).bin
all: bin/$(PROJECT).elf

$(OBJ)%.o: libs/%.s
	$(CC) $(SFLAGS) -o $@ $^ 
# assembly
$(assembly/made/)%.o: aeabi-cortexm0/%.S
	$(AS) $(ASFLAGS) -c $< -o $@

$(OBJ)%.o: src/%.c
	$(CC) -o $@ $^ $(INC) $(CFLAGS)

$(OBJ)%.o: libs/%.c
	$(CC) -o $@ $^ $(INC) $(CFLAGS)

bin/$(PROJECT).elf: $(OBJS) $(S_OBJS) $(PRE_OBJS) $(C_SWITCH_OBJS)
	$(LD) -o $@ $^ $(LDFLAGS)
	
bin/$(PROJECT).bin: bin/$(PROJECT).elf
	$(OBJCOPY) -O binary $< $@

# #Flashes bin to TM4C
# flash:
# 	$(FLASHER) -S $(DEV) bin/$(PROJECT).bin

#remove object and bin files
clean:
	-$(RM) obj
	-$(RM) bin

.PHONY: all clean