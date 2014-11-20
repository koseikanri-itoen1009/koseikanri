REM -----------------------------------------------------------------------------
REM   Program Name     : XXCCP007A07main.bat
REM   Description      : 会計領域夜間ジョブ結果取得(メインバッチ)
REM   Version          : 1.00
REM   Change Record
REM ------------- ----- ---------------- -------------------------------------------------
REM  Date          Ver.  Editor           Description
REM ------------- ----- ---------------- -------------------------------------------------
REM  2013/03/07    1.00  SCSK 小山伸男    新規作成
REM -----------------------------------------------------------------------------

REM 環境変数の設定処理を呼出(初期処理)
call XXCCP007A07init.bat %1

REM sqlplusを使用し、指定された日付の夜間ジョブの結果を取得します。
%ORACLE_HOME%\bin\sqlplus /nolog @%WORK_DIR%XXCCP007A07_conc_check.sql %CONNECT_USER% %CONNECT_PASSWORD% %NET_SERVICE% %LOG_FILE% %INPUT_DATE%

REM sqlplusを使用し、指定された日付の夜間ジョブの出力・ログ取得のためのパラメータ情報を取得します。
%ORACLE_HOME%\bin\sqlplus /nolog @%WORK_DIR%XXCCP007A07_conc_ftp.sql %CONNECT_USER% %CONNECT_PASSWORD% %NET_SERVICE% %LOG_FILE2% %INPUT_DATE%

find "get" %LOG_FILE2% > ftpget.txt

copy %WORK_DIR%XXCCP007A07_ftpcmd_front.txt+ftpget.txt+%WORK_DIR%XXCCP007A07_ftpcmd_end.txt ftppara.txt

ftp -s:ftppara.txt >> ftp.log

setlocal enabledelayedexpansion

for /F %%A in ('dir /b *ＡＰ請求書検証*LOG*.txt') do ( set CHK_FILE=%%A
find "再検証" !CHK_FILE!
IF !ERRORLEVEL! EQU 0 (
  ren  !CHK_FILE! 再検証あり_!CHK_FILE!
) ELSE (
  ren  !CHK_FILE! 再検証なし_!CHK_FILE!
)
)

for /F %%A in ('dir /b *ＡＰ請求書検証*LOG*.txt') do ( set CHK_FILE=%%A
find "未検証" !CHK_FILE!
IF !ERRORLEVEL! EQU 0 (
  ren  !CHK_FILE! 未検証あり_!CHK_FILE!
) ELSE (
  ren  !CHK_FILE! 未検証なし_!CHK_FILE!
)
)

for /F %%A in ('dir /b *未払金オープン・インタフェース*') do ( set CHK_FILE=%%A
find "このレポートに対するデータが存在しません" !CHK_FILE!
IF !ERRORLEVEL! EQU 0 (
  ren  !CHK_FILE! 却下レポートなし_!CHK_FILE!
) ELSE (
  ren  !CHK_FILE! 却下レポートあり_!CHK_FILE!
)
)

for /F %%A in ('dir /b 経費精算書インポート*') do ( set CHK_FILE=%%A
find "否認された経費精算書合計: 0" !CHK_FILE!
IF !ERRORLEVEL! EQU 0 (
  ren  !CHK_FILE! 例外レポートなし_!CHK_FILE!
) ELSE (
  ren  !CHK_FILE! 例外レポートあり_!CHK_FILE!
)
)

move *請求ヘッダデータ作成* %BC_DIR%
move *請求明細データ作成* %BC_DIR%
move *請求書データ作成* %BC_DIR%
move *ロックボックス入金処理* %BC_DIR%
move *ロックボックス消込処理* %BC_DIR%
move *売上実績振替情報の作成（振替割合）* %BC_DIR%
copy *買掛／未払金オープン・インタフェース・インポート(問屋支払)* %BC_DIR%


del ftppara.txt
del ftpget.txt
del %LOG_FILE2%


cd /d c:
net use U: /d

exit
