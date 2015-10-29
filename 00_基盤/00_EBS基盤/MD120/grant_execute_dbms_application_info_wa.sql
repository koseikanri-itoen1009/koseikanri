/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Script Name      : grant_execute_dbms_application_info_wa.sql
 * Description      : SR 3-9937910241から提供されたパッケージを
 *                    実行できるようにする為の権限
 * Version          : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/03/27    1.0   T.Kitagawa       新規作成(E_本稼動_12973対応)
 *
 *****************************************************************************************/
grant execute on sys.dbms_application_info_wa to public;