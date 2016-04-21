/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Script Name      : DBMS_AUDIT_MGMT_SET_AUDIT_TRAIL_LOCATION
 * Description      : 監査表(SYS.AUD$、SYS.FGA_LOG$)をSYSAUX表領域へ移動
 *                    DBMS_AUDIT_MGMT を使用した監査証跡のメンテナンス(KROWN:140400) (ドキュメントID 1748595.1)
 * Version          : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/02/09    1.0   T.Kitagawa       [E_本稼動_13496]新規作成
 *
 *****************************************************************************************/
--
BEGIN
  DBMS_AUDIT_MGMT.SET_AUDIT_TRAIL_LOCATION(
    audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_DB_STD,
    audit_trail_location_value => 'SYSAUX'
  );
END;
/
