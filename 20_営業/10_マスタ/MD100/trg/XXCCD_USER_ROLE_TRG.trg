/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Table Name  : XXCCD_USER_ROLE_TRG
 * Description : ユーザロール インサート トリガー
 * Version     : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2022/10/21    1.0   SCSK H.Shimizu   新規作成
 *  2023/04/18    1.1   SCSK Y.Kubota    末尾にスラッシュを追加
 *
 ****************************************************************************************/
CREATE OR REPLACE TRIGGER XXCCD_USER_ROLE_TRG 
BEFORE INSERT ON XXCCD_USER_ROLE 
FOR EACH ROW WHEN (NEW.id IS NULL) 
BEGIN
  :NEW.id := XXCCD_USER_ROLE_SEQ.nextval;
END;
/
