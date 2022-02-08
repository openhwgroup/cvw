script_dir=$(readlink -f ./)
personal_config=$(readlink -f ../buildroot-config-src)
shared_config=$RISCV/buildroot-config-src

if [ -d "$shared_config" ]; then
    echo "Hold the horses, friend!" >&2
    echo "There is already a buildroot-config-src folder in \$RISCV" >&2
    if [ ! -f "$shared_config/.owner" ]; then
        echo "Oy vey -- it was improperly created too!" >&2
        echo "I see no .owner file in it!" >&2
        echo "Maybe just delete it." >&2
        exit 1
    fi
    owner=$(cat $shared_config/.owner)
    echo "It was created by $owner." >&2
    echo "Please contact them before overwriting their source files." >&2
    exit 1
fi
echo "Starting new buildroot session"
# Copy configs to shared location
echo "Elevate permissions to copy ../buildroot-config-src to \$RISCV"
sudo cp -r "$personal_config" "$shared_config"
sudo chown -R cad $shared_config
# Document who created these configs
whoami>.owner
sudo mv .owner $shared_config
# Copy over main.config
echo "Copying main.config to buildroot/.config."
sudo cp $shared_config/main.config $RISCV/buildroot/.config
sudo chown cad $RISCV/buildroot/.config

echo "=============================================="
echo "I'm about to sign you in as cad."
echo ""
echo "You can go straight to the \$RISCV/buildroot"
echo "and run \`make\` if you want."
echo ""
echo "You can also run:"
echo "  * \`make menu-config\`"
echo "  * \`make linux-menuconfig\`"
echo "  * \`make busybox-menuconfig\`"
echo "but if you do, you have to make extra certain" 
echo "that you LOAD and SAVE configs from/to "
echo "\$RISCV/buildroot-config-src."
echo ""
echo "Run \`exit\` to sign out when you are done."
echo "And then any configs that were modified in"
echo "\$RISCV/buildroot-config-src will be copied"
echo "back to ../buildroot-config-src."
echo "=============================================="
read -p "Press any key to sign in as cad" -n1 -s
echo ""
cd $RISCV
sudo su cad
cd $script_dir

echo ""
echo "Ending buildroot session"
if [ ! -d "$shared_config" ]; then
    echo "Warning: $shared_config has already been deleted."
    exit 0
fi
if [ ! -f "$shared_config/.owner" ]; then
    echo "Oy vey -- no .owner file found.">&2
    echo "Not sure whether to delete $shared_config.">&2
    exit 1
fi
owner=$(cat "$shared_config"/.owner)
if [ $owner != $(whoami) ]; then
    echo "Whoah there! It seems $owner created $shared_config.">&2
    echo "Ask them before deleting their work.">&2
    exit 1
fi
echo "Copying modified configs from \$RISCV/buildroot-config-src back to ../buildroot-config-src."
for file in $personal_config/*; do
    file=$(basename $file)
    cp $shared_config/$file $personal_config/$file
done
echo "Elevate permissions to remove personal configs from shared location."
sudo rm -r $shared_config
