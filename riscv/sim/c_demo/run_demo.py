import os
import subprocess
import sys
import filecmp

def main():
    # clean temporary files
    subprocess.call("make clean", shell=True)

    # generate iverilog simulation executable and bin files
    subprocess.call("make", shell=True)

    #run simulation
    vvp_cmd = 'vvp -n '+'./riscv_sim.out '+' -fst'
    #subprocess.call(vvp_cmd, shell=True)
    process = subprocess.Popen(vvp_cmd, shell=True)

    try:
        process.wait(timeout=20)
    except subprocess.TimeoutExpired:
        print('vvp exec timeout, FAIL!!!')

if __name__ == '__main__':
    main()
    sys.exit(0)
