REM -----------------------------------------------------------------------------
REM   Program Name     : XXCCP007A07init.bat
REM   Description      : 会計領域夜間ジョブ結果取得(初期処理)
REM   Version          : 1.0
REM   Change Record
REM ------------- ----- ---------------- -------------------------------------------------
REM  Date          Ver.  Editor           Description
REM ------------- ----- ---------------- -------------------------------------------------
REM  2013/03/07    1.00  SCSK 小山伸男    新規作成
REM  2019/08/01    1.01  SCSK 小山伸男    出力先フォルダ｢業務管理部｣を｢事務センター｣へ変更
REM  2021/12/14    3.00  SCSK 竹浪  隼    [E_本稼動_17774対応] 環境変数(DB SID)の変更
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
cd /d U:\
set LOG_DIR=%cd%\情報管理部\%INPUT_DATE%
set BC_DIR=%cd%\事務センター\%INPUT_DATE%

mkdir %LOG_DIR%
mkdir %BC_DIR%
cd %LOG_DIR%
echo LOG_DIR %LOG_DIR%
REM ファイル名を環境変数へ設定します。
set LOG_FILE=%cd%\%INPUT_DATE%.csv
set LOG_FILE2=%cd%\%INPUT_DATE%temp.csv
echo LOG_FILE  %LOG_FILE%
echo LOG_FILE2 %LOG_FILE2%
