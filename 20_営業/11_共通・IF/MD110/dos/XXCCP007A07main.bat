REM -----------------------------------------------------------------------------
REM   Program Name     : XXCCP007A07main.bat
REM   Description      : ��v�̈��ԃW���u���ʎ擾(���C���o�b�`)
REM   Version          : 1.00
REM   Change Record
REM ------------- ----- ---------------- -------------------------------------------------
REM  Date          Ver.  Editor           Description
REM ------------- ----- ---------------- -------------------------------------------------
REM  2013/03/07    1.00  SCSK ���R�L�j    �V�K�쐬
REM -----------------------------------------------------------------------------

REM ���ϐ��̐ݒ菈�����ďo(��������)
call XXCCP007A07init.bat %1

REM sqlplus���g�p���A�w�肳�ꂽ���t�̖�ԃW���u�̌��ʂ��擾���܂��B
%ORACLE_HOME%\bin\sqlplus /nolog @%WORK_DIR%XXCCP007A07_conc_check.sql %CONNECT_USER% %CONNECT_PASSWORD% %NET_SERVICE% %LOG_FILE% %INPUT_DATE%

REM sqlplus���g�p���A�w�肳�ꂽ���t�̖�ԃW���u�̏o�́E���O�擾�̂��߂̃p�����[�^�����擾���܂��B
%ORACLE_HOME%\bin\sqlplus /nolog @%WORK_DIR%XXCCP007A07_conc_ftp.sql %CONNECT_USER% %CONNECT_PASSWORD% %NET_SERVICE% %LOG_FILE2% %INPUT_DATE%

find "get" %LOG_FILE2% > ftpget.txt

copy %WORK_DIR%XXCCP007A07_ftpcmd_front.txt+ftpget.txt+%WORK_DIR%XXCCP007A07_ftpcmd_end.txt ftppara.txt

ftp -s:ftppara.txt >> ftp.log

setlocal enabledelayedexpansion

for /F %%A in ('dir /b *�`�o����������*LOG*.txt') do ( set CHK_FILE=%%A
find "�Č���" !CHK_FILE!
IF !ERRORLEVEL! EQU 0 (
  ren  !CHK_FILE! �Č��؂���_!CHK_FILE!
) ELSE (
  ren  !CHK_FILE! �Č��؂Ȃ�_!CHK_FILE!
)
)

for /F %%A in ('dir /b *�`�o����������*LOG*.txt') do ( set CHK_FILE=%%A
find "������" !CHK_FILE!
IF !ERRORLEVEL! EQU 0 (
  ren  !CHK_FILE! �����؂���_!CHK_FILE!
) ELSE (
  ren  !CHK_FILE! �����؂Ȃ�_!CHK_FILE!
)
)

for /F %%A in ('dir /b *�������I�[�v���E�C���^�t�F�[�X*') do ( set CHK_FILE=%%A
find "���̃��|�[�g�ɑ΂���f�[�^�����݂��܂���" !CHK_FILE!
IF !ERRORLEVEL! EQU 0 (
  ren  !CHK_FILE! �p�����|�[�g�Ȃ�_!CHK_FILE!
) ELSE (
  ren  !CHK_FILE! �p�����|�[�g����_!CHK_FILE!
)
)

for /F %%A in ('dir /b �o��Z���C���|�[�g*') do ( set CHK_FILE=%%A
find "�۔F���ꂽ�o��Z�����v: 0" !CHK_FILE!
IF !ERRORLEVEL! EQU 0 (
  ren  !CHK_FILE! ��O���|�[�g�Ȃ�_!CHK_FILE!
) ELSE (
  ren  !CHK_FILE! ��O���|�[�g����_!CHK_FILE!
)
)

move *�����w�b�_�f�[�^�쐬* %BC_DIR%
move *�������׃f�[�^�쐬* %BC_DIR%
move *�������f�[�^�쐬* %BC_DIR%
move *���b�N�{�b�N�X��������* %BC_DIR%
move *���b�N�{�b�N�X��������* %BC_DIR%
move *������ѐU�֏��̍쐬�i�U�֊����j* %BC_DIR%
copy *���|�^�������I�[�v���E�C���^�t�F�[�X�E�C���|�[�g(�≮�x��)* %BC_DIR%


del ftppara.txt
del ftpget.txt
del %LOG_FILE2%


cd /d c:
net use U: /d

exit
