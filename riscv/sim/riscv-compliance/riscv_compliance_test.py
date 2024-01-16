import os
import subprocess
import sys
import filecmp

def list_subdirectories(path):
    subdirectories = []
    for item in os.listdir(path):
        if os.path.isdir(os.path.join(path, item)):
            subdirectories.append(item)
    return subdirectories

def list_files(path):
    files = []
    for filename in os.listdir(path):
        if not os.path.isdir(os.path.join(path, filename)):
            files.append(filename)
    return files


def main():
    # clean temporary files
    subprocess.call("make clean", shell=True)

    # generate iverilog simulation executable and elf files
    subprocess.call("make", shell=True)

    # get ISA sub directories
    work_dir = 'work'
    isa_dirs = list_subdirectories(work_dir)
    #print(isa_dirs)

    # traverse all elf files in the ISA directory
    for isa in isa_dirs:
        elf_files = list_files(work_dir+'/'+isa+'/elf')
        #print(elf_files)
        for elf in elf_files:
            #generate bin file for TCM
            elf_path = work_dir+'/'+isa+'/elf/'+elf
            bin_path = 'tcm.bin'
            obj_copy = 'riscv32-unknown-elf-objcopy'
            bin_cmd = obj_copy + ' ' + elf_path + ' -O binary ' + bin_path
            subprocess.call(bin_cmd, shell=True)


if __name__ == '__main__':
    main()
    sys.exit(0)
