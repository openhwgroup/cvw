echo "Hello this ~/.profile is meant to demonstrate running some basic commands on Wally."
echo "I am $(whoami)"
echo "And I am on $(hostname)"
touch myFile.txt
echo "This is a line of text." > myFile.txt
echo "A second line of text." >> myFile.txt
mkdir myDir
mv myFile.txt myDir
echo "Created myFile.txt and moved it to myDir. It contains:"
cat myDir/myFile.txt
touch myScript.sh
echo "echo \"Hello this is another example script\"" > myScript.sh
chmod +x myScript.sh
echo "Created myScript.sh. Running it yields:"
./myScript.sh
cd myDir
ln -s ../myScript.sh symLinkToMyScript.sh
echo "Created symLinkToMyScript.sh. Running it yields:"
./symLinkToMyScript.sh
ln ../myScript.sh hardLinkToMyScript.sh
echo "Created hardLinkToMyScript.sh. Running it yields:"
./hardLinkToMyScript.sh
echo "Now let\'s remove all these example files and scripts"
cd /
rm -r myDir
rm myScript.sh
echo "Here is disk usage:"
df -h
echo "And here are the current processes:"
ps
echo "We can create a user."
cd /
mkdir home
echo "password\npassword\n" | adduser myUser
su -c "cd ~; echo \"I am $(whoami) (a new user) and my home directory is $(pwd)\""
echo "And finally a login prompt."
login
