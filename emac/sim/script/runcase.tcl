#!/usr/bin/wish
#type “wish change_filenames.tcl” to run script

package require Tk

font create EmacDefaultFont -family Helvetica -size 16
option add *font EmacDefaultFont

ttk::style configure TFrame -font EmacDefaultFont ;#change TFrame style
ttk::style configure TButton -font EmacDefaultFont ;#change TButton style
ttk::style configure TCheckbutton -font EmacDefaultFont ;#change TCheckbutton style
ttk::style configure TLable -font EmacDefaultFont ;#change TLable style
ttk::style configure TEntry -font EmacDefaultFont ;#change TEntry style
ttk::style configure TRadiobutton -font EmacDefaultFont ;#change TRadiobutton style
ttk::style configure TCombobox -font EmacDefaultFont ;#change TCombobox style
ttk::style configure TListbox -font EmacDefaultFont ;#change TListbox style

# Create GUI
wm title . "Run Selected Test Case"
frame .frame
grid .frame -row 0 -column 0

label .frame.lbl -text "Current Test Case:" -width 30
entry .frame.ent -textvariable testCaseName -width 50 
button .frame.btn1 -text "Generate sim_emac.v" -width 20 -command {gen_sim_emac $testCaseName}
button .frame.btn2 -text "Select Test Case File" -width 20 -command {select_test_case testCaseName}
button .frame.btn3 -text "Start Verify" -width 20 -command {run_sim}
button .frame.btn4 -text "Quit" -width 20 -command {exit}

grid .frame.lbl -row 0 -column 0
grid .frame.ent -row 0 -column 1 
grid .frame.btn1 -row 0 -column 2 -padx 10 -pady 3
grid .frame.btn2 -row 1 -column 2 -pady 3
grid .frame.btn3 -row 2 -column 2 -pady 3
grid .frame.btn4 -row 3 -column 2 -pady 3

variable currentPath
variable simPath

set currentPath [exec pwd]
set tailPath [file tail $currentPath]
if {![string compare $tailPath "script"]} {
    set simFile ../sim_emac.v
    set simPath ..
} elseif {![string compare $tailPath "sim"]} {
    set simFile ./sim_emac.v
    set simPath .
} else {
    puts "Please enter /path/to/emac/sim or /path/to/emac/sim/script! \n"
}

# Open existed simulation file--sim_emac.v
if {[catch {open $simFile r} fileid]} {
   puts "Failed open $simFile file\n"
} else {
    while {[gets $fileid line] >= 0} {
        if {[lindex $line 0] == "`include"} {
            set testCaseName [lindex $line 1]
        }
    }
    close $fileid
}

# Generate sim_emac.v
proc gen_sim_emac {test_case_name} {
    global simFile

    if {[file exists $simFile]} {
        puts "$simFile already exists and will be deleted and re-created!"
        exec rm $simFile 
    }

    if {[catch {open $simFile w} fileid]} {
        puts "Failed open $simFile file for write\n"
    } else {
        set line "module sim_emac;"
        puts $fileid $line
        set line "tb_emac tb();"
        puts $fileid $line
        set line "`include \"$test_case_name\""
        puts $fileid $line
        set line "endmodule"
        puts $fileid $line
 
        close $fileid
    }

    puts "Simulation file $simFile generated!\n"
    return
}

# Select test case to verify
proc select_test_case {test_case_name} {
    upvar $test_case_name testCase
    global simPath

    set filetypes {
         {{Verilog Files}    {.v}   }
         {{All Files}        *      }
     }
    set fileName [tk_getOpenFile -title "Select a test case" -initialdir $simPath/../tc -filetypes $filetypes]

    if {[file isfile $fileName]} {
        set testCase [file tail $fileName]
        gen_sim_emac $testCase
    }

    return
}

# Run verification
proc run_sim {} {
    global simPath

    if {![string compare $simPath ".."]} {
        source start_verify.tcl
    } else {
        source ./script/start_verify.tcl
    }
    start_verify 0 
}
