CREATE OR REPLACE PACKAGE xxpo_common925_pkg 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo_common925_pkg(spec)
 * Description      : 共通関数
 * MD.050/070       : 支給指示からの発注自動作成 Issue1.0  (T_MD050_BPO_925)
 * Version          : 1.9
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
 *  2008/05/01    1.1   I.Higa           指摘事項修正
 *                                        ・PO_HEADERS_INTERFACEの設定値を変更
 *                                        ・PO_LINES_INTERFACEの設定値を変更
 *  2008/05/07    1.2   M.Imazeki        引当情報作成処理(create_reserve_data)追加
 *  2008/05/22    1.3   Y.Majikina       発注ヘッダのAttribute1に設定値を変更
 *                                       発注ヘッダ（アドオン）への登録を追加
 *  2008/06/16    1.4   I.Higa           指摘事項修正
 *                                        ・従業員番号の型をNUMBER型からTYPE型へ変更
 *                                        ・ヘッダ摘要に受注ヘッダアドオンの出荷指示を設定
 *  2008/07/03    1.5   I.Higa           入庫予定日(着荷予定日)を発注の納入日にしているが
 *                                       出庫予定日を発注の納入日とするように変更する。
 *  2008/12/02    1.6   Y.Suzuki         PLSQL表初期化プロシージャの追加
 *  2008/12/02    1.7   T.Yoshimoto      本番障害#377対応
 *  2009/01/05    1.8   D.Nihei          本番障害#861対応
 *  2009/02/25    1.9   D.Nihei          本番障害#1131対応
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
