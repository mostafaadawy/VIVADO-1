proc findReplace { searchFor replaceWith searchFor1 replaceWith1 searchFor2 replaceWith2} { 
  set cur_dir [pwd]
  set inPath  ${cur_dir}/hw_1/hw_template.xml
  set outPath  ${cur_dir}/hw_1/hw.xml
  # Test if the input is a directory, if not give error message
  if {[file isdirectory $inPath] == 1} {
    puts "Cannot read a directory"
    return
  }
  # Test if the input exists, if not give error message
  if {[file exists $inPath] != 1} {
    set fileName [file tail $inPath]
    #Convert to uppercase
    set fileName [string toupper $fileName] 
    puts "$fileName not found"
    return
  }
  # check if the file is already there 
  if {[file exists $outPath] != 0} {
    puts "$outPath\n is already there. Replacing existing file!"
  }
  set fd [open $inPath r]
  set tempFile [open $outPath w]
  while { [ eof $fd ] != 1} {   
    gets $fd word
    # Find and Replace
    if ([regexp $searchFor $word]) { 
      regsub -all $searchFor $word $replaceWith newWord    
      puts $tempFile $newWord
    } elseif [regexp $searchFor2 $word] {    
      regsub -all $searchFor2 $word $replaceWith2 newWord    
      puts $tempFile $newWord    
    } elseif [regexp $searchFor1 $word] {    
      regsub -all $searchFor1 $word $replaceWith1 newWord    
      puts $tempFile $newWord    
    } else {
      puts $tempFile $word
    }
  }
  close $fd 
  close $tempFile
} 