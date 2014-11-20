CREATE OR REPLACE PACKAGE xxinv550004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv550004c(package)
 * Description      : 棚卸スナップショット作成
 * MD.050           : 在庫(帳票)               T_MD050_BPO_550
 * MD.070           : 棚卸スナップショット作成 T_MD070_BPO_55D
 * Version          : 1.5
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  create_snapshot      棚卸スナップショット作成ファンクション
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/10    1.0  Oracle 松下 竜二  新規作成
 *  2008/05/07    1.1  Oracle 中村 純恵  内部変更要求#47,#62
 *  2008/05/20    1.2  Oracle 熊本 和郎  結合テスト障害(User-Defined Exception)対応
 *  2008/06/23    1.3  Oracle 熊本 和郎  システムテスト障害#260(受払残高リストが終了しない)対応
 *  2008/08/28    1.4  Oracle 山根 一浩  PT 2_1_12 #33,T_S_503対応
 *  2008/09/16    1.5   Y.Yamamoto       PT 2-1_12 #63
 *
 *****************************************************************************************/
--
  -- 棚卸スナップショット作成関数
  FUNCTION create_snapshot(
    iv_invent_ym 	IN  VARCHAR2,                   -- 対象年月	
    iv_whse_code1	IN  VARCHAR2 DEFAULT NULL,      -- 倉庫コード１
    iv_whse_code2       IN  VARCHAR2 DEFAULT NULL,  -- 倉庫コード２
    iv_whse_code3       IN  VARCHAR2 DEFAULT NULL,  -- 倉庫コード３
    iv_whse_department1	IN  VARCHAR2 DEFAULT NULL,  -- 倉庫管理部署１
    iv_whse_department2 IN  VARCHAR2 DEFAULT NULL,  -- 倉庫管理部署２
    iv_whse_department3 IN  VARCHAR2 DEFAULT NULL,  -- 倉庫管理部署３
    iv_block1           IN  VARCHAR2 DEFAULT NULL,  -- ブロック１
    iv_block2           IN  VARCHAR2 DEFAULT NULL,  -- ブロック２
    iv_block3           IN  VARCHAR2 DEFAULT NULL,  -- ブロック３
    iv_arti_div_code    IN  VARCHAR2,               -- 商品区分
    iv_item_class_code  IN  VARCHAR2)               -- 品目区分
    RETURN NUMBER;
END xxinv550004c;
/











































