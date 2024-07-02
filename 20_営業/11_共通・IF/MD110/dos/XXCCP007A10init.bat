REM -----------------------------------------------------------------------------
REM   Program Name     : XXCCP007A10init.bat
REM   Description      : ��v�̈�f�[�^�`�F�b�N�o��(��������)
REM   Version          : 1.0
REM   Change Record
REM ------------- ----- ---------------- -------------------------------------------------
REM  Date          Ver.  Editor           Description
REM ------------- ----- ---------------- -------------------------------------------------
REM  2024/04/04    1.00  SCSK �{�������Y    �V�K�쐬
REM -----------------------------------------------------------------------------

REM �I���N���C���X�g�[���f�B���N�g�������ϐ��֐ݒ肵�܂��B
set ORACLE_HOME=D:\oracle\product\10.2.0\client_1

REM �X�L�[�}�����ϐ��֐ݒ肵�܂��B
set CONNECT_USER=itoen

REM �X�L�[�}PASS�����ϐ��֐ݒ肵�܂��B
set CONNECT_PASSWORD=itoen

REM PROACTIVE DB SID�����ϐ��֐ݒ肵�܂��B
set NET_SERVICE=BEBSITO

REM �l�b�g���[�N�h���C�u����
set LOG_DRIVE=\\itoenfile\8770\��ԃo�b�`�Ǘ�
net use U: %LOG_DRIVE%

REM �g�p������t�����p�����[�^�̐ݒ�L���𔻒f�����ϐ��֐ݒ肵�܂��B
REM �w�肪����ꍇ�́A�w�肳�ꂽ���t�����ɏ������s���A�w�肳��Ă��Ȃ��ꍇ��
REM �V�X�e�����t�����ɏ������s�Ȃ��܂��B
@echo off
IF "%1"=="" (
set INPUT_DATE=%date:~0,4%%date:~5,2%%date:~8,2%
)else (
set INPUT_DATE=%1
)
echo INPUT_DATE %INPUT_DATE%

REM �g�p����f�B���N�g���������ϐ��֐ݒ肵�܂��B
set WORK_DIR=%cd%\%
echo WORK_DIR %WORK_DIR%
cd /d U:\
set LOG_DIR=%cd%\���Ǘ���\%INPUT_DATE%
set BC_DIR=%cd%\�����Z���^�[\%INPUT_DATE%
set FA_DIR=%cd%\�����o����\%INPUT_DATE%

mkdir %LOG_DIR%
mkdir %BC_DIR%
mkdir %FA_DIR%
cd %LOG_DIR%
echo LOG_DIR %LOG_DIR%
REM �t�@�C���������ϐ��֐ݒ肵�܂��B
set LOG_FILE1=%cd%\�o��Z�����ύX�f�[�^_%INPUT_DATE%.csv
echo LOG_FILE1  %LOG_FILE1%
