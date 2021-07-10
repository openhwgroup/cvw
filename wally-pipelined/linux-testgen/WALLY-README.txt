If you do not need to update the Linux image, then go to ./linux-testvectors and 
use tvCopier.py or tvLinker.sh to copy/link premade RAMs and testvectors from Tera.
The RAMs are needed for Wally to run the Linux code, and the testvectors are needed
to verify Wally is executing the code correctly.

If you instead wish to regenerate the RAMs and testvectors from a new Linux image,
you'll need to build the new Linux image, simulate it, and parse its output,
as described below.

*To build a new Linux image:
     1. Git clone the Buildroot repository to ./buildroot.
        For reference, Wally (*** will) be proven to work on an image built using
        Buildroot when the following was the most recent commit to the Buildroot repo:
            commit 4047e10ed6e20492bae572d4929eaa5d67eed746
            Author: Gwenhael Goavec-Merou <gwenhael.goavec-merou@trabucayre.com>
            Date:   Wed Jun 30 06:27:10 2021 +0200

     2. Then hard link ./buildroot-config-src/main.config to ./buildroot/.config.
        That config file will in turn point to the other config files in ./buildroot-config-src.

     3. If you wish to modify the configs, then in ./buildroot:
        a. Run "make menuconfig" or "make linux-menuconfig" or "make busybox-menuconfig".
        b. For linux-menuconfig and busybox-menuconfig, use the TUI (terminal UI) to load in
           configs from "../../../../buildroot-config-src/<linux or busybox>.config"
           We have to tell make to go back up several dirs because for linux and busybox,
           make traverses down to ./buildroot/output/build/<linux or busybox>.
        c. Likewise, when you are done editing, tell the TUI to save to the same location.

     4. Then finally you can run make. Note that it may be necessary to rerun make twice,
        once when main.config asks for an "Image" output, and once when main.config
        "vmlinux" output.

*To generate new RAMs and testvectors from a Linux image:
    1. sym link ./buildroot-image-output to either your new image in ./buildroot/output/image 
       or the existing image at /courses/e190ax/buildroot/output/image on Tera. 
       This might require first deleting the empty buildroot-image-output directory.
    2. Then run ./testvector-generation/logBuildrootMem.sh to generate RAMs.
    3. Then run ./testvector-generation/logAllBuildroot.sh to generate testvectors.

       These latter two steps require QEMU.
       Note that you can only have one instance of QEMU open at a time!
       At least on Tera, it seems. Check "ps -ef" to see if anybody else is running QEMU.
