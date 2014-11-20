CREATE OR REPLACE PACKAGE xxwsh400010c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400010c(spec)
 * Description      : 出荷依頼締め解除処理
 * MD.050           : 出荷依頼 T_MD050_BPO_401
 * MD.070           : 出荷依頼締め解除処理  T_MD070_BPO_40K
 * Version          : 1.3
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/04    1.0  Oracle 上原正好   初回作成
 *  2008/5/19     1.1  Oracle 上原正好   内部変更要求#80対応 パラメータ「拠点」追加
 *  2008/07/04    1.2  Oracle 北寒寺正夫 ST#366対応 締解除時の拠点、拠点カテゴリがALLの際の
 *                                       条件が共通関数の条件と異なるため共通関数からコピーし
 *                                       実装
 *  2009/01/20    1.3  Oracle 伊藤ひとみ 本番障害#1053対応
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT NOCOPY VARCHAR2,  -- エラーメッセージ #固定#
    retcode                   OUT NOCOPY VARCHAR2,  -- エラーコード     #固定#
    iv_transaction_type_id  IN VARCHAR2,          -- 出庫形態
    iv_shipped_locat_code     IN VARCHAR2,          -- 出庫元
    iv_sales_branch           IN VARCHAR2,          -- 拠点
    iv_sales_branch_category  IN VARCHAR2,          -- 拠点カテゴリ
    iv_lead_time_day          IN VARCHAR2,          -- 生産物流LT/引取変更LT
    iv_ship_date              IN VARCHAR2,          -- 出庫日
    iv_base_record_class      IN VARCHAR2,          -- 基準レコード区分
    iv_prod_class             IN VARCHAR2           -- 商品区分
  );
END xxwsh400010c;
/
