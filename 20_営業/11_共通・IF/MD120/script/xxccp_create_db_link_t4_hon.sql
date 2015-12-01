/*************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * DATABASE LINK Name : T4_HON
 * Description        : T4→本番環境のデータベースリンク
 * Version            : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2015/10/29    1.0   S.Niki       新規作成
 ************************************************************************/
CREATE DATABASE LINK t4_hon CONNECT TO APPS IDENTIFIED BY APPS
USING '(DESCRIPTION=
         (ADDRESS_LIST=
           (ADDRESS=(PROTOCOL=tcp)(HOST=aebsdb31.itoen.master)(PORT=1521))
           (ADDRESS=(PROTOCOL=tcp)(HOST=aebsdb21.itoen.master)(PORT=1521))
           (ADDRESS=(PROTOCOL=tcp)(HOST=aebsdb11.itoen.master)(PORT=1521))
         )
         (CONNECT_DATA=
           (SERVICE_NAME=AEBSITO.itoen.master))
      )'
;
