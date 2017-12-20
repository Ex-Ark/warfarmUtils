rmdir /s /q build

mkdir build
mkdir build\db

xcopy db build\db

(echo .\app.exe perrin.wf loka.wf) >  build\start_app_with_syndicats.bat
(echo .\app.exe misc.wf) > build\start_app_with_misc.bat
(echo .\app.exe perrin.wf) >  build\start_app_with_perrin.bat
(echo .\app.exe loka.wf) >  build\start_app_with_loka.bat
(echo .\app.exe hexis.wf) >  build\start_app_with_hexis.bat
(echo .\app.exe suda.wf) >  build\start_app_with_suda.bat
(echo .\app.exe veil.wf) >  build\start_app_with_veil.bat

ocra --output build\app.exe app.rb
