CREATE OR REPLACE PACKAGE xxpo_common925_pkg 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo_common925_pkg(spec)
 * Description      : 共通関数
 * MD.050/070       : 支給指示からの発注自動作成 Issue1.0  (T_MD050_BPO_925)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ------------------------------------------------------------
 *  Name                   Description
 * ---------------------- ------------------------------------------------------------
 *  auto_purchase_orders   支給指示からの発注自動作成
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/12    1.0   M.Imazeki        新規作成
 *
 *****************************************************************************************/
--
  -- 支給指示からの発注自動作成
  PROCEDURE auto_purchase_orders
    (
      iv_request_no         IN          VARCHAR2         --   01 : 依頼No
     ,ov_retcode            OUT NOCOPY  VARCHAR2         --  リターン・コード
     ,on_batch_id           OUT NOCOPY  NUMBER           --  バッチID
     ,ov_errmsg_code        OUT NOCOPY  VARCHAR2         --  エラー・メッセージ・コード
     ,ov_errmsg             OUT NOCOPY  VARCHAR2         --  ユーザー・エラー・メッセージ
    ) ;
--
END xxpo_common925_pkg;
/
