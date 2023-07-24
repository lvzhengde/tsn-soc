# This is an example cmake script to build a verilog to SystemC project
# using CMake and Verilator.
# To use it, run the following:
# cd /path/to/solution
# rm -rf build && mkdir build && cd build
# cmake ..
# make 

cmake_minimum_required(VERSION 3.8)
project(ptpv2_tlm CXX)

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
  ../sc 
  ../sw
  ../sw/dep
  $ENV{SYSTEMC_INCLUDE}
  )
aux_source_directory(../sc SYSC_TLM)
aux_source_directory(../sw SW_TOP)
aux_source_directory(../sw/dep PTP_DEP)

# Create a new executable target that will contain all your sources
add_executable (
  ${CMAKE_PROJECT_NAME} 
  ${SYSC_TLM}
  ${SW_TOP}
  ${PTP_DEP}
  )
target_link_libraries (${CMAKE_PROJECT_NAME} SystemC::systemc)

#the C++ standard may be C++11 or C++20
#The below statement should follow add_executable and target_link_libraries
set_property(
  TARGET ${CMAKE_PROJECT_NAME}
  PROPERTY CXX_STANDARD ${SystemC_CXX_STANDARD}
)

# Add the Verilated circuit to the target
verilate(${CMAKE_PROJECT_NAME} SYSTEMC #TRACE #COVERAGE
  TOP_MODULE ptp_top
  VERILATOR_ARGS -f ./vlog.f -x-assign fast #--timing  
  SOURCES ../vl/ptp_top.v
  )

verilate(${CMAKE_PROJECT_NAME} SYSTEMC #COVERAGE TRACE
  INCLUDE_DIRS "../../rtl/inc"
  SOURCES ../../tb/channel_model.v  
  )
