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
          fu.user_name                            AS "実行ユーザ" 
         ,fcr.request_id                          AS "要求ID"
         ,fcp.CONCURRENT_PROGRAM_NAME             AS "プログラムID" 
         ,pt.user_concurrent_program_name         AS "プログラム名" 
         ,TO_CHAR(fcr.actual_start_date,'YYYY/MM/DD HH24:MI:SS')                   AS "開始時刻" 
         ,TO_CHAR(fcr.actual_completion_date,'YYYY/MM/DD HH24:MI:SS')              AS "終了時刻" 
         ,ROUND((fcr.actual_completion_date - fcr.actual_start_date)*24*60*60,0)   AS "実行時間"
         ,DECODE(fcr.phase_code,'C','完了' 
                               ,'I','無効' 
                               ,'P','保留' 
                               ,'R','実行中' 
          )                                       AS "F" 
         ,DECODE(fcr.status_code,'A','待機中' 
                                ,'P','スケジュール済' 
                                ,'B','再開' 
                                ,'Q','スタンバイ' 
                                ,'C','正常' 
                                ,'R','正常' 
                                ,'D','取消済' 
                                ,'S','延期' 
                                ,'E','エラー' 
                                ,'T','終了中' 
                                ,'G','警告' 
                                ,'U','禁止' 
                                ,'H','保留中' 
                                ,'W','休止' 
                                ,'I','正常' 
                                ,'X','終了' 
                                ,'M','マネージャなし' 
                                ,'Z','待機中' 
          )                                       AS "S" 
         ,'"' || fcr.ARGUMENT_TEXT || '"'        AS "パラメータ" 
         ,fcr.COMPLETION_TEXT                    AS "完了メッセージ"
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
