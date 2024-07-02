REM -----------------------------------------------------------------------------
REM   Program Name     : XXCCP007A10main.bat
REM   Description      : 会計領域データチェック出力(メインバッチ)
REM   Version          : 1.00
REM   Change Record
REM ------------- ----- ---------------- -------------------------------------------------
REM  Date          Ver.  Editor           Description
REM ------------- ----- ---------------- -------------------------------------------------
REM  2024/04/04    1.00  SCSK 須藤賢太郎    新規作成
REM -----------------------------------------------------------------------------

REM 環境変数の設定処理を呼出(初期処理)
call XXCCP007A10init.bat %1

REM sqlplusを使用し、指定された日付の経費精算口座変更データ結果を取得します。
%ORACLE_HOME%\bin\sqlplus /nolog @%WORK_DIR%XXCCP007A10-01_check.sql %CONNECT_USER% %CONNECT_PASSWORD% %NET_SERVICE% %LOG_FILE1% %INPUT_DATE%

setlocal enabledelayedexpansion

for /F %%A in ('dir /b *経費精算口座変更データ*.csv') do ( set CHK_FILE=%%A
find "レコードが選択されませんでした" !CHK_FILE!
IF !ERRORLEVEL! EQU 0 (
  ren  !CHK_FILE! 対象なし_!CHK_FILE!
) ELSE (
  ren  !CHK_FILE! 対象あり_!CHK_FILE!
)
)

copy *経費精算口座変更データ* %BC_DIR%
copy *経費精算口座変更データ* %FA_DIR%

cd /d c:
net use U: /d

cmd /k


