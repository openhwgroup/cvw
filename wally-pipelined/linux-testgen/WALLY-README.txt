If you do not need to update the Linux image, then go to ./linux-testvectors and 
use tvCopier.py or tvLinker.sh to copy/link premade RAMs and testvectors from Tera.
The RAMs are needed for Wally to run the Linux code, and the testvectors are needed
to verify Wally is executing the code correctly.

If you instead wish to regenerate the RAMs and testvectors from a new Linux image,
you'll need to build the new Linux image, simulate it, and parse its output,
as described below.

*To build a new Linux image:
     1. Git clone the Buildroot repository to ./buildroot:
            git clone https://github.com/buildroot/buildroot.git 
        For reference, Wally (*** will) be proven to work on an image built using
        Buildroot when the following was the most recent commit to the Buildroot repo:
            commit 4047e10ed6e20492bae572d4929eaa5d67eed746
            Author: Gwenhael Goavec-Merou <gwenhael.goavec-merou@trabucayre.com>
            Date:   Wed Jun 30 06:27:10 2021 +0200

     2. If you wish to modify the configs, then in ./buildroot:
        a. Run "make menuconfig" or "make linux-menuconfig" or "make busybox-menuconfig".
        b. Use the TUI (terminal UI) to load in the existing configs.

           For menuconfig, you can load in the source file from
               "../buildroot-config-src/main.config"

           For linux-menuconfig or busybox-menuconfig, load in from 
               "../../../../buildroot-config-src/<type>.config"
           because for linux and busybox, make traverses down to
                ./buildroot/output/build/<linux or busybox>.
          
           One annoying thing about the TUI is that if it has a path already loaded,
           then before you can enter the new path to buildroot-config-src, you need to
           delete the existing one from the textbox. Doing so requires more than backspace.
           Once you've deleted as much of the existing path as you can see, arrow left to 
           check if there is more text you need to delete.

        c. Likewise, when you are done editing, tell the TUI to save to the same location.

     3. Finally go to ./buildroot-config-src and run make-buildroot.sh.
        This script copies ./buildroot-config-src/main.config to ./buildroot/.config
        and then invokes make. This is clumsy but effective because buildroot
        sometimes does weird things to .config, like moving it to .config.old and 
        making a new .config -- doing so can really mess up symbolic/hard links.

     4. If you'd like debugging symbols, then reconfigure Buildroot to output "vmlinux"
        and run make-buildroot again.

*To generate new RAMs and testvectors from a Linux image:
    1. sym link ./buildroot-image-output to either your new image in ./buildroot/output/image 
       or the existing image at /courses/e190ax/buildroot-image-output on Tera. 
       This might require first deleting the empty buildroot-image-output directory.
    2. Then run ./testvector-generation/logBuildrootMem.sh to generate RAMs.
    3. Then run ./testvector-generation/logAllBuildroot.sh to generate testvectors.

       These latter two steps require QEMU.
       Note that you can only have one instance of QEMU open at a time!
       At least on Tera, it seems. Check "ps -ef" to see if anybody else is running QEMU.
