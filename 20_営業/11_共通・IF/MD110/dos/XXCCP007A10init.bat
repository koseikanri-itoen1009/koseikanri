REM -----------------------------------------------------------------------------
REM   Program Name     : XXCCP007A10init.bat
REM   Description      : 会計領域データチェック出力(初期処理)
REM   Version          : 1.0
REM   Change Record
REM ------------- ----- ---------------- -------------------------------------------------
REM  Date          Ver.  Editor           Description
REM ------------- ----- ---------------- -------------------------------------------------
REM  2024/04/04    1.00  SCSK 須藤賢太郎    新規作成
REM -----------------------------------------------------------------------------

REM オラクルインストールディレクトリを環境変数へ設定します。
set ORACLE_HOME=D:\oracle\product\10.2.0\client_1

REM スキーマを環境変数へ設定します。
set CONNECT_USER=itoen

REM スキーマPASSを環境変数へ設定します。
set CONNECT_PASSWORD=itoen

REM PROACTIVE DB SIDを環境変数へ設定します。
set NET_SERVICE=BEBSITO

REM ネットワークドライブ割当
set LOG_DRIVE=\\itoenfile\8770\夜間バッチ管理
net use U: %LOG_DRIVE%

REM 使用する日付情報をパラメータの設定有無を判断し環境変数へ設定します。
REM 指定がある場合は、指定された日付を元に処理を行い、指定されていない場合は
REM システム日付を元に処理を行ないます。
@echo off
IF "%1"=="" (
set INPUT_DATE=%date:~0,4%%date:~5,2%%date:~8,2%
)else (
set INPUT_DATE=%1
)
echo INPUT_DATE %INPUT_DATE%

REM 使用するディレクトリ名を環境変数へ設定します。
set WORK_DIR=%cd%\%
echo WORK_DIR %WORK_DIR%
cd /d U:\
set LOG_DIR=%cd%\情報管理部\%INPUT_DATE%
set BC_DIR=%cd%\事務センター\%INPUT_DATE%
set FA_DIR=%cd%\財務経理部\%INPUT_DATE%

mkdir %LOG_DIR%
mkdir %BC_DIR%
mkdir %FA_DIR%
cd %LOG_DIR%
echo LOG_DIR %LOG_DIR%
REM ファイル名を環境変数へ設定します。
set LOG_FILE1=%cd%\経費精算口座変更データ_%INPUT_DATE%.csv
echo LOG_FILE1  %LOG_FILE1%
