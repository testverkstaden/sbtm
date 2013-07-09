sudo rm ./scan.log
sudo rm ./reports/*.txt
sudo rm ./reports/sessions/*.ses

ruby tools-ruby/scan.rb approved datafiles . reports scan.log

cp ./approved/*.ses ./reports/sessions/

tail ./scan.log