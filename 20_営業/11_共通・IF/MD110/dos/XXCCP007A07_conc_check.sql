set verify off
set serveroutput on
set trimspool on
set heading on
set tab off
set headsep ','
set colsep ','
set lines 5000
set pagesize 1000

DEFINE  connect_user       = &1
DEFINE  connect_password   = &2
DEFINE  net_service        = &3
DEFINE  log_file           = &4
DEFINE  input_date         = &5

set echo off
connect &&connect_user/&&connect_password@&&net_service

spool &&log_file

SELECT    /*+ LEADING(fcr) */  
          fu.user_name                            AS "���s���[�U" 
         ,fcr.request_id                          AS "�v��ID"
         ,fcp.CONCURRENT_PROGRAM_NAME             AS "�v���O����ID" 
         ,pt.user_concurrent_program_name         AS "�v���O������" 
         ,TO_CHAR(fcr.actual_start_date,'YYYY/MM/DD HH24:MI:SS')                   AS "�J�n����" 
         ,TO_CHAR(fcr.actual_completion_date,'YYYY/MM/DD HH24:MI:SS')              AS "�I������" 
         ,ROUND((fcr.actual_completion_date - fcr.actual_start_date)*24*60*60,0)   AS "���s����"
         ,DECODE(fcr.phase_code,'C','����' 
                               ,'I','����' 
                               ,'P','�ۗ�' 
                               ,'R','���s��' 
          )                                       AS "F" 
         ,DECODE(fcr.status_code,'A','�ҋ@��' 
                                ,'P','�X�P�W���[����' 
                                ,'B','�ĊJ' 
                                ,'Q','�X�^���o�C' 
                                ,'C','����' 
                                ,'R','����' 
                                ,'D','�����' 
                                ,'S','����' 
                                ,'E','�G���[' 
                                ,'T','�I����' 
                                ,'G','�x��' 
                                ,'U','�֎~' 
                                ,'H','�ۗ���' 
                                ,'W','�x�~' 
                                ,'I','����' 
                                ,'X','�I��' 
                                ,'M','�}�l�[�W���Ȃ�' 
                                ,'Z','�ҋ@��' 
          )                                       AS "S" 
         ,'"' || fcr.ARGUMENT_TEXT || '"'        AS "�p�����[�^" 
         ,fcr.COMPLETION_TEXT                    AS "�������b�Z�[�W"
FROM      apps.fnd_concurrent_requests            fcr 
         ,apps.fnd_concurrent_programs            fcp 
         ,apps.fnd_concurrent_programs_tl         pt 
         ,apps.fnd_user                           fu 
WHERE     pt.application_id        = fcr.program_application_id 
AND       pt.concurrent_program_id = fcr.concurrent_program_id 
AND       pt.application_id        = fcp.application_id 
AND       pt.concurrent_program_id = fcp.concurrent_program_id 
AND       fcr.requested_by         = fu.user_id 
AND       pt.language              = 'JA' 
AND       fu.user_name             IN ('JP1SALES','VDBM_FB','JP1OIE') 
AND       fcr.phase_code           = 'C'          
AND      fcp.concurrent_program_name IN ('FNDWFBG','FNDWFBG','POXPOIV','XX032AP001C','APACCENG','APGLTRANS','APMACR','XX032JU001C','APACCENG','APGLTRANS','XX032JU001C','XX034PT001C','APXIIMPT','XX032AP001C','APACCENG','APGLTRANS','XX032JU001C','XX031EC001C','APXXTR','XXCFO007S07C','APACCENG','APGLTRANS','XX032JU001C','APXIIMPT','XX032AP001C','APACCENG','APGLTRANS','XX032JU001C','XXCFO007A01C','XX031JI001C','XX031AP001C','XX034GT001C','XX031JI001C','XX031AP001C','XX031JI001C','XX031AP001C','XX031JI001C','XX031AP001C','XX031JI001C','XX031AP001C','XX031JI001C','XX031AP001C','XX031JI001C','XX031AP001C','XX031JI001C','XX031AP001C','XXCFO010A01C','RGOPTM','XXCFO008A01C','XXCFO014A01C','XXCFF002A01C','XXCFF009A15C','XXCFR001A04C','RAXMTR','RAXMTR','XX033AP001C','XX033JU001C','XXCFR003A01C','XXCFR003A02C1','XXCFR003A03C','XXCFR003A04C1','XXCFR006A03C','XX033AP001C','XX033JU001C','XXCFR001A02C','FARXPRG','FARXPRG','XX034RT001C','XXCFR001A01C','RAXMTR','XX033AP001C','XX033JU001C','XXCFR006A02C','XX033AP001C','XX033JU001C','XXCFR006A03C','XX033AP001C','XX033JU001C','XXCFF006A12C','XXCFR001A03C','RAXTRX','GLLEZL','XXCMM003A14C','XXCMM003A15C','XXCMM002A11D','XXCMM002A01C','XXCFR005A04C','XXCFR005A05C','XXCOK008A06C','XXCSO010A02C','XXCSO010A02C') 
AND      fcr.request_date  BETWEEN TO_DATE(NVL('&&input_date',TO_CHAR(SYSDATE,'YYYYMMDD'))||' 000000','YYYYMMDD HH24MISS') 
                               AND TO_DATE(NVL('&&input_date',TO_CHAR(SYSDATE,'YYYYMMDD'))||' 060000','YYYYMMDD HH24MISS') 
order by 4
/

spool off

quit
