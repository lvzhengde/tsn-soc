proc start_verify {batch} {
    variable batchmode
    variable pipe

    set batchmode $batch
    toplevel .l
    focus .l
    wm title .l "Simulation Log"
    frame .l.f1 
    frame .l.f2
    grid .l.f1 -column 0 -row 0 
    grid .l.f2 -column 0 -row 1 
     
    text .l.f1.t1 -width 80 -height 40 -yscrollcommand {.l.f1.scroll set}
    
    scrollbar .l.f1.scroll -command {.l.f1.t1 yview}
    button .l.f2.b1 -text "Exit" -command {destroy .l} -width 10
    button .l.f2.b2 -text "Stop" -command {Stop_sim} -width 10

    grid .l.f1.t1 -column 0 -row 0 -sticky w
    grid .l.f1.scroll -column 1 -row 0 -sticky nsew

    grid .l.f2.b1 -column 0 -row 0 -padx 5
    grid .l.f2.b2 -column 1 -row 0 -padx 5
    
    set output_win .l.f1.t1

    set currentPath [exec pwd]
    set tailPath [file tail $currentPath]
    if {![string compare $tailPath "script"]} {
        cd ..
    } elseif {![string compare $tailPath "sim"]} {
        cd .
    } else {
        puts "Please enter /path/to/emac/sim or /path/to/emac/sim/script! \n"
        return
    }

    if {$batch==0} {
        Run "bash ./runsim" $output_win
    } else {
        $output_win insert end "Batch mode is not supported currently!\n"
    }
}

proc Run {command output_win} {
    global pipe
    if [catch {open "|$command |& cat "} pipe] {
        $output_win insert end $pipe\n
    } else {
        fileevent $pipe readable [list Log $pipe $output_win]
    }
}

proc Log {pipe output_win} {
    global batchmode
    set separator "###################################################################\n"
    if {[eof $pipe]} {
        if {$batchmode==0} {
            $output_win insert end $separator  
            $output_win insert end "end of Simulation....\n"
            $output_win insert end $separator         
        } else {
            $output_win insert end $separator  
            $output_win insert end "end of Testcase....\n"
            $output_win insert end $separator 
        }
        catch {close $pipe}
    } else {
        gets $pipe line
        $output_win insert end $line\n
        $output_win see end
    }
}   
        
proc Stop_sim {} {
    global pipe 
    catch {close $pipe}
}

