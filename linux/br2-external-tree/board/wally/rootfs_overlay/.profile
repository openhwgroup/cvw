echo "Hello this ~/.profile is meant to demonstrate running some basic commands on Wally."
echo "I am $(whoami)"
echo "And I am on $(hostname)"
touch myFile.txt
echo "Hello World!" > myFile.txt
echo "And farewell!" >> myFile.txt
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
echo "Now let's remove all these example files and scripts"
cd /
rm -r myDir
rm myScript.sh
echo "Here is disk usage:"
df -h
echo "And here are the current processes:"
ps
echo "And finally a login prompt."
login
