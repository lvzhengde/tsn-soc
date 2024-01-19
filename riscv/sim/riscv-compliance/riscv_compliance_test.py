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

    # FIXME. unsupported instructions.
    # There is a bug in original I-MISALIGN_JMP-01.S file 
    # which lead to endless loop when misalign exception occurs
    unsupported_list = ['I-MISALIGN_JMP-01']

    # traverse all elf files in the ISA directory
    for isa in isa_dirs:
        elf_files = list_files(work_dir+'/'+isa+'/elf')
        #print(elf_files)

        total  = len(elf_files)
        passed = 0
        failed = 0
        unsupported = 0

        for elf in elf_files:
            #get instruction test base name
            tmp = elf.split('.')
            last_index = len(tmp) - 1
            sub_str = tmp[:last_index]
            base_name = ".".join(sub_str)

            #stop current instruction if unsupported
            if base_name in unsupported_list:
                unsupported += 1
                continue

            #generate bin file for TCM
            elf_path = work_dir+'/'+isa+'/elf/'+elf
            bin_path = 'tcm.bin'
            obj_copy = 'riscv32-unknown-elf-objcopy'
            bin_cmd = obj_copy + ' ' + elf_path + ' -O binary ' + bin_path
            subprocess.call(bin_cmd, shell=True)

            #run simulation
            signature_name = base_name + '.signature.output'
            signature_path = work_dir+'/'+isa+'/signature/'+signature_name
            vvp_cmd = 'vvp -n '+'./riscv_sim.out '+'+dumpfile='+signature_path+' -fst'
            #subprocess.call(vvp_cmd, shell=True)
            process = subprocess.Popen(vvp_cmd, shell=True)
            process.wait(timeout=5)            

            #compare with reference signature
            ref_name = base_name + '.reference_output'
            ref_dir  = '../../tc/riscv-compliance/riscv-test-suite/'+isa+'/references/'
            ref_path = ref_dir + ref_name
            result = compare_files(signature_path, ref_path)
            if result == True:
                print(isa+": " + base_name + ", Pass")
                passed += 1
            else:
                print(isa+": " + base_name + ", Fail")
                failed += 1

        print("\n")
        print(f"ISA: {isa}")
        print(f"Total instructions: {total}, Passed: {passed}, Failed: {failed}, Unsupported: {unsupported}")
        print("\n")

if __name__ == '__main__':
    main()
    sys.exit(0)
