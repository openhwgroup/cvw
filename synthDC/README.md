This subdirectory contains synthesis scripts for use with Synopsys
Design Compiler (DC).  The scripts are separated into two distinct
sections: user and technology setups.  The technology setup is found
in .synopsys_dc.setup file.  Key items within this technology setup
are the location of the PDK and standard cell libraries.

We are using the Skywater Technology 130nm process for the synthesis.
The Oklahoma State University standard-cell libraries for this process
are located via the target_library keyword.  There are currently three
versions of the standard-cell libraries available (see
http://stineje.github.io) for dowload locations.  Currently, the TT 18
track OSU standard-cell library is utilized.

There are other useful elements within the technology setup file, as
well.  These include user information as well as search path
information.  Good tool flows usually rely on finding the right files
correctly and having a search path set correctly is importantly.

The user setup is found in two main areas.  The scripts/ and hdl/
directories.  The scripts directory contains a basic DC synthesis Tcl
script that is involved when synthesis is run.  Please modify this
synth.tcl file to add information about PPA and information about your
design (e.g., top-level name, SV files).  The SV is found within the
hdl/ subdirectory.  Just put all your synthesis-friendly files in this
directory or allude to the correct location in the synthesis Tcl
script.

After synthesis completes, always check your synthesis log file that
will be called synth.log.  Good tool flow starts and ends with
understanding what is happening during a specific part of the flow.
This can only be done through interpreting what the Electronic Design
Automation (EDA) tool is doing.  So, always check this file for any
possible warnings or errors after completion.  All output of synthesis
is found in the reports/ subdirectory.