#!/bin/bash

# Orca script
# This script has been written for personal use is not guranteed to function properly in all of the cases
# Awk, Shell script to read energies S^2 value , ... and sort them by file names create spin density cuble files.
# This code finds all the .out files and reads through them (goes through subdirectories).
# The code is designed for most jobs scan files are semi supported.
# For defining the job method and state is read from the naming logic used byt can be easily read from the output file.
# Triplet jobs have -t in their name and CCSD(T) jobs have a -CC (measure have been taken in account to dodge mixing up).
# Few usual errors can be detected by the script.
# this file exports to XLS word reads and converts it just press "finish".

# Configuration
math=/Applications/Mathematica.app/Contents/MacOS/MathKernel

#Notes
#Orca always prints the higher spin block first in state average calculations

LC_ALL=C;
start=`date +%s`
Ver="0.8.9.10.11"

#Synonym
# + means DDCIMP2 is enabled
# Thresholds in parantheses for MRCI are (tsel,tpre)
# BS brokensymmetry
# MRCCm calculation done using MRCC Interface
# nFC NoFrozenCore
# ROPS Restricted OpenShell 

##options
# pairs prints number of strong pairs/total pairs
# corr prints final correlation energy only coupled cluster
# only sets the first  argument is what the outputfiles start with the first argument will be used! (set which output files to be processed)
# only2 sets first and mid one
# bsv prints number of basis functions
# [remobved]bsv basis set version segmented or general only for CC-pVTZ maybe also def2-TZVPP(very approximate based on contraction numbers of H atom orca doesn't provide detailed information in the output)
# ons`prints excel column on screen
# ex add extra results (print CAS energy of NEVPT2 in the unused S^2 field)
# comp publish energy components (only single reference for now)
# All all files in this feature you can also use a path. therefore all the files in the path are rendered.
# zpe reports zpe values
# cube publish orbitals
# ident identifies running calculation ( you have to change your username )
# thermo prints H and S (Enthalpy Entropy)
# LED reading LED

#V0.9.10.13  Improved thermodynamics
#V0.9.10.12  LED
#V0.9.10.11  Improved composition read
#V0.9.10.10+ minor updates
#V0.9.10.10+ pre-alpha relaxed scan support
#V0.9.10.10  Several debugs
#V0.9.10.9+  improved basis set identification
#V0.9.10.9   added printing features
#V0.9.10.8+++minor identification update
#V0.9.10.8++ slight improvements and few features
#V0.9.10.8+  ident improvements
#V0.9.10.8   components for MK-CCSD(T) and bugfixes
#V0.9.10.7+  Improved reports of outputs
#V0.9.10.7   Improved identification
#V0.9.10.6   Further debugs
#V0.9.10.5+  minor debug 
#V0.9.10.5   Performance boost
#V0.9.10.4++ further debugs
#V0.9.10.4+  removed the former bsv option now bsv prints number of basis functions
#V0.9.10.4+  minor debugs
#V0.9.10.4   improved identification of running and queing jobs Warning for probable dead jobd! (will introduce reading inp files for qeued files)
#V0.9.10.3   improved ROPS(ROHF/ROKS) support
#V0.8.10.2   Debugs+
#V0.8.10.1   Identify running calculations, support for OO and Brueckner CC
#V0.8.10.0   Basic MRCI info (CISD,AQCC,DDCI, MRACPF, MRMP, MRCEPA, ...), no support for multiblocks yet
#V0.8.9.10   reprts the largest amplitude of CC in the energy components
#V0.8.9.10   ZPE report if asked
#V0.8.9.9b6  Multipicity bugfix & DLPNO-CCSD component update
#V0.8.9.9b5  Reports quited jobs
#V0.8.9.9b4  Reports crashed jobs
#V0.8.9.9b3  working on # mistake issue & afew debugs
#V0.8.9.9b2  mkcc overlap root coefficient report support
#V0.8.9.9b1  Option to report the annoying basis set version change in orca
#V0.8.9.9    GBW Analysis, State average NEVPT2 added, Heff-right-EigenVectors print for mkcc (mukherjee)
#V0.8.9.9beta  initial State Average support (reporting and printing)(!!NEVPT2 not supported yet!!), improved approach visualization
#V0.8.9.9alpha 1)Details of calculations are now added to the approach tab with the emphasis on CAS and MRCC
#              2)inpinf now sends back return signal which is forwarded to output process functionals for improved reporting
#              3)functioning single file process and Bug fixes.
#V0.8.9.8b9  Relaxed Scan bugfix
#V0.8.9.8b8+ symmetry bugfix(wrong inout error report)
#V0.8.9.8b8  Orca 4.0, error reporting
#V0.8.9.8b7  Energy components bugfix
#V0.8.9.8b6+ wrong state report bug fix
#V0.8.9.8b6  Negative vibrational frequency report
#V0.8.9.8b5  Improved Orca 4.0 support
#V0.8.9.8b4  Excel interface enabled, Error reporting improvement, Interface update, Energy components for optimization
#V0.8.9.8b3  Energy components option for MP2 and Coupled Cluster and DLPNO-CCSD
#V0.8.9.8b2  Error reporting upgrade
#V0.8.9.8b1  files with input error detected as optimization bug fixed
#V0.8.9.8    Interface update and Bug fix
#V0.8.9.7    Timing Functionality added, state detection bug fixed, interface improve
#V0.8.9.6    Broken Symmetry fix for single point energy, superior interface, basis set bug fix, multipicity bug fix
#V0.8.9.5 b4 Basic error report improved UI
#V0.8.9.5 b3 Speed Boost and Runtime report
#V0.8.9.5 b3 Bug fixes and output file Adjusting
#V0.8.9.5 b2 Bug fixes and extra scan support
#V0.8.9.5.0alpha Added argument functionality and single point energy functionality
#V0.8.9.0.1 lots of Bug Fixes
# to be fixed for V0.9
#reduced orbitals
#relaxed Scan
#rewrite the scans steps to count for optimization cycles etc
#argument oprions issue with plt
#optimization graphs


############################
############################
######### FUNCTIONS ########
############################
############################

# Timing
iftim () {
if containsElement "time" "${args[@]}" ; then

  awk '
  /TOTAL RUN TIME/ { if(length($10)==1){sec=$10*10}else{sec=$10}; printf "\t%s:%s:%s:%s\t",$4,$6,$8,sec}
  ' OFS="\t" "$FILENAME"
fi
}

# Function to detect single Point energy
ifspe () {
  awk '
  /Single Point Calculation/ { status="true";exit 0 }
   Single Point Calculation

  /^CARTESIAN COORDINATES/ { exit 1 }

  END { if(status!="true") exit 2 }

  ' OFS="\t" "$FILENAME"
}

ifscan () {
  awk '
  /Parameter Scan Calculation/ { status="true";exit 0 }


  /^CARTESIAN COORDINATES/ { exit 1 }

  END { if(status!="true") exit 2 }

  ' OFS="\t" "$FILENAME"
}
# Function to plot orbitals
function plot_cubes () {
    if [ -z "$1" ]; then
        echo "Usage: make-cube file.gbw ngrid start stop"
    else
        if [ -f "$1.plot" ]; then
            echo "Now removing old file..."
            rm -f "$1.plot"
        fi
        echo "4" >> "$1.plot"
        echo "$2" >> "$1.plot"
        echo "5" >> "$1.plot"
        echo "7" >> "$1.plot"
        for i in `seq $3 $4`
        do
            echo "2" >> "$1.plot"
            echo $i >> "$1.plot"
            echo "10" >> "$1.plot"
        done
        echo "11" >> "$1.plot"
        orca_plot $1 -i < "$1.plot" > tmp.tmp
        rm -f "$1.plot"
    fi
}
# Function to detect optimization
ifopt () {
  awk '
  /Geometry Optimization Run/ { status="true";exit 0 }


  /^CARTESIAN COORDINATES/ { exit 1 }

  END { if(status!="true") exit 2 }

  ' OFS="\t" "$FILENAME"
}
# Function to detect relaxed geometry scan

ifrscan () {
  awk '
  /Relaxed Surface Scan/ { status="true";exit 0 }


  /^CARTESIAN COORDINATES/ { exit 1 }

  END { if(status!="true") exit 2 }

  ' OFS="\t" "$FILENAME"
}

