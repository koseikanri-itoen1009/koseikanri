set verify off
set serveroutput on
set trimspool on
set heading on
set tab off
set headsep ','
set colsep ','
set lines 1000
set pagesize 1000

DEFINE  connect_user       = &1
DEFINE  connect_password   = &2
DEFINE  net_service        = &3
DEFINE  log_file2          = &4
DEFINE  input_date         = &5

set echo off
connect &&connect_user/&&connect_password@&&net_service

spool &&log_file2

SELECT    /*+ LEADING(fcr) */
         CASE   fcp.concurrent_program_name
           WHEN 'XX031EC001C' THEN
             'get '|| fcr.OUTFILE_NAME || ' ' || to_multi_byte(pt.user_concurrent_program_name) || '(' || fcr.argument3 || ')' || '_' || fcr.request_id || '.txt'
           WHEN 'XX031JI001C' THEN
             'get '|| fcr.OUTFILE_NAME || ' ' || to_multi_byte(pt.user_concurrent_program_name) || '(' || DECODE(fcr.argument2,'1','GLïîñÂì¸óÕ','3','é¿ê—êUë÷','4','îÃîÑé¿ê—','5','å¬ï äJî≠','6','ç›å…å¥âøêUë÷','Inventory','ç›å…ä«óù','Payables','îÉä|ä«óù','Receivables','îÑä|ä«óù',fcr.argument2) || ')' ||  '_' || fcr.request_id || '.txt'
           WHEN 'RAXTRX' THEN
             'get '|| fcr.OUTFILE_NAME || ' ' || to_multi_byte(pt.user_concurrent_program_name) || '(' || fcr.argument4 || ')' ||  '_' || fcr.request_id || '.txt'
           WHEN 'APXIIMPT' THEN
             'get '|| fcr.OUTFILE_NAME || ' ' || to_multi_byte(pt.user_concurrent_program_name) || '(' || DECODE(fcr.argument1,'BM_SYSTEM','ñ‚âÆéxï•','XX03_ENTRY','ïîñÂì¸óÕ',fcr.argument1) || ')' ||  '_' || fcr.request_id || '.txt'
           ELSE
             'get '|| fcr.OUTFILE_NAME || ' ' || to_multi_byte(pt.user_concurrent_program_name) ||  '_' || fcr.request_id || '.txt'
         END
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
AND     ((fcr.status_code          IN ('G','E')
AND       fcp.concurrent_program_name IN (
 'APACCENG'
,'APGLTRANS'
,'APMACR'
,'FARXPRG'
,'FNDWFBG'
,'GLLEZL'
,'POXPOIV'
,'RAXMTR'
,'RAXTRX'
,'RGOPTM'
,'XX031AP001C'
,'XX031EC001C'
,'XX031JI001C'
,'XX032JU001C'
,'XX033AP001C'
,'XX033JU001C'
,'XX034GT001C'
,'XX034PT001C'
,'XX034RT001C'
,'XXCFF002A01C'
,'XXCFF006A12C'
,'XXCFF009A15C'
,'XXCFO007A01C'
,'XXCFO010A01C'
,'XXCFO014A01C'
,'XXCFR001A01C'
,'XXCFR001A02C'
,'XXCFR001A03C'
,'XXCFR001A04C'
,'XXCFR003A01C'
,'XXCFR003A02C1'
,'XXCFR003A03C'
,'XXCFR003A04C1'
,'XXCFR005A04C'
,'XXCFR005A05C'
,'XXCFR006A03C'
,'XXCMM002A01C'
,'XXCMM002A11D'
,'XXCMM003A14C'
,'XXCMM003A15C'
,'XXCOK008A06C'
,'XXCSO010A02C'
))
OR (fcp.concurrent_program_name IN ('XX032AP001C','XXCFO007S07C','XXCFR006A02C','APXXTR','XXCFO008A01C','APXIIMPT')))
AND      fcr.request_date  BETWEEN TO_DATE(NVL('&&input_date',TO_CHAR(SYSDATE,'YYYYMMDD'))||' 000000','YYYYMMDD HH24MISS') 
                               AND TO_DATE(NVL('&&input_date',TO_CHAR(SYSDATE,'YYYYMMDD'))||' 060000','YYYYMMDD HH24MISS') 
UNION
SELECT    /*+ LEADING(fcr) */
         CASE   fcp.concurrent_program_name
           WHEN 'XX032AP001C' THEN
             'get '|| fcr.LOGFILE_NAME || ' ' || to_multi_byte(pt.user_concurrent_program_name) ||  'LOG_' || fcr.request_id || '.txt'
           WHEN 'XXCMM002A01C' THEN
             'get '|| fcr.LOGFILE_NAME || ' ' || to_multi_byte(pt.user_concurrent_program_name) ||  'LOG_' || fcr.request_id || '.txt'
           ELSE
             NULL
         END
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
AND       fcp.concurrent_program_name IN (
 'XX032AP001C'
,'XXCMM002A01C'
)
AND      fcr.request_date  BETWEEN TO_DATE(NVL('&&input_date',TO_CHAR(SYSDATE,'YYYYMMDD'))||' 000000','YYYYMMDD HH24MISS') 
                               AND TO_DATE(NVL('&&input_date',TO_CHAR(SYSDATE,'YYYYMMDD'))||' 060000','YYYYMMDD HH24MISS') 
/

spool off

quit
