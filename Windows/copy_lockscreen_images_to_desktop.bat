:: cd to C:/ first if not already on the C drive
c:
:: mkdir tmp
md C:\Users\djp93\Desktop\tmp\
:: copy from lockscreen-random-images dir to tmp/
copy %userprofile%\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets\* C:\Users\djp93\Desktop\tmp\
:: cd tmp
cd C:\Users\djp93\Desktop\tmp\
:: mv * *.jpg
ren * *.jpg