# Function to read basic input info
inpinf () { #starting with method
  read method basis mult app nsr rops nevpt2<<< $(awk '
    BEGIN { if(FILENAME~/.inp/) input=1; print FILENAME}

    /                     INPUT FILE/ { input=1;}
    input &&
    /!/ {for(i=1;i<=NF;i++) {
      if(tolower($i)~/rohf/) rops=1;
      if(tolower($i)~/roks/) rops=1;
      if(tolower($i)~/oocc/) method=$i;
      if(tolower($i)~/ccs/) if(tolower(method)!~/oo/) method=$i;
      if(tolower($i)~/bp/) method=$i;
      if(tolower($i)~/lyp/) method=$i;
      if(tolower($i)~/pbe/) method=$i;
      if(tolower($i)~/b3p/) method=$i;
      if(tolower($i)~/b1p/) method=$i;
      if(tolower($i)~/tpss/) method=$i;
      if(tolower($i)~/m06/) method=$i;
      if(tolower($i)~/wb/) method=$i;
      if(tolower($i)~/b2p/) method=$i;
      if(tolower($i)~/pw1/) method=$i;
      if(tolower($i)~/pw2/) method=$i;
      if(tolower($i)~/b2g/) method=$i;
      if(tolower($i)~/b2k/) method=$i;
      if(tolower($i)~/b2t/) method=$i;
      if(tolower($i)~/pwp/) method=$i;
      if(tolower($i)~/mp2/) method=$i;
      if(tolower($i)~/mp4/) method=$i;
      if(tolower($i)~/cisd/) method=$i;
      if(tolower($i)~/nevpt2/) {method=$i; nevpt2=1}
      if(tolower($i)~/d3bj/) {d3bj=1}
      if(!method && tolower($i)~/hf/) method=$i;
      }
      }
    input &&
    /!/ {for(i=1;i<=NF;i++) {
      if(tolower($i)~/pc-/) {if ($i!~"/"  ) basis=$i;}
      if(tolower($i)~/6-31/) {if ($i!~"/"  ) basis=$i;}
      if(tolower($i)~/def2/) {if ($i!~"/"  ) basis=$i;}
      if(tolower($i)~/ano-/) {if ($i!~"/"  ) basis=$i;}
      if(tolower($i)~/epr/ && tolower($i)!~/largeprint/) {if ($i!~"/"  ) basis=$i;}
      if(tolower($i)~/iglo-/) {if ($i!~"/"  ) basis=$i;}
      if(tolower($i)~/nasa/) {if ($i!~"/"  ) basis=$i;}
      if(tolower($i)~/aug-/) {if ($i!~"/"  ) basis=$i;}
      if(tolower($i)~/cc-/) {if ($i!~"/"  ) basis=$i;}
      if(!method && tolower($i)~/DZ/) {if ($i!~"/"  ) basis=$i;}
      if(!method && tolower($i)~/TZ/) {if ($i!~"/"  ) basis=$i;}
      if(!method && tolower($i)~/VP/) {if ($i!~"/"  ) basis=$i;}
      if(!method && tolower($i)~/SV/) {if ($i!~"/"  ) basis=$i;}
      if(!method && tolower($i)~/hf/) {if ($i!~"/"  ) basis=$i;}
      }
      }

  input &&
  /[Mm][Rr][Cc][Ii]/{mrci=1;nblock=0;}
  mrci &&
  /[Cc][Ii][Tt][Yy][Pp][Ee]/{citype=$NF}
  /[Dd][Oo][Dd][Dd][Cc][Ii][Mm][Pp][2].*[Tt][Rr][Uu][Ee]/{DDCIMP2=1;}
  mrci &&
  /[Tt][Ss][Ee][Ll]/{for(i=1;i<=NF;i++)if($i~/[Tt][Ss][Ee][Ll]/)tsel=$(i+1)}
  mrci &&
  /[Tt][Pp][Rr][Ee]/{for(i=1;i<=NF;i++)if($i~/[Tt][Pp][Rr][Ee]/)tpre=$(i+1)}
  mrci &&
  /[Nn][Ee][Ww][Bb][Ll][Oo][Cc][Kk]/{nblock=nblock+1;for(i=1;i<=NF;i++)if($i~/[Nn][Ee][Ww[Bb][Ll][Oo][Cc][Kk]/)block[nblock,1]=$(i+1);}
  mrci &&
  /[Ee][Xx][Cc][Ii][Tt][Aa][Tt][Ii][Oo][Nn][Ss]/{for(i=1;i<=NF;i++)if($i~/[Ee][Xx][Cc][Ii][Tt][Aa][Tt][Ii][Oo][Nn][Ss]/)block[nblock,2]=$(i+1)}
  mrci &&
  /[Nn][Rr][Oo][Oo][Tt][Ss]/{for(i=1;i<=NF;i++)if($i~/[Nn][Rr][Oo][Oo][Tt][Ss]/)block[nblock,3]=$(i+1)}
  mrci &&
  /[Rr][Ee][Ff][Ss]/{for(i=1;i<=NF;i++)if($i~/[Rr][Ee][Ff][Ss]/)block[nblock,4]=$(i+1)}

  input &&
  /%[Mm][Rr][Cc][Cc]/{if (!mdci){mrccm=1}}
  mrccm &&
  /[Mm][Ee][Tt][Hh][Oo][Dd]/{method="MRCCm"$NF}

  input &&
  /%[Mm][Dd][Cc][Ii]/{mdci=1}
  mdci &&
  / [Mm][Rr][Cc][Cc].*[Oo][Nn]/{MRCC="MRCC"}
  mdci &&
  /[Bb][Rr][Uu][Ee][Cc][Kk].*[Tt][Rr][Uu][Ee]/{Brueck=1}
  mdci &&
  / [Mm][Rr][Cc][Cc][Tt][Yy][Pp][Ee]/{MRCC=$NF}
  input &&
  /%[Cc][Aa][Ss]/{mc=1}
  mc &&
  / [Nn][Ee][Ll]/{nel=$NF}
  mc &&
  / [Nn][Oo][Rr][Bb]/{norb=$NF}
  input &&
  /[Xx][Yy][Zz]/ {if(!$6){iMULT=$5;}else{iMULT=$6;}} #your systems state
  input &&
  /[Xx][Yy][Zz][Ff][Ii][Ll][Ee]/ {iMULT=$(NF-1)} #your systems state
  input &&
  / [Mm][Oo][Rr][Ee][Aa][Dd]/ {rorb1="MOREAD"}
  input &&
  / [Oo][Rr][Bb][Oo][Pp][Tt].*[Tt][Rr][Uu][Ee]/ {rorb2="OrbitalOpt"}
  input &&
  / [Bb][Rr][Oo][Kk][Ee][Nn][Ss][Yy][Mm]/{rorb3="BrokenSym"}
   input &&
  / [Ff][Ll][Ii][Pp][Ss][Pp][Ii][Nn]/{rorb4="FlipSpin"}
   input &&
  / [Uu][Ss][Ee][Qq][Rr][Oo][Ss].*[Tt][Rr][Uu][Ee]/{rorb5="QROs"}
  input &&
  / [Nn][Oo][Ff].*[Cc][Oo][Rr][Ee]/{rorb7="nFC"}
   input &&
  / [Nn][Rr][Oo][Oo][Tt][Ss]/{roots=$NF}
  input &&
  /[Mm][Uu][Ll][Tt]/{mults=$NF}

  /END OF INPUT/ { iEND=1;
                   if(MRCC || mc ){nevpt2==1?nsr=2:nsr=1;}else{nsr=0}; if(!rops){rops=0};
                   if(roots && roots!="1"){if(!mults){mults=iMULT};rorb6="SA["roots"-"mults"]"}
                   if(mrci){rorb3="("tsel","tpre")"}
                   if(rorb3) if(rorb1) rorb1=rorb1"-"; if(rorb4) if(rorb3) {rorb3=rorb3"-"}else if(rorb1){rorb1=rorb1"-"}
                   if(rorb5) if(rorb4) {rorb4=rorb4"-"}else if(rorb3){rorb3=rorb3"-"}else if(rorb1){rorb1=rorb1"-"}
                   if(rorb6) if(rorb5) {rorb5=rorb5"-"}else if(rorb4){rorb4=rorb4"-"}else if(rorb3){rorb3=rorb3"-"}else if(rorb1){rorb1=rorb1"-"}
                   if(rorb7) if(rorb6) {rorb6=rorb6"-"}else if(rorb5){rorb5=rorb5"-"}else if(rorb4){rorb4=rorb4"-"}else if(rorb3){rorb3=rorb3"-"}else if(rorb1){rorb1=rorb1"-"}
                   rorb=rorb1 rorb3 rorb4 rorb5 rorb6 rorb7;
                   if(DDCIMP2){citype=citype"+"}
                   if(rorb2) {method="OO-"method};if(Brueck) {method="B-"method}; if(MRCC){method=MRCC"-"method}; if(mc && method){method="CAS("nel","norb")-"method};if(mc && !method){method="CAS("nel","norb")"};if(d3bj){method=method"-D3BJ"}

                   if(mc && mrci){method="CAS("nel","norb")-"citype"-"block[1,2]"-"block[1,4]}
                   if(!method) method="NULL";  if(!rorb) rorb="**NULL**"; if(!basis) basis="NULL"; print method" "basis" "iMULT" "rorb" "nsr" "rops; exit }

  END {
                   if(MRCC || mc ){nevpt2==1?nsr=2:nsr=1;}else{nsr=0}; if(!rops){rops=0};
                   if(roots && roots!="1"){if(!mults){mults=iMULT};rorb6="SA["roots"-"mults"]"}
                   if(mrci){rorb3="("tsel","tpre")"}
                   if(rorb3) if(rorb1) rorb1=rorb1"-"; if(rorb4) if(rorb3) {rorb3=rorb3"-"}else if(rorb1){rorb1=rorb1"-"}
                   if(rorb5) if(rorb4) {rorb4=rorb4"-"}else if(rorb3){rorb3=rorb3"-"}else if(rorb1){rorb1=rorb1"-"}
                   if(rorb6) if(rorb5) {rorb5=rorb5"-"}else if(rorb4){rorb4=rorb4"-"}else if(rorb3){rorb3=rorb3"-"}else if(rorb1){rorb1=rorb1"-"}
                   if(rorb7) if(rorb6) {rorb6=rorb6"-"}else if(rorb5){rorb5=rorb5"-"}else if(rorb4){rorb4=rorb4"-"}else if(rorb3){rorb3=rorb3"-"}else if(rorb1){rorb1=rorb1"-"}
                   rorb=rorb1 rorb3 rorb4 rorb5 rorb6 rorb7;
                   if(DDCIMP2){citype=citype"+"}
                   if(rorb2) {method="OO-"method};if(Brueck) {method="B-"method} if(MRCC){method=MRCC"-"method}; if(mc && method){method="CAS("nel","norb")-"method};

                   if(mc && mrci){method="CAS("nel","norb")-"citype"-"block[1,2]"-"block[1,4]}
                   if(!method) method="NULL";  if(!rorb) rorb="**NULL**"; if(!basis) basis="NULL"; print method" "basis" "iMULT" "rorb" "nsr" "rops; exit }

  

  ' OFS="\t" "$FILENAME")

# reading elements making chemical formula

read comp <<< $(awk '/CARTESIAN COORDINATES.*A.U./{a=1;next}
 a &&
 /\* core/ {for(i in c){ if(c[i]==1){printf "%s", i} else {printf "%s%s", i,c[i]}}; exit}
a==1&&/NO LB/{b=1;next} $0==""{a=0;b=0;next}
a==1&&b==1{c[$2]++}
 /INTERNAL COORDINATES/ {for(i in c){ if(c[i]==1){printf "%s", i} else {printf "%s%s", i,c[i]}}; exit}

' OFS="\t" "$FILENAME")

# Printing the results in Columns
if [ ${#comp} -lt 8 ] ; then
  if [ ${#method} -lt 8 ] ; then
    if [ ${#basis} -lt 8 ] ; then
      printf "%-5s\t\t\t\t%-5s\t%-5s\t%-5s\t\t%-5s\t\t\t%-5s\t" "$comp" "$mult" "$2" "$method" "$basis" "$app"
    else
      printf "%-5s\t\t\t\t%-5s\t%-5s\t%-5s\t\t%-5s\t\t%-5s\t" "$comp" "$mult" "$2" "$method" "$basis" "$app"
    fi
  else
    if [ ${#basis} -lt 8 ] ; then
      printf "%-5s\t\t\t\t%-5s\t%-5s\t%-5s\t%-5s\t\t\t%-5s\t" "$comp" "$mult" "$2" "$method" "$basis" "$app"
    else
      printf "%-5s\t\t\t\t%-5s\t%-5s\t%-5s\t%-5s\t\t%-5s\t" "$comp" "$mult" "$2" "$method" "$basis" "$app"
    fi
  fi
elif [ ${#comp} -lt 15 -a ${#comp} -ge 8 ] ; then
  if [ ${#method} -lt 8 ] ; then
    if [ ${#basis} -lt 8 ] ; then
      printf "%-5s\t\t\t%-5s\t%-5s\t%-5s\t\t%-5s\t\t\t%-5s\t" "$comp" "$mult" "$2" "$method" "$basis" "$app"
    else
      printf "%-5s\t\t\t%-5s\t%-5s\t%-5s\t\t%-5s\t\t%-5s\t" "$comp" "$mult" "$2" "$method" "$basis" "$app"
    fi
  else
    if [ ${#basis} -lt 8 ] ; then
      printf "%-5s\t\t\t%-5s\t%-5s\t%-5s\t%-5s\t\t\t%-5s\t" "$comp" "$mult" "$2" "$method" "$basis" "$app"
    else
      printf "%-5s\t\t\t%-5s\t%-5s\t%-5s\t%-5s\t\t%-5s\t" "$comp" "$mult" "$2" "$method" "$basis" "$app"
    fi
  fi
else
    if [ ${#method} -lt 8 ] ; then
      if [ ${#basis} -lt 8 ] ; then
        printf "%-5s\t%-5s\t%-5s\t%-5s\t\t%-5s\t\t%-5s\t" "$comp" "$mult" "$2" "$method" "$basis" "$app"
      else
        printf "%-5s\t%-5s\t%-5s\t%-5s\t\t%-5s\t%-5s\t" "$comp" "$mult" "$2" "$method" "$basis" "$app"
      fi
  else
    if [ ${#basis} -lt 8 ] ; then
      printf "%-5s\t%-5s\t%-5s\t%-5s\t%-5s\t\t%-5s\t" "$comp" "$mult" "$2" "$method" "$basis" "$app"
    else
      printf "%-5s\t%-5s\t%-5s\t%-5s\t%-5s\t%-5s\t" "$comp" "$mult" "$2" "$method" "$basis" "$app"
    fi
  fi
fi

if [[ "$nsr" -eq 1 ]] ; then
    return 1
elif [[ "$nsr" -eq 2 ]] ; then
    return 3
elif [[ "$rops" -eq 1 ]] ; then
  return 2
fi
}  >> test.data



# Function to read geometric data (to be cleaned up)
readgeom () {
  rorps="";mc="";
  if containsElement "comp" "${args[@]}" ; then
  ecomp="true"
  fi
  if containsElement "zpe" "${args[@]}" ; then
  ezpe="true"
  fi
    if containsElement "thermo" "${args[@]}" ; then
  thermo="true"
  fi
  if [[ "$2" -eq 1 ]] || [ "$2" -eq 3 ];then
  mc=$2

  fi
  if [[ "$2" -eq 2 ]]; then
  rops=$2
  fi
if containsElement "ex" "${args[@]}" ; then #if ex is asked publish CAS energy under S^2 value
  if [[ "$2" -eq 3 ]]; then
    extra="on"

  fi
fi
  if containsElement "bsv" "${args[@]}" ; then
    bsv=1
  fi
  awk -v ezpe="$ezpe" -v ecomp="$ecomp" -v mc="$mc" -v rops="$rops" -v bsv="$bsv" -v thermo="$thermo" '
  /^INITIAL GUESS ORBITALS/,/^TOTAL SCF ENERGY/ || /CASSCF RESULTS/{next}
  /^ORBITAL ENERGIES/,/MULLIKEN POPULATION ANALYSIS/ {next}
  /MULLIKEN POPULATION ANALYSIS/,/TIMINGS/ || /MP2 TOTAL ENERGY/{next}

  #Input keywords
  /INPUT FILE/{INP=1}

  #if these keywords is found its openshell
  INP &&
  /[Uu][Hh][Ff]/{OPS=1}
  INP &&
  /[Uu][Kk][Ss]/{OPS=1}
  INP &&
  /[Nn][Oo][Ii][Tt][Ee][Rr]/{noiter=1}

  INP &&
  /[Rr][Hh][Ff]/{iRHF=1}
  INP &&
  /[Rr[Kk][Ss]/{iRHF=1}

  /CARTESIAN COORDINATES/{INP=""}

  /Relaxed Surface Scan/{Relaxed_scan=1}

  Relaxed_scan &&
  /Angle \(/{ Angle_scan=$8}  
  /Multiplicity.*1/ {MULT=1;} #your system is singlet

  # Basis set version seg vs general
  bsv &&
  /contracted basis functions/{printf "%s\t",$NF}
  # bsv && !bsvp &&
  # /BASIS SET INFORMATION/{bsvf=1}
  # bsvf &&
  # /Type H.*5s2p1d.*3s2p1d.*[{]311/{printf "%s\t","Seg_basis";bsvp=1;bsvf=""}
  # bsvf &&
  # /Type H.*7s2p1d.*3s2p1d.*[{]511/{printf "%s\t","Gen_basis";bsvp=1;bsvf=""}
  # bsv &&
  # /ORCA GTO INTEGRAL CALCULATION/{if(!bsvp){printf "%s\t","?_basis"}}

  # GBW file analysis
  /INITIAL GUESS: MOREAD/{GBW=1}
  GBW &&
  /Input Geometry matches current geometry/{GBWGeo=1}
  GBW &&
  /Input basis set matches current basis set/{GBWBas=1}
  GBW &&
  /Input basis set is compatible with but different from current basis/{GBWBasCur=1}
  GBW &&
  /projection required/{GBWproj=1}
  GBW &&
  /INITIAL GUESS DONE/{GBW=""; if(!GBWGeo){printf "%s\t","GBW_GEO_ERR"}; if(!GBWBas && !GBWBasCur){printf "%s\t","GBW_Basis_ERR"}; if(GBWproj){printf "%s\t","Basis_projected"};if(!GBWBas && GBWBasCur){printf "%s\t","GBW_old_Basis"} }
  !D3E &&
  /Non-parameterized functional/{D3E=1; printf "%s\t","non parametrized DFT"}

  /SCF not fully converged/ {printf "SCF warning!"}
  /SCF_NOT_CONVERGED/ {PROB=1;} #not convergence issue

  /An error has occured in the MDCI module/ {MDCI=1;} #MDCI issue
  /optimization did not converge/  {OPT=1}
  /The Coupled-Pair iterations have NOT  converged/ {CC=0}

  /Warning: Active space composition/ {printf "Active space Error"}
  /HURRAY/        {FOUND=1;} #system optimized :D

  /Job terminated from outer space!/ {CAN=1}
  /‘.*’ -> ‘.*’/ {iquit=1}
  /ORCA finished by error termination/ {iError=1}

  FOUND && MULT && !OPS &&
  /THE OPTIMIZATION HAS CONVERGED/ {if (!mc && !rops) {printf "%s\t\t","NONE";SS=1}} # if sytem is singlet and openshell keywords are not used its restricted calculation

  FOUND &&
  /SCF_NOT_CONVERGED AFTER/ {printf "%s\t","SCF Crash!"} # sometimes after you optimize the system it crashes! you get no S^2 value!

  FOUND && !mc && !rops &&
  /Expectation value of/ { printf "%s\t",$6; SS=1;}  # S^2 value

  #### energy composition

    ecomp &&
  /^ORBITAL OPTIMIZED/ {OO=1}

    FOUND && ecomp && !OO &&
  /^Total Energy/ {HF=$4}

    FOUND && ecomp && OO &&
  /CONVERGENCE REACHED/ {ooc=1; }

    FOUND && ooc &&
  /Reference Energy/{oHF=$4 }

    FOUND && ecomp && OO &&
  /RI-MP2 CORRELATION ENERGY/ {OO=1; oMCorr=$4;}

    FOUND && ecomp && !OO &&
  /MP2 CORRELATION ENERGY/ {MP=1; if($5~/[0-9]/){MCorr=$5}else{MCorr=$4} }

  /ORCA ORBITAL LOCALIZATION/ {local=1;}

    FOUND && local &&
  /PAIRS ARE KEPT CC/ {spair=$1; tpair=$3}

    FOUND && local &&
  /of surviving pairs is/ {spair=$6; tpair=$9}


    ecomp &&
  /The Coupled-Pair iterations have converged/ {CC=1}

    FOUND && ecomp && !CC &&
  /COUPLED CLUSTER ENERGY/ {CC=1}

    FOUND && ecomp && CC && !trip &&
  /E\(0\)/  { HF=$NF;}

    FOUND && ecomp && CC && !trip &&
  /E\(CORR\)/|| /Final F12 correlation energy/ {Corr=$NF}

    FOUND && ecomp && CC &&
  /strong-pairs/{CCpair=$NF}

    FOUND && ecomp && CC &&
  /weak-pairs/{MPpair=$NF}

    FOUND && ecomp && CC &&
  /^T1/{T1=$NF}

    FOUND && ecomp && CC &&
    /LARGEST AMPLITUDES/{getline;getline; Amp=$NF}

    FOUND && ecomp && CC &&
    /LARGEST PNO AMPLITUDES/{getline;getline; Amp=$NF}

    FOUND && ecomp && CC &&
  /Triples Correction/ {CC=2;trip=$NF}

  #####

  FOUND &&
  /^FINAL.*ERGY/  {
      if (!PROB) # if you have energy but with SCF isuue you get ! after your energy
          {   if ( mc ){printf "%s\t","Mult-Ref"}
              else if ( rops ){printf "%s\t","ROPS"}
              else if (!SS){if(noiter){printf "%s\t","no-SCF     "}else{printf "%s\t","ERROR*"}} #if you dont find values for S^2 and energy you publish error for s^2
              if (CC=="0") {printf "%s\t%s","CC not converged",$NF}
              else if( SCF=="0" ) {printf "%s\t%s","SCF not converged",$NF}
              else if( !ecomp ){printf "%s\t%s",S2,$NF}
              else if( ecomp && CC==1 && !local) {printf "%s\t%s\t%s\t%s\t%s\t%s",S2,$NF,HF,Corr,T1,Amp}
              else if( ecomp && CC==1 && local) {printf "%s\t%s%s%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s",S2,spair,"/",tpair,$NF,HF,MPpair,CCpair,Corr,T1,Amp}
              else if( ecomp && CC==2 && !local) {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s",S2,$NF,HF,Corr,T1,Amp,trip}
              else if( ecomp && CC==2 && local) {printf "%s\t%s%s%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s",S2,spair,"/",tpair,$NF,HF,MPpair,CCpair,Corr,T1,Amp,trip}
              else if( ecomp && MP==1) {printf "%s\t%s\t%s\t%s",S2,$NF,HF,MCorr}
              else if( ecomp && OO==1) {printf "%s\t%s\t%s\t%s",S2,$NF,oHF,oMCorr}
              else {printf "%s\t%s\t%s",S2,$NF,"none"}
              if(Relaxed_scan==1){FOUND=0;printf "\t%s\n", Angle_scan}

              CONV=1
          }
          }
  ezpe &&
  /Zero point energy/ {printf "\t%s\t",$5}

  thermo &&
 /Thermal Enthalpy correction/ {printf "%s\t",$5}

  thermo &&
 /Final entropy term/ {printf "%s\t",$5}

   thermo &&
 /G-E\(el\)/ {printf "%s\t",$3}

  Found &&
  /VIBRATIONAL.*CIES/{a=1;getline;next} #Vibrational frequencies : checks if theres negative frequency, then report value and number if so
  a &&
  /.*/ {sub(":","", $1);if ($2!="" && $2<0){printf "%s%s%s%s"," negative frequency! ",$2,"@",$1}}
 /---/{a=""}

END         {
      if (CONV && !SS && !mc && !rops && !noiter && OPS){printf "%s\t","ERROR     "} #if you dont find values for S^2 and energy you publish error for s^2
      if (!CONV && OPT==1) {printf "NOT_OPTIMIZED\t\t\t\t"} #not optimized error
      else if(!CONV && PROB==1) {printf "SCF_NOT_CONVERGED\t\t\t\t"} #SCF error
      else if(!CONV && MDCI==1) {printf "MDCI_MODULE_ERROR\t\t\t\t"} #MDCI error
      else if(CAN==1 && !CONV) {printf "CANCELLED\t\t\t\t\t"} #cancelled job
      else if(!CONV && !PROB && CONV!=1 && MDCI!=1){if(iError){printf "Error :( \t"}
      else if(iquit){printf "Unexpected_Quit!\t\t\t\t"}
      else{printf "Running...\t\t\t\t"}} # other issues
      };

  ' OFS="\t" "$FILENAME"
}  >> test.data

# function to read scan
readrscan () {

read -r -a scanopt <<< $(awk '     /end/{f=0} #reading the scan parameters into array
    /%geom Scan/{gsub(",","");f=1;sub(/^.*%geom Scan/,"");;sub(/#.*/,"")}
    f&&NF>3{gsub(",","");sub(/#.*/,""); print $3,$(NF-2),$(NF-1),$NF}' OFS="\t" "$FILENAME")


from="${scanopt[1]}";to="${scanopt[2]}";nsteps=$((${scanopt[3]}-1)); #saving the values from the array to variables


for c in $(seq 0 $nsteps) ; do
   steps[c]=$(printf "%s%s%s\t" "${scanopt[0]}" " " $(bc -l <<< "scale=4; $from + ($to - $from) / ($nsteps) * ($c)"))
done

   read -r -a esteps <<< $(awk ' #reading energies saving them into a bash array

 /SCF_NOT_CONVERGED/ {PROB=1} #not convergence issue

 /An error has occured in the MDCI module/ {MDCI=1} #MDCI issue


 /HURRAY/        {found=1;} #system optimized :D we find the final energy in the next step!

 found &&
   /^FINAL.*ERGY/  {printf "%s\t",$NF; found=""; EN=1} #printing the final energy

 /optimization did not converge/ {printf "%s%s\t","!","not converged!" ; EN=1} #if optimization didnt converge!

 /RELAXED SURFACE SCAN STEP/ { if ($6!=1) {
     if ( !EN) {printf "%s%s\t",$6,"failed  "}
     else {EN=0} }  }
 END         { if (!EN && !MDCI && !PROB) {printf "%s\t","not_finished?"}
               else if(!EN && MDCI==1) {printf "%s\t","mdci_error"}
               else if(!EN && PROB==1) {printf "%s\t","scf_error"}}

 ' OFS="\t" "$FILENAME")


   read -r -a ssteps <<< $(awk '
 #if these keywords is found its openshell
 /[Uu][Hh][Ff]/{OPS=1}
 /[Uu][Kk][Ss]/{OPS=1}

 /Multiplicity.*1/ {MULT=1;} #your system is singlet

 /HURRAY/        {FOUND=1;} #system optimized :D

 FOUND &&
 /SCF_NOT_CONVERGED AFTER/ {printf "%s\t","SCF Crash!"} # sometimes after you optimize the system it crashes! you get no S^2 value!

 FOUND && MULT && !OPS &&
 /THE OPTIMIZATION HAS CONVERGED/ {printf "%s\t\t","NONE"} # if sytem is singlet and openshell keywords are not used its restricted calculation

 FOUND &&
 /Expectation value of/ { spin=$6; }  # S^2 value

 /optimization did not converge/ {
         if (!OPS && MULT) # open shell system
         {   printf "%s\t","Resricted"; SS=1;
         }
       else { printf "%s\t",spin}; SS=1;}

 FOUND &&
 /^FINAL.*ERGY/  { FOUND=0; CONV=1; SS=1;
     if (!OPS && MULT) # open shell system
         {   printf "%s\t","Resricted"
         }
       else { printf "%s\t",spin } }

/RELAXED SURFACE SCAN STEP/ { if ($6!=1) {
     if ( !SS) {printf "%s\t","bum   "}
     else {SS=0} }  }
 END         { if ( !SS) {printf "%s\t","finished?"}}
 ' OFS="\t" "$FILENAME")


printf "%s\t%s\t%s\n" "${ssteps[0]}" "${esteps[0]}" "${steps[0]}";
for ((i=1; i< "${#steps[@]}"; i++)) do printf "%s\t%s\t%s\t%s\t%s\t\t%s\t%s\t%s" "         " "         " "         " "         " "         " "${ssteps[$i]}" "${esteps[$i]}" "${steps[$i]}"; [[ $i -ne nsteps ]] && echo "" ; done

}   >> test.data

# Function to read single point energy
readener () {
rorps="";mc="";
if containsElement "comp" "${args[@]}" ; then
ecomp="true"
fi

if containsElement "LED" "${args[@]}" ; then
LED="true"
fi

if containsElement "zpe" "${args[@]}" ; then
ezpe="true"
fi

if containsElement "thermo" "${args[@]}" ; then
thermo="true"
fi

if containsElement "corr" "${args[@]}" ; then
corr="true"
fi

if [[ "$2" -eq 1 ]] || [ "$2" -eq 3 ];then
  mc=$2
fi

if [[ "$2" -eq 2 ]]; then
  rops=$2
fi

if containsElement "ex" "${args[@]}" ; then #if ex is asked publish CAS energy under S^2 value
  if [[ "$2" -eq 3 ]]; then
    extra="on"
  fi
fi

if containsElement "bsv" "${args[@]}" ; then
  bsv=1
fi

if containsElement "pair" "${args[@]}" ; then
  ppairs=1
fi

  awk -v ezpe="$ezpe" -v ecomp="$ecomp" -v mc="$mc" -v rops="$rops" -v bsv="$bsv" -v thermo="$thermo" -v nevpt2="$extra" -v LED="$LED" -v icorr="$corr" -v ppairs="$ppairs" '

  /^INITIAL GUESS ORBITALS/,/^TOTAL SCF ENERGY/ || /CASSCF RESULTS/{next}
  /^ORBITAL ENERGIES/,/MULLIKEN POPULATION ANALYSIS/ {next}
  /MULLIKEN POPULATION ANALYSIS/,/TIMINGS/||/EXCITATION SPECTRA/{next}

  #Input keywords
  /INPUT FILE/{INP=1}
  INP &&
  /[Uu][Hh][Ff]/{OPS=1}
  INP &&
  /[Uu][Kk][Ss]/{OPS=1}
  INP &&
  /[Rr][Hh][Ff]/{iRHF=1}
  INP &&
  /[Rr[Kk][Ss]/{iRHF=1}
  INP &&
  /[Nn][Oo][Ii][Tt][Ee][Rr]/{noiter=1}
  INP &&
  /[Mm][Kk][Cc][Cc]/{mkcc=1}
  INP &&
  /Multiplicity.*1/ {MULT=1;} #your system is singlet
  INP && mkcc &&
  / [Rr][Oo][Oo][Tt] /{rootn=$4;rootn=rootn+2}

  /CARTESIAN COORDINATES/{INP=""}
  
  # Basis set version seg vs general
  bsv &&
  /contracted basis functions/{printf "%s\t",$NF}
  # bsv && !bsvp &&
  # /BASIS SET INFORMATION/{bsvf=1}
  # bsvf &&
  # /Type H.*5s2p1d.*3s2p1d.*[{]311/{printf "%s\t","Seg_basis";bsvp=1;bsvf=""}
  # bsvf &&
  # /Type H.*7s2p1d.*3s2p1d.*[{]511/{printf "%s\t","Gen_basis";bsvp=1;bsvf=""}
  # bsv &&
  # /ORCA GTO INTEGRAL CALCULATION/{if(!bsvp){printf "%s\t","?_basis"}}

  # GBW file analysis
  /INITIAL GUESS: MOREAD/{GBW=1}
  GBW &&
  /Input Geometry matches current geometry/{GBWGeo=1}
  GBW &&
  /Input basis set matches current basis set/{GBWBas=1}
  GBW &&
  /Input basis set is compatible with but different from current basis/{GBWBasCur=1}
  GBW &&
  /INITIAL GUESS DONE/{GBW=""; if(!GBWGeo){printf "%s\t","GBW_GEO_ERR"}; if(!GBWBas && !GBWBasCur){printf "%s\t","GBW_Basis_ERR"}; if(!GBWBas && GBWBasCur){printf "%s\t","GBW_old_Basis"} }
  !D3E &&
  /Non-parameterized functional/{D3E=1; printf "%s\t","non parametrized DFT"}
  mc &&
  /Number of multiplicity blocks/ {if($NF != "1"){SA=$NF;print $NF}}

  /SCF not fully converged/ {printf "SCF warning!"}
  /SCF_NOT_CONVERGED/ {PROB=1} #not convergence issue

  /An error has occured in the MDCI module/ {MDCI=1} #MDCI issue

  SA && !nevpt2 &&
  /CASSCF RESULTS/{SAR=1}

  SAR &&
  /CAS-SCF STATES FOR BLOCK/{i=0;Block=$5}
  SAR &&
  /^ROOT.*[0-9]/ {i=i+1;root[Block,i]=$4}
  SAR &&
  /SA-CASSCF TRANSITION ENERGIES/{SAR="";SAP=1}

  SA && nevpt2 &&
  /NEVPT2 TOTAL ENERGIES/ {i=0;nevr=1}

  nevr &&
  /[0-9]:/{i=i+1;root[i]=$4}

  /Expectation value of.*oo/{new_S2=$6}
  /Warning: Active space composition/ {printf "Active space Error "}
  mkcc &&
  /Heff Right Eigenvectors/ {if(!rootn){rootn=2} #if root is not specified it should be 0 (0+2 column will be read)
   if (rootn!=1 && !overlap){
    mkccp=1;getline;getline;getline;
    for (x = 1; x <= 10; x++) {
      if ($rootn~/[0-9].[0-9]/){Heff[x]="["x-1"]"$rootn;getline;} else{break}}
    }else{ # in case of overlap we need to read the whole matrix and print the selected root based on overlap later 
      overlap=1; 
      mkccp=1;getline;getline;getline;
      for(i = 1; i <= 10; i++){
        if ($2~/[0-9].[0-9]/){
          for (x = 2; x <= 10; x++) {
            if ($x~/[0-9].[0-9]/){
            Heffo[i,x]="["i-1"]"$x}else{break}
          }
        }else{break};getline}
      }}

    mkccp &&
    /Selected bwroot/ {rootn=$3+2; #for (x = 1; x <= 10; x++) {printf("%s ", Heffo[x])}
    for(x = 1; x <= 10; x++){ if(Heffo[x,rootn]){ Heff[x]=Heffo[x,rootn] }else{break}}}


  /NEVPT2 TRANSITION ENERGIES/ {nevr="";nevp=1}

  nevpt2 &&
  /Final CASSCF energy/ {CAS=$5}

  /RAGMENT SCF INTERACTION FRAGMENTs   2/{LEDscf=1}
  
  LED && LEDscf &&
  /Sum of electrostatics/{printf "%s\t", $5}

  LED && LEDscf &&
  /Two electron exchange/{printf "%s\t", $5}

  LED && LEDscf &&
  /Sum of INTRA-fragment SCF energies/{printf "%s\t", $7}

  /Summary strong pair decomposition/{LEDs=1}
  LED && LEDs &&
  /INTRA Fragment 1/ {printf "%s\t", $4}

  LED && LEDs &&
  /INTRA Fragment 2/ {printf "%s\t", $4}

  LED && LEDs &&
  /Dispersion  2,1/ {printf "%s\t", $3}

  LED && LEDs &&
  /Charge Transfer 1/ {printf "%s\t", $6}

  LED && LEDs &&
  /Charge Transfer 2/ {printf "%s\t", $6}

  MULT && !OPS &&
  /^FINAL S.*ERGY/ {if (!mc && !rops){printf "%s\t\t","NONE";SS=1}} # if sytem is singlet and openshell keywords are not used its restricted calculation

  /The Coupled-Pair iterations have NOT  converged/ {CC=0;}

  !mc && !rops && !S2 &&
  /Expectation value of/ { S2=$6; SS=1;}  # S^2 value (Save the S^2 values in a variable print the last one with energy Broken Symmetry fix)
  
  icorr &&
  /Final correlation energy/ {icorr=$NF}

  ecomp &&
  /^ORBITAL OPTIMIZED/ {OO=1}

  ecomp && mkccp &&
  /COUPLED CLUSTER ENERGY/ {getline;getline;getline;mkCCSD=$1}

  ecomp && mkccp &&
  /Triples Correction/{mktriples=$NF}

  ecomp && !OO &&
  /^Total Energy/ {HF=$4}

  ecomp && OO &&
  /CONVERGENCE REACHED/ {ooc=1; }

  ooc &&
  /Reference Energy/{oHF=$4 }

  ecomp && OO &&
  /RI-MP2 CORRELATION ENERGY/ {OO=1; oMCorr=$4;}

  ecomp && !OO &&
  /MP2 CORRELATION ENERGY/ {MP=1; if($5~/[0-9]/){MCorr=$5}else{MCorr=$4} }

  /ORCA ORBITAL LOCALIZATION/ {local=1;}

  local  &&
  /PAIRS ARE KEPT CC/ {spair=$1; tpair=$3}

  local  &&
  /of surviving pairs is/ {spair=$6; tpair=$9}

  ppairs  &&
  /PAIRS ARE KEPT CC/ {spair=$1; tpair=$3}

  ppairs  &&
  /PAIRS ARE KEPT CC/ {spair=$1; tpair=$3}

  #ppairs &&
  #/PAIRS ARE KEPT MP2 PAIRS FOR (T)/ {trpair=$1;if(trpair==0){trpair=0.5}}

  #ppairs &&
  #/PAIRS ARE SKIPPED/ {skpair=$1;if(!trpair){trpair=0.5};if(skpair==0){skpair=0.5}}

  ecomp &&
  /COUPLED CLUSTER ITERATIONS/ {CC=1}

  ecomp && !CC &&
  /COUPLED CLUSTER ENERGY/ {CC=1}

  ecomp && CC && !trip &&
  /E\(0\)/||/Corrected 0th order energy/ { HF=$NF;}

  ecomp && CC && !trip &&
  /E\(CORR\)/|| /Final F12 correlation energy/{Corr=$NF}

  ecomp && CC &&
  /strong-pairs/{CCpair=$NF}

  ecomp && CC &&
  /weak-pairs/{MPpair=$NF}

  ecomp && CC &&
  /^T1/{T1=$NF}

  ecomp && CC &&
  /LARGEST AMPLITUDES/{getline;getline; Amp=$NF}

  ecomp && CC &&
  /LARGEST PNO AMPLITUDES/{getline;getline; Amp=$NF}

  ecomp && CC &&
  /Triples Correction/ {CC=2;trip=$NF}

  /Job terminated from outer space!/ {CAN=1}
  /ORCA finished by error termination/ {iError=1}
  /‘.*’ -> ‘.*’/ {iquit=1}

  /^FINAL S.*ERGY/  {
      if (!PROB) # if you have energy but with SCF isuue you get ! after your energy
          {   if ( mc ){if(CAS){printf "%s\t",CAS}else{printf "%s\t","Mult-Ref"}}
              else if ( rops ){printf "%s\t","ROPS"}
              else if (!SS){if(noiter){printf "%s\t","no-SCF     "}else{printf "%s\t",rops}} #if you dont find values for S^2 and energy you publish error for s^2
              if (CC=="0") {printf "%s\t%s","CC not converged",$NF}
              else if( SCF=="0" ) {printf "%s\t%s","SCF not converged",$NF}
              else if( mkccp ){if (ecomp){printf("%s ", rootn-2);for (x = 1; x <= 10; x++) {printf("%s ", Heff[x])};printf "%s\t%s\t%s\t%s",S2,$NF,mkCCSD,mktriples

                               }else{printf("%s ", rootn-2);for (x = 1; x <= 10; x++) {printf("%s ", Heff[x])};printf "%s\t%s",S2,$NF}}

              
              else if( !ecomp ){if(SAP && !nevp){ max_block=SA;max_nr=2;#if state average CAS then print a matrix of blocks and roots
                for (x = 1; x <= max_block; x++) {
                  for (y = 1; y <= 10; y++)
                  printf("%s ", root[x, y])
                }
              }else if(nevp){for (x = 1; x <= i; x++) {printf("%s ", root[x])}; #nevpt2 state average
            }else if(new_S2){printf "%s\t%s\t%s",S2,new_S2,$NF
            }else if(icorr){ if(ppairs){printf "%s\t%s\t%s\t%s",S2,spair/tpair,icorr,$NF}else{printf "%s\t%s\t%s",S2,icorr,$NF}
            }else{printf "%s\t%s",S2,$NF}}
            else if( ecomp && CC==1 && !local) {printf "%s\t%s\t%s\t%s\t%s\t%s",S2,$NF,HF,Corr,T1,Amp}
            else if( ecomp && CC==1 && local) {printf "%s\t%s%s%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s",S2,spair,"/",tpair,$NF,HF,MPpair,CCpair,Corr,T1,Amp}
            else if( ecomp && CC==2 && !local) {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s",S2,$NF,HF,Corr,T1,Amp,trip}
            else if( ecomp && CC==2 && local) {printf "%s\t%s%s%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s",S2,spair,"/",tpair,$NF,HF,MPpair,CCpair,Corr,T1,Amp,trip}
              else if( ecomp && MP==1) {printf "%s\t%s\t%s\t%s",S2,$NF,HF,MCorr}
              else if( ecomp && OO==1) {printf "%s\t%s\t%s\t%s",S2,$NF,oHF,oMCorr}
              else {if(SAP){ #if state average CAS then print a matrix of blocks and roots
                for (x = 1; x <= max_nf; x++) {
                  for (y = max_nr; y >= 1; --y)
                  printf("%s ", root[x, y])
                  printf("\n")
                }
                }else{
                printf "%s\t%s\t%s",S2,$NF,"none"}}
              CONV=1
          }
          }

  ezpe &&
  /Zero point energy/ {printf "\t%s\t",$5}

  thermo &&
 /Thermal Enthalpy correction/ {printf "%s\t",$5}

  thermo &&
 /Final entropy term/ {printf "%s\t",$5}

   thermo &&
 /G-E\(el\)/ {printf "%s\t",$3}

 /SPIN-SPIN/ {printf "%s\t%s\t",$3,$4}
 

  /VIBRATIONAL.*CIES/{a=1;getline;next} #Vibrational frequencies : checks if theres negative frequency, then report value and number if so
  a &&
  /.*/ {sub(":","", $1);if ($2!="" && $2<0){printf "%s%s%s%s"," negative frequency! ",$2,"@",$1}}
 /---/{a=""}


  END         {
      if (CONV && !SS && !mc && !rops && !noiter && !iRHF && OPS){printf "%s\t","ERROR     "} #if you dont find values for S^2 and energy you publish error for s^2
      else if(!CONV && PROB==1) {printf "SCF_NOT_CONVERGED\t\t\t\t"} #SCF error
      else if(!CONV && MDCI==1) {printf "MDCI_MODULE_ERROR\t\t\t\t"} #MDCI error
      else if(CAN==1 && !CONV) {printf "CANCELLED\t\t\t\t\t"} #cancelled job
      else if(!CONV && !PROB && CONV!=1 && MDCI!=1){if(iError){printf "Error :( \t"}
      else if(iquit){printf "Unexpected_Quit!\t\t\t\t"}
      else{printf "Running...\t\t\t\t"}} # other issues
              };

  ' OFS="\t" "$FILENAME"
}  >> test.data

# name logic function
nl () {
awk '  FNR==1  {
           if (FILENAME ~ /-/) #if the filename includes - its special case and will be studied
              {

                  sub("./","", FILENAME) #remove ./ at the begining of file addresses
                  m=split(FILENAME, Ti, "/") #crash it into / then Ti[m] is the exact file name
                  n=split(Ti[m], T, "-") #split file name into dashes to extract -CC and -t, ... file name logic
                  if (length(T[1]) < 2 ) {T[1]=T[1]"("T[2]")"substr(T[3],1,1)} #avoid special cases
                  if (FILENAME ~ /-CC-/ || FILENAME ~ /-CC.o/){imethod="CC";} else {imethod="DFT";} #avoid the case if your compound has CC
                  printf("%-15.10s\t%-10s\t%-10s\t%-10s\t%-5s\t",  T[1], substr(T[n],1,1)=="t"?"triplet":"singlet", imethod,"NULL",FILENAME~"3-1"?"TO        ":"NONE       ") #print results of filename investigation

              }
          else
              {

                  sub("./","", FILENAME);m=split(FILENAME, Ti, "/")
                  n=split(Ti[m], T, ".")
                  if (length(T[1]) < 2 ) {T[1]=T[1]"("T[2]")"T[3]}
                  printf ("%-15.10s\t%-10s\t%-10s\t%-10s\t%-5s\t", T[1] ,FILENAME~"3B1"?"triplet":"singlet", "DFT","NULL",FILENAME~"3-1"?"TO        ":"NONE       ");

              }
          }' OFS="\t" "$FILENAME"
          } >> test.data

# function to plot stuff (for now we stick to spin densities)
cubeplt(){
if [[ "$FILENAME" =~ .*mpi.* ]]; then
oFILENAME=$FILENAME
intn=$(echo ${FILENAME%.*})
FILENAME=$(echo ${intn%.*}".out")

fi

# name of cubefiles should be
name=$(echo ${FILENAME%.*}".gbw")
# plot orbitals only if compuation is converged
if [ -e $name ]; then
    echo "1" > "FILENAME.plot"
    echo "3" >> "FILENAME.plot" #x
    echo "y" >> "FILENAME.plot"
    echo "4" >> "FILENAME.plot"
    echo "50" >> "FILENAME.plot" #g_d
    echo "5" >> "FILENAME.plot" #y
    echo "7" >> "FILENAME.plot"
    echo "10" >> "FILENAME.plot"
    echo "11" >> "FILENAME.plot"

    orca_plot $name -i < "FILENAME.plot" >> "tmp.plot"
    PLOTS=1;
else
    PLOTS=0;
fi

if [[ "$PLOTS" -eq 1 ]]; then
    printf "\t%-10s " "plotted"
    sname=$(basename "$FILENAME")
    cname=$(basename "$(echo ${sname%.*}".spindens.cube")")
    # this is for an issue in orca_plot which suddenly decides to give a different filename to plots
    if [ -e $cname ]; then
        mv $(basename "$(echo ${sname%.*}".spindens.cube")") $(echo ${FILENAME%.*}".spindens.cube");
    else
        mv $(basename "$(echo ${sname%-*}".spindens.cube")") $(echo ${FILENAME%.*}".spindens.cube");
    fi

    rm -f  $(basename "$(echo ${sname%.*}".xyz")") $(basename "$(echo ${sname%.*}".scfr")")
else
    printf "\t%-10s" "No GBW file"
fi

int=${FILENAME#?}




rm -f "FILENAME.plot" "tmp.plot"  #remove temp files

} >> test.data





# a function to check arguments
containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && { ipos="$i"; return 0; }
  done
  return 1
}
containsfilepath () {
  local e
  for e in "${@:1}"
  do
      [[ "$e" =~ .*".out" ]] && { path="$e"; return 0; }
  done
  return 1
}
containsfolderpath () {
  local e
  for e in "${@:1}"
  do
      [[ "$e" =~ .*"/" ]] && { if [ ! -d "$DIRECTORY" ]; then
        path="$e"; return 0;
      fi
    }
  done
  return 1
}

#function to process file
process () {
#give a tip we are processing which file now
if [ ${#FILENAME} -ge 48 ] ; then # This if here adjusts the amount of tab spaces according to file path length to make the table look nice
  printf "%s\t" "$FILENAME"
elif [ ${#FILENAME} -lt 48 ] && [ ${#FILENAME} -ge 40 ] ; then
  printf "%s\t\t" "$FILENAME"
elif [ ${#FILENAME} -lt 40 ] && [ ${#FILENAME} -ge 32 ] ; then
  printf "%s\t\t\t" "$FILENAME"
elif [ ${#FILENAME} -lt 32 ] && [ ${#FILENAME} -ge 24 ] ; then
  printf "%s\t\t\t\t" "$FILENAME"
elif [ ${#FILENAME} -lt 24 ] && [ ${#FILENAME} -ge 16 ] ; then
  printf "%s\t\t\t\t\t" "$FILENAME"
elif [ ${#FILENAME} -lt 16 ] ; then
  printf "%s\t\t\t\t\t\t" "$FILENAME"
else
  printf "%s\t" "$FILENAME"
fi

if ifopt "$FILENAME"; then # check if the file is optimization
  printf "%s\t" "Optimization"

if containsElement "nl" "${args[@]}" ; then  # if name logic is used process it
  nl "$FILENAME"
elif containsElement "nlt" "${args[@]}" ; then
  nl "$FILENAME";  inpinf "$FILENAME"
else
  inpinf "$FILENAME" OPT # if the filename logic is not used no worries we process the input file
fi
iopt=$?
readgeom "$FILENAME" "$iopt" # reading geometry output file


elif ifrscan "$FILENAME" ; then # if geometry scan ()
 printf "%s\t" "Relaxed Scan"
inpinf "$FILENAME" R-Scan # if the filename logic is not used no worries we process the input file
readgeom "$FILENAME"  # reading geometry output file


elif ifscan "$FILENAME" ; then # if geometry scan ()
 printf "%s\t\t" "Parameter Scan"
inpinf "$FILENAME" Scan # if the filename logic is not used no worries we process the input file
 printf "%s\t" "Not implemented yet"
readrscan "$FILENAME"  # reading geometry output file


elif ifspe "$FILENAME" ; then # check if it's single point energy
 printf "%s\t" "S-Point Energy"
if containsElement "nl" "${args[@]}" ; then # if name logic is used process it
  nl "$FILENAME"
elif containsElement "nlt" "${args[@]}" ; then
  nl "$FILENAME";  inpinf "$FILENAME"
else
  inpinf "$FILENAME" SPE # if the filename logic is not used we process the input file
fi
iopt=$?
readener "$FILENAME" "$iopt" # reading single point energy


else
ifopt "$FILENAME"
if (($? == 2)); then
  printf "%s\t" "input error"
  printf "\t%s\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" "I  n  p  u  t  --  E  r  r  o  r" >> test.data

else
 inpinf "$FILENAME"
 printf "%s\t" "Undetected file?!"
fi
fi

# plot cubes if necessary
if containsElement "cube" "${args[@]}" ; then
printf "%s\t" "Plotting"
cubeplt "$FILENAME"
fi
iftim "$FILENAME"  >> test.data
printf "\t%s\n" "$FILENAME" >> test.data
printf "%s\n" "Done"
}
###end

############################
############################
####### Actual script ######
############################
############################

# Reading arguments
args=("$@")


# If no arguments are enetgered error message and help offer
if [[ -z ${args[0]} ]]; then
     echo ${args[0]}
     echo  $Ver " Arguments required to process"
     echo "For help about current functions enter argument h: sh scripta.sh h \n"
fi

# If assistance is called
if containsElement "h" "${args[@]}" ; then
     echo "\nScripta version:" $Ver
     echo "Scripta will read output files and prints out data such as energy, S^2, method, basis set"
     echo "Scripta supports geometry optimization and can track optimization steps"
     echo "Scripta can produce cube files and convert them to vector or bitmap pictures (Mathematica is required)\n"
     echo "keywords:"
     echo "ident: Identifies running calculations using qstat command(modify your username)"
     echo "zpe prints ZPE"
     echo "comp: Energy composition for CCSD, CCSD(T) & MP2"
     echo "time: calculation time"
     echo "All: will process all files .out in subdirectories"
     echo "path: to an aoutput file will process that specific file"
     echo "cube: will make spin density cubefiles"
     echo "plt x y |z:z| |g_d|: x=plot type, y=plot format (5=cube, 6=gOpenMol),z= molecular orbitals (10:20 or 10), g_d= grid points (g_40), || means optional"
     echo "positioning after plt is important, values are read with respect to their position"
     echo "nlt: name logic + test"
     echo "nl: uses name logic \n"
     exit 1
fi

if containsElement "ident" "${args[@]}" ; then
:
else # Print Headers of the table
if containsElement "scan" "${args[@]}" ; then
  awk '
    BEGIN           {print "Compound\t\t\tState\tCalc.\tMethod\t\tBasisset\t\t\tApproach\tS^2\t\t\t\tEnergy\t\t\t\tstep\tvalue"}' > test.data
elif containsElement "cube" "${args[@]}" ; then
  if containsElement "nlt" "${args[@]}" ; then
    awk '
    BEGIN           {print "Compound\t\t\tState\tMethod\tApproach\tCompound\t\tState\t\tMethod\t\tBasisset\t\tApproach\tS^2\t\tEnergy\t\t\tCube file\t\tPath"}' > test.data
  else
    awk '
    BEGIN           {print "Compound\t\t\tState\tCalc.\tMethod\t\tBasisset\t\tApproach\tS^2\t\tEnergy\t\t\tCube file\t\tPath"}' > test.data
  fi

else
  if containsElement "nlt" "${args[@]}" ; then
    awk '
    BEGIN           {print "Compound\t\t\tState\tMethod\tApproach\tCompound\t\tState\t\tMethod\tBasisset\t\t\tApproach\tS^2\t\tEnergy\t\t\t\tPath"}' > test.data
  else
    awk '
    BEGIN           {print "Compound\t\t\tState\tCalc.\tMethod\t\tBasisset\t\t\tApproach\tS^2\t\t\t\tEnergy\t\t\t\tPath"}' > test.data
  fi
fi
fi

# Check if users wants all output files in subdirectories processed
if containsElement "All" "${args[@]}" ; then
  # Finds all the .out file and reads through
  # If a path to a folder is given
  if containsfolderpath "${args[@]}"; then
    dir="$path"
  else
    dir=. ;
  fi
  if containsElement "only" "${args[@]}" ; then
    find "$dir" -name ${1}*.out | while read FILENAME
      do
        process "$FILENAME"
      done
  elif containsElement "only2" "${args[@]}" ; then
    find "$dir" -name ${1}*${2}*.out | while read FILENAME
      do
        process "$FILENAME"
      done
  else
    find "$dir" -name '*.out' | while read FILENAME
      do
        process "$FILENAME"
      done
  fi
  # Check if users have given path to a specific file to be processed
elif containsfilepath "${args[@]}" ; then
  FILENAME="$path"
  process "$FILENAME"
elif containsElement "orbs" "${args[@]}"; then
  plot_cubes "$2" "$3" "$4" "$5" 
elif containsElement "ident" "${args[@]}" ; then
  [ -e qstat.tmp ] && rm qstat.tmp
  [ -e Identify.tmp ] && rm Identify.tmp
  [ -e test.data ] &&rm -f "test.data"
  qstat -u ghafarian | awk '/^[0-9][0-9]/{print $1}' | grep -o '[0-9]\+' > Identify.tmp
  while read job_id
  do
    qstat -f "$job_id" | awk -v id="$job_id" '/Resource_List.nodes/{if(substr($NF,length($NF)-1,2)~ /^[0-9]+$/ ){nodes=substr($NF,length($NF)-1,2)}else{nodes=substr($NF,length($NF),1)};if(nodes=="1"){name="out"}else{name="mpi" nodes ".out"}}/Error_Path/{path=substr($3,9);if(path!~/err/){getline;path=path $1} };/resour.*walltime/{time=substr($NF,0,length($NF)-3)}/job_state/{state=$3};END{gsub("err", name,path);print id," ",state," ",nodes," ",path," ",time}' >>qstat.tmp
  done  < Identify.tmp 
  while read  first  second  third fourth fifth
  do 
    FILENAME="${fourth#/home1/ghafarian/}"
    if [ -e "$FILENAME" ]; then
      if [ "$second" == "R" ] || [ "$second" == "C" ]; then
        inpinf "$path" SPE
        Dead=$((($(date +%s) - $(date +%s -r "$FILENAME"))/(60*60) ))
        if [ "$Dead" -gt "12" ]; then
          printf "%s%s%s\t" "!" "$Dead" "!" >>test.data
        else
          printf "%s\t" "$Dead"  >>test.data
        fi
        echo "" >>test.data
      else

        echo "-" "-" "-" "-" "-" "-" "" >>test.data
        #inpinf "${file%.*}.inp" SPE
        #echo "" >>test.data
      fi
    else
      echo "-" "-" "-" "-" "-" "-" "" >>test.data
      #inpinf "${file%.*}.inp" SPE
      #echo "" >>test.data
    fi

  done < qstat.tmp

  awk 'NR==FNR{a[NR]=$1;b[NR]=$2;c[NR]=$3;d[NR]=$4;e[NR]=$5;f[NR]=$6;g[NR]=$7; next} {print $1, $2, $3, $5, a[FNR],b[FNR],c[FNR],d[FNR],e[FNR],f[FNR],g[FNR],$4}' test.data qstat.tmp

  rm -f "qstat.tmp" "Identify.tmp"




else
  echo "Either process all files found in sub directories or give file path to a specific file, we just process .out files!\n Further options are identifying running jobs"
fi

#Identify running calculations


# Here we make an excedl usable file or print on screen if asked for
if containsElement "ons" "${args[@]}" ; then
  echo ""
  awk '   {
             printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32
          }'  test.data
else
  awk '   {
             printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32
          }'  test.data > excel.data
fi

# a nice runtime

end=`date +%s`
runtime=$( echo "$end - $start" | bc -l )
echo "Runtime:" $runtime "Sec"
