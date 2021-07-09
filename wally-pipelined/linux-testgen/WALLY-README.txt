If you do not need to update the Linux image, then go to ./linux-testvectors and 
use tvCopier.py or tvLinker.sh to copy/link premade RAMs and testvectors from Tera.
The RAMs are needed for Wally to run the Linux code, and the testvectors are needed
to verify Wally is executing the code correctly.

If you instead wish to regenerate the RAMs and testvectors from a new Linux image,
you'll need to build the new Linux image, simulate it, and parse its output,
as described below.

* To build a new Linux image, Git clone the Buildroot repository to ./buildroot.
    For reference, most recent commit made to the Buildroot repo was
    as of last generating the image found on Tera:
        commit 4047e10ed6e20492bae572d4929eaa5d67eed746
        Author: Gwenhael Goavec-Merou <gwenhael.goavec-merou@trabucayre.com>
        Date:   Wed Jun 30 06:27:10 2021 +0200
    Then hard link ./buildroot-config-src/main.config to ./buildroot/.config.
    That config file will in turn point to the other config files in ./buildroot-config-src.
    If you wish to modify the configs, then
    1. Copy ./buildroot-config-src/linux.config   to ./buildroot/output/build/linux-5.10.7/.config
    2. Copy ./buildroot-config-src/busybox.config to ./buildroot/output/build/busybox-1.33.1/.config
    3. Run "make menuconfig" "make linux-menuconfig" "make busybox-menuconfig" as needed.
    4. Copy ./buildroot/output/build/linux-5.10.7/.config   back to ./buildroot-config-src/linux.config 
    5. Copy ./buildroot/output/build/busybox-1.33.1/.config back to ./buildroot-config-src/busybox.config 
    (*** There may be a better way to do this, but do know that setting up main.config
    to point to those two locations within the Buildroot repo results in interesting
    ".config is the same as .config" errors.)
    Then finally you can run make. Note that it may be necessary to rerun make twice,
    once when main.config asks for an "Image" output, and once when main.config
    "vmlinux" output.

* To generate new RAMs and testvectors from a Linux image,
    sym link ./buildroot-image-output to either your new image in ./buildroot/output/image 
    or the existing image at /courses/e190ax/buildroot/output/image on Tera. 
    (This might require first deleting the empty buildroot-image-output directory).
    Then run ./testvector-generation/logBuildrootMem.sh to generate RAMs.
    Then run ./testvector-generation/logAllBuildroot.sh to generate testvectors.
    Note that you can only have one instance of QEMU open at a time! Check "ps -ef" to see if
    anybody else is running QEMU.
