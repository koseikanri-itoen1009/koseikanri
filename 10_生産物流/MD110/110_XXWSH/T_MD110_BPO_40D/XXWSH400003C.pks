CREATE OR REPLACE PACKAGE xxwsh400003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400003c(package)
 * Description      : 出荷依頼確定関数
 * MD.050           : 出荷依頼               T_MD050_BPO_401
 * MD.070           : 出荷依頼確定関数       T_MD070_EDO_BPO_40D
 * Version          : 1.6
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  ship_set             出荷依頼確定関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/3/13    1.0   R.Matusita        初回作成
 *  2008/4/23    1.1   R.Matusita        内部変更要求#65
 *  2008/6/03    1.2   M.Uehara          内部変更要求#80
 *  2008/6/05    1.3   N.Yoshida         リードタイム妥当性チェック D-2出庫日 > 稼働日に修正
 *  2008/6/05    1.4   M.Uehara          積載効率チェック(積載効率算出)の実施条件を修正
 *  2008/6/05    1.5   N.Yoshida         出荷可否チェックにて引数設定の修正
 *                                       (入力パラメータ：管轄拠点⇒受注ヘッダの管轄拠点)
 *  2008/6/06    1.6   T.Ishiwata        出荷可否チェックにてエラーメッセージの修正
 *
 *****************************************************************************************/
--
  -- 出荷依頼確定関数
  PROCEDURE ship_set(
    iv_prod_class            IN VARCHAR2  DEFAULT NULL, -- 商品区分
    iv_head_sales_branch     IN VARCHAR2  DEFAULT NULL, -- 管轄拠点
    iv_input_sales_branch    IN VARCHAR2  DEFAULT NULL, -- 入力拠点
    in_deliver_to_id         IN NUMBER    DEFAULT NULL, -- 配送先ID
    iv_request_no            IN VARCHAR2  DEFAULT NULL, -- 依頼No
    id_schedule_ship_date    IN DATE      DEFAULT NULL, -- 出庫日
    id_schedule_arrival_date IN DATE      DEFAULT NULL, -- 着日
    iv_callfrom_flg          IN VARCHAR2,               -- 呼出元フラグ
    iv_status_kbn            IN VARCHAR2,               -- 締めステータスチェック区分
    ov_errbuf                OUT NOCOPY   VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY   VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY   VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
    );    
END xxwsh400003c;
/
