REM -----------------------------------------------------------------------------
REM   Program Name     : XXCCP007A07init.bat
REM   Description      : ��v�̈��ԃW���u���ʎ擾(��������)
REM   Version          : 1.0
REM   Change Record
REM ------------- ----- ---------------- -------------------------------------------------
REM  Date          Ver.  Editor           Description
REM ------------- ----- ---------------- -------------------------------------------------
REM  2013/03/07    1.00  SCSK ���R�L�j    �V�K�쐬
REM  2019/08/01    1.01  SCSK ���R�L�j    �o�͐�t�H���_��Ɩ��Ǘ�����𢎖���Z���^�[��֕ύX
REM  2021/12/14    3.00  SCSK �|�Q  ��    [E_�{�ғ�_17774�Ή�] ���ϐ�(DB SID)�̕ύX
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
cd /d U:\
set LOG_DIR=%cd%\���Ǘ���\%INPUT_DATE%
set BC_DIR=%cd%\�����Z���^�[\%INPUT_DATE%

mkdir %LOG_DIR%
mkdir %BC_DIR%
cd %LOG_DIR%
echo LOG_DIR %LOG_DIR%
REM �t�@�C���������ϐ��֐ݒ肵�܂��B
set LOG_FILE=%cd%\%INPUT_DATE%.csv
set LOG_FILE2=%cd%\%INPUT_DATE%temp.csv
echo LOG_FILE  %LOG_FILE%
echo LOG_FILE2 %LOG_FILE2%
