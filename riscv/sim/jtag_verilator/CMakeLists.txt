# This is an example cmake script to build a verilog to SystemC project
# using CMake and Verilator.
# To use it, run the following:
# cd /path/to/solution
# rm -rf build && mkdir build && cd build
# cmake ..
# make 

cmake_minimum_required(VERSION 3.8)
project(jtag_verilator CXX)

#set(CMAKE_CXX_STANDARD 11)  #SystemC may be compiled by C++20
#set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

# SystemC dependencies
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

# Find SystemC using SystemC's CMake integration
set (CMAKE_PREFIX_PATH $ENV{SYSTEMC_HOME}/build)
find_package(SystemCLanguage CONFIG REQUIRED)

#include_directories(./ $ENV{SYSTEMC_INCLUDE})
include_directories(
  ../../tb/jtag_verilator
  $ENV{SYSTEMC_INCLUDE}
  )
aux_source_directory(../../tb/jtag_verilator SYSC_TB)

# Create a new executable target that will contain all your sources
add_executable (
  ${CMAKE_PROJECT_NAME} 
  ${SYSC_TB}
  )
target_link_libraries (${CMAKE_PROJECT_NAME} SystemC::systemc)

target_link_libraries (${CMAKE_PROJECT_NAME} elf bfd)

#the C++ standard may be C++11 or C++20
#The below statement should follow add_executable and target_link_libraries
set_property(
  TARGET ${CMAKE_PROJECT_NAME}
  PROPERTY CXX_STANDARD ${SystemC_CXX_STANDARD}
)

# Add the Verilated circuit to the target
verilate(${CMAKE_PROJECT_NAME} SYSTEMC COVERAGE TRACE 
  TOP_MODULE riscv_top
  VERILATOR_ARGS -f ./file_list.txt -x-assign fast #--timing  
  SOURCES ../../rtl/top/riscv_top.v
  )

