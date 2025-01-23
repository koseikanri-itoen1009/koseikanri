@ECHO OFF
REM -------------------------------------------------------------------------------------
REM Copyright(c)SCSK Corporation, 2024. All rights reserved.
REM 
REM Program Name           : xxccd10401.bat
REM Description            : SVF���[�����o�b�`
REM MD.070                 : ERP_MD070_IPO_CCD_104_01_SVF���[�����o�b�`.xls
REM Version                : 1.0
REM 
REM Parameter List
REM -------- ----------------------------------------------------------
REM  No.     Description
REM -------- ----------------------------------------------------------
REM      %1  ���[�U�[ID
REM      %2  �p�X���[�h
REM      %3  SVF�T�[�o
REM      %4  �t�H�[���l���t�@�C���p�X
REM      %5  �N�G���[�l���t�@�C���p�X
REM      %6  �I�[�K�l�[�V����ID
REM      %7  �t�@�C���X�v�[����
REM      %8  NO DATA���b�Z�[�W
REM      %9  �t�H�[���l�����[�h
REM      %10 ���[�W����
REM      %11 �l�[���X�y�[�X
REM      %12 �o�P�b�g��
REM      %13 �o�̓t�@�C����
REM      %14 �σp�����[�^�P
REM      ... (����)
REM      %28 �σp�����[�^�P�T
REM 
REM Change Record
REM ------------ ----- ----------------   -----------------------------------------------
REM Date         Ver.  Editor             Description
REM ------------ ----- ----------------   -----------------------------------------------
REM 2024-03-12   1.0   Yoshio.Kubota      �V�K�쐬
REM -------------------------------------------------------------------------------------

REM ===============================
REM �萔
REM ===============================
REM ���s�@�\ID
SET FUNC_NAME=Xxccd10402
REM �I���R�[�h
SET STATUS_NORMAL=0
SET STATUS_ERROR=8
REM �p�X�ݒ�
SET TEMP_PATH=%~dp0%
SET BASE_PATH=%TEMP_PATH:~0,-10%
SET LOG_PATH=%BASE_PATH%\log
SET LOG_FILE=%LOG_PATH%\xxccd10401.log

REM �J�n����
CALL :log "START"

REM �p�����[�^�����O�ɏo��
CALL :log "parameters : %*"

REM �p�����[�^���`�F�b�N�i13�����̓G���[�Ƃ��邽��4��SHIFT����%9�Ƃ��ă`�F�b�N�j
SET PARAMS=%*
SHIFT
SHIFT
SHIFT
SHIFT
IF "%~9"=="" (
  CALL :log "Parameter Error."
  EXIT /B %STATUS_ERROR%
)

REM JAVA�p���ϐ�
SET JAVA_HOME=C:\PROGRA~2\Java\jdk1.8.0_45
SET JAVA_LIB=%BASE_PATH%\lib
SET PATH=%JAVA_HOME%\bin;%PATH%
SET CLASSPATH=%BASE_PATH%\env;%JAVA_LIB%\%FUNC_NAME%.jar

REM SVF�p���ϐ�
set CLASSPATH=%CLASSPATH%;C:\SVFJP\svfjpd\lib\svf.jar
set CLASSPATH=%CLASSPATH%;C:\app\Administrator\product\11.2.0\client_1\jdbc\lib\ojdbc8.jar

REM OCI SDK for Java�p���ϐ�
SET CLASSPATH=%CLASSPATH%;%JAVA_LIB%\oci-java-sdk-full-3.29.0.jar
SET CLASSPATH=%CLASSPATH%;%JAVA_LIB%\log4j-slf4j-impl-2.23.1.jar
SET CLASSPATH=%CLASSPATH%;%JAVA_LIB%\log4j-api-2.23.1.jar
SET CLASSPATH=%CLASSPATH%;%JAVA_LIB%\log4j-core-2.23.1.jar
SET CLASSPATH=%CLASSPATH%;%JAVA_LIB%\jersey3\oci-java-sdk-common-httpclient-jersey3-3.29.0.jar
SET CLASSPATH=%CLASSPATH%;%JAVA_LIB%\third-party\*
SET CLASSPATH=%CLASSPATH%;%JAVA_LIB%\third-party\jersey3\*

REM Java���s
java -cp %CLASSPATH% -Djavax.net.ssl.trustStore=%BASE_PATH%\env\cacerts jp.co.itoen.xxccd.xxccd10402.%FUNC_NAME% %PARAMS%

REM Java���s���G���[�̏ꍇ
IF NOT "%ERRORLEVEL%"=="%STATUS_NORMAL%" (
  CALL :log "%FUNC_NAME% failed [%ERRORLEVEL%]."
  EXIT /B %STATUS_ERROR%
)

REM �I������
CALL :log "END"
EXIT /B %STATUS_NORMAL%

REM -------------------------------------------------------------------------------------
REM ���O�o�͊֐�
REM -------------------------------------------------------------------------------------
:log
ECHO %DATE% %TIME% %~n0 %* >> %LOG_FILE%
EXIT /B
