REM -----------------------------------------------------------------------------
REM   Program Name     : XXCCP007A10main.bat
REM   Description      : ��v�̈�f�[�^�`�F�b�N�o��(���C���o�b�`)
REM   Version          : 1.00
REM   Change Record
REM ------------- ----- ---------------- -------------------------------------------------
REM  Date          Ver.  Editor           Description
REM ------------- ----- ---------------- -------------------------------------------------
REM  2024/04/04    1.00  SCSK �{�������Y    �V�K�쐬
REM -----------------------------------------------------------------------------

REM ���ϐ��̐ݒ菈�����ďo(��������)
call XXCCP007A10init.bat %1

REM sqlplus���g�p���A�w�肳�ꂽ���t�̌o��Z�����ύX�f�[�^���ʂ��擾���܂��B
%ORACLE_HOME%\bin\sqlplus /nolog @%WORK_DIR%XXCCP007A10-01_check.sql %CONNECT_USER% %CONNECT_PASSWORD% %NET_SERVICE% %LOG_FILE1% %INPUT_DATE%

setlocal enabledelayedexpansion

for /F %%A in ('dir /b *�o��Z�����ύX�f�[�^*.csv') do ( set CHK_FILE=%%A
find "���R�[�h���I������܂���ł���" !CHK_FILE!
IF !ERRORLEVEL! EQU 0 (
  ren  !CHK_FILE! �ΏۂȂ�_!CHK_FILE!
) ELSE (
  ren  !CHK_FILE! �Ώۂ���_!CHK_FILE!
)
)

copy *�o��Z�����ύX�f�[�^* %BC_DIR%
copy *�o��Z�����ύX�f�[�^* %FA_DIR%

cd /d c:
net use U: /d

cmd /k


