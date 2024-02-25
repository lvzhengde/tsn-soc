import os
import subprocess
import sys

def main():
    subprocess.run(['make', 'clean'], check=True)

    subprocess.run(['make'], check=True)
    
    subprocess.run(['mkdir', '-p', 'build'], check=True)
    
    #The subprocess.run() function expects the first argument to be the path to an executable file, 
    #while cd is a shell builtin command and does not have a corresponding executable file.

    os.chdir('build') #error in use: subprocess.run(['cd', 'build'], check=True
    
    subprocess.run(['cmake', '..'], check=True)
    
    subprocess.run(['make'], check=True)
    
    os.chdir('..')   #
    
    subprocess.run(['./build/cache_verilator'], check=True)

if __name__ == '__main__':
    main()
    sys.exit(0)
