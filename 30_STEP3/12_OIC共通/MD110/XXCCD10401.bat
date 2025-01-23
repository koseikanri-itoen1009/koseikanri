@ECHO OFF
REM -------------------------------------------------------------------------------------
REM Copyright(c)SCSK Corporation, 2024. All rights reserved.
REM 
REM Program Name           : xxccd10401.bat
REM Description            : SVF帳票生成バッチ
REM MD.070                 : ERP_MD070_IPO_CCD_104_01_SVF帳票生成バッチ.xls
REM Version                : 1.0
REM 
REM Parameter List
REM -------- ----------------------------------------------------------
REM  No.     Description
REM -------- ----------------------------------------------------------
REM      %1  ユーザーID
REM      %2  パスワード
REM      %3  SVFサーバ
REM      %4  フォーム様式ファイルパス
REM      %5  クエリー様式ファイルパス
REM      %6  オーガネーションID
REM      %7  ファイルスプール先
REM      %8  NO DATAメッセージ
REM      %9  フォーム様式モード
REM      %10 リージョン
REM      %11 ネームスペース
REM      %12 バケット名
REM      %13 出力ファイル名
REM      %14 可変パラメータ１
REM      ... (中略)
REM      %28 可変パラメータ１５
REM 
REM Change Record
REM ------------ ----- ----------------   -----------------------------------------------
REM Date         Ver.  Editor             Description
REM ------------ ----- ----------------   -----------------------------------------------
REM 2024-03-12   1.0   Yoshio.Kubota      新規作成
REM -------------------------------------------------------------------------------------

REM ===============================
REM 定数
REM ===============================
REM 実行機能ID
SET FUNC_NAME=Xxccd10402
REM 終了コード
SET STATUS_NORMAL=0
SET STATUS_ERROR=8
REM パス設定
SET TEMP_PATH=%~dp0%
SET BASE_PATH=%TEMP_PATH:~0,-10%
SET LOG_PATH=%BASE_PATH%\log
SET LOG_FILE=%LOG_PATH%\xxccd10401.log

REM 開始処理
CALL :log "START"

REM パラメータをログに出力
CALL :log "parameters : %*"

REM パラメータ数チェック（13個未満はエラーとするため4回SHIFTして%9としてチェック）
SET PARAMS=%*
SHIFT
SHIFT
SHIFT
SHIFT
IF "%~9"=="" (
  CALL :log "Parameter Error."
  EXIT /B %STATUS_ERROR%
)

REM JAVA用環境変数
SET JAVA_HOME=C:\PROGRA~2\Java\jdk1.8.0_45
SET JAVA_LIB=%BASE_PATH%\lib
SET PATH=%JAVA_HOME%\bin;%PATH%
SET CLASSPATH=%BASE_PATH%\env;%JAVA_LIB%\%FUNC_NAME%.jar

REM SVF用環境変数
set CLASSPATH=%CLASSPATH%;C:\SVFJP\svfjpd\lib\svf.jar
set CLASSPATH=%CLASSPATH%;C:\app\Administrator\product\11.2.0\client_1\jdbc\lib\ojdbc8.jar

REM OCI SDK for Java用環境変数
SET CLASSPATH=%CLASSPATH%;%JAVA_LIB%\oci-java-sdk-full-3.29.0.jar
SET CLASSPATH=%CLASSPATH%;%JAVA_LIB%\log4j-slf4j-impl-2.23.1.jar
SET CLASSPATH=%CLASSPATH%;%JAVA_LIB%\log4j-api-2.23.1.jar
SET CLASSPATH=%CLASSPATH%;%JAVA_LIB%\log4j-core-2.23.1.jar
SET CLASSPATH=%CLASSPATH%;%JAVA_LIB%\jersey3\oci-java-sdk-common-httpclient-jersey3-3.29.0.jar
SET CLASSPATH=%CLASSPATH%;%JAVA_LIB%\third-party\*
SET CLASSPATH=%CLASSPATH%;%JAVA_LIB%\third-party\jersey3\*

REM Java実行
java -cp %CLASSPATH% -Djavax.net.ssl.trustStore=%BASE_PATH%\env\cacerts jp.co.itoen.xxccd.xxccd10402.%FUNC_NAME% %PARAMS%

REM Java実行がエラーの場合
IF NOT "%ERRORLEVEL%"=="%STATUS_NORMAL%" (
  CALL :log "%FUNC_NAME% failed [%ERRORLEVEL%]."
  EXIT /B %STATUS_ERROR%
)

REM 終了処理
CALL :log "END"
EXIT /B %STATUS_NORMAL%

REM -------------------------------------------------------------------------------------
REM ログ出力関数
REM -------------------------------------------------------------------------------------
:log
ECHO %DATE% %TIME% %~n0 %* >> %LOG_FILE%
EXIT /B
