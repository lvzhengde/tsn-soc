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

def compare_files(file1, file2):
    try:
        with open(file1, 'r') as f1, open(file2, 'r') as f2:
            if f1.readlines() == f2.readlines():
                return True
            else:
                print("Failure：inconsistent with reference output")
                return False
    except FileNotFoundError:
        print("Failure：file does not exist")
        return False

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
            #run simulation
            tmp = elf.split('.')
            base_name = tmp[0]
            signature_name = base_name + '.signature.output'
            signature_path = work_dir+'/'+isa+'/signature/'+signature_name
            vvp_cmd = 'vvp -n '+'./riscv_sim.out '+'+dumpfile='+signature_path+' -fst'
            subprocess.call(vvp_cmd, shell=True)
            #compare with reference signature
            ref_name = base_name + '.reference_output'
            ref_dir  = '../../tc/riscv-compliance/riscv-test-suite/'+isa+'/references/'
            ref_path = ref_dir + ref_name
            result = compare_files(signature_path, ref_path)
            if result == True:
                print(isa+": " + base_name + ", Pass")
            else:
                print(isa+": " + base_name + ", Fail")


if __name__ == '__main__':
    main()
    sys.exit(0)
