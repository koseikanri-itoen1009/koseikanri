/*************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 * 
 * DB Link Name    : EBS_PAAS3
 * Description     : 検証環境用EBS to PaaSデータベースリンク
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2025/01/22    1.0  Y.Kubota       初回作成
 ************************************************************************/
CREATE DATABASE LINK EBS_PAAS3.ITOEN.MASTER
  CONNECT TO oicuser IDENTIFIED BY ItoeN_oicuser#_2023
  USING '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=xddbsv1-scan.database.stgvcn.oraclevcn.com)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=XDPDB1.DATABASE.STGVCN.ORACLEVCN.COM)))'
;
